
log_sum_exp <- function(values) {
  maximum <- max(values)
  maximum + log(sum(exp(values - maximum)))
}

beta_binomial_cdf <- function(y, n, mu, phi) {
  if (y < 0L) {
    return(0)
  }
  if (y >= n) {
    return(1)
  }
  support <- 0:y
  log_probability <- ba_boundary_log_beta_binomial(
    support,
    n,
    mu,
    phi
  )
  exp(log_sum_exp(log_probability))
}

correlation_with_interval <- function(x, y) {
  complete <- stats::complete.cases(x, y)
  x <- x[complete]
  y <- y[complete]
  count <- length(x)
  correlation <- if (count > 1L) stats::cor(x, y) else NA_real_
  if (count > 3L && is.finite(correlation) && abs(correlation) < 1) {
    fisher <- atanh(correlation)
    half_width <- stats::qnorm(0.975) / sqrt(count - 3)
    lower <- tanh(fisher - half_width)
    upper <- tanh(fisher + half_width)
  } else {
    lower <- NA_real_
    upper <- NA_real_
  }
  list(
    pairs = count,
    correlation = correlation,
    lower_95 = lower,
    upper_95 = upper
  )
}

conditional_predictions <- function(bundle) {
  design <- bundle$design_object$data
  frame <- bundle$design_object$frame
  parameters <- bundle$parameter_list
  participant_row <- design$part_index + 1L
  participant_effect <- rowSums(
    design$Z_mu_part * parameters$b_mu_part[participant_row, , drop = FALSE]
  )
  eta_mu <- as.numeric(design$X_mu %*% parameters$beta_mu) +
    participant_effect
  eta_zero <- as.numeric(design$X_zero %*% parameters$beta_zero)
  eta_one <- as.numeric(design$X_one %*% parameters$beta_one)
  eta_disp <- as.numeric(design$X_disp %*% parameters$beta_disp)
  mu <- stats::plogis(eta_mu)
  phi <- exp(eta_disp)
  weights <- ba_boundary_component_weights(
    eta_zero,
    eta_one,
    one_active = design$one_active == 1L,
    use_zero_component = TRUE
  )
  n <- design$n
  alpha <- mu * phi
  beta <- (1 - mu) * phi
  beta_zero <- exp(lbeta(alpha, beta + n) - lbeta(alpha, beta))
  beta_one <- exp(lbeta(alpha + n, beta) - lbeta(alpha, beta))
  exact_zero_probability <- weights$pi_zero + weights$pi_beta * beta_zero
  exact_one_probability <- weights$pi_one + weights$pi_beta * beta_one
  mixed_probability <- 1 - exact_zero_probability - exact_one_probability
  conditional_mean <- weights$pi_one + weights$pi_beta * mu
  beta_variance <- mu * (1 - mu) * (phi + n) / (n * (phi + 1))
  conditional_variance <-
    weights$pi_one +
    weights$pi_beta * (mu^2 + beta_variance) -
    conditional_mean^2
  list(
    frame = frame,
    n = n,
    y = design$y,
    mu = mu,
    phi = phi,
    pi_zero = weights$pi_zero,
    pi_one = weights$pi_one,
    pi_beta = weights$pi_beta,
    exact_zero_probability = exact_zero_probability,
    exact_one_probability = exact_one_probability,
    mixed_probability = mixed_probability,
    conditional_mean = conditional_mean,
    conditional_variance = conditional_variance,
    fixed_linear_predictor_variance = rowSums(
      (design$X_mu %*%
        bundle$covariance_fixed[
          seq_len(ncol(design$X_mu)),
          seq_len(ncol(design$X_mu)),
          drop = FALSE
        ]) *
        design$X_mu
    )
  )
}

