# H06_daily H06-D-007 model fitting, clock diagnostics, and deletion helpers.

h06d_nl_capture <- function(expression) {
  warnings <- character()
  started <- proc.time()[["elapsed"]]
  value <- tryCatch(
    withCallingHandlers(
      expression,
      warning = function(condition) {
        warnings <<- c(warnings, conditionMessage(condition))
        invokeRestart("muffleWarning")
      }
    ),
    error = function(condition) condition
  )
  elapsed <- unname(proc.time()[["elapsed"]] - started)
  list(
    value = if (inherits(value, "error")) NULL else value,
    error = if (inherits(value, "error")) conditionMessage(value) else NA_character_,
    warnings = unique(warnings),
    elapsed_seconds = elapsed
  )
}

h06d_nl_fit_model <- function(
  frame,
  formula,
  response_family,
  REML = TRUE,
  ar = FALSE
) {
  if (identical(response_family, "gaussian") && !isTRUE(ar)) {
    return(h06d_nl_capture(lme4::lmer(
      formula = formula,
      data = frame,
      REML = REML,
      control = lme4::lmerControl(
        optimizer = "nloptwrap",
        calc.derivs = TRUE,
        optCtrl = list(maxeval = 10000L)
      )
    )))
  }
  if (identical(response_family, "tweedie_log") && !isTRUE(ar)) {
    return(h06d_nl_capture(glmmTMB::glmmTMB(
      formula = formula,
      data = frame,
      family = glmmTMB::tweedie(link = "log"),
      REML = FALSE,
      control = glmmTMB::glmmTMBControl(
        optCtrl = list(iter.max = 10000L, eval.max = 10000L)
      )
    )))
  }
  if (identical(response_family, "gaussian") && isTRUE(ar)) {
    return(h06d_nl_capture(glmmTMB::glmmTMB(
      formula = formula,
      data = frame,
      family = stats::gaussian(link = "identity"),
      REML = REML,
      control = glmmTMB::glmmTMBControl(
        optCtrl = list(iter.max = 10000L, eval.max = 10000L)
      )
    )))
  }
  h06d_nl_abort("Unsupported non-L10 model family or AR combination")
}

h06d_nl_model_status <- function(model) {
  if (is.null(model)) {
    return(tibble::tibble(
      converged = FALSE,
      positive_definite_hessian = FALSE,
      singular = NA,
      maximum_absolute_gradient = NA_real_,
      convergence_message = "fit failed"
    ))
  }
  if (inherits(model, "merMod")) {
    messages <- unlist(model@optinfo$conv$lme4$messages, use.names = FALSE)
    gradient <- model@optinfo$derivs$gradient
    maximum_gradient <- if (is.null(gradient)) 0 else max(abs(gradient))
    hessian <- model@optinfo$derivs$Hessian
    pd_hessian <- if (is.null(hessian)) {
      NA
    } else {
      all(eigen(hessian, symmetric = TRUE, only.values = TRUE)$values > 0)
    }
    return(tibble::tibble(
      converged = length(messages) == 0L && maximum_gradient <= 0.002,
      positive_definite_hessian = pd_hessian,
      singular = lme4::isSingular(model, tol = 1e-4),
      maximum_absolute_gradient = maximum_gradient,
      convergence_message = if (length(messages)) {
        paste(messages, collapse = " | ")
      } else {
        "full convergence"
      }
    ))
  }
  if (inherits(model, "glmmTMB")) {
    return(tibble::tibble(
      converged = identical(as.integer(model$fit$convergence), 0L) &&
        isTRUE(model$sdr$pdHess),
      positive_definite_hessian = isTRUE(model$sdr$pdHess),
      singular = tryCatch(
        as.logical(performance::check_singularity(model)),
        error = function(condition) NA
      ),
      maximum_absolute_gradient = NA_real_,
      convergence_message = paste(model$fit$message, collapse = " | ")
    ))
  }
  h06d_nl_abort("Unknown non-L10 model class")
}

