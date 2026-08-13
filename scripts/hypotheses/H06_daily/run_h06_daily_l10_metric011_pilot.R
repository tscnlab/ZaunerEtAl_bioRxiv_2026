#!/usr/bin/env Rscript

# Timed serial production-code pilot for the first METRIC-011 scenario.

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
options(contrasts = c("contr.treatment", "contr.poly"))

required_packages <- c(
  "digest", "dplyr", "glmmTMB", "lme4", "performance", "readr", "tibble"
)
stopifnot(
  identical(as.character(getRversion()), "4.6.1"),
  all(vapply(required_packages, requireNamespace, logical(1), quietly = TRUE))
)

source(file.path(
  root,
  "scripts/hypotheses/H06_daily/h06_daily_l10_metric011_contract.R"
))
source(file.path(
  root,
  "scripts/hypotheses/H06_daily/h06_daily_l10_metric011_data.R"
))
source(file.path(
  root,
  "scripts/hypotheses/H06_daily/h06_daily_l10_metric011_modeling.R"
))

roots <- h06d_l10_artifact_roots(root)
static_verdict <- readr::read_csv(
  file.path(roots$diagnostics, "H06_daily_l10_metric011_static_verdict.csv"),
  show_col_types = FALSE
)
h06d_l10_assert(
  nrow(static_verdict) == 1L &&
    static_verdict$disposition == "PASS_STATIC_GATE_MODEL_PILOT_ALLOWED" &&
    static_verdict$model_fits_run == 0L,
  "METRIC-011 production pilot requires the no-fit static gate"
)
protected <- readr::read_csv(
  file.path(roots$diagnostics, "H06_daily_l10_metric011_protected_baseline.csv"),
  show_col_types = FALSE
)
h06d_l10_assert(
  all(file.exists(file.path(root, protected$relative_path))) &&
    all(vapply(
      file.path(root, protected$relative_path),
      h06d_l10_sha256,
      character(1)
    ) == protected$sha256_before),
  "A protected pre-existing H06_daily artifact changed before the pilot"
)

registry <- readr::read_csv(
  file.path(roots$model_data, "H06_daily_l10_metric011_frame_registry.csv"),
  show_col_types = FALSE
)
pilot_registry <- registry |>
  dplyr::filter(
    .data$run_id == "primary__near_eye__all_available",
    .data$predictor_id == "work_free_day"
  )
h06d_l10_assert(nrow(pilot_registry) == 2L, "Pilot component registry failed")

read_frame <- function(component) {
  row <- pilot_registry |>
    dplyr::filter(.data$component == .env$component)
  frame <- readRDS(file.path(root, row$frame_path[[1L]]))
  h06d_l10_assert(
    h06d_l10_object_sha256(frame) == row$frame_object_sha256[[1L]] &&
      h06d_l10_sha256(file.path(root, row$frame_path[[1L]])) ==
        row$frame_file_sha256[[1L]],
    "Pilot frame identity failed for `%s`",
    component
  )
  frame
}

occurrence_frame <- read_frame("zero_occurrence")
positive_frame <- read_frame("positive_magnitude")
predictor <- h06d_l10_predictor_registry() |>
  dplyr::filter(.data$predictor_id == "work_free_day")
formulas <- h06d_l10_formula_set(predictor$column[[1L]])

started_all <- proc.time()[["elapsed"]]

occurrence_additive <- h06d_l10_fit_occurrence(
  occurrence_frame,
  formulas$fixed_site_additive
)
positive_additive <- h06d_l10_fit_positive_gaussian(
  positive_frame,
  formulas$fixed_site_additive,
  REML = TRUE
)
positive_t <- h06d_l10_fit_positive_t(
  positive_frame,
  formulas$fixed_site_additive,
  REML = TRUE
)
one_part <- h06d_l10_fit_one_part(
  occurrence_frame,
  formulas$fixed_site_additive,
  REML = TRUE
)
h06d_l10_assert(
  !is.null(occurrence_additive$value) &&
    !is.null(positive_additive$value) &&
    !is.null(positive_t$value) &&
    !is.null(one_part$value),
  "A core METRIC-011 pilot model failed"
)

