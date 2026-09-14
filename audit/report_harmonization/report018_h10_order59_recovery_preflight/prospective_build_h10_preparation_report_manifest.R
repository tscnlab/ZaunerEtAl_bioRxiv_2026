#!/usr/bin/env Rscript

# Seal the H10 preparation source, website copy and render, scientific inputs,
# result outputs, display assets, code, tests, and environment. The manifest is
# deliberately unavailable until shared-profile adjacency exists.

suppressPackageStartupMessages({
  library(dplyr)
  library(tibble)
})

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
source(file.path(root, "scripts/pipeline/paths_io.R"))
source(file.path(
  root,
  "scripts/pipeline/hypothesis_preparation_provenance_contract.R"
))

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop(
    sprintf(
      "H10 preparation manifest requires R 4.6.1; running %s",
      getRversion()
    ),
    call. = FALSE
  )
}

producer <- paste0(
  "scripts/hypotheses/H10/",
  "build_h10_preparation_report_manifest.R"
)
output_path <- file.path(
  root,
  "artifacts/12_manifests/H10/H10_preparation_report_manifest.csv"
)
paths <- preparation_companion_paths(root, "H10")

profile_lines <- readLines(
  paths$quarto_profile,
  warn = FALSE,
  encoding = "UTF-8"
)
assert_adjacent_profile_entries(
  profile_lines,
  "notebooks/hypotheses/H10.qmd",
  "audit/hypotheses/H10/H10_analysis_preparation.qmd"
)
if (!file.exists(paths$html)) {
  stop(
    paste0(
      "The profile-integrated H10 preparation HTML is missing: ",
      paths$html
    ),
    call. = FALSE
  )
}
dir.create(dirname(paths$rendered_qmd), recursive = TRUE, showWarnings = FALSE)
if (!file.copy(paths$qmd, paths$rendered_qmd, overwrite = TRUE)) {
  stop("Could not create the H10 website QMD source copy", call. = FALSE)
}
if (
  !identical(read_file_bytes(paths$qmd), read_file_bytes(paths$rendered_qmd))
) {
  stop(
    "The H10 website QMD copy is not byte-identical to its authoring source",
    call. = FALSE
  )
}

list_artifacts <- function(path, pattern = NULL) {
  if (!dir.exists(path)) {
    return(character())
  }
  list.files(
    path,
    pattern = pattern,
    recursive = TRUE,
    full.names = TRUE,
    include.dirs = FALSE
  )
}

script_files <- list_artifacts(
  file.path(root, "scripts/hypotheses/H10"),
  pattern = "\\.R$"
)
test_files <- list_artifacts(
  file.path(root, "tests/hypotheses/H10"),
  pattern = "\\.R$"
)
audit_files <- list_artifacts(file.path(root, "audit/hypotheses/H10"))
historical_order59_evidence <- file.path(
  root,
  paste0(
    "audit/hypotheses/H10/",
    "report018_order59_companion_no_rerender_completion"
  ),
  c(
    "execution_record.csv",
    "fail_closed_checks.csv",
    "fixed_identity_at_stop.csv",
    "helper_mismatch_diagnosis.csv",
    "helper_transition.diff",
    "independent_build_delta.csv",
    "independent_preflight_checks.csv",
    "independent_protected_delta.csv",
    "order59_fail_closed_non_circular_evidence_manifest.csv",
    "order59_fail_closed_stop_record.md",
    "preparation_test_transition.diff",
    "seal_order59_fail_closed.R",
    "transition_checks.csv"
  )
)
if (!all(file.exists(historical_order59_evidence))) {
  stop(
    "The sealed Order 59 historical evidence set is incomplete",
    call. = FALSE
  )
}
audit_files <- setdiff(audit_files, historical_order59_evidence)
artifact_files <- unlist(lapply(
  file.path(
    root,
    c(
      "artifacts/06_model_data/H10",
      "artifacts/07_models/H10",
      "artifacts/08_diagnostics/H10",
      "artifacts/09_tables/H10",
      "artifacts/10_figures/H10",
      "artifacts/11_source_data/H10",
      "artifacts/12_manifests/H10"
    )
  ),
  list_artifacts
))
artifact_files <- setdiff(artifact_files, output_path)

