# Define the approved H01 response, multiplicity, and scenario contracts.

h01_abort <- function(message, ..., call. = FALSE) {
  stop(sprintf(message, ...), call. = call.)
}

h01_metric_registry <- function() {
  tibble::tribble(
    ~metric_order, ~metric_id, ~analysis_unit, ~response_family,
    ~response_transform, ~effect_scale, ~preregistered_photoperiod,
    ~lower_bound, ~upper_bound, ~audit_upper_threshold, ~diagnostic_note,
    1L, "interdaily_stability", "participant", "gaussian",
    "logit", "odds_ratio", FALSE, 0, 1, NA_real_,
    "Transformed residual and influence checks",
    2L, "intradaily_variability", "participant", "gaussian",
    "identity", "difference", FALSE, 0, NA_real_, NA_real_,
    "Residual spread and influence checks",
    3L, "daily_geometric_mean_medi", "participant_day", "gaussian",
    "log10_offset_0.1", "ratio", FALSE, 0, NA_real_, NA_real_,
    "Offset, influence, and upper-tail checks",
    4L, "m10_mean_medi", "participant_day", "gaussian",
    "log10_offset_0.1", "ratio", FALSE, 0, NA_real_, NA_real_,
    "Influence and upper-tail checks",
    5L, "l10_mean_medi", "participant_day", "gaussian",
    "log10_offset_0.1", "ratio", FALSE, 0, NA_real_, NA_real_,
    "High-risk exact-zero and residual checks",
    6L, "duration_above_1000", "participant_day", "tweedie_log",
    "identity", "ratio", TRUE, 0, 24, NA_real_,
    "Zero mass, dispersion, tail, and 24-hour prediction checks",
    7L, "duration_above_250_wake", "participant_day", "tweedie_log",
    "identity", "ratio", TRUE, 0, NA_real_, NA_real_,
    "Zero mass, tail, and waking-duration prediction checks",
    8L, "duration_below_10_pre_sleep", "participant_day", "gaussian",
    "identity", "difference", TRUE, 0, 24, 6,
    paste0(
      "Calendar-day cumulative duration with a six-hour audit threshold; ",
      "identity-scale Gaussian selected by the H01 candidate assessment"
    ),
    9L, "duration_below_1_sleep_environment", "participant_day",
    "tweedie_log", "identity", "ratio", TRUE, 0, NA_real_, NA_real_,
    "Distribution and sleep-window prediction checks",
    10L, "longest_bout_above_250", "participant_day", "gaussian",
    "log10_offset_0.1", "ratio", TRUE, 0, 24, NA_real_,
    "Mandatory exactly-identified-only sensitivity",
    11L, "m10_midpoint", "participant_day", "gaussian",
    "clock_hours", "difference", FALSE, 0, 24, NA_real_,
    "Continuous daytime range check",
    12L, "l10_midpoint", "participant_day", "gaussian",
    "clock_hours_midnight_after_16", "difference", FALSE, 0, 24, NA_real_,
    "Strict-after-16:00 primary conversion with noon sensitivity",
    13L, "mean_timing_above_250", "participant_day", "gaussian",
    "clock_hours", "difference", FALSE, 0, 24, NA_real_,
    "Continuous daytime-to-evening range check",
    14L, "first_timing_above_250", "participant_day", "gaussian",
    "clock_hours", "difference", FALSE, 0, 24, NA_real_,
    "Late-evening cluster check",
    15L, "last_timing_above_250", "participant_day", "gaussian",
    "clock_hours", "difference", FALSE, 0, 24, NA_real_,
    "Early-morning cluster check",
    16L, "dose_time_sensitive_corrected_medi", "participant_day",
    "gaussian", "log10_offset_0.1", "ratio", FALSE, 0, NA_real_, NA_real_,
    "Offset, influence, and upper-tail checks",
    17L, "mder_mean_of_viable_ratios", "participant_day", "gaussian",
    "identity", "difference", FALSE, 0, NA_real_, NA_real_,
    "Distribution, viable-minute support, upper-tail, and influence checks"
  )
}

