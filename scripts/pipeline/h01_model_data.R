
h01_abort <- function(..., call. = FALSE) {
  message <- sprintf(...)
  if (exists("abort_pipeline", mode = "function", inherits = TRUE)) {
    abort_pipeline("%s", message)
  }
  stop(message, call. = call.)
}

h01_placements <- function() {
  c("glasses", "chest")
}

h01_scenarios <- function() {
  c("all_available", "paired_common_sample")
}

h01_validate_data_scenario_id <- function(data_scenario_id) {
  if (
    length(data_scenario_id) != 1L ||
      is.na(data_scenario_id) ||
      !nzchar(data_scenario_id) ||
      !grepl("^[a-z][a-z0-9_]*$", data_scenario_id)
  ) {
    h01_abort(
      paste0(
        "`data_scenario_id` must be one lower-case identifier ",
        "with underscores"
      )
    )
  }
  invisible(data_scenario_id)
}

h01_metric_contract <- function(root = project_root()) {
  contract <- tibble::tribble(
    ~metric_order,
    ~metric_id,
    ~analysis_unit,
    ~source_field,
    ~source_unit,
    1L,
    "interdaily_stability",
    "participant",
    "interdaily_stability",
    "dimensionless",
    2L,
    "intradaily_variability",
    "participant",
    "intradaily_variability",
    "dimensionless",
    3L,
    "daily_geometric_mean_medi",
    "participant_day",
    "daily_geometric_mean_medi_lx",
    "lx",
    4L,
    "m10_mean_medi",
    "participant_day",
    "m10_mean_medi_lx",
    "lx",
    5L,
    "l10_mean_medi",
    "participant_day",
    "l10_mean_medi_lx",
    "lx",
    6L,
    "duration_above_1000",
    "participant_day",
    "duration_above_1000_h",
    "h",
    7L,
    "duration_above_250_wake",
    "participant_day",
    "duration_above_250_wake_h",
    "h",
    8L,
    "duration_below_10_pre_sleep",
    "participant_day",
    "duration_below_10_pre_sleep_h",
    "h",
    9L,
    "duration_below_1_sleep_environment",
    "participant_day",
    "duration_below_1_sleep_environment_h",
    "h",
    10L,
    "longest_bout_above_250",
    "participant_day",
    "longest_bout_above_250_h",
    "h",
    11L,
    "m10_midpoint",
    "participant_day",
    "m10_midpoint_clock_minute",
    "clock_minute",
    12L,
    "l10_midpoint",
    "participant_day",
    "l10_midpoint_clock_minute",
    "clock_minute",
    13L,
    "mean_timing_above_250",
    "participant_day",
    "mean_timing_above_250_clock_minute",
    "clock_minute",
    14L,
    "first_timing_above_250",
    "participant_day",
    "first_timing_above_250_clock_minute",
    "clock_minute",
    15L,
    "last_timing_above_250",
    "participant_day",
    "last_timing_above_250_clock_minute",
    "clock_minute",
    16L,
    "dose_time_sensitive_corrected_medi",
    "participant_day",
    "dose_corrected_medi_lx_h",
    "lx_h",
    17L,
    "mder_mean_of_viable_ratios",
    "participant_day",
    "mder",
    "dimensionless"
  )
  display <- read_metric_display_registry(root) |>
    dplyr::rename(display_analysis_unit = "analysis_unit")
  contract <- dplyr::left_join(
    contract,
    display,
    by = "metric_id",
    relationship = "one-to-one"
  )
  if (
    anyNA(contract$display_analysis_unit) ||
      any(
        contract$analysis_unit !=
          gsub("-", "_", contract$display_analysis_unit, fixed = TRUE)
      )
  ) {
    h01_abort(
      "H01 metric analysis units differ from the display registry"
    )
  }
  contract <- contract |>
    dplyr::select(-"display_analysis_unit") |>
    dplyr::mutate(
      value_definition = paste0(
        .data$manuscript_name,
        ": ",
        .data$variant_label
      ),
      .after = "variant_label"
    )
  validate_h01_metric_contract(contract)
  contract
}

h01_implementation_contract_columns <- function() {
  c(
    "metric_order",
    "metric_id",
    "analysis_unit",
    "source_field",
    "source_unit",
    "manuscript_name",
    "manuscript_category",
    "display_unit",
    "analytical_role"
  )
}

validate_h01_metric_contract <- function(
  contract,
  object = deparse(substitute(contract))
) {
  required <- c(
    "metric_order",
    "metric_id",
    "analysis_unit",
    "source_field",
    "source_unit",
    "manuscript_name",
    "abbreviation",
    "manuscript_category",
    "display_unit",
    "analytical_role",
    "variant_label",
    "value_definition"
  )
  missing <- setdiff(required, names(contract))
  if (length(missing) > 0L) {
    h01_abort(
      "%s is missing required column(s): %s",
      object,
      paste(missing, collapse = ", ")
    )
  }
  if (
    nrow(contract) != 17L ||
      !identical(contract$metric_order, seq_len(17L)) ||
      anyDuplicated(contract$metric_id) ||
      anyDuplicated(contract$source_field) ||
      any(!contract$analysis_unit %in% c("participant", "participant_day")) ||
      any(contract$analytical_role != "primary_outcome") ||
      anyNA(contract)
  ) {
    h01_abort(
      "%s must declare exactly 17 ordered, unique primary H01 metrics",
      object
    )
  }
  prohibited <- grepl(
    "(^|_)(m10|l10)_(onset|offset)($|_)",
    contract$metric_id,
    perl = TRUE
  )
  if (any(prohibited)) {
    h01_abort("%s contains internal M10/L10 boundary metrics", object)
  }
  invisible(contract)
}

h01_model_data_paths <- function(root, output_root = root) {
  root <- normalizePath(root, winslash = "/", mustWork = TRUE)
  output_root <- normalizePath(output_root, winslash = "/", mustWork = TRUE)
  model_root <- file.path(output_root, "results", "intermediate", "model_data")
  support_root <- file.path(model_root, "H01")
  tables <- c("model_rows", "metric_contract", "sample_flow", "exclusion_reasons",
              "scenario_status", "predictor_centers", "variable_dictionary")
  list(root = root, output_root = output_root, model_root = model_root,
       support_root = support_root, rds = file.path(model_root, "H01.rds"),
       csv = stats::setNames(file.path(support_root, paste0(tables, ".csv")), tables))
}

