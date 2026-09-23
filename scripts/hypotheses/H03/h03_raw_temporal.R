h03_fit_raw_temporal_bam <- function(data, rho) {
  s <- mgcv::s
  fit_formula <- formula
  environment(fit_formula) <- environment()
  captured <- h03_capture_warnings(mgcv::bam(
    formula = fit_formula,
    data = data,
    family = mgcv::Tweedie(p = working_power, link = "log"),
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

h03_raw_temporal_object <- function(entry) {
  model_path <- file.path(
    model_root,
    paste0("H03_temporal_raw_mean_", entry$id, "_object.rds")
  )
  data <- h03_prepare_temporal_data(entry$bundle$data)
  message("Fitting preliminary raw temporal mean GAM for ", entry$placement)
  preliminary_capture <- h03_fit_raw_temporal_bam(data, rho = 0)
  preliminary <- preliminary_capture$fit
  pearson <- stats::residuals(preliminary, type = "pearson")
  rho <- unname(h03_boundary_lag_correlation(
    pearson,
    data$AR_start,
    lag = 1L
  )["correlation"])
  if (!is.finite(rho)) {
    h03_abort("Could not estimate raw temporal rho for %s", entry$placement)
  }
  rho <- pmin(0.95, pmax(-0.95, rho))
  rm(preliminary)
  invisible(gc())

  message(
    "Fitting final raw temporal mean GAM for ", entry$placement,
    " with fixed rho = ", sprintf("%.4f", rho)
  )
  final_capture <- h03_fit_raw_temporal_bam(data, rho = rho)
  object <- list(
    run_id = paste0("temporal_raw_mean__", entry$id),
    placement = entry$placement,
    data = data,
    final = final_capture$fit,
    rho = rho,
    formula = formula,
    family = paste0(
      "mgcv::Tweedie(p = ", format(working_power, digits = 8),
      ", link = 'log')"
    ),
    working_power = working_power,
    basis_variant = "inherited_thin_plate_sz",
    preliminary_warnings = preliminary_capture$warnings,
    final_warnings = final_capture$warnings,
    inferential_role = paste(
      "exploratory raw-scale conditional-mean analysis;",
      "no simulation or curve-wide inference"
    )
  )
  write_rds_artifact(object, model_path, producer)
  list(object = object, path = model_path)
}

h03_raw_temporal_predictions <- function(object) {
  fit <- object$final
  data <- object$data
  covariance <- h03_temporal_covariance(fit)
  beta <- stats::coef(fit)
  time_grid <- seq(0.5, 23.5, by = 1)
  grid <- tidyr::crossing(
    time_hour = time_grid,
    light_source = factor(
      levels(data$light_source),
      levels = levels(data$light_source)
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
  design <- stats::predict(fit, newdata = grid, type = "lpmatrix")
  participant_indices <- h03_smooth_coefficient_indices(
    fit,
    "s(time_hour,participant)"
  )
  day_indices <- h03_smooth_coefficient_indices(fit, "s(participant_day)")
  category_indices <- h03_smooth_coefficient_indices(
    fit,
    "s(time_hour,light_source)"
  )
  site_indices <- h03_smooth_coefficient_indices(fit, "s(time_hour,site)")
  population_design <- design
  # For population curves, retain these terms in the fitted model, but
  # omit their contributions from the displayed global/category curves.
  population_design[, c(
    site_indices,
    participant_indices,
    day_indices
  )] <- 0

  global_grid <- tibble::tibble(
    time_hour = time_grid,
    light_source = factor(
      levels(data$light_source)[1L],
      levels = levels(data$light_source)
    ),
    site = factor(levels(data$site)[1L], levels = levels(data$site)),
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
  global_design <- stats::predict(
    fit,
    newdata = global_grid,
    type = "lpmatrix"
  )
  global_design[, c(
    category_indices,
    site_indices,
    participant_indices,
    day_indices
  )] <- 0
  global_eta <- drop(global_design %*% beta)
  global_gradient <- global_design
  global_se <- sqrt(pmax(rowSums(
    (global_gradient %*% covariance) * global_gradient
  ), 0))
  global <- tibble::tibble(
    run_id = object$run_id,
    placement = object$placement,
    time_hour = time_grid,
    global_mel_edi_lx = exp(global_eta),
    pointwise_conf_low_lx = exp(global_eta - 1.96 * global_se),
    pointwise_conf_high_lx = exp(global_eta + 1.96 * global_se),
    pointwise_log_se = global_se,
    estimand = paste(
      "global raw-scale conditional arithmetic mean; site, participant,",
      "and participant-day smooths excluded"
    )
  )

  curve_rows <- split(
    seq_len(nrow(grid)),
    interaction(
      grid$time_hour,
      grid$light_source,
      drop = TRUE,
      lex.order = TRUE
    )
  )
  curve_list <- lapply(curve_rows, function(rows) {
    time_hour <- unique(grid$time_hour[rows])
    light_source <- as.character(unique(grid$light_source[rows]))
    x_bar <- colMeans(population_design[rows, , drop = FALSE])
    eta <- drop(x_bar %*% beta)
    variance <- drop(crossprod(x_bar, covariance %*% x_bar))
    se <- sqrt(max(variance, 0))
    tibble::tibble(
      run_id = object$run_id,
      placement = object$placement,
      time_hour = time_hour,
      light_source = light_source,
      estimated_mel_edi_lx = exp(eta),
      pointwise_conf_low_lx = exp(eta - 1.96 * se),
      pointwise_conf_high_lx = exp(eta + 1.96 * se),
      pointwise_log_se = se,
      site_effects_excluded = TRUE,
      estimand = paste(
        "raw-scale conditional arithmetic mean; site, participant, and",
        "participant-day smooths excluded"
      ),
      interval_type = "pointwise_95_percent_conditional"
    )
  })
  curves <- dplyr::bind_rows(curve_list)
  # Category contrasts use gratia::smooth_estimates(). On the log-link
  # scale this sum-to-zero category smooth is a log ratio to the global smooth.
  # Specify all smooth-estimation options explicitly.
  ratios <- gratia::smooth_estimates(
    fit,
    select = "s(time_hour,light_source)",
    n = length(time_grid),
    unconditional = FALSE,
    overall_uncertainty = TRUE
  ) |>
    dplyr::transmute(
      run_id = object$run_id,
      placement = object$placement,
      time_hour = .data$time_hour,
      light_source = as.character(.data$light_source),
      ratio_to_global = exp(.data$.estimate),
      ratio_conf_low = exp(.data$.estimate - 1.96 * .data$.se),
      ratio_conf_high = exp(.data$.estimate + 1.96 * .data$.se),
      pointwise_log_ratio_se = .data$.se,
      reference = paste(
        "global raw-scale conditional time-of-day mean; site, participant,",
        "and participant-day smooths excluded"
      ),
      extraction = "gratia::smooth_estimates(overall_uncertainty = TRUE)",
      interval_type = "pointwise_95_percent_gratia_smooth_estimate"
    )
  ratio_validation <- curves |>
    dplyr::left_join(
      global |>
        dplyr::select("time_hour", "global_mel_edi_lx"),
      by = "time_hour",
      relationship = "many-to-one"
    ) |>
    dplyr::left_join(
      ratios |>
        dplyr::select("time_hour", "light_source", "ratio_to_global"),
      by = c("time_hour", "light_source"),
      relationship = "one-to-one"
    ) |>
    dplyr::mutate(
      curve_ratio = .data$estimated_mel_edi_lx / .data$global_mel_edi_lx
    )
  maximum_ratio_difference <- max(abs(
    ratio_validation$curve_ratio - ratio_validation$ratio_to_global
  ))
  if (!is.finite(maximum_ratio_difference) ||
      maximum_ratio_difference > 1e-10) {
    h03_abort(
      "gratia ratio extraction disagrees with displayed curves (max = %.3g)",
      maximum_ratio_difference
    )
  }
  registry <- inputs$categories |>
    dplyr::transmute(
      .data$category_order,
      .data$category_code,
      light_source = .data$category_label,
      .data$short_label,
      .data$figure_label
    )
  curves <- curves |>
    dplyr::left_join(
      registry,
      by = "light_source",
      relationship = "many-to-one"
    ) |>
    dplyr::arrange(.data$category_order, .data$time_hour)
  ratios <- ratios |>
    dplyr::left_join(
      registry,
      by = "light_source",
      relationship = "many-to-one"
    ) |>
    dplyr::arrange(.data$category_order, .data$time_hour)
  list(curves = curves, ratios = ratios, global = global)
}

h03_raw_temporal_diagnostics <- function(object) {
  fit <- object$final
  summary_fit <- summary(fit)
  residual <- if (!is.null(fit$std.rsd) &&
      length(fit$std.rsd) == nrow(object$data)) {
    fit$std.rsd
  } else {
    stats::residuals(fit, type = "pearson")
  }
  lag_one <- h03_boundary_lag_correlation(
    residual,
    object$data$AR_start,
    lag = 1L
  )
  hessian <- fit$outer.info$hess
  hessian_values <- if (
    is.matrix(hessian) && all(is.finite(hessian))
  ) {
    eigen(
      (hessian + t(hessian)) / 2,
      symmetric = TRUE,
      only.values = TRUE
    )$values
  } else {
    NA_real_
  }
  fitted_mean <- stats::fitted(fit)
  dispersion <- summary_fit$scale
  lambda <- fitted_mean^(2 - object$working_power) /
    (dispersion * (2 - object$working_power))
  working_zero <- exp(-lambda)
  tibble::tibble(
    run_id = object$run_id,
    placement = object$placement,
    formula = paste(deparse(object$formula), collapse = " "),
    response = "geo_medi_1h",
    estimand = "conditional arithmetic mean of hourly geometric melEDI",
    family = object$family,
    working_power = object$working_power,
    method = "fREML",
    discrete = TRUE,
    nthreads = 1L,
    observations = nrow(object$data),
    participants = nlevels(object$data$participant),
    participant_days = nlevels(object$data$participant_day),
    sites = nlevels(object$data$site),
    categories = nlevels(object$data$light_source),
    rho = object$rho,
    rank = fit$rank,
    coefficients = length(stats::coef(fit)),
    total_edf = sum(fit$edf),
    adjusted_r_squared = summary_fit$r.sq,
    deviance_explained = summary_fit$dev.expl,
    residual_scale = summary_fit$scale,
    converged = identical(h03_gam_convergence(fit), "full convergence"),
    convergence = h03_gam_convergence(fit),
    preliminary_warning_count = length(unique(object$preliminary_warnings)),
    preliminary_warnings = paste(unique(object$preliminary_warnings), collapse = " | "),
    final_warning_count = length(unique(object$final_warnings)),
    final_warnings = paste(unique(object$final_warnings), collapse = " | "),
    warning_count = length(unique(c(
      object$preliminary_warnings,
      object$final_warnings
    ))),
    smoothing_gradient_maximum_absolute = max(abs(fit$outer.info$grad)),
    smoothing_hessian_minimum_eigenvalue = min(hessian_values),
    smoothing_hessian_positive_definite = all(hessian_values > 0),
    standardized_residual_lag1 = lag_one[["correlation"]],
    standardized_residual_lag1_pairs = lag_one[["pairs"]],
    absolute_residual_fitted_spearman = stats::cor(
      abs(residual),
      fitted_mean,
      method = "spearman"
    ),
    observed_zero_fraction = mean(object$data$geo_medi_1h == 0),
    working_expected_zero_fraction = mean(working_zero),
    no_simulation = TRUE
  )
}
