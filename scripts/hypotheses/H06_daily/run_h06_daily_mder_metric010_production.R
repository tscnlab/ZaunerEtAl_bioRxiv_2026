#!/usr/bin/env Rscript

# Fit and diagnose the METRIC-010 portion of the approved H06_daily route.
# Non-MDER outcomes are neither read nor refitted.

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

required_packages <- c(
  "digest", "dplyr", "emmeans", "glmmTMB", "lme4", "performance",
  "readr", "tibble", "tidyr"
)
stopifnot(
  identical(as.character(getRversion()), "4.6.1"),
  all(vapply(required_packages, requireNamespace, logical(1), quietly = TRUE))
)

source(file.path(
  root,
  "scripts/hypotheses/H06_daily/h06_daily_mder_metric010_contract.R"
))
source(file.path(
  root,
  "scripts/hypotheses/H06_daily/h06_daily_mder_metric010_data.R"
))
source(file.path(
  root,
  "scripts/hypotheses/H06_daily/h06_daily_mder_metric010_modeling.R"
))

roots <- h06d_m10_artifact_roots(root)
producer <- paste0(
  "scripts/hypotheses/H06_daily/",
  "run_h06_daily_mder_metric010_production.R"
)
frame_registry_path <- paste0(
  "artifacts/06_model_data/H06_daily/",
  "H06_daily_mder_metric010_frame_registry.csv"
)
metric_slot_path <- paste0(
  "artifacts/06_model_data/H06_daily/",
  "H06_daily_mder_metric010_metric_slot_registry.csv"
)
family_verdict_path <- paste0(
  "artifacts/08_diagnostics/H06_daily/",
  "H06_daily_mder_metric010_family_pilot_verdict.csv"
)
influence_runtime_path <- paste0(
  "artifacts/08_diagnostics/H06_daily/",
  "H06_daily_mder_metric010_influence_runtime_projection.csv"
)
frame_registry <- readr::read_csv(
  file.path(root, frame_registry_path),
  show_col_types = FALSE
)
metric_slots <- readr::read_csv(
  file.path(root, metric_slot_path),
  show_col_types = FALSE
)
family_verdict <- readr::read_csv(
  file.path(root, family_verdict_path),
  show_col_types = FALSE
)
influence_runtime <- readr::read_csv(
  file.path(root, influence_runtime_path),
  show_col_types = FALSE
)
h06d_m10_assert(
  all(grepl("RETAIN_GAUSSIAN_IDENTITY", family_verdict$family_disposition)),
  "Production requires the passed METRIC-010 family pilot"
)
h06d_m10_assert(
  all(!influence_runtime$classified_heavy) &&
    all(influence_runtime$pilot_failures == 0L),
  "Production influence work still requires a runtime gate"
)
h06d_m10_assert(
  nrow(frame_registry) == 36L && nrow(metric_slots) == 15L,
  "METRIC-010 production registry is incomplete"
)

refresh_scope <- Sys.getenv("H06D_M10_REFRESH_SCOPE", unset = "full")
h06d_m10_assert(
  refresh_scope %in% c("full", "metric010_gap_refresh"),
  "Unknown METRIC-010 production refresh scope"
)
targeted_gap_refresh <- identical(refresh_scope, "metric010_gap_refresh")
affected_registry <- frame_registry |>
  dplyr::filter(
    .data$dataset_id == "gap_timing_unaware" |
      .data$sample_role == "dataset_common"
  )
fit_registry <- if (targeted_gap_refresh) affected_registry else frame_registry
h06d_m10_assert(
  !targeted_gap_refresh || nrow(fit_registry) == 24L,
  "The bounded METRIC-010 gap refresh must contain exactly 24 affected frames"
)

production_paths <- c(
  effects = "artifacts/09_tables/H06_daily/H06_daily_mder_metric010_effect_estimates.csv",
  model_tests = "artifacts/09_tables/H06_daily/H06_daily_mder_metric010_model_tests.csv",
  bh_slots = "artifacts/09_tables/H06_daily/H06_daily_mder_metric010_bh_slot_families.csv",
  diagnostics = "artifacts/08_diagnostics/H06_daily/H06_daily_mder_metric010_model_diagnostics.csv",
  lag_by_site = "artifacts/08_diagnostics/H06_daily/H06_daily_mder_metric010_site_residual_lag.csv",
  ar_counterparts = "artifacts/08_diagnostics/H06_daily/H06_daily_mder_metric010_ar_counterparts.csv",
  registered_benchmark = "artifacts/08_diagnostics/H06_daily/H06_daily_mder_metric010_registered_benchmark.csv",
  heterogeneity_site = "artifacts/09_tables/H06_daily/H06_daily_mder_metric010_site_heterogeneity_estimates.csv",
  participant_influence = "artifacts/08_diagnostics/H06_daily/H06_daily_mder_metric010_participant_deletion_influence.csv",
  site_influence = "artifacts/08_diagnostics/H06_daily/H06_daily_mder_metric010_site_deletion_influence.csv",
  influence_summary = "artifacts/08_diagnostics/H06_daily/H06_daily_mder_metric010_influence_summary.csv",
  production_verdict = "artifacts/08_diagnostics/H06_daily/H06_daily_mder_metric010_production_verdict.csv",
  runtime = "artifacts/08_diagnostics/H06_daily/H06_daily_mder_metric010_production_runtime.csv"
)
model_relative <- paste0(
  "artifacts/07_models/H06_daily/",
  "H06_daily_mder_metric010_production_models.rds"
)
previous_output_manifest_relative <- paste0(
  "artifacts/12_manifests/H06_daily/",
  "H06_daily_mder_metric010_production_output_manifest.csv"
)
frozen_outputs <- NULL
previous_output_manifest <- NULL
previous_output_manifest_sha256 <- NA_character_
if (targeted_gap_refresh) {
  previous_output_manifest <- readr::read_csv(
    file.path(root, previous_output_manifest_relative),
    show_col_types = FALSE
  )
  previous_output_manifest_sha256 <- h06d_m10_sha256(file.path(
    root,
    previous_output_manifest_relative
  ))
  h06d_m10_assert(
    all(
      file.exists(file.path(root, previous_output_manifest$relative_path))
    ) &&
      all(vapply(
        file.path(root, previous_output_manifest$relative_path),
        h06d_m10_sha256,
        character(1)
      ) == previous_output_manifest$sha256),
    "A pre-refresh METRIC-010 production artifact is not at its frozen hash"
  )
  frozen_outputs <- lapply(
    production_paths,
    function(path) readr::read_csv(file.path(root, path), show_col_types = FALSE)
  )
}

