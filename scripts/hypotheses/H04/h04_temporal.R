# H04 exploratory temporal GAMs for fractionally weighted activity memberships.

h04_prepare_temporal_data <- function(frame) {
  data <- h04_add_activity_ar_sequences(frame)
  site_levels <- levels(droplevels(data$site))
  activity_levels <- levels(droplevels(data$activity))
  participant_levels <- sort(unique(as.character(data$participant)))
  day_levels <- sort(unique(as.character(data$participant_day)))
  data |>
    dplyr::mutate(
      site = factor(as.character(.data$site), levels = site_levels),
      activity = factor(
        as.character(.data$activity),
        levels = activity_levels
      ),
      participant = factor(
        as.character(.data$participant),
        levels = participant_levels
      ),
      participant_day = factor(
        as.character(.data$participant_day),
        levels = day_levels
      ),
      AR_start = as.logical(.data$AR_start)
    ) |>
    dplyr::arrange(
      .data$site,
      .data$participant,
      .data$participant_day,
      .data$activity,
      .data$activity_run_id,
      .data$interval_start_utc
    )
}

h04_temporal_lag_correlation <- function(residual, ar_start, lag = 1L) {
  sequence_id <- cumsum(ar_start)
  index <- seq_along(residual)
  earlier <- index - lag
  eligible <- earlier >= 1L
  eligible[eligible] <- sequence_id[index[eligible]] ==
    sequence_id[earlier[eligible]]
  complete <- eligible &
    is.finite(residual) &
    is.finite(residual[pmax(earlier, 1L)])
  if (sum(complete) < 3L) {
    return(c(correlation = NA_real_, pairs = sum(complete)))
  }
  c(
    correlation = stats::cor(
      residual[index[complete]],
      residual[earlier[complete]]
    ),
    pairs = sum(complete)
  )
}

h04_fit_temporal_bam <- function(formula, data, rho = 0) {
  s <- mgcv::s
  environment(formula) <- environment()
  captured <- h04_capture_warnings(mgcv::bam(
    formula = formula,
    data = data,
    family = mgcv::Tweedie(
      p = h04_specification()$working_tweedie_power,
      link = "log"
    ),
    weights = analysis_weight,
    method = "fREML",
    discrete = TRUE,
    rho = rho,
    AR.start = data$AR_start,
    knots = list(time_hour = c(0, 24)),
    nthreads = 1L,
    gc.level = 1L,
    drop.unused.levels = TRUE
  ))
  list(fit = captured$value, warnings = captured$warnings)
}

h04_fit_temporal_model <- function(frame, placement, formula_id) {
  formula <- h04_formula_set()[[formula_id]]
  if (is.null(formula)) {
    h04_abort("Unknown H04 temporal formula id: %s", formula_id)
  }
  data <- h04_prepare_temporal_data(frame)
  start <- proc.time()[["elapsed"]]
  preliminary <- h04_fit_temporal_bam(formula, data, rho = 0)
  pearson <- stats::residuals(preliminary$fit, type = "pearson")
  rho <- unname(h04_temporal_lag_correlation(
    pearson,
    data$AR_start,
    lag = 1L
  )["correlation"])
  if (!is.finite(rho)) {
    h04_abort("Could not estimate temporal rho for %s", placement)
  }
  rho <- pmin(0.95, pmax(-0.95, rho))
  preliminary_seconds <- proc.time()[["elapsed"]] - start
  rm(pearson)
  invisible(gc())
  final_start <- proc.time()[["elapsed"]]
  final <- h04_fit_temporal_bam(formula, data, rho = rho)
  final_seconds <- proc.time()[["elapsed"]] - final_start
  list(
    run_id = paste0(formula_id, "__", tolower(gsub("-", "_", placement))),
    placement = placement,
    formula_id = formula_id,
    formula = formula,
    data = data,
    final = final$fit,
    rho = rho,
    preliminary_warnings = preliminary$warnings,
    final_warnings = final$warnings,
    preliminary_seconds = preliminary_seconds,
    final_seconds = final_seconds,
    basis_variant = "global_cc_activity_site_thin_plate_sz",
    working_power = h04_specification()$working_tweedie_power
  )
}

h04_gam_convergence <- function(fit) {
  if (is.list(fit$outer.info) && !is.null(fit$outer.info$conv)) {
    return(as.character(fit$outer.info$conv))
  }
  if (is.logical(fit$converged) && length(fit$converged) == 1L) {
    return(
      if (isTRUE(fit$converged)) {
        "full convergence"
      } else {
        "not fully converged"
      }
    )
  }
  "not reported"
}

h04_smooth_labels <- function(fit) {
  vapply(fit$smooth, `[[`, character(1), "label")
}

h04_smooth_coefficient_indices <- function(fit, label) {
  matches <- which(h04_smooth_labels(fit) == label)
  if (length(matches) != 1L) {
    h04_abort(
      "Expected one H04 temporal smooth labelled `%s`; found %s",
      label,
      length(matches)
    )
  }
  seq.int(
    fit$smooth[[matches]]$first.para,
    fit$smooth[[matches]]$last.para
  )
}

h04_temporal_covariance <- function(fit) {
  covariance_result <- tryCatch(
    list(
      covariance = stats::vcov(fit, unconditional = TRUE),
      source = "stats::vcov(fit, unconditional = TRUE)"
    ),
    error = function(condition) {
      list(
        covariance = fit$Vp,
        source = "fit$Vp fallback after unconditional vcov error"
      )
    }
  )
  covariance <- covariance_result$covariance
  if (!all(is.finite(covariance))) {
    h04_abort("H04 temporal coefficient covariance is non-finite")
  }
  attr(covariance, "h04_covariance_source") <- covariance_result$source
  covariance
}

h04_temporal_residual <- function(object) {
  if (
    !is.null(object$final$std.rsd) &&
      length(object$final$std.rsd) == nrow(object$data)
  ) {
    object$final$std.rsd
  } else {
    stats::residuals(object$final, type = "pearson")
  }
}

h04_temporal_model_summary <- function(object) {
  fit <- object$final
  summary_fit <- summary(fit)
  residual <- h04_temporal_residual(object)
  lag_one <- h04_temporal_lag_correlation(
    residual,
    object$data$AR_start,
    1L
  )
  hessian <- fit$outer.info$hess
  hessian_values <- if (is.matrix(hessian) && all(is.finite(hessian))) {
    eigen(
      (hessian + t(hessian)) / 2,
      symmetric = TRUE,
      only.values = TRUE
    )$values
  } else {
    NA_real_
  }
  tibble::tibble(
    run_id = object$run_id,
    placement = object$placement,
    formula_id = object$formula_id,
    formula = h04_formula_text(object$formula),
    family = paste0(
      "mgcv::Tweedie(p = ",
      format(object$working_power, digits = 8),
      ", link = 'log')"
    ),
    observations_long_rows = nrow(object$data),
    unique_participant_hours = dplyr::n_distinct(
      object$data$analysis_hour_id
    ),
    effective_weighted_hours = sum(object$data$analysis_weight),
    participants = nlevels(object$data$participant),
    participant_days = nlevels(object$data$participant_day),
    sites = nlevels(object$data$site),
    activities = nlevels(object$data$activity),
    activity_runs = dplyr::n_distinct(object$data$activity_run_id),
    method = fit$method,
    discrete = TRUE,
    nthreads = 1L,
    rho = object$rho,
    rank = fit$rank,
    coefficients = length(stats::coef(fit)),
    total_edf = sum(fit$edf),
    adjusted_r_squared = summary_fit$r.sq,
    deviance_explained = summary_fit$dev.expl,
    residual_scale = summary_fit$scale,
    convergence = h04_gam_convergence(fit),
    converged = grepl("conver", h04_gam_convergence(fit), ignore.case = TRUE) &&
      !grepl("not", h04_gam_convergence(fit), ignore.case = TRUE),
    smoothing_gradient_maximum_absolute = if (
      is.null(fit$outer.info$grad) || any(!is.finite(fit$outer.info$grad))
    ) {
      NA_real_
    } else {
      max(abs(fit$outer.info$grad))
    },
    smoothing_hessian_minimum_eigenvalue = if (all(is.na(hessian_values))) {
      NA_real_
    } else {
      min(hessian_values)
    },
    smoothing_hessian_positive_definite = !all(is.na(hessian_values)) &&
      all(hessian_values > 0),
    standardized_residual_lag1 = unname(lag_one["correlation"]),
    standardized_residual_lag1_pairs = unname(lag_one["pairs"]),
    absolute_residual_fitted_spearman = stats::cor(
      abs(residual),
      stats::fitted(fit),
      method = "spearman"
    ),
    observed_zero_fraction_long = mean(object$data$geo_medi_1h == 0),
    preliminary_seconds = object$preliminary_seconds,
    final_seconds = object$final_seconds,
    preliminary_warning_count = length(object$preliminary_warnings),
    preliminary_warnings = paste(object$preliminary_warnings, collapse = " | "),
    final_warning_count = length(object$final_warnings),
    final_warnings = paste(object$final_warnings, collapse = " | ")
  )
}

