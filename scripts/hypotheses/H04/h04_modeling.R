# H04 Stage 2 weighted quasi-Tweedie fitting, inference, and diagnostics.

h04_capture_warnings <- function(expression) {
  warnings <- character()
  value <- withCallingHandlers(
    expression,
    warning = function(condition) {
      warnings <<- c(warnings, conditionMessage(condition))
      invokeRestart("muffleWarning")
    }
  )
  list(value = value, warnings = unique(warnings))
}

h04_prepare_fit_factors <- function(frame, formula) {
  data <- h04_refactor_frame(frame)
  variables <- all.vars(formula)
  if ("site" %in% variables) {
    contrasts(data$site) <- stats::contr.sum(nlevels(data$site))
  }
  if ("activity" %in% variables) {
    data$activity <- factor(
      as.character(data$activity),
      levels = h04_activity_levels()
    )
    contrasts(data$activity) <- h04_treatment_contrasts(
      levels(data$activity)
    )
  }
  if ("activity_named" %in% variables) {
    data$activity_named <- factor(
      as.character(data$activity_named),
      levels = h04_named_activity_levels()
    )
    contrasts(data$activity_named) <- h04_treatment_contrasts(
      levels(data$activity_named)
    )
  }
  if ("activity_core" %in% variables) {
    data$activity_core <- factor(
      as.character(data$activity_core),
      levels = h04_core_heterogeneity_levels()
    )
    contrasts(data$activity_core) <- h04_treatment_contrasts(
      levels(data$activity_core)
    )
  }
  data$participant <- droplevels(factor(data$participant))
  data$participant_day <- droplevels(factor(data$participant_day))
  data
}

h04_fit_quasi <- function(
  formula,
  frame,
  working_power = h04_specification()$working_tweedie_power
) {
  if (!is.finite(working_power) || working_power <= 1 || working_power >= 2) {
    h04_abort("The H04 quasi-Tweedie working power must lie in (1, 2)")
  }
  data <- h04_prepare_fit_factors(frame, formula)
  if (any(!is.finite(data$geo_medi_1h)) || any(data$geo_medi_1h < 0)) {
    h04_abort("The H04 outcome must be finite and non-negative")
  }
  if (
    !"analysis_weight" %in% names(data) ||
      any(!is.finite(data$analysis_weight)) ||
      any(data$analysis_weight <= 0)
  ) {
    h04_abort("The H04 model frame has invalid analysis weights")
  }
  captured <- h04_capture_warnings(stats::glm(
    formula = formula,
    data = data,
    family = statmod::tweedie(
      var.power = working_power,
      link.power = 0
    ),
    weights = analysis_weight,
    control = stats::glm.control(epsilon = 1e-10, maxit = 100L),
    model = TRUE,
    x = TRUE,
    y = TRUE
  ))
  fit <- captured$value
  if (stats::nobs(fit) != nrow(data)) {
    h04_abort(
      "The H04 fit silently dropped rows: expected %s, used %s",
      nrow(data),
      stats::nobs(fit)
    )
  }
  covariance_capture <- h04_capture_warnings(sandwich::vcovCL(
    fit,
    cluster = data$participant,
    type = "HC1",
    cadjust = TRUE,
    fix = FALSE
  ))
  list(
    fit = fit,
    data = data,
    covariance = covariance_capture$value,
    working_power = working_power,
    fit_warnings = captured$warnings,
    covariance_warnings = covariance_capture$warnings,
    formula = formula
  )
}

h04_covariance_diagnostics <- function(
  covariance,
  relative_tolerance = h04_specification()$interaction_gate$eigen_relative_tolerance
) {
  finite <- is.matrix(covariance) && all(is.finite(covariance))
  if (!finite || nrow(covariance) < 1L) {
    return(tibble::tibble(
      dimension = if (is.matrix(covariance)) nrow(covariance) else NA_integer_,
      finite = FALSE,
      minimum_eigenvalue = NA_real_,
      maximum_eigenvalue = NA_real_,
      numerical_rank = NA_integer_,
      positive_definite = FALSE,
      condition_number = Inf
    ))
  }
  covariance <- (covariance + t(covariance)) / 2
  eigenvalues <- eigen(covariance, symmetric = TRUE, only.values = TRUE)$values
  maximum <- max(eigenvalues)
  tolerance <- max(maximum * relative_tolerance, .Machine$double.eps)
  retained <- eigenvalues > tolerance
  tibble::tibble(
    dimension = nrow(covariance),
    finite = TRUE,
    minimum_eigenvalue = min(eigenvalues),
    maximum_eigenvalue = maximum,
    numerical_rank = sum(retained),
    positive_definite = all(retained),
    condition_number = if (all(retained)) {
      maximum / min(eigenvalues)
    } else {
      Inf
    }
  )
}

h04_term_restriction <- function(fit, term_label) {
  design <- stats::model.matrix(fit)
  term_labels <- attr(stats::terms(fit), "term.labels")
  term_index <- match(term_label, term_labels)
  if (is.na(term_index)) {
    h04_abort("H04 model term not found: %s", term_label)
  }
  indices <- which(attr(design, "assign") == term_index)
  restriction <- matrix(
    0,
    nrow = length(indices),
    ncol = length(stats::coef(fit)),
    dimnames = list(colnames(design)[indices], names(stats::coef(fit)))
  )
  restriction[cbind(seq_along(indices), indices)] <- 1
  restriction
}

