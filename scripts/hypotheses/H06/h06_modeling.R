h06_clock_hour <- function(x) {
  as.numeric(format(x, "%H")) + as.numeric(format(x, "%M")) / 60
}

h06_prepare_diaries <- function(exercise_raw, sleep_raw) {
  intensity_levels <- h06_exercise_intensity_levels()
  activity_levels <- h06_activity_levels()
  exercise_day <- exercise_raw |>
    dplyr::transmute(
      site,
      Id,
      local_date = as.Date(Date),
      exercise_intensity = dplyr::recode(
        as.character(intensity),
        "None of the above, I did not perform any type of physical activity" = "No exercise",
        "Light (causing small to no increases in heart rate and breathing, e.g. taking a stroll in the park)" = "Light",
        "Moderate (causing moderate increases in heart rate and breathing, e.g. cycling in the city)" = "Moderate",
        "Vigorous (causing large increases in heart rate and breathing, e.g. running)" = "Vigorous"
      ) |>
        factor(levels = intensity_levels),
      activity_status = dplyr::case_when(
        is.na(exercise_intensity) ~ NA_character_,
        exercise_intensity == "No exercise" ~ activity_levels[[1L]],
        TRUE ~ activity_levels[[2L]]
      ) |>
        factor(levels = activity_levels),
      exercise_location = dplyr::recode(
        as.character(location),
        "Outdoors (e.g. running, cycling in the city)" = "Outdoors",
        "Indoors (e.g. gym or home workout)" = "Indoors",
        "Both indoors and outdoors" = "Indoors and outdoors"
      ) |>
        factor(levels = c("Outdoors", "Indoors", "Indoors and outdoors")),
      active_commute_h = as.numeric(commute, units = "hours"),
      sedentary_source_minutes = as.numeric(sedentary, units = "mins"),
      sedentary_h_as_recorded = as.numeric(sedentary, units = "hours"),
      sedentary_h = dplyr::if_else(
        site == "KNUST" &
          Id == "KNUST_S005" &
          local_date == as.Date("2024-11-04") &
          sedentary_source_minutes == 3600,
        1,
        sedentary_h_as_recorded
      ),
      sedentary_reinterpretation = dplyr::if_else(
        site == "KNUST" &
          Id == "KNUST_S005" &
          local_date == as.Date("2024-11-04") &
          sedentary_source_minutes == 3600,
        "Source numeral interpreted as 3,600 seconds (1 h)",
        NA_character_
      ),
      wore_light_logger_during_exercise = factor(
        light_glasses,
        levels = c(0, 1),
        labels = c("No", "Yes")
      ),
      exercise_source_row = source_row
    )
  sleep_day <- sleep_raw |>
    dplyr::transmute(
      site,
      Id,
      local_date = as.Date(wake_wall),
      work_free_day = factor(
        as.character(daytype2),
        levels = c("a work day", "a free day"),
        labels = c("Work day", "Free day")
      ),
      previous_sleep_duration_h = as.numeric(sleep_duration, units = "hours"),
      previous_sleep_duration_centered_h = previous_sleep_duration_h - 8,
      previous_sleep_onset_clock_h = h06_clock_hour(sleep_onset_wall),
      previous_sleep_onset_after_noon_h = (previous_sleep_onset_clock_h - 12) %%
        24,
      previous_sleep_onset_centered_h = previous_sleep_onset_after_noon_h - 11,
      wake_clock_h = h06_clock_hour(wake_wall),
      wake_centered_h = wake_clock_h - 7,
      sleep_onset_date = as.Date(sleep_onset_wall),
      sleep_interval_analysis_eligible,
      sleep_interval_quarantined,
      sleep_source_row = source_row
    )
  exercise_duplicates <- exercise_day |>
    dplyr::count(site, Id, local_date, name = "rows") |>
    dplyr::filter(rows != 1L)
  sleep_duplicates <- sleep_day |>
    dplyr::filter(!is.na(local_date)) |>
    dplyr::count(site, Id, local_date, name = "rows") |>
    dplyr::filter(rows != 1L)
  sedentary_reinterpreted <- exercise_day |>
    dplyr::filter(!is.na(sedentary_reinterpretation))
  if (
    nrow(exercise_duplicates) != 0L ||
      nrow(sleep_duplicates) != 0L ||
      nrow(sedentary_reinterpreted) != 1L ||
      sedentary_reinterpreted$sedentary_source_minutes != 3600 ||
      sedentary_reinterpreted$sedentary_h != 1
  ) {
    h06_abort(
      "The H06 diary uniqueness or unit-conversion check failed"
    )
  }
  list(
    exercise_day = exercise_day,
    sleep_day = sleep_day,
    sedentary_reinterpreted = sedentary_reinterpreted
  )
}

