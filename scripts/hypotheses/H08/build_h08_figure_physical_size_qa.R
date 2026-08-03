#!/usr/bin/env Rscript

# Build A4 physical-size inspection sheets and record REPORT-011 QA for every
# reader-facing H08 figure. The script uses existing raster outputs only; it
# does not transform research data or fit, diagnose, compare, or refit a model.

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
  stop(
    paste0(
      "The H08 physical-size QA requires R 4.6.1; found ",
      as.character(getRversion())
    ),
    call. = FALSE
  )
}
if (!requireNamespace("png", quietly = TRUE)) {
  stop("The project library does not provide package 'png'", call. = FALSE)
}

producer <- paste0(
  "scripts/hypotheses/H08/",
  "build_h08_figure_physical_size_qa.R"
)
manifest_dir <- file.path(root, "artifacts/12_manifests/H08")
proof_dir <- file.path(manifest_dir, "physical_size_qa")
dir.create(proof_dir, recursive = TRUE, showWarnings = FALSE)

result_manifest <- readr::read_csv(
  file.path(manifest_dir, "H08_figure_manifest.csv"),
  show_col_types = FALSE
)
required_result_columns <- c(
  "figure_path",
  "source_data_path",
  "width_in",
  "height_in",
  "native_width_mm",
  "intended_width_mm",
  "smallest_essential_nominal_text_pt",
  "scaling_factor",
  "effective_final_text_pt"
)
stopifnot(
  nrow(result_manifest) == 5L,
  all(required_result_columns %in% names(result_manifest))
)

result_figure_ids <- c(
  "fig-h08-near-eye-effects",
  "fig-h08-chest-effects",
  "fig-h08-paired-placement",
  "fig-h08-gap-common-sample",
  "fig-h08-model-adequacy"
)
result_review_notes <- c(
  paste(
    "Nine metric labels, both practical-effect panels, points, 95% interval",
    "bars, null line, title, subtitle, and caption are legible and unclipped."
  ),
  paste(
    "Nine metric labels, both practical-effect panels, points, 95% interval",
    "bars, null line, title, subtitle, and caption are legible and unclipped."
  ),
  paste(
    "Eight abbreviations, component interval bars, placement identity line,",
    "null lines, category legend, title, subtitle, axes, and caption remain",
    "distinct; equal-axis geometry is not distorted."
  ),
  paste(
    "Sixteen point labels, placement colours and shapes, identity and null",
    "lines, title, subtitle, axes, and caption are legible without overlap."
  ),
  paste(
    "All nine metric strips, both diagnostic columns, residual marks, axes,",
    "title, subtitle, and caption are legible; the 18 data regions are",
    "balanced and fully contained on the A4 page."
  )
)

result_registry <- result_manifest |>
  mutate(
    figure_id = result_figure_ids,
    page = "H08 results",
    path = .data$figure_path,
    source_data_path = .data$source_data_path,
    native_export_width_mm = .data$native_width_mm,
    native_export_height_mm = .data$height_in * 25.4,
    intended_display_width_mm = .data$intended_width_mm,
    scale_factor = .data$scaling_factor,
    smallest_essential_nominal_text_pt = .data$smallest_essential_nominal_text_pt,
    effective_final_essential_text_pt = .data$effective_final_text_pt,
    review_note = result_review_notes
  ) |>
  select(
    "figure_id",
    "page",
    "path",
    "source_data_path",
    "native_export_width_mm",
    "native_export_height_mm",
    "intended_display_width_mm",
    "scale_factor",
    "smallest_essential_nominal_text_pt",
    "effective_final_essential_text_pt",
    "review_note"
  )

preparation_asset_root_candidates <- c(
  "_build/nathealth/audit/hypotheses/H08/H08_analysis_preparation_files/figure-html",
  "audit/hypotheses/H08/H08_analysis_preparation_files/figure-html"
)
preparation_asset_root <- preparation_asset_root_candidates[
  vapply(
    preparation_asset_root_candidates,
    function(path) dir.exists(file.path(root, path)),
    logical(1)
  )
][1L]
if (is.na(preparation_asset_root)) {
  stop("Could not locate rendered H08 preparation figure assets", call. = FALSE)
}

