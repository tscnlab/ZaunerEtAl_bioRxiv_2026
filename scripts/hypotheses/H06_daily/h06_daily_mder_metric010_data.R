# H06_daily METRIC-010 input adapters and exact analysis-frame construction.

h06d_m10_assert_unique <- function(data, key, label) {
  duplicate <- data |>
    dplyr::count(dplyr::across(dplyr::all_of(key)), name = "rows") |>
    dplyr::filter(.data$rows != 1L)
  h06d_m10_assert(
    nrow(duplicate) == 0L,
    "%s contains %d duplicated keys",
    label,
    nrow(duplicate)
  )
  invisible(data)
}

h06d_m10_site_levels <- function(root) {
  readr::read_csv(
    file.path(root, "config/site_display_registry.csv"),
    show_col_types = FALSE
  ) |>
    dplyr::arrange(.data$display_order) |>
    dplyr::pull(.data$site) |>
    as.character()
}

h06d_m10_load_diaries <- function(root) {
  exercise_raw <- readRDS(file.path(
    root,
    "artifacts/06_model_data/normalized_inputs/exercisediary.rds"
  ))
  sleep_raw <- readRDS(file.path(
    root,
    "artifacts/06_model_data/normalized_inputs/sleepdiaries.rds"
  ))

  exercise_day <- exercise_raw |>
    dplyr::transmute(
      site = as.character(.data$site),
      Id = as.character(.data$Id),
      local_date = as.Date(.data$Date),
      activity_status = dplyr::case_when(
        is.na(.data$intensity) ~ NA_character_,
        as.character(.data$intensity) ==
          "None of the above, I did not perform any type of physical activity" ~
          "Sedentary",
        TRUE ~ "Active"
      ) |>
        factor(levels = c("Sedentary", "Active")),
      exercise_source_row = .data$source_row
    )

  sleep_day <- sleep_raw |>
    dplyr::transmute(
      site = as.character(.data$site),
      Id = as.character(.data$Id),
      local_date = as.Date(.data$wake_wall),
      work_free_day = factor(
        as.character(.data$daytype2),
        levels = c("a work day", "a free day"),
        labels = c("Work day", "Free day")
      ),
      previous_sleep_duration_h = as.numeric(
        .data$sleep_duration,
        units = "hours"
      ),
      previous_sleep_duration_centered_h =
        .data$previous_sleep_duration_h - 8,
      sleep_source_row = .data$source_row
    )

  h06d_m10_assert_unique(
    exercise_day,
    c("site", "Id", "local_date"),
    "METRIC-010 exercise diary"
  )
  h06d_m10_assert_unique(
    dplyr::filter(sleep_day, !is.na(.data$local_date)),
    c("site", "Id", "local_date"),
    "METRIC-010 sleep diary"
  )
  h06d_m10_assert(
    sum(exercise_raw$site == "TUM" & exercise_raw$Id == "TUM_S001") == 7L,
    "Immutable TUM S001 exercise-row identity failed"
  )
  h06d_m10_assert(
    sum(exercise_raw$site == "TUM" & exercise_raw$Id == "TUM_S101") == 0L,
    "Immutable TUM S101 exercise-row identity failed"
  )
  h06d_m10_assert(
    sum(is.na(sleep_day$local_date)) == 1L,
    "Unexpected number of sleep rows without a wake date"
  )

  list(
    exercise_raw = exercise_raw,
    sleep_raw = sleep_raw,
    exercise_day = exercise_day,
    sleep_day = sleep_day
  )
}

h06d_m10_join_context <- function(data, diaries) {
  data |>
    dplyr::left_join(
      diaries$sleep_day,
      by = c("site", "Id", "local_date"),
      relationship = "many-to-one"
    ) |>
    dplyr::left_join(
      diaries$exercise_day,
      by = c("site", "Id", "local_date"),
      relationship = "many-to-one"
    )
}

