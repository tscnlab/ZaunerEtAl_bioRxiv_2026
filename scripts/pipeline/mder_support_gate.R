# Cutoff-neutral support diagnostics for the ratio-of-paired-integrals MDER.

mder_support_day_key <- c("site", "Id", "position", "local_date")
mder_support_participant_key <- c("site", "Id", "position")
mder_support_candidate_cutoffs <- c(0.70, 0.80, 0.90)

mder_finite_quantile <- function(value, probability) {
  finite <- is.finite(value)
  if (!any(finite)) {
    return(NA_real_)
  }
  as.numeric(stats::quantile(
    value[finite],
    probs = probability,
    names = FALSE,
    type = 7
  ))
}

mder_gate_single_value <- function(value, name, object) {
  observed <- unique(value[!is.na(value)])
  if (length(observed) != 1L) {
    abort_pipeline(
      "%s must have exactly one non-missing `%s` value; found %d",
      object,
      name,
      length(observed)
    )
  }
  observed[[1L]]
}

validate_mder_candidate_cutoffs <- function(
  candidate_cutoffs = mder_support_candidate_cutoffs
) {
  if (
    !is.numeric(candidate_cutoffs) ||
      anyNA(candidate_cutoffs) ||
      any(!is.finite(candidate_cutoffs)) ||
      any(candidate_cutoffs < 0 | candidate_cutoffs > 1)
  ) {
    abort_pipeline("MDER candidate cutoffs must be finite values in [0, 1]")
  }
  candidate_cutoffs <- sort(unique(as.numeric(candidate_cutoffs)))
  if (
    length(candidate_cutoffs) != length(mder_support_candidate_cutoffs) ||
      !isTRUE(all.equal(
        candidate_cutoffs,
        mder_support_candidate_cutoffs,
        tolerance = 1e-12
      ))
  ) {
    abort_pipeline(
      "The cutoff-neutral MDER gate is fixed at 0.70, 0.80, and 0.90"
    )
  }
  candidate_cutoffs
}

mder_candidate_column <- function(candidate_cutoff) {
  paste0(
    "retained_at_",
    gsub(".", "_", sprintf("%.2f", candidate_cutoff), fixed = TRUE)
  )
}

assert_no_mder_l5 <- function(...) {
  objects <- list(...)
  contains_l5 <- vapply(
    objects,
    function(object) {
      if (!is.data.frame(object)) {
        return(FALSE)
      }
      name_match <- any(grepl("L5", names(object), fixed = TRUE))
      character_columns <- vapply(
        object,
        function(column) is.character(column) || is.factor(column),
        logical(1)
      )
      value_match <- if (any(character_columns)) {
        any(vapply(
          object[character_columns],
          function(column) {
            any(grepl("L5", as.character(column), fixed = TRUE), na.rm = TRUE)
          },
          logical(1)
        ))
      } else {
        FALSE
      }
      name_match || value_match
    },
    logical(1)
  )
  if (any(contains_l5)) {
    abort_pipeline(
      "An excluded darkest-five-hour label entered the MDER support gate"
    )
  }
  invisible(TRUE)
}

