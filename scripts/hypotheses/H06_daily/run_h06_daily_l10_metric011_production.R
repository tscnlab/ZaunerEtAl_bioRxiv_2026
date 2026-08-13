#!/usr/bin/env Rscript

# Serial L10-only production under METRIC-011. This script neither reads nor
# refits another daily metric. Separated occurrence models remain visible but
# cannot contribute an ordinary p-value or replace the joint two-part slot.

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
  "digest", "dplyr", "glmmTMB", "lme4", "performance", "readr", "tibble",
  "tidyr"
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
pilot_runtime <- readr::read_csv(
  file.path(
    roots$diagnostics,
    "H06_daily_l10_metric011_pilot_runtime_projection.csv"
  ),
  show_col_types = FALSE
)
h06d_l10_assert(
  nrow(pilot_runtime) == 1L &&
    !pilot_runtime$classified_heavy &&
    pilot_runtime$authorization_disposition == "BOUNDED_NOT_HEAVY_MAY_PROCEED",
  "METRIC-011 production lacks a passed runtime pilot"
)

protected <- readr::read_csv(
  file.path(roots$diagnostics, "H06_daily_l10_metric011_protected_baseline.csv"),
  show_col_types = FALSE
)
h06d_l10_assert(
  all(vapply(
    file.path(root, protected$relative_path),
    h06d_l10_sha256,
    character(1)
  ) == protected$sha256_before),
  "A protected H06_daily artifact changed before L10 production"
)

frame_registry <- readr::read_csv(
  file.path(roots$model_data, "H06_daily_l10_metric011_frame_registry.csv"),
  show_col_types = FALSE
)
change_inventory <- readr::read_csv(
  file.path(
    roots$diagnostics,
    "H06_daily_l10_metric011_scenario_component_change_inventory.csv"
  ),
  show_col_types = FALSE
)
h06d_l10_assert(
  nrow(frame_registry) == 36L &&
    nrow(change_inventory) == 36L &&
    !any(change_inventory$fit_action == "PRESERVE_ACCEPTED_FIT_BYTE_FOR_BYTE"),
  "METRIC-011 production registry or fit-action inventory failed"
)

predictors <- h06d_l10_predictor_registry()
parent_registry <- frame_registry |>
  dplyr::filter(.data$component == "zero_occurrence") |>
  dplyr::arrange(.data$predictor_order, .data$run_order)
h06d_l10_assert(nrow(parent_registry) == 18L, "Expected 18 L10 parent analyses")

read_component_frame <- function(registry, component) {
  row <- frame_registry |>
    dplyr::filter(
      .data$run_id == registry$run_id[[1L]],
      .data$predictor_id == registry$predictor_id[[1L]],
      .data$component == .env$component
    )
  h06d_l10_assert(nrow(row) == 1L, "Component frame lookup failed")
  frame <- readRDS(file.path(root, row$frame_path[[1L]]))
  h06d_l10_assert(
    h06d_l10_object_sha256(frame) == row$frame_object_sha256[[1L]] &&
      h06d_l10_sha256(file.path(root, row$frame_path[[1L]])) ==
        row$frame_file_sha256[[1L]],
    "Component frame identity failed"
  )
  frame
}

safe_ar_parameters <- function(model) {
  tryCatch(
    h06d_l10_ar_parameters(model),
    error = function(condition) tibble::tibble(
      ar_standard_deviation = NA_real_,
      ar_rho = NA_real_
    )
  )
}

effects_rows <- list()
standardized_rows <- list()
contrast_rows <- list()
diagnostic_rows <- list()
lag_rows <- list()
lag_site_rows <- list()
ar_rows <- list()
sensitivity_rows <- list()
map_coefficient_rows <- list()
map_prediction_rows <- list()
test_rows <- list()
registered_rows <- list()
runtime_rows <- list()
model_bundle <- list()

started_all <- proc.time()[["elapsed"]]

