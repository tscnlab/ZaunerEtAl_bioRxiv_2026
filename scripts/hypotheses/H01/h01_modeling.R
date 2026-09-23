# Fit, diagnose, summarize, and bootstrap the specified H01 models.

h01_required_model_columns <- function() {
  c(
    "data_scenario_id",
    "model_implementation_id",
    "placement",
    "scenario",
    "metric_order",
    "metric_id",
    "analysis_unit",
    "site",
    "local_date",
    "participant_days_contributing",
    "metric_support_available",
    "metric_support_unavailability_reason",
    "metric_support_valid_minutes",
    "metric_support_expected_minutes",
    "participant_key",
    "photoperiod_hours",
    "latitude_deg",
    "absolute_latitude_10deg",
    "photoperiod_centered_hours",
    "absolute_latitude_10deg_centered",
    "value",
    "scenario_estimable",
    "site_photoperiod_included",
    "latitude_photoperiod_included",
    "metric_any_censored"
  )
}

h01_transform_clock_after <- function(value, cutpoint_hour) {
  if (any(!is.finite(value) | value < 0 | value >= 1440)) {
    h01_abort("Clock-minute H01 responses must be in [0, 1440)")
  }
  if (
    length(cutpoint_hour) != 1L ||
      !is.finite(cutpoint_hour) ||
      cutpoint_hour <= 0 ||
      cutpoint_hour >= 24
  ) {
    h01_abort("The H01 clock cutpoint must be one finite hour in (0, 24)")
  }
  hours <- value / 60
  ifelse(hours > cutpoint_hour, hours - 24, hours)
}

h01_transform_response <- function(value, response_transform) {
  if (!is.numeric(value)) {
    h01_abort("H01 response values must be numeric")
  }
  transformed <- switch(
    response_transform,
    logit = {
      if (any(!is.finite(value) | value <= 0 | value >= 1)) {
        h01_abort("Logit H01 responses must be finite and strictly in (0, 1)")
      }
      stats::qlogis(value)
    },
    identity = value,
    log10_offset_0.1 = {
      if (any(!is.finite(value) | value < 0)) {
        h01_abort("Offset-log10 H01 responses must be finite and non-negative")
      }
      log10(value + 0.1)
    },
    clock_hours = {
      if (any(!is.finite(value) | value < 0 | value >= 1440)) {
        h01_abort("Clock-minute H01 responses must be in [0, 1440)")
      }
      value / 60
    },
    clock_hours_midnight_after_16 =
      h01_transform_clock_after(value, cutpoint_hour = 16),
    clock_hours_midnight_after_12 =
      h01_transform_clock_after(value, cutpoint_hour = 12),
    h01_abort("Unknown H01 response transformation: %s", response_transform)
  )
  if (any(!is.finite(transformed))) {
    h01_abort("H01 response transformation produced a non-finite value")
  }
  transformed
}

h01_inverse_response <- function(value, response_transform, response_family) {
  if (response_family == "tweedie_log") {
    return(exp(value))
  }
  switch(
    response_transform,
    logit = stats::plogis(value),
    identity = value,
    log10_offset_0.1 = 10^value - 0.1,
    clock_hours = value %% 24,
    clock_hours_midnight_after_16 = value %% 24,
    clock_hours_midnight_after_12 = value %% 24,
    h01_abort("Unknown H01 inverse transformation: %s", response_transform)
  )
}

h01_transform_effect <- function(
  estimate,
  conf_low,
  conf_high,
  spec
) {
  multiplicative <- spec$response_family == "tweedie_log" ||
    spec$response_transform %in% c("logit", "log10_offset_0.1")
  if (multiplicative) {
    base <- if (spec$response_transform == "log10_offset_0.1") 10 else exp(1)
    tibble::tibble(
      effect_type = if (spec$response_transform == "logit") {
        "odds_ratio"
      } else {
        "ratio"
      },
      estimate_practical = base^estimate,
      conf_low_practical = base^conf_low,
      conf_high_practical = base^conf_high
    )
  } else {
    tibble::tibble(
      effect_type = "difference",
      estimate_practical = estimate,
      conf_low_practical = conf_low,
      conf_high_practical = conf_high
    )
  }
}

h01_prepare_model_frame <- function(
  object,
  spec,
  placement,
  sample_scenario,
  recenter = FALSE,
  restrict_keys = NULL,
  exactly_identified_only = FALSE
) {
  rows <- object$model_rows
  missing <- setdiff(h01_required_model_columns(), names(rows))
  if (length(missing) > 0L) {
    h01_abort(
      "H01 model data are missing column(s): %s",
      paste(missing, collapse = ", ")
    )
  }
  rows <- rows[
    rows$placement == placement &
      rows$scenario == sample_scenario &
      rows$metric_id == spec$metric_id,
    ,
    drop = FALSE
  ]
  if (nrow(rows) == 0L) {
    return(tibble::tibble())
  }
  included <- rows$scenario_estimable &
    rows$site_photoperiod_included &
    rows$latitude_photoperiod_included &
    is.finite(rows$value)
  included[is.na(included)] <- FALSE
  rows <- rows[included, , drop = FALSE]
  if (exactly_identified_only) {
    exactly_identified <- !is.na(rows$metric_any_censored) &
      !rows$metric_any_censored
    rows <- rows[exactly_identified, , drop = FALSE]
  }
  if (!is.null(restrict_keys)) {
    key <- if (spec$analysis_unit == "participant") {
      rows$participant_key
    } else {
      paste(rows$participant_key, rows$local_date, sep = "::")
    }
    rows <- rows[key %in% restrict_keys, , drop = FALSE]
  }
  if (nrow(rows) == 0L) {
    return(tibble::tibble())
  }
  key <- if (spec$analysis_unit == "participant") {
    rows["participant_key"]
  } else {
    rows[c("participant_key", "local_date")]
  }
  if (anyDuplicated(key)) {
    h01_abort(
      "H01 `%s` frame contains duplicated %s keys",
      spec$metric_id,
      spec$analysis_unit
    )
  }
  required_complete <- c(
    "site",
    "participant_key",
    "photoperiod_hours",
    "latitude_deg",
    "absolute_latitude_10deg"
  )
  if (any(!stats::complete.cases(rows[required_complete]))) {
    h01_abort("H01 `%s` model frame has missing predictors", spec$metric_id)
  }
  latitude_count <- dplyr::summarise(
    dplyr::group_by(rows, site),
    n_latitude = dplyr::n_distinct(latitude_deg),
    .groups = "drop"
  )
  if (any(latitude_count$n_latitude != 1L)) {
    h01_abort("H01 `%s` has more than one latitude per site", spec$metric_id)
  }
  if (recenter) {
    rows$photoperiod_centered_hours <-
      rows$photoperiod_hours - mean(rows$photoperiod_hours)
    site_latitude <- unique(rows[c("site", "absolute_latitude_10deg")])
    latitude_center <- mean(site_latitude$absolute_latitude_10deg)
    rows$absolute_latitude_10deg_centered <-
      rows$absolute_latitude_10deg - latitude_center
  } else {
    if (
      any(!is.finite(rows$photoperiod_centered_hours)) ||
        any(!is.finite(rows$absolute_latitude_10deg_centered))
    ) {
      h01_abort("H01 `%s` has invalid centered predictors", spec$metric_id)
    }
  }
  rows$site <- droplevels(factor(rows$site))
  rows$participant_key <- factor(rows$participant_key)
  if (nlevels(rows$site) < 2L) {
    h01_abort("H01 `%s` model frame contains fewer than two sites", spec$metric_id)
  }
  stats::contrasts(rows$site) <- stats::contr.sum(nlevels(rows$site))
  rows$response_value <- h01_transform_response(
    rows$value,
    spec$response_transform
  )
  rows <- rows[
    order(rows$site, rows$participant_key, rows$local_date, na.last = TRUE),
    ,
    drop = FALSE
  ]
  rows$.model_row_id <- if (spec$analysis_unit == "participant") {
    as.character(rows$participant_key)
  } else {
    paste(rows$participant_key, rows$local_date, sep = "::")
  }
  rows <- as.data.frame(rows)
  rownames(rows) <- rows$.model_row_id
  tibble::as_tibble(rows)
}

