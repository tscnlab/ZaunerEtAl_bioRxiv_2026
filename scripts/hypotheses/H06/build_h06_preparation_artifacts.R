#!/usr/bin/env Rscript

# Build lightweight descriptive source data for the H06 analysis-preparation
# companion from frozen H06 model frames and contracts. This script does not
# fit, refit, diagnose, compare, predict from, resample, or simulate a model.

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
source(file.path(root, "scripts/hypotheses/H06/h06_contract.R"))

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop(
    sprintf(
      "The H06 preparation artifacts require R 4.6.1; found %s",
      getRversion()
    ),
    call. = FALSE
  )
}

producer <- paste0(
  "scripts/hypotheses/H06/",
  "build_h06_preparation_artifacts.R"
)
output_dir <- file.path(root, "artifacts/11_source_data/H06")
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

read_h06_csv <- function(relative_path) {
  readr::read_csv(file.path(root, relative_path), show_col_types = FALSE)
}

write_h06_csv <- function(data, filename) {
  write_csv_artifact(
    data,
    file.path(output_dir, filename),
    producer = producer
  )
}

frame_registry <- tibble::tribble(
  ~run_id, ~relative_path, ~placement, ~data_scenario, ~sample_scenario,
  "main__glasses__all_available",
  "artifacts/06_model_data/H06/main__glasses__all_available__frame.rds",
  "Near-eye", "Primary dataset", "All available",
  "main__chest__all_available",
  "artifacts/06_model_data/H06/main__chest__all_available__frame.rds",
  "Chest", "Primary dataset", "All available",
  "main__glasses__paired_common",
  "artifacts/06_model_data/H06/main__glasses__paired_common__frame.rds",
  "Near-eye", "Primary dataset", "Paired days",
  "main__chest__paired_common",
  "artifacts/06_model_data/H06/main__chest__paired_common__frame.rds",
  "Chest", "Primary dataset", "Paired days",
  "gap_timing_unaware__glasses__all_available",
  paste0(
    "artifacts/06_model_data/H06/",
    "gap_timing_unaware__glasses__all_available__frame.rds"
  ),
  "Near-eye", "Gap-timing-unaware dataset", "All available",
  "gap_timing_unaware__chest__all_available",
  paste0(
    "artifacts/06_model_data/H06/",
    "gap_timing_unaware__chest__all_available__frame.rds"
  ),
  "Chest", "Gap-timing-unaware dataset", "All available"
) |>
  mutate(
    path = file.path(root, .data$relative_path),
    run_order = dplyr::row_number()
  )

if (any(!file.exists(frame_registry$path))) {
  stop("One or more frozen H06 frames are missing", call. = FALSE)
}

frames <- lapply(frame_registry$path, readRDS)
names(frames) <- frame_registry$run_id
invariance_relative <- paste0(
  "artifacts/08_diagnostics/mder_METRIC-010/downstream_rebuild/",
  "h06_hourly_frame_invariance.csv"
)
invariance <- read_h06_csv(invariance_relative)
stopifnot(
  nrow(invariance) == 6L,
  all(invariance$exact_frame_match)
)
required_columns <- c(
  "site", "Id", "local_date", "clock_minute", "response_value",
  "work_free_day", "activity_status",
  "previous_sleep_duration_h", "previous_sleep_duration_centered_h",
  "participant_key", "participant_day_key", "hour_sequence_id",
  "AR_start", "interval_seconds", "irregular_elapsed_bin",
  ".model_row_id"
)
stopifnot(all(vapply(
  frames,
  function(frame) all(required_columns %in% names(frame)),
  logical(1)
)))

