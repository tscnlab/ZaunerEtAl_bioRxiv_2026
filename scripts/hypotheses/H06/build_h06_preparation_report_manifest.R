#!/usr/bin/env Rscript

# Record source, rendered identities, display assets, scientific inputs, and
# verification code for the H06 preparation companion. The shared-profile
# render must already exist; this script adds only the required byte-identical
# source copy and performs no scientific calculation.

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
    sprintf("H06 requires R 4.6.1; running %s", getRversion()),
    call. = FALSE
  )
}

producer <- paste0(
  "scripts/hypotheses/H06/",
  "build_h06_preparation_report_manifest.R"
)
output_path <- file.path(
  root,
  "artifacts/12_manifests/H06/H06_preparation_report_manifest.csv"
)
source_path <- file.path(
  root,
  "audit/hypotheses/H06/H06_analysis_preparation.qmd"
)
website_root <- file.path(
  root,
  "_build/nathealth/audit/hypotheses/H06"
)
website_source_path <- file.path(
  website_root,
  "H06_analysis_preparation.qmd"
)
website_html_path <- file.path(
  website_root,
  "H06_analysis_preparation.html"
)
website_assets_path <- file.path(
  website_root,
  "H06_analysis_preparation_files"
)

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

profile_lines <- readLines(
  file.path(root, "_quarto-nathealth.yml"),
  warn = FALSE,
  encoding = "UTF-8"
)
assert_adjacent_profile_entries(
  profile_lines,
  "notebooks/hypotheses/H06.qmd",
  "audit/hypotheses/H06/H06_analysis_preparation.qmd"
)
if (
  !file.exists(source_path) ||
    !file.exists(website_html_path)
) {
  stop(
    "The H06 preparation source or profile-integrated render is missing",
    call. = FALSE
  )
}

dir.create(dirname(website_source_path), recursive = TRUE, showWarnings = FALSE)
if (!file.copy(source_path, website_source_path, overwrite = TRUE)) {
  stop("Could not create the H06 website QMD source copy", call. = FALSE)
}

website_assets <- list_artifacts(website_assets_path, pattern = "\\.png$")
if (length(website_assets) == 0L) {
  stop("The profile-integrated H06 render has no page assets", call. = FALSE)
}

if (!identical(
  read_file_bytes(source_path),
  read_file_bytes(website_source_path)
)) {
  stop(
    "The H06 website QMD copy is not byte-identical to its authoring source",
    call. = FALSE
  )
}

script_files <- list_artifacts(
  file.path(root, "scripts/hypotheses/H06"),
  pattern = "\\.R$"
)
test_files <- list_artifacts(
  file.path(root, "tests/hypotheses/H06"),
  pattern = "\\.R$"
)
audit_files <- list_artifacts(file.path(root, "audit/hypotheses/H06"))
model_data_files <- list_artifacts(
  file.path(root, "artifacts/06_model_data/H06")
)
model_files <- list_artifacts(file.path(root, "artifacts/07_models/H06"))
diagnostic_files <- list_artifacts(
  file.path(root, "artifacts/08_diagnostics/H06")
)
table_files <- list_artifacts(file.path(root, "artifacts/09_tables/H06"))
figure_files <- list_artifacts(file.path(root, "artifacts/10_figures/H06"))
source_data_files <- list_artifacts(
  file.path(root, "artifacts/11_source_data/H06")
)
manifest_files <- list_artifacts(
  file.path(root, "artifacts/12_manifests/H06")
)
manifest_files <- setdiff(manifest_files, output_path)

decision_relatives <- c(
  "audit/decisions/h03_h11_gated_workflow.md",
  "audit/decisions/hypothesis_preparation_provenance_companions.md",
  "audit/decisions/model_reporting.md",
  "audit/decisions/p_value_display_conventions.md",
  "audit/decisions/paired_placement_comparison_display.md",
  "audit/decisions/gap_timing_unaware_dataset_terminology.md",
  "audit/decisions/site_display_conventions.md",
  "audit/decisions/bootstrap_execution_policy.md",
  "audit/decisions/figure_readability_and_layout.md",
  "audit/decisions/report011_physical_size_revalidation.md",
  "audit/decisions/reader_facing_symlog_scale.md",
  "audit/decisions/answer_in_brief_callout.md",
  "audit/decisions/h06_stage1_gate_and_stage2_transition.md",
  "audit/decisions/h06_stage1a_gate_and_stage2_transition.md",
  "audit/decisions/h06_stage2_gate_and_stage3_transition.md",
  "audit/decisions/h06_stage3_gate_and_stage4_transition.md"
)
decision_files <- file.path(root, decision_relatives)

shared_provenance_relatives <- c(
  "artifacts/12_manifests/base_model_data_artifacts.csv",
  paste0(
    "artifacts/08_diagnostics/mder_METRIC-010/downstream_rebuild/",
    "h06_hourly_frame_invariance.csv"
  ),
  "config/site_display_registry.csv",
  "config/model_input_source_pins.csv",
  "scripts/pipeline/paths_io.R",
  "scripts/pipeline/multiplicity.R",
  "scripts/pipeline/p_value_display.R",
  "scripts/pipeline/hypothesis_preparation_provenance_contract.R"
)
shared_provenance_files <- file.path(root, shared_provenance_relatives)