predictors <- h06d_m10_predictor_registry()
model_bundle <- if (targeted_gap_refresh) {
  readRDS(file.path(root, model_relative))
} else {
  list()
}
effect_rows <- list()
diagnostic_rows <- list()
lag_site_rows <- list()
ar_rows <- list()
test_rows <- list()
benchmark_rows <- list()
heterogeneity_rows <- list()
runtime_rows <- list()

started_all <- proc.time()[["elapsed"]]

extract_site_heterogeneity <- function(model, predictor, run_id) {
  column <- predictor$column[[1L]]
  if (predictor$type[[1L]] == "categorical") {
    grid <- emmeans::emmeans(
      model,
      specs = stats::as.formula(sprintf("~ %s | site", column)),
      weights = "equal"
    )
    contrast <- emmeans::contrast(
      grid,
      method = list("contrast" = c(-1, 1))
    )
    output <- as.data.frame(summary(contrast, infer = c(TRUE, FALSE))) |>
      dplyr::transmute(
        site = as.character(.data$site),
        estimate = .data$estimate,
        standard_error = .data$SE,
        lower_95 = .data$lower.CL,
        upper_95 = .data$upper.CL
      )
  } else {
    trend <- emmeans::emtrends(model, specs = "site", var = column)
    output <- as.data.frame(summary(trend, infer = c(TRUE, FALSE)))
    trend_column <- grep("\\.trend$", names(output), value = TRUE)
    h06d_m10_assert(
      length(trend_column) == 1L,
      "Could not identify METRIC-010 continuous site trend"
    )
    output <- output |>
      dplyr::transmute(
        site = as.character(.data$site),
        estimate = .data[[trend_column]],
        standard_error = .data$SE,
        lower_95 = .data$lower.CL,
        upper_95 = .data$upper.CL
      )
  }
  output |>
    dplyr::mutate(
      run_id = .env$run_id,
      predictor_order = predictor$predictor_order[[1L]],
      predictor_id = predictor$predictor_id[[1L]],
      contrast = predictor$contrast_label[[1L]],
      inferential_role = "descriptive site-specific heterogeneity estimate"
    ) |>
    dplyr::select(
      "run_id", "predictor_order", "predictor_id", "contrast", "site",
      "estimate", "standard_error", "lower_95", "upper_95",
      "inferential_role"
    )
}

