# Define the author-approved H08 Stage 2 analysis contract.

h08_abort <- function(message, ..., call. = FALSE) {
  stop(sprintf(message, ...), call. = call.)
}

h08_score_contract <- function() {
  list(
    score_name = "VLSQ8",
    score_label = "VLSQ-8",
    scoring_rule = "Stored score = sum of eight ordered 1--5 item codes + 5",
    center = 21.5978260869565,
    participant_sd = 5.53984036898639,
    observed_min = 13,
    observed_max = 39,
    participants = 184L
  )
}

h08_metric_registry <- function() {
  tibble::tribble(
    ~metric_order,
    ~metric_id,
    ~manuscript_name,
    ~abbreviation,
    ~manuscript_category,
    ~display_unit,
    ~source_column,
    ~v0_name,
    ~response_family,
    ~response_transform,
    ~effect_scale,
    ~lower_bound,
    ~upper_bound,
    ~audit_upper_threshold,
    ~diagnostic_note,
    1L,
    "daily_geometric_mean_medi",
    "Mean melEDI",
    "Mean",
    "level-based",
    "lx",
    "daily_geometric_mean_medi_lx",
    "Mean",
    "gaussian",
    "log10_offset_0.1",
    "ratio",
    0,
    NA_real_,
    NA_real_,
    "Offset, influence, and upper-tail checks",
    2L,
    "m10_mean_medi",
    "Brightest 10 h mean",
    "M10mean",
    "level-based",
    "lx",
    "m10_mean_medi_lx",
    "brightest_10h_mean",
    "gaussian",
    "log10_offset_0.1",
    "ratio",
    0,
    NA_real_,
    NA_real_,
    "Influence and upper-tail checks",
    3L,
    "l10_mean_medi",
    "Darkest 10 h mean",
    "L10mean",
    "level-based",
    "lx",
    "l10_mean_medi_lx",
    "darkest_10h_mean",
    "gaussian",
    "log10_offset_0.1",
    "ratio",
    0,
    NA_real_,
    NA_real_,
    "High-risk exact-zero and residual checks",
    4L,
    "duration_above_1000",
    "Time above 1,000 lx melEDI",
    "TAT1000",
    "duration-based",
    "h",
    "duration_above_1000_h",
    "duration_above_1000",
    "tweedie_log",
    "identity",
    "ratio",
    0,
    24,
    NA_real_,
    "Zero mass, dispersion, tail, and 24-hour prediction checks",
    5L,
    "duration_above_250_wake",
    "Time above 250 lx melEDI during wake",
    "TAT250",
    "duration-based",
    "h",
    "duration_above_250_wake_h",
    "duration_above_250_wake",
    "tweedie_log",
    "identity",
    "ratio",
    0,
    NA_real_,
    NA_real_,
    "Zero mass, tail, and waking-duration checks",
    6L,
    "duration_below_10_pre_sleep",
    "Time below 10 lx melEDI before sleep",
    "TBT10",
    "duration-based",
    "h",
    "duration_below_10_pre_sleep_h",
    "duration_below_10_pre-sleep",
    "gaussian",
    "identity",
    "difference",
    0,
    24,
    6,
    "Identity Gaussian; calendar-day cumulative duration and six-hour audit",
    7L,
    "duration_below_1_sleep_environment",
    "Time below 1 lx melEDI during sleep",
    "TBT1",
    "duration-based",
    "h",
    "duration_below_1_sleep_environment_h",
    "duration_below_1_sleep",
    "tweedie_log",
    "identity",
    "ratio",
    0,
    NA_real_,
    NA_real_,
    "Distribution and sleep-window prediction checks",
    8L,
    "longest_bout_above_250",
    "Longest continuous period above 250 lx melEDI",
    "PAT250",
    "duration-based",
    "h",
    "longest_bout_above_250_h",
    "period_above_250",
    "gaussian",
    "log10_offset_0.1",
    "ratio",
    0,
    24,
    NA_real_,
    "Observed lower bound; mandatory exactly-identifiable-only sensitivity",
    9L,
    "dose_time_sensitive_corrected_medi",
    "melEDI dose",
    "Dose",
    "exposure-history-based",
    "lx·h",
    "dose_corrected_medi_lx_h",
    "dose",
    "gaussian",
    "log10_offset_0.1",
    "ratio",
    0,
    NA_real_,
    NA_real_,
    "Time-sensitive corrected dose; observed-dose common-sample sensitivity"
  ) |>
    dplyr::mutate(
      analysis_unit = "participant_day",
      primary_value_definition = dplyr::case_when(
        .data$metric_id == "daily_geometric_mean_medi" ~
          "Supported hybrid-day geometric mean; no coverage scaling",
        .data$metric_id == "m10_mean_medi" ~
          "Brightest supported 10 h geometric mean",
        .data$metric_id == "l10_mean_medi" ~
          "Darkest supported midnight-wrapping 10 h geometric mean",
        .data$metric_id == "duration_above_1000" ~
          "Actual supported time above 1,000 lx melEDI",
        .data$metric_id == "duration_above_250_wake" ~
          "Actual supported waking near-eye/chest time above 250 lx melEDI",
        .data$metric_id == "duration_below_10_pre_sleep" ~
          "Calendar-day cumulative supported pre-sleep time below 10 lx melEDI",
        .data$metric_id == "duration_below_1_sleep_environment" ~
          "Supported bedside sleep-environment time below 1 lx melEDI",
        .data$metric_id == "longest_bout_above_250" ~
          "Observed lower bound for the longest continuous period above 250 lx melEDI",
        .data$metric_id == "dose_time_sensitive_corrected_medi" ~
          "Time-sensitive corrected melEDI dose"
      )
    )
}

