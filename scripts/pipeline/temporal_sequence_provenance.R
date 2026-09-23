# Derive true-elapsed source-bin provenance for clock-aligned outcomes.
#
# Source scripts/pipeline/assertions.R before this file.

temporal_resolution_specification <- function() {
  tibble::tribble(
    ~resolution,
    ~bin_minutes,
    ~metric_clock_column,
    "30_minute",
    30L,
    "clock_bin",
    "one_hour",
    60L,
    "clock_minute"
  )
}

temporal_participant_key <- c("site", "Id", "position")
temporal_day_key <- c(temporal_participant_key, "local_date")
temporal_wall_key <- c(
  "resolution",
  temporal_day_key,
  "wall_bin_start_minute"
)

temporal_resolution_row <- function(resolution) {
  specification <- temporal_resolution_specification()
  if (
    !is.character(resolution) ||
      length(resolution) != 1L ||
      is.na(resolution) ||
      !resolution %in% specification$resolution
  ) {
    abort_pipeline(
      "`resolution` must be one of: %s",
      paste(specification$resolution, collapse = ", ")
    )
  }
  specification[
    specification$resolution == resolution,
    ,
    drop = FALSE
  ]
}

temporal_utc_label <- function(datetime) {
  if (!inherits(datetime, "POSIXct")) {
    abort_pipeline("True-time provenance timestamps must be POSIXct")
  }
  format(datetime, "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
}

temporal_wall_outcome_id <- function(
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

temporal_source_bin_id <- function(
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
    temporal_utc_label(true_utc_start),
    sep = "|"
  )
}

validate_temporal_coverage_input <- function(
  coverage,
  placement,
  object = deparse(substitute(coverage))
) {
  if (!is.data.frame(coverage) || nrow(coverage) == 0L) {
    abort_pipeline("%s must be a non-empty data frame", object)
  }
  required <- c(
    temporal_day_key,
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
  assert_columns(coverage, required, object = object)
  assert_no_missing_key(
    coverage,
    c(temporal_participant_key, "datetime_utc"),
    object = object
  )
  assert_unique_key(
    coverage,
    c(temporal_participant_key, "datetime_utc"),
    object = object
  )
  if (
    !inherits(coverage$datetime_utc, "POSIXct") ||
      !identical(lubridate::tz(coverage$datetime_utc), "UTC")
  ) {
    abort_pipeline("%s column `datetime_utc` must be true UTC", object)
  }
  if (
    !inherits(coverage$datetime_wall, "POSIXct") ||
      !identical(lubridate::tz(coverage$datetime_wall), "UTC")
  ) {
    abort_pipeline(
      "%s column `datetime_wall` must be pseudo-local POSIXct in UTC",
      object
    )
  }
  if (!inherits(coverage$local_date, "Date")) {
    abort_pipeline("%s column `local_date` must be Date", object)
  }
  if (
    !is.character(placement) ||
      length(placement) != 1L ||
      is.na(placement) ||
      !nzchar(placement)
  ) {
    abort_pipeline("`placement` must be one non-empty string")
  }
  observed_placements <- unique(as.character(coverage$position))
  if (!identical(observed_placements, placement)) {
    abort_pipeline(
      "%s has placement(s) %s; expected only %s",
      object,
      paste(observed_placements, collapse = ", "),
      placement
    )
  }
  if (
    !is.numeric(coverage$clock_minute) ||
      anyNA(coverage$clock_minute) ||
      any(
        coverage$clock_minute != as.integer(coverage$clock_minute) |
          coverage$clock_minute < 0L |
          coverage$clock_minute > 1439L
      )
  ) {
    abort_pipeline(
      "%s column `clock_minute` must contain integers from 0 to 1439",
      object
    )
  }
  if (
    !is.numeric(coverage$utc_offset_minutes) ||
      anyNA(coverage$utc_offset_minutes) ||
      any(
        coverage$utc_offset_minutes !=
          as.integer(
            coverage$utc_offset_minutes
          )
      )
  ) {
    abort_pipeline(
      "%s column `utc_offset_minutes` must contain non-missing integers",
      object
    )
  }
  if (
    !is.numeric(coverage$source_subepochs) ||
      !is.numeric(coverage$implicit_subepochs) ||
      anyNA(coverage$source_subepochs) ||
      anyNA(coverage$implicit_subepochs) ||
      any(
        coverage$source_subepochs < 0L |
          coverage$implicit_subepochs < 0L |
          coverage$implicit_subepochs > coverage$source_subepochs
      )
  ) {
    abort_pipeline(
      "%s has invalid source/implicit subepoch support",
      object
    )
  }
  logical_columns <- c(
    "is_dst",
    "MEDI_precoverage_observed",
    "coverage_period_eligible",
    "MEDI_coverage_eligible"
  )
  invalid_logical <- vapply(
    coverage[logical_columns],
    function(value) !is.logical(value) || anyNA(value),
    logical(1)
  )
  if (any(invalid_logical)) {
    abort_pipeline(
      "%s has invalid logical field(s): %s",
      object,
      paste(names(invalid_logical)[invalid_logical], collapse = ", ")
    )
  }
  if (
    any(
      coverage$MEDI_coverage_eligible &
        (!coverage$MEDI_precoverage_observed |
          !coverage$coverage_period_eligible)
    )
  ) {
    abort_pipeline(
      "%s marks MEDI eligible outside observed and eligible coverage",
      object
    )
  }
  invisible(coverage)
}

validate_temporal_metric_input <- function(
  metric,
  placement,
  resolution,
  object = deparse(substitute(metric))
) {
  if (!is.data.frame(metric) || nrow(metric) == 0L) {
    abort_pipeline("%s must be a non-empty data frame", object)
  }
  specification <- temporal_resolution_row(resolution)
  clock_column <- specification$metric_clock_column[[1L]]
  bin_minutes <- specification$bin_minutes[[1L]]
  required <- c(
    temporal_day_key,
    clock_column,
    "expected_wall_minutes",
    "wall_minutes_existing",
    "source_real_minutes",
    "source_observed_real_minutes",
    "dst_fold_wall_minutes",
    "valid_medi_wall_minutes",
    "ordinary_support",
    "bin_admissible",
    "failure_reason",
    "metric"
  )
  assert_columns(metric, c(required, "metric_value_lx"), object = object)
  assert_no_missing_key(
    metric,
    c(temporal_day_key, clock_column),
    object = object
  )
  assert_unique_key(
    metric,
    c(temporal_day_key, clock_column),
    object = object
  )
  if (!inherits(metric$local_date, "Date")) {
    abort_pipeline("%s column `local_date` must be Date", object)
  }
  observed_placements <- unique(as.character(metric$position))
  if (!identical(observed_placements, placement)) {
    abort_pipeline(
      "%s has placement(s) %s; expected only %s",
      object,
      paste(observed_placements, collapse = ", "),
      placement
    )
  }
  expected_clock <- seq.int(0L, 1440L - bin_minutes, by = bin_minutes)
  day_grid <- metric |>
    dplyr::group_by(dplyr::across(dplyr::all_of(temporal_day_key))) |>
    dplyr::summarise(
      rows = dplyr::n(),
      complete_clock_grid = identical(
        sort(as.integer(.data[[clock_column]])),
        expected_clock
      ),
      .groups = "drop"
    )
  if (
    any(day_grid$rows != length(expected_clock)) ||
      any(!day_grid$complete_clock_grid)
  ) {
    abort_pipeline(
      "%s must contain the complete %s wall-clock grid for every day",
      object,
      resolution
    )
  }
  if (
    any(metric$expected_wall_minutes != bin_minutes) ||
      !is.logical(metric$bin_admissible) ||
      anyNA(metric$bin_admissible)
  ) {
    abort_pipeline(
      "%s has invalid expected support or admissibility fields",
      object
    )
  }
  finite_outcome <- is.finite(metric$metric_value_lx)
  if (!identical(finite_outcome, metric$bin_admissible)) {
    abort_pipeline(
      "%s finite outcomes do not exactly match `bin_admissible`",
      object
    )
  }
  if (
    any(metric$bin_admissible & !is.na(metric$failure_reason)) ||
      any(!metric$bin_admissible & is.na(metric$failure_reason))
  ) {
    abort_pipeline(
      "%s failure reasons do not exactly complement admissibility",
      object
    )
  }
  invisible(metric)
}

temporal_local_day_type <- function(real_minutes) {
  dplyr::case_when(
    real_minutes == 1380L ~ "spring_forward_23h",
    real_minutes == 1440L ~ "ordinary_24h",
    real_minutes == 1500L ~ "fall_back_25h",
    TRUE ~ "unsupported_day_length"
  )
}

derive_true_utc_source_bins <- function(
  coverage,
  metric,
  placement,
  resolution
) {
  validate_temporal_coverage_input(
    coverage,
    placement,
    object = paste0(placement, " coverage input")
  )
  validate_temporal_metric_input(
    metric,
    placement,
    resolution,
    object = paste(placement, resolution, "metric input")
  )
  specification <- temporal_resolution_row(resolution)
  bin_minutes <- specification$bin_minutes[[1L]]

  day_domain <- metric |>
    dplyr::distinct(dplyr::across(dplyr::all_of(temporal_day_key)))
  coverage_days <- coverage |>
    dplyr::distinct(dplyr::across(dplyr::all_of(temporal_day_key)))
  unmatched_days <- dplyr::anti_join(
    day_domain,
    coverage_days,
    by = temporal_day_key
  )
  if (nrow(unmatched_days) > 0L) {
    abort_pipeline(
      "%s %s metrics contain %d day(s) absent from coverage",
      placement,
      resolution,
      nrow(unmatched_days)
    )
  }

  minute <- coverage |>
    dplyr::semi_join(day_domain, by = temporal_day_key) |>
    dplyr::select(
      dplyr::all_of(temporal_day_key),
      dplyr::all_of(c(
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
      ))
    ) |>
    dplyr::arrange(
      .data$site,
      .data$Id,
      .data$position,
      .data$local_date,
      .data$datetime_utc
    ) |>
    dplyr::group_by(dplyr::across(dplyr::all_of(temporal_day_key))) |>
    dplyr::mutate(
      day_real_minutes = dplyr::n(),
      wall_bin_start_minute = as.integer(
        floor(.data$clock_minute / bin_minutes) * bin_minutes
      ),
      previous_utc = dplyr::lag(.data$datetime_utc),
      previous_wall = dplyr::lag(.data$datetime_wall),
      new_source_bin = dplyr::row_number() == 1L |
        .data$wall_bin_start_minute !=
          dplyr::lag(
            .data$wall_bin_start_minute,
            default = dplyr::first(.data$wall_bin_start_minute)
          ) |
        as.numeric(difftime(
          .data$datetime_wall,
          .data$previous_wall,
          units = "secs"
        )) !=
          60 |
        as.numeric(difftime(
          .data$datetime_utc,
          .data$previous_utc,
          units = "secs"
        )) !=
          60,
      source_bin_run = cumsum(.data$new_source_bin)
    ) |>
    dplyr::ungroup()

  unsupported_day <- minute |>
    dplyr::distinct(
      dplyr::across(dplyr::all_of(temporal_day_key)),
      .data$day_real_minutes
    ) |>
    dplyr::filter(
      !.data$day_real_minutes %in% c(1380L, 1440L, 1500L)
    )
  if (nrow(unsupported_day) > 0L) {
    abort_pipeline(
      "%s %s coverage contains unsupported local-day length(s)",
      placement,
      resolution
    )
  }
  minute_gap <- minute |>
    dplyr::filter(
      !is.na(.data$previous_utc) &
        as.numeric(difftime(
          .data$datetime_utc,
          .data$previous_utc,
          units = "secs"
        )) !=
          60
    )
  if (nrow(minute_gap) > 0L) {
    abort_pipeline(
      "%s %s coverage is not a complete consecutive true-minute day grid",
      placement,
      resolution
    )
  }

  source_bins <- minute |>
    dplyr::group_by(
      dplyr::across(dplyr::all_of(temporal_day_key)),
      .data$source_bin_run
    ) |>
    dplyr::summarise(
      wall_bin_start_minute = dplyr::first(
        .data$wall_bin_start_minute
      ),
      true_utc_start = min(.data$datetime_utc),
      true_utc_end = max(.data$datetime_utc) + 60,
      true_utc_last_minute = max(.data$datetime_utc),
      wall_datetime_start = dplyr::first(.data$datetime_wall),
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
    ) |>
    dplyr::mutate(
      resolution = resolution,
      bin_minutes = as.integer(bin_minutes),
      local_day_type = temporal_local_day_type(.data$day_real_minutes),
      source_support_fraction = .data$source_present_real_minutes /
        .data$expected_real_minutes,
      observed_medi_support_fraction = .data$observed_medi_real_minutes /
        .data$expected_real_minutes,
      eligible_medi_support_fraction = .data$eligible_medi_real_minutes /
        .data$expected_real_minutes,
      offset_changes_within_bin = .data$utc_offset_start_minutes !=
        .data$utc_offset_end_minutes,
      source_bin_id = temporal_source_bin_id(
        resolution = .data$resolution,
        site = .data$site,
        Id = .data$Id,
        position = .data$position,
        true_utc_start = .data$true_utc_start
      ),
      outcome_row_id = temporal_wall_outcome_id(
        resolution = .data$resolution,
        site = .data$site,
        Id = .data$Id,
        position = .data$position,
        local_date = .data$local_date,
        wall_bin_start_minute = .data$wall_bin_start_minute
      ),
      true_utc_range = paste0(
        temporal_utc_label(.data$true_utc_start),
        "/",
        temporal_utc_label(.data$true_utc_end)
      )
    ) |>
    dplyr::group_by(dplyr::across(dplyr::all_of(temporal_wall_key))) |>
    dplyr::arrange(.data$true_utc_start, .by_group = TRUE) |>
    dplyr::mutate(
      source_bins_for_wall_outcome = dplyr::n(),
      wall_occurrence = dplyr::row_number(),
      repeated_fall_back_source_bin = .data$source_bins_for_wall_outcome > 1L
    ) |>
    dplyr::ungroup() |>
    dplyr::select(-dplyr::all_of("source_bin_run"))

  if (
    any(source_bins$expected_real_minutes != bin_minutes) ||
      any(source_bins$source_bins_for_wall_outcome > 2L)
  ) {
    abort_pipeline(
      "%s %s true-time source bins violate expected support or cardinality",
      placement,
      resolution
    )
  }
  assert_unique_key(
    source_bins,
    c("resolution", temporal_participant_key, "true_utc_start"),
    object = paste(placement, resolution, "true-UTC source bins")
  )
  source_bins
}

build_wall_outcome_links <- function(
  metric,
  source_bins,
  placement,
  resolution
) {
  validate_temporal_metric_input(
    metric,
    placement,
    resolution,
    object = paste(placement, resolution, "metric input")
  )
  specification <- temporal_resolution_row(resolution)
  clock_column <- specification$metric_clock_column[[1L]]
  bin_minutes <- specification$bin_minutes[[1L]]

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
      outcome_row_id = temporal_wall_outcome_id(
        resolution = resolution,
        site = .data$site,
        Id = .data$Id,
        position = .data$position,
        local_date = .data$local_date,
        wall_bin_start_minute = .data[[clock_column]]
      )
    )

  source_summary <- source_bins |>
    dplyr::group_by(dplyr::across(dplyr::all_of(temporal_wall_key))) |>
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
  day_type <- source_bins |>
    dplyr::distinct(
      dplyr::across(dplyr::all_of(temporal_day_key)),
      .data$local_day_type
    )

  links <- outcome |>
    dplyr::left_join(
      source_summary,
      by = temporal_wall_key,
      relationship = "one-to-one"
    ) |>
    dplyr::left_join(
      day_type,
      by = temporal_day_key,
      relationship = "many-to-one",
      suffix = c("", ".day")
    )
  if ("local_day_type.day" %in% names(links)) {
    links$local_day_type <- dplyr::coalesce(
      links$local_day_type,
      links$local_day_type.day
    )
    links$local_day_type.day <- NULL
  }
  links$source_bin_links <- dplyr::coalesce(
    as.integer(links$source_bin_links),
    0L
  )
  integer_support <- c(
    "source_expected_real_minutes_total",
    "source_present_real_minutes_total",
    "source_observed_medi_real_minutes_total",
    "source_coverage_eligible_real_minutes_total",
    "source_eligible_medi_real_minutes_total"
  )
  for (column in integer_support) {
    links[[column]] <- dplyr::coalesce(
      as.integer(links[[column]]),
      0L
    )
  }
  character_support <- c(
    "source_bin_ids",
    "source_utc_ranges",
    "source_utc_offsets_minutes",
    "source_dst_states"
  )
  for (column in character_support) {
    links[[column]] <- dplyr::coalesce(
      as.character(links[[column]]),
      ""
    )
  }
  links <- links |>
    dplyr::mutate(
      relationship_type = dplyr::case_when(
        .data$source_bin_links == 0L ~ "zero_to_one_structural_spring_gap",
        .data$source_bin_links == 1L ~ "one_to_one_true_elapsed",
        .data$source_bin_links == 2L ~ "two_to_one_averaged_fall_back",
        TRUE ~ "invalid_mapping_cardinality"
      ),
      fold_provenance = dplyr::if_else(
        .data$source_bin_links == 2L,
        "averaged_repeated_wall_bin",
        "none"
      ),
      spring_gap_provenance = dplyr::if_else(
        .data$source_bin_links == 0L,
        "structural_nonexistent_wall_bin",
        "none"
      ),
      one_to_one_elapsed_coordinate = .data$source_bin_links == 1L
    ) |>
    dplyr::arrange(
      .data$resolution,
      .data$site,
      .data$Id,
      .data$position,
      .data$local_date,
      .data$wall_bin_start_minute
    )

  invalid_cardinality <- !links$source_bin_links %in% 0:2
  invalid_zero <- links$source_bin_links == 0L &
    (links$local_day_type != "spring_forward_23h" |
      links$outcome_wall_minutes_existing != 0L |
      links$outcome_source_real_minutes != 0L |
      links$outcome_dst_fold_wall_minutes != 0L)
  invalid_two <- links$source_bin_links == 2L &
    (links$local_day_type != "fall_back_25h" |
      links$outcome_dst_fold_wall_minutes <= 0L)
  invalid_one <- links$source_bin_links == 1L &
    links$outcome_dst_fold_wall_minutes != 0L
  invalid_source_support <-
    links$source_expected_real_minutes_total !=
      links$outcome_source_real_minutes
  if (
    any(invalid_cardinality) ||
      any(invalid_zero) ||
      any(invalid_two) ||
      any(invalid_one) ||
      any(invalid_source_support)
  ) {
    abort_pipeline(
      "%s %s wall-to-source mapping violates DST or support invariants",
      placement,
      resolution
    )
  }
  assert_unique_key(
    links,
    temporal_wall_key,
    object = paste(placement, resolution, "wall outcome links")
  )
  attr(links, "metric_settings") <- NULL
  links
}

add_true_elapsed_sequences <- function(source_bins, wall_links) {
  assert_unique_key(
    source_bins,
    c("resolution", temporal_participant_key, "true_utc_start"),
    object = "true-UTC source bins"
  )
  assert_unique_key(
    wall_links,
    temporal_wall_key,
    object = "wall outcome links"
  )
  link_fields <- wall_links |>
    dplyr::select(
      dplyr::all_of(temporal_wall_key),
      dplyr::all_of(c(
        "relationship_type",
        "one_to_one_elapsed_coordinate",
        "outcome_usable",
        "outcome_bin_admissible",
        "outcome_failure_reason"
      ))
    )
  output <- source_bins |>
    dplyr::left_join(
      link_fields,
      by = temporal_wall_key,
      relationship = "many-to-one"
    )
  if (
    anyNA(output$one_to_one_elapsed_coordinate) ||
      anyNA(output$outcome_usable)
  ) {
    abort_pipeline("A true-UTC source bin lacks its wall outcome link")
  }
  output <- output |>
    dplyr::arrange(
      .data$resolution,
      .data$site,
      .data$Id,
      .data$position,
      .data$true_utc_start
    ) |>
    dplyr::group_by(
      .data$resolution,
      dplyr::across(dplyr::all_of(temporal_participant_key))
    ) |>
    dplyr::mutate(
      previous_true_utc_end = dplyr::lag(.data$true_utc_end),
      elapsed_from_previous_seconds = as.numeric(difftime(
        .data$true_utc_start,
        .data$previous_true_utc_end,
        units = "secs"
      )),
      previous_wall_datetime_start = dplyr::lag(
        .data$wall_datetime_start
      ),
      wall_elapsed_from_previous_minutes = as.numeric(difftime(
        .data$wall_datetime_start,
        .data$previous_wall_datetime_start,
        units = "mins"
      )),
      previous_one_to_one_elapsed_coordinate = dplyr::lag(
        .data$one_to_one_elapsed_coordinate
      ),
      previous_outcome_usable = dplyr::lag(.data$outcome_usable),
      sequence_eligible = .data$one_to_one_elapsed_coordinate &
        .data$outcome_usable,
      sequence_start_reason = dplyr::case_when(
        !.data$one_to_one_elapsed_coordinate ~
          "excluded_non_one_to_one_wall_outcome",
        !.data$outcome_usable ~ "excluded_unusable_wall_outcome",
        dplyr::row_number() == 1L ~ "participant_start",
        is.na(.data$elapsed_from_previous_seconds) ~ "participant_start",
        .data$elapsed_from_previous_seconds != 0 ~ "after_true_utc_gap",
        .data$wall_elapsed_from_previous_minutes != .data$bin_minutes ~
          "after_structural_wall_gap",
        !.data$previous_one_to_one_elapsed_coordinate ~
          "after_non_one_to_one_wall_outcome",
        !.data$previous_outcome_usable ~ "after_unusable_wall_outcome",
        TRUE ~ "continuous"
      ),
      true_elapsed_sequence_start = .data$sequence_eligible &
        .data$sequence_start_reason != "continuous",
      sequence_number = cumsum(.data$true_elapsed_sequence_start),
      true_elapsed_sequence_id = dplyr::if_else(
        .data$sequence_eligible,
        paste(
          .data$resolution,
          .data$site,
          .data$Id,
          .data$position,
          sprintf("S%05d", .data$sequence_number),
          sep = "|"
        ),
        NA_character_
      )
    ) |>
    dplyr::ungroup() |>
    dplyr::select(-dplyr::all_of("sequence_number"))

  invalid_excluded <- !output$sequence_eligible &
    (output$true_elapsed_sequence_start |
      !is.na(output$true_elapsed_sequence_id))
  continuous <- output$sequence_start_reason == "continuous"
  invalid_continuous <- continuous &
    (!output$sequence_eligible |
      output$true_elapsed_sequence_start |
      output$elapsed_from_previous_seconds != 0 |
      output$wall_elapsed_from_previous_minutes != output$bin_minutes |
      !output$previous_one_to_one_elapsed_coordinate |
      !output$previous_outcome_usable)
  if (any(invalid_excluded) || any(invalid_continuous)) {
    abort_pipeline("True-elapsed sequence construction bridged an invalid bin")
  }
  output
}

build_temporal_sequence_provenance <- function(
  coverage,
  metric,
  placement,
  resolution
) {
  source_bins <- derive_true_utc_source_bins(
    coverage = coverage,
    metric = metric,
    placement = placement,
    resolution = resolution
  )
  wall_links <- build_wall_outcome_links(
    metric = metric,
    source_bins = source_bins,
    placement = placement,
    resolution = resolution
  )
  source_bins <- add_true_elapsed_sequences(source_bins, wall_links)
  list(
    source_bins = source_bins,
    wall_links = wall_links
  )
}

temporal_provenance_csv_data <- function(data) {
  output <- dplyr::ungroup(data)
  posix_columns <- names(output)[vapply(
    output,
    inherits,
    logical(1),
    what = "POSIXct"
  )]
  for (column in posix_columns) {
    output[[column]] <- ifelse(
      is.na(output[[column]]),
      NA_character_,
      temporal_utc_label(output[[column]])
    )
  }
  date_columns <- names(output)[vapply(
    output,
    inherits,
    logical(1),
    what = "Date"
  )]
  for (column in date_columns) {
    output[[column]] <- format(output[[column]], "%Y-%m-%d")
  }
  output
}

validate_combined_temporal_provenance <- function(
  source_bins,
  wall_links
) {
  assert_unique_key(
    source_bins,
    c("resolution", temporal_participant_key, "true_utc_start"),
    object = "combined true-UTC source bins"
  )
  assert_unique_key(
    source_bins,
    "source_bin_id",
    object = "combined true-UTC source-bin IDs"
  )
  assert_unique_key(
    wall_links,
    temporal_wall_key,
    object = "combined wall outcome links"
  )
  assert_unique_key(
    wall_links,
    "outcome_row_id",
    object = "combined wall outcome IDs"
  )
  if (
    any(
      source_bins$repeated_fall_back_source_bin &
        source_bins$sequence_eligible
    ) ||
      any(
        !wall_links$one_to_one_elapsed_coordinate &
          wall_links$source_bin_links == 2L &
          wall_links$relationship_type != "two_to_one_averaged_fall_back"
      )
  ) {
    abort_pipeline(
      "A fall-back averaged outcome is sequence-eligible or mislabeled"
    )
  }
  mapped_source <- source_bins |>
    dplyr::count(
      dplyr::across(dplyr::all_of(temporal_wall_key)),
      name = "reconstructed_links"
    )
  link_check <- wall_links |>
    dplyr::left_join(
      mapped_source,
      by = temporal_wall_key,
      relationship = "one-to-one"
    ) |>
    dplyr::mutate(
      reconstructed_links = dplyr::coalesce(
        .data$reconstructed_links,
        0L
      )
    )
  if (any(link_check$source_bin_links != link_check$reconstructed_links)) {
    abort_pipeline("Combined wall-link cardinalities do not reconcile")
  }
  invisible(TRUE)
}
