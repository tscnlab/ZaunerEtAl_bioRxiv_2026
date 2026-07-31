# Independently verify the cutoff-neutral state-support author-gate artifacts.
#
# Source paths_io.R and assertions.R before calling
# verify_state_support_gate_artifacts(). This verifier does not source the
# metric builder or its state-support diagnostic functions.

state_gate_verifier_cutoffs <- c(0.70, 0.80, 0.90)

state_gate_verifier_metrics <- c(
  duration_above_250_wake = "wake",
  duration_below_10_pre_sleep = "pre-sleep",
  duration_below_1_sleep_environment = "sleep"
)

state_gate_verifier_run_label <- function(run_label = "full") {
  if (
    !is.character(run_label) ||
      length(run_label) != 1L ||
      is.na(run_label) ||
      !nzchar(trimws(run_label)) ||
      !grepl("^[A-Za-z0-9._-]+$", trimws(run_label))
  ) {
    abort_pipeline("`run_label` must be one safe non-empty label")
  }
  trimws(run_label)
}

state_gate_verifier_optional_path <- function(
  path,
  default,
  must_work = TRUE
) {
  selected <- if (is.null(path)) default else path
  if (
    !is.character(selected) ||
      length(selected) != 1L ||
      is.na(selected) ||
      !nzchar(trimws(selected))
  ) {
    abort_pipeline("Verifier paths must be one non-empty character value")
  }
  normalizePath(
    trimws(selected),
    winslash = "/",
    mustWork = must_work
  )
}

state_gate_verifier_layout <- function(
  root,
  run_label = "full",
  coverage_run_root = NULL,
  state_interval_run_root = NULL,
  state_interval_manifest_path = NULL,
  metric_run_root = NULL,
  manifest_path = NULL
) {
  root <- normalizePath(root, winslash = "/", mustWork = TRUE)
  run_label <- state_gate_verifier_run_label(run_label)
  paths <- pipeline_paths(root)
  suffix <- if (identical(run_label, "full")) {
    ""
  } else {
    paste0("_", run_label)
  }
  coverage_default <- if (identical(run_label, "full")) {
    paths$coverage
  } else {
    file.path(paths$coverage, "runs", run_label)
  }
  interval_default <- if (identical(run_label, "full")) {
    file.path(paths$aligned, "state_intervals")
  } else {
    file.path(paths$aligned, "runs", run_label, "state_intervals")
  }
  metric_default <- if (identical(run_label, "full")) {
    paths$metrics
  } else {
    file.path(paths$metrics, "runs", run_label)
  }
  state_manifest_default <- file.path(
    paths$manifests,
    paste0("state_interval_artifacts", suffix, ".csv")
  )
  manifest_default <- file.path(
    paths$manifests,
    paste0("state_support_gate_artifacts", suffix, ".csv")
  )
  list(
    root = root,
    run_label = run_label,
    paths = paths,
    coverage_run_root = state_gate_verifier_optional_path(
      coverage_run_root,
      coverage_default
    ),
    state_interval_run_root = state_gate_verifier_optional_path(
      state_interval_run_root,
      interval_default
    ),
    state_interval_manifest_path = state_gate_verifier_optional_path(
      state_interval_manifest_path,
      state_manifest_default
    ),
    metric_run_root = state_gate_verifier_optional_path(
      metric_run_root,
      metric_default
    ),
    manifest_path = state_gate_verifier_optional_path(
      manifest_path,
      manifest_default
    )
  )
}

state_gate_verifier_output_paths <- function(metric_run_root) {
  c(
    state_support_gate_daily = file.path(
      metric_run_root,
      "state_support_gate_daily.csv"
    ),
    state_support_candidate_diagnostics = file.path(
      metric_run_root,
      "state_support_candidate_diagnostics.csv"
    ),
    state_support_candidate_by_site = file.path(
      metric_run_root,
      "state_support_candidate_by_site.csv"
    ),
    state_support_gate_inputs = file.path(
      metric_run_root,
      "state_support_gate_inputs.csv"
    )
  )
}

state_gate_verifier_values_equal <- function(
  observed,
  expected,
  tolerance = 1e-12
) {
  if (
    length(observed) != length(expected) ||
      !identical(is.na(observed), is.na(expected))
  ) {
    return(FALSE)
  }
  available <- !is.na(observed)
  if (!any(available)) {
    return(TRUE)
  }
  if (
    inherits(observed, "POSIXt") ||
      inherits(expected, "POSIXt") ||
      inherits(observed, "Date") ||
      inherits(expected, "Date")
  ) {
    return(isTRUE(all.equal(
      as.numeric(observed[available]),
      as.numeric(expected[available]),
      tolerance = tolerance,
      check.attributes = FALSE
    )))
  }
  if (is.numeric(observed) && is.numeric(expected)) {
    return(isTRUE(all.equal(
      as.numeric(observed[available]),
      as.numeric(expected[available]),
      tolerance = tolerance,
      check.attributes = FALSE
    )))
  }
  identical(
    as.character(observed[available]),
    as.character(expected[available])
  )
}

state_gate_verifier_assert_table <- function(
  observed,
  expected,
  key,
  object,
  tolerance = 1e-12
) {
  if (!identical(names(observed), names(expected))) {
    abort_pipeline(
      "%s schema differs from the independent reconstruction; observed: %s; expected: %s",
      object,
      paste(names(observed), collapse = "|"),
      paste(names(expected), collapse = "|")
    )
  }
  assert_unique_key(observed, key, object = object)
  assert_unique_key(
    expected,
    key,
    object = paste0("independently reconstructed ", object)
  )
  observed <- dplyr::arrange(
    observed,
    dplyr::across(dplyr::all_of(key))
  )
  expected <- dplyr::arrange(
    expected,
    dplyr::across(dplyr::all_of(key))
  )
  if (nrow(observed) != nrow(expected)) {
    abort_pipeline(
      "%s has %d rows; independently expected %d",
      object,
      nrow(observed),
      nrow(expected)
    )
  }
  for (column in names(expected)) {
    if (
      !state_gate_verifier_values_equal(
        observed[[column]],
        expected[[column]],
        tolerance = tolerance
      )
    ) {
      abort_pipeline(
        "%s disagrees with the independent reconstruction in `%s`",
        object,
        column
      )
    }
  }
  invisible(TRUE)
}

