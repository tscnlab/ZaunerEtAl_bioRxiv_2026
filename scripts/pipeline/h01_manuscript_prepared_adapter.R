# Adapt the verified manuscript-prepared metrics to the shared H01 model-data
# contract without fitting models.
#
# Source paths_io.R, assertions.R, metric_display_registry.R,
# manuscript_prepared_data.R, build_manuscript_prepared_data.R, and
# h01_model_data.R before this file.

h01_manuscript_prepared_scenario_id <- function() {
  manuscript_prepared_scenario_id()
}

h01_manuscript_prepared_model_implementation_id <- function() {
  manuscript_prepared_model_implementation_id()
}

h01_manuscript_prepared_support_reason <- function() {
  paste0(
    "manuscript_prepared_artifacts_do_not_retain_",
    "exact_support_minutes"
  )
}

h01_manuscript_prepared_missing_metric_reason <- function() {
  "manuscript_prepared_nonestimable_reason_not_recorded"
}

h01_manuscript_prepared_measurement_construct <- function(position) {
  dplyr::case_when(
    position == "glasses" ~
      "hybrid_near_eye_wake_and_bedside_sleep_environment",
    position == "chest" ~
      "hybrid_chest_level_wake_and_bedside_sleep_environment",
    TRUE ~ NA_character_
  )
}

h01_manuscript_prepared_timing_metrics <- function() {
  c(
    "m10_midpoint",
    "l10_midpoint",
    "mean_timing_above_250",
    "first_timing_above_250",
    "last_timing_above_250"
  )
}

h01_manuscript_prepared_output_paths <- function(
  root = project_root(),
  output_root = root
) {
  root <- normalizePath(root, winslash = "/", mustWork = TRUE)
  output_root <- normalizePath(
    output_root,
    winslash = "/",
    mustWork = TRUE
  )
  source_paths <- manuscript_prepared_output_paths(root, root)
  scenario_root <- file.path(
    output_root,
    "artifacts",
    "06_model_data",
    "H01",
    "scenarios",
    h01_manuscript_prepared_scenario_id()
  )
  support_root <- scenario_root
  csv <- c(
    model_rows = file.path(support_root, "model_rows.csv"),
    metric_contract = file.path(support_root, "metric_contract.csv"),
    sample_flow = file.path(support_root, "sample_flow.csv"),
    exclusion_reasons = file.path(support_root, "exclusion_reasons.csv"),
    scenario_status = file.path(support_root, "scenario_status.csv"),
    predictor_centers = file.path(support_root, "predictor_centers.csv"),
    variable_dictionary = file.path(support_root, "variable_dictionary.csv"),
    input_provenance = file.path(support_root, "input_provenance.csv"),
    contract_equivalence = file.path(
      support_root,
      "contract_equivalence.csv"
    ),
    timing_conversion_audit = file.path(
      support_root,
      "timing_conversion_audit.csv"
    )
  )
  list(
    root = root,
    output_root = output_root,
    source = source_paths,
    scenario_root = scenario_root,
    support_root = support_root,
    rds = file.path(scenario_root, "H01.rds"),
    csv = csv,
    manifest = file.path(
      output_root,
      "artifacts",
      "12_manifests",
      "H01_manuscript_prepared_data_artifacts.csv"
    )
  )
}

