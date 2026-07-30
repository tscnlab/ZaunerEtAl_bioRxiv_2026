# Project canonical sleep and wear intervals onto metric time grids.

metric_state_comparison_columns <- c(
  "sleep",
  "State.Brown",
  "wear",
  "measurement_context",
  "measurement_context_source",
  "invalid_nonwear",
  "wear_sleep_disagrees_with_diary",
  "wear_off_during_diary_sleep",
  "wear_state_missing"
)

state_interval_artifact_paths <- function(state_interval_root, sites) {
  if (
    !is.character(state_interval_root) ||
      length(state_interval_root) != 1L ||
      is.na(state_interval_root) ||
      !nzchar(trimws(state_interval_root))
  ) {
    abort_pipeline(
      "`state_interval_root` must be one non-empty directory path"
    )
  }
  if (
    !is.character(sites) ||
      length(sites) == 0L ||
      anyNA(sites) ||
      any(!nzchar(trimws(sites)))
  ) {
    abort_pipeline("`sites` must contain non-empty site labels")
  }
  sites <- sort(unique(trimws(sites)))
  tidyr::crossing(
    site = sites,
    interval_kind = c("sleep", "wear")
  ) |>
    dplyr::mutate(
      path = file.path(
        state_interval_root,
        paste0(.data$site, "_", .data$interval_kind, "_intervals.rds")
      )
    )
}

validate_metric_state_interval_artifact <- function(
  intervals,
  interval_kind = c("sleep", "wear")
) {
  interval_kind <- match.arg(interval_kind)
  common <- c(
    "site",
    "Id",
    "timezone",
    "interval_kind",
    "interval_bounds",
    "start",
    "end",
    "source_modality",
    "source_repository",
    "source_commit",
    "source_doi",
    "source_sha256",
    "source_url"
  )
  state_columns <- if (interval_kind == "sleep") {
    c(
      "sleep",
      "State.Brown",
      "sleep_source_row_start",
      "sleep_source_row_end",
      "sleep_state_source"
    )
  } else {
    c("wear", "wear_source_row", "wear_state_source")
  }
  assert_columns(
    intervals,
    c(common, state_columns),
    object = paste0("Preparation 01 ", interval_kind, " intervals")
  )
  validated <- validate_interval_table(
    intervals,
    id_cols = c("site", "Id"),
    start_col = "start",
    end_col = "end",
    object = paste0("Preparation 01 ", interval_kind, " intervals")
  )
  if (
    !identical(lubridate::tz(validated$start), "UTC") ||
      !identical(lubridate::tz(validated$end), "UTC")
  ) {
    abort_pipeline(
      "Preparation 01 %s intervals must use true UTC",
      interval_kind
    )
  }
  if (
    any(validated$interval_kind != interval_kind) ||
      any(validated$interval_bounds != "[)")
  ) {
    abort_pipeline(
      "Preparation 01 %s intervals have inconsistent kind or bounds",
      interval_kind
    )
  }
  if (
    dplyr::n_distinct(validated$site) != 1L ||
      dplyr::n_distinct(validated$timezone) != 1L ||
      !(unique(validated$timezone) %in% OlsonNames())
  ) {
    abort_pipeline(
      "Preparation 01 %s intervals require one site and valid time zone",
      interval_kind
    )
  }
  expected_modality <- if (interval_kind == "sleep") {
    "sleepdiaries"
  } else {
    "wearlog"
  }
  valid_states <- if (interval_kind == "sleep") {
    all(validated$State.Brown %in% c("wake", "pre-sleep", "sleep")) &&
      all(validated$sleep %in% c("wake", "sleepprep"))
  } else {
    all(validated$wear %in% c("off", "sleep", "site_leave"))
  }
  invalid_provenance <-
    any(validated$source_modality != expected_modality) ||
    anyNA(validated$source_commit) ||
    anyNA(validated$source_doi) ||
    anyNA(validated$source_sha256) ||
    any(!grepl("^[0-9a-f]{40}$", validated$source_commit)) ||
    any(!grepl("^10[.]5281/zenodo[.][0-9]+$", validated$source_doi)) ||
    any(!grepl("^[0-9a-f]{64}$", validated$source_sha256))
  if (!valid_states || invalid_provenance) {
    abort_pipeline(
      "Preparation 01 %s intervals have invalid state or provenance",
      interval_kind
    )
  }
  provenance <- attr(intervals, "state_interval_provenance")
  if (
    is.null(provenance) ||
      !identical(provenance$bounds, "[)") ||
      !identical(provenance$interval_kind, interval_kind) ||
      !identical(provenance$site, unique(validated$site)) ||
      !identical(provenance$timezone, unique(validated$timezone)) ||
      !identical(provenance$commit, unique(validated$source_commit)) ||
      !identical(provenance$doi, unique(validated$source_doi)) ||
      !identical(provenance$sha256, unique(validated$source_sha256))
  ) {
    abort_pipeline(
      "Preparation 01 %s intervals lack artifact-level provenance",
      interval_kind
    )
  }
  invisible(validated)
}