h06_prepare_temporal_provenance <- function(provenance) {
  output <- provenance |>
    dplyr::filter(
      resolution == "one_hour",
      outcome_metric == "one_hour_zero_aware_geometric_mean_medi"
    ) |>
    dplyr::transmute(
      site,
      Id,
      position,
      local_date = as.Date(local_date),
      clock_minute = as.integer(wall_bin_start_minute),
      source_bin_links = as.integer(source_bin_links),
      utc_start = as.POSIXct(
        source_utc_start,
        format = "%Y-%m-%dT%H:%M:%SZ",
        tz = "UTC"
      ),
      utc_end = as.POSIXct(
        source_utc_end,
        format = "%Y-%m-%dT%H:%M:%SZ",
        tz = "UTC"
      ),
      local_day_type,
      relationship_type,
      one_to_one_elapsed_coordinate = as.logical(one_to_one_elapsed_coordinate),
      temporal_outcome_usable = as.logical(outcome_usable)
    )
  key <- output[c("site", "Id", "position", "local_date", "clock_minute")]
  if (anyDuplicated(key)) {
    h06_abort("The one-hour temporal provenance key is not unique")
  }
  output
}

h06_join_diaries <- function(rows, diaries) {
  rows |>
    dplyr::left_join(
      diaries$sleep_day |>
        dplyr::select(-sleep_onset_date),
      by = c("site", "Id", "local_date"),
      relationship = "many-to-one"
    ) |>
    dplyr::left_join(
      diaries$exercise_day,
      by = c("site", "Id", "local_date"),
      relationship = "many-to-one"
    ) |>
    dplyr::mutate(
      weekday_weekend = factor(
        ifelse(
          as.POSIXlt(local_date)$wday %in% c(0L, 6L),
          "Weekend",
          "Weekday"
        ),
        levels = c("Weekday", "Weekend")
      )
    )
}

h06_prepare_main_hour <- function(hour_data, placement, diaries) {
  if (
    length(unique(hour_data$zero_offset)) != 1L ||
      !isTRUE(all.equal(unique(hour_data$zero_offset), 0.1))
  ) {
    h06_abort("The H06 one-hour zero offset is not the specified 0.1 lx")
  }
  hour_data |>
    dplyr::filter(
      bin_admissible,
      is.finite(zero_aware_geometric_mean_medi_lx)
    ) |>
    dplyr::transmute(
      data_scenario_id = "main",
      placement = placement,
      position,
      site,
      Id,
      local_date = as.Date(local_date),
      clock_minute = as.integer(clock_minute),
      clock_hour = (clock_minute + 30) / 60,
      response_value = zero_aware_geometric_mean_medi_lx,
      zero_offset = zero_offset,
      log10_melEDI_offset = log10(response_value + zero_offset),
      valid_medi_wall_minutes,
      photoperiod_hours
    ) |>
    h06_join_diaries(diaries) |>
    dplyr::filter(
      !is.na(work_free_day),
      !is.na(activity_status),
      is.finite(previous_sleep_duration_centered_h)
    )
}

