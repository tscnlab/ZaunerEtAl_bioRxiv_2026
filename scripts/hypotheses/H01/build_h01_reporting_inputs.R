# Build audited, reader-facing H01 reporting inputs and figure source data.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
source(file.path(root, "scripts/pipeline/paths_io.R"))
source(file.path(root, "scripts/hypotheses/H01/h01_contract.R"))

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("H01 reporting inputs require R 4.6.1", call. = FALSE)
}

producer <- "scripts/hypotheses/H01/build_h01_reporting_inputs.R"
primary_run <- "main__glasses__all_available"
manuscript_run <-
  "manuscript_prepared_data__glasses__all_available"
pilot_label <- "PILOT — NOT FOR INFERENCE OR MANUSCRIPT REPORTING"

read_csv_required <- function(relative_path) {
  path <- file.path(root, relative_path)
  if (!file.exists(path)) {
    stop("Missing required H01 input: ", relative_path, call. = FALSE)
  }
  readr::read_csv(path, show_col_types = FALSE, progress = FALSE)
}

format_family <- function(response_family, response_transform) {
  dplyr::case_when(
    response_family == "tweedie_log" ~ "Tweedie, log link",
    response_transform == "log10_offset_0.1" ~
      "Gaussian, log10(value + 0.1)",
    response_transform == "logit" ~ "Gaussian, logit scale",
    response_transform == "clock_hours_midnight_after_16" ~
      "Gaussian, linear clock scale (strict after 16:00 cut)",
    response_transform == "clock_hours" ~
      "Gaussian, linear clock scale",
    TRUE ~ "Gaussian, identity scale"
  )
}

parse_percent <- function(value) {
  value <- trimws(as.character(value))
  output <- rep(NA_real_, length(value))
  keep <- grepl("%$", value)
  output[keep] <- as.numeric(sub("%$", "", value[keep])) / 100
  output
}

site_registry <- read_csv_required("config/site_display_registry.csv") |>
  dplyr::arrange(.data$display_order)
metric_contract <- read_csv_required(
  "artifacts/06_model_data/H01/metric_contract.csv"
) |>
  dplyr::select(
    .data$metric_order,
    .data$metric_id,
    .data$manuscript_name,
    .data$abbreviation,
    .data$manuscript_category,
    .data$display_unit,
    .data$variant_label
  )
metric_registry <- h01_metric_registry() |>
  dplyr::left_join(
    metric_contract,
    by = c("metric_order", "metric_id"),
    relationship = "one-to-one"
  ) |>
  dplyr::mutate(
    family_label = format_family(
      .data$response_family,
      .data$response_transform
    )
  )
if (nrow(metric_registry) != 17L || anyNA(metric_registry$manuscript_name)) {
  stop("The H01 reporting metric registry is incomplete", call. = FALSE)
}

tests <- read_csv_required(
  "artifacts/09_tables/H01/H01_model_level_tests.csv"
)
term_effects <- read_csv_required(
  "artifacts/09_tables/H01/H01_term_effects.csv"
)
site_estimates <- read_csv_required(
  "artifacts/09_tables/H01/H01_site_estimates.csv"
)
site_deviations <- read_csv_required(
  "artifacts/09_tables/H01/H01_site_deviations.csv"
)
samples <- read_csv_required(
  "artifacts/09_tables/H01/H01_exact_samples.csv"
)
diagnostics <- read_csv_required(
  "artifacts/08_diagnostics/H01/H01_model_diagnostics.csv"
)
r2_production <- read_csv_required(
  "artifacts/09_tables/H01/H01_r2_bootstrap_summaries.csv"
)
r2_pilot <- read_csv_required(paste0(
  "artifacts/09_tables/H01/bootstrap_pilot/response_family_change/",
  "H01_response_family_bootstrap_pilot_r2_summaries.csv"
))
pilot_audit <- read_csv_required(paste0(
  "artifacts/08_diagnostics/H01/bootstrap_pilot/response_family_change/",
  "H01_response_family_bootstrap_pilot_audit.csv"
))
pilot_runtime <- read_csv_required(paste0(
  "artifacts/08_diagnostics/H01/bootstrap_pilot/response_family_change/",
  "H01_response_family_bootstrap_pilot_runtime.csv"
))
candidate_selection <- read_csv_required(paste0(
  "artifacts/09_tables/H01/response_family_candidates/",
  "H01_response_family_candidate_selection.csv"
))
candidate_scorecard <- read_csv_required(paste0(
  "artifacts/09_tables/H01/response_family_candidates/",
  "H01_response_family_candidate_scorecard.csv"
))
v0_model <- read_csv_required(
  "artifacts/09_tables/H01/v0/H01_v0_model_results.csv"
)
v0_samples <- read_csv_required(
  "artifacts/09_tables/H01/v0/H01_v0_exact_samples.csv"
)

primary_tests <- tests |>
  dplyr::filter(.data$run_id == primary_run) |>
  dplyr::mutate(
    test_id = dplyr::recode(
      .data$family_id,
      `H01-F1-site` = "site",
      `H01-F2-photoperiod` = "photoperiod",
      `H01-F3-latitude` = "latitude",
      `H01-F4-site-latitude-adequacy` = "adequacy"
    )
  )
if (
  nrow(primary_tests) != 68L ||
    any(primary_tests$family_status != "COMPLETE") ||
    any(primary_tests$family_n != 17L)
) {
  stop("The four primary 17-test H01 families are incomplete", call. = FALSE)
}

test_wide <- primary_tests |>
  dplyr::select(
    .data$metric_order,
    .data$metric_id,
    .data$test_id,
    .data$p_raw,
    .data$p_adjusted,
    .data$comparison_status
  ) |>
  tidyr::pivot_wider(
    names_from = .data$test_id,
    values_from = c(
      .data$p_raw,
      .data$p_adjusted,
      .data$comparison_status
    ),
    names_glue = "{test_id}_{.value}"
  )

