# Canonical Preparation 03 executor.
#
# Reference profiles are learned once on a pseudo-local wall-clock plane and
# are fixed before participant-day metric calculation. Preparation 02 true-UTC
# rows remain immutable inputs and are identified by their SHA-256 checksums.

normalise_profile_run_label <- function(run_label = "full") {
  if (
    !is.character(run_label) ||
      length(run_label) != 1L ||
      is.na(run_label) ||
      !nzchar(trimws(run_label))
  ) {
    abort_pipeline("`run_label` must be one non-empty character value")
  }
  run_label <- trimws(run_label)
  if (!grepl("^[A-Za-z0-9._-]+$", run_label)) {
    abort_pipeline(
      paste0(
        "`run_label` may contain only letters, numbers, dots, ",
        "underscores, and hyphens"
      )
    )
  }
  run_label
}

normalise_profile_optional_root <- function(
  path,
  argument,
  must_work = FALSE
) {
  if (is.null(path)) {
    return(NULL)
  }
  if (
    !is.character(path) ||
      length(path) != 1L ||
      is.na(path) ||
      !nzchar(trimws(path))
  ) {
    abort_pipeline("`%s` must be NULL or one non-empty path", argument)
  }
  normalizePath(
    trimws(path),
    winslash = "/",
    mustWork = must_work
  )
}

reference_profile_run_layout <- function(
  paths,
  run_label = "full",
  coverage_run_root = NULL,
  profile_run_root = NULL
) {
  run_label <- normalise_profile_run_label(run_label)
  coverage_run_root <- normalise_profile_optional_root(
    coverage_run_root,
    "coverage_run_root",
    must_work = TRUE
  )
  profile_run_root <- normalise_profile_optional_root(
    profile_run_root,
    "profile_run_root",
    must_work = FALSE
  )
  if (is.null(coverage_run_root)) {
    coverage_run_root <- if (identical(run_label, "full")) {
      paths$coverage
    } else {
      file.path(paths$coverage, "runs", run_label)
    }
  }
  if (is.null(profile_run_root)) {
    profile_run_root <- if (identical(run_label, "full")) {
      paths$profiles
    } else {
      file.path(paths$profiles, "runs", run_label)
    }
  }
  list(
    run_label = run_label,
    coverage_run_root = coverage_run_root,
    profile_run_root = profile_run_root,
    manifest_suffix = if (identical(run_label, "full")) {
      ""
    } else {
      paste0("_", run_label)
    }
  )
}

discover_coverage_profile_placements <- function(coverage_run_root) {
  candidates <- list.files(
    coverage_run_root,
    pattern = "^light_[A-Za-z0-9._-]+_coverage[.]rds$",
    full.names = FALSE
  )
  placements <- sub(
    "^light_(.+)_coverage[.]rds$",
    "\\1",
    candidates
  )
  sort(unique(placements))
}

resolve_profile_placements <- function(placements, coverage_run_root) {
  available <- discover_coverage_profile_placements(coverage_run_root)
  if (length(available) == 0L) {
    abort_pipeline(
      "No coverage artifacts were found under %s",
      coverage_run_root
    )
  }
  if (is.null(placements) || length(placements) == 0L) {
    return(available)
  }
  placements <- sort(unique(trimws(as.character(placements))))
  if (
    length(placements) == 0L ||
      anyNA(placements) ||
      any(!nzchar(placements)) ||
      any(!grepl("^[A-Za-z0-9._-]+$", placements))
  ) {
    abort_pipeline(
      "`placements` must contain non-missing placement labels"
    )
  }
  missing <- setdiff(placements, available)
  if (length(missing) > 0L) {
    abort_pipeline(
      "Missing coverage artifact(s) for placement(s): %s",
      paste(missing, collapse = ", ")
    )
  }
  placements
}

