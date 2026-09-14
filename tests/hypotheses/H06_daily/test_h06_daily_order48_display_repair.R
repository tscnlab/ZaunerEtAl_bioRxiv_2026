#!/usr/bin/env Rscript

# Verify REPORT-018 order 48a without executing scientific computation.

options(stringsAsFactors = FALSE)

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
setwd(root)
.libPaths(c(
  file.path(root, "renv/library/macos/R-4.6/aarch64-apple-darwin23"),
  .libPaths()
))

required_packages <- c(
  "base64enc",
  "digest",
  "dplyr",
  "readr",
  "rvest",
  "tibble",
  "xml2"
)
missing_packages <- required_packages[
  !vapply(
    required_packages,
    requireNamespace,
    logical(1),
    quietly = TRUE
  )
]
if (length(missing_packages)) {
  stop(
    "Missing synchronized project package(s): ",
    paste(missing_packages, collapse = ", "),
    call. = FALSE
  )
}

suppressPackageStartupMessages({
  library(digest)
  library(dplyr)
  library(readr)
  library(rvest)
  library(tibble)
  library(xml2)
})

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("Order 48a verification requires R 4.6.1.", call. = FALSE)
}

phase <- Sys.getenv("ORDER48A_VERIFY_PHASE", unset = "preflight")
phase <- match.arg(
  phase,
  c("preflight", "prerender", "postrender", "postqa")
)

evidence_relative <-
  "audit/hypotheses/H06_daily/report018_order48a_display_repair"
evidence_dir <- file.path(root, evidence_relative)
dir.create(evidence_dir, recursive = TRUE, showWarnings = FALSE)

work_dir <- Sys.getenv("H06_DAILY_ORDER48A_WORK_DIR", unset = "")
if (nzchar(work_dir)) {
  work_dir <- normalizePath(work_dir, winslash = "/", mustWork = TRUE)
}

sha256_file <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
}

sha256_raw <- function(value) {
  digest::digest(value, algo = "sha256", serialize = FALSE)
}

sha256_text <- function(value) {
  digest::digest(enc2utf8(value), algo = "sha256", serialize = FALSE)
}

write_evidence <- function(data, name) {
  readr::write_csv(data, file.path(evidence_dir, name), na = "")
}

clean_text <- function(node) {
  value <- rvest::html_text2(node)
  trimws(gsub("[[:space:]]+", " ", value))
}

relative_path <- function(path) {
  normalized <- normalizePath(path, winslash = "/", mustWork = FALSE)
  prefix <- paste0(root, "/")
  ifelse(
    startsWith(normalized, prefix),
    substring(normalized, nchar(prefix) + 1L),
    normalized
  )
}

list_files <- function(path, exclude_prefix = character()) {
  if (!dir.exists(path)) {
    return(character())
  }
  files <- list.files(
    path,
    all.files = TRUE,
    full.names = TRUE,
    recursive = TRUE,
    include.dirs = FALSE,
    no.. = TRUE
  )
  info <- file.info(files)
  files <- files[!is.na(info$isdir) & !info$isdir]
  if (length(exclude_prefix)) {
    normalized <- normalizePath(files, winslash = "/", mustWork = FALSE)
    excluded <- Reduce(
      `|`,
      lapply(exclude_prefix, function(prefix) {
        normalized_prefix <- normalizePath(
          prefix,
          winslash = "/",
          mustWork = FALSE
        )
        normalized == normalized_prefix |
          startsWith(normalized, paste0(normalized_prefix, "/"))
      })
    )
    files <- files[!excluded]
  }
  files
}

inventory_paths <- function(paths, role = "inventory member") {
  paths <- sort(unique(paths[file.exists(paths)]))
  if (!length(paths)) {
    stop("An inventory unexpectedly has no files.", call. = FALSE)
  }
  links <- Sys.readlink(paths)
  info <- file.info(paths)
  if (any(info$isdir)) {
    stop("An inventory member is a directory.", call. = FALSE)
  }
  tibble(
    relative_path = relative_path(paths),
    role = if (length(role) == 1L) rep(role, length(paths)) else role,
    sha256 = vapply(paths, sha256_file, character(1)),
    bytes = as.numeric(info$size),
    modified_utc = format(
      info$mtime,
      tz = "UTC",
      usetz = TRUE,
      format = "%Y-%m-%dT%H:%M:%OS6Z"
    ),
    is_symlink = nzchar(links),
    symlink_target = links
  ) |>
    arrange(.data$relative_path)
}

inventory_comparison <- function(before, after) {
  full_join(
    before,
    after,
    by = "relative_path",
    suffix = c("_before", "_after")
  ) |>
    mutate(
      delta = case_when(
        is.na(.data$sha256_before) ~ "ADDED",
        is.na(.data$sha256_after) ~ "REMOVED",
        .data$sha256_before != .data$sha256_after ~ "CHANGED_CONTENT",
        .data$modified_utc_before != .data$modified_utc_after ~ "MTIME_ONLY",
        TRUE ~ "UNCHANGED"
      )
    )
}

manifest_contract <- function(
  path,
  expected_rows,
  label,
  authorized_postimages = character(),
  authorized_bytes = numeric()
) {
  manifest <- readr::read_csv(path, show_col_types = FALSE)
  if (
    nrow(manifest) != expected_rows ||
      anyDuplicated(manifest$path) ||
      any(manifest$path == relative_path(path))
  ) {
    stop(label, " is not exact, unique, and non-circular.", call. = FALSE)
  }
  members <- file.path(root, manifest$path)
  observed_hash <- vapply(members, sha256_file, character(1))
  observed_bytes <- as.numeric(file.info(members)$size)
  audit <- manifest |>
    transmute(
      path = .data$path,
      expected_sha256 = .data$sha256,
      observed_sha256 = observed_hash,
      expected_bytes = .data$bytes,
      observed_bytes = observed_bytes,
      disposition = case_when(
        .data$expected_sha256 == .data$observed_sha256 &
          .data$expected_bytes == .data$observed_bytes ~
          "UNCHANGED",
        .data$path %in%
          names(authorized_postimages) &
          .data$observed_sha256 == authorized_postimages[.data$path] &
          .data$observed_bytes == authorized_bytes[.data$path] ~
          "AUTHORIZED_POSTIMAGE",
        TRUE ~ "UNAUTHORIZED_MISMATCH"
      ),
      status = ifelse(
        .data$disposition == "UNAUTHORIZED_MISMATCH",
        "FAIL",
        "PASS"
      )
    )
  if (!all(audit$status == "PASS")) {
    stop(label, " contains a changed member.", call. = FALSE)
  }
  audit
}

qmd_path <- file.path(root, "notebooks/hypotheses/H06_daily.qmd")
refresh_path <- file.path(
  root,
  "scripts/hypotheses/H06_daily/refresh_h06_daily_order48_figures.R"
)
verifier_path <- file.path(
  root,
  "tests/hypotheses/H06_daily/test_h06_daily_order48_display_repair.R"
)
profile_path <- file.path(root, "_quarto-nathealth.yml")
companion_qmd <- file.path(
  root,
  "audit/hypotheses/H06_daily/H06_daily_analysis_preparation.qmd"
)
companion_html <- file.path(
  root,
  paste0(
    "_build/nathealth/audit/hypotheses/H06_daily/",
    "H06_daily_analysis_preparation.html"
  )
)
html_path <- file.path(
  root,
  "_build/nathealth/notebooks/hypotheses/H06_daily.html"
)
build_root <- file.path(root, "_build/nathealth")

input_paths <- c(
  placement = file.path(
    root,
    paste0(
      "artifacts/11_source_data/H06_daily/",
      "H06_daily_stage3_placement_results.csv"
    )
  ),
  ratio = file.path(
    root,
    paste0(
      "artifacts/11_source_data/H06_daily/",
      "H06_daily_non_l10_production_primary_ratio_effects.csv"
    )
  ),
  absolute = file.path(
    root,
    paste0(
      "artifacts/11_source_data/H06_daily/",
      "H06_daily_non_l10_production_primary_absolute_effects.csv"
    )
  ),
  fdr = file.path(
    root,
    paste0(
      "artifacts/11_source_data/H06_daily/",
      "H06_daily_stage3_fdr_overview_figure.csv"
    )
  ),
  site = file.path(
    root,
    paste0(
      "artifacts/11_source_data/H06_daily/",
      "H06_daily_stage3_primary_site_deviation_figure.csv"
    )
  ),
  site_registry = file.path(root, "config/site_display_registry.csv")
)
expected_input_hashes <- c(
  placement = "55fc295f3d5ad4e4e19fc0dce745d64c1c954ada15e99ca7e28086058dd9769b",
  ratio = "c7a1c0018e82db71e2fb0fe74d6e3e5a6645948017b10dd938fce18f6c5c2a9d",
  absolute = "2b695be686e6fdfdef9bdad4082be1fdcd1100e0d3d763fac35b4a75b8df11a7",
  fdr = "4a9a7c3f0877872e2efe7bfddd73afac1c50299f60474bd8d328ce945f17ddf1",
  site = "12193a0a1795fe478bf4829a3986c2b1290510038e4c4aed59aa7e61714bcbcc",
  site_registry = "3d669d459ecc27d3154bbb5ff5b0d64cb510805d486b45264443228c44a6d809"
)

