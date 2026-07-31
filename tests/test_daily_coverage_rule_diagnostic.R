source("scripts/pipeline/paths_io.R")
source("scripts/pipeline/assertions.R")
source("scripts/pipeline/aggregation_coverage.R")
source("scripts/pipeline/daily_coverage_rule_diagnostic.R")
source("scripts/pipeline/build_daily_coverage_rule_diagnostic.R")

new_daily_coverage_day <- function(
  date,
  id,
  medi = rep(1, 1440L),
  state = rep("wake", 1440L),
  site = "TEST",
  placement = "glasses",
  fold_clock_minute = integer(),
  fold_medi = numeric(),
  fold_state = character()
) {
  if (length(medi) != 1440L || length(state) != 1440L) {
    stop("Synthetic days require 1,440 MEDI and state values", call. = FALSE)
  }
  clock_minute <- 0:1439
  datetime_wall <- as.POSIXct(date, tz = "UTC") + clock_minute * 60
  day <- tibble::tibble(
    site = site,
    Id = id,
    position = placement,
    datetime_utc = datetime_wall,
    datetime_wall = datetime_wall,
    local_date = as.Date(date),
    clock_minute = clock_minute,
    utc_offset_minutes = 0L,
    MEDI = medi,
    State.Brown = state
  )
  if (length(fold_clock_minute) > 0L) {
    if (
      length(fold_medi) != length(fold_clock_minute) ||
        length(fold_state) != length(fold_clock_minute)
    ) {
      stop("Synthetic fold values must match fold clock minutes", call. = FALSE)
    }
    duplicate <- day[
      match(fold_clock_minute, day$clock_minute),
      ,
      drop = FALSE
    ]
    duplicate$datetime_utc <- max(day$datetime_utc) +
      seq_along(fold_clock_minute) * 60
    duplicate$utc_offset_minutes <- -60L
    duplicate$MEDI <- fold_medi
    duplicate$State.Brown <- fold_state
    day <- dplyr::bind_rows(day, duplicate) |>
      dplyr::arrange(.data$datetime_utc)
  }
  day
}

rule_day <- function(diagnostic, id, rule) {
  diagnostic$daily_detail |>
    dplyr::filter(.data$Id == .env$id, .data$rule == .env$rule)
}

message("Testing mixed-state fall-back fractional support")
mixed_fold <- new_daily_coverage_day(
  date = "2026-10-25",
  id = "MIXED",
  fold_clock_minute = 120L,
  fold_medi = NA_real_,
  fold_state = "sleep"
)
mixed_result <- compare_daily_coverage_rules(mixed_fold)
mixed_wall <- mixed_result$wall_grid |>
  dplyr::filter(.data$clock_minute == 120L)
mixed_a <- rule_day(mixed_result, "MIXED", "A_full_day")
mixed_b <- rule_day(mixed_result, "MIXED", "B_sleep_excluded_daily")
mixed_c <- rule_day(
  mixed_result,
  "MIXED",
  "C_sleep_excluded_hourly_daily"
)
stopifnot(
  nrow(mixed_wall) == 1L,
  mixed_wall$source_real_minutes == 2L,
  mixed_wall$coverage_signal_observed,
  mixed_wall$waking_expected_mass == 0.5,
  mixed_wall$waking_valid_mass == 0.5,
  mixed_wall$known_sleep_mass == 0.5,
  mixed_a$day_expected_support_minutes == 1440,
  mixed_b$day_expected_support_minutes == 1439.5,
  mixed_c$day_expected_support_minutes == 1439.5,
  mixed_b$day_waking_valid_minutes_raw == 1439.5,
  mixed_b$day_eligible,
  mixed_c$day_eligible
)

message("Testing a fully sleeping hour")
sleep_hour_medi <- rep(1, 1440L)
sleep_hour_medi[1:60] <- NA_real_
sleep_hour_state <- rep("wake", 1440L)
sleep_hour_state[1:60] <- "sleep"
sleep_hour <- new_daily_coverage_day(
  date = "2026-01-02",
  id = "SLEEP_HOUR",
  medi = sleep_hour_medi,
  state = sleep_hour_state
)
sleep_result <- compare_daily_coverage_rules(sleep_hour)
sleep_b_hour <- sleep_result$current_hourly |>
  dplyr::filter(.data$clock_hour == 0L)
sleep_c_hour <- sleep_result$wake_hourly |>
  dplyr::filter(.data$clock_hour == 0L)