h04_temporal_prediction_grid <- function(object, times = seq(0, 24, by = 0.5)) {
  data <- object$data
  tidyr::crossing(
    time_hour = times,
    activity = factor(
      levels(data$activity),
      levels = levels(data$activity)
    ),
    site = factor(levels(data$site), levels = levels(data$site))
  ) |>
    dplyr::mutate(
      participant = factor(
        levels(data$participant)[1L],
        levels = levels(data$participant)
      ),
      participant_day = factor(
        levels(data$participant_day)[1L],
        levels = levels(data$participant_day)
      ),
      AR_start = TRUE
    )
}

h04_temporal_curves <- function(
  object,
  times = seq(0, 24, by = 0.5),
  include_model_intervals = TRUE
) {
  fit <- object$final
  grid <- h04_temporal_prediction_grid(object, times)
  design <- stats::predict(fit, newdata = grid, type = "lpmatrix")
  participant_indices <- h04_smooth_coefficient_indices(
    fit,
    "s(time_hour,participant)"
  )
  day_indices <- h04_smooth_coefficient_indices(fit, "s(participant_day)")
  population_design <- design
  population_design[, c(participant_indices, day_indices)] <- 0
  beta <- stats::coef(fit)
  covariance <- if (include_model_intervals) {
    h04_temporal_covariance(fit)
  } else {
    NULL
  }
  covariance_source <- if (include_model_intervals) {
    attr(covariance, "h04_covariance_source")
  } else {
    "not calculated"
  }
  rows <- split(
    seq_len(nrow(grid)),
    interaction(
      grid$time_hour,
      grid$activity,
      drop = TRUE,
      lex.order = TRUE
    )
  )
  curves <- dplyr::bind_rows(lapply(rows, function(index) {
    x_bar <- colMeans(population_design[index, , drop = FALSE])
    eta <- drop(x_bar %*% beta)
    if (include_model_intervals) {
      variance <- drop(crossprod(x_bar, covariance %*% x_bar))
      se <- sqrt(max(variance, 0))
    } else {
      se <- NA_real_
    }
    tibble::tibble(
      run_id = object$run_id,
      placement = object$placement,
      time_hour = unique(grid$time_hour[index]),
      activity = as.character(unique(grid$activity[index])),
      estimated_mel_edi_lx = exp(eta),
      pointwise_conf_low_lx = if (is.finite(se)) {
        exp(eta - 1.96 * se)
      } else {
        NA_real_
      },
      pointwise_conf_high_lx = if (is.finite(se)) {
        exp(eta + 1.96 * se)
      } else {
        NA_real_
      },
      pointwise_log_se = se,
      sites_standardized = length(index),
      estimand = paste(
        "equal-site standardized conditional arithmetic mean;",
        "participant and participant-day smooths excluded"
      ),
      interval_type = if (include_model_intervals) {
        "pointwise_95_percent_conditional"
      } else {
        "no interval"
      },
      covariance_source = covariance_source,
      interval_critical_value = if (include_model_intervals) 1.96 else NA_real_,
      resampling_replicates = 0L,
      simultaneous_band = FALSE,
      curve_wide_inference = FALSE
    )
  }))
  curves |>
    dplyr::left_join(
      h04_activity_registry() |>
        dplyr::select(
          activity = "activity_label",
          "activity_code",
          "display_order"
        ),
      by = "activity",
      relationship = "many-to-one"
    ) |>
    dplyr::arrange(.data$display_order, .data$time_hour)
}

