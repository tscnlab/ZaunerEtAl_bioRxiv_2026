# Pilot revised H06 dependence structures using the collapsed-activity V0 scaffold.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)

source(file.path(root, "scripts/pipeline/paths_io.R"))
source(file.path(root, "scripts/hypotheses/H06/h06_contract.R"))
source(file.path(root, "scripts/hypotheses/H06/h06_modeling.R"))

options(lifecycle_verbosity = "quiet", warn = 1)

if (!identical(as.character(getRversion()), "4.6.1")) {
  h06_abort(
    "H06 V0-scaffold pilots require R 4.6.1; found %s",
    as.character(getRversion())
  )
}

required_packages <- c(
  "dplyr", "tidyr", "tibble", "readr", "digest", "openssl",
  "glmmTMB", "performance", "DHARMa", "mgcv", "sandwich",
  "tweedie", "ggplot2", "scales"
)
missing_packages <- required_packages[!vapply(
  required_packages,
  requireNamespace,
  logical(1),
  quietly = TRUE
)]
if (length(missing_packages) > 0L) {
  h06_abort(
    "H06 V0-scaffold pilots are missing project package(s): %s",
    paste(missing_packages, collapse = ", ")
  )
}

suppressPackageStartupMessages(library(mgcv))

producer <- "scripts/hypotheses/H06/pilot_h06_v0_scaffold_models.R"
paths <- pipeline_paths(root)
roots <- list(
  model_data = file.path(paths$model_data, "H06"),
  models = file.path(paths$models, "H06"),
  diagnostics = file.path(paths$diagnostics, "H06"),
  tables = file.path(paths$tables, "H06"),
  figures = file.path(paths$figures, "H06"),
  source_data = file.path(paths$source_data, "H06")
)
invisible(vapply(
  roots,
  dir.create,
  logical(1),
  recursive = TRUE,
  showWarnings = FALSE
))

write_h06_csv <- function(data, path) {
  write_csv_artifact(data, path, producer = producer)
  invisible(path)
}

write_h06_rds <- function(object, path) {
  write_rds_artifact(object, path, producer = producer)
  invisible(path)
}

fixed_scaffold <- paste(
  "site * work_free_day + site * activity_status +",
  "site * previous_sleep_duration_centered_h"
)

pilot_formulas <- list(
  tmb_v0_participant = stats::as.formula(paste(
    "response_value ~", fixed_scaffold,
    "+ (1 | participant_key)"
  )),
  tmb_participant_day = stats::as.formula(paste(
    "response_value ~", fixed_scaffold,
    "+ (1 | participant_key) + (1 | participant_day_key)"
  )),
  tmb_participant_latent_ar = stats::as.formula(paste(
    "response_value ~", fixed_scaffold,
    "+ (1 | participant_key) +",
    "ar1(hour_index_factor + 0 | hour_sequence_id)"
  )),
  tmb_participant_day_latent_ar = stats::as.formula(paste(
    "response_value ~", fixed_scaffold,
    "+ (1 | participant_key) + (1 | participant_day_key) +",
    "ar1(hour_index_factor + 0 | hour_sequence_id)"
  )),
  bam_participant_day_working_ar = stats::as.formula(paste(
    "response_value ~", fixed_scaffold,
    "+ s(participant_key, bs = 're') +",
    "s(participant_day_key, bs = 're')"
  )),
  glm_participant_cluster_robust = stats::as.formula(paste(
    "response_value ~", fixed_scaffold
  ))
)
environment(pilot_formulas$bam_participant_day_working_ar) <-
  asNamespace("mgcv")