validate_mder_fixed_profiles <- function(profiles, maps, placements) {
  if (!is.data.frame(profiles) || !is.data.frame(maps)) {
    abort_pipeline("Fixed profiles and relevance maps must be data frames")
  }
  assert_no_mder_l5(profiles, maps)
  profile_columns <- c(
    "profile_scope",
    "profile_variant",
    "placement",
    "state_domain",
    "signal",
    "clock_bin",
    "profile_supported",
    "reference_weight"
  )
  map_columns <- c(
    profile_columns,
    "metric_map",
    "map_estimable",
    "relevance_weight"
  )
  assert_columns(profiles, profile_columns, object = "fixed profiles")
  assert_columns(maps, map_columns, object = "fixed relevance maps")

  selected_profiles <- profiles |>
    dplyr::filter(
      .data$profile_scope == "pooled",
      .data$profile_variant == "pooled",
      .data$placement %in% .env$placements,
      .data$state_domain == "full_day",
      .data$signal %in% c("MEDI", "LIGHT")
    ) |>
    dplyr::arrange(.data$placement, .data$signal, .data$clock_bin)
  selected_maps <- maps |>
    dplyr::filter(
      .data$profile_scope == "pooled",
      .data$profile_variant == "pooled",
      .data$placement %in% .env$placements,
      .data$state_domain == "full_day",
      .data$signal %in% c("MEDI", "LIGHT"),
      .data$metric_map == "paired_channel_coverage"
    ) |>
    dplyr::arrange(.data$placement, .data$signal, .data$clock_bin)

  expected_bins <- seq.int(0L, 1410L, by = 30L)
  expected_rows <- length(placements) * 2L * length(expected_bins)
  if (
    nrow(selected_profiles) != expected_rows ||
      nrow(selected_maps) != expected_rows
  ) {
    abort_pipeline(
      paste0(
        "The MDER support gate requires one complete pooled full-day ",
        "MEDI and LIGHT profile for every requested placement"
      )
    )
  }
  profile_key <- c("placement", "state_domain", "signal", "clock_bin")
  assert_unique_key(
    selected_profiles,
    profile_key,
    object = "pooled full-day fixed profiles"
  )
  assert_unique_key(
    selected_maps,
    c(profile_key, "metric_map"),
    object = "pooled full-day paired-channel maps"
  )

  grouped_profiles <- split(
    selected_profiles,
    interaction(
      selected_profiles$placement,
      selected_profiles$signal,
      drop = TRUE,
      lex.order = TRUE
    )
  )
  grouped_maps <- split(
    selected_maps,
    interaction(
      selected_maps$placement,
      selected_maps$signal,
      drop = TRUE,
      lex.order = TRUE
    )
  )
  validate_group <- function(data, weight_column, supported_column, object) {
    if (!identical(as.integer(data$clock_bin), expected_bins)) {
      abort_pipeline(
        "%s does not contain the ordered 30-minute clock grid",
        object
      )
    }
    weight <- data[[weight_column]]
    supported <- data[[supported_column]]
    if (
      !is.logical(supported) ||
        anyNA(supported) ||
        !all(supported) ||
        !is.numeric(weight) ||
        anyNA(weight) ||
        any(!is.finite(weight) | weight < 0) ||
        !isTRUE(all.equal(sum(weight), 1, tolerance = 1e-12))
    ) {
      abort_pipeline(
        "%s must be complete, supported, non-negative, and normalized",
        object
      )
    }
    invisible(TRUE)
  }
  invisible(lapply(grouped_profiles, function(data) {
    validate_group(
      data,
      weight_column = "reference_weight",
      supported_column = "profile_supported",
      object = "A pooled full-day fixed profile"
    )
  }))
  invisible(lapply(grouped_maps, function(data) {
    validate_group(
      data,
      weight_column = "relevance_weight",
      supported_column = "map_estimable",
      object = "A pooled full-day paired-channel map"
    )
  }))

  profile_weights <- selected_profiles[
    c(profile_key, "reference_weight")
  ]
  names(profile_weights)[names(profile_weights) == "reference_weight"] <-
    "profile_weight"
  map_weights <- selected_maps[c(profile_key, "relevance_weight")]
  names(map_weights)[names(map_weights) == "relevance_weight"] <- "map_weight"
  compared <- dplyr::left_join(
    profile_weights,
    map_weights,
    by = profile_key,
    relationship = "one-to-one"
  )
  if (
    anyNA(compared$map_weight) ||
      !isTRUE(all.equal(
        compared$profile_weight,
        compared$map_weight,
        tolerance = 1e-12
      ))
  ) {
    abort_pipeline(
      paste0(
        "Paired-channel relevance weights do not reproduce the fixed ",
        "signal-specific reference-profile weights"
      )
    )
  }

  list(profiles = selected_profiles, maps = selected_maps)
}

