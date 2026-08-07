source("scripts/hypotheses/H07/h07_stage2_core.R")

pilot_draws <- 100L
pilot_seed_base <- 202608060L
central_step_hours <- 0.01
normal_critical <- stats::qnorm(0.975)

h07_stage2_inverse_response <- function(eta, spec) {
  if (identical(spec$response_family[[1L]], "tweedie_log")) {
    exp(eta)
  } else if (identical(spec$response_transform[[1L]], "log10_offset_0.1")) {
    10^eta - 0.1
  } else {
    eta
  }
}

h07_stage2_response_derivative <- function(eta, derivative_eta, spec) {
  if (identical(spec$response_family[[1L]], "tweedie_log")) {
    exp(eta) * derivative_eta
  } else if (identical(spec$response_transform[[1L]], "log10_offset_0.1")) {
    log(10) * 10^eta * derivative_eta
  } else {
    derivative_eta
  }
}

h07_stage2_derivative_gradient <- function(
    X,
    D,
    eta,
    derivative_eta,
    spec) {
  if (identical(spec$response_family[[1L]], "tweedie_log")) {
    multiplier <- exp(eta)
    D * multiplier + X * (multiplier * derivative_eta)
  } else if (identical(spec$response_transform[[1L]], "log10_offset_0.1")) {
    multiplier <- log(10) * 10^eta
    D * multiplier + X * (log(10) * multiplier * derivative_eta)
  } else {
    D
  }
}

h07_stage2_random_effect_labels <- function(fit) {
  labels <- vapply(fit$smooth, function(smooth) smooth$label, character(1))
  intersect(labels, c("s(site)", "s(site_participant)"))
}

h07_stage2_prediction_data <- function(frame, photoperiod_hours) {
  template <- frame[rep(1L, length(photoperiod_hours)), , drop = FALSE]
  template$photoperiod_hours <- photoperiod_hours
  template
}

h07_stage2_population_curve <- function(fit, frame, spec, grid) {
  newdata <- h07_stage2_prediction_data(frame, grid)
  excluded <- h07_stage2_random_effect_labels(fit)
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
    response_estimate = h07_stage2_inverse_response(eta, spec),
    response_lower_pointwise = h07_stage2_inverse_response(
      eta - normal_critical * se_eta,
      spec
    ),
    response_upper_pointwise = h07_stage2_inverse_response(
      eta + normal_critical * se_eta,
      spec
    )
  )
}

h07_stage2_covariance_draws <- function(mean, covariance, draws, seed) {
  covariance <- (covariance + t(covariance)) / 2
  decomposition <- eigen(covariance, symmetric = TRUE)
  tolerance <- max(abs(decomposition$values)) * 1e-10
  if (any(decomposition$values < -tolerance)) {
    h07_stage2_abort("The H07 unconditional covariance is not positive semidefinite")
  }
  values <- pmax(decomposition$values, 0)
  set.seed(seed)
  standard <- matrix(
    stats::rnorm(length(mean) * draws),
    nrow = length(mean),
    ncol = draws
  )
  sweep(
    decomposition$vectors %*% (sqrt(values) * standard),
    1L,
    mean,
    "+"
  )
}