h06d_m10_primary_source <- function(
  root,
  placement_id = c("near_eye", "chest"),
  diaries = h06d_m10_load_diaries(root)
) {
  placement_id <- match.arg(placement_id)
  stem <- if (placement_id == "near_eye") "glasses" else "chest"
  wide_path <- file.path(
    root,
    "artifacts/06_model_data/base",
    sprintf("metrics_%s_participant_day_enriched.rds", stem)
  )
  long_path <- file.path(
    root,
    "artifacts/05_metrics",
    sprintf("metrics_%s_values_long.csv", stem)
  )

  wide <- readRDS(wide_path) |>
    dplyr::transmute(
      site = as.character(.data$site),
      Id = as.character(.data$Id),
      local_date = as.Date(.data$local_date),
      response_source = as.numeric(.data$mder),
      viable_ratio_minutes = as.integer(.data$mder_viable_ratio_minutes),
      expected_minutes = as.integer(.data$mder_expected_minutes),
      viable_ratio_fraction = as.numeric(.data$mder_viable_ratio_fraction),
      minimum_viable_fraction = as.numeric(
        .data$mder_minimum_viable_fraction
      ),
      passes_support = as.logical(.data$mder_passes_viable_ratio_support),
      support_threshold_enforced = as.logical(
        .data$mder_support_threshold_enforced
      ),
      ratio_scaled_or_weighted = as.logical(
        .data$mder_ratio_scaled_or_weighted
      ),
      estimable = as.logical(.data$mder_estimable),
      failure_reason = as.character(.data$mder_failure_reason),
      excluded_nonfinite_source_minutes = as.integer(
        .data$mder_excluded_nonfinite_source_minutes
      ),
      excluded_zero_either_minutes = as.integer(
        .data$mder_excluded_zero_either_minutes
      )
    )

  long <- readr::read_csv(long_path, show_col_types = FALSE) |>
    dplyr::filter(
      .data$analysis_unit == "participant_day",
      .data$profile_variant == "pooled",
      .data$metric == "mder_mean_of_viable_ratios"
    ) |>
    dplyr::transmute(
      site = as.character(.data$site),
      Id = as.character(.data$Id),
      local_date = as.Date(.data$local_date),
      audited_value = as.numeric(.data$value),
      audited_units = as.character(.data$units),
      audited_estimable = as.logical(.data$estimable),
      audited_failure_reason = as.character(.data$failure_reason),
      audited_valid_minutes = as.integer(.data$valid_minutes),
      audited_expected_minutes = as.integer(.data$expected_minutes),
      audited_minimum_support = as.numeric(.data$minimum_support),
      audited_support_threshold_enforced = as.logical(
        .data$support_threshold_enforced
      ),
      audited_ratio_scaled_or_weighted = as.logical(
        .data$ratio_scaled_or_weighted
      ),
      audited_estimate_interpretation = as.character(
        .data$estimate_interpretation
      )
    )

  h06d_m10_assert_unique(
    wide,
    c("site", "Id", "local_date"),
    sprintf("METRIC-010 %s primary wide source", placement_id)
  )
  h06d_m10_assert_unique(
    long,
    c("site", "Id", "local_date"),
    sprintf("METRIC-010 %s primary long source", placement_id)
  )
  h06d_m10_assert(
    nrow(wide) == nrow(long),
    "METRIC-010 %s wide/long row mismatch",
    placement_id
  )

  reconciled <- wide |>
    dplyr::left_join(
      long,
      by = c("site", "Id", "local_date"),
      relationship = "one-to-one"
    )

  h06d_m10_assert(
    all(is.na(reconciled$response_source) == is.na(reconciled$audited_value)),
    "METRIC-010 %s wide/long missingness mismatch",
    placement_id
  )
  finite <- is.finite(reconciled$response_source)
  h06d_m10_assert(
    all(abs(
      reconciled$response_source[finite] -
        reconciled$audited_value[finite]
    ) < .Machine$double.eps^0.5),
    "METRIC-010 %s wide/long value mismatch",
    placement_id
  )
  h06d_m10_assert(
    all(reconciled$expected_minutes == 1440L) &&
      all(reconciled$audited_expected_minutes == 1440L),
    "METRIC-010 %s expected-minute denominator is not 1,440",
    placement_id
  )
  h06d_m10_assert(
    all(reconciled$minimum_viable_fraction == 0.5) &&
      all(reconciled$audited_minimum_support == 0.5),
    "METRIC-010 %s 50%% support contract failed",
    placement_id
  )
  h06d_m10_assert(
    all(reconciled$support_threshold_enforced) &&
      all(reconciled$audited_support_threshold_enforced),
    "METRIC-010 %s support threshold is not enforced",
    placement_id
  )
  h06d_m10_assert(
    all(!reconciled$ratio_scaled_or_weighted) &&
      all(!reconciled$audited_ratio_scaled_or_weighted),
    "METRIC-010 %s contains a scaled or weighted ratio",
    placement_id
  )
  h06d_m10_assert(
    all(reconciled$audited_units == "dimensionless"),
    "METRIC-010 %s unit is not dimensionless",
    placement_id
  )
  h06d_m10_assert(
    all(finite == reconciled$estimable) &&
      all(finite == reconciled$audited_estimable) &&
      all(finite == reconciled$passes_support) &&
      all(reconciled$viable_ratio_minutes[finite] >= 720L) &&
      all(reconciled$viable_ratio_minutes[!finite] < 720L) &&
      all(reconciled$response_source[finite] > 0),
    "METRIC-010 %s estimability, positivity, or inclusive support failed",
    placement_id
  )

  reconciled |>
    h06d_m10_join_context(diaries) |>
    dplyr::mutate(
      dataset_id = "primary",
      dataset_label = "Primary gap-aware dataset",
      placement_id = .env$placement_id,
      placement = ifelse(.env$placement_id == "near_eye", "Near-eye", "Chest"),
      metric_id = "mder_mean_of_viable_ratios",
      participant_key = paste(.data$site, .data$Id, sep = "::"),
      participant_day_key = paste(
        .data$site,
        .data$Id,
        .data$local_date,
        sep = "::"
      )
    )
}

