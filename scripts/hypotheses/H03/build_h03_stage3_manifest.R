#!/usr/bin/env Rscript

# Seal the H03 reader report, rendered page, linked inputs, and H03 provenance.
# This script performs hashing and structural inventory only. It does not fit
# a model, resample observations, simulate data, or calculate a scientific
# result.

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
source(file.path(root, "scripts/pipeline/paths_io.R"))

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop(
    paste0(
      "The H03 Stage 3 manifest requires R 4.6.1; found ",
      as.character(getRversion())
    ),
    call. = FALSE
  )
}

producer <- "scripts/hypotheses/H03/build_h03_stage3_manifest.R"
output_path <- file.path(
  root,
  "artifacts/12_manifests/H03/H03_stage3_artifacts.csv"
)
preparation_manifest_path <- file.path(
  root,
  "artifacts/12_manifests/H03/H03_preparation_report_manifest.csv"
)
handoff_path <- file.path(root, "audit/handoffs/H03_worker_handoff.md")

inventory_roots <- file.path(
  root,
  c(
    "scripts/hypotheses/H03",
    "tests/hypotheses/H03",
    "audit/hypotheses/H03",
    "artifacts/06_model_data/H03",
    "artifacts/07_models/H03",
    "artifacts/08_diagnostics/H03",
    "artifacts/09_tables/H03",
    "artifacts/10_figures/H03",
    "artifacts/11_source_data/H03",
    "artifacts/12_manifests/H03",
    "_build/nathealth/notebooks/hypotheses/H03_files",
    "_build/nathealth/artifacts/08_diagnostics/H03",
    "_build/nathealth/artifacts/09_tables/H03",
    "_build/nathealth/artifacts/10_figures/H03",
    "_build/nathealth/artifacts/11_source_data/H03"
  )
)
inventory_files <- unlist(lapply(
  inventory_roots[dir.exists(inventory_roots)],
  list.files,
  recursive = TRUE,
  full.names = TRUE,
  include.dirs = FALSE
))

single_files <- file.path(
  root,
  c(
    "_quarto.yml",
    "_quarto-nathealth.yml",
    "renv.lock",
    "config/site_display_registry.csv",
    "notebooks/hypotheses/H03.qmd",
    "_build/nathealth/notebooks/hypotheses/H03.html",
    "audit/hypotheses/H03-H11_gated_workflow.qmd",
    "audit/hypotheses/H01-H04_migration_map.md",
    "audit/decisions/p_value_display_conventions.md",
    "audit/decisions/paired_placement_comparison_display.md",
    "audit/decisions/gap_timing_unaware_dataset_terminology.md",
    "audit/decisions/answer_in_brief_callout.md",
    "audit/decisions/figure_readability_and_layout.md",
    "audit/decisions/reader_facing_symlog_scale.md",
    "scripts/pipeline/p_value_display.R"
  )
)

files <- sort(unique(c(inventory_files, single_files)))
files <- files[file.exists(files) & !dir.exists(files)]
normalized_files <- normalizePath(files, winslash = "/", mustWork = TRUE)
excluded <- normalizePath(
  c(
    output_path,
    # The Stage 4 manifest records this Stage 3 manifest. Excluding the
    # reciprocal edge prevents an impossible circular hash dependency.
    preparation_manifest_path,
    handoff_path,
    file.path(
      root,
      "audit/hypotheses/H03/H03_analysis_preparation.qmd"
    )
  ),
  winslash = "/",
  mustWork = FALSE
)
files <- normalized_files[!normalized_files %in% excluded]
relative <- substring(files, nchar(root) + 2L)

artifact_class <- dplyr::case_when(
  relative == "notebooks/hypotheses/H03.qmd" ~ "reader_report_source",
  relative == "_build/nathealth/notebooks/hypotheses/H03.html" ~
    "reader_report_render",
  startsWith(relative, "_build/nathealth/notebooks/hypotheses/H03_files/") ~
    "reader_report_page_asset",
  startsWith(relative, "_build/nathealth/artifacts/") ~
    "reader_report_linked_asset",
  startsWith(relative, "scripts/hypotheses/H03/") ~ "H03_code",
  startsWith(relative, "tests/hypotheses/H03/") ~ "H03_test",
  startsWith(relative, "audit/hypotheses/H03/") ~ "H03_audit_report",
  startsWith(relative, "audit/decisions/") ~ "coordinator_decision",
  relative == "scripts/pipeline/p_value_display.R" ~
    "shared_reporting_helper",
  startsWith(relative, "artifacts/06_model_data/H03/") ~
    "H03_model_data_or_contract",
  startsWith(relative, "artifacts/07_models/H03/") ~ "H03_model_archive",
  startsWith(relative, "artifacts/08_diagnostics/H03/") ~ "H03_diagnostic",
  startsWith(relative, "artifacts/09_tables/H03/") ~ "H03_table",
  startsWith(relative, "artifacts/10_figures/H03/") ~ "H03_figure",
  startsWith(relative, "artifacts/11_source_data/H03/") ~ "H03_source_data",
  startsWith(relative, "artifacts/12_manifests/H03/") ~ "prior_H03_manifest",
  relative %in% c("_quarto.yml", "_quarto-nathealth.yml") ~
    "shared_quarto_configuration",
  relative == "config/site_display_registry.csv" ~ "shared_display_registry",
  relative == "renv.lock" ~ "environment_lock",
  TRUE ~ "supporting_provenance"
)
artifact_type <- tolower(tools::file_ext(relative))
artifact_type[artifact_type == ""] <- "file"
written_utc <- format(Sys.time(), tz = "UTC", usetz = TRUE)

inventory <- tibble::tibble(
  path = relative,
  artifact_class = artifact_class,
  artifact_type = artifact_type,
  sha256 = unname(vapply(files, artifact_sha256, character(1))),
  bytes = as.numeric(file.info(files)$size),
  producer = producer,
  r_version = as.character(getRversion()),
  written_utc = written_utc
) |>
  arrange(.data$artifact_class, .data$path)

if (
  anyDuplicated(inventory$path) ||
    anyNA(inventory$sha256) ||
    any(nchar(inventory$sha256) != 64L) ||
    output_path %in% file.path(root, inventory$path) ||
    handoff_path %in% file.path(root, inventory$path)
) {
  stop("Invalid H03 Stage 3 artifact inventory", call. = FALSE)
}

dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
invisible(write_csv_artifact(inventory, output_path, producer))
message("H03 Stage 3 artifact manifest completed: ", nrow(inventory), " files")
