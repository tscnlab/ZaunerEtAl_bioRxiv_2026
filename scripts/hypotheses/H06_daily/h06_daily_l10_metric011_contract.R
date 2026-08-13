# H06_daily METRIC-011 contract: exact numerical zeros for the L10 mean.
#
# This module is isolated from the historical H06_daily pilots. It consumes
# shared prepared metrics unchanged and defines only the prespecified L10-mean
# amendment branch.

h06d_l10_abort <- function(..., call. = FALSE) {
  stop(sprintf(...), call. = call.)
}

h06d_l10_assert <- function(condition, ...) {
  if (!isTRUE(condition)) {
    h06d_l10_abort(...)
  }
  invisible(TRUE)
}

h06d_l10_sha256 <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE)
}

h06d_l10_object_sha256 <- function(object) {
  digest::digest(object, algo = "sha256", serialize = TRUE)
}

h06d_l10_input_contract <- function() {
  tibble::tribble(
    ~input_id, ~relative_path, ~expected_sha256, ~role,
    "metric011_decision",
    "audit/decisions/l10_numerical_zero_normalization.md",
    "23b9f70d1d16f7fd3ebbdbc57aaf78c0a701fe1f9d22bd667d926cd320d40797",
    "controlling numerical-zero decision",
    "metric011_evidence_manifest",
    "audit/reconciliation/l10_METRIC-011/METRIC-011_evidence_manifest.csv",
    "a37efd3449a8d1a6065d0eb8964bd6cf8b241f1683a26c065ea1a946e23214fb",
    "independent implementation evidence",
    "metric_manifest",
    "artifacts/12_manifests/metric_artifacts.csv",
    "028bce108339c1277df4a070597430ea20b49c34c2888f4eef42741c1fe76a5e",
    "current shared metric manifest",
    "site_context_manifest",
    "artifacts/12_manifests/site_solar_context_artifacts.csv",
    "c0c6d7f97782c0d880a213050f576213f5d56b3204a02732f6399e7e4aeb8518",
    "current shared site/context manifest",
    "base_manifest",
    "artifacts/12_manifests/base_model_data_artifacts.csv",
    "8344bdc0339a53079bf9eeb7d86de1ad7c15373641c3a0a5a01d040b418895ce",
    "current shared base-model-data manifest",
    "primary_near_eye",
    "artifacts/06_model_data/base/metrics_glasses_participant_day_context.rds",
    "013afe75e9b75b141b4cb48d04111a9e6c688630085a24c9fe07ca3d142a4e9a",
    "near-eye participant-day L10 source",
    "primary_chest",
    "artifacts/06_model_data/base/metrics_chest_participant_day_context.rds",
    "497466ccd1a35635cca40bb8f9ce51efb97321ab04b42ee1bb76785e466a2057",
    "chest participant-day L10 source",
    "gap_manifest",
    "artifacts/12_manifests/manuscript_prepared_data_artifacts.csv",
    "4ed62fbe58de65a6d05d8cfc6b5d870d7c74a3c83fe89bcd72bd1dd838698935",
    "gap-timing-unaware artifact manifest",
    "gap_participant_day",
    paste0(
      "artifacts/06_model_data/scenarios/manuscript_prepared_data/",
      "participant_day_metrics.rds"
    ),
    "7561b5dd47cb5e23ca94ba59bd57648f11fe492f86af53a566c5c9cf42d932f1",
    "gap-timing-unaware L10 values",
    "metric011_changed_cells",
    "audit/reconciliation/l10_METRIC-011/primary_scientific_cell_changes.csv",
    "a32b850d7af2b8c8471445ae1af7f4362d74f4e733c874775a4edfa9a6a3dbeb",
    "exact eight primary changed cells",
    "exercise_diary",
    "artifacts/06_model_data/normalized_inputs/exercisediary.rds",
    "5bffe44cdd9c65f3d1dc20575d10b3f0a403577f3cf9109e83cfea95a2ae7107",
    "immutable daily activity context",
    "sleep_diary",
    "artifacts/06_model_data/normalized_inputs/sleepdiaries.rds",
    "110819d74503c895170552c1f2214aca83de51cadd23bde7525aa821ee0b0e15",
    "immutable work/free and previous-night sleep context",
    "site_registry",
    "config/site_display_registry.csv",
    "3d669d459ecc27d3154bbb5ff5b0d64cb510805d486b45264443228c44a6d809",
    "submitted site order and display names"
  )
}

h06d_l10_base_bundle_sha256 <- function() {
  "e840ce9d2a7f653bc5ebbfe020ce087017dfdaf0276df09da578bda30a539916"
}

h06d_l10_metric_contract <- function() {
  tibble::tibble(
    metric_slot = 3L,
    metric_id = "l10_mean_medi",
    source_column = "l10_mean_medi_lx",
    manuscript_name = "Darkest 10 h mean melEDI",
    analysis_unit = "participant-day",
    display_unit = "lx melEDI",
    lower_bound = 0,
    upper_bound = Inf,
    primary_family = "two-part",
    occurrence_family = "binomial",
    occurrence_link = "logit",
    occurrence_event = "exact zero",
    positive_family = "Gaussian",
    positive_link = "identity",
    positive_transform = "log10",
    zero_rule = "exact normalized zero retained in occurrence; excluded only from positive magnitude"
  )
}