for (analysis_index in seq_len(nrow(parent_registry))) {
  registry <- parent_registry[analysis_index, ]
  predictor <- predictors |>
    dplyr::filter(.data$predictor_id == registry$predictor_id[[1L]])
  h06d_l10_assert(nrow(predictor) == 1L, "Predictor lookup failed")
  key <- paste(registry$run_id[[1L]], registry$predictor_id[[1L]], sep = "__")
  message("METRIC-011 production: ", key)
  occurrence_frame <- read_component_frame(registry, "zero_occurrence")
  positive_frame <- read_component_frame(registry, "positive_magnitude")
  formulas <- h06d_l10_formula_set(predictor$column[[1L]])

  occurrence <- h06d_l10_fit_occurrence(
    occurrence_frame,
    formulas$fixed_site_additive
  )
  positive <- h06d_l10_fit_positive_gaussian(
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
    !is.null(occurrence$value) && !is.null(positive$value) &&
      !is.null(positive_t$value) && !is.null(one_part$value),
    "A core METRIC-011 production fit failed for %s",
    key
  )

  occurrence_status <- h06d_l10_model_status(occurrence$value)
  positive_status <- h06d_l10_model_status(positive$value)
  occurrence_diagnostic <- h06d_l10_occurrence_diagnostics(
    occurrence$value,
    occurrence_frame
  )
  positive_diagnostic <- h06d_l10_positive_diagnostics(
    positive$value,
    positive_frame
  )
  occurrence_effect <- h06d_l10_effect_row(
    occurrence$value,
    predictor,
    "zero_occurrence",
    "binomial logit"
  )
  positive_effect <- h06d_l10_effect_row(
    positive$value,
    predictor,
    "positive_magnitude",
    "Gaussian identity on log10-positive L10"
  )
  positive_t_effect <- h06d_l10_effect_row(
    positive_t$value,
    predictor,
    "positive_magnitude",
    "Student-t identity on log10-positive L10 sensitivity"
  )
  one_part_effect <- h06d_l10_effect_row(
    one_part$value,
    predictor,
    "positive_magnitude",
    "one-part Gaussian identity on log10(L10 + 0.1) sensitivity"
  )
  positive_t_shift <- abs(
    positive_t_effect$link_estimate - positive_effect$link_estimate
  ) / positive_effect$link_standard_error
  positive_t_direction_reversal <-
    sign(positive_t_effect$link_estimate) != sign(positive_effect$link_estimate)
  positive_family_status <- dplyr::case_when(
    is.null(positive_t$value) || !isTRUE(h06d_l10_model_status(positive_t$value)$converged) ~
      "SENSITIVITY_UNRESOLVED_T_NUMERICAL_FAILURE_NO_STANDALONE_CLAIM",
    positive_t_shift > 2 ~
      "NOT_ACCEPTABLE_FAMILY_SENSITIVITY",
    positive_t_direction_reversal || positive_t_shift >= 1 ~
      paste0(
        "ACCEPTABLE_ONLY_WITH_MAJOR_FAMILY_SENSITIVITY_LIMITATION_",
        "NO_DIRECTIONAL_CLAIM"
      ),
    positive_t_shift >= 0.5 ~
      paste0(
        "ACCEPTABLE_ONLY_WITH_FAMILY_SENSITIVITY_LIMITATION_",
        "NO_CONFIRMATORY_CLAIM"
      ),
    TRUE ~ "ACCEPTABLE_FOR_DESCRIPTIVE_POSITIVE_COMPONENT_NO_CONFIRMATORY_CLAIM"
  )

  occurrence_residual <- as.numeric(stats::residuals(
    occurrence$value,
    type = "pearson"
  ))
  positive_residual <- as.numeric(stats::residuals(positive$value))
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
      h06d_l10_formula_set(
        predictor$column[[1L]],
        ar = TRUE
      )$fixed_site_additive,
      "zero_occurrence"
    )
  }
  if (
    isTRUE(positive_lag$overall$ar_trigger) &&
      isTRUE(positive_lag$overall$ar_support_adequate)
  ) {
    positive_ar <- h06d_l10_fit_ar(
      positive_frame,
      h06d_l10_formula_set(
        predictor$column[[1L]],
        ar = TRUE
      )$fixed_site_additive,
      "positive_magnitude"
    )
  }

  ar_component_rows <- list()
  for (component in c("zero_occurrence", "positive_magnitude")) {
    lag <- if (component == "zero_occurrence") occurrence_lag else positive_lag
    capture <- if (component == "zero_occurrence") occurrence_ar else positive_ar
    primary_effect <- if (component == "zero_occurrence") {
      occurrence_effect
    } else {
      positive_effect
    }
    if (is.null(capture) || is.null(capture$value)) {
      ar_component_rows[[component]] <- tibble::tibble(
        component = component,
        ar_trigger = lag$overall$ar_trigger,
        ar_support_adequate = lag$overall$ar_support_adequate,
        ar_fitted = FALSE,
        ar_rho = NA_real_,
        effect_shift_in_primary_se = NA_real_,
        ar_acceptable = !lag$overall$ar_trigger,
        disposition = ifelse(
          lag$overall$ar_trigger,
          "TRIGGERED_BUT_NOT_ESTIMABLE",
          "NOT_TRIGGERED"
        )
      )
    } else {
      parameter <- safe_ar_parameters(capture$value)
      ar_effect <- h06d_l10_effect_row(
        capture$value,
        predictor,
        component,
        "gap-aware daily AR(1) counterpart"
      )
      shift <- abs(ar_effect$link_estimate - primary_effect$link_estimate) /
        primary_effect$link_standard_error
      status <- h06d_l10_model_status(capture$value)
      acceptable <- isTRUE(status$converged) &&
        is.finite(parameter$ar_rho) &&
        abs(parameter$ar_rho) < 0.95 && shift < 1
      ar_component_rows[[component]] <- tibble::tibble(
        component = component,
        ar_trigger = lag$overall$ar_trigger,
        ar_support_adequate = lag$overall$ar_support_adequate,
        ar_fitted = TRUE,
        ar_rho = parameter$ar_rho,
        effect_shift_in_primary_se = shift,
        ar_acceptable = acceptable,
        disposition = dplyr::case_when(
          is.finite(parameter$ar_rho) && abs(parameter$ar_rho) >= 0.95 ~
            "NOT_ACCEPTABLE_RHO_BOUNDARY",
          !isTRUE(status$converged) ~ "NOT_ACCEPTABLE_CONVERGENCE",
          shift >= 1 ~ "NOT_ACCEPTABLE_EFFECT_INSTABILITY",
          TRUE ~ "ACCEPTABLE"
        )
      )
    }
  }
  ar_component <- dplyr::bind_rows(ar_component_rows)
  occurrence_ar_row <- ar_component |>
    dplyr::filter(.data$component == "zero_occurrence")
  occurrence_failure <- dplyr::case_when(
    !isTRUE(occurrence_status$converged) ||
      !isTRUE(occurrence_status$positive_definite_hessian) ~
      "NON_ESTIMABLE_NUMERICAL_FAILURE",
    isTRUE(occurrence_diagnostic$separation_flag) &&
      isTRUE(occurrence_ar_row$ar_trigger) &&
      !isTRUE(occurrence_ar_row$ar_acceptable) ~
      "NON_ESTIMABLE_SEPARATION_AND_AR_FAILURE",
    isTRUE(occurrence_diagnostic$separation_flag) ~
      "NON_ESTIMABLE_SEPARATION",
    isTRUE(occurrence_ar_row$ar_trigger) &&
      !isTRUE(occurrence_ar_row$ar_acceptable) ~
      "NON_ESTIMABLE_AR_COMPONENT_FAILURE",
    TRUE ~ "ESTIMABLE"
  )

  effects_rows[[key]] <- dplyr::bind_rows(
    occurrence_effect,
    positive_effect,
    positive_t_effect,
    one_part_effect
  ) |>
    dplyr::mutate(
      run_order = registry$run_order[[1L]],
      run_id = registry$run_id[[1L]],
      dataset_id = registry$dataset_id[[1L]],
      placement_id = registry$placement_id[[1L]],
      sample_role = registry$sample_role[[1L]],
      inferential_status = dplyr::case_when(
        .data$component == "zero_occurrence" ~ occurrence_failure,
        grepl("Student-t", .data$family, fixed = TRUE) ~ positive_family_status,
        grepl("Gaussian identity on log10-positive", .data$family, fixed = TRUE) ~
          positive_family_status,
        TRUE ~ "DIAGNOSTIC_SENSITIVITY_ONLY"
      ),
      .before = 1L
    )

  sensitivity_rows[[key]] <- tibble::tibble(
    run_order = registry$run_order[[1L]],
    run_id = registry$run_id[[1L]],
    dataset_id = registry$dataset_id[[1L]],
    placement_id = registry$placement_id[[1L]],
    sample_role = registry$sample_role[[1L]],
    predictor_order = predictor$predictor_order[[1L]],
    predictor_id = predictor$predictor_id[[1L]],
    gaussian_positive_link_estimate = positive_effect$link_estimate,
    gaussian_positive_link_standard_error = positive_effect$link_standard_error,
    student_t_positive_link_estimate = positive_t_effect$link_estimate,
    student_t_effect_shift_in_gaussian_se = positive_t_shift,
    student_t_direction_reversal = positive_t_direction_reversal,
    positive_family_status = positive_family_status,
    one_part_shifted_log_link_estimate = one_part_effect$link_estimate,
    one_part_inferential_role = "diagnostic sensitivity only"
  )

  diagnostic_rows[[key]] <- dplyr::bind_rows(
    dplyr::bind_cols(
      tibble::tibble(component = "zero_occurrence"),
      occurrence_status,
      occurrence_diagnostic
    ),
    dplyr::bind_cols(
      tibble::tibble(component = "positive_magnitude"),
      positive_status,
      positive_diagnostic
    )
  ) |>
    dplyr::mutate(
      run_order = registry$run_order[[1L]],
      run_id = registry$run_id[[1L]],
      dataset_id = registry$dataset_id[[1L]],
      placement_id = registry$placement_id[[1L]],
      sample_role = registry$sample_role[[1L]],
      predictor_order = predictor$predictor_order[[1L]],
      predictor_id = predictor$predictor_id[[1L]],
      participant_days = ifelse(
        .data$component == "zero_occurrence",
        nrow(occurrence_frame),
        nrow(positive_frame)
      ),
      participants = ifelse(
        .data$component == "zero_occurrence",
        dplyr::n_distinct(occurrence_frame$participant_key),
        dplyr::n_distinct(positive_frame$participant_key)
      ),
      sites = ifelse(
        .data$component == "zero_occurrence",
        dplyr::n_distinct(occurrence_frame$site),
        dplyr::n_distinct(positive_frame$site)
      ),
      component_disposition = dplyr::case_when(
        .data$component == "zero_occurrence" ~ occurrence_failure,
        TRUE ~ positive_family_status
      ),
      .before = 1L
    )

  lag_rows[[key]] <- dplyr::bind_rows(
    occurrence_lag$overall |>
      dplyr::mutate(component = "zero_occurrence", .before = 1L),
    positive_lag$overall |>
      dplyr::mutate(component = "positive_magnitude", .before = 1L)
  ) |>
    dplyr::mutate(
      run_id = registry$run_id[[1L]],
      predictor_order = predictor$predictor_order[[1L]],
      predictor_id = predictor$predictor_id[[1L]],
      .before = 1L
    )
  lag_site_rows[[key]] <- dplyr::bind_rows(
    occurrence_lag$by_site |>
      dplyr::mutate(component = "zero_occurrence", .before = 1L),
    positive_lag$by_site |>
      dplyr::mutate(component = "positive_magnitude", .before = 1L)
  ) |>
    dplyr::mutate(
      run_id = registry$run_id[[1L]],
      predictor_order = predictor$predictor_order[[1L]],
      predictor_id = predictor$predictor_id[[1L]],
      .before = 1L
    )
  ar_rows[[key]] <- ar_component |>
    dplyr::mutate(
      run_id = registry$run_id[[1L]],
      dataset_id = registry$dataset_id[[1L]],
      placement_id = registry$placement_id[[1L]],
      sample_role = registry$sample_role[[1L]],
      predictor_order = predictor$predictor_order[[1L]],
      predictor_id = predictor$predictor_id[[1L]],
      .before = 1L
    )

  map_fits <- list()
  for (prior_sd in c(1.5, 3, 6)) {
    map_key <- sprintf("normal_0_%s", gsub("\\.", "_", prior_sd))
    map_fit <- h06d_l10_fit_occurrence_map(
      occurrence_frame,
      formulas$fixed_site_additive,
      prior_sd
    )
    h06d_l10_assert(
      !is.null(map_fit$value),
      "A regularized occurrence sensitivity failed for %s",
      key
    )
    map_summary <- h06d_l10_map_occurrence_summary(
      map_fit$value,
      occurrence_frame,
      predictor,
      formulas$fixed_site_additive,
      prior_sd
    )
    map_coefficient_rows[[paste(key, map_key, sep = "__")]] <-
      map_summary$coefficient |>
      dplyr::mutate(
        run_id = registry$run_id[[1L]],
        dataset_id = registry$dataset_id[[1L]],
        placement_id = registry$placement_id[[1L]],
        sample_role = registry$sample_role[[1L]],
        predictor_order = predictor$predictor_order[[1L]],
        predictor_id = predictor$predictor_id[[1L]],
        converged = h06d_l10_model_status(map_fit$value)$converged,
        .before = 1L
      )
    map_prediction_rows[[paste(key, map_key, sep = "__")]] <-
      map_summary$predictions |>
      dplyr::mutate(
        run_id = registry$run_id[[1L]],
        dataset_id = registry$dataset_id[[1L]],
        placement_id = registry$placement_id[[1L]],
        sample_role = registry$sample_role[[1L]],
        predictor_order = predictor$predictor_order[[1L]],
        predictor_id = predictor$predictor_id[[1L]],
        prior_standard_deviation = prior_sd,
        inferential_role = paste0(
          "regularized occurrence diagnostic sensitivity; no ordinary ",
          "confidence interval or significance decision"
        ),
        .before = 1L
      )
    map_fits[[map_key]] <- map_fit
  }

  if (occurrence_failure == "ESTIMABLE") {
    standardized <- h06d_l10_pointwise_standardization(
      occurrence$value,
      positive$value,
      occurrence_frame,
      positive_frame,
      predictor,
      formulas
    )
    standardized_rows[[key]] <- standardized$estimates |>
      dplyr::mutate(
        run_id = registry$run_id[[1L]],
        dataset_id = registry$dataset_id[[1L]],
        placement_id = registry$placement_id[[1L]],
        sample_role = registry$sample_role[[1L]],
        predictor_order = predictor$predictor_order[[1L]],
        predictor_id = predictor$predictor_id[[1L]],
        estimand_status = "ESTIMABLE",
        .before = 1L
      )
    contrast_rows[[key]] <- standardized$contrasts |>
      dplyr::mutate(
        run_id = registry$run_id[[1L]],
        dataset_id = registry$dataset_id[[1L]],
        placement_id = registry$placement_id[[1L]],
        sample_role = registry$sample_role[[1L]],
        predictor_order = predictor$predictor_order[[1L]],
        predictor_id = predictor$predictor_id[[1L]],
        estimand_status = "ESTIMABLE",
        .before = 1L
      )
  }

  hierarchy <- list()
  if (registry$test_role[[1L]] %in% c("primary_raw_slot", "gap_raw_slot")) {
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
    additive_design_occurrence <- h06d_l10_design_check(
      occurrence_frame,
      predictor,
      heterogeneity = FALSE
    )
    heterogeneity_design_occurrence <- h06d_l10_design_check(
      occurrence_frame,
      predictor,
      heterogeneity = TRUE
    )
    heterogeneity_design_positive <- h06d_l10_design_check(
      positive_frame,
      predictor,
      heterogeneity = TRUE
    )
    core_hierarchy_fits <- list(
      occurrence_reduced,
      occurrence_heterogeneity,
      positive_reduced,
      positive_additive_ml,
      positive_heterogeneity
    )
    h06d_l10_assert(
      all(vapply(core_hierarchy_fits, function(x) !is.null(x$value), logical(1))),
      "A hierarchy fit failed for %s",
      key
    )

    occurrence_association_diagnostic <- h06d_l10_lrt_row(
      occurrence_reduced$value,
      occurrence$value,
      "zero_occurrence"
    )
    positive_association <- h06d_l10_lrt_row(
      positive_reduced$value,
      positive_additive_ml$value,
      "positive_magnitude"
    )
    occurrence_association <- occurrence_association_diagnostic |>
      dplyr::mutate(
        diagnostic_raw_p_value = .data$raw_p_value,
        raw_p_value = ifelse(occurrence_failure == "ESTIMABLE", .data$raw_p_value, NA_real_),
        test_status = occurrence_failure
      )
    association_joint <- if (occurrence_failure == "ESTIMABLE") {
      h06d_l10_combined_lrt(
        occurrence_association_diagnostic,
        positive_association,
        "association"
      ) |>
        dplyr::mutate(test_status = "ESTIMABLE")
    } else {
      tibble::tibble(
        test_type = "association",
        likelihood_ratio = NA_real_,
        degrees_of_freedom = NA_real_,
        raw_p_value = NA_real_,
        method = "joint two-part test withheld after occurrence component failure",
        occurrence_likelihood_ratio = occurrence_association_diagnostic$likelihood_ratio,
        occurrence_degrees_of_freedom = occurrence_association_diagnostic$degrees_of_freedom,
        occurrence_raw_p_value = NA_real_,
        positive_likelihood_ratio = positive_association$likelihood_ratio,
        positive_degrees_of_freedom = positive_association$degrees_of_freedom,
        positive_raw_p_value = positive_association$raw_p_value,
        test_status = "NON_ESTIMABLE_COMPONENT_FAILURE"
      )
    }

    occurrence_heterogeneity_failure <- if (
      occurrence_failure != "ESTIMABLE"
    ) {
      occurrence_failure
    } else if (!isTRUE(heterogeneity_design_occurrence$estimable)) {
      "NON_ESTIMABLE_DESIGN"
    } else {
      heterogeneity_diagnostic <- h06d_l10_occurrence_diagnostics(
        occurrence_heterogeneity$value,
        occurrence_frame
      )
      heterogeneity_status <- h06d_l10_model_status(
        occurrence_heterogeneity$value
      )
      dplyr::case_when(
        !isTRUE(heterogeneity_status$converged) ~
          "NON_ESTIMABLE_NUMERICAL_FAILURE",
        isTRUE(heterogeneity_diagnostic$separation_flag) ~
          "NON_ESTIMABLE_SEPARATION",
        TRUE ~ "ESTIMABLE"
      )
    }
    occurrence_heterogeneity_diagnostic <- h06d_l10_lrt_row(
      occurrence$value,
      occurrence_heterogeneity$value,
      "zero_occurrence"
    )
    positive_heterogeneity_test <- h06d_l10_lrt_row(
      positive_additive_ml$value,
      positive_heterogeneity$value,
      "positive_magnitude"
    )
    occurrence_heterogeneity_test <- occurrence_heterogeneity_diagnostic |>
      dplyr::mutate(
        diagnostic_raw_p_value = .data$raw_p_value,
        raw_p_value = ifelse(
          occurrence_heterogeneity_failure == "ESTIMABLE",
          .data$raw_p_value,
          NA_real_
        ),
        test_status = occurrence_heterogeneity_failure
      )
    heterogeneity_joint <- if (
      occurrence_heterogeneity_failure == "ESTIMABLE" &&
        isTRUE(heterogeneity_design_positive$estimable)
    ) {
      h06d_l10_combined_lrt(
        occurrence_heterogeneity_diagnostic,
        positive_heterogeneity_test,
        "site_heterogeneity"
      ) |>
        dplyr::mutate(test_status = "ESTIMABLE")
    } else {
      tibble::tibble(
        test_type = "site_heterogeneity",
        likelihood_ratio = NA_real_,
        degrees_of_freedom = NA_real_,
        raw_p_value = NA_real_,
        method = "joint two-part test withheld after component/design failure",
        occurrence_likelihood_ratio = occurrence_heterogeneity_diagnostic$likelihood_ratio,
        occurrence_degrees_of_freedom = occurrence_heterogeneity_diagnostic$degrees_of_freedom,
        occurrence_raw_p_value = NA_real_,
        positive_likelihood_ratio = positive_heterogeneity_test$likelihood_ratio,
        positive_degrees_of_freedom = positive_heterogeneity_test$degrees_of_freedom,
        positive_raw_p_value = positive_heterogeneity_test$raw_p_value,
        test_status = "NON_ESTIMABLE_COMPONENT_FAILURE"
      )
    }

    component_tests <- dplyr::bind_rows(
      occurrence_association |>
        dplyr::mutate(test_type = "association", component_test = TRUE),
      positive_association |>
        dplyr::mutate(
          test_type = "association",
          diagnostic_raw_p_value = .data$raw_p_value,
          test_status = positive_family_status,
          component_test = TRUE
        ),
      occurrence_heterogeneity_test |>
        dplyr::mutate(test_type = "site_heterogeneity", component_test = TRUE),
      positive_heterogeneity_test |>
        dplyr::mutate(
          test_type = "site_heterogeneity",
          diagnostic_raw_p_value = .data$raw_p_value,
          test_status = positive_family_status,
          component_test = TRUE
        )
    )
    joint_tests <- dplyr::bind_rows(association_joint, heterogeneity_joint) |>
      dplyr::mutate(component = "joint_two_part", component_test = FALSE)
    test_rows[[key]] <- dplyr::bind_rows(component_tests, joint_tests) |>
      dplyr::mutate(
        run_id = registry$run_id[[1L]],
        dataset_id = registry$dataset_id[[1L]],
        placement_id = registry$placement_id[[1L]],
        predictor_order = predictor$predictor_order[[1L]],
        predictor_id = predictor$predictor_id[[1L]],
        contrast = predictor$contrast_label[[1L]],
        metric_slot = 3L,
        metric_id = "l10_mean_medi",
        multiplicity_status = ifelse(
          .data$component_test,
          "COMPONENT_DIAGNOSTIC_NOT_A_BH_SLOT",
          "RAW_JOINT_SLOT_FAMILY_INCOMPLETE"
        ),
        .before = 1L
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
    registered_rows[[key]] <- dplyr::bind_rows(
      h06d_l10_registered_status(
        occurrence_registered$value,
        occurrence_registered
      ) |>
        dplyr::mutate(component = "zero_occurrence", .before = 1L),
      h06d_l10_registered_status(
        positive_registered$value,
        positive_registered
      ) |>
        dplyr::mutate(component = "positive_magnitude", .before = 1L)
    ) |>
      dplyr::mutate(
        run_id = registry$run_id[[1L]],
        dataset_id = registry$dataset_id[[1L]],
        predictor_order = predictor$predictor_order[[1L]],
        predictor_id = predictor$predictor_id[[1L]],
        benchmark_role = paste0(
          "exact registered random-site/random-slope benchmark; never promoted ",
          "to the fixed-site primary"
        ),
        .before = 1L
      )
    hierarchy <- list(
      occurrence_reduced = occurrence_reduced,
      occurrence_heterogeneity = occurrence_heterogeneity,
      positive_reduced = positive_reduced,
      positive_additive_ml = positive_additive_ml,
      positive_heterogeneity = positive_heterogeneity,
      occurrence_registered = occurrence_registered,
      positive_registered = positive_registered,
      additive_design_occurrence = additive_design_occurrence,
      heterogeneity_design_occurrence = heterogeneity_design_occurrence,
      heterogeneity_design_positive = heterogeneity_design_positive
    )
  }

  fit_times <- c(
    occurrence = occurrence$elapsed_seconds,
    positive = positive$elapsed_seconds,
    positive_t = positive_t$elapsed_seconds,
    one_part = one_part$elapsed_seconds,
    occurrence_ar = if (is.null(occurrence_ar)) 0 else occurrence_ar$elapsed_seconds,
    positive_ar = if (is.null(positive_ar)) 0 else positive_ar$elapsed_seconds,
    map = sum(vapply(map_fits, function(x) x$elapsed_seconds, numeric(1)))
  )
  runtime_rows[[key]] <- tibble::tibble(
    run_order = registry$run_order[[1L]],
    run_id = registry$run_id[[1L]],
    predictor_order = predictor$predictor_order[[1L]],
    predictor_id = predictor$predictor_id[[1L]],
    occurrence_seconds = fit_times[["occurrence"]],
    positive_gaussian_seconds = fit_times[["positive"]],
    positive_student_t_seconds = fit_times[["positive_t"]],
    one_part_seconds = fit_times[["one_part"]],
    occurrence_ar_seconds = fit_times[["occurrence_ar"]],
    positive_ar_seconds = fit_times[["positive_ar"]],
    map_prior_scale_seconds = fit_times[["map"]],
    core_seconds = sum(fit_times)
  )
  model_bundle[[key]] <- list(
    frame_paths = frame_registry |>
      dplyr::filter(
        .data$run_id == registry$run_id[[1L]],
        .data$predictor_id == registry$predictor_id[[1L]]
      ) |>
      dplyr::select("component", "frame_path", "frame_object_sha256"),
    occurrence = occurrence,
    positive = positive,
    positive_t = positive_t,
    one_part = one_part,
    occurrence_ar = occurrence_ar,
    positive_ar = positive_ar,
    map_fits = map_fits,
    hierarchy = hierarchy,
    occurrence_failure = occurrence_failure,
    positive_family_status = positive_family_status
  )
}

