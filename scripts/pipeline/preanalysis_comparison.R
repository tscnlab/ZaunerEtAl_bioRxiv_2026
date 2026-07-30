# Define pure contracts and summaries for the pre-analysis comparison gate.
#
# Source scripts/pipeline/assertions.R before this file.

preanalysis_placements <- function() {
  c("glasses", "chest")
}

preanalysis_discarded_clock_metric_ids <- function() {
  c(
    "m10_onset",
    "m10_offset",
    "l10_onset",
    "l10_offset"
  )
}

preanalysis_discarded_clock_variable_ids <- function() {
  paste0("light_", preanalysis_discarded_clock_metric_ids())
}

preanalysis_discarded_clock_base_columns <- function() {
  paste0(
    preanalysis_discarded_clock_metric_ids(),
    "_clock_minute"
  )
}

preanalysis_comparison_statuses <- function() {
  c(
    "applicable_field_key_mapping",
    "not_applicable_no_field_key_mapping"
  )
}

preanalysis_metric_crosswalk <- function() {
  metric <- c(
    "interdaily_stability",
    "intradaily_variability",
    "daily_geometric_mean_medi",
    "dose_observed_medi",
    "dose_time_sensitive_corrected_medi",
    "duration_above_1000",
    "duration_above_250_full_day",
    "duration_above_250_wake",
    "duration_below_10_pre_sleep",
    "duration_below_1_sleep_environment",
    "first_timing_above_250",
    "l10_mean_medi",
    "l10_midpoint",
    "last_timing_above_250",
    "longest_bout_above_250",
    "longest_bout_above_250_exact_only_sensitivity",
    "m10_mean_medi",
    "m10_midpoint",
    "mder_ratio_of_integrals",
    "mean_timing_above_250"
  )
  baseline_metric <- c(
    "interdaily_stability",
    "intradaily_variability",
    "Mean",
    "dose",
    NA,
    "duration_above_1000",
    "duration_above_250",
    "duration_above_250_wake",
    "duration_below_10_pre-sleep",
    "duration_below_1_sleep",
    "first_timing_above_250",
    "darkest_10h_mean",
    "darkest_10h_midpoint",
    "last_timing_above_250",
    "period_above_250",
    NA,
    "brightest_10h_mean",
    "brightest_10h_midpoint",
    NA,
    "mean_timing_above_250"
  )
  analysis_unit <- c(
    rep("participant", 2L),
    rep("participant_day", length(metric) - 2L)
  )
  native_unit <- ifelse(
    metric %in%
      c(
        "interdaily_stability",
        "intradaily_variability",
        "mder_ratio_of_integrals"
      ),
    "dimensionless",
    ifelse(
      metric %in%
        c(
          "daily_geometric_mean_medi",
          "l10_mean_medi",
          "m10_mean_medi"
        ),
      "lx",
      ifelse(
        metric %in%
          c(
            "dose_observed_medi",
            "dose_time_sensitive_corrected_medi"
          ),
        "lx_h",
        ifelse(
          grepl("timing|midpoint", metric),
          "clock_minute",
          "h"
        )
      )
    )
  )
  comparison_unit <- native_unit
  clock_metric <- grepl(
    "timing|midpoint|offset|onset",
    metric
  )
  comparison_unit[clock_metric] <- "decimal_hour"
  centered_clock <- metric == "l10_midpoint"
  comparison_unit[centered_clock] <- "centered_decimal_hour"
  canonical_transform <- rep("identity", length(metric))
  canonical_transform[clock_metric] <- "clock_minute_to_decimal_hour"
  canonical_transform[centered_clock] <-
    "clock_minute_to_centered_decimal_hour"
  difference_method <- rep("linear_current_minus_baseline", length(metric))
  baseline_transform <- rep("identity", length(metric))
  status <- ifelse(
    is.na(baseline_metric),
    "not_applicable_no_field_key_mapping",
    "applicable_field_key_mapping"
  )
  non_applicable_reason <- rep(NA_character_, length(metric))
  non_applicable_reason[metric == "dose_time_sensitive_corrected_medi"] <-
    paste(
      "The corrected dose is a new support-profile estimand;",
      "the frozen baseline contains only uncorrected dose."
    )
  non_applicable_reason[
    metric == "longest_bout_above_250_exact_only_sensitivity"
  ] <- paste(
    "The exact-identifiable sensitivity is new and has no distinct",
    "frozen-baseline implementation."
  )
  non_applicable_reason[metric == "mder_ratio_of_integrals"] <- paste(
    "Main-analysis MDER is a ratio of paired-channel integrals;",
    "the manuscript-prepared mean of epoch-wise ratios measures a",
    "different quantity."
  )
  technical_estimand <- gsub("_", " ", metric, fixed = TRUE)
  technical_estimand <- gsub(
    "\\bmedi\\b",
    "melEDI",
    technical_estimand,
    ignore.case = TRUE
  )
  technical_estimand[metric == "daily_geometric_mean_medi"] <-
    "Participant-day zero-aware geometric mean melEDI"
  technical_estimand[metric == "dose_observed_medi"] <-
    "Observed participant-day melEDI integral"
  technical_estimand[metric == "dose_time_sensitive_corrected_medi"] <-
    "Time-sensitive support-profile corrected melEDI integral"
  technical_estimand[metric == "mder_ratio_of_integrals"] <-
    "Ratio of observed paired melEDI and photopic illuminance integrals"

  data.frame(
    variable_order = seq_along(metric),
    variable_id = paste0("light_", metric),
    domain = "light_metric",
    analysis_unit = analysis_unit,
    value_type = "numeric",
    canonical_source = "metric_values_long",
    canonical_variable = metric,
    baseline_source = ifelse(is.na(baseline_metric), NA, "baseline_metrics"),
    baseline_variable = baseline_metric,
    native_unit = native_unit,
    comparison_unit = comparison_unit,
    canonical_transform = canonical_transform,
    baseline_transform = baseline_transform,
    difference_method = difference_method,
    technical_estimand = technical_estimand,
    comparison_status = status,
    non_applicable_reason = non_applicable_reason,
    figure_priority = TRUE,
    stringsAsFactors = FALSE
  )
}

preanalysis_grid_metric_crosswalk <- function() {
  data.frame(
    variable_order = 21:22,
    variable_id = c(
      "light_medi_30_minute_arithmetic_mean",
      "light_medi_one_hour_zero_aware_geometric_mean"
    ),
    domain = "light_metric",
    analysis_unit = c("30_minute", "one_hour"),
    value_type = "numeric",
    canonical_source = c("grid_30_minute", "grid_one_hour"),
    canonical_variable = "metric_value_lx",
    baseline_source = NA_character_,
    baseline_variable = NA_character_,
    native_unit = "lx",
    comparison_unit = "lx",
    canonical_transform = "identity",
    baseline_transform = "identity",
    difference_method = "linear_current_minus_baseline",
    technical_estimand = c(
      "Admissible 30-minute arithmetic mean melEDI",
      "Admissible one-hour zero-aware geometric mean melEDI"
    ),
    comparison_status = "not_applicable_no_field_key_mapping",
    non_applicable_reason = c(
      paste(
        "The frozen participant-hour object is a 30-minute geometric",
        "implementation, not the main-analysis 30-minute arithmetic mean."
      ),
      paste(
        "The manuscript-prepared data have no one-hour zero-aware geometric",
        "implementation on the main-analysis complete clock grid."
      )
    ),
    figure_priority = TRUE,
    stringsAsFactors = FALSE
  )
}

