h05_abort <- function(message, ..., call. = FALSE) {
  stop(sprintf(message, ...), call. = call.)
}

h05_factor_registry <- function() {
  tibble::tribble(
    ~factor_order,
    ~factor_id,
    ~factor_label,
    ~direction_text,
    ~first_item,
    ~last_item,
    ~reverse_item,
    ~possible_min,
    ~possible_max,
    1L,
    "leba_f2",
    "Spending time outdoors",
    "Higher scores indicate more frequent reported time outdoors",
    4L,
    9L,
    "leba_f2_04",
    6L,
    30L,
    2L,
    "leba_f3",
    "Using phones and smartwatches in bed before sleep",
    paste0(
      "Higher scores indicate more frequent reported phone and smartwatch ",
      "use in bed before sleep"
    ),
    10L,
    14L,
    NA_character_,
    5L,
    25L,
    3L,
    "leba_f4",
    "Controlling and using ambient light before bedtime",
    paste0(
      "Higher scores indicate more frequent reported light/screen-control ",
      "or light-reduction behaviours before sleep"
    ),
    15L,
    18L,
    NA_character_,
    4L,
    20L,
    4L,
    "leba_f5",
    "Using light in the morning and during daytime",
    paste0(
      "Higher scores indicate more frequent reported light use in the ",
      "morning and during daytime"
    ),
    19L,
    23L,
    NA_character_,
    5L,
    25L
  ) |>
    dplyr::mutate(
      score_rule = dplyr::if_else(
        is.na(.data$reverse_item),
        "Sum all ordered item scores (Never=1 to Always=5)",
        paste0(
          "Sum ordered item scores after reverse coding ",
          .data$reverse_item,
          " as 6 - item score"
        )
      ),
      missing_item_rule = "Complete score only; any missing item is non-estimable"
    )
}

h05_metric_registry <- function(display_contract) {
  model_contract <- h01_metric_registry()
  display_contract <- display_contract |>
    dplyr::arrange(.data$metric_order)
  if (
    nrow(display_contract) != 17L ||
      !identical(display_contract$metric_order, seq_len(17L)) ||
      anyDuplicated(display_contract$metric_id)
  ) {
    h05_abort("The H05 display contract must contain 17 ordered metrics")
  }
  changed_ids <- model_contract |>
    dplyr::transmute(
      .data$metric_order,
      model_metric_id = .data$metric_id
    ) |>
    dplyr::left_join(
      display_contract |>
        dplyr::select("metric_order", display_metric_id = "metric_id"),
      by = "metric_order",
      relationship = "one-to-one"
    ) |>
    dplyr::filter(.data$model_metric_id != .data$display_metric_id)
  alternate_mder_identifier <- nrow(changed_ids) == 1L &&
    changed_ids$metric_order == 17L &&
    changed_ids$model_metric_id == "mder_ratio_of_integrals" &&
    changed_ids$display_metric_id == "mder_mean_of_viable_ratios"
  current_mder_contract <- nrow(changed_ids) == 0L &&
    model_contract$metric_id[[17L]] == "mder_mean_of_viable_ratios"
  if (!alternate_mder_identifier && !current_mder_contract) {
    h05_abort("Only the MDER metric identifier may differ")
  }

  registry <- model_contract |>
    dplyr::select(-"metric_id") |>
    dplyr::left_join(
      display_contract |>
        dplyr::select(
          "metric_order",
          "metric_id",
          "manuscript_name",
          "abbreviation",
          "manuscript_category",
          "display_unit",
          "variant_label",
          "value_definition"
        ),
      by = "metric_order",
      relationship = "one-to-one"
    ) |>
    dplyr::arrange(.data$metric_order)

  # H05 omits the H01 noon sensitivity. The strict-after-
  # 16 representation and response family remain unchanged.
  registry$diagnostic_note[
    registry$metric_id == "l10_midpoint"
  ] <- paste0(
    "Strict-after-16:00 conversion; continuous-range check; ",
    "no noon sensitivity in H05"
  )
  registry$diagnostic_note[
    registry$metric_id == "mder_mean_of_viable_ratios"
  ] <- paste0(
    "Mean of viable one-minute melEDI/illuminance ratios with at least ",
    "720 viable minutes; upper-tail and influence checks"
  )
  registry
}

