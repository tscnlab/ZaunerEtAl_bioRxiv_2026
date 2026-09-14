source("scripts/pipeline/time_support.R")

expect_equal <- function(actual, expected, tolerance = 1e-10) {
  stopifnot(isTRUE(all.equal(actual, expected, tolerance = tolerance)))
}

expect_error <- function(code) {
  errored <- tryCatch(
    {
      force(code)
      FALSE
    },
    error = function(error) TRUE
  )
  stopifnot(errored)
}

message("Testing geometric-mean roundoff repair")
expect_equal(
  restore_nonnegative_geometric_mean(log10(0.1), zero_offset = 0.1),
  0
)
stopifnot(
  restore_nonnegative_geometric_mean(
    log10(0.1) - .Machine$double.eps,
    zero_offset = 0.1
  ) == 0
)
positive_zero_details <- geometric_mean_backtransform_details(
  log10(0.1) + .Machine$double.eps,
  zero_offset = 0.1,
  source_all_zero = TRUE
)
positive_nonzero_details <- geometric_mean_backtransform_details(
  log10(0.1) + .Machine$double.eps,
  zero_offset = 0.1,
  source_all_zero = FALSE
)
stopifnot(
  positive_zero_details$raw_value > 0,
  positive_zero_details$raw_value <= positive_zero_details$tolerance,
  positive_zero_details$value == 0,
  positive_zero_details$numerical_zero_reclassified,
  positive_zero_details$numerical_zero_reason ==
    "source_verified_all_zero_roundoff",
  positive_nonzero_details$value == positive_nonzero_details$raw_value,
  !positive_nonzero_details$numerical_zero_reclassified
)
expect_error(
  restore_nonnegative_geometric_mean(
    log10(0.09),
    zero_offset = 0.1
  )
)

message("Testing cumulative fixed-width sums against literal windows")
rolling_values <- (seq.int(0, 1439) %% 17) / 17
non_wrapped_starts <- seq.int(0L, 840L)
non_wrapped_literal <- vapply(
  non_wrapped_starts,
  function(start) {
    sum(rolling_values[start + seq_len(600L)])
  },
  numeric(1)
)
non_wrapped_fast <- fixed_width_window_sums(
  values = rolling_values,
  starts = non_wrapped_starts,
  window_width = 600L,
  wrap = FALSE
)
expect_equal(non_wrapped_fast, non_wrapped_literal, tolerance = 1e-12)

wrapped_starts <- seq.int(0L, 1439L)
wrapped_literal <- vapply(
  wrapped_starts,
  function(start) {
    indices <- ((start + seq.int(0L, 599L)) %% 1440L) + 1L
    sum(rolling_values[indices])
  },
  numeric(1)
)
wrapped_fast <- fixed_width_window_sums(
  values = rolling_values,
  starts = wrapped_starts,
  window_width = 600L,
  wrap = TRUE
)
expect_equal(wrapped_fast, wrapped_literal, tolerance = 1e-12)

message("Testing numeric profile-weighted coverage")
expect_equal(
  profile_weighted_coverage(c(1, 0.5), c(1, 3)),
  0.625
)
expect_equal(
  profile_weighted_coverage(c(TRUE, FALSE), c(1, 3)),
  0.25
)
stopifnot(
  is.na(profile_weighted_coverage(c(1, 1), c(0, 0))),
  is.na(profile_weighted_coverage(c(1, NA), c(1, 1)))
)

message("Testing observed and support-corrected dose")
dose_low <- time_sensitive_integral(
  value = c(10, 20),
  reference_weight = c(1, 3),
  epoch_hours = 1,
  observed_fraction = c(1, 0.5)
)
stopifnot(
  dose_low$observed_integral == 20,
  dose_low$ordinary_coverage == 0.75,
  dose_low$relevance_coverage == 0.625,
  is.na(dose_low$corrected_integral),
  !dose_low$correction_admissible,
  dose_low$failure_reason == "low_relevance_coverage"
)
dose_high <- time_sensitive_integral(
  value = c(10, 20),
  reference_weight = c(1, 1),
  epoch_hours = 1,
  observed_fraction = c(1, 0.8)
)
stopifnot(
  dose_high$observed_integral == 26,
  dose_high$ordinary_coverage == 0.9,
  dose_high$correction_admissible
)
expect_equal(dose_high$corrected_integral, 26 / 0.9)
dose_empty <- time_sensitive_integral(
  value = c(NA_real_, NA_real_),
  reference_weight = c(1, 1),
  epoch_hours = 1
)
stopifnot(
  is.na(dose_empty$observed_integral),
  is.na(dose_empty$corrected_integral),
  dose_empty$failure_reason == "no_observed_value"
)
dose_unknown_support <- time_sensitive_integral(
  value = c(10, 20),
  reference_weight = c(1, 1),
  epoch_hours = 1,
  observed_fraction = c(1, NA_real_)
)
stopifnot(
  is.na(dose_unknown_support$observed_integral),
  dose_unknown_support$failure_reason == "unknown_observation_support"
)