h06d_m10_gap_source <- function(
  root,
  placement_id = c("near_eye", "chest"),
  diaries = h06d_m10_load_diaries(root)
) {
  placement_id <- match.arg(placement_id)
  position_role <- if (placement_id == "near_eye") {
    "near_eye_primary"
  } else {
    "complementary_chest"
  }
  data <- readRDS(file.path(
    root,
    paste0(
      "artifacts/06_model_data/scenarios/manuscript_prepared_data/",
      "participant_day_metrics.rds"
    )
  )) |>
    dplyr::filter(
      .data$metric_id == "mder_mean_of_viable_ratios",
      .data$position_role == .env$position_role
    ) |>
    dplyr::transmute(
      site = as.character(.data$site),
      Id = as.character(.data$Id),
      local_date = as.Date(.data$local_date),
      response_source = as.numeric(.data$manuscript_prepared_value)
    )

  support <- readRDS(file.path(
    root,
    paste0(
      "artifacts/06_model_data/scenarios/manuscript_prepared_data/",
      "mder_support.rds"
    )
  )) |>
    dplyr::filter(
      .data$metric_id == "mder_mean_of_viable_ratios",
      .data$position_role == .env$position_role
    ) |>
    dplyr::transmute(
      site = as.character(.data$site),
      Id = as.character(.data$Id),
      local_date = as.Date(.data$local_date),
      audited_response_source = as.numeric(.data$manuscript_prepared_value),
      viable_ratio_minutes = as.integer(.data$viable_ratio_minutes),
      expected_minutes = as.integer(.data$expected_minutes),
      viable_ratio_fraction = as.numeric(.data$viable_ratio_fraction),
      minimum_viable_fraction = as.numeric(.data$minimum_viable_fraction),
      passes_support = as.logical(.data$passes_viable_ratio_support),
      support_threshold_enforced = as.logical(
        .data$support_threshold_enforced
      ),
      ratio_scaled_or_weighted = as.logical(
        .data$ratio_scaled_or_weighted
      ),
      estimable = as.logical(.data$estimable),
      failure_reason = as.character(.data$failure_reason),
      excluded_nonfinite_source_minutes = as.integer(
        .data$excluded_nonfinite_source_minutes
      ),
      excluded_zero_either_minutes = as.integer(
        .data$excluded_zero_either_minutes
      ),
      duplicate_minute_rule = as.character(.data$duplicate_minute_rule),
      expected_day_rule = as.character(.data$expected_day_rule)
    )

  h06d_m10_assert_unique(
    data,
    c("site", "Id", "local_date"),
    sprintf("METRIC-010 %s gap-timing-unaware source", placement_id)
  )
  h06d_m10_assert_unique(
    support,
    c("site", "Id", "local_date"),
    sprintf("METRIC-010 %s gap support audit", placement_id)
  )
  h06d_m10_assert(
    nrow(data) == ifelse(placement_id == "near_eye", 811L, 897L) &&
      nrow(support) == nrow(data),
    "Unexpected METRIC-010 %s gap source row count",
    placement_id
  )

  data <- data |>
    dplyr::left_join(
      support,
      by = c("site", "Id", "local_date"),
      relationship = "one-to-one"
    )

  finite <- is.finite(data$response_source)
  h06d_m10_assert(
    all(is.na(data$response_source) == is.na(data$audited_response_source)) &&
      all(abs(
        data$response_source[finite] - data$audited_response_source[finite]
      ) < .Machine$double.eps^0.5),
    "METRIC-010 %s gap value/support reconciliation failed",
    placement_id
  )
  h06d_m10_assert(
    all(data$expected_minutes == 1440L) &&
      all(data$minimum_viable_fraction == 0.5) &&
      all(data$support_threshold_enforced) &&
      all(!data$ratio_scaled_or_weighted) &&
      all(data$duplicate_minute_rule == "channel_mean_before_ratio") &&
      all(data$expected_day_rule == "complete_1440_local_wall_clock_minutes"),
    "METRIC-010 %s gap support-rule identity failed",
    placement_id
  )
  h06d_m10_assert(
    all(finite == data$estimable) &&
      all(finite == data$passes_support) &&
      all(data$viable_ratio_minutes[finite] >= 720L) &&
      all(data$viable_ratio_minutes[!finite] < 720L) &&
      all(data$response_source[finite] > 0) &&
      all(is.na(data$failure_reason[finite])) &&
      all(!is.na(data$failure_reason[!finite])) &&
      all(abs(
        data$viable_ratio_fraction - data$viable_ratio_minutes / 1440
      ) < .Machine$double.eps^0.5),
    "METRIC-010 %s gap estimability, positivity, or inclusive support failed",
    placement_id
  )

  data |>
    dplyr::select(
      -"audited_response_source",
      -"duplicate_minute_rule",
      -"expected_day_rule"
    ) |>
    h06d_m10_join_context(diaries) |>
    dplyr::mutate(
      dataset_id = "gap_timing_unaware",
      dataset_label = "Gap-timing-unaware dataset",
      placement_id = .env$placement_id,
      placement = ifelse(.env$placement_id == "near_eye", "Near-eye", "Chest"),
      metric_id = "mder_mean_of_viable_ratios",
      participant_key = paste(.data$site, .data$Id, sep = "::"),
      participant_day_key = paste(
        .data$site,
        .data$Id,
        .data$local_date,
        sep = "::"
      )
    )
}