h01_manuscript_prepared_selected_crosswalk <- function(
  crosswalk,
  main_contract
) {
  assert_columns(
    crosswalk,
    c(
      "metric_id",
      "source_unit",
      "analysis_unit",
      "selected_for_h01",
      "value_definition",
      "manuscript_name",
      "abbreviation",
      "manuscript_category",
      "display_analysis_unit",
      "display_unit",
      "analytical_role",
      "variant_label"
    ),
    object = "manuscript-prepared metric crosswalk"
  )
  selected <- crosswalk |>
    dplyr::filter(.data$selected_for_h01) |>
    dplyr::arrange(match(.data$metric_id, main_contract$metric_id))
  if (
    nrow(selected) != nrow(main_contract) ||
      anyDuplicated(selected$metric_id) ||
      !identical(selected$metric_id, main_contract$metric_id)
  ) {
    h01_abort(
      "Manuscript-prepared H01 metrics differ from the 17-metric contract"
    )
  }
  timing <- selected$metric_id %in%
    h01_manuscript_prepared_timing_metrics()
  expected_source_unit <- ifelse(
    timing,
    "decimal_clock_hour",
    main_contract$source_unit
  )
  display_analysis_unit <- gsub(
    "-",
    "_",
    selected$display_analysis_unit,
    fixed = TRUE
  )
  if (
    any(selected$analysis_unit != main_contract$analysis_unit) ||
      any(selected$source_unit != expected_source_unit) ||
      any(selected$manuscript_name != main_contract$manuscript_name) ||
      any(selected$abbreviation != main_contract$abbreviation) ||
      any(
        selected$manuscript_category != main_contract$manuscript_category
      ) ||
      any(display_analysis_unit != main_contract$analysis_unit) ||
      any(selected$display_unit != main_contract$display_unit) ||
      any(selected$analytical_role != main_contract$analytical_role)
  ) {
    h01_abort(
      paste0(
        "Manuscript-prepared H01 crosswalk differs from the shared ",
        "analysis or display contract"
      )
    )
  }
  selected
}

h01_manuscript_prepared_contract <- function(
  crosswalk,
  main_contract
) {
  selected <- h01_manuscript_prepared_selected_crosswalk(
    crosswalk,
    main_contract
  )
  scenario_contract <- main_contract
  scenario_contract$variant_label <- selected$variant_label
  scenario_contract$value_definition <- selected$value_definition
  validate_h01_metric_contract(scenario_contract)
  expected_variants <- c(
    dose_time_sensitive_corrected_medi = "Uncorrected manuscript-prepared dose",
    mder_ratio_of_integrals = "Mean of epoch-wise melEDI/illuminance ratios"
  )
  expected_definitions <- c(
    dose_time_sensitive_corrected_medi = paste(
      "Manuscript-prepared melEDI dose without the new",
      "time-sensitive coverage correction"
    ),
    mder_ratio_of_integrals = paste(
      "Manuscript-prepared mean of epoch-wise MEDI/LIGHT ratios,",
      "not the new ratio of integrals"
    )
  )
  observed_variants <- stats::setNames(
    scenario_contract$variant_label,
    scenario_contract$metric_id
  )
  observed_definitions <- stats::setNames(
    scenario_contract$value_definition,
    scenario_contract$metric_id
  )
  changed_variants <- scenario_contract$metric_id[
    scenario_contract$variant_label != main_contract$variant_label
  ]
  if (
    !identical(
      unname(observed_variants[names(expected_variants)]),
      unname(expected_variants)
    ) ||
      !setequal(changed_variants, names(expected_variants)) ||
      !identical(
        unname(observed_definitions[names(expected_definitions)]),
        unname(expected_definitions)
      )
  ) {
    h01_abort(
      paste0(
        "Manuscript-prepared dose or MDER semantics are not explicit, ",
        "or another metric variant changed"
      )
    )
  }
  main_hash <- h01_implementation_contract_sha256(main_contract)
  scenario_hash <- h01_implementation_contract_sha256(
    scenario_contract
  )
  if (!identical(main_hash, scenario_hash)) {
    h01_abort(
      "Manuscript-prepared H01 implementation contract changed"
    )
  }
  list(
    contract = scenario_contract,
    crosswalk = selected,
    implementation_contract_sha256 = scenario_hash
  )
}

h01_clock_hour_to_minute <- function(value) {
  output <- rep(NA_real_, length(value))
  finite <- is.finite(value)
  output[finite] <- ((value[finite] %% 24) + 24) %% 24 * 60
  output
}

