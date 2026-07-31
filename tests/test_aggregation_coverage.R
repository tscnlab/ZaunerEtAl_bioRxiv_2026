source("scripts/pipeline/assertions.R")
source("scripts/pipeline/time_axes.R")
source("scripts/pipeline/aggregation_coverage.R")
source("scripts/pipeline/state_alignment.R")

new_ten_second_data <- function(
  utc_start,
  minutes,
  medi,
  light,
  site = "TEST",
  id = "P01",
  position = "glasses",
  timezone = "UTC"
) {
  offsets <- rep(c(5, 15, 25, 35, 45, 55), times = minutes)
  minute_offsets <- rep(seq.int(0, minutes - 1L) * 60, each = 6L)
  datetime_utc <- utc_start + minute_offsets + offsets
  local_datetime <- lubridate::with_tz(datetime_utc, tzone = timezone)
  annotate_time_axes(
    tibble::tibble(
      Id = id,
      position = position,
      Datetime = local_datetime,
      MEDI = medi,
      LIGHT = light,
      is.implicit = FALSE
    ),
    timezone = timezone,
    site = site
  )
}

new_minute_day <- function(
  date,
  medi,
  id = "P01",
  position = "glasses"
) {
  clock_minute <- seq_along(medi) - 1L
  datetime_wall <- as.POSIXct(date, tz = "UTC") + clock_minute * 60
  tibble::tibble(
    site = "TEST",
    Id = id,
    position = position,
    datetime_utc = datetime_wall,
    datetime_wall = datetime_wall,
    local_date = as.Date(date),
    clock_minute = clock_minute,
    utc_offset_minutes = 0L,
    is_dst = FALSE,
    MEDI = medi,
    LIGHT = medi * 2
  )
}

message("Testing explicit ten-second aggregation and support counts")
start <- as.POSIXct("2026-01-01 00:00:00", tz = "UTC")
ten_second <- new_ten_second_data(
  utc_start = start,
  minutes = 2L,
  medi = c(rep(100001, 6L), 1:5, NA_real_),
  light = c(1:6, 11:16)
)
minute_default <- aggregate_ten_second_to_minute(ten_second)
stopifnot(
  nrow(minute_default) == 2L,
  identical(minute_default$datetime_utc, start + c(0, 60)),
  minute_default$MEDI[1L] == 100001,
  is.na(minute_default$MEDI[2L]),
  minute_default$LIGHT[1L] == 3.5,
  minute_default$LIGHT[2L] == 13.5,
  identical(minute_default$MEDI_finite_subepochs, c(6L, 5L)),
  identical(minute_default$source_subepochs, c(6L, 6L)),
  all(minute_default$complete_subepoch_set),
  all(minute_default$minimum_finite_subepochs == 6L)
)
minute_relaxed <- aggregate_ten_second_to_minute(
  ten_second,
  minimum_finite_subepochs = 5L
)
stopifnot(
  minute_relaxed$MEDI[2L] == 3,
  all(minute_relaxed$minimum_finite_subepochs == 5L)
)
short_minute <- aggregate_ten_second_to_minute(ten_second[-12L, ])
stopifnot(
  is.na(short_minute$MEDI[2L]),
  is.na(short_minute$LIGHT[2L]),
  short_minute$source_subepochs[2L] == 5L,
  !short_minute$complete_subepoch_set[2L]
)
duplicate_error <- tryCatch(
  {
    aggregate_ten_second_to_minute(
      dplyr::bind_rows(ten_second, ten_second[1L, ])
    )
    FALSE
  },
  error = function(error) TRUE
)
stopifnot(duplicate_error)

message("Testing the 100,000-lx boundary after minute aggregation")
boundary_source <- new_ten_second_data(
  utc_start = start,
  minutes = 2L,
  medi = c(200000, rep(0, 5L), rep(100000, 6L)),
  light = rep(1000, 12L)
)
boundary_minutes <- aggregate_native_epoch_to_minute(boundary_source)
boundary_minutes$State.Brown <- "wake"
boundary_minutes$wear <- NA_character_
boundary_context <- derive_measurement_context(
  boundary_minutes,
  placement = "glasses"
)
stopifnot(
  isTRUE(all.equal(boundary_context$MEDI_raw[1L], 200000 / 6)),
  isTRUE(all.equal(boundary_context$MEDI[1L], 200000 / 6)),
  !boundary_context$medi_saturated[1L],
  boundary_context$MEDI_raw[2L] == 100000,
  is.na(boundary_context$MEDI[2L]),
  boundary_context$medi_saturated[2L],
  boundary_context$LIGHT[2L] == 1000,
  !boundary_context$valid_medi_light_pair[2L]
)

