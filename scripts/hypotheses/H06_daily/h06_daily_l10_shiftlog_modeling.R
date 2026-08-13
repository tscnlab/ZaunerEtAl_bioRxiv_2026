# H06_daily L10 shifted-log fitting, diagnostics, and pointwise summaries.

h06d_shiftlog_capture <- function(expression) {
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
    error = if (inherits(value, "error")) conditionMessage(value) else
      NA_character_,
    warnings = unique(warnings),
    elapsed_seconds = elapsed
  )
}

h06d_shiftlog_fit_gaussian <- function(frame, formula, reml) {
  h06d_shiftlog_capture(lme4::lmer(
    formula = formula,
    data = frame,
    REML = reml,
    control = lme4::lmerControl(
      optimizer = "nloptwrap",
      calc.derivs = TRUE,
      optCtrl = list(maxeval = 10000L)
    )
  ))
}

h06d_shiftlog_fit_student_t <- function(frame, formula) {
  h06d_shiftlog_capture(glmmTMB::glmmTMB(
    formula = formula,
    data = frame,
    family = glmmTMB::t_family(link = "identity"),
    REML = TRUE,
    control = glmmTMB::glmmTMBControl(
      optCtrl = list(iter.max = 10000L, eval.max = 10000L)
    )
  ))
}

h06d_shiftlog_fit_glmmtmb_gaussian <- function(frame, formula) {
  h06d_shiftlog_capture(glmmTMB::glmmTMB(
    formula = formula,
    data = frame,
    family = stats::gaussian(link = "identity"),
    REML = TRUE,
    control = glmmTMB::glmmTMBControl(
      optCtrl = list(iter.max = 10000L, eval.max = 10000L)
    )
  ))
}

h06d_shiftlog_glmmtmb_singularity <- function(model, tolerance = 1e-4) {
  covariance_blocks <- glmmTMB::VarCorr(model)$cond
  block_checks <- lapply(covariance_blocks, function(block) {
    standard_deviations <- as.numeric(attr(block, "stddev"))
    covariance <- as.matrix(block)
    eigenvalues <- tryCatch(
      eigen(covariance, symmetric = TRUE, only.values = TRUE)$values,
      error = function(condition) NA_real_
    )
    maximum_eigenvalue <- if (all(is.finite(eigenvalues))) {
      max(eigenvalues)
    } else {
      NA_real_
    }
    minimum_scaled_eigenvalue <- if (
      is.finite(maximum_eigenvalue) && maximum_eigenvalue > 0
    ) {
      min(eigenvalues) / maximum_eigenvalue
    } else {
      NA_real_
    }
    list(
      minimum_standard_deviation = if (length(standard_deviations)) {
        min(standard_deviations)
      } else {
        NA_real_
      },
      minimum_scaled_eigenvalue = minimum_scaled_eigenvalue,
      acceptable = length(standard_deviations) > 0L &&
        all(is.finite(standard_deviations)) &&
        all(standard_deviations > tolerance) &&
        all(is.finite(eigenvalues)) &&
        is.finite(maximum_eigenvalue) &&
        maximum_eigenvalue > 0 &&
        is.finite(minimum_scaled_eigenvalue) &&
        minimum_scaled_eigenvalue > tolerance
    )
  })
  minimum_standard_deviation <- min(vapply(
    block_checks,
    `[[`,
    numeric(1),
    "minimum_standard_deviation"
  ))
  minimum_scaled_eigenvalue <- min(vapply(
    block_checks,
    `[[`,
    numeric(1),
    "minimum_scaled_eigenvalue"
  ))
  list(
    singular = !all(vapply(block_checks, `[[`, logical(1), "acceptable")),
    minimum_standard_deviation = minimum_standard_deviation,
    minimum_scaled_eigenvalue = minimum_scaled_eigenvalue
  )
}

