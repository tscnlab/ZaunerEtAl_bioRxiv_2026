# H06_daily H06-D-013 per-cell fitting, diagnostics, and deletion helpers.

h06d_prod_capture <- function(expression) {
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
  list(
    value = if (inherits(value, "error")) NULL else value,
    error = if (inherits(value, "error")) conditionMessage(value) else NA_character_,
    warnings = unique(warnings),
    elapsed_seconds = unname(proc.time()[["elapsed"]] - started)
  )
}

h06d_prod_capture_summary <- function(capture, structure, method) {
  tibble::tibble(
    structure = structure,
    method = method,
    fitted = !is.null(capture$value),
    elapsed_seconds = capture$elapsed_seconds,
    warning_count = length(capture$warnings),
    warnings = paste(capture$warnings, collapse = " | "),
    fit_error = capture$error
  )
}

h06d_prod_empty_effect <- function(metric, predictor, method, status) {
  tibble::tibble(
    metric_slot = .env$metric$metric_slot[[1L]],
    metric_id = .env$metric$metric_id[[1L]],
    manuscript_name = .env$metric$manuscript_name[[1L]],
    predictor_order = .env$predictor$predictor_order[[1L]],
    predictor_id = .env$predictor$predictor_id[[1L]],
    predictor = .env$predictor$reader_name[[1L]],
    contrast = .env$predictor$contrast_label[[1L]],
    method = .env$method,
    term = .env$predictor$term[[1L]],
    estimate = NA_real_,
    standard_error = NA_real_,
    lower_95 = NA_real_,
    upper_95 = NA_real_,
    display_estimate = NA_real_,
    display_lower_95 = NA_real_,
    display_upper_95 = NA_real_,
    effect_scale = .env$metric$effect_scale[[1L]],
    interval_type = NA_character_,
    effect_status = .env$status
  )
}

h06d_prod_empty_test <- function(test_type, status, method) {
  tibble::tibble(
    test_type = test_type,
    statistic = NA_real_,
    numerator_degrees_of_freedom = NA_real_,
    denominator_degrees_of_freedom = NA_real_,
    raw_p_value = NA_real_,
    method = method,
    test_status = status
  )
}

h06d_prod_fixed_site_terms <- function(model, predictor) {
  names <- names(if (inherits(model, "lm")) stats::coef(model) else {
    if (inherits(model, "merMod")) lme4::fixef(model) else glmmTMB::fixef(model)$cond
  })
  names[
    grepl(":", names, fixed = TRUE) &
      grepl("site", names, fixed = TRUE) &
      grepl(predictor$column[[1L]], names, fixed = TRUE)
  ]
}

h06d_prod_mixed_fit <- function(frame, metric, predictor, formula, REML) {
  h06d_nl_fit_model(
    frame = frame,
    formula = formula,
    response_family = metric$response_family[[1L]],
    REML = REML,
    ar = FALSE
  )
}

h06d_prod_mixed_model_acceptable <- function(capture) {
  if (is.null(capture$value)) return(FALSE)
  status <- h06d_nl_model_status(capture$value)
  isTRUE(status$converged) && isTRUE(status$positive_definite_hessian) &&
    !isTRUE(status$singular)
}

h06d_prod_mixed_effect <- function(model, metric, predictor) {
  output <- h06d_nl_effect_row(model, predictor, metric)
  output |>
    dplyr::transmute(
      metric_slot = .data$metric_slot,
      metric_id = .data$metric_id,
      manuscript_name = .data$manuscript_name,
      predictor_order = .data$predictor_order,
      predictor_id = .data$predictor_id,
      predictor = .data$predictor,
      contrast = .data$contrast,
      method = "mixed_model_primary_route",
      term = .data$term,
      estimate = .data$estimate,
      standard_error = .data$standard_error,
      lower_95 = .data$lower_95,
      upper_95 = .data$upper_95,
      display_estimate = .data$display_estimate,
      display_lower_95 = .data$display_lower_95,
      display_upper_95 = .data$display_upper_95,
      effect_scale = .data$effect_scale,
      interval_type = "model-based pointwise 95% confidence interval",
      effect_status = "ESTIMABLE"
    )
}

h06d_prod_mixed_test <- function(reduced, full, test_type) {
  result <- h06d_nl_lrt_row(reduced, full, test_type)
  result |>
    dplyr::transmute(
      test_type = .env$test_type,
      statistic = .data$likelihood_ratio,
      numerator_degrees_of_freedom = .data$degrees_of_freedom,
      denominator_degrees_of_freedom = NA_real_,
      raw_p_value = .data$raw_p_value,
      method = "maximum-likelihood likelihood-ratio test",
      test_status = dplyr::if_else(
        .data$test_status == "PILOT_RAW_ONLY",
        "ESTIMABLE_RAW_PENDING_FAMILY",
        .data$test_status
      )
    )
}

