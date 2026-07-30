# Verify the manuscript-prepared-data sensitivity inputs fail closed.
#
# Source paths_io.R, assertions.R, metric_display_registry.R,
# manuscript_prepared_data.R, and build_manuscript_prepared_data.R first.

manuscript_prepared_csv_serialization_contract <- function() {
  # CSV is a review format; RDS is authoritative. Decimal text is accepted
  # within 1e-12 absolute/relative error, and second-formatted timestamps may
  # differ by less than one second when an RDS value contains subseconds.
  list(
    numeric_absolute_tolerance = 1e-12,
    numeric_relative_tolerance = 1e-12,
    datetime_tolerance_seconds = 1
  )
}

manuscript_prepared_compare_csv_to_rds <- function(
  csv_path,
  rds_path,
  object
) {
  contract <- manuscript_prepared_csv_serialization_contract()
  expected <- readRDS(rds_path)
  actual <- utils::read.csv(
    csv_path,
    stringsAsFactors = FALSE,
    check.names = FALSE,
    colClasses = "character",
    na.strings = ""
  )
  if (
    !is.data.frame(expected) ||
      !identical(names(actual), names(expected)) ||
      nrow(actual) != nrow(expected)
  ) {
    abort_pipeline("%s CSV structure differs from its RDS authority", object)
  }

  for (column in names(expected)) {
    reference <- expected[[column]]
    serialized <- actual[[column]]
    if (inherits(reference, "POSIXt")) {
      restored <- as.POSIXct(serialized, tz = "UTC")
      missing_match <- identical(is.na(restored), is.na(reference))
      difference <- abs(as.numeric(restored) - as.numeric(reference))
      values_match <- all(
        is.na(difference) |
          difference < contract$datetime_tolerance_seconds
      )
    } else if (inherits(reference, "Date")) {
      restored <- as.Date(serialized)
      missing_match <- identical(is.na(restored), is.na(reference))
      values_match <- identical(restored, as.Date(reference))
    } else if (is.logical(reference)) {
      restored <- rep(NA, length(serialized))
      restored[serialized == "TRUE"] <- TRUE
      restored[serialized == "FALSE"] <- FALSE
      invalid <- !is.na(serialized) & !serialized %in% c("TRUE", "FALSE")
      missing_match <- identical(is.na(restored), is.na(reference))
      values_match <- !any(invalid) && identical(restored, reference)
    } else if (is.integer(reference)) {
      restored <- suppressWarnings(as.integer(serialized))
      invalid <- !is.na(serialized) & is.na(restored)
      missing_match <- identical(is.na(restored), is.na(reference))
      values_match <- !any(invalid) && identical(restored, reference)
    } else if (is.numeric(reference)) {
      restored <- suppressWarnings(as.numeric(serialized))
      invalid <- !is.na(serialized) & is.na(restored)
      missing_match <- identical(is.na(restored), is.na(reference))
      difference <- abs(restored - reference)
      tolerance <- pmax(
        contract$numeric_absolute_tolerance,
        contract$numeric_relative_tolerance * abs(reference)
      )
      values_match <- !any(invalid) &&
        all(is.na(difference) | difference <= tolerance)
    } else {
      restored <- as.character(serialized)
      reference <- as.character(reference)
      missing_match <- identical(is.na(restored), is.na(reference))
      values_match <- identical(restored, reference)
    }
    if (!missing_match || !values_match) {
      abort_pipeline(
        "%s CSV column `%s` differs from its RDS authority",
        object,
        column
      )
    }
  }
  invisible(TRUE)
}

manuscript_prepared_verify_csv_rds_pairs <- function(paths) {
  paired <- c(
    "participant_metrics",
    "participant_day_metrics",
    "thirty_minute_data",
    "one_hour_data",
    "normalized_input_references"
  )
  for (id in paired) {
    manuscript_prepared_compare_csv_to_rds(
      paths$csv[[id]],
      paths$rds[[id]],
      id
    )
  }
  invisible(paired)
}

