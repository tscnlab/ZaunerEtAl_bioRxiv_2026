h08_abort <- function(message, ..., call. = FALSE) {
  stop(sprintf(message, ...), call. = call.)
}

h08_score_contract <- function(vlsq) {
  required <- c("site", "Id", "VLSQ8")
  if (!all(required %in% names(vlsq)) || nrow(vlsq) < 2L ||
      anyDuplicated(vlsq[c("site", "Id")]) ||
      any(!is.finite(vlsq$VLSQ8))) {
    h08_abort("VLSQ-8 requires one finite score per participant and site")
  }
  list(
    score_name = "VLSQ8",
    score_label = "VLSQ-8",
    scoring_rule = "Stored score = sum of eight ordered 1--5 item codes + 5",
    center = mean(vlsq$VLSQ8),
    participant_sd = stats::sd(vlsq$VLSQ8),
    observed_min = min(vlsq$VLSQ8),
    observed_max = max(vlsq$VLSQ8),
    participants = nrow(vlsq)
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
    ~source_metric_alias,
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
      "participant_day"
    ),
    formula_rows(h08_formula_set("photoperiod"), "photoperiod_sensitivity"),
    formula_rows(
      h08_formula_set("participant"),
      "participant_summary_sensitivity"
    )
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
 tibble::tribble(~input_role, ~path,
"normalized_vlsq8", "results/intermediate/model_data/normalized_inputs/vlsq8.rds",
"primary_near_eye_metrics", "results/intermediate/model_data/base/metrics_glasses_participant_day_enriched.rds",
"primary_chest_metrics", "results/intermediate/model_data/base/metrics_chest_participant_day_enriched.rds",
"gap_timing_unaware_metrics", "results/intermediate/model_data/scenarios/alternative_preprocessing/participant_day_metrics.rds",
"primary_support_provenance", "results/intermediate/model_data/H01.rds",
"gap_support_provenance", "results/intermediate/model_data/H01/scenarios/alternative_preprocessing/H01.rds") |> dplyr::mutate(absolute_path = file.path(root,.data$path))
}