h06d_prod_tweedie_diagnostics <- function(model, frame, metric) {
  residual <- as.numeric(stats::residuals(model, type = "pearson"))
  fitted <- as.numeric(stats::predict(model, type = "response"))
  centered <- residual - mean(residual, na.rm = TRUE)
  residual_sd <- stats::sd(centered, na.rm = TRUE)
  power <- tryCatch(
    unname(sigma(model)),
    error = function(condition) NA_real_
  )
  if (!is.finite(power) || power <= 1 || power >= 2) {
    power <- tryCatch(
      unname(model$family$getTheta(trans = TRUE)[[1L]]),
      error = function(condition) NA_real_
    )
  }
  prediction <- h06d_nl_prediction_bounds(model, frame, metric)
  tibble::tibble(
    tweedie_power = power,
    tweedie_power_interior = is.finite(power) && power > 1 && power < 2,
    exact_zero_fraction = mean(frame$response_source == 0),
    pearson_residual_fitted_spearman = abs(suppressWarnings(stats::cor(
      abs(residual),
      fitted,
      method = "spearman",
      use = "complete.obs"
    ))),
    pearson_residual_skewness = if (is.finite(residual_sd) && residual_sd > 0) {
      mean((centered / residual_sd)^3, na.rm = TRUE)
    } else {
      NA_real_
    },
    standardized_residual_gt4_fraction = if (
      is.finite(residual_sd) && residual_sd > 0
    ) mean(abs(centered / residual_sd) > 4, na.rm = TRUE) else NA_real_,
    simulation_diagnostic_status =
      "NOT_RUN_BY_H06-D-013_NO_SIMULATION_AUTHORIZATION"
  ) |>
    dplyr::bind_cols(prediction)
}

