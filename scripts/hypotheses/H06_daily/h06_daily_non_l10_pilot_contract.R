# H06_daily H06-D-007 contract for the bounded remaining non-L10 pilot.

h06d_nl_abort <- function(..., call. = FALSE) {
  stop(sprintf(...), call. = call.)
}

h06d_nl_assert <- function(condition, ...) {
  if (!isTRUE(condition)) {
    h06d_nl_abort(...)
  }
  invisible(TRUE)
}

h06d_nl_sha256 <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE)
}

h06d_nl_input_contract <- function() {
  tibble::tribble(
    ~input_id, ~relative_path, ~expected_sha256, ~role,
    "primary_selection",
    "audit/decisions/h06_primary_selection_and_daily_complement.md",
    "c5c08a454ba94a4d955d9821be50b422b697d779b2b5ec921a316c508dd248c1",
    "hourly H06 primary and H06_daily complementary role",
    "non_l10_reopening",
    "audit/decisions/h06_daily_non_l10_grid_reopening.md",
    "0c16d2c89d79aa25a7e8bcfb0404a653186108232c93222af0a3c60695d3cdaa",
    "controlling bounded-pilot authorization",
    "base_gate",
    "audit/decisions/preparation06_current_base_model_gate.md",
    "63f17f1b9b3a91d437a5964cde063770d0fb4fac3f9c81e588fc374d9cc71f04",
    "current Preparation 06 base-model gate",
    "metric_manifest",
    "artifacts/12_manifests/metric_artifacts.csv",
    "028bce108339c1277df4a070597430ea20b49c34c2888f4eef42741c1fe76a5e",
    "current shared metric manifest",
    "base_manifest",
    "artifacts/12_manifests/base_model_data_artifacts.csv",
    "8344bdc0339a53079bf9eeb7d86de1ad7c15373641c3a0a5a01d040b418895ce",
    "current shared base-model-data manifest",
    "site_context_manifest",
    "artifacts/12_manifests/site_solar_context_artifacts.csv",
    "c0c6d7f97782c0d880a213050f576213f5d56b3204a02732f6399e7e4aeb8518",
    "current shared site/context manifest",
    "primary_near_eye",
    "artifacts/06_model_data/base/metrics_glasses_participant_day_enriched.rds",
    "b469fa8f0a743de1cbb1075f78879b84ab602c74cc44fb97da45dee596681f42",
    "current near-eye participant-day source",
    "primary_chest",
    "artifacts/06_model_data/base/metrics_chest_participant_day_enriched.rds",
    "10aebeb5dabb53e8f3ee0747b62c31707da344e11b7068261c2ada2a0b7badc9",
    "current chest participant-day source",
    "exercise_diary",
    "artifacts/06_model_data/normalized_inputs/exercisediary.rds",
    "5bffe44cdd9c65f3d1dc20575d10b3f0a403577f3cf9109e83cfea95a2ae7107",
    "immutable daily activity context",
    "sleep_diary",
    "artifacts/06_model_data/normalized_inputs/sleepdiaries.rds",
    "110819d74503c895170552c1f2214aca83de51cadd23bde7525aa821ee0b0e15",
    "immutable work/free and previous-night sleep context",
    "gap_manifest",
    "artifacts/12_manifests/manuscript_prepared_data_artifacts.csv",
    "4ed62fbe58de65a6d05d8cfc6b5d870d7c74a3c83fe89bcd72bd1dd838698935",
    "gap-timing-unaware preparation manifest",
    "gap_participant_day",
    "artifacts/06_model_data/scenarios/manuscript_prepared_data/participant_day_metrics.rds",
    "7561b5dd47cb5e23ca94ba59bd57648f11fe492f86af53a566c5c9cf42d932f1",
    "gap-timing-unaware participant-day values",
    "metric010_decision",
    "audit/decisions/mder_mean_of_viable_ratios.md",
    "1664347de976057807fcb5ac6e24bd4b66af1fe32378fabd1f2acafcfc9266de",
    "frozen MDER estimand",
    "metric011_decision",
    "audit/decisions/l10_numerical_zero_normalization.md",
    "23b9f70d1d16f7fd3ebbdbc57aaf78c0a701fe1f9d22bd667d926cd320d40797",
    "frozen L10 numerical-zero rule",
    "site_registry",
    "config/site_display_registry.csv",
    "3d669d459ecc27d3154bbb5ff5b0d64cb510805d486b45264443228c44a6d809",
    "submitted site order and display contract",
    "metric010_primary_non_mder_invariance",
    "artifacts/08_diagnostics/mder_METRIC-010/non_mder_invariance.csv",
    "a5de464c193ee732cc9e5c931f58f1c3ba89eee49f7d446f9cf0675c8562fc5e",
    "sealed primary non-MDER preservation evidence",
    "metric010_gap_non_mder_invariance",
    "audit/reconciliation/mder_METRIC-010_gap_repair/gap_non_mder_invariance.csv",
    "e13f1e9099c981fb0d491c1cd31f2e3a9fd7ec441a3cd890780a31c13ab85eba",
    "sealed gap non-MDER preservation evidence",
    "metric010_gap_evidence_manifest",
    "audit/reconciliation/mder_METRIC-010_gap_repair/gap_repair_evidence_manifest.csv",
    "81e3aa9439b88cf239d6669dc4343cfb146cd2f45790bae412ab837156315018",
    "independently verified gap-repair evidence",
    "metric011_invariance_summary",
    "audit/reconciliation/l10_METRIC-011/invariance_summary.csv",
    "34ddcd418be07d50484bad2b62411e6c8961788af0b45d0ff436708ed3d0c213",
    "sealed METRIC-011 non-L10 preservation summary",
    "metric011_evidence_manifest",
    "audit/reconciliation/l10_METRIC-011/METRIC-011_evidence_manifest.csv",
    "a37efd3449a8d1a6065d0eb8964bd6cf8b241f1683a26c065ea1a946e23214fb",
    "independently verified METRIC-011 evidence manifest",
    "historical_daily_pilot_models",
    "artifacts/07_models/H06_daily/H06_daily_stage2_pilot_daily_models.rds",
    "338949fcaeff43156135b956c21ea53f726e011284e3ccb0a7ac2632c5c6e60d",
    "historical composite; access restricted to three named non-L10 members",
    "historical_daily_pilot_software",
    "artifacts/12_manifests/H06_daily/H06_daily_stage2_pilot_software_manifest.csv",
    "9ecb490b7d821b41c91d3154de12f5ad12f0da2affe26fb92efa341e937f677d",
    "historical representative-pilot software identity",
    "historical_daily_pilot_diagnostics",
    "artifacts/08_diagnostics/H06_daily/H06_daily_stage2_pilot_daily_diagnostics.csv",
    "788909932597058d71ac4c11e25542e1e9636254e9ac40958c0a966923284f93",
    "historical representative-pilot diagnostics",
    "historical_daily_pilot_verdict",
    "artifacts/08_diagnostics/H06_daily/H06_daily_stage2_pilot_daily_verdict.csv",
    "9dafaa933120a1caba5a6f35b0d5f0e301774331c2424ead9d185ef9e9c1651c",
    "historical representative-pilot gate verdict",
    "pre_sleep_reference",
    "artifacts/07_models/H06_daily/H06_daily_pre_sleep_only_historical_reference.rds",
    "2c5534516d398f7eef01e5d43ff151cfc88303b8937f8280f91c871b5fd2b98a",
    "standalone frozen pre-sleep reference",
    "l10_protected_history",
    "artifacts/08_diagnostics/H06_daily/H06_daily_l10_shiftlog_historical_preservation_final.csv",
    "f215052bf42ed0e35626dc0064d4c15ac162d7ec36f88b70ce2dfc314ba386f9",
    "118-entry frozen L10 history"
  )
}

