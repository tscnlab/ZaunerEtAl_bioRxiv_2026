#!/usr/bin/env Rscript

# Build non-circular manifests for the no-refit H06-D-014 amendment.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
.libPaths(c(
  file.path(root, "renv/library/macos/R-4.6/aarch64-apple-darwin23"),
  .libPaths()
))

required_packages <- c(
  "digest", "dplyr", "ggplot2", "glmmTMB", "gt", "knitr", "lme4",
  "patchwork", "readr", "tibble", "tidyr"
)
missing_packages <- required_packages[!vapply(
  required_packages,
  requireNamespace,
  logical(1L),
  quietly = TRUE
)]
if (length(missing_packages)) {
  stop(
    sprintf("Missing synchronized packages: %s", paste(missing_packages, collapse = ", ")),
    call. = FALSE
  )
}

source(file.path(
  root,
  "scripts/hypotheses/H06_daily/h06_daily_h01_diagnostic_alignment_contract.R"
))

h06d_h01_assert(
  identical(as.character(getRversion()), "4.6.1"),
  "H06-D-014 manifest sealing requires R 4.6.1; found %s",
  as.character(getRversion())
)
h06d_h01_verify_direct_inputs(root)
roots <- h06d_h01_artifact_roots(root)

manifest_record <- function(relative_path, role, producer) {
  record <- h06d_h01_file_record(root, relative_path, role)
  dplyr::mutate(
    record,
    producer = producer,
    r_version = as.character(getRversion())
  )
}

manifest_from_paths <- function(relative_paths, roles, producer) {
  h06d_h01_assert(
    length(relative_paths) == length(roles),
    "Manifest path/role lengths differ"
  )
  dplyr::bind_rows(Map(
    function(path, role) manifest_record(path, role, producer),
    relative_paths,
    roles
  )) |>
    dplyr::arrange(.data$relative_path)
}

code_paths <- c(
  "scripts/hypotheses/H06_daily/h06_daily_h01_diagnostic_alignment_contract.R",
  "scripts/hypotheses/H06_daily/build_h06_daily_h01_residual_review.R",
  "scripts/hypotheses/H06_daily/record_h06_daily_h01_visual_review.R",
  "scripts/hypotheses/H06_daily/audit_h06_daily_h01_timing_unit_contract.R",
  "scripts/hypotheses/H06_daily/finalize_h06_daily_h01_diagnostic_alignment.R",
  "scripts/hypotheses/H06_daily/build_h06_daily_h01_diagnostic_alignment_manifests.R",
  "tests/hypotheses/H06_daily/test_h06_daily_h01_diagnostic_alignment.R",
  "audit/hypotheses/H06_daily/13_h01_diagnostic_alignment.qmd"
)
code_roles <- c(
  "author-approved task-local input and hard-gate contract",
  "frozen-fit residual evidence and atlas generator",
  "manual visual-review record",
  "clock-unit construct audit",
  "no-refit classification and claim-eligibility finalizer",
  "non-circular manifest builder",
  "focused H06-D-G2A R verifier",
  "H06-D-G2A Quarto report source"
)
code_manifest <- manifest_from_paths(
  code_paths,
  code_roles,
  "H06-D-014 task-local code"
)
h06d_h01_assert(
  nrow(code_manifest) == 8L && !anyDuplicated(code_manifest$relative_path),
  "The H06-D-014 code inventory is incomplete"
)

diagnostic_names <- c(
  "H06_daily_h01_aligned_cell_classification.csv",
  "H06_daily_h01_l10_shiftlog_reclassification.csv",
  "H06_daily_h01_previsual_replay.csv",
  "H06_daily_h01_protected_identity_verification.csv",
  "H06_daily_h01_sidecar_retention_audit.csv",
  "H06_daily_h01_timing_unit_contract_audit.csv",
  "H06_daily_h01_timing_unit_family_impact.csv",
  "H06_daily_h01_visual_residual_atlas_index.csv",
  "H06_daily_h01_visual_residual_plot_index.csv",
  "H06_daily_h01_visual_residual_review.csv",
  "H06_daily_h01_visual_residual_review_template.csv"
)
table_names <- c(
  "H06_daily_h01_aligned_claim_eligibility.csv",
  "H06_daily_h01_aligned_classification_summary.csv",
  "H06_daily_h01_claim_transition_summary.csv"
)
cell_plot_paths <- list.files(
  file.path(roots$figures, "h01_diagnostic_alignment/cells"),
  pattern = "[.]png$",
  full.names = TRUE
)
cell_source_paths <- list.files(
  file.path(roots$source_data, "h01_diagnostic_alignment/cells"),
  pattern = "[.]csv$",
  full.names = TRUE
)
atlas_paths <- list.files(
  file.path(roots$figures, "h01_diagnostic_alignment/atlases"),
  pattern = "[.]png$",
  full.names = TRUE
)
h06d_h01_assert(
  length(cell_plot_paths) == 471L && length(cell_source_paths) == 471L &&
    length(atlas_paths) == 37L &&
    !any(grepl(" 2[.]png$", c(cell_plot_paths, atlas_paths))),
  "The indexed visual evidence contains missing or stale duplicate files"
)

