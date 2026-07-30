options(warn = 2)

source("scripts/pipeline/assertions.R")
source("scripts/pipeline/temporal_sequence_provenance.R")

new_temporal_coverage_day <- function(
  local_date,
  timezone,
  Id,
  position = "glasses"
) {
  local_start <- as.POSIXct(
    paste(format(local_date, "%Y-%m-%d"), "00:00:00"),
    tz = timezone
  )
  next_local_start <- as.POSIXct(
    paste(format(local_date + 1L, "%Y-%m-%d"), "00:00:00"),
    tz = timezone
  )
  datetime_utc <- as.POSIXct(
    seq.int(
      as.numeric(local_start),
      as.numeric(next_local_start) - 60,
      by = 60
    ),
    origin = "1970-01-01",
    tz = "UTC"
  )
  local_fields <- as.POSIXlt(datetime_utc, tz = timezone)
  local_labels <- format(
    datetime_utc,
    "%Y-%m-%d %H:%M:%S",
    tz = timezone
  )
  offset <- format(datetime_utc, "%z", tz = timezone)
  offset_sign <- ifelse(substr(offset, 1L, 1L) == "-", -1L, 1L)
  offset_minutes <- offset_sign *
    (as.integer(substr(offset, 2L, 3L)) *
      60L +
      as.integer(substr(offset, 4L, 5L)))
  tibble::tibble(
    site = "TEST",
    Id = Id,
    position = position,
    datetime_utc = datetime_utc,
    datetime_wall = as.POSIXct(local_labels, tz = "UTC"),
    local_date = as.Date(local_labels),
    clock_minute = as.integer(
      local_fields$hour * 60L + local_fields$min
    ),
    utc_offset_minutes = as.integer(offset_minutes),
    is_dst = local_fields$isdst == 1L,
    timezone = timezone,
    source_subepochs = 6L,
    implicit_subepochs = 0L,
    MEDI_precoverage_observed = TRUE,
    coverage_period_eligible = TRUE,
    MEDI_coverage_eligible = TRUE
  )
}

new_temporal_metric <- function(coverage, resolution) {
  bin_minutes <- if (resolution == "30_minute") 30L else 60L
  clock_column <- if (resolution == "30_minute") {
    "clock_bin"
  } else {
    "clock_minute"
  }
  day_key <- c("site", "Id", "position", "local_date")
  wall_observed <- coverage |>
    dplyr::group_by(
      dplyr::across(dplyr::all_of(day_key)),
      .data$clock_minute
    ) |>
    dplyr::summarise(
      source_real_minutes = dplyr::n(),
      source_observed_real_minutes = sum(.data$source_subepochs > 0L),
      valid_medi = any(.data$MEDI_coverage_eligible),
      dst_fold = dplyr::n() > 1L,
      .groups = "drop"
    )
  domain <- coverage |>
    dplyr::distinct(dplyr::across(dplyr::all_of(day_key)))
  wall <- tidyr::crossing(
    domain,
    clock_minute = 0:1439
  ) |>
    dplyr::left_join(
      wall_observed,
      by = c(day_key, "clock_minute"),
      relationship = "one-to-one"
    ) |>
    dplyr::mutate(
      source_real_minutes = dplyr::coalesce(
        as.integer(.data$source_real_minutes),
        0L
      ),
      source_observed_real_minutes = dplyr::coalesce(
        as.integer(.data$source_observed_real_minutes),
        0L
      ),
      valid_medi = dplyr::coalesce(.data$valid_medi, FALSE),
      dst_fold = dplyr::coalesce(.data$dst_fold, FALSE),
      wall_bin_start_minute = as.integer(
        floor(.data$clock_minute / bin_minutes) * bin_minutes
      )
    ) |>
    dplyr::group_by(
      dplyr::across(dplyr::all_of(day_key)),
      .data$wall_bin_start_minute
    ) |>
    dplyr::summarise(
      expected_wall_minutes = as.integer(bin_minutes),
      wall_minutes_existing = sum(.data$source_real_minutes > 0L),
      source_real_minutes = sum(.data$source_real_minutes),
      source_observed_real_minutes = sum(
        .data$source_observed_real_minutes
      ),
      dst_fold_wall_minutes = sum(.data$dst_fold),
      valid_medi_wall_minutes = sum(.data$valid_medi),
      ordinary_support = .data$valid_medi_wall_minutes /
        .data$expected_wall_minutes,
      bin_admissible = .data$valid_medi_wall_minutes >= bin_minutes / 2L,
      failure_reason = ifelse(
        .data$bin_admissible,
        NA_character_,
        "insufficient_bin_support"
      ),
      metric_value_lx = ifelse(.data$bin_admissible, 10, NA_real_),
      metric = ifelse(
        resolution == "30_minute",
        "30_minute_arithmetic_mean_medi",
        "one_hour_zero_aware_geometric_mean_medi"
      ),
      .groups = "drop"
    )
  names(wall)[names(wall) == "wall_bin_start_minute"] <- clock_column
  wall
}

