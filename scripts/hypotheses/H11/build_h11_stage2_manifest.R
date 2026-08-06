#!/usr/bin/env Rscript

# Build a non-circular inventory of H11 Stage 2 code, reports, exact frames,
# fitted models, diagnostics, tables, figures, and source data.

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(tibble)
})

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
source(file.path(root, "scripts/hypotheses/H11/h11_stage2.R"))
paths <- h11_stage2_paths(root)
h11_stage2_create_directories(paths)

relative_to_root <- function(path) {
  normalized <- normalizePath(path, winslash = "/", mustWork = TRUE)
  prefix <- paste0(root, "/")
  if (!startsWith(normalized, prefix)) {
    h11_stage2_abort("Manifest path is outside the project root: %s", path)
  }
  substring(normalized, nchar(prefix) + 1L)
}

collect_files <- function(path, pattern = NULL) {
  if (!dir.exists(path)) {
    return(character())
  }
  list.files(
    path,
    pattern = pattern,
    recursive = TRUE,
    full.names = TRUE,
    all.files = FALSE
  )
}

fixed_files <- file.path(root, c(
  "audit/decisions/answer_in_brief_callout.md",
  "audit/decisions/gap_timing_unaware_dataset_terminology.md",
  "audit/decisions/figure_readability_and_layout.md",
  "audit/decisions/manuscript_prepared_data_sensitivity.md",
  "audit/decisions/model_reporting.md",
  "audit/decisions/p_value_display_conventions.md",
  "audit/decisions/paired_placement_comparison_display.md",
  "audit/hypotheses/implementation_result_comparison_contract.qmd",
  "audit/hypotheses/H11/01_author_decision.md",
  "audit/hypotheses/H11/02_inferential_method_amendment.qmd",
  "audit/hypotheses/H11/02_inferential_method_amendment.html",
  "audit/hypotheses/H11/02_inferential_method_decision.md",
  "audit/hypotheses/H11/02_reader_facing_terminology_decision.md",
  "audit/hypotheses/H11/02_figure_readability_qa.md",
  "audit/hypotheses/H11/02_implementation_and_v0_comparison.qmd",
  "audit/hypotheses/H11/02_implementation_and_v0_comparison.html",
  "audit/handoffs/H11_shared_change_request.md",
  "audit/handoffs/H11_worker_handoff.md",
  "scripts/hypotheses/H11/audit_h11_robust_inference_alternative.R",
  "scripts/hypotheses/H11/h11_stage2.R",
  "scripts/hypotheses/H11/run_h11_stage2_analysis.R",
  "scripts/hypotheses/H11/run_h11_stage2_checkpoint.R",
  "scripts/hypotheses/H11/build_h11_stage2_displays.R",
  "scripts/hypotheses/H11/build_h11_stage2_manifest.R",
  "scripts/pipeline/p_value_display.R",
  "tests/hypotheses/H11/test_h11_robust_inference_alternative.R",
  "tests/hypotheses/H11/test_h11_stage2_contract.R",
  "tests/hypotheses/H11/test_h11_stage2_outputs.R",
  "artifacts/12_manifests/H11/H11_robust_method_feasibility_hashes.csv",
  "artifacts/12_manifests/H11/H11_stage2_figure_readability_qa.csv"
))
artifact_files <- unique(c(
  collect_files(paths$model_data),
  collect_files(paths$models),
  collect_files(paths$diagnostics),
  collect_files(paths$tables),
  collect_files(paths$figures),
  collect_files(paths$source_data),
  file.path(paths$manifests, "H11_stage2_figure_manifest.csv")
))
files <- sort(unique(c(fixed_files, artifact_files)))
files <- files[file.exists(files) & !dir.exists(files)]
output_manifest_path <- file.path(
  paths$manifests,
  "H11_stage2_output_hashes.csv"
)
artifact_manifest_path <- file.path(
  paths$manifests,
  "H11_stage2_artifact_manifest.csv"
)
files <- setdiff(files, c(output_manifest_path, artifact_manifest_path))
if (length(files) == 0L) {
  h11_stage2_abort("No H11 Stage 2 files were found for the manifest")
}

