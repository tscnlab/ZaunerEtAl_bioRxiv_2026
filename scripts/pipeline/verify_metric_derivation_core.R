# Independently verify core Preparation 04 artifacts and sensitive metrics.
#
# Source paths_io.R and assertions.R before calling
# verify_metric_derivation_core(). This verifier intentionally does not source
# build_metric_derivation.R, metric_derivation.R, time_support.R, or their
# scientific helpers. Whole-cohort artifact invariants are exact. Minute-level
# state projection, longest-bout reconstruction, and threshold-timing
# reconstruction are exact on a deterministic sample whose keys are returned.

p04_core_day_key <- c("site", "Id", "position", "local_date")
p04_core_participant_key <- c("site", "Id", "position")
p04_core_numerical_zero_rule <- paste0(
  "normalize_to_zero_only_if_abs(raw_backtransform)<=",
  "100*.Machine$double.eps*max(1,abs(shifted_mean),abs(zero_offset))",
  "_and_source_values_are_all_exact_zero;",
  "within-tolerance_negative_domain_roundoff_is_also_zero"
)
p04_core_profile_alignment_key <- c(
  "profile_scope",
  "profile_variant",
  "profile_site",
  "held_out_site",
  "placement",
  "state_domain",
  "signal",
  "clock_bin"
)
p04_core_daily_timing_metrics <- c(
  "first_timing_above_250",
  "last_timing_above_250",
  "mean_timing_above_250"
)
p04_core_longest_metrics <- c(
  "longest_bout_above_250",
  "longest_bout_above_250_exact_only_sensitivity"
)

p04_core_abort <- function(...) {
  abort_pipeline(...)
}

p04_core_run_label <- function(run_label = "full") {
  if (
    !is.character(run_label) ||
      length(run_label) != 1L ||
      is.na(run_label) ||
      !nzchar(trimws(run_label)) ||
      !grepl("^[A-Za-z0-9._-]+$", trimws(run_label))
  ) {
    p04_core_abort("`run_label` must be one safe non-empty label")
  }
  trimws(run_label)
}

p04_core_path <- function(path, default, must_work = TRUE) {
  selected <- if (is.null(path)) default else path
  if (
    !is.character(selected) ||
      length(selected) != 1L ||
      is.na(selected) ||
      !nzchar(trimws(selected))
  ) {
    p04_core_abort("Verifier paths must be one non-empty character value")
  }
  normalizePath(
    trimws(selected),
    winslash = "/",
    mustWork = must_work
  )
}

p04_core_layout <- function(
  root,
  run_label = "full",
  metric_run_root = NULL,
  metric_manifest_path = NULL,
  coverage_run_root = NULL,
  profile_run_root = NULL,
  state_interval_manifest_path = NULL
) {
  root <- normalizePath(root, winslash = "/", mustWork = TRUE)
  run_label <- p04_core_run_label(run_label)
  paths <- pipeline_paths(root)
  suffix <- if (identical(run_label, "full")) {
    ""
  } else {
    paste0("_", run_label)
  }
  metric_default <- if (identical(run_label, "full")) {
    paths$metrics
  } else {
    file.path(paths$metrics, "runs", run_label)
  }
  coverage_default <- if (identical(run_label, "full")) {
    paths$coverage
  } else {
    file.path(paths$coverage, "runs", run_label)
  }
  profile_default <- if (identical(run_label, "full")) {
    paths$profiles
  } else {
    file.path(paths$profiles, "runs", run_label)
  }
  state_manifest_default <- file.path(
    paths$manifests,
    paste0("state_interval_artifacts", suffix, ".csv")
  )
  list(
    root = root,
    run_label = run_label,
    paths = paths,
    metric_run_root = p04_core_path(
      metric_run_root,
      metric_default
    ),
    metric_manifest_path = p04_core_path(
      metric_manifest_path,
      file.path(paths$manifests, paste0("metric_artifacts", suffix, ".csv"))
    ),
    coverage_run_root = p04_core_path(
      coverage_run_root,
      coverage_default
    ),
    profile_run_root = p04_core_path(
      profile_run_root,
      profile_default
    ),
    state_interval_manifest_path = p04_core_path(
      state_interval_manifest_path,
      state_manifest_default
    )
  )
}

p04_core_normalise_placements <- function(
  placements = c("chest", "glasses")
) {
  placements <- sort(unique(trimws(as.character(placements))))
  if (
    length(placements) != 2L ||
      anyNA(placements) ||
      any(!nzchar(placements)) ||
      any(!grepl("^[A-Za-z0-9._-]+$", placements))
  ) {
    p04_core_abort(
      paste0(
        "The exact 31-artifact contract requires exactly two safe ",
        "placement labels"
      )
    )
  }
  placements
}

p04_core_output_paths <- function(metric_run_root, placement) {
  prefix <- paste0("metrics_", placement, "_")
  c(
    participant_day_metrics_rds = file.path(
      metric_run_root,
      paste0(prefix, "participant_day.rds")
    ),
    participant_day_metrics_csv = file.path(
      metric_run_root,
      paste0(prefix, "participant_day.csv")
    ),
    participant_is_iv_rds = file.path(
      metric_run_root,
      paste0(prefix, "participant.rds")
    ),
    participant_is_iv_csv = file.path(
      metric_run_root,
      paste0(prefix, "participant.csv")
    ),
    complete_30_minute_arithmetic_medi_grid_rds = file.path(
      metric_run_root,
      paste0(prefix, "30_minute.rds")
    ),
    complete_30_minute_arithmetic_medi_grid_csv = file.path(
      metric_run_root,
      paste0(prefix, "30_minute.csv")
    ),
    complete_one_hour_geometric_medi_grid_rds = file.path(
      metric_run_root,
      paste0(prefix, "one_hour.rds")
    ),
    complete_one_hour_geometric_medi_grid_csv = file.path(
      metric_run_root,
      paste0(prefix, "one_hour.csv")
    ),
    long_metric_values = file.path(
      metric_run_root,
      paste0(prefix, "values_long.csv")
    ),
    metric_admissibility = file.path(
      metric_run_root,
      paste0(prefix, "admissibility.csv")
    ),
    metric_support_diagnostics = file.path(
      metric_run_root,
      paste0(prefix, "support_diagnostics.csv")
    ),
    metric_censoring_diagnostics = file.path(
      metric_run_root,
      paste0(prefix, "censoring_diagnostics.csv")
    ),
    metric_gap_diagnostics = file.path(
      metric_run_root,
      paste0(prefix, "gap_diagnostics.csv")
    ),
    metric_numerical_zero_audit = file.path(
      metric_run_root,
      paste0(prefix, "numerical_zero_audit.csv")
    )
  )
}

p04_core_expected_artifacts <- function(metric_run_root, placements) {
  placement_rows <- lapply(placements, function(placement) {
    paths <- p04_core_output_paths(metric_run_root, placement)
    tibble::tibble(
      placement = placement,
      artifact_type = names(paths),
      path = unname(paths)
    )
  })
  combined <- tibble::tibble(
    placement = NA_character_,
    artifact_type = c(
      "metric_derivation_settings",
      "state_support_candidate_diagnostics",
      "metric_state_interval_inputs"
    ),
    path = file.path(
      metric_run_root,
      c(
        "metric_derivation_settings.csv",
        "state_support_candidate_diagnostics.csv",
        "metric_state_interval_inputs.csv"
      )
    )
  )
  dplyr::bind_rows(placement_rows, list(combined)) |>
    dplyr::mutate(
      path = vapply(
        .data$path,
        normalizePath,
        character(1),
        winslash = "/",
        mustWork = FALSE
      )
    ) |>
    dplyr::arrange(.data$artifact_type, .data$path)
}

p04_core_read_csv <- function(path) {
  header <- names(readr::read_csv(
    path,
    n_max = 0L,
    show_col_types = FALSE,
    progress = FALSE,
    col_types = readr::cols(.default = readr::col_character())
  ))
  character_columns <- c(
    "run_label",
    "status",
    "site",
    "Id",
    "position",
    "placement",
    "profile_variant",
    "profile_scope",
    "profile_site",
    "held_out_site",
    "state_domain",
    "signal",
    "metric_map",
    "map_application",
    "relevance_source",
    "metric",
    "analysis_unit",
    "units",
    "failure_reason",
    "measurement_construct",
    "longest_bout_censor_reason",
    "longest_bout_estimate_interpretation",
    "longest_bout_observed_value_interpretation",
    "longest_bout_possible_bound_interpretation",
    "estimate_interpretation",
    "artifact_type",
    "producer",
    "path",
    "sha256",
    "coverage_path",
    "coverage_sha256",
    "reference_profiles_path",
    "reference_profiles_sha256",
    "timing_exceedance_distributions_path",
    "timing_exceedance_distributions_sha256",
    "relevance_maps_path",
    "relevance_maps_sha256",
    "state_interval_path",
    "state_interval_sha256",
    "state_interval_manifest_path",
    "state_interval_manifest_sha256",
    "interval_kind",
    "timing_exceedance_comparison",
    "timing_exceedance_aggregation",
    "timing_exceedance_application",
    "probability_aggregation",
    "probability_unit",
    "exceedance_comparison",
    "longest_bout_primary",
    "longest_bout_missing_rule",
    "longest_bout_possible_bound"
  )
  logical_columns <- c(
    "estimable",
    "descriptive_nonconfirmatory",
    "left_censored",
    "right_censored",
    "any_censored",
    "state_domain_complete",
    "passes_ordinary_support",
    "passes_medi_profile_support",
    "passes_light_profile_support",
    "support_threshold_enforced",
    "ratio_scaled_or_weighted",
    "timing_threshold_observed",
    "first_timing_left_censored",
    "last_timing_right_censored",
    "strict_first_boundary_gap",
    "strict_last_boundary_gap",
    "longest_bout_censored",
    "longest_bout_exact_identifiable",
    "longest_bout_missing_invalid_breaks_runs",
    "longest_bout_day_boundary_contact",
    "longest_bout_above_250_exact_identifiable",
    "longest_bout_above_250_censored",
    "longest_bout_above_250_missing_invalid_breaks_runs",
    "longest_bout_above_250_day_boundary_contact",
    "missing_invalid_breaks_runs",
    "exact_identifiable",
    "longest_bout_exact_only_sensitivity",
    "mder_ratio_scaled_or_weighted",
    "m10_wraps_midnight",
    "l10_wraps_midnight",
    "value_correction_allowed",
    "ratio_correction_allowed",
    "paired_channel_required",
    "map_estimable",
    "profile_supported",
    "profile_estimable"
  )
  date_columns <- "local_date"
  datetime_columns <- c(
    "longest_bout_above_250_onset_utc",
    "longest_bout_above_250_offset_utc",
    "longest_bout_winner_onset_utc",
    "longest_bout_winner_offset_utc"
  )
  parsers <- list()
  for (column in intersect(character_columns, header)) {
    parsers[[column]] <- readr::col_character()
  }
  for (column in intersect(logical_columns, header)) {
    parsers[[column]] <- readr::col_logical()
  }
  for (column in intersect(date_columns, header)) {
    parsers[[column]] <- readr::col_date()
  }
  for (column in intersect(datetime_columns, header)) {
    parsers[[column]] <- readr::col_datetime(format = "")
  }
  col_types <- do.call(
    readr::cols,
    c(list(.default = readr::col_guess()), parsers)
  )
  readr::read_csv(
    path,
    show_col_types = FALSE,
    progress = FALSE,
    col_types = col_types
  )
}

