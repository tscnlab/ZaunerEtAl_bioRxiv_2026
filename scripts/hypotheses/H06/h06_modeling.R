# Prepare, fit, diagnose, and summarize the approved H06 Stage 2 models.

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
        "Author-approved: source numeral interpreted as 3,600 seconds (1 h)",
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
  tum_dates <- as.Date("2024-05-13") + 0:6
  tum_correction <- exercise_raw |>
    dplyr::filter(
      site == "TUM",
      Date %in% tum_dates,
      Id %in% c("TUM_S001", "TUM_S101")
    ) |>
    dplyr::count(Id, Date, name = "diary_rows") |>
    dplyr::arrange(Date)
  if (
    nrow(exercise_duplicates) != 0L ||
      nrow(sleep_duplicates) != 0L ||
      nrow(sedentary_reinterpreted) != 1L ||
      sedentary_reinterpreted$sedentary_source_minutes != 3600 ||
      sedentary_reinterpreted$sedentary_h != 1 ||
      nrow(tum_correction) != 7L ||
      any(tum_correction$Id != "TUM_S001") ||
      sum(exercise_raw$site == "TUM" & exercise_raw$Id == "TUM_S101") != 0L
  ) {
    h06_abort(
      "The H06 diary identity, uniqueness, or reinterpretation gate failed"
    )
  }
  list(
    exercise_day = exercise_day,
    sleep_day = sleep_day,
    tum_correction = tum_correction,
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
    h06_abort("The H06 one-hour zero offset is not the approved 0.1 lx")
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

h06_model_frame_hash <- function(frame) {
  digest::digest(
    list(
      row_id = frame$.model_row_id,
      response = frame$response_value,
      site = as.character(frame$site),
      work_free_day = as.character(frame$work_free_day),
      activity_status = as.character(frame$activity_status),
      previous_sleep_duration_centered_h = frame$previous_sleep_duration_centered_h,
      sequence = as.character(frame$hour_sequence_id),
      sequence_position = frame$hour_sequence_position
    ),
    algo = "sha256",
    serialize = TRUE
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

h06_fit_model <- function(
  frame,
  formula,
  response_family = c("tweedie_log", "gaussian_log10_offset"),
  fixed_site = TRUE
) {
  response_family <- match.arg(response_family)
  if (nrow(frame) == 0L) {
    return(list(
      model = NULL,
      warnings = character(),
      error = "No estimable rows",
      elapsed_seconds = 0
    ))
  }
  data <- frame
  if (response_family == "gaussian_log10_offset") {
    data$response_value <- data$log10_melEDI_offset
  }
  contrasts_argument <- if (fixed_site && nlevels(data$site) > 1L) {
    list(site = "contr.sum")
  } else {
    NULL
  }
  family <- if (response_family == "tweedie_log") {
    glmmTMB::tweedie(link = "log")
  } else {
    stats::gaussian(link = "identity")
  }
  h06_capture_fit(glmmTMB::glmmTMB(
    formula = formula,
    data = data,
    family = family,
    REML = FALSE,
    contrasts = contrasts_argument,
    control = glmmTMB::glmmTMBControl(
      optCtrl = list(iter.max = 10000L, eval.max = 10000L),
      profile = FALSE
    )
  ))
}

h06_fit_core_bundle <- function(frame, comparisons = FALSE, prefit = list()) {
  formulas <- h06_formula_set()
  fits <- list(
    additive = if (!is.null(prefit$additive)) {
      prefit$additive
    } else {
      h06_fit_model(frame, formulas$additive)
    },
    full = if (!is.null(prefit$full)) {
      prefit$full
    } else {
      h06_fit_model(frame, formulas$full)
    }
  )
  if (comparisons) {
    fits$additive_no_daytype <- h06_fit_model(
      frame,
      formulas$additive_no_daytype
    )
    fits$additive_no_activity <- h06_fit_model(
      frame,
      formulas$additive_no_activity
    )
    fits$additive_no_sleep <- h06_fit_model(
      frame,
      formulas$additive_no_sleep
    )
    fits$full_no_daytype_interaction <- h06_fit_model(
      frame,
      formulas$full_no_daytype_interaction
    )
    fits$full_no_activity_interaction <- h06_fit_model(
      frame,
      formulas$full_no_activity_interaction
    )
    fits$full_no_sleep_interaction <- h06_fit_model(
      frame,
      formulas$full_no_sleep_interaction
    )
  }
  list(
    frame_hash = h06_model_frame_hash(frame),
    frame_row_ids = frame$.model_row_id,
    formulas = formulas,
    comparisons = comparisons,
    fits = fits
  )
}

h06_model_fit_status <- function(model) {
  if (is.null(model)) {
    return(tibble::tibble(
      convergence_code = NA_integer_,
      converged = FALSE,
      positive_definite_hessian = FALSE,
      singular = NA,
      max_gradient = NA_real_,
      minimum_fixed_covariance_eigenvalue = NA_real_
    ))
  }
  gradient <- tryCatch(
    max(abs(model$obj$gr(model$fit$par))),
    error = function(error) NA_real_
  )
  fixed_covariance <- tryCatch(
    as.matrix(stats::vcov(model)$cond),
    error = function(error) NULL
  )
  minimum_eigenvalue <- if (
    is.null(fixed_covariance) || any(!is.finite(fixed_covariance))
  ) {
    NA_real_
  } else {
    min(eigen(fixed_covariance, symmetric = TRUE, only.values = TRUE)$values)
  }
  singular <- tryCatch(
    as.logical(performance::check_singularity(model, tolerance = 1e-5))[[1L]],
    error = function(error) NA
  )
  tibble::tibble(
    convergence_code = as.integer(model$fit$convergence),
    converged = isTRUE(model$fit$convergence == 0L),
    positive_definite_hessian = isTRUE(model$sdr$pdHess),
    singular = singular,
    max_gradient = as.numeric(gradient),
    minimum_fixed_covariance_eigenvalue = as.numeric(minimum_eigenvalue)
  )
}

h06_random_parameter_summary <- function(model) {
  empty <- tibble::tibble(
    participant_intercept_sd = NA_real_,
    participant_day_intercept_sd = NA_real_,
    ar1_latent_sd = NA_real_,
    ar1_correlation = NA_real_,
    dispersion = NA_real_,
    tweedie_power = NA_real_
  )
  if (is.null(model)) {
    return(empty)
  }
  conditional <- tryCatch(
    glmmTMB::VarCorr(model)$cond,
    error = function(error) NULL
  )
  get_sd <- function(group) {
    if (is.null(conditional) || !group %in% names(conditional)) {
      return(NA_real_)
    }
    as.numeric(attr(conditional[[group]], "stddev")[[1L]])
  }
  ar_correlation <- tryCatch(
    {
      correlation <- attr(conditional$hour_sequence_id, "correlation")
      if (is.null(correlation) || nrow(correlation) < 2L) {
        NA_real_
      } else {
        as.numeric(correlation[1L, 2L])
      }
    },
    error = function(error) NA_real_
  )
  power <- tryCatch(
    as.numeric(glmmTMB::family_params(model)[[1L]]),
    error = function(error) NA_real_
  )
  tibble::tibble(
    participant_intercept_sd = get_sd("participant_key"),
    participant_day_intercept_sd = get_sd("participant_day_key"),
    ar1_latent_sd = get_sd("hour_sequence_id"),
    ar1_correlation = ar_correlation,
    dispersion = tryCatch(
      as.numeric(stats::sigma(model)),
      error = function(error) NA_real_
    ),
    tweedie_power = power
  )
}

h06_model_manifest_rows <- function(
  bundle,
  run_id,
  response_family = "tweedie_log"
) {
  dplyr::bind_rows(lapply(names(bundle$fits), function(model_id) {
    fit <- bundle$fits[[model_id]]
    model <- fit$model
    formula <- bundle$formulas[[model_id]]
    dplyr::bind_cols(
      tibble::tibble(
        run_id = run_id,
        model_id = model_id,
        response_family = response_family,
        formula = paste(deparse(formula), collapse = " "),
        engine = if (is.null(model)) NA_character_ else class(model)[[1L]],
        observations = if (is.null(model)) NA_integer_ else stats::nobs(model),
        log_likelihood = if (is.null(model)) NA_real_ else
          as.numeric(stats::logLik(model)),
        aic = if (is.null(model)) NA_real_ else stats::AIC(model),
        elapsed_seconds = fit$elapsed_seconds,
        warnings = paste(fit$warnings, collapse = " | "),
        error = fit$error,
        frame_sha256 = bundle$frame_hash
      ),
      h06_model_fit_status(model),
      h06_random_parameter_summary(model)
    )
  }))
}

h06_likelihood_ratio <- function(reduced_fit, full_fit, comparison_id) {
  if (is.null(reduced_fit$model) || is.null(full_fit$model)) {
    reason <- paste(
      stats::na.omit(c(reduced_fit$error, full_fit$error)),
      collapse = " | "
    )
    return(tibble::tibble(
      comparison_id = comparison_id,
      statistic = NA_real_,
      degrees_freedom = NA_real_,
      raw_p = NA_real_,
      non_estimability_reason = ifelse(
        nzchar(reason),
        reason,
        "Model unavailable"
      )
    ))
  }
  if (stats::nobs(reduced_fit$model) != stats::nobs(full_fit$model)) {
    h06_abort(
      "The H06 comparison %s does not use an identical frame",
      comparison_id
    )
  }
  result <- tryCatch(
    stats::anova(reduced_fit$model, full_fit$model, test = "LRT"),
    error = function(error) error
  )
  if (inherits(result, "error")) {
    return(tibble::tibble(
      comparison_id = comparison_id,
      statistic = NA_real_,
      degrees_freedom = NA_real_,
      raw_p = NA_real_,
      non_estimability_reason = conditionMessage(result)
    ))
  }
  statistic_column <- grep("Chisq", names(result), value = TRUE)[[1L]]
  p_column <- grep("Pr\\(>Chisq\\)", names(result), value = TRUE)[[1L]]
  df_column <- intersect(c("Df", "df"), names(result))[[1L]]
  tibble::tibble(
    comparison_id = comparison_id,
    statistic = as.numeric(result[[statistic_column]][[2L]]),
    degrees_freedom = abs(diff(as.numeric(result[[df_column]]))),
    raw_p = as.numeric(result[[p_column]][[2L]]),
    non_estimability_reason = NA_character_
  )
}

h06_core_likelihood_tests <- function(
  bundle,
  family_main,
  family_heterogeneity
) {
  if (!isTRUE(bundle$comparisons)) {
    return(tibble::tibble())
  }
  predictor_ids <- c(
    "work_free_day",
    "activity_status",
    "previous_sleep_duration_centered_h"
  )
  main_reduced <- c(
    "additive_no_daytype",
    "additive_no_activity",
    "additive_no_sleep"
  )
  heterogeneity_reduced <- c(
    "full_no_daytype_interaction",
    "full_no_activity_interaction",
    "full_no_sleep_interaction"
  )
  main <- dplyr::bind_rows(lapply(seq_along(predictor_ids), function(index) {
    h06_likelihood_ratio(
      bundle$fits[[main_reduced[[index]]]],
      bundle$fits$additive,
      paste0("main__", predictor_ids[[index]])
    ) |>
      dplyr::mutate(
        family_id = family_main,
        family_member = index,
        predictor_id = predictor_ids[[index]],
        test_role = "main_association"
      )
  }))
  heterogeneity <- dplyr::bind_rows(lapply(
    seq_along(predictor_ids),
    function(index) {
      h06_likelihood_ratio(
        bundle$fits[[heterogeneity_reduced[[index]]]],
        bundle$fits$full,
        paste0("site_heterogeneity__", predictor_ids[[index]])
      ) |>
        dplyr::mutate(
          family_id = family_heterogeneity,
          family_member = index,
          predictor_id = predictor_ids[[index]],
          test_role = "site_heterogeneity"
        )
    }
  ))
  dplyr::bind_rows(main, heterogeneity) |>
    dplyr::select(
      family_id,
      family_member,
      predictor_id,
      test_role,
      comparison_id,
      statistic,
      degrees_freedom,
      raw_p,
      non_estimability_reason
    )
}

h06_emmeans_summary <- function(object) {
  output <- as.data.frame(summary(
    object,
    infer = c(TRUE, TRUE),
    adjust = "none"
  ))
  estimate_candidates <- c(
    intersect(c("estimate", "emmean", "response", "rate"), names(output)),
    grep("\\.trend$", names(output), value = TRUE)
  )
  if (length(estimate_candidates) == 0L) {
    h06_abort("An emmeans result lacks an estimate or trend column")
  }
  estimate_name <- estimate_candidates[[1L]]
  lower_name <- intersect(
    c("asymp.LCL", "lower.CL", "LCL"),
    names(output)
  )[[1L]]
  upper_name <- intersect(
    c("asymp.UCL", "upper.CL", "UCL"),
    names(output)
  )[[1L]]
  p_name <- intersect(c("p.value", "p.value."), names(output))[[1L]]
  tibble::as_tibble(output) |>
    dplyr::mutate(
      estimate_model = as.numeric(.data[[estimate_name]]),
      standard_error = as.numeric(.data$SE),
      conf_low_model = as.numeric(.data[[lower_name]]),
      conf_high_model = as.numeric(.data[[upper_name]]),
      raw_p = as.numeric(.data[[p_name]])
    )
}

h06_response_scale <- function(x, response_family) {
  ifelse(response_family == "tweedie_log", exp(x), 10^x)
}

h06_practical_effects <- function(
  model,
  response_family = "tweedie_log",
  marginalization = c("equal_site", "observed_proportional"),
  site_specific = FALSE,
  day_variable = "work_free_day"
) {
  marginalization <- match.arg(marginalization)
  if (is.null(model)) {
    return(tibble::tibble())
  }
  weights <- if (marginalization == "equal_site") "equal" else "proportional"
  by_site <- if (site_specific) " | site" else ""
  day_reference <- if (day_variable == "work_free_day") {
    c("Work day" = -1, "Free day" = 1)
  } else {
    c("Weekday" = -1, "Weekend" = 1)
  }
  day_emm <- emmeans::emmeans(
    model,
    stats::as.formula(paste0("~", day_variable, by_site)),
    weights = weights,
    type = "link"
  )
  day <- h06_emmeans_summary(emmeans::contrast(
    day_emm,
    method = list(day_reference = unname(day_reference)),
    by = if (site_specific) "site" else NULL
  )) |>
    dplyr::mutate(
      predictor_id = day_variable,
      effect_id = if (day_variable == "work_free_day") {
        "free_day_vs_work_day"
      } else {
        "weekend_vs_weekday"
      }
    )
  activity_emm <- emmeans::emmeans(
    model,
    stats::as.formula(paste0("~activity_status", by_site)),
    weights = weights,
    type = "link"
  )
  activity <- h06_emmeans_summary(emmeans::contrast(
    activity_emm,
    method = list(active_vs_sedentary = c(-1, 1)),
    by = if (site_specific) "site" else NULL
  )) |>
    dplyr::mutate(
      predictor_id = "activity_status",
      effect_id = "active_vs_sedentary"
    )
  trend_formula <- stats::as.formula(if (site_specific) "~site" else "~1")
  sleep <- h06_emmeans_summary(emmeans::emtrends(
    model,
    trend_formula,
    var = "previous_sleep_duration_centered_h",
    weights = weights
  )) |>
    dplyr::mutate(
      predictor_id = "previous_sleep_duration_centered_h",
      effect_id = "per_hour_previous_sleep"
    )
  dplyr::bind_rows(day, activity, sleep) |>
    dplyr::mutate(
      response_family = .env$response_family,
      marginalization = marginalization,
      site_specific = site_specific,
      estimate_response_ratio = h06_response_scale(
        estimate_model,
        response_family
      ),
      conf_low_response_ratio = h06_response_scale(
        conf_low_model,
        response_family
      ),
      conf_high_response_ratio = h06_response_scale(
        conf_high_model,
        response_family
      ),
      response_scale_interpretation = ifelse(
        response_family == "tweedie_log",
        "ratio of expected hourly melEDI",
        "ratio of geometric means of melEDI + 0.1 lx"
      )
    ) |>
    dplyr::select(
      dplyr::any_of("site"),
      predictor_id,
      effect_id,
      response_family,
      marginalization,
      site_specific,
      estimate_model,
      standard_error,
      conf_low_model,
      conf_high_model,
      estimate_response_ratio,
      conf_low_response_ratio,
      conf_high_response_ratio,
      raw_p,
      response_scale_interpretation
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
    maximum_supported_hours_per_day = max(hours_per_day$supported_hours),
    frame_sha256 = h06_model_frame_hash(frame)
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

h06_temporal_diagnostics <- function(
  model,
  frame,
  run_id,
  response_family = c("tweedie_log", "gaussian_log10_offset")
) {
  response_family <- match.arg(response_family)
  if (is.null(model)) {
    return(tibble::tibble())
  }
  residual <- tryCatch(
    as.numeric(stats::residuals(model, type = "pearson")),
    error = function(error) as.numeric(stats::residuals(model))
  )
  fitted_model_scale <- as.numeric(stats::fitted(model))
  fitted_response <- if (response_family == "tweedie_log") {
    fitted_model_scale
  } else {
    10^fitted_model_scale - 0.1
  }
  diagnostic <- frame |>
    dplyr::mutate(
      residual = residual,
      fitted_response = fitted_response
    ) |>
    dplyr::arrange(hour_sequence_id, hour_sequence_position) |>
    dplyr::group_by(hour_sequence_id) |>
    dplyr::mutate(
      previous_residual = dplyr::lag(residual),
      next_position = dplyr::lead(hour_sequence_position)
    ) |>
    dplyr::ungroup()
  lag_rows <- diagnostic |>
    dplyr::filter(is.finite(residual), is.finite(previous_residual))
  sequence_correlations <- diagnostic |>
    dplyr::group_by(hour_sequence_id) |>
    dplyr::filter(dplyr::n() >= 3L) |>
    dplyr::summarise(
      lag1 = suppressWarnings(stats::cor(residual[-1L], residual[-dplyr::n()])),
      .groups = "drop"
    ) |>
    dplyr::filter(is.finite(lag1))
  summary <- tibble::tibble(
    run_id = run_id,
    pearson_residual_mean = mean(residual, na.rm = TRUE),
    pearson_residual_sd = stats::sd(residual, na.rm = TRUE),
    pearson_residual_over_3_fraction = mean(abs(residual) > 3, na.rm = TRUE),
    pearson_residual_over_4_fraction = mean(abs(residual) > 4, na.rm = TRUE),
    pooled_within_sequence_lag1 = if (nrow(lag_rows) >= 3L) {
      suppressWarnings(stats::cor(
        lag_rows$residual,
        lag_rows$previous_residual
      ))
    } else {
      NA_real_
    },
    sequences_with_lag1 = nrow(sequence_correlations),
    median_sequence_lag1 = if (nrow(sequence_correlations) > 0L) {
      stats::median(sequence_correlations$lag1)
    } else {
      NA_real_
    },
    observed_zero_fraction = mean(frame$response_value == 0),
    fitted_minimum = min(diagnostic$fitted_response, na.rm = TRUE),
    fitted_maximum = max(diagnostic$fitted_response, na.rm = TRUE),
    nonnegative_predictions = all(diagnostic$fitted_response >= 0)
  )
  clock <- diagnostic |>
    dplyr::mutate(clock_hour_bin = floor(clock_hour)) |>
    dplyr::summarise(
      one_hour_observations = dplyr::n(),
      residual_mean = mean(residual),
      residual_sd = stats::sd(residual),
      fitted_mean = mean(fitted_response),
      observed_mean = mean(response_value),
      .by = c(site, work_free_day, activity_status, clock_hour_bin)
    ) |>
    dplyr::mutate(run_id = run_id, .before = 1L)
  plot_data <- diagnostic |>
    dplyr::transmute(
      run_id = run_id,
      model_row_id = .model_row_id,
      site = as.character(site),
      participant_key = as.character(participant_key),
      participant_day_key = as.character(participant_day_key),
      hour_sequence_id = as.character(hour_sequence_id),
      clock_hour,
      response_value,
      fitted_response,
      pearson_residual = residual
    )
  list(summary = summary, clock = clock, plot_data = plot_data)
}

h06_influence_screen <- function(model, frame, run_id, n = 5L) {
  if (is.null(model)) {
    return(tibble::tibble())
  }
  residual <- abs(tryCatch(
    as.numeric(stats::residuals(model, type = "pearson")),
    error = function(error) as.numeric(stats::residuals(model))
  ))
  participant <- tibble::tibble(
    unit = as.character(frame$participant_key),
    score = residual
  ) |>
    dplyr::summarise(
      influence_score = max(score, na.rm = TRUE),
      one_hour_observations = dplyr::n(),
      .by = unit
    ) |>
    dplyr::slice_max(influence_score, n = n, with_ties = FALSE) |>
    dplyr::mutate(
      run_id = run_id,
      influence_unit = "participant",
      screen_rank = dplyr::row_number()
    )
  site <- tibble::tibble(
    unit = as.character(frame$site),
    score = residual
  ) |>
    dplyr::summarise(
      influence_score = max(score, na.rm = TRUE),
      one_hour_observations = dplyr::n(),
      .by = unit
    ) |>
    dplyr::arrange(dplyr::desc(influence_score)) |>
    dplyr::mutate(
      run_id = run_id,
      influence_unit = "site",
      screen_rank = dplyr::row_number()
    )
  dplyr::bind_rows(participant, site) |>
    dplyr::select(
      run_id,
      influence_unit,
      unit,
      influence_score,
      one_hour_observations,
      screen_rank
    )
}

h06_special_record_screen <- function(frame, run_id) {
  frame |>
    dplyr::mutate(
      special_record = dplyr::case_when(
        site == "TUM" &
          Id == "TUM_S001" &
          local_date %in% (as.Date("2024-05-13") + 0:6) ~
          "corrected_TUM_S001_diary_day",
        site == "KNUST" &
          Id == "KNUST_S005" &
          local_date == as.Date("2024-11-04") ~
          "KNUST_S005_sedentary_reinterpretation_day",
        sleep_interval_quarantined %in% TRUE ~ "quarantined_sleep_interval",
        TRUE ~ NA_character_
      )
    ) |>
    dplyr::filter(!is.na(special_record)) |>
    dplyr::summarise(
      one_hour_observations = dplyr::n(),
      participant_days = dplyr::n_distinct(participant_day_key),
      .by = c(special_record, site, Id)
    ) |>
    dplyr::mutate(run_id = run_id, .before = 1L)
}

h06_dharma_diagnostics <- function(model, run_id, seed, simulations = 100L) {
  if (is.null(model)) {
    return(tibble::tibble())
  }
  set.seed(seed)
  simulated <- tryCatch(
    DHARMa::simulateResiduals(
      fittedModel = model,
      n = simulations,
      refit = FALSE,
      plot = FALSE,
      seed = seed
    ),
    error = function(error) error
  )
  if (inherits(simulated, "error")) {
    return(tibble::tibble(
      run_id = run_id,
      simulations = simulations,
      uniformity_p = NA_real_,
      dispersion_p = NA_real_,
      zero_inflation_p = NA_real_,
      outlier_p = NA_real_,
      simulated_zero_fraction = NA_real_,
      error = conditionMessage(simulated)
    ))
  }
  p_value <- function(expression) {
    tryCatch(as.numeric(expression$p.value), error = function(error) NA_real_)
  }
  simulated_matrix <- simulated$simulatedResponse
  tibble::tibble(
    run_id = run_id,
    simulations = simulations,
    uniformity_p = p_value(DHARMa::testUniformity(simulated, plot = FALSE)),
    dispersion_p = p_value(DHARMa::testDispersion(simulated, plot = FALSE)),
    zero_inflation_p = p_value(DHARMa::testZeroInflation(
      simulated,
      plot = FALSE
    )),
    outlier_p = p_value(DHARMa::testOutliers(simulated, plot = FALSE)),
    simulated_zero_fraction = mean(simulated_matrix == 0),
    error = NA_character_
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
      "The constructed H06 run order differs from the approved registry"
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

h06_weekend_sensitivity <- function(frame) {
  formula <- h06_formula_set()$weekend_additive
  fit <- h06_fit_model(frame, formula)
  effect <- if (is.null(fit$model)) {
    tibble::tibble()
  } else {
    h06_practical_effects(
      fit$model,
      marginalization = "equal_site",
      day_variable = "weekday_weekend"
    )
  }
  list(fit = fit, formula = formula, effect = effect)
}

h06_random_site_sensitivity <- function(frame) {
  formula <- h06_formula_set()$registered_random_site
  fit <- h06_fit_model(frame, formula, fixed_site = FALSE)
  list(
    fit = fit,
    formula = formula,
    status = h06_model_fit_status(fit$model),
    random_parameters = h06_random_parameter_summary(fit$model),
    effect = if (is.null(fit$model)) {
      tibble::tibble()
    } else {
      h06_practical_effects(
        fit$model,
        marginalization = "observed_proportional"
      )
    }
  )
}

h06_distribution_sensitivity <- function(frame) {
  formula <- h06_formula_set()$full
  fit <- h06_fit_model(
    frame,
    formula,
    response_family = "gaussian_log10_offset"
  )
  list(
    fit = fit,
    formula = formula,
    status = h06_model_fit_status(fit$model),
    random_parameters = h06_random_parameter_summary(fit$model),
    effect_equal_site = if (is.null(fit$model)) {
      tibble::tibble()
    } else {
      h06_practical_effects(
        fit$model,
        response_family = "gaussian_log10_offset",
        marginalization = "equal_site"
      )
    }
  )
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

h06_exploratory_effects <- function(model, analysis_id) {
  if (is.null(model)) {
    return(tibble::tibble())
  }
  variable <- h06_exploratory_variable(analysis_id)
  if (variable == "exercise_location") {
    marginal <- emmeans::emmeans(
      model,
      ~exercise_location,
      weights = "equal",
      type = "link"
    )
    output <- h06_emmeans_summary(emmeans::contrast(
      marginal,
      method = "trt.vs.ctrl",
      ref = 1L,
      adjust = "none"
    )) |>
      dplyr::mutate(effect_id = as.character(contrast))
  } else {
    output <- h06_emmeans_summary(emmeans::emtrends(
      model,
      ~1,
      var = variable,
      weights = "equal"
    )) |>
      dplyr::mutate(effect_id = paste0("per_unit__", variable))
  }
  output |>
    dplyr::mutate(
      analysis_id = analysis_id,
      predictor_id = variable,
      estimate_response_ratio = exp(estimate_model),
      conf_low_response_ratio = exp(conf_low_model),
      conf_high_response_ratio = exp(conf_high_model),
      inferential_role = "exploratory_estimate_and_95CI_no_confirmatory_p_family"
    ) |>
    dplyr::select(
      analysis_id,
      predictor_id,
      effect_id,
      estimate_model,
      standard_error,
      conf_low_model,
      conf_high_model,
      estimate_response_ratio,
      conf_low_response_ratio,
      conf_high_response_ratio,
      raw_p,
      inferential_role
    )
}

h06_fit_exploratory_predictors <- function(frame) {
  formulas <- h06_exploratory_formula_set()
  stats::setNames(
    lapply(names(formulas), function(analysis_id) {
      analysis_frame <- h06_exploratory_frame(frame, analysis_id)
      fit <- h06_fit_model(analysis_frame, formulas[[analysis_id]])
      status <- h06_model_fit_status(fit$model)
      effects <- h06_exploratory_effects(fit$model, analysis_id)
      list(
        analysis_id = analysis_id,
        frame = analysis_frame,
        fit = fit,
        status = status,
        effects = effects
      )
    }),
    names(formulas)
  )
}

h06_fit_gamm <- function(frame, seed = 6106L) {
  formula <- h06_gamm_formula()
  ordered <- frame |>
    dplyr::arrange(participant_day_key, utc_start) |>
    dplyr::mutate(
      participant_key = factor(participant_key),
      participant_day_key = factor(participant_day_key),
      site = factor(site),
      work_free_day = factor(work_free_day),
      activity_status = factor(activity_status),
      day_activity_group = h06_day_activity_group(
        work_free_day,
        activity_status
      )
    )
  environment(formula) <- environment()
  knots <- list(clock_hour = c(0, 24))
  initial <- h06_capture_fit(mgcv::bam(
    formula = formula,
    data = ordered,
    method = "fREML",
    discrete = TRUE,
    knots = knots,
    nthreads = 1L,
    gc.level = 1L
  ))
  if (is.null(initial$model)) {
    return(list(
      formula = formula,
      data = ordered,
      initial = initial,
      rho = NA_real_,
      final = initial,
      diagnostics = tibble::tibble(),
      contract_version = "v3_reproducible_diagnostics_and_full_closure_check"
    ))
  }
  residual <- stats::residuals(initial$model, type = "pearson")
  lag_rows <- tibble::tibble(
    sequence = ordered$hour_sequence_id,
    position = ordered$hour_sequence_position,
    residual = as.numeric(residual)
  ) |>
    dplyr::arrange(sequence, position) |>
    dplyr::group_by(sequence) |>
    dplyr::mutate(previous = dplyr::lag(residual)) |>
    dplyr::ungroup() |>
    dplyr::filter(is.finite(residual), is.finite(previous))
  rho <- if (nrow(lag_rows) >= 3L) {
    suppressWarnings(stats::cor(lag_rows$residual, lag_rows$previous))
  } else {
    0
  }
  rho <- max(min(rho, 0.95), -0.95)
  set.seed(seed)
  final <- h06_capture_fit(mgcv::bam(
    formula = formula,
    data = ordered,
    method = "fREML",
    discrete = TRUE,
    knots = knots,
    rho = rho,
    AR.start = ordered$AR_start,
    nthreads = 1L,
    gc.level = 1L
  ))
  diagnostics <- if (is.null(final$model)) {
    tibble::tibble()
  } else {
    set.seed(seed + 1L)
    check <- tryCatch(
      mgcv::k.check(final$model),
      error = function(error) NULL
    )
    concurvity <- tryCatch(
      mgcv::concurvity(final$model, full = TRUE),
      error = function(error) NULL
    )
    clock_columns <- if (is.null(concurvity)) {
      character()
    } else {
      grep("clock_hour", colnames(concurvity), value = TRUE, fixed = TRUE)
    }
    clock_concurvity <- if (length(clock_columns) == 0L) {
      NA_real_
    } else {
      max(concurvity["estimate", clock_columns], na.rm = TRUE)
    }
    final_residual <- stats::residuals(final$model, type = "pearson")
    closure_grid <- tidyr::expand_grid(
      clock_hour = c(0, 24),
      site = factor(levels(ordered$site), levels = levels(ordered$site)),
      work_free_day = factor(
        levels(ordered$work_free_day),
        levels = levels(ordered$work_free_day)
      ),
      activity_status = factor(
        levels(ordered$activity_status),
        levels = levels(ordered$activity_status)
      )
    ) |>
      dplyr::mutate(
        day_activity_group = h06_day_activity_group(
          work_free_day,
          activity_status
        ),
        previous_sleep_duration_centered_h = 0,
        participant_key = factor(
          levels(ordered$participant_key)[[1L]],
          levels = levels(ordered$participant_key)
        ),
        participant_day_key = factor(
          levels(ordered$participant_day_key)[[1L]],
          levels = levels(ordered$participant_day_key)
        )
      )
    closure_prediction <- tryCatch(
      as.numeric(stats::predict(
        final$model,
        newdata = closure_grid,
        type = "link",
        exclude = c("s(participant_key)", "s(participant_day_key)")
      )),
      error = function(error) rep(NA_real_, nrow(closure_grid))
    )
    closure_differences <- closure_grid |>
      dplyr::mutate(prediction = closure_prediction) |>
      dplyr::summarise(
        closure_difference = abs(diff(prediction)),
        .by = c(site, work_free_day, activity_status)
      )
    tibble::tibble(
      discrete = TRUE,
      method = "fREML",
      rho = rho,
      observations = stats::nobs(final$model),
      deviance_explained = summary(final$model)$dev.expl,
      minimum_available_k_index = if (is.null(check)) NA_real_ else
        min(check[, "k-index"], na.rm = TRUE),
      minimum_k_check_p = if (is.null(check)) NA_real_ else
        min(check[, "p-value"], na.rm = TRUE),
      maximum_clock_smooth_concurvity = clock_concurvity,
      maximum_cyclic_closure_absolute_difference = max(
        closure_differences$closure_difference,
        na.rm = TRUE
      ),
      median_cyclic_closure_absolute_difference = stats::median(
        closure_differences$closure_difference,
        na.rm = TRUE
      ),
      residual_mean = mean(final_residual),
      residual_sd = stats::sd(final_residual),
      initial_elapsed_seconds = initial$elapsed_seconds,
      final_elapsed_seconds = final$elapsed_seconds,
      warnings = paste(final$warnings, collapse = " | "),
      error = final$error
    )
  }
  list(
    formula = formula,
    data = ordered,
    initial = initial,
    rho = rho,
    final = final,
    diagnostics = diagnostics,
    contract_version = "v3_reproducible_diagnostics_and_full_closure_check"
  )
}

h06_gamm_prediction_grid <- function(gamm_bundle, site_levels) {
  model <- gamm_bundle$final$model
  if (is.null(model)) {
    return(tibble::tibble())
  }
  data <- gamm_bundle$data
  participant_reference <- levels(data$participant_key)[[1L]]
  day_reference <- levels(data$participant_day_key)[[1L]]
  grid <- tidyr::expand_grid(
    clock_hour = seq(0, 24, by = 0.25),
    site = factor(site_levels, levels = levels(data$site)),
    work_free_day = factor(
      levels(data$work_free_day),
      levels = levels(data$work_free_day)
    ),
    activity_status = factor(
      levels(data$activity_status),
      levels = levels(data$activity_status)
    )
  ) |>
    dplyr::mutate(
      day_activity_group = h06_day_activity_group(
        work_free_day,
        activity_status
      ),
      previous_sleep_duration_centered_h = 0,
      participant_key = factor(
        participant_reference,
        levels = levels(data$participant_key)
      ),
      participant_day_key = factor(
        day_reference,
        levels = levels(data$participant_day_key)
      )
    )
  prediction <- stats::predict(
    model,
    newdata = grid,
    type = "link",
    se.fit = TRUE,
    exclude = c("s(participant_key)", "s(participant_day_key)")
  )
  grid |>
    dplyr::mutate(
      fit_log10_offset = as.numeric(prediction$fit),
      standard_error = as.numeric(prediction$se.fit),
      conf_low_log10_offset = fit_log10_offset -
        stats::qnorm(0.975) * standard_error,
      conf_high_log10_offset = fit_log10_offset +
        stats::qnorm(0.975) * standard_error,
      fitted_melEDI_lx = pmax(10^fit_log10_offset - 0.1, 0),
      conf_low_melEDI_lx = pmax(10^conf_low_log10_offset - 0.1, 0),
      conf_high_melEDI_lx = pmax(10^conf_high_log10_offset - 0.1, 0),
      inferential_role = "exploratory_pointwise_95CI_not_simultaneous"
    )
}

h06_v0_method_frame <- function(
  light_path,
  exercise_raw,
  sleep_raw,
  placement
) {
  environment <- new.env(parent = emptyenv())
  loaded <- load(light_path, envir = environment)
  if (length(loaded) != 1L) {
    h06_abort("The frozen V0 light file must contain exactly one object")
  }
  light <- environment[[loaded[[1L]]]]
  hourly <- LightLogR::aggregate_Datetime(
    light,
    "1 hour",
    type = "floor",
    numeric.handler = function(x) mean(x, na.rm = TRUE),
    geo.MEDI = LightLogR::exp_zero_inflated(mean(
      LightLogR::log_zero_inflated(MEDI),
      na.rm = TRUE
    ))
  ) |>
    LightLogR::add_Date_col(group.by = TRUE) |>
    dplyr::mutate(static = all(MEDI == MEDI[[1L]])) |>
    dplyr::filter_out(static) |>
    dplyr::select(-static) |>
    dplyr::ungroup()
  sleep <- sleep_raw |>
    dplyr::transmute(
      site,
      Id,
      Date = as.Date(wake_wall),
      sleep_duration = as.numeric(sleep_duration, units = "hours"),
      daytype = factor(
        as.character(daytype2),
        levels = c("a work day", "a free day")
      )
    )
  exercise <- exercise_raw |>
    dplyr::transmute(
      site,
      Id,
      Date = as.Date(Date),
      exercise = dplyr::recode(
        as.character(intensity),
        "None of the above, I did not perform any type of physical activity" = "None",
        "Light (causing small to no increases in heart rate and breathing, e.g. taking a stroll in the park)" = "Light",
        "Moderate (causing moderate increases in heart rate and breathing, e.g. cycling in the city)" = "Moderate",
        "Vigorous (causing large increases in heart rate and breathing, e.g. running)" = "Vigorous"
      ) |>
        factor(levels = c("None", "Light", "Moderate", "Vigorous"))
    )
  frame <- hourly |>
    dplyr::left_join(
      dplyr::full_join(
        sleep,
        exercise,
        by = c("site", "Id", "Date"),
        relationship = "one-to-one"
      ),
      by = c("site", "Id", "Date"),
      relationship = "many-to-one"
    ) |>
    dplyr::filter(
      is.finite(geo.MEDI),
      !is.na(daytype),
      !is.na(exercise),
      is.finite(sleep_duration)
    ) |>
    dplyr::mutate(
      placement = placement,
      site = factor(site),
      Id = factor(Id),
      daytype = droplevels(daytype),
      exercise = droplevels(exercise),
      .model_row_id = paste(
        placement,
        site,
        Id,
        Date,
        format(Datetime, "%Y-%m-%dT%H:%M:%S"),
        sep = "::"
      )
    )
  if (anyDuplicated(frame$.model_row_id)) {
    h06_abort(
      "The current-pin V0-method reconstruction has duplicate hourly rows"
    )
  }
  attr(frame, "h06_v0_frame_contract_version") <-
    "v1_exact_filter_out_retains_unknown_static_days"
  frame
}

h06_v0_formula_set <- function() {
  list(
    full = stats::as.formula(
      "geo.MEDI ~ site * daytype + site * exercise + site * sleep_duration + (1 | Id)"
    ),
    no_daytype = stats::as.formula(
      "geo.MEDI ~ site * exercise + site * sleep_duration + (1 | Id)"
    ),
    no_exercise = stats::as.formula(
      "geo.MEDI ~ site * daytype + site * sleep_duration + (1 | Id)"
    ),
    no_sleep = stats::as.formula(
      "geo.MEDI ~ site * daytype + site * exercise + (1 | Id)"
    )
  )
}

h06_fit_v0_model <- function(frame, formula) {
  h06_capture_fit(glmmTMB::glmmTMB(
    formula = formula,
    data = frame,
    REML = FALSE,
    family = glmmTMB::tweedie(),
    contrasts = list(site = "contr.sum"),
    control = glmmTMB::glmmTMBControl(
      optCtrl = list(iter.max = 10000L, eval.max = 10000L),
      profile = FALSE
    )
  ))
}

h06_fit_v0_method <- function(frame) {
  formulas <- h06_v0_formula_set()
  fits <- stats::setNames(
    lapply(formulas, function(formula) {
      h06_fit_v0_model(frame, formula)
    }),
    names(formulas)
  )
  list(
    frame_rows = frame$.model_row_id,
    frame_sha256 = digest::digest(
      list(
        frame$.model_row_id,
        frame$geo.MEDI,
        frame$daytype,
        frame$exercise,
        frame$sleep_duration
      ),
      algo = "sha256",
      serialize = TRUE
    ),
    formulas = formulas,
    fits = fits
  )
}

h06_v0_method_tests <- function(bundle, placement) {
  dplyr::bind_rows(
    h06_likelihood_ratio(
      bundle$fits$no_daytype,
      bundle$fits$full,
      "v0_combined_daytype_plus_site_interactions"
    ) |>
      dplyr::mutate(predictor_id = "daytype"),
    h06_likelihood_ratio(
      bundle$fits$no_exercise,
      bundle$fits$full,
      "v0_combined_exercise_plus_site_interactions"
    ) |>
      dplyr::mutate(predictor_id = "exercise"),
    h06_likelihood_ratio(
      bundle$fits$no_sleep,
      bundle$fits$full,
      "v0_combined_sleep_plus_site_interactions"
    ) |>
      dplyr::mutate(predictor_id = "sleep_duration")
  ) |>
    dplyr::mutate(
      placement = placement,
      analytical_role = "current_pin_V0_method_reconstruction_not_exact_frozen_refit",
      .before = 1L
    )
}

h06_v0_method_effects <- function(bundle, placement) {
  model <- bundle$fits$full$model
  if (is.null(model)) {
    return(tibble::tibble())
  }
  day <- h06_emmeans_summary(emmeans::contrast(
    emmeans::emmeans(model, ~daytype, weights = "equal", type = "link"),
    list(free_vs_work = c(-1, 1))
  )) |>
    dplyr::mutate(effect_id = "free_vs_work")
  exercise <- h06_emmeans_summary(emmeans::contrast(
    emmeans::emmeans(model, ~exercise, weights = "equal", type = "link"),
    method = "trt.vs.ctrl",
    ref = 1L,
    adjust = "none"
  )) |>
    dplyr::mutate(effect_id = as.character(contrast))
  sleep <- h06_emmeans_summary(emmeans::emtrends(
    model,
    ~1,
    var = "sleep_duration",
    weights = "equal"
  )) |>
    dplyr::mutate(effect_id = "per_hour_sleep")
  dplyr::bind_rows(day, exercise, sleep) |>
    dplyr::mutate(
      placement = placement,
      estimate_ratio = exp(estimate_model),
      conf_low_ratio = exp(conf_low_model),
      conf_high_ratio = exp(conf_high_model),
      analytical_role = "current_pin_V0_method_reconstruction_not_exact_frozen_refit",
      .before = 1L
    ) |>
    dplyr::select(
      analytical_role,
      placement,
      effect_id,
      estimate_model,
      standard_error,
      conf_low_model,
      conf_high_model,
      estimate_ratio,
      conf_low_ratio,
      conf_high_ratio,
      raw_p
    )
}

h06_v0_method_performance <- function(bundle, placement) {
  model <- bundle$fits$full$model
  status <- h06_model_fit_status(model)
  r2 <- tryCatch(
    as.data.frame(performance::r2_nakagawa(model, approximation = "lognormal")),
    error = function(error) NULL
  )
  conditional <- if (is.null(r2)) NA_real_ else
    as.numeric(r2$R2_conditional[[1L]])
  marginal <- if (is.null(r2)) NA_real_ else as.numeric(r2$R2_marginal[[1L]])
  participant_sd <- tryCatch(
    as.numeric(attr(glmmTMB::VarCorr(model)$cond$Id, "stddev")[[1L]]),
    error = function(error) NA_real_
  )
  dplyr::bind_cols(
    tibble::tibble(
      placement = placement,
      observations = if (is.null(model)) NA_integer_ else stats::nobs(model),
      conditional_r2 = conditional,
      marginal_r2 = marginal,
      participant_random_multiplier = exp(participant_sd),
      frame_sha256 = bundle$frame_sha256,
      analytical_role = "current_pin_V0_method_reconstruction_not_exact_frozen_refit"
    ),
    status
  )
}

h06_v0_method_reference <- function(bundle, placement, sleep_hours = 7.9) {
  model <- bundle$fits$full$model
  if (is.null(model)) {
    return(tibble::tibble())
  }
  reference <- h06_emmeans_summary(emmeans::emmeans(
    model,
    ~1,
    at = list(
      daytype = "a work day",
      exercise = "None",
      sleep_duration = sleep_hours
    ),
    weights = "equal",
    type = "link"
  ))
  reference |>
    dplyr::transmute(
      analytical_role = "current_pin_V0_method_reconstruction_not_exact_frozen_refit",
      placement = placement,
      sleep_hours = sleep_hours,
      estimate_model,
      conf_low_model,
      conf_high_model,
      reference_melEDI_lx = exp(estimate_model),
      conf_low_melEDI_lx = exp(conf_low_model),
      conf_high_melEDI_lx = exp(conf_high_model)
    )
}

h06_model_performance_summary <- function(model, run_id, model_id) {
  if (is.null(model)) {
    return(tibble::tibble(
      run_id = run_id,
      model_id = model_id,
      computed_marginal_r2 = NA_real_,
      computed_conditional_r2 = NA_real_,
      computed_intraclass_correlation = NA_real_,
      marginal_r2 = NA_real_,
      conditional_r2 = NA_real_,
      intraclass_correlation = NA_real_,
      performance_interval = NA_character_,
      performance_status = "model_unavailable",
      non_estimability_reason = "Model unavailable"
    ))
  }
  r2 <- tryCatch(
    suppressWarnings(performance::r2_nakagawa(
      model,
      approximation = "lognormal",
      tolerance = 1e-8
    )),
    error = function(error) NULL
  )
  icc <- tryCatch(
    suppressWarnings(performance::icc(model, tolerance = 1e-8)),
    error = function(error) NULL
  )
  status <- h06_model_fit_status(model)
  computed_marginal <- if (is.null(r2)) NA_real_ else
    as.numeric(r2$R2_marginal[[1L]])
  computed_conditional <- if (is.null(r2)) NA_real_ else
    as.numeric(r2$R2_conditional[[1L]])
  computed_icc <- if (is.null(icc)) NA_real_ else
    as.numeric(icc$ICC_adjusted[[1L]])
  reportable <- isTRUE(status$converged) &&
    isTRUE(status$positive_definite_hessian) &&
    !isTRUE(status$singular) &&
    is.finite(computed_marginal) &&
    is.finite(computed_conditional)
  tibble::tibble(
    run_id = run_id,
    model_id = model_id,
    computed_marginal_r2 = computed_marginal,
    computed_conditional_r2 = computed_conditional,
    computed_intraclass_correlation = computed_icc,
    marginal_r2 = if (reportable) computed_marginal else NA_real_,
    conditional_r2 = if (reportable) computed_conditional else NA_real_,
    intraclass_correlation = if (reportable) computed_icc else NA_real_,
    performance_interval = NA_character_,
    performance_status = if (reportable) "point_estimate_only" else {
      "not_reportable_singular_or_unstable_model"
    },
    non_estimability_reason = if (reportable) {
      paste0(
        "No 95% interval: model-performance uncertainty would require heavy ",
        "cluster resampling, which was not run without a pilot/production gate"
      )
    } else {
      paste0(
        "Performance point estimates are not reported because the approved ",
        "model is singular or otherwise unstable; the computed boundary value ",
        "is retained only for audit"
      )
    }
  )
}

h06_gaussian_diagnostics <- function(model, frame, run_id, seed = 6106L) {
  if (is.null(model)) {
    return(tibble::tibble())
  }
  residual <- as.numeric(stats::residuals(model, type = "pearson"))
  fitted_log10 <- as.numeric(stats::fitted(model))
  standardized <- as.numeric(scale(residual))
  set.seed(seed)
  shapiro_values <- if (length(standardized) > 5000L) {
    sample(standardized, 5000L)
  } else {
    standardized
  }
  fitted_group <- cut(
    fitted_log10,
    breaks = unique(stats::quantile(
      fitted_log10,
      probs = seq(0, 1, length.out = 6L),
      na.rm = TRUE
    )),
    include.lowest = TRUE
  )
  group_variance <- tapply(residual, fitted_group, stats::var, na.rm = TRUE)
  variance_ratio <- if (length(group_variance) > 1L) {
    max(group_variance, na.rm = TRUE) / min(group_variance, na.rm = TRUE)
  } else {
    NA_real_
  }
  physical <- 10^fitted_log10 - 0.1
  tibble::tibble(
    run_id = run_id,
    residual_mean = mean(residual),
    residual_sd = stats::sd(residual),
    shapiro_p_5000 = stats::shapiro.test(shapiro_values)$p.value,
    fitted_quintile_residual_variance_ratio = variance_ratio,
    standardized_residual_over_3_fraction = mean(abs(standardized) > 3),
    standardized_residual_over_4_fraction = mean(abs(standardized) > 4),
    fitted_physical_minimum_melEDI_lx = min(physical),
    fitted_physical_maximum_melEDI_lx = max(physical),
    negative_physical_prediction_fraction = mean(physical < 0),
    observed_log10_offset_minimum = min(frame$log10_melEDI_offset),
    observed_log10_offset_maximum = max(frame$log10_melEDI_offset)
  )
}

h06_fit_influence_refits <- function(
  frame,
  participant_candidates = character(),
  site_candidates = levels(frame$site)
) {
  targets <- dplyr::bind_rows(
    tibble::tibble(
      influence_unit = "site",
      omitted_unit = site_candidates
    ),
    tibble::tibble(
      influence_unit = "participant",
      omitted_unit = participant_candidates
    )
  )
  formulas <- h06_formula_set()
  stats::setNames(
    lapply(seq_len(nrow(targets)), function(index) {
      unit_type <- targets$influence_unit[[index]]
      unit <- targets$omitted_unit[[index]]
      subset <- if (unit_type == "site") {
        frame[as.character(frame$site) != unit, , drop = FALSE]
      } else {
        frame[as.character(frame$participant_key) != unit, , drop = FALSE]
      }
      subset <- h06_refactor_frame(subset)
      fit <- h06_fit_model(subset, formulas$full)
      effects <- if (is.null(fit$model)) {
        tibble::tibble()
      } else {
        h06_practical_effects(
          fit$model,
          marginalization = "equal_site"
        )
      }
      list(
        influence_unit = unit_type,
        omitted_unit = unit,
        frame_sha256 = h06_model_frame_hash(subset),
        observations = nrow(subset),
        participants = dplyr::n_distinct(subset$participant_key),
        sites = dplyr::n_distinct(subset$site),
        fit = fit,
        status = h06_model_fit_status(fit$model),
        random_parameters = h06_random_parameter_summary(fit$model),
        effects = effects
      )
    }),
    paste(targets$influence_unit, targets$omitted_unit, sep = "__")
  )
}

h06_influence_refit_summary <- function(refits, full_effects) {
  dplyr::bind_rows(lapply(refits, function(item) {
    effects <- item$effects |>
      dplyr::left_join(
        full_effects |>
          dplyr::select(
            predictor_id,
            full_estimate_model = estimate_model,
            full_estimate_response_ratio = estimate_response_ratio
          ),
        by = "predictor_id",
        relationship = "many-to-one"
      ) |>
      dplyr::mutate(
        estimate_model_change = estimate_model - full_estimate_model,
        response_ratio_change = estimate_response_ratio -
          full_estimate_response_ratio,
        sign_reversal = sign(estimate_model) != sign(full_estimate_model)
      )
    dplyr::bind_cols(
      tibble::tibble(
        influence_unit = item$influence_unit,
        omitted_unit = item$omitted_unit,
        observations = item$observations,
        participants = item$participants,
        sites = item$sites,
        frame_sha256 = item$frame_sha256,
        elapsed_seconds = item$fit$elapsed_seconds,
        warnings = paste(item$fit$warnings, collapse = " | "),
        error = item$fit$error
      ),
      item$status,
      item$random_parameters
    ) |>
      dplyr::slice(rep(1L, nrow(effects))) |>
      dplyr::bind_cols(effects)
  }))
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
        record_type = "author_approved_KNUST_reinterpretation",
        site,
        Id,
        local_date,
        source_value = sedentary_source_minutes,
        analysis_value = sedentary_h,
        unit = "source minutes label / analysis hours"
      )
  )
}