manuscript_prepared_reconstruct_averaged_one_hour <- function(data) {
  assert_columns(
    data,
    c("site", "Id", "Datetime", "Date", "MEDI", "LIGHT"),
    object = "verification one-minute data"
  )
  hourly <- LightLogR::aggregate_Datetime(
    dplyr::group_by(data, .data$site, .data$Id),
    "1 hour",
    type = "floor",
    numeric.handler = function(value) mean(value, na.rm = TRUE),
    geo.MEDI = LightLogR::exp_zero_inflated(
      mean(LightLogR::log_zero_inflated(MEDI), na.rm = TRUE)
    )
  )
  hourly <- LightLogR::add_Date_col(hourly, group.by = TRUE)
  hourly <- dplyr::mutate(
    hourly,
    verification_static_day = all(.data$MEDI == .data$MEDI[[1L]])
  )
  hourly <- dplyr::filter(hourly, !.data$verification_static_day)
  hourly <- dplyr::select(hourly, -"verification_static_day")
  hourly <- dplyr::ungroup(hourly)
  dplyr::mutate(hourly, local_occurrence = 1L)
}

manuscript_prepared_expected_artifact_ids <- function() {
  sort(c(
    paste0(
      c(
        "participant_metrics",
        "participant_day_metrics",
        "thirty_minute_data",
        "one_hour_data",
        "normalized_input_references"
      ),
      "_rds"
    ),
    paste0(
      c(
        "participant_metrics",
        "participant_day_metrics",
        "thirty_minute_data",
        "one_hour_data",
        "normalized_input_references"
      ),
      "_csv"
    ),
    paste0(
      c(
        "source_manifest",
        "correction_manifest",
        "metric_crosswalk",
        "variable_dictionary"
      ),
      "_csv"
    )
  ))
}

manuscript_prepared_expected_scenario_files <- function() {
  c(
    paste0(
      c(
        "participant_metrics",
        "participant_day_metrics",
        "thirty_minute_data",
        "one_hour_data",
        "normalized_input_references"
      ),
      ".rds"
    ),
    paste0(
      c(
        "participant_metrics",
        "participant_day_metrics",
        "thirty_minute_data",
        "one_hour_data",
        "normalized_input_references",
        "source_manifest",
        "correction_manifest",
        "metric_crosswalk",
        "variable_dictionary"
      ),
      ".csv"
    )
  )
}

manuscript_prepared_assert_identical_frame <- function(
  actual,
  expected,
  key,
  object
) {
  assert_unique_key(actual, key, paste(object, "actual"))
  assert_unique_key(expected, key, paste(object, "expected"))
  actual <- actual[do.call(order, actual[key]), , drop = FALSE]
  expected <- expected[do.call(order, expected[key]), , drop = FALSE]
  rownames(actual) <- NULL
  rownames(expected) <- NULL
  comparison <- all.equal(
    as.data.frame(actual),
    as.data.frame(expected),
    check.attributes = TRUE,
    tolerance = 0
  )
  if (!isTRUE(comparison)) {
    abort_pipeline(
      "%s differs from independently reconstructed values: %s",
      object,
      paste(comparison, collapse = "; ")
    )
  }
  invisible(actual)
}