reader_page_assets <- list_artifacts(file.path(
  root,
  "_build/nathealth/notebooks/hypotheses/H10_files"
))
preparation_page_assets <- list_artifacts(file.path(
  root,
  paste0(
    "_build/nathealth/audit/hypotheses/H10/",
    "H10_analysis_preparation_files"
  )
))
linked_website_assets <- unlist(lapply(
  file.path(
    root,
    c(
      "_build/nathealth/artifacts/08_diagnostics/H10",
      "_build/nathealth/artifacts/09_tables/H10",
      "_build/nathealth/artifacts/10_figures/H10",
      "_build/nathealth/artifacts/11_source_data/H10"
    )
  ),
  list_artifacts
))

decision_files <- file.path(
  root,
  c(
    "audit/decisions/answer_in_brief_callout.md",
    "audit/decisions/figure_readability_and_layout.md",
    "audit/decisions/gap_timing_unaware_dataset_terminology.md",
    "audit/decisions/hypothesis_preparation_provenance_companions.md",
    "audit/decisions/model_reporting.md",
    "audit/decisions/p_value_display_conventions.md",
    "audit/decisions/paired_placement_comparison_display.md",
    "audit/decisions/preparation06_current_base_model_gate.md",
    "audit/decisions/mder_mean_of_viable_ratios.md",
    "audit/decisions/l10_numerical_zero_normalization.md",
    "audit/reconciliation/l10_METRIC-011/METRIC-011_evidence_manifest.csv",
    "audit/decisions/reader_facing_symlog_scale.md",
    "audit/decisions/site_display_conventions.md"
  )
)

files <- unique(c(
  paths$quarto_profile,
  paths$qmd,
  paths$rendered_qmd,
  paths$html,
  paths$result_qmd,
  paths$result_html,
  file.path(root, "_quarto.yml"),
  file.path(root, "renv.lock"),
  file.path(root, "config/site_display_registry.csv"),
  file.path(root, "config/metric_display_registry.csv"),
  file.path(root, "audit/hypotheses/H03-H11_gated_workflow.qmd"),
  decision_files,
  file.path(root, "scripts/pipeline/paths_io.R"),
  file.path(root, "scripts/pipeline/multiplicity.R"),
  file.path(root, "scripts/pipeline/p_value_display.R"),
  file.path(
    root,
    "scripts/pipeline/hypothesis_preparation_provenance_contract.R"
  ),
  script_files,
  test_files,
  audit_files,
  artifact_files,
  reader_page_assets,
  preparation_page_assets,
  linked_website_assets
))

files <- files[
  !grepl(
    paste0(
      "audit/(?:handoffs/H10_|hypotheses/H10/",
      "(?:03_stage3_author_gate|04_stage4_author_gate))"
    ),
    files,
    perl = TRUE
  )
]
files <- setdiff(files, output_path)
if (any(!file.exists(files))) {
  missing <- files[!file.exists(files)]
  stop(
    paste0(
      "Missing H10 preparation-report provenance file(s): ",
      paste(missing, collapse = ", ")
    ),
    call. = FALSE
  )
}

normalized_files <- normalizePath(files, winslash = "/", mustWork = TRUE)
relative <- substring(normalized_files, nchar(root) + 2L)

