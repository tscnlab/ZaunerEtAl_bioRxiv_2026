# Post-build verification for Canonical Preparation 02.
#
# Source paths_io.R and assertions.R before calling
# verify_coverage_artifacts(). The verifier reads completed artifacts only;
# it does not call the Preparation 02 builder or modify any artifact.

coverage_verification_layout <- function(
  root,
  run_label = "full",
  aligned_run_root = NULL,
  coverage_run_root = NULL
) {
  if (
    !is.character(run_label) ||
      length(run_label) != 1L ||
      is.na(run_label) ||
      !grepl("^[A-Za-z0-9._-]+$", run_label)
  ) {
    abort_pipeline("`run_label` must be one safe non-empty label")
  }
  paths <- pipeline_paths(root)
  aligned_root <- if (is.null(aligned_run_root)) {
    if (identical(run_label, "full")) {
      paths$aligned
    } else {
      file.path(paths$aligned, "runs", run_label)
    }
  } else {
    aligned_run_root
  }
  coverage_root <- if (is.null(coverage_run_root)) {
    if (identical(run_label, "full")) {
      paths$coverage
    } else {
      file.path(paths$coverage, "runs", run_label)
    }
  } else {
    coverage_run_root
  }
  manifest_suffix <- if (identical(run_label, "full")) {
    ""
  } else {
    paste0("_", run_label)
  }
  list(
    run_label = run_label,
    aligned_root = normalizePath(
      aligned_root,
      winslash = "/",
      mustWork = TRUE
    ),
    coverage_root = normalizePath(
      coverage_root,
      winslash = "/",
      mustWork = TRUE
    ),
    manifest_path = file.path(
      paths$manifests,
      paste0("coverage_artifacts", manifest_suffix, ".csv")
    )
  )
}

coverage_verify_manifest_bytes <- function(manifest) {
  assert_columns(
    manifest,
    c("path", "sha256", "bytes", "artifact_type", "run_label"),
    object = "Preparation 02 artifact manifest"
  )
  assert_unique_key(
    manifest,
    "path",
    object = "Preparation 02 artifact manifest"
  )
  if (
    anyNA(manifest$path) ||
      anyNA(manifest$sha256) ||
      anyNA(manifest$bytes)
  ) {
    abort_pipeline(
      "Preparation 02 artifact manifest has missing byte metadata"
    )
  }
  present <- file.exists(manifest$path)
  if (!all(present)) {
    abort_pipeline(
      "Preparation 02 manifest references missing file(s): %s",
      paste(manifest$path[!present], collapse = ", ")
    )
  }
  observed_sha256 <- vapply(
    manifest$path,
    artifact_sha256,
    character(1)
  )
  observed_bytes <- unname(file.info(manifest$path)$size)
  hash_match <- observed_sha256 == as.character(manifest$sha256)
  byte_match <- observed_bytes == manifest$bytes
  valid <- !is.na(hash_match) & !is.na(byte_match) & hash_match & byte_match
  if (!all(valid)) {
    abort_pipeline(
      "Preparation 02 manifest disagrees with file bytes for: %s",
      paste(manifest$path[!valid], collapse = ", ")
    )
  }
  tibble::tibble(
    artifacts = nrow(manifest),
    files_present = sum(present),
    sha256_matches = sum(hash_match),
    byte_counts_match = sum(byte_match)
  )
}

coverage_assert_constant <- function(data, column, expected, object) {
  assert_columns(data, column, object = object)
  observed <- data[[column]]
  if (
    length(observed) == 0L ||
      anyNA(observed) ||
      !all(observed == expected)
  ) {
    abort_pipeline(
      "%s does not record `%s` as %s",
      object,
      column,
      paste(expected, collapse = ",")
    )
  }
  invisible(data)
}

