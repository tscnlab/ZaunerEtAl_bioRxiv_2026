validate_state_timezone <- function(
  datetime,
  timezone,
  column,
  object
) {
  if (
    length(timezone) != 1L ||
      is.na(timezone) ||
      !timezone %in% OlsonNames()
  ) {
    abort_pipeline("`timezone` must be one valid Olson time zone")
  }
  if (!inherits(datetime, "POSIXct")) {
    abort_pipeline("%s column `%s` must be POSIXct", object, column)
  }
  source_timezone <- lubridate::tz(datetime)
  if (!identical(source_timezone, timezone)) {
    abort_pipeline(
      "%s column `%s` has time zone '%s'; expected '%s'",
      object,
      column,
      source_timezone,
      timezone
    )
  }
  invisible(datetime)
}

new_interval_audit <- function(
  data,
  id_cols,
  interval_source,
  record_type,
  source_row_start,
  source_row_end,
  start,
  end,
  reason
) {
  output <- tibble::as_tibble(data[id_cols])
  output$interval_source <- rep(interval_source, nrow(output))
  output$record_type <- rep(record_type, nrow(output))
  output$source_row_start <- as.integer(source_row_start)
  output$source_row_end <- as.integer(source_row_end)
  output$start <- start
  output$end <- end
  output$reason <- as.character(reason)
  output
}

new_interval_preparation <- function(
  intervals,
  audit,
  source,
  timezone
) {
  structure(
    list(
      intervals = intervals,
      audit = audit,
      source = source,
      timezone = timezone,
      bounds = "[)"
    ),
    class = c("state_interval_preparation", "list")
  )
}

validate_interval_table <- function(
  intervals,
  id_cols = "Id",
  start_col = "start",
  end_col = "end",
  object = deparse(substitute(intervals))
) {
  required <- unique(c(id_cols, start_col, end_col))
  assert_columns(intervals, required, object = object)
  assert_no_missing_key(intervals, required, object = object)
  if (
    !inherits(intervals[[start_col]], "POSIXct") ||
      !inherits(intervals[[end_col]], "POSIXct")
  ) {
    abort_pipeline("%s start and end columns must be POSIXct", object)
  }
  assert_interval_order(intervals, start_col, end_col, object = object)
  assert_unique_key(intervals, required, object = object)

  ordered <- intervals |>
    dplyr::arrange(
      dplyr::across(dplyr::all_of(c(id_cols, start_col, end_col)))
    ) |>
    dplyr::group_by(dplyr::across(dplyr::all_of(id_cols))) |>
    dplyr::mutate(
      .previous_end = dplyr::lag(.data[[end_col]]),
      .overlap = !is.na(.data$.previous_end) &
        .data[[start_col]] < .data$.previous_end
    ) |>
    dplyr::ungroup()
  if (any(ordered$.overlap)) {
    abort_pipeline(
      "%s has %d overlapping interval(s)",
      object,
      sum(ordered$.overlap)
    )
  }
  dplyr::select(ordered, -dplyr::all_of(c(".previous_end", ".overlap")))
}

