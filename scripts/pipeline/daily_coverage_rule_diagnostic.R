# Compare the selected full-day rule with two fixed sensitivities.

daily_coverage_rule_definitions <- function() {
  tibble::tibble(
    rule = c(
      "A_full_day",
      "B_sleep_excluded_daily",
      "C_sleep_excluded_hourly_daily"
    ),
    rule_label = c(
      "Full 24-hour rule (primary)",
      "Sleep-excluded daily rule",
      "Sleep-excluded hourly and daily rule"
    ),
    hourly_denominator = c(
      "60 wall-clock minutes for hourly summaries only",
      "60 wall-clock minutes",
      "fractional non-sleep wall-minute support"
    ),
    hourly_numerator = c(
      "wall minutes with any finite wall-mean MEDI for hourly summaries only",
      "wall minutes with any finite wall-mean MEDI",
      "fractional finite non-sleep MEDI support"
    ),
    daily_denominator = c(
      "1440 wall-clock minutes",
      "fractional non-sleep wall-minute support",
      "fractional non-sleep wall-minute support"
    ),
    daily_numerator = c(
      "finite wall-mean MEDI across the fixed 24-hour day",
      "fractional finite non-sleep MEDI support in all-minute eligible hours",
      paste0(
        "fractional finite non-sleep MEDI support in wake-support ",
        "eligible hours"
      )
    ),
    full_sleep_hour = c(
      "does not affect daily eligibility; evaluated only for hourly summaries",
      "evaluated against 60 wall-clock minutes",
      "structurally excluded from the waking hourly gate"
    ),
    all_zero_medi_day = c(
      "excluded if the day otherwise passes and every finite melEDI minute is zero",
      "excluded if the day otherwise passes and every finite melEDI minute is zero",
      "excluded if the day otherwise passes and every finite melEDI minute is zero"
    )
  )
}

validate_daily_coverage_rule_input <- function(
  data,
  coverage_signal = "MEDI",
  state_col = "State.Brown",
  id_cols = c("site", "Id", "position"),
  object = deparse(substitute(data))
) {
  if (!is.data.frame(data)) {
    abort_pipeline("%s must be a data frame", object)
  }
  if (
    !is.character(coverage_signal) ||
      length(coverage_signal) != 1L ||
      is.na(coverage_signal) ||
      !nzchar(coverage_signal)
  ) {
    abort_pipeline("`coverage_signal` must be one non-empty column name")
  }
  if (
    !is.character(state_col) ||
      length(state_col) != 1L ||
      is.na(state_col) ||
      !nzchar(state_col)
  ) {
    abort_pipeline("`state_col` must be one non-empty column name")
  }
  if (
    !is.character(id_cols) ||
      length(id_cols) == 0L ||
      anyNA(id_cols) ||
      any(!nzchar(id_cols)) ||
      anyDuplicated(id_cols)
  ) {
    abort_pipeline("`id_cols` must contain unique non-missing column names")
  }
  required <- unique(c(
    id_cols,
    "datetime_utc",
    "datetime_wall",
    "local_date",
    "clock_minute",
    "utc_offset_minutes",
    coverage_signal,
    state_col
  ))
  assert_columns(data, required, object = object)
  assert_no_missing_key(
    data,
    c(id_cols, "datetime_utc", "local_date", "clock_minute"),
    object = object
  )
  assert_unique_key(
    data,
    c(id_cols, "datetime_utc"),
    object = paste0(object, " true-minute rows")
  )
  if (!is.numeric(data[[coverage_signal]])) {
    abort_pipeline(
      "%s coverage signal `%s` must be numeric",
      object,
      coverage_signal
    )
  }
  if (any(is.infinite(data[[coverage_signal]]))) {
    abort_pipeline(
      "%s coverage signal `%s` contains infinite values",
      object,
      coverage_signal
    )
  }
  invisible(data)
}

