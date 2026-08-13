# Exact H02-aligned H06-daily 30-minute model frame and sleep decomposition.

h06d_h02_temporal_frame <- function(
  root,
  placement = c("near_eye", "chest"),
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
      arithmetic_mean_medi_lx = as.numeric(.data$arithmetic_mean_medi_lx)
    ) |>
    h06d_join_day_context(diaries) |>
    dplyr::left_join(
      h06d_temporal_links(root),
      by = c("site", "Id", "position", "local_date", "clock_bin"),
      relationship = "one-to-one"
    ) |>
    dplyr::filter(
      .data$bin_admissible,
      is.finite(.data$arithmetic_mean_medi_lx),
      .data$arithmetic_mean_medi_lx >= 0,
      !is.na(.data$work_free_day),
      !is.na(.data$activity_status),
      is.finite(.data$previous_sleep_duration_h)
    ) |>
    dplyr::mutate(
      placement = ifelse(.env$placement == "near_eye", "Near-eye", "Chest"),
      participant_key = paste(.data$site, .data$Id, sep = "::"),
      participant_day_key = paste(
        .data$site,
        .data$Id,
        .data$local_date,
        sep = "::"
      ),
      time_hour = (.data$clock_bin + 15) / 60
    )

  day_sleep <- raw |>
    dplyr::distinct(
      .data$participant_key,
      .data$participant_day_key,
      .data$previous_sleep_duration_h
    )
  h06d_assert_unique(
    day_sleep,
    c("participant_key", "participant_day_key"),
    "H06-daily H02-aligned fitted-day sleep values"
  )
  person_sleep <- day_sleep |>
    dplyr::summarise(
      sleep_person_mean_h = mean(.data$previous_sleep_duration_h),
      sleep_fitted_days = dplyr::n(),
      sleep_within_sd_h = if (dplyr::n() > 1L) {
        stats::sd(.data$previous_sleep_duration_h)
      } else {
        0
      },
      .by = "participant_key"
    )
  sleep_grand_mean_h <- mean(person_sleep$sleep_person_mean_h)

  output <- raw |>
    dplyr::left_join(
      person_sleep,
      by = "participant_key",
      relationship = "many-to-one"
    ) |>
    dplyr::mutate(
      sleep_between_h = .data$sleep_person_mean_h - .env$sleep_grand_mean_h,
      sleep_within_h =
        .data$previous_sleep_duration_h - .data$sleep_person_mean_h,
      response = log10(.data$arithmetic_mean_medi_lx + 0.1)
    ) |>
    h06d_assign_temporal_sequences() |>
    dplyr::mutate(
      site = factor(.data$site, levels = h06d_site_levels(root)),
      participant = factor(.data$participant_key),
      participant_day = factor(.data$participant_day_key),
      work_free_day = factor(
        .data$work_free_day,
        levels = c("Work day", "Free day")
      ),
      activity_status = factor(
        .data$activity_status,
        levels = c("Sedentary", "Active")
      ),
      AR_start = as.logical(.data$AR_start)
    )

  within_check <- output |>
    dplyr::distinct(
      .data$participant_key,
      .data$participant_day_key,
      .data$sleep_within_h
    ) |>
    dplyr::summarise(
      mean_within_h = mean(.data$sleep_within_h),
      .by = "participant_key"
    )
  if (
    nrow(output) == 0L ||
      any(output$expected_wall_minutes != 30L) ||
      any(output$valid_medi_wall_minutes < 15L) ||
      any(output$time_hour <= 0 | output$time_hour >= 24) ||
      any(!is.finite(output$response)) ||
      anyNA(output$work_free_day) ||
      anyNA(output$activity_status) ||
      max(abs(within_check$mean_within_h)) > 1e-10
  ) {
    h06d_abort("H06-daily H02-aligned temporal frame contract failed")
  }

  attr(output, "sleep_grand_mean_h") <- sleep_grand_mean_h
  output
}

h06d_h02_temporal_support <- function(frame) {
  participant_sleep <- frame |>
    dplyr::distinct(
      .data$site,
      .data$participant_key,
      .data$sleep_person_mean_h,
      .data$sleep_fitted_days,
      .data$sleep_within_sd_h
    )
  fitted_day_sleep <- frame |>
    dplyr::distinct(
      .data$site,
      .data$participant_key,
      .data$participant_day_key,
      .data$previous_sleep_duration_h,
      .data$sleep_between_h,
      .data$sleep_within_h
    )
  between_by_site <- fitted_day_sleep |>
    dplyr::distinct(
      .data$site,
      .data$participant_key,
      .data$sleep_between_h
    ) |>
    dplyr::summarise(
      between_sleep_sd_h = stats::sd(.data$sleep_between_h),
      .by = "site"
    )
  list(
    overall = tibble::tibble(
      placement = unique(frame$placement),
      observations_30_minute = nrow(frame),
      participant_days = dplyr::n_distinct(frame$participant_day_key),
      participants = dplyr::n_distinct(frame$participant_key),
      sites = dplyr::n_distinct(frame$site),
      exact_zero_bins = sum(frame$arithmetic_mean_medi_lx == 0),
      exact_zero_fraction = mean(frame$arithmetic_mean_medi_lx == 0),
      ar_sequences = sum(frame$AR_start),
      sleep_grand_mean_h = attr(frame, "sleep_grand_mean_h"),
      participants_with_two_or_more_days = sum(
        participant_sleep$sleep_fitted_days >= 2L
      ),
      participants_with_within_sleep_variation = sum(
        participant_sleep$sleep_within_sd_h > 0
      )
    ),
    context_cells = frame |>
      dplyr::summarise(
        observations_30_minute = dplyr::n(),
        participant_days = dplyr::n_distinct(.data$participant_day_key),
        participants = dplyr::n_distinct(.data$participant_key),
        sites = dplyr::n_distinct(.data$site),
        .by = c("work_free_day", "activity_status")
      ),
    sleep_by_site = fitted_day_sleep |>
      dplyr::summarise(
        participant_days = dplyr::n(),
        participants = dplyr::n_distinct(.data$participant_key),
        sleep_min_h = min(.data$previous_sleep_duration_h),
        sleep_median_h = stats::median(.data$previous_sleep_duration_h),
        sleep_max_h = max(.data$previous_sleep_duration_h),
        within_sleep_sd_h = stats::sd(.data$sleep_within_h),
        .by = "site"
      ) |>
      dplyr::left_join(
        between_by_site,
        by = "site",
        relationship = "one-to-one"
      ),
    ar_boundaries = frame |>
      dplyr::count(.data$ar_start_reason, name = "observations")
  )
}
