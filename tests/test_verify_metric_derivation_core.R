source("scripts/pipeline/paths_io.R")
source("scripts/pipeline/assertions.R")
source("scripts/pipeline/verify_metric_derivation_core.R")

options(warn = 2)

test_p04_core_expect_error <- function(expression, pattern) {
  observed <- tryCatch(
    {
      force(expression)
      ""
    },
    error = function(error) conditionMessage(error)
  )
  stopifnot(
    nzchar(observed),
    grepl(pattern, observed, fixed = TRUE)
  )
  invisible(observed)
}

test_p04_core_circular <- function(minutes) {
  radians <- minutes / 1440 * 2 * pi
  vector <- mean(exp(1i * radians))
  list(
    mean = (Arg(vector) %% (2 * pi)) / (2 * pi) * 1440,
    resultant = Mod(vector)
  )
}

test_p04_core_coverage <- function(placement) {
  dates <- as.Date(c("2026-01-01", "2026-01-02"))
  rows <- lapply(seq_along(dates), function(index) {
    local_date <- dates[[index]]
    clock_minute <- 0:1439
    datetime <- as.POSIXct(local_date, tz = "UTC") + clock_minute * 60
    medi <- rep(100, 1440L)
    if (index == 1L) {
      medi[301:311] <- 300
      medi[101] <- NA_real_
    } else {
      medi[501:505] <- 300
      medi[506:521] <- NA_real_
    }
    brown <- ifelse(clock_minute < 420L, "sleep", "wake")
    context <- ifelse(
      brown == "sleep",
      "bedside_sleep_environment",
      ifelse(
        identical(placement, "glasses"),
        "worn_near_eye",
        "worn_chest"
      )
    )
    tibble::tibble(
      site = "SITE",
      Id = "P01",
      position = placement,
      local_date = local_date,
      timezone = "UTC",
      datetime_utc = datetime,
      datetime_wall = datetime,
      clock_minute = clock_minute,
      day_eligible = TRUE,
      MEDI_eligible = medi,
      LIGHT_eligible = medi * 2,
      source_subepochs = 6L,
      State.Brown = brown,
      measurement_context = context
    )
  })
  dplyr::bind_rows(rows)
}

test_p04_core_state_artifacts <- function(paths, run_label) {
  state_root <- file.path(
    paths$aligned,
    "runs",
    run_label,
    "state_intervals"
  )
  dir.create(state_root, recursive = TRUE)
  origin <- as.POSIXct("2026-01-01 00:00:00", tz = "UTC")
  sleep <- tibble::tibble(
    site = "SITE",
    Id = "P01",
    timezone = "UTC",
    interval_kind = "sleep",
    interval_bounds = "[)",
    start = origin + c(0, 420, 1440, 1860) * 60,
    end = origin + c(420, 1440, 1860, 2880) * 60,
    State.Brown = c("sleep", "wake", "sleep", "wake"),
    sleep = c("sleepprep", "wake", "sleepprep", "wake")
  )
  wear <- tibble::tibble(
    site = "SITE",
    Id = "P01",
    timezone = "UTC",
    interval_kind = "wear",
    interval_bounds = "[)",
    start = origin,
    end = origin + 2880 * 60,
    wear = "sleep"
  )
  sleep_path <- file.path(state_root, "SITE_sleep_intervals.rds")
  wear_path <- file.path(state_root, "SITE_wear_intervals.rds")
  sleep_record <- manifest_row(write_rds_artifact(
    sleep,
    sleep_path,
    producer = "scripts/pipeline/build_import_alignment.R",
    metadata = list(
      artifact_type = "site_sleep_state_intervals",
      run_label = run_label,
      site = "SITE",
      interval_kind = "sleep"
    )
  ))
  wear_record <- manifest_row(write_rds_artifact(
    wear,
    wear_path,
    producer = "scripts/pipeline/build_import_alignment.R",
    metadata = list(
      artifact_type = "site_wear_state_intervals",
      run_label = run_label,
      site = "SITE",
      interval_kind = "wear"
    )
  ))
  manifest <- dplyr::bind_rows(sleep_record, wear_record)
  manifest_path <- file.path(
    paths$manifests,
    paste0("state_interval_artifacts_", run_label, ".csv")
  )
  readr::write_csv(manifest, manifest_path, na = "")
  list(
    root = state_root,
    manifest_path = manifest_path,
    manifest_sha256 = artifact_sha256(manifest_path),
    sleep_path = sleep_path,
    sleep_sha256 = artifact_sha256(sleep_path),
    wear_path = wear_path,
    wear_sha256 = artifact_sha256(wear_path)
  )
}