effects <- dplyr::bind_rows(effects_rows) |>
  dplyr::arrange(.data$predictor_order, .data$run_order, .data$family)
standardized <- dplyr::bind_rows(standardized_rows) |>
  dplyr::arrange(.data$predictor_order, .data$run_id, .data$target_index, .data$quantity)
contrasts <- dplyr::bind_rows(contrast_rows) |>
  dplyr::arrange(.data$predictor_order, .data$run_id, .data$quantity)
diagnostics <- dplyr::bind_rows(diagnostic_rows) |>
  dplyr::arrange(.data$predictor_order, .data$run_order, .data$component)
lag_overall <- dplyr::bind_rows(lag_rows) |>
  dplyr::arrange(.data$predictor_order, .data$run_id, .data$component)
lag_by_site <- dplyr::bind_rows(lag_site_rows) |>
  dplyr::arrange(.data$predictor_order, .data$run_id, .data$component, .data$site)
ar_summary <- dplyr::bind_rows(ar_rows) |>
  dplyr::arrange(.data$predictor_order, .data$run_id, .data$component)
sensitivity <- dplyr::bind_rows(sensitivity_rows) |>
  dplyr::arrange(.data$predictor_order, .data$run_order)
map_coefficients <- dplyr::bind_rows(map_coefficient_rows) |>
  dplyr::arrange(.data$predictor_order, .data$run_id, .data$prior_standard_deviation)