h06d_nl_metric_registry <- function() {
  tibble::tribble(
    ~metric_slot, ~metric_id, ~source_column, ~manuscript_name,
    ~display_unit, ~response_family, ~response_transform, ~effect_scale,
    ~lower_bound, ~upper_bound,
    1L, "daily_geometric_mean_medi", "daily_geometric_mean_medi_lx",
    "Mean melEDI", "lx", "gaussian", "log10_offset_0.1",
    "ratio for fitted metric + 0.1 lx", 0, Inf,
    2L, "m10_mean_medi", "m10_mean_medi_lx",
    "Brightest 10 h mean", "lx", "gaussian", "log10_offset_0.1",
    "ratio for fitted metric + 0.1 lx", 0, Inf,
    4L, "duration_above_1000", "duration_above_1000_h",
    "Time above 1,000 lx melEDI", "h", "tweedie_log", "identity",
    "ratio of expected duration", 0, 24,
    5L, "duration_above_250_wake", "duration_above_250_wake_h",
    "Time above 250 lx melEDI during wake", "h", "tweedie_log", "identity",
    "ratio of expected duration", 0, Inf,
    6L, "duration_below_10_pre_sleep", "duration_below_10_pre_sleep_h",
    "Time below 10 lx melEDI before sleep", "h", "gaussian", "identity",
    "absolute difference", 0, 6,
    7L, "duration_below_1_sleep_environment",
    "duration_below_1_sleep_environment_h",
    "Time below 1 lx melEDI during sleep", "h", "tweedie_log", "identity",
    "ratio of expected duration", 0, Inf,
    8L, "longest_bout_above_250", "longest_bout_above_250_h",
    "Longest continuous period above 250 lx melEDI", "h", "gaussian",
    "log10_offset_0.1", "ratio for fitted period + 0.1 h", 0, 24,
    9L, "m10_midpoint", "m10_midpoint_clock_minute",
    "Midpoint of the brightest 10 hours", "clock time", "gaussian",
    "clock_hours", "absolute clock-hour difference", 0, 24,
    10L, "l10_midpoint", "l10_midpoint_clock_minute",
    "Midpoint of the darkest 10 hours", "clock time", "gaussian",
    "clock_hours_midnight_after_16", "absolute unwrapped clock-hour difference",
    0, 24,
    11L, "mean_timing_above_250", "mean_timing_above_250_clock_minute",
    "Mean timing of exposure above 250 lx melEDI", "clock time", "gaussian",
    "clock_hours", "absolute clock-hour difference", 0, 24,
    12L, "first_timing_above_250", "first_timing_above_250_clock_minute",
    "First light timing above 250 lx melEDI", "clock time", "gaussian",
    "clock_hours", "absolute clock-hour difference", 0, 24,
    13L, "last_timing_above_250", "last_timing_above_250_clock_minute",
    "Last light timing above 250 lx melEDI", "clock time", "gaussian",
    "clock_hours", "absolute clock-hour difference", 0, 24,
    14L, "dose_time_sensitive_corrected_medi", "dose_corrected_medi_lx_h",
    "melEDI dose", "lx h", "gaussian", "log10_offset_0.1",
    "ratio for fitted dose + 0.1 lx h", 0, Inf
  ) |>
    dplyr::mutate(
      analysis_unit = "participant-day",
      is_timing = grepl("^clock_hours", .data$response_transform)
    )
}