preanalysis_participant_crosswalk <- function() {
  variable <- c(
    "site",
    "age",
    "sex",
    "gender",
    "employment_status",
    "meq_type",
    "meq",
    "msf_sc",
    "sjl",
    "outdoor",
    "leba_f2",
    "leba_f3",
    "leba_f4",
    "leba_f5",
    "VLSQ8"
  )
  value_type <- ifelse(
    variable %in% c("site", "sex", "gender", "employment_status", "meq_type"),
    "categorical",
    "numeric"
  )
  baseline_variable <- ifelse(
    variable %in% c("site", "age", "sex", "gender", "employment_status"),
    variable,
    NA_character_
  )
  unit <- c(
    "category",
    "years",
    rep("category", 4L),
    "score",
    "clock_hour",
    "h",
    "min",
    rep("score", 5L)
  )
  transform <- rep("identity", length(variable))
  transform[variable == "msf_sc"] <- "difftime_to_hours"
  transform[variable == "sjl"] <- "difftime_to_hours"
  transform[variable == "outdoor"] <- "difftime_to_minutes"
  label <- c(
    "Study site",
    "Current age",
    "Sex assigned at birth",
    "Gender identity",
    "Employment status",
    "MEQ chronotype",
    "Morningness-Eveningness Questionnaire score",
    "Sleep-corrected midsleep on free days",
    "Social jetlag",
    "Average time outdoors",
    "LEBA F2: time outdoors",
    "LEBA F3: devices in bed",
    "LEBA F4: ambient light before bed",
    "LEBA F5: morning/daytime light",
    "VLSQ-8 light-sensitivity sum score"
  )
  status <- ifelse(
    is.na(baseline_variable),
    "not_applicable_no_field_key_mapping",
    "applicable_field_key_mapping"
  )
  data.frame(
    variable_order = seq_along(variable) + 100L,
    variable_id = paste0("participant_", tolower(variable)),
    domain = "participant_predictor",
    analysis_unit = "participant",
    value_type = value_type,
    canonical_source = "participant_enriched",
    canonical_variable = variable,
    baseline_source = ifelse(is.na(baseline_variable), NA, "baseline_metrics"),
    baseline_variable = baseline_variable,
    native_unit = unit,
    comparison_unit = unit,
    canonical_transform = transform,
    baseline_transform = "identity",
    difference_method = ifelse(
      value_type == "numeric",
      "linear_current_minus_baseline",
      "categorical_exact_agreement"
    ),
    technical_estimand = label,
    comparison_status = status,
    non_applicable_reason = ifelse(
      is.na(baseline_variable),
      paste(
        "This predictor was not present in the manuscript-prepared general",
        "metric object; main-analysis availability is reported without a",
        "direct comparison."
      ),
      NA_character_
    ),
    figure_priority = variable %in%
      c(
        "site",
        "age",
        "sex",
        "gender",
        "meq_type",
        "meq",
        "msf_sc",
        "sjl",
        "leba_f2",
        "leba_f3",
        "leba_f4",
        "leba_f5",
        "VLSQ8"
      ),
    stringsAsFactors = FALSE
  )
}

preanalysis_day_context_crosswalk <- function() {
  variable <- c(
    "site",
    "latitude_deg",
    "photoperiod_hours",
    "local_day_real_hours",
    "local_day_crosses_dst",
    "weekpart"
  )
  canonical_variable <- c(
    "site",
    "latitude_deg",
    "photoperiod_hours",
    "local_day_real_hours",
    "local_day_crosses_dst",
    "local_date"
  )
  baseline_variable <- c("site", "lat", "photoperiod", NA, NA, "Date")
  value_type <- c(
    "categorical",
    "numeric",
    "numeric",
    "numeric",
    "categorical",
    "categorical"
  )
  canonical_transform <- c(
    rep("identity", 5L),
    "date_to_weekpart"
  )
  baseline_transform <- c(
    rep("identity", 5L),
    "date_to_weekpart"
  )
  status <- ifelse(
    is.na(baseline_variable),
    "not_applicable_no_field_key_mapping",
    "applicable_field_key_mapping"
  )
  data.frame(
    variable_order = seq_along(variable) + 200L,
    variable_id = paste0("day_", variable),
    domain = "participant_day_predictor",
    analysis_unit = "participant_day",
    value_type = value_type,
    canonical_source = "participant_day_enriched",
    canonical_variable = canonical_variable,
    baseline_source = ifelse(is.na(baseline_variable), NA, "baseline_metrics"),
    baseline_variable = baseline_variable,
    native_unit = c("category", "degrees", "h", "h", "category", "category"),
    comparison_unit = c(
      "category",
      "degrees",
      "h",
      "h",
      "category",
      "category"
    ),
    canonical_transform = canonical_transform,
    baseline_transform = baseline_transform,
    difference_method = ifelse(
      value_type == "numeric",
      "linear_current_minus_baseline",
      "categorical_exact_agreement"
    ),
    technical_estimand = c(
      "Study site represented among participant-days",
      "Site latitude attached to participant-day",
      "Civil photoperiod duration attached to participant-day",
      "True UTC duration of the local participant-day",
      "Participant-day crosses a daylight-saving transition",
      "Weekday versus weekend from local date"
    ),
    comparison_status = status,
    non_applicable_reason = ifelse(
      is.na(baseline_variable),
      paste(
        "This main-analysis participant-day variable has no exact",
        "manuscript-prepared field."
      ),
      NA_character_
    ),
    figure_priority = TRUE,
    stringsAsFactors = FALSE
  )
}

preanalysis_normalized_day_crosswalk <- function() {
  source <- c(
    rep("exercise_diary", 5L),
    rep("sleep_diary", 6L)
  )
  variable <- c(
    "intensity",
    "location",
    "commute",
    "sedentary",
    "light_glasses",
    "sleepdelay",
    "awakenings",
    "awake_duration",
    "sleepquality",
    "daytype2",
    "sleep_duration"
  )
  value_type <- c(
    "categorical",
    "categorical",
    "numeric",
    "numeric",
    "categorical",
    "numeric",
    "numeric",
    "numeric",
    "categorical",
    "categorical",
    "numeric"
  )
  unit <- c(
    "category",
    "category",
    "min",
    "min",
    "category",
    "min",
    "count",
    "min",
    "category",
    "category",
    "h"
  )
  transform <- rep("identity", length(variable))
  transform[variable %in% c("commute", "sedentary")] <-
    "difftime_to_minutes"
  transform[variable == "sleep_duration"] <- "difftime_to_hours"
  data.frame(
    variable_order = seq_along(variable) + 300L,
    variable_id = paste0("day_", variable),
    domain = "participant_day_predictor",
    analysis_unit = "participant_day",
    value_type = value_type,
    canonical_source = source,
    canonical_variable = variable,
    baseline_source = NA_character_,
    baseline_variable = NA_character_,
    native_unit = unit,
    comparison_unit = unit,
    canonical_transform = transform,
    baseline_transform = "identity",
    difference_method = ifelse(
      value_type == "numeric",
      "linear_current_minus_baseline",
      "categorical_exact_agreement"
    ),
    technical_estimand = c(
      "Self-reported daily exercise intensity",
      "Self-reported daily exercise location",
      "Daily active-commute duration",
      "Daily sedentary duration",
      "Light-glasses use during exercise",
      "Sleep-onset latency",
      "Number of nocturnal awakenings",
      "Total awake duration after sleep onset",
      "Self-reported sleep quality",
      "Free-day versus work-day classification",
      "Diary-derived sleep duration"
    ),
    comparison_status = "not_applicable_no_field_key_mapping",
    non_applicable_reason = paste(
      "No frozen one-object baseline input provides this normalized",
      "participant-day predictor."
    ),
    figure_priority = TRUE,
    stringsAsFactors = FALSE
  )
}

