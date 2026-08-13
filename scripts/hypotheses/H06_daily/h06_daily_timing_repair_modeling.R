# Model and diagnostic helpers for H06-D-G2P-TIMING-REPAIR.

h06d_tr_capture <- function(expression) {
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
    error = if (inherits(value, "error")) conditionMessage(value) else
      NA_character_,
    warnings = unique(warnings),
    elapsed_seconds = unname(proc.time()[["elapsed"]] - started)
  )
}

h06d_tr_add_day_sequences <- function(frame) {
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
  h06d_tr_assert(
    !anyDuplicated(output[c("participant_key", "local_date")]),
    "A timing-repair AR frame contains duplicate participant-dates"
  )
  h06d_tr_assert(
    all(output$date_gap[!output$sequence_start] == 1L),
    "A timing-repair AR sequence crosses a missing calendar date"
  )
  output
}

h06d_tr_lag_screen <- function(frame, residual) {
  h06d_tr_assert(
    length(residual) == nrow(frame),
    "Residual vector and daily frame differ in length"
  )
  pairs <- frame |>
    dplyr::mutate(.residual = as.numeric(residual)) |>
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
  finite_site <- by_site$residual_lag1[is.finite(by_site$residual_lag1)]
  overall <- tibble::tibble(
    adjacent_pairs = nrow(pairs),
    participants_with_adjacent_pair =
      dplyr::n_distinct(pairs$participant_key),
    residual_lag1 = if (nrow(pairs) >= 3L) {
      stats::cor(pairs$.residual, pairs$previous_residual)
    } else {
      NA_real_
    },
    maximum_absolute_site_lag1 = if (length(finite_site)) {
      max(abs(finite_site))
    } else {
      NA_real_
    },
    temporal_threshold_pass = nrow(pairs) >= 3L &&
      abs(stats::cor(pairs$.residual, pairs$previous_residual)) < 0.20 &&
      length(finite_site) > 0L && all(abs(finite_site) < 0.30)
  )
  list(overall = overall, by_site = by_site, pairs = pairs)
}

h06d_tr_fit_lm <- function(frame, formula) {
  h06d_tr_capture(stats::lm(
    formula = formula,
    data = frame,
    model = TRUE,
    x = TRUE,
    y = TRUE,
    qr = TRUE
  ))
}

h06d_tr_hc3 <- function(model) {
  h06d_tr_capture(sandwich::vcovCL(
    model,
    cluster = ~ participant_key,
    type = "HC3",
    cadjust = TRUE,
    fix = FALSE
  ))
}

h06d_tr_matrix_status <- function(matrix, tolerance = 1e-10) {
  if (is.null(matrix) || !is.matrix(matrix) || nrow(matrix) != ncol(matrix)) {
    return(tibble::tibble(
      matrix_dimension = NA_integer_,
      finite = FALSE,
      symmetric = FALSE,
      maximum_asymmetry = NA_real_,
      positive_semidefinite = FALSE,
      minimum_eigenvalue = NA_real_,
      maximum_eigenvalue = NA_real_,
      numerical_rank = NA_integer_,
      full_rank = FALSE
    ))
  }
  finite <- all(is.finite(matrix))
  maximum_asymmetry <- if (finite) max(abs(matrix - t(matrix))) else NA_real_
  symmetric <- finite && maximum_asymmetry <= tolerance
  eigenvalues <- if (symmetric) {
    eigen((matrix + t(matrix)) / 2, symmetric = TRUE, only.values = TRUE)$values
  } else {
    rep(NA_real_, nrow(matrix))
  }
  maximum_eigenvalue <- if (all(is.finite(eigenvalues))) {
    max(eigenvalues)
  } else {
    NA_real_
  }
  minimum_eigenvalue <- if (all(is.finite(eigenvalues))) {
    min(eigenvalues)
  } else {
    NA_real_
  }
  scale <- if (is.finite(maximum_eigenvalue)) {
    max(1, abs(maximum_eigenvalue))
  } else {
    NA_real_
  }
  psd_tolerance <- sqrt(.Machine$double.eps) * scale
  positive_semidefinite <- all(is.finite(eigenvalues)) &&
    minimum_eigenvalue >= -psd_tolerance
  rank_tolerance <- if (is.finite(maximum_eigenvalue)) {
    max(dim(matrix)) * .Machine$double.eps * max(1, maximum_eigenvalue)
  } else {
    NA_real_
  }
  numerical_rank <- if (all(is.finite(eigenvalues))) {
    sum(eigenvalues > rank_tolerance)
  } else {
    NA_integer_
  }
  tibble::tibble(
    matrix_dimension = nrow(matrix),
    finite = finite,
    symmetric = symmetric,
    maximum_asymmetry = maximum_asymmetry,
    positive_semidefinite = positive_semidefinite,
    minimum_eigenvalue = minimum_eigenvalue,
    maximum_eigenvalue = maximum_eigenvalue,
    numerical_rank = numerical_rank,
    full_rank = isTRUE(numerical_rank == nrow(matrix))
  )
}