message("Testing inferred 1-, 10-, and 60-second source epochs")
new_regular_epoch_data <- function(
  epoch_seconds,
  minutes = 2L,
  id,
  value
) {
  expected <- 60L / epoch_seconds
  offsets <- rep(
    seq.int(0, 60L - epoch_seconds, by = epoch_seconds),
    times = minutes
  )
  minute_offsets <- rep(
    seq.int(0, minutes - 1L) * 60L,
    each = expected
  )
  datetime_utc <- start + minute_offsets + offsets
  annotate_time_axes(
    tibble::tibble(
      Id = id,
      position = "glasses",
      Datetime = datetime_utc,
      MEDI = rep(value, length(datetime_utc)),
      LIGHT = rep(value * 2, length(datetime_utc)),
      is.implicit = FALSE
    ),
    timezone = "UTC",
    site = "MIXED"
  )
}
mixed_epoch <- dplyr::bind_rows(
  new_regular_epoch_data(1L, id = "E01", value = 1),
  new_regular_epoch_data(10L, id = "E10", value = 10),
  new_regular_epoch_data(60L, id = "E60", value = 60)
)
mixed_minute <- aggregate_native_epoch_to_minute(mixed_epoch) |>
  dplyr::arrange(.data$Id, .data$datetime_utc)
mixed_stream <- mixed_minute |>
  dplyr::distinct(
    .data$Id,
    .data$stream_epoch_seconds,
    .data$expected_subepochs
  ) |>
  dplyr::arrange(.data$Id)
stopifnot(
  identical(mixed_stream$stream_epoch_seconds, c(1L, 10L, 60L)),
  identical(mixed_stream$expected_subepochs, c(60L, 6L, 1L)),
  all(mixed_minute$complete_subepoch_set),
  all(mixed_minute$MEDI[mixed_minute$Id == "E01"] == 1),
  all(mixed_minute$MEDI[mixed_minute$Id == "E10"] == 10),
  all(mixed_minute$MEDI[mixed_minute$Id == "E60"] == 60)
)
mixed_partial <- mixed_epoch[
  !(mixed_epoch$Id == "E01" &
    mixed_epoch$datetime_utc == start + 59) &
    !(mixed_epoch$Id == "E10" &
      mixed_epoch$datetime_utc == start + 50),
]
mixed_partial_minute <- aggregate_native_epoch_to_minute(mixed_partial)
partial_first <- mixed_partial_minute |>
  dplyr::filter(
    .data$Id %in% c("E01", "E10"),
    .data$datetime_utc == start
  ) |>
  dplyr::arrange(.data$Id)
stopifnot(
  identical(partial_first$source_subepochs, c(59L, 5L)),
  identical(partial_first$expected_subepochs, c(60L, 6L)),
  all(!partial_first$complete_subepoch_set),
  all(is.na(partial_first$MEDI))
)
mixed_relaxed <- aggregate_native_epoch_to_minute(
  mixed_partial,
  minimum_finite_fraction = 0.5
)
stopifnot(
  all(is.finite(mixed_relaxed$MEDI)),
  all(
    mixed_relaxed$minimum_finite_subepochs ==
      ceiling(mixed_relaxed$expected_subepochs * 0.5)
  )
)

message("Testing separate DST-fold wall-clock collapse")
fold_instants <- c(
  as.POSIXct("2024-10-27 00:00:00", tz = "UTC"),
  as.POSIXct("2024-10-27 01:00:00", tz = "UTC")
)
fold_raw <- dplyr::bind_rows(
  new_ten_second_data(
    utc_start = fold_instants[1L],
    minutes = 1L,
    medi = rep(10, 6L),
    light = rep(100, 6L),
    timezone = "Europe/Berlin"
  ),
  new_ten_second_data(
    utc_start = fold_instants[2L],
    minutes = 1L,
    medi = rep(20, 6L),
    light = rep(200, 6L),
    timezone = "Europe/Berlin"
  )
)
fold_minutes <- aggregate_ten_second_to_minute(fold_raw)
fold_wall <- collapse_minutes_for_wall_coverage(fold_minutes)
stopifnot(
  nrow(fold_minutes) == 2L,
  length(unique(fold_minutes$datetime_utc)) == 2L,
  length(unique(fold_minutes$datetime_wall)) == 1L,
  nrow(fold_wall) == 1L,
  fold_wall$MEDI == 15,
  fold_wall$LIGHT == 150,
  fold_wall$source_real_minutes == 2L,
  fold_wall$distinct_utc_minutes == 2L,
  fold_wall$MEDI_valid_real_minutes == 2L,
  fold_wall$dst_fold
)