validate_mder_coverage_input <- function(
  data,
  placement,
  object = deparse(substitute(data))
) {
  if (!is.data.frame(data)) {
    abort_pipeline("%s must be a data frame", object)
  }
  required <- c(
    mder_support_day_key,
    "timezone",
    "datetime_utc",
    "clock_minute",
    "day_eligible",
    "MEDI_eligible",
    "LIGHT_eligible",
    "source_subepochs"
  )
  assert_columns(data, required, object = object)
  assert_no_missing_key(
    data,
    c(
      mder_support_participant_key,
      "local_date",
      "timezone",
      "datetime_utc",
      "clock_minute"
    ),
    object = object
  )
  assert_unique_key(
    data,
    c(mder_support_participant_key, "datetime_utc"),
    object = object
  )
  if (
    !inherits(data$local_date, "Date") ||
      !inherits(data$datetime_utc, "POSIXct") ||
      !identical(lubridate::tz(data$datetime_utc), "UTC")
  ) {
    abort_pipeline(
      "%s must contain Date `local_date` and UTC POSIXct `datetime_utc`",
      object
    )
  }
  datetime_numeric <- as.numeric(data$datetime_utc)
  nearest_minute <- round(datetime_numeric / 60) * 60
  off_minute <- !is.finite(datetime_numeric) |
    abs(datetime_numeric - nearest_minute) > 1e-6
  if (any(off_minute)) {
    abort_pipeline(
      "%s has %d `datetime_utc` value(s) outside an exact minute boundary",
      object,
      sum(off_minute)
    )
  }
  if (any(as.character(data$position) != placement)) {
    abort_pipeline("%s contains a placement other than `%s`", object, placement)
  }
  if (
    !is.logical(data$day_eligible) ||
      anyNA(data$day_eligible)
  ) {
    abort_pipeline("%s `day_eligible` must be complete logical", object)
  }
  if (
    !is.numeric(data$clock_minute) ||
      anyNA(data$clock_minute) ||
      any(
        data$clock_minute < 0 |
          data$clock_minute >= 1440 |
          data$clock_minute != as.integer(data$clock_minute)
      )
  ) {
    abort_pipeline("%s has invalid pseudo-local clock minutes", object)
  }
  invalid_timezones <- !as.character(data$timezone) %in% OlsonNames()
  if (any(invalid_timezones)) {
    abort_pipeline("%s contains an invalid Olson time zone", object)
  }
  site_timezones <- data |>
    dplyr::distinct(.data$site, .data$timezone) |>
    dplyr::count(.data$site, name = "timezone_count")
  if (any(site_timezones$timezone_count != 1L)) {
    abort_pipeline("%s assigns more than one time zone to a site", object)
  }
  timezone <- as.character(data$timezone)
  derived_local_date <- as.Date(rep(NA_character_, nrow(data)))
  derived_clock_minute <- rep(NA_integer_, nrow(data))
  for (timezone_value in sort(unique(timezone))) {
    rows <- which(timezone == timezone_value)
    local_datetime <- lubridate::with_tz(
      data$datetime_utc[rows],
      tzone = timezone_value
    )
    local_fields <- as.POSIXlt(local_datetime, tz = timezone_value)
    derived_local_date[rows] <- as.Date(
      local_datetime,
      tz = timezone_value
    )
    derived_clock_minute[rows] <- as.integer(
      local_fields$hour * 60L + local_fields$min
    )
  }
  bad_local_date <- derived_local_date != data$local_date
  bad_clock_minute <- derived_clock_minute != as.integer(data$clock_minute)
  if (any(bad_local_date) || any(bad_clock_minute)) {
    abort_pipeline(
      paste0(
        "%s has %d row(s) whose `timezone`, `local_date`, or ",
        "`clock_minute` does not match `datetime_utc`"
      ),
      object,
      sum(bad_local_date | bad_clock_minute)
    )
  }
  for (signal in c("MEDI_eligible", "LIGHT_eligible")) {
    value <- data[[signal]]
    if (
      !is.numeric(value) ||
        any(!is.na(value) & (!is.finite(value) | value < 0))
    ) {
      abort_pipeline(
        "%s `%s` must contain finite non-negative values or NA",
        object,
        signal
      )
    }
  }
  if (any(is.finite(data$MEDI_eligible) & data$MEDI_eligible >= 100000)) {
    abort_pipeline(
      "%s contains eligible MEDI at or above the 100000 lx boundary",
      object
    )
  }
  source_subepochs <- data$source_subepochs
  if (
    !is.numeric(source_subepochs) ||
      anyNA(source_subepochs) ||
      any(
        !is.finite(source_subepochs) |
          source_subepochs < 0 |
          source_subepochs != as.integer(source_subepochs)
      )
  ) {
    abort_pipeline(
      "%s `source_subepochs` must contain complete non-negative integers",
      object
    )
  }
  source_present <- source_subepochs > 0L
  eligible_signal_present <- is.finite(data$MEDI_eligible) |
    is.finite(data$LIGHT_eligible)
  if (any(!source_present & eligible_signal_present)) {
    abort_pipeline(
      "%s has eligible light values on source-absent minutes",
      object
    )
  }
  for (source_present_col in intersect(
    c("source_present", "source_minute_present"),
    names(data)
  )) {
    recorded_source_present <- data[[source_present_col]]
    if (
      !is.logical(recorded_source_present) ||
        anyNA(recorded_source_present) ||
        !identical(recorded_source_present, source_present)
    ) {
      abort_pipeline(
        "%s `%s` is inconsistent with `source_subepochs > 0`",
        object,
        source_present_col
      )
    }
  }
  if ("expected_subepochs" %in% names(data)) {
    expected_subepochs <- data$expected_subepochs
    if (
      !is.numeric(expected_subepochs) ||
        anyNA(expected_subepochs) ||
        any(
          !is.finite(expected_subepochs) |
            expected_subepochs < 1 |
            expected_subepochs != as.integer(expected_subepochs)
        ) ||
        any(source_subepochs > expected_subepochs)
    ) {
      abort_pipeline(
        paste0(
          "%s `expected_subepochs` must be positive integers and may ",
          "not be smaller than `source_subepochs`"
        ),
        object
      )
    }
  }
  if ("observed_subepochs" %in% names(data)) {
    observed_subepochs <- data$observed_subepochs
    if (
      !is.numeric(observed_subepochs) ||
        anyNA(observed_subepochs) ||
        any(
          !is.finite(observed_subepochs) |
            observed_subepochs < 0 |
            observed_subepochs != as.integer(observed_subepochs)
        ) ||
        !identical(
          as.integer(observed_subepochs),
          as.integer(source_subepochs)
        )
    ) {
      abort_pipeline(
        "%s `observed_subepochs` must equal `source_subepochs`",
        object
      )
    }
  }
  if ("distinct_subepochs" %in% names(data)) {
    distinct_subepochs <- data$distinct_subepochs
    if (
      !is.numeric(distinct_subepochs) ||
        anyNA(distinct_subepochs) ||
        any(
          !is.finite(distinct_subepochs) |
            distinct_subepochs < 0 |
            distinct_subepochs != as.integer(distinct_subepochs) |
            distinct_subepochs > source_subepochs
        )
    ) {
      abort_pipeline(
        "%s has invalid `distinct_subepochs` relative to source rows",
        object
      )
    }
  }
  if ("implicit_subepochs" %in% names(data)) {
    implicit_subepochs <- data$implicit_subepochs
    if (
      !is.numeric(implicit_subepochs) ||
        anyNA(implicit_subepochs) ||
        any(
          !is.finite(implicit_subepochs) |
            implicit_subepochs < 0 |
            implicit_subepochs != as.integer(implicit_subepochs) |
            implicit_subepochs > source_subepochs
        )
    ) {
      abort_pipeline(
        "%s has invalid `implicit_subepochs` relative to source rows",
        object
      )
    }
  }
  if (
    all(
      c(
        "complete_subepoch_set",
        "distinct_subepochs",
        "expected_subepochs"
      ) %in%
        names(data)
    )
  ) {
    expected_complete <- data$distinct_subepochs == data$expected_subepochs
    if (
      !is.logical(data$complete_subepoch_set) ||
        anyNA(data$complete_subepoch_set) ||
        !identical(data$complete_subepoch_set, expected_complete)
    ) {
      abort_pipeline(
        "%s `complete_subepoch_set` is inconsistent with subepoch counts",
        object
      )
    }
  }

  consistency <- data |>
    dplyr::group_by(dplyr::across(dplyr::all_of(mder_support_day_key))) |>
    dplyr::summarise(
      timezones = dplyr::n_distinct(.data$timezone),
      eligibility_values = dplyr::n_distinct(.data$day_eligible),
      .groups = "drop"
    )
  if (
    any(consistency$timezones != 1L) ||
      any(consistency$eligibility_values != 1L)
  ) {
    abort_pipeline(
      "%s has participant-days with inconsistent timezone or eligibility",
      object
    )
  }
  invisible(data)
}

