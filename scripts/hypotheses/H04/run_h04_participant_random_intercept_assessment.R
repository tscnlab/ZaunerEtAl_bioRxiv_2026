#!/usr/bin/env Rscript

# Quantify stable participant-level heterogeneity in the accepted H04
# activity-by-site frames using bounded auxiliary Tweedie random-intercept
# models. The Nakagawa fixed-predictor variance is calculated with the exact
# 1/k activity weights so every retained participant-hour contributes one unit.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
project_library <- file.path(
  root,
  "renv/library/macos/R-4.6/aarch64-apple-darwin23"
)
.libPaths(c(project_library, .libPaths()))

source(file.path(root, "scripts/pipeline/paths_io.R"))
source(file.path(root, "scripts/hypotheses/H04/h04_contract.R"))
source(file.path(root, "scripts/hypotheses/H04/h04_stage1_support.R"))
source(file.path(root, "scripts/hypotheses/H04/h04_data.R"))
source(file.path(root, "scripts/hypotheses/H04/h04_modeling.R"))

if (!identical(as.character(getRversion()), "4.6.1")) {
  h04_abort(
    "H04 participant random-intercept assessment requires R 4.6.1; found %s",
    as.character(getRversion())
  )
}

required_packages <- c(
  "dplyr", "tibble", "readr", "openssl", "glmmTMB", "lme4",
  "performance", "insight"
)
missing_packages <- required_packages[!vapply(
  required_packages,
  requireNamespace,
  logical(1L),
  quietly = TRUE
)]
if (length(missing_packages) > 0L) {
  h04_abort(
    "Missing synchronized project package(s): %s",
    paste(missing_packages, collapse = ", ")
  )
}

producer <- paste0(
  "scripts/hypotheses/H04/",
  "run_h04_participant_random_intercept_assessment.R"
)
working_power <- h04_specification()$working_tweedie_power

roots <- list(
  models = file.path(root, "artifacts/07_models/H04"),
  diagnostics = file.path(root, "artifacts/08_diagnostics/H04"),
  tables = file.path(root, "artifacts/09_tables/H04"),
  manifests = file.path(root, "artifacts/12_manifests/H04")
)
invisible(lapply(
  roots,
  dir.create,
  recursive = TRUE,
  showWarnings = FALSE
))

accepted_model_path <- file.path(
  roots$models,
  "H04_heterogeneity_model_objects.rds"
)
expected_input_sha256 <-
  "ccc6122cc0e7b41b9a8769bc3406629c398d71a3a30b3ff84587ee3323e5d05c"
if (!file.exists(accepted_model_path)) {
  h04_abort("Missing accepted H04 heterogeneity model archive")
}
observed_input_sha256 <- artifact_sha256(accepted_model_path)
if (!identical(observed_input_sha256, expected_input_sha256)) {
  h04_abort(
    "The accepted H04 heterogeneity archive drifted: expected %s, observed %s",
    expected_input_sha256,
    observed_input_sha256
  )
}

model_formulas <- list(
  intercept = stats::as.formula(
    "geo_medi_1h ~ 1 + (1 | participant)"
  ),
  site = stats::as.formula(
    "geo_medi_1h ~ site + (1 | participant)"
  ),
  activity = stats::as.formula(
    "geo_medi_1h ~ activity_named + (1 | participant)"
  ),
  additive = stats::as.formula(
    "geo_medi_1h ~ site + activity_named + (1 | participant)"
  ),
  full = stats::as.formula(
    "geo_medi_1h ~ site * activity_named + (1 | participant)"
  )
)
model_formulas <- lapply(model_formulas, function(formula) {
  environment(formula) <- environment()
  formula
})

h04_fractional_frequency_variance <- function(value, weight) {
  if (
    length(value) != length(weight) ||
      any(!is.finite(value)) ||
      any(!is.finite(weight)) ||
      any(weight <= 0) ||
      sum(weight) <= 1
  ) {
    h04_abort("Invalid values supplied to weighted fixed-predictor variance")
  }
  centre <- stats::weighted.mean(value, weight)
  sum(weight * (value - centre)^2) / (sum(weight) - 1)
}