test_p04_core_profile_artifacts <- function(paths, run_label) {
  profile_root <- file.path(paths$profiles, "runs", run_label)
  dir.create(profile_root, recursive = TRUE)
  reference_profiles <- tibble::tibble(
    profile_variant = "pooled",
    profile_scope = "pooled",
    profile_site = NA_character_,
    held_out_site = NA_character_,
    placement = rep(c("chest", "glasses"), each = 48L),
    state_domain = "full_day",
    signal = "MEDI",
    clock_bin = rep(seq.int(0L, 1410L, 30L), 2L),
    reference_weight = 1 / 48
  )
  distribution <- reference_profiles |>
    dplyr::transmute(
      .data$profile_scope,
      .data$profile_variant,
      .data$profile_site,
      .data$held_out_site,
      .data$placement,
      .data$state_domain,
      .data$signal,
      .data$clock_bin,
      exceedance_probability = 1,
      supported_exceedance_probability = 1,
      probability_weight = 1 / 48,
      profile_estimable = TRUE,
      exceedance_threshold_lx = 250,
      exceedance_comparison = "strict_greater_than",
      probability_unit = "proportion_of_valid_wall_minutes",
      probability_aggregation = paste0(
        "valid_minutes_within_participant_day_bin;",
        "equal_days_within_participant_bin;",
        "equal_participants_within_profile_bin"
      )
    )
  maps <- distribution |>
    dplyr::transmute(
      .data$profile_scope,
      .data$profile_variant,
      .data$profile_site,
      .data$held_out_site,
      .data$placement,
      .data$state_domain,
      .data$signal,
      .data$clock_bin,
      metric_map = "timing_above_250",
      map_application = "support_only",
      relevance_source = "participant_balanced_exceedance_distribution",
      relevance_mass = .data$supported_exceedance_probability,
      relevance_weight = .data$probability_weight,
      map_estimable = .data$profile_estimable,
      value_correction_allowed = FALSE,
      ratio_correction_allowed = FALSE,
      paired_channel_required = FALSE,
      .data$exceedance_probability,
      .data$exceedance_threshold_lx,
      .data$exceedance_comparison,
      .data$probability_unit,
      .data$probability_aggregation
    )
  profile_path <- file.path(profile_root, "reference_profiles.rds")
  distribution_path <- file.path(
    profile_root,
    "timing_exceedance_distributions.rds"
  )
  map_path <- file.path(profile_root, "metric_relevance_maps.rds")
  saveRDS(reference_profiles, profile_path, version = 3)
  saveRDS(distribution, distribution_path, version = 3)
  saveRDS(maps, map_path, version = 3)
  list(
    root = profile_root,
    profile_path = profile_path,
    profile_sha256 = artifact_sha256(profile_path),
    distribution_path = distribution_path,
    distribution_sha256 = artifact_sha256(distribution_path),
    map_path = map_path,
    map_sha256 = artifact_sha256(map_path)
  )
}

test_p04_core_expected_days <- function(placement) {
  day1_circle <- test_p04_core_circular(300:310)
  day2_circle <- test_p04_core_circular(500:504)
  dates <- as.Date(c("2026-01-01", "2026-01-02"))
  onset <- as.POSIXct(dates, tz = "UTC") + c(300, 500) * 60
  offset <- as.POSIXct(dates, tz = "UTC") + c(311, 505) * 60
  tibble::tibble(
    site = "SITE",
    Id = "P01",
    position = placement,
    local_date = dates,
    profile_variant = "pooled",
    expected_real_minutes = 1440L,
    valid_medi_real_minutes = c(1439L, 1424L),
    longest_bout_above_250_h = c(11, 5) / 60,
    longest_bout_above_250_observed_h = c(11, 5) / 60,
    longest_bout_above_250_observed_lower_bound_h = c(11, 5) / 60,
    longest_bout_above_250_possible_h = c(11, 21) / 60,
    longest_bout_above_250_possible_upper_bound_h = c(11, 21) / 60,
    longest_bout_above_250_exact_only_sensitivity_h = c(11 / 60, NA_real_),
    longest_bout_above_250_exact_identifiable = c(TRUE, FALSE),
    longest_bout_above_250_censored = c(FALSE, TRUE),
    longest_bout_above_250_missing_invalid_breaks_runs = TRUE,
    longest_bout_above_250_estimate_interpretation = "observed_lower_bound",
    longest_bout_above_250_onset_utc = onset,
    longest_bout_above_250_offset_utc = offset,
    longest_bout_above_250_day_boundary_contact = FALSE,
    longest_bout_above_250_censor_reason = c(
      NA_character_,
      "missing_or_invalid_minutes_allow_longer_bout"
    ),
    first_timing_above_250_clock_minute = c(300, 500),
    last_timing_above_250_clock_minute = c(310, 504),
    mean_timing_above_250_clock_minute = c(
      day1_circle$mean,
      day2_circle$mean
    ),
    timing_overall_support = c(1439 / 1440, 1424 / 1440),
    timing_first_support = c(300 / 301, 1),
    timing_last_support = c(1, 920 / 936),
    timing_resultant = c(
      day1_circle$resultant,
      day2_circle$resultant
    )
  )
}