figure_names <- c(
  ratio_png = "H06_daily_non_l10_production_primary_ratio_effects.png",
  absolute_png = "H06_daily_non_l10_production_primary_absolute_effects.png",
  fdr_png = "H06_daily_stage3_fdr_overview.png",
  fdr_svg = "H06_daily_stage3_fdr_overview.svg",
  site_png = "H06_daily_stage3_primary_site_deviations.png",
  site_svg = "H06_daily_stage3_primary_site_deviations.svg"
)
figure_paths <- file.path(
  root,
  "artifacts/10_figures/H06_daily",
  unname(figure_names)
)
names(figure_paths) <- names(figure_names)
figure5_path <- file.path(
  root,
  paste0(
    "artifacts/10_figures/H06_daily/",
    "H06_daily_temporal_h02_primary_context_functions.png"
  )
)
figure5_hash <-
  "e28c639f23b3f33687ca046a77069153bb66073d29cd03d96fd03408c4317d98"

hard_contract <- tibble(
  item = c(
    "QMD postimage",
    "normal profile",
    "held companion QMD",
    "held companion HTML",
    "protected Figure 5"
  ),
  path = c(
    qmd_path,
    profile_path,
    companion_qmd,
    companion_html,
    figure5_path
  ),
  expected_sha256 = c(
    "8f696f3f89fe9ea18c8066b756a01fc5da6b41e86f8ac7d37d1e16f9c10ba639",
    "80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3",
    "ef4fde67d5dd2ebbb14deb76c025b5ac2ac9b6a34f7b34ca62c2fdb382bde709",
    "7f3adfd0d80c9e083baa34f6aa056bc12e0a30e233f786fbc55a6ad6ac176259",
    figure5_hash
  ),
  expected_bytes = c(65349, 7480, 35409, 4613650, 256215)
) |>
  mutate(
    observed_sha256 = vapply(.data$path, sha256_file, character(1)),
    observed_bytes = as.numeric(file.info(.data$path)$size),
    status = ifelse(
      .data$expected_sha256 == .data$observed_sha256 &
        .data$expected_bytes == .data$observed_bytes,
      "PASS",
      "FAIL"
    ),
    path = relative_path(.data$path)
  )
if (!all(hard_contract$status == "PASS")) {
  stop("A hard order-48a identity changed.", call. = FALSE)
}
write_evidence(hard_contract, paste0("hard_identity_contract_", phase, ".csv"))

input_contract <- tibble(
  input_id = names(input_paths),
  path = relative_path(unname(input_paths)),
  expected_sha256 = unname(expected_input_hashes),
  observed_sha256 = vapply(input_paths, sha256_file, character(1)),
  bytes = as.numeric(file.info(input_paths)$size),
  status = ifelse(
    .data$expected_sha256 == .data$observed_sha256,
    "PASS",
    "FAIL"
  )
)
if (!all(input_contract$status == "PASS")) {
  stop("A frozen display or table input changed.", call. = FALSE)
}
write_evidence(input_contract, paste0("source_input_contract_", phase, ".csv"))

collect_build <- function(label) {
  inventory <- inventory_paths(list_files(build_root), "build member")
  write_evidence(inventory, paste0("build_inventory_", label, ".csv"))
  symlinks <- inventory |>
    filter(.data$is_symlink)
  write_evidence(symlinks, paste0("build_symlink_inventory_", label, ".csv"))
  if (nrow(symlinks)) {
    stop("The nathealth build contains a symlink.", call. = FALSE)
  }
  inventory
}

collect_protected <- function(label) {
  artifact_roots <- list.dirs(
    file.path(root, "artifacts"),
    recursive = FALSE,
    full.names = TRUE
  )
  artifact_roots <- file.path(artifact_roots, "H06_daily")
  artifact_roots <- artifact_roots[dir.exists(artifact_roots)]
  task_roots <- c(
    artifact_roots,
    file.path(root, "audit/hypotheses/H06_daily"),
    file.path(root, "scripts/hypotheses/H06_daily"),
    file.path(root, "tests/hypotheses/H06_daily")
  )
  task_paths <- unlist(
    lapply(task_roots, list_files, exclude_prefix = evidence_dir),
    use.names = FALSE
  )
  handoff_paths <- c(
    list.files(
      file.path(root, "audit/handoffs"),
      pattern = "^H06_daily.*[.](md|csv)$",
      full.names = TRUE
    ),
    list.files(
      file.path(root, "audit/decisions"),
      pattern = "^(h06_daily|h06_primary_selection).*",
      full.names = TRUE
    )
  )
  ledger_paths <- list_files(file.path(root, "audit/ledgers"))
  dispatch_paths <- c(
    list.files(
      file.path(root, "audit/report_harmonization"),
      pattern = "report018_h06_daily.*[.](md|csv)$",
      full.names = TRUE
    ),
    list.files(
      file.path(root, "audit/report_harmonization/owner_orders"),
      pattern = "^48a?_h06_daily.*[.]md$",
      full.names = TRUE
    )
  )
  explicit_paths <- file.path(
    root,
    c(
      "notebooks/hypotheses/H06_daily.qmd",
      "audit/hypotheses/H06_daily/H06_daily_analysis_preparation.qmd",
      "_build/nathealth/notebooks/hypotheses/H06_daily.html",
      paste0(
        "_build/nathealth/audit/hypotheses/H06_daily/",
        "H06_daily_analysis_preparation.html"
      ),
      "notebooks/hypotheses/H06.qmd",
      "audit/hypotheses/H06/H06_analysis_preparation.qmd",
      "_build/nathealth/notebooks/hypotheses/H06.html",
      "_build/nathealth/audit/hypotheses/H06/H06_analysis_preparation.html",
      "_quarto-nathealth.yml",
      "_quarto.yml",
      "scripts/report_harmonization/post_render_gt_html_semantics.R",
      "scripts/report_harmonization/repair_gt_html_semantics.R",
      "scripts/pipeline/p_value_display.R",
      "config/site_display_registry.csv",
      "audit/report_harmonization/phase4_corpus_manifest.csv",
      "renv.lock"
    )
  )
  paths <- sort(unique(c(
    task_paths,
    handoff_paths,
    ledger_paths,
    dispatch_paths,
    explicit_paths
  )))
  inventory <- inventory_paths(paths, "protected member")
  write_evidence(inventory, paste0("protected_inventory_", label, ".csv"))
  inventory
}

parse_qmd_chunks <- function(path) {
  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  starts <- grep("^```\\{r([^}]*)\\}[[:space:]]*$", lines)
  rows <- lapply(seq_along(starts), function(index) {
    start <- starts[[index]]
    relative_end <- which(
      grepl("^```[[:space:]]*$", lines[(start + 1L):length(lines)])
    )[[1L]]
    end <- start + relative_end
    code <- lines[(start + 1L):(end - 1L)]
    error <- ""
    parsed <- tryCatch(
      {
        parse(text = code, keep.source = TRUE)
        TRUE
      },
      error = function(condition) {
        error <<- conditionMessage(condition)
        FALSE
      }
    )
    tibble(
      chunk_order = index,
      start_line = start,
      end_line = end,
      code_sha256 = sha256_text(paste(code, collapse = "\n")),
      parsed = parsed,
      error = error,
      status = ifelse(parsed, "PASS", "FAIL")
    )
  })
  bind_rows(rows)
}

qmd_source_audit <- function() {
  text <- readChar(qmd_path, nchars = file.info(qmd_path)$size, useBytes = TRUE)
  old <- "filter(.data$predictor_id == predictor_id)"
  new <- "filter(.data$predictor_id == .env$predictor_id)"
  old_positions <- gregexpr(old, text, fixed = TRUE)[[1L]]
  new_positions <- gregexpr(new, text, fixed = TRUE)[[1L]]
  old_count <- if (identical(old_positions[[1L]], -1L)) 0L else
    length(old_positions)
  new_count <- if (identical(new_positions[[1L]], -1L)) 0L else
    length(new_positions)
  reconstructed <- sub(new, old, text, fixed = TRUE)
  reconstructed_raw <- charToRaw(reconstructed)
  audit <- tibble(
    check = c(
      "QMD postimage hash",
      "QMD postimage bytes",
      "live safe predicate count",
      "unused historical predicate count",
      "reverse-reconstructed preimage hash",
      "reverse-reconstructed preimage bytes"
    ),
    observed = c(
      sha256_file(qmd_path),
      file.info(qmd_path)$size,
      new_count,
      old_count,
      sha256_raw(reconstructed_raw),
      length(reconstructed_raw)
    ),
    expected = c(
      "8f696f3f89fe9ea18c8066b756a01fc5da6b41e86f8ac7d37d1e16f9c10ba639",
      65349,
      1,
      1,
      "01213a193515c49419dcd1ed9cffcc070a88d639a7382e218275a89bd704cb08",
      65344
    )
  ) |>
    mutate(
      status = ifelse(
        as.character(.data$observed) == as.character(.data$expected),
        "PASS",
        "FAIL"
      )
    )
  if (!all(audit$status == "PASS")) {
    stop("The exact one-hunk QMD transition failed.", call. = FALSE)
  }
  write_evidence(audit, "qmd_source_transition.csv")
  chunk_audit <- parse_qmd_chunks(qmd_path)
  if (nrow(chunk_audit) != 15L || !all(chunk_audit$status == "PASS")) {
    stop("A result QMD R chunk did not parse.", call. = FALSE)
  }
  write_evidence(chunk_audit, "source_chunk_audit.csv")
}

