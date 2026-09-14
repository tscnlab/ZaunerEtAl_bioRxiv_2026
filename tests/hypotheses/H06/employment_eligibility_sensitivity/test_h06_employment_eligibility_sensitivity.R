# Verify the frozen outputs for the H06 near-eye employment sensitivity.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)

source(file.path(root, "scripts/pipeline/paths_io.R"))
source(file.path(root, "scripts/hypotheses/H06/h06_contract.R"))
source(file.path(root, "scripts/hypotheses/H06/h06_modeling.R"))
source(file.path(root, "scripts/hypotheses/H06/h06_robust_modeling.R"))

stopifnot(identical(as.character(getRversion()), "4.6.1"))

model_data <- file.path(
  root,
  "artifacts/06_model_data/H06/employment_eligibility_sensitivity"
)
models <- file.path(
  root,
  "artifacts/07_models/H06/employment_eligibility_sensitivity"
)
diagnostics <- file.path(
  root,
  "artifacts/08_diagnostics/H06/employment_eligibility_sensitivity"
)
tables <- file.path(
  root,
  "artifacts/09_tables/H06/employment_eligibility_sensitivity"
)
manifests <- file.path(
  root,
  "artifacts/12_manifests/H06/employment_eligibility_sensitivity"
)

read_csv <- function(directory, filename) {
  readr::read_csv(
    file.path(directory, filename),
    show_col_types = FALSE,
    na = ""
  )
}

input_audit <- read_csv(
  model_data,
  "H06_employment_eligibility_input_audit.csv"
)
stopifnot(
  nrow(input_audit) == 18L,
  all(input_audit$exists),
  all(input_audit$hash_verified),
  identical(input_audit$expected_sha256, input_audit$observed_sha256)
)

scenario_contract <- read_csv(
  model_data,
  "H06_employment_eligibility_scenario_contract.csv"
)
stopifnot(
  nrow(scenario_contract) == 1L,
  scenario_contract$scenario_id == "H06-S-EMP-NE",
  scenario_contract$primary_axis_changed == "employment status",
  grepl("do not apply an age exclusion", scenario_contract$change_from_primary),
  grepl("no redundant common-sample refit", scenario_contract$sample_strategy)
)

sample_flow <- read_csv(
  model_data,
  "H06_employment_eligibility_sample_flow.csv"
)
stopifnot(
  nrow(sample_flow) == 2L,
  identical(sample_flow$one_hour_observations, c(16596, 15871)),
  identical(sample_flow$participant_days, c(715, 684)),
  identical(sample_flow$participants, c(137, 131)),
  identical(sample_flow$sites, c(9, 9)),
  all(sample_flow$retained_hour_fraction > 0.95),
  all(sample_flow$retained_day_fraction > 0.95),
  all(sample_flow$retained_participant_fraction > 0.95)
)

exclusions <- read_csv(
  model_data,
  "H06_employment_eligibility_exclusion_audit.csv"
)
stopifnot(
  nrow(exclusions) == 6L,
  all(nchar(exclusions$participant_key_sha256) == 64L),
  !anyDuplicated(exclusions$participant_key_sha256),
  identical(
    sort(unique(exclusions$employment_status)),
    c("Marginally employed (Minijob)", "Not employed")
  ),
  sum(exclusions$employment_status == "Marginally employed (Minijob)") == 4L,
  sum(exclusions$employment_status == "Not employed") == 2L,
  sum(exclusions$excluded_supported_hours) == 725L,
  sum(exclusions$excluded_participant_days) == 31L,
  !any(grepl("::", exclusions$participant_key_sha256, fixed = TRUE))
)

primary_frame <- readRDS(file.path(
  root,
  "artifacts/06_model_data/H06/main__glasses__all_available__frame.rds"
))
demographics <- readRDS(file.path(
  root,
  "artifacts/06_model_data/normalized_inputs/demographics.rds"
))
excluded_keys <- demographics |>
  dplyr::filter(
    .data$employment_status %in%
      c("Not employed", "Marginally employed (Minijob)")
  ) |>
  dplyr::transmute(
    participant_key = paste(.data$site, .data$Id, sep = "::")
  ) |>
  dplyr::pull(.data$participant_key)
