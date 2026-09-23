h09_abort <- function(message, ..., call. = FALSE) {
  stop(sprintf(message, ...), call. = call.)
}

h09_score_contract <- function(chronotype) {
  required <- c("site", "Id", "msf_sc", "meq")
  if (!all(required %in% names(chronotype)) ||
      anyDuplicated(chronotype[c("site", "Id")])) {
    h09_abort("Chronotype inputs require unique participant keys and both score fields")
  }
  mctq_hours <- as.numeric(chronotype$msf_sc) / 3600
  meq_scores <- as.numeric(chronotype$meq)
  if (!any(is.finite(mctq_hours)) || !any(is.finite(meq_scores))) {
    h09_abort("Both chronotype instruments require finite observed scores")
  }
  list(
    mctq_center_hour = mean(mctq_hours, na.rm = TRUE),
    meq_center_score = mean(meq_scores, na.rm = TRUE),
    mctq_field = "msf_sc",
    meq_field = "meq",
    participants = nrow(chronotype),
    mctq_missing = sum(is.na(mctq_hours)),
    meq_missing = sum(is.na(meq_scores)),
    score_definition = paste(
      "The input data provide aggregate calculated fields msf_sc and meq;",
      "item-level reconstruction is unavailable"
    )
  )
}

h09_metric_registry <- function() {
  tibble::tribble(
    ~metric_order, ~metric_id, ~manuscript_name, ~abbreviation,
    ~source_column, ~analysis_branch, ~primary_family_member,
    1L, "m10_midpoint", "Midpoint of the brightest 10 hours",
    "M10 midpoint", "m10_hour", "registered", TRUE,
    2L, "l10_midpoint", "Midpoint of the darkest 10 hours",
    "L10 midpoint", "l10_hour", "registered", TRUE,
    3L, "first_timing_above_250",
    "First light timing above 250 lx melEDI", "First >250",
    "first_hour", "registered", TRUE,
    4L, "last_timing_above_250",
    "Last light timing above 250 lx melEDI", "Last >250",
    "last_hour", "registered", TRUE,
    5L, "longest_period_midpoint",
    "Midpoint of the longest continuous period above 250 lx melEDI",
    "Longest-period midpoint", "longest_midpoint_exact_hour",
    "registered", TRUE,
    6L, "mean_timing_above_250",
    "Mean timing of exposure above 250 lx melEDI", "Mean >250",
    "mean_hour", "adapted_mean_timing_sensitivity", FALSE
  ) |>
    dplyr::mutate(
      analysis_unit = "participant_day",
      display_unit = "local clock hour",
      response_family = "gaussian",
      response_link = "identity",
      interval_method = "Wald normal 95% confidence interval",
      value_definition = dplyr::case_when(
        .data$metric_id == "m10_midpoint" ~
          "Local midpoint of the brightest supported 10 hours",
        .data$metric_id == "l10_midpoint" ~ paste(
          "Local midpoint of the darkest supported 10 hours; strict",
          ">16:00 values shifted by -24 hours"
        ),
        .data$metric_id == "first_timing_above_250" ~
          "First supported local timing above 250 lx melEDI",
        .data$metric_id == "last_timing_above_250" ~
          "Last supported local timing above 250 lx melEDI",
        .data$metric_id == "longest_period_midpoint" ~ paste(
          "Local midpoint of the selected longest continuous period above",
          "250 lx melEDI, restricted to exact-identifiable periods"
        ),
        TRUE ~ paste(
          "Duration-weighted mean local timing across supported exposure",
          "above 250 lx melEDI"
        )
      )
    )
}

h09_predictor_registry <- function() {
  tibble::tribble(
    ~instrument_id, ~instrument_name, ~predictor_column, ~centered_column,
    ~effect_unit, ~effect_direction, ~main_family, ~interaction_family,
    "MCTQ", "MCTQ MSFsc", "mctq_hour", "mctq_hour_centered",
    "1 hour", "later corrected midsleep", "H09-F1-MCTQ-main",
    "H09-F3-MCTQ-interaction",
    "MEQ", "MEQ", "meq_score", "meq_10_centered",
    "10 score points", "greater morning preference", "H09-F2-MEQ-main",
    "H09-F4-MEQ-interaction"
  )
}