state_gate_verifier_assert_manifest <- function(
  manifest,
  layout,
  output_paths
) {
  required <- c(
    "path",
    "sha256",
    "bytes",
    "rows",
    "columns",
    "producer",
    "r_version",
    "written_utc",
    "artifact_type",
    "run_label",
    "profile_variant",
    "status"
  )
  if (!identical(names(manifest), required)) {
    abort_pipeline(
      "State-support gate manifest has an unexpected schema: %s",
      paste(names(manifest), collapse = "|")
    )
  }
  if (nrow(manifest) != length(output_paths)) {
    abort_pipeline(
      "State-support gate manifest has %d rows; expected exactly %d",
      nrow(manifest),
      length(output_paths)
    )
  }
  assert_unique_key(
    manifest,
    c("path", "artifact_type"),
    object = "state-support gate manifest"
  )
  normalized_manifest_paths <- vapply(
    manifest$path,
    normalizePath,
    character(1),
    winslash = "/",
    mustWork = TRUE
  )
  normalized_output_paths <- vapply(
    output_paths,
    normalizePath,
    character(1),
    winslash = "/",
    mustWork = TRUE
  )
  if (!setequal(normalized_manifest_paths, unname(normalized_output_paths))) {
    abort_pipeline(
      "State-support gate manifest does not identify the exact canonical output paths"
    )
  }
  if (
    anyNA(manifest[c(
      "path",
      "sha256",
      "bytes",
      "rows",
      "columns",
      "producer",
      "r_version",
      "written_utc",
      "artifact_type",
      "run_label",
      "profile_variant",
      "status"
    )]) ||
      any(!grepl("^[0-9a-f]{64}$", manifest$sha256)) ||
      any(manifest$run_label != layout$run_label) ||
      any(manifest$profile_variant != "pooled") ||
      any(manifest$producer != "scripts/pipeline/build_metric_derivation.R")
  ) {
    abort_pipeline("State-support gate manifest metadata is inconsistent")
  }
  expected_status <- c(
    state_support_gate_daily = "author_gate_input",
    state_support_candidate_diagnostics = "diagnostic_only_not_final",
    state_support_candidate_by_site = "diagnostic_only_not_final",
    state_support_gate_inputs = "author_gate_input"
  )
  manifest_by_type <- manifest[
    match(names(output_paths), manifest$artifact_type),
    ,
    drop = FALSE
  ]
  if (
    anyNA(manifest_by_type$artifact_type) ||
      !identical(
        as.character(manifest_by_type$status),
        unname(expected_status[names(output_paths)])
      )
  ) {
    abort_pipeline(
      "State-support gate manifest has incorrect artifact types or statuses"
    )
  }
  actual_sha256 <- vapply(
    normalized_manifest_paths,
    artifact_sha256,
    character(1)
  )
  actual_bytes <- unname(file.info(normalized_manifest_paths)$size)
  actual_rows <- integer(length(normalized_manifest_paths))
  actual_columns <- integer(length(normalized_manifest_paths))
  for (index in seq_along(normalized_manifest_paths)) {
    artifact <- readr::read_csv(
      normalized_manifest_paths[[index]],
      show_col_types = FALSE,
      progress = FALSE
    )
    actual_rows[[index]] <- nrow(artifact)
    actual_columns[[index]] <- ncol(artifact)
  }
  exact <- actual_sha256 == manifest$sha256 &
    actual_bytes == manifest$bytes &
    actual_rows == manifest$rows &
    actual_columns == manifest$columns
  if (anyNA(exact) || !all(exact)) {
    abort_pipeline(
      "State-support gate manifest path/hash/bytes/rows/columns disagree for: %s",
      paste(manifest$artifact_type[!exact], collapse = ", ")
    )
  }
  tibble::tibble(
    artifact_type = manifest$artifact_type,
    path = normalized_manifest_paths,
    sha256 = actual_sha256,
    bytes = actual_bytes,
    rows = actual_rows,
    columns = actual_columns
  )
}

state_gate_verifier_assert_rule_a <- function(
  settings,
  run_label,
  placements
) {
  required <- c(
    "run_label",
    "placement",
    "coverage_rule_id",
    "coverage_signal",
    "daily_denominator_domain",
    "daily_eligibility_basis",
    "hourly_gate_scope",
    "minute_values_masked_by_hour_gate",
    "hour_screened_sensitivity_available",
    "all_zero_medi_exclusion_applied",
    "all_zero_medi_sensitivity_available",
    "diary_sleep_excluded_from_denominator",
    "expected_wall_minutes_per_hour",
    "expected_wall_minutes_per_day",
    "minimum_hour_coverage",
    "minimum_day_coverage"
  )
  assert_columns(
    settings,
    required,
    object = "Preparation 02 coverage settings"
  )
  assert_unique_key(
    settings,
    c("run_label", "placement"),
    object = "Preparation 02 coverage settings"
  )
  if (
    nrow(settings) != length(placements) ||
      !setequal(as.character(settings$placement), placements) ||
      anyNA(settings[required]) ||
      any(settings$run_label != run_label) ||
      any(settings$coverage_rule_id != "A") ||
      any(settings$coverage_signal != "MEDI") ||
      any(
        settings$daily_denominator_domain != "all_pseudo_local_wall_minutes"
      ) ||
      any(
        settings$daily_eligibility_basis !=
          "finite_medi_minutes_across_fixed_24_hour_cycle"
      ) ||
      any(settings$hourly_gate_scope != "hourly_metrics_only") ||
      any(settings$minute_values_masked_by_hour_gate) ||
      any(!settings$hour_screened_sensitivity_available) ||
      any(!settings$all_zero_medi_exclusion_applied) ||
      any(!settings$all_zero_medi_sensitivity_available) ||
      any(settings$diary_sleep_excluded_from_denominator) ||
      any(settings$expected_wall_minutes_per_hour != 60) ||
      any(settings$expected_wall_minutes_per_day != 1440) ||
      any(settings$minimum_hour_coverage != 0.50) ||
      any(settings$minimum_day_coverage != 0.80)
  ) {
    abort_pipeline(
      paste0(
        "Preparation 02 settings do not record the approved full-day ",
        "coverage rule, hourly-summary-only 50% requirement, and all-zero ",
        "melEDI day exclusion with an inclusive sensitivity available"
      )
    )
  }
  invisible(settings)
}

state_gate_verifier_assert_cutoffs <- function(cutoffs) {
  observed <- sort(unique(as.numeric(cutoffs)))
  if (
    anyNA(observed) ||
      length(observed) != length(state_gate_verifier_cutoffs) ||
      !isTRUE(all.equal(
        observed,
        state_gate_verifier_cutoffs,
        tolerance = 0,
        check.attributes = FALSE
      ))
  ) {
    abort_pipeline(
      "State-support cutoff registry must be exactly 0.70, 0.80, and 0.90"
    )
  }
  invisible(observed)
}