test_p04_core_long_rows <- function(daily) {
  rows <- lapply(seq_len(nrow(daily)), function(index) {
    day <- daily[index, , drop = FALSE]
    common <- day[p04_core_day_key]
    ordinary <- day$valid_medi_real_minutes / day$expected_real_minutes
    primary <- tibble::tibble(
      analysis_unit = "participant_day",
      metric = "longest_bout_above_250",
      value = day$longest_bout_above_250_h,
      units = "h",
      state_domain = "full_day_hybrid",
      estimable = TRUE,
      failure_reason = NA_character_,
      ordinary_support = ordinary,
      relevance_support = day$timing_overall_support,
      valid_minutes = day$valid_medi_real_minutes,
      expected_minutes = day$expected_real_minutes,
      descriptive_nonconfirmatory = FALSE,
      left_censored = FALSE,
      right_censored = FALSE,
      any_censored = day$longest_bout_above_250_censored,
      state_domain_complete = NA,
      medi_profile_support = NA_real_,
      light_profile_support = NA_real_,
      minimum_support = NA_real_,
      passes_ordinary_support = NA,
      passes_medi_profile_support = NA,
      passes_light_profile_support = NA,
      support_threshold_enforced = NA,
      ratio_scaled_or_weighted = NA,
      estimate_interpretation = "observed_lower_bound",
      missing_invalid_breaks_runs = TRUE,
      exact_identifiable = day$longest_bout_above_250_exact_identifiable
    )
    exact <- primary |>
      dplyr::mutate(
        metric = "longest_bout_above_250_exact_only_sensitivity",
        value = day$longest_bout_above_250_exact_only_sensitivity_h,
        estimable = day$longest_bout_above_250_exact_identifiable,
        failure_reason = if (day$longest_bout_above_250_exact_identifiable) {
          NA_character_
        } else {
          "not_exactly_identifiable_due_to_missing_or_invalid_minutes"
        },
        descriptive_nonconfirmatory = TRUE,
        estimate_interpretation = "exact_only_sensitivity"
      )
    timing <- tibble::tibble(
      analysis_unit = "participant_day",
      metric = c(
        "first_timing_above_250",
        "last_timing_above_250",
        "mean_timing_above_250"
      ),
      value = c(
        day$first_timing_above_250_clock_minute,
        day$last_timing_above_250_clock_minute,
        day$mean_timing_above_250_clock_minute
      ),
      units = "clock_minute",
      state_domain = "full_day_hybrid",
      estimable = TRUE,
      failure_reason = NA_character_,
      ordinary_support = ordinary,
      relevance_support = c(
        day$timing_first_support,
        day$timing_last_support,
        day$timing_overall_support
      ),
      valid_minutes = day$valid_medi_real_minutes,
      expected_minutes = day$expected_real_minutes,
      descriptive_nonconfirmatory = FALSE,
      left_censored = c(FALSE, FALSE, FALSE),
      right_censored = c(FALSE, FALSE, FALSE),
      any_censored = FALSE,
      state_domain_complete = NA,
      medi_profile_support = NA_real_,
      light_profile_support = NA_real_,
      minimum_support = NA_real_,
      passes_ordinary_support = NA,
      passes_medi_profile_support = NA,
      passes_light_profile_support = NA,
      support_threshold_enforced = NA,
      ratio_scaled_or_weighted = NA,
      estimate_interpretation = NA_character_,
      missing_invalid_breaks_runs = NA,
      exact_identifiable = NA
    )
    dplyr::bind_rows(primary, exact, timing) |>
      dplyr::mutate(
        !!!common,
        profile_variant = "pooled",
        .before = 1L
      )
  })
  dplyr::bind_rows(rows) |>
    dplyr::arrange(
      .data$site,
      .data$Id,
      .data$position,
      .data$local_date,
      .data$metric
    )
}

