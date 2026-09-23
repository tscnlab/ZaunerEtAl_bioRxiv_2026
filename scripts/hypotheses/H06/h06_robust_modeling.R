h06_robust_capture <- function(expression) {
  warnings <- character()
  value <- withCallingHandlers(
    tryCatch(expression, error = function(error) error),
    warning = function(warning) {
      warnings <<- c(warnings, conditionMessage(warning))
      invokeRestart("muffleWarning")
    }
  )
  list(value = value, warnings = unique(warnings))
}

h06_formula_text <- function(formula) {
  paste(deparse(formula), collapse = " ")
}

h06_robust_family <- function(working_power = 1) {
  if (length(working_power) != 1L || !is.finite(working_power)) {
    h06_abort("H06 working power must be one finite scalar")
  }
  if (isTRUE(all.equal(working_power, 1))) {
    return(stats::quasipoisson(link = "log"))
  }
  if (working_power <= 1 || working_power >= 2) {
    h06_abort("H06 quasi-Tweedie working power must lie strictly in (1, 2)")
  }
  statmod::tweedie(var.power = working_power, link.power = 0)
}

h06_prepare_robust_frame <- function(frame, formula) {
  data <- h06_refactor_frame(frame) |>
    as.data.frame()
  variables <- all.vars(formula)
  missing_variables <- setdiff(variables, names(data))
  if (length(missing_variables) > 0L) {
    h06_abort(
      "H06 robust formula variables are missing: %s",
      paste(missing_variables, collapse = ", ")
    )
  }
  if (any(!stats::complete.cases(data[variables]))) {
    h06_abort("H06 robust model received an incomplete declared formula row")
  }
  if ("site" %in% variables) {
    data$site <- droplevels(factor(data$site, levels = levels(data$site)))
    contrasts(data$site) <- stats::contr.sum(nlevels(data$site))
  }
  treatment_factors <- intersect(
    c(
      "work_free_day", "activity_status", "weekday_weekend",
      "exercise_location"
    ),
    variables
  )
  for (variable in treatment_factors) {
    data[[variable]] <- droplevels(factor(
      data[[variable]],
      levels = levels(data[[variable]])
    ))
    contrasts(data[[variable]]) <- stats::contr.treatment(
      nlevels(data[[variable]]),
      base = 1L
    )
  }
  data$participant_key <- droplevels(factor(data$participant_key))
  data$participant_day_key <- droplevels(factor(data$participant_day_key))
  data
}

h06_fit_marginal <- function(
  frame,
  formula,
  working_power = 1,
  covariance_types = c("HC0", "HC1", "HC2", "HC3")
) {
  data <- h06_prepare_robust_frame(frame, formula)
  elapsed <- system.time({
    captured_fit <- h06_robust_capture(stats::glm(
      formula = formula,
      data = data,
      family = h06_robust_family(working_power),
      control = stats::glm.control(epsilon = 1e-10, maxit = 100L),
      model = TRUE,
      x = TRUE,
      y = TRUE,
      na.action = stats::na.fail
    ))
  })
  if (inherits(captured_fit$value, "error")) {
    return(list(
      fit = NULL,
      data = data,
      formula = formula,
      working_power = working_power,
      covariance = list(),
      fit_warnings = captured_fit$warnings,
      fit_error = conditionMessage(captured_fit$value),
      elapsed_seconds = unname(elapsed[["elapsed"]])
    ))
  }
  fit <- captured_fit$value
  covariance <- stats::setNames(lapply(covariance_types, function(type) {
    captured <- h06_robust_capture(sandwich::vcovCL(
      fit,
      cluster = data$participant_key,
      type = type,
      cadjust = TRUE,
      fix = FALSE
    ))
    list(
      value = if (inherits(captured$value, "error")) NULL else captured$value,
      warnings = captured$warnings,
      error = if (inherits(captured$value, "error")) {
        conditionMessage(captured$value)
      } else {
        ""
      }
    )
  }), covariance_types)
  list(
    fit = fit,
    data = data,
    formula = formula,
    working_power = working_power,
    covariance = covariance,
    fit_warnings = captured_fit$warnings,
    fit_error = "",
    elapsed_seconds = unname(elapsed[["elapsed"]])
  )
}