state_gate_verifier_read_interval <- function(
  path,
  site,
  interval_kind
) {
  intervals <- readRDS(path)
  if (!is.data.frame(intervals)) {
    abort_pipeline(
      "%s %s interval artifact is not a data frame",
      site,
      interval_kind
    )
  }
  state_columns <- if (identical(interval_kind, "sleep")) {
    c("State.Brown", "sleep")
  } else {
    "wear"
  }
  required <- c(
    "site",
    "Id",
    "timezone",
    "interval_kind",
    "interval_bounds",
    "start",
    "end",
    state_columns
  )
  assert_columns(
    intervals,
    required,
    object = paste(site, interval_kind, "interval artifact")
  )
  if (
    anyNA(intervals[c(
      "site",
      "Id",
      "timezone",
      "interval_kind",
      "interval_bounds",
      "start",
      "end"
    )]) ||
      any(intervals$site != site) ||
      any(intervals$interval_kind != interval_kind) ||
      any(intervals$interval_bounds != "[)") ||
      !inherits(intervals$start, "POSIXct") ||
      !inherits(intervals$end, "POSIXct") ||
      !identical(attr(intervals$start, "tzone"), "UTC") ||
      !identical(attr(intervals$end, "tzone"), "UTC") ||
      any(as.numeric(intervals$start) >= as.numeric(intervals$end)) ||
      any(!intervals$timezone %in% OlsonNames())
  ) {
    abort_pipeline(
      "%s %s intervals violate canonical true-UTC half-open semantics",
      site,
      interval_kind
    )
  }
  if (identical(interval_kind, "sleep")) {
    if (
      anyNA(intervals[c("State.Brown", "sleep")]) ||
        any(
          !intervals$State.Brown %in% c("wake", "pre-sleep", "sleep")
        ) ||
        any(!intervals$sleep %in% c("wake", "sleepprep"))
    ) {
      abort_pipeline("%s sleep intervals contain invalid states", site)
    }
  } else if (
    anyNA(intervals$wear) ||
      any(!intervals$wear %in% c("off", "sleep", "site_leave"))
  ) {
    abort_pipeline("%s wear intervals contain invalid states", site)
  }
  provenance <- attr(intervals, "state_interval_provenance")
  if (
    !is.list(provenance) ||
      !identical(as.character(provenance$site), site) ||
      !identical(as.character(provenance$interval_kind), interval_kind) ||
      !identical(as.character(provenance$bounds), "[)") ||
      !identical(
        as.character(provenance$timezone),
        unique(as.character(intervals$timezone))
      )
  ) {
    abort_pipeline(
      "%s %s intervals lack matching artifact-level provenance",
      site,
      interval_kind
    )
  }
  intervals
}

state_gate_verifier_validate_nonoverlap <- function(
  intervals,
  interval_kind
) {
  participant_key <- paste(intervals$site, intervals$Id, sep = "\r")
  groups <- split(seq_len(nrow(intervals)), participant_key)
  for (index in groups) {
    ordered <- index[order(
      as.numeric(intervals$start[index]),
      as.numeric(intervals$end[index])
    )]
    if (length(ordered) > 1L) {
      starts <- as.numeric(intervals$start[ordered])
      ends <- as.numeric(intervals$end[ordered])
      if (any(starts[-1L] < ends[-length(ends)])) {
        abort_pipeline(
          "Canonical %s intervals overlap within participant",
          interval_kind
        )
      }
    }
  }
  invisible(intervals)
}

state_gate_verifier_project_intervals <- function(
  target,
  intervals,
  value_column
) {
  output <- rep(NA_character_, nrow(target))
  target_key <- paste(target$site, target$Id, sep = "\r")
  interval_key <- paste(intervals$site, intervals$Id, sep = "\r")
  target_groups <- split(seq_len(nrow(target)), target_key)
  interval_groups <- split(seq_len(nrow(intervals)), interval_key)
  for (key in names(target_groups)) {
    interval_index <- interval_groups[[key]]
    if (is.null(interval_index) || length(interval_index) == 0L) {
      next
    }
    ordered <- interval_index[order(
      as.numeric(intervals$start[interval_index]),
      as.numeric(intervals$end[interval_index])
    )]
    starts <- as.numeric(intervals$start[ordered])
    ends <- as.numeric(intervals$end[ordered])
    values <- as.character(intervals[[value_column]][ordered])
    target_index <- target_groups[[key]]
    instants <- as.numeric(target$datetime_utc[target_index])
    match_index <- findInterval(instants, starts)
    inside <- match_index > 0L
    inside[inside] <- instants[inside] < ends[match_index[inside]]
    output[target_index[inside]] <- values[match_index[inside]]
  }
  output
}

state_gate_verifier_assert_complete_days <- function(eligible, placement) {
  day_key <- paste(
    eligible$site,
    eligible$Id,
    eligible$position,
    eligible$local_date,
    sep = "\r"
  )
  groups <- split(seq_len(nrow(eligible)), day_key)
  for (index in groups) {
    timezone <- unique(as.character(eligible$timezone[index]))
    local_date <- unique(as.Date(eligible$local_date[index]))
    if (
      length(timezone) != 1L ||
        length(local_date) != 1L ||
        !timezone %in% OlsonNames()
    ) {
      abort_pipeline(
        "%s eligible participant-day has inconsistent date or time zone",
        placement
      )
    }
    local_start <- as.POSIXct(
      paste(format(local_date), "00:00:00"),
      tz = timezone
    )
    local_end <- as.POSIXct(
      paste(format(local_date + 1L), "00:00:00"),
      tz = timezone
    )
    expected <- seq.int(
      from = as.numeric(local_start),
      to = as.numeric(local_end) - 60,
      by = 60
    )
    observed <- sort(as.numeric(eligible$datetime_utc[index]))
    if (!identical(observed, expected)) {
      abort_pipeline(
        paste0(
          "%s participant-day is not an exact complete true-UTC minute ",
          "grid bounded by local midnights"
        ),
        placement
      )
    }
  }
  invisible(length(groups))
}

state_gate_verifier_equal_missing <- function(observed, expected) {
  (is.na(observed) & is.na(expected)) |
    (!is.na(observed) & !is.na(expected) & observed == expected)
}