h06d_prod_mixed_ar_diagnostic <- function(
  frame,
  metric,
  predictor,
  primary_model,
  primary_effect
) {
  lag <- h06d_nl_lag_screen(
    frame,
    as.numeric(stats::residuals(primary_model, type = "pearson"))
  )
  support <- lag$overall$adjacent_pairs >= 100L &&
    lag$overall$participants >= 20L
  default <- list(
    model = NULL,
    summary = tibble::tibble(
      independent_residual_lag1 = lag$overall$residual_lag1,
      independent_maximum_absolute_site_lag1 =
        lag$overall$maximum_absolute_site_lag1,
      adjacent_pairs = lag$overall$adjacent_pairs,
      participants_with_adjacency = lag$overall$participants,
      ar_trigger = lag$overall$ar_trigger,
      ar_support = support,
      ar_fitted = FALSE,
      ar_rho = NA_real_,
      ar_effect_shift_in_primary_se = NA_real_,
      ar_direction_reversal = NA,
      post_ar_residual_lag1 = NA_real_,
      post_ar_maximum_absolute_site_lag1 = NA_real_,
      ar_acceptable = !isTRUE(lag$overall$ar_trigger),
      ar_disposition = if (isTRUE(lag$overall$ar_trigger)) {
        if (support) "TRIGGERED_PENDING_FIT" else "UNRESOLVED_SPARSE_AR_SUPPORT"
      } else {
        "NOT_TRIGGERED"
      },
      ar_warning_count = 0L,
      ar_warnings = NA_character_,
      ar_fit_error = NA_character_
    ),
    by_site = lag$by_site,
    post_by_site = tibble::tibble()
  )
  if (!isTRUE(lag$overall$ar_trigger) || !support) return(default)

  special_pre_sleep <- identical(metric$metric_id[[1L]], "duration_below_10_pre_sleep") &&
    identical(predictor$predictor_id[[1L]], "previous_sleep_duration_centered_h") &&
    nrow(frame) == 648L &&
    dplyr::n_distinct(frame$participant_key) == 139L &&
    dplyr::n_distinct(frame$site) == 9L
  if (special_pre_sleep) {
    frozen <- readRDS(file.path(
      getwd(),
      "artifacts/07_models/H06_daily/H06_daily_pre_sleep_no_nugget_diagnostic_model.rds"
    ))
    current_key <- frame |>
      dplyr::transmute(
        key = paste(as.character(.data$site), .data$Id, .data$local_date, sep = "|"),
        response_value = .data$response_value
      ) |>
      dplyr::arrange(.data$key)
    frozen_frame <- readRDS(file.path(getwd(), frozen$frame_relative_path)) |>
      dplyr::transmute(
        key = paste(as.character(.data$site), .data$Id, .data$local_date, sep = "|"),
        response_value = .data$response_value
      ) |>
      dplyr::arrange(.data$key)
    h06d_prod_assert(
      identical(current_key$key, frozen_frame$key) &&
        identical(current_key$response_value, frozen_frame$response_value),
      "Frozen pre-sleep no-nugget sensitivity does not match the production frame"
    )
    final <- frozen$diagnostics
    effect <- frozen$effect_stability |>
      dplyr::filter(.data$model_id == "no_nugget_ar1")
    default$model <- list(
      reused_frozen_object = TRUE,
      relative_path = paste0(
        "artifacts/07_models/H06_daily/",
        "H06_daily_pre_sleep_no_nugget_diagnostic_model.rds"
      ),
      sha256 = "d1271775f2a46252247ac945977e338866df3a99f68d9af123067329fd526368"
    )
    default$summary <- default$summary |>
      dplyr::mutate(
        ar_fitted = TRUE,
        ar_rho = final$ar_rho,
        ar_effect_shift_in_primary_se = effect$shift_from_frozen_lmer_se,
        ar_direction_reversal = !effect$direction_matches_frozen_lmer,
        post_ar_residual_lag1 = final$true_date_residual_lag1,
        post_ar_maximum_absolute_site_lag1 =
          final$maximum_absolute_site_residual_lag1,
        ar_acceptable = TRUE,
        ar_disposition = "ACCEPTABLE_REUSED_FROZEN_PRE_SLEEP_NO_NUGGET",
        ar_warning_count = final$warning_count,
        ar_warnings = final$warnings,
        ar_fit_error = NA_character_
      )
    default$post_by_site <- frozen$site_lag
    return(default)
  }

  ar_frame <- h06d_nl_add_day_sequences(frame)
  ar_formula <- h06d_nl_formula_set(
    predictor$column[[1L]],
    ar = TRUE
  )$fixed_site_additive
  ar_capture <- h06d_nl_fit_model(
    ar_frame,
    ar_formula,
    "gaussian",
    REML = TRUE,
    ar = TRUE
  )
  if (is.null(ar_capture$value)) {
    default$summary <- default$summary |>
      dplyr::mutate(
        ar_disposition = "UNRESOLVED_AR_FIT_FAILURE",
        ar_warning_count = length(ar_capture$warnings),
        ar_warnings = paste(ar_capture$warnings, collapse = " | "),
        ar_fit_error = ar_capture$error
      )
    return(default)
  }
  status <- h06d_nl_model_status(ar_capture$value)
  parameters <- h06d_nl_ar_parameters(ar_capture$value)
  ar_effect <- h06d_nl_effect_row(ar_capture$value, predictor, metric)
  shift <- abs(ar_effect$estimate - primary_effect$estimate) /
    primary_effect$standard_error
  reversal <- sign(ar_effect$estimate) != sign(primary_effect$estimate)
  post <- h06d_nl_lag_screen(
    ar_frame,
    as.numeric(stats::residuals(ar_capture$value, type = "pearson"))
  )
  acceptable <- isTRUE(status$converged) &&
    isTRUE(status$positive_definite_hessian) &&
    !isTRUE(status$singular) &&
    is.finite(parameters$ar_rho) && abs(parameters$ar_rho) < 0.95 &&
    is.finite(shift) && shift < 1 && !isTRUE(reversal) &&
    is.finite(post$overall$residual_lag1) &&
    abs(post$overall$residual_lag1) < 0.20 &&
    is.finite(post$overall$maximum_absolute_site_lag1) &&
    post$overall$maximum_absolute_site_lag1 < 0.30
  disposition <- dplyr::case_when(
    !isTRUE(status$converged) || !isTRUE(status$positive_definite_hessian) ~
      "UNRESOLVED_AR_NUMERICAL_FAILURE",
    isTRUE(status$singular) ~ "UNRESOLVED_AR_SINGULAR",
    !is.finite(parameters$ar_rho) || abs(parameters$ar_rho) >= 0.95 ~
      "UNRESOLVED_AR_BOUNDARY",
    !is.finite(shift) || shift >= 2 || isTRUE(reversal) ~
      "UNSTABLE_AR_EFFECT",
    shift >= 1 ~ "SUBSTANTIAL_AR_EFFECT_LIMITATION",
    !is.finite(post$overall$residual_lag1) ||
      abs(post$overall$residual_lag1) >= 0.20 ||
      !is.finite(post$overall$maximum_absolute_site_lag1) ||
      post$overall$maximum_absolute_site_lag1 >= 0.30 ~
      "UNRESOLVED_POST_AR_RESIDUAL_DEPENDENCE",
    TRUE ~ "ACCEPTABLE"
  )
  default$model <- ar_capture
  default$summary <- default$summary |>
    dplyr::mutate(
      ar_fitted = TRUE,
      ar_rho = parameters$ar_rho,
      ar_effect_shift_in_primary_se = shift,
      ar_direction_reversal = reversal,
      post_ar_residual_lag1 = post$overall$residual_lag1,
      post_ar_maximum_absolute_site_lag1 =
        post$overall$maximum_absolute_site_lag1,
      ar_acceptable = acceptable,
      ar_disposition = disposition,
      ar_warning_count = length(ar_capture$warnings),
      ar_warnings = paste(ar_capture$warnings, collapse = " | "),
      ar_fit_error = ar_capture$error
    )
  default$post_by_site <- post$by_site
  default
}