randomized_quantile_residuals <- function(predictions, seed) {
  rows <- seq_along(predictions$y)
  lower <- numeric(length(rows))
  upper <- numeric(length(rows))
  for (row in rows) {
    y <- predictions$y[[row]]
    n <- predictions$n[[row]]
    beta_lower <- beta_binomial_cdf(
      y - 1L,
      n,
      predictions$mu[[row]],
      predictions$phi[[row]]
    )
    beta_upper <- beta_binomial_cdf(
      y,
      n,
      predictions$mu[[row]],
      predictions$phi[[row]]
    )
    lower[[row]] <-
      predictions$pi_beta[[row]] *
      beta_lower +
      if (y > 0L) predictions$pi_zero[[row]] else 0
    upper[[row]] <-
      predictions$pi_beta[[row]] *
      beta_upper +
      predictions$pi_zero[[row]] +
      if (y == n) predictions$pi_one[[row]] else 0
  }
  lower <- pmin(pmax(lower, 0), 1)
  upper <- pmin(pmax(upper, lower), 1)
  set.seed(seed)
  uniform <- lower + stats::runif(length(rows)) * (upper - lower)
  uniform <- pmin(pmax(uniform, 1e-12), 1 - 1e-12)
  list(
    lower_cdf = lower,
    upper_cdf = upper,
    scaled_residual = uniform,
    quantile_residual = stats::qnorm(uniform)
  )
}

simulate_conditional <- function(predictions, simulations, seed) {
  set.seed(seed)
  rows <- length(predictions$y)
  output <- matrix(0L, nrow = rows, ncol = simulations)
  for (simulation in seq_len(simulations)) {
    component_draw <- stats::runif(rows)
    simulated <- integer(rows)
    one <- component_draw >= predictions$pi_zero &
      component_draw < predictions$pi_zero + predictions$pi_one
    beta <- component_draw >= predictions$pi_zero + predictions$pi_one
    simulated[one] <- predictions$n[one]
    if (any(beta)) {
      beta_probability <- stats::rbeta(
        sum(beta),
        predictions$mu[beta] * predictions$phi[beta],
        (1 - predictions$mu[beta]) * predictions$phi[beta]
      )
      simulated[beta] <- stats::rbinom(
        sum(beta),
        size = predictions$n[beta],
        prob = beta_probability
      )
    }
    output[, simulation] <- simulated
  }
  output
}

summarize_calibration <- function(data, by_columns, grouping) {
  output <- data[,
    .(
      state_rows = .N,
      participants = data.table::uniqueN(participant_id),
      behavioral_days = data.table::uniqueN(behavioral_day_id),
      valid_minutes = sum(valid_minutes),
      observed_adherence = sum(brown_yes) / sum(valid_minutes),
      predicted_adherence = sum(
        conditional_mean * valid_minutes
      ) /
        sum(valid_minutes),
      observed_all_zero = mean(exact_zero),
      predicted_all_zero = mean(exact_zero_probability),
      observed_all_one = mean(exact_one),
      predicted_all_one = mean(exact_one_probability),
      observed_mixed = mean(!exact_zero & !exact_one),
      predicted_mixed = mean(mixed_probability),
      mean_pearson_residual = mean(pearson_residual),
      mean_scaled_residual = mean(scaled_residual),
      sd_scaled_residual = stats::sd(scaled_residual)
    ),
    by = by_columns
  ]
  output[, `:=`(
    grouping = grouping,
    adherence_observed_minus_predicted = observed_adherence -
      predicted_adherence,
    all_zero_observed_minus_predicted = observed_all_zero - predicted_all_zero,
    all_one_observed_minus_predicted = observed_all_one - predicted_all_one,
    mixed_observed_minus_predicted = observed_mixed - predicted_mixed
  )]
  output
}