state_gate_verifier_reconstruct_placement <- function(
  coverage_path,
  placement,
  sleep_intervals,
  wear_intervals
) {
  coverage <- readRDS(coverage_path)
  if (!is.data.frame(coverage)) {
    abort_pipeline("%s coverage artifact is not a data frame", placement)
  }
  required <- c(
    "site",
    "Id",
    "position",
    "datetime_utc",
    "timezone",
    "local_date",
    "State.Brown",
    "wear",
    "invalid_nonwear",
    "MEDI_eligible",
    "day_eligible"
  )
  assert_columns(
    coverage,
    required,
    object = paste(placement, "coverage artifact")
  )
  if (
    anyNA(coverage[c(
      "site",
      "Id",
      "position",
      "datetime_utc",
      "timezone",
      "local_date",
      "invalid_nonwear",
      "day_eligible"
    )]) ||
      any(coverage$position != placement) ||
      !inherits(coverage$datetime_utc, "POSIXct") ||
      !identical(attr(coverage$datetime_utc, "tzone"), "UTC") ||
      !inherits(coverage$local_date, "Date")
  ) {
    abort_pipeline("%s coverage has invalid key or time fields", placement)
  }
  day_key <- c("site", "Id", "position", "local_date")
  day_flags <- coverage |>
    dplyr::group_by(dplyr::across(dplyr::all_of(day_key))) |>
    dplyr::summarise(
      timezones = dplyr::n_distinct(.data$timezone),
      eligibility_values = dplyr::n_distinct(.data$day_eligible),
      timezone = dplyr::first(.data$timezone),
      day_eligible = dplyr::first(.data$day_eligible),
      .groups = "drop"
    )
  if (
    any(day_flags$timezones != 1L) ||
      any(day_flags$eligibility_values != 1L)
  ) {
    abort_pipeline(
      "%s coverage does not have constant day eligibility and time zone",
      placement
    )
  }
  eligible <- coverage[
    coverage$day_eligible,
    required[required != "day_eligible"],
    drop = FALSE
  ]
  rm(coverage)
  invisible(gc())
  if (nrow(eligible) == 0L) {
    abort_pipeline("%s coverage has no Rule A eligible days", placement)
  }
  eligible_days <- dplyr::filter(day_flags, .data$day_eligible)
  state_gate_verifier_assert_complete_days(eligible, placement)

  projected_state <- state_gate_verifier_project_intervals(
    eligible,
    sleep_intervals,
    "State.Brown"
  )
  projected_wear <- state_gate_verifier_project_intervals(
    eligible,
    wear_intervals,
    "wear"
  )
  if (
    !all(state_gate_verifier_equal_missing(
      as.character(eligible$State.Brown),
      projected_state
    )) ||
      !all(state_gate_verifier_equal_missing(
        as.character(eligible$wear),
        projected_wear
      ))
  ) {
    abort_pipeline(
      "%s coverage disagrees with independent true-UTC half-open state projection",
      placement
    )
  }
  projected_invalid_nonwear <- !is.na(projected_wear) &
    projected_wear == "off" &
    (is.na(projected_state) | projected_state != "sleep")
  if (
    !identical(
      as.logical(eligible$invalid_nonwear),
      projected_invalid_nonwear
    ) ||
      any(projected_invalid_nonwear & is.finite(eligible$MEDI_eligible))
  ) {
    abort_pipeline(
      "%s coverage violates the approved off-outside-diary-sleep mask",
      placement
    )
  }
  eligible$projected_state <- projected_state
  grouped <- split(
    seq_len(nrow(eligible)),
    paste(
      eligible$site,
      eligible$Id,
      eligible$position,
      eligible$local_date,
      sep = "\r"
    )
  )
  records <- vector("list", length(grouped))
  group_number <- 0L
  for (index in grouped) {
    group_number <- group_number + 1L
    state <- eligible$projected_state[index]
    unknown <- sum(is.na(state))
    metric_rows <- vector(
      "list",
      length(state_gate_verifier_metrics)
    )
    metric_number <- 0L
    for (metric in names(state_gate_verifier_metrics)) {
      metric_number <- metric_number + 1L
      domain <- unname(state_gate_verifier_metrics[[metric]])
      domain_rows <- !is.na(state) & state == domain
      expected_minutes <- sum(domain_rows)
      valid_minutes <- sum(
        domain_rows & is.finite(eligible$MEDI_eligible[index])
      )
      metric_rows[[metric_number]] <- tibble::tibble(
        site = as.character(eligible$site[index[[1L]]]),
        Id = as.character(eligible$Id[index[[1L]]]),
        position = as.character(eligible$position[index[[1L]]]),
        local_date = as.Date(eligible$local_date[index[[1L]]]),
        metric = metric,
        state_domain = domain,
        ordinary_support = if (expected_minutes > 0L) {
          valid_minutes / expected_minutes
        } else {
          NA_real_
        },
        valid_minutes = as.integer(valid_minutes),
        expected_minutes = as.integer(expected_minutes),
        unknown_diary_state_minutes = as.integer(unknown),
        state_domain_complete = unknown == 0L,
        failure_reason = if (unknown > 0L) {
          "incomplete_state_domain"
        } else if (expected_minutes == 0L) {
          "no_state_window"
        } else {
          NA_character_
        }
      )
    }
    records[[group_number]] <- dplyr::bind_rows(metric_rows)
  }
  daily <- dplyr::bind_rows(records) |>
    dplyr::arrange(
      .data$site,
      .data$Id,
      .data$position,
      .data$local_date,
      .data$metric
    )
  expected_days <- nrow(eligible_days)
  if (nrow(daily) != expected_days * 3L) {
    abort_pipeline(
      "%s reconstruction did not produce exactly three rows per eligible day",
      placement
    )
  }
  assert_unique_key(
    daily,
    c(day_key, "metric"),
    object = paste(placement, "reconstructed state-support daily table")
  )
  list(
    daily = daily,
    eligible_days = expected_days,
    eligible_participants = dplyr::n_distinct(
      paste(eligible_days$site, eligible_days$Id, sep = "\r")
    ),
    sites = sort(unique(as.character(eligible_days$site)))
  )
}

state_gate_verifier_assert_daily_invariants <- function(daily) {
  expected_names <- c(
    "site",
    "Id",
    "position",
    "local_date",
    "metric",
    "state_domain",
    "ordinary_support",
    "valid_minutes",
    "expected_minutes",
    "unknown_diary_state_minutes",
    "state_domain_complete",
    "failure_reason"
  )
  if (!identical(names(daily), expected_names)) {
    abort_pipeline("State-support daily artifact has an unexpected schema")
  }
  daily$local_date <- as.Date(daily$local_date)
  daily$state_domain_complete <- as.logical(
    daily$state_domain_complete
  )
  assert_unique_key(
    daily,
    c(
      "site",
      "Id",
      "position",
      "local_date",
      "metric"
    ),
    object = "state-support daily artifact"
  )
  mapped <- unname(state_gate_verifier_metrics[daily$metric])
  if (
    anyNA(mapped) ||
      any(mapped != daily$state_domain) ||
      anyNA(daily[c(
        "valid_minutes",
        "expected_minutes",
        "unknown_diary_state_minutes",
        "state_domain_complete"
      )]) ||
      any(daily$valid_minutes < 0) ||
      any(daily$expected_minutes < 0) ||
      any(daily$valid_minutes > daily$expected_minutes) ||
      any(daily$unknown_diary_state_minutes < 0) ||
      any(
        daily$state_domain_complete != (daily$unknown_diary_state_minutes == 0L)
      )
  ) {
    abort_pipeline(
      "State-support daily artifact has invalid metric mapping, counts, or state completeness"
    )
  }
  positive <- daily$expected_minutes > 0L
  expected_support <- ifelse(
    positive,
    daily$valid_minutes / daily$expected_minutes,
    NA_real_
  )
  if (
    !state_gate_verifier_values_equal(
      daily$ordinary_support,
      expected_support
    )
  ) {
    abort_pipeline(
      "State-support daily artifact has inconsistent support fractions"
    )
  }
  expected_reason <- ifelse(
    !daily$state_domain_complete,
    "incomplete_state_domain",
    ifelse(!positive, "no_state_window", NA_character_)
  )
  if (
    !all(state_gate_verifier_equal_missing(
      as.character(daily$failure_reason),
      expected_reason
    ))
  ) {
    abort_pipeline(
      "State-support daily artifact has inconsistent explicit failure categories"
    )
  }
  day_counts <- daily |>
    dplyr::count(
      .data$site,
      .data$Id,
      .data$position,
      .data$local_date,
      name = "metric_rows"
    )
  if (any(day_counts$metric_rows != 3L)) {
    abort_pipeline(
      "State-support daily artifact does not contain exactly three metrics per eligible day"
    )
  }
  daily
}

