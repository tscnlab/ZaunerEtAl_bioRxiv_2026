# Reusable numerical exports and fitted-model diagnostics for H02.
write_h02_csv <- function(data, path, id = NULL, metadata = list()) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  readr::write_csv(data, path, na = "")
  invisible(path)
}
write_h02_rds <- function(object, path, id = NULL, metadata = list()) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  saveRDS(object, path, version = 3)
  invisible(path)
}
write_h02_plot <- function(plot, path, id = NULL, width, height) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  ggplot2::ggsave(path, plot, width = width, height = height, units = "in", dpi = 300, bg = "white")
  if (is.data.frame(plot$data)) {
    readr::write_csv(plot$data, sub("\\.[^.]+$", ".csv", path))
  }
  invisible(path)
}
formula_text <- function(formula) paste(deparse(formula), collapse = " ")
relative_to_root <- function(path) substring(normalizePath(path, winslash = "/", mustWork = TRUE), nchar(root) + 2L)

find_exact_smooth <- function(fit, label) {
  index <- which(h02_smooth_labels(fit) == label)
  if (length(index) != 1L) {
    h02_abort("Expected exactly one smooth labelled '%s'", label)
  }
  index
}

component_endpoint_rows <- function(
  values,
  group,
  component,
  run_id,
  cyclic_expected,
  step_hours
) {
  value_at <- function(time) values[match(time, values$time_hour), "eta"][[1L]]
  value_0 <- value_at(0)
  value_step <- value_at(step_hours)
  value_before_24 <- value_at(24 - step_hours)
  value_24 <- value_at(24)
  derivative_0 <- (value_step - value_0) / step_hours
  derivative_24 <- (value_24 - value_before_24) / step_hours
  tibble::tibble(
    run_id = run_id,
    component = component,
    group = group,
    cyclic_continuity_imposed = cyclic_expected,
    finite_difference_step_hours = step_hours,
    eta_at_00 = value_0,
    eta_at_24 = value_24,
    midnight_value_jump_eta = value_24 - value_0,
    midnight_ratio_24_to_00 = 10^(value_24 - value_0),
    derivative_at_00_eta_per_hour = derivative_0,
    derivative_at_24_eta_per_hour = derivative_24,
    midnight_derivative_jump_eta_per_hour = derivative_24 - derivative_0
  )
}

