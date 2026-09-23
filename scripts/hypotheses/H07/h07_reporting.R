h07_inverse_response <- function(eta, spec) {
  if (identical(spec$response_family[[1L]], "tweedie_log")) {
    exp(eta)
  } else if (identical(spec$response_transform[[1L]], "log10_offset_0.1")) {
    10^eta - 0.1
  } else {
    eta
  }
}

h07_random_effect_labels <- function(fit) {
  labels <- vapply(fit$smooth, function(smooth) smooth$label, character(1))
  intersect(labels, c("s(site)", "s(site_participant)"))
}

h07_prediction_data <- function(frame, photoperiod_hours) {
  template <- frame[rep(1L, length(photoperiod_hours)), , drop = FALSE]
  template$photoperiod_hours <- photoperiod_hours
  template
}

h07_population_curve <- function(fit, frame, spec, grid) {
  newdata <- h07_prediction_data(frame, grid)
  excluded <- h07_random_effect_labels(fit)
  prediction <- stats::predict(
    fit,
    newdata = newdata,
    type = "link",
    se.fit = TRUE,
    unconditional = TRUE,
    exclude = excluded
  )
  eta <- as.numeric(prediction$fit)
  se_eta <- as.numeric(prediction$se.fit)
  tibble::tibble(
    photoperiod_hours = grid,
    link_estimate = eta,
    link_se = se_eta,
    response_estimate = h07_inverse_response(eta, spec),
    response_lower_pointwise = h07_inverse_response(
      eta - normal_critical * se_eta,
      spec
    ),
    response_upper_pointwise = h07_inverse_response(
      eta + normal_critical * se_eta,
      spec
    )
  )
}

h07_aggregate_local_support <- function(data) {
  if (nrow(data) == 0L) {
    return(c(
      sites = 0,
      participants = 0,
      participant_days = 0,
      max_site_share = NA_real_,
      passes = 0
    ))
  }
  sites <- nrow(data)
  participants <- sum(data$participants)
  participant_days <- sum(data$participant_days)
  max_site_share <- if (participant_days > 0) {
    max(data$participant_days / participant_days)
  } else {
    NA_real_
  }
  passes <- sites >= 3L &&
    participants >= 20L &&
    participant_days >= 60L &&
    is.finite(max_site_share) &&
    max_site_share <= 0.50
  c(
    sites = sites,
    participants = participants,
    participant_days = participant_days,
    max_site_share = max_site_share,
    passes = as.numeric(passes)
  )
}

h07_support_at_point <- function(frame, grid_value) {
  by_site <- frame |>
    group_by(.data$site) |>
    summarise(
      q05 = stats::quantile(.data$photoperiod_hours, 0.05, names = FALSE),
      q95 = stats::quantile(.data$photoperiod_hours, 0.95, names = FALSE),
      participants = n_distinct(
        .data$Id[abs(.data$photoperiod_hours - .env$grid_value) <= 0.5]
      ),
      participant_days = sum(
        abs(.data$photoperiod_hours - .env$grid_value) <= 0.5
      ),
      .groups = "drop"
    ) |>
    mutate(
      site_supported =
        .env$grid_value >= .data$q05 &
        .env$grid_value <= .data$q95 &
        .data$participants >= 5L &
        .data$participant_days >= 15L
    ) |>
    filter(.data$site_supported)
  pooled <- h07_aggregate_local_support(by_site)
  omitted_sites <- levels(frame$site)
  loso_eligible <- all(vapply(
    omitted_sites,
    function(omitted_site) {
      h07_aggregate_local_support(
        by_site |>
          filter(as.character(.data$site) != .env$omitted_site)
      )[["passes"]] == 1
    },
    logical(1)
  ))
  tibble::tibble(
    photoperiod_hours = grid_value,
    sites = pooled[["sites"]],
    participants = pooled[["participants"]],
    participant_days = pooled[["participant_days"]],
    max_site_share = pooled[["max_site_share"]],
    pooled_eligible = pooled[["passes"]] == 1,
    loso_eligible = loso_eligible
  )
}

