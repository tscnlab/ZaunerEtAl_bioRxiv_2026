# Canonical order: annotate both time axes, aggregate raw subepochs, align
# measurement state and apply signal limits, then evaluate coarse coverage.
# The wall-clock representation below is derived only for coverage decisions;
# it never replaces the real-time rows used by elapsed-time metrics.

validate_coverage_fraction <- function(
  x,
  argument = deparse(substitute(x))
) {
  if (
    !is.numeric(x) ||
      length(x) != 1L ||
      is.na(x) ||
      !is.finite(x) ||
      x < 0 ||
      x > 1
  ) {
    abort_pipeline("`%s` must be one finite value in [0, 1]", argument)
  }
  invisible(x)
}

validate_positive_integer <- function(
  x,
  argument = deparse(substitute(x))
) {
  if (
    !is.numeric(x) ||
      length(x) != 1L ||
      is.na(x) ||
      !is.finite(x) ||
      x < 1 ||
      x != as.integer(x)
  ) {
    abort_pipeline("`%s` must be one positive integer", argument)
  }
  invisible(as.integer(x))
}

infer_regular_stream_epoch <- function(
  datetime_utc,
  maximum_epoch_seconds = 60,
  tolerance = 1e-6,
  object = deparse(substitute(datetime_utc))
) {
  if (!inherits(datetime_utc, "POSIXct")) {
    abort_pipeline("%s must be POSIXct", object)
  }
  if (length(datetime_utc) < 2L) {
    abort_pipeline(
      "%s needs at least two timestamps to infer its source epoch",
      object
    )
  }
  numeric_time <- sort(unique(as.numeric(datetime_utc)))
  if (length(numeric_time) < 2L || any(!is.finite(numeric_time))) {
    abort_pipeline(
      "%s needs at least two unique finite timestamps to infer its source epoch",
      object
    )
  }
  differences <- diff(numeric_time)
  local_differences <- differences[
    differences > tolerance &
      differences <= maximum_epoch_seconds + tolerance
  ]
  if (length(local_differences) == 0L) {
    abort_pipeline(
      "%s has no positive timestamp difference at or below %d seconds",
      object,
      maximum_epoch_seconds
    )
  }
  integer_differences <- round(local_differences)
  if (any(abs(local_differences - integer_differences) > tolerance)) {
    abort_pipeline("%s has a non-integer source epoch", object)
  }
  frequency <- table(integer_differences)
  modal_differences <- as.integer(names(frequency)[
    frequency == max(frequency)
  ])
  epoch_seconds <- min(modal_differences)
  if (
    epoch_seconds < 1L ||
      epoch_seconds > maximum_epoch_seconds ||
      maximum_epoch_seconds %% epoch_seconds != 0L
  ) {
    abort_pipeline(
      paste0(
        "%s has inferred epoch %d seconds, which does not divide ",
        "the %d-second aggregation interval"
      ),
      object,
      epoch_seconds,
      maximum_epoch_seconds
    )
  }
  incompatible <- abs(
    local_differences / epoch_seconds - round(local_differences / epoch_seconds)
  ) >
    tolerance
  if (any(incompatible)) {
    abort_pipeline(
      "%s has local timestamp differences incompatible with epoch %d seconds",
      object,
      epoch_seconds
    )
  }
  epoch_seconds
}

infer_stream_epoch_table <- function(
  data,
  id_cols = c("site", "Id", "position"),
  datetime_utc_col = "datetime_utc",
  object = deparse(substitute(data))
) {
  assert_columns(data, c(id_cols, datetime_utc_col), object = object)
  assert_no_missing_key(data, c(id_cols, datetime_utc_col), object = object)
  data |>
    dplyr::group_by(dplyr::across(dplyr::all_of(id_cols))) |>
    dplyr::summarise(
      stream_epoch_seconds = infer_regular_stream_epoch(
        .data[[datetime_utc_col]],
        object = paste0(object, " participant stream")
      ),
      .groups = "drop"
    ) |>
    dplyr::mutate(
      expected_subepochs = as.integer(60L / .data$stream_epoch_seconds)
    )
}