h01_manuscript_prepared_timing_audit <- function(before, after) {
  timing <- h01_manuscript_prepared_timing_metrics()
  selected <- before |>
    dplyr::filter(.data$metric_id %in% timing) |>
    dplyr::rename(input_value = "manuscript_prepared_value") |>
    dplyr::left_join(
      after |>
        dplyr::filter(.data$metric_id %in% timing) |>
        dplyr::select(
          dplyr::all_of(c(
            "position",
            "site",
            "Id",
            "local_date",
            "metric_id",
            "value"
          ))
        ),
      by = c("position", "site", "Id", "local_date", "metric_id"),
      relationship = "one-to-one"
    )
  finite_range <- function(value, which) {
    value <- value[is.finite(value)]
    if (length(value) == 0L) {
      return(NA_real_)
    }
    if (which == "min") min(value) else max(value)
  }
  selected |>
    dplyr::group_by(.data$position, .data$metric_id) |>
    dplyr::summarise(
      rows = dplyr::n(),
      finite_input_values = sum(is.finite(.data$input_value)),
      missing_input_values = sum(!is.finite(.data$input_value)),
      negative_input_values = sum(
        .data$input_value < 0,
        na.rm = TRUE
      ),
      input_values_outside_0_24 = sum(
        .data$input_value < 0 | .data$input_value >= 24,
        na.rm = TRUE
      ),
      wrapped_values = sum(
        .data$input_value < 0 | .data$input_value >= 24,
        na.rm = TRUE
      ),
      input_min_decimal_hour = finite_range(.data$input_value, "min"),
      input_max_decimal_hour = finite_range(.data$input_value, "max"),
      output_min_clock_minute = finite_range(.data$value, "min"),
      output_max_clock_minute = finite_range(.data$value, "max"),
      .groups = "drop"
    ) |>
    dplyr::mutate(
      data_scenario_id = h01_manuscript_prepared_scenario_id(),
      model_implementation_id = h01_manuscript_prepared_model_implementation_id(),
      input_unit = "decimal_clock_hour",
      output_unit = "clock_minute",
      transformation = "restore_modulo_24_then_convert_to_clock_minute",
      downstream_timing_handling = "nighttime_linearization_is_applied_once_in_the_model",
      .before = 1L
    )
}

h01_manuscript_prepared_contract_equivalence <- function(
  main_contract,
  scenario_contract,
  selected_crosswalk
) {
  main_hash <- h01_implementation_contract_sha256(main_contract)
  scenario_hash <- h01_implementation_contract_sha256(
    scenario_contract
  )
  tibble::tibble(
    data_scenario_id = h01_manuscript_prepared_scenario_id(),
    model_implementation_id = h01_manuscript_prepared_model_implementation_id(),
    metric_id = main_contract$metric_id,
    analysis_unit = main_contract$analysis_unit,
    source_field = main_contract$source_field,
    input_source_unit = selected_crosswalk$source_unit,
    shared_model_unit = scenario_contract$source_unit,
    timing_unit_conversion_required = selected_crosswalk$source_unit !=
      scenario_contract$source_unit,
    main_variant_label = main_contract$variant_label,
    scenario_variant_label = scenario_contract$variant_label,
    scenario_value_definition = scenario_contract$value_definition,
    implementation_fields_match = vapply(
      seq_len(nrow(main_contract)),
      function(index) {
        fields <- h01_implementation_contract_columns()
        identical(
          as.list(main_contract[index, fields, drop = FALSE]),
          as.list(scenario_contract[index, fields, drop = FALSE])
        )
      },
      logical(1)
    ),
    main_implementation_contract_sha256 = main_hash,
    scenario_implementation_contract_sha256 = scenario_hash
  )
}

h01_manuscript_prepared_validate_source_ids <- function(
  participant_day,
  participant
) {
  scenario_id <- h01_manuscript_prepared_scenario_id()
  implementation_id <-
    h01_manuscript_prepared_model_implementation_id()
  for (data in list(participant_day, participant)) {
    assert_columns(
      data,
      c(
        "scenario_id",
        "model_implementation_id",
        "position",
        "position_role"
      ),
      object = "manuscript-prepared H01 source"
    )
    role_valid <- (data$position == "glasses" &
      data$position_role == "near_eye_primary") |
      (data$position == "chest" &
        data$position_role == "complementary_chest")
    if (
      !identical(unique(data$scenario_id), scenario_id) ||
        !identical(
          unique(data$model_implementation_id),
          implementation_id
        ) ||
        !setequal(unique(data$position), h01_placements()) ||
        any(!role_valid)
    ) {
      h01_abort(
        "Manuscript-prepared source IDs differ from the declared scenario"
      )
    }
  }
  invisible(TRUE)
}