h06d_m10_load_sources <- function(root) {
  diaries <- h06d_m10_load_diaries(root)
  dplyr::bind_rows(
    h06d_m10_primary_source(root, "near_eye", diaries),
    h06d_m10_primary_source(root, "chest", diaries),
    h06d_m10_gap_source(root, "near_eye", diaries),
    h06d_m10_gap_source(root, "chest", diaries)
  ) |>
    dplyr::mutate(
      site = factor(.data$site, levels = h06d_m10_site_levels(root)),
      placement = factor(.data$placement, levels = c("Near-eye", "Chest"))
    )
}

h06d_m10_predictor_available <- function(data, column) {
  value <- data[[column]]
  if (is.numeric(value)) {
    is.finite(value)
  } else {
    !is.na(value)
  }
}

h06d_m10_prepare_frame <- function(data, predictor) {
  column <- predictor$column[[1L]]
  output <- data |>
    dplyr::filter(
      is.finite(.data$response_source),
      h06d_m10_predictor_available(dplyr::pick(dplyr::everything()), column)
    ) |>
    dplyr::mutate(
      predictor_id = predictor$predictor_id[[1L]],
      response_value = .data$response_source,
      participant_key = factor(.data$participant_key),
      site = droplevels(.data$site),
      work_free_day = droplevels(.data$work_free_day),
      activity_status = droplevels(.data$activity_status)
    ) |>
    dplyr::arrange(.data$site, .data$participant_key, .data$local_date)

  h06d_m10_assert_unique(
    output,
    c("site", "participant_key", "local_date"),
    paste("METRIC-010 frame", predictor$predictor_id[[1L]])
  )
  h06d_m10_assert(
    nrow(output) > 0L && dplyr::n_distinct(output$site) >= 2L,
    "METRIC-010 frame is empty or single-site"
  )
  if (nlevels(output$site) > 1L) {
    contrasts(output$site) <- stats::contr.sum(nlevels(output$site))
  }
  output
}