h04_wald_f <- function(bundle, restriction) {
  coefficient_names <- names(stats::coef(bundle$fit))
  if (!setequal(colnames(restriction), coefficient_names)) {
    h04_abort("The H04 restriction does not match fitted coefficients")
  }
  restriction <- restriction[, coefficient_names, drop = FALSE]
  estimate <- drop(restriction %*% stats::coef(bundle$fit))
  covariance <- restriction %*% bundle$covariance %*% t(restriction)
  covariance_diagnostic <- h04_covariance_diagnostics(covariance)
  q <- nrow(restriction)
  clusters <- nlevels(bundle$data$participant)
  if (
    !covariance_diagnostic$finite ||
      !covariance_diagnostic$positive_definite ||
      covariance_diagnostic$numerical_rank != q ||
      clusters <= 1L
  ) {
    return(tibble::tibble(
      restrictions = q,
      clusters = clusters,
      denominator_df = clusters - 1L,
      wald_chisq = NA_real_,
      f_statistic = NA_real_,
      p_raw = NA_real_,
      covariance_minimum_eigenvalue = covariance_diagnostic$minimum_eigenvalue,
      covariance_condition_number = covariance_diagnostic$condition_number,
      status = "NON_ESTIMABLE"
    ))
  }
  wald <- drop(crossprod(estimate, solve(covariance, estimate)))
  f_statistic <- wald / q
  tibble::tibble(
    restrictions = q,
    clusters = clusters,
    denominator_df = clusters - 1L,
    wald_chisq = wald,
    f_statistic = f_statistic,
    p_raw = stats::pf(
      f_statistic,
      df1 = q,
      df2 = clusters - 1L,
      lower.tail = FALSE
    ),
    covariance_minimum_eigenvalue = covariance_diagnostic$minimum_eigenvalue,
    covariance_condition_number = covariance_diagnostic$condition_number,
    status = "ESTIMABLE"
  )
}

h04_model_matrix_newdata <- function(bundle, newdata) {
  stats::model.matrix(
    stats::delete.response(stats::terms(bundle$fit)),
    data = newdata,
    contrasts.arg = bundle$fit$contrasts,
    xlev = bundle$fit$xlevels
  )
}

h04_complete_prediction_grid <- function(bundle, grid) {
  needed <- setdiff(
    all.vars(stats::delete.response(stats::terms(bundle$fit))),
    names(grid)
  )
  for (variable in needed) {
    if (!variable %in% names(bundle$data)) {
      next
    }
    value <- bundle$data[[variable]]
    if (is.numeric(value)) {
      grid[[variable]] <- stats::weighted.mean(
        value,
        bundle$data$analysis_weight,
        na.rm = TRUE
      )
    } else if (is.factor(value)) {
      grid[[variable]] <- factor(levels(value)[1L], levels = levels(value))
    } else {
      grid[[variable]] <- value[which(!is.na(value))[1L]]
    }
  }
  grid
}

h04_link_delta <- function(
  log_estimate,
  gradient,
  covariance,
  df,
  null_log = 0,
  confidence_level = h04_specification()$confidence_level
) {
  variance <- drop(crossprod(gradient, covariance %*% gradient))
  if (!is.finite(variance) || variance < 0 || !is.finite(log_estimate)) {
    return(tibble::tibble(
      log_estimate = log_estimate,
      log_se = NA_real_,
      estimate = if (is.finite(log_estimate)) exp(log_estimate) else NA_real_,
      conf_low = NA_real_,
      conf_high = NA_real_,
      statistic = NA_real_,
      df = df,
      p_raw = NA_real_,
      status = "NON_ESTIMABLE"
    ))
  }
  se <- sqrt(max(variance, 0))
  critical <- stats::qt((1 + confidence_level) / 2, df = df)
  statistic <- if (is.finite(null_log) && se > 0) {
    (log_estimate - null_log) / se
  } else {
    NA_real_
  }
  tibble::tibble(
    log_estimate = log_estimate,
    log_se = se,
    estimate = exp(log_estimate),
    conf_low = exp(log_estimate - critical * se),
    conf_high = exp(log_estimate + critical * se),
    statistic = statistic,
    df = df,
    p_raw = if (is.finite(statistic)) {
      2 * stats::pt(abs(statistic), df = df, lower.tail = FALSE)
    } else {
      NA_real_
    },
    status = "ESTIMABLE"
  )
}

h04_difference_delta <- function(
  estimate,
  gradient,
  covariance,
  df,
  confidence_level = h04_specification()$confidence_level
) {
  variance <- drop(crossprod(gradient, covariance %*% gradient))
  if (!is.finite(variance) || variance < 0 || !is.finite(estimate)) {
    return(tibble::tibble(
      estimate = estimate,
      se = NA_real_,
      conf_low = NA_real_,
      conf_high = NA_real_,
      status = "NON_ESTIMABLE"
    ))
  }
  se <- sqrt(max(variance, 0))
  critical <- stats::qt((1 + confidence_level) / 2, df = df)
  tibble::tibble(
    estimate = estimate,
    se = se,
    conf_low = estimate - critical * se,
    conf_high = estimate + critical * se,
    status = "ESTIMABLE"
  )
}

