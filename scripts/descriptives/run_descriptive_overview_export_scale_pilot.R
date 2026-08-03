# Render only the corrected Figure 1 ggsave export-scale pilot.

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
source(file.path(root, "scripts", "descriptives", "build_descriptives.R"))
source_descriptive_modules(root)

paths <- descriptive_paths(root)
spec <- descriptive_figure_spec()
pilot_spec <- spec |>
  dplyr::filter(.data$figure_id == "descriptive_overview")
expected_pixels <- c(4725L, 4500L)

if (
  nrow(pilot_spec) != 1L ||
    !identical(pilot_spec$base_width_in, 10.5) ||
    !identical(pilot_spec$base_height_in, 10) ||
    !identical(pilot_spec$export_scale_multiplier, 1.5) ||
    !identical(pilot_spec$export_width_in, 15.75) ||
    !identical(pilot_spec$export_height_in, 15) ||
    !identical(pilot_spec$html_out_width, "100%") ||
    !identical(pilot_spec$print_display_width_mm, 170) ||
    !identical(pilot_spec$dpi, 300L)
) {
  stop("The corrected Figure 1 export-scale contract is invalid.", call. = FALSE)
}

locations <- read_plot_source_csv(file.path(
  paths$source_dir, "site_locations.csv"
))
world <- read_plot_source_csv(file.path(
  paths$source_dir, "world_map_wkt.csv"
))
collection_intervals <- read_plot_source_csv(file.path(
  paths$source_dir, "collection_intervals.csv"
)) |>
  dplyr::mutate(
    interval_start = as.Date(.data$interval_start),
    interval_end = as.Date(.data$interval_end)
  )
collection_days <- read_plot_source_csv(file.path(
  paths$source_dir, "available_collection_days.csv"
)) |>
  dplyr::mutate(local_date = as.Date(.data$local_date))
profile <- read_plot_source_csv(file.path(
  paths$source_dir, "profile_summary.csv"
))
state <- read_plot_source_csv(file.path(
  paths$source_dir, "profile_context_bands.csv"
))
period <- read_plot_source_csv(file.path(
  paths$source_dir, "profile_average_periods.csv"
))

pilot_plot <- make_overview_replica_figure(
  protocol_asset_path = file.path(
    root, "assets", "2026-03-30_MeLiDos_Protocol.png"
  ),
  site_locations = locations,
  world_map = world,
  collection_intervals = collection_intervals,
  collection_days = collection_days,
  profile = profile,
  state_source = state,
  period_source = period
)

outputs <- save_descriptive_figure(
  plot = pilot_plot,
  stem = file.path(paths$figure_dir, "descriptive_overview"),
  width = pilot_spec$base_width_in[[1L]],
  height = pilot_spec$base_height_in[[1L]],
  dpi = pilot_spec$dpi[[1L]],
  scale = pilot_spec$export_scale_multiplier[[1L]]
)
pilot_dimensions <- read_png_dimensions(outputs[["png"]])
if (!identical(unname(pilot_dimensions), expected_pixels)) {
  stop(
    "Corrected Figure 1 must be exactly 4725 by 4500 pixels; observed ",
    paste(pilot_dimensions, collapse = " by "), ".",
    call. = FALSE
  )
}

mockup_path <- file.path(root, pilot_spec$a4_mockup_path[[1L]])
save_descriptive_a4_mockup(
  figure_png = outputs[["png"]],
  mockup_png = mockup_path,
  figure_width_mm = pilot_spec$print_display_width_mm[[1L]],
  figure_height_mm = pilot_spec$print_display_height_mm[[1L]],
  dpi = pilot_spec$a4_mockup_dpi[[1L]]
)

figure_spec_path <- file.path(
  paths$manifest_dir, "figure_specifications.csv"
)
write_descriptive_csv(spec, figure_spec_path)

qa_path <- file.path(paths$audit_dir, "figure_readability_qa.csv")
qa <- build_descriptive_figure_qa(spec, paths)
write_descriptive_csv(qa, qa_path)