h06_prepare_gap_hour <- function(hour_data, placement, diaries) {
  position_value <- if (placement == "glasses") "glasses" else "chest"
  hour_data |>
    dplyr::filter(
      position == position_value,
      is.finite(medi_geometric_mean_lx)
    ) |>
    dplyr::transmute(
      data_scenario_id = "gap_timing_unaware",
      placement = placement,
      position,
      site,
      Id,
      local_date = as.Date(local_date),
      clock_minute = as.integer(
        as.numeric(format(local_clock_datetime_utc_proxy, "%H")) *
          60 +
          as.numeric(format(local_clock_datetime_utc_proxy, "%M"))
      ),
      clock_hour = (clock_minute + 30) / 60,
      response_value = medi_geometric_mean_lx,
      zero_offset = 0.1,
      log10_melEDI_offset = log10(response_value + zero_offset),
      valid_medi_wall_minutes = NA_real_,
      photoperiod_hours = as.numeric(difftime(
        dusk_local_clock_utc_proxy,
        dawn_local_clock_utc_proxy,
        units = "hours"
      ))
    ) |>
    h06_join_diaries(diaries) |>
    dplyr::filter(
      !is.na(work_free_day),
      !is.na(activity_status),
      is.finite(previous_sleep_duration_centered_h)
    )
}

h06_add_true_time_sequences <- function(rows, temporal, site_levels) {
  before <- nrow(rows)
  output <- rows |>
    dplyr::left_join(
      temporal,
      by = c("site", "Id", "position", "local_date", "clock_minute"),
      relationship = "many-to-one"
    )
  if (
    nrow(output) != before ||
      anyNA(output$utc_start) ||
      anyNA(output$utc_end) ||
      any(!output$temporal_outcome_usable)
  ) {
    h06_abort(
      "An H06 model row lacks a unique usable true-time provenance link"
    )
  }
  output <- output |>
    dplyr::mutate(
      participant_key = paste(site, Id, sep = "::"),
      participant_day_key = paste(site, Id, local_date, sep = "::"),
      interval_seconds = as.numeric(difftime(
        utc_end,
        utc_start,
        units = "secs"
      )),
      irregular_elapsed_bin = !one_to_one_elapsed_coordinate |
        abs(interval_seconds - 3600) > 1e-6
    ) |>
    dplyr::arrange(placement, site, Id, local_date, utc_start) |>
    dplyr::group_by(placement, participant_day_key) |>
    dplyr::mutate(
      elapsed_gap_seconds = as.numeric(difftime(
        utc_start,
        dplyr::lag(utc_end),
        units = "secs"
      )),
      sequence_break = dplyr::row_number() == 1L |
        irregular_elapsed_bin |
        dplyr::lag(irregular_elapsed_bin, default = TRUE) |
        (!is.na(elapsed_gap_seconds) & abs(elapsed_gap_seconds) > 1e-6),
      sequence_number = cumsum(sequence_break)
    ) |>
    dplyr::ungroup() |>
    dplyr::mutate(
      hour_sequence_id = paste(participant_day_key, sequence_number, sep = "::")
    ) |>
    dplyr::group_by(placement, hour_sequence_id) |>
    dplyr::mutate(
      hour_sequence_position = dplyr::row_number(),
      AR_start = dplyr::row_number() == 1L
    ) |>
    dplyr::ungroup()
  max_position <- max(output$hour_sequence_position)
  output <- output |>
    dplyr::mutate(
      site = droplevels(factor(site, levels = site_levels)),
      participant_key = factor(participant_key),
      participant_day_key = factor(participant_day_key),
      hour_sequence_id = factor(hour_sequence_id),
      hour_index_factor = factor(
        hour_sequence_position,
        levels = seq_len(max_position)
      ),
      .model_row_id = paste(
        data_scenario_id,
        placement,
        site,
        Id,
        local_date,
        sprintf("%04d", clock_minute),
        sep = "::"
      )
    )
  if (anyDuplicated(output$.model_row_id)) {
    h06_abort("The H06 hourly model-row identifier is not unique")
  }
  output
}

