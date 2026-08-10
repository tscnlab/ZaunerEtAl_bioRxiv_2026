# Prepare, fit, diagnose, and summarize the approved H09 models.

h09_local_midpoint_clock_minute <- function(onset, offset, timezone) {
  mapply(
    FUN = function(on, off, tz) {
      if (is.na(on) || is.na(off) || is.na(tz)) return(NA_real_)
      midpoint <- on + as.numeric(difftime(off, on, units = "secs")) / 2
      local <- as.POSIXlt(midpoint, tz = tz)
      local$hour * 60 + local$min + local$sec / 60
    },
    onset,
    offset,
    timezone,
    USE.NAMES = FALSE
  )
}

h09_complete_sum <- function(x) {
  if (length(x) == 0L || all(is.na(x))) NA_real_ else sum(x, na.rm = TRUE)
}

h09_prepare_primary_wide <- function(data, score_contract) {
  raw_l10_hour <- as.numeric(data$l10_midpoint_clock_minute) / 60
  midpoint_longest <- h09_local_midpoint_clock_minute(
    data$longest_bout_above_250_onset_utc,
    data$longest_bout_above_250_offset_utc,
    data$timezone
  ) / 60
  data |>
    dplyr::mutate(
      local_date = as.Date(.data$local_date),
      mctq_hour = as.numeric(.data$msf_sc) / 3600,
      mctq_hour_centered = .data$mctq_hour -
        score_contract$mctq_center_hour,
      meq_score = as.numeric(.data$meq),
      meq_10_centered = (.data$meq_score -
        score_contract$meq_center_score) / 10,
      m10_hour = as.numeric(.data$m10_midpoint_clock_minute) / 60,
      l10_hour = dplyr::if_else(
        raw_l10_hour > 16,
        raw_l10_hour - 24,
        raw_l10_hour
      ),
      l10_hour_noon_cut = dplyr::if_else(
        raw_l10_hour > 12,
        raw_l10_hour - 24,
        raw_l10_hour
      ),
      l10_raw_hour = raw_l10_hour,
      first_hour = as.numeric(
        .data$first_timing_above_250_clock_minute
      ) / 60,
      last_hour = as.numeric(
        .data$last_timing_above_250_clock_minute
      ) / 60,
      mean_hour = as.numeric(
        .data$mean_timing_above_250_clock_minute
      ) / 60,
      longest_midpoint_observed_hour = midpoint_longest,
      longest_midpoint_exact_hour = dplyr::if_else(
        .data$longest_bout_above_250_exact_identifiable %in% TRUE,
        midpoint_longest,
        NA_real_
      ),
      photoperiod_within_site = .data$photoperiod_hours - ave(
        .data$photoperiod_hours,
        .data$site,
        FUN = function(x) mean(x, na.rm = TRUE)
      ),
      participant_key = paste(.data$site, .data$Id, sep = ":")
    ) |>
    dplyr::group_by(.data$participant_key) |>
    dplyr::mutate(
      elapsed_day = as.numeric(.data$local_date - min(.data$local_date))
    ) |>
    dplyr::ungroup()
}

h09_primary_long <- function(data, placement, metric_registry) {
  purrr::map_dfr(seq_len(nrow(metric_registry)), function(index) {
    spec <- metric_registry[index, ]
    tibble::as_tibble(data) |>
      dplyr::transmute(
        data_scenario_id = "primary",
        placement = placement,
        .data$site,
        .data$Id,
        .data$local_date,
        .data$participant_key,
        .data$elapsed_day,
        metric_id = spec$metric_id,
        timing_hour = as.numeric(.data[[spec$source_column]]),
        .data$mctq_hour,
        .data$mctq_hour_centered,
        .data$meq_score,
        .data$meq_10_centered,
        .data$photoperiod_hours,
        .data$photoperiod_within_site,
        valid_measurement_minutes = as.numeric(.data$valid_medi_real_minutes),
        expected_measurement_minutes = as.numeric(.data$expected_real_minutes),
        l10_raw_hour = as.numeric(.data$l10_raw_hour),
        l10_hour_noon_cut = as.numeric(.data$l10_hour_noon_cut),
        longest_exact_identifiable =
          .data$longest_bout_above_250_exact_identifiable,
        longest_censored = .data$longest_bout_above_250_censored,
        longest_censor_reason = .data$longest_bout_above_250_censor_reason,
        longest_day_boundary_contact =
          .data$longest_bout_above_250_selected_winner_day_boundary_contact
      )
  })
}