h04_equal_site_estimands <- function(bundle, family_id = "H04-F2") {
  registry <- h04_activity_registry()
  sites <- levels(bundle$data$site)
  activities <- bundle$fit$xlevels$activity
  grid <- tidyr::crossing(
    site = factor(sites, levels = sites),
    activity = factor(activities, levels = activities)
  )
  grid <- h04_complete_prediction_grid(bundle, grid)
  design <- h04_model_matrix_newdata(bundle, grid)
  beta <- stats::coef(bundle$fit)
  covariance <- bundle$covariance
  clusters <- nlevels(bundle$data$participant)
  mean_objects <- stats::setNames(
    vector("list", length(activities)),
    activities
  )
  for (activity in activities) {
    rows <- as.character(grid$activity) == activity
    x <- design[rows, , drop = FALSE]
    mean_objects[[activity]] <- list(
      log_mean = mean(drop(x %*% beta)),
      gradient = colMeans(x)
    )
  }
  reference <- mean_objects[[h04_specification()$reference_label]]
  support <- h04_category_support_stage2(bundle$data)

  output <- lapply(activities, function(activity) {
    object <- mean_objects[[activity]]
    absolute <- h04_link_delta(
      object$log_mean,
      object$gradient,
      covariance,
      clusters - 1L,
      null_log = NA_real_
    )
    if (identical(activity, h04_specification()$reference_label)) {
      ratio <- tibble::tibble(
        estimate = 1,
        conf_low = 1,
        conf_high = 1,
        statistic = NA_real_,
        df = clusters - 1L,
        p_raw = NA_real_,
        status = "REFERENCE"
      )
      difference <- tibble::tibble(
        estimate = 0,
        se = 0,
        conf_low = 0,
        conf_high = 0,
        status = "REFERENCE"
      )
    } else {
      ratio <- h04_link_delta(
        object$log_mean - reference$log_mean,
        object$gradient - reference$gradient,
        covariance,
        clusters - 1L
      )
      mu <- exp(object$log_mean)
      mu_reference <- exp(reference$log_mean)
      difference <- h04_difference_delta(
        mu - mu_reference,
        mu * object$gradient - mu_reference * reference$gradient,
        covariance,
        clusters - 1L
      )
    }
    registry_row <- registry[
      registry$activity_label == activity,
      ,
      drop = FALSE
    ]
    support_row <- support[support$activity_label == activity, , drop = FALSE]
    is_named_contrast <- activity %in%
      setdiff(
        h04_named_activity_levels(),
        h04_specification()$reference_label
      )
    tibble::tibble(
      activity_code = registry_row$activity_code,
      activity = activity,
      display_order = registry_row$display_order,
      model_order = registry_row$model_order,
      standardized_mean_lx = absolute$estimate,
      mean_conf_low_lx = absolute$conf_low,
      mean_conf_high_lx = absolute$conf_high,
      ratio_to_home = ratio$estimate,
      ratio_conf_low = ratio$conf_low,
      ratio_conf_high = ratio$conf_high,
      difference_from_home_lx = difference$estimate,
      difference_conf_low_lx = difference$conf_low,
      difference_conf_high_lx = difference$conf_high,
      statistic = if (is_named_contrast) ratio$statistic else NA_real_,
      denominator_df = ratio$df,
      p_raw = if (is_named_contrast) ratio$p_raw else NA_real_,
      inferential_role = dplyr::case_when(
        activity == h04_specification()$reference_label ~ "REFERENCE",
        activity == "Other/unspecified activity" ~ "DISPLAY_ONLY",
        TRUE ~ "NAMED_VERSUS_HOME"
      ),
      unique_participant_hours = support_row$unique_participant_hours,
      long_rows = support_row$long_rows,
      effective_weighted_hours = support_row$effective_weighted_hours,
      participants = support_row$participants,
      participant_days = support_row$participant_days,
      sites = support_row$sites,
      family_id = if (is_named_contrast) family_id else NA_character_,
      family_n = if (is_named_contrast) 4L else NA_integer_
    )
  }) |>
    dplyr::bind_rows() |>
    dplyr::arrange(.data$display_order)
  output$p_adjusted <- NA_real_
  eligible <- which(output$inferential_role == "NAMED_VERSUS_HOME")
  output$p_adjusted[eligible] <- stats::p.adjust(
    output$p_raw[eligible],
    method = "BH",
    n = 4L
  )
  output
}

h04_mundlak_between_estimands <- function(
  bundle,
  proportion_change = 0.10
) {
  if (
    !is.finite(proportion_change) ||
      proportion_change <= 0 ||
      proportion_change > 1
  ) {
    h04_abort("The H04 Mundlak proportion change must lie in (0, 1]")
  }
  mapping <- h04_mundlak_activity_map()
  coefficient_names <- names(stats::coef(bundle$fit))
  if (!all(mapping$between_variable %in% coefficient_names)) {
    h04_abort("The fitted H04 Mundlak model lacks participant-mean terms")
  }
  clusters <- nlevels(bundle$data$participant)
  df <- clusters - 1L
  critical <- stats::qt(
    (1 + h04_specification()$confidence_level) / 2,
    df = df
  )
  beta <- stats::coef(bundle$fit)
  covariance <- bundle$covariance
  output <- lapply(seq_len(nrow(mapping)), function(index) {
    variable <- mapping$between_variable[index]
    estimate <- unname(beta[variable])
    variance <- unname(covariance[variable, variable])
    se <- if (is.finite(variance) && variance >= 0) sqrt(variance) else NA_real_
    inferential_role <- if (
      mapping$activity[index] == "Other/unspecified activity"
    ) {
      "DISPLAY_ONLY"
    } else {
      "NAMED_COMPOSITION_VERSUS_HOME"
    }
    statistic <- if (is.finite(se) && se > 0) estimate / se else NA_real_
    p_raw <- if (
      inferential_role == "NAMED_COMPOSITION_VERSUS_HOME" &&
        is.finite(statistic)
    ) {
      2 * stats::pt(abs(statistic), df = df, lower.tail = FALSE)
    } else {
      NA_real_
    }
    tibble::tibble(
      activity_code = mapping$activity_code[index],
      activity = mapping$activity[index],
      display_order = mapping$display_order[index],
      model_order = mapping$model_order[index],
      between_variable = variable,
      composition_change_percentage_points = 100 * proportion_change,
      log_ratio_per_change = proportion_change * estimate,
      log_se_per_change = proportion_change * se,
      ratio_per_change = exp(proportion_change * estimate),
      ratio_conf_low = exp(proportion_change * (estimate - critical * se)),
      ratio_conf_high = exp(proportion_change * (estimate + critical * se)),
      statistic = statistic,
      denominator_df = df,
      p_raw = p_raw,
      inferential_role = inferential_role,
      family_id = if (
        inferential_role == "NAMED_COMPOSITION_VERSUS_HOME"
      ) {
        "mundlak_between_named"
      } else {
        NA_character_
      },
      family_n = if (
        inferential_role == "NAMED_COMPOSITION_VERSUS_HOME"
      ) {
        4L
      } else {
        NA_integer_
      }
    )
  }) |>
    dplyr::bind_rows() |>
    dplyr::arrange(.data$display_order)
  output$p_adjusted <- NA_real_
  eligible <- which(
    output$inferential_role == "NAMED_COMPOSITION_VERSUS_HOME"
  )
  output$p_adjusted[eligible] <- stats::p.adjust(
    output$p_raw[eligible],
    method = "BH",
    n = 4L
  )
  output
}

