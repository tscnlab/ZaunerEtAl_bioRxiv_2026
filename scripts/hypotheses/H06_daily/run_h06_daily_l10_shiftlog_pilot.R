#!/usr/bin/env Rscript

# Run the compute-cleared three-predictor H06-D-003 shifted-log pilot.

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
  "digest",
  "dplyr",
  "glmmTMB",
  "lme4",
  "readr",
  "reformulas",
  "tibble",
  "tidyr"
)
stopifnot(
  identical(as.character(getRversion()), "4.6.1"),
  all(vapply(required_packages, requireNamespace, logical(1), quietly = TRUE))
)

source(file.path(
  root,
  "scripts/hypotheses/H06_daily/h06_daily_l10_shiftlog_contract.R"
))
source(file.path(
  root,
  "scripts/hypotheses/H06_daily/h06_daily_l10_shiftlog_data.R"
))
source(file.path(
  root,
  "scripts/hypotheses/H06_daily/h06_daily_l10_shiftlog_modeling.R"
))

clearance <- Sys.getenv(
  "H06D_L10_SHIFTLOG_COMPUTE_CLEARANCE",
  unset = ""
)
h06d_shiftlog_assert(
  identical(clearance, "H06-D-003-COMPUTE-CLEARED-2026-08-12"),
  paste0(
    "H06-D-003 pilot compute is held. Supply the task-specific clearance ",
    "token only after coordinator authorization."
  )
)

roots <- h06d_shiftlog_artifact_roots(root)
invisible(lapply(roots, dir.create, recursive = TRUE, showWarnings = FALSE))

read_csv <- function(path) {
  readr::read_csv(path, show_col_types = FALSE, na = c("", "NA"))
}

#####
# Step 1: Reverify static inputs and historical preservation
#####

static_verdict <- read_csv(file.path(
  roots$diagnostics,
  "H06_daily_l10_shiftlog_static_verdict.csv"
))
reuse_verification <- read_csv(file.path(
  roots$diagnostics,
  "H06_daily_l10_shiftlog_exact_reuse_verification.csv"
))
reference_registry <- read_csv(file.path(
  roots$diagnostics,
  "H06_daily_l10_shiftlog_reference_registry.csv"
))
frame_registry <- read_csv(file.path(
  roots$model_data,
  "H06_daily_l10_shiftlog_pilot_frame_registry.csv"
))
historical_preservation <- read_csv(file.path(
  roots$diagnostics,
  "H06_daily_l10_shiftlog_historical_preservation_baseline.csv"
))
h06d_shiftlog_assert(
  nrow(static_verdict) == 1L &&
    static_verdict$static_disposition ==
      paste0(
        "STATIC_CONTRACT_PASS; THREE_REML_ADDITIVE_OBJECTS_EXACTLY_REUSABLE; ",
        "NO_MODEL_LAUNCH"
      ) &&
    nrow(reuse_verification) == 3L &&
    all(reuse_verification$exact_reuse_authorized) &&
    nrow(frame_registry) == 3L &&
    nrow(historical_preservation) == 118L &&
    all(historical_preservation$preserved_byte_for_byte),
  "H06-D-003 pilot lacks a passed static contract"
)
h06d_shiftlog_assert(
  all(
    vapply(
      file.path(root, historical_preservation$relative_path),
      h06d_shiftlog_sha256,
      character(1)
    ) ==
      historical_preservation$sha256
  ),
  "A historical H06-D-001/H06-D-002 artifact changed before the pilot"
)

historical_bundle_path <- file.path(
  root,
  "artifacts/07_models/H06_daily/",
  "H06_daily_l10_metric011_production_models.rds"
)
historical_bundle <- readRDS(historical_bundle_path)
predictors <- h06d_shiftlog_predictor_registry()

#####
# Step 2: Fit only missing pilot components
#####

sample_rows <- list()
effect_rows <- list()
test_rows <- list()
diagnostic_rows <- list()
zero_mass_rows <- list()
family_rows <- list()
lag_rows <- list()
lag_site_rows <- list()
post_ar_lag_site_rows <- list()
ar_rows <- list()
registered_rows <- list()
equal_site_rows <- list()
equal_site_contrast_rows <- list()
equal_site_grid_rows <- list()
runtime_rows <- list()
provenance_rows <- list()
verdict_rows <- list()
new_model_bundle <- list()

pilot_started <- proc.time()[["elapsed"]]