comparison_path <- file.path(
  paths$audit_dir, "visual_export_comparison.csv"
)
comparison <- read_plot_source_csv(comparison_path)
comparison_index <- which(
  comparison$output_id == "descriptive_overview" &
    comparison$output_type == "figure"
)
if (length(comparison_index) != 1L) {
  stop("The Figure 1 visual-comparison row is missing.", call. = FALSE)
}
comparison$comparison_scope[[comparison_index]] <- paste(
  "REPORT-011-PILOT-001 literal ggsave(scale = 1.5) showcase;",
  "submitted Figure 1 geometry, source-level themes, and accepted",
  "scientific content"
)
comparison$required_difference[[comparison_index]] <- paste(
  "The accepted content uses the submitted 14-pt cowplot themes and",
  "10.5-by-10-inch base canvas, exported on a 15.75-by-15-inch device;",
  "Quarto displays the external asset at 100%."
)
comparison$rebuilt_sha256[[comparison_index]] <- artifact_sha256(
  outputs[["png"]]
)
comparison$rebuilt_width_px[[comparison_index]] <- pilot_dimensions[[1L]]
comparison$rebuilt_height_px[[comparison_index]] <- pilot_dimensions[[2L]]
comparison$review_state[[comparison_index]] <- pilot_spec$physical_size_qa[[1L]]
write_descriptive_csv(comparison, comparison_path)

manifest_path <- file.path(
  paths$manifest_dir, "descriptive_artifacts.csv"
)
manifest <- read_plot_source_csv(manifest_path)
changed_paths <- c(unname(outputs), mockup_path, qa_path, comparison_path)
figure_output_paths <- vapply(
  unname(outputs), relative_descriptive_path, character(1), root = root
)
mockup_relative_path <- relative_descriptive_path(mockup_path, root)
producer <- paste0(
  "scripts/descriptives/",
  "run_descriptive_overview_export_scale_pilot.R"
)
for (changed_path in changed_paths) {
  relative_path <- relative_descriptive_path(changed_path, root)
  manifest_index <- which(manifest$path == relative_path)
  if (length(manifest_index) != 1L) {
    stop("A pilot output is absent from the descriptive manifest.", call. = FALSE)
  }
  manifest$sha256[[manifest_index]] <- artifact_sha256(changed_path)
  manifest$bytes[[manifest_index]] <- unname(file.info(changed_path)$size)
  manifest$producer[[manifest_index]] <- producer
  manifest$r_version[[manifest_index]] <- as.character(getRversion())
  if (relative_path %in% figure_output_paths) {
    manifest$figure_id[[manifest_index]] <- pilot_spec$figure_id[[1L]]
    manifest$width_in[[manifest_index]] <- pilot_spec$export_width_in[[1L]]
    manifest$height_in[[manifest_index]] <- pilot_spec$export_height_in[[1L]]
    manifest$dpi[[manifest_index]] <- if (
      identical(tools::file_ext(relative_path), "svg")
    ) {
      NA_integer_
    } else {
      pilot_spec$dpi[[1L]]
    }
  } else if (identical(relative_path, mockup_relative_path)) {
    manifest$figure_id[[manifest_index]] <- pilot_spec$figure_id[[1L]]
    manifest$width_in[[manifest_index]] <- 210 / 25.4
    manifest$height_in[[manifest_index]] <- 297 / 25.4
    manifest$dpi[[manifest_index]] <- pilot_spec$a4_mockup_dpi[[1L]]
  }
}
write_descriptive_csv(manifest, manifest_path)

cat(
  paste0(
    "Corrected Figure 1 pilot exported with literal ggsave scale 1.5.\n",
    "Base: 10.5 x 10 in; export: 15.75 x 15 in.\n",
    "PNG: ", pilot_dimensions[[1L]], " x ", pilot_dimensions[[2L]],
    " pixels at 300 dpi.\n",
    "QA status: ", pilot_spec$physical_size_qa[[1L]], "\n"
  )
)