h01_base_input_paths <- function(root) {
  base <- file.path(root, "results", "intermediate/model_data", "base")
  list(
    glasses = c(
      participant_day = file.path(
        base,
        "metrics_glasses_participant_day_enriched.rds"
      ),
      participant = file.path(
        base,
        "metrics_glasses_participant_enriched.rds"
      )
    ),
    chest = c(
      participant_day = file.path(
        base,
        "metrics_chest_participant_day_enriched.rds"
      ),
      participant = file.path(
        base,
        "metrics_chest_participant_enriched.rds"
      )
    )
  )
}

h01_admissibility_input_paths <- function(root) {
  metric_root <- file.path(root, "results", "intermediate/metrics")
  c(
    glasses = file.path(
      metric_root,
      "metrics_glasses_admissibility.csv"
    ),
    chest = file.path(
      metric_root,
      "metrics_chest_admissibility.csv"
    )
  )
}

h01_metric_support_input_paths <- function(root) {
  metric_root <- file.path(root, "results", "intermediate/metrics")
  c(
    glasses = file.path(
      metric_root,
      "metrics_glasses_values_long.csv"
    ),
    chest = file.path(
      metric_root,
      "metrics_chest_values_long.csv"
    )
  )
}

h01_required_day_columns <- function(contract) {
  c(
    "site",
    "Id",
    "position",
    "local_date",
    "profile_variant",
    "measurement_construct",
    "prepared_record_support_available",
    "prepared_record_support_unavailability_reason",
    "expected_real_minutes",
    "valid_medi_real_minutes",
    "valid_light_real_minutes",
    "photoperiod_hours",
    "latitude_deg",
    contract$source_field[contract$analysis_unit == "participant_day"]
  )
}

h01_required_participant_columns <- function(contract) {
  c(
    "site",
    "Id",
    "position",
    "profile_variant",
    "measurement_construct",
    "prepared_record_support_available",
    "prepared_record_support_unavailability_reason",
    "days",
    "valid_minutes",
    "expected_minutes",
    contract$source_field[contract$analysis_unit == "participant"]
  )
}

validate_h01_base_inputs <- function(
  participant_day,
  participant,
  placement,
  contract
) {
  placement <- match.arg(placement, h01_placements())
  validate_h01_metric_contract(contract)
  if (!is.data.frame(participant_day) || !is.data.frame(participant)) {
    h01_abort("H01 base inputs for `%s` must be data frames", placement)
  }
  assert_columns(
    participant_day,
    h01_required_day_columns(contract),
    object = paste0(placement, " H01 participant-day input")
  )
  assert_columns(
    participant,
    h01_required_participant_columns(contract),
    object = paste0(placement, " H01 participant input")
  )
  assert_unique_key(
    participant_day,
    c("site", "Id", "position", "local_date"),
    object = paste0(placement, " H01 participant-day input")
  )
  assert_unique_key(
    participant,
    c("site", "Id", "position"),
    object = paste0(placement, " H01 participant input")
  )
  if (
    !identical(unique(as.character(participant_day$position)), placement) ||
      !identical(unique(as.character(participant$position)), placement)
  ) {
    h01_abort("H01 base inputs do not contain only `%s` rows", placement)
  }
  if (
    !inherits(participant_day$local_date, "Date") ||
      anyNA(participant_day[c("site", "Id", "position", "local_date")]) ||
      anyNA(participant[c("site", "Id", "position")])
  ) {
    h01_abort("H01 base inputs for `%s` contain an invalid key", placement)
  }
  if (
    any(!is.finite(participant_day$photoperiod_hours)) ||
      any(!is.finite(participant_day$latitude_deg))
  ) {
    h01_abort(
      "H01 participant-day context for `%s` has missing predictors",
      placement
    )
  }
  support_status_valid <- function(data, support_columns) {
    available <- data$prepared_record_support_available
    reason <- data$prepared_record_support_unavailability_reason
    if (
      !is.logical(available) ||
        anyNA(available) ||
        any(available & !is.na(reason)) ||
        any(
          !available &
            (is.na(reason) | !nzchar(reason))
        )
    ) {
      return(FALSE)
    }
    support <- data[support_columns]
    available_matrix <- as.matrix(support[available, , drop = FALSE])
    unavailable_matrix <- as.matrix(support[!available, , drop = FALSE])
    (nrow(available_matrix) == 0L ||
      all(is.finite(available_matrix))) &&
      (nrow(unavailable_matrix) == 0L ||
        all(is.na(unavailable_matrix)))
  }
  day_support <- participant_day[c(
    "expected_real_minutes",
    "valid_medi_real_minutes",
    "valid_light_real_minutes"
  )]
  participant_support <- participant[c(
    "expected_minutes",
    "valid_minutes"
  )]
  if (
    !support_status_valid(
      participant_day,
      names(day_support)
    ) ||
      !support_status_valid(
        participant,
        names(participant_support)
      ) ||
      any(
        participant_day$prepared_record_support_available &
          participant_day$expected_real_minutes <= 0,
        na.rm = TRUE
      ) ||
      any(
        participant_day$prepared_record_support_available &
          participant_day$valid_medi_real_minutes < 0,
        na.rm = TRUE
      ) ||
      any(
        participant_day$prepared_record_support_available &
          participant_day$valid_light_real_minutes < 0,
        na.rm = TRUE
      ) ||
      any(
        participant_day$prepared_record_support_available &
          participant_day$valid_medi_real_minutes >
            participant_day$expected_real_minutes,
        na.rm = TRUE
      ) ||
      any(
        participant_day$prepared_record_support_available &
          participant_day$valid_light_real_minutes >
            participant_day$expected_real_minutes,
        na.rm = TRUE
      ) ||
      any(
        participant$prepared_record_support_available &
          participant$expected_minutes <= 0,
        na.rm = TRUE
      ) ||
      any(
        participant$prepared_record_support_available &
          participant$valid_minutes < 0,
        na.rm = TRUE
      ) ||
      any(
        participant$prepared_record_support_available &
          participant$valid_minutes > participant$expected_minutes,
        na.rm = TRUE
      ) ||
      any(
        !is.finite(participant$days) |
          participant$days <= 0 |
          participant$days != as.integer(participant$days)
      )
  ) {
    h01_abort(
      "H01 base-input support is invalid for `%s`",
      placement
    )
  }
  invisible(TRUE)
}