h06_refactor_frame <- function(frame) {
  if (nrow(frame) == 0L) {
    return(frame)
  }
  max_position <- max(frame$hour_sequence_position)
  frame |>
    dplyr::arrange(site, Id, local_date, utc_start) |>
    dplyr::mutate(
      site = droplevels(site),
      work_free_day = droplevels(work_free_day),
      activity_status = droplevels(activity_status),
      weekday_weekend = droplevels(weekday_weekend),
      exercise_location = droplevels(exercise_location),
      participant_key = droplevels(participant_key),
      participant_day_key = droplevels(participant_day_key),
      hour_sequence_id = droplevels(hour_sequence_id),
      hour_index_factor = factor(
        hour_sequence_position,
        levels = seq_len(max_position)
      )
    )
}


h06_exact_common_hour_frames <- function(reference, alternative) {
  key_columns <- c("site", "Id", "local_date", "clock_minute")
  missing_reference <- setdiff(key_columns, names(reference))
  missing_alternative <- setdiff(key_columns, names(alternative))
  if (length(missing_reference) > 0L || length(missing_alternative) > 0L) {
    h06_abort("An H06 exact-common-hour frame lacks required key columns")
  }
  reference_keys <- reference |>
    dplyr::distinct(dplyr::across(dplyr::all_of(key_columns)))
  alternative_keys <- alternative |>
    dplyr::distinct(dplyr::across(dplyr::all_of(key_columns)))
  if (
    nrow(reference_keys) != nrow(reference) ||
      nrow(alternative_keys) != nrow(alternative)
  ) {
    h06_abort("An H06 hourly comparison key is not unique")
  }
  common_keys <- dplyr::inner_join(
    reference_keys,
    alternative_keys,
    by = key_columns,
    relationship = "one-to-one"
  )
  reference_common <- reference |>
    dplyr::semi_join(common_keys, by = key_columns) |>
    h06_refactor_frame()
  alternative_common <- alternative |>
    dplyr::semi_join(common_keys, by = key_columns) |>
    h06_refactor_frame()
  reference_common_keys <- reference_common |>
    dplyr::arrange(dplyr::across(dplyr::all_of(key_columns))) |>
    dplyr::select(dplyr::all_of(key_columns)) |>
    dplyr::mutate(dplyr::across(dplyr::everything(), as.character))
  alternative_common_keys <- alternative_common |>
    dplyr::arrange(dplyr::across(dplyr::all_of(key_columns))) |>
    dplyr::select(dplyr::all_of(key_columns)) |>
    dplyr::mutate(dplyr::across(dplyr::everything(), as.character))
  if (!identical(reference_common_keys, alternative_common_keys)) {
    h06_abort("The H06 exact-common-hour comparison frames do not share keys")
  }
  list(
    reference = reference_common,
    alternative = alternative_common,
    common_keys = common_keys,
    summary = tibble::tibble(
      primary_all_hours = nrow(reference),
      gap_timing_unaware_all_hours = nrow(alternative),
      exact_common_hours = nrow(common_keys),
      primary_only_hours = nrow(reference) - nrow(common_keys),
      gap_timing_unaware_only_hours = nrow(alternative) - nrow(common_keys),
      exact_common_participant_days = dplyr::n_distinct(
        reference_common$participant_day_key
      ),
      exact_common_participants = dplyr::n_distinct(
        reference_common$participant_key
      ),
      exact_common_sites = dplyr::n_distinct(reference_common$site)
    )
  )
}

h06_capture_fit <- function(expression) {
  warnings <- character()
  elapsed <- system.time({
    model <- tryCatch(
      withCallingHandlers(
        expression,
        warning = function(condition) {
          warnings <<- c(warnings, conditionMessage(condition))
          invokeRestart("muffleWarning")
        }
      ),
      error = function(condition) condition
    )
  })[["elapsed"]]
  if (inherits(model, "error")) {
    return(list(
      model = NULL,
      warnings = unique(warnings),
      error = conditionMessage(model),
      elapsed_seconds = as.numeric(elapsed)
    ))
  }
  list(
    model = model,
    warnings = unique(warnings),
    error = NA_character_,
    elapsed_seconds = as.numeric(elapsed)
  )
}

