#!/usr/bin/env Rscript

# Build REPORT-011 physical-size evidence for the two H07 results figures and
# the two analysis-preparation figures. Existing raster assets are inspected;
# no scientific result is calculated or changed.

suppressPackageStartupMessages({
  library(dplyr)
  library(png)
  library(tibble)
})

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
source(file.path(root, "scripts/pipeline/paths_io.R"))

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("H07 figure readability QA requires R 4.6.1", call. = FALSE)
}

producer <- paste0(
  "scripts/hypotheses/H07/",
  "build_h07_figure_readability_qa.R"
)
manifest_dir <- file.path(root, "artifacts/12_manifests/H07")
proof_dir <- file.path(manifest_dir, "figure_proofs")
qa_path <- file.path(manifest_dir, "H07_figure_readability_qa.csv")
record_relative <- "audit/hypotheses/H07/H07_figure_readability_qa.md"
record_path <- file.path(root, record_relative)
dir.create(proof_dir, recursive = TRUE, showWarnings = FALSE)

qa <- tibble::tribble(
  ~figure_id, ~page, ~path, ~base_width_in, ~base_height_in,
  ~export_scale_multiplier, ~raster_dpi,
  ~smallest_essential_nominal_text_pt,
  ~smallest_central_nominal_text_pt, ~proof_segments, ~review_note,
  "fig-h07-near-smooth-derivative-pairs", "H07 results",
  "artifacts/08_figures/H07/H07_revised_smooth_derivative_pairs_near_eye.png",
  9, 18, 1, 270, 10.5, 12, 2L,
  "Title, four-line subtitle, 18 facet strips, axes, ticks, ribbons, rugs, smooths, derivative zero lines, transition lines, and blue tails must remain readable, balanced, and unclipped.",
  "fig-h07-chest-smooth-derivative-pairs", "H07 results",
  "artifacts/08_figures/H07/H07_revised_smooth_derivative_pairs_chest.png",
  9, 18, 1, 270, 10.5, 12, 2L,
  "Title, four-line subtitle, 18 facet strips, axes, ticks, ribbons, rugs, smooths, derivative zero lines, transition lines, and blue tails must remain readable, balanced, and unclipped.",
  "fig-h07-prep-metric-sample-support", "H07 preparation",
  "artifacts/10_figures/H07/preparation/H07_preparation_metric_sample_support.png",
  8.5, 6.8, 1, 300, 10, 11, 1L,
  "Nine metric labels, both placement symbols and colours, participant-day axis, subtitle, and legend must remain readable and unclipped without implying a paired effect.",
  "fig-h07-prep-site-photoperiod-ranges", "H07 preparation",
  "artifacts/10_figures/H07/preparation/H07_preparation_site_photoperiod_ranges.png",
  8.5, 5.8, 1, 300, 10, 11, 1L,
  "Submitted-manuscript site names, both placement panels, endpoint marks, site colours, title, subtitle, axes, and ranges must remain readable and unclipped."
)

absolute_paths <- file.path(root, qa$path)
if (any(!file.exists(absolute_paths))) {
  stop(
    "Missing H07 figure asset(s): ",
    paste(qa$path[!file.exists(absolute_paths)], collapse = ", "),
    call. = FALSE
  )
}

rasters <- lapply(absolute_paths, png::readPNG)
dimensions <- lapply(rasters, dim)
qa <- qa |>
  mutate(
    export_width_in = .data$base_width_in * .data$export_scale_multiplier,
    export_height_in = .data$base_height_in * .data$export_scale_multiplier,
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
    proof_strategy = if_else(
      .data$proof_segments == 2L,
      paste(
        "Two contiguous page crops at exact 170-mm display width;",
        "together they cover the full tall web figure without downscaling"
      ),
      "Whole figure at exact 170-mm display width"
    ),
    final_asset_canvas = "Tightly bounded raster; A4 proof page excluded"
  )

expected_pixel_width <- qa$export_width_in * qa$raster_dpi
expected_pixel_height <- qa$export_height_in * qa$raster_dpi
if (
  nrow(qa) != 4L ||
    anyDuplicated(qa$figure_id) ||
    any(abs(qa$pixel_width - expected_pixel_width) > 1L) ||
    any(abs(qa$pixel_height - expected_pixel_height) > 1L) ||
    any(qa$effective_final_essential_text_pt < 7) ||
    any(qa$effective_final_central_text_pt < 7) ||
    any(nchar(qa$sha256) != 64L)
) {
  stop("Invalid H07 physical-size figure evidence", call. = FALSE)
}