h06d_shiftlog_model_status <- function(model) {
  if (is.null(model)) {
    return(tibble::tibble(
      converged = FALSE,
      positive_definite_hessian = FALSE,
      singular = NA,
      singularity_method = NA_character_,
      minimum_random_effect_standard_deviation = NA_real_,
      minimum_scaled_covariance_eigenvalue = NA_real_,
      maximum_absolute_gradient = NA_real_,
      convergence_message = "fit failed"
    ))
  }
  if (inherits(model, "merMod")) {
    messages <- unlist(model@optinfo$conv$lme4$messages, use.names = FALSE)
    gradient <- model@optinfo$derivs$gradient
    maximum_gradient <- if (is.null(gradient)) 0 else max(abs(gradient))
    hessian <- model@optinfo$derivs$Hessian
    positive_definite <- if (is.null(hessian)) {
      NA
    } else {
      all(eigen(hessian, symmetric = TRUE, only.values = TRUE)$values > -1e-8)
    }
    return(tibble::tibble(
      converged = length(messages) == 0L && maximum_gradient <= 0.002,
      positive_definite_hessian = positive_definite,
      singular = lme4::isSingular(model, tol = 1e-4),
      singularity_method = "lme4::isSingular(tol = 1e-4)",
      minimum_random_effect_standard_deviation = NA_real_,
      minimum_scaled_covariance_eigenvalue = NA_real_,
      maximum_absolute_gradient = maximum_gradient,
      convergence_message = if (length(messages)) {
        paste(messages, collapse = " | ")
      } else {
        "full convergence"
      }
    ))
  }
  if (inherits(model, "glmmTMB")) {
    singularity <- h06d_shiftlog_glmmtmb_singularity(model, tolerance = 1e-4)
    return(tibble::tibble(
      converged = identical(as.integer(model$fit$convergence), 0L) &&
        isTRUE(model$sdr$pdHess),
      positive_definite_hessian = isTRUE(model$sdr$pdHess),
      singular = singularity$singular,
      singularity_method = paste0(
        "finite random-effect SDs and scaled covariance eigenvalues > 1e-4; ",
        "structured-correlation boundary assessed separately"
      ),
      minimum_random_effect_standard_deviation = singularity$minimum_standard_deviation,
      minimum_scaled_covariance_eigenvalue = singularity$minimum_scaled_eigenvalue,
      maximum_absolute_gradient = NA_real_,
      convergence_message = paste(model$fit$message, collapse = " | ")
    ))
  }
  h06d_shiftlog_abort("Unknown shifted-log model class")
}

h06d_shiftlog_fixed_estimate <- function(model) {
  if (inherits(model, "merMod")) {
    estimate <- lme4::fixef(model)
    covariance <- as.matrix(stats::vcov(model))
  } else if (inherits(model, "glmmTMB")) {
    estimate <- glmmTMB::fixef(model)$cond
    covariance <- as.matrix(stats::vcov(model)$cond)
  } else {
    h06d_shiftlog_abort("Cannot extract shifted-log fixed effects")
  }
  list(estimate = estimate, covariance = covariance)
}

h06d_shiftlog_effect_row <- function(model, predictor, family_label) {
  fixed <- h06d_shiftlog_fixed_estimate(model)
  term <- predictor$term[[1L]]
  predictor_order <- predictor$predictor_order[[1L]]
  predictor_id <- predictor$predictor_id[[1L]]
  predictor_name <- predictor$reader_name[[1L]]
  contrast_label <- predictor$contrast_label[[1L]]
  h06d_shiftlog_assert(
    term %in% names(fixed$estimate),
    "Shifted-log effect term `%s` was not estimated",
    term
  )
  estimate <- unname(fixed$estimate[[term]])
  standard_error <- sqrt(fixed$covariance[term, term])
  critical <- stats::qnorm(0.975)
  lower <- estimate - critical * standard_error
  upper <- estimate + critical * standard_error
  transformed <- 10^c(estimate, lower, upper)
  tibble::tibble(
    predictor_order = predictor_order,
    predictor_id = predictor_id,
    predictor = predictor_name,
    contrast = contrast_label,
    family = family_label,
    term = term,
    link_estimate = estimate,
    link_standard_error = standard_error,
    link_lower_95 = lower,
    link_upper_95 = upper,
    shifted_geometric_mean_ratio = transformed[[1L]],
    ratio_lower_95 = transformed[[2L]],
    ratio_upper_95 = transformed[[3L]],
    effect_scale = paste0(
      "ratio for fitted geometric means of L10 mean melEDI + 0.1 lx; ",
      "not an unshifted raw-L10 ratio"
    ),
    interval_type = "model-based pointwise 95% confidence interval"
  )
}

