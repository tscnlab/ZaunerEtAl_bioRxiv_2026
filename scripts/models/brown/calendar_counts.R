# Count true-local-date intersections of immutable B parent windows.

lb_calendar_counts <- function(parent_frame, coverage) {
  parents <- data.table::as.data.table(data.table::copy(parent_frame))
  required <- c(
    "site",
    "Id",
    "raw_state",
    "period_source_start",
    "period_source_end",
    "site_timezone",
    "period_tick_start_utc",
    "period_tick_end_exclusive_utc",
    "expected_minutes",
    "projected_minutes",
    "valid_minutes",
    "brown_yes"
  )
  stopifnot(all(required %in% names(parents)), nrow(parents) > 0L)
  for (column in c("site", "Id", "raw_state", "site_timezone"))
    parents[, (column) := as.character(get(column))]
  parents[, parent_index := seq_len(.N)]
  key_columns <- c(
    "site",
    "Id",
    "raw_state",
    "period_source_start",
    "period_source_end"
  )
  parent_key <- do.call(paste, c(parents[, ..key_columns], sep = "\r"))
  stopifnot(
    !anyDuplicated(parent_key),
    !anyNA(parents[, ..required]),
    all(parents$expected_minutes > 0L),
    all(as.numeric(parents$period_tick_start_utc) %% 60 == 0),
    all(as.numeric(parents$period_tick_end_exclusive_utc) %% 60 == 0),
    all(
      (as.numeric(parents$period_tick_end_exclusive_utc) -
        as.numeric(parents$period_tick_start_utc)) /
        60 ==
        parents$expected_minutes
    )
  )
  raw <- data.table::as.data.table(data.table::copy(coverage))
  stopifnot(all(
    c(
      "site",
      "Id",
      "State.Brown",
      "sleep_source_row_start",
      "sleep_source_row_end",
      "datetime_utc",
      "local_date",
      "MEDI_eligible"
    ) %in%
      names(raw)
  ))
  raw_key <- paste(
    as.character(raw$site),
    as.character(raw$Id),
    as.character(raw$State.Brown),
    as.integer(raw$sleep_source_row_start),
    as.integer(raw$sleep_source_row_end),
    sep = "\r"
  )
  parent_index <- match(raw_key, parent_key)
  raw[, parent_index := parent_index]
  minute <- raw[!is.na(parent_index)]
  stopifnot(
    nrow(minute) > 0L,
    !anyDuplicated(minute[, .(site, Id, datetime_utc)])
  )
  minute[, `:=`(
    calendar_timezone = parents$site_timezone[parent_index],
    raw_state = parents$raw_state[parent_index],
    valid_minute = is.finite(MEDI_eligible)
  )]
  minute[,
    computed_date := as.Date(format(
      datetime_utc,
      format = "%Y-%m-%d",
      tz = calendar_timezone[1L]
    )),
    by = calendar_timezone
  ]
  stopifnot(
    !anyNA(minute$computed_date),
    all(as.character(minute$computed_date) == as.character(minute$local_date)),
    all(as.numeric(minute$datetime_utc) %% 60 == 0),
    all(
      as.numeric(minute$datetime_utc) >=
        as.numeric(parents$period_tick_start_utc[minute$parent_index])
    ),
    all(
      as.numeric(minute$datetime_utc) <
        as.numeric(parents$period_tick_end_exclusive_utc[minute$parent_index])
    )
  )
  minute[,
    adherent := data.table::fcase(
      raw_state == "wake" & valid_minute,
      MEDI_eligible >= 250,
      raw_state == "pre-sleep" & valid_minute,
      MEDI_eligible <= 10,
      raw_state == "sleep" & valid_minute,
      MEDI_eligible <= 1,
      default = NA
    )
  ]
  observed <- minute[,
    .(
      projected_minutes = .N,
      valid_minutes = sum(valid_minute),
      brown_yes = sum(adherent, na.rm = TRUE)
    ),
    by = .(parent_index, local_date = computed_date)
  ]
  expected <- data.table::rbindlist(lapply(seq_len(nrow(parents)), function(i) {
    row <- parents[i]
    ticks <- as.POSIXct(
      as.numeric(row$period_tick_start_utc) +
        60 * (seq_len(row$expected_minutes) - 1L),
      origin = "1970-01-01",
      tz = "UTC"
    )
    dates <- as.Date(format(ticks, format = "%Y-%m-%d", tz = row$site_timezone))
    data.table::data.table(parent_index = i, local_date = dates)[,
      .(expected_minutes = .N),
      by = .(parent_index, local_date)
    ]
  }))
  observed_key <- paste(observed$parent_index, observed$local_date, sep = "\r")
  expected_key <- paste(expected$parent_index, expected$local_date, sep = "\r")
  stopifnot(
    !anyDuplicated(expected_key),
    !anyNA(match(observed_key, expected_key))
  )
  chunks <- merge(
    expected,
    observed,
    by = c("parent_index", "local_date"),
    all.x = TRUE,
    sort = TRUE
  )
  for (column in c("projected_minutes", "valid_minutes", "brown_yes"))
    data.table::set(chunks, which(is.na(chunks[[column]])), column, 0L)
  sums <- chunks[,
    .(
      expected_recount = sum(expected_minutes),
      projected_recount = sum(projected_minutes),
      valid_recount = sum(valid_minutes),
      yes_recount = sum(brown_yes)
    ),
    by = parent_index
  ]
  reconciliation <- merge(
    parents[,
      c(
        "parent_index",
        key_columns,
        "expected_minutes",
        "projected_minutes",
        "valid_minutes",
        "brown_yes"
      ),
      with = FALSE
    ],
    sums,
    by = "parent_index",
    all = TRUE
  )
  reconciliation[,
    pass := expected_minutes == expected_recount &
      projected_minutes == projected_recount &
      valid_minutes == valid_recount &
      brown_yes == yes_recount
  ]
  stopifnot(
    nrow(reconciliation) == nrow(parents),
    !anyNA(reconciliation$pass),
    all(reconciliation$pass),
    all(
      chunks$brown_yes >= 0 &
        chunks$brown_yes <= chunks$valid_minutes &
        chunks$valid_minutes <= chunks$projected_minutes &
        chunks$projected_minutes <= chunks$expected_minutes
    )
  )
  list(
    parents = parents,
    candidate_chunks = chunks,
    reconciliation = reconciliation,
    minute_identity = data.frame(
      checked_projected_minutes = nrow(minute),
      UTC_membership_exact = TRUE,
      local_date_exact = TRUE,
      duplicated_ticks = 0L,
      parent_count = nrow(parents),
      raw_coverage_used = TRUE
    )
  )
}
