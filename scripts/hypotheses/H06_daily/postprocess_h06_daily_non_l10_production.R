#!/usr/bin/env Rscript

# H06-D-013 phase 4: assemble the sealed Stage 2 production outputs.
# This script does not fit or refit a scientific model. It reads the complete
# base, influence, and bounded-sensitivity checkpoints; applies the declared
# diagnostic rules; and completes the twelve prespecified 15-slot BH families.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
.libPaths(c(
  file.path(root, "renv/library/macos/R-4.6/aarch64-apple-darwin23"),
  .libPaths()
))

required_packages <- c(
  "digest", "dplyr", "tidyr", "tibble", "readr", "lme4", "glmmTMB",
  "performance", "emmeans", "sandwich", "melidosData", "LightLogR"
)
missing_packages <- required_packages[!vapply(
  required_packages,
  requireNamespace,
  logical(1),
  quietly = TRUE
)]
if (length(missing_packages)) {
  stop(
    "Missing synchronized project package(s): ",
    paste(missing_packages, collapse = ", "),
    call. = FALSE
  )
}
suppressPackageStartupMessages({
  library(digest)
  library(dplyr)
  library(tidyr)
  library(tibble)
  library(readr)
})

for (script in c(
  "h06_daily_non_l10_pilot_contract.R",
  "h06_daily_non_l10_pilot_data.R",
  "h06_daily_non_l10_pilot_modeling.R",
  "h06_daily_timing_repair_contract.R",
  "h06_daily_timing_repair_modeling.R",
  "h06_daily_non_l10_production_contract.R",
  "h06_daily_non_l10_production_modeling.R"
)) {
  source(file.path(root, "scripts/hypotheses/H06_daily", script))
}

h06d_prod_assert(
  identical(as.character(getRversion()), "4.6.1"),
  "H06-D-013 postprocessing requires R 4.6.1"
)
h06d_prod_assert(
  identical(as.character(utils::packageVersion("melidosData")), "1.0.6"),
  "H06-D-013 requires immutable melidosData 1.0.6"
)

