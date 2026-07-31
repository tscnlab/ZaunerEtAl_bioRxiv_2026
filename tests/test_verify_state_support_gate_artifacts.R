source("scripts/pipeline/paths_io.R")
source("scripts/pipeline/assertions.R")
source("scripts/pipeline/verify_state_support_gate_artifacts.R")

options(warn = 2)

test_state_gate_interval <- function(
  starts,
  ends,
  states,
  interval_kind,
  site = "TEST",
  id = "TEST_P01",
  timezone = "UTC"
) {
  if (identical(interval_kind, "sleep")) {
    output <- tibble::tibble(
      site = site,
      Id = id,
      timezone = timezone,
      interval_kind = interval_kind,
      interval_bounds = "[)",
      start = as.POSIXct(starts, tz = "UTC"),
      end = as.POSIXct(ends, tz = "UTC"),
      sleep = ifelse(states == "sleep", "sleepprep", "wake"),
      State.Brown = states
    )
  } else {
    output <- tibble::tibble(
      site = site,
      Id = id,
      timezone = timezone,
      interval_kind = interval_kind,
      interval_bounds = "[)",
      start = as.POSIXct(starts, tz = "UTC"),
      end = as.POSIXct(ends, tz = "UTC"),
      wear = states
    )
  }
  attr(output, "state_interval_provenance") <- list(
    site = site,
    timezone = timezone,
    interval_kind = interval_kind,
    bounds = "[)"
  )
  output
}

test_state_gate_coverage <- function() {
  dates <- as.Date("2026-01-01") + 0:2
  rows <- lapply(seq_along(dates), function(day_number) {
    date <- dates[[day_number]]
    clock_minute <- 0:1439
    datetime_utc <- as.POSIXct(
      paste(format(date), "00:00:00"),
      tz = "UTC"
    ) +
      clock_minute * 60
    state <- if (day_number == 1L) {
      ifelse(
        clock_minute < 360L,
        "sleep",
        ifelse(clock_minute < 1320L, "wake", "pre-sleep")
      )
    } else if (day_number == 2L) {
      ifelse(clock_minute < 360L, "sleep", "wake")
    } else {
      ifelse(
        clock_minute < 360L,
        "sleep",
        ifelse(clock_minute < 1380L, "wake", NA_character_)
      )
    }
    wear <- ifelse(
      day_number == 1L &
        clock_minute >= 720L &
        clock_minute < 730L,
      "off",
      NA_character_
    )
    invalid_nonwear <- !is.na(wear) &
      wear == "off" &
      (is.na(state) | state != "sleep")
    medi <- rep(NA_real_, length(clock_minute))
    if (day_number == 1L) {
      required_valid <- c(
        sleep = 324L,
        wake = 672L,
        `pre-sleep` = 96L
      )
      for (domain in names(required_valid)) {
        available <- which(
          !is.na(state) &
            state == domain &
            !invalid_nonwear
        )
        medi[utils::head(
          available,
          required_valid[[domain]]
        )] <- 10
      }
    } else {
      medi[!is.na(state) & !invalid_nonwear] <- 10
    }
    tibble::tibble(
      site = "TEST",
      Id = "TEST_P01",
      position = "glasses",
      datetime_utc = datetime_utc,
      timezone = "UTC",
      local_date = date,
      State.Brown = state,
      wear = wear,
      invalid_nonwear = invalid_nonwear,
      MEDI_eligible = medi,
      day_eligible = TRUE
    )
  })
  dplyr::bind_rows(rows)
}