h06_adjust_complete_family <- function(data, planned_size = 3L) {
  if (nrow(data) != planned_size) {
    h06_abort(
      "An H06 multiplicity family does not contain its planned %d rows",
      planned_size
    )
  }
  available <- which(is.finite(data$raw_p))
  adjusted <- rep(NA_real_, nrow(data))
  if (length(available) > 0L) {
    adjusted[available] <- stats::p.adjust(
      data$raw_p[available],
      method = "BH",
      n = planned_size
    )
  }
  data |>
    dplyr::mutate(
      planned_size = planned_size,
      available_rank = dplyr::if_else(
        is.finite(.data$raw_p),
        rank(.data$raw_p, ties.method = "min", na.last = "keep"),
        NA_real_
      ),
      adjustment_method = "Benjamini-Hochberg",
      adjusted_p = adjusted
    )
}

h06_sample_summary <- function(frame, run_id) {
  hours_per_day <- frame |>
    dplyr::count(participant_day_key, name = "supported_hours")
  tibble::tibble(
    run_id = run_id,
    one_hour_observations = nrow(frame),
    participant_days = dplyr::n_distinct(frame$participant_day_key),
    participants = dplyr::n_distinct(frame$participant_key),
    sites = dplyr::n_distinct(frame$site),
    true_time_sequences = dplyr::n_distinct(frame$hour_sequence_id),
    minimum_supported_hours_per_day = min(hours_per_day$supported_hours),
    median_supported_hours_per_day = stats::median(
      hours_per_day$supported_hours
    ),
    maximum_supported_hours_per_day = max(hours_per_day$supported_hours)
  )
}

h06_category_cells <- function(frame, run_id) {
  day <- frame |>
    dplyr::summarise(
      one_hour_observations = dplyr::n(),
      participant_days = dplyr::n_distinct(participant_day_key),
      participants = dplyr::n_distinct(participant_key),
      .by = c(site, work_free_day)
    ) |>
    dplyr::transmute(
      run_id = run_id,
      cell_type = "work_free_day",
      site = as.character(site),
      category = as.character(work_free_day),
      one_hour_observations,
      participant_days,
      participants
    )
  activity <- frame |>
    dplyr::summarise(
      one_hour_observations = dplyr::n(),
      participant_days = dplyr::n_distinct(participant_day_key),
      participants = dplyr::n_distinct(participant_key),
      .by = c(site, activity_status)
    ) |>
    dplyr::transmute(
      run_id = run_id,
      cell_type = "activity_status",
      site = as.character(site),
      category = as.character(activity_status),
      one_hour_observations,
      participant_days,
      participants
    )
  dplyr::bind_rows(day, activity)
}

h06_design_diagnostics <- function(frame, run_id) {
  formula <- h06_formula_set()$full
  matrix <- stats::model.matrix(
    formula,
    data = frame,
    contrasts.arg = list(site = "contr.sum")
  )
  scaled_continuous <- frame |>
    dplyr::distinct(
      participant_day_key,
      previous_sleep_duration_centered_h,
      work_free_day,
      activity_status,
      site
    )
  predictor_matrix <- stats::model.matrix(
    ~ site +
      work_free_day +
      activity_status +
      previous_sleep_duration_centered_h,
    data = scaled_continuous,
    contrasts.arg = list(site = "contr.sum")
  )
  correlations <- suppressWarnings(stats::cor(predictor_matrix[,
    -1L,
    drop = FALSE
  ]))
  tibble::tibble(
    run_id = run_id,
    design_columns = ncol(matrix),
    design_rank = qr(matrix)$rank,
    full_rank = qr(matrix)$rank == ncol(matrix),
    maximum_absolute_predictor_correlation = max(
      abs(correlations[upper.tri(correlations)]),
      na.rm = TRUE
    ),
    work_day_reference = levels(frame$work_free_day)[[1L]],
    sedentary_reference = levels(frame$activity_status)[[1L]],
    site_contrast = "contr.sum"
  )
}