select_mder_pooled_map <- function(maps, placement, signal) {
  selected <- maps |>
    dplyr::filter(
      .data$profile_scope == "pooled",
      .data$profile_variant == "pooled",
      .data$placement == .env$placement,
      .data$state_domain == "full_day",
      .data$signal == .env$signal,
      .data$metric_map == "paired_channel_coverage"
    ) |>
    dplyr::arrange(.data$clock_bin)
  if (
    nrow(selected) != 48L ||
      !identical(
        as.integer(selected$clock_bin),
        seq.int(0L, 1410L, by = 30L)
      )
  ) {
    abort_pipeline(
      "The pooled %s paired-channel map is incomplete for `%s`",
      signal,
      placement
    )
  }
  selected
}

mder_weights_from_clock <- function(clock_minute, map) {
  bin <- floor(as.integer(clock_minute) / 30L) * 30L
  weight <- map$relevance_weight[match(bin, map$clock_bin)]
  if (
    anyNA(weight) ||
      any(!is.finite(weight) | weight < 0)
  ) {
    abort_pipeline(
      "A fixed paired-channel map did not cover every true clock minute"
    )
  }
  weight
}

mder_support_day_index <- function(data) {
  data |>
    dplyr::group_by(dplyr::across(dplyr::all_of(mder_support_day_key))) |>
    dplyr::summarise(
      timezone = mder_gate_single_value(
        .data$timezone,
        "timezone",
        "MDER participant-day"
      ),
      day_eligible = mder_gate_single_value(
        .data$day_eligible,
        "day_eligible",
        "MDER participant-day"
      ),
      .groups = "drop"
    ) |>
    dplyr::filter(.data$day_eligible) |>
    dplyr::arrange(
      .data$site,
      .data$Id,
      .data$position,
      .data$local_date
    )
}