validate_state_interval_manifest <- function(
  manifest,
  manifest_path,
  state_interval_root,
  sites,
  run_label
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
  assert_no_missing_key(
    manifest,
    c("path", "sha256", "site", "interval_kind"),
    object = "Preparation 01 state-interval manifest"
  )
  assert_unique_key(
    manifest,
    c("site", "interval_kind"),
    object = "Preparation 01 state-interval manifest"
  )
  requested <- state_interval_artifact_paths(state_interval_root, sites)
  selected <- manifest |>
    dplyr::filter(.data$site %in% .env$sites) |>
    dplyr::arrange(.data$site, .data$interval_kind)
  if (
    nrow(selected) != nrow(requested) ||
      !setequal(
        paste(selected$site, selected$interval_kind, sep = "/"),
        paste(requested$site, requested$interval_kind, sep = "/")
      )
  ) {
    abort_pipeline(
      paste0(
        "Preparation 01 state-interval manifest does not identify exactly ",
        "one sleep and one wear artifact for every requested site"
      )
    )
  }
  selected <- dplyr::left_join(
    requested,
    selected,
    by = c("site", "interval_kind"),
    relationship = "one-to-one",
    suffix = c("_expected", "_manifest")
  )
  expected_type <- ifelse(
    selected$interval_kind == "sleep",
    "site_sleep_state_intervals",
    "site_wear_state_intervals"
  )
  invalid_metadata <-
    selected$artifact_type != expected_type |
    selected$run_label != run_label |
    selected$interval_bounds != "[)" |
    !grepl("^[0-9a-f]{64}$", selected$sha256)
  if (anyNA(invalid_metadata) || any(invalid_metadata)) {
    abort_pipeline(
      "Preparation 01 state-interval manifest metadata is inconsistent"
    )
  }
  expected_path <- vapply(
    selected$path_expected,
    normalizePath,
    character(1),
    winslash = "/",
    mustWork = TRUE
  )
  manifest_artifact_path <- vapply(
    selected$path_manifest,
    normalizePath,
    character(1),
    winslash = "/",
    mustWork = TRUE
  )
  if (!identical(unname(expected_path), unname(manifest_artifact_path))) {
    abort_pipeline(
      paste0(
        "Preparation 01 state-interval manifest paths do not exactly match ",
        "the selected state-interval root"
      )
    )
  }
  actual_bytes <- unname(file.info(expected_path)$size)
  if (
    any(!is.finite(selected$bytes)) ||
      any(as.numeric(selected$bytes) != actual_bytes)
  ) {
    abort_pipeline(
      "Preparation 01 state-interval artifact sizes do not match the manifest"
    )
  }
  actual_sha256 <- vapply(
    expected_path,
    artifact_sha256,
    character(1)
  )
  if (
    !identical(
      unname(actual_sha256),
      unname(as.character(selected$sha256))
    )
  ) {
    abort_pipeline(
      "Preparation 01 state-interval artifact hashes do not match the manifest"
    )
  }
  selected$path <- expected_path
  selected$actual_sha256 <- actual_sha256
  selected$manifest_path <- normalizePath(
    manifest_path,
    winslash = "/",
    mustWork = TRUE
  )
  dplyr::select(
    selected,
    "site",
    "interval_kind",
    "path",
    manifest_sha256 = "sha256",
    "actual_sha256",
    manifest_bytes = "bytes",
    "artifact_type",
    "run_label",
    "interval_bounds",
    "manifest_path"
  )
}