h07_stage2_derivative_pilot <- function(
    fit,
    frame,
    spec,
    grid,
    eligible,
    seed) {
  started <- proc.time()[["elapsed"]]
  newdata <- h07_stage2_prediction_data(frame, grid)
  plus <- newdata
  minus <- newdata
  plus$photoperiod_hours <- plus$photoperiod_hours + central_step_hours
  minus$photoperiod_hours <- minus$photoperiod_hours - central_step_hours
  excluded <- h07_stage2_random_effect_labels(fit)
  X <- stats::predict(
    fit,
    newdata = newdata,
    type = "lpmatrix",
    exclude = excluded
  )
  X_plus <- stats::predict(
    fit,
    newdata = plus,
    type = "lpmatrix",
    exclude = excluded
  )
  X_minus <- stats::predict(
    fit,
    newdata = minus,
    type = "lpmatrix",
    exclude = excluded
  )
  D <- (X_plus - X_minus) / (2 * central_step_hours)
  coefficients <- stats::coef(fit)
  covariance <- if (!is.null(fit$Vc)) fit$Vc else fit$Vp
  eta <- as.numeric(X %*% coefficients)
  derivative_eta <- as.numeric(D %*% coefficients)
  derivative <- h07_stage2_response_derivative(eta, derivative_eta, spec)
  gradient <- h07_stage2_derivative_gradient(
    X,
    D,
    eta,
    derivative_eta,
    spec
  )
  derivative_se <- sqrt(pmax(rowSums((gradient %*% covariance) * gradient), 0))
  coefficient_draws <- h07_stage2_covariance_draws(
    coefficients,
    covariance,
    pilot_draws,
    seed
  )
  eta_draws <- X %*% coefficient_draws
  derivative_eta_draws <- D %*% coefficient_draws
  derivative_draws <- h07_stage2_response_derivative(
    eta_draws,
    derivative_eta_draws,
    spec
  )
  usable <- eligible & is.finite(derivative_se) & derivative_se > 0
  maximum_statistics <- if (any(usable)) {
    apply(
      abs(sweep(
        derivative_draws[usable, , drop = FALSE],
        1L,
        derivative[usable],
        "-"
      ) / derivative_se[usable]),
      2L,
      max
    )
  } else {
    rep(NA_real_, pilot_draws)
  }
  simultaneous_critical <- if (any(is.finite(maximum_statistics))) {
    as.numeric(stats::quantile(
      maximum_statistics,
      0.95,
      names = FALSE,
      na.rm = TRUE,
      type = 8
    ))
  } else {
    NA_real_
  }
  elapsed <- proc.time()[["elapsed"]] - started
  list(
    points = tibble::tibble(
      photoperiod_hours = grid,
      derivative_estimate = derivative,
      derivative_se = derivative_se,
      derivative_lower_pointwise =
        derivative - normal_critical * derivative_se,
      derivative_upper_pointwise =
        derivative + normal_critical * derivative_se,
      derivative_lower_simultaneous_pilot =
        derivative - simultaneous_critical * derivative_se,
      derivative_upper_simultaneous_pilot =
        derivative + simultaneous_critical * derivative_se,
      pooled_eligible = eligible
    ),
    audit = tibble::tibble(
      pilot_status = "PILOT_NOT_FOR_INFERENCE_OR_MANUSCRIPT_REPORTING",
      draws = pilot_draws,
      seed = seed,
      finite_difference = "central",
      central_step_hours = central_step_hours,
      covariance = if (!is.null(fit$Vc)) {
        "unconditional_Vc"
      } else {
        "conditional_Vp"
      },
      eligible_grid_points = sum(usable),
      simultaneous_critical_pilot = simultaneous_critical,
      elapsed_seconds = elapsed,
      projected_10000_seconds = elapsed * (10000 / pilot_draws)
    )
  )
}

