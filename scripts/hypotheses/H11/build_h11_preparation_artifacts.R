#!/usr/bin/env Rscript

# Build bounded descriptive and display artifacts for the H11 analysis-
# preparation companion from frozen model frames. This script does not fit,
# diagnose, compare, predict from, resample, or simulate a model.

suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
  library(LightLogR)
  library(patchwork)
  library(png)
  library(readr)
  library(scales)
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
    paste0(
      "H11 preparation artifacts require R 4.6.1; found ",
      as.character(getRversion())
    ),
    call. = FALSE
  )
}

producer <- paste0(
  "scripts/hypotheses/H11/",
  "build_h11_preparation_artifacts.R"
)
source_data_dir <- file.path(
  root,
  "artifacts/11_source_data/H11/preparation"
)
figure_dir <- file.path(root, "artifacts/10_figures/H11/preparation")
manifest_dir <- file.path(root, "artifacts/12_manifests/H11")
dir.create(source_data_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(manifest_dir, recursive = TRUE, showWarnings = FALSE)

read_h11_csv <- function(relative_path) {
  path <- file.path(root, relative_path)
  if (!file.exists(path)) {
    stop("Missing H11 preparation input: ", relative_path, call. = FALSE)
  }
  readr::read_csv(path, show_col_types = FALSE)
}

write_h11_csv <- function(data, filename) {
  write_csv_artifact(
    data,
    file.path(source_data_dir, filename),
    producer = producer
  )
}

stage2_manifest <- read_h11_csv(
  "artifacts/12_manifests/H11/H11_stage2_output_hashes.csv"
)
activity_manifest <- read_h11_csv(
  "artifacts/12_manifests/H11/H11_activity_context_output_hashes.csv"
)
stage2_samples <- read_h11_csv(
  "artifacts/09_tables/H11/stage2/sample_counts.csv"
)
activity_samples <- read_h11_csv(
  paste0(
    "artifacts/09_tables/H11/activity_context/",
    "activity_common_sample_counts.csv"
  )
)
site_registry <- read_h11_csv("config/site_display_registry.csv") |>
  arrange(.data$display_order)

frame_registry <- tibble::tribble(
  ~analysis_order, ~run_id, ~analysis_label, ~placement, ~placement_label,
  ~data_role, ~frame_kind, ~relative_path, ~manifest_kind,
  1L, "main__glasses__all_available", "Primary near eye", "glasses",
  "Near eye", "Primary", "accepted",
  "artifacts/06_model_data/H11/stage2/main__glasses__all_available__frame.rds",
  "stage2",
  2L, "main__chest__all_available", "Complementary chest", "chest",
  "Chest", "Complementary", "accepted",
  "artifacts/06_model_data/H11/stage2/main__chest__all_available__frame.rds",
  "stage2",
  3L, "manuscript_prepared_data__glasses__all_available",
  "Gap-timing-unaware near eye", "glasses", "Near eye", "Sensitivity",
  "accepted",
  paste0(
    "artifacts/06_model_data/H11/stage2/",
    "manuscript_prepared_data__glasses__all_available__frame.rds"
  ),
  "stage2",
  4L, "manuscript_prepared_data__chest__all_available",
  "Gap-timing-unaware chest", "chest", "Chest", "Sensitivity", "accepted",
  paste0(
    "artifacts/06_model_data/H11/stage2/",
    "manuscript_prepared_data__chest__all_available__frame.rds"
  ),
  "stage2",
  5L, "activity_context__glasses", "Activity-complete near eye", "glasses",
  "Near eye", "Exploratory sensitivity", "activity",
  paste0(
    "artifacts/06_model_data/H11/activity_context/",
    "activity_context__glasses__frame.rds"
  ),
  "activity",
  6L, "activity_context__chest", "Activity-complete chest", "chest",
  "Chest", "Exploratory sensitivity", "activity",
  paste0(
    "artifacts/06_model_data/H11/activity_context/",
    "activity_context__chest__frame.rds"
  ),
  "activity"
)

expected_file_hash <- function(relative_path, manifest_kind) {
  if (identical(manifest_kind, "stage2")) {
    match <- stage2_manifest |>
      filter(.data$path == .env$relative_path)
  } else {
    match <- activity_manifest |>
      filter(.data$relative_path == .env$relative_path)
  }
  if (nrow(match) != 1L) {
    stop("No unique manifest identity for ", relative_path, call. = FALSE)
  }
  match$sha256[[1L]]
}

frames <- setNames(
  lapply(frame_registry$relative_path, function(relative_path) {
    readRDS(file.path(root, relative_path))
  }),
  frame_registry$run_id
)

sample_reference <- bind_rows(
  stage2_samples |>
    select(
      "run_id", "participants", "female_participants",
      "male_participants", "participant_days",
      "female_participant_days", "male_participant_days",
      "observations_30_minute", "nominal_observation_hours",
      "female_observations_30_minute", "male_observations_30_minute",
      "sites", "AR_sequences"
    ),
  activity_samples |>
    select(
      "run_id", "participants", "female_participants",
      "male_participants", "participant_days",
      "female_participant_days", "male_participant_days",
      "observations_30_minute", "nominal_observation_hours",
      "female_observations_30_minute", "male_observations_30_minute",
      "sites", "AR_sequences"
    )
)

frame_integrity_rows <- lapply(
  seq_len(nrow(frame_registry)),
  function(index) {
    registry_row <- frame_registry[index, , drop = FALSE]
    data <- frames[[registry_row$run_id]]
    activity_frame <- identical(registry_row$frame_kind, "activity")
    gap_timing_unaware_frame <- identical(
      registry_row$data_role,
      "Sensitivity"
    )
    required_columns <- c(
      "site", "Id", "local_date", "clock_bin", "metric_value_lx",
      "valid_medi_wall_minutes", "support_available", "bin_admissible",
      "AR_start",
      "participant_key", "participant_day_key", "time_hour", "response",
      "biological_sex", "sex"
    )
    if (activity_frame) {
      required_columns <- c(
        required_columns,
        "activity", "activity_smooth", "activity_AR_start_reason",
        "activity_true_elapsed_sequence_id"
      )
      boundary_reason <- data$activity_AR_start_reason
      sequence_id <- data$activity_true_elapsed_sequence_id
    } else {
      required_columns <- c(
        required_columns,
        "ar_start_reason", "true_elapsed_sequence_id"
      )
      boundary_reason <- data$ar_start_reason
      sequence_id <- data$true_elapsed_sequence_id
    }
    reference <- sample_reference |>
      filter(.data$run_id == registry_row$run_id)
    if (nrow(reference) != 1L) {
      stop(
        "No unique stored sample reference for ",
        registry_row$run_id,
        call. = FALSE
      )
    }

    observed_participants <- n_distinct(data$participant_key)
    observed_days <- n_distinct(data$participant_day_key)
    observed_sites <- n_distinct(data$site)
    observed_sequences <- n_distinct(sequence_id)
    response_error <- max(
      abs(data$response - log10(data$metric_value_lx + 0.1))
    )
    expected_hash <- expected_file_hash(
      registry_row$relative_path,
      registry_row$manifest_kind
    )
    current_hash <- artifact_sha256(
      file.path(root, registry_row$relative_path)
    )
    day_bins <- data |>
      count(.data$participant_day_key, name = "clock_bins")
    boundary_matches <- all(
      data$AR_start == (boundary_reason != "continuous")
    )
    biological_sex_matches <- all(
      as.character(data$sex) == as.character(data$biological_sex)
    )
    count_matches <- nrow(data) == reference$observations_30_minute &&
      observed_participants == reference$participants &&
      observed_days == reference$participant_days &&
      observed_sites == reference$sites &&
      observed_sequences == reference$AR_sequences
    schema_complete <- all(required_columns %in% names(data))
    unique_row_key <- !anyDuplicated(
      data[c("participant_day_key", "clock_bin")]
    )
    complete_clock_grid <- identical(
      sort(unique(data$time_hour)),
      seq(0.25, 23.75, by = 0.5)
    )
    values_valid <- all(
      is.finite(data$metric_value_lx) & data$metric_value_lx >= 0
    )
    support_valid <- if (gap_timing_unaware_frame) {
      all(data$bin_admissible) &&
        all(!data$support_available) &&
        all(is.na(data$valid_medi_wall_minutes))
    } else {
      all(data$bin_admissible) &&
        all(data$support_available) &&
        all(!is.na(data$valid_medi_wall_minutes)) &&
        min(data$valid_medi_wall_minutes) >= 15L &&
        max(data$valid_medi_wall_minutes) <= 30L
    }
    minimum_valid_minutes <- if (
      all(is.na(data$valid_medi_wall_minutes))
    ) {
      NA_integer_
    } else {
      min(data$valid_medi_wall_minutes, na.rm = TRUE)
    }
    maximum_valid_minutes <- if (
      all(is.na(data$valid_medi_wall_minutes))
    ) {
      NA_integer_
    } else {
      max(data$valid_medi_wall_minutes, na.rm = TRUE)
    }
    overall <- all(c(
      identical(current_hash, expected_hash),
      count_matches,
      schema_complete,
      unique_row_key,
      complete_clock_grid,
      values_valid,
      biological_sex_matches,
      response_error == 0,
      support_valid,
      boundary_matches
    ))

    tibble::tibble(
      analysis_order = registry_row$analysis_order,
      run_id = registry_row$run_id,
      analysis_label = registry_row$analysis_label,
      placement_label = registry_row$placement_label,
      frame_kind = registry_row$frame_kind,
      relative_path = registry_row$relative_path,
      expected_file_sha256 = expected_hash,
      current_file_sha256 = current_hash,
      file_identity = if_else(current_hash == expected_hash, "PASS", "FAIL"),
      participants = observed_participants,
      participant_days = observed_days,
      observations_30_minute = nrow(data),
      sites = observed_sites,
      AR_sequences = observed_sequences,
      schema_complete = schema_complete,
      duplicate_row_keys = sum(duplicated(
        data[c("participant_day_key", "clock_bin")]
      )),
      complete_48_bin_clock_grid = complete_clock_grid,
      minimum_bins_per_participant_day = min(day_bins$clock_bins),
      complete_48_bin_participant_days = sum(day_bins$clock_bins == 48L),
      minimum_valid_minutes_per_30_minute_bin =
        minimum_valid_minutes,
      maximum_valid_minutes_per_30_minute_bin =
        maximum_valid_minutes,
      metric_specific_gap_timing_field = if_else(
        gap_timing_unaware_frame,
        "Intentionally not used",
        "Available and checked"
      ),
      exact_zero_observations = sum(data$metric_value_lx == 0),
      response_reconstruction_maximum_absolute_error = response_error,
      biological_sex_encoding_matches = biological_sex_matches,
      AR_start_matches_boundary_reason = boundary_matches,
      stored_sample_counts_match = count_matches,
      overall_status = if_else(overall, "PASS", "FAIL")
    )
  }
)
frame_integrity <- bind_rows(frame_integrity_rows) |>
  arrange(.data$analysis_order)
if (nrow(frame_integrity) != 6L || any(frame_integrity$overall_status != "PASS")) {
  print(
    frame_integrity |>
      filter(.data$overall_status != "PASS"),
    width = Inf
  )
  stop("One or more frozen H11 frames failed integrity checks", call. = FALSE)
}
write_h11_csv(
  frame_integrity,
  "H11_preparation_frame_integrity.csv"
)

sample_support <- frame_registry |>
  select(
    "analysis_order", "run_id", "analysis_label", "placement",
    "placement_label", "data_role", "frame_kind"
  ) |>
  left_join(sample_reference, by = "run_id", relationship = "one-to-one") |>
  arrange(.data$analysis_order)

stopifnot(
  identical(sample_support$participants, c(141, 154, 141, 154, 126, 150)),
  identical(sample_support$participant_days, c(816, 902, 809, 894, 724, 875)),
  identical(
    sample_support$observations_30_minute,
    c(37756, 41842, 37603, 41664, 30499, 36711)
  )
)
write_h11_csv(sample_support, "H11_preparation_sample_support.csv")

upstream <- read_h11_csv(
  "artifacts/06_model_data/H11/stage2/upstream_reconciliation.csv"
)
important_input_paths <- c(
  "preregistration/AsPredicted #273407.pdf",
  "audit/evidence/preregistration_contract.md",
  "artifacts/07_models/H02/selected_temporal_model_specification.csv",
  "artifacts/06_model_data/normalized_inputs/demographics.rds",
  "config/site_display_registry.csv",
  "artifacts/06_model_data/H02/main__glasses__all_available.rds",
  "artifacts/06_model_data/H02/main__chest__all_available.rds",
  paste0(
    "artifacts/06_model_data/H02/",
    "manuscript_prepared_data__glasses__all_available.rds"
  ),
  paste0(
    "artifacts/06_model_data/H02/",
    "manuscript_prepared_data__chest__all_available.rds"
  )
)
input_labels <- stats::setNames(
  c(
    "Signed preregistration",
    "Extracted H11 contract",
    "Final H02 temporal specification",
    "Biological-sex metadata",
    "Submitted-manuscript site registry",
    "Primary H02 near-eye frame",
    "Primary H02 chest frame",
    "Gap-timing-unaware H02 near-eye frame",
    "Gap-timing-unaware H02 chest frame"
  ),
  important_input_paths
)
input_candidates <- upstream |>
  filter(.data$relative_path %in% important_input_paths)
input_candidate_consistency <- input_candidates |>
  group_by(.data$relative_path) |>
  summarise(
    expected_hashes = n_distinct(.data$expected_sha256),
    current_hashes = n_distinct(.data$current_sha256),
    all_acceptable = all(.data$acceptable_for_stage2),
    .groups = "drop"
  )
stopifnot(
  nrow(input_candidate_consistency) == length(important_input_paths),
  all(input_candidate_consistency$expected_hashes == 1L),
  all(input_candidate_consistency$current_hashes == 1L),
  all(input_candidate_consistency$all_acceptable)
)
input_identities <- input_candidates |>
  distinct(.data$relative_path, .keep_all = TRUE) |>
  mutate(
    input = unname(input_labels[.data$relative_path]),
    current_sha256 = vapply(
      file.path(root, .data$relative_path),
      artifact_sha256,
      character(1)
    ),
    verification = if_else(
      .data$current_sha256 == .data$expected_sha256 &
        .data$acceptable_for_stage2,
      "PASS",
      "FAIL"
    )
  ) |>
  select(
    "input", "relative_path", "expected_sha256", "current_sha256",
    "verification"
  )

activity_provenance <- read_h11_csv(
  "artifacts/06_model_data/H11/activity_context/input_provenance.csv"
) |>
  filter(
    .data$relative_path ==
      "artifacts/06_model_data/normalized_inputs/lightexposurediary.rds"
  )
stopifnot(nrow(activity_provenance) == 1L)
activity_diary_identity <- activity_provenance |>
  transmute(
    input = "Normalised hourly activity diary",
    relative_path = .data$relative_path,
    expected_sha256 = .data$sha256,
    current_sha256 = vapply(
      file.path(root, .data$relative_path),
      artifact_sha256,
      character(1)
    ),
    verification = if_else(
      .data$current_sha256 == .data$expected_sha256,
      "PASS",
      "FAIL"
    )
  )
input_identities <- bind_rows(input_identities, activity_diary_identity) |>
  arrange(match(.data$relative_path, c(
    important_input_paths,
    activity_diary_identity$relative_path
  )))
stopifnot(
  nrow(input_identities) == 10L,
  !anyDuplicated(input_identities$relative_path),
  all(input_identities$verification == "PASS")
)
write_h11_csv(input_identities, "H11_preparation_input_identities.csv")

primary_registry <- frame_registry |>
  filter(.data$run_id %in% c(
    "main__glasses__all_available",
    "main__chest__all_available"
  ))

site_sex_rows <- lapply(seq_len(nrow(primary_registry)), function(index) {
  registry_row <- primary_registry[index, , drop = FALSE]
  data <- frames[[registry_row$run_id]]
  data |>
    mutate(
      site = as.character(.data$site),
      sex = as.character(.data$sex)
    ) |>
    group_by(.data$site, .data$sex) |>
    summarise(
      participants = n_distinct(.data$participant_key),
      participant_days = n_distinct(.data$participant_day_key),
      observations_30_minute = n(),
      nominal_observation_hours = n() / 2,
      .groups = "drop"
    ) |>
    mutate(
      analysis_order = registry_row$analysis_order,
      run_id = registry_row$run_id,
      placement = registry_row$placement,
      placement_label = registry_row$placement_label,
      .before = 1L
    )
})
site_sex_support <- bind_rows(site_sex_rows) |>
  left_join(
    site_registry,
    by = "site",
    relationship = "many-to-one"
  ) |>
  arrange(.data$analysis_order, .data$display_order, .data$sex) |>
  select(
    "analysis_order", "run_id", "placement", "placement_label",
    "display_order", "site", site_name = "display_name",
    site_color = "color_hex", "sex", "participants", "participant_days",
    "observations_30_minute", "nominal_observation_hours"
  )
stopifnot(
  nrow(site_sex_support) == 34L,
  !anyNA(site_sex_support$site_name),
  all(site_sex_support$participants > 0L)
)
write_h11_csv(
  site_sex_support,
  "H11_preparation_site_sex_support.csv"
)

distribution_rows <- lapply(seq_len(nrow(primary_registry)), function(index) {
  registry_row <- primary_registry[index, , drop = FALSE]
  data <- frames[[registry_row$run_id]] |>
    mutate(sex = as.character(.data$sex))
  data |>
    group_by(.data$sex) |>
    summarise(
      observations = n(),
      exact_zeros = sum(.data$metric_value_lx == 0),
      exact_zero_percent = 100 * mean(.data$metric_value_lx == 0),
      positive_observations = sum(.data$metric_value_lx > 0),
      positive_p10_melEDI_lx = as.numeric(stats::quantile(
        .data$metric_value_lx[.data$metric_value_lx > 0],
        0.10
      )),
      positive_p25_melEDI_lx = as.numeric(stats::quantile(
        .data$metric_value_lx[.data$metric_value_lx > 0],
        0.25
      )),
      positive_median_melEDI_lx = stats::median(
        .data$metric_value_lx[.data$metric_value_lx > 0]
      ),
      positive_p75_melEDI_lx = as.numeric(stats::quantile(
        .data$metric_value_lx[.data$metric_value_lx > 0],
        0.75
      )),
      positive_p90_melEDI_lx = as.numeric(stats::quantile(
        .data$metric_value_lx[.data$metric_value_lx > 0],
        0.90
      )),
      positive_p99_melEDI_lx = as.numeric(stats::quantile(
        .data$metric_value_lx[.data$metric_value_lx > 0],
        0.99
      )),
      maximum_melEDI_lx = max(.data$metric_value_lx),
      .groups = "drop"
    ) |>
    mutate(
      analysis_order = registry_row$analysis_order,
      run_id = registry_row$run_id,
      placement = registry_row$placement,
      placement_label = registry_row$placement_label,
      .before = 1L
    )
})
melEDI_distribution <- bind_rows(distribution_rows) |>
  arrange(.data$analysis_order, .data$sex)
stopifnot(
  nrow(melEDI_distribution) == 4L,
  all(melEDI_distribution$exact_zeros > 0L),
  all(melEDI_distribution$positive_p10_melEDI_lx > 0),
  all(melEDI_distribution$positive_p99_melEDI_lx < 20000)
)
write_h11_csv(
  melEDI_distribution,
  "H11_preparation_melEDI_distribution.csv"
)

boundary_labels <- c(
  participant_day_start = "Participant-day start",
  elapsed_discontinuity = "Elapsed-time discontinuity",
  non_one_to_one_wall_outcome = "Non-one-to-one wall-clock outcome",
  after_non_one_to_one_wall_outcome =
    "First observation after a non-one-to-one wall-clock outcome",
  participant_day_activity_start =
    "First retained activity-complete observation of participant-day",
  inherited_true_time_boundary = "Inherited true-time boundary",
  activity_filter_gap = "Gap created by activity eligibility filtering",
  continuous = "Continuous with preceding observation"
)
boundary_rows <- lapply(seq_len(nrow(frame_registry)), function(index) {
  registry_row <- frame_registry[index, , drop = FALSE]
  data <- frames[[registry_row$run_id]]
  reason <- if (identical(registry_row$frame_kind, "activity")) {
    data$activity_AR_start_reason
  } else {
    data$ar_start_reason
  }
  tibble::tibble(boundary_reason_id = as.character(reason)) |>
    count(.data$boundary_reason_id, name = "observations") |>
    mutate(
      percent_of_frame = 100 * .data$observations / nrow(data),
      boundary_reason = unname(
        boundary_labels[.data$boundary_reason_id]
      ),
      analysis_order = registry_row$analysis_order,
      run_id = registry_row$run_id,
      analysis_label = registry_row$analysis_label,
      placement_label = registry_row$placement_label,
      frame_kind = registry_row$frame_kind,
      .before = 1L
    )
})
boundary_support <- bind_rows(boundary_rows) |>
  arrange(.data$analysis_order, desc(.data$observations))
stopifnot(!anyNA(boundary_support$boundary_reason))
write_h11_csv(
  boundary_support,
  "H11_preparation_AR_boundary_support.csv"
)

activity_status_labels <- c(
  retained_v0_five_level_activity =
    "Retained: one eligible mapped activity",
  no_matching_diary_hour = "No unique containing diary hour",
  all_flags_missing = "All activity flags missing",
  observed_zero_selected = "No activity selected",
  multiple_selected = "Multiple activities selected",
  exactly_one_other_excluded = "Only unspecified other selected"
)
activity_status_order <- c(
  "retained_v0_five_level_activity",
  "no_matching_diary_hour",
  "all_flags_missing",
  "observed_zero_selected",
  "multiple_selected",
  "exactly_one_other_excluded"
)
activity_attrition <- read_h11_csv(
  "artifacts/06_model_data/H11/activity_context/activity_join_attrition.csv"
) |>
  mutate(
    placement_label = recode(
      .data$placement,
      glasses = "Near eye",
      chest = "Chest"
    ),
    status_order = match(.data$activity_join_status, activity_status_order),
    status_label = unname(
      activity_status_labels[.data$activity_join_status]
    )
  ) |>
  arrange(.data$status_order, .data$placement_label) |>
  select(
    "run_id", "placement", "placement_label", "status_order",
    status_id = "activity_join_status", "status_label",
    "observations_30_minute", "percent_of_original_frame"
  )
stopifnot(
  nrow(activity_attrition) == 12L,
  !anyNA(activity_attrition$status_label),
  all(abs(
    activity_attrition |>
      group_by(.data$placement) |>
      summarise(total = sum(.data$percent_of_original_frame)) |>
      pull(.data$total) - 100
  ) < 1e-8)
)
write_h11_csv(
  activity_attrition,
  "H11_preparation_activity_attrition.csv"
)

environment <- tibble::tibble(
  component = c(
    "R", "Quarto", "dplyr", "readr", "ggplot2", "gt", "mgcv",
    "LightLogR", "patchwork"
  ),
  version = c(
    as.character(getRversion()),
    system2("quarto", "--version", stdout = TRUE, stderr = TRUE)[[1L]],
    vapply(
      c(
        "dplyr", "readr", "ggplot2", "gt", "mgcv", "LightLogR",
        "patchwork"
      ),
      function(package) as.character(utils::packageVersion(package)),
      character(1)
    )
  ),
  role = c(
    "Authoritative scientific computation and report rendering",
    "HTML report rendering",
    "Data manipulation",
    "Typed CSV input and output",
    "Reader figures",
    "Reader tables",
    "Stored GAM/BAM fits",
    "Approved melEDI symlog display transform",
    "Multi-panel figure composition"
  )
)
write_h11_csv(environment, "H11_preparation_environment.csv")

figure_spec <- list(
  intended_width_mm = 170,
  base_width_in = 8.5,
  export_scale_multiplier = 1,
  smallest_central_nominal_text_pt = 12,
  smallest_essential_nominal_text_pt = 10,
  smallest_minor_nominal_text_pt = 9,
  raster_dpi = 300,
  a4_width_mm = 210,
  a4_height_mm = 297,
  a4_side_margin_mm = 20
)
figure_spec$export_width_in <-
  figure_spec$base_width_in * figure_spec$export_scale_multiplier
figure_spec$export_width_mm <- figure_spec$export_width_in * 25.4
figure_spec$display_reduction_factor <-
  figure_spec$intended_width_mm / figure_spec$export_width_mm
figure_spec$effective_final_central_text_pt <-
  figure_spec$smallest_central_nominal_text_pt *
  figure_spec$display_reduction_factor
figure_spec$effective_final_essential_text_pt <-
  figure_spec$smallest_essential_nominal_text_pt *
  figure_spec$display_reduction_factor
figure_spec$effective_final_minor_text_pt <-
  figure_spec$smallest_minor_nominal_text_pt *
  figure_spec$display_reduction_factor

stopifnot(
  figure_spec$effective_final_central_text_pt >= 7,
  figure_spec$effective_final_essential_text_pt >= 7,
  figure_spec$effective_final_minor_text_pt >= 5,
  identical(
    LightLogR::symlog_trans(base = 10, thr = 1, scale = 1)$name,
    "symlog-1-10-1"
  )
)

sex_palette <- c(Female = "#CC79A7", Male = "#0072B2")
placement_palette <- c("Near eye" = "#0072B2", Chest = "#D55E00")

theme_h11_preparation <- function() {
  cowplot::theme_cowplot(font_size = 12) +
    ggplot2::theme(
      panel.grid.minor = ggplot2::element_blank(),
      panel.grid.major = ggplot2::element_line(
        colour = "grey88",
        linewidth = 0.35
      ),
      legend.position = "top",
      legend.title = ggplot2::element_blank(),
      legend.text = ggplot2::element_text(size = 10),
      axis.title = ggplot2::element_text(size = 12),
      axis.text = ggplot2::element_text(size = 10),
      strip.text = ggplot2::element_text(size = 11, face = "bold"),
      plot.title = ggplot2::element_text(
        size = 12,
        face = "bold",
        lineheight = 1.05
      ),
      plot.tag = ggplot2::element_text(size = 13, face = "bold"),
      plot.margin = ggplot2::margin(8, 12, 8, 8)
    )
}

site_levels <- site_registry$display_name
site_colors <- stats::setNames(
  site_registry$color_hex,
  site_registry$display_name
)
site_plot_data <- site_sex_support |>
  mutate(
    site_name = factor(.data$site_name, levels = rev(site_levels)),
    placement_label = factor(
      .data$placement_label,
      levels = c("Near eye", "Chest")
    ),
    sex = factor(.data$sex, levels = c("Female", "Male"))
  )
site_support_plot <- ggplot2::ggplot(
  site_plot_data,
  ggplot2::aes(
    x = .data$participants,
    y = .data$site_name,
    colour = .data$site_name,
    group = interaction(.data$placement_label, .data$site_name)
  )
) +
  ggplot2::geom_line(linewidth = 1.1, alpha = 0.72) +
  ggplot2::geom_point(
    ggplot2::aes(shape = .data$sex),
    size = 3.3,
    stroke = 1
  ) +
  ggplot2::facet_wrap(
    ggplot2::vars(.data$placement_label),
    nrow = 1,
    drop = FALSE
  ) +
  ggplot2::scale_colour_manual(values = site_colors, guide = "none") +
  ggplot2::scale_shape_manual(
    values = c(Female = 16, Male = 17),
    drop = FALSE
  ) +
  ggplot2::scale_x_continuous(
    breaks = scales::breaks_pretty(n = 6),
    expand = ggplot2::expansion(mult = c(0.04, 0.10))
  ) +
  ggplot2::labs(
    x = "Participants in fitted frame",
    y = NULL,
    shape = "Recorded biological sex"
  ) +
  theme_h11_preparation()

distribution_plot_data <- melEDI_distribution |>
  mutate(
    placement_label = factor(
      .data$placement_label,
      levels = c("Near eye", "Chest")
    ),
    sex = factor(.data$sex, levels = c("Female", "Male"))
  )
positive_distribution_panel <- ggplot2::ggplot(
  distribution_plot_data,
  ggplot2::aes(y = .data$sex, colour = .data$sex)
) +
  ggplot2::geom_segment(
    ggplot2::aes(
      x = .data$positive_p10_melEDI_lx,
      xend = .data$positive_p90_melEDI_lx,
      yend = .data$sex
    ),
    linewidth = 1.2
  ) +
  ggplot2::geom_segment(
    ggplot2::aes(
      x = .data$positive_p25_melEDI_lx,
      xend = .data$positive_p75_melEDI_lx,
      yend = .data$sex
    ),
    linewidth = 4.2,
    lineend = "round"
  ) +
  ggplot2::geom_point(
    ggplot2::aes(x = .data$positive_median_melEDI_lx),
    size = 3.4
  ) +
  ggplot2::geom_point(
    ggplot2::aes(x = .data$positive_p99_melEDI_lx),
    shape = 1,
    size = 3.2,
    stroke = 1
  ) +
  ggplot2::facet_wrap(
    ggplot2::vars(.data$placement_label),
    nrow = 1
  ) +
  ggplot2::scale_colour_manual(values = sex_palette, guide = "none") +
  ggplot2::scale_x_continuous(
    trans = LightLogR::symlog_trans(base = 10, thr = 1, scale = 1),
    breaks = c(0, 1, 10, 250, 1000, 10000),
    labels = scales::label_number(big.mark = ","),
    limits = c(0, 20000),
    expand = ggplot2::expansion(mult = c(0, 0.02))
  ) +
  ggplot2::labs(
    title = "A  Positive melEDI observations",
    x = "melEDI (lx; symlog scale)",
    y = NULL
  ) +
  theme_h11_preparation()

zero_distribution_panel <- ggplot2::ggplot(
  distribution_plot_data,
  ggplot2::aes(
    x = .data$sex,
    y = .data$exact_zero_percent,
    fill = .data$sex
  )
) +
  ggplot2::geom_col(width = 0.62) +
  ggplot2::geom_text(
    ggplot2::aes(
      label = paste0(sprintf("%.1f", .data$exact_zero_percent), "%")
    ),
    vjust = -0.35,
    size = 3.5
  ) +
  ggplot2::facet_wrap(
    ggplot2::vars(.data$placement_label),
    nrow = 1
  ) +
  ggplot2::scale_fill_manual(values = sex_palette, guide = "none") +
  ggplot2::scale_y_continuous(
    labels = function(value) paste0(value, "%"),
    limits = c(0, 40),
    breaks = seq(0, 40, by = 10),
    expand = c(0, 0)
  ) +
  ggplot2::labs(
    title = "B  Exact-zero observations retained in the models",
    x = "Recorded biological sex",
    y = "Share of fitted observations"
  ) +
  theme_h11_preparation()

melEDI_distribution_plot <-
  positive_distribution_panel / zero_distribution_panel +
  patchwork::plot_layout(heights = c(1.35, 1))

activity_plot_data <- activity_attrition |>
  mutate(
    status_label = factor(
      .data$status_label,
      levels = rev(unname(activity_status_labels[activity_status_order]))
    ),
    placement_label = factor(
      .data$placement_label,
      levels = c("Near eye", "Chest")
    )
  )
activity_attrition_plot <- ggplot2::ggplot(
  activity_plot_data,
  ggplot2::aes(
    x = .data$percent_of_original_frame,
    y = .data$status_label,
    fill = .data$placement_label
  )
) +
  ggplot2::geom_col(
    width = 0.66,
    position = ggplot2::position_dodge(width = 0.74),
    alpha = 0.9
  ) +
  ggplot2::geom_text(
    ggplot2::aes(
      label = paste0(
        sprintf("%.1f", .data$percent_of_original_frame),
        "%"
      )
    ),
    position = ggplot2::position_dodge(width = 0.74),
    hjust = -0.18,
    size = 3.35,
    colour = "grey15"
  ) +
  ggplot2::scale_fill_manual(values = placement_palette, drop = FALSE) +
  ggplot2::scale_x_continuous(
    labels = function(value) paste0(value, "%"),
    breaks = c(0, 20, 40, 60, 80, 100),
    limits = c(0, 100),
    expand = ggplot2::expansion(mult = c(0, 0.07))
  ) +
  ggplot2::labs(
    x = "Share of the accepted placement-specific frame",
    y = NULL,
    fill = "Placement"
  ) +
  theme_h11_preparation() +
  ggplot2::theme(
    panel.grid.major.y = ggplot2::element_blank(),
    axis.text.y = ggplot2::element_text(lineheight = 1.05),
    plot.margin = ggplot2::margin(8, 22, 8, 8)
  )

figure_registry <- tibble::tribble(
  ~figure_id, ~filename, ~base_height_in, ~source_data, ~display_transform,
  "site_sex_support", "H11_preparation_site_sex_support", 6.2,
  paste0(
    "artifacts/11_source_data/H11/preparation/",
    "H11_preparation_site_sex_support.csv"
  ),
  "linear participant counts",
  "melEDI_distribution", "H11_preparation_melEDI_distribution", 7.0,
  paste0(
    "artifacts/11_source_data/H11/preparation/",
    "H11_preparation_melEDI_distribution.csv"
  ),
  "LightLogR::symlog_trans(base = 10, thr = 1, scale = 1) for melEDI; linear percentage for exact zeros",
  "activity_attrition", "H11_preparation_activity_attrition", 6.2,
  paste0(
    "artifacts/11_source_data/H11/preparation/",
    "H11_preparation_activity_attrition.csv"
  ),
  "linear percentage"
) |>
  mutate(
    export_height_in = .data$base_height_in *
      figure_spec$export_scale_multiplier,
    native_export_height_mm = .data$export_height_in * 25.4,
    intended_display_height_mm = figure_spec$intended_width_mm *
      .data$base_height_in / figure_spec$base_width_in
  )
plots <- list(
  site_sex_support = site_support_plot,
  melEDI_distribution = melEDI_distribution_plot,
  activity_attrition = activity_attrition_plot
)

figure_manifest_rows <- list()
for (index in seq_len(nrow(figure_registry))) {
  registry_row <- figure_registry[index, , drop = FALSE]
  plot <- plots[[registry_row$figure_id]]
  png_path <- file.path(
    figure_dir,
    paste0(registry_row$filename, ".png")
  )
  pdf_path <- file.path(
    figure_dir,
    paste0(registry_row$filename, ".pdf")
  )
  ggplot2::ggsave(
    filename = png_path,
    plot = plot,
    width = figure_spec$base_width_in,
    height = registry_row$base_height_in,
    units = "in",
    scale = figure_spec$export_scale_multiplier,
    dpi = figure_spec$raster_dpi,
    bg = "white"
  )
  ggplot2::ggsave(
    filename = pdf_path,
    plot = plot,
    width = figure_spec$base_width_in,
    height = registry_row$base_height_in,
    units = "in",
    scale = figure_spec$export_scale_multiplier,
    device = grDevices::cairo_pdf,
    bg = "white"
  )
  output_paths <- c(png_path, pdf_path)
  figure_manifest_rows[[registry_row$figure_id]] <- tibble::tibble(
    figure_id = registry_row$figure_id,
    path = substring(output_paths, nchar(root) + 2L),
    file_format = tools::file_ext(output_paths),
    sha256 = unname(vapply(output_paths, artifact_sha256, character(1))),
    bytes = as.numeric(file.info(output_paths)$size),
    base_width_in = figure_spec$base_width_in,
    base_height_in = registry_row$base_height_in,
    export_scale_multiplier = figure_spec$export_scale_multiplier,
    export_width_in = figure_spec$export_width_in,
    export_height_in = registry_row$export_height_in,
    native_export_width_mm = figure_spec$export_width_mm,
    native_export_height_mm = registry_row$native_export_height_mm,
    intended_display_width_mm = figure_spec$intended_width_mm,
    intended_display_height_mm = registry_row$intended_display_height_mm,
    display_reduction_factor = figure_spec$display_reduction_factor,
    smallest_central_nominal_text_pt =
      figure_spec$smallest_central_nominal_text_pt,
    effective_final_central_text_pt =
      figure_spec$effective_final_central_text_pt,
    smallest_essential_nominal_text_pt =
      figure_spec$smallest_essential_nominal_text_pt,
    effective_final_essential_text_pt =
      figure_spec$effective_final_essential_text_pt,
    smallest_minor_nominal_text_pt =
      figure_spec$smallest_minor_nominal_text_pt,
    effective_final_minor_text_pt =
      figure_spec$effective_final_minor_text_pt,
    source_data = registry_row$source_data,
    display_transform = registry_row$display_transform,
    raster_dpi = ifelse(
      tools::file_ext(output_paths) == "png",
      figure_spec$raster_dpi,
      NA_real_
    ),
    policy_id = if_else(
      registry_row$figure_id == "melEDI_distribution",
      "REPORT-011; REPORT-013",
      "REPORT-011"
    ),
    producer = producer
  )
}

proof_path <- file.path(
  manifest_dir,
  "H11_preparation_figure_A4_proofs.pdf"
)
grDevices::cairo_pdf(
  proof_path,
  width = figure_spec$a4_width_mm / 25.4,
  height = figure_spec$a4_height_mm / 25.4,
  onefile = TRUE,
  bg = "white"
)
for (index in seq_len(nrow(figure_registry))) {
  registry_row <- figure_registry[index, , drop = FALSE]
  grid::grid.newpage()
  grid::grid.rect(gp = grid::gpar(fill = "white", col = NA))
  png_path <- file.path(
    figure_dir,
    paste0(registry_row$filename, ".png")
  )
  proof_raster <- png::readPNG(png_path)
  grid::grid.raster(
    proof_raster,
    x = grid::unit(figure_spec$a4_side_margin_mm, "mm"),
    y = grid::unit(
      figure_spec$a4_height_mm - figure_spec$a4_side_margin_mm,
      "mm"
    ),
    width = grid::unit(figure_spec$intended_width_mm, "mm"),
    height = grid::unit(registry_row$intended_display_height_mm, "mm"),
    just = c("left", "top"),
    interpolate = TRUE
  )
  grid::grid.text(
    paste0(
      "Physical-size QA page ",
      index,
      ": ",
      registry_row$figure_id
    ),
    x = grid::unit(figure_spec$a4_side_margin_mm, "mm"),
    y = grid::unit(10, "mm"),
    just = c("left", "bottom"),
    gp = grid::gpar(fontsize = 6, col = "grey40")
  )
}
grDevices::dev.off()

figure_manifest <- bind_rows(figure_manifest_rows)
qa_manifest <- figure_registry |>
  transmute(
    .data$figure_id,
    png_path = paste0(
      "artifacts/10_figures/H11/preparation/",
      .data$filename,
      ".png"
    ),
    .data$source_data,
    .data$display_transform,
    base_width_in = figure_spec$base_width_in,
    base_height_in = .data$base_height_in,
    export_scale_multiplier = figure_spec$export_scale_multiplier,
    export_width_in = figure_spec$export_width_in,
    export_height_in = .data$export_height_in,
    native_export_width_mm = figure_spec$export_width_mm,
    native_export_height_mm = .data$native_export_height_mm,
    intended_display_width_mm = figure_spec$intended_width_mm,
    intended_display_height_mm = .data$intended_display_height_mm,
    display_reduction_factor = figure_spec$display_reduction_factor,
    smallest_central_nominal_text_pt =
      figure_spec$smallest_central_nominal_text_pt,
    effective_final_central_text_pt =
      figure_spec$effective_final_central_text_pt,
    smallest_essential_nominal_text_pt =
      figure_spec$smallest_essential_nominal_text_pt,
    effective_final_essential_text_pt =
      figure_spec$effective_final_essential_text_pt,
    smallest_minor_nominal_text_pt =
      figure_spec$smallest_minor_nominal_text_pt,
    effective_final_minor_text_pt =
      figure_spec$effective_final_minor_text_pt,
    a4_page_width_mm = figure_spec$a4_width_mm,
    a4_page_height_mm = figure_spec$a4_height_mm,
    a4_side_margin_mm = figure_spec$a4_side_margin_mm,
    a4_proof_path = substring(proof_path, nchar(root) + 2L),
    a4_proof_page = row_number(),
    final_asset_canvas = "tightly bounded to figure; A4 page excluded",
    physical_size_evidence = paste(
      "A4 portrait raster proof of exported asset displayed at 170 mm;",
      "20-mm side margins; A4 is QA only"
    ),
    typography_status = "PASS_BY_CALCULATION_PENDING_VISUAL_INSPECTION",
    visual_status = "PENDING",
    overall_status = "NOT_TESTED_PENDING_VISUAL_INSPECTION",
    policy_id = if_else(
      .data$figure_id == "melEDI_distribution",
      "REPORT-011; REPORT-013",
      "REPORT-011"
    )
  )

invisible(write_csv_artifact(
  figure_manifest,
  file.path(manifest_dir, "H11_preparation_figure_manifest.csv"),
  producer = producer
))
invisible(write_csv_artifact(
  qa_manifest,
  file.path(manifest_dir, "H11_preparation_figure_readability_qa.csv"),
  producer = producer
))

message(
  "H11 preparation artifacts complete: 6 frozen-frame integrity rows, ",
  nrow(site_sex_support), " site-sex support rows, ",
  nrow(melEDI_distribution), " distribution rows, ",
  nrow(activity_attrition), " activity attrition rows, and ",
  nrow(figure_registry), " logical figures. Visual A4 proof inspection ",
  "remains required."
)
