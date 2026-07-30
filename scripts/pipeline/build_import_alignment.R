# Canonical Preparation 01 executor.
#
# This script deliberately stops at one-minute import and state alignment.
# Hourly and participant-day coverage rules belong to Preparation 02.

normalise_requested_sites <- function(requested_sites, available_sites) {
  if (is.null(requested_sites) || length(requested_sites) == 0L) {
    return(available_sites)
  }
  requested_sites <- trimws(as.character(requested_sites))
  requested_sites <- requested_sites[nzchar(requested_sites)]
  if (length(requested_sites) == 0L || anyNA(requested_sites)) {
    abort_pipeline("`requested_sites` must contain non-missing site labels")
  }
  requested_sites <- unique(requested_sites)
  unknown <- setdiff(requested_sites, available_sites)
  if (length(unknown) > 0L) {
    abort_pipeline(
      "Unknown requested site(s): %s",
      paste(unknown, collapse = ", ")
    )
  }
  available_sites[available_sites %in% requested_sites]
}

import_alignment_run_layout <- function(paths, requested_sites, all_sites) {
  is_complete <- identical(sort(requested_sites), sort(all_sites))
  run_label <- if (is_complete) {
    "full"
  } else {
    paste0("subset_", paste(tolower(requested_sites), collapse = "_"))
  }
  imported_root <- if (is_complete) {
    paths$imported
  } else {
    file.path(paths$imported, "runs", run_label)
  }
  aligned_root <- if (is_complete) {
    paths$aligned
  } else {
    file.path(paths$aligned, "runs", run_label)
  }
  list(
    is_complete = is_complete,
    run_label = run_label,
    imported_root = imported_root,
    imported_minute = file.path(imported_root, "minute"),
    aligned_root = aligned_root,
    aligned_site_position = file.path(aligned_root, "site_position"),
    aligned_state_intervals = file.path(aligned_root, "state_intervals"),
    manifest_suffix = if (is_complete) "" else paste0("_", run_label)
  )
}

resolve_pinned_download_manifest <- function(
  site_sources,
  paths,
  cache_policy = c("reuse", "refresh")
) {
  cache_policy <- match.arg(cache_policy)
  cache_directory <- file.path(paths$imported, "cache")
  manifest_path <- file.path(paths$manifests, "pinned_downloads.csv")
  specifications <- available_source_specifications(site_sources)

  if (cache_policy == "refresh" || !file.exists(manifest_path)) {
    return(download_pinned_sources(
      sources = site_sources,
      cache_directory = cache_directory,
      cache_policy = cache_policy
    ))
  }

  previous <- readr::read_csv(manifest_path, show_col_types = FALSE)
  required_previous <- c(
    "site",
    "modality",
    "local_path",
    "sha256",
    "bytes",
    "cache_mtime_utc"
  )
  assert_columns(
    previous,
    required_previous,
    object = "existing pinned download manifest"
  )
  assert_unique_key(
    previous,
    c("site", "modality"),
    object = "existing pinned download manifest"
  )

  expected_keys <- specifications[c("site", "modality")]
  observed_keys <- previous[c("site", "modality")]
  complete_key_set <- nrow(expected_keys) == nrow(observed_keys) &&
    all(
      paste(expected_keys$site, expected_keys$modality) %in%
        paste(observed_keys$site, observed_keys$modality)
    )
  all_paths_exist <- complete_key_set &&
    all(file.exists(previous$local_path))
  if (!complete_key_set || !all_paths_exist) {
    return(download_pinned_sources(
      sources = site_sources,
      cache_directory = cache_directory,
      cache_policy = "reuse"
    ))
  }

  reused <- specifications |>
    dplyr::select(dplyr::all_of(c(
      "site",
      "modality",
      "repository",
      "commit",
      "doi",
      "source_url"
    ))) |>
    dplyr::left_join(
      dplyr::select(
        previous,
        dplyr::all_of(c("site", "modality", "local_path")),
        recorded_sha256 = dplyr::all_of("sha256"),
        recorded_bytes = dplyr::all_of("bytes"),
        dplyr::all_of("cache_mtime_utc")
      ),
      by = c("site", "modality"),
      relationship = "one-to-one"
    )
  current_sha256 <- vapply(
    reused$local_path,
    artifact_sha256,
    character(1)
  )
  current_bytes <- unname(file.info(reused$local_path)$size)
  changed <- current_sha256 != reused$recorded_sha256 |
    current_bytes != reused$recorded_bytes
  if (any(changed)) {
    abort_pipeline(
      paste0(
        "Cached pinned source content differs from its recorded manifest ",
        "for: %s. Use an explicit refresh only after resolving provenance."
      ),
      paste(
        paste(reused$site[changed], reused$modality[changed], sep = "/"),
        collapse = ", "
      )
    )
  }

  dplyr::transmute(
    reused,
    .data$site,
    .data$modality,
    .data$repository,
    .data$commit,
    .data$doi,
    .data$source_url,
    .data$local_path,
    sha256 = current_sha256,
    bytes = current_bytes,
    .data$cache_mtime_utc,
    verified_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
    downloaded = FALSE
  )
}

source_datetime_columns <- function(modality) {
  switch(
    modality,
    light_glasses = "Datetime",
    light_chest = "Datetime",
    sleepdiaries = c("sleepprep", "wake"),
    wearlog = c("start", "end"),
    abort_pipeline("Unknown source modality '%s'", modality)
  )
}

finite_datetime_range <- function(data, columns) {
  numeric_values <- unlist(
    lapply(data[columns], function(value) as.numeric(value)),
    use.names = FALSE
  )
  finite_values <- numeric_values[is.finite(numeric_values)]
  if (length(finite_values) == 0L) {
    return(c(NA_character_, NA_character_))
  }
  range_values <- as.POSIXct(
    range(finite_values),
    origin = "1970-01-01",
    tz = "UTC"
  )
  format(range_values, tz = "UTC", usetz = TRUE)
}

