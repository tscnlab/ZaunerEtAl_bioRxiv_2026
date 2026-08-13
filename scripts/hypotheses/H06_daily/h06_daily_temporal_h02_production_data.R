# Construct the six approved H02-aligned H06-daily temporal production frames.
# This code only adapts prepared 30-minute artifacts into H06_daily-owned model
# frames; it never rebuilds shared preparation or metric artifacts.

h06d_h02_production_key <- function(include_position = TRUE) {
  key <- c("site", "Id", "local_date", "clock_bin")
  if (isTRUE(include_position)) {
    key <- append(key, "position", after = 2L)
  }
  key
}

h06d_h02_production_registry <- function() {
  tibble::tribble(
    ~run_order, ~run_id, ~data_scenario_id, ~data_scenario_label,
    ~placement_id, ~position, ~placement_label, ~sample_scenario,
    ~analytical_role, ~multiplicity_role,
    1L, "primary__near_eye__all_available", "primary",
    "Primary dataset", "near_eye", "glasses", "Near eye",
    "all_available", "primary exploratory temporal analysis",
    "primary_four_test_bh",
    2L, "primary__chest__all_available", "primary",
    "Primary dataset", "chest", "chest", "Chest",
    "all_available", "complementary placement analysis",
    "estimation_only",
    3L, "primary__near_eye__paired_common", "primary",
    "Primary dataset", "near_eye", "glasses", "Near eye",
    "paired_common", "paired/common-sample complementary analysis",
    "estimation_only",
    4L, "primary__chest__paired_common", "primary",
    "Primary dataset", "chest", "chest", "Chest",
    "paired_common", "paired/common-sample complementary analysis",
    "estimation_only",
    5L, "gap_timing_unaware__near_eye__all_available",
    "gap_timing_unaware", "Gap-timing-unaware dataset", "near_eye",
    "glasses", "Near eye", "all_available",
    "predefined dataset sensitivity", "gap_four_test_bh",
    6L, "gap_timing_unaware__chest__all_available",
    "gap_timing_unaware", "Gap-timing-unaware dataset", "chest",
    "chest", "Chest", "all_available",
    "complementary placement dataset sensitivity", "estimation_only"
  )
}

h06d_h02_clock_bin_from_proxy <- function(value) {
  local_time <- as.POSIXlt(value, tz = "UTC")
  as.integer(local_time$hour * 60L + local_time$min)
}

