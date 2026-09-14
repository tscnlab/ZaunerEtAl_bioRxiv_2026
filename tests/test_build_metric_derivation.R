source("scripts/pipeline/paths_io.R")
source("scripts/pipeline/assertions.R")
source("scripts/pipeline/state_alignment.R")
source("scripts/pipeline/time_axes.R")
source("scripts/pipeline/time_support.R")
source("scripts/pipeline/reference_profiles.R")
source("scripts/pipeline/state_interval_projection.R")
source("scripts/pipeline/metric_derivation.R")
source("scripts/pipeline/build_metric_derivation.R")

new_fixed_test_profiles <- function(placement = "glasses") {
  clock_bin <- seq.int(0L, 1410L, by = 30L)
  medi_reference <- dplyr::case_when(
    clock_bin < 360L | clock_bin >= 1200L ~ 1,
    clock_bin >= 480L & clock_bin < 1080L ~ 1000,
    TRUE ~ 50
  )
  profile_rows <- lapply(
    c("full_day", "wake", "pre-sleep", "sleep"),
    function(state_domain) {
      dplyr::bind_rows(lapply(c("MEDI", "LIGHT"), function(signal) {
        reference <- if (signal == "MEDI") {
          medi_reference
        } else {
          medi_reference * 2
        }
        tibble::tibble(
          profile_scope = "pooled",
          profile_variant = "pooled",
          profile_site = NA_character_,
          held_out_site = NA_character_,
          placement = placement,
          state_domain = state_domain,
          signal = signal,
          clock_bin = clock_bin,
          reference_value = reference,
          profile_supported = TRUE,
          profile_complete = TRUE,
          supported_bins = 48L,
          supported_reference_value = reference,
          reference_total = sum(reference),
          reference_weight = reference / sum(reference)
        )
      }))
    }
  )
  profiles <- dplyr::bind_rows(profile_rows)
  distribution_input <- expand.grid(
    Id = sprintf("D%02d", seq_len(20L)),
    clock_minute = seq.int(0L, 1439L),
    KEEP.OUT.ATTRS = FALSE,
    stringsAsFactors = FALSE
  )
  distribution_input$site <- "TEST"
  distribution_input$local_date <- as.Date("2026-01-01")
  distribution_input$placement <- placement
  distribution_input$state_domain <- "full_day"
  distribution_input$signal <- "MEDI"
  distribution_input$clock_bin <- clock_bin(
    distribution_input$clock_minute,
    bin_minutes = 30L
  )
  distribution_input$profile_value <- medi_reference[
    match(distribution_input$clock_bin, clock_bin)
  ]
  distribution_profiles <- learn_exceedance_distribution_profile_set(
    data = distribution_input,
    value_col = "profile_value",
    variants = "pooled"
  )
  maps <- derive_metric_relevance_maps(
    profiles = profiles,
    distribution_profiles = distribution_profiles,
    signal_col = "signal",
    clock_bin_col = "clock_bin",
    strata = c("placement", "state_domain"),
    zero_offset = 0.1
  )
  list(
    profiles = profiles,
    distribution_profiles = distribution_profiles,
    maps = maps
  )
}

new_metric_test_day <- function(
  date,
  scenario,
  timezone = "Europe/Berlin",
  id = "P01",
  placement = "glasses"
) {
  day_index <- tibble::tibble(
    site = "TEST",
    Id = id,
    position = placement,
    local_date = as.Date(date),
    timezone = timezone
  )
  grid <- build_true_minute_day_grid(day_index)
  clock <- grid$clock_minute
  medi <- dplyr::case_when(
    clock < 360L | clock >= 1200L ~ 1,
    clock >= 480L & clock < 1080L ~ 1000,
    TRUE ~ 50
  )
  state <- dplyr::case_when(
    clock < 480L ~ "sleep",
    clock < 1200L ~ "wake",
    TRUE ~ "pre-sleep"
  )

  if (scenario == "baseline") {
    medi[clock == 100L] <- 0
    medi[clock == 400L] <- 250
    medi[clock == 700L] <- 1200
    medi[clock == 701L] <- 1000
  } else if (scenario == "no_event") {
    medi[] <- 100
  } else if (scenario == "m10_all_candidates_tied") {
    medi[] <- 0
  } else if (scenario == "broken_bout") {
    medi[] <- 100
    medi[clock %in% 600:609] <- 300
    medi[clock == 610L] <- NA_real_
    medi[clock %in% 611:620] <- 300
  } else if (scenario == "missing_low_relevance") {
    medi[clock %in% 0:149] <- NA_real_
  } else if (scenario == "missing_high_relevance") {
    medi[clock %in% 600:749] <- NA_real_
  } else if (scenario == "unsupported_30_minute") {
    medi[clock %in% 120:135] <- NA_real_
  } else if (scenario == "unsupported_hour") {
    medi[clock %in% 300:330] <- NA_real_
  } else if (scenario == "no_pre_sleep") {
    state[clock >= 1200L] <- "wake"
  } else if (scenario == "pre_sleep_75_percent") {
    medi[clock %in% 1200:1259] <- NA_real_
  } else if (scenario == "unknown_state_gap") {
    state[clock %in% 600:659] <- NA_character_
  } else if (
    !scenario %in%
      c(
        "dst_spring",
        "dst_fall",
        "source_gap_known_state",
        "boundary_gap",
        "wear_off_context",
        "mder_40_percent",
        "mder_50_percent",
        "mder_zero_pairs"
      )
  ) {
    stop("Unknown synthetic scenario: ", scenario, call. = FALSE)
  }
  light <- medi * 2
  if (scenario == "baseline") {
    light[clock == 900L] <- NA_real_
  } else if (scenario == "mder_40_percent") {
    light[clock < 864L] <- NA_real_
  } else if (scenario == "mder_50_percent") {
    light[clock < 720L] <- NA_real_
  } else if (scenario == "mder_zero_pairs") {
    light[clock < 288L] <- 0
  }

  dplyr::mutate(
    grid,
    day_eligible = TRUE,
    source_subepochs = 1L,
    MEDI_eligible = medi,
    LIGHT_eligible = light,
    State.Brown = state,
    sleep = dplyr::case_when(
      .data$State.Brown == "sleep" ~ "sleepprep",
      !is.na(.data$State.Brown) ~ "wake",
      TRUE ~ NA_character_
    ),
    wear = NA_character_,
    measurement_context = dplyr::case_when(
      !is.na(.data$State.Brown) & .data$State.Brown == "sleep" ~
        "bedside_sleep_environment",
      TRUE ~ "worn_near_eye"
    ),
    measurement_context_source = dplyr::case_when(
      !is.na(.data$State.Brown) & .data$State.Brown == "sleep" ~ "sleep_diary",
      TRUE ~ "placement_protocol"
    ),
    invalid_nonwear = FALSE,
    wear_sleep_disagrees_with_diary = FALSE,
    wear_off_during_diary_sleep = FALSE,
    wear_state_missing = TRUE
  )
}

message("Checking conservative longest-bout identifiability")
bout_time <- as.POSIXct(
  "2026-01-01 00:00:00",
  tz = "UTC"
) +
  seq.int(0, 8) * 60