aggregate_native_epoch_to_minute <- function(
  data,
  signal_cols = c("MEDI", "LIGHT"),
  id_cols = c("site", "Id", "position"),
  expected_subepochs = NULL,
  minimum_finite_subepochs = NULL,
  minimum_finite_fraction = 1,
  datetime_utc_col = "datetime_utc",
  datetime_wall_col = "datetime_wall",
  implicit_col = "is.implicit",
  object = deparse(substitute(data))
) {
  if (!is.null(expected_subepochs)) {
    expected_subepochs <- validate_positive_integer(
      expected_subepochs,
      argument = "expected_subepochs"
    )
    if (60L %% expected_subepochs != 0L) {
      abort_pipeline("`expected_subepochs` must divide 60 exactly")
    }
  }
  if (!is.null(minimum_finite_subepochs)) {
    minimum_finite_subepochs <- validate_positive_integer(
      minimum_finite_subepochs,
      argument = "minimum_finite_subepochs"
    )
  }
  validate_coverage_fraction(
    minimum_finite_fraction,
    argument = "minimum_finite_fraction"
  )
  if (minimum_finite_fraction <= 0) {
    abort_pipeline("`minimum_finite_fraction` must be greater than zero")
  }
  if (
    !is.character(signal_cols) ||
      length(signal_cols) == 0L ||
      anyNA(signal_cols) ||
      anyDuplicated(signal_cols)
  ) {
    abort_pipeline(
      "`signal_cols` must contain unique non-missing column names"
    )
  }
  if (
    !is.character(id_cols) ||
      length(id_cols) == 0L ||
      anyNA(id_cols) ||
      anyDuplicated(id_cols)
  ) {
    abort_pipeline("`id_cols` must contain unique non-missing column names")
  }

  required <- unique(c(
    id_cols,
    signal_cols,
    datetime_utc_col,
    datetime_wall_col,
    "utc_offset_minutes",
    "is_dst"
  ))
  assert_columns(data, required, object = object)
  assert_no_missing_key(
    data,
    c(id_cols, datetime_utc_col, datetime_wall_col),
    object = object
  )
  if (
    !inherits(data[[datetime_utc_col]], "POSIXct") ||
      !inherits(data[[datetime_wall_col]], "POSIXct")
  ) {
    abort_pipeline(
      "%s columns `%s` and `%s` must be POSIXct",
      object,
      datetime_utc_col,
      datetime_wall_col
    )
  }
  if (!identical(lubridate::tz(data[[datetime_utc_col]]), "UTC")) {
    abort_pipeline("%s column `%s` must use UTC", object, datetime_utc_col)
  }
  if (!identical(lubridate::tz(data[[datetime_wall_col]]), "UTC")) {
    abort_pipeline(
      paste0(
        "%s column `%s` must use UTC as its pseudo-local wall-clock ",
        "display zone"
      ),
      object,
      datetime_wall_col
    )
  }
  non_numeric <- signal_cols[
    !vapply(data[signal_cols], is.numeric, logical(1))
  ]
  if (length(non_numeric) > 0L) {
    abort_pipeline(
      "%s signal column(s) must be numeric: %s",
      object,
      paste(non_numeric, collapse = ", ")
    )
  }
  assert_unique_key(
    data,
    c(id_cols, datetime_utc_col),
    object = paste0(object, " ten-second observations")
  )

  input <- dplyr::ungroup(data)
  input$.minute_utc <- lubridate::floor_date(
    input[[datetime_utc_col]],
    unit = "minute"
  )
  input$.minute_wall <- lubridate::floor_date(
    input[[datetime_wall_col]],
    unit = "minute"
  )
  input$.implicit_subepoch <- if (implicit_col %in% names(input)) {
    input[[implicit_col]] %in% TRUE
  } else {
    FALSE
  }

  stream_epochs <- if (is.null(expected_subepochs)) {
    infer_stream_epoch_table(
      input,
      id_cols = id_cols,
      datetime_utc_col = datetime_utc_col,
      object = object
    )
  } else {
    dplyr::distinct(input, dplyr::across(dplyr::all_of(id_cols))) |>
      dplyr::mutate(
        stream_epoch_seconds = as.integer(60L / expected_subepochs),
        expected_subepochs = expected_subepochs
      )
  }
  input <- left_join_checked(
    input,
    stream_epochs,
    by = id_cols,
    relationship = "many-to-one",
    x_name = object,
    y_name = "stream epoch table"
  )
  input$.minimum_finite_subepochs <- if (is.null(minimum_finite_subepochs)) {
    as.integer(ceiling(
      input$expected_subepochs * minimum_finite_fraction
    ))
  } else {
    rep(minimum_finite_subepochs, nrow(input))
  }
  impossible_minimum <- input$.minimum_finite_subepochs >
    input$expected_subepochs
  if (any(impossible_minimum)) {
    abort_pipeline(
      paste0(
        "`minimum_finite_subepochs` exceeds the expected count for %d ",
        "source row(s); use `minimum_finite_fraction` for mixed epochs"
      ),
      sum(impossible_minimum)
    )
  }

  minute_key <- c(id_cols, ".minute_utc")
  context_audit <- input |>
    dplyr::group_by(dplyr::across(dplyr::all_of(minute_key))) |>
    dplyr::summarise(
      wall_values = dplyr::n_distinct(.data$.minute_wall),
      offset_values = dplyr::n_distinct(.data$utc_offset_minutes),
      dst_values = dplyr::n_distinct(.data$is_dst),
      subepochs = dplyr::n(),
      epoch_values = dplyr::n_distinct(.data$stream_epoch_seconds),
      expected_values = dplyr::n_distinct(.data$expected_subepochs),
      minimum_values = dplyr::n_distinct(
        .data$.minimum_finite_subepochs
      ),
      expected_subepochs = dplyr::first(.data$expected_subepochs),
      .groups = "drop"
    )
  invalid_context <- context_audit$wall_values != 1L |
    context_audit$offset_values != 1L |
    context_audit$dst_values != 1L |
    context_audit$epoch_values != 1L |
    context_audit$expected_values != 1L |
    context_audit$minimum_values != 1L
  if (any(invalid_context)) {
    abort_pipeline(
      paste0(
        "%s has %d real minute(s) with inconsistent wall-clock, UTC-offset, ",
        "DST, or source-epoch metadata"
      ),
      object,
      sum(invalid_context)
    )
  }
  overflow <- context_audit$subepochs > context_audit$expected_subepochs
  if (any(overflow)) {
    abort_pipeline(
      paste0(
        "%s has %d real minute(s) with more source observations than ",
        "their stream-specific expected count"
      ),
      object,
      sum(overflow)
    )
  }

  optional_context_cols <- intersect("timezone", names(input))
  if (length(optional_context_cols) > 0L) {
    timezone_audit <- input |>
      dplyr::group_by(dplyr::across(dplyr::all_of(minute_key))) |>
      dplyr::summarise(
        timezone_values = dplyr::n_distinct(.data$timezone),
        .groups = "drop"
      )
    if (any(timezone_audit$timezone_values != 1L)) {
      abort_pipeline(
        "%s has real minute(s) with inconsistent time-zone metadata",
        object
      )
    }
  }

  minutes <- input |>
    dplyr::group_by(dplyr::across(dplyr::all_of(minute_key))) |>
    dplyr::summarise(
      datetime_wall = dplyr::first(.data$.minute_wall),
      utc_offset_minutes = dplyr::first(.data$utc_offset_minutes),
      is_dst = dplyr::first(.data$is_dst),
      dplyr::across(
        dplyr::all_of(optional_context_cols),
        dplyr::first
      ),
      stream_epoch_seconds = dplyr::first(.data$stream_epoch_seconds),
      expected_subepochs = dplyr::first(.data$expected_subepochs),
      minimum_finite_subepochs = dplyr::first(
        .data$.minimum_finite_subepochs
      ),
      source_subepochs = dplyr::n(),
      observed_subepochs = dplyr::n(),
      distinct_subepochs = dplyr::n_distinct(.data[[datetime_utc_col]]),
      implicit_subepochs = sum(.data$.implicit_subepoch),
      dplyr::across(
        dplyr::all_of(signal_cols),
        list(
          finite_subepochs = ~ sum(is.finite(.x)),
          candidate_mean = ~ {
            finite <- is.finite(.x)
            if (any(finite)) mean(.x[finite]) else NA_real_
          }
        ),
        .names = "{.col}_{.fn}"
      ),
      .groups = "drop"
    )

  names(minutes)[match(
    paste0(signal_cols, "_candidate_mean"),
    names(minutes)
  )] <- signal_cols
  for (signal_col in signal_cols) {
    finite_col <- paste0(signal_col, "_finite_subepochs")
    insufficient <- minutes[[finite_col]] < minutes$minimum_finite_subepochs
    minutes[[signal_col]][insufficient] <- NA_real_
  }
  names(minutes)[names(minutes) == ".minute_utc"] <- "datetime_utc"
  minutes$local_date <- as.Date(minutes$datetime_wall, tz = "UTC")
  minutes$clock_minute <- as.integer(
    format(minutes$datetime_wall, format = "%H", tz = "UTC")
  ) *
    60L +
    as.integer(format(
      minutes$datetime_wall,
      format = "%M",
      tz = "UTC"
    ))
  minutes$complete_subepoch_set <-
    minutes$distinct_subepochs == minutes$expected_subepochs

  leading_cols <- c(
    id_cols,
    "datetime_utc",
    "datetime_wall",
    "local_date",
    "clock_minute",
    "utc_offset_minutes",
    "is_dst",
    optional_context_cols,
    signal_cols
  )
  minutes <- dplyr::select(
    minutes,
    dplyr::all_of(leading_cols),
    dplyr::everything()
  ) |>
    dplyr::arrange(
      dplyr::across(dplyr::all_of(id_cols)),
      .data$datetime_utc
    )
  assert_unique_key(
    minutes,
    c(id_cols, "datetime_utc"),
    object = "one-minute real-time data"
  )
  minutes
}

