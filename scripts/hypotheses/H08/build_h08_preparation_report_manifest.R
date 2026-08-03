#!/usr/bin/env Rscript

# Record the source, rendered identities, display assets, scientific inputs,
# and verification code for the H08 preparation companion. The final manifest
# is deliberately unavailable until shared-profile adjacency and the website
# render exist. This script performs no scientific calculation.

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
    sprintf("H08 requires R 4.6.1; running %s", getRversion()),
    call. = FALSE
  )
}

producer <- paste0(
  "scripts/hypotheses/H08/",
  "build_h08_preparation_report_manifest.R"
)
output_path <- file.path(
  root,
  "artifacts/12_manifests/H08/H08_preparation_report_manifest.csv"
)
source_path <- file.path(
  root,
  "audit/hypotheses/H08/H08_analysis_preparation.qmd"
)
rendered_dir <- file.path(
  root,
  "_build/nathealth/audit/hypotheses/H08"
)
rendered_source_path <- file.path(
  rendered_dir,
  "H08_analysis_preparation.qmd"
)
rendered_html_path <- file.path(
  rendered_dir,
  "H08_analysis_preparation.html"
)

profile_lines <- readLines(
  file.path(root, "_quarto-nathealth.yml"),
  warn = FALSE,
  encoding = "UTF-8"
)
assert_adjacent_profile_entries(
  profile_lines,
  "notebooks/hypotheses/H08.qmd",
  "audit/hypotheses/H08/H08_analysis_preparation.qmd"
)
if (!file.exists(rendered_html_path)) {
  stop(
    paste0(
      "The profile-integrated H08 preparation HTML is missing: ",
      rendered_html_path
    ),
    call. = FALSE
  )
}

read_raw_file <- function(path) {
  readBin(path, what = "raw", n = file.info(path)$size)
}

