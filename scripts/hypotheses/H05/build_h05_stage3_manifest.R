#!/usr/bin/env Rscript

# Seal the source, render, displayed inputs, and provenance for the standalone
# H05 reader report. This script performs hashing and structural inventory only;
# it does not fit a model or calculate a scientific result.

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
      "The H05 Stage 3 manifest requires R 4.6.1; found ",
      as.character(getRversion())
    ),
    call. = FALSE
  )
}

producer <- "scripts/hypotheses/H05/build_h05_stage3_manifest.R"
output_path <- file.path(
  root,
  "artifacts/12_manifests/H05/H05_stage3_artifacts.csv"
)
stage3_handoff_path <- file.path(
  root,
  "audit/handoffs/H05_stage3_handoff.md"
)
stage2_manifest_path <- file.path(
  root,
  "artifacts/12_manifests/H05/H05_stage2_artifacts.csv"
)

stage2_manifest <- readr::read_csv(
  stage2_manifest_path,
  show_col_types = FALSE
)
stage2_absolute_paths <- file.path(root, stage2_manifest$path)
if (any(!file.exists(stage2_absolute_paths))) {
  stop("A frozen H05 Stage 2 artifact is missing", call. = FALSE)
}
stage2_observed_sha256 <- unname(vapply(
  stage2_absolute_paths,
  artifact_sha256,
  character(1)
))
if (!identical(stage2_observed_sha256, stage2_manifest$sha256)) {
  changed <- stage2_manifest$path[
    stage2_observed_sha256 != stage2_manifest$sha256
  ]
  stop(
    paste0(
      "Frozen H05 Stage 2 artifact identities changed: ",
      paste(changed, collapse = ", ")
    ),
    call. = FALSE
  )
}

inventory_roots <- file.path(
  root,
  c(
    "scripts/hypotheses/H05",
    "tests/hypotheses/H05",
    "audit/hypotheses/H05",
    "artifacts/06_model_data/H05",
    "artifacts/07_models/H05",
    "artifacts/08_diagnostics/H05",
    "artifacts/09_tables/H05",
    "artifacts/10_figures/H05",
    "artifacts/11_source_data/H05",
    "artifacts/12_manifests/H05",
    "_build/nathealth/notebooks/hypotheses/H05_files",
    "_build/nathealth/artifacts/09_tables/H05",
    "_build/nathealth/artifacts/10_figures/H05",
    "_build/nathealth/artifacts/11_source_data/H05"
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
    "notebooks/hypotheses/H05.qmd",
    "_build/nathealth/notebooks/hypotheses/H05.html",
    "audit/handoffs/H05_stage1_handoff.md",
    "audit/handoffs/H05_stage2_handoff.md",
    "audit/decisions/h05_stage2_gate_and_stage3_transition.md",
    "audit/decisions/p_value_display_conventions.md",
    "audit/decisions/paired_placement_comparison_display.md",
    "audit/decisions/gap_timing_unaware_dataset_terminology.md",
    "audit/decisions/manuscript_prepared_data_sensitivity.md",
    "audit/decisions/mder_mean_of_viable_ratios.md",
    "audit/decisions/l10_numerical_zero_normalization.md",
    paste0(
      "audit/reconciliation/l10_METRIC-011/",
      "METRIC-011_evidence_manifest.csv"
    ),
    "audit/decisions/answer_in_brief_callout.md",
    "audit/decisions/figure_readability_and_layout.md",
    "audit/decisions/report011_physical_size_revalidation.md",
    "audit/decisions/reader_facing_symlog_scale.md",
    "audit/ledgers/hypothesis_stage_gates.csv",
    "audit/ledgers/change_log.csv",
    "scripts/pipeline/p_value_display.R"
  )
)
files <- sort(unique(c(inventory_files, single_files)))
files <- files[file.exists(files) & !dir.exists(files)]