preparation_registry <- tibble::tribble(
  ~figure_id,
  ~page,
  ~filename,
  ~source_data_path,
  ~native_export_width_mm,
  ~native_export_height_mm,
  ~intended_display_width_mm,
  ~smallest_essential_nominal_text_pt,
  ~review_note,
  "fig-h08-prep-vlsq-distribution",
  "H08 preparation",
  "fig-h08-prep-vlsq-distribution-1.png",
  "artifacts/11_source_data/H08/H08_preparation_vlsq_score_distribution.csv",
  170,
  4.6 * 25.4,
  170,
  8,
  paste(
    "Every score tick, participant-count tick, axis title, and bar is legible;",
    "the distribution is balanced and unclipped."
  ),
  "fig-h08-prep-sample-support",
  "H08 preparation",
  "fig-h08-prep-sample-support-1.png",
  "artifacts/11_source_data/H08/H08_preparation_sample_support.csv",
  170,
  4.9 * 25.4,
  170,
  8,
  paste(
    "Both sample-support panels, metric-order ticks, placement legend, lines,",
    "points, and axis titles are legible and distinguishable."
  ),
  "fig-h08-prep-site-range",
  "H08 preparation",
  "fig-h08-prep-site-range-1.png",
  "artifacts/11_source_data/H08/H08_preparation_site_support_summary.csv",
  170,
  5.9 * 25.4,
  170,
  8,
  paste(
    "Submitted site names, both placement panels, axes, coloured ranges, and",
    "end points are legible, distinct, and unclipped."
  )
) |>
  mutate(
    path = file.path(preparation_asset_root, .data$filename),
    scale_factor = .data$intended_display_width_mm /
      .data$native_export_width_mm,
    effective_final_essential_text_pt = .data$smallest_essential_nominal_text_pt *
      .data$scale_factor
  ) |>
  select(-"filename")

qa <- bind_rows(result_registry, preparation_registry) |>
  mutate(
    a4_page_width_mm = 210,
    a4_page_height_mm = 297,
    a4_side_margin_mm = 20,
    final_display_height_mm = .data$native_export_height_mm *
      .data$scale_factor
  )

absolute_paths <- file.path(root, qa$path)
absolute_sources <- file.path(root, qa$source_data_path)
if (any(!file.exists(absolute_paths))) {
  stop(
    paste0(
      "Missing H08 figure asset(s): ",
      paste(qa$path[!file.exists(absolute_paths)], collapse = ", ")
    ),
    call. = FALSE
  )
}
if (any(!file.exists(absolute_sources))) {
  stop(
    paste0(
      "Missing H08 figure source-data file(s): ",
      paste(
        qa$source_data_path[!file.exists(absolute_sources)],
        collapse = ", "
      )
    ),
    call. = FALSE
  )
}
if (
  nrow(qa) != 8L ||
    anyDuplicated(qa$figure_id) ||
    any(abs(qa$native_export_width_mm - 170) > 1e-8) ||
    any(abs(qa$intended_display_width_mm - 170) > 1e-8) ||
    any(abs(qa$scale_factor - 1) > 1e-8) ||
    any(qa$effective_final_essential_text_pt < 7) ||
    any(qa$final_display_height_mm > 257)
) {
  stop("H08 figure registry violates the REPORT-011 geometry", call. = FALSE)
}

dimensions <- lapply(
  absolute_paths,
  function(path) dim(png::readPNG(path, native = TRUE))
)
qa$pixel_width <- vapply(dimensions, `[[`, integer(1), 2L)
qa$pixel_height <- vapply(dimensions, `[[`, integer(1), 1L)
qa$figure_sha256 <- vapply(
  absolute_paths,
  artifact_sha256,
  character(1)
)
qa$figure_bytes <- as.numeric(file.info(absolute_paths)$size)

