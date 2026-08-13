#!/usr/bin/env Rscript

# Assemble the targeted gap clock repair outputs from sealed checkpoints.
# This script performs no scientific refitting.

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
  logical(1L),
  quietly = TRUE
)]
if (length(missing_packages)) {
  stop(
    sprintf("Missing package(s): %s", paste(missing_packages, collapse = ", ")),
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
  "h06_daily_non_l10_production_modeling.R",
  "h06_daily_gap_clock_repair_contract.R",
  "h06_daily_gap_clock_repair_data.R"
)) {
  source(file.path(root, "scripts/hypotheses/H06_daily", script))
}
h06d_gap_assert(
  identical(as.character(getRversion()), "4.6.1"),
  "Repair postprocessing requires R 4.6.1"
)
paths <- h06d_gap_paths(root)
invisible(h06d_gap_verify_direct_pins(root))
invisible(h06d_gap_verify_protected_1011(root, "pre_postprocess"))

state <- readRDS(paths$state)
h06d_gap_assert(
  identical(state$phase, "INFLUENCE_COMPLETE") &&
    state$completed_refits == 12837L,
  "Complete repaired base and influence checkpoints are required"
)
base_index <- readr::read_csv(paths$base_index, show_col_types = FALSE) |>
  dplyr::arrange(.data$metric_slot, .data$predictor_order, .data$run_order)
influence_index <- readr::read_csv(
  paths$influence_index,
  show_col_types = FALSE
) |>
  dplyr::arrange(.data$metric_slot, .data$predictor_order, .data$run_order)
h06d_gap_assert(
  nrow(base_index) == 90L && nrow(influence_index) == 90L &&
    identical(base_index$frame_key, influence_index$frame_key) &&
    sum(influence_index$completed_refits) == 12837L,
  "The repaired indexes are incomplete or misaligned"
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
  retained <- setdiff(meta_columns, intersect(names(data), meta_columns))
  dplyr::bind_cols(meta[, retained, drop = FALSE], data)
}
normalize_diagnostic_names <- function(data, frame_key) {
  duplicated_zero <- c("exact_zero_fraction...18", "exact_zero_fraction...24")
  if (all(duplicated_zero %in% names(data))) {
    h06d_gap_assert(
      isTRUE(all.equal(
        data[[duplicated_zero[[1L]]]],
        data[[duplicated_zero[[2L]]]],
        tolerance = 0
      )),
      "Internally reported zero fractions differ for `%s`",
      frame_key
    )
    data$exact_zero_fraction <- data[[duplicated_zero[[1L]]]]
    data <- dplyr::select(data, -dplyr::all_of(duplicated_zero))
  }
  h06d_gap_assert(!anyDuplicated(names(data)), "Duplicate diagnostic names")
  data
}

effects <- tests <- diagnostics <- model_diagnostics <- marginals <- list()
benchmarks <- lag_by_site <- post_ar_lag_by_site <- list()
student_models <- student_stability <- ar_models <- ar_stability <- ar_lag <- list()
model_catalog <- list()