prepare_sleep_intervals <- function(
  sleep_diary,
  timezone,
  id_cols = "Id",
  sleepprep_col = "sleepprep",
  wake_col = "wake",
  evening_hours = 3,
  maximum_carry_forward_hours = 24,
  object = deparse(substitute(sleep_diary))
) {
  required <- unique(c(id_cols, sleepprep_col, wake_col))
  assert_columns(sleep_diary, required, object = object)
  assert_no_missing_key(sleep_diary, id_cols, object = object)
  validate_state_timezone(
    sleep_diary[[sleepprep_col]],
    timezone = timezone,
    column = sleepprep_col,
    object = object
  )
  validate_state_timezone(
    sleep_diary[[wake_col]],
    timezone = timezone,
    column = wake_col,
    object = object
  )
  if (
    length(evening_hours) != 1L ||
      !is.finite(evening_hours) ||
      evening_hours <= 0
  ) {
    abort_pipeline("`evening_hours` must be one positive finite value")
  }
  if (
    length(maximum_carry_forward_hours) != 1L ||
      !is.finite(maximum_carry_forward_hours) ||
      maximum_carry_forward_hours <= 0
  ) {
    abort_pipeline(
      "`maximum_carry_forward_hours` must be one positive finite value"
    )
  }

  source <- dplyr::ungroup(sleep_diary)
  source$.source_row <- seq_len(nrow(source))
  source$.start_utc <- lubridate::with_tz(
    source[[sleepprep_col]],
    tzone = "UTC"
  )
  source$.end_utc <- lubridate::with_tz(
    source[[wake_col]],
    tzone = "UTC"
  )
  start_finite <- is.na(source$.start_utc) |
    is.finite(as.numeric(source$.start_utc))
  end_finite <- is.na(source$.end_utc) |
    is.finite(as.numeric(source$.end_utc))
  source$.exclusion_reason <- dplyr::case_when(
    is.na(source$.start_utc) & is.na(source$.end_utc) ~
      "incomplete_sleep_interval_missing_both_bounds",
    is.na(source$.start_utc) ~ "incomplete_sleep_interval_missing_sleepprep",
    is.na(source$.end_utc) ~ "open_sleep_interval_missing_wake",
    !start_finite | !end_finite ~ "nonfinite_sleep_interval",
    source$.start_utc >= source$.end_utc ~ "nonpositive_sleep_interval",
    TRUE ~ NA_character_
  )

  invalid_source <- source[!is.na(source$.exclusion_reason), , drop = FALSE]
  source_audit <- new_interval_audit(
    data = invalid_source,
    id_cols = id_cols,
    interval_source = "sleep_diary",
    record_type = "source_sleep_record",
    source_row_start = invalid_source$.source_row,
    source_row_end = invalid_source$.source_row,
    start = invalid_source$.start_utc,
    end = invalid_source$.end_utc,
    reason = invalid_source$.exclusion_reason
  )
  valid_source <- source[is.na(source$.exclusion_reason), , drop = FALSE]
  assert_unique_key(
    valid_source,
    c(id_cols, ".start_utc", ".end_utc"),
    object = paste0(object, " valid sleep records")
  )

  evening_seconds <- evening_hours * 60 * 60
  sleep_intervals <- tibble::as_tibble(valid_source[id_cols])
  sleep_intervals$start <- valid_source$.start_utc
  sleep_intervals$end <- valid_source$.end_utc
  sleep_intervals$sleep <- "sleepprep"
  sleep_intervals$State.Brown <- "sleep"
  sleep_intervals$sleep_source_row_start <- valid_source$.source_row
  sleep_intervals$sleep_source_row_end <- valid_source$.source_row

  evening_intervals <- tibble::as_tibble(valid_source[id_cols])
  evening_intervals$start <- valid_source$.start_utc - evening_seconds
  evening_intervals$end <- valid_source$.start_utc
  evening_intervals$sleep <- "wake"
  evening_intervals$State.Brown <- "pre-sleep"
  evening_intervals$sleep_source_row_start <- valid_source$.source_row
  evening_intervals$sleep_source_row_end <- valid_source$.source_row

  ordered <- valid_source |>
    dplyr::arrange(
      dplyr::across(dplyr::all_of(c(id_cols, ".start_utc", ".end_utc")))
    ) |>
    dplyr::group_by(dplyr::across(dplyr::all_of(id_cols))) |>
    dplyr::mutate(
      .next_start_utc = dplyr::lead(.data$.start_utc),
      .next_source_row = dplyr::lead(.data$.source_row),
      .wake_start_utc = .data$.end_utc,
      .wake_end_utc = .data$.next_start_utc - evening_seconds,
      .carry_forward_hours = as.numeric(
        difftime(
          .data$.next_start_utc,
          .data$.wake_start_utc,
          units = "hours"
        )
      ),
      .wake_duration_hours = as.numeric(
        difftime(
          .data$.wake_end_utc,
          .data$.wake_start_utc,
          units = "hours"
        )
      ),
      .wake_exclusion_reason = dplyr::case_when(
        is.na(.data$.next_start_utc) ~ NA_character_,
        !is.finite(.data$.carry_forward_hours) |
          !is.finite(.data$.wake_duration_hours) ~
          "nonfinite_wake_interval",
        .data$.wake_duration_hours <= 0 ~ "nonpositive_wake_interval",
        .data$.carry_forward_hours > maximum_carry_forward_hours ~
          "wake_interval_exceeds_support_limit",
        TRUE ~ NA_character_
      )
    ) |>
    dplyr::ungroup()

  invalid_wake <- ordered[
    !is.na(ordered$.wake_exclusion_reason),
    ,
    drop = FALSE
  ]
  wake_audit <- new_interval_audit(
    data = invalid_wake,
    id_cols = id_cols,
    interval_source = "sleep_diary",
    record_type = "derived_wake_interval",
    source_row_start = invalid_wake$.source_row,
    source_row_end = invalid_wake$.next_source_row,
    start = invalid_wake$.wake_start_utc,
    end = invalid_wake$.wake_end_utc,
    reason = invalid_wake$.wake_exclusion_reason
  )

  valid_wake <- ordered[
    !is.na(ordered$.next_start_utc) &
      is.na(ordered$.wake_exclusion_reason),
    ,
    drop = FALSE
  ]
  wake_intervals <- tibble::as_tibble(valid_wake[id_cols])
  wake_intervals$start <- valid_wake$.wake_start_utc
  wake_intervals$end <- valid_wake$.wake_end_utc
  wake_intervals$sleep <- "wake"
  wake_intervals$State.Brown <- "wake"
  wake_intervals$sleep_source_row_start <- valid_wake$.source_row
  wake_intervals$sleep_source_row_end <- valid_wake$.next_source_row

  boundary_source <- valid_source |>
    dplyr::arrange(
      dplyr::across(dplyr::all_of(c(id_cols, ".start_utc", ".end_utc")))
    ) |>
    dplyr::group_by(dplyr::across(dplyr::all_of(id_cols))) |>
    dplyr::summarise(
      .first_start_utc = dplyr::first(.data$.start_utc),
      .first_source_row = dplyr::first(.data$.source_row),
      .last_end_utc = dplyr::last(.data$.end_utc),
      .last_source_row = dplyr::last(.data$.source_row),
      .groups = "drop"
    )
  first_local <- lubridate::with_tz(
    boundary_source$.first_start_utc,
    tzone = timezone
  )
  last_local <- lubridate::with_tz(
    boundary_source$.last_end_utc,
    tzone = timezone
  )

  initial_wake <- tibble::as_tibble(boundary_source[id_cols])
  initial_wake$start <- lubridate::with_tz(
    lubridate::floor_date(first_local, unit = "day"),
    tzone = "UTC"
  )
  initial_wake$end <- boundary_source$.first_start_utc - evening_seconds
  initial_wake$sleep <- "wake"
  initial_wake$State.Brown <- "wake"
  initial_wake$sleep_source_row_start <- NA_integer_
  initial_wake$sleep_source_row_end <- boundary_source$.first_source_row

  terminal_wake <- tibble::as_tibble(boundary_source[id_cols])
  terminal_wake$start <- boundary_source$.last_end_utc
  terminal_wake$end <- lubridate::with_tz(
    lubridate::ceiling_date(last_local, unit = "day"),
    tzone = "UTC"
  )
  terminal_wake$sleep <- "wake"
  terminal_wake$State.Brown <- "wake"
  terminal_wake$sleep_source_row_start <- boundary_source$.last_source_row
  terminal_wake$sleep_source_row_end <- NA_integer_

  valid_boundary_interval <- function(intervals) {
    is.finite(as.numeric(intervals$start)) &
      is.finite(as.numeric(intervals$end)) &
      intervals$start < intervals$end
  }
  initial_wake <- initial_wake[
    valid_boundary_interval(initial_wake),
    ,
    drop = FALSE
  ]
  terminal_wake <- terminal_wake[
    valid_boundary_interval(terminal_wake),
    ,
    drop = FALSE
  ]

  intervals <- dplyr::bind_rows(
    initial_wake,
    evening_intervals,
    sleep_intervals,
    wake_intervals,
    terminal_wake
  )
  intervals$sleep_state_source <- "sleep_diary"
  intervals$sleep_interval_bounds <- "[)"
  intervals <- validate_interval_table(
    intervals,
    id_cols = id_cols,
    start_col = "start",
    end_col = "end",
    object = "prepared sleep intervals"
  )
  audit <- dplyr::bind_rows(source_audit, wake_audit) |>
    dplyr::arrange(
      dplyr::across(dplyr::all_of(id_cols)),
      .data$source_row_start,
      .data$record_type
    )

  new_interval_preparation(
    intervals = intervals,
    audit = audit,
    source = "sleep_diary",
    timezone = timezone
  )
}