mder_expected_pattern_support <- function(day_index, medi_map, light_map) {
  patterns <- day_index |>
    dplyr::distinct(.data$timezone, .data$local_date) |>
    dplyr::arrange(.data$timezone, .data$local_date) |>
    dplyr::mutate(pattern_id = sprintf("pattern_%06d", dplyr::row_number()))
  pattern_grid <- build_true_minute_day_grid(
    participant_days = dplyr::select(
      patterns,
      dplyr::all_of(c("pattern_id", "local_date", "timezone"))
    ),
    id_cols = "pattern_id",
    date_col = "local_date",
    timezone_col = "timezone",
    epoch_seconds = 60
  )
  pattern_grid$medi_profile_weight <- mder_weights_from_clock(
    pattern_grid$clock_minute,
    medi_map
  )
  pattern_grid$light_profile_weight <- mder_weights_from_clock(
    pattern_grid$clock_minute,
    light_map
  )
  expected <- pattern_grid |>
    dplyr::group_by(
      .data$pattern_id,
      .data$timezone,
      .data$local_date
    ) |>
    dplyr::summarise(
      expected_true_minutes = dplyr::n(),
      expected_medi_profile_mass = sum(.data$medi_profile_weight),
      expected_light_profile_mass = sum(.data$light_profile_weight),
      .groups = "drop"
    )
  if (
    any(
      expected$expected_true_minutes < 1380L |
        expected$expected_true_minutes > 1500L
    ) ||
      any(
        !is.finite(expected$expected_medi_profile_mass) |
          expected$expected_medi_profile_mass <= 0 |
          !is.finite(expected$expected_light_profile_mass) |
          expected$expected_light_profile_mass <= 0
      )
  ) {
    abort_pipeline("Could not establish expected true-minute profile support")
  }
  dplyr::select(expected, -dplyr::all_of("pattern_id"))
}

add_mder_candidate_retention <- function(
  daily,
  candidate_cutoffs = mder_support_candidate_cutoffs
) {
  candidate_cutoffs <- validate_mder_candidate_cutoffs(candidate_cutoffs)
  required <- c(
    mder_support_day_key,
    "ordinary_paired_coverage",
    "medi_paired_profile_coverage",
    "light_paired_profile_coverage",
    "positive_light_integral",
    "has_paired_observation"
  )
  assert_columns(daily, required, object = "daily MDER support diagnostics")
  if (
    !is.logical(daily$positive_light_integral) ||
      anyNA(daily$positive_light_integral)
  ) {
    abort_pipeline("`positive_light_integral` must be complete logical")
  }
  if (
    !is.logical(daily$has_paired_observation) ||
      anyNA(daily$has_paired_observation) ||
      any(
        daily$has_paired_observation !=
          (daily$paired_finite_medi_light_minutes > 0L)
      )
  ) {
    abort_pipeline(
      "`has_paired_observation` must match the paired finite-minute count"
    )
  }

  long <- tidyr::crossing(
    daily,
    candidate_support_cutoff = candidate_cutoffs
  ) |>
    dplyr::mutate(
      passes_ordinary_paired_support = is.finite(
        .data$ordinary_paired_coverage
      ) &
        .data$ordinary_paired_coverage >= .data$candidate_support_cutoff,
      passes_medi_profile_support = is.finite(
        .data$medi_paired_profile_coverage
      ) &
        .data$medi_paired_profile_coverage >= .data$candidate_support_cutoff,
      passes_light_profile_support = is.finite(
        .data$light_paired_profile_coverage
      ) &
        .data$light_paired_profile_coverage >= .data$candidate_support_cutoff,
      retained_at_candidate = .data$passes_ordinary_paired_support &
        .data$passes_medi_profile_support &
        .data$passes_light_profile_support &
        .data$positive_light_integral,
      below_any_support = .data$has_paired_observation &
        .data$positive_light_integral &
        !.data$retained_at_candidate,
      candidate_failure_reason = dplyr::case_when(
        !.data$has_paired_observation ~ "no_paired_observation",
        !.data$positive_light_integral ~ "nonpositive_paired_light_integral",
        !.data$passes_ordinary_paired_support ~ "below_ordinary_paired_support",
        !.data$passes_medi_profile_support ~ "below_medi_profile_support",
        !.data$passes_light_profile_support ~ "below_light_profile_support",
        TRUE ~ NA_character_
      ),
      status = "diagnostic_only_not_final",
      selection_rule = "ordinary_and_both_fixed_signal_profile_supports_gte_candidate_with_positive_paired_light_integral"
    ) |>
    dplyr::arrange(
      .data$position,
      .data$site,
      .data$Id,
      .data$local_date,
      .data$candidate_support_cutoff
    )
  long
}