message("Gap clock repair: collecting 90 sealed base cells")
for (index in seq_len(nrow(base_index))) {
  meta <- base_index[index, , drop = FALSE]
  absolute <- file.path(root, meta$checkpoint_relative_path[[1L]])
  h06d_gap_assert(
    file.exists(absolute) &&
      h06d_gap_sha256(absolute) == meta$checkpoint_sha256[[1L]],
    "Base checkpoint changed for `%s`",
    meta$frame_key[[1L]]
  )
  object <- readRDS(absolute)
  h06d_gap_assert(
    identical(object$authorization, h06d_gap_authorization()$authorization) &&
      identical(object$gate, h06d_gap_authorization()$gate) &&
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
    student_models[[index]] <- add_meta(result$student_t$diagnostics, meta)
    student_stability[[index]] <- add_meta(result$student_t$stability, meta)
    ar_models[[index]] <- add_meta(result$no_nugget_ar$diagnostics, meta)
    ar_stability[[index]] <- add_meta(result$no_nugget_ar$stability, meta)
    ar_lag[[index]] <- add_meta(result$no_nugget_ar$lag, meta)
  }
  model_catalog[[index]] <- meta |>
    dplyr::transmute(
      run_order, run_id, dataset_id, placement_id, sample_role, analysis_role,
      metric_slot, metric_id, predictor_order, predictor_id, frame_key, route,
      checkpoint_relative_path, checkpoint_sha256, checkpoint_bytes,
      frame_object_sha256, fit_code_sha256, outer_warning_count,
      outer_warnings, elapsed_seconds
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
student_models <- dplyr::bind_rows(student_models)
student_stability <- dplyr::bind_rows(student_stability)
ar_models <- dplyr::bind_rows(ar_models)
ar_stability <- dplyr::bind_rows(ar_stability)
ar_lag <- dplyr::bind_rows(ar_lag)
model_catalog <- dplyr::bind_rows(model_catalog)
h06d_gap_assert(
  nrow(effects) == 90L && nrow(raw_tests) == 180L &&
    nrow(diagnostics) == 90L && nrow(model_catalog) == 90L &&
    nrow(student_stability) == 144L && nrow(ar_stability) == 144L,
  "A repaired base component is incomplete"
)

# The accepted mixed Gaussian response-family sensitivity is triggered by the
# frozen production rule. Scaling the response from hour/60 to hour cannot
# alter the three scale-free trigger summaries; record the resulting no-fit
# disposition for all 18 mean-timing cells.
mean_student <- diagnostics |>
  dplyr::filter(.data$metric_slot == 11L) |>
  dplyr::transmute(
    dplyr::across(dplyr::all_of(meta_columns)),
    trigger_student_t =
      is.finite(.data$residual_qq_correlation) &
        .data$residual_qq_correlation < 0.95 |
      is.finite(.data$absolute_residual_fitted_spearman) &
        abs(.data$absolute_residual_fitted_spearman) >= 0.20 |
      is.finite(.data$standardized_residual_gt4_fraction) &
        .data$standardized_residual_gt4_fraction >= 0.01,
    sensitivity_status = dplyr::if_else(
      .data$trigger_student_t,
      "TRIGGERED_REQUIRES_FIT",
      "NOT_TRIGGERED_BY_FROZEN_PRODUCTION_RULE"
    ),
    inferential_role = "diagnostic only; no p-value substitution"
  )
h06d_gap_assert(
  nrow(mean_student) == 18L && !any(mean_student$trigger_student_t),
  "The corrected mean-timing Student-t trigger unexpectedly changed"
)

message("Gap clock repair: consolidating 12,837 deletion refits")
influence_results <- lapply(seq_len(nrow(influence_index)), function(index) {
  meta <- influence_index[index, , drop = FALSE]
  absolute <- file.path(root, meta$checkpoint_relative_path[[1L]])
  h06d_gap_assert(
    file.exists(absolute) &&
      h06d_gap_sha256(absolute) == meta$checkpoint_sha256[[1L]],
    "Influence checkpoint changed for `%s`",
    meta$frame_key[[1L]]
  )
  object <- readRDS(absolute)
  h06d_gap_assert(
    identical(object$authorization, h06d_gap_authorization()$authorization) &&
      identical(object$frame_key, meta$frame_key[[1L]]) &&
      identical(object$frame_object_sha256, meta$frame_object_sha256[[1L]]) &&
      nrow(object$results) == meta$completed_refits[[1L]] &&
      identical(
        object$results$task_within_cell,
        seq_len(meta$completed_refits[[1L]])
      ),
    "Influence checkpoint contract failed for `%s`",
    meta$frame_key[[1L]]
  )
  object$results
}) |>
  dplyr::bind_rows() |>
  dplyr::arrange(.data$global_task_id)
h06d_gap_assert(
  nrow(influence_results) == 12837L &&
    identical(influence_results$global_task_id, seq_len(12837L)) &&
    !anyDuplicated(influence_results[c("frame_key", "deletion_label")]),
  "The consolidated repaired influence battery is incomplete"
)

influence_summary <- influence_index |>
  dplyr::transmute(
    dplyr::across(dplyr::all_of(meta_columns)),
    influence_expected_refits = .data$expected_refits,
    influence_completed_refits = .data$completed_refits,
    influence_failed_refits = .data$failed_refits,
    influence_warning_count = .data$warning_count,
    influence_direction_reversals = .data$direction_reversals,
    influence_maximum_shift_in_full_se =
      .data$maximum_absolute_shift_in_full_se,
    influence_substantial_limitations = .data$substantial_limitations,
    influence_unstable_refits = .data$unstable_refits,
    influence_classification = dplyr::case_when(
      .data$failed_refits > 0L ~ "NON_ESTIMABLE_DELETION_REFIT_PRESENT",
      .data$unstable_refits > 0L ~ "UNSTABLE",
      .data$substantial_limitations > 0L ~ "SUBSTANTIAL_LIMITATION",
      TRUE ~ "STABLE"
    ),
    influence_wall_seconds = .data$cell_wall_seconds,
    influence_checkpoint_relative_path = .data$checkpoint_relative_path,
    influence_checkpoint_sha256 = .data$checkpoint_sha256
  )

# Replace exactly the 30 affected primary-gap raw timing tests, then recompute
# only the six gap families. The primary 90 rows and all unaffected raw slots
# are copied without modification from the frozen historical family table.
historical_bh <- readr::read_csv(
  file.path(
    paths$tables,
    "H06_daily_non_l10_production_bh_families.csv"
  ),
  show_col_types = FALSE
)
replacement <- raw_tests |>
  dplyr::filter(
    .data$placement_id == "near_eye",
    .data$sample_role == "all_available",
    .data$metric_slot %in% 9:13
  ) |>
  dplyr::select(
    "dataset_id", "predictor_id", "test_type", "metric_slot",
    repaired_raw_p_value = "raw_p_value",
    repaired_method = "method",
    repaired_test_status = "test_status",
    repaired_frame_key = "frame_key"
  )
h06d_gap_assert(
  nrow(replacement) == 30L &&
    !anyDuplicated(replacement[c(
      "dataset_id", "predictor_id", "test_type", "metric_slot"
    )]),
  "The 30-test repair source is incomplete"
)
repaired_bh <- historical_bh |>
  dplyr::left_join(
    replacement,
    by = c("dataset_id", "predictor_id", "test_type", "metric_slot"),
    relationship = "one-to-one"
  ) |>
  dplyr::mutate(
    repaired_slot = !is.na(.data$repaired_test_status),
    raw_p_value = dplyr::if_else(
      .data$repaired_slot,
      .data$repaired_raw_p_value,
      .data$raw_p_value
    ),
    method = dplyr::if_else(
      .data$repaired_slot,
      .data$repaired_method,
      .data$method
    ),
    test_status = dplyr::if_else(
      .data$repaired_slot,
      .data$repaired_test_status,
      .data$test_status
    ),
    frame_key = dplyr::if_else(
      .data$repaired_slot,
      .data$repaired_frame_key,
      .data$frame_key
    ),
    slot_source = dplyr::if_else(
      .data$repaired_slot,
      "gap_clock_repair",
      .data$slot_source
    )
  ) |>
  dplyr::select(-dplyr::starts_with("repaired_")) |>
  dplyr::group_by(.data$dataset_id, .data$predictor_id, .data$test_type) |>
  dplyr::mutate(
    bh_adjusted_p_value = {
      output <- rep(NA_real_, dplyr::n())
      available <- is.finite(.data$raw_p_value)
      output[available] <- stats::p.adjust(
        .data$raw_p_value[available],
        method = "BH",
        n = 15L
      )
      output
    },
    raw_rank_within_available = {
      output <- rep(NA_real_, dplyr::n())
      available <- is.finite(.data$raw_p_value)
      output[available] <- rank(
        .data$raw_p_value[available],
        ties.method = "min"
      )
      output
    },
    raw_decision = dplyr::case_when(
      !is.finite(.data$raw_p_value) ~ "NOT_ESTIMABLE",
      .data$raw_p_value < 0.05 ~ "RAW_P_LT_0.05",
      TRUE ~ "RAW_P_GE_0.05"
    ),
    adjusted_decision = dplyr::case_when(
      !is.finite(.data$bh_adjusted_p_value) ~ "NOT_ESTIMABLE",
      .data$bh_adjusted_p_value < 0.05 ~ "BH_Q_LT_0.05",
      TRUE ~ "BH_Q_GE_0.05"
    ),
    family_slots_available = sum(is.finite(.data$raw_p_value)),
    family_slots_required = 15L,
    family_status = "COMPLETE_NAMED_15_SLOT_FAMILY_WITH_NA_SLOTS",
    multiplicity_method = "Benjamini-Hochberg; stats::p.adjust(n = 15)"
  ) |>
  dplyr::ungroup() |>
  dplyr::mutate(
    diagnostic_status = dplyr::if_else(
      .data$dataset_id == "gap_timing_unaware" & .data$metric_slot %in% 9:13,
      "PENDING_REPAIRED_VISUAL_REVIEW",
      .data$diagnostic_status
    ),
    association_claim_status = dplyr::if_else(
      .data$dataset_id == "gap_timing_unaware" & .data$metric_slot %in% 9:13,
      "PENDING_REPAIRED_VISUAL_REVIEW",
      .data$association_claim_status
    ),
    heterogeneity_claim_status = dplyr::if_else(
      .data$dataset_id == "gap_timing_unaware" & .data$metric_slot %in% 9:13,
      "PENDING_REPAIRED_VISUAL_REVIEW",
      .data$heterogeneity_claim_status
    ),
    claim_status = dplyr::if_else(
      .data$dataset_id == "gap_timing_unaware" & .data$metric_slot %in% 9:13,
      "PENDING_REPAIRED_VISUAL_REVIEW",
      .data$claim_status
    ),
    adjusted_inferential_decision = dplyr::if_else(
      .data$dataset_id == "gap_timing_unaware" & .data$metric_slot %in% 9:13,
      "PENDING_REPAIRED_VISUAL_REVIEW",
      .data$adjusted_inferential_decision
    ),
    family_slots_available = as.numeric(.data$family_slots_available),
    family_slots_required = as.numeric(.data$family_slots_required)
  )

# The computation above is vectorized across the common table structure, but
# the authorization permits derived multiplicity changes only in gap
# families. Restore every primary field from the frozen table by exact key.
primary_key <- with(
  historical_bh,
  paste(dataset_id, predictor_id, test_type, metric_slot, sep = "::")
)
repaired_key <- with(
  repaired_bh,
  paste(dataset_id, predictor_id, test_type, metric_slot, sep = "::")
)
primary_rows <- repaired_bh$dataset_id == "primary"
historical_primary_match <- match(
  repaired_key[primary_rows],
  primary_key
)
h06d_gap_assert(
  !anyNA(historical_primary_match),
  "A primary family key was lost during repair assembly"
)
repaired_bh[primary_rows, names(historical_bh)] <-
  historical_bh[historical_primary_match, names(historical_bh)]
h06d_gap_assert(
  nrow(repaired_bh) == 180L &&
    all(repaired_bh$family_slots_available == 14L) &&
    all(repaired_bh$family_slots_required == 15L),
  "The repaired full multiplicity table is incomplete"
)

primary_columns <- names(historical_bh)
historical_primary <- historical_bh |>
  dplyr::filter(.data$dataset_id == "primary") |>
  dplyr::arrange(.data$predictor_order, .data$test_type, .data$metric_slot)
repaired_primary <- repaired_bh |>
  dplyr::filter(.data$dataset_id == "primary") |>
  dplyr::arrange(.data$predictor_order, .data$test_type, .data$metric_slot)
primary_column_identity <- vapply(
  primary_columns,
  function(column) identical(
    historical_primary[[column]],
    repaired_primary[[column]]
  ),
  logical(1L)
)
primary_unchanged <- all(primary_column_identity)
if (!primary_unchanged) {
  message(
    "Primary columns not identical: ",
    paste(names(primary_column_identity)[!primary_column_identity], collapse = ", ")
  )
}
unaffected_gap <- historical_bh |>
  dplyr::filter(
    .data$dataset_id == "gap_timing_unaware",
    !.data$metric_slot %in% 9:13
  ) |>
  dplyr::select(
    "dataset_id", "predictor_id", "test_type", "metric_slot",
    old_raw_p_value = "raw_p_value", old_method = "method",
    old_test_status = "test_status", old_frame_key = "frame_key"
  ) |>
  dplyr::left_join(
    repaired_bh |>
      dplyr::filter(
        .data$dataset_id == "gap_timing_unaware",
        !.data$metric_slot %in% 9:13
      ) |>
      dplyr::select(
        "dataset_id", "predictor_id", "test_type", "metric_slot",
        new_raw_p_value = "raw_p_value", new_method = "method",
        new_test_status = "test_status", new_frame_key = "frame_key"
      ),
    by = c("dataset_id", "predictor_id", "test_type", "metric_slot"),
    relationship = "one-to-one"
  ) |>
  dplyr::mutate(
    raw_model_fields_identical =
      dplyr::coalesce(.data$old_raw_p_value == .data$new_raw_p_value, TRUE) &
      dplyr::coalesce(.data$old_method == .data$new_method, TRUE) &
      dplyr::coalesce(.data$old_test_status == .data$new_test_status, TRUE) &
      dplyr::coalesce(.data$old_frame_key == .data$new_frame_key, TRUE)
  )
h06d_gap_assert(
  primary_unchanged,
  "A primary family field changed"
)
h06d_gap_assert(
  nrow(unaffected_gap) == 60L &&
    all(unaffected_gap$raw_model_fields_identical),
  "An unaffected gap raw/model field changed"
)

scale_comparison <- historical_bh |>
  dplyr::filter(
    .data$dataset_id == "gap_timing_unaware",
    .data$metric_slot %in% 9:13
  ) |>
  dplyr::select(
    "dataset_id", "predictor_id", "test_type", "metric_slot", "metric_id",
    historical_raw_p_value = "raw_p_value",
    historical_bh_q = "bh_adjusted_p_value"
  ) |>
  dplyr::left_join(
    repaired_bh |>
      dplyr::filter(
        .data$dataset_id == "gap_timing_unaware",
        .data$metric_slot %in% 9:13
      ) |>
      dplyr::select(
        "dataset_id", "predictor_id", "test_type", "metric_slot",
        repaired_raw_p_value = "raw_p_value",
        repaired_bh_q = "bh_adjusted_p_value"
      ),
    by = c("dataset_id", "predictor_id", "test_type", "metric_slot"),
    relationship = "one-to-one"
  ) |>
  dplyr::mutate(
    absolute_raw_p_difference = abs(
      .data$repaired_raw_p_value - .data$historical_raw_p_value
    ),
    absolute_bh_q_difference = abs(
      .data$repaired_bh_q - .data$historical_bh_q
    ),
    inference_scale_equivariant_within_1e_10 =
      .data$absolute_raw_p_difference <= 1e-10 &
      .data$absolute_bh_q_difference <= 1e-10
  )
h06d_gap_assert(
  nrow(scale_comparison) == 30L &&
    all(scale_comparison$inference_scale_equivariant_within_1e_10),
  "Corrected timing inference was not scale-equivariant"
)

runtime <- tibble::tibble(
  component = c(
    "90 repaired base cells and embedded sidecars",
    "50-refit production-code pilot",
    "complete participant/site deletion battery"
  ),
  completed_units = c(90L, 50L, 12837L),
  wall_seconds = c(
    state$base_elapsed_seconds,
    readr::read_csv(
      file.path(
        paths$diagnostic,
        "H06_daily_gap_clock_repair_influence_pilot_runtime.csv"
      ),
      show_col_types = FALSE
    )$pilot_wall_seconds,
    state$influence_wall_seconds
  ),
  execution = "serial; R 4.6.1; no bootstrap or simulation"
)

outputs <- list(
  effects = list(paths$tables, "H06_daily_gap_clock_repair_effects.csv", effects),
  tests = list(paths$tables, "H06_daily_gap_clock_repair_raw_tests.csv", raw_tests),
  bh = list(paths$tables, "H06_daily_gap_clock_repair_bh_families_provisional.csv", repaired_bh),
  scale = list(paths$tables, "H06_daily_gap_clock_repair_scale_equivariance.csv", scale_comparison),
  unaffected = list(paths$tables, "H06_daily_gap_clock_repair_unaffected_raw_model_fields.csv", unaffected_gap),
  diagnostics = list(paths$diagnostic, "H06_daily_gap_clock_repair_diagnostics.csv", diagnostics),
  model_diagnostics = list(paths$diagnostic, "H06_daily_gap_clock_repair_model_diagnostics.csv", model_diagnostics),
  influence = list(paths$diagnostic, "H06_daily_gap_clock_repair_influence_results.csv", influence_results),
  influence_summary = list(paths$diagnostic, "H06_daily_gap_clock_repair_influence_summary.csv", influence_summary),
  student_models = list(paths$diagnostic, "H06_daily_gap_clock_repair_student_t_model_diagnostics.csv", student_models),
  student_stability = list(paths$diagnostic, "H06_daily_gap_clock_repair_student_t_stability.csv", student_stability),
  mean_student = list(paths$diagnostic, "H06_daily_gap_clock_repair_mean_timing_student_t_trigger.csv", mean_student),
  ar_models = list(paths$diagnostic, "H06_daily_gap_clock_repair_ar_model_diagnostics.csv", ar_models),
  ar_stability = list(paths$diagnostic, "H06_daily_gap_clock_repair_ar_stability.csv", ar_stability),
  ar_lag = list(paths$diagnostic, "H06_daily_gap_clock_repair_ar_lag_by_site.csv", ar_lag),
  lag = list(paths$diagnostic, "H06_daily_gap_clock_repair_independent_lag_by_site.csv", lag_by_site),
  post_ar_lag = list(paths$diagnostic, "H06_daily_gap_clock_repair_post_ar_lag_by_site.csv", post_ar_lag_by_site),
  marginals = list(paths$tables, "H06_daily_gap_clock_repair_equal_site_marginals.csv", marginals),
  benchmark = list(paths$diagnostic, "H06_daily_gap_clock_repair_registered_benchmarks.csv", benchmarks),
  model_catalog = list(paths$manifests, "H06_daily_gap_clock_repair_model_catalog.csv", model_catalog),
  runtime = list(paths$diagnostic, "H06_daily_gap_clock_repair_runtime.csv", runtime)
)
for (output in outputs) {
  h06d_gap_write_csv(output[[3L]], file.path(output[[1L]], output[[2L]]))
}

state$phase <- "POSTPROCESS_COMPLETE"
state$raw_tests <- nrow(raw_tests)
state$provisional_bh_rows <- nrow(repaired_bh)
state$scale_equivariance_max_raw_p_difference <- max(
  scale_comparison$absolute_raw_p_difference
)
state$scale_equivariance_max_bh_q_difference <- max(
  scale_comparison$absolute_bh_q_difference
)
state$updated <- format(Sys.time(), tz = "UTC", usetz = TRUE)
h06d_gap_write_rds(state, paths$state)
invisible(h06d_gap_verify_protected_1011(root, "post_postprocess"))
message(sprintf(
  paste0(
    "Gap clock repair postprocessing complete: 90 cells, 180 raw tests, ",
    "six recomputed gap families; max raw-p difference %.3g"
  ),
  state$scale_equivariance_max_raw_p_difference
))