paths <- h06d_prod_checkpoint_paths(root)
artifact <- function(stage, filename) {
  file.path(root, "artifacts", stage, "H06_daily", filename)
}
diagnostic_dir <- artifact("08_diagnostics", "")
table_dir <- artifact("09_tables", "")
model_data_dir <- artifact("06_model_data", "")
source_data_dir <- artifact("11_source_data", "")
dir.create(table_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(source_data_dir, recursive = TRUE, showWarnings = FALSE)

invisible(h06d_prod_verify_contract(root, h06d_prod_input_contract()))
invisible(h06d_prod_verify_contract(
  root,
  h06d_prod_main_h06_contract() |>
    dplyr::mutate(input_id = paste0("main_h06_", dplyr::row_number()), .before = 1L)
))
preservation_baseline <- readr::read_csv(
  artifact(
    "08_diagnostics",
    "H06_daily_non_l10_production_preservation_baseline.csv"
  ),
  show_col_types = FALSE
)
h06d_prod_recheck_preservation(root, preservation_baseline, "pre_postprocess") |>
  h06d_prod_write_csv(artifact(
    "08_diagnostics",
    "H06_daily_non_l10_production_preservation_pre_postprocess.csv"
  ))

state <- readRDS(paths$state)
h06d_prod_assert(
  identical(state$authorization, "H06-D-013") &&
    state$phase %in% c("SENSITIVITY_COMPLETE", "POSTPROCESS_COMPLETE") &&
    state$completed_refits == 66664L,
  "Complete base, influence, and bounded-sensitivity phases are required"
)

base_index <- readr::read_csv(paths$base_index, show_col_types = FALSE) |>
  dplyr::arrange(.data$metric_slot, .data$predictor_order, .data$run_order)
influence_index <- readr::read_csv(paths$influence, show_col_types = FALSE) |>
  dplyr::arrange(.data$metric_slot, .data$predictor_order, .data$run_order)
h06d_prod_assert(
  nrow(base_index) == 468L && all(base_index$outer_success) &&
    nrow(influence_index) == 468L &&
    sum(influence_index$completed_refits) == 66664L &&
    identical(base_index$frame_key, influence_index$frame_key),
  "Production checkpoint indexes are incomplete or misaligned"
)

meta_columns <- c(
  "run_order", "run_id", "dataset_id", "placement_id", "sample_role",
  "analysis_role", "test_role", "metric_slot", "metric_id",
  "manuscript_name", "display_unit", "response_family",
  "response_transform", "effect_scale", "is_timing", "predictor_order",
  "predictor_id", "reader_name", "contrast_label", "association_family_id",
  "heterogeneity_family_id", "frame_key", "participant_days",
  "participants", "sites", "exact_source_zeros", "source_minimum",
  "source_median", "source_maximum", "frame_object_sha256", "route"
)
add_meta <- function(data, meta) {
  if (is.null(data) || !nrow(data)) return(tibble::tibble())
  duplicate <- intersect(names(data), meta_columns)
  retained_meta <- setdiff(meta_columns, duplicate)
  dplyr::bind_cols(meta[, retained_meta, drop = FALSE], data)
}

normalize_diagnostic_names <- function(data, frame_key) {
  duplicate_zero_names <- c(
    "exact_zero_fraction...18",
    "exact_zero_fraction...24"
  )
  if (all(duplicate_zero_names %in% names(data))) {
    h06d_prod_assert(
      isTRUE(all.equal(
        data[[duplicate_zero_names[[1L]]]],
        data[[duplicate_zero_names[[2L]]]],
        tolerance = 0
      )),
      "The two internally reported zero fractions differ for `%s`",
      frame_key
    )
    data$exact_zero_fraction <- data[[duplicate_zero_names[[1L]]]]
    data <- dplyr::select(data, -dplyr::all_of(duplicate_zero_names))
  }
  h06d_prod_assert(
    !anyDuplicated(names(data)),
    "Diagnostic column normalization failed for `%s`",
    frame_key
  )
  data
}

effects <- list()
tests <- list()
diagnostics <- list()
model_diagnostics <- list()
marginals <- list()
benchmarks <- list()
lag_by_site <- list()
post_ar_lag_by_site <- list()
timing_student_models <- list()
timing_student_stability <- list()
timing_ar_models <- list()
timing_ar_stability <- list()
timing_ar_lag_by_site <- list()
model_catalog <- list()

message("H06-D-013 phase 4: validating and collecting 468 sealed cells")
for (index in seq_len(nrow(base_index))) {
  meta <- base_index[index, , drop = FALSE]
  absolute <- file.path(root, meta$checkpoint_relative_path[[1L]])
  h06d_prod_assert(
    file.exists(absolute) &&
      h06d_prod_sha256(absolute) == meta$checkpoint_sha256[[1L]],
    "Base checkpoint identity changed for `%s`",
    meta$frame_key[[1L]]
  )
  object <- readRDS(absolute)
  h06d_prod_assert(
    identical(object$authorization, "H06-D-013") &&
      identical(object$frame_key, meta$frame_key[[1L]]) &&
      identical(object$frame_object_sha256, meta$frame_object_sha256[[1L]]) &&
      identical(object$route, meta$route[[1L]]) &&
      is.na(object$outer_error),
    "Base checkpoint contract failed for `%s`",
    meta$frame_key[[1L]]
  )
  result <- object$result
  effects[[index]] <- add_meta(result$effect, meta)
  tests[[index]] <- add_meta(result$tests, meta)
  diagnostics[[index]] <- add_meta(
    normalize_diagnostic_names(result$diagnostics, meta$frame_key[[1L]]),
    meta
  )
  model_diagnostics[[index]] <- add_meta(result$model_diagnostics, meta)
  marginals[[index]] <- add_meta(result$marginals, meta)
  benchmarks[[index]] <- add_meta(result$benchmark, meta)
  lag_by_site[[index]] <- add_meta(result$lag_by_site, meta)
  post_ar_lag_by_site[[index]] <- add_meta(result$post_ar_lag_by_site, meta)
  if (identical(meta$route[[1L]], "participant_cluster_HC3")) {
    timing_student_models[[index]] <- add_meta(
      result$student_t$diagnostics,
      meta
    )
    timing_student_stability[[index]] <- add_meta(
      result$student_t$stability,
      meta
    )
    timing_ar_models[[index]] <- add_meta(
      result$no_nugget_ar$diagnostics,
      meta
    )
    timing_ar_stability[[index]] <- add_meta(
      result$no_nugget_ar$stability,
      meta
    )
    timing_ar_lag_by_site[[index]] <- add_meta(
      result$no_nugget_ar$lag,
      meta
    )
  }
  model_catalog[[index]] <- meta |>
    dplyr::transmute(
      run_order,
      run_id,
      dataset_id,
      placement_id,
      sample_role,
      analysis_role,
      metric_slot,
      metric_id,
      predictor_order,
      predictor_id,
      frame_key,
      route,
      checkpoint_relative_path,
      checkpoint_sha256,
      checkpoint_bytes,
      frame_object_sha256,
      fit_code_sha256,
      outer_warning_count,
      outer_warnings,
      elapsed_seconds
    )
}

effects <- dplyr::bind_rows(effects)
raw_tests <- dplyr::bind_rows(tests)
diagnostics <- dplyr::bind_rows(diagnostics)
model_diagnostics <- dplyr::bind_rows(model_diagnostics)
marginals <- dplyr::bind_rows(marginals)
benchmarks <- dplyr::bind_rows(benchmarks)
lag_by_site <- dplyr::bind_rows(lag_by_site)
post_ar_lag_by_site <- dplyr::bind_rows(post_ar_lag_by_site)
timing_student_models <- dplyr::bind_rows(timing_student_models)
timing_student_stability <- dplyr::bind_rows(timing_student_stability)
timing_ar_models <- dplyr::bind_rows(timing_ar_models)
timing_ar_stability <- dplyr::bind_rows(timing_ar_stability)
timing_ar_lag_by_site <- dplyr::bind_rows(timing_ar_lag_by_site)
model_catalog <- dplyr::bind_rows(model_catalog)
h06d_prod_assert(
  nrow(effects) == 468L && nrow(raw_tests) == 936L &&
    nrow(diagnostics) == 468L && nrow(model_catalog) == 468L &&
    nrow(timing_student_stability) == 288L &&
    nrow(timing_ar_stability) == 288L,
  "A collected production component is incomplete"
)

# Consolidate all authorized deletion refits while retaining the sealed cell
# checkpoints as the authoritative restart units.
message("H06-D-013 phase 4: consolidating 66,664 deletion refits")
influence_results <- lapply(seq_len(nrow(influence_index)), function(index) {
  meta <- influence_index[index, , drop = FALSE]
  absolute <- file.path(root, meta$checkpoint_relative_path[[1L]])
  h06d_prod_assert(
    file.exists(absolute) &&
      h06d_prod_sha256(absolute) == meta$checkpoint_sha256[[1L]],
    "Influence checkpoint identity changed for `%s`",
    meta$frame_key[[1L]]
  )
  object <- readRDS(absolute)
  h06d_prod_assert(
    identical(object$authorization, "H06-D-013") &&
      identical(object$frame_key, meta$frame_key[[1L]]) &&
      identical(object$frame_object_sha256, meta$frame_object_sha256[[1L]]) &&
      nrow(object$results) == meta$completed_refits[[1L]] &&
      identical(object$results$task_within_cell, seq_len(meta$completed_refits[[1L]])),
    "Influence checkpoint contract failed for `%s`",
    meta$frame_key[[1L]]
  )
  object$results
}) |>
  dplyr::bind_rows() |>
  dplyr::arrange(.data$global_task_id)
h06d_prod_assert(
  nrow(influence_results) == 66664L &&
    identical(influence_results$global_task_id, seq_len(66664L)) &&
    !anyDuplicated(influence_results[c("frame_key", "deletion_label")]),
  "The consolidated influence result is not the declared 66,664-refit battery"
)

# Corrected bounded sensitivity outputs were produced only after influence
# completion. No sensitivity p-value replaces a primary test.
tweedie <- readr::read_csv(artifact(
  "08_diagnostics",
  "H06_daily_non_l10_production_tweedie_diagnostics.csv"
), show_col_types = FALSE)
tweedie_ar <- readr::read_csv(artifact(
  "08_diagnostics",
  "H06_daily_non_l10_production_tweedie_ar_sensitivity.csv"
), show_col_types = FALSE)
gaussian_student <- readr::read_csv(artifact(
  "08_diagnostics",
  "H06_daily_non_l10_production_gaussian_student_t_sensitivity.csv"
), show_col_types = FALSE)
period_exact <- readr::read_csv(artifact(
  "08_diagnostics",
  "H06_daily_non_l10_production_period_exact_sensitivity.csv"
), show_col_types = FALSE)
mean_timing_clock <- readr::read_csv(artifact(
  "08_diagnostics",
  "H06_daily_non_l10_production_mean_timing_clock_support.csv"
), show_col_types = FALSE)
h06d_prod_assert(
  nrow(tweedie) == 108L &&
    nrow(tweedie_ar) == sum(tweedie$ar_trigger) &&
    nrow(period_exact) == 18L && nrow(mean_timing_clock) == 36L,
  "A bounded sensitivity artifact is incomplete"
)

# Family-wide multiplicity. Diagnostic status is deliberately separate from
# numerical estimability: every estimable raw test remains in its named slot,
# while claim_status below controls whether an inferential statement is allowed.
family_source <- raw_tests |>
  dplyr::filter(
    .data$placement_id == "near_eye",
    .data$sample_role == "all_available",
    .data$test_role %in% c("primary_raw_slot", "gap_raw_slot")
  ) |>
  dplyr::select(
    "dataset_id", "predictor_order", "predictor_id", "test_type",
    "metric_slot", "metric_id", "manuscript_name", "raw_p_value",
    "method", "test_status", "frame_key"
  )
h06d_prod_assert(
  nrow(family_source) == 156L &&
    !anyDuplicated(family_source[c(
      "dataset_id", "predictor_id", "test_type", "metric_slot"
    )]),
  "The 13-slot production family source is incomplete"
)

mder <- readr::read_csv(
  artifact("09_tables", "H06_daily_mder_metric010_model_tests.csv"),
  show_col_types = FALSE
) |>
  dplyr::transmute(
    dataset_id,
    predictor_order,
    predictor_id,
    test_type,
    metric_slot,
    metric_id,
    manuscript_name = "Melanopic daylight efficacy ratio",
    raw_p_value,
    method,
    test_status,
    frame_key = NA_character_
  )
h06d_prod_assert(
  nrow(mder) == 12L && all(mder$metric_slot == 15L),
  "The frozen MDER raw-test source is incomplete"
)

slots <- h06d_nl_full_slot_registry()
predictors <- h06d_nl_predictor_registry()
families <- tidyr::crossing(
  dataset_id = c("primary", "gap_timing_unaware"),
  predictor_order = predictors$predictor_order,
  test_type = c("association", "site_heterogeneity"),
  metric_slot = slots$metric_slot
) |>
  dplyr::left_join(
    predictors |>
      dplyr::select(
        "predictor_order", "predictor_id", "reader_name",
        "association_family_id", "heterogeneity_family_id"
      ),
    by = "predictor_order",
    relationship = "many-to-one"
  ) |>
  dplyr::left_join(slots, by = "metric_slot", relationship = "many-to-one") |>
  dplyr::left_join(
    dplyr::bind_rows(family_source, mder) |>
      dplyr::select(
        "dataset_id", "predictor_order", "predictor_id", "test_type",
        "metric_slot", "raw_p_value", "method", "test_status", "frame_key"
      ),
    by = c(
      "dataset_id", "predictor_order", "predictor_id", "test_type",
      "metric_slot"
    ),
    relationship = "one-to-one"
  ) |>
  dplyr::mutate(
    multiplicity_family_id = paste0(
      .data$dataset_id,
      "__",
      dplyr::if_else(
        .data$test_type == "association",
        .data$association_family_id,
        .data$heterogeneity_family_id
      )
    ),
    slot_status = dplyr::case_when(
      .data$metric_slot == 3L ~ "FROZEN_NAMED_NA_L10_COMPONENT_FAILURE",
      .data$metric_slot == 15L ~ "FROZEN_MDER_RAW_RESULT",
      is.na(.data$raw_p_value) ~ dplyr::coalesce(
        .data$test_status,
        "NON_ESTIMABLE_PRODUCTION_TEST"
      ),
      TRUE ~ "ESTIMABLE_PRODUCTION_RAW_TEST"
    )
  ) |>
  dplyr::arrange(
    .data$dataset_id,
    .data$predictor_order,
    .data$test_type,
    .data$metric_slot
  ) |>
  dplyr::group_by(
    .data$dataset_id,
    .data$predictor_order,
    .data$predictor_id,
    .data$test_type,
    .data$multiplicity_family_id
  ) |>
  dplyr::mutate(
    bh_adjusted_p_value = stats::p.adjust(
      .data$raw_p_value,
      method = "BH",
      n = 15L
    ),
    raw_rank_within_available = dplyr::if_else(
      is.na(.data$raw_p_value),
      NA_real_,
      rank(.data$raw_p_value, ties.method = "min", na.last = "keep")
    ),
    raw_decision = dplyr::case_when(
      is.na(.data$raw_p_value) ~ "NOT_ESTIMABLE",
      .data$raw_p_value < 0.05 ~ "RAW_P_LT_0.05",
      TRUE ~ "RAW_P_GE_0.05"
    ),
    adjusted_decision = dplyr::case_when(
      is.na(.data$bh_adjusted_p_value) ~ "NOT_ESTIMABLE",
      .data$bh_adjusted_p_value < 0.05 ~ "BH_Q_LT_0.05",
      TRUE ~ "BH_Q_GE_0.05"
    ),
    family_slots_available = sum(!is.na(.data$raw_p_value)),
    family_slots_required = 15L,
    family_status = "COMPLETE_NAMED_15_SLOT_FAMILY_WITH_NA_SLOTS",
    multiplicity_method = "Benjamini-Hochberg; stats::p.adjust(n = 15)"
  ) |>
  dplyr::ungroup()
h06d_prod_assert(
  nrow(families) == 180L &&
    dplyr::n_distinct(families$multiplicity_family_id) == 12L &&
    all(table(families$multiplicity_family_id) == 15L) &&
    all(is.na(families$raw_p_value[families$metric_slot == 3L])) &&
    all(is.na(families$bh_adjusted_p_value[families$metric_slot == 3L])) &&
    all(
      families$raw_p_value[families$metric_slot == 15L] ==
        mder$raw_p_value[match(
          paste(
            families$dataset_id[families$metric_slot == 15L],
            families$predictor_id[families$metric_slot == 15L],
            families$test_type[families$metric_slot == 15L]
          ),
          paste(mder$dataset_id, mder$predictor_id, mder$test_type)
        )]
    ),
  "The twelve 15-slot multiplicity families failed their contract"
)

# Cell-level diagnostic classification. Raw numerical tests are preserved even
# where this assessment blocks an unqualified scientific claim.
influence_cell <- influence_index |>
  dplyr::transmute(
    frame_key,
    influence_expected_refits = expected_refits,
    influence_completed_refits = completed_refits,
    influence_failed_refits = failed_refits,
    influence_warning_count = warning_count,
    influence_direction_reversals = direction_reversals,
    influence_maximum_shift_in_full_se = maximum_absolute_shift_in_full_se,
    influence_substantial_limitations = substantial_limitations,
    influence_unstable_refits = unstable_refits,
    influence_classification = dplyr::case_when(
      .data$failed_refits > 0L ~ "UNRESOLVED_NON_ESTIMABLE_DELETION_REFIT",
      .data$direction_reversals > 0L |
        .data$maximum_absolute_shift_in_full_se >= 2 ~ "UNSTABLE",
      .data$maximum_absolute_shift_in_full_se >= 1 ~ "SUBSTANTIAL_LIMITATION",
      TRUE ~ "STABLE"
    )
  )

student_additive <- gaussian_student |>
  dplyr::select(
    "frame_key",
    student_t_shift_in_primary_se = "effect_shift_in_primary_se",
    student_t_direction_reversal = "direction_reversal",
    student_t_classification = "sensitivity_classification"
  )
tweedie_support <- tweedie |>
  dplyr::transmute(
    frame_key,
    corrected_tweedie_power = tweedie_power,
    corrected_tweedie_power_interior = tweedie_power_interior,
    tweedie_residual_fitted_spearman = pearson_residual_fitted_spearman,
    tweedie_standardized_residual_gt4_fraction =
      standardized_residual_gt4_fraction,
    tweedie_simulation_diagnostic_status = simulation_diagnostic_status,
    tweedie_prediction_below_fraction = conditional_prediction_below_fraction,
    tweedie_prediction_above_fraction = conditional_prediction_above_fraction,
    tweedie_prediction_bound_acceptable = prediction_bound_acceptable,
    tweedie_ar_trigger = ar_trigger
  ) |>
  dplyr::left_join(
    tweedie_ar |>
      dplyr::select(
        "frame_key", tweedie_ar_rho = "ar_rho",
        tweedie_ar_shift_in_primary_se = "effect_shift_in_primary_se",
        tweedie_ar_direction_reversal = "direction_reversal",
        tweedie_ar_disposition = "ar_disposition"
      ),
    by = "frame_key",
    relationship = "one-to-one"
  )
period_support <- period_exact |>
  dplyr::select(
    "frame_key", period_exact_fraction = "exact_fraction_of_primary_frame",
    period_effect_shift_in_primary_se = "effect_shift_in_primary_se",
    period_direction_reversal = "direction_reversal",
    period_sensitivity_classification = "sensitivity_classification"
  )
timing_student_additive <- timing_student_stability |>
  dplyr::filter(.data$component == "predictor_additive") |>
  dplyr::select(
    "frame_key",
    timing_student_shift_in_hc3_se = "maximum_shift_in_hc3_se",
    timing_student_direction_reversal = "direction_reversal",
    timing_student_classification = "sensitivity_classification"
  )
timing_ar_additive <- timing_ar_models |>
  dplyr::filter(.data$structure == "additive") |>
  dplyr::select(
    "frame_key", timing_ar_converged = "converged",
    timing_ar_positive_definite_hessian = "positive_definite_hessian",
    timing_ar_finite_fixed_effects = "finite_fixed_effects",
    timing_ar_finite_standard_errors = "finite_standard_errors",
    timing_ar_singular = "singular", timing_ar_rho = "ar_rho",
    timing_ar_residual_lag1 = "residual_lag1",
    timing_ar_maximum_absolute_site_lag1 = "maximum_absolute_site_lag1",
    timing_ar_temporal_threshold_pass = "temporal_threshold_pass"
  ) |>
  dplyr::left_join(
    timing_ar_stability |>
      dplyr::filter(.data$component == "predictor_additive") |>
      dplyr::select(
        "frame_key",
        timing_ar_shift_in_hc3_se = "maximum_shift_in_hc3_se",
        timing_ar_direction_reversal = "direction_reversal",
        timing_ar_classification = "sensitivity_classification"
      ),
    by = "frame_key",
    relationship = "one-to-one"
  )

diagnostic_assessment <- diagnostics |>
  dplyr::left_join(influence_cell, by = "frame_key", relationship = "one-to-one") |>
  dplyr::left_join(student_additive, by = "frame_key", relationship = "one-to-one") |>
  dplyr::left_join(tweedie_support, by = "frame_key", relationship = "one-to-one") |>
  dplyr::left_join(period_support, by = "frame_key", relationship = "one-to-one") |>
  dplyr::left_join(
    timing_student_additive,
    by = "frame_key",
    relationship = "one-to-one"
  ) |>
  dplyr::left_join(timing_ar_additive, by = "frame_key", relationship = "one-to-one") |>
  dplyr::mutate(
    model_gate = dplyr::case_when(
      .data$route == "mixed_model" &
        (!.data$additive_converged |
          !.data$additive_positive_definite_hessian |
          dplyr::coalesce(.data$additive_singular, TRUE)) ~ "NOT_ACCEPTABLE",
      .data$route == "participant_cluster_HC3" &
        !.data$all_three_candidate_models_pass ~ "NOT_ACCEPTABLE",
      TRUE ~ "ACCEPTABLE"
    ),
    distribution_gate = dplyr::case_when(
      .data$route == "participant_cluster_HC3" &
        !.data$source_clock_acceptable ~ "NOT_ACCEPTABLE_CLOCK_SUPPORT",
      .data$route == "participant_cluster_HC3" &
        (.data$absolute_residual_fitted_spearman >= 0.40 |
          .data$standardized_residual_gt4_fraction >= 0.01) &
        .data$timing_student_classification == "UNSTABLE" ~
        "NOT_ACCEPTABLE_STUDENT_T_INSTABILITY",
      .data$route == "participant_cluster_HC3" &
        .data$timing_student_classification == "SUBSTANTIAL_LIMITATION" ~
        "ACCEPTABLE_WITH_MAJOR_STUDENT_T_LIMITATION",
      .data$route == "participant_cluster_HC3" &
        (.data$residual_qq_correlation < 0.95 |
          .data$absolute_residual_fitted_spearman >= 0.20 |
          .data$standardized_residual_gt4_fraction >= 0.01) ~
        "ACCEPTABLE_WITH_DISTRIBUTIONAL_LIMITATION",
      .data$response_family == "gaussian" &
        (.data$conditional_prediction_below_fraction > 0.01 |
          .data$conditional_prediction_above_fraction > 0.01) ~
        "NOT_ACCEPTABLE_PREDICTION_BOUNDS",
      .data$response_family == "gaussian" &
        .data$absolute_residual_fitted_spearman >= 0.40 ~
        "NOT_ACCEPTABLE_RESIDUAL_SPREAD",
      .data$response_family == "gaussian" &
        .data$student_t_classification == "UNSTABLE" ~
        "NOT_ACCEPTABLE_STUDENT_T_INSTABILITY",
      .data$response_family == "gaussian" &
        .data$student_t_classification == "SUBSTANTIAL_LIMITATION" ~
        "ACCEPTABLE_WITH_MAJOR_STUDENT_T_LIMITATION",
      .data$response_family == "gaussian" &
        (.data$residual_qq_correlation < 0.95 |
          .data$absolute_residual_fitted_spearman >= 0.20 |
          .data$standardized_residual_gt4_fraction >= 0.01) ~
        "ACCEPTABLE_WITH_DISTRIBUTIONAL_LIMITATION",
      .data$response_family == "tweedie_log" &
        (!.data$corrected_tweedie_power_interior |
          .data$tweedie_residual_fitted_spearman >= 0.40 |
          .data$tweedie_prediction_below_fraction > 0.01 |
          .data$tweedie_prediction_above_fraction > 0.01) ~
        "NOT_ACCEPTABLE_TWEEDIE_CORE",
      .data$response_family == "tweedie_log" &
        (.data$tweedie_residual_fitted_spearman >= 0.20 |
          .data$tweedie_standardized_residual_gt4_fraction >= 0.01) ~
        "ACCEPTABLE_WITH_TWEEDIE_LIMITATION_NO_SIMULATION",
      .data$response_family == "tweedie_log" ~
        "ACCEPTABLE_WITH_NO_SIMULATION_BY_AUTHORIZATION",
      TRUE ~ "ACCEPTABLE"
    ),
    temporal_gate = dplyr::case_when(
      .data$route == "participant_cluster_HC3" &
        (!dplyr::coalesce(.data$timing_ar_converged, FALSE) |
          !dplyr::coalesce(.data$timing_ar_positive_definite_hessian, FALSE) |
          dplyr::coalesce(.data$timing_ar_singular, TRUE)) ~
        "NOT_ACCEPTABLE_UNRESOLVED_AR_NUMERICS",
      .data$route == "participant_cluster_HC3" &
        .data$timing_ar_classification == "UNSTABLE" ~
        "NOT_ACCEPTABLE_UNSTABLE_AR_EFFECT",
      .data$route == "participant_cluster_HC3" &
        .data$timing_ar_classification == "SUBSTANTIAL_LIMITATION" ~
        "ACCEPTABLE_WITH_MAJOR_AR_LIMITATION",
      .data$route == "participant_cluster_HC3" &
        !dplyr::coalesce(.data$timing_ar_temporal_threshold_pass, FALSE) ~
        "NOT_ACCEPTABLE_POST_AR_RESIDUAL_DEPENDENCE",
      .data$route == "participant_cluster_HC3" ~ "ACCEPTABLE",
      .data$response_family == "tweedie_log" &
        !.data$tweedie_ar_trigger ~ "ACCEPTABLE",
      .data$response_family == "tweedie_log" &
        .data$tweedie_ar_disposition == "ACCEPTABLE" ~ "ACCEPTABLE",
      .data$response_family == "tweedie_log" &
        .data$tweedie_ar_disposition == "SUBSTANTIAL_AR_EFFECT_LIMITATION" ~
        "ACCEPTABLE_WITH_MAJOR_AR_LIMITATION",
      .data$response_family == "tweedie_log" ~
        paste0("NOT_ACCEPTABLE_", .data$tweedie_ar_disposition),
      .data$ar_disposition %in% c(
        "NOT_TRIGGERED", "ACCEPTABLE",
        "ACCEPTABLE_REUSED_FROZEN_PRE_SLEEP_NO_NUGGET"
      ) ~ "ACCEPTABLE",
      .data$ar_disposition == "SUBSTANTIAL_AR_EFFECT_LIMITATION" ~
        "ACCEPTABLE_WITH_MAJOR_AR_LIMITATION",
      TRUE ~ paste0("NOT_ACCEPTABLE_", .data$ar_disposition)
    ),
    period_gate = dplyr::case_when(
      is.na(.data$period_sensitivity_classification) ~ "NOT_APPLICABLE",
      .data$period_sensitivity_classification == "STABLE" ~ "ACCEPTABLE",
      .data$period_sensitivity_classification == "SUBSTANTIAL_LIMITATION" ~
        "ACCEPTABLE_WITH_MAJOR_PERIOD_LIMITATION",
      TRUE ~ "NOT_ACCEPTABLE_PERIOD_IDENTIFICATION"
    ),
    influence_gate = dplyr::case_when(
      .data$influence_classification == "STABLE" ~ "ACCEPTABLE",
      .data$influence_classification == "SUBSTANTIAL_LIMITATION" ~
        "ACCEPTABLE_WITH_MAJOR_INFLUENCE_LIMITATION",
      .data$influence_classification == "UNSTABLE" ~
        "NOT_ACCEPTABLE_INFLUENCE_INSTABILITY",
      TRUE ~ "NOT_ACCEPTABLE_INCOMPLETE_INFLUENCE"
    ),
    diagnostic_status = dplyr::case_when(
      .data$model_gate == "NOT_ACCEPTABLE" ~ "NOT_ACCEPTABLE",
      grepl("^NOT_ACCEPTABLE", .data$distribution_gate) |
        grepl("^NOT_ACCEPTABLE", .data$temporal_gate) |
        grepl("^NOT_ACCEPTABLE", .data$period_gate) |
        grepl("^NOT_ACCEPTABLE", .data$influence_gate) ~ "NOT_ACCEPTABLE",
      grepl("LIMITATION|NO_SIMULATION", .data$distribution_gate) |
        grepl("LIMITATION", .data$temporal_gate) |
        grepl("LIMITATION", .data$period_gate) |
        grepl("LIMITATION", .data$influence_gate) ~
        "ACCEPTABLE_WITH_LIMITATION",
      TRUE ~ "ACCEPTABLE"
    ),
    association_claim_status = dplyr::case_when(
      .data$diagnostic_status == "NOT_ACCEPTABLE" ~
        "NO_UNQUALIFIED_ASSOCIATION_CLAIM",
      .data$diagnostic_status == "ACCEPTABLE_WITH_LIMITATION" ~
        "ASSOCIATION_CLAIM_REQUIRES_EXPLICIT_LIMITATION",
      TRUE ~ "ASSOCIATION_CLAIM_ELIGIBLE"
    ),
    heterogeneity_claim_status = dplyr::case_when(
      .data$route == "participant_cluster_HC3" ~
        "NO_UNQUALIFIED_SITE_INTERACTION_CLAIM_SENSITIVITY_DEPENDENT",
      .data$diagnostic_status == "NOT_ACCEPTABLE" ~
        "NO_UNQUALIFIED_SITE_INTERACTION_CLAIM",
      .data$diagnostic_status == "ACCEPTABLE_WITH_LIMITATION" ~
        "SITE_INTERACTION_CLAIM_REQUIRES_EXPLICIT_LIMITATION",
      TRUE ~ "SITE_INTERACTION_CLAIM_ELIGIBLE"
    )
  )
h06d_prod_assert(
  nrow(diagnostic_assessment) == 468L &&
    !anyDuplicated(diagnostic_assessment$frame_key) &&
    !any(is.na(diagnostic_assessment$diagnostic_status)),
  "The cell-level diagnostic assessment is incomplete"
)

family_claims <- families |>
  dplyr::left_join(
    diagnostic_assessment |>
      dplyr::select(
        "frame_key", "diagnostic_status", "association_claim_status",
        "heterogeneity_claim_status"
      ),
    by = "frame_key",
    relationship = "many-to-one"
  ) |>
  dplyr::mutate(
    claim_status = dplyr::case_when(
      .data$metric_slot == 3L ~ "NO_CLAIM_FROZEN_L10_COMPONENT_FAILURE",
      .data$metric_slot == 15L ~ "FROZEN_MDER_CLAIM_UNCHANGED",
      .data$test_type == "association" ~ .data$association_claim_status,
      TRUE ~ .data$heterogeneity_claim_status
    ),
    adjusted_inferential_decision = dplyr::case_when(
      .data$adjusted_decision != "BH_Q_LT_0.05" ~ .data$adjusted_decision,
      .data$metric_slot == 15L ~
        "BH_Q_LT_0.05_FROZEN_MDER_CLAIM_RETAINS_EXISTING_LIMITATIONS",
      grepl("^NO_", .data$claim_status) ~
        "BH_Q_LT_0.05_BUT_DIAGNOSTICALLY_NOT_ACCEPTABLE",
      grepl("REQUIRES_EXPLICIT_LIMITATION", .data$claim_status) ~
        "BH_Q_LT_0.05_WITH_EXPLICIT_DIAGNOSTIC_LIMITATION",
      TRUE ~ "BH_Q_LT_0.05_AND_DIAGNOSTICALLY_ELIGIBLE"
    )
  )

# Exact-sample and cross-scenario comparison tables are deterministic views of
# the sealed frames and pointwise estimates; they introduce no new fitting.
samples <- base_index |>
  dplyr::select(
    "run_order", "run_id", "dataset_id", "placement_id", "sample_role",
    "analysis_role", "test_role", "metric_slot", "metric_id",
    "manuscript_name", "predictor_order", "predictor_id", "reader_name",
    "participant_days", "participants", "sites", "exact_source_zeros",
    "source_minimum", "source_median", "source_maximum", "frame_key",
    "frame_object_sha256"
  )

primary_results <- effects |>
  dplyr::filter(
    .data$dataset_id == "primary",
    .data$placement_id == "near_eye",
    .data$sample_role == "all_available"
  ) |>
  dplyr::left_join(
    family_claims |>
      dplyr::filter(
        .data$dataset_id == "primary",
        .data$test_type == "association"
      ) |>
      dplyr::select(
        "predictor_id", "metric_slot", association_raw_p = "raw_p_value",
        association_bh_q = "bh_adjusted_p_value",
        "adjusted_inferential_decision", family_claim_status = "claim_status"
      ),
    by = c("predictor_id", "metric_slot"),
    relationship = "one-to-one"
  ) |>
  dplyr::left_join(
    family_claims |>
      dplyr::filter(
        .data$dataset_id == "primary",
        .data$test_type == "site_heterogeneity"
      ) |>
      dplyr::select(
        "predictor_id", "metric_slot", heterogeneity_raw_p = "raw_p_value",
        heterogeneity_bh_q = "bh_adjusted_p_value",
        heterogeneity_inferential_decision = "adjusted_inferential_decision",
        heterogeneity_claim_status = "claim_status"
      ),
    by = c("predictor_id", "metric_slot"),
    relationship = "one-to-one"
  ) |>
  dplyr::left_join(
    diagnostic_assessment |>
      dplyr::select(
        "frame_key", "diagnostic_status", "model_gate", "distribution_gate",
        "temporal_gate", "period_gate", "influence_gate"
      ),
    by = "frame_key",
    relationship = "one-to-one"
  )

scenario_effect_comparison <- effects |>
  dplyr::select(
    "run_order", "run_id", "dataset_id", "placement_id", "sample_role",
    "analysis_role", "metric_slot", "metric_id", "manuscript_name",
    "predictor_order", "predictor_id", "contrast", "display_estimate",
    "display_lower_95", "display_upper_95", "effect_scale", "effect_status",
    "estimate", "standard_error", "participant_days", "participants",
    "sites", "frame_key"
  ) |>
  dplyr::group_by(.data$metric_slot, .data$predictor_id) |>
  dplyr::mutate(
    primary_near_eye_all_available_estimate = .data$display_estimate[
      .data$dataset_id == "primary" &
        .data$placement_id == "near_eye" &
        .data$sample_role == "all_available"
    ][[1L]],
    shift_from_primary_near_eye_in_primary_se = if (
      .data$effect_scale[[1L]] %in% c(
        "absolute difference", "absolute clock-hour difference",
        "absolute unwrapped clock-hour difference"
      )
    ) {
      (.data$estimate - .data$estimate[
        .data$dataset_id == "primary" &
          .data$placement_id == "near_eye" &
          .data$sample_role == "all_available"
      ][[1L]]) / .data$standard_error[
        .data$dataset_id == "primary" &
          .data$placement_id == "near_eye" &
          .data$sample_role == "all_available"
      ][[1L]]
    } else {
      (.data$estimate - .data$estimate[
        .data$dataset_id == "primary" &
          .data$placement_id == "near_eye" &
          .data$sample_role == "all_available"
      ][[1L]]) / .data$standard_error[
        .data$dataset_id == "primary" &
          .data$placement_id == "near_eye" &
          .data$sample_role == "all_available"
      ][[1L]]
    }
  ) |>
  dplyr::ungroup()

runtime <- tibble::tibble(
  component = c(
    "base models and embedded diagnostics",
    "participant/site deletion influence",
    "bounded family/support sensitivities",
    "complete production computation before reporting"
  ),
  completed_units = c(
    468L,
    state$completed_refits,
    state$sensitivity_models,
    468L + state$completed_refits + state$sensitivity_models
  ),
  wall_seconds = c(
    state$base_elapsed_seconds,
    state$influence_wall_seconds,
    state$sensitivity_elapsed_seconds,
    state$base_elapsed_seconds + state$influence_wall_seconds +
      state$sensitivity_elapsed_seconds
  ),
  execution = "serial; R 4.6.1; no bootstrap or simulation"
)

outputs <- list(
  effects = list(table_dir, "H06_daily_non_l10_production_effects.csv", effects),
  tests = list(table_dir, "H06_daily_non_l10_production_raw_tests.csv", raw_tests),
  families = list(
    table_dir,
    "H06_daily_non_l10_production_bh_families.csv",
    family_claims
  ),
  primary = list(
    table_dir,
    "H06_daily_non_l10_production_primary_results.csv",
    primary_results
  ),
  comparisons = list(
    table_dir,
    "H06_daily_non_l10_production_scenario_effect_comparison.csv",
    scenario_effect_comparison
  ),
  marginals = list(
    table_dir,
    "H06_daily_non_l10_production_equal_site_marginals.csv",
    marginals
  ),
  samples = list(
    model_data_dir,
    "H06_daily_non_l10_production_exact_samples.csv",
    samples
  ),
  diagnostics = list(
    diagnostic_dir,
    "H06_daily_non_l10_production_diagnostic_assessment.csv",
    diagnostic_assessment
  ),
  model_diagnostics = list(
    diagnostic_dir,
    "H06_daily_non_l10_production_model_diagnostics.csv",
    model_diagnostics
  ),
  benchmarks = list(
    diagnostic_dir,
    "H06_daily_non_l10_production_registered_benchmarks.csv",
    benchmarks
  ),
  lag = list(
    diagnostic_dir,
    "H06_daily_non_l10_production_lag_by_site.csv",
    lag_by_site
  ),
  post_ar_lag = list(
    diagnostic_dir,
    "H06_daily_non_l10_production_post_ar_lag_by_site.csv",
    post_ar_lag_by_site
  ),
  timing_student_models = list(
    diagnostic_dir,
    "H06_daily_non_l10_production_timing_student_t_models.csv",
    timing_student_models
  ),
  timing_student_stability = list(
    diagnostic_dir,
    "H06_daily_non_l10_production_timing_student_t_stability.csv",
    timing_student_stability
  ),
  timing_ar_models = list(
    diagnostic_dir,
    "H06_daily_non_l10_production_timing_ar_models.csv",
    timing_ar_models
  ),
  timing_ar_stability = list(
    diagnostic_dir,
    "H06_daily_non_l10_production_timing_ar_stability.csv",
    timing_ar_stability
  ),
  timing_ar_lag = list(
    diagnostic_dir,
    "H06_daily_non_l10_production_timing_ar_lag_by_site.csv",
    timing_ar_lag_by_site
  ),
  influence = list(
    diagnostic_dir,
    "H06_daily_non_l10_production_influence_results.csv",
    influence_results
  ),
  influence_summary = list(
    diagnostic_dir,
    "H06_daily_non_l10_production_influence_summary.csv",
    influence_cell
  ),
  catalog = list(
    diagnostic_dir,
    "H06_daily_non_l10_production_model_catalog.csv",
    model_catalog
  ),
  runtime = list(
    diagnostic_dir,
    "H06_daily_non_l10_production_runtime.csv",
    runtime
  )
)
for (output in outputs) {
  h06d_prod_write_csv(output[[3L]], file.path(output[[1L]], output[[2L]]))
}

h06d_prod_recheck_preservation(root, preservation_baseline, "post_postprocess") |>
  h06d_prod_write_csv(artifact(
    "08_diagnostics",
    "H06_daily_non_l10_production_preservation_post_postprocess.csv"
  ))
h06d_prod_write_rds(
  utils::modifyList(
    state,
    list(
      phase = "POSTPROCESS_COMPLETE",
      production_effects = nrow(effects),
      production_raw_tests = nrow(raw_tests),
      multiplicity_families = dplyr::n_distinct(family_claims$multiplicity_family_id),
      multiplicity_slots = nrow(family_claims),
      diagnostic_cells = nrow(diagnostic_assessment),
      updated = format(Sys.time(), tz = "UTC", usetz = TRUE)
    )
  ),
  paths$state
)

message(sprintf(
  paste0(
    "H06-D-013 postprocessing complete: %d effects, %d raw tests, ",
    "%d named BH slots, %d diagnostic cells, and %s deletion refits."
  ),
  nrow(effects),
  nrow(raw_tests),
  nrow(family_claims),
  nrow(diagnostic_assessment),
  format(nrow(influence_results), big.mark = ",")
))
