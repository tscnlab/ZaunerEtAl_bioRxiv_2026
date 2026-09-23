factorize_frame <- function(data, allowed_states = unname(state_labels)) {
  output <- data.table::copy(data)
  output[,
    analysis_state := factor(
      state_labels[raw_state],
      levels = allowed_states
    )
  ]
  output[, site := factor(as.character(site), levels = site_levels)]
  output[,
    day_type := factor(
      as.character(day_type),
      levels = c("Work day", "Free day")
    )
  ]
  output[, participant_id := factor(as.character(participant_id))]
  output[, behavioral_day_id := factor(as.character(behavioral_day_id))]
  if ("participant_calendar_day_id" %chin% names(output)) {
    output[,
      participant_calendar_day_id := factor(
        as.character(participant_calendar_day_id)
      )
    ]
  }
  output <- droplevels(as.data.frame(output))
  contrasts(output$analysis_state) <- stats::contr.sum(nlevels(
    output$analysis_state
  ))
  contrasts(output$site) <- stats::contr.sum(nlevels(output$site))
  contrasts(output$day_type) <- stats::contr.sum(nlevels(output$day_type))
  output
}

build_period_data <- function(
  coverage,
  expected_position,
  include_calendar = FALSE
) {
  observed_positions <- unique(as.character(coverage$position))
  if (
    length(observed_positions) != 1L ||
      !identical(observed_positions, expected_position)
  ) {
    stop(
      sprintf("Expected only `%s` coverage.", expected_position),
      call. = FALSE
    )
  }

  minute <- data.table::copy(
    coverage[State.Brown %chin% c("wake", "pre-sleep", "sleep")]
  )
  minute[, `:=`(
    site = as.character(site),
    Id = as.character(Id),
    local_date = as.Date(local_date),
    raw_state = as.character(State.Brown),
    period_source_start = as.integer(sleep_source_row_start),
    period_source_end = as.integer(sleep_source_row_end),
    valid_minute = is.finite(MEDI_eligible)
  )]
  minute[,
    brown_check := data.table::fcase(
      raw_state == "wake" & valid_minute,
      MEDI_eligible >= 250,
      raw_state == "pre-sleep" & valid_minute,
      MEDI_eligible <= 10,
      raw_state == "sleep" & valid_minute,
      MEDI_eligible <= 1,
      default = NA
    )
  ]
  minute[,
    brown_check_strict := data.table::fcase(
      raw_state == "wake" & valid_minute,
      MEDI_eligible > 250,
      raw_state == "pre-sleep" & valid_minute,
      MEDI_eligible < 10,
      raw_state == "sleep" & valid_minute,
      MEDI_eligible < 1,
      default = NA
    )
  ]
  minute[,
    threshold_lx := data.table::fcase(
      raw_state == "wake",
      250,
      raw_state == "pre-sleep",
      10,
      raw_state == "sleep",
      1,
      default = NA_real_
    )
  ]
  minute[, at_threshold := valid_minute & MEDI_eligible == threshold_lx]

  interval_key <- c(
    "site",
    "Id",
    "raw_state",
    "period_source_start",
    "period_source_end"
  )
  observed_interval <- minute[,
    .(
      projected_minutes = .N,
      valid_minutes = sum(valid_minute),
      brown_yes = sum(brown_check, na.rm = TRUE),
      brown_yes_strict = sum(brown_check_strict, na.rm = TRUE),
      threshold_equal_minutes = sum(at_threshold)
    ),
    by = interval_key
  ]

  observed_chunk <- minute[,
    .(
      projected_minutes = .N,
      valid_minutes = sum(valid_minute),
      brown_yes = sum(brown_check, na.rm = TRUE),
      brown_yes_strict = sum(brown_check_strict, na.rm = TRUE),
      threshold_equal_minutes = sum(at_threshold)
    ),
    by = c(interval_key, "local_date")
  ]

  wake_pairs <- unique(minute[
    raw_state == "wake" &
      !is.na(period_source_start) &
      !is.na(period_source_end),
    .(
      site,
      Id,
      behavior_source_row = period_source_start,
      next_sleep_source_row = period_source_end
    )
  ])
  if (
    anyDuplicated(wake_pairs[, .(site, Id, behavior_source_row)]) ||
      anyDuplicated(wake_pairs[, .(site, Id, next_sleep_source_row)])
  ) {
    stop("Wake source-row links are not one-to-one.", call. = FALSE)
  }

  behavior_record <- sleep_map[, .(
    site,
    Id,
    behavior_source_row = source_row,
    behavior_date,
    daytype_source_value,
    day_type,
    site_timezone,
    current_sleepprep_utc = sleepprep_utc,
    current_wake_utc = wake_utc
  )]
  next_record <- sleep_map[, .(
    site,
    Id,
    next_sleep_source_row = source_row,
    next_sleepprep_utc = sleepprep_utc,
    next_wake_utc = wake_utc
  )]
  cycle <- merge(
    wake_pairs,
    behavior_record,
    by = c("site", "Id", "behavior_source_row"),
    all.x = TRUE,
    sort = FALSE
  )
  cycle <- merge(
    cycle,
    next_record,
    by = c("site", "Id", "next_sleep_source_row"),
    all.x = TRUE,
    sort = FALSE
  )
  boundary_columns <- c(
    "current_sleepprep_utc",
    "current_wake_utc",
    "next_sleepprep_utc",
    "next_wake_utc"
  )
  if (any(vapply(cycle[, ..boundary_columns], anyNA, logical(1)))) {
    stop("A complete cycle lacks an exact diary boundary.", call. = FALSE)
  }

  common_columns <- c(
    "site",
    "Id",
    "behavior_source_row",
    "behavior_date",
    "daytype_source_value",
    "day_type",
    "site_timezone"
  )
  new_period <- function(
    data,
    variant,
    state_value,
    source_start,
    source_end,
    period_start,
    period_end
  ) {
    output <- data[, ..common_columns]
    output[, `:=`(
      linkage_variant = variant,
      raw_state = state_value,
      period_source_start = as.integer(source_start),
      period_source_end = as.integer(source_end),
      period_start_utc = period_start,
      period_end_utc = period_end
    )]
    output
  }

  variant_a <- "A_wake_then_following_presleep_sleep"
  variant_b <- "B_previous_sleep_wake_following_presleep"
  variant_c <- "C_previous_presleep_sleep_then_wake"

  period_skeleton <- data.table::rbindlist(
    list(
      new_period(
        cycle,
        variant_a,
        "wake",
        cycle$behavior_source_row,
        cycle$next_sleep_source_row,
        cycle$current_wake_utc,
        cycle$next_sleepprep_utc - 3 * 60 * 60
      ),
      new_period(
        cycle,
        variant_a,
        "pre-sleep",
        cycle$next_sleep_source_row,
        cycle$next_sleep_source_row,
        cycle$next_sleepprep_utc - 3 * 60 * 60,
        cycle$next_sleepprep_utc
      ),
      new_period(
        cycle,
        variant_a,
        "sleep",
        cycle$next_sleep_source_row,
        cycle$next_sleep_source_row,
        cycle$next_sleepprep_utc,
        cycle$next_wake_utc
      ),
      new_period(
        cycle,
        variant_b,
        "sleep",
        cycle$behavior_source_row,
        cycle$behavior_source_row,
        cycle$current_sleepprep_utc,
        cycle$current_wake_utc
      ),
      new_period(
        cycle,
        variant_b,
        "wake",
        cycle$behavior_source_row,
        cycle$next_sleep_source_row,
        cycle$current_wake_utc,
        cycle$next_sleepprep_utc - 3 * 60 * 60
      ),
      new_period(
        cycle,
        variant_b,
        "pre-sleep",
        cycle$next_sleep_source_row,
        cycle$next_sleep_source_row,
        cycle$next_sleepprep_utc - 3 * 60 * 60,
        cycle$next_sleepprep_utc
      ),
      new_period(
        cycle,
        variant_c,
        "pre-sleep",
        cycle$behavior_source_row,
        cycle$behavior_source_row,
        cycle$current_sleepprep_utc - 3 * 60 * 60,
        cycle$current_sleepprep_utc
      ),
      new_period(
        cycle,
        variant_c,
        "sleep",
        cycle$behavior_source_row,
        cycle$behavior_source_row,
        cycle$current_sleepprep_utc,
        cycle$current_wake_utc
      ),
      new_period(
        cycle,
        variant_c,
        "wake",
        cycle$behavior_source_row,
        cycle$next_sleep_source_row,
        cycle$current_wake_utc,
        cycle$next_sleepprep_utc - 3 * 60 * 60
      )
    ),
    use.names = TRUE
  )

  period_skeleton[,
    raw_duration_minutes := as.numeric(
      difftime(period_end_utc, period_start_utc, units = "mins")
    )
  ]
  period_skeleton[,
    period_tick_start_utc := as.POSIXct(
      ceiling(as.numeric(period_start_utc) / 60) * 60,
      origin = "1970-01-01",
      tz = "UTC"
    )
  ]
  period_skeleton[,
    period_tick_end_exclusive_utc := as.POSIXct(
      ceiling(as.numeric(period_end_utc) / 60) * 60,
      origin = "1970-01-01",
      tz = "UTC"
    )
  ]
  period_skeleton[,
    expected_minutes := as.integer(as.numeric(difftime(
      period_tick_end_exclusive_utc,
      period_tick_start_utc,
      units = "mins"
    )))
  ]
  if (
    any(period_skeleton$raw_duration_minutes <= 0) ||
      any(period_skeleton$expected_minutes <= 0L)
  ) {
    stop("A candidate period has a nonpositive duration.", call. = FALSE)
  }

  period_key <- c(
    "linkage_variant",
    "site",
    "Id",
    "behavior_source_row",
    "raw_state"
  )
  if (anyDuplicated(period_skeleton[, ..period_key])) {
    stop("The variant period key is duplicated.", call. = FALSE)
  }

  period <- merge(
    period_skeleton,
    observed_interval,
    by = interval_key,
    all.x = TRUE,
    sort = FALSE
  )
  count_columns <- c(
    "projected_minutes",
    "valid_minutes",
    "brown_yes",
    "brown_yes_strict",
    "threshold_equal_minutes"
  )
  for (column in count_columns) {
    data.table::set(period, which(is.na(period[[column]])), column, 0L)
  }
  if (
    any(period$projected_minutes > period$expected_minutes) ||
      any(period$valid_minutes > period$projected_minutes) ||
      any(period$brown_yes > period$valid_minutes) ||
      any(period$brown_yes_strict > period$valid_minutes)
  ) {
    stop("Observed period counts violate their exact bounds.", call. = FALSE)
  }

  period[, `:=`(
    brown_no = valid_minutes - brown_yes,
    brown_no_strict = valid_minutes - brown_yes_strict,
    support_fraction = valid_minutes / expected_minutes,
    brown_fraction = data.table::fifelse(
      valid_minutes > 0L,
      brown_yes / valid_minutes,
      NA_real_
    ),
    exact_zero = valid_minutes > 0L & brown_yes == 0L,
    exact_one = valid_minutes > 0L & brown_yes == valid_minutes,
    participant_id = paste(site, Id, sep = "::"),
    behavioral_day_id = paste(site, Id, behavior_source_row, sep = "::"),
    participant_state_id = paste(site, Id, raw_state, sep = "::"),
    placement = expected_position
  )]
  period[,
    support_band := data.table::fcase(
      valid_minutes == 0L,
      "0_no_valid",
      support_fraction < 0.10,
      "1_gt0_lt10pct",
      support_fraction < 0.25,
      "2_10_to_lt25pct",
      support_fraction < 0.50,
      "3_25_to_lt50pct",
      support_fraction < 0.80,
      "4_50_to_lt80pct",
      default = "5_ge80pct"
    )
  ]

  calendar_chunk <- NULL
  if (include_calendar) {
    variant_c_skeleton <- period_skeleton[linkage_variant == variant_c]
    expected_chunk <- data.table::rbindlist(
      lapply(
        seq_len(nrow(variant_c_skeleton)),
        function(index) {
          row <- variant_c_skeleton[index]
          minute_time <- seq.POSIXt(
            from = row$period_tick_start_utc[[1L]],
            to = row$period_tick_end_exclusive_utc[[1L]] - 60,
            by = "1 min"
          )
          data.table::data.table(
            linkage_variant = row$linkage_variant[[1L]],
            site = row$site[[1L]],
            Id = row$Id[[1L]],
            behavior_source_row = row$behavior_source_row[[1L]],
            behavior_date = row$behavior_date[[1L]],
            daytype_source_value = row$daytype_source_value[[1L]],
            day_type = row$day_type[[1L]],
            site_timezone = row$site_timezone[[1L]],
            raw_state = row$raw_state[[1L]],
            period_source_start = row$period_source_start[[1L]],
            period_source_end = row$period_source_end[[1L]],
            local_date = as.Date(minute_time, tz = row$site_timezone[[1L]])
          )[,
            .(expected_minutes = .N),
            by = .(
              linkage_variant,
              site,
              Id,
              behavior_source_row,
              behavior_date,
              daytype_source_value,
              day_type,
              site_timezone,
              raw_state,
              period_source_start,
              period_source_end,
              local_date
            )
          ]
        }
      ),
      use.names = TRUE
    )
    calendar_chunk <- merge(
      expected_chunk,
      observed_chunk,
      by = c(interval_key, "local_date"),
      all.x = TRUE,
      sort = FALSE
    )
    for (column in count_columns) {
      data.table::set(
        calendar_chunk,
        which(is.na(calendar_chunk[[column]])),
        column,
        0L
      )
    }
    calendar_chunk[, `:=`(
      brown_no = valid_minutes - brown_yes,
      brown_no_strict = valid_minutes - brown_yes_strict,
      support_fraction = valid_minutes / expected_minutes,
      brown_fraction = data.table::fifelse(
        valid_minutes > 0L,
        brown_yes / valid_minutes,
        NA_real_
      ),
      exact_zero = valid_minutes > 0L & brown_yes == 0L,
      exact_one = valid_minutes > 0L & brown_yes == valid_minutes,
      participant_id = paste(site, Id, sep = "::"),
      behavioral_day_id = paste(site, Id, behavior_source_row, sep = "::"),
      participant_state_id = paste(site, Id, raw_state, sep = "::"),
      participant_calendar_day_id = paste(site, Id, local_date, sep = "::"),
      placement = expected_position
    )]
  }

  list(
    minute = minute,
    cycle = cycle,
    period = period,
    calendar_chunk = calendar_chunk
  )
}
