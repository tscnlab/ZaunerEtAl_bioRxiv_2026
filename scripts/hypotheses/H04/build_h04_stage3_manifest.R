#!/usr/bin/env Rscript

# Seal the H04 reader report, rendered page, H04 artifacts, and supporting
# provenance. This script performs hashing and structural inventory only; it
# does not fit a model or calculate a scientific result.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
project_library <- file.path(
  root,
  "renv/library/macos/R-4.6/aarch64-apple-darwin23"
)
.libPaths(c(project_library, .libPaths()))

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(tibble)
})

source(file.path(root, "scripts/pipeline/paths_io.R"))

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop(
    "H04 reader-report manifest requires R 4.6.1; found ",
    as.character(getRversion()),
    call. = FALSE
  )
}

producer <- "scripts/hypotheses/H04/build_h04_stage3_manifest.R"
output_path <- file.path(
  root,
  "artifacts/12_manifests/H04/H04_stage3_artifacts.csv"
)
handoff_path <- file.path(root, "audit/handoffs/H04_worker_handoff.md")
preparation_manifest_path <- file.path(
  root,
  "artifacts/12_manifests/H04/H04_preparation_report_manifest.csv"
)

inventory_roots <- file.path(
  root,
  c(
    "scripts/hypotheses/H04",
    "tests/hypotheses/H04",
    "audit/hypotheses/H04",
    "artifacts/06_model_data/H04",
    "artifacts/07_models/H04",
    "artifacts/08_diagnostics/H04",
    "artifacts/09_tables/H04",
    "artifacts/10_figures/H04",
    "artifacts/11_source_data/H04",
    "artifacts/12_manifests/H04",
    "_build/nathealth/notebooks/hypotheses/H04_files",
    "_build/nathealth/artifacts/06_model_data/H04",
    "_build/nathealth/artifacts/08_diagnostics/H04",
    "_build/nathealth/artifacts/09_tables/H04",
    "_build/nathealth/artifacts/10_figures/H04",
    "_build/nathealth/artifacts/11_source_data/H04"
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
    "notebooks/hypotheses/H04.qmd",
    "_build/nathealth/notebooks/hypotheses/H04.html",
    "_quarto.yml",
    "_quarto-nathealth.yml",
    "renv.lock",
    "config/site_display_registry.csv",
    "audit/hypotheses/H03-H11_gated_workflow.qmd",
    "audit/hypotheses/H03_H04_category_support_gate.md",
    "audit/decisions/p_value_display_conventions.md",
    "audit/decisions/paired_placement_comparison_display.md",
    "audit/decisions/gap_timing_unaware_dataset_terminology.md",
    "audit/decisions/answer_in_brief_callout.md",
    "audit/decisions/figure_readability_and_layout.md",
    "audit/decisions/reader_facing_symlog_scale.md",
    "scripts/pipeline/p_value_display.R",
    "scripts/pipeline/paths_io.R"
  )
)

files <- sort(unique(c(inventory_files, single_files)))
files <- files[file.exists(files) & !dir.exists(files)]
files <- normalizePath(files, winslash = "/", mustWork = TRUE)
# The preparation manifest records this result-report manifest. Excluding the
# preparation manifest here prevents a reciprocal hash cycle while retaining
# every other H04 preparation artifact in the result-report inventory.
excluded <- normalizePath(
  c(output_path, handoff_path, preparation_manifest_path),
  winslash = "/",
  mustWork = FALSE
)
files <- files[!files %in% excluded]
relative <- substring(files, nchar(root) + 2L)

artifact_class <- case_when(
  relative == "notebooks/hypotheses/H04.qmd" ~ "reader_report_source",
  relative == "_build/nathealth/notebooks/hypotheses/H04.html" ~
    "reader_report_render",
  startsWith(relative, "_build/nathealth/notebooks/hypotheses/H04_files/") ~
    "reader_report_page_asset",
  startsWith(relative, "_build/nathealth/artifacts/") ~
    "reader_report_linked_asset",
  startsWith(relative, "scripts/hypotheses/H04/") ~ "H04_code",
  startsWith(relative, "tests/hypotheses/H04/") ~ "H04_test",
  startsWith(relative, "audit/hypotheses/H04/") ~ "H04_audit_report",
  startsWith(relative, "audit/decisions/") ~ "coordinator_decision",
  relative %in% c(
    "scripts/pipeline/p_value_display.R",
    "scripts/pipeline/paths_io.R"
  ) ~ "shared_reporting_helper",
  startsWith(relative, "artifacts/06_model_data/H04/") ~
    "H04_model_data_or_contract",
  startsWith(relative, "artifacts/07_models/H04/") ~ "H04_model_archive",
  startsWith(relative, "artifacts/08_diagnostics/H04/") ~ "H04_diagnostic",
  startsWith(relative, "artifacts/09_tables/H04/") ~ "H04_table",
  startsWith(relative, "artifacts/10_figures/H04/") ~ "H04_figure",
  startsWith(relative, "artifacts/11_source_data/H04/") ~ "H04_source_data",
  startsWith(relative, "artifacts/12_manifests/H04/") ~
    "prior_H04_manifest",
  relative %in% c("_quarto.yml", "_quarto-nathealth.yml") ~
    "shared_quarto_configuration",
  relative == "config/site_display_registry.csv" ~ "shared_display_registry",
  relative == "renv.lock" ~ "environment_lock",
  TRUE ~ "supporting_provenance"
)
artifact_type <- tolower(tools::file_ext(relative))
artifact_type[artifact_type == ""] <- "file"

inventory <- tibble::tibble(
  path = relative,
  artifact_class = artifact_class,
  artifact_type = artifact_type,
  sha256 = unname(vapply(files, artifact_sha256, character(1))),
  bytes = as.numeric(file.info(files)$size),
  producer = producer,
  r_version = as.character(getRversion()),
  written_utc = format(Sys.time(), tz = "UTC", usetz = TRUE)
) |>
  arrange(.data$artifact_class, .data$path)

if (
  anyDuplicated(inventory$path) ||
    anyNA(inventory$sha256) ||
    any(nchar(inventory$sha256) != 64L) ||
    normalizePath(output_path, winslash = "/", mustWork = FALSE) %in% files ||
    normalizePath(handoff_path, winslash = "/", mustWork = FALSE) %in% files ||
    normalizePath(
      preparation_manifest_path,
      winslash = "/",
      mustWork = FALSE
    ) %in% files
) {
  stop("Invalid H04 reader-report artifact inventory", call. = FALSE)
}

dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
invisible(write_csv_artifact(inventory, output_path, producer))
message("H04 reader-report manifest completed: ", nrow(inventory), " files")