message("Testing strict thresholds, actual durations, and gap-aware runs")
threshold_start <- as.POSIXct("2026-01-01 00:00:00", tz = "UTC")
gapped_time <- threshold_start + c(0, 60, 180, 240)
strict <- gap_aware_threshold_summary(
  value = rep(10, 4),
  datetime = gapped_time,
  threshold = 10,
  comparison = "above"
)
stopifnot(strict$duration_seconds == 0, strict$threshold_epochs == 0L)
gapped <- gap_aware_threshold_summary(
  value = rep(11, 4),
  datetime = gapped_time,
  threshold = 10,
  comparison = "above"
)
stopifnot(
  gapped$duration_seconds == 240,
  gapped$longest_seconds == 120,
  gapped$qualifying_runs == 2L
)
actual_duration <- gap_aware_threshold_summary(
  value = c(11, 11),
  datetime = threshold_start + c(0, 60),
  threshold = 10,
  comparison = "above",
  interval_seconds = c(30, 60)
)
stopifnot(
  actual_duration$duration_seconds == 90,
  actual_duration$longest_seconds == 90
)
segmented <- gap_aware_threshold_summary(
  value = c(11, 11),
  datetime = threshold_start + c(0, 60),
  threshold = 10,
  comparison = "above",
  segment = c("A", "B")
)
stopifnot(
  segmented$longest_seconds == 60,
  segmented$qualifying_runs == 2L
)
expect_error(gap_aware_threshold_summary(
  value = c(11, 11),
  datetime = rep(threshold_start, 2),
  threshold = 10
))

message("Testing circular timing and relevance-aware boundary censoring")
midnight_mean <- circular_summary_minutes(c(1435, 5))
stopifnot(
  midnight_mean$estimable,
  circular_distance_minutes(midnight_mean$mean, 0) < 1e-8
)
opposed <- circular_summary_minutes(c(0, 720))
stopifnot(!opposed$estimable, is.na(opposed$mean))
timing_datetime <- threshold_start + seq.int(0, 119) * 60
timing_value <- rep(0, 120)
timing_value[1:30] <- NA_real_
timing_value[61] <- 300
timing_reference <- rep(1, 120)
timing_reference[1:30] <- 0
timing <- threshold_timing_summary(
  value = timing_value,
  datetime = timing_datetime,
  threshold = 250,
  comparison = "above",
  clock_minute = 0:119,
  reference_weight = timing_reference
)
stopifnot(
  timing$threshold_observed,
  !timing$first_censored,
  timing$strict_first_censored,
  timing$first_clock_minute == 60
)

message("Testing fixed support-aware M10 and L10 windows")
day_datetime <- threshold_start + seq.int(0, 1439) * 60
clock_minute <- 0:1439
uniform_reference <- rep(1, 1440)
m10_value <- rep(10, 1440)
m10_value[clock_minute >= 300 & clock_minute < 900] <- 100
m10 <- rolling_window_summary(
  value = m10_value,
  datetime = day_datetime,
  clock_minute = clock_minute,
  period = "brightest",
  reference_weight = uniform_reference
)
stopifnot(
  m10$estimable,
  m10$timing_estimable,
  m10$onset_clock_minute == 300,
  m10$midpoint_clock_minute == 600,
  m10$offset_clock_minute == 900,
  m10$midpoint_day_shift == 0L,
  m10$offset_day_shift == 0L
)
expect_equal(m10$window_mean, 100)

m10_minute_value <- rep(10, 1440)
m10_minute_value[
  clock_minute >= 301 & clock_minute < 901
] <- 100
m10_minute <- rolling_window_summary(
  value = m10_minute_value,
  datetime = day_datetime,
  clock_minute = clock_minute,
  period = "brightest",
  reference_weight = uniform_reference
)
stopifnot(
  m10_minute$estimable,
  m10_minute$timing_estimable,
  m10_minute$onset_clock_minute == 301,
  m10_minute$midpoint_clock_minute == 601,
  m10_minute$offset_clock_minute == 901
)
expect_equal(m10_minute$window_mean, 100)

