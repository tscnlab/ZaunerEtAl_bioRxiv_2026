# Summarize H01 models and write their reusable numerical outputs.

h01_write_csv <- function(data, path) {
  write_csv_artifact(data, path, producer = producer)
  invisible(path)
}

h01_write_rds <- function(object, path) {
  write_rds_artifact(object, path, producer = producer)
  invisible(path)
}

h01_add_identity <- function(data, run, spec) {
  if (nrow(data) == 0L) {
    return(data)
  }
  identity <- tibble::tibble(
    run_id = run$run_id,
    data_scenario_id = run$data_scenario_id,
    placement = run$placement,
    sample_scenario = run$sample_scenario,
    analytical_role = run$analytical_role,
    metric_order = spec$metric_order,
    metric_id = spec$metric_id,
    analysis_unit = spec$analysis_unit,
    response_family = spec$response_family,
    response_transform = spec$response_transform
  )
  dplyr::bind_cols(identity[rep(1L, nrow(data)), , drop = FALSE], data)
}

h01_model_specification_rows <- function(bundle, run, spec) {
  rows <- list()
  index <- 1L
  for (stage_name in c("comparison", "final")) {
    for (model_name in names(bundle[[stage_name]])) {
      fit <- bundle[[stage_name]][[model_name]]
      model <- fit$model
      status <- h01_model_fit_status(model)
      rows[[index]] <- h01_add_identity(
        tibble::tibble(
          model_name = model_name,
          estimation_stage = stage_name,
          formula = if (is.null(model)) {
            paste(deparse(bundle$formulas[[model_name]]), collapse = " ")
          } else {
            paste(deparse(stats::formula(model)), collapse = " ")
          },
          engine = if (spec$analysis_unit == "participant") {
            "lm"
          } else if (spec$response_family == "gaussian") {
            "lmer"
          } else {
            "glmmTMB"
          },
          estimation_method = if (
            spec$analysis_unit == "participant"
          ) {
            "maximum_likelihood"
          } else if (
            spec$response_family == "gaussian" &&
              stage_name == "final"
          ) {
            "restricted_maximum_likelihood"
          } else {
            "maximum_likelihood"
          },
          family = if (spec$response_family == "tweedie_log") {
            "Tweedie"
          } else {
            "Gaussian"
          },
          link = if (spec$response_family == "tweedie_log") {
            "log"
          } else {
            "identity_after_declared_transformation"
          },
          observations = if (is.null(model)) {
            NA_integer_
          } else {
            stats::nobs(model)
          },
          log_likelihood = if (is.null(model)) {
            NA_real_
          } else {
            as.numeric(stats::logLik(model))
          },
          aic = if (is.null(model)) NA_real_ else stats::AIC(model),
          converged = status$converged,
          positive_definite_hessian = status$positive_definite_hessian,
          singular = status$singular,
          max_gradient = status$max_gradient,
          warnings = paste(fit$warnings, collapse = " | "),
          error = fit$error,
          status = if (is.null(model)) "NON_ESTIMABLE" else "FITTED"
        ),
        run,
        spec
      )
      index <- index + 1L
    }
  }
  dplyr::bind_rows(rows)
}

h01_empty_metric_rows <- function(run, spec) {
  families <- h01_family_registry()
  tests <- h01_add_identity(
    dplyr::transmute(
      families,
      comparison_id = comparison,
      statistic = NA_real_,
      df = NA_real_,
      p_raw = NA_real_,
      log_lik_reduced = NA_real_,
      log_lik_full = NA_real_,
      n_obs_reduced = NA_integer_,
      n_obs_full = NA_integer_,
      comparison_status = "NON_ESTIMABLE",
      family_order,
      family_id,
      family_label,
      family_n,
      adjustment_method
    ),
    run,
    spec
  )
  diagnostics <- h01_add_identity(
    tibble::tibble(
      converged = FALSE,
      positive_definite_hessian = FALSE,
      singular = NA,
      max_gradient = NA_real_,
      diagnostic_status = "NON_ESTIMABLE",
      fit_error = "Prepared scenario is unavailable for this metric"
    ),
    run,
    spec
  )
  samples <- h01_add_identity(
    tibble::tibble(
      participants = 0L,
      participant_days = 0L,
      observations = 0L,
      sites = 0L,
      derivation_support_hours = NA_real_,
      derivation_support_status = "not_applicable",
      derivation_support_unavailability_reason =
        "prepared_scenario_unavailable",
      sample_status = "NON_ESTIMABLE"
    ),
    run,
    spec
  )
  list(tests = tests, diagnostics = diagnostics, samples = samples)
}

h01_adjust_primary_families <- function(tests) {
  tests <- tests |>
    dplyr::mutate(
      family_instance_id = paste(run_id, family_id, sep = "::")
    )
  tests <- adjust_result_families(
    tests,
    family_col = "family_instance_id",
    p_col = "p_raw",
    family_n_col = "family_n",
    output_col = "p_adjusted",
    method = "BH"
  )
  tests |>
    dplyr::group_by(family_instance_id) |>
    dplyr::mutate(
      family_rank = ifelse(
        is.na(p_raw),
        NA_integer_,
        rank(p_raw, ties.method = "min", na.last = "keep")
      ),
      family_observed_tests = sum(!is.na(p_raw))
    ) |>
    dplyr::ungroup()
}

h01_fit_registered_scope <- function(frame, spec, primary_tests) {
  if (spec$preregistered_photoperiod) {
    output <- primary_tests |>
      dplyr::mutate(scope_change = "none_duration_metric")
  } else {
    formulas <- h01_formula_set(
      spec$analysis_unit,
      preregistered_scope = TRUE
    )
    bundle <- h01_fit_metric_models(frame, spec, formulas = formulas)
    output <- h01_model_tests(bundle) |>
      dplyr::filter(
        comparison_id != "site_full_vs_no_photoperiod"
      ) |>
      dplyr::mutate(
        scope_change = "photoperiod_omitted_for_non_duration_metric"
      )
  }
  output
}
