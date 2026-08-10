#!/usr/bin/env Rscript

# Record source, rendered identities, display assets, scientific inputs, and
# verification code for the H03 preparation companion. Until the coordinator
# registers the source in the shared profile, this script copies the direct
# single-file render and its assets into the expected website path. It performs
# no scientific calculation.

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
    sprintf("H03 requires R 4.6.1; running %s", getRversion()),
    call. = FALSE
  )
}

producer <- paste0(
  "scripts/hypotheses/H03/",
  "build_h03_preparation_report_manifest.R"
)
output_path <- file.path(
  root,
  "artifacts/12_manifests/H03/H03_preparation_report_manifest.csv"
)
source_path <- file.path(
  root,
  "audit/hypotheses/H03/H03_analysis_preparation.qmd"
)
direct_html_path <- file.path(
  root,
  "audit/hypotheses/H03/H03_analysis_preparation.html"
)
direct_assets_path <- file.path(
  root,
  "audit/hypotheses/H03/H03_analysis_preparation_files"
)
website_root <- file.path(
  root,
  "_build/nathealth/audit/hypotheses/H03"
)
website_source_path <- file.path(
  website_root,
  "H03_analysis_preparation.qmd"
)
website_html_path <- file.path(
  website_root,
  "H03_analysis_preparation.html"
)
website_assets_path <- file.path(
  website_root,
  "H03_analysis_preparation_files"
)

read_raw_file <- function(path) {
  readBin(path, what = "raw", n = file.info(path)$size)
}

copy_file_strict <- function(from, to) {
  dir.create(dirname(to), recursive = TRUE, showWarnings = FALSE)
  if (!file.copy(from, to, overwrite = TRUE, copy.mode = TRUE)) {
    stop("Could not copy ", from, " to ", to, call. = FALSE)
  }
  if (!identical(read_raw_file(from), read_raw_file(to))) {
    stop("Copied file is not byte-identical: ", to, call. = FALSE)
  }
  invisible(to)
}

if (!file.exists(source_path) || !file.exists(direct_html_path)) {
  stop("The H03 preparation source or direct render is missing", call. = FALSE)
}
copy_file_strict(source_path, website_source_path)
copy_file_strict(direct_html_path, website_html_path)

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

direct_assets <- list_artifacts(direct_assets_path)
if (length(direct_assets) == 0L) {
  stop("The direct H03 preparation render has no page assets", call. = FALSE)
}
direct_asset_relative <- substring(
  normalizePath(direct_assets, winslash = "/", mustWork = TRUE),
  nchar(normalizePath(
    direct_assets_path,
    winslash = "/",
    mustWork = TRUE
  )) + 2L
)
website_assets <- file.path(website_assets_path, direct_asset_relative)
invisible(Map(copy_file_strict, direct_assets, website_assets))

if (!identical(
  read_raw_file(source_path),
  read_raw_file(website_source_path)
)) {
  stop(
    "The H03 website QMD copy is not byte-identical to its authoring source",
    call. = FALSE
  )
}

script_files <- list_artifacts(
  file.path(root, "scripts/hypotheses/H03"),
  pattern = "\\.R$"
)
test_files <- list_artifacts(
  file.path(root, "tests/hypotheses/H03"),
  pattern = "\\.R$"
)
model_data_files <- list_artifacts(
  file.path(root, "artifacts/06_model_data/H03")
)
model_files <- list_artifacts(
  file.path(root, "artifacts/07_models/H03")
)
diagnostic_files <- list_artifacts(
  file.path(root, "artifacts/08_diagnostics/H03")
)
table_files <- list_artifacts(
  file.path(root, "artifacts/09_tables/H03")
)
figure_files <- list_artifacts(
  file.path(root, "artifacts/10_figures/H03")
)
source_data_files <- list_artifacts(
  file.path(root, "artifacts/11_source_data/H03")
)
manifest_files <- list_artifacts(
  file.path(root, "artifacts/12_manifests/H03")
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
  "audit/decisions/figure_readability_and_layout.md",
  "audit/decisions/report011_physical_size_revalidation.md",
  "audit/decisions/reader_facing_symlog_scale.md",
  "audit/decisions/answer_in_brief_callout.md"
)
decision_files <- file.path(root, decision_relatives)