frame_integrity <- bind_rows(lapply(seq_len(nrow(frame_registry)), function(i) {
  frame <- frames[[frame_registry$run_id[[i]]]]
  day_hours <- frame |>
    count(.data$participant_day_key, name = "supported_hours")
  unique_hour_keys <- frame |>
    distinct(.data$site, .data$Id, .data$local_date, .data$clock_minute) |>
    nrow()

  tibble(
    run_id = frame_registry$run_id[[i]],
    placement = frame_registry$placement[[i]],
    data_scenario = frame_registry$data_scenario[[i]],
    sample_scenario = frame_registry$sample_scenario[[i]],
    observations = nrow(frame),
    unique_hour_keys = unique_hour_keys,
    duplicate_hour_keys = nrow(frame) - unique_hour_keys,
    participants = n_distinct(frame$participant_key),
    participant_days = n_distinct(frame$participant_day_key),
    sites = n_distinct(frame$site),
    exact_zero_hours = sum(frame$response_value == 0),
    positive_hours = sum(frame$response_value > 0),
    missing_outcome = sum(is.na(frame$response_value)),
    missing_site = sum(is.na(frame$site)),
    missing_day_type = sum(is.na(frame$work_free_day)),
    missing_activity = sum(is.na(frame$activity_status)),
    missing_previous_sleep = sum(
      is.na(frame$previous_sleep_duration_centered_h)
    ),
    invalid_response = sum(
      !is.finite(frame$response_value) | frame$response_value < 0
    ),
    minimum_supported_hours_per_day = min(day_hours$supported_hours),
    median_supported_hours_per_day = median(day_hours$supported_hours),
    maximum_supported_hours_per_day = max(day_hours$supported_hours),
    true_time_sequences = n_distinct(frame$hour_sequence_id),
    sequence_starts = sum(frame$AR_start),
    irregular_elapsed_bins = sum(frame$irregular_elapsed_bin),
    non_3600_second_rows = sum(frame$interval_seconds != 3600),
    frame_sha256 = artifact_sha256(frame_registry$path[[i]])
  )
})) |>
  arrange(match(.data$run_id, frame_registry$run_id))

expected_samples <- read_h06_csv(
  "artifacts/06_model_data/H06/H06_exact_samples.csv"
) |>
  select(
    .data$run_id,
    expected_observations = .data$one_hour_observations,
    expected_participant_days = .data$participant_days,
    expected_participants = .data$participants,
    expected_sites = .data$sites,
    accepted_stage2_frame_sha256 = .data$frame_sha256
  )
frame_integrity <- frame_integrity |>
  left_join(expected_samples, by = "run_id", relationship = "one-to-one") |>
  left_join(
    invariance |>
      select(
        .data$run_id,
        .data$exact_frame_match,
        current_invariance_frame_sha256 = .data$frozen_frame_sha256
      ),
    by = "run_id",
    relationship = "one-to-one"
  ) |>
  mutate(
    accepted_identity_match =
      .data$observations == .data$expected_observations &
      .data$participant_days == .data$expected_participant_days &
      .data$participants == .data$expected_participants &
      .data$sites == .data$expected_sites &
      .data$exact_frame_match &
      .data$frame_sha256 == .data$current_invariance_frame_sha256,
    provenance_only_file_reseal =
      .data$accepted_stage2_frame_sha256 !=
      .data$current_invariance_frame_sha256
  )

stopifnot(
  nrow(frame_integrity) == 6L,
  all(frame_integrity$duplicate_hour_keys == 0L),
  all(frame_integrity$missing_outcome == 0L),
  all(frame_integrity$missing_site == 0L),
  all(frame_integrity$missing_day_type == 0L),
  all(frame_integrity$missing_activity == 0L),
  all(frame_integrity$missing_previous_sleep == 0L),
  all(frame_integrity$invalid_response == 0L),
  all(frame_integrity$true_time_sequences == frame_integrity$sequence_starts),
  all(frame_integrity$accepted_identity_match)
)
write_h06_csv(
  frame_integrity,
  "H06_preparation_frame_integrity.csv"
)

main_run_ids <- c(
  "main__glasses__all_available",
  "main__chest__all_available"
)
main_frames <- frames[main_run_ids]
main_placements <- c(
  "main__glasses__all_available" = "Near-eye",
  "main__chest__all_available" = "Chest"
)