h06_build_run_frames <- function(
  near_main,
  chest_main,
  gap_hour,
  exercise_raw,
  sleep_raw,
  temporal_raw,
  site_levels
) {
  diaries <- h06_prepare_diaries(exercise_raw, sleep_raw)
  temporal <- h06_prepare_temporal_provenance(temporal_raw)
  all_frames <- list(
    main__glasses = h06_prepare_main_hour(
      near_main,
      "glasses",
      diaries
    ) |>
      h06_add_true_time_sequences(temporal, site_levels),
    main__chest = h06_prepare_main_hour(
      chest_main,
      "chest",
      diaries
    ) |>
      h06_add_true_time_sequences(temporal, site_levels),
    gap_timing_unaware__glasses = h06_prepare_gap_hour(
      gap_hour,
      "glasses",
      diaries
    ) |>
      h06_add_true_time_sequences(temporal, site_levels),
    gap_timing_unaware__chest = h06_prepare_gap_hour(
      gap_hour,
      "chest",
      diaries
    ) |>
      h06_add_true_time_sequences(temporal, site_levels)
  )
  paired_days <- intersect(
    unique(as.character(all_frames$main__glasses$participant_day_key)),
    unique(as.character(all_frames$main__chest$participant_day_key))
  )
  runs <- list(
    main__glasses__all_available = all_frames$main__glasses,
    main__chest__all_available = all_frames$main__chest,
    main__glasses__paired_common = all_frames$main__glasses |>
      dplyr::filter(as.character(participant_day_key) %in% paired_days) |>
      h06_refactor_frame(),
    main__chest__paired_common = all_frames$main__chest |>
      dplyr::filter(as.character(participant_day_key) %in% paired_days) |>
      h06_refactor_frame(),
    gap_timing_unaware__glasses__all_available = all_frames$gap_timing_unaware__glasses,
    gap_timing_unaware__chest__all_available = all_frames$gap_timing_unaware__chest
  )
  expected <- h06_run_registry()$run_id
  if (!identical(names(runs), expected)) {
    h06_abort(
      "The constructed H06 run order differs from the run registry"
    )
  }
  list(
    runs = runs,
    all_frames = all_frames,
    paired_days = paired_days,
    diaries = diaries,
    temporal = temporal
  )
}

h06_candidate_flow <- function(
  hour_data,
  placement,
  data_scenario_id,
  diaries
) {
  if (data_scenario_id == "main") {
    base <- hour_data |>
      dplyr::transmute(
        site,
        Id,
        local_date = as.Date(local_date),
        outcome_available = bin_admissible &
          is.finite(zero_aware_geometric_mean_medi_lx)
      )
  } else {
    position_value <- if (placement == "glasses") "glasses" else "chest"
    base <- hour_data |>
      dplyr::filter(position == position_value) |>
      dplyr::transmute(
        site,
        Id,
        local_date = as.Date(local_date),
        outcome_available = is.finite(medi_geometric_mean_lx)
      )
  }
  joined <- base |>
    dplyr::filter(outcome_available) |>
    h06_join_diaries(diaries) |>
    dplyr::mutate(
      work_free_available = !is.na(work_free_day),
      activity_available = !is.na(activity_status),
      previous_sleep_duration_available = is.finite(
        previous_sleep_duration_centered_h
      )
    )
  stages <- list(
    source_one_hour_rows = rep(TRUE, nrow(base)),
    admissible_outcome = base$outcome_available,
    plus_work_free_day = joined$work_free_available,
    plus_binary_activity = joined$work_free_available &
      joined$activity_available,
    complete_three_core_predictors = joined$work_free_available &
      joined$activity_available &
      joined$previous_sleep_duration_available
  )
  counts <- c(
    length(stages$source_one_hour_rows),
    sum(stages$admissible_outcome),
    sum(stages$plus_work_free_day),
    sum(stages$plus_binary_activity),
    sum(stages$complete_three_core_predictors)
  )
  flow <- tibble::tibble(
    data_scenario_id = data_scenario_id,
    placement = placement,
    flow_order = seq_along(stages),
    flow_stage = names(stages),
    one_hour_observations = counts,
    removed_at_stage = c(NA_integer_, -diff(counts))
  )
  fields <- joined |>
    dplyr::summarise(
      admissible_outcome_rows = dplyr::n(),
      missing_work_free_day = sum(!work_free_available),
      missing_binary_activity = sum(!activity_available),
      missing_previous_sleep_duration = sum(!previous_sleep_duration_available),
      complete_three_core_predictors = sum(
        work_free_available &
          activity_available &
          previous_sleep_duration_available
      )
    ) |>
    dplyr::mutate(
      data_scenario_id = data_scenario_id,
      placement = placement,
      .before = 1L
    )
  list(flow = flow, fields = fields)
}