summarise_mder_candidate_retention <- function(candidate_daily) {
  summary <- candidate_daily |>
    dplyr::group_by(
      .data$position,
      .data$candidate_support_cutoff
    ) |>
    dplyr::summarise(
      eligible_participant_days = dplyr::n(),
      eligible_participants = dplyr::n_distinct(.data$site, .data$Id),
      eligible_sites = dplyr::n_distinct(.data$site),
      participant_days_with_paired_minutes = sum(
        .data$paired_finite_medi_light_minutes > 0L
      ),
      participants_with_paired_minutes = dplyr::n_distinct(
        .data$site[.data$has_paired_observation],
        .data$Id[.data$has_paired_observation]
      ),
      participant_days_with_positive_light_integral = sum(
        .data$positive_light_integral
      ),
      retained_participant_days = sum(.data$retained_at_candidate),
      retained_participants = dplyr::n_distinct(
        .data$site[.data$retained_at_candidate],
        .data$Id[.data$retained_at_candidate]
      ),
      sites_with_retained_days = dplyr::n_distinct(
        .data$site[.data$retained_at_candidate]
      ),
      excluded_participant_days = sum(!.data$retained_at_candidate),
      no_paired_observation_days = sum(
        .data$paired_finite_medi_light_minutes == 0L
      ),
      nonpositive_paired_light_integral_days = sum(
        .data$paired_finite_medi_light_minutes > 0L &
          !.data$positive_light_integral
      ),
      below_ordinary_paired_support_days = sum(
        !.data$passes_ordinary_paired_support
      ),
      below_medi_profile_support_days = sum(
        !.data$passes_medi_profile_support
      ),
      below_light_profile_support_days = sum(
        !.data$passes_light_profile_support
      ),
      below_any_support_days = sum(.data$below_any_support),
      ordinary_paired_coverage_q10 = mder_finite_quantile(
        .data$ordinary_paired_coverage,
        0.10
      ),
      ordinary_paired_coverage_median = mder_finite_quantile(
        .data$ordinary_paired_coverage,
        0.50
      ),
      medi_profile_coverage_q10 = mder_finite_quantile(
        .data$medi_paired_profile_coverage,
        0.10
      ),
      medi_profile_coverage_median = mder_finite_quantile(
        .data$medi_paired_profile_coverage,
        0.50
      ),
      light_profile_coverage_q10 = mder_finite_quantile(
        .data$light_paired_profile_coverage,
        0.10
      ),
      light_profile_coverage_median = mder_finite_quantile(
        .data$light_paired_profile_coverage,
        0.50
      ),
      .groups = "drop"
    ) |>
    dplyr::group_by(.data$position) |>
    dplyr::arrange(.data$candidate_support_cutoff, .by_group = TRUE) |>
    dplyr::mutate(
      retained_fraction = .data$retained_participant_days /
        .data$eligible_participant_days,
      marginal_participant_day_loss_from_lower = dplyr::lag(
        .data$retained_participant_days
      ) -
        .data$retained_participant_days,
      marginal_participant_loss_from_lower = dplyr::lag(
        .data$retained_participants
      ) -
        .data$retained_participants,
      classification_total = .data$retained_participant_days +
        .data$no_paired_observation_days +
        .data$nonpositive_paired_light_integral_days +
        .data$below_any_support_days,
      status = "diagnostic_only_not_final",
      selection_rule = "candidate_cutoffs_fixed_without_result_preference"
    ) |>
    dplyr::ungroup() |>
    dplyr::arrange(
      .data$position,
      .data$candidate_support_cutoff
    )
  if (
    any(
      summary$classification_total != summary$eligible_participant_days
    )
  ) {
    abort_pipeline("MDER support candidate classifications do not reconcile")
  }
  summary
}

summarise_mder_candidate_retention_by_site <- function(candidate_daily) {
  summary <- candidate_daily |>
    dplyr::group_by(
      .data$position,
      .data$site,
      .data$candidate_support_cutoff
    ) |>
    dplyr::summarise(
      eligible_participant_days = dplyr::n(),
      eligible_participants = dplyr::n_distinct(.data$Id),
      participant_days_with_paired_minutes = sum(
        .data$has_paired_observation
      ),
      retained_participant_days = sum(.data$retained_at_candidate),
      retained_participants = dplyr::n_distinct(
        .data$Id[.data$retained_at_candidate]
      ),
      no_paired_observation_days = sum(
        !.data$has_paired_observation
      ),
      nonpositive_paired_light_integral_days = sum(
        .data$has_paired_observation &
          !.data$positive_light_integral
      ),
      below_any_support_days = sum(.data$below_any_support),
      ordinary_paired_coverage_median = mder_finite_quantile(
        .data$ordinary_paired_coverage,
        0.50
      ),
      medi_profile_coverage_median = mder_finite_quantile(
        .data$medi_paired_profile_coverage,
        0.50
      ),
      light_profile_coverage_median = mder_finite_quantile(
        .data$light_paired_profile_coverage,
        0.50
      ),
      .groups = "drop"
    ) |>
    dplyr::group_by(.data$position, .data$site) |>
    dplyr::arrange(.data$candidate_support_cutoff, .by_group = TRUE) |>
    dplyr::mutate(
      retained_fraction = .data$retained_participant_days /
        .data$eligible_participant_days,
      marginal_participant_day_loss_from_lower = dplyr::lag(
        .data$retained_participant_days
      ) -
        .data$retained_participant_days,
      classification_total = .data$retained_participant_days +
        .data$no_paired_observation_days +
        .data$nonpositive_paired_light_integral_days +
        .data$below_any_support_days,
      status = "diagnostic_only_not_final",
      selection_rule = "candidate_cutoffs_fixed_without_result_preference"
    ) |>
    dplyr::ungroup() |>
    dplyr::arrange(
      .data$position,
      .data$site,
      .data$candidate_support_cutoff
    )
  if (
    any(
      summary$classification_total != summary$eligible_participant_days
    )
  ) {
    abort_pipeline(
      "Site-stratified MDER support classifications do not reconcile"
    )
  }
  summary
}

