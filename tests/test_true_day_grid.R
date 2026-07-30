source("scripts/pipeline/assertions.R")
source("scripts/pipeline/time_axes.R")

participant_days <- tibble::tibble(
  site = "TUM",
  Id = "TUM_S001",
  position = "glasses",
  local_date = as.Date(c(
    "2026-01-15",
    "2026-03-29",
    "2026-10-25"
  )),
  timezone = "Europe/Berlin"
)

grid <- build_true_minute_day_grid(participant_days)
day_counts <- grid |>
  dplyr::count(.data$local_date, name = "real_minutes") |>
  dplyr::arrange(.data$local_date)

stopifnot(
  identical(day_counts$real_minutes, c(1440L, 1380L, 1500L)),
  identical(
    unique(grid$day_expected_real_minutes[
      grid$local_date == as.Date("2026-01-15")
    ]),
    1440L
  ),
  identical(
    unique(grid$day_expected_real_minutes[
      grid$local_date == as.Date("2026-03-29")
    ]),
    1380L
  ),
  identical(
    unique(grid$day_expected_real_minutes[
      grid$local_date == as.Date("2026-10-25")
    ]),
    1500L
  ),
  identical(lubridate::tz(grid$datetime_utc), "UTC"),
  identical(lubridate::tz(grid$datetime_wall), "UTC"),
  !anyDuplicated(grid[c("site", "Id", "position", "datetime_utc")])
)

spring <- dplyr::filter(grid, .data$local_date == as.Date("2026-03-29"))
fall <- dplyr::filter(grid, .data$local_date == as.Date("2026-10-25"))

stopifnot(
  !any(spring$clock_minute %in% 120:179),
  sum(duplicated(fall$clock_minute)) == 60L,
  all(table(fall$clock_minute[fall$clock_minute %in% 120:179]) == 2L),
  setequal(unique(fall$utc_offset_minutes), c(60L, 120L)),
  sum(fall$is_dst) == 180L
)

adjacency <- grid |>
  dplyr::group_by(.data$local_date) |>
  dplyr::summarise(
    regular = all(diff(as.numeric(.data$datetime_utc)) == 60),
    .groups = "drop"
  )
stopifnot(all(adjacency$regular))

duplicate_index <- dplyr::bind_rows(
  participant_days[1L, ],
  participant_days[1L, ]
)
duplicate_error <- tryCatch(
  {
    build_true_minute_day_grid(duplicate_index)
    FALSE
  },
  error = function(error) TRUE
)
stopifnot(duplicate_error)

message("True-minute participant-day grid tests passed")
