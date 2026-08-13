# H06-daily immutable input adapters and exact daily/30-minute model frames.

h06d_assert_unique <- function(data, key, label) {
  duplicate <- data |>
    dplyr::count(dplyr::across(dplyr::all_of(key)), name = "rows") |>
    dplyr::filter(.data$rows != 1L)
  if (nrow(duplicate) > 0L) {
    h06d_abort("%s contains %d duplicated keys", label, nrow(duplicate))
  }
  invisible(data)
}

h06d_load_diaries <- function(root) {
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
      exercise_intensity = dplyr::recode(
        as.character(.data$intensity),
        "None of the above, I did not perform any type of physical activity" =
          "No exercise",
        "Light (causing small to no increases in heart rate and breathing, e.g. taking a stroll in the park)" =
          "Light",
        "Moderate (causing moderate increases in heart rate and breathing, e.g. cycling in the city)" =
          "Moderate",
        "Vigorous (causing large increases in heart rate and breathing, e.g. running)" =
          "Vigorous"
      ) |>
        factor(levels = c("No exercise", "Light", "Moderate", "Vigorous")),
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

  h06d_assert_unique(
    exercise_day,
    c("site", "Id", "local_date"),
    "H06-daily exercise diary"
  )
  h06d_assert_unique(
    dplyr::filter(sleep_day, !is.na(.data$local_date)),
    c("site", "Id", "local_date"),
    "H06-daily sleep diary"
  )
  if (
    sum(exercise_raw$site == "TUM" & exercise_raw$Id == "TUM_S001") != 7L ||
      sum(exercise_raw$site == "TUM" & exercise_raw$Id == "TUM_S101") != 0L
  ) {
    h06d_abort("Immutable melidosData 1.0.6 TUM exercise identity failed")
  }
  if (sum(is.na(sleep_day$local_date)) != 1L) {
    h06d_abort("Unexpected number of quarantined sleep rows without wake date")
  }

  list(
    exercise_raw = exercise_raw,
    sleep_raw = sleep_raw,
    exercise_day = exercise_day,
    sleep_day = sleep_day
  )
}

h06d_site_levels <- function(root) {
  registry <- readr::read_csv(
    file.path(root, "config/site_display_registry.csv"),
    show_col_types = FALSE
  ) |>
    dplyr::arrange(.data$display_order)
  as.character(registry$site)
}

