# Validate coverage and summarize sample flow.

validate_aligned_coverage_input <- function(
  data,
  placement,
  object = deparse(substitute(data))
) {
  if (!is.data.frame(data)) {
    abort_pipeline("%s must be a data frame", object)
  }
  required <- c(
    "site",
    "Id",
    "position",
    "datetime_utc",
    "datetime_wall",
    "local_date",
    "clock_minute",
    "utc_offset_minutes",
    "is_dst",
    "MEDI",
    "LIGHT",
    "MEDI_raw",
    "LIGHT_raw",
    "invalid_nonwear",
    "medi_saturated",
    "valid_medi",
    "valid_light",
    "valid_medi_light_pair"
  )
  assert_columns(data, required, object = object)
  assert_no_missing_key(
    data,
    c("site", "Id", "position", "datetime_utc", "local_date", "clock_minute"),
    object = object
  )
  assert_unique_key(
    data,
    c("site", "Id", "position", "datetime_utc"),
    object = object
  )
  if (
    !inherits(data$datetime_utc, "POSIXct") ||
      !inherits(data$datetime_wall, "POSIXct") ||
      !inherits(data$local_date, "Date")
  ) {
    abort_pipeline(
      paste0(
        "%s must contain POSIXct `datetime_utc`/`datetime_wall` ",
        "and Date `local_date`"
      ),
      object
    )
  }
  if (
    !identical(lubridate::tz(data$datetime_utc), "UTC") ||
      !identical(lubridate::tz(data$datetime_wall), "UTC")
  ) {
    abort_pipeline(
      "%s true and pseudo-local datetime axes must both use UTC storage",
      object
    )
  }
  if (any(data$position != placement)) {
    abort_pipeline(
      "%s contains a position other than '%s'",
      object,
      placement
    )
  }
  signal_columns <- c("MEDI", "LIGHT", "MEDI_raw", "LIGHT_raw")
  non_numeric <- signal_columns[
    !vapply(data[signal_columns], is.numeric, logical(1))
  ]
  if (length(non_numeric) > 0L) {
    abort_pipeline(
      "%s signal column(s) must be numeric: %s",
      object,
      paste(non_numeric, collapse = ", ")
    )
  }
  infinite <- vapply(
    data[signal_columns],
    function(column) any(is.infinite(column)),
    logical(1)
  )
  if (any(infinite)) {
    abort_pipeline(
      "%s contains infinite values in: %s",
      object,
      paste(names(infinite)[infinite], collapse = ", ")
    )
  }
  flag_columns <- c(
    "invalid_nonwear",
    "medi_saturated",
    "valid_medi",
    "valid_light",
    "valid_medi_light_pair"
  )
  invalid_flags <- flag_columns[
    !vapply(
      data[flag_columns],
      function(column) is.logical(column) && !anyNA(column),
      logical(1)
    )
  ]
  if (length(invalid_flags) > 0L) {
    abort_pipeline(
      "%s validity flag(s) must be complete logical: %s",
      object,
      paste(invalid_flags, collapse = ", ")
    )
  }
  expected_saturated <- is.finite(data$MEDI_raw) &
    data$MEDI_raw >= 100000
  if (!identical(as.logical(data$medi_saturated), expected_saturated)) {
    abort_pipeline(
      "%s does not implement the approved MEDI >=100000 boundary",
      object
    )
  }
  if (any(is.finite(data$MEDI) & data$MEDI >= 100000)) {
    abort_pipeline(
      "%s retains analytical MEDI at or above 100000 lx",
      object
    )
  }
  if (any(expected_saturated & is.finite(data$MEDI))) {
    abort_pipeline(
      "%s retains operating-boundary-invalid MEDI values",
      object
    )
  }
  saturation_only <- expected_saturated & !data$invalid_nonwear
  if (
    any(
      is.finite(data$LIGHT_raw[saturation_only]) &
        !is.finite(data$LIGHT[saturation_only])
    )
  ) {
    abort_pipeline(
      "%s incorrectly applies the MEDI operating boundary to LIGHT",
      object
    )
  }
  expected_valid_medi <- is.finite(data$MEDI)
  expected_valid_light <- is.finite(data$LIGHT)
  if (
    !identical(as.logical(data$valid_medi), expected_valid_medi) ||
      !identical(as.logical(data$valid_light), expected_valid_light) ||
      !identical(
        as.logical(data$valid_medi_light_pair),
        expected_valid_medi & expected_valid_light
      )
  ) {
    abort_pipeline("%s has inconsistent signal-validity flags", object)
  }
  expected_wall <- as.POSIXct(data$local_date, tz = "UTC") +
    as.integer(data$clock_minute) * 60
  invalid_clock <- data$clock_minute < 0 |
    data$clock_minute > 1439 |
    data$clock_minute != as.integer(data$clock_minute)
  if (
    any(invalid_clock) ||
      any(as.numeric(data$datetime_wall) != as.numeric(expected_wall))
  ) {
    abort_pipeline("%s has inconsistent pseudo-local wall-clock keys", object)
  }
  invisible(data)
}