summarize_boundaries <- function(
  data,
  simulated,
  by_columns,
  grouping,
  sample_id
) {
  groups <- data[, .(row_indices = list(.I)), by = by_columns]
  data.table::rbindlist(lapply(seq_len(nrow(groups)), function(group_row) {
    indices <- groups$row_indices[[group_row]]
    simulated_zero <- colSums(simulated[indices, , drop = FALSE] == 0L)
    simulated_one <- colSums(
      simulated[indices, , drop = FALSE] == data$valid_minutes[indices]
    )
    simulated_mixed <- length(indices) - simulated_zero - simulated_one
    group_values <- groups[
      group_row,
      setdiff(names(groups), "row_indices"),
      with = FALSE
    ]
    data.table::rbindlist(lapply(
      list(
        list(
          boundary = "all-no period",
          observed = sum(data$exact_zero[indices]),
          expected = sum(data$exact_zero_probability[indices]),
          simulated = simulated_zero
        ),
        list(
          boundary = "mixed period",
          observed = sum(!data$exact_zero[indices] & !data$exact_one[indices]),
          expected = sum(data$mixed_probability[indices]),
          simulated = simulated_mixed
        ),
        list(
          boundary = "all-yes period",
          observed = sum(data$exact_one[indices]),
          expected = sum(data$exact_one_probability[indices]),
          simulated = simulated_one
        )
      ),
      function(boundary_result) {
        cbind(
          data.table::data.table(
            sample_id = sample_id,
            grouping = grouping
          ),
          group_values,
          data.table::data.table(
            boundary = boundary_result$boundary,
            observed_periods = boundary_result$observed,
            analytic_expected_periods = boundary_result$expected,
            simulation_median = stats::median(boundary_result$simulated),
            simulation_lower_95 = unname(stats::quantile(
              boundary_result$simulated,
              0.025
            )),
            simulation_upper_95 = unname(stats::quantile(
              boundary_result$simulated,
              0.975
            ))
          )
        )
      }
    ))
  }))
}