h08_formula_set <- function(
  kind = c("participant_day", "photoperiod", "participant")
) {
  kind <- match.arg(kind)
  if (kind == "participant_day") {
    return(list(
      site_only = stats::as.formula(
        "response_value ~ site + (1 | site:Id)"
      ),
      additive = stats::as.formula(
        "response_value ~ site + VLSQ8_c + (1 | site:Id)"
      ),
      interaction = stats::as.formula(
        "response_value ~ site * VLSQ8_c + (1 | site:Id)"
      )
    ))
  }
  if (kind == "photoperiod") {
    return(list(
      site_only = stats::as.formula(
        "response_value ~ site + photoperiod_c + (1 | site:Id)"
      ),
      additive = stats::as.formula(
        paste0(
          "response_value ~ site + photoperiod_c + VLSQ8_c + ",
          "(1 | site:Id)"
        )
      ),
      interaction = stats::as.formula(
        paste0(
          "response_value ~ site * VLSQ8_c + photoperiod_c + ",
          "(1 | site:Id)"
        )
      )
    ))
  }
  list(
    site_only = stats::as.formula("participant_response ~ site"),
    additive = stats::as.formula(
      "participant_response ~ site + VLSQ8_c"
    ),
    interaction = stats::as.formula(
      "participant_response ~ site * VLSQ8_c"
    )
  )
}

h08_v0_formula_set <- function() {
  list(
    full = stats::as.formula(
      "response_value ~ site * VLSQ8 + (1 | Id)"
    ),
    site_only = stats::as.formula(
      "response_value ~ site + (1 | Id)"
    ),
    additive = stats::as.formula(
      "response_value ~ site + VLSQ8 + (1 | Id)"
    ),
    vlsq_only = stats::as.formula(
      "response_value ~ VLSQ8 + (1 | Id)"
    )
  )
}

h08_formula_registry <- function() {
  formula_rows <- function(formulas, analysis_kind) {
    tibble::tibble(
      analysis_kind = analysis_kind,
      formula_id = names(formulas),
      formula = vapply(
        formulas,
        function(x) paste(deparse(x), collapse = " "),
        character(1)
      )
    )
  }
  dplyr::bind_rows(
    formula_rows(
      h08_formula_set("participant_day"),
      "approved_participant_day"
    ),
    formula_rows(h08_formula_set("photoperiod"), "photoperiod_sensitivity"),
    formula_rows(
      h08_formula_set("participant"),
      "participant_summary_sensitivity"
    ),
    formula_rows(h08_v0_formula_set(), "v0_reconstruction")
  )
}