placement_cardinality_audit <- function() {
  placement <- readr::read_csv(
    input_paths[["placement"]],
    show_col_types = FALSE
  )
  predictor_ids <- c(
    "work_free_day",
    "activity_status",
    "previous_sleep_duration_centered_h"
  )
  audit <- bind_rows(lapply(predictor_ids, function(id) {
    subset <- placement |>
      filter(.data$predictor_id == id)
    tibble(
      predictor_id = id,
      rows = nrow(subset),
      metric_slots = n_distinct(subset$metric_slot),
      scenarios = n_distinct(subset$scenario_label),
      row_content_sha256 = sha256_text(paste(
        apply(as.data.frame(subset), 1L, paste, collapse = "|"),
        collapse = "\n"
      )),
      status = ifelse(
        nrow(subset) == 60L &
          n_distinct(subset$metric_slot) == 15L &
          n_distinct(subset$scenario_label) == 4L,
        "PASS",
        "FAIL"
      )
    )
  }))
  if (
    !all(audit$status == "PASS") ||
      n_distinct(audit$row_content_sha256) != 3L
  ) {
    stop(
      "The predictor-specific placement subsets are not distinct and complete.",
      call. = FALSE
    )
  }
  write_evidence(audit, "placement_source_cardinality_audit.csv")
}

static_call_audit <- function() {
  refresh_text <- paste(
    readLines(refresh_path, warn = FALSE, encoding = "UTF-8"),
    collapse = "\n"
  )
  forbidden <- c(
    "readRDS",
    "saveRDS",
    "lmer",
    "glmer",
    "glmmTMB",
    "gam",
    "bam",
    "vcovCL",
    "predict",
    "p.adjust",
    "boot",
    "simulate"
  )
  refresh_calls <- all.names(
    parse(file = refresh_path, keep.source = FALSE),
    functions = TRUE,
    unique = FALSE
  )
  verifier_calls <- all.names(
    parse(file = verifier_path, keep.source = FALSE),
    functions = TRUE,
    unique = FALSE
  )
  audit <- bind_rows(lapply(forbidden, function(call) {
    tibble(
      pattern = call,
      refresh_matches = sum(refresh_calls == call),
      verifier_matches = sum(verifier_calls == call)
    )
  })) |>
    mutate(
      status = ifelse(
        .data$refresh_matches == 0L & .data$verifier_matches == 0L,
        "PASS",
        "FAIL"
      )
    )
  allowed_path_mentions <- vapply(
    unname(input_paths[names(input_paths) != "placement"]),
    function(path) grepl(basename(path), refresh_text, fixed = TRUE),
    logical(1)
  )
  supplemental <- tibble(
    pattern = c(
      "all five authorized display inputs named",
      "no RDS extension",
      "no source call",
      "no broad builder name"
    ),
    refresh_matches = c(
      sum(allowed_path_mentions),
      as.integer(grepl("[.]rds", refresh_text, ignore.case = TRUE)),
      sum(refresh_calls == "source"),
      sum(
        refresh_calls %in%
          c(
            "make_h06_daily_non_l10_production_figures",
            "build_h06_daily_stage3_reader",
            "build_h06_daily_stage3_revision_inputs"
          )
      )
    ),
    verifier_matches = 0L,
    status = c(
      ifelse(all(allowed_path_mentions), "PASS", "FAIL"),
      ifelse(
        !grepl("[.]rds", refresh_text, ignore.case = TRUE),
        "PASS",
        "FAIL"
      ),
      ifelse(sum(refresh_calls == "source") == 0L, "PASS", "FAIL"),
      ifelse(
        sum(
          refresh_calls %in%
            c(
              "make_h06_daily_non_l10_production_figures",
              "build_h06_daily_stage3_reader",
              "build_h06_daily_stage3_revision_inputs"
            )
        ) ==
          0L,
        "PASS",
        "FAIL"
      )
    )
  )
  audit <- bind_rows(audit, supplemental)
  if (!all(audit$status == "PASS")) {
    stop(
      "The dedicated code failed the no-scientific-call audit.",
      call. = FALSE
    )
  }
  write_evidence(audit, "no_scientific_call_audit.csv")
}

whitespace_audit <- function() {
  paths <- c(qmd_path, refresh_path, verifier_path)
  audit <- bind_rows(lapply(paths, function(path) {
    lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
    tibble(
      path = relative_path(path),
      trailing_whitespace_lines = sum(grepl("[[:blank:]]+$", lines)),
      final_newline = length(readBin(path, "raw", n = file.info(path)$size)) >
        0L &&
        tail(readBin(path, "raw", n = file.info(path)$size), 1L) == as.raw(10),
      status = ifelse(
        sum(grepl("[[:blank:]]+$", lines)) == 0L &&
          length(lines) > 0L &&
          length(readBin(path, "raw", n = file.info(path)$size)) > 0L &&
          tail(readBin(path, "raw", n = file.info(path)$size), 1L) ==
            as.raw(10),
        "PASS",
        "FAIL"
      )
    )
  }))
  if (!all(audit$status == "PASS")) {
    stop("A scoped source file has whitespace defects.", call. = FALSE)
  }
  write_evidence(audit, paste0("scoped_whitespace_audit_", phase, ".csv"))
}

versions_audit <- function() {
  quarto_version <- system2("quarto", "--version", stdout = TRUE)
  packages <- c(
    "base64enc",
    "digest",
    "dplyr",
    "ggplot2",
    "gt",
    "png",
    "readr",
    "rvest",
    "svglite",
    "tibble",
    "xml2"
  )
  versions <- bind_rows(
    tibble(component = "R", version = as.character(getRversion())),
    tibble(component = "Quarto", version = quarto_version[[1L]]),
    tibble(
      component = packages,
      version = vapply(
        packages,
        function(package) as.character(utils::packageVersion(package)),
        character(1)
      )
    )
  )
  if (
    versions$version[versions$component == "R"] != "4.6.1" ||
      versions$version[versions$component == "Quarto"] != "1.9.37"
  ) {
    stop("The R or Quarto version changed.", call. = FALSE)
  }
  write_evidence(versions, paste0("software_versions_", phase, ".csv"))
}

qmd_source_audit()
placement_cardinality_audit()
static_call_audit()
whitespace_audit()
versions_audit()

if (phase == "preflight") {
  dispatch_path <- file.path(
    root,
    "audit/report_harmonization/report018_h06_daily_order48a_dispatch_manifest.csv"
  )
  dispatch <- readr::read_csv(dispatch_path, show_col_types = FALSE)
  if (nrow(dispatch) != 50L || anyDuplicated(dispatch$path)) {
    stop("The order-48a dispatch is not exact and unique.", call. = FALSE)
  }
  observed <- tibble(
    path = dispatch$path,
    expected_sha256 = dispatch$sha256,
    observed_sha256 = vapply(
      file.path(root, dispatch$path),
      sha256_file,
      character(1)
    ),
    expected_bytes = dispatch$bytes,
    observed_bytes = as.numeric(file.info(file.path(root, dispatch$path))$size)
  ) |>
    mutate(
      disposition = case_when(
        .data$path == "notebooks/hypotheses/H06_daily.qmd" &
          .data$observed_sha256 ==
            "8f696f3f89fe9ea18c8066b756a01fc5da6b41e86f8ac7d37d1e16f9c10ba639" ~
          "AUTHORIZED_QMD_POSTIMAGE",
        .data$path == "audit/report_harmonization/coordination_matrix.csv" &
          .data$observed_sha256 ==
            "e208a935121cb031bf76669575daf885ec22103bd2c70c86c717bd8de444c20c" ~
          "AUTHORIZED_DISPATCH_TRANSITION",
        .data$expected_sha256 == .data$observed_sha256 &
          .data$expected_bytes == .data$observed_bytes ~
          "UNCHANGED",
        TRUE ~ "UNAUTHORIZED_MISMATCH"
      ),
      status = ifelse(
        .data$disposition == "UNAUTHORIZED_MISMATCH",
        "FAIL",
        "PASS"
      )
    )
  if (!all(observed$status == "PASS")) {
    stop("The dispatch baseline has an unauthorized mismatch.", call. = FALSE)
  }
  write_evidence(observed, "dispatch_reconciliation_preflight.csv")

  concurrence_audit <- manifest_contract(
    file.path(
      root,
      paste0(
        "audit/report_harmonization/",
        "report018_h06_daily_order48_consolidated_repair_concurrence_manifest.csv"
      )
    ),
    25L,
    "Central concurrence manifest",
    authorized_postimages = c(
      "notebooks/hypotheses/H06_daily.qmd" = "8f696f3f89fe9ea18c8066b756a01fc5da6b41e86f8ac7d37d1e16f9c10ba639"
    ),
    authorized_bytes = c("notebooks/hypotheses/H06_daily.qmd" = 65349)
  )
  write_evidence(concurrence_audit, "concurrence_manifest_audit.csv")
  owner_audit <- manifest_contract(
    file.path(
      root,
      paste0(
        "audit/hypotheses/H06_daily/report018_order48_result_render/",
        "order48_fail_closed_manifest.csv"
      )
    ),
    108L,
    "Order-48 owner manifest",
    authorized_postimages = c(
      "notebooks/hypotheses/H06_daily.qmd" = "8f696f3f89fe9ea18c8066b756a01fc5da6b41e86f8ac7d37d1e16f9c10ba639"
    ),
    authorized_bytes = c("notebooks/hypotheses/H06_daily.qmd" = 65349)
  )
  write_evidence(owner_audit, "order48_owner_manifest_audit.csv")

  build <- collect_build("preflight")
  protected <- collect_protected("preflight")
  stopped_html <- tibble(
    path = relative_path(html_path),
    sha256 = sha256_file(html_path),
    bytes = as.numeric(file.info(html_path)$size),
    status = ifelse(
      sha256_file(html_path) ==
        "15c537269ac0be96ce06c6b574946dc0b98d46afe36c3c696f804a216a7d0c76" &
        file.info(html_path)$size == 11691631,
      "PASS",
      "FAIL"
    )
  )
  if (!all(stopped_html$status == "PASS")) {
    stop("The stopped result HTML baseline changed.", call. = FALSE)
  }
  write_evidence(stopped_html, "stopped_html_preimage.csv")
  write_evidence(
    tibble(
      phase = "preflight",
      dispatch_rows = nrow(dispatch),
      concurrence_rows = nrow(concurrence_audit),
      owner_manifest_rows = nrow(owner_audit),
      build_files = nrow(build),
      protected_files = nrow(protected),
      build_symlinks = 0L,
      status = "PASS"
    ),
    "preflight_summary.csv"
  )
  cat(sprintf(
    paste0(
      "ORDER48A_PREFLIGHT=PASS dispatch=%d concurrence=%d owner=%d ",
      "build=%d protected=%d symlinks=0\n"
    ),
    nrow(dispatch),
    nrow(concurrence_audit),
    nrow(owner_audit),
    nrow(build),
    nrow(protected)
  ))
}

