#!/usr/bin/env Rscript

# Focused checks for the additive H09 Stage 3 observed-data composite. The
# checks use frozen inputs and stored fits but do not fit a model.

startup_root <- Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd())
startup_library <- file.path(
  startup_root,
  "renv/library/macos/R-4.6/aarch64-apple-darwin23"
)
if (dir.exists(startup_library)) {
  .libPaths(c(startup_library, .libPaths()))
}

suppressPackageStartupMessages({
  library(dplyr)
  library(png)
  library(readr)
})

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("H09 observed-figure tests require R 4.6.1", call. = FALSE)
}

builder_path <- file.path(
  root,
  "scripts/hypotheses/H09/build_h09_stage3_observed_figure.R"
)
source(builder_path, local = TRUE)
output_root <- normalizePath(
  Sys.getenv("H09_STAGE3_OBSERVED_OUTPUT_ROOT", unset = root),
  winslash = "/",
  mustWork = TRUE
)
source_path <- file.path(
  output_root,
  "artifacts/11_source_data/H09/H09_observed_timing_patterns_data.csv"
)
png_path <- file.path(
  output_root,
  "artifacts/10_figures/H09/H09_observed_timing_patterns.png"
)
pdf_path <- file.path(
  output_root,
  "artifacts/10_figures/H09/H09_observed_timing_patterns.pdf"
)
stopifnot(all(file.exists(c(source_path, png_path, pdf_path))))

expected <- h09_prepare_stage3_observed_layers(root)
observed <- readr::read_csv(
  source_path,
  show_col_types = FALSE,
  progress = FALSE,
  na = ""
)
comparison <- all.equal(
  as.data.frame(observed),
  as.data.frame(expected),
  tolerance = 1e-12,
  check.attributes = FALSE
)
if (!isTRUE(comparison)) {
  stop(
    paste("Paired figure source differs from frozen plotting layers:", comparison),
    call. = FALSE
  )
}

points <- observed |>
  filter(.data$layer_role == "participant_day")
lines <- observed |>
  filter(.data$layer_role == "model_line")
overview <- observed |>
  filter(.data$layer_role == "chronotype_participant")
master <- readr::read_csv(
  file.path(root, "artifacts/09_tables/H09/H09_model_results_master.csv"),
  show_col_types = FALSE,
  progress = FALSE
)
supported <- master |>
  filter(
    .data$data_scenario_id == "primary",
    .data$placement == "glasses",
    .data$sample_scenario == "all_available",
    .data$primary_family_member,
    .data$main_adjusted_significant
  )
expected_point_rows <- sum(supported$observations)
expected_pairs <- tidyr::crossing(
  instrument_id = c("MCTQ", "MEQ"),
  metric_id = c(
    "m10_midpoint",
    "l10_midpoint",
    "first_timing_above_250"
  )
)
observed_pairs <- points |>
  distinct(.data$instrument_id, .data$metric_id)

forbidden_columns <- c(
  "Id",
  "participant_key",
  "local_date",
  ".model_row_id",
  "private_order_key",
  "main_p_raw"
)
stopifnot(
  nrow(points) == expected_point_rows,
  nrow(lines) == 606L,
  nrow(overview) == 371L,
  dplyr::n_distinct(points$frame_id) == 6L,
  nrow(dplyr::anti_join(expected_pairs, observed_pairs, by = c(
    "instrument_id",
    "metric_id"
  ))) == 0L,
  identical(sort(unique(points$instrument_id)), c("MCTQ", "MEQ")),
  identical(sort(unique(points$metric_id)), sort(c(
    "m10_midpoint",
    "l10_midpoint",
    "first_timing_above_250"
  ))),
  all(points$data_scenario_id == "primary"),
  all(points$placement == "glasses"),
  all(points$fdr_supported),
  all(points$main_p_adjusted < 0.05),
  all(lines$prediction_scope ==
    "equal-site-average fixed effect; random effect zero"),
  sum(overview$instrument_id == "MCTQ") == 185L,
  sum(overview$instrument_id == "MEQ") == 186L,
  !any(forbidden_columns %in% names(observed))
)

