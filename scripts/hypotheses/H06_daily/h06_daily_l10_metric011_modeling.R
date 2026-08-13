# H06_daily METRIC-011 model fitting and component-appropriate diagnostics.

h06d_l10_capture <- function(expression) {
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

h06d_l10_fit_occurrence <- function(frame, formula) {
  h06d_l10_capture(glmmTMB::glmmTMB(
    formula = formula,
    data = frame,
    family = stats::binomial(link = "logit"),
    REML = FALSE,
    control = glmmTMB::glmmTMBControl(
      optCtrl = list(iter.max = 10000L, eval.max = 10000L)
    )
  ))
}

h06d_l10_occurrence_prior <- function(standard_deviation) {
  data.frame(
    prior = rep(sprintf("normal(0,%s)", standard_deviation), 2L),
    class = rep("fixef", 2L),
    coef = c("(Intercept)", ""),
    stringsAsFactors = FALSE
  )
}

h06d_l10_fit_occurrence_map <- function(frame, formula, standard_deviation) {
  h06d_l10_capture(glmmTMB::glmmTMB(
    formula = formula,
    data = frame,
    family = stats::binomial(link = "logit"),
    REML = FALSE,
    priors = h06d_l10_occurrence_prior(standard_deviation),
    control = glmmTMB::glmmTMBControl(
      optCtrl = list(iter.max = 10000L, eval.max = 10000L)
    )
  ))
}

h06d_l10_fit_positive_gaussian <- function(frame, formula, REML = TRUE) {
  h06d_l10_capture(lme4::lmer(
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

h06d_l10_fit_positive_t <- function(frame, formula, REML = TRUE) {
  h06d_l10_capture(glmmTMB::glmmTMB(
    formula = formula,
    data = frame,
    family = glmmTMB::t_family(link = "identity"),
    REML = REML,
    control = glmmTMB::glmmTMBControl(
      optCtrl = list(iter.max = 10000L, eval.max = 10000L)
    )
  ))
}

h06d_l10_fit_one_part <- function(parent_frame, formula, REML = TRUE) {
  frame <- parent_frame |>
    dplyr::mutate(response_value = log10(.data$response_source + 0.1))
  fit <- h06d_l10_fit_positive_gaussian(frame, formula, REML = REML)
  fit$frame <- frame
  fit
}

h06d_l10_fit_ar <- function(frame, formula, component) {
  family <- if (component == "zero_occurrence") {
    stats::binomial(link = "logit")
  } else {
    stats::gaussian(link = "identity")
  }
  h06d_l10_capture(glmmTMB::glmmTMB(
    formula = formula,
    data = h06d_l10_add_day_sequences(frame),
    family = family,
    REML = component == "positive_magnitude",
    control = glmmTMB::glmmTMBControl(
      optCtrl = list(iter.max = 10000L, eval.max = 10000L)
    )
  ))
}

h06d_l10_model_status <- function(model) {
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
      all(eigen(hessian, symmetric = TRUE, only.values = TRUE)$values > -1e-8)
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
    singular <- tryCatch(
      as.logical(performance::check_singularity(model)),
      error = function(condition) NA
    )
    return(tibble::tibble(
      converged = identical(as.integer(model$fit$convergence), 0L) &&
        isTRUE(model$sdr$pdHess),
      positive_definite_hessian = isTRUE(model$sdr$pdHess),
      singular = singular[[1L]],
      maximum_absolute_gradient = NA_real_,
      convergence_message = paste(model$fit$message, collapse = " | ")
    ))
  }
  h06d_l10_abort("Unknown METRIC-011 fitted model class")
}

h06d_l10_fixed_estimate <- function(model) {
  if (inherits(model, "merMod")) {
    estimate <- lme4::fixef(model)
    covariance <- as.matrix(stats::vcov(model))
  } else if (inherits(model, "glmmTMB")) {
    estimate <- glmmTMB::fixef(model)$cond
    covariance <- as.matrix(stats::vcov(model)$cond)
  } else {
    h06d_l10_abort("Cannot extract METRIC-011 fixed effects")
  }
  list(estimate = estimate, covariance = covariance)
}

h06d_l10_effect_row <- function(model, predictor, component, family_label) {
  fixed <- h06d_l10_fixed_estimate(model)
  term <- predictor$term[[1L]]
  predictor_order <- predictor$predictor_order[[1L]]
  predictor_id <- predictor$predictor_id[[1L]]
  predictor_name <- predictor$reader_name[[1L]]
  contrast_label <- predictor$contrast_label[[1L]]
  h06d_l10_assert(
    term %in% names(fixed$estimate),
    "METRIC-011 effect term `%s` was not estimated",
    term
  )
  estimate <- unname(fixed$estimate[[term]])
  standard_error <- sqrt(fixed$covariance[term, term])
  critical <- stats::qnorm(0.975)
  lower <- estimate - critical * standard_error
  upper <- estimate + critical * standard_error
  if (component == "zero_occurrence") {
    effect_scale <- "odds ratio for an exact-zero L10 mean"
    transformed <- exp(c(estimate, lower, upper))
  } else {
    effect_scale <- "ratio of conditional geometric means among positive L10 values"
    transformed <- 10^c(estimate, lower, upper)
  }
  tibble::tibble(
    predictor_order = predictor_order,
    predictor_id = predictor_id,
    predictor = predictor_name,
    contrast = contrast_label,
    component = component,
    family = family_label,
    term = term,
    link_estimate = estimate,
    link_standard_error = standard_error,
    link_lower_95 = lower,
    link_upper_95 = upper,
    estimate = transformed[[1L]],
    lower_95 = transformed[[2L]],
    upper_95 = transformed[[3L]],
    effect_scale = effect_scale,
    interval_type = "model-based pointwise 95% confidence interval"
  )
}

h06d_l10_occurrence_diagnostics <- function(model, frame) {
  prediction <- as.numeric(stats::predict(model, type = "response"))
  response <- frame$response_value
  pearson <- as.numeric(stats::residuals(model, type = "pearson"))
  residual_df <- max(1, nrow(frame) - length(glmmTMB::fixef(model)$cond))
  fixed <- h06d_l10_fixed_estimate(model)$estimate
  tibble::tibble(
    observed_zero_fraction = mean(response),
    mean_predicted_zero_probability = mean(prediction),
    predicted_to_observed_zero_ratio = mean(prediction) / mean(response),
    brier_score = mean((response - prediction)^2),
    log_loss = -mean(
      response * log(pmax(prediction, .Machine$double.eps)) +
        (1 - response) * log(pmax(1 - prediction, .Machine$double.eps))
    ),
    pearson_dispersion = sum(pearson^2) / residual_df,
    minimum_predicted_probability = min(prediction),
    maximum_predicted_probability = max(prediction),
    maximum_absolute_fixed_coefficient = max(abs(fixed)),
    maximum_fixed_standard_error = max(sqrt(diag(
      h06d_l10_fixed_estimate(model)$covariance
    ))),
    separation_flag = max(abs(fixed)) > 10 ||
      max(sqrt(diag(h06d_l10_fixed_estimate(model)$covariance))) > 10
  )
}

h06d_l10_positive_diagnostics <- function(model, frame) {
  residual <- as.numeric(stats::residuals(model))
  sigma <- stats::sigma(model)
  standardized <- residual / sigma
  prediction <- as.numeric(stats::predict(model))
  theoretical <- stats::qnorm(stats::ppoints(length(standardized)))
  tibble::tibble(
    residual_qq_correlation = stats::cor(sort(standardized), theoretical),
    absolute_residual_fitted_spearman = suppressWarnings(stats::cor(
      abs(residual),
      prediction,
      method = "spearman",
      use = "complete.obs"
    )),
    standardized_residual_gt4_fraction = mean(abs(standardized) > 4),
    maximum_absolute_standardized_residual = max(abs(standardized)),
    residual_skewness = mean(
      ((residual - mean(residual)) / stats::sd(residual))^3
    ),
    fitted_log10_minimum = min(prediction),
    fitted_log10_maximum = max(prediction),
    inverse_fitted_minimum_lx = min(10^prediction),
    inverse_fitted_maximum_lx = max(10^prediction)
  )
}

h06d_l10_lag_screen <- function(frame, residual) {
  pairs <- frame |>
    dplyr::mutate(.residual = residual) |>
    dplyr::arrange(.data$participant_key, .data$local_date) |>
    dplyr::group_by(.data$participant_key) |>
    dplyr::mutate(
      previous_residual = dplyr::lag(.data$.residual),
      date_gap = as.integer(.data$local_date - dplyr::lag(.data$local_date))
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
  pooled <- if (nrow(pairs) >= 3L) {
    stats::cor(pairs$.residual, pairs$previous_residual)
  } else {
    NA_real_
  }
  maximum_site <- if (any(is.finite(by_site$residual_lag1))) {
    max(abs(by_site$residual_lag1), na.rm = TRUE)
  } else {
    NA_real_
  }
  overall <- tibble::tibble(
    adjacent_pairs = nrow(pairs),
    participants = dplyr::n_distinct(pairs$participant_key),
    residual_lag1 = pooled,
    maximum_absolute_site_lag1 = maximum_site,
    ar_trigger = (is.finite(pooled) && abs(pooled) >= 0.20) ||
      (is.finite(maximum_site) && maximum_site >= 0.30),
    ar_support_adequate = nrow(pairs) >= 100L &&
      dplyr::n_distinct(pairs$participant_key) >= 20L
  )
  list(overall = overall, by_site = by_site, pairs = pairs)
}

h06d_l10_ar_parameters <- function(model) {
  variance <- glmmTMB::VarCorr(model)$cond$day_sequence_id
  correlation <- attr(variance, "correlation")
  tibble::tibble(
    ar_standard_deviation = unname(attr(variance, "stddev")[[1L]]),
    ar_rho = if (nrow(correlation) >= 2L) {
      unname(correlation[[1L, 2L]])
    } else {
      NA_real_
    }
  )
}

h06d_l10_lrt_row <- function(reduced, full, component) {
  reduced_loglik <- stats::logLik(reduced)
  full_loglik <- stats::logLik(full)
  statistic <- 2 * (as.numeric(full_loglik) - as.numeric(reduced_loglik))
  degrees <- attr(full_loglik, "df") - attr(reduced_loglik, "df")
  statistic <- max(0, statistic)
  tibble::tibble(
    component = component,
    likelihood_ratio = statistic,
    degrees_of_freedom = degrees,
    raw_p_value = stats::pchisq(statistic, degrees, lower.tail = FALSE),
    method = "maximum-likelihood likelihood-ratio test"
  )
}

h06d_l10_combined_lrt <- function(occurrence, positive, test_type) {
  h06d_l10_assert(
    nrow(occurrence) == 1L && nrow(positive) == 1L,
    "METRIC-011 combined LRT requires both component tests"
  )
  statistic <- occurrence$likelihood_ratio + positive$likelihood_ratio
  degrees <- occurrence$degrees_of_freedom + positive$degrees_of_freedom
  tibble::tibble(
    test_type = test_type,
    likelihood_ratio = statistic,
    degrees_of_freedom = degrees,
    raw_p_value = stats::pchisq(statistic, degrees, lower.tail = FALSE),
    method = paste0(
      "joint two-part maximum-likelihood LRT: sum of zero-occurrence and ",
      "strictly-positive magnitude component statistics"
    ),
    occurrence_likelihood_ratio = occurrence$likelihood_ratio,
    occurrence_degrees_of_freedom = occurrence$degrees_of_freedom,
    occurrence_raw_p_value = occurrence$raw_p_value,
    positive_likelihood_ratio = positive$likelihood_ratio,
    positive_degrees_of_freedom = positive$degrees_of_freedom,
    positive_raw_p_value = positive$raw_p_value
  )
}

h06d_l10_design_check <- function(frame, predictor, heterogeneity = FALSE) {
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
    design_rows = nrow(matrix),
    design_columns = ncol(matrix),
    design_rank = rank,
    full_rank = rank == ncol(matrix),
    categorical_cells_complete = categorical_cells_complete,
    continuous_variation_complete = continuous_variation_complete,
    estimable = rank == ncol(matrix) &&
      categorical_cells_complete && continuous_variation_complete
  )
}

h06d_l10_registered_status <- function(model, capture) {
  status <- h06d_l10_model_status(model)
  maximum_correlation <- NA_real_
  if (!is.null(model)) {
    variance <- if (inherits(model, "merMod")) {
      lme4::VarCorr(model)$site
    } else {
      glmmTMB::VarCorr(model)$cond$site
    }
    correlation <- attr(variance, "correlation")
    if (!is.null(correlation) && nrow(correlation) > 1L) {
      maximum_correlation <- max(
        abs(correlation[upper.tri(correlation)]),
        na.rm = TRUE
      )
    }
  }
  dplyr::bind_cols(
    status,
    tibble::tibble(
      warning_count = length(capture$warnings),
      warnings = paste(capture$warnings, collapse = " | "),
      fit_error = capture$error,
      maximum_absolute_random_site_correlation = maximum_correlation,
      disposition = if (
        is.null(model) ||
          !isTRUE(status$converged) ||
          isTRUE(status$singular) ||
          (is.finite(maximum_correlation) && maximum_correlation >= 0.98)
      ) {
        "NON_ESTIMABLE_BENCHMARK"
      } else {
        "ESTIMABLE_BENCHMARK_ONLY"
      }
    )
  )
}

h06d_l10_fixed_matrix <- function(model, formula, newdata) {
  fixed <- h06d_l10_fixed_estimate(model)
  fixed_terms <- stats::delete.response(stats::terms(lme4::nobars(formula)))
  matrix <- stats::model.matrix(fixed_terms, data = newdata)
  missing <- setdiff(names(fixed$estimate), colnames(matrix))
  h06d_l10_assert(
    length(missing) == 0L,
    "Prediction matrix omits fixed terms: %s",
    paste(missing, collapse = ", ")
  )
  matrix[, names(fixed$estimate), drop = FALSE]
}

h06d_l10_prediction_grid <- function(frame, predictor) {
  column <- predictor$column[[1L]]
  sites <- levels(droplevels(frame$site))
  targets <- if (predictor$type[[1L]] == "categorical") {
    levels(droplevels(frame[[column]]))
  } else {
    c("8 h", "9 h")
  }
  values <- if (predictor$type[[1L]] == "categorical") {
    targets
  } else {
    c(0, 1)
  }
  grid <- expand.grid(
    site = sites,
    target_index = seq_along(targets),
    KEEP.OUT.ATTRS = FALSE,
    stringsAsFactors = FALSE
  ) |>
    tibble::as_tibble() |>
    dplyr::mutate(target = targets[.data$target_index])
  grid$site <- factor(grid$site, levels = levels(frame$site))
  contrasts(grid$site) <- contrasts(frame$site)
  if (predictor$type[[1L]] == "categorical") {
    grid[[column]] <- factor(
      values[grid$target_index],
      levels = levels(frame[[column]])
    )
    contrasts(grid[[column]]) <- contrasts(frame[[column]])
  } else {
    grid[[column]] <- values[grid$target_index]
  }
  grid
}

h06d_l10_pointwise_standardization <- function(
  occurrence_model,
  positive_model,
  occurrence_frame,
  positive_frame,
  predictor,
  formulas
) {
  grid <- h06d_l10_prediction_grid(occurrence_frame, predictor)
  h06d_l10_assert(
    identical(
      levels(droplevels(occurrence_frame$site)),
      levels(droplevels(positive_frame$site))
    ),
    "Occurrence and positive models do not contain the same sites"
  )
  occurrence_matrix <- h06d_l10_fixed_matrix(
    occurrence_model,
    formulas$fixed_site_additive,
    grid
  )
  positive_matrix <- h06d_l10_fixed_matrix(
    positive_model,
    formulas$fixed_site_additive,
    grid
  )
  occurrence_fixed <- h06d_l10_fixed_estimate(occurrence_model)
  positive_fixed <- h06d_l10_fixed_estimate(positive_model)
  eta_occurrence <- as.numeric(occurrence_matrix %*% occurrence_fixed$estimate)
  eta_positive <- as.numeric(positive_matrix %*% positive_fixed$estimate)
  probability_zero <- stats::plogis(eta_occurrence)
  positive_geometric_mean <- 10^eta_positive
  zero_inclusive_index <- (1 - probability_zero) * positive_geometric_mean
  critical <- stats::qnorm(0.975)

  target_rows <- lapply(sort(unique(grid$target_index)), function(target_index) {
    select <- grid$target_index == target_index
    p <- probability_zero[select]
    gm <- positive_geometric_mean[select]
    x_occ <- occurrence_matrix[select, , drop = FALSE]
    x_pos <- positive_matrix[select, , drop = FALSE]
    probability_estimate <- mean(p)
    probability_gradient <- colMeans(x_occ * as.numeric(p * (1 - p)))
    probability_variance <- as.numeric(
      t(probability_gradient) %*% occurrence_fixed$covariance %*%
        probability_gradient
    )
    positive_estimate <- mean(gm)
    positive_gradient <- colMeans(x_pos * as.numeric(log(10) * gm))
    positive_variance <- as.numeric(
      t(positive_gradient) %*% positive_fixed$covariance %*%
        positive_gradient
    )
    index_estimate <- mean((1 - p) * gm)
    index_occurrence_gradient <- colMeans(
      x_occ * as.numeric(-p * (1 - p) * gm)
    )
    index_positive_gradient <- colMeans(
      x_pos * as.numeric((1 - p) * log(10) * gm)
    )
    index_variance <- as.numeric(
      t(index_occurrence_gradient) %*% occurrence_fixed$covariance %*%
        index_occurrence_gradient +
        t(index_positive_gradient) %*% positive_fixed$covariance %*%
        index_positive_gradient
    )
    target <- unique(grid$target[select])
    summaries <- tibble::tribble(
      ~quantity, ~estimate, ~standard_error, ~lower_95, ~upper_95, ~unit,
      "exact-zero probability",
      probability_estimate,
      sqrt(max(0, probability_variance)),
      max(0, probability_estimate - critical * sqrt(max(0, probability_variance))),
      min(1, probability_estimate + critical * sqrt(max(0, probability_variance))),
      "probability",
      "positive conditional geometric mean",
      positive_estimate,
      sqrt(max(0, positive_variance)),
      max(0, positive_estimate - critical * sqrt(max(0, positive_variance))),
      positive_estimate + critical * sqrt(max(0, positive_variance)),
      "lx melEDI",
      "zero-inclusive geometric-magnitude index",
      index_estimate,
      sqrt(max(0, index_variance)),
      max(0, index_estimate - critical * sqrt(max(0, index_variance))),
      index_estimate + critical * sqrt(max(0, index_variance)),
      "lx melEDI index"
    ) |>
      dplyr::mutate(
        target_index = target_index,
        target = target,
        interval_type = "model-based pointwise 95% confidence interval",
        .before = 1L
      )
    list(
      summaries = summaries,
      p = probability_estimate,
      gm = positive_estimate,
      index = index_estimate,
      probability_gradient = probability_gradient,
      positive_gradient = positive_gradient,
      index_occurrence_gradient = index_occurrence_gradient,
      index_positive_gradient = index_positive_gradient
    )
  })

  first <- target_rows[[1L]]
  second <- target_rows[[2L]]
  difference <- second$index - first$index
  difference_occurrence_gradient <-
    second$index_occurrence_gradient - first$index_occurrence_gradient
  difference_positive_gradient <-
    second$index_positive_gradient - first$index_positive_gradient
  difference_variance <- as.numeric(
    t(difference_occurrence_gradient) %*% occurrence_fixed$covariance %*%
      difference_occurrence_gradient +
      t(difference_positive_gradient) %*% positive_fixed$covariance %*%
      difference_positive_gradient
  )
  ratio <- second$index / first$index
  ratio_occurrence_gradient <-
    second$index_occurrence_gradient / first$index -
    second$index * first$index_occurrence_gradient / first$index^2
  ratio_positive_gradient <-
    second$index_positive_gradient / first$index -
    second$index * first$index_positive_gradient / first$index^2
  ratio_variance <- as.numeric(
    t(ratio_occurrence_gradient) %*% occurrence_fixed$covariance %*%
      ratio_occurrence_gradient +
      t(ratio_positive_gradient) %*% positive_fixed$covariance %*%
      ratio_positive_gradient
  )
  probability_difference <- second$p - first$p
  probability_gradient <-
    second$probability_gradient - first$probability_gradient
  probability_variance <- as.numeric(
    t(probability_gradient) %*% occurrence_fixed$covariance %*%
      probability_gradient
  )
  contrasts <- tibble::tribble(
    ~quantity, ~estimate, ~standard_error, ~lower_95, ~upper_95, ~unit,
    "exact-zero probability difference",
    probability_difference,
    sqrt(max(0, probability_variance)),
    probability_difference - critical * sqrt(max(0, probability_variance)),
    probability_difference + critical * sqrt(max(0, probability_variance)),
    "probability points",
    "zero-inclusive geometric-magnitude index difference",
    difference,
    sqrt(max(0, difference_variance)),
    difference - critical * sqrt(max(0, difference_variance)),
    difference + critical * sqrt(max(0, difference_variance)),
    "lx melEDI index",
    "zero-inclusive geometric-magnitude index ratio",
    ratio,
    sqrt(max(0, ratio_variance)),
    max(0, ratio - critical * sqrt(max(0, ratio_variance))),
    ratio + critical * sqrt(max(0, ratio_variance)),
    "ratio"
  ) |>
    dplyr::mutate(
      contrast = paste(second$summaries$target[[1L]], "versus", first$summaries$target[[1L]]),
      interval_type = "model-based pointwise 95% confidence interval",
      .before = 1L
    )
  list(
    estimates = dplyr::bind_rows(lapply(target_rows, `[[`, "summaries")),
    contrasts = contrasts
  )
}

h06d_l10_map_occurrence_summary <- function(
  model,
  frame,
  predictor,
  formula,
  prior_standard_deviation
) {
  fixed <- h06d_l10_fixed_estimate(model)
  term <- predictor$term[[1L]]
  grid <- h06d_l10_prediction_grid(frame, predictor)
  matrix <- h06d_l10_fixed_matrix(model, formula, grid)
  probability <- stats::plogis(as.numeric(matrix %*% fixed$estimate))
  predictions <- grid |>
    dplyr::mutate(probability_zero = probability) |>
    dplyr::summarise(
      equal_site_probability_zero = mean(.data$probability_zero),
      minimum_site_probability_zero = min(.data$probability_zero),
      maximum_site_probability_zero = max(.data$probability_zero),
      .by = c("target_index", "target")
    )
  coefficient <- tibble::tibble(
    prior_standard_deviation = prior_standard_deviation,
    prior = sprintf("normal(0,%s)", prior_standard_deviation),
    prior_class = "fixef",
    prior_coefficients =
      "(Intercept) explicitly and all remaining conditional fixed effects",
    predictor_term = term,
    map_log_odds_coefficient = unname(fixed$estimate[[term]]),
    map_odds_ratio = exp(unname(fixed$estimate[[term]])),
    inferential_role = paste0(
      "regularized fixed-site occurrence diagnostic sensitivity; no ordinary ",
      "Wald, likelihood-ratio, or BH inference"
    )
  )
  list(coefficient = coefficient, predictions = predictions)
}

h06d_l10_deletion_refit_positive <- function(
  frame,
  predictor,
  deletion_level,
  deletion_value,
  full_link_estimate,
  full_link_standard_error
) {
  retained <- if (deletion_level == "participant") {
    dplyr::filter(frame, as.character(.data$participant_key) != deletion_value)
  } else {
    dplyr::filter(frame, as.character(.data$site) != deletion_value)
  }
  retained <- retained |>
    dplyr::mutate(
      site = droplevels(.data$site),
      participant_key = droplevels(.data$participant_key),
      work_free_day = droplevels(.data$work_free_day),
      activity_status = droplevels(.data$activity_status)
    ) |>
    h06d_l10_set_factor_contrasts()
  formula <- h06d_l10_formula_set(predictor$column[[1L]])$fixed_site_additive
  fit <- h06d_l10_fit_positive_gaussian(retained, formula, REML = TRUE)
  effect <- if (is.null(fit$value)) {
    NULL
  } else {
    tryCatch(
      h06d_l10_effect_row(
        fit$value,
        predictor,
        "positive_magnitude",
        "Gaussian deletion refit"
      ),
      error = function(condition) NULL
    )
  }
  estimate <- if (is.null(effect)) NA_real_ else effect$link_estimate
  status <- h06d_l10_model_status(fit$value)
  tibble::tibble(
    deletion_level = deletion_level,
    deletion_value = deletion_value,
    retained_rows = nrow(retained),
    converged = status$converged,
    link_estimate = estimate,
    absolute_shift_in_full_se = abs(estimate - full_link_estimate) /
      full_link_standard_error,
    direction_reversal = is.finite(estimate) &&
      sign(estimate) != sign(full_link_estimate),
    elapsed_seconds = fit$elapsed_seconds,
    warning_count = length(fit$warnings),
    fit_error = fit$error
  )
}
