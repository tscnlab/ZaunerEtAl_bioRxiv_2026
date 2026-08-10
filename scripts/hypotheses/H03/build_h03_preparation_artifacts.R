#!/usr/bin/env Rscript

# Build lightweight descriptive source data for the H03 analysis-preparation
# companion from the frozen H03 model frames. This script does not fit,
# diagnose, compare, predict from, resample, or simulate a model.

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(tibble)
  library(tidyr)
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
      "The H03 preparation artifacts require R 4.6.1; found %s",
      getRversion()
    ),
    call. = FALSE
  )
}

producer <- paste0(
  "scripts/hypotheses/H03/",
  "build_h03_preparation_artifacts.R"
)
output_dir <- file.path(root, "artifacts/11_source_data/H03")
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

read_h03_csv <- function(relative_path) {
  readr::read_csv(file.path(root, relative_path), show_col_types = FALSE)
}

write_h03_csv <- function(data, filename) {
  write_csv_artifact(
    data,
    file.path(output_dir, filename),
    producer = producer
  )
}

archive_path <- file.path(
  root,
  "artifacts/06_model_data/H03/H03_model_frames.rds"
)
model_frames <- readRDS(archive_path)
stopifnot(
  identical(sort(names(model_frames)), sort(c(
    "main", "paired", "gap_timing_unaware", "boundary_excluded",
    "supported_cells_only"
  ))),
  identical(names(model_frames$main), c("near_eye", "chest"))
)

main_frames <- model_frames$main
placement_labels <- c(
  near_eye = "Near-eye",
  chest = "Chest"
)
required_columns <- c(
  "site", "Id", "local_date", "clock_minute", "valid_medi_wall_minutes",
  "metric_value_lx", "zero_offset", "participant", "participant_day",
  "light_source", "light_source_code", "source_flag_n", "placement",
  "outcome_available", "category_available", "model_candidate",
  "geo_medi_1h", "time_hour", "spans_diary_state_boundary",
  "spans_measurement_context_boundary", "AR_start", "ar_sequence"
)
stopifnot(all(vapply(
  main_frames,
  function(frame) all(required_columns %in% names(frame)),
  logical(1)
)))

frame_integrity <- bind_rows(lapply(names(main_frames), function(frame_id) {
  frame <- main_frames[[frame_id]]
  hour_keys <- frame |>
    distinct(.data$site, .data$Id, .data$local_date, .data$clock_minute) |>
    nrow()
  category_mapping_conflicts <- frame |>
    distinct(.data$light_source_code, .data$light_source) |>
    count(.data$light_source_code, name = "labels") |>
    filter(.data$labels != 1L) |>
    nrow()

  tibble(
    frame_id = frame_id,
    placement = unname(placement_labels[[frame_id]]),
    observations = nrow(frame),
    unique_hour_keys = hour_keys,
    duplicate_hour_keys = nrow(frame) - hour_keys,
    participants = n_distinct(frame$participant),
    participant_days = n_distinct(frame$participant_day),
    sites = n_distinct(frame$site),
    categories = n_distinct(frame$light_source_code),
    category_mapping_conflicts = category_mapping_conflicts,
    missing_outcome = sum(is.na(frame$geo_medi_1h)),
    missing_category = sum(is.na(frame$light_source_code)),
    model_candidate_false = sum(!frame$model_candidate),
    invalid_response = sum(
      !is.finite(frame$geo_medi_1h) | frame$geo_medi_1h < 0
    ),
    valid_wall_minutes_below_30 = sum(frame$valid_medi_wall_minutes < 30),
    source_flag_zero = sum(frame$source_flag_n == 0L),
    source_flag_one = sum(frame$source_flag_n == 1L),
    source_flag_multiple = sum(frame$source_flag_n > 1L),
    exact_zero_hours = sum(frame$geo_medi_1h == 0),
    positive_hours = sum(frame$geo_medi_1h > 0),
    diary_boundary_hours = sum(
      frame$spans_diary_state_boundary,
      na.rm = TRUE
    ),
    measurement_context_boundary_hours = sum(
      frame$spans_measurement_context_boundary,
      na.rm = TRUE
    ),
    either_boundary_hours = sum(
      frame$spans_diary_state_boundary |
        frame$spans_measurement_context_boundary,
      na.rm = TRUE
    ),
    ar_sequences = n_distinct(frame$ar_sequence),
    ar_sequence_starts = sum(frame$AR_start, na.rm = TRUE)
  )
})) |>
  arrange(match(.data$placement, c("Near-eye", "Chest")))