h08_run_registry <- function() {
  tibble::tribble(
    ~run_order,
    ~run_id,
    ~data_scenario_id,
    ~reader_scenario,
    ~placement,
    ~placement_label,
    ~sample_scenario,
    ~analytical_role,
    ~inferential_run,
    1L,
    "main__glasses__all_available",
    "main",
    "Primary dataset",
    "glasses",
    "Near eye",
    "all_available",
    "primary_near_eye",
    TRUE,
    2L,
    "main__chest__all_available",
    "main",
    "Primary dataset",
    "chest",
    "Chest",
    "all_available",
    "complementary_chest",
    TRUE,
    3L,
    "main__glasses__paired_common_sample",
    "main",
    "Primary dataset",
    "glasses",
    "Near eye",
    "paired_common_sample",
    "paired_placement_sensitivity",
    FALSE,
    4L,
    "main__chest__paired_common_sample",
    "main",
    "Primary dataset",
    "chest",
    "Chest",
    "paired_common_sample",
    "paired_placement_sensitivity",
    FALSE,
    5L,
    "gap_timing_unaware__glasses__all_available",
    "gap_timing_unaware",
    "Gap-timing-unaware dataset",
    "glasses",
    "Near eye",
    "all_available",
    "data_preparation_sensitivity",
    TRUE,
    6L,
    "gap_timing_unaware__chest__all_available",
    "gap_timing_unaware",
    "Gap-timing-unaware dataset",
    "chest",
    "Chest",
    "all_available",
    "complementary_data_preparation_sensitivity",
    TRUE,
    7L,
    "gap_timing_unaware__glasses__paired_common_sample",
    "gap_timing_unaware",
    "Gap-timing-unaware dataset",
    "glasses",
    "Near eye",
    "paired_common_sample",
    "paired_placement_sensitivity",
    FALSE,
    8L,
    "gap_timing_unaware__chest__paired_common_sample",
    "gap_timing_unaware",
    "Gap-timing-unaware dataset",
    "chest",
    "Chest",
    "paired_common_sample",
    "paired_placement_sensitivity",
    FALSE,
    9L,
    "main__glasses__main_gap_common_sample",
    "main",
    "Primary dataset",
    "glasses",
    "Near eye",
    "main_gap_common_sample",
    "data_preparation_common_sample",
    FALSE,
    10L,
    "main__chest__main_gap_common_sample",
    "main",
    "Primary dataset",
    "chest",
    "Chest",
    "main_gap_common_sample",
    "data_preparation_common_sample",
    FALSE,
    11L,
    "gap_timing_unaware__glasses__main_gap_common_sample",
    "gap_timing_unaware",
    "Gap-timing-unaware dataset",
    "glasses",
    "Near eye",
    "main_gap_common_sample",
    "data_preparation_common_sample",
    FALSE,
    12L,
    "gap_timing_unaware__chest__main_gap_common_sample",
    "gap_timing_unaware",
    "Gap-timing-unaware dataset",
    "chest",
    "Chest",
    "main_gap_common_sample",
    "data_preparation_common_sample",
    FALSE
  )
}

h08_family_registry <- function() {
  tibble::tribble(
    ~family_id,
    ~run_id,
    ~comparison_id,
    ~planned_n,
    ~role,
    "H08-F1-main-near-eye-average",
    "main__glasses__all_available",
    "average_vlsq",
    9L,
    "Primary decision family",
    "H08-F2-main-near-eye-heterogeneity",
    "main__glasses__all_available",
    "site_heterogeneity",
    9L,
    "Registered secondary family",
    "H08-C1-main-chest-average",
    "main__chest__all_available",
    "average_vlsq",
    9L,
    "Complementary family",
    "H08-C2-main-chest-heterogeneity",
    "main__chest__all_available",
    "site_heterogeneity",
    9L,
    "Complementary family",
    "H08-G1-gap-near-eye-average",
    "gap_timing_unaware__glasses__all_available",
    "average_vlsq",
    9L,
    "Sensitivity family",
    "H08-G2-gap-near-eye-heterogeneity",
    "gap_timing_unaware__glasses__all_available",
    "site_heterogeneity",
    9L,
    "Sensitivity family",
    "H08-GC1-gap-chest-average",
    "gap_timing_unaware__chest__all_available",
    "average_vlsq",
    9L,
    "Complementary sensitivity family",
    "H08-GC2-gap-chest-heterogeneity",
    "gap_timing_unaware__chest__all_available",
    "site_heterogeneity",
    9L,
    "Complementary sensitivity family"
  ) |>
    dplyr::mutate(multiplicity_method = "BH")
}

h08_sensitivity_registry <- function() {
  tibble::tribble(
    ~sensitivity_order,
    ~sensitivity_id,
    ~change,
    ~inferential_role,
    1L,
    "primary_near_eye",
    "None",
    "Primary",
    2L,
    "complementary_chest",
    "Placement only",
    "Complementary",
    3L,
    "paired_common_placement",
    "Restrict both placements to identical eight-site participant-days",
    "Placement concordance",
    4L,
    "gap_timing_unaware",
    "Prepared metric values and available days",
    "Data-preparation sensitivity",
    5L,
    "main_gap_common_sample",
    "Restrict both preparation scenarios to identical participant-days",
    "Data-preparation common-sample sensitivity",
    6L,
    "photoperiod_adjusted",
    "Add centred linear photoperiod",
    "Descriptive model sensitivity",
    7L,
    "participant_summary",
    "One natural-scale daily mean per participant before response representation",
    "Unequal-day-weighting sensitivity",
    8L,
    "longest_period_exact_only",
    "Use exactly identifiable periods only",
    "Metric-identifiability sensitivity",
    9L,
    "observed_dose_common_sample",
    "Replace corrected dose by observed dose on corrected-dose rows",
    "Correction-dependence sensitivity",
    10L,
    "leave_one_site_out",
    "Remove one whole site per additive-model refit",
    "Influence diagnostic",
    11L,
    "coverage_and_all_zero_deferred",
    "Rules B/C and all-zero-inclusive metrics are not H08-ready",
    "Deferred prepared-data sensitivity"
  )
}