for (registry_index in seq_len(nrow(fit_registry))) {
  registry <- fit_registry[registry_index, ]
  predictor <- predictors |>
    dplyr::filter(.data$predictor_id == registry$predictor_id[[1L]])
  h06d_m10_assert(nrow(predictor) == 1L, "Predictor registry mismatch")
  frame <- readRDS(file.path(root, registry$frame_path[[1L]]))
  h06d_m10_assert(
    digest::digest(frame, algo = "sha256", serialize = TRUE) ==
      registry$frame_object_sha256[[1L]],
    "Production frame object identity failed"
  )

  key <- registry$frame_key[[1L]]
  message("METRIC-010 production: ", key)
  formulas <- h06d_m10_formula_set(predictor$column[[1L]])
  additive_design <- h06d_m10_design_check(frame, predictor, FALSE)
  heterogeneity_design <- h06d_m10_design_check(frame, predictor, TRUE)
  h06d_m10_assert(
    additive_design$estimable,
    "A METRIC-010 additive design is not estimable"
  )

  gaussian_reml <- h06d_m10_fit_gaussian(
    frame,
    formulas$fixed_site_additive,
    REML = TRUE
  )
  student_t_reml <- h06d_m10_fit_t(
    frame,
    formulas$fixed_site_additive,
    REML = TRUE
  )
  h06d_m10_assert(
    !is.null(gaussian_reml$value) && !is.null(student_t_reml$value),
    "A METRIC-010 final additive fit failed"
  )
  gaussian_effect <- h06d_m10_effect_row(gaussian_reml$value, predictor)
  student_t_effect <- h06d_m10_effect_row(student_t_reml$value, predictor)
  gaussian_status <- h06d_m10_model_status(gaussian_reml$value)
  student_t_status <- h06d_m10_model_status(student_t_reml$value)
  gaussian_diagnostics <- h06d_m10_gaussian_residual_diagnostics(
    gaussian_reml$value,
    frame
  )
  student_t_diagnostics <- h06d_m10_t_residual_diagnostics(
    student_t_reml$value,
    frame
  )
  lag <- h06d_m10_lag_screen(
    frame,
    as.numeric(stats::residuals(gaussian_reml$value))
  )
  lag_site_rows[[key]] <- lag$by_site |>
    dplyr::mutate(
      run_id = registry$run_id[[1L]],
      predictor_order = predictor$predictor_order[[1L]],
      predictor_id = predictor$predictor_id[[1L]]
    ) |>
    dplyr::select(
      "run_id", "predictor_order", "predictor_id", "site",
      "adjacent_pairs", "participants", "residual_lag1"
    )

  ar_fit <- NULL
  ar_effect <- tibble::tibble(
    estimate = NA_real_, standard_error = NA_real_, lower_95 = NA_real_,
    upper_95 = NA_real_
  )
  ar_status <- tibble::tibble(
    converged = NA, positive_definite_hessian = NA, singular = NA,
    maximum_absolute_gradient = NA_real_, convergence_message = "not triggered"
  )
  ar_parameters <- tibble::tibble(
    ar_standard_deviation = NA_real_, ar_rho = NA_real_
  )
  ar_shift_se <- NA_real_
  ar_support_pass <- lag$overall$adjacent_pairs >= 100L &&
    lag$overall$participants >= 20L
  if (isTRUE(lag$overall$ar_trigger) && ar_support_pass) {
    ar_frame <- h06d_m10_add_day_sequences(frame)
    ar_formula <- h06d_m10_formula_set(
      predictor$column[[1L]],
      ar = TRUE
    )$fixed_site_additive
    ar_fit <- h06d_m10_fit_ar_gaussian(ar_frame, ar_formula, REML = TRUE)
    if (!is.null(ar_fit$value)) {
      ar_effect <- h06d_m10_effect_row(ar_fit$value, predictor) |>
        dplyr::select("estimate", "standard_error", "lower_95", "upper_95")
      ar_status <- h06d_m10_model_status(ar_fit$value)
      ar_parameters <- h06d_m10_ar_parameters(ar_fit$value)
      ar_shift_se <- abs(ar_effect$estimate - gaussian_effect$estimate) /
        gaussian_effect$standard_error
    } else {
      ar_status$convergence_message <- ar_fit$error
    }
  }
  ar_acceptable <- if (!isTRUE(lag$overall$ar_trigger)) {
    TRUE
  } else {
    ar_support_pass &&
      isTRUE(ar_status$converged) &&
      is.finite(ar_parameters$ar_rho) &&
      abs(ar_parameters$ar_rho) < 0.95 &&
      is.finite(ar_shift_se) && ar_shift_se < 1
  }
  ar_rows[[key]] <- dplyr::bind_cols(
    registry |>
      dplyr::select(
        "run_id", "dataset_id", "placement_id", "sample_role",
        "analysis_role"
      ),
    predictor |>
      dplyr::select("predictor_order", "predictor_id", "contrast_label"),
    lag$overall |>
      dplyr::rename(
        independent_residual_lag1 = "residual_lag1",
        independent_maximum_absolute_site_lag1 =
          "maximum_absolute_site_lag1"
      ),
    tibble::tibble(
      ar_support_pass = ar_support_pass,
      ar_fitted = !is.null(ar_fit) && !is.null(ar_fit$value),
      ar_estimate = ar_effect$estimate,
      ar_standard_error = ar_effect$standard_error,
      ar_lower_95 = ar_effect$lower_95,
      ar_upper_95 = ar_effect$upper_95,
      ar_effect_shift_in_primary_se = ar_shift_se,
      ar_acceptable = ar_acceptable
    ),
    ar_parameters,
    ar_status |>
      dplyr::rename_with(~ paste0("ar_", .x))
  )

  effect_shift_se <- abs(
    student_t_effect$estimate - gaussian_effect$estimate
  ) / gaussian_effect$standard_error
  effect_rows[[key]] <- dplyr::bind_rows(
    gaussian_effect |>
      dplyr::mutate(
        family = "Gaussian",
        link = "identity",
        sensitivity_role = "selected candidate"
      ),
    student_t_effect |>
      dplyr::mutate(
        family = "Student-t",
        link = "identity",
        sensitivity_role = "mandatory heavy-tail sensitivity"
      )
  ) |>
    dplyr::mutate(
      run_order = registry$run_order[[1L]],
      run_id = registry$run_id[[1L]],
      dataset_id = registry$dataset_id[[1L]],
      placement_id = registry$placement_id[[1L]],
      sample_role = registry$sample_role[[1L]],
      analysis_role = registry$analysis_role[[1L]],
      participant_days = nrow(frame),
      participants = dplyr::n_distinct(frame$participant_key),
      sites = dplyr::n_distinct(frame$site),
      frame_file_sha256 = registry$frame_file_sha256[[1L]],
      student_t_shift_in_gaussian_se = effect_shift_se
    ) |>
    dplyr::select(
      "run_order", "run_id", "dataset_id", "placement_id", "sample_role",
      "analysis_role", "predictor_order", "predictor_id", "predictor",
      "contrast", "family", "link", "sensitivity_role", "estimate",
      "standard_error", "lower_95", "upper_95", "effect_scale", "unit",
      "participant_days", "participants", "sites", "frame_file_sha256",
      "student_t_shift_in_gaussian_se"
    )

  gaussian_core_pass <- isTRUE(gaussian_status$converged) &&
    !isTRUE(gaussian_status$singular) &&
    gaussian_diagnostics$absolute_residual_fitted_spearman < 0.20 &&
    gaussian_diagnostics$standardized_residual_gt4_fraction < 0.01 &&
    gaussian_diagnostics$conditional_below_minus_0_05_fraction <= 0.01 &&
    gaussian_diagnostics$marginal_below_minus_0_05_fraction <= 0.01
  student_t_pass <- isTRUE(student_t_status$converged) &&
    isTRUE(student_t_status$positive_definite_hessian) &&
    student_t_diagnostics$t_degrees_of_freedom > 2 &&
    student_t_diagnostics$quantile_residual_qq_correlation >= 0.95 &&
    student_t_diagnostics$absolute_quantile_residual_fitted_spearman < 0.20 &&
    student_t_diagnostics$prediction_below_minus_0_05_fraction <= 0.01 &&
    effect_shift_se < 1
  diagnostic_disposition <- dplyr::case_when(
    !gaussian_core_pass ~ "NOT_ACCEPTABLE_GAUSSIAN_CORE",
    !student_t_pass ~ "NOT_ACCEPTABLE_T_SENSITIVITY",
    !ar_acceptable ~ "TEMPORAL_STABILITY_UNRESOLVED",
    gaussian_diagnostics$residual_qq_correlation < 0.95 ~
      "ACCEPTABLE_WITH_HEAVY_TAIL_LIMITATION",
    TRUE ~ "ACCEPTABLE"
  )
  diagnostic_rows[[key]] <- dplyr::bind_cols(
    registry |>
      dplyr::select(
        "run_id", "dataset_id", "placement_id", "sample_role",
        "analysis_role"
      ),
    predictor |>
      dplyr::select("predictor_order", "predictor_id"),
    tibble::tibble(
      participant_days = nrow(frame),
      participants = dplyr::n_distinct(frame$participant_key),
      sites = dplyr::n_distinct(frame$site),
      additive_design_estimable = additive_design$estimable,
      heterogeneity_design_estimable = heterogeneity_design$estimable,
      gaussian_warning_count = length(gaussian_reml$warnings),
      gaussian_warnings = paste(gaussian_reml$warnings, collapse = " | "),
      student_t_warning_count = length(student_t_reml$warnings),
      student_t_warnings = paste(student_t_reml$warnings, collapse = " | "),
      student_t_effect_shift_in_gaussian_se = effect_shift_se,
      gaussian_core_pass = gaussian_core_pass,
      student_t_sensitivity_pass = student_t_pass,
      ar_acceptable = ar_acceptable,
      diagnostic_disposition = diagnostic_disposition
    ),
    gaussian_status |>
      dplyr::rename_with(~ paste0("gaussian_", .x)),
    gaussian_diagnostics |>
      dplyr::rename_with(~ paste0("gaussian_", .x)),
    student_t_status |>
      dplyr::rename_with(~ paste0("student_t_", .x)),
    student_t_diagnostics |>
      dplyr::rename_with(~ paste0("student_t_", .x))
  )

  hierarchy <- list()
  if (registry$test_role[[1L]] %in% c("primary_raw_slot", "gap_raw_slot")) {
    reduced_ml <- h06d_m10_fit_gaussian(
      frame,
      formulas$fixed_site_reduced,
      REML = FALSE
    )
    additive_ml <- h06d_m10_fit_gaussian(
      frame,
      formulas$fixed_site_additive,
      REML = FALSE
    )
    h06d_m10_assert(
      !is.null(reduced_ml$value) && !is.null(additive_ml$value),
      "A METRIC-010 association LRT model failed"
    )
    association_test <- h06d_m10_lrt_row(
      reduced_ml$value,
      additive_ml$value
    ) |>
      dplyr::mutate(
        test_type = "association",
        test_status = "ESTIMABLE"
      )

    heterogeneity_ml <- NULL
    heterogeneity_reml <- NULL
    if (isTRUE(heterogeneity_design$estimable)) {
      heterogeneity_ml <- h06d_m10_fit_gaussian(
        frame,
        formulas$fixed_site_heterogeneity,
        REML = FALSE
      )
      heterogeneity_reml <- h06d_m10_fit_gaussian(
        frame,
        formulas$fixed_site_heterogeneity,
        REML = TRUE
      )
    }
    if (
      !is.null(heterogeneity_ml) &&
        !is.null(heterogeneity_ml$value) &&
        !is.null(heterogeneity_reml) &&
        !is.null(heterogeneity_reml$value)
    ) {
      heterogeneity_test <- h06d_m10_lrt_row(
        additive_ml$value,
        heterogeneity_ml$value
      ) |>
        dplyr::mutate(
          test_type = "site_heterogeneity",
          test_status = "ESTIMABLE"
        )
      heterogeneity_rows[[key]] <- extract_site_heterogeneity(
        heterogeneity_reml$value,
        predictor,
        registry$run_id[[1L]]
      )
    } else {
      heterogeneity_test <- tibble::tibble(
        likelihood_ratio = NA_real_,
        degrees_of_freedom = NA_real_,
        raw_p_value = NA_real_,
        method = "not fitted",
        test_type = "site_heterogeneity",
        test_status = "NON_ESTIMABLE"
      )
    }

    test_rows[[key]] <- dplyr::bind_rows(
      association_test,
      heterogeneity_test
    ) |>
      dplyr::mutate(
        run_id = registry$run_id[[1L]],
        dataset_id = registry$dataset_id[[1L]],
        placement_id = registry$placement_id[[1L]],
        predictor_order = predictor$predictor_order[[1L]],
        predictor_id = predictor$predictor_id[[1L]],
        contrast = predictor$contrast_label[[1L]],
        metric_slot = 15L,
        metric_id = "mder_mean_of_viable_ratios",
        multiplicity_status = "RAW_SLOT_ONLY_FAMILY_INCOMPLETE"
      ) |>
      dplyr::select(
        "run_id", "dataset_id", "placement_id", "predictor_order",
        "predictor_id", "contrast", "metric_slot", "metric_id",
        "test_type", "likelihood_ratio", "degrees_of_freedom",
        "raw_p_value", "method", "test_status", "multiplicity_status"
      )

    benchmark <- h06d_m10_fit_gaussian(
      frame,
      formulas$registered_random_site,
      REML = TRUE
    )
    benchmark_status <- h06d_m10_model_status(benchmark$value)
    maximum_random_site_correlation <- NA_real_
    if (!is.null(benchmark$value)) {
      site_vc <- lme4::VarCorr(benchmark$value)$site
      if (!is.null(site_vc) && nrow(site_vc) > 1L) {
        maximum_random_site_correlation <- max(
          abs(attr(site_vc, "correlation")[upper.tri(
            attr(site_vc, "correlation")
          )]),
          na.rm = TRUE
        )
      }
    }
    benchmark_disposition <- if (
      is.null(benchmark$value) ||
        !isTRUE(benchmark_status$converged) ||
        isTRUE(benchmark_status$singular) ||
        (
          is.finite(maximum_random_site_correlation) &&
            maximum_random_site_correlation >= 0.98
        )
    ) {
      "NON_ESTIMABLE"
    } else {
      "ESTIMABLE_BENCHMARK_ONLY"
    }
    benchmark_rows[[key]] <- dplyr::bind_cols(
      registry |>
        dplyr::select("run_id", "dataset_id", "placement_id"),
      predictor |>
        dplyr::select("predictor_order", "predictor_id"),
      tibble::tibble(
        formula = paste(
          deparse(formulas$registered_random_site),
          collapse = " "
        ),
        warning_count = length(benchmark$warnings),
        warnings = paste(benchmark$warnings, collapse = " | "),
        fit_error = benchmark$error,
        maximum_absolute_random_site_correlation =
          maximum_random_site_correlation,
        disposition = benchmark_disposition
      ),
      benchmark_status
    )
    hierarchy <- list(
      reduced_ml = reduced_ml,
      additive_ml = additive_ml,
      heterogeneity_ml = heterogeneity_ml,
      heterogeneity_reml = heterogeneity_reml,
      registered_benchmark = benchmark
    )
  }

  model_bundle[[key]] <- list(
    frame_path = registry$frame_path[[1L]],
    gaussian_reml = gaussian_reml,
    student_t_reml = student_t_reml,
    ar_gaussian_reml = ar_fit,
    hierarchy = hierarchy
  )
  runtime_rows[[key]] <- tibble::tibble(
    run_id = registry$run_id[[1L]],
    predictor_id = predictor$predictor_id[[1L]],
    gaussian_reml_seconds = gaussian_reml$elapsed_seconds,
    student_t_reml_seconds = student_t_reml$elapsed_seconds,
    ar_gaussian_reml_seconds = if (is.null(ar_fit)) {
      0
    } else {
      ar_fit$elapsed_seconds
    }
  )
}