source_audit_row <- function(
  data,
  specification,
  downloaded_source
) {
  datetime_columns <- source_datetime_columns(specification$modality)
  assert_columns(
    data,
    c("Id", datetime_columns),
    object = paste0(specification$site, "/", specification$modality)
  )
  datetime_zones <- unique(vapply(
    data[datetime_columns],
    lubridate::tz,
    character(1)
  ))
  if (
    length(datetime_zones) != 1L ||
      !identical(datetime_zones, specification$timezone)
  ) {
    abort_pipeline(
      "%s/%s has source time zone(s) %s; expected %s",
      specification$site,
      specification$modality,
      paste(datetime_zones, collapse = ","),
      specification$timezone
    )
  }
  datetime_range <- finite_datetime_range(data, datetime_columns)
  tibble::tibble(
    site = specification$site,
    location = specification$location,
    modality = specification$modality,
    object_name = specification$object_name,
    repository = specification$repository,
    commit = specification$commit,
    doi = specification$doi,
    source_url = specification$source_url,
    source_sha256 = downloaded_source$sha256,
    source_bytes = downloaded_source$bytes,
    source_timezone = specification$timezone,
    source_rows = nrow(data),
    source_participants = dplyr::n_distinct(data$Id),
    source_columns = ncol(data),
    source_start_utc = datetime_range[1L],
    source_end_utc = datetime_range[2L]
  )
}

add_source_identifiers <- function(
  data,
  specification,
  downloaded_source
) {
  data$source_modality <- specification$modality
  data$source_repository <- specification$repository
  data$source_commit <- specification$commit
  data$source_doi <- specification$doi
  data$source_sha256 <- downloaded_source$sha256
  data$source_url <- specification$source_url
  data$location <- specification$location
  data
}

prepare_state_interval_pair <- function(
  sleep_diary,
  wear_log,
  site,
  timezone
) {
  list(
    sleep = prepare_sleep_intervals(
      sleep_diary,
      timezone = timezone,
      id_cols = "Id",
      sleepprep_col = "sleepprep",
      wake_col = "wake",
      object = paste0(site, " sleep diary")
    ),
    wear = prepare_wear_intervals(
      wear_log,
      timezone = timezone,
      id_cols = "Id",
      start_col = "start",
      end_col = "end",
      state_col = "state",
      object = paste0(site, " wear log")
    )
  )
}

decorate_state_intervals <- function(
  preparation,
  site,
  timezone,
  interval_kind = c("sleep", "wear"),
  specification,
  downloaded_source
) {
  interval_kind <- match.arg(interval_kind)
  source_repository <- unname(as.character(specification$repository))
  source_commit <- unname(as.character(specification$commit))
  source_doi <- unname(as.character(specification$doi))
  source_sha256 <- unname(as.character(downloaded_source$sha256))
  source_url <- unname(as.character(specification$source_url))
  intervals <- dplyr::ungroup(preparation$intervals)
  intervals$site <- site
  intervals$timezone <- timezone
  intervals$interval_kind <- interval_kind
  intervals$interval_bounds <- "[)"
  intervals$source_modality <- specification$modality
  intervals$source_repository <- source_repository
  intervals$source_commit <- source_commit
  intervals$source_doi <- source_doi
  intervals$source_sha256 <- source_sha256
  intervals$source_url <- source_url
  intervals <- dplyr::select(
    intervals,
    dplyr::all_of(c(
      "site",
      "Id",
      "timezone",
      "interval_kind",
      "interval_bounds"
    )),
    dplyr::everything()
  )
  attr(intervals, "state_interval_provenance") <- list(
    site = site,
    timezone = timezone,
    interval_kind = interval_kind,
    bounds = "[)",
    repository = source_repository,
    commit = source_commit,
    doi = source_doi,
    sha256 = source_sha256,
    source_url = source_url
  )
  intervals
}

validate_exported_state_intervals <- function(
  intervals,
  interval_kind = c("sleep", "wear")
) {
  interval_kind <- match.arg(interval_kind)
  required <- c(
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
    c(required, state_columns),
    object = paste0("exported ", interval_kind, " intervals")
  )
  validated <- validate_interval_table(
    intervals,
    id_cols = c("site", "Id"),
    start_col = "start",
    end_col = "end",
    object = paste0("exported ", interval_kind, " intervals")
  )
  if (
    !identical(lubridate::tz(validated$start), "UTC") ||
      !identical(lubridate::tz(validated$end), "UTC")
  ) {
    abort_pipeline("Exported %s intervals must use true UTC", interval_kind)
  }
  if (
    any(validated$interval_kind != interval_kind) ||
      any(validated$interval_bounds != "[)")
  ) {
    abort_pipeline(
      "Exported %s intervals have inconsistent kind or bounds",
      interval_kind
    )
  }
  if (
    dplyr::n_distinct(validated$site) != 1L ||
      dplyr::n_distinct(validated$timezone) != 1L ||
      !(unique(validated$timezone) %in% OlsonNames())
  ) {
    abort_pipeline(
      "Exported %s intervals require one site and one valid time zone",
      interval_kind
    )
  }
  if (
    anyNA(validated$source_commit) ||
      anyNA(validated$source_doi) ||
      anyNA(validated$source_sha256) ||
      any(!grepl("^[0-9a-f]{40}$", validated$source_commit)) ||
      any(!grepl("^10[.]5281/zenodo[.][0-9]+$", validated$source_doi)) ||
      any(!grepl("^[0-9a-f]{64}$", validated$source_sha256))
  ) {
    abort_pipeline(
      "Exported %s intervals have invalid release provenance",
      interval_kind
    )
  }
  expected_modality <- if (interval_kind == "sleep") {
    "sleepdiaries"
  } else {
    "wearlog"
  }
  if (any(validated$source_modality != expected_modality)) {
    abort_pipeline(
      "Exported %s intervals have the wrong source modality",
      interval_kind
    )
  }
  valid_states <- if (interval_kind == "sleep") {
    all(validated$State.Brown %in% c("wake", "pre-sleep", "sleep")) &&
      all(validated$sleep %in% c("wake", "sleepprep"))
  } else {
    all(validated$wear %in% c("off", "sleep", "site_leave"))
  }
  if (!valid_states) {
    abort_pipeline(
      "Exported %s intervals contain an unexpected state",
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
      "Exported %s intervals lack artifact-level provenance",
      interval_kind
    )
  }
  invisible(validated)
}

