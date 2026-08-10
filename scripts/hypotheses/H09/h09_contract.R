# Define the author-approved H09 Stage 2 analysis contract.

h09_abort <- function(message, ..., call. = FALSE) {
  stop(sprintf(message, ...), call. = call.)
}

h09_score_contract <- function() {
  list(
    mctq_center_hour = 4.1135842985834801,
    meq_center_score = 52.86021505376344,
    mctq_field = "msf_sc",
    meq_field = "meq",
    participants = 186L,
    mctq_missing = 1L,
    meq_missing = 0L,
    author_decision = paste(
      "H09-001 explicitly accepts the pinned upstream aggregate calculated",
      "fields msf_sc and meq without claiming item-level reconstruction"
    )
  )
}

h09_metric_registry <- function() {
  tibble::tribble(
    ~metric_order, ~metric_id, ~manuscript_name, ~abbreviation,
    ~source_column, ~analysis_branch, ~primary_family_member,
    1L, "m10_midpoint", "Midpoint of the brightest 10 hours",
    "M10 midpoint", "m10_hour", "registered", TRUE,
    2L, "l10_midpoint", "Midpoint of the darkest 10 hours",
    "L10 midpoint", "l10_hour", "registered", TRUE,
    3L, "first_timing_above_250",
    "First light timing above 250 lx melEDI", "First >250",
    "first_hour", "registered", TRUE,
    4L, "last_timing_above_250",
    "Last light timing above 250 lx melEDI", "Last >250",
    "last_hour", "registered", TRUE,
    5L, "longest_period_midpoint",
    "Midpoint of the longest continuous period above 250 lx melEDI",
    "Longest-period midpoint", "longest_midpoint_exact_hour",
    "registered", TRUE,
    6L, "mean_timing_above_250",
    "Mean timing of exposure above 250 lx melEDI", "Mean >250",
    "mean_hour", "adapted_mean_timing_sensitivity", FALSE
  ) |>
    dplyr::mutate(
      analysis_unit = "participant_day",
      display_unit = "local clock hour",
      response_family = "gaussian",
      response_link = "identity",
      interval_method = "Wald normal 95% confidence interval",
      value_definition = dplyr::case_when(
        .data$metric_id == "m10_midpoint" ~
          "Local midpoint of the brightest supported 10 hours",
        .data$metric_id == "l10_midpoint" ~ paste(
          "Local midpoint of the darkest supported 10 hours; strict",
          ">16:00 values shifted by -24 hours"
        ),
        .data$metric_id == "first_timing_above_250" ~
          "First supported local timing above 250 lx melEDI",
        .data$metric_id == "last_timing_above_250" ~
          "Last supported local timing above 250 lx melEDI",
        .data$metric_id == "longest_period_midpoint" ~ paste(
          "Local midpoint of the selected longest continuous period above",
          "250 lx melEDI, restricted to exact-identifiable periods"
        ),
        TRUE ~ paste(
          "Duration-weighted mean local timing across supported exposure",
          "above 250 lx melEDI"
        )
      )
    )
}

h09_predictor_registry <- function() {
  tibble::tribble(
    ~instrument_id, ~instrument_name, ~predictor_column, ~centered_column,
    ~effect_unit, ~effect_direction, ~main_family, ~interaction_family,
    "MCTQ", "MCTQ MSFsc", "mctq_hour", "mctq_hour_centered",
    "1 hour", "later corrected midsleep", "H09-F1-MCTQ-main",
    "H09-F3-MCTQ-interaction",
    "MEQ", "MEQ", "meq_score", "meq_10_centered",
    "10 score points", "greater morning preference", "H09-F2-MEQ-main",
    "H09-F4-MEQ-interaction"
  )
}

