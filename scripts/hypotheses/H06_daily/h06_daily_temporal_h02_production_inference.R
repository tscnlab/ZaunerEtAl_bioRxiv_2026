# Pointwise inference and diagnostics for one approved H02-aligned H06-daily
# temporal production fit. No simultaneous-band simulation is implemented.

h06d_h02_production_smooth_tests <- function(fit, run) {
  smooth_table <- summary(fit)$s.table
  required <- tibble::tribble(
    ~estimand_order, ~estimand_id, ~estimand_label, ~smooth_label,
    1L, "free_minus_work", "Free day minus Work day",
    "s(time_hour,work_free_day)",
    2L, "active_minus_sedentary", "Active minus Sedentary",
    "s(time_hour,activity_status)",
    3L, "sleep_within_plus_1h",
    "+1 h previous-night sleep within participant",
    "s(time_hour):sleep_within_h",
    4L, "sleep_between_plus_1h",
    "+1 h participant-mean previous-night sleep between participants",
    "s(time_hour):sleep_between_h"
  )
  if (
    is.null(smooth_table) ||
      !all(required$smooth_label %in% rownames(smooth_table))
  ) {
    h06d_abort("Required whole-function smooth tests are unavailable")
  }
  statistic_column <- intersect(c("F", "Chi.sq"), colnames(smooth_table))
  p_column <- intersect(c("p-value", "p-value"), colnames(smooth_table))
  if (length(statistic_column) != 1L || length(p_column) != 1L) {
    h06d_abort("Unexpected mgcv smooth-test columns")
  }
  selected <- smooth_table[required$smooth_label, , drop = FALSE]
  required |>
    dplyr::mutate(
      run_order = run$run_order,
      run_id = run$run_id,
      data_scenario_id = run$data_scenario_id,
      placement_id = run$placement_id,
      sample_scenario = run$sample_scenario,
      multiplicity_role = run$multiplicity_role,
      effective_df = as.numeric(selected[, "edf"]),
      reference_df = as.numeric(selected[, "Ref.df"]),
      test_statistic = as.numeric(selected[, statistic_column]),
      raw_p_value_unclamped = as.numeric(selected[, p_column]),
      raw_p_value = pmin(1, pmax(0, .data$raw_p_value_unclamped)),
      p_value_numerical_clamp =
        .data$raw_p_value != .data$raw_p_value_unclamped,
      approximation = paste(
        "mgcv whole-smooth approximate test from the selected fixed-rho",
        "Gaussian fREML BAM"
      )
    ) |>
    dplyr::relocate(
      run_order, run_id, data_scenario_id, placement_id, sample_scenario,
      multiplicity_role
    )
}

h06d_h02_population_exclusions <- function(fit) {
  labels <- vapply(fit$smooth, function(smooth) smooth$label, character(1))
  required <- c(
    "s(time_hour,site)",
    "s(time_hour,participant)",
    "s(participant_day)"
  )
  if (!all(required %in% labels)) {
    h06d_abort("Population display exclusions do not match fitted smooths")
  }
  required
}

h06d_h02_lpmatrix <- function(
  fit,
  frame,
  work_free_day,
  activity_status,
  sleep_between_h = 0,
  sleep_within_h = 0,
  time_hour = seq(0.25, 23.75, by = 0.5)
) {
  fit_data <- fit$model
  day_values <- as.character(work_free_day)
  activity_values <- as.character(activity_status)
  grid <- tidyr::expand_grid(
    time_hour = time_hour,
    work_free_day = day_values,
    activity_status = activity_values,
    sleep_between_h = sleep_between_h,
    sleep_within_h = sleep_within_h
  ) |>
    dplyr::mutate(
      site = factor(levels(fit_data$site)[[1L]], levels = levels(fit_data$site)),
      participant = factor(
        levels(fit_data$participant)[[1L]],
        levels = levels(fit_data$participant)
      ),
      participant_day = factor(
        levels(fit_data$participant_day)[[1L]],
        levels = levels(fit_data$participant_day)
      ),
      work_free_day = factor(
        .data$work_free_day,
        levels = levels(fit_data$work_free_day)
      ),
      activity_status = factor(
        .data$activity_status,
        levels = levels(fit_data$activity_status)
      )
    )
  matrix <- stats::predict(
    fit,
    newdata = grid,
    type = "lpmatrix",
    exclude = h06d_h02_population_exclusions(fit),
    discrete = FALSE,
    newdata.guaranteed = TRUE
  )
  list(grid = grid, matrix = matrix)
}