h04_temporal_reader_components <- function(
  object,
  times = seq(0, 24, by = 0.5)
) {
  fit <- object$final
  grid <- h04_temporal_prediction_grid(object, times)
  design <- stats::predict(fit, newdata = grid, type = "lpmatrix")
  participant_indices <- h04_smooth_coefficient_indices(
    fit,
    "s(time_hour,participant)"
  )
  day_indices <- h04_smooth_coefficient_indices(fit, "s(participant_day)")
  population_design <- design
  population_design[, c(participant_indices, day_indices)] <- 0
  global_indices <- h04_smooth_coefficient_indices(fit, "s(time_hour)")
  intercept <- match("(Intercept)", names(stats::coef(fit)))
  if (is.na(intercept)) {
    h04_abort("H04 temporal reader curves require an intercept")
  }
  beta <- stats::coef(fit)
  covariance <- h04_temporal_covariance(fit)
  covariance_source <- attr(covariance, "h04_covariance_source")
  registry <- h04_activity_registry()

  global_rows <- which(
    as.character(grid$activity) == levels(grid$activity)[1L] &
      as.character(grid$site) == levels(grid$site)[1L]
  )
  global_rows <- global_rows[order(grid$time_hour[global_rows])]
  global_design <- matrix(
    0,
    nrow = length(global_rows),
    ncol = ncol(population_design)
  )
  global_design[, c(intercept, global_indices)] <-
    population_design[global_rows, c(intercept, global_indices), drop = FALSE]
  global_eta <- drop(global_design %*% beta)
  global_variance <- rowSums((global_design %*% covariance) * global_design)
  global_se <- sqrt(pmax(global_variance, 0))
  global <- tibble::tibble(
    run_id = object$run_id,
    placement = object$placement,
    time_hour = grid$time_hour[global_rows],
    global_mel_edi_lx = exp(global_eta),
    pointwise_conf_low_lx = exp(global_eta - 1.96 * global_se),
    pointwise_conf_high_lx = exp(global_eta + 1.96 * global_se),
    pointwise_log_se = global_se,
    component_definition = paste(
      "intercept plus global cyclic time smooth; activity, site,",
      "participant, and participant-day deviations excluded"
    ),
    interval_type = "pointwise_95_percent_conditional",
    covariance_source = covariance_source,
    resampling_replicates = 0L,
    simultaneous_band = FALSE,
    curve_wide_inference = FALSE
  )

  activity_rows <- split(
    seq_len(nrow(grid)),
    interaction(
      grid$time_hour,
      grid$activity,
      drop = TRUE,
      lex.order = TRUE
    )
  )
  curve_rows <- vector("list", length(activity_rows))
  ratio_rows <- vector("list", length(activity_rows))
  row_index <- 0L
  for (indices in activity_rows) {
    row_index <- row_index + 1L
    x_bar <- colMeans(population_design[indices, , drop = FALSE])
    time_value <- unique(grid$time_hour[indices])
    activity_value <- as.character(unique(grid$activity[indices]))
    global_index <- match(time_value, global$time_hour)
    x_global <- global_design[global_index, ]
    eta <- drop(x_bar %*% beta)
    variance <- drop(crossprod(x_bar, covariance %*% x_bar))
    se <- sqrt(max(variance, 0))
    ratio_gradient <- x_bar - x_global
    ratio_eta <- drop(ratio_gradient %*% beta)
    ratio_variance <- drop(crossprod(
      ratio_gradient,
      covariance %*% ratio_gradient
    ))
    ratio_se <- sqrt(max(ratio_variance, 0))
    curve_rows[[row_index]] <- tibble::tibble(
      run_id = object$run_id,
      placement = object$placement,
      time_hour = time_value,
      activity = activity_value,
      estimated_mel_edi_lx = exp(eta),
      pointwise_conf_low_lx = exp(eta - 1.96 * se),
      pointwise_conf_high_lx = exp(eta + 1.96 * se),
      pointwise_log_se = se,
      sites_standardized = length(indices),
      estimand = paste(
        "equal-site standardized conditional arithmetic mean;",
        "participant and participant-day smooths excluded"
      ),
      interval_type = "pointwise_95_percent_conditional",
      covariance_source = covariance_source,
      interval_critical_value = 1.96,
      resampling_replicates = 0L,
      simultaneous_band = FALSE,
      curve_wide_inference = FALSE
    )
    ratio_rows[[row_index]] <- tibble::tibble(
      run_id = object$run_id,
      placement = object$placement,
      time_hour = time_value,
      activity = activity_value,
      ratio_to_global = exp(ratio_eta),
      ratio_conf_low = exp(ratio_eta - 1.96 * ratio_se),
      ratio_conf_high = exp(ratio_eta + 1.96 * ratio_se),
      pointwise_log_se = ratio_se,
      numerator = paste(
        "equal-site activity curve with participant and day terms excluded"
      ),
      denominator = "intercept plus global cyclic time smooth",
      interval_type = "pointwise_95_percent_conditional",
      covariance_source = covariance_source,
      interval_critical_value = 1.96,
      resampling_replicates = 0L,
      simultaneous_band = FALSE,
      curve_wide_inference = FALSE
    )
  }
  add_registry <- function(data) {
    data |>
      dplyr::left_join(
        registry |>
          dplyr::select(
            activity = "activity_label",
            "activity_code",
            "display_order"
          ),
        by = "activity",
        relationship = "many-to-one"
      ) |>
      dplyr::arrange(.data$display_order, .data$time_hour)
  }
  list(
    curves = add_registry(dplyr::bind_rows(curve_rows)),
    ratios = add_registry(dplyr::bind_rows(ratio_rows)),
    global = global
  )
}

h04_temporal_reader_weights <- function(data) {
  participant_counts <- data |>
    dplyr::distinct(.data$site, .data$participant) |>
    dplyr::count(.data$site, name = "participants_in_site")
  hour_counts <- data |>
    dplyr::distinct(
      .data$site,
      .data$participant,
      .data$analysis_hour_id
    ) |>
    dplyr::count(
      .data$site,
      .data$participant,
      name = "hours_in_participant"
    )
  weights <- data |>
    dplyr::select(
      "site",
      "participant",
      "analysis_weight"
    ) |>
    dplyr::left_join(
      participant_counts,
      by = "site",
      relationship = "many-to-one"
    ) |>
    dplyr::left_join(
      hour_counts,
      by = c("site", "participant"),
      relationship = "many-to-one"
    ) |>
    dplyr::mutate(
      weight = .data$analysis_weight /
        dplyr::n_distinct(data$site) /
        .data$participants_in_site /
        .data$hours_in_participant
    ) |>
    dplyr::pull(.data$weight)
  weights / sum(weights)
}

h04_gamm_variance_partition <- function(
  model,
  data,
  groups,
  weights,
  n_draws = 0L
) {
  if (!inherits(model, "gam")) {
    h04_abort("H04 temporal variance partition requires a gam")
  }
  if (!identical(as.integer(n_draws), 0L)) {
    h04_abort("H04 temporal point allocation does not authorize simulation")
  }
  terms <- as.matrix(stats::predict(model, newdata = data, type = "terms"))
  available <- colnames(terms)
  members <- unlist(groups, use.names = FALSE)
  if (
    is.null(names(groups)) || anyDuplicated(members) ||
      !setequal(members, available)
  ) {
    h04_abort("H04 temporal variance groups must partition all model terms")
  }
  components <- vapply(
    groups,
    function(labels) rowSums(terms[, labels, drop = FALSE]),
    numeric(nrow(terms))
  )
  colnames(components) <- names(groups)
  weights <- weights / sum(weights)
  means <- colSums(components * weights)
  centered <- sweep(components, 2L, means, "-")
  covariance <- crossprod(centered, centered * weights)
  total <- rowSums(components)
  total_mean <- sum(weights * total)
  total_variance <- sum(weights * (total - total_mean)^2)
  shapley <- rowSums(covariance)
  partial_unique <- vapply(seq_len(ncol(components)), function(index) {
    response <- components[, index]
    others <- components[, -index, drop = FALSE]
    design <- cbind(`(Intercept)` = 1, others)
    residual <- stats::lm.wfit(design, response, w = weights)$residuals
    residual_mean <- sum(weights * residual)
    sum(weights * (residual - residual_mean)^2)
  }, numeric(1))
  allocation <- tibble::tibble(
    group = colnames(components),
    component_variance = as.numeric(diag(covariance)),
    shapley = as.numeric(shapley),
    shapley_share = as.numeric(shapley / total_variance),
    partial_unique = as.numeric(partial_unique),
    partial_unique_share = as.numeric(partial_unique / total_variance)
  )
  list(
    allocation = allocation,
    covariance = covariance,
    total_variance = total_variance,
    shapley_efficiency_error = sum(shapley) - total_variance,
    reference_rows = nrow(data),
    reference_weight_sum = sum(weights)
  )
}