hidden_longer <- longest_bout_with_censoring(
  value = c(300, 300, 100, 300, NA, NA, NA, 300, 100),
  datetime = bout_time,
  segment = rep(1L, length(bout_time))
)
wholly_missing <- longest_bout_with_censoring(
  value = rep(NA_real_, 5L),
  datetime = bout_time[seq_len(5L)],
  segment = rep(1L, 5L)
)
boundary_contact <- longest_bout_with_censoring(
  value = c(300, 300, 100, 100),
  datetime = bout_time[seq_len(4L)],
  segment = rep(1L, 4L)
)
no_event_complete <- longest_bout_with_censoring(
  value = rep(100, 5L),
  datetime = bout_time[seq_len(5L)],
  segment = rep(1L, 5L)
)
no_event_gap <- longest_bout_with_censoring(
  value = c(100, NA, NA, 100),
  datetime = bout_time[seq_len(4L)],
  segment = rep(1L, 4L)
)
segment_break <- longest_bout_with_censoring(
  value = c(300, NA, 300),
  datetime = bout_time[seq_len(3L)],
  segment = 1:3
)
missing_but_exact <- longest_bout_with_censoring(
  value = c(300, 300, 300, 100, NA, 100),
  datetime = bout_time[seq_len(6L)],
  segment = rep(1L, 6L)
)
strict_threshold <- longest_bout_with_censoring(
  value = c(250, 250.0001, 100),
  datetime = bout_time[seq_len(3L)],
  segment = rep(1L, 3L)
)
invalid_break <- longest_bout_with_censoring(
  value = c(300, Inf, 300),
  datetime = bout_time[seq_len(3L)],
  segment = rep(1L, 3L)
)
tied_interior_then_boundary <- longest_bout_with_censoring(
  value = c(100, 300, 300, 100, 300, 300),
  datetime = bout_time[seq_len(6L)],
  segment = rep(1L, 6L)
)
stopifnot(
  hidden_longer$longest_observed_seconds == 120,
  hidden_longer$longest_observed_lower_bound_seconds == 120,
  hidden_longer$longest_possible_seconds == 300,
  hidden_longer$longest_possible_upper_bound_seconds == 300,
  hidden_longer$longest_reported_seconds == 120,
  is.na(hidden_longer$longest_exact_identifiable_seconds),
  hidden_longer$estimable,
  is.na(hidden_longer$failure_reason),
  !hidden_longer$exact_identifiable,
  hidden_longer$longest_run_censored,
  hidden_longer$missing_invalid_breaks_observed_runs,
  hidden_longer$observed_value_interpretation == "observed_lower_bound",
  hidden_longer$censor_reason == "missing_or_invalid_minutes_allow_longer_bout",
  hidden_longer$exact_failure_reason ==
    "not_exactly_identifiable_due_to_missing_or_invalid_minutes",
  wholly_missing$longest_observed_seconds == 0,
  wholly_missing$longest_possible_seconds == 300,
  wholly_missing$longest_reported_seconds == 0,
  is.na(wholly_missing$longest_exact_identifiable_seconds),
  wholly_missing$censor_reason ==
    "missing_or_invalid_minutes_allow_longer_bout",
  boundary_contact$longest_reported_seconds == 120,
  boundary_contact$longest_exact_identifiable_seconds == 120,
  boundary_contact$exact_identifiable,
  !boundary_contact$longest_run_censored,
  boundary_contact$winner_day_boundary_contact,
  boundary_contact$any_winning_observed_run_day_boundary_contact,
  boundary_contact$winner_selection_rule ==
    "earliest_onset_then_earliest_offset",
  is.na(boundary_contact$censor_reason),
  boundary_contact$winner_onset_utc == bout_time[1L],
  boundary_contact$winner_offset_utc == bout_time[3L],
  no_event_complete$longest_reported_seconds == 0,
  no_event_complete$longest_exact_identifiable_seconds == 0,
  no_event_complete$estimable,
  is.na(no_event_complete$censor_reason),
  no_event_gap$longest_reported_seconds == 0,
  is.na(no_event_gap$longest_exact_identifiable_seconds),
  no_event_gap$longest_run_censored,
  is.na(no_event_gap$failure_reason),
  segment_break$longest_reported_seconds == 60,
  segment_break$longest_possible_seconds == 60,
  segment_break$longest_exact_identifiable_seconds == 60,
  missing_but_exact$longest_observed_seconds == 180,
  missing_but_exact$longest_possible_seconds == 180,
  missing_but_exact$longest_exact_identifiable_seconds == 180,
  missing_but_exact$exact_identifiable,
  strict_threshold$longest_observed_seconds == 60,
  invalid_break$longest_observed_seconds == 60,
  invalid_break$longest_possible_seconds == 180,
  invalid_break$longest_run_censored,
  tied_interior_then_boundary$winning_observed_runs == 2L,
  tied_interior_then_boundary$winner_onset_utc == bout_time[2L],
  tied_interior_then_boundary$winner_offset_utc == bout_time[4L],
  !tied_interior_then_boundary$winner_day_boundary_contact,
  tied_interior_then_boundary$any_winning_observed_run_day_boundary_contact,
  tied_interior_then_boundary$winner_selection_rule ==
    "earliest_onset_then_earliest_offset"
)

message("Checking placement-aware measurement constructs")
stopifnot(
  measurement_construct_for_placement("glasses") ==
    "hybrid_near_eye_wake_and_bedside_sleep_environment",
  measurement_construct_for_placement("chest") ==
    "hybrid_chest_level_wake_and_bedside_sleep_environment"
)

message("Building isolated synthetic Preparation 04 inputs")
test_root <- tempfile("nathealth-metric-test-")
dir.create(test_root, recursive = TRUE)
on.exit(unlink(test_root, recursive = TRUE), add = TRUE)
paths <- pipeline_paths(test_root)
ensure_pipeline_directories(paths)
canonical_layout <- metric_derivation_run_layout(
  paths,
  run_label = "full",
  profile_variant = "pooled"
)
variant_layout <- metric_derivation_run_layout(
  paths,
  run_label = "full",
  profile_variant = "site_specific"
)
run_variant_layout <- metric_derivation_run_layout(
  paths,
  run_label = "smoke",
  profile_variant = "leave_one_site_out"
)
unsafe_canonical_layout <- canonical_layout
unsafe_canonical_layout$coverage_run_root <- file.path(
  paths$coverage,
  "runs",
  "unsafe"
)
unsafe_canonical_error <- tryCatch(
  {
    assert_canonical_metric_output_scope(
      unsafe_canonical_layout,
      paths
    )
    FALSE
  },
  error = function(error) {
    grepl(
      "Canonical Preparation 04 output is reserved",
      conditionMessage(error),
      fixed = TRUE
    )
  }
)
stopifnot(
  identical(canonical_layout$metric_run_root, paths$metrics),
  identical(
    variant_layout$metric_run_root,
    file.path(paths$metrics, "profile_variants", "site_specific")
  ),
  variant_layout$manifest_suffix == "_site_specific",
  identical(
    run_variant_layout$metric_run_root,
    file.path(
      paths$metrics,
      "runs",
      "smoke",
      "profile_variants",
      "leave_one_site_out"
    )
  ),
  run_variant_layout$manifest_suffix == "_smoke_leave_one_site_out",
  unsafe_canonical_error
)
coverage_root <- file.path(paths$coverage, "runs", "smoke")
profile_root <- file.path(paths$profiles, "runs", "smoke")
dir.create(coverage_root, recursive = TRUE)
dir.create(profile_root, recursive = TRUE)