for (predictor_index in seq_len(nrow(predictors))) {
  predictor <- predictors[predictor_index, ]
  predictor_id <- predictor$predictor_id[[1L]]
  message("H06-D-003 shifted-log pilot: ", predictor_id)

  frame_row <- frame_registry |>
    dplyr::filter(.data$predictor_id == .env$predictor_id)
  reference_row <- reference_registry |>
    dplyr::filter(.data$predictor_id == .env$predictor_id)
  reuse_row <- reuse_verification |>
    dplyr::filter(.data$predictor_id == .env$predictor_id)
  h06d_shiftlog_assert(
    nrow(frame_row) == 1L &&
      nrow(reference_row) == 1L &&
      nrow(reuse_row) == 1L &&
      reuse_row$exact_reuse_authorized,
    "Shifted-log pilot lookup failed for `%s`",
    predictor_id
  )
  frame_path <- file.path(root, frame_row$frame_path[[1L]])
  frame <- readRDS(frame_path)
  h06d_shiftlog_assert(
    h06d_shiftlog_sha256(frame_path) == frame_row$frame_file_sha256[[1L]] &&
      h06d_shiftlog_object_sha256(frame) == frame_row$frame_object_sha256[[1L]],
    "Shifted-log pilot frame identity failed for `%s`",
    predictor_id
  )

  model_key <- h06d_shiftlog_model_key(
    h06d_shiftlog_pilot_run_id(),
    predictor_id
  )
  gaussian_reml_capture <- historical_bundle$models[[model_key]]$one_part
  gaussian_reml <- gaussian_reml_capture$value
  h06d_shiftlog_assert(
    h06d_shiftlog_object_sha256(gaussian_reml_capture) ==
      reference_row$capture_object_sha256[[1L]] &&
      h06d_shiftlog_object_sha256(gaussian_reml) ==
        reference_row$model_object_sha256[[1L]] &&
      identical(frame, gaussian_reml_capture$frame),
    "Exact reusable REML object identity failed for `%s`",
    predictor_id
  )

  formulas <- h06d_shiftlog_formula_set(predictor$column[[1L]])
  additive_design <- h06d_shiftlog_design_check(
    frame,
    predictor,
    heterogeneity = FALSE
  )
  heterogeneity_design <- h06d_shiftlog_design_check(
    frame,
    predictor,
    heterogeneity = TRUE
  )

  reduced_ml <- h06d_shiftlog_fit_gaussian(
    frame,
    formulas$fixed_site_reduced,
    reml = FALSE
  )
  additive_ml <- h06d_shiftlog_fit_gaussian(
    frame,
    formulas$fixed_site_additive,
    reml = FALSE
  )
  heterogeneity_ml <- h06d_shiftlog_fit_gaussian(
    frame,
    formulas$fixed_site_heterogeneity,
    reml = FALSE
  )
  student_t <- h06d_shiftlog_fit_student_t(
    frame,
    formulas$fixed_site_additive
  )
  registered <- h06d_shiftlog_fit_gaussian(
    frame,
    formulas$registered_random_site,
    reml = TRUE
  )

  reduced_status <- h06d_shiftlog_model_status(reduced_ml$value)
  additive_ml_status <- h06d_shiftlog_model_status(additive_ml$value)
  heterogeneity_status <- h06d_shiftlog_model_status(
    heterogeneity_ml$value
  )
  gaussian_status <- h06d_shiftlog_model_status(gaussian_reml)
  student_t_status <- h06d_shiftlog_model_status(student_t$value)

  hierarchy_fits_available <- all(vapply(
    list(reduced_ml, additive_ml, heterogeneity_ml),
    function(capture) !is.null(capture$value),
    logical(1)
  ))
  hierarchy_numerically_acceptable <- hierarchy_fits_available &&
    all(c(
      reduced_status$converged,
      additive_ml_status$converged,
      heterogeneity_status$converged,
      reduced_status$positive_definite_hessian,
      additive_ml_status$positive_definite_hessian,
      heterogeneity_status$positive_definite_hessian
    )) &&
    !any(c(
      reduced_status$singular,
      additive_ml_status$singular,
      heterogeneity_status$singular
    ))

  if (
    hierarchy_numerically_acceptable &&
      additive_design$estimable &&
      heterogeneity_design$estimable
  ) {
    association_test <- h06d_shiftlog_lrt_row(
      reduced_ml$value,
      additive_ml$value,
      "association"
    ) |>
      dplyr::mutate(test_status = "ESTIMABLE_PILOT_RAW_ONLY")
    heterogeneity_test <- h06d_shiftlog_lrt_row(
      additive_ml$value,
      heterogeneity_ml$value,
      "site_heterogeneity"
    ) |>
      dplyr::mutate(test_status = "ESTIMABLE_PILOT_RAW_ONLY")
  } else {
    association_test <- tibble::tibble(
      test_type = "association",
      likelihood_ratio = NA_real_,
      degrees_of_freedom = NA_real_,
      raw_p_value = NA_real_,
      method = "pilot test withheld after hierarchy/design failure",
      multiplicity_status = "PILOT_RAW_ONLY_NO_BH_UPDATE",
      test_status = "NON_ESTIMABLE_HIERARCHY_OR_DESIGN_FAILURE"
    )
    heterogeneity_test <- association_test |>
      dplyr::mutate(test_type = "site_heterogeneity")
  }

  gaussian_effect <- h06d_shiftlog_effect_row(
    gaussian_reml,
    predictor,
    "Gaussian identity on log10(L10 mean melEDI + 0.1 lx)"
  )
  if (!is.null(student_t$value)) {
    student_t_effect <- h06d_shiftlog_effect_row(
      student_t$value,
      predictor,
      "Student-t identity on log10(L10 mean melEDI + 0.1 lx) sensitivity"
    )
    family_sensitivity <- h06d_shiftlog_family_sensitivity(
      gaussian_effect,
      student_t_effect,
      student_t_status
    )
  } else {
    student_t_effect <- gaussian_effect |>
      dplyr::mutate(
        family = paste0(
          "Student-t identity on log10(L10 mean melEDI + 0.1 lx) ",
          "sensitivity"
        ),
        dplyr::across(
          c(
            "link_estimate",
            "link_standard_error",
            "link_lower_95",
            "link_upper_95",
            "shifted_geometric_mean_ratio",
            "ratio_lower_95",
            "ratio_upper_95"
          ),
          ~NA_real_
        )
      )
    family_sensitivity <- tibble::tibble(
      gaussian_link_estimate = gaussian_effect$link_estimate,
      gaussian_link_standard_error = gaussian_effect$link_standard_error,
      student_t_link_estimate = NA_real_,
      effect_shift_in_gaussian_se = NA_real_,
      direction_reversal = NA,
      family_sensitivity_disposition = "SENSITIVITY_UNRESOLVED_STUDENT_T_NUMERICAL_FAILURE"
    )
  }

  residual_diagnostics <- h06d_shiftlog_residual_diagnostics(
    gaussian_reml,
    frame
  )
  lag <- h06d_shiftlog_lag_screen(
    frame,
    as.numeric(stats::residuals(gaussian_reml))
  )
  standardized <- h06d_shiftlog_equal_site_predictions(
    gaussian_reml,
    frame,
    predictor
  )

  independent_glmmtmb <- NULL
  ar_capture <- NULL
  ar_summary <- tibble::tibble(
    ar_trigger = lag$overall$ar_trigger,
    ar_support_adequate = lag$overall$ar_support_adequate,
    independent_glmmtmb_fitted = FALSE,
    ar_fitted = FALSE,
    independent_engine_converged = NA,
    independent_engine_positive_definite_hessian = NA,
    independent_engine_singular = NA,
    independent_engine_singularity_method = NA_character_,
    ar_converged = NA,
    ar_positive_definite_hessian = NA,
    ar_singular = NA,
    ar_singularity_method = NA_character_,
    ar_minimum_random_effect_standard_deviation = NA_real_,
    ar_minimum_scaled_covariance_eigenvalue = NA_real_,
    independent_engine_shift_in_gaussian_se = NA_real_,
    ar_effect_shift_in_gaussian_se = NA_real_,
    ar_rho = NA_real_,
    ar_standard_deviation = NA_real_,
    post_ar_residual_lag1 = NA_real_,
    post_ar_maximum_absolute_site_lag1 = NA_real_,
    ar_disposition = ifelse(
      lag$overall$ar_trigger,
      "NOT_FITTED_PENDING_SUPPORT_CHECK",
      "ACCEPTABLE_NO_AR_TRIGGER"
    )
  )
  if (
    isTRUE(lag$overall$ar_trigger) &&
      isTRUE(lag$overall$ar_support_adequate)
  ) {
    independent_glmmtmb <- h06d_shiftlog_fit_glmmtmb_gaussian(
      frame,
      formulas$fixed_site_additive
    )
    ar_capture <- h06d_shiftlog_fit_ar(
      frame,
      h06d_shiftlog_formula_set(
        predictor$column[[1L]],
        ar = TRUE
      )$fixed_site_additive
    )
    independent_status <- h06d_shiftlog_model_status(
      independent_glmmtmb$value
    )
    ar_status <- h06d_shiftlog_model_status(ar_capture$value)
    if (!is.null(independent_glmmtmb$value) && !is.null(ar_capture$value)) {
      independent_effect <- h06d_shiftlog_effect_row(
        independent_glmmtmb$value,
        predictor,
        "glmmTMB independent Gaussian calibration"
      )
      ar_effect <- h06d_shiftlog_effect_row(
        ar_capture$value,
        predictor,
        "actual-date gap-aware Gaussian AR(1) counterpart"
      )
      ar_parameters <- h06d_shiftlog_ar_parameters(ar_capture$value)
      post_ar_lag <- h06d_shiftlog_lag_screen(
        ar_capture$frame,
        as.numeric(stats::residuals(ar_capture$value))
      )
      post_ar_lag_site_rows[[predictor_id]] <- post_ar_lag$by_site |>
        dplyr::mutate(
          run_id = h06d_shiftlog_pilot_run_id(),
          predictor_order = predictor$predictor_order[[1L]],
          predictor_id = predictor_id,
          .before = 1L
        )
      engine_shift <- abs(
        independent_effect$link_estimate - gaussian_effect$link_estimate
      ) /
        gaussian_effect$link_standard_error
      ar_shift <- abs(
        ar_effect$link_estimate - gaussian_effect$link_estimate
      ) /
        gaussian_effect$link_standard_error
      ar_acceptable <- isTRUE(independent_status$converged) &&
        isTRUE(independent_status$positive_definite_hessian) &&
        !isTRUE(independent_status$singular) &&
        isTRUE(ar_status$converged) &&
        isTRUE(ar_status$positive_definite_hessian) &&
        !isTRUE(ar_status$singular) &&
        is.finite(ar_parameters$ar_rho) &&
        abs(ar_parameters$ar_rho) < 0.95 &&
        ar_shift < 1 &&
        abs(post_ar_lag$overall$residual_lag1) < 0.20 &&
        post_ar_lag$overall$maximum_absolute_site_lag1 < 0.30
      ar_disposition <- dplyr::case_when(
        !isTRUE(independent_status$converged) ||
          !isTRUE(independent_status$positive_definite_hessian) ||
          isTRUE(independent_status$singular) ~
          "NOT_ACCEPTABLE_INDEPENDENT_ENGINE_CALIBRATION",
        !isTRUE(ar_status$converged) ||
          !isTRUE(ar_status$positive_definite_hessian) ||
          isTRUE(ar_status$singular) ~
          "NOT_ACCEPTABLE_AR_NUMERICAL_FAILURE",
        !is.finite(ar_parameters$ar_rho) ||
          abs(ar_parameters$ar_rho) >= 0.95 ~
          "NOT_ACCEPTABLE_AR_RHO_BOUNDARY",
        ar_shift >= 1 ~ "NOT_ACCEPTABLE_AR_EFFECT_INSTABILITY",
        abs(post_ar_lag$overall$residual_lag1) >= 0.20 ||
          post_ar_lag$overall$maximum_absolute_site_lag1 >= 0.30 ~
          "NOT_ACCEPTABLE_POST_AR_RESIDUAL_DEPENDENCE",
        ar_acceptable ~ "ACCEPTABLE_TRIGGERED_AR_COUNTERPART",
        TRUE ~ "NOT_ACCEPTABLE_AR_UNCLASSIFIED_FAILURE"
      )
      ar_summary <- tibble::tibble(
        ar_trigger = TRUE,
        ar_support_adequate = TRUE,
        independent_glmmtmb_fitted = TRUE,
        ar_fitted = TRUE,
        independent_engine_converged = independent_status$converged,
        independent_engine_positive_definite_hessian = independent_status$positive_definite_hessian,
        independent_engine_singular = independent_status$singular,
        independent_engine_singularity_method = independent_status$singularity_method,
        ar_converged = ar_status$converged,
        ar_positive_definite_hessian = ar_status$positive_definite_hessian,
        ar_singular = ar_status$singular,
        ar_singularity_method = ar_status$singularity_method,
        ar_minimum_random_effect_standard_deviation = ar_status$minimum_random_effect_standard_deviation,
        ar_minimum_scaled_covariance_eigenvalue = ar_status$minimum_scaled_covariance_eigenvalue,
        independent_engine_shift_in_gaussian_se = engine_shift,
        ar_effect_shift_in_gaussian_se = ar_shift,
        ar_rho = ar_parameters$ar_rho,
        ar_standard_deviation = ar_parameters$ar_standard_deviation,
        post_ar_residual_lag1 = post_ar_lag$overall$residual_lag1,
        post_ar_maximum_absolute_site_lag1 = post_ar_lag$overall$maximum_absolute_site_lag1,
        ar_disposition = ar_disposition
      )
    } else {
      ar_summary <- ar_summary |>
        dplyr::mutate(
          independent_glmmtmb_fitted = !is.null(independent_glmmtmb$value),
          ar_fitted = !is.null(ar_capture$value),
          ar_disposition = "NOT_ACCEPTABLE_AR_FIT_FAILURE"
        )
    }
  } else if (isTRUE(lag$overall$ar_trigger)) {
    ar_summary <- ar_summary |>
      dplyr::mutate(
        ar_disposition = "NOT_ACCEPTABLE_INSUFFICIENT_TRUE_DATE_AR_SUPPORT"
      )
  }

  registered_status <- h06d_shiftlog_registered_status(
    registered$value,
    registered
  )
  numerical_disposition <- if (
    isTRUE(gaussian_status$converged) &&
      isTRUE(gaussian_status$positive_definite_hessian) &&
      !isTRUE(gaussian_status$singular) &&
      hierarchy_numerically_acceptable &&
      isTRUE(additive_design$estimable) &&
      isTRUE(heterogeneity_design$estimable)
  ) {
    "ACCEPTABLE"
  } else {
    "NOT_ACCEPTABLE_NUMERICAL_OR_DESIGN_FAILURE"
  }
  major_failure <- startsWith(numerical_disposition, "NOT_ACCEPTABLE") ||
    startsWith(residual_diagnostics$residual_disposition, "NOT_ACCEPTABLE") ||
    startsWith(residual_diagnostics$bound_disposition, "NOT_ACCEPTABLE") ||
    startsWith(
      family_sensitivity$family_sensitivity_disposition,
      "NOT_ACCEPTABLE"
    ) ||
    startsWith(ar_summary$ar_disposition, "NOT_ACCEPTABLE")
  overall_disposition <- if (major_failure) {
    "NOT_ACCEPTABLE"
  } else {
    paste0(
      "PILOT_ROUTE_ADEQUATE_PENDING_EXPLICIT_AUTHOR_ACCEPTANCE_OF_",
      "GE_10_PERCENT_ZERO_MASS_AND_STATED_LIMITATIONS"
    )
  }

  sample_rows[[predictor_id]] <- frame_row |>
    dplyr::select(
      "run_id",
      "predictor_order",
      "predictor_id",
      "participant_days",
      "participants",
      "sites",
      "exact_zeros",
      "exact_zero_fraction",
      "positive_values",
      "frame_path",
      "frame_file_sha256",
      "frame_object_sha256"
    )
  effect_rows[[predictor_id]] <- dplyr::bind_rows(
    gaussian_effect |>
      dplyr::mutate(
        inferential_role = "candidate primary estimate from exact reused REML object"
      ),
    student_t_effect |>
      dplyr::mutate(
        inferential_role = "distributional sensitivity; never a selected replacement"
      )
  ) |>
    dplyr::mutate(run_id = h06d_shiftlog_pilot_run_id(), .before = 1L)
  test_rows[[predictor_id]] <- dplyr::bind_rows(
    association_test,
    heterogeneity_test
  ) |>
    dplyr::mutate(
      run_id = h06d_shiftlog_pilot_run_id(),
      predictor_order = predictor$predictor_order[[1L]],
      predictor_id = predictor_id,
      metric_slot = 3L,
      metric_id = "l10_mean_medi",
      bh_adjusted_p_value = NA_real_,
      adjusted_decision = NA,
      .before = 1L
    )
  diagnostic_rows[[predictor_id]] <- dplyr::bind_cols(
    tibble::tibble(
      run_id = h06d_shiftlog_pilot_run_id(),
      predictor_order = predictor$predictor_order[[1L]],
      predictor_id = predictor_id,
      participant_days = nrow(frame),
      participants = dplyr::n_distinct(frame$participant_key),
      sites = dplyr::n_distinct(frame$site),
      numerical_disposition = numerical_disposition,
      additive_design_estimable = additive_design$estimable,
      heterogeneity_design_estimable = heterogeneity_design$estimable
    ),
    gaussian_status,
    residual_diagnostics
  )
  zero_mass_rows[[predictor_id]] <- h06d_shiftlog_zero_mass_cells(
    frame,
    predictor
  ) |>
    dplyr::mutate(run_id = h06d_shiftlog_pilot_run_id(), .before = 1L)
  family_rows[[predictor_id]] <- family_sensitivity |>
    dplyr::mutate(
      run_id = h06d_shiftlog_pilot_run_id(),
      predictor_order = predictor$predictor_order[[1L]],
      predictor_id = predictor_id,
      .before = 1L
    )
  lag_rows[[predictor_id]] <- lag$overall |>
    dplyr::mutate(
      run_id = h06d_shiftlog_pilot_run_id(),
      predictor_order = predictor$predictor_order[[1L]],
      predictor_id = predictor_id,
      .before = 1L
    )
  lag_site_rows[[predictor_id]] <- lag$by_site |>
    dplyr::mutate(
      run_id = h06d_shiftlog_pilot_run_id(),
      predictor_order = predictor$predictor_order[[1L]],
      predictor_id = predictor_id,
      .before = 1L
    )
  ar_rows[[predictor_id]] <- ar_summary |>
    dplyr::mutate(
      run_id = h06d_shiftlog_pilot_run_id(),
      predictor_order = predictor$predictor_order[[1L]],
      predictor_id = predictor_id,
      .before = 1L
    )
  registered_rows[[predictor_id]] <- registered_status |>
    dplyr::mutate(
      run_id = h06d_shiftlog_pilot_run_id(),
      predictor_order = predictor$predictor_order[[1L]],
      predictor_id = predictor_id,
      .before = 1L
    )
  equal_site_rows[[predictor_id]] <- standardized$estimates |>
    dplyr::mutate(
      run_id = h06d_shiftlog_pilot_run_id(),
      predictor_order = predictor$predictor_order[[1L]],
      predictor_id = predictor_id,
      .before = 1L
    )
  equal_site_contrast_rows[[predictor_id]] <- standardized$contrast |>
    dplyr::mutate(
      run_id = h06d_shiftlog_pilot_run_id(),
      predictor_order = predictor$predictor_order[[1L]],
      predictor_id = predictor_id,
      .before = 1L
    )
  equal_site_grid_rows[[predictor_id]] <- standardized$site_grid |>
    dplyr::mutate(
      run_id = h06d_shiftlog_pilot_run_id(),
      predictor_order = predictor$predictor_order[[1L]],
      predictor_id = predictor_id,
      .before = 1L
    )
  provenance_rows[[predictor_id]] <- reference_row |>
    dplyr::mutate(
      run_id = h06d_shiftlog_pilot_run_id(),
      frame_path = frame_row$frame_path[[1L]],
      frame_file_sha256 = frame_row$frame_file_sha256[[1L]],
      formula = h06d_shiftlog_formula_text(formulas$fixed_site_additive),
      family = "Gaussian identity",
      fitting_method = "REML",
      reuse_verified = TRUE,
      relabel_refit_performed = FALSE,
      .before = 1L
    )
  runtime_rows[[predictor_id]] <- tibble::tibble(
    run_id = h06d_shiftlog_pilot_run_id(),
    predictor_order = predictor$predictor_order[[1L]],
    predictor_id = predictor_id,
    reused_additive_reml_seconds = 0,
    historical_additive_reml_seconds = gaussian_reml_capture$elapsed_seconds,
    reduced_ml_seconds = reduced_ml$elapsed_seconds,
    additive_ml_seconds = additive_ml$elapsed_seconds,
    heterogeneity_ml_seconds = heterogeneity_ml$elapsed_seconds,
    student_t_seconds = student_t$elapsed_seconds,
    registered_benchmark_seconds = registered$elapsed_seconds,
    independent_glmmtmb_seconds = if (is.null(independent_glmmtmb)) {
      0
    } else {
      independent_glmmtmb$elapsed_seconds
    },
    ar_seconds = if (is.null(ar_capture)) 0 else ar_capture$elapsed_seconds
  ) |>
    dplyr::mutate(
      newly_fitted_seconds = .data$reduced_ml_seconds +
        .data$additive_ml_seconds +
        .data$heterogeneity_ml_seconds +
        .data$student_t_seconds +
        .data$registered_benchmark_seconds +
        .data$independent_glmmtmb_seconds +
        .data$ar_seconds
    )
  verdict_rows[[predictor_id]] <- tibble::tibble(
    run_id = h06d_shiftlog_pilot_run_id(),
    predictor_order = predictor$predictor_order[[1L]],
    predictor_id = predictor_id,
    numerical_disposition = numerical_disposition,
    residual_disposition = residual_diagnostics$residual_disposition,
    bound_disposition = residual_diagnostics$bound_disposition,
    zero_mass_disposition = residual_diagnostics$zero_mass_disposition,
    family_sensitivity_disposition = family_sensitivity$family_sensitivity_disposition,
    temporal_disposition = ar_summary$ar_disposition,
    registered_benchmark_disposition = registered_status$disposition,
    overall_pilot_disposition = overall_disposition,
    recommendation = ifelse(
      overall_disposition == "NOT_ACCEPTABLE",
      "DO_NOT_RELEASE_FULL_L10_SHIFTED_LOG_BATCH",
      paste0(
        "AUTHOR_MAY_APPROVE_BOUNDED_SIX_SCENARIO_L10_ONLY_BATCH_WITH_",
        "ZERO_MASS_AND_LISTED_LIMITATIONS_EXPLICITLY_ACCEPTED"
      )
    )
  )
  new_model_bundle[[predictor_id]] <- list(
    reused_additive_reml_reference = reference_row,
    reduced_ml = reduced_ml,
    additive_ml = additive_ml,
    heterogeneity_ml = heterogeneity_ml,
    student_t = student_t,
    registered_benchmark = registered,
    independent_glmmtmb = independent_glmmtmb,
    ar = ar_capture
  )
}