h06d_h02_average_lpmatrix <- function(object) {
  split_index <- split(seq_len(nrow(object$grid)), object$grid$time_hour)
  matrix <- do.call(rbind, lapply(split_index, function(index) {
    colMeans(object$matrix[index, , drop = FALSE])
  }))
  time_hour <- as.numeric(names(split_index))
  order <- order(time_hour)
  list(time_hour = time_hour[order], matrix = matrix[order, , drop = FALSE])
}

h06d_h02_pointwise_covariance <- function(fit) {
  covariance <- tryCatch(
    stats::vcov(fit, unconditional = TRUE),
    error = function(condition) NULL
  )
  if (
    is.null(covariance) ||
      !is.matrix(covariance) ||
      any(dim(covariance) != length(stats::coef(fit))) ||
      any(!is.finite(covariance))
  ) {
    covariance <- fit$Vp
    covariance_type <- "conditional on fitted smoothing parameters"
  } else {
    covariance_type <-
      "unconditional model covariance including smoothing-parameter uncertainty"
  }
  list(matrix = covariance, type = covariance_type)
}

h06d_h02_link_from_matrix <- function(matrix, fit, covariance) {
  estimate <- as.numeric(matrix %*% stats::coef(fit))
  variance <- rowSums((matrix %*% covariance) * matrix)
  variance[variance < 0 & variance > -1e-10] <- 0
  if (any(!is.finite(variance)) || any(variance < 0)) {
    h06d_abort("Pointwise prediction variance is invalid")
  }
  standard_error <- sqrt(variance)
  critical <- stats::qnorm(0.975)
  tibble::tibble(
    link_estimate = estimate,
    link_standard_error = standard_error,
    link_lower_95 = estimate - critical * standard_error,
    link_upper_95 = estimate + critical * standard_error
  )
}