h09_formula_set <- function(
  instrument_id = c("MCTQ", "MEQ"),
  kind = c("participant_day", "photoperiod", "participant", "temporal")
) {
  instrument_id <- match.arg(instrument_id)
  kind <- match.arg(kind)
  predictor <- if (instrument_id == "MCTQ") {
    "mctq_hour_centered"
  } else {
    "meq_10_centered"
  }
  if (kind == "participant_day") {
    return(list(
      M0_site_only = stats::as.formula(
        "timing_hour ~ site + (1 | site:Id)"
      ),
      M1_main = stats::as.formula(sprintf(
        "timing_hour ~ site + %s + (1 | site:Id)", predictor
      )),
      M2_interaction = stats::as.formula(sprintf(
        "timing_hour ~ site * %s + (1 | site:Id)", predictor
      )),
      D_spline = stats::as.formula(sprintf(
        paste0(
          "timing_hour ~ site + splines::ns(%s, df = 3) + ",
          "(1 | site:Id)"
        ),
        predictor
      ))
    ))
  }
  if (kind == "photoperiod") {
    return(list(
      P0_site_photoperiod = stats::as.formula(paste0(
        "timing_hour ~ site + photoperiod_within_site + ",
        "(1 | site:Id)"
      )),
      P1_main = stats::as.formula(sprintf(
        paste0(
          "timing_hour ~ site + photoperiod_within_site + %s + ",
          "(1 | site:Id)"
        ),
        predictor
      )),
      P2_interaction = stats::as.formula(sprintf(
        paste0(
          "timing_hour ~ site * %s + photoperiod_within_site + ",
          "(1 | site:Id)"
        ),
        predictor
      ))
    ))
  }
  if (kind == "participant") {
    return(list(
      S0_site_only = stats::as.formula(
        "participant_mean_timing_hour ~ site"
      ),
      S1_main = stats::as.formula(sprintf(
        "participant_mean_timing_hour ~ site + %s", predictor
      )),
      S2_interaction = stats::as.formula(sprintf(
        "participant_mean_timing_hour ~ site * %s", predictor
      ))
    ))
  }
  list(
    fixed = stats::as.formula(sprintf(
      "timing_hour ~ site + %s", predictor
    )),
    random = stats::as.formula("~ 1 | participant_key"),
    correlation = stats::as.formula(
      "~ elapsed_day | participant_key"
    )
  )
}

h09_v0_formula_set <- function() {
  list(
    H9_1 = stats::as.formula(
      "timing_hour ~ site * mctq_hour + (1 | Id)"
    ),
    H9_0 = stats::as.formula(
      "timing_hour ~ site + (1 | Id)"
    ),
    H9_00 = stats::as.formula(
      "timing_hour ~ 1 + (1 | Id)"
    ),
    H9_ni = stats::as.formula(
      "timing_hour ~ site + mctq_hour + (1 | Id)"
    ),
    H9_ns = stats::as.formula(
      "timing_hour ~ mctq_hour + (1 | Id)"
    )
  )
}

h09_formula_registry <- function() {
  formula_rows <- function(formulas, analysis_kind, instrument) {
    tibble::tibble(
      analysis_kind = analysis_kind,
      instrument = instrument,
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
      h09_formula_set("MCTQ", "participant_day"),
      "approved_participant_day", "MCTQ"
    ),
    formula_rows(
      h09_formula_set("MEQ", "participant_day"),
      "approved_participant_day", "MEQ"
    ),
    formula_rows(
      h09_formula_set("MCTQ", "photoperiod"),
      "photoperiod_sensitivity", "MCTQ"
    ),
    formula_rows(
      h09_formula_set("MEQ", "photoperiod"),
      "photoperiod_sensitivity", "MEQ"
    ),
    formula_rows(
      h09_formula_set("MCTQ", "participant"),
      "participant_summary_sensitivity", "MCTQ"
    ),
    formula_rows(
      h09_formula_set("MEQ", "participant"),
      "participant_summary_sensitivity", "MEQ"
    ),
    formula_rows(
      h09_formula_set("MCTQ", "temporal"),
      "continuous_time_ar1_sensitivity", "MCTQ"
    ),
    formula_rows(
      h09_formula_set("MEQ", "temporal"),
      "continuous_time_ar1_sensitivity", "MEQ"
    ),
    formula_rows(h09_v0_formula_set(), "v0_reconstruction", "MCTQ")
  )
}

h09_run_registry <- function() {
  tibble::tribble(
    ~run_order, ~run_id, ~data_scenario_id, ~reader_scenario, ~placement,
    ~placement_label, ~sample_scenario, ~analytical_role, ~family_enabled,
    1L, "primary__glasses__all_available", "primary", "Primary dataset",
    "glasses", "Near eye", "all_available", "primary_near_eye", TRUE,
    2L, "primary__chest__all_available", "primary", "Primary dataset",
    "chest", "Chest", "all_available", "complementary_chest", TRUE,
    3L, "primary__glasses__paired_common", "primary", "Primary dataset",
    "glasses", "Near eye", "paired_common",
    "paired_placement_sensitivity", TRUE,
    4L, "primary__chest__paired_common", "primary", "Primary dataset",
    "chest", "Chest", "paired_common",
    "paired_placement_sensitivity", TRUE,
    5L, "gap__glasses__all_available", "gap_timing_unaware",
    "Gap-timing-unaware dataset", "glasses", "Near eye", "all_available",
    "data_preparation_sensitivity", TRUE,
    6L, "gap__chest__all_available", "gap_timing_unaware",
    "Gap-timing-unaware dataset", "chest", "Chest", "all_available",
    "complementary_data_preparation_sensitivity", TRUE,
    7L, "primary__glasses__gap_common", "primary", "Primary dataset",
    "glasses", "Near eye", "gap_common", "exact_common_data_sensitivity",
    TRUE,
    8L, "gap__glasses__gap_common", "gap_timing_unaware",
    "Gap-timing-unaware dataset", "glasses", "Near eye", "gap_common",
    "exact_common_data_sensitivity", TRUE,
    9L, "primary__chest__gap_common", "primary", "Primary dataset",
    "chest", "Chest", "gap_common", "exact_common_data_sensitivity", TRUE,
    10L, "gap__chest__gap_common", "gap_timing_unaware",
    "Gap-timing-unaware dataset", "chest", "Chest", "gap_common",
    "exact_common_data_sensitivity", TRUE
  )
}