h07_support_grid <- function(frame) {
  grid <- seq(
    floor(min(frame$photoperiod_hours) * 10) / 10,
    ceiling(max(frame$photoperiod_hours) * 10) / 10,
    by = 0.1
  )
  purrr::map_dfr(grid, ~ h07_support_at_point(frame, .x))
}

h07_pairwise_concurvity <- function(
    fit_bundle,
    target_pattern) {
  fit <- fit_bundle$fit
  pairwise <- tryCatch(
    mgcv::concurvity(fit, full = FALSE),
    error = function(error) NULL
  )
  if (is.null(pairwise)) return(tibble::tibble())
  purrr::imap_dfr(pairwise, function(matrix, measure) {
    target <- grep(target_pattern, colnames(matrix), value = TRUE)
    if (length(target) != 1L) return(tibble::tibble())
    tibble::tibble(
      run_id = fit_bundle$run_id,
      metric_id = fit_bundle$metric_id,
      model_id = fit_bundle$model_id,
      measure = measure,
      supplier_term = rownames(matrix),
      target_term = target,
      concurvity = as.numeric(matrix[, target])
    )
  })
}

h07_residual_summary <- function(fit, frame, spec) {
  residual <- as.numeric(stats::residuals(fit, type = "pearson"))
  fitted_response_scale <- as.numeric(stats::fitted(fit))
  fitted_natural <- if (identical(spec$response_family[[1L]], "tweedie_log")) {
    # fitted.gam() is already on the response scale for a log-link Tweedie fit.
    fitted_response_scale
  } else {
    h07_inverse_response(fitted_response_scale, spec)
  }
  centred <- residual - mean(residual)
  sd_residual <- stats::sd(residual)
  skewness <- if (is.finite(sd_residual) && sd_residual > 0) {
    mean(centred^3) / sd_residual^3
  } else {
    NA_real_
  }
  excess_kurtosis <- if (is.finite(sd_residual) && sd_residual > 0) {
    mean(centred^4) / sd_residual^4 - 3
  } else {
    NA_real_
  }
  summary_fit <- summary(fit)
  tibble::tibble(
    observations = nrow(frame),
    residual_mean = mean(residual),
    residual_sd = sd_residual,
    residual_q01 = stats::quantile(residual, 0.01, names = FALSE),
    residual_q05 = stats::quantile(residual, 0.05, names = FALSE),
    residual_q50 = stats::quantile(residual, 0.50, names = FALSE),
    residual_q95 = stats::quantile(residual, 0.95, names = FALSE),
    residual_q99 = stats::quantile(residual, 0.99, names = FALSE),
    residual_skewness = skewness,
    residual_excess_kurtosis = excess_kurtosis,
    normal_qq_correlation = suppressWarnings(stats::cor(
      sort(residual),
      stats::qnorm(stats::ppoints(length(residual)))
    )),
    fitted_residual_correlation = suppressWarnings(stats::cor(
      fitted_response_scale,
      residual
    )),
    fitted_absolute_residual_correlation = suppressWarnings(stats::cor(
      fitted_response_scale,
      abs(residual)
    )),
    proportion_abs_pearson_above_2 = mean(abs(residual) > 2),
    proportion_abs_pearson_above_3 = mean(abs(residual) > 3),
    deviance_explained = summary_fit$dev.expl,
    adjusted_r_squared = summary_fit$r.sq,
    observed_natural_min = min(frame$original_value),
    observed_natural_max = max(frame$original_value),
    observed_zeros = sum(frame$original_value == 0),
    observed_negative = sum(frame$original_value < 0),
    observed_above_24_hours = if (spec$display_unit[[1L]] == "h") {
      sum(frame$original_value > 24)
    } else {
      NA_integer_
    },
    fitted_natural_min = min(fitted_natural),
    fitted_natural_max = max(fitted_natural)
  )
}