effect_wide <- term_effects |>
  dplyr::filter(.data$run_id == primary_run) |>
  dplyr::mutate(
    effect_id = dplyr::case_when(
      .data$term == "photoperiod_centered_hours" ~ "photoperiod",
      .data$term == "absolute_latitude_10deg_centered" ~ "latitude",
      TRUE ~ NA_character_
    )
  ) |>
  dplyr::filter(!is.na(.data$effect_id)) |>
  dplyr::select(
    .data$metric_order,
    .data$metric_id,
    .data$effect_id,
    .data$effect_type,
    .data$estimate_practical,
    .data$conf_low_practical,
    .data$conf_high_practical,
    .data$status
  ) |>
  tidyr::pivot_wider(
    names_from = .data$effect_id,
    values_from = c(
      .data$effect_type,
      .data$estimate_practical,
      .data$conf_low_practical,
      .data$conf_high_practical,
      .data$status
    ),
    names_glue = "{effect_id}_{.value}"
  )

overall_means <- site_estimates |>
  dplyr::filter(
    .data$run_id == primary_run,
    .data$estimand == "overall_equal_site_mean"
  ) |>
  dplyr::select(
    .data$metric_order,
    .data$metric_id,
    overall_estimate = .data$estimate_practical,
    overall_conf_low = .data$conf_low_practical,
    overall_conf_high = .data$conf_high_practical,
    overall_interval_method = .data$interval_method
  )

primary_samples <- samples |>
  dplyr::filter(.data$run_id == primary_run) |>
  dplyr::select(
    .data$metric_order,
    .data$metric_id,
    .data$participants,
    .data$participant_days,
    .data$observations,
    .data$sites,
    .data$derivation_support_hours,
    .data$derivation_support_status
  )

primary_diagnostics <- diagnostics |>
  dplyr::filter(.data$run_id == primary_run) |>
  dplyr::select(
    .data$metric_order,
    .data$metric_id,
    .data$converged,
    .data$positive_definite_hessian,
    .data$singular,
    .data$residual_status,
    .data$prediction_bound_status,
    .data$audit_threshold_status,
    .data$observed_above_audit_threshold_n,
    .data$predicted_above_audit_threshold_n,
    .data$diagnostic_status
  )

v0_primary <- v0_model |>
  dplyr::filter(.data$placement == "glasses") |>
  dplyr::mutate(
    submitted_metric_id = .data$metric_id,
    metric_id = dplyr::if_else(
      .data$metric_order == 17L &
        .data$metric_id == "mder_ratio_of_integrals",
      "mder_mean_of_viable_ratios",
      .data$metric_id
    )
  ) |>
  dplyr::select(
    .data$metric_order,
    .data$metric_id,
    .data$submitted_metric_id,
    .data$family_v0,
    .data$response_v0,
    .data$site_p_adjusted_v0,
    .data$photoperiod_p_adjusted_v0,
    .data$latitude_p_adjusted_v0,
    .data$site_supported_v0,
    .data$photoperiod_supported_v0,
    .data$latitude_supported_v0,
    .data$overall_estimate_v0,
    .data$photoperiod_effect_v0,
    .data$latitude_effect_per_10deg_v0
  )

model_overview <- metric_registry |>
  dplyr::select(
    .data$metric_order,
    .data$metric_id,
    .data$manuscript_name,
    .data$manuscript_category,
    .data$display_unit,
    .data$family_label,
    .data$effect_scale
  ) |>
  dplyr::left_join(
    test_wide,
    by = c("metric_order", "metric_id"),
    relationship = "one-to-one"
  ) |>
  dplyr::left_join(
    effect_wide,
    by = c("metric_order", "metric_id"),
    relationship = "one-to-one"
  ) |>
  dplyr::left_join(
    overall_means,
    by = c("metric_order", "metric_id"),
    relationship = "one-to-one"
  ) |>
  dplyr::left_join(
    primary_samples,
    by = c("metric_order", "metric_id"),
    relationship = "one-to-one"
  ) |>
  dplyr::left_join(
    primary_diagnostics,
    by = c("metric_order", "metric_id"),
    relationship = "one-to-one"
  ) |>
  dplyr::left_join(
    v0_primary,
    by = c("metric_order", "metric_id"),
    relationship = "one-to-one"
  ) |>
  dplyr::arrange(.data$metric_order)
if (nrow(model_overview) != 17L || anyNA(model_overview$site_p_adjusted)) {
  stop("The primary H01 model overview is incomplete", call. = FALSE)
}

site_followups <- site_deviations |>
  dplyr::filter(
    .data$run_id == primary_run,
    .data$inferential_followup_supported
  ) |>
  dplyr::left_join(
    metric_contract,
    by = c("metric_order", "metric_id"),
    relationship = "many-to-one"
  ) |>
  dplyr::left_join(
    site_registry,
    by = "site",
    relationship = "many-to-one"
  ) |>
  dplyr::arrange(.data$metric_order, .data$display_order) |>
  dplyr::select(
    .data$metric_order,
    .data$metric_id,
    .data$manuscript_name,
    .data$manuscript_category,
    .data$display_unit,
    .data$site,
    .data$display_order,
    site_display_name = .data$display_name,
    site_color = .data$color_hex,
    .data$effect_type,
    .data$estimate_practical,
    .data$conf_low_practical,
    .data$conf_high_practical,
    .data$p_raw,
    .data$p_adjusted_within_metric,
    .data$contrast_family_n,
    .data$overall_site_p_adjusted,
    .data$interval_method
  )
supported_site_metrics <- primary_tests |>
  dplyr::filter(.data$test_id == "site", .data$p_adjusted < 0.05) |>
  dplyr::pull(.data$metric_id)
if (
  nrow(site_followups) != 9L * length(supported_site_metrics) ||
    any(site_followups$contrast_family_n != 9L) ||
    !setequal(unique(site_followups$metric_id), supported_site_metrics)
) {
  stop("The hierarchical H01 site follow-up table is incomplete", call. = FALSE)
}

