#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE)

stopifnot(identical(as.character(getRversion()), "4.6.1"))

suppressPackageStartupMessages({
  library(digest)
  library(readr)
})

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
setwd(root)

stage <- Sys.getenv("ORDER48_STAGE", unset = "prerender")
stopifnot(stage %in% c("prerender", "postrender", "postqa"))

evidence_relative <-
  "audit/hypotheses/H06_daily/report018_order48_result_render"
evidence_dir <- file.path(root, evidence_relative)
dir.create(evidence_dir, recursive = TRUE, showWarnings = FALSE)

sha256_file <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
}

write_evidence <- function(object, name) {
  utils::write.csv(
    object,
    file.path(evidence_dir, name),
    row.names = FALSE,
    na = "",
    fileEncoding = "UTF-8"
  )
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

inventory_paths <- function(paths, role = "inventory_member") {
  paths <- sort(unique(paths))
  links <- Sys.readlink(paths)
  paths <- normalizePath(
    paths,
    winslash = "/",
    mustWork = TRUE
  )
  info <- file.info(paths)
  stopifnot(length(paths) > 0L, all(!info$isdir))
  data.frame(
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
    symlink_target = links,
    stringsAsFactors = FALSE
  )
}

list_files <- function(path, exclude_prefix = character()) {
  if (!dir.exists(path)) return(character())
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

build_root <- file.path(root, "_build/nathealth")
build_paths <- list_files(build_root)
build_inventory <- inventory_paths(build_paths, "build_member")
build_inventory <- build_inventory[
  order(build_inventory$relative_path),
  ,
  drop = FALSE
]
write_evidence(
  build_inventory,
  paste0("build_inventory_", stage, ".csv")
)

build_symlinks <- build_inventory[build_inventory$is_symlink, , drop = FALSE]
write_evidence(
  build_symlinks,
  paste0("build_symlink_inventory_", stage, ".csv")
)

dispatch_path <- file.path(
  root,
  "audit/report_harmonization/report018_h06_daily_order48_dispatch_manifest.csv"
)
dispatch <- readr::read_csv(dispatch_path, show_col_types = FALSE)
matrix_relative <- "audit/report_harmonization/coordination_matrix.csv"
dispatch_hard <- dispatch[dispatch$path != matrix_relative, , drop = FALSE]

if (identical(stage, "prerender")) {
  dispatch_files <- file.path(root, dispatch_hard$path)
  dispatch_observed <- data.frame(
    path = dispatch_hard$path,
    expected_sha256 = dispatch_hard$sha256,
    observed_sha256 = vapply(dispatch_files, sha256_file, character(1)),
    expected_bytes = dispatch_hard$bytes,
    observed_bytes = as.numeric(file.info(dispatch_files)$size),
    hash_matches = FALSE,
    bytes_match = FALSE,
    status = "",
    stringsAsFactors = FALSE
  )
  dispatch_observed$hash_matches <-
    dispatch_observed$expected_sha256 == dispatch_observed$observed_sha256
  dispatch_observed$bytes_match <-
    dispatch_observed$expected_bytes == dispatch_observed$observed_bytes
  dispatch_observed$status <- ifelse(
    dispatch_observed$hash_matches & dispatch_observed$bytes_match,
    "PASS",
    "FAIL"
  )
  write_evidence(dispatch_observed, "dispatch_reconciliation_prerender.csv")
  stopifnot(
    nrow(dispatch) == 47L,
    nrow(dispatch_hard) == 46L,
    !anyDuplicated(dispatch$path),
    all(dispatch_observed$status == "PASS")
  )
}

artifact_roots <- list.dirs(
  file.path(root, "artifacts"),
  recursive = FALSE,
  full.names = TRUE
)
artifact_roots <- file.path(artifact_roots, "H06_daily")
artifact_roots <- artifact_roots[dir.exists(artifact_roots)]

h06_daily_roots <- c(
  artifact_roots,
  file.path(root, "audit/hypotheses/H06_daily"),
  file.path(root, "scripts/hypotheses/H06_daily"),
  file.path(root, "tests/hypotheses/H06_daily")
)
h06_daily_paths <- unlist(
  lapply(
    h06_daily_roots,
    list_files,
    exclude_prefix = evidence_dir
  ),
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
dispatch_paths <- file.path(root, dispatch$path)

protected_paths <- sort(unique(c(
  h06_daily_paths,
  handoff_paths,
  ledger_paths,
  dispatch_paths,
  file.path(
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
)))
stopifnot(all(file.exists(protected_paths)), all(!dir.exists(protected_paths)))

protected_relative <- relative_path(protected_paths)
protected_role <- rep("h06_daily_protected", length(protected_paths))
protected_role[startsWith(protected_relative, "audit/ledgers/")] <-
  "central_ledger"
protected_role[protected_relative %in% dispatch$path] <-
  "dispatch_contract"
protected_role[protected_relative == matrix_relative] <-
  "dispatch_time_coordination_matrix"
protected_role[grepl(
  "^(notebooks/hypotheses/H06[.]qmd|audit/hypotheses/H06/|_build/nathealth/(notebooks/hypotheses/H06[.]html|audit/hypotheses/H06/))",
  protected_relative
)] <- "hourly_h06_endpoint"
protected_role[
  protected_relative == "_build/nathealth/notebooks/hypotheses/H06_daily.html"
] <-
  "expected_render_target"
protected_role[
  protected_relative ==
    paste0(
      "_build/nathealth/audit/hypotheses/H06_daily/",
      "H06_daily_analysis_preparation.html"
    )
] <- "held_companion_target"
protected_role[
  protected_relative %in%
    c(
      "_quarto-nathealth.yml",
      "_quarto.yml",
      "scripts/report_harmonization/post_render_gt_html_semantics.R",
      "scripts/report_harmonization/repair_gt_html_semantics.R",
      "scripts/pipeline/p_value_display.R",
      "config/site_display_registry.csv",
      "audit/report_harmonization/phase4_corpus_manifest.csv",
      "renv.lock"
    )
] <- "shared_protected"

protected_inventory <- inventory_paths(protected_paths, protected_role)
protected_inventory <- protected_inventory[
  order(protected_inventory$relative_path),
  ,
  drop = FALSE
]
write_evidence(
  protected_inventory,
  paste0("protected_inventory_", stage, ".csv")
)

if (identical(stage, "prerender")) {
  qmd_relative <- "notebooks/hypotheses/H06_daily.qmd"
  qmd_path <- file.path(root, qmd_relative)
  qmd_lines <- readLines(qmd_path, warn = FALSE, encoding = "UTF-8")
  qmd_text <- paste(qmd_lines, collapse = "\n")

  chunk_starts <- grep("^```\\{r(?:[ ,}])", qmd_lines, perl = TRUE)
  chunk_ends <- vapply(
    chunk_starts,
    function(start) {
      candidates <- which(
        seq_along(qmd_lines) > start & grepl("^```[[:space:]]*$", qmd_lines)
      )
      stopifnot(length(candidates) > 0L)
      candidates[[1L]]
    },
    integer(1)
  )
  chunk_rows <- lapply(seq_along(chunk_starts), function(index) {
    body_lines <- qmd_lines[
      (chunk_starts[[index]] + 1L):(chunk_ends[[index]] - 1L)
    ]
    label_lines <- grep("^#\\| label:[[:space:]]*", body_lines, value = TRUE)
    label <- if (length(label_lines)) {
      trimws(sub("^#\\| label:[[:space:]]*", "", label_lines[[1L]]))
    } else {
      ""
    }
    parsed <- tryCatch(
      {
        parse(text = body_lines, keep.source = TRUE)
        TRUE
      },
      error = function(error) FALSE
    )
    data.frame(
      order = index,
      start_line = chunk_starts[[index]],
      end_line = chunk_ends[[index]],
      label = label,
      parseable_r = parsed,
      stringsAsFactors = FALSE
    )
  })
  chunk_audit <- do.call(rbind, chunk_rows)
  write_evidence(chunk_audit, "source_chunk_audit_prerender.csv")

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
  table_labels <- chunk_audit$label[startsWith(chunk_audit$label, "tbl-")]

  figure_matches <- regmatches(
    qmd_text,
    gregexpr("\\{#fig-h06-daily-[^ }]+", qmd_text, perl = TRUE)
  )[[1L]]
  figure_labels <- sub("^\\{#", "", figure_matches)
  expected_figures <- c(
    "fig-h06-daily-primary-ratio",
    "fig-h06-daily-primary-absolute",
    "fig-h06-daily-fdr-overview",
    "fig-h06-daily-primary-site-deviations",
    "fig-h06-daily-temporal-gamm"
  )

  endpoint_audit <- rbind(
    data.frame(
      endpoint_type = "table",
      order = seq_along(table_labels),
      observed = table_labels,
      expected = expected_tables,
      exact_match = table_labels == expected_tables,
      stringsAsFactors = FALSE
    ),
    data.frame(
      endpoint_type = "figure",
      order = seq_along(figure_labels),
      observed = figure_labels,
      expected = expected_figures,
      exact_match = figure_labels == expected_figures,
      stringsAsFactors = FALSE
    )
  )
  write_evidence(endpoint_audit, "source_endpoint_contract_prerender.csv")

  qmd_link_matches <- regmatches(
    qmd_text,
    gregexpr(
      "\\[[^]]+\\]\\([^)]*[.]qmd(?:#[^)]*)?\\)",
      qmd_text,
      perl = TRUE
    )
  )[[1L]]
  qmd_link_targets <- sub("^.*\\(([^)]*)\\)$", "\\1", qmd_link_matches)
  expected_qmd_link_targets <- c(
    "H06.qmd",
    "../../audit/hypotheses/H06_daily/H06_daily_analysis_preparation.qmd",
    "../preregistration_deviations.qmd#dev-015",
    "H06.qmd",
    "../preregistration_deviations.qmd#dev-030",
    "../preregistration_deviations.qmd#dev-031",
    "../preregistration_deviations.qmd#dev-032"
  )
  qmd_link_audit <- data.frame(
    order = seq_along(qmd_link_targets),
    source_markdown = qmd_link_matches,
    observed_target = qmd_link_targets,
    expected_target = expected_qmd_link_targets,
    exact_match = qmd_link_targets == expected_qmd_link_targets,
    stringsAsFactors = FALSE
  )
  write_evidence(qmd_link_audit, "source_dynamic_links_prerender.csv")

  call_names <- function(expression) {
    found <- character()
    walk <- function(node) {
      if (is.call(node)) {
        head <- node[[1L]]
        call_name <- if (is.symbol(head)) {
          as.character(head)
        } else if (
          is.call(head) &&
            identical(as.character(head[[1L]]), "::") &&
            length(head) == 3L
        ) {
          paste0(as.character(head[[2L]]), "::", as.character(head[[3L]]))
        } else {
          ""
        }
        if (nzchar(call_name)) found <<- c(found, call_name)
        lapply(as.list(node)[-1L], walk)
      } else if (is.expression(node) || is.pairlist(node)) {
        lapply(as.list(node), walk)
      }
      invisible(NULL)
    }
    walk(expression)
    unique(found)
  }

  parsed_chunks <- lapply(seq_along(chunk_starts), function(index) {
    parse(
      text = qmd_lines[
        (chunk_starts[[index]] + 1L):(chunk_ends[[index]] - 1L)
      ]
    )
  })
  observed_calls <- sort(unique(unlist(lapply(parsed_chunks, call_names))))
  prohibited_bare <- c(
    "lm",
    "glm",
    "lmer",
    "glmer",
    "glmmTMB",
    "gam",
    "bam",
    "gamm",
    "brm",
    "predict",
    "emmeans",
    "contrast",
    "marginaleffects",
    "anova",
    "Anova",
    "waldtest",
    "linearHypothesis",
    "boot",
    "bootstrap",
    "simulate",
    "sample",
    "replicate",
    "p.adjust",
    "write.csv",
    "write_csv",
    "writeLines",
    "writeBin",
    "save",
    "saveRDS",
    "ggsave",
    "png",
    "pdf",
    "svg",
    "jpeg",
    "tiff",
    "dir.create",
    "file.create",
    "file.copy",
    "file.rename",
    "unlink",
    "system",
    "system2",
    "shell",
    "quarto_render",
    "render",
    "knit"
  )
  observed_bare <- sub("^.*::", "", observed_calls)
  prohibited_hits <- observed_calls[observed_bare %in% prohibited_bare]
  prohibited_audit <- data.frame(
    prohibited_call = prohibited_bare,
    observed = prohibited_bare %in% observed_bare,
    status = ifelse(prohibited_bare %in% observed_bare, "FAIL", "PASS"),
    stringsAsFactors = FALSE
  )
  write_evidence(
    prohibited_audit,
    "source_prohibited_call_audit_prerender.csv"
  )

  historical_gt_audit <- readr::read_csv(
    file.path(
      root,
      "audit/report_harmonization/phase4_h06_daily_gt_source_audit.csv"
    ),
    show_col_types = FALSE
  )
  stopifnot(
    nrow(chunk_audit) == 15L,
    all(chunk_audit$parseable_r),
    identical(table_labels, expected_tables),
    !anyDuplicated(table_labels),
    identical(figure_labels, expected_figures),
    !anyDuplicated(figure_labels),
    identical(qmd_link_targets, expected_qmd_link_targets),
    length(qmd_link_targets) == 7L,
    length(prohibited_hits) == 0L,
    nrow(historical_gt_audit) == 14L,
    identical(historical_gt_audit$label, expected_tables),
    all(historical_gt_audit$source_contract_complete),
    all(
      historical_gt_audit$source_sha256 ==
        "01213a193515c49419dcd1ed9cffcc070a88d639a7382e218275a89bd704cb08"
    )
  )

  package_names <- c("digest", "dplyr", "gt", "readr", "rvest", "xml2")
  versions <- data.frame(
    component = c("R", "Quarto", package_names),
    version = c(
      as.character(getRversion()),
      trimws(system2("quarto", "--version", stdout = TRUE)),
      vapply(
        package_names,
        function(package) {
          as.character(utils::packageVersion(package))
        },
        character(1)
      )
    ),
    stringsAsFactors = FALSE
  )
  write_evidence(versions, "versions_prerender.csv")
  stopifnot(
    versions$version[versions$component == "R"] == "4.6.1",
    versions$version[versions$component == "Quarto"] == "1.9.37"
  )

  preflight_status <- data.frame(
    check = c(
      "dispatch hard rows",
      "R chunks",
      "native gt table endpoints",
      "figure endpoints",
      "dynamic QMD links",
      "prohibited source calls",
      "build symlinks",
      "protected paths",
      "R version",
      "Quarto version"
    ),
    observed = c(
      nrow(dispatch_hard),
      nrow(chunk_audit),
      length(table_labels),
      length(figure_labels),
      length(qmd_link_targets),
      length(prohibited_hits),
      nrow(build_symlinks),
      nrow(protected_inventory),
      versions$version[versions$component == "R"],
      versions$version[versions$component == "Quarto"]
    ),
    expected = c(46L, 15L, 14L, 5L, 7L, 0L, 0L, "complete", "4.6.1", "1.9.37"),
    status = "PASS",
    stringsAsFactors = FALSE
  )
  write_evidence(preflight_status, "preflight_status.csv")
}

stopifnot(nrow(build_symlinks) == 0L)

cat(sprintf(
  paste0(
    "ORDER48_INVENTORY=PASS stage=%s build_files=%d build_symlinks=%d ",
    "protected_files=%d\n"
  ),
  stage,
  nrow(build_inventory),
  nrow(build_symlinks),
  nrow(protected_inventory)
))