h07_tweedie_distribution_check <- function(fit, frame, seed) {
  family <- fit$family
  power <- as.numeric(family$getTheta(trans = TRUE))[[1L]]
  dispersion <- summary(fit)$dispersion
  mu <- as.numeric(stats::fitted(fit))
  zero_probability <- exp(
    -(mu^(2 - power)) / (dispersion * (2 - power))
  )
  observed_positive <- frame$original_value[frame$original_value > 0]
  started <- proc.time()[["elapsed"]]
  set.seed(seed)
  simulated <- replicate(
    simulation_draws,
    {
      response <- family$rd(
        mu = mu,
        wt = fit$prior.weights,
        scale = dispersion
      )
      positive <- response[response > 0]
      c(
        zero_count = sum(response == 0),
        positive_q95 = if (length(positive)) {
          stats::quantile(positive, 0.95, names = FALSE)
        } else {
          NA_real_
        },
        positive_max = if (length(positive)) max(positive) else NA_real_
      )
    }
  )
  elapsed <- proc.time()[["elapsed"]] - started
  interval <- function(x) {
    stats::quantile(x, c(0.025, 0.975), names = FALSE, na.rm = TRUE, type = 8)
  }
  zero_interval <- interval(simulated["zero_count", ])
  q95_interval <- interval(simulated["positive_q95", ])
  max_interval <- interval(simulated["positive_max", ])
  observed_q95 <- if (length(observed_positive)) {
    stats::quantile(observed_positive, 0.95, names = FALSE)
  } else {
    NA_real_
  }
  observed_max <- if (length(observed_positive)) max(observed_positive) else NA_real_
  tibble::tibble(
    analysis_role = "response-distribution diagnostic",
    draws = simulation_draws,
    seed = seed,
    power = power,
    dispersion = dispersion,
    observed_zero_count = sum(frame$original_value == 0),
    analytic_expected_zero_count = sum(zero_probability),
    analytic_zero_sd = sqrt(sum(zero_probability * (1 - zero_probability))),
    simulated_zero_lower = zero_interval[[1L]],
    simulated_zero_upper = zero_interval[[2L]],
    observed_positive_q95 = observed_q95,
    simulated_positive_q95_lower = q95_interval[[1L]],
    simulated_positive_q95_upper = q95_interval[[2L]],
    observed_positive_max = observed_max,
    simulated_positive_max_lower = max_interval[[1L]],
    simulated_positive_max_upper = max_interval[[2L]],
    elapsed_seconds = elapsed
  )
}

h07_model_form_inverse <- function(eta, spec) {
  if (identical(spec$response_family[[1L]], "tweedie_log")) {
    exp(eta)
  } else if (identical(spec$response_transform[[1L]], "log10_offset_0.1")) {
    10^eta - 0.1
  } else {
    eta
  }
}

h07_model_form_curve <- function(fit, frame, grid, model_id) {
  spec <- attr(frame, "h07_spec")
  labels <- vapply(fit$smooth, function(smooth) smooth$label, character(1))
  participant_label <- intersect(labels, "s(site_participant)")
  if (model_id == "adapted_photoperiod_fixed_site") {
    sites <- levels(frame$site)
    site_curves <- purrr::map_dfr(sites, function(site_value) {
      newdata <- frame[rep(1L, length(grid)), , drop = FALSE]
      newdata$photoperiod_hours <- grid
      newdata$site <- factor(site_value, levels = levels(frame$site))
      prediction <- stats::predict(
        fit,
        newdata = newdata,
        type = "link",
        exclude = participant_label
      )
      tibble::tibble(
        site = site_value,
        photoperiod_hours = round(grid, 1),
        site_response = h07_model_form_inverse(
          as.numeric(prediction),
          spec
        )
      )
    })
    return(site_curves |>
      group_by(.data$photoperiod_hours) |>
      summarise(
        response_estimate = mean(.data$site_response),
        site_response_min = min(.data$site_response),
        site_response_max = max(.data$site_response),
        .groups = "drop"
      ) |>
      mutate(
        prediction_mode = "equal_site_response_average_fixed_site",
        pointwise_interval_available = FALSE
      ))
  }
  excluded <- intersect(labels, c("s(site)", "s(site_participant)"))
  newdata <- frame[rep(1L, length(grid)), , drop = FALSE]
  newdata$photoperiod_hours <- grid
  prediction <- stats::predict(
    fit,
    newdata = newdata,
    type = "link",
    se.fit = TRUE,
    unconditional = TRUE,
    exclude = excluded
  )
  estimate <- as.numeric(prediction$fit)
  se <- as.numeric(prediction$se.fit)
  tibble::tibble(
    photoperiod_hours = round(grid, 1),
    response_estimate = h07_model_form_inverse(estimate, spec),
    site_response_min = NA_real_,
    site_response_max = NA_real_,
    response_lower_pointwise = h07_model_form_inverse(
      estimate - stats::qnorm(0.975) * se,
      spec
    ),
    response_upper_pointwise = h07_model_form_inverse(
      estimate + stats::qnorm(0.975) * se,
      spec
    ),
    prediction_mode = "zero_random_effect_population_curve",
    pointwise_interval_available = TRUE
  )
}