scenario_table <- tibble::tribble(
  ~date,
  ~scenario,
  "2026-01-01",
  "baseline",
  "2026-01-02",
  "no_event",
  "2026-01-03",
  "broken_bout",
  "2026-01-04",
  "missing_low_relevance",
  "2026-01-05",
  "missing_high_relevance",
  "2026-01-06",
  "unsupported_30_minute",
  "2026-01-07",
  "unsupported_hour",
  "2026-01-08",
  "no_pre_sleep",
  "2026-01-09",
  "pre_sleep_75_percent",
  "2026-01-10",
  "source_gap_known_state",
  "2026-01-11",
  "boundary_gap",
  "2026-01-12",
  "unknown_state_gap",
  "2026-01-13",
  "wear_off_context",
  "2026-01-14",
  "mder_40_percent",
  "2026-01-15",
  "mder_50_percent",
  "2026-01-16",
  "mder_zero_pairs",
  "2026-01-17",
  "m10_all_candidates_tied",
  "2026-03-29",
  "dst_spring",
  "2026-10-25",
  "dst_fall"
)
coverage <- purrr::map2_dfr(
  scenario_table$date,
  scenario_table$scenario,
  new_metric_test_day
) |>
  dplyr::arrange(.data$site, .data$Id, .data$position, .data$datetime_utc)

message("Creating exact synthetic Preparation 01 interval inputs")
sleep_interval_rows <- purrr::map_dfr(
  split(
    seq_len(nrow(coverage)),
    interaction(
      coverage$site,
      coverage$Id,
      coverage$local_date,
      drop = TRUE,
      lex.order = TRUE
    )
  ),
  function(index) {
    day <- coverage[index, , drop = FALSE] |>
      dplyr::filter(!is.na(.data$State.Brown)) |>
      dplyr::arrange(.data$datetime_utc)
    if (nrow(day) == 0L) {
      return(tibble::tibble())
    }
    state_change <- c(
      TRUE,
      as.character(day$State.Brown[-1L]) !=
        as.character(day$State.Brown[-nrow(day)]) |
        diff(as.numeric(day$datetime_utc)) != 60
    )
    day$.interval_run <- cumsum(state_change)
    day |>
      dplyr::group_by(.data$site, .data$Id, .data$.interval_run) |>
      dplyr::summarise(
        start = dplyr::first(.data$datetime_utc),
        end = dplyr::last(.data$datetime_utc) + 60,
        State.Brown = dplyr::first(.data$State.Brown),
        sleep = dplyr::first(.data$sleep),
        .groups = "drop"
      ) |>
      dplyr::select(-".interval_run")
  }
) |>
  dplyr::arrange(.data$site, .data$Id, .data$start, .data$end)
sleep_interval_rows$sleep_source_row_start <-
  seq_len(nrow(sleep_interval_rows))
sleep_interval_rows$sleep_source_row_end <-
  sleep_interval_rows$sleep_source_row_start
sleep_interval_rows$sleep_state_source <- "sleep_diary"
sleep_interval_rows$sleep_interval_bounds <- "[)"

wear_day <- coverage |>
  dplyr::filter(.data$local_date == as.Date("2026-01-13")) |>
  dplyr::arrange(.data$datetime_utc)
wear_interval_rows <- dplyr::bind_rows(
  tibble::tibble(
    site = "TEST",
    Id = "P01",
    start = wear_day$datetime_utc[wear_day$clock_minute == 300L],
    end = wear_day$datetime_utc[wear_day$clock_minute == 310L],
    wear = "off"
  ),
  tibble::tibble(
    site = "TEST",
    Id = "P01",
    start = wear_day$datetime_utc[wear_day$clock_minute == 600L],
    end = wear_day$datetime_utc[wear_day$clock_minute == 610L],
    wear = "off"
  )
)
wear_interval_rows$wear_source_row <- seq_len(nrow(wear_interval_rows))
wear_interval_rows$wear_state_source <- "wear_log_provenance"
wear_interval_rows$wear_interval_bounds <- "[)"

decorate_test_intervals <- function(intervals, interval_kind) {
  source_sha256 <- if (interval_kind == "sleep") {
    strrep("b", 64L)
  } else {
    strrep("c", 64L)
  }
  intervals$timezone <- "Europe/Berlin"
  intervals$interval_kind <- interval_kind
  intervals$interval_bounds <- "[)"
  intervals$source_modality <- if (interval_kind == "sleep") {
    "sleepdiaries"
  } else {
    "wearlog"
  }
  intervals$source_repository <- "synthetic_state_repository"
  intervals$source_commit <- strrep("a", 40L)
  intervals$source_doi <- "10.5281/zenodo.1"
  intervals$source_sha256 <- source_sha256
  intervals$source_url <- paste0(
    "https://example.test/",
    interval_kind,
    ".rds"
  )
  intervals <- dplyr::select(
    intervals,
    "site",
    "Id",
    "timezone",
    "interval_kind",
    "interval_bounds",
    dplyr::everything()
  )
  attr(intervals, "state_interval_provenance") <- list(
    site = "TEST",
    timezone = "Europe/Berlin",
    interval_kind = interval_kind,
    bounds = "[)",
    repository = "synthetic_state_repository",
    commit = strrep("a", 40L),
    doi = "10.5281/zenodo.1",
    sha256 = source_sha256,
    source_url = paste0("https://example.test/", interval_kind, ".rds")
  )
  intervals
}
sleep_intervals <- decorate_test_intervals(
  sleep_interval_rows,
  "sleep"
)
wear_intervals <- decorate_test_intervals(
  wear_interval_rows,
  "wear"
)
state_interval_root <- file.path(
  paths$aligned,
  "runs",
  "smoke",
  "state_intervals"
)
dir.create(state_interval_root, recursive = TRUE)
state_interval_metadata <- dplyr::bind_rows(
  manifest_row(write_rds_artifact(
    sleep_intervals,
    file.path(state_interval_root, "TEST_sleep_intervals.rds"),
    producer = "tests/test_build_metric_derivation.R",
    metadata = list(
      artifact_type = "site_sleep_state_intervals",
      run_label = "smoke",
      site = "TEST",
      interval_kind = "sleep",
      interval_bounds = "[)"
    )
  )),
  manifest_row(write_rds_artifact(
    wear_intervals,
    file.path(state_interval_root, "TEST_wear_intervals.rds"),
    producer = "tests/test_build_metric_derivation.R",
    metadata = list(
      artifact_type = "site_wear_state_intervals",
      run_label = "smoke",
      site = "TEST",
      interval_kind = "wear",
      interval_bounds = "[)"
    )
  ))
)
state_interval_manifest_path <- file.path(
  paths$manifests,
  "state_interval_artifacts_smoke.csv"
)
readr::write_csv(
  state_interval_metadata,
  state_interval_manifest_path
)

known_gap <- coverage$local_date == as.Date("2026-01-10") &
  coverage$clock_minute %in% 600:629
boundary_gap <- coverage$local_date == as.Date("2026-01-11") &
  coverage$clock_minute %in% 1195:1204
source_absent <- known_gap | boundary_gap
coverage$source_subepochs[source_absent] <- 0L
coverage$MEDI_eligible[source_absent] <- NA_real_
coverage$LIGHT_eligible[source_absent] <- NA_real_
for (column in metric_state_comparison_columns) {
  coverage[[column]][source_absent] <- NA
}

sleep_off <- coverage$local_date == as.Date("2026-01-13") &
  coverage$clock_minute %in% 300:309
wake_off <- coverage$local_date == as.Date("2026-01-13") &
  coverage$clock_minute %in% 600:609