write_state_interval_pair <- function(
  state_pair,
  site,
  timezone,
  sleep_source,
  wear_source,
  output_directory,
  producer,
  run_label
) {
  dir.create(output_directory, recursive = TRUE, showWarnings = FALSE)
  sleep_intervals <- decorate_state_intervals(
    state_pair$sleep,
    site = site,
    timezone = timezone,
    interval_kind = "sleep",
    specification = sleep_source$specification,
    downloaded_source = sleep_source$downloaded_source
  )
  wear_intervals <- decorate_state_intervals(
    state_pair$wear,
    site = site,
    timezone = timezone,
    interval_kind = "wear",
    specification = wear_source$specification,
    downloaded_source = wear_source$downloaded_source
  )
  validate_exported_state_intervals(sleep_intervals, "sleep")
  validate_exported_state_intervals(wear_intervals, "wear")

  sleep_path <- file.path(
    output_directory,
    paste0(site, "_sleep_intervals.rds")
  )
  wear_path <- file.path(
    output_directory,
    paste0(site, "_wear_intervals.rds")
  )
  sleep_metadata <- write_rds_artifact(
    sleep_intervals,
    sleep_path,
    producer,
    metadata = list(
      artifact_type = "site_sleep_state_intervals",
      run_label = run_label,
      site = site,
      interval_kind = "sleep",
      interval_bounds = "[)",
      source_commit = sleep_source$specification$commit,
      source_doi = sleep_source$specification$doi,
      source_sha256 = sleep_source$downloaded_source$sha256
    )
  )
  wear_metadata <- write_rds_artifact(
    wear_intervals,
    wear_path,
    producer,
    metadata = list(
      artifact_type = "site_wear_state_intervals",
      run_label = run_label,
      site = site,
      interval_kind = "wear",
      interval_bounds = "[)",
      source_commit = wear_source$specification$commit,
      source_doi = wear_source$specification$doi,
      source_sha256 = wear_source$downloaded_source$sha256
    )
  )
  list(
    sleep = sleep_intervals,
    wear = wear_intervals,
    paths = c(sleep = sleep_path, wear = wear_path),
    metadata = list(sleep = sleep_metadata, wear = wear_metadata)
  )
}

validate_light_stream <- function(
  data,
  site,
  placement,
  timezone
) {
  assert_columns(
    data,
    c("Id", "Datetime", "MEDI", "LIGHT", "position"),
    object = paste0(site, "/", placement, " source stream")
  )
  assert_no_missing_key(
    data,
    c("Id", "Datetime"),
    object = paste0(site, "/", placement, " source stream")
  )
  if (!is.numeric(data$MEDI) || !is.numeric(data$LIGHT)) {
    abort_pipeline("%s/%s MEDI and LIGHT must be numeric", site, placement)
  }
  observed_positions <- unique(stats::na.omit(as.character(data$position)))
  if (
    length(observed_positions) != 1L ||
      !identical(observed_positions, placement)
  ) {
    abort_pipeline(
      "%s/%s has unexpected source position label(s): %s",
      site,
      placement,
      paste(observed_positions, collapse = ", ")
    )
  }
  if (!identical(lubridate::tz(data$Datetime), timezone)) {
    abort_pipeline(
      "%s/%s source time zone is '%s'; expected '%s'",
      site,
      placement,
      lubridate::tz(data$Datetime),
      timezone
    )
  }
  assert_unique_key(
    data,
    c("Id", "Datetime"),
    object = paste0(site, "/", placement, " source stream")
  )
  invisible(data)
}

key_audit_row <- function(data, stage, site, placement, key) {
  assert_columns(data, key, object = paste0(stage, " key audit"))
  missing_key <- !stats::complete.cases(data[key])
  duplicate_excess <- sum(duplicated(data[key]))
  tibble::tibble(
    site = site,
    placement = placement,
    stage = stage,
    key = paste(key, collapse = " + "),
    rows = nrow(data),
    participants = if ("Id" %in% names(data)) {
      dplyr::n_distinct(data$Id)
    } else {
      NA_integer_
    },
    missing_key_rows = sum(missing_key),
    duplicate_key_excess_rows = duplicate_excess,
    key_is_unique = !any(missing_key) && duplicate_excess == 0L
  )
}

sample_audit_row <- function(data, stage, site, placement) {
  assert_columns(data, c("Id", "MEDI", "LIGHT"), object = stage)
  participant_days <- if ("local_date" %in% names(data)) {
    nrow(unique(data[c("Id", "local_date")]))
  } else {
    NA_integer_
  }
  implicit_subepochs <- if ("implicit_subepochs" %in% names(data)) {
    sum(data$implicit_subepochs, na.rm = TRUE)
  } else if ("is.implicit" %in% names(data)) {
    sum(data$is.implicit %in% TRUE)
  } else {
    NA_real_
  }
  complete_minutes <- if ("complete_subepoch_set" %in% names(data)) {
    sum(data$complete_subepoch_set %in% TRUE)
  } else {
    NA_integer_
  }
  tibble::tibble(
    site = site,
    placement = placement,
    stage = stage,
    rows = nrow(data),
    participants = dplyr::n_distinct(data$Id),
    participant_days = participant_days,
    finite_medi = sum(is.finite(data$MEDI)),
    finite_light = sum(is.finite(data$LIGHT)),
    finite_medi_light_pairs = sum(
      is.finite(data$MEDI) & is.finite(data$LIGHT)
    ),
    implicit_subepochs = implicit_subepochs,
    complete_native_minute_schedules = complete_minutes
  )
}

time_audit_row <- function(
  annotated_stream,
  minute_data,
  site,
  placement
) {
  assert_columns(
    minute_data,
    c(
      "Id",
      "datetime_utc",
      "datetime_wall",
      "utc_offset_minutes",
      "source_subepochs",
      "complete_subepoch_set"
    ),
    object = "one-minute time audit data"
  )
  ordered <- dplyr::ungroup(annotated_stream) |>
    dplyr::group_by(.data$Id) |>
    dplyr::mutate(
      .input_reversal = as.numeric(.data$datetime_utc) <
        dplyr::lag(as.numeric(.data$datetime_utc))
    ) |>
    dplyr::ungroup()
  wall_keys <- minute_data[c(
    "Id",
    "datetime_wall",
    "datetime_utc",
    "utc_offset_minutes"
  )]
  wall_duplicates <- wall_keys |>
    dplyr::group_by(.data$Id, .data$datetime_wall) |>
    dplyr::summarise(
      real_minutes = dplyr::n(),
      distinct_instants = dplyr::n_distinct(.data$datetime_utc),
      .groups = "drop"
    ) |>
    dplyr::filter(.data$distinct_instants > 1L)

  epoch_column <- intersect(
    c(
      "stream_epoch_seconds",
      "native_epoch_seconds",
      "participant_epoch_seconds",
      "inferred_epoch_seconds"
    ),
    names(minute_data)
  )
  expected_column <- intersect(
    c("expected_subepochs", "expected_subepochs_per_minute"),
    names(minute_data)
  )
  epoch_regimes <- if (
    length(epoch_column) > 0L &&
      length(expected_column) > 0L
  ) {
    minute_data |>
      dplyr::distinct(
        stream_epoch = .data[[epoch_column[1L]]],
        expected_subepochs = .data[[expected_column[1L]]]
      ) |>
      dplyr::filter(
        !is.na(.data$stream_epoch),
        !is.na(.data$expected_subepochs)
      ) |>
      dplyr::arrange(.data$stream_epoch)
  } else {
    tibble::tibble(
      stream_epoch = numeric(),
      expected_subepochs = integer()
    )
  }

  tibble::tibble(
    site = site,
    placement = placement,
    source_rows = nrow(annotated_stream),
    minute_rows = nrow(minute_data),
    participants = dplyr::n_distinct(minute_data$Id),
    source_start_utc = format(
      min(annotated_stream$datetime_utc),
      tz = "UTC",
      usetz = TRUE
    ),
    source_end_utc = format(
      max(annotated_stream$datetime_utc),
      tz = "UTC",
      usetz = TRUE
    ),
    input_order_reversals = sum(ordered$.input_reversal %in% TRUE),
    utc_offset_values = paste(
      sort(unique(minute_data$utc_offset_minutes)),
      collapse = ","
    ),
    native_epoch_seconds = paste(
      paste0(epoch_regimes$stream_epoch, "s"),
      collapse = ";"
    ),
    expected_subepochs_per_minute = paste(
      paste0(epoch_regimes$expected_subepochs, "/min"),
      collapse = ";"
    ),
    minutes_with_incomplete_native_schedule = sum(
      !minute_data$complete_subepoch_set
    ),
    wall_minutes_with_multiple_real_instants = nrow(wall_duplicates)
  )
}

