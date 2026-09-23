# Validate and name the derived metric outputs.

assert_metric_long_unique <- function(data, object) {
  assert_columns(
    data,
    c(
      metric_participant_key,
      "local_date",
      "profile_variant",
      "analysis_unit",
      "metric"
    ),
    object = object
  )
  allowed_units <- c("participant_day", "participant")
  invalid_units <- unique(data$analysis_unit[
    is.na(data$analysis_unit) | !data$analysis_unit %in% allowed_units
  ])
  if (length(invalid_units) > 0L) {
    abort_pipeline("%s contains an unknown analysis unit", object)
  }
  participant_day <- dplyr::filter(
    data,
    .data$analysis_unit == "participant_day"
  )
  participant <- dplyr::filter(
    data,
    .data$analysis_unit == "participant"
  )
  if (nrow(participant_day) > 0L) {
    assert_unique_key(
      participant_day,
      c(metric_day_key, "profile_variant", "analysis_unit", "metric"),
      object = paste0(object, " participant-day rows")
    )
  }
  if (nrow(participant) > 0L) {
    assert_unique_key(
      participant,
      c(
        metric_participant_key,
        "profile_variant",
        "analysis_unit",
        "metric"
      ),
      object = paste0(object, " participant rows")
    )
  }
  invisible(data)
}

metric_output_paths <- function(metric_run_root, placement) {
  prefix <- paste0("metrics_", placement, "_")
  list(
    daily_rds = file.path(
      metric_run_root,
      paste0(prefix, "participant_day.rds")
    ),
    daily_csv = file.path(
      metric_run_root,
      paste0(prefix, "participant_day.csv")
    ),
    participant_rds = file.path(
      metric_run_root,
      paste0(prefix, "participant.rds")
    ),
    participant_csv = file.path(
      metric_run_root,
      paste0(prefix, "participant.csv")
    ),
    thirty_minute_rds = file.path(
      metric_run_root,
      paste0(prefix, "30_minute.rds")
    ),
    thirty_minute_csv = file.path(
      metric_run_root,
      paste0(prefix, "30_minute.csv")
    ),
    hourly_rds = file.path(
      metric_run_root,
      paste0(prefix, "one_hour.rds")
    ),
    hourly_csv = file.path(
      metric_run_root,
      paste0(prefix, "one_hour.csv")
    ),
    values = file.path(
      metric_run_root,
      paste0(prefix, "values_long.csv")
    ),
    admissibility = file.path(
      metric_run_root,
      paste0(prefix, "admissibility.csv")
    ),
    support = file.path(
      metric_run_root,
      paste0(prefix, "support_diagnostics.csv")
    ),
    censoring = file.path(
      metric_run_root,
      paste0(prefix, "censoring_diagnostics.csv")
    ),
    gaps = file.path(
      metric_run_root,
      paste0(prefix, "gap_diagnostics.csv")
    ),
    numerical_zero_audit = file.path(
      metric_run_root,
      paste0(prefix, "numerical_zero_diagnostics.csv")
    )
  )
}

