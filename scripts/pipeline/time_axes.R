parse_utc_offset_minutes <- function(offset) {
  if (!is.character(offset)) {
    abort_pipeline("UTC offset must be a character vector")
  }
  valid <- is.na(offset) | grepl("^[+-][0-9]{4}$", offset)
  if (!all(valid)) {
    abort_pipeline(
      "UTC offset contains invalid value(s): %s",
      paste(unique(offset[!valid]), collapse = ", ")
    )
  }
  sign <- ifelse(substr(offset, 1L, 1L) == "-", -1, 1)
  hours <- suppressWarnings(as.integer(substr(offset, 2L, 3L)))
  minutes <- suppressWarnings(as.integer(substr(offset, 4L, 5L)))
  result <- sign * (hours * 60 + minutes)
  result[is.na(offset)] <- NA_integer_
  as.integer(result)
}

build_true_minute_day_grid <- function(
  participant_days,
  id_cols = c("site", "Id", "position"),
  date_col = "local_date",
  timezone_col = "timezone",
  epoch_seconds = 60
) {
  if (!is.data.frame(participant_days)) {
    abort_pipeline("`participant_days` must be a data frame")
  }
  required <- unique(c(id_cols, date_col, timezone_col))
  assert_columns(
    participant_days,
    required,
    object = "participant-day index"
  )
  assert_no_missing_key(
    participant_days,
    required,
    object = "participant-day index"
  )
  assert_unique_key(
    participant_days,
    c(id_cols, date_col),
    object = "participant-day index"
  )
  if (!inherits(participant_days[[date_col]], "Date")) {
    abort_pipeline("`%s` must be Date", date_col)
  }
  if (
    length(epoch_seconds) != 1L ||
      !is.numeric(epoch_seconds) ||
      !is.finite(epoch_seconds) ||
      epoch_seconds <= 0 ||
      epoch_seconds != as.integer(epoch_seconds) ||
      60 %% epoch_seconds != 0L
  ) {
    abort_pipeline(
      "`epoch_seconds` must be a positive integer divisor of 60"
    )
  }
  timezones <- as.character(participant_days[[timezone_col]])
  invalid_timezones <- !timezones %in% OlsonNames()
  if (any(invalid_timezones)) {
    abort_pipeline(
      "Participant-day index has invalid time zone(s): %s",
      paste(sort(unique(timezones[invalid_timezones])), collapse = ", ")
    )
  }

  rows <- lapply(seq_len(nrow(participant_days)), function(index) {
    timezone <- timezones[[index]]
    local_date <- participant_days[[date_col]][[index]]
    next_date <- local_date + 1L
    local_start <- as.POSIXct(
      paste(format(local_date, "%Y-%m-%d"), "00:00:00"),
      tz = timezone
    )
    local_end <- as.POSIXct(
      paste(format(next_date, "%Y-%m-%d"), "00:00:00"),
      tz = timezone
    )
    start_numeric <- as.numeric(local_start)
    end_numeric <- as.numeric(local_end)
    if (
      !is.finite(start_numeric) ||
        !is.finite(end_numeric) ||
        end_numeric <= start_numeric ||
        (end_numeric - start_numeric) %% epoch_seconds != 0
    ) {
      abort_pipeline(
        "Could not construct a regular true-time day for %s in %s",
        format(local_date),
        timezone
      )
    }
    datetime_utc <- as.POSIXct(
      seq.int(
        from = start_numeric,
        to = end_numeric - epoch_seconds,
        by = epoch_seconds
      ),
      origin = "1970-01-01",
      tz = "UTC"
    )
    local_time <- lubridate::with_tz(datetime_utc, tzone = timezone)
    local_fields <- as.POSIXlt(local_time, tz = timezone)
    grid <- participant_days[
      rep(index, length(datetime_utc)),
      ,
      drop = FALSE
    ]
    grid$datetime_utc <- datetime_utc
    grid$datetime_wall <- lubridate::force_tz(local_time, tzone = "UTC")
    derived_date <- as.Date(local_time, tz = timezone)
    if (any(derived_date != local_date)) {
      abort_pipeline(
        "True-time day for %s in %s crossed its requested local date",
        format(local_date),
        timezone
      )
    }
    grid[[date_col]] <- derived_date
    grid$clock_minute <- as.integer(
      local_fields$hour * 60L + local_fields$min
    )
    grid$utc_offset_minutes <- parse_utc_offset_minutes(
      format(datetime_utc, format = "%z", tz = timezone)
    )
    grid$is_dst <- local_fields$isdst == 1L
    grid$day_expected_real_minutes <- as.integer(
      (end_numeric - start_numeric) / epoch_seconds
    )
    grid$epoch_seconds <- as.integer(epoch_seconds)
    grid
  })
  output <- dplyr::bind_rows(rows) |>
    dplyr::arrange(
      dplyr::across(dplyr::all_of(c(id_cols, date_col))),
      .data$datetime_utc
    )
  assert_unique_key(
    output,
    c(id_cols, "datetime_utc"),
    object = "true-minute participant-day grid"
  )
  output
}