collapse_waking_wall_support <- function(
  minute_data,
  coverage_signal = "MEDI",
  state_col = "State.Brown",
  sleep_value = "sleep",
  id_cols = c("site", "Id", "position"),
  object = deparse(substitute(minute_data))
) {
  validate_daily_coverage_rule_input(
    minute_data,
    coverage_signal = coverage_signal,
    state_col = state_col,
    id_cols = id_cols,
    object = object
  )
  if (
    !is.character(sleep_value) ||
      length(sleep_value) != 1L ||
      is.na(sleep_value) ||
      !nzchar(sleep_value)
  ) {
    abort_pipeline("`sleep_value` must be one non-empty character value")
  }

  input <- dplyr::ungroup(minute_data)
  state <- as.character(input[[state_col]])
  input$.known_sleep <- !is.na(state) & state == sleep_value
  input$.unknown_state <- is.na(state) | !nzchar(trimws(state))
  input$.finite_coverage_signal <- is.finite(input[[coverage_signal]])
  wall_key <- c(
    id_cols,
    "local_date",
    "clock_minute",
    "datetime_wall"
  )

  support <- input |>
    dplyr::group_by(dplyr::across(dplyr::all_of(wall_key))) |>
    dplyr::summarise(
      state_source_real_minutes = dplyr::n(),
      waking_expected_mass = mean(!.data$.known_sleep),
      waking_valid_mass = mean(
        !.data$.known_sleep & .data$.finite_coverage_signal
      ),
      known_sleep_mass = mean(.data$.known_sleep),
      unknown_state_mass = mean(.data$.unknown_state),
      .groups = "drop"
    )
  assert_unique_key(
    support,
    c(id_cols, "local_date", "clock_minute"),
    object = "fractional wall-clock waking support"
  )
  tolerance <- sqrt(.Machine$double.eps)
  invalid_mass <- vapply(
    support[c(
      "waking_expected_mass",
      "waking_valid_mass",
      "known_sleep_mass",
      "unknown_state_mass"
    )],
    function(value) {
      any(!is.finite(value) | value < 0 | value > 1)
    },
    logical(1)
  )
  if (any(invalid_mass)) {
    abort_pipeline("Fractional wall-clock support fell outside [0, 1]")
  }
  if (
    any(
      support$waking_valid_mass > support$waking_expected_mass + tolerance
    ) ||
      any(
        abs(
          support$waking_expected_mass + support$known_sleep_mass - 1
        ) >
          tolerance
      )
  ) {
    abort_pipeline("Fractional wall-clock waking support is inconsistent")
  }
  support
}

add_waking_support_to_wall_grid <- function(
  wall_grid,
  waking_support,
  id_cols = c("site", "Id", "position")
) {
  wall_key <- c(id_cols, "local_date", "clock_minute")
  support_values <- dplyr::select(
    waking_support,
    -dplyr::all_of("datetime_wall")
  )
  grid <- left_join_checked(
    dplyr::ungroup(wall_grid),
    support_values,
    by = wall_key,
    relationship = "one-to-one",
    x_name = "complete wall-clock coverage grid",
    y_name = "fractional waking support"
  )
  source_count <- dplyr::coalesce(
    as.integer(grid$state_source_real_minutes),
    0L
  )
  if (any(source_count != grid$source_real_minutes)) {
    abort_pipeline(
      "State support does not reconcile to wall-clock source-minute counts"
    )
  }

  source_absent <- source_count == 0L
  grid$state_source_real_minutes <- source_count
  grid$waking_expected_mass <- dplyr::coalesce(
    grid$waking_expected_mass,
    1
  )
  grid$waking_valid_mass <- dplyr::coalesce(
    grid$waking_valid_mass,
    0
  )
  grid$known_sleep_mass <- dplyr::coalesce(grid$known_sleep_mass, 0)
  grid$unknown_state_mass <- dplyr::coalesce(
    grid$unknown_state_mass,
    1
  )
  if (
    any(
      source_absent &
        (grid$waking_expected_mass != 1 |
          grid$waking_valid_mass != 0 |
          grid$known_sleep_mass != 0 |
          grid$unknown_state_mass != 1)
    )
  ) {
    abort_pipeline(
      "Source-absent wall minutes were not retained as unknown support"
    )
  }
  grid
}