h06d_h02_production_curves <- function(fit, frame, run) {
  covariance <- h06d_h02_pointwise_covariance(fit)
  day_levels <- c("Work day", "Free day")
  activity_levels <- c("Sedentary", "Active")

  l_work <- h06d_h02_average_lpmatrix(h06d_h02_lpmatrix(
    fit, frame, "Work day", activity_levels
  ))
  l_free <- h06d_h02_average_lpmatrix(h06d_h02_lpmatrix(
    fit, frame, "Free day", activity_levels
  ))
  l_sedentary <- h06d_h02_average_lpmatrix(h06d_h02_lpmatrix(
    fit, frame, day_levels, "Sedentary"
  ))
  l_active <- h06d_h02_average_lpmatrix(h06d_h02_lpmatrix(
    fit, frame, day_levels, "Active"
  ))
  l_reference <- h06d_h02_average_lpmatrix(h06d_h02_lpmatrix(
    fit, frame, day_levels, activity_levels
  ))
  l_within_plus <- h06d_h02_average_lpmatrix(h06d_h02_lpmatrix(
    fit, frame, day_levels, activity_levels, sleep_within_h = 1
  ))
  l_between_plus <- h06d_h02_average_lpmatrix(h06d_h02_lpmatrix(
    fit, frame, day_levels, activity_levels, sleep_between_h = 1
  ))

  estimands <- list(
    free_minus_work = list(
      order = 1L,
      label = "Free day minus Work day",
      contrast = l_free$matrix - l_work$matrix
    ),
    active_minus_sedentary = list(
      order = 2L,
      label = "Active minus Sedentary",
      contrast = l_active$matrix - l_sedentary$matrix
    ),
    sleep_within_plus_1h = list(
      order = 3L,
      label = "+1 h previous-night sleep within participant",
      contrast = l_within_plus$matrix - l_reference$matrix
    ),
    sleep_between_plus_1h = list(
      order = 4L,
      label = paste(
        "+1 h participant-mean previous-night sleep between participants"
      ),
      contrast = l_between_plus$matrix - l_reference$matrix
    )
  )
  functions <- dplyr::bind_rows(lapply(names(estimands), function(id) {
    estimand <- estimands[[id]]
    h06d_h02_link_from_matrix(
      estimand$contrast,
      fit,
      covariance$matrix
    ) |>
      dplyr::mutate(
        run_order = run$run_order,
        run_id = run$run_id,
        data_scenario_id = run$data_scenario_id,
        data_scenario_label = run$data_scenario_label,
        placement_id = run$placement_id,
        placement_label = run$placement_label,
        sample_scenario = run$sample_scenario,
        analytical_role = run$analytical_role,
        multiplicity_role = run$multiplicity_role,
        estimand_order = estimand$order,
        estimand_id = id,
        estimand_label = estimand$label,
        time_hour = l_reference$time_hour,
        shifted_response_ratio = 10^.data$link_estimate,
        shifted_response_ratio_lower_95 = 10^.data$link_lower_95,
        shifted_response_ratio_upper_95 = 10^.data$link_upper_95,
        interval_type = "pointwise 95% confidence interval",
        covariance_type = covariance$type,
        response_scale = "log10(Y + 0.1 lx)"
      ) |>
      dplyr::relocate(
        run_order, run_id, data_scenario_id, data_scenario_label,
        placement_id, placement_label, sample_scenario, analytical_role,
        multiplicity_role, estimand_order, estimand_id, estimand_label,
        time_hour
      )
  }))

  profiles <- list(
    work_day = list(1L, "day_type", "Work day", l_work$matrix),
    free_day = list(2L, "day_type", "Free day", l_free$matrix),
    sedentary = list(1L, "activity", "Sedentary", l_sedentary$matrix),
    active = list(2L, "activity", "Active", l_active$matrix),
    sleep_reference = list(
      1L, "sleep_within", "Participant-specific sleep reference",
      l_reference$matrix
    ),
    sleep_within_plus_1h = list(
      2L, "sleep_within", "+1 h within participant", l_within_plus$matrix
    ),
    sleep_between_reference = list(
      1L, "sleep_between", "Participant-mean sleep reference",
      l_reference$matrix
    ),
    sleep_between_plus_1h = list(
      2L, "sleep_between", "+1 h between participants", l_between_plus$matrix
    )
  )
  profile_curves <- dplyr::bind_rows(lapply(names(profiles), function(id) {
    profile <- profiles[[id]]
    h06d_h02_link_from_matrix(profile[[4L]], fit, covariance$matrix) |>
      dplyr::mutate(
        run_order = run$run_order,
        run_id = run$run_id,
        data_scenario_id = run$data_scenario_id,
        data_scenario_label = run$data_scenario_label,
        placement_id = run$placement_id,
        placement_label = run$placement_label,
        sample_scenario = run$sample_scenario,
        analytical_role = run$analytical_role,
        profile_family = profile[[2L]],
        profile_order = profile[[1L]],
        profile_id = id,
        profile_label = profile[[3L]],
        time_hour = l_reference$time_hour,
        display_medi_lx = pmax(0, 10^.data$link_estimate - 0.1),
        display_lower_95_lx = pmax(0, 10^.data$link_lower_95 - 0.1),
        display_upper_95_lx = pmax(0, 10^.data$link_upper_95 - 0.1),
        interval_type = "pointwise 95% confidence interval",
        covariance_type = covariance$type,
        display_scale_qualification = paste(
          "inverse transform of mean log10(Y + 0.1 lx);",
          "conditional-median-like, not raw-scale E[Y]"
        )
      ) |>
      dplyr::relocate(
        run_order, run_id, data_scenario_id, data_scenario_label,
        placement_id, placement_label, sample_scenario, analytical_role,
        profile_family, profile_order, profile_id, profile_label, time_hour
      )
  }))

  list(functions = functions, profiles = profile_curves)
}