h09_prepare_gap_long <- function(gap, chronotype, score_contract) {
  predictors <- chronotype |>
    dplyr::transmute(
      .data$site,
      .data$Id,
      mctq_hour = as.numeric(.data$msf_sc) / 3600,
      mctq_hour_centered = mctq_hour -
        score_contract$mctq_center_hour,
      meq_score = as.numeric(.data$meq),
      meq_10_centered = (meq_score -
        score_contract$meq_center_score) / 10
    )
  gap |>
    dplyr::filter(.data$metric_id %in% c(
      "m10_midpoint",
      "l10_midpoint",
      "first_timing_above_250",
      "last_timing_above_250",
      "mean_timing_above_250"
    )) |>
    dplyr::left_join(
      predictors,
      by = c("site", "Id"),
      relationship = "many-to-one"
    ) |>
    dplyr::mutate(
      data_scenario_id = "gap_timing_unaware",
      local_date = as.Date(.data$local_date),
      timing_hour = as.numeric(.data$manuscript_prepared_value),
      participant_key = paste(.data$site, .data$Id, sep = ":"),
      valid_measurement_minutes = NA_real_,
      expected_measurement_minutes = NA_real_,
      photoperiod_hours = NA_real_,
      photoperiod_within_site = NA_real_,
      l10_raw_hour = dplyr::if_else(
        .data$metric_id == "l10_midpoint",
        dplyr::if_else(.data$timing_hour < 0, .data$timing_hour + 24,
          .data$timing_hour),
        NA_real_
      ),
      l10_hour_noon_cut = dplyr::if_else(
        .data$metric_id == "l10_midpoint",
        dplyr::if_else(.data$l10_raw_hour > 12,
          .data$l10_raw_hour - 24, .data$l10_raw_hour),
        NA_real_
      ),
      longest_exact_identifiable = NA,
      longest_censored = NA,
      longest_censor_reason = NA_character_,
      longest_day_boundary_contact = NA
    ) |>
    dplyr::group_by(.data$participant_key) |>
    dplyr::mutate(
      elapsed_day = as.numeric(.data$local_date - min(.data$local_date))
    ) |>
    dplyr::ungroup() |>
    dplyr::select(
      .data$data_scenario_id,
      placement = .data$position,
      .data$site,
      .data$Id,
      .data$local_date,
      .data$participant_key,
      .data$elapsed_day,
      .data$metric_id,
      .data$timing_hour,
      .data$mctq_hour,
      .data$mctq_hour_centered,
      .data$meq_score,
      .data$meq_10_centered,
      .data$photoperiod_hours,
      .data$photoperiod_within_site,
      .data$valid_measurement_minutes,
      .data$expected_measurement_minutes,
      .data$l10_raw_hour,
      .data$l10_hour_noon_cut,
      .data$longest_exact_identifiable,
      .data$longest_censored,
      .data$longest_censor_reason,
      .data$longest_day_boundary_contact
    )
}

h09_frame_key <- function(data) {
  paste(
    data$site,
    data$Id,
    format(as.Date(data$local_date)),
    data$metric_id,
    sep = "|"
  )
}

h09_prepare_model_frame <- function(rows, instrument_id, site_levels) {
  predictor <- if (instrument_id == "MCTQ") {
    "mctq_hour_centered"
  } else {
    "meq_10_centered"
  }
  frame <- rows[
    is.finite(rows$timing_hour) & is.finite(rows[[predictor]]),
    ,
    drop = FALSE
  ]
  if (nrow(frame) == 0L) return(tibble::tibble())
  frame$site <- factor(as.character(frame$site), levels = site_levels)
  if (any(is.na(frame$site))) {
    h09_abort("H09 frame contains a site absent from the display registry")
  }
  frame$site <- droplevels(frame$site)
  if (nlevels(frame$site) < 2L) {
    h09_abort("An H09 model frame contains fewer than two sites")
  }
  stats::contrasts(frame$site) <- stats::contr.sum(nlevels(frame$site))
  frame$Id <- factor(as.character(frame$Id))
  frame$participant_key <- factor(as.character(frame$participant_key))
  frame$local_date <- as.Date(frame$local_date)
  frame$.model_row_id <- h09_frame_key(frame)
  frame <- frame[order(frame$site, frame$Id, frame$local_date), , drop = FALSE]
  if (anyDuplicated(frame$.model_row_id)) {
    h09_abort("H09 model row identifiers are not unique")
  }
  tibble::as_tibble(frame)
}

h09_frame_hash <- function(frame, include_values = TRUE) {
  if (nrow(frame) == 0L) return(NA_character_)
  columns <- c("site", "Id", "local_date")
  if (include_values) {
    columns <- c(
      columns,
      intersect(
        c(
          "timing_hour", "mctq_hour_centered", "meq_10_centered",
          "participant_mean_timing_hour"
        ),
        names(frame)
      )
    )
  }
  digest::digest(
    as.data.frame(frame[columns]),
    algo = "sha256",
    serialize = TRUE
  )
}

h09_key_hash <- function(frame) h09_frame_hash(frame, include_values = FALSE)

h09_sample_summary <- function(frame) {
  if (nrow(frame) == 0L) {
    return(tibble::tibble(
      participants = 0L,
      participant_days = 0L,
      observations = 0L,
      sites = 0L,
      derivation_hours = NA_real_,
      min_days_per_participant = NA_integer_,
      median_days_per_participant = NA_real_,
      max_days_per_participant = NA_integer_
    ))
  }
  days <- table(frame$participant_key)
  tibble::tibble(
    participants = dplyr::n_distinct(frame$participant_key),
    participant_days = dplyr::n_distinct(paste(
      frame$site, frame$Id, frame$local_date, sep = "|"
    )),
    observations = nrow(frame),
    sites = dplyr::n_distinct(frame$site),
    derivation_hours = h09_complete_sum(frame$valid_measurement_minutes) / 60,
    min_days_per_participant = min(days),
    median_days_per_participant = stats::median(days),
    max_days_per_participant = max(days)
  )
}

h09_sample_by_site <- function(frame) {
  if (nrow(frame) == 0L) return(tibble::tibble())
  frame |>
    dplyr::group_by(.data$site) |>
    dplyr::summarise(
      participants = dplyr::n_distinct(.data$participant_key),
      participant_days = dplyr::n(),
      observations = dplyr::n(),
      derivation_hours = h09_complete_sum(.data$valid_measurement_minutes) / 60,
      .groups = "drop"
    )
}

h09_capture_fit <- function(expression) {
  warnings <- character()
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
  if (inherits(model, "error")) {
    return(list(
      model = NULL,
      warnings = unique(warnings),
      error = conditionMessage(model)
    ))
  }
  list(model = model, warnings = unique(warnings), error = NA_character_)
}