add_eligible_signal_channels <- function(
  aligned,
  coverage_result,
  object = deparse(substitute(aligned))
) {
  real_minutes <- dplyr::ungroup(coverage_result$real_minutes)
  if (nrow(real_minutes) != nrow(aligned)) {
    abort_pipeline("%s lost real-time rows during coverage mapping", object)
  }
  if (!identical(real_minutes$datetime_utc, aligned$datetime_utc)) {
    abort_pipeline(
      "%s changed true-UTC row order during coverage mapping",
      object
    )
  }
  for (column in names(aligned)) {
    if (!identical(real_minutes[[column]], aligned[[column]])) {
      abort_pipeline(
        "%s changed pre-coverage column `%s` during coverage mapping",
        object,
        column
      )
    }
  }

  real_minutes$MEDI_precoverage <- real_minutes$MEDI
  real_minutes$LIGHT_precoverage <- real_minutes$LIGHT
  real_minutes$MEDI_precoverage_observed <- is.finite(
    real_minutes$MEDI_precoverage
  )
  real_minutes$LIGHT_precoverage_observed <- is.finite(
    real_minutes$LIGHT_precoverage
  )
  real_minutes$MEDI_coverage_eligible <-
    real_minutes$coverage_period_eligible &
    real_minutes$MEDI_precoverage_observed
  real_minutes$LIGHT_coverage_eligible <-
    real_minutes$coverage_period_eligible &
    real_minutes$LIGHT_precoverage_observed
  real_minutes$MEDI_eligible <- ifelse(
    real_minutes$coverage_period_eligible,
    real_minutes$MEDI_precoverage,
    NA_real_
  )
  real_minutes$LIGHT_eligible <- ifelse(
    real_minutes$coverage_period_eligible,
    real_minutes$LIGHT_precoverage,
    NA_real_
  )
  real_minutes$MEDI_eligibility_reason <- dplyr::case_when(
    !real_minutes$MEDI_precoverage_observed ~ "signal_invalidity",
    real_minutes$day_all_zero_medi_excluded ~ "all_zero_medi_day",
    !real_minutes$day_eligible ~ "day_failure",
    TRUE ~ NA_character_
  )
  real_minutes$LIGHT_eligibility_reason <- dplyr::case_when(
    !real_minutes$LIGHT_precoverage_observed ~ "signal_invalidity",
    real_minutes$day_all_zero_medi_excluded ~ "all_zero_medi_day",
    !real_minutes$day_eligible ~ "day_failure",
    TRUE ~ NA_character_
  )

  if (
    any(
      !real_minutes$coverage_period_eligible &
        (is.finite(real_minutes$MEDI_eligible) |
          is.finite(real_minutes$LIGHT_eligible))
    )
  ) {
    abort_pipeline(
      "%s retained an eligible signal outside an eligible coverage period",
      object
    )
  }
  if (
    !identical(
      is.finite(real_minutes$MEDI_eligible),
      real_minutes$MEDI_coverage_eligible
    ) ||
      !identical(
        is.finite(real_minutes$LIGHT_eligible),
        real_minutes$LIGHT_coverage_eligible
      )
  ) {
    abort_pipeline("%s has inconsistent signal eligibility flags", object)
  }
  assert_unique_key(
    real_minutes,
    c("site", "Id", "position", "datetime_utc"),
    object = "coverage-annotated real-time minutes"
  )
  real_minutes
}

