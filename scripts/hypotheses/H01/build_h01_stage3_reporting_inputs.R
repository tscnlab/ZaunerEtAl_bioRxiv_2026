# Build standalone H01 reader-facing reporting inputs from verified stored fits.
# This script does not fit, predict, compare, or bootstrap a model.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
source(file.path(root, "scripts/pipeline/paths_io.R"))
source(file.path(root, "scripts/hypotheses/H01/h01_contract.R"))

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("H01 Stage 3 reporting requires R 4.6.1", call. = FALSE)
}

suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
  library(ggridges)
  library(readr)
  library(tibble)
  library(tidyr)
})

producer <- "scripts/hypotheses/H01/build_h01_stage3_reporting_inputs.R"
primary_run <- "main__glasses__all_available"
chest_run <- "main__chest__all_available"
selected_runs <- c(primary_run, chest_run)

read_required <- function(relative_path) {
  path <- file.path(root, relative_path)
  if (!file.exists(path)) {
    stop("Missing required H01 Stage 3 input: ", relative_path, call. = FALSE)
  }
  readr::read_csv(path, show_col_types = FALSE, progress = FALSE)
}

format_family <- function(response_family, response_transform) {
  dplyr::case_when(
    response_family == "tweedie_log" ~ "Tweedie with log link",
    response_transform == "log10_offset_0.1" ~
      "Gaussian after log10(value + 0.1)",
    response_transform == "logit" ~ "Gaussian after logit transformation",
    response_transform == "clock_hours_midnight_after_16" ~
      "Gaussian on the linear clock scale (strict after-16:00 cut)",
    response_transform == "clock_hours" ~
      "Gaussian on the linear clock scale",
    TRUE ~ "Gaussian on the identity scale"
  )
}

run_registry <- tibble::tribble(
  ~run_id, ~run_order, ~run_label, ~data_label, ~placement_label, ~sample_label,
  "main__glasses__all_available", 1L,
  "Main near-eye", "Main", "Near eye", "All available",
  "main__chest__all_available", 2L,
  "Main chest", "Main", "Chest", "All available",
  "main__glasses__paired_common_sample", 3L,
  "Main near-eye, paired/common sample", "Main", "Near eye", "Paired/common",
  "main__chest__paired_common_sample", 4L,
  "Main chest, paired/common sample", "Main", "Chest", "Paired/common",
  "manuscript_prepared_data__glasses__all_available", 5L,
  "Manuscript-prepared near-eye", "Manuscript-prepared", "Near eye", "All available",
  "manuscript_prepared_data__chest__all_available", 6L,
  "Manuscript-prepared chest", "Manuscript-prepared", "Chest", "All available",
  "manuscript_prepared_data__glasses__paired_common_sample", 7L,
  "Manuscript-prepared near-eye, paired/common sample",
  "Manuscript-prepared", "Near eye", "Paired/common",
  "manuscript_prepared_data__chest__paired_common_sample", 8L,
  "Manuscript-prepared chest, paired/common sample",
  "Manuscript-prepared", "Chest", "Paired/common"
)

question_registry <- tibble::tribble(
  ~family_id, ~question_order, ~question_id, ~question_label,
  "H01-F1-site", 1L, "site", "Overall site",
  "H01-F2-photoperiod", 2L, "photoperiod", "Photoperiod",
  "H01-F3-latitude", 3L, "latitude", "Latitude",
  "H01-F4-site-latitude-adequacy", 4L, "adequacy",
  "Site versus linear latitude"
)

site_registry <- read_required("config/site_display_registry.csv") |>
  arrange(.data$display_order)
metric_contract <- read_required(
  "artifacts/06_model_data/H01/metric_contract.csv"
) |>
  select(
    "metric_order", "metric_id", "manuscript_name", "abbreviation",
    "manuscript_category", "display_unit", "variant_label"
  )
metric_registry <- h01_metric_registry() |>
  left_join(
    metric_contract,
    by = c("metric_order", "metric_id"),
    relationship = "one-to-one"
  ) |>
  mutate(
    family_label = format_family(
      .data$response_family,
      .data$response_transform
    ),
    analysis_unit_label = if_else(
      .data$analysis_unit == "participant",
      "Participant",
      "Participant-day"
    )
  )
if (nrow(metric_registry) != 17L || anyNA(metric_registry$manuscript_name)) {
  stop("The H01 Stage 3 metric registry is incomplete", call. = FALSE)
}

tests <- read_required("artifacts/09_tables/H01/H01_model_level_tests.csv")
term_effects <- read_required("artifacts/09_tables/H01/H01_term_effects.csv")
site_deviations <- read_required("artifacts/09_tables/H01/H01_site_deviations.csv")
samples <- read_required("artifacts/09_tables/H01/H01_exact_samples.csv")
samples_by_site <- read_required(
  "artifacts/09_tables/H01/H01_exact_samples_by_site.csv"
)
r2 <- read_required("artifacts/09_tables/H01/H01_r2_bootstrap_summaries.csv")
diagnostics <- read_required(
  "artifacts/08_diagnostics/H01/H01_model_diagnostics.csv"
)
bootstrap_audit <- read_required(
  "artifacts/08_diagnostics/H01/H01_r2_bootstrap_audit.csv"
)
model_manifest <- read_required(
  "artifacts/09_tables/H01/H01_model_manifest.csv"
)
noon_tests <- read_required(
  "artifacts/09_tables/H01/H01_l10_noon_conversion_model_tests.csv"
)
noon_effects <- read_required(
  "artifacts/09_tables/H01/H01_l10_noon_conversion_term_effects.csv"
)
noon_samples <- read_required(
  "artifacts/09_tables/H01/H01_l10_noon_conversion_samples.csv"
)
period_sensitivity <- read_required(
  "artifacts/09_tables/H01/H01_exactly_identified_period_sensitivity.csv"
)
scope_sensitivity <- read_required(
  "artifacts/09_tables/H01/H01_preregistered_scope_sensitivity.csv"
)
participant_influence <- read_required(
  "artifacts/08_diagnostics/H01/H01_participant_influence.csv"
)
latitude_loo <- read_required(
  "artifacts/08_diagnostics/H01/H01_latitude_leave_one_site_out.csv"
)
marginalization <- read_required(
  "artifacts/09_tables/H01/H01_marginalization_comparison.csv"
)
descriptive_metric_summary <- read_required(
  "artifacts/09_tables/descriptives/metric_descriptive_summary_replica.csv"
)
descriptive_metric_values <- read_required(
  "artifacts/11_source_data/descriptives/metric_plot_values.csv"
)

if (
  nrow(bootstrap_audit) != 128L ||
    any(bootstrap_audit$status != "PASS") ||
    any(bootstrap_audit$used_refits < 1000L)
) {
  stop(
    "Stored H01 production-bootstrap outputs do not pass the Stage 3 read gate",
    call. = FALSE
  )
}
if (
  any(tests$family_n != 17L) ||
    any(tests$family_status != "COMPLETE") ||
    nrow(tests) != 8L * 17L * 4L
) {
  stop("The stored H01 multiplicity families are incomplete", call. = FALSE)
}

test_wide <- tests |>
  filter(.data$run_id %in% selected_runs) |>
  left_join(question_registry, by = "family_id", relationship = "many-to-one") |>
  select(
    "run_id", "metric_id", "question_id", "statistic", "df", "p_raw",
    "p_adjusted", "comparison_status", "family_status"
  ) |>
  pivot_wider(
    names_from = "question_id",
    values_from = c(
      "statistic", "df", "p_raw", "p_adjusted",
      "comparison_status", "family_status"
    ),
    names_glue = "{question_id}_{.value}"
  )

effect_wide <- term_effects |>
  filter(
    .data$run_id %in% selected_runs,
    .data$term %in% c(
      "photoperiod_centered_hours",
      "absolute_latitude_10deg_centered"
    )
  ) |>
  mutate(
    effect_id = if_else(
      .data$term == "photoperiod_centered_hours",
      "photoperiod",
      "latitude"
    )
  ) |>
  select(
    "run_id", "metric_id", "effect_id", "effect_type",
    "estimate_practical", "conf_low_practical", "conf_high_practical",
    "p_raw", "interval_method", "status"
  ) |>
  pivot_wider(
    names_from = "effect_id",
    values_from = c(
      "effect_type", "estimate_practical", "conf_low_practical",
      "conf_high_practical", "p_raw", "interval_method", "status"
    ),
    names_glue = "{effect_id}_{.value}"
  )

diagnostic_assessment <- diagnostics |>
  filter(.data$run_id %in% selected_runs) |>
  left_join(metric_registry, by = c("metric_order", "metric_id")) |>
  left_join(run_registry, by = "run_id", relationship = "many-to-one") |>
  mutate(
    assessment = case_when(
      .data$diagnostic_status == "PASS" ~ "Acceptable",
      .data$diagnostic_status == "WARN_REVIEW" ~
        "Acceptable with limitations",
      .data$diagnostic_status == "NON_ESTIMABLE" ~ "Not fitted",
      TRUE ~ "Not acceptable"
    ),
    residual_assessment = case_when(
      .data$residual_status == "PASS" ~ "No flagged residual issue",
      .data$residual_status == "WARN_GAUSSIAN_DIAGNOSTIC" ~
        "Gaussian residual-shape warning",
      .data$residual_status == "WARN_STRONG_GAUSSIAN_MISFIT" ~
        "Strong Gaussian residual-shape warning",
      .data$residual_status == "WARN_TWEEDIE_DIAGNOSTIC" ~
        "Tweedie simulation-diagnostic warning",
      .data$residual_status == "WARN_STRONG_TWEEDIE_MISFIT" ~
        "Strong Tweedie simulation-diagnostic warning",
      TRUE ~ "Not available"
    ),
    bound_assessment = case_when(
      .data$prediction_bound_status == "PASS" ~ "Prediction bounds passed",
      .data$prediction_bound_status == "WARN_PREDICTED_BOUND" ~
        "Predicted values crossed a physical bound",
      .data$prediction_bound_status == "UPPER_BOUND_UNAVAILABLE" ~
        "No verified upper bound available",
      TRUE ~ "Not available"
    )
  ) |>
  arrange(.data$run_order, .data$metric_order)

