# Prepare learning rows and validate the reference profiles.

validate_reference_profile_input <- function(
  data,
  placement,
  object = deparse(substitute(data))
) {
  if (!is.data.frame(data)) {
    abort_pipeline("%s must be a data frame", object)
  }
  required <- c(
    "site",
    "Id",
    "position",
    "datetime_utc",
    "datetime_wall",
    "local_date",
    "clock_minute",
    "State.Brown",
    "MEDI_eligible",
    "LIGHT_eligible"
  )
  assert_columns(data, required, object = object)
  assert_no_missing_key(
    data,
    c(
      "site",
      "Id",
      "position",
      "datetime_utc",
      "datetime_wall",
      "local_date",
      "clock_minute"
    ),
    object = object
  )
  assert_unique_key(
    data,
    c("site", "Id", "position", "datetime_utc"),
    object = object
  )
  if (
    !inherits(data$datetime_utc, "POSIXct") ||
      !inherits(data$datetime_wall, "POSIXct") ||
      !inherits(data$local_date, "Date")
  ) {
    abort_pipeline(
      paste0(
        "%s must contain POSIXct `datetime_utc`/`datetime_wall` ",
        "and Date `local_date`"
      ),
      object
    )
  }
  if (
    !identical(lubridate::tz(data$datetime_utc), "UTC") ||
      !identical(lubridate::tz(data$datetime_wall), "UTC")
  ) {
    abort_pipeline(
      "%s must retain UTC true-instant and pseudo-local wall coordinates",
      object
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
    abort_pipeline(
      "%s has invalid pseudo-local clock minutes",
      object
    )
  }
  observed_placements <- unique(as.character(data$position))
  if (!identical(observed_placements, placement)) {
    abort_pipeline(
      "%s contains placement value(s) %s; expected only %s",
      object,
      paste(observed_placements, collapse = ", "),
      placement
    )
  }
  allowed_states <- c("wake", "pre-sleep", "sleep")
  observed_states <- unique(as.character(data$State.Brown))
  invalid_states <- observed_states[
    !is.na(observed_states) & !observed_states %in% allowed_states
  ]
  if (length(invalid_states) > 0L) {
    abort_pipeline(
      "%s contains unknown diary state(s): %s",
      object,
      paste(sort(invalid_states), collapse = ", ")
    )
  }
  for (signal in c("MEDI_eligible", "LIGHT_eligible")) {
    value <- data[[signal]]
    if (
      !is.numeric(value) ||
        any(!is.na(value) & (!is.finite(value) | value < 0))
    ) {
      abort_pipeline(
        "%s must contain only finite non-negative values or NA in `%s`",
        object,
        signal
      )
    }
  }
  invalid_medi <- is.finite(data$MEDI_eligible) &
    data$MEDI_eligible >= 100000
  if (any(invalid_medi)) {
    abort_pipeline(
      paste0(
        "%s contains %d eligible MEDI value(s) at or above the approved ",
        "100000 lx operating boundary"
      ),
      object,
      sum(invalid_medi)
    )
  }
  invisible(data)
}

finite_mean_or_na <- function(value) {
  finite <- is.finite(value)
  if (!any(finite)) {
    return(NA_real_)
  }
  mean(value[finite])
}

single_state_or_na <- function(value) {
  observed <- unique(as.character(value[!is.na(value)]))
  if (length(observed) == 0L) {
    return(NA_character_)
  }
  observed[[1L]]
}

assert_reference_profile_wall_reconciliation <- function(
  source,
  collapsed,
  state_domain,
  object
) {
  true_utc_key <- c("site", "Id", "position", "datetime_utc")
  wall_key <- c("site", "Id", "position", "local_date", "clock_minute")
  domain_label <- paste0(object, " [", state_domain, "]")

  assert_unique_key(
    source,
    true_utc_key,
    object = paste0(domain_label, " true-UTC source")
  )
  assert_unique_key(
    collapsed,
    wall_key,
    object = paste0(domain_label, " wall-clock learning plane")
  )

  expected_wall_keys <- nrow(unique(source[wall_key]))
  if (nrow(collapsed) != expected_wall_keys) {
    abort_pipeline(
      paste0(
        "%s produced %d wall-clock key(s), but %d unique key(s) ",
        "were present in its true-UTC source"
      ),
      domain_label,
      nrow(collapsed),
      expected_wall_keys
    )
  }
  if (
    sum(collapsed$source_real_minutes) != nrow(source) ||
      sum(collapsed$distinct_true_utc_minutes) != nrow(source) ||
      any(
        collapsed$source_real_minutes != collapsed$distinct_true_utc_minutes
      )
  ) {
    abort_pipeline(
      "%s true-UTC rows did not reconcile after wall-key collapse",
      domain_label
    )
  }

  for (signal in c("MEDI", "LIGHT")) {
    source_column <- paste0(signal, "_eligible")
    count_column <- paste0(signal, "_finite_true_minutes")
    expected_finite <- sum(is.finite(source[[source_column]]))
    observed_finite <- sum(collapsed[[count_column]])
    if (observed_finite != expected_finite) {
      abort_pipeline(
        paste0(
          "%s reconciled %d finite %s true minute(s), but ",
          "%d were present in its source"
        ),
        domain_label,
        observed_finite,
        signal,
        expected_finite
      )
    }
  }

  if (
    !identical(state_domain, "full_day") &&
      any(
        is.na(collapsed$State.Brown) |
          collapsed$State.Brown != state_domain
      )
  ) {
    abort_pipeline(
      "%s contains a row outside its diary-state domain",
      domain_label
    )
  }
  invisible(collapsed)
}

collapse_reference_profile_wall_minutes <- function(
  data,
  state_domain = c("full_day", "wake", "pre-sleep", "sleep"),
  object = deparse(substitute(data))
) {
  state_domain <- match.arg(state_domain)
  if (!identical(state_domain, "full_day")) {
    data <- data[
      !is.na(data$State.Brown) &
        data$State.Brown == state_domain,
      ,
      drop = FALSE
    ]
  }
  keys <- c("site", "Id", "position", "local_date", "clock_minute")
  collapsed <- data |>
    dplyr::group_by(dplyr::across(dplyr::all_of(keys))) |>
    dplyr::summarise(
      diary_states = dplyr::n_distinct(.data$State.Brown, na.rm = TRUE),
      wall_coordinates = dplyr::n_distinct(.data$datetime_wall),
      datetime_wall = dplyr::first(.data$datetime_wall),
      true_utc_start = min(.data$datetime_utc),
      true_utc_end = max(.data$datetime_utc),
      source_real_minutes = dplyr::n(),
      distinct_true_utc_minutes = dplyr::n_distinct(.data$datetime_utc),
      source_utc_offsets = if ("utc_offset_minutes" %in% names(data)) {
        paste(
          sort(unique(.data$utc_offset_minutes)),
          collapse = "|"
        )
      } else {
        NA_character_
      },
      State.Brown = dplyr::case_when(
        .data$diary_states == 0L ~ NA_character_,
        .data$diary_states == 1L ~ single_state_or_na(.data$State.Brown),
        TRUE ~ "mixed"
      ),
      MEDI_finite_true_minutes = sum(is.finite(.data$MEDI_eligible)),
      LIGHT_finite_true_minutes = sum(is.finite(.data$LIGHT_eligible)),
      MEDI_eligible = finite_mean_or_na(.data$MEDI_eligible),
      LIGHT_eligible = finite_mean_or_na(.data$LIGHT_eligible),
      .groups = "drop"
    )
  state_conflicts <- collapsed |>
    dplyr::filter(
      .data$wall_coordinates != 1L |
        (!identical(state_domain, "full_day") & .data$diary_states > 1L)
    )
  if (nrow(state_conflicts) > 0L) {
    abort_pipeline(
      paste0(
        "%s has %d repeated wall-minute key(s) with an inconsistent ",
        "state-specific diary domain or pseudo-local coordinate"
      ),
      object,
      nrow(state_conflicts)
    )
  }

  collapsed <- collapsed |>
    dplyr::select(
      -dplyr::all_of(c("diary_states", "wall_coordinates"))
    ) |>
    dplyr::mutate(
      wall_dst_fold = .data$distinct_true_utc_minutes > 1L,
      state_domain = state_domain,
      clock_bin = clock_bin(.data$clock_minute, bin_minutes = 30L)
    ) |>
    dplyr::arrange(
      .data$site,
      .data$Id,
      .data$position,
      .data$local_date,
      .data$clock_minute
    )

  assert_reference_profile_wall_reconciliation(
    source = data,
    collapsed = collapsed,
    state_domain = state_domain,
    object = object
  )
  collapsed
}

profile_training_rows <- function(
  wall_minutes,
  signal,
  state_domain,
  skeleton_wall_minutes = wall_minutes,
  object = deparse(substitute(wall_minutes))
) {
  signal <- match.arg(signal, c("MEDI", "LIGHT"))
  state_domain <- match.arg(
    state_domain,
    c("full_day", "wake", "pre-sleep", "sleep")
  )
  value_col <- paste0(signal, "_eligible")
  required <- c(
    "site",
    "Id",
    "position",
    "local_date",
    "clock_bin",
    "State.Brown",
    value_col
  )
  assert_columns(wall_minutes, required, object = object)

  selected <- if (identical(state_domain, "full_day")) {
    wall_minutes
  } else {
    wall_minutes[
      !is.na(wall_minutes$State.Brown) &
        wall_minutes$State.Brown == state_domain,
      ,
      drop = FALSE
    ]
  }
  selected <- selected |>
    dplyr::transmute(
      .data$site,
      .data$Id,
      placement = as.character(.data$position),
      .data$local_date,
      .data$clock_bin,
      state_domain = .env$state_domain,
      signal = .env$signal,
      profile_value = .data[[value_col]]
    )

  # Explicit zero-support strata are retained without inventing observations.
  # One all-missing skeleton row per site lets the profile grid represent a
  # diary state that is wholly absent at that site.
  skeleton <- skeleton_wall_minutes |>
    dplyr::group_by(.data$site) |>
    dplyr::slice_head(n = 1L) |>
    dplyr::ungroup() |>
    dplyr::transmute(
      .data$site,
      .data$Id,
      placement = as.character(.data$position),
      .data$local_date,
      .data$clock_bin,
      state_domain = .env$state_domain,
      signal = .env$signal,
      profile_value = NA_real_
    )
  dplyr::bind_rows(selected, skeleton)
}

timing_distribution_training_rows <- function(
  wall_minutes,
  object = deparse(substitute(wall_minutes))
) {
  required <- c(
    "site",
    "Id",
    "position",
    "local_date",
    "clock_minute",
    "clock_bin",
    "MEDI_eligible"
  )
  assert_columns(wall_minutes, required, object = object)
  assert_no_missing_key(
    wall_minutes,
    c(
      "site",
      "Id",
      "position",
      "local_date",
      "clock_minute",
      "clock_bin"
    ),
    object = object
  )
  assert_unique_key(
    wall_minutes,
    c("site", "Id", "position", "local_date", "clock_minute"),
    object = paste0(object, " timing-distribution learning rows")
  )

  wall_minutes |>
    dplyr::transmute(
      .data$site,
      .data$Id,
      placement = as.character(.data$position),
      .data$local_date,
      .data$clock_minute,
      .data$clock_bin,
      state_domain = "full_day",
      signal = "MEDI",
      profile_value = .data$MEDI_eligible
    )
}

summarise_profile_support <- function(profiles) {
  grouping <- c(
    "profile_scope",
    "profile_variant",
    "profile_site",
    "held_out_site",
    "placement",
    "state_domain",
    "signal"
  )
  profiles |>
    dplyr::group_by(dplyr::across(dplyr::all_of(grouping))) |>
    dplyr::summarise(
      training_sites = dplyr::first(.data$training_sites),
      training_site_count = dplyr::first(.data$training_site_count),
      clock_bins = dplyr::n(),
      supported_bins = sum(.data$profile_supported),
      unsupported_bins = sum(!.data$profile_supported),
      no_observation_bins = sum(
        .data$support_reason == "no_finite_observations"
      ),
      below_participant_minimum_bins = sum(
        .data$support_reason == "below_minimum_participants"
      ),
      minimum_required_participants = dplyr::first(
        .data$minimum_participants
      ),
      minimum_bin_participants = min(.data$participants),
      median_bin_participants = stats::median(.data$participants),
      maximum_bin_participants = max(.data$participants),
      minimum_bin_participant_days = min(.data$participant_days),
      median_bin_participant_days = stats::median(.data$participant_days),
      maximum_bin_participant_days = max(.data$participant_days),
      finite_wall_minute_observations = sum(.data$observations),
      profile_complete = dplyr::first(.data$profile_complete),
      profile_estimable = dplyr::first(.data$profile_estimable),
      reference_total = dplyr::first(.data$reference_total),
      .groups = "drop"
    ) |>
    dplyr::arrange(
      .data$profile_scope,
      .data$profile_variant,
      .data$placement,
      .data$state_domain,
      .data$signal
    )
}

summarise_exceedance_distribution_support <- function(
  distribution_profiles
) {
  grouping <- c(
    "profile_scope",
    "profile_variant",
    "profile_site",
    "held_out_site",
    "placement",
    "state_domain",
    "signal"
  )
  distribution_profiles |>
    dplyr::group_by(dplyr::across(dplyr::all_of(grouping))) |>
    dplyr::summarise(
      training_sites = dplyr::first(.data$training_sites),
      training_site_count = dplyr::first(.data$training_site_count),
      clock_bins = dplyr::n(),
      supported_bins = sum(.data$profile_supported),
      unsupported_bins = sum(!.data$profile_supported),
      no_valid_minute_bins = sum(
        .data$support_reason == "no_valid_minutes"
      ),
      below_participant_minimum_bins = sum(
        .data$support_reason == "below_minimum_participants"
      ),
      nonzero_probability_bins = sum(
        .data$profile_supported &
          .data$exceedance_probability > 0,
        na.rm = TRUE
      ),
      minimum_required_participants = dplyr::first(
        .data$minimum_participants
      ),
      minimum_bin_participants = min(.data$participants),
      median_bin_participants = stats::median(.data$participants),
      maximum_bin_participants = max(.data$participants),
      minimum_bin_participant_days = min(.data$participant_days),
      median_bin_participant_days = stats::median(.data$participant_days),
      maximum_bin_participant_days = max(.data$participant_days),
      valid_wall_minutes = sum(.data$valid_minutes),
      exceedance_wall_minutes = sum(.data$exceedance_minutes),
      profile_complete = dplyr::first(.data$profile_complete),
      profile_estimable = dplyr::first(.data$profile_estimable),
      probability_total = dplyr::first(.data$probability_total),
      .groups = "drop"
    ) |>
    dplyr::arrange(
      .data$profile_scope,
      .data$profile_variant,
      .data$placement,
      .data$state_domain,
      .data$signal
    )
}

summarise_relevance_map_support <- function(maps) {
  grouping <- c(
    "profile_scope",
    "profile_variant",
    "profile_site",
    "held_out_site",
    "placement",
    "state_domain",
    "signal",
    "metric_map"
  )
  maps |>
    dplyr::group_by(dplyr::across(dplyr::all_of(grouping))) |>
    dplyr::summarise(
      map_application = dplyr::first(.data$map_application),
      clock_bins = dplyr::n(),
      supported_profile_bins = sum(.data$profile_supported),
      finite_weight_bins = sum(is.finite(.data$relevance_weight)),
      relevance_weight_sum = sum(.data$relevance_weight, na.rm = TRUE),
      map_estimable = dplyr::first(.data$map_estimable),
      value_correction_allowed = dplyr::first(
        .data$value_correction_allowed
      ),
      ratio_correction_allowed = dplyr::first(
        .data$ratio_correction_allowed
      ),
      paired_channel_required = dplyr::first(
        .data$paired_channel_required
      ),
      .groups = "drop"
    ) |>
    dplyr::arrange(
      .data$profile_scope,
      .data$profile_variant,
      .data$placement,
      .data$state_domain,
      .data$signal,
      .data$metric_map
    )
}

validate_reference_profile_outputs <- function(
  profiles,
  distribution_profiles,
  maps,
  placements,
  bin_minutes
) {
  expected_domains <- c("full_day", "wake", "pre-sleep", "sleep")
  expected_signals <- c("MEDI", "LIGHT")
  assert_columns(
    profiles,
    c(
      "placement",
      "state_domain",
      "signal",
      "clock_bin",
      "profile_supported",
      "supported_reference_value"
    ),
    object = "fixed reference profiles"
  )
  if (
    !setequal(unique(profiles$placement), placements) ||
      !setequal(unique(profiles$state_domain), expected_domains) ||
      !setequal(unique(profiles$signal), expected_signals)
  ) {
    abort_pipeline(
      "Reference-profile placement, state-domain, or signal strata are incomplete"
    )
  }
  expected_bins <- seq.int(0L, 1440L - bin_minutes, by = bin_minutes)
  if (!setequal(unique(profiles$clock_bin), expected_bins)) {
    abort_pipeline(
      "Reference profiles do not contain the complete %d-minute clock grid",
      bin_minutes
    )
  }
  profile_key <- c(
    "profile_scope",
    "profile_variant",
    "placement",
    "state_domain",
    "signal",
    "clock_bin"
  )
  assert_unique_key(
    profiles,
    profile_key,
    object = "fixed reference profiles"
  )
  if (
    any(
      !profiles$profile_supported &
        !is.na(profiles$supported_reference_value)
    )
  ) {
    abort_pipeline(
      "Unsupported profile bins received a reference value"
    )
  }
  validate_exceedance_distribution_profiles(distribution_profiles)
  if (
    !setequal(unique(distribution_profiles$placement), placements) ||
      !identical(unique(as.character(distribution_profiles$state_domain)), "full_day") ||
      !identical(unique(toupper(as.character(distribution_profiles$signal))), "MEDI") ||
      !setequal(unique(distribution_profiles$clock_bin), expected_bins)
  ) {
    abort_pipeline(
      paste0(
        "Timing distributions do not contain the complete full-day MEDI ",
        "placement and clock-bin strata"
      )
    )
  }
  if ("L5" %in% maps$metric_map) {
    abort_pipeline("L5 is not permitted in the fixed relevance maps")
  }
  validate_relevance_weight_normalization(maps)
  invisible(TRUE)
}