proof_rows <- tibble::tibble()
page_number <- 0L
for (index in seq_len(nrow(qa))) {
  raster <- rasters[[index]]
  segments <- qa$proof_segments[[index]]
  row_ranges <- if (segments == 1L) {
    list(seq_len(dim(raster)[1L]))
  } else {
    midpoint <- floor(dim(raster)[1L] * 0.56)
    list(
      seq_len(midpoint),
      seq.int(midpoint + 1L, dim(raster)[1L])
    )
  }
  for (segment in seq_along(row_ranges)) {
    page_number <- page_number + 1L
    segment_raster <- raster[row_ranges[[segment]], , , drop = FALSE]
    segment_height_mm <-
      qa$intended_display_width_mm[[index]] *
      dim(segment_raster)[1L] / dim(segment_raster)[2L]
    proof_relative <- file.path(
      "artifacts/12_manifests/H07/figure_proofs",
      sprintf("H07_figure_A4_proof_%02d.png", page_number)
    )
    proof_path <- file.path(root, proof_relative)
    grDevices::png(
      proof_path,
      width = 210 / 25.4,
      height = 297 / 25.4,
      units = "in",
      res = 150,
      bg = "white"
    )
    grid::grid.newpage()
    grid::grid.text(
      paste0(
        qa$figure_id[[index]],
        if (segments == 2L) paste0(" — segment ", segment, "/2") else "",
        " — 170-mm display width"
      ),
      x = grid::unit(105, "mm"),
      y = grid::unit(286, "mm"),
      gp = grid::gpar(fontsize = 8, col = "grey25")
    )
    grid::grid.raster(
      segment_raster,
      x = grid::unit(105, "mm"),
      y = grid::unit(145, "mm"),
      width = grid::unit(170, "mm"),
      height = grid::unit(segment_height_mm, "mm"),
      interpolate = TRUE
    )
    grid::grid.rect(
      x = grid::unit(105, "mm"),
      y = grid::unit(145, "mm"),
      width = grid::unit(170, "mm"),
      height = grid::unit(segment_height_mm, "mm"),
      gp = grid::gpar(fill = NA, col = "grey75", lwd = 0.4)
    )
    grDevices::dev.off()
    proof_rows <- bind_rows(
      proof_rows,
      tibble::tibble(
        figure_id = qa$figure_id[[index]],
        proof_segment = segment,
        proof_segments = segments,
        proof_page = page_number,
        proof_path = proof_relative,
        proof_segment_height_mm = segment_height_mm
      )
    )
  }
}

if (
  nrow(proof_rows) != 6L ||
    any(!file.exists(file.path(root, proof_rows$proof_path)))
) {
  stop("H07 A4 raster proofs were not created", call. = FALSE)
}

proof_summary <- proof_rows |>
  group_by(.data$figure_id) |>
  summarise(
    a4_proof_pages = paste(.data$proof_page, collapse = ","),
    a4_proof_paths = paste(.data$proof_path, collapse = " | "),
    .groups = "drop"
  )
qa <- qa |>
  left_join(proof_summary, by = "figure_id", relationship = "one-to-one")

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
    inspection_date = if (inspection_passed) as.Date("2026-08-07") else as.Date(NA),
    inspection_basis = paste(
      "Six A4 portrait raster proofs at exact 170-mm display width;",
      "each tall results figure split into two contiguous",
      "segments without additional reduction, plus the actual PNG assets"
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
      .data$effective_final_essential_text_pt >= 7 &
        .data$effective_final_central_text_pt >= 7,
      "PASS_BY_CALCULATION",
      "FAIL"
    ),
    visual_status = check_value,
    overall_status = overall_value,
    status = overall_value,
    reporting_rule = "REPORT-011; symlog not applicable",
    qa_record = record_relative,
    producer = producer,
    r_version = as.character(getRversion())
  )

invisible(write_csv_artifact(qa, qa_path, producer = producer))
invisible(write_csv_artifact(
  proof_rows,
  file.path(manifest_dir, "H07_figure_A4_proof_index.csv"),
  producer = producer
))
message(
  "Recorded physical-size evidence for ",
  nrow(qa),
  " H07 figures; status ",
  unique(qa$overall_status)
)