aggregate_ten_second_to_minute <- function(...) {
  aggregate_native_epoch_to_minute(...)
}

collapse_minutes_for_wall_coverage <- function(
  minute_data,
  value_cols = c("MEDI", "LIGHT"),
  id_cols = c("site", "Id", "position"),
  object = deparse(substitute(minute_data))
) {
  if (
    !is.character(value_cols) ||
      length(value_cols) == 0L ||
      anyNA(value_cols) ||
      anyDuplicated(value_cols)
  ) {
    abort_pipeline(
      "`value_cols` must contain unique non-missing column names"
    )
  }
  required <- unique(c(
    id_cols,
    value_cols,
    "datetime_utc",
    "datetime_wall",
    "local_date",
    "clock_minute",
    "utc_offset_minutes"
  ))
  assert_columns(minute_data, required, object = object)
  assert_no_missing_key(
    minute_data,
    c(id_cols, "datetime_utc", "local_date", "clock_minute"),
    object = object
  )
  assert_unique_key(
    minute_data,
    c(id_cols, "datetime_utc"),
    object = paste0(object, " real-time minutes")
  )
  if (
    !inherits(minute_data$datetime_utc, "POSIXct") ||
      !inherits(minute_data$datetime_wall, "POSIXct") ||
      !inherits(minute_data$local_date, "Date")
  ) {
    abort_pipeline(
      paste0(
        "%s must contain POSIXct `datetime_utc`/`datetime_wall` ",
        "and Date `local_date`"
      ),
      object
    )
  }
  valid_clock <- is.numeric(minute_data$clock_minute) &
    !anyNA(minute_data$clock_minute) &&
    all(
      minute_data$clock_minute >= 0 &
        minute_data$clock_minute < 1440 &
        minute_data$clock_minute == as.integer(minute_data$clock_minute)
    )
  if (!valid_clock) {
    abort_pipeline(
      "%s `clock_minute` must contain integers in [0, 1439]",
      object
    )
  }
  non_numeric <- value_cols[
    !vapply(minute_data[value_cols], is.numeric, logical(1))
  ]
  if (length(non_numeric) > 0L) {
    abort_pipeline(
      "%s value column(s) must be numeric: %s",
      object,
      paste(non_numeric, collapse = ", ")
    )
  }

  expected_wall <- as.POSIXct(
    minute_data$local_date,
    tz = "UTC"
  ) +
    as.integer(minute_data$clock_minute) * 60
  inconsistent_wall <- as.numeric(minute_data$datetime_wall) !=
    as.numeric(expected_wall)
  if (any(inconsistent_wall)) {
    abort_pipeline(
      "%s has %d row(s) with inconsistent wall-clock keys",
      object,
      sum(inconsistent_wall)
    )
  }

  wall_key <- c(id_cols, "local_date", "clock_minute", "datetime_wall")
  wall_minutes <- dplyr::ungroup(minute_data) |>
    dplyr::group_by(dplyr::across(dplyr::all_of(wall_key))) |>
    dplyr::summarise(
      dplyr::across(
        dplyr::all_of(value_cols),
        list(
          valid_real_minutes = ~ sum(is.finite(.x)),
          wall_mean = ~ {
            finite <- is.finite(.x)
            if (any(finite)) mean(.x[finite]) else NA_real_
          }
        ),
        .names = "{.col}_{.fn}"
      ),
      source_real_minutes = dplyr::n(),
      distinct_utc_minutes = dplyr::n_distinct(.data$datetime_utc),
      utc_offsets = paste(
        sort(unique(stats::na.omit(.data$utc_offset_minutes))),
        collapse = ","
      ),
      dst_fold = .data$distinct_utc_minutes > 1L,
      .groups = "drop"
    )
  names(wall_minutes)[match(
    paste0(value_cols, "_wall_mean"),
    names(wall_minutes)
  )] <- value_cols
  assert_unique_key(
    wall_minutes,
    c(id_cols, "local_date", "clock_minute"),
    object = "wall-clock coverage minutes"
  )
  wall_minutes
}

