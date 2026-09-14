# Targeted Figure 4 source refresh from the pinned submitted V0 dataset.
# This script does not rebuild any other descriptive source or fit a model.

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
source(file.path(root, "scripts", "descriptives", "build_descriptives.R"))
source_descriptive_modules(root)
check_descriptive_packages()
paths <- descriptive_paths(root)

existing_metrics_path <- file.path(
  paths$source_dir, "time_series_replica_metrics.csv"
)
existing_metrics <- read_plot_source_csv(existing_metrics_path)
time_series <- build_time_series_replica_sources(root)

metric_key <- c("participant", "protocol_day")
metric_columns <- c(
  metric_key, "duration_above_250_daytime_h", "finite_daytime_samples",
  "samples_above_250"
)
old_metrics <- existing_metrics |>
  dplyr::select(dplyr::all_of(metric_columns)) |>
  dplyr::arrange(.data$participant, .data$protocol_day)
new_metrics <- time_series$metrics |>
  dplyr::select(dplyr::all_of(metric_columns)) |>
  dplyr::arrange(.data$participant, .data$protocol_day)
if (!isTRUE(all.equal(
  old_metrics, new_metrics, tolerance = 0, check.attributes = FALSE
))) {
  stop(
    "The targeted Figure 4 context repair changed a stored TAT250 value",
    call. = FALSE
  )
}
if (
  nrow(time_series$selected) != 35L ||
  nrow(time_series$series) != 1680L ||
  nrow(time_series$states) != 70L ||
  nrow(time_series$metrics) != 35L ||
  !identical(
    time_series$provenance$source_sha256,
    gap_timing_unaware_near_eye_contract(root)$expected_sha256
  )
) {
  stop("The targeted Figure 4 source contract failed", call. = FALSE)
}

outputs <- list(
  "time_series_replica_selection.csv" = time_series$selected,
  "time_series_replica_30_minute.csv" = time_series$series,
  "time_series_replica_states.csv" = time_series$states,
  "time_series_replica_metrics.csv" = time_series$metrics,
  "gap_timing_unaware_source_provenance.csv" = time_series$provenance
)
invisible(lapply(names(outputs), function(filename) {
  write_descriptive_csv(outputs[[filename]], file.path(paths$source_dir, filename))
}))

alt_path <- file.path(paths$source_dir, "figure_alt_text.csv")
alt_text <- read_plot_source_csv(alt_path)
alt_row <- match("time_series_to_metrics", alt_text$figure_id)
if (is.na(alt_row)) {
  stop("Figure 4 is absent from the stored alt-text source", call. = FALSE)
}
time_series_alt <- build_time_series_replica_alt_text(time_series)
alt_text$short_alt_text[[alt_row]] <- time_series_alt$short
alt_text$long_description[[alt_row]] <- time_series_alt$long
write_descriptive_csv(alt_text, alt_path)

message(
  "Figure 4 sources refreshed from the pinned V0 data: 35 days, 1,680 ",
  "stored bins, 70 dawn/dusk context intervals, unchanged TAT250 values."
)