coverage$wear[sleep_off | wake_off] <- "off"
coverage$wear_state_missing[sleep_off | wake_off] <- FALSE
coverage$wear_off_during_diary_sleep[sleep_off] <- TRUE
coverage$invalid_nonwear[wake_off] <- TRUE
coverage$measurement_context[wake_off] <- "invalid_nonwear"
coverage$measurement_context_source[wake_off] <- "wearlog_off"
coverage$MEDI_eligible[wake_off] <- NA_real_
coverage$LIGHT_eligible[wake_off] <- NA_real_

coverage_path <- file.path(
  coverage_root,
  "light_glasses_coverage.rds"
)
saveRDS(coverage, coverage_path)
coverage_sha256 <- artifact_sha256(coverage_path)
coverage_settings_path <- file.path(
  coverage_root,
  "coverage_settings.csv"
)
readr::write_csv(
  tibble::tibble(
    run_label = "smoke",
    placement = "glasses",
    coverage_rule_id = "A",
    coverage_signal = "MEDI",
    daily_denominator_domain = "all_pseudo_local_wall_minutes",
    daily_eligibility_basis =
      "finite_medi_minutes_across_fixed_24_hour_cycle",
    hourly_gate_scope = "hourly_metrics_only",
    minute_values_masked_by_hour_gate = FALSE,
    hour_screened_sensitivity_available = TRUE,
    all_zero_medi_exclusion_applied = TRUE,
    all_zero_medi_sensitivity_available = TRUE,
    diary_sleep_excluded_from_denominator = FALSE,
    expected_wall_minutes_per_hour = 60L,
    expected_wall_minutes_per_day = 1440L,
    minimum_hour_coverage = 0.50,
    minimum_day_coverage = 0.80
  ),
  coverage_settings_path
)
verified_coverage_settings <- validate_preparation02_settings(
  coverage_root,
  "glasses"
)
stopifnot(
  verified_coverage_settings$data$minimum_hour_coverage == 0.50,
  verified_coverage_settings$data$minimum_day_coverage == 0.80
)

message("Checking interval manifests and true-UTC state projection")
state_inputs <- read_metric_state_interval_inputs(
  state_interval_root = state_interval_root,
  state_interval_manifest_path = state_interval_manifest_path,
  sites = "TEST",
  run_label = "smoke"
)
projected_grid <- build_complete_metric_grid(
  coverage,
  state_intervals = state_inputs,
  placement = "glasses"
)
known_projected_gap <- projected_grid |>
  dplyr::filter(
    .data$local_date == as.Date("2026-01-10"),
    .data$clock_minute %in% 600:629
  )
boundary_projected_gap <- projected_grid |>
  dplyr::filter(
    .data$local_date == as.Date("2026-01-11"),
    .data$clock_minute %in% 1195:1204
  )
unknown_projected_gap <- projected_grid |>
  dplyr::filter(
    .data$local_date == as.Date("2026-01-12"),
    .data$clock_minute %in% 600:659
  )
wear_projection <- projected_grid |>
  dplyr::filter(
    .data$local_date == as.Date("2026-01-13"),
    .data$clock_minute %in% c(300L, 309L, 600L, 609L)
  ) |>
  dplyr::arrange(.data$clock_minute)
stopifnot(
  nrow(state_inputs$inputs) == 2L,
  all(
    state_inputs$inputs$actual_sha256 == state_inputs$inputs$manifest_sha256
  ),
  state_inputs$manifest_sha256 == artifact_sha256(state_interval_manifest_path),
  nrow(known_projected_gap) == 30L,
  all(!known_projected_gap$source_minute_present),
  all(known_projected_gap$State.Brown == "wake"),
  all(
    boundary_projected_gap$State.Brown[
      boundary_projected_gap$clock_minute < 1200L
    ] ==
      "wake"
  ),
  all(
    boundary_projected_gap$State.Brown[
      boundary_projected_gap$clock_minute >= 1200L
    ] ==
      "pre-sleep"
  ),
  all(is.na(unknown_projected_gap$State.Brown)),
  identical(
    wear_projection$measurement_context,
    c(
      "bedside_sleep_environment",
      "bedside_sleep_environment",
      "invalid_nonwear",
      "invalid_nonwear"
    )
  ),
  identical(
    wear_projection$invalid_nonwear,
    c(FALSE, FALSE, TRUE, TRUE)
  ),
  identical(
    wear_projection$wear_off_during_diary_sleep,
    c(TRUE, TRUE, FALSE, FALSE)
  ),
  all(is.finite(wear_projection$MEDI_eligible[1:2])),
  all(is.na(wear_projection$MEDI_eligible[3:4]))
)

mismatched_coverage <- coverage
mismatch_row <- which(
  mismatched_coverage$local_date == as.Date("2026-01-01") &
    mismatched_coverage$clock_minute == 600L
)[1L]
mismatched_coverage$measurement_context[mismatch_row] <- "invalid_nonwear"
projection_mismatch_error <- tryCatch(
  {
    build_complete_metric_grid(
      mismatched_coverage,
      state_intervals = state_inputs,
      placement = "glasses"
    )
    FALSE
  },
  error = function(error) {
    grepl(
      "disagrees with Preparation 01",
      conditionMessage(error),
      fixed = TRUE
    )
  }
)
bad_state_manifest <- readr::read_csv(
  state_interval_manifest_path,
  show_col_types = FALSE
)
bad_state_manifest$sha256[1L] <- strrep("d", 64L)
bad_state_manifest_path <- file.path(
  paths$manifests,
  "state_interval_artifacts_bad.csv"
)
readr::write_csv(bad_state_manifest, bad_state_manifest_path)
state_manifest_mismatch_error <- tryCatch(
  {
    read_metric_state_interval_inputs(
      state_interval_root = state_interval_root,
      state_interval_manifest_path = bad_state_manifest_path,
      sites = "TEST",
      run_label = "smoke"
    )
    FALSE
  },
  error = function(error) {
    grepl("hashes do not match", conditionMessage(error), fixed = TRUE)
  }
)
stopifnot(projection_mismatch_error, state_manifest_mismatch_error)

bad_coverage_root <- file.path(test_root, "bad_coverage_settings")
dir.create(bad_coverage_root)
readr::write_csv(
  tibble::tibble(
    run_label = "bad",
    placement = "glasses",
    coverage_rule_id = "A",
    coverage_signal = "MEDI",
    daily_denominator_domain = "all_pseudo_local_wall_minutes",
    daily_eligibility_basis =
      "finite_medi_minutes_across_fixed_24_hour_cycle",
    hourly_gate_scope = "hourly_metrics_only",
    minute_values_masked_by_hour_gate = FALSE,
    hour_screened_sensitivity_available = TRUE,
    all_zero_medi_exclusion_applied = TRUE,
    all_zero_medi_sensitivity_available = TRUE,
    diary_sleep_excluded_from_denominator = FALSE,
    expected_wall_minutes_per_hour = 60L,
    expected_wall_minutes_per_day = 1440L,
    minimum_hour_coverage = 0.51,
    minimum_day_coverage = 0.80
  ),
  file.path(bad_coverage_root, "coverage_settings.csv")
)
bad_coverage_settings_error <- tryCatch(
  {
    validate_preparation02_settings(bad_coverage_root, "glasses")
    FALSE
  },
  error = function(error) {
    grepl(
      "0.50 hourly requirement",
      conditionMessage(error),
      fixed = TRUE
    )
  }
)
stopifnot(bad_coverage_settings_error)