clock_label <- function(clock_minute) {
  sprintf(
    "%02d:%02d",
    as.integer(clock_minute %/% 60L),
    as.integer(clock_minute %% 60L)
  )
}

coverage_gap_runs <- function(
  wall_grid,
  placement,
  object = deparse(substitute(wall_grid))
) {
  required <- c(
    "site",
    "Id",
    "position",
    "local_date",
    "clock_minute",
    "datetime_wall",
    "minute_present",
    "source_real_minutes",
    "dst_fold",
    "coverage_signal_observed",
    "hour_eligible",
    "day_eligible_without_all_zero_screen",
    "day_all_zero_medi_excluded",
    "day_eligible",
    "MEDI",
    "LIGHT"
  )
  assert_columns(wall_grid, required, object = object)
  assert_unique_key(
    wall_grid,
    c("site", "Id", "position", "local_date", "clock_minute"),
    object = object
  )
  if (any(wall_grid$position != placement)) {
    abort_pipeline(
      "%s contains a position other than '%s'",
      object,
      placement
    )
  }

  reason_specs <- list(
    list(
      reason = "raw_absence",
      reason_class = "availability",
      signal = "row",
      include = !wall_grid$minute_present
    ),
    list(
      reason = "signal_invalidity",
      reason_class = "measurement",
      signal = "MEDI",
      include = wall_grid$minute_present & !is.finite(wall_grid$MEDI)
    ),
    list(
      reason = "signal_invalidity",
      reason_class = "measurement",
      signal = "LIGHT",
      include = wall_grid$minute_present & !is.finite(wall_grid$LIGHT)
    ),
    list(
      reason = "all_zero_medi_day",
      reason_class = "plausibility",
      signal = "MEDI",
      include = wall_grid$day_all_zero_medi_excluded
    ),
    list(
      reason = "day_failure",
      reason_class = "coverage",
      signal = "MEDI",
      include = !wall_grid$day_eligible_without_all_zero_screen
    )
  )
  gap_minutes <- dplyr::bind_rows(lapply(reason_specs, function(specification) {
    selected <- wall_grid[specification$include, , drop = FALSE]
    if (nrow(selected) == 0L) {
      return(NULL)
    }
    dplyr::mutate(
      selected,
      gap_reason = specification$reason,
      reason_class = specification$reason_class,
      signal = specification$signal
    )
  }))
  if (nrow(gap_minutes) == 0L) {
    return(tibble::tibble(
      site = character(),
      Id = character(),
      position = character(),
      local_date = as.Date(character()),
      gap_reason = character(),
      reason_class = character(),
      signal = character(),
      run_number = integer(),
      start_clock_minute = integer(),
      end_clock_minute = integer(),
      start_clock = character(),
      end_clock_exclusive = character(),
      start_datetime_wall = as.POSIXct(character(), tz = "UTC"),
      end_datetime_wall_exclusive = as.POSIXct(character(), tz = "UTC"),
      wall_minutes = integer(),
      source_real_minutes = integer(),
      dst_fold_minutes = integer(),
      finite_medi_wall_minutes = integer(),
      finite_light_wall_minutes = integer()
    ))
  }

  keys <- c(
    "site",
    "Id",
    "position",
    "local_date",
    "gap_reason",
    "reason_class",
    "signal"
  )
  runs <- gap_minutes |>
    dplyr::arrange(
      dplyr::across(dplyr::all_of(keys)),
      .data$clock_minute
    ) |>
    dplyr::group_by(dplyr::across(dplyr::all_of(keys))) |>
    dplyr::mutate(
      .new_run = dplyr::row_number() == 1L |
        .data$clock_minute != dplyr::lag(.data$clock_minute) + 1L,
      run_number = cumsum(.data$.new_run)
    ) |>
    dplyr::group_by(
      dplyr::across(dplyr::all_of(keys)),
      .data$run_number
    ) |>
    dplyr::summarise(
      start_clock_minute = min(.data$clock_minute),
      end_clock_minute = max(.data$clock_minute),
      start_datetime_wall = min(.data$datetime_wall),
      end_datetime_wall_exclusive = max(.data$datetime_wall) + 60,
      wall_minutes = dplyr::n(),
      source_real_minutes = sum(.data$source_real_minutes),
      dst_fold_minutes = sum(.data$dst_fold),
      finite_medi_wall_minutes = sum(is.finite(.data$MEDI)),
      finite_light_wall_minutes = sum(is.finite(.data$LIGHT)),
      .groups = "drop"
    ) |>
    dplyr::mutate(
      start_clock = clock_label(.data$start_clock_minute),
      end_clock_exclusive = clock_label(.data$end_clock_minute + 1L),
      .after = "end_clock_minute"
    ) |>
    dplyr::arrange(
      .data$site,
      .data$Id,
      .data$position,
      .data$local_date,
      .data$gap_reason,
      .data$signal,
      .data$start_clock_minute
    )
  if (any(runs$wall_minutes < 1L)) {
    abort_pipeline("%s produced an empty gap run", object)
  }
  runs
}