replacement_keys <- affected_registry |>
  dplyr::distinct(.data$run_id, .data$predictor_id)
replace_affected_rows <- function(frozen, refreshed) {
  dplyr::bind_rows(
    frozen |>
      dplyr::anti_join(
        replacement_keys,
        by = c("run_id", "predictor_id")
      ),
    refreshed
  )
}

refreshed_effects <- dplyr::bind_rows(effect_rows)
refreshed_diagnostics <- dplyr::bind_rows(diagnostic_rows)
refreshed_lag_by_site <- dplyr::bind_rows(lag_site_rows)
refreshed_ar_counterparts <- dplyr::bind_rows(ar_rows)
refreshed_model_tests <- dplyr::bind_rows(test_rows)
refreshed_registered_benchmark <- dplyr::bind_rows(benchmark_rows)
refreshed_heterogeneity_site <- dplyr::bind_rows(heterogeneity_rows)
refreshed_runtime <- dplyr::bind_rows(runtime_rows)

if (targeted_gap_refresh) {
  effects <- replace_affected_rows(
    frozen_outputs$effects,
    refreshed_effects
  )
  diagnostics <- replace_affected_rows(
    frozen_outputs$diagnostics,
    refreshed_diagnostics
  )
  lag_by_site <- replace_affected_rows(
    frozen_outputs$lag_by_site,
    refreshed_lag_by_site
  )
  ar_counterparts <- replace_affected_rows(
    frozen_outputs$ar_counterparts,
    refreshed_ar_counterparts
  )
  model_tests <- replace_affected_rows(
    frozen_outputs$model_tests,
    refreshed_model_tests
  )
  registered_benchmark <- replace_affected_rows(
    frozen_outputs$registered_benchmark,
    refreshed_registered_benchmark
  )
  heterogeneity_site <- replace_affected_rows(
    frozen_outputs$heterogeneity_site,
    refreshed_heterogeneity_site
  )
  runtime <- replace_affected_rows(
    frozen_outputs$runtime |>
      dplyr::filter(!grepl("wall_time$", .data$run_id)),
    refreshed_runtime
  )
} else {
  effects <- refreshed_effects
  diagnostics <- refreshed_diagnostics
  lag_by_site <- refreshed_lag_by_site
  ar_counterparts <- refreshed_ar_counterparts
  model_tests <- refreshed_model_tests
  registered_benchmark <- refreshed_registered_benchmark
  heterogeneity_site <- refreshed_heterogeneity_site
  runtime <- refreshed_runtime
}

