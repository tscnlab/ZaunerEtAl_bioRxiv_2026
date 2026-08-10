# Fit the bounded H03 near-eye Tweedie GLMM without participant-day intercepts.

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
source(file.path(root, "scripts/pipeline/p_value_display.R"))
source(file.path(root, "scripts/hypotheses/H03/h03_contract.R"))
source(file.path(root, "scripts/hypotheses/H03/h03_modeling.R"))

if (!identical(as.character(getRversion()), "4.6.1")) {
  h03_abort(
    "H03 reduced-GLMM pilot requires R 4.6.1; found %s",
    as.character(getRversion())
  )
}

required_packages <- c(
  "dplyr", "tibble", "readr", "glmmTMB", "performance", "DHARMa",
  "emmeans"
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
  "run_h03_reduced_tweedie_glmm_pilot.R"
)
run_id <- "reduced_tweedie_glmm__near_eye__pilot100"
simulation_replicates <- 100L
simulation_seed <- 20260807L

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

additive_path <- file.path(model_root, "H03_additive_model_objects.rds")
if (!file.exists(additive_path)) {
  h03_abort("Missing accepted H03 additive model object")
}
accepted <- readRDS(additive_path)$main_near_eye
data <- accepted$data |>
  dplyr::arrange(
    .data$site,
    .data$participant,
    .data$local_date,
    .data$interval_start_utc,
    .data$clock_minute
  ) |>
  dplyr::group_by(.data$ar_sequence) |>
  dplyr::mutate(ar_step = dplyr::row_number()) |>
  dplyr::ungroup()
maximum_ar_step <- max(data$ar_step)
data$ar_step_factor <- factor(
  data$ar_step,
  levels = seq_len(maximum_ar_step)
)

if (nrow(data) != 17935L ||
    nlevels(data$participant) != 140L ||
    nlevels(data$site) != 9L ||
    nlevels(data$light_source) != 7L ||
    nlevels(data$ar_sequence) != 1178L) {
  h03_abort("Near-eye pilot frame differs from the accepted primary sample")
}
first_by_sequence <- !duplicated(data$ar_sequence)
if (!all(data$ar_step[first_by_sequence] == 1L) ||
    !all(data$AR_start[first_by_sequence])) {
  h03_abort("AR sequence starts are inconsistent with the accepted frame")
}

formula <- stats::as.formula(paste0(
  "geo_medi_1h ~ site + light_source + (1 | participant) + ",
  "ar1(ar_step_factor + 0 | ar_sequence)"
))
environment(formula) <- environment()

model_path <- file.path(
  model_root,
  "H03_reduced_tweedie_glmm_near_eye_pilot_object.rds"
)
metadata <- list()
if (file.exists(model_path)) {
  object <- readRDS(model_path)
  cache_valid <- identical(object$run_id, run_id) &&
    identical(
      paste(deparse(object$formula), collapse = " "),
      paste(deparse(formula), collapse = " ")
    ) &&
    nrow(object$data) == nrow(data) &&
    inherits(object$fit, "glmmTMB")
  if (!cache_valid) {
    h03_abort("Existing reduced-GLMM pilot cache violates its contract")
  }
  message("Using validated reduced Tweedie GLMM pilot cache")
} else {
  message("Fitting reduced near-eye Tweedie GLMM")
  elapsed_fit <- system.time({
    captured <- h03_capture_warnings(glmmTMB::glmmTMB(
      formula = formula,
      data = data,
      family = glmmTMB::tweedie(link = "log"),
      REML = FALSE
    ))
  })
  object <- list(
    run_id = run_id,
    placement = "Near-eye",
    data = data,
    formula = formula,
    fit = captured$value,
    warnings = unique(captured$warnings),
    elapsed_fit_seconds = unname(elapsed_fit[["elapsed"]]),
    inferential_role = paste(
      "bounded reduced Tweedie GLMM architecture pilot;",
      "not the accepted H03 primary model"
    )
  )
  metadata$model <- write_rds_artifact(object, model_path, producer)
}
if (is.null(metadata$model)) {
  info <- file.info(model_path)
  metadata$model <- list(
    path = normalizePath(model_path, winslash = "/", mustWork = TRUE),
    sha256 = artifact_sha256(model_path),
    bytes = unname(info$size),
    producer = producer,
    r_version = as.character(getRversion()),
    written_utc = format(info$mtime, tz = "UTC", usetz = TRUE)
  )
}