manuscript_prepared_validate_frozen_objects <- function(sources) {
  expected_rows <- list(
    glasses = c(
      participant = 141L,
      participant_day = 811L,
      `30_minute` = 38832L,
      nested = 22L,
      preprocessed = 1168080L,
      repeated_minutes = 240L
    ),
    chest = c(
      participant = 154L,
      participant_day = 897L,
      `30_minute` = 42912L,
      nested = 22L,
      preprocessed = 1291800L,
      repeated_minutes = 120L
    )
  )
  expected_frozen_names <- c(
    "interdaily_stability",
    "intradaily_variability",
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
    "MDER",
    "duration_below_10_pre-sleep",
    "duration_below_1_sleep",
    "duration_above_250_wake"
  )

  for (position in manuscript_prepared_positions()) {
    counts <- expected_rows[[position]]
    separate <- sources$objects[[paste0("metrics_separate_", position)]]
    participant <- separate[[paste0("metric_", position, "_participant")]]
    participant_day <- separate[[
      paste0("metric_", position, "_participantday")
    ]]
    thirty_minute <- separate[[
      paste0("metric_", position, "_participanthour")
    ]]
    nested <- sources$objects[[paste0("metrics_", position)]][[
      paste0("metrics_", position)
    ]]
    preprocessed <- sources$objects[[
      paste0("preprocessed_", position, "_2")
    ]][[paste0("light_", position, "_processed2")]]

    if (
      nrow(participant) != counts[["participant"]] ||
        nrow(participant_day) != counts[["participant_day"]] ||
        nrow(thirty_minute) != counts[["30_minute"]] ||
        nrow(nested) != counts[["nested"]] ||
        nrow(preprocessed) != counts[["preprocessed"]]
    ) {
      abort_pipeline("Frozen %s source dimensions changed", position)
    }
    assert_unique_key(
      participant,
      c("site", "Id"),
      paste(position, "frozen participant metrics")
    )
    assert_unique_key(
      participant_day,
      c("site", "Id", "Date"),
      paste(position, "frozen participant-day metrics")
    )
    thirty_keyed <- manuscript_prepared_add_occurrence(thirty_minute)
    assert_unique_key(
      thirty_keyed,
      c("site", "Id", "Datetime", "local_occurrence"),
      paste(position, "frozen 30-minute metrics")
    )
    minute_keyed <- manuscript_prepared_add_occurrence(preprocessed)
    repeated_minutes <- sum(minute_keyed$local_occurrence > 1L)
    if (repeated_minutes != counts[["repeated_minutes"]]) {
      abort_pipeline(
        "Frozen %s repeated local-minute count changed",
        position
      )
    }
    assert_unique_key(
      minute_keyed,
      c("site", "Id", "Datetime", "local_occurrence"),
      paste(position, "frozen one-minute input")
    )
    if (
      !setequal(nested$name, expected_frozen_names) ||
        anyDuplicated(nested$name) ||
        !setequal(nested$type, c("participant", "participant-day"))
    ) {
      abort_pipeline("Frozen %s nested metric registry changed", position)
    }
    for (index in seq_len(nrow(nested))) {
      data <- nested$data[[index]]
      key <- c("site", "Id")
      if (nested$type[[index]] == "participant-day") {
        key <- c(key, "Date")
      }
      assert_unique_key(
        data,
        key,
        paste(position, nested$name[[index]], "nested metric")
      )
    }
  }
  invisible(TRUE)
}

manuscript_prepared_verify_manifest <- function(
  paths,
  output_root
) {
  if (!file.exists(paths$manifest)) {
    abort_pipeline("Scenario artifact manifest is missing")
  }
  manifest <- utils::read.csv(
    paths$manifest,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  required <- c(
    "scenario_id",
    "model_implementation_id",
    "producer",
    "artifact_id",
    "artifact_type",
    "path",
    "sha256",
    "bytes",
    "rows",
    "columns"
  )
  if (
    !identical(names(manifest), required) ||
      !identical(
        sort(manifest$artifact_id),
        manuscript_prepared_expected_artifact_ids()
      ) ||
      anyDuplicated(manifest$artifact_id) ||
      any(manifest$scenario_id != manuscript_prepared_scenario_id()) ||
      any(
        manifest$model_implementation_id !=
          manuscript_prepared_model_implementation_id()
      )
  ) {
    abort_pipeline("Scenario artifact manifest differs from its contract")
  }
  for (index in seq_len(nrow(manifest))) {
    path <- file.path(output_root, manifest$path[[index]])
    if (
      !file.exists(path) ||
        artifact_sha256(path) != manifest$sha256[[index]] ||
        as.numeric(file.info(path)$size) != manifest$bytes[[index]]
    ) {
      abort_pipeline(
        "Scenario artifact `%s` failed fingerprint verification",
        manifest$artifact_id[[index]]
      )
    }
    object <- if (manifest$artifact_type[[index]] == "rds") {
      readRDS(path)
    } else if (manifest$artifact_type[[index]] == "csv") {
      utils::read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)
    } else {
      abort_pipeline("Scenario manifest contains an unsupported artifact type")
    }
    if (
      !is.data.frame(object) ||
        nrow(object) != manifest$rows[[index]] ||
        ncol(object) != manifest$columns[[index]]
    ) {
      abort_pipeline(
        "Scenario artifact `%s` failed dimension verification",
        manifest$artifact_id[[index]]
      )
    }
  }
  manifest
}

