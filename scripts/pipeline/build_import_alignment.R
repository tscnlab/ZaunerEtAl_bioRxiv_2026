# Prepare and validate recording and diary intervals.

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