preanalysis_hour_crosswalk <- function() {
  variable <- c(
    "site",
    "clock_hour",
    "diary_state_composition",
    "measurement_context_composition",
    "bin_admissible",
    "lightsource_primary",
    "act_sleep",
    "act_home",
    "act_road_vehicle",
    "act_road_open",
    "act_working_indoor",
    "act_working_outdoor",
    "act_free_outdoor",
    "act_other",
    "interval_analysis_eligible",
    "interval_quarantined",
    "interval_issue_code",
    "diary_date_missing"
  )
  source <- c(
    rep("grid_one_hour", 5L),
    rep("light_diary", 13L)
  )
  value_type <- ifelse(variable == "clock_hour", "numeric", "categorical")
  grid_row <- source == "grid_one_hour"
  data.frame(
    variable_order = seq_along(variable) + 400L,
    variable_id = paste0("hour_", variable),
    domain = ifelse(
      grid_row,
      "participant_hour_predictor",
      "diary_interval_predictor"
    ),
    analysis_unit = ifelse(grid_row, "one_hour", "diary_interval"),
    value_type = value_type,
    canonical_source = source,
    canonical_variable = variable,
    baseline_source = NA_character_,
    baseline_variable = NA_character_,
    native_unit = ifelse(variable == "clock_hour", "clock_hour", "category"),
    comparison_unit = ifelse(
      variable == "clock_hour",
      "clock_hour",
      "category"
    ),
    canonical_transform = ifelse(
      variable == "interval_issue_code",
      "missing_issue_to_no_issue",
      "identity"
    ),
    baseline_transform = "identity",
    difference_method = ifelse(
      value_type == "numeric",
      "linear_current_minus_baseline",
      "categorical_exact_agreement"
    ),
    technical_estimand = c(
      "Study site represented among main-analysis one-hour rows",
      "Local clock hour",
      "Diary-state composition within main-analysis one-hour bin",
      "Measurement-context composition within main-analysis one-hour bin",
      "Main-analysis one-hour metric availability",
      "Primary self-reported light-source category",
      "Sleeping-in-bed activity flag",
      "Awake-at-home activity flag",
      "Vehicle/public-transport activity flag",
      "Walking/cycling road activity flag",
      "Indoor-work activity flag",
      "Outdoor-work activity flag",
      "Outdoor-free-time activity flag",
      "Other-activity flag",
      "Light-diary interval eligible for hour-level analysis",
      "Retained light-diary interval quarantine flag",
      "Retained light-diary interval issue code",
      "Retained light-diary missing-date flag"
    ),
    comparison_status = "not_applicable_no_field_key_mapping",
    non_applicable_reason = paste(
      "The manuscript-prepared data have no directly matching main-analysis",
      "one-hour or diary-interval field and record key."
    ),
    figure_priority = TRUE,
    stringsAsFactors = FALSE
  )
}

preanalysis_variable_crosswalk <- function() {
  crosswalk <- rbind(
    preanalysis_metric_crosswalk(),
    preanalysis_grid_metric_crosswalk(),
    preanalysis_participant_crosswalk(),
    preanalysis_day_context_crosswalk(),
    preanalysis_normalized_day_crosswalk(),
    preanalysis_hour_crosswalk()
  )
  light_metric <- crosswalk$domain == "light_metric"
  crosswalk$metric_id <- NA_character_
  crosswalk$metric_id[light_metric] <- sub(
    "^light_",
    "",
    crosswalk$variable_id[light_metric]
  )
  crosswalk$metric_id[
    crosswalk$variable_id == "light_medi_30_minute_arithmetic_mean"
  ] <- "thirty_minute_arithmetic_medi"
  crosswalk$metric_id[
    crosswalk$variable_id == "light_medi_one_hour_zero_aware_geometric_mean"
  ] <- "one_hour_geometric_mean_medi"
  centered_clock <- crosswalk$canonical_transform ==
    "clock_minute_to_centered_decimal_hour"
  ordinary_clock <- crosswalk$canonical_transform ==
    "clock_minute_to_decimal_hour" |
    crosswalk$variable_id == "hour_clock_hour"
  crosswalk$axis_geometry <- ifelse(
    crosswalk$value_type == "categorical",
    "categorical",
    "linear"
  )
  crosswalk$linear_summary_interpretation <- ifelse(
    centered_clock,
    paste(
      "Ordinary linear summaries on the midnight-centred half-open",
      "[-12, 12) hour axis; clock values at or after 12:00 are shifted",
      "by -24 hours."
    ),
    ifelse(
      ordinary_clock,
      paste(
        "Ordinary linear summaries on the declared unwrapped",
        "0-24 hour axis."
      ),
      ifelse(
        crosswalk$variable_id == "participant_msf_sc",
        paste(
          "Ordinary linear summaries on the observed post-midnight",
          "midsleep hour range."
        ),
        ifelse(
          crosswalk$value_type == "numeric",
          paste(
            "Ordinary linear distribution summary on the declared",
            "comparison scale."
          ),
          "Not applicable to categorical level distributions."
        )
      )
    )
  )
  crosswalk$mapping_scope <- ifelse(
    crosswalk$comparison_status == "applicable_field_key_mapping",
    paste(
      "Direct field and key mapping for descriptive before/after",
      "reconciliation; not a claim of value or estimand equivalence."
    ),
    paste(
      "Main-analysis availability only; no direct manuscript-prepared field",
      "and record-key mapping is asserted."
    )
  )
  crosswalk$semantic_comparability <- ifelse(
    crosswalk$comparison_status != "applicable_field_key_mapping",
    "not_applicable",
    ifelse(
      crosswalk$domain == "light_metric",
      "same_named_or_directly_corresponding_construct_with_repaired_implementation",
      "same_declared_field_and_scale"
    )
  )
  crosswalk$comparability_class <- ifelse(
    crosswalk$comparison_status != "applicable_field_key_mapping",
    "changed_estimand_or_no_direct_mapping_no_numerical_comparison",
    ifelse(
      crosswalk$domain == "light_metric",
      "same_nominal_construct_changed_computation_admissibility_descriptive_only",
      "exact_field_key_and_scale_mapping"
    )
  )
  light_id <- crosswalk$variable_id
  crosswalk$comparability_note <- ifelse(
    crosswalk$comparability_class == "exact_field_key_and_scale_mapping",
    paste(
      "The manuscript-prepared and main-analysis fields share the declared",
      "record key and scale;",
      "paired equality is descriptive and still subject to upstream sample",
      "availability."
    ),
    crosswalk$non_applicable_reason
  )
  changed_light <- crosswalk$comparability_class ==
    paste0(
      "same_nominal_construct_changed_computation_admissibility_",
      "descriptive_only"
  )
  crosswalk$comparability_note[changed_light] <- paste(
    "The variables have the same broad name, but the main analysis changes",
    "masking, temporal support, admissibility, gap handling, DST handling,",
    "tie handling, or integration; side-by-side and paired values are",
    "descriptive and do not prove that the variables measure exactly the",
    "same quantity."
  )
  crosswalk$comparability_note[
    changed_light &
      grepl("interdaily_stability|intradaily_variability", light_id)
  ] <- paste(
    "The manuscript-prepared IS/IV calculation drops missing hourly values",
    "before aggregation or adjacency, which can bridge absent hours; the main",
    "analysis represents time support and adjacency explicitly. Comparison",
    "is descriptive only."
  )
  crosswalk$comparability_note[
    changed_light &
      grepl("m10_|l10_", light_id)
  ] <- paste(
    "The manuscript-prepared rolling windows allow partial data through",
    "`na.rm`; the main-analysis windows apply explicit data-support, tie,",
    "wall-clock and daylight-saving rules.",
    "Comparison is descriptive only."
  )
  crosswalk$comparability_note[
    changed_light &
      grepl("timing_above_250", light_id)
  ] <- paste(
    "The manuscript-prepared timing calculation drops gaps and averages",
    "timestamps arithmetically; the main analysis checks time-of-day data",
    "support on the declared linear hour scale.",
    "Comparison is descriptive only."
  )
  crosswalk$comparability_note[
    changed_light &
      grepl(
        "duration_above_1000|duration_above_250_full_day|timing_above_250",
        light_id
      )
  ] <- paste(
    "The manuscript-prepared LightLogR threshold helpers use inclusive",
    ">=/<= endpoints; the main-analysis endpoints are strict >/< and also",
    "change coverage, gap and time handling. Comparison is descriptive only."
  )
  crosswalk$comparability_note[
    changed_light &
      grepl("longest_bout_above_250$", light_id)
  ] <- paste(
    "The manuscript-prepared longest-period code can bridge missing intervals",
    "after `na.rm`; main-analysis periods break at missing, invalid or changed",
    "context intervals and retain lower- and upper-bound information.",
    "Comparison is descriptive, not equivalent."
  )
  crosswalk$comparability_note[
    changed_light &
      grepl(
        "duration_above_250_wake|duration_below_10_pre_sleep|duration_below_1_sleep",
        light_id
      )
  ] <- paste(
    "Main-analysis sleep and wake durations require explicit diary-window and",
    "data-support checks that are absent from the manuscript-prepared data.",
    "Comparison is descriptive only."
  )
  crosswalk$comparability_note[
    crosswalk$variable_id == "day_photoperiod_hours"
  ] <- paste(
    "Field, key, scale, and frozen-domain values agree exactly, but",
    "manuscript-prepared and main-analysis photoperiod have different",
    "calculation records; the main-analysis civil -6 degree context is used."
  )
  l10_centered <- crosswalk$variable_id == "light_l10_midpoint"
  crosswalk$comparability_note[l10_centered] <- paste(
    crosswalk$comparability_note[l10_centered],
    paste(
      "For this descriptive comparison, the clock axis is linear and",
      "midnight-centred on [-12, 12); main-analysis values at or after noon",
      "are shifted by -24 and manuscript-prepared values are already centred."
    )
  )
  rownames(crosswalk) <- NULL
  if (
    anyDuplicated(crosswalk$variable_id) ||
      anyNA(crosswalk$metric_id[light_metric]) ||
      anyDuplicated(crosswalk$metric_id[light_metric]) ||
      any(
        preanalysis_discarded_clock_variable_ids() %in%
          crosswalk$variable_id
      ) ||
      !all(
        crosswalk$comparison_status %in% preanalysis_comparison_statuses()
      ) ||
      any(
        crosswalk$comparison_status == "applicable_field_key_mapping" &
          is.na(crosswalk$baseline_variable)
      ) ||
      any(
        crosswalk$value_type == "numeric" &
          (crosswalk$axis_geometry != "linear" |
            crosswalk$difference_method != "linear_current_minus_baseline")
      ) ||
      any(
        centered_clock &
          crosswalk$baseline_transform != "identity"
      )
  ) {
    abort_pipeline("Pre-analysis variable crosswalk is internally invalid")
  }
  crosswalk[order(crosswalk$variable_order), , drop = FALSE]
}