h06_covariance_diagnostics <- function(covariance) {
  if (
    is.null(covariance) || !is.matrix(covariance) ||
      nrow(covariance) < 1L || !all(is.finite(covariance))
  ) {
    return(tibble::tibble(
      dimension = if (is.matrix(covariance)) nrow(covariance) else NA_integer_,
      finite = FALSE,
      numerical_rank = NA_integer_,
      positive_definite = FALSE,
      minimum_eigenvalue = NA_real_,
      maximum_eigenvalue = NA_real_,
      condition_number = Inf
    ))
  }
  symmetric <- (covariance + t(covariance)) / 2
  eigenvalues <- eigen(symmetric, symmetric = TRUE, only.values = TRUE)$values
  maximum <- max(eigenvalues)
  tolerance <- max(maximum * sqrt(.Machine$double.eps), .Machine$double.eps)
  positive <- eigenvalues > tolerance
  tibble::tibble(
    dimension = nrow(covariance),
    finite = TRUE,
    numerical_rank = sum(positive),
    positive_definite = all(positive),
    minimum_eigenvalue = min(eigenvalues),
    maximum_eigenvalue = maximum,
    condition_number = if (all(positive)) maximum / min(eigenvalues) else Inf
  )
}

h06_term_restriction <- function(fit, term_label) {
  design <- stats::model.matrix(fit)
  labels <- attr(stats::terms(fit), "term.labels")
  term_index <- match(term_label, labels)
  if (is.na(term_index)) {
    h06_abort(
      "H06 fitted term `%s` is unavailable; fitted terms are %s",
      term_label,
      paste(labels, collapse = ", ")
    )
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

h06_wald_f <- function(bundle, restriction, covariance_type = "HC3") {
  covariance <- bundle$covariance[[covariance_type]]$value
  estimate <- drop(restriction %*% stats::coef(bundle$fit))
  restricted_covariance <- restriction %*% covariance %*% t(restriction)
  diagnostics <- h06_covariance_diagnostics(restricted_covariance)
  restrictions <- nrow(restriction)
  clusters <- nlevels(bundle$data$participant_key)
  if (
    !diagnostics$finite || !diagnostics$positive_definite ||
      diagnostics$numerical_rank != restrictions || clusters <= 1L
  ) {
    return(tibble::tibble(
      restrictions = restrictions,
      clusters = clusters,
      denominator_df = clusters - 1L,
      wald_chisq = NA_real_,
      f_statistic = NA_real_,
      p_raw = NA_real_,
      covariance_minimum_eigenvalue = diagnostics$minimum_eigenvalue,
      covariance_condition_number = diagnostics$condition_number,
      status = "NON_ESTIMABLE"
    ))
  }
  wald <- drop(crossprod(
    estimate,
    solve(restricted_covariance, estimate)
  ))
  f_statistic <- wald / restrictions
  tibble::tibble(
    restrictions = restrictions,
    clusters = clusters,
    denominator_df = clusters - 1L,
    wald_chisq = wald,
    f_statistic = f_statistic,
    p_raw = stats::pf(
      f_statistic,
      df1 = restrictions,
      df2 = clusters - 1L,
      lower.tail = FALSE
    ),
    covariance_minimum_eigenvalue = diagnostics$minimum_eigenvalue,
    covariance_condition_number = diagnostics$condition_number,
    status = "ESTIMABLE"
  )
}

h06_model_matrix_newdata <- function(bundle, newdata) {
  stats::model.matrix(
    stats::delete.response(stats::terms(bundle$fit)),
    data = newdata,
    contrasts.arg = bundle$fit$contrasts,
    xlev = bundle$fit$xlevels
  )
}

h06_log_delta <- function(
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
      log_standard_error = NA_real_,
      estimate_ratio = if (is.finite(log_estimate)) exp(log_estimate) else NA_real_,
      conf_low_ratio = NA_real_,
      conf_high_ratio = NA_real_,
      statistic = NA_real_,
      denominator_df = df,
      p_raw = NA_real_,
      status = "NON_ESTIMABLE"
    ))
  }
  standard_error <- sqrt(variance)
  critical <- stats::qt((1 + confidence_level) / 2, df = df)
  statistic <- if (is.finite(null_log)) {
    (log_estimate - null_log) / standard_error
  } else {
    NA_real_
  }
  tibble::tibble(
    log_estimate = log_estimate,
    log_standard_error = standard_error,
    estimate_ratio = exp(log_estimate),
    conf_low_ratio = exp(log_estimate - critical * standard_error),
    conf_high_ratio = exp(log_estimate + critical * standard_error),
    statistic = statistic,
    denominator_df = df,
    p_raw = if (is.finite(statistic)) {
      2 * stats::pt(abs(statistic), df = df, lower.tail = FALSE)
    } else {
      NA_real_
    },
    status = "ESTIMABLE"
  )
}