candidate_registry <- tibble::tribble(
  ~candidate_order, ~candidate_id, ~engine, ~response_family,
  ~dependence_strategy, ~inferential_scale, ~pilot_role,
  1L, "tmb_v0_participant", "glmmTMB",
  "Tweedie with log link",
  "Participant random intercept only",
  "Conditional expected hourly melEDI",
  "V0 random-structure benchmark on the repaired exact frame",
  2L, "tmb_participant_day", "glmmTMB",
  "Tweedie with log link",
  "Participant and participant-day random intercepts; no serial term",
  "Conditional expected hourly melEDI",
  "Tests whether participant-day clustering is estimable without latent AR(1)",
  3L, "tmb_participant_latent_ar", "glmmTMB",
  "Tweedie with log link",
  "Participant random intercept plus gap-bounded latent AR(1); no day intercept",
  "Conditional expected hourly melEDI",
  "Tests whether the latent AR(1) is estimable after removing the day intercept",
  4L, "tmb_participant_day_latent_ar", "glmmTMB",
  "Tweedie with log link",
  "Participant and day intercepts plus gap-bounded latent AR(1)",
  "Conditional expected hourly melEDI",
  "Stage 2 failed-structure benchmark refitted with the V0 scaffold notation",
  5L, "bam_participant_day_working_ar", "mgcv::bam",
  "Tweedie with log link",
  paste(
    "Penalized participant and day random effects plus gap-bounded",
    "working-residual AR(1)"
  ),
  "Conditional expected hourly melEDI; GEE-like AR correction",
  "Separates working residual AR(1) from random-effect penalties",
  6L, "glm_participant_cluster_robust", "stats::glm + sandwich::vcovCL",
  "Quasi-Poisson mean-variance with log link",
  "Working independence with participant-cluster CR1 covariance",
  "Population-average expected hourly melEDI",
  "Marginal fallback robust to arbitrary within-participant covariance"
) |>
  dplyr::mutate(
    fixed_effect_scaffold = fixed_scaffold,
    collapsed_activity = TRUE,
    confirmatory_clock_term = FALSE,
    formula = vapply(
      pilot_formulas[candidate_id],
      function(formula) paste(deparse(formula), collapse = " "),
      character(1)
    ),
    diagnostic_simulations = dplyr::if_else(
      candidate_id == "glm_participant_cluster_robust",
      NA_integer_,
      100L
    ),
    inferential_status = "feasibility_pilot_not_accepted_inference"
  )

fit_bam_working_ar <- function(frame, seed) {
  ordered <- frame |>
    dplyr::arrange(hour_sequence_id, hour_sequence_position)
  contrasts(ordered$site) <- stats::contr.sum(nlevels(ordered$site))
  bam_formula <- pilot_formulas$bam_participant_day_working_ar
  environment(bam_formula) <- environment()
  ar_start <- ordered$AR_start

  initial <- h06_capture_fit(mgcv::bam(
    formula = bam_formula,
    data = ordered,
    family = mgcv::tw(link = "log"),
    method = "fREML",
    discrete = TRUE,
    nthreads = 1L,
    gc.level = 1L
  ))
  if (is.null(initial$model)) {
    return(list(
      initial = initial,
      final = initial,
      rho = NA_real_,
      data = ordered
    ))
  }

  residual <- as.numeric(stats::residuals(initial$model, type = "deviance"))
  lag_rows <- tibble::tibble(
    sequence = ordered$hour_sequence_id,
    position = ordered$hour_sequence_position,
    residual = residual
  ) |>
    dplyr::arrange(sequence, position) |>
    dplyr::group_by(sequence) |>
    dplyr::mutate(previous = dplyr::lag(residual)) |>
    dplyr::ungroup() |>
    dplyr::filter(is.finite(residual), is.finite(previous))
  rho <- if (nrow(lag_rows) >= 3L) {
    suppressWarnings(stats::cor(lag_rows$residual, lag_rows$previous))
  } else {
    0
  }
  rho <- max(min(rho, 0.95), -0.95)

  set.seed(seed)
  final <- h06_capture_fit(mgcv::bam(
    formula = bam_formula,
    data = ordered,
    family = mgcv::tw(link = "log"),
    method = "fREML",
    discrete = TRUE,
    rho = rho,
    AR.start = ar_start,
    nthreads = 1L,
    gc.level = 1L
  ))
  list(initial = initial, final = final, rho = rho, data = ordered)
}

fit_cluster_robust_quasi <- function(frame) {
  data <- frame |>
    dplyr::arrange(participant_key, participant_day_key, utc_start)
  fit <- h06_capture_fit(stats::glm(
    formula = pilot_formulas$glm_participant_cluster_robust,
    data = data,
    family = stats::quasipoisson(link = "log"),
    contrasts = list(site = "contr.sum"),
    control = stats::glm.control(maxit = 100L)
  ))
  covariance <- if (is.null(fit$model)) {
    NULL
  } else {
    tryCatch(
      sandwich::vcovCL(
        fit$model,
        cluster = data$participant_key,
        type = "HC1",
        cadjust = TRUE,
        fix = TRUE
      ),
      error = function(error) error
    )
  }
  list(
    fit = fit,
    covariance = covariance,
    clusters = nlevels(data$participant_key),
    data = data
  )
}