prepare_wear_intervals <- function(
  wear_log,
  timezone,
  id_cols = "Id",
  start_col = "start",
  end_col = "end",
  state_col = "state",
  allowed_states = c("off", "sleep", "site_leave"),
  object = deparse(substitute(wear_log))
) {
  required <- unique(c(id_cols, start_col, end_col, state_col))
  assert_columns(wear_log, required, object = object)
  assert_no_missing_key(wear_log, id_cols, object = object)
  validate_state_timezone(
    wear_log[[start_col]],
    timezone = timezone,
    column = start_col,
    object = object
  )
  validate_state_timezone(
    wear_log[[end_col]],
    timezone = timezone,
    column = end_col,
    object = object
  )
  if (
    !is.character(allowed_states) ||
      length(allowed_states) == 0L ||
      anyNA(allowed_states) ||
      anyDuplicated(allowed_states)
  ) {
    abort_pipeline("`allowed_states` must contain unique non-missing labels")
  }

  source <- dplyr::ungroup(wear_log)
  source$.source_row <- seq_len(nrow(source))
  source$.wear <- as.character(source[[state_col]])
  unknown_state <- !is.na(source$.wear) &
    !source$.wear %in% allowed_states
  if (any(unknown_state)) {
    abort_pipeline(
      "%s has unknown wear state(s): %s",
      object,
      paste(sort(unique(source$.wear[unknown_state])), collapse = ", ")
    )
  }
  source$.start_utc <- lubridate::with_tz(
    source[[start_col]],
    tzone = "UTC"
  )
  source$.end_utc <- lubridate::with_tz(
    source[[end_col]],
    tzone = "UTC"
  )
  start_finite <- is.na(source$.start_utc) |
    is.finite(as.numeric(source$.start_utc))
  end_finite <- is.na(source$.end_utc) |
    is.finite(as.numeric(source$.end_utc))
  source$.exclusion_reason <- dplyr::case_when(
    is.na(source$.start_utc) & is.na(source$.end_utc) ~
      "incomplete_wear_interval_missing_both_bounds",
    is.na(source$.start_utc) ~ "incomplete_wear_interval_missing_start",
    is.na(source$.end_utc) ~ "open_wear_interval_missing_end",
    is.na(source$.wear) ~ "incomplete_wear_interval_missing_state",
    !start_finite | !end_finite ~ "nonfinite_wear_interval",
    source$.start_utc >= source$.end_utc ~ "nonpositive_wear_interval",
    TRUE ~ NA_character_
  )

  invalid_source <- source[!is.na(source$.exclusion_reason), , drop = FALSE]
  audit <- new_interval_audit(
    data = invalid_source,
    id_cols = id_cols,
    interval_source = "wear_log",
    record_type = "source_wear_record",
    source_row_start = invalid_source$.source_row,
    source_row_end = invalid_source$.source_row,
    start = invalid_source$.start_utc,
    end = invalid_source$.end_utc,
    reason = invalid_source$.exclusion_reason
  )

  valid_source <- source[is.na(source$.exclusion_reason), , drop = FALSE]
  assert_unique_key(
    valid_source,
    c(id_cols, ".start_utc", ".end_utc"),
    object = paste0(object, " valid wear records")
  )
  intervals <- tibble::as_tibble(valid_source[id_cols])
  intervals$start <- valid_source$.start_utc
  intervals$end <- valid_source$.end_utc
  intervals$wear <- valid_source$.wear
  intervals$wear_source_row <- valid_source$.source_row
  intervals$wear_state_source <- "wear_log_provenance"
  intervals$wear_interval_bounds <- "[)"
  intervals <- validate_interval_table(
    intervals,
    id_cols = id_cols,
    start_col = "start",
    end_col = "end",
    object = "prepared wear intervals"
  )
  audit <- audit |>
    dplyr::arrange(
      dplyr::across(dplyr::all_of(id_cols)),
      .data$source_row_start
    )

  new_interval_preparation(
    intervals = intervals,
    audit = audit,
    source = "wear_log_provenance",
    timezone = timezone
  )
}