h06_prediction_defaults <- function(bundle, sites = levels(bundle$data$site)) {
  variables <- all.vars(stats::delete.response(stats::terms(bundle$fit)))
  output <- tibble::tibble(.row = seq_along(sites))
  for (variable in variables) {
    value <- bundle$data[[variable]]
    if (variable == "site") {
      output[[variable]] <- factor(sites, levels = levels(value))
    } else if (is.factor(value)) {
      output[[variable]] <- factor(levels(value)[[1L]], levels = levels(value))
    } else if (is.numeric(value)) {
      output[[variable]] <- 0
    } else {
      output[[variable]] <- value[[1L]]
    }
  }
  output$.row <- NULL
  output
}

h06_site_weights <- function(bundle, sites, distribution) {
  if (distribution == "equal_site") {
    return(rep(1 / length(sites), length(sites)))
  }
  if (distribution != "observed_sample") {
    h06_abort("Unknown H06 standardization distribution: %s", distribution)
  }
  counts <- table(bundle$data$site)
  weights <- as.numeric(counts[sites])
  weights / sum(weights)
}

h06_standardized_contrast <- function(
  bundle,
  variable,
  high = NULL,
  low = NULL,
  increment = NULL,
  site = NULL,
  distribution = "equal_site",
  covariance_type = "HC3"
) {
  sites <- if (is.null(site)) levels(bundle$data$site) else site
  low_data <- h06_prediction_defaults(bundle, sites)
  high_data <- low_data
  source <- bundle$data[[variable]]
  if (is.factor(source)) {
    if (is.null(low)) low <- levels(source)[[1L]]
    if (is.null(high)) high <- levels(source)[[2L]]
    low_data[[variable]] <- factor(low, levels = levels(source))
    high_data[[variable]] <- factor(high, levels = levels(source))
  } else {
    if (is.null(increment)) increment <- 1
    low_data[[variable]] <- 0
    high_data[[variable]] <- increment
  }
  low_matrix <- h06_model_matrix_newdata(bundle, low_data)
  high_matrix <- h06_model_matrix_newdata(bundle, high_data)
  weights <- h06_site_weights(bundle, sites, distribution)
  gradient <- drop(crossprod(high_matrix - low_matrix, weights))
  log_estimate <- drop(crossprod(gradient, stats::coef(bundle$fit)))
  h06_log_delta(
    log_estimate,
    gradient,
    bundle$covariance[[covariance_type]]$value,
    df = nlevels(bundle$data$participant_key) - 1L
  )
}

h06_core_estimands <- function(
  bundle,
  run_id,
  model_role = "additive",
  distribution = "equal_site",
  covariance_type = "HC3",
  site_specific = FALSE
) {
  registry <- tibble::tribble(
    ~predictor_id, ~effect_id, ~high, ~low, ~increment,
    "work_free_day", "free_vs_work", "Free day", "Work day", NA_real_,
    "activity_status", "active_vs_sedentary",
    h06_activity_levels()[[2L]], h06_activity_levels()[[1L]], NA_real_,
    "previous_sleep_duration_centered_h", "per_hour_previous_sleep",
    NA_character_, NA_character_, 1
  )
  sites <- if (site_specific) levels(bundle$data$site) else NA_character_
  dplyr::bind_rows(lapply(sites, function(site) {
    dplyr::bind_rows(lapply(seq_len(nrow(registry)), function(index) {
      row <- registry[index, ]
      result <- h06_standardized_contrast(
        bundle,
        variable = row$predictor_id,
        high = row$high,
        low = row$low,
        increment = row$increment,
        site = if (site_specific) site else NULL,
        distribution = distribution,
        covariance_type = covariance_type
      )
      dplyr::mutate(
        result,
        run_id = run_id,
        model_role = model_role,
        predictor_id = row$predictor_id,
        effect_id = row$effect_id,
        distribution = distribution,
        covariance_type = covariance_type,
        site_specific = site_specific,
        site = if (site_specific) site else NA_character_,
        .before = 1L
      )
    }))
  }))
}

