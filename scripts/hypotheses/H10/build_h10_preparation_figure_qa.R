#!/usr/bin/env Rscript

# Build physical-size evidence for the two descriptive H10 preparation
# figures. Existing rasters are placed on an A4 inspection scaffold only;
# no scientific result is calculated or altered.

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
    sprintf(
      "H10 preparation-figure QA requires R 4.6.1; running %s",
      getRversion()
    ),
    call. = FALSE
  )
}
if (!requireNamespace("png", quietly = TRUE)) {
  stop("The project library does not provide package 'png'", call. = FALSE)
}

producer <- paste0(
  "scripts/hypotheses/H10/",
  "build_h10_preparation_figure_qa.R"
)
output_relative <- paste0(
  "artifacts/12_manifests/H10/",
  "H10_preparation_figure_readability_qa.csv"
)
proof_relative <- paste0(
  "artifacts/12_manifests/H10/",
  "H10_preparation_figure_A4_proofs.pdf"
)
record_relative <- "audit/hypotheses/H10/04_stage4_figure_qa.md"
output_path <- file.path(root, output_relative)
proof_path <- file.path(root, proof_relative)
record_path <- file.path(root, record_relative)

qa <- tibble::tribble(
  ~figure_id,
  ~path,
  ~source_data_path,
  ~base_width_in,
  ~base_height_in,
  ~smallest_essential_nominal_text_pt,
  ~smallest_central_nominal_text_pt,
  ~review_note,
  "fig-h10-prep-age-distribution",
  "artifacts/10_figures/H10/H10_preparation_age_distribution.png",
  "artifacts/11_source_data/H10/H10_preparation_age_distribution_data.csv",
  9.4,
  5.2,
  9,
  10,
  "Both placement panels, submitted site order and colours, participant marks, biological-sex shapes, age axis, and legend must be readable and unclipped.",
  "fig-h10-prep-sample-support",
  "artifacts/10_figures/H10/H10_preparation_sample_support.png",
  "artifacts/11_source_data/H10/H10_preparation_sample_support_data.csv",
  9.4,
  8.2,
  8.5,
  10,
  "All 17 metric labels, both analysis-unit facets, placement marks, percentage axis, and legend must be readable without compressing the data region."
)

absolute_paths <- file.path(root, qa$path)
absolute_source_paths <- file.path(root, qa$source_data_path)
if (any(!file.exists(c(absolute_paths, absolute_source_paths)))) {
  stop(
    "An H10 preparation figure or paired source CSV is missing",
    call. = FALSE
  )
}

dimensions <- lapply(
  absolute_paths,
  function(path) dim(png::readPNG(path, native = TRUE))
)

qa <- qa |>
  mutate(
    page = "H10 analysis preparation and provenance",
    intended_html_width = "100%",
    intended_html_fraction = 1,
    export_scale_multiplier = 1,
    raster_dpi = 300,
    export_width_in = .data$base_width_in,
    export_height_in = .data$base_height_in,
    native_export_width_mm = .data$export_width_in * 25.4,
    native_export_height_mm = .data$export_height_in * 25.4,
    intended_display_width_mm = 170,
    intended_display_height_mm = .data$intended_display_width_mm *
      .data$base_height_in /
      .data$base_width_in,
    display_reduction_factor = .data$intended_display_width_mm /
      .data$native_export_width_mm,
    effective_final_essential_text_pt = .data$smallest_essential_nominal_text_pt *
      .data$display_reduction_factor,
    effective_final_central_text_pt = .data$smallest_central_nominal_text_pt *
      .data$display_reduction_factor,
    pixel_width = vapply(dimensions, `[[`, integer(1), 2L),
    pixel_height = vapply(dimensions, `[[`, integer(1), 1L),
    sha256 = vapply(absolute_paths, artifact_sha256, character(1)),
    source_data_sha256 = vapply(
      absolute_source_paths,
      artifact_sha256,
      character(1)
    ),
    bytes = unname(file.info(absolute_paths)$size),
    source_data_bytes = unname(file.info(absolute_source_paths)$size),
    a4_page_width_mm = 210,
    a4_page_height_mm = 297,
    a4_side_margin_mm = 20,
    a4_proof_path = proof_relative,
    a4_proof_page = dplyr::row_number(),
    final_asset_canvas = "tightly bounded to figure; A4 page excluded",
    symlog_applicability = paste0(
      "NOT_APPLICABLE: age and fitted-row proportions are displayed; ",
      "no nonnegative right-skewed melEDI-like response is plotted"
    )
  )

expected_pixel_width <- qa$export_width_in * qa$raster_dpi
expected_pixel_height <- qa$export_height_in * qa$raster_dpi
if (
  nrow(qa) != 2L ||
    anyDuplicated(qa$figure_id) ||
    any(abs(qa$pixel_width - expected_pixel_width) > 1L) ||
    any(abs(qa$pixel_height - expected_pixel_height) > 1L) ||
    any(qa$effective_final_essential_text_pt < 5) ||
    any(qa$effective_final_central_text_pt < 7) ||
    any(nchar(qa$sha256) != 64L) ||
    any(nchar(qa$source_data_sha256) != 64L) ||
    any(qa$intended_display_height_mm > 257)
) {
  stop("Invalid H10 preparation physical-size evidence", call. = FALSE)
}

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
inspection_value <- if (inspection_passed) "PASS" else "NOT TESTED"
overall_value <- if (inspection_passed) {
  "PASS"
} else {
  "NOT_TESTED_PENDING_PHYSICAL_SIZE_INSPECTION"
}

qa <- qa |>
  mutate(
    no_clipping_or_cropping = inspection_value,
    no_overlap = inspection_value,
    no_text_distortion = inspection_value,
    no_bad_wrapping = inspection_value,
    important_text_readable = inspection_value,
    data_region_proportionate = inspection_value,
    marks_distinguishable = inspection_value,
    caption_and_alt_text_present = inspection_value,
    overall_status = overall_value,
    producer = producer,
    r_version = as.character(getRversion())
  )

dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
invisible(write_csv_artifact(qa, output_path, producer))
message(
  "Recorded physical-size evidence for ",
  nrow(qa),
  " H10 preparation figures; status ",
  unique(qa$overall_status)
)
