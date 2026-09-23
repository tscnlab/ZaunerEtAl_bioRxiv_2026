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
  exp(log_sum_exp(cs_log_beta_binomial(support, n, mu, phi)))
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

randomized_quantile_residuals <- function(predictions, seed) {
  rows <- seq_along(predictions$y)
  lower <- numeric(length(rows))
  upper <- numeric(length(rows))
  for (row in rows) {
    y <- predictions$y[[row]]
    n <- predictions$n[[row]]
    beta_lower <- beta_binomial_cdf(
      y - 1L, n, predictions$mu[[row]], predictions$phi[[row]]
    )
    beta_upper <- beta_binomial_cdf(
      y, n, predictions$mu[[row]], predictions$phi[[row]]
    )
    lower[[row]] <- predictions$pi_beta[[row]] * beta_lower +
      if (y > 0L) predictions$pi_zero[[row]] else 0
    upper[[row]] <- predictions$pi_beta[[row]] * beta_upper +
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
    beta_component <- component_draw >=
      predictions$pi_zero + predictions$pi_one
    simulated[one] <- predictions$n[one]
    if (any(beta_component)) {
      probability <- stats::rbeta(
        sum(beta_component),
        predictions$mu[beta_component] * predictions$phi[beta_component],
        (1 - predictions$mu[beta_component]) * predictions$phi[beta_component]
      )
      simulated[beta_component] <- stats::rbinom(
        sum(beta_component),
        size = predictions$n[beta_component],
        prob = probability
      )
    }
    output[, simulation] <- simulated
  }
  output
}

summarize_calibration <- function(data, by_columns, grouping) {
  result <- data[, .(
    rows = .N,
    participants = data.table::uniqueN(participant_cluster),
    cycles = data.table::uniqueN(association_cycle_cluster),
    valid_minutes = sum(target_valid_minutes),
    observed_adherence = sum(target_brown_yes) / sum(target_valid_minutes),
    predicted_adherence = sum(
      conditional_mean * target_valid_minutes
    ) / sum(target_valid_minutes),
    observed_all_zero = mean(target_exact_zero),
    predicted_all_zero = mean(exact_zero_probability),
    observed_all_one = mean(target_exact_one),
    predicted_all_one = mean(exact_one_probability),
    observed_mixed = mean(!target_exact_zero & !target_exact_one),
    predicted_mixed = mean(mixed_probability),
    mean_pearson_residual = mean(pearson_residual),
    mean_quantile_residual = mean(quantile_residual),
    sd_quantile_residual = stats::sd(quantile_residual)
  ), by = by_columns]
  result[, `:=`(
    grouping = grouping,
    adherence_observed_minus_predicted =
      observed_adherence - predicted_adherence,
    all_zero_observed_minus_predicted =
      observed_all_zero - predicted_all_zero,
    all_one_observed_minus_predicted =
      observed_all_one - predicted_all_one,
    mixed_observed_minus_predicted = observed_mixed - predicted_mixed
  )]
  result
}

summarize_predictive_boundaries <- function(
  data,
  simulations,
  by_columns,
  grouping,
  sample_id
) {
  groups <- data[, .(row_indices = list(.I)), by = by_columns]
  data.table::rbindlist(lapply(seq_len(nrow(groups)), function(group_row) {
    indices <- groups$row_indices[[group_row]]
    simulated_zero <- colSums(simulations[indices, , drop = FALSE] == 0L)
    simulated_one <- colSums(
      simulations[indices, , drop = FALSE] ==
        data$target_valid_minutes[indices]
    )
    simulated_mixed <- length(indices) - simulated_zero - simulated_one
    group_values <- groups[
      group_row,
      setdiff(names(groups), "row_indices"),
      with = FALSE
    ]
    data.table::rbindlist(lapply(list(
      list(
        boundary = "all-no period",
        observed = sum(data$target_exact_zero[indices]),
        expected = sum(data$exact_zero_probability[indices]),
        draws = simulated_zero
      ),
      list(
        boundary = "mixed period",
        observed = sum(
          !data$target_exact_zero[indices] & !data$target_exact_one[indices]
        ),
        expected = sum(data$mixed_probability[indices]),
        draws = simulated_mixed
      ),
      list(
        boundary = "all-yes period",
        observed = sum(data$target_exact_one[indices]),
        expected = sum(data$exact_one_probability[indices]),
        draws = simulated_one
      )
    ), function(boundary) {
      cbind(
        data.table::data.table(sample_id = sample_id, grouping = grouping),
        group_values,
        data.table::data.table(
          boundary = boundary$boundary,
          observed_periods = boundary$observed,
          analytic_expected_periods = boundary$expected,
          simulation_median = stats::median(boundary$draws),
          simulation_lower_95 = unname(stats::quantile(boundary$draws, 0.025)),
          simulation_upper_95 = unname(stats::quantile(boundary$draws, 0.975))
        )
      )
    }))
  }))
}