test_state_gate_daily <- function() {
  dates <- as.Date("2026-01-01") + 0:2
  tibble::tribble(
    ~local_date,
    ~metric,
    ~state_domain,
    ~ordinary_support,
    ~valid_minutes,
    ~expected_minutes,
    ~unknown_diary_state_minutes,
    ~state_domain_complete,
    ~failure_reason,
    dates[[1L]],
    "duration_above_250_wake",
    "wake",
    0.70,
    672L,
    960L,
    0L,
    TRUE,
    NA_character_,
    dates[[1L]],
    "duration_below_10_pre_sleep",
    "pre-sleep",
    0.80,
    96L,
    120L,
    0L,
    TRUE,
    NA_character_,
    dates[[1L]],
    "duration_below_1_sleep_environment",
    "sleep",
    0.90,
    324L,
    360L,
    0L,
    TRUE,
    NA_character_,
    dates[[2L]],
    "duration_above_250_wake",
    "wake",
    1,
    1080L,
    1080L,
    0L,
    TRUE,
    NA_character_,
    dates[[2L]],
    "duration_below_10_pre_sleep",
    "pre-sleep",
    NA_real_,
    0L,
    0L,
    0L,
    TRUE,
    "no_state_window",
    dates[[2L]],
    "duration_below_1_sleep_environment",
    "sleep",
    1,
    360L,
    360L,
    0L,
    TRUE,
    NA_character_,
    dates[[3L]],
    "duration_above_250_wake",
    "wake",
    1,
    1020L,
    1020L,
    60L,
    FALSE,
    "incomplete_state_domain",
    dates[[3L]],
    "duration_below_10_pre_sleep",
    "pre-sleep",
    NA_real_,
    0L,
    0L,
    60L,
    FALSE,
    "incomplete_state_domain",
    dates[[3L]],
    "duration_below_1_sleep_environment",
    "sleep",
    1,
    360L,
    360L,
    60L,
    FALSE,
    "incomplete_state_domain"
  ) |>
    dplyr::mutate(
      site = "TEST",
      Id = "TEST_P01",
      position = "glasses",
      .before = 1
    ) |>
    dplyr::arrange(
      .data$site,
      .data$Id,
      .data$position,
      .data$local_date,
      .data$metric
    )
}

