# Fit and diagnose the versioned H02-aligned H06-daily temporal pilot.

h06d_h02_fit_temporal_pilot <- function(frame) {
  formula <- h06d_h02_temporal_formula("response")
  family <- stats::gaussian(link = "identity")

  message("H02-aligned temporal pilot: preliminary full model with rho = 0")
  preliminary <- h06d_fit_bam(
    formula = formula,
    data = frame,
    family = family,
    rho = 0
  )
  if (is.null(preliminary$value)) {
    h06d_abort(
      "H02-aligned preliminary BAM failed: %s",
      preliminary$error
    )
  }
  preliminary_residual <- stats::residuals(
    preliminary$value,
    type = "response"
  )
  rho_raw <- unname(h06d_boundary_lag_correlation(
    preliminary_residual,
    frame$AR_start,
    lag = 1L
  )[["correlation"]])
  if (!is.finite(rho_raw)) {
    h06d_abort("H02-aligned preliminary BAM did not yield a finite rho")
  }
  bounds <- h06d_h02_temporal_specification()$rho_bounds
  rho <- max(bounds[[1L]], min(bounds[[2L]], rho_raw))

  message(sprintf(
    "H02-aligned temporal pilot: identical final model with rho = %.4f",
    rho
  ))
  final <- h06d_fit_bam(
    formula = formula,
    data = frame,
    family = family,
    rho = rho
  )
  if (is.null(final$value)) {
    h06d_abort("H02-aligned final BAM failed: %s", final$error)
  }

  list(
    data = frame,
    formula = formula,
    family = family,
    preliminary = preliminary,
    final = final,
    rho_unclamped = rho_raw,
    rho = rho
  )
}

h06d_h02_standardized_residual <- function(fit) {
  if (!is.null(fit$std.rsd) && length(fit$std.rsd) == stats::nobs(fit)) {
    return(as.numeric(fit$std.rsd))
  }
  as.numeric(stats::residuals(fit, type = "pearson"))
}

h06d_h02_smooth_registry <- function(fit) {
  dplyr::bind_rows(lapply(fit$smooth, function(smooth) {
    index <- seq.int(smooth$first.para, smooth$last.para)
    declared_margin <- dplyr::case_when(
      identical(smooth$label, "s(time_hour)") ~ "cyclic cubic",
      grepl("participant_day", smooth$label, fixed = TRUE) ~ "random effect",
      TRUE ~ "default thin plate"
    )
    tibble::tibble(
      term = smooth$label,
      smooth_class = class(smooth)[[1L]],
      declared_time_margin = declared_margin,
      xt_is_null = is.null(smooth$xt),
      coefficient_columns = length(index),
      effective_df = sum(fit$edf[index]),
      first_parameter = smooth$first.para,
      last_parameter = smooth$last.para
    )
  }))
}

