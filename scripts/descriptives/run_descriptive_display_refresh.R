# Display-only refresh from accepted descriptive CSV artifacts.
# This script deliberately does not import raw measurements or recompute
# descriptive metrics. It regenerates reader-facing tables/figures, their
# physical-size QA scaffolds, and matching manifest hashes.

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
source(file.path(root, "scripts", "descriptives", "build_descriptives.R"))
source_descriptive_modules(root)
check_descriptive_packages()
paths <- descriptive_paths(root)

metric_path <- file.path(
  paths$table_dir, "metric_descriptive_summary_replica.csv"
)
metric_before <- read_plot_source_csv(metric_path)
derived_metric_columns <- c(
  setdiff(names(replica_metric_contract()), "metric_id"),
  "reader_site", "median_formatted", "q1_formatted", "q3_formatted",
  "mean_formatted", "sd_formatted", "display"
)
metric_source <- metric_before |>
  dplyr::select(-dplyr::any_of(derived_metric_columns))
metric_after <- build_metric_replica(metric_source)

scientific_columns <- c(
  "n_possible_observations", "n_observations", "n_participants",
  "n_participant_days", "mean", "sd", "q1", "median", "q3",
  "circular_resultant"
)
before_order <- match(
  paste(metric_after$metric_id, metric_after$site),
  paste(metric_before$metric_id, metric_before$site)
)
if (anyNA(before_order) || !isTRUE(all.equal(
  metric_after[scientific_columns],
  metric_before[before_order, scientific_columns],
  tolerance = 0, check.attributes = FALSE
))) {
  stop("Display refresh changed a stored Table 2 scientific value", call. = FALSE)
}
write_descriptive_csv(metric_after, metric_path)

metric_values <- read_plot_source_csv(file.path(
  paths$source_dir, "metric_plot_values.csv"
))
metric_table <- build_metric_publication_gt(metric_after, metric_values)
metric_spec <- publication_table_export_spec() |>
  dplyr::filter(.data$table_id == "near_eye_metric_summary")
gt::gtsave(
  metric_table,
  filename = file.path(paths$table_dir, metric_spec$filename[[1L]]),
  vwidth = metric_spec$viewport_width_px[[1L]]
)

default_figure_ids <- c(
  "descriptive_overview", "near_eye_site_profiles", "chest_site_profiles",
  "near_eye_metric_distributions", "time_series_to_metrics"
)
requested_figure_ids <- Sys.getenv(
  "DESCRIPTIVE_REFRESH_FIGURE_IDS",
  unset = paste(default_figure_ids, collapse = ",")
)
refresh_figure_ids <- trimws(strsplit(
  requested_figure_ids, ",", fixed = TRUE
)[[1L]])
refresh_figure_ids <- refresh_figure_ids[nzchar(refresh_figure_ids)]
figure_build <- build_and_save_descriptive_figures(
  paths,
  figure_ids = refresh_figure_ids
)
write_descriptive_csv(
  figure_build$spec,
  file.path(paths$manifest_dir, "figure_specifications.csv")
)
write_descriptive_csv(
  figure_build$qa,
  file.path(paths$audit_dir, "figure_readability_qa.csv")
)
source_map <- descriptive_figure_source_map()
source_map_table <- dplyr::bind_rows(lapply(
  names(source_map),
  function(figure_id) {
    data.frame(
      figure_id = figure_id,
      source_data_path = file.path(
        "artifacts/11_source_data/descriptives",
        source_map[[figure_id]]
      ),
      stringsAsFactors = FALSE
    )
  }
)) |>
  dplyr::mutate(
    source_data_sha256 = vapply(
      file.path(root, .data$source_data_path),
      artifact_sha256,
      character(1)
    )
  )
write_descriptive_csv(
  source_map_table,
  file.path(paths$manifest_dir, "figure_source_data_map.csv")
)
visual_comparison <- build_visual_export_comparison(
  paths,
  list(spec = publication_table_export_spec()),
  figure_build
)
write_descriptive_csv(
  visual_comparison,
  file.path(paths$audit_dir, "visual_export_comparison.csv")
)

manifest_path <- file.path(paths$manifest_dir, "descriptive_artifacts.csv")
manifest <- read_plot_source_csv(manifest_path)
absolute_paths <- file.path(root, manifest$path)
if (any(!file.exists(absolute_paths))) {
  stop("A manifest path is missing during display refresh", call. = FALSE)
}
manifest$sha256 <- vapply(absolute_paths, artifact_sha256, character(1))
manifest$bytes <- as.numeric(file.info(absolute_paths)$size)
write_descriptive_csv(manifest, manifest_path)

message("Display-only descriptive refresh completed from stored CSV artifacts.")