h06_reference_mean <- function(
  bundle,
  run_id,
  distribution = "equal_site",
  covariance_type = "HC3"
) {
  sites <- levels(bundle$data$site)
  grid <- h06_prediction_defaults(bundle, sites)
  design <- h06_model_matrix_newdata(bundle, grid)
  weights <- h06_site_weights(bundle, sites, distribution)
  gradient <- drop(crossprod(design, weights))
  log_estimate <- drop(crossprod(gradient, stats::coef(bundle$fit)))
  result <- h06_log_delta(
    log_estimate,
    gradient,
    bundle$covariance[[covariance_type]]$value,
    df = nlevels(bundle$data$participant_key) - 1L,
    null_log = NA_real_
  )
  dplyr::transmute(
    result,
    run_id = run_id,
    distribution = distribution,
    covariance_type = covariance_type,
    reference_day = levels(bundle$data$work_free_day)[[1L]],
    reference_activity = levels(bundle$data$activity_status)[[1L]],
    reference_previous_sleep_h = 8,
    expected_melEDI_lx = .data$estimate_ratio,
    conf_low_melEDI_lx = .data$conf_low_ratio,
    conf_high_melEDI_lx = .data$conf_high_ratio,
    log_standard_error = .data$log_standard_error,
    denominator_df = .data$denominator_df,
    status = .data$status
  )
}

h06_adjust_complete_family <- function(data, planned_size = 3L) {
  if (nrow(data) != planned_size) {
    h06_abort(
      "H06 multiplicity family has %d rows; expected %d",
      nrow(data),
      planned_size
    )
  }
  family_size <- planned_size
  data |>
    dplyr::mutate(
      planned_size = .env$family_size,
      available_rank = sum(is.finite(.data$p_raw)),
      adjustment_method = "BH",
      p_adjusted = stats::p.adjust(
        .data$p_raw,
        method = "BH",
        n = .env$family_size
      ),
      adjusted_significant_0_05 = is.finite(.data$p_adjusted) &
        .data$p_adjusted <= 0.05
    )
}

h06_primary_tests <- function(
  additive_bundle,
  full_bundle,
  run_id,
  main_family,
  heterogeneity_family,
  covariance_type = "HC3"
) {
  predictors <- c(
    "work_free_day",
    "activity_status",
    "previous_sleep_duration_centered_h"
  )
  interaction_terms <- c(
    "site:work_free_day",
    "site:activity_status",
    "site:previous_sleep_duration_centered_h"
  )
  main <- dplyr::bind_rows(lapply(seq_along(predictors), function(index) {
    predictor <- predictors[[index]]
    h06_wald_f(
      additive_bundle,
      h06_term_restriction(additive_bundle$fit, predictor),
      covariance_type
    ) |>
      dplyr::mutate(
        run_id = run_id,
        family_id = main_family,
        family_member = index,
        test_role = "additive_main_association",
        predictor_id = predictor,
        tested_term = predictor,
        covariance_type = covariance_type,
        .before = 1L
      )
  })) |>
    h06_adjust_complete_family()
  heterogeneity <- dplyr::bind_rows(lapply(
    seq_along(interaction_terms),
    function(index) {
      term <- interaction_terms[[index]]
      h06_wald_f(
        full_bundle,
        h06_term_restriction(full_bundle$fit, term),
        covariance_type
      ) |>
        dplyr::mutate(
          run_id = run_id,
          family_id = heterogeneity_family,
          family_member = index,
          test_role = "site_heterogeneity",
          predictor_id = predictors[[index]],
          tested_term = term,
          covariance_type = covariance_type,
          .before = 1L
        )
    }
  )) |>
    h06_adjust_complete_family()
  list(main = main, heterogeneity = heterogeneity)
}

h06_f3_family <- function(core_effects) {
  core_effects |>
    dplyr::arrange(match(
      .data$predictor_id,
      c(
        "work_free_day", "activity_status",
        "previous_sleep_duration_centered_h"
      )
    )) |>
    dplyr::mutate(
      family_id = "H06-F3-practical-contrasts",
      family_member = dplyr::row_number(),
      test_role = "reader_facing_equal_site_contrast"
    ) |>
    h06_adjust_complete_family()
}

