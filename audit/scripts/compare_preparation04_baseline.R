# Reconcile baseline and canonical Preparation 04 metric artifacts.

#####
# Step 1: Define run configuration
#####

abort_comparison <- function(...) {
  stop(sprintf(...), call. = FALSE)
}

assert_scalar_character <- function(value, argument) {
  if (
    !is.character(value) ||
      length(value) != 1L ||
      is.na(value) ||
      !nzchar(trimws(value))
  ) {
    abort_comparison("`%s` must be one non-empty character value", argument)
  }
  invisible(value)
}

normalise_path <- function(path, must_work = TRUE) {
  assert_scalar_character(path, "path")
  normalizePath(
    trimws(path),
    winslash = "/",
    mustWork = must_work
  )
}

parse_named_arguments <- function(arguments) {
  parsed <- list(
    run = FALSE,
    self_test = FALSE,
    project_root = getwd(),
    project_library = NULL,
    output_dir = NULL
  )
  for (argument in arguments) {
    if (identical(argument, "--run")) {
      parsed$run <- TRUE
    } else if (identical(argument, "--self-test")) {
      parsed$self_test <- TRUE
    } else if (grepl("^--project-root=", argument)) {
      parsed$project_root <- sub("^--project-root=", "", argument)
    } else if (grepl("^--project-library=", argument)) {
      parsed$project_library <- sub("^--project-library=", "", argument)
    } else if (grepl("^--output-dir=", argument)) {
      parsed$output_dir <- sub("^--output-dir=", "", argument)
    } else {
      abort_comparison("Unknown command-line argument: %s", argument)
    }
  }
  if (parsed$run && parsed$self_test) {
    abort_comparison("Use either `--run` or `--self-test`, not both")
  }
  parsed
}

default_project_library <- function(project_root) {
  r_minor <- strsplit(R.Version()$minor, ".", fixed = TRUE)[[1L]][[1L]]
  file.path(
    project_root,
    "renv",
    "library",
    "macos",
    paste0("R-", R.Version()$major, ".", r_minor),
    R.version$platform
  )
}

configure_comparison_runtime <- function(
  project_root,
  project_library = NULL
) {
  project_root <- normalise_path(project_root, must_work = TRUE)
  if (!identical(as.character(getRversion()), "4.6.1")) {
    abort_comparison(
      "Preparation 04 reconciliation requires R 4.6.1; found R %s",
      as.character(getRversion())
    )
  }
  if (is.null(project_library)) {
    project_library <- default_project_library(project_root)
  }
  project_library <- normalise_path(project_library, must_work = TRUE)
  .libPaths(unique(c(project_library, .Library, .Library.site)))
  active_library <- normalise_path(.libPaths()[[1L]], must_work = TRUE)
  if (!identical(active_library, project_library)) {
    abort_comparison(
      "The explicit project library was not placed first in `.libPaths()`"
    )
  }
  if (!requireNamespace("openssl", quietly = TRUE)) {
    abort_comparison(
      "Package `openssl` is required in the explicit project library"
    )
  }
  Sys.setenv(TZ = "UTC")
  options(stringsAsFactors = FALSE, warn = 2)
  list(
    project_root = project_root,
    project_library = project_library
  )
}

comparison_input_paths <- function(project_root) {
  list(
    baseline_ledger = file.path(
      project_root,
      "audit",
      "baseline",
      "data_artifact_hashes.csv"
    ),
    current_manifest = file.path(
      project_root,
      "artifacts",
      "12_manifests",
      "metric_artifacts.csv"
    ),
    script = file.path(
      project_root,
      "audit",
      "scripts",
      "compare_preparation04_baseline.R"
    ),
    placements = list(
      glasses = list(
        baseline_path = file.path(
          project_root,
          "data",
          "metrics_glasses.RData"
        ),
        baseline_object = "metrics_glasses",
        current_path = file.path(
          project_root,
          "artifacts",
          "05_metrics",
          "metrics_glasses_participant_day.rds"
        )
      ),
      chest = list(
        baseline_path = file.path(
          project_root,
          "data",
          "metrics_chest.RData"
        ),
        baseline_object = "metrics_chest",
        current_path = file.path(
          project_root,
          "artifacts",
          "05_metrics",
          "metrics_chest_participant_day.rds"
        )
      )
    )
  )
}

#####
# Step 2: Declare the metric crosswalk
#####