fixed <- new_fixed_test_profiles()
profile_path <- file.path(profile_root, "reference_profiles.rds")
timing_distribution_path <- file.path(
  profile_root,
  "timing_exceedance_distributions.rds"
)
map_path <- file.path(profile_root, "metric_relevance_maps.rds")
saveRDS(fixed$profiles, profile_path)
saveRDS(fixed$distribution_profiles, timing_distribution_path)
saveRDS(fixed$maps, map_path)
profile_sha256 <- artifact_sha256(profile_path)
timing_distribution_sha256 <- artifact_sha256(
  timing_distribution_path
)
map_sha256 <- artifact_sha256(map_path)

message("Checking the required explicit state-window setting")
missing_gate_error <- tryCatch(
  {
    build_metric_derivation(
      root = test_root,
      run_label = "smoke",
      placements = "glasses"
    )
    FALSE
  },
  error = function(error) {
    grepl(
      "`minimum_state_support` is required",
      conditionMessage(error),
      fixed = TRUE
    )
  }
)
stopifnot(missing_gate_error)
non_synthetic_provisional_error <- tryCatch(
  {
    build_metric_derivation(
      root = test_root,
      run_label = "smoke",
      placements = "glasses",
      minimum_state_support = 0.80,
      provisional_state_support = TRUE
    )
    FALSE
  },
  error = function(error) {
    grepl("only in a synthetic test", conditionMessage(error))
  }
)
stopifnot(non_synthetic_provisional_error)

message("Checking the approved canonical state-support cutoff")
canonical_layout <- list(metric_run_root = paths$metrics)
invisible(assert_primary_state_support_cutoff(
  0.80,
  canonical_layout,
  paths
))
unapproved_primary_error <- tryCatch(
  {
    assert_primary_state_support_cutoff(
      0.70,
      canonical_layout,
      paths
    )
    FALSE
  },
  error = function(error) {
    grepl(
      "author-approved 0.80",
      conditionMessage(error),
      fixed = TRUE
    )
  }
)
stopifnot(unapproved_primary_error)

message("Checking the approved MDER viable-ratio fraction")
invisible(assert_primary_mder_viable_fraction(
  0.50,
  canonical_layout,
  paths
))
unapproved_mder_primary_error <- tryCatch(
  {
    assert_primary_mder_viable_fraction(
      0.40,
      canonical_layout,
      paths
    )
    FALSE
  },
  error = function(error) {
    grepl(
      "author-approved 0.50",
      conditionMessage(error),
      fixed = TRUE
    )
  }
)
invisible(assert_primary_mder_viable_fraction(
  0.40,
  run_variant_layout,
  paths
))
stopifnot(unapproved_mder_primary_error)

message("Building the cutoff-neutral state-support gate diagnostics")
state_gate <- build_state_support_gate(
  root = test_root,
  run_label = "smoke",
  placements = "glasses"
)
stopifnot(
  nrow(state_gate$daily) == nrow(scenario_table) * 3L,
  nrow(state_gate$candidates) == 9L,
  nrow(state_gate$site_candidates) == 9L,
  all(state_gate$inputs$status == "AUTHOR_GATE_INPUT_NOT_A_SELECTED_RULE"),
  all(state_gate$candidates$status == "diagnostic_only_not_final"),
  all(
    state_gate$candidates$classification_total ==
      state_gate$candidates$eligible_participant_days
  ),
  all(
    state_gate$site_candidates$classification_total ==
      state_gate$site_candidates$eligible_participant_days
  ),
  all(
    state_gate$candidates$marginal_metric_instance_loss_from_lower[
      !is.na(
        state_gate$candidates$marginal_metric_instance_loss_from_lower
      )
    ] >=
      0L
  ),
  all(file.exists(c(
    state_gate$daily_path,
    state_gate$candidates_path,
    state_gate$site_candidates_path,
    state_gate$inputs_path,
    state_gate$artifact_manifest_path
  )))
)

message("Checking fixed registry, inclusive boundaries, and invariants")
invalid_state_registry_error <- tryCatch(
  {
    state_support_cutoff_diagnostics(
      state_gate$daily,
      candidate_cutoffs = c(0.70, 0.80)
    )
    FALSE
  },
  error = function(error) {
    grepl(
      "fixed at 0.70, 0.80, and 0.90",
      conditionMessage(error),
      fixed = TRUE
    )
  }
)
stopifnot(invalid_state_registry_error)
boundary_state_support <- state_gate$daily |>
  dplyr::filter(
    .data$site == dplyr::first(.data$site),
    .data$Id == dplyr::first(.data$Id),
    .data$local_date == dplyr::first(.data$local_date)
  ) |>
  dplyr::arrange(.data$metric) |>
  dplyr::mutate(
    expected_minutes = 10L,
    valid_minutes = c(7L, 8L, 9L),
    ordinary_support = .data$valid_minutes / .data$expected_minutes,
    state_domain_complete = TRUE,
    failure_reason = NA_character_
  )
boundary_classification <- classify_state_support_candidates(
  boundary_state_support
)
stopifnot(
  all(
    boundary_classification$retained_at_candidate[
      boundary_classification$ordinary_support ==
        boundary_classification$candidate_state_support_cutoff
    ]
  )
)
inconsistent_state_support <- boundary_state_support
inconsistent_state_support$state_domain_complete[1L] <- FALSE
inconsistent_state_error <- tryCatch(
  {
    state_support_cutoff_diagnostics(inconsistent_state_support)
    FALSE
  },
  error = function(error) {
    grepl(
      "inconsistent state completeness",
      conditionMessage(error),
      fixed = TRUE
    )
  }
)
stopifnot(inconsistent_state_error)

message("Running Preparation 04 only with the provisional synthetic cutoff")
result <- build_metric_derivation(
  root = test_root,
  run_label = "smoke",
  placements = "glasses",
  minimum_state_support = 0.80,
  minimum_mder_viable_fraction = 0.50,
  provisional_state_support = TRUE,
  synthetic_test = TRUE
)
metric <- result$results$glasses
stopifnot(
  identical(
    normalizePath(result$metric_run_root, winslash = "/", mustWork = TRUE),
    normalizePath(
      file.path(paths$metrics, "runs", "smoke"),
      winslash = "/",
      mustWork = TRUE
    )
  ),
  !file.exists(file.path(paths$metrics, "metrics_glasses_participant_day.rds")),
  artifact_sha256(coverage_path) == coverage_sha256,
  artifact_sha256(profile_path) == profile_sha256,
  artifact_sha256(timing_distribution_path) == timing_distribution_sha256,
  artifact_sha256(map_path) == map_sha256
)

message("Checking rectangular day/bin/hour outputs and no excluded window")
stopifnot(
  nrow(metric$daily_metrics) == nrow(scenario_table),
  nrow(metric$thirty_minute) == nrow(scenario_table) * 48L,
  nrow(metric$hourly) == nrow(scenario_table) * 24L,
  !any(grepl(
    "L5",
    c(
      names(metric$daily_metrics),
      names(metric$participant_metrics),
      names(metric$thirty_minute),
      names(metric$hourly),
      metric$metric_values$metric
    ),
    fixed = TRUE
  )),
  all(
    metric$metric_values$descriptive_nonconfirmatory[
      metric$metric_values$metric == "duration_above_250_full_day"
    ]
  )
)

day_metric <- function(date) {
  metric$daily_metrics |>
    dplyr::filter(.data$local_date == as.Date(date))
}
day_value <- function(date, metric_name) {
  metric$metric_values |>
    dplyr::filter(
      .data$local_date == as.Date(date),
      .data$metric == metric_name
    )
}