test_p04_core_outputs <- function(placement) {
  daily <- test_p04_core_expected_days(placement)
  long <- test_p04_core_long_rows(daily)
  support_columns <- c(
    p04_core_day_key,
    "profile_variant",
    "metric",
    "state_domain",
    "ordinary_support",
    "relevance_support",
    "medi_profile_support",
    "light_profile_support",
    "minimum_support",
    "passes_ordinary_support",
    "passes_medi_profile_support",
    "passes_light_profile_support",
    "support_threshold_enforced",
    "ratio_scaled_or_weighted",
    "valid_minutes",
    "expected_minutes",
    "state_domain_complete",
    "estimable",
    "failure_reason"
  )
  admissibility_columns <- c(
    p04_core_day_key,
    "profile_variant",
    "analysis_unit",
    "metric",
    "state_domain",
    "estimable",
    "failure_reason",
    "descriptive_nonconfirmatory",
    "left_censored",
    "right_censored",
    "any_censored"
  )
  censoring <- daily |>
    dplyr::transmute(
      dplyr::across(dplyr::all_of(p04_core_day_key)),
      .data$profile_variant,
      timing_threshold_observed = TRUE,
      first_timing_left_censored = FALSE,
      last_timing_right_censored = FALSE,
      strict_first_boundary_gap = c(TRUE, FALSE),
      strict_last_boundary_gap = c(FALSE, TRUE),
      timing_circular_resultant = .data$timing_resultant,
      longest_bout_censored = .data$longest_bout_above_250_censored,
      longest_bout_observed_h = .data$longest_bout_above_250_observed_h,
      longest_bout_observed_lower_bound_h = .data$longest_bout_above_250_observed_lower_bound_h,
      longest_bout_possible_h = .data$longest_bout_above_250_possible_h,
      longest_bout_possible_upper_bound_h = .data$longest_bout_above_250_possible_upper_bound_h,
      longest_bout_exact_only_sensitivity_h = .data$longest_bout_above_250_exact_only_sensitivity_h,
      longest_bout_exact_identifiable = .data$longest_bout_above_250_exact_identifiable,
      longest_bout_missing_invalid_breaks_runs = TRUE,
      longest_bout_observed_value_interpretation = "observed_lower_bound",
      longest_bout_possible_bound_interpretation = "upper_bound_if_all_missing_or_invalid_minutes_qualified",
      longest_bout_winning_observed_runs = 1L,
      longest_bout_winner_onset_utc = .data$longest_bout_above_250_onset_utc,
      longest_bout_winner_offset_utc = .data$longest_bout_above_250_offset_utc,
      longest_bout_day_boundary_contact = FALSE,
      longest_bout_censor_reason = .data$longest_bout_above_250_censor_reason,
      m10_tied_windows = 1L,
      m10_tie_resultant = 1,
      l10_tied_windows = 1L,
      l10_tie_resultant = 1,
      structural_nonexistent_wall_minutes = 0L,
      dst_fold_wall_minutes = 0L,
      maximum_true_minutes_per_wall_minute = 1L
    )
  participant <- tibble::tibble(
    site = "SITE",
    Id = "P01",
    position = placement,
    profile_variant = "pooled",
    is = 0.5,
    iv = 0.5
  )
  thirty <- tidyr::crossing(
    daily[p04_core_day_key],
    clock_bin = seq.int(0L, 1410L, 30L)
  ) |>
    dplyr::mutate(metric_value_lx = 100)
  hourly <- tidyr::crossing(
    daily[p04_core_day_key],
    clock_hour = 0:23
  ) |>
    dplyr::mutate(metric_value_lx = 100)
  gap <- daily |>
    dplyr::transmute(
      dplyr::across(dplyr::all_of(p04_core_day_key)),
      expected_real_minutes = .data$expected_real_minutes,
      missing_medi_real_minutes = .data$expected_real_minutes -
        .data$valid_medi_real_minutes
    )
  list(
    daily = dplyr::select(
      daily,
      -dplyr::starts_with("timing_")
    ),
    participant = participant,
    thirty = thirty,
    hourly = hourly,
    long = long,
    support = dplyr::select(long, dplyr::all_of(support_columns)),
    admissibility = dplyr::select(
      long,
      dplyr::all_of(admissibility_columns)
    ),
    censoring = censoring,
    gap = gap
  )
}