#####
# Step 3: Project the bounded later L10-only batch
#####

samples <- dplyr::bind_rows(sample_rows) |>
  dplyr::arrange(.data$predictor_order)
effects <- dplyr::bind_rows(effect_rows) |>
  dplyr::arrange(.data$predictor_order, .data$family)
model_tests <- dplyr::bind_rows(test_rows) |>
  dplyr::arrange(.data$predictor_order, .data$test_type)
diagnostics <- dplyr::bind_rows(diagnostic_rows) |>
  dplyr::arrange(.data$predictor_order)
zero_mass <- dplyr::bind_rows(zero_mass_rows) |>
  dplyr::arrange(.data$predictor_order, .data$site, .data$predictor_level)
family_sensitivity <- dplyr::bind_rows(family_rows) |>
  dplyr::arrange(.data$predictor_order)
lag_overall <- dplyr::bind_rows(lag_rows) |>
  dplyr::arrange(.data$predictor_order)
lag_by_site <- dplyr::bind_rows(lag_site_rows) |>
  dplyr::arrange(.data$predictor_order, .data$site)
post_ar_lag_by_site <- dplyr::bind_rows(post_ar_lag_site_rows) |>
  dplyr::arrange(.data$predictor_order, .data$site)
ar_summary <- dplyr::bind_rows(ar_rows) |>
  dplyr::arrange(.data$predictor_order)