endpoint_diagnostics <- function(fit, data, run_id, step_hours = 0.01) {
  endpoint_times <- c(0, step_hours, 24 - step_hours, 24)
  common_index <- find_exact_smooth(fit, "s(time_hour)")
  site_index <- find_exact_smooth(fit, "s(time_hour,site)")
  participant_index <- find_exact_smooth(
    fit,
    "s(time_hour,participant)"
  )

  representative <- tibble::tibble(
    time_hour = endpoint_times,
    site = factor(levels(data$site)[1L], levels = levels(data$site)),
    site_smooth = ordered(
      levels(data$site)[1L],
      levels = levels(data$site)
    ),
    participant = factor(
      levels(data$participant)[1L],
      levels = levels(data$participant)
    ),
    participant_day = factor(
      levels(data$participant_day)[1L],
      levels = levels(data$participant_day)
    )
  )
  representative$eta <- h02_term_contribution(
    fit,
    representative,
    common_index
  )
  common <- component_endpoint_rows(
    representative[, c("time_hour", "eta")],
    "equal-site common curve",
    "common_time_curve",
    run_id,
    TRUE,
    step_hours
  )

  site_grid <- tidyr::crossing(
    site = factor(levels(data$site), levels = levels(data$site)),
    time_hour = endpoint_times
  ) |>
    dplyr::mutate(
      site_smooth = ordered(
        as.character(.data$site),
        levels = levels(data$site)
      ),
      participant = factor(
        levels(data$participant)[1L],
        levels = levels(data$participant)
      ),
      participant_day = factor(
        levels(data$participant_day)[1L],
        levels = levels(data$participant_day)
      )
    )
  site_grid$site_eta <- h02_term_contribution(fit, site_grid, site_index)
  site_grid$common_eta <- h02_term_contribution(
    fit,
    site_grid,
    common_index
  )
  site_deviation <- site_grid |>
    dplyr::transmute(
      group = as.character(.data$site),
      time_hour = .data$time_hour,
      eta = .data$site_eta
    ) |>
    dplyr::group_split(.data$group) |>
    lapply(function(x) {
      component_endpoint_rows(
        x[, c("time_hour", "eta")],
        x$group[[1L]],
        "site_deviation_curve",
        run_id,
        FALSE,
        step_hours
      )
    }) |>
    dplyr::bind_rows()
  full_site <- site_grid |>
    dplyr::transmute(
      group = as.character(.data$site),
      time_hour = .data$time_hour,
      eta = .data$site_eta + .data$common_eta
    ) |>
    dplyr::group_split(.data$group) |>
    lapply(function(x) {
      component_endpoint_rows(
        x[, c("time_hour", "eta")],
        x$group[[1L]],
        "full_site_curve",
        run_id,
        FALSE,
        step_hours
      )
    }) |>
    dplyr::bind_rows()

  participant_info <- data |>
    dplyr::distinct(.data$site, .data$participant)
  participant_grid <- tidyr::crossing(
    participant_info,
    time_hour = endpoint_times
  ) |>
    dplyr::mutate(
      site_smooth = ordered(
        as.character(.data$site),
        levels = levels(data$site)
      ),
      participant_day = factor(
        levels(data$participant_day)[1L],
        levels = levels(data$participant_day)
      )
    )
  participant_grid$eta <- h02_term_contribution(
    fit,
    participant_grid,
    participant_index
  )
  participant <- participant_grid |>
    dplyr::transmute(
      group = as.character(.data$participant),
      time_hour = .data$time_hour,
      eta = .data$eta
    ) |>
    dplyr::group_split(.data$group) |>
    lapply(function(x) {
      component_endpoint_rows(
        x[, c("time_hour", "eta")],
        x$group[[1L]],
        "participant_deviation_curve",
        run_id,
        FALSE,
        step_hours
      )
    }) |>
    dplyr::bind_rows()

  dplyr::bind_rows(common, site_deviation, full_site, participant)
}

site_constraint_diagnostic <- function(fit, data, run_id) {
  site_index <- find_exact_smooth(fit, "s(time_hour,site)")
  grid <- tidyr::crossing(
    site = factor(levels(data$site), levels = levels(data$site)),
    time_hour = (seq.int(0L, 1410L, by = 30L) + 15) / 60
  ) |>
    dplyr::mutate(
      site_smooth = ordered(
        as.character(.data$site),
        levels = levels(data$site)
      ),
      participant = factor(
        levels(data$participant)[1L],
        levels = levels(data$participant)
      ),
      participant_day = factor(
        levels(data$participant_day)[1L],
        levels = levels(data$participant_day)
      )
    )
  grid$site_deviation_eta <- h02_term_contribution(fit, grid, site_index)
  sums <- grid |>
    dplyr::group_by(.data$time_hour) |>
    dplyr::summarise(
      sum_site_deviation_eta = sum(.data$site_deviation_eta),
      .groups = "drop"
    )
  tolerance <- 1e-8
  maximum_absolute_sum <- max(abs(sums$sum_site_deviation_eta))
  tibble::tibble(
    run_id = run_id,
    sites = dplyr::n_distinct(data$site),
    clock_bins = nrow(sums),
    maximum_absolute_sum_site_deviation_eta = maximum_absolute_sum,
    root_mean_square_sum_site_deviation_eta = sqrt(mean(
      sums$sum_site_deviation_eta^2
    )),
    numerical_tolerance = tolerance,
    sum_to_zero_constraint_verified = maximum_absolute_sum <= tolerance,
    coefficient_rank = fit$rank,
    coefficients = length(stats::coef(fit)),
    full_coefficient_rank = fit$rank == length(stats::coef(fit)),
    diagnostic_definition = paste(
      "sum of fitted sz site-deviation contributions across all factor",
      "levels at each of the 48 equal-clock bins"
    )
  )
}