stream_epoch_audit_rows <- function(minute_data) {
  required <- c(
    "site",
    "Id",
    "position",
    "stream_epoch_seconds",
    "expected_subepochs",
    "minimum_finite_subepochs",
    "source_subepochs",
    "implicit_subepochs",
    "complete_subepoch_set",
    "MEDI",
    "LIGHT",
    "source_modality",
    "source_commit",
    "source_doi",
    "source_sha256"
  )
  assert_columns(
    minute_data,
    required,
    object = "participant-stream epoch audit data"
  )
  consistency <- minute_data |>
    dplyr::group_by(.data$site, .data$Id, .data$position) |>
    dplyr::summarise(
      epoch_values = dplyr::n_distinct(.data$stream_epoch_seconds),
      expected_values = dplyr::n_distinct(.data$expected_subepochs),
      minimum_values = dplyr::n_distinct(.data$minimum_finite_subepochs),
      .groups = "drop"
    )
  inconsistent <- consistency$epoch_values != 1L |
    consistency$expected_values != 1L |
    consistency$minimum_values != 1L
  if (any(inconsistent)) {
    abort_pipeline(
      "%d participant stream(s) have inconsistent native-epoch metadata",
      sum(inconsistent)
    )
  }

  minute_data |>
    dplyr::group_by(.data$site, .data$Id, .data$position) |>
    dplyr::summarise(
      source_modality = dplyr::first(.data$source_modality),
      source_commit = dplyr::first(.data$source_commit),
      source_doi = dplyr::first(.data$source_doi),
      source_sha256 = dplyr::first(.data$source_sha256),
      stream_epoch_seconds = dplyr::first(.data$stream_epoch_seconds),
      expected_subepochs_per_minute = dplyr::first(
        .data$expected_subepochs
      ),
      required_finite_subepochs_per_signal = dplyr::first(
        .data$minimum_finite_subepochs
      ),
      minute_rows = dplyr::n(),
      source_observations = sum(.data$source_subepochs),
      implicit_source_observations = sum(.data$implicit_subepochs),
      complete_native_minute_schedules = sum(
        .data$complete_subepoch_set
      ),
      incomplete_native_minute_schedules = sum(
        !.data$complete_subepoch_set
      ),
      finite_medi_minutes = sum(is.finite(.data$MEDI)),
      finite_light_minutes = sum(is.finite(.data$LIGHT)),
      .groups = "drop"
    ) |>
    dplyr::arrange(.data$site, .data$position, .data$Id)
}

dst_fold_audit_rows <- function(minute_data) {
  minute_data |>
    dplyr::group_by(
      .data$site,
      .data$Id,
      .data$position,
      .data$local_date,
      .data$clock_minute,
      .data$datetime_wall
    ) |>
    dplyr::summarise(
      real_minutes = dplyr::n(),
      distinct_utc_minutes = dplyr::n_distinct(.data$datetime_utc),
      utc_offsets = paste(
        sort(unique(.data$utc_offset_minutes)),
        collapse = ","
      ),
      .groups = "drop"
    ) |>
    dplyr::filter(.data$distinct_utc_minutes > 1L)
}

state_audit_rows <- function(aligned) {
  dplyr::ungroup(aligned) |>
    dplyr::count(
      .data$site,
      .data$position,
      .data$State.Brown,
      .data$wear,
      .data$measurement_context,
      .data$measurement_context_source,
      name = "minutes"
    ) |>
    dplyr::arrange(
      .data$site,
      .data$position,
      .data$measurement_context,
      .data$State.Brown,
      .data$wear
    )
}

state_conflict_audit_row <- function(aligned) {
  tibble::tibble(
    site = unique(aligned$site),
    placement = unique(aligned$position),
    rows = nrow(aligned),
    diary_sleep_minutes = sum(aligned$State.Brown == "sleep", na.rm = TRUE),
    diary_sleep_without_wear_label = sum(
      aligned$State.Brown == "sleep" & is.na(aligned$wear),
      na.rm = TRUE
    ),
    wear_sleep_outside_diary_sleep = sum(
      aligned$wear_sleep_disagrees_with_diary
    ),
    wear_off_during_diary_sleep = sum(
      aligned$wear_off_during_diary_sleep
    ),
    wear_off_outside_diary_sleep = sum(aligned$invalid_nonwear),
    wear_state_missing = sum(aligned$wear_state_missing),
    retained_bedside_sleep_minutes = sum(
      aligned$measurement_context == "bedside_sleep_environment"
    )
  )
}

saturation_audit_row <- function(aligned, threshold) {
  saturated <- aligned$medi_saturated
  values <- aligned$MEDI_raw[saturated]
  tibble::tibble(
    site = unique(aligned$site),
    placement = unique(aligned$position),
    operating_limit_lux_mel_edi = threshold,
    saturated_minutes = sum(saturated),
    affected_participants = dplyr::n_distinct(aligned$Id[saturated]),
    affected_participant_days = nrow(unique(
      aligned[saturated, c("Id", "local_date"), drop = FALSE]
    )),
    minimum_saturated_medi = if (any(saturated)) min(values) else NA_real_,
    maximum_saturated_medi = if (any(saturated)) max(values) else NA_real_
  )
}