verify_manuscript_prepared_data_artifacts <- function(
  root = project_root(),
  output_root = root
) {
  root <- normalizePath(root, winslash = "/", mustWork = TRUE)
  output_root <- normalizePath(output_root, winslash = "/", mustWork = TRUE)
  paths <- manuscript_prepared_output_paths(root, output_root)
  if (!dir.exists(paths$scenario_root)) {
    abort_pipeline("Scenario output directory is missing")
  }
  actual_files <- sort(list.files(paths$scenario_root))
  if (
    !identical(
      actual_files,
      sort(manuscript_prepared_expected_scenario_files())
    )
  ) {
    abort_pipeline(
      "Scenario directory contains missing or unexpected files: %s",
      paste(actual_files, collapse = ", ")
    )
  }
  artifact_manifest <- manuscript_prepared_verify_manifest(
    paths,
    output_root
  )
  csv_rds_pairs <- manuscript_prepared_verify_csv_rds_pairs(paths)

  sources <- manuscript_prepared_load_sources(root)
  manuscript_prepared_validate_frozen_objects(sources)
  mapping <- manuscript_prepared_output_metric_mapping(root)
  references <- manuscript_prepared_normalized_input_references(root)
  corrections <- manuscript_prepared_correction_manifest(root)
  source_manifest <- dplyr::bind_rows(sources$manifest, references)

  actual_mapping <- utils::read.csv(
    paths$csv[["metric_crosswalk"]],
    stringsAsFactors = FALSE,
    check.names = FALSE,
    na.strings = ""
  )
  actual_source_manifest <- utils::read.csv(
    paths$csv[["source_manifest"]],
    stringsAsFactors = FALSE,
    check.names = FALSE,
    na.strings = ""
  )
  actual_corrections <- utils::read.csv(
    paths$csv[["correction_manifest"]],
    stringsAsFactors = FALSE,
    check.names = FALSE,
    na.strings = ""
  )
  actual_dictionary <- utils::read.csv(
    paths$csv[["variable_dictionary"]],
    stringsAsFactors = FALSE,
    check.names = FALSE,
    na.strings = ""
  )
  if (
    !isTRUE(all.equal(actual_mapping, mapping, tolerance = 0)) ||
      !isTRUE(
        all.equal(actual_source_manifest, source_manifest, tolerance = 0)
      ) ||
      !isTRUE(all.equal(actual_corrections, corrections, tolerance = 0)) ||
      !isTRUE(
        all.equal(
          actual_dictionary,
          manuscript_prepared_output_variable_dictionary(),
          tolerance = 0
        )
      ) ||
      !identical(actual_corrections$correction_id, "DEV-056") ||
      any(actual_corrections$scientific_light_values_changed)
  ) {
    abort_pipeline("Scenario contracts or correction manifest changed")
  }

  expected <- list(
    participant_metrics = list(),
    participant_day_metrics = list(),
    thirty_minute_data = list(),
    one_hour_data = list()
  )
  for (position in manuscript_prepared_positions()) {
    nested <- sources$objects[[paste0("metrics_", position)]][[
      paste0("metrics_", position)
    ]]
    separate <- sources$objects[[paste0("metrics_separate_", position)]]
    preprocessed <- sources$objects[[
      paste0("preprocessed_", position, "_2")
    ]][[paste0("light_", position, "_processed2")]]
    expected$participant_metrics[[position]] <-
      manuscript_prepared_extract_metric_rows(
        nested,
        mapping,
        position,
        "participant"
      )
    expected$participant_day_metrics[[position]] <-
      manuscript_prepared_extract_metric_rows(
        nested,
        mapping,
        position,
        "participant_day"
      )
    expected$thirty_minute_data[[position]] <-
      manuscript_prepared_normalize_clock_data(
        manuscript_prepared_add_occurrence(
          separate[[paste0("metric_", position, "_participanthour")]]
        ),
        position,
        "30_minute"
      )
    expected$one_hour_data[[position]] <-
      manuscript_prepared_normalize_clock_data(
        manuscript_prepared_reconstruct_averaged_one_hour(preprocessed),
        position,
        "one_hour"
      )
  }
  expected <- lapply(expected, dplyr::bind_rows)
  actual <- lapply(
    names(expected),
    function(id) readRDS(paths$rds[[id]])
  )
  names(actual) <- names(expected)

  manuscript_prepared_assert_identical_frame(
    actual$participant_metrics,
    expected$participant_metrics,
    c("scenario_id", "position", "site", "Id", "metric_id"),
    "participant metric artifact"
  )
  manuscript_prepared_assert_identical_frame(
    actual$participant_day_metrics,
    expected$participant_day_metrics,
    c(
      "scenario_id",
      "position",
      "site",
      "Id",
      "local_date",
      "metric_id"
    ),
    "participant-day metric artifact"
  )
  clock_key <- c(
    "scenario_id",
    "position",
    "site",
    "Id",
    "local_clock_label",
    "local_occurrence"
  )
  manuscript_prepared_assert_identical_frame(
    actual$thirty_minute_data,
    expected$thirty_minute_data,
    clock_key,
    "30-minute artifact"
  )
  manuscript_prepared_assert_identical_frame(
    actual$one_hour_data,
    expected$one_hour_data,
    clock_key,
    "one-hour artifact"
  )

  expected_one_hour_rows <- data.frame(
    position = c("chest", "glasses"),
    one_hour_rows = c(21288L, 19176L),
    stringsAsFactors = FALSE
  )
  observed_one_hour_rows <- actual$one_hour_data |>
    dplyr::group_by(.data$position) |>
    dplyr::summarise(
      one_hour_rows = dplyr::n(),
      .groups = "drop"
    ) |>
    as.data.frame()
  if (
    !isTRUE(
      all.equal(
        observed_one_hour_rows,
        expected_one_hour_rows,
        tolerance = 0
      )
    ) ||
      any(actual$thirty_minute_data$local_occurrence != 1L) ||
      any(actual$one_hour_data$local_occurrence != 1L)
  ) {
    abort_pipeline(
      "One-hour rows do not use the unique averaged local-hour key"
    )
  }

  stored_references <- readRDS(
    paths$rds[["normalized_input_references"]]
  )
  if (!isTRUE(all.equal(stored_references, references, tolerance = 0))) {
    abort_pipeline("Stored normalized-input references changed")
  }

  list(
    status = "PASS",
    scenario_id = manuscript_prepared_scenario_id(),
    model_implementation_id = manuscript_prepared_model_implementation_id(),
    artifact_manifest = artifact_manifest,
    output_rows = vapply(actual, nrow, integer(1)),
    correction_ids = corrections$correction_id,
    paired_csv_rds_artifacts = csv_rds_pairs,
    csv_serialization_contract = manuscript_prepared_csv_serialization_contract(),
    one_hour_rows = observed_one_hour_rows
  )
}