h04_temporal_reader_fit_summaries <- function(object) {
  weights <- h04_temporal_reader_weights(object$data)
  response <- object$data$geo_medi_1h
  fitted_mean <- stats::fitted(object$final)
  response_mean <- sum(weights * response)
  weighted_sse <- sum(weights * (response - fitted_mean)^2)
  weighted_sst <- sum(weights * (response - response_mean)^2)
  r_squared <- tibble::tibble(
    run_id = object$run_id,
    placement = object$placement,
    estimand = paste(
      "equal-site participant-balanced in-sample R-squared with each",
      "multi-select hour sharing one unit across its activity memberships"
    ),
    scale = "raw one-hour geometric melEDI (lx)",
    r_squared = 1 - weighted_sse / weighted_sst,
    weighted_sse = weighted_sse,
    weighted_sst = weighted_sst,
    weight_sum = sum(weights),
    sites_equal_weight = TRUE,
    participants_equal_within_site = TRUE,
    hours_equal_within_participant = TRUE,
    concurrent_memberships_fractionally_weighted = TRUE,
    uncertainty = "point estimate; no resampling interval computed"
  )
  expected_terms <- c(
    "s(time_hour)",
    "s(time_hour,activity)",
    "s(time_hour,site)",
    "s(time_hour,participant)",
    "s(participant_day)"
  )
  term_names <- colnames(stats::predict(object$final, type = "terms"))
  if (!setequal(term_names, expected_terms)) {
    h04_abort(
      "Unexpected H04 temporal terms for reader allocation: %s",
      paste(term_names, collapse = "; ")
    )
  }
  groups <- list(
    global_time = "s(time_hour)",
    activity_deviations = "s(time_hour,activity)",
    site_deviations = "s(time_hour,site)",
    participant_curves = "s(time_hour,participant)",
    participant_day_shifts = "s(participant_day)"
  )
  partition <- h04_gamm_variance_partition(
    object$final,
    object$data,
    groups,
    weights,
    n_draws = 0L
  )
  allocation <- partition$allocation |>
    dplyr::mutate(
      run_id = object$run_id,
      placement = object$placement,
      total_fitted_predictor_variance = partition$total_variance,
      shapley_efficiency_error = partition$shapley_efficiency_error,
      scale = "natural-log conditional-mean linear predictor",
      reference_distribution = paste(
        "sites equally weighted; participants equally weighted within site;",
        "hours equally weighted within participant; 1/k within hour"
      ),
      uncertainty = "point allocation; no simulation interval computed",
      .before = 1
    )
  covariance <- as.data.frame(as.table(partition$covariance)) |>
    tibble::as_tibble() |>
    dplyr::rename(
      group_1 = "Var1",
      group_2 = "Var2",
      covariance = "Freq"
    ) |>
    dplyr::mutate(
      run_id = object$run_id,
      placement = object$placement,
      scale = "natural-log conditional-mean linear predictor",
      .before = 1
    )
  list(r_squared = r_squared, allocation = allocation, covariance = covariance)
}

h04_temporal_uncertainty_contract <- function(curves) {
  required <- c(
    "placement",
    "interval_type",
    "covariance_source",
    "interval_critical_value",
    "resampling_replicates",
    "simultaneous_band",
    "curve_wide_inference"
  )
  missing <- setdiff(required, names(curves))
  if (length(missing) > 0L) {
    h04_abort(
      "H04 temporal curves lack uncertainty field(s): %s",
      paste(missing, collapse = ", ")
    )
  }
  curves |>
    dplyr::summarise(
      placement = dplyr::first(.data$placement),
      implementation = "H03-aligned fitted-coefficient covariance",
      interval_type = dplyr::first(.data$interval_type),
      covariance_source = dplyr::first(.data$covariance_source),
      interval_critical_value = dplyr::first(.data$interval_critical_value),
      response_scale = "log mean with exp() back-transformation",
      site_standardization = paste(
        "equal-site average of population design rows on the fitted",
        "log-mean scale, followed by one back-transformation"
      ),
      resampling_replicates = dplyr::first(.data$resampling_replicates),
      simultaneous_band = dplyr::first(.data$simultaneous_band),
      curve_wide_inference = dplyr::first(.data$curve_wide_inference),
      author_decision = "approved in H04 task on 2026-08-11"
    )
}

h04_temporal_bootstrap_supersession <- function(checkpoint_directory) {
  checkpoint_paths <- if (dir.exists(checkpoint_directory)) {
    list.files(
      checkpoint_directory,
      pattern = "[.]rds$",
      full.names = TRUE
    )
  } else {
    character()
  }
  checkpoint_status <- dplyr::bind_rows(lapply(
    checkpoint_paths,
    function(path) {
      checkpoint <- readRDS(path)
      checkpoint$status |>
        dplyr::mutate(checkpoint_file = basename(path), .before = 1)
    }
  ))
  if (nrow(checkpoint_status) == 0L) {
    return(tibble::tibble(
      placement = character(),
      placement_id = character(),
      completed_checkpoint_files = integer(),
      successful_checkpoint_files = integer(),
      unsuccessful_checkpoint_files = integer(),
      pilot_completion_status = character(),
      supersession_status = character(),
      superseded_by = character(),
      author_decision_date = character()
    ))
  }
  checkpoint_status |>
    dplyr::group_by(.data$placement, .data$placement_id) |>
    dplyr::summarise(
      completed_checkpoint_files = dplyr::n(),
      successful_checkpoint_files = sum(.data$successful %in% TRUE),
      unsuccessful_checkpoint_files = sum(!(.data$successful %in% TRUE)),
      .groups = "drop"
    ) |>
    dplyr::mutate(
      pilot_completion_status = "stopped before the 50-success target",
      supersession_status = paste(
        "preserved as superseded provenance; excluded from estimates,",
        "intervals, figures, tests, and scientific claims"
      ),
      superseded_by = paste(
        "H03-aligned fitted-coefficient covariance with pointwise 95%",
        "intervals and no curve-wide inference"
      ),
      author_decision_date = "2026-08-11"
    )
}

h04_temporal_endpoint_diagnostics <- function(object, curves) {
  activity <- curves |>
    dplyr::filter(.data$time_hour %in% c(0, 24)) |>
    dplyr::select(
      "placement",
      "activity",
      "activity_code",
      "display_order",
      "time_hour",
      "estimated_mel_edi_lx"
    ) |>
    tidyr::pivot_wider(
      names_from = "time_hour",
      values_from = "estimated_mel_edi_lx",
      names_prefix = "hour_"
    ) |>
    dplyr::mutate(
      endpoint_difference_lx = .data$hour_24 - .data$hour_0,
      endpoint_ratio_24_to_0 = .data$hour_24 / .data$hour_0,
      endpoint_absolute_log_ratio = abs(log(.data$endpoint_ratio_24_to_0)),
      global_component_cyclic = TRUE,
      activity_deviation_basis = "thin-plate sz; endpoint equality not imposed"
    )

  fit <- object$final
  data <- object$data
  grid <- tidyr::crossing(
    time_hour = c(0, 24),
    site = factor(levels(data$site), levels = levels(data$site))
  ) |>
    dplyr::mutate(
      activity = factor(
        levels(data$activity)[1L],
        levels = levels(data$activity)
      ),
      participant = factor(
        levels(data$participant)[1L],
        levels = levels(data$participant)
      ),
      participant_day = factor(
        levels(data$participant_day)[1L],
        levels = levels(data$participant_day)
      ),
      AR_start = TRUE
    )
  design <- stats::predict(fit, newdata = grid, type = "lpmatrix")
  global_indices <- h04_smooth_coefficient_indices(fit, "s(time_hour)")
  site_indices <- h04_smooth_coefficient_indices(fit, "s(time_hour,site)")
  intercept <- match("(Intercept)", names(stats::coef(fit)))
  allowed <- c(intercept, global_indices, site_indices)
  component_design <- matrix(0, nrow(design), ncol(design))
  component_design[, allowed] <- design[, allowed]
  site_rows <- split(seq_len(nrow(grid)), as.character(grid$site))
  site <- dplyr::bind_rows(lapply(names(site_rows), function(site_name) {
    rows <- site_rows[[site_name]]
    rows <- rows[order(grid$time_hour[rows])]
    eta <- drop(component_design[rows, , drop = FALSE] %*% stats::coef(fit))
    tibble::tibble(
      placement = object$placement,
      site = site_name,
      hour_0_lx = exp(eta[1L]),
      hour_24_lx = exp(eta[2L]),
      endpoint_difference_lx = exp(eta[2L]) - exp(eta[1L]),
      endpoint_ratio_24_to_0 = exp(eta[2L] - eta[1L]),
      endpoint_absolute_log_ratio = abs(eta[2L] - eta[1L]),
      global_component_cyclic = TRUE,
      site_deviation_basis = "thin-plate sz; endpoint equality not imposed"
    )
  }))

  global_grid <- grid[grid$site == levels(data$site)[1L], , drop = FALSE]
  global_design <- stats::predict(
    fit,
    newdata = global_grid,
    type = "lpmatrix"
  )
  global_only <- matrix(0, nrow(global_design), ncol(global_design))
  global_only[, c(intercept, global_indices)] <-
    global_design[, c(intercept, global_indices)]
  global_eta <- drop(global_only %*% stats::coef(fit))
  global <- tibble::tibble(
    placement = object$placement,
    hour_0_lx = exp(global_eta[1L]),
    hour_24_lx = exp(global_eta[2L]),
    endpoint_difference_lx = exp(global_eta[2L]) - exp(global_eta[1L]),
    endpoint_absolute_log_ratio = abs(global_eta[2L] - global_eta[1L]),
    acceptable_rule = "numerical equality for the cyclic global smooth"
  )
  list(activity = activity, site = site, global = global)
}