fitted_term_dependence <- function(fit, data, run_id) {
  terms <- mgcv::predict.gam(
    fit,
    newdata = as.data.frame(data),
    type = "terms",
    block.size = 1000L,
    newdata.guaranteed = TRUE
  )
  terms <- as.matrix(terms)
  labels <- colnames(terms)
  if (ncol(terms) < 2L) {
    h02_abort("Fitted-term dependence requires at least two model terms")
  }
  pairwise <- utils::combn(
    seq_len(ncol(terms)),
    2L,
    simplify = FALSE
  ) |>
    lapply(function(index) {
      tibble::tibble(
        run_id = run_id,
        diagnostic = "pairwise_fitted_term_correlation",
        target_term = labels[index[1L]],
        comparison_terms = labels[index[2L]],
        estimate = stats::cor(
          terms[, index[1L]],
          terms[, index[2L]],
          use = "complete.obs"
        ),
        observations = nrow(terms)
      )
    }) |>
    dplyr::bind_rows()
  multiple <- dplyr::bind_rows(lapply(seq_len(ncol(terms)), function(i) {
    target <- terms[, i]
    others <- terms[, -i, drop = FALSE]
    fitted <- stats::lm.fit(cbind(intercept = 1, others), target)$fitted.values
    denominator <- sum((target - mean(target))^2)
    r_squared <- if (denominator > 0) {
      1 - sum((target - fitted)^2) / denominator
    } else {
      NA_real_
    }
    tibble::tibble(
      run_id = run_id,
      diagnostic = "fitted_term_multiple_R2_proxy",
      target_term = labels[i],
      comparison_terms = paste(labels[-i], collapse = " + "),
      estimate = r_squared,
      observations = nrow(terms)
    )
  }))
  dplyr::bind_rows(pairwise, multiple) |>
    dplyr::mutate(
      interpretation = paste(
        "empirical dependence among fitted term contributions on the exact",
        "model rows; this is not mgcv's design-matrix worst-case",
        "concurvity statistic"
      )
    )
}

formal_concurvity <- function(fit, run_id) {
  started <- Sys.time()
  result <- gratia::model_concurvity(
    fit,
    type = "all",
    pairwise = FALSE
  )
  tibble::as_tibble(result) |>
    dplyr::mutate(
      run_id = run_id,
      method = paste(
        "gratia::model_concurvity() wrapper around",
        "mgcv::concurvity(full = TRUE)"
      ),
      elapsed_seconds = as.numeric(
        difftime(Sys.time(), started, units = "secs")
      ),
      .before = 1L
    )
}

residual_pair_table <- function(fit, data, run_id) {
  residual <- if (!is.null(fit$std.rsd) && length(fit$std.rsd) == nrow(data)) {
    fit$std.rsd
  } else {
    stats::residuals(fit, type = "response")
  }
  sequence_id <- cumsum(data$AR_start)
  index <- seq_along(residual)
  previous <- index - 1L
  eligible <- previous >= 1L
  eligible[eligible] <- sequence_id[index[eligible]] ==
    sequence_id[previous[eligible]]
  current_index <- index[eligible]
  previous_index <- previous[eligible]
  tibble::tibble(
    run_id = run_id,
    participant = as.character(data$participant[current_index]),
    participant_day = as.character(data$participant_day[current_index]),
    sequence_id = sequence_id[current_index],
    residual_current = residual[current_index],
    residual_previous = residual[previous_index]
  ) |>
    dplyr::filter(
      is.finite(.data$residual_current),
      is.finite(.data$residual_previous)
    )
}

cluster_residual_acf <- function(fit, data, run_id) {
  pairs <- residual_pair_table(fit, data, run_id)
  bind_cluster <- function(group, level) {
    pairs |>
      dplyr::group_by(across(all_of(group))) |>
      dplyr::summarise(
        eligible_pairs = dplyr::n(),
        lag1_correlation = if (dplyr::n() >= 3L) {
          stats::cor(.data$residual_current, .data$residual_previous)
        } else {
          NA_real_
        },
        .groups = "drop"
      ) |>
      dplyr::transmute(
        run_id = run_id,
        cluster_level = level,
        cluster_id = as.character(.data[[group]]),
        eligible_pairs = .data$eligible_pairs,
        lag1_correlation = .data$lag1_correlation
      )
  }
  dplyr::bind_rows(
    bind_cluster("participant", "participant"),
    bind_cluster("participant_day", "participant_day"),
    bind_cluster("sequence_id", "AR_sequence")
  )
}