frame <- primary_frame |>
  dplyr::filter(
    !as.character(.data$participant_key) %in% .env$excluded_keys
  ) |>
  h06_refactor_frame()
stopifnot(
  nrow(frame) == 15871L,
  dplyr::n_distinct(frame$participant_day_key) == 684L,
  dplyr::n_distinct(frame$participant_key) == 131L,
  dplyr::n_distinct(frame$site) == 9L,
  !anyDuplicated(frame$.model_row_id),
  identical(
    levels(frame$work_free_day),
    c("Work day", "Free day")
  ),
  identical(levels(frame$activity_status), h06_activity_levels())
)

category_cells <- read_csv(
  model_data,
  "H06_employment_eligibility_category_cells.csv"
)
stopifnot(
  nrow(category_cells) == 36L,
  min(category_cells$one_hour_observations[
    category_cells$cell_type == "work_free_day"
  ]) == 187L,
  min(category_cells$one_hour_observations[
    category_cells$cell_type == "activity_status"
  ]) == 180L
)

formula_registry <- read_csv(
  model_data,
  "H06_employment_eligibility_formula_registry.csv"
)
expected_formulas <- vapply(
  h06_formula_set()[c("additive", "full")],
  h06_formula_text,
  character(1)
)
stopifnot(
  nrow(formula_registry) == 2L,
  identical(formula_registry$model_role, c("additive", "full")),
  identical(formula_registry$wilkinson_formula, unname(expected_formulas)),
  all(formula_registry$family == "quasi-Poisson"),
  all(formula_registry$link == "log"),
  all(formula_registry$covariance == "participant-cluster HC3")
)

model_object <- readRDS(file.path(
  models,
  "H06_employment_eligibility_models.rds"
))
stopifnot(
  model_object$scenario_id == "H06-S-EMP-NE",
  model_object$run_id == "employment_eligible__glasses__all_available",
  identical(model_object$sensitivity_frame_sha256, h06_model_frame_hash(frame)),
  length(model_object$excluded_participant_key_sha256) == 6L,
  all(nchar(model_object$excluded_participant_key_sha256) == 64L),
  inherits(model_object$additive$fit, "glm"),
  inherits(model_object$full$fit, "glm"),
  is.null(model_object$additive$data),
  is.null(model_object$full$data),
  model_object$additive$observations == 15871L,
  model_object$full$participants == 131L
)

fit_diagnostics <- read_csv(
  diagnostics,
  "H06_employment_eligibility_fit_diagnostics.csv"
)
stopifnot(
  nrow(fit_diagnostics) == 2L,
  identical(fit_diagnostics$model_role, c("additive", "full")),
  all(fit_diagnostics$observations == 15871L),
  all(fit_diagnostics$participants == 131L),
  all(fit_diagnostics$participant_days == 684L),
  all(fit_diagnostics$sites == 9L),
  all(fit_diagnostics$converged),
  all(fit_diagnostics$full_rank),
  all(fit_diagnostics$finite_coefficients),
  all(fit_diagnostics$hc3_covariance_finite),
  all(fit_diagnostics$hc3_covariance_positive_definite),
  all(fit_diagnostics$numerical_gate_pass),
  all(is.na(fit_diagnostics$fit_error))
)

covariance <- read_csv(
  diagnostics,
  "H06_employment_eligibility_covariance_diagnostics.csv"
)
stopifnot(
  nrow(covariance) == 8L,
  all(table(covariance$covariance_type) == 2L),
  all(covariance$finite),
  all(covariance$positive_definite),
  all(is.na(covariance$covariance_error))
)

cluster <- read_csv(
  diagnostics,
  "H06_employment_eligibility_cluster_diagnostics.csv"
)
stopifnot(
  nrow(cluster) == 262L,
  all(nchar(cluster$participant_key_sha256) == 64L),
  !"participant_key" %in% names(cluster),
  max(cluster$score_share) <= 0.50,
  max(cluster$leverage_share) <= 0.20
)