h04_temporal_support <- function(object) {
  object$data |>
    dplyr::mutate(clock_hour = floor(.data$time_hour) %% 24L) |>
    dplyr::group_by(.data$placement, .data$activity, .data$clock_hour) |>
    dplyr::summarise(
      unique_participant_hours = dplyr::n_distinct(.data$analysis_hour_id),
      long_rows = dplyr::n(),
      effective_weighted_hours = sum(.data$analysis_weight),
      participants = dplyr::n_distinct(.data$participant),
      participant_days = dplyr::n_distinct(.data$participant_day),
      sites = dplyr::n_distinct(.data$site),
      .groups = "drop"
    ) |>
    dplyr::mutate(
      locally_sparse = .data$unique_participant_hours <
        h04_specification()$temporal$local_sparse_hours |
        .data$participants <
          h04_specification()$temporal$local_sparse_participants
    ) |>
    dplyr::left_join(
      h04_activity_registry() |>
        dplyr::select(
          activity = "activity_label",
          "activity_code",
          "display_order"
        ),
      by = "activity"
    ) |>
    dplyr::arrange(.data$display_order, .data$clock_hour)
}

h04_temporal_k_check <- function(object) {
  check <- as.data.frame(mgcv::k.check(
    object$final,
    subsample = nrow(object$data),
    n.rep = 0L
  ))
  check$term <- rownames(check)
  rownames(check) <- NULL
  tibble::as_tibble(check) |>
    dplyr::rename(
      k_prime = "k'",
      effective_df = "edf",
      k_index = "k-index",
      p_value = "p-value"
    ) |>
    dplyr::mutate(
      run_id = object$run_id,
      placement = object$placement,
      resampling_replicates = 0L,
      p_value = NA_real_,
      interpretation = paste(
        "deterministic basis-capacity diagnostic;",
        "no permutation p-value computed"
      ),
      .before = 1
    )
}

h04_temporal_concurvity <- function(object) {
  error_message <- NULL
  value <- tryCatch(
    mgcv::concurvity(object$final, full = TRUE),
    error = function(condition) {
      error_message <<- conditionMessage(condition)
      NULL
    }
  )
  if (!is.null(value)) {
    return(
      as.data.frame(value) |>
        tibble::rownames_to_column("measure") |>
        tidyr::pivot_longer(
          -"measure",
          names_to = "term",
          values_to = "concurvity"
        ) |>
        dplyr::mutate(
          run_id = object$run_id,
          placement = object$placement,
          method = "mgcv_full_concurvity",
          standard_mgcv_diagnostic_available = TRUE,
          diagnostic_note = NA_character_,
          .before = 1
        )
    )
  }
  contributions <- as.matrix(stats::predict(
    object$final,
    newdata = object$data,
    type = "terms"
  ))
  fallback <- dplyr::bind_rows(lapply(
    seq_len(ncol(contributions)),
    function(index) {
      response <- contributions[, index]
      others <- contributions[, -index, drop = FALSE]
      fit <- stats::lm.fit(cbind(`(Intercept)` = 1, others), response)
      total <- sum((response - mean(response))^2)
      tibble::tibble(
        measure = "observed_term_contribution_multiple_r_squared",
        term = colnames(contributions)[index],
        concurvity = if (total > 0) {
          1 - sum(fit$residuals^2) / total
        } else {
          NA_real_
        }
      )
    }
  ))
  fallback |>
    dplyr::mutate(
      run_id = object$run_id,
      placement = object$placement,
      method = "deterministic_term_contribution_fallback",
      standard_mgcv_diagnostic_available = FALSE,
      diagnostic_note = paste0(
        "mgcv full concurvity unavailable: ",
        error_message,
        ". Value is fitted-term multiple R-squared, not mgcv concurvity."
      ),
      .before = 1
    )
}

h04_temporal_residual_acf <- function(object, max_lag = 6L) {
  residual <- h04_temporal_residual(object)
  dplyr::bind_rows(lapply(seq_len(max_lag), function(lag) {
    estimate <- h04_temporal_lag_correlation(
      residual,
      object$data$AR_start,
      lag
    )
    tibble::tibble(
      run_id = object$run_id,
      placement = object$placement,
      lag_hours = lag,
      correlation = unname(estimate["correlation"]),
      pairs = unname(estimate["pairs"])
    )
  }))
}

h04_temporal_run_diagnostics <- function(object) {
  run_check <- object$data |>
    dplyr::group_by(.data$activity_run_id) |>
    dplyr::summarise(
      rows = dplyr::n(),
      unique_timestamps = dplyr::n_distinct(.data$interval_start_utc),
      consecutive_utc = all(
        dplyr::row_number() == 1L |
          dplyr::near(.data$utc_step_hours, 1)
      ),
      consecutive_wall = all(
        dplyr::row_number() == 1L |
          .data$wall_step_minutes == 60L
      ),
      one_activity = dplyr::n_distinct(.data$activity) == 1L,
      one_participant_day = dplyr::n_distinct(.data$participant_day) == 1L,
      .groups = "drop"
    )
  hour_weight <- object$data |>
    dplyr::group_by(.data$analysis_hour_id) |>
    dplyr::summarise(
      rows = dplyr::n(),
      k = dplyr::first(.data$k),
      weight_sum = sum(.data$analysis_weight),
      .groups = "drop"
    )
  tibble::tibble(
    run_id = object$run_id,
    placement = object$placement,
    activity_runs = nrow(run_check),
    maximum_rows_per_run = max(run_check$rows),
    runs_with_duplicate_timestamps = sum(
      run_check$rows != run_check$unique_timestamps
    ),
    nonconsecutive_utc_within_runs = sum(!run_check$consecutive_utc),
    nonconsecutive_wall_within_runs = sum(!run_check$consecutive_wall),
    mixed_activity_runs = sum(!run_check$one_activity),
    mixed_participant_day_runs = sum(!run_check$one_participant_day),
    hours = nrow(hour_weight),
    hours_with_row_k_mismatch = sum(hour_weight$rows != hour_weight$k),
    maximum_hour_weight_error = max(abs(hour_weight$weight_sum - 1)),
    concurrent_rows_never_lag_neighbours = all(
      run_check$rows == run_check$unique_timestamps
    )
  )
}