evaluate_wake_aware_hourly_gate <- function(
  wall_grid,
  id_cols = c("site", "Id", "position"),
  minimum_hour_coverage = 0.5
) {
  validate_coverage_fraction(
    minimum_hour_coverage,
    argument = "minimum_hour_coverage"
  )
  required <- c(
    id_cols,
    "local_date",
    "clock_hour",
    "waking_expected_mass",
    "waking_valid_mass"
  )
  assert_columns(
    wall_grid,
    required,
    object = "wall grid with waking support"
  )
  wall_grid |>
    dplyr::group_by(
      dplyr::across(dplyr::all_of(c(id_cols, "local_date"))),
      .data$clock_hour
    ) |>
    dplyr::summarise(
      hour_expected_support_minutes = sum(.data$waking_expected_mass),
      hour_valid_support_minutes = sum(.data$waking_valid_mass),
      hour_evaluable = .data$hour_expected_support_minutes > 0,
      hour_valid_fraction = dplyr::if_else(
        .data$hour_evaluable,
        .data$hour_valid_support_minutes /
          .data$hour_expected_support_minutes,
        NA_real_
      ),
      hour_support_pass = !.data$hour_evaluable |
        .data$hour_valid_fraction >= minimum_hour_coverage,
      hour_structurally_excluded = !.data$hour_evaluable,
      .groups = "drop"
    )
}