h07_sensitivity_inverse <- function(eta, spec) {
  if (identical(spec$response_family[[1L]], "tweedie_log")) {
    exp(eta)
  } else if (identical(spec$response_transform[[1L]], "log10_offset_0.1")) {
    10^eta - 0.1
  } else {
    eta
  }
}

h07_sensitivity_curve <- function(fit, frame, grid) {
  spec <- attr(frame, "h07_spec")
  newdata <- frame[rep(1L, length(grid)), , drop = FALSE]
  newdata$photoperiod_hours <- grid
  labels <- vapply(fit$smooth, function(smooth) smooth$label, character(1))
  excluded <- intersect(labels, c("s(site)", "s(site_participant)"))
  prediction <- stats::predict(
    fit,
    newdata = newdata,
    type = "link",
    se.fit = TRUE,
    unconditional = TRUE,
    exclude = excluded
  )
  estimate <- as.numeric(prediction$fit)
  se <- as.numeric(prediction$se.fit)
  tibble::tibble(
    photoperiod_hours = round(grid, 1),
    response_estimate = h07_sensitivity_inverse(estimate, spec),
    response_lower_pointwise = h07_sensitivity_inverse(
      estimate - normal_critical * se,
      spec
    ),
    response_upper_pointwise = h07_sensitivity_inverse(
      estimate + normal_critical * se,
      spec
    )
  )
}

h07_sensitivity_aggregate_support <- function(data) {
  if (nrow(data) == 0L) {
    return(c(
      sites = 0,
      participants = 0,
      participant_days = 0,
      max_site_share = NA_real_,
      passes = 0
    ))
  }
  participant_days <- sum(data$participant_days)
  max_site_share <- if (participant_days > 0) {
    max(data$participant_days / participant_days)
  } else {
    NA_real_
  }
  c(
    sites = nrow(data),
    participants = sum(data$participants),
    participant_days = participant_days,
    max_site_share = max_site_share,
    passes = as.numeric(
      nrow(data) >= 3L &&
        sum(data$participants) >= 20L &&
        participant_days >= 60L &&
        is.finite(max_site_share) &&
        max_site_share <= 0.50
    )
  )
}

h07_sensitivity_support_point <- function(frame, value) {
  by_site <- frame |>
    group_by(.data$site) |>
    summarise(
      q05 = stats::quantile(.data$photoperiod_hours, 0.05, names = FALSE),
      q95 = stats::quantile(.data$photoperiod_hours, 0.95, names = FALSE),
      participants = n_distinct(
        .data$Id[abs(.data$photoperiod_hours - .env$value) <= 0.5]
      ),
      participant_days = sum(abs(.data$photoperiod_hours - .env$value) <= 0.5),
      .groups = "drop"
    ) |>
    filter(
      .env$value >= .data$q05,
      .env$value <= .data$q95,
      .data$participants >= 5L,
      .data$participant_days >= 15L
    )
  pooled <- h07_sensitivity_aggregate_support(by_site)
  omitted <- levels(frame$site)
  loso <- all(vapply(
    omitted,
    function(site_value) {
      h07_sensitivity_aggregate_support(
        by_site |>
          filter(as.character(.data$site) != .env$site_value)
      )[["passes"]] == 1
    },
    logical(1)
  ))
  tibble::tibble(
    photoperiod_hours = round(value, 1),
    support_sites = pooled[["sites"]],
    support_participants = pooled[["participants"]],
    support_participant_days = pooled[["participant_days"]],
    support_max_site_share = pooled[["max_site_share"]],
    pooled_eligible = pooled[["passes"]] == 1,
    loso_eligible = loso
  )
}

