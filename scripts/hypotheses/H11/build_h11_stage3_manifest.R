#!/usr/bin/env Rscript

# Seal the scoped H11 Stage 3 reader deliverables and their read-only policy
# inputs. The manifest excludes itself to avoid a circular digest.

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
  stop("H11 Stage 3 manifest requires R 4.6.1", call. = FALSE)
}

producer <- "scripts/hypotheses/H11/build_h11_stage3_manifest.R"
manifest_path <- file.path(
  root,
  "artifacts/12_manifests/H11/H11_stage3_artifact_manifest.csv"
)

scoped_files <- function(relative_directory) {
  directory <- file.path(root, relative_directory)
  if (!dir.exists(directory)) {
    stop("Missing H11 Stage 3 directory: ", relative_directory, call. = FALSE)
  }
  paths <- list.files(directory, recursive = TRUE, full.names = TRUE)
  paths[file.info(paths)$isdir %in% FALSE]
}

canonical_artifacts <- c(
  scoped_files("artifacts/06_model_data/H11/stage3"),
  scoped_files("artifacts/08_diagnostics/H11/stage3"),
  scoped_files("artifacts/09_tables/H11/stage3"),
  scoped_files("artifacts/10_figures/H11/stage3"),
  scoped_files("artifacts/11_source_data/H11/stage3")
)

figure_manifests <- file.path(
  root,
  c(
    "artifacts/12_manifests/H11/H11_stage3_figure_manifest.csv",
    "artifacts/12_manifests/H11/H11_stage3_figure_readability_qa.csv",
    "artifacts/12_manifests/H11/H11_stage3_figure_A4_proofs.pdf"
  )
)
sources <- file.path(
  root,
  c(
    "notebooks/hypotheses/H11.qmd",
    "scripts/hypotheses/H11/build_h11_stage3_reader_artifacts.R",
    "scripts/hypotheses/H11/build_h11_stage3_figures.R",
    "scripts/hypotheses/H11/finalize_h11_stage3_figure_qa.R",
    "scripts/hypotheses/H11/build_h11_stage3_manifest.R",
    "tests/hypotheses/H11/test_h11_stage3_reader_report.R"
  )
)
audit_records <- file.path(
  root,
  c(
    "audit/hypotheses/H11/03_stage2_gate_and_stage3_transition.md",
    "audit/hypotheses/H11/03_figure_readability_qa.md",
    "audit/hypotheses/H11/03_stage3_author_gate.md",
    "audit/hypotheses/H11/04_activity_context_amendment.md",
    "audit/hypotheses/H11/04_activity_context_results_and_stage3_revision.md",
    "audit/hypotheses/H11/05_reader_diagnostic_figure_addition.md"
  )
)
policy_inputs <- file.path(
  root,
  c(
    "audit/decisions/p_value_display_conventions.md",
    "audit/decisions/paired_placement_comparison_display.md",
    "audit/decisions/gap_timing_unaware_dataset_terminology.md",
    "audit/decisions/figure_readability_and_layout.md",
    "audit/decisions/reader_facing_symlog_scale.md",
    "audit/decisions/answer_in_brief_callout.md",
    "audit/decisions/model_reporting.md",
    "audit/hypotheses/implementation_result_comparison_contract.qmd",
    "scripts/pipeline/p_value_display.R",
    "artifacts/12_manifests/H11/H11_stage2_output_hashes.csv"
  )
)
scientific_input_manifests <- file.path(
  root,
  "artifacts/12_manifests/H11/H11_activity_context_output_hashes.csv"
)
rendered <- file.path(
  root,
  "_build/nathealth/notebooks/hypotheses/H11.html"
)

inventory <- dplyr::bind_rows(
  tibble::tibble(path = canonical_artifacts, role = "reader_artifact"),
  tibble::tibble(path = figure_manifests, role = "reader_manifest"),
  tibble::tibble(path = sources, role = "source_or_test"),
  tibble::tibble(path = audit_records, role = "audit_or_gate"),
  tibble::tibble(path = policy_inputs, role = "read_only_policy_input"),
  tibble::tibble(
    path = scientific_input_manifests,
    role = "verified_scientific_input_manifest"
  ),
  tibble::tibble(path = rendered, role = "rendered_report")
) |>
  dplyr::distinct(.data$path, .keep_all = TRUE) |>
  dplyr::filter(.data$path != .env$manifest_path)

missing <- inventory$path[!file.exists(inventory$path)]
if (length(missing) > 0L) {
  stop("Missing H11 Stage 3 inventory item: ", paste(missing, collapse = ", "),
    call. = FALSE
  )
}

inventory <- inventory |>
  dplyr::mutate(
    path = substring(.data$path, nchar(root) + 2L),
    sha256 = unname(vapply(
      file.path(root, .data$path),
      artifact_sha256,
      character(1)
    )),
    bytes = unname(file.info(file.path(root, .data$path))$size),
    r_version = as.character(getRversion()),
    producer = .env$producer
  ) |>
  dplyr::arrange(.data$role, .data$path)

stopifnot(
  nrow(inventory) >= 50L,
  any(inventory$path == "notebooks/hypotheses/H11.qmd"),
  any(inventory$path ==
    "_build/nathealth/notebooks/hypotheses/H11.html"),
  any(inventory$path ==
    "artifacts/12_manifests/H11/H11_stage3_figure_A4_proofs.pdf"),
  !any(inventory$path ==
    "artifacts/10_figures/H11/stage3/H11_reader_figure_A4_proofs.pdf"),
  any(inventory$path ==
    "audit/hypotheses/H11/03_stage3_author_gate.md"),
  any(inventory$path ==
    "audit/hypotheses/H11/04_activity_context_results_and_stage3_revision.md"),
  any(inventory$path ==
    "audit/hypotheses/H11/05_reader_diagnostic_figure_addition.md"),
  any(inventory$path ==
    "artifacts/12_manifests/H11/H11_activity_context_output_hashes.csv"),
  !any(grepl("manuscript/R0_NatMed", inventory$path, fixed = TRUE)),
  !any(grepl("pilot|bootstrap", inventory$path, ignore.case = TRUE) &
    inventory$role == "reader_artifact")
)

invisible(write_csv_artifact(inventory, manifest_path, producer = producer))
message("H11 Stage 3 manifest sealed: ", nrow(inventory), " files")
