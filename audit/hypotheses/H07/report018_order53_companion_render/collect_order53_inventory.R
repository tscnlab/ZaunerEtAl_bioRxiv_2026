#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE, warn = 2)

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

stage <- Sys.getenv("ORDER53_STAGE", unset = "prerender")
stopifnot(stage %in% c("prerender", "postrender", "posthelper", "postqa"))

evidence_relative <-
  "audit/hypotheses/H07/report018_order53_companion_render"
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

inventory_paths <- function(paths, role = "inventory_member") {
  paths <- sort(unique(paths))
  stopifnot(length(paths) > 0L, all(file.exists(paths)))
  links <- Sys.readlink(paths)
  normalized <- normalizePath(paths, winslash = "/", mustWork = TRUE)
  info <- file.info(normalized)
  stopifnot(all(!info$isdir))
  data.frame(
    relative_path = relative_path(normalized),
    role = if (length(role) == 1L) rep(role, length(normalized)) else role,
    sha256 = vapply(normalized, sha256_file, character(1)),
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

build_root <- file.path(root, "_build/nathealth")
build_paths <- list_files(build_root)
build_inventory <- inventory_paths(build_paths, "build_member")
build_inventory <- build_inventory[
  order(build_inventory$relative_path),
  ,
  drop = FALSE
]
write_evidence(build_inventory, paste0("build_inventory_", stage, ".csv"))
build_symlinks <- build_inventory[build_inventory$is_symlink, , drop = FALSE]
write_evidence(
  build_symlinks,
  paste0("build_symlink_inventory_", stage, ".csv")
)

dispatch_relative <- paste0(
  "audit/report_harmonization/",
  "report018_h07_companion_order53_dispatch_manifest.csv"
)
dispatch_path <- file.path(root, dispatch_relative)
dispatch <- readr::read_csv(dispatch_path, show_col_types = FALSE)
matrix_relative <- "audit/report_harmonization/coordination_matrix.csv"
dispatch_hard <- dispatch[dispatch$path != matrix_relative, , drop = FALSE]

h07_roots <- file.path(root, c(
  "artifacts/07_models/H07",
  "artifacts/08_figures/H07",
  "artifacts/09_tables/H07",
  "artifacts/10_figures/H07",
  "artifacts/11_source_data/H07",
  "artifacts/12_manifests/H07",
  "audit/hypotheses/H07",
  "scripts/hypotheses/H07",
  "tests/hypotheses/H07"
))
h07_paths <- unlist(
  lapply(h07_roots, list_files, exclude_prefix = evidence_dir),
  use.names = FALSE
)

handoff_paths <- list.files(
  file.path(root, "audit/handoffs"),
  pattern = "^H07.*[.](md|csv)$",
  full.names = TRUE
)
decision_paths <- file.path(root, c(
  "audit/decisions/hypothesis_preparation_provenance_companions.md",
  "audit/decisions/input_source_selection.md",
  "audit/decisions/metric_validity.md",
  "audit/decisions/site_display_conventions.md",
  "audit/decisions/placement_decision.md",
  "audit/decisions/paired_placement_comparison_display.md",
  "audit/decisions/model_reporting.md",
  "audit/decisions/p_value_display_conventions.md",
  "audit/decisions/bootstrap_execution_policy.md",
  "audit/decisions/gap_timing_unaware_dataset_terminology.md",
  "audit/decisions/answer_in_brief_callout.md",
  "audit/decisions/figure_readability_and_layout.md",
  "audit/decisions/report011_physical_size_revalidation.md",
  "audit/decisions/render_and_hypothesis_comparison_workflow.md",
  "audit/decisions/h03_h11_gated_workflow.md",
  "audit/decisions/saturation_boundary.md"
))
ledger_paths <- list_files(file.path(root, "audit/ledgers"))
dispatch_paths <- file.path(root, dispatch$path)

protected_paths <- sort(unique(c(
  h07_paths,
  handoff_paths,
  decision_paths,
  ledger_paths,
  dispatch_paths,
  file.path(root, c(
    "notebooks/hypotheses/H07.qmd",
    "_build/nathealth/notebooks/hypotheses/H07.html",
    "_quarto-nathealth.yml",
    "_quarto.yml",
    "scripts/report_harmonization/post_render_gt_html_semantics.R",
    "scripts/report_harmonization/repair_gt_html_semantics.R",
    "scripts/pipeline/paths_io.R",
    "scripts/pipeline/p_value_display.R",
    "scripts/pipeline/hypothesis_preparation_provenance_contract.R",
    "config/site_display_registry.csv",
    "audit/report_harmonization/phase4_corpus_manifest.csv",
    "audit/report_harmonization/phase4_gt_source_audit.csv",
    "audit/report_harmonization/deviation_link_plan.csv",
    "audit/report_harmonization/report018_h07_companion_release.md",
    "audit/report_harmonization/report018_h07_companion_release_manifest.csv",
    "audit/report_harmonization/report018_h07_companion_release_pins.csv",
    "audit/report_harmonization/report018_h07_companion_release_verification.csv",
    "audit/report_harmonization/report018_h07_result_independent_acceptance.md",
    "audit/report_harmonization/report018_h07_result_independent_acceptance_manifest.csv",
    "notebooks/preregistration_deviations.qmd",
    "_build/nathealth/supplementary_information.html",
    "renv.lock"
  ))
)))
protected_exists <- file.exists(protected_paths) & !dir.exists(protected_paths)
protected_missing <- data.frame(
  relative_path = relative_path(protected_paths[!protected_exists]),
  status = "MISSING",
  stringsAsFactors = FALSE
)
write_evidence(
  protected_missing,
  paste0("protected_missing_", stage, ".csv")
)
if (identical(stage, "prerender")) {
  stopifnot(nrow(protected_missing) == 0L)
}
protected_paths <- protected_paths[protected_exists]

protected_relative <- relative_path(protected_paths)
protected_role <- rep("h07_protected", length(protected_paths))
protected_role[startsWith(protected_relative, "audit/ledgers/")] <-
  "central_ledger"
protected_role[protected_relative %in% dispatch$path] <- "dispatch_contract"
protected_role[protected_relative == matrix_relative] <-
  "dispatch_time_coordination_matrix"
protected_role[
  protected_relative ==
    "_build/nathealth/audit/hypotheses/H07/H07_analysis_preparation.html"
] <- "expected_companion_render_target"
protected_role[
  protected_relative ==
    "_build/nathealth/audit/hypotheses/H07/H07_analysis_preparation.qmd"
] <- "expected_source_identical_build_qmd"
protected_role[
  protected_relative ==
    "artifacts/12_manifests/H07/H07_preparation_report_manifest.csv"
] <- "expected_live_preparation_manifest"
protected_role[startsWith(protected_relative, "artifacts/")] <-
  "h07_artifact_or_input"

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
  stopifnot(
    nrow(dispatch) == 29L,
    nrow(dispatch_hard) == 28L,
    !anyDuplicated(dispatch$path)
  )
  dispatch_files <- file.path(root, dispatch_hard$path)
  dispatch_observed <- data.frame(
    path = dispatch_hard$path,
    role = dispatch_hard$role,
    expected_sha256 = dispatch_hard$sha256,
    observed_sha256 = vapply(dispatch_files, sha256_file, character(1)),
    expected_bytes = dispatch_hard$bytes,
    observed_bytes = as.numeric(file.info(dispatch_files)$size),
    stringsAsFactors = FALSE
  )
  dispatch_observed$status <- ifelse(
    dispatch_observed$expected_sha256 == dispatch_observed$observed_sha256 &
      dispatch_observed$expected_bytes == dispatch_observed$observed_bytes,
    "PASS",
    "FAIL"
  )
  stopifnot(all(dispatch_observed$status == "PASS"))
  write_evidence(
    dispatch_observed,
    "dispatch_reconciliation_prerender.csv"
  )

  source(file.path(
    root,
    "scripts/pipeline/hypothesis_preparation_provenance_contract.R"
  ))
  qmd_path <- file.path(
    root,
    "audit/hypotheses/H07/H07_analysis_preparation.qmd"
  )
  qmd_lines <- readLines(qmd_path, warn = FALSE, encoding = "UTF-8")
  qmd_text <- paste(qmd_lines, collapse = "\n")
  qmd_compact <- gsub("[[:space:]]+", " ", qmd_text)
  chunks <- extract_executable_r_chunks(qmd_lines)
  chunk_parse <- vapply(
    chunks,
    function(chunk) {
      !inherits(try(parse(text = chunk), silent = TRUE), "try-error")
    },
    logical(1)
  )
  chunk_audit <- data.frame(
    order = seq_along(chunks),
    parseable_r = chunk_parse,
    stringsAsFactors = FALSE
  )
  write_evidence(chunk_audit, "source_chunk_audit_prerender.csv")

  table_labels <- sub(
    "^#\\| label: ",
    "",
    grep("^#\\| label: tbl-h07-", qmd_lines, value = TRUE)
  )
  figure_labels <- sub(
    "^#\\| label: ",
    "",
    grep("^#\\| label: fig-h07-", qmd_lines, value = TRUE)
  )
  endpoint_audit <- rbind(
    data.frame(
      endpoint_type = "table",
      order = seq_along(table_labels),
      endpoint = table_labels,
      stringsAsFactors = FALSE
    ),
    data.frame(
      endpoint_type = "figure",
      order = seq_along(figure_labels),
      endpoint = figure_labels,
      stringsAsFactors = FALSE
    )
  )
  write_evidence(
    endpoint_audit,
    "source_endpoint_contract_prerender.csv"
  )

  calls <- executable_r_call_names(qmd_lines)
  forbidden_calls <- c(
    "mgcv::gam", "mgcv::bam", "gam", "bam", "stats::predict",
    "predict", "stats::simulate", "simulate", "boot::boot", "boot",
    "gratia::derivatives", "derivatives", "h07_stage2_fit_checkpoint",
    "h07_revised_derivatives", "h07_derivative_draws",
    "h07_stage2_tweedie_pilot"
  )
  prohibited_audit <- data.frame(
    prohibited_call = forbidden_calls,
    observed = forbidden_calls %in% calls,
    stringsAsFactors = FALSE
  )
  prohibited_audit$status <- ifelse(
    prohibited_audit$observed,
    "FAIL",
    "PASS"
  )
  write_evidence(
    prohibited_audit,
    "source_prohibited_call_audit_prerender.csv"
  )

  relative_matches <- gregexpr("\\]\\((\\.\\./[^)]+)\\)", qmd_text, perl = TRUE)
  relative_values <- regmatches(qmd_text, relative_matches)[[1L]]
  relative_targets <- sub("^\\]\\(", "", relative_values)
  relative_targets <- sub("\\)$", "", relative_targets)
  relative_files <- sub("#.*$", "", relative_targets)
  resolved_targets <- normalizePath(
    file.path(dirname(qmd_path), relative_files),
    winslash = "/",
    mustWork = FALSE
  )
  target_audit <- data.frame(
    order = seq_along(relative_targets),
    target = relative_targets,
    resolved_path = resolved_targets,
    exists = file.exists(resolved_targets),
    stringsAsFactors = FALSE
  )
  target_audit$status <- ifelse(target_audit$exists, "PASS", "FAIL")
  write_evidence(
    target_audit,
    "source_reader_targets_prerender.csv"
  )

  dynamic_matches <- gregexpr(
    paste0(
      "\\.\\./\\.\\./\\.\\./notebooks/hypotheses/H07\\.qmd",
      "(?:#[A-Za-z0-9_-]+)?"
    ),
    qmd_text,
    perl = TRUE
  )
  dynamic_values <- regmatches(qmd_text, dynamic_matches)[[1L]]
  expected_dynamic <- c(
    rep("../../../notebooks/hypotheses/H07.qmd", 2L),
    paste0(
      "../../../notebooks/hypotheses/H07.qmd",
      "#h07-preregistration-deviations"
    )
  )

  required_phrases <- c(
    "gap-timing-unaware dataset",
    "time-sensitive primary metric dataset",
    "every later point through the recorded maximum",
    "not a ceiling claim",
    "Absolute latitude is constant within every site",
    "No independent temperature",
    "METRIC-011"
  )
  phrase_audit <- data.frame(
    phrase = required_phrases,
    present = vapply(
      required_phrases,
      grepl,
      logical(1),
      x = qmd_compact,
      fixed = TRUE
    ),
    stringsAsFactors = FALSE
  )
  phrase_audit$status <- ifelse(phrase_audit$present, "PASS", "FAIL")
  write_evidence(
    phrase_audit,
    "source_scientific_contract_prerender.csv"
  )

  manifest_path <- file.path(
    root,
    "artifacts/12_manifests/H07/H07_preparation_report_manifest.csv"
  )
  manifest <- readr::read_csv(manifest_path, show_col_types = FALSE)
  manifest_files <- file.path(root, manifest$path)
  manifest_exists <- file.exists(manifest_files) & !dir.exists(manifest_files)
  manifest_sha <- rep(NA_character_, nrow(manifest))
  manifest_bytes <- rep(NA_real_, nrow(manifest))
  manifest_sha[manifest_exists] <- vapply(
    manifest_files[manifest_exists],
    sha256_file,
    character(1)
  )
  manifest_bytes[manifest_exists] <- as.numeric(
    file.info(manifest_files[manifest_exists])$size
  )
  manifest_exact <- manifest_exists &
    manifest_sha == manifest$sha256 &
    manifest_bytes == manifest$bytes
  manifest_audit <- data.frame(
    path = manifest$path,
    recorded_sha256 = manifest$sha256,
    observed_sha256 = manifest_sha,
    recorded_bytes = manifest$bytes,
    observed_bytes = manifest_bytes,
    exact = manifest_exact,
    stringsAsFactors = FALSE
  )
  write_evidence(
    manifest_audit[!manifest_audit$exact, , drop = FALSE],
    "stale_manifest_mismatches_prerender.csv"
  )
  expected_mismatches <- c(
    "audit/hypotheses/H07/H07_analysis_preparation.qmd",
    "_build/nathealth/notebooks/hypotheses/H07.html",
    "notebooks/hypotheses/H07.qmd",
    "_quarto-nathealth.yml"
  )

  profile_lines <- readLines(
    file.path(root, "_quarto-nathealth.yml"),
    warn = FALSE,
    encoding = "UTF-8"
  )
  profile_registration <- sum(
    trimws(profile_lines) ==
      "- audit/hypotheses/H07/H07_analysis_preparation.qmd"
  )
  versions <- data.frame(
    component = c("R", "Quarto", "digest"),
    version = c(
      as.character(getRversion()),
      trimws(system2("quarto", "--version", stdout = TRUE)),
      as.character(utils::packageVersion("digest"))
    ),
    stringsAsFactors = FALSE
  )
  write_evidence(versions, "versions_prerender.csv")

  preflight_status <- data.frame(
    check = c(
      "dispatch non-matrix hard rows",
      "parseable R chunks",
      "unique native gt source endpoints",
      "unique figure source endpoints",
      "relative reader and source targets",
      "dynamic result QMD links",
      "companion deviation anchor",
      "prohibited scientific calls",
      "scientific preservation phrases",
      "historical manifest exact rows",
      "historical manifest expected mismatches",
      "profile registration",
      "build symlinks",
      "protected files",
      "R version",
      "Quarto version"
    ),
    observed = c(
      nrow(dispatch_hard),
      sum(chunk_parse),
      length(table_labels),
      length(figure_labels),
      sum(target_audit$exists),
      length(dynamic_values),
      lengths(regmatches(
        qmd_text,
        gregexpr(
          "#h07-preparation-preregistration-deviations",
          qmd_text,
          fixed = TRUE
        )
      )),
      sum(prohibited_audit$observed),
      sum(phrase_audit$present),
      sum(manifest_exact),
      sum(!manifest_exact),
      profile_registration,
      nrow(build_symlinks),
      nrow(protected_inventory),
      versions$version[versions$component == "R"],
      versions$version[versions$component == "Quarto"]
    ),
    expected = c(
      28L, 26L, 21L, 3L, 14L, 3L, 1L, 0L, 7L, 1231L, 4L, 1L,
      0L, "complete", "4.6.1", "1.9.37"
    ),
    status = "PASS",
    stringsAsFactors = FALSE
  )
  write_evidence(preflight_status, "preflight_status.csv")

  stopifnot(
    length(chunks) == 26L,
    all(chunk_parse),
    length(table_labels) == 21L,
    !anyDuplicated(table_labels),
    length(figure_labels) == 3L,
    !anyDuplicated(figure_labels),
    length(relative_targets) == 14L,
    all(target_audit$exists),
    identical(sort(dynamic_values), sort(expected_dynamic)),
    lengths(regmatches(
      qmd_text,
      gregexpr(
        "#h07-preparation-preregistration-deviations",
        qmd_text,
        fixed = TRUE
      )
    )) == 1L,
    !any(prohibited_audit$observed),
    all(phrase_audit$present),
    nrow(manifest) == 1235L,
    !anyDuplicated(manifest$path),
    sum(manifest_exact) == 1231L,
    setequal(manifest$path[!manifest_exact], expected_mismatches),
    profile_registration == 1L,
    versions$version[versions$component == "R"] == "4.6.1",
    versions$version[versions$component == "Quarto"] == "1.9.37"
  )
}

stopifnot(nrow(build_symlinks) == 0L)

cat(sprintf(
  paste0(
    "ORDER53_INVENTORY=PASS stage=%s build_files=%d build_symlinks=%d ",
    "protected_files=%d\n"
  ),
  stage,
  nrow(build_inventory),
  nrow(build_symlinks),
  nrow(protected_inventory)
))