h09_fit_lmer <- function(frame, formula, REML) {
  if (nrow(frame) == 0L) {
    return(list(model = NULL, warnings = character(), error = "No rows"))
  }
  fit <- h09_capture_fit(suppressMessages(lme4::lmer(
      formula = formula,
      data = as.data.frame(frame),
      REML = REML,
      na.action = stats::na.fail,
      control = lme4::lmerControl(
        optimizer = "nloptwrap",
        calc.derivs = TRUE,
        optCtrl = list(maxeval = 200000L)
      )
    )))
  if (!is.null(fit$model)) {
    fit$model@call$REML <- REML
  }
  fit
}

h09_fit_bundle <- function(frame, instrument_id) {
  formulas <- h09_formula_set(instrument_id, "participant_day")
  list(
    instrument_id = instrument_id,
    formulas = formulas,
    ml = list(
      M0_site_only = h09_fit_lmer(frame, formulas$M0_site_only, FALSE),
      M1_main = h09_fit_lmer(frame, formulas$M1_main, FALSE),
      M2_interaction = h09_fit_lmer(frame, formulas$M2_interaction, FALSE)
    ),
    reml = list(
      M1_main = h09_fit_lmer(frame, formulas$M1_main, TRUE),
      M2_interaction = h09_fit_lmer(frame, formulas$M2_interaction, TRUE)
    ),
    frame_key_hash = h09_key_hash(frame),
    frame_hash = h09_frame_hash(frame)
  )
}

h09_model_fit_status <- function(fit, frame = NULL) {
  model <- fit$model
  if (is.null(model)) {
    return(tibble::tibble(
      fit_status = "FAILED",
      converged = FALSE,
      optimizer_code = NA_integer_,
      positive_definite_hessian = FALSE,
      minimum_hessian_eigenvalue = NA_real_,
      max_gradient = NA_real_,
      singular = NA,
      fixed_rank = NA_integer_,
      fixed_columns = NA_integer_,
      fixed_full_rank = FALSE,
      warning_message = paste(fit$warnings, collapse = " | "),
      error_message = fit$error
    ))
  }
  messages <- model@optinfo$conv$lme4$messages
  optimizer_code <- model@optinfo$conv$opt
  gradient <- model@optinfo$derivs$gradient
  hessian <- model@optinfo$derivs$Hessian
  eigenvalues <- tryCatch(
    eigen(hessian, symmetric = TRUE, only.values = TRUE)$values,
    error = function(condition) NA_real_
  )
  matrix <- lme4::getME(model, "X")
  tibble::tibble(
    fit_status = "FITTED",
    converged = isTRUE(optimizer_code == 0L) && is.null(messages),
    optimizer_code = as.integer(optimizer_code),
    positive_definite_hessian = all(is.finite(eigenvalues)) &&
      min(eigenvalues) > 0,
    minimum_hessian_eigenvalue = suppressWarnings(min(eigenvalues)),
    max_gradient = if (is.null(gradient)) NA_real_ else
      max(abs(gradient), na.rm = TRUE),
    singular = lme4::isSingular(model, tol = 1e-4),
    fixed_rank = qr(as.matrix(matrix))$rank,
    fixed_columns = ncol(matrix),
    fixed_full_rank = qr(as.matrix(matrix))$rank == ncol(matrix),
    warning_message = if (length(c(fit$warnings, messages)) == 0L) {
      NA_character_
    } else {
      paste(unique(c(fit$warnings, messages)), collapse = " | ")
    },
    error_message = fit$error
  )
}

h09_nested_test <- function(reduced_fit, full_fit, comparison_id) {
  if (is.null(reduced_fit$model) || is.null(full_fit$model)) {
    return(tibble::tibble(
      comparison_id = comparison_id,
      chi_square = NA_real_,
      df = NA_real_,
      p_raw = NA_real_,
      comparison_status = "NON_ESTIMABLE",
      comparison_error = paste(
        c(reduced_fit$error, full_fit$error),
        collapse = " | "
      )
    ))
  }
  result <- tryCatch(
    stats::anova(reduced_fit$model, full_fit$model, refit = FALSE),
    error = function(condition) condition
  )
  if (inherits(result, "error")) {
    return(tibble::tibble(
      comparison_id = comparison_id,
      chi_square = NA_real_,
      df = NA_real_,
      p_raw = NA_real_,
      comparison_status = "NON_ESTIMABLE",
      comparison_error = conditionMessage(result)
    ))
  }
  last <- nrow(result)
  df_column <- if ("Chi Df" %in% names(result)) "Chi Df" else "Df"
  tibble::tibble(
    comparison_id = comparison_id,
    chi_square = as.numeric(result$Chisq[last]),
    df = as.numeric(result[[df_column]][last]),
    p_raw = as.numeric(result$`Pr(>Chisq)`[last]),
    comparison_status = "PASS",
    comparison_error = NA_character_
  )
}

h09_bundle_tests <- function(bundle) {
  dplyr::bind_rows(
    h09_nested_test(
      bundle$ml$M0_site_only,
      bundle$ml$M1_main,
      "main"
    ),
    h09_nested_test(
      bundle$ml$M1_main,
      bundle$ml$M2_interaction,
      "interaction"
    )
  )
}

h09_effect_summary <- function(fit, instrument_id) {
  predictor <- if (instrument_id == "MCTQ") {
    "mctq_hour_centered"
  } else {
    "meq_10_centered"
  }
  model <- fit$model
  if (is.null(model) || !predictor %in% names(lme4::fixef(model))) {
    return(tibble::tibble(
      estimate = NA_real_,
      std_error = NA_real_,
      conf_low = NA_real_,
      conf_high = NA_real_,
      interval_method = "Wald normal 95% confidence interval",
      effect_status = "NON_ESTIMABLE"
    ))
  }
  estimate <- unname(lme4::fixef(model)[predictor])
  standard_error <- sqrt(diag(as.matrix(stats::vcov(model))))[predictor]
  tibble::tibble(
    estimate = estimate,
    std_error = standard_error,
    conf_low = estimate - stats::qnorm(0.975) * standard_error,
    conf_high = estimate + stats::qnorm(0.975) * standard_error,
    interval_method = "Wald normal 95% confidence interval",
    effect_status = "PASS"
  )
}