h06d_nl_full_slot_registry <- function() {
  tibble::tribble(
    ~metric_slot, ~metric_id, ~manuscript_name, ~slot_source,
    1L, "daily_geometric_mean_medi", "Mean melEDI", "new_non_l10",
    2L, "m10_mean_medi", "Brightest 10 h mean", "new_non_l10",
    3L, "l10_mean_medi", "Darkest 10 h mean", "frozen_named_na",
    4L, "duration_above_1000", "Time above 1,000 lx melEDI", "new_non_l10",
    5L, "duration_above_250_wake", "Time above 250 lx melEDI during wake",
    "new_non_l10",
    6L, "duration_below_10_pre_sleep", "Time below 10 lx melEDI before sleep",
    "new_non_l10",
    7L, "duration_below_1_sleep_environment",
    "Time below 1 lx melEDI during sleep", "new_non_l10",
    8L, "longest_bout_above_250",
    "Longest continuous period above 250 lx melEDI", "new_non_l10",
    9L, "m10_midpoint", "Midpoint of the brightest 10 hours", "new_non_l10",
    10L, "l10_midpoint", "Midpoint of the darkest 10 hours", "new_non_l10",
    11L, "mean_timing_above_250",
    "Mean timing of exposure above 250 lx melEDI", "new_non_l10",
    12L, "first_timing_above_250",
    "First light timing above 250 lx melEDI", "new_non_l10",
    13L, "last_timing_above_250",
    "Last light timing above 250 lx melEDI", "new_non_l10",
    14L, "dose_time_sensitive_corrected_medi", "melEDI dose", "new_non_l10",
    15L, "mder_mean_of_viable_ratios",
    "Melanopic daylight efficacy ratio", "frozen_metric010"
  )
}

h06d_nl_predictor_registry <- function() {
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

h06d_nl_formula_set <- function(predictor_column, ar = FALSE) {
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

h06d_nl_run_registry <- function() {
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
    "dataset_sensitivity_context", "estimate_only",
    7L, "gap_timing_unaware__near_eye__paired_common",
    "gap_timing_unaware", "near_eye", "paired_common",
    "dataset_paired_complement", "estimate_only",
    8L, "gap_timing_unaware__chest__paired_common",
    "gap_timing_unaware", "chest", "paired_common",
    "dataset_paired_complement", "estimate_only",
    9L, "primary__near_eye__dataset_common", "primary", "near_eye",
    "dataset_common", "common_sample_primary", "estimate_only",
    10L, "gap_timing_unaware__near_eye__dataset_common",
    "gap_timing_unaware", "near_eye", "dataset_common",
    "common_sample_gap", "estimate_only",
    11L, "primary__chest__dataset_common", "primary", "chest",
    "dataset_common", "common_sample_primary", "estimate_only",
    12L, "gap_timing_unaware__chest__dataset_common",
    "gap_timing_unaware", "chest", "dataset_common",
    "common_sample_gap", "estimate_only"
  )
}

h06d_nl_reuse_registry <- function() {
  tibble::tribble(
    ~reuse_id, ~metric_id, ~predictor_id, ~response_family,
    ~response_transform, ~historical_member,
    "gaussian_offset", "daily_geometric_mean_medi", "work_free_day",
    "gaussian", "log10_offset_0.1",
    "gaussian_offset__fixed_site_additive",
    "tweedie_log", "duration_above_1000", "activity_status",
    "tweedie_log", "identity", "tweedie_duration__fixed_site_additive",
    "gaussian_identity", "duration_below_10_pre_sleep",
    "previous_sleep_duration_centered_h", "gaussian", "identity",
    "gaussian_identity__fixed_site_additive"
  )
}

h06d_nl_artifact_roots <- function(root) {
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