dir.create(rendered_dir, recursive = TRUE, showWarnings = FALSE)
if (!file.copy(source_path, rendered_source_path, overwrite = TRUE)) {
  stop("Could not create the H08 website QMD source copy", call. = FALSE)
}
if (
  !identical(read_raw_file(source_path), read_raw_file(rendered_source_path))
) {
  stop(
    "The H08 website QMD copy is not byte-identical to its authoring source",
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
  file.path(root, "scripts/hypotheses/H08"),
  pattern = "\\.R$"
)
test_files <- list_artifacts(
  file.path(root, "tests/hypotheses/H08"),
  pattern = "\\.R$"
)
audit_files <- list_artifacts(file.path(root, "audit/hypotheses/H08"))
model_data_files <- list_artifacts(
  file.path(root, "artifacts/06_model_data/H08")
)
model_files <- list_artifacts(file.path(root, "artifacts/07_models/H08"))
diagnostic_files <- list_artifacts(
  file.path(root, "artifacts/08_diagnostics/H08")
)
table_files <- list_artifacts(file.path(root, "artifacts/09_tables/H08"))
figure_files <- list_artifacts(file.path(root, "artifacts/10_figures/H08"))
source_data_files <- list_artifacts(
  file.path(root, "artifacts/11_source_data/H08")
)
manifest_files <- list_artifacts(file.path(root, "artifacts/12_manifests/H08"))
manifest_files <- setdiff(manifest_files, output_path)
preparation_asset_files <- list_artifacts(file.path(
  rendered_dir,
  "H08_analysis_preparation_files"
))

decision_files <- file.path(
  root,
  c(
    "audit/decisions/answer_in_brief_callout.md",
    "audit/decisions/bootstrap_execution_policy.md",
    "audit/decisions/figure_readability_and_layout.md",
    "audit/decisions/gap_timing_unaware_dataset_terminology.md",
    "audit/decisions/hypothesis_preparation_provenance_companions.md",
    "audit/decisions/model_reporting.md",
    "audit/decisions/p_value_display_conventions.md",
    "audit/decisions/paired_placement_comparison_display.md",
    "audit/decisions/site_display_conventions.md"
  )
)

files <- unique(c(
  file.path(root, "_quarto-nathealth.yml"),
  source_path,
  rendered_html_path,
  rendered_source_path,
  file.path(root, "notebooks/hypotheses/H08.qmd"),
  file.path(root, "_build/nathealth/notebooks/hypotheses/H08.html"),
  file.path(root, "config/site_display_registry.csv"),
  file.path(root, "config/metric_display_registry.csv"),
  file.path(root, "renv.lock"),
  file.path(root, "audit/hypotheses/H03-H11_gated_workflow.qmd"),
  decision_files,
  file.path(root, "scripts/pipeline/paths_io.R"),
  file.path(root, "scripts/pipeline/multiplicity.R"),
  file.path(root, "scripts/pipeline/p_value_display.R"),
  file.path(
    root,
    "scripts/pipeline/hypothesis_preparation_provenance_contract.R"
  ),
  preparation_asset_files,
  audit_files,
  script_files,
  test_files,
  model_data_files,
  model_files,
  diagnostic_files,
  table_files,
  figure_files,
  source_data_files,
  manifest_files
))

files <- files[
  !grepl(
    "audit/handoffs/H08_(?:worker_handoff|shared_change_request)\\.md$",
    files,
    perl = TRUE
  )
]
if (any(!file.exists(files))) {
  missing <- files[!file.exists(files)]
  stop(
    paste0(
      "Missing H08 preparation-report provenance file(s): ",
      paste(missing, collapse = ", ")
    ),
    call. = FALSE
  )
}

normalized_files <- normalizePath(files, winslash = "/", mustWork = TRUE)
relative <- substring(normalized_files, nchar(root) + 2L)

role <- dplyr::case_when(
  relative == "audit/hypotheses/H08/H08_analysis_preparation.qmd" ~
    "preparation_source",
  relative ==
    paste0(
      "_build/nathealth/audit/hypotheses/H08/",
      "H08_analysis_preparation.html"
    ) ~
    "preparation_render",
  relative ==
    paste0(
      "_build/nathealth/audit/hypotheses/H08/",
      "H08_analysis_preparation.qmd"
    ) ~
    "preparation_rendered_source",
  startsWith(
    relative,
    paste0(
      "_build/nathealth/audit/hypotheses/H08/",
      "H08_analysis_preparation_files/"
    )
  ) ~
    "preparation_page_asset",
  relative == "notebooks/hypotheses/H08.qmd" ~ "result_report_source",
  relative == "_build/nathealth/notebooks/hypotheses/H08.html" ~
    "result_report_render",
  startsWith(relative, "scripts/hypotheses/H08/") ~ "H08_code",
  startsWith(relative, "tests/hypotheses/H08/") ~ "H08_test",
  startsWith(relative, "audit/hypotheses/H08/") ~ "H08_audit_record",
  startsWith(relative, "artifacts/06_model_data/H08/") ~
    "stored_model_data_or_contract",
  startsWith(relative, "artifacts/07_models/H08/") ~ "stored_model_output",
  startsWith(relative, "artifacts/08_diagnostics/H08/") ~
    "stored_diagnostic_output",
  startsWith(relative, "artifacts/09_tables/H08/") ~ "stored_table_output",
  startsWith(relative, "artifacts/10_figures/H08/") ~ "reader_figure",
  startsWith(relative, "artifacts/11_source_data/H08/") ~
    "reader_figure_or_table_source_data",
  startsWith(relative, "artifacts/12_manifests/H08/physical_size_qa/") ~
    "A4_physical_size_proof",
  relative ==
    paste0(
      "artifacts/12_manifests/H08/",
      "H08_figure_physical_size_qa.csv"
    ) ~
    "figure_physical_size_QA",
  startsWith(relative, "artifacts/12_manifests/H08/") ~
    "referenced_H08_manifest",
  startsWith(relative, "audit/decisions/") ~ "approved_reporting_rule",
  relative == "audit/hypotheses/H03-H11_gated_workflow.qmd" ~
    "approved_workflow_contract",
  relative == "_quarto-nathealth.yml" ~ "shared_quarto_profile",
  startsWith(relative, "config/") ~ "shared_display_registry",
  relative == "renv.lock" ~ "environment_lock",
  startsWith(relative, "scripts/pipeline/") ~ "shared_pipeline_code",
  TRUE ~ "supporting_provenance"
)

inventory <- tibble::tibble(
  path = relative,
  role = role,
  artifact_class = role,
  sha256 = vapply(normalized_files, artifact_sha256, character(1)),
  bytes = unname(file.info(normalized_files)$size),
  producer = producer,
  r_version = as.character(getRversion())
) |>
  arrange(.data$role, .data$path)

required_inventory_paths <- c(
  "audit/hypotheses/H08/H08_analysis_preparation.qmd",
  paste0(
    "_build/nathealth/audit/hypotheses/H08/",
    "H08_analysis_preparation.qmd"
  ),
  paste0(
    "_build/nathealth/audit/hypotheses/H08/",
    "H08_analysis_preparation.html"
  ),
  "artifacts/12_manifests/H08/H08_figure_physical_size_qa.csv",
  "_quarto-nathealth.yml"
)
if (
  anyDuplicated(inventory$path) ||
    anyNA(inventory$sha256) ||
    any(nchar(inventory$sha256) != 64L) ||
    !all(required_inventory_paths %in% inventory$path)
) {
  stop("Invalid H08 preparation-report manifest", call. = FALSE)
}

dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
invisible(write_csv_artifact(inventory, output_path, producer))
message(
  "Recorded ",
  nrow(inventory),
  " H08 preparation-report identities with a byte-identical website source copy"
)