display_manifest_path <- file.path(
  root,
  paste0(
    "artifacts/12_manifests/H06_daily/",
    "H06_daily_order48a_display_manifest.csv"
  )
)

authorized_verifier_transition_path <- file.path(
  root,
  paste0(
    "audit/report_harmonization/owner_orders/",
    "48d_h06_daily_authorized_verifier_transition.csv"
  )
)

read_authorized_verifier_transition <- function() {
  transition <- readr::read_csv(
    authorized_verifier_transition_path,
    show_col_types = FALSE
  )
  if (
    nrow(transition) != 1L ||
      anyDuplicated(transition$path) ||
      !identical(transition$path, relative_path(verifier_path)) ||
      sha256_file(verifier_path) != transition$post_sha256 ||
      as.numeric(file.info(verifier_path)$size) !=
        as.numeric(transition$post_bytes)
  ) {
    stop("The authorized verifier transition does not resolve.", call. = FALSE)
  }
  transition
}

verify_promoted_display <- function() {
  if (!file.exists(display_manifest_path)) {
    stop("The current display manifest does not exist.", call. = FALSE)
  }
  manifest <- readr::read_csv(display_manifest_path, show_col_types = FALSE)
  if (
    anyDuplicated(manifest$path) ||
      any(manifest$path == relative_path(display_manifest_path))
  ) {
    stop("The display manifest is not unique and non-circular.", call. = FALSE)
  }
  authorized_verifier <- read_authorized_verifier_transition()
  members <- file.path(root, manifest$path)
  audit <- manifest |>
    transmute(
      path = .data$path,
      expected_sha256 = .data$sha256,
      observed_sha256 = vapply(members, sha256_file, character(1)),
      expected_bytes = .data$bytes,
      observed_bytes = as.numeric(file.info(members)$size),
      disposition = case_when(
        .data$expected_sha256 == .data$observed_sha256 &
          .data$expected_bytes == .data$observed_bytes ~
          "UNCHANGED",
        .data$path == authorized_verifier$path &
          .data$expected_sha256 == authorized_verifier$pre_sha256 &
          .data$expected_bytes == authorized_verifier$pre_bytes &
          .data$observed_sha256 == authorized_verifier$post_sha256 &
          .data$observed_bytes == authorized_verifier$post_bytes ~
          "AUTHORIZED_VERIFIER_TRANSITION",
        TRUE ~ "UNAUTHORIZED_MISMATCH"
      ),
      status = ifelse(
        .data$disposition != "UNAUTHORIZED_MISMATCH",
        "PASS",
        "FAIL"
      )
    )
  if (
    sum(audit$disposition == "AUTHORIZED_VERIFIER_TRANSITION") != 1L ||
      !all(audit$status == "PASS")
  ) {
    stop("A current display-manifest member changed.", call. = FALSE)
  }
  write_evidence(audit, paste0("display_manifest_audit_", phase, ".csv"))

  candidate_inventory <- readr::read_csv(
    file.path(evidence_dir, "candidate_inventory.csv"),
    show_col_types = FALSE
  )
  observed_hashes <- vapply(figure_paths, sha256_file, character(1))
  if (!identical(unname(observed_hashes), candidate_inventory$sha256)) {
    stop(
      "A promoted display differs from its accepted candidate.",
      call. = FALSE
    )
  }
  if (!identical(sha256_file(figure5_path), figure5_hash)) {
    stop("Figure 5 changed.", call. = FALSE)
  }
  audit
}

if (phase == "prerender") {
  if (!nzchar(work_dir)) {
    stop(
      "The pre-render verifier requires the bounded work directory.",
      call. = FALSE
    )
  }
  verify_promoted_display()
  build <- collect_build("prerender")
  protected <- collect_protected("prerender")
  if (!file.exists(file.path(evidence_dir, "process_preflight.csv"))) {
    stop("The external process preflight evidence is missing.", call. = FALSE)
  }
  if (!file.exists(file.path(evidence_dir, "candidate_visual_qa.csv"))) {
    stop("The complete candidate visual review is missing.", call. = FALSE)
  }
  visual <- readr::read_csv(
    file.path(evidence_dir, "candidate_visual_qa.csv"),
    show_col_types = FALSE
  )
  if (nrow(visual) != 4L || !all(visual$status == "PASS")) {
    stop("Candidate visual review did not pass.", call. = FALSE)
  }
  write_evidence(
    tibble(
      phase = "prerender",
      qmd_sha256 = sha256_file(qmd_path),
      display_manifest_sha256 = sha256_file(display_manifest_path),
      candidate_figures = length(figure_paths),
      visual_rows = nrow(visual),
      build_files = nrow(build),
      protected_files = nrow(protected),
      status = "PASS"
    ),
    "prerender_gate_summary.csv"
  )
  cat(sprintf(
    paste0(
      "ORDER48A_PRERENDER=PASS figures=%d visual=%d build=%d ",
      "protected=%d\n"
    ),
    length(figure_paths),
    nrow(visual),
    nrow(build),
    nrow(protected)
  ))
}

outside_source_modal <- function(nodes) {
  if (!length(nodes)) {
    return(logical())
  }
  !vapply(
    nodes,
    function(node) {
      length(xml2::xml_find_all(
        node,
        "ancestor::*[@id='quarto-embedded-source-code-modal']"
      )) >
        0L
    },
    logical(1)
  )
}

format_effect_values <- function(
  estimate,
  lower,
  upper,
  effect_scale,
  metric_slot,
  result_status
) {
  result <- rep("—", length(estimate))
  non_estimable <- result_status == "NON_ESTIMABLE_COMPONENT_FAILURE"
  result[non_estimable] <- "Not estimable"
  mder <- metric_slot == 15L & !is.na(estimate)
  result[mder] <- sprintf(
    "%+.3f (%+.3f to %+.3f)",
    estimate[mder],
    lower[mder],
    upper[mder]
  )
  ratio <- grepl("ratio", effect_scale, fixed = TRUE) &
    !mder &
    !non_estimable &
    !is.na(estimate)
  result[ratio] <- sprintf(
    "%.2f× (%.2f to %.2f)",
    estimate[ratio],
    lower[ratio],
    upper[ratio]
  )
  absolute <- !ratio & !mder & !non_estimable & !is.na(estimate)
  result[absolute] <- sprintf(
    "%+.2f h (%+.2f to %+.2f)",
    estimate[absolute],
    lower[absolute],
    upper[absolute]
  )
  result
}

format_sample <- function(days, participants, sites) {
  sprintf(
    "%d days / %d participants / %d sites",
    days,
    participants,
    sites
  )
}

expected_placement_matrix <- function(placement, predictor_id) {
  scenarios <- c(
    "Primary near eye, all available",
    "Complementary chest, all available",
    "Paired/common near eye",
    "Paired/common chest"
  )
  data <- placement |>
    filter(.data$predictor_id == .env$predictor_id) |>
    mutate(
      Result = paste0(
        format_effect_values(
          .data$estimate,
          .data$lower_95,
          .data$upper_95,
          .data$effect_scale,
          .data$metric_slot,
          .data$result_status
        ),
        "; n = ",
        format_sample(.data$participant_days, .data$participants, .data$sites)
      ),
      scenario_label = factor(.data$scenario_label, levels = scenarios)
    ) |>
    arrange(.data$metric_slot, .data$scenario_label)
  rows <- split(data, data$metric_slot)
  matrices <- lapply(rows, function(row) {
    c(row$manuscript_name[[1L]], row$Result)
  })
  matrix(unlist(matrices), nrow = 15L, byrow = TRUE)
}