summarise_mder_candidate_retention_by_participant <- function(
  candidate_daily
) {
  summary <- candidate_daily |>
    dplyr::group_by(
      .data$position,
      .data$site,
      .data$Id,
      .data$candidate_support_cutoff
    ) |>
    dplyr::summarise(
      eligible_participant_days = dplyr::n(),
      participant_days_with_paired_minutes = sum(
        .data$has_paired_observation
      ),
      retained_participant_days = sum(.data$retained_at_candidate),
      no_paired_observation_days = sum(
        !.data$has_paired_observation
      ),
      nonpositive_paired_light_integral_days = sum(
        .data$has_paired_observation &
          !.data$positive_light_integral
      ),
      below_any_support_days = sum(.data$below_any_support),
      ordinary_paired_coverage_median = mder_finite_quantile(
        .data$ordinary_paired_coverage,
        0.50
      ),
      medi_profile_coverage_median = mder_finite_quantile(
        .data$medi_paired_profile_coverage,
        0.50
      ),
      light_profile_coverage_median = mder_finite_quantile(
        .data$light_paired_profile_coverage,
        0.50
      ),
      .groups = "drop"
    ) |>
    dplyr::group_by(.data$position, .data$site, .data$Id) |>
    dplyr::arrange(.data$candidate_support_cutoff, .by_group = TRUE) |>
    dplyr::mutate(
      retained_fraction = .data$retained_participant_days /
        .data$eligible_participant_days,
      marginal_participant_day_loss_from_lower = dplyr::lag(
        .data$retained_participant_days
      ) -
        .data$retained_participant_days,
      classification_total = .data$retained_participant_days +
        .data$no_paired_observation_days +
        .data$nonpositive_paired_light_integral_days +
        .data$below_any_support_days,
      status = "diagnostic_only_not_final",
      selection_rule = "candidate_cutoffs_fixed_without_result_preference"
    ) |>
    dplyr::ungroup() |>
    dplyr::arrange(
      .data$position,
      .data$site,
      .data$Id,
      .data$candidate_support_cutoff
    )
  if (
    any(
      summary$classification_total != summary$eligible_participant_days
    )
  ) {
    abort_pipeline(
      "Participant-stratified MDER support classifications do not reconcile"
    )
  }
  summary
}