stopifnot(
  nrow(frame_integrity) == 2L,
  all(frame_integrity$observations == frame_integrity$unique_hour_keys),
  all(frame_integrity$duplicate_hour_keys == 0L),
  all(frame_integrity$category_mapping_conflicts == 0L),
  all(frame_integrity$missing_outcome == 0L),
  all(frame_integrity$missing_category == 0L),
  all(frame_integrity$model_candidate_false == 0L),
  all(frame_integrity$invalid_response == 0L),
  all(frame_integrity$valid_wall_minutes_below_30 == 0L),
  all(frame_integrity$source_flag_zero == 0L),
  all(frame_integrity$ar_sequences == frame_integrity$ar_sequence_starts),
  identical(frame_integrity$observations, c(17935L, 19512L)),
  identical(frame_integrity$participants, c(140L, 151L)),
  identical(frame_integrity$participant_days, c(801L, 880L)),
  identical(frame_integrity$sites, c(9L, 8L))
)
write_h03_csv(
  frame_integrity,
  "H03_preparation_frame_integrity.csv"
)

zero_summary <- bind_rows(lapply(names(main_frames), function(frame_id) {
  frame <- main_frames[[frame_id]]
  tibble(
    placement = unname(placement_labels[[frame_id]]),
    observations = nrow(frame),
    exact_zero_hours = sum(frame$geo_medi_1h == 0),
    positive_hours = sum(frame$geo_medi_1h > 0),
    exact_zero_fraction = mean(frame$geo_medi_1h == 0),
    positive_minimum_lx = min(frame$geo_medi_1h[frame$geo_medi_1h > 0]),
    positive_median_lx = stats::median(
      frame$geo_medi_1h[frame$geo_medi_1h > 0]
    ),
    positive_95th_percentile_lx = unname(stats::quantile(
      frame$geo_medi_1h[frame$geo_medi_1h > 0],
      0.95,
      names = FALSE
    )),
    maximum_lx = max(frame$geo_medi_1h),
    zeros_retained_in_models = TRUE
  )
})) |>
  arrange(match(.data$placement, c("Near-eye", "Chest")))
stopifnot(
  identical(zero_summary$exact_zero_hours, c(4977L, 5409L)),
  all(zero_summary$zeros_retained_in_models)
)
write_h03_csv(
  zero_summary,
  "H03_preparation_zero_summary.csv"
)

# Positive observations are binned only for the descriptive histogram. Exact
# zeros are recorded separately above and remained in every fitted model.
log_breaks <- seq(-5, 5, by = 0.25)
response_distribution <- bind_rows(lapply(names(main_frames), function(frame_id) {
  values <- main_frames[[frame_id]]$geo_medi_1h
  values <- values[is.finite(values) & values > 0]
  log_values <- log10(values)
  interval <- cut(
    log_values,
    breaks = log_breaks,
    include.lowest = TRUE,
    right = FALSE,
    labels = FALSE
  )
  stopifnot(!anyNA(interval))
  tibble(interval = interval) |>
    count(.data$interval, name = "positive_hours") |>
    complete(
      interval = seq_len(length(log_breaks) - 1L),
      fill = list(positive_hours = 0L)
    ) |>
    mutate(
      placement = unname(placement_labels[[frame_id]]),
      log10_lower = log_breaks[.data$interval],
      log10_upper = log_breaks[.data$interval + 1L],
      log10_midpoint = (.data$log10_lower + .data$log10_upper) / 2,
      mel_edi_lower_lx = 10^.data$log10_lower,
      mel_edi_upper_lx = 10^.data$log10_upper,
      mel_edi_midpoint_lx = 10^.data$log10_midpoint,
      .before = 1L
    )
})) |>
  arrange(match(.data$placement, c("Near-eye", "Chest")), .data$interval)
stopifnot(
  sum(response_distribution$positive_hours[
    response_distribution$placement == "Near-eye"
  ]) == zero_summary$positive_hours[zero_summary$placement == "Near-eye"],
  sum(response_distribution$positive_hours[
    response_distribution$placement == "Chest"
  ]) == zero_summary$positive_hours[zero_summary$placement == "Chest"]
)
write_h03_csv(
  response_distribution,
  "H03_preparation_positive_response_distribution.csv"
)

category_support <- read_h03_csv(
  "artifacts/06_model_data/H03/H03_category_support.csv"
) |>
  arrange(
    match(.data$placement, c("Near-eye", "Chest")),
    .data$category_order
  )
stopifnot(
  nrow(category_support) == 14L,
  all(category_support$hours > 0L),
  all(category_support$participants > 0L),
  all(category_support$participant_days > 0L),
  all(category_support$pooled_estimable)
)
write_h03_csv(
  category_support,
  "H03_preparation_category_support.csv"
)