semantic_and_reader_audit <- function() {
  semantic_dir <- normalizePath(
    Sys.getenv("GT_HTML_SEMANTIC_AUDIT_DIR", unset = ""),
    winslash = "/",
    mustWork = TRUE
  )
  summary_path <- file.path(
    semantic_dir,
    "gt_html_semantic_post_render_summary.csv"
  )
  summary <- readr::read_csv(summary_path, show_col_types = FALSE)
  if (
    nrow(summary) != 1L ||
      summary$target !=
        "_build/nathealth/notebooks/hypotheses/H06_daily.html" ||
      !summary$disposition %in% c("REPAIRED", "ALREADY_VALID") ||
      summary$table_count != 14L
  ) {
    stop("The semantic-hook summary is not acceptable.", call. = FALSE)
  }
  file.copy(
    summary_path,
    file.path(evidence_dir, "gt_html_semantic_post_render_summary.csv"),
    overwrite = TRUE
  )

  final_raw <- readBin(html_path, "raw", n = file.info(html_path)$size)
  if (summary$disposition == "REPAIRED") {
    engine <- new.env(parent = globalenv())
    sys.source(
      file.path(
        root,
        "scripts/report_harmonization/repair_gt_html_semantics.R"
      ),
      envir = engine
    )
    ledger_path <- file.path(semantic_dir, summary$ledger_file)
    ledger <- readr::read_csv(ledger_path, show_col_types = FALSE)
    reversed_raw <- engine$apply_raw_replacements(
      final_raw,
      ledger,
      reverse = TRUE
    )
    reapplied_raw <- engine$apply_raw_replacements(
      reversed_raw,
      ledger,
      reverse = FALSE
    )
    semantic_reverse <- tibble(
      check = c(
        "summary post hash equals final HTML",
        "reverse hash equals pre-hook hash",
        "forward reapplication equals final HTML",
        "ledger row count equals substitutions",
        "ledger ID count equals summary",
        "ledger headers count equals summary"
      ),
      observed = c(
        sha256_raw(final_raw),
        sha256_raw(reversed_raw),
        sha256_raw(reapplied_raw),
        nrow(ledger),
        sum(ledger$attribute == "id"),
        sum(ledger$attribute == "headers")
      ),
      expected = c(
        summary$post_sha256,
        summary$pre_sha256,
        summary$post_sha256,
        summary$total_substitutions,
        summary$id_count,
        summary$headers_count
      ),
      status = "PASS"
    )
    if (
      !all(
        as.character(semantic_reverse$observed) ==
          as.character(semantic_reverse$expected)
      ) ||
        !identical(final_raw, reapplied_raw)
    ) {
      stop(
        "Semantic repair did not reverse and reapply exactly.",
        call. = FALSE
      )
    }
    file.copy(
      ledger_path,
      file.path(evidence_dir, basename(ledger_path)),
      overwrite = TRUE
    )
  } else {
    reversed_raw <- final_raw
    semantic_reverse <- tibble(
      check = "already-valid semantic disposition",
      observed = summary$disposition,
      expected = "ALREADY_VALID",
      status = "PASS"
    )
  }
  write_evidence(semantic_reverse, "semantic_reverse_audit.csv")

  pre_document <- xml2::read_html(rawToChar(reversed_raw))
  post_document <- xml2::read_html(rawToChar(final_raw))
  pre_main <- rvest::html_elements(pre_document, "main#quarto-document-content")
  post_main <- rvest::html_elements(
    post_document,
    "main#quarto-document-content"
  )
  if (length(pre_main) != 1L || length(post_main) != 1L) {
    stop("The rendered document has no unique main element.", call. = FALSE)
  }
  pre_main <- pre_main[[1L]]
  post_main <- post_main[[1L]]
  semantic_invariance <- tibble(
    check = c(
      "whole-document visible text",
      "main visible text",
      "element sequence",
      "link sequence",
      "caption sequence",
      "source-note sequence"
    ),
    before = c(
      sha256_text(xml2::xml_text(pre_document)),
      sha256_text(xml2::xml_text(pre_main)),
      sha256_text(paste(
        xml2::xml_name(xml2::xml_find_all(pre_document, "//*")),
        collapse = "|"
      )),
      sha256_text(paste(
        xml2::xml_attr(xml2::xml_find_all(pre_document, "//a[@href]"), "href"),
        collapse = "|"
      )),
      sha256_text(paste(
        vapply(
          rvest::html_elements(pre_main, "figcaption.quarto-float-caption"),
          clean_text,
          character(1)
        ),
        collapse = "|"
      )),
      sha256_text(paste(
        vapply(
          rvest::html_elements(pre_main, ".gt_sourcenotes"),
          clean_text,
          character(1)
        ),
        collapse = "|"
      ))
    ),
    after = c(
      sha256_text(xml2::xml_text(post_document)),
      sha256_text(xml2::xml_text(post_main)),
      sha256_text(paste(
        xml2::xml_name(xml2::xml_find_all(post_document, "//*")),
        collapse = "|"
      )),
      sha256_text(paste(
        xml2::xml_attr(xml2::xml_find_all(post_document, "//a[@href]"), "href"),
        collapse = "|"
      )),
      sha256_text(paste(
        vapply(
          rvest::html_elements(post_main, "figcaption.quarto-float-caption"),
          clean_text,
          character(1)
        ),
        collapse = "|"
      )),
      sha256_text(paste(
        vapply(
          rvest::html_elements(post_main, ".gt_sourcenotes"),
          clean_text,
          character(1)
        ),
        collapse = "|"
      ))
    )
  ) |>
    mutate(status = ifelse(.data$before == .data$after, "PASS", "FAIL"))
  if (!all(semantic_invariance$status == "PASS")) {
    stop(
      "The semantic hook changed visible or structural content.",
      call. = FALSE
    )
  }
  write_evidence(semantic_invariance, "semantic_invariance_audit.csv")

  expected_tables <- c(
    "tbl-h06-daily-analysis-roles",
    "tbl-h06-daily-fdr-families",
    "tbl-h06-daily-primary-matrix",
    "tbl-h06-daily-primary-site-interactions",
    "tbl-h06-daily-placement-work-free",
    "tbl-h06-daily-placement-activity",
    "tbl-h06-daily-placement-sleep",
    "tbl-h06-daily-gap-decision-changes",
    "tbl-h06-daily-joint-family-summary",
    "tbl-h06-daily-joint-stability-limitations",
    "tbl-h06-daily-joint-site-interactions",
    "tbl-h06-daily-temporal-gamm",
    "tbl-h06-daily-main-comparison",
    "tbl-h06-daily-diagnostic-summary"
  )
  expected_captions <- c(
    "Analysis roles and exact fitted-sample ranges.",
    "Twelve fixed 15-slot FDR families.",
    "Primary near-eye predictor-specific participant-day associations.",
    paste(
      "Site-average contrasts and site adjustment factors for primary",
      "interaction blocks retained by the global FDR rule."
    ),
    "Near-eye, chest, and paired/common estimates for Free versus Work day.",
    paste(
      "Near-eye, chest, and paired/common estimates for Active versus",
      "Sedentary status."
    ),
    paste(
      "Near-eye, chest, and paired/common estimates per additional hour of",
      "previous-night sleep."
    ),
    paste(
      "Primary versus gap-timing-unaware association decisions that crossed",
      "the FDR threshold."
    ),
    "Exploratory mutually adjusted daily-model FDR families.",
    "Covariate-adjustment shifts of at least one common-sample standard error.",
    paste(
      "Site-specific contrasts for conditionally supported exploratory",
      "interaction blocks."
    ),
    "Exploratory primary near-eye 30-minute GAMM summaries.",
    "Selected main hourly H06 versus daily mean-melEDI associations.",
    "Model-check and sensitivity classifications."
  )
  table_endpoints <- rvest::html_elements(
    post_main,
    '.quarto-float[id^="tbl-h06-daily-"]'
  )
  table_endpoints <- table_endpoints[outside_source_modal(table_endpoints)]
  table_ids <- rvest::html_attr(table_endpoints, "id")
  table_audit <- bind_rows(lapply(seq_along(table_endpoints), function(index) {
    endpoint_node <- table_endpoints[[index]]
    table <- rvest::html_element(endpoint_node, "table.gt_table")
    caption <- clean_text(rvest::html_element(
      endpoint_node,
      "figcaption.quarto-float-caption"
    ))
    tibble(
      order = index,
      endpoint = table_ids[[index]],
      native_gt_count = length(rvest::html_elements(
        endpoint_node,
        "table.gt_table"
      )),
      caption_count = length(rvest::html_elements(
        endpoint_node,
        "figcaption.quarto-float-caption"
      )),
      source_note_count = length(rvest::html_elements(
        endpoint_node,
        ".gt_sourcenotes"
      )),
      caption = caption,
      expected_caption = expected_captions[[index]],
      caption_matches = grepl(
        expected_captions[[index]],
        caption,
        fixed = TRUE
      ),
      data_rows = sum(vapply(
        rvest::html_elements(table, "tbody tr"),
        function(row) length(rvest::html_elements(row, ".gt_row")) > 0L,
        logical(1)
      )),
      status = "PASS"
    )
  }))
  if (
    !identical(table_ids, expected_tables) ||
      nrow(table_audit) != 14L ||
      !all(table_audit$native_gt_count == 1L) ||
      !all(table_audit$caption_count == 1L) ||
      !all(table_audit$source_note_count == 1L) ||
      !all(table_audit$caption_matches)
  ) {
    stop("The 14-table endpoint contract failed.", call. = FALSE)
  }
  write_evidence(table_audit, "table_endpoint_audit.csv")

  placement <- readr::read_csv(
    input_paths[["placement"]],
    show_col_types = FALSE
  )
  placement_contract <- tribble(
    ~table_id,
    ~predictor_id,
    "tbl-h06-daily-placement-work-free",
    "work_free_day",
    "tbl-h06-daily-placement-activity",
    "activity_status",
    "tbl-h06-daily-placement-sleep",
    "previous_sleep_duration_centered_h"
  )
  placement_rows <- lapply(seq_len(nrow(placement_contract)), function(index) {
    table_id <- placement_contract$table_id[[index]]
    predictor_id <- placement_contract$predictor_id[[index]]
    table <- rvest::html_element(
      post_main,
      paste0("#", table_id, " table.gt_table")
    )
    candidate_rows <- rvest::html_elements(table, "tbody tr")
    data_rows <- candidate_rows[vapply(
      candidate_rows,
      function(row) length(rvest::html_elements(row, ".gt_row")) > 0L,
      logical(1)
    )]
    actual <- do.call(
      rbind,
      lapply(data_rows, function(row) {
        cells <- rvest::html_elements(row, ".gt_row")
        vapply(cells, clean_text, character(1))
      })
    )
    expected <- expected_placement_matrix(placement, predictor_id)
    headers <- vapply(
      rvest::html_elements(table, "thead th.gt_col_heading"),
      clean_text,
      character(1)
    )
    expected_headers <- c(
      "Metric",
      "Primary near eye, all available",
      "Complementary chest, all available",
      "Paired/common near eye",
      "Paired/common chest"
    )
    tibble(
      table_id = table_id,
      predictor_id = predictor_id,
      metric_rows = nrow(actual),
      placement_columns = ncol(actual) - 1L,
      source_rows = sum(placement$predictor_id == predictor_id),
      source_metric_slots = n_distinct(placement$metric_slot[
        placement$predictor_id == predictor_id
      ]),
      source_scenarios = n_distinct(placement$scenario_label[
        placement$predictor_id == predictor_id
      ]),
      headers_match = identical(headers, expected_headers),
      body_matches_source = identical(actual, expected),
      body_sha256 = sha256_text(paste(actual, collapse = "|")),
      status = ifelse(
        nrow(actual) == 15L &
          ncol(actual) == 5L &
          identical(headers, expected_headers) &
          identical(actual, expected),
        "PASS",
        "FAIL"
      )
    )
  })
  placement_audit <- bind_rows(placement_rows)
  if (
    !all(placement_audit$status == "PASS") ||
      n_distinct(placement_audit$body_sha256) != 3L
  ) {
    stop(
      "Tables 5 through 7 do not reconcile predictor by predictor.",
      call. = FALSE
    )
  }
  write_evidence(placement_audit, "placement_table_reconciliation.csv")

  expected_figures <- c(
    "fig-h06-daily-primary-ratio",
    "fig-h06-daily-primary-absolute",
    "fig-h06-daily-fdr-overview",
    "fig-h06-daily-primary-site-deviations",
    "fig-h06-daily-temporal-gamm"
  )
  figure_files <- c(
    unname(figure_names[c("ratio_png", "absolute_png", "fdr_png", "site_png")]),
    basename(figure5_path)
  )
  source_files <- c(
    basename(input_paths[["ratio"]]),
    basename(input_paths[["absolute"]]),
    basename(input_paths[["fdr"]]),
    basename(input_paths[["site"]]),
    "H06_daily_temporal_h02_primary_context_functions_figure_source.csv"
  )
  source_hashes <- c(
    unname(expected_input_hashes[c("ratio", "absolute", "fdr", "site")]),
    "4c104c16734f5b23d02b864fdc90aee445538823e41fb0119e2de7ac9bd4ef63"
  )
  figure_hashes <- c(
    vapply(
      figure_paths[c("ratio_png", "absolute_png", "fdr_png", "site_png")],
      sha256_file,
      character(1)
    ),
    figure5_hash
  )
  figure_endpoints <- rvest::html_elements(
    post_main,
    '.quarto-float[id^="fig-h06-daily-"]'
  )
  figure_endpoints <- figure_endpoints[outside_source_modal(figure_endpoints)]
  figure_ids <- rvest::html_attr(figure_endpoints, "id")
  main_hrefs <- rvest::html_attr(
    rvest::html_elements(post_main, "a[href]"),
    "href"
  )
  figure_audit <- bind_rows(lapply(
    seq_along(figure_endpoints),
    function(index) {
      endpoint_node <- figure_endpoints[[index]]
      image <- rvest::html_element(endpoint_node, "img")
      src <- rvest::html_attr(image, "src")
      encoded <- sub("^data:image/png;base64,", "", src)
      embedded_raw <- base64enc::base64decode(encoded)
      durable_path <- file.path(
        root,
        "artifacts/10_figures/H06_daily",
        figure_files[[index]]
      )
      source_path <- file.path(
        root,
        "artifacts/11_source_data/H06_daily",
        source_files[[index]]
      )
      tibble(
        order = index,
        endpoint = figure_ids[[index]],
        image_count = length(rvest::html_elements(endpoint_node, "img")),
        caption_count = length(rvest::html_elements(
          endpoint_node,
          "figcaption.quarto-float-caption"
        )),
        caption = clean_text(rvest::html_element(
          endpoint_node,
          "figcaption.quarto-float-caption"
        )),
        alt = rvest::html_attr(image, "alt"),
        embedded_png = startsWith(src, "data:image/png;base64,"),
        embedded_sha256 = sha256_raw(embedded_raw),
        durable_sha256 = sha256_file(durable_path),
        expected_figure_sha256 = figure_hashes[[index]],
        source_sha256 = sha256_file(source_path),
        expected_source_sha256 = source_hashes[[index]],
        paired_source_links = sum(grepl(
          source_files[[index]],
          main_hrefs,
          fixed = TRUE
        )),
        status = "PASS"
      )
    }
  )) |>
    mutate(
      status = ifelse(
        .data$image_count == 1L &
          .data$caption_count == 1L &
          nzchar(.data$caption) &
          !is.na(.data$alt) &
          nzchar(.data$alt) &
          .data$embedded_png &
          .data$embedded_sha256 == .data$durable_sha256 &
          .data$durable_sha256 == .data$expected_figure_sha256 &
          .data$source_sha256 == .data$expected_source_sha256 &
          .data$paired_source_links >= 1L,
        "PASS",
        "FAIL"
      )
    )
  if (
    !identical(figure_ids, expected_figures) ||
      !all(figure_audit$status == "PASS")
  ) {
    stop("The five-figure endpoint contract failed.", call. = FALSE)
  }
  write_evidence(figure_audit, "figure_endpoint_audit.csv")

  all_ids <- rvest::html_attr(rvest::html_elements(post_document, "[id]"), "id")
  all_ids <- all_ids[!is.na(all_ids) & nzchar(all_ids)]
  duplicate_ids <- unique(all_ids[duplicated(all_ids)])
  duplicate_audit <- tibble(
    document_ids = length(all_ids),
    unique_document_ids = n_distinct(all_ids),
    duplicate_ids = length(duplicate_ids),
    duplicate_values = paste(duplicate_ids, collapse = " | "),
    status = ifelse(length(duplicate_ids) == 0L, "PASS", "FAIL")
  )
  if (length(duplicate_ids)) {
    stop("The rendered document contains duplicate IDs.", call. = FALSE)
  }
  write_evidence(duplicate_audit, "duplicate_id_audit.csv")

  header_audit <- bind_rows(lapply(table_endpoints, function(endpoint) {
    endpoint_id <- rvest::html_attr(endpoint, "id")
    table <- rvest::html_element(endpoint, "table.gt_table")
    nodes <- rvest::html_elements(table, "[headers]")
    bind_rows(lapply(nodes, function(node) {
      tokens <- strsplit(
        trimws(rvest::html_attr(node, "headers")),
        "[[:space:]]+"
      )[[1L]]
      bind_rows(lapply(tokens[nzchar(tokens)], function(token) {
        matches <- xml2::xml_find_all(table, sprintf(".//*[@id='%s']", token))
        tibble(
          endpoint = endpoint_id,
          element = xml2::xml_name(node),
          header_token = token,
          matches_in_table = length(matches),
          resolves_to_th = length(matches) == 1L &&
            identical(xml2::xml_name(matches[[1L]]), "th"),
          status = ifelse(
            length(matches) == 1L &&
              identical(xml2::xml_name(matches[[1L]]), "th"),
            "PASS",
            "FAIL"
          )
        )
      }))
    }))
  }))
  if (!nrow(header_audit) || !all(header_audit$status == "PASS")) {
    stop("A table header token does not resolve once to th.", call. = FALSE)
  }
  write_evidence(header_audit, "table_header_reference_audit.csv")

  main_anchors <- rvest::html_elements(post_main, "a[href]")
  main_anchors <- main_anchors[outside_source_modal(main_anchors)]
  main_hrefs <- rvest::html_attr(main_anchors, "href")
  main_link_text <- vapply(main_anchors, clean_text, character(1))
  forbidden_link <- grepl("[.]qmd($|[?#])", main_hrefs, ignore.case = TRUE) |
    grepl("file://|_build|/Users/", main_hrefs)
  local_link <- !grepl(
    "^(https?|mailto|tel|data):",
    main_hrefs,
    ignore.case = TRUE
  )
  resolved <- rep("", length(main_hrefs))
  exists <- rep(TRUE, length(main_hrefs))
  for (index in which(local_link)) {
    path_part <- sub("[?#].*$", "", main_hrefs[[index]])
    resolved[[index]] <- if (!nzchar(path_part)) {
      html_path
    } else if (startsWith(path_part, "/")) {
      file.path(build_root, sub("^/+", "", path_part))
    } else {
      file.path(dirname(html_path), URLdecode(path_part))
    }
    exists[[index]] <- file.exists(resolved[[index]])
  }
  link_audit <- tibble(
    order = seq_along(main_hrefs),
    link_text = main_link_text,
    href = main_hrefs,
    local = local_link,
    resolved_path = resolved,
    target_exists = exists,
    forbidden_internal_target = forbidden_link,
    status = ifelse(!forbidden_link & exists, "PASS", "FAIL")
  )
  if (!all(link_audit$status == "PASS")) {
    stop("A reader link is forbidden or unresolved.", call. = FALSE)
  }
  write_evidence(link_audit, "reader_link_audit.csv")

  dynamic_text <- c(
    "hourly H06 analysis",
    "analysis-preparation and provenance companion",
    "preregistration-deviations page",
    "main H06 report",
    "primary predictor scope",
    "model and site structure",
    "multiplicity and contrast decisions"
  )
  dynamic_href <- c(
    "../../notebooks/hypotheses/H06.html",
    "../../audit/hypotheses/H06_daily/H06_daily_analysis_preparation.html",
    "../../notebooks/preregistration_deviations.html#dev-015",
    "../../notebooks/hypotheses/H06.html",
    "../../notebooks/preregistration_deviations.html#dev-030",
    "../../notebooks/preregistration_deviations.html#dev-031",
    "../../notebooks/preregistration_deviations.html#dev-032"
  )
  dynamic_audit <- bind_rows(lapply(seq_along(dynamic_text), function(index) {
    matches <- which(
      link_audit$link_text == dynamic_text[[index]] &
        link_audit$href == dynamic_href[[index]]
    )
    tibble(
      order = index,
      link_text = dynamic_text[[index]],
      href = dynamic_href[[index]],
      matches = length(matches),
      status = ifelse(length(matches) == 1L, "PASS", "FAIL")
    )
  }))
  if (nrow(dynamic_audit) != 7L || !all(dynamic_audit$status == "PASS")) {
    stop("The seven dynamic links are not exact.", call. = FALSE)
  }
  write_evidence(dynamic_audit, "dynamic_link_audit.csv")

  main_text <- clean_text(post_main)
  site_names <- c(
    "Borås (SE)",
    "Delft (NL)",
    "Dortmund (DE)",
    "Tübingen (DE)",
    "Munich (DE)",
    "Madrid (ES)",
    "Izmir (TR)",
    "San José (CR)",
    "Kumasi (GH)"
  )
  sites_present <- vapply(
    site_names,
    grepl,
    logical(1),
    x = main_text,
    fixed = TRUE
  )
  active_text <- vapply(
    rvest::html_elements(post_document, "a.sidebar-link.active"),
    clean_text,
    character(1)
  )
  defects <- sum(vapply(
    c(
      ".cell-output-error",
      ".cell-output-warning",
      ".cell-output-stderr",
      ".quarto-error",
      ".quarto-warning",
      "pre.stderr"
    ),
    function(selector) length(rvest::html_elements(post_main, selector)),
    integer(1)
  ))
  unresolved_crossref <- grepl(
    "[?]@(tbl|fig|sec|eq)-|@(tbl|fig|sec|eq)-[A-Za-z0-9_-]+",
    main_text,
    perl = TRUE
  )
  raw_trace <- any(vapply(
    c("processing file:", "output file:", "Quitting from lines", "pandoc --"),
    grepl,
    logical(1),
    x = main_text,
    fixed = TRUE
  ))
  reciprocal_document <- xml2::read_html(companion_html)
  reciprocal_hrefs <- rvest::html_attr(
    rvest::html_elements(reciprocal_document, "a[href]"),
    "href"
  )
  reciprocal <- sum(grepl(
    "notebooks/hypotheses/H06_daily[.]html$",
    reciprocal_hrefs
  ))
  reader_contract <- tibble(
    check = c(
      "native gt tables",
      "figures",
      "dynamic links",
      "answer note callout",
      "hourly-main complementary-daily hierarchy",
      "reciprocal companion link",
      "active navigation",
      "country-coded sites",
      "embedded execution defects",
      "unresolved cross-reference",
      "raw execution trace"
    ),
    observed = c(
      nrow(table_audit),
      nrow(figure_audit),
      nrow(dynamic_audit),
      sum(grepl(
        "Answer in brief",
        vapply(
          rvest::html_elements(post_main, ".callout-note"),
          clean_text,
          character(1)
        ),
        fixed = TRUE
      )),
      grepl("selected main H06 result", main_text, fixed = TRUE) &&
        grepl("complementary", main_text, ignore.case = TRUE),
      reciprocal,
      paste(active_text, collapse = "|"),
      sum(sites_present),
      defects,
      unresolved_crossref,
      raw_trace
    ),
    expected = c(
      14,
      5,
      7,
      1,
      TRUE,
      1,
      "H06 complementary daily results",
      9,
      0,
      FALSE,
      FALSE
    )
  ) |>
    mutate(
      status = ifelse(
        as.character(.data$observed) == as.character(.data$expected),
        "PASS",
        "FAIL"
      )
    )
  if (!all(reader_contract$status == "PASS")) {
    stop("The reader content contract failed.", call. = FALSE)
  }
  write_evidence(reader_contract, "reader_contract_audit.csv")

  list(
    semantic_summary = summary,
    table_audit = table_audit,
    placement_audit = placement_audit,
    figure_audit = figure_audit,
    header_audit = header_audit,
    link_audit = link_audit,
    dynamic_audit = dynamic_audit,
    reader_contract = reader_contract
  )
}