h06d_shiftlog_lrt_row <- function(reduced, full, test_type) {
  h06d_shiftlog_assert(
    stats::nobs(reduced) == stats::nobs(full) &&
      !lme4::isREML(reduced) &&
      !lme4::isREML(full),
    "Shifted-log LRT models do not use identical rows and ML"
  )
  reduced_loglik <- stats::logLik(reduced)
  full_loglik <- stats::logLik(full)
  statistic <- max(
    0,
    2 * (as.numeric(full_loglik) - as.numeric(reduced_loglik))
  )
  degrees <- attr(full_loglik, "df") - attr(reduced_loglik, "df")
  h06d_shiftlog_assert(
    degrees > 0,
    "Shifted-log LRT has non-positive degrees of freedom"
  )
  tibble::tibble(
    test_type = test_type,
    likelihood_ratio = statistic,
    degrees_of_freedom = degrees,
    raw_p_value = stats::pchisq(statistic, degrees, lower.tail = FALSE),
    method = "maximum-likelihood likelihood-ratio test",
    multiplicity_status = "PILOT_RAW_ONLY_NO_BH_UPDATE"
  )
}

h06d_shiftlog_design_check <- function(frame, predictor, heterogeneity) {
  column <- predictor$column[[1L]]
  fixed_formula <- if (isTRUE(heterogeneity)) {
    stats::as.formula(sprintf("~ site * %s", column))
  } else {
    stats::as.formula(sprintf("~ site + %s", column))
  }
  matrix <- stats::model.matrix(fixed_formula, data = frame)
  matrix_rank <- qr(matrix)$rank
  categorical_cells_complete <- if (predictor$type[[1L]] == "categorical") {
    cells <- frame |>
      dplyr::count(
        .data$site,
        category = as.character(.data[[column]]),
        name = "participant_days"
      )
    nrow(cells) ==
      dplyr::n_distinct(cells$site) *
        dplyr::n_distinct(as.character(frame[[column]])) &&
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
    design_rank = matrix_rank,
    full_rank = matrix_rank == ncol(matrix),
    categorical_cells_complete = categorical_cells_complete,
    continuous_variation_complete = continuous_variation_complete,
    estimable = matrix_rank == ncol(matrix) &&
      categorical_cells_complete &&
      continuous_variation_complete
  )
}