fit <- object$fit
fit_summary <- summary(fit)
variance <- glmmTMB::VarCorr(fit)$cond
participant_sd <- unname(attr(variance$participant, "stddev")[[1L]])
ar_standard_deviation <- unname(attr(variance$ar_sequence, "stddev")[[1L]])
ar_correlation <- attr(variance$ar_sequence, "correlation")
rho <- if (is.matrix(ar_correlation) && nrow(ar_correlation) >= 2L) {
  unname(ar_correlation[1L, 2L])
} else {
  NA_real_
}
tweedie_power <- unname(glmmTMB::family_params(fit)[[1L]])
singular <- isTRUE(performance::check_singularity(fit))
maximum_gradient <- if (!is.null(fit$sdr$gradient.fixed)) {
  max(abs(fit$sdr$gradient.fixed))
} else {
  NA_real_
}

pearson <- stats::residuals(fit, type = "pearson")
acf_data <- dplyr::bind_rows(lapply(1:6, function(lag) {
  value <- h03_boundary_lag_correlation(
    pearson,
    object$data$AR_start,
    lag = lag
  )
  tibble::tibble(
    run_id = run_id,
    placement = "Near-eye",
    lag = lag,
    correlation = unname(value[["correlation"]]),
    pairs = as.integer(value[["pairs"]])
  )
}))

simulation_path <- file.path(
  diagnostic_root,
  "H03_reduced_tweedie_glmm_near_eye_DHARMa_100.rds"
)
if (file.exists(simulation_path)) {
  simulation_object <- readRDS(simulation_path)
  if (!identical(simulation_object$replicates, simulation_replicates) ||
      !identical(simulation_object$seed, simulation_seed)) {
    h03_abort("Existing reduced-GLMM DHARMa cache violates its contract")
  }
  message("Using validated 100-replicate DHARMa pilot cache")
} else {
  message("Running bounded 100-replicate DHARMa pilot")
  elapsed_simulation <- system.time({
    simulation <- DHARMa::simulateResiduals(
      fittedModel = fit,
      n = simulation_replicates,
      refit = FALSE,
      seed = simulation_seed,
      plot = FALSE
    )
  })
  simulation_object <- list(
    replicates = simulation_replicates,
    seed = simulation_seed,
    simulation = simulation,
    elapsed_seconds = unname(elapsed_simulation[["elapsed"]])
  )
  metadata$simulation <- write_rds_artifact(
    simulation_object,
    simulation_path,
    producer
  )
}
if (is.null(metadata$simulation)) {
  info <- file.info(simulation_path)
  metadata$simulation <- list(
    path = normalizePath(simulation_path, winslash = "/", mustWork = TRUE),
    sha256 = artifact_sha256(simulation_path),
    bytes = unname(info$size),
    producer = producer,
    r_version = as.character(getRversion()),
    written_utc = format(info$mtime, tz = "UTC", usetz = TRUE)
  )
}

simulation <- simulation_object$simulation
uniformity <- DHARMa::testUniformity(simulation, plot = FALSE)
dispersion <- DHARMa::testDispersion(simulation, plot = FALSE)
zeros <- DHARMa::testZeroInflation(simulation, plot = FALSE)
outliers <- DHARMa::testOutliers(simulation, plot = FALSE)
observed_zero_count <- sum(object$data$geo_medi_1h == 0)
simulated_zero_count <- colSums(simulation$simulatedResponse == 0)
zero_ratio <- observed_zero_count / mean(simulated_zero_count)

dharma_acf_data <- dplyr::bind_rows(lapply(1:6, function(lag) {
  value <- h03_boundary_lag_correlation(
    simulation$scaledResiduals,
    object$data$AR_start,
    lag = lag
  )
  tibble::tibble(
    run_id = run_id,
    placement = "Near-eye",
    residual_type = "DHARMa simulation-scaled residual",
    lag = lag,
    correlation = unname(value[["correlation"]]),
    pairs = as.integer(value[["pairs"]])
  )
}))