h01_build_participant_context <- function(
  participant_day,
  participant,
  placement
) {
  site_latitude <- participant_day |>
    dplyr::distinct(.data$site, .data$latitude_deg) |>
    dplyr::count(.data$site, name = "latitude_values")
  if (any(site_latitude$latitude_values != 1L)) {
    h01_abort(
      "H01 `%s` data contain more than one latitude for a site",
      placement
    )
  }
  context <- participant_day |>
    dplyr::group_by(.data$site, .data$Id, .data$position) |>
    dplyr::summarise(
      participant_days_contributing = dplyr::n_distinct(.data$local_date),
      photoperiod_hours = mean(.data$photoperiod_hours),
      latitude_deg = dplyr::first(.data$latitude_deg),
      .groups = "drop"
    )
  participant_keys <- participant |>
    dplyr::distinct(.data$site, .data$Id, .data$position)
  context_keys <- context |>
    dplyr::distinct(.data$site, .data$Id, .data$position)
  key <- c("site", "Id", "position")
  if (
    nrow(dplyr::anti_join(participant_keys, context_keys, by = key)) > 0L ||
      nrow(dplyr::anti_join(context_keys, participant_keys, by = key)) > 0L
  ) {
    h01_abort(
      "H01 `%s` participant and participant-day keys differ",
      placement
    )
  }
  linked <- participant |>
    dplyr::select(dplyr::all_of(c("site", "Id", "position", "days"))) |>
    dplyr::rename(reported_contributing_days = "days") |>
    dplyr::left_join(
      context,
      by = c("site", "Id", "position"),
      relationship = "one-to-one"
    )
  if (
    anyNA(linked$participant_days_contributing) ||
      any(
        linked$reported_contributing_days !=
          linked$participant_days_contributing
      )
  ) {
    h01_abort(
      paste0(
        "H01 `%s` participant metrics do not reconcile with the exact ",
        "contributing participant-day set"
      ),
      placement
    )
  }
  context
}

validate_h01_admissibility <- function(
  admissibility,
  placement,
  contract
) {
  required <- c(
    "site",
    "Id",
    "position",
    "local_date",
    "profile_variant",
    "analysis_unit",
    "metric",
    "estimable",
    "failure_reason",
    "left_censored",
    "right_censored",
    "any_censored"
  )
  assert_columns(
    admissibility,
    required,
    object = paste0(placement, " H01 metric admissibility")
  )
  selected <- admissibility |>
    dplyr::filter(.data$metric %in% contract$metric_id)
  if (
    !setequal(unique(selected$metric), contract$metric_id) ||
      anyNA(selected$estimable) ||
      !identical(unique(as.character(selected$position)), placement)
  ) {
    h01_abort(
      "H01 `%s` admissibility does not cover the declared metric set",
      placement
    )
  }
  key <- c(
    "site",
    "Id",
    "position",
    "local_date",
    "analysis_unit",
    "metric"
  )
  if (anyDuplicated(selected[key])) {
    h01_abort("H01 `%s` admissibility has duplicated metric keys", placement)
  }
  declared_units <- contract |>
    dplyr::select(dplyr::all_of(c("metric_id", "analysis_unit")))
  observed_units <- selected |>
    dplyr::distinct(metric_id = .data$metric, .data$analysis_unit)
  if (
    nrow(observed_units) != nrow(declared_units) ||
      nrow(dplyr::anti_join(
        declared_units,
        observed_units,
        by = c("metric_id", "analysis_unit")
      )) >
        0L
  ) {
    h01_abort(
      "H01 `%s` admissibility analysis units differ from the contract",
      placement
    )
  }
  missing_reason <- !selected$estimable &
    (is.na(selected$failure_reason) | !nzchar(selected$failure_reason))
  unexpected_reason <- selected$estimable & !is.na(selected$failure_reason)
  if (any(missing_reason) || any(unexpected_reason)) {
    h01_abort(
      paste0(
        "H01 `%s` admissibility must retain an exact reason for every ",
        "non-estimable row and no reason for an estimable row"
      ),
      placement
    )
  }
  invisible(TRUE)
}

h01_join_admissibility <- function(rows, admissibility, placement, contract) {
  validate_h01_admissibility(admissibility, placement, contract)
  selected <- admissibility |>
    dplyr::filter(.data$metric %in% contract$metric_id) |>
    dplyr::transmute(
      .data$site,
      .data$Id,
      .data$position,
      .data$local_date,
      .data$profile_variant,
      .data$analysis_unit,
      metric_id = .data$metric,
      metric_estimable = .data$estimable,
      metric_failure_reason = .data$failure_reason,
      metric_left_censored = .data$left_censored,
      metric_right_censored = .data$right_censored,
      metric_any_censored = .data$any_censored
    )
  key <- c(
    "site",
    "Id",
    "position",
    "local_date",
    "profile_variant",
    "analysis_unit",
    "metric_id"
  )
  row_keys <- dplyr::distinct(rows, dplyr::across(dplyr::all_of(key)))
  admissibility_keys <- dplyr::distinct(
    selected,
    dplyr::across(dplyr::all_of(key))
  )
  if (
    nrow(dplyr::anti_join(row_keys, admissibility_keys, by = key)) > 0L ||
      nrow(dplyr::anti_join(admissibility_keys, row_keys, by = key)) > 0L
  ) {
    h01_abort(
      "H01 `%s` admissibility keys differ from model-row keys",
      placement
    )
  }
  output <- dplyr::left_join(
    rows,
    selected,
    by = key,
    relationship = "one-to-one",
    na_matches = "na"
  )
  if (
    nrow(output) != nrow(rows) ||
      anyNA(output$metric_estimable) ||
      any(output$metric_estimable != is.finite(output$value))
  ) {
    h01_abort(
      "H01 `%s` base values do not reconcile with recorded admissibility",
      placement
    )
  }
  output
}