p04_core_key <- function(data, columns) {
  missing <- setdiff(columns, names(data))
  if (length(missing) > 0L) {
    p04_core_abort(
      "Verification table is missing key column(s): %s",
      paste(missing, collapse = ", ")
    )
  }
  values <- lapply(data[columns], function(value) {
    output <- as.character(value)
    output[is.na(output)] <- "<NA>"
    output
  })
  do.call(paste, c(values, sep = "\034"))
}

p04_core_assert_unique <- function(data, columns, object) {
  key <- p04_core_key(data, columns)
  if (anyDuplicated(key)) {
    p04_core_abort("%s has duplicate key rows", object)
  }
  invisible(data)
}

p04_core_vector_equal <- function(
  observed,
  expected,
  tolerance = 1e-10
) {
  if (
    length(observed) != length(expected) ||
      !identical(
        unname(is.na(observed)),
        unname(is.na(expected))
      )
  ) {
    return(FALSE)
  }
  keep <- !is.na(observed)
  if (!any(keep)) {
    return(TRUE)
  }
  if (
    (is.numeric(observed) ||
      is.integer(observed) ||
      inherits(observed, "Date") ||
      inherits(observed, "POSIXt")) &&
      (is.numeric(expected) ||
        is.integer(expected) ||
        inherits(expected, "Date") ||
        inherits(expected, "POSIXt"))
  ) {
    left <- as.numeric(observed[keep])
    right <- as.numeric(expected[keep])
    return(all(
      abs(left - right) <= tolerance * pmax(1, abs(left), abs(right))
    ))
  }
  if (is.logical(observed) && is.logical(expected)) {
    return(identical(
      unname(observed[keep]),
      unname(expected[keep])
    ))
  }
  identical(
    unname(as.character(observed[keep])),
    unname(as.character(expected[keep]))
  )
}

p04_core_assert_columns_equal <- function(
  observed,
  expected,
  columns,
  object,
  tolerance = 1e-10
) {
  missing <- union(
    setdiff(columns, names(observed)),
    setdiff(columns, names(expected))
  )
  if (length(missing) > 0L) {
    p04_core_abort(
      "%s is missing comparison column(s): %s",
      object,
      paste(missing, collapse = ", ")
    )
  }
  if (nrow(observed) != nrow(expected)) {
    p04_core_abort(
      "%s row count differs: observed %d, expected %d",
      object,
      nrow(observed),
      nrow(expected)
    )
  }
  unequal <- columns[
    !vapply(
      columns,
      function(column) {
        p04_core_vector_equal(
          observed[[column]],
          expected[[column]],
          tolerance = tolerance
        )
      },
      logical(1)
    )
  ]
  if (length(unequal) > 0L) {
    p04_core_abort(
      "%s disagrees in column(s): %s",
      object,
      paste(unequal, collapse = ", ")
    )
  }
  invisible(TRUE)
}

p04_core_arrange_by_key <- function(data, key) {
  order_rows <- do.call(
    order,
    c(
      lapply(data[key], function(value) {
        output <- as.character(value)
        output[is.na(output)] <- "<NA>"
        output
      }),
      list(na.last = TRUE)
    )
  )
  data[order_rows, , drop = FALSE]
}

p04_core_assert_projection <- function(
  observed,
  expected,
  key,
  columns,
  object,
  tolerance = 1e-10
) {
  p04_core_assert_unique(observed, key, object)
  p04_core_assert_unique(expected, key, paste0("expected ", object))
  observed_key <- sort(p04_core_key(observed, key))
  expected_key <- sort(p04_core_key(expected, key))
  if (!identical(observed_key, expected_key)) {
    p04_core_abort("%s has a different key set", object)
  }
  observed <- p04_core_arrange_by_key(observed, key)
  expected <- p04_core_arrange_by_key(expected, key)
  p04_core_assert_columns_equal(
    observed,
    expected,
    columns = columns,
    object = object,
    tolerance = tolerance
  )
}

p04_core_cast_csv_like_rds <- function(csv, rds) {
  if (!identical(names(csv), names(rds))) {
    p04_core_abort("RDS and CSV column names or order differ")
  }
  output <- csv
  for (column in names(rds)) {
    reference <- rds[[column]]
    value <- output[[column]]
    output[[column]] <- if (inherits(reference, "Date")) {
      as.Date(value)
    } else if (inherits(reference, "POSIXct")) {
      as.POSIXct(value, tz = "UTC")
    } else if (is.integer(reference)) {
      as.integer(value)
    } else if (is.numeric(reference)) {
      as.numeric(value)
    } else if (is.logical(reference)) {
      as.logical(value)
    } else {
      as.character(value)
    }
  }
  output
}

p04_core_verify_manifest <- function(
  manifest_path,
  metric_run_root,
  placements
) {
  manifest <- p04_core_read_csv(manifest_path)
  assert_columns(
    manifest,
    c(
      "artifact_type",
      "path",
      "sha256",
      "bytes",
      "producer"
    ),
    object = "Preparation 04 artifact manifest"
  )
  if (nrow(manifest) != 31L) {
    p04_core_abort(
      "Preparation 04 manifest must contain exactly 31 artifacts; found %d",
      nrow(manifest)
    )
  }
  p04_core_assert_unique(
    manifest,
    "path",
    "Preparation 04 artifact manifest"
  )
  expected <- p04_core_expected_artifacts(metric_run_root, placements)
  observed <- manifest |>
    dplyr::transmute(
      artifact_type = as.character(.data$artifact_type),
      path = vapply(
        .data$path,
        normalizePath,
        character(1),
        winslash = "/",
        mustWork = FALSE
      )
    ) |>
    dplyr::arrange(.data$artifact_type, .data$path)
  if (
    !identical(observed$artifact_type, expected$artifact_type) ||
      !identical(observed$path, expected$path)
  ) {
    p04_core_abort(
      "Preparation 04 manifest does not match the exact 31-artifact path/type set"
    )
  }
  if (
    anyNA(manifest$producer) ||
      any(
        manifest$producer != "scripts/pipeline/build_metric_derivation.R"
      )
  ) {
    p04_core_abort(
      "Preparation 04 manifest has an unexpected artifact producer"
    )
  }
  for (index in seq_len(nrow(manifest))) {
    path <- as.character(manifest$path[[index]])
    if (!file.exists(path)) {
      p04_core_abort("Manifest-listed artifact is missing: %s", path)
    }
    actual_hash <- artifact_sha256(path)
    if (!identical(actual_hash, as.character(manifest$sha256[[index]]))) {
      p04_core_abort("Manifest hash mismatch for %s", path)
    }
    actual_bytes <- unname(file.info(path)$size)
    if (
      !is.finite(manifest$bytes[[index]]) ||
        as.numeric(manifest$bytes[[index]]) != actual_bytes
    ) {
      p04_core_abort("Manifest byte count mismatch for %s", path)
    }
    if (grepl("[.]csv$", path)) {
      data <- p04_core_read_csv(path)
      if (
        !"rows" %in% names(manifest) ||
          !"columns" %in% names(manifest) ||
          !is.finite(manifest$rows[[index]]) ||
          !is.finite(manifest$columns[[index]]) ||
          as.numeric(manifest$rows[[index]]) != nrow(data) ||
          as.numeric(manifest$columns[[index]]) != ncol(data)
      ) {
        p04_core_abort(
          "Manifest CSV dimensions mismatch for %s",
          path
        )
      }
    }
  }
  manifest
}