message("Checking strict thresholds, zero events, and state windows")
baseline <- day_metric("2026-01-01")
no_event <- day_metric("2026-01-02")
stopifnot(
  abs(baseline$duration_above_1000_h - 1 / 60) < 1e-12,
  abs(baseline$duration_below_1_sleep_environment_h - 1 / 60) < 1e-12,
  no_event$duration_above_250_full_day_h == 0,
  is.na(no_event$first_timing_above_250_clock_minute),
  day_value("2026-01-02", "first_timing_above_250")$failure_reason ==
    "no_threshold_event",
  is.na(day_metric("2026-01-08")$duration_below_10_pre_sleep_h),
  day_value("2026-01-08", "duration_below_10_pre_sleep")$failure_reason ==
    "no_state_window",
  is.na(day_metric("2026-01-09")$duration_below_10_pre_sleep_h),
  day_value("2026-01-09", "duration_below_10_pre_sleep")$failure_reason ==
    "insufficient_state_support"
)

message("Checking projected state denominators and incomplete domains")
known_gap_support <- day_value(
  "2026-01-10",
  "duration_above_250_wake"
)
boundary_wake_support <- day_value(
  "2026-01-11",
  "duration_above_250_wake"
)
boundary_pre_sleep_support <- day_value(
  "2026-01-11",
  "duration_below_10_pre_sleep"
)
unknown_state_values <- metric$metric_values |>
  dplyr::filter(
    .data$local_date == as.Date("2026-01-12"),
    .data$metric %in%
      c(
        "duration_above_250_wake",
        "duration_below_10_pre_sleep",
        "duration_below_1_sleep_environment"
      )
  )
unknown_state_gate <- state_gate$daily |>
  dplyr::filter(.data$local_date == as.Date("2026-01-12"))
stopifnot(
  known_gap_support$expected_minutes == 720L,
  known_gap_support$valid_minutes == 690L,
  abs(known_gap_support$ordinary_support - 690 / 720) < 1e-12,
  boundary_wake_support$expected_minutes == 720L,
  boundary_wake_support$valid_minutes == 715L,
  boundary_pre_sleep_support$expected_minutes == 240L,
  boundary_pre_sleep_support$valid_minutes == 235L,
  nrow(unknown_state_values) == 3L,
  all(!unknown_state_values$estimable),
  all(unknown_state_values$failure_reason == "incomplete_state_domain"),
  all(unknown_state_gate$failure_reason == "incomplete_state_domain"),
  all(unknown_state_gate$unknown_diary_state_minutes == 60L),
  day_metric("2026-01-12")$diary_state_domain_complete == FALSE,
  is.finite(day_metric("2026-01-12")$daily_geometric_mean_medi_lx)
)

message("Checking non-wrapping M10 and midnight-wrapping L10")
stopifnot(
  baseline$m10_onset_clock_minute == 480,
  baseline$m10_midpoint_clock_minute == 780,
  baseline$m10_offset_clock_minute == 1080,
  baseline$l10_onset_clock_minute == 1200,
  baseline$l10_midpoint_clock_minute == 60,
  baseline$l10_offset_clock_minute == 360
)

message("Checking all-candidate M10 ties retain level but not timing")
m10_all_tie_day <- day_metric("2026-01-17")
m10_all_tie_level <- day_value("2026-01-17", "m10_mean_medi")
m10_all_tie_timing <- metric$metric_values |>
  dplyr::filter(
    .data$local_date == as.Date("2026-01-17"),
    .data$metric %in% c("m10_midpoint", "m10_onset", "m10_offset")
  )
m10_all_tie_censoring <- metric$censoring |>
  dplyr::filter(.data$local_date == as.Date("2026-01-17"))
stopifnot(
  m10_all_tie_day$m10_mean_medi_lx == 0,
  all(is.na(c(
    m10_all_tie_day$m10_midpoint_clock_minute,
    m10_all_tie_day$m10_onset_clock_minute,
    m10_all_tie_day$m10_offset_clock_minute
  ))),
  nrow(m10_all_tie_level) == 1L,
  m10_all_tie_level$estimable,
  is.na(m10_all_tie_level$failure_reason),
  nrow(m10_all_tie_timing) == 3L,
  all(!m10_all_tie_timing$estimable),
  all(is.na(m10_all_tie_timing$value)),
  all(m10_all_tie_timing$failure_reason == "all_candidates_tied"),
  m10_all_tie_censoring$m10_tied_windows == 841L
)

message("Checking gap-broken bouts and unsupported bins")
broken <- day_metric("2026-01-03")
broken_primary_bout <- day_value(
  "2026-01-03",
  "longest_bout_above_250"
)
broken_exact_bout <- day_value(
  "2026-01-03",
  "longest_bout_above_250_exact_only_sensitivity"
)
broken_censoring <- metric$censoring |>
  dplyr::filter(.data$local_date == as.Date("2026-01-03"))
stopifnot(
  abs(broken$longest_bout_above_250_observed_h - 10 / 60) < 1e-12,
  abs(
    broken$longest_bout_above_250_observed_lower_bound_h - 10 / 60
  ) <
    1e-12,
  abs(broken$longest_bout_above_250_h - 10 / 60) < 1e-12,
  broken$longest_bout_above_250_possible_upper_bound_h >
    broken$longest_bout_above_250_h,
  is.na(broken$longest_bout_above_250_exact_only_sensitivity_h),
  broken$longest_bout_above_250_censored,
  !broken$longest_bout_above_250_exact_identifiable,
  broken$longest_bout_above_250_missing_invalid_breaks_runs,
  broken$longest_bout_above_250_estimate_interpretation ==
    "observed_lower_bound",
  baseline$longest_bout_above_250_exact_identifiable,
  baseline$longest_bout_above_250_exact_only_sensitivity_h ==
    baseline$longest_bout_above_250_h,
  nrow(broken_primary_bout) == 1L,
  broken_primary_bout$estimable,
  abs(broken_primary_bout$value - 10 / 60) < 1e-12,
  broken_primary_bout$estimate_interpretation == "observed_lower_bound",
  broken_primary_bout$missing_invalid_breaks_runs,
  !broken_primary_bout$exact_identifiable,
  nrow(broken_exact_bout) == 1L,
  !broken_exact_bout$estimable,
  is.na(broken_exact_bout$value),
  broken_exact_bout$failure_reason ==
    "not_exactly_identifiable_due_to_missing_or_invalid_minutes",
  nrow(broken_censoring) == 1L,
  broken_censoring$longest_bout_censored,
  broken_censoring$longest_bout_censor_reason ==
    "missing_or_invalid_minutes_allow_longer_bout",
  broken_censoring$longest_bout_missing_invalid_breaks_runs,
  !broken_censoring$longest_bout_exact_identifiable
)
unsupported_30 <- metric$thirty_minute |>
  dplyr::filter(
    .data$local_date == as.Date("2026-01-06"),
    .data$clock_bin == 120L
  )
supported_hour <- metric$hourly |>
  dplyr::filter(
    .data$local_date == as.Date("2026-01-06"),
    .data$clock_hour == 2L
  )
unsupported_hour <- metric$hourly |>
  dplyr::filter(
    .data$local_date == as.Date("2026-01-07"),
    .data$clock_hour == 5L
  )
stopifnot(
  unsupported_30$valid_medi_wall_minutes == 14L,
  !unsupported_30$bin_admissible,
  is.na(unsupported_30$metric_value_lx),
  supported_hour$valid_medi_wall_minutes == 44L,
  supported_hour$bin_admissible,
  unsupported_hour$valid_medi_wall_minutes == 29L,
  !unsupported_hour$bin_admissible,
  is.na(unsupported_hour$metric_value_lx)
)

