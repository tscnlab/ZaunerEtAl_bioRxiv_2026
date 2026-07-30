source("scripts/pipeline/assertions.R")
source("scripts/pipeline/paths_io.R")
source("scripts/pipeline/import_sources.R")
source("scripts/pipeline/time_axes.R")
source("scripts/pipeline/state_alignment.R")
source("scripts/pipeline/multiplicity.R")
source("scripts/pipeline/reference_profiles.R")
source("scripts/pipeline/time_support.R")

message("Testing vector-wide Benjamini-Hochberg adjustment")
p <- c(0.002, 0.010, 0.030, 0.200)
stopifnot(
  isTRUE(all.equal(
    adjust_p_family(p, method = "BH", n = 4L),
    c(0.008, 0.020, 0.040, 0.200)
  )),
  isTRUE(all.equal(
    vapply(p, function(value) stats::p.adjust(value, "BH", n = 4L), numeric(1)),
    stats::p.adjust(p, "bonferroni", n = 4L)
  ))
)

message("Testing planned family size with a non-estimable test")
with_missing <- adjust_p_family(c(0.01, NA, 0.04), method = "BH", n = 3L)
stopifnot(is.na(with_missing[2L]), length(with_missing) == 3L)

message("Testing key assertions")
assert_unique_key(data.frame(a = 1:3, b = letters[1:3]), c("a", "b"))
duplicate_error <- tryCatch(
  {
    assert_unique_key(data.frame(a = c(1, 1)), "a")
    FALSE
  },
  error = function(error) TRUE
)
stopifnot(duplicate_error)

message("Testing pinned-source specifications")
site_sources <- read_site_sources("config/site_sources.csv")
baua_glasses <- source_specification(
  site_sources,
  site = "BAUA",
  modality = "light_glasses"
)
stopifnot(
  nrow(site_sources) == 9L,
  baua_glasses$timezone == "Europe/Berlin",
  grepl(
    paste0("/", baua_glasses$commit, "/"),
    baua_glasses$source_url,
    fixed = TRUE
  )
)
unavailable_error <- tryCatch(
  {
    source_specification(site_sources, site = "MPI", modality = "light_chest")
    FALSE
  },
  error = function(error) TRUE
)
stopifnot(unavailable_error)

message("Testing preservation of repeated DST fall-back instants")
fallback_utc <- as.POSIXct(
  c("2024-10-27 00:30:00", "2024-10-27 01:30:00"),
  tz = "UTC"
)
fallback_local <- lubridate::with_tz(fallback_utc, tzone = "Europe/Berlin")
fallback <- annotate_time_axes(
  data.frame(
    Id = "P01",
    Datetime = fallback_local,
    MEDI = c(10, 20)
  ),
  timezone = "Europe/Berlin",
  site = "TEST"
)
fallback_summary <- dst_local_key_summary(fallback)
stopifnot(
  length(unique(fallback$datetime_utc)) == 2L,
  length(unique(fallback$Datetime)) == 2L,
  lubridate::tz(fallback$Datetime) == "UTC",
  length(unique(fallback$datetime_wall)) == 1L,
  length(unique(fallback$local_clock_label)) == 1L,
  nrow(fallback_summary) == 1L,
  fallback_summary$distinct_instants == 2L,
  fallback_summary$crosses_dst,
  length(unique(lubridate::force_tz(fallback_local, tzone = "UTC"))) == 1L
)
fallback_collapsed <- collapse_wall_clock_intervals(
  fallback,
  value_cols = "MEDI"
)
stopifnot(
  nrow(fallback_collapsed) == 1L,
  fallback_collapsed$MEDI == 15,
  fallback_collapsed$valid_MEDI == 2L,
  fallback_collapsed$source_intervals == 2L,
  fallback_collapsed$distinct_instants == 2L,
  fallback_collapsed$dst_fold
)