p04_core_read_outputs <- function(metric_run_root, placements) {
  outputs <- list()
  for (placement in placements) {
    paths <- p04_core_output_paths(metric_run_root, placement)
    daily_rds <- readRDS(paths[["participant_day_metrics_rds"]])
    participant_rds <- readRDS(paths[["participant_is_iv_rds"]])
    thirty_rds <- readRDS(
      paths[["complete_30_minute_arithmetic_medi_grid_rds"]]
    )
    hourly_rds <- readRDS(
      paths[["complete_one_hour_geometric_medi_grid_rds"]]
    )
    daily_csv <- p04_core_cast_csv_like_rds(
      p04_core_read_csv(paths[["participant_day_metrics_csv"]]),
      daily_rds
    )
    participant_csv <- p04_core_cast_csv_like_rds(
      p04_core_read_csv(paths[["participant_is_iv_csv"]]),
      participant_rds
    )
    thirty_csv <- p04_core_cast_csv_like_rds(
      p04_core_read_csv(
        paths[["complete_30_minute_arithmetic_medi_grid_csv"]]
      ),
      thirty_rds
    )
    hourly_csv <- p04_core_cast_csv_like_rds(
      p04_core_read_csv(
        paths[["complete_one_hour_geometric_medi_grid_csv"]]
      ),
      hourly_rds
    )
    pairs <- list(
      daily = list(rds = daily_rds, csv = daily_csv),
      participant = list(rds = participant_rds, csv = participant_csv),
      thirty = list(rds = thirty_rds, csv = thirty_csv),
      hourly = list(rds = hourly_rds, csv = hourly_csv)
    )
    for (label in names(pairs)) {
      pair <- pairs[[label]]
      p04_core_assert_columns_equal(
        pair$rds,
        pair$csv,
        columns = names(pair$rds),
        object = paste0(placement, " ", label, " RDS/CSV pair")
      )
    }
    outputs[[placement]] <- list(
      paths = paths,
      daily = tibble::as_tibble(daily_rds),
      participant = tibble::as_tibble(participant_rds),
      thirty = tibble::as_tibble(thirty_rds),
      hourly = tibble::as_tibble(hourly_rds),
      long = p04_core_read_csv(paths[["long_metric_values"]]),
      admissibility = p04_core_read_csv(
        paths[["metric_admissibility"]]
      ),
      support = p04_core_read_csv(
        paths[["metric_support_diagnostics"]]
      ),
      censoring = p04_core_read_csv(
        paths[["metric_censoring_diagnostics"]]
      ),
      gap = p04_core_read_csv(paths[["metric_gap_diagnostics"]]),
      numerical_zero = p04_core_read_csv(
        paths[["metric_numerical_zero_audit"]]
      )
    )
  }
  outputs
}

p04_core_verify_dimensions <- function(
  output,
  settings_row,
  placement
) {
  daily <- output$daily
  participant <- output$participant
  thirty <- output$thirty
  hourly <- output$hourly
  long <- output$long
  support <- output$support
  admissibility <- output$admissibility
  censoring <- output$censoring
  gap <- output$gap
  numerical_zero <- output$numerical_zero

  assert_columns(
    daily,
    p04_core_day_key,
    object = paste0(placement, " participant-day metrics")
  )
  assert_columns(
    participant,
    p04_core_participant_key,
    object = paste0(placement, " participant metrics")
  )
  p04_core_assert_unique(
    daily,
    p04_core_day_key,
    paste0(placement, " participant-day metrics")
  )
  p04_core_assert_unique(
    participant,
    p04_core_participant_key,
    paste0(placement, " participant metrics")
  )
  p04_core_assert_unique(
    thirty,
    c(p04_core_day_key, "clock_bin"),
    paste0(placement, " 30-minute metrics")
  )
  p04_core_assert_unique(
    hourly,
    c(p04_core_day_key, "clock_hour"),
    paste0(placement, " hourly metrics")
  )
  expected_days <- as.integer(settings_row$eligible_participant_days[[1L]])
  expected_participants <- as.integer(settings_row$participants[[1L]])
  if (
    nrow(daily) != expected_days ||
      nrow(participant) != expected_participants ||
      nrow(thirty) != expected_days * 48L ||
      nrow(hourly) != expected_days * 24L
  ) {
    p04_core_abort(
      "%s output dimensions do not reconcile to metric settings",
      placement
    )
  }
  assert_columns(
    numerical_zero,
    c(
      p04_core_day_key,
      "metric",
      "analysis_unit",
      "clock_hour",
      "raw_backtransformed_value_lx",
      "normalized_value_lx",
      "numerical_zero_tolerance_lx",
      "source_all_zero",
      "source_valid_minutes",
      "source_zero_minutes",
      "source_positive_minutes",
      "source_missing_minutes",
      "numerical_zero_decision_id",
      "numerical_zero_rule",
      "raw_value_preserved"
    ),
    object = paste0(placement, " numerical-zero audit")
  )
  if (nrow(numerical_zero) > 0L) {
    invalid_clock_key <-
      (!numerical_zero$analysis_unit %in% c(
        "participant_day",
        "participant_day_window",
        "participant_hour"
      )) |
      (numerical_zero$analysis_unit %in% c(
        "participant_day",
        "participant_day_window"
      ) &
        !is.na(numerical_zero$clock_hour)) |
      (numerical_zero$analysis_unit == "participant_hour" &
        (
          is.na(numerical_zero$clock_hour) |
            numerical_zero$clock_hour < 0L |
            numerical_zero$clock_hour > 23L |
            numerical_zero$clock_hour !=
              as.integer(numerical_zero$clock_hour)
        ))
    if (anyNA(invalid_clock_key) || any(invalid_clock_key)) {
      p04_core_abort(
        "%s numerical-zero audit has an invalid analysis-unit/clock key",
        placement
      )
    }
    numerical_zero_key <- numerical_zero
    numerical_zero_key$clock_hour_key <- ifelse(
      numerical_zero_key$analysis_unit %in% c(
        "participant_day",
        "participant_day_window"
      ),
      -1L,
      as.integer(numerical_zero_key$clock_hour)
    )
    p04_core_assert_unique(
      numerical_zero_key,
      c(
        p04_core_day_key,
        "metric",
        "analysis_unit",
        "clock_hour_key"
      ),
      paste0(placement, " numerical-zero audit")
    )
    invalid_numerical_zero <-
      !is.finite(numerical_zero$raw_backtransformed_value_lx) |
      numerical_zero$raw_backtransformed_value_lx == 0 |
      numerical_zero$normalized_value_lx != 0 |
      !is.finite(numerical_zero$numerical_zero_tolerance_lx) |
      numerical_zero$numerical_zero_tolerance_lx <= 0 |
      abs(numerical_zero$raw_backtransformed_value_lx) >
        numerical_zero$numerical_zero_tolerance_lx |
      (numerical_zero$raw_backtransformed_value_lx > 0 &
        !numerical_zero$source_all_zero) |
      numerical_zero$source_valid_minutes !=
        numerical_zero$source_zero_minutes +
          numerical_zero$source_positive_minutes |
      numerical_zero$numerical_zero_decision_id != "METRIC-011" |
      !numerical_zero$raw_value_preserved
    if (anyNA(invalid_numerical_zero) || any(invalid_numerical_zero)) {
      p04_core_abort(
        "%s numerical-zero audit violates METRIC-011",
        placement
      )
    }
  }

  daily_long <- long |>
    dplyr::filter(.data$analysis_unit == "participant_day")
  participant_long <- long |>
    dplyr::filter(.data$analysis_unit == "participant")
  p04_core_assert_unique(
    daily_long,
    c(
      p04_core_day_key,
      "profile_variant",
      "analysis_unit",
      "metric"
    ),
    paste0(placement, " participant-day long metrics")
  )
  p04_core_assert_unique(
    participant_long,
    c(
      p04_core_participant_key,
      "profile_variant",
      "analysis_unit",
      "metric"
    ),
    paste0(placement, " participant long metrics")
  )
  day_counts <- table(p04_core_key(daily_long, p04_core_day_key))
  if (
    length(day_counts) != nrow(daily) ||
      length(unique(as.integer(day_counts))) != 1L
  ) {
    p04_core_abort(
      "%s long metrics are not rectangular over participant-days",
      placement
    )
  }
  if (
    !identical(
      sort(unique(p04_core_key(daily_long, p04_core_day_key))),
      sort(p04_core_key(daily, p04_core_day_key))
    ) ||
      nrow(support) != nrow(daily_long) ||
      nrow(admissibility) != nrow(long) ||
      nrow(censoring) != nrow(daily) ||
      nrow(gap) != nrow(daily)
  ) {
    p04_core_abort(
      "%s long/support/admissibility/diagnostic dimensions disagree",
      placement
    )
  }
  if (
    any(grepl("L5", names(daily), fixed = TRUE)) ||
      any(grepl("L5", as.character(long$metric), fixed = TRUE))
  ) {
    p04_core_abort("%s outputs contain excluded L5 content", placement)
  }
  tibble::tibble(
    placement = placement,
    participant_days = nrow(daily),
    participants = nrow(participant),
    thirty_minute_rows = nrow(thirty),
    hourly_rows = nrow(hourly),
    participant_day_long_rows = nrow(daily_long),
    participant_long_rows = nrow(participant_long)
  )
}