derive_mder_support_gate_diagnostics <- function(
  coverage,
  profiles,
  maps,
  placement,
  candidate_cutoffs = mder_support_candidate_cutoffs
) {
  candidate_cutoffs <- validate_mder_candidate_cutoffs(candidate_cutoffs)
  validate_mder_coverage_input(
    coverage,
    placement = placement,
    object = paste0(placement, " MDER support-gate coverage")
  )
  fixed <- validate_mder_fixed_profiles(
    profiles,
    maps,
    placements = placement
  )
  medi_map <- select_mder_pooled_map(fixed$maps, placement, "MEDI")
  light_map <- select_mder_pooled_map(fixed$maps, placement, "LIGHT")
  day_index <- mder_support_day_index(coverage)
  if (nrow(day_index) == 0L) {
    abort_pipeline("%s has no eligible participant-days", placement)
  }

  expected <- mder_expected_pattern_support(
    day_index,
    medi_map = medi_map,
    light_map = light_map
  )
  day_index <- dplyr::left_join(
    day_index,
    expected,
    by = c("timezone", "local_date"),
    relationship = "many-to-one"
  )
  eligible <- dplyr::semi_join(
    coverage,
    day_index,
    by = mder_support_day_key
  )
  eligible$medi_profile_weight <- mder_weights_from_clock(
    eligible$clock_minute,
    medi_map
  )
  eligible$light_profile_weight <- mder_weights_from_clock(
    eligible$clock_minute,
    light_map
  )
  eligible$paired_finite <- is.finite(eligible$MEDI_eligible) &
    is.finite(eligible$LIGHT_eligible)

  observed <- eligible |>
    dplyr::group_by(dplyr::across(dplyr::all_of(mder_support_day_key))) |>
    dplyr::summarise(
      finite_medi_minutes = sum(is.finite(.data$MEDI_eligible)),
      finite_light_minutes = sum(is.finite(.data$LIGHT_eligible)),
      paired_finite_medi_light_minutes = sum(.data$paired_finite),
      paired_medi_profile_mass = sum(
        dplyr::if_else(
          .data$paired_finite,
          .data$medi_profile_weight,
          0
        )
      ),
      paired_light_profile_mass = sum(
        dplyr::if_else(
          .data$paired_finite,
          .data$light_profile_weight,
          0
        )
      ),
      paired_light_integral_lx_h = if (any(.data$paired_finite)) {
        sum(.data$LIGHT_eligible[.data$paired_finite]) / 60
      } else {
        NA_real_
      },
      .groups = "drop"
    )
  daily <- dplyr::left_join(
    day_index,
    observed,
    by = mder_support_day_key,
    relationship = "one-to-one"
  ) |>
    dplyr::mutate(
      finite_medi_minutes = dplyr::coalesce(
        as.integer(.data$finite_medi_minutes),
        0L
      ),
      finite_light_minutes = dplyr::coalesce(
        as.integer(.data$finite_light_minutes),
        0L
      ),
      paired_finite_medi_light_minutes = dplyr::coalesce(
        as.integer(.data$paired_finite_medi_light_minutes),
        0L
      ),
      paired_medi_profile_mass = dplyr::coalesce(
        .data$paired_medi_profile_mass,
        0
      ),
      paired_light_profile_mass = dplyr::coalesce(
        .data$paired_light_profile_mass,
        0
      ),
      ordinary_paired_coverage = .data$paired_finite_medi_light_minutes /
        .data$expected_true_minutes,
      medi_paired_profile_coverage = .data$paired_medi_profile_mass /
        .data$expected_medi_profile_mass,
      light_paired_profile_coverage = .data$paired_light_profile_mass /
        .data$expected_light_profile_mass,
      positive_light_integral = is.finite(.data$paired_light_integral_lx_h) &
        .data$paired_light_integral_lx_h > 0,
      has_paired_observation = .data$paired_finite_medi_light_minutes > 0L,
      profile_variant = "pooled",
      support_role = "author_gate_input_only",
      ratio_value_calculated = FALSE,
      ratio_scaled_or_weighted = FALSE,
      failure_reason = dplyr::case_when(
        !.data$has_paired_observation ~ "no_paired_observation",
        !.data$positive_light_integral ~ "nonpositive_paired_light_integral",
        TRUE ~ NA_character_
      )
    ) |>
    dplyr::arrange(
      .data$site,
      .data$Id,
      .data$position,
      .data$local_date
    )
  if (
    any(
      daily$paired_finite_medi_light_minutes > daily$expected_true_minutes
    ) ||
      any(
        daily$ordinary_paired_coverage < 0 |
          daily$ordinary_paired_coverage > 1 |
          daily$medi_paired_profile_coverage < 0 |
          daily$medi_paired_profile_coverage > 1 |
          daily$light_paired_profile_coverage < 0 |
          daily$light_paired_profile_coverage > 1
      )
  ) {
    abort_pipeline("MDER support diagnostics fell outside their denominators")
  }

  candidate_daily <- add_mder_candidate_retention(
    daily,
    candidate_cutoffs = candidate_cutoffs
  )
  for (candidate_cutoff in candidate_cutoffs) {
    column <- mder_candidate_column(candidate_cutoff)
    selected <- candidate_daily[
      abs(candidate_daily$candidate_support_cutoff - candidate_cutoff) < 1e-12,
      ,
      drop = FALSE
    ]
    daily[[column]] <- selected$retained_at_candidate
  }
  output_columns <- c(
    mder_support_day_key,
    "timezone",
    "profile_variant",
    "expected_true_minutes",
    "finite_medi_minutes",
    "finite_light_minutes",
    "paired_finite_medi_light_minutes",
    "ordinary_paired_coverage",
    "medi_paired_profile_coverage",
    "light_paired_profile_coverage",
    "paired_light_integral_lx_h",
    "positive_light_integral",
    "has_paired_observation",
    vapply(candidate_cutoffs, mder_candidate_column, character(1)),
    "failure_reason",
    "support_role",
    "ratio_value_calculated",
    "ratio_scaled_or_weighted"
  )
  daily <- daily |>
    dplyr::select(dplyr::all_of(output_columns))
  assert_unique_key(
    daily,
    mder_support_day_key,
    object = paste0(placement, " daily MDER support diagnostics")
  )
  candidate_daily <- add_mder_candidate_retention(
    daily,
    candidate_cutoffs = candidate_cutoffs
  )
  list(
    daily = daily,
    candidate_daily = candidate_daily,
    candidate_summary = summarise_mder_candidate_retention(candidate_daily)
  )
}