validate_metric_builder_outputs <- function(result, placement) {
  expected_days <- nrow(result$daily_metrics)
  if (
    expected_days < 1L ||
      nrow(result$thirty_minute) != expected_days * 48L ||
      nrow(result$hourly) != expected_days * 24L
  ) {
    abort_pipeline(
      "%s metric grids are not rectangular over retained days",
      placement
    )
  }
  assert_unique_key(
    result$daily_metrics,
    metric_day_key,
    object = paste0(placement, " participant-day metrics")
  )
  assert_unique_key(
    result$participant_metrics,
    metric_participant_key,
    object = paste0(placement, " participant metrics")
  )
  assert_unique_key(
    result$thirty_minute,
    c(metric_day_key, "clock_bin"),
    object = paste0(placement, " 30-minute outcome grid")
  )
  assert_unique_key(
    result$hourly,
    c(metric_day_key, "clock_hour"),
    object = paste0(placement, " one-hour outcome grid")
  )
  assert_metric_long_unique(
    result$metric_values,
    object = paste0(placement, " long metric values")
  )
  assert_unique_key(
    result$support,
    c(metric_day_key, "profile_variant", "metric"),
    object = paste0(placement, " metric support diagnostics")
  )
  assert_metric_long_unique(
    result$admissibility,
    object = paste0(placement, " metric admissibility")
  )
  assert_unique_key(
    result$censoring,
    c(metric_day_key, "profile_variant"),
    object = paste0(placement, " censoring diagnostics")
  )
  assert_unique_key(
    result$gap,
    metric_day_key,
    object = paste0(placement, " gap diagnostics")
  )
  assert_columns(
    result$numerical_zero_audit,
    c(
      metric_day_key,
      "metric",
      "analysis_unit",
      "clock_hour",
      "raw_backtransformed_value_lx",
      "normalized_value_lx",
      "numerical_zero_tolerance_lx",
      "source_all_zero",
      "numerical_zero_rule",
      "raw_value_preserved"
    ),
    object = paste0(placement, " numerical-zero audit")
  )
  if (nrow(result$numerical_zero_audit) > 0L) {
    numerical_zero_key <- result$numerical_zero_audit
    invalid_clock_key <-
      (!numerical_zero_key$analysis_unit %in% c(
        "participant_day",
        "participant_day_window",
        "participant_hour"
      )) |
      (numerical_zero_key$analysis_unit %in% c(
        "participant_day",
        "participant_day_window"
      ) &
        !is.na(numerical_zero_key$clock_hour)) |
      (numerical_zero_key$analysis_unit == "participant_hour" &
        (
          is.na(numerical_zero_key$clock_hour) |
            numerical_zero_key$clock_hour < 0L |
            numerical_zero_key$clock_hour > 23L |
            numerical_zero_key$clock_hour !=
              as.integer(numerical_zero_key$clock_hour)
        ))
    if (anyNA(invalid_clock_key) || any(invalid_clock_key)) {
      abort_pipeline(
        "%s numerical-zero audit has an invalid analysis-unit/clock key",
        placement
      )
    }
    numerical_zero_key$clock_hour_key <- ifelse(
      numerical_zero_key$analysis_unit %in% c(
        "participant_day",
        "participant_day_window"
      ),
      -1L,
      as.integer(numerical_zero_key$clock_hour)
    )
    assert_unique_key(
      numerical_zero_key,
      c(
        metric_day_key,
        "metric",
        "analysis_unit",
        "clock_hour_key"
      ),
      object = paste0(placement, " numerical-zero audit")
    )
    numerical_zero <- result$numerical_zero_audit
    if (
      any(!is.finite(numerical_zero$raw_backtransformed_value_lx)) ||
        any(numerical_zero$raw_backtransformed_value_lx == 0) ||
        any(numerical_zero$normalized_value_lx != 0) ||
        any(!is.finite(numerical_zero$numerical_zero_tolerance_lx)) ||
        any(numerical_zero$numerical_zero_tolerance_lx <= 0) ||
        any(
          abs(numerical_zero$raw_backtransformed_value_lx) >
            numerical_zero$numerical_zero_tolerance_lx
        ) ||
        any(
          numerical_zero$raw_backtransformed_value_lx > 0 &
            !numerical_zero$source_all_zero
        ) ||
        any(
          numerical_zero$numerical_zero_rule !=
            numerical_zero_rule
        ) ||
        anyNA(numerical_zero$raw_value_preserved) ||
        !all(numerical_zero$raw_value_preserved)
    ) {
      abort_pipeline(
        "%s numerical-zero audit does not satisfy all_zero_source_roundoff_to_zero",
        placement
      )
    }
  }
  assert_unique_key(
    result$state_support_candidates,
    c(
      "position",
      "metric",
      "state_domain",
      "candidate_state_support_cutoff"
    ),
    object = paste0(placement, " state-support candidates")
  )
  prohibited <- c(
    names(result$daily_metrics),
    names(result$participant_metrics),
    names(result$thirty_minute),
    names(result$hourly),
    unique(result$metric_values$metric)
  )
  if (any(grepl("L5", prohibited, fixed = TRUE))) {
    abort_pipeline("Excluded darkest-five-hour output was produced")
  }
  invisible(TRUE)
}