read_primary_coverage_settings <- function(
  coverage_run_root,
  placements,
  run_label
) {
  settings_path <- file.path(coverage_run_root, "coverage_settings.csv")
  if (!file.exists(settings_path)) {
    abort_pipeline(
      "Required Preparation 02 settings do not exist: %s",
      settings_path
    )
  }
  settings <- readr::read_csv(
    settings_path,
    show_col_types = FALSE,
    progress = FALSE
  )
  required <- c(
    "run_label",
    "placement",
    "coverage_rule_id",
    "coverage_signal",
    "daily_denominator_domain",
    "diary_sleep_excluded_from_denominator",
    "expected_wall_minutes_per_hour",
    "expected_wall_minutes_per_day",
    "minimum_hour_coverage",
    "minimum_day_coverage"
  )
  assert_columns(
    settings,
    required,
    object = "Preparation 02 coverage settings"
  )
  assert_no_missing_key(
    settings,
    c("run_label", "placement"),
    object = "Preparation 02 coverage settings"
  )
  assert_unique_key(
    settings,
    "placement",
    object = "Preparation 02 coverage settings"
  )
  if (!setequal(as.character(settings$placement), placements)) {
    abort_pipeline(
      paste0(
        "Preparation 02 settings placements do not match the requested ",
        "profile placements"
      )
    )
  }
  if (any(settings$run_label != run_label)) {
    abort_pipeline(
      "Preparation 02 settings do not match run label '%s'",
      run_label
    )
  }
  expected <- list(
    coverage_rule_id = "A",
    coverage_signal = "MEDI",
    daily_denominator_domain = "all_pseudo_local_wall_minutes",
    diary_sleep_excluded_from_denominator = FALSE,
    expected_wall_minutes_per_hour = 60,
    expected_wall_minutes_per_day = 1440,
    minimum_hour_coverage = 0.5,
    minimum_day_coverage = 0.8
  )
  mismatch <- vapply(
    names(expected),
    function(column) {
      value <- settings[[column]]
      anyNA(value) || any(value != expected[[column]])
    },
    logical(1)
  )
  if (any(mismatch)) {
    abort_pipeline(
      paste0(
        "Preparation 02 settings do not implement approved primary ",
        "coverage rule A in: %s"
      ),
      paste(names(expected)[mismatch], collapse = ", ")
    )
  }
  list(
    data = dplyr::arrange(settings, .data$placement),
    path = normalizePath(settings_path, winslash = "/", mustWork = TRUE),
    sha256 = artifact_sha256(settings_path)
  )
}

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