h09_formula_set <- function(
  instrument_id = c("MCTQ", "MEQ"),
  kind = c("participant_day", "photoperiod", "participant", "temporal")
) {
  instrument_id <- match.arg(instrument_id)
  kind <- match.arg(kind)
  predictor <- if (instrument_id == "MCTQ") {
    "mctq_hour_centered"
  } else {
    "meq_10_centered"
  }
  if (kind == "participant_day") {
    return(list(
      M0_site_only = stats::as.formula(
        "timing_hour ~ site + (1 | site:Id)"
      ),
      M1_main = stats::as.formula(sprintf(
        "timing_hour ~ site + %s + (1 | site:Id)", predictor
      )),
      M2_interaction = stats::as.formula(sprintf(
        "timing_hour ~ site * %s + (1 | site:Id)", predictor
      )),
      D_spline = stats::as.formula(sprintf(
        paste0(
          "timing_hour ~ site + splines::ns(%s, df = 3) + ",
          "(1 | site:Id)"
        ),
        predictor
      ))
    ))
  }
  if (kind == "photoperiod") {
    return(list(
      P0_site_photoperiod = stats::as.formula(paste0(
        "timing_hour ~ site + photoperiod_within_site + ",
        "(1 | site:Id)"
      )),
      P1_main = stats::as.formula(sprintf(
        paste0(
          "timing_hour ~ site + photoperiod_within_site + %s + ",
          "(1 | site:Id)"
        ),
        predictor
      )),
      P2_interaction = stats::as.formula(sprintf(
        paste0(
          "timing_hour ~ site * %s + photoperiod_within_site + ",
          "(1 | site:Id)"
        ),
        predictor
      ))
    ))
  }
  if (kind == "participant") {
    return(list(
      S0_site_only = stats::as.formula(
        "participant_mean_timing_hour ~ site"
      ),
      S1_main = stats::as.formula(sprintf(
        "participant_mean_timing_hour ~ site + %s", predictor
      )),
      S2_interaction = stats::as.formula(sprintf(
        "participant_mean_timing_hour ~ site * %s", predictor
      ))
    ))
  }
  list(
    fixed = stats::as.formula(sprintf(
      "timing_hour ~ site + %s", predictor
    )),
    random = stats::as.formula("~ 1 | participant_key"),
    correlation = stats::as.formula(
      "~ elapsed_day | participant_key"
    )
  )
}

h09_formula_registry <- function() {
  formula_rows <- function(formulas, analysis_kind, instrument) {
    tibble::tibble(
      analysis_kind = analysis_kind,
      instrument = instrument,
      formula_id = names(formulas),
      formula = vapply(
        formulas,
        function(x) paste(deparse(x), collapse = " "),
        character(1)
      )
    )
  }
  dplyr::bind_rows(
    formula_rows(
      h09_formula_set("MCTQ", "participant_day"),
      "participant_day", "MCTQ"
    ),
    formula_rows(
      h09_formula_set("MEQ", "participant_day"),
      "participant_day", "MEQ"
    ),
    formula_rows(
      h09_formula_set("MCTQ", "photoperiod"),
      "photoperiod_sensitivity", "MCTQ"
    ),
    formula_rows(
      h09_formula_set("MEQ", "photoperiod"),
      "photoperiod_sensitivity", "MEQ"
    ),
    formula_rows(
      h09_formula_set("MCTQ", "participant"),
      "participant_summary_sensitivity", "MCTQ"
    ),
    formula_rows(
      h09_formula_set("MEQ", "participant"),
      "participant_summary_sensitivity", "MEQ"
    ),
    formula_rows(
      h09_formula_set("MCTQ", "temporal"),
      "continuous_time_ar1_sensitivity", "MCTQ"
    ),
    formula_rows(
      h09_formula_set("MEQ", "temporal"),
      "continuous_time_ar1_sensitivity", "MEQ"
    )
  )
}