map_predictions <- dplyr::bind_rows(map_prediction_rows) |>
  dplyr::arrange(
    .data$predictor_order,
    .data$run_id,
    .data$prior_standard_deviation,
    .data$target_index
  )
model_tests <- dplyr::bind_rows(test_rows) |>
  dplyr::arrange(
    .data$dataset_id,
    .data$predictor_order,
    .data$test_type,
    .data$component_test,
    .data$component
  )
registered_benchmark <- dplyr::bind_rows(registered_rows) |>
  dplyr::arrange(.data$dataset_id, .data$predictor_order, .data$component)
runtime <- dplyr::bind_rows(runtime_rows) |>
  dplyr::arrange(.data$predictor_order, .data$run_order)

joint_tests <- model_tests |>
  dplyr::filter(!.data$component_test)
h06d_l10_assert(
  nrow(joint_tests) == 2L * 3L * 2L,
  "METRIC-011 must supply 12 joint primary/gap raw slots"
)

# Complete the only mathematically dependent family fields: the new L10 slot
# and the already frozen MDER slot. No MDER model or result is modified.
mder_tests <- readr::read_csv(
  file.path(
    root,
    "artifacts/09_tables/H06_daily/H06_daily_mder_metric010_model_tests.csv"
  ),
  show_col_types = FALSE
)
metric_slots <- h06d_l10_metric_slot_registry()
bh_slots <- dplyr::bind_rows(lapply(
  c("primary", "gap_timing_unaware"),
  function(dataset_id) {
    dplyr::bind_rows(lapply(seq_len(nrow(predictors)), function(index) {
      predictor <- predictors[index, ]
      dplyr::bind_rows(lapply(
        c("association", "site_heterogeneity"),
        function(test_type) {
          l10_test <- joint_tests |>
            dplyr::filter(
              .data$dataset_id == .env$dataset_id,
              .data$predictor_id == predictor$predictor_id[[1L]],
              .data$test_type == .env$test_type
            )
          mder_test <- mder_tests |>
            dplyr::filter(
              .data$dataset_id == .env$dataset_id,
              .data$predictor_id == predictor$predictor_id[[1L]],
              .data$test_type == .env$test_type
            )
          h06d_l10_assert(
            nrow(l10_test) == 1L && nrow(mder_test) == 1L,
            "Dependent BH slot lookup failed"
          )
          family_id <- if (test_type == "association") {
            predictor$association_family_id[[1L]]
          } else {
            predictor$heterogeneity_family_id[[1L]]
          }
          available <- sum(c(
            l10_test$test_status[[1L]] == "ESTIMABLE" &&
              is.finite(l10_test$raw_p_value[[1L]]),
            mder_test$test_status[[1L]] == "ESTIMABLE" &&
              is.finite(mder_test$raw_p_value[[1L]])
          ))
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
              slot_status = dplyr::case_when(
                .data$metric_slot == 3L ~ l10_test$test_status[[1L]],
                .data$metric_slot == 15L ~ mder_test$test_status[[1L]],
                TRUE ~ "NON_L10_MDER_SLOT_NOT_AVAILABLE_TO_TARGETED_AMENDMENT"
              ),
              raw_p_value = dplyr::case_when(
                .data$metric_slot == 3L ~ l10_test$raw_p_value[[1L]],
                .data$metric_slot == 15L ~ mder_test$raw_p_value[[1L]],
                TRUE ~ NA_real_
              ),
              bh_adjusted_p_value = NA_real_,
              family_slots_available = available,
              family_slots_required = 15L,
              family_status = sprintf(
                "INCOMPLETE_%d_OF_15_NO_BH_DECISION",
                available
              ),
              adjusted_decision = NA
            )
        }
      ))
    }))
  }
)) |>
  dplyr::arrange(
    .data$dataset_id,
    .data$predictor_order,
    .data$test_type,
    .data$metric_slot
  )