diagnostic_details <- diagnostic_assessment |>
  transmute(
    .data$run_id,
    .data$run_order,
    .data$run_label,
    .data$placement_label,
    .data$metric_order,
    .data$metric_id,
    .data$manuscript_category,
    .data$manuscript_name,
    response_family = .data$response_family.x,
    response_transform = .data$response_transform.x,
    .data$assessment,
    .data$residual_assessment,
    .data$bound_assessment,
    .data$residual_status,
    .data$diagnostic_status,
    .data$shapiro_p,
    .data$residual_variance_ratio,
    .data$standardized_residual_over_3_fraction,
    .data$standardized_residual_over_4_fraction,
    .data$dharma_uniformity_p,
    .data$dharma_dispersion_p,
    .data$dharma_zero_inflation_p,
    .data$dharma_outlier_p,
    .data$observed_zero_fraction,
    .data$simulated_zero_fraction,
    .data$zero_fraction_ratio,
    .data$prediction_bound_status,
    .data$predicted_below_bound_n,
    .data$predicted_above_bound_n
  ) |>
  arrange(.data$run_order, .data$metric_order)

model_results <- samples |>
  filter(.data$run_id %in% selected_runs) |>
  left_join(metric_registry, by = c("metric_order", "metric_id")) |>
  left_join(run_registry, by = "run_id", relationship = "many-to-one") |>
  left_join(test_wide, by = c("run_id", "metric_id"), relationship = "one-to-one") |>
  left_join(effect_wide, by = c("run_id", "metric_id"), relationship = "one-to-one") |>
  left_join(
    diagnostic_assessment |>
      select("run_id", "metric_id", "assessment", "residual_assessment", "bound_assessment"),
    by = c("run_id", "metric_id"),
    relationship = "one-to-one"
  ) |>
  arrange(.data$run_order, .data$metric_order)
if (nrow(model_results) != 34L) {
  stop("H01 Stage 3 requires 17 main near-eye and 17 main chest rows", call. = FALSE)
}

primary_publication_summary <- model_results |>
  filter(.data$run_id == primary_run) |>
  transmute(
    .data$metric_order,
    .data$metric_id,
    .data$manuscript_category,
    .data$manuscript_name,
    .data$display_unit,
    .data$site_p_adjusted,
    .data$photoperiod_effect_type,
    .data$photoperiod_estimate_practical,
    .data$photoperiod_conf_low_practical,
    .data$photoperiod_conf_high_practical,
    .data$photoperiod_p_adjusted,
    .data$latitude_effect_type,
    .data$latitude_estimate_practical,
    .data$latitude_conf_low_practical,
    .data$latitude_conf_high_practical,
    .data$latitude_p_adjusted,
    .data$adequacy_p_adjusted,
    .data$participants,
    .data$participant_days,
    .data$observations,
    .data$sites
  ) |>
  arrange(.data$metric_order)

site_sample_support <- samples_by_site |>
  filter(.data$run_id %in% selected_runs) |>
  transmute(
    .data$run_id,
    .data$metric_order,
    .data$metric_id,
    .data$site,
    site_participants = as.integer(.data$participants),
    site_participant_days = as.integer(.data$participant_days),
    site_observations = as.integer(.data$observations)
  )
if (
  anyDuplicated(
    site_sample_support[c("run_id", "metric_order", "metric_id", "site")]
  ) ||
    any(site_sample_support$site_observations <= 0L)
) {
  stop("The stored H01 per-site fitted samples are invalid", call. = FALSE)
}

site_contrasts <- site_deviations |>
  filter(
    .data$run_id %in% selected_runs,
    .data$inferential_followup_supported
  ) |>
  left_join(metric_registry, by = c("metric_order", "metric_id")) |>
  left_join(run_registry, by = "run_id", relationship = "many-to-one") |>
  left_join(site_registry, by = "site", relationship = "many-to-one") |>
  left_join(
    site_sample_support,
    by = c("run_id", "metric_order", "metric_id", "site"),
    relationship = "one-to-one"
  ) |>
  mutate(
    null_value = if_else(.data$effect_type == "ratio", 1, 0),
    supported_within_metric = .data$p_adjusted_within_metric < 0.05,
    support_display = if_else(
      .data$supported_within_metric,
      "Adjusted p < 0.050",
      "Adjusted p ≥ 0.050"
    ),
    scale_group = if_else(.data$effect_type == "ratio", "Ratios", "Differences"),
    figure_panel_tag = if_else(.data$scale_group == "Ratios", "A", "B"),
    figure_panel_label = paste0(.data$figure_panel_tag, ". ", .data$scale_group),
    metric_facet_label = .data$manuscript_name,
    site_panel_key = paste(.data$metric_id, .data$site, sep = "__"),
    site_axis_label = paste0(
      sub("\\)$", "", .data$display_name),
      ", n=", .data$site_observations, ")"
    )
  ) |>
  group_by(.data$run_id, .data$metric_id) |>
  mutate(
    display_half_range = 1.08 * max(
      abs(c(
        .data$conf_low_practical - first(.data$null_value),
        .data$conf_high_practical - first(.data$null_value)
      )),
      na.rm = TRUE
    ),
    display_half_range = pmax(
      .data$display_half_range,
      if_else(first(.data$null_value) == 1, 0.05, 0.10)
    ),
    display_x_min = .data$null_value - .data$display_half_range,
    display_x_max = .data$null_value + .data$display_half_range
  ) |>
  ungroup() |>
  arrange(.data$run_order, .data$metric_order, .data$display_order)
if (
  anyNA(site_contrasts[c(
    "site_participants", "site_participant_days", "site_observations",
    "scale_group", "figure_panel_tag", "figure_panel_label",
    "metric_facet_label", "display_x_min", "display_x_max"
  )]) ||
    any(site_contrasts$display_half_range <= 0)
) {
  stop("The H01 site-contrast display metadata are incomplete", call. = FALSE)
}

question_support <- tests |>
  select("run_id", "metric_id", "family_id", "p_adjusted") |>
  left_join(question_registry, by = "family_id", relationship = "many-to-one") |>
  mutate(supported = !is.na(.data$p_adjusted) & .data$p_adjusted < 0.05) |>
  select("run_id", "metric_id", "question_id", "supported") |>
  pivot_wider(
    names_from = "question_id",
    values_from = "supported",
    names_glue = "{question_id}_supported"
  )

r2_stage3 <- r2 |>
  filter(
    .data$run_id %in% selected_runs,
    .data$approximation == "lognormal"
  ) |>
  left_join(metric_registry, by = c("metric_order", "metric_id")) |>
  left_join(run_registry, by = "run_id", relationship = "many-to-one") |>
  left_join(
    question_support,
    by = c("run_id", "metric_id"),
    relationship = "many-to-one"
  ) |>
  mutate(
    term_supported = case_when(
      .data$measure == "site_part_r2" ~ .data$site_supported,
      .data$measure == "photoperiod_part_r2" ~ .data$photoperiod_supported,
      .data$measure == "latitude_part_r2" ~ .data$latitude_supported,
      TRUE ~ NA
    )
  ) |>
  arrange(.data$run_order, .data$metric_order, .data$measure)

r2_table_measures <- c(
  "conditional_r2", "marginal_r2", "participant_associated_share",
  "unrepresented_share", "site_part_r2", "photoperiod_part_r2",
  "latitude_part_r2"
)
r2_term_measures <- c(
  "site_part_r2", "photoperiod_part_r2", "latitude_part_r2"
)
r2_table_metrics <- r2_stage3 |>
  filter(.data$measure %in% r2_table_measures) |>
  transmute(
    .data$run_id,
    .data$run_order,
    .data$run_label,
    .data$placement_label,
    row_type = "Metric",
    .data$metric_order,
    .data$metric_id,
    .data$manuscript_category,
    .data$manuscript_name,
    .data$measure,
    .data$estimate,
    .data$conf_low,
    .data$conf_high,
    .data$bootstrap_successful_used,
    .data$term_supported,
    supported_n = if_else(
      .data$measure %in% r2_term_measures & .data$term_supported %in% TRUE,
      1L,
      if_else(.data$measure %in% r2_term_measures, 0L, NA_integer_)
    ),
    unsupported_n = if_else(
      .data$measure %in% r2_term_measures & .data$term_supported %in% FALSE,
      1L,
      if_else(.data$measure %in% r2_term_measures, 0L, NA_integer_)
    )
  )
r2_table_grand <- r2_table_metrics |>
  mutate(is_term_measure = .data$measure %in% r2_term_measures) |>
  group_by(
    .data$run_id, .data$run_order, .data$run_label, .data$placement_label,
    .data$measure, .data$is_term_measure
  ) |>
  summarise(
    row_type = "Grand average",
    metric_order = 0L,
    metric_id = "grand_average",
    manuscript_category = "Grand average",
    manuscript_name = "Grand average",
    estimate = if_else(
      dplyr::first(.data$is_term_measure),
      mean(.data$estimate[.data$term_supported %in% TRUE], na.rm = TRUE),
      mean(.data$estimate, na.rm = TRUE)
    ),
    conf_low = NA_real_,
    conf_high = NA_real_,
    bootstrap_successful_used = NA_integer_,
    supported_n = if_else(
      dplyr::first(.data$is_term_measure),
      sum(.data$term_supported %in% TRUE),
      NA_integer_
    ),
    unsupported_n = if_else(
      dplyr::first(.data$is_term_measure),
      sum(.data$term_supported %in% FALSE),
      NA_integer_
    ),
    term_supported = NA,
    .groups = "drop"
  ) |>
  select(-"is_term_measure")
r2_table <- bind_rows(r2_table_grand, r2_table_metrics) |>
  arrange(.data$run_order, .data$metric_order, .data$measure)

synthesis_r2_measures <- c(
  "marginal_r2", "conditional_r2", "participant_associated_share",
  "site_part_r2", "photoperiod_part_r2", "latitude_part_r2"
)
synthesis_r2 <- r2_stage3 |>
  filter(
    .data$run_id == primary_run,
    .data$measure %in% synthesis_r2_measures
  ) |>
  select(
    "metric_id", "measure", "estimate", "conf_low", "conf_high",
    "bootstrap_successful_used", "term_supported"
  ) |>
  pivot_wider(
    names_from = "measure",
    values_from = c(
      "estimate", "conf_low", "conf_high", "bootstrap_successful_used",
      "term_supported"
    ),
    names_glue = "{.value}_{measure}"
  )