h01_manuscript_prepared_assert_complete_metric_grid <- function(
  data,
  contract,
  object
) {
  for (placement in h01_placements()) {
    placement_data <- data[data$position == placement, , drop = FALSE]
    expected_metrics <- contract$metric_id
    if (!setequal(unique(placement_data$metric_id), expected_metrics)) {
      h01_abort("%s does not contain every metric for `%s`", object, placement)
    }
    key <- if (identical(unique(contract$analysis_unit), "participant_day")) {
      c("site", "Id", "local_date")
    } else {
      c("site", "Id")
    }
    reference <- placement_data |>
      dplyr::filter(.data$metric_id == expected_metrics[[1L]]) |>
      dplyr::distinct(dplyr::across(dplyr::all_of(key)))
    for (metric_id in expected_metrics) {
      observed <- placement_data |>
        dplyr::filter(.data$metric_id == metric_id) |>
        dplyr::distinct(dplyr::across(dplyr::all_of(key)))
      if (
        nrow(dplyr::anti_join(reference, observed, by = key)) > 0L ||
          nrow(dplyr::anti_join(observed, reference, by = key)) > 0L
      ) {
        h01_abort(
          "%s metric `%s` has an incomplete `%s` key grid",
          object,
          metric_id,
          placement
        )
      }
    }
  }
  invisible(TRUE)
}

h01_manuscript_prepared_rename_metric_fields <- function(data, contract) {
  for (index in seq_len(nrow(contract))) {
    metric_id <- contract$metric_id[[index]]
    source_field <- contract$source_field[[index]]
    if (!metric_id %in% names(data)) {
      h01_abort(
        "Manuscript-prepared wide data are missing metric `%s`",
        metric_id
      )
    }
    names(data)[names(data) == metric_id] <- source_field
  }
  data
}