classify_build_delta <- function(before, after) {
  delta <- inventory_comparison(before, after) |>
    filter(.data$delta != "UNCHANGED") |>
    mutate(
      classification = "UNCLASSIFIED",
      source_relative_path = "",
      source_identical = NA
    )
  if (!nrow(delta)) {
    stop("The render produced no build delta.", call. = FALSE)
  }
  mtime <- delta$delta == "MTIME_ONLY"
  delta$classification[mtime] <- "MTIME_ONLY_FRAMEWORK_TOUCH"
  delta$source_identical[mtime] <- TRUE

  result_html <- delta$relative_path ==
    "_build/nathealth/notebooks/hypotheses/H06_daily.html"
  delta$classification[result_html] <- "EXPECTED_RESULT_HTML_TRANSITION"
  delta$source_identical[result_html] <- TRUE

  integration <- delta$relative_path %in%
    c(
      "_build/nathealth/search.json",
      "_build/nathealth/sitemap.xml"
    )
  delta$classification[integration] <- "EXPECTED_SITE_INTEGRATION"
  delta$source_identical[integration] <- TRUE

  build_prefix <- "_build/nathealth/"
  for (index in which(delta$classification == "UNCLASSIFIED")) {
    relative <- delta$relative_path[[index]]
    if (!startsWith(relative, build_prefix)) {
      next
    }
    source_relative <- substring(relative, nchar(build_prefix) + 1L)
    source_path <- file.path(root, source_relative)
    if (
      file.exists(source_path) &&
        !is.na(delta$sha256_after[[index]]) &&
        identical(sha256_file(source_path), delta$sha256_after[[index]])
    ) {
      delta$classification[[index]] <- "SOURCE_IDENTICAL_TARGET_RESOURCE"
      delta$source_relative_path[[index]] <- source_relative
      delta$source_identical[[index]] <- TRUE
    }
  }
  delta <- delta |>
    mutate(
      status = ifelse(
        .data$classification != "UNCLASSIFIED" &
          .data$delta != "REMOVED" &
          !is.na(.data$source_identical) &
          .data$source_identical,
        "PASS",
        "FAIL"
      )
    )
  if (!all(delta$status == "PASS")) {
    stop("The build contains an unclassified content change.", call. = FALSE)
  }
  delta
}