sleep_b <- rule_day(
  sleep_result,
  "SLEEP_HOUR",
  "B_sleep_excluded_daily"
)
sleep_c <- rule_day(
  sleep_result,
  "SLEEP_HOUR",
  "C_sleep_excluded_hourly_daily"
)
stopifnot(
  !sleep_b_hour$hour_eligible,
  sleep_b_hour$hour_valid_fraction == 0,
  !sleep_c_hour$hour_evaluable,
  is.na(sleep_c_hour$hour_valid_fraction),
  sleep_c_hour$hour_support_pass,
  sleep_c_hour$hour_structurally_excluded,
  sleep_b$day_expected_support_minutes == 1380,
  sleep_b$day_support_fraction_used == 1,
  sleep_b$hour_gate_exempt_hours == 0L,
  sleep_c$day_expected_support_minutes == 1380,
  sleep_c$day_support_fraction_used == 1,
  sleep_c$hour_gate_exempt_hours == 1L
)

message("Testing that unknown state is retained in expected support")
unknown_day <- new_daily_coverage_day(
  date = "2026-01-03",
  id = "UNKNOWN",
  medi = c(NA_real_, rep(1, 1439L)),
  state = rep(NA_character_, 1440L)
)
unknown_result <- compare_daily_coverage_rules(unknown_day)
unknown_b <- rule_day(
  unknown_result,
  "UNKNOWN",
  "B_sleep_excluded_daily"
)
unknown_c <- rule_day(
  unknown_result,
  "UNKNOWN",
  "C_sleep_excluded_hourly_daily"
)
stopifnot(
  unknown_b$day_expected_support_minutes == 1440,
  unknown_c$day_expected_support_minutes == 1440,
  unknown_b$day_unknown_state_minutes == 1440,
  unknown_c$day_unknown_state_minutes == 1440,
  unknown_b$day_known_sleep_minutes == 0,
  unknown_c$day_known_sleep_minutes == 0
)

message("Testing inclusive 50% hourly and 80% daily boundaries")
exact_boundary <- rep(NA_real_, 1440L)
exact_boundary[1:1080] <- 1
exact_boundary[1081:1110] <- 1
exact_boundary[1141:1182] <- 1
boundary_day <- new_daily_coverage_day(
  date = "2026-01-04",
  id = "BOUNDARY",
  medi = exact_boundary
)
boundary_result <- compare_daily_coverage_rules(boundary_day)
boundary_c_hour <- boundary_result$wake_hourly |>
  dplyr::filter(.data$clock_hour == 18L)
boundary_detail <- boundary_result$daily_detail |>
  dplyr::filter(.data$Id == "BOUNDARY")
stopifnot(
  boundary_c_hour$hour_valid_support_minutes == 30,
  boundary_c_hour$hour_valid_fraction == 0.5,
  boundary_c_hour$hour_support_pass,
  all(boundary_detail$day_valid_support_minutes_after_hour == 1152),
  all(boundary_detail$day_support_fraction_used == 0.8),
  all(boundary_detail$day_eligible)
)

message("Testing no-sleep equivalence and exact primary rule A")
no_sleep <- new_daily_coverage_day(
  date = "2026-01-05",
  id = "NO_SLEEP",
  medi = c(rep(1, 1200L), rep(NA_real_, 240L)),
  state = rep("wake", 1440L)
)
no_sleep_result <- compare_daily_coverage_rules(no_sleep)
primary <- apply_wall_clock_coverage_rules(
  no_sleep,
  value_cols = "MEDI",
  coverage_signal = "MEDI"
)
no_sleep_detail <- no_sleep_result$daily_detail |>
  dplyr::filter(.data$Id == "NO_SLEEP") |>
  dplyr::arrange(.data$rule)
no_sleep_a <- rule_day(no_sleep_result, "NO_SLEEP", "A_full_day")
stopifnot(
  length(unique(no_sleep_detail$day_expected_support_minutes)) == 1L,
  length(unique(no_sleep_detail$day_valid_support_minutes_raw)) == 1L,
  length(unique(no_sleep_detail$day_valid_support_minutes_after_hour)) == 1L,
  length(unique(no_sleep_detail$day_support_fraction_used)) == 1L,
  length(unique(no_sleep_detail$day_eligible)) == 1L,
  no_sleep_a$day_expected_support_minutes ==
    primary$daily$day_expected_wall_minutes,
  no_sleep_a$day_valid_support_minutes_raw ==
    primary$daily$day_valid_minutes_raw,
  no_sleep_a$day_valid_support_minutes_after_hour ==
    primary$daily$day_valid_minutes_raw,
  no_sleep_a$day_support_fraction_used ==
    primary$daily$day_valid_fraction_raw,
  identical(no_sleep_a$day_eligible, primary$daily$day_eligible)
)