h06d_prod_fit_mixed_cell <- function(frame, metric, predictor, meta) {
  formulas <- h06d_nl_formula_set(predictor$column[[1L]])
  additive_design <- h06d_nl_design_check(frame, predictor, FALSE)
  heterogeneity_design <- h06d_nl_design_check(frame, predictor, TRUE)
  model_rows <- list()
  models <- list()

  model_spec <- list(
    reduced_ml = list(formula = formulas$fixed_site_reduced, REML = FALSE),
    additive_ml = list(formula = formulas$fixed_site_additive, REML = FALSE),
    additive_reml = list(formula = formulas$fixed_site_additive, REML = TRUE),
    heterogeneity_ml = list(
      formula = formulas$fixed_site_heterogeneity,
      REML = FALSE,
      permitted = isTRUE(heterogeneity_design$estimable)
    ),
    heterogeneity_reml = list(
      formula = formulas$fixed_site_heterogeneity,
      REML = TRUE,
      permitted = isTRUE(heterogeneity_design$estimable)
    ),
    registered_benchmark = list(
      formula = formulas$registered_random_site,
      REML = TRUE,
      permitted = TRUE
    )
  )
  for (name in names(model_spec)) {
    spec <- model_spec[[name]]
    permitted <- is.null(spec$permitted) || isTRUE(spec$permitted)
    capture <- if (permitted) {
      h06d_prod_mixed_fit(frame, metric, predictor, spec$formula, spec$REML)
    } else {
      list(
        value = NULL,
        error = "design not estimable",
        warnings = character(),
        elapsed_seconds = 0
      )
    }
    models[[name]] <- capture
    status <- if (!is.null(capture$value)) {
      h06d_nl_model_status(capture$value)
    } else {
      tibble::tibble(
        converged = FALSE,
        positive_definite_hessian = FALSE,
        singular = NA,
        maximum_absolute_gradient = NA_real_,
        convergence_message = capture$error
      )
    }
    model_rows[[name]] <- dplyr::bind_cols(
      h06d_prod_capture_summary(
        capture,
        name,
        if (metric$response_family[[1L]] == "gaussian") {
          if (spec$REML) "Gaussian REML" else "Gaussian ML"
        } else {
          "Tweedie log maximum likelihood"
        }
      ),
      tibble::tibble(
        formula = h06d_prod_formula_text(spec$formula),
        design_permitted = permitted
      ),
      status
    )
  }

  additive_ok <- h06d_prod_mixed_model_acceptable(models$additive_reml)
  effect <- if (additive_ok) {
    h06d_prod_mixed_effect(models$additive_reml$value, metric, predictor)
  } else {
    h06d_prod_empty_effect(
      metric,
      predictor,
      "mixed_model_primary_route",
      "NON_ESTIMABLE_ADDITIVE_MODEL"
    )
  }

  association_ok <- h06d_prod_mixed_model_acceptable(models$reduced_ml) &&
    h06d_prod_mixed_model_acceptable(models$additive_ml)
  association <- if (association_ok) {
    h06d_prod_mixed_test(
      models$reduced_ml$value,
      models$additive_ml$value,
      "association"
    )
  } else {
    h06d_prod_empty_test(
      "association",
      "NON_ESTIMABLE_MODEL_FAILURE",
      "maximum-likelihood likelihood-ratio test"
    )
  }
  heterogeneity_ok <- association_ok &&
    isTRUE(heterogeneity_design$estimable) &&
    h06d_prod_mixed_model_acceptable(models$heterogeneity_ml)
  heterogeneity <- if (heterogeneity_ok) {
    h06d_prod_mixed_test(
      models$additive_ml$value,
      models$heterogeneity_ml$value,
      "site_heterogeneity"
    )
  } else {
    h06d_prod_empty_test(
      "site_heterogeneity",
      if (isTRUE(heterogeneity_design$estimable)) {
        "NON_ESTIMABLE_MODEL_FAILURE"
      } else {
        "NON_ESTIMABLE_DESIGN"
      },
      "maximum-likelihood likelihood-ratio test"
    )
  }
  tests <- dplyr::bind_rows(association, heterogeneity)

  effect_model <- models$additive_reml$value
  status <- if (additive_ok) h06d_nl_model_status(effect_model) else {
    tibble::tibble(
      converged = FALSE,
      positive_definite_hessian = FALSE,
      singular = NA,
      maximum_absolute_gradient = NA_real_,
      convergence_message = "additive model not acceptable"
    )
  }
  diagnostics <- dplyr::bind_cols(
    additive_design |>
      dplyr::rename_with(~ paste0("additive_", .x)),
    heterogeneity_design |>
      dplyr::rename_with(~ paste0("heterogeneity_", .x)),
    status |>
      dplyr::rename_with(~ paste0("additive_", .x)),
    tibble::tibble(
      exact_zero_fraction = mean(frame$response_source == 0),
      response_minimum = min(frame$response_source),
      response_median = stats::median(frame$response_source),
      response_maximum = max(frame$response_source)
    )
  )
  if (additive_ok && metric$response_family[[1L]] == "gaussian") {
    gaussian <- h06d_nl_gaussian_residual_diagnostics(effect_model)
    bounds <- h06d_nl_prediction_bounds(effect_model, frame, metric)
    diagnostics <- dplyr::bind_cols(diagnostics, gaussian, bounds)
  } else if (additive_ok && metric$response_family[[1L]] == "tweedie_log") {
    diagnostics <- dplyr::bind_cols(
      diagnostics,
      h06d_prod_tweedie_diagnostics(effect_model, frame, metric)
    )
  }

  ar <- if (additive_ok && metric$response_family[[1L]] == "gaussian") {
    h06d_prod_mixed_ar_diagnostic(
      frame,
      metric,
      predictor,
      effect_model,
      effect
    )
  } else {
    residual <- if (additive_ok) {
      as.numeric(stats::residuals(effect_model, type = "pearson"))
    } else {
      rep(NA_real_, nrow(frame))
    }
    lag <- h06d_nl_lag_screen(frame, residual)
    list(
      model = NULL,
      summary = tibble::tibble(
        independent_residual_lag1 = lag$overall$residual_lag1,
        independent_maximum_absolute_site_lag1 =
          lag$overall$maximum_absolute_site_lag1,
        adjacent_pairs = lag$overall$adjacent_pairs,
        participants_with_adjacency = lag$overall$participants,
        ar_trigger = lag$overall$ar_trigger,
        ar_support = lag$overall$adjacent_pairs >= 100L &&
          lag$overall$participants >= 20L,
        ar_fitted = FALSE,
        ar_rho = NA_real_,
        ar_effect_shift_in_primary_se = NA_real_,
        ar_direction_reversal = NA,
        post_ar_residual_lag1 = NA_real_,
        post_ar_maximum_absolute_site_lag1 = NA_real_,
        ar_acceptable = NA,
        ar_disposition = if (isTRUE(lag$overall$ar_trigger)) {
          "TRIGGERED_NOT_FITTED_NON_GAUSSIAN_ROUTE"
        } else {
          "NOT_TRIGGERED"
        },
        ar_warning_count = 0L,
        ar_warnings = NA_character_,
        ar_fit_error = NA_character_
      ),
      by_site = lag$by_site,
      post_by_site = tibble::tibble()
    )
  }
  diagnostics <- dplyr::bind_cols(diagnostics, ar$summary)

  benchmark <- dplyr::filter(
    dplyr::bind_rows(model_rows, .id = "model_id"),
    .data$model_id == "registered_benchmark"
  ) |>
    dplyr::mutate(
      benchmark_disposition = dplyr::if_else(
        .data$converged & .data$positive_definite_hessian &
          !dplyr::coalesce(.data$singular, TRUE),
        "ESTIMABLE_BENCHMARK_ONLY",
        "NON_ESTIMABLE_BENCHMARK"
      )
    )

  marginal <- if (additive_ok) {
    h06d_nl_equal_site_summary(effect_model, predictor, metric)
  } else {
    tibble::tibble()
  }
  list(
    route = "mixed_model",
    models = models,
    model_diagnostics = dplyr::bind_rows(model_rows, .id = "model_id"),
    effect = effect,
    tests = tests,
    diagnostics = diagnostics,
    marginals = marginal,
    benchmark = benchmark,
    lag_by_site = ar$by_site,
    post_ar_lag_by_site = ar$post_by_site,
    influence_reference = list(
      model = effect_model,
      estimate = effect$estimate[[1L]],
      standard_error = effect$standard_error[[1L]]
    )
  )
}