descriptive_overall <- descriptive_metric_summary |>
  filter(.data$placement == "near_eye", .data$site == "Overall") |>
  transmute(
    .data$metric_id,
    descriptive_metric_order = as.integer(.data$metric_order),
    descriptive_name = .data$manuscript_name,
    metric_description = .data$meaning_and_relevance,
    descriptive_analysis_unit = .data$analysis_unit,
    descriptive_unit = .data$unit,
    descriptive_scaling = .data$scaling,
    descriptive_median = .data$median,
    descriptive_q1 = .data$q1,
    descriptive_q3 = .data$q3,
    descriptive_median_display = .data$median_formatted,
    descriptive_q1_display = .data$q1_formatted,
    descriptive_q3_display = .data$q3_formatted,
    descriptive_participants = as.integer(.data$n_participants),
    descriptive_participant_days = as.integer(.data$n_participant_days),
    descriptive_observations = as.integer(.data$n_observations)
  )

primary_metric_synthesis <- primary_publication_summary |>
  left_join(
    descriptive_overall,
    by = "metric_id",
    relationship = "one-to-one"
  ) |>
  left_join(synthesis_r2, by = "metric_id", relationship = "one-to-one") |>
  mutate(
    density_artifact_path = paste0(
      "artifacts/10_figures/H01/stage3/metric_density/",
      "H01_stage3_metric_density_", .data$metric_id, ".png"
    ),
    site_supported = !is.na(.data$site_p_adjusted) &
      .data$site_p_adjusted < 0.05,
    photoperiod_supported = !is.na(.data$photoperiod_p_adjusted) &
      .data$photoperiod_p_adjusted < 0.05,
    latitude_supported = !is.na(.data$latitude_p_adjusted) &
      .data$latitude_p_adjusted < 0.05
  ) |>
  arrange(.data$metric_order)

if (
  nrow(descriptive_overall) != 17L ||
    nrow(primary_metric_synthesis) != 17L ||
    anyDuplicated(primary_metric_synthesis$metric_id) ||
    !setequal(primary_metric_synthesis$metric_id, metric_registry$metric_id) ||
    anyNA(primary_metric_synthesis[c(
      "metric_description", "descriptive_analysis_unit", "descriptive_unit",
      "descriptive_scaling",
      "descriptive_median", "descriptive_q1", "descriptive_q3",
      "descriptive_median_display", "descriptive_q1_display",
      "descriptive_q3_display", "descriptive_participants",
      "descriptive_participant_days", "descriptive_observations"
    )]) ||
    any(primary_metric_synthesis$sites != 9L) ||
    any(
      primary_metric_synthesis$bootstrap_successful_used_marginal_r2 < 1000L |
        primary_metric_synthesis$bootstrap_successful_used_conditional_r2 < 1000L |
        primary_metric_synthesis$bootstrap_successful_used_site_part_r2 < 1000L |
        primary_metric_synthesis$bootstrap_successful_used_photoperiod_part_r2 < 1000L |
        primary_metric_synthesis$bootstrap_successful_used_latitude_part_r2 < 1000L
    ) ||
    any(
      primary_metric_synthesis$site_supported !=
        primary_metric_synthesis$term_supported_site_part_r2 |
        primary_metric_synthesis$photoperiod_supported !=
          primary_metric_synthesis$term_supported_photoperiod_part_r2 |
        primary_metric_synthesis$latitude_supported !=
          primary_metric_synthesis$term_supported_latitude_part_r2
    )
) {
  stop("The H01 primary metric synthesis failed its source contract", call. = FALSE)
}

exact_samples <- samples |>
  left_join(metric_registry, by = c("metric_order", "metric_id")) |>
  left_join(run_registry, by = "run_id", relationship = "many-to-one") |>
  arrange(.data$run_order, .data$metric_order)

exact_samples_by_site <- samples_by_site |>
  left_join(metric_registry, by = c("metric_order", "metric_id")) |>
  left_join(run_registry, by = "run_id", relationship = "many-to-one") |>
  left_join(site_registry, by = "site", relationship = "many-to-one") |>
  arrange(.data$run_order, .data$metric_order, .data$display_order)

formula_manifest <- model_manifest |>
  distinct(
    .data$analysis_unit,
    .data$model_name,
    .data$estimation_stage,
    .data$formula,
    .data$engine,
    .data$estimation_method,
    .data$family,
    .data$link
  ) |>
  arrange(.data$analysis_unit, .data$model_name, .data$estimation_stage, .data$engine)

support_summary <- tests |>
  left_join(question_registry, by = "family_id", relationship = "many-to-one") |>
  left_join(run_registry, by = "run_id", relationship = "many-to-one") |>
  group_by(
    .data$run_id, .data$run_order, .data$run_label, .data$data_label,
    .data$placement_label, .data$sample_label, .data$question_order,
    .data$family_id, .data$question_label
  ) |>
  summarise(
    planned_tests = dplyr::n(),
    supported_metrics = sum(.data$p_adjusted < 0.05, na.rm = TRUE),
    nonestimable_metrics = sum(is.na(.data$p_adjusted)),
    family_status = paste(unique(.data$family_status), collapse = "; "),
    .groups = "drop"
  ) |>
  arrange(.data$run_order, .data$question_order)

primary_support_reference <- tests |>
  filter(.data$run_id == primary_run) |>
  transmute(
    .data$metric_id,
    .data$family_id,
    primary_supported = !is.na(.data$p_adjusted) & .data$p_adjusted < 0.05
  )
sensitivity_classification <- tests |>
  filter(.data$run_id != primary_run) |>
  left_join(
    primary_support_reference,
    by = c("metric_id", "family_id"),
    relationship = "many-to-one"
  ) |>
  left_join(run_registry, by = "run_id", relationship = "many-to-one") |>
  mutate(
    target_supported = case_when(
      is.na(.data$p_adjusted) ~ NA,
      .data$p_adjusted < 0.05 ~ TRUE,
      TRUE ~ FALSE
    )
  ) |>
  group_by(
    .data$run_id, .data$run_order, .data$run_label, .data$data_label,
    .data$placement_label, .data$sample_label
  ) |>
  summarise(
    evaluated_cells = dplyr::n(),
    nonestimable_cells = sum(is.na(.data$target_supported)),
    support_switches = sum(
      !is.na(.data$target_supported) &
        .data$target_supported != .data$primary_supported
    ),
    classification = case_when(
      .data$support_switches == 0L & .data$nonestimable_cells == 0L ~ "Stable",
      .data$support_switches == 0L ~ "Inconclusive",
      TRUE ~ "Qualitatively sensitive"
    ),
    .groups = "drop"
  ) |>
  arrange(.data$run_order)

support_matrix <- tests |>
  filter(.data$run_id %in% selected_runs) |>
  left_join(metric_registry, by = c("metric_order", "metric_id")) |>
  left_join(run_registry, by = "run_id", relationship = "many-to-one") |>
  left_join(question_registry, by = "family_id", relationship = "many-to-one") |>
  mutate(
    support_status = case_when(
      is.na(.data$p_adjusted) ~ "Not estimable",
      .data$p_adjusted < 0.05 ~ "Supported",
      TRUE ~ "Not supported"
    ),
    support_symbol = case_when(
      .data$support_status == "Supported" ~ "✓",
      .data$support_status == "Not estimable" ~ "?",
      TRUE ~ "–"
    )
  ) |>
  arrange(.data$run_order, .data$metric_order, .data$question_order)

diagnostic_matrix <- diagnostic_assessment |>
  transmute(
    .data$run_id,
    .data$run_order,
    .data$placement_label,
    .data$metric_order,
    .data$manuscript_name,
    `Convergence and Hessian` = case_when(
      coalesce(.data$converged, FALSE) &
        coalesce(.data$positive_definite_hessian, FALSE) ~ "Pass",
      TRUE ~ "Fail"
    ),
    `Random-effect singularity` = case_when(
      is.na(.data$singular) ~ "Not applicable",
      !.data$singular ~ "Pass",
      TRUE ~ "Review"
    ),
    `Residual distribution` = case_when(
      .data$residual_status == "PASS" ~ "Pass",
      is.na(.data$residual_status) ~ "Not applicable",
      TRUE ~ "Review"
    ),
    `Prediction bounds` = case_when(
      .data$prediction_bound_status == "PASS" ~ "Pass",
      .data$prediction_bound_status == "UPPER_BOUND_UNAVAILABLE" ~
        "Not applicable",
      is.na(.data$prediction_bound_status) ~ "Not applicable",
      TRUE ~ "Review"
    ),
    `Construct audit` = case_when(
      .data$audit_threshold_status == "PASS" ~ "Pass",
      .data$audit_threshold_status == "NOT_APPLICABLE" ~ "Not applicable",
      is.na(.data$audit_threshold_status) ~ "Not applicable",
      TRUE ~ "Review"
    ),
    `Clock-time cut` = case_when(
      .data$timing_status == "PASS" ~ "Pass",
      .data$timing_status == "NOT_APPLICABLE" ~ "Not applicable",
      is.na(.data$timing_status) ~ "Not applicable",
      TRUE ~ "Review"
    )
  ) |>
  pivot_longer(
    cols = c(
      "Convergence and Hessian", "Random-effect singularity",
      "Residual distribution", "Prediction bounds", "Construct audit",
      "Clock-time cut"
    ),
    names_to = "diagnostic_check",
    values_to = "check_status"
  ) |>
  mutate(
    check_order = match(
      .data$diagnostic_check,
      c(
        "Convergence and Hessian", "Random-effect singularity",
        "Residual distribution", "Prediction bounds", "Construct audit",
        "Clock-time cut"
      )
    ),
    check_symbol = recode(
      .data$check_status,
      Pass = "P",
      Review = "R",
      Fail = "F",
      `Not applicable` = "—"
    )
  )

influence_summary <- participant_influence |>
  filter(.data$run_id %in% selected_runs) |>
  group_by(.data$run_id, .data$metric_order, .data$metric_id) |>
  arrange(desc(.data$maximum_absolute_dfbeta), .by_group = TRUE) |>
  summarise(
    refits = dplyr::n(),
    successful_refits = sum(.data$refit_status == "PASS"),
    maximum_absolute_dfbeta = dplyr::first(.data$maximum_absolute_dfbeta),
    most_influential_participant = dplyr::first(.data$omitted_participant),
    maximum_dfbeta_term = dplyr::first(.data$maximum_dfbeta_term),
    .groups = "drop"
  ) |>
  left_join(metric_registry, by = c("metric_order", "metric_id")) |>
  left_join(run_registry, by = "run_id", relationship = "many-to-one") |>
  arrange(.data$run_order, .data$metric_order)

