source("scripts/pipeline/paths_io.R")
source("scripts/pipeline/assertions.R")
source("scripts/pipeline/time_axes.R")
source("scripts/pipeline/mder_support_gate.R")
source("scripts/pipeline/build_mder_support_gate.R")

new_mder_gate_profiles <- function(placement = "glasses") {
  clock_bin <- seq.int(0L, 1410L, by = 30L)
  daytime <- clock_bin >= 360L & clock_bin < 1080L
  values <- list(
    MEDI = ifelse(daytime, 100, 1),
    LIGHT = ifelse(daytime, 1, 100)
  )
  profiles <- dplyr::bind_rows(lapply(names(values), function(signal) {
    reference <- values[[signal]]
    tibble::tibble(
      profile_scope = "pooled",
      profile_variant = "pooled",
      profile_site = NA_character_,
      held_out_site = NA_character_,
      placement = placement,
      state_domain = "full_day",
      signal = signal,
      clock_bin = clock_bin,
      profile_supported = TRUE,
      reference_weight = reference / sum(reference)
    )
  }))
  maps <- profiles |>
    dplyr::mutate(
      metric_map = "paired_channel_coverage",
      map_estimable = TRUE,
      relevance_weight = .data$reference_weight,
      map_application = "paired_coverage_only",
      ratio_correction_allowed = FALSE
    )
  list(profiles = profiles, maps = maps)
}

new_mder_gate_day <- function(
  date,
  id,
  scenario,
  placement = "glasses",
  timezone = "UTC",
  site = "TEST"
) {
  day_index <- tibble::tibble(
    site = site,
    Id = id,
    position = placement,
    local_date = as.Date(date),
    timezone = timezone
  )
  grid <- build_true_minute_day_grid(day_index)
  minute <- grid$clock_minute
  medi <- rep(100, nrow(grid))
  light <- rep(200, nrow(grid))
  if (scenario == "day_only") {
    retained <- minute >= 360L & minute < 1080L
    medi[!retained] <- NA_real_
    light[!retained] <- NA_real_
  } else if (scenario == "night_only") {
    retained <- minute < 360L | minute >= 1080L
    medi[!retained] <- NA_real_
    light[!retained] <- NA_real_
  } else if (scenario == "zero_denominator") {
    light[] <- 0
  } else if (scenario == "no_pairing") {
    medi[minute >= 720L] <- NA_real_
    light[minute < 720L] <- NA_real_
  } else if (scenario == "all_observed") {
    NULL
  } else if (scenario == "ineligible") {
    NULL
  } else {
    stop("Unknown synthetic MDER support scenario", call. = FALSE)
  }
  grid$day_eligible <- scenario != "ineligible"
  grid$MEDI_eligible <- medi
  grid$LIGHT_eligible <- light
  grid$source_subepochs <- 1L
  grid$observed_subepochs <- 1L
  grid$distinct_subepochs <- 1L
  grid$expected_subepochs <- 1L
  grid$implicit_subepochs <- 0L
  grid$complete_subepoch_set <- TRUE
  grid |>
    dplyr::select(dplyr::all_of(c(
      "site",
      "Id",
      "position",
      "local_date",
      "timezone",
      "datetime_utc",
      "clock_minute",
      "day_eligible",
      "MEDI_eligible",
      "LIGHT_eligible",
      "source_subepochs",
      "observed_subepochs",
      "distinct_subepochs",
      "expected_subepochs",
      "implicit_subepochs",
      "complete_subepoch_set"
    )))
}

message("Building synthetic fixed-profile and coverage fixtures")
fixed <- new_mder_gate_profiles()
coverage <- dplyr::bind_rows(
  new_mder_gate_day("2026-01-01", "P01", "day_only"),
  new_mder_gate_day("2026-01-02", "P01", "night_only"),
  new_mder_gate_day("2026-01-03", "P01", "zero_denominator"),
  new_mder_gate_day("2026-01-04", "P01", "no_pairing"),
  new_mder_gate_day("2026-01-05", "P01", "all_observed"),
  new_mder_gate_day("2026-01-06", "P01", "ineligible"),
  new_mder_gate_day(
    "2026-03-29",
    "P02",
    "all_observed",
    timezone = "Europe/Berlin",
    site = "BERLIN"
  ),
  new_mder_gate_day(
    "2026-10-25",
    "P02",
    "all_observed",
    timezone = "Europe/Berlin",
    site = "BERLIN"
  )
)

