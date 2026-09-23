
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
    "end"
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
  valid_states <- if (interval_kind == "sleep") {
    all(validated$State.Brown %in% c("wake", "pre-sleep", "sleep")) &&
      all(validated$sleep %in% c("wake", "sleepprep"))
  } else {
    all(validated$wear %in% c("off", "sleep", "site_leave"))
  }
  if (!valid_states) {
    abort_pipeline(
      "%s intervals contain invalid state labels",
      interval_kind
    )
  }
  invisible(validated)
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


read_metric_state_interval_inputs <- function(state_interval_root, sites) {
  inputs <- state_interval_artifact_paths(state_interval_root, sites)
  objects <- lapply(seq_len(nrow(inputs)), function(index) {
    object <- read_rds_artifact(inputs$path[index], "data.frame")
    validate_metric_state_interval_artifact(object, inputs$interval_kind[index])
    stopifnot(identical(unique(as.character(object$site)), inputs$site[index]))
    dplyr::ungroup(object)
  })
  sleep <- dplyr::bind_rows(objects[inputs$interval_kind == "sleep"]) |>
    dplyr::arrange(.data$site, .data$Id, .data$start, .data$end)
  wear <- dplyr::bind_rows(objects[inputs$interval_kind == "wear"]) |>
    dplyr::arrange(.data$site, .data$Id, .data$start, .data$end)
  validate_interval_table(sleep, id_cols = c("site", "Id"), object = "Sleep intervals")
  validate_interval_table(wear, id_cols = c("site", "Id"), object = "Wear intervals")
  list(sleep = sleep, wear = wear)
}