daily_coverage_rule_detail <- function(
  wall_grid,
  current_daily,
  current_hourly,
  wake_hourly,
  id_cols = c("site", "Id", "position"),
  minimum_hour_coverage = 0.5,
  minimum_day_coverage = 0.8
) {
  day_key <- c(id_cols, "local_date")
  hour_key <- c(day_key, "clock_hour")
  current_hour_lookup <- dplyr::select(
    current_hourly,
    dplyr::all_of(c(hour_key, "hour_eligible"))
  ) |>
    dplyr::rename(
      current_hour_eligible = "hour_eligible"
    )
  current_hour_days <- current_hourly |>
    dplyr::group_by(dplyr::across(dplyr::all_of(day_key))) |>
    dplyr::summarise(
      current_hour_gate_evaluable_hours = dplyr::n(),
      current_hour_gate_pass_hours = sum(.data$hour_eligible),
      current_hour_gate_exempt_hours = 0L,
      .groups = "drop"
    )
  if (any(current_hour_days$current_hour_gate_evaluable_hours != 24L)) {
    abort_pipeline("Current hourly coverage did not produce 24 wall hours")
  }
  wake_hour_days <- wake_hourly |>
    dplyr::group_by(dplyr::across(dplyr::all_of(day_key))) |>
    dplyr::summarise(
      wake_hour_gate_evaluable_hours = sum(.data$hour_evaluable),
      wake_hour_gate_pass_hours = sum(
        .data$hour_support_pass & .data$hour_evaluable
      ),
      wake_hour_gate_exempt_hours = sum(.data$hour_structurally_excluded),
      .groups = "drop"
    )
  if (
    any(
      wake_hour_days$wake_hour_gate_evaluable_hours +
        wake_hour_days$wake_hour_gate_exempt_hours !=
        24L
    )
  ) {
    abort_pipeline("Wake-aware hourly coverage did not classify 24 wall hours")
  }
  wake_hour_lookup <- dplyr::select(
    wake_hourly,
    dplyr::all_of(c(
      hour_key,
      "hour_evaluable",
      "hour_support_pass",
      "hour_structurally_excluded"
    ))
  )
  wake_hour_lookup <- dplyr::rename(
    wake_hour_lookup,
    wake_hour_evaluable = "hour_evaluable",
    wake_hour_support_pass = "hour_support_pass",
    wake_hour_structurally_excluded = "hour_structurally_excluded"
  )
  grid <- left_join_checked(
    wall_grid,
    current_hour_lookup,
    by = hour_key,
    relationship = "many-to-one",
    x_name = "wall grid with waking support",
    y_name = "current hourly coverage"
  )
  grid <- left_join_checked(
    grid,
    wake_hour_lookup,
    by = hour_key,
    relationship = "many-to-one",
    x_name = "wall grid with current hourly coverage",
    y_name = "wake-aware hourly coverage"
  )
  if (
    anyNA(grid$current_hour_eligible) ||
      anyNA(grid$wake_hour_evaluable) ||
      anyNA(grid$wake_hour_support_pass) ||
      anyNA(grid$wake_hour_structurally_excluded)
  ) {
    abort_pipeline("Hourly coverage flags did not map to every wall minute")
  }

  day_support <- grid |>
    dplyr::group_by(dplyr::across(dplyr::all_of(day_key))) |>
    dplyr::summarise(
      day_observed_wall_minutes = sum(.data$minute_present),
      day_source_real_minutes = sum(.data$source_real_minutes),
      day_dst_fold_wall_minutes = sum(.data$dst_fold),
      day_source_absent_wall_minutes = sum(!.data$minute_present),
      day_waking_expected_minutes = sum(.data$waking_expected_mass),
      day_waking_valid_minutes_raw = sum(.data$waking_valid_mass),
      day_known_sleep_minutes = sum(.data$known_sleep_mass),
      day_unknown_state_minutes = sum(.data$unknown_state_mass),
      b_valid_minutes_after_hour = sum(
        .data$waking_valid_mass * .data$current_hour_eligible
      ),
      c_valid_minutes_after_hour = sum(
        .data$waking_valid_mass * .data$wake_hour_support_pass
      ),
      .groups = "drop"
    )
  if (
    any(
      abs(
        day_support$day_waking_expected_minutes +
          day_support$day_known_sleep_minutes -
          1440
      ) >
        sqrt(.Machine$double.eps)
    )
  ) {
    abort_pipeline(
      "Daily fractional waking and sleep support does not sum to 1440"
    )
  }

  current <- current_daily |>
    dplyr::select(
      dplyr::all_of(day_key),
      day_expected_wall_minutes,
      day_valid_minutes_raw,
      day_valid_fraction_raw,
      day_valid_minutes_after_hour,
      day_valid_fraction_after_hour,
      day_all_finite_medi_zero,
      day_all_zero_medi_excluded,
      day_eligible_without_all_zero_screen,
      day_eligible_after_hour_without_all_zero_screen,
      day_eligible,
      day_eligible_after_hour
    )
  day_support <- left_join_checked(
    day_support,
    current_hour_days,
    by = day_key,
    relationship = "one-to-one",
    x_name = "daily waking-support summary",
    y_name = "current hourly gate summary"
  )
  day_support <- left_join_checked(
    day_support,
    wake_hour_days,
    by = day_key,
    relationship = "one-to-one",
    x_name = "daily support and current-hour summary",
    y_name = "wake-aware hourly gate summary"
  )
  base <- left_join_checked(
    day_support,
    current,
    by = day_key,
    relationship = "one-to-one",
    x_name = "daily waking-support summary",
    y_name = "primary full-day coverage"
  )
  if (anyNA(base$day_eligible)) {
    abort_pipeline("Primary full-day coverage did not map to every day")
  }

  make_rule <- function(
    rule,
    expected,
    valid_raw,
    valid_after_hour,
    hour_evaluable,
    hour_pass,
    hour_exempt,
    reference_fraction = NULL,
    reference_eligible = NULL
  ) {
    day_evaluable <- expected > 0
    support_fraction <- ifelse(
      day_evaluable,
      valid_after_hour / expected,
      NA_real_
    )
    eligible_without_all_zero_screen <- day_evaluable &
      support_fraction >= minimum_day_coverage
    all_zero_medi_excluded <-
      eligible_without_all_zero_screen &
        base$day_all_finite_medi_zero
    eligible <-
      eligible_without_all_zero_screen &
        !all_zero_medi_excluded
    if (!is.null(reference_fraction)) {
      tolerance <- sqrt(.Machine$double.eps)
      same_fraction <- isTRUE(all.equal(
        support_fraction,
        reference_fraction,
        tolerance = tolerance,
        check.attributes = FALSE
      ))
      if (!same_fraction || !identical(eligible, reference_eligible)) {
        abort_pipeline(
          "Rule A failed to reproduce primary full-day eligibility"
        )
      }
    }
    dplyr::transmute(
      base,
      dplyr::across(dplyr::all_of(day_key)),
      rule = rule,
      minimum_hour_coverage = minimum_hour_coverage,
      minimum_day_coverage = minimum_day_coverage,
      day_expected_support_minutes = expected,
      day_valid_support_minutes_raw = valid_raw,
      day_valid_support_minutes_after_hour = valid_after_hour,
      day_support_fraction_used = support_fraction,
      day_evaluable = day_evaluable,
      day_all_finite_medi_zero = .data$day_all_finite_medi_zero,
      day_eligible_without_all_zero_screen =
        eligible_without_all_zero_screen,
      day_all_zero_medi_excluded = all_zero_medi_excluded,
      day_eligible = eligible,
      day_eligibility_reason = dplyr::case_when(
        !.data$day_evaluable ~ "no_non_sleep_denominator",
        .data$day_all_zero_medi_excluded ~ "all_zero_medi_day",
        .data$day_eligible ~ "eligible",
        TRUE ~ "below_daily_threshold"
      ),
      hour_gate_evaluable_hours = hour_evaluable,
      hour_gate_pass_hours = hour_pass,
      hour_gate_exempt_hours = hour_exempt,
      day_observed_wall_minutes = .data$day_observed_wall_minutes,
      day_source_real_minutes = .data$day_source_real_minutes,
      day_dst_fold_wall_minutes = .data$day_dst_fold_wall_minutes,
      day_source_absent_wall_minutes = .data$day_source_absent_wall_minutes,
      day_waking_expected_minutes = .data$day_waking_expected_minutes,
      day_waking_valid_minutes_raw = .data$day_waking_valid_minutes_raw,
      day_known_sleep_minutes = .data$day_known_sleep_minutes,
      day_unknown_state_minutes = .data$day_unknown_state_minutes
    )
  }

  a <- make_rule(
    rule = "A_full_day",
    expected = base$day_expected_wall_minutes,
    valid_raw = base$day_valid_minutes_raw,
    valid_after_hour = base$day_valid_minutes_raw,
    hour_evaluable = base$current_hour_gate_evaluable_hours,
    hour_pass = base$current_hour_gate_pass_hours,
    hour_exempt = base$current_hour_gate_exempt_hours,
    reference_fraction = base$day_valid_fraction_raw,
    reference_eligible = base$day_eligible
  )
  b <- make_rule(
    rule = "B_sleep_excluded_daily",
    expected = base$day_waking_expected_minutes,
    valid_raw = base$day_waking_valid_minutes_raw,
    valid_after_hour = base$b_valid_minutes_after_hour,
    hour_evaluable = base$current_hour_gate_evaluable_hours,
    hour_pass = base$current_hour_gate_pass_hours,
    hour_exempt = base$current_hour_gate_exempt_hours
  )
  c <- make_rule(
    rule = "C_sleep_excluded_hourly_daily",
    expected = base$day_waking_expected_minutes,
    valid_raw = base$day_waking_valid_minutes_raw,
    valid_after_hour = base$c_valid_minutes_after_hour,
    hour_evaluable = base$wake_hour_gate_evaluable_hours,
    hour_pass = base$wake_hour_gate_pass_hours,
    hour_exempt = base$wake_hour_gate_exempt_hours
  )

  definitions <- daily_coverage_rule_definitions()
  detail <- dplyr::bind_rows(a, b, c)
  detail <- left_join_checked(
    detail,
    definitions,
    by = "rule",
    relationship = "many-to-one",
    x_name = "participant-day rule comparison",
    y_name = "coverage-rule definitions"
  ) |>
    dplyr::arrange(
      dplyr::across(dplyr::all_of(day_key)),
      factor(
        .data$rule,
        levels = c(
          "A_full_day",
          "B_sleep_excluded_daily",
          "C_sleep_excluded_hourly_daily"
        )
      )
    )
  assert_unique_key(
    detail,
    c(day_key, "rule"),
    object = "participant-day coverage-rule detail"
  )
  detail
}