l10_value <- rep(100, 1440)
l10_value[clock_minute >= 1200 | clock_minute < 360] <- 0
l10 <- rolling_window_summary(
  value = l10_value,
  datetime = day_datetime,
  clock_minute = clock_minute,
  period = "darkest",
  reference_weight = uniform_reference
)
stopifnot(
  l10$estimable,
  l10$timing_estimable,
  l10$onset_clock_minute == 1200,
  l10$midpoint_clock_minute == 60,
  l10$offset_clock_minute == 360,
  l10$midpoint_day_shift == 1L,
  l10$offset_day_shift == 1L
)
expect_equal(l10$window_mean, 0)
stopifnot(
  abs(l10$window_raw_backtransformed_mean) <=
    l10$numerical_zero_tolerance,
  l10$selected_window_wall_minutes == 600L,
  l10$selected_window_valid_wall_minutes == 600L,
  l10$selected_window_zero_wall_minutes == 600L,
  l10$selected_window_positive_wall_minutes == 0L,
  l10$selected_window_missing_wall_minutes == 0L,
  l10$selected_window_start_clock_minute == 1200L,
  l10$selected_window_end_clock_minute == 360L,
  l10$selected_window_wraps_midnight
)

l10_minute_value <- rep(100, 1440)
l10_minute_value[
  clock_minute >= 1207 | clock_minute < 367
] <- 0
l10_minute <- rolling_window_summary(
  value = l10_minute_value,
  datetime = day_datetime,
  clock_minute = clock_minute,
  period = "darkest",
  reference_weight = uniform_reference
)
stopifnot(
  l10_minute$estimable,
  l10_minute$timing_estimable,
  l10_minute$onset_clock_minute == 1207,
  l10_minute$midpoint_clock_minute == 67,
  l10_minute$offset_clock_minute == 367,
  l10_minute$midpoint_day_shift == 1L,
  l10_minute$offset_day_shift == 1L
)
expect_equal(l10_minute$window_mean, 0)

l10_missing <- l10_value
l10_missing[1:30] <- NA_real_
l10_supported <- rolling_window_summary(
  value = l10_missing,
  datetime = day_datetime,
  clock_minute = clock_minute,
  period = "darkest",
  reference_weight = uniform_reference
)
stopifnot(
  l10_supported$estimable,
  l10_supported$onset_clock_minute == 1200
)
expect_equal(l10_supported$ordinary_support, 0.95)
expect_equal(l10_supported$profile_weighted_support, 0.95)

l10_tie <- rolling_window_summary(
  value = rep(10, 1440),
  datetime = day_datetime,
  clock_minute = clock_minute,
  period = "darkest",
  reference_weight = uniform_reference
)
stopifnot(
  l10_tie$level_estimable,
  !l10_tie$timing_estimable,
  l10_tie$tied_windows == 1440L,
  l10_tie$failure_reason == "low_tie_resultant"
)

m10_all_tie <- rolling_window_summary(
  value = rep(10, 1440),
  datetime = day_datetime,
  clock_minute = clock_minute,
  period = "brightest",
  reference_weight = uniform_reference
)
stopifnot(
  m10_all_tie$level_estimable,
  !m10_all_tie$timing_estimable,
  m10_all_tie$tied_windows == 841L,
  is.finite(m10_all_tie$window_mean),
  all(is.na(c(
    m10_all_tie$onset_clock_minute,
    m10_all_tie$midpoint_clock_minute,
    m10_all_tie$offset_clock_minute
  ))),
  m10_all_tie$failure_reason == "all_candidates_tied"
)

m10_partial_tie_value <- rep(10, 1440)
m10_partial_tie_value[[1L]] <- 0
m10_partial_tie <- rolling_window_summary(
  value = m10_partial_tie_value,
  datetime = day_datetime,
  clock_minute = clock_minute,
  period = "brightest",
  reference_weight = uniform_reference
)
stopifnot(
  m10_partial_tie$level_estimable,
  m10_partial_tie$timing_estimable,
  m10_partial_tie$tied_windows == 840L,
  all(is.finite(c(
    m10_partial_tie$onset_clock_minute,
    m10_partial_tie$midpoint_clock_minute,
    m10_partial_tie$offset_clock_minute
  ))),
  is.na(m10_partial_tie$failure_reason)
)

fold_datetime <- c(
  day_datetime,
  max(day_datetime) + seq.int(1, 60) * 60
)
fold_clock <- c(clock_minute, 120:179)
fold_window <- rolling_window_summary(
  value = rep(10, length(fold_datetime)),
  datetime = fold_datetime,
  clock_minute = fold_clock,
  period = "darkest",
  reference_weight = rep(1, length(fold_datetime))
)
stopifnot(fold_window$duplicate_wall_minutes == 60L)