message("Checking night-versus-day relevance and channel asymmetry")
diagnostic <- derive_mder_support_gate_diagnostics(
  coverage,
  profiles = fixed$profiles,
  maps = fixed$maps,
  placement = "glasses"
)
day_only <- dplyr::filter(
  diagnostic$daily,
  .data$local_date == as.Date("2026-01-01")
)
night_only <- dplyr::filter(
  diagnostic$daily,
  .data$local_date == as.Date("2026-01-02")
)
stopifnot(
  nrow(diagnostic$daily) == 7L,
  diagnostic$daily$expected_true_minutes[
    diagnostic$daily$local_date == as.Date("2026-03-29")
  ] ==
    1380L,
  diagnostic$daily$expected_true_minutes[
    diagnostic$daily$local_date == as.Date("2026-10-25")
  ] ==
    1500L,
  abs(day_only$ordinary_paired_coverage - 0.5) < 1e-12,
  abs(night_only$ordinary_paired_coverage - 0.5) < 1e-12,
  day_only$medi_paired_profile_coverage >
    night_only$medi_paired_profile_coverage,
  day_only$light_paired_profile_coverage <
    night_only$light_paired_profile_coverage,
  day_only$medi_paired_profile_coverage > day_only$light_paired_profile_coverage
)

message("Checking zero denominator and absent pairing")
zero_denominator <- dplyr::filter(
  diagnostic$daily,
  .data$local_date == as.Date("2026-01-03")
)
no_pairing <- dplyr::filter(
  diagnostic$daily,
  .data$local_date == as.Date("2026-01-04")
)
all_observed <- dplyr::filter(
  diagnostic$daily,
  .data$local_date == as.Date("2026-01-05")
)
stopifnot(
  zero_denominator$paired_finite_medi_light_minutes == 1440L,
  zero_denominator$paired_light_integral_lx_h == 0,
  !zero_denominator$positive_light_integral,
  zero_denominator$failure_reason == "nonpositive_paired_light_integral",
  !zero_denominator$retained_at_0_70,
  no_pairing$paired_finite_medi_light_minutes == 0L,
  no_pairing$ordinary_paired_coverage == 0,
  no_pairing$medi_paired_profile_coverage == 0,
  no_pairing$light_paired_profile_coverage == 0,
  is.na(no_pairing$paired_light_integral_lx_h),
  no_pairing$failure_reason == "no_paired_observation",
  !no_pairing$retained_at_0_70,
  all_observed$retained_at_0_70,
  all_observed$retained_at_0_80,
  all_observed$retained_at_0_90,
  !all_observed$ratio_value_calculated,
  !all_observed$ratio_scaled_or_weighted
)

message("Checking inclusive fixed candidate thresholds")
inclusive_fixture <- tibble::tibble(
  site = "TEST",
  Id = "P02",
  position = "glasses",
  local_date = as.Date("2026-02-01"),
  ordinary_paired_coverage = 0.80,
  medi_paired_profile_coverage = 0.80,
  light_paired_profile_coverage = 0.80,
  positive_light_integral = TRUE,
  has_paired_observation = TRUE,
  paired_finite_medi_light_minutes = 1152L
)
inclusive <- add_mder_candidate_retention(inclusive_fixture)
stopifnot(
  inclusive$retained_at_candidate[
    inclusive$candidate_support_cutoff == 0.80
  ],
  !inclusive$retained_at_candidate[
    inclusive$candidate_support_cutoff == 0.90
  ]
)
invalid_cutoffs <- tryCatch(
  {
    add_mder_candidate_retention(
      inclusive_fixture,
      candidate_cutoffs = c(0.75, 0.80, 0.90)
    )
    FALSE
  },
  error = function(error) TRUE
)
stopifnot(invalid_cutoffs)

message("Checking that L5 cannot enter the diagnostic gate")
l5_maps <- dplyr::bind_rows(
  fixed$maps,
  dplyr::mutate(fixed$maps[1L, , drop = FALSE], metric_map = "L5")
)
l5_error <- tryCatch(
  {
    validate_mder_fixed_profiles(
      fixed$profiles,
      l5_maps,
      placements = "glasses"
    )
    FALSE
  },
  error = function(error) {
    grepl("darkest-five-hour", conditionMessage(error), fixed = TRUE)
  }
)
stopifnot(l5_error)

message("Checking the strict 100000 lx MEDI operating boundary")
out_of_range <- coverage
out_of_range$MEDI_eligible[1L] <- 100000
range_error <- tryCatch(
  {
    validate_mder_coverage_input(
      out_of_range,
      placement = "glasses",
      object = "synthetic out-of-range coverage"
    )
    FALSE
  },
  error = function(error) {
    grepl("100000 lx boundary", conditionMessage(error), fixed = TRUE)
  }
)
stopifnot(range_error)

expect_mder_coverage_rejection <- function(data, pattern) {
  tryCatch(
    {
      validate_mder_coverage_input(
        data,
        placement = "glasses",
        object = "synthetic malformed coverage"
      )
      FALSE
    },
    error = function(error) {
      grepl(pattern, conditionMessage(error), fixed = TRUE)
    }
  )
}