h09_performance_summary <- function(model) {
  if (is.null(model)) {
    return(tibble::tibble(
      random_intercept_variance = NA_real_,
      residual_variance = NA_real_,
      icc = NA_real_,
      marginal_r2 = NA_real_,
      conditional_r2 = NA_real_,
      performance_interval_status = "NON_ESTIMABLE_MODEL_FAILED"
    ))
  }
  variance_components <- as.data.frame(lme4::VarCorr(model))
  random_variance <- sum(
    variance_components$vcov[variance_components$grp != "Residual"],
    na.rm = TRUE
  )
  residual_variance <- sigma(model)^2
  fixed_prediction <- as.numeric(
    lme4::getME(model, "X") %*% lme4::fixef(model)
  )
  fixed_variance <- stats::var(fixed_prediction)
  denominator <- fixed_variance + random_variance + residual_variance
  tibble::tibble(
    random_intercept_variance = random_variance,
    residual_variance = residual_variance,
    icc = random_variance / (random_variance + residual_variance),
    marginal_r2 = fixed_variance / denominator,
    conditional_r2 = (fixed_variance + random_variance) / denominator,
    performance_interval_status = paste(
      "Point summaries only; a valid 95% interval would require resampling",
      "and remains outside the approved no-production-resampling gate"
    )
  )
}

h09_site_slopes <- function(fit, frame, instrument_id) {
  if (is.null(fit$model)) return(tibble::tibble())
  predictor <- if (instrument_id == "MCTQ") {
    "mctq_hour_centered"
  } else {
    "meq_10_centered"
  }
  result <- tryCatch(
    suppressMessages(emmeans::emtrends(
      fit$model,
      specs = ~site,
      var = predictor,
      lmer.df = "asymptotic"
    )),
    error = function(condition) condition
  )
  if (inherits(result, "error")) {
    return(tibble::tibble(
      site = levels(frame$site),
      estimate = NA_real_,
      std_error = NA_real_,
      conf_low = NA_real_,
      conf_high = NA_real_,
      slope_status = paste0("NON_ESTIMABLE: ", conditionMessage(result))
    ))
  }
  output <- as.data.frame(summary(result, infer = c(TRUE, FALSE)))
  trend_column <- grep("[.]trend$", names(output), value = TRUE)[1L]
  tibble::tibble(
    site = as.character(output$site),
    estimate = as.numeric(output[[trend_column]]),
    std_error = as.numeric(output$SE),
    conf_low = as.numeric(output$asymp.LCL),
    conf_high = as.numeric(output$asymp.UCL),
    slope_status = "DESCRIPTIVE"
  )
}

h09_residual_diagnostics <- function(model, frame) {
  if (is.null(model)) {
    return(tibble::tibble(
      residual_skewness = NA_real_,
      residual_excess_kurtosis = NA_real_,
      qq_correlation = NA_real_,
      max_abs_standardized_residual = NA_real_,
      abs_residual_fitted_spearman = NA_real_,
      site_residual_sd_ratio = NA_real_,
      distribution_assessment = "not acceptable",
      heteroscedasticity_assessment = "not acceptable"
    ))
  }
  residual <- stats::residuals(model) / sigma(model)
  fitted <- stats::fitted(model)
  centered <- residual - mean(residual)
  sd_residual <- stats::sd(residual)
  skewness <- mean(centered^3) / sd_residual^3
  excess_kurtosis <- mean(centered^4) / sd_residual^4 - 3
  qq_correlation <- stats::cor(
    sort(residual),
    stats::qnorm(stats::ppoints(length(residual)))
  )
  site_sd <- tapply(residual, frame$site, stats::sd, na.rm = TRUE)
  site_sd <- site_sd[is.finite(site_sd) & site_sd > 0]
  site_ratio <- if (length(site_sd) < 2L) NA_real_ else
    max(site_sd) / min(site_sd)
  fitted_correlation <- suppressWarnings(stats::cor(
    abs(residual),
    fitted,
    method = "spearman",
    use = "complete.obs"
  ))
  distribution_ok <-
    is.finite(qq_correlation) && qq_correlation >= 0.970 &&
    is.finite(skewness) && abs(skewness) <= 2 &&
    is.finite(excess_kurtosis) && abs(excess_kurtosis) <= 7 &&
    max(abs(residual)) <= 5
  heteroscedasticity_ok <-
    is.finite(fitted_correlation) && abs(fitted_correlation) <= 0.20 &&
    is.finite(site_ratio) && site_ratio <= 2.5
  tibble::tibble(
    residual_skewness = skewness,
    residual_excess_kurtosis = excess_kurtosis,
    qq_correlation = qq_correlation,
    max_abs_standardized_residual = max(abs(residual)),
    abs_residual_fitted_spearman = fitted_correlation,
    site_residual_sd_ratio = site_ratio,
    distribution_assessment = if (distribution_ok) {
      "acceptable"
    } else {
      "not acceptable"
    },
    heteroscedasticity_assessment = if (heteroscedasticity_ok) {
      "acceptable"
    } else {
      "not acceptable"
    }
  )
}