h09_family_registry <- function() {
  predictors <- h09_predictor_registry()
  dplyr::bind_rows(lapply(seq_len(nrow(predictors)), function(index) {
    row <- predictors[index, ]
    tibble::tibble(
      family_id = c(row$main_family, row$interaction_family),
      instrument_id = row$instrument_id,
      test_kind = c("main", "interaction"),
      comparison = c("M0 versus M1", "M1 versus M2"),
      planned_n = 5L,
      adjustment_method = "BH",
      decision_rule = "BH-adjusted p < 0.05"
    )
  }))
}

h09_diagnostic_thresholds <- function() {
  tibble::tribble(
    ~diagnostic, ~acceptable_rule, ~threshold,
    "optimizer_gradient", "maximum absolute raw gradient < 0.002", 0.002,
    "singularity", "isSingular(tolerance = 1e-4) is false", 1e-4,
    "qq_correlation", "normal-score Q-Q correlation >= 0.970", 0.970,
    "residual_skewness", "absolute residual skewness <= 2", 2,
    "residual_excess_kurtosis", "absolute excess kurtosis <= 7", 7,
    "standardized_residual", "maximum absolute standardized residual <= 5", 5,
    "heteroscedasticity_fitted", "absolute Spearman correlation <= 0.20", 0.20,
    "heteroscedasticity_site", "largest/smallest site residual SD <= 2.5", 2.5,
    "temporal_lag1", "absolute adjacent-day residual correlation <= 0.20 or stable AR(1) correction", 0.20,
    "linearity_aic", "spline improvement < 4 AIC units unless curvature < 0.25 h", 4,
    "linearity_departure", "maximum anchored spline departure < 0.25 h unless AIC improvement < 4", 0.25,
    "influence_dfbeta", "absolute participant DFBETA <= 2/sqrt(participants) or stable deletion refit", NA_real_,
    "material_effect_change", "absolute slope change < 0.25 local clock hours", 0.25
  )
}