h04_mundlak_between_omnibus <- function(bundle) {
  mapping <- h04_mundlak_activity_map() |>
    dplyr::filter(.data$activity != "Other/unspecified activity")
  coefficient_names <- names(stats::coef(bundle$fit))
  if (!all(mapping$between_variable %in% coefficient_names)) {
    h04_abort("The fitted H04 Mundlak model lacks named composition terms")
  }
  restriction <- matrix(
    0,
    nrow = nrow(mapping),
    ncol = length(coefficient_names),
    dimnames = list(mapping$activity, coefficient_names)
  )
  restriction[cbind(
    seq_len(nrow(mapping)),
    match(mapping$between_variable, coefficient_names)
  )] <- 1
  h04_wald_f(bundle, restriction) |>
    dplyr::mutate(
      test_role = "EXPLORATORY_BETWEEN_PARTICIPANT_COMPOSITION",
      null_hypothesis = paste(
        "the four named participant-level activity-composition terms",
        "are jointly zero while Other remains unrestricted"
      ),
      .before = 1
    )
}

h04_primary_omnibus <- function(bundle) {
  coefficient_names <- names(stats::coef(bundle$fit))
  activities <- bundle$fit$xlevels$activity
  contrast_for <- function(activity) {
    newdata <- bundle$data[rep(1L, 2L), , drop = FALSE]
    newdata$site <- factor(
      levels(bundle$data$site)[1L],
      levels = levels(bundle$data$site)
    )
    newdata$activity <- factor(
      c(h04_specification()$reference_label, activity),
      levels = activities
    )
    design <- h04_model_matrix_newdata(bundle, newdata)
    contrast <- design[2L, ] - design[1L, ]
    contrast[coefficient_names]
  }
  named_nonreference <- setdiff(
    h04_named_activity_levels(),
    h04_specification()$reference_label
  )
  if (!all(named_nonreference %in% activities)) {
    h04_abort("A named activity is absent from an H04 sensitivity fit")
  }
  primary <- do.call(rbind, lapply(named_nonreference, contrast_for))
  secondary <- primary
  if ("Other/unspecified activity" %in% activities) {
    secondary <- rbind(
      primary,
      `Other/unspecified activity = At home` = contrast_for(
        "Other/unspecified activity"
      )
    )
  }
  dplyr::bind_rows(
    h04_wald_f(bundle, primary) |>
      dplyr::mutate(
        test_id = "H04-F1",
        decision_role = "PRIMARY",
        null_hypothesis = "the five named activity-category means are equal; Other is unrestricted",
        .before = 1
      ),
    h04_wald_f(bundle, secondary) |>
      dplyr::mutate(
        test_id = "H04-F1b",
        decision_role = if ("Other/unspecified activity" %in% activities)
          "SECONDARY" else "SECONDARY_FIVE_CATEGORY_SENSITIVITY",
        null_hypothesis = if ("Other/unspecified activity" %in% activities) {
          "all six activity-category means are equal"
        } else {
          "all five retained named activity-category means are equal; Other is absent"
        },
        .before = 1
      )
  )
}

h04_cluster_diagnostics <- function(bundle) {
  score <- sandwich::estfun(bundle$fit)
  cluster <- droplevels(bundle$data$participant)
  score_by_cluster <- rowsum(score, cluster, reorder = FALSE)
  score_energy <- rowSums(score_by_cluster^2)
  score_share <- score_energy / sum(score_energy)
  leverage <- stats::hatvalues(bundle$fit)
  leverage_by_cluster <- rowsum(leverage, cluster, reorder = FALSE)[, 1L]
  leverage_share <- leverage_by_cluster / sum(leverage_by_cluster)
  tibble::tibble(
    participant = rownames(score_by_cluster),
    long_rows = as.integer(table(cluster)[rownames(score_by_cluster)]),
    effective_weighted_hours = as.numeric(rowsum(
      bundle$data$analysis_weight,
      cluster,
      reorder = FALSE
    )[, 1L]),
    score_energy = score_energy,
    score_share = score_share,
    leverage = leverage_by_cluster,
    leverage_share = leverage_share,
    score_rank = rank(-score_share, ties.method = "first"),
    leverage_rank = rank(-leverage_share, ties.method = "first")
  ) |>
    dplyr::arrange(.data$score_rank)
}