preparation04_metric_crosswalk <- function() {
  crosswalk <- data.frame(
    comparison_order = seq_len(21L),
    mapping_id = sprintf("D%02d", seq_len(21L)),
    focus_group = c("MDER", rep("mapped_daily_metric", 20L)),
    baseline_metric = c(
      "MDER",
      "Mean",
      "brightest_10h_mean",
      "brightest_10h_midpoint",
      "brightest_10h_onset",
      "brightest_10h_offset",
      "darkest_10h_mean",
      "darkest_10h_midpoint",
      "darkest_10h_onset",
      "darkest_10h_offset",
      "duration_above_1000",
      "duration_above_250",
      "period_above_250",
      "mean_timing_above_250",
      "first_timing_above_250",
      "last_timing_above_250",
      "dose",
      "dose",
      "duration_above_250_wake",
      "duration_below_10_pre-sleep",
      "duration_below_1_sleep"
    ),
    current_metric = c(
      "mder_ratio_of_integrals",
      "daily_geometric_mean_medi",
      "m10_mean_medi",
      "m10_midpoint",
      "m10_onset",
      "m10_offset",
      "l10_mean_medi",
      "l10_midpoint",
      "l10_onset",
      "l10_offset",
      "duration_above_1000",
      "duration_above_250_full_day",
      "longest_bout_above_250",
      "mean_timing_above_250",
      "first_timing_above_250",
      "last_timing_above_250",
      "dose_observed_medi",
      "dose_time_sensitive_corrected_medi",
      "duration_above_250_wake",
      "duration_below_10_pre_sleep",
      "duration_below_1_sleep_environment"
    ),
    current_column = c(
      "mder",
      "daily_geometric_mean_medi_lx",
      "m10_mean_medi_lx",
      "m10_midpoint_clock_minute",
      "m10_onset_clock_minute",
      "m10_offset_clock_minute",
      "l10_mean_medi_lx",
      "l10_midpoint_clock_minute",
      "l10_onset_clock_minute",
      "l10_offset_clock_minute",
      "duration_above_1000_h",
      "duration_above_250_full_day_h",
      "longest_bout_above_250_h",
      "mean_timing_above_250_clock_minute",
      "first_timing_above_250_clock_minute",
      "last_timing_above_250_clock_minute",
      "dose_observed_medi_lx_h",
      "dose_corrected_medi_lx_h",
      "duration_above_250_wake_h",
      "duration_below_10_pre_sleep_h",
      "duration_below_1_sleep_environment_h"
    ),
    baseline_unit = c(
      "dimensionless",
      "lx",
      "lx",
      rep("decimal_hour", 3L),
      "lx",
      rep("centered_decimal_hour", 3L),
      rep("h", 3L),
      rep("decimal_hour", 3L),
      "lx_h",
      "lx_h",
      rep("h", 3L)
    ),
    current_unit = c(
      "dimensionless",
      "lx",
      "lx",
      rep("clock_minute", 3L),
      "lx",
      rep("clock_minute", 3L),
      rep("h", 3L),
      rep("clock_minute", 3L),
      "lx_h",
      "lx_h",
      rep("h", 3L)
    ),
    comparison_unit = c(
      "dimensionless",
      "lx",
      "lx",
      rep("decimal_hour", 3L),
      "lx",
      rep("centered_decimal_hour", 3L),
      rep("h", 3L),
      rep("decimal_hour", 3L),
      "lx_h",
      "lx_h",
      rep("h", 3L)
    ),
    baseline_transform = "identity",
    current_transform = c(
      "identity",
      "identity",
      "identity",
      rep("clock_minute_to_decimal_hour", 3L),
      "identity",
      rep("clock_minute_to_centered_decimal_hour", 3L),
      rep("identity", 3L),
      rep("clock_minute_to_decimal_hour", 3L),
      rep("identity", 5L)
    ),
    difference_method = c(
      rep("linear_current_minus_baseline", 3L),
      rep("circular_24h_current_minus_baseline", 3L),
      "linear_current_minus_baseline",
      rep("circular_24h_current_minus_baseline", 3L),
      rep("linear_current_minus_baseline", 3L),
      rep("circular_24h_current_minus_baseline", 3L),
      rep("linear_current_minus_baseline", 5L)
    ),
    semantic_comparability = c(
      "related_construct_changed_estimand",
      "same_construct_modified_support_and_masking",
      rep("same_construct_modified_window_support", 8L),
      rep("same_construct_modified_gap_handling", 6L),
      "same_construct_observed_integral_comparison",
      "related_construct_support_corrected_estimand",
      rep("same_construct_metric_specific_support", 3L)
    ),
    limitation = c(
      paste0(
        "Baseline is the mean of epoch-wise MEDI/LIGHT ratios; current is ",
        "the ratio of observed paired-channel integrals and is estimable ",
        "only when ordinary and both fixed-profile supports are at least 80%."
      ),
      paste0(
        "Both are zero-aware geometric means, but upstream masking, the ",
        "100000-lx operating boundary, and explicit minute support differ."
      ),
      rep(
        paste0(
          "The fixed 10-hour construct is retained, but current calculation ",
          "uses explicit wall-minute support, fixed relevance profiles, and ",
          "fall-back duplicate averaging for clock analyses."
        ),
        8L
      ),
      rep(
        paste0(
          "Threshold and bout metrics are compared in hours; current ",
          "calculation is gap-aware and uses true UTC elapsed minutes."
        ),
        3L
      ),
      rep(
        paste0(
          "Clock values are compared in decimal hours with circular 24-hour ",
          "paired differences; current timing also requires explicit ",
          "relevance support."
        ),
        3L
      ),
      paste0(
        "This is the closest like-for-like dose comparison, but current ",
        "integration follows true UTC minutes and current masks."
      ),
      paste0(
        "Current dose applies the pre-learned time-sensitive relevance map; ",
        "it is intentionally not the same estimand as the uncorrected ",
        "baseline dose."
      ),
      rep(
        paste0(
          "Current state-window duration retains the participant-day but ",
          "sets this metric non-estimable when diary-domain completeness or ",
          "the approved 80% state support is not met."
        ),
        3L
      )
    ),
    stringsAsFactors = FALSE
  )
  if (
    anyDuplicated(crosswalk$mapping_id) ||
      crosswalk$mapping_id[[1L]] != "D01" ||
      crosswalk$focus_group[[1L]] != "MDER"
  ) {
    abort_comparison("The Preparation 04 crosswalk has an invalid order")
  }
  crosswalk
}

transform_metric_value <- function(value, transformation) {
  value <- as.numeric(value)
  if (identical(transformation, "identity")) {
    return(value)
  }
  if (identical(transformation, "clock_minute_to_decimal_hour")) {
    return(value / 60)
  }
  if (
    identical(
      transformation,
      "clock_minute_to_centered_decimal_hour"
    )
  ) {
    hour <- value / 60
    hour[is.finite(hour) & hour > 12] <-
      hour[is.finite(hour) & hour > 12] - 24
    return(hour)
  }
  abort_comparison("Unknown metric transformation: %s", transformation)
}

metric_difference <- function(current, baseline, method) {
  raw_difference <- current - baseline
  if (identical(method, "linear_current_minus_baseline")) {
    return(raw_difference)
  }
  if (identical(method, "circular_24h_current_minus_baseline")) {
    return(((raw_difference + 12) %% 24) - 12)
  }
  abort_comparison("Unknown paired-difference method: %s", method)
}

#####
# Step 3: Load and validate immutable inputs
#####

sha256_file <- function(path) {
  path <- normalise_path(path, must_work = TRUE)
  connection <- file(path, open = "rb")
  on.exit(close(connection), add = TRUE)
  as.character(openssl::sha256(connection))
}

file_bytes <- function(path) {
  as.numeric(file.info(path)$size)
}

read_csv_base <- function(path) {
  utils::read.csv(
    path,
    stringsAsFactors = FALSE,
    check.names = FALSE,
    na.strings = c("", "NA")
  )
}

assert_columns <- function(data, required, object) {
  missing <- setdiff(required, names(data))
  if (length(missing) > 0L) {
    abort_comparison(
      "%s is missing required column(s): %s",
      object,
      paste(missing, collapse = ", ")
    )
  }
  invisible(data)
}

key_token <- function(data) {
  paste(
    data$site,
    data$Id,
    data$position,
    format(data$local_date, "%Y-%m-%d"),
    sep = "\u001f"
  )
}

assert_unique_day_key <- function(data, object) {
  token <- key_token(data)
  if (anyNA(token) || anyDuplicated(token)) {
    abort_comparison("%s has missing or duplicate participant-day keys", object)
  }
  invisible(data)
}