exact_samples <- samples |>
  dplyr::filter(.data$run_id %in% c(primary_run, manuscript_run)) |>
  dplyr::mutate(
    data_scenario = dplyr::if_else(
      .data$run_id == primary_run,
      "Main data",
      "Manuscript-prepared data"
    ),
    support_hours_available =
      .data$derivation_support_status == "available"
  ) |>
  dplyr::left_join(
    metric_contract,
    by = c("metric_order", "metric_id"),
    relationship = "many-to-one"
  ) |>
  dplyr::arrange(.data$metric_order, .data$data_scenario_id) |>
  dplyr::select(
    .data$data_scenario,
    .data$data_scenario_id,
    .data$metric_order,
    .data$metric_id,
    .data$manuscript_name,
    .data$analysis_unit,
    .data$response_family,
    .data$response_transform,
    .data$participants,
    .data$participant_days,
    .data$observations,
    .data$sites,
    .data$derivation_support_hours,
    .data$derivation_support_status,
    .data$derivation_support_unavailability_reason,
    .data$sample_status
  )
if (
  nrow(exact_samples) != 34L ||
    any(
      exact_samples$data_scenario_id == "manuscript_prepared_data" &
        exact_samples$derivation_support_status != "unavailable"
    )
) {
  stop("The exact H01 sample table violates its reporting contract", call. = FALSE)
}

primary_production_r2 <- r2_production |>
  dplyr::filter(
    .data$run_id == primary_run,
    .data$approximation == "lognormal"
  )
changed_metric_has_production_r2 <- any(
  primary_production_r2$metric_id == "duration_below_10_pre_sleep" &
    primary_production_r2$bootstrap_successful_used >= 1000L &
    primary_production_r2$status %in% c("PASS", "NON_ESTIMABLE")
)
primary_production_r2 <- primary_production_r2 |>
  dplyr::mutate(
    evidence_status =
      "PRODUCTION — 1,000 successful joint bootstrap refits",
    preview_only = FALSE
  )
primary_pilot_r2 <- if (changed_metric_has_production_r2) {
  r2_pilot[0, ] |>
    dplyr::mutate(
      evidence_status = character(),
      preview_only = logical()
    )
} else {
  r2_pilot |>
    dplyr::filter(
      .data$run_id == primary_run,
      .data$approximation == "lognormal"
    ) |>
    dplyr::mutate(
      evidence_status = .data$inference_status,
      preview_only = TRUE
    )
}
r2_preview_long <- dplyr::bind_rows(
  primary_production_r2,
  primary_pilot_r2
) |>
  dplyr::left_join(
    metric_contract,
    by = c("metric_order", "metric_id"),
    relationship = "many-to-one"
  ) |>
  dplyr::arrange(.data$metric_order, .data$measure)
if (
  nrow(r2_preview_long) != 136L ||
    dplyr::n_distinct(r2_preview_long$metric_id) != 17L ||
    any(!r2_preview_long$status %in% c("PASS", "NON_ESTIMABLE")) ||
    any(
      r2_preview_long$status == "NON_ESTIMABLE" &
        (
          r2_preview_long$measure != "participant_associated_share" |
            r2_preview_long$analysis_unit != "participant" |
            is.finite(r2_preview_long$estimate)
        )
    ) ||
    any(
      r2_preview_long$metric_id == "duration_below_10_pre_sleep" &
        r2_preview_long$bootstrap_successful_used !=
          if (changed_metric_has_production_r2) 1000L else 50L
    ) ||
    any(
      r2_preview_long$metric_id != "duration_below_10_pre_sleep" &
        r2_preview_long$bootstrap_successful_used < 1000L
    )
) {
  stop("The mixed production/pilot H01 R2 preview is incomplete", call. = FALSE)
}

r2_table_measures <- c(
  "conditional_r2",
  "marginal_r2",
  "site_part_r2",
  "photoperiod_part_r2",
  "latitude_part_r2",
  "participant_associated_share",
  "unrepresented_share"
)
r2_preview_wide <- r2_preview_long |>
  dplyr::filter(.data$measure %in% r2_table_measures) |>
  dplyr::select(
    .data$metric_order,
    .data$metric_id,
    .data$manuscript_name,
    .data$manuscript_category,
    .data$evidence_status,
    .data$preview_only,
    .data$measure,
    .data$estimate,
    .data$conf_low,
    .data$conf_high,
    .data$bootstrap_successful_used
  ) |>
  tidyr::pivot_wider(
    names_from = .data$measure,
    values_from = c(
      .data$estimate,
      .data$conf_low,
      .data$conf_high,
      .data$bootstrap_successful_used
    ),
    names_glue = "{measure}_{.value}"
  ) |>
  dplyr::arrange(.data$metric_order)

r2_grand <- r2_preview_long |>
  dplyr::filter(.data$measure %in% r2_table_measures) |>
  dplyr::group_by(.data$measure) |>
  dplyr::summarise(
    estimate = mean(.data$estimate, na.rm = TRUE),
    .groups = "drop"
  ) |>
  tidyr::pivot_wider(
    names_from = .data$measure,
    values_from = .data$estimate,
    names_glue = "{measure}_estimate"
  ) |>
  dplyr::mutate(
    metric_order = 0L,
    metric_id = "grand_average",
    manuscript_name = "Grand average",
    manuscript_category = "Grand average",
    evidence_status = dplyr::if_else(
      changed_metric_has_production_r2,
      paste(
        "DESCRIPTIVE MEAN — all component models have 1,000 successful",
        "joint bootstrap refits; no interval is claimed for this mean"
      ),
      paste(
        "PREVIEW ONLY — descriptive mean includes the 50-refit pilot row;",
        "no confidence interval is claimed"
      )
    ),
    preview_only = !changed_metric_has_production_r2
  )
for (measure in r2_table_measures) {
  r2_grand[[paste0(measure, "_conf_low")]] <- NA_real_
  r2_grand[[paste0(measure, "_conf_high")]] <- NA_real_
  r2_grand[[paste0(measure, "_bootstrap_successful_used")]] <- NA_real_
}
r2_preview_wide <- dplyr::bind_rows(r2_grand, r2_preview_wide) |>
  dplyr::arrange(.data$metric_order)