saturation_observation_rows <- function(aligned, threshold) {
  aligned |>
    dplyr::ungroup() |>
    dplyr::filter(.data$medi_saturated) |>
    dplyr::transmute(
      .data$site,
      .data$Id,
      .data$position,
      .data$datetime_utc,
      .data$datetime_wall,
      .data$local_date,
      .data$clock_minute,
      .data$State.Brown,
      .data$wear,
      .data$measurement_context,
      .data$MEDI_raw,
      .data$LIGHT_raw,
      operating_limit_lux_mel_edi = threshold,
      .data$source_commit,
      .data$source_sha256
    )
}

validate_aligned_stream <- function(aligned, saturation_threshold) {
  assert_unique_key(
    aligned,
    c("site", "Id", "position", "datetime_utc"),
    object = "state-aligned one-minute stream"
  )
  if (
    any(
      as.numeric(aligned$Datetime) != as.numeric(aligned$datetime_utc),
      na.rm = TRUE
    )
  ) {
    abort_pipeline("`Datetime` is not identical to true `datetime_utc`")
  }
  if (
    any(
      aligned$invalid_nonwear &
        (is.finite(aligned$MEDI) | is.finite(aligned$LIGHT))
    )
  ) {
    abort_pipeline("True non-wear was not masked jointly in MEDI and LIGHT")
  }
  expected_saturation <- is.finite(aligned$MEDI_raw) &
    aligned$MEDI_raw >= saturation_threshold
  if (!identical(aligned$medi_saturated, expected_saturation)) {
    abort_pipeline("Saturation flags do not implement the approved boundary")
  }
  if (any(aligned$medi_saturated & is.finite(aligned$MEDI))) {
    abort_pipeline("Saturated melanopic EDI remained analytically valid")
  }
  if (any(aligned$wear_off_during_diary_sleep & aligned$invalid_nonwear)) {
    abort_pipeline(
      "Wear-log off state overrode an authoritative diary sleep interval"
    )
  }
  invisible(aligned)
}