h06d_h02_production_raw_grid <- function(
  root,
  data_scenario_id = c("primary", "gap_timing_unaware"),
  placement_id = c("near_eye", "chest"),
  diaries = h06d_load_diaries(root)
) {
  data_scenario_id <- match.arg(data_scenario_id)
  placement_id <- match.arg(placement_id)
  position <- if (placement_id == "near_eye") "glasses" else "chest"

  if (data_scenario_id == "primary") {
    filename <- paste0("metrics_", position, "_30_minute_context.rds")
    grid <- readRDS(file.path(root, "artifacts/06_model_data/base", filename)) |>
      dplyr::transmute(
        data_scenario_id = "primary",
        site = as.character(.data$site),
        Id = as.character(.data$Id),
        position = as.character(.data$position),
        local_date = as.Date(.data$local_date),
        clock_bin = as.integer(.data$clock_bin),
        arithmetic_mean_medi_lx = as.numeric(
          .data$arithmetic_mean_medi_lx
        ),
        bin_admissible = as.logical(.data$bin_admissible),
        expected_wall_minutes = as.integer(.data$expected_wall_minutes),
        valid_medi_wall_minutes = as.integer(
          .data$valid_medi_wall_minutes
        ),
        support_available = TRUE,
        local_occurrence = 1L
      )
    if (
      any(grid$expected_wall_minutes != 30L) ||
        any(
          grid$bin_admissible !=
            (
              grid$valid_medi_wall_minutes >= 15L &
                is.finite(grid$arithmetic_mean_medi_lx)
            )
        )
    ) {
      h06d_abort("Primary 30-minute support contract changed")
    }
  } else {
    grid <- readRDS(file.path(
      root,
      paste0(
        "artifacts/06_model_data/scenarios/",
        "manuscript_prepared_data/thirty_minute_data.rds"
      )
    )) |>
      dplyr::filter(.data$position == .env$position) |>
      dplyr::transmute(
        data_scenario_id = "gap_timing_unaware",
        site = as.character(.data$site),
        Id = as.character(.data$Id),
        position = as.character(.data$position),
        local_date = as.Date(.data$local_date),
        clock_bin = h06d_h02_clock_bin_from_proxy(
          .data$local_clock_datetime_utc_proxy
        ),
        arithmetic_mean_medi_lx = as.numeric(
          .data$medi_arithmetic_mean_lx
        ),
        bin_admissible = is.finite(.data$medi_arithmetic_mean_lx),
        expected_wall_minutes = NA_integer_,
        valid_medi_wall_minutes = NA_integer_,
        support_available = FALSE,
        local_occurrence = as.integer(.data$local_occurrence)
      )
    if (
      any(grid$local_occurrence != 1L) ||
        any(!grid$clock_bin %in% seq.int(0L, 1410L, by = 30L))
    ) {
      h06d_abort("Gap-timing-unaware 30-minute clock contract changed")
    }
  }

  key <- h06d_h02_production_key()
  h06d_assert_unique(grid, key, paste(data_scenario_id, position, "grid"))

  output <- grid |>
    h06d_join_day_context(diaries) |>
    dplyr::left_join(
      h06d_temporal_links(root),
      by = key,
      relationship = "one-to-one"
    ) |>
    dplyr::filter(
      .data$bin_admissible,
      is.finite(.data$arithmetic_mean_medi_lx),
      .data$arithmetic_mean_medi_lx >= 0,
      !is.na(.data$work_free_day),
      !is.na(.data$activity_status),
      is.finite(.data$previous_sleep_duration_h)
    )

  if (nrow(output) == 0L) {
    h06d_abort("Empty production grid for %s/%s", data_scenario_id, position)
  }
  h06d_assert_unique(
    output,
    key,
    paste(data_scenario_id, position, "complete-context grid")
  )
  output
}

