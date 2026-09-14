#!/usr/bin/env Rscript

# Build lightweight descriptive source data for the H04 analysis-preparation
# companion from the frozen H04 model frames. This script does not fit,
# diagnose, compare, predict from, resample, or simulate a model.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
project_library <- file.path(
  root,
  "renv/library/macos/R-4.6/aarch64-apple-darwin23"
)
if (!dir.exists(project_library)) {
  stop("The synchronized project library is missing", call. = FALSE)
}
.libPaths(c(project_library, .libPaths()))

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(tibble)
  library(tidyr)
})

source(file.path(root, "scripts/pipeline/paths_io.R"))
source(file.path(root, "scripts/hypotheses/H04/h04_stage1_support.R"))

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop(
    sprintf(
      "The H04 preparation artifacts require R 4.6.1; found %s",
      getRversion()
    ),
    call. = FALSE
  )
}

producer <- paste0(
  "scripts/hypotheses/H04/",
  "build_h04_preparation_artifacts.R"
)
output_dir <- file.path(root, "artifacts/11_source_data/H04")
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

read_h04_csv <- function(relative_path) {
  readr::read_csv(file.path(root, relative_path), show_col_types = FALSE)
}

write_h04_csv <- function(data, filename) {
  write_csv_artifact(
    data,
    file.path(output_dir, filename),
    producer = producer
  )
}

archive_path <- file.path(
  root,
  "artifacts/06_model_data/H04/H04_model_frames.rds"
)
model_frames <- readRDS(archive_path)
expected_scenarios <- c(
  "main",
  "paired",
  "exactly_one",
  "retain_coselected_other",
  "exclude_other_only",
  "unweighted_long",
  "gap_timing_unaware"
)
stopifnot(
  identical(sort(names(model_frames)), sort(expected_scenarios)),
  identical(names(model_frames$main), c("near_eye", "chest"))
)

main_frames <- model_frames$main
placement_labels <- c(
  near_eye = "Near-eye",
  chest = "Chest"
)
required_columns <- c(
  "site",
  "Id",
  "local_date",
  "clock_minute",
  "valid_medi_wall_minutes",
  "participant",
  "participant_day",
  "interval_start_utc",
  "other_selected",
  "other_coselected",
  "k",
  "model_hour_candidate",
  "geo_medi_1h",
  "time_hour",
  "analysis_hour_id",
  "activity_code",
  "activity_label",
  "analysis_weight",
  "k_from_long"
)
stopifnot(all(vapply(
  main_frames,
  function(frame) all(required_columns %in% names(frame)),
  logical(1)
)))