test_p04_core_write_placement <- function(
  outputs,
  metric_root,
  placement,
  run_label
) {
  paths <- p04_core_output_paths(metric_root, placement)
  producer <- "scripts/pipeline/build_metric_derivation.R"
  specifications <- list(
    list(
      type = "participant_day_metrics_rds",
      data = outputs$daily,
      path = paths[["participant_day_metrics_rds"]],
      writer = "rds"
    ),
    list(
      type = "participant_day_metrics_csv",
      data = outputs$daily,
      path = paths[["participant_day_metrics_csv"]],
      writer = "csv"
    ),
    list(
      type = "participant_is_iv_rds",
      data = outputs$participant,
      path = paths[["participant_is_iv_rds"]],
      writer = "rds"
    ),
    list(
      type = "participant_is_iv_csv",
      data = outputs$participant,
      path = paths[["participant_is_iv_csv"]],
      writer = "csv"
    ),
    list(
      type = "complete_30_minute_arithmetic_medi_grid_rds",
      data = outputs$thirty,
      path = paths[["complete_30_minute_arithmetic_medi_grid_rds"]],
      writer = "rds"
    ),
    list(
      type = "complete_30_minute_arithmetic_medi_grid_csv",
      data = outputs$thirty,
      path = paths[["complete_30_minute_arithmetic_medi_grid_csv"]],
      writer = "csv"
    ),
    list(
      type = "complete_one_hour_geometric_medi_grid_rds",
      data = outputs$hourly,
      path = paths[["complete_one_hour_geometric_medi_grid_rds"]],
      writer = "rds"
    ),
    list(
      type = "complete_one_hour_geometric_medi_grid_csv",
      data = outputs$hourly,
      path = paths[["complete_one_hour_geometric_medi_grid_csv"]],
      writer = "csv"
    ),
    list(
      type = "long_metric_values",
      data = outputs$long,
      path = paths[["long_metric_values"]],
      writer = "csv"
    ),
    list(
      type = "metric_admissibility",
      data = outputs$admissibility,
      path = paths[["metric_admissibility"]],
      writer = "csv"
    ),
    list(
      type = "metric_support_diagnostics",
      data = outputs$support,
      path = paths[["metric_support_diagnostics"]],
      writer = "csv"
    ),
    list(
      type = "metric_censoring_diagnostics",
      data = outputs$censoring,
      path = paths[["metric_censoring_diagnostics"]],
      writer = "csv"
    ),
    list(
      type = "metric_gap_diagnostics",
      data = outputs$gap,
      path = paths[["metric_gap_diagnostics"]],
      writer = "csv"
    )
  )
  records <- lapply(specifications, function(specification) {
    metadata <- list(
      artifact_type = specification$type,
      run_label = run_label,
      placement = placement,
      profile_variant = "pooled"
    )
    result <- if (identical(specification$writer, "rds")) {
      write_rds_artifact(
        specification$data,
        specification$path,
        producer,
        metadata
      )
    } else {
      write_csv_artifact(
        specification$data,
        specification$path,
        producer,
        metadata
      )
    }
    manifest_row(result)
  })
  list(records = records, paths = paths)
}

