# Define the author-approved H10 Stage 2 analysis contract.

h10_abort <- function(message, ..., call. = FALSE) {
  stop(sprintf(message, ...), call. = call.)
}

h10_metric_registry <- function() {
  tibble::tribble(
    ~metric_order,
    ~metric_id,
    ~analysis_unit,
    ~source_field,
    ~response_family,
    ~response_transform,
    ~effect_scale,
    ~lower_bound,
    ~upper_bound,
    ~audit_upper_threshold,
    1L,
    "interdaily_stability",
    "participant",
    "interdaily_stability",
    "gaussian",
    "logit",
    "odds_ratio",
    0,
    1,
    NA_real_,
    2L,
    "intradaily_variability",
    "participant",
    "intradaily_variability",
    "gaussian",
    "identity",
    "difference",
    0,
    NA_real_,
    NA_real_,
    3L,
    "daily_geometric_mean_medi",
    "participant_day",
    "daily_geometric_mean_medi_lx",
    "gaussian",
    "log10_offset_0.1",
    "ratio",
    0,
    NA_real_,
    NA_real_,
    4L,
    "m10_mean_medi",
    "participant_day",
    "m10_mean_medi_lx",
    "gaussian",
    "log10_offset_0.1",
    "ratio",
    0,
    NA_real_,
    NA_real_,
    5L,
    "l10_mean_medi",
    "participant_day",
    "l10_mean_medi_lx",
    "gaussian",
    "log10_offset_0.1",
    "ratio",
    0,
    NA_real_,
    NA_real_,
    6L,
    "duration_above_1000",
    "participant_day",
    "duration_above_1000_h",
    "tweedie_log",
    "identity",
    "ratio",
    0,
    24,
    NA_real_,
    7L,
    "duration_above_250_wake",
    "participant_day",
    "duration_above_250_wake_h",
    "tweedie_log",
    "identity",
    "ratio",
    0,
    NA_real_,
    NA_real_,
    8L,
    "duration_below_10_pre_sleep",
    "participant_day",
    "duration_below_10_pre_sleep_h",
    "gaussian",
    "identity",
    "difference",
    0,
    24,
    6,
    9L,
    "duration_below_1_sleep_environment",
    "participant_day",
    "duration_below_1_sleep_environment_h",
    "tweedie_log",
    "identity",
    "ratio",
    0,
    NA_real_,
    NA_real_,
    10L,
    "longest_bout_above_250",
    "participant_day",
    "longest_bout_above_250_h",
    "gaussian",
    "log10_offset_0.1",
    "ratio",
    0,
    24,
    NA_real_,
    11L,
    "m10_midpoint",
    "participant_day",
    "m10_midpoint_clock_minute",
    "gaussian",
    "clock_minutes",
    "difference",
    0,
    1440,
    NA_real_,
    12L,
    "l10_midpoint",
    "participant_day",
    "l10_midpoint_clock_minute",
    "gaussian",
    "clock_minutes_after_16",
    "difference",
    -1440,
    1440,
    NA_real_,
    13L,
    "mean_timing_above_250",
    "participant_day",
    "mean_timing_above_250_clock_minute",
    "gaussian",
    "clock_minutes",
    "difference",
    0,
    1440,
    NA_real_,
    14L,
    "first_timing_above_250",
    "participant_day",
    "first_timing_above_250_clock_minute",
    "gaussian",
    "clock_minutes",
    "difference",
    0,
    1440,
    NA_real_,
    15L,
    "last_timing_above_250",
    "participant_day",
    "last_timing_above_250_clock_minute",
    "gaussian",
    "clock_minutes",
    "difference",
    0,
    1440,
    NA_real_,
    16L,
    "dose_time_sensitive_corrected_medi",
    "participant_day",
    "dose_corrected_medi_lx_h",
    "gaussian",
    "log10_offset_0.1",
    "ratio",
    0,
    NA_real_,
    NA_real_,
    17L,
    "mder_mean_of_viable_ratios",
    "participant_day",
    "mder",
    "gaussian",
    "identity",
    "difference",
    0,
    NA_real_,
    NA_real_
  )
}