preanalysis_transform_value <- function(value, transformation) {
  if (identical(transformation, "identity")) {
    return(value)
  }
  if (identical(transformation, "clock_minute_to_decimal_hour")) {
    return(as.numeric(value) / 60)
  }
  if (
    identical(
      transformation,
      "clock_minute_to_centered_decimal_hour"
    )
  ) {
    result <- as.numeric(value) / 60
    result[is.finite(result) & result >= 12] <-
      result[is.finite(result) & result >= 12] - 24
    return(result)
  }
  if (identical(transformation, "difftime_to_minutes")) {
    if (inherits(value, "hms")) {
      return(as.numeric(value) / 60)
    }
    return(as.numeric(value, units = "mins"))
  }
  if (identical(transformation, "difftime_to_hours")) {
    if (inherits(value, "hms")) {
      return(as.numeric(value) / 3600)
    }
    return(as.numeric(value, units = "hours"))
  }
  if (identical(transformation, "date_to_weekpart")) {
    date <- as.Date(value)
    weekday <- as.POSIXlt(date, tz = "UTC")$wday
    return(factor(
      ifelse(weekday %in% c(0L, 6L), "weekend", "weekday"),
      levels = c("weekday", "weekend")
    ))
  }
  if (identical(transformation, "missing_issue_to_no_issue")) {
    result <- as.character(value)
    result[is.na(result)] <- "no_issue"
    return(result)
  }
  abort_pipeline("Unknown pre-analysis transformation: %s", transformation)
}

preanalysis_difference <- function(canonical, baseline, method) {
  if (identical(method, "linear_current_minus_baseline")) {
    return(canonical - baseline)
  }
  abort_pipeline("Unknown numeric paired-difference method: %s", method)
}

preanalysis_key_columns <- function(analysis_unit) {
  switch(
    analysis_unit,
    participant = c("site", "Id", "position"),
    participant_day = c("site", "Id", "position", "local_date"),
    `30_minute` = c(
      "site",
      "Id",
      "position",
      "local_date",
      "subkey"
    ),
    one_hour = c(
      "site",
      "Id",
      "position",
      "local_date",
      "subkey"
    ),
    diary_interval = c(
      "site",
      "Id",
      "position",
      "local_date",
      "subkey"
    ),
    abort_pipeline(
      "Unknown pre-analysis unit for key construction: %s",
      analysis_unit
    )
  )
}

preanalysis_value_rows <- function(
  data,
  specification,
  series,
  placement,
  value,
  local_date = NULL,
  subkey = NULL,
  estimable = NULL
) {
  if (!is.data.frame(data)) {
    abort_pipeline("Pre-analysis value input must be a data frame")
  }
  assert_columns(data, c("site", "Id"), object = "pre-analysis value input")
  if (nrow(specification) != 1L) {
    abort_pipeline("One variable specification row is required")
  }
  if (length(value) != nrow(data)) {
    abort_pipeline("Pre-analysis value length does not match input rows")
  }
  if (is.null(local_date)) {
    local_date <- rep(as.Date(NA), nrow(data))
  }
  if (is.null(subkey)) {
    subkey <- rep(NA_character_, nrow(data))
  }
  if (is.null(estimable)) {
    estimable <- !is.na(value)
  }
  if (
    length(local_date) != nrow(data) ||
      length(subkey) != nrow(data) ||
      length(estimable) != nrow(data)
  ) {
    abort_pipeline("Pre-analysis key/estimability lengths do not reconcile")
  }
  transformed <- preanalysis_transform_value(
    value,
    specification[[paste0(series, "_transform")]][[1L]]
  )
  value_type <- specification$value_type[[1L]]
  if (identical(value_type, "numeric")) {
    numeric_value <- as.numeric(transformed)
    character_value <- rep(NA_character_, nrow(data))
  } else if (identical(value_type, "categorical")) {
    numeric_value <- rep(NA_real_, nrow(data))
    character_value <- as.character(transformed)
  } else {
    abort_pipeline("Unknown pre-analysis value type: %s", value_type)
  }
  result <- data.frame(
    variable_id = specification$variable_id[[1L]],
    placement = placement,
    position = placement,
    analysis_unit = specification$analysis_unit[[1L]],
    series = series,
    site = as.character(data$site),
    Id = as.character(data$Id),
    local_date = as.Date(local_date),
    subkey = as.character(subkey),
    estimable = as.logical(estimable),
    numeric_value = numeric_value,
    character_value = character_value,
    stringsAsFactors = FALSE
  )
  key <- preanalysis_key_columns(specification$analysis_unit[[1L]])
  if (anyNA(result[c("site", "Id", "position")])) {
    abort_pipeline("Pre-analysis rows contain missing participant keys")
  }
  if (
    specification$analysis_unit[[1L]] != "participant" &&
      specification$analysis_unit[[1L]] != "diary_interval" &&
      any(
        is.na(result$local_date) &
          result$estimable %in% TRUE
      )
  ) {
    abort_pipeline(
      "Estimable pre-analysis rows contain missing participant-day keys"
    )
  }
  if (
    specification$analysis_unit[[1L]] %in%
      c("30_minute", "one_hour", "diary_interval") &&
      anyNA(result$subkey)
  ) {
    abort_pipeline("Pre-analysis rows contain missing within-day keys")
  }
  token <- do.call(
    paste,
    c(
      lapply(result[key], function(value) {
        value <- as.character(value)
        value[is.na(value)] <- "<missing>"
        value
      }),
      sep = "\u001f"
    )
  )
  if (anyDuplicated(token)) {
    abort_pipeline("Pre-analysis variable rows contain duplicated keys")
  }
  result
}