h07_sensitivity_support <- function(frame, grid) {
  purrr::map_dfr(grid, ~ h07_sensitivity_support_point(frame, .x))
}

h07_compare_curves <- function(comparison) {
  curve_a <- all_curve_points |>
    filter(
      .data$run_id == comparison$run_a[[1L]],
      .data$metric_id == comparison$metric_id[[1L]]
    ) |>
    select(
      "photoperiod_hours",
      estimate_a = "response_estimate",
      pooled_a = "pooled_eligible"
    )
  curve_b <- all_curve_points |>
    filter(
      .data$run_id == comparison$run_b[[1L]],
      .data$metric_id == comparison$metric_id[[1L]]
    ) |>
    select(
      "photoperiod_hours",
      estimate_b = "response_estimate",
      pooled_b = "pooled_eligible"
    )
  common <- inner_join(curve_a, curve_b, by = "photoperiod_hours") |>
    filter(.data$pooled_a, .data$pooled_b) |>
    arrange(.data$photoperiod_hours) |>
    mutate(
      difference_b_minus_a = .data$estimate_b - .data$estimate_a,
      ratio_b_over_a = if_else(
        .data$estimate_a > 0 & .data$estimate_b > 0,
        .data$estimate_b / .data$estimate_a,
        NA_real_
      )
    )
  if (nrow(common) == 0L) {
    return(comparison |>
      mutate(
        common_supported_points = 0L,
        common_support_min = NA_real_,
        common_support_max = NA_real_,
        net_change_a = NA_real_,
        net_change_b = NA_real_,
        maximum_absolute_difference = NA_real_,
        median_absolute_difference = NA_real_,
        maximum_absolute_log_ratio = NA_real_,
        direction_agreement = NA,
        stability_classification = "NON_ESTIMABLE_NO_COMMON_POOLED_SUPPORT"
      ))
  }
  net_a <- common$estimate_a[[nrow(common)]] - common$estimate_a[[1L]]
  net_b <- common$estimate_b[[nrow(common)]] - common$estimate_b[[1L]]
  direction_agreement <- sign(net_a) == sign(net_b)
  comparison |>
    mutate(
      common_supported_points = nrow(common),
      common_support_min = min(common$photoperiod_hours),
      common_support_max = max(common$photoperiod_hours),
      net_change_a = net_a,
      net_change_b = net_b,
      maximum_absolute_difference = max(abs(common$difference_b_minus_a)),
      median_absolute_difference = stats::median(abs(common$difference_b_minus_a)),
      maximum_absolute_log_ratio = if (any(is.finite(common$ratio_b_over_a))) {
        max(abs(log(common$ratio_b_over_a)), na.rm = TRUE)
      } else {
        NA_real_
      },
      direction_agreement = direction_agreement,
      stability_classification = if_else(
        direction_agreement,
        "SAME_DIRECTION_MAGNITUDE_THRESHOLD_NOT_AVAILABLE",
        "DIRECTION_SENSITIVE"
      )
    )
}

h07_derivative_grid <- function(frame) {
  seq(
    min(frame$photoperiod_hours),
    max(frame$photoperiod_hours),
    length.out = grid_points
  )
}