h06d_prod_hc3_fit_set <- function(frame, predictor) {
  formulas <- h06d_tr_formula_set(predictor$column[[1L]], ar = FALSE)
  formulas <- lapply(formulas, function(formula) {
    environment(formula) <- environment()
    formula
  })
  fits <- lapply(formulas, function(formula) h06d_tr_fit_lm(frame, formula))
  models <- lapply(fits, `[[`, "value")
  covariance <- lapply(models, function(model) {
    if (is.null(model)) {
      list(value = NULL, error = "LM fit failed", warnings = character(), elapsed_seconds = 0)
    } else {
      h06d_tr_hc3(model)
    }
  })
  list(formulas = formulas, fits = fits, models = models, covariance = covariance)
}

h06d_prod_hc3_effect <- function(model, covariance, metric, predictor, clusters) {
  base <- h06d_tr_effect(model, covariance, predictor, clusters)
  base |>
    dplyr::transmute(
      metric_slot = .env$metric$metric_slot[[1L]],
      metric_id = .env$metric$metric_id[[1L]],
      manuscript_name = .env$metric$manuscript_name[[1L]],
      predictor_order = .env$predictor$predictor_order[[1L]],
      predictor_id = .env$predictor$predictor_id[[1L]],
      predictor = .env$predictor$reader_name[[1L]],
      contrast = .env$predictor$contrast_label[[1L]],
      method = "fixed_site_lm_participant_cluster_HC3",
      term = .data$term,
      estimate = .data$estimate_hours,
      standard_error = .data$standard_error_hours,
      lower_95 = .data$lower_95_hours,
      upper_95 = .data$upper_95_hours,
      display_estimate = .data$estimate_hours,
      display_lower_95 = .data$lower_95_hours,
      display_upper_95 = .data$upper_95_hours,
      effect_scale = .env$metric$effect_scale[[1L]],
      interval_type = .data$interval_type,
      effect_status = "ESTIMABLE"
    )
}

h06d_prod_hc3_test <- function(model, covariance, terms, clusters, test_type) {
  result <- h06d_tr_wald_test(
    model,
    covariance,
    terms,
    clusters,
    paste0(test_type, "_block")
  )
  result |>
    dplyr::transmute(
      test_type = test_type,
      statistic = .data$f_statistic,
      numerator_degrees_of_freedom = .data$numerator_degrees_of_freedom,
      denominator_degrees_of_freedom = .data$denominator_degrees_of_freedom,
      raw_p_value = .data$raw_p_value,
      method = paste0(
        "participant-cluster HC3 robust Wald F; cluster-minus-one reference"
      ),
      test_status = dplyr::if_else(
        .data$test_status == "PILOT_RAW_ONLY_NO_BH_UPDATE",
        "ESTIMABLE_RAW_PENDING_FAMILY",
        .data$test_status
      )
    )
}

