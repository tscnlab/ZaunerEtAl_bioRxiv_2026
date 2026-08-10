# Fit and diagnose one bounded near-eye no-time GAMM pilot for H03.

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
source(file.path(root, "scripts/hypotheses/H03/h03_temporal.R"))
source(file.path(root, "scripts/hypotheses/H03/h03_reporting.R"))

if (!identical(as.character(getRversion()), "4.6.1")) {
  h03_abort(
    "H03 no-time GAMM pilot requires R 4.6.1; found %s",
    as.character(getRversion())
  )
}

required_packages <- c(
  "dplyr", "tidyr", "tibble", "readr", "mgcv", "gratia", "emmeans",
  "ggplot2", "scales", "LightLogR", "cowplot", "patchwork", "svglite",
  "ragg"
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
  "run_h03_no_time_gamm_near_eye_pilot.R"
)
run_id <- "no_time_log_gaussian_gamm_pilot__near_eye"
nthreads <- 2L
transform_offset <- 0.1
transform_base <- 10
model_root <- file.path(root, "artifacts/07_models/H03")
diagnostic_root <- file.path(root, "artifacts/08_diagnostics/H03")
table_root <- file.path(root, "artifacts/09_tables/H03")
figure_root <- file.path(root, "artifacts/10_figures/H03")
source_root <- file.path(root, "artifacts/11_source_data/H03")
manifest_root <- file.path(root, "artifacts/12_manifests/H03")
invisible(lapply(
  c(
    model_root,
    diagnostic_root,
    table_root,
    figure_root,
    source_root,
    manifest_root
  ),
  dir.create,
  recursive = TRUE,
  showWarnings = FALSE
))

h03_existing_artifact_metadata <- function(path, producer) {
  info <- file.info(path)
  list(
    path = normalizePath(path, winslash = "/", mustWork = TRUE),
    sha256 = artifact_sha256(path),
    bytes = unname(info$size),
    producer = producer,
    r_version = as.character(getRversion()),
    written_utc = format(info$mtime, tz = "UTC", usetz = TRUE)
  )
}

log_zero_inflated <- LightLogR::log_zero_inflated
exp_zero_inflated <- LightLogR::exp_zero_inflated
formula <- stats::as.formula(paste0(
  "log_zero_inflated(geo_medi_1h) ~ light_source + site + ",
  "s(participant, bs = 're') + s(participant_day, bs = 're')"
))
s <- mgcv::s
environment(formula) <- environment()

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
  )
if (nrow(data) != 17935L ||
    nlevels(data$participant) != 140L ||
    nlevels(data$participant_day) != 801L ||
    nlevels(data$site) != 9L ||
    nlevels(data$light_source) != 7L) {
  h03_abort("Near-eye pilot frame differs from the accepted primary sample")
}