summarise_cluster_residual_acf <- function(detail) {
  detail |>
    dplyr::group_by(.data$run_id, .data$cluster_level) |>
    dplyr::summarise(
      clusters = dplyr::n(),
      clusters_with_estimable_correlation = sum(
        is.finite(.data$lag1_correlation)
      ),
      eligible_pairs = sum(.data$eligible_pairs),
      median_lag1_correlation = stats::median(
        .data$lag1_correlation,
        na.rm = TRUE
      ),
      q05_lag1_correlation = unname(stats::quantile(
        .data$lag1_correlation,
        0.05,
        na.rm = TRUE
      )),
      q25_lag1_correlation = unname(stats::quantile(
        .data$lag1_correlation,
        0.25,
        na.rm = TRUE
      )),
      q75_lag1_correlation = unname(stats::quantile(
        .data$lag1_correlation,
        0.75,
        na.rm = TRUE
      )),
      q95_lag1_correlation = unname(stats::quantile(
        .data$lag1_correlation,
        0.95,
        na.rm = TRUE
      )),
      .groups = "drop"
    ) |>
    dplyr::mutate(
      stage = "final_AR1_standardized",
      pair_definition = paste(
        "lag-1 30-minute pairs within verified AR sequences only; no pair",
        "crosses participant-day or a declared discontinuity"
      ),
      .after = "run_id"
    )
}


h02_sensitivity_model_convergence <- function(fit) {
  if (
    is.list(fit$outer.info) &&
      !is.null(fit$outer.info$conv)
  ) {
    return(as.character(fit$outer.info$conv))
  }
  if (
    is.list(fit$mgcv.conv) &&
      !is.null(fit$mgcv.conv$fully.converged)
  ) {
    return(if (isTRUE(fit$mgcv.conv$fully.converged)) {
      "full convergence"
    } else {
      "not fully converged"
    })
  }
  "not reported"
}

h02_sensitivity_residual_pair_table <- function(fit, data) {
  residual <- if (
    !is.null(fit$std.rsd) &&
      length(fit$std.rsd) == nrow(data)
  ) {
    fit$std.rsd
  } else {
    stats::residuals(fit, type = "response")
  }
  sequence_id <- cumsum(data$AR_start)
  index <- seq_along(residual)
  previous <- index - 1L
  eligible <- previous >= 1L
  eligible[eligible] <- sequence_id[index[eligible]] ==
    sequence_id[previous[eligible]]
  current_index <- index[eligible]
  previous_index <- previous[eligible]
  tibble::tibble(
    participant = as.character(data$participant[current_index]),
    participant_day = as.character(data$participant_day[current_index]),
    sequence_id = sequence_id[current_index],
    residual_current = residual[current_index],
    residual_previous = residual[previous_index]
  ) |>
    dplyr::filter(
      is.finite(.data$residual_current),
      is.finite(.data$residual_previous)
    )
}

h02_sensitivity_cluster_residual_summary <- function(
  fit,
  data,
  base_run_id,
  placement,
  model_variant
) {
  pairs <- h02_sensitivity_residual_pair_table(fit, data)
  summarise_level <- function(group, level) {
    detail <- pairs |>
      dplyr::group_by(dplyr::across(dplyr::all_of(group))) |>
      dplyr::summarise(
        eligible_pairs = dplyr::n(),
        lag1_correlation = if (dplyr::n() >= 3L) {
          stats::cor(.data$residual_current, .data$residual_previous)
        } else {
          NA_real_
        },
        .groups = "drop"
      )
    tibble::tibble(
      base_run_id = base_run_id,
      placement = placement,
      model_variant = model_variant,
      cluster_level = level,
      clusters = nrow(detail),
      clusters_with_estimable_correlation = sum(
        is.finite(detail$lag1_correlation)
      ),
      eligible_pairs = sum(detail$eligible_pairs),
      median_lag1_correlation = stats::median(
        detail$lag1_correlation,
        na.rm = TRUE
      ),
      q05_lag1_correlation = unname(stats::quantile(
        detail$lag1_correlation,
        0.05,
        na.rm = TRUE
      )),
      q95_lag1_correlation = unname(stats::quantile(
        detail$lag1_correlation,
        0.95,
        na.rm = TRUE
      ))
    )
  }
  dplyr::bind_rows(
    summarise_level("participant", "participant"),
    summarise_level("participant_day", "participant_day"),
    summarise_level("sequence_id", "AR_sequence")
  )
}

