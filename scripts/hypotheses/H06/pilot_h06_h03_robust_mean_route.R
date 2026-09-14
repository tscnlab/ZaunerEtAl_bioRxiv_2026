# Bounded H06 architecture pilot for the H03 population-mean route.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)

source(file.path(root, "scripts/pipeline/paths_io.R"))
source(file.path(root, "scripts/hypotheses/H06/h06_contract.R"))

options(lifecycle_verbosity = "quiet", warn = 1)

if (!identical(as.character(getRversion()), "4.6.1")) {
  h06_abort(
    "H06 H03-route pilot requires R 4.6.1; found %s",
    as.character(getRversion())
  )
}

required_packages <- c(
  "dplyr", "tibble", "tidyr", "readr", "sandwich", "statmod"
)
missing_packages <- required_packages[!vapply(
  required_packages,
  requireNamespace,
  logical(1),
  quietly = TRUE
)]
if (length(missing_packages) > 0L) {
  h06_abort(
    "H06 H03-route pilot is missing project package(s): %s",
    paste(missing_packages, collapse = ", ")
  )
}

producer <-
  "scripts/hypotheses/H06/pilot_h06_h03_robust_mean_route.R"
paths <- pipeline_paths(root)
model_data_root <- file.path(paths$model_data, "H06")
model_root <- file.path(paths$models, "H06")
diagnostic_root <- file.path(paths$diagnostics, "H06")
table_root <- file.path(paths$tables, "H06")
for (directory in c(
  model_data_root, model_root, diagnostic_root, table_root
)) {
  dir.create(directory, recursive = TRUE, showWarnings = FALSE)
}

write_h06_csv <- function(data, path) {
  write_csv_artifact(data, path, producer = producer)
  invisible(path)
}

write_h06_rds <- function(object, path) {
  write_rds_artifact(object, path, producer = producer)
  invisible(path)
}