build_import_alignment <- function(
  root = project_root(),
  requested_sites = NULL,
  cache_policy = c("reuse", "refresh"),
  saturation_threshold = 100000
) {
  cache_policy <- match.arg(cache_policy)
  if (
    length(saturation_threshold) != 1L ||
      !is.finite(saturation_threshold) ||
      !identical(as.numeric(saturation_threshold), 100000)
  ) {
    abort_pipeline(
      paste0(
        "Canonical Preparation 01 requires the approved ActLumus MEDI ",
        "operating boundary of 100000 lx"
      )
    )
  }
  producer <- "scripts/pipeline/build_import_alignment.R"
  paths <- pipeline_paths(root)
  ensure_pipeline_directories(paths)
  site_sources <- read_site_sources(file.path(root, "config/site_sources.csv"))
  requested_sites <- normalise_requested_sites(
    requested_sites,
    site_sources$site
  )
  run_layout <- import_alignment_run_layout(
    paths,
    requested_sites,
    site_sources$site
  )
  dir.create(
    run_layout$imported_minute,
    recursive = TRUE,
    showWarnings = FALSE
  )
  dir.create(
    run_layout$aligned_site_position,
    recursive = TRUE,
    showWarnings = FALSE
  )
  dir.create(
    run_layout$aligned_state_intervals,
    recursive = TRUE,
    showWarnings = FALSE
  )

  download_manifest <- resolve_pinned_download_manifest(
    site_sources = site_sources,
    paths = paths,
    cache_policy = cache_policy
  )
  assert_unique_key(
    download_manifest,
    c("site", "modality"),
    object = "resolved pinned download manifest"
  )

  artifact_records <- list()
  record_artifact <- function(metadata, label) {
    artifact_records[[label]] <<- manifest_row(metadata)
    invisible(metadata)
  }
  pinned_manifest_path <- file.path(paths$manifests, "pinned_downloads.csv")
  record_artifact(
    write_csv_artifact(
      download_manifest,
      pinned_manifest_path,
      producer,
      metadata = list(
        artifact_type = "pinned_source_manifest",
        run_label = run_layout$run_label
      )
    ),
    "pinned_source_manifest"
  )

  source_audits <- list()
  key_audits <- list()
  time_audits <- list()
  stream_epoch_audits <- list()
  dst_fold_audits <- list()
  interval_audits <- list()
  interval_summaries <- list()
  join_audits <- list()
  state_audits <- list()
  state_conflict_audits <- list()
  saturation_audits <- list()
  saturation_observations <- list()
  sample_audits <- list()
  aligned_paths <- list(glasses = character(), chest = character())

  load_site_modality <- function(site, modality) {
    specification <- source_specification(
      site_sources,
      site = site,
      modality = modality
    )
    downloaded_source <- downloaded_source_row(
      download_manifest,
      site = site,
      modality = modality
    )
    data <- load_pinned_source(specification, downloaded_source)
    source_audits[[paste(site, modality, sep = "/")]] <<-
      source_audit_row(data, specification, downloaded_source)
    list(
      data = dplyr::ungroup(data),
      specification = specification,
      downloaded_source = downloaded_source
    )
  }

  for (site in requested_sites) {
    site_row <- site_sources[site_sources$site == site, , drop = FALSE]
    timezone <- site_row$timezone
    message("Preparing state intervals for ", site)
    sleep_source <- load_site_modality(site, "sleepdiaries")
    wear_source <- load_site_modality(site, "wearlog")
    state_pair <- prepare_state_interval_pair(
      sleep_diary = sleep_source$data,
      wear_log = wear_source$data,
      site = site,
      timezone = timezone
    )
    sleep_preparation <- state_pair$sleep
    wear_preparation <- state_pair$wear
    state_interval_export <- write_state_interval_pair(
      state_pair = state_pair,
      site = site,
      timezone = timezone,
      sleep_source = sleep_source,
      wear_source = wear_source,
      output_directory = run_layout$aligned_state_intervals,
      producer = producer,
      run_label = run_layout$run_label
    )
    record_artifact(
      state_interval_export$metadata$sleep,
      paste(site, "sleep_intervals", sep = "/")
    )
    record_artifact(
      state_interval_export$metadata$wear,
      paste(site, "wear_intervals", sep = "/")
    )
    interval_audits[[paste0(site, "/sleep")]] <-
      dplyr::mutate(sleep_preparation$audit, site = site, .before = 1L)
    interval_audits[[paste0(site, "/wear")]] <-
      dplyr::mutate(wear_preparation$audit, site = site, .before = 1L)
    interval_summaries[[site]] <- tibble::tibble(
      site = site,
      sleep_intervals = nrow(sleep_preparation$intervals),
      sleep_participants = dplyr::n_distinct(
        sleep_preparation$intervals$Id
      ),
      sleep_audit_rows = nrow(sleep_preparation$audit),
      wear_intervals = nrow(wear_preparation$intervals),
      wear_participants = dplyr::n_distinct(
        wear_preparation$intervals$Id
      ),
      wear_audit_rows = nrow(wear_preparation$audit)
    )

    placements <- "glasses"
    if (isTRUE(site_row$has_chest)) {
      placements <- c(placements, "chest")
    }
    for (placement in placements) {
      message("Importing and aligning ", site, "/", placement)
      modality <- paste0("light_", placement)
      light_source <- load_site_modality(site, modality)
      validate_light_stream(
        light_source$data,
        site = site,
        placement = placement,
        timezone = timezone
      )
      annotated <- annotate_time_axes(
        data = light_source$data,
        timezone = timezone,
        datetime_col = "Datetime",
        site = site
      )
      annotated$position <- placement
      assert_unique_key(
        annotated,
        c("site", "Id", "position", "datetime_utc"),
        object = paste0(site, "/", placement, " annotated stream")
      )
      key_audits[[paste(site, placement, "raw", sep = "/")]] <-
        key_audit_row(
          annotated,
          stage = "annotated_native_epoch",
          site = site,
          placement = placement,
          key = c("site", "Id", "position", "datetime_utc")
        )
      sample_audits[[paste(site, placement, "raw", sep = "/")]] <-
        sample_audit_row(
          annotated,
          stage = "annotated_native_epoch",
          site = site,
          placement = placement
        )

      minute_data <- aggregate_native_epoch_to_minute(
        annotated,
        signal_cols = c("MEDI", "LIGHT"),
        id_cols = c("site", "Id", "position"),
        expected_subepochs = NULL,
        minimum_finite_subepochs = NULL,
        minimum_finite_fraction = 1,
        datetime_utc_col = "datetime_utc",
        datetime_wall_col = "datetime_wall",
        implicit_col = "is.implicit",
        object = paste0(site, "/", placement, " native-epoch stream")
      )
      minute_data <- add_source_identifiers(
        minute_data,
        light_source$specification,
        light_source$downloaded_source
      )
      assert_unique_key(
        minute_data,
        c("site", "Id", "position", "datetime_utc"),
        object = paste0(site, "/", placement, " imported minutes")
      )
      key_audits[[paste(site, placement, "minute", sep = "/")]] <-
        key_audit_row(
          minute_data,
          stage = "aggregated_one_minute",
          site = site,
          placement = placement,
          key = c("site", "Id", "position", "datetime_utc")
        )
      sample_audits[[paste(site, placement, "minute", sep = "/")]] <-
        sample_audit_row(
          minute_data,
          stage = "aggregated_one_minute",
          site = site,
          placement = placement
        )
      time_audits[[paste(site, placement, sep = "/")]] <-
        time_audit_row(annotated, minute_data, site, placement)
      stream_epoch_audits[[paste(site, placement, sep = "/")]] <-
        stream_epoch_audit_rows(minute_data)
      dst_fold_audits[[paste(site, placement, sep = "/")]] <-
        dst_fold_audit_rows(minute_data)

      imported_path <- file.path(
        run_layout$imported_minute,
        paste0(site, "_", placement, "_minute.rds")
      )
      record_artifact(
        write_rds_artifact(
          dplyr::ungroup(minute_data),
          imported_path,
          producer,
          metadata = list(
            artifact_type = "site_placement_imported_minutes",
            run_label = run_layout$run_label,
            site = site,
            placement = placement,
            source_commit = light_source$specification$commit,
            source_doi = light_source$specification$doi,
            source_sha256 = light_source$downloaded_source$sha256
          )
        ),
        paste(site, placement, "imported", sep = "/")
      )

      state_target <- minute_data
      state_target$Datetime <- state_target$datetime_utc
      input_rows <- nrow(state_target)
      sleep_joined <- attach_states_checked(
        state_target,
        sleep_preparation$intervals,
        stream_keys = "Id",
        object = paste0(site, " prepared sleep intervals")
      )
      wear_joined <- attach_states_checked(
        sleep_joined,
        wear_preparation$intervals,
        stream_keys = "Id",
        object = paste0(site, " prepared wear intervals")
      )
      aligned <- derive_measurement_context(
        dplyr::ungroup(wear_joined),
        placement = placement,
        brown_state_col = "State.Brown",
        wear_col = "wear",
        medi_col = "MEDI",
        light_col = "LIGHT",
        saturation_threshold = saturation_threshold
      )
      aligned <- dplyr::ungroup(aligned)
      validate_aligned_stream(aligned, saturation_threshold)
      join_audits[[paste(site, placement, sep = "/")]] <- tibble::tibble(
        site = site,
        placement = placement,
        input_minute_rows = input_rows,
        after_sleep_join_rows = nrow(sleep_joined),
        after_wear_join_rows = nrow(wear_joined),
        sleep_state_matched_rows = sum(!is.na(aligned$State.Brown)),
        wear_state_matched_rows = sum(!is.na(aligned$wear)),
        cardinality_preserved = input_rows == nrow(sleep_joined) &&
          input_rows == nrow(wear_joined)
      )
      key_audits[[paste(site, placement, "aligned", sep = "/")]] <-
        key_audit_row(
          aligned,
          stage = "state_aligned_one_minute",
          site = site,
          placement = placement,
          key = c("site", "Id", "position", "datetime_utc")
        )
      sample_audits[[paste(site, placement, "aligned", sep = "/")]] <-
        sample_audit_row(
          aligned,
          stage = "state_aligned_one_minute",
          site = site,
          placement = placement
        )
      state_audits[[paste(site, placement, sep = "/")]] <-
        state_audit_rows(aligned)
      state_conflict_audits[[paste(site, placement, sep = "/")]] <-
        state_conflict_audit_row(aligned)
      saturation_audits[[paste(site, placement, sep = "/")]] <-
        saturation_audit_row(aligned, saturation_threshold)
      saturation_observations[[paste(site, placement, sep = "/")]] <-
        saturation_observation_rows(aligned, saturation_threshold)

      aligned_path <- file.path(
        run_layout$aligned_site_position,
        paste0(site, "_", placement, "_aligned.rds")
      )
      record_artifact(
        write_rds_artifact(
          aligned,
          aligned_path,
          producer,
          metadata = list(
            artifact_type = "site_placement_state_aligned_minutes",
            run_label = run_layout$run_label,
            site = site,
            placement = placement,
            source_commit = light_source$specification$commit,
            source_doi = light_source$specification$doi,
            source_sha256 = light_source$downloaded_source$sha256,
            sleep_source_commit = sleep_source$specification$commit,
            sleep_source_doi = sleep_source$specification$doi,
            sleep_source_sha256 = sleep_source$downloaded_source$sha256,
            wear_source_commit = wear_source$specification$commit,
            wear_source_doi = wear_source$specification$doi,
            wear_source_sha256 = wear_source$downloaded_source$sha256,
            saturation_threshold = saturation_threshold
          )
        ),
        paste(site, placement, "aligned", sep = "/")
      )
      aligned_paths[[placement]] <- c(
        aligned_paths[[placement]],
        aligned_path
      )
      rm(
        annotated,
        minute_data,
        state_target,
        sleep_joined,
        wear_joined,
        aligned,
        light_source
      )
      invisible(gc())
    }
    rm(
      sleep_source,
      wear_source,
      state_pair,
      state_interval_export,
      sleep_preparation,
      wear_preparation
    )
    invisible(gc())
  }

  combined_paths <- list()
  for (placement in names(aligned_paths)) {
    placement_paths <- aligned_paths[[placement]]
    if (length(placement_paths) == 0L) {
      next
    }
    message("Assembling combined ", placement, " artifact")
    combined <- dplyr::bind_rows(lapply(
      placement_paths,
      read_rds_artifact,
      expected_class = "data.frame"
    ))
    combined <- dplyr::arrange(
      combined,
      .data$site,
      .data$Id,
      .data$datetime_utc
    )
    assert_unique_key(
      combined,
      c("site", "Id", "position", "datetime_utc"),
      object = paste0("combined ", placement, " aligned minutes")
    )
    combined_path <- file.path(
      run_layout$aligned_root,
      paste0("light_", placement, "_aligned.rds")
    )
    combined_sites <- sort(unique(combined$site))
    combined_state_sources <- download_manifest |>
      dplyr::filter(
        .data$site %in% combined_sites,
        .data$modality %in% c("sleepdiaries", "wearlog")
      ) |>
      dplyr::arrange(.data$site, .data$modality)
    record_artifact(
      write_rds_artifact(
        combined,
        combined_path,
        producer,
        metadata = list(
          artifact_type = "combined_state_aligned_minutes",
          run_label = run_layout$run_label,
          placement = placement,
          sites = paste(combined_sites, collapse = ","),
          state_source_commits = paste(
            paste0(
              combined_state_sources$site,
              "/",
              combined_state_sources$modality,
              "=",
              combined_state_sources$commit
            ),
            collapse = ";"
          ),
          state_source_dois = paste(
            paste0(
              combined_state_sources$site,
              "/",
              combined_state_sources$modality,
              "=",
              combined_state_sources$doi
            ),
            collapse = ";"
          ),
          state_source_sha256 = paste(
            paste0(
              combined_state_sources$site,
              "/",
              combined_state_sources$modality,
              "=",
              combined_state_sources$sha256
            ),
            collapse = ";"
          ),
          saturation_threshold = saturation_threshold
        )
      ),
      paste("combined", placement, sep = "/")
    )
    combined_paths[[placement]] <- combined_path
    rm(combined)
    invisible(gc())
  }

  audit_tables <- list(
    source_audit = dplyr::bind_rows(source_audits),
    key_audit = dplyr::bind_rows(key_audits),
    time_audit = dplyr::bind_rows(time_audits),
    stream_epoch_audit = dplyr::bind_rows(stream_epoch_audits),
    dst_fold_audit = dplyr::bind_rows(dst_fold_audits),
    state_interval_audit = dplyr::bind_rows(interval_audits),
    state_interval_summary = dplyr::bind_rows(interval_summaries),
    join_cardinality_audit = dplyr::bind_rows(join_audits),
    state_audit = dplyr::bind_rows(state_audits),
    state_conflict_audit = dplyr::bind_rows(state_conflict_audits),
    saturation_audit = dplyr::bind_rows(saturation_audits),
    saturation_observations = dplyr::bind_rows(saturation_observations),
    sample_audit = dplyr::bind_rows(sample_audits)
  )
  for (audit_name in names(audit_tables)) {
    audit_path <- file.path(
      run_layout$aligned_root,
      paste0(audit_name, ".csv")
    )
    record_artifact(
      write_csv_artifact(
        audit_tables[[audit_name]],
        audit_path,
        producer,
        metadata = list(
          artifact_type = audit_name,
          run_label = run_layout$run_label
        )
      ),
      paste("audit", audit_name, sep = "/")
    )
  }

  state_interval_manifest <- dplyr::bind_rows(artifact_records) |>
    dplyr::filter(
      .data$artifact_type %in%
        c(
          "site_sleep_state_intervals",
          "site_wear_state_intervals"
        )
    ) |>
    dplyr::arrange(.data$site, .data$interval_kind)
  state_interval_manifest_path <- file.path(
    paths$manifests,
    paste0(
      "state_interval_artifacts",
      run_layout$manifest_suffix,
      ".csv"
    )
  )
  record_artifact(
    write_csv_artifact(
      state_interval_manifest,
      state_interval_manifest_path,
      producer,
      metadata = list(
        artifact_type = "state_interval_artifact_manifest",
        run_label = run_layout$run_label
      )
    ),
    "state_interval_artifact_manifest"
  )

  artifact_manifest <- dplyr::bind_rows(artifact_records) |>
    dplyr::arrange(.data$artifact_type, .data$path)
  artifact_manifest_path <- file.path(
    paths$manifests,
    paste0(
      "import_alignment_artifacts",
      run_layout$manifest_suffix,
      ".csv"
    )
  )
  write_csv_artifact(
    artifact_manifest,
    artifact_manifest_path,
    producer,
    metadata = list(
      artifact_type = "import_alignment_artifact_manifest",
      run_label = run_layout$run_label
    )
  )

  list(
    run_label = run_layout$run_label,
    complete_run = run_layout$is_complete,
    requested_sites = requested_sites,
    combined_paths = combined_paths,
    state_interval_manifest_path = state_interval_manifest_path,
    artifact_manifest_path = artifact_manifest_path,
    audits = audit_tables
  )
}

