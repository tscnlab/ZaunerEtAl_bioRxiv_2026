#!/usr/bin/env Rscript

# Build REPORT-011 physical-size evidence for the eight reader-facing H10
# figures. This script places existing raster assets on a bounded A4 QA
# scaffold; it does not calculate or alter a scientific result.

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
    sprintf("H10 figure QA requires R 4.6.1; running %s", getRversion()),
    call. = FALSE
  )
}
if (!requireNamespace("png", quietly = TRUE)) {
  stop("The project library does not provide package 'png'", call. = FALSE)
}

producer <- paste0(
  "scripts/hypotheses/H10/",
  "build_h10_stage3_figure_qa.R"
)
output_relative <- paste0(
  "artifacts/12_manifests/H10/",
  "H10_stage3_figure_readability_qa.csv"
)
output_path <- file.path(root, output_relative)
proof_relative <- paste0(
  "artifacts/12_manifests/H10/",
  "H10_stage3_figure_A4_proofs.pdf"
)
proof_path <- file.path(root, proof_relative)
record_relative <- "audit/hypotheses/H10/03_stage3_figure_qa.md"
record_path <- file.path(root, record_relative)

qa <- tibble::tribble(
  ~figure_id,
  ~path,
  ~base_width_in,
  ~base_height_in,
  ~smallest_essential_nominal_text_pt,
  ~smallest_central_nominal_text_pt,
  ~review_note,
  "fig-h10-age-associations",
  "artifacts/10_figures/H10/H10_primary_age_associations.png",
  9.4,
  8.5,
  8,
  10,
  "All 17 metric labels, placement panels, points, intervals, axes, annotations, and retained-finding marks must remain readable and unclipped.",
  "fig-h10-age-site-overview",
  "artifacts/10_figures/H10/H10_age_site_significant_associations.png",
  9.4,
  13,
  8,
  10,
  "Both placement-specific age distributions, all 11 retained main estimates, both heterogeneity panels, submitted site names and colours, intervals, annotations, and qualifications must remain readable and unclipped.",
  "fig-h10-sex-associations",
  "artifacts/10_figures/H10/H10_primary_biological_sex_associations.png",
  9.4,
  8.5,
  8,
  10,
  "All 17 metric labels, placement panels, points, intervals, axes, annotations, and retained-finding marks must remain readable and unclipped.",
  "fig-h10-diagnostics",
  "artifacts/10_figures/H10/H10_diagnostic_assessment.png",
  9.4,
  8.2,
  8,
  10,
  "All 17 metric labels, four association panels, assessment cells, and legend must remain readable and distinguishable without overlap.",
  "fig-h10-core-diagnostics-age",
  "artifacts/10_figures/H10/H10_retained_age_core_diagnostics.png",
  9.4,
  13,
  8,
  10,
  "All nine retained age models, 18 independently scaled residual-fitted and normal Q-Q panels, site-coloured points, reference lines, axes, titles, and legend must remain readable and unclipped.",
  "fig-h10-core-diagnostics-biological-sex",
  "artifacts/10_figures/H10/H10_retained_biological_sex_core_diagnostics.png",
  9.4,
  5.5,
  8,
  10,
  "Both retained biological-sex models, four independently scaled residual-fitted and normal Q-Q panels, site-coloured points, reference lines, axes, titles, and legend must remain readable and unclipped.",
  "fig-h10-paired-placement",
  "artifacts/10_figures/H10/H10_paired_placement_effects.png",
  9.4,
  5.8,
  8,
  10,
  "Both association panels, component intervals, point labels, null and identity lines, and legend must remain readable without implying equivalence.",
  "fig-h10-gap-common",
  "artifacts/10_figures/H10/H10_gap_common_sample_effects.png",
  9.4,
  5.8,
  8,
  10,
  "Both association panels, component intervals, point labels, null and identity lines, and placement legend must remain readable and unclipped."
)

absolute_paths <- file.path(root, qa$path)
if (any(!file.exists(absolute_paths))) {
  stop(
    paste0(
      "Missing H10 reader figure(s): ",
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
    page = "H10 results",
    intended_html_width = "100%",
    intended_html_fraction = 1,
    export_scale_multiplier = 1,
    raster_dpi = 300,
    export_width_in = .data$base_width_in * .data$export_scale_multiplier,
    export_height_in = .data$base_height_in * .data$export_scale_multiplier,
    native_export_width_mm = .data$export_width_in * 25.4,
    native_export_height_mm = .data$export_height_in * 25.4,
    intended_display_width_mm = 170 * .data$intended_html_fraction,
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
    bytes = unname(file.info(absolute_paths)$size),
    a4_page_width_mm = 210,
    a4_page_height_mm = 297,
    a4_side_margin_mm = (.data$a4_page_width_mm -
      .data$intended_display_width_mm) /
      2,
    a4_proof_path = proof_relative,
    a4_proof_page = dplyr::row_number(),
    final_asset_canvas = "tightly bounded to figure; A4 page excluded",
    physical_size_evidence = paste0(
      "A4 portrait raster proof at ",
      format(round(.data$intended_display_width_mm, 1), nsmall = 1),
      " mm within the 170-mm reference frame"
    ),
    symlog_applicability = paste0(
      "NOT_APPLICABLE: displays show participant ages, standardized ",
      "coefficients, categorical assessments, or Pearson residuals, not ",
      "nonnegative melEDI-like values"
    )
  )

expected_pixel_width <- qa$export_width_in * qa$raster_dpi
expected_pixel_height <- qa$export_height_in * qa$raster_dpi
if (
  nrow(qa) != 8L ||
    anyDuplicated(qa$figure_id) ||
    any(abs(qa$pixel_width - expected_pixel_width) > 1L) ||
    any(abs(qa$pixel_height - expected_pixel_height) > 1L) ||
    any(qa$effective_final_essential_text_pt < 5) ||
    any(qa$effective_final_central_text_pt < 7) ||
    any(nchar(qa$sha256) != 64L) ||
    any(qa$a4_side_margin_mm < 20)
) {
  stop("Invalid H10 physical-size figure evidence", call. = FALSE)
}

# The A4 file is an inspection scaffold only. The reader assets themselves
# remain tightly cropped PNG/PDF exports at their original dimensions.
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
  stop("H10 physical-size proof was not created", call. = FALSE)
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
    inspection_date = if (inspection_passed) {
      as.Date("2026-08-10")
    } else {
      as.Date(NA)
    },
    inspection_basis = paste(
      "Eight-page A4 portrait proof with each final figure at 170 mm;",
      "compiled Quarto HTML structure checked for 100% display width,",
      "captions, alt text, and resolved local assets"
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
      .data$effective_final_essential_text_pt >= 5 &
        .data$effective_final_central_text_pt >= 7,
      "PASS_BY_CALCULATION",
      "FAIL"
    ),
    visual_status = check_value,
    overall_status = overall_value,
    status = overall_value,
    reporting_rule = "REPORT-011; REPORT-013 not applicable",
    qa_record = record_relative,
    producer = producer,
    r_version = as.character(getRversion())
  )

invisible(write_csv_artifact(qa, output_path, producer))
message(
  "Recorded physical-size evidence for ",
  nrow(qa),
  " H10 figures; status ",
  unique(qa$overall_status)
)