h06_cluster_diagnostics <- function(bundle, run_id, model_role) {
  cluster <- droplevels(bundle$data$participant_key)
  score <- sandwich::estfun(bundle$fit)
  score_by_cluster <- rowsum(score, cluster, reorder = FALSE)
  score_energy <- rowSums(score_by_cluster^2)
  leverage <- stats::hatvalues(bundle$fit)
  leverage_by_cluster <- rowsum(leverage, cluster, reorder = FALSE)[, 1L]
  tibble::tibble(
    run_id = run_id,
    model_role = model_role,
    participant_key = rownames(score_by_cluster),
    observations = as.integer(table(cluster)[rownames(score_by_cluster)]),
    score_energy = score_energy,
    score_share = score_energy / sum(score_energy),
    leverage = leverage_by_cluster,
    leverage_share = leverage_by_cluster / sum(leverage_by_cluster),
    score_rank = rank(-score_energy, ties.method = "first"),
    leverage_rank = rank(-leverage_by_cluster, ties.method = "first")
  ) |>
    dplyr::arrange(.data$score_rank)
}

h06_fit_diagnostics_robust <- function(bundle, run_id, model_role) {
  if (is.null(bundle$fit)) {
    return(tibble::tibble(
      run_id = run_id,
      model_role = model_role,
      working_power = bundle$working_power,
      formula = h06_formula_text(bundle$formula),
      converged = FALSE,
      fit_error = bundle$fit_error
    ))
  }
  fit <- bundle$fit
  covariance <- h06_covariance_diagnostics(bundle$covariance$HC3$value)
  clusters <- h06_cluster_diagnostics(bundle, run_id, model_role)
  design <- stats::model.matrix(fit)
  pearson <- stats::residuals(fit, type = "pearson")
  fitted <- stats::fitted(fit)
  tibble::tibble(
    run_id = run_id,
    model_role = model_role,
    working_power = bundle$working_power,
    formula = h06_formula_text(bundle$formula),
    observations = stats::nobs(fit),
    participants = nlevels(bundle$data$participant_key),
    participant_days = nlevels(bundle$data$participant_day_key),
    sites = nlevels(bundle$data$site),
    iterations = fit$iter,
    converged = isTRUE(fit$converged),
    design_columns = ncol(design),
    design_rank = fit$rank,
    full_rank = fit$rank == ncol(design),
    aliased_coefficients = sum(is.na(stats::coef(fit))),
    finite_coefficients = all(is.finite(stats::coef(fit))),
    hc3_covariance_finite = covariance$finite,
    hc3_covariance_positive_definite = covariance$positive_definite,
    hc3_covariance_rank = covariance$numerical_rank,
    hc3_covariance_minimum_eigenvalue = covariance$minimum_eigenvalue,
    hc3_covariance_condition_number = covariance$condition_number,
    dispersion = summary(fit)$dispersion,
    exact_zero_hours = sum(bundle$data$response_value == 0),
    exact_zero_fraction = mean(bundle$data$response_value == 0),
    fitted_minimum = min(fitted),
    fitted_median = stats::median(fitted),
    fitted_maximum = max(fitted),
    pearson_mean = mean(pearson),
    pearson_sd = stats::sd(pearson),
    pearson_q01 = unname(stats::quantile(pearson, 0.01)),
    pearson_q99 = unname(stats::quantile(pearson, 0.99)),
    residual_fitted_spearman = suppressWarnings(stats::cor(
      pearson,
      fitted,
      method = "spearman"
    )),
    absolute_residual_fitted_spearman = suppressWarnings(stats::cor(
      abs(pearson),
      fitted,
      method = "spearman"
    )),
    maximum_cluster_score_share = max(clusters$score_share),
    maximum_cluster_leverage_share = max(clusters$leverage_share),
    elapsed_seconds = bundle$elapsed_seconds,
    fit_warnings = paste(bundle$fit_warnings, collapse = " | "),
    covariance_warnings = paste(
      bundle$covariance$HC3$warnings,
      collapse = " | "
    ),
    fit_error = bundle$fit_error,
    numerical_check_pass =
      isTRUE(fit$converged) && fit$rank == ncol(design) &&
      all(is.finite(stats::coef(fit))) && covariance$finite &&
      covariance$positive_definite && covariance$condition_number < 1e10 &&
      max(clusters$score_share) <= 0.50 &&
      max(clusters$leverage_share) <= 0.20
  )
}

h06_covariance_diagnostic_rows <- function(bundle, run_id, model_role) {
  dplyr::bind_rows(lapply(names(bundle$covariance), function(type) {
    item <- bundle$covariance[[type]]
    h06_covariance_diagnostics(item$value) |>
      dplyr::mutate(
        run_id = run_id,
        model_role = model_role,
        working_power = bundle$working_power,
        covariance_type = type,
        covariance_warnings = paste(item$warnings, collapse = " | "),
        covariance_error = item$error,
        .before = 1L
      )
  }))
}