pooled_residual_lag <- function(frame, residual) {
  if (length(residual) != nrow(frame)) {
    return(tibble::tibble(
      residual_lag1 = NA_real_,
      residual_pairs = NA_integer_,
      median_sequence_lag1 = NA_real_,
      sequences_with_lag1 = NA_integer_
    ))
  }
  rows <- tibble::tibble(
    sequence = frame$hour_sequence_id,
    position = frame$hour_sequence_position,
    residual = as.numeric(residual)
  ) |>
    dplyr::arrange(sequence, position) |>
    dplyr::group_by(sequence) |>
    dplyr::mutate(previous = dplyr::lag(residual)) |>
    dplyr::ungroup()
  pairs <- rows |>
    dplyr::filter(is.finite(residual), is.finite(previous))
  by_sequence <- rows |>
    dplyr::filter(is.finite(residual)) |>
    dplyr::summarise(
      lag1 = if (dplyr::n() >= 3L) {
        suppressWarnings(stats::cor(residual[-1L], residual[-dplyr::n()]))
      } else {
        NA_real_
      },
      .by = sequence
    ) |>
    dplyr::filter(is.finite(lag1))
  tibble::tibble(
    residual_lag1 = if (nrow(pairs) >= 3L) {
      suppressWarnings(stats::cor(pairs$residual, pairs$previous))
    } else {
      NA_real_
    },
    residual_pairs = nrow(pairs),
    median_sequence_lag1 = if (nrow(by_sequence) > 0L) {
      stats::median(by_sequence$lag1)
    } else {
      NA_real_
    },
    sequences_with_lag1 = nrow(by_sequence)
  )
}

fixed_effect_components <- function(model, engine, covariance = NULL) {
  if (is.null(model)) {
    return(list(coefficients = numeric(), covariance = matrix(numeric(), 0, 0)))
  }
  if (engine == "glmmTMB") {
    return(list(
      coefficients = glmmTMB::fixef(model)$cond,
      covariance = as.matrix(stats::vcov(model)$cond)
    ))
  }
  coefficients <- stats::coef(model)
  if (is.null(covariance)) {
    covariance <- stats::vcov(model)
  }
  list(coefficients = coefficients, covariance = as.matrix(covariance))
}

pilot_effects <- function(
  model,
  engine,
  candidate_id,
  placement,
  covariance = NULL,
  degrees_freedom = Inf
) {
  components <- fixed_effect_components(model, engine, covariance)
  effect_terms <- c(
    free_day_vs_work_day = "work_free_dayFree day",
    active_vs_sedentary = paste0(
      "activity_status",
      "Active (light, moderate, or vigorous exercise)"
    ),
    per_hour_previous_sleep = "previous_sleep_duration_centered_h"
  )
  if (!all(effect_terms %in% names(components$coefficients))) {
    missing <- effect_terms[!effect_terms %in% names(components$coefficients)]
    h06_abort(
      "Pilot `%s` is missing fixed coefficient(s): %s",
      candidate_id,
      paste(missing, collapse = ", ")
    )
  }
  critical <- if (is.finite(degrees_freedom)) {
    stats::qt(0.975, df = degrees_freedom)
  } else {
    stats::qnorm(0.975)
  }
  estimate <- unname(components$coefficients[effect_terms])
  standard_error <- sqrt(diag(components$covariance)[effect_terms])
  low <- estimate - critical * standard_error
  high <- estimate + critical * standard_error
  tibble::tibble(
    placement = placement,
    candidate_id = candidate_id,
    effect_id = names(effect_terms),
    predictor_id = c(
      "work_free_day",
      "activity_status",
      "previous_sleep_duration_centered_h"
    ),
    estimate_link = estimate,
    standard_error = unname(standard_error),
    degrees_freedom = degrees_freedom,
    conf_low_link = low,
    conf_high_link = high,
    estimate_response_ratio = exp(estimate),
    conf_low_response_ratio = exp(low),
    conf_high_response_ratio = exp(high),
    marginalization = "equal_site_via_sum_contrasts",
    inferential_status = "feasibility_pilot_not_accepted_inference"
  )
}