latitude_loo_summary <- latitude_loo |>
  filter(.data$run_id %in% selected_runs) |>
  group_by(
    .data$run_id, .data$metric_order, .data$metric_id, .data$effect_type
  ) |>
  summarise(
    omitted_site_refits = dplyr::n(),
    successful_refits = sum(.data$status == "PASS" & is.na(.data$refit_error)),
    minimum_estimate = min(.data$estimate_practical, na.rm = TRUE),
    maximum_estimate = max(.data$estimate_practical, na.rm = TRUE),
    .groups = "drop"
  ) |>
  mutate(
    null_value = if_else(.data$effect_type == "ratio", 1, 0),
    range_crosses_null =
      .data$minimum_estimate <= .data$null_value &
      .data$maximum_estimate >= .data$null_value
  ) |>
  left_join(metric_registry, by = c("metric_order", "metric_id")) |>
  left_join(run_registry, by = "run_id", relationship = "many-to-one") |>
  arrange(.data$run_order, .data$metric_order)

primary_l10_tests <- tests |>
  filter(
    .data$run_id %in% selected_runs,
    .data$metric_id == "l10_midpoint"
  ) |>
  left_join(question_registry, by = "family_id", relationship = "many-to-one") |>
  transmute(
    .data$run_id,
    variant = "Primary strict-after-16:00 conversion",
    .data$question_order,
    .data$question_label,
    .data$p_raw,
    adjusted_p = .data$p_adjusted,
    multiplicity = "Primary 17-test BH family"
  )
noon_l10_tests <- noon_tests |>
  filter(.data$run_id %in% selected_runs) |>
  mutate(
    question_id = recode(
      .data$comparison_id,
      site_full_vs_no_site = "site",
      site_full_vs_no_photoperiod = "photoperiod",
      latitude_full_vs_no_latitude = "latitude",
      site_full_vs_latitude_full = "adequacy"
    )
  ) |>
  left_join(question_registry, by = "question_id", relationship = "many-to-one") |>
  transmute(
    .data$run_id,
    variant = "Noon-cut sensitivity",
    .data$question_order,
    .data$question_label,
    .data$p_raw,
    adjusted_p = NA_real_,
    multiplicity = "Outside primary multiplicity families"
  )
l10_sensitivity <- bind_rows(primary_l10_tests, noon_l10_tests) |>
  left_join(run_registry, by = "run_id", relationship = "many-to-one") |>
  arrange(.data$run_order, .data$variant, .data$question_order)

period_sensitivity_stage3 <- period_sensitivity |>
  filter(.data$run_id %in% selected_runs) |>
  mutate(
    question_id = recode(
      .data$comparison_id,
      site_full_vs_no_site = "site",
      site_full_vs_no_photoperiod = "photoperiod",
      latitude_full_vs_no_latitude = "latitude",
      site_full_vs_latitude_full = "adequacy"
    )
  ) |>
  left_join(question_registry, by = "question_id", relationship = "many-to-one") |>
  left_join(run_registry, by = "run_id", relationship = "many-to-one") |>
  arrange(.data$run_order, .data$question_order)

scope_sensitivity_stage3 <- scope_sensitivity |>
  left_join(metric_registry, by = c("metric_order", "metric_id")) |>
  left_join(question_registry, by = "family_id", relationship = "many-to-one") |>
  left_join(run_registry, by = "run_id", relationship = "many-to-one") |>
  arrange(.data$run_order, .data$metric_order, .data$question_order)

marginalization_stage3 <- marginalization |>
  filter(.data$run_id %in% selected_runs) |>
  left_join(metric_registry, by = c("metric_order", "metric_id")) |>
  left_join(run_registry, by = "run_id", relationship = "many-to-one") |>
  arrange(.data$run_order, .data$metric_order)

deviations <- tibble::tribble(
  ~deviation_ids, ~topic, ~registered_or_expected, ~analysis_used,
  "DEV-001; REP-001; REP-002", "Placement",
  "Chest measurements were primary and near-eye measurements a robustness repeat.",
  "Near-eye measurements are primary; chest measurements are complementary and placements are not pooled.",
  "DEV-003; DEV-004; IMP-003; DEV-055", "Inclusion and support",
  "Protocol eligibility and fixed daily/hourly coverage exclusions defined the sample.",
  "Verified participant-day coverage is followed by metric-specific support; every fitted model reports its exact rows and support hours.",
  "DEV-005; DEV-006; IMP-018; IMP-019; REP-003", "Sleep and non-wear",
  "Logged non-wear and sleep exclusions were applied without a fully specified state hierarchy.",
  "Diary sleep has precedence, invalid non-wear is masked consistently, and sleep measurements are described as the bedside environment rather than ocular exposure.",
  "IMP-002", "Upper light boundary",
  "Values above 120,000 lx were to be removed.",
  "The verified analytical melEDI signal retains values strictly below 100,000 lx.",
  "DEV-007", "Darkest-window level",
  "The level metric used the five darkest hours.",
  "The approved metric is the mean melEDI during the darkest 10 hours.",
  "DEV-008; DEV-054", "Threshold timing",
  "The timing outcome was the midpoint of the longest period above 250 lx.",
  "The registered midpoint of the longest qualifying period is retained. Mean timing above 250 lx melEDI is a distinct circular duration-weighted metric and is labelled as an adapted sensitivity; period construction follows verified continuity and support rules.",
  "DEV-009", "Site and latitude",
  "One model included both site and latitude.",
  "Because each site has one latitude, fixed-site and linear-latitude models are fitted separately on identical rows and compared for adequacy.",
  "DEV-017", "Photoperiod scope",
  "Photoperiod adjustment was specified for duration metrics.",
  "Photoperiod is included in the common model implementation for all 17 metrics.",
  "DEV-018", "Response models",
  "Linear mixed models were specified generically.",
  "Each metric uses its approved Gaussian transformation or Tweedie log-link response model.",
  "IMP-001; DEV-009", "Multiplicity",
  "False-discovery-rate control was required within H1 but the exact vectors were not specified.",
  "Four separate complete 17-test Benjamini–Hochberg families are used for site, photoperiod, latitude, and site-versus-latitude adequacy.",
  "DEV-009", "Site follow-ups",
  "Site coefficients were reported without a fixed hierarchical follow-up rule.",
  "Only after a supported overall site test, each site is compared with the equally weighted overall site mean and the site contrasts are adjusted within metric.",
  "IMP-003; IMP-004", "Variation, uncertainty, and exact samples",
  "Conditional R² and significance-dependent component summaries were used without joint interval estimation or exact model-specific sample reporting.",
  "Marginal and conditional R², participant-associated share, and non-overlapping term part-R² summaries use 1,000 successful joint bootstrap refits and 95% intervals; exact model-specific samples are reported.",
  "IMP-010", "Model comparison",
  "Fixed-effect structures had been compared using REML-derived criteria.",
  "Gaussian fixed-effect comparisons use maximum likelihood; final Gaussian estimation uses REML where applicable.",
  "IMP-012", "Full-day construct",
  "The intended relation between worn exposure and sleep-period environmental measurement was implicit.",
  "The 24-hour record retains both constructs but keeps their interpretations distinct.",
  "DEV-058", "Melanopic daylight efficacy ratio",
  "The submitted implementation averaged available momentary melEDI-to-photopic-illuminance ratios; the preregistration did not specify a ratio-of-integrals replacement.",
  "MDER is the arithmetic mean of viable one-minute melEDI-to-photopic-illuminance ratios. Both channels must be finite and strictly positive, and at least 720 viable minutes are required on the complete 1,440-minute local wall-clock grid.",
  "IMP-014; DEV-053", "Interdaily stability and intradaily variability",
  "Incomplete repeated-day support could enter the dynamics metrics.",
  "Dynamics metrics use verified temporal support and report participant-level model rows plus contributing participant-days.",
  "IMP-015; DEV-054", "Windows, periods, and timing",
  "Missing intervals could be bridged or incomplete windows summarized.",
  "Windows and continuous periods use support, continuity, gap, wrapping, and tie rules fixed before modelling.",
  "IMP-016; DEV-052", "melEDI dose",
  "Dose could be a partial sum without a defined support denominator.",
  "Dose is time-sensitive and retained only with the approved interval support.",
  "IMP-017; IMP-020", "Time axes and source epochs",
  "A single local time axis and one assumed source epoch were used.",
  "Absolute time governs ordering and duration, local wall time governs clock metrics, repeated fall-back bins are handled explicitly, and each source epoch is respected.",
  "DEV-049; DEV-050", "Software environment",
  "R 4.5 and earlier LightLogR/API versions were named.",
  "The analysis uses the verified R 4.6.1 project library and pinned contemporary package APIs.",
  "DEV-057", "Participant-day plausibility",
  "The preregistration and submitted implementation use coverage and signal-validity rules but do not specify exclusion of an otherwise eligible complete exact-zero melEDI day.",
  "An otherwise eligible participant-day is excluded only when every finite one-minute melEDI value is exactly 0 lx; individual zeros remain valid and the former inclusion is retained as a fixed data sensitivity.",
  "IMP-024", "Pre-sleep duration",
  "The label implied a single three-hour window before sleep.",
  "The outcome is calendar-day cumulative time below 10 lx melEDI across every diary-defined pre-sleep interval; values strictly above six hours trigger an audit warning but are not capped.",
  "IMP-023", "Darkest-10-hour midpoint",
  "The clock response was linearized around noon.",
  "The primary conversion subtracts 24 hours only for values strictly after 16:00; the noon cut is a registered same-row sensitivity."
)

# Build the paired photoperiod/latitude source without altering model inputs.
near_photoperiod <- read_required(
  "artifacts/11_source_data/descriptives/latitude_photoperiod.csv"
) |>
  transmute(
    placement = "glasses",
    .data$site,
    participant_key = .data$Id,
    .data$local_date,
    .data$photoperiod_hours,
    .data$absolute_latitude_deg,
    .data$deterministic_plot_offset_deg,
    .data$plot_latitude_deg
  )
h01_data <- readRDS(file.path(root, "artifacts/06_model_data/H01.rds"))
chest_photoperiod <- h01_data$model_rows |>
  filter(
    .data$placement == "chest",
    .data$scenario == "all_available",
    .data$metric_id == "daily_geometric_mean_medi",
    .data$scenario_estimable,
    .data$site_photoperiod_included,
    .data$latitude_photoperiod_included
  ) |>
  arrange(.data$site, .data$participant_key, .data$local_date) |>
  group_by(.data$site) |>
  mutate(
    deterministic_plot_offset_deg =
      seq(-0.2, 0.2, length.out = 17)[(dplyr::row_number() - 1L) %% 17L + 1L],
    absolute_latitude_deg = abs(.data$latitude_deg),
    plot_latitude_deg =
      .data$absolute_latitude_deg + .data$deterministic_plot_offset_deg
  ) |>
  ungroup() |>
  transmute(
    placement = "chest",
    .data$site,
    .data$participant_key,
    .data$local_date,
    .data$photoperiod_hours,
    .data$absolute_latitude_deg,
    .data$deterministic_plot_offset_deg,
    .data$plot_latitude_deg
  )