h04_mixed_r_squared <- function(fit, null_fit, weight) {
  variance <- insight::get_variance(
    fit,
    null_model = null_fit,
    approximation = "lognormal"
  )
  required <- c("var.fixed", "var.random", "var.residual")
  if (!all(required %in% names(variance))) {
    h04_abort("Could not recover the mixed-model variance components")
  }

  fixed_matrix <- lme4::getME(fit, "X")
  fixed_coefficients <- unname(glmmTMB::fixef(fit)$cond)
  if (ncol(fixed_matrix) != length(fixed_coefficients)) {
    h04_abort("Fixed design and coefficient dimensions do not agree")
  }
  fixed_predictor <- as.vector(fixed_matrix %*% fixed_coefficients)
  fixed_weighted <- h04_fractional_frequency_variance(
    fixed_predictor,
    weight
  )
  random <- as.numeric(variance$var.random)
  residual <- as.numeric(variance$var.residual)
  total <- fixed_weighted + random + residual

  conventional <- performance::r2_nakagawa(
    fit,
    null_model = null_fit,
    approximation = "lognormal"
  )
  if (
    any(!is.finite(c(fixed_weighted, random, residual, total))) ||
      total <= 0 ||
      is.null(conventional$R2_marginal) ||
      is.null(conventional$R2_conditional)
  ) {
    h04_abort("The mixed-model R-squared calculation returned invalid values")
  }

  list(
    marginal = fixed_weighted / total,
    conditional = (fixed_weighted + random) / total,
    fixed_weighted = fixed_weighted,
    random = random,
    residual = residual,
    conventional_marginal = as.numeric(conventional$R2_marginal[[1L]]),
    conventional_conditional = as.numeric(
      conventional$R2_conditional[[1L]]
    ),
    conventional_fixed = as.numeric(variance$var.fixed)
  )
}

h04_fit_auxiliary_model <- function(model_id, formula, data) {
  message("Fitting auxiliary H04 model: ", model_id)
  elapsed <- system.time({
    captured <- h04_capture_warnings(glmmTMB::glmmTMB(
      formula = formula,
      data = data,
      family = glmmTMB::tweedie(link = "log"),
      weights = analysis_weight,
      REML = FALSE,
      start = list(psi = stats::qlogis(working_power - 1)),
      map = list(psi = factor(NA))
    ))
  })
  list(
    model_id = model_id,
    formula = formula,
    fit = captured$value,
    warnings = captured$warnings,
    elapsed_fit_seconds = unname(elapsed[["elapsed"]])
  )
}