for (filename in c(
  "H06_employment_eligibility_residual_calibration.csv",
  "H06_employment_eligibility_residual_fitted_bins.csv",
  "H06_employment_eligibility_residual_clock.csv",
  "H06_employment_eligibility_residual_acf.csv"
)) {
  output <- read_csv(diagnostics, filename)
  stopifnot(
    nrow(output) > 0L,
    all(!is.na(output$run_id)),
    all(output$run_id == "employment_eligible__glasses__all_available")
  )
}

effects <- read_csv(tables, "H06_employment_eligibility_effects.csv")
stopifnot(
  nrow(effects) == 3L,
  identical(
    effects$predictor_id,
    c(
      "work_free_day",
      "activity_status",
      "previous_sleep_duration_centered_h"
    )
  ),
  all(effects$status == "ESTIMABLE"),
  all(effects$conf_low_ratio > 0),
  all(effects$conf_high_ratio > effects$conf_low_ratio),
  all(effects$planned_size == 3L),
  all(effects$available_rank == 3L),
  all(effects$adjustment_method == "BH")
)

wald <- read_csv(tables, "H06_employment_eligibility_wald_tests.csv")
stopifnot(
  nrow(wald) == 6L,
  all(table(wald$family_id) == 3L),
  all(wald$status == "ESTIMABLE"),
  all(wald$planned_size == 3L),
  all(wald$available_rank == 3L),
  all(wald$adjustment_method == "BH")
)

site_summaries <- read_csv(
  tables,
  "H06_employment_eligibility_site_summaries.csv"
)
stopifnot(
  nrow(site_summaries) == 27L,
  all(table(site_summaries$predictor_id) == 9L),
  all(site_summaries$status == "ESTIMABLE"),
  all(site_summaries$conf_low_ratio > 0),
  all(site_summaries$conf_high_ratio > site_summaries$conf_low_ratio),
  all(grepl("no new multiplicity family", site_summaries$inferential_role))
)

effect_comparison <- read_csv(
  tables,
  "H06_employment_eligibility_effect_comparison.csv"
)
stopifnot(
  nrow(effect_comparison) == 3L,
  all(effect_comparison$comparison_id ==
    "frozen_primary_vs_employment_eligible_near_eye"),
  all(effect_comparison$stability_classification %in% c(
    "stable",
    "quantitatively sensitive",
    "qualitatively sensitive",
    "inconclusive",
    "invalid",
    "non-estimable"
  ))
)

heterogeneity <- read_csv(
  tables,
  "H06_employment_eligibility_heterogeneity_comparison.csv"
)
stopifnot(
  nrow(heterogeneity) == 3L,
  all(heterogeneity$sensitivity_status == "ESTIMABLE"),
  all(is.finite(heterogeneity$primary_p_adjusted)),
  all(is.finite(heterogeneity$sensitivity_p_adjusted)),
  all(grepl("p-value crossing alone", heterogeneity$interpretation_rule))
)

site_comparison <- read_csv(
  tables,
  "H06_employment_eligibility_site_comparison.csv"
)
stopifnot(
  nrow(site_comparison) == 27L,
  all(table(site_comparison$predictor_id) == 9L),
  all(is.finite(site_comparison$log_estimate_difference)),
  all(site_comparison$detailed_stability_classification %in% c(
    "stable within model uncertainty",
    "precision-sensitive",
    "magnitude-sensitive",
    "direction-sensitive",
    "multiplicity-conclusion-sensitive",
    "non-estimable"
  ))
)

manifest <- read_csv(
  manifests,
  "H06_employment_eligibility_analysis_manifest.csv"
)
manifest_path <- paste0(
  "artifacts/12_manifests/H06/employment_eligibility_sensitivity/",
  "H06_employment_eligibility_analysis_manifest.csv"
)
stopifnot(
  nrow(manifest) >= 20L,
  !anyDuplicated(manifest$path),
  !manifest_path %in% manifest$path,
  all(file.exists(file.path(root, manifest$path))),
  all(vapply(
    seq_len(nrow(manifest)),
    function(index) {
      identical(
        artifact_sha256(file.path(root, manifest$path[[index]])),
        manifest$sha256[[index]]
      )
    },
    logical(1)
  ))
)

cat("H06-S-EMP-NE verifier PASS\n")