bam_variance_components <- function(model) {
  empty <- tibble::tibble(
    participant_intercept_sd = NA_real_,
    participant_intercept_sd_lower = NA_real_,
    participant_intercept_sd_upper = NA_real_,
    participant_day_intercept_sd = NA_real_,
    participant_day_intercept_sd_lower = NA_real_,
    participant_day_intercept_sd_upper = NA_real_,
    residual_scale = NA_real_
  )
  if (is.null(model)) {
    return(empty)
  }
  output <- tryCatch(
    suppressMessages(suppressWarnings(mgcv::gam.vcomp(model))),
    error = function(error) NULL
  )
  if (is.null(output)) {
    return(empty)
  }
  matrix <- if (is.list(output) && !is.null(output$vc)) {
    as.matrix(output$vc)
  } else {
    as.matrix(output)
  }
  standard_deviation <- matrix[, "std.dev"]
  lower <- matrix[, "lower"]
  upper <- matrix[, "upper"]
  tibble::tibble(
    participant_intercept_sd = unname(
      standard_deviation["s(participant_key)"]
    ),
    participant_intercept_sd_lower = unname(
      lower["s(participant_key)"]
    ),
    participant_intercept_sd_upper = unname(
      upper["s(participant_key)"]
    ),
    participant_day_intercept_sd = unname(
      standard_deviation["s(participant_day_key)"]
    ),
    participant_day_intercept_sd_lower = unname(
      lower["s(participant_day_key)"]
    ),
    participant_day_intercept_sd_upper = unname(
      upper["s(participant_day_key)"]
    ),
    residual_scale = unname(
      standard_deviation["scale"]
    )
  ) |>
    dplyr::mutate(
      dplyr::across(dplyr::everything(), ~ dplyr::coalesce(.x, NA_real_))
    )
}

model_status_row <- function(
  model,
  fit,
  engine,
  candidate_id,
  placement,
  frame,
  covariance = NULL,
  working_ar_rho = NA_real_,
  clusters = NA_integer_
) {
  if (is.null(model)) {
    return(tibble::tibble(
      placement = placement,
      candidate_id = candidate_id,
      engine = engine,
      observations = NA_integer_,
      converged = FALSE,
      positive_definite_hessian = FALSE,
      singular = NA,
      random_component_boundary = NA,
      minimum_fixed_covariance_eigenvalue = NA_real_,
      participant_intercept_sd = NA_real_,
      participant_intercept_sd_lower = NA_real_,
      participant_intercept_sd_upper = NA_real_,
      participant_day_intercept_sd = NA_real_,
      participant_day_intercept_sd_lower = NA_real_,
      participant_day_intercept_sd_upper = NA_real_,
      residual_scale = NA_real_,
      latent_ar_sd = NA_real_,
      latent_ar_rho = NA_real_,
      working_ar_rho = working_ar_rho,
      participant_clusters = clusters,
      elapsed_seconds = fit$elapsed_seconds,
      warnings = paste(fit$warnings, collapse = " | "),
      error = fit$error
    ))
  }

  if (engine == "glmmTMB") {
    status <- h06_model_fit_status(model)
    random <- h06_random_parameter_summary(model)
    return(dplyr::bind_cols(
      tibble::tibble(
        placement = placement,
        candidate_id = candidate_id,
        engine = engine,
        observations = stats::nobs(model)
      ),
      status |>
        dplyr::transmute(
          converged,
          positive_definite_hessian,
          singular,
          random_component_boundary = singular,
          minimum_fixed_covariance_eigenvalue
        ),
      random |>
        dplyr::transmute(
          participant_intercept_sd,
          participant_intercept_sd_lower = NA_real_,
          participant_intercept_sd_upper = NA_real_,
          participant_day_intercept_sd,
          participant_day_intercept_sd_lower = NA_real_,
          participant_day_intercept_sd_upper = NA_real_,
          residual_scale = dispersion,
          latent_ar_sd = ar1_latent_sd,
          latent_ar_rho = ar1_correlation
        ),
      tibble::tibble(
        working_ar_rho = working_ar_rho,
        participant_clusters = clusters,
        elapsed_seconds = fit$elapsed_seconds,
        warnings = paste(fit$warnings, collapse = " | "),
        error = fit$error
      )
    ))
  }

  components <- fixed_effect_components(model, engine, covariance)
  eigenvalue <- tryCatch(
    min(eigen(
      components$covariance,
      symmetric = TRUE,
      only.values = TRUE
    )$values),
    error = function(error) NA_real_
  )
  if (engine == "mgcv::bam") {
    random <- bam_variance_components(model)
    boundary <- any(
      c(
        random$participant_intercept_sd,
        random$participant_day_intercept_sd
      ) / random$residual_scale < 1e-3,
      na.rm = TRUE
    )
    converged <- isTRUE(model$converged)
  } else {
    random <- tibble::tibble(
      participant_intercept_sd = NA_real_,
      participant_intercept_sd_lower = NA_real_,
      participant_intercept_sd_upper = NA_real_,
      participant_day_intercept_sd = NA_real_,
      participant_day_intercept_sd_lower = NA_real_,
      participant_day_intercept_sd_upper = NA_real_,
      residual_scale = NA_real_
    )
    boundary <- FALSE
    converged <- isTRUE(model$converged) && is.finite(eigenvalue)
  }
  dplyr::bind_cols(
    tibble::tibble(
      placement = placement,
      candidate_id = candidate_id,
      engine = engine,
      observations = stats::nobs(model),
      converged = converged,
      positive_definite_hessian = NA,
      singular = NA,
      random_component_boundary = boundary,
      minimum_fixed_covariance_eigenvalue = eigenvalue
    ),
    random,
    tibble::tibble(
      latent_ar_sd = NA_real_,
      latent_ar_rho = NA_real_,
      working_ar_rho = working_ar_rho,
      participant_clusters = clusters,
      elapsed_seconds = fit$elapsed_seconds,
      warnings = paste(fit$warnings, collapse = " | "),
      error = fit$error
    )
  )
}