h07_derivatives <- function(
    fit,
    frame,
    method_id,
    type,
    eps,
    unconditional,
    boundary_aware = FALSE) {
  grid <- h07_derivative_grid(frame)
  newdata <- frame[rep(1L, length(grid)), , drop = FALSE]
  newdata$photoperiod_hours <- grid

  derivative_call <- function(difference_type) {
    gratia::derivatives(
      fit,
      select = "s(photoperiod_hours)",
      data = newdata,
      order = 1L,
      type = difference_type,
      eps = eps,
      interval = "confidence",
      level = confidence_level,
      unconditional = unconditional,
      frequentist = FALSE,
      partial_match = FALSE
    ) |>
      as_tibble()
  }

  derivative <- derivative_call(type)
  if (boundary_aware) {
    forward <- derivative_call("forward")
    backward <- derivative_call("backward")
    derivative[1L, ] <- forward[1L, ]
    derivative[nrow(derivative), ] <- backward[nrow(backward), ]
  }

  required <- c(
    ".smooth",
    ".derivative",
    ".se",
    ".crit",
    ".lower_ci",
    ".upper_ci",
    "photoperiod_hours"
  )
  if (!all(required %in% names(derivative)) || nrow(derivative) != grid_points) {
    h07_abort("Unexpected H07 derivative output")
  }

  derivative |>
    transmute(
      method_id = method_id,
      photoperiod_hours = .data$photoperiod_hours,
      derivative_estimate = .data$.derivative,
      derivative_se = .data$.se,
      critical_value = .data$.crit,
      derivative_lower = .data$.lower_ci,
      derivative_upper = .data$.upper_ci,
      pointwise_detected_increase = .data$.lower_ci > 0,
      pointwise_detected_decrease = .data$.upper_ci < 0,
      pointwise_compatible_with_zero =
        .data$.lower_ci <= 0 & .data$.upper_ci >= 0
    ) |>
    arrange(.data$photoperiod_hours) |>
    mutate(
      zero_compatible_to_recorded_end =
        rev(cumall(rev(.data$pointwise_compatible_with_zero))),
      previous_point_detected_increase = lag(
        .data$pointwise_detected_increase,
        default = FALSE
      ),
      qualifying_transition =
        .data$previous_point_detected_increase &
        .data$pointwise_compatible_with_zero &
        .data$zero_compatible_to_recorded_end,
      derivative_state = case_when(
        .data$pointwise_detected_increase ~ "POINTWISE_DETECTED_INCREASE",
        .data$pointwise_detected_decrease ~ "POINTWISE_DETECTED_DECREASE",
        TRUE ~ "POINTWISE_COMPATIBLE_WITH_ZERO"
      )
    )
}