model_path <- file.path(
  model_root,
  "H03_no_time_log_gaussian_gamm_near_eye_pilot_object.rds"
)
metadata <- list()
if (file.exists(model_path)) {
  object <- readRDS(model_path)
  cache_valid <- identical(object$run_id, run_id) &&
    identical(object$nthreads, nthreads) &&
    isTRUE(all.equal(object$transform_offset, transform_offset)) &&
    isTRUE(all.equal(object$transform_base, transform_base)) &&
    identical(
      paste(deparse(object$formula), collapse = " "),
      paste(deparse(formula), collapse = " ")
    ) &&
    inherits(object$preliminary, "gam") &&
    inherits(object$final, "gam") &&
    is.finite(object$rho) &&
    nrow(object$data) == nrow(data)
  if (!cache_valid) {
    h03_abort("Existing no-time GAMM pilot cache violates its contract")
  }
  message("Using validated near-eye no-time log-Gaussian GAMM pilot cache")
  metadata$model <- h03_existing_artifact_metadata(model_path, producer)
} else {
  message(
    "Fitting the single near-eye no-time log-Gaussian GAMM pilot with two threads"
  )
  elapsed <- system.time({
    captured_preliminary <- h03_capture_warnings(mgcv::bam(
      formula = formula,
      data = data,
      method = "fREML",
      discrete = TRUE,
      nthreads = nthreads,
      gc.level = 1L,
      drop.unused.levels = TRUE
    ))
    preliminary_residual <- stats::residuals(
      captured_preliminary$value,
      type = "response"
    )
    rho_unclipped <- unname(h03_boundary_lag_correlation(
      preliminary_residual,
      data$AR_start,
      lag = 1L
    )[["correlation"]])
    if (!is.finite(rho_unclipped)) {
      h03_abort("Could not estimate boundary-aware lag-1 rho")
    }
    rho <- pmin(0.95, pmax(-0.95, rho_unclipped))
    message(sprintf("Second-run AR1 rho fixed at %.6f", rho))
    captured_final <- h03_capture_warnings(mgcv::bam(
      formula = formula,
      data = data,
      method = "fREML",
      discrete = TRUE,
      rho = rho,
      AR.start = data$AR_start,
      nthreads = nthreads,
      gc.level = 1L,
      drop.unused.levels = TRUE
    ))
  })
  object <- list(
    run_id = run_id,
    placement = "Near-eye",
    data = data,
    preliminary = captured_preliminary$value,
    final = captured_final$value,
    formula = formula,
    rho_unclipped = rho_unclipped,
    rho = rho,
    rho_estimation = paste(
      "boundary-aware lag-1 correlation of preliminary response residuals;",
      "clipped to [-0.95, 0.95]"
    ),
    transform_offset = transform_offset,
    transform_base = transform_base,
    transformation = "LightLogR::log_zero_inflated(x, offset = 0.1, base = 10)",
    family = "Gaussian identity on log10(geo_medi_1h + 0.1)",
    method = "fREML",
    discrete = TRUE,
    nthreads = nthreads,
    warnings_preliminary = unique(captured_preliminary$warnings),
    warnings_final = unique(captured_final$warnings),
    warnings = unique(c(
      captured_preliminary$warnings,
      captured_final$warnings
    )),
    elapsed_seconds = unname(elapsed[["elapsed"]]),
    inferential_role = paste(
      "bounded conditional no-time GAMM test balloon;",
      "not the accepted H03 primary model"
    )
  )
  metadata$model <- write_rds_artifact(object, model_path, producer)
}
rm(accepted)
invisible(gc())