h06d_h02_residual_diagnostics <- function(pilot) {
  fit <- pilot$final$value
  preliminary_fit <- pilot$preliminary$value
  frame <- pilot$data
  response_residual <- as.numeric(stats::residuals(fit, type = "response"))
  standardized_residual <- h06d_h02_standardized_residual(fit)
  preliminary_residual <- as.numeric(stats::residuals(
    preliminary_fit,
    type = "response"
  ))
  fitted_value <- as.numeric(stats::fitted(fit))
  preliminary_lag <- h06d_boundary_lag_correlation(
    preliminary_residual,
    frame$AR_start,
    lag = 1L
  )
  final_lag <- h06d_boundary_lag_correlation(
    standardized_residual,
    frame$AR_start,
    lag = 1L
  )
  qq_theoretical <- stats::qnorm(stats::ppoints(length(standardized_residual)))
  qq_observed <- sort(standardized_residual)
  hessian <- h06d_smoothing_hessian(fit)
  fit_summary <- summary(fit)
  hat <- fit$hat

  tibble::tibble(
    implementation_id = h06d_h02_temporal_specification()$implementation_id,
    formula = paste(deparse(pilot$formula), collapse = " "),
    family = fit$family$family,
    link = fit$family$link,
    observations_30_minute = nrow(frame),
    participant_days = dplyr::n_distinct(frame$participant_day_key),
    participants = dplyr::n_distinct(frame$participant_key),
    sites = dplyr::n_distinct(frame$site),
    exact_zero_bins = sum(frame$arithmetic_mean_medi_lx == 0),
    exact_zero_fraction = mean(frame$arithmetic_mean_medi_lx == 0),
    rho_unclamped = pilot$rho_unclamped,
    rho = pilot$rho,
    preliminary_residual_lag1 = preliminary_lag[["correlation"]],
    preliminary_residual_lag1_pairs = preliminary_lag[["pairs"]],
    final_standardized_residual_lag1 = final_lag[["correlation"]],
    final_standardized_residual_lag1_pairs = final_lag[["pairs"]],
    response_residual_rmse = sqrt(mean(response_residual^2)),
    standardized_residual_rmse = sqrt(mean(standardized_residual^2)),
    standardized_residual_mean = mean(standardized_residual),
    standardized_residual_sd = stats::sd(standardized_residual),
    standardized_residual_qq_correlation = stats::cor(
      qq_theoretical,
      qq_observed
    ),
    absolute_residual_fitted_spearman = suppressWarnings(stats::cor(
      abs(standardized_residual),
      fitted_value,
      method = "spearman",
      use = "complete.obs"
    )),
    convergence = h06d_bam_convergence(fit),
    rank = fit$rank,
    coefficients = length(stats::coef(fit)),
    total_effective_df = sum(fit$edf),
    adjusted_r_squared = fit_summary$r.sq,
    deviance_explained = fit_summary$dev.expl,
    dispersion = fit_summary$scale,
    smoothing_hessian_minimum_eigenvalue = hessian[["minimum"]],
    smoothing_hessian_minimum_relative_eigenvalue =
      hessian[["minimum_relative"]],
    smoothing_hessian_positive_definite = as.logical(
      hessian[["positive_definite"]]
    ),
    maximum_hat = if (length(hat)) max(hat, na.rm = TRUE) else NA_real_,
    preliminary_warning_count = length(pilot$preliminary$warnings),
    final_warning_count = length(pilot$final$warnings),
    preliminary_warnings = paste(pilot$preliminary$warnings, collapse = " | "),
    final_warnings = paste(pilot$final$warnings, collapse = " | "),
    preliminary_elapsed_seconds = pilot$preliminary$elapsed_seconds,
    final_elapsed_seconds = pilot$final$elapsed_seconds,
    total_fit_elapsed_seconds = pilot$preliminary$elapsed_seconds +
      pilot$final$elapsed_seconds
  )
}

h06d_h02_site_residual_acf <- function(pilot) {
  residual <- h06d_h02_standardized_residual(pilot$final$value)
  pilot$data |>
    dplyr::mutate(.residual = residual) |>
    dplyr::group_split(.data$site, .keep = TRUE) |>
    lapply(function(site_data) {
      lag <- h06d_boundary_lag_correlation(
        site_data$.residual,
        site_data$AR_start,
        lag = 1L
      )
      tibble::tibble(
        site = as.character(site_data$site[[1L]]),
        residual_lag1 = lag[["correlation"]],
        adjacent_pairs = lag[["pairs"]],
        observations_30_minute = nrow(site_data),
        participant_days = dplyr::n_distinct(site_data$participant_day_key),
        participants = dplyr::n_distinct(site_data$participant_key)
      )
    }) |>
    dplyr::bind_rows()
}

h06d_h02_participant_day_residual_acf <- function(pilot) {
  residual <- h06d_h02_standardized_residual(pilot$final$value)
  pilot$data |>
    dplyr::mutate(.residual = residual) |>
    dplyr::group_split(.data$participant_day_key, .keep = TRUE) |>
    lapply(function(day_data) {
      lag <- h06d_boundary_lag_correlation(
        day_data$.residual,
        day_data$AR_start,
        lag = 1L
      )
      tibble::tibble(
        participant_day_key = day_data$participant_day_key[[1L]],
        site = as.character(day_data$site[[1L]]),
        participant_key = day_data$participant_key[[1L]],
        observations_30_minute = nrow(day_data),
        residual_lag1 = lag[["correlation"]],
        adjacent_pairs = lag[["pairs"]]
      )
    }) |>
    dplyr::bind_rows()
}