h06d_l10_assert(
  nrow(bh_slots) == 2L * 3L * 2L * 15L &&
    all(is.na(bh_slots$bh_adjusted_p_value)),
  "METRIC-011 incomplete BH contract failed"
)

primary_verdict <- diagnostics |>
  dplyr::filter(.data$run_id == "primary__near_eye__all_available") |>
  dplyr::select(
    "predictor_order", "predictor_id", "component", "participant_days",
    "participants", "sites", "component_disposition"
  ) |>
  dplyr::left_join(
    ar_summary |>
      dplyr::filter(.data$run_id == "primary__near_eye__all_available") |>
      dplyr::select(
        "predictor_order", "predictor_id", "component", "ar_trigger",
        "ar_fitted", "ar_rho", "effect_shift_in_primary_se",
        "ar_acceptable", "disposition"
      ) |>
      dplyr::rename(ar_disposition = "disposition"),
    by = c("predictor_order", "predictor_id", "component"),
    relationship = "one-to-one"
  ) |>
  dplyr::mutate(
    claim_disposition = dplyr::case_when(
      .data$component == "zero_occurrence" &
        grepl("NON_ESTIMABLE", .data$component_disposition) ~
        "NO_OCCURRENCE_OR_JOINT_ASSOCIATION_CLAIM",
      .data$component == "positive_magnitude" &
        grepl("MAJOR", .data$component_disposition) ~
        "DESCRIPTIVE_POSITIVE_ONLY_ESTIMATE_MAJOR_FAMILY_LIMITATION",
      .data$component == "positive_magnitude" &
        grepl("UNRESOLVED", .data$component_disposition) ~
        "DESCRIPTIVE_POSITIVE_ONLY_ESTIMATE_SENSITIVITY_UNRESOLVED",
      .data$component == "positive_magnitude" ~
        "DESCRIPTIVE_POSITIVE_ONLY_ESTIMATE",
      TRUE ~ "COMPONENT_ESTIMATE_ONLY"
    )
  )

