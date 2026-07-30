source("scripts/pipeline/time_support.R")
source("scripts/pipeline/verify_rolling_windows.R")

expect_verified <- function(result) {
  if (!result$passed) {
    failed <- names(result$checks)[!result$checks]
    stop(
      result$label,
      " failed independent checks: ",
      paste(failed, collapse = ", "),
      call. = FALSE
    )
  }
  invisible(result)
}

message("Checking exact one-minute candidate domains")
stopifnot(
  identical(
    rolling_verifier_window_starts("brightest"),
    0:840
  ),
  identical(
    rolling_verifier_window_starts("darkest"),
    0:1439
  ),
  length(rolling_verifier_window_starts("brightest")) == 841L,
  length(rolling_verifier_window_starts("darkest")) == 1440L
)

day_start <- as.POSIXct("2026-01-01 00:00:00", tz = "UTC")
day_datetime <- day_start + 0:1439 * 60
clock_minute <- 0:1439
uniform_reference <- rep(1, 1440)

message("Checking minute-aligned non-wrapping M10")
m10_value <- rep(10, 1440)
m10_value[clock_minute >= 301 & clock_minute < 901] <- 100
m10 <- expect_verified(rolling_verifier_compare_case(
  value = m10_value,
  datetime = day_datetime,
  clock_minute = clock_minute,
  period = "brightest",
  reference_weight = uniform_reference,
  label = "synthetic::minute_aligned_m10"
))
stopifnot(
  m10$optimized$onset_clock_minute == 301,
  m10$optimized$midpoint_clock_minute == 601,
  m10$optimized$offset_clock_minute == 901,
  abs(m10$optimized$window_mean - 100) < 1e-10
)

message("Checking minute-aligned midnight-wrapping L10")
l10_value <- rep(100, 1440)
l10_value[clock_minute >= 1207 | clock_minute < 367] <- 0
l10 <- expect_verified(rolling_verifier_compare_case(
  value = l10_value,
  datetime = day_datetime,
  clock_minute = clock_minute,
  period = "darkest",
  reference_weight = uniform_reference,
  label = "synthetic::minute_aligned_l10"
))
stopifnot(
  l10$optimized$onset_clock_minute == 1207,
  l10$optimized$midpoint_clock_minute == 67,
  l10$optimized$offset_clock_minute == 367,
  l10$optimized$midpoint_day_shift == 1L,
  l10$optimized$offset_day_shift == 1L,
  abs(l10$optimized$window_mean) < 1e-10
)

message("Checking literal ordinary and profile-weighted support")
support_value <- 5 + (clock_minute %% 97) / 10
support_value[1:120] <- NA_real_
support_reference <- rep(4, 1440)
support_reference[1:120] <- 1
support_literal <- rolling_verifier_literal_summary(
  value = support_value,
  datetime = day_datetime,
  clock_minute = clock_minute,
  period = "brightest",
  reference_weight = support_reference
)
start_zero <- support_literal$candidates[
  support_literal$candidates$start == 0L,
  ,
  drop = FALSE
]
stopifnot(
  abs(start_zero$ordinary_support - 0.8) < 1e-12,
  abs(start_zero$profile_weighted_support - 1920 / 2040) < 1e-12,
  start_zero$candidate_supported
)
expect_verified(rolling_verifier_compare_case(
  value = support_value,
  datetime = day_datetime,
  clock_minute = clock_minute,
  period = "brightest",
  reference_weight = support_reference,
  label = "synthetic::nonuniform_support"
))

message("Checking 48-bin profile expansion and unsupported profile bins")
profile_48 <- seq(0.25, 2.60, length.out = 48L)
profile_case <- expect_verified(rolling_verifier_compare_case(
  value = 1 + (clock_minute %% 211),
  datetime = day_datetime,
  clock_minute = clock_minute,
  period = "darkest",
  reference_weight = profile_48,
  label = "synthetic::profile_48"
))
stopifnot(profile_case$passed)

profile_with_gap <- profile_48
profile_with_gap[[3L]] <- NA_real_
gap_case <- expect_verified(rolling_verifier_compare_case(
  value = 1 + (clock_minute %% 211),
  datetime = day_datetime,
  clock_minute = clock_minute,
  period = "brightest",
  reference_weight = profile_with_gap,
  label = "synthetic::unsupported_profile_bin"
))
gap_candidates <- gap_case$literal$candidates
stopifnot(
  any(is.na(gap_candidates$profile_weighted_support)),
  any(is.finite(gap_candidates$profile_weighted_support))
)

message("Checking circular tie handling")
m10_tie <- expect_verified(rolling_verifier_compare_case(
  value = rep(10, 1440),
  datetime = day_datetime,
  clock_minute = clock_minute,
  period = "brightest",
  reference_weight = uniform_reference,
  label = "synthetic::m10_full_tie"
))
stopifnot(
  m10_tie$optimized$tied_windows == 841L,
  m10_tie$optimized$level_estimable,
  !m10_tie$optimized$timing_estimable,
  all(is.na(c(
    m10_tie$optimized$onset_clock_minute,
    m10_tie$optimized$midpoint_clock_minute,
    m10_tie$optimized$offset_clock_minute
  ))),
  m10_tie$optimized$failure_reason == "all_candidates_tied"
)