registered_benchmark <- dplyr::bind_rows(registered_rows) |>
  dplyr::arrange(.data$predictor_order)
equal_site <- dplyr::bind_rows(equal_site_rows) |>
  dplyr::arrange(.data$predictor_order, .data$target_index)
equal_site_contrasts <- dplyr::bind_rows(equal_site_contrast_rows) |>
  dplyr::arrange(.data$predictor_order)
equal_site_grid <- dplyr::bind_rows(equal_site_grid_rows) |>
  dplyr::arrange(.data$predictor_order, .data$target_index, .data$site)
runtime <- dplyr::bind_rows(runtime_rows) |>
  dplyr::arrange(.data$predictor_order)
provenance <- dplyr::bind_rows(provenance_rows) |>
  dplyr::arrange(.data$predictor_order)
pilot_verdict <- dplyr::bind_rows(verdict_rows) |>
  dplyr::arrange(.data$predictor_order)

pilot_wall_seconds <- unname(proc.time()[["elapsed"]] - pilot_started)
hierarchy_seconds <- sum(
  runtime$reduced_ml_seconds +
    runtime$additive_ml_seconds +
    runtime$heterogeneity_ml_seconds
)
distribution_seconds <- sum(runtime$student_t_seconds)
benchmark_seconds <- sum(runtime$registered_benchmark_seconds)
temporal_seconds <- sum(
  runtime$independent_glmmtmb_seconds + runtime$ar_seconds
)
historical_mean_reml_seconds <- mean(unlist(lapply(
  historical_bundle$models,
  function(model) model$one_part$elapsed_seconds
)))
projected_hierarchy_seconds <- hierarchy_seconds * 2
projected_distribution_seconds <- distribution_seconds * 6
projected_benchmark_seconds <- benchmark_seconds * 2
projected_temporal_seconds <- temporal_seconds * 6
projected_influence_refits <- 440L
projected_influence_seconds <-
  projected_influence_refits * historical_mean_reml_seconds