h10_formula_set <- function(analysis_unit) {
  if (!analysis_unit %in% c("participant", "participant_day")) {
    h10_abort("Unknown H10 analysis unit: %s", analysis_unit)
  }
  random <- if (analysis_unit == "participant_day") {
    " + (1 | site:Id)"
  } else {
    ""
  }
  make <- function(rhs) {
    stats::as.formula(paste0("response ~ ", rhs, random))
  }
  list(
    M0 = make("site"),
    M_age = make("site + age_decade"),
    M_age_site = make("site * age_decade"),
    M_sex = make("site + biological_sex"),
    M_sex_site = make("site * biological_sex")
  )
}

h10_comparison_registry <- function() {
  tibble::tribble(
    ~comparison_order,
    ~comparison_id,
    ~predictor,
    ~comparison_role,
    ~reduced_model,
    ~full_model,
    ~family_near_eye,
    ~family_chest,
    1L,
    "AGE-MAIN",
    "age",
    "main_association",
    "M0",
    "M_age",
    "H10-F1-age-main",
    "H10-C1-age-main",
    2L,
    "SEX-MAIN",
    "biological_sex",
    "main_association",
    "M0",
    "M_sex",
    "H10-F2-sex-main",
    "H10-C2-sex-main",
    3L,
    "AGE-SITE",
    "age",
    "site_heterogeneity",
    "M_age",
    "M_age_site",
    "H10-F3-age-site-interaction",
    "H10-C3-age-site-interaction",
    4L,
    "SEX-SITE",
    "biological_sex",
    "site_heterogeneity",
    "M_sex",
    "M_sex_site",
    "H10-F4-sex-site-interaction",
    "H10-C4-sex-site-interaction"
  ) |>
    dplyr::mutate(
      adjustment_method = "BH",
      planned_n = 17L
    )
}

h10_primary_run_registry <- function() {
  tidyr::crossing(
    data_scenario = c("primary", "gap_timing_unaware"),
    placement = c("glasses", "chest")
  ) |>
    dplyr::mutate(
      sample_scenario = "all_available",
      run_id = paste(
        .data$data_scenario,
        .data$placement,
        .data$sample_scenario,
        sep = "__"
      ),
      analytical_role = dplyr::case_when(
        .data$data_scenario == "primary" &
          .data$placement == "glasses" ~
          "primary_near_eye",
        .data$data_scenario == "primary" ~ "complementary_chest",
        .data$placement == "glasses" ~ "gap_timing_unaware_near_eye",
        TRUE ~ "gap_timing_unaware_chest"
      )
    )
}