proof_paths <- file.path(
  proof_dir,
  paste0(qa$figure_id, "_A4_170mm.png")
)
for (index in seq_len(nrow(qa))) {
  figure_raster <- png::readPNG(absolute_paths[index])
  grDevices::png(
    filename = proof_paths[index],
    width = 210,
    height = 297,
    units = "mm",
    res = 150,
    type = "cairo-png",
    bg = "white"
  )
  grid::grid.newpage()
  grid::grid.rect(gp = grid::gpar(fill = "white", col = NA))
  grid::grid.lines(
    x = grid::unit(c(20, 20), "mm"),
    y = grid::unit(c(0, 297), "mm"),
    gp = grid::gpar(col = "#D1D5DB", lwd = 0.5)
  )
  grid::grid.lines(
    x = grid::unit(c(190, 190), "mm"),
    y = grid::unit(c(0, 297), "mm"),
    gp = grid::gpar(col = "#D1D5DB", lwd = 0.5)
  )
  figure_viewport <- grid::viewport(
    x = grid::unit(105, "mm"),
    y = grid::unit(148.5, "mm"),
    width = grid::unit(qa$intended_display_width_mm[index], "mm"),
    height = grid::unit(qa$final_display_height_mm[index], "mm")
  )
  grid::pushViewport(figure_viewport)
  grid::grid.raster(
    figure_raster,
    width = grid::unit(1, "npc"),
    height = grid::unit(1, "npc"),
    interpolate = TRUE
  )
  grid::grid.rect(gp = grid::gpar(fill = NA, col = "#9CA3AF", lwd = 0.5))
  grid::popViewport()
  grid::grid.text(
    paste0(
      qa$figure_id[index],
      " — 170 mm on A4 portrait; 20-mm side margins"
    ),
    x = grid::unit(20, "mm"),
    y = grid::unit(7, "mm"),
    just = c("left", "bottom"),
    gp = grid::gpar(fontsize = 6, col = "#4B5563")
  )
  grDevices::dev.off()
}

visual_approval <- identical(
  tolower(Sys.getenv("H08_PHYSICAL_QA_APPROVED", unset = "false")),
  "true"
)
qa <- qa |>
  mutate(
    a4_proof_path = substring(proof_paths, nchar(root) + 2L),
    a4_proof_sha256 = vapply(
      proof_paths,
      artifact_sha256,
      character(1)
    ),
    inspection_medium = paste(
      "A4 portrait PNG at 210 x 297 mm and 150 dpi, with the figure",
      "placed at 170 mm between 20-mm side margins; inspected at original",
      "page dimensions"
    ),
    physical_size_calculation = if_else(
      .data$effective_final_essential_text_pt >= 7,
      "PASS",
      "FAIL"
    ),
    no_clipping_or_cropping = visual_approval,
    no_overlap = visual_approval,
    no_text_distortion = visual_approval,
    no_bad_wrapping = visual_approval,
    important_text_readable = visual_approval,
    data_region_proportionate = visual_approval,
    marks_distinguishable = visual_approval,
    caption_and_alt_text_present = visual_approval,
    visual_inspection = if_else(visual_approval, "PASS", "PENDING"),
    status = if_else(visual_approval, "PASS", "NOT TESTED"),
    reporting_rule = "REPORT-011",
    producer = producer,
    r_version = as.character(getRversion())
  ) |>
  select(-"final_display_height_mm")

output_path <- file.path(
  manifest_dir,
  "H08_figure_physical_size_qa.csv"
)
invisible(write_csv_artifact(qa, output_path, producer))

if (visual_approval) {
  message(
    "Recorded passing A4 physical-size inspection for ",
    nrow(qa),
    " H08 figures"
  )
} else {
  message(
    "Built ",
    nrow(qa),
    " A4 physical-size inspection sheets; QA remains NOT TESTED until the ",
    "sheets are inspected and H08_PHYSICAL_QA_APPROVED=true is supplied"
  )
}