h09_diagnostic_plot_data <- function(model, frame) {
  if (is.null(model)) return(tibble::tibble())
  residual <- stats::residuals(model) / sigma(model)
  tibble::tibble(
    .model_row_id = frame$.model_row_id,
    site = as.character(frame$site),
    participant_key = as.character(frame$participant_key),
    local_date = frame$local_date,
    fitted = as.numeric(stats::fitted(model)),
    standardized_residual = as.numeric(residual),
    theoretical_quantile = stats::qnorm(stats::ppoints(length(residual)))[
      rank(residual, ties.method = "first")
    ],
    sample_quantile = as.numeric(residual)
  )
}

h09_serial_diagnostic <- function(model, frame) {
  if (is.null(model)) {
    return(tibble::tibble(
      adjacent_pairs = 0L,
      one_day_pairs = 0L,
      adjacent_residual_correlation = NA_real_,
      one_day_residual_correlation = NA_real_
    ))
  }
  work <- tibble::tibble(
    participant_key = as.character(frame$participant_key),
    local_date = as.Date(frame$local_date),
    residual = as.numeric(stats::residuals(model) / sigma(model))
  ) |>
    dplyr::arrange(.data$participant_key, .data$local_date) |>
    dplyr::group_by(.data$participant_key) |>
    dplyr::mutate(
      next_residual = dplyr::lead(.data$residual),
      day_gap = as.numeric(dplyr::lead(.data$local_date) - .data$local_date)
    ) |>
    dplyr::ungroup() |>
    dplyr::filter(is.finite(.data$next_residual), .data$day_gap > 0)
  one_day <- work[work$day_gap == 1, , drop = FALSE]
  safe_cor <- function(x, y) {
    if (length(x) < 3L || stats::sd(x) == 0 || stats::sd(y) == 0) {
      NA_real_
    } else {
      stats::cor(x, y)
    }
  }
  tibble::tibble(
    adjacent_pairs = nrow(work),
    one_day_pairs = nrow(one_day),
    adjacent_residual_correlation = safe_cor(
      work$residual, work$next_residual
    ),
    one_day_residual_correlation = safe_cor(
      one_day$residual, one_day$next_residual
    )
  )
}

h09_linearity_diagnostic <- function(frame, bundle, instrument_id) {
  formulas <- h09_formula_set(instrument_id, "participant_day")
  spline_fit <- h09_fit_lmer(frame, formulas$D_spline, FALSE)
  linear_fit <- bundle$ml$M1_main
  predictor <- if (instrument_id == "MCTQ") {
    "mctq_hour_centered"
  } else {
    "meq_10_centered"
  }
  if (is.null(linear_fit$model) || is.null(spline_fit$model)) {
    return(list(
      summary = tibble::tibble(
        spline_status = "NON_ESTIMABLE",
        spline_error = paste(
          c(linear_fit$error, spline_fit$error), collapse = " | "
        ),
        spline_lrt_p = NA_real_,
        spline_aic_improvement = NA_real_,
        max_anchored_departure_hour = NA_real_,
        linearity_assessment = "not acceptable"
      ),
      curve = tibble::tibble(),
      fit = spline_fit
    ))
  }
  comparison <- tryCatch(
    stats::anova(linear_fit$model, spline_fit$model, refit = FALSE),
    error = function(condition) condition
  )
  spline_lrt_p <- if (inherits(comparison, "error")) {
    NA_real_
  } else {
    as.numeric(comparison$`Pr(>Chisq)`[nrow(comparison)])
  }
  limits <- stats::quantile(
    frame[[predictor]],
    probs = c(0.025, 0.975),
    na.rm = TRUE
  )
  grid_value <- seq(limits[[1L]], limits[[2L]], length.out = 101L)
  newdata <- expand.grid(
    site = levels(frame$site),
    predictor_value = grid_value,
    KEEP.OUT.ATTRS = FALSE,
    stringsAsFactors = FALSE
  )
  names(newdata)[names(newdata) == "predictor_value"] <- predictor
  newdata$site <- factor(newdata$site, levels = levels(frame$site))
  stats::contrasts(newdata$site) <- stats::contr.sum(nlevels(newdata$site))
  newdata$Id <- factor(rep(levels(frame$Id)[1L], nrow(newdata)),
    levels = levels(frame$Id))
  newdata$participant_key <- factor(
    rep(levels(frame$participant_key)[1L], nrow(newdata)),
    levels = levels(frame$participant_key)
  )
  linear_prediction <- stats::predict(
    linear_fit$model,
    newdata = newdata,
    re.form = NA,
    allow.new.levels = TRUE
  )
  spline_prediction <- stats::predict(
    spline_fit$model,
    newdata = newdata,
    re.form = NA,
    allow.new.levels = TRUE
  )
  curve <- tibble::tibble(
    predictor_value = newdata[[predictor]],
    site = as.character(newdata$site),
    linear_prediction = as.numeric(linear_prediction),
    spline_prediction = as.numeric(spline_prediction)
  ) |>
    dplyr::group_by(.data$predictor_value) |>
    dplyr::summarise(
      linear_prediction = mean(.data$linear_prediction),
      spline_prediction = mean(.data$spline_prediction),
      .groups = "drop"
    )
  anchor <- which.min(abs(curve$predictor_value))
  curve <- curve |>
    dplyr::mutate(
      linear_anchored = .data$linear_prediction -
        .data$linear_prediction[anchor],
      spline_anchored = .data$spline_prediction -
        .data$spline_prediction[anchor],
      anchored_departure_hour =
        .data$spline_anchored - .data$linear_anchored
    )
  aic_improvement <- stats::AIC(linear_fit$model) -
    stats::AIC(spline_fit$model)
  departure <- max(abs(curve$anchored_departure_hour))
  acceptable <- !(aic_improvement >= 4 && departure >= 0.25)
  list(
    summary = tibble::tibble(
      spline_status = "FITTED",
      spline_error = NA_character_,
      spline_lrt_p = spline_lrt_p,
      spline_aic_improvement = aic_improvement,
      max_anchored_departure_hour = departure,
      linearity_assessment = if (acceptable) {
        "acceptable"
      } else {
        "not acceptable"
      }
    ),
    curve = curve,
    fit = spline_fit
  )
}