h10_input_contract <- function(root) {
  tibble::tribble(
    ~input_role,
    ~path,
    ~expected_sha256,
    "metric_manifest",
    "artifacts/12_manifests/metric_artifacts.csv",
    "028bce108339c1277df4a070597430ea20b49c34c2888f4eef42741c1fe76a5e",
    "site_context_manifest",
    "artifacts/12_manifests/site_solar_context_artifacts.csv",
    "c0c6d7f97782c0d880a213050f576213f5d56b3204a02732f6399e7e4aeb8518",
    "base_manifest",
    "artifacts/12_manifests/base_model_data_artifacts.csv",
    "8344bdc0339a53079bf9eeb7d86de1ad7c15373641c3a0a5a01d040b418895ce",
    "metric011_decision",
    "audit/decisions/l10_numerical_zero_normalization.md",
    "23b9f70d1d16f7fd3ebbdbc57aaf78c0a701fe1f9d22bd667d926cd320d40797",
    "metric011_evidence_manifest",
    "audit/reconciliation/l10_METRIC-011/METRIC-011_evidence_manifest.csv",
    "a37efd3449a8d1a6065d0eb8964bd6cf8b241f1683a26c065ea1a946e23214fb",
    "mder_decision",
    "audit/decisions/mder_mean_of_viable_ratios.md",
    "1664347de976057807fcb5ac6e24bd4b66af1fe32378fabd1f2acafcfc9266de",
    "mder_audit_manifest",
    "artifacts/08_diagnostics/mder_METRIC-010/audit_manifest.csv",
    "5bd34fd4ac26dc2761540393d40e096cde835d8dd4b4edda9253243c9083d4bb",
    "state_support_manifest",
    "artifacts/12_manifests/state_support_gate_artifacts.csv",
    "755508076e42ed74ce0d40f48de192b69ea81b04532db2d5a950c451236e2619",
    "near_eye_context",
    "artifacts/06_model_data/base/metrics_glasses_participant_day_context.rds",
    "013afe75e9b75b141b4cb48d04111a9e6c688630085a24c9fe07ca3d142a4e9a",
    "chest_context",
    "artifacts/06_model_data/base/metrics_chest_participant_day_context.rds",
    "497466ccd1a35635cca40bb8f9ce51efb97321ab04b42ee1bb76785e466a2057",
    "near_eye_daily_enriched",
    "artifacts/06_model_data/base/metrics_glasses_participant_day_enriched.rds",
    "b469fa8f0a743de1cbb1075f78879b84ab602c74cc44fb97da45dee596681f42",
    "chest_daily_enriched",
    "artifacts/06_model_data/base/metrics_chest_participant_day_enriched.rds",
    "10aebeb5dabb53e8f3ee0747b62c31707da344e11b7068261c2ada2a0b7badc9",
    "near_eye_participant_enriched",
    "artifacts/06_model_data/base/metrics_glasses_participant_enriched.rds",
    "42d7980f641f1ec557daf75547f0f8d6a212714087576aa7d1cdbc7bef267850",
    "chest_participant_enriched",
    "artifacts/06_model_data/base/metrics_chest_participant_enriched.rds",
    "2784007a55e778dc02336a7e105b5f788f769acda573e87af48bf5bec0832058",
    "normalized_demographics",
    "artifacts/06_model_data/normalized_inputs/demographics.rds",
    "a11d0ff6615b51dbaa0be8c0790c1ea550750d9f1d4d7e8893609803f269dadf",
    "gap_daily_metrics",
    paste0(
      "artifacts/06_model_data/scenarios/manuscript_prepared_data/",
      "participant_day_metrics.rds"
    ),
    "7561b5dd47cb5e23ca94ba59bd57648f11fe492f86af53a566c5c9cf42d932f1",
    "gap_participant_metrics",
    paste0(
      "artifacts/06_model_data/scenarios/manuscript_prepared_data/",
      "participant_metrics.rds"
    ),
    "ab06279daac01311219ebc1267b7f1506012f362823c7fd8d0cf2254d862fd1e",
    "gap_mder_support",
    paste0(
      "artifacts/06_model_data/scenarios/manuscript_prepared_data/",
      "mder_support.rds"
    ),
    "a0bc5d7ea2142709412da2253158086416ddb730b0f60ff616bba9d6ccb1edc5",
    "gap_preparation_manifest",
    "artifacts/12_manifests/manuscript_prepared_data_artifacts.csv",
    "4ed62fbe58de65a6d05d8cfc6b5d870d7c74a3c83fe89bcd72bd1dd838698935",
    "primary_h01_prepared_provenance",
    "artifacts/06_model_data/H01.rds",
    "0328fe1a698bc13965feb0b68b03ccf0fd20f32b55d6148635811b0d674e0a00",
    "gap_h01_prepared_provenance",
    "artifacts/06_model_data/H01/scenarios/manuscript_prepared_data/H01.rds",
    "3c70363fc0468202a431904aa9d9444f2858af2e3add3475a56c872b49a18bd6",
    "primary_h01_prepared_manifest",
    "artifacts/12_manifests/H01_model_data_artifacts.csv",
    "25978c5d6903e6e835c1aff6a9bc2e7552b85295e8d840d3dd65bbf9b1eb6b72",
    "gap_h01_prepared_manifest",
    "artifacts/12_manifests/H01_manuscript_prepared_data_artifacts.csv",
    "e0d98178ede61b74353e3a654e7f1b53d7e1c915833a2cda74eea45ed02f383b",
    "preanalysis_comparison_manifest",
    "artifacts/12_manifests/preanalysis_comparison_artifacts.csv",
    "f3c4bfbf120d2023c045b44e3c7c04c58bce1f8d11621956bca1e5ede90c5623",
    "gap_repair_evidence_manifest",
    paste0(
      "audit/reconciliation/mder_METRIC-010_gap_repair/",
      "gap_repair_evidence_manifest.csv"
    ),
    "81e3aa9439b88cf239d6669dc4343cfb146cd2f45790bae412ab837156315018",
    "downstream_rebuild_manifest",
    paste0(
      "artifacts/08_diagnostics/mder_METRIC-010/downstream_rebuild/",
      "rebuild_manifest.csv"
    ),
    "408087d420999322628066caae31efc288a5a5213b8b57d4b9a4ad77c9ec9a77",
    "metric_display_registry",
    "config/metric_display_registry.csv",
    "c82db05a77cc50ce5b9dbd459c90997fa6bb7d87c0b8e880c1bf8186fad06ed0",
    "site_display_registry",
    "config/site_display_registry.csv",
    "3d669d459ecc27d3154bbb5ff5b0d64cb510805d486b45264443228c44a6d809",
    "final_h01_response_selection",
    paste0(
      "artifacts/09_tables/H01/response_family_candidates/",
      "H01_response_family_candidate_selection.csv"
    ),
    "37e38ed7715c3c5e364557a79795c321548ee8f14efcca91204adbf26a1bf0e0",
    "deviation_source",
    "_deviations.qmd",
    "a2565a71482d761877d9852932ee2118a3f319959a32af94ab3de1cf4d7ab7bb",
    "v0_near_eye_render",
    "docs/RQ3.html",
    "a4fa3c566d954dfd939d8fba94f0ecf05c675c02411ac4732ea74da1c9d4c368",
    "v0_chest_render",
    "docs/RQ3_chest.html",
    "de4bf82e03978c9a1b7747107dba3345f6f011e96bca3f77eea2f57e4fc4991e",
    "v0_near_eye_source",
    "RQ3.qmd",
    "dd5b8fedc0205006af2caff74c61da485d9589f37530c91bf45786120b7d5ae2",
    "v0_chest_source",
    "RQ3_chest.qmd",
    "e0b91d924e1e1e3241ad51a61dee402976aead0ac203d44371e2f10fe5f1047b",
    "v0_near_eye_metrics",
    "data/metrics_glasses.RData",
    "9595cb7c574672cf2c8ff89ac3d227f3f7ff11eca57776609e19599561b2d441",
    "v0_chest_metrics",
    "data/metrics_chest.RData",
    "4498d677a8fc7d47168ab2f03731f2dc67b419102b7c818305925273d57c818c"
  ) |>
    dplyr::mutate(absolute_path = file.path(root, .data$path))
}