occurrence_reduced <- h06d_l10_fit_occurrence(
  occurrence_frame,
  formulas$fixed_site_reduced
)
occurrence_heterogeneity <- h06d_l10_fit_occurrence(
  occurrence_frame,
  formulas$fixed_site_heterogeneity
)
positive_reduced <- h06d_l10_fit_positive_gaussian(
  positive_frame,
  formulas$fixed_site_reduced,
  REML = FALSE
)
positive_additive_ml <- h06d_l10_fit_positive_gaussian(
  positive_frame,
  formulas$fixed_site_additive,
  REML = FALSE
)
positive_heterogeneity <- h06d_l10_fit_positive_gaussian(
  positive_frame,
  formulas$fixed_site_heterogeneity,
  REML = FALSE
)
h06d_l10_assert(
  all(vapply(
    list(
      occurrence_reduced,
      occurrence_heterogeneity,
      positive_reduced,
      positive_additive_ml,
      positive_heterogeneity
    ),
    function(fit) !is.null(fit$value),
    logical(1)
  )),
  "A hierarchy METRIC-011 pilot model failed"
)

occurrence_registered <- h06d_l10_fit_occurrence(
  occurrence_frame,
  formulas$registered_random_site
)
positive_registered <- h06d_l10_fit_positive_gaussian(
  positive_frame,
  formulas$registered_random_site,
  REML = TRUE
)

occurrence_residual <- as.numeric(stats::residuals(
  occurrence_additive$value,
  type = "pearson"
))
positive_residual <- as.numeric(stats::residuals(positive_additive$value))
occurrence_lag <- h06d_l10_lag_screen(occurrence_frame, occurrence_residual)
positive_lag <- h06d_l10_lag_screen(positive_frame, positive_residual)

occurrence_ar <- NULL
positive_ar <- NULL
if (
  isTRUE(occurrence_lag$overall$ar_trigger) &&
    isTRUE(occurrence_lag$overall$ar_support_adequate)
) {
  occurrence_ar <- h06d_l10_fit_ar(
    occurrence_frame,
    h06d_l10_formula_set(predictor$column[[1L]], ar = TRUE)$fixed_site_additive,
    "zero_occurrence"
  )
}
if (
  isTRUE(positive_lag$overall$ar_trigger) &&
    isTRUE(positive_lag$overall$ar_support_adequate)
) {
  positive_ar <- h06d_l10_fit_ar(
    positive_frame,
    h06d_l10_formula_set(predictor$column[[1L]], ar = TRUE)$fixed_site_additive,
    "positive_magnitude"
  )
}

association_test <- h06d_l10_combined_lrt(
  h06d_l10_lrt_row(
    occurrence_reduced$value,
    occurrence_additive$value,
    "zero_occurrence"
  ),
  h06d_l10_lrt_row(
    positive_reduced$value,
    positive_additive_ml$value,
    "positive_magnitude"
  ),
  "association"
)
heterogeneity_test <- h06d_l10_combined_lrt(
  h06d_l10_lrt_row(
    occurrence_additive$value,
    occurrence_heterogeneity$value,
    "zero_occurrence"
  ),
  h06d_l10_lrt_row(
    positive_additive_ml$value,
    positive_heterogeneity$value,
    "positive_magnitude"
  ),
  "site_heterogeneity"
)

effects <- dplyr::bind_rows(
  h06d_l10_effect_row(
    occurrence_additive$value,
    predictor,
    "zero_occurrence",
    "binomial logit"
  ),
  h06d_l10_effect_row(
    positive_additive$value,
    predictor,
    "positive_magnitude",
    "Gaussian identity on log10-positive L10"
  ),
  h06d_l10_effect_row(
    positive_t$value,
    predictor,
    "positive_magnitude",
    "Student-t identity on log10-positive L10 sensitivity"
  ),
  h06d_l10_effect_row(
    one_part$value,
    predictor,
    "positive_magnitude",
    "one-part Gaussian identity on log10(L10 + 0.1) sensitivity"
  )
)

component_diagnostics <- dplyr::bind_rows(
  dplyr::bind_cols(
    tibble::tibble(component = "zero_occurrence"),
    h06d_l10_model_status(occurrence_additive$value),
    h06d_l10_occurrence_diagnostics(occurrence_additive$value, occurrence_frame)
  ),
  dplyr::bind_cols(
    tibble::tibble(component = "positive_magnitude"),
    h06d_l10_model_status(positive_additive$value),
    h06d_l10_positive_diagnostics(positive_additive$value, positive_frame)
  )
)

lag_overall <- dplyr::bind_rows(
  occurrence_lag$overall |>
    dplyr::mutate(component = "zero_occurrence", .before = 1L),
  positive_lag$overall |>
    dplyr::mutate(component = "positive_magnitude", .before = 1L)
)
lag_by_site <- dplyr::bind_rows(
  occurrence_lag$by_site |>
    dplyr::mutate(component = "zero_occurrence", .before = 1L),
  positive_lag$by_site |>
    dplyr::mutate(component = "positive_magnitude", .before = 1L)
)