summarise_daily_coverage_rule_counts <- function(detail) {
  required <- c(
    "site",
    "Id",
    "position",
    "rule",
    "day_evaluable",
    "day_eligible"
  )
  assert_columns(detail, required, object = "coverage-rule detail")
  scoped <- dplyr::bind_rows(
    dplyr::mutate(detail, scope = "site", report_site = .data$site),
    dplyr::mutate(detail, scope = "overall", report_site = "ALL")
  )
  scoped |>
    dplyr::group_by(
      .data$position,
      .data$scope,
      .data$report_site,
      .data$rule
    ) |>
    dplyr::summarise(
      participants = dplyr::n_distinct(.data$site, .data$Id),
      participant_days = dplyr::n(),
      evaluable_days = sum(.data$day_evaluable),
      non_evaluable_days = sum(!.data$day_evaluable),
      eligible_participants = dplyr::n_distinct(
        .data$site[.data$day_eligible],
        .data$Id[.data$day_eligible]
      ),
      ineligible_participants = dplyr::n_distinct(
        .data$site[!.data$day_eligible],
        .data$Id[!.data$day_eligible]
      ),
      eligible_days = sum(.data$day_eligible),
      ineligible_days = sum(!.data$day_eligible),
      eligible_fraction = .data$eligible_days / .data$participant_days,
      .groups = "drop"
    ) |>
    dplyr::rename(site = "report_site") |>
    dplyr::arrange(.data$position, .data$scope, .data$site, .data$rule)
}