message("Testing inclusive 50%-hour and 80%-wall-day boundaries")
exact_80 <- rep(NA_real_, 1440L)
exact_80[1:1080] <- 1
exact_80[1081:1104] <- 1
exact_80[1141:1164] <- 1
exact_80[1201:1224] <- 1
just_below_80 <- exact_80
just_below_80[1224L] <- NA_real_
boundary_minutes <- dplyr::bind_rows(
  new_minute_day("2026-01-01", exact_80, id = "PASS"),
  new_minute_day("2026-01-01", just_below_80, id = "FAIL")
)
boundary <- apply_wall_clock_coverage_rules(boundary_minutes)
boundary_days <- boundary$daily |>
  dplyr::arrange(.data$Id)
pass_day <- boundary_days[boundary_days$Id == "PASS", ]
fail_day <- boundary_days[boundary_days$Id == "FAIL", ]
stopifnot(
  pass_day$day_valid_minutes_raw == 1152L,
  pass_day$day_valid_fraction_raw == 0.8,
  pass_day$day_valid_minutes_after_hour == 1080L,
  pass_day$day_valid_fraction_after_hour == 0.75,
  pass_day$day_eligible_hours == 18L,
  pass_day$day_eligible,
  !pass_day$day_eligible_after_hour,
  fail_day$day_valid_minutes_raw == 1151L,
  fail_day$day_valid_minutes_after_hour == 1080L,
  fail_day$day_eligible_hours == 18L,
  !fail_day$day_eligible,
  !fail_day$day_eligible_after_hour
)
pass_hours <- boundary$hourly[boundary$hourly$Id == "PASS", ]
pass_minutes <- boundary$real_minutes |>
  dplyr::filter(.data$Id == "PASS", .data$clock_minute == 1080L)
stopifnot(
  pass_hours$hour_valid_minutes[pass_hours$clock_hour == 18L] == 24L,
  pass_hours$hour_valid_minutes[pass_hours$clock_hour == 19L] == 24L,
  all(!pass_hours$hour_eligible[
    pass_hours$clock_hour %in% c(18L, 19L, 20L)
  ]),
  pass_minutes$coverage_period_eligible,
  !pass_minutes$hourly_metric_period_eligible,
  !pass_minutes$hour_screened_coverage_period_eligible
)

hour_boundary <- rep(NA_real_, 1440L)
hour_boundary[1:1200] <- 1
hour_boundary[1201:1230] <- 1
hour_boundary[1261:1289] <- 1
hour_result <- apply_wall_clock_coverage_rules(
  new_minute_day("2026-01-02", hour_boundary)
)
hour_summary <- hour_result$hourly
stopifnot(
  hour_summary$hour_valid_fraction[hour_summary$clock_hour == 20L] == 0.5,
  hour_summary$hour_eligible[hour_summary$clock_hour == 20L],
  hour_summary$hour_valid_minutes[hour_summary$clock_hour == 21L] == 29L,
  !hour_summary$hour_eligible[hour_summary$clock_hour == 21L],
  hour_result$daily$day_valid_minutes_raw == 1259L,
  hour_result$daily$day_valid_fraction_raw == 1259 / 1440,
  hour_result$daily$day_valid_minutes_after_hour == 1230L,
  hour_result$daily$day_eligible_hours == 21L,
  hour_result$daily$day_eligible,
  hour_result$daily$day_eligible_after_hour
)