h06d_nl_fixed_table <- function(model) {
  if (inherits(model, "merMod")) {
    estimate <- lme4::fixef(model)
    covariance <- as.matrix(stats::vcov(model))
  } else if (inherits(model, "glmmTMB")) {
    estimate <- glmmTMB::fixef(model)$cond
    covariance <- as.matrix(stats::vcov(model)$cond)
  } else {
    h06d_nl_abort("Cannot extract fixed effects from non-L10 model")
  }
  standard_error <- sqrt(diag(covariance))
  critical <- stats::qnorm(0.975)
  tibble::tibble(
    term = names(estimate),
    estimate = unname(estimate),
    standard_error = unname(standard_error),
    lower_95 = unname(estimate - critical * standard_error),
    upper_95 = unname(estimate + critical * standard_error)
  )
}

h06d_nl_effect_row <- function(model, predictor, metric) {
  term <- predictor$term[[1L]]
  selected <- h06d_nl_fixed_table(model) |>
    dplyr::filter(.data$term == .env$term)
  h06d_nl_assert(
    nrow(selected) == 1L,
    "Effect term `%s` was not uniquely estimated",
    term
  )
  base <- if (metric$response_transform[[1L]] == "log10_offset_0.1") {
    10
  } else if (metric$response_family[[1L]] == "tweedie_log") {
    exp(1)
  } else {
    NA_real_
  }
  selected |>
    dplyr::mutate(
      metric_slot = .env$metric$metric_slot[[1L]],
      metric_id = .env$metric$metric_id[[1L]],
      manuscript_name = .env$metric$manuscript_name[[1L]],
      predictor_order = .env$predictor$predictor_order[[1L]],
      predictor_id = .env$predictor$predictor_id[[1L]],
      predictor = .env$predictor$reader_name[[1L]],
      contrast = .env$predictor$contrast_label[[1L]],
      response_family = .env$metric$response_family[[1L]],
      response_transform = .env$metric$response_transform[[1L]],
      effect_scale = .env$metric$effect_scale[[1L]],
      display_estimate = if (is.finite(.env$base)) {
        .env$base^.data$estimate
      } else {
        .data$estimate
      },
      display_lower_95 = if (is.finite(.env$base)) {
        .env$base^.data$lower_95
      } else {
        .data$lower_95
      },
      display_upper_95 = if (is.finite(.env$base)) {
        .env$base^.data$upper_95
      } else {
        .data$upper_95
      }
    )
}

h06d_nl_inverse_response <- function(value, metric) {
  if (metric$response_family[[1L]] == "tweedie_log") {
    return(exp(value))
  }
  switch(
    metric$response_transform[[1L]],
    identity = value,
    log10_offset_0.1 = 10^value - 0.1,
    clock_hours = value %% 24,
    clock_hours_midnight_after_16 = value %% 24,
    h06d_nl_abort("Unknown inverse transformation")
  )
}

h06d_nl_prediction_bounds <- function(model, frame, metric) {
  link_prediction <- if (inherits(model, "glmmTMB")) {
    as.numeric(stats::predict(model, type = "link"))
  } else {
    as.numeric(stats::predict(model))
  }
  prediction <- h06d_nl_inverse_response(link_prediction, metric)
  lower <- metric$lower_bound[[1L]]
  upper <- metric$upper_bound[[1L]]
  if (
    metric$metric_id[[1L]] %in% c(
      "duration_above_250_wake",
      "duration_below_1_sleep_environment"
    ) && all(is.finite(frame$expected_minutes))
  ) {
    upper_values <- frame$expected_minutes / 60
  } else {
    upper_values <- rep(upper, nrow(frame))
  }
  below <- if (is.finite(lower)) {
    mean(prediction < lower - 0.05)
  } else {
    0
  }
  above <- if (any(is.finite(upper_values))) {
    mean(prediction > upper_values + 0.05, na.rm = TRUE)
  } else {
    0
  }
  tibble::tibble(
    conditional_prediction_below_fraction = below,
    conditional_prediction_above_fraction = above,
    prediction_bound_acceptable = below <= 0.01 && above <= 0.01,
    unwrapped_prediction_minimum = min(link_prediction),
    unwrapped_prediction_maximum = max(link_prediction)
  )
}