h08_input_contract <- function(root) {
  tibble::tribble(
    ~input_role,
    ~path,
    ~expected_sha256,
    ~use,
    "metric011_decision",
    "audit/decisions/l10_numerical_zero_normalization.md",
    "23b9f70d1d16f7fd3ebbdbc57aaf78c0a701fe1f9d22bd667d926cd320d40797",
    "Controlling exact-zero normalization and bounded downstream scope",
    "metric011_evidence_manifest",
    "audit/reconciliation/l10_METRIC-011/METRIC-011_evidence_manifest.csv",
    "a37efd3449a8d1a6065d0eb8964bd6cf8b241f1683a26c065ea1a946e23214fb",
    "Independently verified row-level METRIC-011 evidence inventory",
    "metric_artifact_manifest",
    "artifacts/12_manifests/metric_artifacts.csv",
    "028bce108339c1277df4a070597430ea20b49c34c2888f4eef42741c1fe76a5e",
    "Sealed shared metric identities after exact-zero normalization",
    "site_context_manifest",
    "artifacts/12_manifests/site_solar_context_artifacts.csv",
    "c0c6d7f97782c0d880a213050f576213f5d56b3204a02732f6399e7e4aeb8518",
    "Sealed site and photoperiod identities",
    "base_model_manifest",
    "artifacts/12_manifests/base_model_data_artifacts.csv",
    "8344bdc0339a53079bf9eeb7d86de1ad7c15373641c3a0a5a01d040b418895ce",
    "Sealed base-model bundle and participant-day input identities",
    "primary_near_eye_context",
    "artifacts/06_model_data/base/metrics_glasses_participant_day_context.rds",
    "013afe75e9b75b141b4cb48d04111a9e6c688630085a24c9fe07ca3d142a4e9a",
    "Sealed near-eye participant-day context cross-check",
    "primary_chest_context",
    "artifacts/06_model_data/base/metrics_chest_participant_day_context.rds",
    "497466ccd1a35635cca40bb8f9ce51efb97321ab04b42ee1bb76785e466a2057",
    "Sealed chest participant-day context cross-check",
    "normalized_vlsq8",
    "artifacts/06_model_data/normalized_inputs/vlsq8.rds",
    "a261e1e7e99f4484b095be726b3eaeeef98eab000ad1cb7d7a537d04b9a1e0f8",
    "Predictor values and scoring audit",
    "primary_near_eye_metrics",
    "artifacts/06_model_data/base/metrics_glasses_participant_day_enriched.rds",
    "b469fa8f0a743de1cbb1075f78879b84ab602c74cc44fb97da45dee596681f42",
    "Primary participant-day outcomes, photoperiod, and metric variants",
    "primary_chest_metrics",
    "artifacts/06_model_data/base/metrics_chest_participant_day_enriched.rds",
    "10aebeb5dabb53e8f3ee0747b62c31707da344e11b7068261c2ada2a0b7badc9",
    "Complementary participant-day outcomes, photoperiod, and metric variants",
    "gap_timing_unaware_metrics",
    paste0(
      "artifacts/06_model_data/scenarios/manuscript_prepared_data/",
      "participant_day_metrics.rds"
    ),
    "7561b5dd47cb5e23ca94ba59bd57648f11fe492f86af53a566c5c9cf42d932f1",
    "Gap-timing-unaware participant-day outcomes",
    "primary_support_provenance",
    "artifacts/06_model_data/H01.rds",
    "0328fe1a698bc13965feb0b68b03ccf0fd20f32b55d6148635811b0d674e0a00",
    "Metric-specific derivation support and value cross-check only",
    "gap_support_provenance",
    "artifacts/06_model_data/H01/scenarios/manuscript_prepared_data/H01.rds",
    "3c70363fc0468202a431904aa9d9444f2858af2e3add3475a56c872b49a18bd6",
    "Metric-specific derivation support and value cross-check only",
    "v0_near_eye_metrics",
    "data/metrics_glasses.RData",
    "9595cb7c574672cf2c8ff89ac3d227f3f7ff11eca57776609e19599561b2d441",
    "Submitted near-eye H08 reconstruction",
    "v0_chest_metrics",
    "data/metrics_chest.RData",
    "4498d677a8fc7d47168ab2f03731f2dc67b419102b7c818305925273d57c818c",
    "Submitted chest H08 reconstruction",
    "v0_near_eye_render",
    "docs/RQ3.html",
    "a4fa3c566d954dfd939d8fba94f0ecf05c675c02411ac4732ea74da1c9d4c368",
    "Submitted displayed H08 strings",
    "v0_chest_render",
    "docs/RQ3_chest.html",
    "de4bf82e03978c9a1b7747107dba3345f6f011e96bca3f77eea2f57e4fc4991e",
    "Submitted displayed H08 strings",
    "site_display_registry",
    "config/site_display_registry.csv",
    "3d669d459ecc27d3154bbb5ff5b0d64cb510805d486b45264443228c44a6d809",
    "Submitted site names, order, and colours",
    "metric_display_registry",
    "config/metric_display_registry.csv",
    "c82db05a77cc50ce5b9dbd459c90997fa6bb7d87c0b8e880c1bf8186fad06ed0",
    "Manuscript metric names and units",
    "h05_response_contract",
    "artifacts/06_model_data/H05/H05_metric_registry.csv",
    "25a3df408dad73b657ea1ee20631195c93fe33340fafa7250ed6e76727c65bb7",
    "Inherited response-family contract cross-check"
  ) |>
    dplyr::mutate(absolute_path = file.path(root, .data$path))
}