frame_integrity <- bind_rows(lapply(names(main_frames), function(frame_id) {
  frame <- main_frames[[frame_id]]
  hour_check <- frame |>
    group_by(.data$analysis_hour_id) |>
    summarise(
      rows = n(),
      distinct_labels = n_distinct(.data$activity_code),
      recorded_k = first(.data$k),
      recorded_k_from_long = first(.data$k_from_long),
      weight_sum = sum(.data$analysis_weight),
      outcomes = n_distinct(.data$geo_medi_1h),
      participants = n_distinct(.data$participant),
      participant_days = n_distinct(.data$participant_day),
      .groups = "drop"
    )
  hour_values <- frame |>
    distinct(
      .data$analysis_hour_id,
      .data$geo_medi_1h,
      .data$valid_medi_wall_minutes,
      .data$k,
      .keep_all = TRUE
    )
  duplicate_hour_activity_memberships <- nrow(frame) - nrow(
    distinct(frame, .data$analysis_hour_id, .data$activity_code)
  )

  tibble(
    frame_id = frame_id,
    placement = unname(placement_labels[[frame_id]]),
    long_rows = nrow(frame),
    unique_participant_hours = nrow(hour_check),
    effective_weighted_hours = sum(frame$analysis_weight),
    participants = n_distinct(frame$participant),
    participant_days = n_distinct(frame$participant_day),
    sites = n_distinct(frame$site),
    categories = n_distinct(frame$activity_code),
    duplicate_hour_activity_memberships =
      duplicate_hour_activity_memberships,
    missing_outcome_rows = sum(is.na(frame$geo_medi_1h)),
    missing_activity_rows = sum(is.na(frame$activity_code)),
    invalid_response_rows = sum(
      !is.finite(frame$geo_medi_1h) | frame$geo_medi_1h < 0
    ),
    invalid_weight_rows = sum(
      !is.finite(frame$analysis_weight) | frame$analysis_weight <= 0
    ),
    noncandidate_rows = sum(!frame$model_hour_candidate),
    hour_response_conflicts = sum(hour_check$outcomes != 1L),
    hour_participant_conflicts = sum(hour_check$participants != 1L),
    hour_day_conflicts = sum(hour_check$participant_days != 1L),
    row_k_mismatches = sum(hour_check$rows != hour_check$recorded_k),
    distinct_label_mismatches = sum(
      hour_check$rows != hour_check$distinct_labels
    ),
    long_k_mismatches = sum(
      hour_check$recorded_k != hour_check$recorded_k_from_long
    ),
    maximum_weight_sum_error = max(abs(hour_check$weight_sum - 1)),
    co_selected_other_suppressed_hours = n_distinct(
      frame$analysis_hour_id[frame$other_coselected %in% TRUE]
    ),
    co_selected_other_retained_rows = sum(
      frame$other_coselected %in% TRUE & frame$activity_code == "other"
    ),
    other_only_hours = n_distinct(
      frame$analysis_hour_id[frame$activity_code == "other"]
    ),
    exact_zero_unique_hours = sum(hour_values$geo_medi_1h == 0),
    positive_unique_hours = sum(hour_values$geo_medi_1h > 0),
    valid_wall_minutes_below_30 = sum(
      hour_values$valid_medi_wall_minutes < 30
    )
  )
})) |>
  arrange(match(.data$placement, c("Near-eye", "Chest")))

stopifnot(
  nrow(frame_integrity) == 2L,
  identical(frame_integrity$long_rows, c(17266L, 21071L)),
  identical(
    frame_integrity$unique_participant_hours,
    c(16526L, 20128L)
  ),
  identical(frame_integrity$participants, c(126L, 150L)),
  identical(frame_integrity$participant_days, c(724L, 875L)),
  identical(frame_integrity$sites, c(9L, 8L)),
  identical(frame_integrity$categories, c(6L, 6L)),
  all(abs(
    frame_integrity$effective_weighted_hours -
      frame_integrity$unique_participant_hours
  ) < 1e-10),
  all(frame_integrity$duplicate_hour_activity_memberships == 0L),
  all(frame_integrity$missing_outcome_rows == 0L),
  all(frame_integrity$missing_activity_rows == 0L),
  all(frame_integrity$invalid_response_rows == 0L),
  all(frame_integrity$invalid_weight_rows == 0L),
  all(frame_integrity$noncandidate_rows == 0L),
  all(frame_integrity$hour_response_conflicts == 0L),
  all(frame_integrity$hour_participant_conflicts == 0L),
  all(frame_integrity$hour_day_conflicts == 0L),
  all(frame_integrity$row_k_mismatches == 0L),
  all(frame_integrity$distinct_label_mismatches == 0L),
  all(frame_integrity$long_k_mismatches == 0L),
  all(frame_integrity$maximum_weight_sum_error < 1e-12),
  all(frame_integrity$co_selected_other_retained_rows == 0L),
  all(frame_integrity$valid_wall_minutes_below_30 == 0L)
)
write_h04_csv(
  frame_integrity,
  "H04_preparation_frame_integrity.csv"
)

zero_summary <- bind_rows(lapply(names(main_frames), function(frame_id) {
  hour <- main_frames[[frame_id]] |>
    distinct(.data$analysis_hour_id, .data$geo_medi_1h)
  positive <- hour$geo_medi_1h[hour$geo_medi_1h > 0]
  tibble(
    placement = unname(placement_labels[[frame_id]]),
    unique_participant_hours = nrow(hour),
    exact_zero_unique_hours = sum(hour$geo_medi_1h == 0),
    positive_unique_hours = sum(hour$geo_medi_1h > 0),
    exact_zero_fraction = mean(hour$geo_medi_1h == 0),
    positive_minimum_lx = min(positive),
    positive_median_lx = median(positive),
    positive_95th_percentile_lx = unname(quantile(
      positive,
      0.95,
      names = FALSE
    )),
    maximum_lx = max(hour$geo_medi_1h),
    zeros_retained_in_models = TRUE
  )
})) |>
  arrange(match(.data$placement, c("Near-eye", "Chest")))