h09_fit_ar1 <- function(frame, instrument_id, reference_effect) {
  formulas <- h09_formula_set(instrument_id, "temporal")
  predictor <- if (instrument_id == "MCTQ") {
    "mctq_hour_centered"
  } else {
    "meq_10_centered"
  }
  fit <- h09_capture_fit(nlme::lme(
    fixed = formulas$fixed,
    random = formulas$random,
    correlation = nlme::corCAR1(form = formulas$correlation),
    data = as.data.frame(frame),
    method = "REML",
    na.action = stats::na.fail,
    control = nlme::lmeControl(
      opt = "optim",
      maxIter = 200L,
      msMaxIter = 200L,
      niterEM = 50L,
      returnObject = TRUE
    )
  ))
  if (is.null(fit$model)) {
    return(tibble::tibble(
      ar1_status = "NON_ESTIMABLE",
      ar1_error = fit$error,
      ar1_warnings = paste(fit$warnings, collapse = " | "),
      ar1_estimate = NA_real_,
      ar1_std_error = NA_real_,
      ar1_conf_low = NA_real_,
      ar1_conf_high = NA_real_,
      ar1_phi = NA_real_,
      ar1_effect_difference = NA_real_,
      ar1_interval_overlap = FALSE,
      ar1_direction_stable = FALSE
    ))
  }
  table <- summary(fit$model)$tTable
  estimate <- as.numeric(table[predictor, "Value"])
  standard_error <- as.numeric(table[predictor, "Std.Error"])
  low <- estimate - stats::qnorm(0.975) * standard_error
  high <- estimate + stats::qnorm(0.975) * standard_error
  phi <- as.numeric(stats::coef(
    fit$model$modelStruct$corStruct,
    unconstrained = FALSE
  ))
  tibble::tibble(
    ar1_status = "FITTED",
    ar1_error = NA_character_,
    ar1_warnings = if (length(fit$warnings)) {
      paste(fit$warnings, collapse = " | ")
    } else {
      NA_character_
    },
    ar1_estimate = estimate,
    ar1_std_error = standard_error,
    ar1_conf_low = low,
    ar1_conf_high = high,
    ar1_phi = phi,
    ar1_effect_difference = estimate - reference_effect$estimate,
    ar1_interval_overlap = low <= reference_effect$conf_high &&
      high >= reference_effect$conf_low,
    ar1_direction_stable = isTRUE(
      sign(estimate) == sign(reference_effect$estimate)
    )
  )
}

h09_temporal_assessment <- function(serial, ar1) {
  raw_correlation <- serial$one_day_residual_correlation
  if (!is.finite(raw_correlation)) {
    raw_correlation <- serial$adjacent_residual_correlation
  }
  low_autocorrelation <- is.finite(raw_correlation) &&
    abs(raw_correlation) <= 0.20
  stable_correction <-
    ar1$ar1_status == "FITTED" &&
    isTRUE(ar1$ar1_direction_stable) &&
    isTRUE(ar1$ar1_interval_overlap) &&
    is.finite(ar1$ar1_effect_difference) &&
    abs(ar1$ar1_effect_difference) < 0.25
  if (low_autocorrelation || stable_correction) "acceptable" else
    "not acceptable"
}

h09_prepare_participant_summary <- function(frame) {
  summary <- frame |>
    dplyr::group_by(.data$site, .data$Id, .data$participant_key) |>
    dplyr::summarise(
      participant_mean_timing_hour = mean(.data$timing_hour),
      mctq_hour_centered = dplyr::first(.data$mctq_hour_centered),
      meq_10_centered = dplyr::first(.data$meq_10_centered),
      participant_days = dplyr::n(),
      derivation_hours = h09_complete_sum(
        .data$valid_measurement_minutes
      ) / 60,
      .groups = "drop"
    )
  summary$site <- factor(as.character(summary$site), levels = levels(frame$site))
  summary$site <- droplevels(summary$site)
  stats::contrasts(summary$site) <- stats::contr.sum(nlevels(summary$site))
  summary$Id <- factor(as.character(summary$Id))
  summary$participant_key <- factor(as.character(summary$participant_key))
  summary
}

h09_fit_lm_effect <- function(frame, formulas, predictor) {
  fit <- h09_capture_fit(stats::lm(
    formula = formulas$S1_main,
    data = as.data.frame(frame),
    na.action = stats::na.fail
  ))
  if (is.null(fit$model)) {
    return(tibble::tibble(
      status = "NON_ESTIMABLE",
      error = fit$error,
      estimate = NA_real_,
      std_error = NA_real_,
      conf_low = NA_real_,
      conf_high = NA_real_
    ))
  }
  coefficients <- summary(fit$model)$coefficients
  estimate <- coefficients[predictor, "Estimate"]
  standard_error <- coefficients[predictor, "Std. Error"]
  tibble::tibble(
    status = "FITTED",
    error = NA_character_,
    estimate = estimate,
    std_error = standard_error,
    conf_low = estimate - stats::qnorm(0.975) * standard_error,
    conf_high = estimate + stats::qnorm(0.975) * standard_error
  )
}