response_distribution <- bind_rows(lapply(main_run_ids, function(run_id) {
  frame <- main_frames[[run_id]]
  positive <- frame$response_value[frame$response_value > 0]
  quantiles <- stats::quantile(
    positive,
    probs = c(0.10, 0.25, 0.50, 0.75, 0.90, 0.99),
    names = FALSE
  )
  tibble(
    run_id = run_id,
    placement = unname(main_placements[[run_id]]),
    observations = nrow(frame),
    exact_zero_hours = sum(frame$response_value == 0),
    exact_zero_fraction = mean(frame$response_value == 0),
    positive_hours = length(positive),
    positive_minimum_lx = min(positive),
    positive_p10_lx = quantiles[[1L]],
    positive_p25_lx = quantiles[[2L]],
    positive_median_lx = quantiles[[3L]],
    positive_p75_lx = quantiles[[4L]],
    positive_p90_lx = quantiles[[5L]],
    positive_p99_lx = quantiles[[6L]],
    maximum_lx = max(frame$response_value),
    zeros_retained_in_models = TRUE,
    display_transform =
      "LightLogR::symlog_trans(base = 10, thr = 1, scale = 1)"
  )
})) |>
  arrange(match(.data$placement, c("Near-eye", "Chest")))
stopifnot(
  nrow(response_distribution) == 2L,
  all(response_distribution$positive_hours > 0L),
  all(response_distribution$exact_zero_hours > 0L),
  all(response_distribution$zeros_retained_in_models)
)
write_h06_csv(
  response_distribution,
  "H06_preparation_response_distribution.csv"
)

site_registry <- read_h06_csv("config/site_display_registry.csv")
day_levels <- c("Work day", "Free day")
activity_levels <- c(
  "Sedentary (no reported exercise)",
  "Active (light, moderate, or vigorous exercise)"
)
activity_labels <- c(
  "Sedentary (no reported exercise)" = "Sedentary",
  "Active (light, moderate, or vigorous exercise)" = "Active"
)

site_day_activity_support <- bind_rows(lapply(main_run_ids, function(run_id) {
  frame <- main_frames[[run_id]] |>
    mutate(
      site = as.character(.data$site),
      work_free_day = as.character(.data$work_free_day),
      activity_status = as.character(.data$activity_status)
    )
  sites <- sort(unique(frame$site))
  placement <- unname(main_placements[[run_id]])

  frame |>
    group_by(.data$site, .data$work_free_day, .data$activity_status) |>
    summarise(
      hours = n(),
      participants = n_distinct(.data$participant_key),
      participant_days = n_distinct(.data$participant_day_key),
      exact_zero_hours = sum(.data$response_value == 0),
      .groups = "drop"
    ) |>
    complete(
      site = sites,
      work_free_day = day_levels,
      activity_status = activity_levels,
      fill = list(
        hours = 0L,
        participants = 0L,
        participant_days = 0L,
        exact_zero_hours = 0L
      )
    ) |>
    left_join(site_registry, by = "site", relationship = "many-to-one") |>
    mutate(
      placement = placement,
      activity_label = unname(activity_labels[.data$activity_status]),
      joint_group = paste(.data$work_free_day, .data$activity_label, sep = " · "),
      joint_order = match(
        .data$joint_group,
        c(
          "Work day · Sedentary", "Work day · Active",
          "Free day · Sedentary", "Free day · Active"
        )
      ),
      support_status = case_when(
        .data$hours == 0L ~ "No observations",
        .data$participants < 4L | .data$participant_days < 8L ~
          "Observed but sparse",
        TRUE ~ "Supported"
      ),
      .before = 1L
    )
})) |>
  arrange(
    match(.data$placement, c("Near-eye", "Chest")),
    .data$display_order,
    .data$joint_order
  )