sample_flow_counts <- function(data, include) {
  selected <- data[include, , drop = FALSE]
  if (nrow(selected) == 0L) {
    return(tibble::tibble(
      participants = 0L,
      participant_days = 0L,
      true_utc_minutes = 0L,
      wall_minutes = 0L,
      finite_medi_minutes = 0L,
      finite_light_minutes = 0L
    ))
  }
  tibble::tibble(
    participants = nrow(dplyr::distinct(
      selected,
      .data$site,
      .data$Id
    )),
    participant_days = nrow(dplyr::distinct(
      selected,
      .data$site,
      .data$Id,
      .data$position,
      .data$local_date
    )),
    true_utc_minutes = nrow(selected),
    wall_minutes = nrow(dplyr::distinct(
      selected,
      .data$site,
      .data$Id,
      .data$position,
      .data$local_date,
      .data$clock_minute
    )),
    finite_medi_minutes = sum(is.finite(selected$MEDI_precoverage)),
    finite_light_minutes = sum(is.finite(selected$LIGHT_precoverage))
  )
}

coverage_sample_flow <- function(
  data,
  placement,
  object = deparse(substitute(data))
) {
  required <- c(
    "site",
    "Id",
    "position",
    "local_date",
    "clock_minute",
    "MEDI_precoverage",
    "LIGHT_precoverage",
    "hour_eligible",
    "day_all_finite_medi_zero",
    "day_all_zero_medi_excluded",
    "day_eligible_without_all_zero_screen",
    "day_eligible",
    "day_eligible_after_hour",
    "coverage_period_eligible",
    "all_zero_medi_inclusive_sensitivity_period_eligible",
    "hourly_metric_period_eligible",
    "hour_screened_coverage_period_eligible",
    "MEDI_coverage_eligible",
    "LIGHT_coverage_eligible"
  )
  assert_columns(data, required, object = object)
  stages <- list(
    list(
      order = 1L,
      branch = "common",
      label = "aligned_real_minutes",
      include = rep(TRUE, nrow(data))
    ),
    list(
      order = 2L,
      branch = "MEDI",
      label = "precoverage_medi_finite",
      include = is.finite(data$MEDI_precoverage)
    ),
    list(
      order = 3L,
      branch = "LIGHT",
      label = "precoverage_light_finite",
      include = is.finite(data$LIGHT_precoverage)
    ),
    list(
      order = 4L,
      branch = "coverage_sensitivity",
      label = "all_zero_medi_inclusive_sensitivity_real_minutes",
      include = data$all_zero_medi_inclusive_sensitivity_period_eligible
    ),
    list(
      order = 5L,
      branch = "coverage",
      label = "primary_day_eligible_real_minutes",
      include = data$coverage_period_eligible
    ),
    list(
      order = 6L,
      branch = "MEDI",
      label = "medi_eligible_real_minutes",
      include = data$MEDI_coverage_eligible
    ),
    list(
      order = 7L,
      branch = "LIGHT",
      label = "light_eligible_real_minutes",
      include = data$LIGHT_coverage_eligible
    ),
    list(
      order = 8L,
      branch = "hourly_metric",
      label = "hourly_metric_eligible_real_minutes",
      include = data$hourly_metric_period_eligible
    ),
    list(
      order = 9L,
      branch = "coverage_sensitivity",
      label = "hour_screened_sensitivity_real_minutes",
      include = data$hour_screened_coverage_period_eligible
    )
  )
  sites <- sort(unique(data$site))
  scopes <- c(sites, "ALL")
  dplyr::bind_rows(lapply(scopes, function(site_label) {
    scope_include <- if (identical(site_label, "ALL")) {
      rep(TRUE, nrow(data))
    } else {
      data$site == site_label
    }
    dplyr::bind_rows(lapply(stages, function(stage) {
      counts <- sample_flow_counts(data, scope_include & stage$include)
      dplyr::mutate(
        counts,
        placement = placement,
        scope = if (identical(site_label, "ALL")) "overall" else "site",
        site = site_label,
        stage_order = stage$order,
        stage_branch = stage$branch,
        stage = stage$label,
        .before = 1L
      )
    }))
  })) |>
    dplyr::arrange(
      .data$placement,
      dplyr::desc(.data$scope),
      .data$site,
      .data$stage_order
    )
}