regenerate_state_interval_artifacts <- function(
  root = project_root(),
  requested_sites = NULL,
  cache_policy = c("reuse", "refresh")
) {
  cache_policy <- match.arg(cache_policy)
  producer <- "scripts/pipeline/build_import_alignment.R"
  paths <- pipeline_paths(root)
  ensure_pipeline_directories(paths)
  site_sources <- read_site_sources(file.path(root, "config/site_sources.csv"))
  requested_sites <- normalise_requested_sites(
    requested_sites,
    site_sources$site
  )
  run_layout <- import_alignment_run_layout(
    paths,
    requested_sites,
    site_sources$site
  )
  download_manifest <- resolve_pinned_download_manifest(
    site_sources = site_sources,
    paths = paths,
    cache_policy = cache_policy
  )

  interval_records <- list()
  for (site in requested_sites) {
    site_row <- site_sources[site_sources$site == site, , drop = FALSE]
    load_state_source <- function(modality) {
      specification <- source_specification(
        site_sources,
        site = site,
        modality = modality
      )
      downloaded_source <- downloaded_source_row(
        download_manifest,
        site = site,
        modality = modality
      )
      list(
        data = dplyr::ungroup(load_pinned_source(
          specification,
          downloaded_source
        )),
        specification = specification,
        downloaded_source = downloaded_source
      )
    }
    sleep_source <- load_state_source("sleepdiaries")
    wear_source <- load_state_source("wearlog")
    state_pair <- prepare_state_interval_pair(
      sleep_diary = sleep_source$data,
      wear_log = wear_source$data,
      site = site,
      timezone = site_row$timezone
    )
    exported <- write_state_interval_pair(
      state_pair = state_pair,
      site = site,
      timezone = site_row$timezone,
      sleep_source = sleep_source,
      wear_source = wear_source,
      output_directory = run_layout$aligned_state_intervals,
      producer = producer,
      run_label = run_layout$run_label
    )
    interval_records[[paste(site, "sleep", sep = "/")]] <-
      manifest_row(exported$metadata$sleep)
    interval_records[[paste(site, "wear", sep = "/")]] <-
      manifest_row(exported$metadata$wear)

    persisted_sleep <- read_rds_artifact(
      exported$paths[["sleep"]],
      expected_class = "data.frame"
    )
    persisted_wear <- read_rds_artifact(
      exported$paths[["wear"]],
      expected_class = "data.frame"
    )
    validate_exported_state_intervals(persisted_sleep, "sleep")
    validate_exported_state_intervals(persisted_wear, "wear")
  }

  interval_manifest <- dplyr::bind_rows(interval_records) |>
    dplyr::arrange(.data$site, .data$interval_kind)
  expected_artifacts <- length(requested_sites) * 2L
  if (nrow(interval_manifest) != expected_artifacts) {
    abort_pipeline(
      "Expected %d state-interval artifacts; produced %d",
      expected_artifacts,
      nrow(interval_manifest)
    )
  }
  if (
    !all(file.exists(interval_manifest$path)) ||
      !all(vapply(
        seq_len(nrow(interval_manifest)),
        function(row) {
          artifact_sha256(interval_manifest$path[row]) ==
            interval_manifest$sha256[row]
        },
        logical(1)
      ))
  ) {
    abort_pipeline("State-interval artifact checksum verification failed")
  }

  interval_manifest_path <- file.path(
    paths$manifests,
    paste0(
      "state_interval_artifacts",
      run_layout$manifest_suffix,
      ".csv"
    )
  )
  interval_manifest_metadata <- write_csv_artifact(
    interval_manifest,
    interval_manifest_path,
    producer,
    metadata = list(
      artifact_type = "state_interval_artifact_manifest",
      run_label = run_layout$run_label
    )
  )
  main_manifest_path <- file.path(
    paths$manifests,
    paste0(
      "import_alignment_artifacts",
      run_layout$manifest_suffix,
      ".csv"
    )
  )
  replacement_rows <- dplyr::bind_rows(
    interval_manifest,
    manifest_row(interval_manifest_metadata)
  )
  if (file.exists(main_manifest_path)) {
    main_manifest <- readr::read_csv(
      main_manifest_path,
      show_col_types = FALSE
    ) |>
      dplyr::filter(
        !.data$artifact_type %in%
          c(
            "site_sleep_state_intervals",
            "site_wear_state_intervals",
            "state_interval_artifact_manifest"
          )
      )
    main_manifest <- dplyr::bind_rows(
      main_manifest,
      replacement_rows
    ) |>
      dplyr::arrange(.data$artifact_type, .data$path)
    write_csv_artifact(
      main_manifest,
      main_manifest_path,
      producer,
      metadata = list(
        artifact_type = "import_alignment_artifact_manifest",
        run_label = run_layout$run_label
      )
    )
  }

  list(
    run_label = run_layout$run_label,
    sites = requested_sites,
    interval_manifest = interval_manifest,
    interval_manifest_path = interval_manifest_path,
    main_manifest_path = if (file.exists(main_manifest_path)) {
      main_manifest_path
    } else {
      NA_character_
    }
  )
}

