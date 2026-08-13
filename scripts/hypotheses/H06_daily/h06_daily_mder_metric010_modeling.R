# H06_daily METRIC-010 model fitting, diagnostics, and extraction helpers.

h06d_m10_capture <- function(expression) {
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
    error = if (inherits(value, "error")) {
      conditionMessage(value)
    } else {
      NA_character_
    },
    warnings = unique(warnings),
    elapsed_seconds = elapsed
  )
}

h06d_m10_fit_gaussian <- function(frame, formula, REML = TRUE) {
  h06d_m10_capture(lme4::lmer(
    formula = formula,
    data = frame,
    REML = REML,
    control = lme4::lmerControl(
      optimizer = "nloptwrap",
      calc.derivs = TRUE,
      optCtrl = list(maxeval = 10000L)
    )
  ))
}

h06d_m10_fit_t <- function(frame, formula, REML = TRUE) {
  h06d_m10_capture(glmmTMB::glmmTMB(
    formula = formula,
    data = frame,
    family = glmmTMB::t_family(link = "identity"),
    REML = REML,
    control = glmmTMB::glmmTMBControl(
      optCtrl = list(iter.max = 10000L, eval.max = 10000L)
    )
  ))
}

h06d_m10_fit_ar_gaussian <- function(frame, formula, REML = TRUE) {
  h06d_m10_capture(glmmTMB::glmmTMB(
    formula = formula,
    data = frame,
    family = stats::gaussian(link = "identity"),
    REML = REML,
    control = glmmTMB::glmmTMBControl(
      optCtrl = list(iter.max = 10000L, eval.max = 10000L)
    )
  ))
}