if (phase == "postrender") {
  verify_promoted_display()
  semantic <- semantic_and_reader_audit()
  build_post <- collect_build("postrender")
  protected_post <- collect_protected("postrender")
  build_pre <- readr::read_csv(
    file.path(evidence_dir, "build_inventory_prerender.csv"),
    show_col_types = FALSE
  )
  protected_pre <- readr::read_csv(
    file.path(evidence_dir, "protected_inventory_prerender.csv"),
    show_col_types = FALSE
  )
  build_delta <- classify_build_delta(build_pre, build_post)
  write_evidence(build_delta, "build_delta_postrender.csv")
  authorized_evidence_path <- file.path(
    root,
    paste0(
      "audit/report_harmonization/owner_orders/",
      "48d_h06_daily_authorized_evidence_additions.csv"
    )
  )
  authorized_evidence <- readr::read_csv(
    authorized_evidence_path,
    show_col_types = FALSE
  )
  authorized_evidence_paths <- file.path(root, authorized_evidence$path)
  if (
    nrow(authorized_evidence) != 17L ||
      anyDuplicated(authorized_evidence$path) ||
      any(
        authorized_evidence$path == relative_path(authorized_evidence_path)
      ) ||
      !all(file.exists(authorized_evidence_paths)) ||
      !identical(
        unname(vapply(authorized_evidence_paths, sha256_file, character(1L))),
        authorized_evidence$sha256
      ) ||
      !identical(
        as.numeric(file.info(authorized_evidence_paths)$size),
        as.numeric(authorized_evidence$bytes)
      )
  ) {
    stop(
      "The authorized evidence-addition manifest does not resolve.",
      call. = FALSE
    )
  }
  authorized_evidence_sha <- setNames(
    authorized_evidence$sha256,
    authorized_evidence$path
  )
  authorized_evidence_bytes <- setNames(
    as.numeric(authorized_evidence$bytes),
    authorized_evidence$path
  )
  authorized_verifier <- read_authorized_verifier_transition()
  protected_delta <- inventory_comparison(protected_pre, protected_post) |>
    mutate(
      expected_result_transition = .data$relative_path ==
        "_build/nathealth/notebooks/hypotheses/H06_daily.html" &
        .data$delta == "CHANGED_CONTENT",
      expected_evidence_addition = .data$delta == "ADDED" &
        .data$relative_path %in% authorized_evidence$path &
        .data$sha256_after == authorized_evidence_sha[.data$relative_path] &
        .data$bytes_after == authorized_evidence_bytes[.data$relative_path],
      expected_verifier_transition = .data$delta == "CHANGED_CONTENT" &
        .data$relative_path == authorized_verifier$path &
        .data$sha256_before == authorized_verifier$pre_sha256 &
        .data$bytes_before == authorized_verifier$pre_bytes &
        .data$sha256_after == authorized_verifier$post_sha256 &
        .data$bytes_after == authorized_verifier$post_bytes,
      status = ifelse(
        .data$delta %in%
          c("UNCHANGED", "MTIME_ONLY") |
          .data$expected_result_transition |
          .data$expected_evidence_addition |
          .data$expected_verifier_transition,
        "PASS",
        "FAIL"
      )
    )
  observed_evidence_additions <- sort(protected_delta$relative_path[
    protected_delta$expected_evidence_addition
  ])
  if (
    !identical(observed_evidence_additions, sort(authorized_evidence$path)) ||
      sum(protected_delta$expected_verifier_transition) != 1L ||
      !all(protected_delta$status == "PASS")
  ) {
    stop("A protected project member changed unexpectedly.", call. = FALSE)
  }
  write_evidence(protected_delta, "protected_reconciliation_postrender.csv")
  write_evidence(
    tibble(
      phase = "postrender",
      html_sha256 = sha256_file(html_path),
      html_bytes = as.numeric(file.info(html_path)$size),
      semantic_disposition = semantic$semantic_summary$disposition,
      semantic_substitutions = semantic$semantic_summary$total_substitutions,
      tables = nrow(semantic$table_audit),
      placement_tables = nrow(semantic$placement_audit),
      figures = nrow(semantic$figure_audit),
      dynamic_links = nrow(semantic$dynamic_audit),
      build_deltas = nrow(build_delta),
      protected_members = nrow(protected_post),
      status = "PASS"
    ),
    "postrender_nonvisual_summary.csv"
  )
  cat(sprintf(
    paste0(
      "ORDER48A_POSTRENDER=PASS tables=%d figures=%d links=%d ",
      "build_delta=%d protected=%d\n"
    ),
    nrow(semantic$table_audit),
    nrow(semantic$figure_audit),
    nrow(semantic$dynamic_audit),
    nrow(build_delta),
    nrow(protected_post)
  ))
}