effects <- effects |>
  dplyr::arrange(.data$predictor_order, .data$run_order, .data$family)
diagnostics <- diagnostics |>
  dplyr::arrange(.data$predictor_order, .data$run_id)
lag_by_site <- lag_by_site |>
  dplyr::arrange(.data$predictor_order, .data$run_id, .data$site)
ar_counterparts <- ar_counterparts |>
  dplyr::arrange(.data$predictor_order, .data$run_id)
model_tests <- model_tests |>
  dplyr::arrange(.data$dataset_id, .data$predictor_order, .data$test_type)
registered_benchmark <- registered_benchmark |>
  dplyr::arrange(.data$dataset_id, .data$predictor_order)
heterogeneity_site <- heterogeneity_site |>
  dplyr::arrange(.data$run_id, .data$predictor_order, .data$site)

# A 15-slot family remains incomplete because no non-MDER production results
# are available inside H06_daily-owned artifacts.  Never adjust one scalar.
bh_slots <- dplyr::bind_rows(lapply(
  c("primary", "gap_timing_unaware"),
  function(dataset_id) {
    dplyr::bind_rows(lapply(
      seq_len(nrow(predictors)),
      function(index) {
        predictor <- predictors[index, ]
        dplyr::bind_rows(lapply(
          c("association", "site_heterogeneity"),
          function(test_type) {
            test <- model_tests |>
              dplyr::filter(
                .data$dataset_id == .env$dataset_id,
                .data$predictor_id == predictor$predictor_id[[1L]],
                .data$test_type == .env$test_type
              )
            h06d_m10_assert(nrow(test) == 1L, "BH raw-slot lookup failed")
            family_id <- if (test_type == "association") {
              predictor$association_family_id[[1L]]
            } else {
              predictor$heterogeneity_family_id[[1L]]
            }
            metric_slots |>
              dplyr::mutate(
                dataset_id = .env$dataset_id,
                predictor_order = predictor$predictor_order[[1L]],
                predictor_id = predictor$predictor_id[[1L]],
                test_type = .env$test_type,
                multiplicity_family_id = paste(
                  .env$dataset_id,
                  family_id,
                  sep = "__"
                ),
                slot_status = ifelse(
                  .data$metric_slot == 15L,
                  test$test_status[[1L]],
                  "NON_MDER_SLOT_NOT_AVAILABLE_TO_MDER_ONLY_AMENDMENT"
                ),
                raw_p_value = ifelse(
                  .data$metric_slot == 15L,
                  test$raw_p_value[[1L]],
                  NA_real_
                ),
                bh_adjusted_p_value = NA_real_,
                family_slots_available = 1L,
                family_slots_required = 15L,
                family_status = "INCOMPLETE_1_OF_15_NO_BH_DECISION",
                adjusted_decision = NA
              )
          }
        ))
      }
    ))
  }
)) |>
  dplyr::arrange(
    .data$dataset_id,
    .data$predictor_order,
    .data$test_type,
    .data$metric_slot
  )
h06d_m10_assert(
  nrow(bh_slots) == 2L * 3L * 2L * 15L &&
    all(is.na(bh_slots$bh_adjusted_p_value)),
  "METRIC-010 incomplete BH family contract failed"
)