ar_summary <- dplyr::bind_rows(lapply(
  c("zero_occurrence", "positive_magnitude"),
  function(component) {
    lag <- if (component == "zero_occurrence") occurrence_lag else positive_lag
    fit <- if (component == "zero_occurrence") occurrence_ar else positive_ar
    primary <- if (component == "zero_occurrence") {
      occurrence_additive$value
    } else {
      positive_additive$value
    }
    primary_effect <- h06d_l10_effect_row(
      primary,
      predictor,
      component,
      "primary"
    )
    if (is.null(fit) || is.null(fit$value)) {
      return(tibble::tibble(
        component = component,
        ar_trigger = lag$overall$ar_trigger,
        ar_support_adequate = lag$overall$ar_support_adequate,
        ar_fitted = FALSE,
        ar_rho = NA_real_,
        effect_shift_in_primary_se = NA_real_,
        ar_acceptable = !lag$overall$ar_trigger,
        disposition = ifelse(
          lag$overall$ar_trigger,
          "TRIGGERED_BUT_NOT_ESTIMABLE_IN_PILOT",
          "NOT_TRIGGERED"
        )
      ))
    }
    ar_effect <- h06d_l10_effect_row(
      fit$value,
      predictor,
      component,
      "gap-aware daily AR(1) counterpart"
    )
    ar_parameter <- h06d_l10_ar_parameters(fit$value)
    shift <- abs(ar_effect$link_estimate - primary_effect$link_estimate) /
      primary_effect$link_standard_error
    status <- h06d_l10_model_status(fit$value)
    acceptable <- isTRUE(status$converged) &&
      is.finite(ar_parameter$ar_rho) &&
      abs(ar_parameter$ar_rho) < 0.95 && shift < 1
    tibble::tibble(
      component = component,
      ar_trigger = lag$overall$ar_trigger,
      ar_support_adequate = lag$overall$ar_support_adequate,
      ar_fitted = TRUE,
      ar_rho = ar_parameter$ar_rho,
      effect_shift_in_primary_se = shift,
      ar_acceptable = acceptable,
      disposition = ifelse(acceptable, "ACCEPTABLE", "NOT_ACCEPTABLE")
    )
  }
))

registered_benchmark <- dplyr::bind_rows(
  h06d_l10_registered_status(occurrence_registered$value, occurrence_registered) |>
    dplyr::mutate(component = "zero_occurrence", .before = 1L),
  h06d_l10_registered_status(positive_registered$value, positive_registered) |>
    dplyr::mutate(component = "positive_magnitude", .before = 1L)
)

fit_captures <- list(
  occurrence_additive = occurrence_additive,
  positive_additive = positive_additive,
  positive_t = positive_t,
  one_part = one_part,
  occurrence_reduced = occurrence_reduced,
  occurrence_heterogeneity = occurrence_heterogeneity,
  positive_reduced = positive_reduced,
  positive_additive_ml = positive_additive_ml,
  positive_heterogeneity = positive_heterogeneity,
  occurrence_registered = occurrence_registered,
  positive_registered = positive_registered,
  occurrence_ar = occurrence_ar,
  positive_ar = positive_ar
)
runtime_detail <- dplyr::bind_rows(lapply(names(fit_captures), function(name) {
  capture <- fit_captures[[name]]
  tibble::tibble(
    fit_id = name,
    elapsed_seconds = if (is.null(capture)) 0 else capture$elapsed_seconds,
    fitted = !is.null(capture) && !is.null(capture$value),
    warning_count = if (is.null(capture)) 0L else length(capture$warnings),
    fit_error = if (is.null(capture)) NA_character_ else capture$error
  )
}))

core_ids <- c(
  "occurrence_additive", "positive_additive", "positive_t", "one_part"
)
hierarchy_ids <- c(
  "occurrence_reduced", "occurrence_heterogeneity", "positive_reduced",
  "positive_additive_ml", "positive_heterogeneity", "occurrence_registered",
  "positive_registered"
)
ar_ids <- c("occurrence_ar", "positive_ar")
projected_seconds <-
  sum(runtime_detail$elapsed_seconds[runtime_detail$fit_id %in% core_ids]) * 18 +
  sum(runtime_detail$elapsed_seconds[runtime_detail$fit_id %in% hierarchy_ids]) * 6 +
  sum(runtime_detail$elapsed_seconds[runtime_detail$fit_id %in% ar_ids]) * 18
