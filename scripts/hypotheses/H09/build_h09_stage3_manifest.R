#!/usr/bin/env Rscript

# Seal the source, render, accepted H09 inputs, and provenance for the
# standalone H09 reader report. This script hashes and inventories files only;
# it does not fit, predict, simulate, or calculate a scientific result.

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
      "The H09 reader-report manifest requires R 4.6.1; found ",
      as.character(getRversion())
    ),
    call. = FALSE
  )
}

producer <- "scripts/hypotheses/H09/build_h09_stage3_manifest.R"
output_path <- file.path(
  root,
  "artifacts/12_manifests/H09/H09_stage3_artifacts.csv"
)
stage2_manifest_path <- file.path(
  root,
  "artifacts/12_manifests/H09/H09_stage2_artifacts.csv"
)
mutable_handoff <- "audit/handoffs/H09_worker_handoff.md"

# The continuing handoff changes at each gate. Verify every other identity in
# the accepted Stage 2 inventory before sealing the current reader report.
stage2_manifest <- readr::read_csv(
  stage2_manifest_path,
  show_col_types = FALSE
)
stage2_frozen <- stage2_manifest |>
  filter(.data$path != mutable_handoff)
stage2_absolute <- file.path(root, stage2_frozen$path)
if (any(!file.exists(stage2_absolute))) {
  stop("A frozen H09 Stage 2 artifact is missing", call. = FALSE)
}
stage2_observed_sha256 <- unname(vapply(
  stage2_absolute,
  artifact_sha256,
  character(1)
))
if (!identical(stage2_observed_sha256, stage2_frozen$sha256)) {
  changed <- stage2_frozen$path[
    stage2_observed_sha256 != stage2_frozen$sha256
  ]
  stop(
    paste0(
      "Frozen H09 Stage 2 artifact identities changed: ",
      paste(changed, collapse = ", ")
    ),
    call. = FALSE
  )
}

inventory_roots <- file.path(
  root,
  c(
    "scripts/hypotheses/H09",
    "tests/hypotheses/H09",
    "audit/hypotheses/H09",
    "artifacts/06_model_data/H09",
    "artifacts/07_models/H09",
    "artifacts/08_diagnostics/H09",
    "artifacts/09_tables/H09",
    "artifacts/10_figures/H09",
    "artifacts/11_source_data/H09",
    "artifacts/12_manifests/H09"
  )
)
inventory_files <- unlist(lapply(
  inventory_roots[dir.exists(inventory_roots)],
  list.files,
  recursive = TRUE,
  full.names = TRUE,
  include.dirs = FALSE
))

supporting_files <- file.path(
  root,
  c(
    "AGENTS.md",
    "renv.lock",
    "_quarto.yml",
    "_quarto-nathealth.yml",
    "notebooks/hypotheses/H09.qmd",
    "_build/nathealth/notebooks/hypotheses/H09.html",
    mutable_handoff,
    "audit/handoffs/H09_shared_change_request.md",
    "scripts/pipeline/paths_io.R",
    "scripts/pipeline/p_value_display.R",
    "config/metric_display_registry.csv",
    "config/site_display_registry.csv",
    "audit/evidence/preregistration_contract.md",
    "audit/hypotheses/H03-H11_gated_workflow.qmd",
    "audit/hypotheses/H09-H11_migration_map.md",
    "audit/decisions/model_reporting.md",
    "audit/decisions/p_value_display_conventions.md",
    "audit/decisions/paired_placement_comparison_display.md",
    "audit/decisions/site_display_conventions.md",
    "audit/decisions/gap_timing_unaware_dataset_terminology.md",
    "audit/decisions/bootstrap_execution_policy.md",
    "audit/decisions/figure_readability_and_layout.md",
    "audit/decisions/reader_facing_symlog_scale.md",
    "audit/decisions/placement_decision.md"
  )
)

files <- sort(unique(c(
  inventory_files,
  supporting_files[file.exists(supporting_files)]
)))
files <- files[file.exists(files) & !dir.exists(files)]

excluded <- normalizePath(
  c(
    output_path,
    file.path(
      root,
      "audit/hypotheses/H09/H09_analysis_preparation.qmd"
    )
  ),
  winslash = "/",
  mustWork = FALSE
)
normalized_files <- normalizePath(files, winslash = "/", mustWork = TRUE)
files <- normalized_files[!normalized_files %in% excluded]
relative <- substring(files, nchar(root) + 2L)

artifact_class <- dplyr::case_when(
  relative == "notebooks/hypotheses/H09.qmd" ~ "reader_report_source",
  relative == "_build/nathealth/notebooks/hypotheses/H09.html" ~
    "reader_report_render",
  startsWith(relative, "scripts/hypotheses/H09/") ~ "H09_code",
  startsWith(relative, "tests/hypotheses/H09/") ~ "H09_test",
  startsWith(relative, "audit/hypotheses/H09/") ~ "H09_audit_report",
  relative == mutable_handoff ~ "H09_continuing_handoff",
  relative == "audit/handoffs/H09_shared_change_request.md" ~
    "H09_shared_change_request",
  startsWith(relative, "audit/decisions/") ~ "shared_reporting_decision",
  relative == "audit/evidence/preregistration_contract.md" ~
    "preregistration_contract",
  relative == "audit/hypotheses/H03-H11_gated_workflow.qmd" ~
    "gated_workflow",
  relative == "audit/hypotheses/H09-H11_migration_map.md" ~ "migration_map",
  relative == "scripts/pipeline/p_value_display.R" ~
    "shared_reporting_helper",
  relative == "scripts/pipeline/paths_io.R" ~ "shared_io_helper",
  startsWith(relative, "artifacts/06_model_data/H09/") ~
    "frozen_model_data_or_contract",
  startsWith(relative, "artifacts/07_models/H09/") ~ "frozen_model_archive",
  startsWith(relative, "artifacts/08_diagnostics/H09/") ~
    "frozen_diagnostic_source",
  startsWith(relative, "artifacts/09_tables/H09/") ~ "frozen_table_source",
  startsWith(relative, "artifacts/10_figures/H09/") ~ "H09_figure",
  startsWith(relative, "artifacts/11_source_data/H09/") ~
    "H09_figure_source_data",
  startsWith(relative, "artifacts/12_manifests/H09/") ~
    "prior_H09_manifest",
  startsWith(relative, "config/") ~ "shared_display_registry",
  relative %in% c("_quarto.yml", "_quarto-nathealth.yml") ~
    "shared_quarto_configuration",
  relative == "renv.lock" ~ "environment_lock",
  relative == "AGENTS.md" ~ "project_instructions",
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
    output_path %in% file.path(root, inventory$path)
) {
  stop("Invalid H09 reader-report artifact inventory", call. = FALSE)
}

dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
invisible(write_csv_artifact(inventory, output_path, producer))
message(
  "H09 reader-report artifact manifest completed: ",
  nrow(inventory),
  " files; all frozen Stage 2 identities unchanged"
)