# Full primary near-eye deletion checks.  The bounded 50-refit pilot projected
# this as a 0.19-minute, non-heavy batch.
participant_influence <- if (targeted_gap_refresh) {
  frozen_outputs$participant_influence
} else {
  list()
}
site_influence <- if (targeted_gap_refresh) {
  frozen_outputs$site_influence
} else {
  list()
}
influence_summary <- if (targeted_gap_refresh) {
  frozen_outputs$influence_summary
} else {
  list()
}
influence_indices <- if (targeted_gap_refresh) integer(0) else seq_len(nrow(predictors))
for (index in influence_indices) {
  predictor <- predictors[index, ]
  registry <- frame_registry |>
    dplyr::filter(
      .data$run_id == "primary__near_eye__all_available",
      .data$predictor_id == predictor$predictor_id[[1L]]
    )
  frame <- readRDS(file.path(root, registry$frame_path[[1L]]))
  key <- registry$frame_key[[1L]]
  full_model <- model_bundle[[key]]$gaussian_reml$value
  full_effect <- h06d_m10_effect_row(full_model, predictor)

  participant_values <- sort(unique(as.character(frame$participant_key)))
  participant_results <- dplyr::bind_rows(lapply(
    participant_values,
    function(value) {
      h06d_m10_deletion_refit(
        frame,
        predictor,
        "participant",
        value,
        full_effect$estimate,
        full_effect$standard_error
      ) |>
        dplyr::mutate(
          participant_hash = substr(
            digest::digest(value, algo = "sha256"),
            1L,
            12L
          )
        ) |>
        dplyr::select(-"deletion_value")
    }
  )) |>
    dplyr::mutate(
      predictor_order = predictor$predictor_order[[1L]],
      predictor_id = predictor$predictor_id[[1L]],
      full_estimate = full_effect$estimate,
      full_standard_error = full_effect$standard_error
    )
  site_values <- sort(unique(as.character(frame$site)))
  site_results <- dplyr::bind_rows(lapply(
    site_values,
    function(value) {
      h06d_m10_deletion_refit(
        frame,
        predictor,
        "site",
        value,
        full_effect$estimate,
        full_effect$standard_error
      ) |>
        dplyr::rename(deleted_site = "deletion_value")
    }
  )) |>
    dplyr::mutate(
      predictor_order = predictor$predictor_order[[1L]],
      predictor_id = predictor$predictor_id[[1L]],
      full_estimate = full_effect$estimate,
      full_standard_error = full_effect$standard_error
    )

  participant_influence[[predictor$predictor_id[[1L]]]] <- participant_results
  site_influence[[predictor$predictor_id[[1L]]]] <- site_results
  maximum_participant <- participant_results |>
    dplyr::slice_max(
      .data$absolute_shift_in_full_se,
      n = 1L,
      with_ties = FALSE
    )
  maximum_site <- site_results |>
    dplyr::slice_max(
      .data$absolute_shift_in_full_se,
      n = 1L,
      with_ties = FALSE
    )
  participant_direction_reversal_count <- sum(
    participant_results$direction_reversal,
    na.rm = TRUE
  )
  site_direction_reversal_count <- sum(
    site_results$direction_reversal,
    na.rm = TRUE
  )
  direction_reversal_count <- participant_direction_reversal_count +
    site_direction_reversal_count
  strict_influence_pass <- all(participant_results$converged) &&
    all(site_results$converged) &&
    maximum_participant$absolute_shift_in_full_se < 1 &&
    maximum_site$absolute_shift_in_full_se < 1 &&
    direction_reversal_count == 0L
  estimate_magnitude_reportable <- all(participant_results$converged) &&
    all(site_results$converged) &&
    maximum_participant$absolute_shift_in_full_se < 2 &&
    maximum_site$absolute_shift_in_full_se < 2
  participant_direction_claim_acceptable <-
    maximum_participant$absolute_shift_in_full_se < 1 &&
    participant_direction_reversal_count == 0L
  cross_site_direction_claim_acceptable <-
    maximum_site$absolute_shift_in_full_se < 2 &&
    site_direction_reversal_count == 0L
  influence_summary[[predictor$predictor_id[[1L]]]] <- tibble::tibble(
    predictor_order = predictor$predictor_order[[1L]],
    predictor_id = predictor$predictor_id[[1L]],
    participant_deletions = nrow(participant_results),
    participant_failures = sum(!participant_results$converged),
    maximum_participant_shift_in_full_se =
      maximum_participant$absolute_shift_in_full_se,
    maximum_participant_hash = maximum_participant$participant_hash,
    site_deletions = nrow(site_results),
    site_failures = sum(!site_results$converged),
    maximum_site_shift_in_full_se = maximum_site$absolute_shift_in_full_se,
    maximum_shift_site = maximum_site$deleted_site,
    participant_direction_reversal_count =
      participant_direction_reversal_count,
    site_direction_reversal_count = site_direction_reversal_count,
    direction_reversal_count = direction_reversal_count,
    strict_influence_pass = strict_influence_pass,
    estimate_magnitude_reportable = estimate_magnitude_reportable,
    participant_direction_claim_acceptable =
      participant_direction_claim_acceptable,
    cross_site_direction_claim_acceptable =
      cross_site_direction_claim_acceptable,
    influence_disposition = dplyr::case_when(
      !estimate_magnitude_reportable ~ "NOT_ACCEPTABLE",
      site_direction_reversal_count > 0L ~
        "MAGNITUDE_REPORTABLE_CROSS_SITE_DIRECTION_UNSTABLE",
      participant_direction_reversal_count > 0L ~
        "MAGNITUDE_REPORTABLE_PARTICIPANT_DIRECTION_UNSTABLE",
      maximum_site$absolute_shift_in_full_se >= 1 ~
        "MAGNITUDE_REPORTABLE_SITE_GENERALITY_LIMITED",
      TRUE ~ "ACCEPTABLE"
    )
  )
}
participant_influence <- dplyr::bind_rows(participant_influence) |>
  dplyr::arrange(.data$predictor_order, .data$participant_hash)
site_influence <- dplyr::bind_rows(site_influence) |>
  dplyr::arrange(.data$predictor_order, .data$deleted_site)
influence_summary <- dplyr::bind_rows(influence_summary) |>
  dplyr::arrange(.data$predictor_order)

primary_diagnostics <- diagnostics |>
  dplyr::filter(.data$run_id == "primary__near_eye__all_available")
primary_ar <- ar_counterparts |>
  dplyr::filter(.data$run_id == "primary__near_eye__all_available")
production_verdict <- primary_diagnostics |>
  dplyr::select(
    "predictor_order", "predictor_id", "participant_days", "participants",
    "sites", "diagnostic_disposition"
  ) |>
  dplyr::left_join(
    influence_summary,
    by = c("predictor_order", "predictor_id"),
    relationship = "one-to-one"
  ) |>
  dplyr::left_join(
    primary_ar |>
      dplyr::select(
        "predictor_order", "predictor_id", "ar_trigger", "ar_fitted",
        "ar_rho", "ar_effect_shift_in_primary_se", "ar_acceptable"
      ),
    by = c("predictor_order", "predictor_id"),
    relationship = "one-to-one"
  ) |>
  dplyr::mutate(
    overall_verdict = dplyr::case_when(
      !.data$estimate_magnitude_reportable ~ "NOT_ACCEPTABLE_INFLUENCE",
      !.data$ar_acceptable ~ "TEMPORAL_STABILITY_UNRESOLVED",
      grepl("NOT_ACCEPTABLE", .data$diagnostic_disposition) ~
        .data$diagnostic_disposition,
      !.data$cross_site_direction_claim_acceptable ~
        "REPORTABLE_ESTIMATE_NO_STABLE_CROSS_SITE_DIRECTION",
      !.data$participant_direction_claim_acceptable ~
        "REPORTABLE_ESTIMATE_NO_STABLE_PARTICIPANT_DIRECTION",
      .data$maximum_site_shift_in_full_se >= 1 ~
        "ACCEPTABLE_WITH_SITE_INFLUENCE_AND_HEAVY_TAIL_LIMITATIONS",
      TRUE ~ "ACCEPTABLE_WITH_HEAVY_TAIL_LIMITATION"
    ),
    claim_disposition = dplyr::case_when(
      .data$overall_verdict %in% c(
        "NOT_ACCEPTABLE_INFLUENCE",
        "TEMPORAL_STABILITY_UNRESOLVED",
        "NOT_ACCEPTABLE_GAUSSIAN_CORE",
        "NOT_ACCEPTABLE_T_SENSITIVITY"
      ) ~
        "NO_ASSOCIATION_CLAIM",
      grepl("NO_STABLE", .data$overall_verdict) ~
        "ESTIMATE_AND_CI_REPORTABLE_NO_DIRECTIONAL_GENERALIZATION",
      TRUE ~ "ASSOCIATION_ESTIMATE_ALLOWED"
    )
  )