h05_run_registry <- function() {
  tidyr::crossing(
    data_scenario_id = c("main", "alternative_preprocessing"),
    placement = c("glasses", "chest"),
    sample_scenario = c("all_available", "paired_common_sample")
  ) |>
    dplyr::mutate(
      run_id = paste(
        .data$data_scenario_id,
        .data$placement,
        .data$sample_scenario,
        sep = "__"
      ),
      analytical_role = dplyr::case_when(
        .data$data_scenario_id == "main" &
          .data$placement == "glasses" &
          .data$sample_scenario == "all_available" ~
          "primary_near_eye",
        .data$data_scenario_id == "main" &
          .data$placement == "chest" &
          .data$sample_scenario == "all_available" ~
          "complementary_chest_all_available",
        .data$data_scenario_id == "alternative_preprocessing" &
          .data$placement == "glasses" &
          .data$sample_scenario == "all_available" ~
          "alternative_preprocessing_sensitivity",
        .data$sample_scenario == "paired_common_sample" ~
          "paired_placement_sensitivity",
        TRUE ~ "supporting_sensitivity"
      ),
      family_id = dplyr::case_when(
        .data$analytical_role == "primary_near_eye" ~ "H05-F1-primary",
        .data$analytical_role == "complementary_chest_all_available" ~
          "H05-F2-complementary-chest",
        .data$analytical_role == "alternative_preprocessing_sensitivity" ~
          "H05-F3-alternative-preprocessing",
        TRUE ~ NA_character_
      ),
      inferential_family = !is.na(.data$family_id),
      family_n = dplyr::if_else(.data$inferential_family, 68L, NA_integer_),
      multiplicity_method = dplyr::if_else(
        .data$inferential_family,
        "BH",
        "none_descriptive_sensitivity"
      )
    )
}

h05_formula_set <- function(analysis_unit) {
  if (!analysis_unit %in% c("participant", "participant_day")) {
    h05_abort("Unknown H05 analysis unit: %s", analysis_unit)
  }
  if (analysis_unit == "participant") {
    return(list(
      fixed_full = stats::as.formula(
        "response_value ~ site + leba_centered"
      ),
      fixed_reduced = stats::as.formula("response_value ~ site"),
      random_site = stats::as.formula(
        "response_value ~ leba_centered + (1 | site)"
      )
    ))
  }
  list(
    fixed_full = stats::as.formula(
      "response_value ~ site + leba_centered + (1 | participant_key)"
    ),
    fixed_reduced = stats::as.formula(
      "response_value ~ site + (1 | participant_key)"
    ),
    random_site = stats::as.formula(
      paste0(
        "response_value ~ leba_centered + (1 | site) + ",
        "(1 | participant_key)"
      )
    )
  )
}

h05_input_contract <- function(root) {
 list(main=list(path=file.path(root,"results/intermediate/model_data/H01.rds")),
 alternative_preprocessing=list(path=file.path(root,"results/intermediate/model_data/H01/scenarios/alternative_preprocessing/H01.rds")),
 leba=list(path=file.path(root,"results/intermediate/model_data/normalized_inputs/leba.rds")),
 h01_fit_results_site_evidence=list(path=file.path(root,"results/models/H01/H01_fit_results.rds")))
}

h05_validate_contract <- function(
  metric_registry,
  factor_registry,
  run_registry
) {
  if (
    nrow(metric_registry) != 17L ||
      !identical(metric_registry$metric_order, seq_len(17L)) ||
      anyDuplicated(metric_registry$metric_id)
  ) {
    h05_abort("H05 requires 17 ordered, unique metrics")
  }
  if (
    nrow(factor_registry) != 4L ||
      !identical(factor_registry$factor_order, seq_len(4L)) ||
      anyDuplicated(factor_registry$factor_id)
  ) {
    h05_abort("H05 requires four ordered, unique LEBA factors")
  }
  if (
    nrow(run_registry) != 8L ||
      anyDuplicated(run_registry$run_id) ||
      sum(run_registry$inferential_family) != 3L ||
      any(run_registry$family_n[run_registry$inferential_family] != 68L)
  ) {
    h05_abort("H05 requires eight runs and three declared 68-test families")
  }
  invisible(TRUE)
}