preanalysis_participant_token <- function(data) {
  paste(data$site, data$Id, sep = "\u001f")
}

preanalysis_day_token <- function(data) {
  token <- paste(
    data$site,
    data$Id,
    format(data$local_date, "%Y-%m-%d"),
    sep = "\u001f"
  )
  token[is.na(data$local_date)] <- NA_character_
  token
}

preanalysis_count_unique <- function(data, observed, unit) {
  participant <- preanalysis_participant_token(data)
  participant_total <- length(unique(participant))
  participant_observed <- length(unique(participant[observed]))
  has_day <- !identical(unit, "participant")
  day <- if (has_day) preanalysis_day_token(data) else character()
  day_total <- if (has_day) day[!is.na(day)] else character()
  day_observed <- if (has_day) day[observed & !is.na(day)] else character()
  c(
    n_participants = participant_total,
    n_participants_observed = participant_observed,
    n_participant_days = if (has_day) {
      length(unique(day_total))
    } else {
      NA_integer_
    },
    n_participant_days_observed = if (has_day) {
      length(unique(day_observed))
    } else {
      NA_integer_
    }
  )
}

preanalysis_quantile_probabilities <- function() {
  c(0, 0.025, 0.05, 0.25, 0.5, 0.75, 0.95, 0.975, 1)
}

preanalysis_numeric_quantiles <- function(rows, specification) {
  finite <- rows$estimable %in% TRUE & is.finite(rows$numeric_value)
  probabilities <- preanalysis_quantile_probabilities()
  values <- if (any(finite)) {
    as.numeric(stats::quantile(
      rows$numeric_value[finite],
      probs = probabilities,
      names = FALSE,
      type = 7
    ))
  } else {
    rep(NA_real_, length(probabilities))
  }
  data.frame(
    variable_id = specification$variable_id[[1L]],
    placement = unique(rows$placement),
    analysis_unit = specification$analysis_unit[[1L]],
    series = unique(rows$series),
    comparison_unit = specification$comparison_unit[[1L]],
    axis_geometry = specification$axis_geometry[[1L]],
    summary_interpretation = specification$linear_summary_interpretation[[1L]],
    probability = probabilities,
    value = values,
    n_finite = sum(finite),
    stringsAsFactors = FALSE
  )
}

preanalysis_series_summary <- function(rows, specification) {
  value_type <- specification$value_type[[1L]]
  observed <- if (identical(value_type, "numeric")) {
    rows$estimable %in% TRUE & is.finite(rows$numeric_value)
  } else {
    rows$estimable %in% TRUE & !is.na(rows$character_value)
  }
  counts <- preanalysis_count_unique(
    rows,
    observed,
    specification$analysis_unit[[1L]]
  )
  numeric_summary <- identical(value_type, "numeric")
  finite_value <- if (numeric_summary) {
    rows$numeric_value[observed]
  } else {
    numeric()
  }
  quantile_value <- if (numeric_summary && length(finite_value) > 0L) {
    as.numeric(stats::quantile(
      finite_value,
      probs = c(0.025, 0.25, 0.5, 0.75, 0.975),
      names = FALSE,
      type = 7
    ))
  } else {
    rep(NA_real_, 5L)
  }
  circular <- c(
    circular_mean = NA_real_,
    circular_median = NA_real_,
    circular_resultant_length = NA_real_,
    circular_sd_hours = NA_real_
  )
  data.frame(
    variable_id = specification$variable_id[[1L]],
    placement = unique(rows$placement),
    analysis_unit = specification$analysis_unit[[1L]],
    series = unique(rows$series),
    domain = specification$domain[[1L]],
    value_type = value_type,
    comparison_unit = specification$comparison_unit[[1L]],
    axis_geometry = specification$axis_geometry[[1L]],
    linear_summary_interpretation = specification$linear_summary_interpretation[[
      1L
    ]],
    n_observations = nrow(rows),
    n_estimable = sum(rows$estimable %in% TRUE),
    n_nonestimable = sum(!(rows$estimable %in% TRUE)),
    n_observed = sum(observed),
    n_missing = if (numeric_summary) {
      sum(is.na(rows$numeric_value))
    } else {
      sum(is.na(rows$character_value))
    },
    n_nonfinite = if (numeric_summary) {
      sum(
        rows$estimable %in%
          TRUE &
          !is.na(rows$numeric_value) &
          !is.finite(rows$numeric_value)
      )
    } else {
      NA_integer_
    },
    n_estimable_missing = if (numeric_summary) {
      sum(rows$estimable %in% TRUE & is.na(rows$numeric_value))
    } else {
      sum(rows$estimable %in% TRUE & is.na(rows$character_value))
    },
    n_participants = counts[["n_participants"]],
    n_participants_observed = counts[["n_participants_observed"]],
    n_participant_days = counts[["n_participant_days"]],
    n_participant_days_observed = counts[[
      "n_participant_days_observed"
    ]],
    mean = if (numeric_summary && length(finite_value) > 0L) {
      mean(finite_value)
    } else {
      NA_real_
    },
    sd = if (numeric_summary && length(finite_value) > 1L) {
      stats::sd(finite_value)
    } else {
      NA_real_
    },
    median = if (numeric_summary) quantile_value[[3L]] else NA_real_,
    iqr = if (numeric_summary && length(finite_value) > 0L) {
      stats::IQR(finite_value, type = 7)
    } else {
      NA_real_
    },
    q025 = if (numeric_summary) quantile_value[[1L]] else NA_real_,
    q25 = if (numeric_summary) quantile_value[[2L]] else NA_real_,
    q75 = if (numeric_summary) quantile_value[[4L]] else NA_real_,
    q975 = if (numeric_summary) quantile_value[[5L]] else NA_real_,
    minimum = if (numeric_summary && length(finite_value) > 0L) {
      min(finite_value)
    } else {
      NA_real_
    },
    maximum = if (numeric_summary && length(finite_value) > 0L) {
      max(finite_value)
    } else {
      NA_real_
    },
    n_zero = if (numeric_summary) sum(finite_value == 0) else NA_integer_,
    zero_rate = if (numeric_summary && length(finite_value) > 0L) {
      mean(finite_value == 0)
    } else {
      NA_real_
    },
    nonfinite_rate = if (
      numeric_summary && sum(rows$estimable %in% TRUE) > 0L
    ) {
      sum(
        rows$estimable %in%
          TRUE &
          !is.na(rows$numeric_value) &
          !is.finite(rows$numeric_value)
      ) /
        sum(rows$estimable %in% TRUE)
    } else {
      NA_real_
    },
    circular_mean = circular[["circular_mean"]],
    circular_median = circular[["circular_median"]],
    circular_resultant_length = circular[["circular_resultant_length"]],
    circular_sd_hours = circular[["circular_sd_hours"]],
    stringsAsFactors = FALSE
  )
}