capture_conditions <- function(expression) {
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

formula_text <- function(formula) paste(deparse(formula), collapse = " ")

fixed_formula <- stats::as.formula(paste(
  "response_value ~",
  "site * work_free_day + site * activity_status +",
  "site * previous_sleep_duration_centered_h"
))
additive_formula <- stats::as.formula(paste(
  "response_value ~ site + work_free_day + activity_status +",
  "previous_sleep_duration_centered_h"
))

route_registry <- tibble::tribble(
  ~route_id, ~working_power, ~working_family, ~role,
  "quasi_poisson_p1", 1,
  "quasi-Poisson log-mean", "recommended H06 primary working-mean candidate",
  "h03_literal_p1_539919", 1.539919,
  "quasi-Tweedie log-mean", "literal H03 working-power comparator",
  "h06_stable_p1_8", 1.8,
  "quasi-Tweedie log-mean", "effect-blind fixed-power working-variance sensitivity",
  "h06_v0_boundary_p1_9", 1.9,
  "quasi-Tweedie log-mean", "boundary check motivated by prior V0 power estimates near 1.9"
) |>
  dplyr::mutate(
    selected_for_revised_gate = .data$route_id ==
      "quasi_poisson_p1",
    response_estimand =
      "population-average expected zero-inclusive hourly melEDI",
    fixed_formula = formula_text(fixed_formula),
    dependence_handling = paste(
      "participant-cluster sandwich covariance; arbitrary dependence",
      "allowed across retained hours and days within participant"
    ),
    confirmatory_clock_term = FALSE,
    inferential_status =
      "bounded_architecture_pilot_not_accepted_inference"
  )

model_path <- file.path(
  model_root,
  "H06_v0_scaffold_pilot_models.rds"
)
if (!file.exists(model_path)) {
  h06_abort("Missing H06 scaffold-pilot model bundle: %s", model_path)
}
source_bundle <- readRDS(model_path)
if (!identical(sort(names(source_bundle)), c("chest", "glasses"))) {
  h06_abort("Unexpected placement set in H06 scaffold-pilot bundle")
}

family_for_power <- function(power) {
  if (identical(power, 1)) {
    return(stats::quasipoisson(link = "log"))
  }
  statmod::tweedie(var.power = power, link.power = 0)
}

fit_route <- function(data, working_power, formula = fixed_formula) {
  fit_capture <- capture_conditions(stats::glm(
    formula = formula,
    data = data,
    family = family_for_power(working_power),
    contrasts = list(site = "contr.sum"),
    control = stats::glm.control(epsilon = 1e-10, maxit = 100L),
    model = TRUE,
    x = TRUE,
    y = TRUE
  ))
  if (inherits(fit_capture$value, "error")) {
    return(list(
      model = NULL,
      fit_error = conditionMessage(fit_capture$value),
      fit_warnings = fit_capture$warnings,
      covariance = list()
    ))
  }
  model <- fit_capture$value
  covariance <- lapply(c("HC1", "HC3"), function(type) {
    capture <- capture_conditions(sandwich::vcovCL(
      model,
      cluster = data$participant_key,
      type = type,
      cadjust = TRUE,
      fix = FALSE
    ))
    list(
      type = type,
      value = if (inherits(capture$value, "error")) NULL else capture$value,
      error = if (inherits(capture$value, "error")) {
        conditionMessage(capture$value)
      } else {
        ""
      },
      warnings = capture$warnings
    )
  })
  names(covariance) <- c("HC1", "HC3")
  list(
    model = model,
    fit_error = "",
    fit_warnings = fit_capture$warnings,
    covariance = covariance
  )
}

covariance_diagnostics <- function(covariance) {
  if (is.null(covariance) || !is.matrix(covariance) ||
      !all(is.finite(covariance))) {
    return(tibble::tibble(
      covariance_finite = FALSE,
      covariance_rank = NA_integer_,
      covariance_positive_definite = FALSE,
      covariance_minimum_eigenvalue = NA_real_,
      covariance_maximum_eigenvalue = NA_real_,
      covariance_condition_number = Inf
    ))
  }
  covariance <- (covariance + t(covariance)) / 2
  eigenvalues <- eigen(
    covariance,
    symmetric = TRUE,
    only.values = TRUE
  )$values
  maximum <- max(eigenvalues)
  tolerance <- max(
    maximum * sqrt(.Machine$double.eps),
    .Machine$double.eps
  )
  positive <- eigenvalues > tolerance
  tibble::tibble(
    covariance_finite = TRUE,
    covariance_rank = sum(positive),
    covariance_positive_definite = all(positive),
    covariance_minimum_eigenvalue = min(eigenvalues),
    covariance_maximum_eigenvalue = maximum,
    covariance_condition_number = if (all(positive)) {
      maximum / min(eigenvalues)
    } else {
      Inf
    }
  )
}

cluster_diagnostics <- function(model, data) {
  cluster <- droplevels(data$participant_key)
  score <- sandwich::estfun(model)
  score_by_cluster <- rowsum(score, cluster, reorder = FALSE)
  score_energy <- rowSums(score_by_cluster^2)
  leverage <- stats::hatvalues(model)
  leverage_by_cluster <- rowsum(leverage, cluster, reorder = FALSE)[, 1L]
  tibble::tibble(
    participant_key = rownames(score_by_cluster),
    observations = as.integer(table(cluster)[rownames(score_by_cluster)]),
    score_share = score_energy / sum(score_energy),
    leverage_share = leverage_by_cluster / sum(leverage_by_cluster)
  ) |>
    dplyr::mutate(
      score_rank = rank(-.data$score_share, ties.method = "first"),
      leverage_rank = rank(-.data$leverage_share, ties.method = "first")
    ) |>
    dplyr::arrange(.data$score_rank)
}

sequence_lag <- function(residual, AR_start) {
  sequence_id <- cumsum(AR_start)
  index <- seq_along(residual)
  previous <- index - 1L
  eligible <- previous >= 1L
  eligible[eligible] <- sequence_id[index[eligible]] ==
    sequence_id[previous[eligible]]
  complete <- eligible & is.finite(residual) &
    is.finite(residual[pmax(previous, 1L)])
  tibble::tibble(
    lag1_correlation = if (sum(complete) >= 3L) {
      stats::cor(residual[index[complete]], residual[previous[complete]])
    } else {
      NA_real_
    },
    lag1_pairs = sum(complete)
  )
}

calibration_summary <- function(model, data) {
  fitted <- as.numeric(stats::fitted(model))
  tibble::tibble(
    decile = dplyr::ntile(fitted, 10L),
    observed = data$response_value,
    fitted = fitted
  ) |>
    dplyr::summarise(
      observations = dplyr::n(),
      observed_mean = mean(.data$observed),
      fitted_mean = mean(.data$fitted),
      observed_to_fitted_ratio = .data$observed_mean / .data$fitted_mean,
      .by = .data$decile
    )
}

fit_objects <- list()
fit_rows <- list()
covariance_rows <- list()
cluster_rows <- list()
calibration_rows <- list()

for (placement in names(source_bundle)) {
  data <- source_bundle[[placement]]$candidates[[
    "glm_participant_cluster_robust"
  ]]$data |>
    dplyr::arrange(.data$participant_key, .data$utc_start)
  if (anyDuplicated(data$.model_row_id)) {
    h06_abort("Duplicate H06 pilot row IDs for `%s`", placement)
  }
  if (!all(data$response_value >= 0) || any(!is.finite(data$response_value))) {
    h06_abort("Invalid H06 pilot response for `%s`", placement)
  }

  fit_objects[[placement]] <- list(data = data, routes = list())
  for (route_index in seq_len(nrow(route_registry))) {
    route <- route_registry[route_index, ]
    route_id <- route$route_id
    fitted_route <- fit_route(data, route$working_power)
    if (is.null(fitted_route$model)) {
      fit_rows[[paste(placement, route_id, sep = "__")]] <- tibble::tibble(
        placement = placement,
        route_id = route_id,
        working_power = route$working_power,
        observations = nrow(data),
        participant_days = dplyr::n_distinct(data$participant_day_key),
        participant_clusters = nlevels(droplevels(data$participant_key)),
        sites = nlevels(droplevels(data$site)),
        exact_zero_hours = sum(data$response_value == 0),
        iterations = NA_integer_,
        converged = FALSE,
        design_columns = NA_integer_,
        design_rank = NA_integer_,
        full_rank = FALSE,
        finite_coefficients = FALSE,
        hc3_covariance_finite = FALSE,
        hc3_covariance_positive_definite = FALSE,
        hc3_covariance_condition_number = Inf,
        maximum_hc3_to_hc1_se_ratio = NA_real_,
        maximum_cluster_score_share = NA_real_,
        maximum_cluster_leverage_share = NA_real_,
        pearson_lag1_correlation = NA_real_,
        pearson_lag1_pairs = NA_integer_,
        fitted_minimum = NA_real_,
        fitted_maximum = NA_real_,
        fit_warnings = paste(fitted_route$fit_warnings, collapse = " | "),
        fit_error = fitted_route$fit_error,
        numerical_gate_pass = FALSE,
        inferential_status =
          "bounded_architecture_pilot_not_accepted_inference"
      )
      fit_objects[[placement]]$routes[[route_id]] <- list(
        model = NULL,
        covariance = list(HC1 = NULL, HC3 = NULL),
        working_power = route$working_power,
        fit_error = fitted_route$fit_error
      )
      next
    }
    model <- fitted_route$model
    design <- stats::model.matrix(model)
    clusters <- cluster_diagnostics(model, data)
    lag <- sequence_lag(stats::residuals(model, type = "pearson"), data$AR_start)

    covariance_diagnostic <- list()
    for (covariance_type in names(fitted_route$covariance)) {
      item <- fitted_route$covariance[[covariance_type]]
      diagnostic <- covariance_diagnostics(item$value)
      covariance_diagnostic[[covariance_type]] <- diagnostic
      covariance_rows[[paste(
        placement, route_id, covariance_type, sep = "__"
      )]] <- diagnostic |>
        dplyr::mutate(
          placement = placement,
          route_id = route_id,
          working_power = route$working_power,
          covariance_type = covariance_type,
          covariance_error = item$error,
          covariance_warnings = paste(item$warnings, collapse = " | "),
          .before = 1L
        )
    }

    hc3 <- fitted_route$covariance$HC3$value
    hc1 <- fitted_route$covariance$HC1$value
    if (is.null(hc3) || is.null(hc1)) {
      h06_abort("Missing robust covariance for `%s` / `%s`", placement, route_id)
    }
    hc3_se <- sqrt(diag(hc3))
    hc1_se <- sqrt(diag(hc1))
    fit_rows[[paste(placement, route_id, sep = "__")]] <- tibble::tibble(
      placement = placement,
      route_id = route_id,
      working_power = route$working_power,
      observations = stats::nobs(model),
      participant_days = dplyr::n_distinct(data$participant_day_key),
      participant_clusters = nlevels(droplevels(data$participant_key)),
      sites = nlevels(droplevels(data$site)),
      exact_zero_hours = sum(data$response_value == 0),
      iterations = model$iter,
      converged = isTRUE(model$converged),
      design_columns = ncol(design),
      design_rank = model$rank,
      full_rank = model$rank == ncol(design),
      finite_coefficients = all(is.finite(stats::coef(model))),
      hc3_covariance_finite =
        covariance_diagnostic$HC3$covariance_finite,
      hc3_covariance_positive_definite =
        covariance_diagnostic$HC3$covariance_positive_definite,
      hc3_covariance_condition_number =
        covariance_diagnostic$HC3$covariance_condition_number,
      maximum_hc3_to_hc1_se_ratio = max(hc3_se / hc1_se),
      maximum_cluster_score_share = max(clusters$score_share),
      maximum_cluster_leverage_share = max(clusters$leverage_share),
      pearson_lag1_correlation = lag$lag1_correlation,
      pearson_lag1_pairs = lag$lag1_pairs,
      fitted_minimum = min(stats::fitted(model)),
      fitted_maximum = max(stats::fitted(model)),
      fit_warnings = paste(fitted_route$fit_warnings, collapse = " | "),
      fit_error = "",
      numerical_gate_pass =
        isTRUE(model$converged) &&
        model$rank == ncol(design) &&
        all(is.finite(stats::coef(model))) &&
        covariance_diagnostic$HC3$covariance_finite &&
        covariance_diagnostic$HC3$covariance_positive_definite &&
        covariance_diagnostic$HC3$covariance_condition_number < 1e10 &&
        max(clusters$score_share) <= 0.50 &&
        max(clusters$leverage_share) <= 0.20,
      inferential_status =
        "bounded_architecture_pilot_not_accepted_inference"
    )
    cluster_rows[[paste(placement, route_id, sep = "__")]] <- clusters |>
      dplyr::mutate(
        placement = placement,
        route_id = route_id,
        working_power = route$working_power,
        .before = 1L
      )
    calibration_rows[[paste(placement, route_id, sep = "__")]] <-
      calibration_summary(model, data) |>
      dplyr::mutate(
        placement = placement,
        route_id = route_id,
        working_power = route$working_power,
        .before = 1L
      )
    fit_objects[[placement]]$routes[[route_id]] <- list(
      model = model,
      covariance = list(HC1 = hc1, HC3 = hc3),
      working_power = route$working_power
    )
  }
}

additive_gate_rows <- list()
for (placement in names(fit_objects)) {
  data <- fit_objects[[placement]]$data
  additive <- fit_route(data, 1, formula = additive_formula)
  if (is.null(additive$model)) {
    h06_abort(
      "H06 primary additive marginal route failed for `%s`: %s",
      placement,
      additive$fit_error
    )
  }
  model <- additive$model
  design <- stats::model.matrix(model)
  covariance <- additive$covariance$HC3$value
  covariance_diagnostic <- covariance_diagnostics(covariance)
  clusters <- cluster_diagnostics(model, data)
  lag <- sequence_lag(
    stats::residuals(model, type = "pearson"),
    data$AR_start
  )
  additive_gate_rows[[placement]] <- tibble::tibble(
    placement = placement,
    mean_structure = "primary_additive",
    working_family = "quasi-Poisson log-mean",
    working_power = 1,
    formula = formula_text(additive_formula),
    observations = stats::nobs(model),
    participant_clusters = nlevels(droplevels(data$participant_key)),
    design_columns = ncol(design),
    design_rank = model$rank,
    converged = isTRUE(model$converged),
    full_rank = model$rank == ncol(design),
    hc3_covariance_finite = covariance_diagnostic$covariance_finite,
    hc3_covariance_positive_definite =
      covariance_diagnostic$covariance_positive_definite,
    hc3_covariance_condition_number =
      covariance_diagnostic$covariance_condition_number,
    maximum_cluster_score_share = max(clusters$score_share),
    maximum_cluster_leverage_share = max(clusters$leverage_share),
    pearson_lag1_correlation = lag$lag1_correlation,
    fit_warnings = paste(additive$fit_warnings, collapse = " | "),
    numerical_gate_pass =
      isTRUE(model$converged) &&
      model$rank == ncol(design) &&
      covariance_diagnostic$covariance_finite &&
      covariance_diagnostic$covariance_positive_definite &&
      covariance_diagnostic$covariance_condition_number < 1e10 &&
      max(clusters$score_share) <= 0.50 &&
      max(clusters$leverage_share) <= 0.20,
    inferential_status =
      "bounded_architecture_pilot_not_accepted_inference"
  )
  fit_objects[[placement]]$additive_primary <- list(
    model = model,
    covariance = list(
      HC1 = additive$covariance$HC1$value,
      HC3 = covariance
    ),
    working_power = 1
  )
}
mean_structure_gate <- dplyr::bind_rows(additive_gate_rows)

fit_diagnostics <- dplyr::bind_rows(fit_rows) |>
  dplyr::arrange(
    match(.data$placement, c("glasses", "chest")),
    match(.data$route_id, route_registry$route_id)
  )
covariance_diagnostics_table <- dplyr::bind_rows(covariance_rows)
cluster_influence <- dplyr::bind_rows(cluster_rows)
calibration <- dplyr::bind_rows(calibration_rows)

core_term_patterns <- c(
  "work_free_day",
  "activity_status",
  "previous_sleep_duration_centered_h"
)

power_sensitivity_rows <- list()
for (placement in names(fit_objects)) {
  selected <- fit_objects[[placement]]$routes[[
    "quasi_poisson_p1"
  ]]
  selected_coefficient <- stats::coef(selected$model)
  selected_se <- sqrt(diag(selected$covariance$HC3))
  core_terms <- unique(unlist(lapply(core_term_patterns, function(pattern) {
    grep(pattern, names(selected_coefficient), fixed = TRUE, value = TRUE)
  })))
  for (route_id in names(fit_objects[[placement]]$routes)) {
    candidate <- fit_objects[[placement]]$routes[[route_id]]
    if (is.null(candidate$model)) {
      power_sensitivity_rows[[paste(placement, route_id, sep = "__")]] <-
        tibble::tibble(
          placement = placement,
          comparator_route_id = route_id,
          selected_route_id = "quasi_poisson_p1",
          maximum_abs_all_coefficient_shift_selected_hc3_se = NA_real_,
          maximum_abs_core_and_site_interaction_shift_selected_hc3_se =
            NA_real_,
          inferential_status =
            "architecture_comparator_failed_before_effect_extraction"
        )
      next
    }
    difference <- stats::coef(candidate$model) - selected_coefficient
    standardized <- abs(difference / selected_se)
    power_sensitivity_rows[[paste(placement, route_id, sep = "__")]] <-
      tibble::tibble(
        placement = placement,
        comparator_route_id = route_id,
        selected_route_id = "quasi_poisson_p1",
        maximum_abs_all_coefficient_shift_selected_hc3_se =
          max(standardized),
        maximum_abs_core_and_site_interaction_shift_selected_hc3_se =
          max(standardized[core_terms]),
        inferential_status =
          "architecture_stability_only_no_effect_estimates"
      )
  }
}
power_sensitivity <- dplyr::bind_rows(power_sensitivity_rows)

selected_influence_rows <- list()
selected_influence_summary_rows <- list()
for (placement in names(fit_objects)) {
  data <- fit_objects[[placement]]$data
  selected <- fit_objects[[placement]]$routes[[
    "quasi_poisson_p1"
  ]]
  full_coefficient <- stats::coef(selected$model)
  full_se <- sqrt(diag(selected$covariance$HC3))
  core_terms <- unique(unlist(lapply(core_term_patterns, function(pattern) {
    grep(pattern, names(full_coefficient), fixed = TRUE, value = TRUE)
  })))
  ranking <- cluster_influence |>
    dplyr::filter(
      .data$placement == .env$placement,
      .data$route_id == "quasi_poisson_p1"
    ) |>
    dplyr::slice_min(.data$score_rank, n = 5L, with_ties = FALSE)

  for (participant in ranking$participant_key) {
    reduced_data <- droplevels(data[data$participant_key != participant, ])
    reduced <- fit_route(reduced_data, 1)
    if (is.null(reduced$model)) {
      selected_influence_rows[[paste(placement, participant, sep = "__")]] <-
        tibble::tibble(
          placement = placement,
          omitted_participant = participant,
          refit_converged = FALSE,
          refit_full_rank = FALSE,
          maximum_abs_core_shift_full_hc3_se = NA_real_,
          refit_error = reduced$fit_error
        )
      next
    }
    difference <- stats::coef(reduced$model)[names(full_coefficient)] -
      full_coefficient
    selected_influence_rows[[paste(placement, participant, sep = "__")]] <-
      tibble::tibble(
        placement = placement,
        omitted_participant = participant,
        refit_converged = isTRUE(reduced$model$converged),
        refit_full_rank = reduced$model$rank ==
          ncol(stats::model.matrix(reduced$model)),
        maximum_abs_core_shift_full_hc3_se =
          max(abs(difference[core_terms] / full_se[core_terms])),
        refit_error = ""
      )
  }
  placement_rows <- dplyr::bind_rows(selected_influence_rows) |>
    dplyr::filter(.data$placement == .env$placement)
  selected_influence_summary_rows[[placement]] <- tibble::tibble(
    placement = placement,
    targeted_participant_refits = nrow(placement_rows),
    successful_refits = sum(
      placement_rows$refit_converged & placement_rows$refit_full_rank
    ),
    maximum_abs_core_shift_full_hc3_se = max(
      placement_rows$maximum_abs_core_shift_full_hc3_se,
      na.rm = TRUE
    ),
    influence_interpretation = paste(
      "top five participants by cluster-score share; diagnostic only;",
      "no participant removed from the candidate frame"
    )
  )
}
selected_influence <- dplyr::bind_rows(selected_influence_rows)
selected_influence_summary <- dplyr::bind_rows(
  selected_influence_summary_rows
)

selected_diagnostics <- fit_diagnostics |>
  dplyr::filter(.data$route_id == "quasi_poisson_p1")
selected_calibration <- calibration |>
  dplyr::filter(.data$route_id == "quasi_poisson_p1") |>
  dplyr::summarise(
    fitted_decile_min_observed_to_fitted =
      min(.data$observed_to_fitted_ratio),
    fitted_decile_max_observed_to_fitted =
      max(.data$observed_to_fitted_ratio),
    .by = .data$placement
  )

pilot_summary <- selected_diagnostics |>
  dplyr::select(
    .data$placement,
    .data$observations,
    .data$participant_days,
    .data$participant_clusters,
    .data$sites,
    .data$exact_zero_hours,
    .data$iterations,
    .data$converged,
    .data$full_rank,
    .data$hc3_covariance_positive_definite,
    .data$hc3_covariance_condition_number,
    .data$maximum_hc3_to_hc1_se_ratio,
    .data$maximum_cluster_score_share,
    .data$maximum_cluster_leverage_share,
    .data$pearson_lag1_correlation,
    .data$numerical_gate_pass
  ) |>
  dplyr::left_join(
    selected_calibration,
    by = "placement",
    relationship = "one-to-one"
  ) |>
  dplyr::left_join(
    selected_influence_summary,
    by = "placement",
    relationship = "one-to-one"
  ) |>
  dplyr::left_join(
    mean_structure_gate |>
      dplyr::select(
        .data$placement,
        additive_design_columns = .data$design_columns,
        additive_design_rank = .data$design_rank,
        additive_hc3_covariance_condition_number =
          .data$hc3_covariance_condition_number,
        additive_numerical_gate_pass = .data$numerical_gate_pass
      ),
    by = "placement",
    relationship = "one-to-one"
  ) |>
  dplyr::mutate(
    route_disposition = dplyr::if_else(
      .data$numerical_gate_pass & .data$additive_numerical_gate_pass &
        .data$successful_refits ==
        .data$targeted_participant_refits,
      paste(
        "adequate production-route candidate; residual dependence and",
        "participant influence remain reportable limitations"
      ),
      "architecture gate failed"
    ),
    inferential_status =
      "bounded_architecture_pilot_not_accepted_inference"
  )

stopifnot(
  nrow(route_registry) == 4L,
  nrow(fit_diagnostics) == 8L,
  nrow(mean_structure_gate) == 2L,
  nrow(pilot_summary) == 2L,
  all(fit_diagnostics$converged[
    fit_diagnostics$route_id != "h06_v0_boundary_p1_9"
  ]),
  all(fit_diagnostics$full_rank[
    fit_diagnostics$route_id != "h06_v0_boundary_p1_9"
  ]),
  !fit_diagnostics$converged[
    fit_diagnostics$placement == "glasses" &
      fit_diagnostics$route_id == "h06_v0_boundary_p1_9"
  ],
  all(pilot_summary$numerical_gate_pass),
  all(pilot_summary$additive_numerical_gate_pass),
  all(pilot_summary$successful_refits == 5L),
  !any(route_registry$confirmatory_clock_term),
  all(fit_diagnostics$observations ==
    c(rep(16596L, 4L), rep(18352L, 4L)))
)

write_h06_csv(
  route_registry,
  file.path(
    model_data_root,
    "H06_h03_robust_route_pilot_registry.csv"
  )
)
write_h06_csv(
  fit_diagnostics,
  file.path(
    diagnostic_root,
    "H06_h03_robust_route_pilot_fit_diagnostics.csv"
  )
)
write_h06_csv(
  mean_structure_gate,
  file.path(
    diagnostic_root,
    "H06_h03_robust_route_pilot_mean_structure_gate.csv"
  )
)
write_h06_csv(
  covariance_diagnostics_table,
  file.path(
    diagnostic_root,
    "H06_h03_robust_route_pilot_covariance.csv"
  )
)
write_h06_csv(
  cluster_influence,
  file.path(
    diagnostic_root,
    "H06_h03_robust_route_pilot_cluster_influence.csv"
  )
)
write_h06_csv(
  calibration,
  file.path(
    diagnostic_root,
    "H06_h03_robust_route_pilot_calibration.csv"
  )
)
write_h06_csv(
  power_sensitivity,
  file.path(
    diagnostic_root,
    "H06_h03_robust_route_pilot_power_sensitivity.csv"
  )
)
write_h06_csv(
  selected_influence,
  file.path(
    diagnostic_root,
    "H06_h03_robust_route_pilot_targeted_deletions.csv"
  )
)
write_h06_csv(
  pilot_summary,
  file.path(
    table_root,
    "H06_h03_robust_route_pilot_summary.csv"
  )
)
write_h06_rds(
  list(
    contract_version = "h06_h03_robust_route_pilot_v1",
    formula = fixed_formula,
    registry = route_registry,
    fits = fit_objects,
    inferential_status =
      "bounded_architecture_pilot_not_accepted_inference"
  ),
  file.path(
    model_root,
    "H06_h03_robust_route_pilot_models.rds"
  )
)

message("H06 H03-informed robust-mean architecture pilot complete")