h01_join_metric_support <- function(
  rows,
  metric_support,
  placement,
  contract
) {
  required <- c(
    "site",
    "Id",
    "position",
    "local_date",
    "profile_variant",
    "analysis_unit",
    "metric",
    "value",
    "units",
    "estimable",
    "failure_reason",
    "metric_support_available",
    "metric_support_unavailability_reason",
    "valid_minutes",
    "expected_minutes"
  )
  assert_columns(
    metric_support,
    required,
    object = paste0(placement, " H01 metric support")
  )
  selected <- metric_support |>
    dplyr::filter(.data$metric %in% contract$metric_id) |>
    dplyr::transmute(
      .data$site,
      .data$Id,
      .data$position,
      .data$local_date,
      .data$profile_variant,
      .data$analysis_unit,
      metric_id = .data$metric,
      support_value = .data$value,
      support_unit = .data$units,
      support_estimable = .data$estimable,
      support_failure_reason = .data$failure_reason,
      metric_support_available = .data$metric_support_available,
      metric_support_unavailability_reason = .data$metric_support_unavailability_reason,
      metric_support_valid_minutes = .data$valid_minutes,
      metric_support_expected_minutes = .data$expected_minutes
    )
  key <- c(
    "site",
    "Id",
    "position",
    "local_date",
    "profile_variant",
    "analysis_unit",
    "metric_id"
  )
  if (
    anyDuplicated(selected[key]) ||
      !identical(unique(as.character(selected$position)), placement)
  ) {
    h01_abort("H01 `%s` metric support has invalid keys", placement)
  }
  row_keys <- dplyr::distinct(rows, dplyr::across(dplyr::all_of(key)))
  support_keys <- dplyr::distinct(
    selected,
    dplyr::across(dplyr::all_of(key))
  )
  if (
    nrow(dplyr::anti_join(row_keys, support_keys, by = key)) > 0L ||
      nrow(dplyr::anti_join(support_keys, row_keys, by = key)) > 0L
  ) {
    h01_abort(
      "H01 `%s` metric-support keys differ from model-row keys",
      placement
    )
  }
  output <- dplyr::left_join(
    rows,
    selected,
    by = key,
    relationship = "one-to-one",
    na_matches = "na"
  )
  finite_values <- is.finite(output$value) & is.finite(output$support_value)
  unequal_values <- finite_values &
    abs(output$value - output$support_value) >
      1e-12 * pmax(1, abs(output$value), abs(output$support_value))
  valid_support <- output$metric_support_valid_minutes
  expected_support <- output$metric_support_expected_minutes
  support_missing_mismatch <- is.na(valid_support) != is.na(expected_support)
  invalid_support_status <-
    is.na(output$metric_support_available) |
    output$metric_support_available !=
      (is.finite(valid_support) & is.finite(expected_support)) |
    (output$metric_support_available &
      !is.na(output$metric_support_unavailability_reason)) |
    (!output$metric_support_available &
      (is.na(output$metric_support_unavailability_reason) |
        !nzchar(output$metric_support_unavailability_reason)))
  support_out_of_bounds <- is.finite(valid_support) &
    (valid_support < 0 |
      !is.finite(expected_support) |
      expected_support < 0 |
      (output$metric_estimable & expected_support == 0) |
      valid_support > expected_support)
  negative_value <- is.finite(output$value) & output$value < 0
  invalid_clock_value <- output$source_unit == "clock_minute" &
    is.finite(output$value) &
    output$value >= 1440
  if (
    nrow(output) != nrow(rows) ||
      anyNA(output$support_estimable) ||
      any(output$support_estimable != output$metric_estimable) ||
      any(output$support_unit != output$source_unit) ||
      any(unequal_values) ||
      any(
        is.finite(output$value) != is.finite(output$support_value)
      ) ||
      any(
        !is.na(output$support_failure_reason) !=
          !is.na(output$metric_failure_reason)
      ) ||
      any(
        !is.na(output$support_failure_reason) &
          output$support_failure_reason != output$metric_failure_reason
      ) ||
      any(support_missing_mismatch) ||
      any(invalid_support_status) ||
      any(support_out_of_bounds) ||
      any(negative_value) ||
      any(invalid_clock_value)
  ) {
    h01_abort(
      "H01 `%s` metric support differs from values or admissibility",
      placement
    )
  }
  output |>
    dplyr::select(
      -dplyr::all_of(c(
        "support_value",
        "support_unit",
        "support_estimable",
        "support_failure_reason"
      ))
    )
}

h01_model_exclusion_reason <- function(
  metric_estimable,
  metric_failure_reason,
  value,
  site,
  Id,
  photoperiod_hours,
  latitude_deg,
  require_latitude = FALSE
) {
  reason <- rep(NA_character_, length(value))
  reason[!metric_estimable] <- paste0(
    "metric_not_estimable:",
    metric_failure_reason[!metric_estimable]
  )
  assign_reason <- function(condition, label) {
    replace <- is.na(reason) & condition
    reason[replace] <<- label
  }
  assign_reason(!is.finite(value), "metric_value_nonfinite")
  assign_reason(is.na(site) | !nzchar(site), "missing_site")
  assign_reason(is.na(Id) | !nzchar(Id), "missing_participant_id")
  assign_reason(
    !is.finite(photoperiod_hours),
    "missing_photoperiod"
  )
  if (require_latitude) {
    assign_reason(!is.finite(latitude_deg), "missing_latitude")
  }
  reason
}

h01_add_model_flags <- function(rows) {
  site_reason <- h01_model_exclusion_reason(
    metric_estimable = rows$metric_estimable,
    metric_failure_reason = rows$metric_failure_reason,
    value = rows$value,
    site = rows$site,
    Id = rows$Id,
    photoperiod_hours = rows$photoperiod_hours,
    latitude_deg = rows$latitude_deg,
    require_latitude = FALSE
  )
  latitude_reason <- h01_model_exclusion_reason(
    metric_estimable = rows$metric_estimable,
    metric_failure_reason = rows$metric_failure_reason,
    value = rows$value,
    site = rows$site,
    Id = rows$Id,
    photoperiod_hours = rows$photoperiod_hours,
    latitude_deg = rows$latitude_deg,
    require_latitude = TRUE
  )
  rows |>
    dplyr::mutate(
      participant_key = paste(.data$site, .data$Id, sep = "::"),
      absolute_latitude_10deg = abs(.data$latitude_deg) / 10,
      scenario_estimable = .data$metric_estimable,
      scenario_failure_reason = .data$metric_failure_reason,
      site_photoperiod_included = is.na(site_reason),
      site_photoperiod_exclusion_reason = site_reason,
      latitude_photoperiod_included = is.na(latitude_reason),
      latitude_photoperiod_exclusion_reason = latitude_reason
    )
}