photoperiod_source <- bind_rows(near_photoperiod, chest_photoperiod) |>
  left_join(site_registry, by = "site", relationship = "many-to-one") |>
  arrange(.data$placement, .data$display_order, .data$participant_key, .data$local_date)
photoperiod_expected <- samples |>
  filter(
    .data$run_id %in% selected_runs,
    .data$metric_id == "daily_geometric_mean_medi"
  ) |>
  transmute(
    placement = .data$placement,
    expected_observations = as.integer(.data$observations)
  )
photoperiod_observed <- photoperiod_source |>
  count(.data$placement, name = "observed_observations") |>
  left_join(
    photoperiod_expected,
    by = "placement",
    relationship = "one-to-one"
  )
if (
  nrow(photoperiod_observed) != length(selected_runs) ||
    anyNA(photoperiod_observed$expected_observations) ||
    any(
      photoperiod_observed$observed_observations !=
        photoperiod_observed$expected_observations
    )
) {
  stop("The Stage 3 photoperiod source does not match exact fitted samples", call. = FALSE)
}
photoperiod_bounds <- read_required(
  paste0(
    "artifacts/11_source_data/H01/reporting/",
    "H01_figure_s10_theoretical_bounds_source.csv"
  )
)

# Compare matched paired/common-sample placement estimands without refitting.
paired_near_run <- "main__glasses__paired_common_sample"
paired_chest_run <- "main__chest__paired_common_sample"
paired_terms <- c(
  "photoperiod_centered_hours",
  "absolute_latitude_10deg_centered"
)
paired_effect_base <- term_effects |>
  filter(
    .data$run_id %in% c(paired_near_run, paired_chest_run),
    .data$term %in% paired_terms,
    is.finite(.data$estimate_practical),
    is.finite(.data$conf_low_practical),
    is.finite(.data$conf_high_practical)
  ) |>
  transmute(
    .data$run_id,
    .data$metric_order,
    .data$metric_id,
    .data$analysis_unit,
    .data$response_family,
    .data$response_transform,
    .data$term,
    .data$effect_type,
    .data$estimate_practical,
    .data$conf_low_practical,
    .data$conf_high_practical,
    .data$p_raw,
    .data$status
  )
paired_test_base <- tests |>
  filter(
    .data$run_id %in% c(paired_near_run, paired_chest_run),
    .data$family_id %in% c("H01-F2-photoperiod", "H01-F3-latitude")
  ) |>
  transmute(
    .data$run_id,
    .data$metric_id,
    term = if_else(
      .data$family_id == "H01-F2-photoperiod",
      "photoperiod_centered_hours",
      "absolute_latitude_10deg_centered"
    ),
    model_level_p_raw = .data$p_raw,
    model_level_bh_adjusted_p = .data$p_adjusted
  )
paired_effect_base <- paired_effect_base |>
  left_join(
    paired_test_base,
    by = c("run_id", "metric_id", "term"),
    relationship = "one-to-one"
  )
paired_near_effect <- paired_effect_base |>
  filter(.data$run_id == paired_near_run) |>
  select(-"run_id") |>
  rename_with(
    ~ paste0("near_", .x),
    -c("metric_order", "metric_id", "term")
  )
paired_chest_effect <- paired_effect_base |>
  filter(.data$run_id == paired_chest_run) |>
  select(-"run_id") |>
  rename_with(
    ~ paste0("chest_", .x),
    -c("metric_order", "metric_id", "term")
  )
paired_near_sample <- samples |>
  filter(.data$run_id == paired_near_run) |>
  transmute(
    .data$metric_id,
    near_participants = as.integer(.data$participants),
    near_participant_days = as.integer(.data$participant_days),
    near_observations = as.integer(.data$observations),
    near_sites = as.integer(.data$sites)
  )
paired_chest_sample <- samples |>
  filter(.data$run_id == paired_chest_run) |>
  transmute(
    .data$metric_id,
    chest_participants = as.integer(.data$participants),
    chest_participant_days = as.integer(.data$participant_days),
    chest_observations = as.integer(.data$observations),
    chest_sites = as.integer(.data$sites)
  )
paired_placement <- paired_near_effect |>
  inner_join(
    paired_chest_effect,
    by = c("metric_order", "metric_id", "term"),
    relationship = "one-to-one"
  ) |>
  left_join(paired_near_sample, by = "metric_id", relationship = "many-to-one") |>
  left_join(paired_chest_sample, by = "metric_id", relationship = "many-to-one") |>
  left_join(metric_registry, by = c("metric_order", "metric_id")) |>
  mutate(
    predictor = recode(
      .data$term,
      photoperiod_centered_hours = "Photoperiod",
      absolute_latitude_10deg_centered = "Latitude per 10°"
    ),
    predictor_order = if_else(.data$term == "photoperiod_centered_hours", 1L, 2L),
    effect_scale = if_else(.data$near_effect_type == "ratio", "Ratio", "Difference"),
    null_value = if_else(.data$near_effect_type == "ratio", 1, 0),
    point_label = paste0(
      .data$abbreviation,
      if_else(.data$term == "photoperiod_centered_hours", " · P", " · L")
    ),
    sample_exactly_matched =
      .data$near_participants == .data$chest_participants &
      .data$near_participant_days == .data$chest_participant_days &
      .data$near_observations == .data$chest_observations &
      .data$near_sites == .data$chest_sites
  ) |>
  arrange(.data$effect_scale, .data$metric_order, .data$predictor_order)
if (
  nrow(paired_placement) != 30L ||
    any(!paired_placement$sample_exactly_matched) ||
    any(paired_placement$near_response_family != paired_placement$chest_response_family) ||
    any(paired_placement$near_response_transform != paired_placement$chest_response_transform) ||
    any(paired_placement$near_effect_type != paired_placement$chest_effect_type) ||
    any(paired_placement$near_analysis_unit != paired_placement$chest_analysis_unit)
) {
  stop(
    "Stored H01 paired-placement estimands do not meet the matched-display rule",
    call. = FALSE
  )
}

table_root <- file.path(root, "artifacts/09_tables/H01/stage3")
figure_root <- file.path(root, "artifacts/10_figures/H01/stage3")
density_root <- file.path(figure_root, "metric_density")
source_root <- file.path(root, "artifacts/11_source_data/H01/stage3")
diagnostic_root <- file.path(root, "artifacts/08_diagnostics/H01/stage3")
manifest_path <- file.path(
  root,
  "artifacts/12_manifests/H01_stage3_reporting_artifacts.csv"
)
dir.create(table_root, recursive = TRUE, showWarnings = FALSE)
dir.create(figure_root, recursive = TRUE, showWarnings = FALSE)
dir.create(density_root, recursive = TRUE, showWarnings = FALSE)
dir.create(source_root, recursive = TRUE, showWarnings = FALSE)
dir.create(diagnostic_root, recursive = TRUE, showWarnings = FALSE)

unwrap_density_clock <- function(value, metric_id) {
  centers <- c(
    m10_midpoint = 840,
    l10_midpoint = 180,
    first_timing_above_250 = 540,
    last_timing_above_250 = 1080,
    mean_timing_above_250 = 810
  )
  center <- unname(centers[[metric_id]])
  if (is.null(center) || !is.finite(center)) {
    stop("No density-display clock centre for ", metric_id, call. = FALSE)
  }
  (value - center + 720) %% 1440 - 720 + center
}

make_metric_density_plot <- function(metric_id, scaling) {
  density_data <- descriptive_metric_values |>
    filter(
      .data$placement == "near_eye",
      .data$metric_id == .env$metric_id,
      .data$finite,
      is.finite(.data$value)
    ) |>
    transmute(
      site = factor(.data$site, levels = rev(site_registry$site)),
      display_value = .data$value
    )
  if (
    nrow(density_data) == 0L ||
      anyNA(density_data$site) ||
      dplyr::n_distinct(density_data$site) != nrow(site_registry)
  ) {
    stop("Incomplete density-display data for ", metric_id, call. = FALSE)
  }
  if (identical(scaling, "Circular clock")) {
    density_data$display_value <- unwrap_density_clock(
      density_data$display_value,
      metric_id
    )
  } else if (identical(scaling, "Symlog")) {
    density_data$display_value <- LightLogR::symlog_trans(
      base = 10,
      thr = 1,
      scale = 1
    )$transform(density_data$display_value)
  }

  site_palette <- stats::setNames(
    site_registry$color_hex,
    site_registry$site
  )
  site_labels <- stats::setNames(
    site_registry$display_name,
    site_registry$site
  )
  ggplot(
    density_data,
    aes(
      x = .data$display_value,
      y = .data$site,
      fill = .data$site,
      colour = .data$site
    )
  ) +
    ggridges::geom_density_ridges(
      alpha = 0.42,
      linewidth = 0.42,
      scale = 0.82,
      rel_min_height = 0.008,
      show.legend = FALSE
    ) +
    scale_fill_manual(values = site_palette, drop = FALSE) +
    scale_colour_manual(values = site_palette, drop = FALSE) +
    scale_y_discrete(labels = site_labels, drop = FALSE) +
    scale_x_continuous(expand = expansion(mult = c(0.025, 0.025))) +
    labs(x = NULL, y = NULL) +
    ggridges::theme_ridges(font_size = 9, grid = FALSE) +
    theme(
      axis.text.x = element_blank(),
      axis.ticks.x = element_blank(),
      axis.text.y = element_text(size = 7.2, lineheight = 0.9),
      panel.grid = element_blank(),
      plot.margin = margin(2, 2, 2, 2)
    )
}

density_figure_paths <- vapply(
  seq_len(nrow(primary_metric_synthesis)),
  function(index) {
    row <- primary_metric_synthesis[index, , drop = FALSE]
    path <- file.path(
      density_root,
      paste0("H01_stage3_metric_density_", row$metric_id[[1]], ".png")
    )
    ggsave(
      path,
      make_metric_density_plot(
        row$metric_id[[1]],
        row$descriptive_scaling[[1]]
      ),
      width = 2.7,
      height = 1.5,
      units = "in",
      dpi = 320,
      bg = "white"
    )
    path
  },
  character(1)
)
if (
  length(density_figure_paths) != 17L ||
    any(!file.exists(density_figure_paths)) ||
    any(file.info(density_figure_paths)$size <= 0L) ||
    !identical(
      substring(density_figure_paths, nchar(root) + 2L),
      primary_metric_synthesis$density_artifact_path
    )
) {
  stop("The H01 metric-density thumbnails are incomplete", call. = FALSE)
}