profile_input_provenance <- function(
  input,
  wall_minutes,
  placement,
  input_path,
  input_sha256
) {
  input_info <- file.info(input_path)
  input_start <- min(input$datetime_utc)
  input_end <- max(input$datetime_utc)
  dplyr::bind_rows(lapply(c("MEDI", "LIGHT"), function(signal) {
    value_col <- paste0(signal, "_eligible")
    tibble::tibble(
      placement = placement,
      signal = signal,
      input_path = normalizePath(
        input_path,
        winslash = "/",
        mustWork = TRUE
      ),
      input_sha256 = input_sha256,
      input_bytes = unname(input_info$size),
      input_sites = dplyr::n_distinct(input$site),
      input_participants = nrow(dplyr::distinct(
        input,
        .data$site,
        .data$Id
      )),
      input_participant_days = nrow(dplyr::distinct(
        input,
        .data$site,
        .data$Id,
        .data$position,
        .data$local_date
      )),
      input_true_utc_minutes = nrow(input),
      input_true_utc_start = format(input_start, tz = "UTC", usetz = TRUE),
      input_true_utc_end = format(input_end, tz = "UTC", usetz = TRUE),
      eligible_true_utc_minutes = sum(is.finite(input[[value_col]])),
      learning_wall_minutes = nrow(wall_minutes),
      eligible_learning_wall_minutes = sum(
        is.finite(wall_minutes[[value_col]])
      ),
      repeated_wall_keys = sum(
        wall_minutes$source_real_minutes > 1L
      ),
      mixed_state_wall_keys = sum(
        wall_minutes$State.Brown == "mixed",
        na.rm = TRUE
      ),
      repeated_mixed_state_wall_keys = sum(
        wall_minutes$source_real_minutes > 1L &
          wall_minutes$State.Brown == "mixed",
        na.rm = TRUE
      ),
      repeated_wall_minutes_averaged = sum(
        wall_minutes$source_real_minutes > 1L
      ),
      repeated_wall_minutes_with_mixed_state = sum(
        wall_minutes$source_real_minutes > 1L &
          wall_minutes$State.Brown == "mixed",
        na.rm = TRUE
      ),
      additional_true_rows_in_repeated_minutes = sum(
        pmax(wall_minutes$source_real_minutes - 1L, 0L)
      ),
      maximum_true_rows_per_wall_minute = max(
        wall_minutes$source_real_minutes
      ),
      clock_coordinate = "pseudo_local_wall_clock",
      absolute_coordinate = "datetime_utc_preserved_in_input"
    )
  }))
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

build_reference_profiles <- function(
  root = project_root(),
  run_label = "full",
  coverage_run_root = NULL,
  profile_run_root = NULL,
  placements = NULL,
  bin_minutes = 30L,
  pooled_full_day_min = 20L,
  leave_one_site_out_full_day_min = 20L,
  state_specific_min = 5L,
  site_specific_min = 5L,
  zero_offset = 0.1
) {
  producer <- "scripts/pipeline/build_reference_profiles.R"
  if (!identical(as.integer(bin_minutes), 30L)) {
    abort_pipeline(
      "`bin_minutes` must remain at the approved 30-minute resolution"
    )
  }
  bin_minutes <- as.integer(bin_minutes)
  pooled_full_day_min <- check_profile_minimum(
    pooled_full_day_min,
    "pooled_full_day_min"
  )
  leave_one_site_out_full_day_min <- check_profile_minimum(
    leave_one_site_out_full_day_min,
    "leave_one_site_out_full_day_min"
  )
  state_specific_min <- check_profile_minimum(
    state_specific_min,
    "state_specific_min"
  )
  site_specific_min <- check_profile_minimum(
    site_specific_min,
    "site_specific_min"
  )
  if (
    length(zero_offset) != 1L ||
      !is.numeric(zero_offset) ||
      !is.finite(zero_offset) ||
      zero_offset <= 0
  ) {
    abort_pipeline("`zero_offset` must be one finite positive value")
  }

  paths <- pipeline_paths(root)
  ensure_pipeline_directories(paths)
  run_layout <- reference_profile_run_layout(
    paths = paths,
    run_label = run_label,
    coverage_run_root = coverage_run_root,
    profile_run_root = profile_run_root
  )
  dir.create(
    run_layout$profile_run_root,
    recursive = TRUE,
    showWarnings = FALSE
  )
  placements <- resolve_profile_placements(
    placements,
    run_layout$coverage_run_root
  )
  coverage_settings <- read_primary_coverage_settings(
    coverage_run_root = run_layout$coverage_run_root,
    placements = placements,
    run_label = run_layout$run_label
  )

  profile_sets <- list()
  distribution_sets <- list()
  provenance_sets <- list()
  input_hashes <- character(length(placements))
  names(input_hashes) <- placements
  domains <- c("full_day", "wake", "pre-sleep", "sleep")
  signals <- c("MEDI", "LIGHT")

  for (placement in placements) {
    message("Learning fixed reference profiles for ", placement)
    input_path <- file.path(
      run_layout$coverage_run_root,
      paste0("light_", placement, "_coverage.rds")
    )
    input_sha256 <- artifact_sha256(input_path)
    input_hashes[[placement]] <- input_sha256
    coverage <- dplyr::ungroup(read_rds_artifact(
      input_path,
      expected_class = "data.frame"
    ))
    validate_reference_profile_input(
      coverage,
      placement = placement,
      object = paste0(placement, " coverage artifact")
    )
    wall_planes <- stats::setNames(
      lapply(domains, function(state_domain) {
        collapse_reference_profile_wall_minutes(
          coverage,
          state_domain = state_domain,
          object = paste0(
            placement,
            " ",
            state_domain,
            " coverage artifact"
          )
        )
      }),
      domains
    )
    wall_minutes <- wall_planes$full_day
    provenance_sets[[placement]] <- profile_input_provenance(
      input = coverage,
      wall_minutes = wall_minutes,
      placement = placement,
      input_path = input_path,
      input_sha256 = input_sha256
    )

    placement_profiles <- list()
    for (signal in signals) {
      for (state_domain in domains) {
        training <- profile_training_rows(
          wall_planes[[state_domain]],
          signal = signal,
          state_domain = state_domain,
          skeleton_wall_minutes = wall_minutes,
          object = paste0(placement, " wall-clock learning plane")
        )
        label <- paste(signal, state_domain, sep = "/")
        placement_profiles[[label]] <- learn_reference_profile_set(
          data = training,
          value_col = "profile_value",
          participant_col = "Id",
          participant_day_col = "local_date",
          site_col = "site",
          clock_bin_col = "clock_bin",
          strata = c("placement", "state_domain", "signal"),
          bin_minutes = bin_minutes,
          variants = c(
            "pooled",
            "site_specific",
            "leave_one_site_out"
          ),
          pooled_full_day_min = pooled_full_day_min,
          leave_one_site_out_full_day_min = leave_one_site_out_full_day_min,
          state_specific_min = state_specific_min,
          site_specific_min = site_specific_min
        )
      }
    }
    distribution_training <- timing_distribution_training_rows(
      wall_minutes,
      object = paste0(
        placement,
        " full-day wall-clock learning plane"
      )
    )
    distribution_sets[[placement]] <-
      learn_exceedance_distribution_profile_set(
        data = distribution_training,
        value_col = "profile_value",
        participant_col = "Id",
        participant_day_col = "local_date",
        site_col = "site",
        clock_minute_col = "clock_minute",
        clock_bin_col = "clock_bin",
        strata = c("placement", "state_domain", "signal"),
        bin_minutes = bin_minutes,
        threshold = 250,
        variants = c(
          "pooled",
          "site_specific",
          "leave_one_site_out"
        ),
        pooled_full_day_min = pooled_full_day_min,
        leave_one_site_out_full_day_min =
          leave_one_site_out_full_day_min,
        state_specific_min = state_specific_min,
        site_specific_min = site_specific_min
      )
    profile_sets[[placement]] <- dplyr::bind_rows(placement_profiles)
    if (artifact_sha256(input_path) != input_sha256) {
      abort_pipeline(
        "%s input changed while its fixed profiles were being learned",
        placement
      )
    }
    rm(
      coverage,
      wall_planes,
      wall_minutes,
      placement_profiles,
      distribution_training
    )
    invisible(gc())
  }

  provenance <- dplyr::bind_rows(provenance_sets) |>
    dplyr::arrange(.data$placement, .data$signal)
  profiles <- dplyr::bind_rows(profile_sets) |>
    dplyr::arrange(
      .data$profile_scope,
      .data$profile_variant,
      .data$placement,
      .data$state_domain,
      .data$signal,
      .data$clock_bin
    )
  attr(profiles, "profile_learning") <-
    "fixed_once_before_participant_day_metrics"
  attr(profiles, "profile_strata") <- c(
    "placement",
    "state_domain",
    "signal"
  )
  attr(profiles, "bin_minutes") <- bin_minutes
  attr(profiles, "input_provenance") <- provenance

  distribution_profiles <- dplyr::bind_rows(distribution_sets) |>
    dplyr::arrange(
      .data$profile_scope,
      .data$profile_variant,
      .data$placement,
      .data$state_domain,
      .data$signal,
      .data$clock_bin
    )
  attr(distribution_profiles, "profile_learning") <-
    "fixed_once_before_participant_day_metrics"
  attr(distribution_profiles, "profile_strata") <- c(
    "placement",
    "state_domain",
    "signal"
  )
  attr(distribution_profiles, "distribution_profile_type") <-
    "participant_balanced_valid_minute_exceedance_probability"
  attr(distribution_profiles, "bin_minutes") <- bin_minutes
  attr(distribution_profiles, "threshold_lx") <- 250
  attr(distribution_profiles, "comparison") <- "strict_greater_than"
  attr(distribution_profiles, "input_provenance") <- provenance

  maps <- derive_metric_relevance_maps(
    profiles,
    distribution_profiles = distribution_profiles,
    signal_col = "signal",
    clock_bin_col = "clock_bin",
    strata = c("placement", "state_domain"),
    zero_offset = zero_offset
  )
  attr(maps, "profile_learning") <-
    "fixed_once_before_participant_day_metrics"
  attr(maps, "bin_minutes") <- bin_minutes
  validate_reference_profile_outputs(
    profiles,
    distribution_profiles,
    maps,
    placements = placements,
    bin_minutes = bin_minutes
  )

  profile_support <- summarise_profile_support(profiles)
  distribution_support <- summarise_exceedance_distribution_support(
    distribution_profiles
  )
  map_support <- summarise_relevance_map_support(maps)
  input_hash_set <- paste(
    paste(names(input_hashes), input_hashes, sep = "="),
    collapse = "|"
  )
  settings <- tibble::tibble(
    run_label = run_layout$run_label,
    input_coverage_rule_id = "A",
    input_coverage_settings_path = coverage_settings$path,
    input_coverage_settings_sha256 = coverage_settings$sha256,
    input_daily_denominator_domain = "all_pseudo_local_wall_minutes",
    input_diary_sleep_excluded_from_denominator = FALSE,
    profile_learning = "fixed_once_before_participant_day_metrics",
    profile_fit_unit = "placement_by_signal_by_state_domain",
    participant_day_profiles_fitted = FALSE,
    clock_coordinate = "pseudo_local_wall_clock",
    absolute_time_provenance = "true_utc_inputs_immutable_and_hashed",
    dst_fold_rule = "average_repeated_wall_minute_for_clock_learning",
    bin_minutes = bin_minutes,
    participant_balance = "within_participant_bin_median_then_across_participant_median",
    timing_distribution = "participant_day_then_participant_balanced_strict_exceedance_probability",
    timing_distribution_threshold_lx = 250,
    timing_distribution_comparison = "strict_greater_than",
    timing_distribution_day_weighting = "equal_days_within_participant_bin",
    timing_distribution_participant_weighting = "equal_participants_within_profile_bin",
    timing_distribution_fitted_once = TRUE,
    timing_distribution_applies_to = "timing_above_250_support_only",
    timing_distribution_scales_metric_values = FALSE,
    profile_variants = "pooled|site_specific|leave_one_site_out",
    state_domains = paste(domains, collapse = "|"),
    signals = paste(signals, collapse = "|"),
    pooled_full_day_min = pooled_full_day_min,
    leave_one_site_out_full_day_min = leave_one_site_out_full_day_min,
    state_specific_min = state_specific_min,
    site_specific_min = site_specific_min,
    unsupported_bin_rule = "retain_as_unsupported_without_interpolation",
    zero_offset = zero_offset,
    l5_permitted = FALSE,
    profile_rows = nrow(profiles),
    timing_distribution_rows = nrow(distribution_profiles),
    relevance_map_rows = nrow(maps),
    input_hashes = input_hash_set
  )
  attr(profiles, "settings") <- settings
  attr(distribution_profiles, "settings") <- settings
  attr(maps, "settings") <- settings

  artifact_records <- list()
  record_artifact <- function(metadata, label) {
    artifact_records[[label]] <<- manifest_row(metadata)
    invisible(metadata)
  }
  output_paths <- list(
    profiles_rds = file.path(
      run_layout$profile_run_root,
      "reference_profiles.rds"
    ),
    profiles_csv = file.path(
      run_layout$profile_run_root,
      "reference_profiles.csv"
    ),
    timing_distributions_rds = file.path(
      run_layout$profile_run_root,
      "timing_exceedance_distributions.rds"
    ),
    timing_distributions_csv = file.path(
      run_layout$profile_run_root,
      "timing_exceedance_distributions.csv"
    ),
    relevance_maps_rds = file.path(
      run_layout$profile_run_root,
      "metric_relevance_maps.rds"
    ),
    relevance_maps_csv = file.path(
      run_layout$profile_run_root,
      "metric_relevance_maps.csv"
    ),
    profile_support = file.path(
      run_layout$profile_run_root,
      "reference_profile_support.csv"
    ),
    timing_distribution_support = file.path(
      run_layout$profile_run_root,
      "timing_exceedance_distribution_support.csv"
    ),
    map_support = file.path(
      run_layout$profile_run_root,
      "relevance_map_support.csv"
    ),
    provenance = file.path(
      run_layout$profile_run_root,
      "reference_profile_input_provenance.csv"
    ),
    settings = file.path(
      run_layout$profile_run_root,
      "reference_profile_settings.csv"
    )
  )
  common_metadata <- list(
    run_label = run_layout$run_label,
    input_coverage_root = normalizePath(
      run_layout$coverage_run_root,
      winslash = "/",
      mustWork = TRUE
    ),
    input_coverage_rule_id = "A",
    input_coverage_settings_sha256 = coverage_settings$sha256,
    input_hashes = input_hash_set,
    bin_minutes = bin_minutes,
    profile_learning = "fixed_once_before_participant_day_metrics",
    timing_distribution_threshold_lx = 250,
    timing_distribution_comparison = "strict_greater_than",
    timing_distribution_fit_unit =
      "participant_day_then_participant_balanced_clock_bin_probability"
  )
  record_artifact(
    write_rds_artifact(
      profiles,
      output_paths$profiles_rds,
      producer,
      metadata = c(
        list(artifact_type = "fixed_reference_profiles_rds"),
        common_metadata
      )
    ),
    "profiles/rds"
  )
  record_artifact(
    write_csv_artifact(
      profiles,
      output_paths$profiles_csv,
      producer,
      metadata = c(
        list(artifact_type = "fixed_reference_profiles_csv"),
        common_metadata
      )
    ),
    "profiles/csv"
  )
  record_artifact(
    write_rds_artifact(
      distribution_profiles,
      output_paths$timing_distributions_rds,
      producer,
      metadata = c(
        list(
          artifact_type =
            "fixed_timing_exceedance_distributions_rds"
        ),
        common_metadata
      )
    ),
    "timing_distributions/rds"
  )
  record_artifact(
    write_csv_artifact(
      distribution_profiles,
      output_paths$timing_distributions_csv,
      producer,
      metadata = c(
        list(
          artifact_type =
            "fixed_timing_exceedance_distributions_csv"
        ),
        common_metadata
      )
    ),
    "timing_distributions/csv"
  )
  record_artifact(
    write_rds_artifact(
      maps,
      output_paths$relevance_maps_rds,
      producer,
      metadata = c(
        list(artifact_type = "metric_relevance_maps_rds"),
        common_metadata
      )
    ),
    "maps/rds"
  )
  record_artifact(
    write_csv_artifact(
      maps,
      output_paths$relevance_maps_csv,
      producer,
      metadata = c(
        list(artifact_type = "metric_relevance_maps_csv"),
        common_metadata
      )
    ),
    "maps/csv"
  )
  record_artifact(
    write_csv_artifact(
      profile_support,
      output_paths$profile_support,
      producer,
      metadata = c(
        list(artifact_type = "reference_profile_support_diagnostics"),
        common_metadata
      )
    ),
    "diagnostics/profile_support"
  )
  record_artifact(
    write_csv_artifact(
      distribution_support,
      output_paths$timing_distribution_support,
      producer,
      metadata = c(
        list(
          artifact_type =
            "timing_exceedance_distribution_support_diagnostics"
        ),
        common_metadata
      )
    ),
    "diagnostics/timing_distribution_support"
  )
  record_artifact(
    write_csv_artifact(
      map_support,
      output_paths$map_support,
      producer,
      metadata = c(
        list(artifact_type = "relevance_map_support_diagnostics"),
        common_metadata
      )
    ),
    "diagnostics/map_support"
  )
  record_artifact(
    write_csv_artifact(
      provenance,
      output_paths$provenance,
      producer,
      metadata = c(
        list(artifact_type = "reference_profile_input_provenance"),
        common_metadata
      )
    ),
    "audit/provenance"
  )
  record_artifact(
    write_csv_artifact(
      settings,
      output_paths$settings,
      producer,
      metadata = c(
        list(artifact_type = "reference_profile_settings"),
        common_metadata
      )
    ),
    "audit/settings"
  )

  artifact_manifest <- dplyr::bind_rows(artifact_records) |>
    dplyr::arrange(.data$artifact_type, .data$path)
  artifact_manifest_path <- file.path(
    paths$manifests,
    paste0(
      "reference_profile_artifacts",
      run_layout$manifest_suffix,
      ".csv"
    )
  )
  write_csv_artifact(
    artifact_manifest,
    artifact_manifest_path,
    producer,
    metadata = list(
      artifact_type = "reference_profile_artifact_manifest",
      run_label = run_layout$run_label
    )
  )

  list(
    run_label = run_layout$run_label,
    coverage_run_root = run_layout$coverage_run_root,
    profile_run_root = run_layout$profile_run_root,
    placements = placements,
    output_paths = output_paths,
    artifact_manifest_path = artifact_manifest_path,
    profiles = profiles,
    timing_distributions = distribution_profiles,
    relevance_maps = maps,
    profile_support = profile_support,
    timing_distribution_support = distribution_support,
    map_support = map_support,
    provenance = provenance,
    settings = settings,
    coverage_settings = coverage_settings$data
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
    "reference_profiles.R"
  )
  for (dependency in dependencies) {
    source(file.path(
      execution_root,
      "scripts",
      "pipeline",
      dependency
    ))
  }
  run_label <- Sys.getenv(
    "NATHEALTH_PROFILE_RUN_LABEL",
    unset = "full"
  )
  coverage_root <- Sys.getenv(
    "NATHEALTH_COVERAGE_RUN_ROOT",
    unset = ""
  )
  profile_root <- Sys.getenv(
    "NATHEALTH_PROFILE_RUN_ROOT",
    unset = ""
  )
  placement_argument <- Sys.getenv(
    "NATHEALTH_PROFILE_PLACEMENTS",
    unset = ""
  )
  result <- build_reference_profiles(
    root = execution_root,
    run_label = run_label,
    coverage_run_root = if (nzchar(coverage_root)) {
      coverage_root
    } else {
      NULL
    },
    profile_run_root = if (nzchar(profile_root)) {
      profile_root
    } else {
      NULL
    },
    placements = if (nzchar(placement_argument)) {
      strsplit(placement_argument, ",", fixed = TRUE)[[1L]]
    } else {
      NULL
    }
  )
  print(result$settings)
}