message("Checking canonical true-minute coordinate rejection")
coordinate_fixture <- coverage |>
  dplyr::filter(
    .data$site == "TEST",
    .data$local_date == as.Date("2026-01-05")
  )
stopifnot(coordinate_fixture$clock_minute[1L] == 0L)
off_minute <- coordinate_fixture
off_minute$datetime_utc[1L] <- off_minute$datetime_utc[1L] + 30
bad_clock <- coordinate_fixture
bad_clock$clock_minute[1L] <- bad_clock$clock_minute[1L] + 1L
bad_date <- coordinate_fixture
bad_date$local_date[1L] <- bad_date$local_date[1L] + 1L
bad_timezone <- coordinate_fixture
bad_timezone$timezone <- "Europe/Berlin"
stopifnot(
  expect_mder_coverage_rejection(off_minute, "exact minute boundary"),
  expect_mder_coverage_rejection(bad_clock, "does not match `datetime_utc`"),
  expect_mder_coverage_rejection(bad_date, "does not match `datetime_utc`"),
  expect_mder_coverage_rejection(
    bad_timezone,
    "does not match `datetime_utc`"
  )
)

message("Checking source-presence and subepoch rejection")
source_absent_with_signal <- coordinate_fixture
source_absent_with_signal$source_subepochs[1L] <- 0L
source_present_mismatch <- coordinate_fixture
source_present_mismatch$source_minute_present <- TRUE
source_present_mismatch$source_minute_present[1L] <- FALSE
subepoch_overflow <- coordinate_fixture
subepoch_overflow$source_subepochs[1L] <- 2L
observed_subepoch_mismatch <- coordinate_fixture
observed_subepoch_mismatch$observed_subepochs[1L] <- 0L
stopifnot(
  expect_mder_coverage_rejection(
    source_absent_with_signal,
    "eligible light values on source-absent minutes"
  ),
  expect_mder_coverage_rejection(
    source_present_mismatch,
    "inconsistent with `source_subepochs > 0`"
  ),
  expect_mder_coverage_rejection(
    subepoch_overflow,
    "may not be smaller than `source_subepochs`"
  ),
  expect_mder_coverage_rejection(
    observed_subepoch_mismatch,
    "must equal `source_subepochs`"
  )
)
valid_source_absence <- coordinate_fixture
valid_source_absence$source_subepochs[1L] <- 0L
valid_source_absence$observed_subepochs[1L] <- 0L
valid_source_absence$distinct_subepochs[1L] <- 0L
valid_source_absence$complete_subepoch_set[1L] <- FALSE
valid_source_absence$MEDI_eligible[1L] <- NA_real_
valid_source_absence$LIGHT_eligible[1L] <- NA_real_
validate_mder_coverage_input(
  valid_source_absence,
  placement = "glasses",
  object = "synthetic valid source absence"
)

message("Building isolated diagnostic-only artifacts")
test_root <- tempfile("nathealth-mder-gate-test-")
dir.create(test_root, recursive = TRUE)
on.exit(unlink(test_root, recursive = TRUE), add = TRUE)
paths <- pipeline_paths(test_root)
ensure_pipeline_directories(paths)
coverage_root <- file.path(paths$coverage, "runs", "smoke")
profile_root <- file.path(paths$profiles, "runs", "smoke")
diagnostic_root <- file.path(
  paths$diagnostics,
  "runs",
  "smoke",
  "mder_support_gate"
)
dir.create(coverage_root, recursive = TRUE)
dir.create(profile_root, recursive = TRUE)
saveRDS(
  coverage,
  file.path(coverage_root, "light_glasses_coverage.rds")
)
readr::write_csv(
  tibble::tibble(
    run_label = "smoke",
    placement = "glasses",
    coverage_rule_id = "A",
    coverage_signal = "MEDI",
    daily_denominator_domain = "all_pseudo_local_wall_minutes",
    diary_sleep_excluded_from_denominator = FALSE,
    expected_wall_minutes_per_hour = 60L,
    expected_wall_minutes_per_day = 1440L,
    minimum_hour_coverage = 0.50,
    minimum_day_coverage = 0.80
  ),
  file.path(coverage_root, "coverage_settings.csv")
)
saveRDS(
  fixed$profiles,
  file.path(profile_root, "reference_profiles.rds")
)
saveRDS(
  fixed$maps,
  file.path(profile_root, "metric_relevance_maps.rds")
)
readr::write_csv(
  tibble::tibble(
    run_label = "smoke",
    input_coverage_rule_id = "A",
    input_daily_denominator_domain = "all_pseudo_local_wall_minutes",
    input_diary_sleep_excluded_from_denominator = FALSE,
    profile_learning = "fixed_once_before_participant_day_metrics",
    participant_day_profiles_fitted = FALSE,
    bin_minutes = 30L,
    l5_permitted = FALSE
  ),
  file.path(profile_root, "reference_profile_settings.csv")
)