h01_build_all_available_rows <- function(
  participant_day,
  participant,
  admissibility,
  metric_support,
  placement,
  contract
) {
  validate_h01_base_inputs(
    participant_day,
    participant,
    placement,
    contract
  )
  participant_context <- h01_build_participant_context(
    participant_day,
    participant,
    placement
  )
  rows <- vector("list", nrow(contract))
  for (index in seq_len(nrow(contract))) {
    specification <- contract[index, , drop = FALSE]
    source_field <- specification$source_field[[1L]]
    if (specification$analysis_unit[[1L]] == "participant_day") {
      metric_rows <- participant_day |>
        dplyr::transmute(
          hypothesis_id = "H01",
          placement = as.character(.data$position),
          scenario = "all_available",
          metric_order = specification$metric_order[[1L]],
          metric_id = specification$metric_id[[1L]],
          analysis_unit = "participant_day",
          .data$site,
          .data$Id,
          .data$position,
          .data$local_date,
          participant_days_contributing = 1L,
          .data$profile_variant,
          .data$measurement_construct,
          .data$prepared_record_support_available,
          .data$prepared_record_support_unavailability_reason,
          prepared_record_expected_minutes = .data$expected_real_minutes,
          prepared_record_valid_melEDI_minutes = .data$valid_medi_real_minutes,
          prepared_record_valid_illuminance_minutes = .data$valid_light_real_minutes,
          .data$photoperiod_hours,
          .data$latitude_deg,
          value = .data[[source_field]],
          source_unit = specification$source_unit[[1L]],
          manuscript_name = specification$manuscript_name[[1L]],
          manuscript_category = specification$manuscript_category[[1L]],
          display_unit = specification$display_unit[[1L]],
          variant_label = specification$variant_label[[1L]],
          value_definition = specification$value_definition[[1L]]
        )
    } else {
      metric_rows <- participant |>
        dplyr::left_join(
          participant_context,
          by = c("site", "Id", "position"),
          relationship = "one-to-one"
        ) |>
        dplyr::transmute(
          hypothesis_id = "H01",
          placement = as.character(.data$position),
          scenario = "all_available",
          metric_order = specification$metric_order[[1L]],
          metric_id = specification$metric_id[[1L]],
          analysis_unit = "participant",
          .data$site,
          .data$Id,
          .data$position,
          local_date = as.Date(NA),
          .data$participant_days_contributing,
          .data$profile_variant,
          .data$measurement_construct,
          .data$prepared_record_support_available,
          .data$prepared_record_support_unavailability_reason,
          prepared_record_expected_minutes = .data$expected_minutes,
          prepared_record_valid_melEDI_minutes = .data$valid_minutes,
          prepared_record_valid_illuminance_minutes = NA_real_,
          .data$photoperiod_hours,
          .data$latitude_deg,
          value = .data[[source_field]],
          source_unit = specification$source_unit[[1L]],
          manuscript_name = specification$manuscript_name[[1L]],
          manuscript_category = specification$manuscript_category[[1L]],
          display_unit = specification$display_unit[[1L]],
          variant_label = specification$variant_label[[1L]],
          value_definition = specification$value_definition[[1L]]
        )
    }
    rows[[index]] <- metric_rows
  }
  output <- dplyr::bind_rows(rows) |>
    dplyr::arrange(
      .data$metric_order,
      .data$site,
      .data$Id,
      .data$local_date
    )
  output <- h01_join_admissibility(
    output,
    admissibility,
    placement,
    contract
  )
  output <- h01_join_metric_support(
    output,
    metric_support,
    placement,
    contract
  )
  h01_add_model_flags(output)
}

h01_paired_common_day_keys <- function(all_available_rows) {
  day_keys <- all_available_rows |>
    dplyr::filter(.data$analysis_unit == "participant_day") |>
    dplyr::distinct(
      .data$data_scenario_id,
      .data$model_implementation_id,
      .data$placement,
      .data$site,
      .data$Id,
      .data$local_date
    )
  day_keys |>
    dplyr::count(
      .data$data_scenario_id,
      .data$model_implementation_id,
      .data$site,
      .data$Id,
      .data$local_date,
      name = "placements"
    ) |>
    dplyr::filter(.data$placements == length(h01_placements())) |>
    dplyr::select(-"placements")
}

h01_build_paired_daily_rows <- function(all_available_rows) {
  common_keys <- h01_paired_common_day_keys(all_available_rows)
  paired <- all_available_rows |>
    dplyr::filter(.data$analysis_unit == "participant_day") |>
    dplyr::inner_join(
      common_keys,
      by = c(
        "data_scenario_id",
        "model_implementation_id",
        "site",
        "Id",
        "local_date"
      ),
      relationship = "many-to-one"
    )
  pair_status <- paired |>
    dplyr::group_by(
      .data$data_scenario_id,
      .data$model_implementation_id,
      .data$metric_order,
      .data$metric_id,
      .data$site,
      .data$Id,
      .data$local_date
    ) |>
    dplyr::summarise(
      placements = dplyr::n_distinct(.data$placement),
      glasses_metric_estimable = .data$metric_estimable[
        .data$placement == "glasses"
      ],
      chest_metric_estimable = .data$metric_estimable[
        .data$placement == "chest"
      ],
      glasses_metric_reason = .data$metric_failure_reason[
        .data$placement == "glasses"
      ],
      chest_metric_reason = .data$metric_failure_reason[
        .data$placement == "chest"
      ],
      glasses_site_included = .data$site_photoperiod_included[
        .data$placement == "glasses"
      ],
      chest_site_included = .data$site_photoperiod_included[
        .data$placement == "chest"
      ],
      glasses_latitude_included = .data$latitude_photoperiod_included[
        .data$placement == "glasses"
      ],
      chest_latitude_included = .data$latitude_photoperiod_included[
        .data$placement == "chest"
      ],
      glasses_site_reason = .data$site_photoperiod_exclusion_reason[
        .data$placement == "glasses"
      ],
      chest_site_reason = .data$site_photoperiod_exclusion_reason[
        .data$placement == "chest"
      ],
      glasses_latitude_reason = .data$latitude_photoperiod_exclusion_reason[
        .data$placement == "glasses"
      ],
      chest_latitude_reason = .data$latitude_photoperiod_exclusion_reason[
        .data$placement == "chest"
      ],
      .groups = "drop"
    )
  if (
    any(pair_status$placements != 2L) ||
      any(lengths(pair_status$glasses_metric_estimable) != 1L) ||
      any(lengths(pair_status$chest_metric_estimable) != 1L)
  ) {
    h01_abort("H01 paired daily keys do not contain one row per placement")
  }
  paired <- paired |>
    dplyr::left_join(
      pair_status,
      by = c(
        "data_scenario_id",
        "model_implementation_id",
        "metric_order",
        "metric_id",
        "site",
        "Id",
        "local_date"
      ),
      relationship = "many-to-one"
    ) |>
    dplyr::mutate(
      scenario = "paired_common_sample",
      pair_metric_estimable = .data$glasses_metric_estimable &
        .data$chest_metric_estimable,
      scenario_estimable = .data$pair_metric_estimable,
      scenario_failure_reason = dplyr::case_when(
        .data$scenario_estimable ~ NA_character_,
        !.data$metric_estimable ~ .data$metric_failure_reason,
        .data$placement == "glasses" ~
          paste0(
            "paired_other_placement:",
            .data$chest_metric_reason
          ),
        TRUE ~
          paste0(
            "paired_other_placement:",
            .data$glasses_metric_reason
          )
      ),
      site_photoperiod_included = .data$glasses_site_included &
        .data$chest_site_included,
      latitude_photoperiod_included = .data$glasses_latitude_included &
        .data$chest_latitude_included,
      site_photoperiod_exclusion_reason = dplyr::case_when(
        .data$site_photoperiod_included ~ NA_character_,
        .data$placement == "glasses" &
          !.data$glasses_site_included ~
          .data$glasses_site_reason,
        .data$placement == "chest" &
          !.data$chest_site_included ~
          .data$chest_site_reason,
        .data$placement == "glasses" ~
          paste0(
            "paired_other_placement:",
            .data$chest_site_reason
          ),
        TRUE ~
          paste0(
            "paired_other_placement:",
            .data$glasses_site_reason
          )
      ),
      latitude_photoperiod_exclusion_reason = dplyr::case_when(
        .data$latitude_photoperiod_included ~ NA_character_,
        .data$placement == "glasses" &
          !.data$glasses_latitude_included ~
          .data$glasses_latitude_reason,
        .data$placement == "chest" &
          !.data$chest_latitude_included ~
          .data$chest_latitude_reason,
        .data$placement == "glasses" ~
          paste0(
            "paired_other_placement:",
            .data$chest_latitude_reason
          ),
        TRUE ~
          paste0(
            "paired_other_placement:",
            .data$glasses_latitude_reason
          )
      )
    ) |>
    dplyr::select(
      -dplyr::all_of(c(
        "placements",
        "pair_metric_estimable",
        "glasses_metric_estimable",
        "chest_metric_estimable",
        "glasses_metric_reason",
        "chest_metric_reason",
        "glasses_site_included",
        "chest_site_included",
        "glasses_latitude_included",
        "chest_latitude_included",
        "glasses_site_reason",
        "chest_site_reason",
        "glasses_latitude_reason",
        "chest_latitude_reason"
      ))
    ) |>
    dplyr::arrange(
      .data$metric_order,
      .data$placement,
      .data$site,
      .data$Id,
      .data$local_date
    )
  paired
}