test_p04_core_fixture <- function() {
  root <- tempfile("nathealth-p04-core-verifier-")
  dir.create(root, recursive = TRUE)
  paths <- pipeline_paths(root)
  ensure_pipeline_directories(paths)
  run_label <- "smoke"
  metric_root <- file.path(paths$metrics, "runs", run_label)
  coverage_root <- file.path(paths$coverage, "runs", run_label)
  dir.create(metric_root, recursive = TRUE)
  dir.create(coverage_root, recursive = TRUE)
  state <- test_p04_core_state_artifacts(paths, run_label)
  profiles <- test_p04_core_profile_artifacts(paths, run_label)
  producer <- "scripts/pipeline/build_metric_derivation.R"
  records <- list()
  placement_outputs <- list()
  coverage_metadata <- list()

  for (placement in c("chest", "glasses")) {
    coverage <- test_p04_core_coverage(placement)
    coverage_path <- file.path(
      coverage_root,
      paste0("light_", placement, "_coverage.rds")
    )
    saveRDS(coverage, coverage_path, version = 3)
    coverage_metadata[[placement]] <- list(
      path = coverage_path,
      sha256 = artifact_sha256(coverage_path)
    )
    outputs <- test_p04_core_outputs(placement)
    placement_outputs[[placement]] <- test_p04_core_write_placement(
      outputs,
      metric_root,
      placement,
      run_label
    )
    records <- c(records, placement_outputs[[placement]]$records)
  }

  settings <- dplyr::bind_rows(lapply(
    c("chest", "glasses"),
    function(placement) {
      tibble::tibble(
        run_label = run_label,
        placement = placement,
        profile_variant = "pooled",
        coverage_path = coverage_metadata[[placement]]$path,
        coverage_sha256 = coverage_metadata[[placement]]$sha256,
        state_interval_manifest_path = state$manifest_path,
        state_interval_manifest_sha256 = state$manifest_sha256,
        reference_profiles_path = profiles$profile_path,
        reference_profiles_sha256 = profiles$profile_sha256,
        timing_exceedance_distributions_path = profiles$distribution_path,
        timing_exceedance_distributions_sha256 = profiles$distribution_sha256,
        relevance_maps_path = profiles$map_path,
        relevance_maps_sha256 = profiles$map_sha256,
        timing_exceedance_threshold_lx = 250,
        timing_exceedance_comparison = "strict_greater_than",
        timing_exceedance_aggregation = "equal_days_within_participant_then_equal_participants",
        timing_exceedance_application = "support_only_no_value_scaling",
        dose_minimum_relevance_support = 0.80,
        minimum_circular_resultant = 0.10,
        longest_bout_primary = "longest_observed_uninterrupted_above_250_lower_bound",
        longest_bout_missing_rule = "missing_or_invalid_minutes_break_observed_runs",
        longest_bout_possible_bound = "upper_bound_if_all_missing_or_invalid_minutes_qualified",
        longest_bout_exact_only_sensitivity = TRUE,
        eligible_participant_days = 2L,
        participants = 1L
      )
    }
  ))
  state_inputs <- tidyr::crossing(
    placement = c("chest", "glasses"),
    interval_kind = c("sleep", "wear")
  ) |>
    dplyr::mutate(
      run_label = run_label,
      profile_variant = "pooled",
      site = "SITE",
      state_interval_path = ifelse(
        .data$interval_kind == "sleep",
        state$sleep_path,
        state$wear_path
      ),
      state_interval_sha256 = ifelse(
        .data$interval_kind == "sleep",
        state$sleep_sha256,
        state$wear_sha256
      ),
      state_interval_manifest_path = state$manifest_path,
      state_interval_manifest_sha256 = state$manifest_sha256,
      .before = 1L
    )
  candidates <- tibble::tibble(
    position = rep(c("chest", "glasses"), each = 3L),
    metric = "duration_above_250_wake",
    state_domain = "wake",
    candidate_state_support_cutoff = rep(c(0.7, 0.8, 0.9), 2L)
  )
  combined <- list(
    list(
      data = settings,
      path = file.path(metric_root, "metric_derivation_settings.csv"),
      type = "metric_derivation_settings"
    ),
    list(
      data = candidates,
      path = file.path(
        metric_root,
        "state_support_candidate_diagnostics.csv"
      ),
      type = "state_support_candidate_diagnostics"
    ),
    list(
      data = state_inputs,
      path = file.path(metric_root, "metric_state_interval_inputs.csv"),
      type = "metric_state_interval_inputs"
    )
  )
  for (specification in combined) {
    records[[length(records) + 1L]] <- manifest_row(write_csv_artifact(
      specification$data,
      specification$path,
      producer,
      metadata = list(
        artifact_type = specification$type,
        run_label = run_label
      )
    ))
  }
  manifest <- dplyr::bind_rows(records) |>
    dplyr::arrange(.data$artifact_type, .data$path)
  manifest_path <- file.path(
    paths$manifests,
    paste0("metric_artifacts_", run_label, ".csv")
  )
  readr::write_csv(manifest, manifest_path, na = "")
  list(
    root = root,
    run_label = run_label,
    metric_root = metric_root,
    coverage_root = coverage_root,
    profile_root = profiles$root,
    state_manifest_path = state$manifest_path,
    metric_manifest_path = manifest_path,
    map_path = profiles$map_path,
    settings_path = file.path(
      metric_root,
      "metric_derivation_settings.csv"
    ),
    placement_outputs = placement_outputs
  )
}

