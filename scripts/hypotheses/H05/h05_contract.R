# Define the author-approved H05 Stage 2 analysis contract.

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

h05_v0_metric_registry <- function() {
  tibble::tribble(
    ~v0_order,
    ~v0_name,
    ~metric_id_v0,
    ~metric_id_current,
    ~manuscript_name,
    1L,
    "interdaily_stability",
    "interdaily_stability",
    "interdaily_stability",
    "Interdaily stability",
    2L,
    "intradaily_variability",
    "intradaily_variability",
    "intradaily_variability",
    "Intradaily variability",
    3L,
    "Mean",
    "daily_geometric_mean_medi",
    "daily_geometric_mean_medi",
    "Mean melEDI",
    4L,
    "brightest_10h_mean",
    "m10_mean_medi",
    "m10_mean_medi",
    "Brightest 10 h mean",
    5L,
    "brightest_10h_midpoint",
    "m10_midpoint",
    "m10_midpoint",
    "Midpoint of the brightest 10 hours",
    6L,
    "darkest_10h_mean",
    "l10_mean_medi",
    "l10_mean_medi",
    "Darkest 10 h mean",
    7L,
    "darkest_10h_midpoint",
    "l10_midpoint",
    "l10_midpoint",
    "Midpoint of the darkest 10 hours",
    8L,
    "duration_above_1000",
    "duration_above_1000",
    "duration_above_1000",
    "Time above 1,000 lx melEDI",
    9L,
    "period_above_250",
    "longest_bout_above_250",
    "longest_bout_above_250",
    "Longest continuous period above 250 lx melEDI",
    10L,
    "mean_timing_above_250",
    "mean_timing_above_250",
    "mean_timing_above_250",
    "Mean timing of exposure above 250 lx melEDI",
    11L,
    "first_timing_above_250",
    "first_timing_above_250",
    "first_timing_above_250",
    "First light timing above 250 lx melEDI",
    12L,
    "last_timing_above_250",
    "last_timing_above_250",
    "last_timing_above_250",
    "Last light timing above 250 lx melEDI",
    13L,
    "dose",
    "dose_observed_medi",
    "dose_time_sensitive_corrected_medi",
    "melEDI dose",
    14L,
    "MDER",
    "mder_ratio_of_integrals",
    "mder_mean_of_viable_ratios",
    "Melanopic daylight efficacy ratio",
    15L,
    "duration_below_10_pre-sleep",
    "duration_below_10_pre_sleep",
    "duration_below_10_pre_sleep",
    "Time below 10 lx melEDI before sleep",
    16L,
    "duration_below_1_sleep",
    "duration_below_1_sleep_environment",
    "duration_below_1_sleep_environment",
    "Time below 1 lx melEDI during sleep",
    17L,
    "duration_above_250_wake",
    "duration_above_250_wake",
    "duration_above_250_wake",
    "Time above 250 lx melEDI during wake"
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
        dplyr::select(.data$metric_order, display_metric_id = .data$metric_id),
      by = "metric_order",
      relationship = "one-to-one"
    ) |>
    dplyr::filter(.data$model_metric_id != .data$display_metric_id)
  legacy_mder_translation <- nrow(changed_ids) == 1L &&
    changed_ids$metric_order == 17L &&
    changed_ids$model_metric_id == "mder_ratio_of_integrals" &&
    changed_ids$display_metric_id == "mder_mean_of_viable_ratios"
  current_mder_contract <- nrow(changed_ids) == 0L &&
    model_contract$metric_id[[17L]] == "mder_mean_of_viable_ratios"
  if (!legacy_mder_translation && !current_mder_contract) {
    h05_abort("Only the approved METRIC-010 MDER identifier may differ")
  }

  registry <- model_contract |>
    dplyr::select(-.data$metric_id) |>
    dplyr::left_join(
      display_contract |>
        dplyr::select(
          .data$metric_order,
          .data$metric_id,
          .data$manuscript_name,
          .data$abbreviation,
          .data$manuscript_category,
          .data$display_unit,
          .data$variant_label,
          .data$value_definition
        ),
      by = "metric_order",
      relationship = "one-to-one"
    ) |>
    dplyr::arrange(.data$metric_order)

  # H05 explicitly omits the H01 noon sensitivity. The approved strict-after-
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
    data_scenario_id = c("main", "manuscript_prepared_data"),
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
        .data$data_scenario_id == "manuscript_prepared_data" &
          .data$placement == "glasses" &
          .data$sample_scenario == "all_available" ~
          "manuscript_prepared_data_sensitivity",
        .data$sample_scenario == "paired_common_sample" ~
          "paired_placement_sensitivity",
        TRUE ~ "audit_only_supporting_sensitivity"
      ),
      family_id = dplyr::case_when(
        .data$analytical_role == "primary_near_eye" ~ "H05-F1-primary",
        .data$analytical_role == "complementary_chest_all_available" ~
          "H05-F2-complementary-chest",
        .data$analytical_role == "manuscript_prepared_data_sensitivity" ~
          "H05-F3-manuscript-prepared",
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
  list(
    main = list(
      path = file.path(root, "artifacts/06_model_data/H01.rds"),
      sha256 = "0328fe1a698bc13965feb0b68b03ccf0fd20f32b55d6148635811b0d674e0a00",
      manifest = file.path(
        root,
        "artifacts/12_manifests/H01_model_data_artifacts.csv"
      ),
      manifest_sha256 = "25978c5d6903e6e835c1aff6a9bc2e7552b85295e8d840d3dd65bbf9b1eb6b72"
    ),
    manuscript_prepared_data = list(
      path = file.path(
        root,
        paste0(
          "artifacts/06_model_data/H01/scenarios/",
          "manuscript_prepared_data/H01.rds"
        )
      ),
      sha256 = "3c70363fc0468202a431904aa9d9444f2858af2e3add3475a56c872b49a18bd6",
      manifest = file.path(
        root,
        "artifacts/12_manifests/H01_manuscript_prepared_data_artifacts.csv"
      ),
      manifest_sha256 = "e0d98178ede61b74353e3a654e7f1b53d7e1c915833a2cda74eea45ed02f383b"
    ),
    leba = list(
      path = file.path(
        root,
        "artifacts/06_model_data/normalized_inputs/leba.rds"
      ),
      sha256 = "71882566d4665dde757a13b18e56c1f7308e855ea22bced4384e91254e64e636"
    ),
    v0_near_eye = list(
      path = file.path(root, "data/H1_results.RData"),
      sha256 = "d274865818cc4a0364dae9a444b9be44be02424daa8ad74b9452840f3115b3dc"
    ),
    v0_chest = list(
      path = file.path(root, "data/H1_results_chest.RData"),
      sha256 = "01f91db675d1aa6ae96b6aa7bbc45b2f86445e851a37020d1fe5335d802de9b5"
    ),
    h01_contract_source = list(
      path = file.path(root, "scripts/hypotheses/H01/h01_contract.R"),
      sha256 = "9151f2ca8ef549d16df1465768ed5b33c0aa33b37dc315a13e06d795ba20de2e"
    ),
    h01_modeling_source = list(
      path = file.path(root, "scripts/hypotheses/H01/h01_modeling.R"),
      sha256 = "a8879209e0d7c42f2e0de0d459e3cfbf7218cec27afd8f39a50c846ed43f9388"
    ),
    h01_fit_results_site_evidence = list(
      path = file.path(root, "artifacts/07_models/H01/H01_fit_results.rds"),
      sha256 = "16b5ab67234c73d7cd7e14f29bf4b96bda9caff1bb2e786e3027aa59825d32c7"
    ),
    metric010_decision = list(
      path = file.path(root, "audit/decisions/mder_mean_of_viable_ratios.md"),
      sha256 = "1664347de976057807fcb5ac6e24bd4b66af1fe32378fabd1f2acafcfc9266de"
    ),
    primary_metric_manifest = list(
      path = file.path(root, "artifacts/12_manifests/metric_artifacts.csv"),
      sha256 = "028bce108339c1277df4a070597430ea20b49c34c2888f4eef42741c1fe76a5e"
    ),
    independent_mder_audit_manifest = list(
      path = file.path(
        root,
        "artifacts/08_diagnostics/mder_METRIC-010/audit_manifest.csv"
      ),
      sha256 = "5bd34fd4ac26dc2761540393d40e096cde835d8dd4b4edda9253243c9083d4bb"
    ),
    base_model_manifest = list(
      path = file.path(
        root,
        "artifacts/12_manifests/base_model_data_artifacts.csv"
      ),
      sha256 = "8344bdc0339a53079bf9eeb7d86de1ad7c15373641c3a0a5a01d040b418895ce"
    ),
    gap_preparation_manifest = list(
      path = file.path(
        root,
        "artifacts/12_manifests/manuscript_prepared_data_artifacts.csv"
      ),
      sha256 = "4ed62fbe58de65a6d05d8cfc6b5d870d7c74a3c83fe89bcd72bd1dd838698935"
    ),
    gap_repair_evidence_manifest = list(
      path = file.path(
        root,
        paste0(
          "audit/reconciliation/mder_METRIC-010_gap_repair/",
          "gap_repair_evidence_manifest.csv"
        )
      ),
      sha256 = "81e3aa9439b88cf239d6669dc4343cfb146cd2f45790bae412ab837156315018"
    ),
    metric011_decision = list(
      path = file.path(
        root,
        "audit/decisions/l10_numerical_zero_normalization.md"
      ),
      sha256 = "23b9f70d1d16f7fd3ebbdbc57aaf78c0a701fe1f9d22bd667d926cd320d40797"
    ),
    metric011_evidence_manifest = list(
      path = file.path(
        root,
        paste0(
          "audit/reconciliation/l10_METRIC-011/",
          "METRIC-011_evidence_manifest.csv"
        )
      ),
      sha256 = "a37efd3449a8d1a6065d0eb8964bd6cf8b241f1683a26c065ea1a946e23214fb"
    ),
    site_context_manifest = list(
      path = file.path(
        root,
        "artifacts/12_manifests/site_solar_context_artifacts.csv"
      ),
      sha256 = "c0c6d7f97782c0d880a213050f576213f5d56b3204a02732f6399e7e4aeb8518"
    ),
    primary_near_eye_context = list(
      path = file.path(
        root,
        "artifacts/06_model_data/base/metrics_glasses_participant_day_context.rds"
      ),
      sha256 = "013afe75e9b75b141b4cb48d04111a9e6c688630085a24c9fe07ca3d142a4e9a"
    ),
    primary_chest_context = list(
      path = file.path(
        root,
        "artifacts/06_model_data/base/metrics_chest_participant_day_context.rds"
      ),
      sha256 = "497466ccd1a35635cca40bb8f9ce51efb97321ab04b42ee1bb76785e466a2057"
    )
  )
}