v0_name_map <- tibble::tribble(
  ~metric_order, ~metric_id, ~v0_rendered_name,
  1L, "interdaily_stability", "Interdaily stability",
  2L, "intradaily_variability", "Intradaily variability",
  3L, "daily_geometric_mean_medi", "Mean",
  4L, "m10_mean_medi", "Brightest 10h mean",
  5L, "l10_mean_medi", "Darkest 10h mean",
  6L, "duration_above_1000", "Duration above 1000",
  7L, "duration_above_250_wake", "Duration above 250 wake",
  8L, "duration_below_10_pre_sleep", "Duration below 10 pre-sleep",
  9L, "duration_below_1_sleep_environment", "Duration below 1 sleep",
  10L, "longest_bout_above_250", "Period above 250",
  11L, "m10_midpoint", "Brightest 10h midpoint",
  12L, "l10_midpoint", "Darkest 10h midpoint",
  13L, "mean_timing_above_250", "Mean timing above 250",
  14L, "first_timing_above_250", "First timing above 250",
  15L, "last_timing_above_250", "Last timing above 250",
  16L, "dose_time_sensitive_corrected_medi", "Dose",
  17L, "mder_mean_of_viable_ratios", "MDER"
)

v0_html_path <- file.path(root, "docs/RQ1.html")
v0_tables <- rvest::html_table(
  rvest::html_elements(rvest::read_html(v0_html_path), "table"),
  fill = TRUE
)
if (length(v0_tables) < 4L) {
  stop("The submitted H01 HTML does not contain Tables S2 and S3", call. = FALSE)
}

v0_s2_raw <- v0_tables[[3L]]
v0_s2 <- v0_s2_raw |>
  dplyr::filter(.data$X1 %in% v0_name_map$v0_rendered_name) |>
  dplyr::left_join(
    v0_name_map,
    by = c("X1" = "v0_rendered_name"),
    relationship = "one-to-one"
  ) |>
  dplyr::transmute(
    .data$metric_order,
    .data$metric_id,
    submitted_metric_label = .data$X1,
    submitted_effect_scale = .data$X2,
    submitted_site_q = .data$X3,
    submitted_overall = .data$X4,
    `Borås (SE)` = .data$X5,
    `Delft (NL)` = .data$X6,
    `Dortmund (DE)` = .data$X7,
    `Tübingen (DE)` = .data$X8,
    `Munich (DE)` = .data$X9,
    `Madrid (ES)` = .data$X10,
    `Izmir (TR)` = .data$X11,
    `San José (CR)` = .data$X12,
    `Kumasi (GH)` = .data$X13,
    submitted_photoperiod = .data$X14,
    submitted_participant_sd = .data$X15,
    submitted_residual_sd = .data$X16,
    submitted_latitude = .data$X17,
    submitted_site_sd = .data$X18,
    source = "Exact rendered strings from docs/RQ1.html, table 3"
  ) |>
  dplyr::arrange(.data$metric_order)
if (nrow(v0_s2) != 17L) {
  stop("Exact submitted Table S2 extraction is incomplete", call. = FALSE)
}

v0_s3_raw <- v0_tables[[4L]]
v0_s3_metrics <- v0_s3_raw |>
  dplyr::filter(.data$X1 %in% v0_name_map$v0_rendered_name) |>
  dplyr::left_join(
    v0_name_map,
    by = c("X1" = "v0_rendered_name"),
    relationship = "one-to-one"
  ) |>
  dplyr::transmute(
    .data$metric_order,
    .data$metric_id,
    submitted_metric_label = .data$X1,
    conditional_r2 = parse_percent(.data$X2),
    marginal_r2 = parse_percent(.data$X3),
    site_part_r2 = parse_percent(.data$X4),
    photoperiod_part_r2 = parse_percent(.data$X5),
    latitude_part_r2 = parse_percent(.data$X6),
    participant_associated_share = parse_percent(.data$X7),
    unrepresented_share = parse_percent(.data$X8),
    source = "Exact rendered percentages from docs/RQ1.html, table 4"
  ) |>
  dplyr::arrange(.data$metric_order)
v0_s3_grand <- v0_s3_raw |>
  dplyr::filter(.data$X1 == "Grand average") |>
  dplyr::transmute(
    metric_order = 0L,
    metric_id = "grand_average",
    submitted_metric_label = .data$X1,
    conditional_r2 = parse_percent(.data$X2),
    marginal_r2 = parse_percent(.data$X3),
    site_part_r2 = parse_percent(.data$X4),
    photoperiod_part_r2 = parse_percent(.data$X5),
    latitude_part_r2 = parse_percent(.data$X6),
    participant_associated_share = parse_percent(.data$X7),
    unrepresented_share = parse_percent(.data$X8),
    source = "Exact rendered percentages from docs/RQ1.html, table 4"
  )
v0_s3 <- dplyr::bind_rows(v0_s3_grand, v0_s3_metrics)
if (nrow(v0_s3) != 18L) {
  stop("Exact submitted Table S3 extraction is incomplete", call. = FALSE)
}

