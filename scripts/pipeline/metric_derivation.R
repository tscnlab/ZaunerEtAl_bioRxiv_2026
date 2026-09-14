# Support-aware personal light-exposure metric derivation.

metric_day_key <- c("site", "Id", "position", "local_date")
metric_participant_key <- c("site", "Id", "position")
state_support_candidate_cutoffs <- c(0.70, 0.80, 0.90)
mder_primary_viable_fraction <- 0.50
mder_metric_failure_reasons <- c(
  "no_viable_momentary_ratio",
  "below_viable_ratio_fraction"
)
numerical_zero_decision_id <- "METRIC-011"
numerical_zero_rule <- paste0(
  "normalize_to_zero_only_if_abs(raw_backtransform)<=",
  "100*.Machine$double.eps*max(1,abs(shifted_mean),abs(zero_offset))",
  "_and_source_values_are_all_exact_zero;",
  "within-tolerance_negative_domain_roundoff_is_also_zero"
)

validate_state_support_candidate_cutoffs <- function(
  candidate_cutoffs = state_support_candidate_cutoffs
) {
  if (
    !is.numeric(candidate_cutoffs) ||
      anyNA(candidate_cutoffs) ||
      any(!is.finite(candidate_cutoffs)) ||
      any(candidate_cutoffs < 0 | candidate_cutoffs > 1)
  ) {
    abort_pipeline(
      "State-support candidate cutoffs must be finite values in [0, 1]"
    )
  }
  candidate_cutoffs <- sort(unique(as.numeric(candidate_cutoffs)))
  if (
    length(candidate_cutoffs) != length(state_support_candidate_cutoffs) ||
      !isTRUE(all.equal(
        candidate_cutoffs,
        state_support_candidate_cutoffs,
        tolerance = 1e-12
      ))
  ) {
    abort_pipeline(
      "The cutoff-neutral state-support gate is fixed at 0.70, 0.80, and 0.90"
    )
  }
  candidate_cutoffs
}

validate_mder_viable_fraction <- function(minimum_mder_viable_fraction) {
  validate_fraction(
    minimum_mder_viable_fraction,
    "minimum_mder_viable_fraction"
  )
  if (
    length(minimum_mder_viable_fraction) != 1L ||
      is.na(minimum_mder_viable_fraction)
  ) {
    abort_pipeline(
      "`minimum_mder_viable_fraction` must be one value in [0, 1]"
    )
  }
  as.numeric(minimum_mder_viable_fraction)
}

measurement_construct_for_placement <- function(placement) {
  if (
    !is.character(placement) ||
      length(placement) != 1L ||
      is.na(placement) ||
      !nzchar(trimws(placement))
  ) {
    abort_pipeline("`placement` must be one non-empty character value")
  }
  switch(
    trimws(placement),
    glasses = "hybrid_near_eye_wake_and_bedside_sleep_environment",
    chest = "hybrid_chest_level_wake_and_bedside_sleep_environment",
    paste0(
      "hybrid_",
      gsub("[^a-z0-9]+", "_", tolower(trimws(placement))),
      "_wake_and_bedside_sleep_environment"
    )
  )
}

