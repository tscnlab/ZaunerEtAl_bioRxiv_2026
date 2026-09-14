#!/usr/bin/env Rscript

# Seal the source, render, frozen inputs, reader assets, QA evidence, and
# provenance for the standalone H10 report. Hashing and file inventory are
# structural operations; no scientific result is recalculated here.

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
  stop("H10 reader manifest requires R 4.6.1", call. = FALSE)
}

producer <- "scripts/hypotheses/H10/build_h10_stage3_manifest.R"
output_path <- file.path(
  root,
  "artifacts/12_manifests/H10/H10_stage3_artifacts.csv"
)
downstream_preparation_manifest_path <- file.path(
  root,
  "artifacts/12_manifests/H10/H10_preparation_report_manifest.csv"
)
stage2_manifest_path <- file.path(
  root,
  "artifacts/12_manifests/H10/H10_stage2_artifacts.csv"
)

stage2_manifest <- readr::read_csv(
  stage2_manifest_path,
  show_col_types = FALSE
)
# H10 handoff records are intentionally updated at later gates. They remain
# in the final reader inventory below, but are not frozen scientific outputs.
stage2_frozen_manifest <- stage2_manifest |>
  filter(!startsWith(.data$path, "audit/handoffs/H10_"))
stage2_paths <- file.path(root, stage2_frozen_manifest$path)
if (any(!file.exists(stage2_paths))) {
  stop("A frozen H10 numerical-package artifact is missing", call. = FALSE)
}
stage2_observed_sha256 <- unname(vapply(
  stage2_paths,
  artifact_sha256,
  character(1)
))
if (!identical(stage2_observed_sha256, stage2_frozen_manifest$sha256)) {
  changed <- stage2_frozen_manifest$path[
    stage2_observed_sha256 != stage2_frozen_manifest$sha256
  ]
  stop(
    paste0(
      "Frozen H10 numerical-package identities changed: ",
      paste(changed, collapse = ", ")
    ),
    call. = FALSE
  )
}

inventory_roots <- file.path(
  root,
  c(
    "scripts/hypotheses/H10",
    "tests/hypotheses/H10",
    "audit/hypotheses/H10",
    "artifacts/06_model_data/H10",
    "artifacts/07_models/H10",
    "artifacts/08_diagnostics/H10",
    "artifacts/09_tables/H10",
    "artifacts/10_figures/H10",
    "artifacts/11_source_data/H10",
    "artifacts/12_manifests/H10",
    "_build/nathealth/notebooks/hypotheses/H10_files",
    "_build/nathealth/artifacts/08_diagnostics/H10",
    "_build/nathealth/artifacts/09_tables/H10",
    "_build/nathealth/artifacts/10_figures/H10",
    "_build/nathealth/artifacts/11_source_data/H10"
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
    "notebooks/hypotheses/H10.qmd",
    "_build/nathealth/notebooks/hypotheses/H10.html",
    "audit/handoffs/H10_worker_handoff.md",
    "audit/handoffs/H10_shared_change_request.md",
    "audit/decisions/p_value_display_conventions.md",
    "audit/decisions/paired_placement_comparison_display.md",
    "audit/decisions/gap_timing_unaware_dataset_terminology.md",
    "audit/decisions/answer_in_brief_callout.md",
    "audit/decisions/figure_readability_and_layout.md",
    "audit/decisions/report011_physical_size_revalidation.md",
    "audit/decisions/reader_facing_symlog_scale.md",
    "audit/decisions/preparation06_current_base_model_gate.md",
    "audit/decisions/mder_mean_of_viable_ratios.md",
    "audit/decisions/l10_numerical_zero_normalization.md",
    "audit/reconciliation/l10_METRIC-011/METRIC-011_evidence_manifest.csv",
    "scripts/pipeline/p_value_display.R"
  )
)

files <- sort(unique(c(inventory_files, single_files, stage2_paths)))
files <- files[file.exists(files) & !dir.exists(files)]
normalized_files <- normalizePath(files, winslash = "/", mustWork = TRUE)
normalized_output <- normalizePath(
  output_path,
  winslash = "/",
  mustWork = FALSE
)
normalized_downstream_preparation_manifest <- normalizePath(
  downstream_preparation_manifest_path,
  winslash = "/",
  mustWork = FALSE
)
files <- normalized_files[
  !normalized_files %in% c(
    normalized_output,
    normalized_downstream_preparation_manifest
  )
]
relative <- substring(files, nchar(root) + 2L)

artifact_class <- dplyr::case_when(
  relative == "notebooks/hypotheses/H10.qmd" ~ "reader_report_source",
  relative == "_build/nathealth/notebooks/hypotheses/H10.html" ~
    "reader_report_render",
  startsWith(
    relative,
    "_build/nathealth/notebooks/hypotheses/H10_files/"
  ) ~
    "reader_report_page_asset",
  startsWith(relative, "_build/nathealth/artifacts/") ~
    "reader_report_linked_asset",
  startsWith(relative, "scripts/hypotheses/H10/") ~ "H10_code",
  startsWith(relative, "tests/hypotheses/H10/") ~ "H10_test",
  startsWith(relative, "audit/hypotheses/H10/") ~ "H10_audit_record",
  startsWith(relative, "audit/handoffs/H10_") ~ "H10_handoff",
  startsWith(relative, "audit/decisions/") ~ "coordinator_decision",
  relative == "scripts/pipeline/p_value_display.R" ~ "shared_reporting_helper",
  startsWith(relative, "artifacts/06_model_data/H10/") ~
    "frozen_model_data_or_contract",
  startsWith(relative, "artifacts/07_models/H10/") ~ "frozen_model_archive",
  startsWith(relative, "artifacts/08_diagnostics/H10/") ~
    "frozen_diagnostic_source",
  startsWith(relative, "artifacts/09_tables/H10/") ~ "frozen_table_source",
  startsWith(relative, "artifacts/10_figures/H10/") ~ "H10_figure",
  startsWith(relative, "artifacts/11_source_data/H10/") ~
    "H10_paired_source_data",
  startsWith(relative, "artifacts/12_manifests/H10/") ~ "H10_manifest_or_QA",
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
  arrange(.data$artifact_class, .data$path)

if (
  nrow(inventory) <= 80L ||
    anyDuplicated(inventory$path) ||
    anyNA(inventory$sha256) ||
    any(nchar(inventory$sha256) != 64L) ||
    normalized_output %in% files ||
    normalized_downstream_preparation_manifest %in% files
) {
  stop("Invalid H10 reader artifact inventory", call. = FALSE)
}

dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
invisible(write_csv_artifact(inventory, output_path, producer))
message(
  "H10 reader artifact manifest completed: ",
  nrow(inventory),
  " files; frozen numerical-package identities unchanged"
)
