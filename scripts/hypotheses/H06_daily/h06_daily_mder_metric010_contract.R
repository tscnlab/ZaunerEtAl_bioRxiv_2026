# H06_daily METRIC-010 contract: the mean of viable momentary MDER ratios.
#
# This module is deliberately separate from the historical H06_daily pilot
# contract, whose final metric identifier referred to the superseded
# ratio-of-integrals implementation.  Nothing in this file recalculates MDER.

h06d_m10_abort <- function(..., call. = FALSE) {
  stop(sprintf(...), call. = call.)
}

h06d_m10_assert <- function(condition, ...) {
  if (!isTRUE(condition)) {
    h06d_m10_abort(...)
  }
  invisible(TRUE)
}

h06d_m10_sha256 <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE)
}

h06d_m10_input_contract <- function() {
  tibble::tribble(
    ~input_id, ~relative_path, ~expected_sha256, ~role,
    "metric010_decision",
    "audit/decisions/mder_mean_of_viable_ratios.md",
    "1664347de976057807fcb5ac6e24bd4b66af1fe32378fabd1f2acafcfc9266de",
    "controlling author-approved estimand",
    "metric_manifest",
    "artifacts/12_manifests/metric_artifacts.csv",
    "7bb2830c695e5600f0877acca500a187a040fe727a029bdb069f69099abe4f43",
    "current shared metric manifest",
    "mder_audit_manifest",
    "artifacts/08_diagnostics/mder_METRIC-010/audit_manifest.csv",
    "5bd34fd4ac26dc2761540393d40e096cde835d8dd4b4edda9253243c9083d4bb",
    "independent METRIC-010 verification",
    "base_manifest",
    "artifacts/12_manifests/base_model_data_artifacts.csv",
    "b6fa22836faee5243bb6ce1cc9dceab5d5403f94d688f8f74472a19dbf6e3e09",
    "current shared base-model-data manifest",
    "primary_near_eye",
    "artifacts/06_model_data/base/metrics_glasses_participant_day_enriched.rds",
    "fb04a84f49a410f3474cc64ef97e91183db413197f5815f5dd83805a7d40b06e",
    "near-eye participant-day source",
    "primary_chest",
    "artifacts/06_model_data/base/metrics_chest_participant_day_enriched.rds",
    "f70f93ed59c24c5c75eaa7d87f19be3d57a626c47c788e6d280d0b230ea1db99",
    "chest participant-day source",
    "primary_near_eye_long",
    "artifacts/05_metrics/metrics_glasses_values_long.csv",
    "41201d54e8da965eb3b86970d702c711ff438afba5020c21e1a0a58fb473bd93",
    "near-eye value and support audit",
    "primary_chest_long",
    "artifacts/05_metrics/metrics_chest_values_long.csv",
    "f2dbfe5321993f4d522dd5d52fc8e0292a6c19019d93f4523b52e3d7972ba6cd",
    "chest value and support audit",
    "gap_manifest",
    "artifacts/12_manifests/manuscript_prepared_data_artifacts.csv",
    "4ed62fbe58de65a6d05d8cfc6b5d870d7c74a3c83fe89bcd72bd1dd838698935",
    "gap-timing-unaware artifact manifest",
    "h01_gap_manifest",
    "artifacts/12_manifests/H01_manuscript_prepared_data_artifacts.csv",
    "79ee4818d7f3967827a6412f8537196e84ee7a6ccc1b8d2c5e9dd3124ed44b47",
    "independent gap-timing-unaware artifact manifest",
    "gap_repair_evidence",
    "audit/reconciliation/mder_METRIC-010_gap_repair/gap_repair_evidence_manifest.csv",
    "81e3aa9439b88cf239d6669dc4343cfb146cd2f45790bae412ab837156315018",
    "independently verified METRIC-010 gap repair evidence",
    "gap_participant_day",
    "artifacts/06_model_data/scenarios/manuscript_prepared_data/participant_day_metrics.rds",
    "7561b5dd47cb5e23ca94ba59bd57648f11fe492f86af53a566c5c9cf42d932f1",
    "gap-timing-unaware participant-day values",
    "gap_mder_support",
    "artifacts/06_model_data/scenarios/manuscript_prepared_data/mder_support.rds",
    "a0bc5d7ea2142709412da2253158086416ddb730b0f60ff616bba9d6ccb1edc5",
    "gap-timing-unaware MDER support and failure-reason audit",
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

h06d_m10_metric_contract <- function() {
  tibble::tibble(
    metric_slot = 15L,
    metric_id = "mder_mean_of_viable_ratios",
    source_column = "mder",
    manuscript_name = "Melanopic daylight efficacy ratio",
    abbreviation = "MDER",
    analysis_unit = "participant-day",
    display_unit = "dimensionless",
    lower_bound = 0,
    upper_bound = Inf,
    candidate_family = "Gaussian",
    candidate_link = "identity",
    candidate_transform = "identity",
    practical_effect_scale = "absolute MDER difference"
  )
}

h06d_m10_metric_slot_registry <- function() {
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
    11L, "mean_timing_above_250", "Mean timing of exposure above 250 lx melEDI",
    12L, "first_timing_above_250", "First light timing above 250 lx melEDI",
    13L, "last_timing_above_250", "Last light timing above 250 lx melEDI",
    14L, "dose_time_sensitive_corrected_medi", "melEDI dose",
    15L, "mder_mean_of_viable_ratios", "Melanopic daylight efficacy ratio"
  )
}

h06d_m10_predictor_registry <- function() {
  tibble::tribble(
    ~predictor_order, ~predictor_id, ~column, ~reader_name, ~type,
    ~reference, ~contrast_label, ~term,
    1L, "work_free_day", "work_free_day", "Work/free day", "categorical",
    "Work day", "Free day minus Work day", "work_free_dayFree day",
    3L, "activity_status", "activity_status", "Daily activity status",
    "categorical", "Sedentary", "Active minus Sedentary",
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

h06d_m10_formula_set <- function(predictor_column, ar = FALSE) {
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

h06d_m10_diagnostic_contract <- function() {
  tibble::tribble(
    ~domain, ~acceptable_rule,
    "Gaussian residual spread", "absolute Spearman trend < 0.20",
    "Gaussian tail", "fewer than 1% standardized residuals exceed |4|",
    "Gaussian Q-Q", "correlation >= 0.95; otherwise explicit family review",
    "Physical lower bound", "no more than 1% predictions below -0.05",
    "Temporal dependence",
    "pooled |true one-day r| < 0.20 and every site |r| < 0.30; otherwise fit gap-aware AR(1)",
    "Gap-aware AR(1)",
    ">=100 adjacent pairs, >=20 participants, convergence, |rho| < 0.95, effect shift <1 primary SE",
    "Influence",
    "maximum participant/site deletion shift <1 primary SE; no stable directional claim after a reversal",
    "Multiplicity",
    "15 named slots retained; no BH adjustment until all 15 raw tests exist"
  )
}

h06d_m10_artifact_roots <- function(root) {
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