files <- unique(c(
  file.path(root, "_quarto-nathealth.yml"),
  source_path,
  direct_html_path,
  direct_assets,
  website_source_path,
  website_html_path,
  website_assets,
  file.path(root, "notebooks/hypotheses/H03.qmd"),
  file.path(root, "_build/nathealth/notebooks/hypotheses/H03.html"),
  file.path(root, "config/site_display_registry.csv"),
  file.path(root, "renv.lock"),
  file.path(
    root,
    "audit/hypotheses/H03/H03_preparation_figure_readability_qa.md"
  ),
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
      "Missing H03 preparation-report provenance file(s): ",
      paste(missing, collapse = ", ")
    ),
    call. = FALSE
  )
}

normalized_files <- normalizePath(files, winslash = "/", mustWork = TRUE)
relative <- substring(normalized_files, nchar(root) + 2L)

role <- dplyr::case_when(
  relative == "audit/hypotheses/H03/H03_analysis_preparation.qmd" ~
    "preparation_source",
  relative == "audit/hypotheses/H03/H03_analysis_preparation.html" ~
    "preparation_direct_render",
  startsWith(
    relative,
    "audit/hypotheses/H03/H03_analysis_preparation_files/"
  ) ~ "preparation_direct_page_asset",
  relative == paste0(
    "_build/nathealth/audit/hypotheses/H03/",
    "H03_analysis_preparation.html"
  ) ~ "preparation_website_render",
  relative == paste0(
    "_build/nathealth/audit/hypotheses/H03/",
    "H03_analysis_preparation.qmd"
  ) ~ "preparation_website_source",
  startsWith(
    relative,
    paste0(
      "_build/nathealth/audit/hypotheses/H03/",
      "H03_analysis_preparation_files/"
    )
  ) ~ "preparation_website_page_asset",
  relative == "notebooks/hypotheses/H03.qmd" ~ "result_report_source",
  relative == "_build/nathealth/notebooks/hypotheses/H03.html" ~
    "result_report_render",
  startsWith(relative, "scripts/hypotheses/H03/") ~ "H03_code",
  startsWith(relative, "tests/hypotheses/H03/") ~ "H03_test",
  startsWith(relative, "artifacts/06_model_data/H03/") ~
    "stored_model_data_or_contract",
  startsWith(relative, "artifacts/07_models/H03/") ~
    "stored_model_output",
  startsWith(relative, "artifacts/08_diagnostics/H03/") ~
    "stored_diagnostic_output",
  startsWith(relative, "artifacts/09_tables/H03/") ~
    "stored_table_output",
  startsWith(relative, "artifacts/10_figures/H03/") ~ "reader_figure",
  startsWith(relative, "artifacts/11_source_data/H03/") ~
    "reader_figure_or_table_source_data",
  startsWith(relative, "artifacts/12_manifests/H03/") ~
    "referenced_H03_manifest",
  relative == paste0(
    "audit/hypotheses/H03/",
    "H03_preparation_figure_readability_qa.md"
  ) ~ "visual_QA_record",
  startsWith(relative, "audit/decisions/") ~ "approved_reporting_rule",
  relative == "_quarto-nathealth.yml" ~ "shared_quarto_profile",
  relative == "config/site_display_registry.csv" ~
    "shared_display_registry",
  relative == "renv.lock" ~ "environment_lock",
  startsWith(relative, "scripts/pipeline/") ~ "shared_pipeline_code",
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
      "H03_code",
      "H03_test",
      "reader_figure_or_table_source_data",
      "shared_quarto_profile"
    ) %in% manifest$role)
) {
  stop("Invalid H03 preparation-report manifest", call. = FALSE)
}

invisible(write_csv_artifact(manifest, output_path, producer))
message(
  "H03 preparation-report manifest completed: ",
  nrow(manifest),
  " files"
)