projected_seconds <- projected_seconds * 1.25
runtime_projection <- tibble::tibble(
  pilot_scenario = "primary__near_eye__all_available__work_free_day",
  pilot_wall_seconds = unname(proc.time()[["elapsed"]] - started_all),
  fitted_model_calls = sum(runtime_detail$fitted),
  projected_production_seconds = projected_seconds,
  projected_production_minutes = projected_seconds / 60,
  heavy_batch_threshold_minutes = 2,
  classified_heavy = projected_seconds / 60 >= 2,
  authorization_disposition = ifelse(
    projected_seconds / 60 >= 2,
    "STOP_FOR_FULL_BATCH_APPROVAL",
    "BOUNDED_NOT_HEAVY_MAY_PROCEED"
  )
)

positive_primary <- effects |>
  dplyr::filter(
    .data$family == "Gaussian identity on log10-positive L10"
  )
positive_t_effect <- effects |>
  dplyr::filter(grepl("Student-t", .data$family, fixed = TRUE))
t_shift <- abs(
  positive_t_effect$link_estimate - positive_primary$link_estimate
) / positive_primary$link_standard_error
pilot_verdict <- tibble::tibble(
  gate = "H06-D-G2P-L10-METRIC011-PILOT",
  occurrence_converged = component_diagnostics$converged[
    component_diagnostics$component == "zero_occurrence"
  ],
  occurrence_separation_flag = component_diagnostics$separation_flag[
    component_diagnostics$component == "zero_occurrence"
  ],
  positive_converged = component_diagnostics$converged[
    component_diagnostics$component == "positive_magnitude"
  ],
  positive_qq_correlation = component_diagnostics$residual_qq_correlation[
    component_diagnostics$component == "positive_magnitude"
  ],
  positive_t_effect_shift_in_primary_se = t_shift,
  all_triggered_ar_acceptable = all(ar_summary$ar_acceptable),
  projected_minutes = runtime_projection$projected_production_minutes,
  classified_heavy = runtime_projection$classified_heavy,
  disposition = ifelse(
    runtime_projection$classified_heavy,
    "STOP_FOR_FULL_BATCH_APPROVAL",
    "PILOT_COMPLETE_BOUNDED_PRODUCTION_ALLOWED"
  )
)

model_bundle <- list(
  pilot_registry = pilot_registry,
  occurrence_frame_sha256 = h06d_l10_object_sha256(occurrence_frame),
  positive_frame_sha256 = h06d_l10_object_sha256(positive_frame),
  fits = fit_captures,
  effects = effects,
  model_tests = dplyr::bind_rows(association_test, heterogeneity_test),
  diagnostics = component_diagnostics,
  lag_overall = lag_overall,
  ar_summary = ar_summary,
  registered_benchmark = registered_benchmark,
  runtime_projection = runtime_projection,
  r_version = as.character(getRversion()),
  package_versions = vapply(
    required_packages,
    function(package) as.character(utils::packageVersion(package)),
    character(1)
  )
)
saveRDS(
  model_bundle,
  file.path(roots$models, "H06_daily_l10_metric011_production_pilot.rds"),
  compress = "xz"
)

outputs <- list(
  "artifacts/09_tables/H06_daily/H06_daily_l10_metric011_pilot_effects.csv" =
    effects,
  "artifacts/09_tables/H06_daily/H06_daily_l10_metric011_pilot_model_tests.csv" =
    dplyr::bind_rows(association_test, heterogeneity_test),
  "artifacts/08_diagnostics/H06_daily/H06_daily_l10_metric011_pilot_component_diagnostics.csv" =
    component_diagnostics,
  "artifacts/08_diagnostics/H06_daily/H06_daily_l10_metric011_pilot_lag_overall.csv" =
    lag_overall,
  "artifacts/08_diagnostics/H06_daily/H06_daily_l10_metric011_pilot_lag_by_site.csv" =
    lag_by_site,
  "artifacts/08_diagnostics/H06_daily/H06_daily_l10_metric011_pilot_ar_summary.csv" =
    ar_summary,
  "artifacts/08_diagnostics/H06_daily/H06_daily_l10_metric011_pilot_registered_benchmark.csv" =
    registered_benchmark,
  "artifacts/08_diagnostics/H06_daily/H06_daily_l10_metric011_pilot_runtime_detail.csv" =
    runtime_detail,
  "artifacts/08_diagnostics/H06_daily/H06_daily_l10_metric011_pilot_runtime_projection.csv" =
    runtime_projection,
  "artifacts/08_diagnostics/H06_daily/H06_daily_l10_metric011_pilot_verdict.csv" =
    pilot_verdict
)
for (path in names(outputs)) {
  readr::write_csv(outputs[[path]], file.path(root, path))
}

message(
  "METRIC-011 production-code pilot complete in ",
  sprintf("%.2f", runtime_projection$pilot_wall_seconds),
  " s; projected production ",
  sprintf("%.2f", runtime_projection$projected_production_minutes),
  " min (",
  runtime_projection$authorization_disposition,
  ")."
)