message("Checking time-sensitive dose and mean-of-viable-ratios MDER")
low_missing <- day_metric("2026-01-04")
high_missing <- day_metric("2026-01-05")
  mder_40 <- day_metric("2026-01-14")
  mder_50 <- day_metric("2026-01-15")
  mder_zero_pairs <- day_metric("2026-01-16")
  mder_40_value <- day_value(
    "2026-01-14",
    "mder_mean_of_viable_ratios"
  )
  mder_40_support <- metric$support |>
    dplyr::filter(
      .data$local_date == as.Date("2026-01-14"),
      .data$metric == "mder_mean_of_viable_ratios"
    )
stopifnot(
  is.finite(low_missing$dose_corrected_medi_lx_h),
  low_missing$dose_relevance_coverage > high_missing$dose_relevance_coverage,
  high_missing$dose_relevance_coverage < 0.80,
  is.na(high_missing$dose_corrected_medi_lx_h),
  abs(baseline$mder - 0.5) < 1e-12,
  is.finite(mder_40$daily_geometric_mean_medi_lx),
  is.na(mder_40$mder),
  abs(mder_40$mder_viable_ratio_fraction - 0.40) < 1e-12,
  mder_40$mder_minimum_viable_fraction == 0.50,
  !mder_40$mder_passes_viable_ratio_support,
  mder_40$mder_support_threshold_enforced,
  !mder_40$mder_ratio_scaled_or_weighted,
  !mder_40$mder_estimable,
  mder_40$mder_failure_reason == "below_viable_ratio_fraction",
  nrow(mder_40_value) == 1L,
  !mder_40_value$estimable,
  mder_40_value$failure_reason == "below_viable_ratio_fraction",
  nrow(mder_40_support) == 1L,
  abs(mder_40_support$ordinary_support - 0.40) < 1e-12,
  is.na(mder_40_support$medi_profile_support),
  is.na(mder_40_support$light_profile_support),
  mder_40_support$minimum_support == 0.50,
  !mder_40_support$passes_ordinary_support,
  mder_40_support$support_threshold_enforced,
  !mder_40_support$ratio_scaled_or_weighted,
  abs(mder_50$mder_viable_ratio_fraction - 0.50) < 1e-12,
  mder_50$mder_passes_viable_ratio_support,
  is.finite(mder_50$mder),
  abs(mder_zero_pairs$mder_viable_ratio_fraction - 0.80) < 1e-12,
  mder_zero_pairs$mder_excluded_zero_either_minutes == 288L,
  mder_zero_pairs$mder_passes_viable_ratio_support,
  is.finite(mder_zero_pairs$mder),
  is.na(mder_zero_pairs$mder_failure_reason)
)

message("Checking independent namespaced MDER threshold behavior")
mder_40_sensitivity <- derive_metric_set(
  coverage = coverage |>
    dplyr::filter(
      .data$local_date %in%
        as.Date(c("2026-01-09", "2026-01-14"))
    ),
  state_intervals = state_inputs,
  profiles = fixed$profiles,
  maps = fixed$maps,
  placement = "glasses",
  minimum_state_support = 0.80,
  minimum_mder_viable_fraction = 0.40
)
mder_40_day <- mder_40_sensitivity$daily_metrics |>
  dplyr::filter(.data$local_date == as.Date("2026-01-14"))
state_80_day <- mder_40_sensitivity$daily_metrics |>
  dplyr::filter(.data$local_date == as.Date("2026-01-09"))
stopifnot(
  is.finite(mder_40_day$mder),
  mder_40_day$mder_minimum_viable_fraction == 0.40,
  is.na(state_80_day$duration_below_10_pre_sleep_h)
)

message("Checking 23/25-hour true time and fall-back wall collapse")
spring_gap <- metric$gap |>
  dplyr::filter(.data$local_date == as.Date("2026-03-29"))
fall_gap <- metric$gap |>
  dplyr::filter(.data$local_date == as.Date("2026-10-25"))
fall_bin <- metric$thirty_minute |>
  dplyr::filter(
    .data$local_date == as.Date("2026-10-25"),
    .data$clock_bin == 120L
  )
spring_clock <- metric$censoring |>
  dplyr::filter(.data$local_date == as.Date("2026-03-29"))
fall_clock <- metric$censoring |>
  dplyr::filter(.data$local_date == as.Date("2026-10-25"))
stopifnot(
  spring_gap$expected_real_minutes == 1380L,
  spring_gap$structural_nonexistent_wall_minutes == 60L,
  fall_gap$expected_real_minutes == 1500L,
  fall_gap$dst_fold_real_minutes == 120L,
  fall_bin$source_real_minutes == 60L,
  fall_bin$dst_fold_wall_minutes == 30L,
  spring_clock$structural_nonexistent_wall_minutes == 60L,
  fall_clock$dst_fold_wall_minutes == 60L,
  fall_clock$maximum_true_minutes_per_wall_minute == 2L,
  nrow(metric$thirty_minute[
    metric$thirty_minute$local_date == as.Date("2026-10-25"),
  ]) ==
    48L,
  nrow(metric$hourly[
    metric$hourly$local_date == as.Date("2026-10-25"),
  ]) ==
    24L
)

message("Checking participant IS/IV and candidate state cutoffs")
participant <- metric$participant_metrics
candidates <- result$state_support_candidates
pre_sleep_candidates <- candidates |>
  dplyr::filter(.data$metric == "duration_below_10_pre_sleep") |>
  dplyr::arrange(.data$candidate_state_support_cutoff)
stopifnot(
  nrow(participant) == 1L,
  is.finite(participant$interdaily_stability),
  is.finite(participant$intradaily_variability),
  participant$is_folded_hours >= 1L,
  nrow(candidates) == 9L,
  identical(
    pre_sleep_candidates$candidate_state_support_cutoff,
    c(0.70, 0.80, 0.90)
  ),
  all(diff(pre_sleep_candidates$retained_metric_instances) <= 0L),
  all(candidates$status == "diagnostic_only_not_final"),
  all(candidates$incomplete_state_domain_instances == 1L),
  result$settings$state_support_status ==
    "PROVISIONAL_SYNTHETIC_ONLY_NOT_FINAL",
  result$settings$mder_support_cutoff == 0.50,
  result$settings$mder_support_decision_id == "METRIC-010",
  result$settings$mder_support_status == "author_approved",
  result$settings$mder_support_candidates == "0.5",
  is.na(result$settings$mder_support_sensitivity_cutoffs),
  result$settings$mder_failure_scope == "metric_specific_only_day_retained",
  result$settings$mder_ratio_definition ==
    "arithmetic_mean_of_positive_finite_one_minute_ratios",
  result$settings$mder_pair_resolution_minutes == 1L,
  result$settings$mder_zero_pair_rule == "exclude_if_either_channel_zero",
  !result$settings$mder_ratio_scaled_or_weighted,
  result$settings$numerical_zero_decision_id == "METRIC-011",
  result$settings$numerical_zero_status == "author_approved",
  result$settings$numerical_zero_scope ==
    "offset_geometric_mean_backtransforms",
  result$settings$numerical_zero_tolerance_multiplier == 100,
  result$settings$numerical_zero_positive_requires_all_source_zero,
  result$settings$numerical_zero_raw_value_preserved,
  result$settings$numerical_zero_reclassified_cells ==
    nrow(metric$numerical_zero_audit),
  result$settings$numerical_zero_zero_capable_model_rule ==
    "retain_participant_day_as_zero",
  result$settings$numerical_zero_two_part_model_rule ==
    paste0(
      "retain_in_zero_occurrence_component;exclude_only_from_",
      "strictly_positive_magnitude_component"
    ),
  result$settings$window_minutes == 600L,
  result$settings$rolling_window_candidate_step_minutes == 1L,
  result$settings$rolling_window_profile_bin_minutes == 30L,
  !result$settings$m10_wraps_midnight,
  result$settings$l10_wraps_midnight,
  result$settings$excluded_darkest_window == "five_hour_window_not_produced",
  result$settings$timing_exceedance_distributions_sha256 ==
    timing_distribution_sha256,
  result$settings$timing_exceedance_threshold_lx == 250,
  result$settings$timing_exceedance_comparison == "strict_greater_than",
  result$settings$timing_exceedance_aggregation ==
    "equal_days_within_participant_then_equal_participants",
  result$settings$timing_exceedance_application ==
    "support_only_no_value_scaling",
  result$settings$longest_bout_primary ==
    "longest_observed_uninterrupted_above_250_lower_bound",
  result$settings$longest_bout_missing_rule ==
    "missing_or_invalid_minutes_break_observed_runs",
  result$settings$longest_bout_possible_bound ==
    "upper_bound_if_all_missing_or_invalid_minutes_qualified",
  result$settings$longest_bout_exact_only_sensitivity,
  result$settings$longest_bout_failure_scope ==
    "metric_specific_only_day_retained",
  result$settings$longest_bout_winner_selection_rule ==
    "earliest_onset_then_earliest_offset",
  result$settings$longest_bout_day_boundary_contact_scope ==
    "selected_winner_with_any_winning_run_diagnostic",
  nrow(result$state_interval_inputs) == 2L,
  all(file.exists(result$state_interval_inputs$state_interval_path)),
  all(
    result$state_interval_inputs$state_interval_sha256 ==
      state_inputs$inputs$actual_sha256
  ),
  participant$valid_minutes == sum(is.finite(coverage$MEDI_eligible)),
  participant$expected_minutes == nrow(coverage),
  participant$valid_minutes != participant$valid_hours * 60
)