h08_approval_registry <- function() {
  tibble::tribble(
    ~decision_order,
    ~decision_id,
    ~author_disposition,
    1L,
    "H08-G1-vlsq-score",
    "Approved stored VLSQ8 and reconstructed sum(eight 1--5 codes) + 5 provenance",
    2L,
    "H08-G2-score-scaling",
    "Approved centre 21.5978 and participant SD 5.5398; no within-site standardization",
    3L,
    "H08-G3-primary-estimand",
    "Approved site-adjusted additive VLSQ-8 slope as primary",
    4L,
    "H08-G4-heterogeneity",
    "Approved separate secondary site-by-VLSQ-8 interaction test",
    5L,
    "H08-G5-metric-set",
    "Approved exact nine repaired outcomes",
    6L,
    "H08-G6-response-package",
    "Approved current H01/H05 response families, transforms, links, and common gate",
    7L,
    "H08-G7-analysis-unit",
    "Approved participant-day models with participant nested in site and participant-summary sensitivity",
    8L,
    "H08-G8-site-photoperiod",
    "Approved fixed submitted site order and sum contrasts; photoperiod sensitivity only",
    9L,
    "H08-G9-multiplicity",
    "Approved eight complete nine-member BH families; no scalar adjustment",
    10L,
    "H08-G10-placement-samples",
    "Approved near-eye primary, chest complementary, exact paired/common comparisons, and no pooling",
    11L,
    "H08-G11-practical-reporting",
    "Approved raw-point, one-SD, centred contrast, site-slope, and 95% interval reporting",
    12L,
    "H08-G12-sensitivities",
    "Approved fixed Stage 2 sensitivity matrix",
    13L,
    "H08-G13-diagnostics",
    "Approved diagnostic registry, common-family gate, and non-estimable disposition",
    14L,
    "H08-G14-language",
    "Approved association language without physiological or health-effect claims"
  ) |>
    dplyr::mutate(
      approved = TRUE,
      recorded_date = as.Date("2026-08-01")
    )
}

h08_validate_contract <- function() {
  metrics <- h08_metric_registry()
  runs <- h08_run_registry()
  families <- h08_family_registry()
  approvals <- h08_approval_registry()
  if (
    nrow(metrics) != 9L ||
      !identical(metrics$metric_order, seq_len(9L)) ||
      anyDuplicated(metrics$metric_id)
  ) {
    h08_abort("H08 requires nine ordered, unique metrics")
  }
  if (nrow(runs) != 12L || anyDuplicated(runs$run_id)) {
    h08_abort("H08 requires 12 unique exact-sample runs")
  }
  if (
    nrow(families) != 8L ||
      any(families$planned_n != 9L) ||
      anyDuplicated(families$family_id)
  ) {
    h08_abort("H08 requires eight unique nine-member multiplicity families")
  }
  if (nrow(approvals) != 14L || any(!approvals$approved)) {
    h08_abort("H08 requires all 14 Stage 1 decisions to be approved")
  }
  invisible(TRUE)
}