h04_hour_residual_data <- function(bundle) {
  data <- bundle$data
  data$pearson_residual <- stats::residuals(bundle$fit, type = "pearson")
  data$deviance_residual <- stats::residuals(bundle$fit, type = "deviance")
  data$fitted_mean <- stats::fitted(bundle$fit)
  data |>
    dplyr::group_by(.data$analysis_hour_id) |>
    dplyr::summarise(
      site = dplyr::first(.data$site),
      participant = dplyr::first(.data$participant),
      participant_day = dplyr::first(.data$participant_day),
      local_date = dplyr::first(.data$local_date),
      clock_minute = dplyr::first(.data$clock_minute),
      interval_start_utc = dplyr::first(.data$interval_start_utc),
      geo_medi_1h = dplyr::first(.data$geo_medi_1h),
      pearson_residual = stats::weighted.mean(
        .data$pearson_residual,
        .data$analysis_weight
      ),
      deviance_residual = stats::weighted.mean(
        .data$deviance_residual,
        .data$analysis_weight
      ),
      fitted_mean = stats::weighted.mean(
        .data$fitted_mean,
        .data$analysis_weight
      ),
      .groups = "drop"
    )
}

h04_residual_acf <- function(bundle, max_lag = 6L) {
  residual <- h04_hour_residual_data(bundle)
  sequence <- h04_add_unique_hour_sequences(bundle$data) |>
    dplyr::select("analysis_hour_id", "sequence_id")
  residual <- residual |>
    dplyr::left_join(sequence, by = "analysis_hour_id") |>
    dplyr::arrange(
      .data$participant,
      .data$participant_day,
      .data$interval_start_utc
    )
  index <- seq_len(nrow(residual))
  dplyr::bind_rows(lapply(0:max_lag, function(lag) {
    earlier <- index - lag
    eligible <- earlier >= 1L
    eligible[eligible] <- residual$sequence_id[index[eligible]] ==
      residual$sequence_id[earlier[eligible]]
    if (lag == 0L) {
      correlation <- 1
    } else if (sum(eligible) >= 3L) {
      correlation <- stats::cor(
        residual$pearson_residual[index[eligible]],
        residual$pearson_residual[earlier[eligible]]
      )
    } else {
      correlation <- NA_real_
    }
    tibble::tibble(
      lag_hours = lag,
      pairs = sum(eligible),
      correlation = correlation
    )
  }))
}

h04_fit_diagnostics <- function(bundle, run_id) {
  fit <- bundle$fit
  covariance <- h04_covariance_diagnostics(bundle$covariance)
  clusters <- h04_cluster_diagnostics(bundle)
  hour <- h04_hour_residual_data(bundle)
  acf <- h04_residual_acf(bundle)
  lag_one <- acf$correlation[acf$lag_hours == 1L]
  tibble::tibble(
    run_id = run_id,
    observations_long_rows = stats::nobs(fit),
    unique_participant_hours = nrow(hour),
    effective_weighted_hours = sum(bundle$data$analysis_weight),
    participants = nlevels(bundle$data$participant),
    participant_days = nlevels(bundle$data$participant_day),
    sites = nlevels(bundle$data$site),
    iterations = fit$iter,
    converged = isTRUE(fit$converged),
    design_columns = ncol(stats::model.matrix(fit)),
    design_rank = fit$rank,
    full_rank = fit$rank == ncol(stats::model.matrix(fit)),
    aliased_coefficients = sum(is.na(stats::coef(fit))),
    finite_coefficients = all(is.finite(stats::coef(fit))),
    covariance_finite = covariance$finite,
    covariance_positive_definite = covariance$positive_definite,
    covariance_minimum_eigenvalue = covariance$minimum_eigenvalue,
    covariance_condition_number = covariance$condition_number,
    dispersion = summary(fit)$dispersion,
    exact_zero_unique_hours = sum(hour$geo_medi_1h == 0),
    exact_zero_fraction = mean(hour$geo_medi_1h == 0),
    fitted_minimum = min(stats::fitted(fit)),
    fitted_median = stats::median(stats::fitted(fit)),
    fitted_maximum = max(stats::fitted(fit)),
    hour_pearson_mean = mean(hour$pearson_residual),
    hour_pearson_sd = stats::sd(hour$pearson_residual),
    hour_pearson_q01 = unname(stats::quantile(hour$pearson_residual, 0.01)),
    hour_pearson_q99 = unname(stats::quantile(hour$pearson_residual, 0.99)),
    hour_residual_fitted_spearman = stats::cor(
      hour$pearson_residual,
      hour$fitted_mean,
      method = "spearman"
    ),
    hour_absolute_residual_fitted_spearman = stats::cor(
      abs(hour$pearson_residual),
      hour$fitted_mean,
      method = "spearman"
    ),
    hour_residual_lag1_correlation = lag_one,
    maximum_cluster_score_share = max(clusters$score_share),
    maximum_cluster_leverage_share = max(clusters$leverage_share),
    fit_warnings = paste(bundle$fit_warnings, collapse = " | "),
    covariance_warnings = paste(bundle$covariance_warnings, collapse = " | ")
  )
}

h04_residual_calibration <- function(bundle, run_id, bins = 20L) {
  data <- bundle$data
  data$fitted_mean <- stats::fitted(bundle$fit)
  data$pearson_residual <- stats::residuals(bundle$fit, type = "pearson")
  data |>
    dplyr::mutate(fitted_bin = dplyr::ntile(.data$fitted_mean, bins)) |>
    dplyr::group_by(.data$fitted_bin) |>
    dplyr::summarise(
      long_rows = dplyr::n(),
      effective_weighted_hours = sum(.data$analysis_weight),
      observed_mean_lx = stats::weighted.mean(
        .data$geo_medi_1h,
        .data$analysis_weight
      ),
      fitted_mean_lx = stats::weighted.mean(
        .data$fitted_mean,
        .data$analysis_weight
      ),
      pearson_mean = stats::weighted.mean(
        .data$pearson_residual,
        .data$analysis_weight
      ),
      zero_weighted_fraction = stats::weighted.mean(
        .data$geo_medi_1h == 0,
        .data$analysis_weight
      ),
      .groups = "drop"
    ) |>
    dplyr::mutate(run_id = run_id, .before = 1)
}