h06d_shiftlog_residual_diagnostics <- function(model, frame) {
  residual <- as.numeric(stats::residuals(model))
  fitted <- as.numeric(stats::fitted(model))
  residual_scale <- stats::sd(residual)
  standardized <- residual / residual_scale
  theoretical <- stats::qnorm(stats::ppoints(length(standardized)))
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
  variance_ratio <- if (length(group_variance) >= 2L) {
    max(group_variance) / min(group_variance)
  } else {
    NA_real_
  }
  shapiro_p <- if (length(residual) >= 3L) {
    stats::shapiro.test(residual)$p.value
  } else {
    NA_real_
  }
  spread_correlation <- suppressWarnings(stats::cor(
    abs(residual),
    fitted,
    method = "spearman",
    use = "complete.obs"
  ))
  raw_fitted <- 10^fitted - h06d_shiftlog_offset_lx()
  zero_row <- frame$response_source == 0
  tail3 <- mean(abs(standardized) > 3)
  tail4 <- mean(abs(standardized) > 4)
  residual_disposition <- dplyr::case_when(
    (is.finite(variance_ratio) && variance_ratio > 10) ||
      tail4 > 0.02 ||
      (is.finite(spread_correlation) && abs(spread_correlation) >= 0.40) ~
      "NOT_ACCEPTABLE_STRONG_GAUSSIAN_MISFIT",
    (is.finite(variance_ratio) && variance_ratio > 4) ||
      tail3 > 0.02 ||
      tail4 >= 0.01 ||
      (is.finite(shapiro_p) && shapiro_p < 0.001) ||
      (is.finite(spread_correlation) && abs(spread_correlation) >= 0.20) ~
      "ACCEPTABLE_ONLY_WITH_GAUSSIAN_RESIDUAL_LIMITATION",
    TRUE ~ "ACCEPTABLE"
  )
  bound_disposition <- dplyr::case_when(
    mean(raw_fitted < -0.05) > 0.01 ~ "NOT_ACCEPTABLE_PHYSICAL_BOUND_VIOLATION",
    any(raw_fitted < 0) ~
      "ACCEPTABLE_ONLY_WITH_NEGATIVE_BACK_TRANSFORM_LIMITATION",
    TRUE ~ "ACCEPTABLE"
  )
  tibble::tibble(
    residual_qq_correlation = stats::cor(sort(standardized), theoretical),
    shapiro_p_value = shapiro_p,
    residual_variance_ratio = variance_ratio,
    absolute_residual_fitted_spearman = spread_correlation,
    standardized_residual_gt3_fraction = tail3,
    standardized_residual_gt4_fraction = tail4,
    maximum_absolute_standardized_residual = max(abs(standardized)),
    residual_skewness = mean(
      ((residual - mean(residual)) / stats::sd(residual))^3
    ),
    exact_zero_fraction = mean(zero_row),
    transformed_zero_value = -1,
    zero_row_standardized_residual_mean = mean(standardized[zero_row]),
    zero_row_standardized_residual_median = stats::median(standardized[
      zero_row
    ]),
    zero_row_maximum_absolute_standardized_residual = max(
      abs(standardized[zero_row])
    ),
    fitted_link_minimum = min(fitted),
    fitted_link_maximum = max(fitted),
    raw_back_transform_minimum_lx = min(raw_fitted),
    raw_back_transform_maximum_lx = max(raw_fitted),
    raw_back_transform_below_zero_fraction = mean(raw_fitted < 0),
    raw_back_transform_below_minus_0_05_fraction = mean(raw_fitted < -0.05),
    residual_disposition = residual_disposition,
    bound_disposition = bound_disposition,
    zero_mass_disposition = ifelse(
      mean(zero_row) >= 0.10,
      "OPEN_AUTHOR_DISPOSITION_ZERO_MASS_GE_10_PERCENT",
      "ACCEPTABLE_ZERO_MASS_BELOW_10_PERCENT"
    )
  )
}

h06d_shiftlog_zero_mass_cells <- function(frame, predictor) {
  column <- predictor$column[[1L]]
  if (predictor$type[[1L]] == "categorical") {
    output <- frame |>
      dplyr::mutate(predictor_level = as.character(.data[[column]])) |>
      dplyr::summarise(
        participant_days = dplyr::n(),
        exact_zeros = sum(.data$response_source == 0),
        exact_zero_fraction = mean(.data$response_source == 0),
        .by = c("site", "predictor_level")
      )
  } else {
    output <- frame |>
      dplyr::mutate(predictor_level = "All observed sleep durations") |>
      dplyr::summarise(
        participant_days = dplyr::n(),
        exact_zeros = sum(.data$response_source == 0),
        exact_zero_fraction = mean(.data$response_source == 0),
        predictor_mean_hours = mean(.data[[column]] + 8),
        predictor_mean_hours_zero_days = mean(
          (.data[[column]] + 8)[.data$response_source == 0]
        ),
        predictor_mean_hours_positive_days = mean(
          (.data[[column]] + 8)[.data$response_source > 0]
        ),
        .by = c("site", "predictor_level")
      )
  }
  output |>
    dplyr::mutate(
      predictor_order = predictor$predictor_order[[1L]],
      predictor_id = predictor$predictor_id[[1L]],
      .before = 1L
    )
}

h06d_shiftlog_lag_screen <- function(frame, residual) {
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
  list(
    overall = tibble::tibble(
      adjacent_pairs = nrow(pairs),
      participants = dplyr::n_distinct(pairs$participant_key),
      residual_lag1 = pooled,
      maximum_absolute_site_lag1 = maximum_site,
      ar_trigger = (is.finite(pooled) && abs(pooled) >= 0.20) ||
        (is.finite(maximum_site) && maximum_site >= 0.30),
      ar_support_adequate = nrow(pairs) >= 100L &&
        dplyr::n_distinct(pairs$participant_key) >= 20L
    ),
    by_site = by_site,
    pairs = pairs
  )
}