message("Testing all-zero melEDI exclusion across all three rules")
all_zero <- new_daily_coverage_day(
  date = "2026-01-06",
  id = "ALL_ZERO",
  medi = rep(0, 1440L),
  state = rep("wake", 1440L)
)
all_zero_result <- compare_daily_coverage_rules(all_zero)
all_zero_detail <- all_zero_result$daily_detail
stopifnot(
  nrow(all_zero_detail) == 3L,
  all(all_zero_detail$day_all_finite_medi_zero),
  all(all_zero_detail$day_eligible_without_all_zero_screen),
  all(all_zero_detail$day_all_zero_medi_excluded),
  all(!all_zero_detail$day_eligible),
  all(all_zero_detail$day_eligibility_reason == "all_zero_medi_day")
)

message("Building isolated diagnostic artifacts")
test_root <- tempfile("nathealth-daily-coverage-diagnostic-")
dir.create(test_root, recursive = TRUE)
on.exit(unlink(test_root, recursive = TRUE), add = TRUE)
paths <- pipeline_paths(test_root)
ensure_pipeline_directories(paths)
aligned_root <- file.path(paths$aligned, "runs", "smoke")
dir.create(aligned_root, recursive = TRUE)
builder_input <- dplyr::bind_rows(
  mixed_fold,
  sleep_hour,
  unknown_day,
  boundary_day,
  no_sleep
)
input_path <- file.path(aligned_root, "light_glasses_aligned.rds")
saveRDS(builder_input, input_path)
input_sha256 <- artifact_sha256(input_path)
builder <- build_daily_coverage_rule_diagnostic(
  root = test_root,
  run_label = "smoke",
  placements = "glasses"
)
stopifnot(artifact_sha256(input_path) == input_sha256)

message("Checking identifier separation, summaries, and bytewise manifest")
detail <- readRDS(builder$detail_path)
counts <- readr::read_csv(builder$counts_path, show_col_types = FALSE)
transitions <- readr::read_csv(
  builder$transitions_path,
  show_col_types = FALSE
)
settings <- readr::read_csv(builder$settings_path, show_col_types = FALSE)
inputs <- readr::read_csv(builder$inputs_path, show_col_types = FALSE)
manifest <- readr::read_csv(
  builder$artifact_manifest_path,
  show_col_types = FALSE
)
stopifnot(
  "Id" %in% names(detail),
  all(
    !vapply(
      list(counts, transitions, settings, inputs, manifest),
      function(data) "Id" %in% names(data),
      logical(1)
    )
  ),
  setequal(unique(counts$scope), c("site", "overall")),
  all(c("TEST", "ALL") %in% counts$site),
  all(
    counts$participants[
      counts$scope == "overall"
    ] ==
      5L
  ),
  all(
    counts$eligible_participants[
      counts$scope == "overall"
    ] ==
      5L
  ),
  nrow(transitions) == 3L * 2L * 4L,
  all(
    c(
      "A_full_day",
      "B_sleep_excluded_daily",
      "C_sleep_excluded_hourly_daily"
    ) %in%
      settings$rule
  ),
  sum(settings$selected_as_primary) == 1L,
  settings$rule[settings$selected_as_primary] == "A_full_day",
  all(settings$status == "PRIMARY_WITH_FIXED_SENSITIVITIES"),
  identical(inputs$sha256, input_sha256),
  inputs$bytes == unname(file.info(input_path)$size),
  nrow(manifest) == 5L
)
detail_manifest <- manifest |>
  dplyr::filter(.data$artifact_type == "participant_day_rule_detail")
stopifnot(
  nrow(detail_manifest) == 1L,
  detail_manifest$sha256 == artifact_sha256(builder$detail_path),
  detail_manifest$bytes == unname(file.info(builder$detail_path)$size),
  all(
    vapply(
      manifest$path,
      function(path) artifact_sha256(path),
      character(1)
    ) ==
      manifest$sha256
  )
)

message("All daily coverage-rule diagnostic tests passed")