read_metric_state_interval_inputs <- function(
  state_interval_root,
  state_interval_manifest_path,
  sites,
  run_label
) {
  if (
    !is.character(state_interval_manifest_path) ||
      length(state_interval_manifest_path) != 1L ||
      is.na(state_interval_manifest_path) ||
      !nzchar(trimws(state_interval_manifest_path)) ||
      !file.exists(state_interval_manifest_path)
  ) {
    abort_pipeline(
      "Preparation 01 state-interval manifest is missing: %s",
      state_interval_manifest_path
    )
  }
  manifest_path <- normalizePath(
    state_interval_manifest_path,
    winslash = "/",
    mustWork = TRUE
  )
  manifest_sha256 <- artifact_sha256(manifest_path)
  manifest <- readr::read_csv(
    manifest_path,
    show_col_types = FALSE,
    progress = FALSE
  )
  inputs <- validate_state_interval_manifest(
    manifest = manifest,
    manifest_path = manifest_path,
    state_interval_root = state_interval_root,
    sites = sites,
    run_label = run_label
  )
  if (artifact_sha256(manifest_path) != manifest_sha256) {
    abort_pipeline(
      "Preparation 01 state-interval manifest changed while being verified"
    )
  }

  interval_objects <- vector("list", nrow(inputs))
  for (index in seq_len(nrow(inputs))) {
    interval_kind <- inputs$interval_kind[index]
    intervals <- read_rds_artifact(
      inputs$path[index],
      expected_class = "data.frame"
    )
    validate_metric_state_interval_artifact(intervals, interval_kind)
    if (
      unique(intervals$site) != inputs$site[index] ||
        artifact_sha256(inputs$path[index]) != inputs$actual_sha256[index]
    ) {
      abort_pipeline(
        "Preparation 01 %s intervals for %s changed during validation",
        interval_kind,
        inputs$site[index]
      )
    }
    interval_objects[[index]] <- dplyr::ungroup(intervals)
  }
  names(interval_objects) <- paste(
    inputs$site,
    inputs$interval_kind,
    sep = "/"
  )
  sleep <- dplyr::bind_rows(
    interval_objects[inputs$interval_kind == "sleep"]
  ) |>
    dplyr::arrange(.data$site, .data$Id, .data$start, .data$end)
  wear <- dplyr::bind_rows(
    interval_objects[inputs$interval_kind == "wear"]
  ) |>
    dplyr::arrange(.data$site, .data$Id, .data$start, .data$end)
  validate_interval_table(
    sleep,
    id_cols = c("site", "Id"),
    start_col = "start",
    end_col = "end",
    object = "combined Preparation 01 sleep intervals"
  )
  validate_interval_table(
    wear,
    id_cols = c("site", "Id"),
    start_col = "start",
    end_col = "end",
    object = "combined Preparation 01 wear intervals"
  )
  inputs$state_interval_manifest_sha256 <- manifest_sha256
  list(
    sleep = sleep,
    wear = wear,
    inputs = inputs,
    manifest_path = manifest_path,
    manifest_sha256 = manifest_sha256
  )
}

assert_metric_state_interval_inputs_unchanged <- function(inputs) {
  if (artifact_sha256(inputs$manifest_path) != inputs$manifest_sha256) {
    abort_pipeline(
      "Preparation 01 state-interval manifest changed during metric derivation"
    )
  }
  changed <- vapply(
    seq_len(nrow(inputs$inputs)),
    function(index) {
      artifact_sha256(inputs$inputs$path[index]) !=
        inputs$inputs$actual_sha256[index]
    },
    logical(1)
  )
  if (any(changed)) {
    abort_pipeline(
      "Preparation 01 state-interval artifact changed during metric derivation"
    )
  }
  invisible(TRUE)
}