message("Testing MDER as the mean of viable one-minute ratios")
mder <- mder_mean_of_viable_ratios(
  medi = c(1, 9),
  light = c(1, 3),
  minimum_viable_fraction = 0.50
)
expect_equal(mder$MDER, mean(c(1, 3)))
stopifnot(
  mder$viable_ratio_minutes == 2L,
  mder$expected_minutes == 2L,
  mder$viable_ratio_fraction == 1,
  mder$minimum_viable_fraction == 0.50,
  mder$passes_viable_ratio_support,
  mder$support_threshold_enforced,
  !mder$ratio_scaled_or_weighted,
  mder$estimable,
  is.na(mder$failure_reason)
)

message("Testing zero/non-finite exclusions and inclusive 50% support")
mder_boundary <- mder_mean_of_viable_ratios(
  medi = c(2, 6, 0, NA_real_),
  light = c(1, 2, 5, 1),
  minimum_viable_fraction = 0.50
)
expect_equal(mder_boundary$MDER, mean(c(2, 3)))
stopifnot(
  mder_boundary$viable_ratio_minutes == 2L,
  mder_boundary$expected_minutes == 4L,
  mder_boundary$viable_ratio_fraction == 0.50,
  mder_boundary$excluded_nonfinite_source_minutes == 1L,
  mder_boundary$excluded_zero_either_minutes == 1L,
  mder_boundary$passes_viable_ratio_support,
  mder_boundary$estimable
)

mder_below <- mder_mean_of_viable_ratios(
  medi = c(2, 0, NA_real_, 4),
  light = c(1, 2, 1, 0),
  minimum_viable_fraction = 0.50
)
stopifnot(
  is.na(mder_below$MDER),
  mder_below$viable_ratio_minutes == 1L,
  mder_below$viable_ratio_fraction == 0.25,
  !mder_below$passes_viable_ratio_support,
  !mder_below$estimable,
  mder_below$failure_reason == "below_viable_ratio_fraction"
)

mder_zero <- mder_mean_of_viable_ratios(
  medi = c(0, 2),
  light = c(1, 0),
  minimum_viable_fraction = 0.50
)
stopifnot(
  is.na(mder_zero$MDER),
  mder_zero$viable_ratio_minutes == 0L,
  mder_zero$excluded_zero_either_minutes == 2L,
  !mder_zero$estimable,
  mder_zero$failure_reason == "no_viable_momentary_ratio"
)

new_is_iv_data <- function(
  hourly_clock,
  hourly_date,
  hourly_value,
  start = as.POSIXct("2026-01-01 00:00:00", tz = "UTC")
) {
  n_hours <- length(hourly_clock)
  stopifnot(
    length(hourly_date) == n_hours,
    length(hourly_value) == n_hours
  )
  minute <- rep(0:59, times = n_hours)
  tibble::tibble(
    value = rep(hourly_value, each = 60),
    datetime = start + seq.int(0, n_hours * 60 - 1L) * 60,
    clock_hour = rep(hourly_clock, each = 60),
    clock_minute = rep(hourly_clock * 60, each = 60) + minute,
    local_date = rep(as.Date(hourly_date), each = 60)
  )
}

message("Testing support-aware IS and absolute-adjacency IV")
three_day <- new_is_iv_data(
  hourly_clock = rep(0:23, times = 3),
  hourly_date = rep(as.Date("2026-01-01") + 0:2, each = 24),
  hourly_value = rep(1:24, times = 3)
)
is_iv <- gap_aware_is_iv(
  value = three_day$value,
  datetime = three_day$datetime,
  clock_hour = three_day$clock_hour,
  clock_minute = three_day$clock_minute,
  local_date = three_day$local_date
)
stopifnot(
  is_iv$is_estimable,
  is_iv$iv_estimable,
  is_iv$valid_minutes == nrow(three_day),
  is_iv$expected_minutes == nrow(three_day),
  is_iv$valid_hours == 72L,
  is_iv$is_wall_hours == 72L,
  is_iv$adjacent_pairs == 71L,
  is_iv$adjacent_pair_days == 3L
)
expect_equal(is_iv$interdaily_stability, 1)

two_day <- three_day[three_day$local_date < as.Date("2026-01-03"), ]
two_day_result <- gap_aware_is_iv(
  value = two_day$value,
  datetime = two_day$datetime,
  clock_hour = two_day$clock_hour,
  clock_minute = two_day$clock_minute,
  local_date = two_day$local_date
)
stopifnot(
  !two_day_result$is_estimable,
  !two_day_result$iv_estimable,
  two_day_result$is_failure_reason == "insufficient_days",
  two_day_result$iv_failure_reason == "insufficient_days"
)