message("Testing explicit half-open state joins")
state_target <- tibble::tibble(
  Id = "P01",
  Datetime = as.POSIXct("2026-01-01 00:00:00", tz = "UTC") + c(0, 60, 120),
  MEDI = c(10, 20, 30)
)
state_intervals <- tibble::tibble(
  Id = "P01",
  start = as.POSIXct("2026-01-01 00:00:00", tz = "UTC"),
  end = as.POSIXct("2026-01-01 00:02:00", tz = "UTC"),
  State.Brown = "sleep"
)
state_joined <- attach_states_checked(
  state_target,
  state_intervals,
  stream_keys = "Id",
  object = "synthetic sleep intervals"
)
stopifnot(
  identical(state_joined$State.Brown, c("sleep", "sleep", NA_character_)),
  nrow(state_joined) == nrow(state_target)
)
overlap_error <- tryCatch(
  {
    validate_interval_table(
      dplyr::bind_rows(
        state_intervals,
        dplyr::mutate(
          state_intervals,
          start = start + 60,
          end = end + 60
        )
      )
    )
    FALSE
  },
  error = function(error) TRUE
)
stopifnot(overlap_error)

message("Testing sleep-diary interval preparation and exclusion audit")
berlin_timezone <- "Europe/Berlin"
sleep_diary_input <- tibble::tibble(
  Id = c("P01", "P01", "P01", "P02"),
  sleepprep = as.POSIXct(
    c(
      "2026-01-01 22:00:00",
      "2026-01-02 23:00:00",
      "2026-01-04 23:00:00",
      "2026-01-01 22:00:00"
    ),
    tz = berlin_timezone
  ),
  wake = as.POSIXct(
    c(
      "2026-01-02 06:00:00",
      "2026-01-03 07:00:00",
      NA,
      "2026-01-01 21:00:00"
    ),
    tz = berlin_timezone
  )
)
prepared_sleep <- prepare_sleep_intervals(
  sleep_diary_input,
  timezone = berlin_timezone
)
stopifnot(
  inherits(prepared_sleep, "state_interval_preparation"),
  prepared_sleep$bounds == "[)",
  prepared_sleep$source == "sleep_diary",
  nrow(prepared_sleep$intervals) == 7L,
  sum(prepared_sleep$intervals$State.Brown == "sleep") == 2L,
  sum(prepared_sleep$intervals$State.Brown == "pre-sleep") == 2L,
  sum(prepared_sleep$intervals$State.Brown == "wake") == 3L,
  all(prepared_sleep$intervals$sleep_state_source == "sleep_diary"),
  lubridate::tz(prepared_sleep$intervals$start) == "UTC",
  lubridate::tz(prepared_sleep$intervals$end) == "UTC",
  nrow(prepared_sleep$audit) == 2L,
  setequal(
    prepared_sleep$audit$reason,
    c(
      "open_sleep_interval_missing_wake",
      "nonpositive_sleep_interval"
    )
  )
)
expected_sleep_start <- lubridate::with_tz(
  sleep_diary_input$sleepprep[1L],
  tzone = "UTC"
)
observed_sleep_start <- prepared_sleep$intervals |>
  dplyr::filter(.data$Id == "P01", .data$State.Brown == "sleep") |>
  dplyr::arrange(.data$start) |>
  dplyr::pull(.data$start) |>
  utils::head(1L)
stopifnot(identical(observed_sleep_start, expected_sleep_start))

message("Testing unsupported sleep-diary wake gaps")
long_gap_diary <- tibble::tibble(
  Id = "P03",
  sleepprep = as.POSIXct(
    c("2026-01-01 22:00:00", "2026-01-04 22:00:00"),
    tz = berlin_timezone
  ),
  wake = as.POSIXct(
    c("2026-01-02 06:00:00", "2026-01-05 06:00:00"),
    tz = berlin_timezone
  )
)
long_gap_sleep <- prepare_sleep_intervals(
  long_gap_diary,
  timezone = berlin_timezone,
  maximum_carry_forward_hours = 24
)
stopifnot(
  nrow(long_gap_sleep$intervals) == 6L,
  "wake_interval_exceeds_support_limit" %in% long_gap_sleep$audit$reason,
  !"open_wake_interval_no_next_sleepprep" %in% long_gap_sleep$audit$reason
)