output_paths <- c(
  file.path("artifacts/08_diagnostics/H06_daily", diagnostic_names),
  file.path("artifacts/09_tables/H06_daily", table_names),
  vapply(
    cell_plot_paths,
    function(path) h06d_h01_relative(root, path),
    character(1L)
  ),
  vapply(
    cell_source_paths,
    function(path) h06d_h01_relative(root, path),
    character(1L)
  ),
  vapply(
    atlas_paths,
    function(path) h06d_h01_relative(root, path),
    character(1L)
  ),
  "audit/hypotheses/H06_daily/13_h01_diagnostic_alignment.qmd",
  "audit/hypotheses/H06_daily/13_h01_diagnostic_alignment.html",
  "audit/hypotheses/H06_daily/H06_daily_h01_diagnostic_alignment_transition.md",
  "audit/handoffs/H06_daily_shared_change_request.md"
)
output_roles <- c(
  rep("row-level diagnostic alignment or audit table", length(diagnostic_names)),
  rep("reader-facing classification or claim table", length(table_names)),
  rep("indexed cell-level visual diagnostic", length(cell_plot_paths)),
  rep("paired diagnostic source data", length(cell_source_paths)),
  rep("indexed visual-review atlas", length(atlas_paths)),
  "H06-D-G2A report source",
  "rendered H06-D-G2A report",
  "H06-D-G2A transition and stop record",
  "task-local shared-change request for future bounded repair"
)
output_manifest <- manifest_from_paths(
  output_paths,
  output_roles,
  "H06-D-014 no-refit diagnostic amendment"
)
h06d_h01_assert(
  nrow(output_manifest) == 997L && !anyDuplicated(output_manifest$relative_path),
  "The H06-D-014 997-entry output inventory is incomplete"
)

report_paths <- c(
  "audit/hypotheses/H06_daily/13_h01_diagnostic_alignment.qmd",
  "audit/hypotheses/H06_daily/13_h01_diagnostic_alignment.html",
  "audit/hypotheses/H06_daily/H06_daily_h01_diagnostic_alignment_transition.md"
)
report_manifest <- manifest_from_paths(
  report_paths,
  c("Quarto source", "embedded-resource HTML", "gate transition"),
  "H06-D-014 report seal"
)
h06d_h01_assert(nrow(report_manifest) == 3L, "The report manifest is incomplete")

quarto_version <- tryCatch(
  trimws(system2("quarto", "--version", stdout = TRUE, stderr = TRUE)[[1L]]),
  error = function(error) NA_character_
)
software <- tibble::tibble(
  component = c("R", "Quarto", required_packages),
  version = c(
    as.character(getRversion()),
    quarto_version,
    vapply(required_packages, function(package) {
      as.character(utils::packageVersion(package))
    }, character(1L))
  ),
  role = c(
    "authoritative scientific and audit runtime",
    "narrow report renderer",
    rep("task-local analytical, visual, or reporting dependency", length(required_packages))
  )
)
h06d_h01_assert(
  !any(is.na(software$version)) && !anyDuplicated(software$component),
  "A software identity could not be recorded"
)

h06d_h01_write_csv(
  code_manifest,
  file.path(roots$manifests, "H06_daily_h01_diagnostic_alignment_code_manifest.csv")
)
h06d_h01_write_csv(
  output_manifest,
  file.path(roots$manifests, "H06_daily_h01_diagnostic_alignment_output_manifest.csv")
)
h06d_h01_write_csv(
  software,
  file.path(roots$manifests, "H06_daily_h01_diagnostic_alignment_software_manifest.csv")
)
h06d_h01_write_csv(
  report_manifest,
  file.path(roots$audit, "H06_daily_h01_diagnostic_alignment_report_manifest.csv")
)

cat(sprintf(
  paste0(
    "H06-D-014 manifests sealed: %d code, %d output, %d report, ",
    "%d software records.\n"
  ),
  nrow(code_manifest),
  nrow(output_manifest),
  nrow(report_manifest),
  nrow(software)
))