h06d_tr_lm_status <- function(model) {
  if (is.null(model)) {
    return(tibble::tibble(
      coefficients = NA_integer_,
      design_rank = NA_integer_,
      design_full_rank = FALSE,
      finite_coefficients = FALSE,
      finite_standard_errors = FALSE,
      residual_degrees_of_freedom = NA_integer_
    ))
  }
  coefficient_values <- stats::coef(model)
  standard_errors <- sqrt(diag(stats::vcov(model)))
  tibble::tibble(
    coefficients = length(coefficient_values),
    design_rank = model$rank,
    design_full_rank = model$rank == length(coefficient_values),
    finite_coefficients = all(is.finite(coefficient_values)),
    finite_standard_errors = all(is.finite(standard_errors)),
    residual_degrees_of_freedom = stats::df.residual(model)
  )
}

h06d_tr_leverage <- function(model, frame) {
  leverage <- as.numeric(stats::hatvalues(model))
  cluster <- as.character(frame$participant_key)
  h06d_tr_assert(
    length(leverage) == length(cluster),
    "LM leverage and participant clusters differ in length"
  )
  cluster_sum <- tapply(leverage, cluster, sum)
  cluster_size <- table(cluster)
  maximum_cluster <- names(which.max(cluster_sum))
  tibble::tibble(
    observations = length(leverage),
    participant_clusters = length(cluster_sum),
    maximum_observation_hat = max(leverage),
    mean_observation_hat = mean(leverage),
    maximum_cluster_hat_sum = unname(max(cluster_sum)),
    maximum_cluster_hat_share = unname(max(cluster_sum) / sum(cluster_sum)),
    maximum_cluster_hat_ratio_to_median = unname(
      max(cluster_sum) / stats::median(cluster_sum)
    ),
    maximum_cluster_id = maximum_cluster,
    maximum_cluster_days = unname(cluster_size[[maximum_cluster]]),
    hc3_leverage_numerically_usable = all(is.finite(leverage)) &&
      max(leverage) < 0.99
  )
}

h06d_tr_residual_diagnostics <- function(model, frame) {
  residual <- as.numeric(stats::residuals(model))
  fitted <- as.numeric(stats::fitted(model))
  standardized <- residual / stats::sd(residual)
  theoretical <- stats::qnorm(stats::ppoints(length(standardized)))
  lag <- h06d_tr_lag_screen(frame, residual)
  list(
    overall = tibble::tibble(
      residual_qq_correlation = stats::cor(sort(standardized), theoretical),
      absolute_residual_fitted_spearman = abs(suppressWarnings(stats::cor(
        abs(residual),
        fitted,
        method = "spearman",
        use = "complete.obs"
      ))),
      standardized_residual_gt4_fraction = mean(abs(standardized) > 4),
      fitted_minimum = min(fitted),
      fitted_maximum = max(fitted),
      residual_lag1 = lag$overall$residual_lag1,
      maximum_absolute_site_lag1 = lag$overall$maximum_absolute_site_lag1,
      adjacent_pairs = lag$overall$adjacent_pairs,
      participants_with_adjacent_pair =
        lag$overall$participants_with_adjacent_pair
    ),
    by_site = lag$by_site
  )
}