h01_capture_fit <- function(expression) {
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

h01_fit_model <- function(data, formula, spec, estimation = "comparison") {
  estimation <- match.arg(estimation, c("comparison", "final"))
  if (nrow(data) == 0L) {
    return(list(
      model = NULL,
      warnings = character(),
      error = "No estimable rows"
    ))
  }
  if (spec$analysis_unit == "participant") {
    return(h01_capture_fit(stats::lm(formula = formula, data = data)))
  }
  if (spec$response_family == "gaussian") {
    reml <- identical(estimation, "final")
    return(h01_capture_fit(
      lme4::lmer(
        formula = formula,
        data = data,
        REML = reml,
        control = lme4::lmerControl(
          optimizer = "nloptwrap",
          calc.derivs = TRUE
        )
      )
    ))
  }
  h01_capture_fit(
    glmmTMB::glmmTMB(
      formula = formula,
      data = data,
      family = glmmTMB::tweedie(link = "log"),
      REML = FALSE,
      control = glmmTMB::glmmTMBControl(
        optCtrl = list(iter.max = 10000L, eval.max = 10000L)
      )
    )
  )
}

h01_model_fit_status <- function(model) {
  if (is.null(model)) {
    return(tibble::tibble(
      converged = FALSE,
      positive_definite_hessian = FALSE,
      singular = NA,
      max_gradient = NA_real_
    ))
  }
  if (inherits(model, "lm") && !inherits(model, "merMod")) {
    return(tibble::tibble(
      converged = isTRUE(model$rank == ncol(stats::model.matrix(model))),
      positive_definite_hessian = TRUE,
      singular = FALSE,
      max_gradient = NA_real_
    ))
  }
  if (inherits(model, "merMod")) {
    gradient <- model@optinfo$derivs$gradient
    return(tibble::tibble(
      converged = is.null(model@optinfo$conv$lme4$messages) &&
        isTRUE(model@optinfo$conv$opt == 0L),
      positive_definite_hessian = TRUE,
      singular = lme4::isSingular(model, tol = 1e-5),
      max_gradient = if (is.null(gradient)) {
        NA_real_
      } else {
        max(abs(gradient))
      }
    ))
  }
  if (inherits(model, "glmmTMB")) {
    return(tibble::tibble(
      converged = isTRUE(model$fit$convergence == 0L),
      positive_definite_hessian = isTRUE(model$sdr$pdHess),
      singular = tryCatch(
        performance::check_singularity(model, tolerance = 1e-5),
        error = function(error) NA
      ),
      max_gradient = NA_real_
    ))
  }
  h01_abort("Unsupported H01 model class: %s", class(model)[1L])
}

h01_fit_metric_models <- function(frame, spec, formulas = NULL) {
  if (is.null(formulas)) {
    formulas <- h01_formula_set(spec$analysis_unit)
  }
  comparison_names <- c(
    "site_full",
    "no_site",
    "no_photoperiod",
    "latitude_full",
    "random_site"
  )
  comparison <- stats::setNames(
    lapply(
      comparison_names,
      function(name) {
        if (
          name == "random_site" &&
            spec$analysis_unit == "participant"
        ) {
          return(list(
            model = NULL,
            warnings = character(),
            error = "Random-site description is not estimable for participant-level H01 outcomes"
          ))
        }
        h01_fit_model(
          frame,
          formulas[[name]],
          spec,
          estimation = "comparison"
        )
      }
    ),
    comparison_names
  )
  if (
    spec$analysis_unit == "participant" ||
      spec$response_family == "tweedie_log"
  ) {
    final <- comparison[c(
      "site_full",
      "no_site",
      "no_photoperiod",
      "latitude_full"
    )]
  } else {
    final_names <- c(
      "site_full",
      "no_site",
      "no_photoperiod",
      "latitude_full"
    )
    final <- stats::setNames(
      lapply(
        final_names,
        function(name) {
          h01_fit_model(
            frame,
            formulas[[name]],
            spec,
            estimation = "final"
          )
        }
      ),
      final_names
    )
  }
  list(
    spec = spec,
    formulas = formulas,
    comparison = comparison,
    final = final,
    frame_keys = frame$.model_row_id
  )
}

h01_unwrap_model <- function(bundle, stage, name) {
  fit <- bundle[[stage]][[name]]
  if (is.null(fit) || !is.na(fit$error)) {
    return(NULL)
  }
  fit$model
}

h01_loglik_test <- function(reduced, full, comparison_id) {
  if (is.null(reduced) || is.null(full)) {
    return(tibble::tibble(
      comparison_id = comparison_id,
      statistic = NA_real_,
      df = NA_real_,
      p_raw = NA_real_,
      log_lik_reduced = NA_real_,
      log_lik_full = NA_real_,
      n_obs_reduced = if (is.null(reduced)) NA_integer_ else stats::nobs(reduced),
      n_obs_full = if (is.null(full)) NA_integer_ else stats::nobs(full),
      comparison_status = "NON_ESTIMABLE"
    ))
  }
  n_reduced <- stats::nobs(reduced)
  n_full <- stats::nobs(full)
  if (!identical(as.integer(n_reduced), as.integer(n_full))) {
    h01_abort("%s used non-identical model-frame sizes", comparison_id)
  }
  reduced_loglik <- stats::logLik(reduced)
  full_loglik <- stats::logLik(full)
  df <- attr(full_loglik, "df") - attr(reduced_loglik, "df")
  statistic <- 2 * (as.numeric(full_loglik) - as.numeric(reduced_loglik))
  if (!is.finite(statistic) || df <= 0 || statistic < -1e-6) {
    return(tibble::tibble(
      comparison_id = comparison_id,
      statistic = statistic,
      df = df,
      p_raw = NA_real_,
      log_lik_reduced = as.numeric(reduced_loglik),
      log_lik_full = as.numeric(full_loglik),
      n_obs_reduced = n_reduced,
      n_obs_full = n_full,
      comparison_status = "INVALID_LIKELIHOOD_COMPARISON"
    ))
  }
  statistic <- max(statistic, 0)
  tibble::tibble(
    comparison_id = comparison_id,
    statistic = statistic,
    df = df,
    p_raw = stats::pchisq(statistic, df = df, lower.tail = FALSE),
    log_lik_reduced = as.numeric(reduced_loglik),
    log_lik_full = as.numeric(full_loglik),
    n_obs_reduced = n_reduced,
    n_obs_full = n_full,
    comparison_status = "PASS"
  )
}

h01_model_tests <- function(bundle) {
  site <- h01_unwrap_model(bundle, "comparison", "site_full")
  no_site <- h01_unwrap_model(bundle, "comparison", "no_site")
  no_photoperiod <- h01_unwrap_model(
    bundle,
    "comparison",
    "no_photoperiod"
  )
  latitude <- h01_unwrap_model(bundle, "comparison", "latitude_full")
  dplyr::bind_rows(
    h01_loglik_test(no_site, site, "site_full_vs_no_site"),
    h01_loglik_test(
      no_photoperiod,
      site,
      "site_full_vs_no_photoperiod"
    ),
    h01_loglik_test(no_site, latitude, "latitude_full_vs_no_latitude"),
    h01_loglik_test(
      latitude,
      site,
      "site_full_vs_latitude_full"
    )
  )
}

h01_fixed_effects <- function(model) {
  if (inherits(model, "glmmTMB")) {
    return(glmmTMB::fixef(model)$cond)
  }
  if (inherits(model, "merMod")) {
    return(lme4::fixef(model))
  }
  stats::coef(model)
}

h01_fixed_vcov <- function(model) {
  if (inherits(model, "glmmTMB")) {
    return(as.matrix(stats::vcov(model)$cond))
  }
  as.matrix(stats::vcov(model))
}

h01_extract_term_effect <- function(
  model,
  term,
  term_label,
  spec,
  confidence_level = 0.95
) {
  if (is.null(model)) {
    return(tibble::tibble(
      term = term,
      term_label = term_label,
      estimate_model = NA_real_,
      std_error = NA_real_,
      conf_low_model = NA_real_,
      conf_high_model = NA_real_,
      p_raw = NA_real_,
      effect_type = NA_character_,
      estimate_practical = NA_real_,
      conf_low_practical = NA_real_,
      conf_high_practical = NA_real_,
      interval_method = "wald_normal",
      status = "NON_ESTIMABLE"
    ))
  }
  coefficients <- h01_fixed_effects(model)
  covariance <- h01_fixed_vcov(model)
  if (!term %in% names(coefficients) || !term %in% rownames(covariance)) {
    return(h01_extract_term_effect(
      model = NULL,
      term = term,
      term_label = term_label,
      spec = spec,
      confidence_level = confidence_level
    ))
  }
  estimate <- unname(coefficients[[term]])
  standard_error <- sqrt(covariance[term, term])
  critical <- stats::qnorm(1 - (1 - confidence_level) / 2)
  conf_low <- estimate - critical * standard_error
  conf_high <- estimate + critical * standard_error
  practical <- h01_transform_effect(estimate, conf_low, conf_high, spec)
  dplyr::bind_cols(
    tibble::tibble(
      term = term,
      term_label = term_label,
      estimate_model = estimate,
      std_error = standard_error,
      conf_low_model = conf_low,
      conf_high_model = conf_high,
      p_raw = 2 * stats::pnorm(
        abs(estimate / standard_error),
        lower.tail = FALSE
      )
    ),
    practical,
    tibble::tibble(
      interval_method = "wald_normal",
      status = "PASS"
    )
  )
}

h01_site_summaries <- function(model, frame, spec, confidence_level = 0.95) {
  if (is.null(model)) {
    return(list(
      estimates = tibble::tibble(),
      deviations = tibble::tibble(),
      marginalization = tibble::tibble()
    ))
  }
  grid <- emmeans::emmeans(
    model,
    specs = ~site,
    at = list(photoperiod_centered_hours = 0),
    weights = "equal",
    lmer.df = "asymptotic"
  )
  grid_summary <- as.data.frame(summary(grid))
  estimate_column <- intersect(
    c("emmean", "response", "prob"),
    names(grid_summary)
  )
  if (length(estimate_column) != 1L) {
    h01_abort("Could not resolve the H01 site marginal-mean column")
  }
  eta <- grid_summary[[estimate_column]]
  covariance <- as.matrix(stats::vcov(grid))
  sites <- as.character(grid_summary$site)
  critical <- stats::qnorm(1 - (1 - confidence_level) / 2)
  site_standard_error <- sqrt(diag(covariance))
  site_low <- eta - critical * site_standard_error
  site_high <- eta + critical * site_standard_error
  estimates <- tibble::tibble(
    estimand = "site_mean",
    site = sites,
    estimate_model = eta,
    std_error = site_standard_error,
    conf_low_model = site_low,
    conf_high_model = site_high,
    estimate_practical = h01_inverse_response(
      eta,
      spec$response_transform,
      spec$response_family
    ),
    conf_low_practical = h01_inverse_response(
      site_low,
      spec$response_transform,
      spec$response_family
    ),
    conf_high_practical = h01_inverse_response(
      site_high,
      spec$response_transform,
      spec$response_family
    ),
    interval_method = "emmeans_wald_normal"
  )
  n_sites <- length(sites)
  equal_weights <- rep(1 / n_sites, n_sites)
  observed_counts <- table(factor(frame$site, levels = sites))
  observed_weights <- as.numeric(observed_counts) / sum(observed_counts)
  summarize_weighted <- function(weights, label) {
    value <- sum(weights * eta)
    standard_error <- sqrt(drop(t(weights) %*% covariance %*% weights))
    low <- value - critical * standard_error
    high <- value + critical * standard_error
    tibble::tibble(
      estimand = label,
      site = NA_character_,
      estimate_model = value,
      std_error = standard_error,
      conf_low_model = low,
      conf_high_model = high,
      estimate_practical = h01_inverse_response(
        value,
        spec$response_transform,
        spec$response_family
      ),
      conf_low_practical = h01_inverse_response(
        low,
        spec$response_transform,
        spec$response_family
      ),
      conf_high_practical = h01_inverse_response(
        high,
        spec$response_transform,
        spec$response_family
      ),
      interval_method = "emmeans_wald_normal"
    )
  }
  overall <- dplyr::bind_rows(
    summarize_weighted(equal_weights, "overall_equal_site_mean"),
    summarize_weighted(observed_weights, "overall_observed_sample_mean")
  )
  contrast_matrix <- diag(n_sites) - matrix(1 / n_sites, n_sites, n_sites)
  contrast_estimate <- drop(contrast_matrix %*% eta)
  contrast_covariance <- contrast_matrix %*% covariance %*%
    t(contrast_matrix)
  contrast_standard_error <- sqrt(diag(contrast_covariance))
  contrast_low <- contrast_estimate - critical * contrast_standard_error
  contrast_high <- contrast_estimate + critical * contrast_standard_error
  practical <- h01_transform_effect(
    contrast_estimate,
    contrast_low,
    contrast_high,
    spec
  )
  deviations <- dplyr::bind_cols(
    tibble::tibble(
      site = sites,
      reference = "equally_weighted_overall_site_mean",
      estimate_model = contrast_estimate,
      std_error = contrast_standard_error,
      conf_low_model = contrast_low,
      conf_high_model = contrast_high,
      z_value = contrast_estimate / contrast_standard_error,
      p_raw = 2 * stats::pnorm(
        abs(contrast_estimate / contrast_standard_error),
        lower.tail = FALSE
      )
    ),
    practical
  ) |>
    dplyr::mutate(
      p_adjusted_within_metric = stats::p.adjust(
        p_raw,
        method = "BH"
      ),
      contrast_family_n = n_sites,
      contrast_adjustment_method = "BH",
      interval_method = "emmeans_wald_normal"
    )
  marginalization <- tibble::tibble(
    equal_site_estimate_model = sum(equal_weights * eta),
    observed_sample_estimate_model = sum(observed_weights * eta),
    equal_site_estimate_practical = h01_inverse_response(
      sum(equal_weights * eta),
      spec$response_transform,
      spec$response_family
    ),
    observed_sample_estimate_practical = h01_inverse_response(
      sum(observed_weights * eta),
      spec$response_transform,
      spec$response_family
    ),
    practical_difference = observed_sample_estimate_practical -
      equal_site_estimate_practical,
    observed_site_weights = paste(
      paste(sites, signif(observed_weights, 8), sep = "="),
      collapse = ";"
    )
  )
  list(
    estimates = dplyr::bind_rows(estimates, overall),
    deviations = deviations,
    marginalization = marginalization
  )
}

h01_sample_summary <- function(frame, spec) {
  if (nrow(frame) == 0L) {
    return(list(
      overall = tibble::tibble(),
      by_site = tibble::tibble()
    ))
  }
  support_available <- any(frame$metric_support_available) &&
    !all(is.na(frame$metric_support_valid_minutes))
  support_hours <- if (support_available) {
    sum(frame$metric_support_valid_minutes, na.rm = TRUE) / 60
  } else {
    NA_real_
  }
  unavailable_reason <- if (support_available) {
    NA_character_
  } else {
    reasons <- unique(stats::na.omit(
      frame$metric_support_unavailability_reason
    ))
    if (length(reasons) == 0L) {
      "metric_support_not_retained"
    } else {
      paste(reasons, collapse = ";")
    }
  }
  participant_days <- if (spec$analysis_unit == "participant_day") {
    nrow(frame)
  } else {
    sum(frame$participant_days_contributing, na.rm = TRUE)
  }
  overall <- tibble::tibble(
    participants = dplyr::n_distinct(frame$participant_key),
    participant_days = participant_days,
    observations = nrow(frame),
    sites = dplyr::n_distinct(frame$site),
    derivation_support_hours = support_hours,
    derivation_support_status = if (support_available) {
      "available"
    } else {
      "unavailable"
    },
    derivation_support_unavailability_reason = unavailable_reason
  )
  by_site <- dplyr::summarise(
    dplyr::group_by(frame, site),
    participants = dplyr::n_distinct(participant_key),
    participant_days = if (spec$analysis_unit == "participant_day") {
      dplyr::n()
    } else {
      sum(participant_days_contributing, na.rm = TRUE)
    },
    observations = dplyr::n(),
    derivation_support_hours = if (
      all(is.na(metric_support_valid_minutes))
    ) {
      NA_real_
    } else {
      sum(metric_support_valid_minutes, na.rm = TRUE) / 60
    },
    .groups = "drop"
  )
  list(overall = overall, by_site = by_site)
}

h01_model_variance <- function(model, approximation = "lognormal") {
  if (is.null(model)) {
    return(tibble::tibble(
      fixed = NA_real_,
      random = NA_real_,
      residual = NA_real_,
      denominator = NA_real_
    ))
  }
  if (inherits(model, "lm") && !inherits(model, "merMod")) {
    fixed <- stats::var(stats::fitted(model))
    residual <- stats::var(stats::residuals(model))
    return(tibble::tibble(
      fixed = fixed,
      random = 0,
      residual = residual,
      denominator = fixed + residual
    ))
  }
  variance <- tryCatch(
    insight::get_variance(model, approximation = approximation),
    error = function(error) NULL
  )
  if (is.null(variance)) {
    return(h01_model_variance(NULL, approximation))
  }
  fixed <- unname(variance$var.fixed)
  random <- if (is.null(variance$var.random)) 0 else unname(variance$var.random)
  residual <- if (is.null(variance$var.residual)) {
    NA_real_
  } else {
    unname(variance$var.residual)
  }
  tibble::tibble(
    fixed = fixed,
    random = random,
    residual = residual,
    denominator = fixed + random + residual
  )
}

h01_r2_from_models <- function(models, spec, approximation = "lognormal") {
  site_full <- h01_model_variance(models$site_full, approximation)
  no_site <- h01_model_variance(models$no_site, approximation)
  no_photoperiod <- h01_model_variance(
    models$no_photoperiod,
    approximation
  )
  latitude_full <- h01_model_variance(models$latitude_full, approximation)
  valid <- all(is.finite(c(
    site_full$fixed,
    site_full$random,
    site_full$residual,
    no_site$fixed,
    no_photoperiod$fixed,
    latitude_full$fixed,
    latitude_full$random,
    latitude_full$residual
  )))
  if (!valid || site_full$denominator <= 0 || latitude_full$denominator <= 0) {
    return(tibble::tibble(
      approximation = approximation,
      marginal_r2 = NA_real_,
      conditional_r2 = NA_real_,
      participant_associated_share = NA_real_,
      site_part_r2 = NA_real_,
      photoperiod_part_r2 = NA_real_,
      latitude_model_marginal_r2 = NA_real_,
      latitude_part_r2 = NA_real_,
      unrepresented_share = NA_real_,
      status = "NON_ESTIMABLE"
    ))
  }
  marginal <- site_full$fixed / site_full$denominator
  conditional <- (site_full$fixed + site_full$random) /
    site_full$denominator
  latitude_marginal <- latitude_full$fixed / latitude_full$denominator
  tibble::tibble(
    approximation = approximation,
    marginal_r2 = marginal,
    conditional_r2 = conditional,
    participant_associated_share = if (
      spec$analysis_unit == "participant_day"
    ) {
      conditional - marginal
    } else {
      NA_real_
    },
    site_part_r2 = (site_full$fixed - no_site$fixed) /
      site_full$denominator,
    photoperiod_part_r2 = (site_full$fixed - no_photoperiod$fixed) /
      site_full$denominator,
    latitude_model_marginal_r2 = latitude_marginal,
    latitude_part_r2 = (latitude_full$fixed - no_site$fixed) /
      latitude_full$denominator,
    unrepresented_share = 1 - conditional,
    status = "PASS"
  )
}

h01_r2_point_summary <- function(bundle) {
  models <- lapply(
    c("site_full", "no_site", "no_photoperiod", "latitude_full"),
    function(name) h01_unwrap_model(bundle, "final", name)
  )
  names(models) <- c(
    "site_full",
    "no_site",
    "no_photoperiod",
    "latitude_full"
  )
  primary <- h01_r2_from_models(
    models,
    bundle$spec,
    approximation = "lognormal"
  )
  if (bundle$spec$response_family == "tweedie_log") {
    dplyr::bind_rows(
      primary,
      h01_r2_from_models(
        models,
        bundle$spec,
        approximation = "delta"
      )
    )
  } else {
    primary
  }
}

h01_prediction_bounds <- function(model, frame, spec) {
  if (is.null(model)) {
    return(tibble::tibble(
      observed_below_bound_n = NA_integer_,
      observed_above_bound_n = NA_integer_,
      predicted_below_bound_n = NA_integer_,
      predicted_above_bound_n = NA_integer_,
      prediction_bound_status = "NON_ESTIMABLE",
      audit_upper_threshold = if (
        "audit_upper_threshold" %in% names(spec)
      ) {
        spec$audit_upper_threshold
      } else {
        NA_real_
      },
      observed_above_audit_threshold_n = NA_integer_,
      predicted_above_audit_threshold_n = NA_integer_,
      audit_threshold_status = "NON_ESTIMABLE"
    ))
  }
  predicted_model <- tryCatch(
    stats::predict(
      model,
      type = if (inherits(model, "glmmTMB")) "link" else "response"
    ),
    error = function(error) rep(NA_real_, nrow(frame))
  )
  predicted <- if (inherits(model, "glmmTMB")) {
    exp(predicted_model)
  } else {
    h01_inverse_response(
      predicted_model,
      spec$response_transform,
      spec$response_family
    )
  }
  observed <- if (
    startsWith(spec$response_transform, "clock_hours")
  ) {
    frame$value / 60
  } else {
    frame$value
  }
  lower <- rep(spec$lower_bound, nrow(frame))
  upper <- rep(spec$upper_bound, nrow(frame))
  if (
    spec$metric_id %in%
      c(
        "duration_above_250_wake",
        "duration_below_1_sleep_environment"
      )
  ) {
    support_upper <- frame$metric_support_expected_minutes / 60
    if (!all(is.na(support_upper))) {
      upper <- support_upper
    }
  }
  observed_below <- sum(
    is.finite(lower) & observed < lower - 1e-8,
    na.rm = TRUE
  )
  observed_above <- sum(
    is.finite(upper) & observed > upper + 1e-8,
    na.rm = TRUE
  )
  predicted_below <- sum(
    is.finite(lower) & predicted < lower - 1e-8,
    na.rm = TRUE
  )
  predicted_above <- sum(
    is.finite(upper) & predicted > upper + 1e-8,
    na.rm = TRUE
  )
  upper_available <- any(is.finite(upper))
  audit_upper_threshold <- if (
    "audit_upper_threshold" %in% names(spec) &&
      is.finite(spec$audit_upper_threshold)
  ) {
    spec$audit_upper_threshold
  } else {
    NA_real_
  }
  observed_above_audit_threshold <- if (
    is.finite(audit_upper_threshold)
  ) {
    sum(observed > audit_upper_threshold + 1e-8, na.rm = TRUE)
  } else {
    NA_integer_
  }
  predicted_above_audit_threshold <- if (
    is.finite(audit_upper_threshold)
  ) {
    sum(predicted > audit_upper_threshold + 1e-8, na.rm = TRUE)
  } else {
    NA_integer_
  }
  tibble::tibble(
    observed_below_bound_n = observed_below,
    observed_above_bound_n = observed_above,
    predicted_below_bound_n = predicted_below,
    predicted_above_bound_n = if (upper_available) {
      predicted_above
    } else {
      NA_integer_
    },
    prediction_bound_status = if (
      observed_below > 0L || observed_above > 0L
    ) {
      "FAIL_OBSERVED_SUPPORT"
    } else if (predicted_below > 0L || (upper_available && predicted_above > 0L)) {
      "WARN_PREDICTED_BOUND"
    } else if (!upper_available) {
      "UPPER_BOUND_UNAVAILABLE"
    } else {
      "PASS"
    },
    audit_upper_threshold = audit_upper_threshold,
    observed_above_audit_threshold_n =
      observed_above_audit_threshold,
    predicted_above_audit_threshold_n =
      predicted_above_audit_threshold,
    audit_threshold_status = if (!is.finite(audit_upper_threshold)) {
      "NOT_APPLICABLE"
    } else if (observed_above_audit_threshold > 0L) {
      "WARN_OBSERVED_AUDIT_THRESHOLD"
    } else if (predicted_above_audit_threshold > 0L) {
      "WARN_PREDICTED_AUDIT_THRESHOLD"
    } else {
      "PASS"
    }
  )
}

h01_timing_diagnostic <- function(frame, spec) {
  if (!grepl("^clock_hours", spec$response_transform)) {
    return(tibble::tibble(
      timing_min_hour = NA_real_,
      timing_max_hour = NA_real_,
      timing_span_hours = NA_real_,
      early_cluster_fraction = NA_real_,
      late_cluster_fraction = NA_real_,
      timing_cutpoint_hour = NA_real_,
      observations_within_one_hour_of_cut = NA_integer_,
      fraction_within_one_hour_of_cut = NA_real_,
      timing_status = "NOT_APPLICABLE"
    ))
  }
  hours <- frame$value / 60
  model_hours <- frame$response_value
  early <- mean(hours < 3)
  late <- mean(hours > 21)
  cutpoint_hour <- switch(
    spec$response_transform,
    clock_hours_midnight_after_16 = 16,
    clock_hours_midnight_after_12 = 12,
    NA_real_
  )
  near_cut <- if (is.finite(cutpoint_hour)) {
    abs(hours - cutpoint_hour) <= 1
  } else {
    rep(FALSE, length(hours))
  }
  status <- if (is.finite(cutpoint_hour)) {
    "PASS"
  } else if (early > 0.01 && late > 0.01) {
    "FAIL_CLOCK_BOUNDARY"
  } else {
    "PASS"
  }
  tibble::tibble(
    timing_min_hour = min(model_hours),
    timing_max_hour = max(model_hours),
    timing_span_hours = diff(range(model_hours)),
    early_cluster_fraction = early,
    late_cluster_fraction = late,
    timing_cutpoint_hour = cutpoint_hour,
    observations_within_one_hour_of_cut = if (
      is.finite(cutpoint_hour)
    ) {
      sum(near_cut)
    } else {
      NA_integer_
    },
    fraction_within_one_hour_of_cut = if (
      is.finite(cutpoint_hour)
    ) {
      mean(near_cut)
    } else {
      NA_real_
    },
    timing_status = status
  )
}

h01_residual_diagnostics <- function(model, spec, seed) {
  if (is.null(model)) {
    return(tibble::tibble(
      shapiro_p = NA_real_,
      residual_variance_ratio = NA_real_,
      standardized_residual_over_3_fraction = NA_real_,
      standardized_residual_over_4_fraction = NA_real_,
      dharma_uniformity_p = NA_real_,
      dharma_dispersion_p = NA_real_,
      dharma_zero_inflation_p = NA_real_,
      dharma_outlier_p = NA_real_,
      observed_zero_fraction = NA_real_,
      simulated_zero_fraction = NA_real_,
      zero_fraction_ratio = NA_real_,
      residual_status = "NON_ESTIMABLE"
    ))
  }
  if (spec$response_family == "gaussian") {
    residual <- stats::residuals(model)
    fitted <- stats::fitted(model)
    sigma_value <- stats::sd(residual)
    standardized <- residual / sigma_value
    groups <- cut(
      fitted,
      breaks = unique(stats::quantile(
        fitted,
        probs = seq(0, 1, 0.25),
        na.rm = TRUE
      )),
      include.lowest = TRUE
    )
    group_variance <- tapply(residual, groups, stats::var, na.rm = TRUE)
    group_variance <- group_variance[
      is.finite(group_variance) & group_variance > 0
    ]
    variance_ratio <- if (length(group_variance) < 2L) {
      NA_real_
    } else {
      max(group_variance) / min(group_variance)
    }
    set.seed(seed)
    shapiro_values <- if (length(residual) > 5000L) {
      sample(residual, 5000L)
    } else {
      residual
    }
    shapiro_p <- if (length(shapiro_values) >= 3L) {
      stats::shapiro.test(shapiro_values)$p.value
    } else {
      NA_real_
    }
    tail3 <- mean(abs(standardized) > 3, na.rm = TRUE)
    tail4 <- mean(abs(standardized) > 4, na.rm = TRUE)
    status <- if (
      (is.finite(variance_ratio) && variance_ratio > 10) ||
        tail4 > 0.02
    ) {
      "WARN_STRONG_GAUSSIAN_MISFIT"
    } else if (
      (is.finite(variance_ratio) && variance_ratio > 4) ||
        tail3 > 0.02 ||
        (is.finite(shapiro_p) && shapiro_p < 0.001)
    ) {
      "WARN_GAUSSIAN_DIAGNOSTIC"
    } else {
      "PASS"
    }
    return(tibble::tibble(
      shapiro_p = shapiro_p,
      residual_variance_ratio = variance_ratio,
      standardized_residual_over_3_fraction = tail3,
      standardized_residual_over_4_fraction = tail4,
      dharma_uniformity_p = NA_real_,
      dharma_dispersion_p = NA_real_,
      dharma_zero_inflation_p = NA_real_,
      dharma_outlier_p = NA_real_,
      observed_zero_fraction = NA_real_,
      simulated_zero_fraction = NA_real_,
      zero_fraction_ratio = NA_real_,
      residual_status = status
    ))
  }
  set.seed(seed)
  simulated <- tryCatch(
    DHARMa::simulateResiduals(
      fittedModel = model,
      n = 250L,
      refit = FALSE,
      plot = FALSE
    ),
    error = function(error) NULL
  )
  if (is.null(simulated)) {
    return(tibble::tibble(
      shapiro_p = NA_real_,
      residual_variance_ratio = NA_real_,
      standardized_residual_over_3_fraction = NA_real_,
      standardized_residual_over_4_fraction = NA_real_,
      dharma_uniformity_p = NA_real_,
      dharma_dispersion_p = NA_real_,
      dharma_zero_inflation_p = NA_real_,
      dharma_outlier_p = NA_real_,
      observed_zero_fraction = mean(stats::model.response(
        stats::model.frame(model)
      ) == 0),
      simulated_zero_fraction = NA_real_,
      zero_fraction_ratio = NA_real_,
      residual_status = "WARN_DHARMA_UNAVAILABLE"
    ))
  }
  uniformity <- tryCatch(
    DHARMa::testUniformity(simulated, plot = FALSE)$p.value,
    error = function(error) NA_real_
  )
  dispersion <- tryCatch(
    DHARMa::testDispersion(simulated, plot = FALSE)$p.value,
    error = function(error) NA_real_
  )
  zero_inflation <- tryCatch(
    DHARMa::testZeroInflation(simulated, plot = FALSE)$p.value,
    error = function(error) NA_real_
  )
  outlier <- tryCatch(
    DHARMa::testOutliers(simulated, plot = FALSE)$p.value,
    error = function(error) NA_real_
  )
  response <- stats::model.response(stats::model.frame(model))
  observed_zero <- mean(response == 0)
  simulated_matrix <- simulated$simulatedResponse
  simulated_zero <- if (is.null(simulated_matrix)) {
    NA_real_
  } else {
    mean(simulated_matrix == 0)
  }
  zero_ratio <- if (
    !is.finite(simulated_zero) || simulated_zero == 0
  ) {
    if (observed_zero == 0) 1 else Inf
  } else {
    observed_zero / simulated_zero
  }
  p_values <- c(uniformity, dispersion, zero_inflation, outlier)
  status <- if (
    sum(p_values < 0.001, na.rm = TRUE) >= 2L ||
      (is.finite(zero_ratio) && (zero_ratio < 0.5 || zero_ratio > 2))
  ) {
    "WARN_STRONG_TWEEDIE_MISFIT"
  } else if (any(p_values < 0.01, na.rm = TRUE)) {
    "WARN_TWEEDIE_DIAGNOSTIC"
  } else {
    "PASS"
  }
  tibble::tibble(
    shapiro_p = NA_real_,
    residual_variance_ratio = NA_real_,
    standardized_residual_over_3_fraction = NA_real_,
    standardized_residual_over_4_fraction = NA_real_,
    dharma_uniformity_p = uniformity,
    dharma_dispersion_p = dispersion,
    dharma_zero_inflation_p = zero_inflation,
    dharma_outlier_p = outlier,
    observed_zero_fraction = observed_zero,
    simulated_zero_fraction = simulated_zero,
    zero_fraction_ratio = zero_ratio,
    residual_status = status
  )
}

h01_model_diagnostics <- function(bundle, frame, seed) {
  model <- h01_unwrap_model(bundle, "final", "site_full")
  fit_status <- h01_model_fit_status(model)
  timing <- h01_timing_diagnostic(frame, bundle$spec)
  residual <- h01_residual_diagnostics(model, bundle$spec, seed)
  bounds <- h01_prediction_bounds(model, frame, bundle$spec)
  fit_error <- bundle$final$site_full$error
  fit_warnings <- paste(bundle$final$site_full$warnings, collapse = " | ")
  status <- if (
    !is.na(fit_error) ||
      !fit_status$converged ||
      !fit_status$positive_definite_hessian ||
      isTRUE(fit_status$singular) ||
      startsWith(timing$timing_status, "FAIL") ||
      identical(bounds$prediction_bound_status, "FAIL_OBSERVED_SUPPORT")
  ) {
    "MODEL_CHECK_FAILED"
  } else if (
    startsWith(residual$residual_status, "WARN") ||
      startsWith(bounds$prediction_bound_status, "WARN") ||
      startsWith(bounds$audit_threshold_status, "WARN") ||
      nzchar(fit_warnings)
  ) {
    "WARN_REVIEW"
  } else {
    "PASS"
  }
  dplyr::bind_cols(
    fit_status,
    timing,
    residual,
    bounds,
    tibble::tibble(
      fit_error = fit_error,
      fit_warnings = fit_warnings,
      diagnostic_status = status
    )
  )
}

h01_diagnostic_plot_data <- function(model, frame) {
  if (is.null(model)) {
    return(tibble::tibble())
  }
  residual <- tryCatch(
    stats::residuals(model, type = "pearson"),
    error = function(error) stats::residuals(model)
  )
  fitted <- stats::fitted(model)
  standardized <- as.numeric(scale(residual))
  order_index <- order(standardized)
  theoretical <- stats::qnorm(stats::ppoints(length(standardized)))
  residual_rows <- tibble::tibble(
    panel = "residual_fitted",
    model_row_id = frame$.model_row_id,
    site = as.character(frame$site),
    participant_key = as.character(frame$participant_key),
    x = fitted,
    y = standardized
  )
  qq_rows <- tibble::tibble(
    panel = "normal_qq",
    model_row_id = frame$.model_row_id[order_index],
    site = as.character(frame$site[order_index]),
    participant_key = as.character(frame$participant_key[order_index]),
    x = theoretical,
    y = standardized[order_index]
  )
  dplyr::bind_rows(residual_rows, qq_rows)
}

h01_save_diagnostic_plot <- function(data, path, title) {
  if (nrow(data) == 0L) {
    return(invisible(NULL))
  }
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  residual <- data[data$panel == "residual_fitted", , drop = FALSE]
  qq <- data[data$panel == "normal_qq", , drop = FALSE]
  residual_plot <- ggplot2::ggplot(
    residual,
    ggplot2::aes(x = x, y = y)
  ) +
    ggplot2::geom_hline(yintercept = 0, colour = "grey60") +
    ggplot2::geom_point(alpha = 0.35, size = 0.8) +
    ggplot2::geom_smooth(se = FALSE, method = "loess", colour = "#0072B2") +
    ggplot2::labs(x = "Fitted value", y = "Standardized residual") +
    ggplot2::theme_minimal(base_size = 10)
  qq_plot <- ggplot2::ggplot(
    qq,
    ggplot2::aes(x = x, y = y)
  ) +
    ggplot2::geom_abline(slope = 1, intercept = 0, colour = "grey60") +
    ggplot2::geom_point(alpha = 0.35, size = 0.8) +
    ggplot2::labs(x = "Theoretical quantile", y = "Observed quantile") +
    ggplot2::theme_minimal(base_size = 10)
  plot <- patchwork::wrap_plots(
    residual_plot,
    qq_plot,
    nrow = 1
  ) +
    patchwork::plot_annotation(title = title)
  ggplot2::ggsave(
    filename = path,
    plot = plot,
    width = 10,
    height = 4.5,
    dpi = 180
  )
  invisible(path)
}

h01_candidate_participants <- function(model, frame, n = 3L) {
  if (is.null(model)) {
    return(character())
  }
  if (inherits(model, "lm") && !inherits(model, "merMod")) {
    cooks <- stats::cooks.distance(model)
    index <- order(cooks, decreasing = TRUE)[seq_len(min(n, length(cooks)))]
    return(unique(as.character(frame$participant_key[index])))
  }
  residual <- tryCatch(
    abs(stats::residuals(model, type = "pearson")),
    error = function(error) abs(stats::residuals(model))
  )
  residual_score <- tapply(
    residual,
    frame$participant_key,
    max,
    na.rm = TRUE
  )
  residual_candidates <- names(sort(
    residual_score,
    decreasing = TRUE
  ))[seq_len(min(n, length(residual_score)))]
  random_candidates <- character()
  random_effects <- tryCatch(
    if (inherits(model, "glmmTMB")) {
      glmmTMB::ranef(model)$cond$participant_key
    } else {
      lme4::ranef(model)$participant_key
    },
    error = function(error) NULL
  )
  if (!is.null(random_effects) && nrow(random_effects) > 0L) {
    values <- abs(random_effects[[1L]])
    names(values) <- rownames(random_effects)
    random_candidates <- names(sort(
      values,
      decreasing = TRUE
    ))[seq_len(min(n, length(values)))]
  }
  unique(c(residual_candidates, random_candidates))
}

h01_participant_influence <- function(bundle, frame) {
  full <- h01_unwrap_model(bundle, "final", "site_full")
  if (is.null(full)) {
    return(tibble::tibble())
  }
  candidates <- h01_candidate_participants(full, frame, n = 3L)
  if (length(candidates) == 0L) {
    return(tibble::tibble())
  }
  full_coefficients <- h01_fixed_effects(full)
  full_standard_error <- sqrt(diag(h01_fixed_vcov(full)))
  dplyr::bind_rows(lapply(candidates, function(candidate) {
    subset <- frame[
      as.character(frame$participant_key) != candidate,
      ,
      drop = FALSE
    ]
    subset$participant_key <- droplevels(subset$participant_key)
    fit <- h01_fit_model(
      subset,
      bundle$formulas$site_full,
      bundle$spec,
      estimation = "final"
    )
    if (!is.na(fit$error)) {
      return(tibble::tibble(
        omitted_participant = candidate,
        maximum_absolute_dfbeta = NA_real_,
        maximum_dfbeta_term = NA_character_,
        refit_status = "NON_ESTIMABLE",
        refit_error = fit$error
      ))
    }
    coefficients <- h01_fixed_effects(fit$model)
    shared <- intersect(names(full_coefficients), names(coefficients))
    dfbeta <- (coefficients[shared] - full_coefficients[shared]) /
      full_standard_error[shared]
    maximum <- which.max(abs(dfbeta))
    tibble::tibble(
      omitted_participant = candidate,
      maximum_absolute_dfbeta = abs(dfbeta[[maximum]]),
      maximum_dfbeta_term = names(dfbeta)[[maximum]],
      refit_status = if (
        h01_model_fit_status(fit$model)$converged
      ) {
        "PASS"
      } else {
        "NONCONVERGED"
      },
      refit_error = NA_character_
    )
  }))
}

h01_latitude_leave_one_site_out <- function(bundle, frame) {
  full <- h01_unwrap_model(bundle, "final", "latitude_full")
  if (is.null(full)) {
    return(tibble::tibble())
  }
  sites <- levels(frame$site)
  dplyr::bind_rows(lapply(sites, function(site_value) {
    subset <- frame[as.character(frame$site) != site_value, , drop = FALSE]
    subset$site <- droplevels(subset$site)
    subset$participant_key <- droplevels(subset$participant_key)
    fit <- h01_fit_model(
      subset,
      bundle$formulas$latitude_full,
      bundle$spec,
      estimation = "final"
    )
    term <- h01_extract_term_effect(
      if (is.na(fit$error)) fit$model else NULL,
      term = "absolute_latitude_10deg_centered",
      term_label = "Absolute latitude per 10 degrees",
      spec = bundle$spec
    )
    dplyr::bind_cols(
      tibble::tibble(
        omitted_site = site_value,
        observations = nrow(subset),
        participants = dplyr::n_distinct(subset$participant_key),
        sites = dplyr::n_distinct(subset$site),
        refit_error = fit$error,
        refit_warnings = paste(fit$warnings, collapse = " | ")
      ),
      term
    )
  }))
}

h01_fit_random_site_summary <- function(bundle) {
  fixed <- h01_unwrap_model(bundle, "comparison", "site_full")
  random <- h01_unwrap_model(bundle, "comparison", "random_site")
  if (is.null(random)) {
    return(tibble::tibble(
      random_site_sd = NA_real_,
      random_site_singular = NA,
      fixed_site_aic = if (is.null(fixed)) NA_real_ else stats::AIC(fixed),
      random_site_aic = NA_real_,
      random_minus_fixed_aic = NA_real_,
      status = "NON_ESTIMABLE"
    ))
  }
  site_variance <- tryCatch(
    {
      if (inherits(random, "glmmTMB")) {
        as.data.frame(glmmTMB::VarCorr(random)$cond)$sdcor[
          as.data.frame(glmmTMB::VarCorr(random)$cond)$grp == "site"
        ][1L]
      } else {
        data <- as.data.frame(lme4::VarCorr(random))
        data$sdcor[data$grp == "site"][1L]
      }
    },
    error = function(error) NA_real_
  )
  fit_status <- h01_model_fit_status(random)
  fixed_aic <- if (is.null(fixed)) NA_real_ else stats::AIC(fixed)
  random_aic <- stats::AIC(random)
  tibble::tibble(
    random_site_sd = site_variance,
    random_site_singular = fit_status$singular,
    fixed_site_aic = fixed_aic,
    random_site_aic = random_aic,
    random_minus_fixed_aic = random_aic - fixed_aic,
    status = if (
      fit_status$converged &&
        fit_status$positive_definite_hessian &&
        !isTRUE(fit_status$singular)
    ) {
      "DESCRIPTIVE_PASS"
    } else {
      "DESCRIPTIVE_UNSTABLE"
    }
  )
}

h01_refit_with_response <- function(fit, response, frame) {
  model <- fit$model
  if (inherits(model, "lm") && !inherits(model, "merMod")) {
    data <- frame
    data$response_value <- response
    return(h01_capture_fit(stats::lm(stats::formula(model), data = data)))
  }
  if (inherits(model, "glmmTMB")) {
    data <- frame
    data$response_value <- response
    return(h01_capture_fit(
      glmmTMB::glmmTMB(
        formula = stats::formula(model),
        data = data,
        family = glmmTMB::tweedie(link = "log"),
        REML = FALSE,
        control = glmmTMB::glmmTMBControl(
          optCtrl = list(iter.max = 10000L, eval.max = 10000L)
        )
      )
    ))
  }
  h01_capture_fit(lme4::refit(model, newresp = response))
}

h01_simulate_response <- function(model) {
  if (inherits(model, "lm") && !inherits(model, "merMod")) {
    return(stats::rnorm(
      stats::nobs(model),
      mean = stats::fitted(model),
      sd = summary(model)$sigma
    ))
  }
  as.numeric(stats::simulate(model, nsim = 1L)[[1L]])
}

h01_bootstrap_one <- function(attempt, bundle, frame, seed_base) {
  set.seed(seed_base + attempt)
  fit_names <- c(
    "site_full",
    "no_site",
    "no_photoperiod",
    "latitude_full"
  )
  fits <- bundle$final[fit_names]
  full <- fits$site_full$model
  response <- tryCatch(
    h01_simulate_response(full),
    error = function(error) error
  )
  if (inherits(response, "error")) {
    return(list(
      success = FALSE,
      attempt = attempt,
      error = conditionMessage(response),
      warnings = character(),
      values = NULL
    ))
  }
  refits <- lapply(fits, h01_refit_with_response, response = response, frame = frame)
  errors <- vapply(refits, function(fit) fit$error, character(1))
  warnings <- unique(unlist(lapply(refits, function(fit) fit$warnings)))
  if (any(!is.na(errors))) {
    return(list(
      success = FALSE,
      attempt = attempt,
      error = paste(stats::na.omit(errors), collapse = " | "),
      warnings = warnings,
      values = NULL
    ))
  }
  statuses <- lapply(refits, function(fit) h01_model_fit_status(fit$model))
  valid <- vapply(
    statuses,
    function(status) {
      isTRUE(status$converged) &&
        isTRUE(status$positive_definite_hessian) &&
        !isTRUE(status$singular)
    },
    logical(1)
  )
  if (!all(valid)) {
    return(list(
      success = FALSE,
      attempt = attempt,
      error = "A joint bootstrap refit failed convergence, Hessian, or singularity checks",
      warnings = warnings,
      values = NULL
    ))
  }
  models <- lapply(refits, function(fit) fit$model)
  primary <- h01_r2_from_models(
    models,
    bundle$spec,
    approximation = "lognormal"
  )
  values <- if (bundle$spec$response_family == "tweedie_log") {
    dplyr::bind_rows(
      primary,
      h01_r2_from_models(
        models,
        bundle$spec,
        approximation = "delta"
      )
    )
  } else {
    primary
  }
  list(
    success = all(values$status == "PASS"),
    attempt = attempt,
    error = if (all(values$status == "PASS")) NA_character_ else "R2 was non-estimable",
    warnings = warnings,
    values = values
  )
}

h01_bootstrap_r2 <- function(
  bundle,
  frame,
  seed,
  successful_refits = 1000L,
  cores = 1L,
  maximum_attempts = ceiling(successful_refits * 1.5)
) {
  requested_successful_refits <- as.integer(successful_refits)
  if (successful_refits < 1L) {
    h01_abort("`successful_refits` must be positive")
  }
  fit_names <- c(
    "site_full",
    "no_site",
    "no_photoperiod",
    "latitude_full"
  )
  if (any(vapply(
    bundle$final[fit_names],
    function(fit) is.null(fit$model) || !is.na(fit$error),
    logical(1)
  ))) {
    return(list(
      draws = tibble::tibble(),
      audit = tibble::tibble(
        attempted_refits = 0L,
        successful_refits = 0L,
        used_refits = 0L,
        failed_refits = 0L,
        warning_refits = 0L,
        seed = seed,
        interval_method = "parametric_percentile",
        status = "NON_ESTIMABLE"
      ),
      failures = tibble::tibble()
    ))
  }
  worker <- function(attempt) {
    h01_bootstrap_one(attempt, bundle, frame, seed)
  }
  # Every attempt has its own fixed seed. Stop after enough successful refits
  # while retaining the same first successful attempts in the same order.
  results <- list()
  successful_indices <- integer()
  while (length(successful_indices) < successful_refits &&
         length(results) < maximum_attempts) {
    needed <- successful_refits - length(successful_indices)
    batch_size <- min(maximum_attempts - length(results), max(needed, cores))
    attempts <- seq.int(length(results) + 1L, length(results) + batch_size)
    batch <- if (cores > 1L && .Platform$OS.type != "windows") {
      parallel::mclapply(
        attempts,
        worker,
        mc.cores = cores,
        mc.preschedule = TRUE,
        mc.set.seed = FALSE
      )
    } else {
      lapply(attempts, worker)
    }
    results <- c(results, batch)
    success <- vapply(results, function(result) isTRUE(result$success), logical(1))
    successful_indices <- which(success)
  }
  if (length(successful_indices) < successful_refits) {
    h01_abort(
      paste0(
        "H01 bootstrap obtained %d successful joint refits after %d attempts; ",
        "%d were required"
      ),
      length(successful_indices),
      maximum_attempts,
      successful_refits
    )
  }
  used_indices <- successful_indices[seq_len(successful_refits)]
  draws <- dplyr::bind_rows(lapply(used_indices, function(index) {
    results[[index]]$values |>
      dplyr::mutate(
        bootstrap_replicate = match(index, used_indices),
        attempt = results[[index]]$attempt,
        warning_count = length(results[[index]]$warnings),
        warnings = paste(results[[index]]$warnings, collapse = " | ")
      )
  }))
  failures <- dplyr::bind_rows(lapply(which(!success), function(index) {
    tibble::tibble(
      attempt = results[[index]]$attempt,
      error = results[[index]]$error,
      warning_count = length(results[[index]]$warnings),
      warnings = paste(results[[index]]$warnings, collapse = " | ")
    )
  }))
  warning_refits <- sum(vapply(
    results,
    function(result) length(result$warnings) > 0L,
    logical(1)
  ))
  list(
    draws = draws,
    audit = tibble::tibble(
      attempted_refits = length(results),
      successful_refits = sum(success),
      used_refits = requested_successful_refits,
      failed_refits = sum(!success),
      warning_refits = warning_refits,
      seed = seed,
      interval_method = "parametric_percentile",
      status = "PASS"
    ),
    failures = failures
  )
}

h01_summarize_bootstrap <- function(point, draws, confidence_level = 0.95) {
  measures <- c(
    "marginal_r2",
    "conditional_r2",
    "participant_associated_share",
    "site_part_r2",
    "photoperiod_part_r2",
    "latitude_model_marginal_r2",
    "latitude_part_r2",
    "unrepresented_share"
  )
  alpha <- (1 - confidence_level) / 2
  dplyr::bind_rows(lapply(seq_len(nrow(point)), function(i) {
    approximation <- point$approximation[[i]]
    approximation_draws <- draws[
      draws$approximation == approximation,
      ,
      drop = FALSE
    ]
    dplyr::bind_rows(lapply(measures, function(measure) {
      values <- approximation_draws[[measure]]
      values <- values[is.finite(values)]
      tibble::tibble(
        approximation = approximation,
        measure = measure,
        estimate = point[[measure]][[i]],
        conf_low = if (length(values) == 0L) {
          NA_real_
        } else {
          unname(stats::quantile(values, alpha, names = FALSE))
        },
        conf_high = if (length(values) == 0L) {
          NA_real_
        } else {
          unname(stats::quantile(values, 1 - alpha, names = FALSE))
        },
        bootstrap_successful_used = dplyr::n_distinct(
          approximation_draws$bootstrap_replicate
        ),
        interval_method = "joint_parametric_percentile",
        status = if (length(values) == 0L) {
          "NON_ESTIMABLE"
        } else {
          "PASS"
        }
      )
    }))
  }))
}