classify <- function(path) {
  dplyr::case_when(
    grepl("^audit/decisions/", path) |
      path == "audit/hypotheses/implementation_result_comparison_contract.qmd" |
      path == "scripts/pipeline/p_value_display.R" ~ "shared_input",
    grepl("^audit/", path) & grepl("\\.html$", path) ~ "rendered_report",
    grepl("^audit/", path) ~ "audit",
    grepl("^scripts/", path) ~ "code",
    grepl("^tests/", path) ~ "test",
    grepl("artifacts/06_model_data", path, fixed = TRUE) ~ "model_data",
    grepl("artifacts/07_models", path, fixed = TRUE) ~ "fitted_model",
    grepl("artifacts/08_diagnostics", path, fixed = TRUE) ~ "diagnostic",
    grepl("artifacts/09_tables", path, fixed = TRUE) ~ "table",
    grepl("artifacts/10_figures", path, fixed = TRUE) ~ "figure",
    grepl("artifacts/11_source_data", path, fixed = TRUE) ~ "source_data",
    grepl("artifacts/12_manifests", path, fixed = TRUE) ~ "nested_manifest",
    TRUE ~ "other"
  )
}
producer_for <- function(path) {
  dplyr::case_when(
    grepl("^audit/decisions/", path) |
      path == "audit/hypotheses/implementation_result_comparison_contract.qmd" |
      path == "scripts/pipeline/p_value_display.R" ~
      "coordinator-owned shared reporting input",
    grepl("method_amendment|H11_robust_method_feasibility", path) ~
      "scripts/hypotheses/H11/audit_h11_robust_inference_alternative.R",
    grepl("H11_stage2_figure_readability_qa", path) ~
      "H11 Stage 2 REPORT-011 final-size visual inspection",
    grepl("artifacts/10_figures|H11_stage2_figure_manifest", path) ~
      "scripts/hypotheses/H11/build_h11_stage2_displays.R",
    grepl("^artifacts/", path) ~
      "scripts/hypotheses/H11/run_h11_stage2_analysis.R",
    grepl("02_implementation_and_v0_comparison.html$", path) ~
      "Quarto 1.9.37 from H11 Stage 2 source",
    grepl("^tests/", path) ~ "H11 Stage 2 focused verification",
    TRUE ~ "H11 Stage 2 worker"
  )
}

relative <- vapply(files, relative_to_root, character(1))
inventory <- tibble::tibble(
  path = relative,
  sha256 = vapply(files, h11_stage2_sha256, character(1)),
  bytes = as.numeric(file.info(files)$size),
  artifact_class = classify(relative),
  producer = producer_for(relative),
  R_version = "4.6.1"
) |>
  dplyr::arrange(.data$path)
if (anyDuplicated(inventory$path) || any(!is.finite(inventory$bytes))) {
  h11_stage2_abort("H11 Stage 2 inventory contains duplicates or invalid sizes")
}

readr::write_csv(inventory, artifact_manifest_path, na = "")
artifact_manifest_row <- tibble::tibble(
  path = relative_to_root(artifact_manifest_path),
  sha256 = h11_stage2_sha256(artifact_manifest_path),
  bytes = as.numeric(file.info(artifact_manifest_path)$size),
  artifact_class = "manifest",
  producer = "scripts/hypotheses/H11/build_h11_stage2_manifest.R",
  R_version = "4.6.1"
)
output_inventory <- dplyr::bind_rows(inventory, artifact_manifest_row) |>
  dplyr::arrange(.data$path)
readr::write_csv(output_inventory, output_manifest_path, na = "")

verification <- readr::read_csv(
  output_manifest_path,
  show_col_types = FALSE
)
verification_paths <- file.path(root, verification$path)
observed <- vapply(
  verification_paths,
  h11_stage2_sha256,
  character(1)
)
if (
  anyDuplicated(verification$path) ||
    !identical(unname(observed), verification$sha256)
) {
  h11_stage2_abort("The written H11 Stage 2 output inventory did not reverify")
}

message(
  "H11 Stage 2 non-circular inventory complete: ",
  nrow(output_inventory),
  " files; manifest SHA-256 ",
  h11_stage2_sha256(output_manifest_path)
)