h06d_tr_interaction_terms <- function(model, predictor_column) {
  names <- names(stats::coef(model))
  names[
    grepl(":", names, fixed = TRUE) &
      grepl("site", names, fixed = TRUE) &
      grepl(predictor_column, names, fixed = TRUE)
  ]
}

h06d_tr_wald_test <- function(
  model,
  covariance,
  terms,
  clusters,
  test_id
) {
  coefficients <- stats::coef(model)
  missing_terms <- setdiff(terms, names(coefficients))
  if (length(terms) == 0L || length(missing_terms) > 0L) {
    return(tibble::tibble(
      test_id = test_id,
      tested_terms = paste(terms, collapse = " | "),
      numerator_degrees_of_freedom = length(terms),
      denominator_degrees_of_freedom = clusters - 1L,
      wald_chisq = NA_real_,
      f_statistic = NA_real_,
      raw_p_value = NA_real_,
      adjusted_p_value = NA_real_,
      block_covariance_rank = NA_integer_,
      test_status = "NON_ESTIMABLE_TERM_MISMATCH",
      multiplicity_status = "PILOT_RAW_ONLY_NO_BH_UPDATE"
    ))
  }
  selected <- match(terms, names(coefficients))
  beta <- unname(coefficients[selected])
  block <- covariance[selected, selected, drop = FALSE]
  status <- h06d_tr_matrix_status(block)
  q <- length(beta)
  valid <- all(is.finite(beta)) && isTRUE(status$finite) &&
    isTRUE(status$symmetric) && isTRUE(status$positive_semidefinite) &&
    isTRUE(status$full_rank) && clusters > q
  statistic <- if (valid) {
    as.numeric(crossprod(beta, solve(block, beta)))
  } else {
    NA_real_
  }
  f_statistic <- if (valid) statistic / q else NA_real_
  tibble::tibble(
    test_id = test_id,
    tested_terms = paste(terms, collapse = " | "),
    numerator_degrees_of_freedom = q,
    denominator_degrees_of_freedom = clusters - 1L,
    wald_chisq = statistic,
    f_statistic = f_statistic,
    raw_p_value = if (valid) {
      stats::pf(f_statistic, q, clusters - 1L, lower.tail = FALSE)
    } else {
      NA_real_
    },
    adjusted_p_value = NA_real_,
    block_covariance_rank = status$numerical_rank,
    test_status = if (valid) "PILOT_RAW_ONLY_NO_BH_UPDATE" else
      "NON_ESTIMABLE_ROBUST_WALD",
    multiplicity_status = "PILOT_RAW_ONLY_NO_BH_UPDATE"
  )
}

h06d_tr_effect <- function(
  model,
  covariance,
  predictor,
  clusters,
  model_id = "hc3_additive"
) {
  term <- predictor$term[[1L]]
  coefficients <- stats::coef(model)
  index <- match(term, names(coefficients))
  h06d_tr_assert(!is.na(index), "Predictor term `%s` is missing", term)
  estimate <- unname(coefficients[[index]])
  standard_error <- sqrt(covariance[index, index])
  critical <- stats::qt(0.975, df = clusters - 1L)
  tibble::tibble(
    model_id = model_id,
    term = term,
    estimate_hours = estimate,
    standard_error_hours = standard_error,
    lower_95_hours = estimate - critical * standard_error,
    upper_95_hours = estimate + critical * standard_error,
    confidence_reference = sprintf(
      "t(%d), participant clusters minus one",
      clusters - 1L
    ),
    interval_type = "participant-cluster HC3 pointwise 95% confidence interval"
  )
}