h07_summary <- function(points) {
  transition_index <- which(points$qualifying_transition)
  transition_index <- if (length(transition_index)) {
    transition_index[[1L]]
  } else {
    NA_integer_
  }
  positive_index <- which(points$pointwise_detected_increase)
  negative_index <- which(points$pointwise_detected_decrease)
  has_transition <- is.finite(transition_index)
  end_index <- nrow(points)

  disposition <- if (has_transition) {
    "DERIVATIVE_DEFINED_PLATEAU_PATTERN"
  } else if (length(positive_index) == 0L) {
    "NO_POINTWISE_DETECTED_PRIOR_INCREASE"
  } else if (points$pointwise_detected_increase[[end_index]]) {
    "POINTWISE_DETECTED_INCREASE_AT_RECORDED_END"
  } else if (
    length(negative_index) > 0L &&
      any(negative_index > max(positive_index))
  ) {
    "LATER_POINTWISE_DETECTED_DECREASE"
  } else {
    "NO_SUSTAINED_ZERO_COMPATIBLE_TAIL"
  }

  tibble::tibble(
    method_id = points$method_id[[1L]],
    grid_points = nrow(points),
    recorded_photoperiod_min = min(points$photoperiod_hours),
    recorded_photoperiod_max = max(points$photoperiod_hours),
    any_pointwise_detected_increase = length(positive_index) > 0L,
    any_pointwise_detected_decrease = length(negative_index) > 0L,
    plateau_pattern = has_transition,
    last_detected_increase = if (length(positive_index)) {
      points$photoperiod_hours[[max(positive_index)]]
    } else {
      NA_real_
    },
    plateau_transition_lower = if (has_transition) {
      points$photoperiod_hours[[transition_index - 1L]]
    } else {
      NA_real_
    },
    plateau_start = if (has_transition) {
      points$photoperiod_hours[[transition_index]]
    } else {
      NA_real_
    },
    plateau_tail_span_hours = if (has_transition) {
      points$photoperiod_hours[[end_index]] -
        points$photoperiod_hours[[transition_index]]
    } else {
      NA_real_
    },
    plateau_start_fraction_of_recorded_range = if (has_transition) {
      (points$photoperiod_hours[[transition_index]] -
         points$photoperiod_hours[[1L]]) /
        (points$photoperiod_hours[[end_index]] -
           points$photoperiod_hours[[1L]])
    } else {
      NA_real_
    },
    derivative_before_transition = if (has_transition) {
      points$derivative_estimate[[transition_index - 1L]]
    } else {
      NA_real_
    },
    derivative_before_lower = if (has_transition) {
      points$derivative_lower[[transition_index - 1L]]
    } else {
      NA_real_
    },
    derivative_before_upper = if (has_transition) {
      points$derivative_upper[[transition_index - 1L]]
    } else {
      NA_real_
    },
    derivative_at_plateau_start = if (has_transition) {
      points$derivative_estimate[[transition_index]]
    } else {
      NA_real_
    },
    derivative_at_plateau_start_lower = if (has_transition) {
      points$derivative_lower[[transition_index]]
    } else {
      NA_real_
    },
    derivative_at_plateau_start_upper = if (has_transition) {
      points$derivative_upper[[transition_index]]
    } else {
      NA_real_
    },
    derivative_at_recorded_end = points$derivative_estimate[[end_index]],
    derivative_at_recorded_end_lower = points$derivative_lower[[end_index]],
    derivative_at_recorded_end_upper = points$derivative_upper[[end_index]],
    disposition = disposition
  )
}

read_h07_table <- function(file) {
  readr::read_csv(
    file.path(h07_paths$tables, file),
    show_col_types = FALSE,
    na = ""
  )
}

h07_read_variant_map <- function(path, placement) {
  readRDS(path) |>
    transmute(
      placement = .env$placement,
      site = as.character(.data$site),
      Id = as.character(.data$Id),
      local_date = as.Date(.data$local_date),
      exact_period_value = .data$longest_bout_above_250_exact_only_sensitivity_h,
      exact_period_identifiable =
        as.logical(.data$longest_bout_above_250_exact_identifiable),
      corrected_dose_value = .data$dose_corrected_medi_lx_h,
      observed_dose_value = .data$dose_observed_medi_lx_h
    )
}

h07_override_from_variant <- function(placement, value_column) {
  map <- variant_map |>
    filter(.data$placement == .env$placement) |>
    select(all_of(key_columns), variant_value = all_of(value_column))
  function(frame) {
    frame |>
      left_join(map, by = key_columns, relationship = "one-to-one") |>
      mutate(original_value = .data$variant_value) |>
      select(-"variant_value")
  }
}

h07_keys_for_run <- function(run, metric_id) {
  switch(
    run$key_rule[[1L]],
    paired = paired_keys |>
      filter(.data$metric_id == .env$metric_id) |>
      select(all_of(key_columns)),
    preparation_common = preparation_common_keys |>
      filter(
        .data$placement == run$placement[[1L]],
        .data$metric_id == .env$metric_id
      ) |>
      select(all_of(key_columns)),
    exact_period = exact_period_keys |>
      filter(.data$placement == run$placement[[1L]]) |>
      select(all_of(key_columns)),
    dose_common = dose_common_keys |>
      filter(.data$placement == run$placement[[1L]]) |>
      select(all_of(key_columns)),
    all_available = NULL,
    h07_abort("Unknown H07 sensitivity key rule: %s", run$key_rule[[1L]])
  )
}

h07_override_for_run <- function(run) {
  value_column <- run$value_column[[1L]]
  if (is.na(value_column) || !nzchar(value_column)) return(NULL)
  h07_override_from_variant(run$placement[[1L]], value_column)
}