h06d_nl_gaussian_residual_diagnostics <- function(model) {
  residual <- as.numeric(stats::residuals(model))
  fitted <- as.numeric(stats::fitted(model))
  sigma <- stats::sd(residual)
  standardized <- residual / sigma
  theoretical <- stats::qnorm(stats::ppoints(length(standardized)))
  tibble::tibble(
    residual_qq_correlation = stats::cor(sort(standardized), theoretical),
    absolute_residual_fitted_spearman = suppressWarnings(stats::cor(
      abs(residual),
      fitted,
      method = "spearman",
      use = "complete.obs"
    )),
    standardized_residual_gt4_fraction = mean(abs(standardized) > 4),
    residual_minimum = min(residual),
    residual_maximum = max(residual)
  )
}

h06d_nl_lag_screen <- function(frame, residual) {
  lag_rows <- frame |>
    dplyr::mutate(.residual = as.numeric(residual)) |>
    dplyr::arrange(.data$participant_key, .data$local_date) |>
    dplyr::group_by(.data$participant_key) |>
    dplyr::mutate(
      previous_residual = dplyr::lag(.data$.residual),
      previous_date = dplyr::lag(.data$local_date),
      date_gap = as.integer(.data$local_date - .data$previous_date)
    ) |>
    dplyr::ungroup() |>
    dplyr::filter(
      .data$date_gap == 1L,
      is.finite(.data$.residual),
      is.finite(.data$previous_residual)
    )
  by_site <- lag_rows |>
    dplyr::summarise(
      adjacent_pairs = dplyr::n(),
      participants = dplyr::n_distinct(.data$participant_key),
      residual_lag1 = if (dplyr::n() >= 3L) {
        stats::cor(.data$.residual, .data$previous_residual)
      } else {
        NA_real_
      },
      .by = "site"
    )
  pooled <- if (nrow(lag_rows) >= 3L) {
    stats::cor(lag_rows$.residual, lag_rows$previous_residual)
  } else {
    NA_real_
  }
  maximum_site <- if (any(is.finite(by_site$residual_lag1))) {
    max(abs(by_site$residual_lag1), na.rm = TRUE)
  } else {
    NA_real_
  }
  overall <- tibble::tibble(
    adjacent_pairs = nrow(lag_rows),
    participants = dplyr::n_distinct(lag_rows$participant_key),
    residual_lag1 = pooled,
    maximum_absolute_site_lag1 = maximum_site,
    ar_trigger = (is.finite(pooled) && abs(pooled) >= 0.20) ||
      (is.finite(maximum_site) && maximum_site >= 0.30)
  )
  list(overall = overall, by_site = by_site)
}

h06d_nl_ar_parameters <- function(model) {
  variance <- glmmTMB::VarCorr(model)$cond
  ar <- variance[["day_sequence_id"]]
  correlation <- if (is.null(ar)) NULL else attr(ar, "correlation")
  tibble::tibble(
    ar_standard_deviation = if (is.null(ar)) NA_real_ else attr(ar, "stddev")[[1L]],
    ar_rho = if (is.null(correlation) || nrow(correlation) < 2L) {
      NA_real_
    } else {
      correlation[1L, 2L]
    }
  )
}

h06d_nl_lrt_row <- function(reduced, full, comparison_id) {
  if (is.null(reduced) || is.null(full)) {
    return(tibble::tibble(
      comparison_id = comparison_id,
      likelihood_ratio = NA_real_,
      degrees_of_freedom = NA_real_,
      raw_p_value = NA_real_,
      test_status = "NON_ESTIMABLE"
    ))
  }
  reduced_ll <- stats::logLik(reduced)
  full_ll <- stats::logLik(full)
  df <- attr(full_ll, "df") - attr(reduced_ll, "df")
  statistic <- 2 * (as.numeric(full_ll) - as.numeric(reduced_ll))
  valid <- is.finite(statistic) && is.finite(df) && df > 0 && statistic >= -1e-6
  statistic <- if (valid) max(0, statistic) else statistic
  tibble::tibble(
    comparison_id = comparison_id,
    likelihood_ratio = statistic,
    degrees_of_freedom = df,
    raw_p_value = if (valid) {
      stats::pchisq(statistic, df = df, lower.tail = FALSE)
    } else {
      NA_real_
    },
    test_status = if (valid) "PILOT_RAW_ONLY" else "INVALID_COMPARISON"
  )
}