bam_conditional_distribution_diagnostics <- function(
  model,
  frame,
  run_id,
  seed,
  simulations = 100L
) {
  fitted_mean <- as.numeric(stats::fitted(model))
  dispersion <- as.numeric(summary(model)$scale)
  power <- as.numeric(model$family$getTheta(trans = TRUE))
  if (
    length(fitted_mean) != nrow(frame) ||
      !is.finite(dispersion) || dispersion <= 0 ||
      !is.finite(power) || power <= 1 || power >= 2
  ) {
    return(tibble::tibble(
      run_id = run_id,
      simulations = simulations,
      uniformity_p = NA_real_,
      dispersion_p = NA_real_,
      zero_inflation_p = NA_real_,
      outlier_p = NA_real_,
      simulated_zero_fraction = NA_real_,
      error = "Invalid Tweedie simulation parameters"
    ))
  }

  set.seed(seed)
  simulated <- tryCatch(
    vapply(seq_len(simulations), function(index) {
      tweedie::rtweedie(
        n = nrow(frame),
        mu = fitted_mean,
        phi = dispersion,
        power = power
      )
    }, numeric(nrow(frame))),
    error = function(error) error
  )
  if (inherits(simulated, "error")) {
    return(tibble::tibble(
      run_id = run_id,
      simulations = simulations,
      uniformity_p = NA_real_,
      dispersion_p = NA_real_,
      zero_inflation_p = NA_real_,
      outlier_p = NA_real_,
      simulated_zero_fraction = NA_real_,
      error = conditionMessage(simulated)
    ))
  }
  residual <- DHARMa::createDHARMa(
    simulatedResponse = simulated,
    observedResponse = frame$response_value,
    fittedPredictedResponse = fitted_mean,
    integerResponse = FALSE,
    seed = seed,
    method = "PIT"
  )
  p_value <- function(result) {
    tryCatch(as.numeric(result$p.value), error = function(error) NA_real_)
  }
  tibble::tibble(
    run_id = run_id,
    simulations = simulations,
    uniformity_p = p_value(DHARMa::testUniformity(residual, plot = FALSE)),
    dispersion_p = p_value(DHARMa::testDispersion(residual, plot = FALSE)),
    zero_inflation_p = p_value(DHARMa::testZeroInflation(residual)),
    outlier_p = p_value(DHARMa::testOutliers(residual, plot = FALSE)),
    simulated_zero_fraction = mean(simulated == 0),
    error = NA_character_
  )
}

placement_paths <- c(
  glasses = file.path(
    roots$model_data,
    "main__glasses__all_available__frame.rds"
  ),
  chest = file.path(
    roots$model_data,
    "main__chest__all_available__frame.rds"
  )
)

all_models <- list()
sample_rows <- list()
status_rows <- list()
temporal_rows <- list()
dharma_rows <- list()
effect_rows <- list()
simulation_runtime_rows <- list()