site_category_support <- read_h03_csv(
  "artifacts/06_model_data/H03/H03_site_category_support.csv"
) |>
  mutate(
    support_status = case_when(
      !.data$site_present | .data$hours == 0L ~ "No observations",
      .data$supported ~ "Supported",
      TRUE ~ "Observed but sparse"
    )
  ) |>
  arrange(
    match(.data$placement, c("Near-eye", "Chest")),
    .data$display_order,
    .data$category_order
  )
stopifnot(
  nrow(site_category_support) == 126L,
  all(site_category_support$hours >= 0L),
  all(site_category_support$participants >= 0L),
  all(site_category_support$participant_days >= 0L),
  !anyNA(site_category_support$display_name),
  !anyNA(site_category_support$color_hex)
)
write_h03_csv(
  site_category_support,
  "H03_preparation_site_category_support.csv"
)

category_registry <- category_support |>
  distinct(
    .data$category_order,
    .data$category_code,
    .data$short_label,
    .data$light_source
  )
site_registry <- site_category_support |>
  distinct(
    .data$site,
    .data$display_order,
    site_display_name = .data$display_name,
    site_color_hex = .data$color_hex
  )

clock_support <- bind_rows(lapply(names(main_frames), function(frame_id) {
  frame <- main_frames[[frame_id]] |>
    mutate(
      site = as.character(.data$site),
      light_source_code = as.character(.data$light_source_code),
      local_hour = as.integer(.data$clock_minute / 60)
    )
  placement <- unname(placement_labels[[frame_id]])
  sites <- sort(unique(frame$site))

  frame |>
    group_by(.data$light_source_code, .data$local_hour) |>
    summarise(
      hours = n(),
      participants = n_distinct(.data$participant),
      participant_days = n_distinct(.data$participant_day),
      sites = n_distinct(.data$site),
      .groups = "drop"
    ) |>
    complete(
      light_source_code = category_registry$category_code,
      local_hour = 0:23,
      fill = list(
        hours = 0L,
        participants = 0L,
        participant_days = 0L,
        sites = 0L
      )
    ) |>
    left_join(
      category_registry,
      by = c("light_source_code" = "category_code"),
      relationship = "many-to-one"
    ) |>
    mutate(
      placement = placement,
      locally_sparse =
        .data$hours > 0L &
        (
          .data$hours < 20L |
            .data$participants < 5L |
            .data$sites < 3L
        ),
      support_status = case_when(
        .data$hours == 0L ~ "No observations",
        .data$locally_sparse ~ "Locally sparse",
        TRUE ~ "Supported"
      ),
      model_sites = length(sites),
      .before = 1L
    )
})) |>
  arrange(
    match(.data$placement, c("Near-eye", "Chest")),
    .data$category_order,
    .data$local_hour
  )
stopifnot(
  nrow(clock_support) == 2L * 7L * 24L,
  all(clock_support$hours >= 0L),
  all(clock_support$participants >= 0L),
  all(clock_support$participant_days >= 0L),
  all(clock_support$sites >= 0L),
  !anyNA(clock_support$category_order),
  !anyNA(clock_support$short_label)
)
write_h03_csv(
  clock_support,
  "H03_preparation_clock_category_support.csv"
)

participant_day_support <- bind_rows(lapply(names(main_frames), function(frame_id) {
  frame <- main_frames[[frame_id]]
  frame |>
    mutate(
      placement = unname(placement_labels[[frame_id]]),
      site = as.character(.data$site),
      participant = as.character(.data$participant),
      participant_day = as.character(.data$participant_day),
      light_source_code = as.character(.data$light_source_code)
    ) |>
    group_by(
      .data$placement,
      .data$site,
      .data$participant,
      .data$participant_day
    ) |>
    summarise(
      hours = n(),
      exact_zero_hours = sum(.data$geo_medi_1h == 0),
      categories = n_distinct(.data$light_source_code),
      ar_sequences = n_distinct(.data$ar_sequence),
      boundary_hours = sum(
        .data$spans_diary_state_boundary |
          .data$spans_measurement_context_boundary,
        na.rm = TRUE
      ),
      .groups = "drop"
    )
})) |>
  arrange(
    match(.data$placement, c("Near-eye", "Chest")),
    .data$site,
    .data$participant,
    .data$participant_day
  )
stopifnot(
  nrow(participant_day_support) == sum(frame_integrity$participant_days),
  sum(participant_day_support$hours) == sum(frame_integrity$observations),
  all(participant_day_support$hours > 0L),
  all(participant_day_support$ar_sequences > 0L)
)
write_h03_csv(
  participant_day_support,
  "H03_preparation_participant_day_support.csv"
)

message(
  "H03 preparation source data written: ",
  nrow(frame_integrity), " frames; ",
  nrow(category_support), " placement-category rows; ",
  nrow(site_category_support), " site-category rows; ",
  nrow(clock_support), " local-hour support rows"
)