h06d_nl_design_check <- function(frame, predictor, heterogeneity = FALSE) {
  column <- predictor$column[[1L]]
  formula <- stats::as.formula(if (heterogeneity) {
    sprintf("~ site * %s", column)
  } else {
    sprintf("~ site + %s", column)
  })
  matrix <- stats::model.matrix(formula, data = frame)
  rank <- qr(matrix)$rank
  if (predictor$type[[1L]] == "categorical") {
    cells <- table(frame$site, frame[[column]])
    required_variation <- all(cells > 0L)
  } else {
    support <- tapply(frame[[column]], frame$site, function(value) {
      length(unique(value)) >= 2L && stats::sd(value) > 0
    })
    required_variation <- all(support)
  }
  tibble::tibble(
    design_columns = ncol(matrix),
    design_rank = rank,
    full_rank = rank == ncol(matrix),
    required_within_site_variation = required_variation,
    estimable = rank == ncol(matrix) && required_variation,
    design_matrix_sha256 = digest::digest(
      matrix,
      algo = "sha256",
      serialize = TRUE
    )
  )
}

h06d_nl_equal_site_summary <- function(model, predictor, metric) {
  column <- predictor$column[[1L]]
  if (predictor$type[[1L]] == "categorical") {
    grid <- emmeans::emmeans(
      model,
      specs = stats::as.formula(sprintf("~ %s", column)),
      weights = "equal",
      lmer.df = "asymptotic"
    )
    means <- as.data.frame(summary(grid, infer = c(TRUE, FALSE)))
    estimate_column <- intersect(c("emmean", "response", "prob"), names(means))
    h06d_nl_assert(length(estimate_column) == 1L, "Could not resolve emmean")
    lower_column <- intersect(c("asymp.LCL", "lower.CL"), names(means))
    upper_column <- intersect(c("asymp.UCL", "upper.CL"), names(means))
    h06d_nl_assert(
      length(lower_column) == 1L && length(upper_column) == 1L,
      "Could not resolve emmean confidence limits"
    )
    levels <- as.character(means[[column]])
    marginal <- tibble::tibble(
      level = levels,
      estimate_model = means[[estimate_column]],
      standard_error = means$SE,
      lower_95_model = means[[lower_column]],
      upper_95_model = means[[upper_column]]
    ) |>
      dplyr::mutate(
        estimate_display = h06d_nl_inverse_response(.data$estimate_model, metric),
        lower_95_display = h06d_nl_inverse_response(.data$lower_95_model, metric),
        upper_95_display = h06d_nl_inverse_response(.data$upper_95_model, metric)
      )
  } else {
    center <- c(0, 1)
    grid <- emmeans::emmeans(
      model,
      specs = stats::as.formula(sprintf("~ %s", column)),
      at = stats::setNames(list(center), column),
      weights = "equal",
      lmer.df = "asymptotic"
    )
    means <- as.data.frame(summary(grid, infer = c(TRUE, FALSE)))
    estimate_column <- intersect(c("emmean", "response", "prob"), names(means))
    lower_column <- intersect(c("asymp.LCL", "lower.CL"), names(means))
    upper_column <- intersect(c("asymp.UCL", "upper.CL"), names(means))
    h06d_nl_assert(
      length(estimate_column) == 1L && length(lower_column) == 1L &&
        length(upper_column) == 1L,
      "Could not resolve continuous emmean columns"
    )
    marginal <- tibble::tibble(
      level = c("8 h", "9 h"),
      estimate_model = means[[estimate_column]],
      standard_error = means$SE,
      lower_95_model = means[[lower_column]],
      upper_95_model = means[[upper_column]]
    ) |>
      dplyr::mutate(
        estimate_display = h06d_nl_inverse_response(.data$estimate_model, metric),
        lower_95_display = h06d_nl_inverse_response(.data$lower_95_model, metric),
        upper_95_display = h06d_nl_inverse_response(.data$upper_95_model, metric)
      )
  }
  marginal |>
    dplyr::mutate(
      metric_slot = metric$metric_slot[[1L]],
      metric_id = metric$metric_id[[1L]],
      predictor_order = predictor$predictor_order[[1L]],
      predictor_id = predictor$predictor_id[[1L]],
      marginalization = "equal submitted-site weights; random effects set to zero"
    )
}