h06_residual_outputs <- function(bundle, run_id, model_role) {
  data <- bundle$data |>
    dplyr::mutate(
      pearson_residual = as.numeric(stats::residuals(bundle$fit, type = "pearson")),
      deviance_residual = as.numeric(stats::residuals(bundle$fit, type = "deviance")),
      fitted_mean = as.numeric(stats::fitted(bundle$fit))
    )
  calibration <- data |>
    dplyr::mutate(fitted_decile = dplyr::ntile(.data$fitted_mean, 10L)) |>
    dplyr::summarise(
      observations = dplyr::n(),
      observed_mean = mean(.data$response_value),
      fitted_mean = mean(.data$fitted_mean),
      observed_to_fitted_ratio = .data$observed_mean / .data$fitted_mean,
      zero_fraction = mean(.data$response_value == 0),
      pearson_mean = mean(.data$pearson_residual),
      pearson_sd = stats::sd(.data$pearson_residual),
      .by = "fitted_decile"
    ) |>
    dplyr::mutate(run_id = run_id, model_role = model_role, .before = 1L)
  fitted_bins <- data |>
    dplyr::mutate(fitted_bin = dplyr::ntile(.data$fitted_mean, 30L)) |>
    dplyr::summarise(
      observations = dplyr::n(),
      fitted_mean = mean(.data$fitted_mean),
      fitted_minimum = min(.data$fitted_mean),
      fitted_maximum = max(.data$fitted_mean),
      pearson_mean = mean(.data$pearson_residual),
      pearson_q25 = unname(stats::quantile(.data$pearson_residual, 0.25)),
      pearson_q75 = unname(stats::quantile(.data$pearson_residual, 0.75)),
      absolute_pearson_mean = mean(abs(.data$pearson_residual)),
      observed_mean = mean(.data$response_value),
      zero_fraction = mean(.data$response_value == 0),
      .by = "fitted_bin"
    ) |>
    dplyr::mutate(run_id = run_id, model_role = model_role, .before = 1L)
  clock <- data |>
    dplyr::mutate(clock_hour_bin = floor(.data$clock_hour)) |>
    dplyr::summarise(
      one_hour_observations = dplyr::n(),
      participant_days = dplyr::n_distinct(.data$participant_day_key),
      participants = dplyr::n_distinct(.data$participant_key),
      residual_mean = mean(.data$pearson_residual),
      residual_sd = stats::sd(.data$pearson_residual),
      fitted_mean = mean(.data$fitted_mean),
      observed_mean = mean(.data$response_value),
      zero_fraction = mean(.data$response_value == 0),
      .by = c("site", "work_free_day", "activity_status", "clock_hour_bin")
    ) |>
    dplyr::mutate(run_id = run_id, model_role = model_role, .before = 1L)
  sequence_split <- split(data$pearson_residual, data$hour_sequence_id)
  acf <- dplyr::bind_rows(lapply(1:6, function(lag) {
    pairs <- lapply(sequence_split, function(residual) {
      if (length(residual) <= lag) return(NULL)
      tibble::tibble(
        current = residual[(lag + 1L):length(residual)],
        earlier = residual[seq_len(length(residual) - lag)]
      )
    }) |>
      dplyr::bind_rows() |>
      dplyr::filter(is.finite(.data$current), is.finite(.data$earlier))
    tibble::tibble(
      lag_hours = lag,
      residual_correlation = if (nrow(pairs) >= 3L) {
        stats::cor(pairs$current, pairs$earlier)
      } else {
        NA_real_
      },
      residual_pairs = nrow(pairs)
    )
  })) |>
    dplyr::mutate(run_id = run_id, model_role = model_role, .before = 1L)
  row_source <- data |>
    dplyr::transmute(
      run_id = run_id,
      model_role = model_role,
      model_row_id = .data$.model_row_id,
      site = as.character(.data$site),
      participant_key = as.character(.data$participant_key),
      participant_day_key = as.character(.data$participant_day_key),
      hour_sequence_id = as.character(.data$hour_sequence_id),
      clock_hour = .data$clock_hour,
      response_value = .data$response_value,
      fitted_mean = .data$fitted_mean,
      pearson_residual = .data$pearson_residual,
      deviance_residual = .data$deviance_residual
    )
  list(
    calibration = calibration,
    fitted_bins = fitted_bins,
    clock = clock,
    acf = acf,
    row_source = row_source
  )
}