test_p04_core_verify_fixture <- function(fixture) {
  verify_metric_derivation_core(
    root = fixture$root,
    run_label = fixture$run_label,
    metric_run_root = fixture$metric_root,
    metric_manifest_path = fixture$metric_manifest_path,
    coverage_run_root = fixture$coverage_root,
    profile_run_root = fixture$profile_root,
    state_interval_manifest_path = fixture$state_manifest_path,
    sample_days_per_placement = Inf
  )
}

test_p04_core_refresh_manifest <- function(
  manifest_path,
  changed_paths
) {
  manifest <- p04_core_read_csv(manifest_path)
  for (path in changed_paths) {
    index <- match(
      normalizePath(path, winslash = "/", mustWork = TRUE),
      normalizePath(
        manifest$path,
        winslash = "/",
        mustWork = TRUE
      )
    )
    stopifnot(!is.na(index))
    manifest$sha256[[index]] <- artifact_sha256(path)
    manifest$bytes[[index]] <- unname(file.info(path)$size)
    if (grepl("[.]csv$", path)) {
      data <- p04_core_read_csv(path)
      manifest$rows[[index]] <- nrow(data)
      manifest$columns[[index]] <- ncol(data)
    }
  }
  readr::write_csv(manifest, manifest_path, na = "")
  invisible(manifest_path)
}

fixture <- test_p04_core_fixture()
verified <- test_p04_core_verify_fixture(fixture)
stopifnot(
  identical(verified$status, "PASS"),
  verified$manifest_artifacts == 29L,
  nrow(verified$dimensions) == 2L,
  all(verified$dimensions$participant_days == 2L),
  nrow(verified$sampled_reconstruction) == 4L,
  any(!verified$sampled_reconstruction$reconstructed_longest_exact),
  all(verified$sampled_reconstruction$reconstructed_threshold_observed)
)

hash_fixture <- test_p04_core_fixture()
hash_path <- hash_fixture$placement_outputs$glasses$paths[
  "metric_gap_diagnostics"
]
hash_data <- p04_core_read_csv(hash_path)
hash_data$missing_medi_real_minutes[[1L]] <- 999L
readr::write_csv(hash_data, hash_path, na = "")
test_p04_core_expect_error(
  test_p04_core_verify_fixture(hash_fixture),
  "Manifest hash mismatch"
)

longest_fixture <- test_p04_core_fixture()
longest_paths <- longest_fixture$placement_outputs$glasses$paths
longest_rds <- readRDS(longest_paths[["participant_day_metrics_rds"]])
longest_rds$longest_bout_above_250_h[[1L]] <-
  longest_rds$longest_bout_above_250_h[[1L]] + 1
saveRDS(
  longest_rds,
  longest_paths[["participant_day_metrics_rds"]],
  version = 3,
  compress = "xz"
)
readr::write_csv(
  longest_rds,
  longest_paths[["participant_day_metrics_csv"]],
  na = ""
)
test_p04_core_refresh_manifest(
  longest_fixture$metric_manifest_path,
  c(
    longest_paths[["participant_day_metrics_rds"]],
    longest_paths[["participant_day_metrics_csv"]]
  )
)
test_p04_core_expect_error(
  test_p04_core_verify_fixture(longest_fixture),
  "longest-bout"
)

map_fixture <- test_p04_core_fixture()
maps <- readRDS(map_fixture$map_path)
maps$relevance_mass[[1L]] <- maps$relevance_mass[[1L]] + 0.25
saveRDS(maps, map_fixture$map_path, version = 3)
settings <- p04_core_read_csv(map_fixture$settings_path)
settings$relevance_maps_sha256 <- artifact_sha256(map_fixture$map_path)
readr::write_csv(settings, map_fixture$settings_path, na = "")
test_p04_core_refresh_manifest(
  map_fixture$metric_manifest_path,
  map_fixture$settings_path
)
test_p04_core_expect_error(
  test_p04_core_verify_fixture(map_fixture),
  "Timing map values disagree"
)

cat("Preparation 04 core artifact verifier checks passed.\n")
