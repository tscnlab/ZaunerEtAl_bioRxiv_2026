# H03 exploratory GAM/GAMM fitting, diagnostics, curves, and point partitions.

h03_prepare_temporal_data <- function(frame) {
  site_levels <- levels(droplevels(frame$site))
  category_levels <- levels(frame$light_source)
  participant_levels <- sort(unique(as.character(frame$participant)))
  day_levels <- sort(unique(as.character(frame$participant_day)))
  frame |>
    dplyr::mutate(
      site = factor(as.character(.data$site), levels = site_levels),
      light_source = factor(
        as.character(.data$light_source),
        levels = category_levels
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
      .data$local_date,
      .data$interval_start_utc,
      .data$clock_minute
    )
}

h03_fit_bam <- function(formula, data, rho = 0) {
  s <- mgcv::s
  environment(formula) <- environment()
  captured <- h03_capture_warnings(mgcv::bam(
    formula = formula,
    data = data,
    family = stats::gaussian(link = "identity"),
    method = "fREML",
    discrete = TRUE,
    rho = rho,
    AR.start = data$AR_start,
    knots = list(time_hour = c(0, 24)),
    nthreads = 1L,
    gc.level = 1L,
    drop.unused.levels = TRUE
  ))
  fit <- captured$value
  attr(fit, "h03_warnings") <- captured$warnings
  fit
}

h03_temporal_rho <- function(preliminary, data) {
  residual <- stats::residuals(preliminary, type = "response")
  estimate <- unname(h03_boundary_lag_correlation(
    residual,
    data$AR_start,
    lag = 1L
  )["correlation"])
  if (!is.finite(estimate)) {
    h03_abort("Could not estimate H03 boundary-aware temporal rho")
  }
  pmin(0.95, pmax(-0.95, estimate))
}

h03_fit_temporal_model <- function(
  frame,
  run_id,
  formula = h03_formula_set()$temporal_category,
  basis_variant = "inherited_thin_plate_sz"
) {
  data <- h03_prepare_temporal_data(frame)
  preliminary <- h03_fit_bam(formula, data, rho = 0)
  rho <- h03_temporal_rho(preliminary, data)
  final <- h03_fit_bam(formula, data, rho = rho)
  list(
    run_id = run_id,
    data = data,
    final = final,
    rho = rho,
    formula = formula,
    basis_variant = basis_variant
  )
}

h03_gam_convergence <- function(fit) {
  if (is.logical(fit$mgcv.conv) && length(fit$mgcv.conv) == 1L) {
    return(if (isTRUE(fit$mgcv.conv)) {
      "full convergence"
    } else {
      "not fully converged"
    })
  }
  if (is.list(fit$outer.info) && !is.null(fit$outer.info$conv)) {
    return(as.character(fit$outer.info$conv))
  }
  if (is.list(fit$mgcv.conv) &&
      !is.null(fit$mgcv.conv$fully.converged)) {
    return(if (isTRUE(fit$mgcv.conv$fully.converged)) {
      "full convergence"
    } else {
      "not fully converged"
    })
  }
  if (is.logical(fit$converged) && length(fit$converged) == 1L) {
    return(if (isTRUE(fit$converged)) {
      "full convergence"
    } else {
      "not fully converged"
    })
  }
  "not reported"
}

h03_temporal_model_summary <- function(object, placement) {
  fit <- object$final
  summary_fit <- summary(fit)
  residual <- if (!is.null(fit$std.rsd) &&
      length(fit$std.rsd) == nrow(object$data)) {
    fit$std.rsd
  } else {
    stats::residuals(fit, type = "response")
  }
  lag_one <- h03_boundary_lag_correlation(
    residual,
    object$data$AR_start,
    lag = 1L
  )
  outer_gradient <- fit$outer.info$grad
  outer_hessian <- fit$outer.info$hess
  hessian_values <- if (
    is.matrix(outer_hessian) && all(is.finite(outer_hessian))
  ) {
    eigen(
      (outer_hessian + t(outer_hessian)) / 2,
      symmetric = TRUE,
      only.values = TRUE
    )$values
  } else {
    NA_real_
  }
  hessian_minimum <- if (all(is.na(hessian_values))) {
    NA_real_
  } else {
    min(hessian_values, na.rm = TRUE)
  }
  hessian_nonpositive <- if (all(is.na(hessian_values))) {
    NA_integer_
  } else {
    sum(hessian_values <= 0, na.rm = TRUE)
  }
  tibble::tibble(
    run_id = object$run_id,
    placement = placement,
    basis_variant = if (is.null(object$basis_variant)) {
      "inherited_thin_plate_sz"
    } else {
      object$basis_variant
    },
    formula = paste(deparse(object$formula), collapse = " "),
    observations = stats::nobs(fit),
    participants = nlevels(object$data$participant),
    participant_days = nlevels(object$data$participant_day),
    sites = nlevels(object$data$site),
    categories = nlevels(object$data$light_source),
    method = fit$method,
    discrete = TRUE,
    nthreads = 1L,
    rho = object$rho,
    rank = fit$rank,
    coefficients = length(stats::coef(fit)),
    total_edf = sum(fit$edf),
    adjusted_r_squared = summary_fit$r.sq,
    deviance_explained = summary_fit$dev.expl,
    residual_scale = fit$sig2,
    converged = identical(h03_gam_convergence(fit), "full convergence"),
    convergence = h03_gam_convergence(fit),
    smoothing_optimizer_iterations = fit$iter,
    smoothing_gradient_maximum_absolute = if (
      is.null(outer_gradient) || any(!is.finite(outer_gradient))
    ) {
      NA_real_
    } else {
      max(abs(outer_gradient))
    },
    smoothing_hessian_minimum_eigenvalue = hessian_minimum,
    smoothing_hessian_nonpositive_eigenvalues = hessian_nonpositive,
    smoothing_hessian_positive_definite = !is.na(hessian_nonpositive) &&
      hessian_nonpositive == 0L,
    smoothing_parameter_minimum = min(fit$sp),
    smoothing_parameter_maximum = max(fit$sp),
    singularity_interpretation = paste(
      "lme-style singularity is not defined for penalized bam;",
      "inspect smoothing Hessian and penalty-scale variance components"
    ),
    warnings = paste(attr(fit, "h03_warnings"), collapse = " | "),
    standardized_residual_lag1 = unname(lag_one["correlation"]),
    standardized_residual_lag1_pairs = unname(lag_one["pairs"]),
    residual_mean = mean(residual),
    residual_sd = stats::sd(residual),
    residual_skewness = mean((residual - mean(residual))^3) /
      stats::sd(residual)^3,
    residual_excess_kurtosis = mean((residual - mean(residual))^4) /
      stats::sd(residual)^4 - 3,
    residual_fitted_spearman = stats::cor(
      residual,
      stats::fitted(fit),
      method = "spearman"
    ),
    absolute_residual_fitted_spearman = stats::cor(
      abs(residual),
      stats::fitted(fit),
      method = "spearman"
    )
  )
}

h03_smooth_labels <- function(fit) {
  vapply(fit$smooth, `[[`, character(1), "label")
}

h03_smooth_coefficient_indices <- function(fit, label) {
  matches <- which(h03_smooth_labels(fit) == label)
  if (length(matches) != 1L) {
    h03_abort(
      "Expected one temporal smooth labelled `%s`; found %s",
      label,
      length(matches)
    )
  }
  seq.int(
    fit$smooth[[matches]]$first.para,
    fit$smooth[[matches]]$last.para
  )
}

h03_temporal_covariance <- function(fit) {
  covariance <- tryCatch(
    stats::vcov(fit, unconditional = TRUE),
    error = function(condition) fit$Vp
  )
  if (!all(is.finite(covariance))) {
    h03_abort("H03 temporal coefficient covariance is non-finite")
  }
  covariance
}

h03_temporal_prediction_data <- function(object) {
  data <- object$data
  tidyr::crossing(
    time_hour = seq(0.5, 23.5, by = 1),
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
}

h03_temporal_curves <- function(object, category_registry) {
  fit <- object$final
  covariance <- h03_temporal_covariance(fit)
  beta <- stats::coef(fit)
  grid <- h03_temporal_prediction_data(object)
  design <- stats::predict(fit, newdata = grid, type = "lpmatrix")
  participant_indices <- h03_smooth_coefficient_indices(
    fit,
    "s(time_hour,participant)"
  )
  day_indices <- h03_smooth_coefficient_indices(fit, "s(participant_day)")
  population_design <- design
  population_design[, c(participant_indices, day_indices)] <- 0

  curve_rows <- split(
    seq_len(nrow(grid)),
    interaction(grid$time_hour, grid$light_source, drop = TRUE, lex.order = TRUE)
  )
  curves <- lapply(curve_rows, function(rows) {
    eta <- drop(population_design[rows, , drop = FALSE] %*% beta)
    # Author amendment 2026-08-07: average site predictions on the fitted
    # log10 scale and back-transform once, matching the H03 primary
    # cross-site standardization convention.
    log_mean <- mean(eta)
    gradient_log_mean <- colMeans(
      population_design[rows, , drop = FALSE]
    )
    estimate <- 10^log_mean - 0.1
    variance <- drop(crossprod(
      gradient_log_mean,
      covariance %*% gradient_log_mean
    ))
    se <- sqrt(max(variance, 0))
    tibble::tibble(
      time_hour = unique(grid$time_hour[rows]),
      light_source = as.character(unique(grid$light_source[rows])),
      site_standardized_mel_edi_lx = max(estimate, 0),
      pointwise_conf_low_lx = max(10^(log_mean - 1.96 * se) - 0.1, 0),
      pointwise_conf_high_lx = max(10^(log_mean + 1.96 * se) - 0.1, 0),
      pointwise_log10_se = se,
      sites_standardized = length(rows),
      interval_type = "pointwise_95_percent_conditional"
    )
  }) |>
    dplyr::bind_rows()

  category_indices <- h03_smooth_coefficient_indices(
    fit,
    "s(time_hour,light_source)"
  )
  deviation_grid <- tidyr::crossing(
    time_hour = seq(0.5, 23.5, by = 1),
    light_source = factor(
      levels(object$data$light_source),
      levels = levels(object$data$light_source)
    )
  ) |>
    dplyr::mutate(
      site = factor(
        levels(object$data$site)[1L],
        levels = levels(object$data$site)
      ),
      participant = factor(
        levels(object$data$participant)[1L],
        levels = levels(object$data$participant)
      ),
      participant_day = factor(
        levels(object$data$participant_day)[1L],
        levels = levels(object$data$participant_day)
      ),
      AR_start = TRUE
    )
  deviation_design <- stats::predict(
    fit,
    newdata = deviation_grid,
    type = "lpmatrix"
  )
  term_design <- matrix(0, nrow(deviation_design), ncol(deviation_design))
  term_design[, category_indices] <- deviation_design[, category_indices]
  deviation_estimate <- drop(term_design %*% beta)
  deviation_se <- sqrt(pmax(rowSums((term_design %*% covariance) * term_design), 0))
  deviations <- deviation_grid |>
    dplyr::transmute(
      .data$time_hour,
      light_source = as.character(.data$light_source),
      deviation_log10 = deviation_estimate,
      pointwise_conf_low_log10 = deviation_estimate - 1.96 * deviation_se,
      pointwise_conf_high_log10 = deviation_estimate + 1.96 * deviation_se,
      pointwise_se_log10 = deviation_se,
      reference = "global_time_of_day_smooth",
      interval_type = "pointwise_95_percent_conditional"
    )

  global_indices <- h03_smooth_coefficient_indices(fit, "s(time_hour)")
  global_grid <- tibble::tibble(
    time_hour = seq(0.5, 23.5, by = 1),
    light_source = factor(
      levels(object$data$light_source)[1L],
      levels = levels(object$data$light_source)
    ),
    site = factor(
      levels(object$data$site)[1L],
      levels = levels(object$data$site)
    ),
    participant = factor(
      levels(object$data$participant)[1L],
      levels = levels(object$data$participant)
    ),
    participant_day = factor(
      levels(object$data$participant_day)[1L],
      levels = levels(object$data$participant_day)
    ),
    AR_start = TRUE
  )
  global_design <- stats::predict(
    fit,
    newdata = global_grid,
    type = "lpmatrix"
  )
  keep_global <- c(match("(Intercept)", names(beta)), global_indices)
  keep_global <- keep_global[!is.na(keep_global)]
  global_only <- matrix(0, nrow(global_design), ncol(global_design))
  global_only[, keep_global] <- global_design[, keep_global]
  global_eta <- drop(global_only %*% beta)
  global_variance <- rowSums((global_only %*% covariance) * global_only)
  global_se <- sqrt(pmax(global_variance, 0))
  global <- tibble::tibble(
    time_hour = seq(0.5, 23.5, by = 1),
    global_mel_edi_lx = pmax(10^global_eta - 0.1, 0),
    pointwise_conf_low_lx = pmax(10^(global_eta - 1.96 * global_se) - 0.1, 0),
    pointwise_conf_high_lx = pmax(10^(global_eta + 1.96 * global_se) - 0.1, 0),
    interval_type = "pointwise_95_percent_conditional"
  )

  registry <- category_registry |>
    dplyr::select(
      light_source = "category_label",
      "category_order",
      "category_code",
      "short_label",
      "figure_label"
    )
  list(
    curves = dplyr::left_join(curves, registry, by = "light_source") |>
      dplyr::arrange(.data$category_order, .data$time_hour),
    deviations = dplyr::left_join(deviations, registry, by = "light_source") |>
      dplyr::arrange(.data$category_order, .data$time_hour),
    global = global
  )
}

h03_temporal_support <- function(object, category_registry, spec) {
  object$data |>
    dplyr::group_by(.data$light_source, .data$time_hour) |>
    dplyr::summarise(
      participant_hours = dplyr::n(),
      participants = dplyr::n_distinct(.data$participant),
      participant_days = dplyr::n_distinct(.data$participant_day),
      sites = dplyr::n_distinct(.data$site),
      .groups = "drop"
    ) |>
    tidyr::complete(
      light_source = factor(
        category_registry$category_label,
        levels = category_registry$category_label
      ),
      time_hour = seq(0.5, 23.5, by = 1),
      fill = list(
        participant_hours = 0L,
        participants = 0L,
        participant_days = 0L,
        sites = 0L
      )
    ) |>
    dplyr::mutate(
      light_source = as.character(.data$light_source),
      locally_sparse = .data$participant_hours <
        spec$temporal$local_sparse_hours |
        .data$participants < spec$temporal$local_sparse_participants |
        .data$sites < spec$temporal$local_sparse_sites
    ) |>
    dplyr::left_join(
      category_registry |>
        dplyr::select(
          light_source = "category_label",
          "category_order",
          "category_code",
          "short_label",
          "figure_label"
        ),
      by = "light_source"
    ) |>
    dplyr::arrange(.data$category_order, .data$time_hour)
}

h03_temporal_k_check <- function(object, placement) {
  # mgcv::k.check() defaults to a random 5,000-row subsample and 400
  # permutations. Neither is appropriate at this computation gate. Using all
  # rows and zero permutations retains the deterministic k-index/edf capacity
  # diagnostic while deliberately leaving the resampling p-value unavailable.
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
      placement = placement,
      resampling_replicates = 0L,
      p_value = NA_real_,
      interpretation = paste(
        "deterministic basis-capacity diagnostic;",
        "no k-check permutation p-value was computed"
      ),
      .before = 1
    )
}

h03_temporal_concurvity <- function(object, placement) {
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
          placement = placement,
          method = "mgcv_full_concurvity",
          standard_mgcv_diagnostic_available = TRUE,
          diagnostic_note = NA_character_,
          .before = 1
        )
    )
  }

  # The high-dimensional fs/re design can make the LAPACK SVD used by
  # mgcv::concurvity() fail. As a deterministic, explicitly non-equivalent
  # fallback, quantify how well each *fitted term contribution* is linearly
  # reconstructed by the remaining fitted term contributions. This is a
  # component-dependence diagnostic, not a replacement mgcv basis-concurvity
  # statistic, and is labelled accordingly in every output.
  contributions <- as.matrix(stats::predict(
    object$final,
    newdata = object$data,
    type = "terms"
  ))
  fallback <- lapply(seq_len(ncol(contributions)), function(index) {
    response <- contributions[, index]
    others <- contributions[, -index, drop = FALSE]
    fit <- stats::lm.fit(cbind(`(Intercept)` = 1, others), response)
    total <- sum((response - mean(response))^2)
    r_squared <- if (total > 0) {
      1 - sum(fit$residuals^2) / total
    } else {
      NA_real_
    }
    tibble::tibble(
      measure = "observed_term_contribution_multiple_r_squared",
      term = colnames(contributions)[index],
      concurvity = r_squared
    )
  }) |>
    dplyr::bind_rows()
  fallback |>
    dplyr::mutate(
      run_id = object$run_id,
      placement = placement,
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

h03_temporal_weights <- function(data) {
  participant_counts <- data |>
    dplyr::distinct(.data$site, .data$participant) |>
    dplyr::count(.data$site, name = "participants_in_site")
  hour_counts <- data |>
    dplyr::count(.data$site, .data$participant, name = "hours_in_participant")
  weighted <- data |>
    dplyr::select(.data$site, .data$participant) |>
    dplyr::left_join(participant_counts, by = "site", relationship = "many-to-one") |>
    dplyr::left_join(
      hour_counts,
      by = c("site", "participant"),
      relationship = "many-to-one"
    ) |>
    dplyr::mutate(
      weight = 1 / dplyr::n_distinct(data$site) /
        .data$participants_in_site /
        .data$hours_in_participant
    ) |>
    dplyr::pull(.data$weight)
  weighted / sum(weighted)
}

h03_temporal_weighted_r_squared <- function(object, placement) {
  y <- object$data$h03_temporal_response
  fitted <- stats::fitted(object$final)
  weights <- h03_temporal_weights(object$data)
  mean_y <- sum(weights * y)
  sse <- sum(weights * (y - fitted)^2)
  sst <- sum(weights * (y - mean_y)^2)
  tibble::tibble(
    run_id = object$run_id,
    placement = placement,
    estimand = "site-standardized participant-balanced in-sample R-squared",
    scale = "log10(melEDI + 0.1 lx)",
    r_squared = 1 - sse / sst,
    weighted_sse = sse,
    weighted_sst = sst,
    weight_sum = sum(weights),
    sites_equal_weight = TRUE,
    participants_equal_within_site = TRUE,
    hours_equal_within_participant = TRUE
  )
}

# Point-only implementation of the audited analyze-gamms helper contract.
# It uses the exact Shapley identity Cov(a_j, sum_k a_k) for the empirical
# weighted link-scale variance game and deliberately refuses simulations.
gamm_variance_partition <- function(
  model,
  data,
  groups,
  weights,
  n_draws = 0L,
  ...
) {
  if (!inherits(model, "gam")) {
    h03_abort("`model` must inherit from gam")
  }
  if (!identical(as.integer(n_draws), 0L)) {
    h03_abort(
      "This H03 point-partition implementation does not authorize simulations"
    )
  }
  terms <- as.matrix(stats::predict(model, newdata = data, type = "terms"))
  available <- colnames(terms)
  members <- unlist(groups, use.names = FALSE)
  if (
    is.null(names(groups)) || anyDuplicated(members) ||
      !setequal(members, available)
  ) {
    h03_abort("Temporal variance groups must partition all model terms exactly")
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
  component_variance <- diag(covariance)
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
    component_variance = as.numeric(component_variance),
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
    groups = groups,
    available_terms = available,
    reference_rows = nrow(data),
    reference_weight_sum = sum(weights),
    scale = "linear predictor",
    target = "model terms excluding the constant intercept",
    uncertainty_draws = NULL
  )
}

h03_temporal_variance_partition <- function(object, placement) {
  terms <- colnames(stats::predict(object$final, type = "terms"))
  required <- c(
    "s(time_hour)",
    "s(time_hour,light_source)",
    "s(time_hour,site)",
    "s(time_hour,participant)",
    "s(participant_day)"
  )
  if (!setequal(terms, required)) {
    h03_abort(
      "Unexpected H03 temporal term labels: %s",
      paste(terms, collapse = "; ")
    )
  }
  groups <- list(
    global_time = "s(time_hour)",
    light_source_deviations = "s(time_hour,light_source)",
    site_deviations = "s(time_hour,site)",
    participant_curves = "s(time_hour,participant)",
    participant_day_shifts = "s(participant_day)"
  )
  partition <- gamm_variance_partition(
    object$final,
    data = object$data,
    groups = groups,
    weights = h03_temporal_weights(object$data),
    n_draws = 0L
  )
  allocation <- partition$allocation |>
    dplyr::mutate(
      run_id = object$run_id,
      placement = placement,
      total_fitted_predictor_variance = partition$total_variance,
      shapley_efficiency_error = partition$shapley_efficiency_error,
      scale = "log10(melEDI + 0.1 lx) linear predictor",
      reference_distribution = paste(
        "site-standardized, participant-balanced, hours balanced within participant"
      ),
      uncertainty = "point allocation; no simulation run",
      .before = 1
    )
  covariance <- as.data.frame(as.table(partition$covariance)) |>
    tibble::as_tibble() |>
    dplyr::rename(group_1 = "Var1", group_2 = "Var2", covariance = "Freq") |>
    dplyr::mutate(
      run_id = object$run_id,
      placement = placement,
      .before = 1
    )
  list(allocation = allocation, covariance = covariance)
}

h03_temporal_variance_components <- function(object, placement) {
  result <- gratia::variance_comp(object$final, rescale = TRUE)
  tibble::as_tibble(result) |>
    dplyr::mutate(
      run_id = object$run_id,
      placement = placement,
      interpretation = paste(
        "penalty-scale variance/standard-deviation parameter;",
        "not percent outcome variance"
      ),
      .before = 1
    )
}

h03_temporal_residual_data <- function(object, placement) {
  residual <- if (!is.null(object$final$std.rsd) &&
      length(object$final$std.rsd) == nrow(object$data)) {
    object$final$std.rsd
  } else {
    stats::residuals(object$final, type = "response")
  }
  tibble::tibble(
    run_id = object$run_id,
    placement = placement,
    site = as.character(object$data$site),
    participant = as.character(object$data$participant),
    participant_day = as.character(object$data$participant_day),
    time_hour = object$data$time_hour,
    light_source = as.character(object$data$light_source),
    fitted_log10 = stats::fitted(object$final),
    standardized_residual = residual,
    theoretical_normal_quantile = stats::qnorm(
      (rank(residual, ties.method = "average") - 0.5) / length(residual)
    ),
    AR_start = object$data$AR_start
  )
}

h03_temporal_constraint_diagnostics <- function(
  object,
  curves,
  placement
) {
  category_sum <- curves$deviations |>
    dplyr::group_by(.data$time_hour) |>
    dplyr::summarise(sum_deviation = sum(.data$deviation_log10), .groups = "drop")

  fit <- object$final
  site_indices <- h03_smooth_coefficient_indices(fit, "s(time_hour,site)")
  data <- object$data
  site_grid <- tidyr::crossing(
    time_hour = seq(0.5, 23.5, by = 1),
    site = factor(levels(data$site), levels = levels(data$site))
  ) |>
    dplyr::mutate(
      light_source = factor(
        levels(data$light_source)[1L],
        levels = levels(data$light_source)
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
  design <- stats::predict(fit, newdata = site_grid, type = "lpmatrix")
  site_only <- matrix(0, nrow(design), ncol(design))
  site_only[, site_indices] <- design[, site_indices]
  site_value <- drop(site_only %*% stats::coef(fit))
  site_sum <- tibble::tibble(
    time_hour = site_grid$time_hour,
    site_value = site_value
  ) |>
    dplyr::group_by(.data$time_hour) |>
    dplyr::summarise(sum_deviation = sum(.data$site_value), .groups = "drop")

  maximum_sums <- c(
    max(abs(category_sum$sum_deviation)),
    max(abs(site_sum$sum_deviation))
  )

  tibble::tibble(
    run_id = object$run_id,
    placement = placement,
    constraint = c("light_source_sz_sum", "site_sz_sum"),
    maximum_absolute_sum = maximum_sums,
    tolerance = 1e-7,
    passes = maximum_sums <= 1e-7
  )
}

h03_temporal_midnight_diagnostic <- function(object, placement) {
  fit <- object$final
  data <- object$data
  covariance <- h03_temporal_covariance(fit)
  grid <- tidyr::crossing(
    time_hour = c(0, 24),
    light_source = factor(
      levels(data$light_source),
      levels = levels(data$light_source)
    )
  ) |>
    dplyr::mutate(
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
  design <- stats::predict(fit, newdata = grid, type = "lpmatrix")
  global_indices <- h03_smooth_coefficient_indices(fit, "s(time_hour)")
  category_indices <- h03_smooth_coefficient_indices(
    fit,
    "s(time_hour,light_source)"
  )
  intercept <- match("(Intercept)", names(stats::coef(fit)))
  allowed <- c(intercept, global_indices, category_indices)
  allowed <- allowed[!is.na(allowed)]
  population_design <- matrix(0, nrow(design), ncol(design))
  population_design[, allowed] <- design[, allowed]
  split_rows <- split(
    seq_len(nrow(grid)),
    as.character(grid$light_source)
  )
  dplyr::bind_rows(lapply(names(split_rows), function(category) {
    rows <- split_rows[[category]]
    rows <- rows[order(grid$time_hour[rows])]
    difference_design <- population_design[rows[2L], ] -
      population_design[rows[1L], ]
    estimate <- drop(difference_design %*% stats::coef(fit))
    se <- sqrt(max(drop(crossprod(
      difference_design,
      covariance %*% difference_design
    )), 0))
    tibble::tibble(
      run_id = object$run_id,
      placement = placement,
      light_source = category,
      endpoint_difference_log10 = estimate,
      endpoint_difference_se = se,
      endpoint_difference_abs = abs(estimate),
      global_component_is_cyclic = TRUE,
      category_deviation_basis_is_cyclic = identical(
        if (is.null(object$basis_variant)) {
          "inherited_thin_plate_sz"
        } else {
          object$basis_variant
        },
        "cyclic_sz"
      ),
      site_deviation_basis_is_cyclic = identical(
        if (is.null(object$basis_variant)) {
          "inherited_thin_plate_sz"
        } else {
          object$basis_variant
        },
        "cyclic_sz"
      ),
      interpretation = paste(
        "24 h minus 0 h for global plus category deviation;",
        "descriptive endpoint diagnostic"
      )
    )
  }))
}

h03_temporal_site_midnight_diagnostic <- function(object, placement) {
  fit <- object$final
  data <- object$data
  covariance <- h03_temporal_covariance(fit)
  grid <- tidyr::crossing(
    time_hour = c(0, 24),
    site = factor(levels(data$site), levels = levels(data$site))
  ) |>
    dplyr::mutate(
      light_source = factor(
        levels(data$light_source)[1L],
        levels = levels(data$light_source)
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
  global_indices <- h03_smooth_coefficient_indices(fit, "s(time_hour)")
  site_indices <- h03_smooth_coefficient_indices(fit, "s(time_hour,site)")
  intercept <- match("(Intercept)", names(stats::coef(fit)))
  allowed <- c(intercept, global_indices, site_indices)
  allowed <- allowed[!is.na(allowed)]
  population_design <- matrix(0, nrow(design), ncol(design))
  population_design[, allowed] <- design[, allowed]
  split_rows <- split(seq_len(nrow(grid)), as.character(grid$site))
  dplyr::bind_rows(lapply(names(split_rows), function(site) {
    rows <- split_rows[[site]]
    rows <- rows[order(grid$time_hour[rows])]
    difference_design <- population_design[rows[2L], ] -
      population_design[rows[1L], ]
    estimate <- drop(difference_design %*% stats::coef(fit))
    se <- sqrt(max(drop(crossprod(
      difference_design,
      covariance %*% difference_design
    )), 0))
    tibble::tibble(
      run_id = object$run_id,
      placement = placement,
      site = site,
      endpoint_difference_log10 = estimate,
      endpoint_difference_se = se,
      endpoint_difference_abs = abs(estimate),
      global_component_is_cyclic = TRUE,
      site_deviation_basis_is_cyclic = identical(
        if (is.null(object$basis_variant)) {
          "inherited_thin_plate_sz"
        } else {
          object$basis_variant
        },
        "cyclic_sz"
      ),
      interpretation = paste(
        "24 h minus 0 h for global plus site deviation;",
        "descriptive endpoint diagnostic"
      )
    )
  }))
}

h03_temporal_residual_acf <- function(object, placement, max_lag = 6L) {
  residual <- if (!is.null(object$final$std.rsd) &&
      length(object$final$std.rsd) == nrow(object$data)) {
    object$final$std.rsd
  } else {
    stats::residuals(object$final, type = "response")
  }
  dplyr::bind_rows(lapply(seq_len(max_lag), function(lag) {
    estimate <- h03_boundary_lag_correlation(
      residual,
      object$data$AR_start,
      lag
    )
    tibble::tibble(
      run_id = object$run_id,
      placement = placement,
      lag = lag,
      correlation = unname(estimate["correlation"]),
      pairs = unname(estimate["pairs"])
    )
  }))
}

h03_temporal_cluster_diagnostics <- function(object, placement) {
  residual_data <- h03_temporal_residual_data(object, placement)
  # Discrete bam objects do not retain the lm QR component required by
  # stats::hatvalues(). Some mgcv builds retain an observation-level hat
  # diagonal; when it is absent, do not reconstruct the enormous penalized
  # hat matrix merely for an exploratory influence screen. The primary GLM
  # analysis has the prespecified leverage and deletion-refit diagnostics.
  leverage <- object$final$hat
  leverage_available <- !is.null(leverage) &&
    length(leverage) == nrow(residual_data) &&
    all(is.finite(leverage))
  if (!leverage_available) {
    leverage <- rep(NA_real_, nrow(residual_data))
  }
  residual_data$leverage <- leverage
  residual_data |>
    dplyr::group_by(.data$participant) |>
    dplyr::summarise(
      observations = dplyr::n(),
      leverage = if (all(is.na(.data$leverage))) {
        NA_real_
      } else {
        sum(.data$leverage, na.rm = TRUE)
      },
      mean_absolute_standardized_residual = mean(
        abs(.data$standardized_residual)
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
      leverage_rank = rank(-.data$leverage_share, ties.method = "first"),
      residual_rank = rank(
        -.data$mean_absolute_standardized_residual,
        ties.method = "first"
      ),
      run_id = object$run_id,
      placement = placement,
      leverage_source = if (leverage_available) {
        "mgcv stored hat diagonal"
      } else {
        paste(
          "unavailable for discrete bam;",
          "participant residual ranking retained"
        )
      },
      .before = 1
    ) |>
    dplyr::arrange(.data$leverage_rank)
}