object_sha256 <- function(object) {
  digest::digest(object, algo = "sha256", serialize = TRUE)
}
canonical_tabular_values <- function(data) {
  data |>
    dplyr::mutate(dplyr::across(
      dplyr::everything(),
      function(value) {
        output <- if (inherits(value, "Date")) {
          format(value, "%Y-%m-%d")
        } else if (is.numeric(value)) {
          sprintf("%.17g", value)
        } else if (is.logical(value)) {
          ifelse(value, "TRUE", "FALSE")
        } else {
          as.character(value)
        }
        output[is.na(value)] <- "<H06D_NA>"
        output
      }
    )) |>
    dplyr::arrange(dplyr::across(dplyr::everything()))
}
unaffected_keys <- frame_registry |>
  dplyr::select(.data$run_id, .data$predictor_id) |>
  dplyr::anti_join(replacement_keys, by = c("run_id", "predictor_id"))
unaffected_rows <- function(data) {
  data |>
    dplyr::semi_join(unaffected_keys, by = c("run_id", "predictor_id"))
}
preservation_row <- function(domain, previous, current, checked_items) {
  previous_sha256 <- object_sha256(previous)
  current_sha256 <- object_sha256(current)
  serialized_identical <- identical(previous_sha256, current_sha256)
  exact_values_equal <- isTRUE(all.equal(
    previous,
    current,
    tolerance = 0,
    check.attributes = FALSE
  ))
  canonical_values_equal <- if (
    is.data.frame(previous) && is.data.frame(current)
  ) {
    identical(
      canonical_tabular_values(previous),
      canonical_tabular_values(current)
    )
  } else {
    FALSE
  }
  preserved <- serialized_identical ||
    exact_values_equal ||
    canonical_values_equal
  tibble::tibble(
    domain = domain,
    checked_items = checked_items,
    previous_object_sha256 = previous_sha256,
    current_object_sha256 = current_sha256,
    serialized_identical = serialized_identical,
    exact_values_equal = exact_values_equal,
    canonical_values_equal = canonical_values_equal,
    preserved = preserved,
    disposition = dplyr::case_when(
      serialized_identical ~ "FROZEN_SERIALIZATION_IDENTICAL",
      exact_values_equal ~ "FROZEN_VALUES_IDENTICAL_ATTRIBUTES_DIFFER",
      canonical_values_equal ~ "FROZEN_TABULAR_VALUES_IDENTICAL",
      TRUE ~ "UNEXPECTED_FROZEN_CONTENT_CHANGE"
    )
  )
}
if (targeted_gap_refresh) {
  unaffected_model_keys <- names(model_bundle)[
    names(model_bundle) %in% frame_registry$frame_key[
      frame_registry$dataset_id == "primary" &
        frame_registry$sample_role != "dataset_common"
    ]
  ]
  frozen_model_bundle <- readRDS(file.path(root, model_relative))
  refresh_preservation <- dplyr::bind_rows(
    preservation_row(
      "Unaffected effect estimates",
      unaffected_rows(frozen_outputs$effects),
      unaffected_rows(effects),
      nrow(unaffected_rows(effects))
    ),
    preservation_row(
      "Unaffected model diagnostics",
      unaffected_rows(frozen_outputs$diagnostics),
      unaffected_rows(diagnostics),
      nrow(unaffected_rows(diagnostics))
    ),
    preservation_row(
      "Unaffected site residual lags",
      unaffected_rows(frozen_outputs$lag_by_site),
      unaffected_rows(lag_by_site),
      nrow(unaffected_rows(lag_by_site))
    ),
    preservation_row(
      "Unaffected AR counterparts",
      unaffected_rows(frozen_outputs$ar_counterparts),
      unaffected_rows(ar_counterparts),
      nrow(unaffected_rows(ar_counterparts))
    ),
    preservation_row(
      "Unaffected raw model tests",
      unaffected_rows(frozen_outputs$model_tests),
      unaffected_rows(model_tests),
      nrow(unaffected_rows(model_tests))
    ),
    preservation_row(
      "Unaffected registered benchmarks",
      unaffected_rows(frozen_outputs$registered_benchmark),
      unaffected_rows(registered_benchmark),
      nrow(unaffected_rows(registered_benchmark))
    ),
    preservation_row(
      "Unaffected site heterogeneity estimates",
      unaffected_rows(frozen_outputs$heterogeneity_site),
      unaffected_rows(heterogeneity_site),
      nrow(unaffected_rows(heterogeneity_site))
    ),
    preservation_row(
      "Primary participant-deletion diagnostics",
      frozen_outputs$participant_influence,
      participant_influence,
      nrow(participant_influence)
    ),
    preservation_row(
      "Primary site-deletion diagnostics",
      frozen_outputs$site_influence,
      site_influence,
      nrow(site_influence)
    ),
    preservation_row(
      "Primary influence summary",
      frozen_outputs$influence_summary,
      influence_summary,
      nrow(influence_summary)
    ),
    preservation_row(
      "Primary production verdict",
      frozen_outputs$production_verdict,
      production_verdict,
      nrow(production_verdict)
    ),
    preservation_row(
      "Unaffected primary model objects",
      frozen_model_bundle[unaffected_model_keys],
      model_bundle[unaffected_model_keys],
      length(unaffected_model_keys)
    )
  )
  if (!all(refresh_preservation$preserved)) {
    print(dplyr::filter(
      refresh_preservation,
      !.data$preserved
    ))
  }
  h06d_m10_assert(
    all(refresh_preservation$preserved),
    "A frozen METRIC-010 production result changed during the gap refresh"
  )
} else {
  refresh_preservation <- tibble::tibble(
    domain = "Full production execution",
    checked_items = nrow(frame_registry),
    previous_object_sha256 = NA_character_,
    current_object_sha256 = NA_character_,
    serialized_identical = NA,
    exact_values_equal = NA,
    canonical_values_equal = NA,
    preserved = NA,
    disposition = "NOT_APPLICABLE_FULL_PRODUCTION"
  )
}