coverage_assert_rule_a <- function(data, object, manifest = FALSE) {
  constants <- list(
    coverage_rule_id = "A",
    coverage_signal = "MEDI",
    daily_denominator_domain = "all_pseudo_local_wall_minutes",
    diary_sleep_excluded_from_denominator = FALSE,
    minimum_hour_coverage = 0.5,
    minimum_day_coverage = 0.8
  )
  if (manifest) {
    constants$wall_minutes_per_hour <- 60
    constants$wall_minutes_per_day <- 1440
  } else {
    constants$expected_wall_minutes_per_hour <- 60
    constants$expected_wall_minutes_per_day <- 1440
  }
  for (column in names(constants)) {
    coverage_assert_constant(
      data,
      column,
      constants[[column]],
      object
    )
  }
  invisible(data)
}

coverage_values_equal <- function(x, y, tolerance = 1e-12) {
  if (length(x) != length(y) || !identical(is.na(x), is.na(y))) {
    return(FALSE)
  }
  available <- !is.na(x)
  if (!any(available)) {
    return(TRUE)
  }
  if (
    inherits(x, "POSIXt") ||
      inherits(y, "POSIXt") ||
      inherits(x, "Date") ||
      inherits(y, "Date")
  ) {
    return(isTRUE(all.equal(
      as.numeric(x[available]),
      as.numeric(y[available]),
      tolerance = tolerance,
      check.attributes = FALSE
    )))
  }
  if (is.numeric(x) && is.numeric(y)) {
    return(isTRUE(all.equal(
      as.numeric(x[available]),
      as.numeric(y[available]),
      tolerance = tolerance,
      check.attributes = FALSE
    )))
  }
  identical(
    as.character(x[available]),
    as.character(y[available])
  )
}