files <- unique(c(
  file.path(root, "_quarto-nathealth.yml"),
  source_path,
  website_source_path,
  website_html_path,
  website_assets,
  file.path(root, "notebooks/hypotheses/H06.qmd"),
  file.path(root, "notebooks/hypotheses/H06.css"),
  file.path(root, "_build/nathealth/notebooks/hypotheses/H06.html"),
  file.path(root, "renv.lock"),
  decision_files,
  shared_provenance_files,
  script_files,
  test_files,
  audit_files,
  model_data_files,
  model_files,
  diagnostic_files,
  table_files,
  figure_files,
  source_data_files,
  manifest_files
))

excluded <- c(
  output_path,
  file.path(root, "audit/handoffs/H06_worker_handoff.md"),
  file.path(root, "audit/handoffs/H06_shared_change_request.md")
)
files <- setdiff(files, excluded)
if (any(!file.exists(files))) {
  missing <- files[!file.exists(files)]
  stop(
    paste0(
      "Missing H06 preparation-report provenance file(s): ",
      paste(missing, collapse = ", ")
    ),
    call. = FALSE
  )
}

normalized_files <- normalizePath(files, winslash = "/", mustWork = TRUE)
relative <- substring(normalized_files, nchar(root) + 2L)

role <- dplyr::case_when(
  relative == "audit/hypotheses/H06/H06_analysis_preparation.qmd" ~
    "preparation_source",
  relative == paste0(
    "_build/nathealth/audit/hypotheses/H06/",
    "H06_analysis_preparation.html"
  ) ~ "preparation_website_render",
  relative == paste0(
    "_build/nathealth/audit/hypotheses/H06/",
    "H06_analysis_preparation.qmd"
  ) ~ "preparation_website_source",
  startsWith(
    relative,
    paste0(
      "_build/nathealth/audit/hypotheses/H06/",
      "H06_analysis_preparation_files/"
    )
  ) ~ "preparation_website_page_asset",
  relative == "notebooks/hypotheses/H06.qmd" ~ "result_report_source",
  relative == "notebooks/hypotheses/H06.css" ~ "result_report_style",
  relative == "_build/nathealth/notebooks/hypotheses/H06.html" ~
    "result_report_render",
  startsWith(relative, "scripts/hypotheses/H06/") ~ "H06_code",
  startsWith(relative, "tests/hypotheses/H06/") ~ "H06_test",
  startsWith(relative, "audit/hypotheses/H06/") ~ "H06_audit_record",
  startsWith(relative, "artifacts/06_model_data/H06/") ~
    "stored_model_data_or_contract",
  startsWith(relative, "artifacts/07_models/H06/") ~
    "stored_model_output",
  startsWith(relative, "artifacts/08_diagnostics/H06/") ~
    "stored_diagnostic_output",
  startsWith(relative, "artifacts/09_tables/H06/") ~
    "stored_table_output",
  startsWith(relative, "artifacts/10_figures/H06/") ~ "reader_figure",
  startsWith(relative, "artifacts/11_source_data/H06/") ~
    "reader_figure_or_table_source_data",
  startsWith(relative, "artifacts/12_manifests/H06/") ~
    "referenced_H06_manifest",
  relative == paste0(
    "audit/hypotheses/H06/",
    "H06_preparation_figure_readability_qa.md"
  ) ~ "visual_QA_record",
  startsWith(relative, "audit/decisions/") ~ "approved_reporting_rule",
  relative == "_quarto-nathealth.yml" ~ "shared_quarto_profile",
  relative == "config/site_display_registry.csv" ~
    "shared_display_registry",
  relative == "config/model_input_source_pins.csv" ~
    "shared_input_source_registry",
  relative == "renv.lock" ~ "environment_lock",
  startsWith(relative, "scripts/pipeline/") ~ "shared_pipeline_code",
  relative == "artifacts/12_manifests/base_model_data_artifacts.csv" ~
    "shared_base_manifest",
  grepl("h06_hourly_frame_invariance[.]csv$", relative) ~
    "shared_invariance_evidence",
  TRUE ~ "supporting_provenance"
)

manifest <- tibble::tibble(
  path = relative,
  role = role,
  sha256 = vapply(normalized_files, artifact_sha256, character(1)),
  bytes = unname(as.numeric(file.info(normalized_files)$size)),
  producer = producer,
  r_version = as.character(getRversion()),
  recorded_utc = format(Sys.time(), tz = "UTC", usetz = TRUE)
) |>
  arrange(.data$path)

if (
  anyDuplicated(manifest$path) ||
    any(nchar(manifest$sha256) != 64L) ||
    any(manifest$bytes <= 0L) ||
    !all(c(
      "preparation_source",
      "preparation_website_render",
      "preparation_website_source",
      "H06_code",
      "H06_test",
      "reader_figure_or_table_source_data",
      "shared_quarto_profile",
      "shared_base_manifest",
      "shared_invariance_evidence"
    ) %in% manifest$role)
) {
  stop("Invalid H06 preparation-report manifest", call. = FALSE)
}

invisible(write_csv_artifact(manifest, output_path, producer))
message(
  "H06 preparation-report manifest completed: ",
  nrow(manifest),
  " files"
)
