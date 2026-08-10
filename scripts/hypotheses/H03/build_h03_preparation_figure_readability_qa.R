#!/usr/bin/env Rscript

# Build REPORT-011 physical-size evidence for the four reader-facing figures
# in the H03 preparation companion. The proof uses only existing raster
# assets; it does not calculate or change a scientific result.

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
    sprintf("H03 requires R 4.6.1; running %s", getRversion()),
    call. = FALSE
  )
}
if (!requireNamespace("png", quietly = TRUE)) {
  stop("The project library does not provide package 'png'", call. = FALSE)
}

producer <- paste0(
  "scripts/hypotheses/H03/",
  "build_h03_preparation_figure_readability_qa.R"
)
output_path <- file.path(
  root,
  paste0(
    "artifacts/12_manifests/H03/",
    "H03_preparation_figure_readability_qa.csv"
  )
)
proof_relative <- paste0(
  "artifacts/12_manifests/H03/",
  "H03_preparation_figure_A4_proofs.pdf"
)
proof_path <- file.path(root, proof_relative)
record_relative <- paste0(
  "audit/hypotheses/H03/",
  "H03_preparation_figure_readability_qa.md"
)
record_path <- file.path(root, record_relative)
asset_root <- paste0(
  "audit/hypotheses/H03/",
  "H03_analysis_preparation_files/figure-html/"
)

qa <- tibble::tribble(
  ~figure_id, ~path, ~base_width_in, ~base_height_in, ~review_note,
  "fig-h03-prep-positive-distribution",
  paste0(asset_root, "fig-h03-prep-positive-distribution-1.png"),
  10, 5.8,
  "Placement order, original-unit lux labels, exact-zero separation, long x-axis title, and histogram marks must remain legible and unclipped.",
  "fig-h03-prep-category-support",
  paste0(asset_root, "fig-h03-prep-category-support-1.png"),
  10, 6.6,
  "Seven category labels, both support measures, placement legend, ticks, and paired bars must remain readable and balanced.",
  "fig-h03-prep-site-category-support",
  paste0(asset_root, "fig-h03-prep-site-category-support-1.png"),
  11, 8.2,
  "Submitted site labels, seven categories, sparse circles, no-observation crosses, and original-count legend must remain distinguishable.",
  "fig-h03-prep-clock-category-support",
  paste0(asset_root, "fig-h03-prep-clock-category-support-1.png"),
  11, 8,
  "Hourly cells, category labels, selected clock ticks, support markers, and original-count legend must remain distinguishable."
)

absolute_paths <- file.path(root, qa$path)
if (any(!file.exists(absolute_paths))) {
  stop(
    paste0(
      "Missing H03 preparation figure asset(s): ",
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
    page = "H03 preparation",
    intended_html_width = "100%",
    intended_html_fraction = 1,
    export_scale_multiplier = 1,
    raster_dpi = 192,
    smallest_essential_nominal_text_pt = 12,
    smallest_central_nominal_text_pt = 14,
    export_width_in = .data$base_width_in,
    export_height_in = .data$base_height_in,
    native_export_width_mm = .data$export_width_in * 25.4,
    native_export_height_mm = .data$export_height_in * 25.4,
    intended_display_width_mm = 170,
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
    a4_side_margin_mm = 20,
    a4_proof_path = proof_relative,
    a4_proof_page = dplyr::row_number(),
    final_asset_canvas = "tightly bounded to figure; A4 page excluded",
    physical_size_evidence = paste0(
      "A4 portrait raster proof at 170.0 mm; native ",
      .data$pixel_width,
      " × ",
      .data$pixel_height,
      " pixels"
    )
  )

expected_pixel_width <- qa$base_width_in * qa$raster_dpi
expected_pixel_height <- qa$base_height_in * qa$raster_dpi
if (
  nrow(qa) != 4L ||
    anyDuplicated(qa$figure_id) ||
    any(abs(qa$pixel_width - expected_pixel_width) > 1L) ||
    any(abs(qa$pixel_height - expected_pixel_height) > 1L) ||
    any(qa$effective_final_essential_text_pt < 5) ||
    any(qa$effective_final_central_text_pt < 7) ||
    any(nchar(qa$sha256) != 64L) ||
    any(qa$a4_side_margin_mm < 20)
) {
  stop("Invalid H03 preparation physical-size evidence", call. = FALSE)
}

# The A4 proof is a QA-only inspection scaffold. Final PNG assets remain
# tightly bounded and never include the A4 page.
dir.create(dirname(proof_path), recursive = TRUE, showWarnings = FALSE)
grDevices::cairo_pdf(
  proof_path,
  width = 210 / 25.4,
  height = 297 / 25.4,
  onefile = TRUE,
  family = "sans"
)
for (index in seq_len(nrow(qa))) {
  raster <- png::readPNG(absolute_paths[[index]])
  grid::grid.newpage()
  grid::grid.text(
    paste0(qa$figure_id[[index]], " — display width 170.0 mm"),
    x = grid::unit(105, "mm"),
    y = grid::unit(286, "mm"),
    gp = grid::gpar(fontsize = 8, col = "grey25")
  )
  grid::grid.raster(
    raster,
    x = grid::unit(105, "mm"),
    y = grid::unit(148.5, "mm"),
    width = grid::unit(170, "mm"),
    height = grid::unit(qa$intended_display_height_mm[[index]], "mm"),
    interpolate = TRUE
  )
  grid::grid.rect(
    x = grid::unit(105, "mm"),
    y = grid::unit(148.5, "mm"),
    width = grid::unit(170, "mm"),
    height = grid::unit(qa$intended_display_height_mm[[index]], "mm"),
    gp = grid::gpar(fill = NA, col = "grey75", lwd = 0.4)
  )
}
grDevices::dev.off()
if (!file.exists(proof_path) || file.info(proof_path)$size <= 0L) {
  stop("H03 preparation A4 figure proof was not created", call. = FALSE)
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
if (!inspection_passed) {
  stop("H03 preparation visual-inspection record is incomplete", call. = FALSE)
}

qa <- qa |>
  mutate(
    inspection_date = as.Date("2026-08-10"),
    inspection_basis = paste(
      "Four-page A4 portrait proof; each final figure placed at 170 mm",
      "and inspected together with the direct Quarto HTML"
    ),
    clipping_or_cropping = "PASS",
    overlaps = "PASS",
    text_shape_and_distortion = "PASS",
    wrapping_and_units = "PASS",
    important_text_readable = "PASS",
    legend_and_data_region_balance = "PASS",
    marks_and_lines_distinguishable = "PASS",
    caption_and_alt_text_present = "PASS",
    typography_status = "PASS_BY_CALCULATION",
    visual_status = "PASS",
    overall_status = "PASS",
    status = "PASS",
    symlog_applicability = if_else(
      .data$figure_id == "fig-h03-prep-positive-distribution",
      paste(
        "NOT_APPLICABLE: exact zeros shown separately; plotted values are",
        "strictly positive and binned on log10 scale"
      ),
      "NOT_APPLICABLE: plotted values are support counts"
    ),
    reporting_rule = "REPORT-011 and REPORT-013",
    qa_record = record_relative,
    producer = producer,
    r_version = as.character(getRversion())
  )

invisible(write_csv_artifact(qa, output_path, producer))
message(
  "H03 preparation figure QA passed for ",
  nrow(qa),
  " figures at 170-mm display width"
)