summarise_daily_coverage_rule_transitions <- function(detail) {
  key <- c("site", "Id", "position", "local_date")
  assert_columns(
    detail,
    c(key, "rule", "day_eligible"),
    object = "coverage-rule detail"
  )
  pair_specifications <- tibble::tribble(
    ~from_rule,
    ~to_rule,
    "A_full_day",
    "B_sleep_excluded_daily",
    "A_full_day",
    "C_sleep_excluded_hourly_daily",
    "B_sleep_excluded_daily",
    "C_sleep_excluded_hourly_daily"
  )
  transition_levels <- tibble::tibble(
    from_eligible = c(FALSE, FALSE, TRUE, TRUE),
    to_eligible = c(FALSE, TRUE, FALSE, TRUE),
    transition = c(
      "ineligible_to_ineligible",
      "ineligible_to_eligible",
      "eligible_to_ineligible",
      "eligible_to_eligible"
    )
  )

  pairs <- dplyr::bind_rows(lapply(
    seq_len(nrow(pair_specifications)),
    function(index) {
      specification <- pair_specifications[index, , drop = FALSE]
      from <- detail |>
        dplyr::filter(.data$rule == specification$from_rule) |>
        dplyr::select(
          dplyr::all_of(key),
          from_eligible = "day_eligible"
        )
      to <- detail |>
        dplyr::filter(.data$rule == specification$to_rule) |>
        dplyr::select(
          dplyr::all_of(key),
          to_eligible = "day_eligible"
        )
      joined <- left_join_checked(
        from,
        to,
        by = key,
        relationship = "one-to-one",
        x_name = paste0("daily rule ", specification$from_rule),
        y_name = paste0("daily rule ", specification$to_rule)
      )
      if (anyNA(joined$to_eligible)) {
        abort_pipeline(
          "Transition comparison is missing a `%s` participant-day",
          specification$to_rule
        )
      }
      joined |>
        dplyr::mutate(
          from_rule = specification$from_rule,
          to_rule = specification$to_rule,
          transition = dplyr::case_when(
            !.data$from_eligible & !.data$to_eligible ~
              "ineligible_to_ineligible",
            !.data$from_eligible & .data$to_eligible ~ "ineligible_to_eligible",
            .data$from_eligible & !.data$to_eligible ~ "eligible_to_ineligible",
            TRUE ~ "eligible_to_eligible"
          )
        )
    }
  ))
  scoped <- dplyr::bind_rows(
    dplyr::mutate(pairs, scope = "site", report_site = .data$site),
    dplyr::mutate(pairs, scope = "overall", report_site = "ALL")
  )
  observed <- scoped |>
    dplyr::group_by(
      .data$position,
      .data$scope,
      .data$report_site,
      .data$from_rule,
      .data$to_rule,
      .data$from_eligible,
      .data$to_eligible,
      .data$transition
    ) |>
    dplyr::summarise(
      participants = dplyr::n_distinct(.data$site, .data$Id),
      participant_days = dplyr::n(),
      .groups = "drop"
    )
  groups <- dplyr::distinct(
    scoped,
    .data$position,
    .data$scope,
    .data$report_site,
    .data$from_rule,
    .data$to_rule
  )
  skeleton <- tidyr::crossing(groups, transition_levels)
  left_join_checked(
    skeleton,
    observed,
    by = c(
      "position",
      "scope",
      "report_site",
      "from_rule",
      "to_rule",
      "from_eligible",
      "to_eligible",
      "transition"
    ),
    relationship = "one-to-one",
    x_name = "complete transition table",
    y_name = "observed transition counts"
  ) |>
    dplyr::mutate(
      participants = dplyr::coalesce(
        as.integer(.data$participants),
        0L
      ),
      participant_days = dplyr::coalesce(
        as.integer(.data$participant_days),
        0L
      )
    ) |>
    dplyr::rename(site = "report_site") |>
    dplyr::arrange(
      .data$position,
      .data$scope,
      .data$site,
      .data$from_rule,
      .data$to_rule,
      .data$transition
    )
}