v0_new_tests <- primary_tests |>
  dplyr::filter(.data$test_id %in% c("site", "photoperiod", "latitude")) |>
  dplyr::select(
    .data$metric_order,
    .data$metric_id,
    question = .data$test_id,
    current_p_raw = .data$p_raw,
    current_p_adjusted = .data$p_adjusted
  ) |>
  dplyr::left_join(
    v0_primary,
    by = c("metric_order", "metric_id"),
    relationship = "many-to-one"
  ) |>
  dplyr::mutate(
    submitted_p_adjusted = dplyr::case_when(
      .data$question == "site" ~ .data$site_p_adjusted_v0,
      .data$question == "photoperiod" ~
        .data$photoperiod_p_adjusted_v0,
      .data$question == "latitude" ~ .data$latitude_p_adjusted_v0,
      TRUE ~ NA_real_
    ),
    current_supported = is.finite(.data$current_p_adjusted) &
      .data$current_p_adjusted < 0.05,
    submitted_supported = is.finite(.data$submitted_p_adjusted) &
      .data$submitted_p_adjusted < 0.05,
    support_comparison = dplyr::case_when(
      .data$current_supported & .data$submitted_supported ~
        "Supported in both",
      .data$current_supported & !.data$submitted_supported ~
        "Supported only in audited analysis",
      !.data$current_supported & .data$submitted_supported ~
        "Supported only in submitted analysis",
      TRUE ~ "Unsupported in both"
    )
  ) |>
  dplyr::left_join(
    metric_contract,
    by = c("metric_order", "metric_id"),
    relationship = "many-to-one"
  ) |>
  dplyr::select(
    .data$metric_order,
    .data$metric_id,
    .data$manuscript_name,
    .data$manuscript_category,
    .data$question,
    .data$current_p_raw,
    .data$current_p_adjusted,
    .data$submitted_p_adjusted,
    .data$current_supported,
    .data$submitted_supported,
    .data$support_comparison
  ) |>
  dplyr::arrange(.data$question, .data$metric_order)

v0_r2_long <- v0_s3 |>
  dplyr::filter(.data$metric_id != "grand_average") |>
  tidyr::pivot_longer(
    cols = dplyr::all_of(r2_table_measures),
    names_to = "measure",
    values_to = "submitted_estimate"
  )
v0_new_r2 <- r2_preview_long |>
  dplyr::filter(.data$measure %in% r2_table_measures) |>
  dplyr::select(
    .data$metric_order,
    .data$metric_id,
    .data$manuscript_name,
    .data$manuscript_category,
    .data$measure,
    current_estimate = .data$estimate,
    current_conf_low = .data$conf_low,
    current_conf_high = .data$conf_high,
    current_bootstrap_refits = .data$bootstrap_successful_used,
    .data$evidence_status,
    .data$preview_only
  ) |>
  dplyr::left_join(
    v0_r2_long,
    by = c("metric_order", "metric_id", "measure"),
    relationship = "one-to-one"
  ) |>
  dplyr::mutate(
    difference_current_minus_submitted =
      .data$current_estimate - .data$submitted_estimate
  ) |>
  dplyr::arrange(.data$metric_order, .data$measure)

scenario_support <- tests |>
  dplyr::mutate(
    supported = is.finite(.data$p_adjusted) & .data$p_adjusted < 0.05,
    run_label = dplyr::case_when(
      .data$run_id == primary_run ~ "Main near-eye — primary",
      .data$run_id == "main__glasses__paired_common_sample" ~
        "Main near-eye — paired/common sample",
      .data$run_id == "main__chest__all_available" ~
        "Main chest — complementary",
      .data$run_id == "main__chest__paired_common_sample" ~
        "Main chest — paired/common sample",
      .data$run_id == manuscript_run ~
        "Manuscript-prepared near-eye — sensitivity",
      .data$run_id ==
        "manuscript_prepared_data__glasses__paired_common_sample" ~
        "Manuscript-prepared near-eye — paired/common sample",
      .data$run_id ==
        "manuscript_prepared_data__chest__all_available" ~
        "Manuscript-prepared chest — complementary",
      .data$run_id ==
        "manuscript_prepared_data__chest__paired_common_sample" ~
        "Manuscript-prepared chest — paired/common sample",
      TRUE ~ .data$run_id
    )
  ) |>
  dplyr::group_by(
    .data$run_id,
    .data$run_label,
    .data$data_scenario_id,
    .data$placement,
    .data$sample_scenario,
    .data$analytical_role,
    .data$family_order,
    .data$family_id,
    .data$family_label
  ) |>
  dplyr::summarise(
    tests = dplyr::n(),
    supported_metrics = sum(.data$supported),
    nonestimable_metrics = sum(!is.finite(.data$p_adjusted)),
    family_status = paste(sort(unique(.data$family_status)), collapse = ";"),
    .groups = "drop"
  ) |>
  dplyr::arrange(.data$run_label, .data$family_order)

claim_summary <- v0_new_tests |>
  dplyr::group_by(.data$question) |>
  dplyr::summarise(
    submitted_supported_n = sum(.data$submitted_supported),
    current_supported_n = sum(.data$current_supported),
    retained_supported_metrics = paste(
      .data$manuscript_name[
        .data$submitted_supported & .data$current_supported
      ],
      collapse = "; "
    ),
    newly_supported_metrics = paste(
      .data$manuscript_name[
        !.data$submitted_supported & .data$current_supported
      ],
      collapse = "; "
    ),
    no_longer_supported_metrics = paste(
      .data$manuscript_name[
        .data$submitted_supported & !.data$current_supported
      ],
      collapse = "; "
    ),
    .groups = "drop"
  ) |>
  dplyr::mutate(
    question_label = dplyr::recode(
      .data$question,
      site = "Overall site",
      photoperiod = "Photoperiod",
      latitude = "Latitude"
    ),
    newly_supported_metrics = dplyr::if_else(
      .data$newly_supported_metrics == "",
      "None",
      .data$newly_supported_metrics
    ),
    no_longer_supported_metrics = dplyr::if_else(
      .data$no_longer_supported_metrics == "",
      "None",
      .data$no_longer_supported_metrics
    )
  ) |>
  dplyr::select(
    .data$question,
    .data$question_label,
    .data$submitted_supported_n,
    .data$current_supported_n,
    .data$retained_supported_metrics,
    .data$newly_supported_metrics,
    .data$no_longer_supported_metrics
  )