h04_group_calibration <- function(bundle, run_id) {
  data <- bundle$data
  data$fitted_mean <- stats::fitted(bundle$fit)
  summarize_group <- function(group, group_type) {
    data |>
      dplyr::group_by(group_value = {{ group }}) |>
      dplyr::summarise(
        long_rows = dplyr::n(),
        effective_weighted_hours = sum(.data$analysis_weight),
        observed_mean_lx = stats::weighted.mean(
          .data$geo_medi_1h,
          .data$analysis_weight
        ),
        fitted_mean_lx = stats::weighted.mean(
          .data$fitted_mean,
          .data$analysis_weight
        ),
        zero_weighted_fraction = stats::weighted.mean(
          .data$geo_medi_1h == 0,
          .data$analysis_weight
        ),
        .groups = "drop"
      ) |>
      dplyr::mutate(
        run_id = run_id,
        group_type = group_type,
        group_value = as.character(.data$group_value),
        .before = 1
      )
  }
  dplyr::bind_rows(
    summarize_group(.data$site, "site"),
    summarize_group(.data$activity, "activity")
  )
}

h04_fit_additive_run <- function(
  frame,
  run_id,
  scenario_id,
  placement,
  working_power = h04_specification()$working_tweedie_power,
  formula = h04_formula_set()$primary_full
) {
  bundle <- h04_fit_quasi(
    formula,
    frame,
    working_power
  )
  list(
    bundle = bundle,
    estimands = h04_equal_site_estimands(bundle) |>
      dplyr::mutate(
        run_id = run_id,
        scenario_id = scenario_id,
        placement = placement,
        working_power = working_power,
        .before = 1
      ),
    tests = h04_primary_omnibus(bundle) |>
      dplyr::mutate(
        run_id = run_id,
        scenario_id = scenario_id,
        placement = placement,
        working_power = working_power,
        .before = 1
      ),
    diagnostics = h04_fit_diagnostics(bundle, run_id) |>
      dplyr::mutate(
        scenario_id = scenario_id,
        placement = placement,
        working_power = working_power,
        formula = h04_formula_text(bundle$formula),
        .after = "run_id"
      ),
    sample = h04_sample_summary(bundle$data, run_id, scenario_id, placement) |>
      dplyr::mutate(
        working_power = working_power,
        formula = h04_formula_text(bundle$formula)
      )
  )
}

h04_interaction_prediction <- function(bundle, architecture) {
  activity_variable <- if (architecture == "five_named") {
    "activity_named"
  } else {
    "activity_core"
  }
  activity_levels <- levels(bundle$data[[activity_variable]])
  sites <- levels(bundle$data$site)
  grid <- tidyr::crossing(
    site = factor(sites, levels = sites),
    activity_value = factor(activity_levels, levels = activity_levels)
  )
  names(grid)[names(grid) == "activity_value"] <- activity_variable
  design <- h04_model_matrix_newdata(bundle, grid)
  list(grid = grid, design = design, activity_variable = activity_variable)
}

h04_interaction_estimands <- function(bundle, architecture, cell_support) {
  prediction <- h04_interaction_prediction(bundle, architecture)
  grid <- prediction$grid
  design <- prediction$design
  variable <- prediction$activity_variable
  beta <- stats::coef(bundle$fit)
  covariance <- bundle$covariance
  clusters <- nlevels(bundle$data$participant)
  sites <- levels(bundle$data$site)
  activities <- levels(bundle$data[[variable]])
  activity_values <- as.character(grid[[variable]])
  mean_objects <- stats::setNames(
    vector("list", length(activities)),
    activities
  )
  for (activity in activities) {
    rows <- activity_values == activity
    x <- design[rows, , drop = FALSE]
    mean_objects[[activity]] <- list(
      log_mean = mean(drop(x %*% beta)),
      gradient = colMeans(x)
    )
  }
  cell_index <- stats::setNames(
    seq_len(nrow(grid)),
    paste(as.character(grid$site), activity_values, sep = "__")
  )
  output <- lapply(seq_len(nrow(cell_support)), function(index) {
    support <- cell_support[index, , drop = FALSE]
    site <- as.character(support$site)
    activity <- as.character(support$activity)
    included <- activity %in% activities && site %in% sites
    row <- unname(cell_index[paste(site, activity, sep = "__")])
    if (!included || length(row) != 1L || is.na(row)) {
      return(tibble::tibble(
        site = site,
        activity = activity,
        architecture = architecture,
        support_rule = isTRUE(support$support_rule),
        reporting_status = "NOT_IN_SELECTED_ARCHITECTURE",
        cell_mean_lx = NA_real_,
        cell_conf_low_lx = NA_real_,
        cell_conf_high_lx = NA_real_,
        category_standardized_mean_lx = NA_real_,
        site_deviation_ratio = NA_real_,
        site_deviation_conf_low = NA_real_,
        site_deviation_conf_high = NA_real_,
        site_deviation_p_raw = NA_real_
      ))
    }
    x <- design[row, ]
    eta <- drop(x %*% beta)
    object <- mean_objects[[activity]]
    cell <- h04_link_delta(
      eta,
      x,
      covariance,
      clusters - 1L,
      null_log = NA_real_
    )
    deviation <- h04_link_delta(
      eta - object$log_mean,
      x - object$gradient,
      covariance,
      clusters - 1L
    )
    reportable <- isTRUE(support$support_rule) &&
      cell$status == "ESTIMABLE" &&
      deviation$status == "ESTIMABLE"
    tibble::tibble(
      site = site,
      activity = activity,
      architecture = architecture,
      support_rule = isTRUE(support$support_rule),
      reporting_status = if (reportable) {
        "ESTIMABLE"
      } else {
        "SUPPORT_NON_ESTIMABLE"
      },
      cell_mean_lx = if (reportable) cell$estimate else NA_real_,
      cell_conf_low_lx = if (reportable) cell$conf_low else NA_real_,
      cell_conf_high_lx = if (reportable) cell$conf_high else NA_real_,
      category_standardized_mean_lx = exp(object$log_mean),
      site_deviation_ratio = if (reportable) deviation$estimate else NA_real_,
      site_deviation_conf_low = if (reportable) deviation$conf_low else
        NA_real_,
      site_deviation_conf_high = if (reportable) deviation$conf_high else
        NA_real_,
      site_deviation_p_raw = if (reportable) deviation$p_raw else NA_real_
    )
  }) |>
    dplyr::bind_rows() |>
    dplyr::left_join(
      cell_support |>
        dplyr::transmute(
          site = as.character(.data$site),
          activity = as.character(.data$activity),
          activity_code = .data$activity_code,
          activity_display_order = .data$display_order.x,
          site_display_name = .data$display_name,
          site_display_order = .data$display_order.y,
          site_color_hex = .data$color_hex,
          unique_participant_hours = .data$unique_hours,
          long_rows = .data$long_rows,
          effective_weighted_hours = .data$effective_weighted_hours,
          participants = .data$participants,
          shared_with_home_participants = .data$shared_with_home_participants
        ),
      by = c("site", "activity"),
      relationship = "one-to-one"
    )
  eligible <- is.finite(output$site_deviation_p_raw)
  output$family_id <- ifelse(eligible, "H04-F4", NA_character_)
  output$family_n <- ifelse(eligible, sum(eligible), NA_integer_)
  output$site_deviation_p_adjusted <- NA_real_
  output$site_deviation_p_adjusted[eligible] <- stats::p.adjust(
    output$site_deviation_p_raw[eligible],
    method = "BH",
    n = sum(eligible)
  )
  output |>
    dplyr::arrange(.data$activity_display_order, .data$site_display_order)
}