h04_temporal_cluster_diagnostics <- function(object) {
  residual <- h04_temporal_residual(object)
  data <- object$data
  data$standardized_residual <- residual
  leverage <- object$final$hat
  leverage_available <- !is.null(leverage) &&
    length(leverage) == nrow(data) &&
    all(is.finite(leverage))
  if (!leverage_available) {
    leverage <- rep(NA_real_, nrow(data))
  }
  data$leverage <- leverage
  data |>
    dplyr::group_by(.data$participant) |>
    dplyr::summarise(
      long_rows = dplyr::n(),
      effective_weighted_hours = sum(.data$analysis_weight),
      leverage = if (all(is.na(.data$leverage))) {
        NA_real_
      } else {
        sum(.data$leverage, na.rm = TRUE)
      },
      mean_absolute_standardized_residual = stats::weighted.mean(
        abs(.data$standardized_residual),
        .data$analysis_weight
      ),
      maximum_absolute_standardized_residual = max(
        abs(.data$standardized_residual)
      ),
      .groups = "drop"
    ) |>
    dplyr::mutate(
      leverage_share = if (all(is.na(.data$leverage))) {
        NA_real_
      } else {
        .data$leverage / sum(.data$leverage, na.rm = TRUE)
      },
      residual_rank = rank(
        -.data$mean_absolute_standardized_residual,
        ties.method = "first"
      ),
      run_id = object$run_id,
      placement = object$placement,
      leverage_source = if (leverage_available) {
        "mgcv stored hat diagonal"
      } else {
        "unavailable for discrete bam; participant residual ranking retained"
      },
      .before = 1
    ) |>
    dplyr::arrange(.data$residual_rank)
}

h04_temporal_smooth_table <- function(object) {
  table <- as.data.frame(summary(object$final)$s.table) |>
    tibble::rownames_to_column("smooth") |>
    tibble::as_tibble()
  names(table) <- make.names(names(table), unique = TRUE)
  table |>
    dplyr::mutate(
      run_id = object$run_id,
      placement = object$placement,
      approximate_p_values_not_primary = TRUE,
      .before = 1
    )
}

h04_temporal_comparison <- function(activity_object, no_activity_object) {
  activity <- h04_temporal_model_summary(activity_object)
  no_activity <- h04_temporal_model_summary(no_activity_object)
  dplyr::bind_rows(
    dplyr::mutate(activity, aic = stats::AIC(activity_object$final)),
    dplyr::mutate(no_activity, aic = stats::AIC(no_activity_object$final))
  ) |>
    dplyr::group_by(.data$placement) |>
    dplyr::mutate(
      delta_aic_from_minimum = .data$aic - min(.data$aic),
      comparison_role = paste(
        "exploratory contextual comparison; not a primary likelihood-ratio test"
      )
    ) |>
    dplyr::ungroup()
}

h04_temporal_basis_contract <- function() {
  probe <- tibble::tibble(
    time_hour = rep(seq(0, 23, length.out = 24), 3),
    activity = factor(rep(c("A", "B", "C"), each = 24)),
    site = factor(rep(c("A", "B", "C"), each = 24))
  )
  knots <- list(time_hour = c(0, 24))
  activity <- mgcv::smoothCon(
    mgcv::s(time_hour, activity, bs = "sz", k = 12),
    data = probe,
    knots = knots,
    absorb.cons = FALSE
  )[[1L]]
  site <- mgcv::smoothCon(
    mgcv::s(time_hour, site, bs = "sz", k = 12),
    data = probe,
    knots = knots,
    absorb.cons = FALSE
  )[[1L]]
  global <- mgcv::smoothCon(
    mgcv::s(time_hour, bs = "cc", k = 12),
    data = probe,
    knots = knots,
    absorb.cons = FALSE
  )[[1L]]
  tibble::tribble(
    ~component,
    ~constructed_class,
    ~marginal_basis,
    ~cyclic,
    "global time",
    class(global)[1L],
    "cyclic cubic regression spline",
    TRUE,
    "activity deviation",
    class(activity)[1L],
    paste(activity$base.bs, activity$base$bs, sep = " / "),
    FALSE,
    "site deviation",
    class(site)[1L],
    paste(site$base.bs, site$base$bs, sep = " / "),
    FALSE
  )
}

h04_temporal_figure <- function(
  curves,
  support,
  placement,
  interval = "pointwise"
) {
  interval <- match.arg(interval, c("pointwise", "none"))
  registry <- h04_activity_registry()
  display <- curves |>
    dplyr::mutate(
      activity = factor(.data$activity, levels = registry$activity_label),
      display_role = ifelse(
        as.character(.data$activity) == "Other/unspecified activity",
        "Other",
        "Named category"
      )
    )
  counts <- support |>
    dplyr::mutate(
      activity = factor(
        as.character(.data$activity),
        levels = registry$activity_label
      )
    )
  curve_plot <- ggplot2::ggplot(
    display,
    ggplot2::aes(
      x = .data$time_hour,
      y = .data$estimated_mel_edi_lx,
      group = .data$activity
    )
  ) +
    {
      if (interval == "pointwise") {
        ggplot2::geom_ribbon(
          ggplot2::aes(
            ymin = .data$pointwise_conf_low_lx,
            ymax = .data$pointwise_conf_high_lx
          ),
          fill = "#56B4E9",
          alpha = 0.22
        )
      } else {
        ggplot2::geom_blank()
      }
    } +
    ggplot2::geom_line(colour = "#0072B2", linewidth = 0.8) +
    ggplot2::geom_point(
      data = dplyr::filter(display, .data$time_hour %in% c(0, 24)),
      shape = 21,
      fill = "white",
      colour = "#0072B2",
      size = 2.2,
      stroke = 0.7
    ) +
    ggplot2::scale_x_continuous(
      breaks = seq(0, 24, by = 6),
      limits = c(0, 24),
      expand = ggplot2::expansion(mult = c(0.01, 0.01))
    ) +
    ggplot2::scale_y_continuous(
      trans = LightLogR::symlog_trans(base = 10, thr = 1, scale = 1),
      breaks = c(0, 1, 10, 100, 1000, 10000),
      labels = scales::label_number(big.mark = ",")
    ) +
    ggplot2::facet_wrap(
      ggplot2::vars(activity),
      ncol = 3,
      labeller = ggplot2::labeller(
        activity = ggplot2::label_wrap_gen(width = 22)
      )
    ) +
    ggplot2::labs(
      title = paste0(
        placement,
        ": exploratory activity-associated melEDI patterns by local time"
      ),
      subtitle = paste(
        "Global time is cyclic; activity and site deviations use thin-plate sz bases.",
        "Open endpoints expose accepted midnight separation."
      ),
      x = "Local time (hours)",
      y = "Equal-site standardized melEDI (lx)"
    ) +
    h04_figure_theme() +
    ggplot2::theme(
      panel.spacing.x = grid::unit(1.8, "lines"),
      panel.spacing.y = grid::unit(1.0, "lines")
    )

  count_plot <- ggplot2::ggplot(
    counts,
    ggplot2::aes(
      x = .data$clock_hour + 0.5,
      y = .data$effective_weighted_hours,
      fill = .data$locally_sparse
    )
  ) +
    ggplot2::geom_col(width = 0.92) +
    ggplot2::scale_fill_manual(
      values = c(`FALSE` = "#999999", `TRUE` = "#CC79A7"),
      labels = c(`FALSE` = "adequate", `TRUE` = "locally sparse")
    ) +
    ggplot2::scale_x_continuous(
      breaks = seq(0, 24, by = 6),
      limits = c(0, 24),
      expand = c(0, 0)
    ) +
    ggplot2::facet_wrap(
      ggplot2::vars(activity),
      ncol = 3,
      labeller = ggplot2::labeller(
        activity = ggplot2::label_wrap_gen(width = 22)
      )
    ) +
    ggplot2::labs(
      x = "Local time (hours)",
      y = "Effective weighted hours",
      fill = "Clock/category support"
    ) +
    h04_figure_theme() +
    ggplot2::theme(
      strip.text = ggplot2::element_blank(),
      legend.position = "top",
      panel.spacing.x = grid::unit(1.8, "lines"),
      panel.spacing.y = grid::unit(1.0, "lines")
    )
  patchwork::wrap_plots(curve_plot, count_plot, ncol = 1, heights = c(2.2, 1)) +
    patchwork::plot_annotation(
      caption = paste(
        "Curves share each multi-select hour through 1/k weights and exclude participant/day smooths.",
        "\nRibbons are model-based pointwise 95% intervals from the fitted-coefficient covariance.",
        "They are not simultaneous bands and do not support curve-wide inference.",
        "\nNo line wraps from 24:00 to 00:00. Other is display-only."
      ),
      theme = h04_figure_theme()
    )
}

