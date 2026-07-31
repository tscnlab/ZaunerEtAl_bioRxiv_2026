source("scripts/pipeline/paths_io.R")
source("scripts/pipeline/assertions.R")
source("scripts/pipeline/aggregation_coverage.R")
source("scripts/pipeline/build_coverage_sample_flow.R")

new_aligned_day <- function(
  site,
  id,
  placement,
  date,
  medi,
  light,
  omit_clock_minute = integer(),
  fold_clock_minute = integer()
) {
  if (length(medi) != 1440L || length(light) != 1440L) {
    stop("Synthetic signals must have 1,440 values", call. = FALSE)
  }
  clock_minute <- setdiff(0:1439, omit_clock_minute)
  datetime_wall <- as.POSIXct(date, tz = "UTC") + clock_minute * 60
  data <- tibble::tibble(
    site = site,
    Id = id,
    position = placement,
    datetime_utc = datetime_wall,
    datetime_wall = datetime_wall,
    local_date = as.Date(date),
    clock_minute = clock_minute,
    utc_offset_minutes = 0L,
    is_dst = FALSE,
    MEDI = medi[clock_minute + 1L],
    LIGHT = light[clock_minute + 1L],
    MEDI_raw = dplyr::coalesce(medi[clock_minute + 1L], 100000),
    LIGHT_raw = dplyr::coalesce(light[clock_minute + 1L], 999),
    invalid_nonwear = FALSE,
    medi_saturated = is.na(medi[clock_minute + 1L])
  )
  if (length(fold_clock_minute) > 0L) {
    duplicate <- data[data$clock_minute %in% fold_clock_minute, , drop = FALSE]
    duplicate$datetime_utc <- max(data$datetime_utc) +
      seq_along(fold_clock_minute) * 60
    duplicate$utc_offset_minutes <- -60L
    duplicate$is_dst <- TRUE
    duplicate$MEDI <- duplicate$MEDI + 2
    duplicate$LIGHT <- duplicate$LIGHT + 4
    duplicate$MEDI_raw <- duplicate$MEDI
    duplicate$LIGHT_raw <- duplicate$LIGHT
    data <- dplyr::bind_rows(data, duplicate) |>
      dplyr::arrange(.data$datetime_utc)
  }
  data$valid_medi <- is.finite(data$MEDI)
  data$valid_light <- is.finite(data$LIGHT)
  data$valid_medi_light_pair <- data$valid_medi & data$valid_light
  data
}

message("Building isolated synthetic Preparation 02 inputs")
test_root <- tempfile("nathealth-coverage-test-")
dir.create(test_root, recursive = TRUE)
on.exit(unlink(test_root, recursive = TRUE), add = TRUE)
paths <- pipeline_paths(test_root)
ensure_pipeline_directories(paths)
aligned_run_root <- file.path(paths$aligned, "runs", "smoke")
dir.create(aligned_run_root, recursive = TRUE)

medi_a <- rep(10, 1440L)
light_a <- rep(20, 1440L)
medi_a[301L] <- NA_real_
light_a[401L] <- NA_real_
medi_a[601:631] <- NA_real_
site_a_glasses <- new_aligned_day(
  site = "A",
  id = "P01",
  placement = "glasses",
  date = "2026-01-01",
  medi = medi_a,
  light = light_a,
  omit_clock_minute = 100L,
  fold_clock_minute = 120L
)

medi_b <- c(rep(10, 1100L), rep(NA_real_, 340L))
light_b <- rep(20, 1440L)
site_b_glasses <- new_aligned_day(
  site = "B",
  id = "P01",
  placement = "glasses",
  date = "2026-01-01",
  medi = medi_b,
  light = light_b
)
site_c_glasses <- new_aligned_day(
  site = "C",
  id = "P01",
  placement = "glasses",
  date = "2026-01-01",
  medi = rep(0, 1440L),
  light = rep(0, 1440L)
)
glasses_input <- dplyr::bind_rows(
  site_a_glasses,
  site_b_glasses,
  site_c_glasses
)

chest_input <- new_aligned_day(
  site = "A",
  id = "P01",
  placement = "chest",
  date = "2026-01-01",
  medi = rep(12, 1440L),
  light = rep(24, 1440L)
)
glasses_input_path <- file.path(
  aligned_run_root,
  "light_glasses_aligned.rds"
)
chest_input_path <- file.path(
  aligned_run_root,
  "light_chest_aligned.rds"
)
saveRDS(glasses_input, glasses_input_path)
saveRDS(chest_input, chest_input_path)
glasses_input_sha256 <- artifact_sha256(glasses_input_path)
chest_input_sha256 <- artifact_sha256(chest_input_path)