h06d_shiftlog_add_day_sequences <- function(frame) {
  output <- frame |>
    dplyr::arrange(.data$participant_key, .data$local_date) |>
    dplyr::group_by(.data$participant_key) |>
    dplyr::mutate(
      date_gap = as.integer(.data$local_date - dplyr::lag(.data$local_date)),
      sequence_start = dplyr::row_number() == 1L |
        is.na(.data$date_gap) |
        .data$date_gap != 1L,
      sequence_number = cumsum(.data$sequence_start)
    ) |>
    dplyr::ungroup() |>
    dplyr::group_by(.data$participant_key, .data$sequence_number) |>
    dplyr::mutate(day_index = dplyr::row_number()) |>
    dplyr::ungroup() |>
    dplyr::mutate(
      day_sequence_id = interaction(
        .data$participant_key,
        .data$sequence_number,
        drop = TRUE,
        lex.order = TRUE
      ),
      day_index_factor = factor(
        .data$day_index,
        levels = seq_len(max(.data$day_index))
      )
    )
  h06d_shiftlog_assert(
    all(output$date_gap[!output$sequence_start] == 1L),
    "Shifted-log AR sequence crosses a missing calendar date"
  )
  output
}

h06d_shiftlog_fit_ar <- function(frame, formula) {
  ar_frame <- h06d_shiftlog_add_day_sequences(frame)
  capture <- h06d_shiftlog_fit_glmmtmb_gaussian(ar_frame, formula)
  capture$frame <- ar_frame
  capture
}