attach_states_checked <- function(
  data,
  intervals,
  stream_keys = "Id",
  object = deparse(substitute(intervals))
) {
  assert_columns(data, c(stream_keys, "Datetime"), object = "state target")
  validated <- validate_interval_table(
    intervals,
    id_cols = stream_keys,
    start_col = "start",
    end_col = "end",
    object = object
  )
  input_rows <- nrow(data)
  input_key <- c(stream_keys, "Datetime")
  assert_unique_key(data, input_key, object = "state target")

  target <- data |>
    dplyr::arrange(dplyr::across(dplyr::all_of(input_key))) |>
    dplyr::group_by(dplyr::across(dplyr::all_of(stream_keys)))
  state_data <- validated |>
    dplyr::group_by(dplyr::across(dplyr::all_of(stream_keys)))
  joined <- LightLogR::add_states(
    dataset = target,
    States.dataset = state_data,
    Datetime.colname = Datetime,
    start.colname = start,
    end.colname = end,
    force.tz = FALSE,
    bounds = "[)",
    leave.out = c("duration", "epoch")
  )

  if (nrow(joined) != input_rows) {
    abort_pipeline(
      paste0(
        "Joining %s changed target cardinality from %d to %d rows; ",
        "check interval overlap and stream keys"
      ),
      object,
      input_rows,
      nrow(joined)
    )
  }
  assert_unique_key(joined, input_key, object = "state-enriched target")
  joined
}