hour_gap <- three_day
gap_rows <- hour_gap$datetime >= threshold_start + 30 * 3600 &
  hour_gap$datetime < threshold_start + 31 * 3600
hour_gap$value[which(gap_rows)[30:60]] <- NA_real_
gap_result <- gap_aware_is_iv(
  value = hour_gap$value,
  datetime = hour_gap$datetime,
  clock_hour = hour_gap$clock_hour,
  clock_minute = hour_gap$clock_minute,
  local_date = hour_gap$local_date
)
stopifnot(
  gap_result$valid_minutes == sum(is.finite(hour_gap$value)),
  gap_result$expected_minutes == nrow(hour_gap),
  gap_result$valid_minutes != gap_result$valid_hours * 60,
  gap_result$valid_hours == 71L,
  gap_result$adjacent_pairs == 69L
)

insufficient_clock <- three_day
insufficient_clock$value[insufficient_clock$clock_hour >= 19] <- NA_real_
clock_result <- gap_aware_is_iv(
  value = insufficient_clock$value,
  datetime = insufficient_clock$datetime,
  clock_hour = insufficient_clock$clock_hour,
  clock_minute = insufficient_clock$clock_minute,
  local_date = insufficient_clock$local_date
)
stopifnot(
  !clock_result$is_estimable,
  clock_result$is_clock_hours == 19L,
  clock_result$is_failure_reason == "insufficient_clock_support"
)

insufficient_pairs <- three_day
insufficient_pairs$value[insufficient_pairs$clock_hour >= 8] <- NA_real_
pair_result <- gap_aware_is_iv(
  value = insufficient_pairs$value,
  datetime = insufficient_pairs$datetime,
  clock_hour = insufficient_pairs$clock_hour,
  clock_minute = insufficient_pairs$clock_minute,
  local_date = insufficient_pairs$local_date
)
stopifnot(
  !pair_result$iv_estimable,
  pair_result$adjacent_pairs == 21L,
  pair_result$iv_failure_reason == "insufficient_adjacent_pairs"
)

constant_result <- gap_aware_is_iv(
  value = rep(1, nrow(three_day)),
  datetime = three_day$datetime,
  clock_hour = three_day$clock_hour,
  clock_minute = three_day$clock_minute,
  local_date = three_day$local_date
)
stopifnot(
  !constant_result$is_estimable,
  !constant_result$iv_estimable,
  constant_result$is_failure_reason == "undefined_variance",
  constant_result$iv_failure_reason == "undefined_variance"
)

message("Testing fall-back handling: IS collapses; IV preserves real hours")
fold_clock <- c(0, 1, 1, 2:23)
fold_value <- c(1, 2, 200, 3:24)
fold_data <- new_is_iv_data(
  hourly_clock = c(0:23, fold_clock, 0:23),
  hourly_date = c(
    rep(as.Date("2026-10-24"), 24),
    rep(as.Date("2026-10-25"), 25),
    rep(as.Date("2026-10-26"), 24)
  ),
  hourly_value = c(1:24, fold_value, 1:24),
  start = as.POSIXct("2026-10-24 00:00:00", tz = "UTC")
)
fold_result <- gap_aware_is_iv(
  value = fold_data$value,
  datetime = fold_data$datetime,
  clock_hour = fold_data$clock_hour,
  clock_minute = fold_data$clock_minute,
  local_date = fold_data$local_date
)
fold_day_value <- c(1, mean(c(2, 200)), 3:24)
expected_wall_value <- c(1:24, fold_day_value, 1:24)
expected_clock <- rep(0:23, times = 3)
expected_overall <- mean(expected_wall_value)
expected_total_ss <- sum((expected_wall_value - expected_overall)^2)
expected_clock_mean <- vapply(
  0:23,
  function(hour) mean(expected_wall_value[expected_clock == hour]),
  numeric(1)
)
expected_is <- sum(3 * (expected_clock_mean - expected_overall)^2) /
  expected_total_ss
stopifnot(
  fold_result$valid_minutes == nrow(fold_data),
  fold_result$expected_minutes == nrow(fold_data),
  fold_result$valid_hours == 73L,
  fold_result$is_wall_hours == 72L,
  fold_result$is_folded_hours == 1L,
  fold_result$adjacent_pairs == 72L,
  fold_result$adjacent_pair_days == 3L
)
expect_equal(fold_result$interdaily_stability, expected_is)

message("All support-aware metric tests passed")