pilot_summary <- pilot_audit |>
  dplyr::summarise(
    inference_status = paste(unique(.data$inference_status), collapse = ";"),
    targets = dplyr::n(),
    attempted_refits = sum(.data$attempted_refits),
    successful_refits = sum(.data$successful_refits),
    retained_refits = sum(.data$used_refits),
    failed_refits = sum(.data$failed_refits),
    warning_refits = sum(.data$warning_refits),
    minimum_successful_per_target = min(.data$used_refits),
    maximum_successful_per_target = max(.data$used_refits),
    all_status_pass = all(.data$status == "PASS"),
    requested_parallel_workers = max(
      pilot_runtime$requested_parallel_workers
    ),
    total_wall_seconds = sum(pilot_runtime$wall_seconds),
    projected_production_minutes_point =
      sum(pilot_runtime$wall_seconds) * 1000 / 50 / 60,
    projected_production_minutes_low =
      sum(pilot_runtime$wall_seconds) * 1000 / 50 / 60 * 0.9,
    projected_production_minutes_high =
      sum(pilot_runtime$wall_seconds) * 1000 / 50 / 60 * 1.5,
    checkpoint_status = paste(
      sort(unique(pilot_runtime$checkpoint_status)),
      collapse = ";"
    )
  )
if (
  pilot_summary$targets != 8L ||
    pilot_summary$minimum_successful_per_target != 50L ||
    !pilot_summary$all_status_pass ||
    pilot_summary$inference_status != pilot_label
) {
  stop("The H01 response-family pilot has not passed", call. = FALSE)
}

latitude_source_input <- file.path(
  root,
  "artifacts/11_source_data/descriptives/latitude_photoperiod.csv"
)
latitude_source <- readr::read_csv(
  latitude_source_input,
  show_col_types = FALSE,
  progress = FALSE
) |>
  dplyr::left_join(
    site_registry,
    by = "site",
    relationship = "many-to-one"
  ) |>
  dplyr::mutate(
    site = factor(as.character(.data$site), levels = site_registry$site),
    site_display_name = factor(
      .data$display_name,
      levels = site_registry$display_name
    )
  ) |>
  dplyr::arrange(.data$display_order, .data$Id, .data$local_date)
if (nrow(latitude_source) != 816L || anyNA(latitude_source$display_order)) {
  stop("The H01 Figure S10 source data are incomplete", call. = FALSE)
}

span_photoperiod <- tibble::tibble(
  Datetime = as.POSIXct("2025-01-01", tz = "UTC") +
    as.difftime(0:364, units = "days")
)
photoperiod_bounds <- dplyr::bind_rows(lapply(0:60, function(latitude) {
  values <- LightLogR::extract_photoperiod(
    span_photoperiod,
    c(latitude, 0)
  )
  tibble::tibble(
    absolute_latitude_deg = latitude,
    minimum_possible_photoperiod_hours = min(
      as.numeric(values$photoperiod),
      na.rm = TRUE
    ),
    maximum_possible_photoperiod_hours = max(
      as.numeric(values$photoperiod),
      na.rm = TRUE
    ),
    calendar_year = 2025L,
    solar_depression_deg = 6
  )
}))

site_colors <- stats::setNames(
  site_registry$color_hex,
  site_registry$site
)
photoperiod_xlim <- range(
  c(
    photoperiod_bounds$minimum_possible_photoperiod_hours,
    photoperiod_bounds$maximum_possible_photoperiod_hours
  ),
  na.rm = TRUE
)