h04_interaction_gate_row <- function(
  bundle,
  placement,
  architecture,
  restriction,
  site_estimands
) {
  spec <- h04_specification()
  covariance <- restriction %*% bundle$covariance %*% t(restriction)
  covariance_diagnostic <- h04_covariance_diagnostics(covariance)
  clusters <- h04_cluster_diagnostics(bundle)
  supported <- site_estimands$support_rule &
    site_estimands$reporting_status != "NOT_IN_SELECTED_ARCHITECTURE"
  finite_supported_intervals <- all(
    is.finite(site_estimands$cell_conf_low_lx[supported]) &
      is.finite(site_estimands$cell_conf_high_lx[supported])
  )
  gate_pass <- isTRUE(bundle$fit$converged) &&
    bundle$fit$rank == ncol(stats::model.matrix(bundle$fit)) &&
    all(is.finite(stats::coef(bundle$fit))) &&
    covariance_diagnostic$finite &&
    covariance_diagnostic$positive_definite &&
    covariance_diagnostic$condition_number <=
      spec$interaction_gate$maximum_condition_number &&
    max(clusters$score_share) <=
      spec$interaction_gate$maximum_cluster_score_share &&
    max(clusters$leverage_share) <=
      spec$interaction_gate$maximum_cluster_leverage_share &&
    finite_supported_intervals
  tibble::tibble(
    placement = placement,
    architecture = architecture,
    formula = h04_formula_text(bundle$formula),
    long_rows = nrow(bundle$data),
    unique_participant_hours = dplyr::n_distinct(
      bundle$data$analysis_hour_id
    ),
    effective_weighted_hours = sum(bundle$data$analysis_weight),
    participants = nlevels(bundle$data$participant),
    converged = isTRUE(bundle$fit$converged),
    full_rank = bundle$fit$rank == ncol(stats::model.matrix(bundle$fit)),
    finite_coefficients = all(is.finite(stats::coef(bundle$fit))),
    restriction_df = nrow(restriction),
    restriction_covariance_positive_definite = covariance_diagnostic$positive_definite,
    restriction_covariance_condition_number = covariance_diagnostic$condition_number,
    maximum_cluster_score_share = max(clusters$score_share),
    maximum_cluster_leverage_share = max(clusters$leverage_share),
    finite_supported_intervals = finite_supported_intervals,
    fit_warnings = paste(bundle$fit_warnings, collapse = " | "),
    covariance_warnings = paste(bundle$covariance_warnings, collapse = " | "),
    gate_pass = gate_pass
  )
}

h04_run_heterogeneity_gate <- function(frame, placement, root) {
  formulas <- h04_formula_set()
  support <- h04_site_category_support_stage2(frame, root)
  run_architecture <- function(architecture) {
    data <- h04_prepare_heterogeneity_frame(frame, architecture)
    formula <- if (architecture == "five_named") {
      formulas$heterogeneity_five_named_full
    } else {
      formulas$heterogeneity_core_full
    }
    term <- if (architecture == "five_named") {
      "site:activity_named"
    } else {
      "site:activity_core"
    }
    bundle <- h04_fit_quasi(formula, data)
    restriction <- h04_term_restriction(bundle$fit, term)
    estimands <- h04_interaction_estimands(
      bundle,
      architecture,
      support
    )
    gate <- h04_interaction_gate_row(
      bundle,
      placement,
      architecture,
      restriction,
      estimands
    )
    list(
      bundle = bundle,
      restriction = restriction,
      estimands = estimands,
      gate = gate
    )
  }
  full <- run_architecture("five_named")
  if (isTRUE(full$gate$gate_pass)) {
    selected <- full
    selected_architecture <- "five_named"
    gates <- full$gate
  } else {
    fallback <- run_architecture("core")
    selected <- fallback
    selected_architecture <- if (isTRUE(fallback$gate$gate_pass)) {
      "core"
    } else {
      "non_estimable"
    }
    gates <- dplyr::bind_rows(full$gate, fallback$gate)
  }
  test <- if (selected_architecture == "non_estimable") {
    tibble::tibble(
      restrictions = nrow(selected$restriction),
      clusters = nlevels(selected$bundle$data$participant),
      denominator_df = nlevels(selected$bundle$data$participant) - 1L,
      wald_chisq = NA_real_,
      f_statistic = NA_real_,
      p_raw = NA_real_,
      covariance_minimum_eigenvalue = NA_real_,
      covariance_condition_number = NA_real_,
      status = "GATE_NON_ESTIMABLE"
    )
  } else {
    h04_wald_f(selected$bundle, selected$restriction)
  }
  test <- test |>
    dplyr::mutate(
      test_id = "H04-F3",
      placement = placement,
      selected_architecture = selected_architecture,
      null_hypothesis = paste(
        "all site-by-activity departures from additivity are zero",
        "within the selected named-category architecture"
      ),
      .before = 1
    )
  list(
    selected_architecture = selected_architecture,
    selected = selected,
    gate = gates,
    test = test,
    cell_support = support
  )
}

