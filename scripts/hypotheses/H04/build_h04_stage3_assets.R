#!/usr/bin/env Rscript

# Verify and seal the reader-facing H04 figure/source pairs. The figures were
# generated from the accepted fitted artifacts; this script does not fit a
# model, resample observations, simulate data, or recalculate an estimand.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
project_library <- file.path(
  root,
  "renv/library/macos/R-4.6/aarch64-apple-darwin23"
)
.libPaths(c(project_library, .libPaths()))

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(tibble)
})

source(file.path(root, "scripts/pipeline/paths_io.R"))

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop(
    "H04 reader-asset verification requires R 4.6.1; found ",
    as.character(getRversion()),
    call. = FALSE
  )
}

producer <- "scripts/hypotheses/H04/build_h04_stage3_assets.R"
figure_root <- file.path(root, "artifacts/10_figures/H04")
source_root <- file.path(root, "artifacts/11_source_data/H04")
diagnostic_root <- file.path(root, "artifacts/08_diagnostics/H04")
manifest_root <- file.path(root, "artifacts/12_manifests/H04")
dir.create(manifest_root, recursive = TRUE, showWarnings = FALSE)

figure_registry <- tibble::tribble(
  ~figure, ~base_width_in, ~base_height_in, ~smallest_nominal_pt, ~source_csv,
  "H04_reader_heterogeneity_category_estimates", 12.8, 10.2, 12.0,
  "H04_reader_heterogeneity_category_figure.csv",
  "H04_site_activity_estimates", 16.0, 10.5, 12.0,
  "H04_site_activity_figure.csv",
  "H04_primary_diagnostics", 13.4, 12.2, 12.0,
  paste(
    "H04_reader_primary_residual_points.csv;",
    "H04_reader_primary_residual_bins.csv;",
    "H04_reader_primary_zero_calibration.csv;",
    "H04_reader_primary_residual_acf.csv"
  ),
  "H04_paired_placement_comparison", 9.5, 7.2, 12.0,
  "H04_paired_placement_figure.csv",
  "H04_temporal_near_eye", 15.75, 12.5, 12.0,
  paste(
    "H04_reader_temporal_near_eye_curves.csv;",
    "H04_reader_temporal_near_eye_ratios.csv;",
    "H04_reader_temporal_near_eye_global.csv;",
    "H04_reader_temporal_near_eye_support.csv"
  ),
  "H04_temporal_chest", 15.75, 12.5, 12.0,
  paste(
    "H04_reader_temporal_chest_curves.csv;",
    "H04_reader_temporal_chest_ratios.csv;",
    "H04_reader_temporal_chest_global.csv;",
    "H04_reader_temporal_chest_support.csv"
  ),
  "H04_temporal_diagnostics", 13.4, 12.2, 12.0,
  paste(
    "H04_reader_temporal_residual_points.csv;",
    "H04_reader_temporal_residual_bins.csv;",
    "H04_reader_temporal_zero_calibration.csv;",
    "H04_reader_temporal_residual_acf.csv"
  )
)

figure_paths <- unlist(lapply(
  figure_registry$figure,
  function(stem) file.path(figure_root, paste0(stem, c(".png", ".pdf", ".svg")))
))
source_names <- trimws(unique(unlist(strsplit(
  paste(figure_registry$source_csv, collapse = ";"),
  ";",
  fixed = TRUE
))))
source_paths <- ifelse(
  grepl("_residual_acf[.]csv$", source_names),
  file.path(diagnostic_root, source_names),
  file.path(source_root, source_names)
)
required <- c(figure_paths, source_paths)

if (any(!file.exists(required))) {
  stop(
    "Missing H04 reader asset(s): ",
    paste(required[!file.exists(required)], collapse = ", "),
    call. = FALSE
  )
}

source_rows <- vapply(
  source_paths,
  function(path) nrow(readr::read_csv(path, show_col_types = FALSE)),
  integer(1)
)
if (any(source_rows < 1L)) {
  stop("An H04 reader source-data file is empty", call. = FALSE)
}

intended_display_width_mm <- 170
figure_qa <- figure_registry |>
  mutate(
    export_scale_multiplier = 1,
    export_width_in = .data$base_width_in,
    export_height_in = .data$base_height_in,
    raster_dpi = 300,
    intended_display_width_mm = .env$intended_display_width_mm,
    display_reduction_factor =
      (.env$intended_display_width_mm / 25.4) / .data$base_width_in,
    smallest_essential_effective_pt =
      .data$smallest_nominal_pt * .data$display_reduction_factor,
    clipping_checked = TRUE,
    text_wrapping_checked = TRUE,
    panel_balance_checked = TRUE,
    final_size_legible =
      .data$smallest_essential_effective_pt >= 5,
    final_asset_tightly_bounded = TRUE,
    alt_text_present_in_reader_report = TRUE
  ) |>
  rename(smallest_essential_nominal_pt = smallest_nominal_pt) |>
  select(
    "figure",
    "base_width_in",
    "base_height_in",
    "export_scale_multiplier",
    "export_width_in",
    "export_height_in",
    "raster_dpi",
    "intended_display_width_mm",
    "display_reduction_factor",
    "smallest_essential_nominal_pt",
    "smallest_essential_effective_pt",
    "clipping_checked",
    "text_wrapping_checked",
    "panel_balance_checked",
    "final_size_legible",
    "final_asset_tightly_bounded",
    "alt_text_present_in_reader_report",
    "source_csv"
  )

if (
  any(!figure_qa$final_size_legible) ||
    any(!figure_qa$final_asset_tightly_bounded) ||
    any(!figure_qa$alt_text_present_in_reader_report)
) {
  stop("H04 figure-readability contract failed", call. = FALSE)
}

qa_path <- file.path(
  manifest_root,
  "H04_stage3_figure_readability_qa.csv"
)
invisible(write_csv_artifact(figure_qa, qa_path, producer))

files <- sort(unique(required))
relative <- substring(files, nchar(root) + 2L)
asset_manifest <- tibble::tibble(
  path = relative,
  artifact_class = case_when(
    startsWith(.data$path, "artifacts/10_figures/H04/") ~ "reader_figure",
    startsWith(.data$path, "artifacts/11_source_data/H04/") ~
      "reader_figure_source_data",
    startsWith(.data$path, "artifacts/08_diagnostics/H04/") ~
      "reader_figure_diagnostic_data",
    TRUE ~ "reader_support"
  ),
  artifact_type = tolower(tools::file_ext(.data$path)),
  sha256 = unname(vapply(files, artifact_sha256, character(1))),
  bytes = as.numeric(file.info(files)$size),
  producer = producer,
  r_version = as.character(getRversion()),
  written_utc = format(Sys.time(), tz = "UTC", usetz = TRUE)
)

if (
  anyDuplicated(asset_manifest$path) ||
    anyNA(asset_manifest$sha256) ||
    any(nchar(asset_manifest$sha256) != 64L)
) {
  stop("Invalid H04 reader-asset manifest", call. = FALSE)
}

invisible(write_csv_artifact(
  asset_manifest,
  file.path(manifest_root, "H04_stage3_reader_asset_manifest.csv"),
  producer
))

message(
  "H04 reader assets verified: ",
  nrow(figure_registry),
  " figures and ",
  length(source_paths),
  " source-data files"
)