evaluate_wall_clock_coverage <- function(
  wall_minutes,
  coverage_signal = "MEDI",
  id_cols = c("site", "Id", "position"),
  participant_days = NULL,
  minimum_hour_coverage = 0.5,
  minimum_day_coverage = 0.8,
  object = deparse(substitute(wall_minutes))
) {
  validate_coverage_fraction(
    minimum_hour_coverage,
    argument = "minimum_hour_coverage"
  )
  validate_coverage_fraction(
    minimum_day_coverage,
    argument = "minimum_day_coverage"
  )
  required <- c(
    id_cols,
    "local_date",
    "clock_minute",
    "datetime_wall",
    "source_real_minutes",
    "distinct_utc_minutes",
    "dst_fold",
    coverage_signal
  )
  assert_columns(wall_minutes, required, object = object)
  assert_unique_key(
    wall_minutes,
    c(id_cols, "local_date", "clock_minute"),
    object = object
  )
  if (!is.numeric(wall_minutes[[coverage_signal]])) {
    abort_pipeline(
      "%s coverage signal `%s` must be numeric",
      object,
      coverage_signal
    )
  }
  if (!inherits(wall_minutes$local_date, "Date")) {
    abort_pipeline("%s `local_date` must be Date", object)
  }

  if (is.null(participant_days)) {
    days <- dplyr::distinct(
      wall_minutes,
      dplyr::across(dplyr::all_of(c(id_cols, "local_date")))
    )
  } else {
    assert_columns(
      participant_days,
      c(id_cols, "local_date"),
      object = "participant-day index"
    )
    assert_no_missing_key(
      participant_days,
      c(id_cols, "local_date"),
      object = "participant-day index"
    )
    assert_unique_key(
      participant_days,
      c(id_cols, "local_date"),
      object = "participant-day index"
    )
    if (!inherits(participant_days$local_date, "Date")) {
      abort_pipeline("Participant-day index `local_date` must be Date")
    }
    days <- tibble::as_tibble(participant_days[c(id_cols, "local_date")])
  }
  if (nrow(days) == 0L) {
    abort_pipeline("No participant-days are available for coverage evaluation")
  }

  grid <- days[
    rep(seq_len(nrow(days)), each = 1440L),
    ,
    drop = FALSE
  ]
  grid$clock_minute <- rep(0:1439, times = nrow(days))
  grid$datetime_wall <- as.POSIXct(grid$local_date, tz = "UTC") +
    grid$clock_minute * 60

  wall_values <- dplyr::select(
    wall_minutes,
    -dplyr::all_of("datetime_wall")
  )
  grid <- left_join_checked(
    grid,
    wall_values,
    by = c(id_cols, "local_date", "clock_minute"),
    relationship = "one-to-one",
    x_name = "complete wall-clock grid",
    y_name = "observed wall-clock minutes"
  )
  grid$minute_present <- !is.na(grid$source_real_minutes)
  grid$source_real_minutes <- dplyr::coalesce(
    as.integer(grid$source_real_minutes),
    0L
  )
  grid$distinct_utc_minutes <- dplyr::coalesce(
    as.integer(grid$distinct_utc_minutes),
    0L
  )
  grid$dst_fold <- dplyr::coalesce(grid$dst_fold, FALSE)
  grid$coverage_signal_observed <- is.finite(grid[[coverage_signal]])
  grid$clock_hour <- as.integer(grid$clock_minute %/% 60L)

  hourly <- grid |>
    dplyr::group_by(
      dplyr::across(dplyr::all_of(c(id_cols, "local_date"))),
      .data$clock_hour
    ) |>
    dplyr::summarise(
      expected_wall_minutes = 60L,
      observed_wall_minutes = sum(.data$minute_present),
      source_real_minutes = sum(.data$source_real_minutes),
      valid_minutes = sum(.data$coverage_signal_observed),
      valid_fraction = .data$valid_minutes / .data$expected_wall_minutes,
      dst_fold_minutes = sum(.data$dst_fold),
      hour_eligible = .data$valid_fraction >= minimum_hour_coverage,
      .groups = "drop"
    ) |>
    dplyr::rename(
      hour_expected_wall_minutes = "expected_wall_minutes",
      hour_observed_wall_minutes = "observed_wall_minutes",
      hour_source_real_minutes = "source_real_minutes",
      hour_valid_minutes = "valid_minutes",
      hour_valid_fraction = "valid_fraction",
      hour_dst_fold_minutes = "dst_fold_minutes"
    )

  grid <- left_join_checked(
    grid,
    hourly,
    by = c(id_cols, "local_date", "clock_hour"),
    relationship = "many-to-one",
    x_name = "complete wall-clock grid",
    y_name = "hourly coverage"
  )
  grid$coverage_signal_after_hour <-
    grid$coverage_signal_observed & grid$hour_eligible

  daily <- grid |>
    dplyr::group_by(
      dplyr::across(dplyr::all_of(c(id_cols, "local_date")))
    ) |>
    dplyr::summarise(
      expected_wall_minutes = 1440L,
      observed_wall_minutes = sum(.data$minute_present),
      source_real_minutes = sum(.data$source_real_minutes),
      valid_minutes_raw = sum(.data$coverage_signal_observed),
      valid_minutes_after_hour = sum(.data$coverage_signal_after_hour),
      valid_fraction_after_hour = .data$valid_minutes_after_hour /
        .data$expected_wall_minutes,
      eligible_hours = dplyr::n_distinct(
        .data$clock_hour[.data$hour_eligible]
      ),
      dst_fold_minutes = sum(.data$dst_fold),
      day_eligible = .data$valid_fraction_after_hour >= minimum_day_coverage,
      .groups = "drop"
    ) |>
    dplyr::rename(
      day_expected_wall_minutes = "expected_wall_minutes",
      day_observed_wall_minutes = "observed_wall_minutes",
      day_source_real_minutes = "source_real_minutes",
      day_valid_minutes_raw = "valid_minutes_raw",
      day_valid_minutes_after_hour = "valid_minutes_after_hour",
      day_valid_fraction_after_hour = "valid_fraction_after_hour",
      day_eligible_hours = "eligible_hours",
      day_dst_fold_minutes = "dst_fold_minutes"
    )

  grid <- left_join_checked(
    grid,
    daily,
    by = c(id_cols, "local_date"),
    relationship = "many-to-one",
    x_name = "complete wall-clock grid",
    y_name = "daily coverage"
  )
  grid$coverage_period_eligible <- grid$hour_eligible & grid$day_eligible
  grid$coverage_value_eligible <- grid$coverage_period_eligible &
    grid$coverage_signal_observed

  grid <- grid |>
    dplyr::arrange(
      dplyr::across(dplyr::all_of(c(id_cols, "local_date"))),
      .data$clock_minute
    )
  assert_unique_key(
    grid,
    c(id_cols, "local_date", "clock_minute"),
    object = "complete wall-clock coverage grid"
  )
  list(
    wall_grid = grid,
    hourly = hourly,
    daily = daily
  )
}

