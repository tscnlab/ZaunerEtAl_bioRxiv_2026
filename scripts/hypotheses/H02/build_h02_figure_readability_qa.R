#!/usr/bin/env Rscript

# Record the final-size visual QA for every reader-facing H02 figure.
# This script hashes existing raster outputs and records a completed visual
# review. It does not calculate or change a scientific result.

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
source(file.path(root, "scripts/hypotheses/H02/h02_contract.R"))

if (getRversion() != "4.6.1") {
  h02_abort("H02 requires R 4.6.1; running %s", getRversion())
}
if (!requireNamespace("png", quietly = TRUE)) {
  h02_abort("The synchronized project library does not provide package 'png'")
}

invisible(h02_validate_inputs(root))

producer <- paste0(
  "scripts/hypotheses/H02/",
  "build_h02_figure_readability_qa.R"
)
output_path <- file.path(
  root,
  "artifacts/12_manifests/H02/H02_figure_readability_qa.csv"
)

qa <- tibble::tribble(
  ~figure_id, ~page, ~path, ~intended_html_width, ~review_note,
  "fig-h02-near-patterns", "H02 results", "artifacts/10_figures/H02/figure4_exact_layout_replication.png", "88%", "Panel letters, axes, site and participant-day labels, curves, ribbons, and red pointwise segments remain legible and unclipped.",
  "fig-h02-near-diagnostics", "H02 results", "artifacts/10_figures/H02/model_diagnostics_near_eye.png", "88%", "All five panel letters, diagnostic titles, axes, points, lines, and the two-entry legend remain legible and unclipped.",
  "fig-h02-chest-patterns", "H02 results", "artifacts/10_figures/H02/figure4_exact_layout_replication_chest.png", "88%", "Panel letters, axes, site and participant-day labels, curves, ribbons, and red pointwise segments remain legible and unclipped.",
  "fig-h02-chest-diagnostics", "H02 results", "artifacts/10_figures/H02/model_diagnostics_chest.png", "88%", "All five panel letters, diagnostic titles, axes, points, lines, and the two-entry legend remain legible and unclipped.",
  "fig-h02-paired-placement-curves", "H02 results", "_build/nathealth/notebooks/hypotheses/H02_files/figure-html/fig-h02-paired-placement-curves-1.png", "100%", "Eight facet titles, transformed-scale labels, solid and dashed curves, ribbons, and the placement legend remain distinguishable without overlap.",
  "fig-h02-prep-response-distribution", "H02 preparation", "_build/nathealth/audit/hypotheses/H02/H02_analysis_preparation_files/figure-html/fig-h02-prep-response-distribution-1.png", "100%", "Facet, axis, tick, and exact-zero annotation text remains legible; the positive-response data region is proportionate and unclipped.",
  "fig-h02-prep-clock-support", "H02 preparation", "_build/nathealth/audit/hypotheses/H02/H02_analysis_preparation_files/figure-html/fig-h02-prep-clock-support-1.png", "100%", "Site and placement labels are legible; the widened bottom colour bar separates all percentage labels without overlap.",
  "fig-h02-prep-day-support", "H02 preparation", "_build/nathealth/audit/hypotheses/H02/H02_analysis_preparation_files/figure-html/fig-h02-prep-day-support-1.png", "100%", "Facet, axis, and tick text remains legible; bars and the data region are proportionate and unclipped.",
  "fig-h02-prep-ar-change", "H02 preparation", "_build/nathealth/audit/hypotheses/H02/H02_analysis_preparation_files/figure-html/fig-h02-prep-ar-change-1.png", "100%", "Facet, axis, tick, and legend text remains legible; coloured and line-type encoded series remain distinguishable."
)

absolute_paths <- file.path(root, qa$path)
if (any(!file.exists(absolute_paths))) {
  h02_abort(
    "Missing H02 reader-figure asset(s): %s",
    paste(qa$path[!file.exists(absolute_paths)], collapse = ", ")
  )
}

dimensions <- lapply(
  absolute_paths,
  function(path) dim(png::readPNG(path, native = TRUE))
)
qa <- qa |>
  mutate(
    pixel_width = vapply(dimensions, `[[`, integer(1), 2L),
    pixel_height = vapply(dimensions, `[[`, integer(1), 1L),
    sha256 = vapply(absolute_paths, artifact_sha256, character(1)),
    bytes = unname(file.info(absolute_paths)$size),
    final_size_review = paste(
      "Visual inspection at a 1024-pixel-wide final-scale preview,",
      "cross-checked against the rendered HTML width and intrinsic raster size"
    ),
    no_clipping_or_cropping = TRUE,
    no_overlap = TRUE,
    no_text_distortion = TRUE,
    no_bad_wrapping = TRUE,
    important_text_readable = TRUE,
    data_region_proportionate = TRUE,
    marks_distinguishable = TRUE,
    caption_and_alt_text_present = TRUE,
    status = "PASS",
    reporting_rule = "REPORT-011",
    producer = producer,
    r_version = as.character(getRversion())
  )

if (
  nrow(qa) != 9L ||
    anyDuplicated(qa$figure_id) ||
    any(qa$pixel_width < 1500L) ||
    any(qa$pixel_height < 1000L) ||
    any(nchar(qa$sha256) != 64L) ||
    any(qa$status != "PASS")
) {
  h02_abort("Invalid H02 figure-readability QA record")
}

dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
invisible(write_csv_artifact(qa, output_path, producer))
message("Recorded final-size visual QA for ", nrow(qa), " H02 figures")