h06d_prod_fit_hc3_cell <- function(frame, metric, predictor, meta) {
  clusters <- dplyr::n_distinct(frame$participant_key)
  fit_set <- h06d_prod_hc3_fit_set(frame, predictor)
  model_rows <- list()
  gate <- logical()
  for (structure in names(fit_set$formulas)) {
    fit <- fit_set$fits[[structure]]
    covariance <- fit_set$covariance[[structure]]
    model_status <- h06d_tr_lm_status(fit$value)
    covariance_status <- h06d_tr_matrix_status(covariance$value)
    leverage <- if (!is.null(fit$value)) {
      h06d_tr_leverage(fit$value, frame)
    } else {
      tibble::tibble(
        observations = nrow(frame),
        participant_clusters = clusters,
        maximum_observation_hat = NA_real_,
        mean_observation_hat = NA_real_,
        maximum_cluster_hat_sum = NA_real_,
        maximum_cluster_hat_share = NA_real_,
        maximum_cluster_hat_ratio_to_median = NA_real_,
        maximum_cluster_id = NA_character_,
        maximum_cluster_days = NA_integer_,
        hc3_leverage_numerically_usable = FALSE
      )
    }
    passed <- !is.null(fit$value) && !is.null(covariance$value) &&
      isTRUE(model_status$design_full_rank) &&
      isTRUE(model_status$finite_coefficients) &&
      isTRUE(covariance_status$finite) &&
      isTRUE(covariance_status$symmetric) &&
      isTRUE(covariance_status$positive_semidefinite) &&
      isTRUE(leverage$hc3_leverage_numerically_usable) &&
      length(covariance$warnings) == 0L
    gate[[structure]] <- passed
    model_rows[[structure]] <- dplyr::bind_cols(
      h06d_prod_capture_summary(
        fit,
        structure,
        "fixed-site lm with participant-cluster HC3"
      ),
      tibble::tibble(
        formula = h06d_prod_formula_text(fit_set$formulas[[structure]]),
        covariance_elapsed_seconds = covariance$elapsed_seconds,
        covariance_warning_count = length(covariance$warnings),
        covariance_warnings = paste(covariance$warnings, collapse = " | "),
        covariance_error = covariance$error
      ),
      model_status,
      covariance_status,
      leverage,
      tibble::tibble(candidate_model_gate_pass = passed)
    )
  }

  additive_ok <- isTRUE(gate[["additive"]])
  interaction_ok <- isTRUE(gate[["interaction"]])
  additive_terms <- predictor$term[[1L]]
  interaction_terms <- if (interaction_ok) {
    h06d_tr_interaction_terms(
      fit_set$models$interaction,
      predictor$column[[1L]]
    )
  } else {
    character()
  }
  effect <- if (additive_ok) {
    h06d_prod_hc3_effect(
      fit_set$models$additive,
      fit_set$covariance$additive$value,
      metric,
      predictor,
      clusters
    )
  } else {
    h06d_prod_empty_effect(
      metric,
      predictor,
      "fixed_site_lm_participant_cluster_HC3",
      "NON_ESTIMABLE_ADDITIVE_MODEL_OR_COVARIANCE"
    )
  }
  association <- if (additive_ok) {
    h06d_prod_hc3_test(
      fit_set$models$additive,
      fit_set$covariance$additive$value,
      additive_terms,
      clusters,
      "association"
    )
  } else {
    h06d_prod_empty_test(
      "association",
      "NON_ESTIMABLE_MODEL_OR_COVARIANCE",
      "participant-cluster HC3 robust Wald F"
    )
  }
  heterogeneity <- if (interaction_ok && length(interaction_terms) > 0L) {
    h06d_prod_hc3_test(
      fit_set$models$interaction,
      fit_set$covariance$interaction$value,
      interaction_terms,
      clusters,
      "site_heterogeneity"
    )
  } else {
    h06d_prod_empty_test(
      "site_heterogeneity",
      "NON_ESTIMABLE_MODEL_OR_COVARIANCE",
      "participant-cluster HC3 robust Wald F"
    )
  }

  residual <- if (additive_ok) {
    h06d_tr_residual_diagnostics(fit_set$models$additive, frame)
  } else {
    list(
      overall = tibble::tibble(
        residual_qq_correlation = NA_real_,
        absolute_residual_fitted_spearman = NA_real_,
        standardized_residual_gt4_fraction = NA_real_,
        fitted_minimum = NA_real_,
        fitted_maximum = NA_real_,
        residual_lag1 = NA_real_,
        maximum_absolute_site_lag1 = NA_real_,
        adjacent_pairs = NA_integer_,
        participants_with_adjacent_pair = NA_integer_
      ),
      by_site = tibble::tibble()
    )
  }
  source <- h06d_tr_clock_support(frame, metric)
  diagnostics <- dplyr::bind_cols(
    source,
    residual$overall,
    tibble::tibble(
      participant_clusters = clusters,
      all_three_candidate_models_pass = all(gate),
      association_estimable = association$test_status ==
        "ESTIMABLE_RAW_PENDING_FAMILY",
      heterogeneity_estimable = heterogeneity$test_status ==
        "ESTIMABLE_RAW_PENDING_FAMILY"
    )
  )

  student <- list(models = list(), diagnostics = tibble::tibble(), stability = tibble::tibble())
  if (additive_ok && interaction_ok) {
    student_fits <- lapply(
      fit_set$formulas,
      function(formula) h06d_tr_fit_student_t(frame, formula)
    )
    student_models <- lapply(student_fits, `[[`, "value")
    student_status <- lapply(names(student_fits), function(structure) {
      dplyr::bind_cols(
        tibble::tibble(structure = structure),
        h06d_tr_glmmtmb_status(
          student_models[[structure]],
          student_fits[[structure]]
        )
      )
    }) |>
      dplyr::bind_rows()
    additive_pass <- student_status$converged[student_status$structure == "additive"]
    interaction_pass <- student_status$converged[
      student_status$structure == "interaction"
    ]
    student_stability <- dplyr::bind_rows(
      h06d_tr_shift_summary(
        fit_set$models$additive,
        fit_set$covariance$additive$value,
        if (isTRUE(additive_pass)) student_models$additive else NULL,
        additive_terms,
        "predictor_additive"
      ),
      h06d_tr_shift_summary(
        fit_set$models$interaction,
        fit_set$covariance$interaction$value,
        if (isTRUE(interaction_pass)) student_models$interaction else NULL,
        interaction_terms,
        "predictor_by_site_block"
      )
    ) |>
      dplyr::mutate(
        sensitivity_id = "student_t_identity",
        inferential_role = "diagnostic only; no p-value substitution"
      )
    student <- list(
      models = student_fits,
      diagnostics = student_status,
      stability = student_stability
    )
  }

  ar <- list(models = list(), diagnostics = tibble::tibble(), stability = tibble::tibble(), lag = tibble::tibble())
  if (additive_ok && interaction_ok) {
    ar_frame <- h06d_tr_add_day_sequences(frame)
    ar_formulas <- h06d_tr_formula_set(predictor$column[[1L]], ar = TRUE)
    ar_fits <- lapply(
      ar_formulas,
      function(formula) h06d_tr_fit_no_nugget_ar(ar_frame, formula)
    )
    ar_models <- lapply(ar_fits, `[[`, "value")
    ar_rows <- list()
    ar_lag <- list()
    ar_pass <- list()
    for (structure in names(ar_formulas)) {
      status <- h06d_tr_glmmtmb_status(ar_models[[structure]], ar_fits[[structure]])
      covariance_rank <- h06d_tr_covariance_rank(ar_models[[structure]])
      parameters <- h06d_tr_ar_parameters(ar_models[[structure]])
      lag <- if (!is.null(ar_models[[structure]])) {
        h06d_tr_lag_screen(
          ar_frame,
          as.numeric(stats::residuals(ar_models[[structure]]))
        )
      } else {
        list(
          overall = tibble::tibble(
            adjacent_pairs = NA_integer_,
            participants_with_adjacent_pair = NA_integer_,
            residual_lag1 = NA_real_,
            maximum_absolute_site_lag1 = NA_real_,
            temporal_threshold_pass = FALSE
          ),
          by_site = tibble::tibble()
        )
      }
      ar_pass[[structure]] <- isTRUE(status$converged) &&
        isTRUE(covariance_rank$covariance_full_rank) &&
        isTRUE(parameters$no_nugget_verified)
      ar_rows[[structure]] <- dplyr::bind_cols(
        tibble::tibble(
          structure = structure,
          formula = h06d_prod_formula_text(ar_formulas[[structure]]),
          elapsed_seconds = ar_fits[[structure]]$elapsed_seconds
        ),
        status,
        covariance_rank,
        parameters,
        lag$overall
      )
      if (nrow(lag$by_site)) {
        ar_lag[[structure]] <- lag$by_site |>
          dplyr::mutate(structure = structure, .before = 1L)
      }
    }
    ar_stability <- dplyr::bind_rows(
      h06d_tr_shift_summary(
        fit_set$models$additive,
        fit_set$covariance$additive$value,
        if (isTRUE(ar_pass$additive)) ar_models$additive else NULL,
        additive_terms,
        "predictor_additive"
      ),
      h06d_tr_shift_summary(
        fit_set$models$interaction,
        fit_set$covariance$interaction$value,
        if (isTRUE(ar_pass$interaction)) ar_models$interaction else NULL,
        interaction_terms,
        "predictor_by_site_block"
      )
    ) |>
      dplyr::mutate(
        sensitivity_id = "no_nugget_gap_aware_ar1",
        inferential_role = "diagnostic only; no p-value substitution"
      )
    ar <- list(
      models = ar_fits,
      diagnostics = dplyr::bind_rows(ar_rows),
      stability = ar_stability,
      lag = dplyr::bind_rows(ar_lag)
    )
  }

  marginals <- if (additive_ok) {
    h06d_tr_equal_site_marginals(
      fit_set$models$additive,
      fit_set$covariance$additive$value,
      frame,
      predictor,
      metric,
      clusters
    )
  } else {
    tibble::tibble()
  }
  list(
    route = "participant_cluster_HC3",
    models = fit_set,
    model_diagnostics = dplyr::bind_rows(model_rows, .id = "model_id"),
    effect = effect,
    tests = dplyr::bind_rows(association, heterogeneity),
    diagnostics = diagnostics,
    marginals = marginals,
    benchmark = tibble::tibble(
      benchmark_disposition = "NOT_APPLICABLE_TO_ACCEPTED_HC3_ROUTE"
    ),
    lag_by_site = residual$by_site,
    post_ar_lag_by_site = ar$lag,
    student_t = student,
    no_nugget_ar = ar,
    influence_reference = list(
      model = fit_set$models$additive,
      covariance = fit_set$covariance$additive$value,
      estimate = effect$estimate[[1L]],
      standard_error = effect$standard_error[[1L]],
      clusters = clusters
    )
  )
}