map_wall_coverage_to_real_minutes <- function(
  minute_data,
  wall_grid,
  coverage_signal = "MEDI",
  id_cols = c("site", "Id", "position"),
  object = deparse(substitute(minute_data))
) {
  minute_key <- c(id_cols, "datetime_utc")
  wall_key <- c(id_cols, "local_date", "clock_minute")
  assert_columns(
    minute_data,
    c(minute_key, "local_date", "clock_minute", coverage_signal),
    object = object
  )
  assert_unique_key(
    minute_data,
    minute_key,
    object = paste0(object, " real-time minutes")
  )
  coverage_cols <- c(
    wall_key,
    "source_real_minutes",
    "distinct_utc_minutes",
    "dst_fold",
    "hour_valid_minutes",
    "hour_valid_fraction",
    "hour_eligible",
    "day_valid_minutes_raw",
    "day_valid_minutes_after_hour",
    "day_valid_fraction_after_hour",
    "day_eligible",
    "coverage_period_eligible"
  )
  assert_columns(wall_grid, coverage_cols, object = "wall-clock grid")
  assert_unique_key(
    wall_grid,
    wall_key,
    object = "wall-clock grid"
  )

  collisions <- intersect(
    setdiff(coverage_cols, wall_key),
    names(minute_data)
  )
  if (length(collisions) > 0L) {
    abort_pipeline(
      "%s already contains coverage column(s): %s",
      object,
      paste(collisions, collapse = ", ")
    )
  }

  coverage_lookup <- dplyr::select(
    wall_grid,
    dplyr::all_of(coverage_cols)
  ) |>
    dplyr::rename(
      wall_source_real_minutes = "source_real_minutes",
      wall_distinct_utc_minutes = "distinct_utc_minutes",
      wall_dst_fold = "dst_fold"
    )
  output <- dplyr::ungroup(minute_data)
  output$.coverage_row_order <- seq_len(nrow(output))
  output <- left_join_checked(
    output,
    coverage_lookup,
    by = wall_key,
    relationship = "many-to-one",
    x_name = object,
    y_name = "wall-clock coverage lookup"
  ) |>
    dplyr::arrange(.data$.coverage_row_order) |>
    dplyr::select(-dplyr::all_of(".coverage_row_order"))
  if (anyNA(output$coverage_period_eligible)) {
    abort_pipeline(
      "%s contains real minute(s) absent from the wall-clock grid",
      object
    )
  }
  output$coverage_signal_observed_real <-
    is.finite(output[[coverage_signal]])
  output$coverage_value_eligible_real <-
    output$coverage_period_eligible &
    output$coverage_signal_observed_real
  assert_unique_key(
    output,
    minute_key,
    object = "coverage-annotated real-time minutes"
  )
  output
}