project_metric_state_context <- function(
  grid,
  state_intervals,
  placement,
  object = deparse(substitute(grid))
) {
  assert_columns(
    grid,
    c(metric_participant_key, "datetime_utc"),
    object = object
  )
  assert_unique_key(
    grid,
    c(metric_participant_key, "datetime_utc"),
    object = object
  )
  if (
    !is.list(state_intervals) ||
      !all(c("sleep", "wear") %in% names(state_intervals))
  ) {
    abort_pipeline(
      "`state_intervals` must contain canonical `sleep` and `wear` tables"
    )
  }
  sleep <- dplyr::select(
    state_intervals$sleep,
    dplyr::all_of(c(
      "site",
      "Id",
      "start",
      "end",
      "sleep",
      "State.Brown",
      "sleep_state_source"
    ))
  )
  wear <- dplyr::select(
    state_intervals$wear,
    dplyr::all_of(c(
      "site",
      "Id",
      "start",
      "end",
      "wear",
      "wear_state_source"
    ))
  )
  target <- dplyr::select(
    grid,
    dplyr::all_of(c(metric_participant_key, "datetime_utc"))
  )
  target$Datetime <- target$datetime_utc
  projected <- attach_states_checked(
    target,
    sleep,
    stream_keys = c("site", "Id"),
    object = "canonical sleep intervals"
  ) |>
    dplyr::ungroup()
  projected <- attach_states_checked(
    projected,
    wear,
    stream_keys = c("site", "Id"),
    object = "canonical wear intervals"
  ) |>
    dplyr::ungroup()
  projected$.projection_medi <- NA_real_
  projected$.projection_light <- NA_real_
  projected <- derive_measurement_context(
    projected,
    placement = placement,
    brown_state_col = "State.Brown",
    wear_col = "wear",
    medi_col = ".projection_medi",
    light_col = ".projection_light",
    saturation_threshold = 100000
  )
  projected$state_interval_projected <- TRUE
  projected$state_interval_bounds <- "[)"
  dplyr::select(
    projected,
    dplyr::all_of(c(metric_participant_key, "datetime_utc")),
    dplyr::all_of(metric_state_comparison_columns),
    "state_interval_projected",
    "state_interval_bounds"
  )
}

equal_with_missing <- function(left, right) {
  if (is.factor(left)) {
    left <- as.character(left)
  }
  if (is.factor(right)) {
    right <- as.character(right)
  }
  (is.na(left) & is.na(right)) |
    (!is.na(left) & !is.na(right) & left == right)
}

assert_source_state_projection_match <- function(data) {
  assert_columns(
    data,
    c(
      "source_minute_present",
      metric_state_comparison_columns,
      paste0("source_", metric_state_comparison_columns)
    ),
    object = "state-projected metric grid"
  )
  present <- data$source_minute_present
  if (!is.logical(present) || anyNA(present)) {
    abort_pipeline("`source_minute_present` must be complete logical")
  }
  mismatch_rows <- rep(FALSE, nrow(data))
  mismatch_columns <- character()
  for (column in metric_state_comparison_columns) {
    comparison <- equal_with_missing(
      data[[column]],
      data[[paste0("source_", column)]]
    )
    mismatch <- present & !comparison
    if (any(mismatch)) {
      mismatch_rows <- mismatch_rows | mismatch
      mismatch_columns <- c(mismatch_columns, column)
    }
  }
  if (any(mismatch_rows)) {
    abort_pipeline(
      paste0(
        "Canonical interval projection disagrees with Preparation 01 on ",
        "%d source-present minute(s) for column(s): %s"
      ),
      sum(mismatch_rows),
      paste(unique(mismatch_columns), collapse = ", ")
    )
  }
  invisible(TRUE)
}