h01_build_model_rows_from_inputs <- function(
  inputs,
  contract,
  data_scenario_id = "main",
  model_implementation_id = "hypothesis_models"
) {
  h01_validate_data_scenario_id(data_scenario_id)
  h01_validate_data_scenario_id(model_implementation_id)
  if (
    !is.list(inputs) ||
      !identical(sort(names(inputs)), sort(h01_placements()))
  ) {
    h01_abort("H01 input bundle must contain glasses and chest")
  }
  all_rows <- lapply(h01_placements(), function(placement) {
    placement_inputs <- inputs[[placement]]
    required <- c(
      "participant_day",
      "participant",
      "admissibility",
      "metric_support"
    )
    if (
      !is.list(placement_inputs) ||
        !all(required %in% names(placement_inputs))
    ) {
      h01_abort(
        "H01 `%s` input bundle is missing required objects",
        placement
      )
    }
    h01_build_all_available_rows(
      participant_day = placement_inputs$participant_day,
      participant = placement_inputs$participant,
      admissibility = placement_inputs$admissibility,
      metric_support = placement_inputs$metric_support,
      placement = placement,
      contract = contract
    )
  })
  all_available_rows <- dplyr::bind_rows(all_rows) |>
    dplyr::mutate(
      data_scenario_id = data_scenario_id,
      model_implementation_id = model_implementation_id,
      .before = 1L
    )
  paired_daily_rows <- h01_build_paired_daily_rows(all_available_rows)
  h01_add_predictor_centers(
    dplyr::bind_rows(all_available_rows, paired_daily_rows)
  )
}

h01_add_predictor_centers <- function(rows) {
  rows <- rows |>
    dplyr::mutate(
      center_group = ifelse(
        .data$scenario == "paired_common_sample",
        paste(
          .data$data_scenario_id,
          .data$model_implementation_id,
          .data$scenario,
          .data$metric_id,
          sep = "::"
        ),
        paste(
          .data$data_scenario_id,
          .data$model_implementation_id,
          .data$scenario,
          .data$placement,
          .data$metric_id,
          sep = "::"
        )
      )
    )
  center_groups <- unique(rows$center_group)
  centers <- lapply(center_groups, function(group) {
    data <- rows[rows$center_group == group, , drop = FALSE]
    site_rows <- data[data$site_photoperiod_included, , drop = FALSE]
    latitude_rows <- data[
      data$latitude_photoperiod_included,
      ,
      drop = FALSE
    ]
    latitude_sites <- latitude_rows |>
      dplyr::distinct(.data$site, .data$absolute_latitude_10deg)
    tibble::tibble(
      center_group = group,
      data_scenario_id = unique(data$data_scenario_id),
      model_implementation_id = unique(data$model_implementation_id),
      scenario = unique(data$scenario),
      placement_scope = if (unique(data$scenario) == "paired_common_sample") {
        "paired_placements"
      } else {
        unique(data$placement)
      },
      metric_id = unique(data$metric_id),
      photoperiod_center_hours = if (nrow(site_rows) > 0L) {
        mean(site_rows$photoperiod_hours)
      } else {
        NA_real_
      },
      photoperiod_center_rows = nrow(site_rows),
      absolute_latitude_center_10deg = if (nrow(latitude_sites) > 0L) {
        mean(latitude_sites$absolute_latitude_10deg)
      } else {
        NA_real_
      },
      latitude_center_sites = nrow(latitude_sites),
      latitude_center_weighting = "equal_across_observed_sites"
    )
  }) |>
    dplyr::bind_rows()
  output <- rows |>
    dplyr::left_join(
      centers |>
        dplyr::select(dplyr::all_of(c(
          "center_group",
          "photoperiod_center_hours",
          "absolute_latitude_center_10deg"
        ))),
      by = "center_group",
      relationship = "many-to-one"
    ) |>
    dplyr::mutate(
      photoperiod_centered_hours = .data$photoperiod_hours -
        .data$photoperiod_center_hours,
      absolute_latitude_10deg_centered = .data$absolute_latitude_10deg -
        .data$absolute_latitude_center_10deg
    ) |>
    dplyr::select(-"center_group")
  list(rows = output, centers = centers)
}