h06_stability_class <- function(
  estimate_a,
  low_a,
  high_a,
  estimate_b,
  low_b,
  high_b,
  conclusion_a = NA,
  conclusion_b = NA
) {
  if (any(!is.finite(c(
    estimate_a, low_a, high_a, estimate_b, low_b, high_b
  )))) {
    return("non-estimable")
  }
  if (sign(estimate_a) != sign(estimate_b) && estimate_a != 0 && estimate_b != 0) {
    return("direction-sensitive")
  }
  if (!is.na(conclusion_a) && !is.na(conclusion_b) && conclusion_a != conclusion_b) {
    return("multiplicity-conclusion-sensitive")
  }
  excludes_zero_a <- low_a > 0 || high_a < 0
  excludes_zero_b <- low_b > 0 || high_b < 0
  if (excludes_zero_a != excludes_zero_b) {
    return("precision-sensitive")
  }
  mutually_contained <- estimate_a >= low_b && estimate_a <= high_b &&
    estimate_b >= low_a && estimate_b <= high_a
  if (!mutually_contained) return("magnitude-sensitive")
  "stable within model uncertainty"
}

h06_compare_effect_sets <- function(reference, alternative, comparison_id) {
  if (!"p_adjusted" %in% names(reference)) reference$p_adjusted <- NA_real_
  if (!"p_adjusted" %in% names(alternative)) alternative$p_adjusted <- NA_real_
  reference_small <- reference |>
    dplyr::transmute(
      .data$predictor_id,
      reference_log_estimate = .data$log_estimate,
      reference_log_se = .data$log_standard_error,
      reference_log_low = dplyr::if_else(
        .data$conf_low_ratio > 0,
        log(.data$conf_low_ratio),
        NA_real_
      ),
      reference_log_high = dplyr::if_else(
        .data$conf_high_ratio > 0,
        log(.data$conf_high_ratio),
        NA_real_
      ),
      reference_ratio = .data$estimate_ratio,
      reference_conf_low = .data$conf_low_ratio,
      reference_conf_high = .data$conf_high_ratio,
      reference_p_adjusted = .data$p_adjusted
    )
  alternative_small <- alternative |>
    dplyr::transmute(
      .data$predictor_id,
      alternative_log_estimate = .data$log_estimate,
      alternative_log_low = dplyr::if_else(
        .data$conf_low_ratio > 0,
        log(.data$conf_low_ratio),
        NA_real_
      ),
      alternative_log_high = dplyr::if_else(
        .data$conf_high_ratio > 0,
        log(.data$conf_high_ratio),
        NA_real_
      ),
      alternative_ratio = .data$estimate_ratio,
      alternative_conf_low = .data$conf_low_ratio,
      alternative_conf_high = .data$conf_high_ratio,
      alternative_p_adjusted = .data$p_adjusted
    )
  dplyr::left_join(
    reference_small,
    alternative_small,
    by = "predictor_id",
    relationship = "one-to-one"
  ) |>
    dplyr::rowwise() |>
    dplyr::mutate(
      comparison_id = comparison_id,
      log_estimate_difference = .data$alternative_log_estimate -
        .data$reference_log_estimate,
      absolute_difference_reference_se = abs(.data$log_estimate_difference) /
        .data$reference_log_se,
      reference_conclusion = if (is.finite(.data$reference_p_adjusted)) {
        .data$reference_p_adjusted <= 0.05
      } else {
        NA
      },
      alternative_conclusion = if (is.finite(.data$alternative_p_adjusted)) {
        .data$alternative_p_adjusted <= 0.05
      } else {
        NA
      },
      stability_classification = h06_stability_class(
        .data$reference_log_estimate,
        .data$reference_log_low,
        .data$reference_log_high,
        .data$alternative_log_estimate,
        .data$alternative_log_low,
        .data$alternative_log_high,
        .data$reference_conclusion,
        .data$alternative_conclusion
      )
    ) |>
    dplyr::ungroup() |>
    dplyr::relocate(.data$comparison_id)
}