if (sys.nframe() == 0L) {
  root_override <- Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = "")
  execution_root <- if (nzchar(root_override)) {
    normalizePath(root_override, winslash = "/", mustWork = TRUE)
  } else {
    normalizePath(getwd(), winslash = "/", mustWork = TRUE)
  }
  dependencies <- c(
    "paths_io.R",
    "assertions.R",
    "import_sources.R",
    "time_axes.R",
    "state_alignment.R",
    "aggregation_coverage.R"
  )
  for (dependency in dependencies) {
    source(file.path(
      execution_root,
      "scripts",
      "pipeline",
      dependency
    ))
  }
  site_argument <- Sys.getenv("NATHEALTH_IMPORT_SITES", unset = "")
  requested <- if (nzchar(site_argument)) {
    strsplit(site_argument, ",", fixed = TRUE)[[1L]]
  } else {
    NULL
  }
  cache_argument <- Sys.getenv(
    "NATHEALTH_CACHE_POLICY",
    unset = "reuse"
  )
  intervals_only <- identical(
    Sys.getenv("NATHEALTH_INTERVALS_ONLY", unset = "0"),
    "1"
  )
  if (intervals_only) {
    result <- regenerate_state_interval_artifacts(
      root = execution_root,
      requested_sites = requested,
      cache_policy = cache_argument
    )
    print(
      tibble::as_tibble(result$interval_manifest) |>
        dplyr::select(dplyr::all_of(c(
          "site",
          "interval_kind",
          "path",
          "sha256"
        ))),
      n = Inf
    )
  } else {
    result <- build_import_alignment(
      root = execution_root,
      requested_sites = requested,
      cache_policy = cache_argument
    )
    print(result$audits$sample_audit)
  }
}