h07_stage2_aggregate_local_support <- function(data) {
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

h07_stage2_support_at_point <- function(frame, grid_value) {
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
  pooled <- h07_stage2_aggregate_local_support(by_site)
  omitted_sites <- levels(frame$site)
  loso_eligible <- all(vapply(
    omitted_sites,
    function(omitted_site) {
      h07_stage2_aggregate_local_support(
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

h07_stage2_support_grid <- function(frame) {
  grid <- seq(
    floor(min(frame$photoperiod_hours) * 10) / 10,
    ceiling(max(frame$photoperiod_hours) * 10) / 10,
    by = 0.1
  )
  purrr::map_dfr(grid, ~ h07_stage2_support_at_point(frame, .x))
}

h07_stage2_pairwise_concurvity <- function(
    checkpoint,
    target_pattern) {
  fit <- checkpoint$fit
  pairwise <- tryCatch(
    mgcv::concurvity(fit, full = FALSE),
    error = function(error) NULL
  )
  if (is.null(pairwise)) return(tibble::tibble())
  purrr::imap_dfr(pairwise, function(matrix, measure) {
    target <- grep(target_pattern, colnames(matrix), value = TRUE)
    if (length(target) != 1L) return(tibble::tibble())
    tibble::tibble(
      run_id = checkpoint$run_id,
      metric_id = checkpoint$metric_id,
      model_id = checkpoint$model_id,
      measure = measure,
      supplier_term = rownames(matrix),
      target_term = target,
      concurvity = as.numeric(matrix[, target])
    )
  })
}

h07_stage2_residual_summary <- function(fit, frame, spec) {
  residual <- as.numeric(stats::residuals(fit, type = "pearson"))
  fitted_response_scale <- as.numeric(stats::fitted(fit))
  fitted_natural <- if (identical(spec$response_family[[1L]], "tweedie_log")) {
    # fitted.gam() is already on the response scale for a log-link Tweedie fit.
    fitted_response_scale
  } else {
    h07_stage2_inverse_response(fitted_response_scale, spec)
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

h07_stage2_tweedie_pilot <- function(fit, frame, seed) {
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
    pilot_draws,
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
    pilot_status = "PILOT_NOT_FOR_INFERENCE_OR_MANUSCRIPT_REPORTING",
    draws = pilot_draws,
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
    elapsed_seconds = elapsed,
    projected_10000_seconds = elapsed * (10000 / pilot_draws)
  )
}

main_registry <- tidyr::crossing(
  placement = c("near_eye", "chest"),
  metric_id = h07_stage2_metric_ids
) |>
  left_join(
    h07_stage2_metric_contract |>
      select("metric_id", "metric_order", "manuscript_name"),
    by = "metric_id"
  ) |>
  arrange(factor(.data$placement, levels = c("near_eye", "chest")), .data$metric_order) |>
  mutate(run_id = paste("primary", .data$placement, sep = "__"))

support_points <- tibble::tibble()
site_support <- tibble::tibble()
curve_points <- tibble::tibble()
curve_summary <- tibble::tibble()
derivative_points <- tibble::tibble()
derivative_pilot_audit <- tibble::tibble()
pairwise_concurvity <- tibble::tibble()
residual_summary <- tibble::tibble()
tweedie_pilot <- tibble::tibble()

for (row_index in seq_len(nrow(main_registry))) {
  run <- main_registry[row_index, , drop = FALSE]
  frame <- readRDS(file.path(
    h07_stage2_paths$models,
    "frames",
    run$run_id,
    paste0(run$metric_id, ".rds")
  ))
  spec <- attr(frame, "h07_spec")
  support <- h07_stage2_support_grid(frame)
  checkpoint <- readRDS(file.path(
    h07_stage2_paths$models,
    "fits",
    run$run_id,
    run$metric_id,
    "adapted_photoperiod_smooth.rds"
  ))
  fit <- checkpoint$fit
  curve <- h07_stage2_population_curve(
    fit,
    frame,
    spec,
    support$photoperiod_hours
  ) |>
    left_join(support, by = "photoperiod_hours")
  derivative <- h07_stage2_derivative_pilot(
    fit,
    frame,
    spec,
    support$photoperiod_hours,
    support$pooled_eligible,
    pilot_seed_base + run$metric_order + if_else(run$placement == "chest", 100L, 0L)
  )
  identity <- tibble::tibble(
    run_id = run$run_id,
    placement = run$placement,
    metric_id = run$metric_id,
    metric_order = run$metric_order,
    manuscript_name = run$manuscript_name
  )
  support_points <- bind_rows(
    support_points,
    bind_cols(identity[rep(1L, nrow(support)), ], support)
  )
  site_support <- bind_rows(
    site_support,
    frame |>
      mutate(site = as.character(.data$site)) |>
      group_by(.data$site) |>
      summarise(
        participants = n_distinct(.data$Id),
        participant_days = n(),
        first_date = min(.data$local_date),
        last_date = max(.data$local_date),
        abs_latitude_deg = unique(.data$abs_latitude_deg),
        photoperiod_min = min(.data$photoperiod_hours),
        photoperiod_max = max(.data$photoperiod_hours),
        .groups = "drop"
      ) |>
      mutate(
        run_id = run$run_id,
        placement = run$placement,
        metric_id = run$metric_id,
        metric_order = run$metric_order,
        manuscript_name = run$manuscript_name,
        .before = 1L
      )
  )
  curve_points <- bind_rows(
    curve_points,
    bind_cols(identity[rep(1L, nrow(curve)), ], curve)
  )
  eligible_curve <- curve |>
    filter(.data$pooled_eligible)
  curve_summary <- bind_rows(
    curve_summary,
    identity |>
      mutate(
        observed_grid_min = min(curve$photoperiod_hours),
        observed_grid_max = max(curve$photoperiod_hours),
        pooled_eligible_points = nrow(eligible_curve),
        loso_eligible_points = sum(curve$loso_eligible),
        supported_grid_min = if (nrow(eligible_curve)) {
          min(eligible_curve$photoperiod_hours)
        } else {
          NA_real_
        },
        supported_grid_max = if (nrow(eligible_curve)) {
          max(eligible_curve$photoperiod_hours)
        } else {
          NA_real_
        },
        supported_response_first = if (nrow(eligible_curve)) {
          eligible_curve$response_estimate[[1L]]
        } else {
          NA_real_
        },
        supported_response_last = if (nrow(eligible_curve)) {
          eligible_curve$response_estimate[[nrow(eligible_curve)]]
        } else {
          NA_real_
        },
        supported_response_difference =
          .data$supported_response_last - .data$supported_response_first,
        supported_response_ratio = if_else(
          .data$supported_response_first > 0,
          .data$supported_response_last / .data$supported_response_first,
          NA_real_
        ),
        any_negative_point_estimate = any(curve$response_estimate < 0),
        any_negative_pointwise_lower = any(curve$response_lower_pointwise < 0),
        any_above_24_hour_point_estimate = if (spec$display_unit[[1L]] == "h") {
          any(curve$response_estimate > 24)
        } else {
          NA
        },
        support_disposition = if_else(
          sum(curve$loso_eligible) == 0L,
          "NO_LOSO_STABLE_GRID_POINT",
          "HAS_LOSO_STABLE_GRID_POINTS"
        )
      )
  )
  derivative_points <- bind_rows(
    derivative_points,
    bind_cols(identity[rep(1L, nrow(derivative$points)), ], derivative$points)
  )
  derivative_pilot_audit <- bind_rows(
    derivative_pilot_audit,
    bind_cols(identity, derivative$audit)
  )
  for (model_id in c(
    "registered_tensor",
    "adapted_photoperiod_smooth",
    "adapted_photoperiod_expanded_basis",
    "adapted_photoperiod_fixed_site"
  )) {
    model_checkpoint <- readRDS(file.path(
      h07_stage2_paths$models,
      "fits",
      run$run_id,
      run$metric_id,
      paste0(model_id, ".rds")
    ))
    target_pattern <- if (model_id == "registered_tensor") {
      "^te\\(abs_latitude_deg"
    } else {
      "^s\\(photoperiod_hours"
    }
    pairwise_concurvity <- bind_rows(
      pairwise_concurvity,
      h07_stage2_pairwise_concurvity(model_checkpoint, target_pattern) |>
        mutate(
          placement = run$placement,
          metric_order = run$metric_order,
          manuscript_name = run$manuscript_name,
          .after = "run_id"
        )
    )
  }
  residual_summary <- bind_rows(
    residual_summary,
    bind_cols(
      identity,
      h07_stage2_residual_summary(fit, frame, spec)
    )
  )
  if (identical(spec$response_family[[1L]], "tweedie_log")) {
    tweedie_pilot <- bind_rows(
      tweedie_pilot,
      bind_cols(
        identity,
        h07_stage2_tweedie_pilot(
          fit,
          frame,
          pilot_seed_base + 1000L + run$metric_order +
            if_else(run$placement == "chest", 100L, 0L)
        )
      )
    )
  }
  message(sprintf("H07 MAIN DIAGNOSTICS DONE %s / %s", run$run_id, run$metric_id))
  rm(frame, fit, checkpoint, curve, derivative)
  invisible(gc())
}

eligible_support_points <- support_points |>
  group_by(.data$run_id, .data$metric_id) |>
  arrange(.data$photoperiod_hours, .by_group = TRUE) |>
  mutate(
    eligible_change = .data$loso_eligible != lag(
      .data$loso_eligible,
      default = FALSE
    ),
    support_run = cumsum(.data$eligible_change)
  ) |>
  ungroup() |>
  filter(.data$loso_eligible)

support_runs <- if (nrow(eligible_support_points) == 0L) {
  tibble::tibble(
    run_id = character(),
    placement = character(),
    metric_id = character(),
    metric_order = integer(),
    manuscript_name = character(),
    support_run = integer(),
    lower = double(),
    upper = double(),
    span_hours = double(),
    sustained_one_hour = logical()
  )
} else {
  eligible_support_points |>
    group_by(
      .data$run_id,
      .data$placement,
      .data$metric_id,
      .data$metric_order,
      .data$manuscript_name,
      .data$support_run
    ) |>
    summarise(
      lower = min(.data$photoperiod_hours),
      upper = max(.data$photoperiod_hours),
      span_hours = .data$upper - .data$lower,
      sustained_one_hour = .data$span_hours >= 1 - 1e-8,
      .groups = "drop"
    )
}

h07_stage2_write_table(support_points, "H07_main_support_grid.csv")
h07_stage2_write_table(support_runs, "H07_main_support_runs.csv")
h07_stage2_write_table(site_support, "H07_main_site_support.csv")
h07_stage2_write_table(curve_points, "H07_main_curve_points.csv")
h07_stage2_write_table(curve_summary, "H07_main_curve_summary.csv")
h07_stage2_write_table(derivative_points, "H07_main_derivative_pilot_points.csv")
h07_stage2_write_table(
  derivative_pilot_audit,
  "H07_main_derivative_pilot_runtime.csv"
)
h07_stage2_write_table(
  pairwise_concurvity,
  "H07_main_pairwise_concurvity.csv"
)
h07_stage2_write_table(
  residual_summary,
  "H07_main_residual_distribution_summary.csv"
)
h07_stage2_write_table(
  tweedie_pilot,
  "H07_main_tweedie_distribution_pilot.csv"
)

curve_plot_data <- curve_points |>
  mutate(
    placement_label = recode(
      .data$placement,
      near_eye = "Near eye — primary",
      chest = "Chest — complementary"
    ),
    manuscript_name = factor(
      .data$manuscript_name,
      levels = h07_stage2_metric_contract$manuscript_name
    )
  )

for (placement_value in c("near_eye", "chest")) {
  plot_data <- curve_plot_data |>
    filter(.data$placement == .env$placement_value)
  support_subtitle <- if (any(plot_data$pooled_eligible)) {
    paste(
      "Blue: pooled-support estimate with pointwise 95% CI.\n",
      "Grey: outside the pooled support rule."
    )
  } else {
    paste(
      "No grid point passes the pooled support rule.\n",
      "All curves are grey descriptive context only."
    )
  }
  plot <- ggplot(plot_data, aes(.data$photoperiod_hours, .data$response_estimate)) +
    geom_line(colour = "#9ca3af", linewidth = 0.55) +
    geom_ribbon(
      data = ~ filter(.x, .data$pooled_eligible),
      aes(
        ymin = .data$response_lower_pointwise,
        ymax = .data$response_upper_pointwise
      ),
      inherit.aes = TRUE,
      fill = "#3b82f6",
      alpha = 0.18,
      colour = NA
    ) +
    geom_line(
      data = ~ filter(.x, .data$pooled_eligible),
      colour = "#1d4ed8",
      linewidth = 0.85
    ) +
    facet_wrap(
      vars(.data$manuscript_name),
      scales = "free_y",
      ncol = 3,
      labeller = label_wrap_gen(27)
    ) +
    scale_x_continuous(breaks = seq(10, 20, by = 2)) +
    labs(
      x = "Civil photoperiod (h)",
      y = "Estimated metric value",
      title = unique(plot_data$placement_label),
      subtitle = support_subtitle
    ) +
    theme_minimal(base_size = 10) +
    theme(
      panel.grid.minor = element_blank(),
      strip.text = element_text(face = "bold", size = 9),
      plot.title = element_text(face = "bold", size = 14),
      plot.subtitle = element_text(size = 10, margin = margin(b = 10)),
      plot.title.position = "plot",
      plot.margin = margin(10, 10, 10, 10),
      axis.title = element_text(size = 10)
    )
  ggplot2::ggsave(
    file.path(
      h07_stage2_paths$figures,
      paste0("H07_main_curves_", placement_value, ".png")
    ),
    plot,
    width = 13,
    height = 10,
    units = "in",
    dpi = 180,
    bg = "white"
  )
}

derivative_plot_data <- derivative_points |>
  filter(.data$placement == "near_eye") |>
  mutate(
    manuscript_name = factor(
      .data$manuscript_name,
      levels = h07_stage2_metric_contract$manuscript_name
    )
  )
derivative_plot <- ggplot(
  derivative_plot_data,
  aes(.data$photoperiod_hours, .data$derivative_estimate)
) +
  geom_hline(yintercept = 0, colour = "#4b5563", linewidth = 0.35) +
  geom_ribbon(
    data = ~ filter(.x, .data$pooled_eligible),
    aes(
      ymin = .data$derivative_lower_pointwise,
      ymax = .data$derivative_upper_pointwise
    ),
    fill = "#60a5fa",
    alpha = 0.22,
    colour = NA
  ) +
  geom_line(
    data = ~ filter(.x, .data$pooled_eligible),
    colour = "#1d4ed8",
    linewidth = 0.8
  ) +
  geom_line(
    data = ~ filter(.x, .data$pooled_eligible),
    aes(y = .data$derivative_lower_simultaneous_pilot),
    colour = "#b91c1c",
    linewidth = 0.45,
    linetype = 2
  ) +
  geom_line(
    data = ~ filter(.x, .data$pooled_eligible),
    aes(y = .data$derivative_upper_simultaneous_pilot),
    colour = "#b91c1c",
    linewidth = 0.45,
    linetype = 2
  ) +
  facet_wrap(
    vars(.data$manuscript_name),
    scales = "free_y",
    ncol = 3,
    labeller = label_wrap_gen(27)
  ) +
  scale_x_continuous(breaks = scales::breaks_pretty(n = 3)) +
  labs(
    x = "Civil photoperiod (h)",
    y = "Response-scale change per photoperiod hour",
    title = "PILOT — near-eye photoperiod derivatives",
    subtitle = paste(
      "Blue: pointwise 95% CI; red dashed: 100-draw pilot simultaneous band.",
      "Neither tests a ceiling."
    )
  ) +
  theme_minimal(base_size = 10) +
  theme(
    panel.grid.minor = element_blank(),
    strip.text = element_text(face = "bold", size = 9),
    plot.title = element_text(face = "bold", size = 14),
    plot.subtitle = element_text(size = 10, margin = margin(b = 10)),
    plot.title.position = "plot",
    plot.margin = margin(10, 10, 10, 10)
  )
ggplot2::ggsave(
  file.path(h07_stage2_paths$figures, "H07_derivative_pilot_near_eye.png"),
  derivative_plot,
  width = 13,
  height = 10,
  units = "in",
  dpi = 180,
  bg = "white"
)

message("H07 Stage 2 main diagnostic and curve artifacts complete")