m10_partial_tie_value <- rep(10, 1440)
m10_partial_tie_value[[1L]] <- 0
m10_partial_tie <- expect_verified(rolling_verifier_compare_case(
  value = m10_partial_tie_value,
  datetime = day_datetime,
  clock_minute = clock_minute,
  period = "brightest",
  reference_weight = uniform_reference,
  label = "synthetic::m10_partial_tie"
))
stopifnot(
  m10_partial_tie$optimized$tied_windows == 840L,
  m10_partial_tie$optimized$timing_estimable,
  all(is.finite(c(
    m10_partial_tie$optimized$onset_clock_minute,
    m10_partial_tie$optimized$midpoint_clock_minute,
    m10_partial_tie$optimized$offset_clock_minute
  ))),
  is.na(m10_partial_tie$optimized$failure_reason)
)

l10_tie <- expect_verified(rolling_verifier_compare_case(
  value = rep(10, 1440),
  datetime = day_datetime,
  clock_minute = clock_minute,
  period = "darkest",
  reference_weight = uniform_reference,
  label = "synthetic::l10_full_circle_tie"
))
stopifnot(
  l10_tie$optimized$tied_windows == 1440L,
  l10_tie$optimized$level_estimable,
  !l10_tie$optimized$timing_estimable,
  l10_tie$optimized$failure_reason == "low_tie_resultant"
)

message("Checking DST-fold wall-minute averaging and partial support")
fold_datetime <- c(
  day_datetime,
  max(day_datetime) + seq.int(1L, 60L) * 60
)
fold_clock <- c(clock_minute, 120:179)
fold_value <- c(rep(10, 1440), rep(30, 60))
fold_value[[1441L]] <- NA_real_
fold_reference <- rep(1, length(fold_value))
fold <- expect_verified(rolling_verifier_compare_case(
  value = fold_value,
  datetime = fold_datetime,
  clock_minute = fold_clock,
  period = "darkest",
  reference_weight = fold_reference,
  label = "synthetic::dst_fold"
))
fold_grid <- fold$literal$grid
stopifnot(
  fold$optimized$duplicate_wall_minutes == 60L,
  fold_grid$occurrences[fold_grid$clock_minute == 120L] == 2L,
  fold_grid$valid_occurrences[fold_grid$clock_minute == 120L] == 1L,
  fold_grid$observed_fraction[fold_grid$clock_minute == 120L] == 0.5,
  fold_grid$value[fold_grid$clock_minute == 120L] == 10,
  fold_grid$value[fold_grid$clock_minute == 121L] == 20
)

message("Checking deterministic irregular missingness in both searches")
irregular_value <- exp(sin(2 * pi * clock_minute / 1440) + 2) - 1
irregular_value[c(17:63, 482:511, 1001:1087)] <- NA_real_
irregular_reference <- 0.2 +
  (cos(2 * pi * (clock_minute - 180) / 1440) + 1)^2
for (period in c("brightest", "darkest")) {
  expect_verified(rolling_verifier_compare_case(
    value = irregular_value,
    datetime = day_datetime,
    clock_minute = clock_minute,
    period = period,
    reference_weight = irregular_reference,
    label = paste0("synthetic::irregular::", period)
  ))
}

coverage_paths <- c(
  "artifacts/03_coverage/light_glasses_coverage.rds",
  "artifacts/03_coverage/light_chest_coverage.rds"
)
map_path <- "artifacts/04_reference_profiles/metric_relevance_maps.rds"
if (all(file.exists(c(coverage_paths, map_path)))) {
  message("Checking a fixed representative sample of actual eligible days")
  actual <- rolling_verifier_actual_sample(
    coverage_paths = coverage_paths,
    relevance_map_path = map_path,
    maximum_days_per_placement = 3L
  )
  stopifnot(
    nrow(actual) >= 12L,
    all(actual$passed),
    all(
      actual$optimized_estimable == actual$literal_estimable
    ),
    max(actual$maximum_candidate_difference) < 1e-8,
    max(actual$maximum_summary_difference) < 1e-8
  )
  print(actual)
} else {
  message("Actual artifacts unavailable; actual-sample verification skipped")
}

message("Benchmarking optimized and literal one-minute searches")
benchmark <- do.call(
  rbind,
  lapply(
    c("brightest", "darkest"),
    function(period) {
      rolling_verifier_benchmark(
        value = irregular_value,
        datetime = day_datetime,
        clock_minute = clock_minute,
        reference_weight = irregular_reference,
        period = period,
        repetitions = 3L
      )
    }
  )
)
stopifnot(
  all(is.finite(benchmark$optimized_seconds_per_case)),
  all(is.finite(benchmark$literal_seconds_per_case)),
  all(benchmark$optimized_seconds_per_case < 5)
)
print(benchmark)

message("Independent rolling-window verification passed")