h01_scenario_status <- function(
  contract,
  data_scenario_id = "main",
  model_implementation_id = "hypothesis_models"
) {
  h01_validate_data_scenario_id(data_scenario_id)
  h01_validate_data_scenario_id(model_implementation_id)
  all_available <- tidyr::crossing(
    data_scenario_id = data_scenario_id,
    model_implementation_id = model_implementation_id,
    placement = h01_placements(),
    scenario = "all_available",
    contract |>
      dplyr::select(dplyr::all_of(c(
        "metric_order",
        "metric_id",
        "analysis_unit"
      )))
  ) |>
    dplyr::mutate(
      available = TRUE,
      availability_reason = NA_character_
    )
  paired <- tidyr::crossing(
    data_scenario_id = data_scenario_id,
    model_implementation_id = model_implementation_id,
    placement = h01_placements(),
    scenario = "paired_common_sample",
    contract |>
      dplyr::select(dplyr::all_of(c(
        "metric_order",
        "metric_id",
        "analysis_unit"
      )))
  ) |>
    dplyr::mutate(
      available = .data$analysis_unit == "participant_day",
      availability_reason = ifelse(
        .data$available,
        NA_character_,
        paste0(
          "paired_common_sample_participant_metric_requires_",
          "minute_level_is_iv_recomputation"
        )
      )
    )
  dplyr::bind_rows(all_available, paired) |>
    dplyr::mutate(
      status = ifelse(.data$available, "AVAILABLE", "UNAVAILABLE")
    ) |>
    dplyr::arrange(
      .data$data_scenario_id,
      .data$model_implementation_id,
      factor(.data$scenario, levels = h01_scenarios()),
      factor(.data$placement, levels = h01_placements()),
      .data$metric_order
    )
}

h01_count_selected_rows <- function(data, selected, scope, site_value) {
  chosen <- data[selected, , drop = FALSE]
  analysis_unit <- unique(data$analysis_unit)
  if (length(analysis_unit) != 1L) {
    h01_abort("H01 sample-flow rows mix analysis units")
  }
  complete_total <- function(value) {
    if (length(value) == 0L) {
      return(0)
    }
    if (any(!is.finite(value))) {
      return(NA_real_)
    }
    sum(value)
  }
  tibble::tibble(
    scope = scope,
    site = site_value,
    model_observations = nrow(chosen),
    participants = dplyr::n_distinct(chosen$participant_key),
    participant_days = if (analysis_unit == "participant_day") {
      nrow(chosen)
    } else {
      NA_integer_
    },
    participant_hours = NA_integer_,
    contributing_participant_days = sum(
      chosen$participant_days_contributing,
      na.rm = TRUE
    ),
    metric_support_missing_observations = sum(
      !is.finite(chosen$metric_support_valid_minutes) |
        !is.finite(chosen$metric_support_expected_minutes)
    ),
    metric_support_valid_hours = complete_total(
      chosen$metric_support_valid_minutes
    ) /
      60,
    metric_support_expected_hours = complete_total(
      chosen$metric_support_expected_minutes
    ) /
      60,
    prepared_record_support_missing_observations = sum(
      !chosen$prepared_record_support_available
    ),
    prepared_record_valid_melEDI_hours = complete_total(
      chosen$prepared_record_valid_melEDI_minutes
    ) /
      60,
    prepared_record_valid_illuminance_hours = complete_total(
      chosen$prepared_record_valid_illuminance_minutes
    ) /
      60,
    sites = dplyr::n_distinct(chosen$site),
    excluded_observations = nrow(data) - nrow(chosen)
  )
}

h01_build_sample_flow <- function(rows, scenario_status) {
  stages <- c(
    prepared_rows = NA_character_,
    metric_estimable = "scenario_estimable",
    site_photoperiod_model = "site_photoperiod_included",
    latitude_photoperiod_model = "latitude_photoperiod_included"
  )
  combinations <- rows |>
    dplyr::distinct(
      .data$placement,
      .data$data_scenario_id,
      .data$model_implementation_id,
      .data$scenario,
      .data$metric_order,
      .data$metric_id,
      .data$analysis_unit
    )
  output <- list()
  output_index <- 0L
  for (index in seq_len(nrow(combinations))) {
    combination <- combinations[index, , drop = FALSE]
    data <- rows[
      rows$data_scenario_id == combination$data_scenario_id[[1L]] &
        rows$model_implementation_id ==
          combination$model_implementation_id[[1L]] &
        rows$placement == combination$placement[[1L]] &
        rows$scenario == combination$scenario[[1L]] &
        rows$metric_id == combination$metric_id[[1L]],
      ,
      drop = FALSE
    ]
    sites <- c("ALL", sort(unique(data$site)))
    for (stage in names(stages)) {
      flag <- stages[[stage]]
      selected <- if (is.na(flag)) {
        rep(TRUE, nrow(data))
      } else {
        data[[flag]]
      }
      for (site in sites) {
        site_data <- if (site == "ALL") {
          data
        } else {
          data[data$site == site, , drop = FALSE]
        }
        site_selected <- if (site == "ALL") {
          selected
        } else {
          selected[data$site == site]
        }
        output_index <- output_index + 1L
        counts <- h01_count_selected_rows(
          site_data,
          site_selected,
          scope = if (site == "ALL") "overall" else "site",
          site_value = site
        )
        output[[output_index]] <- dplyr::bind_cols(
          combination,
          tibble::tibble(stage = stage),
          counts,
          tibble::tibble(status = "AVAILABLE")
        )
      }
    }
  }
  available <- dplyr::bind_rows(output)
  unavailable <- scenario_status |>
    dplyr::filter(!.data$available) |>
    tidyr::crossing(stage = names(stages)) |>
    dplyr::transmute(
      .data$placement,
      .data$data_scenario_id,
      .data$model_implementation_id,
      .data$scenario,
      .data$metric_order,
      .data$metric_id,
      .data$analysis_unit,
      .data$stage,
      scope = "overall",
      site = "ALL",
      model_observations = NA_integer_,
      participants = NA_integer_,
      participant_days = NA_integer_,
      participant_hours = NA_integer_,
      contributing_participant_days = NA_integer_,
      metric_support_missing_observations = NA_integer_,
      metric_support_valid_hours = NA_real_,
      metric_support_expected_hours = NA_real_,
      prepared_record_support_missing_observations = NA_integer_,
      prepared_record_valid_melEDI_hours = NA_real_,
      prepared_record_valid_illuminance_hours = NA_real_,
      sites = NA_integer_,
      excluded_observations = NA_integer_,
      status = "UNAVAILABLE"
    )
  dplyr::bind_rows(available, unavailable) |>
    dplyr::arrange(
      .data$data_scenario_id,
      .data$model_implementation_id,
      factor(.data$scenario, levels = h01_scenarios()),
      factor(.data$placement, levels = h01_placements()),
      .data$metric_order,
      factor(.data$stage, levels = names(stages)),
      dplyr::desc(.data$scope),
      .data$site
    )
}