test_state_gate_candidate_tables <- function(daily) {
  classified <- tidyr::crossing(
    daily,
    candidate_state_support_cutoff = c(0.70, 0.80, 0.90)
  ) |>
    dplyr::mutate(
      has_state_window = .data$state_domain_complete &
        .data$expected_minutes > 0L,
      retained_at_candidate = .data$has_state_window &
        .data$ordinary_support >= .data$candidate_state_support_cutoff,
      metric_na_at_candidate = !.data$retained_at_candidate,
      no_state_window = .data$state_domain_complete &
        !.data$has_state_window,
      incomplete_state_domain = !.data$state_domain_complete,
      insufficient_state_support = .data$has_state_window &
        .data$ordinary_support < .data$candidate_state_support_cutoff
    )
  finite_quantile <- function(value, probability) {
    finite <- is.finite(value)
    if (!any(finite)) {
      return(NA_real_)
    }
    as.numeric(stats::quantile(
      value[finite],
      probs = probability,
      names = FALSE,
      type = 7
    ))
  }
  overall <- classified |>
    dplyr::group_by(
      .data$position,
      .data$metric,
      .data$state_domain,
      .data$candidate_state_support_cutoff
    ) |>
    dplyr::summarise(
      eligible_participant_days = dplyr::n(),
      eligible_participants = dplyr::n_distinct(.data$site, .data$Id),
      eligible_sites = dplyr::n_distinct(.data$site),
      participant_days_with_state_window = sum(.data$has_state_window),
      participants_with_state_window = dplyr::n_distinct(
        .data$site[.data$has_state_window],
        .data$Id[.data$has_state_window]
      ),
      retained_metric_instances = sum(.data$retained_at_candidate),
      retained_participants = dplyr::n_distinct(
        .data$site[.data$retained_at_candidate],
        .data$Id[.data$retained_at_candidate]
      ),
      sites_with_retained_metric = dplyr::n_distinct(
        .data$site[.data$retained_at_candidate]
      ),
      metric_na_instances = sum(.data$metric_na_at_candidate),
      no_state_window_instances = sum(.data$no_state_window),
      incomplete_state_domain_instances = sum(
        .data$incomplete_state_domain
      ),
      insufficient_state_support_instances = sum(
        .data$insufficient_state_support
      ),
      ordinary_support_q10 = finite_quantile(
        .data$ordinary_support[.data$has_state_window],
        0.10
      ),
      ordinary_support_q25 = finite_quantile(
        .data$ordinary_support[.data$has_state_window],
        0.25
      ),
      ordinary_support_median = finite_quantile(
        .data$ordinary_support[.data$has_state_window],
        0.50
      ),
      ordinary_support_q75 = finite_quantile(
        .data$ordinary_support[.data$has_state_window],
        0.75
      ),
      ordinary_support_q90 = finite_quantile(
        .data$ordinary_support[.data$has_state_window],
        0.90
      ),
      .groups = "drop"
    ) |>
    dplyr::group_by(
      .data$position,
      .data$metric,
      .data$state_domain
    ) |>
    dplyr::arrange(
      .data$candidate_state_support_cutoff,
      .by_group = TRUE
    ) |>
    dplyr::mutate(
      retained_fraction = .data$retained_metric_instances /
        .data$eligible_participant_days,
      marginal_metric_instance_loss_from_lower = dplyr::lag(
        .data$retained_metric_instances
      ) -
        .data$retained_metric_instances,
      marginal_participant_loss_from_lower = dplyr::lag(
        .data$retained_participants
      ) -
        .data$retained_participants,
      classification_total = .data$retained_metric_instances +
        .data$no_state_window_instances +
        .data$incomplete_state_domain_instances +
        .data$insufficient_state_support_instances,
      status = "diagnostic_only_not_final",
      selection_rule = "candidate_cutoffs_fixed_without_result_preference"
    ) |>
    dplyr::ungroup() |>
    dplyr::arrange(
      .data$position,
      .data$metric,
      .data$candidate_state_support_cutoff
    )
  by_site <- classified |>
    dplyr::group_by(
      .data$position,
      .data$site,
      .data$metric,
      .data$state_domain,
      .data$candidate_state_support_cutoff
    ) |>
    dplyr::summarise(
      eligible_participant_days = dplyr::n(),
      eligible_participants = dplyr::n_distinct(.data$Id),
      participant_days_with_state_window = sum(.data$has_state_window),
      retained_metric_instances = sum(.data$retained_at_candidate),
      retained_participants = dplyr::n_distinct(
        .data$Id[.data$retained_at_candidate]
      ),
      no_state_window_instances = sum(.data$no_state_window),
      incomplete_state_domain_instances = sum(
        .data$incomplete_state_domain
      ),
      insufficient_state_support_instances = sum(
        .data$insufficient_state_support
      ),
      ordinary_support_q25 = finite_quantile(
        .data$ordinary_support[.data$has_state_window],
        0.25
      ),
      ordinary_support_median = finite_quantile(
        .data$ordinary_support[.data$has_state_window],
        0.50
      ),
      ordinary_support_q75 = finite_quantile(
        .data$ordinary_support[.data$has_state_window],
        0.75
      ),
      .groups = "drop"
    ) |>
    dplyr::group_by(
      .data$position,
      .data$site,
      .data$metric,
      .data$state_domain
    ) |>
    dplyr::arrange(
      .data$candidate_state_support_cutoff,
      .by_group = TRUE
    ) |>
    dplyr::mutate(
      retained_fraction = .data$retained_metric_instances /
        .data$eligible_participant_days,
      marginal_metric_instance_loss_from_lower = dplyr::lag(
        .data$retained_metric_instances
      ) -
        .data$retained_metric_instances,
      classification_total = .data$retained_metric_instances +
        .data$no_state_window_instances +
        .data$incomplete_state_domain_instances +
        .data$insufficient_state_support_instances,
      status = "diagnostic_only_not_final",
      selection_rule = "candidate_cutoffs_fixed_without_result_preference"
    ) |>
    dplyr::ungroup() |>
    dplyr::arrange(
      .data$position,
      .data$site,
      .data$metric,
      .data$candidate_state_support_cutoff
    )
  list(overall = overall, by_site = by_site)
}