model_relative <- paste0(
  "artifacts/07_models/H06_daily/",
  "H06_daily_l10_metric011_production_models.rds"
)
saveRDS(
  list(
    models = model_bundle,
    frame_registry_sha256 = h06d_l10_sha256(file.path(
      roots$model_data,
      "H06_daily_l10_metric011_frame_registry.csv"
    )),
    input_contract_sha256 = h06d_l10_sha256(file.path(
      roots$diagnostics,
      "H06_daily_l10_metric011_input_contract.csv"
    )),
    r_version = as.character(getRversion()),
    package_versions = vapply(
      required_packages,
      function(package) as.character(utils::packageVersion(package)),
      character(1)
    )
  ),
  file.path(root, model_relative),
  compress = "xz"
)

runtime <- dplyr::bind_rows(
  runtime,
  tibble::tibble(
    run_order = NA_integer_,
    run_id = "full_serial_wall_time",
    predictor_order = NA_integer_,
    predictor_id = NA_character_,
    occurrence_seconds = NA_real_,
    positive_gaussian_seconds = NA_real_,
    positive_student_t_seconds = NA_real_,
    one_part_seconds = NA_real_,
    occurrence_ar_seconds = NA_real_,
    positive_ar_seconds = NA_real_,
    map_prior_scale_seconds = NA_real_,
    core_seconds = unname(proc.time()[["elapsed"]] - started_all)
  )
)