line_slopes <- lines |>
  group_by(.data$frame_id, .data$instrument_id, .data$metric_id) |>
  summarise(
    reconstructed_slope = (
      dplyr::last(.data$timing_hour) - dplyr::first(.data$timing_hour)
    ) / (
      dplyr::last(.data$predictor_centered_value) -
        dplyr::first(.data$predictor_centered_value)
    ),
    .groups = "drop"
  ) |>
  left_join(
    supported |>
      select("frame_id", accepted_slope = "estimate"),
    by = "frame_id",
    relationship = "one-to-one"
  )
stopifnot(max(abs(
  line_slopes$reconstructed_slope - line_slopes$accepted_slope
)) < 1e-12)

site_registry <- readr::read_csv(
  file.path(root, "config/site_display_registry.csv"),
  show_col_types = FALSE,
  progress = FALSE
)
observed_sites <- observed |>
  filter(!is.na(.data$site)) |>
  distinct(.data$site, .data$site_order, .data$site_name, .data$site_colour) |>
  arrange(.data$site_order) |>
  transmute(
    site = .data$site,
    display_order = .data$site_order,
    display_name = .data$site_name,
    color_hex = .data$site_colour
  )
stopifnot(isTRUE(all.equal(
  as.data.frame(observed_sites),
  as.data.frame(site_registry),
  tolerance = 0,
  check.attributes = FALSE
)))

png_image <- png::readPNG(png_path, native = TRUE, info = TRUE)
stopifnot(identical(as.integer(dim(png_image)), c(3825L, 4725L)))
pdf_header <- readBin(pdf_path, what = "raw", n = 4L)
stopifnot(identical(rawToChar(pdf_header), "%PDF"))

builder_text <- paste(readLines(builder_path, warn = FALSE), collapse = "\n")
forbidden_calls <- c(
  "lmer(",
  "lm(",
  "glm(",
  "gam(",
  "update(",
  "boot(",
  "geom_smooth("
)
stopifnot(!any(vapply(
  forbidden_calls,
  grepl,
  logical(1),
  x = builder_text,
  fixed = TRUE
)))

qmd_path <- file.path(root, "notebooks/hypotheses/H09.qmd")
qmd_text <- paste(readLines(qmd_path, warn = FALSE), collapse = "\n")
stopifnot(
  grepl("fig-h09-observed-timing-patterns", qmd_text, fixed = TRUE),
  grepl("H09_observed_timing_patterns.png", qmd_text, fixed = TRUE),
  grepl("H09_observed_timing_patterns_data.csv", qmd_text, fixed = TRUE),
  grepl("equal-site-average", qmd_text, fixed = TRUE),
  grepl("descriptive participant-level", qmd_text, fixed = TRUE),
  !grepl("V0", qmd_text, fixed = TRUE)
)

if (identical(output_root, root)) {
  figure_manifest <- readr::read_csv(
    file.path(root, "artifacts/12_manifests/H09/H09_figure_manifest.csv"),
    show_col_types = FALSE,
    progress = FALSE
  )
  manifest_row <- figure_manifest |>
    filter(.data$figure_id == "observed_timing_patterns")
  stopifnot(
    nrow(manifest_row) == 1L,
    manifest_row$figure_path ==
      "artifacts/10_figures/H09/H09_observed_timing_patterns.png",
    manifest_row$source_data_path ==
      "artifacts/11_source_data/H09/H09_observed_timing_patterns_data.csv",
    manifest_row$pdf_path ==
      "artifacts/10_figures/H09/H09_observed_timing_patterns.pdf",
    manifest_row$base_width_in == 10.5,
    manifest_row$base_height_in == 8.5,
    manifest_row$export_scale_multiplier == 1.5,
    manifest_row$effective_final_text_pt >= 7,
    grepl("SOURCE-READY", manifest_row$visual_qa_status, fixed = TRUE),
    !grepl("V0", manifest_row$alt_text, fixed = TRUE)
  )
}

message(
  "H09 Stage 3 composite checks passed: six frozen FDR-supported primary ",
  "near-eye associations, exact equal-site-average lines and 95% CIs, ",
  "371 de-identified participant-level chronotype rows, registered sites, ",
  "paired plotting data, and no model fitting"
)