preanalysis_categorical_levels <- function(rows, specification) {
  value <- rows$character_value
  value[is.na(value)] <- "<missing>"
  estimable_rows <- rows$estimable %in% TRUE
  value <- value[estimable_rows]
  retained <- rows[estimable_rows, , drop = FALSE]
  levels_present <- sort(unique(value), na.last = TRUE)
  if (length(levels_present) == 0L) {
    levels_present <- "<no_estimable_rows>"
  }
  result <- lapply(seq_along(levels_present), function(index) {
    level <- levels_present[[index]]
    selected <- if (identical(level, "<no_estimable_rows>")) {
      rep(FALSE, nrow(retained))
    } else {
      value == level
    }
    counts <- if (nrow(retained) > 0L) {
      preanalysis_count_unique(
        retained,
        selected,
        specification$analysis_unit[[1L]]
      )
    } else {
      c(
        n_participants = 0L,
        n_participants_observed = 0L,
        n_participant_days = if (
          specification$analysis_unit[[1L]] == "participant"
        ) {
          NA_integer_
        } else {
          0L
        },
        n_participant_days_observed = if (
          specification$analysis_unit[[1L]] == "participant"
        ) {
          NA_integer_
        } else {
          0L
        }
      )
    }
    data.frame(
      variable_id = specification$variable_id[[1L]],
      placement = unique(rows$placement),
      analysis_unit = specification$analysis_unit[[1L]],
      series = unique(rows$series),
      level = level,
      n = sum(selected),
      proportion = if (length(value) > 0L) {
        sum(selected) / length(value)
      } else {
        NA_real_
      },
      n_participants = counts[["n_participants_observed"]],
      n_participant_days = counts[["n_participant_days_observed"]],
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, result)
}

preanalysis_key_token <- function(rows, analysis_unit) {
  key <- preanalysis_key_columns(analysis_unit)
  do.call(
    paste,
    c(lapply(rows[key], as.character), sep = "\u001f")
  )
}

preanalysis_reconcile_keys <- function(
  baseline,
  canonical,
  specification
) {
  status <- specification$comparison_status[[1L]]
  canonical_token <- preanalysis_key_token(
    canonical,
    specification$analysis_unit[[1L]]
  )
  if (!identical(status, "applicable_field_key_mapping")) {
    return(data.frame(
      variable_id = specification$variable_id[[1L]],
      placement = unique(canonical$placement),
      analysis_unit = specification$analysis_unit[[1L]],
      comparison_status = status,
      baseline_n_keys = NA_integer_,
      canonical_n_keys = length(canonical_token),
      common_n_keys = NA_integer_,
      baseline_only_n_keys = NA_integer_,
      canonical_only_n_keys = NA_integer_,
      baseline_n_participants = NA_integer_,
      canonical_n_participants = length(unique(
        preanalysis_participant_token(canonical)
      )),
      baseline_n_participant_days = NA_integer_,
      canonical_n_participant_days = if (
        specification$analysis_unit[[1L]] == "participant"
      ) {
        NA_integer_
      } else {
        day <- preanalysis_day_token(canonical)
        length(unique(day[!is.na(day)]))
      },
      stringsAsFactors = FALSE
    ))
  }
  baseline_token <- preanalysis_key_token(
    baseline,
    specification$analysis_unit[[1L]]
  )
  data.frame(
    variable_id = specification$variable_id[[1L]],
    placement = unique(canonical$placement),
    analysis_unit = specification$analysis_unit[[1L]],
    comparison_status = status,
    baseline_n_keys = length(baseline_token),
    canonical_n_keys = length(canonical_token),
    common_n_keys = length(intersect(baseline_token, canonical_token)),
    baseline_only_n_keys = length(setdiff(baseline_token, canonical_token)),
    canonical_only_n_keys = length(setdiff(canonical_token, baseline_token)),
    baseline_n_participants = length(unique(
      preanalysis_participant_token(baseline)
    )),
    canonical_n_participants = length(unique(
      preanalysis_participant_token(canonical)
    )),
    baseline_n_participant_days = if (
      specification$analysis_unit[[1L]] == "participant"
    ) {
      NA_integer_
    } else {
      day <- preanalysis_day_token(baseline)
      length(unique(day[!is.na(day)]))
    },
    canonical_n_participant_days = if (
      specification$analysis_unit[[1L]] == "participant"
    ) {
      NA_integer_
    } else {
      day <- preanalysis_day_token(canonical)
      length(unique(day[!is.na(day)]))
    },
    stringsAsFactors = FALSE
  )
}

preanalysis_pair_rows <- function(baseline, canonical, specification) {
  key <- preanalysis_key_columns(specification$analysis_unit[[1L]])
  baseline_value <- baseline[c(
    key,
    "estimable",
    "numeric_value",
    "character_value"
  )]
  canonical_value <- canonical[c(
    key,
    "estimable",
    "numeric_value",
    "character_value"
  )]
  names(baseline_value)[-(seq_along(key))] <- paste0(
    names(baseline_value)[-(seq_along(key))],
    "_baseline"
  )
  names(canonical_value)[-(seq_along(key))] <- paste0(
    names(canonical_value)[-(seq_along(key))],
    "_canonical"
  )
  merge(
    baseline_value,
    canonical_value,
    by = key,
    all = FALSE,
    sort = TRUE
  )
}

preanalysis_paired_summary <- function(
  baseline,
  canonical,
  specification
) {
  status <- specification$comparison_status[[1L]]
  value_type <- specification$value_type[[1L]]
  empty <- data.frame(
    variable_id = specification$variable_id[[1L]],
    placement = unique(canonical$placement),
    analysis_unit = specification$analysis_unit[[1L]],
    value_type = value_type,
    comparison_status = status,
    difference_method = specification$difference_method[[1L]],
    comparison_unit = specification$comparison_unit[[1L]],
    n_common_keys = NA_integer_,
    n_paired_observed = NA_integer_,
    mean_difference = NA_real_,
    sd_difference = NA_real_,
    median_difference = NA_real_,
    iqr_difference = NA_real_,
    q025_difference = NA_real_,
    q975_difference = NA_real_,
    mean_absolute_difference = NA_real_,
    root_mean_square_difference = NA_real_,
    pearson_correlation = NA_real_,
    spearman_correlation = NA_real_,
    n_equal = NA_integer_,
    agreement_rate = NA_real_,
    stringsAsFactors = FALSE
  )
  if (!identical(status, "applicable_field_key_mapping")) {
    return(empty)
  }
  paired <- preanalysis_pair_rows(baseline, canonical, specification)
  empty$n_common_keys <- nrow(paired)
  if (identical(value_type, "categorical")) {
    observed <- paired$estimable_baseline %in%
      TRUE &
      paired$estimable_canonical %in% TRUE &
      !is.na(paired$character_value_baseline) &
      !is.na(paired$character_value_canonical)
    equal <- paired$character_value_baseline[observed] ==
      paired$character_value_canonical[observed]
    empty$n_paired_observed <- sum(observed)
    empty$n_equal <- sum(equal)
    empty$agreement_rate <- if (length(equal) > 0L) mean(equal) else NA_real_
    return(empty)
  }
  observed <- paired$estimable_baseline %in%
    TRUE &
    paired$estimable_canonical %in% TRUE &
    is.finite(paired$numeric_value_baseline) &
    is.finite(paired$numeric_value_canonical)
  baseline_value <- paired$numeric_value_baseline[observed]
  canonical_value <- paired$numeric_value_canonical[observed]
  difference <- preanalysis_difference(
    canonical_value,
    baseline_value,
    specification$difference_method[[1L]]
  )
  empty$n_paired_observed <- length(difference)
  if (length(difference) == 0L) {
    return(empty)
  }
  quantile_value <- as.numeric(stats::quantile(
    difference,
    probs = c(0.025, 0.5, 0.975),
    names = FALSE,
    type = 7
  ))
  empty$mean_difference <- mean(difference)
  empty$sd_difference <- if (length(difference) > 1L) {
    stats::sd(difference)
  } else {
    NA_real_
  }
  empty$median_difference <- quantile_value[[2L]]
  empty$iqr_difference <- stats::IQR(difference, type = 7)
  empty$q025_difference <- quantile_value[[1L]]
  empty$q975_difference <- quantile_value[[3L]]
  empty$mean_absolute_difference <- mean(abs(difference))
  empty$root_mean_square_difference <- sqrt(mean(difference^2))
  correlation_estimable <- length(difference) > 1L &&
    stats::sd(baseline_value) > 0 &&
    stats::sd(canonical_value) > 0
  if (correlation_estimable) {
    empty$pearson_correlation <- stats::cor(
      baseline_value,
      canonical_value,
      method = "pearson"
    )
    empty$spearman_correlation <- stats::cor(
      baseline_value,
      canonical_value,
      method = "spearman"
    )
  }
  empty
}

preanalysis_bowley_skew <- function(value) {
  if (length(value) < 1L) {
    return(NA_real_)
  }
  q <- as.numeric(stats::quantile(
    value,
    probs = c(0.25, 0.5, 0.75),
    names = FALSE,
    type = 7
  ))
  denominator <- q[[3L]] - q[[1L]]
  if (!is.finite(denominator) || denominator == 0) {
    return(NA_real_)
  }
  (q[[3L]] + q[[1L]] - 2 * q[[2L]]) / denominator
}

preanalysis_tail_asymmetry <- function(value) {
  if (length(value) < 1L) {
    return(NA_real_)
  }
  q <- as.numeric(stats::quantile(
    value,
    probs = c(0.05, 0.5, 0.95),
    names = FALSE,
    type = 7
  ))
  denominator <- q[[3L]] - q[[1L]]
  if (!is.finite(denominator) || denominator == 0) {
    return(NA_real_)
  }
  ((q[[3L]] - q[[2L]]) - (q[[2L]] - q[[1L]])) / denominator
}

preanalysis_numeric_distance <- function(baseline, canonical) {
  baseline <- baseline[is.finite(baseline)]
  canonical <- canonical[is.finite(canonical)]
  if (length(baseline) == 0L || length(canonical) == 0L) {
    return(c(
      ecdf_max_distance = NA_real_,
      wasserstein_1 = NA_real_,
      wasserstein_1_iqr_scaled = NA_real_
    ))
  }
  grid <- sort(unique(c(baseline, canonical)))
  ecdf_distance <- max(abs(
    stats::ecdf(baseline)(grid) -
      stats::ecdf(canonical)(grid)
  ))
  probabilities <- seq(0.001, 0.999, length.out = 999L)
  baseline_quantile <- as.numeric(stats::quantile(
    baseline,
    probs = probabilities,
    names = FALSE,
    type = 7
  ))
  canonical_quantile <- as.numeric(stats::quantile(
    canonical,
    probs = probabilities,
    names = FALSE,
    type = 7
  ))
  wasserstein <- mean(abs(canonical_quantile - baseline_quantile))
  pooled_iqr <- stats::IQR(c(baseline, canonical), type = 7)
  c(
    ecdf_max_distance = ecdf_distance,
    wasserstein_1 = wasserstein,
    wasserstein_1_iqr_scaled = if (is.finite(pooled_iqr) && pooled_iqr > 0) {
      wasserstein / pooled_iqr
    } else {
      NA_real_
    }
  )
}

preanalysis_categorical_distance <- function(baseline, canonical) {
  baseline[is.na(baseline)] <- "<missing>"
  canonical[is.na(canonical)] <- "<missing>"
  if (length(baseline) == 0L || length(canonical) == 0L) {
    return(c(
      total_variation_distance = NA_real_,
      maximum_absolute_proportion_difference = NA_real_
    ))
  }
  level <- sort(unique(c(baseline, canonical)))
  baseline_proportion <- table(factor(baseline, levels = level)) /
    length(baseline)
  canonical_proportion <- table(factor(canonical, levels = level)) /
    length(canonical)
  absolute <- abs(
    as.numeric(canonical_proportion) -
      as.numeric(baseline_proportion)
  )
  c(
    total_variation_distance = 0.5 * sum(absolute),
    maximum_absolute_proportion_difference = max(absolute)
  )
}

preanalysis_distribution_shape <- function(
  baseline,
  canonical,
  specification
) {
  value_type <- specification$value_type[[1L]]
  status <- specification$comparison_status[[1L]]
  result <- data.frame(
    variable_id = specification$variable_id[[1L]],
    placement = unique(canonical$placement),
    analysis_unit = specification$analysis_unit[[1L]],
    value_type = value_type,
    comparison_status = status,
    comparison_unit = specification$comparison_unit[[1L]],
    axis_geometry = specification$axis_geometry[[1L]],
    distance_scope = paste(
      "all_estimable_rows;",
      "numeric finite only;",
      "categorical missing retained as level"
    ),
    distance_interpretation = paste(
      "Descriptive empirical distance only; no hypothesis test or",
      "sample-size-driven p-value."
    ),
    baseline_bowley_skew = NA_real_,
    canonical_bowley_skew = NA_real_,
    baseline_tail_asymmetry = NA_real_,
    canonical_tail_asymmetry = NA_real_,
    ecdf_max_distance = NA_real_,
    wasserstein_1 = NA_real_,
    wasserstein_1_iqr_scaled = NA_real_,
    circular_kuiper_distance = NA_real_,
    total_variation_distance = NA_real_,
    maximum_absolute_proportion_difference = NA_real_,
    stringsAsFactors = FALSE
  )
  if (identical(value_type, "numeric")) {
    if (specification$axis_geometry[[1L]] != "linear") {
      abort_pipeline(
        "Numeric descriptive distributions require a declared linear axis"
      )
    }
    canonical_value <- canonical$numeric_value[
      canonical$estimable %in% TRUE & is.finite(canonical$numeric_value)
    ]
    result$canonical_bowley_skew <- preanalysis_bowley_skew(
      canonical_value
    )
    result$canonical_tail_asymmetry <- preanalysis_tail_asymmetry(
      canonical_value
    )
    if (identical(status, "applicable_field_key_mapping")) {
      baseline_value <- baseline$numeric_value[
        baseline$estimable %in% TRUE & is.finite(baseline$numeric_value)
      ]
      result$baseline_bowley_skew <- preanalysis_bowley_skew(
        baseline_value
      )
      result$baseline_tail_asymmetry <- preanalysis_tail_asymmetry(
        baseline_value
      )
      distance <- preanalysis_numeric_distance(
        baseline_value,
        canonical_value
      )
      result$ecdf_max_distance <- distance[["ecdf_max_distance"]]
      result$wasserstein_1 <- distance[["wasserstein_1"]]
      result$wasserstein_1_iqr_scaled <-
        distance[["wasserstein_1_iqr_scaled"]]
    }
  } else if (identical(status, "applicable_field_key_mapping")) {
    baseline_value <- baseline$character_value[
      baseline$estimable %in% TRUE
    ]
    canonical_value <- canonical$character_value[
      canonical$estimable %in% TRUE
    ]
    distance <- preanalysis_categorical_distance(
      baseline_value,
      canonical_value
    )
    result$total_variation_distance <-
      distance[["total_variation_distance"]]
    result$maximum_absolute_proportion_difference <-
      distance[["maximum_absolute_proportion_difference"]]
  }
  result
}

preanalysis_comparison_overview <- function(
  series_summary,
  shape_summary,
  key_reconciliation,
  paired_summary,
  crosswalk
) {
  baseline <- series_summary[
    series_summary$series == "baseline",
    ,
    drop = FALSE
  ]
  canonical <- series_summary[
    series_summary$series == "canonical",
    ,
    drop = FALSE
  ]
  key <- c("variable_id", "placement", "analysis_unit")
  metric_columns <- c(
    "n_observations",
    "n_estimable",
    "n_observed",
    "n_missing",
    "n_nonfinite",
    "n_participants",
    "n_participants_observed",
    "n_participant_days",
    "n_participant_days_observed",
    "mean",
    "median",
    "sd",
    "iqr",
    "q025",
    "q25",
    "q75",
    "q975",
    "zero_rate",
    "nonfinite_rate",
    "circular_mean",
    "circular_median",
    "circular_resultant_length",
    "circular_sd_hours"
  )
  baseline <- baseline[c(key, metric_columns)]
  canonical <- canonical[c(key, metric_columns)]
  names(baseline)[-(seq_along(key))] <- paste0(
    "baseline_",
    names(baseline)[-(seq_along(key))]
  )
  names(canonical)[-(seq_along(key))] <- paste0(
    "canonical_",
    names(canonical)[-(seq_along(key))]
  )
  overview <- merge(
    canonical,
    baseline,
    by = key,
    all.x = TRUE,
    sort = FALSE
  )
  metadata <- crosswalk[c(
    "variable_order",
    "variable_id",
    "metric_id",
    "manuscript_name",
    "abbreviation",
    "manuscript_category",
    "analytical_role",
    "variant_label",
    "domain",
    "value_type",
    "native_unit",
    "comparison_unit",
    "display_unit",
    "canonical_transform",
    "baseline_transform",
    "axis_geometry",
    "linear_summary_interpretation",
    "technical_estimand",
    "comparison_status",
    "mapping_scope",
    "semantic_comparability",
    "comparability_class",
    "comparability_note",
    "non_applicable_reason"
  )]
  overview <- merge(
    metadata,
    overview,
    by = "variable_id",
    all.y = TRUE,
    sort = FALSE
  )
  count_delta <- c(
    "n_observations",
    "n_estimable",
    "n_observed",
    "n_missing",
    "n_nonfinite",
    "n_participants",
    "n_participants_observed",
    "n_participant_days",
    "n_participant_days_observed"
  )
  for (column in count_delta) {
    overview[[paste0("delta_", column)]] <-
      overview[[paste0("canonical_", column)]] -
      overview[[paste0("baseline_", column)]]
  }
  overview <- merge(
    overview,
    shape_summary,
    by = c(
      "variable_id",
      "placement",
      "analysis_unit",
      "value_type",
      "comparison_status",
      "comparison_unit",
      "axis_geometry"
    ),
    all.x = TRUE,
    sort = FALSE
  )
  key_fields <- c(
    key,
    "baseline_n_keys",
    "canonical_n_keys",
    "common_n_keys",
    "baseline_only_n_keys",
    "canonical_only_n_keys",
    "baseline_n_participants",
    "canonical_n_participants",
    "baseline_n_participant_days",
    "canonical_n_participant_days"
  )
  key_table <- key_reconciliation[key_fields]
  names(key_table)[-(seq_along(key))] <- paste0(
    "key_",
    names(key_table)[-(seq_along(key))]
  )
  overview <- merge(
    overview,
    key_table,
    by = key,
    all.x = TRUE,
    sort = FALSE
  )
  paired_fields <- c(
    key,
    "n_common_keys",
    "n_paired_observed",
    "mean_difference",
    "sd_difference",
    "median_difference",
    "iqr_difference",
    "q025_difference",
    "q975_difference",
    "mean_absolute_difference",
    "root_mean_square_difference",
    "pearson_correlation",
    "spearman_correlation",
    "n_equal",
    "agreement_rate"
  )
  overview <- merge(
    overview,
    paired_summary[paired_fields],
    by = key,
    all.x = TRUE,
    sort = FALSE
  )
  overview[
    order(overview$variable_order, overview$placement),
    ,
    drop = FALSE
  ]
}

preanalysis_numeric_figure_data <- function(
  quantiles,
  crosswalk
) {
  retained <- quantiles$probability %in% c(0.05, 0.25, 0.5, 0.75, 0.95)
  data <- quantiles[retained, , drop = FALSE]
  metadata <- crosswalk[c(
    "variable_id",
    "variable_order",
    "metric_id",
    "manuscript_name",
    "abbreviation",
    "manuscript_category",
    "display_unit",
    "analytical_role",
    "variant_label",
    "domain",
    "figure_priority"
  )]
  data <- merge(data, metadata, by = "variable_id", all.x = TRUE)
  data <- data[
    data$figure_priority & data$axis_geometry == "linear",
    ,
    drop = FALSE
  ]
  canonical <- data[
    data$series == "canonical" & data$probability %in% c(0.25, 0.5, 0.75),
    c("variable_id", "placement", "probability", "value"),
    drop = FALSE
  ]
  canonical_wide <- reshape(
    canonical,
    idvar = c("variable_id", "placement"),
    timevar = "probability",
    direction = "wide"
  )
  names(canonical_wide) <- sub(
    "^value\\.",
    "canonical_q",
    names(canonical_wide)
  )
  data <- merge(
    data,
    canonical_wide,
    by = c("variable_id", "placement"),
    all.x = TRUE
  )
  denominator <- data$canonical_q0.75 - data$canonical_q0.25
  data$standardized_value <- ifelse(
    is.finite(denominator) & denominator > 0,
    (data$value - data$canonical_q0.5) / denominator,
    NA_real_
  )
  data$display_axis <- "Main-analysis median/IQR standardized value"
  data[
    is.finite(data$standardized_value),
    c(
      "variable_id",
      "variable_order",
      "metric_id",
      "manuscript_name",
      "abbreviation",
      "manuscript_category",
      "display_unit",
      "analytical_role",
      "variant_label",
      "domain",
      "placement",
      "analysis_unit",
      "series",
      "comparison_unit",
      "axis_geometry",
      "summary_interpretation",
      "probability",
      "value",
      "canonical_q0.25",
      "canonical_q0.5",
      "canonical_q0.75",
      "standardized_value",
      "display_axis",
      "n_finite"
    ),
    drop = FALSE
  ]
}

preanalysis_categorical_figure_data <- function(
  levels,
  crosswalk,
  maximum_levels = 8L
) {
  metadata <- crosswalk[c(
    "variable_id",
    "variable_order",
    "metric_id",
    "manuscript_name",
    "abbreviation",
    "manuscript_category",
    "display_unit",
    "analytical_role",
    "variant_label",
    "domain",
    "figure_priority"
  )]
  data <- merge(levels, metadata, by = "variable_id", all.x = TRUE)
  data <- data[
    data$figure_priority & data$level != "<no_estimable_rows>",
    ,
    drop = FALSE
  ]
  group <- interaction(
    data$variable_id,
    data$placement,
    data$series,
    drop = TRUE,
    lex.order = TRUE
  )
  ranks <- ave(
    -data$proportion,
    group,
    FUN = function(value) rank(value, ties.method = "first")
  )
  data <- data[ranks <= maximum_levels, , drop = FALSE]
  data[
    order(
      data$variable_order,
      data$placement,
      data$series,
      -data$proportion,
      data$level
    ),
    c(
      "variable_id",
      "variable_order",
      "metric_id",
      "manuscript_name",
      "abbreviation",
      "manuscript_category",
      "display_unit",
      "analytical_role",
      "variant_label",
      "domain",
      "placement",
      "analysis_unit",
      "series",
      "level",
      "n",
      "proportion",
      "n_participants",
      "n_participant_days"
    ),
    drop = FALSE
  ]
}