h06d_shiftlog_ar_parameters <- function(model) {
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

h06d_shiftlog_family_sensitivity <- function(
  gaussian_effect,
  student_t_effect,
  student_t_status
) {
  shift <- abs(
    student_t_effect$link_estimate - gaussian_effect$link_estimate
  ) /
    gaussian_effect$link_standard_error
  direction_reversal <- sign(student_t_effect$link_estimate) !=
    sign(gaussian_effect$link_estimate)
  disposition <- dplyr::case_when(
    !isTRUE(student_t_status$converged) ||
      !isTRUE(student_t_status$positive_definite_hessian) ~
      "SENSITIVITY_UNRESOLVED_STUDENT_T_NUMERICAL_FAILURE",
    shift > 2 ~ "NOT_ACCEPTABLE_FAMILY_SENSITIVITY_GT_2_SE",
    direction_reversal || shift >= 1 ~
      "ACCEPTABLE_ONLY_WITH_MAJOR_FAMILY_SENSITIVITY_LIMITATION",
    shift >= 0.5 ~ "ACCEPTABLE_ONLY_WITH_FAMILY_SENSITIVITY_LIMITATION",
    TRUE ~ "ACCEPTABLE"
  )
  tibble::tibble(
    gaussian_link_estimate = gaussian_effect$link_estimate,
    gaussian_link_standard_error = gaussian_effect$link_standard_error,
    student_t_link_estimate = student_t_effect$link_estimate,
    effect_shift_in_gaussian_se = shift,
    direction_reversal = direction_reversal,
    family_sensitivity_disposition = disposition
  )
}

h06d_shiftlog_prediction_grid <- function(frame, predictor) {
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

h06d_shiftlog_equal_site_predictions <- function(model, frame, predictor) {
  formula <- h06d_shiftlog_formula_set(
    predictor$column[[1L]]
  )$fixed_site_additive
  grid <- h06d_shiftlog_prediction_grid(frame, predictor)
  fixed <- h06d_shiftlog_fixed_estimate(model)
  matrix <- stats::model.matrix(
    stats::delete.response(stats::terms(reformulas::nobars(formula))),
    data = grid
  )
  missing <- setdiff(names(fixed$estimate), colnames(matrix))
  h06d_shiftlog_assert(
    length(missing) == 0L,
    "Equal-site shifted-log grid omits fixed terms: %s",
    paste(missing, collapse = ", ")
  )
  matrix <- matrix[, names(fixed$estimate), drop = FALSE]
  eta <- as.numeric(matrix %*% fixed$estimate)
  shifted_fitted <- 10^eta
  raw_fitted <- shifted_fitted - h06d_shiftlog_offset_lx()
  critical <- stats::qnorm(0.975)
  grid_rows <- lapply(sort(unique(grid$target_index)), function(target_index) {
    selected <- grid$target_index == target_index
    target_matrix <- matrix[selected, , drop = FALSE]
    target_shifted <- shifted_fitted[selected]
    target_raw <- raw_fitted[selected]
    raw_estimate <- mean(target_raw)
    raw_gradient <- colMeans(
      target_matrix * as.numeric(log(10) * target_shifted)
    )
    raw_variance <- as.numeric(
      t(raw_gradient) %*% fixed$covariance %*% raw_gradient
    )
    raw_standard_error <- sqrt(max(0, raw_variance))
    target <- unique(grid$target[selected])
    list(
      summary = tibble::tibble(
        target_index = target_index,
        target = target,
        equal_site_raw_back_transform_lx = raw_estimate,
        raw_back_transform_standard_error_lx = raw_standard_error,
        raw_back_transform_lower_95_lx = raw_estimate -
          critical * raw_standard_error,
        raw_back_transform_upper_95_lx = raw_estimate +
          critical * raw_standard_error,
        negative_point_back_transform = raw_estimate < 0,
        interval_type = "model-based pointwise 95% confidence interval",
        clipping_rule = "unclipped 10^eta - 0.1 lx"
      ),
      raw_estimate = raw_estimate,
      raw_gradient = raw_gradient
    )
  })
  first <- grid_rows[[1L]]
  second <- grid_rows[[2L]]
  difference <- second$raw_estimate - first$raw_estimate
  difference_gradient <- second$raw_gradient - first$raw_gradient
  difference_variance <- as.numeric(
    t(difference_gradient) %*% fixed$covariance %*% difference_gradient
  )
  difference_standard_error <- sqrt(max(0, difference_variance))
  list(
    estimates = dplyr::bind_rows(lapply(grid_rows, `[[`, "summary")),
    contrast = tibble::tibble(
      contrast = paste(
        second$summary$target[[1L]],
        "versus",
        first$summary$target[[1L]]
      ),
      equal_site_raw_back_transform_difference_lx = difference,
      difference_standard_error_lx = difference_standard_error,
      difference_lower_95_lx = difference -
        critical * difference_standard_error,
      difference_upper_95_lx = difference +
        critical * difference_standard_error,
      interval_type = "model-based pointwise 95% confidence interval",
      clipping_rule = "unclipped 10^eta - 0.1 lx"
    ),
    site_grid = grid |>
      dplyr::mutate(
        link_fitted = eta,
        shifted_fitted_lx = shifted_fitted,
        raw_back_transform_lx = raw_fitted,
        clipping_rule = "unclipped 10^eta - 0.1 lx"
      )
  )
}

h06d_shiftlog_registered_status <- function(model, capture) {
  status <- h06d_shiftlog_model_status(model)
  maximum_correlation <- NA_real_
  if (!is.null(model)) {
    variance <- lme4::VarCorr(model)$site
    correlation <- attr(variance, "correlation")
    if (!is.null(correlation) && nrow(correlation) > 1L) {
      maximum_correlation <- max(
        abs(correlation[upper.tri(correlation)]),
        na.rm = TRUE
      )
    }
  }
  disposition <- if (
    is.null(model) ||
      !isTRUE(status$converged) ||
      isTRUE(status$singular) ||
      (is.finite(maximum_correlation) && maximum_correlation >= 0.98)
  ) {
    "NON_ESTIMABLE_BENCHMARK"
  } else {
    "ESTIMABLE_BENCHMARK_ONLY"
  }
  dplyr::bind_cols(
    status,
    tibble::tibble(
      warning_count = length(capture$warnings),
      warnings = paste(capture$warnings, collapse = " | "),
      fit_error = capture$error,
      maximum_absolute_random_site_correlation = maximum_correlation,
      disposition = disposition,
      inferential_role = paste0(
        "exact registered random-site/random-slope benchmark; never promoted ",
        "to the fixed-site primary"
      )
    )
  )
}