if (phase == "postqa") {
  required_visual <- c(
    "final_visual_qa.csv",
    "loopback_lifecycle.csv",
    "browser_console_warn_error.json",
    "visual_1440x1000.png",
    "visual_708x1000.png",
    "visual_720x500.png",
    "visual_figures_170mm.png"
  )
  if (!all(file.exists(file.path(evidence_dir, required_visual)))) {
    stop("The complete secure-loopback evidence is missing.", call. = FALSE)
  }
  visual <- readr::read_csv(
    file.path(evidence_dir, "final_visual_qa.csv"),
    show_col_types = FALSE
  )
  lifecycle <- readr::read_csv(
    file.path(evidence_dir, "loopback_lifecycle.csv"),
    show_col_types = FALSE
  )
  if (!all(visual$status == "PASS") || !all(lifecycle$status == "PASS")) {
    stop("The secure-loopback QA is not acceptable.", call. = FALSE)
  }

  build_postqa <- collect_build("postqa")
  protected_postqa <- collect_protected("postqa")
  build_postrender <- readr::read_csv(
    file.path(evidence_dir, "build_inventory_postrender.csv"),
    show_col_types = FALSE
  )
  protected_postrender <- readr::read_csv(
    file.path(evidence_dir, "protected_inventory_postrender.csv"),
    show_col_types = FALSE
  )
  build_reconciliation <- inventory_comparison(
    build_postrender,
    build_postqa
  ) |>
    mutate(
      status = ifelse(
        .data$delta %in% c("UNCHANGED", "MTIME_ONLY"),
        "PASS",
        "FAIL"
      )
    )
  protected_reconciliation <- inventory_comparison(
    protected_postrender,
    protected_postqa
  ) |>
    mutate(
      status = ifelse(
        .data$delta %in% c("UNCHANGED", "MTIME_ONLY"),
        "PASS",
        "FAIL"
      )
    )
  if (
    !all(build_reconciliation$status == "PASS") ||
      !all(protected_reconciliation$status == "PASS")
  ) {
    stop("The build or protected set changed during visual QA.", call. = FALSE)
  }
  write_evidence(build_reconciliation, "build_reconciliation_postqa.csv")
  write_evidence(
    protected_reconciliation,
    "protected_reconciliation_postqa.csv"
  )

  completion_path <- file.path(
    evidence_dir,
    "order48a_combined_completion.md"
  )
  completion <- c(
    "# REPORT-018 H06_daily order 48a combined completion",
    "",
    paste("Date:", format(Sys.Date(), "%Y-%m-%d")),
    "",
    "Status: `PASS`",
    "",
    paste0(
      "The exact placement-table predicate repair, frozen-CSV display refresh, ",
      "one recoverable six-file promotion, one result render, semantic reversal, ",
      "predictor-specific table reconciliation, and secure-loopback review all passed."
    ),
    "",
    paste0("Final result HTML SHA-256: `", sha256_file(html_path), "`."),
    paste0("Final QMD SHA-256: `", sha256_file(qmd_path), "`."),
    paste0(
      "Current display manifest SHA-256: `",
      sha256_file(display_manifest_path),
      "`."
    ),
    "",
    "No model, fit, prediction, simulation, resampling, inferential result, source data, companion, profile, package, lockfile, ledger, or unrelated report was changed."
  )
  writeLines(completion, completion_path, useBytes = TRUE)

  manifest_path <- file.path(evidence_dir, "order48a_acceptance_manifest.csv")
  members <- sort(unique(c(
    list_files(evidence_dir, exclude_prefix = manifest_path),
    qmd_path,
    refresh_path,
    verifier_path,
    display_manifest_path,
    figure_paths,
    figure5_path,
    input_paths,
    html_path,
    companion_qmd,
    companion_html,
    profile_path
  )))
  members <- members[relative_path(members) != relative_path(manifest_path)]
  manifest <- tibble(
    path = relative_path(members),
    role = ifelse(
      startsWith(relative_path(members), paste0(evidence_relative, "/")),
      "order-48a acceptance evidence",
      "pinned implementation, input, display, or endpoint"
    ),
    sha256 = vapply(members, sha256_file, character(1)),
    bytes = as.numeric(file.info(members)$size)
  )
  if (
    anyDuplicated(manifest$path) ||
      any(manifest$path == relative_path(manifest_path))
  ) {
    stop("The final manifest is circular or duplicated.", call. = FALSE)
  }
  write_evidence(manifest, basename(manifest_path))
  cat(sprintf(
    paste0(
      "ORDER48A_POSTQA=PASS visual=%d build=%d protected=%d ",
      "manifest=%d html=%s\n"
    ),
    nrow(visual),
    nrow(build_postqa),
    nrow(protected_postqa),
    nrow(manifest),
    sha256_file(html_path)
  ))
}