h04_fit_v0_bridge <- function(data, placement) {
  formulas <- h04_formula_set()
  contrasts(data$site) <- stats::contr.sum(nlevels(data$site))
  contrasts(data$activity_v0) <- stats::contr.treatment(
    nlevels(data$activity_v0),
    base = 1L
  )
  full_capture <- h04_capture_warnings(glmmTMB::glmmTMB(
    formula = formulas$v0_full,
    data = data,
    REML = FALSE,
    family = glmmTMB::tweedie(link = "log"),
    contrasts = list(
      site = stats::contr.sum,
      activity_v0 = stats::contr.treatment
    )
  ))
  null_capture <- h04_capture_warnings(glmmTMB::glmmTMB(
    formula = formulas$v0_site_only,
    data = data,
    REML = FALSE,
    family = glmmTMB::tweedie(link = "log"),
    contrasts = list(site = stats::contr.sum)
  ))
  full <- full_capture$value
  null <- null_capture$value
  comparison <- stats::anova(null, full)
  means <- emmeans::emmeans(
    full,
    specs = ~activity_v0,
    type = "response",
    weights = "equal"
  )
  means_table <- summary(means, infer = c(TRUE, TRUE)) |>
    as.data.frame() |>
    tibble::as_tibble()
  ratios <- summary(
    emmeans::contrast(
      means,
      method = "trt.vs.ctrl",
      ref = 1L,
      adjust = "none"
    ),
    infer = c(TRUE, TRUE),
    type = "response"
  ) |>
    as.data.frame() |>
    tibble::as_tibble()
  response_column <- intersect(c("response", "emmean"), names(means_table))[1L]
  mean_lower <- intersect(
    c("asymp.LCL", "lower.CL", "response.LCL"),
    names(means_table)
  )[1L]
  mean_upper <- intersect(
    c("asymp.UCL", "upper.CL", "response.UCL"),
    names(means_table)
  )[1L]
  ratio_column <- intersect(c("ratio", "response"), names(ratios))[1L]
  ratio_lower <- intersect(
    c("asymp.LCL", "lower.CL", "response.LCL"),
    names(ratios)
  )[1L]
  ratio_upper <- intersect(
    c("asymp.UCL", "upper.CL", "response.UCL"),
    names(ratios)
  )[1L]
  list(
    full = full,
    null = null,
    model_table = tibble::tibble(
      placement = placement,
      model_id = c("v0_site_only", "v0_full_joint"),
      formula = c(
        h04_formula_text(formulas$v0_site_only),
        h04_formula_text(formulas$v0_full)
      ),
      long_rows = nrow(data),
      unique_participant_hours = dplyr::n_distinct(
        interaction(
          data$site,
          data$Id,
          data$local_date,
          data$clock_minute,
          drop = TRUE
        )
      ),
      participants = dplyr::n_distinct(data$participant),
      participant_days = dplyr::n_distinct(data$participant_day),
      sites = dplyr::n_distinct(data$site),
      categories = dplyr::n_distinct(data$activity_v0),
      convergence_code = c(null$fit$convergence, full$fit$convergence),
      positive_definite_hessian = c(null$sdr$pdHess, full$sdr$pdHess),
      warnings = c(
        paste(null_capture$warnings, collapse = " | "),
        paste(full_capture$warnings, collapse = " | ")
      )
    ),
    test = tibble::tibble(
      placement = placement,
      test_id = "V0_joint_category_plus_interaction_LRT",
      reduced_formula = h04_formula_text(formulas$v0_site_only),
      full_formula = h04_formula_text(formulas$v0_full),
      restrictions_added = comparison$Df[2L] - comparison$Df[1L],
      likelihood_ratio_chisq = comparison$Chisq[2L],
      p_raw = comparison$`Pr(>Chisq)`[2L],
      interpretation = paste(
        "jointly adds activity main effects and site interactions;",
        "not the repaired H04-F1 primary test"
      )
    ),
    means = tibble::tibble(
      placement = placement,
      activity_v0 = as.character(means_table$activity_v0),
      estimated_mean_lx = means_table[[response_column]],
      conf_low_lx = means_table[[mean_lower]],
      conf_high_lx = means_table[[mean_upper]]
    ),
    ratios = tibble::tibble(
      placement = placement,
      contrast = ratios$contrast,
      ratio_to_home = ratios[[ratio_column]],
      conf_low = ratios[[ratio_lower]],
      conf_high = ratios[[ratio_upper]],
      p_raw_unadjusted = ratios$p.value
    )
  )
}