h04_boundary_lag_correlation <- function(residual, ar_start, lag = 1L) {
  sequence_id <- cumsum(ar_start)
  index <- seq_along(residual)
  earlier <- index - lag
  eligible <- earlier >= 1L
  eligible[eligible] <- sequence_id[index[eligible]] ==
    sequence_id[earlier[eligible]]
  complete <- eligible &
    is.finite(residual) &
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

h04_hour_level_diagnostics <- function(fit, data) {
  pearson <- stats::residuals(fit, type = "pearson")
  fitted_mean <- stats::fitted(fit)
  dispersion <- stats::sigma(fit)
  fitted_power <- unname(glmmTMB::family_params(fit)[[1L]])
  lambda <- fitted_mean^(2 - fitted_power) /
    (dispersion * (2 - fitted_power))
  row_zero_probability <- exp(-lambda)

  hour_values <- data |>
    dplyr::mutate(
      .pearson = pearson,
      .fitted = fitted_mean,
      .zero_probability = row_zero_probability
    ) |>
    dplyr::group_by(.data$analysis_hour_id) |>
    dplyr::summarise(
      pearson = stats::weighted.mean(.data$.pearson, .data$analysis_weight),
      fitted = stats::weighted.mean(.data$.fitted, .data$analysis_weight),
      zero_probability = stats::weighted.mean(
        .data$.zero_probability,
        .data$analysis_weight
      ),
      observed_zero = dplyr::first(.data$geo_medi_1h) == 0,
      weight_sum = sum(.data$analysis_weight),
      .groups = "drop"
    )
  sequence <- h04_add_unique_hour_sequences(data) |>
    dplyr::select("analysis_hour_id", "AR_start") |>
    dplyr::left_join(
      hour_values,
      by = "analysis_hour_id",
      relationship = "one-to-one"
    )
  if (
    any(!is.finite(sequence$pearson)) ||
      any(!is.finite(sequence$fitted)) ||
      any(!is.finite(sequence$zero_probability)) ||
      any(abs(sequence$weight_sum - 1) > 1e-10)
  ) {
    h04_abort("Hour-level mixed-model diagnostics failed their weight gate")
  }
  lag_one <- h04_boundary_lag_correlation(
    sequence$pearson,
    sequence$AR_start,
    lag = 1L
  )
  list(
    pearson = sequence$pearson,
    fitted = sequence$fitted,
    zero_probability = sequence$zero_probability,
    observed_zero = sequence$observed_zero,
    lag_one = lag_one,
    fitted_power = fitted_power,
    dispersion = dispersion
  )
}

message("Reading the accepted frozen H04 heterogeneity frames")
accepted <- readRDS(accepted_model_path)
placement_contract <- list(
  near_eye = list(
    label = "Near-eye",
    long_rows = 16875L,
    unique_hours = 16135L,
    participants = 126L
  ),
  chest = list(
    label = "Chest",
    long_rows = 20440L,
    unique_hours = 19497L,
    participants = 150L
  )
)

assessment <- lapply(names(placement_contract), function(placement_id) {
  contract <- placement_contract[[placement_id]]
  selected <- accepted[[placement_id]]$selected
  if (
    is.null(selected$bundle$data) ||
      !identical(selected$gate$architecture[[1L]], "five_named")
  ) {
    h04_abort("Missing accepted five-category heterogeneity frame for %s", contract$label)
  }
  data <- selected$bundle$data |>
    dplyr::arrange(
      .data$site,
      .data$participant,
      .data$participant_day,
      .data$interval_start_utc,
      .data$activity_named
    ) |>
    h04_prepare_fit_factors(model_formulas$full)

  hour_weights <- data |>
    dplyr::group_by(.data$analysis_hour_id) |>
    dplyr::summarise(
      rows = dplyr::n(),
      weight_sum = sum(.data$analysis_weight),
      exact_fraction = all(abs(.data$analysis_weight - 1 / dplyr::n()) < 1e-12),
      .groups = "drop"
    )
  if (
    nrow(data) != contract$long_rows ||
      dplyr::n_distinct(data$analysis_hour_id) != contract$unique_hours ||
      nlevels(data$participant) != contract$participants ||
      nlevels(data$activity_named) != 5L ||
      anyDuplicated(data[c("analysis_hour_id", "activity_named")]) ||
      any(abs(hour_weights$weight_sum - 1) > 1e-12) ||
      !all(hour_weights$exact_fraction) ||
      abs(sum(data$analysis_weight) - contract$unique_hours) > 1e-8
  ) {
    h04_abort("The accepted %s mixed-model frame failed its contract", contract$label)
  }

  nested_models <- Map(
    h04_fit_auxiliary_model,
    names(model_formulas),
    model_formulas,
    MoreArgs = list(data = data)
  )
  names(nested_models) <- names(model_formulas)
  null_fit <- nested_models$intercept$fit

  nested_model_summaries <- lapply(nested_models, function(item) {
    r_squared <- h04_mixed_r_squared(
      item$fit,
      null_fit,
      data$analysis_weight
    )
    gradient <- if (!is.null(item$fit$sdr$gradient.fixed)) {
      max(abs(item$fit$sdr$gradient.fixed))
    } else {
      NA_real_
    }
    tibble::tibble(
      placement = contract$label,
      model_id = item$model_id,
      formula = paste(deparse(item$formula), collapse = " "),
      marginal_r_squared = r_squared$marginal,
      conditional_r_squared = r_squared$conditional,
      fixed_effect_variance_weighted = r_squared$fixed_weighted,
      participant_intercept_variance = r_squared$random,
      distribution_specific_variance = r_squared$residual,
      conventional_unweighted_row_marginal_r_squared =
        r_squared$conventional_marginal,
      conventional_unweighted_row_conditional_r_squared =
        r_squared$conventional_conditional,
      conventional_unweighted_row_fixed_effect_variance =
        r_squared$conventional_fixed,
      convergence_code = as.integer(item$fit$fit$convergence),
      converged = identical(as.integer(item$fit$fit$convergence), 0L) &&
        isTRUE(item$fit$sdr$pdHess),
      warning_count = length(item$warnings),
      warnings = paste(item$warnings, collapse = " | "),
      positive_definite_hessian = isTRUE(item$fit$sdr$pdHess),
      maximum_absolute_gradient = gradient,
      singular = isTRUE(performance::check_singularity(item$fit)),
      log_likelihood = as.numeric(stats::logLik(item$fit)),
      aic = stats::AIC(item$fit),
      elapsed_fit_seconds = item$elapsed_fit_seconds
    )
  }) |>
    dplyr::bind_rows()

  model_values <- stats::setNames(
    nested_model_summaries$marginal_r_squared,
    nested_model_summaries$model_id
  )
  site_shapley <- 0.5 * (
    (model_values[["site"]] - model_values[["intercept"]]) +
      (model_values[["additive"]] - model_values[["activity"]])
  )
  activity_shapley <- 0.5 * (
    (model_values[["activity"]] - model_values[["intercept"]]) +
      (model_values[["additive"]] - model_values[["site"]])
  )
  interaction_shapley <-
    model_values[["full"]] - model_values[["additive"]]
  component_r_squared <- c(
    site_shapley,
    activity_shapley,
    interaction_shapley
  )
  allocated <- sum(component_r_squared)
  target <- model_values[["full"]] - model_values[["intercept"]]
  efficiency_error <- allocated - target

  shapley <- tibble::tibble(
    placement = contract$label,
    component_id = c("site", "activity", "site_by_activity"),
    component = c(
      "Study site",
      "Activity category",
      "Study site × activity category"
    ),
    marginal_r_squared_component = component_r_squared,
    share_of_full_marginal_r_squared_percent = 100 *
      component_r_squared / model_values[["full"]],
    full_marginal_r_squared = model_values[["full"]],
    null_marginal_r_squared = model_values[["intercept"]],
    allocated_marginal_r_squared = allocated,
    shapley_efficiency_error = efficiency_error,
    allocation_definition = paste(
      "hierarchy-respecting Shapley/dominance allocation of 1/k-weighted",
      "Nakagawa marginal R-squared across refitted nested models; study",
      "site and activity category are averaged over both admissible entry",
      "orders; the interaction enters only after both main effects"
    ),
    reference_invariance = paste(
      "nested-model value function; invariant to factor reference levels"
    ),
    uncertainty = "point estimates; no bootstrap intervals",
    inferential_role = paste(
      "exploratory descriptive allocation; not a unique or causal",
      "partition and does not replace the accepted H04 population-mean model"
    )
  )

  full_row <- nested_model_summaries |>
    dplyr::filter(.data$model_id == "full")
  fit <- nested_models$full$fit
  diagnostics <- h04_hour_level_diagnostics(fit, data)
  participant_variance <- full_row$participant_intercept_variance[[1L]]
  participant_sd <- sqrt(participant_variance)
  total_variance <- with(
    full_row,
    fixed_effect_variance_weighted + participant_intercept_variance +
      distribution_specific_variance
  )
  summary <- tibble::tibble(
    run_id = paste0(
      "participant_random_intercept__",
      placement_id
    ),
    placement = contract$label,
    formula = paste(deparse(model_formulas$full), collapse = " "),
    family = "glmmTMB Tweedie",
    link = "log",
    fitting_method = "maximum likelihood",
    long_rows = nrow(data),
    unique_participant_hours = dplyr::n_distinct(data$analysis_hour_id),
    effective_weighted_hours = sum(data$analysis_weight),
    participants = nlevels(data$participant),
    participant_days = nlevels(data$participant_day),
    sites = nlevels(data$site),
    activity_categories = nlevels(data$activity_named),
    working_power_fixed = working_power,
    marginal_r_squared = full_row$marginal_r_squared,
    conditional_r_squared = full_row$conditional_r_squared,
    participant_r_squared_increment =
      full_row$conditional_r_squared - full_row$marginal_r_squared,
    residual_variance_share =
      full_row$distribution_specific_variance / total_variance,
    adjusted_participant_icc = participant_variance /
      (participant_variance + full_row$distribution_specific_variance),
    unadjusted_participant_icc = participant_variance / total_variance,
    fixed_effect_variance_weighted = full_row$fixed_effect_variance_weighted,
    participant_intercept_variance = participant_variance,
    distribution_specific_variance =
      full_row$distribution_specific_variance,
    participant_to_fixed_variance_ratio = participant_variance /
      full_row$fixed_effect_variance_weighted,
    participant_intercept_sd_log = participant_sd,
    participant_factor_per_sd = exp(participant_sd),
    conventional_unweighted_row_marginal_r_squared =
      full_row$conventional_unweighted_row_marginal_r_squared,
    conventional_unweighted_row_conditional_r_squared =
      full_row$conventional_unweighted_row_conditional_r_squared,
    marginal_r_squared_weighting_difference =
      full_row$marginal_r_squared -
      full_row$conventional_unweighted_row_marginal_r_squared,
    conditional_r_squared_weighting_difference =
      full_row$conditional_r_squared -
      full_row$conventional_unweighted_row_conditional_r_squared,
    r_squared_approximation = paste(
      "H03 Nakagawa lognormal distribution-specific variance convention",
      "with the fixed linear-predictor sample variance weighted by exact 1/k",
      "fractional-frequency weights"
    ),
    weighting_role = paste(
      "every retained participant-hour sums to one; the conventional",
      "unweighted expanded-row result is retained only as a cross-check"
    ),
    uncertainty = "point estimates; no bootstrap intervals",
    inferential_role = paste(
      "exploratory participant random-intercept variance assessment;",
      "does not replace the accepted H04 population-mean quasi-Tweedie model"
    )
  )

  full_warnings <- nested_models$full$warnings
  diagnostic_row <- tibble::tibble(
    run_id = summary$run_id,
    placement = contract$label,
    convergence_code = as.integer(fit$fit$convergence),
    convergence_message = as.character(fit$fit$message),
    converged = identical(as.integer(fit$fit$convergence), 0L) &&
      isTRUE(fit$sdr$pdHess),
    warning_count = length(full_warnings),
    warnings = paste(full_warnings, collapse = " | "),
    positive_definite_hessian = isTRUE(fit$sdr$pdHess),
    maximum_absolute_gradient = if (!is.null(fit$sdr$gradient.fixed)) {
      max(abs(fit$sdr$gradient.fixed))
    } else {
      NA_real_
    },
    singular = isTRUE(performance::check_singularity(fit)),
    finite_fixed_coefficients = all(is.finite(glmmTMB::fixef(fit)$cond)),
    finite_participant_variance = is.finite(participant_variance) &&
      participant_variance > 0,
    tweedie_power = diagnostics$fitted_power,
    dispersion = diagnostics$dispersion,
    log_likelihood = as.numeric(stats::logLik(fit)),
    aic = stats::AIC(fit),
    long_rows = nrow(data),
    unique_participant_hours = nrow(diagnostics$pearson),
    effective_weighted_hours = sum(data$analysis_weight),
    minimum_hour_weight_sum = min(hour_weights$weight_sum),
    maximum_hour_weight_sum = max(hour_weights$weight_sum),
    pearson_mean_hour_aggregated = mean(diagnostics$pearson),
    pearson_sd_hour_aggregated = stats::sd(diagnostics$pearson),
    pearson_q01_hour_aggregated = unname(stats::quantile(
      diagnostics$pearson,
      0.01
    )),
    pearson_q99_hour_aggregated = unname(stats::quantile(
      diagnostics$pearson,
      0.99
    )),
    absolute_residual_fitted_spearman_hour_aggregated = stats::cor(
      abs(diagnostics$pearson),
      diagnostics$fitted,
      method = "spearman"
    ),
    lag1_pearson_residual_correlation_hour_aggregated = unname(
      diagnostics$lag_one[["correlation"]]
    ),
    lag1_pairs = as.integer(diagnostics$lag_one[["pairs"]]),
    observed_zero_fraction = mean(diagnostics$observed_zero),
    tweedie_implied_zero_fraction = mean(diagnostics$zero_probability),
    observed_minus_implied_zero_fraction =
      mean(diagnostics$observed_zero) -
      mean(diagnostics$zero_probability),
    fitted_minimum_lx_hour_aggregated = min(diagnostics$fitted),
    fitted_median_lx_hour_aggregated = stats::median(diagnostics$fitted),
    fitted_maximum_lx_hour_aggregated = max(diagnostics$fitted),
    diagnostic_role = paste(
      "numerical and working-distribution checks for the exploratory",
      "variance assessment; concurrent memberships are aggregated to one",
      "weighted residual per participant-hour; no simulation"
    )
  )

  if (
    any(!nested_model_summaries$converged) ||
      any(nested_model_summaries$warning_count != 0L) ||
      any(!nested_model_summaries$positive_definite_hessian) ||
      any(nested_model_summaries$singular) ||
      any(!is.finite(nested_model_summaries$maximum_absolute_gradient)) ||
      abs(model_values[["intercept"]]) > 1e-10 ||
      abs(efficiency_error) > 1e-10 ||
      !isTRUE(diagnostic_row$finite_fixed_coefficients[[1L]]) ||
      !isTRUE(diagnostic_row$finite_participant_variance[[1L]]) ||
      summary$conditional_r_squared < summary$marginal_r_squared ||
      abs(
        summary$marginal_r_squared +
          summary$participant_r_squared_increment +
          summary$residual_variance_share - 1
      ) > 1e-10
  ) {
    h04_abort(
      "Auxiliary participant random-intercept assessment failed for %s",
      contract$label
    )
  }

  list(
    placement_id = placement_id,
    placement = contract$label,
    data = data,
    formula = model_formulas$full,
    family = "glmmTMB Tweedie with log link",
    working_power = working_power,
    fit = fit,
    nested_models = lapply(nested_models, `[[`, "fit"),
    nested_model_formulas = model_formulas,
    nested_model_warnings = lapply(nested_models, `[[`, "warnings"),
    nested_model_elapsed_fit_seconds = vapply(
      nested_models,
      `[[`,
      numeric(1L),
      "elapsed_fit_seconds"
    ),
    summary = summary,
    diagnostics = diagnostic_row,
    nested_model_summaries = nested_model_summaries,
    shapley = shapley
  )
})
names(assessment) <- names(placement_contract)

summary_data <- dplyr::bind_rows(lapply(assessment, `[[`, "summary"))
diagnostics <- dplyr::bind_rows(lapply(assessment, `[[`, "diagnostics"))
nested_model_summaries <- dplyr::bind_rows(lapply(
  assessment,
  `[[`,
  "nested_model_summaries"
))
shapley <- dplyr::bind_rows(lapply(assessment, `[[`, "shapley"))

model_object <- list(
  assessment = lapply(assessment, function(item) {
    item[c(
      "placement_id", "placement", "data", "formula", "family",
      "working_power", "fit", "nested_models", "nested_model_formulas",
      "nested_model_warnings", "nested_model_elapsed_fit_seconds"
    )]
  }),
  input_path = normalizePath(
    accepted_model_path,
    winslash = "/",
    mustWork = TRUE
  ),
  input_sha256 = observed_input_sha256,
  weighting_convention = summary_data$r_squared_approximation[[1L]],
  inferential_role = summary_data$inferential_role[[1L]]
)

metadata <- list()
metadata$model <- write_rds_artifact(
  model_object,
  file.path(
    roots$models,
    "H04_participant_random_intercept_assessment.rds"
  ),
  producer
)
metadata$summary <- write_csv_artifact(
  summary_data,
  file.path(
    roots$tables,
    "H04_participant_random_intercept_summary.csv"
  ),
  producer
)
metadata$shapley <- write_csv_artifact(
  shapley,
  file.path(
    roots$tables,
    "H04_participant_random_intercept_marginal_r2_shapley.csv"
  ),
  producer
)
metadata$diagnostics <- write_csv_artifact(
  diagnostics,
  file.path(
    roots$diagnostics,
    "H04_participant_random_intercept_diagnostics.csv"
  ),
  producer
)
metadata$nested_models <- write_csv_artifact(
  nested_model_summaries,
  file.path(
    roots$diagnostics,
    "H04_participant_random_intercept_shapley_models.csv"
  ),
  producer
)

environment <- tibble::tibble(
  component = c("R", required_packages),
  version = c(
    as.character(getRversion()),
    vapply(
      required_packages,
      function(package) as.character(utils::packageVersion(package)),
      character(1L)
    )
  )
)
metadata$environment <- write_csv_artifact(
  environment,
  file.path(
    roots$manifests,
    "H04_participant_random_intercept_environment.csv"
  ),
  producer
)

manifest <- dplyr::bind_rows(lapply(metadata, manifest_row)) |>
  dplyr::arrange(.data$path)
write_csv_artifact(
  manifest,
  file.path(
    roots$manifests,
    "H04_participant_random_intercept_manifest.csv"
  ),
  producer
)

message("H04 participant random-intercept assessment complete")
for (index in seq_len(nrow(summary_data))) {
  message(sprintf(
    paste(
      "%s: marginal R2 %.3f; conditional R2 %.3f; participant %.3f;",
      "residual %.3f"
    ),
    summary_data$placement[[index]],
    summary_data$marginal_r_squared[[index]],
    summary_data$conditional_r_squared[[index]],
    summary_data$participant_r_squared_increment[[index]],
    summary_data$residual_variance_share[[index]]
  ))
}