stopifnot(
  identical(zero_summary$exact_zero_unique_hours, c(4784L, 5923L)),
  all(zero_summary$zeros_retained_in_models)
)
write_h04_csv(
  zero_summary,
  "H04_preparation_zero_summary.csv"
)

# Positive responses are binned for display with their accepted 1/k weights.
# Every original participant-hour occupies one response bin, so weighted bin
# totals sum to the number of positive unique participant-hours.
log_breaks <- seq(-5, 5, by = 0.25)
response_distribution <- bind_rows(lapply(names(main_frames), function(frame_id) {
  frame <- main_frames[[frame_id]] |>
    filter(is.finite(.data$geo_medi_1h), .data$geo_medi_1h > 0) |>
    mutate(
      log10_value = log10(.data$geo_medi_1h),
      interval = cut(
        .data$log10_value,
        breaks = log_breaks,
        include.lowest = TRUE,
        right = FALSE,
        labels = FALSE
      )
    )
  stopifnot(!anyNA(frame$interval))
  frame |>
    group_by(.data$interval) |>
    summarise(
      long_rows = n(),
      unique_participant_hours = n_distinct(.data$analysis_hour_id),
      effective_weighted_hours = sum(.data$analysis_weight),
      .groups = "drop"
    ) |>
    complete(
      interval = seq_len(length(log_breaks) - 1L),
      fill = list(
        long_rows = 0L,
        unique_participant_hours = 0L,
        effective_weighted_hours = 0
      )
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
  nrow(response_distribution) == 80L,
  all(abs(
    response_distribution |>
      group_by(.data$placement) |>
      summarise(value = sum(.data$effective_weighted_hours), .groups = "drop") |>
      arrange(match(.data$placement, c("Near-eye", "Chest"))) |>
      pull(.data$value) -
      zero_summary$positive_unique_hours
  ) < 1e-8)
)
write_h04_csv(
  response_distribution,
  "H04_preparation_positive_response_distribution.csv"
)

reader_order <- c(
  home = 1L,
  working_indoor = 2L,
  outdoors = 3L,
  road_vehicle = 4L,
  sleeping = 5L,
  other = 6L
)
reader_labels <- c(
  home = "At home",
  working_indoor = "Office/home working",
  outdoors = "Outdoors",
  road_vehicle = "Vehicle/public transport",
  sleeping = "Sleeping",
  other = "Other"
)

category_support <- read_h04_csv(
  "artifacts/06_model_data/H04/H04_category_support.csv"
) |>
  mutate(
    reader_order = unname(reader_order[.data$activity_code]),
    short_label = unname(reader_labels[.data$activity_code])
  ) |>
  arrange(
    match(.data$placement, c("Near-eye", "Chest")),
    .data$reader_order
  )
stopifnot(
  nrow(category_support) == 12L,
  !anyNA(category_support$reader_order),
  all(category_support$unique_participant_hours > 0L),
  all(category_support$effective_weighted_hours > 0)
)
write_h04_csv(
  category_support,
  "H04_preparation_category_support.csv"
)

site_category_support <- read_h04_csv(
  "artifacts/06_model_data/H04/H04_site_category_support.csv"
) |>
  mutate(
    support_status = case_when(
      .data$unique_hours == 0L ~ "No observations",
      .data$support_rule ~ "Supported",
      TRUE ~ "Observed but sparse"
    ),
    reader_order = unname(reader_order[.data$activity_code]),
    short_label = unname(reader_labels[.data$activity_code])
  ) |>
  arrange(
    match(.data$placement, c("Near-eye", "Chest")),
    .data$display_order.y,
    .data$reader_order
  )
stopifnot(
  nrow(site_category_support) == 102L,
  sum(site_category_support$support_status == "Supported") == 98L,
  sum(site_category_support$support_status == "Observed but sparse") == 4L,
  sum(site_category_support$support_status == "No observations") == 0L,
  !anyNA(site_category_support$display_name),
  !anyNA(site_category_support$color_hex)
)
write_h04_csv(
  site_category_support,
  "H04_preparation_site_category_support.csv"
)

activity_registry <- h04_activity_registry() |>
  transmute(
    activity_code = .data$activity_code,
    activity_label = .data$activity_label,
    reader_order = unname(reader_order[.data$activity_code]),
    short_label = unname(reader_labels[.data$activity_code])
  )
clock_support <- bind_rows(lapply(names(main_frames), function(frame_id) {
  frame <- main_frames[[frame_id]] |>
    mutate(clock_hour = floor(.data$time_hour) %% 24L)
  frame |>
    group_by(.data$activity_code, .data$clock_hour) |>
    summarise(
      unique_participant_hours = n_distinct(.data$analysis_hour_id),
      long_rows = n(),
      effective_weighted_hours = sum(.data$analysis_weight),
      participants = n_distinct(.data$participant),
      participant_days = n_distinct(.data$participant_day),
      sites = n_distinct(.data$site),
      .groups = "drop"
    ) |>
    complete(
      activity_code = activity_registry$activity_code,
      clock_hour = 0:23,
      fill = list(
        unique_participant_hours = 0L,
        long_rows = 0L,
        effective_weighted_hours = 0,
        participants = 0L,
        participant_days = 0L,
        sites = 0L
      )
    ) |>
    left_join(activity_registry, by = "activity_code") |>
    mutate(
      placement = unname(placement_labels[[frame_id]]),
      locally_sparse = .data$unique_participant_hours > 0L &
        (
          .data$unique_participant_hours < 20L |
            .data$participants < 5L
        ),
      support_status = case_when(
        .data$unique_participant_hours == 0L ~ "No observations",
        .data$locally_sparse ~ "Locally sparse",
        TRUE ~ "Supported"
      ),
      .before = 1L
    )
})) |>
  arrange(
    match(.data$placement, c("Near-eye", "Chest")),
    .data$reader_order,
    .data$clock_hour
  )
stopifnot(
  nrow(clock_support) == 2L * 6L * 24L,
  all(clock_support$clock_hour %in% 0:23),
  all(clock_support$effective_weighted_hours >= 0),
  !anyNA(clock_support$reader_order)
)
write_h04_csv(
  clock_support,
  "H04_preparation_clock_category_support.csv"
)

participant_day_support <- bind_rows(lapply(names(main_frames), function(frame_id) {
  main_frames[[frame_id]] |>
    mutate(
      placement = unname(placement_labels[[frame_id]]),
      site = as.character(.data$site),
      participant = as.character(.data$participant),
      participant_day = as.character(.data$participant_day)
    ) |>
    group_by(
      .data$placement,
      .data$site,
      .data$participant,
      .data$participant_day
    ) |>
    summarise(
      unique_participant_hours = n_distinct(.data$analysis_hour_id),
      long_rows = n(),
      effective_weighted_hours = sum(.data$analysis_weight),
      categories = n_distinct(.data$activity_code),
      multiselect_hours = n_distinct(
        .data$analysis_hour_id[.data$k > 1L]
      ),
      maximum_k = max(.data$k),
      exact_zero_unique_hours = n_distinct(
        .data$analysis_hour_id[.data$geo_medi_1h == 0]
      ),
      other_only_hours = n_distinct(
        .data$analysis_hour_id[.data$activity_code == "other"]
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
  sum(participant_day_support$unique_participant_hours) ==
    sum(frame_integrity$unique_participant_hours),
  all(abs(
    participant_day_support$effective_weighted_hours -
      participant_day_support$unique_participant_hours
  ) < 1e-10),
  all(participant_day_support$unique_participant_hours > 0L),
  all(participant_day_support$maximum_k >= 1L)
)
write_h04_csv(
  participant_day_support,
  "H04_preparation_participant_day_support.csv"
)

message(
  "H04 preparation source data written: ",
  nrow(frame_integrity), " frames; ",
  nrow(category_support), " placement-category rows; ",
  nrow(site_category_support), " site-category rows; ",
  nrow(clock_support), " local-hour support rows; ",
  nrow(participant_day_support), " participant-day rows"
)