apply_wall_clock_coverage_rules <- function(
  minute_data,
  value_cols = c("MEDI", "LIGHT"),
  coverage_signal = "MEDI",
  id_cols = c("site", "Id", "position"),
  participant_days = NULL,
  minimum_hour_coverage = 0.5,
  minimum_day_coverage = 0.8,
  object = deparse(substitute(minute_data))
) {
  if (!coverage_signal %in% value_cols) {
    abort_pipeline(
      "`coverage_signal` ('%s') must be included in `value_cols`",
      coverage_signal
    )
  }
  wall_minutes <- collapse_minutes_for_wall_coverage(
    minute_data = minute_data,
    value_cols = value_cols,
    id_cols = id_cols,
    object = object
  )
  evaluated <- evaluate_wall_clock_coverage(
    wall_minutes = wall_minutes,
    coverage_signal = coverage_signal,
    id_cols = id_cols,
    participant_days = participant_days,
    minimum_hour_coverage = minimum_hour_coverage,
    minimum_day_coverage = minimum_day_coverage,
    object = paste0(object, " wall-clock minutes")
  )
  real_minutes <- map_wall_coverage_to_real_minutes(
    minute_data = minute_data,
    wall_grid = evaluated$wall_grid,
    coverage_signal = coverage_signal,
    id_cols = id_cols,
    object = object
  )

  structure(
    list(
      real_minutes = real_minutes,
      wall_minutes = wall_minutes,
      wall_grid = evaluated$wall_grid,
      hourly = evaluated$hourly,
      daily = evaluated$daily,
      settings = tibble::tibble(
        coverage_signal = coverage_signal,
        expected_wall_minutes_per_hour = 60L,
        expected_wall_minutes_per_day = 1440L,
        minimum_hour_coverage = minimum_hour_coverage,
        minimum_day_coverage = minimum_day_coverage
      )
    ),
    class = c("wall_clock_coverage", "list")
  )
}