p04_core_verify_cross_artifact_tables <- function(output, placement) {
  long <- output$long
  support <- output$support
  admissibility <- output$admissibility
  daily_long <- long |>
    dplyr::filter(.data$analysis_unit == "participant_day")
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
  expected_support <- daily_long |>
    dplyr::select(dplyr::all_of(support_columns))
  p04_core_assert_projection(
    support,
    expected_support,
    key = c(p04_core_day_key, "profile_variant", "metric"),
    columns = support_columns,
    object = paste0(placement, " support projection")
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
  expected_admissibility <- long |>
    dplyr::select(dplyr::all_of(admissibility_columns))
  p04_core_assert_projection(
    admissibility,
    expected_admissibility,
    key = c(
      p04_core_day_key,
      "profile_variant",
      "analysis_unit",
      "metric"
    ),
    columns = admissibility_columns,
    object = paste0(placement, " admissibility projection")
  )
  invisible(TRUE)
}

p04_core_join_daily_metric <- function(daily, long, metric) {
  selected <- long |>
    dplyr::filter(
      .data$analysis_unit == "participant_day",
      .data$metric == .env$metric
    )
  p04_core_assert_unique(
    selected,
    p04_core_day_key,
    paste0(metric, " long metric")
  )
  if (
    !identical(
      sort(p04_core_key(selected, p04_core_day_key)),
      sort(p04_core_key(daily, p04_core_day_key))
    )
  ) {
    p04_core_abort("%s does not cover every participant-day", metric)
  }
  selected
}

p04_core_verify_longest_invariants <- function(output, placement) {
  daily <- output$daily
  long <- output$long
  censoring <- output$censoring
  required_daily <- c(
    p04_core_day_key,
    "longest_bout_above_250_h",
    "longest_bout_above_250_observed_h",
    "longest_bout_above_250_observed_lower_bound_h",
    "longest_bout_above_250_possible_h",
    "longest_bout_above_250_possible_upper_bound_h",
    "longest_bout_above_250_exact_only_sensitivity_h",
    "longest_bout_above_250_exact_identifiable",
    "longest_bout_above_250_censored",
    "longest_bout_above_250_missing_invalid_breaks_runs",
    "longest_bout_above_250_estimate_interpretation",
    "longest_bout_above_250_censor_reason"
  )
  required_censor <- c(
    p04_core_day_key,
    "longest_bout_censored",
    "longest_bout_observed_h",
    "longest_bout_observed_lower_bound_h",
    "longest_bout_possible_h",
    "longest_bout_possible_upper_bound_h",
    "longest_bout_exact_only_sensitivity_h",
    "longest_bout_exact_identifiable",
    "longest_bout_missing_invalid_breaks_runs",
    "longest_bout_observed_value_interpretation",
    "longest_bout_censor_reason"
  )
  assert_columns(
    daily,
    required_daily,
    object = paste0(placement, " daily longest-bout fields")
  )
  assert_columns(
    censoring,
    required_censor,
    object = paste0(placement, " longest-bout censoring fields")
  )
  observed <- daily$longest_bout_above_250_observed_lower_bound_h
  possible <- daily$longest_bout_above_250_possible_upper_bound_h
  exact <- daily$longest_bout_above_250_exact_identifiable
  censored <- daily$longest_bout_above_250_censored
  if (
    any(!is.finite(observed) | observed < 0) ||
      any(!is.finite(possible) | possible < observed) ||
      anyNA(exact) ||
      anyNA(censored) ||
      any(exact != !censored) ||
      any(censored != (possible > observed + 1e-12)) ||
      !p04_core_vector_equal(
        daily$longest_bout_above_250_h,
        observed
      ) ||
      !p04_core_vector_equal(
        daily$longest_bout_above_250_observed_h,
        observed
      ) ||
      !p04_core_vector_equal(
        daily$longest_bout_above_250_possible_h,
        possible
      ) ||
      anyNA(daily$longest_bout_above_250_missing_invalid_breaks_runs) ||
      !all(daily$longest_bout_above_250_missing_invalid_breaks_runs) ||
      any(
        daily$longest_bout_above_250_estimate_interpretation !=
          "observed_lower_bound"
      )
  ) {
    p04_core_abort(
      "%s whole-cohort longest-bout lower/upper invariants failed",
      placement
    )
  }
  expected_exact_value <- ifelse(exact, observed, NA_real_)
  expected_reason <- ifelse(
    censored,
    "missing_or_invalid_minutes_allow_longer_bout",
    NA_character_
  )
  if (
    !p04_core_vector_equal(
      daily$longest_bout_above_250_exact_only_sensitivity_h,
      expected_exact_value
    ) ||
      !p04_core_vector_equal(
        daily$longest_bout_above_250_censor_reason,
        expected_reason
      )
  ) {
    p04_core_abort(
      "%s longest-bout exact-only sensitivity invariants failed",
      placement
    )
  }

  primary <- p04_core_join_daily_metric(
    daily,
    long,
    "longest_bout_above_250"
  )
  exact_only <- p04_core_join_daily_metric(
    daily,
    long,
    "longest_bout_above_250_exact_only_sensitivity"
  )
  daily_sorted <- p04_core_arrange_by_key(daily, p04_core_day_key)
  primary <- p04_core_arrange_by_key(primary, p04_core_day_key)
  exact_only <- p04_core_arrange_by_key(exact_only, p04_core_day_key)
  censoring <- p04_core_arrange_by_key(censoring, p04_core_day_key)
  if (
    !p04_core_vector_equal(
      primary$value,
      daily_sorted$longest_bout_above_250_h
    ) ||
      anyNA(primary$estimable) ||
      !all(primary$estimable) ||
      any(!is.na(primary$failure_reason)) ||
      !p04_core_vector_equal(
        primary$any_censored,
        daily_sorted$longest_bout_above_250_censored
      ) ||
      !p04_core_vector_equal(
        exact_only$value,
        daily_sorted$longest_bout_above_250_exact_only_sensitivity_h
      ) ||
      !p04_core_vector_equal(
        exact_only$estimable,
        daily_sorted$longest_bout_above_250_exact_identifiable
      ) ||
      !p04_core_vector_equal(
        exact_only$failure_reason,
        ifelse(
          daily_sorted$longest_bout_above_250_exact_identifiable,
          NA_character_,
          "not_exactly_identifiable_due_to_missing_or_invalid_minutes"
        )
      ) ||
      !p04_core_vector_equal(
        primary$estimate_interpretation,
        rep("observed_lower_bound", nrow(primary))
      ) ||
      !p04_core_vector_equal(
        primary$missing_invalid_breaks_runs,
        rep(TRUE, nrow(primary))
      ) ||
      !p04_core_vector_equal(
        primary$exact_identifiable,
        daily_sorted$longest_bout_above_250_exact_identifiable
      ) ||
      !p04_core_vector_equal(
        censoring$longest_bout_observed_lower_bound_h,
        daily_sorted$longest_bout_above_250_h
      ) ||
      !p04_core_vector_equal(
        censoring$longest_bout_possible_upper_bound_h,
        daily_sorted$longest_bout_above_250_possible_upper_bound_h
      ) ||
      !p04_core_vector_equal(
        censoring$longest_bout_exact_only_sensitivity_h,
        daily_sorted$longest_bout_above_250_exact_only_sensitivity_h
      ) ||
      !p04_core_vector_equal(
        censoring$longest_bout_censored,
        daily_sorted$longest_bout_above_250_censored
      ) ||
      !p04_core_vector_equal(
        censoring$longest_bout_exact_identifiable,
        daily_sorted$longest_bout_above_250_exact_identifiable
      ) ||
      !p04_core_vector_equal(
        censoring$longest_bout_missing_invalid_breaks_runs,
        rep(TRUE, nrow(censoring))
      ) ||
      !p04_core_vector_equal(
        censoring$longest_bout_observed_value_interpretation,
        rep("observed_lower_bound", nrow(censoring))
      ) ||
      !p04_core_vector_equal(
        censoring$longest_bout_censor_reason,
        daily_sorted$longest_bout_above_250_censor_reason
      )
  ) {
    p04_core_abort(
      "%s longest-bout daily/long/censoring cross-check failed",
      placement
    )
  }
  invisible(TRUE)
}

p04_core_verify_timing_invariants <- function(output, placement) {
  daily <- output$daily
  long <- output$long
  censoring <- output$censoring
  mapping <- c(
    first_timing_above_250 = "first_timing_above_250_clock_minute",
    last_timing_above_250 = "last_timing_above_250_clock_minute",
    mean_timing_above_250 = "mean_timing_above_250_clock_minute"
  )
  assert_columns(
    daily,
    unname(mapping),
    object = paste0(placement, " timing fields")
  )
  assert_columns(
    censoring,
    c(
      p04_core_day_key,
      "timing_threshold_observed",
      "first_timing_left_censored",
      "last_timing_right_censored",
      "strict_first_boundary_gap",
      "strict_last_boundary_gap",
      "timing_circular_resultant"
    ),
    object = paste0(placement, " timing censoring fields")
  )
  daily_sorted <- p04_core_arrange_by_key(daily, p04_core_day_key)
  censoring <- p04_core_arrange_by_key(censoring, p04_core_day_key)
  for (metric in names(mapping)) {
    record <- p04_core_join_daily_metric(daily, long, metric)
    record <- p04_core_arrange_by_key(record, p04_core_day_key)
    if (
      !p04_core_vector_equal(
        record$value,
        daily_sorted[[mapping[[metric]]]]
      ) ||
        !identical(
          is.finite(record$value),
          as.logical(record$estimable)
        ) ||
        any(is.finite(record$value) & !is.na(record$failure_reason)) ||
        any(!is.finite(record$value) & is.na(record$failure_reason))
    ) {
      p04_core_abort(
        "%s %s value/reason consistency failed",
        placement,
        metric
      )
    }
  }
  first <- p04_core_join_daily_metric(
    daily,
    long,
    "first_timing_above_250"
  ) |>
    p04_core_arrange_by_key(p04_core_day_key)
  last <- p04_core_join_daily_metric(
    daily,
    long,
    "last_timing_above_250"
  ) |>
    p04_core_arrange_by_key(p04_core_day_key)
  if (
    !p04_core_vector_equal(
      first$left_censored,
      censoring$first_timing_left_censored
    ) ||
      !p04_core_vector_equal(
        last$right_censored,
        censoring$last_timing_right_censored
      )
  ) {
    p04_core_abort(
      "%s timing censor flags disagree across artifacts",
      placement
    )
  }
  invisible(TRUE)
}

p04_core_verify_settings_and_inputs <- function(
  layout,
  outputs,
  placements
) {
  settings_path <- file.path(
    layout$metric_run_root,
    "metric_derivation_settings.csv"
  )
  state_inputs_path <- file.path(
    layout$metric_run_root,
    "metric_state_interval_inputs.csv"
  )
  settings <- p04_core_read_csv(settings_path)
  state_inputs <- p04_core_read_csv(state_inputs_path)
  required_settings <- c(
    "run_label",
    "placement",
    "profile_variant",
    "coverage_path",
    "coverage_sha256",
    "state_interval_manifest_path",
    "state_interval_manifest_sha256",
    "reference_profiles_path",
    "reference_profiles_sha256",
    "timing_exceedance_distributions_path",
    "timing_exceedance_distributions_sha256",
    "relevance_maps_path",
    "relevance_maps_sha256",
    "timing_exceedance_threshold_lx",
    "timing_exceedance_comparison",
    "timing_exceedance_aggregation",
    "timing_exceedance_application",
    "dose_minimum_relevance_support",
    "minimum_circular_resultant",
    "numerical_zero_decision_id",
    "numerical_zero_status",
    "numerical_zero_scope",
    "numerical_zero_rule",
    "numerical_zero_tolerance_multiplier",
    "numerical_zero_positive_requires_all_source_zero",
    "numerical_zero_raw_value_preserved",
    "numerical_zero_reclassified_cells",
    "numerical_zero_zero_capable_model_rule",
    "numerical_zero_two_part_model_rule",
    "eligible_participant_days",
    "participants",
    "longest_bout_primary",
    "longest_bout_missing_rule",
    "longest_bout_possible_bound",
    "longest_bout_exact_only_sensitivity"
  )
  assert_columns(
    settings,
    required_settings,
    object = "Preparation 04 metric settings"
  )
  if (
    nrow(settings) != length(placements) ||
      !identical(sort(as.character(settings$placement)), placements)
  ) {
    p04_core_abort(
      "Preparation 04 settings do not contain exactly one row per placement"
    )
  }
  p04_core_assert_unique(
    settings,
    "placement",
    "Preparation 04 metric settings"
  )
  expected_aggregation <-
    "equal_days_within_participant_then_equal_participants"
  invalid_contract <-
    settings$run_label != layout$run_label |
    settings$timing_exceedance_threshold_lx != 250 |
    settings$timing_exceedance_comparison != "strict_greater_than" |
    settings$timing_exceedance_aggregation != expected_aggregation |
    settings$timing_exceedance_application != "support_only_no_value_scaling" |
    settings$numerical_zero_decision_id != "METRIC-011" |
    settings$numerical_zero_status != "author_approved" |
    settings$numerical_zero_scope !=
      "offset_geometric_mean_backtransforms" |
    settings$numerical_zero_rule != p04_core_numerical_zero_rule |
    settings$numerical_zero_tolerance_multiplier != 100 |
    !settings$numerical_zero_positive_requires_all_source_zero |
    !settings$numerical_zero_raw_value_preserved |
    settings$numerical_zero_zero_capable_model_rule !=
      "retain_participant_day_as_zero" |
    settings$numerical_zero_two_part_model_rule != paste0(
      "retain_in_zero_occurrence_component;exclude_only_from_",
      "strictly_positive_magnitude_component"
    ) |
    settings$longest_bout_primary !=
      "longest_observed_uninterrupted_above_250_lower_bound" |
    settings$longest_bout_missing_rule !=
      "missing_or_invalid_minutes_break_observed_runs" |
    settings$longest_bout_possible_bound !=
      "upper_bound_if_all_missing_or_invalid_minutes_qualified" |
    !settings$longest_bout_exact_only_sensitivity
  if (anyNA(invalid_contract) || any(invalid_contract)) {
    p04_core_abort(
      "Preparation 04 settings violate the approved timing/bout contract"
    )
  }
  for (index in seq_len(nrow(settings))) {
    row <- settings[index, , drop = FALSE]
    placement <- as.character(row$placement[[1L]])
    expected_coverage <- file.path(
      layout$coverage_run_root,
      paste0("light_", placement, "_coverage.rds")
    )
    input_paths <- c(
      coverage_path = as.character(row$coverage_path[[1L]]),
      reference_profiles_path = as.character(row$reference_profiles_path[[1L]]),
      timing_exceedance_distributions_path = as.character(row$timing_exceedance_distributions_path[[
        1L
      ]]),
      relevance_maps_path = as.character(row$relevance_maps_path[[1L]]),
      state_interval_manifest_path = as.character(row$state_interval_manifest_path[[
        1L
      ]])
    )
    expected_paths <- c(
      coverage_path = expected_coverage,
      reference_profiles_path = file.path(
        layout$profile_run_root,
        "reference_profiles.rds"
      ),
      timing_exceedance_distributions_path = file.path(
        layout$profile_run_root,
        "timing_exceedance_distributions.rds"
      ),
      relevance_maps_path = file.path(
        layout$profile_run_root,
        "metric_relevance_maps.rds"
      ),
      state_interval_manifest_path = layout$state_interval_manifest_path
    )
    if (
      !identical(
        vapply(
          input_paths,
          normalizePath,
          character(1),
          winslash = "/",
          mustWork = FALSE
        ),
        vapply(
          expected_paths,
          normalizePath,
          character(1),
          winslash = "/",
          mustWork = FALSE
        )
      )
    ) {
      p04_core_abort(
        "%s Preparation 04 settings point outside canonical verifier inputs",
        placement
      )
    }
    hash_columns <- c(
      coverage_path = "coverage_sha256",
      reference_profiles_path = "reference_profiles_sha256",
      timing_exceedance_distributions_path = "timing_exceedance_distributions_sha256",
      relevance_maps_path = "relevance_maps_sha256",
      state_interval_manifest_path = "state_interval_manifest_sha256"
    )
    for (name in names(hash_columns)) {
      path <- input_paths[[name]]
      recorded <- as.character(row[[hash_columns[[name]]]][[1L]])
      if (!file.exists(path) || artifact_sha256(path) != recorded) {
        p04_core_abort(
          "%s input hash mismatch for `%s`",
          placement,
          name
        )
      }
    }
    if (
      nrow(outputs[[placement]]$daily) !=
        as.integer(row$eligible_participant_days[[1L]]) ||
        nrow(outputs[[placement]]$numerical_zero) !=
          as.integer(row$numerical_zero_reclassified_cells[[1L]])
    ) {
      p04_core_abort(
        "%s settings participant-day count is stale",
        placement
      )
    }
  }

  assert_columns(
    state_inputs,
    c(
      "run_label",
      "profile_variant",
      "placement",
      "site",
      "interval_kind",
      "state_interval_path",
      "state_interval_sha256",
      "state_interval_manifest_path",
      "state_interval_manifest_sha256"
    ),
    object = "Preparation 04 state-interval inputs"
  )
  p04_core_assert_unique(
    state_inputs,
    c("placement", "site", "interval_kind"),
    "Preparation 04 state-interval inputs"
  )
  if (
    any(!state_inputs$placement %in% placements) ||
      any(!state_inputs$interval_kind %in% c("sleep", "wear")) ||
      any(state_inputs$run_label != layout$run_label)
  ) {
    p04_core_abort(
      "Preparation 04 state-interval input registry has invalid labels"
    )
  }
  for (index in seq_len(nrow(state_inputs))) {
    path <- as.character(state_inputs$state_interval_path[[index]])
    if (
      !file.exists(path) ||
        artifact_sha256(path) !=
          as.character(state_inputs$state_interval_sha256[[index]]) ||
        artifact_sha256(layout$state_interval_manifest_path) !=
          as.character(
            state_inputs$state_interval_manifest_sha256[[index]]
          )
    ) {
      p04_core_abort(
        "Preparation 04 state-interval input hash mismatch"
      )
    }
  }
  recorded_manifest_paths <- vapply(
    state_inputs$state_interval_manifest_path,
    normalizePath,
    character(1),
    winslash = "/",
    mustWork = TRUE
  )
  if (any(recorded_manifest_paths != layout$state_interval_manifest_path)) {
    p04_core_abort(
      "Preparation 04 state inputs point to a different interval manifest"
    )
  }
  state_manifest <- p04_core_read_csv(layout$state_interval_manifest_path)
  assert_columns(
    state_manifest,
    c(
      "site",
      "interval_kind",
      "artifact_type",
      "path",
      "sha256"
    ),
    object = "Preparation 01 state-interval manifest"
  )
  state_manifest <- state_manifest |>
    dplyr::filter(.data$interval_kind %in% c("sleep", "wear")) |>
    dplyr::transmute(
      .data$site,
      .data$interval_kind,
      state_interval_path = vapply(
        .data$path,
        normalizePath,
        character(1),
        winslash = "/",
        mustWork = TRUE
      ),
      state_interval_sha256 = as.character(.data$sha256)
    )
  p04_core_assert_unique(
    state_manifest,
    c("site", "interval_kind"),
    "Preparation 01 state-interval manifest"
  )
  registered <- state_inputs |>
    dplyr::transmute(
      .data$site,
      .data$interval_kind,
      state_interval_path = vapply(
        .data$state_interval_path,
        normalizePath,
        character(1),
        winslash = "/",
        mustWork = TRUE
      ),
      state_interval_sha256 = as.character(.data$state_interval_sha256)
    ) |>
    dplyr::distinct()
  expected_registered <- state_manifest |>
    dplyr::semi_join(
      registered,
      by = c("site", "interval_kind")
    )
  p04_core_assert_projection(
    registered,
    expected_registered,
    key = c("site", "interval_kind"),
    columns = c(
      "site",
      "interval_kind",
      "state_interval_path",
      "state_interval_sha256"
    ),
    object = "Preparation 04 versus Preparation 01 state inputs"
  )
  list(settings = settings, state_inputs = state_inputs)
}

p04_core_verify_timing_map_linkage <- function(
  maps,
  distributions,
  placements,
  tolerance = 1e-10
) {
  required_map <- c(
    p04_core_profile_alignment_key,
    "metric_map",
    "map_application",
    "relevance_source",
    "relevance_mass",
    "relevance_weight",
    "map_estimable",
    "value_correction_allowed",
    "ratio_correction_allowed",
    "paired_channel_required",
    "exceedance_probability",
    "exceedance_threshold_lx",
    "exceedance_comparison",
    "probability_unit",
    "probability_aggregation"
  )
  required_distribution <- c(
    p04_core_profile_alignment_key,
    "exceedance_probability",
    "supported_exceedance_probability",
    "probability_weight",
    "profile_estimable",
    "exceedance_threshold_lx",
    "exceedance_comparison",
    "probability_unit",
    "probability_aggregation"
  )
  assert_columns(maps, required_map, object = "fixed metric relevance maps")
  assert_columns(
    distributions,
    required_distribution,
    object = "fixed timing exceedance distributions"
  )
  timing <- maps |>
    dplyr::filter(.data$metric_map == "timing_above_250")
  distributions <- distributions |>
    dplyr::filter(
      .data$placement %in% placements,
      .data$state_domain == "full_day",
      .data$signal == "MEDI"
    )
  timing <- timing |>
    dplyr::filter(.data$placement %in% placements)
  if (nrow(timing) != nrow(distributions) || nrow(timing) == 0L) {
    p04_core_abort(
      "Timing relevance maps do not have one row per distribution row"
    )
  }
  map_key <- p04_core_key(timing, p04_core_profile_alignment_key)
  distribution_key <- p04_core_key(
    distributions,
    p04_core_profile_alignment_key
  )
  if (
    anyDuplicated(map_key) ||
      anyDuplicated(distribution_key) ||
      !identical(sort(map_key), sort(distribution_key))
  ) {
    p04_core_abort(
      "Timing relevance maps and distributions have different keys"
    )
  }
  distributions <- distributions[match(map_key, distribution_key), ]
  invalid_metadata <-
    timing$state_domain != "full_day" |
    timing$signal != "MEDI" |
    timing$map_application != "support_only" |
    timing$relevance_source != "participant_balanced_exceedance_distribution" |
    timing$exceedance_threshold_lx != 250 |
    timing$exceedance_comparison != "strict_greater_than" |
    timing$probability_unit != "proportion_of_valid_wall_minutes" |
    timing$probability_aggregation !=
      paste0(
        "valid_minutes_within_participant_day_bin;",
        "equal_days_within_participant_bin;",
        "equal_participants_within_profile_bin"
      ) |
    timing$value_correction_allowed |
    timing$ratio_correction_allowed |
    timing$paired_channel_required
  if (anyNA(invalid_metadata) || any(invalid_metadata)) {
    p04_core_abort(
      "Timing map metadata does not enforce strict >250 support-only use"
    )
  }
  invalid_distribution_metadata <-
    distributions$exceedance_threshold_lx != 250 |
    distributions$exceedance_comparison != "strict_greater_than" |
    distributions$probability_unit != "proportion_of_valid_wall_minutes" |
    distributions$probability_aggregation !=
      paste0(
        "valid_minutes_within_participant_day_bin;",
        "equal_days_within_participant_bin;",
        "equal_participants_within_profile_bin"
      )
  if (
    anyNA(invalid_distribution_metadata) ||
      any(invalid_distribution_metadata)
  ) {
    p04_core_abort(
      "Fixed timing distributions do not encode strict >250 balancing"
    )
  }
  if (
    !p04_core_vector_equal(
      timing$exceedance_probability,
      distributions$exceedance_probability,
      tolerance
    ) ||
      !p04_core_vector_equal(
        timing$relevance_mass,
        distributions$supported_exceedance_probability,
        tolerance
      ) ||
      !p04_core_vector_equal(
        timing$relevance_weight,
        distributions$probability_weight,
        tolerance
      ) ||
      !p04_core_vector_equal(
        timing$map_estimable,
        distributions$profile_estimable,
        tolerance
      ) ||
      !p04_core_vector_equal(
        timing$probability_aggregation,
        distributions$probability_aggregation,
        tolerance
      )
  ) {
    p04_core_abort(
      "Timing map values disagree with fixed exceedance distributions"
    )
  }
  group <- interaction(
    timing$placement,
    timing$profile_variant,
    drop = TRUE,
    lex.order = TRUE
  )
  summaries <- lapply(split(seq_len(nrow(timing)), group), function(index) {
    rows <- timing[index, , drop = FALSE]
    if (
      nrow(rows) != 48L ||
        !identical(sort(as.integer(rows$clock_bin)), seq.int(0L, 1410L, 30L))
    ) {
      p04_core_abort(
        "A timing relevance map is not a complete 48-bin clock profile"
      )
    }
    if (all(rows$map_estimable)) {
      if (
        any(
          !is.finite(rows$relevance_weight) |
            rows$relevance_weight < 0
        ) ||
          abs(sum(rows$relevance_weight) - 1) > tolerance
      ) {
        p04_core_abort(
          "An estimable timing relevance map is not normalized"
        )
      }
    }
    tibble::tibble(
      placement = as.character(rows$placement[[1L]]),
      profile_variant = as.character(rows$profile_variant[[1L]]),
      bins = nrow(rows),
      estimable = all(rows$map_estimable),
      relevance_weight_sum = sum(rows$relevance_weight)
    )
  })
  dplyr::bind_rows(summaries)
}

p04_core_select_sample_days <- function(
  coverage,
  sample_days_per_placement
) {
  assert_columns(
    coverage,
    c(
      p04_core_day_key,
      "day_eligible",
      "datetime_utc",
      "MEDI_eligible"
    ),
    object = "Preparation 02 coverage input"
  )
  eligible <- coverage |>
    dplyr::filter(.data$day_eligible) |>
    dplyr::group_by(dplyr::across(dplyr::all_of(p04_core_day_key))) |>
    dplyr::summarise(
      expected_minutes = dplyr::n(),
      missing_medi_minutes = sum(!is.finite(.data$MEDI_eligible)),
      .groups = "drop"
    ) |>
    dplyr::arrange(
      .data$site,
      .data$Id,
      .data$local_date
    )
  if (nrow(eligible) == 0L) {
    p04_core_abort("Coverage input has no eligible participant-days")
  }
  if (is.infinite(sample_days_per_placement)) {
    return(eligible)
  }
  number <- min(as.integer(sample_days_per_placement), nrow(eligible))
  if (number < 1L) {
    p04_core_abort("`sample_days_per_placement` must be positive")
  }
  evenly_spaced <- unique(as.integer(round(seq(
    1,
    nrow(eligible),
    length.out = number
  ))))
  by_site <- split(seq_len(nrow(eligible)), eligible$site)
  priority <- unlist(lapply(by_site, function(index) {
    missing_order <- index[order(
      -eligible$missing_medi_minutes[index],
      eligible$Id[index],
      eligible$local_date[index]
    )]
    unique(c(index[[1L]], missing_order[[1L]], index[[length(index)]]))
  }))
  selected <- unique(c(priority, evenly_spaced))
  if (length(selected) > number) {
    selected <- selected[seq_len(number)]
  }
  if (length(selected) < number) {
    selected <- c(
      selected,
      setdiff(seq_len(nrow(eligible)), selected)[
        seq_len(number - length(selected))
      ]
    )
  }
  eligible[sort(selected), , drop = FALSE]
}

p04_core_project_interval_value <- function(
  datetime,
  intervals,
  value_column
) {
  output <- rep(NA_character_, length(datetime))
  if (nrow(intervals) == 0L) {
    return(output)
  }
  intervals <- intervals[order(intervals$start, intervals$end), , drop = FALSE]
  starts <- as.numeric(intervals$start)
  ends <- as.numeric(intervals$end)
  if (
    anyNA(starts) ||
      anyNA(ends) ||
      any(ends <= starts) ||
      (length(starts) > 1L && any(starts[-1L] < ends[-length(ends)]))
  ) {
    p04_core_abort("State intervals are missing, invalid, or overlapping")
  }
  index <- findInterval(as.numeric(datetime), starts)
  inside <- index > 0L
  inside[inside] <- as.numeric(datetime[inside]) < ends[index[inside]]
  output[inside] <- as.character(intervals[[value_column]][index[inside]])
  output
}

p04_core_load_state_intervals <- function(
  state_inputs,
  placement,
  sites
) {
  selected <- state_inputs |>
    dplyr::filter(
      .data$placement == .env$placement,
      .data$site %in% sites
    )
  expected <- tidyr::crossing(
    site = sort(unique(sites)),
    interval_kind = c("sleep", "wear")
  )
  if (
    nrow(selected) != nrow(expected) ||
      !identical(
        sort(paste(selected$site, selected$interval_kind, sep = "/")),
        sort(paste(expected$site, expected$interval_kind, sep = "/"))
      )
  ) {
    p04_core_abort(
      "%s state-interval inputs do not cover sampled sites",
      placement
    )
  }
  objects <- lapply(seq_len(nrow(selected)), function(index) {
    data <- readRDS(as.character(selected$state_interval_path[[index]]))
    assert_columns(
      data,
      c(
        "site",
        "Id",
        "interval_kind",
        "interval_bounds",
        "start",
        "end"
      ),
      object = "state-interval artifact"
    )
    if (
      any(data$interval_kind != selected$interval_kind[[index]]) ||
        any(data$interval_bounds != "[)")
    ) {
      p04_core_abort("State-interval artifact kind or bounds changed")
    }
    data
  })
  combined <- dplyr::bind_rows(objects)
  list(
    sleep = combined |>
      dplyr::filter(.data$interval_kind == "sleep"),
    wear = combined |>
      dplyr::filter(.data$interval_kind == "wear")
  )
}

p04_core_project_context <- function(
  day,
  intervals,
  placement
) {
  site <- as.character(day$site[[1L]])
  participant <- as.character(day$Id[[1L]])
  sleep_intervals <- intervals$sleep |>
    dplyr::filter(.data$site == .env$site, .data$Id == .env$participant)
  wear_intervals <- intervals$wear |>
    dplyr::filter(.data$site == .env$site, .data$Id == .env$participant)
  brown <- p04_core_project_interval_value(
    day$datetime_utc,
    sleep_intervals,
    "State.Brown"
  )
  wear <- p04_core_project_interval_value(
    day$datetime_utc,
    wear_intervals,
    "wear"
  )
  diary_sleep <- !is.na(brown) & brown == "sleep"
  invalid_nonwear <- !is.na(wear) & wear == "off" & !diary_sleep
  context <- ifelse(
    diary_sleep,
    "bedside_sleep_environment",
    ifelse(
      invalid_nonwear,
      "invalid_nonwear",
      ifelse(
        identical(placement, "glasses"),
        "worn_near_eye",
        "worn_chest"
      )
    )
  )
  if (
    !"State.Brown" %in% names(day) ||
      !"measurement_context" %in% names(day) ||
      !p04_core_vector_equal(day$State.Brown, brown) ||
      !p04_core_vector_equal(day$measurement_context, context)
  ) {
    p04_core_abort(
      "%s sampled state-interval projection disagrees with coverage",
      placement
    )
  }
  context
}

p04_core_scan_runs <- function(member, datetime, segment) {
  n <- length(member)
  starts <- integer()
  ends <- integer()
  active_start <- NA_integer_
  for (index in seq_len(n)) {
    connected <- index > 1L &&
      abs(
        as.numeric(datetime[[index]]) -
          as.numeric(datetime[[index - 1L]]) -
          60
      ) <=
        1e-6 &&
      segment[[index]] == segment[[index - 1L]]
    continuation <- member[[index]] &&
      index > 1L &&
      member[[index - 1L]] &&
      connected
    if (member[[index]] && !continuation) {
      active_start <- index
    }
    closes <- member[[index]] &&
      (index == n ||
        !member[[index + 1L]] ||
        abs(
          as.numeric(datetime[[index + 1L]]) -
            as.numeric(datetime[[index]]) -
            60
        ) >
          1e-6 ||
        segment[[index + 1L]] != segment[[index]])
    if (closes) {
      starts <- c(starts, active_start)
      ends <- c(ends, index)
      active_start <- NA_integer_
    }
  }
  tibble::tibble(
    start = starts,
    end = ends,
    minutes = ends - starts + 1L
  )
}

p04_core_reconstruct_longest <- function(day, context) {
  order_rows <- order(day$datetime_utc)
  day <- day[order_rows, , drop = FALSE]
  context <- context[order_rows]
  context[is.na(context)] <- "unknown"
  segment <- cumsum(c(
    TRUE,
    context[-1L] != context[-length(context)]
  ))
  value <- day$MEDI_eligible
  observed_runs <- p04_core_scan_runs(
    is.finite(value) & value > 250,
    day$datetime_utc,
    segment
  )
  possible_runs <- p04_core_scan_runs(
    !is.finite(value) | value > 250,
    day$datetime_utc,
    segment
  )
  observed <- if (nrow(observed_runs) > 0L) {
    max(observed_runs$minutes)
  } else {
    0L
  }
  possible <- if (nrow(possible_runs) > 0L) {
    max(possible_runs$minutes)
  } else {
    0L
  }
  winners <- observed_runs[
    observed_runs$minutes == observed & observed > 0L,
    ,
    drop = FALSE
  ]
  winner <- if (nrow(winners) > 0L) {
    winners[order(winners$start, winners$end)[1L], , drop = FALSE]
  } else {
    NULL
  }
  empty_datetime <- as.POSIXct(
    NA_real_,
    origin = "1970-01-01",
    tz = "UTC"
  )
  censored <- possible > observed
  tibble::tibble(
    observed_h = observed / 60,
    possible_h = possible / 60,
    exact_only_h = if (censored) NA_real_ else observed / 60,
    exact_identifiable = !censored,
    censored = censored,
    missing_invalid_breaks_runs = TRUE,
    winning_observed_runs = nrow(winners),
    winner_onset_utc = if (is.null(winner)) {
      empty_datetime
    } else {
      day$datetime_utc[winner$start]
    },
    winner_offset_utc = if (is.null(winner)) {
      empty_datetime
    } else {
      day$datetime_utc[winner$end] + 60
    },
    day_boundary_contact = nrow(winners) > 0L &&
      any(winners$start == 1L | winners$end == nrow(day)),
    censor_reason = if (censored) {
      "missing_or_invalid_minutes_allow_longer_bout"
    } else {
      NA_character_
    },
    exact_failure_reason = if (censored) {
      "not_exactly_identifiable_due_to_missing_or_invalid_minutes"
    } else {
      NA_character_
    }
  )
}

p04_core_weighted_support <- function(observed, weight) {
  if (
    anyNA(observed) ||
      anyNA(weight) ||
      any(!is.finite(weight) | weight < 0) ||
      sum(weight) <= 0
  ) {
    return(NA_real_)
  }
  sum(observed * weight) / sum(weight)
}

p04_core_circular_summary <- function(minutes, minimum_resultant) {
  if (length(minutes) == 0L) {
    return(list(mean = NA_real_, resultant = NA_real_, estimable = FALSE))
  }
  radians <- (minutes %% 1440) / 1440 * 2 * pi
  vector <- mean(exp(1i * radians))
  resultant <- Mod(vector)
  estimable <- is.finite(resultant) &&
    resultant >= minimum_resultant
  list(
    mean = if (estimable) {
      (Arg(vector) %% (2 * pi)) / (2 * pi) * 1440
    } else {
      NA_real_
    },
    resultant = resultant,
    estimable = estimable
  )
}

p04_core_reconstruct_timing <- function(
  day,
  timing_map,
  minimum_support,
  minimum_resultant
) {
  value <- rep(NA_real_, 1440L)
  groups <- split(seq_len(nrow(day)), day$clock_minute)
  for (name in names(groups)) {
    observed <- day$MEDI_eligible[groups[[name]]]
    finite <- is.finite(observed)
    value[as.integer(name) + 1L] <- if (any(finite)) {
      mean(observed[finite])
    } else {
      NA_real_
    }
  }
  timing_map <- timing_map[order(timing_map$clock_bin), , drop = FALSE]
  expected_bins <- seq.int(0L, 1410L, 30L)
  if (
    nrow(timing_map) != 48L ||
      !identical(as.integer(timing_map$clock_bin), expected_bins)
  ) {
    p04_core_abort(
      "Selected timing map is not a complete ordered 48-bin profile"
    )
  }
  weight <- timing_map$relevance_weight[
    match(floor((0:1439) / 30L) * 30L, timing_map$clock_bin)
  ]
  observed_fraction <- as.numeric(is.finite(value))
  qualifies <- is.finite(value) & value > 250
  selected <- which(qualifies)
  overall_support <- p04_core_weighted_support(
    observed_fraction,
    weight
  )
  if (length(selected) == 0L) {
    censored <- !is.finite(overall_support) ||
      overall_support < minimum_support
    reason <- if (censored) {
      "insufficient_relevance_support"
    } else {
      "no_threshold_event"
    }
    return(tibble::tibble(
      first = NA_real_,
      last = NA_real_,
      mean = NA_real_,
      overall_support = overall_support,
      first_support = overall_support,
      last_support = overall_support,
      threshold_observed = FALSE,
      first_censored = censored,
      last_censored = censored,
      strict_first_gap = any(observed_fraction < 1),
      strict_last_gap = any(observed_fraction < 1),
      resultant = NA_real_,
      mean_estimable = FALSE,
      first_reason = reason,
      last_reason = reason,
      mean_reason = reason
    ))
  }
  first_index <- selected[[1L]]
  last_index <- selected[[length(selected)]]
  first_region <- seq_len(first_index)
  last_region <- seq.int(last_index, 1440L)
  first_support <- p04_core_weighted_support(
    observed_fraction[first_region],
    weight[first_region]
  )
  last_support <- p04_core_weighted_support(
    observed_fraction[last_region],
    weight[last_region]
  )
  first_censored <- !is.finite(first_support) ||
    first_support < minimum_support
  last_censored <- !is.finite(last_support) ||
    last_support < minimum_support
  circular <- p04_core_circular_summary(
    minutes = selected - 1L,
    minimum_resultant = minimum_resultant
  )
  mean_supported <- is.finite(overall_support) &&
    overall_support >= minimum_support
  mean_estimable <- mean_supported && circular$estimable
  mean_reason <- if (!mean_supported) {
    "insufficient_relevance_support"
  } else if (!circular$estimable) {
    "low_circular_resultant"
  } else {
    NA_character_
  }
  tibble::tibble(
    first = if (first_censored) NA_real_ else first_index - 1L,
    last = if (last_censored) NA_real_ else last_index - 1L,
    mean = if (mean_estimable) circular$mean else NA_real_,
    overall_support = overall_support,
    first_support = first_support,
    last_support = last_support,
    threshold_observed = TRUE,
    first_censored = first_censored,
    last_censored = last_censored,
    strict_first_gap = any(observed_fraction[first_region] < 1),
    strict_last_gap = any(observed_fraction[last_region] < 1),
    resultant = circular$resultant,
    mean_estimable = mean_estimable,
    first_reason = if (first_censored) {
      "insufficient_relevance_support"
    } else {
      NA_character_
    },
    last_reason = if (last_censored) {
      "insufficient_relevance_support"
    } else {
      NA_character_
    },
    mean_reason = mean_reason
  )
}

p04_core_assert_scalar <- function(
  observed,
  expected,
  object,
  tolerance = 1e-10
) {
  if (!p04_core_vector_equal(observed, expected, tolerance)) {
    p04_core_abort("%s disagrees with independent reconstruction", object)
  }
  invisible(TRUE)
}

p04_core_verify_sample_day <- function(
  day,
  output,
  timing_maps,
  intervals,
  settings_row,
  placement
) {
  key <- day[1L, p04_core_day_key, drop = FALSE]
  daily_index <- match(
    p04_core_key(key, p04_core_day_key),
    p04_core_key(output$daily, p04_core_day_key)
  )
  if (is.na(daily_index)) {
    p04_core_abort("Sampled coverage day is absent from daily metrics")
  }
  daily <- output$daily[daily_index, , drop = FALSE]
  context <- p04_core_project_context(day, intervals, placement)
  longest <- p04_core_reconstruct_longest(day, context)
  variant <- as.character(daily$profile_variant[[1L]])
  timing_map <- timing_maps |>
    dplyr::filter(
      .data$placement == .env$placement,
      .data$profile_variant == .env$variant
    )
  timing <- p04_core_reconstruct_timing(
    day,
    timing_map,
    minimum_support = as.numeric(
      settings_row$dose_minimum_relevance_support[[1L]]
    ),
    minimum_resultant = as.numeric(
      settings_row$minimum_circular_resultant[[1L]]
    )
  )
  label <- paste(
    placement,
    as.character(key$site),
    as.character(key$Id),
    as.character(key$local_date)
  )

  longest_checks <- c(
    longest_bout_above_250_h = longest$observed_h,
    longest_bout_above_250_observed_h = longest$observed_h,
    longest_bout_above_250_observed_lower_bound_h = longest$observed_h,
    longest_bout_above_250_possible_h = longest$possible_h,
    longest_bout_above_250_possible_upper_bound_h = longest$possible_h,
    longest_bout_above_250_exact_only_sensitivity_h = longest$exact_only_h
  )
  for (column in names(longest_checks)) {
    p04_core_assert_scalar(
      daily[[column]],
      longest_checks[[column]],
      paste(label, column)
    )
  }
  logical_checks <- list(
    longest_bout_above_250_exact_identifiable = longest$exact_identifiable,
    longest_bout_above_250_censored = longest$censored,
    longest_bout_above_250_missing_invalid_breaks_runs = longest$missing_invalid_breaks_runs,
    longest_bout_above_250_day_boundary_contact = longest$day_boundary_contact
  )
  for (column in names(logical_checks)) {
    p04_core_assert_scalar(
      daily[[column]],
      logical_checks[[column]],
      paste(label, column)
    )
  }
  p04_core_assert_scalar(
    daily$longest_bout_above_250_onset_utc,
    longest$winner_onset_utc,
    paste(label, "longest-bout onset")
  )
  p04_core_assert_scalar(
    daily$longest_bout_above_250_offset_utc,
    longest$winner_offset_utc,
    paste(label, "longest-bout offset")
  )
  p04_core_assert_scalar(
    daily$longest_bout_above_250_censor_reason,
    longest$censor_reason,
    paste(label, "longest-bout censor reason")
  )

  censor_index <- match(
    p04_core_key(key, p04_core_day_key),
    p04_core_key(output$censoring, p04_core_day_key)
  )
  censoring <- output$censoring[censor_index, , drop = FALSE]
  censor_checks <- list(
    longest_bout_censored = longest$censored,
    longest_bout_observed_h = longest$observed_h,
    longest_bout_observed_lower_bound_h = longest$observed_h,
    longest_bout_possible_h = longest$possible_h,
    longest_bout_possible_upper_bound_h = longest$possible_h,
    longest_bout_exact_only_sensitivity_h = longest$exact_only_h,
    longest_bout_exact_identifiable = longest$exact_identifiable,
    longest_bout_missing_invalid_breaks_runs = longest$missing_invalid_breaks_runs,
    longest_bout_winning_observed_runs = longest$winning_observed_runs,
    longest_bout_winner_onset_utc = longest$winner_onset_utc,
    longest_bout_winner_offset_utc = longest$winner_offset_utc,
    longest_bout_day_boundary_contact = longest$day_boundary_contact,
    longest_bout_censor_reason = longest$censor_reason
  )
  for (column in names(censor_checks)) {
    p04_core_assert_scalar(
      censoring[[column]],
      censor_checks[[column]],
      paste(label, column)
    )
  }

  timing_checks <- list(
    first_timing_above_250_clock_minute = timing$first,
    last_timing_above_250_clock_minute = timing$last,
    mean_timing_above_250_clock_minute = timing$mean
  )
  for (column in names(timing_checks)) {
    p04_core_assert_scalar(
      daily[[column]],
      timing_checks[[column]],
      paste(label, column)
    )
  }
  timing_censor_checks <- list(
    timing_threshold_observed = timing$threshold_observed,
    first_timing_left_censored = timing$first_censored,
    last_timing_right_censored = timing$last_censored,
    strict_first_boundary_gap = timing$strict_first_gap,
    strict_last_boundary_gap = timing$strict_last_gap,
    timing_circular_resultant = timing$resultant
  )
  for (column in names(timing_censor_checks)) {
    p04_core_assert_scalar(
      censoring[[column]],
      timing_censor_checks[[column]],
      paste(label, column)
    )
  }

  metric_expectations <- list(
    longest_bout_above_250 = list(
      value = longest$observed_h,
      estimable = TRUE,
      failure_reason = NA_character_,
      relevance_support = timing$overall_support,
      any_censored = longest$censored
    ),
    longest_bout_above_250_exact_only_sensitivity = list(
      value = longest$exact_only_h,
      estimable = longest$exact_identifiable,
      failure_reason = longest$exact_failure_reason,
      relevance_support = timing$overall_support,
      any_censored = longest$censored
    ),
    first_timing_above_250 = list(
      value = timing$first,
      estimable = is.finite(timing$first),
      failure_reason = timing$first_reason,
      relevance_support = timing$first_support,
      any_censored = FALSE
    ),
    last_timing_above_250 = list(
      value = timing$last,
      estimable = is.finite(timing$last),
      failure_reason = timing$last_reason,
      relevance_support = timing$last_support,
      any_censored = FALSE
    ),
    mean_timing_above_250 = list(
      value = timing$mean,
      estimable = timing$mean_estimable,
      failure_reason = timing$mean_reason,
      relevance_support = timing$overall_support,
      any_censored = FALSE
    )
  )
  for (metric in names(metric_expectations)) {
    rows <- output$long |>
      dplyr::filter(
        .data$site == key$site[[1L]],
        .data$Id == key$Id[[1L]],
        .data$position == key$position[[1L]],
        .data$local_date == key$local_date[[1L]],
        .data$analysis_unit == "participant_day",
        .data$metric == .env$metric
      )
    if (nrow(rows) != 1L) {
      p04_core_abort("%s %s long row is missing", label, metric)
    }
    expectation <- metric_expectations[[metric]]
    for (column in names(expectation)) {
      p04_core_assert_scalar(
        rows[[column]],
        expectation[[column]],
        paste(label, metric, column)
      )
    }
  }
  tibble::tibble(
    site = as.character(key$site),
    Id = as.character(key$Id),
    position = as.character(key$position),
    local_date = as.Date(key$local_date),
    expected_true_minutes = nrow(day),
    missing_medi_minutes = sum(!is.finite(day$MEDI_eligible)),
    reconstructed_longest_observed_h = longest$observed_h,
    reconstructed_longest_possible_h = longest$possible_h,
    reconstructed_longest_exact = longest$exact_identifiable,
    reconstructed_timing_support = timing$overall_support,
    reconstructed_threshold_observed = timing$threshold_observed
  )
}

verify_metric_derivation_core <- function(
  root = project_root(),
  run_label = "full",
  metric_run_root = NULL,
  metric_manifest_path = NULL,
  coverage_run_root = NULL,
  profile_run_root = NULL,
  state_interval_manifest_path = NULL,
  placements = c("chest", "glasses"),
  sample_days_per_placement = 48L
) {
  placements <- p04_core_normalise_placements(placements)
  if (
    length(sample_days_per_placement) != 1L ||
      is.na(sample_days_per_placement) ||
      (!is.infinite(sample_days_per_placement) &&
        (!is.numeric(sample_days_per_placement) ||
          sample_days_per_placement < 1 ||
          sample_days_per_placement != floor(sample_days_per_placement)))
  ) {
    p04_core_abort(
      "`sample_days_per_placement` must be a positive integer or `Inf`"
    )
  }
  layout <- p04_core_layout(
    root = root,
    run_label = run_label,
    metric_run_root = metric_run_root,
    metric_manifest_path = metric_manifest_path,
    coverage_run_root = coverage_run_root,
    profile_run_root = profile_run_root,
    state_interval_manifest_path = state_interval_manifest_path
  )
  manifest <- p04_core_verify_manifest(
    layout$metric_manifest_path,
    layout$metric_run_root,
    placements
  )
  outputs <- p04_core_read_outputs(
    layout$metric_run_root,
    placements
  )
  verified_inputs <- p04_core_verify_settings_and_inputs(
    layout,
    outputs,
    placements
  )
  settings <- verified_inputs$settings
  state_inputs <- verified_inputs$state_inputs
  dimension_summaries <- list()
  for (placement in placements) {
    settings_row <- settings |>
      dplyr::filter(.data$placement == .env$placement)
    dimension_summaries[[placement]] <- p04_core_verify_dimensions(
      outputs[[placement]],
      settings_row,
      placement
    )
    p04_core_verify_cross_artifact_tables(
      outputs[[placement]],
      placement
    )
    p04_core_verify_longest_invariants(
      outputs[[placement]],
      placement
    )
    p04_core_verify_timing_invariants(
      outputs[[placement]],
      placement
    )
  }

  map_path <- unique(as.character(settings$relevance_maps_path))
  distribution_path <- unique(
    as.character(settings$timing_exceedance_distributions_path)
  )
  if (length(map_path) != 1L || length(distribution_path) != 1L) {
    p04_core_abort(
      "Preparation 04 placements do not share one fixed timing-map input"
    )
  }
  maps <- readRDS(map_path)
  distributions <- readRDS(distribution_path)
  map_summary <- p04_core_verify_timing_map_linkage(
    maps,
    distributions,
    placements
  )
  timing_maps <- maps |>
    dplyr::filter(
      .data$metric_map == "timing_above_250",
      .data$placement %in% placements
    )

  sample_summaries <- list()
  for (placement in placements) {
    settings_row <- settings |>
      dplyr::filter(.data$placement == .env$placement)
    coverage_path <- as.character(settings_row$coverage_path[[1L]])
    coverage <- readRDS(coverage_path)
    sample_days <- p04_core_select_sample_days(
      coverage,
      sample_days_per_placement
    )
    intervals <- p04_core_load_state_intervals(
      state_inputs,
      placement,
      unique(sample_days$site)
    )
    sample_key <- p04_core_key(sample_days, p04_core_day_key)
    coverage_key <- p04_core_key(coverage, p04_core_day_key)
    day_rows <- split(
      which(coverage_key %in% sample_key),
      factor(
        coverage_key[coverage_key %in% sample_key],
        levels = sample_key
      )
    )
    sample_summaries[[placement]] <- dplyr::bind_rows(lapply(
      day_rows,
      function(index) {
        day <- coverage[index, , drop = FALSE] |>
          dplyr::arrange(.data$datetime_utc)
        p04_core_verify_sample_day(
          day = day,
          output = outputs[[placement]],
          timing_maps = timing_maps,
          intervals = intervals,
          settings_row = settings_row,
          placement = placement
        )
      }
    ))
  }

  list(
    status = "PASS",
    run_label = layout$run_label,
    verification_scope = paste0(
      "exact_31_artifact_manifest_and_whole_cohort_invariants;",
      "deterministic_exact_minute_reconstruction"
    ),
    minute_reconstruction_scope = if (is.infinite(sample_days_per_placement)) {
      "all_eligible_participant_days"
    } else {
      paste0(
        "deterministic_sample_up_to_",
        as.integer(sample_days_per_placement),
        "_days_per_placement"
      )
    },
    manifest_path = layout$metric_manifest_path,
    manifest_sha256 = artifact_sha256(layout$metric_manifest_path),
    manifest_artifacts = nrow(manifest),
    dimensions = dplyr::bind_rows(dimension_summaries),
    timing_map_summary = map_summary,
    sampled_reconstruction = dplyr::bind_rows(sample_summaries)
  )
}