validate_coverage_outputs <- function(
  aligned,
  eligible,
  hourly,
  daily,
  placement
) {
  if (nrow(aligned) != nrow(eligible)) {
    abort_pipeline(
      "%s coverage output changed the real-time row count",
      placement
    )
  }
  assert_unique_key(
    eligible,
    c("site", "Id", "position", "datetime_utc"),
    object = paste0(placement, " coverage output")
  )
  assert_unique_key(
    hourly,
    c("site", "Id", "position", "local_date", "clock_hour"),
    object = paste0(placement, " hourly coverage")
  )
  assert_unique_key(
    daily,
    c("site", "Id", "position", "local_date"),
    object = paste0(placement, " daily coverage")
  )
  if (
    anyNA(eligible$hour_eligible) ||
      anyNA(eligible$day_eligible) ||
      anyNA(eligible$day_all_zero_medi_excluded) ||
      anyNA(eligible$coverage_period_eligible)
  ) {
    abort_pipeline(
      "%s coverage output has missing eligibility flags",
      placement
    )
  }
  if (
    any(
      eligible$coverage_period_eligible !=
        eligible$day_eligible
    ) ||
      any(
        eligible$all_zero_medi_inclusive_sensitivity_period_eligible !=
          eligible$day_eligible_without_all_zero_screen
      )
  ) {
    abort_pipeline(
      paste0(
        "%s coverage-period or all-zero-inclusive sensitivity flags ",
        "are internally inconsistent"
      ),
      placement
    )
  }
  if (
    any(
      eligible$day_all_zero_medi_excluded &
        (
          !eligible$day_all_finite_medi_zero |
            !eligible$day_eligible_without_all_zero_screen |
            eligible$day_eligible
        )
    )
  ) {
    abort_pipeline(
      "%s all-zero melEDI exclusion flags are internally inconsistent",
      placement
    )
  }
  if (
    any(
      eligible$hourly_metric_period_eligible !=
        (eligible$day_eligible & eligible$hour_eligible)
    ) ||
      any(
        eligible$hour_screened_coverage_period_eligible !=
          (eligible$day_eligible_after_hour & eligible$hour_eligible)
      )
  ) {
    abort_pipeline(
      "%s hourly or hour-screened sensitivity flags are inconsistent",
      placement
    )
  }
  invisible(TRUE)
}