coverage_assert_table_equal <- function(
  observed,
  expected,
  key,
  fields,
  object
) {
  assert_columns(observed, c(key, fields), object = object)
  assert_columns(
    expected,
    c(key, fields),
    object = paste0("expected ", object)
  )
  assert_unique_key(observed, key, object = object)
  assert_unique_key(
    expected,
    key,
    object = paste0("expected ", object)
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
  for (column in key) {
    if (!coverage_values_equal(observed[[column]], expected[[column]])) {
      abort_pipeline("%s has different keys in `%s`", object, column)
    }
  }
  for (column in fields) {
    if (!coverage_values_equal(observed[[column]], expected[[column]])) {
      abort_pipeline(
        paste0(
          "%s disagrees with independent reconstruction in `%s`; ",
          "observed head: %s; expected head: %s"
        ),
        object,
        column,
        paste(utils::head(observed[[column]], 5L), collapse = ","),
        paste(utils::head(expected[[column]], 5L), collapse = ",")
      )
    }
  }
  invisible(TRUE)
}

coverage_verify_inherited_signal_invariants <- function(
  data,
  object,
  saturation_threshold = 100000
) {
  required <- c(
    "MEDI",
    "LIGHT",
    "MEDI_raw",
    "LIGHT_raw",
    "invalid_nonwear",
    "medi_saturated",
    "valid_medi",
    "valid_light",
    "valid_medi_light_pair"
  )
  assert_columns(data, required, object = object)
  flags <- c(
    "invalid_nonwear",
    "medi_saturated",
    "valid_medi",
    "valid_light",
    "valid_medi_light_pair"
  )
  invalid_flags <- flags[
    !vapply(
      data[flags],
      function(value) is.logical(value) && !anyNA(value),
      logical(1)
    )
  ]
  if (length(invalid_flags) > 0L) {
    abort_pipeline(
      "%s has incomplete or non-logical validity flags: %s",
      object,
      paste(invalid_flags, collapse = ", ")
    )
  }
  expected_saturated <- is.finite(data$MEDI_raw) &
    data$MEDI_raw >= saturation_threshold
  if (!identical(as.logical(data$medi_saturated), expected_saturated)) {
    abort_pipeline(
      "%s does not implement MEDI >=100000 as operating-boundary invalid",
      object
    )
  }
  if (
    any(expected_saturated & is.finite(data$MEDI)) ||
      any(is.finite(data$MEDI) & data$MEDI >= saturation_threshold)
  ) {
    abort_pipeline("%s retains MEDI at or above 100000 lx", object)
  }
  saturation_only <- expected_saturated & !data$invalid_nonwear
  if (
    any(
      is.finite(data$LIGHT_raw[saturation_only]) &
        !is.finite(data$LIGHT[saturation_only])
    )
  ) {
    abort_pipeline(
      "%s incorrectly propagates the MEDI boundary to LIGHT",
      object
    )
  }
  if (
    any(
      data$invalid_nonwear &
        (is.finite(data$MEDI) | is.finite(data$LIGHT))
    )
  ) {
    abort_pipeline("%s retains a signal during invalid non-wear", object)
  }
  expected_valid_medi <- is.finite(data$MEDI)
  expected_valid_light <- is.finite(data$LIGHT)
  if (
    !identical(as.logical(data$valid_medi), expected_valid_medi) ||
      !identical(as.logical(data$valid_light), expected_valid_light) ||
      !identical(
        as.logical(data$valid_medi_light_pair),
        expected_valid_medi & expected_valid_light
      )
  ) {
    abort_pipeline("%s has inconsistent signal-validity flags", object)
  }
  invisible(data)
}

coverage_reconstruct_rule_a <- function(aligned, placement) {
  required <- c(
    "site",
    "Id",
    "position",
    "datetime_utc",
    "local_date",
    "clock_minute",
    "MEDI"
  )
  assert_columns(
    aligned,
    required,
    object = paste0(placement, " aligned input")
  )
  assert_unique_key(
    aligned,
    c("site", "Id", "position", "datetime_utc"),
    object = paste0(placement, " aligned input")
  )
  if (
    anyNA(aligned$clock_minute) ||
      any(aligned$clock_minute < 0L) ||
      any(aligned$clock_minute > 1439L) ||
      any(aligned$clock_minute != as.integer(aligned$clock_minute))
  ) {
    abort_pipeline(
      "%s aligned input has invalid wall-clock minute keys",
      placement
    )
  }
  if (
    anyNA(aligned$position) ||
      !identical(unique(as.character(aligned$position)), placement)
  ) {
    abort_pipeline("%s aligned input has a wrong placement", placement)
  }

  day_key <- c("site", "Id", "position", "local_date")
  wall_key <- c(day_key, "clock_minute")
  wall <- aligned |>
    dplyr::group_by(dplyr::across(dplyr::all_of(wall_key))) |>
    dplyr::summarise(
      wall_source_real_minutes = dplyr::n(),
      wall_distinct_utc_minutes = dplyr::n_distinct(.data$datetime_utc),
      coverage_signal_observed = any(is.finite(.data$MEDI)),
      .groups = "drop"
    ) |>
    dplyr::mutate(
      wall_dst_fold = .data$wall_distinct_utc_minutes > 1L,
      clock_hour = as.integer(.data$clock_minute %/% 60L)
    )

  days <- dplyr::distinct(
    aligned,
    dplyr::across(dplyr::all_of(day_key))
  )
  hourly <- days[
    rep(seq_len(nrow(days)), each = 24L),
    ,
    drop = FALSE
  ]
  hourly$clock_hour <- rep(0:23, times = nrow(days))
  observed_hourly <- wall |>
    dplyr::group_by(
      dplyr::across(dplyr::all_of(day_key)),
      .data$clock_hour
    ) |>
    dplyr::summarise(
      hour_observed_wall_minutes = dplyr::n(),
      hour_source_real_minutes = sum(.data$wall_source_real_minutes),
      hour_valid_minutes = sum(.data$coverage_signal_observed),
      hour_dst_fold_minutes = sum(.data$wall_dst_fold),
      .groups = "drop"
    )
  hourly <- dplyr::left_join(
    hourly,
    observed_hourly,
    by = c(day_key, "clock_hour"),
    relationship = "one-to-one"
  )
  count_fields <- c(
    "hour_observed_wall_minutes",
    "hour_source_real_minutes",
    "hour_valid_minutes",
    "hour_dst_fold_minutes"
  )
  for (column in count_fields) {
    hourly[[column]] <- dplyr::coalesce(
      as.integer(hourly[[column]]),
      0L
    )
  }
  hourly$hour_expected_wall_minutes <- 60L
  hourly$hour_valid_fraction <- hourly$hour_valid_minutes / 60
  hourly$hour_eligible <- hourly$hour_valid_fraction >= 0.5
  hourly <- dplyr::select(
    hourly,
    dplyr::all_of(c(
      day_key,
      "clock_hour",
      "hour_expected_wall_minutes",
      "hour_observed_wall_minutes",
      "hour_source_real_minutes",
      "hour_valid_minutes",
      "hour_valid_fraction",
      "hour_dst_fold_minutes",
      "hour_eligible"
    ))
  )

  daily <- hourly |>
    dplyr::group_by(dplyr::across(dplyr::all_of(day_key))) |>
    dplyr::summarise(
      day_expected_wall_minutes = 1440L,
      day_observed_wall_minutes = sum(.data$hour_observed_wall_minutes),
      day_source_real_minutes = sum(.data$hour_source_real_minutes),
      day_valid_minutes_raw = sum(.data$hour_valid_minutes),
      day_valid_minutes_after_hour = sum(
        .data$hour_valid_minutes[.data$hour_eligible]
      ),
      day_valid_fraction_after_hour = .data$day_valid_minutes_after_hour /
        1440,
      day_eligible_hours = sum(.data$hour_eligible),
      day_dst_fold_minutes = sum(.data$hour_dst_fold_minutes),
      day_eligible = .data$day_valid_fraction_after_hour >= 0.8,
      .groups = "drop"
    )
  list(wall = wall, hourly = hourly, daily = daily)
}

coverage_expected_sample_flow <- function(eligible, placement) {
  count_stage <- function(include) {
    selected <- eligible[include, , drop = FALSE]
    tibble::tibble(
      participants = nrow(dplyr::distinct(
        selected,
        .data$site,
        .data$Id
      )),
      participant_days = nrow(dplyr::distinct(
        selected,
        .data$site,
        .data$Id,
        .data$position,
        .data$local_date
      )),
      true_utc_minutes = nrow(selected),
      wall_minutes = nrow(dplyr::distinct(
        selected,
        .data$site,
        .data$Id,
        .data$position,
        .data$local_date,
        .data$clock_minute
      )),
      finite_medi_minutes = sum(is.finite(selected$MEDI_precoverage)),
      finite_light_minutes = sum(is.finite(selected$LIGHT_precoverage))
    )
  }
  stages <- list(
    list(1L, "common", "aligned_real_minutes", rep(TRUE, nrow(eligible))),
    list(
      2L,
      "MEDI",
      "precoverage_medi_finite",
      is.finite(eligible$MEDI_precoverage)
    ),
    list(
      3L,
      "LIGHT",
      "precoverage_light_finite",
      is.finite(eligible$LIGHT_precoverage)
    ),
    list(
      4L,
      "coverage",
      "hour_eligible_real_minutes",
      eligible$hour_eligible
    ),
    list(
      5L,
      "coverage",
      "day_eligible_real_minutes",
      eligible$day_eligible
    ),
    list(
      6L,
      "coverage",
      "hour_and_day_eligible_real_minutes",
      eligible$coverage_period_eligible
    ),
    list(
      7L,
      "MEDI",
      "medi_eligible_real_minutes",
      eligible$MEDI_coverage_eligible
    ),
    list(
      8L,
      "LIGHT",
      "light_eligible_real_minutes",
      eligible$LIGHT_coverage_eligible
    )
  )
  sites <- sort(unique(as.character(eligible$site)))
  scopes <- c(sites, "ALL")
  dplyr::bind_rows(lapply(scopes, function(site_label) {
    scope <- if (identical(site_label, "ALL")) {
      rep(TRUE, nrow(eligible))
    } else {
      eligible$site == site_label
    }
    dplyr::bind_rows(lapply(stages, function(stage) {
      dplyr::mutate(
        count_stage(scope & stage[[4L]]),
        placement = placement,
        scope = if (identical(site_label, "ALL")) "overall" else "site",
        site = site_label,
        stage_order = stage[[1L]],
        stage_branch = stage[[2L]],
        stage = stage[[3L]],
        .before = 1L
      )
    }))
  }))
}

coverage_verify_eligible_channels <- function(
  aligned,
  eligible,
  reconstructed,
  placement
) {
  key <- c("site", "Id", "position", "datetime_utc")
  assert_unique_key(
    eligible,
    key,
    object = paste0(placement, " coverage-annotated minutes")
  )
  missing_input_columns <- setdiff(names(aligned), names(eligible))
  if (length(missing_input_columns) > 0L) {
    abort_pipeline(
      "%s coverage output dropped input column(s): %s",
      placement,
      paste(missing_input_columns, collapse = ", ")
    )
  }
  if (nrow(aligned) != nrow(eligible)) {
    abort_pipeline("%s coverage output changed the input row count", placement)
  }
  for (column in names(aligned)) {
    if (!identical(aligned[[column]], eligible[[column]])) {
      abort_pipeline(
        "%s coverage output changed input column `%s` or row order",
        placement,
        column
      )
    }
  }

  required <- c(
    "wall_source_real_minutes",
    "wall_distinct_utc_minutes",
    "wall_dst_fold",
    "hour_valid_minutes",
    "hour_valid_fraction",
    "hour_eligible",
    "day_valid_minutes_raw",
    "day_valid_minutes_after_hour",
    "day_valid_fraction_after_hour",
    "day_eligible",
    "coverage_period_eligible",
    "coverage_signal_observed_real",
    "coverage_value_eligible_real",
    "MEDI_precoverage",
    "LIGHT_precoverage",
    "MEDI_precoverage_observed",
    "LIGHT_precoverage_observed",
    "MEDI_coverage_eligible",
    "LIGHT_coverage_eligible",
    "MEDI_eligible",
    "LIGHT_eligible",
    "MEDI_eligibility_reason",
    "LIGHT_eligibility_reason"
  )
  assert_columns(
    eligible,
    required,
    object = paste0(placement, " coverage-annotated minutes")
  )

  expected <- dplyr::mutate(
    aligned,
    clock_hour = as.integer(.data$clock_minute %/% 60L)
  )
  expected <- dplyr::left_join(
    expected,
    dplyr::select(
      reconstructed$wall,
      dplyr::all_of(c(
        "site",
        "Id",
        "position",
        "local_date",
        "clock_minute",
        "wall_source_real_minutes",
        "wall_distinct_utc_minutes",
        "wall_dst_fold"
      ))
    ),
    by = c("site", "Id", "position", "local_date", "clock_minute"),
    relationship = "many-to-one"
  )
  expected <- dplyr::left_join(
    expected,
    dplyr::select(
      reconstructed$hourly,
      dplyr::all_of(c(
        "site",
        "Id",
        "position",
        "local_date",
        "clock_hour",
        "hour_valid_minutes",
        "hour_valid_fraction",
        "hour_eligible"
      ))
    ),
    by = c("site", "Id", "position", "local_date", "clock_hour"),
    relationship = "many-to-one"
  )
  expected <- dplyr::left_join(
    expected,
    dplyr::select(
      reconstructed$daily,
      dplyr::all_of(c(
        "site",
        "Id",
        "position",
        "local_date",
        "day_valid_minutes_raw",
        "day_valid_minutes_after_hour",
        "day_valid_fraction_after_hour",
        "day_eligible"
      ))
    ),
    by = c("site", "Id", "position", "local_date"),
    relationship = "many-to-one"
  )
  expected$coverage_period_eligible <-
    expected$hour_eligible & expected$day_eligible
  expected$coverage_signal_observed_real <- is.finite(expected$MEDI)
  expected$coverage_value_eligible_real <-
    expected$coverage_period_eligible &
    expected$coverage_signal_observed_real
  expected$MEDI_precoverage <- expected$MEDI
  expected$LIGHT_precoverage <- expected$LIGHT
  expected$MEDI_precoverage_observed <- is.finite(expected$MEDI)
  expected$LIGHT_precoverage_observed <- is.finite(expected$LIGHT)
  expected$MEDI_coverage_eligible <-
    expected$coverage_period_eligible &
    expected$MEDI_precoverage_observed
  expected$LIGHT_coverage_eligible <-
    expected$coverage_period_eligible &
    expected$LIGHT_precoverage_observed
  expected$MEDI_eligible <- ifelse(
    expected$coverage_period_eligible,
    expected$MEDI,
    NA_real_
  )
  expected$LIGHT_eligible <- ifelse(
    expected$coverage_period_eligible,
    expected$LIGHT,
    NA_real_
  )
  expected$MEDI_eligibility_reason <- ifelse(
    !expected$MEDI_precoverage_observed,
    "signal_invalidity",
    ifelse(
      !expected$hour_eligible,
      "hour_failure",
      ifelse(!expected$day_eligible, "day_failure", NA_character_)
    )
  )
  expected$LIGHT_eligibility_reason <- ifelse(
    !expected$LIGHT_precoverage_observed,
    "signal_invalidity",
    ifelse(
      !expected$hour_eligible,
      "hour_failure",
      ifelse(!expected$day_eligible, "day_failure", NA_character_)
    )
  )
  for (column in required) {
    if (!coverage_values_equal(eligible[[column]], expected[[column]])) {
      abort_pipeline(
        "%s coverage output has inconsistent eligible-channel `%s`",
        placement,
        column
      )
    }
  }
  invisible(TRUE)
}

coverage_verify_settings_row <- function(
  settings_row,
  aligned,
  eligible,
  reconstructed,
  placement
) {
  expected <- tibble::tibble(
    placement = placement,
    input_sites = dplyr::n_distinct(aligned$site),
    input_participants = nrow(dplyr::distinct(
      aligned,
      .data$site,
      .data$Id
    )),
    input_participant_days = nrow(dplyr::distinct(
      aligned,
      .data$site,
      .data$Id,
      .data$position,
      .data$local_date
    )),
    input_true_utc_minutes = nrow(aligned),
    output_true_utc_minutes = nrow(eligible),
    eligible_hours = sum(reconstructed$hourly$hour_eligible),
    ineligible_hours = sum(!reconstructed$hourly$hour_eligible),
    eligible_days = sum(reconstructed$daily$day_eligible),
    ineligible_days = sum(!reconstructed$daily$day_eligible),
    medi_eligible_true_utc_minutes = sum(
      eligible$MEDI_coverage_eligible
    ),
    light_eligible_true_utc_minutes = sum(
      eligible$LIGHT_coverage_eligible
    ),
    dst_fold_wall_minutes = sum(
      reconstructed$daily$day_dst_fold_minutes
    )
  )
  fields <- setdiff(names(expected), "placement")
  coverage_assert_table_equal(
    settings_row,
    expected,
    key = "placement",
    fields = fields,
    object = paste0(placement, " coverage settings")
  )
}

verify_coverage_artifacts <- function(
  root = project_root(),
  run_label = "full",
  placements = c("glasses", "chest"),
  aligned_run_root = NULL,
  coverage_run_root = NULL
) {
  layout <- coverage_verification_layout(
    root = root,
    run_label = run_label,
    aligned_run_root = aligned_run_root,
    coverage_run_root = coverage_run_root
  )
  settings_path <- file.path(
    layout$coverage_root,
    "coverage_settings.csv"
  )
  sample_flow_path <- file.path(
    layout$coverage_root,
    "sample_flow.csv"
  )
  required <- c(layout$manifest_path, settings_path, sample_flow_path)
  if (!all(file.exists(required))) {
    abort_pipeline(
      "Preparation 02 verification is missing required file(s): %s",
      paste(required[!file.exists(required)], collapse = ", ")
    )
  }
  manifest <- readr::read_csv(
    layout$manifest_path,
    show_col_types = FALSE
  )
  manifest_check <- coverage_verify_manifest_bytes(manifest)
  settings <- readr::read_csv(settings_path, show_col_types = FALSE)
  sample_flow <- readr::read_csv(
    sample_flow_path,
    show_col_types = FALSE
  )

  placements <- unique(as.character(placements))
  if (
    length(placements) == 0L ||
      anyNA(placements) ||
      any(!grepl("^[A-Za-z0-9._-]+$", placements))
  ) {
    abort_pipeline("`placements` must contain safe non-missing labels")
  }
  assert_unique_key(
    settings,
    "placement",
    object = "coverage settings"
  )
  if (!setequal(as.character(settings$placement), placements)) {
    abort_pipeline(
      "Coverage settings and requested placements have different sets"
    )
  }
  coverage_assert_constant(
    settings,
    "run_label",
    layout$run_label,
    "coverage settings"
  )
  coverage_assert_rule_a(settings, "coverage settings")

  expected_paths <- c(
    unlist(
      lapply(placements, function(placement) {
        file.path(
          layout$coverage_root,
          c(
            paste0("light_", placement, "_coverage.rds"),
            paste0("light_", placement, "_hourly_coverage.csv"),
            paste0("light_", placement, "_daily_coverage.csv"),
            paste0("light_", placement, "_gap_runs.csv")
          )
        )
      }),
      use.names = FALSE
    ),
    settings_path,
    sample_flow_path
  )
  expected_paths <- normalizePath(
    expected_paths,
    winslash = "/",
    mustWork = TRUE
  )
  manifested_paths <- normalizePath(
    manifest$path,
    winslash = "/",
    mustWork = TRUE
  )
  if (
    anyDuplicated(manifested_paths) ||
      !setequal(expected_paths, manifested_paths)
  ) {
    abort_pipeline(
      "Preparation 02 manifest does not contain the exact output path set"
    )
  }
  coverage_assert_constant(
    manifest,
    "run_label",
    layout$run_label,
    "Preparation 02 artifact manifest"
  )

  artifact_type_counts <- table(manifest$artifact_type)
  expected_type_counts <- c(
    coverage_annotated_real_minutes = length(placements),
    hourly_coverage = length(placements),
    daily_coverage = length(placements),
    reason_coded_gap_runs = length(placements),
    stage_labelled_sample_flow = 1L,
    coverage_settings = 1L
  )
  if (
    !setequal(names(artifact_type_counts), names(expected_type_counts)) ||
      any(
        as.integer(artifact_type_counts[names(expected_type_counts)]) !=
          expected_type_counts
      )
  ) {
    abort_pipeline(
      "Preparation 02 manifest has an unexpected artifact-type inventory"
    )
  }

  expected_artifact_types <- list(
    coverage = "coverage_annotated_real_minutes",
    hourly = "hourly_coverage",
    daily = "daily_coverage",
    gaps = "reason_coded_gap_runs"
  )
  sample_flow_expected <- list()
  summaries <- list()

  for (placement in placements) {
    input_path <- normalizePath(
      file.path(
        layout$aligned_root,
        paste0("light_", placement, "_aligned.rds")
      ),
      winslash = "/",
      mustWork = TRUE
    )
    output_paths <- c(
      coverage = file.path(
        layout$coverage_root,
        paste0("light_", placement, "_coverage.rds")
      ),
      hourly = file.path(
        layout$coverage_root,
        paste0("light_", placement, "_hourly_coverage.csv")
      ),
      daily = file.path(
        layout$coverage_root,
        paste0("light_", placement, "_daily_coverage.csv")
      ),
      gaps = file.path(
        layout$coverage_root,
        paste0("light_", placement, "_gap_runs.csv")
      )
    )
    output_path_names <- names(output_paths)
    output_paths <- normalizePath(
      output_paths,
      winslash = "/",
      mustWork = TRUE
    )
    names(output_paths) <- output_path_names
    placement_manifest <- manifest[
      !is.na(manifest$placement) &
        manifest$placement == placement,
      ,
      drop = FALSE
    ]
    if (nrow(placement_manifest) != length(output_paths)) {
      abort_pipeline(
        "%s does not have four placement-specific manifest rows",
        placement
      )
    }
    coverage_assert_rule_a(
      placement_manifest,
      paste0(placement, " manifest metadata"),
      manifest = TRUE
    )
    for (artifact_name in names(output_paths)) {
      row <- placement_manifest[
        normalizePath(
          placement_manifest$path,
          winslash = "/",
          mustWork = TRUE
        ) ==
          output_paths[[artifact_name]],
        ,
        drop = FALSE
      ]
      if (
        nrow(row) != 1L ||
          row$artifact_type[[1L]] != expected_artifact_types[[artifact_name]]
      ) {
        abort_pipeline(
          "%s manifest metadata misclassifies `%s`",
          placement,
          artifact_name
        )
      }
    }

    settings_row <- settings[
      settings$placement == placement,
      ,
      drop = FALSE
    ]
    observed_input_sha256 <- artifact_sha256(input_path)
    if (
      nrow(settings_row) != 1L ||
        is.na(settings_row$input_path[[1L]]) ||
        is.na(settings_row$input_sha256[[1L]]) ||
        normalizePath(
          settings_row$input_path[[1L]],
          winslash = "/",
          mustWork = TRUE
        ) !=
          input_path ||
        settings_row$input_sha256[[1L]] != observed_input_sha256
    ) {
      abort_pipeline(
        "%s settings fail the aligned-input path/SHA-256 rehash",
        placement
      )
    }
    if (
      anyNA(placement_manifest$input_path) ||
        anyNA(placement_manifest$input_sha256) ||
        any(
          normalizePath(
            placement_manifest$input_path,
            winslash = "/",
            mustWork = TRUE
          ) !=
            input_path
        ) ||
        any(placement_manifest$input_sha256 != observed_input_sha256)
    ) {
      abort_pipeline(
        "%s manifest fails aligned-input hash propagation",
        placement
      )
    }

    aligned <- dplyr::ungroup(read_rds_artifact(
      input_path,
      expected_class = "data.frame"
    ))
    eligible <- dplyr::ungroup(read_rds_artifact(
      output_paths[["coverage"]],
      expected_class = "data.frame"
    ))
    coverage_verify_inherited_signal_invariants(
      aligned,
      paste0(placement, " aligned input")
    )
    reconstructed <- coverage_reconstruct_rule_a(aligned, placement)
    persisted_hourly <- readr::read_csv(
      output_paths[["hourly"]],
      show_col_types = FALSE
    )
    persisted_daily <- readr::read_csv(
      output_paths[["daily"]],
      show_col_types = FALSE
    )
    hourly_key <- c(
      "site",
      "Id",
      "position",
      "local_date",
      "clock_hour"
    )
    daily_key <- c("site", "Id", "position", "local_date")
    coverage_assert_table_equal(
      persisted_hourly,
      reconstructed$hourly,
      key = hourly_key,
      fields = setdiff(names(reconstructed$hourly), hourly_key),
      object = paste0(placement, " hourly coverage")
    )
    coverage_assert_table_equal(
      persisted_daily,
      reconstructed$daily,
      key = daily_key,
      fields = setdiff(names(reconstructed$daily), daily_key),
      object = paste0(placement, " daily coverage")
    )
    coverage_verify_eligible_channels(
      aligned,
      eligible,
      reconstructed,
      placement
    )
    coverage_verify_inherited_signal_invariants(
      eligible,
      paste0(placement, " coverage output")
    )
    coverage_verify_settings_row(
      settings_row,
      aligned,
      eligible,
      reconstructed,
      placement
    )
    sample_flow_expected[[placement]] <- coverage_expected_sample_flow(
      eligible,
      placement
    )
    summaries[[placement]] <- tibble::tibble(
      placement = placement,
      input_rows = nrow(aligned),
      output_rows = nrow(eligible),
      participant_days = nrow(reconstructed$daily),
      eligible_days = sum(reconstructed$daily$day_eligible),
      ineligible_days = sum(!reconstructed$daily$day_eligible),
      saturated_minutes = sum(aligned$medi_saturated),
      invalid_nonwear_minutes = sum(aligned$invalid_nonwear)
    )
    rm(aligned, eligible, reconstructed)
    invisible(gc())
  }

  expected_sample_flow <- dplyr::bind_rows(sample_flow_expected)
  flow_key <- c(
    "placement",
    "scope",
    "site",
    "stage_order"
  )
  coverage_assert_table_equal(
    sample_flow,
    expected_sample_flow,
    key = flow_key,
    fields = setdiff(names(expected_sample_flow), flow_key),
    object = "Preparation 02 sample flow"
  )

  list(
    status = "PASS",
    run_label = layout$run_label,
    manifest = manifest_check,
    placements = placements,
    summary = dplyr::bind_rows(summaries)
  )
}