h09_fit_photoperiod <- function(frame, instrument_id) {
  formulas <- h09_formula_set(instrument_id, "photoperiod")
  predictor <- if (instrument_id == "MCTQ") {
    "mctq_hour_centered"
  } else {
    "meq_10_centered"
  }
  fit <- h09_fit_lmer(frame, formulas$P1_main, TRUE)
  effect <- h09_effect_summary(fit, instrument_id)
  dplyr::bind_cols(
    effect,
    h09_model_fit_status(fit) |>
      dplyr::select(
        .data$converged,
        .data$positive_definite_hessian,
        .data$singular,
        .data$fixed_full_rank,
        .data$warning_message,
        .data$error_message
      )
  )
}

h09_participant_influence <- function(model, frame, instrument_id) {
  predictor <- if (instrument_id == "MCTQ") {
    "mctq_hour_centered"
  } else {
    "meq_10_centered"
  }
  if (is.null(model)) return(tibble::tibble())
  influence_object <- tryCatch(
    suppressMessages(stats::influence(
        model,
        groups = "participant_key",
        data = as.data.frame(frame),
        maxfun = 20000L,
        parallel = "no"
      )),
    error = function(condition) condition
  )
  if (inherits(influence_object, "error")) {
    return(tibble::tibble(
      participant_key = levels(frame$participant_key),
      deletion_converged = FALSE,
      deleted_estimate = NA_real_,
      estimate_change = NA_real_,
      dfbeta = NA_real_,
      cooks_distance = NA_real_,
      dfbeta_threshold = 2 / sqrt(nlevels(frame$participant_key)),
      dfbeta_flag = NA,
      sign_reversal = NA,
      material_change = NA,
      influence_error = conditionMessage(influence_object)
    ))
  }
  deleted <- influence_object[[2L]][, predictor]
  dfbeta <- stats::dfbetas(influence_object)[, predictor]
  cooks <- stats::cooks.distance(influence_object)
  full <- unname(lme4::fixef(model)[predictor])
  threshold <- 2 / sqrt(nlevels(frame$participant_key))
  output <- tibble::tibble(
    participant_key = names(deleted),
    deletion_converged = as.logical(influence_object$converged),
    deleted_estimate = as.numeric(deleted),
    estimate_change = as.numeric(deleted - full),
    dfbeta = as.numeric(dfbeta),
    cooks_distance = as.numeric(cooks),
    dfbeta_threshold = threshold,
    influence_error = NA_character_
  )
  output |>
    dplyr::mutate(
      dfbeta_flag = abs(.data$dfbeta) > threshold,
      sign_reversal = sign(.data$deleted_estimate) != sign(full),
      material_change = abs(.data$estimate_change) >= 0.25
    )
}

h09_influence_summary <- function(influence_rows) {
  if (nrow(influence_rows) == 0L) {
    return(tibble::tibble(
      participants_checked = 0L,
      failed_deletions = 0L,
      dfbeta_flags = 0L,
      sign_reversals = 0L,
      material_changes = 0L,
      max_abs_dfbeta = NA_real_,
      max_abs_estimate_change = NA_real_,
      influence_assessment = "not acceptable"
    ))
  }
  failed <- sum(!influence_rows$deletion_converged)
  sign_reversals <- sum(influence_rows$sign_reversal %in% TRUE, na.rm = TRUE)
  material_changes <- sum(influence_rows$material_change %in% TRUE,
    na.rm = TRUE)
  acceptable <- failed == 0L && sign_reversals == 0L && material_changes == 0L
  tibble::tibble(
    participants_checked = nrow(influence_rows),
    failed_deletions = failed,
    dfbeta_flags = sum(influence_rows$dfbeta_flag %in% TRUE, na.rm = TRUE),
    sign_reversals = sign_reversals,
    material_changes = material_changes,
    max_abs_dfbeta = suppressWarnings(max(abs(influence_rows$dfbeta),
      na.rm = TRUE)),
    max_abs_estimate_change = suppressWarnings(max(
      abs(influence_rows$estimate_change), na.rm = TRUE
    )),
    influence_assessment = if (acceptable) {
      "acceptable"
    } else {
      "not acceptable"
    }
  )
}

h09_leave_one_site_out <- function(frame, instrument_id, full_estimate) {
  formulas <- h09_formula_set(instrument_id, "participant_day")
  predictor <- if (instrument_id == "MCTQ") {
    "mctq_hour_centered"
  } else {
    "meq_10_centered"
  }
  purrr::map_dfr(levels(frame$site), function(removed_site) {
    reduced <- frame[as.character(frame$site) != removed_site, , drop = FALSE]
    reduced$site <- droplevels(reduced$site)
    stats::contrasts(reduced$site) <- stats::contr.sum(nlevels(reduced$site))
    reduced$Id <- droplevels(reduced$Id)
    reduced$participant_key <- droplevels(reduced$participant_key)
    fit <- h09_fit_lmer(reduced, formulas$M1_main, TRUE)
    if (is.null(fit$model)) {
      return(tibble::tibble(
        removed_site = removed_site,
        remaining_participants = dplyr::n_distinct(reduced$participant_key),
        remaining_participant_days = nrow(reduced),
        refit_status = "NON_ESTIMABLE",
        refit_error = fit$error,
        estimate = NA_real_,
        std_error = NA_real_,
        conf_low = NA_real_,
        conf_high = NA_real_,
        estimate_change = NA_real_,
        sign_reversal = NA,
        material_change = NA
      ))
    }
    estimate <- unname(lme4::fixef(fit$model)[predictor])
    standard_error <- sqrt(diag(as.matrix(stats::vcov(fit$model))))[predictor]
    output <- tibble::tibble(
      removed_site = removed_site,
      remaining_participants = dplyr::n_distinct(reduced$participant_key),
      remaining_participant_days = nrow(reduced),
      refit_status = "FITTED",
      refit_error = NA_character_,
      estimate = estimate,
      std_error = standard_error,
      conf_low = estimate - stats::qnorm(0.975) * standard_error,
      conf_high = estimate + stats::qnorm(0.975) * standard_error,
      estimate_change = estimate - full_estimate
    )
    output |>
      dplyr::mutate(
        sign_reversal = sign(.data$estimate) != sign(full_estimate),
        material_change = abs(.data$estimate_change) >= 0.25
      )
  })
}

