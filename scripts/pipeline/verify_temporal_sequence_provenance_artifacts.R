# Independently verify H02/H11 true-time sequence-provenance artifacts.
#
# This verifier intentionally does not source the production provenance module.
# Source paths_io.R and assertions.R before this file.

p06tp_require <- function(condition, message, ...) {
  if (
    length(condition) != 1L ||
      is.na(condition) ||
      !isTRUE(condition)
  ) {
    abort_pipeline(message, ...)
  }
  invisible(TRUE)
}

p06tp_input_roles <- function() {
  tibble::tribble(
    ~input_role,
    ~placement,
    ~resolution,
    ~input_kind,
    ~filename,
    "glasses_coverage",
    "glasses",
    "all",
    "coverage",
    "light_glasses_coverage.rds",
    "chest_coverage",
    "chest",
    "all",
    "coverage",
    "light_chest_coverage.rds",
    "glasses_30_minute",
    "glasses",
    "30_minute",
    "metric",
    "metrics_glasses_30_minute.rds",
    "glasses_one_hour",
    "glasses",
    "one_hour",
    "metric",
    "metrics_glasses_one_hour.rds",
    "chest_30_minute",
    "chest",
    "30_minute",
    "metric",
    "metrics_chest_30_minute.rds",
    "chest_one_hour",
    "chest",
    "one_hour",
    "metric",
    "metrics_chest_one_hour.rds"
  )
}

p06tp_input_paths <- function(input_root) {
  paths <- pipeline_paths(input_root)
  roles <- p06tp_input_roles()
  roots <- ifelse(
    roles$input_kind == "coverage",
    paths$coverage,
    paths$metrics
  )
  stats::setNames(file.path(roots, roles$filename), roles$input_role)
}

p06tp_resolve_input_paths <- function(input_paths, input_root) {
  expected <- p06tp_input_roles()$input_role
  if (is.null(input_paths)) {
    input_paths <- p06tp_input_paths(input_root)
  }
  if (
    !is.character(input_paths) ||
      is.null(names(input_paths)) ||
      anyNA(input_paths) ||
      any(!nzchar(input_paths)) ||
      anyDuplicated(names(input_paths)) ||
      !setequal(names(input_paths), expected)
  ) {
    abort_pipeline(
      "Verifier input paths must have exactly these roles: %s",
      paste(expected, collapse = ", ")
    )
  }
  input_paths <- input_paths[expected]
  missing <- !file.exists(input_paths)
  if (any(missing)) {
    abort_pipeline(
      "Verifier input(s) do not exist: %s",
      paste(input_paths[missing], collapse = ", ")
    )
  }
  vapply(
    input_paths,
    normalizePath,
    character(1),
    winslash = "/",
    mustWork = TRUE
  )
}

p06tp_paths <- function(root) {
  paths <- pipeline_paths(root)
  output_root <- file.path(paths$model_data, "temporal_provenance")
  list(
    output_root = output_root,
    source_bins_rds = file.path(output_root, "true_utc_source_bins.rds"),
    source_bins_csv = file.path(output_root, "true_utc_source_bins.csv"),
    wall_links_rds = file.path(output_root, "wall_outcome_links.rds"),
    wall_links_csv = file.path(output_root, "wall_outcome_links.csv"),
    manifest = file.path(output_root, "artifact_manifest.csv")
  )
}

p06tp_relative_path <- function(path, anchor, object) {
  path <- normalizePath(path, winslash = "/", mustWork = TRUE)
  anchor <- normalizePath(anchor, winslash = "/", mustWork = TRUE)
  prefix <- paste0(anchor, "/")
  p06tp_require(
    startsWith(path, prefix),
    "%s is outside its declared provenance root: %s",
    object,
    path
  )
  substring(path, nchar(prefix) + 1L)
}

p06tp_manifest_columns <- function() {
  c(
    "path",
    "sha256",
    "bytes",
    "producer",
    "r_version",
    "artifact_type",
    "run_label",
    "coverage_input_paths",
    "coverage_inputs",
    "metric_input_paths",
    "metric_inputs",
    "coverage_manifest_path",
    "coverage_manifest_sha256",
    "metric_manifest_path",
    "metric_manifest_sha256",
    "sequence_contract",
    "wall_outcome_contract",
    "status",
    "rows",
    "columns"
  )
}

p06tp_bin_minutes <- function(resolution) {
  switch(
    resolution,
    `30_minute` = 30L,
    one_hour = 60L,
    abort_pipeline("Verifier encountered unknown resolution: %s", resolution)
  )
}

p06tp_metric_clock_column <- function(resolution) {
  switch(
    resolution,
    `30_minute` = "clock_bin",
    one_hour = "clock_minute",
    abort_pipeline("Verifier encountered unknown resolution: %s", resolution)
  )
}