representative_diagnostic_relative_paths <- c(
  "artifacts/08_diagnostics/H01/main/glasses/all_available/daily_geometric_mean_medi_diagnostics.png",
  "artifacts/08_diagnostics/H01/main/glasses/all_available/duration_below_10_pre_sleep_diagnostics.png",
  "artifacts/08_diagnostics/H01/main/glasses/all_available/duration_above_250_wake_diagnostics.png",
  "artifacts/08_diagnostics/H01/main/glasses/all_available/duration_below_1_sleep_environment_diagnostics.png"
)
representative_diagnostic_source_relative_paths <- c(
  "artifacts/11_source_data/H01/main/glasses/all_available/daily_geometric_mean_medi_diagnostic_plot_data.csv",
  "artifacts/11_source_data/H01/main/glasses/all_available/duration_below_10_pre_sleep_diagnostic_plot_data.csv",
  "artifacts/11_source_data/H01/main/glasses/all_available/duration_above_250_wake_diagnostic_plot_data.csv",
  "artifacts/11_source_data/H01/main/glasses/all_available/duration_below_1_sleep_environment_diagnostic_plot_data.csv"
)
representative_diagnostic_paths <- file.path(
  root,
  representative_diagnostic_relative_paths
)
representative_diagnostic_source_paths <- file.path(
  root,
  representative_diagnostic_source_relative_paths
)
if (
  !all(file.exists(representative_diagnostic_paths)) ||
    !all(file.exists(representative_diagnostic_source_paths))
) {
  stop("A preserved representative diagnostic plot or source file is missing", call. = FALSE)
}

figure_display_registry <- tibble::tribble(
  ~figure_id, ~artifact_path, ~reader_display_status, ~reason,
  "model_support", "artifacts/10_figures/H01/stage3/H01_stage3_model_support.png", "displayed", "Compact overview of the four corrected inferential families.",
  "site_contrasts_near_eye", "artifacts/10_figures/H01/stage3/H01_stage3_site_contrasts_near_eye.png", "displayed", "Primary hierarchical site contrasts.",
  "site_contrasts_chest", "artifacts/10_figures/H01/stage3/H01_stage3_site_contrasts_chest.png", "displayed", "Complementary hierarchical site contrasts.",
  "r2_intervals", "artifacts/10_figures/H01/stage3/H01_stage3_r2_intervals.png", "displayed", "Variation represented by the accepted models.",
  "diagnostic_assessment", "artifacts/10_figures/H01/stage3/H01_stage3_diagnostic_assessment.png", "displayed", "Overview of diagnostic review status.",
  "paired_placement", "artifacts/10_figures/H01/stage3/H01_stage3_paired_placement.png", "displayed", "Matched near-eye-versus-chest placement comparison.",
  "photoperiod_latitude_near_eye", "artifacts/10_figures/H01/stage3/H01_stage3_photoperiod_latitude_near_eye.png", "retained_not_displayed", "The standalone coverage section duplicated the descriptive report and was removed under REPORT-012/CHG-085.",
  "photoperiod_latitude_chest", "artifacts/10_figures/H01/stage3/H01_stage3_photoperiod_latitude_chest.png", "retained_not_displayed", "The standalone coverage section duplicated the descriptive report and was removed under REPORT-012/CHG-085.",
  "diagnostic_daily_geometric_mean_medi", representative_diagnostic_relative_paths[[1]], "displayed", "Representative Gaussian review example.",
  "diagnostic_duration_below_10_pre_sleep", representative_diagnostic_relative_paths[[2]], "displayed", "Representative Gaussian review example.",
  "diagnostic_duration_above_250_wake", representative_diagnostic_relative_paths[[3]], "displayed", "Representative Tweedie review example.",
  "diagnostic_duration_below_1_sleep_environment", representative_diagnostic_relative_paths[[4]], "displayed", "Representative strong Tweedie and prediction-bound review example."
)

tables <- list(
  H01_stage3_metric_registry = metric_registry,
  H01_stage3_model_results = model_results,
  H01_stage3_primary_publication_summary = primary_publication_summary,
  H01_stage3_primary_metric_synthesis = primary_metric_synthesis,
  H01_stage3_site_contrasts = site_contrasts,
  H01_stage3_r2 = r2_stage3,
  H01_stage3_r2_table = r2_table,
  H01_stage3_diagnostic_details = diagnostic_details,
  H01_stage3_figure_display_registry = figure_display_registry,
  H01_stage3_exact_samples = exact_samples,
  H01_stage3_exact_samples_by_site = exact_samples_by_site,
  H01_stage3_formula_manifest = formula_manifest,
  H01_stage3_sensitivity_support = support_summary,
  H01_stage3_sensitivity_classification = sensitivity_classification,
  H01_stage3_paired_placement = paired_placement,
  H01_stage3_l10_noon_sensitivity = l10_sensitivity,
  H01_stage3_exact_period_sensitivity = period_sensitivity_stage3,
  H01_stage3_scope_sensitivity = scope_sensitivity_stage3,
  H01_stage3_influence_summary = influence_summary,
  H01_stage3_latitude_loo_summary = latitude_loo_summary,
  H01_stage3_marginalization = marginalization_stage3,
  H01_stage3_deviations = deviations
)
table_paths <- vapply(names(tables), function(name) {
  path <- file.path(table_root, paste0(name, ".csv"))
  write_csv_artifact(tables[[name]], path, producer = producer)
  path
}, character(1))

source_objects <- list(
  H01_stage3_model_support_figure_source = support_matrix,
  H01_stage3_site_contrast_figure_source = site_contrasts,
  H01_stage3_r2_figure_source = r2_stage3 |>
    filter(.data$measure %in% c(
      "marginal_r2", "conditional_r2", "participant_associated_share",
      "unrepresented_share"
    )),
  H01_stage3_diagnostic_figure_source = diagnostic_matrix,
  H01_stage3_photoperiod_latitude_source = photoperiod_source,
  H01_stage3_photoperiod_latitude_bounds = photoperiod_bounds,
  H01_stage3_l10_noon_effect_source = noon_effects |>
    filter(.data$run_id %in% selected_runs),
  H01_stage3_l10_noon_sample_source = noon_samples |>
    filter(.data$run_id %in% selected_runs),
  H01_stage3_latitude_leave_one_site_out_source = latitude_loo |>
    filter(.data$run_id %in% selected_runs),
  H01_stage3_participant_influence_source = participant_influence |>
    filter(.data$run_id %in% selected_runs),
  H01_stage3_paired_placement_figure_source = paired_placement
)
source_paths <- vapply(names(source_objects), function(name) {
  path <- file.path(source_root, paste0(name, ".csv"))
  write_csv_artifact(source_objects[[name]], path, producer = producer)
  path
}, character(1))

metric_levels <- rev(metric_registry$manuscript_name)
support_plot <- support_matrix |>
  mutate(
    manuscript_name = factor(.data$manuscript_name, levels = metric_levels),
    question_label = factor(
      .data$question_label,
      levels = question_registry$question_label
    ),
    placement_label = factor(
      .data$placement_label,
      levels = c("Near eye", "Chest")
    )
  ) |>
  ggplot(aes(x = .data$question_label, y = .data$manuscript_name)) +
  geom_tile(aes(fill = .data$support_status), colour = "white", linewidth = 0.35) +
  geom_text(aes(label = .data$support_symbol), size = 4.0, colour = "#111111") +
  facet_wrap(vars(.data$placement_label), ncol = 2) +
  scale_fill_manual(
    values = c(
      Supported = "#88CCEE",
      `Not supported` = "#ECECEC",
      `Not estimable` = "#CC6677"
    ),
    drop = FALSE
  ) +
  labs(x = NULL, y = NULL, fill = "FDR-adjusted result") +
  theme_minimal(base_size = 9) +
  theme(
    panel.grid = element_blank(),
    axis.text.x = element_text(size = 11.2, angle = 28, hjust = 1),
    axis.text.y = element_text(size = 11.2),
    strip.text = element_text(size = 11.2, face = "bold"),
    legend.text = element_text(size = 11.2),
    legend.title = element_text(size = 11.2),
    legend.position = "bottom"
  )

