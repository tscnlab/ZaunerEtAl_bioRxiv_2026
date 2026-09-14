#!/usr/bin/env Rscript

# Build the REPORT-011 physical-size evidence for every reader-facing H05
# figure in the results report and preparation companion. The proof uses only
# existing raster assets; it does not calculate or change a scientific result.

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
proof_relative <- paste0(
  "artifacts/12_manifests/H05/",
  "H05_figure_A4_proofs.pdf"
)
proof_path <- file.path(root, proof_relative)
record_relative <- paste0(
  "audit/hypotheses/H05/",
  "H05_figure_readability_qa.md"
)
record_path <- file.path(root, record_relative)

# Result figures use the repaired 9-inch design canvases at 300 dpi. The three
# preparation figures retain their accepted knitr canvases and 192-dpi output.
# Intended display widths apply each QMD out-width percentage to the 170-mm
# reference frame, making the check at least as strict as a full-width figure.
qa <- tibble::tribble(
  ~figure_id, ~page, ~path, ~intended_html_width, ~intended_html_fraction, ~base_width_in, ~base_height_in, ~export_scale_multiplier, ~raster_dpi, ~smallest_essential_nominal_text_pt, ~smallest_central_nominal_text_pt, ~symlog_applicability, ~review_note,
  "fig-h05-near-effects", "H05 results", "artifacts/10_figures/H05/H05_reader_near_eye_effects.png", "96%", 0.96, 9, 9, 1, 300, 8.8, 9.96, "NOT_APPLICABLE", "All 17 metric labels, four factor labels, practical-scale cell values, colour legend, and grey unfit cells must remain readable and unclipped.",
  "fig-h05-near-adequacy", "H05 results", "artifacts/10_figures/H05/H05_reader_near_eye_adequacy.png", "94%", 0.94, 9, 8.5, 1, 300, 8.8, NA_real_, "NOT_APPLICABLE", "Metric and factor labels, three adequacy classes, cell marks, and legend must remain readable and distinguishable without overlap.",
  "fig-h05-near-residual-fitted", "H05 results", "artifacts/10_figures/H05/H05_reader_near_eye_residual_fitted.png", "88%", 0.88, 9, 9, 1, 300, 8.8, NA_real_, "NOT_APPLICABLE", "Four facet titles, axes, points, smooths, and the diagnostic subtitle must remain readable, proportionate, and unclipped.",
  "fig-h05-near-residual-qq", "H05 results", "artifacts/10_figures/H05/H05_reader_near_eye_residual_qq.png", "88%", 0.88, 9, 9, 1, 300, 8.8, NA_real_, "NOT_APPLICABLE", "Four facet titles, axes, points, reference lines, and the two-line unfit-for-inference subtitle must remain readable and fully visible.",
  "fig-h05-chest-effects", "H05 results", "artifacts/10_figures/H05/H05_reader_chest_effects.png", "96%", 0.96, 9, 9, 1, 300, 8.8, 9.96, "NOT_APPLICABLE", "All 17 metric labels, four factor labels, practical-scale cell values, colour legend, and grey unfit cells must remain readable and unclipped.",
  "fig-h05-chest-adequacy", "H05 results", "artifacts/10_figures/H05/H05_reader_chest_adequacy.png", "94%", 0.94, 9, 8.5, 1, 300, 8.8, NA_real_, "NOT_APPLICABLE", "Metric and factor labels, three adequacy classes, cell marks, and legend must remain readable and distinguishable without overlap.",
  "fig-h05-paired-placement", "H05 results", "artifacts/10_figures/H05/H05_reader_paired_placement_effects.png", "90%", 0.90, 9, 8, 1, 300, 8.8, NA_real_, "NOT_APPLICABLE", "Four factor panels, equal-axis geometry, identity and null lines, and annotations must remain readable; the display must not imply equivalence.",
  "fig-h05-prep-leba-distribution", "H05 preparation", "_build/nathealth/audit/hypotheses/H05/H05_analysis_preparation_files/figure-html/fig-h05-prep-leba-distribution-1.png", "100%", 1, 10, 6.8, 1, 192, 9.6, NA_real_, "NOT_APPLICABLE", "F2-F5 facet titles, axes, ticks, bars, and participant labels must remain readable; the four-panel canvas must remain balanced and unclipped.",
  "fig-h05-prep-sample-support", "H05 preparation", "_build/nathealth/audit/hypotheses/H05/H05_analysis_preparation_files/figure-html/fig-h05-prep-sample-support-1.png", "100%", 1, 11, 6.5, 1, 192, 9.6, NA_real_, "NOT_APPLICABLE", "Both sample-support panels, metric-order ticks, placement legend, lines, and points must remain readable and distinguishable without overlap.",
  "fig-h05-prep-site-range", "H05 preparation", "_build/nathealth/audit/hypotheses/H05/H05_analysis_preparation_files/figure-html/fig-h05-prep-site-range-1.png", "100%", 1, 11, 7, 1, 192, 9.6, NA_real_, "NOT_APPLICABLE", "Submitted-manuscript site names, both placement panels, axes, ticks, coloured ranges, and points must remain readable and unclipped."
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
    export_width_in = .data$base_width_in * .data$export_scale_multiplier,
    export_height_in = .data$base_height_in * .data$export_scale_multiplier,
    native_export_width_mm = .data$export_width_in * 25.4,
    native_export_height_mm = .data$export_height_in * 25.4,
    intended_display_width_mm = 170 * .data$intended_html_fraction,
    intended_display_height_mm =
      .data$intended_display_width_mm *
      .data$base_height_in / .data$base_width_in,
    display_reduction_factor =
      .data$intended_display_width_mm / .data$native_export_width_mm,
    effective_final_essential_text_pt =
      .data$smallest_essential_nominal_text_pt *
      .data$display_reduction_factor,
    effective_final_central_text_pt =
      .data$smallest_central_nominal_text_pt *
      .data$display_reduction_factor,
    pixel_width = vapply(dimensions, `[[`, integer(1), 2L),
    pixel_height = vapply(dimensions, `[[`, integer(1), 1L),
    sha256 = vapply(absolute_paths, artifact_sha256, character(1)),
    bytes = unname(file.info(absolute_paths)$size),
    a4_page_width_mm = 210,
    a4_page_height_mm = 297,
    a4_side_margin_mm =
      (.data$a4_page_width_mm - .data$intended_display_width_mm) / 2,
    a4_proof_path = proof_relative,
    a4_proof_page = dplyr::row_number(),
    final_asset_canvas = "tightly bounded to figure; A4 page excluded",
    physical_size_evidence = paste0(
      "A4 portrait raster proof at ",
      format(round(.data$intended_display_width_mm, 1), nsmall = 1),
      " mm; 170-mm reference frame with QMD out-width applied"
    )
  )