h06d_h02_global_closure <- function(pilot) {
  fit <- pilot$final$value
  grid <- pilot$data[rep(1L, 2L), , drop = FALSE]
  grid$time_hour <- c(0, 24)
  grid$sleep_between_h <- 0
  grid$sleep_within_h <- 0
  term_prediction <- stats::predict(
    fit,
    newdata = grid,
    type = "terms",
    terms = "s(time_hour)",
    discrete = FALSE,
    newdata.guaranteed = TRUE
  )
  global <- as.numeric(term_prediction[, "s(time_hour)"])
  endpoint_difference <- abs(global[[2L]] - global[[1L]])
  tolerance <- h06d_h02_temporal_specification()$global_closure_tolerance
  tibble::tibble(
    term = "s(time_hour)",
    link_at_0 = global[[1L]],
    link_at_24 = global[[2L]],
    absolute_endpoint_difference_link = endpoint_difference,
    tolerance = tolerance,
    cyclic_closure_pass = endpoint_difference < tolerance
  )
}

h06d_h02_diagnostic_verdict <- function(
  support,
  component,
  site_acf,
  k_check,
  identifiability,
  closure,
  smooth_registry
) {
  spec <- h06d_h02_temporal_specification()
  context_k <- k_check |>
    dplyr::filter(
      !grepl("participant", .data$term, fixed = TRUE),
      !grepl("participant_day", .data$term, fixed = TRUE)
    ) |>
    dplyr::mutate(edf_fraction = .data$effective_df / .data$k_prime)
  fixed_identifiability <- identifiability |>
    dplyr::filter(
      !grepl("participant", .data$term, fixed = TRUE),
      !grepl("participant_day", .data$term, fixed = TRUE)
    )
  exact_formula <- paste(deparse(h06d_h02_temporal_formula()), collapse = " ")
  fitted_formula <- component$formula[[1L]]
  smooth_contract_pass <-
    identical(exact_formula, fitted_formula) &&
    all(smooth_registry$xt_is_null) &&
    !grepl("xt", fitted_formula, fixed = TRUE)
  hessian_pass <- isTRUE(component$smoothing_hessian_positive_definite[[1L]]) ||
    (
      is.finite(component$smoothing_hessian_minimum_relative_eigenvalue[[1L]]) &&
        component$smoothing_hessian_minimum_relative_eigenvalue[[1L]] > -1e-8
    )
  finite_edf_fraction <- is.finite(context_k$edf_fraction)
  finite_k_index <- is.finite(context_k$k_index)
  basis_pass <- any(finite_edf_fraction) && all(
    !finite_edf_fraction |
      context_k$edf_fraction < spec$basis_edf_fraction_limit
  ) && all(
    !finite_k_index |
      context_k$k_index >= spec$basis_k_index_limit
  )
  maximum_edf_fraction <- if (any(finite_edf_fraction)) {
    max(context_k$edf_fraction[finite_edf_fraction])
  } else {
    NA_real_
  }
  minimum_k_index <- if (any(finite_k_index)) {
    min(context_k$k_index[finite_k_index])
  } else {
    NA_real_
  }
  identifiability_max <- if (nrow(fixed_identifiability)) {
    max(fixed_identifiability$fitted_term_multiple_r_squared, na.rm = TRUE)
  } else {
    NA_real_
  }
  identifiability_pass <- is.finite(identifiability_max) &&
    identifiability_max < spec$fixed_term_concurvity_limit
  support_pass <-
    min(support$context_cells$participant_days) >= 30L &&
    min(support$context_cells$sites) >= 5L &&
    support$overall$participants_with_two_or_more_days >= 50L &&
    support$overall$participants_with_within_sleep_variation >= 50L
  pooled_lag <- component$final_standardized_residual_lag1[[1L]]
  site_lag_max <- max(abs(site_acf$residual_lag1), na.rm = TRUE)
  residual_dependence_pass <-
    abs(pooled_lag) < spec$pooled_residual_lag1_limit &&
    site_lag_max < spec$site_residual_lag1_limit
  distribution_pass <-
    component$standardized_residual_qq_correlation[[1L]] >=
      spec$residual_qq_correlation_limit &&
    abs(component$absolute_residual_fitted_spearman[[1L]]) <
      spec$residual_scale_pattern_limit

  verdict <- tibble::tribble(
    ~domain, ~evidence, ~status, ~required_action,
    "Frame and context support",
    sprintf(
      "%d observations; %d days; %d participants; minimum context cell %d days across %d sites",
      support$overall$observations_30_minute,
      support$overall$participant_days,
      support$overall$participants,
      min(support$context_cells$participant_days),
      min(support$context_cells$sites)
    ),
    ifelse(support_pass, "PASS", "FAIL"),
    ifelse(support_pass, "retain frame", "revise context estimand or support rule"),
    "Formula and basis inheritance",
    paste(
      "exact formula match =", identical(exact_formula, fitted_formula),
      "; every fitted smooth xt is NULL =", all(smooth_registry$xt_is_null)
    ),
    ifelse(smooth_contract_pass, "PASS", "FAIL"),
    ifelse(smooth_contract_pass, "retain contract", "stop and correct formula"),
    "Convergence and smoothing Hessian",
    sprintf(
      "%s; warnings %d/%d; Hessian min relative %.3g",
      component$convergence,
      component$preliminary_warning_count,
      component$final_warning_count,
      component$smoothing_hessian_minimum_relative_eigenvalue
    ),
    ifelse(
      component$convergence == "full convergence" &&
        component$preliminary_warning_count == 0L &&
        component$final_warning_count == 0L && hessian_pass,
      "PASS",
      "FAIL"
    ),
    "repair before interpreting context terms",
    "Basis capacity",
    sprintf(
      "maximum monitored edf/k-prime %.3f; minimum finite k-index %.3f",
      maximum_edf_fraction,
      minimum_k_index
    ),
    ifelse(basis_pass, "PASS", "FAIL"),
    ifelse(basis_pass, "retain k", "run a term-specific bounded basis repair"),
    "Residual distribution and scale pattern",
    sprintf(
      "QQ correlation %.3f; Spearman |residual|-fitted %.3f",
      component$standardized_residual_qq_correlation,
      component$absolute_residual_fitted_spearman
    ),
    ifelse(distribution_pass, "PASS", "FAIL"),
    ifelse(distribution_pass, "retain Gaussian diagnostic architecture", "reassess transform or variance model"),
    "Residual temporal dependence",
    sprintf(
      "pooled lag-1 %.3f; maximum absolute site lag-1 %.3f",
      pooled_lag,
      site_lag_max
    ),
    ifelse(residual_dependence_pass, "PASS", "FAIL"),
    ifelse(residual_dependence_pass, "retain working AR correction", "do not interpret curves; repair dependence"),
    "Fixed-term identifiability screen",
    sprintf("maximum bounded fitted-term multiple R-squared %.3f", identifiability_max),
    ifelse(identifiability_pass, "PASS", "FAIL"),
    ifelse(identifiability_pass, "retain joint context model", "revise joint context parameterization"),
    "Global cyclic closure",
    sprintf(
      "absolute 24:00 versus 00:00 link difference %.3g",
      closure$absolute_endpoint_difference_link
    ),
    ifelse(closure$cyclic_closure_pass, "PASS", "FAIL"),
    ifelse(closure$cyclic_closure_pass, "retain global cyclic smooth", "stop and repair cyclic contract")
  )
  overall_pass <- all(verdict$status == "PASS")
  dplyr::bind_rows(
    verdict,
    tibble::tibble(
      domain = "Overall pilot gate",
      evidence = paste(
        sum(verdict$status == "PASS"),
        "of",
        nrow(verdict),
        "diagnostic domains passed"
      ),
      status = ifelse(
        overall_pass,
        "ACCEPTABLE_FOR_BOUNDED_EFFECT_EXTRACTION",
        "REPAIR_REQUIRED"
      ),
      required_action = ifelse(
        overall_pass,
        "stop for author approval before effect extraction",
        "stop; repair failed domains before effect extraction"
      )
    )
  )
}