h06d_nl_registered_benchmark_summary <- function(fit, predictor) {
  status <- h06d_nl_model_status(fit$value)
  maximum_correlation <- NA_real_
  if (!is.null(fit$value) && inherits(fit$value, "merMod")) {
    site_variance <- lme4::VarCorr(fit$value)$site
    correlation <- attr(site_variance, "correlation")
    if (!is.null(correlation) && nrow(correlation) > 1L) {
      maximum_correlation <- max(abs(correlation[upper.tri(correlation)]))
    }
  }
  estimable <- !is.null(fit$value) && isTRUE(status$converged) &&
    isTRUE(status$positive_definite_hessian) && !isTRUE(status$singular) &&
    is.finite(maximum_correlation) && maximum_correlation < 0.98
  dplyr::bind_cols(
    tibble::tibble(
      predictor_id = predictor$predictor_id[[1L]],
      warning_count = length(fit$warnings),
      warnings = paste(fit$warnings, collapse = " | "),
      fit_error = fit$error,
      elapsed_seconds = fit$elapsed_seconds,
      maximum_absolute_random_site_correlation = maximum_correlation,
      benchmark_disposition = if (estimable) {
        "ESTIMABLE_BENCHMARK_ONLY"
      } else {
        "NON_ESTIMABLE_BENCHMARK"
      }
    ),
    status
  )
}