for (placement in names(placement_paths)) {
  frame <- readRDS(placement_paths[[placement]])
  expected_rows <- if (placement == "glasses") 16596L else 18352L
  expected_days <- if (placement == "glasses") 715L else 789L
  expected_participants <- if (placement == "glasses") 137L else 149L
  stopifnot(
    nrow(frame) == expected_rows,
    nlevels(frame$participant_day_key) == expected_days,
    nlevels(frame$participant_key) == expected_participants,
    identical(levels(frame$activity_status), h06_activity_levels()),
    !anyNA(frame$response_value),
    all(frame$response_value >= 0)
  )

  fixed_matrix <- stats::model.matrix(
    stats::as.formula(paste("~", fixed_scaffold)),
    data = frame,
    contrasts.arg = list(site = "contr.sum")
  )
  stopifnot(qr(fixed_matrix)$rank == ncol(fixed_matrix))

  hours_per_day <- frame |>
    dplyr::count(participant_day_key, name = "supported_hours")
  participants_per_site <- frame |>
    dplyr::distinct(site, participant_key) |>
    dplyr::count(site, name = "participants")
  sample_rows[[placement]] <- tibble::tibble(
    placement = placement,
    one_hour_observations = nrow(frame),
    participant_days = nlevels(frame$participant_day_key),
    participants = nlevels(frame$participant_key),
    sites = nlevels(frame$site),
    median_supported_hours_per_day = stats::median(hours_per_day$supported_hours),
    minimum_participants_per_site = min(participants_per_site$participants),
    fixed_design_columns = ncol(fixed_matrix),
    fixed_design_rank = qr(fixed_matrix)$rank,
    fixed_design_full_rank = TRUE,
    frame_sha256 = h06_model_frame_hash(frame)
  )

  tmb_ids <- names(pilot_formulas)[1:4]
  tmb_candidates <- stats::setNames(lapply(tmb_ids, function(candidate_id) {
    h06_fit_model(frame, pilot_formulas[[candidate_id]])
  }), tmb_ids)

  bam <- fit_bam_working_ar(
    frame,
    seed = if (placement == "glasses") 66101L else 66102L
  )
  quasi <- fit_cluster_robust_quasi(frame)

  candidates <- lapply(tmb_ids, function(candidate_id) {
    list(
      candidate_id = candidate_id,
      engine = "glmmTMB",
      fit = tmb_candidates[[candidate_id]],
      model = tmb_candidates[[candidate_id]]$model,
      data = frame,
      covariance = NULL,
      degrees_freedom = Inf,
      working_ar_rho = NA_real_,
      clusters = nlevels(frame$participant_key)
    )
  })
  names(candidates) <- tmb_ids
  candidates$bam_participant_day_working_ar <- list(
    candidate_id = "bam_participant_day_working_ar",
    engine = "mgcv::bam",
    fit = bam$final,
    model = bam$final$model,
    data = bam$data,
    covariance = NULL,
    degrees_freedom = Inf,
    working_ar_rho = bam$rho,
    clusters = nlevels(frame$participant_key),
    initial_fit = bam$initial
  )
  quasi_covariance <- if (inherits(quasi$covariance, "error")) {
    NULL
  } else {
    quasi$covariance
  }
  if (inherits(quasi$covariance, "error")) {
    quasi$fit$error <- conditionMessage(quasi$covariance)
  }
  candidates$glm_participant_cluster_robust <- list(
    candidate_id = "glm_participant_cluster_robust",
    engine = "stats::glm + sandwich::vcovCL",
    fit = quasi$fit,
    model = if (is.null(quasi_covariance)) NULL else quasi$fit$model,
    data = quasi$data,
    covariance = quasi_covariance,
    degrees_freedom = quasi$clusters - 1,
    working_ar_rho = NA_real_,
    clusters = quasi$clusters
  )

  all_models[[placement]] <- list(
    frame_row_ids = frame$.model_row_id,
    frame_sha256 = h06_model_frame_hash(frame),
    candidates = candidates,
    contract = list(
      fixed_scaffold = fixed_scaffold,
      collapsed_activity = h06_activity_levels(),
      simulations = 100L,
      inferential_status = "feasibility_pilot_not_accepted_inference"
    )
  )

  for (candidate_id in names(candidates)) {
    candidate <- candidates[[candidate_id]]
    model <- candidate$model
    status_rows[[paste(placement, candidate_id, sep = "__")]] <-
      model_status_row(
        model = model,
        fit = candidate$fit,
        engine = candidate$engine,
        candidate_id = candidate_id,
        placement = placement,
        frame = candidate$data,
        covariance = candidate$covariance,
        working_ar_rho = candidate$working_ar_rho,
        clusters = candidate$clusters
      )

    if (!is.null(model)) {
      effect_rows[[paste(placement, candidate_id, sep = "__")]] <-
        pilot_effects(
          model = model,
          engine = candidate$engine,
          candidate_id = candidate_id,
          placement = placement,
          covariance = candidate$covariance,
          degrees_freedom = candidate$degrees_freedom
        )

      pearson <- tryCatch(
        as.numeric(stats::residuals(model, type = "pearson")),
        error = function(error) as.numeric(stats::residuals(model))
      )
      pearson_lag <- pooled_residual_lag(candidate$data, pearson) |>
        dplyr::rename_with(~ paste0("pearson_", .x))
      standardized <- if (
        candidate$engine == "mgcv::bam" &&
          !is.null(model$std.rsd)
      ) {
        as.numeric(model$std.rsd)
      } else {
        rep(NA_real_, nrow(candidate$data))
      }
      standardized_lag <- pooled_residual_lag(
        candidate$data,
        standardized
      ) |>
        dplyr::rename_with(~ paste0("standardized_", .x))
      temporal_rows[[paste(placement, candidate_id, sep = "__")]] <-
        dplyr::bind_cols(
          tibble::tibble(
            placement = placement,
            candidate_id = candidate_id,
            residual_mean = mean(pearson, na.rm = TRUE),
            residual_sd = stats::sd(pearson, na.rm = TRUE),
            observed_zero_fraction = mean(candidate$data$response_value == 0)
          ),
          pearson_lag,
          standardized_lag
        )

      if (candidate$engine != "stats::glm + sandwich::vcovCL") {
        seed <- 66200L +
          match(placement, names(placement_paths)) * 100L +
          match(candidate_id, names(candidates))
        elapsed <- system.time({
          diagnostic <- if (candidate$engine == "mgcv::bam") {
            bam_conditional_distribution_diagnostics(
              model,
              frame = candidate$data,
              run_id = paste(placement, candidate_id, sep = "__"),
              seed = seed,
              simulations = 100L
            )
          } else {
            h06_dharma_diagnostics(
              model,
              run_id = paste(placement, candidate_id, sep = "__"),
              seed = seed,
              simulations = 100L
            )
          }
        })[["elapsed"]]
        dharma_rows[[paste(placement, candidate_id, sep = "__")]] <-
          diagnostic |>
          tidyr::separate_wider_delim(
            run_id,
            delim = "__",
            names = c("placement", "candidate_id")
          ) |>
          dplyr::mutate(
            observed_zero_fraction = mean(candidate$data$response_value == 0),
            diagnostic_elapsed_seconds = as.numeric(elapsed)
          )
        simulation_runtime_rows[[paste(placement, candidate_id, sep = "__")]] <-
          tibble::tibble(
            placement = placement,
            candidate_id = candidate_id,
            simulations = 100L,
            elapsed_seconds = as.numeric(elapsed),
            projected_1000_simulation_seconds = as.numeric(elapsed) * 10,
            production_status = "not_run_not_authorized"
          )
      }
    }
  }
}

