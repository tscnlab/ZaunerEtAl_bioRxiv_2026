#!/usr/bin/env Rscript

# Quantify stable participant-level heterogeneity in the accepted H03
# near-eye frame using a bounded auxiliary Tweedie random-intercept model.

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
source(file.path(root, "scripts/hypotheses/H03/h03_contract.R"))
source(file.path(root, "scripts/hypotheses/H03/h03_modeling.R"))

if (!identical(as.character(getRversion()), "4.6.1")) {
  h03_abort(
    "H03 participant random-intercept assessment requires R 4.6.1; found %s",
    as.character(getRversion())
  )
}

required_packages <- c(
  "dplyr", "tibble", "readr", "glmmTMB", "performance", "insight"
)
missing_packages <- required_packages[!vapply(
  required_packages,
  requireNamespace,
  logical(1),
  quietly = TRUE
)]
if (length(missing_packages) > 0L) {
  h03_abort(
    "Missing project package(s): %s",
    paste(missing_packages, collapse = ", ")
  )
}

producer <- paste0(
  "scripts/hypotheses/H03/",
  "run_h03_participant_random_intercept_assessment.R"
)
run_id <- "participant_random_intercept__near_eye"
working_power <- h03_specification()$working_tweedie_power

model_root <- file.path(root, "artifacts/07_models/H03")
diagnostic_root <- file.path(root, "artifacts/08_diagnostics/H03")
table_root <- file.path(root, "artifacts/09_tables/H03")
manifest_root <- file.path(root, "artifacts/12_manifests/H03")
invisible(lapply(
  c(model_root, diagnostic_root, table_root, manifest_root),
  dir.create,
  recursive = TRUE,
  showWarnings = FALSE
))

accepted_model_path <- file.path(
  model_root,
  "H03_additive_model_objects.rds"
)
if (!file.exists(accepted_model_path)) {
  h03_abort("Missing accepted H03 additive model object")
}
accepted <- readRDS(accepted_model_path)$main_near_eye
if (is.null(accepted$data)) {
  h03_abort("Accepted H03 near-eye model frame is unavailable")
}

model_formulas <- list(
  intercept = stats::as.formula(
    "geo_medi_1h ~ 1 + (1 | participant)"
  ),
  site = stats::as.formula(
    "geo_medi_1h ~ site + (1 | participant)"
  ),
  light_source = stats::as.formula(
    "geo_medi_1h ~ light_source + (1 | participant)"
  ),
  additive = stats::as.formula(
    "geo_medi_1h ~ site + light_source + (1 | participant)"
  ),
  full = stats::as.formula(
    "geo_medi_1h ~ site * light_source + (1 | participant)"
  )
)
model_formulas <- lapply(model_formulas, function(formula) {
  environment(formula) <- environment()
  formula
})
formula <- model_formulas$full
data <- accepted$data |>
  dplyr::arrange(
    .data$site,
    .data$participant,
    .data$local_date,
    .data$interval_start_utc,
    .data$clock_minute
  ) |>
  h03_prepare_model_factors(formula)

if (
  nrow(data) != 17935L ||
    nlevels(data$participant) != 140L ||
    nlevels(data$participant_day) != 801L ||
    nlevels(data$site) != 9L ||
    nlevels(data$light_source) != 7L ||
    nlevels(data$ar_sequence) != 1178L
) {
  h03_abort(
    "Near-eye random-intercept frame differs from the accepted primary sample"
  )
}
first_by_sequence <- !duplicated(data$ar_sequence)
if (
  !identical(as.logical(data$AR_start), first_by_sequence) ||
    sum(data$AR_start) != nlevels(data$ar_sequence)
) {
  h03_abort("AR sequence starts are inconsistent with the accepted frame")
}