h06d_nl_fit_clock_cell <- function(frame, metric, predictor) {
  formulas <- h06d_nl_formula_set(predictor$column[[1L]])
  source_clock <- h06d_nl_clock_source_diagnostics(frame, metric)
  additive_design <- h06d_nl_design_check(frame, predictor, FALSE)
  heterogeneity_design <- h06d_nl_design_check(frame, predictor, TRUE)
  h06d_nl_assert(
    isTRUE(additive_design$estimable),
    "A timing additive design is not estimable"
  )

  reduced_ml <- h06d_nl_fit_model(
    frame,
    formulas$fixed_site_reduced,
    "gaussian",
    REML = FALSE
  )
  additive_ml <- h06d_nl_fit_model(
    frame,
    formulas$fixed_site_additive,
    "gaussian",
    REML = FALSE
  )
  additive_reml <- h06d_nl_fit_model(
    frame,
    formulas$fixed_site_additive,
    "gaussian",
    REML = TRUE
  )
  h06d_nl_assert(
    !is.null(reduced_ml$value) && !is.null(additive_ml$value) &&
      !is.null(additive_reml$value),
    "A required timing reduced/additive fit failed"
  )

  heterogeneity_ml <- NULL
  heterogeneity_reml <- NULL
  if (isTRUE(heterogeneity_design$estimable)) {
    heterogeneity_ml <- h06d_nl_fit_model(
      frame,
      formulas$fixed_site_heterogeneity,
      "gaussian",
      REML = FALSE
    )
    heterogeneity_reml <- h06d_nl_fit_model(
      frame,
      formulas$fixed_site_heterogeneity,
      "gaussian",
      REML = TRUE
    )
  }

  benchmark <- h06d_nl_fit_model(
    frame,
    formulas$registered_random_site,
    "gaussian",
    REML = TRUE
  )
  additive_status <- h06d_nl_model_status(additive_reml$value)
  residual <- h06d_nl_gaussian_residual_diagnostics(additive_reml$value)
  bounds <- h06d_nl_prediction_bounds(additive_reml$value, frame, metric)
  effect <- h06d_nl_effect_row(additive_reml$value, predictor, metric)
  marginal <- h06d_nl_equal_site_summary(additive_reml$value, predictor, metric)
  lag <- h06d_nl_lag_screen(
    frame,
    as.numeric(stats::residuals(additive_reml$value))
  )

  ar_fit <- NULL
  ar_effect <- tibble::tibble(
    estimate = NA_real_,
    standard_error = NA_real_,
    lower_95 = NA_real_,
    upper_95 = NA_real_
  )
  ar_status <- tibble::tibble(
    converged = NA,
    positive_definite_hessian = NA,
    singular = NA,
    maximum_absolute_gradient = NA_real_,
    convergence_message = "not triggered"
  )
  ar_parameters <- tibble::tibble(
    ar_standard_deviation = NA_real_,
    ar_rho = NA_real_
  )
  post_ar_lag <- list(overall = tibble::tibble(
    adjacent_pairs = NA_integer_,
    participants = NA_integer_,
    residual_lag1 = NA_real_,
    maximum_absolute_site_lag1 = NA_real_,
    ar_trigger = NA
  ), by_site = tibble::tibble())
  ar_shift <- NA_real_
  ar_support <- lag$overall$adjacent_pairs >= 100L &&
    lag$overall$participants >= 20L
  if (isTRUE(lag$overall$ar_trigger) && ar_support) {
    ar_frame <- h06d_nl_add_day_sequences(frame)
    ar_formula <- h06d_nl_formula_set(
      predictor$column[[1L]],
      ar = TRUE
    )$fixed_site_additive
    ar_fit <- h06d_nl_fit_model(
      ar_frame,
      ar_formula,
      "gaussian",
      REML = TRUE,
      ar = TRUE
    )
    if (!is.null(ar_fit$value)) {
      ar_effect <- h06d_nl_effect_row(ar_fit$value, predictor, metric) |>
        dplyr::select("estimate", "standard_error", "lower_95", "upper_95")
      ar_status <- h06d_nl_model_status(ar_fit$value)
      ar_parameters <- h06d_nl_ar_parameters(ar_fit$value)
      ar_shift <- abs(ar_effect$estimate - effect$estimate) /
        effect$standard_error
      post_ar_lag <- h06d_nl_lag_screen(
        ar_frame,
        as.numeric(stats::residuals(ar_fit$value))
      )
    } else {
      ar_status$convergence_message <- ar_fit$error
    }
  }
  ar_acceptable <- if (!isTRUE(lag$overall$ar_trigger)) {
    TRUE
  } else {
    ar_support && isTRUE(ar_status$converged) &&
      isTRUE(ar_status$positive_definite_hessian) &&
      !isTRUE(ar_status$singular) &&
      is.finite(ar_parameters$ar_rho) && abs(ar_parameters$ar_rho) < 0.95 &&
      is.finite(ar_shift) && ar_shift < 1 &&
      is.finite(post_ar_lag$overall$residual_lag1) &&
      abs(post_ar_lag$overall$residual_lag1) < 0.20 &&
      is.finite(post_ar_lag$overall$maximum_absolute_site_lag1) &&
      post_ar_lag$overall$maximum_absolute_site_lag1 < 0.30
  }

  gaussian_core <- isTRUE(additive_status$converged) &&
    isTRUE(additive_status$positive_definite_hessian) &&
    !isTRUE(additive_status$singular) &&
    residual$residual_qq_correlation >= 0.95 &&
    residual$standardized_residual_gt4_fraction < 0.01 &&
    abs(residual$absolute_residual_fitted_spearman) < 0.40 &&
    isTRUE(bounds$prediction_bound_acceptable)
  diagnostic_disposition <- dplyr::case_when(
    !source_clock$source_clock_acceptable ~ "NOT_ACCEPTABLE_CLOCK_SOURCE",
    !gaussian_core ~ "NOT_ACCEPTABLE_GAUSSIAN_CORE",
    !ar_acceptable ~ "NOT_ACCEPTABLE_TEMPORAL_STABILITY",
    abs(residual$absolute_residual_fitted_spearman) >= 0.20 ~
      "ACCEPTABLE_WITH_RESIDUAL_SPREAD_LIMITATION",
    TRUE ~ "ACCEPTABLE"
  )

  association <- h06d_nl_lrt_row(
    reduced_ml$value,
    additive_ml$value,
    "reduced_vs_additive"
  )
  heterogeneity <- if (
    !is.null(heterogeneity_ml) && !is.null(heterogeneity_ml$value)
  ) {
    h06d_nl_lrt_row(
      additive_ml$value,
      heterogeneity_ml$value,
      "additive_vs_site_interaction"
    )
  } else {
    h06d_nl_lrt_row(NULL, NULL, "additive_vs_site_interaction")
  }

  list(
    models = list(
      reduced_ml = reduced_ml,
      additive_ml = additive_ml,
      additive_reml = additive_reml,
      heterogeneity_ml = heterogeneity_ml,
      heterogeneity_reml = heterogeneity_reml,
      registered_benchmark = benchmark,
      ar_additive_reml = ar_fit
    ),
    effect = effect,
    marginal = marginal,
    tests = dplyr::bind_rows(association, heterogeneity),
    diagnostics = dplyr::bind_cols(
      source_clock,
      additive_design |>
        dplyr::rename_with(~ paste0("additive_", .x)),
      heterogeneity_design |>
        dplyr::rename_with(~ paste0("heterogeneity_", .x)),
      additive_status |>
        dplyr::rename_with(~ paste0("additive_", .x)),
      residual,
      bounds,
      tibble::tibble(
        warning_count = length(additive_reml$warnings),
        warnings = paste(additive_reml$warnings, collapse = " | "),
        fit_error = additive_reml$error,
        independent_residual_lag1 = lag$overall$residual_lag1,
        independent_maximum_absolute_site_lag1 =
          lag$overall$maximum_absolute_site_lag1,
        ar_trigger = lag$overall$ar_trigger,
        ar_support = ar_support,
        ar_fitted = !is.null(ar_fit) && !is.null(ar_fit$value),
        ar_effect_shift_in_primary_se = ar_shift,
        post_ar_residual_lag1 = post_ar_lag$overall$residual_lag1,
        post_ar_maximum_absolute_site_lag1 =
          post_ar_lag$overall$maximum_absolute_site_lag1,
        ar_acceptable = ar_acceptable,
        diagnostic_disposition = diagnostic_disposition
      ),
      ar_parameters,
      ar_status |>
        dplyr::rename_with(~ paste0("ar_", .x))
    ),
    lag_by_site = lag$by_site,
    post_ar_lag_by_site = post_ar_lag$by_site,
    ar_effect = ar_effect,
    benchmark = h06d_nl_registered_benchmark_summary(benchmark, predictor)
  )
}