h06d_m10_model_status <- function(model) {
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
    maximum_gradient <- if (is.null(gradient)) {
      0
    } else {
      max(abs(gradient))
    }
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
      convergence_message = if (length(messages) > 0L) {
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
  h06d_m10_abort("Unknown METRIC-010 model class")
}

h06d_m10_fixed_table <- function(model) {
  if (inherits(model, "merMod")) {
    estimate <- lme4::fixef(model)
    covariance <- as.matrix(stats::vcov(model))
  } else if (inherits(model, "glmmTMB")) {
    estimate <- glmmTMB::fixef(model)$cond
    covariance <- as.matrix(stats::vcov(model)$cond)
  } else {
    h06d_m10_abort("Cannot extract METRIC-010 fixed effects")
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

h06d_m10_effect_row <- function(model, predictor) {
  predictor_order <- predictor$predictor_order[[1L]]
  predictor_id <- predictor$predictor_id[[1L]]
  predictor_name <- predictor$reader_name[[1L]]
  contrast_label <- predictor$contrast_label[[1L]]
  effect_term <- predictor$term[[1L]]
  table <- h06d_m10_fixed_table(model)
  selected <- table |>
    dplyr::filter(.data$term == .env$effect_term)
  h06d_m10_assert(
    nrow(selected) == 1L,
    "METRIC-010 effect term `%s` was not uniquely estimated",
    effect_term
  )
  selected |>
    dplyr::mutate(
      predictor_order = .env$predictor_order,
      predictor_id = .env$predictor_id,
      predictor = .env$predictor_name,
      contrast = .env$contrast_label,
      effect_scale = "absolute MDER difference",
      unit = "dimensionless"
    ) |>
    dplyr::select(
      "predictor_order",
      "predictor_id",
      "predictor",
      "contrast",
      "term",
      "estimate",
      "standard_error",
      "lower_95",
      "upper_95",
      "effect_scale",
      "unit"
    )
}

h06d_m10_gaussian_residual_diagnostics <- function(model, frame) {
  residual <- as.numeric(stats::residuals(model))
  sigma <- stats::sigma(model)
  standardized <- residual / sigma
  conditional_prediction <- as.numeric(stats::predict(model))
  marginal_prediction <- as.numeric(stats::predict(model, re.form = NA))
  theoretical <- stats::qnorm(stats::ppoints(length(standardized)))
  tibble::tibble(
    residual_qq_correlation = stats::cor(
      sort(standardized),
      theoretical
    ),
    absolute_residual_fitted_spearman = suppressWarnings(stats::cor(
      abs(residual),
      conditional_prediction,
      method = "spearman",
      use = "complete.obs"
    )),
    standardized_residual_gt4_fraction = mean(abs(standardized) > 4),
    maximum_absolute_standardized_residual = max(abs(standardized)),
    conditional_prediction_minimum = min(conditional_prediction),
    marginal_prediction_minimum = min(marginal_prediction),
    conditional_below_minus_0_05_fraction = mean(
      conditional_prediction < -0.05
    ),
    marginal_below_minus_0_05_fraction = mean(
      marginal_prediction < -0.05
    ),
    residual_standard_deviation = stats::sd(residual),
    residual_skewness = mean(
      ((residual - mean(residual)) / stats::sd(residual))^3
    )
  )
}

h06d_m10_t_quantile_residuals <- function(model, frame) {
  mu <- as.numeric(stats::predict(model, type = "response"))
  scale <- stats::sigma(model)
  degrees_of_freedom <- unname(glmmTMB::family_params(model)[[1L]])
  probability <- stats::pt(
    (frame$response_value - mu) / scale,
    df = degrees_of_freedom
  )
  probability <- pmin(
    pmax(probability, .Machine$double.eps),
    1 - .Machine$double.eps
  )
  stats::qnorm(probability)
}

h06d_m10_t_residual_diagnostics <- function(model, frame) {
  quantile_residual <- h06d_m10_t_quantile_residuals(model, frame)
  prediction <- as.numeric(stats::predict(model, type = "response"))
  theoretical <- stats::qnorm(stats::ppoints(length(quantile_residual)))
  tibble::tibble(
    t_degrees_of_freedom = unname(glmmTMB::family_params(model)[[1L]]),
    quantile_residual_qq_correlation = stats::cor(
      sort(quantile_residual),
      theoretical
    ),
    absolute_quantile_residual_fitted_spearman = suppressWarnings(stats::cor(
      abs(quantile_residual),
      prediction,
      method = "spearman",
      use = "complete.obs"
    )),
    quantile_residual_gt4_fraction = mean(abs(quantile_residual) > 4),
    maximum_absolute_quantile_residual = max(abs(quantile_residual)),
    prediction_minimum = min(prediction),
    prediction_below_minus_0_05_fraction = mean(prediction < -0.05)
  )
}

h06d_m10_lag_screen <- function(frame, residual) {
  pairs <- frame |>
    dplyr::mutate(.residual = residual) |>
    dplyr::arrange(.data$participant_key, .data$local_date) |>
    dplyr::group_by(.data$participant_key) |>
    dplyr::mutate(
      previous_residual = dplyr::lag(.data$.residual),
      date_gap = as.integer(
        .data$local_date - dplyr::lag(.data$local_date)
      )
    ) |>
    dplyr::ungroup() |>
    dplyr::filter(
      .data$date_gap == 1L,
      is.finite(.data$.residual),
      is.finite(.data$previous_residual)
    )
  by_site <- pairs |>
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
  overall <- tibble::tibble(
    adjacent_pairs = nrow(pairs),
    participants = dplyr::n_distinct(pairs$participant_key),
    residual_lag1 = if (nrow(pairs) >= 3L) {
      stats::cor(pairs$.residual, pairs$previous_residual)
    } else {
      NA_real_
    },
    maximum_absolute_site_lag1 = max(
      abs(by_site$residual_lag1),
      na.rm = TRUE
    ),
    ar_trigger = (
      is.finite(if (nrow(pairs) >= 3L) {
        stats::cor(pairs$.residual, pairs$previous_residual)
      } else {
        NA_real_
      }) &&
        abs(if (nrow(pairs) >= 3L) {
          stats::cor(pairs$.residual, pairs$previous_residual)
        } else {
          NA_real_
        }) >= 0.20
    ) || any(abs(by_site$residual_lag1) >= 0.30, na.rm = TRUE)
  )
  list(overall = overall, by_site = by_site, pairs = pairs)
}

h06d_m10_ar_parameters <- function(model) {
  variance <- glmmTMB::VarCorr(model)$cond$day_sequence_id
  tibble::tibble(
    ar_standard_deviation = unname(attr(variance, "stddev")[[1L]]),
    ar_rho = unname(attr(variance, "correlation")[[1L, 2L]])
  )
}

h06d_m10_lrt_row <- function(reduced, full) {
  comparison <- stats::anova(reduced, full)
  tibble::tibble(
    likelihood_ratio = comparison$Chisq[[2L]],
    degrees_of_freedom = comparison$Df[[2L]],
    raw_p_value = comparison$`Pr(>Chisq)`[[2L]],
    method = "maximum-likelihood likelihood-ratio test"
  )
}

h06d_m10_design_check <- function(frame, predictor, heterogeneity = FALSE) {
  column <- predictor$column[[1L]]
  formula <- if (isTRUE(heterogeneity)) {
    stats::as.formula(sprintf("~ site * %s", column))
  } else {
    stats::as.formula(sprintf("~ site + %s", column))
  }
  matrix <- stats::model.matrix(formula, data = frame)
  rank <- qr(matrix)$rank
  categorical_cells_complete <- if (predictor$type[[1L]] == "categorical") {
    cells <- frame |>
      dplyr::count(
        .data$site,
        category = as.character(.data[[column]]),
        name = "participant_days"
      )
    dplyr::n_distinct(cells$site) *
      dplyr::n_distinct(as.character(frame[[column]])) == nrow(cells) &&
      all(cells$participant_days > 0L)
  } else {
    TRUE
  }
  continuous_variation_complete <- if (
    predictor$type[[1L]] == "continuous" && isTRUE(heterogeneity)
  ) {
    variation <- frame |>
      dplyr::summarise(
        standard_deviation = stats::sd(.data[[column]]),
        .by = "site"
      )
    all(is.finite(variation$standard_deviation)) &&
      all(variation$standard_deviation > 0)
  } else {
    TRUE
  }
  tibble::tibble(
    design_columns = ncol(matrix),
    design_rank = rank,
    full_column_rank = rank == ncol(matrix),
    categorical_cells_complete = categorical_cells_complete,
    continuous_site_variation_complete = continuous_variation_complete,
    estimable = rank == ncol(matrix) &&
      categorical_cells_complete &&
      continuous_variation_complete
  )
}

h06d_m10_deletion_refit <- function(
  frame,
  predictor,
  deletion_type = c("participant", "site"),
  deletion_value,
  full_estimate,
  full_standard_error
) {
  deletion_type <- match.arg(deletion_type)
  keep <- if (deletion_type == "participant") {
    as.character(frame$participant_key) != deletion_value
  } else {
    as.character(frame$site) != deletion_value
  }
  deletion_frame <- droplevels(frame[keep, , drop = FALSE])
  if (nlevels(deletion_frame$site) > 1L) {
    contrasts(deletion_frame$site) <- stats::contr.sum(
      nlevels(deletion_frame$site)
    )
  }
  formula <- h06d_m10_formula_set(
    predictor$column[[1L]]
  )$fixed_site_additive
  fit <- h06d_m10_fit_gaussian(deletion_frame, formula, REML = TRUE)
  if (is.null(fit$value)) {
    return(tibble::tibble(
      deletion_type = deletion_type,
      deletion_value = deletion_value,
      participant_days = nrow(deletion_frame),
      participants = dplyr::n_distinct(deletion_frame$participant_key),
      sites = dplyr::n_distinct(deletion_frame$site),
      estimate = NA_real_,
      standard_error = NA_real_,
      lower_95 = NA_real_,
      upper_95 = NA_real_,
      absolute_shift = NA_real_,
      absolute_shift_in_full_se = NA_real_,
      direction_reversal = NA,
      converged = FALSE,
      singular = NA,
      warning_count = length(fit$warnings),
      warnings = paste(fit$warnings, collapse = " | "),
      error = fit$error,
      elapsed_seconds = fit$elapsed_seconds
    ))
  }
  effect <- h06d_m10_effect_row(fit$value, predictor)
  status <- h06d_m10_model_status(fit$value)
  shift <- abs(effect$estimate - full_estimate)
  tibble::tibble(
    deletion_type = deletion_type,
    deletion_value = deletion_value,
    participant_days = nrow(deletion_frame),
    participants = dplyr::n_distinct(deletion_frame$participant_key),
    sites = dplyr::n_distinct(deletion_frame$site),
    estimate = effect$estimate,
    standard_error = effect$standard_error,
    lower_95 = effect$lower_95,
    upper_95 = effect$upper_95,
    absolute_shift = shift,
    absolute_shift_in_full_se = shift / full_standard_error,
    direction_reversal = sign(effect$estimate) != sign(full_estimate),
    converged = status$converged,
    singular = status$singular,
    warning_count = length(fit$warnings),
    warnings = paste(fit$warnings, collapse = " | "),
    error = fit$error,
    elapsed_seconds = fit$elapsed_seconds
  )
}