stopifnot(
  nrow(site_day_activity_support) == 68L,
  all(site_day_activity_support$hours >= 0L),
  all(site_day_activity_support$participants >= 0L),
  all(site_day_activity_support$participant_days >= 0L),
  !anyNA(site_day_activity_support$display_name),
  !anyNA(site_day_activity_support$color_hex),
  !anyNA(site_day_activity_support$joint_order)
)
write_h06_csv(
  site_day_activity_support,
  "H06_preparation_site_day_activity_support.csv"
)

clock_day_activity_support <- bind_rows(lapply(main_run_ids, function(run_id) {
  frame <- main_frames[[run_id]] |>
    mutate(
      work_free_day = as.character(.data$work_free_day),
      activity_status = as.character(.data$activity_status),
      local_hour = as.integer(.data$clock_minute / 60)
    )
  placement <- unname(main_placements[[run_id]])

  frame |>
    group_by(
      .data$work_free_day,
      .data$activity_status,
      .data$local_hour
    ) |>
    summarise(
      hours = n(),
      participants = n_distinct(.data$participant_key),
      participant_days = n_distinct(.data$participant_day_key),
      sites = n_distinct(.data$site),
      .groups = "drop"
    ) |>
    complete(
      work_free_day = day_levels,
      activity_status = activity_levels,
      local_hour = 0:23,
      fill = list(
        hours = 0L,
        participants = 0L,
        participant_days = 0L,
        sites = 0L
      )
    ) |>
    mutate(
      placement = placement,
      activity_label = unname(activity_labels[.data$activity_status]),
      joint_group = paste(.data$work_free_day, .data$activity_label, sep = " · "),
      joint_order = match(
        .data$joint_group,
        c(
          "Work day · Sedentary", "Work day · Active",
          "Free day · Sedentary", "Free day · Active"
        )
      ),
      .before = 1L
    )
})) |>
  arrange(
    match(.data$placement, c("Near-eye", "Chest")),
    .data$joint_order,
    .data$local_hour
  )
stopifnot(
  nrow(clock_day_activity_support) == 192L,
  identical(sort(unique(clock_day_activity_support$local_hour)), 0:23),
  all(clock_day_activity_support$hours >= 0L),
  all(clock_day_activity_support$participants >= 0L),
  all(clock_day_activity_support$participant_days >= 0L),
  all(clock_day_activity_support$sites >= 0L)
)
write_h06_csv(
  clock_day_activity_support,
  "H06_preparation_clock_day_activity_support.csv"
)

participant_day_support <- bind_rows(lapply(main_run_ids, function(run_id) {
  frame <- main_frames[[run_id]] |>
    mutate(
      placement = unname(main_placements[[run_id]]),
      site = as.character(.data$site),
      participant = as.character(.data$participant_key),
      participant_day = as.character(.data$participant_day_key),
      work_free_day = as.character(.data$work_free_day),
      activity_status = as.character(.data$activity_status)
    )

  frame |>
    group_by(
      .data$placement,
      .data$site,
      .data$participant,
      .data$participant_day,
      .data$local_date,
      .data$work_free_day,
      .data$activity_status
    ) |>
    summarise(
      supported_hours = n(),
      exact_zero_hours = sum(.data$response_value == 0),
      previous_sleep_duration_h = first(.data$previous_sleep_duration_h),
      previous_sleep_duration_centered_h = first(
        .data$previous_sleep_duration_centered_h
      ),
      true_time_sequences = n_distinct(.data$hour_sequence_id),
      irregular_elapsed_bins = sum(.data$irregular_elapsed_bin),
      .groups = "drop"
    )
})) |>
  arrange(
    match(.data$placement, c("Near-eye", "Chest")),
    .data$site,
    .data$participant,
    .data$local_date
  )
stopifnot(
  nrow(participant_day_support) == 715L + 789L,
  sum(participant_day_support$supported_hours) == 16596L + 18352L,
  all(participant_day_support$supported_hours >= 19L),
  all(participant_day_support$supported_hours <= 24L),
  max(abs(
    participant_day_support$previous_sleep_duration_centered_h -
      (participant_day_support$previous_sleep_duration_h - 8)
  )) == 0
)
write_h06_csv(
  participant_day_support,
  "H06_preparation_participant_day_support.csv"
)