p06tp_utc_label <- function(datetime) {
  format(datetime, "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
}

p06tp_source_id <- function(
  resolution,
  site,
  Id,
  position,
  true_utc_start
) {
  paste(
    resolution,
    site,
    Id,
    position,
    p06tp_utc_label(true_utc_start),
    sep = "|"
  )
}

p06tp_outcome_id <- function(
  resolution,
  site,
  Id,
  position,
  local_date,
  wall_bin_start_minute
) {
  paste(
    resolution,
    site,
    Id,
    position,
    format(as.Date(local_date), "%Y-%m-%d"),
    sprintf("%04d", as.integer(wall_bin_start_minute)),
    sep = "|"
  )
}

p06tp_local_day_type <- function(real_minutes) {
  ifelse(
    real_minutes == 1380L,
    "spring_forward_23h",
    ifelse(
      real_minutes == 1440L,
      "ordinary_24h",
      ifelse(
        real_minutes == 1500L,
        "fall_back_25h",
        "unsupported_day_length"
      )
    )
  )
}

p06tp_equal_vector <- function(observed, expected, label) {
  p06tp_require(
    length(observed) == length(expected),
    "%s differs in length",
    label
  )
  if (inherits(expected, "POSIXct")) {
    valid <- identical(
      as.numeric(observed),
      as.numeric(expected)
    )
  } else if (inherits(expected, "Date")) {
    valid <- identical(as.Date(observed), as.Date(expected))
  } else if (is.numeric(expected)) {
    valid <- isTRUE(all.equal(
      as.numeric(observed),
      as.numeric(expected),
      tolerance = 1e-12,
      check.attributes = FALSE
    ))
  } else {
    valid <- identical(observed, expected)
  }
  p06tp_require(valid, "%s differs from independent reconstruction", label)
  invisible(TRUE)
}

p06tp_compare_csv <- function(rds_data, csv_path, label) {
  csv <- readr::read_csv(
    csv_path,
    col_types = readr::cols(.default = readr::col_character()),
    na = "__NATHEALTH_MISSING__",
    show_col_types = FALSE,
    progress = FALSE
  )
  p06tp_require(
    identical(names(csv), names(rds_data)),
    "%s CSV columns differ from its RDS",
    label
  )
  p06tp_require(
    nrow(csv) == nrow(rds_data),
    "%s CSV row count differs from its RDS",
    label
  )
  for (column in names(rds_data)) {
    expected <- rds_data[[column]]
    observed <- csv[[column]]
    if (inherits(expected, "POSIXct")) {
      if (inherits(observed, "POSIXct")) {
        observed_value <- as.numeric(observed)
      } else {
        observed[observed == ""] <- NA_character_
        observed_value <- as.numeric(as.POSIXct(
          observed,
          format = "%Y-%m-%dT%H:%M:%SZ",
          tz = "UTC"
        ))
      }
      expected_value <- as.numeric(expected)
      valid <- identical(observed_value, expected_value)
    } else if (inherits(expected, "Date")) {
      observed[observed == ""] <- NA_character_
      valid <- identical(as.Date(observed), expected)
    } else if (is.logical(expected)) {
      observed[observed == ""] <- NA_character_
      valid <- identical(as.logical(observed), expected)
    } else if (is.integer(expected)) {
      observed[observed == ""] <- NA_character_
      valid <- identical(as.integer(observed), expected)
    } else if (is.numeric(expected)) {
      observed[observed == ""] <- NA_character_
      valid <- isTRUE(all.equal(
        as.numeric(observed),
        expected,
        tolerance = 1e-12,
        check.attributes = FALSE
      ))
    } else {
      expected_character <- as.character(expected)
      observed_character <- as.character(observed)
      observed_character[
        is.na(expected_character) & observed_character == ""
      ] <- NA_character_
      valid <- identical(observed_character, expected_character)
    }
    p06tp_require(
      valid,
      "%s CSV column `%s` differs from its RDS",
      label,
      column
    )
  }
  invisible(TRUE)
}

p06tp_reconstruct_source_bins <- function(
  coverage,
  metric,
  placement,
  resolution
) {
  bin_minutes <- p06tp_bin_minutes(resolution)
  day_key <- c("site", "Id", "position", "local_date")
  required_coverage <- c(
    day_key,
    "datetime_utc",
    "datetime_wall",
    "clock_minute",
    "utc_offset_minutes",
    "is_dst",
    "timezone",
    "source_subepochs",
    "implicit_subepochs",
    "MEDI_precoverage_observed",
    "coverage_period_eligible",
    "MEDI_coverage_eligible"
  )
  assert_columns(
    coverage,
    required_coverage,
    object = paste(placement, "verifier coverage")
  )
  assert_unique_key(
    coverage,
    c("site", "Id", "position", "datetime_utc"),
    object = paste(placement, "verifier coverage")
  )
  domain <- metric |>
    dplyr::distinct(dplyr::across(dplyr::all_of(day_key)))
  minute <- coverage |>
    dplyr::semi_join(domain, by = day_key) |>
    dplyr::select(dplyr::all_of(required_coverage)) |>
    dplyr::arrange(
      .data$site,
      .data$Id,
      .data$position,
      .data$local_date,
      .data$datetime_utc
    ) |>
    dplyr::group_by(dplyr::across(dplyr::all_of(day_key))) |>
    dplyr::mutate(
      day_start_utc = min(.data$datetime_utc),
      day_real_minutes = dplyr::n(),
      elapsed_minute = as.integer(
        as.numeric(difftime(
          .data$datetime_utc,
          .data$day_start_utc,
          units = "mins"
        ))
      ),
      elapsed_bin_index = as.integer(
        floor(.data$elapsed_minute / bin_minutes)
      ),
      wall_bin_start_minute = as.integer(
        floor(.data$clock_minute / bin_minutes) * bin_minutes
      )
    ) |>
    dplyr::ungroup()
  minute_continuity <- minute |>
    dplyr::group_by(dplyr::across(dplyr::all_of(day_key))) |>
    dplyr::summarise(
      day_real_minutes = dplyr::n(),
      utc_step_valid = all(
        diff(as.numeric(.data$datetime_utc)) == 60
      ),
      elapsed_index_valid = identical(
        .data$elapsed_minute,
        seq.int(0L, dplyr::n() - 1L)
      ),
      .groups = "drop"
    )
  p06tp_require(
    all(minute_continuity$utc_step_valid) &&
      all(minute_continuity$elapsed_index_valid) &&
      all(
        minute_continuity$day_real_minutes %in%
          c(1380L, 1440L, 1500L)
      ),
    "Coverage is not an independently valid true-minute local-day grid"
  )
  expected <- minute |>
    dplyr::group_by(
      dplyr::across(dplyr::all_of(day_key)),
      .data$elapsed_bin_index
    ) |>
    dplyr::summarise(
      true_utc_start = min(.data$datetime_utc),
      true_utc_end = max(.data$datetime_utc) + 60,
      true_utc_last_minute = max(.data$datetime_utc),
      wall_datetime_start = dplyr::first(.data$datetime_wall),
      wall_bin_start_minute = dplyr::first(
        .data$wall_bin_start_minute
      ),
      wall_bin_values = dplyr::n_distinct(
        .data$wall_bin_start_minute
      ),
      day_real_minutes = dplyr::first(.data$day_real_minutes),
      expected_real_minutes = dplyr::n(),
      source_present_real_minutes = sum(
        .data$source_subepochs > .data$implicit_subepochs
      ),
      observed_medi_real_minutes = sum(
        .data$MEDI_precoverage_observed
      ),
      coverage_eligible_real_minutes = sum(
        .data$coverage_period_eligible
      ),
      eligible_medi_real_minutes = sum(
        .data$MEDI_coverage_eligible
      ),
      utc_offset_start_minutes = dplyr::first(
        .data$utc_offset_minutes
      ),
      utc_offset_end_minutes = dplyr::last(
        .data$utc_offset_minutes
      ),
      utc_offsets_minutes = paste(
        unique(.data$utc_offset_minutes),
        collapse = "|"
      ),
      is_dst_start = dplyr::first(.data$is_dst),
      is_dst_end = dplyr::last(.data$is_dst),
      dst_states = paste(unique(.data$is_dst), collapse = "|"),
      timezone = dplyr::first(.data$timezone),
      .groups = "drop"
    )
  p06tp_require(
    all(expected$expected_real_minutes == bin_minutes) &&
      all(expected$wall_bin_values == 1L),
    "True-time source bins do not align to one wall outcome key"
  )
  expected <- expected |>
    dplyr::mutate(
      resolution = resolution,
      bin_minutes = as.integer(bin_minutes),
      local_day_type = p06tp_local_day_type(.data$day_real_minutes),
      source_support_fraction = .data$source_present_real_minutes /
        .data$expected_real_minutes,
      observed_medi_support_fraction = .data$observed_medi_real_minutes /
        .data$expected_real_minutes,
      eligible_medi_support_fraction = .data$eligible_medi_real_minutes /
        .data$expected_real_minutes,
      offset_changes_within_bin = .data$utc_offset_start_minutes !=
        .data$utc_offset_end_minutes,
      source_bin_id = p06tp_source_id(
        .data$resolution,
        .data$site,
        .data$Id,
        .data$position,
        .data$true_utc_start
      ),
      outcome_row_id = p06tp_outcome_id(
        .data$resolution,
        .data$site,
        .data$Id,
        .data$position,
        .data$local_date,
        .data$wall_bin_start_minute
      ),
      true_utc_range = paste0(
        p06tp_utc_label(.data$true_utc_start),
        "/",
        p06tp_utc_label(.data$true_utc_end)
      )
    ) |>
    dplyr::group_by(
      .data$resolution,
      dplyr::across(dplyr::all_of(day_key)),
      .data$wall_bin_start_minute
    ) |>
    dplyr::arrange(.data$true_utc_start, .by_group = TRUE) |>
    dplyr::mutate(
      source_bins_for_wall_outcome = dplyr::n(),
      wall_occurrence = dplyr::row_number(),
      repeated_fall_back_source_bin = .data$source_bins_for_wall_outcome > 1L
    ) |>
    dplyr::ungroup() |>
    dplyr::select(
      -dplyr::all_of(c(
        "elapsed_bin_index",
        "wall_bin_values"
      ))
    )
  expected
}

p06tp_compare_source_reconstruction <- function(observed, expected) {
  p06tp_require(
    !anyDuplicated(observed$source_bin_id),
    "Source-bin IDs are duplicated"
  )
  p06tp_require(
    setequal(observed$source_bin_id, expected$source_bin_id),
    "Source-bin key set differs from independent reconstruction"
  )
  observed <- observed[
    match(expected$source_bin_id, observed$source_bin_id),
    ,
    drop = FALSE
  ]
  fields <- c(
    "resolution",
    "bin_minutes",
    "site",
    "Id",
    "position",
    "local_date",
    "wall_bin_start_minute",
    "true_utc_start",
    "true_utc_end",
    "true_utc_last_minute",
    "wall_datetime_start",
    "day_real_minutes",
    "expected_real_minutes",
    "source_present_real_minutes",
    "observed_medi_real_minutes",
    "coverage_eligible_real_minutes",
    "eligible_medi_real_minutes",
    "utc_offset_start_minutes",
    "utc_offset_end_minutes",
    "utc_offsets_minutes",
    "is_dst_start",
    "is_dst_end",
    "dst_states",
    "timezone",
    "local_day_type",
    "source_support_fraction",
    "observed_medi_support_fraction",
    "eligible_medi_support_fraction",
    "offset_changes_within_bin",
    "source_bin_id",
    "outcome_row_id",
    "true_utc_range",
    "source_bins_for_wall_outcome",
    "wall_occurrence",
    "repeated_fall_back_source_bin"
  )
  assert_columns(observed, fields, object = "source provenance artifact")
  for (field in fields) {
    p06tp_equal_vector(
      observed[[field]],
      expected[[field]],
      paste0("Source field `", field, "`")
    )
  }
  invisible(observed)
}

p06tp_verify_wall_links <- function(
  observed,
  expected_source,
  metric,
  placement,
  resolution
) {
  bin_minutes <- p06tp_bin_minutes(resolution)
  clock_column <- p06tp_metric_clock_column(resolution)
  wall_key <- c(
    "resolution",
    "site",
    "Id",
    "position",
    "local_date",
    "wall_bin_start_minute"
  )
  outcome <- metric |>
    dplyr::transmute(
      resolution = resolution,
      bin_minutes = as.integer(bin_minutes),
      site = as.character(.data$site),
      Id = as.character(.data$Id),
      position = as.character(.data$position),
      local_date = as.Date(.data$local_date),
      wall_bin_start_minute = as.integer(.data[[clock_column]]),
      outcome_metric = as.character(.data$metric),
      outcome_expected_wall_minutes = as.integer(
        .data$expected_wall_minutes
      ),
      outcome_wall_minutes_existing = as.integer(
        .data$wall_minutes_existing
      ),
      outcome_source_real_minutes = as.integer(
        .data$source_real_minutes
      ),
      outcome_source_observed_real_minutes = as.integer(
        .data$source_observed_real_minutes
      ),
      outcome_dst_fold_wall_minutes = as.integer(
        .data$dst_fold_wall_minutes
      ),
      outcome_valid_medi_wall_minutes = as.integer(
        .data$valid_medi_wall_minutes
      ),
      outcome_ordinary_support = as.numeric(.data$ordinary_support),
      outcome_bin_admissible = as.logical(.data$bin_admissible),
      outcome_failure_reason = as.character(.data$failure_reason),
      outcome_metric_value_finite = is.finite(.data$metric_value_lx),
      outcome_usable = .data$outcome_bin_admissible &
        .data$outcome_metric_value_finite,
      outcome_row_id = p06tp_outcome_id(
        resolution,
        .data$site,
        .data$Id,
        .data$position,
        .data$local_date,
        .data[[clock_column]]
      )
    )
  source_summary <- expected_source |>
    dplyr::group_by(dplyr::across(dplyr::all_of(wall_key))) |>
    dplyr::arrange(.data$true_utc_start, .by_group = TRUE) |>
    dplyr::summarise(
      source_bin_links = dplyr::n(),
      source_bin_ids = paste(.data$source_bin_id, collapse = ";"),
      source_utc_ranges = paste(.data$true_utc_range, collapse = ";"),
      source_utc_start = min(.data$true_utc_start),
      source_utc_end = max(.data$true_utc_end),
      source_utc_offsets_minutes = paste(
        .data$utc_offsets_minutes,
        collapse = ";"
      ),
      source_dst_states = paste(.data$dst_states, collapse = ";"),
      source_expected_real_minutes_total = sum(
        .data$expected_real_minutes
      ),
      source_present_real_minutes_total = sum(
        .data$source_present_real_minutes
      ),
      source_observed_medi_real_minutes_total = sum(
        .data$observed_medi_real_minutes
      ),
      source_coverage_eligible_real_minutes_total = sum(
        .data$coverage_eligible_real_minutes
      ),
      source_eligible_medi_real_minutes_total = sum(
        .data$eligible_medi_real_minutes
      ),
      local_day_type = dplyr::first(.data$local_day_type),
      .groups = "drop"
    )
  day_type <- expected_source |>
    dplyr::distinct(
      .data$site,
      .data$Id,
      .data$position,
      .data$local_date,
      .data$local_day_type
    )
  expected <- outcome |>
    dplyr::left_join(
      source_summary,
      by = wall_key,
      relationship = "one-to-one"
    ) |>
    dplyr::left_join(
      day_type,
      by = c("site", "Id", "position", "local_date"),
      relationship = "many-to-one",
      suffix = c("", ".day")
    )
  expected$local_day_type <- dplyr::coalesce(
    expected$local_day_type,
    expected$local_day_type.day
  )
  expected$local_day_type.day <- NULL
  expected$source_bin_links <- dplyr::coalesce(
    as.integer(expected$source_bin_links),
    0L
  )
  integer_support <- c(
    "source_expected_real_minutes_total",
    "source_present_real_minutes_total",
    "source_observed_medi_real_minutes_total",
    "source_coverage_eligible_real_minutes_total",
    "source_eligible_medi_real_minutes_total"
  )
  for (field in integer_support) {
    expected[[field]] <- dplyr::coalesce(
      as.integer(expected[[field]]),
      0L
    )
  }
  character_support <- c(
    "source_bin_ids",
    "source_utc_ranges",
    "source_utc_offsets_minutes",
    "source_dst_states"
  )
  for (field in character_support) {
    expected[[field]] <- dplyr::coalesce(
      as.character(expected[[field]]),
      ""
    )
  }
  expected <- expected |>
    dplyr::mutate(
      relationship_type = dplyr::case_when(
        .data$source_bin_links == 0L ~ "zero_to_one_structural_spring_gap",
        .data$source_bin_links == 1L ~ "one_to_one_true_elapsed",
        .data$source_bin_links == 2L ~ "two_to_one_averaged_fall_back",
        TRUE ~ "invalid"
      ),
      fold_provenance = ifelse(
        .data$source_bin_links == 2L,
        "averaged_repeated_wall_bin",
        "none"
      ),
      spring_gap_provenance = ifelse(
        .data$source_bin_links == 0L,
        "structural_nonexistent_wall_bin",
        "none"
      ),
      one_to_one_elapsed_coordinate = .data$source_bin_links == 1L
    )
  p06tp_require(
    !anyDuplicated(observed$outcome_row_id),
    "%s %s outcome-row IDs are duplicated",
    placement,
    resolution
  )
  p06tp_require(
    setequal(observed$outcome_row_id, expected$outcome_row_id),
    "%s %s outcome key set differs from metric input",
    placement,
    resolution
  )
  observed <- observed[
    match(expected$outcome_row_id, observed$outcome_row_id),
    ,
    drop = FALSE
  ]
  fields <- names(expected)
  assert_columns(observed, fields, object = "wall-link artifact")
  for (field in fields) {
    p06tp_equal_vector(
      observed[[field]],
      expected[[field]],
      paste(
        placement,
        resolution,
        "wall-link field",
        field
      )
    )
  }
  p06tp_require(
    !"metric_value_lx" %in% names(observed),
    "Wall-link artifact duplicated or replaced approved outcome values"
  )
  invisible(expected)
}

p06tp_verify_sequence <- function(source_bins, wall_links) {
  wall_lookup <- wall_links |>
    dplyr::select(
      dplyr::all_of(c(
        "outcome_row_id",
        "one_to_one_elapsed_coordinate",
        "outcome_usable"
      ))
    )
  ordered <- source_bins |>
    dplyr::select(
      -dplyr::any_of(c(
        "one_to_one_elapsed_coordinate",
        "outcome_usable"
      ))
    ) |>
    dplyr::left_join(
      wall_lookup,
      by = "outcome_row_id",
      relationship = "many-to-one"
    ) |>
    dplyr::arrange(
      .data$resolution,
      .data$site,
      .data$Id,
      .data$position,
      .data$true_utc_start
    ) |>
    dplyr::group_by(
      .data$resolution,
      .data$site,
      .data$Id,
      .data$position
    ) |>
    dplyr::mutate(
      expected_previous_end = dplyr::lag(.data$true_utc_end),
      expected_elapsed = as.numeric(difftime(
        .data$true_utc_start,
        .data$expected_previous_end,
        units = "secs"
      )),
      expected_previous_wall_start = dplyr::lag(
        .data$wall_datetime_start
      ),
      expected_wall_elapsed = as.numeric(difftime(
        .data$wall_datetime_start,
        .data$expected_previous_wall_start,
        units = "mins"
      )),
      expected_previous_one_to_one = dplyr::lag(
        .data$one_to_one_elapsed_coordinate
      ),
      expected_previous_usable = dplyr::lag(.data$outcome_usable),
      expected_sequence_eligible = .data$one_to_one_elapsed_coordinate &
        .data$outcome_usable,
      expected_reason = dplyr::case_when(
        !.data$one_to_one_elapsed_coordinate ~
          "excluded_non_one_to_one_wall_outcome",
        !.data$outcome_usable ~ "excluded_unusable_wall_outcome",
        dplyr::row_number() == 1L ~ "participant_start",
        is.na(.data$expected_elapsed) ~ "participant_start",
        .data$expected_elapsed != 0 ~ "after_true_utc_gap",
        .data$expected_wall_elapsed != .data$bin_minutes ~
          "after_structural_wall_gap",
        !.data$expected_previous_one_to_one ~
          "after_non_one_to_one_wall_outcome",
        !.data$expected_previous_usable ~ "after_unusable_wall_outcome",
        TRUE ~ "continuous"
      ),
      expected_start = .data$expected_sequence_eligible &
        .data$expected_reason != "continuous",
      expected_sequence_number = cumsum(.data$expected_start),
      expected_sequence_id = ifelse(
        .data$expected_sequence_eligible,
        paste(
          .data$resolution,
          .data$site,
          .data$Id,
          .data$position,
          sprintf("S%05d", .data$expected_sequence_number),
          sep = "|"
        ),
        NA_character_
      )
    ) |>
    dplyr::ungroup()
  fields <- list(
    previous_true_utc_end = ordered$expected_previous_end,
    elapsed_from_previous_seconds = ordered$expected_elapsed,
    previous_wall_datetime_start = ordered$expected_previous_wall_start,
    wall_elapsed_from_previous_minutes = ordered$expected_wall_elapsed,
    previous_one_to_one_elapsed_coordinate = ordered$expected_previous_one_to_one,
    previous_outcome_usable = ordered$expected_previous_usable,
    sequence_eligible = ordered$expected_sequence_eligible,
    sequence_start_reason = ordered$expected_reason,
    true_elapsed_sequence_start = ordered$expected_start,
    true_elapsed_sequence_id = ordered$expected_sequence_id
  )
  for (field in names(fields)) {
    p06tp_equal_vector(
      ordered[[field]],
      fields[[field]],
      paste0("Sequence field `", field, "`")
    )
  }
  p06tp_require(
    !any(
      ordered$repeated_fall_back_source_bin &
        ordered$sequence_eligible
    ),
    "A fall-back source bin is sequence eligible"
  )
  continued <- ordered$sequence_start_reason == "continuous"
  p06tp_require(
    all(
      !continued |
        (ordered$elapsed_from_previous_seconds == 0 &
          ordered$wall_elapsed_from_previous_minutes == ordered$bin_minutes &
          ordered$previous_one_to_one_elapsed_coordinate &
          ordered$previous_outcome_usable)
    ),
    "A sequence bridges a true-time gap or unusable outcome"
  )
  invisible(TRUE)
}

p06tp_verify_known_dst_scope <- function(source_bins, wall_links) {
  fold_days <- source_bins |>
    dplyr::filter(.data$repeated_fall_back_source_bin) |>
    dplyr::distinct(.data$site, .data$Id, .data$position, .data$local_date)
  expected_fold_days <- tibble::tribble(
    ~site,
    ~Id,
    ~position,
    ~local_date,
    "FUSPCEU",
    "FUSPCEU_S007",
    "glasses",
    as.Date("2024-10-27"),
    "FUSPCEU",
    "FUSPCEU_S008",
    "glasses",
    as.Date("2024-10-27"),
    "MPI",
    "MPI_S221",
    "glasses",
    as.Date("2023-10-29"),
    "MPI",
    "MPI_S222",
    "glasses",
    as.Date("2023-10-29"),
    "FUSPCEU",
    "FUSPCEU_S007",
    "chest",
    as.Date("2024-10-27"),
    "FUSPCEU",
    "FUSPCEU_S008",
    "chest",
    as.Date("2024-10-27")
  )
  p06tp_require(
    nrow(dplyr::anti_join(
      fold_days,
      expected_fold_days,
      by = c("site", "Id", "position", "local_date")
    )) ==
      0L &&
      nrow(dplyr::anti_join(
        expected_fold_days,
        fold_days,
        by = c("site", "Id", "position", "local_date")
      )) ==
        0L,
    "Known fall-back participant-day scope differs"
  )
  fold_counts <- wall_links |>
    dplyr::filter(.data$source_bin_links == 2L) |>
    dplyr::count(.data$position, .data$resolution, name = "rows")
  expected_fold_counts <- tibble::tribble(
    ~position,
    ~resolution,
    ~rows,
    "glasses",
    "30_minute",
    8L,
    "glasses",
    "one_hour",
    4L,
    "chest",
    "30_minute",
    4L,
    "chest",
    "one_hour",
    2L
  )
  fold_count_difference <- dplyr::bind_rows(
    dplyr::anti_join(
      fold_counts,
      expected_fold_counts,
      by = c("position", "resolution", "rows")
    ),
    dplyr::anti_join(
      expected_fold_counts,
      fold_counts,
      by = c("position", "resolution", "rows")
    )
  )
  p06tp_require(
    nrow(fold_count_difference) == 0L,
    "Known fall-back wall-bin counts differ"
  )
  gap_counts <- wall_links |>
    dplyr::filter(.data$source_bin_links == 0L) |>
    dplyr::count(.data$position, .data$resolution, name = "rows")
  expected_gap_counts <- tibble::tribble(
    ~position,
    ~resolution,
    ~rows,
    "glasses",
    "30_minute",
    4L,
    "glasses",
    "one_hour",
    2L,
    "chest",
    "30_minute",
    4L,
    "chest",
    "one_hour",
    2L
  )
  gap_count_difference <- dplyr::bind_rows(
    dplyr::anti_join(
      gap_counts,
      expected_gap_counts,
      by = c("position", "resolution", "rows")
    ),
    dplyr::anti_join(
      expected_gap_counts,
      gap_counts,
      by = c("position", "resolution", "rows")
    )
  )
  p06tp_require(
    nrow(gap_count_difference) == 0L,
    "Known spring-gap wall-bin counts differ"
  )
  spring_days <- wall_links |>
    dplyr::filter(.data$source_bin_links == 0L) |>
    dplyr::distinct(.data$site, .data$Id, .data$position, .data$local_date)
  expected_spring_days <- tidyr::crossing(
    tibble::tribble(
      ~site,
      ~Id,
      ~local_date,
      "RISE",
      "RISE_S004",
      as.Date("2025-03-30"),
      "THUAS",
      "THUAS_S005",
      as.Date("2025-03-30")
    ),
    position = c("chest", "glasses")
  )
  p06tp_require(
    nrow(dplyr::anti_join(
      spring_days,
      expected_spring_days,
      by = c("site", "Id", "position", "local_date")
    )) ==
      0L &&
      nrow(dplyr::anti_join(
        expected_spring_days,
        spring_days,
        by = c("site", "Id", "position", "local_date")
      )) ==
        0L,
    "Known spring-forward participant-day scope differs"
  )
  list(
    fold_participant_days = nrow(fold_days),
    fold_wall_rows = sum(fold_counts$rows),
    spring_gap_participant_days = nrow(spring_days),
    spring_gap_wall_rows = sum(gap_counts$rows)
  )
}

p06tp_verify_manifest <- function(
  root,
  paths,
  source_bins,
  wall_links,
  input_paths,
  input_root
) {
  required_paths <- unlist(
    paths[names(paths) != "output_root"],
    use.names = FALSE
  )
  p06tp_require(
    all(file.exists(required_paths)),
    "One or more temporal-provenance artifacts are missing"
  )
  manifest <- readr::read_csv(
    paths$manifest,
    show_col_types = FALSE,
    progress = FALSE
  )
  expected_types <- c(
    "true_utc_source_bins_rds",
    "true_utc_source_bins_csv",
    "wall_outcome_links_rds",
    "wall_outcome_links_csv"
  )
  p06tp_require(
    identical(names(manifest), p06tp_manifest_columns()) &&
      nrow(manifest) == 4L &&
      setequal(manifest$artifact_type, expected_types) &&
      !anyDuplicated(manifest$artifact_type) &&
      !"written_utc" %in% names(manifest) &&
      all(!grepl("^/", manifest$path)) &&
      all(!grepl("=[/]", manifest$coverage_input_paths)) &&
      all(!grepl("=[/]", manifest$metric_input_paths)) &&
      all(!grepl("^/", manifest$coverage_manifest_path)) &&
      all(!grepl("^/", manifest$metric_manifest_path)) &&
      all(
        manifest$producer ==
          "scripts/pipeline/build_temporal_sequence_provenance.R"
      ) &&
      all(manifest$r_version == "4.6.1") &&
      all(manifest$status == "PASS") &&
      all(
        manifest$sequence_contract ==
          "true_utc_adjacency_with_unusable_and_non_one_to_one_breaks"
      ) &&
      all(
        manifest$wall_outcome_contract == "clock_aligned_values_unchanged"
      ),
    paste0(
      "Temporal-provenance manifest schema, portability, or contract ",
      "differs"
    )
  )
  expected_paths <- c(
    true_utc_source_bins_rds = paths$source_bins_rds,
    true_utc_source_bins_csv = paths$source_bins_csv,
    wall_outcome_links_rds = paths$wall_links_rds,
    wall_outcome_links_csv = paths$wall_links_csv
  )
  for (artifact_type in expected_types) {
    row <- manifest[
      manifest$artifact_type == artifact_type,
      ,
      drop = FALSE
    ]
    expected_absolute_path <- normalizePath(
      expected_paths[[artifact_type]],
      winslash = "/",
      mustWork = TRUE
    )
    expected_relative_path <- p06tp_relative_path(
      expected_absolute_path,
      root,
      "Verifier temporal-provenance output"
    )
    p06tp_require(
      nrow(row) == 1L &&
        identical(row$path[[1L]], expected_relative_path) &&
        artifact_sha256(expected_absolute_path) == row$sha256[[1L]] &&
        file.info(expected_absolute_path)$size == as.numeric(row$bytes[[1L]]),
      "Temporal-provenance manifest path, hash, or size differs for %s",
      artifact_type
    )
  }
  expected_dimensions <- tibble::tribble(
    ~artifact_type,
    ~rows,
    ~columns,
    "true_utc_source_bins_rds",
    nrow(source_bins),
    ncol(source_bins),
    "true_utc_source_bins_csv",
    nrow(source_bins),
    ncol(source_bins),
    "wall_outcome_links_rds",
    nrow(wall_links),
    ncol(wall_links),
    "wall_outcome_links_csv",
    nrow(wall_links),
    ncol(wall_links)
  )
  checked_dimensions <- dplyr::left_join(
    manifest,
    expected_dimensions,
    by = "artifact_type",
    suffix = c(".manifest", ".expected"),
    relationship = "one-to-one"
  )
  p06tp_require(
    all(
      checked_dimensions$rows.manifest == checked_dimensions$rows.expected
    ) &&
      all(
        checked_dimensions$columns.manifest ==
          checked_dimensions$columns.expected
      ),
    "Temporal-provenance manifest dimensions differ"
  )

  roles <- p06tp_input_roles()
  actual_hashes <- vapply(input_paths, artifact_sha256, character(1))
  relative_input_paths <- vapply(
    input_paths,
    p06tp_relative_path,
    character(1),
    anchor = input_root,
    object = "Verifier temporal-provenance input"
  )
  compact_paths <- function(kind) {
    selected <- roles[roles$input_kind == kind, , drop = FALSE]
    selected <- selected[order(selected$input_role), , drop = FALSE]
    paste(
      paste(
        selected$input_role,
        relative_input_paths[selected$input_role],
        sep = "="
      ),
      collapse = ";"
    )
  }
  compact_hashes <- function(kind) {
    selected <- roles[roles$input_kind == kind, , drop = FALSE]
    selected <- selected[order(selected$input_role), , drop = FALSE]
    paste(
      paste(
        selected$input_role,
        actual_hashes[selected$input_role],
        sep = "="
      ),
      collapse = ";"
    )
  }
  p06tp_require(
    all(
      manifest$coverage_input_paths == compact_paths("coverage")
    ) &&
      all(manifest$coverage_inputs == compact_hashes("coverage")) &&
      all(manifest$metric_input_paths == compact_paths("metric")) &&
      all(manifest$metric_inputs == compact_hashes("metric")),
    "Manifest input paths or hashes differ from current upstream artifacts"
  )
  pipeline <- pipeline_paths(input_root)
  coverage_manifest <- file.path(
    pipeline$manifests,
    "coverage_artifacts.csv"
  )
  metric_manifest <- file.path(
    pipeline$manifests,
    "metric_artifacts.csv"
  )
  expected_coverage_manifest_path <- p06tp_relative_path(
    coverage_manifest,
    input_root,
    "Verifier coverage manifest"
  )
  expected_metric_manifest_path <- p06tp_relative_path(
    metric_manifest,
    input_root,
    "Verifier metric manifest"
  )
  p06tp_require(
    all(
      manifest$coverage_manifest_path == expected_coverage_manifest_path
    ) &&
      all(
        manifest$coverage_manifest_sha256 == artifact_sha256(coverage_manifest)
      ) &&
      all(
        manifest$metric_manifest_path == expected_metric_manifest_path
      ) &&
      all(
        manifest$metric_manifest_sha256 == artifact_sha256(metric_manifest)
      ),
    "Manifest upstream-manifest paths or hashes differ"
  )
  manifest
}

verify_temporal_sequence_provenance_artifacts <- function(
  root = project_root(),
  input_paths = NULL,
  input_root = root,
  stop_on_failure = TRUE
) {
  root <- normalizePath(root, winslash = "/", mustWork = TRUE)
  input_root <- normalizePath(
    input_root,
    winslash = "/",
    mustWork = TRUE
  )
  verify_impl <- function() {
    paths <- p06tp_paths(root)
    resolved_input_paths <- p06tp_resolve_input_paths(
      input_paths,
      input_root
    )
    source_bins <- read_rds_artifact(
      paths$source_bins_rds,
      expected_class = "data.frame"
    )
    wall_links <- read_rds_artifact(
      paths$wall_links_rds,
      expected_class = "data.frame"
    )
    p06tp_require(
      !"metric_value_lx" %in% c(names(source_bins), names(wall_links)),
      "Temporal provenance must not duplicate or replace outcome values"
    )
    manifest <- p06tp_verify_manifest(
      root,
      paths,
      source_bins,
      wall_links,
      resolved_input_paths,
      input_root
    )
    p06tp_compare_csv(
      source_bins,
      paths$source_bins_csv,
      "True-UTC source bins"
    )
    p06tp_compare_csv(
      wall_links,
      paths$wall_links_csv,
      "Wall outcome links"
    )

    expected_sources <- list()
    combination_index <- 0L
    for (placement in c("glasses", "chest")) {
      coverage <- readRDS(
        resolved_input_paths[[paste0(placement, "_coverage")]]
      )
      for (resolution in c("30_minute", "one_hour")) {
        combination_index <- combination_index + 1L
        metric <- readRDS(resolved_input_paths[[
          paste(placement, resolution, sep = "_")
        ]])
        expected <- p06tp_reconstruct_source_bins(
          coverage,
          metric,
          placement,
          resolution
        )
        observed_source <- source_bins |>
          dplyr::filter(
            .data$position == .env$placement,
            .data$resolution == .env$resolution
          )
        p06tp_compare_source_reconstruction(observed_source, expected)
        observed_links <- wall_links |>
          dplyr::filter(
            .data$position == .env$placement,
            .data$resolution == .env$resolution
          )
        p06tp_verify_wall_links(
          observed_links,
          expected,
          metric,
          placement,
          resolution
        )
        expected_sources[[combination_index]] <- expected
      }
      rm(coverage)
      invisible(gc(verbose = FALSE))
    }
    p06tp_require(
      nrow(source_bins) ==
        sum(vapply(
          expected_sources,
          nrow,
          integer(1)
        )),
      "Combined source-bin row count differs"
    )
    p06tp_verify_sequence(source_bins, wall_links)
    dst_scope <- p06tp_verify_known_dst_scope(source_bins, wall_links)

    list(
      status = "PASS",
      error = NA_character_,
      source_bin_rows = nrow(source_bins),
      wall_link_rows = nrow(wall_links),
      fold_participant_days = dst_scope$fold_participant_days,
      fold_wall_rows = dst_scope$fold_wall_rows,
      spring_gap_participant_days = dst_scope$spring_gap_participant_days,
      spring_gap_wall_rows = dst_scope$spring_gap_wall_rows,
      non_one_to_one_source_bins = sum(
        !source_bins$one_to_one_elapsed_coordinate
      ),
      sequence_eligible_bins = sum(source_bins$sequence_eligible),
      sequence_starts = sum(source_bins$true_elapsed_sequence_start),
      manifest_rows = nrow(manifest),
      manifest_sha256 = artifact_sha256(paths$manifest)
    )
  }
  result <- tryCatch(
    verify_impl(),
    error = function(error) {
      list(
        status = "FAIL",
        error = conditionMessage(error)
      )
    }
  )
  if (result$status == "FAIL" && isTRUE(stop_on_failure)) {
    abort_pipeline(
      "Temporal sequence-provenance verification failed: %s",
      result$error
    )
  }
  result
}