h01_build_exclusion_summary <- function(rows, scenario_status) {
  site <- rows |>
    dplyr::filter(!.data$site_photoperiod_included) |>
    dplyr::count(
      .data$placement,
      .data$data_scenario_id,
      .data$model_implementation_id,
      .data$scenario,
      .data$metric_order,
      .data$metric_id,
      .data$analysis_unit,
      model_question = "site_and_photoperiod",
      exclusion_reason = .data$site_photoperiod_exclusion_reason,
      name = "rows"
    )
  latitude <- rows |>
    dplyr::filter(!.data$latitude_photoperiod_included) |>
    dplyr::count(
      .data$placement,
      .data$data_scenario_id,
      .data$model_implementation_id,
      .data$scenario,
      .data$metric_order,
      .data$metric_id,
      .data$analysis_unit,
      model_question = "latitude_and_photoperiod",
      exclusion_reason = .data$latitude_photoperiod_exclusion_reason,
      name = "rows"
    )
  unavailable <- scenario_status |>
    dplyr::filter(!.data$available) |>
    tidyr::crossing(
      model_question = c(
        "site_and_photoperiod",
        "latitude_and_photoperiod"
      )
    ) |>
    dplyr::transmute(
      .data$placement,
      .data$data_scenario_id,
      .data$model_implementation_id,
      .data$scenario,
      .data$metric_order,
      .data$metric_id,
      .data$analysis_unit,
      .data$model_question,
      exclusion_reason = .data$availability_reason,
      rows = NA_integer_
    )
  dplyr::bind_rows(site, latitude, unavailable) |>
    dplyr::arrange(
      .data$data_scenario_id,
      .data$model_implementation_id,
      factor(.data$scenario, levels = h01_scenarios()),
      factor(.data$placement, levels = h01_placements()),
      .data$metric_order,
      .data$model_question,
      .data$exclusion_reason
    )
}

h01_variable_dictionary <- function() {
  tibble::tribble(
    ~variable,
    ~meaning,
    "data_scenario_id",
    "Prepared-data input used with the unchanged H01 model-data rules",
    "model_implementation_id",
    "Model implementation used for both the main and prepared-data sensitivity inputs",
    "placement",
    "Sensor placement: near-eye glasses or chest",
    "scenario",
    "All available data or paired common participant-days",
    "metric_id",
    "Stable internal identifier for one of the 17 H01 metrics",
    "analysis_unit",
    "One participant or one participant-day",
    "site",
    "Study-site code",
    "Id",
    "Participant identifier within site",
    "local_date",
    "Participant-local calendar date; missing for participant metrics",
    "participant_days_contributing",
    "Number of participant-days represented by the model row",
    "prepared_record_expected_minutes",
    "Expected minutes in the prepared 24-hour record represented by the row",
    "prepared_record_valid_melEDI_minutes",
    "Valid melEDI minutes in the prepared 24-hour record represented by the row",
    "prepared_record_valid_illuminance_minutes",
    paste0(
      "Valid illuminance minutes in the prepared 24-hour record; ",
      "not applicable to IS or IV"
    ),
    "metric_support_valid_minutes",
    "Valid minutes in the time window used to calculate this metric",
    "metric_support_expected_minutes",
    "Expected minutes in the time window used to calculate this metric",
    "prepared_record_support_available",
    "Whether exact support minutes are available for the prepared 24-hour record",
    "prepared_record_support_unavailability_reason",
    "Reason exact prepared-record support minutes are unavailable",
    "metric_support_available",
    "Whether exact support minutes are available for this metric value",
    "metric_support_unavailability_reason",
    "Reason exact metric-support minutes are unavailable",
    "value",
    "Untransformed metric value in source_unit",
    "metric_estimable",
    "Whether the metric producer declared the value estimable",
    "metric_failure_reason",
    "Exact producer-recorded reason when the metric is not estimable",
    "scenario_estimable",
    "Whether the metric is available under the selected data scenario",
    "scenario_failure_reason",
    "Exact reason the metric is unavailable under the selected data scenario",
    "photoperiod_hours",
    "Civil-dawn to civil-dusk duration in hours",
    "photoperiod_centered_hours",
    "Photoperiod minus the exact model-frame mean",
    "latitude_deg",
    "Signed site latitude in degrees",
    "absolute_latitude_10deg",
    "Absolute site latitude in units of 10 degrees",
    "absolute_latitude_10deg_centered",
    "Absolute latitude minus the equal-site mean for the model frame",
    "site_photoperiod_included",
    "Exact row flag for the site and photoperiod full/reduced comparison",
    "site_photoperiod_exclusion_reason",
    "Reason a row is absent from the site and photoperiod comparison",
    "latitude_photoperiod_included",
    "Exact row flag for the latitude and photoperiod full/reduced comparison",
    "latitude_photoperiod_exclusion_reason",
    "Reason a row is absent from the latitude and photoperiod comparison",
    "model_observations",
    "Number of participant or participant-day values fitted in the model",
    "participants",
    "Number of distinct participants fitted in the model",
    "participant_days",
    "Number of participant-days fitted; not applicable to participant-level models",
    "participant_hours",
    "Number of participant-hours fitted; not applicable to H01 models",
    "contributing_participant_days",
    "Participant-days used to derive the fitted metric values",
    "metric_support_missing_observations",
    "Fitted values for which the metric producer did not report support minutes",
    "metric_support_valid_hours",
    "Valid hours in the time window used to calculate the fitted metric values",
    "metric_support_expected_hours",
    "Expected hours in the time window used to calculate the fitted metric values",
    "prepared_record_valid_melEDI_hours",
    paste0(
      "Valid melEDI hours in the complete prepared 24-hour records ",
      "represented by the fitted values"
    ),
    "prepared_record_valid_illuminance_hours",
    "Valid illuminance hours in those complete prepared 24-hour records",
    "prepared_record_support_missing_observations",
    paste0(
      "Fitted values for which exact support minutes for the complete ",
      "prepared record are unavailable"
    ),
    "excluded_observations",
    "Prepared participant or participant-day values excluded before fitting"
  )
}

h01_output_contract <- function() {
  list(
    top_level = c(
      "hypothesis_id",
      "model_rows",
      "metric_contract",
      "sample_flow",
      "exclusion_reasons",
      "scenario_status",
      "predictor_centers",
      "variable_dictionary",
      "metadata"
    ),
    model_row_key = c(
      "placement",
      "data_scenario_id",
      "model_implementation_id",
      "scenario",
      "metric_id",
      "site",
      "Id",
      "local_date"
    ),
    unavailable_scenario_reason = paste0(
      "paired_common_sample_participant_metric_requires_",
      "minute_level_is_iv_recomputation"
    )
  )
}