derive_measurement_context <- function(
  data,
  placement = c("glasses", "chest"),
  brown_state_col = "State.Brown",
  wear_col = "wear",
  medi_col = "MEDI",
  light_col = "LIGHT",
  saturation_threshold = 100000
) {
  placement <- match.arg(placement)
  required <- c(brown_state_col, wear_col, medi_col, light_col)
  assert_columns(data, required, object = "state-enriched light data")
  if (
    length(saturation_threshold) != 1L ||
      !is.finite(saturation_threshold) ||
      saturation_threshold <= 0
  ) {
    abort_pipeline("`saturation_threshold` must be one positive finite value")
  }
  if (!identical(as.numeric(saturation_threshold), 100000)) {
    abort_pipeline(
      paste0(
        "The approved ActLumus MEDI operating boundary is fixed at ",
        "100000 lx; analytical overrides are not permitted"
      )
    )
  }
  raw_names <- c("MEDI_raw", "LIGHT_raw")
  if (any(raw_names %in% names(data))) {
    abort_pipeline(
      "Raw analytical channel columns already exist: %s",
      paste(intersect(raw_names, names(data)), collapse = ", ")
    )
  }

  brown_state <- as.character(data[[brown_state_col]])
  wear_state <- as.character(data[[wear_col]])
  allowed_brown <- c("wake", "pre-sleep", "sleep")
  unknown_brown <- !is.na(brown_state) & !brown_state %in% allowed_brown
  if (any(unknown_brown)) {
    abort_pipeline(
      "Unknown diary Brown state(s): %s",
      paste(unique(brown_state[unknown_brown]), collapse = ", ")
    )
  }
  allowed_wear <- c("off", "sleep", "site_leave")
  unknown_wear <- !is.na(wear_state) & !wear_state %in% allowed_wear
  if (any(unknown_wear)) {
    abort_pipeline(
      "Unknown wear state(s): %s",
      paste(unique(wear_state[unknown_wear]), collapse = ", ")
    )
  }

  output <- data
  output$MEDI_raw <- data[[medi_col]]
  output$LIGHT_raw <- data[[light_col]]
  diary_sleep <- !is.na(brown_state) & brown_state == "sleep"
  invalid_nonwear <- !is.na(wear_state) &
    wear_state == "off" &
    !diary_sleep
  saturated_medi <- is.finite(output$MEDI_raw) &
    output$MEDI_raw >= saturation_threshold

  output$measurement_context <- dplyr::case_when(
    diary_sleep ~ "bedside_sleep_environment",
    invalid_nonwear ~ "invalid_nonwear",
    placement == "glasses" ~ "worn_near_eye",
    TRUE ~ "worn_chest"
  )
  output$measurement_context_source <- dplyr::case_when(
    diary_sleep ~ "sleep_diary",
    invalid_nonwear ~ "wearlog_off",
    TRUE ~ "placement_protocol"
  )
  output$invalid_nonwear <- invalid_nonwear
  output$wear_sleep_disagrees_with_diary <- !is.na(wear_state) &
    wear_state == "sleep" &
    !diary_sleep
  output$wear_off_during_diary_sleep <- !is.na(wear_state) &
    wear_state == "off" &
    diary_sleep
  output$wear_state_missing <- is.na(wear_state)
  output$medi_saturated <- saturated_medi
  output$exclusion_reason <- dplyr::case_when(
    invalid_nonwear ~ "nonwear_off_outside_sleep",
    saturated_medi ~ "medi_at_or_above_operating_limit",
    TRUE ~ NA_character_
  )

  output[[medi_col]][invalid_nonwear | saturated_medi] <- NA_real_
  output[[light_col]][invalid_nonwear] <- NA_real_
  output$valid_medi <- is.finite(output[[medi_col]])
  output$valid_light <- is.finite(output[[light_col]])
  output$valid_medi_light_pair <- output$valid_medi & output$valid_light
  output
}