h09_input_contract <- function(root) {
  tibble::tribble(
    ~input_role, ~path, ~expected_sha256, ~expected_rows, ~use,
    "metric_manifest", "artifacts/12_manifests/metric_artifacts.csv",
    "6ec3185620d921e1f81b8464e850249613deb823988187d58794b3471303f4e8",
    NA_integer_, "PREP06-BASE-002 current metric identity",
    "base_manifest", "artifacts/12_manifests/base_model_data_artifacts.csv",
    "142d1044dd7e6a566e45e3a5c56033b1e8251e100c0d7c7523564c824950a0e4",
    NA_integer_, "PREP06-BASE-002 current base identity and bundle",
    "primary_near_eye_context",
    "artifacts/06_model_data/base/metrics_glasses_participant_day_context.rds",
    "2326428dde8d0be1eb1b8d7e84ea3d2eac12db5e595d4966955d546fce27d4fc",
    816L, "PREP06-BASE-002 direct near-eye identity",
    "primary_chest_context",
    "artifacts/06_model_data/base/metrics_chest_participant_day_context.rds",
    "f8106f1c5ecaf7488a59f94f11bee472356be6c39d72564b1e6de3b4c3a5d8d3",
    902L, "PREP06-BASE-002 direct chest identity",
    "primary_near_eye_enriched",
    "artifacts/06_model_data/base/metrics_glasses_participant_day_enriched.rds",
    "fc80f8a2a94a447c5470db36c1ad1915868463501f04e9db3218f8156efc59d2",
    816L, "Approved enriched near-eye H09 fields",
    "primary_chest_enriched",
    "artifacts/06_model_data/base/metrics_chest_participant_day_enriched.rds",
    "ce81c159fe018f35bec9bff44c9cd12f91fd4be1ea2696c56a8e91e628a9e2d3",
    902L, "Approved enriched chest H09 fields",
    "normalized_chronotype",
    "artifacts/06_model_data/normalized_inputs/chronotype.rds",
    "9266c61e265d445f60ea3862a68c69a24af3f17b3773ff57cf338939fd67eeb6",
    186L, "Pinned aggregate msf_sc and meq fields accepted by H09-001",
    "gap_timing_unaware_metrics",
    paste0(
      "artifacts/06_model_data/scenarios/manuscript_prepared_data/",
      "participant_day_metrics.rds"
    ),
    "28266064c6213eae6046ec6469d0dae39529f56e60933dcd581cf96c8590e1a4",
    NA_integer_, "Approved prepared-data sensitivity",
    "gap_manifest",
    "artifacts/12_manifests/manuscript_prepared_data_artifacts.csv",
    "af74cc9fa36e426222d9b5f2328e2261c00b14436feb8d86fbf137d0ff313267",
    NA_integer_, "Gap-timing-unaware provenance",
    "site_display_registry", "config/site_display_registry.csv",
    "3d669d459ecc27d3154bbb5ff5b0d64cb510805d486b45264443228c44a6d809",
    NA_integer_, "Submitted site names, order, and colours",
    "metric_display_registry", "config/metric_display_registry.csv",
    "6c0adc3ca061ac49591d71243dd7ff0693311eb1f499836cf52c2742328b8154",
    NA_integer_, "Manuscript metric display names",
    "v0_near_eye_metrics", "data/metrics_glasses.RData",
    "9595cb7c574672cf2c8ff89ac3d227f3f7ff11eca57776609e19599561b2d441",
    NA_integer_, "V0 reconstruction",
    "v0_chest_metrics", "data/metrics_chest.RData",
    "4498d677a8fc7d47168ab2f03731f2dc67b419102b7c818305925273d57c818c",
    NA_integer_, "V0 reconstruction",
    "v0_near_eye_source", "RQ3.qmd",
    "dd5b8fedc0205006af2caff74c61da485d9589f37530c91bf45786120b7d5ae2",
    NA_integer_, "V0 formulas, reporting, table, and figure",
    "v0_chest_source", "RQ3_chest.qmd",
    "e0b91d924e1e1e3241ad51a61dee402976aead0ac203d44371e2f10fe5f1047b",
    NA_integer_, "V0 chest formulas, reporting, table, and figure",
    "v0_helper", "scripts/RQ3_specific.R",
    "1ded47f7f4ed69ff17998cfc192194ce8732a873d375e0f7000a76344bb38e83",
    NA_integer_, "V0 table helper"
  ) |>
    dplyr::mutate(absolute_path = file.path(root, .data$path))
}

h09_approval_registry <- function() {
  tibble::tribble(
    ~gate_id, ~decision, ~approved,
    "H09-G1", "MCTQ and MEQ remain separate registered analyses", TRUE,
    "H09-G2", "Registered exact longest-period midpoint is the fifth primary outcome; mean timing is sensitivity", TRUE,
    "H09-G3", "Registered midpoint is restricted to exact-identifiable selected periods", TRUE,
    "H09-G4", "Pinned aggregate calculated fields msf_sc and meq explicitly accepted", TRUE,
    "H09-G5", "Site-only versus site-plus-chronotype main test; separate interaction test", TRUE,
    "H09-G6", "Fixed scaling, centring, site order, and sum contrasts", TRUE,
    "H09-G7", "Four separate five-member BH families", TRUE,
    "H09-G8", "Site-specific trends descriptive; H09-F5 disabled", TRUE,
    "H09-G9", "Fixed linear clock rules and L10 cut sensitivity", TRUE,
    "H09-G10", "Site retained; within-site photoperiod is sensitivity only", TRUE,
    "H09-G11", "Near-eye primary, chest complementary, exact paired/common, no pooling", TRUE,
    "H09-G12", "Approved dependence and stability checks", TRUE,
    "H09-G13", "Explicit acceptable/not-acceptable diagnostic registry", TRUE,
    "H09-G14", "Raw and adjusted p-values follow REPORT-008", TRUE,
    "H09-G15", "V0 recreation and paired figure source data", TRUE,
    "H09-G16", "Production resampling remains pilot-gated", TRUE
  )
}

h09_validate_contract <- function() {
  metrics <- h09_metric_registry()
  predictors <- h09_predictor_registry()
  families <- h09_family_registry()
  approvals <- h09_approval_registry()
  stopifnot(
    nrow(metrics) == 6L,
    sum(metrics$primary_family_member) == 5L,
    metrics$metric_id[metrics$metric_order == 5L] ==
      "longest_period_midpoint",
    nrow(predictors) == 2L,
    nrow(families) == 4L,
    all(families$planned_n == 5L),
    nrow(approvals) == 16L,
    all(approvals$approved),
    !any(grepl(
      "temperature|weather",
      h09_formula_registry()$formula,
      ignore.case = TRUE
    ))
  )
  invisible(TRUE)
}
