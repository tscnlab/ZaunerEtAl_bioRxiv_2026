#!/usr/bin/env Rscript

# Record final-size visual QA for every reader-facing H05 figure in the
# results report and preparation companion. This hashes existing raster
# outputs and records a completed display review; it does not calculate or
# change a scientific result.

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
if (!requireNamespace("png", quietly = TRUE)) {
  stop(
    "The synchronized project library does not provide package 'png'",
    call. = FALSE
  )
}

producer <- paste0(
  "scripts/hypotheses/H05/",
  "build_h05_figure_readability_qa.R"
)
output_path <- file.path(
  root,
  "artifacts/12_manifests/H05/H05_figure_readability_qa.csv"
)

qa <- tibble::tribble(
  ~figure_id, ~page, ~path, ~intended_html_width, ~review_note,
  "fig-h05-near-effects", "H05 results", "artifacts/10_figures/H05/H05_reader_near_eye_effects.png", "96%", "All 17 metric labels, four factor labels, practical-scale cell values, colour legend, and grey unfit cells remain readable and unclipped.",
  "fig-h05-near-adequacy", "H05 results", "artifacts/10_figures/H05/H05_reader_near_eye_adequacy.png", "94%", "Metric and factor labels, three adequacy classes, cell marks, and legend remain readable and distinguishable without overlap.",
  "fig-h05-near-residual-fitted", "H05 results", "artifacts/10_figures/H05/H05_reader_near_eye_residual_fitted.png", "88%", "Three facet titles, axes, points, smooths, and the diagnostic subtitle remain readable, proportionate, and unclipped.",
  "fig-h05-near-residual-qq", "H05 results", "artifacts/10_figures/H05/H05_reader_near_eye_residual_qq.png", "88%", "Three facet titles, axes, points, reference lines, and the two-line unfit-for-inference subtitle remain readable and fully visible after the display-only repair.",
  "fig-h05-chest-effects", "H05 results", "artifacts/10_figures/H05/H05_reader_chest_effects.png", "96%", "All 17 metric labels, four factor labels, practical-scale cell values, colour legend, and grey unfit cells remain readable and unclipped.",
  "fig-h05-chest-adequacy", "H05 results", "artifacts/10_figures/H05/H05_reader_chest_adequacy.png", "94%", "Metric and factor labels, three adequacy classes, cell marks, and legend remain readable and distinguishable without overlap.",
  "fig-h05-paired-placement", "H05 results", "artifacts/10_figures/H05/H05_paired_placement_effects.png", "90%", "Four factor panels, matched-estimand labels, equal-axis geometry, identity and null lines, and annotations remain readable; the display does not imply equivalence.",
  "fig-h05-prep-leba-distribution", "H05 preparation", "_build/nathealth/audit/hypotheses/H05/H05_analysis_preparation_files/figure-html/fig-h05-prep-leba-distribution-1.png", "100%", "F2-F5 facet titles, axes, ticks, bars, and participant labels remain readable; the four-panel canvas is balanced and unclipped.",
  "fig-h05-prep-sample-support", "H05 preparation", "_build/nathealth/audit/hypotheses/H05/H05_analysis_preparation_files/figure-html/fig-h05-prep-sample-support-1.png", "100%", "Both sample-support panels, metric-order ticks, placement legend, lines, and points remain readable and distinguishable without overlap.",
  "fig-h05-prep-site-range", "H05 preparation", "_build/nathealth/audit/hypotheses/H05/H05_analysis_preparation_files/figure-html/fig-h05-prep-site-range-1.png", "100%", "Submitted-manuscript site names, both placement panels, axes, ticks, coloured ranges, and points remain readable and unclipped."
)

absolute_paths <- file.path(root, qa$path)
if (any(!file.exists(absolute_paths))) {
  stop(
    paste0(
      "Missing H05 reader-figure asset(s): ",
      paste(qa$path[!file.exists(absolute_paths)], collapse = ", ")
    ),
    call. = FALSE
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
      "Visual inspection at the rendered page width and a",
      "1024-pixel-wide final-scale preview, cross-checked against",
      "the intrinsic raster dimensions and HTML display percentage"
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
  nrow(qa) != 10L ||
    anyDuplicated(qa$figure_id) ||
    any(qa$pixel_width < 1900L) ||
    any(qa$pixel_height < 1200L) ||
    any(nchar(qa$sha256) != 64L) ||
    any(qa$status != "PASS")
) {
  stop("Invalid H05 figure-readability QA record", call. = FALSE)
}

dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
invisible(write_csv_artifact(qa, output_path, producer))
message("Recorded final-size visual QA for ", nrow(qa), " H05 figures")