message("Running Preparation 02 only on the isolated smoke root")
result <- build_coverage_sample_flow(
  root = test_root,
  run_label = "smoke",
  placements = c("glasses", "chest")
)
expected_output_root <- file.path(paths$coverage, "runs", "smoke")
stopifnot(
  identical(
    normalizePath(result$coverage_run_root, winslash = "/", mustWork = TRUE),
    normalizePath(expected_output_root, winslash = "/", mustWork = TRUE)
  ),
  !file.exists(file.path(paths$coverage, "light_glasses_coverage.rds")),
  artifact_sha256(glasses_input_path) == glasses_input_sha256,
  artifact_sha256(chest_input_path) == chest_input_sha256
)

message("Checking row preservation and separate eligible signal channels")
glasses <- readRDS(result$output_paths$glasses$eligible)
stopifnot(
  nrow(glasses) == nrow(glasses_input),
  identical(glasses$datetime_utc, glasses_input$datetime_utc),
  identical(glasses$MEDI, glasses_input$MEDI),
  identical(glasses$LIGHT, glasses_input$LIGHT),
  identical(glasses$MEDI_raw, glasses_input$MEDI_raw),
  identical(glasses$LIGHT_raw, glasses_input$LIGHT_raw),
  identical(glasses$MEDI_precoverage, glasses_input$MEDI),
  identical(glasses$LIGHT_precoverage, glasses_input$LIGHT)
)
medi_invalid_light_valid <- glasses |>
  dplyr::filter(
    .data$site == "A",
    .data$clock_minute == 300L
  )
light_invalid_medi_valid <- glasses |>
  dplyr::filter(
    .data$site == "A",
    .data$clock_minute == 400L
  )
failed_hour <- glasses |>
  dplyr::filter(
    .data$site == "A",
    .data$clock_minute == 631L
  )
failed_day <- glasses |>
  dplyr::filter(
    .data$site == "B",
    .data$clock_minute == 100L
  )
all_zero_day <- glasses |>
  dplyr::filter(
    .data$site == "C",
    .data$clock_minute == 100L
  )
stopifnot(
  nrow(medi_invalid_light_valid) == 1L,
  is.na(medi_invalid_light_valid$MEDI_eligible),
  medi_invalid_light_valid$LIGHT_eligible == 20,
  medi_invalid_light_valid$MEDI_eligibility_reason == "signal_invalidity",
  nrow(light_invalid_medi_valid) == 1L,
  light_invalid_medi_valid$MEDI_eligible == 10,
  is.na(light_invalid_medi_valid$LIGHT_eligible),
  light_invalid_medi_valid$LIGHT_eligibility_reason == "signal_invalidity",
  nrow(failed_hour) == 1L,
  failed_hour$coverage_period_eligible,
  !failed_hour$hourly_metric_period_eligible,
  !failed_hour$hour_screened_coverage_period_eligible,
  failed_hour$MEDI_eligible == 10,
  failed_hour$LIGHT_eligible == 20,
  is.na(failed_hour$LIGHT_eligibility_reason),
  nrow(failed_day) == 1L,
  !failed_day$day_eligible,
  is.na(failed_day$MEDI_eligible),
  is.na(failed_day$LIGHT_eligible),
  nrow(all_zero_day) == 1L,
  all_zero_day$day_all_finite_medi_zero,
  all_zero_day$day_eligible_without_all_zero_screen,
  all_zero_day$day_all_zero_medi_excluded,
  !all_zero_day$day_eligible,
  all_zero_day$all_zero_medi_inclusive_sensitivity_period_eligible,
  is.na(all_zero_day$MEDI_eligible),
  is.na(all_zero_day$LIGHT_eligible),
  all_zero_day$MEDI_eligibility_reason == "all_zero_medi_day",
  all_zero_day$LIGHT_eligibility_reason == "all_zero_medi_day"
)

message("Checking that both true instants in the synthetic fold survive")
fold_rows <- glasses |>
  dplyr::filter(.data$site == "A", .data$clock_minute == 120L) |>
  dplyr::arrange(.data$datetime_utc)
stopifnot(
  nrow(fold_rows) == 2L,
  length(unique(fold_rows$datetime_utc)) == 2L,
  length(unique(fold_rows$datetime_wall)) == 1L,
  all(fold_rows$wall_dst_fold),
  all(fold_rows$wall_source_real_minutes == 2L)
)

