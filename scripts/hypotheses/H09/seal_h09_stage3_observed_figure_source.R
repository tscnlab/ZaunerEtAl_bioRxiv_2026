#!/usr/bin/env Rscript

# Create a deterministic, non-circular source-only seal for the additive H09
# Stage 3 composite. The seal inventories files and does not execute science.

startup_root <- Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd())
startup_library <- file.path(
  startup_root,
  "renv/library/macos/R-4.6/aarch64-apple-darwin23"
)
if (dir.exists(startup_library)) {
  .libPaths(c(startup_library, .libPaths()))
}

suppressPackageStartupMessages({
  library(digest)
  library(readr)
  library(tibble)
})

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("The H09 source seal requires R 4.6.1", call. = FALSE)
}

output_relative <- paste0(
  "artifacts/12_manifests/H09/",
  "H09_stage3_observed_figure_source_seal.csv"
)
sealed <- tibble::tribble(
  ~path, ~role,
  "notebooks/hypotheses/H09.qmd", "reader_report_source",
  "scripts/hypotheses/H09/build_h09_stage3_observed_figure.R", "display_builder",
  "scripts/hypotheses/H09/seal_h09_stage3_observed_figure_source.R", "source_sealer",
  "tests/hypotheses/H09/test_h09_stage3_observed_figure.R", "focused_test",
  "artifacts/10_figures/H09/H09_observed_timing_patterns.png", "reader_figure_png",
  "artifacts/10_figures/H09/H09_observed_timing_patterns.pdf", "reader_figure_pdf",
  "artifacts/11_source_data/H09/H09_observed_timing_patterns_data.csv", "paired_figure_source",
  "artifacts/12_manifests/H09/H09_figure_manifest.csv", "figure_manifest",
  "artifacts/06_model_data/H09/H09_model_frames.rds", "frozen_model_frames",
  "artifacts/06_model_data/H09/H09_model_frame_index.csv", "frozen_frame_index",
  "artifacts/06_model_data/H09/H09_metric_registry.csv", "frozen_metric_registry",
  "artifacts/06_model_data/H09/H09_predictor_registry.csv", "frozen_predictor_registry",
  "artifacts/06_model_data/H09/H09_input_audit.csv", "frozen_input_audit",
  "artifacts/06_model_data/normalized_inputs/chronotype.rds", "pinned_chronotype_input",
  "artifacts/07_models/H09/H09_model_bundles.rds", "frozen_model_bundles",
  "artifacts/09_tables/H09/H09_model_results_master.csv", "accepted_results",
  "artifacts/10_figures/H09/H09_primary_effects.png", "accepted_complete_forest_png",
  "artifacts/11_source_data/H09/H09_primary_effects_data.csv", "accepted_complete_forest_source",
  "config/site_display_registry.csv", "shared_site_display_registry",
  "audit/decisions/site_display_conventions.md", "shared_site_display_decision",
  "audit/decisions/p_value_display_conventions.md", "shared_p_value_decision",
  "audit/decisions/figure_readability_and_layout.md", "shared_figure_decision",
  "_build/nathealth/notebooks/hypotheses/H09.html", "protected_accepted_result_html",
  "_build/nathealth/audit/hypotheses/H09/H09_analysis_preparation.html", "protected_accepted_companion_html"
)
if (output_relative %in% sealed$path || anyDuplicated(sealed$path)) {
  stop("The H09 source seal is circular or duplicated", call. = FALSE)
}
absolute <- file.path(root, sealed$path)
if (any(!file.exists(absolute)) || any(dir.exists(absolute))) {
  stop("A source-seal member is missing or not a file", call. = FALSE)
}

seal <- sealed
seal$sha256 <- unname(vapply(
  absolute,
  digest::digest,
  character(1),
  algo = "sha256",
  file = TRUE,
  serialize = FALSE
))
seal$bytes <- as.numeric(file.info(absolute)$size)
seal$r_version <- as.character(getRversion())

result_row <- seal[seal$path ==
  "_build/nathealth/notebooks/hypotheses/H09.html", , drop = FALSE]
if (
  nrow(result_row) != 1L ||
    result_row$sha256 !=
      "901fd63b45182be70ef77166c418633220a7226d86f52e14d1c79afbfc7cdd16"
) {
  stop("The accepted H09 result HTML was not preserved", call. = FALSE)
}

output <- file.path(root, output_relative)
dir.create(dirname(output), recursive = TRUE, showWarnings = FALSE)
candidate <- tempfile(
  pattern = "H09_stage3_observed_figure_source_seal.",
  tmpdir = dirname(output),
  fileext = ".csv"
)
on.exit(unlink(candidate), add = TRUE)
readr::write_csv(seal, candidate, na = "")
if (!file.rename(candidate, output)) {
  stop("Could not promote the H09 source seal", call. = FALSE)
}
message(
  "H09 Stage 3 observed-figure source seal completed: ",
  nrow(seal),
  " non-circular members"
)