dharm_summary <- tibble::tibble(
  run_id = run_id,
  placement = "Near-eye",
  replicates = simulation_replicates,
  test = c("uniformity", "dispersion", "zero_mass", "outliers"),
  statistic = c(
    unname(uniformity$statistic),
    unname(dispersion$statistic),
    unname(zeros$statistic),
    unname(outliers$statistic)
  ),
  p_value = c(
    uniformity$p.value,
    dispersion$p.value,
    zeros$p.value,
    outliers$p.value
  ),
  p_display = nh_format_p_value(p_value),
  pilot_interpretation = paste(
    "100 simulations only; Monte Carlo resolution is coarse and no",
    "production simulation was run"
  )
)

simulation_runtime <- tibble::tibble(
  run_id = run_id,
  placement = "Near-eye",
  pilot_replicates = simulation_replicates,
  elapsed_seconds = simulation_object$elapsed_seconds,
  seconds_per_replicate = simulation_object$elapsed_seconds /
    simulation_replicates,
  projected_1000_replicate_seconds = simulation_object$elapsed_seconds * 10,
  production_run = FALSE
)

random_effect_marginalization_factor <- exp(
  0.5 * (participant_sd^2 + ar_standard_deviation^2)
)

model_summary <- tibble::tibble(
  run_id = run_id,
  placement = "Near-eye",
  formula = paste(deparse(object$formula), collapse = " "),
  family = "glmmTMB Tweedie with log link",
  observations = nrow(object$data),
  participants = nlevels(object$data$participant),
  participant_days = nlevels(object$data$participant_day),
  ar_sequences = nlevels(object$data$ar_sequence),
  maximum_sequence_hours = maximum_ar_step,
  convergence_code = fit$fit$convergence,
  convergence_message = fit$fit$message,
  positive_definite_hessian = isTRUE(fit$sdr$pdHess),
  maximum_absolute_gradient = maximum_gradient,
  singular = singular,
  participant_sd = participant_sd,
  ar_standard_deviation = ar_standard_deviation,
  rho = rho,
  random_effect_marginalization_factor =
    random_effect_marginalization_factor,
  tweedie_power = tweedie_power,
  dispersion = stats::sigma(fit),
  log_likelihood = as.numeric(stats::logLik(fit)),
  aic = stats::AIC(fit),
  lag1_pearson_residual_correlation = acf_data$correlation[acf_data$lag == 1L],
  observed_zero_fraction = mean(object$data$geo_medi_1h == 0),
  observed_to_simulated_zero_ratio = zero_ratio,
  warning_count = length(object$warnings),
  warnings = paste(object$warnings, collapse = " | "),
  elapsed_fit_seconds = object$elapsed_fit_seconds,
  inferential_role = object$inferential_role
)

message("Computing equal-site conditional means and indoor-reference ratios")
emm <- emmeans::emmeans(
  fit,
  specs = ~ light_source,
  weights = "equal"
)
means <- as.data.frame(summary(
  emm,
  infer = c(TRUE, FALSE),
  type = "response",
  level = 0.95
)) |>
  tibble::as_tibble()
mean_column <- intersect(c("response", "emmean"), names(means))
mean_lower_column <- intersect(
  c("asymp.LCL", "lower.CL", "response.LCL"),
  names(means)
)
mean_upper_column <- intersect(
  c("asymp.UCL", "upper.CL", "response.UCL"),
  names(means)
)
if (length(mean_column) != 1L ||
    length(mean_lower_column) != 1L ||
    length(mean_upper_column) != 1L) {
  h03_abort("Could not identify emmeans response columns")
}
category_means <- tibble::tibble(
  run_id = run_id,
  placement = "Near-eye",
  light_source = as.character(means$light_source),
  conditional_mean_lx = means[[mean_column]],
  conf_low_lx = means[[mean_lower_column]],
  conf_high_lx = means[[mean_upper_column]],
  model_implied_marginal_mean_lx =
    means[[mean_column]] * random_effect_marginalization_factor,
  marginalization_method = paste(
    "analytic log-normal integration using point estimates of participant",
    "and AR1 marginal variances; variance-component uncertainty excluded"
  ),
  site_weighting = "equal over nine sites",
  random_effects = "participant and AR1 latent effects set to zero"
)