site_colors <- stats::setNames(site_registry$color_hex, site_registry$display_name)
make_contrast_scale_panel <- function(data, scale_group, show_legend) {
  data <- data |>
    filter(.data$scale_group == .env$scale_group)
  facet_levels <- data |>
    distinct(.data$metric_order, .data$metric_facet_label) |>
    arrange(.data$metric_order) |>
    pull(.data$metric_facet_label)
  site_panel_levels <- data |>
    distinct(.data$metric_order, .data$display_order, .data$site_panel_key) |>
    arrange(.data$metric_order, desc(.data$display_order)) |>
    pull(.data$site_panel_key)
  site_panel_labels <- data |>
    distinct(.data$site_panel_key, .data$site_axis_label) |>
    tibble::deframe()
  panel_limits <- data |>
    distinct(
      .data$metric_order,
      .data$metric_facet_label,
      .data$display_x_min,
      .data$display_x_max
    ) |>
    pivot_longer(
      cols = c("display_x_min", "display_x_max"),
      names_to = "limit_name",
      values_to = "display_limit"
    )
  data <- data |>
    mutate(
      site_panel_key = factor(.data$site_panel_key, levels = site_panel_levels),
      metric_facet_label = factor(
        .data$metric_facet_label,
        levels = facet_levels
      ),
      support_display = factor(
        .data$support_display,
        levels = c("Adjusted p < 0.050", "Adjusted p ≥ 0.050")
      )
    )
  panel_limits <- panel_limits |>
    mutate(
      metric_facet_label = factor(
        .data$metric_facet_label,
        levels = facet_levels
      )
    )
  nulls <- data |>
    distinct(.data$metric_facet_label, .data$null_value)
  ggplot(
    data,
    aes(
      x = .data$estimate_practical,
      y = .data$site_panel_key,
      colour = .data$display_name
    )
  ) +
    geom_blank(
      data = panel_limits,
      aes(x = .data$display_limit),
      inherit.aes = FALSE
    ) +
    geom_vline(
      data = nulls,
      aes(xintercept = .data$null_value),
      inherit.aes = FALSE,
      colour = "#555555",
      linetype = 2,
      linewidth = 0.35
    ) +
    geom_errorbar(
      aes(
        xmin = .data$conf_low_practical,
        xmax = .data$conf_high_practical,
        linewidth = .data$support_display
      ),
      width = 0,
      orientation = "y"
    ) +
    geom_point(
      aes(
        shape = .data$support_display,
        fill = .data$display_name
      ),
      size = 2.7,
      stroke = 0.7
    ) +
    facet_wrap(vars(.data$metric_facet_label), scales = "free", ncol = 2) +
    scale_x_continuous(expand = expansion(mult = c(0.04, 0.04))) +
    scale_y_discrete(labels = site_panel_labels) +
    scale_colour_manual(values = site_colors, drop = FALSE, guide = "none") +
    scale_fill_manual(values = site_colors, drop = FALSE, guide = "none") +
    scale_shape_manual(
      name = "Within-metric contrast",
      values = c(
        "Adjusted p < 0.050" = 21,
        "Adjusted p ≥ 0.050" = 1
      )
    ) +
    scale_linewidth_manual(
      values = c(
        "Adjusted p < 0.050" = 0.9,
        "Adjusted p ≥ 0.050" = 0.38
      ),
      guide = "none"
    ) +
    labs(
      title = paste0(
        if (scale_group == "Ratios") "A" else "B",
        ". ", scale_group
      ),
      x = if (
        scale_group == "Ratios"
      ) {
        "Ratio versus the equally weighted site mean"
      } else {
        "Difference versus the equally weighted site mean"
      },
      y = NULL
    ) +
    theme_minimal(base_size = 11.5) +
    theme(
      panel.grid.minor = element_blank(),
      axis.text = element_text(size = 10),
      axis.title = element_text(size = 11),
      strip.text = element_text(face = "bold", size = 10.5),
      plot.title = element_text(face = "bold", size = 13, hjust = 0),
      plot.title.position = "plot",
      legend.position = if (show_legend) "bottom" else "none",
      legend.title = element_text(size = 10),
      legend.text = element_text(size = 10)
    ) +
    guides(
      shape = guide_legend(
        override.aes = list(
          colour = "#444444",
          fill = c("#444444", "white"),
          size = 2.7,
          linewidth = c(0.9, 0.38)
        )
      )
    )
}
make_contrast_plot <- function(data, placement_name) {
  selected <- data |>
    filter(.data$placement_label == .env$placement_name)
  metric_counts <- selected |>
    distinct(.data$scale_group, .data$metric_id) |>
    count(.data$scale_group, name = "metrics")
  ratios <- make_contrast_scale_panel(selected, "Ratios", show_legend = FALSE)
  differences <- make_contrast_scale_panel(
    selected,
    "Differences",
    show_legend = TRUE
  )
  ratio_rows <- ceiling(
    metric_counts$metrics[metric_counts$scale_group == "Ratios"] / 2
  )
  difference_rows <- ceiling(
    metric_counts$metrics[metric_counts$scale_group == "Differences"] / 2
  )
  cowplot::plot_grid(
    ratios,
    differences,
    ncol = 1,
    align = "v",
    axis = "lr",
    rel_heights = c(ratio_rows + 0.45, difference_rows + 0.80)
  )
}
contrast_near_plot <- make_contrast_plot(site_contrasts, "Near eye")
contrast_chest_plot <- make_contrast_plot(site_contrasts, "Chest")

r2_measure_labels <- c(
  marginal_r2 = "Marginal R²",
  conditional_r2 = "Conditional R²",
  participant_associated_share = "Participant-associated share",
  unrepresented_share = "Not represented"
)
r2_plot_data <- source_objects$H01_stage3_r2_figure_source |>
  filter(.data$status == "PASS") |>
  mutate(
    manuscript_name = factor(.data$manuscript_name, levels = metric_levels),
    measure_label = factor(
      unname(r2_measure_labels[.data$measure]),
      levels = unname(r2_measure_labels)
    ),
    placement_label = factor(
      .data$placement_label,
      levels = c("Near eye", "Chest")
    )
  )
r2_plot <- ggplot(
  r2_plot_data,
  aes(
    x = .data$estimate,
    y = .data$manuscript_name,
    colour = .data$measure_label,
    shape = .data$measure_label
  )
) +
  geom_errorbar(
    aes(xmin = .data$conf_low, xmax = .data$conf_high),
    width = 0,
    orientation = "y",
    position = position_dodge(width = 0.62),
    linewidth = 0.4
  ) +
  geom_point(position = position_dodge(width = 0.62), size = 1.55) +
  facet_wrap(vars(.data$placement_label), ncol = 2) +
  scale_colour_manual(values = c("#117733", "#332288", "#CC6677", "#777777")) +
  scale_shape_manual(values = c(16, 17, 15, 18)) +
  coord_cartesian(xlim = c(0, 1)) +
  labs(x = "Share of outcome variance (95% bootstrap interval)", y = NULL) +
  theme_minimal(base_size = 9.5) +
  theme(
    panel.grid.minor = element_blank(),
    strip.text = element_text(face = "bold"),
    legend.position = "bottom",
    legend.title = element_blank()
  )

diagnostic_plot <- diagnostic_matrix |>
  mutate(
    manuscript_name = factor(.data$manuscript_name, levels = metric_levels),
    diagnostic_check = factor(
      .data$diagnostic_check,
      levels = unique(diagnostic_matrix$diagnostic_check[order(diagnostic_matrix$check_order)])
    ),
    placement_label = factor(
      .data$placement_label,
      levels = c("Near eye", "Chest")
    )
  ) |>
  ggplot(aes(x = .data$diagnostic_check, y = .data$manuscript_name)) +
  geom_tile(aes(fill = .data$check_status), colour = "white", linewidth = 0.35) +
  geom_text(aes(label = .data$check_symbol), size = 4.3) +
  facet_wrap(vars(.data$placement_label), ncol = 2) +
  scale_fill_manual(
    values = c(
      Pass = "#88CCEE",
      Review = "#DDCC77",
      Fail = "#CC6677",
      `Not applicable` = "#ECECEC"
    ),
    drop = FALSE
  ) +
  labs(x = NULL, y = NULL, fill = "Assessment") +
  theme_minimal(base_size = 9.5) +
  theme(
    panel.grid = element_blank(),
    axis.text.x = element_text(size = 12.2, angle = 28, hjust = 1),
    axis.text.y = element_text(size = 12.2),
    strip.text = element_text(size = 12.2, face = "bold"),
    legend.text = element_text(size = 12.2),
    legend.title = element_text(size = 12.2),
    legend.position = "bottom"
  )

make_photoperiod_plot <- function(data, selected_placement) {
  data <- data |>
    filter(.data$placement == .env$selected_placement) |>
    mutate(site = factor(.data$site, levels = site_registry$site))
  present_sites <- site_registry$site[site_registry$site %in% unique(as.character(data$site))]
  colors <- stats::setNames(site_registry$color_hex, site_registry$site)
  x_limits <- range(
    c(
      photoperiod_bounds$minimum_possible_photoperiod_hours,
      photoperiod_bounds$maximum_possible_photoperiod_hours
    ),
    na.rm = TRUE
  )
  ggplot() +
    geom_ribbon(
      data = photoperiod_bounds,
      aes(
        y = .data$absolute_latitude_deg,
        xmin = 0,
        xmax = .data$minimum_possible_photoperiod_hours
      ),
      orientation = "y",
      fill = "black"
    ) +
    geom_ribbon(
      data = photoperiod_bounds,
      aes(
        y = .data$absolute_latitude_deg,
        xmin = .data$maximum_possible_photoperiod_hours,
        xmax = 24
      ),
      orientation = "y",
      fill = "black"
    ) +
    geom_point(
      data = data,
      aes(
        x = .data$photoperiod_hours,
        y = .data$plot_latitude_deg,
        colour = .data$site
      ),
      shape = 16,
      size = 1.05,
      alpha = 0.38
    ) +
    ggridges::geom_density_ridges(
      data = data,
      aes(
        x = .data$photoperiod_hours,
        y = .data$absolute_latitude_deg,
        fill = .data$site,
        colour = .data$site,
        group = .data$site
      ),
      scale = 2,
      position = position_nudge(y = 1),
      bandwidth = 0.15,
      alpha = 0.74,
      linewidth = 0.45,
      rel_min_height = 0.01,
      show.legend = TRUE,
      key_glyph = "rect"
    ) +
    annotate(
      "text",
      y = 3,
      x = 15.2,
      label = "possible photoperiods",
      colour = "white",
      hjust = 0,
      size = 3.8
    ) +
    annotate(
      "curve",
      y = 3,
      x = 15,
      xend = 13.3,
      yend = 5.1,
      curvature = -0.1,
      arrow = grid::arrow(
        type = "closed",
        length = grid::unit(0.2, "cm")
      ),
      colour = "white",
      linewidth = 0.55
    ) +
    scale_colour_manual(
      values = colors,
      breaks = present_sites,
      labels = site_registry$display_name[match(present_sites, site_registry$site)],
      name = "Site"
    ) +
    scale_fill_manual(
      values = colors,
      breaks = present_sites,
      labels = site_registry$display_name[match(present_sites, site_registry$site)],
      name = "Site"
    ) +
    guides(
      colour = "none",
      fill = guide_legend(override.aes = list(alpha = 1, colour = NA))
    ) +
    coord_cartesian(xlim = x_limits, ylim = c(0, 63), expand = FALSE) +
    labs(x = "Photoperiod (hr)", y = "Absolute latitude (°)") +
    cowplot::theme_cowplot(font_size = 10) +
    theme(
      legend.position = "inside",
      legend.position.inside = c(0.65, 0.40),
      legend.justification = c(0.5, 0.5),
      legend.background = element_rect(fill = "transparent", colour = NA),
      legend.key = element_rect(fill = "transparent", colour = NA),
      legend.title = element_blank(),
      legend.text = element_text(colour = "white", size = 8),
      axis.text = element_text(colour = "white"),
      axis.title = element_text(colour = "white"),
      axis.ticks = element_line(colour = "white"),
      axis.line = element_line(colour = "white"),
      plot.background = element_rect(fill = "black", colour = NA),
      panel.background = element_rect(fill = "black", colour = NA),
      plot.margin = margin(5.5, 5.5, 5.5, 5.5)
    )
}
photoperiod_near_plot <- make_photoperiod_plot(photoperiod_source, "glasses")
photoperiod_chest_plot <- make_photoperiod_plot(photoperiod_source, "chest")