message("Checking hourly/day boundaries and reason-coded gap runs")
glasses_hourly <- readr::read_csv(
  result$output_paths$glasses$hourly,
  show_col_types = FALSE
)
glasses_daily <- readr::read_csv(
  result$output_paths$glasses$daily,
  show_col_types = FALSE
)
glasses_gaps <- readr::read_csv(
  result$output_paths$glasses$gaps,
  show_col_types = FALSE
)
stopifnot(
  !glasses_hourly$hour_eligible[
    glasses_hourly$site == "A" &
      glasses_hourly$clock_hour == 10L
  ],
  glasses_daily$day_eligible[glasses_daily$site == "A"],
  !glasses_daily$day_eligible[glasses_daily$site == "B"],
  glasses_daily$day_all_zero_medi_excluded[
    glasses_daily$site == "C"
  ],
  !glasses_daily$day_eligible[glasses_daily$site == "C"],
  setequal(
    unique(glasses_gaps$gap_reason),
    c(
      "raw_absence",
      "signal_invalidity",
      "all_zero_medi_day",
      "day_failure"
    )
  ),
  any(
    glasses_gaps$gap_reason == "raw_absence" &
      glasses_gaps$site == "A" &
      glasses_gaps$start_clock_minute == 100L &
      glasses_gaps$wall_minutes == 1L
  ),
  any(
    glasses_gaps$gap_reason == "signal_invalidity" &
      glasses_gaps$signal == "LIGHT"
  ),
  any(
    glasses_gaps$gap_reason == "all_zero_medi_day" &
      glasses_gaps$site == "C" &
      glasses_gaps$start_clock_minute == 0L &
      glasses_gaps$wall_minutes == 1440L
  ),
  all(glasses_gaps$wall_minutes >= 1L)
)

message("Checking by-site and overall stage-labelled sample flow")
sample_flow <- readr::read_csv(
  result$sample_flow_path,
  show_col_types = FALSE
)
stopifnot(
  setequal(unique(sample_flow$scope), c("site", "overall")),
  all(c("A", "B", "C", "ALL") %in% unique(sample_flow$site)),
  all(1:9 %in% unique(sample_flow$stage_order)),
  nrow(sample_flow[
    sample_flow$placement == "glasses" &
      sample_flow$scope == "overall",
  ]) ==
    9L,
  sample_flow$participants[
    sample_flow$placement == "glasses" &
      sample_flow$scope == "overall" &
      sample_flow$stage == "aligned_real_minutes"
  ] ==
    3L
)

message("Checking the approved primary coverage-rule provenance")
settings <- readr::read_csv(
  result$settings_path,
  show_col_types = FALSE
)
stopifnot(
  nrow(settings) == 2L,
  all(settings$coverage_rule_id == "A"),
  all(
    settings$daily_denominator_domain == "all_pseudo_local_wall_minutes"
  ),
  all(
    settings$daily_eligibility_basis ==
      "finite_medi_minutes_across_fixed_24_hour_cycle"
  ),
  all(settings$hourly_gate_scope == "hourly_metrics_only"),
  all(!settings$minute_values_masked_by_hour_gate),
  all(settings$hour_screened_sensitivity_available),
  all(settings$all_zero_medi_exclusion_applied),
  all(settings$all_zero_medi_sensitivity_available),
  settings$all_zero_medi_days_excluded[
    settings$placement == "glasses"
  ] == 1L,
  settings$all_zero_medi_days_excluded[
    settings$placement == "chest"
  ] == 0L,
  all(!settings$diary_sleep_excluded_from_denominator),
  all(settings$expected_wall_minutes_per_day == 1440L)
)

message("Checking complete artifact manifests and atomic reruns")
manifest <- readr::read_csv(
  result$artifact_manifest_path,
  show_col_types = FALSE
)
stopifnot(
  nrow(manifest) == 10L,
  all(file.exists(manifest$path)),
  all(vapply(
    seq_len(nrow(manifest)),
    function(index) {
      artifact_sha256(manifest$path[index]) == manifest$sha256[index]
    },
    logical(1)
  ))
)
eligible_sha256 <- artifact_sha256(
  result$output_paths$glasses$eligible
)
rerun <- build_coverage_sample_flow(
  root = test_root,
  run_label = "smoke",
  placements = c("glasses", "chest")
)
stopifnot(
  artifact_sha256(rerun$output_paths$glasses$eligible) == eligible_sha256,
  artifact_sha256(glasses_input_path) == glasses_input_sha256,
  artifact_sha256(chest_input_path) == chest_input_sha256
)

message("All Preparation 02 builder tests passed")