ratios <- as.data.frame(summary(
  emmeans::contrast(
    emm,
    method = "trt.vs.ctrl",
    ref = 1L,
    adjust = "none"
  ),
  infer = c(TRUE, TRUE),
  type = "response",
  level = 0.95,
  adjust = "none"
)) |>
  tibble::as_tibble()
ratio_column <- intersect(c("ratio", "response"), names(ratios))
ratio_lower_column <- intersect(
  c("asymp.LCL", "lower.CL", "response.LCL"),
  names(ratios)
)
ratio_upper_column <- intersect(
  c("asymp.UCL", "upper.CL", "response.UCL"),
  names(ratios)
)
statistic_column <- intersect(c("z.ratio", "t.ratio"), names(ratios))
if (length(ratio_column) != 1L ||
    length(ratio_lower_column) != 1L ||
    length(ratio_upper_column) != 1L ||
    length(statistic_column) != 1L) {
  h03_abort("Could not identify emmeans ratio columns")
}
contrast_categories <- levels(object$data$light_source)[-1L]
category_ratios <- tibble::tibble(
  run_id = run_id,
  placement = "Near-eye",
  light_source = contrast_categories,
  reference = levels(object$data$light_source)[1L],
  ratio_to_indoor = ratios[[ratio_column]],
  conf_low = ratios[[ratio_lower_column]],
  conf_high = ratios[[ratio_upper_column]],
  statistic = ratios[[statistic_column]],
  p_value_raw = ratios$p.value,
  p_value_bh = stats::p.adjust(ratios$p.value, method = "BH"),
  multiplicity = "BH across six indoor-reference contrasts"
) |>
  dplyr::mutate(
    p_display_bh = nh_format_p_value(.data$p_value_bh),
    significant_bh = .data$p_value_bh < 0.05
  )

registry <- h03_category_registry(root) |>
  dplyr::select(
    "category_order",
    "category_code",
    light_source = "category_label"
  )
category_means <- category_means |>
  dplyr::left_join(registry, by = "light_source", relationship = "many-to-one") |>
  dplyr::arrange(.data$category_order)
category_ratios <- category_ratios |>
  dplyr::left_join(registry, by = "light_source", relationship = "many-to-one") |>
  dplyr::arrange(.data$category_order)

write_output <- function(data, stem, output_root, role) {
  metadata[[role]] <<- write_csv_artifact(
    data,
    file.path(output_root, paste0(stem, ".csv")),
    producer
  )
}
write_output(
  model_summary,
  "H03_reduced_tweedie_glmm_near_eye_pilot_model_summary",
  table_root,
  "model_summary"
)
write_output(
  category_means,
  "H03_reduced_tweedie_glmm_near_eye_pilot_category_means",
  table_root,
  "category_means"
)
write_output(
  category_ratios,
  "H03_reduced_tweedie_glmm_near_eye_pilot_category_ratios",
  table_root,
  "category_ratios"
)
write_output(
  acf_data,
  "H03_reduced_tweedie_glmm_near_eye_pilot_residual_acf",
  diagnostic_root,
  "residual_acf"
)
write_output(
  dharma_acf_data,
  "H03_reduced_tweedie_glmm_near_eye_DHARMa_100_residual_acf",
  diagnostic_root,
  "dharma_residual_acf"
)
write_output(
  dharm_summary,
  "H03_reduced_tweedie_glmm_near_eye_DHARMa_100",
  diagnostic_root,
  "dharma"
)
write_output(
  simulation_runtime,
  "H03_reduced_tweedie_glmm_near_eye_DHARMa_100_runtime",
  diagnostic_root,
  "simulation_runtime"
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
    "H03_reduced_tweedie_glmm_near_eye_pilot_environment.csv"
  ),
  producer
)
manifest <- dplyr::bind_rows(lapply(metadata, manifest_row)) |>
  dplyr::arrange(.data$path)
write_csv_artifact(
  manifest,
  file.path(
    manifest_root,
    "H03_reduced_tweedie_glmm_near_eye_pilot_manifest.csv"
  ),
  producer
)

message("H03 reduced near-eye Tweedie GLMM pilot complete")