derive_diagnostics <- function(sample_id, model_path) {
  bundle <- readRDS(model_path)
  predictions <- conditional_predictions(bundle)
  frame <- predictions$frame
  residuals <- randomized_quantile_residuals(
    predictions,
    seed = 20260815L
  )
  simulations <- simulate_conditional(
    predictions,
    simulations = bootstrap_count(250L),
    seed = 20260814L
  )

  row_data <- data.table::as.data.table(frame)[, .(
    participant_id,
    behavioral_day_id,
    participant_state_id,
    behavior_date = as.Date(behavior_date),
    analysis_state = as.character(analysis_state),
    site = as.character(site),
    day_type = as.character(day_type),
    support_band,
    expected_minutes,
    valid_minutes,
    support_fraction,
    brown_yes,
    brown_no,
    brown_fraction,
    exact_zero,
    exact_one
  )]
  row_data[,
    denominator_band := data.table::fcase(
      valid_minutes <= 5L,
      "1 to 5 valid minutes",
      valid_minutes <= 30L,
      "6 to 30 valid minutes",
      valid_minutes <= 180L,
      "31 to 180 valid minutes",
      valid_minutes <= 480L,
      "181 to 480 valid minutes",
      default = "more than 480 valid minutes"
    )
  ]
  row_data[, `:=`(
    sample_id = sample_id,
    state_display = unname(state_label[analysis_state]),
    conditional_mu = predictions$mu,
    conditional_phi = predictions$phi,
    extra_all_zero_probability = predictions$pi_zero,
    extra_all_one_probability = predictions$pi_one,
    beta_binomial_component_probability = predictions$pi_beta,
    exact_zero_probability = predictions$exact_zero_probability,
    exact_one_probability = predictions$exact_one_probability,
    mixed_probability = predictions$mixed_probability,
    conditional_mean = predictions$conditional_mean,
    conditional_variance = predictions$conditional_variance,
    pearson_residual = (brown_fraction - predictions$conditional_mean) /
      sqrt(pmax(predictions$conditional_variance, 1e-12)),
    lower_cdf = residuals$lower_cdf,
    upper_cdf = residuals$upper_cdf,
    scaled_residual = residuals$scaled_residual,
    quantile_residual = residuals$quantile_residual,
    fixed_linear_predictor_variance = predictions$fixed_linear_predictor_variance
  )]

  calibration <- data.table::rbindlist(
    list(
      summarize_calibration(row_data, "analysis_state", "state"),
      summarize_calibration(row_data, "site", "site"),
      summarize_calibration(row_data, "day_type", "day_type"),
      summarize_calibration(
        row_data,
        c("analysis_state", "day_type"),
        "state_day_type"
      ),
      summarize_calibration(row_data, "denominator_band", "denominator_band"),
      summarize_calibration(row_data, "support_band", "support_band"),
      summarize_calibration(
        row_data,
        c("analysis_state", "site", "day_type"),
        "state_site_day_type"
      ),
      summarize_calibration(
        row_data,
        c("analysis_state", "support_band"),
        "state_support_band"
      ),
      summarize_calibration(
        row_data,
        c("analysis_state", "denominator_band"),
        "state_denominator_band"
      )
    ),
    use.names = TRUE,
    fill = TRUE
  )
  calibration[, sample_id := sample_id]

  boundary_prediction <- data.table::rbindlist(
    list(
      summarize_boundaries(
        row_data,
        simulations,
        "analysis_state",
        "state",
        sample_id
      ),
      summarize_boundaries(
        row_data,
        simulations,
        c("analysis_state", "day_type"),
        "state_day_type",
        sample_id
      ),
      summarize_boundaries(
        row_data,
        simulations,
        c("analysis_state", "site", "day_type"),
        "state_site_day_type",
        sample_id
      )
    ),
    use.names = TRUE,
    fill = TRUE
  )
  boundary_prediction[,
    outside_simulation_95 := observed_periods < simulation_lower_95 |
      observed_periods > simulation_upper_95
  ]
  boundary_prediction[,
    endpoint_check_applicable := grouping == "state" &
      boundary != "mixed period" &
      !(analysis_state == "Wake outside the three hours before sleep" &
        boundary == "all-yes period")
  ]

  residual_group_summary <- data.table::rbindlist(
    list(
      row_data[,
        .(
          rows = .N,
          mean_scaled_residual = mean(scaled_residual),
          sd_scaled_residual = stats::sd(scaled_residual),
          q05_scaled_residual = unname(stats::quantile(scaled_residual, 0.05)),
          q50_scaled_residual = unname(stats::quantile(scaled_residual, 0.50)),
          q95_scaled_residual = unname(stats::quantile(scaled_residual, 0.95)),
          mean_quantile_residual = mean(quantile_residual),
          sd_quantile_residual = stats::sd(quantile_residual)
        ),
        by = analysis_state
      ][, grouping := "state"],
      row_data[,
        .(
          rows = .N,
          mean_scaled_residual = mean(scaled_residual),
          sd_scaled_residual = stats::sd(scaled_residual),
          q05_scaled_residual = unname(stats::quantile(scaled_residual, 0.05)),
          q50_scaled_residual = unname(stats::quantile(scaled_residual, 0.50)),
          q95_scaled_residual = unname(stats::quantile(scaled_residual, 0.95)),
          mean_quantile_residual = mean(quantile_residual),
          sd_quantile_residual = stats::sd(quantile_residual)
        ),
        by = site
      ][, grouping := "site"],
      row_data[,
        .(
          rows = .N,
          mean_scaled_residual = mean(scaled_residual),
          sd_scaled_residual = stats::sd(scaled_residual),
          q05_scaled_residual = unname(stats::quantile(scaled_residual, 0.05)),
          q50_scaled_residual = unname(stats::quantile(scaled_residual, 0.50)),
          q95_scaled_residual = unname(stats::quantile(scaled_residual, 0.95)),
          mean_quantile_residual = mean(quantile_residual),
          sd_quantile_residual = stats::sd(quantile_residual)
        ),
        by = day_type
      ][, grouping := "day_type"]
    ),
    use.names = TRUE,
    fill = TRUE
  )
  residual_group_summary[, sample_id := sample_id]

  residual_patterns <- data.table::rbindlist(lapply(
    c(
      "conditional_mean",
      "exact_zero_probability",
      "exact_one_probability",
      "valid_minutes",
      "expected_minutes",
      "support_fraction"
    ),
    function(variable) {
      data.table::rbindlist(lapply(
        unique(row_data$analysis_state),
        function(state) {
          selected <- row_data[analysis_state == state]
          data.table::data.table(
            sample_id = sample_id,
            analysis_state = state,
            predictor = variable,
            pairs = nrow(selected),
            pearson_residual_correlation = stats::cor(
              selected[[variable]],
              selected$pearson_residual
            ),
            quantile_residual_correlation = stats::cor(
              selected[[variable]],
              selected$quantile_residual
            )
          )
        }
      ))
    }
  ))

  state_wide <- data.table::dcast(
    row_data,
    behavioral_day_id ~ analysis_state,
    value.var = "quantile_residual"
  )
  states <- unique(row_data$analysis_state)
  state_pairs <- utils::combn(states, 2L, simplify = FALSE)
  state_residual_covariance <- data.table::rbindlist(lapply(
    state_pairs,
    function(pair) {
      complete <- stats::complete.cases(state_wide[, ..pair])
      first <- state_wide[[pair[[1L]]]][complete]
      second <- state_wide[[pair[[2L]]]][complete]
      data.table::data.table(
        sample_id = sample_id,
        state_1 = pair[[1L]],
        state_2 = pair[[2L]],
        complete_behavioral_days = sum(complete),
        covariance = stats::cov(first, second),
        correlation = stats::cor(first, second)
      )
    }
  ))

  temporal_pairs <- data.table::copy(row_data)
  data.table::setorder(temporal_pairs, participant_state_id, behavior_date)
  temporal_pairs[,
    `:=`(
      lag_behavior_date = data.table::shift(behavior_date),
      lag_pearson_residual = data.table::shift(pearson_residual),
      lag_quantile_residual = data.table::shift(quantile_residual)
    ),
    by = participant_state_id
  ]
  temporal_pairs[, gap_days := as.integer(behavior_date - lag_behavior_date)]
  temporal_pairs <- temporal_pairs[
    !is.na(gap_days) & gap_days > 0 & is.finite(lag_pearson_residual)
  ]
  temporal_pairs[,
    gap_band := data.table::fcase(
      gap_days == 1L,
      "1 day",
      gap_days <= 3L,
      "2 to 3 days",
      gap_days <= 7L,
      "4 to 7 days",
      default = "more than 7 days"
    )
  ]
  temporal_correlation <- data.table::rbindlist(lapply(
    unique(row_data$analysis_state),
    function(state) {
      selected <- temporal_pairs[analysis_state == state]
      pearson <- correlation_with_interval(
        selected$pearson_residual,
        selected$lag_pearson_residual
      )
      quantile <- correlation_with_interval(
        selected$quantile_residual,
        selected$lag_quantile_residual
      )
      data.table::rbindlist(list(
        data.table::data.table(
          sample_id = sample_id,
          analysis_state = state,
          residual_type = "Pearson",
          pairs = pearson$pairs,
          correlation = pearson$correlation,
          lower_95 = pearson$lower_95,
          upper_95 = pearson$upper_95
        ),
        data.table::data.table(
          sample_id = sample_id,
          analysis_state = state,
          residual_type = "Randomized quantile",
          pairs = quantile$pairs,
          correlation = quantile$correlation,
          lower_95 = quantile$lower_95,
          upper_95 = quantile$upper_95
        )
      ))
    }
  ))
  temporal_correlation[,
    temporal_trigger := residual_type == "Pearson" &
      abs(correlation) >= 0.20 &
      (lower_95 > 0 | upper_95 < 0)
  ]
  temporal_gap_summary <- temporal_pairs[,
    .(
      pairs = .N,
      median_gap_days = as.numeric(stats::median(gap_days)),
      maximum_gap_days = max(gap_days),
      pearson_lag_correlation = stats::cor(
        pearson_residual,
        lag_pearson_residual
      ),
      quantile_lag_correlation = stats::cor(
        quantile_residual,
        lag_quantile_residual
      )
    ),
    by = .(sample_id, analysis_state, gap_band)
  ]

  participant_influence <- row_data[,
    .(
      state_rows = .N,
      behavioral_days = data.table::uniqueN(behavioral_day_id),
      states = data.table::uniqueN(analysis_state),
      day_types = data.table::uniqueN(day_type),
      valid_minutes = sum(valid_minutes),
      mean_absolute_pearson_residual = mean(abs(pearson_residual)),
      maximum_absolute_pearson_residual = max(abs(pearson_residual)),
      mean_absolute_quantile_residual = mean(abs(quantile_residual)),
      maximum_absolute_quantile_residual = max(abs(quantile_residual)),
      maximum_fixed_linear_predictor_variance = max(
        fixed_linear_predictor_variance
      ),
      sum_fixed_linear_predictor_variance = sum(
        fixed_linear_predictor_variance
      )
    ),
    by = .(sample_id, participant_id, site)
  ]
  participant_influence[,
    valid_minute_share := valid_minutes / sum(valid_minutes)
  ]
  rank_columns <- c(
    "valid_minute_share",
    "mean_absolute_pearson_residual",
    "maximum_absolute_pearson_residual",
    "mean_absolute_quantile_residual",
    "maximum_absolute_quantile_residual",
    "maximum_fixed_linear_predictor_variance",
    "sum_fixed_linear_predictor_variance"
  )
  for (column in rank_columns) {
    participant_influence[,
      (paste0(column, "_percentile")) := data.table::frank(
        get(column),
        ties.method = "average"
      ) /
        .N
    ]
  }
  percentile_columns <- paste0(rank_columns, "_percentile")
  participant_influence[,
    influence_screen_score := do.call(pmax, c(.SD, na.rm = TRUE)),
    .SDcols = percentile_columns
  ]
  data.table::setorder(
    participant_influence,
    -influence_screen_score,
    participant_id
  )
  participant_influence[, influence_screen_rank := seq_len(.N)]
  participant_influence[,
    selected_for_bounded_refit := influence_screen_rank <= 5L
  ]

  overall_maximum_calibration_difference <- max(
    abs(calibration[
      grouping == "state_site_day_type",
      adherence_observed_minus_predicted
    ]),
    na.rm = TRUE
  )
  endpoint_check_passed <- !any(
    boundary_prediction$endpoint_check_applicable &
      boundary_prediction$outside_simulation_95
  )
  temporal_trigger <- any(temporal_correlation$temporal_trigger)
  assessment <- data.table::data.table(
    sample_id = sample_id,
    target = c(
      "overall_adherence",
      "endpoint_probabilities",
      "actual_date_temporal_dependence"
    ),
    status = c(
      if (
        overall_maximum_calibration_difference >= 0.10 ||
          temporal_trigger
      ) {
        "acceptable_with_limitations"
      } else {
        "acceptable"
      },
      if (endpoint_check_passed) "acceptable" else "not_acceptable",
      if (temporal_trigger) "triggered" else "acceptable"
    ),
    detail = c(
      sprintf(
        paste(
          "maximum absolute state-site-day-type adherence calibration",
          "difference %.3f"
        ),
        overall_maximum_calibration_difference
      ),
      sprintf(
        "%d of %d applicable state endpoint envelopes passed",
        sum(
          boundary_prediction$endpoint_check_applicable &
            !boundary_prediction$outside_simulation_95
        ),
        sum(boundary_prediction$endpoint_check_applicable)
      ),
      sprintf(
        "%d state residual series reached the temporal trigger",
        sum(temporal_correlation$temporal_trigger)
      )
    )
  )

  assessment <- data.table::rbindlist(list(
    assessment,
    data.table::data.table(
      sample_id = sample_id,
      target = "numerical_fit",
      status = bundle$fit_diagnostics$fit_status,
      detail = sprintf(
        "Optimizer convergence code %s; maximum absolute gradient %.6g; structural failure: %s",
        bundle$fit_diagnostics$convergence,
        bundle$fit_diagnostics$maximum_absolute_gradient,
        bundle$fit_diagnostics$structural_failure
      )
    )
  ))

  list(
    bundle = bundle,
    row_data = row_data,
    simulated_response = simulations,
    calibration = calibration,
    boundary_prediction = boundary_prediction,
    residual_group_summary = residual_group_summary,
    residual_patterns = residual_patterns,
    state_residual_covariance = state_residual_covariance,
    temporal_correlation = temporal_correlation,
    temporal_gap_summary = temporal_gap_summary,
    participant_influence = participant_influence,
    assessment = assessment
  )
}