message("Checking Preparation 02 run-label agreement")
run_label_error <- tryCatch(
  {
    validate_mder_coverage_settings(
      coverage_root,
      placements = "glasses",
      run_label = "different-run"
    )
    FALSE
  },
  error = function(error) {
    grepl("requested run label", conditionMessage(error), fixed = TRUE)
  }
)
stopifnot(run_label_error)

message("Checking OpenSSL hash-class normalization without weakening equality")
coverage_path <- file.path(
  coverage_root,
  "light_glasses_coverage.rds"
)
plain_artifact_hash <- artifact_sha256(coverage_path)
openssl_hash <- local({
  connection <- file(coverage_path, open = "rb")
  on.exit(close(connection), add = TRUE)
  openssl::sha256(connection)
})
hash_row <- mder_input_row(
  "preparation02_coverage",
  coverage_path,
  openssl_hash,
  placement = "glasses"
)
stopifnot(
  identical(class(plain_artifact_hash), "character"),
  !inherits(plain_artifact_hash, "hash"),
  inherits(openssl_hash, "hash"),
  identical(class(hash_row$sha256), "character"),
  identical(hash_row$sha256, plain_artifact_hash),
  identical(
    hash_row$sha256,
    unname(unclass(as.character(openssl_hash)))
  )
)
assert_mder_gate_inputs_unchanged(hash_row)
tampered_hash_row <- hash_row
substr(tampered_hash_row$sha256, 1L, 1L) <- if (
  startsWith(tampered_hash_row$sha256, "0")
) {
  "1"
} else {
  "0"
}
tampered_hash_error <- tryCatch(
  {
    assert_mder_gate_inputs_unchanged(tampered_hash_row)
    FALSE
  },
  error = function(error) {
    grepl("expected", conditionMessage(error), fixed = TRUE) &&
      grepl("observed", conditionMessage(error), fixed = TRUE)
  }
)
stopifnot(tampered_hash_error)

first <- build_mder_support_gate(
  root = test_root,
  run_label = "smoke",
  coverage_run_root = coverage_root,
  profile_run_root = profile_root,
  diagnostic_run_root = diagnostic_root,
  placements = "glasses"
)
first_hashes <- vapply(
  c(
    first$daily_path,
    first$candidates_path,
    first$site_candidates_path,
    first$participant_candidates_path,
    first$inputs_path,
    first$artifact_manifest_path
  ),
  artifact_sha256,
  character(1)
)
manifest <- readr::read_csv(
  first$artifact_manifest_path,
  show_col_types = FALSE
)
stopifnot(
  nrow(first$daily) == 7L,
  nrow(first$candidates) == 3L,
  nrow(first$site_candidates) == 6L,
  nrow(first$participant_candidates) == 6L,
  nrow(first$inputs) == 5L,
  nrow(manifest) == 5L,
  all(
    first$candidates$classification_total ==
      first$candidates$eligible_participant_days
  ),
  all(
    first$site_candidates$classification_total ==
      first$site_candidates$eligible_participant_days
  ),
  all(
    first$participant_candidates$classification_total ==
      first$participant_candidates$eligible_participant_days
  ),
  all(
    first$candidates$marginal_participant_day_loss_from_lower[
      !is.na(first$candidates$marginal_participant_day_loss_from_lower)
    ] >=
      0L
  ),
  all(file.exists(manifest$path)),
  all(vapply(
    seq_len(nrow(manifest)),
    function(index) {
      artifact_sha256(manifest$path[[index]]) == manifest$sha256[[index]]
    },
    logical(1)
  )),
  all(nzchar(manifest$input_hashes)),
  !startsWith(
    normalizePath(first$diagnostic_run_root, winslash = "/"),
    normalizePath(paths$metrics, winslash = "/")
  ),
  !any(grepl("L5", names(first$daily), fixed = TRUE))
)

message("Checking byte-stable deterministic rerun")
second <- build_mder_support_gate(
  root = test_root,
  run_label = "smoke",
  coverage_run_root = coverage_root,
  profile_run_root = profile_root,
  diagnostic_run_root = diagnostic_root,
  placements = "glasses"
)
second_hashes <- vapply(
  c(
    second$daily_path,
    second$candidates_path,
    second$site_candidates_path,
    second$participant_candidates_path,
    second$inputs_path,
    second$artifact_manifest_path
  ),
  artifact_sha256,
  character(1)
)
stopifnot(identical(unname(first_hashes), unname(second_hashes)))

message("MDER support-gate tests passed")