runtime <- dplyr::bind_rows(
  runtime,
  if (!targeted_gap_refresh) {
    tibble::tibble(
      run_id = "full_primary_influence_batch",
      predictor_id = "all_three_primary_predictors",
      gaussian_reml_seconds = sum(participant_influence$elapsed_seconds) +
        sum(site_influence$elapsed_seconds),
      student_t_reml_seconds = 0,
      ar_gaussian_reml_seconds = 0
    )
  },
  tibble::tibble(
    run_id = ifelse(
      targeted_gap_refresh,
      "metric010_gap_refresh_wall_time",
      "complete_production_script_wall_time"
    ),
    predictor_id = "all",
    gaussian_reml_seconds = unname(
      proc.time()[["elapsed"]] - started_all
    ),
    student_t_reml_seconds = 0,
    ar_gaussian_reml_seconds = 0
  )
)

production_gate_pass <- all(
  production_verdict$claim_disposition != "NO_ASSOCIATION_CLAIM"
)

output_tables <- list(
  "artifacts/09_tables/H06_daily/H06_daily_mder_metric010_effect_estimates.csv" = effects,
  "artifacts/09_tables/H06_daily/H06_daily_mder_metric010_model_tests.csv" = model_tests,
  "artifacts/09_tables/H06_daily/H06_daily_mder_metric010_bh_slot_families.csv" = bh_slots,
  "artifacts/08_diagnostics/H06_daily/H06_daily_mder_metric010_model_diagnostics.csv" = diagnostics,
  "artifacts/08_diagnostics/H06_daily/H06_daily_mder_metric010_site_residual_lag.csv" = lag_by_site,
  "artifacts/08_diagnostics/H06_daily/H06_daily_mder_metric010_ar_counterparts.csv" = ar_counterparts,
  "artifacts/08_diagnostics/H06_daily/H06_daily_mder_metric010_registered_benchmark.csv" = registered_benchmark,
  "artifacts/09_tables/H06_daily/H06_daily_mder_metric010_site_heterogeneity_estimates.csv" = heterogeneity_site,
  "artifacts/08_diagnostics/H06_daily/H06_daily_mder_metric010_participant_deletion_influence.csv" = participant_influence,
  "artifacts/08_diagnostics/H06_daily/H06_daily_mder_metric010_site_deletion_influence.csv" = site_influence,
  "artifacts/08_diagnostics/H06_daily/H06_daily_mder_metric010_influence_summary.csv" = influence_summary,
  "artifacts/08_diagnostics/H06_daily/H06_daily_mder_metric010_production_verdict.csv" = production_verdict,
  "artifacts/08_diagnostics/H06_daily/H06_daily_mder_metric010_production_runtime.csv" = runtime,
  "artifacts/08_diagnostics/H06_daily/H06_daily_mder_metric010_gap_refresh_preservation.csv" = refresh_preservation
)
saveRDS(model_bundle, file.path(root, model_relative), version = 3)
for (path in names(output_tables)) {
  readr::write_csv(output_tables[[path]], file.path(root, path), na = "")
}

manifest <- function(relative_paths, roles) {
  absolute <- file.path(root, relative_paths)
  tibble::tibble(
    relative_path = relative_paths,
    sha256 = vapply(absolute, h06d_m10_sha256, character(1)),
    bytes = unname(file.info(absolute)$size),
    role = roles,
    producer = producer,
    r_version = as.character(getRversion())
  )
}
input_relative <- c(
  frame_registry_path,
  metric_slot_path,
  family_verdict_path,
  influence_runtime_path,
  frame_registry$frame_path
)
input_manifest <- manifest(
  input_relative,
  c(
    "frame registry", "15-slot metric registry", "family pilot verdict",
    "influence runtime gate", rep("exact METRIC-010 model frame", 36L)
  )
)
if (targeted_gap_refresh) {
  input_manifest <- dplyr::bind_rows(
    input_manifest,
    previous_output_manifest |>
      dplyr::transmute(
        relative_path = .data$relative_path,
        sha256 = .data$sha256,
        bytes = .data$bytes,
        role = paste0("pre-refresh frozen production input: ", .data$role),
        producer = .env$producer,
        r_version = as.character(getRversion())
      ),
    tibble::tibble(
      relative_path = previous_output_manifest_relative,
      sha256 = previous_output_manifest_sha256,
      bytes = unname(file.info(file.path(
        root,
        previous_output_manifest_relative
      ))$size),
      role = "pre-refresh production output manifest",
      producer = producer,
      r_version = as.character(getRversion())
    )
  )
}
code_relative <- c(
  producer,
  "scripts/hypotheses/H06_daily/h06_daily_mder_metric010_contract.R",
  "scripts/hypotheses/H06_daily/h06_daily_mder_metric010_data.R",
  "scripts/hypotheses/H06_daily/h06_daily_mder_metric010_modeling.R"
)
code_manifest <- manifest(code_relative, c(
  "production runner", "METRIC-010 contract", "METRIC-010 data adapters",
  "METRIC-010 modeling and deletion helpers"
))
output_manifest <- manifest(
  c(model_relative, names(output_tables)),
  c("production model bundle", rep("production table or diagnostic", length(output_tables)))
)
software_manifest <- tibble::tibble(
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
readr::write_csv(
  input_manifest,
  file.path(roots$manifests, "H06_daily_mder_metric010_production_input_manifest.csv"),
  na = ""
)
readr::write_csv(
  code_manifest,
  file.path(roots$manifests, "H06_daily_mder_metric010_production_code_manifest.csv"),
  na = ""
)
readr::write_csv(
  output_manifest,
  file.path(roots$manifests, "H06_daily_mder_metric010_production_output_manifest.csv"),
  na = ""
)
readr::write_csv(
  software_manifest,
  file.path(roots$manifests, "H06_daily_mder_metric010_production_software_manifest.csv"),
  na = ""
)

message(sprintf(
  paste0(
    "H06_daily METRIC-010 production complete in %.1f seconds; ",
    "primary gate %s."
  ),
  unname(proc.time()[["elapsed"]] - started_all),
  ifelse(production_gate_pass, "PASS", "REQUIRES_REVIEW")
))
