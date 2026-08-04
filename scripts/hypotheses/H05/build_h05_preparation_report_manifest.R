#!/usr/bin/env Rscript

# Record the source, rendered identities, display assets, scientific inputs,
# and verification code for the H05 preparation companion. This script copies
# the authoring QMD into the website build tree and verifies byte identity. It
# performs no scientific calculation.

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

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop(
    sprintf("H05 requires R 4.6.1; running %s", getRversion()),
    call. = FALSE
  )
}

producer <- paste0(
  "scripts/hypotheses/H05/",
  "build_h05_preparation_report_manifest.R"
)
output_path <- file.path(
  root,
  "artifacts/12_manifests/H05/H05_preparation_report_manifest.csv"
)
source_path <- file.path(
  root,
  "audit/hypotheses/H05/H05_analysis_preparation.qmd"
)
rendered_source_path <- file.path(
  root,
  paste0(
    "_build/nathealth/audit/hypotheses/H05/",
    "H05_analysis_preparation.qmd"
  )
)

read_raw_file <- function(path) {
  readBin(path, what = "raw", n = file.info(path)$size)
}

dir.create(
  dirname(rendered_source_path),
  recursive = TRUE,
  showWarnings = FALSE
)
if (!file.copy(source_path, rendered_source_path, overwrite = TRUE)) {
  stop("Could not create the H05 website QMD source copy", call. = FALSE)
}
if (!identical(read_raw_file(source_path), read_raw_file(rendered_source_path))) {
  stop(
    "The H05 website QMD copy is not byte-identical to its authoring source",
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
  file.path(root, "scripts/hypotheses/H05"),
  pattern = "\\.R$"
)
test_files <- list_artifacts(
  file.path(root, "tests/hypotheses/H05"),
  pattern = "\\.R$"
)
model_data_files <- list_artifacts(
  file.path(root, "artifacts/06_model_data/H05")
)
model_files <- list_artifacts(
  file.path(root, "artifacts/07_models/H05")
)
diagnostic_files <- list_artifacts(
  file.path(root, "artifacts/08_diagnostics/H05")
)
table_files <- list_artifacts(
  file.path(root, "artifacts/09_tables/H05")
)
figure_files <- list_artifacts(
  file.path(root, "artifacts/10_figures/H05")
)
source_data_files <- list_artifacts(
  file.path(root, "artifacts/11_source_data/H05")
)
manifest_files <- list_artifacts(
  file.path(root, "artifacts/12_manifests/H05"),
  pattern = "\\.csv$"
)
manifest_files <- setdiff(manifest_files, output_path)
preparation_asset_files <- list_artifacts(file.path(
  root,
  paste0(
    "_build/nathealth/audit/hypotheses/H05/",
    "H05_analysis_preparation_files"
  )
))

files <- unique(c(
  file.path(root, "_quarto-nathealth.yml"),
  source_path,
  file.path(
    root,
    paste0(
      "_build/nathealth/audit/hypotheses/H05/",
      "H05_analysis_preparation.html"
    )
  ),
  rendered_source_path,
  file.path(root, "notebooks/hypotheses/H05.qmd"),
  file.path(root, "_build/nathealth/notebooks/hypotheses/H05.html"),
  file.path(root, "config/site_display_registry.csv"),
  file.path(root, "renv.lock"),
  file.path(
    root,
    "audit/decisions/h05_stage2_gate_and_stage3_transition.md"
  ),
  file.path(
    root,
    "audit/decisions/h05_stage3_gate_and_stage4_transition.md"
  ),
  file.path(
    root,
    "audit/decisions/hypothesis_preparation_provenance_companions.md"
  ),
  file.path(root, "audit/decisions/p_value_display_conventions.md"),
  file.path(
    root,
    "audit/decisions/paired_placement_comparison_display.md"
  ),
  file.path(
    root,
    "audit/decisions/gap_timing_unaware_dataset_terminology.md"
  ),
  file.path(root, "audit/decisions/figure_readability_and_layout.md"),
  file.path(root, "audit/decisions/report011_physical_size_revalidation.md"),
  file.path(root, "audit/decisions/reader_facing_symlog_scale.md"),
  file.path(root, "audit/decisions/answer_in_brief_callout.md"),
  file.path(root, "audit/hypotheses/H05/H05_figure_readability_qa.md"),
  file.path(root, "audit/handoffs/H05_stage3_handoff.md"),
  file.path(root, "scripts/pipeline/paths_io.R"),
  file.path(root, "scripts/pipeline/multiplicity.R"),
  file.path(root, "scripts/pipeline/p_value_display.R"),
  file.path(
    root,
    "scripts/pipeline/hypothesis_preparation_provenance_contract.R"
  ),
  file.path(root, "scripts/hypotheses/H01/h01_contract.R"),
  file.path(root, "scripts/hypotheses/H01/h01_modeling.R"),
  file.path(
    root,
    "artifacts/12_manifests/H05/H05_figure_A4_proofs.pdf"
  ),
  preparation_asset_files,
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

if (any(!file.exists(files))) {
  missing <- files[!file.exists(files)]
  stop(
    paste0(
      "Missing H05 preparation-report provenance file(s): ",
      paste(missing, collapse = ", ")
    ),
    call. = FALSE
  )
}

normalized_files <- normalizePath(files, winslash = "/", mustWork = TRUE)
relative <- substring(normalized_files, nchar(root) + 2L)

role <- dplyr::case_when(
  relative == "audit/hypotheses/H05/H05_analysis_preparation.qmd" ~
    "preparation_source",
  relative == paste0(
    "_build/nathealth/audit/hypotheses/H05/",
    "H05_analysis_preparation.html"
  ) ~ "preparation_render",
  relative == paste0(
    "_build/nathealth/audit/hypotheses/H05/",
    "H05_analysis_preparation.qmd"
  ) ~ "preparation_rendered_source",
  startsWith(
    relative,
    paste0(
      "_build/nathealth/audit/hypotheses/H05/",
      "H05_analysis_preparation_files/"
    )
  ) ~ "preparation_page_asset",
  relative == "notebooks/hypotheses/H05.qmd" ~ "result_report_source",
  relative == "_build/nathealth/notebooks/hypotheses/H05.html" ~
    "result_report_render",
  startsWith(relative, "scripts/hypotheses/H05/") ~ "H05_code",
  startsWith(relative, "tests/hypotheses/H05/") ~ "H05_test",
  startsWith(relative, "artifacts/06_model_data/H05/") ~
    "stored_model_data_or_contract",
  startsWith(relative, "artifacts/07_models/H05/") ~ "stored_model_output",
  startsWith(relative, "artifacts/08_diagnostics/H05/") ~
    "stored_diagnostic_output",
  startsWith(relative, "artifacts/09_tables/H05/") ~ "stored_table_output",
  startsWith(relative, "artifacts/10_figures/H05/") ~ "reader_figure",
  startsWith(relative, "artifacts/11_source_data/H05/") ~
    "reader_figure_or_table_source_data",
  startsWith(relative, "artifacts/12_manifests/H05/") ~
    "referenced_H05_manifest",
  startsWith(relative, "audit/decisions/") ~ "approved_reporting_rule",
  relative == "audit/handoffs/H05_stage3_handoff.md" ~
    "approved_results_handoff",
  relative == "_quarto-nathealth.yml" ~ "shared_quarto_profile",
  relative == "config/site_display_registry.csv" ~ "shared_display_registry",
  relative == "renv.lock" ~ "environment_lock",
  startsWith(relative, "scripts/pipeline/") ~ "shared_pipeline_code",
  startsWith(relative, "scripts/hypotheses/H01/") ~ "shared_scientific_code",
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

if (
  anyDuplicated(inventory$path) ||
    anyNA(inventory$sha256) ||
    any(nchar(inventory$sha256) != 64L) ||
    !all(c(
      "audit/hypotheses/H05/H05_analysis_preparation.qmd",
      paste0(
        "_build/nathealth/audit/hypotheses/H05/",
        "H05_analysis_preparation.qmd"
      ),
      paste0(
        "_build/nathealth/audit/hypotheses/H05/",
        "H05_analysis_preparation.html"
      ),
      "_quarto-nathealth.yml"
    ) %in% inventory$path)
) {
  stop("Invalid H05 preparation-report manifest", call. = FALSE)
}

dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
invisible(write_csv_artifact(inventory, output_path, producer))
message(
  "Recorded ",
  nrow(inventory),
  " H05 preparation-report identities with a byte-identical website source copy"
)