test_state_gate_refresh_manifest <- function(root, run_label = "smoke") {
  paths <- pipeline_paths(root)
  manifest_path <- file.path(
    paths$manifests,
    paste0("state_support_gate_artifacts_", run_label, ".csv")
  )
  manifest <- readr::read_csv(
    manifest_path,
    show_col_types = FALSE,
    progress = FALSE
  )
  for (index in seq_len(nrow(manifest))) {
    artifact <- readr::read_csv(
      manifest$path[[index]],
      show_col_types = FALSE,
      progress = FALSE
    )
    manifest$sha256[[index]] <- artifact_sha256(
      manifest$path[[index]]
    )
    manifest$bytes[[index]] <- file.info(
      manifest$path[[index]]
    )$size
    manifest$rows[[index]] <- nrow(artifact)
    manifest$columns[[index]] <- ncol(artifact)
  }
  readr::write_csv(manifest, manifest_path, na = "")
  invisible(manifest_path)
}

test_state_gate_fixture <- function() {
  root <- tempfile("nathealth-state-support-verifier-")
  dir.create(root, recursive = TRUE)
  paths <- pipeline_paths(root)
  ensure_pipeline_directories(paths)
  run_label <- "smoke"
  coverage_root <- file.path(paths$coverage, "runs", run_label)
  interval_root <- file.path(
    paths$aligned,
    "runs",
    run_label,
    "state_intervals"
  )
  metric_root <- file.path(paths$metrics, "runs", run_label)
  dir.create(coverage_root, recursive = TRUE)
  dir.create(interval_root, recursive = TRUE)
  dir.create(metric_root, recursive = TRUE)

  coverage <- test_state_gate_coverage()
  coverage_path <- file.path(
    coverage_root,
    "light_glasses_coverage.rds"
  )
  saveRDS(coverage, coverage_path, version = 3, compress = "xz")
  coverage_settings_path <- file.path(
    coverage_root,
    "coverage_settings.csv"
  )
  readr::write_csv(
    tibble::tibble(
      run_label = run_label,
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

  sleep <- test_state_gate_interval(
    starts = c(
      "2026-01-01 00:00:00",
      "2026-01-01 06:00:00",
      "2026-01-01 22:00:00",
      "2026-01-02 00:00:00",
      "2026-01-02 06:00:00",
      "2026-01-03 00:00:00",
      "2026-01-03 06:00:00"
    ),
    ends = c(
      "2026-01-01 06:00:00",
      "2026-01-01 22:00:00",
      "2026-01-02 00:00:00",
      "2026-01-02 06:00:00",
      "2026-01-03 00:00:00",
      "2026-01-03 06:00:00",
      "2026-01-03 23:00:00"
    ),
    states = c(
      "sleep",
      "wake",
      "pre-sleep",
      "sleep",
      "wake",
      "sleep",
      "wake"
    ),
    interval_kind = "sleep"
  )
  wear <- test_state_gate_interval(
    starts = "2026-01-01 12:00:00",
    ends = "2026-01-01 12:10:00",
    states = "off",
    interval_kind = "wear"
  )
  sleep_path <- file.path(
    interval_root,
    "TEST_sleep_intervals.rds"
  )
  wear_path <- file.path(
    interval_root,
    "TEST_wear_intervals.rds"
  )
  saveRDS(sleep, sleep_path, version = 3, compress = "xz")
  saveRDS(wear, wear_path, version = 3, compress = "xz")
  interval_manifest_path <- file.path(
    paths$manifests,
    "state_interval_artifacts_smoke.csv"
  )
  interval_manifest <- tibble::tibble(
    path = normalizePath(
      c(sleep_path, wear_path),
      winslash = "/",
      mustWork = TRUE
    ),
    sha256 = vapply(
      c(sleep_path, wear_path),
      artifact_sha256,
      character(1)
    ),
    bytes = unname(file.info(c(sleep_path, wear_path))$size),
    artifact_type = c(
      "site_sleep_state_intervals",
      "site_wear_state_intervals"
    ),
    run_label = run_label,
    site = "TEST",
    interval_kind = c("sleep", "wear"),
    interval_bounds = "[)"
  )
  readr::write_csv(interval_manifest, interval_manifest_path)

  daily <- test_state_gate_daily()
  summaries <- test_state_gate_candidate_tables(daily)
  normalized_interval_manifest_path <- normalizePath(
    interval_manifest_path,
    winslash = "/",
    mustWork = TRUE
  )
  interval_manifest_sha256 <- artifact_sha256(
    interval_manifest_path
  )
  normalized_coverage_path <- normalizePath(
    coverage_path,
    winslash = "/",
    mustWork = TRUE
  )
  coverage_sha256 <- artifact_sha256(coverage_path)
  normalized_coverage_settings_path <- normalizePath(
    coverage_settings_path,
    winslash = "/",
    mustWork = TRUE
  )
  coverage_settings_sha256 <- artifact_sha256(
    coverage_settings_path
  )
  input_rows <- tibble::tibble(
    run_label = run_label,
    profile_variant = "pooled",
    placement = "glasses",
    site = "TEST",
    interval_kind = c("sleep", "wear"),
    state_interval_path = normalizePath(
      c(sleep_path, wear_path),
      winslash = "/",
      mustWork = TRUE
    ),
    state_interval_sha256 = interval_manifest$sha256,
    state_interval_manifest_path = normalized_interval_manifest_path,
    state_interval_manifest_sha256 = interval_manifest_sha256,
    coverage_path = normalized_coverage_path,
    coverage_sha256 = coverage_sha256,
    coverage_settings_path = normalized_coverage_settings_path,
    coverage_settings_sha256 = coverage_settings_sha256,
    verified_minimum_hour_coverage = 0.50,
    verified_minimum_day_coverage = 0.80,
    candidate_cutoffs = "0.7|0.8|0.9",
    status = "AUTHOR_GATE_INPUT_NOT_A_SELECTED_RULE"
  )
  producer <- "scripts/pipeline/build_metric_derivation.R"
  daily_path <- file.path(
    metric_root,
    "state_support_gate_daily.csv"
  )
  overall_path <- file.path(
    metric_root,
    "state_support_candidate_diagnostics.csv"
  )
  by_site_path <- file.path(
    metric_root,
    "state_support_candidate_by_site.csv"
  )
  inputs_path <- file.path(
    metric_root,
    "state_support_gate_inputs.csv"
  )
  manifest <- dplyr::bind_rows(
    manifest_row(write_csv_artifact(
      daily,
      daily_path,
      producer,
      metadata = list(
        artifact_type = "state_support_gate_daily",
        run_label = run_label,
        profile_variant = "pooled",
        status = "author_gate_input"
      )
    )),
    manifest_row(write_csv_artifact(
      summaries$overall,
      overall_path,
      producer,
      metadata = list(
        artifact_type = "state_support_candidate_diagnostics",
        run_label = run_label,
        profile_variant = "pooled",
        status = "diagnostic_only_not_final"
      )
    )),
    manifest_row(write_csv_artifact(
      summaries$by_site,
      by_site_path,
      producer,
      metadata = list(
        artifact_type = "state_support_candidate_by_site",
        run_label = run_label,
        profile_variant = "pooled",
        status = "diagnostic_only_not_final"
      )
    )),
    manifest_row(write_csv_artifact(
      input_rows,
      inputs_path,
      producer,
      metadata = list(
        artifact_type = "state_support_gate_inputs",
        run_label = run_label,
        profile_variant = "pooled",
        status = "author_gate_input"
      )
    ))
  ) |>
    dplyr::arrange(.data$artifact_type, .data$path)
  manifest_path <- file.path(
    paths$manifests,
    "state_support_gate_artifacts_smoke.csv"
  )
  readr::write_csv(manifest, manifest_path, na = "")
  list(
    root = root,
    run_label = run_label,
    metric_root = metric_root,
    manifest_path = manifest_path,
    daily_path = daily_path,
    overall_path = overall_path,
    by_site_path = by_site_path,
    inputs_path = inputs_path
  )
}

test_state_gate_expect_error <- function(expression, pattern) {
  error <- tryCatch(
    {
      force(expression)
      NULL
    },
    error = identity
  )
  stopifnot(
    inherits(error, "error"),
    grepl(pattern, conditionMessage(error), ignore.case = TRUE)
  )
  invisible(error)
}

message("Verifying a valid independently assembled state-support gate")
valid_fixture <- test_state_gate_fixture()
on.exit(unlink(valid_fixture$root, recursive = TRUE), add = TRUE)
verified <- verify_state_support_gate_artifacts(
  root = valid_fixture$root,
  run_label = valid_fixture$run_label
)
stopifnot(
  identical(verified$status, "PASS"),
  identical(verified$daily_rows, 9L),
  identical(verified$overall_candidate_rows, 9L),
  identical(verified$site_candidate_rows, 9L),
  identical(verified$cutoffs, c(0.70, 0.80, 0.90)),
  identical(verified$l5_present, FALSE),
  identical(verified$immutable_inputs, TRUE)
)

message("Rejecting an altered cutoff registry after rehashing")
cutoff_fixture <- test_state_gate_fixture()
on.exit(unlink(cutoff_fixture$root, recursive = TRUE), add = TRUE)
cutoff_inputs <- readr::read_csv(
  cutoff_fixture$inputs_path,
  show_col_types = FALSE,
  progress = FALSE,
  col_types = readr::cols(candidate_cutoffs = readr::col_character())
)
cutoff_inputs$candidate_cutoffs <- "0.75|0.8|0.9"
readr::write_csv(cutoff_inputs, cutoff_fixture$inputs_path, na = "")
test_state_gate_refresh_manifest(cutoff_fixture$root)
test_state_gate_expect_error(
  verify_state_support_gate_artifacts(
    root = cutoff_fixture$root,
    run_label = cutoff_fixture$run_label
  ),
  "cutoff registry"
)

message("Rejecting altered completeness after rehashing")
completeness_fixture <- test_state_gate_fixture()
on.exit(
  unlink(completeness_fixture$root, recursive = TRUE),
  add = TRUE
)
completeness_daily <- readr::read_csv(
  completeness_fixture$daily_path,
  show_col_types = FALSE,
  progress = FALSE,
  col_types = readr::cols(
    local_date = readr::col_date(),
    failure_reason = readr::col_character()
  )
)
changed_day <- completeness_daily$local_date == as.Date("2026-01-01")
completeness_daily$unknown_diary_state_minutes[changed_day] <- 1L
completeness_daily$state_domain_complete[changed_day] <- FALSE
completeness_daily$failure_reason[changed_day] <-
  "incomplete_state_domain"
readr::write_csv(
  completeness_daily,
  completeness_fixture$daily_path,
  na = ""
)
test_state_gate_refresh_manifest(completeness_fixture$root)
test_state_gate_expect_error(
  verify_state_support_gate_artifacts(
    root = completeness_fixture$root,
    run_label = completeness_fixture$run_label
  ),
  "daily artifact disagrees"
)

message("Rejecting altered summary counts after rehashing")
count_fixture <- test_state_gate_fixture()
on.exit(unlink(count_fixture$root, recursive = TRUE), add = TRUE)
count_overall <- readr::read_csv(
  count_fixture$overall_path,
  show_col_types = FALSE,
  progress = FALSE
)
count_overall$retained_metric_instances[[1L]] <-
  count_overall$retained_metric_instances[[1L]] + 1L
readr::write_csv(count_overall, count_fixture$overall_path, na = "")
test_state_gate_refresh_manifest(count_fixture$root)
test_state_gate_expect_error(
  verify_state_support_gate_artifacts(
    root = count_fixture$root,
    run_label = count_fixture$run_label
  ),
  "overall state-support candidate diagnostics disagrees"
)

message("Rejecting an unmanifested byte-level artifact change")
hash_fixture <- test_state_gate_fixture()
on.exit(unlink(hash_fixture$root, recursive = TRUE), add = TRUE)
write("", file = hash_fixture$daily_path, append = TRUE)
test_state_gate_expect_error(
  verify_state_support_gate_artifacts(
    root = hash_fixture$root,
    run_label = hash_fixture$run_label
  ),
  "manifest path/hash/bytes/rows/columns disagree"
)

message(
  "State-support gate verifier tests PASS, including all corruption checks"
)