h10_approval_registry <- function() {
  tibble::tribble(
    ~decision_id,
    ~disposition,
    "H10-G1",
    "Four separate 17-member BH families per placement",
    "H10-G2",
    "Site-adjusted common associations are primary estimands",
    "H10-G3",
    paste0(
      "Final shared response package; pre-sleep TBT10 amended to ",
      "Gaussian identity before fitting"
    ),
    "H10-G4",
    "Participant random intercept for participant-day outcomes",
    "H10-G5",
    "Age per decade; measured biological sex Male then Female",
    "H10-G6",
    "Near-eye primary and chest complementary without pooling",
    "H10-G7",
    "Gap-timing-unaware and common-key sensitivities",
    "H10-G8",
    "Declared metric and preregistered-exclusion sensitivities",
    "H10-G9",
    "Explicit diagnostic acceptance classification",
    "H10-G10",
    "Model-based 95% confidence intervals; no ungated bootstrap",
    "H10-G11",
    "Non-selective site-specific interaction summaries",
    "H10-G12",
    "Paired participant-level IS and IV unavailable",
    "H10-G13",
    paste0(
      "Current shared pins after METRIC-010/FIND-049 and METRIC-011; ",
      "remaining PREP-003/FIND-044 qualification is state-support-only"
    )
  ) |>
    dplyr::mutate(
      approved = TRUE,
      approval_date = as.Date("2026-08-07")
    )
}

h10_validate_contract <- function() {
  metrics <- h10_metric_registry()
  comparisons <- h10_comparison_registry()
  approvals <- h10_approval_registry()
  if (
    nrow(metrics) != 17L ||
      !identical(metrics$metric_order, seq_len(17L)) ||
      anyDuplicated(metrics$metric_id)
  ) {
    h10_abort("H10 requires 17 ordered, unique metrics")
  }
  if (
    !all(metrics$analysis_unit %in% c("participant", "participant_day")) ||
      !all(metrics$response_family %in% c("gaussian", "tweedie_log"))
  ) {
    h10_abort("H10 metric registry contains an unsupported model contract")
  }
  if (
    nrow(comparisons) != 4L ||
      any(comparisons$planned_n != 17L) ||
      anyDuplicated(comparisons$comparison_id)
  ) {
    h10_abort("H10 requires four unique 17-member comparison families")
  }
  if (nrow(approvals) != 13L || any(!approvals$approved)) {
    h10_abort("H10 requires all 13 Stage 1 decisions to be approved")
  }
  invisible(TRUE)
}