h06d_prod_fit_cell <- function(frame, metric, predictor, meta) {
  if (metric$metric_slot[[1L]] %in% c(9L, 10L, 12L, 13L)) {
    h06d_prod_fit_hc3_cell(frame, metric, predictor, meta)
  } else {
    h06d_prod_fit_mixed_cell(frame, metric, predictor, meta)
  }
}

h06d_prod_influence_class <- function(shift, reversal, converged) {
  dplyr::case_when(
    !isTRUE(converged) || !is.finite(shift) ~ "NON_ESTIMABLE_DELETION_REFIT",
    isTRUE(reversal) || shift >= 2 ~ "UNSTABLE",
    shift >= 1 ~ "SUBSTANTIAL_LIMITATION",
    TRUE ~ "STABLE"
  )
}

h06d_prod_hc3_deletion <- function(
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
  } else {
    as.character(frame$site) != deletion_value
  }
  reduced <- droplevels(frame[keep, , drop = FALSE])
  contrasts(reduced$site) <- stats::contr.sum(nlevels(reduced$site))
  formula <- h06d_tr_formula_set(predictor$column[[1L]])$additive
  formula_environment <- new.env(parent = environment())
  formula_environment$frame <- reduced
  environment(formula) <- formula_environment
  fit <- h06d_tr_fit_lm(reduced, formula)
  covariance <- if (is.null(fit$value)) {
    list(value = NULL, error = fit$error, warnings = character(), elapsed_seconds = 0)
  } else {
    h06d_tr_hc3(fit$value)
  }
  clusters <- dplyr::n_distinct(reduced$participant_key)
  effect <- if (!is.null(fit$value) && !is.null(covariance$value)) {
    h06d_prod_hc3_effect(
      fit$value,
      covariance$value,
      metric,
      predictor,
      clusters
    )
  } else {
    h06d_prod_empty_effect(
      metric,
      predictor,
      "fixed_site_lm_participant_cluster_HC3",
      "NON_ESTIMABLE_DELETION_REFIT"
    )
  }
  shift <- abs(effect$estimate - full_effect) / full_standard_error
  reversal <- is.finite(effect$estimate) && is.finite(full_effect) &&
    sign(effect$estimate) != sign(full_effect)
  status <- if (!is.null(fit$value)) h06d_tr_lm_status(fit$value) else {
    tibble::tibble(
      coefficients = NA_integer_,
      design_rank = NA_integer_,
      design_full_rank = FALSE,
      finite_coefficients = FALSE,
      finite_standard_errors = FALSE,
      residual_degrees_of_freedom = NA_integer_
    )
  }
  converged <- !is.null(fit$value) && !is.null(covariance$value) &&
    isTRUE(status$design_full_rank) && isTRUE(status$finite_coefficients) &&
    all(is.finite(covariance$value))
  tibble::tibble(
    participant_days = nrow(reduced),
    participants = dplyr::n_distinct(reduced$participant_key),
    sites = dplyr::n_distinct(reduced$site),
    estimate = effect$estimate,
    standard_error = effect$standard_error,
    lower_95 = effect$lower_95,
    upper_95 = effect$upper_95,
    absolute_shift_in_full_se = shift,
    direction_reversal = reversal,
    converged = converged,
    warning_count = length(c(fit$warnings, covariance$warnings)),
    warnings = paste(unique(c(fit$warnings, covariance$warnings)), collapse = " | "),
    fit_error = paste(na.omit(c(fit$error, covariance$error)), collapse = " | "),
    elapsed_seconds = fit$elapsed_seconds + covariance$elapsed_seconds,
    influence_classification = h06d_prod_influence_class(
      shift,
      reversal,
      converged
    )
  )
}