h01_build_manuscript_prepared_inputs <- function(root = project_root()) {
  root <- normalizePath(root, winslash = "/", mustWork = TRUE)
  paths <- h01_manuscript_prepared_output_paths(root, root)
  required <- c(
    paths$source$rds[["participant_day_metrics"]],
    paths$source$rds[["participant_metrics"]],
    paths$source$csv[["metric_crosswalk"]],
    file.path(
      root,
      "artifacts",
      "06_model_data",
      "context",
      "site_solar_context.rds"
    )
  )
  missing <- required[!file.exists(required)]
  if (length(missing) > 0L) {
    h01_abort(
      "Manuscript-prepared H01 adapter is missing input(s): %s",
      paste(missing, collapse = ", ")
    )
  }
  participant_day_source <- readRDS(
    paths$source$rds[["participant_day_metrics"]]
  )
  participant_source <- readRDS(
    paths$source$rds[["participant_metrics"]]
  )
  h01_manuscript_prepared_validate_source_ids(
    participant_day_source,
    participant_source
  )
  main_contract <- h01_metric_contract(root)
  crosswalk <- readr::read_csv(
    paths$source$csv[["metric_crosswalk"]],
    show_col_types = FALSE,
    progress = FALSE
  )
  contract_result <- h01_manuscript_prepared_contract(
    crosswalk,
    main_contract
  )
  contract <- contract_result$contract
  selected_crosswalk <- contract_result$crosswalk

  day_selected <- participant_day_source |>
    dplyr::filter(.data$metric_id %in% contract$metric_id)
  participant_selected <- participant_source |>
    dplyr::filter(.data$metric_id %in% contract$metric_id)
  assert_unique_key(
    day_selected,
    c("position", "site", "Id", "local_date", "metric_id"),
    object = "manuscript-prepared H01 participant-day metrics"
  )
  assert_unique_key(
    participant_selected,
    c("position", "site", "Id", "metric_id"),
    object = "manuscript-prepared H01 participant metrics"
  )
  h01_manuscript_prepared_assert_complete_metric_grid(
    day_selected,
    contract[contract$analysis_unit == "participant_day", , drop = FALSE],
    "Manuscript-prepared participant-day metrics"
  )
  h01_manuscript_prepared_assert_complete_metric_grid(
    participant_selected,
    contract[contract$analysis_unit == "participant", , drop = FALSE],
    "Manuscript-prepared participant metrics"
  )

  metric_units <- selected_crosswalk |>
    dplyr::select(
      "metric_id",
      input_unit = "source_unit",
      "analysis_unit"
    ) |>
    dplyr::left_join(
      contract |>
        dplyr::select(
          "metric_id",
          units = "source_unit"
        ),
      by = "metric_id",
      relationship = "one-to-one"
    )
  day_long <- day_selected |>
    dplyr::left_join(
      metric_units,
      by = "metric_id",
      relationship = "many-to-one"
    ) |>
    dplyr::mutate(
      value = ifelse(
        .data$metric_id %in%
          h01_manuscript_prepared_timing_metrics(),
        h01_clock_hour_to_minute(.data$manuscript_prepared_value),
        .data$manuscript_prepared_value
      )
    )
  if (
    anyNA(day_long$analysis_unit) ||
      any(day_long$analysis_unit != "participant_day")
  ) {
    h01_abort(
      "Manuscript-prepared daily metrics have invalid analysis units"
    )
  }
  timing_audit <- h01_manuscript_prepared_timing_audit(
    day_selected,
    day_long
  )
  l10_audit <- timing_audit |>
    dplyr::filter(.data$metric_id == "l10_midpoint")
  non_l10_audit <- timing_audit |>
    dplyr::filter(.data$metric_id != "l10_midpoint")
  raw_timing <- day_selected |>
    dplyr::filter(
      .data$metric_id %in% h01_manuscript_prepared_timing_metrics()
    )
  converted_timing <- day_long |>
    dplyr::filter(
      .data$metric_id %in% h01_manuscript_prepared_timing_metrics()
    )
  finite_timing <- is.finite(raw_timing$manuscript_prepared_value)
  reversible_difference <- abs(
    (converted_timing$value[finite_timing] /
      60 -
      raw_timing$manuscript_prepared_value[finite_timing] +
      12) %%
      24 -
      12
  )
  if (
    sum(l10_audit$negative_input_values) != 62L ||
      l10_audit$negative_input_values[
        l10_audit$position == "glasses"
      ] !=
        29L ||
      l10_audit$negative_input_values[
        l10_audit$position == "chest"
      ] !=
        33L ||
      sum(timing_audit$wrapped_values) != 62L ||
      any(non_l10_audit$input_values_outside_0_24 != 0L) ||
      any(
        raw_timing$manuscript_prepared_value >= 24,
        na.rm = TRUE
      ) ||
      !identical(
        is.finite(raw_timing$manuscript_prepared_value),
        is.finite(converted_timing$value)
      ) ||
      any(reversible_difference > 1e-12) ||
      any(
        is.finite(day_long$value) &
          day_long$units == "clock_minute" &
          (day_long$value < 0 | day_long$value >= 1440)
      )
  ) {
    h01_abort(
      "Manuscript-prepared timing conversion differs from its audit contract"
    )
  }

  day_wide <- day_long |>
    dplyr::select(
      dplyr::all_of(c(
        "site",
        "Id",
        "position",
        "local_date",
        "metric_id",
        "value"
      ))
    ) |>
    tidyr::pivot_wider(
      names_from = "metric_id",
      values_from = "value"
    )
  day_wide <- h01_manuscript_prepared_rename_metric_fields(
    day_wide,
    contract[contract$analysis_unit == "participant_day", , drop = FALSE]
  )
  context <- readRDS(file.path(
    root,
    "artifacts",
    "06_model_data",
    "context",
    "site_solar_context.rds"
  )) |>
    dplyr::select(
      "site",
      "local_date",
      "photoperiod_hours",
      "latitude_deg"
    )
  assert_unique_key(
    context,
    c("site", "local_date"),
    object = "verified site and solar context"
  )
  day_wide <- day_wide |>
    dplyr::left_join(
      context,
      by = c("site", "local_date"),
      relationship = "many-to-one"
    ) |>
    dplyr::mutate(
      profile_variant = h01_manuscript_prepared_scenario_id(),
      measurement_construct = h01_manuscript_prepared_measurement_construct(
        .data$position
      ),
      prepared_record_support_available = FALSE,
      prepared_record_support_unavailability_reason = h01_manuscript_prepared_support_reason(),
      expected_real_minutes = NA_real_,
      valid_medi_real_minutes = NA_real_,
      valid_light_real_minutes = NA_real_,
      .after = "local_date"
    )
  if (
    any(!is.finite(day_wide$photoperiod_hours)) ||
      any(!is.finite(day_wide$latitude_deg))
  ) {
    h01_abort(
      "Manuscript-prepared H01 participant-days lack site context"
    )
  }

  participant_units <- metric_units |>
    dplyr::filter(.data$analysis_unit == "participant")
  participant_long <- participant_selected |>
    dplyr::left_join(
      participant_units,
      by = "metric_id",
      relationship = "many-to-one"
    ) |>
    dplyr::rename(value = "manuscript_prepared_value")
  if (
    anyNA(participant_long$analysis_unit) ||
      any(participant_long$analysis_unit != "participant")
  ) {
    h01_abort(
      "Manuscript-prepared participant metrics have invalid analysis units"
    )
  }
  participant_wide <- participant_long |>
    dplyr::select(
      dplyr::all_of(c(
        "site",
        "Id",
        "position",
        "metric_id",
        "value"
      ))
    ) |>
    tidyr::pivot_wider(
      names_from = "metric_id",
      values_from = "value"
    )
  participant_wide <- h01_manuscript_prepared_rename_metric_fields(
    participant_wide,
    contract[contract$analysis_unit == "participant", , drop = FALSE]
  )
  contributing_days <- day_wide |>
    dplyr::count(
      .data$site,
      .data$Id,
      .data$position,
      name = "days"
    )
  participant_wide <- participant_wide |>
    dplyr::left_join(
      contributing_days,
      by = c("site", "Id", "position"),
      relationship = "one-to-one"
    ) |>
    dplyr::mutate(
      profile_variant = h01_manuscript_prepared_scenario_id(),
      measurement_construct = h01_manuscript_prepared_measurement_construct(
        .data$position
      ),
      prepared_record_support_available = FALSE,
      prepared_record_support_unavailability_reason = h01_manuscript_prepared_support_reason(),
      valid_minutes = NA_real_,
      expected_minutes = NA_real_,
      .after = "position"
    )

  combined_long <- dplyr::bind_rows(
    day_long |>
      dplyr::select(
        "site",
        "Id",
        "position",
        "local_date",
        "analysis_unit",
        metric = "metric_id",
        "value",
        "units"
      ),
    participant_long |>
      dplyr::transmute(
        .data$site,
        .data$Id,
        .data$position,
        local_date = as.Date(NA),
        .data$analysis_unit,
        metric = .data$metric_id,
        .data$value,
        .data$units
      )
  ) |>
    dplyr::mutate(
      profile_variant = h01_manuscript_prepared_scenario_id(),
      estimable = is.finite(.data$value),
      failure_reason = ifelse(
        .data$estimable,
        NA_character_,
        h01_manuscript_prepared_missing_metric_reason()
      ),
      .after = "local_date"
    )
  admissibility <- combined_long |>
    dplyr::transmute(
      .data$site,
      .data$Id,
      .data$position,
      .data$local_date,
      .data$profile_variant,
      .data$analysis_unit,
      .data$metric,
      .data$estimable,
      .data$failure_reason,
      left_censored = NA,
      right_censored = NA,
      any_censored = NA
    )
  metric_support <- combined_long |>
    dplyr::transmute(
      .data$site,
      .data$Id,
      .data$position,
      .data$local_date,
      .data$profile_variant,
      .data$analysis_unit,
      .data$metric,
      .data$value,
      .data$units,
      .data$estimable,
      .data$failure_reason,
      metric_support_available = FALSE,
      metric_support_unavailability_reason = h01_manuscript_prepared_support_reason(),
      valid_minutes = NA_real_,
      expected_minutes = NA_real_
    )

  inputs <- lapply(h01_placements(), function(placement) {
    list(
      participant_day = day_wide |>
        dplyr::filter(.data$position == placement),
      participant = participant_wide |>
        dplyr::filter(.data$position == placement),
      admissibility = admissibility |>
        dplyr::filter(.data$position == placement),
      metric_support = metric_support |>
        dplyr::filter(.data$position == placement)
    )
  })
  names(inputs) <- h01_placements()
  equivalence <- h01_manuscript_prepared_contract_equivalence(
    main_contract,
    contract,
    selected_crosswalk
  )
  list(
    inputs = inputs,
    main_contract = main_contract,
    contract = contract,
    selected_crosswalk = selected_crosswalk,
    contract_equivalence = equivalence,
    timing_conversion_audit = timing_audit,
    implementation_contract_sha256 = contract_result$implementation_contract_sha256
  )
}