message("Testing the otherwise eligible all-zero melEDI day exclusion")
all_zero_source <- new_minute_day(
  "2026-01-03",
  rep(0, 1440L),
  id = "ALL_ZERO"
)
all_zero_primary <- apply_wall_clock_coverage_rules(all_zero_source)
stopifnot(
  all_zero_primary$daily$day_valid_minutes_raw == 1440L,
  all_zero_primary$daily$day_zero_medi_minutes_raw == 1440L,
  all_zero_primary$daily$day_all_finite_medi_zero,
  all_zero_primary$daily$day_eligible_without_all_zero_screen,
  all_zero_primary$daily$day_all_zero_medi_excluded,
  !all_zero_primary$daily$day_eligible,
  all(!all_zero_primary$real_minutes$coverage_period_eligible),
  all(
    all_zero_primary$real_minutes$
      all_zero_medi_inclusive_sensitivity_period_eligible
  )
)
all_zero_inclusive <- apply_wall_clock_coverage_rules(
  all_zero_source,
  exclude_all_zero_days = FALSE
)
stopifnot(
  all_zero_inclusive$daily$day_all_finite_medi_zero,
  !all_zero_inclusive$daily$day_all_zero_medi_excluded,
  all_zero_inclusive$daily$day_eligible,
  all(all_zero_inclusive$real_minutes$coverage_period_eligible)
)

message("Testing the fixed 1,440-minute denominator on a short clock day")
spring <- rep(1, 1440L)
spring[121:180] <- NA_real_
spring_result <- apply_wall_clock_coverage_rules(
  new_minute_day("2026-03-29", spring)
)
stopifnot(
  spring_result$daily$day_expected_wall_minutes == 1440L,
  spring_result$daily$day_valid_fraction_raw == 1380 / 1440,
  spring_result$daily$day_valid_minutes_after_hour == 1380L,
  spring_result$daily$day_valid_fraction_after_hour == 1380 / 1440,
  spring_result$daily$day_eligible_hours == 23L,
  spring_result$daily$day_eligible,
  spring_result$daily$day_eligible_after_hour,
  !spring_result$hourly$hour_eligible[
    spring_result$hourly$clock_hour == 2L
  ]
)

message("Testing mapping without averaging or dropping real DST-fold rows")
full_day <- new_minute_day("2024-10-27", rep(10, 1440L), id = "FOLD")
fold_duplicate <- full_day[121L, ]
fold_duplicate$datetime_utc <- max(full_day$datetime_utc) + 60
fold_duplicate$MEDI <- 30
fold_duplicate$LIGHT <- 60
fold_real <- dplyr::bind_rows(full_day, fold_duplicate)
fold_result <- apply_wall_clock_coverage_rules(fold_real)
mapped_fold <- fold_result$real_minutes |>
  dplyr::filter(.data$clock_minute == 120L) |>
  dplyr::arrange(.data$datetime_utc)
wall_fold <- fold_result$wall_minutes |>
  dplyr::filter(.data$clock_minute == 120L)
stopifnot(
  nrow(fold_result$real_minutes) == nrow(fold_real),
  nrow(mapped_fold) == 2L,
  identical(mapped_fold$MEDI, c(10, 30)),
  all(mapped_fold$coverage_period_eligible),
  all(mapped_fold$wall_dst_fold),
  all(mapped_fold$wall_source_real_minutes == 2L),
  wall_fold$MEDI == 20,
  wall_fold$source_real_minutes == 2L,
  fold_result$daily$day_observed_wall_minutes == 1440L,
  fold_result$daily$day_source_real_minutes == 1441L,
  fold_result$daily$day_dst_fold_minutes == 1L
)

message("Testing explicit participant-day indexing")
indexed_days <- tibble::tibble(
  site = "TEST",
  Id = "P01",
  position = "glasses",
  local_date = as.Date(c("2026-01-03", "2026-01-04"))
)
indexed_source <- new_minute_day(
  "2026-01-03",
  rep(1, 1440L),
  id = "P01"
)
indexed <- apply_wall_clock_coverage_rules(
  indexed_source,
  participant_days = indexed_days
)
stopifnot(
  nrow(indexed$daily) == 2L,
  indexed$daily$day_eligible[
    indexed$daily$local_date == as.Date("2026-01-03")
  ],
  !indexed$daily$day_eligible[
    indexed$daily$local_date == as.Date("2026-01-04")
  ],
  indexed$daily$day_valid_minutes_after_hour[
    indexed$daily$local_date == as.Date("2026-01-04")
  ] ==
    0L,
  indexed$daily$day_valid_fraction_raw[
    indexed$daily$local_date == as.Date("2026-01-04")
  ] ==
    0
)

message("All aggregation and coverage tests passed")