message("Testing ordinary, fall-back, and spring-forward mappings")
coverage <- dplyr::bind_rows(
  new_temporal_coverage_day(
    as.Date("2024-10-26"),
    "Europe/Berlin",
    "P01"
  ),
  new_temporal_coverage_day(
    as.Date("2024-10-27"),
    "Europe/Berlin",
    "P01"
  ),
  new_temporal_coverage_day(
    as.Date("2025-03-30"),
    "Europe/Berlin",
    "P02"
  )
)
metric_30 <- new_temporal_metric(coverage, "30_minute")
metric_30$metric_value_lx[
  metric_30$Id == "P01" &
    metric_30$local_date == as.Date("2024-10-26") &
    metric_30$clock_bin == 60L
] <- NA_real_
metric_30$bin_admissible[
  metric_30$Id == "P01" &
    metric_30$local_date == as.Date("2024-10-26") &
    metric_30$clock_bin == 60L
] <- FALSE
metric_30$failure_reason[
  metric_30$Id == "P01" &
    metric_30$local_date == as.Date("2024-10-26") &
    metric_30$clock_bin == 60L
] <- "synthetic_unusable_outcome"

result_30 <- build_temporal_sequence_provenance(
  coverage,
  metric_30,
  placement = "glasses",
  resolution = "30_minute"
)
stopifnot(
  nrow(result_30$source_bins) == 48L + 50L + 46L,
  nrow(result_30$wall_links) == 3L * 48L,
  sum(result_30$wall_links$source_bin_links == 2L) == 2L,
  sum(result_30$wall_links$source_bin_links == 0L) == 2L,
  all(
    !result_30$source_bins$sequence_eligible[
      result_30$source_bins$repeated_fall_back_source_bin
    ]
  ),
  all(
    result_30$source_bins$sequence_start_reason[
      result_30$source_bins$Id == "P02" &
        result_30$source_bins$wall_bin_start_minute == 180L
    ] ==
      "after_structural_wall_gap"
  ),
  all(
    result_30$source_bins$sequence_start_reason[
      result_30$source_bins$Id == "P01" &
        result_30$source_bins$local_date == as.Date("2024-10-26") &
        result_30$source_bins$wall_bin_start_minute == 90L
    ] ==
      "after_unusable_wall_outcome"
  )
)

message("Testing one-hour repeated-hour separation")
metric_hour <- new_temporal_metric(coverage, "one_hour")
result_hour <- build_temporal_sequence_provenance(
  coverage,
  metric_hour,
  placement = "glasses",
  resolution = "one_hour"
)
stopifnot(
  nrow(result_hour$source_bins) == 24L + 25L + 23L,
  nrow(result_hour$wall_links) == 3L * 24L,
  sum(result_hour$wall_links$source_bin_links == 2L) == 1L,
  sum(result_hour$wall_links$source_bin_links == 0L) == 1L,
  sum(result_hour$source_bins$repeated_fall_back_source_bin) == 2L,
  all(
    result_hour$wall_links$relationship_type[
      result_hour$wall_links$source_bin_links == 2L
    ] ==
      "two_to_one_averaged_fall_back"
  ),
  all(
    !result_hour$wall_links$one_to_one_elapsed_coordinate[
      result_hour$wall_links$source_bin_links != 1L
    ]
  )
)

message("Testing corruption rejection at the pure-function boundary")
duplicated_coverage <- dplyr::bind_rows(coverage, coverage[1L, ])
duplicate_error <- tryCatch(
  {
    build_temporal_sequence_provenance(
      duplicated_coverage,
      metric_30,
      placement = "glasses",
      resolution = "30_minute"
    )
    FALSE
  },
  error = function(error) {
    grepl("duplicated", conditionMessage(error), ignore.case = TRUE)
  }
)
stopifnot(duplicate_error)

message("Temporal sequence-provenance unit tests passed")