h02_sensitivity_residual_metrics <- function(
  fit,
  data,
  base_run_id,
  placement,
  model_variant,
  rho
) {
  response_residual <- stats::residuals(fit, type = "response")
  standardized_residual <- if (
    !is.null(fit$std.rsd) &&
      length(fit$std.rsd) == nrow(data)
  ) {
    fit$std.rsd
  } else {
    response_residual
  }
  fitted <- stats::fitted(fit)
  qq_theoretical <- stats::qnorm(stats::ppoints(length(standardized_residual)))
  qq_observed <- sort(standardized_residual)
  fit_summary <- summary(fit)
  lag1 <- h02_boundary_lag_correlation(
    standardized_residual,
    data$AR_start,
    lag = 1L
  )
  tibble::tibble(
    base_run_id = base_run_id,
    placement = placement,
    model_variant = model_variant,
    rho = rho,
    observations = nrow(data),
    response_residual_rmse = sqrt(mean(response_residual^2)),
    response_residual_mae = mean(abs(response_residual)),
    standardized_residual_rmse = sqrt(mean(standardized_residual^2)),
    standardized_residual_mae = mean(abs(standardized_residual)),
    standardized_residual_sd = stats::sd(standardized_residual),
    standardized_residual_q99_absolute = unname(stats::quantile(
      abs(standardized_residual),
      0.99
    )),
    maximum_absolute_standardized_residual = max(
      abs(standardized_residual)
    ),
    correlation_absolute_residual_fitted = stats::cor(
      abs(standardized_residual),
      fitted,
      use = "complete.obs"
    ),
    normal_qq_correlation = stats::cor(
      qq_observed,
      qq_theoretical,
      use = "complete.obs"
    ),
    boundary_aware_lag1_correlation = unname(lag1["correlation"]),
    boundary_aware_lag1_pairs = as.integer(lag1["pairs"]),
    deviance_explained = fit_summary$dev.expl,
    adjusted_r_squared = fit_summary$r.sq
  )
}

h02_sensitivity_global_midnight_diagnostic <- function(
  fit,
  data,
  base_run_id,
  placement,
  model_variant,
  cyclic_expected,
  step_hours = 0.01
) {
  common_index <- which(h02_smooth_labels(fit) == "s(time_hour)")
  if (length(common_index) != 1L) {
    h02_abort("Expected one global time smooth for %s", model_variant)
  }
  endpoint_times <- c(0, step_hours, 24 - step_hours, 24)
  representative <- tibble::tibble(
    time_hour = endpoint_times,
    site = factor(levels(data$site)[1L], levels = levels(data$site)),
    site_smooth = ordered(
      levels(data$site)[1L],
      levels = levels(data$site)
    ),
    participant = factor(
      levels(data$participant)[1L],
      levels = levels(data$participant)
    ),
    participant_day = factor(
      levels(data$participant_day)[1L],
      levels = levels(data$participant_day)
    )
  )
  eta <- h02_term_contribution(fit, representative, common_index)
  tibble::tibble(
    base_run_id = base_run_id,
    placement = placement,
    model_variant = model_variant,
    cyclic_continuity_imposed = cyclic_expected,
    finite_difference_step_hours = step_hours,
    eta_at_00 = eta[1L],
    eta_at_24 = eta[4L],
    midnight_value_jump_eta = eta[4L] - eta[1L],
    midnight_ratio_24_to_00 = 10^(eta[4L] - eta[1L]),
    derivative_at_00_eta_per_hour = (eta[2L] - eta[1L]) / step_hours,
    derivative_at_24_eta_per_hour = (eta[4L] - eta[3L]) / step_hours,
    midnight_derivative_jump_eta_per_hour =
      (eta[4L] - eta[3L]) / step_hours -
      (eta[2L] - eta[1L]) / step_hours
  )
}