h01_family_registry <- function() {
  tibble::tribble(
    ~family_order, ~family_id, ~family_label, ~comparison,
    1L, "H01-F1-site", "Overall site", "site_full_vs_no_site",
    2L, "H01-F2-photoperiod", "Photoperiod", "site_full_vs_no_photoperiod",
    3L, "H01-F3-latitude", "Latitude", "latitude_full_vs_no_latitude",
    4L, "H01-F4-site-latitude-adequacy",
    "Site versus linear latitude adequacy", "site_full_vs_latitude_full"
  ) |>
    dplyr::mutate(
      adjustment_method = "BH",
      family_n = 17L
    )
}

h01_run_registry <- function() {
  tidyr::crossing(
    data_scenario_id = c("main", "manuscript_prepared_data"),
    placement = c("glasses", "chest"),
    sample_scenario = c("all_available", "paired_common_sample")
  ) |>
    dplyr::mutate(
      run_id = paste(
        data_scenario_id,
        placement,
        sample_scenario,
        sep = "__"
      ),
      analytical_role = dplyr::case_when(
        data_scenario_id == "main" &
          placement == "glasses" &
          sample_scenario == "all_available" ~ "primary",
        data_scenario_id == "manuscript_prepared_data" &
          placement == "glasses" &
          sample_scenario == "all_available" ~
            "manuscript_prepared_data_sensitivity",
        placement == "chest" & sample_scenario == "all_available" ~
          "complementary_chest",
        sample_scenario == "paired_common_sample" ~
          "paired_placement_comparison",
        TRUE ~ "supporting"
      )
    )
}

h01_input_contract <- function(root) {
  list(
    main = list(
      path = file.path(root, "artifacts/06_model_data/H01.rds"),
      manifest = file.path(
        root,
        "artifacts/12_manifests/H01_model_data_artifacts.csv"
      ),
      manifest_sha256 =
        "25978c5d6903e6e835c1aff6a9bc2e7552b85295e8d840d3dd65bbf9b1eb6b72"
    ),
    manuscript_prepared_data = list(
      path = file.path(
        root,
        paste0(
          "artifacts/06_model_data/H01/scenarios/",
          "manuscript_prepared_data/H01.rds"
        )
      ),
      manifest = file.path(
        root,
        paste0(
          "artifacts/12_manifests/",
          "H01_manuscript_prepared_data_artifacts.csv"
        )
      ),
      manifest_sha256 =
        "e0d98178ede61b74353e3a654e7f1b53d7e1c915833a2cda74eea45ed02f383b"
    ),
    implementation_contract_sha256 =
      "62e5af96d08062945ad41b9031c0cfeb749fb7917db83deea2666bff98aa86de",
    shared_implementation_sha256 =
      "f0224802bd9b11900c0b446e759c8ce8495788f0fde6afd9101f76ccfabb8303",
    model_implementation_id = "new_h01_h11"
  )
}