fit_nested_model <- function(model_id, formula) {
  message("Fitting auxiliary H03 model: ", model_id)
  elapsed <- system.time({
    captured <- h03_capture_warnings(glmmTMB::glmmTMB(
      formula = formula,
      data = data,
      family = glmmTMB::tweedie(link = "log"),
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

nested_models <- Map(
  fit_nested_model,
  names(model_formulas),
  model_formulas
)
names(nested_models) <- names(model_formulas)
fit <- nested_models$full$fit
captured <- list(warnings = nested_models$full$warnings)
elapsed_fit <- c(elapsed = nested_models$full$elapsed_fit_seconds)

r_squared <- performance::r2_nakagawa(
  fit,
  approximation = "lognormal"
)
icc <- performance::icc(
  fit,
  approximation = "lognormal"
)
variance <- insight::get_variance(
  fit,
  approximation = "lognormal"
)
if (
  is.null(r_squared$R2_marginal) ||
    is.null(r_squared$R2_conditional) ||
    nrow(icc) < 1L ||
    any(!c("var.fixed", "var.random", "var.residual") %in% names(variance))
) {
  h03_abort("Could not recover the requested mixed-model variance summaries")
}

marginal_r_squared <- as.numeric(r_squared$R2_marginal[[1L]])
conditional_r_squared <- as.numeric(r_squared$R2_conditional[[1L]])
participant_r_squared_increment <-
  conditional_r_squared - marginal_r_squared
adjusted_icc <- as.numeric(icc$ICC_adjusted[[1L]])
unadjusted_icc <- as.numeric(icc$ICC_unadjusted[[1L]])
fixed_effect_variance <- as.numeric(variance$var.fixed)
participant_variance <- as.numeric(variance$var.random)
distribution_specific_variance <- as.numeric(variance$var.residual)

nested_model_summaries <- lapply(nested_models, function(item) {
  item_r_squared <- performance::r2_nakagawa(
    item$fit,
    approximation = "lognormal"
  )
  item_variance <- insight::get_variance(
    item$fit,
    approximation = "lognormal"
  )
  item_gradient <- if (!is.null(item$fit$sdr$gradient.fixed)) {
    max(abs(item$fit$sdr$gradient.fixed))
  } else {
    NA_real_
  }
  tibble::tibble(
    model_id = item$model_id,
    formula = paste(deparse(item$formula), collapse = " "),
    marginal_r_squared = as.numeric(item_r_squared$R2_marginal[[1L]]),
    conditional_r_squared = as.numeric(item_r_squared$R2_conditional[[1L]]),
    fixed_effect_variance = as.numeric(item_variance$var.fixed),
    participant_intercept_variance = as.numeric(item_variance$var.random),
    distribution_specific_variance = as.numeric(item_variance$var.residual),
    convergence_code = as.integer(item$fit$fit$convergence),
    converged = identical(as.integer(item$fit$fit$convergence), 0L) &&
      isTRUE(item$fit$sdr$pdHess),
    warning_count = length(item$warnings),
    warnings = paste(item$warnings, collapse = " | "),
    positive_definite_hessian = isTRUE(item$fit$sdr$pdHess),
    maximum_absolute_gradient = item_gradient,
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
    (model_values[["additive"]] - model_values[["light_source"]])
)
light_source_shapley <- 0.5 * (
  (model_values[["light_source"]] - model_values[["intercept"]]) +
    (model_values[["additive"]] - model_values[["site"]])
)
interaction_shapley <-
  model_values[["full"]] - model_values[["additive"]]
allocated_marginal_r_squared <-
  site_shapley + light_source_shapley + interaction_shapley
allocation_target <-
  model_values[["full"]] - model_values[["intercept"]]
shapley_efficiency_error <-
  allocated_marginal_r_squared - allocation_target

component_r_squared <- c(
  site_shapley,
  light_source_shapley,
  interaction_shapley
)
shapley_components <- tibble::tibble(
  component_id = c("site", "light_source", "site_by_light_source"),
  component = c(
    "Study site",
    "Light source",
    "Study site × light source"
  ),
  marginal_r_squared_component = component_r_squared,
  share_of_full_marginal_r_squared_percent = 100 *
    component_r_squared / model_values[["full"]],
  full_marginal_r_squared = model_values[["full"]],
  null_marginal_r_squared = model_values[["intercept"]],
  allocated_marginal_r_squared = allocated_marginal_r_squared,
  shapley_efficiency_error = shapley_efficiency_error,
  allocation_definition = paste(
    "hierarchy-respecting Shapley/dominance allocation of Nakagawa",
    "marginal R-squared across refitted nested models; study site and",
    "light source are averaged over both admissible entry orders; the",
    "interaction enters only after both main effects"
  ),
  reference_invariance = paste(
    "nested-model value function; invariant to the factor reference levels"
  ),
  uncertainty = "point estimates; no bootstrap intervals",
  inferential_role = paste(
    "exploratory descriptive allocation; not a unique or causal partition",
    "and does not replace the accepted H03 primary mean model"
  )
)

variance_components <- glmmTMB::VarCorr(fit)$cond
participant_sd <- unname(attr(
  variance_components$participant,
  "stddev"
)[[1L]])
participant_factor_per_sd <- exp(participant_sd)

pearson <- stats::residuals(fit, type = "pearson")
fitted_mean <- stats::fitted(fit)
lag_one <- h03_boundary_lag_correlation(
  pearson,
  data$AR_start,
  lag = 1L
)
dispersion <- stats::sigma(fit)
fitted_power <- unname(glmmTMB::family_params(fit)[[1L]])
lambda <- fitted_mean^(2 - fitted_power) /
  (dispersion * (2 - fitted_power))
tweedie_zero_probability <- exp(-lambda)

maximum_gradient <- if (!is.null(fit$sdr$gradient.fixed)) {
  max(abs(fit$sdr$gradient.fixed))
} else {
  NA_real_
}
singular <- isTRUE(performance::check_singularity(fit))
converged <- identical(as.integer(fit$fit$convergence), 0L) &&
  isTRUE(fit$sdr$pdHess)

assessment_summary <- tibble::tibble(
  run_id = run_id,
  placement = "Near-eye",
  formula = paste(deparse(formula), collapse = " "),
  family = "glmmTMB Tweedie",
  link = "log",
  fitting_method = "maximum likelihood",
  observations = nrow(data),
  participants = nlevels(data$participant),
  participant_days = nlevels(data$participant_day),
  sites = nlevels(data$site),
  light_source_categories = nlevels(data$light_source),
  working_power_fixed = working_power,
  marginal_r_squared = marginal_r_squared,
  conditional_r_squared = conditional_r_squared,
  participant_r_squared_increment = participant_r_squared_increment,
  adjusted_participant_icc = adjusted_icc,
  unadjusted_participant_icc = unadjusted_icc,
  fixed_effect_variance = fixed_effect_variance,
  participant_intercept_variance = participant_variance,
  distribution_specific_variance = distribution_specific_variance,
  participant_to_fixed_variance_ratio =
    participant_variance / fixed_effect_variance,
  participant_intercept_sd_log = participant_sd,
  participant_factor_per_sd = participant_factor_per_sd,
  r_squared_approximation = paste(
    "Nakagawa model-based variance decomposition with lognormal",
    "distribution-specific variance"
  ),
  uncertainty = "point estimates; no bootstrap intervals",
  inferential_role = paste(
    "exploratory participant random-intercept variance assessment;",
    "does not replace the accepted H03 primary mean model"
  )
)

assessment_diagnostics <- tibble::tibble(
  run_id = run_id,
  placement = "Near-eye",
  convergence_code = as.integer(fit$fit$convergence),
  convergence_message = as.character(fit$fit$message),
  converged = converged,
  warning_count = length(captured$warnings),
  warnings = paste(captured$warnings, collapse = " | "),
  positive_definite_hessian = isTRUE(fit$sdr$pdHess),
  maximum_absolute_gradient = maximum_gradient,
  singular = singular,
  finite_fixed_coefficients = all(is.finite(glmmTMB::fixef(fit)$cond)),
  finite_participant_variance = is.finite(participant_variance) &&
    participant_variance > 0,
  tweedie_power = fitted_power,
  dispersion = dispersion,
  log_likelihood = as.numeric(stats::logLik(fit)),
  aic = stats::AIC(fit),
  pearson_mean = mean(pearson),
  pearson_sd = stats::sd(pearson),
  pearson_q01 = unname(stats::quantile(pearson, 0.01)),
  pearson_q99 = unname(stats::quantile(pearson, 0.99)),
  absolute_residual_fitted_spearman = stats::cor(
    abs(pearson),
    fitted_mean,
    method = "spearman"
  ),
  lag1_pearson_residual_correlation = unname(lag_one[["correlation"]]),
  lag1_pairs = as.integer(lag_one[["pairs"]]),
  observed_zero_fraction = mean(data$geo_medi_1h == 0),
  tweedie_implied_zero_fraction = mean(tweedie_zero_probability),
  observed_minus_implied_zero_fraction =
    mean(data$geo_medi_1h == 0) - mean(tweedie_zero_probability),
  fitted_minimum_lx = min(fitted_mean),
  fitted_median_lx = stats::median(fitted_mean),
  fitted_maximum_lx = max(fitted_mean),
  diagnostic_role = paste(
    "numerical and working-distribution checks for the exploratory",
    "variance assessment; no simulation"
  )
)

if (
  !converged || singular ||
    any(!nested_model_summaries$converged) ||
    any(nested_model_summaries$singular) ||
    any(nested_model_summaries$warning_count != 0L) ||
    abs(model_values[["intercept"]]) > 1e-10 ||
    abs(shapley_efficiency_error) > 1e-10 ||
    any(!is.finite(c(
      marginal_r_squared,
      conditional_r_squared,
      participant_variance,
      distribution_specific_variance,
      shapley_components$marginal_r_squared_component
    ))) ||
    conditional_r_squared < marginal_r_squared
) {
  h03_abort("Auxiliary participant random-intercept assessment failed its gate")
}

model_object <- list(
  run_id = run_id,
  placement = "Near-eye",
  data = data,
  formula = formula,
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
  shapley_components = shapley_components,
  warnings = captured$warnings,
  elapsed_fit_seconds = unname(elapsed_fit[["elapsed"]]),
  input_path = normalizePath(
    accepted_model_path,
    winslash = "/",
    mustWork = TRUE
  ),
  input_sha256 = artifact_sha256(accepted_model_path),
  inferential_role = assessment_summary$inferential_role[[1L]]
)

metadata <- list()
metadata$model <- write_rds_artifact(
  model_object,
  file.path(
    model_root,
    "H03_near_eye_participant_random_intercept_assessment.rds"
  ),
  producer
)
metadata$summary <- write_csv_artifact(
  assessment_summary,
  file.path(
    table_root,
    "H03_near_eye_participant_random_intercept_summary.csv"
  ),
  producer
)
metadata$shapley_components <- write_csv_artifact(
  shapley_components,
  file.path(
    table_root,
    paste0(
      "H03_near_eye_participant_random_intercept_",
      "marginal_r2_shapley.csv"
    )
  ),
  producer
)
metadata$diagnostics <- write_csv_artifact(
  assessment_diagnostics,
  file.path(
    diagnostic_root,
    "H03_near_eye_participant_random_intercept_diagnostics.csv"
  ),
  producer
)
metadata$shapley_models <- write_csv_artifact(
  nested_model_summaries,
  file.path(
    diagnostic_root,
    paste0(
      "H03_near_eye_participant_random_intercept_",
      "shapley_models.csv"
    )
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
      character(1)
    )
  )
)
metadata$environment <- write_csv_artifact(
  environment,
  file.path(
    manifest_root,
    "H03_near_eye_participant_random_intercept_environment.csv"
  ),
  producer
)

manifest <- dplyr::bind_rows(lapply(metadata, manifest_row)) |>
  dplyr::arrange(.data$path)
write_csv_artifact(
  manifest,
  file.path(
    manifest_root,
    "H03_near_eye_participant_random_intercept_manifest.csv"
  ),
  producer
)

message(
  "H03 near-eye participant random-intercept assessment complete: ",
  sprintf(
    paste(
      "marginal R2 %.3f; conditional R2 %.3f; participant increment %.3f;",
      "Shapley site %.3f, light source %.3f, interaction %.3f"
    ),
    marginal_r_squared,
    conditional_r_squared,
    participant_r_squared_increment,
    site_shapley,
    light_source_shapley,
    interaction_shapley
  )
)