h06_sleep_linkage_audit <- function(sleep_raw) {
  sleep_raw |>
    dplyr::mutate(
      wake_date = as.Date(wake_wall),
      onset_date = as.Date(sleep_onset_wall),
      onset_to_wake_date_relation = dplyr::case_when(
        is.na(wake_date) | is.na(onset_date) ~ "unavailable",
        onset_date == wake_date ~ "onset_on_wake_date_after_midnight",
        onset_date == wake_date - 1L ~ "onset_on_preceding_date",
        TRUE ~ "other_date_relation"
      )
    ) |>
    dplyr::summarise(
      diary_rows = dplyr::n(),
      quarantined_rows = sum(sleep_interval_quarantined %in% TRUE),
      analysis_eligible_rows = sum(sleep_interval_analysis_eligible %in% TRUE),
      .by = onset_to_wake_date_relation
    ) |>
    dplyr::arrange(factor(
      onset_to_wake_date_relation,
      levels = c(
        "onset_on_wake_date_after_midnight",
        "onset_on_preceding_date",
        "unavailable",
        "other_date_relation"
      )
    ))
}

h06_exploratory_variable <- function(analysis_id) {
  switch(
    analysis_id,
    exercise_location_active_days = "exercise_location",
    active_travel = "active_commute_h",
    sedentary_time = "sedentary_h",
    previous_sleep_onset = "previous_sleep_onset_centered_h",
    final_wake = "wake_centered_h",
    h06_abort("Unknown H06 exploratory analysis: %s", analysis_id)
  )
}

h06_exploratory_frame <- function(frame, analysis_id) {
  variable <- h06_exploratory_variable(analysis_id)
  output <- frame |>
    dplyr::filter(!is.na(.data[[variable]]))
  if (analysis_id == "exercise_location_active_days") {
    output <- output |>
      dplyr::filter(
        activity_status == h06_activity_levels()[[2L]],
        !is.na(exercise_location)
      )
  }
  h06_refactor_frame(output)
}

h06_extreme_exploratory_records <- function(frame) {
  day <- frame |>
    dplyr::distinct(
      site,
      Id,
      participant_key,
      local_date,
      active_commute_h,
      sedentary_source_minutes,
      sedentary_h,
      sedentary_reinterpretation
    )
  dplyr::bind_rows(
    day |>
      dplyr::filter(is.finite(active_commute_h)) |>
      dplyr::slice_max(active_commute_h, n = 5L, with_ties = FALSE) |>
      dplyr::transmute(
        record_type = "largest_active_travel",
        site,
        Id,
        local_date,
        source_value = active_commute_h,
        analysis_value = active_commute_h,
        unit = "hours"
      ),
    day |>
      dplyr::filter(is.finite(sedentary_h)) |>
      dplyr::slice_max(sedentary_h, n = 5L, with_ties = FALSE) |>
      dplyr::transmute(
        record_type = "largest_sedentary_time_after_H06_adapter",
        site,
        Id,
        local_date,
        source_value = sedentary_source_minutes,
        analysis_value = sedentary_h,
        unit = "source minutes / analysis hours"
      ),
    day |>
      dplyr::filter(!is.na(sedentary_reinterpretation)) |>
      dplyr::transmute(
        record_type = "KNUST_duration_unit_interpretation",
        site,
        Id,
        local_date,
        source_value = sedentary_source_minutes,
        analysis_value = sedentary_h,
        unit = "source minutes label / analysis hours"
      )
  )
}