fit <- object$final
summary_fit <- summary(fit)
response_raw <- object$data$geo_medi_1h
response_transformed <- log_zero_inflated(
  response_raw,
  offset = transform_offset,
  base = transform_base
)
fitted_full_transformed <- stats::fitted(fit)
fitted_full_raw <- exp_zero_inflated(
  fitted_full_transformed,
  offset = transform_offset,
  base = transform_base
)
random_smooths <- c("s(participant)", "s(participant_day)")
fitted_fixed_transformed <- as.numeric(stats::predict(
  fit,
  type = "response",
  exclude = random_smooths
))
fitted_fixed_raw <- exp_zero_inflated(
  fitted_fixed_transformed,
  offset = transform_offset,
  base = transform_base
)
hessian <- fit$outer.info$hess
hessian_values <- if (is.matrix(hessian) && all(is.finite(hessian))) {
  eigen(
    (hessian + t(hessian)) / 2,
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
gradient_maximum <- if (is.null(fit$outer.info$grad)) {
  NA_real_
} else {
  max(abs(fit$outer.info$grad))
}

variance_components <- dplyr::bind_rows(
  gratia::variance_comp(object$preliminary) |>
    dplyr::mutate(stage = "First run: no AR1"),
  gratia::variance_comp(object$final) |>
    dplyr::mutate(stage = "Second run: AR1 corrected")
) |>
  dplyr::mutate(
    run_id = .env$run_id,
    placement = "Near-eye",
    scale = "log10(melEDI + 0.1) scale"
  ) |>
  dplyr::relocate(.data$run_id, .data$placement, .data$stage)
random_variance <- variance_components |>
  dplyr::filter(
    .data$stage == "Second run: AR1 corrected",
    .data$.component %in% random_smooths
  )
random_effect_boundary <- any(
  random_variance$.variance < 1e-6,
  na.rm = TRUE
)

h03_smooth_table <- function(model, stage) {
  table <- summary(model)$s.table
  if (is.null(table)) {
    return(tibble::tibble())
  }
  tibble::rownames_to_column(
    as.data.frame(table),
    var = "smooth"
  ) |>
    tibble::as_tibble() |>
    dplyr::mutate(
      run_id = .env$run_id,
      placement = "Near-eye",
      stage = .env$stage
    ) |>
    dplyr::relocate(.data$run_id, .data$placement, .data$stage)
}
smooth_table <- dplyr::bind_rows(
  h03_smooth_table(object$preliminary, "First run: no AR1"),
  h03_smooth_table(object$final, "Second run: AR1 corrected")
)

model_anova <- stats::anova(fit)
parametric_tests <- if (is.null(model_anova$pTerms.table)) {
  tibble::tibble()
} else {
  tibble::rownames_to_column(
    as.data.frame(model_anova$pTerms.table),
    var = "term"
  ) |>
    tibble::as_tibble() |>
    dplyr::mutate(
      run_id = .env$run_id,
      placement = "Near-eye"
    ) |>
    dplyr::relocate(.data$run_id, .data$placement)
}

message("Computing equal-site fixed-effect category means with emmeans")
emm <- emmeans::emmeans(
  fit,
  specs = ~ light_source,
  weights = "equal"
)
means_link <- as.data.frame(summary(
  emm,
  infer = c(TRUE, FALSE),
  type = "link",
  level = 0.95
)) |>
  tibble::as_tibble()
category_means <- means_link |>
  dplyr::transmute(
    run_id = .env$run_id,
    placement = "Near-eye",
    light_source = as.character(.data$light_source),
    expected_mel_edi_lx = exp_zero_inflated(
      .data$emmean,
      offset = .env$transform_offset,
      base = .env$transform_base
    ),
    conf_low_lx = exp_zero_inflated(
      .data$lower.CL,
      offset = .env$transform_offset,
      base = .env$transform_base
    ),
    conf_high_lx = exp_zero_inflated(
      .data$upper.CL,
      offset = .env$transform_offset,
      base = .env$transform_base
    ),
    transformed_estimate = .data$emmean,
    transformed_se = .data$SE,
    df = .data$df,
    site_weighting = "equal over nine sites",
    random_effects = "participant and participant-day effects set to zero",
    interval_type = "pointwise_95_percent_conditional",
    transformation = "log10(melEDI + 0.1); inverse = 10^x - 0.1"
  )

contrast_link <- as.data.frame(summary(
  emmeans::contrast(
    emm,
    method = "trt.vs.ctrl",
    ref = 1L,
    adjust = "none"
  ),
  infer = c(TRUE, TRUE),
  type = "link",
  level = 0.95,
  adjust = "none"
)) |>
  tibble::as_tibble()
contrast_categories <- levels(object$data$light_source)[-1L]
if (nrow(contrast_link) != length(contrast_categories)) {
  h03_abort("Unexpected indoor-reference contrast count")
}
statistic_column <- intersect(c("t.ratio", "z.ratio"), names(contrast_link))
if (length(statistic_column) != 1L) {
  h03_abort("Could not identify the emmeans contrast statistic column")
}
category_ratios <- contrast_link |>
  dplyr::mutate(
    light_source = contrast_categories,
    statistic = .data[[statistic_column]],
    p_value_bh = stats::p.adjust(.data$p.value, method = "BH"),
    p_display_bh = nh_format_p_value(.data$p_value_bh),
    significant_bh = .data$p_value_bh < 0.05
  ) |>
  dplyr::transmute(
    run_id = .env$run_id,
    placement = "Near-eye",
    .data$light_source,
    reference = levels(object$data$light_source)[1L],
    ratio_to_indoor = transform_base^.data$estimate,
    conf_low = transform_base^.data$lower.CL,
    conf_high = transform_base^.data$upper.CL,
    log10_difference = .data$estimate,
    log10_difference_se = .data$SE,
    df = .data$df,
    .data$statistic,
    p_value_raw = .data$p.value,
    .data$p_value_bh,
    .data$p_display_bh,
    .data$significant_bh,
    multiplicity = "BH across six indoor-reference contrasts",
    ratio_definition = "ratio of shifted geometric means: (melEDI + 0.1)"
  )

preliminary_residual <- stats::residuals(
  object$preliminary,
  type = "response"
)
final_residual <- if (
  !is.null(fit$std.rsd) && length(fit$std.rsd) == nrow(object$data)
) {
  fit$std.rsd
} else {
  stats::residuals(fit, type = "response")
}

h03_acf_stage <- function(residual, stage) {
  dplyr::bind_rows(lapply(1:6, function(lag) {
    values <- h03_boundary_lag_correlation(
      residual,
      object$data$AR_start,
      lag = lag
    )
    tibble::tibble(
      run_id = run_id,
      placement = "Near-eye",
      stage = stage,
      lag = lag,
      correlation = unname(values[["correlation"]]),
      pairs = unname(values[["pairs"]])
    )
  }))
}
acf_data <- dplyr::bind_rows(
  h03_acf_stage(preliminary_residual, "First run: no AR1"),
  h03_acf_stage(final_residual, "Second run: AR1 corrected")
)

zero_structure <- tibble::tibble(
  run_id = run_id,
  placement = "Near-eye",
  observations = length(response_raw),
  zero_observations = sum(response_raw == 0),
  observed_zero_fraction = mean(response_raw == 0),
  transformed_zero_value = log_zero_inflated(
    0,
    offset = transform_offset,
    base = transform_base
  ),
  likelihood_zero_mass = "not modeled: Gaussian likelihood is continuous",
  interpretation = paste(
    "log_zero_inflated is a shifted base-10 log transform,",
    "not a zero-inflated probability model"
  )
)

residual_points <- tibble::tibble(
  run_id = run_id,
  placement = "Near-eye",
  participant = as.character(object$data$participant),
  participant_day = as.character(object$data$participant_day),
  fitted_transformed = fitted_full_transformed,
  fitted_mean_lx = fitted_full_raw,
  fitted_fixed_transformed = fitted_fixed_transformed,
  fitted_fixed_mean_lx = fitted_fixed_raw,
  observed_transformed = response_transformed,
  observed_mel_edi_lx = response_raw,
  ar_standardized_residual = final_residual
)
residual_bins <- residual_points |>
  dplyr::mutate(bin = dplyr::ntile(.data$fitted_mean_lx, 30L)) |>
  dplyr::group_by(.data$bin) |>
  dplyr::summarise(
    observations = dplyr::n(),
    fitted_mean_lx = stats::median(.data$fitted_mean_lx),
    residual_mean = mean(.data$ar_standardized_residual),
    residual_q25 = stats::quantile(.data$ar_standardized_residual, 0.25),
    residual_q75 = stats::quantile(.data$ar_standardized_residual, 0.75),
    .groups = "drop"
  ) |>
  dplyr::mutate(run_id = .env$run_id, placement = "Near-eye") |>
  dplyr::relocate(.data$run_id, .data$placement)

qq_probability <- (seq_along(final_residual) - 0.5) /
  length(final_residual)
qq_data <- tibble::tibble(
  run_id = run_id,
  placement = "Near-eye",
  theoretical_normal_quantile = stats::qnorm(qq_probability),
  ordered_ar_standardized_residual = sort(final_residual)
)

weight_hour <- rep(1 / nrow(object$data), nrow(object$data))
participant_count <- table(object$data$participant)
weight_participant <- 1 / as.numeric(
  participant_count[as.character(object$data$participant)]
)
weight_participant <- weight_participant / sum(weight_participant)
h03_weighted_r2 <- function(observed, prediction, weight) {
  center <- sum(weight * observed)
  1 - sum(weight * (observed - prediction)^2) /
    sum(weight * (observed - center)^2)
}
r_squared <- tibble::tribble(
  ~prediction, ~weighting, ~r_squared,
  "fixed effects only", "participant-hour weighted",
  h03_weighted_r2(
    response_transformed,
    fitted_fixed_transformed,
    weight_hour
  ),
  "full conditional fit", "participant-hour weighted",
  h03_weighted_r2(
    response_transformed,
    fitted_full_transformed,
    weight_hour
  ),
  "fixed effects only", "participant balanced",
  h03_weighted_r2(
    response_transformed,
    fitted_fixed_transformed,
    weight_participant
  ),
  "full conditional fit", "participant balanced",
  h03_weighted_r2(
    response_transformed,
    fitted_full_transformed,
    weight_participant
  )
) |>
  dplyr::mutate(
    run_id = .env$run_id,
    placement = "Near-eye",
    scale = "log10(geo_medi_1h + 0.1) squared error",
    inferential_role = "descriptive in-sample fit only"
  ) |>
  dplyr::relocate(.data$run_id, .data$placement)

residual_centered <- final_residual - mean(final_residual)
residual_standard_deviation <- stats::sd(final_residual)
residual_skewness <- mean(residual_centered^3) /
  residual_standard_deviation^3
residual_excess_kurtosis <- mean(residual_centered^4) /
  residual_standard_deviation^4 - 3
final_lag1 <- dplyr::filter(
  acf_data,
  .data$stage == "Second run: AR1 corrected",
  .data$lag == 1L
)

model_summary <- tibble::tibble(
  run_id = run_id,
  placement = "Near-eye",
  formula = paste(deparse(object$formula), collapse = " "),
  transformation = object$transformation,
  family = object$family,
  method = object$method,
  discrete = object$discrete,
  nthreads = object$nthreads,
  rho_estimate = object$rho,
  rho_estimation = object$rho_estimation,
  observations = nrow(object$data),
  participants = nlevels(object$data$participant),
  participant_days = nlevels(object$data$participant_day),
  sites = nlevels(object$data$site),
  categories = nlevels(object$data$light_source),
  rank = fit$rank,
  coefficients = length(stats::coef(fit)),
  total_edf = sum(fit$edf),
  adjusted_r_squared = summary_fit$r.sq,
  deviance_explained = summary_fit$dev.expl,
  residual_scale = summary_fit$scale,
  aic = stats::AIC(fit),
  converged = identical(h03_gam_convergence(fit), "full convergence"),
  convergence = h03_gam_convergence(fit),
  warning_count = length(object$warnings),
  warnings = paste(object$warnings, collapse = " | "),
  rank_complete = fit$rank == length(stats::coef(fit)),
  smoothing_gradient_maximum_absolute = gradient_maximum,
  smoothing_hessian_minimum_eigenvalue = hessian_minimum,
  smoothing_hessian_positive_definite = all(hessian_values > 0),
  random_effect_boundary = random_effect_boundary,
  random_effect_boundary_rule = paste(
    "final random-effect variance below 1e-6 on",
    "log10(melEDI + 0.1) scale"
  ),
  participant_day_variance = random_variance |>
    dplyr::filter(.data$.component == "s(participant_day)") |>
    dplyr::pull(.data$.variance),
  participant_day_edf = smooth_table |>
    dplyr::filter(
      .data$stage == "Second run: AR1 corrected",
      .data$smooth == "s(participant_day)"
    ) |>
    dplyr::pull(.data$edf),
  pearson_residual_lag1 = final_lag1$correlation,
  pearson_residual_lag1_pairs = final_lag1$pairs,
  absolute_residual_fitted_spearman = stats::cor(
    abs(final_residual),
    fitted_full_transformed,
    method = "spearman"
  ),
  residual_skewness = residual_skewness,
  residual_excess_kurtosis = residual_excess_kurtosis,
  observed_zero_fraction = mean(response_raw == 0),
  zero_likelihood = "continuous Gaussian; no modeled point mass",
  elapsed_seconds = object$elapsed_seconds,
  no_time_term = TRUE,
  ar1_second_run = TRUE,
  inferential_role = object$inferential_role
)

model_runs <- tibble::tibble(
  run_id = run_id,
  placement = "Near-eye",
  stage = c("First run: no AR1", "Second run: AR1 corrected"),
  rho = c(0, object$rho),
  convergence = c(
    h03_gam_convergence(object$preliminary),
    h03_gam_convergence(object$final)
  ),
  rank = c(object$preliminary$rank, object$final$rank),
  coefficients = c(
    length(stats::coef(object$preliminary)),
    length(stats::coef(object$final))
  ),
  adjusted_r_squared = c(
    summary(object$preliminary)$r.sq,
    summary(object$final)$r.sq
  ),
  deviance_explained = c(
    summary(object$preliminary)$dev.expl,
    summary(object$final)$dev.expl
  ),
  lag1_residual_correlation = c(
    dplyr::filter(
      acf_data,
      .data$stage == "First run: no AR1",
      .data$lag == 1L
    )$correlation,
    final_lag1$correlation
  ),
  participant_day_variance = variance_components |>
    dplyr::filter(.data$.component == "s(participant_day)") |>
    dplyr::arrange(factor(
      .data$stage,
      levels = c("First run: no AR1", "Second run: AR1 corrected")
    )) |>
    dplyr::pull(.data$.variance),
  participant_day_edf = smooth_table |>
    dplyr::filter(.data$smooth == "s(participant_day)") |>
    dplyr::arrange(factor(
      .data$stage,
      levels = c("First run: no AR1", "Second run: AR1 corrected")
    )) |>
    dplyr::pull(.data$edf),
  participant_day_boundary = participant_day_variance < 1e-6,
  residual_definition = c(
    "response residual",
    "mgcv AR-standardized residual"
  ),
  warnings = c(
    paste(object$warnings_preliminary, collapse = " | "),
    paste(object$warnings_final, collapse = " | ")
  )
)

registry <- h03_category_registry(root) |>
  dplyr::select(
    .data$category_order,
    .data$category_code,
    light_source = .data$category_label,
    .data$figure_label
  )
category_means <- category_means |>
  dplyr::left_join(registry, by = "light_source", relationship = "many-to-one") |>
  dplyr::arrange(.data$category_order)
category_ratios <- category_ratios |>
  dplyr::left_join(registry, by = "light_source", relationship = "many-to-one") |>
  dplyr::arrange(.data$category_order)
ratio_plot_data <- dplyr::bind_rows(
  tibble::tibble(
    light_source = levels(object$data$light_source)[1L],
    reference = levels(object$data$light_source)[1L],
    ratio_to_indoor = 1,
    conf_low = 1,
    conf_high = 1
  ) |>
    dplyr::left_join(
      registry,
      by = "light_source",
      relationship = "many-to-one"
    ),
  category_ratios
) |>
  dplyr::arrange(.data$category_order)

mean_plot <- ggplot2::ggplot(
  category_means,
  ggplot2::aes(
    x = factor(.data$figure_label, levels = registry$figure_label),
    y = .data$expected_mel_edi_lx
  )
) +
  ggplot2::geom_errorbar(
    ggplot2::aes(
      ymin = .data$conf_low_lx,
      ymax = .data$conf_high_lx
    ),
    width = 0,
    linewidth = 0.75,
    colour = "#4477AA"
  ) +
  ggplot2::geom_point(size = 3.1, colour = "#4477AA") +
  ggplot2::scale_y_continuous(
    trans = LightLogR::symlog_trans(base = 10, thr = 1, scale = 1),
    breaks = c(0, 1, 10, 100, 250, 1000, 10000),
    labels = scales::label_number(big.mark = ",")
  ) +
  ggplot2::labs(
    title = "Conditional geometric-scale category means",
    subtitle = paste(
      "Sites weighted equally; participant and participant-day",
      "random effects set to zero"
    ),
    x = NULL,
    y = "Expected one-hour melEDI (lx)"
  ) +
  h03_figure_theme()

ratio_plot <- ggplot2::ggplot(
  ratio_plot_data,
  ggplot2::aes(
    x = factor(.data$figure_label, levels = registry$figure_label),
    y = .data$ratio_to_indoor
  )
) +
  ggplot2::geom_hline(
    yintercept = 1,
    linetype = "dashed",
    colour = "grey45"
  ) +
  ggplot2::geom_errorbar(
    ggplot2::aes(ymin = .data$conf_low, ymax = .data$conf_high),
    width = 0,
    linewidth = 0.75,
    colour = "#AA3377"
  ) +
  ggplot2::geom_point(size = 3.1, colour = "#AA3377") +
  ggplot2::scale_y_log10(
    breaks = c(0.01, 0.03, 0.1, 0.3, 1, 3, 10, 30),
    labels = scales::label_number(accuracy = 0.01)
  ) +
  ggplot2::labs(
    title = "Conditional factor relative to indoor electric light",
    subtitle = paste(
      "Factors compare shifted geometric means (melEDI + 0.1);",
      "table P-values use BH adjustment"
    ),
    x = NULL,
    y = "Ratio"
  ) +
  h03_figure_theme()

result_figure <- patchwork::wrap_plots(
  mean_plot,
  ratio_plot,
  ncol = 1,
  heights = c(1.05, 1)
) +
  patchwork::plot_annotation(
    tag_levels = "A",
    caption = paste(
      "This is a bounded conditional GAMM test balloon, not the accepted",
      "H03 primary analysis. Intervals use the fitted GAMM covariance."
    ),
    theme = h03_figure_theme()
  )

residual_plot <- ggplot2::ggplot(
  residual_points,
  ggplot2::aes(
    x = .data$fitted_mean_lx,
    y = .data$ar_standardized_residual
  )
) +
  ggplot2::geom_hline(yintercept = 0, linetype = "dashed", colour = "grey45") +
  ggplot2::geom_point(alpha = 0.08, size = 0.45, colour = "#4477AA") +
  ggplot2::geom_ribbon(
    data = residual_bins,
    ggplot2::aes(
      x = .data$fitted_mean_lx,
      ymin = .data$residual_q25,
      ymax = .data$residual_q75
    ),
    inherit.aes = FALSE,
    fill = "#4477AA",
    alpha = 0.16
  ) +
  ggplot2::geom_line(
    data = residual_bins,
    ggplot2::aes(x = .data$fitted_mean_lx, y = .data$residual_mean),
    inherit.aes = FALSE,
    colour = "#225588",
    linewidth = 0.9
  ) +
  ggplot2::scale_x_continuous(
    trans = LightLogR::symlog_trans(base = 10, thr = 1, scale = 1),
    breaks = c(0, 1, 10, 100, 1000, 10000)
  ) +
  ggplot2::labs(
    title = "AR-standardized residuals versus fitted means",
    x = "Fitted conditional mean (lx)",
    y = "AR-standardized residual"
  ) +
  h03_figure_theme()

qq_plot <- ggplot2::ggplot(
  qq_data,
  ggplot2::aes(
    x = .data$theoretical_normal_quantile,
    y = .data$ordered_ar_standardized_residual
  )
) +
  ggplot2::stat_qq_line(
    ggplot2::aes(sample = .data$ordered_ar_standardized_residual),
    inherit.aes = FALSE,
    colour = "grey55"
  ) +
  ggplot2::geom_point(alpha = 0.18, size = 0.6, colour = "#228833") +
  ggplot2::labs(
    title = "AR-standardized residual Q-Q reference",
    x = "Theoretical normal quantile",
    y = "Ordered residual"
  ) +
  h03_figure_theme()

acf_plot <- ggplot2::ggplot(
  acf_data,
  ggplot2::aes(
    x = .data$lag,
    y = .data$correlation,
    colour = .data$stage
  )
) +
  ggplot2::geom_hline(yintercept = 0, colour = "grey55") +
  ggplot2::geom_line(linewidth = 0.85) +
  ggplot2::geom_point(size = 2.5) +
  ggplot2::scale_x_continuous(breaks = 1:6) +
  ggplot2::scale_colour_manual(
    values = c(
      "First run: no AR1" = "#AA3377",
      "Second run: AR1 corrected" = "#0072B2"
    )
  ) +
  ggplot2::labs(
    title = "Boundary-aware residual autocorrelation",
    x = "Lag (hours)",
    y = "Residual correlation",
    colour = NULL
  ) +
  h03_figure_theme() +
  ggplot2::theme(legend.position = "top")

response_plot <- ggplot2::ggplot(
  residual_points,
  ggplot2::aes(x = .data$observed_transformed)
) +
  ggplot2::geom_histogram(
    binwidth = 0.1,
    boundary = -1,
    colour = "white",
    fill = "#4477AA"
  ) +
  ggplot2::geom_vline(
    xintercept = -1,
    linetype = "dashed",
    colour = "#D55E00"
  ) +
  ggplot2::labs(
    title = "Shifted-log response distribution",
    subtitle = "Observed zeros map to -1; the Gaussian likelihood is continuous",
    x = expression(log[10](melEDI + 0.1)),
    y = "Participant-hours"
  ) +
  h03_figure_theme()

diagnostic_figure <- patchwork::wrap_plots(
  residual_plot,
  qq_plot,
  acf_plot,
  response_plot,
  ncol = 2
) +
  patchwork::plot_annotation(
    tag_levels = "A",
    caption = paste(
      "Individual AR-standardized residuals, a Gaussian distributional",
      "reference, first- versus second-run within-sequence dependence,",
      "and the shifted-log response distribution."
    ),
    theme = h03_figure_theme()
  )

write_output <- function(data, stem, root_path, role) {
  metadata[[role]] <<- write_csv_artifact(
    data,
    file.path(root_path, paste0(stem, ".csv")),
    producer
  )
}
write_output(
  model_summary,
  "H03_no_time_gamm_near_eye_pilot_model_summary",
  table_root,
  "model_summary"
)
write_output(
  model_runs,
  "H03_no_time_gamm_near_eye_pilot_model_runs",
  table_root,
  "model_runs"
)
write_output(
  category_means,
  "H03_no_time_gamm_near_eye_pilot_category_means",
  table_root,
  "category_means"
)
write_output(
  category_ratios,
  "H03_no_time_gamm_near_eye_pilot_category_ratios",
  table_root,
  "category_ratios"
)
write_output(
  parametric_tests,
  "H03_no_time_gamm_near_eye_pilot_parametric_tests",
  table_root,
  "parametric_tests"
)
write_output(
  variance_components,
  "H03_no_time_gamm_near_eye_pilot_variance_components",
  table_root,
  "variance_components"
)
write_output(
  smooth_table,
  "H03_no_time_gamm_near_eye_pilot_smooth_table",
  table_root,
  "smooth_table"
)
write_output(
  r_squared,
  "H03_no_time_gamm_near_eye_pilot_r_squared",
  table_root,
  "r_squared"
)
write_output(
  acf_data,
  "H03_no_time_gamm_near_eye_pilot_residual_acf",
  diagnostic_root,
  "residual_acf"
)
write_output(
  zero_structure,
  "H03_no_time_gamm_near_eye_pilot_zero_structure",
  diagnostic_root,
  "zero_structure"
)
write_output(
  residual_bins,
  "H03_no_time_gamm_near_eye_pilot_residual_bins",
  diagnostic_root,
  "residual_bins"
)
write_output(
  residual_points,
  "H03_no_time_gamm_near_eye_pilot_residual_points",
  source_root,
  "residual_points"
)
write_output(
  qq_data,
  "H03_no_time_gamm_near_eye_pilot_qq_data",
  source_root,
  "qq_data"
)

result_saved <- h03_save_plot(
  result_figure,
  "H03_no_time_gamm_near_eye_pilot_results",
  figure_root,
  width = 12,
  height = 10,
  producer = producer
)
diagnostic_saved <- h03_save_plot(
  diagnostic_figure,
  "H03_no_time_gamm_near_eye_pilot_diagnostics",
  figure_root,
  width = 14,
  height = 10,
  producer = producer
)
for (extension in names(result_saved)) {
  metadata[[paste0("result_figure_", extension)]] <-
    result_saved[[extension]]
}
for (extension in names(diagnostic_saved)) {
  metadata[[paste0("diagnostic_figure_", extension)]] <-
    diagnostic_saved[[extension]]
}

environment <- tibble::tibble(
  component = c("R", required_packages),
  version = c(
    as.character(getRversion()),
    vapply(
      required_packages,
      function(package) as.character(utils::packageVersion(package)),
      character(1)
    )
  ),
  nthreads = nthreads
)
metadata$environment <- write_csv_artifact(
  environment,
  file.path(
    manifest_root,
    "H03_no_time_gamm_near_eye_pilot_environment.csv"
  ),
  producer
)
manifest <- dplyr::bind_rows(lapply(metadata, manifest_row)) |>
  dplyr::arrange(.data$path)
write_csv_artifact(
  manifest,
  file.path(
    manifest_root,
    "H03_no_time_gamm_near_eye_pilot_manifest.csv"
  ),
  producer
)
message("H03 near-eye no-time log-Gaussian GAMM test balloon complete")