h06d_tr_equal_site_marginals <- function(
  model,
  covariance,
  frame,
  predictor,
  metric,
  clusters
) {
  column <- predictor$column[[1L]]
  sites <- levels(frame$site)
  values <- if (predictor$type[[1L]] == "categorical") {
    levels(frame[[column]])
  } else {
    c(0, 1)
  }
  labels <- if (predictor$type[[1L]] == "categorical") {
    as.character(values)
  } else {
    c("8 h", "9 h")
  }
  rows <- lapply(seq_along(values), function(index) {
    newdata <- data.frame(site = factor(sites, levels = sites))
    if (predictor$type[[1L]] == "categorical") {
      newdata[[column]] <- factor(
        rep(values[[index]], length(sites)),
        levels = levels(frame[[column]])
      )
    } else {
      newdata[[column]] <- rep(values[[index]], length(sites))
    }
    design <- stats::model.matrix(
      stats::delete.response(stats::terms(model)),
      data = newdata,
      contrasts.arg = model$contrasts
    )
    average <- colMeans(design)
    estimate <- as.numeric(crossprod(average, stats::coef(model)))
    standard_error <- sqrt(as.numeric(crossprod(
      average,
      covariance %*% average
    )))
    critical <- stats::qt(0.975, df = clusters - 1L)
    tibble::tibble(
      level = labels[[index]],
      estimate_unwrapped_hour = estimate,
      standard_error_hour = standard_error,
      lower_95_unwrapped_hour = estimate - critical * standard_error,
      upper_95_unwrapped_hour = estimate + critical * standard_error,
      estimate_clock_hour = estimate %% 24,
      lower_95_clock_hour = (estimate - critical * standard_error) %% 24,
      upper_95_clock_hour = (estimate + critical * standard_error) %% 24
    )
  })
  dplyr::bind_rows(rows) |>
    dplyr::mutate(
      metric_id = metric$metric_id[[1L]],
      predictor_id = predictor$predictor_id[[1L]],
      marginalization = "equal submitted-site weights",
      interval_type = "participant-cluster HC3 pointwise 95% confidence interval",
      .before = 1L
    )
}

h06d_tr_fit_student_t <- function(frame, formula) {
  h06d_tr_capture(glmmTMB::glmmTMB(
    formula = formula,
    data = frame,
    family = glmmTMB::t_family(link = "identity"),
    REML = FALSE,
    control = glmmTMB::glmmTMBControl(
      optCtrl = list(iter.max = 10000L, eval.max = 10000L)
    )
  ))
}

h06d_tr_glmmtmb_status <- function(model, capture = NULL) {
  if (is.null(model)) {
    return(tibble::tibble(
      converged = FALSE,
      positive_definite_hessian = FALSE,
      finite_fixed_effects = FALSE,
      finite_standard_errors = FALSE,
      warning_count = length(capture$warnings %||% character()),
      warnings = paste(capture$warnings %||% character(), collapse = " | "),
      error = capture$error %||% "fit failed",
      convergence_message = "fit failed"
    ))
  }
  coefficients <- glmmTMB::fixef(model)$cond
  covariance <- tryCatch(
    as.matrix(stats::vcov(model)$cond),
    error = function(condition) matrix(NA_real_, 0L, 0L)
  )
  tibble::tibble(
    converged = identical(as.integer(model$fit$convergence), 0L) &&
      isTRUE(model$sdr$pdHess),
    positive_definite_hessian = isTRUE(model$sdr$pdHess),
    finite_fixed_effects = length(coefficients) > 0L &&
      all(is.finite(coefficients)),
    finite_standard_errors = length(covariance) > 0L &&
      all(is.finite(sqrt(diag(covariance)))),
    warning_count = length(capture$warnings %||% character()),
    warnings = paste(capture$warnings %||% character(), collapse = " | "),
    error = capture$error %||% NA_character_,
    convergence_message = paste(model$fit$message, collapse = " | ")
  )
}