make_paired_placement_panel <- function(data, scale_name) {
  panel_data <- data |>
    filter(.data$effect_scale == scale_name)
  axis_range <- range(
    c(
      panel_data$near_estimate_practical,
      panel_data$chest_estimate_practical,
      panel_data$null_value
    ),
    na.rm = TRUE
  )
  padding <- max(diff(axis_range) * 0.12, 0.02)
  axis_limits <- axis_range + c(-padding, padding)
  ggplot(
    panel_data,
    aes(
      x = .data$near_estimate_practical,
      y = .data$chest_estimate_practical
    )
  ) +
    geom_abline(
      intercept = 0,
      slope = 1,
      colour = "#555555",
      linewidth = 0.55,
      linetype = 2
    ) +
    geom_vline(
      xintercept = unique(panel_data$null_value),
      colour = "#111111",
      linewidth = 0.45,
      linetype = 3
    ) +
    geom_hline(
      yintercept = unique(panel_data$null_value),
      colour = "#111111",
      linewidth = 0.45,
      linetype = 3
    ) +
    geom_point(
      aes(colour = .data$predictor, shape = .data$predictor),
      size = 2.1
    ) +
    ggrepel::geom_text_repel(
      aes(label = .data$point_label, colour = .data$predictor),
      size = 3.1,
      seed = 20260801,
      min.segment.length = 0,
      box.padding = 0.55,
      point.padding = 0.32,
      force = 8,
      force_pull = 0.05,
      max.iter = 100000,
      max.time = 10,
      max.overlaps = Inf,
      show.legend = FALSE
    ) +
    scale_colour_manual(
      values = c(Photoperiod = "#117733", `Latitude per 10°` = "#332288")
    ) +
    scale_shape_manual(
      values = c(Photoperiod = 16, `Latitude per 10°` = 17)
    ) +
    coord_equal(xlim = axis_limits, ylim = axis_limits, expand = TRUE) +
    labs(
      title = scale_name,
      x = "Near-eye estimate",
      y = "Chest estimate",
      colour = NULL,
      shape = NULL
    ) +
    theme_minimal(base_size = 10.5) +
    theme(
      panel.grid.minor = element_blank(),
      plot.title = element_text(face = "bold"),
      legend.position = "bottom"
    )
}
paired_difference_plot <- make_paired_placement_panel(paired_placement, "Difference")
paired_ratio_plot <- make_paired_placement_panel(paired_placement, "Ratio")
paired_placement_plot <- cowplot::plot_grid(
  paired_difference_plot,
  paired_ratio_plot,
  nrow = 1,
  align = "hv",
  axis = "tblr",
  rel_widths = c(1, 1)
)

figure_specs <- list(
  H01_stage3_model_support = list(plot = support_plot, width = 10.5, height = 7.4, bg = "white"),
  H01_stage3_site_contrasts_near_eye = list(plot = contrast_near_plot, width = 11.5, height = 14.5, bg = "white"),
  H01_stage3_site_contrasts_chest = list(plot = contrast_chest_plot, width = 11.5, height = 21.0, bg = "white"),
  H01_stage3_r2_intervals = list(plot = r2_plot, width = 10.5, height = 8.0, bg = "white"),
  H01_stage3_diagnostic_assessment = list(plot = diagnostic_plot, width = 11.5, height = 7.6, bg = "white"),
  H01_stage3_paired_placement = list(plot = paired_placement_plot, width = 12, height = 6.8, bg = "white"),
  H01_stage3_photoperiod_latitude_near_eye = list(plot = photoperiod_near_plot, width = 6, height = 6, bg = "black"),
  H01_stage3_photoperiod_latitude_chest = list(plot = photoperiod_chest_plot, width = 6, height = 6, bg = "black")
)
figure_paths <- density_figure_paths
for (name in names(figure_specs)) {
  spec <- figure_specs[[name]]
  png_path <- file.path(figure_root, paste0(name, ".png"))
  svg_path <- file.path(figure_root, paste0(name, ".svg"))
  ggsave(
    png_path,
    spec$plot,
    width = spec$width,
    height = spec$height,
    units = "in",
    dpi = 320,
    bg = spec$bg
  )
  ggsave(
    svg_path,
    spec$plot,
    width = spec$width,
    height = spec$height,
    units = "in",
    bg = spec$bg
  )
  figure_paths <- c(figure_paths, png_path, svg_path)
}

provenance <- tibble::tibble(
  stage = "standalone_reader_facing_results",
  computation_mode = "read_verified_stored_outputs_only",
  model_refit = FALSE,
  prediction_rerun = FALSE,
  bootstrap_rerun = FALSE,
  r_version = as.character(getRversion()),
  ggplot2_version = as.character(utils::packageVersion("ggplot2")),
  ggridges_version = as.character(utils::packageVersion("ggridges")),
  ggrepel_version = as.character(utils::packageVersion("ggrepel")),
  cowplot_version = as.character(utils::packageVersion("cowplot")),
  gt_version = as.character(utils::packageVersion("gt")),
  main_model_data_manifest_sha256 = artifact_sha256(file.path(
    root,
    "artifacts/12_manifests/H01_model_data_artifacts.csv"
  )),
  manuscript_prepared_manifest_sha256 = artifact_sha256(file.path(
    root,
    "artifacts/12_manifests/H01_manuscript_prepared_data_artifacts.csv"
  )),
  model_results_manifest_sha256 = artifact_sha256(file.path(
    root,
    "artifacts/12_manifests/H01_model_results_artifacts.csv"
  )),
  production_bootstrap_manifest_sha256 = artifact_sha256(file.path(
    root,
    "artifacts/12_manifests/H01_response_family_bootstrap_production_artifacts.csv"
  )),
  mder_decision_sha256 = artifact_sha256(file.path(
    root,
    "audit/decisions/mder_mean_of_viable_ratios.md"
  )),
  mder_production_manifest_sha256 = artifact_sha256(file.path(
    root,
    paste0(
      "audit/hypotheses/H01/mder_METRIC-010/bootstrap_production/",
      "H01_METRIC-010_bootstrap_production_manifest.csv"
    )
  )),
  mder_integration_summary_sha256 = artifact_sha256(file.path(
    root,
    paste0(
      "audit/hypotheses/H01/mder_METRIC-010/production_integration/",
      "H01_METRIC-010_production_integration_summary.csv"
    )
  )),
  stage2_archive_manifest_sha256 = artifact_sha256(file.path(
    root,
    paste0(
      "audit/hypotheses/H01/",
      "02_implementation_and_v0_comparison_archive_manifest.csv"
    )
  )),
  bootstrap_targets_verified = nrow(bootstrap_audit),
  minimum_successful_refits = min(bootstrap_audit$used_refits),
  producer = producer,
  completed_utc = format(Sys.time(), tz = "UTC", usetz = TRUE)
)
provenance_path <- file.path(
  diagnostic_root,
  "H01_stage3_reporting_provenance.csv"
)
write_csv_artifact(provenance, provenance_path, producer = producer)

input_paths <- c(
  file.path(
    root,
    c(
      "artifacts/06_model_data/H01.rds",
      "artifacts/06_model_data/H01/metric_contract.csv",
      "artifacts/08_diagnostics/H01/H01_model_diagnostics.csv",
      "artifacts/08_diagnostics/H01/H01_r2_bootstrap_audit.csv",
      "artifacts/08_diagnostics/H01/H01_participant_influence.csv",
      "artifacts/08_diagnostics/H01/H01_latitude_leave_one_site_out.csv",
      "artifacts/09_tables/H01/H01_model_level_tests.csv",
      "artifacts/09_tables/H01/H01_term_effects.csv",
      "artifacts/09_tables/H01/H01_site_deviations.csv",
      "artifacts/09_tables/H01/H01_exact_samples.csv",
      "artifacts/09_tables/H01/H01_exact_samples_by_site.csv",
      "artifacts/09_tables/H01/H01_r2_bootstrap_summaries.csv",
      "artifacts/09_tables/H01/H01_model_manifest.csv",
      "artifacts/09_tables/H01/H01_l10_noon_conversion_model_tests.csv",
      "artifacts/09_tables/H01/H01_l10_noon_conversion_term_effects.csv",
      "artifacts/09_tables/H01/H01_l10_noon_conversion_samples.csv",
      "artifacts/09_tables/H01/H01_exactly_identified_period_sensitivity.csv",
      "artifacts/09_tables/H01/H01_preregistered_scope_sensitivity.csv",
      "artifacts/09_tables/H01/H01_marginalization_comparison.csv",
      "artifacts/09_tables/descriptives/metric_descriptive_summary_replica.csv",
      "artifacts/11_source_data/descriptives/metric_plot_values.csv",
      "artifacts/11_source_data/descriptives/latitude_photoperiod.csv",
      "artifacts/11_source_data/H01/reporting/H01_figure_s10_theoretical_bounds_source.csv",
      "config/site_display_registry.csv",
      "audit/decisions/mder_mean_of_viable_ratios.md",
      paste0(
        "audit/hypotheses/H01/mder_METRIC-010/bootstrap_production/",
        "H01_METRIC-010_bootstrap_production_manifest.csv"
      ),
      paste0(
        "audit/hypotheses/H01/mder_METRIC-010/production_integration/",
        "H01_METRIC-010_production_integration_summary.csv"
      ),
      "audit/hypotheses/H01/02_implementation_and_v0_comparison_archive_manifest.csv",
      producer
    )
  ),
  representative_diagnostic_paths,
  representative_diagnostic_source_paths
)
all_manifest_files <- sort(unique(c(
  table_paths,
  source_paths,
  figure_paths,
  provenance_path,
  input_paths
)))
manifest <- bind_rows(lapply(all_manifest_files, function(path) {
  artifact_path <- path
  relative_path <- substring(artifact_path, nchar(root) + 2L)
  is_reporting_output <- artifact_path %in% c(
    table_paths,
    source_paths,
    figure_paths,
    provenance_path
  )
  tibble::tibble(
    path = relative_path,
    sha256 = artifact_sha256(artifact_path),
    bytes = as.numeric(file.info(artifact_path)$size),
    role = if_else(
      is_reporting_output,
      "H01 Stage 3 reporting output",
      "H01 Stage 3 reporting input"
    ),
    producer = producer,
    r_version = as.character(getRversion())
  )
}))
write_csv_artifact(manifest, manifest_path, producer = producer)

message(
  "Built H01 Stage 3 reporting inputs: ",
  nrow(model_results),
  " primary/complementary model rows, ",
  nrow(site_contrasts),
  " supported site contrasts, and ",
  nrow(exact_samples),
  " exact fitted-sample rows"
)