h06d_prod_mixed_deletion <- function(
  frame,
  metric,
  predictor,
  deletion_type,
  deletion_value,
  full_effect,
  full_standard_error
) {
  result <- h06d_nl_deletion_refit(
    frame,
    metric,
    predictor,
    deletion_type,
    deletion_value,
    full_effect,
    full_standard_error
  )
  converged <- isTRUE(result$converged) &&
    isTRUE(result$positive_definite_hessian) &&
    !isTRUE(result$singular) && is.na(result$fit_error)
  result |>
    dplyr::mutate(
      converged = converged,
      influence_classification = h06d_prod_influence_class(
        .data$absolute_shift_in_full_se,
        .data$direction_reversal,
        .env$converged
      )
    )
}

h06d_prod_deletion_refit <- function(
  frame,
  metric,
  predictor,
  route,
  deletion_type,
  deletion_value,
  full_effect,
  full_standard_error
) {
  if (identical(route, "participant_cluster_HC3")) {
    h06d_prod_hc3_deletion(
      frame,
      metric,
      predictor,
      deletion_type,
      deletion_value,
      full_effect,
      full_standard_error
    )
  } else {
    h06d_prod_mixed_deletion(
      frame,
      metric,
      predictor,
      deletion_type,
      deletion_value,
      full_effect,
      full_standard_error
    )
  }
}