projected_model_seconds <-
  projected_hierarchy_seconds +
  projected_distribution_seconds +
  projected_benchmark_seconds +
  projected_temporal_seconds +
  projected_influence_seconds
projected_full_seconds <- 1.5 * projected_model_seconds

runtime_projection <- tibble::tibble(
  pilot_predictors = 3L,
  pilot_scenarios = 1L,
  pilot_wall_seconds = pilot_wall_seconds,
  reused_additive_reml_objects = 3L,
  newly_fitted_model_seconds = sum(runtime$newly_fitted_seconds),
  triggered_ar_predictors = sum(ar_summary$ar_trigger),
  projected_full_scenarios = 6L,
  projected_full_predictor_scenarios = 18L,
  projected_hierarchy_seconds = projected_hierarchy_seconds,
  projected_distribution_seconds = projected_distribution_seconds,
  projected_benchmark_seconds = projected_benchmark_seconds,
  projected_temporal_seconds = projected_temporal_seconds,
  projected_influence_refits = projected_influence_refits,
  projected_influence_seconds = projected_influence_seconds,
  projection_overhead_multiplier = 1.5,
  projected_full_seconds = projected_full_seconds,
  projected_full_minutes = projected_full_seconds / 60,
  runtime_classification = ifelse(
    projected_full_seconds > 120,
    "HEAVY_GT_2_MINUTES_REQUIRES_SEPARATE_RUNTIME_APPROVAL",
    "BOUNDED_LE_2_MINUTES_BUT_SCIENTIFIC_AUTHOR_APPROVAL_STILL_REQUIRED"
  ),
  projection_note = paste0(
    "Hierarchy and benchmark scale to two near-eye inferential scenarios; ",
    "Student-t and temporal work scale conservatively to all six scenarios; ",
    "440 later influence refits use the observed historical shifted-log REML ",
    "mean fit time; 50% overhead is added."
  )
)