state_gate_verifier_quantile <- function(value, probability) {
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

state_gate_verifier_distinct_participants <- function(
  site,
  id,
  include = rep(TRUE, length(id))
) {
  include[is.na(include)] <- FALSE
  length(unique(paste(site[include], id[include], sep = "\r")))
}

state_gate_verifier_classify <- function(daily) {
  cutoffs <- state_gate_verifier_cutoffs
  expanded <- daily[rep(seq_len(nrow(daily)), each = length(cutoffs)), ]
  expanded$candidate_state_support_cutoff <- rep(
    cutoffs,
    times = nrow(daily)
  )
  expanded$has_state_window <- expanded$state_domain_complete &
    expanded$expected_minutes > 0L
  expanded$retained_at_candidate <- expanded$has_state_window &
    expanded$ordinary_support >= expanded$candidate_state_support_cutoff
  expanded$metric_na_at_candidate <- !expanded$retained_at_candidate
  expanded$no_state_window <- expanded$state_domain_complete &
    !expanded$has_state_window
  expanded$incomplete_state_domain <- !expanded$state_domain_complete
  expanded$insufficient_state_support <- expanded$has_state_window &
    expanded$ordinary_support < expanded$candidate_state_support_cutoff
  categories <- expanded$retained_at_candidate +
    expanded$no_state_window +
    expanded$incomplete_state_domain +
    expanded$insufficient_state_support
  if (anyNA(categories) || any(categories != 1L)) {
    abort_pipeline(
      "Independent state-support candidate categories are not mutually exclusive and exhaustive"
    )
  }
  expanded
}

state_gate_verifier_summarise_overall <- function(classified) {
  group_key <- paste(
    classified$position,
    classified$metric,
    classified$state_domain,
    classified$candidate_state_support_cutoff,
    sep = "\r"
  )
  groups <- split(seq_len(nrow(classified)), group_key)
  rows <- lapply(groups, function(index) {
    data <- classified[index, , drop = FALSE]
    with_window <- data$has_state_window
    retained <- data$retained_at_candidate
    tibble::tibble(
      position = as.character(data$position[[1L]]),
      metric = as.character(data$metric[[1L]]),
      state_domain = as.character(data$state_domain[[1L]]),
      candidate_state_support_cutoff = data$candidate_state_support_cutoff[[
        1L
      ]],
      eligible_participant_days = nrow(data),
      eligible_participants = state_gate_verifier_distinct_participants(
        data$site,
        data$Id
      ),
      eligible_sites = length(unique(data$site)),
      participant_days_with_state_window = sum(with_window),
      participants_with_state_window = state_gate_verifier_distinct_participants(
        data$site,
        data$Id,
        with_window
      ),
      retained_metric_instances = sum(retained),
      retained_participants = state_gate_verifier_distinct_participants(
        data$site,
        data$Id,
        retained
      ),
      sites_with_retained_metric = length(unique(data$site[retained])),
      metric_na_instances = sum(data$metric_na_at_candidate),
      no_state_window_instances = sum(data$no_state_window),
      incomplete_state_domain_instances = sum(
        data$incomplete_state_domain
      ),
      insufficient_state_support_instances = sum(
        data$insufficient_state_support
      ),
      ordinary_support_q10 = state_gate_verifier_quantile(
        data$ordinary_support[with_window],
        0.10
      ),
      ordinary_support_q25 = state_gate_verifier_quantile(
        data$ordinary_support[with_window],
        0.25
      ),
      ordinary_support_median = state_gate_verifier_quantile(
        data$ordinary_support[with_window],
        0.50
      ),
      ordinary_support_q75 = state_gate_verifier_quantile(
        data$ordinary_support[with_window],
        0.75
      ),
      ordinary_support_q90 = state_gate_verifier_quantile(
        data$ordinary_support[with_window],
        0.90
      )
    )
  })
  output <- dplyr::bind_rows(rows) |>
    dplyr::arrange(
      .data$position,
      .data$metric,
      .data$state_domain,
      .data$candidate_state_support_cutoff
    ) |>
    dplyr::group_by(
      .data$position,
      .data$metric,
      .data$state_domain
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
    dplyr::ungroup()
  if (
    any(
      output$classification_total != output$eligible_participant_days
    )
  ) {
    abort_pipeline(
      "Independent overall state-support classifications do not reconcile"
    )
  }
  output
}

state_gate_verifier_summarise_site <- function(classified) {
  group_key <- paste(
    classified$position,
    classified$site,
    classified$metric,
    classified$state_domain,
    classified$candidate_state_support_cutoff,
    sep = "\r"
  )
  groups <- split(seq_len(nrow(classified)), group_key)
  rows <- lapply(groups, function(index) {
    data <- classified[index, , drop = FALSE]
    with_window <- data$has_state_window
    retained <- data$retained_at_candidate
    tibble::tibble(
      position = as.character(data$position[[1L]]),
      site = as.character(data$site[[1L]]),
      metric = as.character(data$metric[[1L]]),
      state_domain = as.character(data$state_domain[[1L]]),
      candidate_state_support_cutoff = data$candidate_state_support_cutoff[[
        1L
      ]],
      eligible_participant_days = nrow(data),
      eligible_participants = length(unique(data$Id)),
      participant_days_with_state_window = sum(with_window),
      retained_metric_instances = sum(retained),
      retained_participants = length(unique(data$Id[retained])),
      no_state_window_instances = sum(data$no_state_window),
      incomplete_state_domain_instances = sum(
        data$incomplete_state_domain
      ),
      insufficient_state_support_instances = sum(
        data$insufficient_state_support
      ),
      ordinary_support_q25 = state_gate_verifier_quantile(
        data$ordinary_support[with_window],
        0.25
      ),
      ordinary_support_median = state_gate_verifier_quantile(
        data$ordinary_support[with_window],
        0.50
      ),
      ordinary_support_q75 = state_gate_verifier_quantile(
        data$ordinary_support[with_window],
        0.75
      )
    )
  })
  output <- dplyr::bind_rows(rows) |>
    dplyr::arrange(
      .data$position,
      .data$site,
      .data$metric,
      .data$state_domain,
      .data$candidate_state_support_cutoff
    ) |>
    dplyr::group_by(
      .data$position,
      .data$site,
      .data$metric,
      .data$state_domain
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
    dplyr::ungroup()
  if (
    any(
      output$classification_total != output$eligible_participant_days
    )
  ) {
    abort_pipeline(
      "Independent site-stratified state-support classifications do not reconcile"
    )
  }
  output
}

state_gate_verifier_contains_l5 <- function(data) {
  labels <- names(data)
  character_columns <- vapply(
    data,
    function(column) is.character(column) || is.factor(column),
    logical(1)
  )
  if (any(character_columns)) {
    labels <- c(
      labels,
      unlist(
        lapply(data[character_columns], as.character),
        use.names = FALSE
      )
    )
  }
  any(grepl("l5", labels[!is.na(labels)], ignore.case = TRUE))
}

state_gate_verifier_validate_inputs <- function(
  inputs,
  layout,
  placements,
  coverage_settings_path,
  coverage_settings_sha256,
  state_manifest,
  state_manifest_sha256
) {
  expected_names <- c(
    "run_label",
    "profile_variant",
    "placement",
    "site",
    "interval_kind",
    "state_interval_path",
    "state_interval_sha256",
    "state_interval_manifest_path",
    "state_interval_manifest_sha256",
    "coverage_path",
    "coverage_sha256",
    "coverage_settings_path",
    "coverage_settings_sha256",
    "verified_minimum_hour_coverage",
    "verified_minimum_day_coverage",
    "candidate_cutoffs",
    "status"
  )
  if (!identical(names(inputs), expected_names)) {
    abort_pipeline("State-support gate input artifact has an unexpected schema")
  }
  assert_unique_key(
    inputs,
    c("placement", "site", "interval_kind"),
    object = "state-support gate inputs"
  )
  recorded_registry <- unique(as.character(inputs$candidate_cutoffs))
  if (
    length(recorded_registry) != 1L ||
      !identical(recorded_registry, "0.7|0.8|0.9")
  ) {
    abort_pipeline(
      "State-support cutoff registry must be exactly 0.70, 0.80, and 0.90"
    )
  }
  state_gate_verifier_assert_cutoffs(
    as.numeric(strsplit(
      recorded_registry,
      "|",
      fixed = TRUE
    )[[1L]])
  )
  expected_pairs <- merge(
    unique(inputs[c("placement", "site")]),
    data.frame(
      interval_kind = c("sleep", "wear"),
      stringsAsFactors = FALSE
    ),
    all = TRUE
  )
  observed_pairs <- inputs[c("placement", "site", "interval_kind")]
  if (
    nrow(observed_pairs) != nrow(expected_pairs) ||
      !setequal(
        paste(
          observed_pairs$placement,
          observed_pairs$site,
          observed_pairs$interval_kind,
          sep = "\r"
        ),
        paste(
          expected_pairs$placement,
          expected_pairs$site,
          expected_pairs$interval_kind,
          sep = "\r"
        )
      ) ||
      anyNA(inputs) ||
      any(inputs$run_label != layout$run_label) ||
      any(inputs$profile_variant != "pooled") ||
      !setequal(as.character(inputs$placement), placements) ||
      any(inputs$verified_minimum_hour_coverage != 0.50) ||
      any(inputs$verified_minimum_day_coverage != 0.80) ||
      any(
        inputs$status != "AUTHOR_GATE_INPUT_NOT_A_SELECTED_RULE"
      )
  ) {
    abort_pipeline(
      "State-support gate inputs do not contain exact placement/site/kind and author-gate metadata"
    )
  }
  normalized_settings_paths <- vapply(
    inputs$coverage_settings_path,
    normalizePath,
    character(1),
    winslash = "/",
    mustWork = TRUE
  )
  normalized_state_manifest_paths <- vapply(
    inputs$state_interval_manifest_path,
    normalizePath,
    character(1),
    winslash = "/",
    mustWork = TRUE
  )
  if (
    any(normalized_settings_paths != coverage_settings_path) ||
      any(inputs$coverage_settings_sha256 != coverage_settings_sha256) ||
      any(
        normalized_state_manifest_paths != layout$state_interval_manifest_path
      ) ||
      any(
        inputs$state_interval_manifest_sha256 != state_manifest_sha256
      )
  ) {
    abort_pipeline(
      "State-support gate inputs fail settings or state-manifest path/hash propagation"
    )
  }
  matched <- match(
    paste(inputs$site, inputs$interval_kind, sep = "\r"),
    paste(
      state_manifest$site,
      state_manifest$interval_kind,
      sep = "\r"
    )
  )
  if (anyNA(matched)) {
    abort_pipeline(
      "State-support gate inputs reference an unmanifested state interval"
    )
  }
  expected_interval_paths <- vapply(
    seq_len(nrow(inputs)),
    function(index) {
      normalizePath(
        file.path(
          layout$state_interval_run_root,
          paste0(
            inputs$site[[index]],
            "_",
            inputs$interval_kind[[index]],
            "_intervals.rds"
          )
        ),
        winslash = "/",
        mustWork = TRUE
      )
    },
    character(1)
  )
  recorded_interval_paths <- vapply(
    inputs$state_interval_path,
    normalizePath,
    character(1),
    winslash = "/",
    mustWork = TRUE
  )
  if (
    any(recorded_interval_paths != expected_interval_paths) ||
      any(inputs$state_interval_sha256 != state_manifest$sha256[matched])
  ) {
    abort_pipeline(
      "State-support gate inputs fail canonical state-interval path/hash propagation"
    )
  }
  coverage_paths <- setNames(character(length(placements)), placements)
  for (placement in placements) {
    expected_path <- normalizePath(
      file.path(
        layout$coverage_run_root,
        paste0("light_", placement, "_coverage.rds")
      ),
      winslash = "/",
      mustWork = TRUE
    )
    rows <- inputs$placement == placement
    recorded_paths <- vapply(
      inputs$coverage_path[rows],
      normalizePath,
      character(1),
      winslash = "/",
      mustWork = TRUE
    )
    observed_sha256 <- artifact_sha256(expected_path)
    if (
      any(recorded_paths != expected_path) ||
        any(inputs$coverage_sha256[rows] != observed_sha256)
    ) {
      abort_pipeline(
        "%s gate input fails canonical coverage path/hash propagation",
        placement
      )
    }
    coverage_paths[[placement]] <- expected_path
  }
  list(
    coverage_paths = coverage_paths,
    interval_paths = sort(unique(recorded_interval_paths))
  )
}

state_gate_verifier_validate_state_manifest <- function(
  manifest,
  layout
) {
  required <- c(
    "path",
    "sha256",
    "bytes",
    "artifact_type",
    "run_label",
    "site",
    "interval_kind",
    "interval_bounds"
  )
  assert_columns(
    manifest,
    required,
    object = "Preparation 01 state-interval manifest"
  )
  assert_unique_key(
    manifest,
    c("site", "interval_kind"),
    object = "Preparation 01 state-interval manifest"
  )
  if (
    anyNA(manifest[required]) ||
      any(!manifest$interval_kind %in% c("sleep", "wear")) ||
      any(manifest$interval_bounds != "[)") ||
      any(manifest$run_label != layout$run_label) ||
      any(!grepl("^[0-9a-f]{64}$", manifest$sha256))
  ) {
    abort_pipeline(
      "Preparation 01 state-interval manifest metadata is inconsistent"
    )
  }
  expected_types <- ifelse(
    manifest$interval_kind == "sleep",
    "site_sleep_state_intervals",
    "site_wear_state_intervals"
  )
  expected_paths <- file.path(
    layout$state_interval_run_root,
    paste0(
      manifest$site,
      "_",
      manifest$interval_kind,
      "_intervals.rds"
    )
  )
  normalized_expected <- vapply(
    expected_paths,
    normalizePath,
    character(1),
    winslash = "/",
    mustWork = TRUE
  )
  normalized_recorded <- vapply(
    manifest$path,
    normalizePath,
    character(1),
    winslash = "/",
    mustWork = TRUE
  )
  actual_sha256 <- vapply(
    normalized_recorded,
    artifact_sha256,
    character(1)
  )
  actual_bytes <- unname(file.info(normalized_recorded)$size)
  if (
    any(manifest$artifact_type != expected_types) ||
      any(normalized_recorded != normalized_expected) ||
      any(manifest$sha256 != actual_sha256) ||
      any(manifest$bytes != actual_bytes)
  ) {
    abort_pipeline(
      "Preparation 01 state-interval manifest fails exact path/hash/bytes verification"
    )
  }
  manifest$path <- normalized_recorded
  manifest
}

verify_state_support_gate_artifacts <- function(
  root = project_root(),
  run_label = "full",
  coverage_run_root = NULL,
  state_interval_run_root = NULL,
  state_interval_manifest_path = NULL,
  metric_run_root = NULL,
  manifest_path = NULL,
  tolerance = 1e-12,
  stop_on_failure = TRUE
) {
  if (
    length(tolerance) != 1L ||
      !is.numeric(tolerance) ||
      !is.finite(tolerance) ||
      tolerance < 0
  ) {
    abort_pipeline("`tolerance` must be one non-negative finite value")
  }
  layout <- state_gate_verifier_layout(
    root = root,
    run_label = run_label,
    coverage_run_root = coverage_run_root,
    state_interval_run_root = state_interval_run_root,
    state_interval_manifest_path = state_interval_manifest_path,
    metric_run_root = metric_run_root,
    manifest_path = manifest_path
  )
  output_paths <- state_gate_verifier_output_paths(layout$metric_run_root)
  if (!all(file.exists(output_paths))) {
    abort_pipeline(
      "State-support gate output is missing: %s",
      paste(output_paths[!file.exists(output_paths)], collapse = ", ")
    )
  }
  initial_manifest_sha256 <- artifact_sha256(layout$manifest_path)
  manifest <- readr::read_csv(
    layout$manifest_path,
    show_col_types = FALSE,
    progress = FALSE
  )
  manifest_check <- state_gate_verifier_assert_manifest(
    manifest,
    layout,
    output_paths
  )

  daily <- readr::read_csv(
    output_paths[["state_support_gate_daily"]],
    show_col_types = FALSE,
    progress = FALSE,
    col_types = readr::cols(
      local_date = readr::col_date(),
      failure_reason = readr::col_character()
    )
  )
  overall <- readr::read_csv(
    output_paths[["state_support_candidate_diagnostics"]],
    show_col_types = FALSE,
    progress = FALSE
  )
  by_site <- readr::read_csv(
    output_paths[["state_support_candidate_by_site"]],
    show_col_types = FALSE,
    progress = FALSE
  )
  inputs <- readr::read_csv(
    output_paths[["state_support_gate_inputs"]],
    show_col_types = FALSE,
    progress = FALSE,
    col_types = readr::cols(candidate_cutoffs = readr::col_character())
  )
  daily <- state_gate_verifier_assert_daily_invariants(daily)
  state_gate_verifier_assert_cutoffs(
    overall$candidate_state_support_cutoff
  )
  state_gate_verifier_assert_cutoffs(
    by_site$candidate_state_support_cutoff
  )
  if (
    state_gate_verifier_contains_l5(daily) ||
      state_gate_verifier_contains_l5(overall) ||
      state_gate_verifier_contains_l5(by_site) ||
      state_gate_verifier_contains_l5(inputs)
  ) {
    abort_pipeline(
      "Excluded L5 output appears in state-support gate artifacts"
    )
  }

  coverage_settings_path <- normalizePath(
    file.path(layout$coverage_run_root, "coverage_settings.csv"),
    winslash = "/",
    mustWork = TRUE
  )
  initial_coverage_settings_sha256 <- artifact_sha256(
    coverage_settings_path
  )
  settings <- readr::read_csv(
    coverage_settings_path,
    show_col_types = FALSE,
    progress = FALSE
  )
  placements <- sort(unique(as.character(settings$placement)))
  state_gate_verifier_assert_rule_a(
    settings,
    layout$run_label,
    placements
  )

  initial_state_manifest_sha256 <- artifact_sha256(
    layout$state_interval_manifest_path
  )
  state_manifest <- readr::read_csv(
    layout$state_interval_manifest_path,
    show_col_types = FALSE,
    progress = FALSE
  )
  state_manifest <- state_gate_verifier_validate_state_manifest(
    state_manifest,
    layout
  )
  verified_inputs <- state_gate_verifier_validate_inputs(
    inputs = inputs,
    layout = layout,
    placements = placements,
    coverage_settings_path = coverage_settings_path,
    coverage_settings_sha256 = initial_coverage_settings_sha256,
    state_manifest = state_manifest,
    state_manifest_sha256 = initial_state_manifest_sha256
  )
  initial_coverage_hashes <- vapply(
    verified_inputs$coverage_paths,
    artifact_sha256,
    character(1)
  )
  initial_interval_hashes <- vapply(
    verified_inputs$interval_paths,
    artifact_sha256,
    character(1)
  )

  interval_objects <- lapply(
    seq_len(nrow(state_manifest)),
    function(index) {
      state_gate_verifier_read_interval(
        state_manifest$path[[index]],
        state_manifest$site[[index]],
        state_manifest$interval_kind[[index]]
      )
    }
  )
  sleep_intervals <- dplyr::bind_rows(
    interval_objects[state_manifest$interval_kind == "sleep"]
  )
  wear_intervals <- dplyr::bind_rows(
    interval_objects[state_manifest$interval_kind == "wear"]
  )
  state_gate_verifier_validate_nonoverlap(
    sleep_intervals,
    "sleep"
  )
  state_gate_verifier_validate_nonoverlap(wear_intervals, "wear")

  reconstructed <- vector("list", length(placements))
  names(reconstructed) <- placements
  placement_summary <- vector("list", length(placements))
  names(placement_summary) <- placements
  for (placement in placements) {
    placement_sites <- sort(unique(
      as.character(inputs$site[inputs$placement == placement])
    ))
    reconstructed[[placement]] <- state_gate_verifier_reconstruct_placement(
      coverage_path = verified_inputs$coverage_paths[[placement]],
      placement = placement,
      sleep_intervals = sleep_intervals[
        sleep_intervals$site %in% placement_sites,
        ,
        drop = FALSE
      ],
      wear_intervals = wear_intervals[
        wear_intervals$site %in% placement_sites,
        ,
        drop = FALSE
      ]
    )
    if (!identical(reconstructed[[placement]]$sites, placement_sites)) {
      abort_pipeline(
        "%s gate inputs and Rule A eligible coverage identify different sites",
        placement
      )
    }
    placement_summary[[placement]] <- tibble::tibble(
      placement = placement,
      eligible_participant_days = reconstructed[[placement]]$eligible_days,
      eligible_participants = reconstructed[[placement]]$eligible_participants,
      sites = length(reconstructed[[placement]]$sites)
    )
  }
  expected_daily <- dplyr::bind_rows(
    lapply(reconstructed, `[[`, "daily")
  ) |>
    dplyr::arrange(
      .data$position,
      .data$site,
      .data$Id,
      .data$local_date,
      .data$metric
    )
  state_gate_verifier_assert_table(
    observed = daily,
    expected = expected_daily,
    key = c(
      "position",
      "site",
      "Id",
      "local_date",
      "metric"
    ),
    object = "state-support daily artifact",
    tolerance = tolerance
  )

  classified <- state_gate_verifier_classify(expected_daily)
  expected_overall <- state_gate_verifier_summarise_overall(classified)
  expected_by_site <- state_gate_verifier_summarise_site(classified)
  state_gate_verifier_assert_table(
    observed = overall,
    expected = expected_overall,
    key = c(
      "position",
      "metric",
      "state_domain",
      "candidate_state_support_cutoff"
    ),
    object = "overall state-support candidate diagnostics",
    tolerance = tolerance
  )
  state_gate_verifier_assert_table(
    observed = by_site,
    expected = expected_by_site,
    key = c(
      "position",
      "site",
      "metric",
      "state_domain",
      "candidate_state_support_cutoff"
    ),
    object = "site state-support candidate diagnostics",
    tolerance = tolerance
  )

  final_hashes <- list(
    gate_manifest = artifact_sha256(layout$manifest_path),
    gate_outputs = vapply(
      output_paths,
      artifact_sha256,
      character(1)
    ),
    coverage_settings = artifact_sha256(coverage_settings_path),
    state_manifest = artifact_sha256(
      layout$state_interval_manifest_path
    ),
    coverage = vapply(
      verified_inputs$coverage_paths,
      artifact_sha256,
      character(1)
    ),
    intervals = vapply(
      verified_inputs$interval_paths,
      artifact_sha256,
      character(1)
    )
  )
  immutable <- identical(
    initial_manifest_sha256,
    final_hashes$gate_manifest
  ) &&
    identical(
      unname(final_hashes$gate_outputs),
      unname(
        manifest_check$sha256[
          match(
            normalizePath(
              output_paths,
              winslash = "/",
              mustWork = TRUE
            ),
            manifest_check$path
          )
        ]
      )
    ) &&
    identical(
      initial_coverage_settings_sha256,
      final_hashes$coverage_settings
    ) &&
    identical(
      initial_state_manifest_sha256,
      final_hashes$state_manifest
    ) &&
    identical(initial_coverage_hashes, final_hashes$coverage) &&
    identical(initial_interval_hashes, final_hashes$intervals)
  if (!immutable) {
    abort_pipeline(
      "State-support gate, coverage, settings, or state-interval inputs changed during verification"
    )
  }

  result <- structure(
    list(
      status = "PASS",
      run_label = layout$run_label,
      manifest_path = layout$manifest_path,
      manifest_sha256 = initial_manifest_sha256,
      manifest = manifest_check,
      placement_summary = dplyr::bind_rows(placement_summary),
      daily_rows = nrow(expected_daily),
      overall_candidate_rows = nrow(expected_overall),
      site_candidate_rows = nrow(expected_by_site),
      state_interval_manifest_sha256 = initial_state_manifest_sha256,
      coverage_settings_sha256 = initial_coverage_settings_sha256,
      cutoffs = state_gate_verifier_cutoffs,
      l5_present = FALSE,
      immutable_inputs = TRUE
    ),
    class = c("state_support_gate_artifact_verification", "list")
  )
  if (!isTRUE(stop_on_failure)) {
    return(result)
  }
  result
}

if (sys.nframe() == 0L) {
  root_override <- Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = "")
  execution_root <- if (nzchar(root_override)) {
    normalizePath(root_override, winslash = "/", mustWork = TRUE)
  } else {
    normalizePath(getwd(), winslash = "/", mustWork = TRUE)
  }
  source(file.path(
    execution_root,
    "scripts",
    "pipeline",
    "paths_io.R"
  ))
  source(file.path(
    execution_root,
    "scripts",
    "pipeline",
    "assertions.R"
  ))
  run_label <- Sys.getenv(
    "NATHEALTH_STATE_SUPPORT_VERIFY_RUN_LABEL",
    unset = "full"
  )
  result <- verify_state_support_gate_artifacts(
    root = execution_root,
    run_label = run_label
  )
  print(result$manifest, n = Inf)
  print(result$placement_summary, n = Inf)
  print(result[c(
    "status",
    "daily_rows",
    "overall_candidate_rows",
    "site_candidate_rows",
    "cutoffs",
    "l5_present",
    "immutable_inputs"
  )])
}