h01_validate_registry <- function(metric_registry = h01_metric_registry()) {
  required <- c(
    "metric_order",
    "metric_id",
    "analysis_unit",
    "response_family",
    "response_transform",
    "effect_scale",
    "lower_bound",
    "upper_bound",
    "audit_upper_threshold"
  )
  missing <- setdiff(required, names(metric_registry))
  if (length(missing) > 0L) {
    h01_abort(
      "H01 metric registry is missing column(s): %s",
      paste(missing, collapse = ", ")
    )
  }
  if (
    nrow(metric_registry) != 17L ||
      !identical(metric_registry$metric_order, seq_len(17L)) ||
      anyDuplicated(metric_registry$metric_id)
  ) {
    h01_abort("H01 metric registry must contain 17 ordered, unique metrics")
  }
  if (
    !all(metric_registry$analysis_unit %in%
      c("participant", "participant_day")) ||
      !all(metric_registry$response_family %in%
        c("gaussian", "tweedie_log"))
  ) {
    h01_abort("H01 metric registry contains an unsupported model contract")
  }
  allowed_transforms <- c(
    "logit",
    "identity",
    "log10_offset_0.1",
    "clock_hours",
    "clock_hours_midnight_after_16"
  )
  if (!all(metric_registry$response_transform %in% allowed_transforms)) {
    h01_abort("H01 metric registry contains an unsupported transformation")
  }
  finite_audit_threshold <- is.finite(metric_registry$audit_upper_threshold)
  if (
    any(
      finite_audit_threshold &
        metric_registry$audit_upper_threshold <= metric_registry$lower_bound
    ) ||
      any(
        finite_audit_threshold &
          is.finite(metric_registry$upper_bound) &
          metric_registry$audit_upper_threshold > metric_registry$upper_bound
      )
  ) {
    h01_abort("H01 audit thresholds must lie inside the response bounds")
  }
  invisible(metric_registry)
}

h01_model_formula <- function(
  analysis_unit,
  fixed_terms,
  response = "response_value"
) {
  if (!analysis_unit %in% c("participant", "participant_day")) {
    h01_abort("Unknown H01 analysis unit: %s", analysis_unit)
  }
  rhs <- if (length(fixed_terms) == 0L) {
    "1"
  } else {
    paste(fixed_terms, collapse = " + ")
  }
  if (analysis_unit == "participant_day") {
    rhs <- paste(rhs, "+ (1 | participant_key)")
  }
  stats::as.formula(paste(response, "~", rhs))
}

h01_formula_set <- function(analysis_unit, preregistered_scope = FALSE) {
  include_photoperiod <- !preregistered_scope
  site_terms <- if (include_photoperiod) {
    c("site", "photoperiod_centered_hours")
  } else {
    "site"
  }
  latitude_terms <- if (include_photoperiod) {
    c("absolute_latitude_10deg_centered", "photoperiod_centered_hours")
  } else {
    "absolute_latitude_10deg_centered"
  }
  no_site_terms <- if (include_photoperiod) {
    "photoperiod_centered_hours"
  } else {
    character()
  }
  list(
    site_full = h01_model_formula(analysis_unit, site_terms),
    no_site = h01_model_formula(analysis_unit, no_site_terms),
    no_photoperiod = h01_model_formula(analysis_unit, "site"),
    latitude_full = h01_model_formula(analysis_unit, latitude_terms),
    no_latitude = h01_model_formula(analysis_unit, no_site_terms),
    random_site = if (analysis_unit == "participant_day") {
      if (include_photoperiod) {
        stats::as.formula(
          paste0(
            "response_value ~ photoperiod_centered_hours + ",
            "(1 | site) + (1 | participant_key)"
          )
        )
      } else {
        stats::as.formula(
          "response_value ~ 1 + (1 | site) + (1 | participant_key)"
        )
      }
    } else {
      if (include_photoperiod) {
        stats::as.formula(
          "response_value ~ photoperiod_centered_hours + (1 | site)"
        )
      } else {
        stats::as.formula("response_value ~ 1 + (1 | site)")
      }
    }
  )
}

h01_primary_seed <- function(
  metric_order,
  data_scenario_id,
  placement,
  sample_scenario
) {
  data_offset <- if (data_scenario_id == "main") 0L else 100000L
  placement_offset <- if (placement == "glasses") 0L else 10000L
  sample_offset <- if (sample_scenario == "all_available") 0L else 1000L
  20260730L + data_offset + placement_offset + sample_offset + metric_order
}

h01_code_paths <- function(root) {
  file.path(
    root,
    "scripts/hypotheses/H01",
    c(
      "h01_contract.R",
      "h01_modeling.R",
      "run_h01_models.R",
      "audit_h01_major_gates.R",
      "build_h01_worker_manifest.R",
      "build_h01_comparisons.R"
    )
  )
}