h09_run_registry <- function() {
  tibble::tribble(
    ~run_order, ~run_id, ~data_scenario_id, ~reader_scenario, ~placement,
    ~placement_label, ~sample_scenario, ~analytical_role, ~family_enabled,
    1L, "primary__glasses__all_available", "primary", "Primary dataset",
    "glasses", "Near eye", "all_available", "primary_near_eye", TRUE,
    2L, "primary__chest__all_available", "primary", "Primary dataset",
    "chest", "Chest", "all_available", "complementary_chest", TRUE,
    3L, "primary__glasses__paired_common", "primary", "Primary dataset",
    "glasses", "Near eye", "paired_common",
    "paired_placement_sensitivity", TRUE,
    4L, "primary__chest__paired_common", "primary", "Primary dataset",
    "chest", "Chest", "paired_common",
    "paired_placement_sensitivity", TRUE,
    5L, "gap__glasses__all_available", "gap_timing_unaware",
    "Gap-timing-unaware dataset", "glasses", "Near eye", "all_available",
    "data_preparation_sensitivity", TRUE,
    6L, "gap__chest__all_available", "gap_timing_unaware",
    "Gap-timing-unaware dataset", "chest", "Chest", "all_available",
    "complementary_data_preparation_sensitivity", TRUE,
    7L, "primary__glasses__gap_common", "primary", "Primary dataset",
    "glasses", "Near eye", "gap_common", "exact_common_data_sensitivity",
    TRUE,
    8L, "gap__glasses__gap_common", "gap_timing_unaware",
    "Gap-timing-unaware dataset", "glasses", "Near eye", "gap_common",
    "exact_common_data_sensitivity", TRUE,
    9L, "primary__chest__gap_common", "primary", "Primary dataset",
    "chest", "Chest", "gap_common", "exact_common_data_sensitivity", TRUE,
    10L, "gap__chest__gap_common", "gap_timing_unaware",
    "Gap-timing-unaware dataset", "chest", "Chest", "gap_common",
    "exact_common_data_sensitivity", TRUE
  )
}

h09_family_registry <- function() {
  predictors <- h09_predictor_registry()
  dplyr::bind_rows(lapply(seq_len(nrow(predictors)), function(index) {
    row <- predictors[index, ]
    tibble::tibble(
      family_id = c(row$main_family, row$interaction_family),
      instrument_id = row$instrument_id,
      test_kind = c("main", "interaction"),
      comparison = c("M0 versus M1", "M1 versus M2"),
      planned_n = 5L,
      adjustment_method = "BH",
      decision_rule = "BH-adjusted p < 0.05"
    )
  }))
}

h09_diagnostic_thresholds <- function() {
  tibble::tribble(
    ~diagnostic, ~acceptable_rule, ~threshold,
    "optimizer_gradient", "maximum absolute raw gradient < 0.002", 0.002,
    "singularity", "isSingular(tolerance = 1e-4) is false", 1e-4,
    "qq_correlation", "normal-score Q-Q correlation >= 0.970", 0.970,
    "residual_skewness", "absolute residual skewness <= 2", 2,
    "residual_excess_kurtosis", "absolute excess kurtosis <= 7", 7,
    "standardized_residual", "maximum absolute standardized residual <= 5", 5,
    "heteroscedasticity_fitted", "absolute Spearman correlation <= 0.20", 0.20,
    "heteroscedasticity_site", "largest/smallest site residual SD <= 2.5", 2.5,
    "temporal_lag1", "absolute adjacent-day residual correlation <= 0.20 or stable AR(1) correction", 0.20,
    "linearity_aic", "spline improvement < 4 AIC units unless curvature < 0.25 h", 4,
    "linearity_departure", "maximum anchored spline departure < 0.25 h unless AIC improvement < 4", 0.25,
    "influence_dfbeta", "absolute participant DFBETA <= 2/sqrt(participants) or stable deletion refit", NA_real_,
    "material_effect_change", "absolute slope change < 0.25 local clock hours", 0.25
  )
}

h09_input_contract <- function(root) {
 tibble::tribble(~input_role, ~path,
"normalized_chronotype", "results/intermediate/model_data/normalized_inputs/chronotype.rds",
"primary_near_eye_context", "results/intermediate/model_data/base/metrics_glasses_participant_day_context.rds",
"primary_chest_context", "results/intermediate/model_data/base/metrics_chest_participant_day_context.rds",
"primary_near_eye_enriched", "results/intermediate/model_data/base/metrics_glasses_participant_day_enriched.rds",
"primary_chest_enriched", "results/intermediate/model_data/base/metrics_chest_participant_day_enriched.rds",
"gap_timing_unaware_metrics", "results/intermediate/model_data/scenarios/alternative_preprocessing/participant_day_metrics.rds") |> dplyr::mutate(absolute_path = file.path(root,.data$path))
}