h06d_h02_finalize_production_frame <- function(raw, root, run) {
  stopifnot(nrow(run) == 1L)
  day_sleep <- raw |>
    dplyr::distinct(
      .data$site,
      .data$Id,
      .data$local_date,
      .data$previous_sleep_duration_h
    ) |>
    dplyr::mutate(
      participant_key = paste(.data$site, .data$Id, sep = "::"),
      participant_day_key = paste(
        .data$site,
        .data$Id,
        .data$local_date,
        sep = "::"
      )
    )
  h06d_assert_unique(
    day_sleep,
    c("participant_key", "participant_day_key"),
    paste(run$run_id, "fitted-day sleep values")
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
    dplyr::mutate(
      participant_key = paste(.data$site, .data$Id, sep = "::"),
      participant_day_key = paste(
        .data$site,
        .data$Id,
        .data$local_date,
        sep = "::"
      )
    ) |>
    dplyr::left_join(
      person_sleep,
      by = "participant_key",
      relationship = "many-to-one"
    ) |>
    dplyr::mutate(
      run_id = run$run_id,
      data_scenario_label = run$data_scenario_label,
      placement_id = run$placement_id,
      placement = run$placement_label,
      sample_scenario = run$sample_scenario,
      analytical_role = run$analytical_role,
      multiplicity_role = run$multiplicity_role,
      sleep_between_h =
        .data$sleep_person_mean_h - .env$sleep_grand_mean_h,
      sleep_within_h =
        .data$previous_sleep_duration_h - .data$sleep_person_mean_h,
      response = log10(.data$arithmetic_mean_medi_lx + 0.1),
      time_hour = (.data$clock_bin + 15) / 60
    ) |>
    h06d_assign_temporal_sequences() |>
    dplyr::mutate(
      site = factor(.data$site, levels = h06d_site_levels(root)),
      participant = factor(.data$participant_key),
      participant_day = factor(.data$participant_day_key),
      work_free_day = factor(
        as.character(.data$work_free_day),
        levels = c("Work day", "Free day")
      ),
      activity_status = factor(
        as.character(.data$activity_status),
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
  primary <- identical(run$data_scenario_id, "primary")
  if (
    any(!is.finite(output$response)) ||
      any(output$time_hour <= 0 | output$time_hour >= 24) ||
      anyNA(output$source_utc_start) ||
      anyNA(output$source_utc_end) ||
      anyNA(output$one_to_one_elapsed_coordinate) ||
      max(abs(within_check$mean_within_h)) > 1e-10 ||
      dplyr::n_distinct(output$site) < 5L ||
      !identical(levels(output$work_free_day), c("Work day", "Free day")) ||
      !identical(levels(output$activity_status), c("Sedentary", "Active")) ||
      (primary && any(output$valid_medi_wall_minutes < 15L)) ||
      (!primary && any(output$support_available))
  ) {
    h06d_abort("Production frame contract failed for %s", run$run_id)
  }

  attr(output, "sleep_grand_mean_h") <- sleep_grand_mean_h
  output
}

h06d_h02_production_frames <- function(root, diaries = h06d_load_diaries(root)) {
  registry <- h06d_h02_production_registry()
  primary_raw <- list(
    near_eye = h06d_h02_production_raw_grid(
      root, "primary", "near_eye", diaries
    ),
    chest = h06d_h02_production_raw_grid(
      root, "primary", "chest", diaries
    )
  )
  paired_key <- h06d_h02_production_key(include_position = FALSE)
  common <- dplyr::inner_join(
    dplyr::distinct(primary_raw$near_eye, dplyr::across(dplyr::all_of(paired_key))),
    dplyr::distinct(primary_raw$chest, dplyr::across(dplyr::all_of(paired_key))),
    by = paired_key,
    relationship = "one-to-one"
  )
  if (nrow(common) == 0L) {
    h06d_abort("Primary paired/common production sample is empty")
  }

  raw_by_run <- list(
    primary__near_eye__all_available = primary_raw$near_eye,
    primary__chest__all_available = primary_raw$chest,
    primary__near_eye__paired_common = dplyr::semi_join(
      primary_raw$near_eye, common, by = paired_key
    ),
    primary__chest__paired_common = dplyr::semi_join(
      primary_raw$chest, common, by = paired_key
    ),
    gap_timing_unaware__near_eye__all_available =
      h06d_h02_production_raw_grid(
        root, "gap_timing_unaware", "near_eye", diaries
      ),
    gap_timing_unaware__chest__all_available =
      h06d_h02_production_raw_grid(
        root, "gap_timing_unaware", "chest", diaries
      )
  )

  frames <- lapply(registry$run_id, function(run_id) {
    h06d_h02_finalize_production_frame(
      raw_by_run[[run_id]],
      root,
      dplyr::filter(registry, .data$run_id == .env$run_id)
    )
  })
  names(frames) <- registry$run_id

  near_keys <- dplyr::distinct(
    frames$primary__near_eye__paired_common,
    dplyr::across(dplyr::all_of(paired_key))
  )
  chest_keys <- dplyr::distinct(
    frames$primary__chest__paired_common,
    dplyr::across(dplyr::all_of(paired_key))
  )
  if (!isTRUE(all.equal(near_keys, chest_keys, tolerance = 0))) {
    h06d_abort("Paired/common near-eye and chest bin keys differ")
  }
  frames
}

h06d_h02_production_support <- function(frames) {
  registry <- h06d_h02_production_registry()
  overall <- dplyr::bind_rows(lapply(names(frames), function(run_id) {
    frame <- frames[[run_id]]
    tibble::tibble(
      run_id = run_id,
      observations_30_minute = nrow(frame),
      participant_days = dplyr::n_distinct(frame$participant_day_key),
      participants = dplyr::n_distinct(frame$participant_key),
      sites = dplyr::n_distinct(frame$site),
      exact_zero_bins = sum(frame$arithmetic_mean_medi_lx == 0),
      exact_zero_fraction = mean(frame$arithmetic_mean_medi_lx == 0),
      ar_sequences = sum(frame$AR_start),
      sleep_grand_mean_h = attr(frame, "sleep_grand_mean_h")
    )
  })) |>
    dplyr::left_join(registry, by = "run_id", relationship = "one-to-one") |>
    dplyr::arrange(.data$run_order)

  context_cells <- dplyr::bind_rows(lapply(names(frames), function(run_id) {
    frames[[run_id]] |>
      dplyr::summarise(
        observations_30_minute = dplyr::n(),
        participant_days = dplyr::n_distinct(.data$participant_day_key),
        participants = dplyr::n_distinct(.data$participant_key),
        sites = dplyr::n_distinct(.data$site),
        .by = c("work_free_day", "activity_status")
      ) |>
      dplyr::mutate(run_id = .env$run_id, .before = 1L)
  }))

  sleep_support <- dplyr::bind_rows(lapply(names(frames), function(run_id) {
    frames[[run_id]] |>
      dplyr::distinct(
        .data$site,
        .data$participant_key,
        .data$participant_day_key,
        .data$previous_sleep_duration_h,
        .data$sleep_between_h,
        .data$sleep_within_h,
        .data$sleep_fitted_days,
        .data$sleep_within_sd_h
      ) |>
      dplyr::summarise(
        participant_days = dplyr::n(),
        participants = dplyr::n_distinct(.data$participant_key),
        sleep_min_h = min(.data$previous_sleep_duration_h),
        sleep_median_h = stats::median(.data$previous_sleep_duration_h),
        sleep_max_h = max(.data$previous_sleep_duration_h),
        within_sleep_sd_h = stats::sd(.data$sleep_within_h),
        between_sleep_sd_h = stats::sd(.data$sleep_between_h),
        participants_with_within_variation = dplyr::n_distinct(
          .data$participant_key[.data$sleep_within_sd_h > 0]
        ),
        .by = "site"
      ) |>
      dplyr::mutate(run_id = .env$run_id, .before = 1L)
  }))

  ar_boundaries <- dplyr::bind_rows(lapply(names(frames), function(run_id) {
    frames[[run_id]] |>
      dplyr::count(.data$ar_start_reason, name = "observations") |>
      dplyr::mutate(run_id = .env$run_id, .before = 1L)
  }))

  paired_key <- h06d_h02_production_key(include_position = FALSE)
  paired_near <- frames$primary__near_eye__paired_common
  paired_chest <- frames$primary__chest__paired_common
  paired_audit <- tibble::tibble(
    sample_scenario = "primary paired/common",
    near_eye_observations = nrow(paired_near),
    chest_observations = nrow(paired_chest),
    exact_common_keys = nrow(dplyr::inner_join(
      dplyr::distinct(paired_near, dplyr::across(dplyr::all_of(paired_key))),
      dplyr::distinct(paired_chest, dplyr::across(dplyr::all_of(paired_key))),
      by = paired_key,
      relationship = "one-to-one"
    )),
    keys_identical = isTRUE(all.equal(
      dplyr::distinct(paired_near, dplyr::across(dplyr::all_of(paired_key))),
      dplyr::distinct(paired_chest, dplyr::across(dplyr::all_of(paired_key))),
      tolerance = 0
    ))
  )

  list(
    registry = registry,
    overall = overall,
    context_cells = context_cells,
    sleep_support = sleep_support,
    ar_boundaries = ar_boundaries,
    paired_audit = paired_audit
  )
}