h06d_nl_deletion_refit <- function(
  frame,
  metric,
  predictor,
  deletion_type,
  deletion_value,
  full_effect,
  full_standard_error
) {
  keep <- if (deletion_type == "participant") {
    as.character(frame$participant_key) != deletion_value
  } else if (deletion_type == "site") {
    as.character(frame$site) != deletion_value
  } else {
    h06d_nl_abort("Unknown deletion type")
  }
  reduced_frame <- droplevels(frame[keep, , drop = FALSE])
  if (nlevels(reduced_frame$site) > 1L) {
    contrasts(reduced_frame$site) <- stats::contr.sum(nlevels(reduced_frame$site))
  }
  formula <- h06d_nl_formula_set(
    predictor$column[[1L]]
  )$fixed_site_additive
  fit <- h06d_nl_fit_model(
    reduced_frame,
    formula,
    metric$response_family[[1L]],
    REML = TRUE
  )
  status <- h06d_nl_model_status(fit$value)
  effect <- if (!is.null(fit$value)) {
    h06d_nl_effect_row(fit$value, predictor, metric)
  } else {
    tibble::tibble(
      estimate = NA_real_,
      standard_error = NA_real_,
      lower_95 = NA_real_,
      upper_95 = NA_real_
    )
  }
  shift <- abs(effect$estimate - full_effect) / full_standard_error
  tibble::tibble(
    deletion_type = deletion_type,
    deletion_value = deletion_value,
    participant_days = nrow(reduced_frame),
    participants = dplyr::n_distinct(reduced_frame$participant_key),
    sites = dplyr::n_distinct(reduced_frame$site),
    estimate = effect$estimate,
    standard_error = effect$standard_error,
    lower_95 = effect$lower_95,
    upper_95 = effect$upper_95,
    absolute_shift_in_full_se = shift,
    direction_reversal = is.finite(effect$estimate) && is.finite(full_effect) &&
      sign(effect$estimate) != sign(full_effect),
    elapsed_seconds = fit$elapsed_seconds,
    warning_count = length(fit$warnings),
    warnings = paste(fit$warnings, collapse = " | "),
    fit_error = fit$error
  ) |>
    dplyr::bind_cols(status)
}