message("Checking explicit long-table key enforcement")
duplicate_long_error <- tryCatch(
  {
    assert_metric_long_unique(
      dplyr::bind_rows(
        metric$metric_values,
        metric$metric_values[1L, , drop = FALSE]
      ),
      object = "deliberately duplicated long metric values"
    )
    FALSE
  },
  error = function(error) {
    grepl("duplicated row", conditionMessage(error), fixed = TRUE)
  }
)
stopifnot(duplicate_long_error)

message("Checking source-ready CSVs, manifests, and deterministic reruns")
manifest <- readr::read_csv(
  result$artifact_manifest_path,
  show_col_types = FALSE
)
placement_manifest <- manifest |>
  dplyr::filter(.data$placement == "glasses")
stopifnot(
  nrow(manifest) == 17L,
  nrow(placement_manifest) == 14L,
  all(placement_manifest$mder_support_cutoff == 0.50),
  all(placement_manifest$mder_support_decision_id == "METRIC-010"),
  all(placement_manifest$mder_support_status == "author_approved"),
  all(placement_manifest$mder_support_candidates == "0.5"),
  all(is.na(placement_manifest$mder_support_sensitivity_cutoffs)),
  all(
    placement_manifest$mder_failure_scope == "metric_specific_only_day_retained"
  ),
  all(!placement_manifest$mder_ratio_scaled_or_weighted),
  all(placement_manifest$numerical_zero_decision_id == "METRIC-011"),
  all(placement_manifest$numerical_zero_status == "author_approved"),
  all(
    placement_manifest$numerical_zero_scope ==
      "offset_geometric_mean_backtransforms"
  ),
  all(placement_manifest$numerical_zero_tolerance_multiplier == 100),
  all(placement_manifest$numerical_zero_positive_requires_all_source_zero),
  all(placement_manifest$numerical_zero_raw_value_preserved),
  all(
    placement_manifest$numerical_zero_reclassified_cells ==
      nrow(metric$numerical_zero_audit)
  ),
  all(placement_manifest$rolling_window_minutes == 600L),
  all(placement_manifest$rolling_window_candidate_step_minutes == 1L),
  all(placement_manifest$rolling_window_profile_bin_minutes == 30L),
  all(
    placement_manifest$timing_exceedance_distributions_sha256 ==
      timing_distribution_sha256
  ),
  all(!placement_manifest$m10_wraps_midnight),
  all(placement_manifest$l10_wraps_midnight),
  all(
    placement_manifest$excluded_darkest_window ==
      "five_hour_window_not_produced"
  ),
  all(
    placement_manifest$longest_bout_primary ==
      "longest_observed_uninterrupted_above_250_lower_bound"
  ),
  all(
    placement_manifest$longest_bout_missing_rule ==
      "missing_or_invalid_minutes_break_observed_runs"
  ),
  all(
    placement_manifest$longest_bout_possible_bound ==
      "upper_bound_if_all_missing_or_invalid_minutes_qualified"
  ),
  all(placement_manifest$longest_bout_exact_only_sensitivity),
  all(
    placement_manifest$longest_bout_failure_scope ==
      "metric_specific_only_day_retained"
  ),
  all(
    placement_manifest$longest_bout_winner_selection_rule ==
      "earliest_onset_then_earliest_offset"
  ),
  all(
    placement_manifest$longest_bout_day_boundary_contact_scope ==
      "selected_winner_with_any_winning_run_diagnostic"
  ),
  all(file.exists(manifest$path)),
  all(vapply(
    seq_len(nrow(manifest)),
    function(index) {
      artifact_sha256(manifest$path[index]) == manifest$sha256[index]
    },
    logical(1)
  ))
)
numerical_zero_audit <- readr::read_csv(
  result$output_paths$glasses$numerical_zero_audit,
  show_col_types = FALSE
)
stopifnot(
  nrow(numerical_zero_audit) == nrow(metric$numerical_zero_audit),
  identical(names(numerical_zero_audit), names(metric$numerical_zero_audit))
)
if (nrow(numerical_zero_audit) > 0L) {
  stopifnot(
    all(numerical_zero_audit$raw_backtransformed_value_lx != 0),
    all(numerical_zero_audit$normalized_value_lx == 0),
    all(
      abs(numerical_zero_audit$raw_backtransformed_value_lx) <=
        numerical_zero_audit$numerical_zero_tolerance_lx
    ),
    all(
      numerical_zero_audit$raw_backtransformed_value_lx <= 0 |
        numerical_zero_audit$source_all_zero
    ),
    all(numerical_zero_audit$raw_value_preserved)
  )
}
daily_sha256 <- artifact_sha256(
  result$output_paths$glasses$daily_rds
)
participant_sha256 <- artifact_sha256(
  result$output_paths$glasses$participant_rds
)
rerun <- build_metric_derivation(
  root = test_root,
  run_label = "smoke",
  placements = "glasses",
  minimum_state_support = 0.80,
  minimum_mder_viable_fraction = 0.50,
  provisional_state_support = TRUE,
  synthetic_test = TRUE
)
stopifnot(
  artifact_sha256(rerun$output_paths$glasses$daily_rds) == daily_sha256,
  artifact_sha256(rerun$output_paths$glasses$participant_rds) ==
    participant_sha256,
  artifact_sha256(coverage_path) == coverage_sha256,
  artifact_sha256(profile_path) == profile_sha256,
  artifact_sha256(timing_distribution_path) == timing_distribution_sha256,
  artifact_sha256(map_path) == map_sha256
)

message("All Preparation 04 builder tests passed")