sample_summary <- dplyr::bind_rows(sample_rows)
model_status <- dplyr::bind_rows(status_rows) |>
  dplyr::left_join(
    candidate_registry |>
      dplyr::select(candidate_order, candidate_id, dependence_strategy),
    by = "candidate_id",
    relationship = "many-to-one"
  ) |>
  dplyr::arrange(placement, candidate_order)
temporal_diagnostics <- dplyr::bind_rows(temporal_rows) |>
  dplyr::left_join(
    candidate_registry |>
      dplyr::select(candidate_order, candidate_id),
    by = "candidate_id",
    relationship = "many-to-one"
  ) |>
  dplyr::arrange(placement, candidate_order)
dharma_diagnostics <- dplyr::bind_rows(dharma_rows) |>
  dplyr::left_join(
    candidate_registry |>
      dplyr::select(candidate_order, candidate_id),
    by = "candidate_id",
    relationship = "many-to-one"
  ) |>
  dplyr::arrange(placement, candidate_order)
effects <- dplyr::bind_rows(effect_rows) |>
  dplyr::left_join(
    candidate_registry |>
      dplyr::select(candidate_order, candidate_id, engine),
    by = "candidate_id",
    relationship = "many-to-one"
  ) |>
  dplyr::arrange(placement, effect_id, candidate_order)