cs_diagnose <- function(sample_id, bundle, sample_offset) {
  if (
    isTRUE(bundle$fit_check$structural_failure) ||
      bundle$specification$random_rung != "R3"
  ) {
    stop(sprintf("Selected model is not an retained R3 fit: %s", sample_id), call. = FALSE)
  }
  predictions <- cs_conditional_predictions(bundle)
  residuals <- randomized_quantile_residuals(
    predictions,
    seed = 20260815L + sample_offset
  )
  simulations <- simulate_conditional(
    predictions,
    simulations = 250L,
    seed = 20260814L + sample_offset
  )
  frame <- data.table::as.data.table(bundle$design_object$frame)
  row_data <- frame[, .(
    participant_cluster = as.character(participant_cluster),
    association_cycle_cluster = as.character(association_cycle_cluster),
    anchor_date = as.Date(anchor_date),
    site = as.character(site),
    day_type = as.character(day_type),
    target_state = as.character(target_state),
    wake_valid_minutes,
    wake_fraction,
    wake_support_fraction,
    target_expected_minutes,
    target_valid_minutes,
    target_brown_yes,
    target_brown_no,
    target_fraction,
    target_exact_zero,
    target_exact_one,
    target_support_fraction,
    wake_within_10pp,
    wake_between_centered_10pp,
    wake_free_fraction_centered_10pp
  )]
  row_data[, denominator_band := data.table::fcase(
    target_valid_minutes <= 30L, "1 to 30 valid minutes",
    target_valid_minutes <= 180L, "31 to 180 valid minutes",
    target_valid_minutes <= 480L, "181 to 480 valid minutes",
    default = "more than 480 valid minutes"
  )]
  row_data[, `:=`(
    sample_id = sample_id,
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
    lower_cdf = residuals$lower_cdf,
    upper_cdf = residuals$upper_cdf,
    scaled_residual = residuals$scaled_residual,
    quantile_residual = residuals$quantile_residual,
    pearson_residual = (
      target_fraction - predictions$conditional_mean
    ) / sqrt(pmax(predictions$conditional_variance, 1e-12))
  )]

  calibration <- data.table::rbindlist(list(
    summarize_calibration(row_data, "target_state", "target"),
    summarize_calibration(row_data, "site", "site"),
    summarize_calibration(row_data, "day_type", "day_type"),
    summarize_calibration(row_data, "denominator_band", "denominator_band"),
    summarize_calibration(
      row_data,
      c("target_state", "site", "day_type"),
      "target_site_day_type"
    ),
    summarize_calibration(
      row_data,
      c("target_state", "denominator_band"),
      "target_denominator_band"
    )
  ), use.names = TRUE, fill = TRUE)
  calibration[, sample_id := sample_id]

  boundary_prediction <- data.table::rbindlist(list(
    summarize_predictive_boundaries(
      row_data, simulations, "target_state", "target", sample_id
    ),
    summarize_predictive_boundaries(
      row_data,
      simulations,
      c("target_state", "site", "day_type"),
      "target_site_day_type",
      sample_id
    )
  ), use.names = TRUE, fill = TRUE)
  boundary_prediction[, outside_simulation_95 :=
    observed_periods < simulation_lower_95 |
      observed_periods > simulation_upper_95]
  boundary_prediction[, endpoint_check_applicable := grouping == "target"]

  residual_summary <- data.table::rbindlist(list(
    row_data[, .(
      rows = .N,
      mean_pearson_residual = mean(pearson_residual),
      sd_pearson_residual = stats::sd(pearson_residual),
      mean_quantile_residual = mean(quantile_residual),
      sd_quantile_residual = stats::sd(quantile_residual),
      q05_quantile_residual = unname(stats::quantile(quantile_residual, 0.05)),
      q50_quantile_residual = unname(stats::quantile(quantile_residual, 0.50)),
      q95_quantile_residual = unname(stats::quantile(quantile_residual, 0.95))
    ), by = target_state][, grouping := "target"],
    row_data[, .(
      rows = .N,
      mean_pearson_residual = mean(pearson_residual),
      sd_pearson_residual = stats::sd(pearson_residual),
      mean_quantile_residual = mean(quantile_residual),
      sd_quantile_residual = stats::sd(quantile_residual),
      q05_quantile_residual = unname(stats::quantile(quantile_residual, 0.05)),
      q50_quantile_residual = unname(stats::quantile(quantile_residual, 0.50)),
      q95_quantile_residual = unname(stats::quantile(quantile_residual, 0.95))
    ), by = site][, grouping := "site"]
  ), use.names = TRUE, fill = TRUE)
  residual_summary[, sample_id := sample_id]

  diagnostic_variables <- c(
    "conditional_mean", "exact_zero_probability", "exact_one_probability",
    "target_valid_minutes", "target_support_fraction",
    "wake_within_10pp", "wake_between_centered_10pp"
  )
  residual_patterns <- data.table::rbindlist(lapply(
    diagnostic_variables,
    function(variable) {
      row_data[, .(
        pairs = .N,
        pearson_residual_correlation = stats::cor(
          get(variable), pearson_residual
        ),
        quantile_residual_correlation = stats::cor(
          get(variable), quantile_residual
        )
      ), by = target_state][, predictor := variable]
    }
  ), use.names = TRUE, fill = TRUE)
  residual_patterns[, sample_id := sample_id]

  fixed_breaks <- c(-Inf, -1, -0.5, 0, 0.5, 1, Inf)
  fixed_labels <- c(
    "less than -10 pp", "-10 to -5 pp", "-5 to 0 pp",
    "0 to 5 pp", "5 to 10 pp", "more than 10 pp"
  )
  linearity <- data.table::rbindlist(lapply(
    c("wake_within_10pp", "wake_between_centered_10pp"),
    function(variable) {
      temporary <- data.table::copy(row_data)
      temporary[, predictor_bin := cut(
        get(variable),
        breaks = fixed_breaks,
        labels = fixed_labels,
        include.lowest = TRUE,
        right = FALSE
      )]
      temporary[, .(
        rows = .N,
        predictor_mean_10pp = mean(get(variable)),
        predictor_minimum_10pp = min(get(variable)),
        predictor_maximum_10pp = max(get(variable)),
        mean_pearson_residual = mean(pearson_residual),
        mean_quantile_residual = mean(quantile_residual)
      ), by = .(target_state, predictor_bin)][, predictor := variable]
    }
  ), use.names = TRUE, fill = TRUE)
  linearity[, sample_id := sample_id]

  temporal <- data.table::copy(row_data)
  data.table::setorder(temporal, participant_cluster, target_state, anchor_date)
  temporal[, `:=`(
    lag_date = data.table::shift(anchor_date),
    lag_pearson_residual = data.table::shift(pearson_residual),
    lag_quantile_residual = data.table::shift(quantile_residual)
  ), by = .(participant_cluster, target_state)]
  temporal[, gap_days := as.integer(anchor_date - lag_date)]
  temporal <- temporal[!is.na(gap_days) & gap_days > 0]
  temporal_correlation <- data.table::rbindlist(lapply(
    unique(row_data$target_state),
    function(target) {
      selected <- temporal[target_state == target]
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
          target_state = target,
          residual_type = "Pearson",
          pairs = pearson$pairs,
          correlation = pearson$correlation,
          lower_95 = pearson$lower_95,
          upper_95 = pearson$upper_95
        ),
        data.table::data.table(
          sample_id = sample_id,
          target_state = target,
          residual_type = "Randomized quantile",
          pairs = quantile$pairs,
          correlation = quantile$correlation,
          lower_95 = quantile$lower_95,
          upper_95 = quantile$upper_95
        )
      ))
    }
  ))
  temporal_correlation[, temporal_trigger :=
    residual_type == "Pearson" & abs(correlation) >= 0.20 &
      (lower_95 > 0 | upper_95 < 0)]
  temporal_gap_summary <- temporal[, .(
    adjacent_pairs = .N,
    one_day_gaps = sum(gap_days == 1L),
    two_day_gaps = sum(gap_days == 2L),
    gaps_over_two_days = sum(gap_days > 2L),
    median_gap_days = as.numeric(stats::median(gap_days)),
    maximum_gap_days = as.numeric(max(gap_days))
  ), by = .(sample_id, target_state)]

  mean_design_covariance <- bundle$covariance_fixed[
    seq_len(ncol(bundle$design_object$data$X_mu)),
    seq_len(ncol(bundle$design_object$data$X_mu)),
    drop = FALSE
  ]
  row_data[, fixed_linear_predictor_variance := rowSums(
    (bundle$design_object$data$X_mu %*% mean_design_covariance) *
      bundle$design_object$data$X_mu
  )]
  influence <- row_data[, .(
    rows = .N,
    cycles = data.table::uniqueN(association_cycle_cluster),
    targets = data.table::uniqueN(target_state),
    valid_minutes = sum(target_valid_minutes),
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
  ), by = .(participant_cluster)]
  influence[, valid_minute_share := valid_minutes / sum(valid_minutes)]
  rank_columns <- c(
    "valid_minute_share", "mean_absolute_pearson_residual",
    "maximum_absolute_pearson_residual", "mean_absolute_quantile_residual",
    "maximum_absolute_quantile_residual",
    "maximum_fixed_linear_predictor_variance",
    "sum_fixed_linear_predictor_variance"
  )
  for (column in rank_columns) {
    influence[, (paste0(column, "_percentile")) :=
      data.table::frank(get(column), ties.method = "average") / .N]
  }
  percentile_columns <- paste0(rank_columns, "_percentile")
  influence[, influence_screen_score :=
    do.call(pmax, c(.SD, na.rm = TRUE)), .SDcols = percentile_columns]
  data.table::setorder(influence, -influence_screen_score, participant_cluster)
  influence[, influence_screen_rank := seq_len(.N)]
  influence[, selected_for_bounded_refit := influence_screen_rank <= 5L]
  influence_summary <- influence[, .(
    sample_id = sample_id,
    participants_screened = .N,
    selected_participants = sum(selected_for_bounded_refit),
    selected_minimum_score = min(
      influence_screen_score[selected_for_bounded_refit]
    ),
    selected_maximum_score = max(
      influence_screen_score[selected_for_bounded_refit]
    ),
    selection_rule = paste(
      "top five by maximum percentile across denominator share,",
      "absolute residual, and fixed-design variance diagnostics"
    )
  )]

  maximum_calibration_difference <- max(abs(calibration[
    grouping == "target_site_day_type" & rows >= 10L,
    adherence_observed_minus_predicted
  ]), na.rm = TRUE)
  endpoint_check_passed <- !any(
    boundary_prediction$endpoint_check_applicable &
      boundary_prediction$outside_simulation_95
  )
  temporal_triggered <- any(temporal_correlation$temporal_trigger)
  assessment <- data.table::data.table(
    sample_id = sample_id,
    target = c(
      "overall_adherence", "endpoint_probabilities",
      "actual_date_temporal_dependence"
    ),
    status = c(
      if (maximum_calibration_difference >= 0.10 || temporal_triggered) {
        "acceptable_with_limitations"
      } else {
        "acceptable"
      },
      if (endpoint_check_passed) "acceptable" else "not_acceptable",
      if (temporal_triggered) "triggered" else "acceptable"
    ),
    detail = c(
      sprintf(
        paste(
          "maximum absolute target-site-day-type calibration difference",
          "among cells with at least 10 rows: %.3f"
        ),
        maximum_calibration_difference
      ),
      sprintf(
        "%d of %d target-level endpoint envelopes passed",
        sum(
          boundary_prediction$endpoint_check_applicable &
            !boundary_prediction$outside_simulation_95
        ),
        sum(boundary_prediction$endpoint_check_applicable)
      ),
      sprintf(
        "%d target Pearson series reached the specified trigger",
        sum(temporal_correlation$temporal_trigger)
      )
    )
  )

  list(
    row_data = row_data,
    simulations = simulations,
    calibration = calibration,
    boundary_prediction = boundary_prediction,
    residual_summary = residual_summary,
    residual_patterns = residual_patterns,
    linearity = linearity,
    temporal_correlation = temporal_correlation,
    temporal_gap_summary = temporal_gap_summary,
    influence = influence,
    influence_summary = influence_summary,
    assessment = assessment,
    predictive_seed = 20260814L + sample_offset,
    randomized_residual_seed = 20260815L + sample_offset
  )
}