h06_exploratory_estimands <- function(bundle, analysis_id) {
  variable <- h06_exploratory_variable(analysis_id)
  if (variable == "exercise_location") {
    levels_variable <- levels(bundle$data[[variable]])
    output <- dplyr::bind_rows(lapply(levels_variable[-1L], function(level) {
      h06_standardized_contrast(
        bundle,
        variable = variable,
        high = level,
        low = levels_variable[[1L]],
        covariance_type = "HC3"
      ) |>
        dplyr::mutate(
          effect_id = paste0(level, "_vs_", levels_variable[[1L]])
        )
    }))
  } else {
    output <- h06_standardized_contrast(
      bundle,
      variable = variable,
      increment = 1,
      covariance_type = "HC3"
    ) |>
      dplyr::mutate(effect_id = paste0("per_hour__", variable))
  }
  output |>
    dplyr::mutate(
      analysis_id = analysis_id,
      predictor_id = variable,
      inferential_role = "exploratory_estimate_and_95CI_no_p_value_screen",
      p_raw = NA_real_,
      .before = 1L
    )
}

h06_deletion_battery <- function(primary_frame, primary_additive, primary_full) {
  full_effects <- h06_core_estimands(
    primary_additive,
    "main__glasses__all_available"
  )
  cluster_scores <- h06_cluster_diagnostics(
    primary_additive,
    "main__glasses__all_available",
    "additive"
  )
  participant_candidates <- unique(c(
    utils::head(cluster_scores$participant_key, 5L),
    "TUM::TUM_S001",
    "KNUST::KNUST_S005"
  ))
  participant_candidates <- participant_candidates[
    participant_candidates %in% as.character(primary_frame$participant_key)
  ]
  candidates <- dplyr::bind_rows(
    tibble::tibble(
      deletion_type = "participant",
      deletion_unit = participant_candidates
    ),
    tibble::tibble(
      deletion_type = "site",
      deletion_unit = levels(primary_frame$site)
    )
  )
  formulas <- h06_formula_set()
  dplyr::bind_rows(lapply(seq_len(nrow(candidates)), function(index) {
    deletion_type <- candidates$deletion_type[[index]]
    deletion_unit <- candidates$deletion_unit[[index]]
    reduced <- if (deletion_type == "participant") {
      primary_frame |>
        dplyr::filter(as.character(.data$participant_key) != deletion_unit) |>
        h06_refactor_frame()
    } else {
      primary_frame |>
        dplyr::filter(as.character(.data$site) != deletion_unit) |>
        h06_refactor_frame()
    }
    additive <- h06_fit_marginal(reduced, formulas$additive, working_power = 1)
    full <- h06_fit_marginal(reduced, formulas$full, working_power = 1)
    additive_diagnostic <- h06_fit_diagnostics_robust(
      additive,
      paste0("delete__", deletion_type, "__", deletion_unit),
      "additive"
    )
    full_diagnostic <- h06_fit_diagnostics_robust(
      full,
      paste0("delete__", deletion_type, "__", deletion_unit),
      "full"
    )
    reduced_effects <- h06_core_estimands(
      additive,
      paste0("delete__", deletion_type, "__", deletion_unit)
    )
    dplyr::left_join(
      full_effects |>
        dplyr::select(
          .data$predictor_id,
          full_log_estimate = .data$log_estimate,
          full_log_standard_error = .data$log_standard_error
        ),
      reduced_effects |>
        dplyr::select(
          .data$predictor_id,
          deletion_log_estimate = .data$log_estimate,
          deletion_estimate_ratio = .data$estimate_ratio,
          deletion_conf_low_ratio = .data$conf_low_ratio,
          deletion_conf_high_ratio = .data$conf_high_ratio
        ),
      by = "predictor_id",
      relationship = "one-to-one"
    ) |>
      dplyr::mutate(
        deletion_type = deletion_type,
        deletion_unit = deletion_unit,
        observations = nrow(reduced),
        participants = dplyr::n_distinct(reduced$participant_key),
        sites = dplyr::n_distinct(reduced$site),
        additive_converged = additive_diagnostic$converged,
        additive_full_rank = additive_diagnostic$full_rank,
        additive_hc3_positive_definite =
          additive_diagnostic$hc3_covariance_positive_definite,
        full_converged = full_diagnostic$converged,
        full_design_full_rank = full_diagnostic$full_rank,
        full_hc3_positive_definite =
          full_diagnostic$hc3_covariance_positive_definite,
        full_hc3_condition_number =
          full_diagnostic$hc3_covariance_condition_number,
        log_estimate_shift = .data$deletion_log_estimate -
          .data$full_log_estimate,
        absolute_shift_full_hc3_se = abs(.data$log_estimate_shift) /
          .data$full_log_standard_error,
        .before = 1L
      )
  }))
}