h04_temporal_activity_palette <- function() {
  palette <- stats::setNames(
    c("#7570B3", "#A6761D", "#D95F02", "#E7298A", "#1B9E77", "#4D4D4D"),
    h04_activity_registry()$activity_code
  )
  h03_palette <- c(
    "#4477AA", "#EE6677", "#228833", "#CCBB44", "#66CCEE", "#AA3377",
    "#777777"
  )
  if (length(intersect(unname(palette), h03_palette)) > 0L) {
    h04_abort("The H04 temporal activity palette overlaps the H03 category palette")
  }
  palette
}

h04_temporal_ratio_breaks <- function() {
  c(0.01, 0.02, 0.05, 0.1, 0.2, 0.5, 1, 2, 5, 10, 20, 50)
}

h04_temporal_reader_figure <- function(
  curves,
  ratios,
  global,
  support,
  placement,
  facet_ncol = 6L
) {
  registry <- h04_reader_activity_registry()
  palette <- h04_temporal_activity_palette()
  ratio_breaks <- h04_temporal_ratio_breaks()
  activity_levels <- registry$activity_label
  activity_labels <- stats::setNames(
    registry$reader_label,
    registry$activity_label
  )
  temporal_panel_theme <- ggplot2::theme(
    strip.text.x = ggplot2::element_text(
      size = 12,
      face = "bold",
      margin = ggplot2::margin(t = 5, r = 1, b = 5, l = 1)
    ),
    plot.tag.position = c(0.995, 0.995),
    plot.tag = ggplot2::element_text(
      size = 14,
      face = "bold",
      hjust = 1,
      vjust = 1,
      margin = ggplot2::margin(l = 8, b = 4)
    )
  )
  complete_support <- tidyr::crossing(
    placement = placement,
    activity = activity_levels,
    clock_hour = 0:23
  ) |>
    dplyr::left_join(
      support,
      by = c("placement", "activity", "clock_hour"),
      relationship = "one-to-one"
    ) |>
    dplyr::mutate(
      dplyr::across(
        c(
          "unique_participant_hours", "long_rows", "effective_weighted_hours",
          "participants", "participant_days", "sites"
        ),
        ~dplyr::coalesce(.x, 0)
      ),
      locally_sparse = dplyr::coalesce(.data$locally_sparse, TRUE),
      activity_code = dplyr::coalesce(
        .data$activity_code,
        registry$activity_code[match(.data$activity, activity_levels)]
      ),
      display_order = registry$reader_display_order[
        match(.data$activity, activity_levels)
      ],
      activity = factor(.data$activity, levels = activity_levels)
    )
  support_for_curves <- complete_support |>
    dplyr::select(
      "activity", "activity_code", "clock_hour",
      "unique_participant_hours", "participants", "participant_days",
      "sites", "locally_sparse"
    )
  prepare_curve <- function(data) {
    data |>
      dplyr::mutate(
        activity = factor(.data$activity, levels = activity_levels),
        clock_hour = floor(.data$time_hour) %% 24L
      ) |>
      dplyr::left_join(
        support_for_curves,
        by = c("activity", "activity_code", "clock_hour"),
        relationship = "many-to-one"
      ) |>
      dplyr::group_by(.data$activity_code) |>
      dplyr::arrange(.data$time_hour, .by_group = TRUE) |>
      dplyr::mutate(
        has_observations = .data$unique_participant_hours > 0,
        observed_run = cumsum(
          .data$has_observations &
            !dplyr::lag(.data$has_observations, default = FALSE)
        ),
        integer_hour = abs(.data$time_hour - round(.data$time_hour)) < 1e-8
      ) |>
      dplyr::ungroup()
  }
  curves <- prepare_curve(curves)
  ratios <- prepare_curve(ratios) |>
    dplyr::mutate(
      ratio_log10 = log10(.data$ratio_to_global),
      ratio_conf_low_log10 = log10(.data$ratio_conf_low),
      ratio_conf_high_log10 = log10(.data$ratio_conf_high)
    )
  global_facets <- tidyr::crossing(
    global,
    activity = activity_levels
  ) |>
    dplyr::mutate(
      activity_code = registry$activity_code[match(.data$activity, activity_levels)],
      activity = factor(.data$activity, levels = activity_levels),
      clock_hour = floor(.data$time_hour) %% 24L
    ) |>
    dplyr::left_join(
      support_for_curves,
      by = c("activity", "activity_code", "clock_hour"),
      relationship = "many-to-one"
    ) |>
    dplyr::group_by(.data$activity_code) |>
    dplyr::arrange(.data$time_hour, .by_group = TRUE) |>
    dplyr::mutate(
      has_observations = .data$unique_participant_hours > 0,
      observed_run = cumsum(
        .data$has_observations &
          !dplyr::lag(.data$has_observations, default = FALSE)
      )
    ) |>
    dplyr::ungroup()
  unsupported <- complete_support |>
    dplyr::filter(.data$unique_participant_hours == 0) |>
    dplyr::transmute(
      .data$activity,
      xmin = .data$clock_hour,
      xmax = .data$clock_hour + 1,
      ymin = -Inf,
      ymax = Inf
    )

  curve_plot <- ggplot2::ggplot(
    curves,
    ggplot2::aes(
      x = .data$time_hour,
      y = .data$estimated_mel_edi_lx,
      colour = .data$activity_code,
      fill = .data$activity_code
    )
  ) +
    ggplot2::geom_rect(
      data = unsupported,
      ggplot2::aes(
        xmin = .data$xmin,
        xmax = .data$xmax,
        ymin = .data$ymin,
        ymax = .data$ymax
      ),
      inherit.aes = FALSE,
      fill = "#F2F2F2",
      colour = NA
    ) +
    ggplot2::geom_ribbon(
      data = dplyr::filter(curves, .data$has_observations),
      ggplot2::aes(
        ymin = .data$pointwise_conf_low_lx,
        ymax = .data$pointwise_conf_high_lx,
        group = interaction(.data$activity_code, .data$observed_run)
      ),
      alpha = 0.18,
      colour = NA
    ) +
    ggplot2::geom_line(
      data = dplyr::filter(curves, .data$has_observations),
      ggplot2::aes(
        group = interaction(.data$activity_code, .data$observed_run)
      ),
      linewidth = 0.9
    ) +
    ggplot2::geom_line(
      data = dplyr::filter(global_facets, .data$has_observations),
      ggplot2::aes(
        x = .data$time_hour,
        y = .data$global_mel_edi_lx,
        group = interaction(.data$activity_code, .data$observed_run)
      ),
      inherit.aes = FALSE,
      colour = "black",
      linetype = "dashed",
      linewidth = 0.55
    ) +
    ggplot2::geom_point(
      data = dplyr::filter(
        curves,
        .data$has_observations,
        .data$integer_hour,
        !.data$locally_sparse
      ),
      shape = 21,
      size = 2,
      stroke = 0.55
    ) +
    ggplot2::geom_point(
      data = dplyr::filter(
        curves,
        .data$has_observations,
        .data$integer_hour,
        .data$locally_sparse
      ),
      shape = 21,
      fill = "white",
      size = 2,
      stroke = 0.55
    ) +
    ggplot2::facet_wrap(
      ggplot2::vars(.data$activity),
      ncol = facet_ncol,
      labeller = ggplot2::labeller(
        activity = ggplot2::as_labeller(activity_labels)
      )
    ) +
    ggplot2::scale_x_continuous(
      breaks = c(0, 6, 12, 18, 24),
      limits = c(0, 24)
    ) +
    ggplot2::scale_y_continuous(
      trans = LightLogR::symlog_trans(base = 10, thr = 1, scale = 1),
      breaks = c(0, 1, 10, 100, 250, 1000, 10000),
      labels = scales::label_number(big.mark = ",")
    ) +
    ggplot2::scale_colour_manual(values = palette, guide = "none") +
    ggplot2::scale_fill_manual(values = palette, guide = "none") +
    ggplot2::labs(
      title = paste0(placement, ": expected one-hour melEDI by time of day"),
      subtitle = paste(
        "Dashed black line: global cyclic smooth; filled points: observed;",
        "open points: locally sparse; grey hours: no observations"
      ),
      x = NULL,
      y = "melEDI (lx)"
    ) +
    h04_figure_theme() +
    temporal_panel_theme

  ratio_plot <- ggplot2::ggplot(
    ratios,
    ggplot2::aes(
      x = .data$time_hour,
      y = .data$ratio_log10,
      colour = .data$activity_code,
      fill = .data$activity_code
    )
  ) +
    ggplot2::geom_rect(
      data = unsupported,
      ggplot2::aes(
        xmin = .data$xmin,
        xmax = .data$xmax,
        ymin = .data$ymin,
        ymax = .data$ymax
      ),
      inherit.aes = FALSE,
      fill = "#F2F2F2",
      colour = NA
    ) +
    ggplot2::geom_hline(yintercept = 0, colour = "grey45", linetype = "dashed") +
    ggplot2::geom_ribbon(
      data = dplyr::filter(ratios, .data$has_observations),
      ggplot2::aes(
        ymin = .data$ratio_conf_low_log10,
        ymax = .data$ratio_conf_high_log10,
        group = interaction(.data$activity_code, .data$observed_run)
      ),
      alpha = 0.18,
      colour = NA
    ) +
    ggplot2::geom_line(
      data = dplyr::filter(ratios, .data$has_observations),
      ggplot2::aes(
        group = interaction(.data$activity_code, .data$observed_run)
      ),
      linewidth = 0.9
    ) +
    ggplot2::geom_point(
      data = dplyr::filter(
        ratios,
        .data$has_observations,
        .data$integer_hour,
        !.data$locally_sparse
      ),
      shape = 21,
      size = 2,
      stroke = 0.55
    ) +
    ggplot2::geom_point(
      data = dplyr::filter(
        ratios,
        .data$has_observations,
        .data$integer_hour,
        .data$locally_sparse
      ),
      shape = 21,
      fill = "white",
      size = 2,
      stroke = 0.55
    ) +
    ggplot2::facet_wrap(
      ggplot2::vars(.data$activity),
      ncol = facet_ncol,
      labeller = ggplot2::labeller(
        activity = ggplot2::as_labeller(activity_labels)
      )
    ) +
    ggplot2::scale_x_continuous(
      breaks = c(0, 6, 12, 18, 24),
      limits = c(0, 24)
    ) +
    ggplot2::scale_y_continuous(
      breaks = log10(ratio_breaks),
      labels = as.character(ratio_breaks),
      limits = log10(range(ratio_breaks)),
      expand = ggplot2::expansion(mult = c(0.01, 0.01))
    ) +
    ggplot2::scale_colour_manual(values = palette, guide = "none") +
    ggplot2::scale_fill_manual(values = palette, guide = "none") +
    ggplot2::labs(
      title = "Activity-associated ratio to the global time-of-day mean",
      subtitle = paste(
        "Filled points: observed; open points: locally sparse;",
        "grey hours: no observations"
      ),
      x = NULL,
      y = "Factor relative to global mean"
    ) +
    h04_figure_theme() +
    temporal_panel_theme

  support_plot <- ggplot2::ggplot(
    complete_support,
    ggplot2::aes(
      x = .data$clock_hour + 0.5,
      y = .data$effective_weighted_hours,
      fill = .data$activity_code
    )
  ) +
    ggplot2::geom_col(width = 0.88) +
    ggplot2::geom_point(
      data = dplyr::filter(
        complete_support,
        .data$unique_participant_hours == 0
      ),
      ggplot2::aes(y = 0),
      shape = 4,
      size = 1.8,
      stroke = 0.7
    ) +
    ggplot2::geom_point(
      data = dplyr::filter(
        complete_support,
        .data$unique_participant_hours > 0,
        .data$locally_sparse
      ),
      ggplot2::aes(y = .data$effective_weighted_hours),
      shape = 1,
      size = 1.7,
      stroke = 0.6
    ) +
    ggplot2::facet_wrap(
      ggplot2::vars(.data$activity),
      ncol = facet_ncol,
      labeller = ggplot2::labeller(
        activity = ggplot2::as_labeller(activity_labels)
      )
    ) +
    ggplot2::scale_x_continuous(
      breaks = c(0, 6, 12, 18, 24),
      limits = c(0, 24)
    ) +
    ggplot2::scale_fill_manual(values = palette, guide = "none") +
    ggplot2::labs(
      title = "Available effective weighted hours by local time",
      subtitle = "×: no observations; open circle: nonzero but locally sparse",
      x = "Local time (hour)",
      y = "Effective weighted hours"
    ) +
    h04_figure_theme() +
    temporal_panel_theme

  patchwork::wrap_plots(
    curve_plot,
    ratio_plot,
    support_plot,
    ncol = 1,
    heights = c(1.15, 1, 0.75)
  ) +
    patchwork::plot_annotation(
      tag_levels = "A",
      caption = paste0(
        "Bands are conditional pointwise 95% intervals; no simultaneous-band or curve-wide inferential claim is made.\n",
        "Sites are averaged equally on the fitted log-mean scale; participant and participant-day smooths are excluded from displayed curves.\n",
        "Panel B divides each displayed activity curve by the displayed global time-of-day mean; the dashed reference is 1. Other is display-only.\n",
        "The activity palette is distinct from the light-source category colours used elsewhere in this report series.\n",
        "Each multi-select participant-hour contributes 1/k to every retained activity. Filled circles mark observed support; open circles mark locally sparse support.\n",
        "Grey regions and × mark zero observations. Only the global smooth is cyclic; thin-plate activity and site deviations may separate over midnight.\n",
        "No line is wrapped from 24:00 to 00:00. The melEDI axis transformation is display-only."
      ),
      theme = h04_figure_theme() +
        ggplot2::theme(
          plot.caption = ggplot2::element_text(
            size = 10.5,
            lineheight = 1.05,
            hjust = 0,
            margin = ggplot2::margin(t = 10, b = 8)
          ),
          plot.caption.position = "plot",
          plot.margin = ggplot2::margin(t = 8, r = 14, b = 16, l = 8)
        )
    )
}