single_complete_value <- function(value, name, object) {
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

single_character_or_mixed <- function(value) {
  observed <- sort(unique(as.character(value[!is.na(value)])))
  if (length(observed) == 0L) {
    return(NA_character_)
  }
  if (length(observed) == 1L) {
    return(observed[[1L]])
  }
  paste(observed, collapse = "|")
}

finite_mean_metric <- function(value) {
  finite <- is.finite(value)
  if (!any(finite)) {
    return(NA_real_)
  }
  mean(value[finite])
}

finite_min_metric <- function(value) {
  finite <- is.finite(value)
  if (!any(finite)) {
    return(NA_real_)
  }
  min(value[finite])
}

finite_quantile_metric <- function(value, probability) {
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

new_numerical_zero_audit_record <- function(
  key,
  metric,
  analysis_unit,
  backtransform,
  zero_offset,
  source_valid_minutes,
  source_zero_minutes,
  source_positive_minutes,
  source_missing_minutes,
  source_real_minutes = source_valid_minutes + source_missing_minutes,
  source_valid_real_minutes = source_valid_minutes,
  clock_hour = NA_integer_,
  window_start_clock_minute = NA_integer_,
  window_end_clock_minute = NA_integer_,
  window_wraps_midnight = NA
) {
  if (!is.data.frame(key) || nrow(key) != 1L) {
    abort_pipeline("Numerical-zero audit keys must contain exactly one row")
  }
  required_details <- c(
    "value",
    "raw_value",
    "shifted_mean",
    "tolerance",
    "source_all_zero",
    "numerical_zero_reclassified",
    "numerical_zero_reason"
  )
  if (!all(required_details %in% names(backtransform))) {
    abort_pipeline("Numerical-zero backtransform details are incomplete")
  }
  out <- dplyr::bind_cols(
    key,
    tibble::tibble(
      metric = metric,
      analysis_unit = analysis_unit,
      units = "lx",
      clock_hour = as.integer(clock_hour),
      window_start_clock_minute = as.integer(window_start_clock_minute),
      window_end_clock_minute = as.integer(window_end_clock_minute),
      window_wraps_midnight = as.logical(window_wraps_midnight),
      raw_backtransformed_value_lx = backtransform$raw_value,
      normalized_value_lx = backtransform$value,
      shifted_mean_lx = backtransform$shifted_mean,
      numerical_zero_tolerance_lx = backtransform$tolerance,
      zero_offset_lx = zero_offset,
      source_all_zero = backtransform$source_all_zero,
      source_valid_minutes = as.integer(source_valid_minutes),
      source_zero_minutes = as.integer(source_zero_minutes),
      source_positive_minutes = as.integer(source_positive_minutes),
      source_missing_minutes = as.integer(source_missing_minutes),
      source_real_minutes = as.integer(source_real_minutes),
      source_valid_real_minutes = as.integer(source_valid_real_minutes),
      numerical_zero_decision_id = numerical_zero_decision_id,
      numerical_zero_rule = numerical_zero_rule,
      numerical_zero_reason = backtransform$numerical_zero_reason,
      raw_value_preserved = TRUE
    )
  )
  if (!isTRUE(backtransform$numerical_zero_reclassified)) {
    out <- out[FALSE, , drop = FALSE]
  }
  out
}

validate_metric_coverage_input <- function(
  data,
  placement,
  object = deparse(substitute(data))
) {
  if (!is.data.frame(data)) {
    abort_pipeline("%s must be a data frame", object)
  }
  required <- c(
    metric_day_key,
    "timezone",
    "datetime_utc",
    "datetime_wall",
    "clock_minute",
    "utc_offset_minutes",
    "is_dst",
    "day_eligible",
    "MEDI_eligible",
    "LIGHT_eligible",
    "source_subepochs",
    metric_state_comparison_columns
  )
  assert_columns(data, required, object = object)
  assert_no_missing_key(
    data,
    c(metric_participant_key, "datetime_utc", "local_date", "clock_minute"),
    object = object
  )
  assert_unique_key(
    data,
    c(metric_participant_key, "datetime_utc"),
    object = object
  )
  if (
    !inherits(data$datetime_utc, "POSIXct") ||
      !inherits(data$datetime_wall, "POSIXct") ||
      !inherits(data$local_date, "Date")
  ) {
    abort_pipeline(
      "%s must retain POSIXct time axes and a Date local-day key",
      object
    )
  }
  if (
    !identical(lubridate::tz(data$datetime_utc), "UTC") ||
      !identical(lubridate::tz(data$datetime_wall), "UTC")
  ) {
    abort_pipeline(
      "%s true and pseudo-local time axes must use UTC storage",
      object
    )
  }
  if (any(as.character(data$position) != placement)) {
    abort_pipeline(
      "%s contains a placement other than `%s`",
      object,
      placement
    )
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
    abort_pipeline("%s has invalid local clock minutes", object)
  }
  if (
    !is.logical(data$day_eligible) ||
      anyNA(data$day_eligible)
  ) {
    abort_pipeline("%s `day_eligible` must be complete logical", object)
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
  if (
    !is.numeric(data$source_subepochs) ||
      anyNA(data$source_subepochs) ||
      any(
        !is.finite(data$source_subepochs) |
          data$source_subepochs < 0 |
          data$source_subepochs != as.integer(data$source_subepochs)
      )
  ) {
    abort_pipeline(
      "%s `source_subepochs` must contain complete non-negative integers",
      object
    )
  }
  if (
    any(
      data$source_subepochs == 0L &
        (is.finite(data$MEDI_eligible) |
          is.finite(data$LIGHT_eligible))
    )
  ) {
    abort_pipeline(
      "%s has eligible light values on source-absent minutes",
      object
    )
  }
  allowed_states <- c("wake", "pre-sleep", "sleep")
  invalid_states <- unique(as.character(data$State.Brown))
  invalid_states <- invalid_states[
    !is.na(invalid_states) & !invalid_states %in% allowed_states
  ]
  if (length(invalid_states) > 0L) {
    abort_pipeline(
      "%s contains unknown diary state(s): %s",
      object,
      paste(sort(invalid_states), collapse = ", ")
    )
  }

  day_consistency <- data |>
    dplyr::group_by(dplyr::across(dplyr::all_of(metric_day_key))) |>
    dplyr::summarise(
      timezones = dplyr::n_distinct(.data$timezone),
      eligibility_values = dplyr::n_distinct(.data$day_eligible),
      .groups = "drop"
    )
  if (
    any(day_consistency$timezones != 1L) ||
      any(day_consistency$eligibility_values != 1L)
  ) {
    abort_pipeline(
      "%s has participant-days with inconsistent timezone or eligibility",
      object
    )
  }
  invalid_timezones <- !unique(data$timezone) %in% OlsonNames()
  if (any(invalid_timezones)) {
    abort_pipeline(
      "%s contains invalid time zone(s): %s",
      object,
      paste(sort(unique(data$timezone)[invalid_timezones]), collapse = ", ")
    )
  }
  invisible(data)
}

profile_variant_for_site <- function(profile_variant, site) {
  if (
    !is.character(profile_variant) ||
      length(profile_variant) != 1L ||
      is.na(profile_variant) ||
      !nzchar(profile_variant)
  ) {
    abort_pipeline("`profile_variant` must be one non-empty value")
  }
  switch(
    profile_variant,
    pooled = "pooled",
    site_specific = paste0("site::", site),
    leave_one_site_out = paste0("leave_one_site_out::", site),
    profile_variant
  )
}

validate_fixed_metric_profiles <- function(
  profiles,
  maps,
  distribution_profiles = NULL,
  tolerance = 1e-12
) {
  profile_columns <- c(
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
    "relevance_weight",
    "map_estimable",
    "relevance_source"
  )
  assert_columns(profiles, profile_columns, object = "fixed profiles")
  assert_columns(maps, map_columns, object = "fixed relevance maps")
  if (
    any(profiles$clock_bin < 0L | profiles$clock_bin > 1410L) ||
      any(profiles$clock_bin %% 30L != 0L) ||
      any(maps$clock_bin < 0L | maps$clock_bin > 1410L) ||
      any(maps$clock_bin %% 30L != 0L)
  ) {
    abort_pipeline("Fixed profiles must use the complete 30-minute clock grid")
  }
  if (any(grepl("L5", c(names(profiles), names(maps)), fixed = TRUE))) {
    abort_pipeline("An excluded darkest-five-hour label entered profile inputs")
  }
  if (any(as.character(maps$metric_map) == "L5")) {
    abort_pipeline("An excluded darkest-five-hour map entered metric inputs")
  }
  timing_maps <- maps |>
    dplyr::filter(.data$metric_map == "timing_above_250")
  if (
    nrow(timing_maps) == 0L ||
      any(as.character(timing_maps$state_domain) != "full_day") ||
      any(toupper(as.character(timing_maps$signal)) != "MEDI") ||
      any(
        timing_maps$relevance_source !=
          "participant_balanced_exceedance_distribution"
      )
  ) {
    abort_pipeline(
      paste0(
        "Timing-above-250 support must come from the full-day MEDI ",
        "participant-balanced exceedance distribution"
      )
    )
  }
  if (!is.null(distribution_profiles)) {
    validate_exceedance_distribution_profiles(distribution_profiles)
    alignment_columns <- c(
      "profile_scope",
      "profile_variant",
      "profile_site",
      "held_out_site",
      "placement",
      "state_domain",
      "signal",
      "clock_bin"
    )
    assert_columns(
      timing_maps,
      c(
        alignment_columns,
        "exceedance_probability",
        "relevance_mass",
        "relevance_weight"
      ),
      object = "timing-above-250 relevance maps"
    )
    aligned <- timing_maps |>
      dplyr::select(dplyr::all_of(c(
        alignment_columns,
        "exceedance_probability",
        "relevance_mass",
        "relevance_weight"
      ))) |>
      dplyr::left_join(
        distribution_profiles |>
          dplyr::select(dplyr::all_of(c(
            alignment_columns,
            "exceedance_probability",
            "supported_exceedance_probability",
            "probability_weight"
          ))) |>
          dplyr::mutate(.distribution_row = TRUE),
        by = alignment_columns,
        suffix = c("_map", "_distribution"),
        na_matches = "na",
        relationship = "one-to-one"
      )
    if (
      nrow(aligned) != nrow(distribution_profiles) ||
        anyNA(aligned$.distribution_row) ||
        !isTRUE(all.equal(
          aligned$exceedance_probability_map,
          aligned$exceedance_probability_distribution,
          tolerance = tolerance,
          check.attributes = FALSE
        )) ||
        !isTRUE(all.equal(
          aligned$relevance_mass,
          aligned$supported_exceedance_probability,
          tolerance = tolerance,
          check.attributes = FALSE
        )) ||
        !isTRUE(all.equal(
          aligned$relevance_weight,
          aligned$probability_weight,
          tolerance = tolerance,
          check.attributes = FALSE
        ))
    ) {
      abort_pipeline(
        paste0(
          "Timing-above-250 maps do not exactly reproduce the fixed ",
          "exceedance-distribution artifact"
        )
      )
    }
  }
  invisible(TRUE)
}

select_fixed_profile <- function(
  profiles,
  placement,
  site,
  state_domain,
  signal,
  profile_variant
) {
  variant <- profile_variant_for_site(profile_variant, site)
  selected <- profiles |>
    dplyr::filter(
      .data$profile_variant == .env$variant,
      .data$placement == .env$placement,
      .data$state_domain == .env$state_domain,
      .data$signal == .env$signal
    ) |>
    dplyr::arrange(.data$clock_bin)
  if (
    nrow(selected) != 48L ||
      !identical(as.integer(selected$clock_bin), seq.int(0L, 1410L, by = 30L))
  ) {
    abort_pipeline(
      paste0(
        "Fixed profile `%s` is incomplete for %s/%s/%s/%s; ",
        "expected 48 ordered bins"
      ),
      variant,
      placement,
      site,
      state_domain,
      signal
    )
  }
  selected
}

select_fixed_map <- function(
  maps,
  placement,
  site,
  state_domain,
  signal,
  metric_map,
  profile_variant
) {
  variant <- profile_variant_for_site(profile_variant, site)
  selected <- maps |>
    dplyr::filter(
      .data$profile_variant == .env$variant,
      .data$placement == .env$placement,
      .data$state_domain == .env$state_domain,
      .data$signal == .env$signal,
      .data$metric_map == .env$metric_map
    ) |>
    dplyr::arrange(.data$clock_bin)
  if (
    nrow(selected) != 48L ||
      !identical(as.integer(selected$clock_bin), seq.int(0L, 1410L, by = 30L))
  ) {
    abort_pipeline(
      paste0(
        "Fixed relevance map `%s` is incomplete for %s/%s/%s/%s/%s; ",
        "expected 48 ordered bins"
      ),
      variant,
      placement,
      site,
      state_domain,
      signal,
      metric_map
    )
  }
  selected
}

weights_from_clock_bins <- function(clock_minute, profile, column) {
  assert_columns(profile, c("clock_bin", column), object = "profile weights")
  bin <- floor(as.integer(clock_minute) / 30L) * 30L
  profile[[column]][match(bin, profile$clock_bin)]
}

profile_coverage_supported_bins <- function(observed_fraction, weight) {
  validate_equal_lengths(
    observed_fraction,
    weight,
    .names = c("observed_fraction", "weight")
  )
  observed_fraction <- validate_fraction(
    observed_fraction,
    "observed_fraction"
  )
  supported <- is.finite(weight) & weight >= 0
  if (!any(supported) || sum(weight[supported]) <= 0) {
    return(NA_real_)
  }
  sum(weight[supported] * observed_fraction[supported]) /
    sum(weight[supported])
}

metric_participant_day_index <- function(data) {
  data |>
    dplyr::group_by(dplyr::across(dplyr::all_of(metric_day_key))) |>
    dplyr::summarise(
      timezone = single_complete_value(
        .data$timezone,
        "timezone",
        "coverage participant-day"
      ),
      day_eligible = single_complete_value(
        .data$day_eligible,
        "day_eligible",
        "coverage participant-day"
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

build_complete_metric_grid <- function(
  data,
  state_intervals,
  placement,
  object = deparse(substitute(data))
) {
  validate_metric_coverage_input(data, placement = placement, object = object)
  participant_days <- metric_participant_day_index(data)
  if (nrow(participant_days) == 0L) {
    abort_pipeline("%s contains no eligible participant-days", object)
  }
  grid <- build_true_minute_day_grid(
    participant_days = dplyr::select(
      participant_days,
      dplyr::all_of(c(metric_day_key, "timezone"))
    ),
    id_cols = metric_participant_key,
    date_col = "local_date",
    timezone_col = "timezone",
    epoch_seconds = 60
  )
  projected_state <- project_metric_state_context(
    grid,
    state_intervals = state_intervals,
    placement = placement,
    object = "complete true-minute metric grid"
  )
  grid <- left_join_checked(
    grid,
    projected_state,
    by = c(metric_participant_key, "datetime_utc"),
    relationship = "one-to-one",
    x_name = "complete true-minute metric grid",
    y_name = "canonical state-interval projection"
  )

  eligible_source <- data |>
    dplyr::semi_join(
      participant_days,
      by = metric_day_key
    )
  context_candidates <- c(
    "MEDI_eligible",
    "LIGHT_eligible",
    "source_subepochs",
    metric_state_comparison_columns,
    "medi_saturated",
    "source_modality",
    "source_commit",
    "source_sha256"
  )
  source_columns <- unique(c(
    metric_participant_key,
    "datetime_utc",
    intersect(context_candidates, names(eligible_source))
  ))
  source_minute <- dplyr::select(
    eligible_source,
    dplyr::all_of(source_columns)
  )
  source_minute$coverage_minute_present <- TRUE
  source_minute$source_minute_present <- source_minute$source_subepochs > 0L
  for (column in metric_state_comparison_columns) {
    names(source_minute)[names(source_minute) == column] <-
      paste0("source_", column)
  }
  grid <- left_join_checked(
    grid,
    source_minute,
    by = c(metric_participant_key, "datetime_utc"),
    relationship = "one-to-one",
    x_name = "complete true-minute metric grid",
    y_name = "coverage-eligible true minutes"
  )
  grid$coverage_minute_present <- dplyr::coalesce(
    grid$coverage_minute_present,
    FALSE
  )
  grid$source_minute_present <- dplyr::coalesce(
    grid$source_minute_present,
    FALSE
  )
  if (sum(grid$coverage_minute_present) != nrow(eligible_source)) {
    abort_pipeline(
      "%s did not reconcile coverage rows to the true-minute grid",
      object
    )
  }
  assert_source_state_projection_match(grid)
  grid <- dplyr::select(
    grid,
    -dplyr::all_of(paste0("source_", metric_state_comparison_columns))
  )
  grid$fold_size <- ave(
    grid$clock_minute,
    grid$site,
    grid$Id,
    grid$position,
    grid$local_date,
    grid$clock_minute,
    FUN = length
  )
  grid$fold_occurrence <- ave(
    as.numeric(grid$datetime_utc),
    grid$site,
    grid$Id,
    grid$position,
    grid$local_date,
    grid$clock_minute,
    FUN = function(value) rank(value, ties.method = "first")
  )
  grid$dst_fold <- grid$fold_size > 1L
  grid <- grid |>
    dplyr::arrange(
      .data$site,
      .data$Id,
      .data$position,
      .data$datetime_utc
    )
  assert_unique_key(
    grid,
    c(metric_participant_key, "datetime_utc"),
    object = "complete true-minute metric grid"
  )
  grid
}

collapse_metric_wall_minutes <- function(day_grid) {
  assert_columns(
    day_grid,
    c(
      metric_day_key,
      "datetime_utc",
      "datetime_wall",
      "clock_minute",
      "source_minute_present",
      "MEDI_eligible",
      "LIGHT_eligible",
      "State.Brown",
      "dst_fold"
    ),
    object = "participant-day true-minute grid"
  )
  key_values <- day_grid[1L, metric_day_key, drop = FALSE]
  observed <- day_grid |>
    dplyr::group_by(.data$clock_minute) |>
    dplyr::summarise(
      source_real_minutes = dplyr::n(),
      source_observed_real_minutes = sum(.data$source_minute_present),
      finite_medi_real_minutes = sum(is.finite(.data$MEDI_eligible)),
      finite_light_real_minutes = sum(is.finite(.data$LIGHT_eligible)),
      MEDI = finite_mean_metric(.data$MEDI_eligible),
      LIGHT = finite_mean_metric(.data$LIGHT_eligible),
      diary_state = single_character_or_mixed(.data$State.Brown),
      measurement_context = if ("measurement_context" %in% names(day_grid)) {
        single_character_or_mixed(.data$measurement_context)
      } else {
        NA_character_
      },
      dst_fold = any(.data$dst_fold),
      utc_offsets = paste(
        sort(unique(.data$utc_offset_minutes)),
        collapse = "|"
      ),
      .groups = "drop"
    )
  wall <- tibble::tibble(clock_minute = 0:1439) |>
    dplyr::left_join(observed, by = "clock_minute", relationship = "one-to-one")
  wall <- dplyr::bind_cols(
    key_values[rep(1L, 1440L), , drop = FALSE],
    wall
  )
  wall$datetime_wall <- as.POSIXct(wall$local_date, tz = "UTC") +
    wall$clock_minute * 60
  for (column in c(
    "source_real_minutes",
    "source_observed_real_minutes",
    "finite_medi_real_minutes",
    "finite_light_real_minutes"
  )) {
    wall[[column]] <- dplyr::coalesce(as.integer(wall[[column]]), 0L)
  }
  wall$dst_fold <- dplyr::coalesce(wall$dst_fold, FALSE)
  wall$utc_offsets <- dplyr::coalesce(wall$utc_offsets, "")
  wall$wall_minute_exists <- wall$source_real_minutes > 0L
  wall$MEDI_observed <- is.finite(wall$MEDI)
  wall$LIGHT_observed <- is.finite(wall$LIGHT)
  assert_unique_key(
    wall,
    c(metric_day_key, "clock_minute"),
    object = "complete participant-day wall-minute grid"
  )
  wall
}

aggregate_clock_outcome <- function(
  wall,
  bin_minutes,
  minimum_valid_minutes,
  outcome = c("arithmetic", "zero_aware_geometric"),
  zero_offset = 0.1
) {
  outcome <- match.arg(outcome)
  if (
    length(bin_minutes) != 1L ||
      !is.finite(bin_minutes) ||
      bin_minutes < 1L ||
      1440L %% bin_minutes != 0L
  ) {
    abort_pipeline("`bin_minutes` must be a positive divisor of 1440")
  }
  if (
    length(minimum_valid_minutes) != 1L ||
      !is.finite(minimum_valid_minutes) ||
      minimum_valid_minutes < 1L ||
      minimum_valid_minutes > bin_minutes
  ) {
    abort_pipeline("`minimum_valid_minutes` is outside the bin")
  }
  wall$bin_start_clock_minute <-
    floor(wall$clock_minute / bin_minutes) * bin_minutes
  grouped <- wall |>
    dplyr::group_by(
      dplyr::across(dplyr::all_of(metric_day_key)),
      .data$bin_start_clock_minute
    ) |>
    dplyr::summarise(
      expected_wall_minutes = as.integer(bin_minutes),
      wall_minutes_existing = sum(.data$wall_minute_exists),
      source_real_minutes = sum(.data$source_real_minutes),
      source_observed_real_minutes = sum(.data$source_observed_real_minutes),
      dst_fold_wall_minutes = sum(.data$dst_fold),
      valid_medi_wall_minutes = sum(is.finite(.data$MEDI)),
      zero_medi_wall_minutes = sum(
        is.finite(.data$MEDI) & .data$MEDI == 0
      ),
      positive_medi_wall_minutes = sum(
        is.finite(.data$MEDI) & .data$MEDI > 0
      ),
      valid_light_wall_minutes = sum(is.finite(.data$LIGHT)),
      diary_state_composition = single_character_or_mixed(.data$diary_state),
      diary_state_categories = dplyr::n_distinct(
        .data$diary_state,
        na.rm = TRUE
      ),
      missing_diary_state_wall_minutes = sum(is.na(.data$diary_state)),
      measurement_context_composition = single_character_or_mixed(
        .data$measurement_context
      ),
      measurement_context_categories = dplyr::n_distinct(
        .data$measurement_context,
        na.rm = TRUE
      ),
      arithmetic_mean_medi_lx = finite_mean_metric(.data$MEDI),
      zero_aware_log_mean_medi = if (any(is.finite(.data$MEDI))) {
        mean(log10(.data$MEDI[is.finite(.data$MEDI)] + zero_offset))
      } else {
        NA_real_
      },
      zero_aware_source_all_zero = any(is.finite(.data$MEDI)) &&
        all(.data$MEDI[is.finite(.data$MEDI)] == 0),
      .groups = "drop"
    )
  geometric_details <- purrr::map2(
    grouped$zero_aware_log_mean_medi,
    grouped$zero_aware_source_all_zero,
    function(log_mean, source_all_zero) {
      if (!is.finite(log_mean)) {
        return(NULL)
      }
      geometric_mean_backtransform_details(
        log_mean = log_mean,
        zero_offset = zero_offset,
        source_all_zero = source_all_zero
      )
    }
  )
  detail_value <- function(name, default = NA_real_) {
    vapply(
      geometric_details,
      function(details) {
        if (is.null(details)) default else details[[name]]
      },
      if (is.logical(default)) logical(1) else if (is.character(default)) {
        character(1)
      } else {
        numeric(1)
      }
    )
  }
  grouped$zero_aware_geometric_mean_medi_lx <- detail_value("value")
  grouped$.numerical_zero_raw_value_lx <- detail_value("raw_value")
  grouped$.numerical_zero_shifted_mean_lx <- detail_value("shifted_mean")
  grouped$.numerical_zero_tolerance_lx <- detail_value("tolerance")
  grouped$.numerical_zero_reclassified <- detail_value(
    "numerical_zero_reclassified",
    FALSE
  )
  grouped$.numerical_zero_reason <- detail_value(
    "numerical_zero_reason",
    NA_character_
  )
  grouped <- grouped |>
    dplyr::mutate(
      ordinary_support = .data$valid_medi_wall_minutes /
        .data$expected_wall_minutes,
      bin_admissible = .data$valid_medi_wall_minutes >= minimum_valid_minutes,
      failure_reason = dplyr::if_else(
        .data$bin_admissible,
        NA_character_,
        "insufficient_bin_support"
      ),
      spans_diary_state_boundary = .data$diary_state_categories > 1L,
      spans_measurement_context_boundary = .data$measurement_context_categories >
        1L
    )
  value_column <- if (outcome == "arithmetic") {
    "arithmetic_mean_medi_lx"
  } else {
    "zero_aware_geometric_mean_medi_lx"
  }
  grouped$metric_value_lx <- ifelse(
    grouped$bin_admissible,
    grouped[[value_column]],
    NA_real_
  )
  grouped$metric <- if (outcome == "arithmetic") {
    "30_minute_arithmetic_mean_medi"
  } else {
    "one_hour_zero_aware_geometric_mean_medi"
  }
  grouped$zero_offset <- zero_offset
  grouped
}

longest_bout_with_censoring <- function(
  value,
  datetime,
  segment,
  threshold = 250,
  interval_seconds = 60
) {
  validate_datetime_axis(datetime)
  validate_equal_lengths(
    value,
    datetime,
    segment,
    .names = c("value", "datetime", "segment")
  )
  validate_positive_scalar(interval_seconds, "interval_seconds")
  if (length(value) == 0L) {
    stop("Bout inputs must not be empty", call. = FALSE)
  }

  order_rows <- order(datetime)
  value <- value[order_rows]
  datetime <- datetime[order_rows]
  segment <- segment[order_rows]
  qualifies <- is.finite(value) & value > threshold
  unknown <- !is.finite(value)
  connected_to_previous <- c(
    FALSE,
    abs(diff(as.numeric(datetime)) - interval_seconds) <= 1e-6 &
      !is.na(segment[-1L]) &
      !is.na(segment[-length(segment)]) &
      segment[-1L] == segment[-length(segment)]
  )

  contiguous_run_table <- function(member) {
    run_start <- member &
      !c(FALSE, member[-length(member)]) |
      member & !connected_to_previous
    run_id <- cumsum(run_start)
    index_groups <- split(which(member), run_id[member])
    if (length(index_groups) == 0L) {
      return(tibble::tibble(
        start = integer(),
        end = integer(),
        duration_seconds = numeric()
      ))
    }
    purrr::map_dfr(index_groups, function(index) {
      tibble::tibble(
        start = min(index),
        end = max(index),
        duration_seconds = length(index) * interval_seconds
      )
    })
  }

  observed_runs <- contiguous_run_table(qualifies)
  possible_runs <- contiguous_run_table(qualifies | unknown)
  longest_observed <- if (nrow(observed_runs) > 0L) {
    max(observed_runs$duration_seconds)
  } else {
    0
  }
  longest_possible <- if (nrow(possible_runs) > 0L) {
    max(possible_runs$duration_seconds)
  } else {
    0
  }
  not_exactly_identifiable <- longest_possible > longest_observed
  winning <- observed_runs[
    observed_runs$duration_seconds == longest_observed &
      longest_observed > 0,
    ,
    drop = FALSE
  ]
  selected_winner <- if (nrow(winning) > 0L) {
    winning[order(winning$start, winning$end)[1L], , drop = FALSE]
  } else {
    NULL
  }
  selected_winner_boundary_contact <- !is.null(selected_winner) &&
    (
      selected_winner$start[[1L]] == 1L ||
        selected_winner$end[[1L]] == length(value)
    )
  any_winning_run_boundary_contact <- nrow(winning) > 0L &&
    any(winning$start == 1L | winning$end == length(value))
  missing_datetime <- as.POSIXct(
    NA_real_,
    origin = "1970-01-01",
    tz = lubridate::tz(datetime)
  )
  winner_onset <- if (is.null(selected_winner)) {
    missing_datetime
  } else {
    datetime[selected_winner$start]
  }
  winner_offset <- if (is.null(selected_winner)) {
    missing_datetime
  } else {
    datetime[selected_winner$end] + interval_seconds
  }
  censor_reason <- if (not_exactly_identifiable) {
    "missing_or_invalid_minutes_allow_longer_bout"
  } else {
    NA_character_
  }
  tibble::tibble(
    longest_observed_seconds = longest_observed,
    longest_observed_lower_bound_seconds = longest_observed,
    longest_possible_seconds = longest_possible,
    longest_possible_upper_bound_seconds = longest_possible,
    longest_exact_identifiable_seconds = if (not_exactly_identifiable) {
      NA_real_
    } else {
      longest_observed
    },
    longest_reported_seconds = longest_observed,
    qualifying_runs = nrow(observed_runs),
    possible_runs = nrow(possible_runs),
    winning_observed_runs = nrow(winning),
    winner_onset_utc = winner_onset,
    winner_offset_utc = winner_offset,
    winner_selection_rule = "earliest_onset_then_earliest_offset",
    winner_day_boundary_contact = selected_winner_boundary_contact,
    any_winning_observed_run_day_boundary_contact =
      any_winning_run_boundary_contact,
    missing_invalid_breaks_observed_runs = TRUE,
    observed_value_interpretation = "observed_lower_bound",
    possible_bound_interpretation = "upper_bound_if_all_missing_or_invalid_minutes_qualified",
    exact_identifiable = !not_exactly_identifiable,
    longest_run_censored = not_exactly_identifiable,
    censor_reason = censor_reason,
    estimable = TRUE,
    failure_reason = NA_character_,
    exact_failure_reason = if (not_exactly_identifiable) {
      "not_exactly_identifiable_due_to_missing_or_invalid_minutes"
    } else {
      NA_character_
    }
  )
}

state_threshold_duration <- function(
  day_grid,
  state,
  threshold,
  comparison,
  state_profile_weight,
  minimum_state_support
) {
  unknown_diary_state_minutes <- sum(is.na(day_grid$State.Brown))
  state_rows <- !is.na(day_grid$State.Brown) &
    day_grid$State.Brown == state
  state_minutes <- sum(state_rows)
  if (unknown_diary_state_minutes > 0L) {
    valid_state_minutes <- sum(
      state_rows & is.finite(day_grid$MEDI_eligible)
    )
    return(tibble::tibble(
      duration_hours = NA_real_,
      state_minutes = state_minutes,
      valid_state_minutes = valid_state_minutes,
      unknown_diary_state_minutes = unknown_diary_state_minutes,
      state_domain_complete = FALSE,
      ordinary_state_support = if (state_minutes > 0L) {
        valid_state_minutes / state_minutes
      } else {
        NA_real_
      },
      profile_state_support = NA_real_,
      estimable = FALSE,
      failure_reason = "incomplete_state_domain"
    ))
  }
  if (state_minutes == 0L) {
    return(tibble::tibble(
      duration_hours = NA_real_,
      state_minutes = 0L,
      valid_state_minutes = 0L,
      unknown_diary_state_minutes = 0L,
      state_domain_complete = TRUE,
      ordinary_state_support = NA_real_,
      profile_state_support = NA_real_,
      estimable = FALSE,
      failure_reason = "no_state_window"
    ))
  }
  valid <- state_rows & is.finite(day_grid$MEDI_eligible)
  valid_state_minutes <- sum(valid)
  ordinary_support <- valid_state_minutes / state_minutes
  profile_support <- profile_coverage_supported_bins(
    observed_fraction = as.numeric(valid),
    weight = state_profile_weight
  )
  if (ordinary_support < minimum_state_support) {
    return(tibble::tibble(
      duration_hours = NA_real_,
      state_minutes = state_minutes,
      valid_state_minutes = valid_state_minutes,
      unknown_diary_state_minutes = 0L,
      state_domain_complete = TRUE,
      ordinary_state_support = ordinary_support,
      profile_state_support = profile_support,
      estimable = FALSE,
      failure_reason = "insufficient_state_support"
    ))
  }
  qualifies <- if (comparison == "above") {
    valid & day_grid$MEDI_eligible > threshold
  } else {
    valid & day_grid$MEDI_eligible < threshold
  }
  tibble::tibble(
    duration_hours = sum(qualifies) / 60,
    state_minutes = state_minutes,
    valid_state_minutes = valid_state_minutes,
    unknown_diary_state_minutes = 0L,
    state_domain_complete = TRUE,
    ordinary_state_support = ordinary_support,
    profile_state_support = profile_support,
    estimable = TRUE,
    failure_reason = NA_character_
  )
}

metric_gap_diagnostics <- function(day_grid) {
  missing_medi <- !is.finite(day_grid$MEDI_eligible)
  runs <- rle(missing_medi)
  missing_lengths <- runs$lengths[runs$values]
  tibble::tibble(
    expected_real_minutes = nrow(day_grid),
    expected_wall_minutes = 1440L,
    represented_wall_minutes = dplyr::n_distinct(day_grid$clock_minute),
    source_observed_real_minutes = sum(day_grid$source_minute_present),
    valid_medi_real_minutes = sum(is.finite(day_grid$MEDI_eligible)),
    valid_light_real_minutes = sum(is.finite(day_grid$LIGHT_eligible)),
    valid_paired_real_minutes = sum(
      is.finite(day_grid$MEDI_eligible) &
        is.finite(day_grid$LIGHT_eligible)
    ),
    unknown_diary_state_real_minutes = sum(is.na(day_grid$State.Brown)),
    missing_medi_real_minutes = sum(missing_medi),
    missing_medi_runs = length(missing_lengths),
    maximum_missing_medi_run_minutes = if (length(missing_lengths) > 0L) {
      max(missing_lengths)
    } else {
      0L
    },
    dst_fold_real_minutes = sum(day_grid$dst_fold),
    repeated_wall_real_minutes = sum(pmax(day_grid$fold_size - 1L, 0L)) /
      max(day_grid$fold_size),
    structural_nonexistent_wall_minutes = 1440L -
      dplyr::n_distinct(day_grid$clock_minute)
  )
}

new_daily_metric_record <- function(
  metric,
  value,
  units,
  state_domain,
  estimable,
  failure_reason = NA_character_,
  ordinary_support = NA_real_,
  relevance_support = NA_real_,
  valid_minutes = NA_integer_,
  expected_minutes = NA_integer_,
  descriptive_nonconfirmatory = FALSE,
  left_censored = FALSE,
  right_censored = FALSE,
  any_censored = FALSE,
  state_domain_complete = NA,
  medi_profile_support = NA_real_,
  light_profile_support = NA_real_,
  minimum_support = NA_real_,
  passes_ordinary_support = NA,
  passes_medi_profile_support = NA,
  passes_light_profile_support = NA,
  support_threshold_enforced = NA,
  ratio_scaled_or_weighted = NA,
  estimate_interpretation = NA_character_,
  missing_invalid_breaks_runs = NA,
  exact_identifiable = NA
) {
  tibble::tibble(
    analysis_unit = "participant_day",
    metric = metric,
    value = as.numeric(value),
    units = units,
    state_domain = state_domain,
    estimable = as.logical(estimable),
    failure_reason = as.character(failure_reason),
    ordinary_support = as.numeric(ordinary_support),
    relevance_support = as.numeric(relevance_support),
    valid_minutes = as.integer(valid_minutes),
    expected_minutes = as.integer(expected_minutes),
    descriptive_nonconfirmatory = descriptive_nonconfirmatory,
    left_censored = left_censored,
    right_censored = right_censored,
    any_censored = any_censored,
    state_domain_complete = as.logical(state_domain_complete),
    medi_profile_support = as.numeric(medi_profile_support),
    light_profile_support = as.numeric(light_profile_support),
    minimum_support = as.numeric(minimum_support),
    passes_ordinary_support = as.logical(passes_ordinary_support),
    passes_medi_profile_support = as.logical(passes_medi_profile_support),
    passes_light_profile_support = as.logical(passes_light_profile_support),
    support_threshold_enforced = as.logical(support_threshold_enforced),
    ratio_scaled_or_weighted = as.logical(ratio_scaled_or_weighted),
    estimate_interpretation = as.character(estimate_interpretation),
    missing_invalid_breaks_runs = as.logical(missing_invalid_breaks_runs),
    exact_identifiable = as.logical(exact_identifiable)
  )
}

derive_one_participant_day <- function(
  day_grid,
  profiles,
  maps,
  profile_variant,
  zero_offset,
  minimum_window_support,
  minimum_relevance_support,
  minimum_state_support,
  minimum_mder_viable_fraction,
  minimum_circular_resultant
) {
  key <- day_grid[1L, metric_day_key, drop = FALSE]
  site <- as.character(key$site)
  placement <- as.character(key$position)
  measurement_construct <- measurement_construct_for_placement(placement)
  variant <- profile_variant_for_site(profile_variant, site)
  expected_real_minutes <- nrow(day_grid)
  valid_medi <- is.finite(day_grid$MEDI_eligible)
  valid_light <- is.finite(day_grid$LIGHT_eligible)
  ordinary_support <- sum(valid_medi) / expected_real_minutes
  wall_grid <- collapse_metric_wall_minutes(day_grid)

  full_medi_profile <- select_fixed_profile(
    profiles,
    placement,
    site,
    "full_day",
    "MEDI",
    profile_variant
  )
  full_medi_weight <- weights_from_clock_bins(
    day_grid$clock_minute,
    full_medi_profile,
    "reference_weight"
  )
  daily_profile_support <- profile_weighted_coverage(
    observed_fraction = as.numeric(valid_medi),
    reference_weight = full_medi_weight
  )

  get_map_weight <- function(signal, map_name, state = "full_day") {
    map <- select_fixed_map(
      maps,
      placement,
      site,
      state,
      signal,
      map_name,
      profile_variant
    )
    weights_from_clock_bins(
      day_grid$clock_minute,
      map,
      "relevance_weight"
    )
  }
  dose_weight <- get_map_weight("MEDI", "dose")
  m10_wall_weight <- weights_from_clock_bins(
    wall_grid$clock_minute,
    select_fixed_map(
      maps,
      placement,
      site,
      "full_day",
      "MEDI",
      "M10",
      profile_variant
    ),
    "relevance_weight"
  )
  l10_wall_weight <- weights_from_clock_bins(
    wall_grid$clock_minute,
    select_fixed_map(
      maps,
      placement,
      site,
      "full_day",
      "MEDI",
      "L10",
      profile_variant
    ),
    "relevance_weight"
  )
  timing_wall_weight <- weights_from_clock_bins(
    wall_grid$clock_minute,
    select_fixed_map(
      maps,
      placement,
      site,
      "full_day",
      "MEDI",
      "timing_above_250",
      profile_variant
    ),
    "relevance_weight"
  )

  state_weight <- function(state) {
    profile <- select_fixed_profile(
      profiles,
      placement,
      site,
      state,
      "MEDI",
      profile_variant
    )
    weights_from_clock_bins(
      day_grid$clock_minute,
      profile,
      "reference_weight"
    )
  }

  daily_geometric_backtransform <- if (any(valid_medi)) {
    geometric_mean_backtransform_details(
      log_mean = mean(log10(
        day_grid$MEDI_eligible[valid_medi] + zero_offset
      )),
      zero_offset = zero_offset,
      source_all_zero = all(day_grid$MEDI_eligible[valid_medi] == 0)
    )
  } else {
    NULL
  }
  daily_geometric_mean <- if (is.null(daily_geometric_backtransform)) {
    NA_real_
  } else {
    daily_geometric_backtransform$value
  }
  m10 <- rolling_window_summary(
    value = wall_grid$MEDI,
    datetime = wall_grid$datetime_wall,
    clock_minute = wall_grid$clock_minute,
    period = "brightest",
    reference_weight = m10_wall_weight,
    window_minutes = 600L,
    epoch_seconds = 60,
    minimum_support = minimum_window_support,
    minimum_profile_support = minimum_window_support,
    minimum_resultant = minimum_circular_resultant,
    zero_offset = zero_offset,
    loop = FALSE
  )
  l10 <- rolling_window_summary(
    value = wall_grid$MEDI,
    datetime = wall_grid$datetime_wall,
    clock_minute = wall_grid$clock_minute,
    period = "darkest",
    reference_weight = l10_wall_weight,
    window_minutes = 600L,
    epoch_seconds = 60,
    minimum_support = minimum_window_support,
    minimum_profile_support = minimum_window_support,
    minimum_resultant = minimum_circular_resultant,
    zero_offset = zero_offset,
    loop = TRUE
  )

  full_above_1000 <- gap_aware_threshold_summary(
    value = day_grid$MEDI_eligible,
    datetime = day_grid$datetime_utc,
    threshold = 1000,
    comparison = "above",
    epoch_seconds = 60,
    interval_seconds = 60,
    segment = rep(1L, nrow(day_grid))
  )
  full_above_250 <- gap_aware_threshold_summary(
    value = day_grid$MEDI_eligible,
    datetime = day_grid$datetime_utc,
    threshold = 250,
    comparison = "above",
    epoch_seconds = 60,
    interval_seconds = 60,
    segment = rep(1L, nrow(day_grid))
  )
  timing <- threshold_timing_summary(
    value = wall_grid$MEDI,
    datetime = wall_grid$datetime_wall,
    threshold = 250,
    comparison = "above",
    clock_minute = wall_grid$clock_minute,
    interval_seconds = 60,
    observed_fraction = as.numeric(is.finite(wall_grid$MEDI)),
    reference_weight = timing_wall_weight,
    minimum_relevance_support = minimum_relevance_support,
    minimum_resultant = minimum_circular_resultant
  )

  measurement_segment <- if ("measurement_context" %in% names(day_grid)) {
    context <- as.character(day_grid$measurement_context)
    context[is.na(context)] <- "unknown"
    cumsum(c(TRUE, context[-1L] != context[-length(context)]))
  } else {
    sleep_environment <- !is.na(day_grid$State.Brown) &
      day_grid$State.Brown == "sleep"
    cumsum(c(
      TRUE,
      sleep_environment[-1L] !=
        sleep_environment[
          -length(
            sleep_environment
          )
        ]
    ))
  }
  longest <- longest_bout_with_censoring(
    value = day_grid$MEDI_eligible,
    datetime = day_grid$datetime_utc,
    segment = measurement_segment,
    threshold = 250,
    interval_seconds = 60
  )

  wake_duration <- state_threshold_duration(
    day_grid,
    state = "wake",
    threshold = 250,
    comparison = "above",
    state_profile_weight = state_weight("wake"),
    minimum_state_support = minimum_state_support
  )
  pre_sleep_duration <- state_threshold_duration(
    day_grid,
    state = "pre-sleep",
    threshold = 10,
    comparison = "below",
    state_profile_weight = state_weight("pre-sleep"),
    minimum_state_support = minimum_state_support
  )
  sleep_duration <- state_threshold_duration(
    day_grid,
    state = "sleep",
    threshold = 1,
    comparison = "below",
    state_profile_weight = state_weight("sleep"),
    minimum_state_support = minimum_state_support
  )

  dose <- time_sensitive_integral(
    value = day_grid$MEDI_eligible,
    reference_weight = dose_weight,
    epoch_hours = 1 / 60,
    observed_fraction = as.numeric(valid_medi),
    minimum_coverage = minimum_relevance_support,
    warning_coverage = minimum_relevance_support
  )
  mder_result <- mder_mean_of_viable_ratios(
    medi = wall_grid$MEDI,
    light = wall_grid$LIGHT,
    minimum_viable_fraction = minimum_mder_viable_fraction
  )

  wide <- dplyr::bind_cols(
    key,
    tibble::tibble(
      profile_variant = variant,
      measurement_construct = measurement_construct,
      expected_real_minutes = expected_real_minutes,
      valid_medi_real_minutes = sum(valid_medi),
      valid_light_real_minutes = sum(valid_light),
      diary_state_domain_complete = !anyNA(day_grid$State.Brown),
      unknown_diary_state_real_minutes = sum(is.na(day_grid$State.Brown)),
      daily_ordinary_support = ordinary_support,
      daily_profile_support = daily_profile_support,
      daily_geometric_mean_medi_lx = daily_geometric_mean,
      m10_mean_medi_lx = m10$window_mean,
      m10_midpoint_clock_minute = if (m10$timing_estimable) {
        m10$midpoint_clock_minute
      } else {
        NA_real_
      },
      m10_onset_clock_minute = if (m10$timing_estimable) {
        m10$onset_clock_minute
      } else {
        NA_real_
      },
      m10_offset_clock_minute = if (m10$timing_estimable) {
        m10$offset_clock_minute
      } else {
        NA_real_
      },
      l10_mean_medi_lx = l10$window_mean,
      l10_midpoint_clock_minute = if (l10$timing_estimable) {
        l10$midpoint_clock_minute
      } else {
        NA_real_
      },
      l10_onset_clock_minute = if (l10$timing_estimable) {
        l10$onset_clock_minute
      } else {
        NA_real_
      },
      l10_offset_clock_minute = if (l10$timing_estimable) {
        l10$offset_clock_minute
      } else {
        NA_real_
      },
      duration_above_1000_h = full_above_1000$duration_seconds / 3600,
      duration_above_250_full_day_h = full_above_250$duration_seconds / 3600,
      longest_bout_above_250_observed_h = longest$longest_observed_seconds /
        3600,
      longest_bout_above_250_observed_lower_bound_h = longest$longest_observed_lower_bound_seconds /
        3600,
      longest_bout_above_250_possible_h = longest$longest_possible_seconds /
        3600,
      longest_bout_above_250_possible_upper_bound_h = longest$longest_possible_upper_bound_seconds /
        3600,
      longest_bout_above_250_exact_only_sensitivity_h = longest$longest_exact_identifiable_seconds /
        3600,
      longest_bout_above_250_h = longest$longest_observed_lower_bound_seconds /
        3600,
      longest_bout_above_250_exact_identifiable = longest$exact_identifiable,
      longest_bout_above_250_censored = longest$longest_run_censored,
      longest_bout_above_250_missing_invalid_breaks_runs = longest$missing_invalid_breaks_observed_runs,
      longest_bout_above_250_estimate_interpretation = longest$observed_value_interpretation,
      longest_bout_above_250_onset_utc = longest$winner_onset_utc,
      longest_bout_above_250_offset_utc = longest$winner_offset_utc,
      longest_bout_above_250_winner_selection_rule = longest$winner_selection_rule,
      longest_bout_above_250_day_boundary_contact = longest$winner_day_boundary_contact,
      longest_bout_above_250_selected_winner_day_boundary_contact =
        longest$winner_day_boundary_contact,
      longest_bout_above_250_any_winning_run_day_boundary_contact =
        longest$any_winning_observed_run_day_boundary_contact,
      longest_bout_above_250_censor_reason = longest$censor_reason,
      first_timing_above_250_clock_minute = timing$first_clock_minute,
      last_timing_above_250_clock_minute = timing$last_clock_minute,
      mean_timing_above_250_clock_minute = timing$mean_clock_minute,
      dose_observed_medi_lx_h = dose$observed_integral,
      dose_corrected_medi_lx_h = dose$corrected_integral,
      dose_correction_factor = dose$correction_factor,
      dose_relevance_coverage = dose$relevance_coverage,
      mder = mder_result$MDER,
      mder_viable_ratio_minutes = mder_result$viable_ratio_minutes,
      mder_expected_minutes = mder_result$expected_minutes,
      mder_viable_ratio_fraction = mder_result$viable_ratio_fraction,
      mder_excluded_nonfinite_source_minutes =
        mder_result$excluded_nonfinite_source_minutes,
      mder_excluded_zero_either_minutes =
        mder_result$excluded_zero_either_minutes,
      mder_excluded_zero_medi_minutes =
        mder_result$excluded_zero_medi_minutes,
      mder_excluded_zero_light_minutes =
        mder_result$excluded_zero_light_minutes,
      mder_excluded_both_zero_minutes =
        mder_result$excluded_both_zero_minutes,
      mder_excluded_nonfinite_ratio_minutes =
        mder_result$excluded_nonfinite_ratio_minutes,
      mder_minimum_viable_fraction = mder_result$minimum_viable_fraction,
      mder_passes_viable_ratio_support =
        mder_result$passes_viable_ratio_support,
      mder_support_threshold_enforced = mder_result$support_threshold_enforced,
      mder_ratio_scaled_or_weighted = mder_result$ratio_scaled_or_weighted,
      mder_estimable = mder_result$estimable,
      mder_failure_reason = mder_result$failure_reason,
      duration_above_250_wake_h = wake_duration$duration_hours,
      duration_below_10_pre_sleep_h = pre_sleep_duration$duration_hours,
      duration_below_1_sleep_environment_h = sleep_duration$duration_hours
    )
  )

  records <- dplyr::bind_rows(
    new_daily_metric_record(
      "daily_geometric_mean_medi",
      daily_geometric_mean,
      "lx",
      "full_day_hybrid",
      is.finite(daily_geometric_mean),
      if (is.finite(daily_geometric_mean)) NA_character_ else
        "no_supported_value",
      ordinary_support,
      daily_profile_support,
      sum(valid_medi),
      expected_real_minutes
    ),
    new_daily_metric_record(
      "m10_mean_medi",
      m10$window_mean,
      "lx",
      "full_day_hybrid",
      m10$level_estimable,
      if (m10$level_estimable) NA_character_ else m10$failure_reason,
      m10$ordinary_support,
      m10$profile_weighted_support
    ),
    new_daily_metric_record(
      "m10_midpoint",
      if (m10$timing_estimable) m10$midpoint_clock_minute else NA_real_,
      "clock_minute",
      "full_day_hybrid",
      m10$timing_estimable,
      if (m10$timing_estimable) NA_character_ else m10$failure_reason,
      m10$ordinary_support,
      m10$profile_weighted_support
    ),
    new_daily_metric_record(
      "m10_onset",
      if (m10$timing_estimable) m10$onset_clock_minute else NA_real_,
      "clock_minute",
      "full_day_hybrid",
      m10$timing_estimable,
      if (m10$timing_estimable) NA_character_ else m10$failure_reason,
      m10$ordinary_support,
      m10$profile_weighted_support
    ),
    new_daily_metric_record(
      "m10_offset",
      if (m10$timing_estimable) m10$offset_clock_minute else NA_real_,
      "clock_minute",
      "full_day_hybrid",
      m10$timing_estimable,
      if (m10$timing_estimable) NA_character_ else m10$failure_reason,
      m10$ordinary_support,
      m10$profile_weighted_support
    ),
    new_daily_metric_record(
      "l10_mean_medi",
      l10$window_mean,
      "lx",
      "full_day_hybrid",
      l10$level_estimable,
      if (l10$level_estimable) NA_character_ else l10$failure_reason,
      l10$ordinary_support,
      l10$profile_weighted_support
    ),
    new_daily_metric_record(
      "l10_midpoint",
      if (l10$timing_estimable) l10$midpoint_clock_minute else NA_real_,
      "clock_minute",
      "full_day_hybrid",
      l10$timing_estimable,
      if (l10$timing_estimable) NA_character_ else l10$failure_reason,
      l10$ordinary_support,
      l10$profile_weighted_support
    ),
    new_daily_metric_record(
      "l10_onset",
      if (l10$timing_estimable) l10$onset_clock_minute else NA_real_,
      "clock_minute",
      "full_day_hybrid",
      l10$timing_estimable,
      if (l10$timing_estimable) NA_character_ else l10$failure_reason,
      l10$ordinary_support,
      l10$profile_weighted_support
    ),
    new_daily_metric_record(
      "l10_offset",
      if (l10$timing_estimable) l10$offset_clock_minute else NA_real_,
      "clock_minute",
      "full_day_hybrid",
      l10$timing_estimable,
      if (l10$timing_estimable) NA_character_ else l10$failure_reason,
      l10$ordinary_support,
      l10$profile_weighted_support
    ),
    new_daily_metric_record(
      "duration_above_1000",
      full_above_1000$duration_seconds / 3600,
      "h",
      "full_day_hybrid",
      TRUE,
      ordinary_support = ordinary_support,
      relevance_support = dose$relevance_coverage,
      valid_minutes = sum(valid_medi),
      expected_minutes = expected_real_minutes
    ),
    new_daily_metric_record(
      "duration_above_250_full_day",
      full_above_250$duration_seconds / 3600,
      "h",
      "full_day_hybrid",
      TRUE,
      ordinary_support = ordinary_support,
      relevance_support = timing$mean_relevance_support,
      valid_minutes = sum(valid_medi),
      expected_minutes = expected_real_minutes,
      descriptive_nonconfirmatory = TRUE
    ),
    new_daily_metric_record(
      "longest_bout_above_250",
      longest$longest_observed_lower_bound_seconds / 3600,
      "h",
      "full_day_hybrid",
      TRUE,
      NA_character_,
      ordinary_support,
      timing$mean_relevance_support,
      sum(valid_medi),
      expected_real_minutes,
      any_censored = longest$longest_run_censored,
      estimate_interpretation = longest$observed_value_interpretation,
      missing_invalid_breaks_runs = longest$missing_invalid_breaks_observed_runs,
      exact_identifiable = longest$exact_identifiable
    ),
    new_daily_metric_record(
      "longest_bout_above_250_exact_only_sensitivity",
      longest$longest_exact_identifiable_seconds / 3600,
      "h",
      "full_day_hybrid",
      longest$exact_identifiable,
      longest$exact_failure_reason,
      ordinary_support,
      timing$mean_relevance_support,
      sum(valid_medi),
      expected_real_minutes,
      descriptive_nonconfirmatory = TRUE,
      any_censored = longest$longest_run_censored,
      estimate_interpretation = "exact_only_sensitivity",
      missing_invalid_breaks_runs = longest$missing_invalid_breaks_observed_runs,
      exact_identifiable = longest$exact_identifiable
    ),
    new_daily_metric_record(
      "first_timing_above_250",
      timing$first_clock_minute,
      "clock_minute",
      "full_day_hybrid",
      is.finite(timing$first_clock_minute),
      timing$first_failure_reason,
      ordinary_support,
      timing$first_relevance_support,
      sum(valid_medi),
      expected_real_minutes,
      left_censored = timing$first_censored
    ),
    new_daily_metric_record(
      "last_timing_above_250",
      timing$last_clock_minute,
      "clock_minute",
      "full_day_hybrid",
      is.finite(timing$last_clock_minute),
      timing$last_failure_reason,
      ordinary_support,
      timing$last_relevance_support,
      sum(valid_medi),
      expected_real_minutes,
      right_censored = timing$last_censored
    ),
    new_daily_metric_record(
      "mean_timing_above_250",
      timing$mean_clock_minute,
      "clock_minute",
      "full_day_hybrid",
      timing$mean_estimable,
      timing$mean_failure_reason,
      ordinary_support,
      timing$mean_relevance_support,
      sum(valid_medi),
      expected_real_minutes
    ),
    new_daily_metric_record(
      "dose_observed_medi",
      dose$observed_integral,
      "lx_h",
      "full_day_hybrid",
      is.finite(dose$observed_integral),
      if (is.finite(dose$observed_integral)) NA_character_ else
        dose$failure_reason,
      dose$ordinary_coverage,
      dose$relevance_coverage,
      sum(valid_medi),
      expected_real_minutes
    ),
    new_daily_metric_record(
      "dose_time_sensitive_corrected_medi",
      dose$corrected_integral,
      "lx_h",
      "full_day_hybrid",
      dose$correction_admissible,
      dose$failure_reason,
      dose$ordinary_coverage,
      dose$relevance_coverage,
      sum(valid_medi),
      expected_real_minutes
    ),
    new_daily_metric_record(
      "mder_mean_of_viable_ratios",
      mder_result$MDER,
      "dimensionless",
      "full_day_positive_paired_minutes",
      mder_result$estimable,
      mder_result$failure_reason,
      mder_result$viable_ratio_fraction,
      NA_real_,
      mder_result$viable_ratio_minutes,
      mder_result$expected_minutes,
      minimum_support = mder_result$minimum_viable_fraction,
      passes_ordinary_support = mder_result$passes_viable_ratio_support,
      support_threshold_enforced = mder_result$support_threshold_enforced,
      ratio_scaled_or_weighted = mder_result$ratio_scaled_or_weighted
    ),
    new_daily_metric_record(
      "duration_above_250_wake",
      wake_duration$duration_hours,
      "h",
      "wake",
      wake_duration$estimable,
      wake_duration$failure_reason,
      wake_duration$ordinary_state_support,
      wake_duration$profile_state_support,
      wake_duration$valid_state_minutes,
      wake_duration$state_minutes,
      state_domain_complete = wake_duration$state_domain_complete
    ),
    new_daily_metric_record(
      "duration_below_10_pre_sleep",
      pre_sleep_duration$duration_hours,
      "h",
      "pre-sleep",
      pre_sleep_duration$estimable,
      pre_sleep_duration$failure_reason,
      pre_sleep_duration$ordinary_state_support,
      pre_sleep_duration$profile_state_support,
      pre_sleep_duration$valid_state_minutes,
      pre_sleep_duration$state_minutes,
      state_domain_complete = pre_sleep_duration$state_domain_complete
    ),
    new_daily_metric_record(
      "duration_below_1_sleep_environment",
      sleep_duration$duration_hours,
      "h",
      "sleep",
      sleep_duration$estimable,
      sleep_duration$failure_reason,
      sleep_duration$ordinary_state_support,
      sleep_duration$profile_state_support,
      sleep_duration$valid_state_minutes,
      sleep_duration$state_minutes,
      state_domain_complete = sleep_duration$state_domain_complete
    )
  ) |>
    dplyr::mutate(
      !!!key,
      profile_variant = variant,
      .before = 1L
    )

  support <- records |>
    dplyr::select(
      dplyr::all_of(c(
        metric_day_key,
        "profile_variant",
        "metric",
        "state_domain",
        "ordinary_support",
        "relevance_support",
        "medi_profile_support",
        "light_profile_support",
        "minimum_support",
        "passes_ordinary_support",
        "passes_medi_profile_support",
        "passes_light_profile_support",
        "support_threshold_enforced",
        "ratio_scaled_or_weighted",
        "valid_minutes",
        "expected_minutes",
        "state_domain_complete",
        "estimable",
        "failure_reason"
      ))
    )
  censoring <- dplyr::bind_cols(
    key,
    tibble::tibble(
      profile_variant = variant,
      timing_threshold_observed = timing$threshold_observed,
      first_timing_left_censored = timing$first_censored,
      last_timing_right_censored = timing$last_censored,
      strict_first_boundary_gap = timing$strict_first_censored,
      strict_last_boundary_gap = timing$strict_last_censored,
      timing_circular_resultant = timing$circular_resultant,
      longest_bout_censored = longest$longest_run_censored,
      longest_bout_observed_h = longest$longest_observed_seconds / 3600,
      longest_bout_observed_lower_bound_h = longest$longest_observed_lower_bound_seconds /
        3600,
      longest_bout_possible_h = longest$longest_possible_seconds / 3600,
      longest_bout_possible_upper_bound_h = longest$longest_possible_upper_bound_seconds /
        3600,
      longest_bout_exact_only_sensitivity_h = longest$longest_exact_identifiable_seconds /
        3600,
      longest_bout_exact_identifiable = longest$exact_identifiable,
      longest_bout_missing_invalid_breaks_runs = longest$missing_invalid_breaks_observed_runs,
      longest_bout_observed_value_interpretation = longest$observed_value_interpretation,
      longest_bout_possible_bound_interpretation = longest$possible_bound_interpretation,
      longest_bout_winning_observed_runs = longest$winning_observed_runs,
      longest_bout_winner_onset_utc = longest$winner_onset_utc,
      longest_bout_winner_offset_utc = longest$winner_offset_utc,
      longest_bout_winner_selection_rule = longest$winner_selection_rule,
      longest_bout_day_boundary_contact = longest$winner_day_boundary_contact,
      longest_bout_selected_winner_day_boundary_contact =
        longest$winner_day_boundary_contact,
      longest_bout_any_winning_run_day_boundary_contact =
        longest$any_winning_observed_run_day_boundary_contact,
      longest_bout_censor_reason = longest$censor_reason,
      m10_tied_windows = m10$tied_windows,
      m10_tie_resultant = m10$tie_resultant,
      l10_tied_windows = l10$tied_windows,
      l10_tie_resultant = l10$tie_resultant,
      structural_nonexistent_wall_minutes = sum(
        !wall_grid$wall_minute_exists
      ),
      dst_fold_wall_minutes = sum(wall_grid$dst_fold),
      maximum_true_minutes_per_wall_minute = max(
        wall_grid$source_real_minutes
      )
    )
  )
  gap <- dplyr::bind_cols(key, metric_gap_diagnostics(day_grid))

  window_backtransform <- function(window) {
    list(
      value = window$window_mean[[1L]],
      raw_value = window$window_raw_backtransformed_mean[[1L]],
      shifted_mean = window$window_shifted_mean[[1L]],
      tolerance = window$numerical_zero_tolerance[[1L]],
      source_all_zero = isTRUE(
        window$selected_window_valid_wall_minutes[[1L]] > 0L &&
          window$selected_window_zero_wall_minutes[[1L]] ==
            window$selected_window_valid_wall_minutes[[1L]]
      ),
      numerical_zero_reclassified = isTRUE(
        window$numerical_zero_reclassified[[1L]]
      ),
      numerical_zero_reason = window$numerical_zero_reason[[1L]]
    )
  }
  window_audit_record <- function(window, metric) {
    new_numerical_zero_audit_record(
      key = key,
      metric = metric,
      analysis_unit = "participant_day_window",
      backtransform = window_backtransform(window),
      zero_offset = zero_offset,
      source_valid_minutes = window$selected_window_valid_wall_minutes,
      source_zero_minutes = window$selected_window_zero_wall_minutes,
      source_positive_minutes = window$selected_window_positive_wall_minutes,
      source_missing_minutes = window$selected_window_missing_wall_minutes,
      source_real_minutes = window$selected_window_source_real_minutes,
      source_valid_real_minutes =
        window$selected_window_valid_source_real_minutes,
      window_start_clock_minute =
        window$selected_window_start_clock_minute,
      window_end_clock_minute = window$selected_window_end_clock_minute,
      window_wraps_midnight = window$selected_window_wraps_midnight
    )
  }
  daily_audit_record <- if (is.null(daily_geometric_backtransform)) {
    window_audit_record(m10, "m10_mean_medi")[FALSE, , drop = FALSE]
  } else {
    new_numerical_zero_audit_record(
      key = key,
      metric = "daily_geometric_mean_medi",
      analysis_unit = "participant_day",
      backtransform = daily_geometric_backtransform,
      zero_offset = zero_offset,
      source_valid_minutes = sum(valid_medi),
      source_zero_minutes = sum(
        valid_medi & day_grid$MEDI_eligible == 0
      ),
      source_positive_minutes = sum(
        valid_medi & day_grid$MEDI_eligible > 0
      ),
      source_missing_minutes = sum(!valid_medi),
      source_real_minutes = nrow(day_grid),
      source_valid_real_minutes = sum(valid_medi)
    )
  }
  numerical_zero_audit <- dplyr::bind_rows(
    daily_audit_record,
    window_audit_record(m10, "m10_mean_medi"),
    window_audit_record(l10, "l10_mean_medi")
  )

  list(
    wide = wide,
    values = records,
    support = support,
    censoring = censoring,
    gap = gap,
    numerical_zero_audit = numerical_zero_audit
  )
}

derive_participant_is_iv <- function(true_grid, profile_variant) {
  groups <- split(
    seq_len(nrow(true_grid)),
    interaction(
      true_grid$site,
      true_grid$Id,
      true_grid$position,
      drop = TRUE,
      lex.order = TRUE
    )
  )
  purrr::map_dfr(groups, function(index) {
    data <- true_grid[index, , drop = FALSE] |>
      dplyr::arrange(.data$datetime_utc)
    key <- data[1L, metric_participant_key, drop = FALSE]
    placement <- as.character(key$position)
    result <- gap_aware_is_iv(
      value = data$MEDI_eligible,
      datetime = data$datetime_utc,
      clock_hour = floor(data$clock_minute / 60L),
      local_date = data$local_date,
      clock_minute = data$clock_minute,
      epoch_seconds = 60,
      bin_seconds = 3600,
      minimum_bin_support = 0.5,
      minimum_days = 3L,
      minimum_is_clock_hours = 20L,
      minimum_days_per_clock_hour = 2L,
      minimum_iv_pairs = 24L,
      minimum_iv_pair_days = 3L
    )
    dplyr::bind_cols(
      key,
      tibble::tibble(
        profile_variant = profile_variant_for_site(
          profile_variant,
          as.character(key$site)
        ),
        measurement_construct = measurement_construct_for_placement(
          placement
        )
      ),
      result
    )
  }) |>
    dplyr::arrange(.data$site, .data$Id, .data$position)
}

participant_metric_values_long <- function(participant_metrics) {
  is_rows <- participant_metrics |>
    dplyr::transmute(
      dplyr::across(dplyr::all_of(metric_participant_key)),
      .data$profile_variant,
      analysis_unit = "participant",
      metric = "interdaily_stability",
      value = .data$interdaily_stability,
      units = "dimensionless",
      state_domain = "repeated_hybrid_days",
      estimable = .data$is_estimable,
      failure_reason = .data$is_failure_reason,
      ordinary_support = NA_real_,
      relevance_support = NA_real_,
      valid_minutes = .data$valid_minutes,
      expected_minutes = .data$expected_minutes,
      descriptive_nonconfirmatory = FALSE,
      left_censored = FALSE,
      right_censored = FALSE,
      any_censored = FALSE
    )
  iv_rows <- participant_metrics |>
    dplyr::transmute(
      dplyr::across(dplyr::all_of(metric_participant_key)),
      .data$profile_variant,
      analysis_unit = "participant",
      metric = "intradaily_variability",
      value = .data$intradaily_variability,
      units = "dimensionless",
      state_domain = "repeated_hybrid_days",
      estimable = .data$iv_estimable,
      failure_reason = .data$iv_failure_reason,
      ordinary_support = NA_real_,
      relevance_support = NA_real_,
      valid_minutes = .data$valid_minutes,
      expected_minutes = .data$expected_minutes,
      descriptive_nonconfirmatory = FALSE,
      left_censored = FALSE,
      right_censored = FALSE,
      any_censored = FALSE
    )
  dplyr::bind_rows(is_rows, iv_rows)
}

validate_state_support_rows <- function(
  support,
  object = deparse(substitute(support))
) {
  state_metrics <- c(
    "duration_above_250_wake",
    "duration_below_10_pre_sleep",
    "duration_below_1_sleep_environment"
  )
  required <- c(
    metric_day_key,
    "metric",
    "state_domain",
    "ordinary_support",
    "valid_minutes",
    "expected_minutes",
    "state_domain_complete",
    "failure_reason"
  )
  assert_columns(support, required, object = object)
  state_support <- support |>
    dplyr::filter(.data$metric %in% state_metrics)
  if (nrow(state_support) == 0L) {
    abort_pipeline("State-specific support diagnostics have no input rows")
  }
  expected_domains <- c(
    duration_above_250_wake = "wake",
    duration_below_10_pre_sleep = "pre-sleep",
    duration_below_1_sleep_environment = "sleep"
  )
  if (
    any(
      state_support$state_domain !=
        unname(expected_domains[state_support$metric])
    )
  ) {
    abort_pipeline("%s has inconsistent state metric/domain mappings", object)
  }
  if (
    !is.logical(state_support$state_domain_complete) ||
      anyNA(state_support$state_domain_complete)
  ) {
    abort_pipeline("%s has incomplete non-logical state completeness", object)
  }
  if (
    anyNA(state_support$valid_minutes) ||
      anyNA(state_support$expected_minutes) ||
      any(!is.finite(state_support$valid_minutes)) ||
      any(!is.finite(state_support$expected_minutes)) ||
      any(state_support$valid_minutes < 0) ||
      any(state_support$expected_minutes < 0) ||
      any(state_support$valid_minutes > state_support$expected_minutes)
  ) {
    abort_pipeline("%s has invalid state-minute denominators", object)
  }
  positive_domain <- state_support$expected_minutes > 0
  valid_support <- is.finite(state_support$ordinary_support) &
    state_support$ordinary_support >= 0 &
    state_support$ordinary_support <= 1
  if (
    any(positive_domain & !valid_support) ||
      any(!positive_domain & !is.na(state_support$ordinary_support))
  ) {
    abort_pipeline("%s has inconsistent state-support fractions", object)
  }
  incomplete <- !state_support$state_domain_complete
  no_window <- state_support$state_domain_complete & !positive_domain
  complete_window <- state_support$state_domain_complete & positive_domain
  if (
    any(
      incomplete &
        state_support$failure_reason != "incomplete_state_domain",
      na.rm = TRUE
    ) ||
      any(incomplete & is.na(state_support$failure_reason)) ||
      any(
        no_window &
          state_support$failure_reason != "no_state_window",
        na.rm = TRUE
      ) ||
      any(no_window & is.na(state_support$failure_reason)) ||
      any(
        complete_window &
          !is.na(state_support$failure_reason) &
          state_support$failure_reason != "insufficient_state_support"
      )
  ) {
    abort_pipeline(
      "%s has inconsistent state completeness, support, or failure reasons",
      object
    )
  }
  state_support
}

classify_state_support_candidates <- function(
  support,
  candidate_cutoffs = state_support_candidate_cutoffs
) {
  candidate_cutoffs <- validate_state_support_candidate_cutoffs(
    candidate_cutoffs
  )
  state_support <- validate_state_support_rows(
    support,
    object = "state-support candidate input"
  )
  tidyr::crossing(
    state_support,
    candidate_state_support_cutoff = candidate_cutoffs
  ) |>
    dplyr::mutate(
      has_state_window = .data$state_domain_complete &
        .data$expected_minutes > 0,
      retained_at_candidate = .data$state_domain_complete &
        .data$has_state_window &
        .data$ordinary_support >= .data$candidate_state_support_cutoff,
      metric_na_at_candidate = !.data$retained_at_candidate,
      no_state_window = .data$state_domain_complete &
        !.data$has_state_window,
      incomplete_state_domain = !.data$state_domain_complete,
      insufficient_state_support = .data$state_domain_complete &
        .data$has_state_window &
        .data$ordinary_support < .data$candidate_state_support_cutoff
    )
}

state_support_cutoff_diagnostics <- function(
  support,
  candidate_cutoffs = state_support_candidate_cutoffs
) {
  classified <- classify_state_support_candidates(
    support,
    candidate_cutoffs = candidate_cutoffs
  )
  summary <- classified |>
    dplyr::group_by(
      .data$position,
      .data$metric,
      .data$state_domain,
      .data$candidate_state_support_cutoff
    ) |>
    dplyr::summarise(
      eligible_participant_days = dplyr::n(),
      eligible_participants = dplyr::n_distinct(.data$site, .data$Id),
      eligible_sites = dplyr::n_distinct(.data$site),
      participant_days_with_state_window = sum(.data$has_state_window),
      participants_with_state_window = dplyr::n_distinct(
        .data$site[.data$has_state_window],
        .data$Id[.data$has_state_window]
      ),
      retained_metric_instances = sum(.data$retained_at_candidate),
      retained_participants = dplyr::n_distinct(
        .data$site[.data$retained_at_candidate],
        .data$Id[.data$retained_at_candidate]
      ),
      sites_with_retained_metric = dplyr::n_distinct(
        .data$site[.data$retained_at_candidate]
      ),
      metric_na_instances = sum(.data$metric_na_at_candidate),
      no_state_window_instances = sum(.data$no_state_window),
      incomplete_state_domain_instances = sum(
        .data$incomplete_state_domain
      ),
      insufficient_state_support_instances = sum(
        .data$insufficient_state_support
      ),
      ordinary_support_q10 = finite_quantile_metric(
        .data$ordinary_support[.data$has_state_window],
        0.10
      ),
      ordinary_support_q25 = finite_quantile_metric(
        .data$ordinary_support[.data$has_state_window],
        0.25
      ),
      ordinary_support_median = finite_quantile_metric(
        .data$ordinary_support[.data$has_state_window],
        0.50
      ),
      ordinary_support_q75 = finite_quantile_metric(
        .data$ordinary_support[.data$has_state_window],
        0.75
      ),
      ordinary_support_q90 = finite_quantile_metric(
        .data$ordinary_support[.data$has_state_window],
        0.90
      ),
      .groups = "drop"
    ) |>
    dplyr::group_by(.data$position, .data$metric, .data$state_domain) |>
    dplyr::arrange(
      .data$candidate_state_support_cutoff,
      .by_group = TRUE
    ) |>
    dplyr::mutate(
      retained_fraction = .data$retained_metric_instances /
        .data$eligible_participant_days,
      marginal_metric_instance_loss_from_lower = dplyr::lag(
        .data$retained_metric_instances
      ) -
        .data$retained_metric_instances,
      marginal_participant_loss_from_lower = dplyr::lag(
        .data$retained_participants
      ) -
        .data$retained_participants,
      classification_total = .data$retained_metric_instances +
        .data$no_state_window_instances +
        .data$incomplete_state_domain_instances +
        .data$insufficient_state_support_instances,
      status = "diagnostic_only_not_final",
      selection_rule = "candidate_cutoffs_fixed_without_result_preference"
    ) |>
    dplyr::ungroup() |>
    dplyr::arrange(
      .data$position,
      .data$metric,
      .data$candidate_state_support_cutoff
    )
  if (
    any(
      summary$classification_total != summary$eligible_participant_days
    )
  ) {
    abort_pipeline("State-support candidate classifications do not reconcile")
  }
  summary
}

state_support_cutoff_site_diagnostics <- function(
  support,
  candidate_cutoffs = state_support_candidate_cutoffs
) {
  classified <- classify_state_support_candidates(
    support,
    candidate_cutoffs = candidate_cutoffs
  )
  summary <- classified |>
    dplyr::group_by(
      .data$position,
      .data$site,
      .data$metric,
      .data$state_domain,
      .data$candidate_state_support_cutoff
    ) |>
    dplyr::summarise(
      eligible_participant_days = dplyr::n(),
      eligible_participants = dplyr::n_distinct(.data$Id),
      participant_days_with_state_window = sum(.data$has_state_window),
      retained_metric_instances = sum(.data$retained_at_candidate),
      retained_participants = dplyr::n_distinct(
        .data$Id[.data$retained_at_candidate]
      ),
      no_state_window_instances = sum(.data$no_state_window),
      incomplete_state_domain_instances = sum(
        .data$incomplete_state_domain
      ),
      insufficient_state_support_instances = sum(
        .data$insufficient_state_support
      ),
      ordinary_support_q25 = finite_quantile_metric(
        .data$ordinary_support[.data$has_state_window],
        0.25
      ),
      ordinary_support_median = finite_quantile_metric(
        .data$ordinary_support[.data$has_state_window],
        0.50
      ),
      ordinary_support_q75 = finite_quantile_metric(
        .data$ordinary_support[.data$has_state_window],
        0.75
      ),
      .groups = "drop"
    ) |>
    dplyr::group_by(
      .data$position,
      .data$site,
      .data$metric,
      .data$state_domain
    ) |>
    dplyr::arrange(
      .data$candidate_state_support_cutoff,
      .by_group = TRUE
    ) |>
    dplyr::mutate(
      retained_fraction = .data$retained_metric_instances /
        .data$eligible_participant_days,
      marginal_metric_instance_loss_from_lower = dplyr::lag(
        .data$retained_metric_instances
      ) -
        .data$retained_metric_instances,
      classification_total = .data$retained_metric_instances +
        .data$no_state_window_instances +
        .data$incomplete_state_domain_instances +
        .data$insufficient_state_support_instances,
      status = "diagnostic_only_not_final",
      selection_rule = "candidate_cutoffs_fixed_without_result_preference"
    ) |>
    dplyr::ungroup() |>
    dplyr::arrange(
      .data$position,
      .data$site,
      .data$metric,
      .data$candidate_state_support_cutoff
    )
  if (
    any(
      summary$classification_total != summary$eligible_participant_days
    )
  ) {
    abort_pipeline(
      "Site-stratified state-support candidate classifications do not reconcile"
    )
  }
  summary
}

derive_state_support_gate_diagnostics <- function(
  coverage,
  state_intervals,
  placement,
  candidate_cutoffs = state_support_candidate_cutoffs
) {
  candidate_cutoffs <- validate_state_support_candidate_cutoffs(
    candidate_cutoffs
  )
  true_grid <- build_complete_metric_grid(
    coverage,
    state_intervals = state_intervals,
    placement = placement,
    object = paste0(placement, " state-support gate input")
  )
  groups <- split(
    seq_len(nrow(true_grid)),
    interaction(
      true_grid$site,
      true_grid$Id,
      true_grid$position,
      true_grid$local_date,
      drop = TRUE,
      lex.order = TRUE
    )
  )
  state_specification <- tibble::tribble(
    ~state_domain,
    ~metric,
    "wake",
    "duration_above_250_wake",
    "pre-sleep",
    "duration_below_10_pre_sleep",
    "sleep",
    "duration_below_1_sleep_environment"
  )
  daily_support <- purrr::map_dfr(groups, function(index) {
    day <- true_grid[index, , drop = FALSE]
    key <- day[1L, metric_day_key, drop = FALSE]
    records <- purrr::map2_dfr(
      state_specification$state_domain,
      state_specification$metric,
      function(state_domain, metric) {
        unknown_diary_state_minutes <- sum(is.na(day$State.Brown))
        state_rows <- !is.na(day$State.Brown) &
          day$State.Brown == state_domain
        state_minutes <- sum(state_rows)
        valid_state_minutes <- sum(
          state_rows & is.finite(day$MEDI_eligible)
        )
        tibble::tibble(
          metric = metric,
          state_domain = state_domain,
          ordinary_support = if (state_minutes > 0L) {
            valid_state_minutes / state_minutes
          } else {
            NA_real_
          },
          valid_minutes = valid_state_minutes,
          expected_minutes = state_minutes,
          unknown_diary_state_minutes = unknown_diary_state_minutes,
          state_domain_complete = unknown_diary_state_minutes == 0L,
          failure_reason = dplyr::case_when(
            unknown_diary_state_minutes > 0L ~ "incomplete_state_domain",
            state_minutes == 0L ~ "no_state_window",
            TRUE ~ NA_character_
          )
        )
      }
    )
    dplyr::bind_cols(
      key[rep(1L, nrow(records)), , drop = FALSE],
      records
    )
  }) |>
    dplyr::arrange(
      .data$site,
      .data$Id,
      .data$position,
      .data$local_date,
      .data$metric
    )
  list(
    daily_support = daily_support,
    candidates = state_support_cutoff_diagnostics(
      daily_support,
      candidate_cutoffs = candidate_cutoffs
    )
  )
}

derive_metric_set <- function(
  coverage,
  state_intervals,
  profiles,
  maps,
  placement,
  profile_variant = "pooled",
  zero_offset = 0.1,
  minimum_window_support = 0.8,
  minimum_relevance_support = 0.8,
  minimum_state_support = NULL,
  minimum_mder_viable_fraction = mder_primary_viable_fraction,
  minimum_circular_resultant = 0.1
) {
  if (is.null(minimum_state_support)) {
    abort_pipeline(
      paste0(
        "`minimum_state_support` must be supplied explicitly. The approved ",
        "canonical cutoff is 0.80; use 0.70 or 0.90 only in a namespaced ",
        "sensitivity run"
      )
    )
  }
  validate_fixed_metric_profiles(profiles, maps)
  validate_fraction(minimum_window_support, "minimum_window_support")
  validate_fraction(minimum_relevance_support, "minimum_relevance_support")
  validate_fraction(minimum_state_support, "minimum_state_support")
  minimum_mder_viable_fraction <- validate_mder_viable_fraction(
    minimum_mder_viable_fraction
  )
  validate_fraction(minimum_circular_resultant, "minimum_circular_resultant")
  validate_positive_scalar(zero_offset, "zero_offset")

  true_grid <- build_complete_metric_grid(
    coverage,
    state_intervals = state_intervals,
    placement = placement,
    object = paste0(placement, " coverage artifact")
  )
  day_groups <- split(
    seq_len(nrow(true_grid)),
    interaction(
      true_grid$site,
      true_grid$Id,
      true_grid$position,
      true_grid$local_date,
      drop = TRUE,
      lex.order = TRUE
    )
  )
  daily_results <- purrr::map(day_groups, function(index) {
    day_grid <- true_grid[index, , drop = FALSE] |>
      dplyr::arrange(.data$datetime_utc)
    derive_one_participant_day(
      day_grid = day_grid,
      profiles = profiles,
      maps = maps,
      profile_variant = profile_variant,
      zero_offset = zero_offset,
      minimum_window_support = minimum_window_support,
      minimum_relevance_support = minimum_relevance_support,
      minimum_state_support = minimum_state_support,
      minimum_mder_viable_fraction = minimum_mder_viable_fraction,
      minimum_circular_resultant = minimum_circular_resultant
    )
  })
  daily_metrics <- purrr::map_dfr(daily_results, "wide") |>
    dplyr::arrange(
      .data$site,
      .data$Id,
      .data$position,
      .data$local_date
    )
  daily_values <- purrr::map_dfr(daily_results, "values") |>
    dplyr::arrange(
      .data$site,
      .data$Id,
      .data$position,
      .data$local_date,
      .data$metric
    )
  support <- purrr::map_dfr(daily_results, "support") |>
    dplyr::arrange(
      .data$site,
      .data$Id,
      .data$position,
      .data$local_date,
      .data$metric
    )
  state_support_candidates <- state_support_cutoff_diagnostics(support)
  censoring <- purrr::map_dfr(daily_results, "censoring") |>
    dplyr::arrange(
      .data$site,
      .data$Id,
      .data$position,
      .data$local_date
    )
  gap <- purrr::map_dfr(daily_results, "gap") |>
    dplyr::arrange(
      .data$site,
      .data$Id,
      .data$position,
      .data$local_date
    )
  daily_numerical_zero_audit <- purrr::map_dfr(
    daily_results,
    "numerical_zero_audit"
  )

  wall_grids <- purrr::map(day_groups, function(index) {
    collapse_metric_wall_minutes(
      true_grid[index, , drop = FALSE] |>
        dplyr::arrange(.data$datetime_utc)
    )
  })
  thirty_minute <- purrr::map_dfr(
    wall_grids,
    aggregate_clock_outcome,
    bin_minutes = 30L,
    minimum_valid_minutes = 15L,
    outcome = "arithmetic",
    zero_offset = zero_offset
  ) |>
    dplyr::rename(clock_bin = "bin_start_clock_minute") |>
    dplyr::arrange(
      .data$site,
      .data$Id,
      .data$position,
      .data$local_date,
      .data$clock_bin
    ) |>
    dplyr::select(
      -"zero_medi_wall_minutes",
      -"positive_medi_wall_minutes",
      -"zero_aware_log_mean_medi",
      -"zero_aware_source_all_zero",
      -dplyr::starts_with(".numerical_zero_")
    )
  hourly_with_audit <- purrr::map_dfr(
    wall_grids,
    aggregate_clock_outcome,
    bin_minutes = 60L,
    minimum_valid_minutes = 30L,
    outcome = "zero_aware_geometric",
    zero_offset = zero_offset
  ) |>
    dplyr::rename(clock_minute = "bin_start_clock_minute") |>
    dplyr::mutate(clock_hour = as.integer(.data$clock_minute / 60L)) |>
    dplyr::arrange(
      .data$site,
      .data$Id,
      .data$position,
      .data$local_date,
      .data$clock_hour
    )
  hourly_numerical_zero_audit <- hourly_with_audit |>
    dplyr::filter(.data$.numerical_zero_reclassified) |>
    dplyr::transmute(
      dplyr::across(dplyr::all_of(metric_day_key)),
      metric = "one_hour_zero_aware_geometric_mean_medi",
      analysis_unit = "participant_hour",
      units = "lx",
      clock_hour = .data$clock_hour,
      window_start_clock_minute = .data$clock_minute,
      window_end_clock_minute = (.data$clock_minute + 60L) %% 1440L,
      window_wraps_midnight = .data$clock_minute + 60L > 1440L,
      raw_backtransformed_value_lx = .data$.numerical_zero_raw_value_lx,
      normalized_value_lx = .data$zero_aware_geometric_mean_medi_lx,
      shifted_mean_lx = .data$.numerical_zero_shifted_mean_lx,
      numerical_zero_tolerance_lx = .data$.numerical_zero_tolerance_lx,
      zero_offset_lx = zero_offset,
      source_all_zero = .data$zero_aware_source_all_zero,
      source_valid_minutes = .data$valid_medi_wall_minutes,
      source_zero_minutes = .data$zero_medi_wall_minutes,
      source_positive_minutes = .data$positive_medi_wall_minutes,
      source_missing_minutes = .data$expected_wall_minutes -
        .data$valid_medi_wall_minutes,
      source_real_minutes = .data$source_real_minutes,
      source_valid_real_minutes = .data$source_observed_real_minutes,
      numerical_zero_decision_id = numerical_zero_decision_id,
      numerical_zero_rule = numerical_zero_rule,
      numerical_zero_reason = .data$.numerical_zero_reason,
      raw_value_preserved = TRUE
    )
  hourly <- hourly_with_audit |>
    dplyr::select(
      -"zero_medi_wall_minutes",
      -"positive_medi_wall_minutes",
      -"zero_aware_log_mean_medi",
      -"zero_aware_source_all_zero",
      -dplyr::starts_with(".numerical_zero_")
    )
  numerical_zero_audit <- dplyr::bind_rows(
    daily_numerical_zero_audit,
    hourly_numerical_zero_audit
  ) |>
    dplyr::arrange(
      .data$site,
      .data$Id,
      .data$position,
      .data$local_date,
      .data$metric,
      .data$clock_hour
    )

  participant_metrics <- derive_participant_is_iv(
    true_grid,
    profile_variant = profile_variant
  )
  participant_values <- participant_metric_values_long(participant_metrics)
  metric_values <- dplyr::bind_rows(daily_values, participant_values) |>
    dplyr::arrange(
      .data$site,
      .data$Id,
      .data$position,
      .data$analysis_unit,
      .data$metric,
      .data$local_date
    )
  admissibility <- metric_values |>
    dplyr::select(
      dplyr::any_of(c(
        metric_day_key,
        "profile_variant",
        "analysis_unit",
        "metric",
        "state_domain",
        "estimable",
        "failure_reason",
        "descriptive_nonconfirmatory",
        "left_censored",
        "right_censored",
        "any_censored"
      ))
    )

  expected_days <- nrow(metric_participant_day_index(coverage))
  if (
    nrow(daily_metrics) != expected_days ||
      nrow(thirty_minute) != expected_days * 48L ||
      nrow(hourly) != expected_days * 24L
  ) {
    abort_pipeline(
      "%s metric outputs did not retain the complete eligible-day grids",
      placement
    )
  }
  mder_support <- support |>
    dplyr::filter(.data$metric == "mder_mean_of_viable_ratios")
  if (
    nrow(mder_support) != expected_days ||
      any(
        mder_support$minimum_support !=
          minimum_mder_viable_fraction
      ) ||
      anyNA(mder_support$support_threshold_enforced) ||
      !all(mder_support$support_threshold_enforced) ||
      anyNA(mder_support$ratio_scaled_or_weighted) ||
      any(mder_support$ratio_scaled_or_weighted) ||
      any(
        !is.na(mder_support$failure_reason) &
          !mder_support$failure_reason %in% mder_metric_failure_reasons
      ) ||
      any(
        mder_support$estimable !=
          (mder_support$passes_ordinary_support &
            is.na(mder_support$failure_reason))
      )
  ) {
    abort_pipeline(
      "%s MDER support enforcement did not reconcile to retained days",
      placement
    )
  }
  prohibited_labels <- c(
    names(daily_metrics),
    names(thirty_minute),
    names(hourly),
    unique(metric_values$metric)
  )
  if (any(grepl("L5", prohibited_labels, fixed = TRUE))) {
    abort_pipeline("An excluded darkest-five-hour label entered metric output")
  }

  list(
    daily_metrics = daily_metrics,
    participant_metrics = participant_metrics,
    thirty_minute = thirty_minute,
    hourly = hourly,
    metric_values = metric_values,
    admissibility = admissibility,
    support = support,
    state_support_candidates = state_support_candidates,
    censoring = censoring,
    gap = gap,
    numerical_zero_audit = numerical_zero_audit,
    true_grid = true_grid
  )
}