expected_pixel_width <- qa$export_width_in * qa$raster_dpi
expected_pixel_height <- qa$export_height_in * qa$raster_dpi
if (
  nrow(qa) != 10L ||
    anyDuplicated(qa$figure_id) ||
    any(abs(qa$pixel_width - expected_pixel_width) > 1L) ||
    any(abs(qa$pixel_height - expected_pixel_height) > 1L) ||
    any(qa$effective_final_essential_text_pt < 5) ||
    any(
      !is.na(qa$effective_final_central_text_pt) &
        qa$effective_final_central_text_pt < 7
    ) ||
    any(nchar(qa$sha256) != 64L) ||
    any(qa$a4_side_margin_mm < 20) ||
    any(qa$symlog_applicability != "NOT_APPLICABLE")
) {
  stop("Invalid H05 physical-size figure evidence", call. = FALSE)
}

# The A4 proof is a QA-only inspection scaffold. Final PNG/PDF assets remain
# tightly cropped and never include the A4 page.
dir.create(dirname(proof_path), recursive = TRUE, showWarnings = FALSE)
grDevices::cairo_pdf(
  proof_path,
  width = 210 / 25.4,
  height = 297 / 25.4,
  onefile = TRUE,
  family = "sans"
)
for (i in seq_len(nrow(qa))) {
  raster <- png::readPNG(absolute_paths[[i]])
  grid::grid.newpage()
  grid::grid.text(
    paste0(
      qa$figure_id[[i]],
      " — display width ",
      format(round(qa$intended_display_width_mm[[i]], 1), nsmall = 1),
      " mm"
    ),
    x = grid::unit(105, "mm"),
    y = grid::unit(286, "mm"),
    gp = grid::gpar(fontsize = 8, col = "grey25")
  )
  grid::grid.raster(
    raster,
    x = grid::unit(105, "mm"),
    y = grid::unit(148.5, "mm"),
    width = grid::unit(qa$intended_display_width_mm[[i]], "mm"),
    height = grid::unit(qa$intended_display_height_mm[[i]], "mm"),
    interpolate = TRUE
  )
  grid::grid.rect(
    x = grid::unit(105, "mm"),
    y = grid::unit(148.5, "mm"),
    width = grid::unit(qa$intended_display_width_mm[[i]], "mm"),
    height = grid::unit(qa$intended_display_height_mm[[i]], "mm"),
    gp = grid::gpar(fill = NA, col = "grey75", lwd = 0.4)
  )
}
grDevices::dev.off()
if (!file.exists(proof_path) || file.info(proof_path)$size <= 0) {
  stop("H05 A4 figure proof was not created", call. = FALSE)
}

record <- if (file.exists(record_path)) {
  paste(readLines(record_path, warn = FALSE), collapse = "\n")
} else {
  ""
}
inspection_passed <-
  grepl("Overall outcome: PASS", record, fixed = TRUE) &&
  all(vapply(
    qa$figure_id,
    function(figure_id) grepl(figure_id, record, fixed = TRUE),
    logical(1)
  ))
check_value <- if (inspection_passed) "PASS" else "NOT TESTED"
overall_value <- if (inspection_passed) {
  "PASS"
} else {
  "NOT_TESTED_PENDING_PHYSICAL_SIZE_INSPECTION"
}

qa <- qa |>
  mutate(
    inspection_date = if (inspection_passed) as.Date("2026-08-11") else as.Date(NA),
    inspection_basis = paste(
      "Ten-page A4 portrait proof; each final figure placed at its",
      "QMD width within a 170-mm reference frame and inspected together",
      "with the actual Quarto HTML"
    ),
    clipping_or_cropping = check_value,
    overlaps = check_value,
    text_shape_and_distortion = check_value,
    wrapping_and_units = check_value,
    important_text_readable = check_value,
    legend_and_data_region_balance = check_value,
    marks_and_lines_distinguishable = check_value,
    caption_and_alt_text_present = check_value,
    typography_status = if_else(
      .data$effective_final_essential_text_pt >= 5,
      "PASS_BY_CALCULATION",
      "FAIL"
    ),
    visual_status = check_value,
    overall_status = overall_value,
    status = overall_value,
    reporting_rule = "REPORT-011; REPORT-013 assessed not applicable",
    qa_record = record_relative,
    producer = producer,
    r_version = as.character(getRversion())
  )

invisible(write_csv_artifact(qa, output_path, producer))
message(
  "Recorded physical-size evidence for ",
  nrow(qa),
  " H05 figures; status ",
  unique(qa$overall_status)
)