h06d_m10_frame_registry <- function() {
  tibble::tribble(
    ~run_order, ~run_id, ~dataset_id, ~placement_id, ~sample_role,
    ~analysis_role, ~test_role,
    1L, "primary__near_eye__all_available", "primary", "near_eye",
    "all_available", "primary", "primary_raw_slot",
    2L, "primary__chest__all_available", "primary", "chest",
    "all_available", "contextual_complement", "estimate_only",
    3L, "primary__near_eye__paired_common", "primary", "near_eye",
    "paired_common", "paired_complement", "estimate_only",
    4L, "primary__chest__paired_common", "primary", "chest",
    "paired_common", "paired_complement", "estimate_only",
    5L, "gap_timing_unaware__near_eye__all_available",
    "gap_timing_unaware", "near_eye", "all_available",
    "dataset_sensitivity", "gap_raw_slot",
    6L, "gap_timing_unaware__chest__all_available",
    "gap_timing_unaware", "chest", "all_available",
    "dataset_sensitivity_context", "estimate_only",
    7L, "gap_timing_unaware__near_eye__paired_common",
    "gap_timing_unaware", "near_eye", "paired_common",
    "dataset_paired_complement", "estimate_only",
    8L, "gap_timing_unaware__chest__paired_common",
    "gap_timing_unaware", "chest", "paired_common",
    "dataset_paired_complement", "estimate_only",
    9L, "primary__near_eye__dataset_common", "primary", "near_eye",
    "dataset_common", "common_sample_primary", "estimate_only",
    10L, "gap_timing_unaware__near_eye__dataset_common",
    "gap_timing_unaware", "near_eye", "dataset_common",
    "common_sample_gap", "estimate_only",
    11L, "primary__chest__dataset_common", "primary", "chest",
    "dataset_common", "common_sample_primary", "estimate_only",
    12L, "gap_timing_unaware__chest__dataset_common",
    "gap_timing_unaware", "chest", "dataset_common",
    "common_sample_gap", "estimate_only"
  )
}