# Reproduce the submitted Figure S10 visual grammar using the audited source.
# The black impossible-photoperiod masks are drawn first so the coloured
# observations and density ribbons remain visible in front of them.
figure_s10 <- ggplot2::ggplot() +
  ggplot2::geom_ribbon(
    data = photoperiod_bounds,
    ggplot2::aes(
      y = .data$absolute_latitude_deg,
      xmin = 0,
      xmax = .data$minimum_possible_photoperiod_hours
    ),
    orientation = "y",
    fill = "black"
  ) +
  ggplot2::geom_ribbon(
    data = photoperiod_bounds,
    ggplot2::aes(
      y = .data$absolute_latitude_deg,
      xmin = .data$maximum_possible_photoperiod_hours,
      xmax = 24
    ),
    orientation = "y",
    fill = "black"
  ) +
  ggplot2::geom_point(
    data = latitude_source,
    ggplot2::aes(
      x = .data$photoperiod_hours,
      y = .data$plot_latitude_deg,
      colour = .data$site
    ),
    shape = 16,
    size = 1.15,
    alpha = 0.38
  ) +
  ggridges::geom_density_ridges(
    data = latitude_source,
    ggplot2::aes(
      x = .data$photoperiod_hours,
      y = .data$absolute_latitude_deg,
      fill = .data$site,
      colour = .data$site,
      group = .data$site
    ),
    scale = 2,
    position = ggplot2::position_nudge(y = 1),
    bandwidth = 0.15,
    alpha = 0.74,
    linewidth = 0.45,
    rel_min_height = 0.01,
    show.legend = TRUE,
    key_glyph = "rect"
  ) +
  ggplot2::annotate(
    "text",
    y = 3,
    x = 15.2,
    label = "possible photoperiods",
    colour = "white",
    hjust = 0,
    size = 3.8
  ) +
  ggplot2::annotate(
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
  ggplot2::scale_colour_manual(
    values = site_colors,
    breaks = site_registry$site,
    labels = site_registry$display_name,
    name = "Site"
  ) +
  ggplot2::scale_fill_manual(
    values = site_colors,
    breaks = site_registry$site,
    labels = site_registry$display_name,
    name = "Site"
  ) +
  ggplot2::guides(
    colour = "none",
    fill = ggplot2::guide_legend(
      override.aes = list(
        alpha = 1,
        colour = NA
      )
    )
  ) +
  ggplot2::coord_cartesian(
    xlim = photoperiod_xlim,
    ylim = c(0, 63),
    expand = FALSE
  ) +
  ggplot2::labs(
    x = "Photoperiod (hr)",
    y = "Absolute latitude (°)"
  ) +
  cowplot::theme_cowplot(font_size = 10) +
  ggplot2::theme(
    legend.position = "inside",
    legend.position.inside = c(0.65, 0.40),
    legend.justification = c(0.5, 0.5),
    legend.background = ggplot2::element_rect(
      fill = "transparent",
      colour = NA
    ),
    legend.key = ggplot2::element_rect(fill = "transparent", colour = NA),
    legend.title = ggplot2::element_blank(),
    legend.text = ggplot2::element_text(colour = "white", size = 8),
    plot.background = ggplot2::element_rect(fill = "transparent", colour = NA),
    panel.background = ggplot2::element_rect(fill = "transparent", colour = NA),
    plot.margin = ggplot2::margin(5.5, 5.5, 5.5, 5.5)
  )

table_root <- file.path(root, "artifacts/09_tables/H01/reporting")
figure_root <- file.path(root, "artifacts/10_figures/H01/reporting")
source_root <- file.path(root, "artifacts/11_source_data/H01/reporting")
diagnostic_root <- file.path(root, "artifacts/08_diagnostics/H01/reporting")
manifest_path <- file.path(
  root,
  "artifacts/12_manifests/H01_reporting_artifacts.csv"
)
dir.create(table_root, recursive = TRUE, showWarnings = FALSE)
dir.create(figure_root, recursive = TRUE, showWarnings = FALSE)
dir.create(source_root, recursive = TRUE, showWarnings = FALSE)
dir.create(diagnostic_root, recursive = TRUE, showWarnings = FALSE)

output_objects <- list(
  H01_reporting_model_overview = model_overview,
  H01_reporting_site_followups = site_followups,
  H01_reporting_exact_samples = exact_samples,
  H01_reporting_r2_preview_long = r2_preview_long,
  H01_reporting_r2_preview_wide = r2_preview_wide,
  H01_submitted_table_s2_exact_render = v0_s2,
  H01_submitted_table_s3_exact_render = v0_s3,
  H01_reporting_v0_new_tests = v0_new_tests,
  H01_reporting_v0_new_r2 = v0_new_r2,
  H01_reporting_scenario_support = scenario_support,
  H01_reporting_claim_summary = claim_summary,
  H01_reporting_pilot_summary = pilot_summary,
  H01_reporting_candidate_selection = candidate_selection,
  H01_reporting_candidate_scorecard = candidate_scorecard
)
output_paths <- vapply(names(output_objects), function(name) {
  path <- file.path(table_root, paste0(name, ".csv"))
  write_csv_artifact(output_objects[[name]], path, producer = producer)
  path
}, character(1))

latitude_path <- file.path(
  source_root,
  "H01_figure_s10_observed_photoperiod_source.csv"
)
bounds_path <- file.path(
  source_root,
  "H01_figure_s10_theoretical_bounds_source.csv"
)
write_csv_artifact(latitude_source, latitude_path, producer = producer)
write_csv_artifact(photoperiod_bounds, bounds_path, producer = producer)

figure_png <- file.path(
  figure_root,
  "H01_figure_s10_photoperiod_latitude.png"
)
figure_svg <- file.path(
  figure_root,
  "H01_figure_s10_photoperiod_latitude.svg"
)
ggplot2::ggsave(
  figure_png,
  figure_s10,
  width = 6,
  height = 6,
  units = "in",
  dpi = 320,
  bg = "transparent"
)
ggplot2::ggsave(
  figure_svg,
  figure_s10,
  width = 6,
  height = 6,
  units = "in",
  bg = "transparent"
)

provenance_path <- file.path(
  diagnostic_root,
  "H01_reporting_provenance.csv"
)
provenance <- tibble::tibble(
  r_version = as.character(getRversion()),
  gt_version = as.character(utils::packageVersion("gt")),
  quarto_version = system2(
    "quarto",
    "--version",
    stdout = TRUE,
    stderr = TRUE
  )[[1L]],
  LightLogR_version = as.character(utils::packageVersion("LightLogR")),
  ggplot2_version = as.character(utils::packageVersion("ggplot2")),
  ggridges_version = as.character(utils::packageVersion("ggridges")),
  cowplot_version = as.character(utils::packageVersion("cowplot")),
  rvest_version = as.character(utils::packageVersion("rvest")),
  main_input_manifest_sha256 = artifact_sha256(file.path(
    root,
    "artifacts/12_manifests/H01_model_data_artifacts.csv"
  )),
  manuscript_input_manifest_sha256 = artifact_sha256(file.path(
    root,
    "artifacts/12_manifests/H01_manuscript_prepared_data_artifacts.csv"
  )),
  renv_lock_sha256 = artifact_sha256(file.path(root, "renv.lock")),
  submitted_h01_html_sha256 = artifact_sha256(v0_html_path),
  submitted_table_s2_png_sha256 = artifact_sha256(file.path(
    root,
    "manuscript/R0_NatMed/Supplements/TableS2.png"
  )),
  submitted_table_s3_png_sha256 = artifact_sha256(file.path(
    root,
    "manuscript/R0_NatMed/Supplements/TableS3.png"
  )),
  submitted_figure_s10_png_sha256 = artifact_sha256(file.path(
    root,
    "manuscript/R0_NatMed/Supplements/FigureS10.png"
  )),
  figure_source_sha256 = artifact_sha256(latitude_source_input),
  report_status = paste0(
    if (changed_metric_has_production_r2) "PRODUCTION: " else "PREVIEW: ",
    "point-model baseline complete; ",
    if (changed_metric_has_production_r2) {
      paste0(
        "all estimable targets have at least 1,000 successful joint ",
        "bootstrap refits"
      )
    } else {
      paste0(
        "120 preserved production bootstrap targets; 8 changed-family ",
        "targets use the 50-refit pilot only until author production approval"
      )
    }
  ),
  producer_path = producer,
  completed_utc = format(Sys.time(), tz = "UTC", usetz = TRUE)
)
write_csv_artifact(provenance, provenance_path, producer = producer)

manifest_inputs <- c(
  "artifacts/06_model_data/H01/metric_contract.csv",
  "artifacts/09_tables/H01/H01_model_level_tests.csv",
  "artifacts/09_tables/H01/H01_term_effects.csv",
  "artifacts/09_tables/H01/H01_site_estimates.csv",
  "artifacts/09_tables/H01/H01_site_deviations.csv",
  "artifacts/09_tables/H01/H01_exact_samples.csv",
  "artifacts/08_diagnostics/H01/H01_model_diagnostics.csv",
  "artifacts/09_tables/H01/H01_r2_bootstrap_summaries.csv",
  paste0(
    "artifacts/09_tables/H01/bootstrap_pilot/response_family_change/",
    "H01_response_family_bootstrap_pilot_r2_summaries.csv"
  ),
  paste0(
    "artifacts/08_diagnostics/H01/bootstrap_pilot/response_family_change/",
    "H01_response_family_bootstrap_pilot_audit.csv"
  ),
  paste0(
    "artifacts/08_diagnostics/H01/bootstrap_pilot/response_family_change/",
    "H01_response_family_bootstrap_pilot_runtime.csv"
  ),
  "artifacts/09_tables/H01/v0/H01_v0_model_results.csv",
  "artifacts/09_tables/H01/v0/H01_v0_exact_samples.csv",
  "audit/decisions/mder_mean_of_viable_ratios.md",
  paste0(
    "audit/hypotheses/H01/mder_METRIC-010/bootstrap_production/",
    "H01_METRIC-010_bootstrap_production_manifest.csv"
  ),
  paste0(
    "audit/hypotheses/H01/mder_METRIC-010/production_integration/",
    "H01_METRIC-010_production_integration_summary.csv"
  ),
  "artifacts/11_source_data/descriptives/latitude_photoperiod.csv",
  "config/site_display_registry.csv",
  "docs/RQ1.html",
  "manuscript/R0_NatMed/Supplements/TableS2.png",
  "manuscript/R0_NatMed/Supplements/TableS3.png",
  "manuscript/R0_NatMed/Supplements/FigureS10.png",
  producer
)
manifest_files <- c(
  output_paths,
  latitude_path,
  bounds_path,
  figure_png,
  figure_svg,
  provenance_path,
  file.path(root, manifest_inputs)
)
manifest <- dplyr::bind_rows(lapply(
  sort(unique(manifest_files)),
  function(path) {
    artifact_path <- path
    relative_path <- substring(artifact_path, nchar(root) + 2L)
    is_reporting_output <- artifact_path %in% c(
      output_paths,
      latitude_path,
      bounds_path,
      figure_png,
      figure_svg,
      provenance_path
    )
    tibble::tibble(
      path = relative_path,
      sha256 = artifact_sha256(artifact_path),
      bytes = as.numeric(file.info(artifact_path)$size),
      role = dplyr::if_else(
        is_reporting_output,
        "H01 reporting output",
        "H01 reporting input"
      ),
      producer = producer,
      r_version = as.character(getRversion())
    )
  }
))
write_csv_artifact(manifest, manifest_path, producer = producer)

# The canonical model-results manifest predates the reporting layer but includes
# these H01 reporting outputs. Reseal only rows owned by this builder, and fail
# closed if any other canonical artifact has drifted.
model_results_manifest_path <- file.path(
  root,
  "artifacts/12_manifests/H01_model_results_artifacts.csv"
)
model_results_manifest <- readr::read_csv(
  model_results_manifest_path,
  show_col_types = FALSE,
  progress = FALSE
)
model_results_paths <- file.path(root, model_results_manifest$path)
stopifnot(all(file.exists(model_results_paths)))
model_results_hashes <- vapply(
  model_results_paths,
  artifact_sha256,
  character(1)
)
model_results_drift <- model_results_hashes != model_results_manifest$sha256
owned_reporting_paths <- substring(
  c(
    output_paths,
    latitude_path,
    bounds_path,
    figure_png,
    figure_svg,
    provenance_path
  ),
  nchar(root) + 2L
)
stopifnot(
  all(model_results_manifest$path[model_results_drift] %in% owned_reporting_paths)
)
owned_rows <- model_results_manifest$path %in% owned_reporting_paths
model_results_manifest$sha256[owned_rows] <- model_results_hashes[owned_rows]
model_results_manifest$bytes[owned_rows] <- as.numeric(
  file.info(model_results_paths[owned_rows])$size
)
model_results_manifest$producer[owned_rows] <- producer
model_results_manifest$r_version[owned_rows] <- as.character(getRversion())
readr::write_csv(model_results_manifest, model_results_manifest_path, na = "")

# The METRIC-010 integration seal pins the canonical model-results manifest.
# Update only that directly dependent row after the bounded reporting reseal.
integration_manifest_path <- file.path(
  root,
  paste0(
    "audit/hypotheses/H01/mder_METRIC-010/production_integration/",
    "H01_METRIC-010_production_integration_manifest.csv"
  )
)
if (file.exists(integration_manifest_path)) {
  integration_manifest <- readr::read_csv(
    integration_manifest_path,
    show_col_types = FALSE,
    progress = FALSE
  )
  integration_files <- file.path(root, integration_manifest$path)
  stopifnot(all(file.exists(integration_files)))
  integration_hashes <- vapply(
    integration_files,
    artifact_sha256,
    character(1)
  )
  integration_drift <-
    integration_hashes != integration_manifest$sha256
  model_results_relative <- substring(
    model_results_manifest_path,
    nchar(root) + 2L
  )
  stopifnot(
    all(
      integration_manifest$path[integration_drift] == model_results_relative
    )
  )
  integration_row <- which(
    integration_manifest$path == model_results_relative
  )
  stopifnot(length(integration_row) == 1L)
  integration_manifest$sha256[integration_row] <-
    integration_hashes[integration_row]
  integration_manifest$bytes[integration_row] <- as.numeric(
    file.info(model_results_manifest_path)$size
  )
  integration_manifest$producer[integration_row] <- producer
  integration_manifest$r_version[integration_row] <- as.character(
    getRversion()
  )
  readr::write_csv(integration_manifest, integration_manifest_path, na = "")
}

message(
  "Built H01 reporting preview: ",
  nrow(model_overview),
  " metrics, ",
  nrow(site_followups),
  " supported site follow-ups, and ",
  nrow(r2_preview_long),
  " R2 preview rows"
)