message("Testing true-UTC sleep intervals across a DST fold")
fold_prep_utc <- as.POSIXct("2024-10-27 01:30:00", tz = "UTC")
fold_wake_utc <- as.POSIXct("2024-10-27 07:30:00", tz = "UTC")
fold_diary <- tibble::tibble(
  Id = "P04",
  sleepprep = lubridate::with_tz(fold_prep_utc, tzone = berlin_timezone),
  wake = lubridate::with_tz(fold_wake_utc, tzone = berlin_timezone)
)
fold_sleep <- prepare_sleep_intervals(
  fold_diary,
  timezone = berlin_timezone
)
fold_sleep_interval <- fold_sleep$intervals |>
  dplyr::filter(.data$State.Brown == "sleep")
stopifnot(
  identical(fold_sleep_interval$start, fold_prep_utc),
  identical(fold_sleep_interval$end, fold_wake_utc)
)

message("Testing wear-provenance interval preparation and exclusion audit")
wear_input <- tibble::tibble(
  Id = c("P01", "P01", "P01", "P02", "P02", "P02"),
  start = as.POSIXct(
    c(
      "2026-01-01 10:00:00",
      "2026-01-01 22:00:00",
      "2026-01-02 10:00:00",
      "2026-01-01 10:00:00",
      "2026-01-01 12:00:00",
      "2026-01-01 13:00:00"
    ),
    tz = berlin_timezone
  ),
  end = as.POSIXct(
    c(
      "2026-01-01 11:00:00",
      "2026-01-02 06:00:00",
      "2026-01-02 12:00:00",
      NA,
      "2026-01-01 12:00:00",
      "2026-01-01 14:00:00"
    ),
    tz = berlin_timezone
  ),
  state = c("off", "sleep", "site_leave", "off", "off", NA)
)
prepared_wear <- prepare_wear_intervals(
  wear_input,
  timezone = berlin_timezone
)
stopifnot(
  inherits(prepared_wear, "state_interval_preparation"),
  prepared_wear$bounds == "[)",
  prepared_wear$source == "wear_log_provenance",
  nrow(prepared_wear$intervals) == 3L,
  setequal(prepared_wear$intervals$wear, c("off", "sleep", "site_leave")),
  all(prepared_wear$intervals$wear_state_source == "wear_log_provenance"),
  !"State.Brown" %in% names(prepared_wear$intervals),
  lubridate::tz(prepared_wear$intervals$start) == "UTC",
  lubridate::tz(prepared_wear$intervals$end) == "UTC",
  nrow(prepared_wear$audit) == 3L,
  setequal(
    prepared_wear$audit$reason,
    c(
      "open_wear_interval_missing_end",
      "nonpositive_wear_interval",
      "incomplete_wear_interval_missing_state"
    )
  )
)
wear_overlap_error <- tryCatch(
  {
    prepare_wear_intervals(
      tibble::tibble(
        Id = "P05",
        start = as.POSIXct(
          c("2026-01-01 10:00:00", "2026-01-01 10:30:00"),
          tz = berlin_timezone
        ),
        end = as.POSIXct(
          c("2026-01-01 11:00:00", "2026-01-01 11:30:00"),
          tz = berlin_timezone
        ),
        state = c("off", "sleep")
      ),
      timezone = berlin_timezone
    )
    FALSE
  },
  error = function(error) TRUE
)
stopifnot(wear_overlap_error)