h09_loo_summary <- function(rows) {
  failed <- sum(rows$refit_status != "FITTED")
  reversals <- sum(rows$sign_reversal %in% TRUE, na.rm = TRUE)
  material <- sum(rows$material_change %in% TRUE, na.rm = TRUE)
  tibble::tibble(
    sites_checked = nrow(rows),
    failed_refits = failed,
    sign_reversals = reversals,
    material_changes = material,
    max_abs_estimate_change = suppressWarnings(max(
      abs(rows$estimate_change), na.rm = TRUE
    )),
    site_influence_assessment = if (
      failed == 0L && reversals == 0L && material == 0L
    ) {
      "acceptable"
    } else {
      "not acceptable"
    }
  )
}

h09_load_v0_metrics <- function(path) {
  environment <- new.env(parent = emptyenv())
  object_name <- load(path, envir = environment)
  environment[[object_name[[1L]]]]
}

h09_prepare_v0_rows <- function(path, placement, chronotype, site_levels) {
  object <- h09_load_v0_metrics(path)
  crosswalk <- tibble::tribble(
    ~v0_name, ~metric_id,
    "brightest_10h_midpoint", "m10_midpoint",
    "darkest_10h_midpoint", "l10_midpoint",
    "mean_timing_above_250", "mean_timing_above_250",
    "first_timing_above_250", "first_timing_above_250",
    "last_timing_above_250", "last_timing_above_250"
  )
  chronotype_rows <- chronotype |>
    dplyr::transmute(
      .data$site,
      .data$Id,
      mctq_hour = as.numeric(.data$msf_sc) / 3600
    )
  purrr::map_dfr(seq_len(nrow(crosswalk)), function(index) {
    metric_index <- match(crosswalk$v0_name[index], object$name)
    object$data[[metric_index]] |>
      tibble::as_tibble() |>
      dplyr::rename(local_date = .data$Date) |>
      dplyr::left_join(
        chronotype_rows,
        by = c("site", "Id"),
        relationship = "many-to-one"
      ) |>
      dplyr::filter(is.finite(.data$metric), is.finite(.data$mctq_hour)) |>
      dplyr::transmute(
        placement = placement,
        metric_id = crosswalk$metric_id[index],
        v0_name = crosswalk$v0_name[index],
        .data$site,
        .data$Id,
        local_date = as.Date(.data$local_date),
        timing_hour = as.numeric(.data$metric),
        .data$mctq_hour,
        photoperiod_hours = as.numeric(.data$photoperiod)
      )
  }) |>
    dplyr::mutate(
      site = factor(.data$site, levels = site_levels),
      Id = factor(.data$Id)
    ) |>
    droplevels()
}

h09_reproduce_v0_target <- function(frame) {
  formulas <- h09_v0_formula_set()
  fits <- lapply(formulas, function(formula) {
    h09_fit_lmer(frame, formula, TRUE)
  })
  if (any(vapply(fits, function(x) is.null(x$model), logical(1)))) {
    return(list(
      summary = tibble::tibble(
        v0_status = "NON_ESTIMABLE",
        participants = dplyr::n_distinct(frame$Id),
        participant_days = nrow(frame),
        sites = dplyr::n_distinct(frame$site),
        estimate = NA_real_,
        std_error = NA_real_,
        conf_low = NA_real_,
        conf_high = NA_real_,
        p_raw = NA_real_,
        p_scalar_fdr_n5 = NA_real_,
        interaction_p_scalar_fdr_n5 = NA_real_,
        site_p_scalar_fdr_n5 = NA_real_,
        marginal_r2 = NA_real_
      ),
      fits = fits
    ))
  }
  comparison <- function(a, b) {
    result <- suppressMessages(stats::anova(a$model, b$model))
    as.numeric(result$`Pr(>Chisq)`[nrow(result)])
  }
  p_main <- comparison(fits$H9_00, fits$H9_ns)
  p_interaction <- comparison(fits$H9_ni, fits$H9_1)
  p_site <- comparison(fits$H9_ns, fits$H9_ni)
  coefficient <- summary(fits$H9_ns$model)$coefficients["mctq_hour", ]
  performance <- h09_performance_summary(fits$H9_ns$model)
  list(
    summary = tibble::tibble(
      v0_status = "REPRODUCED",
      participants = dplyr::n_distinct(frame$Id),
      participant_days = nrow(frame),
      sites = dplyr::n_distinct(frame$site),
      estimate = unname(coefficient["Estimate"]),
      std_error = unname(coefficient["Std. Error"]),
      conf_low = unname(coefficient["Estimate"] -
        stats::qnorm(0.975) * coefficient["Std. Error"]),
      conf_high = unname(coefficient["Estimate"] +
        stats::qnorm(0.975) * coefficient["Std. Error"]),
      p_raw = p_main,
      p_scalar_fdr_n5 = stats::p.adjust(p_main, method = "fdr", n = 5L),
      interaction_p_scalar_fdr_n5 = stats::p.adjust(
        p_interaction, method = "fdr", n = 5L
      ),
      site_p_scalar_fdr_n5 = stats::p.adjust(
        p_site, method = "fdr", n = 5L
      ),
      marginal_r2 = performance$marginal_r2
    ),
    fits = fits
  )
}