load_private_rdata_object <- function(path, expected_object) {
  private <- new.env(parent = baseenv())
  loaded <- load(path, envir = private)
  if (!identical(loaded, expected_object)) {
    abort_comparison(
      "%s must contain only `%s`; found: %s",
      path,
      expected_object,
      paste(loaded, collapse = ", ")
    )
  }
  object <- private[[expected_object]]
  rm(list = loaded, envir = private)
  invisible(gc())
  object
}

normalise_baseline_key <- function(data, placement, object) {
  assert_columns(data, c("site", "Id", "Date", "metric"), object)
  local_date <- as.Date(as.character(data$Date), format = "%Y-%m-%d")
  if (anyNA(local_date)) {
    abort_comparison("%s contains an invalid or missing `Date` key", object)
  }
  metric <- suppressWarnings(as.numeric(data$metric))
  if (length(metric) != nrow(data)) {
    abort_comparison("%s has an invalid metric vector", object)
  }
  data.frame(
    site = as.character(data$site),
    Id = as.character(data$Id),
    position = placement,
    local_date = local_date,
    baseline_value = metric,
    stringsAsFactors = FALSE
  )
}

load_baseline_metrics <- function(path, expected_object, placement) {
  object <- load_private_rdata_object(path, expected_object)
  assert_columns(
    object,
    c("name", "type", "data"),
    sprintf("%s baseline metric object", placement)
  )
  inventory <- data.frame(
    position = placement,
    baseline_metric = as.character(object$name),
    analysis_unit = as.character(object$type),
    rows = vapply(object$data, nrow, integer(1)),
    stringsAsFactors = FALSE
  )
  daily_index <- which(as.character(object$type) == "participant-day")
  if (length(daily_index) == 0L) {
    abort_comparison(
      "%s baseline contains no participant-day metrics",
      placement
    )
  }
  daily <- lapply(daily_index, function(index) {
    metric_name <- as.character(object$name[[index]])
    data <- normalise_baseline_key(
      object$data[[index]],
      placement = placement,
      object = sprintf("%s baseline `%s`", placement, metric_name)
    )
    data$baseline_metric <- metric_name
    data
  })
  daily <- do.call(rbind, daily)
  rownames(daily) <- NULL
  compound_key <- paste(
    key_token(daily),
    daily$baseline_metric,
    sep = "\u001e"
  )
  if (anyDuplicated(compound_key)) {
    abort_comparison(
      "%s baseline has duplicate metric participant-day keys",
      placement
    )
  }
  list(daily = daily, inventory = inventory)
}

normalise_current_daily <- function(data, placement, crosswalk) {
  object <- sprintf("%s current participant-day metrics", placement)
  assert_columns(
    data,
    c(
      "site",
      "Id",
      "position",
      "local_date",
      "profile_variant",
      "measurement_construct",
      "mder_support_threshold_enforced",
      "mder_ratio_scaled_or_weighted",
      unique(crosswalk$current_column)
    ),
    object
  )
  if (any(as.character(data$position) != placement)) {
    abort_comparison("%s contains another placement", object)
  }
  if (any(as.character(data$profile_variant) != "pooled")) {
    abort_comparison("%s is not the canonical pooled profile run", object)
  }
  if (
    anyNA(data$mder_support_threshold_enforced) ||
      !all(data$mder_support_threshold_enforced) ||
      anyNA(data$mder_ratio_scaled_or_weighted) ||
      any(data$mder_ratio_scaled_or_weighted)
  ) {
    abort_comparison(
      "%s does not enforce unscaled 80%% MDER support as declared",
      object
    )
  }
  data$site <- as.character(data$site)
  data$Id <- as.character(data$Id)
  data$position <- as.character(data$position)
  data$local_date <- as.Date(as.character(data$local_date))
  if (anyNA(data$local_date)) {
    abort_comparison("%s contains an invalid `local_date` key", object)
  }
  for (column in unique(crosswalk$current_column)) {
    if (!is.numeric(data[[column]])) {
      abort_comparison("%s `%s` must be numeric", object, column)
    }
  }
  assert_unique_day_key(data, object)

  settings <- attr(data, "metric_settings", exact = TRUE)
  if (!is.data.frame(settings)) {
    abort_comparison("%s lacks durable metric settings", object)
  }
  assert_columns(
    settings,
    c(
      "state_support_cutoff",
      "state_support_decision_id",
      "mder_support_cutoff",
      "mder_support_decision_id",
      "mder_support_status",
      "mder_ratio_definition",
      "mder_ratio_scaled_or_weighted"
    ),
    sprintf("%s settings", object)
  )
  if (
    nrow(settings) != 1L ||
      !isTRUE(all.equal(settings$state_support_cutoff[[1L]], 0.8)) ||
      settings$state_support_decision_id[[1L]] != "STATE-005" ||
      !isTRUE(all.equal(settings$mder_support_cutoff[[1L]], 0.8)) ||
      settings$mder_support_decision_id[[1L]] != "METRIC-003" ||
      settings$mder_support_status[[1L]] != "author_approved" ||
      settings$mder_ratio_definition[[1L]] !=
        "ratio_of_observed_paired_integrals" ||
      isTRUE(settings$mder_ratio_scaled_or_weighted[[1L]])
  ) {
    abort_comparison(
      "%s settings do not match the approved canonical support rules",
      object
    )
  }
  data
}