annotate_time_axes <- function(
  data,
  timezone,
  datetime_col = "Datetime",
  site = NULL
) {
  assert_columns(data, datetime_col)
  if (
    length(timezone) != 1L ||
      is.na(timezone) ||
      !timezone %in% OlsonNames()
  ) {
    abort_pipeline("`timezone` must be one valid Olson time zone")
  }
  datetime <- data[[datetime_col]]
  if (!inherits(datetime, "POSIXct")) {
    abort_pipeline("`%s` must be POSIXct", datetime_col)
  }
  if (anyNA(datetime)) {
    abort_pipeline("`%s` contains missing timestamps", datetime_col)
  }

  source_timezone <- lubridate::tz(datetime)
  if (!identical(source_timezone, timezone)) {
    abort_pipeline(
      "Timestamp time zone is '%s' but source manifest requires '%s'",
      source_timezone,
      timezone
    )
  }

  local_offset <- format(datetime, format = "%z", tz = timezone)
  local_seconds <- (lubridate::hour(datetime) *
    3600 +
    lubridate::minute(datetime) * 60 +
    lubridate::second(datetime))
  local_posixlt <- as.POSIXlt(datetime, tz = timezone)

  output <- data
  output$source_datetime_numeric <- as.numeric(datetime)
  output$datetime_utc <- lubridate::with_tz(datetime, tzone = "UTC")
  output$datetime_wall <- lubridate::force_tz(datetime, tzone = "UTC")
  output[[datetime_col]] <- output$datetime_utc
  output$timezone <- timezone
  output$utc_offset_minutes <- parse_utc_offset_minutes(local_offset)
  output$is_dst <- local_posixlt$isdst == 1L
  output$local_date <- as.Date(datetime, tz = timezone)
  output$local_clock_label <- format(
    datetime,
    format = "%Y-%m-%d %H:%M:%S",
    tz = timezone
  )
  output$clock_second <- as.numeric(local_seconds)
  output$clock_minute <- output$clock_second / 60
  if (!is.null(site)) {
    output$site <- site
  }
  output
}

collapse_wall_clock_intervals <- function(
  data,
  value_cols,
  group_cols = c(
    "site",
    "Id",
    "local_date",
    "clock_minute",
    "datetime_wall"
  )
) {
  required <- unique(c(
    value_cols,
    group_cols,
    "datetime_utc",
    "utc_offset_minutes"
  ))
  assert_columns(data, required, object = "wall-clock input")
  if (length(value_cols) == 0L) {
    abort_pipeline("`value_cols` must contain at least one column")
  }
  non_numeric <- value_cols[!vapply(data[value_cols], is.numeric, logical(1))]
  if (length(non_numeric) > 0L) {
    abort_pipeline(
      "Wall-clock value column(s) must be numeric: %s",
      paste(non_numeric, collapse = ", ")
    )
  }

  collapsed <- data |>
    dplyr::group_by(dplyr::across(dplyr::all_of(group_cols))) |>
    dplyr::summarise(
      dplyr::across(
        dplyr::all_of(value_cols),
        ~ sum(is.finite(.x)),
        .names = "valid_{.col}"
      ),
      dplyr::across(
        dplyr::all_of(value_cols),
        ~ if (any(is.finite(.x))) mean(.x[is.finite(.x)]) else NA_real_
      ),
      source_intervals = dplyr::n(),
      distinct_instants = dplyr::n_distinct(.data$datetime_utc),
      utc_offsets = paste(
        sort(unique(.data$utc_offset_minutes)),
        collapse = ","
      ),
      dst_fold = .data$distinct_instants > 1L,
      .groups = "drop"
    )
  assert_unique_key(
    collapsed,
    group_cols,
    object = "collapsed wall-clock data"
  )
  collapsed
}

bind_site_time_axes <- function(data_by_site, site_sources) {
  if (!is.list(data_by_site) || is.null(names(data_by_site))) {
    abort_pipeline("`data_by_site` must be a named list")
  }
  assert_unique_key(site_sources, "site", object = "site source manifest")
  unknown <- setdiff(names(data_by_site), site_sources$site)
  if (length(unknown) > 0L) {
    abort_pipeline(
      "No source-manifest row for site(s): %s",
      paste(unknown, collapse = ", ")
    )
  }

  bound <- purrr::imap_dfr(data_by_site, function(data, site_name) {
    timezone <- site_sources$timezone[site_sources$site == site_name]
    annotate_time_axes(
      data = dplyr::ungroup(data),
      timezone = timezone,
      datetime_col = "Datetime",
      site = site_name
    )
  })
  assert_unique_key(
    bound,
    c("site", "Id", "datetime_utc"),
    object = "bound site observation data"
  )
  bound
}

dst_local_key_summary <- function(data) {
  required <- c(
    "site",
    "Id",
    "datetime_utc",
    "local_clock_label",
    "utc_offset_minutes",
    "is_dst"
  )
  assert_columns(data, required)
  assert_unique_key(
    data,
    c("site", "Id", "datetime_utc"),
    object = "timestamp audit data"
  )

  data |>
    dplyr::group_by(.data$site, .data$Id, .data$local_clock_label) |>
    dplyr::summarise(
      observations = dplyr::n(),
      distinct_instants = dplyr::n_distinct(.data$datetime_utc),
      offsets = paste(
        sort(unique(.data$utc_offset_minutes)),
        collapse = ","
      ),
      crosses_dst = dplyr::n_distinct(.data$is_dst) > 1L,
      .groups = "drop"
    ) |>
    dplyr::filter(.data$observations > 1L)
}