excluded <- normalizePath(
  c(
    output_path,
    stage3_handoff_path,
    file.path(
      root,
      "audit/hypotheses/H05/H05_analysis_preparation.qmd"
    ),
    file.path(
      root,
      "scripts/hypotheses/H05/build_h05_preparation_artifacts.R"
    ),
    file.path(
      root,
      "scripts/hypotheses/H05/build_h05_preparation_report_manifest.R"
    ),
    file.path(
      root,
      "scripts/hypotheses/H05/build_h05_figure_readability_qa.R"
    ),
    file.path(
      root,
      "tests/hypotheses/H05/test_h05_preparation_report.R"
    ),
    file.path(
      root,
      "artifacts/12_manifests/H05/H05_figure_readability_qa.csv"
    ),
    file.path(
      root,
      "artifacts/12_manifests/H05/H05_preparation_report_manifest.csv"
    ),
    file.path(
      root,
      paste0(
        "artifacts/11_source_data/H05/",
        "H05_preparation_sample_support.csv"
      )
    ),
    file.path(
      root,
      paste0(
        "artifacts/11_source_data/H05/",
        "H05_preparation_leba_score_distribution.csv"
      )
    ),
    file.path(
      root,
      paste0(
        "artifacts/11_source_data/H05/",
        "H05_preparation_site_support.csv"
      )
    ),
    file.path(
      root,
      paste0(
        "artifacts/11_source_data/H05/",
        "H05_preparation_site_support_summary.csv"
      )
    )
  ),
  winslash = "/",
  mustWork = FALSE
)
normalized_files <- normalizePath(files, winslash = "/", mustWork = TRUE)
files <- normalized_files[!normalized_files %in% excluded]
relative <- substring(files, nchar(root) + 2L)

artifact_class <- dplyr::case_when(
  relative == "notebooks/hypotheses/H05.qmd" ~ "reader_report_source",
  relative == "_build/nathealth/notebooks/hypotheses/H05.html" ~
    "reader_report_render",
  startsWith(
    relative,
    "_build/nathealth/notebooks/hypotheses/H05_files/"
  ) ~
    "reader_report_page_asset",
  startsWith(relative, "_build/nathealth/artifacts/") ~
    "reader_report_linked_asset",
  startsWith(relative, "scripts/hypotheses/H05/") ~ "H05_code",
  startsWith(relative, "tests/hypotheses/H05/") ~ "H05_test",
  startsWith(relative, "audit/hypotheses/H05/") ~ "H05_audit_report",
  startsWith(relative, "audit/handoffs/H05_") ~ "H05_prior_handoff",
  startsWith(relative, "audit/decisions/") ~ "coordinator_decision",
  startsWith(relative, "audit/ledgers/") ~ "coordinator_ledger_snapshot",
  relative == "scripts/pipeline/p_value_display.R" ~ "shared_reporting_helper",
  startsWith(relative, "artifacts/06_model_data/H05/") ~
    "frozen_model_data_or_contract",
  startsWith(relative, "artifacts/07_models/H05/") ~ "frozen_model_archive",
  startsWith(relative, "artifacts/08_diagnostics/H05/") ~
    "frozen_diagnostic_source",
  startsWith(relative, "artifacts/09_tables/H05/") ~ "frozen_table_source",
  startsWith(relative, "artifacts/10_figures/H05/") ~ "H05_figure",
  startsWith(relative, "artifacts/11_source_data/H05/") ~
    "H05_paired_source_data",
  startsWith(relative, "artifacts/12_manifests/H05/") ~ "prior_H05_manifest",
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
    stage3_handoff_path %in% file.path(root, inventory$path)
) {
  stop("Invalid H05 Stage 3 artifact inventory", call. = FALSE)
}

dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
invisible(write_csv_artifact(inventory, output_path, producer))
message(
  "H05 Stage 3 artifact manifest completed: ",
  nrow(inventory),
  " files; all frozen Stage 2 identities unchanged"
)