#####
# Step 4: Write new pilot-only artifacts and preserve history
#####

model_relative <- paste0(
  "artifacts/07_models/H06_daily/",
  "H06_daily_l10_shiftlog_pilot_new_models.rds"
)
saveRDS(
  list(
    new_models = new_model_bundle,
    reused_model_references = provenance,
    decision_sha256 = h06d_shiftlog_decision_sha256(),
    r_version = as.character(getRversion()),
    package_versions = vapply(
      required_packages,
      function(package) as.character(utils::packageVersion(package)),
      character(1)
    ),
    compute_clearance = "coordinator message received 2026-08-12"
  ),
  file.path(root, model_relative),
  compress = "xz"
)

outputs <- list(
  samples,
  effects,
  model_tests,
  diagnostics,
  zero_mass,
  family_sensitivity,
  lag_overall,
  lag_by_site,
  post_ar_lag_by_site,
  ar_summary,
  registered_benchmark,
  equal_site,
  equal_site_contrasts,
  equal_site_grid,
  runtime,
  runtime_projection,
  provenance,
  pilot_verdict
)
names(outputs) <- c(
  file.path(roots$tables, "H06_daily_l10_shiftlog_pilot_samples.csv"),
  file.path(roots$tables, "H06_daily_l10_shiftlog_pilot_effects.csv"),
  file.path(roots$tables, "H06_daily_l10_shiftlog_pilot_model_tests.csv"),
  file.path(roots$diagnostics, "H06_daily_l10_shiftlog_pilot_diagnostics.csv"),
  file.path(roots$diagnostics, "H06_daily_l10_shiftlog_pilot_zero_mass.csv"),
  file.path(
    roots$diagnostics,
    "H06_daily_l10_shiftlog_pilot_family_sensitivity.csv"
  ),
  file.path(
    roots$diagnostics,
    "H06_daily_l10_shiftlog_pilot_residual_lag.csv"
  ),
  file.path(
    roots$diagnostics,
    "H06_daily_l10_shiftlog_pilot_site_residual_lag.csv"
  ),
  file.path(
    roots$diagnostics,
    "H06_daily_l10_shiftlog_pilot_post_ar_site_residual_lag.csv"
  ),
  file.path(
    roots$diagnostics,
    "H06_daily_l10_shiftlog_pilot_ar_counterparts.csv"
  ),
  file.path(
    roots$diagnostics,
    "H06_daily_l10_shiftlog_pilot_registered_benchmark.csv"
  ),
  file.path(
    roots$tables,
    "H06_daily_l10_shiftlog_pilot_equal_site_estimates.csv"
  ),
  file.path(
    roots$tables,
    "H06_daily_l10_shiftlog_pilot_equal_site_contrasts.csv"
  ),
  file.path(
    roots$source_data,
    "H06_daily_l10_shiftlog_pilot_equal_site_grid.csv"
  ),
  file.path(roots$diagnostics, "H06_daily_l10_shiftlog_pilot_runtime.csv"),
  file.path(
    roots$diagnostics,
    "H06_daily_l10_shiftlog_pilot_runtime_projection.csv"
  ),
  file.path(
    roots$diagnostics,
    "H06_daily_l10_shiftlog_pilot_model_provenance.csv"
  ),
  file.path(roots$diagnostics, "H06_daily_l10_shiftlog_pilot_verdict.csv")
)
for (path in names(outputs)) {
  readr::write_csv(outputs[[path]], path)
}

