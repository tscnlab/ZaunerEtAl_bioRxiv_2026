h03_capture_warnings <- function(expression) {
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

h03_prepare_model_factors <- function(frame, formula) {
  frame <- as.data.frame(frame)
  if ("site" %in% all.vars(formula)) {
    frame$site <- droplevels(factor(frame$site))
    contrasts(frame$site) <- stats::contr.sum(nlevels(frame$site))
  }
  if ("light_source" %in% all.vars(formula)) {
    original_levels <- levels(frame$light_source)
    frame$light_source <- factor(frame$light_source, levels = original_levels)
    contrasts(frame$light_source) <- stats::contr.treatment(
      nlevels(frame$light_source),
      base = 1L
    )
  }
  if ("light_source_core" %in% all.vars(formula)) {
    frame$light_source_core <- droplevels(factor(frame$light_source_core))
    contrasts(frame$light_source_core) <- stats::contr.treatment(
      nlevels(frame$light_source_core),
      base = 1L
    )
  }
  if ("site_source_cell" %in% all.vars(formula)) {
    frame$site_source_cell <- droplevels(factor(frame$site_source_cell))
  }
  frame$participant <- droplevels(factor(frame$participant))
  frame$participant_day <- droplevels(factor(frame$participant_day))
  frame
}

h03_fit_quasi <- function(
  formula,
  frame,
  working_power = h03_specification()$working_tweedie_power
) {
  if (!is.finite(working_power) || working_power <= 1 || working_power >= 2) {
    h03_abort("The quasi-Tweedie working power must lie strictly in (1, 2)")
  }
  data <- h03_prepare_model_factors(frame, formula)
  captured <- h03_capture_warnings(stats::glm(
    formula = formula,
    data = data,
    family = statmod::tweedie(
      var.power = working_power,
      link.power = 0
    ),
    control = stats::glm.control(epsilon = 1e-10, maxit = 100L),
    model = TRUE,
    x = TRUE,
    y = TRUE
  ))
  fit <- captured$value
  used_rows <- as.integer(rownames(stats::model.frame(fit)))
  if (length(used_rows) != nrow(data)) {
    data <- data[used_rows, , drop = FALSE]
  }
  covariance_capture <- h03_capture_warnings(sandwich::vcovCL(
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

h03_covariance_diagnostics <- function(covariance, relative_tolerance = NULL) {
  if (is.null(relative_tolerance)) {
    relative_tolerance <- h03_specification()$interaction_check$
      eigen_relative_tolerance
  }
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

h03_term_restriction <- function(fit, term_label) {
  design <- stats::model.matrix(fit)
  term_labels <- attr(stats::terms(fit), "term.labels")
  term_index <- match(term_label, term_labels)
  if (is.na(term_index)) {
    h03_abort("Model term not found for restriction: %s", term_label)
  }
  coefficient_indices <- which(attr(design, "assign") == term_index)
  restriction <- matrix(
    0,
    nrow = length(coefficient_indices),
    ncol = length(stats::coef(fit)),
    dimnames = list(
      colnames(design)[coefficient_indices],
      names(stats::coef(fit))
    )
  )
  restriction[cbind(seq_along(coefficient_indices), coefficient_indices)] <- 1
  restriction
}

h03_observed_cell_restriction <- function(bundle) {
  data <- bundle$data
  grid <- data |>
    dplyr::distinct(.data$site_source_cell, .data$site, .data$light_source) |>
    dplyr::arrange(.data$site_source_cell)
  cell_design <- stats::model.matrix(
    ~ 0 + site_source_cell,
    data = grid,
    contrasts.arg = list(site_source_cell = stats::contrasts(
      data$site_source_cell,
      contrasts = TRUE
    ))
  )
  additive_data <- grid
  additive_data$site <- droplevels(factor(additive_data$site))
  additive_data$light_source <- droplevels(factor(
    additive_data$light_source,
    levels = levels(data$light_source)
  ))
  additive_design <- stats::model.matrix(
    ~ site + light_source,
    data = additive_data
  )
  decomposition <- qr(additive_design)
  rank <- decomposition$rank
  complete_q <- qr.Q(decomposition, complete = TRUE)
  if (rank >= nrow(additive_design)) {
    h03_abort("Observed-cell model has no additivity restrictions")
  }
  cell_null <- t(complete_q[, seq.int(rank + 1L, nrow(additive_design)), drop = FALSE])
  restriction <- cell_null %*% cell_design
  colnames(restriction) <- colnames(cell_design)
  coefficient_names <- names(stats::coef(bundle$fit))
  if (!setequal(colnames(restriction), coefficient_names)) {
    h03_abort("Observed-cell restriction does not match fitted coefficients")
  }
  restriction[, coefficient_names, drop = FALSE]
}

h03_wald_f <- function(bundle, restriction) {
  estimate <- drop(restriction %*% stats::coef(bundle$fit))
  covariance <- restriction %*% bundle$covariance %*% t(restriction)
  covariance_diagnostic <- h03_covariance_diagnostics(covariance)
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
      covariance_minimum_eigenvalue =
        covariance_diagnostic$minimum_eigenvalue,
      covariance_condition_number =
        covariance_diagnostic$condition_number,
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
    covariance_minimum_eigenvalue =
      covariance_diagnostic$minimum_eigenvalue,
    covariance_condition_number = covariance_diagnostic$condition_number,
    status = "ESTIMABLE"
  )
}

h03_model_matrix_newdata <- function(bundle, newdata) {
  terms <- stats::delete.response(stats::terms(bundle$fit))
  stats::model.matrix(
    terms,
    data = newdata,
    contrasts.arg = bundle$fit$contrasts,
    xlev = bundle$fit$xlevels
  )
}

h03_log_delta <- function(
  log_estimate,
  gradient,
  covariance,
  df,
  null_log = 0,
  confidence_level = 0.95
) {
  variance <- drop(crossprod(gradient, covariance %*% gradient))
  if (!is.finite(variance) || variance <= 0 || !is.finite(log_estimate)) {
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
  se <- sqrt(variance)
  critical <- stats::qt((1 + confidence_level) / 2, df = df)
  statistic <- (log_estimate - null_log) / se
  tibble::tibble(
    log_estimate = log_estimate,
    log_se = se,
    estimate = exp(log_estimate),
    conf_low = exp(log_estimate - critical * se),
    conf_high = exp(log_estimate + critical * se),
    statistic = statistic,
    df = df,
    p_raw = 2 * stats::pt(abs(statistic), df = df, lower.tail = FALSE),
    status = "ESTIMABLE"
  )
}

h03_weighted_log_mean <- function(x, beta, weights) {
  weights <- weights / sum(weights)
  eta <- drop(x %*% beta)
  # Author amendment 2026-08-07: standardize on the fitted log-mean scale
  # and back-transform once. This is the weighted geometric mean of the
  # response-scale fitted values, not their weighted arithmetic mean.
  log_mean <- sum(weights * eta)
  gradient <- drop(crossprod(x, weights))
  list(log_mean = log_mean, gradient = gradient)
}

h03_prediction_grid <- function(bundle, category_levels = NULL) {
  if (is.null(category_levels)) {
    category_levels <- levels(bundle$data$light_source)
  }
  sites <- levels(bundle$data$site)
  grid <- tidyr::crossing(
    site = factor(sites, levels = sites),
    light_source = factor(category_levels, levels = levels(bundle$data$light_source))
  )
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
      grid[[variable]] <- mean(value, na.rm = TRUE)
    } else if (is.factor(value)) {
      grid[[variable]] <- factor(levels(value)[1L], levels = levels(value))
    } else {
      grid[[variable]] <- value[which(!is.na(value))[1L]]
    }
  }
  grid
}

h03_category_estimands <- function(
  bundle,
  category_registry,
  support,
  distribution = c("site_standardized", "observed_sample_weighted"),
  family_id = NA_character_,
  family_n = NULL
) {
  distribution <- match.arg(distribution)
  grid <- h03_prediction_grid(bundle)
  design <- h03_model_matrix_newdata(bundle, grid)
  beta <- stats::coef(bundle$fit)
  covariance <- bundle$covariance
  clusters <- nlevels(bundle$data$participant)
  reference <- h03_specification()$reference_label

  counts <- bundle$data |>
    dplyr::count(.data$site, .data$light_source, name = "hours") |>
    tidyr::complete(
      site = factor(levels(bundle$data$site), levels = levels(bundle$data$site)),
      light_source = factor(
        levels(bundle$data$light_source),
        levels = levels(bundle$data$light_source)
      ),
      fill = list(hours = 0L)
    )
  grid <- dplyr::left_join(grid, counts, by = c("site", "light_source"))

  mean_objects <- lapply(levels(bundle$data$light_source), function(category) {
    rows <- as.character(grid$light_source) == category
    weights <- if (distribution == "site_standardized") {
      rep(1 / sum(rows), sum(rows))
    } else {
      category_hours <- grid$hours[rows]
      if (sum(category_hours) == 0) rep(NA_real_, sum(rows)) else
        category_hours / sum(category_hours)
    }
    h03_weighted_log_mean(design[rows, , drop = FALSE], beta, weights)
  })
  names(mean_objects) <- levels(bundle$data$light_source)
  reference_object <- mean_objects[[reference]]

  rows <- lapply(seq_along(mean_objects), function(index) {
    category <- names(mean_objects)[index]
    object <- mean_objects[[index]]
    absolute <- h03_log_delta(
      object$log_mean,
      object$gradient,
      covariance,
      df = clusters - 1L,
      null_log = NA_real_
    )
    if (identical(category, reference)) {
      ratio <- tibble::tibble(
        log_estimate = 0,
        log_se = 0,
        estimate = 1,
        conf_low = 1,
        conf_high = 1,
        statistic = NA_real_,
        df = clusters - 1L,
        p_raw = NA_real_,
        status = "REFERENCE"
      )
    } else {
      ratio <- h03_log_delta(
        object$log_mean - reference_object$log_mean,
        object$gradient - reference_object$gradient,
        covariance,
        df = clusters - 1L
      )
    }
    registry_row <- category_registry[
      category_registry$category_label == category,
      ,
      drop = FALSE
    ]
    support_row <- support[
      as.character(support$light_source) == category,
      ,
      drop = FALSE
    ]
    pooled_estimable <- isTRUE(support_row$pooled_estimable)
    tibble::tibble(
      category_order = registry_row$category_order,
      category_code = registry_row$category_code,
      light_source = category,
      short_label = registry_row$short_label,
      distribution = distribution,
      expected_mel_edi_lx = absolute$estimate,
      expected_conf_low_lx = absolute$conf_low,
      expected_conf_high_lx = absolute$conf_high,
      model_ratio_to_indoor = ratio$estimate,
      ratio_to_indoor = if (pooled_estimable) ratio$estimate else NA_real_,
      ratio_conf_low = if (pooled_estimable) ratio$conf_low else NA_real_,
      ratio_conf_high = if (pooled_estimable) ratio$conf_high else NA_real_,
      statistic = if (pooled_estimable) ratio$statistic else NA_real_,
      df = ratio$df,
      p_raw = if (pooled_estimable) ratio$p_raw else NA_real_,
      estimability_status = if (!pooled_estimable) {
        "SUPPORT_NON_ESTIMABLE"
      } else {
        ratio$status
      },
      hours = support_row$hours,
      participants = support_row$participants,
      participant_days = support_row$participant_days,
      sites = support_row$sites,
      family_id = family_id
    )
  }) |>
    dplyr::bind_rows() |>
    dplyr::arrange(.data$category_order)

  nonreference <- !is.na(rows$p_raw)
  if (is.null(family_n)) {
    family_n <- sum(nonreference)
  }
  rows$family_n <- ifelse(nonreference, family_n, NA_integer_)
  rows$p_adjusted <- NA_real_
  if (any(nonreference)) {
    rows$p_adjusted[nonreference] <- stats::p.adjust(
      rows$p_raw[nonreference],
      method = "BH",
      n = family_n
    )
  }
  rows
}

h03_additive_omnibus <- function(bundle, family_id) {
  result <- h03_wald_f(
    bundle,
    h03_term_restriction(bundle$fit, "light_source")
  )
  dplyr::mutate(
    result,
    family_id = family_id,
    test_id = "category_omnibus",
    null_hypothesis = paste(
      "all six non-reference light-source coefficients are zero"
    ),
    .before = 1
  )
}

h03_cluster_diagnostics <- function(bundle) {
  fit <- bundle$fit
  data <- bundle$data
  cluster <- droplevels(data$participant)
  score <- sandwich::estfun(fit)
  score_by_cluster <- rowsum(score, cluster, reorder = FALSE)
  score_energy <- rowSums(score_by_cluster^2)
  score_share <- score_energy / sum(score_energy)
  leverage <- stats::hatvalues(fit)
  leverage_by_cluster <- rowsum(leverage, cluster, reorder = FALSE)[, 1]
  leverage_share <- leverage_by_cluster / sum(leverage_by_cluster)
  tibble::tibble(
    participant = rownames(score_by_cluster),
    observations = as.integer(table(cluster)[rownames(score_by_cluster)]),
    score_energy = score_energy,
    score_share = score_share,
    leverage = leverage_by_cluster,
    leverage_share = leverage_share,
    score_rank = rank(-score_share, ties.method = "first"),
    leverage_rank = rank(-leverage_share, ties.method = "first")
  ) |>
    dplyr::arrange(.data$score_rank)
}

h03_boundary_lag_correlation <- function(residual, AR_start, lag = 1L) {
  sequence_id <- cumsum(AR_start)
  index <- seq_along(residual)
  earlier <- index - lag
  eligible <- earlier >= 1L
  eligible[eligible] <- sequence_id[index[eligible]] ==
    sequence_id[earlier[eligible]]
  complete <- eligible & is.finite(residual) &
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

h03_fit_diagnostics <- function(bundle, run_id) {
  fit <- bundle$fit
  data <- bundle$data
  covariance_diagnostic <- h03_covariance_diagnostics(bundle$covariance)
  clusters <- h03_cluster_diagnostics(bundle)
  pearson <- stats::residuals(fit, type = "pearson")
  deviance <- stats::residuals(fit, type = "deviance")
  fitted <- stats::fitted(fit)
  lag_one <- h03_boundary_lag_correlation(pearson, data$AR_start, lag = 1L)
  tibble::tibble(
    run_id = run_id,
    observations = stats::nobs(fit),
    participants = nlevels(data$participant),
    participant_days = nlevels(data$participant_day),
    sites = nlevels(data$site),
    iterations = fit$iter,
    converged = isTRUE(fit$converged),
    design_columns = ncol(stats::model.matrix(fit)),
    design_rank = fit$rank,
    full_rank = fit$rank == ncol(stats::model.matrix(fit)),
    aliased_coefficients = sum(is.na(stats::coef(fit))),
    finite_coefficients = all(is.finite(stats::coef(fit))),
    covariance_finite = covariance_diagnostic$finite,
    covariance_positive_definite = covariance_diagnostic$positive_definite,
    covariance_minimum_eigenvalue = covariance_diagnostic$minimum_eigenvalue,
    covariance_condition_number = covariance_diagnostic$condition_number,
    dispersion = summary(fit)$dispersion,
    exact_zero_hours = sum(data$geo_medi_1h == 0),
    exact_zero_fraction = mean(data$geo_medi_1h == 0),
    fitted_minimum = min(fitted),
    fitted_median = stats::median(fitted),
    fitted_maximum = max(fitted),
    pearson_mean = mean(pearson),
    pearson_sd = stats::sd(pearson),
    pearson_q01 = unname(stats::quantile(pearson, 0.01)),
    pearson_q99 = unname(stats::quantile(pearson, 0.99)),
    deviance_mean = mean(deviance),
    residual_fitted_spearman = stats::cor(
      pearson,
      fitted,
      method = "spearman"
    ),
    absolute_residual_fitted_spearman = stats::cor(
      abs(pearson),
      fitted,
      method = "spearman"
    ),
    residual_lag1_correlation = unname(lag_one["correlation"]),
    residual_lag1_pairs = unname(lag_one["pairs"]),
    maximum_cluster_score_share = max(clusters$score_share),
    maximum_cluster_leverage_share = max(clusters$leverage_share),
    fit_warnings = paste(bundle$fit_warnings, collapse = " | "),
    covariance_warnings = paste(bundle$covariance_warnings, collapse = " | ")
  )
}

h03_residual_group_summary <- function(bundle, run_id) {
  data <- bundle$data
  data$pearson_residual <- stats::residuals(bundle$fit, type = "pearson")
  data$fitted_mean <- stats::fitted(bundle$fit)
  dplyr::bind_rows(
    data |>
      dplyr::group_by(group_value = .data$site) |>
      dplyr::summarise(
        observations = dplyr::n(),
        mean_residual = mean(.data$pearson_residual),
        sd_residual = stats::sd(.data$pearson_residual),
        zero_fraction = mean(.data$geo_medi_1h == 0),
        mean_fitted = mean(.data$fitted_mean),
        .groups = "drop"
      ) |>
      dplyr::mutate(
        group_type = "site",
        group_value = as.character(.data$group_value),
        .before = 1
      ),
    data |>
      dplyr::group_by(group_value = .data$light_source) |>
      dplyr::summarise(
        observations = dplyr::n(),
        mean_residual = mean(.data$pearson_residual),
        sd_residual = stats::sd(.data$pearson_residual),
        zero_fraction = mean(.data$geo_medi_1h == 0),
        mean_fitted = mean(.data$fitted_mean),
        .groups = "drop"
      ) |>
      dplyr::mutate(
        group_type = "light_source",
        group_value = as.character(.data$group_value),
        .before = 1
      ),
    data |>
      dplyr::mutate(clock_hour = floor(.data$time_hour)) |>
      dplyr::group_by(group_value = .data$clock_hour) |>
      dplyr::summarise(
        observations = dplyr::n(),
        mean_residual = mean(.data$pearson_residual),
        sd_residual = stats::sd(.data$pearson_residual),
        zero_fraction = mean(.data$geo_medi_1h == 0),
        mean_fitted = mean(.data$fitted_mean),
        .groups = "drop"
      ) |>
      dplyr::mutate(
        group_type = "clock_hour",
        group_value = as.character(.data$group_value),
        .before = 1
      )
  ) |>
    dplyr::mutate(run_id = run_id, .before = 1)
}

h03_residual_plot_data <- function(bundle, run_id, bins = 30L) {
  data <- bundle$data
  data$pearson_residual <- stats::residuals(bundle$fit, type = "pearson")
  data$deviance_residual <- stats::residuals(bundle$fit, type = "deviance")
  data$fitted_mean <- stats::fitted(bundle$fit)
  data |>
    dplyr::mutate(fitted_bin = dplyr::ntile(.data$fitted_mean, bins)) |>
    dplyr::group_by(.data$fitted_bin) |>
    dplyr::summarise(
      observations = dplyr::n(),
      fitted_mean = mean(.data$fitted_mean),
      fitted_minimum = min(.data$fitted_mean),
      fitted_maximum = max(.data$fitted_mean),
      pearson_mean = mean(.data$pearson_residual),
      pearson_q25 = unname(stats::quantile(.data$pearson_residual, 0.25)),
      pearson_q75 = unname(stats::quantile(.data$pearson_residual, 0.75)),
      deviance_mean = mean(.data$deviance_residual),
      zero_fraction = mean(.data$geo_medi_1h == 0),
      .groups = "drop"
    ) |>
    dplyr::mutate(run_id = run_id, .before = 1)
}

h03_make_interaction_frame <- function(
  frame,
  architecture,
  category_registry,
  spec
) {
  output <- frame
  if (architecture == "full_literal") {
    return(output)
  }
  if (architecture == "full_observed_cell") {
    cell_levels <- output |>
      dplyr::distinct(.data$site, .data$light_source) |>
      dplyr::arrange(.data$site, .data$light_source) |>
      dplyr::transmute(
        cell = paste(
          as.character(.data$site),
          as.character(.data$light_source),
          sep = "__"
        )
      ) |>
      dplyr::pull(.data$cell)
    output$site_source_cell <- factor(
      paste(
        as.character(output$site),
        as.character(output$light_source),
        sep = "__"
      ),
      levels = cell_levels
    )
    return(output)
  }
  if (architecture == "fallback_core") {
    output <- output |>
      dplyr::filter(
        as.character(.data$light_source) %in%
          spec$core_heterogeneity_levels
      ) |>
      dplyr::mutate(
        light_source_core = factor(
          as.character(.data$light_source),
          levels = spec$core_heterogeneity_levels
        )
      ) |>
      droplevels()
    return(output)
  }
  h03_abort("Unknown H03 interaction architecture: %s", architecture)
}

h03_interaction_formula <- function(architecture) {
  formulas <- h03_formula_set()
  switch(
    architecture,
    full_literal = formulas$full_site_heterogeneity,
    full_observed_cell = formulas$chest_observed_cell_heterogeneity,
    fallback_core = formulas$fallback_core_site_heterogeneity,
    h03_abort("Unknown H03 interaction architecture: %s", architecture)
  )
}

h03_interaction_restriction <- function(bundle, architecture) {
  switch(
    architecture,
    full_literal = h03_term_restriction(bundle$fit, "site:light_source"),
    full_observed_cell = h03_observed_cell_restriction(bundle),
    fallback_core = h03_term_restriction(
      bundle$fit,
      "site:light_source_core"
    ),
    h03_abort("Unknown H03 interaction architecture: %s", architecture)
  )
}

h03_interaction_interval_check <- function(
  bundle,
  architecture,
  cell_support,
  spec
) {
  category_levels <- if (architecture == "fallback_core") {
    spec$core_heterogeneity_levels
  } else {
    levels(bundle$data$light_source)
  }
  grid <- if (architecture == "full_observed_cell") {
    bundle$data |>
      dplyr::distinct(
        .data$site,
        .data$light_source,
        .data$site_source_cell
      ) |>
      dplyr::arrange(.data$site_source_cell)
  } else {
    h03_prediction_grid(bundle, category_levels)
  }
  if (architecture == "fallback_core") {
    grid$light_source_core <- factor(
      as.character(grid$light_source),
      levels = spec$core_heterogeneity_levels
    )
  }
  design <- h03_model_matrix_newdata(bundle, grid)
  variances <- rowSums((design %*% bundle$covariance) * design)
  support_key <- paste(
    as.character(cell_support$site),
    as.character(cell_support$light_source),
    sep = "__"
  )
  grid_key <- paste(
    as.character(grid$site),
    as.character(grid$light_source),
    sep = "__"
  )
  supported <- cell_support$supported[match(grid_key, support_key)] %in% TRUE
  supported <- supported & as.character(grid$light_source) %in% category_levels
  all(is.finite(variances[supported]) & variances[supported] > 0)
}

h03_interaction_check_row <- function(
  bundle,
  placement,
  architecture,
  restriction,
  cell_support,
  spec
) {
  diagnostics <- h03_fit_diagnostics(
    bundle,
    paste(placement, architecture, sep = "__")
  )
  restriction_covariance <- restriction %*%
    bundle$covariance %*% t(restriction)
  restriction_diagnostics <- h03_covariance_diagnostics(
    restriction_covariance
  )
  intervals_finite <- h03_interaction_interval_check(
    bundle,
    architecture,
    cell_support,
    spec
  )
  thresholds <- spec$interaction_check
  hard_pass <- diagnostics$converged &
    diagnostics$full_rank &
    diagnostics$finite_coefficients &
    diagnostics$covariance_finite &
    restriction_diagnostics$positive_definite &
    restriction_diagnostics$numerical_rank == nrow(restriction) &
    restriction_diagnostics$condition_number <=
      thresholds$maximum_condition_number &
    diagnostics$maximum_cluster_score_share <=
      thresholds$maximum_cluster_score_share &
    diagnostics$maximum_cluster_leverage_share <=
      thresholds$maximum_cluster_leverage_share &
    intervals_finite
  tibble::tibble(
    placement = placement,
    architecture = architecture,
    formula = paste(deparse(bundle$formula), collapse = " "),
    observations = diagnostics$observations,
    participants = diagnostics$participants,
    participant_days = diagnostics$participant_days,
    sites = diagnostics$sites,
    converged = diagnostics$converged,
    iterations = diagnostics$iterations,
    design_columns = diagnostics$design_columns,
    design_rank = diagnostics$design_rank,
    finite_coefficients = diagnostics$finite_coefficients,
    robust_covariance_finite = diagnostics$covariance_finite,
    restrictions = nrow(restriction),
    restriction_covariance_rank = restriction_diagnostics$numerical_rank,
    restriction_covariance_minimum_eigenvalue =
      restriction_diagnostics$minimum_eigenvalue,
    restriction_covariance_condition_number =
      restriction_diagnostics$condition_number,
    maximum_cluster_score_share =
      diagnostics$maximum_cluster_score_share,
    maximum_cluster_leverage_share =
      diagnostics$maximum_cluster_leverage_share,
    supported_intervals_finite = intervals_finite,
    maximum_condition_number_allowed =
      thresholds$maximum_condition_number,
    maximum_cluster_score_share_allowed =
      thresholds$maximum_cluster_score_share,
    maximum_cluster_leverage_share_allowed =
      thresholds$maximum_cluster_leverage_share,
    check_pass = hard_pass,
    effect_estimates_emitted = FALSE,
    effect_p_values_emitted = FALSE,
    warnings = paste(
      c(bundle$fit_warnings, bundle$covariance_warnings),
      collapse = " | "
    )
  )
}

h03_run_interaction_check <- function(
  frame,
  placement,
  category_registry,
  site_registry,
  spec
) {
  cell_support <- h03_cell_support(
    frame,
    category_registry,
    site_registry,
    spec
  )
  full_architecture <- if (placement == "Chest") {
    "full_observed_cell"
  } else {
    "full_literal"
  }
  full_frame <- h03_make_interaction_frame(
    frame,
    full_architecture,
    category_registry,
    spec
  )
  full_bundle <- h03_fit_quasi(
    h03_interaction_formula(full_architecture),
    full_frame,
    spec$working_tweedie_power
  )
  full_restriction <- h03_interaction_restriction(
    full_bundle,
    full_architecture
  )
  full_check <- h03_interaction_check_row(
    full_bundle,
    placement,
    full_architecture,
    full_restriction,
    cell_support,
    spec
  )
  if (isTRUE(full_check$check_pass)) {
    return(list(
      estimability_check = full_check,
      selected_architecture = full_architecture,
      selected_bundle = full_bundle,
      selected_restriction = full_restriction,
      cell_support = cell_support
    ))
  }

  core_frame <- h03_make_interaction_frame(
    frame,
    "fallback_core",
    category_registry,
    spec
  )
  core_bundle <- h03_fit_quasi(
    h03_interaction_formula("fallback_core"),
    core_frame,
    spec$working_tweedie_power
  )
  core_restriction <- h03_interaction_restriction(
    core_bundle,
    "fallback_core"
  )
  core_check <- h03_interaction_check_row(
    core_bundle,
    placement,
    "fallback_core",
    core_restriction,
    cell_support,
    spec
  )
  if (!isTRUE(core_check$check_pass)) {
    h03_abort(
      "%s full and fallback interaction architectures both failed the check",
      placement
    )
  }
  list(
    estimability_check = dplyr::bind_rows(full_check, core_check),
    selected_architecture = "fallback_core",
    selected_bundle = core_bundle,
    selected_restriction = core_restriction,
    cell_support = cell_support
  )
}

h03_interaction_prediction_grid <- function(bundle, architecture, spec) {
  if (architecture == "full_observed_cell") {
    return(bundle$data |>
      dplyr::distinct(
        .data$site,
        .data$light_source,
        .data$site_source_cell
      ) |>
      dplyr::arrange(.data$site_source_cell))
  }
  categories <- if (architecture == "fallback_core") {
    spec$core_heterogeneity_levels
  } else {
    levels(bundle$data$light_source)
  }
  grid <- h03_prediction_grid(bundle, categories)
  if (architecture == "fallback_core") {
    grid$light_source_core <- factor(
      as.character(grid$light_source),
      levels = spec$core_heterogeneity_levels
    )
  }
  grid
}

h03_interaction_estimands <- function(
  bundle,
  architecture,
  category_registry,
  cell_support,
  family_id
) {
  spec <- h03_specification()
  grid <- h03_interaction_prediction_grid(bundle, architecture, spec)
  design <- h03_model_matrix_newdata(bundle, grid)
  beta <- stats::coef(bundle$fit)
  covariance <- bundle$covariance
  clusters <- nlevels(bundle$data$participant)
  included_sites <- levels(bundle$data$site)
  included_categories <- if (architecture == "fallback_core") {
    spec$core_heterogeneity_levels
  } else {
    levels(bundle$data$light_source)
  }

  mean_objects <- stats::setNames(
    vector("list", length(included_categories)),
    included_categories
  )
  for (category in included_categories) {
    rows <- as.character(grid$light_source) == category
    category_sites <- unique(as.character(grid$site[rows]))
    if (!setequal(category_sites, included_sites)) {
      mean_objects[category] <- list(NULL)
    } else {
      mean_objects[[category]] <- h03_weighted_log_mean(
        design[rows, , drop = FALSE],
        beta,
        rep(1 / length(included_sites), length(included_sites))
      )
    }
  }
  anchor <- mean_objects[[spec$reference_label]]
  if (is.null(anchor)) {
    h03_abort("The indoor-electric interaction anchor is not estimable")
  }

  grid_key <- paste(
    as.character(grid$site),
    as.character(grid$light_source),
    sep = "__"
  )
  support_key <- paste(
    as.character(cell_support$site),
    as.character(cell_support$light_source),
    sep = "__"
  )
  grid_index <- stats::setNames(seq_len(nrow(grid)), grid_key)

  output <- lapply(seq_len(nrow(cell_support)), function(index) {
    support_row <- cell_support[index, , drop = FALSE]
    site <- as.character(support_row$site)
    category <- as.character(support_row$light_source)
    key <- support_key[index]
    cell_index <- unname(grid_index[key])
    architecture_includes_category <- category %in% included_categories
    cell_estimable <- length(cell_index) == 1L && !is.na(cell_index)
    reportable <- isTRUE(support_row$supported) &&
      architecture_includes_category && cell_estimable

    empty_delta <- tibble::tibble(
      estimate = NA_real_,
      conf_low = NA_real_,
      conf_high = NA_real_,
      statistic = NA_real_,
      df = clusters - 1L,
      p_raw = NA_real_,
      status = "NON_ESTIMABLE"
    )
    fixed_ratio <- tibble::tibble(
      estimate = 1,
      conf_low = 1,
      conf_high = 1,
      statistic = NA_real_,
      df = clusters - 1L,
      p_raw = NA_real_,
      status = "REFERENCE"
    )
    cell <- empty_delta
    category_mean <- empty_delta
    category_ratio <- empty_delta
    site_deviation <- empty_delta
    within_site_ratio <- empty_delta

    if (cell_estimable) {
      x_cell <- design[cell_index, ]
      eta_cell <- drop(x_cell %*% beta)
      cell <- h03_log_delta(
        eta_cell,
        x_cell,
        covariance,
        df = clusters - 1L,
        null_log = NA_real_
      )
      object <- mean_objects[[category]]
      if (!is.null(object)) {
        category_mean <- h03_log_delta(
          object$log_mean,
          object$gradient,
          covariance,
          df = clusters - 1L,
          null_log = NA_real_
        )
        category_ratio <- if (identical(category, spec$reference_label)) {
          fixed_ratio
        } else {
          h03_log_delta(
            object$log_mean - anchor$log_mean,
            object$gradient - anchor$gradient,
            covariance,
            df = clusters - 1L
          )
        }
        site_deviation <- h03_log_delta(
          eta_cell - object$log_mean,
          x_cell - object$gradient,
          covariance,
          df = clusters - 1L
        )
      }
      reference_key <- paste(site, spec$reference_label, sep = "__")
      reference_index <- unname(grid_index[reference_key])
      if (length(reference_index) == 1L && !is.na(reference_index)) {
        x_reference <- design[reference_index, ]
        within_site_ratio <- if (identical(category, spec$reference_label)) {
          fixed_ratio
        } else {
          h03_log_delta(
            eta_cell - drop(x_reference %*% beta),
            x_cell - x_reference,
            covariance,
            df = clusters - 1L
          )
        }
      }
    }

    status <- dplyr::case_when(
      !isTRUE(support_row$site_present) ~ "NOT_APPLICABLE",
      !architecture_includes_category ~ "NOT_IN_SELECTED_ARCHITECTURE",
      !cell_estimable ~ "STRUCTURAL_CELL_NON_ESTIMABLE",
      !isTRUE(support_row$supported) ~ "SUPPORT_NON_ESTIMABLE",
      is.null(mean_objects[[category]]) ~
        "CATEGORY_STANDARDIZATION_NON_ESTIMABLE",
      site_deviation$status != "ESTIMABLE" ~ "COVARIANCE_NON_ESTIMABLE",
      TRUE ~ "ESTIMABLE"
    )
    tibble::tibble(
      display_order = support_row$display_order,
      site = site,
      site_display_name = support_row$display_name,
      site_color_hex = support_row$color_hex,
      category_order = support_row$category_order,
      category_code = support_row$category_code,
      light_source = category,
      short_label = support_row$short_label,
      architecture = architecture,
      hours = support_row$hours,
      participants = support_row$participants,
      participant_days = support_row$participant_days,
      shared_participants = support_row$shared_participants,
      site_present = support_row$site_present,
      support_rule_pass = support_row$supported,
      reporting_status = status,
      model_cell_mean_lx = cell$estimate,
      model_cell_conf_low_lx = cell$conf_low,
      model_cell_conf_high_lx = cell$conf_high,
      cell_mean_lx = if (reportable) cell$estimate else NA_real_,
      cell_conf_low_lx = if (reportable) cell$conf_low else NA_real_,
      cell_conf_high_lx = if (reportable) cell$conf_high else NA_real_,
      site_standardized_category_mean_lx = category_mean$estimate,
      category_mean_conf_low_lx = category_mean$conf_low,
      category_mean_conf_high_lx = category_mean$conf_high,
      category_ratio_to_indoor = category_ratio$estimate,
      category_ratio_conf_low = category_ratio$conf_low,
      category_ratio_conf_high = category_ratio$conf_high,
      site_deviation_ratio = if (reportable) {
        site_deviation$estimate
      } else {
        NA_real_
      },
      site_deviation_conf_low = if (reportable) {
        site_deviation$conf_low
      } else {
        NA_real_
      },
      site_deviation_conf_high = if (reportable) {
        site_deviation$conf_high
      } else {
        NA_real_
      },
      site_deviation_statistic = if (reportable) {
        site_deviation$statistic
      } else {
        NA_real_
      },
      site_deviation_df = clusters - 1L,
      site_deviation_p_raw = if (reportable) {
        site_deviation$p_raw
      } else {
        NA_real_
      },
      within_site_ratio_to_indoor = if (reportable) {
        within_site_ratio$estimate
      } else {
        NA_real_
      },
      within_site_ratio_conf_low = if (reportable) {
        within_site_ratio$conf_low
      } else {
        NA_real_
      },
      within_site_ratio_conf_high = if (reportable) {
        within_site_ratio$conf_high
      } else {
        NA_real_
      },
      family_id = family_id
    )
  }) |>
    dplyr::bind_rows() |>
    dplyr::arrange(.data$display_order, .data$category_order)

  estimable <- is.finite(output$site_deviation_p_raw)
  family_n <- sum(estimable)
  output$family_n <- ifelse(estimable, family_n, NA_integer_)
  output$site_deviation_p_adjusted <- NA_real_
  if (family_n > 0L) {
    output$site_deviation_p_adjusted[estimable] <- stats::p.adjust(
      output$site_deviation_p_raw[estimable],
      method = "BH",
      n = family_n
    )
  }
  output
}

h03_interaction_omnibus <- function(
  bundle,
  restriction,
  family_id,
  architecture
) {
  result <- h03_wald_f(bundle, restriction)
  dplyr::mutate(
    result,
    family_id = family_id,
    test_id = "site_heterogeneity_omnibus",
    architecture = architecture,
    null_hypothesis = paste(
      "all estimable site-by-light-source departures from additivity are zero"
    ),
    .before = 1
  )
}

h03_fit_additive_run <- function(
  frame,
  run_id,
  placement,
  scenario_id,
  category_registry,
  spec,
  working_power = spec$working_tweedie_power,
  formula = h03_formula_set()$primary_population_mean,
  family_prefix = "H03-S"
) {
  bundle <- h03_fit_quasi(formula, frame, working_power)
  support <- h03_category_support(bundle$data, category_registry, spec)
  family_contrasts <- paste0(family_prefix, "-context-contrasts")
  family_omnibus <- paste0(family_prefix, "-omnibus")
  estimands <- h03_category_estimands(
    bundle,
    category_registry,
    support,
    distribution = "site_standardized",
    family_id = family_contrasts,
    family_n = NULL
  ) |>
    dplyr::mutate(
      run_id = run_id,
      placement = placement,
      scenario_id = scenario_id,
      working_power = working_power,
      .before = 1
    )
  observed_weighted <- h03_category_estimands(
    bundle,
    category_registry,
    support,
    distribution = "observed_sample_weighted",
    family_id = paste0(family_prefix, "-observed-weighting"),
    family_n = NULL
  ) |>
    dplyr::mutate(
      run_id = run_id,
      placement = placement,
      scenario_id = scenario_id,
      working_power = working_power,
      .before = 1
    )
  omnibus <- h03_additive_omnibus(bundle, family_omnibus) |>
    dplyr::mutate(
      run_id = run_id,
      placement = placement,
      scenario_id = scenario_id,
      working_power = working_power,
      .before = 1
    )
  diagnostics <- h03_fit_diagnostics(bundle, run_id) |>
    dplyr::mutate(
      placement = placement,
      scenario_id = scenario_id,
      working_power = working_power,
      formula = paste(deparse(formula), collapse = " "),
      .after = "run_id"
    )
  sample <- h03_sample_summary(bundle$data, scenario_id, placement) |>
    dplyr::mutate(
      run_id = run_id,
      working_power = working_power,
      formula = paste(deparse(formula), collapse = " "),
      .before = 1
    )
  list(
    bundle = bundle,
    support = support,
    estimands = estimands,
    observed_weighted = observed_weighted,
    omnibus = omnibus,
    diagnostics = diagnostics,
    sample = sample
  )
}