message("Testing diary-authoritative measurement context and channel masks")
context_input <- tibble::tibble(
  State.Brown = c(
    "wake",
    "sleep",
    "wake",
    "wake",
    "pre-sleep",
    "wake",
    "wake"
  ),
  wear = c("off", "off", "sleep", NA, "site_leave", NA, NA),
  MEDI = c(10, 20, 30, 40, 50, 99999, 100000),
  LIGHT = c(100, 200, 300, 400, 500, 600, 700)
)
context <- derive_measurement_context(context_input, placement = "glasses")
boundary_override_error <- tryCatch(
  {
    derive_measurement_context(
      context_input,
      placement = "glasses",
      saturation_threshold = 120000
    )
    FALSE
  },
  error = function(error) TRUE
)
stopifnot(
  boundary_override_error,
  is.na(context$MEDI[1L]),
  is.na(context$LIGHT[1L]),
  context$measurement_context[1L] == "invalid_nonwear",
  context$measurement_context[2L] == "bedside_sleep_environment",
  context$MEDI[2L] == 20,
  context$measurement_context[3L] == "worn_near_eye",
  context$wear_sleep_disagrees_with_diary[3L],
  context$measurement_context[5L] == "worn_near_eye",
  context$MEDI[6L] == 99999,
  is.na(context$MEDI[7L]),
  context$LIGHT[7L] == 700,
  context$MEDI_raw[1L] == 10,
  context$LIGHT_raw[1L] == 100,
  !context$valid_medi_light_pair[1L],
  context$valid_medi_light_pair[2L]
)

message("Testing participant-balanced reference profiles")
profile_input <- data.frame(
  Id = c("A", "A", "A", "B", "B"),
  placement = "glasses",
  state_domain = "full_day",
  signal = "MEDI",
  clock_bin = c(0, 0, 30, 0, 30),
  value = c(1, 3, 4, 10, 8)
)
profile <- learn_reference_profile(profile_input, value_col = "value")
stopifnot(
  profile$reference_value[profile$clock_bin == 0] == 6,
  profile$reference_value[profile$clock_bin == 30] == 6,
  isTRUE(all.equal(sum(profile$reference_weight, na.rm = TRUE), 1))
)

message("Testing profile-weighted dose correction")
integral <- time_sensitive_integral(
  value = c(100, NA, 10, 10),
  reference_weight = c(0.45, 0.45, 0.05, 0.05),
  epoch_hours = 1
)
stopifnot(
  isTRUE(all.equal(integral$observed_integral, 120)),
  isTRUE(all.equal(integral$relevance_coverage, 0.55)),
  integral$low_relevance_coverage,
  !integral$correction_admissible,
  is.na(integral$corrected_integral)
)

message("Testing gap-aware longest runs")
time <- as.POSIXct("2026-01-01 00:00:00", tz = "UTC") + c(0, 60, 120, 600, 660)
run <- gap_aware_threshold_summary(
  value = rep(300, 5),
  datetime = time,
  threshold = 250,
  epoch_seconds = 60
)
stopifnot(run$duration_seconds == 300, run$longest_seconds == 180)

message("Testing L10 support and tie handling")
day_time <- as.POSIXct("2026-01-01 00:00:00", tz = "UTC") + 0:1439 * 60
clock <- 0:1439
light <- rep(100, 1440)
light[1:600] <- 0
light[101:130] <- NA
dark <- rolling_window_summary(
  value = light,
  datetime = day_time,
  clock_minute = clock,
  period = "darkest",
  reference_weight = rep(1, length(light)),
  window_minutes = 600,
  minimum_support = 0.8,
  loop = TRUE
)
stopifnot(dark$estimable, dark$window_support >= 0.8)

message("Testing gap-aware IS/IV adjacency")
grid <- as.POSIXct("2026-01-01 00:00:00", tz = "UTC") + 0:(72 * 60 - 1) * 60
values <- sin(2 * pi * (0:(length(grid) - 1) %% 1440) / 1440) + 2
values[1000:1100] <- NA
is_iv <- gap_aware_is_iv(
  value = values,
  datetime = grid,
  clock_hour = as.integer(format(grid, "%H", tz = "UTC")),
  local_date = as.Date(grid, tz = "UTC")
)
stopifnot(
  is_iv$estimable,
  is_iv$interdaily_stability >= 0,
  is_iv$interdaily_stability <= 1,
  is_iv$adjacent_pairs < is_iv$valid_hours
)

message("All pipeline tests passed")