h06d_m10_build_frames <- function(source_data) {
  predictors <- h06d_m10_predictor_registry()
  runs <- h06d_m10_frame_registry()
  frames <- list()
  frame_rows <- list()

  for (predictor_index in seq_len(nrow(predictors))) {
    predictor <- predictors[predictor_index, ]
    column <- predictor$column[[1L]]
    available <- source_data |>
      dplyr::mutate(
        response_available = is.finite(.data$response_source),
        predictor_available = h06d_m10_predictor_available(
          dplyr::pick(dplyr::everything()),
          column
        ),
        complete = .data$response_available & .data$predictor_available
      )

    placement_common_keys <- available |>
      dplyr::filter(.data$complete) |>
      dplyr::distinct(dplyr::across(dplyr::all_of(c(
        "dataset_id", "participant_day_key", "placement_id"
      )))) |>
      dplyr::count(
        .data$dataset_id,
        .data$participant_day_key,
        name = "placements"
      ) |>
      dplyr::filter(.data$placements == 2L) |>
      dplyr::select(dplyr::all_of(c("dataset_id", "participant_day_key")))

    dataset_common_keys <- available |>
      dplyr::filter(.data$complete) |>
      dplyr::distinct(dplyr::across(dplyr::all_of(c(
        "placement_id", "participant_day_key", "dataset_id"
      )))) |>
      dplyr::count(
        .data$placement_id,
        .data$participant_day_key,
        name = "datasets"
      ) |>
      dplyr::filter(.data$datasets == 2L) |>
      dplyr::select(dplyr::all_of(c("placement_id", "participant_day_key")))

    for (run_index in seq_len(nrow(runs))) {
      run <- runs[run_index, ]
      selected <- available |>
        dplyr::filter(
          .data$dataset_id == run$dataset_id[[1L]],
          .data$placement_id == run$placement_id[[1L]],
          .data$complete
        )
      if (run$sample_role[[1L]] == "paired_common") {
        selected <- selected |>
          dplyr::inner_join(
            placement_common_keys,
            by = c("dataset_id", "participant_day_key"),
            relationship = "many-to-one"
          )
      }
      if (run$sample_role[[1L]] == "dataset_common") {
        selected <- selected |>
          dplyr::inner_join(
            dataset_common_keys,
            by = c("placement_id", "participant_day_key"),
            relationship = "many-to-one"
          )
      }
      frame <- h06d_m10_prepare_frame(selected, predictor)
      key <- paste(run$run_id[[1L]], predictor$predictor_id[[1L]], sep = "__")
      frames[[key]] <- frame
      frame_rows[[key]] <- dplyr::bind_cols(
        run,
        predictor |>
          dplyr::select(
            "predictor_order",
            "predictor_id",
            "reader_name",
            "contrast_label",
            "association_family_id",
            "heterogeneity_family_id"
          ),
        tibble::tibble(
          frame_key = key,
          participant_days = nrow(frame),
          participants = dplyr::n_distinct(frame$participant_key),
          sites = dplyr::n_distinct(frame$site),
          minimum = min(frame$response_value),
          median = stats::median(frame$response_value),
          maximum = max(frame$response_value),
          exact_zeros = sum(frame$response_value == 0),
          frame_object_sha256 = digest::digest(
            frame,
            algo = "sha256",
            serialize = TRUE
          )
        )
      )
    }
  }

  list(
    frames = frames,
    registry = dplyr::bind_rows(frame_rows) |>
      dplyr::arrange(.data$predictor_order, .data$run_order)
  )
}

h06d_m10_add_day_sequences <- function(frame) {
  output <- frame |>
    dplyr::arrange(.data$participant_key, .data$local_date) |>
    dplyr::group_by(.data$participant_key) |>
    dplyr::mutate(
      date_gap = as.integer(.data$local_date - dplyr::lag(.data$local_date)),
      sequence_start = dplyr::row_number() == 1L |
        is.na(.data$date_gap) |
        .data$date_gap != 1L,
      sequence_number = cumsum(.data$sequence_start)
    ) |>
    dplyr::ungroup() |>
    dplyr::group_by(.data$participant_key, .data$sequence_number) |>
    dplyr::mutate(day_index = dplyr::row_number()) |>
    dplyr::ungroup() |>
    dplyr::mutate(
      day_sequence_id = interaction(
        .data$participant_key,
        .data$sequence_number,
        drop = TRUE,
        lex.order = TRUE
      ),
      day_index_factor = factor(
        .data$day_index,
        levels = seq_len(max(.data$day_index))
      )
    )

  h06d_m10_assert(
    all(output$date_gap[!output$sequence_start] == 1L),
    "METRIC-010 AR sequence crosses a missing calendar date"
  )
  output
}