h06d_tr_fit_no_nugget_ar <- function(frame, formula) {
  zero_dispersion_value <- log(.Machine$double.eps) / 4
  h06d_tr_capture(glmmTMB::glmmTMB(
    formula = formula,
    dispformula = ~0,
    data = frame,
    family = stats::gaussian(link = "identity"),
    REML = TRUE,
    control = glmmTMB::glmmTMBControl(
      zerodisp_val = zero_dispersion_value,
      optCtrl = list(iter.max = 10000L, eval.max = 10000L)
    )
  ))
}

h06d_tr_covariance_rank <- function(model, tolerance = 1e-4) {
  if (is.null(model)) {
    return(tibble::tibble(
      covariance_blocks = NA_integer_,
      minimum_standard_deviation = NA_real_,
      minimum_scaled_eigenvalue = NA_real_,
      covariance_full_rank = FALSE,
      singular = NA
    ))
  }
  blocks <- glmmTMB::VarCorr(model)$cond
  checks <- lapply(blocks, function(block) {
    covariance <- as.matrix(block)
    standard_deviation <- as.numeric(attr(block, "stddev"))
    eigenvalues <- eigen(
      covariance,
      symmetric = TRUE,
      only.values = TRUE
    )$values
    maximum <- max(eigenvalues)
    tibble::tibble(
      minimum_standard_deviation = min(standard_deviation),
      minimum_scaled_eigenvalue = if (maximum > 0) {
        min(eigenvalues) / maximum
      } else {
        NA_real_
      },
      acceptable = all(is.finite(standard_deviation)) &&
        all(standard_deviation > tolerance) &&
        all(is.finite(eigenvalues)) && maximum > 0 &&
        min(eigenvalues) / maximum > tolerance
    )
  })
  checks <- dplyr::bind_rows(checks)
  tibble::tibble(
    covariance_blocks = nrow(checks),
    minimum_standard_deviation = min(checks$minimum_standard_deviation),
    minimum_scaled_eigenvalue = min(checks$minimum_scaled_eigenvalue),
    covariance_full_rank = all(checks$acceptable),
    singular = tryCatch(
      as.logical(performance::check_singularity(model)),
      error = function(condition) NA
    )
  )
}

h06d_tr_ar_parameters <- function(model) {
  if (is.null(model)) {
    return(tibble::tibble(
      ar_standard_deviation = NA_real_,
      ar_rho = NA_real_,
      participant_standard_deviation = NA_real_,
      residual_standard_deviation = NA_real_,
      no_nugget_verified = FALSE
    ))
  }
  covariance <- glmmTMB::VarCorr(model)$cond
  ar <- covariance$day_sequence_id
  participant <- covariance$participant_key
  correlation <- attr(ar, "correlation")
  expected_sigma <- exp(log(.Machine$double.eps) / 4)
  expected_dispersion_value <- log(.Machine$double.eps) / 4
  dispersion_formula <- model$modelInfo$allForm$dispformula
  dispersion_value <- unname(glmmTMB::fixef(model)$disp)
  no_nugget <- identical(
    h06d_tr_normalize_formula(dispersion_formula),
    "~0"
  ) && length(dispersion_value) == 1L &&
    isTRUE(all.equal(
      dispersion_value,
      expected_dispersion_value,
      tolerance = 1e-12
    )) &&
    isTRUE(all.equal(stats::sigma(model), expected_sigma, tolerance = 1e-12))
  tibble::tibble(
    ar_standard_deviation = unname(attr(ar, "stddev")[[1L]]),
    ar_rho = if (!is.null(correlation) && nrow(correlation) >= 2L) {
      unname(correlation[[1L, 2L]])
    } else {
      NA_real_
    },
    participant_standard_deviation =
      unname(attr(participant, "stddev")[[1L]]),
    residual_standard_deviation = stats::sigma(model),
    no_nugget_verified = no_nugget
  )
}