scientific_input_roles <- c(
  "primary_near_eye_hourly",
  "complementary_chest_hourly",
  "gap_timing_unaware_hourly",
  "normalized_exercise_diary",
  "normalized_sleep_diary",
  "temporal_provenance",
  "site_display_registry",
  "model_input_source_pins",
  "current_base_model_manifest",
  "stage4_gate_decision"
)
input_provenance <- h06_input_contract(root) |>
  filter(.data$input_role %in% scientific_input_roles) |>
  rowwise() |>
  mutate(
    observed_sha256 = artifact_sha256(.data$path),
    hash_verified = identical(.data$observed_sha256, .data$expected_sha256)
  ) |>
  ungroup() |>
  select(
    .data$input_role,
    .data$relative_path,
    .data$expected_sha256,
    .data$observed_sha256,
    .data$hash_verified
  )
stopifnot(
  nrow(input_provenance) == length(scientific_input_roles),
  all(input_provenance$hash_verified)
)
write_h06_csv(
  input_provenance,
  "H06_preparation_input_provenance.csv"
)

base_manifest_relative <-
  "artifacts/12_manifests/base_model_data_artifacts.csv"
base_manifest <- read_h06_csv(base_manifest_relative)
base_bundle_values <- unique(base_manifest$input_bundle_sha256)
stopifnot(
  length(base_bundle_values) == 1L,
  identical(base_bundle_values, h06_base_input_bundle_sha256()),
  all(base_manifest$status == "PASS")
)
shared_provenance <- tibble::tribble(
  ~record, ~relative_path, ~pinned_identity, ~observed_identity, ~status,
  "Base-model manifest",
  base_manifest_relative,
  "b6fa22836faee5243bb6ce1cc9dceab5d5403f94d688f8f74472a19dbf6e3e09",
  artifact_sha256(file.path(root, base_manifest_relative)),
  "PASS",
  "Base-model input bundle",
  base_manifest_relative,
  h06_base_input_bundle_sha256(),
  base_bundle_values,
  "PASS",
  "Exact six-frame hourly invariance evidence",
  invariance_relative,
  "75794d5dc13392a05cd81ac57456bd03ccc5f12713f8f774db72f2bfab44de4f",
  artifact_sha256(file.path(root, invariance_relative)),
  "PASS"
)
stopifnot(all(shared_provenance$pinned_identity == shared_provenance$observed_identity))
write_h06_csv(
  shared_provenance,
  "H06_preparation_shared_provenance.csv"
)

source_pins <- read_h06_csv("config/model_input_source_pins.csv")
diary_source_pin <- source_pins |>
  filter(.data$site == "TUM", .data$modality == "exercisediary") |>
  mutate(
    melidosData_release = "1.0.6",
    normalized_s001_rows = 7L,
    normalized_s101_rows = 0L,
    local_identifier_rewrite = FALSE
  )
stopifnot(
  nrow(diary_source_pin) == 1L,
  diary_source_pin$commit ==
    "618fda8521f3cf581661ceb2c026e3de7cd9ba82",
  diary_source_pin$doi == "10.5281/zenodo.16893901",
  diary_source_pin$expected_sha256 ==
    "0db56324e9826d427c42984fdfc43eb1e7487211365f222a1c0b2ecff618f1ef",
  diary_source_pin$normalized_s001_rows == 7L,
  diary_source_pin$normalized_s101_rows == 0L,
  !diary_source_pin$local_identifier_rewrite
)
write_h06_csv(
  diary_source_pin,
  "H06_preparation_exercise_diary_source_pin.csv"
)

message(
  "H06 preparation source data written: ",
  nrow(frame_integrity), " frozen frames; ",
  nrow(site_day_activity_support), " site-by-day-type/activity rows; ",
  nrow(clock_day_activity_support), " local-hour support rows; ",
  nrow(participant_day_support), " participant-day rows"
)