outputs <- list(
  "artifacts/09_tables/H06_daily/H06_daily_l10_metric011_effect_estimates.csv" = effects,
  "artifacts/09_tables/H06_daily/H06_daily_l10_metric011_standardized_estimates.csv" = standardized,
  "artifacts/09_tables/H06_daily/H06_daily_l10_metric011_standardized_contrasts.csv" = contrasts,
  "artifacts/09_tables/H06_daily/H06_daily_l10_metric011_model_tests.csv" = model_tests,
  "artifacts/09_tables/H06_daily/H06_daily_l10_metric011_bh_slot_families.csv" = bh_slots,
  "artifacts/08_diagnostics/H06_daily/H06_daily_l10_metric011_model_diagnostics.csv" = diagnostics,
  "artifacts/08_diagnostics/H06_daily/H06_daily_l10_metric011_site_residual_lag.csv" = lag_by_site,
  "artifacts/08_diagnostics/H06_daily/H06_daily_l10_metric011_residual_lag.csv" = lag_overall,
  "artifacts/08_diagnostics/H06_daily/H06_daily_l10_metric011_ar_counterparts.csv" = ar_summary,
  "artifacts/08_diagnostics/H06_daily/H06_daily_l10_metric011_positive_family_sensitivity.csv" = sensitivity,
  "artifacts/08_diagnostics/H06_daily/H06_daily_l10_metric011_map_occurrence_coefficients.csv" = map_coefficients,
  "artifacts/08_diagnostics/H06_daily/H06_daily_l10_metric011_map_occurrence_predictions.csv" = map_predictions,
  "artifacts/08_diagnostics/H06_daily/H06_daily_l10_metric011_registered_benchmark.csv" = registered_benchmark,
  "artifacts/08_diagnostics/H06_daily/H06_daily_l10_metric011_primary_verdict.csv" = primary_verdict,
  "artifacts/08_diagnostics/H06_daily/H06_daily_l10_metric011_production_runtime.csv" = runtime
)
for (path in names(outputs)) {
  readr::write_csv(outputs[[path]], file.path(root, path))
}

preservation <- protected |>
  dplyr::mutate(
    sha256_after = vapply(
      file.path(root, .data$relative_path),
      h06d_l10_sha256,
      character(1)
    ),
    preserved_byte_for_byte = .data$sha256_before == .data$sha256_after
  )
h06d_l10_assert(
  all(preservation$preserved_byte_for_byte),
  "METRIC-011 production changed a protected pre-existing artifact"
)
readr::write_csv(
  preservation,
  file.path(
    roots$diagnostics,
    "H06_daily_l10_metric011_protected_preservation_after_production.csv"
  )
)

message(
  "METRIC-011 serial production complete in ",
  sprintf("%.2f", runtime$core_seconds[runtime$run_id == "full_serial_wall_time"]),
  " s."
)