role <- dplyr::case_when(
  relative == "audit/hypotheses/H10/H10_analysis_preparation.qmd" ~
    "preparation_source",
  relative == "audit/hypotheses/H10/H10_analysis_preparation.html" ~
    "preintegration_preparation_render",
  relative ==
    paste0(
      "_build/nathealth/audit/hypotheses/H10/",
      "H10_analysis_preparation.qmd"
    ) ~
    "preparation_website_source_copy",
  relative ==
    paste0(
      "_build/nathealth/audit/hypotheses/H10/",
      "H10_analysis_preparation.html"
    ) ~
    "preparation_website_render",
  startsWith(
    relative,
    paste0(
      "_build/nathealth/audit/hypotheses/H10/",
      "H10_analysis_preparation_files/"
    )
  ) ~
    "preparation_page_asset",
  relative == "notebooks/hypotheses/H10.qmd" ~ "result_report_source",
  relative == "_build/nathealth/notebooks/hypotheses/H10.html" ~
    "result_report_render",
  startsWith(
    relative,
    "_build/nathealth/notebooks/hypotheses/H10_files/"
  ) ~
    "result_report_page_asset",
  startsWith(relative, "_build/nathealth/artifacts/") ~ "website_linked_asset",
  startsWith(relative, "scripts/hypotheses/H10/") ~ "H10_code",
  startsWith(relative, "tests/hypotheses/H10/") ~ "H10_test",
  startsWith(relative, "audit/hypotheses/H10/") ~ "H10_audit_record",
  startsWith(relative, "artifacts/06_model_data/H10/") ~
    "stored_model_data_or_contract",
  startsWith(relative, "artifacts/07_models/H10/") ~ "stored_model_output",
  startsWith(relative, "artifacts/08_diagnostics/H10/") ~
    "stored_diagnostic_output",
  startsWith(relative, "artifacts/09_tables/H10/") ~ "stored_table_output",
  startsWith(relative, "artifacts/10_figures/H10/") ~ "reader_figure",
  startsWith(relative, "artifacts/11_source_data/H10/") ~
    "figure_or_table_source_data",
  startsWith(relative, "artifacts/12_manifests/H10/") ~
    "referenced_H10_manifest_or_QA",
  startsWith(relative, "audit/decisions/") ~ "approved_reporting_rule",
  relative == "audit/hypotheses/H03-H11_gated_workflow.qmd" ~
    "approved_workflow_contract",
  relative %in% c("_quarto.yml", "_quarto-nathealth.yml") ~
    "shared_quarto_configuration",
  startsWith(relative, "config/") ~ "shared_display_registry",
  relative == "renv.lock" ~ "environment_lock",
  startsWith(relative, "scripts/pipeline/") ~ "shared_pipeline_code",
  TRUE ~ "supporting_provenance"
)

written_utc <- format(Sys.time(), tz = "UTC", usetz = TRUE)
inventory <- tibble::tibble(
  path = relative,
  role = role,
  artifact_class = role,
  sha256 = vapply(normalized_files, artifact_sha256, character(1)),
  bytes = unname(as.numeric(file.info(normalized_files)$size)),
  producer = producer,
  r_version = as.character(getRversion()),
  written_utc = written_utc,
  provenance_qualification = paste(
    "PREP-003/FIND-044: the current Preparation 06 model-ready layer and",
    "METRIC-010 MDER values are independently verified, including the",
    "FIND-049/CHG-101 gap-MDER repair. METRIC-011 normalized eight primary",
    "L10 means from numerical noise to exact zero without changing samples,",
    "non-L10 scientific values, or inferential decisions; complete independent",
    "reconstruction of the exact current state-support classification remains",
    "open. This is not evidence of incorrect data."
  )
) |>
  arrange(.data$role, .data$path)

required_paths <- c(
  "audit/hypotheses/H10/H10_analysis_preparation.qmd",
  paste0(
    "_build/nathealth/audit/hypotheses/H10/",
    "H10_analysis_preparation.qmd"
  ),
  paste0(
    "_build/nathealth/audit/hypotheses/H10/",
    "H10_analysis_preparation.html"
  ),
  "notebooks/hypotheses/H10.qmd",
  "_build/nathealth/notebooks/hypotheses/H10.html",
  "scripts/hypotheses/H10/build_h10_preparation_artifacts.R",
  "scripts/hypotheses/H10/build_h10_preparation_figure_qa.R",
  "scripts/hypotheses/H10/build_h10_preparation_report_manifest.R",
  "tests/hypotheses/H10/test_h10_preparation_report.R",
  "artifacts/10_figures/H10/H10_preparation_age_distribution.png",
  "artifacts/10_figures/H10/H10_preparation_sample_support.png",
  paste0(
    "artifacts/11_source_data/H10/",
    "H10_preparation_age_distribution_data.csv"
  ),
  paste0(
    "artifacts/11_source_data/H10/",
    "H10_preparation_sample_support_data.csv"
  ),
  paste0(
    "artifacts/12_manifests/H10/",
    "H10_preparation_figure_readability_qa.csv"
  ),
  "_quarto-nathealth.yml"
)
if (
  nrow(inventory) <= 100L ||
    anyDuplicated(inventory$path) ||
    any(nchar(inventory$sha256) != 64L) ||
    any(!required_paths %in% inventory$path) ||
    normalizePath(output_path, winslash = "/", mustWork = FALSE) %in%
      normalized_files
) {
  stop("Invalid H10 preparation-report inventory", call. = FALSE)
}

dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
invisible(write_csv_artifact(inventory, output_path, producer))
message(
  "H10 preparation-report manifest completed: ",
  nrow(inventory),
  " current files"
)