verify_baseline_inputs <- function(input_paths, baseline_ledger) {
  assert_columns(
    baseline_ledger,
    c("path", "bytes", "sha256", "baseline_status"),
    "baseline data-artifact ledger"
  )
  rows <- lapply(names(input_paths$placements), function(placement) {
    path <- input_paths$placements[[placement]]$baseline_path
    relative <- file.path("data", basename(path))
    ledger_row <- baseline_ledger[
      baseline_ledger$path == relative,
      ,
      drop = FALSE
    ]
    if (nrow(ledger_row) != 1L) {
      abort_comparison(
        "Baseline ledger must contain exactly one row for %s",
        relative
      )
    }
    actual_hash <- sha256_file(path)
    actual_bytes <- file_bytes(path)
    if (
      actual_hash != ledger_row$sha256[[1L]] ||
        actual_bytes != as.numeric(ledger_row$bytes[[1L]]) ||
        ledger_row$baseline_status[[1L]] != "tracked-baseline"
    ) {
      abort_comparison("Baseline artifact verification failed for %s", relative)
    }
    data.frame(
      input_role = paste0("baseline_", placement),
      path = normalise_path(path),
      bytes = actual_bytes,
      sha256 = actual_hash,
      expected_sha256 = ledger_row$sha256[[1L]],
      verification_source = normalise_path(input_paths$baseline_ledger),
      verified = TRUE,
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, rows)
}

verify_current_inputs <- function(input_paths, current_manifest) {
  assert_columns(
    current_manifest,
    c(
      "path",
      "sha256",
      "bytes",
      "r_version",
      "artifact_type",
      "run_label",
      "profile_variant"
    ),
    "canonical metric artifact manifest"
  )
  rows <- lapply(names(input_paths$placements), function(placement) {
    path <- normalise_path(
      input_paths$placements[[placement]]$current_path,
      must_work = TRUE
    )
    manifest_paths <- vapply(
      current_manifest$path,
      normalise_path,
      character(1),
      must_work = TRUE
    )
    manifest_row <- current_manifest[manifest_paths == path, , drop = FALSE]
    if (nrow(manifest_row) != 1L) {
      abort_comparison(
        "Canonical manifest must contain exactly one row for %s",
        path
      )
    }
    expected_type <- "participant_day_metrics_rds"
    actual_hash <- sha256_file(path)
    actual_bytes <- file_bytes(path)
    if (
      actual_hash != manifest_row$sha256[[1L]] ||
        actual_bytes != as.numeric(manifest_row$bytes[[1L]]) ||
        manifest_row$r_version[[1L]] != "4.6.1" ||
        manifest_row$artifact_type[[1L]] != expected_type ||
        manifest_row$run_label[[1L]] != "full" ||
        manifest_row$profile_variant[[1L]] != "pooled"
    ) {
      abort_comparison(
        "Canonical metric artifact verification failed for %s",
        path
      )
    }
    data.frame(
      input_role = paste0("current_", placement),
      path = path,
      bytes = actual_bytes,
      sha256 = actual_hash,
      expected_sha256 = manifest_row$sha256[[1L]],
      verification_source = normalise_path(input_paths$current_manifest),
      verified = TRUE,
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, rows)
}

#####
# Step 4: Reconcile keys and metric values
#####

participant_count <- function(data) {
  length(unique(paste(data$site, data$Id, sep = "\u001f")))
}

reconcile_day_keys <- function(baseline, current, placement) {
  key_columns <- c("site", "Id", "position", "local_date")
  baseline_keys <- unique(baseline[key_columns])
  current_keys <- unique(current[key_columns])
  assert_unique_day_key(baseline_keys, paste0(placement, " baseline keys"))
  assert_unique_day_key(current_keys, paste0(placement, " current keys"))
  baseline_keys$baseline_present <- TRUE
  current_keys$current_present <- TRUE
  joined <- merge(
    baseline_keys,
    current_keys,
    by = key_columns,
    all = TRUE,
    sort = TRUE
  )
  joined$baseline_present[is.na(joined$baseline_present)] <- FALSE
  joined$current_present[is.na(joined$current_present)] <- FALSE
  joined$key_status <- ifelse(
    joined$baseline_present & joined$current_present,
    "matched",
    ifelse(joined$baseline_present, "baseline_only", "current_only")
  )
  summary <- data.frame(
    position = placement,
    baseline_participant_days = nrow(baseline_keys),
    current_participant_days = nrow(current_keys),
    matched_participant_days = sum(joined$key_status == "matched"),
    baseline_only_participant_days = sum(
      joined$key_status == "baseline_only"
    ),
    current_only_participant_days = sum(joined$key_status == "current_only"),
    baseline_participants = participant_count(baseline_keys),
    current_participants = participant_count(current_keys),
    baseline_sites = length(unique(baseline_keys$site)),
    current_sites = length(unique(current_keys$site)),
    stringsAsFactors = FALSE
  )

  grouped <- split(
    joined,
    interaction(joined$site, joined$key_status, drop = TRUE)
  )
  by_site <- lapply(grouped, function(group) {
    data.frame(
      position = placement,
      site = as.character(group$site[[1L]]),
      key_status = as.character(group$key_status[[1L]]),
      participant_days = nrow(group),
      participants = participant_count(group),
      stringsAsFactors = FALSE
    )
  })
  by_site <- do.call(rbind, by_site)
  rownames(by_site) <- NULL
  list(summary = summary, by_site = by_site)
}

value_state <- function(value) {
  state <- rep("finite", length(value))
  state[is.infinite(value) & value > 0] <- "positive_infinity"
  state[is.infinite(value) & value < 0] <- "negative_infinity"
  state[is.na(value) & !is.nan(value)] <- "missing_na"
  state[is.nan(value)] <- "missing_nan"
  state
}

finite_distribution <- function(
  value,
  mapping,
  placement,
  series,
  scope
) {
  finite <- value[is.finite(value)]
  probabilities <- c(0, 0.025, 0.25, 0.5, 0.75, 0.975, 1)
  quantiles <- if (length(finite) > 0L) {
    as.numeric(stats::quantile(
      finite,
      probs = probabilities,
      names = FALSE,
      type = 7
    ))
  } else {
    rep(NA_real_, length(probabilities))
  }
  data.frame(
    comparison_order = mapping$comparison_order,
    mapping_id = mapping$mapping_id,
    focus_group = mapping$focus_group,
    position = placement,
    baseline_metric = mapping$baseline_metric,
    current_metric = mapping$current_metric,
    series = series,
    scope = scope,
    comparison_unit = mapping$comparison_unit,
    n_total = length(value),
    n_finite = length(finite),
    n_na = sum(is.na(value) & !is.nan(value)),
    n_nan = sum(is.nan(value)),
    n_positive_infinity = sum(is.infinite(value) & value > 0),
    n_negative_infinity = sum(is.infinite(value) & value < 0),
    mean = if (length(finite) > 0L) mean(finite) else NA_real_,
    sd = if (length(finite) > 1L) stats::sd(finite) else NA_real_,
    minimum = quantiles[[1L]],
    q025 = quantiles[[2L]],
    q25 = quantiles[[3L]],
    median = quantiles[[4L]],
    q75 = quantiles[[5L]],
    q975 = quantiles[[6L]],
    maximum = quantiles[[7L]],
    stringsAsFactors = FALSE
  )
}

paired_difference_summary <- function(
  difference,
  baseline,
  current,
  mapping,
  placement
) {
  finite <- difference[is.finite(difference)]
  paired <- is.finite(baseline) & is.finite(current)
  baseline <- baseline[paired]
  current <- current[paired]
  if (length(finite) != length(baseline)) {
    abort_comparison("Paired finite values and differences do not reconcile")
  }
  correlation_estimable <- length(finite) > 1L &&
    stats::sd(baseline) > 0 &&
    stats::sd(current) > 0
  probabilities <- c(0, 0.025, 0.25, 0.5, 0.75, 0.975, 1)
  quantiles <- if (length(finite) > 0L) {
    as.numeric(stats::quantile(
      finite,
      probs = probabilities,
      names = FALSE,
      type = 7
    ))
  } else {
    rep(NA_real_, length(probabilities))
  }
  data.frame(
    comparison_order = mapping$comparison_order,
    mapping_id = mapping$mapping_id,
    focus_group = mapping$focus_group,
    position = placement,
    baseline_metric = mapping$baseline_metric,
    current_metric = mapping$current_metric,
    comparison_unit = mapping$comparison_unit,
    difference_method = mapping$difference_method,
    n_paired_finite = length(finite),
    mean_difference = if (length(finite) > 0L) mean(finite) else NA_real_,
    sd_difference = if (length(finite) > 1L) {
      stats::sd(finite)
    } else {
      NA_real_
    },
    mean_absolute_difference = if (length(finite) > 0L) {
      mean(abs(finite))
    } else {
      NA_real_
    },
    root_mean_square_difference = if (length(finite) > 0L) {
      sqrt(mean(finite^2))
    } else {
      NA_real_
    },
    pearson_correlation = if (correlation_estimable) {
      stats::cor(baseline, current, method = "pearson")
    } else {
      NA_real_
    },
    spearman_correlation = if (correlation_estimable) {
      stats::cor(baseline, current, method = "spearman")
    } else {
      NA_real_
    },
    minimum_difference = quantiles[[1L]],
    q025_difference = quantiles[[2L]],
    q25_difference = quantiles[[3L]],
    median_difference = quantiles[[4L]],
    q75_difference = quantiles[[5L]],
    q975_difference = quantiles[[6L]],
    maximum_difference = quantiles[[7L]],
    n_negative_difference_lt_minus_1e_12 = sum(finite < -1e-12),
    n_absolute_difference_lte_1e_12 = sum(abs(finite) <= 1e-12),
    n_positive_difference_gt_1e_12 = sum(finite > 1e-12),
    stringsAsFactors = FALSE
  )
}

compare_one_metric <- function(baseline, current, mapping, placement) {
  key_columns <- c("site", "Id", "position", "local_date")
  baseline_rows <- baseline[
    baseline$baseline_metric == mapping$baseline_metric,
    c(key_columns, "baseline_value"),
    drop = FALSE
  ]
  baseline_rows$baseline_present <- TRUE
  current_rows <- current[,
    c(key_columns, mapping$current_column),
    drop = FALSE
  ]
  names(current_rows)[[length(names(current_rows))]] <- "current_value"
  current_rows$current_value <- transform_metric_value(
    current_rows$current_value,
    mapping$current_transform
  )
  current_rows$current_present <- TRUE
  joined <- merge(
    baseline_rows,
    current_rows,
    by = key_columns,
    all = TRUE,
    sort = TRUE
  )
  joined$baseline_present[is.na(joined$baseline_present)] <- FALSE
  joined$current_present[is.na(joined$current_present)] <- FALSE
  matched <- joined$baseline_present & joined$current_present
  baseline_finite <- is.finite(joined$baseline_value)
  current_finite <- is.finite(joined$current_value)
  paired_finite <- matched & baseline_finite & current_finite
  difference <- metric_difference(
    joined$current_value[paired_finite],
    joined$baseline_value[paired_finite],
    mapping$difference_method
  )
  summary <- data.frame(
    comparison_order = mapping$comparison_order,
    mapping_id = mapping$mapping_id,
    focus_group = mapping$focus_group,
    position = placement,
    baseline_metric = mapping$baseline_metric,
    current_metric = mapping$current_metric,
    comparison_unit = mapping$comparison_unit,
    semantic_comparability = mapping$semantic_comparability,
    baseline_rows = sum(joined$baseline_present),
    current_rows = sum(joined$current_present),
    matched_keys = sum(matched),
    baseline_only_keys = sum(
      joined$baseline_present & !joined$current_present
    ),
    current_only_keys = sum(
      !joined$baseline_present & joined$current_present
    ),
    baseline_finite_all_rows = sum(
      joined$baseline_present & baseline_finite
    ),
    current_finite_all_rows = sum(joined$current_present & current_finite),
    matched_both_finite = sum(paired_finite),
    matched_baseline_finite_current_nonfinite = sum(
      matched & baseline_finite & !current_finite
    ),
    matched_baseline_nonfinite_current_finite = sum(
      matched & !baseline_finite & current_finite
    ),
    matched_both_nonfinite = sum(
      matched & !baseline_finite & !current_finite
    ),
    stringsAsFactors = FALSE
  )

  transition_rows <- joined[matched, , drop = FALSE]
  transition_rows$baseline_state <- value_state(
    transition_rows$baseline_value
  )
  transition_rows$current_state <- value_state(transition_rows$current_value)
  transition_table <- as.data.frame(
    table(
      baseline_state = transition_rows$baseline_state,
      current_state = transition_rows$current_state
    ),
    stringsAsFactors = FALSE
  )
  transition_table <- transition_table[
    transition_table$Freq > 0L,
    ,
    drop = FALSE
  ]
  transition_table <- data.frame(
    comparison_order = mapping$comparison_order,
    mapping_id = mapping$mapping_id,
    focus_group = mapping$focus_group,
    position = placement,
    baseline_metric = mapping$baseline_metric,
    current_metric = mapping$current_metric,
    baseline_state = transition_table$baseline_state,
    current_state = transition_table$current_state,
    participant_days = as.integer(transition_table$Freq),
    stringsAsFactors = FALSE
  )

  distributions <- rbind(
    finite_distribution(
      joined$baseline_value[joined$baseline_present],
      mapping,
      placement,
      series = "baseline",
      scope = "all_available_keys"
    ),
    finite_distribution(
      joined$current_value[joined$current_present],
      mapping,
      placement,
      series = "current",
      scope = "all_available_keys"
    ),
    finite_distribution(
      joined$baseline_value[matched],
      mapping,
      placement,
      series = "baseline",
      scope = "matched_keys"
    ),
    finite_distribution(
      joined$current_value[matched],
      mapping,
      placement,
      series = "current",
      scope = "matched_keys"
    ),
    finite_distribution(
      joined$baseline_value[paired_finite],
      mapping,
      placement,
      series = "baseline",
      scope = "paired_finite"
    ),
    finite_distribution(
      joined$current_value[paired_finite],
      mapping,
      placement,
      series = "current",
      scope = "paired_finite"
    )
  )

  list(
    summary = summary,
    transitions = transition_table,
    distributions = distributions,
    differences = paired_difference_summary(
      difference,
      joined$baseline_value[paired_finite],
      joined$current_value[paired_finite],
      mapping,
      placement
    )
  )
}

mapping_coverage_inventory <- function(
  baseline_inventory,
  crosswalk,
  placement
) {
  baseline <- baseline_inventory
  baseline$mappings <- vapply(
    baseline$baseline_metric,
    function(metric) sum(crosswalk$baseline_metric == metric),
    integer(1)
  )
  baseline$mapping_status <- ifelse(
    baseline$analysis_unit == "participant",
    "deferred_participant_metric",
    ifelse(
      baseline$mappings == 0L,
      "unmapped",
      ifelse(
        baseline$mappings == 1L,
        "mapped",
        "mapped_to_multiple_current_estimands"
      )
    )
  )
  baseline$note <- ifelse(
    baseline$analysis_unit == "participant",
    "Participant-level IS/IV comparison is outside this Preparation 04 daily-metric pass.",
    ifelse(
      baseline$mappings > 1L,
      "Baseline dose is compared with both observed and time-sensitive corrected current dose.",
      ""
    )
  )
  baseline_rows <- data.frame(
    position = placement,
    dataset_side = "baseline",
    metric = baseline$baseline_metric,
    analysis_unit = baseline$analysis_unit,
    rows = baseline$rows,
    mappings = baseline$mappings,
    mapping_status = baseline$mapping_status,
    note = baseline$note,
    stringsAsFactors = FALSE
  )

  current_metrics <- unique(crosswalk$current_metric)
  current_rows <- data.frame(
    position = placement,
    dataset_side = "current",
    metric = current_metrics,
    analysis_unit = "participant_day",
    rows = NA_integer_,
    mappings = vapply(
      current_metrics,
      function(metric) sum(crosswalk$current_metric == metric),
      integer(1)
    ),
    mapping_status = "mapped",
    note = "",
    stringsAsFactors = FALSE
  )
  rbind(baseline_rows, current_rows)
}

#####
# Step 5: Write aggregate reconciliation artifacts
#####

write_csv_deterministic <- function(data, path) {
  utils::write.csv(
    data,
    file = path,
    row.names = FALSE,
    na = ""
  )
  invisible(path)
}

validate_output_scope <- function(output_dir, project_root) {
  expected <- normalise_path(
    file.path(
      project_root,
      "audit",
      "reconciliation",
      "preparation04"
    ),
    must_work = FALSE
  )
  actual <- normalise_path(output_dir, must_work = FALSE)
  if (!identical(actual, expected)) {
    abort_comparison(
      "Outputs must be written exactly to %s; received %s",
      expected,
      actual
    )
  }
  actual
}

write_reconciliation_outputs <- function(outputs, output_dir) {
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  output_specification <- list(
    metric_crosswalk = outputs$crosswalk,
    input_inventory = outputs$input_inventory,
    run_metadata = outputs$run_metadata,
    key_reconciliation = outputs$key_reconciliation,
    unmatched_key_counts_by_site = outputs$unmatched_by_site,
    mapping_coverage = outputs$mapping_coverage,
    metric_comparison_summary = outputs$metric_summary,
    metric_finite_transition_counts = outputs$transitions,
    metric_distribution_summary = outputs$distributions,
    metric_paired_difference_summary = outputs$differences
  )
  paths <- vapply(
    names(output_specification),
    function(name) {
      path <- file.path(output_dir, paste0(name, ".csv"))
      write_csv_deterministic(output_specification[[name]], path)
      normalise_path(path)
    },
    character(1)
  )
  manifest <- data.frame(
    artifact = names(paths),
    path = unname(paths),
    bytes = vapply(paths, file_bytes, numeric(1)),
    sha256 = vapply(paths, sha256_file, character(1)),
    producer = "audit/scripts/compare_preparation04_baseline.R",
    r_version = as.character(getRversion()),
    stringsAsFactors = FALSE
  )
  manifest_path <- file.path(output_dir, "artifact_manifest.csv")
  write_csv_deterministic(manifest, manifest_path)
  list(paths = paths, manifest_path = normalise_path(manifest_path))
}

run_preparation04_comparison <- function(
  project_root,
  project_library,
  output_dir,
  input_paths = comparison_input_paths(project_root)
) {
  output_dir <- validate_output_scope(output_dir, project_root)
  required_files <- c(
    input_paths$baseline_ledger,
    input_paths$current_manifest,
    input_paths$script,
    unlist(lapply(
      input_paths$placements,
      function(paths) c(paths$baseline_path, paths$current_path)
    ))
  )
  missing <- required_files[!file.exists(required_files)]
  if (length(missing) > 0L) {
    abort_comparison(
      "Preparation 04 comparison input(s) are missing: %s",
      paste(missing, collapse = ", ")
    )
  }

  crosswalk <- preparation04_metric_crosswalk()
  baseline_ledger <- read_csv_base(input_paths$baseline_ledger)
  current_manifest <- read_csv_base(input_paths$current_manifest)
  baseline_inventory <- verify_baseline_inputs(input_paths, baseline_ledger)
  current_inventory <- verify_current_inputs(input_paths, current_manifest)
  infrastructure_inventory <- data.frame(
    input_role = c(
      "baseline_hash_ledger",
      "current_artifact_manifest",
      "comparison_script"
    ),
    path = vapply(
      c(
        input_paths$baseline_ledger,
        input_paths$current_manifest,
        input_paths$script
      ),
      normalise_path,
      character(1)
    ),
    bytes = vapply(
      c(
        input_paths$baseline_ledger,
        input_paths$current_manifest,
        input_paths$script
      ),
      file_bytes,
      numeric(1)
    ),
    sha256 = vapply(
      c(
        input_paths$baseline_ledger,
        input_paths$current_manifest,
        input_paths$script
      ),
      sha256_file,
      character(1)
    ),
    expected_sha256 = NA_character_,
    verification_source = NA_character_,
    verified = TRUE,
    stringsAsFactors = FALSE
  )
  input_inventory <- rbind(
    baseline_inventory,
    current_inventory,
    infrastructure_inventory
  )

  key_rows <- list()
  unmatched_rows <- list()
  mapping_rows <- list()
  summary_rows <- list()
  transition_rows <- list()
  distribution_rows <- list()
  difference_rows <- list()

  for (placement in names(input_paths$placements)) {
    paths <- input_paths$placements[[placement]]
    baseline <- load_baseline_metrics(
      paths$baseline_path,
      paths$baseline_object,
      placement
    )
    current <- readRDS(paths$current_path)
    current <- normalise_current_daily(current, placement, crosswalk)
    baseline_metrics <- unique(baseline$daily$baseline_metric)
    missing_baseline_metrics <- setdiff(
      unique(crosswalk$baseline_metric),
      baseline_metrics
    )
    if (length(missing_baseline_metrics) > 0L) {
      abort_comparison(
        "%s baseline is missing mapped metric(s): %s",
        placement,
        paste(missing_baseline_metrics, collapse = ", ")
      )
    }

    day_keys <- reconcile_day_keys(baseline$daily, current, placement)
    key_rows[[placement]] <- day_keys$summary
    unmatched_rows[[placement]] <- day_keys$by_site
    mapping_rows[[placement]] <- mapping_coverage_inventory(
      baseline$inventory,
      crosswalk,
      placement
    )

    comparisons <- lapply(seq_len(nrow(crosswalk)), function(index) {
      compare_one_metric(
        baseline$daily,
        current,
        crosswalk[index, , drop = FALSE],
        placement
      )
    })
    summary_rows[[placement]] <- do.call(
      rbind,
      lapply(comparisons, `[[`, "summary")
    )
    transition_rows[[placement]] <- do.call(
      rbind,
      lapply(comparisons, `[[`, "transitions")
    )
    distribution_rows[[placement]] <- do.call(
      rbind,
      lapply(comparisons, `[[`, "distributions")
    )
    difference_rows[[placement]] <- do.call(
      rbind,
      lapply(comparisons, `[[`, "differences")
    )
  }

  sort_comparison <- function(data) {
    data[order(data$comparison_order, data$position), , drop = FALSE]
  }
  run_metadata <- data.frame(
    field = c(
      "scope",
      "model_or_p_value_comparison",
      "r_version",
      "r_platform",
      "project_library",
      "timezone",
      "difference_direction",
      "row_level_participant_output"
    ),
    value = c(
      "Preparation 04 MDER and mapped participant-day metrics",
      "not_performed",
      as.character(getRversion()),
      R.version$platform,
      project_library,
      Sys.getenv("TZ"),
      "current_minus_baseline",
      "not_written"
    ),
    stringsAsFactors = FALSE
  )
  outputs <- list(
    crosswalk = crosswalk,
    input_inventory = input_inventory,
    run_metadata = run_metadata,
    key_reconciliation = do.call(rbind, key_rows),
    unmatched_by_site = do.call(rbind, unmatched_rows),
    mapping_coverage = do.call(rbind, mapping_rows),
    metric_summary = sort_comparison(do.call(rbind, summary_rows)),
    transitions = sort_comparison(do.call(rbind, transition_rows)),
    distributions = sort_comparison(do.call(rbind, distribution_rows)),
    differences = sort_comparison(do.call(rbind, difference_rows))
  )
  written <- write_reconciliation_outputs(outputs, output_dir)
  list(outputs = outputs, written = written)
}

#####
# Step 6: Exercise transformations and reconciliation with fixtures
#####

make_fixture_baseline <- function(path, object_name, placement, crosswalk) {
  keys <- data.frame(
    site = factor(c("A", "A", "B")),
    Id = factor(c("P01", "P01", "P02")),
    Date = factor(c("2026-01-01", "2026-01-02", "2026-01-03")),
    stringsAsFactors = TRUE
  )
  metrics <- unique(c(
    "interdaily_stability",
    "intradaily_variability",
    crosswalk$baseline_metric
  ))
  types <- ifelse(
    metrics %in% c("interdaily_stability", "intradaily_variability"),
    "participant",
    "participant-day"
  )
  data <- lapply(seq_along(metrics), function(index) {
    if (types[[index]] == "participant") {
      return(data.frame(
        site = factor(c("A", "B")),
        Id = factor(c("P01", "P02")),
        Date = factor(c(NA, NA)),
        metric = c(0.5, 0.6)
      ))
    }
    value <- c(index, index + 0.25, index + 0.5)
    if (metrics[[index]] == "MDER") {
      value <- c(0.5, NA_real_, 0.7)
    }
    if (grepl("darkest_10h_(midpoint|onset|offset)", metrics[[index]])) {
      value <- c(-1, 0, 1)
    }
    if (
      grepl(
        "brightest_10h_(midpoint|onset|offset)|timing_above_250",
        metrics[[index]]
      )
    ) {
      value <- c(10, 11, 12)
    }
    data.frame(keys, metric = value)
  })
  object <- data.frame(
    name = metrics,
    type = types,
    stringsAsFactors = FALSE
  )
  object$data <- I(data)
  private <- new.env(parent = baseenv())
  private[[object_name]] <- object
  save(list = object_name, file = path, envir = private)
  rm(list = object_name, envir = private)
  invisible(path)
}

make_fixture_current <- function(path, placement, crosswalk) {
  current <- data.frame(
    site = c("A", "A", "C"),
    Id = c("P01", "P01", "P03"),
    position = placement,
    local_date = as.Date(c("2026-01-01", "2026-01-02", "2026-01-04")),
    profile_variant = "pooled",
    measurement_construct = paste0("fixture_", placement),
    mder_support_threshold_enforced = TRUE,
    mder_ratio_scaled_or_weighted = FALSE,
    stringsAsFactors = FALSE
  )
  for (column in unique(crosswalk$current_column)) {
    current[[column]] <- c(1, 2, 3)
  }
  current$mder <- c(0.6, 0.65, 0.8)
  timing_columns <- unique(crosswalk$current_column[
    crosswalk$current_transform == "clock_minute_to_decimal_hour"
  ])
  for (column in timing_columns) {
    current[[column]] <- c(630, 690, 750)
  }
  centered_columns <- unique(crosswalk$current_column[
    crosswalk$current_transform == "clock_minute_to_centered_decimal_hour"
  ])
  for (column in centered_columns) {
    current[[column]] <- c(1410, 30, 90)
  }
  attr(current, "metric_settings") <- data.frame(
    state_support_cutoff = 0.8,
    state_support_decision_id = "STATE-005",
    mder_support_cutoff = 0.8,
    mder_support_decision_id = "METRIC-003",
    mder_support_status = "author_approved",
    mder_ratio_definition = "ratio_of_observed_paired_integrals",
    mder_ratio_scaled_or_weighted = FALSE,
    stringsAsFactors = FALSE
  )
  saveRDS(current, path)
  invisible(path)
}

run_comparison_self_test <- function(runtime) {
  crosswalk <- preparation04_metric_crosswalk()
  state_fixture <- value_state(c(1, NA_real_, NaN, Inf, -Inf))
  if (
    !identical(
      state_fixture,
      c(
        "finite",
        "missing_na",
        "missing_nan",
        "positive_infinity",
        "negative_infinity"
      )
    ) ||
      any(table(state_fixture) != 1L) ||
      !isTRUE(all.equal(
        transform_metric_value(1410, "clock_minute_to_centered_decimal_hour"),
        -0.5
      )) ||
      !isTRUE(all.equal(
        metric_difference(23.5, 0.5, "circular_24h_current_minus_baseline"),
        -1
      ))
  ) {
    abort_comparison("Clock-time transformation fixture failed")
  }

  fixture_root <- tempfile("preparation04-comparison-fixture-")
  dir.create(file.path(fixture_root, "data"), recursive = TRUE)
  dir.create(
    file.path(fixture_root, "audit", "baseline"),
    recursive = TRUE
  )
  dir.create(
    file.path(fixture_root, "audit", "scripts"),
    recursive = TRUE
  )
  dir.create(
    file.path(fixture_root, "artifacts", "05_metrics"),
    recursive = TRUE
  )
  dir.create(
    file.path(fixture_root, "artifacts", "12_manifests"),
    recursive = TRUE
  )
  fixture_script <- file.path(
    fixture_root,
    "audit",
    "scripts",
    "compare_preparation04_baseline.R"
  )
  file.copy(
    file.path(
      runtime$project_root,
      "audit",
      "scripts",
      "compare_preparation04_baseline.R"
    ),
    fixture_script
  )

  placements <- c("glasses", "chest")
  baseline_rows <- list()
  manifest_rows <- list()
  for (placement in placements) {
    baseline_path <- file.path(
      fixture_root,
      "data",
      paste0("metrics_", placement, ".RData")
    )
    object_name <- paste0("metrics_", placement)
    current_path <- file.path(
      fixture_root,
      "artifacts",
      "05_metrics",
      paste0("metrics_", placement, "_participant_day.rds")
    )
    make_fixture_baseline(
      baseline_path,
      object_name,
      placement,
      crosswalk
    )
    make_fixture_current(current_path, placement, crosswalk)
    baseline_rows[[placement]] <- data.frame(
      path = file.path("data", basename(baseline_path)),
      bytes = file_bytes(baseline_path),
      sha256 = sha256_file(baseline_path),
      baseline_status = "tracked-baseline",
      stringsAsFactors = FALSE
    )
    manifest_rows[[placement]] <- data.frame(
      path = normalise_path(current_path),
      sha256 = sha256_file(current_path),
      bytes = file_bytes(current_path),
      r_version = "4.6.1",
      artifact_type = "participant_day_metrics_rds",
      run_label = "full",
      profile_variant = "pooled",
      stringsAsFactors = FALSE
    )
  }
  write_csv_deterministic(
    do.call(rbind, baseline_rows),
    file.path(
      fixture_root,
      "audit",
      "baseline",
      "data_artifact_hashes.csv"
    )
  )
  write_csv_deterministic(
    do.call(rbind, manifest_rows),
    file.path(
      fixture_root,
      "artifacts",
      "12_manifests",
      "metric_artifacts.csv"
    )
  )
  output_dir <- file.path(
    fixture_root,
    "audit",
    "reconciliation",
    "preparation04"
  )
  result <- run_preparation04_comparison(
    project_root = fixture_root,
    project_library = runtime$project_library,
    output_dir = output_dir
  )
  mder <- result$outputs$metric_summary[
    result$outputs$metric_summary$mapping_id == "D01",
    ,
    drop = FALSE
  ]
  if (
    nrow(mder) != 2L ||
      any(mder$matched_keys != 2L) ||
      any(mder$baseline_only_keys != 1L) ||
      any(mder$current_only_keys != 1L) ||
      any(mder$matched_both_finite != 1L) ||
      any(mder$matched_baseline_nonfinite_current_finite != 1L)
  ) {
    abort_comparison("MDER reconciliation fixture failed")
  }
  mder_difference <- result$outputs$differences[
    result$outputs$differences$mapping_id == "D01",
    ,
    drop = FALSE
  ]
  if (
    nrow(mder_difference) != 2L ||
      any(abs(mder_difference$mean_difference - 0.1) > 1e-12)
  ) {
    abort_comparison("MDER paired-difference fixture failed")
  }
  if (
    !file.exists(result$written$manifest_path) ||
      any(
        result$outputs$mapping_coverage$mapping_status == "unmapped"
      )
  ) {
    abort_comparison("Fixture artifact or mapping coverage check failed")
  }
  message(
    "Preparation 04 comparison self-test PASS under R ",
    as.character(getRversion()),
    "; fixture outputs: ",
    output_dir
  )
  invisible(TRUE)
}

#####
# Step 7: Dispatch an explicit mode
#####

main <- function() {
  arguments <- parse_named_arguments(commandArgs(trailingOnly = TRUE))
  runtime <- configure_comparison_runtime(
    project_root = arguments$project_root,
    project_library = arguments$project_library
  )
  if (arguments$self_test) {
    return(run_comparison_self_test(runtime))
  }
  if (!arguments$run) {
    abort_comparison(
      "No action selected; use `--self-test` or explicitly use `--run`"
    )
  }
  output_dir <- if (is.null(arguments$output_dir)) {
    file.path(
      runtime$project_root,
      "audit",
      "reconciliation",
      "preparation04"
    )
  } else {
    arguments$output_dir
  }
  result <- run_preparation04_comparison(
    project_root = runtime$project_root,
    project_library = runtime$project_library,
    output_dir = output_dir
  )
  message(
    "Preparation 04 baseline/current reconciliation complete: ",
    result$written$manifest_path
  )
  invisible(result)
}

if (sys.nframe() == 0L) {
  main()
}