h06d_tr_fixed_coefficients <- function(model) {
  if (inherits(model, "lm")) {
    return(stats::coef(model))
  }
  if (inherits(model, "glmmTMB")) {
    return(glmmTMB::fixef(model)$cond)
  }
  h06d_tr_abort("Unsupported model class for fixed coefficients")
}

h06d_tr_shift_summary <- function(
  candidate_model,
  candidate_covariance,
  sensitivity_model,
  terms,
  component
) {
  if (is.null(sensitivity_model) || length(terms) == 0L) {
    return(tibble::tibble(
      component = component,
      terms_compared = paste(terms, collapse = " | "),
      terms_available = 0L,
      candidate_estimates = NA_character_,
      sensitivity_estimates = NA_character_,
      maximum_shift_in_hc3_se = NA_real_,
      direction_reversal = NA,
      sensitivity_classification = "UNRESOLVED_NUMERICAL_FAILURE"
    ))
  }
  candidate <- h06d_tr_fixed_coefficients(candidate_model)
  sensitivity <- h06d_tr_fixed_coefficients(sensitivity_model)
  common <- intersect(terms, intersect(names(candidate), names(sensitivity)))
  if (length(common) != length(terms)) {
    return(tibble::tibble(
      component = component,
      terms_compared = paste(terms, collapse = " | "),
      terms_available = length(common),
      candidate_estimates = NA_character_,
      sensitivity_estimates = NA_character_,
      maximum_shift_in_hc3_se = NA_real_,
      direction_reversal = NA,
      sensitivity_classification = "UNRESOLVED_TERM_MISMATCH"
    ))
  }
  index <- match(common, names(candidate))
  standard_error <- sqrt(diag(candidate_covariance))[index]
  shift <- abs(sensitivity[common] - candidate[common]) / standard_error
  reversal <- sign(sensitivity[common]) != sign(candidate[common])
  maximum_shift <- max(shift)
  classification <- dplyr::case_when(
    any(reversal) || maximum_shift >= 2 ~ "UNSTABLE",
    maximum_shift >= 1 ~ "SUBSTANTIAL_LIMITATION",
    TRUE ~ "STABLE"
  )
  tibble::tibble(
    component = component,
    terms_compared = paste(common, collapse = " | "),
    terms_available = length(common),
    candidate_estimates = paste(
      sprintf("%s=%.12g", common, candidate[common]),
      collapse = " | "
    ),
    sensitivity_estimates = paste(
      sprintf("%s=%.12g", common, sensitivity[common]),
      collapse = " | "
    ),
    maximum_shift_in_hc3_se = maximum_shift,
    direction_reversal = any(reversal),
    sensitivity_classification = classification
  )
}

h06d_tr_clock_support <- function(frame, metric) {
  hours <- frame$response_source / 60
  transformed <- frame$response_value
  central <- unname(stats::quantile(
    transformed,
    probs = c(0.025, 0.975),
    names = FALSE,
    type = 8
  ))
  sorted_hours <- sort(hours %% 24)
  keep <- max(2L, ceiling(0.95 * length(sorted_hours)))
  extended <- c(sorted_hours, sorted_hours + 24)
  starts <- seq_along(sorted_hours)
  spans <- extended[starts + keep - 1L] - extended[starts]
  circular_arc <- min(spans)
  ordinary_boundary_split <-
    metric$response_transform[[1L]] == "clock_hours" &&
    mean(hours < 3) > 0.01 && mean(hours > 21) > 0.01
  tibble::tibble(
    source_minimum_hour = min(hours),
    source_maximum_hour = max(hours),
    circular_95_arc_hours = circular_arc,
    transformed_95_span_hours = diff(central),
    ordinary_boundary_split = ordinary_boundary_split,
    source_clock_acceptable = circular_arc <= 18 &&
      diff(central) <= 18 && !ordinary_boundary_split
  )
}