compare_daily_coverage_rules <- function(
  minute_data,
  coverage_signal = "MEDI",
  state_col = "State.Brown",
  sleep_value = "sleep",
  id_cols = c("site", "Id", "position"),
  participant_days = NULL,
  minimum_hour_coverage = 0.5,
  minimum_day_coverage = 0.8,
  object = deparse(substitute(minute_data))
) {
  validate_daily_coverage_rule_input(
    minute_data,
    coverage_signal = coverage_signal,
    state_col = state_col,
    id_cols = id_cols,
    object = object
  )
  validate_coverage_fraction(
    minimum_hour_coverage,
    argument = "minimum_hour_coverage"
  )
  validate_coverage_fraction(
    minimum_day_coverage,
    argument = "minimum_day_coverage"
  )

  current <- apply_wall_clock_coverage_rules(
    minute_data = minute_data,
    value_cols = coverage_signal,
    coverage_signal = coverage_signal,
    id_cols = id_cols,
    participant_days = participant_days,
    minimum_hour_coverage = minimum_hour_coverage,
    minimum_day_coverage = minimum_day_coverage,
    object = object
  )
  waking_support <- collapse_waking_wall_support(
    minute_data,
    coverage_signal = coverage_signal,
    state_col = state_col,
    sleep_value = sleep_value,
    id_cols = id_cols,
    object = object
  )
  wall_grid <- add_waking_support_to_wall_grid(
    current$wall_grid,
    waking_support,
    id_cols = id_cols
  )
  wake_hourly <- evaluate_wake_aware_hourly_gate(
    wall_grid,
    id_cols = id_cols,
    minimum_hour_coverage = minimum_hour_coverage
  )
  detail <- daily_coverage_rule_detail(
    wall_grid,
    current_daily = current$daily,
    current_hourly = current$hourly,
    wake_hourly = wake_hourly,
    id_cols = id_cols,
    minimum_hour_coverage = minimum_hour_coverage,
    minimum_day_coverage = minimum_day_coverage
  )

  structure(
    list(
      daily_detail = detail,
      eligible_counts = summarise_daily_coverage_rule_counts(detail),
      transitions = summarise_daily_coverage_rule_transitions(detail),
      wake_hourly = wake_hourly,
      current_hourly = current$hourly,
      current_daily = current$daily,
      wall_grid = wall_grid,
      definitions = daily_coverage_rule_definitions(),
      settings = list(
        coverage_signal = coverage_signal,
        state_col = state_col,
        sleep_value = sleep_value,
        minimum_hour_coverage = minimum_hour_coverage,
        minimum_day_coverage = minimum_day_coverage,
        fall_back_support = "mean_over_true_instances",
        source_absent_state = "unknown_and_not_excluded",
        selected_primary_rule = "A_full_day"
      )
    ),
    class = c("daily_coverage_rule_diagnostic", "list")
  )
}