h06d_join_day_context <- function(data, diaries) {
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

h06d_daily_frame <- function(
  root,
  placement = c("near_eye", "chest"),
  metric_id,
  predictor_id,
  diaries = h06d_load_diaries(root)
) {
  placement <- match.arg(placement)
  columns <- h06d_metric_columns()
  if (!metric_id %in% names(columns)) {
    h06d_abort("Unknown H06-daily metric `%s`", metric_id)
  }
  predictor <- h06d_predictor_registry() |>
    dplyr::filter(.data$predictor_id == .env$predictor_id)
  if (nrow(predictor) != 1L) {
    h06d_abort("Unknown H06-daily predictor `%s`", predictor_id)
  }
  file <- if (placement == "near_eye") {
    "metrics_glasses_participant_day_enriched.rds"
  } else {
    "metrics_chest_participant_day_enriched.rds"
  }
  raw <- readRDS(file.path(root, "artifacts/06_model_data/base", file)) |>
    dplyr::transmute(
      site = as.character(.data$site),
      Id = as.character(.data$Id),
      local_date = as.Date(.data$local_date),
      response_source = as.numeric(.data[[unname(columns[[metric_id]])]]),
      expected_real_minutes = as.numeric(.data$expected_real_minutes),
      longest_period_exact = as.logical(
        .data$longest_bout_above_250_exact_identifiable
      )
    ) |>
    h06d_join_day_context(diaries) |>
    dplyr::filter(
      is.finite(.data$response_source),
      !is.na(.data[[predictor$column[[1L]]]])
    ) |>
    dplyr::mutate(
      placement = ifelse(.env$placement == "near_eye", "Near-eye", "Chest"),
      metric_id = .env$metric_id,
      predictor_id = .env$predictor_id,
      participant_key = paste(.data$site, .data$Id, sep = "::"),
      participant_day_key = paste(
        .data$site,
        .data$Id,
        .data$local_date,
        sep = "::"
      ),
      site = factor(.data$site, levels = h06d_site_levels(root)),
      participant_key = factor(.data$participant_key),
      work_free_day = droplevels(.data$work_free_day),
      activity_status = droplevels(.data$activity_status)
    )
  if (nrow(raw) == 0L || nlevels(droplevels(raw$site)) < 2L) {
    h06d_abort("Empty or single-site H06-daily frame")
  }
  raw
}

h06d_temporal_links <- function(root) {
  links <- readRDS(file.path(
    root,
    "artifacts/06_model_data/temporal_provenance/wall_outcome_links.rds"
  )) |>
    dplyr::filter(.data$resolution == "30_minute") |>
    dplyr::transmute(
      site = as.character(.data$site),
      Id = as.character(.data$Id),
      position = as.character(.data$position),
      local_date = as.Date(.data$local_date),
      clock_bin = as.integer(.data$wall_bin_start_minute),
      source_utc_start = .data$source_utc_start,
      source_utc_end = .data$source_utc_end,
      relationship_type = as.character(.data$relationship_type),
      one_to_one_elapsed_coordinate = as.logical(
        .data$one_to_one_elapsed_coordinate
      )
    )
  h06d_assert_unique(
    links,
    c("site", "Id", "position", "local_date", "clock_bin"),
    "H06-daily 30-minute temporal links"
  )
  links
}

h06d_assign_temporal_sequences <- function(frame) {
  output <- frame |>
    dplyr::arrange(
      .data$site,
      .data$Id,
      .data$local_date,
      .data$source_utc_start,
      .data$clock_bin
    ) |>
    dplyr::group_by(.data$site, .data$Id, .data$local_date) |>
    dplyr::mutate(
      previous_source_utc_end = dplyr::lag(.data$source_utc_end),
      previous_one_to_one = dplyr::lag(
        .data$one_to_one_elapsed_coordinate
      ),
      elapsed_from_previous_seconds = as.numeric(difftime(
        .data$source_utc_start,
        .data$previous_source_utc_end,
        units = "secs"
      )),
      ar_start_reason = dplyr::case_when(
        dplyr::row_number() == 1L ~ "participant_day_start",
        !.data$one_to_one_elapsed_coordinate ~
          "non_one_to_one_wall_outcome",
        !dplyr::coalesce(.data$previous_one_to_one, TRUE) ~
          "after_non_one_to_one_wall_outcome",
        is.na(.data$elapsed_from_previous_seconds) ~
          "missing_elapsed_coordinate",
        .data$elapsed_from_previous_seconds != 0 ~
          "elapsed_discontinuity",
        TRUE ~ "continuous"
      ),
      AR_start = .data$ar_start_reason != "continuous",
      sequence_number = cumsum(.data$AR_start)
    ) |>
    dplyr::ungroup() |>
    dplyr::mutate(
      temporal_sequence = interaction(
        .data$site,
        .data$Id,
        .data$local_date,
        .data$sequence_number,
        drop = TRUE,
        lex.order = TRUE
      )
    ) |>
    dplyr::select(-"previous_source_utc_end", -"previous_one_to_one")

  if (
    anyNA(output$source_utc_start) ||
      anyNA(output$source_utc_end) ||
      anyNA(output$one_to_one_elapsed_coordinate)
  ) {
    h06d_abort("A fitted temporal row lacks true-time provenance")
  }
  if (any(output$elapsed_from_previous_seconds[!output$AR_start] != 0)) {
    h06d_abort("H06-daily AR(1) crosses an elapsed-time discontinuity")
  }
  if (any(!output$one_to_one_elapsed_coordinate[!output$AR_start])) {
    h06d_abort("H06-daily AR(1) crosses a non-one-to-one outcome")
  }
  output
}

h06d_temporal_frame <- function(
  root,
  placement = c("near_eye", "chest"),
  positive_only = FALSE,
  diaries = h06d_load_diaries(root)
) {
  placement <- match.arg(placement)
  file <- if (placement == "near_eye") {
    "metrics_glasses_30_minute_context.rds"
  } else {
    "metrics_chest_30_minute_context.rds"
  }
  raw <- readRDS(file.path(root, "artifacts/06_model_data/base", file)) |>
    dplyr::transmute(
      site = as.character(.data$site),
      Id = as.character(.data$Id),
      position = as.character(.data$position),
      local_date = as.Date(.data$local_date),
      clock_bin = as.integer(.data$clock_bin),
      expected_wall_minutes = as.integer(.data$expected_wall_minutes),
      valid_medi_wall_minutes = as.integer(.data$valid_medi_wall_minutes),
      bin_admissible = as.logical(.data$bin_admissible),
      geometric_mean_medi_lx = as.numeric(
        .data$zero_aware_geometric_mean_medi_lx
      )
    ) |>
    h06d_join_day_context(diaries) |>
    dplyr::left_join(
      h06d_temporal_links(root),
      by = c("site", "Id", "position", "local_date", "clock_bin"),
      relationship = "one-to-one"
    ) |>
    dplyr::filter(
      .data$bin_admissible,
      is.finite(.data$geometric_mean_medi_lx),
      !is.na(.data$work_free_day),
      !is.na(.data$activity_status),
      is.finite(.data$previous_sleep_duration_centered_h)
    )
  if (isTRUE(positive_only)) {
    raw <- dplyr::filter(raw, .data$geometric_mean_medi_lx > 0)
  }
  output <- raw |>
    dplyr::mutate(
      placement = ifelse(.env$placement == "near_eye", "Near-eye", "Chest"),
      positive_medi = as.integer(.data$geometric_mean_medi_lx > 0),
      participant_key = paste(.data$site, .data$Id, sep = "::"),
      participant_day_key = paste(
        .data$site,
        .data$Id,
        .data$local_date,
        sep = "::"
      ),
      time_hour = (.data$clock_bin + 15) / 60
    ) |>
    h06d_assign_temporal_sequences() |>
    dplyr::mutate(
      site = factor(.data$site, levels = h06d_site_levels(root)),
      participant = factor(.data$participant_key),
      participant_day = factor(.data$participant_day_key),
      work_free_day = droplevels(.data$work_free_day),
      activity_status = droplevels(.data$activity_status),
      AR_start = as.logical(.data$AR_start)
    )
  if (
    any(output$expected_wall_minutes != 30L) ||
      any(output$valid_medi_wall_minutes < 15L) ||
      any(output$time_hour <= 0 | output$time_hour >= 24) ||
      any(output$geometric_mean_medi_lx < 0)
  ) {
    h06d_abort("H06-daily temporal support contract failed")
  }
  output
}