h06d_l10_metric_slot_registry <- function() {
  tibble::tribble(
    ~metric_slot, ~metric_id, ~manuscript_name,
    1L, "daily_geometric_mean_medi", "Mean melEDI",
    2L, "m10_mean_medi", "Brightest 10 h mean",
    3L, "l10_mean_medi", "Darkest 10 h mean",
    4L, "duration_above_1000", "Time above 1,000 lx melEDI",
    5L, "duration_above_250_wake", "Time above 250 lx melEDI during wake",
    6L, "duration_below_10_pre_sleep", "Time below 10 lx melEDI before sleep",
    7L, "duration_below_1_sleep_environment", "Time below 1 lx melEDI during sleep",
    8L, "longest_bout_above_250", "Longest continuous period above 250 lx melEDI",
    9L, "m10_midpoint", "Midpoint of the brightest 10 hours",
    10L, "l10_midpoint", "Midpoint of the darkest 10 hours",
    11L, "mean_timing_above_250", "Mean timing above 250 lx melEDI",
    12L, "first_timing_above_250", "First timing above 250 lx melEDI",
    13L, "last_timing_above_250", "Last timing above 250 lx melEDI",
    14L, "dose_time_sensitive_corrected_medi", "melEDI dose",
    15L, "mder_mean_of_viable_ratios", "Melanopic daylight efficacy ratio"
  )
}

h06d_l10_predictor_registry <- function() {
  tibble::tribble(
    ~predictor_order, ~predictor_id, ~column, ~reader_name, ~type,
    ~reference, ~contrast_label, ~term,
    1L, "work_free_day", "work_free_day", "Work/free day", "categorical",
    "Work day", "Free day versus Work day", "work_free_dayFree day",
    3L, "activity_status", "activity_status", "Daily activity status",
    "categorical", "Sedentary", "Active versus Sedentary",
    "activity_statusActive",
    11L, "previous_sleep_duration_centered_h",
    "previous_sleep_duration_centered_h", "Previous-night sleep duration",
    "continuous", "8 h", "Per 1 h greater previous-night sleep duration",
    "previous_sleep_duration_centered_h"
  ) |>
    dplyr::mutate(
      association_family_id = sprintf("H06-D-A%02d", .data$predictor_order),
      heterogeneity_family_id = sprintf("H06-D-H%02d", .data$predictor_order)
    )
}

h06d_l10_scenario_registry <- function() {
  tibble::tribble(
    ~run_order, ~run_id, ~dataset_id, ~placement_id, ~sample_role,
    ~analysis_role, ~test_role,
    1L, "primary__near_eye__all_available", "primary", "near_eye",
    "all_available", "primary", "primary_raw_slot",
    2L, "primary__chest__all_available", "primary", "chest",
    "all_available", "contextual_complement", "estimate_only",
    3L, "primary__near_eye__paired_common", "primary", "near_eye",
    "paired_common", "paired_complement", "estimate_only",
    4L, "primary__chest__paired_common", "primary", "chest",
    "paired_common", "paired_complement", "estimate_only",
    5L, "gap_timing_unaware__near_eye__all_available",
    "gap_timing_unaware", "near_eye", "all_available",
    "dataset_sensitivity", "gap_raw_slot",
    6L, "gap_timing_unaware__chest__all_available",
    "gap_timing_unaware", "chest", "all_available",
    "dataset_sensitivity_context", "estimate_only"
  )
}

h06d_l10_formula_set <- function(predictor_column, ar = FALSE) {
  ar_term <- if (isTRUE(ar)) {
    " + ar1(day_index_factor + 0 | day_sequence_id)"
  } else {
    ""
  }
  list(
    registered_random_site = stats::as.formula(sprintf(
      "response_value ~ %s + (%s | site) + (1 | site:participant_key)",
      predictor_column,
      predictor_column
    )),
    fixed_site_reduced = stats::as.formula(paste0(
      "response_value ~ site + (1 | participant_key)",
      ar_term
    )),
    fixed_site_additive = stats::as.formula(sprintf(
      "response_value ~ site + %s + (1 | participant_key)%s",
      predictor_column,
      ar_term
    )),
    fixed_site_heterogeneity = stats::as.formula(sprintf(
      "response_value ~ site * %s + (1 | participant_key)%s",
      predictor_column,
      ar_term
    ))
  )
}

h06d_l10_artifact_roots <- function(root) {
  list(
    model_data = file.path(root, "artifacts/06_model_data/H06_daily"),
    models = file.path(root, "artifacts/07_models/H06_daily"),
    diagnostics = file.path(root, "artifacts/08_diagnostics/H06_daily"),
    tables = file.path(root, "artifacts/09_tables/H06_daily"),
    figures = file.path(root, "artifacts/10_figures/H06_daily"),
    source_data = file.path(root, "artifacts/11_source_data/H06_daily"),
    manifests = file.path(root, "artifacts/12_manifests/H06_daily")
  )
}