h06d_h02_production_k_check <- function(fit, seed) {
  set.seed(seed)
  output <- tryCatch(
    mgcv::k.check(fit, subsample = 5000L, n.rep = 400L),
    error = function(condition) condition
  )
  if (inherits(output, "error")) {
    return(tibble::tibble(
      term = NA_character_,
      k_prime = NA_real_,
      effective_df = NA_real_,
      k_index = NA_real_,
      p_value = NA_real_,
      diagnostic_error = conditionMessage(output)
    ))
  }
  tibble::as_tibble(output, rownames = "term") |>
    rlang::set_names(
      c("term", "k_prime", "effective_df", "k_index", "p_value")
    ) |>
    dplyr::mutate(diagnostic_error = NA_character_)
}

h06d_h02_production_diagnostics <- function(
  checkpoint,
  frame,
  run,
  static_gate
) {
  fit <- checkpoint$model
  residual <- h06d_h02_standardized_residual(fit)
  fitted <- as.numeric(stats::fitted(fit))
  qq_theoretical <- stats::qnorm(stats::ppoints(length(residual)))
  hessian <- h06d_smoothing_hessian(fit)
  final_lag <- h06d_boundary_lag_correlation(
    residual, frame$AR_start, lag = 1L
  )
  preliminary_lag <- h06d_boundary_lag_correlation(
    checkpoint$preliminary_response_residuals,
    frame$AR_start,
    lag = 1L
  )
  fit_summary <- summary(fit)
  smooth_registry <- h06d_h02_smooth_registry(fit) |>
    dplyr::mutate(run_id = run$run_id, .before = 1L)
  k_check <- h06d_h02_production_k_check(
    fit,
    seed = 61062026L + as.integer(run$run_order)
  ) |>
    dplyr::mutate(run_id = run$run_id, .before = 1L)
  site_acf <- frame |>
    dplyr::mutate(.residual = residual) |>
    dplyr::group_split(.data$site, .keep = TRUE) |>
    lapply(function(site_data) {
      lag <- h06d_boundary_lag_correlation(
        site_data$.residual, site_data$AR_start, lag = 1L
      )
      tibble::tibble(
        run_id = run$run_id,
        site = as.character(site_data$site[[1L]]),
        residual_lag1 = unname(lag[["correlation"]]),
        adjacent_pairs = unname(lag[["pairs"]]),
        observations_30_minute = nrow(site_data)
      )
    }) |>
    dplyr::bind_rows()
  identifiability <- h06d_term_concurvity_fallback(
    fit,
    candidate_id = run$run_id,
    component = "selected production model",
    maximum_rows = 5000L,
    seed = 61062026L + as.integer(run$run_order)
  ) |>
    dplyr::rename(run_id = candidate_id)

  closure_grid <- frame[rep(1L, 2L), , drop = FALSE]
  closure_grid$time_hour <- c(0, 24)
  closure_grid$sleep_between_h <- 0
  closure_grid$sleep_within_h <- 0
  closure_prediction <- stats::predict(
    fit,
    newdata = closure_grid,
    type = "terms",
    terms = "s(time_hour)",
    discrete = FALSE,
    newdata.guaranteed = TRUE
  )
  closure_difference <- abs(
    closure_prediction[2L, "s(time_hour)"] -
      closure_prediction[1L, "s(time_hour)"]
  )
  closure <- tibble::tibble(
    run_id = run$run_id,
    link_at_0 = closure_prediction[1L, "s(time_hour)"],
    link_at_24 = closure_prediction[2L, "s(time_hour)"],
    absolute_endpoint_difference_link = closure_difference,
    tolerance = 1e-8,
    cyclic_closure_pass = closure_difference < 1e-8
  )

  component <- tibble::tibble(
    run_order = run$run_order,
    run_id = run$run_id,
    data_scenario_id = run$data_scenario_id,
    placement_id = run$placement_id,
    sample_scenario = run$sample_scenario,
    formula = paste(deparse(stats::formula(fit)), collapse = " "),
    family = fit$family$family,
    link = fit$family$link,
    observations_30_minute = nrow(frame),
    participant_days = dplyr::n_distinct(frame$participant_day_key),
    participants = dplyr::n_distinct(frame$participant_key),
    sites = dplyr::n_distinct(frame$site),
    exact_zero_bins = sum(frame$arithmetic_mean_medi_lx == 0),
    exact_zero_fraction = mean(frame$arithmetic_mean_medi_lx == 0),
    rho_unclamped = checkpoint$rho_unclamped,
    rho = checkpoint$rho,
    preliminary_residual_lag1 = unname(preliminary_lag[["correlation"]]),
    preliminary_residual_lag1_pairs = unname(preliminary_lag[["pairs"]]),
    final_standardized_residual_lag1 = unname(final_lag[["correlation"]]),
    final_standardized_residual_lag1_pairs = unname(final_lag[["pairs"]]),
    standardized_residual_qq_correlation = stats::cor(
      qq_theoretical,
      sort(residual)
    ),
    absolute_residual_fitted_spearman = suppressWarnings(stats::cor(
      abs(residual),
      fitted,
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
    maximum_hat = if (length(fit$hat)) max(fit$hat, na.rm = TRUE) else NA_real_,
    preliminary_warning_count = length(checkpoint$preliminary_warnings),
    final_warning_count = length(checkpoint$final_warnings),
    reused_selected_pilot = checkpoint$reused_selected_pilot
  )

  fixed_identifiability <- identifiability |>
    dplyr::filter(
      !grepl("participant", .data$term, fixed = TRUE),
      !grepl("participant_day", .data$term, fixed = TRUE)
    )
  identifiability_max <- max(
    fixed_identifiability$fitted_term_multiple_r_squared,
    na.rm = TRUE
  )
  finite_k <- k_check |>
    dplyr::filter(is.finite(.data$k_index), is.finite(.data$p_value))
  basis_bad <- finite_k |>
    dplyr::filter(.data$k_index < 0.90, .data$p_value < 0.05)
  context_edf <- smooth_registry |>
    dplyr::filter(
      .data$term %in% c(
        "s(time_hour,work_free_day)",
        "s(time_hour,activity_status)",
        "s(time_hour):sleep_between_h",
        "s(time_hour):sleep_within_h"
      )
    ) |>
    dplyr::mutate(k_prime = .data$coefficient_columns - 1) |>
    dplyr::mutate(edf_fraction = .data$effective_df / .data$k_prime)
  high_edf_terms <- context_edf$term[context_edf$edf_fraction >= 0.90]

  formula_pass <- identical(
    paste(deparse(stats::formula(fit)), collapse = " "),
    paste(deparse(h06d_h02_temporal_formula("response")), collapse = " ")
  ) && all(smooth_registry$xt_is_null)
  hessian_pass <- isTRUE(component$smoothing_hessian_positive_definite) ||
    component$smoothing_hessian_minimum_relative_eigenvalue > -1e-8
  convergence_pass <-
    component$convergence == "full convergence" &&
      component$preliminary_warning_count == 0L &&
      component$final_warning_count == 0L &&
      hessian_pass
  basis_pass <- nrow(basis_bad) == 0L && all(is.na(k_check$diagnostic_error))
  distribution_pass <-
    component$standardized_residual_qq_correlation >= 0.95 &&
      abs(component$absolute_residual_fitted_spearman) < 0.30
  temporal_pass <-
    abs(component$final_standardized_residual_lag1) < 0.20 &&
      max(abs(site_acf$residual_lag1), na.rm = TRUE) < 0.30
  identifiability_pass <- is.finite(identifiability_max) &&
    identifiability_max < 0.80
  support_pass <- identical(static_gate$static_gate, "PASS")

  verdict <- tibble::tribble(
    ~run_id, ~domain, ~evidence, ~status, ~plain_language_assessment,
    run$run_id,
    "Frame and context support",
    sprintf(
      "%d bins; %d days; %d participants; %d sites",
      nrow(frame),
      dplyr::n_distinct(frame$participant_day_key),
      dplyr::n_distinct(frame$participant_key),
      dplyr::n_distinct(frame$site)
    ),
    ifelse(support_pass, "PASS", "FAIL"),
    ifelse(support_pass, "Acceptable", "Not acceptable"),
    run$run_id,
    "Formula and H02 basis inheritance",
    paste("exact formula =", formula_pass, "; all fitted xt are NULL"),
    ifelse(formula_pass, "PASS", "FAIL"),
    ifelse(formula_pass, "Acceptable", "Not acceptable"),
    run$run_id,
    "Convergence and smoothing Hessian",
    sprintf(
      "%s; warnings %d/%d; Hessian minimum relative %.3g",
      component$convergence,
      component$preliminary_warning_count,
      component$final_warning_count,
      component$smoothing_hessian_minimum_relative_eigenvalue
    ),
    ifelse(convergence_pass, "PASS", "FAIL"),
    ifelse(convergence_pass, "Acceptable", "Not acceptable"),
    run$run_id,
    "Basis capacity",
    paste0(
      "finite k-index failures ", nrow(basis_bad),
      "; EDF-only review terms ",
      ifelse(length(high_edf_terms), paste(high_edf_terms, collapse = " | "), "none")
    ),
    ifelse(basis_pass, "PASS", "FAIL"),
    ifelse(
      basis_pass,
      "Acceptable; EDF proximity alone is recorded but is not a failure",
      "Not acceptable"
    ),
    run$run_id,
    "Residual distribution and scale pattern",
    sprintf(
      "QQ correlation %.3f; |residual|-fitted Spearman %.3f",
      component$standardized_residual_qq_correlation,
      component$absolute_residual_fitted_spearman
    ),
    ifelse(distribution_pass, "PASS", "FAIL"),
    ifelse(distribution_pass, "Acceptable", "Not acceptable"),
    run$run_id,
    "Residual temporal dependence",
    sprintf(
      "pooled lag-1 %.3f; maximum absolute site lag-1 %.3f",
      component$final_standardized_residual_lag1,
      max(abs(site_acf$residual_lag1), na.rm = TRUE)
    ),
    ifelse(temporal_pass, "PASS", "FAIL"),
    ifelse(temporal_pass, "Acceptable", "Not acceptable"),
    run$run_id,
    "Fixed-term identifiability screen",
    sprintf("maximum fitted-term multiple R-squared %.3f", identifiability_max),
    ifelse(identifiability_pass, "PASS", "FAIL"),
    ifelse(identifiability_pass, "Acceptable", "Not acceptable"),
    run$run_id,
    "Global cyclic closure",
    sprintf("endpoint difference %.3g link units", closure_difference),
    ifelse(closure$cyclic_closure_pass, "PASS", "FAIL"),
    ifelse(closure$cyclic_closure_pass, "Acceptable", "Not acceptable"),
    run$run_id,
    "Influence and site deletion",
    ifelse(
      is.finite(component$maximum_hat),
      sprintf(
        "maximum hat %.3f; site-deletion batch not run",
        component$maximum_hat
      ),
      "BAM hat diagonal unavailable; site-deletion batch not run"
    ),
    "WITHHELD",
    paste(
      "Influence and site-deletion stability remain unassessed under the",
      "separate compute gate"
    )
  )
  required_pass <- verdict |>
    dplyr::filter(.data$status != "WITHHELD") |>
    dplyr::summarise(pass = all(.data$status == "PASS")) |>
    dplyr::pull("pass")
  verdict <- dplyr::bind_rows(
    verdict,
    tibble::tibble(
      run_id = run$run_id,
      domain = "Overall base-model diagnostic gate",
      evidence = paste(
        sum(verdict$status == "PASS"),
        "required domains passed; influence deletion remains withheld"
      ),
      status = ifelse(required_pass, "ACCEPTABLE", "NOT_ACCEPTABLE"),
      plain_language_assessment = ifelse(
        required_pass,
        paste(
          "Acceptable for the approved exploratory association summaries;",
          "site-deletion stability is not yet assessed"
        ),
        "Not acceptable for association interpretation"
      )
    )
  )

  list(
    component = component,
    smooth_registry = smooth_registry,
    k_check = k_check,
    site_acf = site_acf,
    identifiability = identifiability,
    closure = closure,
    verdict = verdict,
    residual_quantiles = tibble::tibble(
      run_id = run$run_id,
      probability = c(0, 0.01, 0.05, 0.25, 0.5, 0.75, 0.95, 0.99, 1),
      standardized_residual = as.numeric(stats::quantile(
        residual,
        probs = c(0, 0.01, 0.05, 0.25, 0.5, 0.75, 0.95, 0.99, 1),
        na.rm = TRUE,
        names = FALSE
      ))
    )
  )
}