h05_approval_registry <- function() {
  tibble::tribble(
    ~decision_order,
    ~decision_id,
    ~author_disposition,
    1L,
    "H05-G1-primary-estimand",
    "Approved Option A: site-adjusted metric model is primary",
    2L,
    "H05-factor-manifest",
    "Approved LEBA F2-F5 manifest and Factor 1 exclusion",
    3L,
    "H05-metric-manifest",
    "Approved exact 17-member repaired metric manifest",
    4L,
    "H05-analysis-unit-hierarchy",
    "Approved participant-day hierarchy and participant-level IS/IV models",
    5L,
    "H05-response-package",
    "Approved current H01 response-family and transformation package",
    6L,
    "H05-leba-scaling",
    paste0(
      "Approved participant-mean-centered raw scores; effects per point and ",
      "participant SD; no within-site standardization"
    ),
    7L,
    "H05-site-handling",
    paste0(
      "Fixed site approved as primary because H01 showed more stable fixed-site ",
      "fits; registered random site retained as sensitivity"
    ),
    8L,
    "H05-multiplicity",
    paste0(
      "Approved complete 68-member BH families and no secondary significance ",
      "screen for descriptive sensitivities"
    ),
    9L,
    "H05-clock-rules",
    paste0(
      "Approved continuous ranges and strict-after-16 L10 conversion; H01 ",
      "already resolved the issue; no noon sensitivity"
    ),
    10L,
    "H05-placement-sample",
    paste0(
      "Near-eye all-available primary; all-available chest complementary; ",
      "paired/common near-eye and chest plus other placements as sensitivities"
    ),
    11L,
    "H05-intervals",
    "Approved declared Wald model intervals and descriptive Spearman intervals",
    12L,
    "H05-diagnostics-sensitivities",
    "Approved diagnostic, sensitivity, adequacy, and failure rules",
    13L,
    "H05-claim-gate",
    "Approved withdrawal of V0 claims until Stage 2 verification"
  ) |>
    dplyr::mutate(
      approved = TRUE,
      recorded_date = as.Date("2026-08-01")
    )
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