historical_after <- historical_preservation |>
  dplyr::mutate(
    sha256_after = vapply(
      file.path(root, .data$relative_path),
      h06d_shiftlog_sha256,
      character(1)
    ),
    bytes_after = unname(file.info(file.path(root, .data$relative_path))$size),
    preserved_after_pilot = .data$sha256 == .data$sha256_after &
      .data$bytes == .data$bytes_after
  )
h06d_shiftlog_assert(
  all(historical_after$preserved_after_pilot),
  "The shifted-log pilot changed a historical H06-D-001/H06-D-002 artifact"
)
readr::write_csv(
  historical_after,
  file.path(
    roots$diagnostics,
    "H06_daily_l10_shiftlog_historical_preservation_after_pilot.csv"
  )
)

h06d_shiftlog_assert(
  nrow(model_tests) == 6L &&
    all(is.na(model_tests$bh_adjusted_p_value)) &&
    !any(model_tests$multiplicity_status != "PILOT_RAW_ONLY_NO_BH_UPDATE") &&
    nrow(pilot_verdict) == 3L,
  "Shifted-log pilot output-scope contract failed"
)

message(
  "H06-D-003 shifted-log pilot complete in ",
  sprintf("%.2f", pilot_wall_seconds),
  " s; projected bounded full L10-only batch ",
  sprintf("%.2f", projected_full_seconds),
  " s; stopping at H06-D-G2P-L10-SHIFTLOG."
)