simulation_runtime <- dplyr::bind_rows(simulation_runtime_rows) |>
  dplyr::left_join(
    candidate_registry |>
      dplyr::select(candidate_order, candidate_id),
    by = "candidate_id",
    relationship = "many-to-one"
  ) |>
  dplyr::arrange(placement, candidate_order)

assessment <- model_status |>
  dplyr::left_join(
    temporal_diagnostics |>
      dplyr::select(
        placement,
        candidate_id,
        pearson_residual_lag1,
        standardized_residual_lag1
      ),
    by = c("placement", "candidate_id"),
    relationship = "one-to-one"
  ) |>
  dplyr::left_join(
    dharma_diagnostics |>
      dplyr::select(
        placement,
        candidate_id,
        uniformity_p,
        dispersion_p,
        zero_inflation_p,
        outlier_p,
        diagnostic_error = error
      ),
    by = c("placement", "candidate_id"),
    relationship = "one-to-one"
  ) |>
  dplyr::mutate(
    structural_screen = converged &
      (is.na(positive_definite_hessian) | positive_definite_hessian) &
      (is.na(singular) | !singular) &
      !random_component_boundary &
      is.finite(minimum_fixed_covariance_eigenvalue) &
      minimum_fixed_covariance_eigenvalue > 0,
    residual_lag_for_screen = dplyr::coalesce(
      standardized_residual_lag1,
      pearson_residual_lag1
    ),
    temporal_screen = dplyr::case_when(
      candidate_id == "glm_participant_cluster_robust" ~ NA,
      TRUE ~ abs(residual_lag_for_screen) <= 0.10
    ),
    distribution_screen = dplyr::case_when(
      candidate_id == "glm_participant_cluster_robust" ~ NA,
      is.na(uniformity_p) | is.na(dispersion_p) |
        is.na(zero_inflation_p) | is.na(outlier_p) ~ FALSE,
      TRUE ~ uniformity_p >= 0.01 &
        dispersion_p >= 0.01 &
        zero_inflation_p >= 0.01 &
        outlier_p >= 0.01
    ),
    automated_pilot_screen = dplyr::case_when(
      candidate_id == "glm_participant_cluster_robust" & structural_screen ~
        "structurally_estimable_marginal_candidate",
      structural_screen & temporal_screen & distribution_screen ~
        "passes_bounded_feasibility_screen",
      !structural_screen ~ "fails_structural_screen",
      !temporal_screen ~ "fails_temporal_screen",
      !distribution_screen ~ "fails_distributional_screen",
      TRUE ~ "requires_manual_review"
    ),
    inferential_status = "feasibility_pilot_not_accepted_inference"
  ) |>
  dplyr::select(
    placement,
    candidate_order,
    candidate_id,
    structural_screen,
    residual_lag_for_screen,
    temporal_screen,
    distribution_screen,
    automated_pilot_screen,
    inferential_status
  )

write_h06_csv(
  candidate_registry,
  file.path(roots$model_data, "H06_v0_scaffold_pilot_registry.csv")
)
write_h06_csv(
  sample_summary,
  file.path(roots$model_data, "H06_v0_scaffold_pilot_samples.csv")
)
write_h06_rds(
  all_models,
  file.path(roots$models, "H06_v0_scaffold_pilot_models.rds")
)
write_h06_csv(
  model_status,
  file.path(roots$diagnostics, "H06_v0_scaffold_pilot_fit_status.csv")
)
write_h06_csv(
  temporal_diagnostics,
  file.path(roots$diagnostics, "H06_v0_scaffold_pilot_temporal.csv")
)
write_h06_csv(
  dharma_diagnostics,
  file.path(roots$diagnostics, "H06_v0_scaffold_pilot_DHARMa_100.csv")
)
write_h06_csv(
  simulation_runtime,
  file.path(roots$diagnostics, "H06_v0_scaffold_pilot_simulation_runtime.csv")
)
write_h06_csv(
  effects,
  file.path(roots$tables, "H06_v0_scaffold_pilot_effects.csv")
)
write_h06_csv(
  assessment,
  file.path(roots$tables, "H06_v0_scaffold_pilot_assessment.csv")
)
source(file.path(
  root,
  "scripts/hypotheses/H06/build_h06_v0_scaffold_pilot_reader_artifacts.R"
))

message("H06 V0-scaffold model pilots complete")
