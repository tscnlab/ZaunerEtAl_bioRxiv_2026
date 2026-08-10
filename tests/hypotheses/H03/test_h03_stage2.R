# Verify the H03 Stage 2 contracts and generated analytical artifacts.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
project_library <- file.path(
  root,
  "renv/library/macos/R-4.6/aarch64-apple-darwin23"
)
.libPaths(c(project_library, .libPaths()))

source(file.path(root, "scripts/pipeline/paths_io.R"))
source(file.path(root, "scripts/pipeline/p_value_display.R"))
source(file.path(root, "scripts/hypotheses/H03/h03_contract.R"))

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("H03 Stage 2 tests require R 4.6.1", call. = FALSE)
}

read_h03 <- function(...) {
  readr::read_csv(
    file.path(root, ...),
    show_col_types = FALSE,
    na = ""
  )
}

input_audit <- h03_validate_inputs(root)
approvals <- read_h03("artifacts/06_model_data/H03/H03_author_approvals.csv")
formulas <- read_h03("artifacts/06_model_data/H03/H03_formula_registry.csv")
frames <- read_h03("artifacts/06_model_data/H03/H03_model_frame_index.csv")
category_support <- read_h03("artifacts/06_model_data/H03/H03_category_support.csv")
cell_support <- read_h03("artifacts/06_model_data/H03/H03_site_category_support.csv")
gate <- read_h03("artifacts/08_diagnostics/H03/H03_interaction_architecture_gate.csv")
selection <- read_h03("artifacts/08_diagnostics/H03/H03_interaction_architecture_selection.csv")
primary <- read_h03("artifacts/09_tables/H03/H03_primary_category_estimands.csv")
omnibus <- read_h03("artifacts/09_tables/H03/H03_primary_omnibus_tests.csv")
site_context <- read_h03("artifacts/09_tables/H03/H03_site_context_estimands.csv")
diagnostics <- read_h03("artifacts/08_diagnostics/H03/H03_model_diagnostics.csv")
zero_mass <- read_h03("artifacts/08_diagnostics/H03/H03_zero_mass_diagnostics.csv")
zero_bins <- read_h03("artifacts/08_diagnostics/H03/H03_zero_mass_calibration_bins.csv")
residual_points <- read_h03(
  "artifacts/11_source_data/H03/H03_primary_residual_points.csv"
)
primary_residual_acf <- read_h03(
  "artifacts/08_diagnostics/H03/H03_primary_residual_acf.csv"
)
standardization <- read_h03(
  "artifacts/09_tables/H03/H03_standardization_reconciliation.csv"
)
paired <- read_h03("artifacts/09_tables/H03/H03_paired_placement_comparison.csv")
sensitivity <- read_h03("artifacts/09_tables/H03/H03_sensitivity_comparison.csv")
sensitivity_omnibus <- read_h03("artifacts/09_tables/H03/H03_sensitivity_omnibus_tests.csv")
influence <- read_h03("artifacts/09_tables/H03/H03_influence_category_refits.csv")
influence_site <- read_h03("artifacts/09_tables/H03/H03_influence_site_context_refits.csv")
influence_jobs <- read_h03("artifacts/08_diagnostics/H03/H03_influence_refit_registry.csv")
v0_models <- read_h03("artifacts/09_tables/H03/H03_v0_bridge_models.csv")
v0_tests <- read_h03("artifacts/09_tables/H03/H03_v0_bridge_tests.csv")
v0_comparison <- read_h03("artifacts/09_tables/H03/H03_v0_denominator_and_test_comparison.csv")
deferred <- read_h03("artifacts/09_tables/H03/H03_deferred_computation.csv")
glm_registry <- read_h03(
  "artifacts/09_tables/H03/H03_glm_candidate_model_registry.csv"
)
glm_r_squared <- read_h03(
  "artifacts/09_tables/H03/H03_glm_r_squared_and_effect_partition.csv"
)
glm_cross_validation <- read_h03(
  "artifacts/09_tables/H03/H03_glm_candidate_cross_validation.csv"
)
glm_cross_validation_folds <- read_h03(
  "artifacts/08_diagnostics/H03/H03_glm_candidate_cross_validation_folds.csv"
)

stopifnot(
  all(input_audit$hash_verified),
  nrow(approvals) == 17L,
  all(approvals$approved),
  any(formulas$formula == "geo_medi_1h ~ site + light_source"),
  any(formulas$formula == "geo_medi_1h ~ site * light_source"),
  any(formulas$formula == "geo_medi_1h ~ 0 + site_source_cell"),
  nrow(category_support) == 14L,
  nrow(cell_support) == 126L,
  sum(cell_support$supported) == 101L,
  all(category_support$pooled_estimable),
  nrow(standardization) == 14L,
  max(abs(standardization$stage2_minus_approved_link_scale_lx)) < 1e-8,
  abs(
    standardization$link_scale_equal_site_backtransform_lx[
      standardization$placement == "Near-eye" &
        standardization$category_code == "electric_indoor"
    ] - 88.872571851
  ) < 1e-8,
  abs(
    standardization$response_scale_equal_site_mean_lx[
      standardization$placement == "Near-eye" &
        standardization$category_code == "electric_indoor"
    ] - 97.117022825
  ) < 1e-8,
  nrow(gate) == 2L,
  all(gate$gate_pass),
  all(gate$converged),
  all(gate$design_columns == gate$design_rank),
  identical(gate$restrictions, c(48, 41)),
  all(!gate$effect_estimates_emitted),
  all(!gate$effect_p_values_emitted),
  nrow(selection) == 2L,
  all(selection$full_architecture_passed),
  all(!selection$interaction_effects_inspected_for_selection),
  all(!selection$interaction_p_values_inspected_for_selection)
)

main_frames <- frames[frames$run_id %in% c("main__near_eye", "main__chest"), ]
main_frames <- main_frames[match(c("main__near_eye", "main__chest"), main_frames$run_id), ]
stopifnot(
  identical(main_frames$observations, c(17935, 19512)),
  identical(main_frames$participants, c(140, 151)),
  identical(main_frames$participant_days, c(801, 880)),
  identical(main_frames$sites, c(9, 8)),
  identical(main_frames$exact_zero_hours, c(4977, 5409)),
  identical(main_frames$boundary_hours, c(2396, 2570))
)

stopifnot(
  nrow(primary) == 14L,
  all(primary$distribution == "site_standardized"),
  all(primary$family_n[primary$category_order != 1L] == 6L),
  all(is.finite(primary$expected_mel_edi_lx)),
  abs(
    primary$expected_mel_edi_lx[
      primary$placement == "Near-eye" &
        primary$category_code == "electric_indoor"
    ] - 88.872571851
  ) < 1e-8,
  all(is.finite(primary$expected_conf_low_lx)),
  all(is.finite(primary$expected_conf_high_lx)),
  all(primary$expected_conf_low_lx <= primary$expected_mel_edi_lx),
  all(primary$expected_mel_edi_lx <= primary$expected_conf_high_lx)
)
for (placement in c("Near-eye", "Chest")) {
  rows <- primary[
    primary$placement == placement & primary$category_order != 1L,
  ]
  reproduced <- stats::p.adjust(rows$p_raw, method = "BH", n = 6L)
  stopifnot(isTRUE(all.equal(
    rows$p_adjusted,
    reproduced,
    tolerance = 1e-14
  )))
}
stopifnot(
  nrow(omnibus) == 4L,
  all(omnibus$status == "ESTIMABLE"),
  identical(omnibus$restrictions, c(6, 6, 48, 41)),
  all(omnibus$p_raw < 0.001),
  nrow(site_context) == 126L,
  sum(site_context$reporting_status == "ESTIMABLE") == 96L,
  sum(site_context$reporting_status == "SUPPORT_NON_ESTIMABLE") == 17L,
  sum(site_context$site_deviation_p_adjusted < 0.05, na.rm = TRUE) == 37L
)

main_diagnostics <- diagnostics[diagnostics$scenario_id == "primary_dataset", ]
stopifnot(
  nrow(main_diagnostics) == 2L,
  all(main_diagnostics$converged),
  all(main_diagnostics$full_rank),
  all(main_diagnostics$covariance_positive_definite),
  all(main_diagnostics$maximum_cluster_score_share < 0.5),
  all(main_diagnostics$maximum_cluster_leverage_share < 0.2),
  all(main_diagnostics$exact_zero_fraction > 0.27),
  all(abs(main_diagnostics$residual_lag1_correlation) > 0.45)
)
overall_zero <- zero_mass[zero_mass$scope == "overall", ]
stopifnot(
  nrow(overall_zero) == 2L,
  all(overall_zero$observed_zero_fraction > 0.27),
  all(overall_zero$working_expected_zero_fraction > 0.85),
  all(overall_zero$observed_minus_working_fraction < -0.55),
  nrow(zero_bins) == 20L,
  nrow(residual_points) == 37447L,
  all(is.finite(residual_points$fitted_mean)),
  all(is.finite(residual_points$pearson_residual)),
  nrow(primary_residual_acf) == 12L,
  all(vapply(
    split(primary_residual_acf$lag, primary_residual_acf$placement),
    function(x) identical(as.integer(x), 1:6),
    logical(1)
  )),
  all(primary_residual_acf$eligible_pairs > 0L)
)

stopifnot(
  nrow(paired) == 7L,
  all(paired$paired_hours_near == paired$paired_hours_chest),
  sum(paired$paired_hours_near) == 14103L,
  paired$near_estimability_status[paired$category_code == "electric_outdoor"] ==
    "SUPPORT_NON_ESTIMABLE",
  nrow(sensitivity) == 98L,
  sum(sensitivity$stability == "stable") == 88L,
  sum(sensitivity$stability == "support_non_estimable") == 6L,
  sum(sensitivity$stability == "direction_shift") == 2L,
  sum(sensitivity$stability == "magnitude_shift") == 2L,
  nrow(sensitivity_omnibus) == 14L,
  all(sensitivity_omnibus$status == "ESTIMABLE"),
  all(sensitivity_omnibus$p_raw < 0.001)
)
gap <- sensitivity[sensitivity$scenario_id == "gap_timing_unaware_dataset", ]
stopifnot(nrow(gap) == 14L, all(gap$stability == "stable"))

stopifnot(
  nrow(influence_jobs) == 27L,
  nrow(influence) == 189L,
  sum(influence$omnibus_decision_changed, na.rm = TRUE) == 0L,
  sum(influence$full_ratio_inside_deletion_interval, na.rm = TRUE) == 173L,
  sum(!is.na(influence$full_ratio_inside_deletion_interval)) == 176L,
  nrow(influence_site) == 882L,
  sum(influence_site$full_deviation_inside_deletion_interval, na.rm = TRUE) ==
    685L
)

stopifnot(
  nrow(v0_models) == 4L,
  all(v0_models$convergence_code == 0L),
  all(v0_models$positive_definite_hessian),
  all(!v0_models$singular),
  nrow(v0_tests) == 2L,
  all(v0_tests$categories == 5L),
  all(v0_tests$p_raw < 0.001),
  nrow(v0_comparison) == 6L,
  identical(
    v0_comparison$observations[v0_comparison$implementation == "Frozen V0"],
    c(16774, 18391)
  ),
  identical(
    v0_comparison$observations[
      v0_comparison$implementation == "Approved H03 Stage 2"
    ],
    c(17935, 19512)
  ),
  all(deferred$status == "DEFERRED"),
  all(deferred$pilot_or_production != "production run")
)

stopifnot(
  nrow(glm_registry) == 3L,
  nrow(glm_r_squared) == 18L,
  nrow(glm_cross_validation) == 6L,
  nrow(glm_cross_validation_folds) == 30L,
  all(glm_cross_validation$folds == 5L),
  all(glm_cross_validation$all_converged),
  all(glm_cross_validation$all_full_rank),
  all(glm_cross_validation$warning_count == 0L),
  all(glm_cross_validation_folds$converged),
  all(glm_cross_validation_folds$rank == glm_cross_validation_folds$coefficients),
  all(glm_r_squared$full_converged),
  all(glm_r_squared$full_rank == glm_r_squared$full_coefficients),
  all(is.finite(glm_r_squared$overall_r_squared)),
  all(is.finite(
    glm_r_squared$interaction_partial_r_squared_conditional_on_additive
  )),
  all(glm_r_squared$interaction_r_squared > 0),
  all(glm_r_squared$heterogeneity_architecture[
    glm_r_squared$placement == "Near-eye"
  ] == "full_literal"),
  all(glm_r_squared$heterogeneity_architecture[
    glm_r_squared$placement == "Chest"
  ] == "full_observed_cell"),
  all(grepl(
    "site * light_source",
    glm_r_squared$r_squared_formula[glm_r_squared$placement == "Near-eye"],
    fixed = TRUE
  )),
  all(grepl(
    "0 + site_source_cell",
    glm_r_squared$r_squared_formula[glm_r_squared$placement == "Chest"],
    fixed = TRUE
  )),
  all(abs(
    glm_r_squared$site_shapley_r_squared +
      glm_r_squared$category_shapley_r_squared +
      glm_r_squared$interaction_r_squared -
      glm_r_squared$overall_r_squared
  ) < 1e-12)
)
for (placement in c("Near-eye", "Chest")) {
  candidates <- glm_cross_validation[
    glm_cross_validation$placement == placement,
  ]
  quasi <- candidates[candidates$model_id == "quasi_tweedie_log", ]
  gaussian <- candidates[candidates$model_id == "gaussian_identity_raw", ]
  log_gaussian <- candidates[
    candidates$model_id == "gaussian_log10_response",
  ]
  stopifnot(
    quasi$raw_rmse_lx < gaussian$raw_rmse_lx,
    quasi$raw_mae_lx < gaussian$raw_mae_lx,
    quasi$negative_prediction_fraction == 0,
    gaussian$negative_prediction_fraction > 0.24,
    log_gaussian$log10_rmse < quasi$log10_rmse,
    log_gaussian$predicted_mean_lx < 0.2 * log_gaussian$observed_mean_lx
  )
}

temporal_summary <- read_h03("artifacts/09_tables/H03/H03_temporal_model_summary.csv")
temporal_r2 <- read_h03("artifacts/09_tables/H03/H03_temporal_weighted_r_squared.csv")
temporal_partition <- read_h03("artifacts/09_tables/H03/H03_temporal_shapley_allocation.csv")
temporal_k <- read_h03("artifacts/08_diagnostics/H03/H03_temporal_k_check.csv")
temporal_concurvity <- read_h03("artifacts/08_diagnostics/H03/H03_temporal_concurvity.csv")
temporal_constraints <- read_h03("artifacts/08_diagnostics/H03/H03_temporal_sz_constraints.csv")
temporal_midnight <- read_h03("artifacts/08_diagnostics/H03/H03_temporal_midnight_diagnostics.csv")
temporal_acf <- read_h03("artifacts/08_diagnostics/H03/H03_temporal_residual_acf.csv")
temporal_curves <- read_h03("artifacts/11_source_data/H03/H03_temporal_category_curves.csv")
temporal_deviations <- read_h03("artifacts/11_source_data/H03/H03_temporal_category_deviations.csv")
temporal_global <- read_h03("artifacts/11_source_data/H03/H03_temporal_global_curves.csv")
temporal_support <- read_h03("artifacts/11_source_data/H03/H03_temporal_clock_support.csv")
temporal_basis_registry <- read_h03(
  "artifacts/09_tables/H03/H03_temporal_basis_model_registry.csv"
)
temporal_basis_fit <- read_h03(
  "artifacts/09_tables/H03/H03_temporal_basis_fit_comparison.csv"
)
temporal_basis_delta <- read_h03(
  "artifacts/09_tables/H03/H03_temporal_basis_comparison_deltas.csv"
)

stopifnot(
  nrow(temporal_summary) == 2L,
  all(temporal_summary$converged),
  all(temporal_summary$convergence == "full convergence"),
  temporal_summary$smoothing_hessian_positive_definite[
    temporal_summary$placement == "Near-eye"
  ],
  !temporal_summary$smoothing_hessian_positive_definite[
    temporal_summary$placement == "Chest"
  ],
  all(temporal_summary$adjusted_r_squared > 0.77),
  all(temporal_summary$standardized_residual_lag1 < 0.10),
  nrow(temporal_r2) == 2L,
  all(temporal_r2$r_squared > 0.78),
  nrow(temporal_partition) == 10L,
  all(abs(temporal_partition$shapley_efficiency_error) < 1e-10),
  all(grepl("no simulation", temporal_partition$uncertainty, fixed = TRUE)),
  nrow(temporal_k) == 10L,
  all(temporal_k$resampling_replicates == 0L),
  all(is.na(temporal_k$p_value)),
  any(!temporal_concurvity$standard_mgcv_diagnostic_available),
  any(temporal_concurvity$standard_mgcv_diagnostic_available),
  nrow(temporal_constraints) == 4L,
  all(temporal_constraints$passes),
  max(temporal_constraints$maximum_absolute_sum) < 1e-12,
  max(temporal_midnight$endpoint_difference_abs) < 0.5,
  all(temporal_acf$correlation[temporal_acf$lag == 1L] < 0.10),
  nrow(temporal_curves) == 336L,
  nrow(temporal_deviations) == 336L,
  nrow(temporal_global) == 48L,
  nrow(temporal_support) == 336L,
  any(temporal_support$participant_hours == 0L),
  nrow(temporal_basis_registry) == 2L,
  nrow(temporal_basis_fit) == 4L,
  nrow(temporal_basis_delta) == 2L,
  all(temporal_basis_fit$converged),
  all(temporal_basis_fit$rank == temporal_basis_fit$coefficients),
  all(temporal_basis_fit$smoothing_hessian_positive_definite[
    temporal_basis_fit$model_id == "cyclic_sz"
  ]),
  max(
    temporal_basis_fit$maximum_category_endpoint_difference_log10[
      temporal_basis_fit$model_id == "cyclic_sz"
    ],
    temporal_basis_fit$maximum_site_endpoint_difference_log10[
      temporal_basis_fit$model_id == "cyclic_sz"
    ]
  ) < 1e-12,
  all(temporal_basis_delta$cyclic_minus_inherited_aic > 25),
  all(temporal_basis_delta$cyclic_minus_inherited_adjusted_r_squared < 0),
  all(temporal_basis_delta$cyclic_minus_inherited_residual_lag1 > 0)
)

required_stems <- c(
  "H03_primary_category_estimates",
  "H03_near_eye_site_context_estimates",
  "H03_paired_placement_comparison",
  "H03_primary_residual_diagnostics",
  "H03_temporal_near_eye",
  "H03_temporal_chest",
  "H03_temporal_basis_diagnostic_comparison",
  "H03_temporal_appraise_near_eye",
  "H03_temporal_appraise_chest"
)
required_figures <- unlist(lapply(required_stems, function(stem) {
  paste0(stem, c(".png", ".pdf", ".svg"))
}))
stopifnot(all(file.exists(file.path(
  root,
  "artifacts/10_figures/H03",
  required_figures
))))
primary_svg <- paste(readLines(file.path(
  root,
  "artifacts/10_figures/H03/H03_primary_category_estimates.svg"
)), collapse = "\n")
temporal_svg <- paste(readLines(file.path(
  root,
  "artifacts/10_figures/H03/H03_temporal_near_eye.svg"
)), collapse = "\n")
site_context_svg <- paste(readLines(file.path(
  root,
  "artifacts/10_figures/H03/H03_near_eye_site_context_estimates.svg"
)), collapse = "\n")
residual_svg <- paste(readLines(file.path(
  root,
  "artifacts/10_figures/H03/H03_primary_residual_diagnostics.svg"
)), collapse = "\n")
temporal_basis_svg <- paste(readLines(file.path(
  root,
  "artifacts/10_figures/H03/H03_temporal_basis_diagnostic_comparison.svg"
)), collapse = "\n")
stopifnot(
  grepl("stroke: #E3E6E8", primary_svg, fixed = TRUE),
  grepl("stroke: #E3E6E8", temporal_svg, fixed = TRUE),
  grepl("fill: #F2F2F2", temporal_svg, fixed = TRUE),
  grepl("filled points: observed", temporal_svg, fixed = TRUE),
  grepl("open points: locally sparse", temporal_svg, fixed = TRUE),
  grepl("&lt;20 participant-hours", temporal_svg, fixed = TRUE),
  grepl("BH-adjusted site deviation", site_context_svg, fixed = TRUE),
  grepl("Individual and binned", residual_svg, fixed = TRUE),
  grepl("Boundary-aware residual autocorrelation", residual_svg, fixed = TRUE),
  grepl("Maximum midnight discontinuity", temporal_basis_svg, fixed = TRUE)
)
stopifnot(
  identical(
    nh_format_p_value(c(0.0009, 0.001, 0.032, 0.247, 1, NA_real_)),
    c("<0.001", "0.001", "0.032", "0.247", "1.000", "—")
  )
)

stage2_html_path <- file.path(
  root,
  "audit/hypotheses/H03/02_implementation_and_v0_comparison.html"
)
stopifnot(file.exists(stage2_html_path))
stage2_document <- xml2::read_html(stage2_html_path)
stage2_text <- xml2::xml_text(stage2_document)
stage2_text_lower <- tolower(stage2_text)
stopifnot(
  grepl("H3: Hourly self-reported light exposure categories predict hourly geometric mean melanopic EDI.", stage2_text, fixed = TRUE),
  grepl("17,935", stage2_text, fixed = TRUE),
  grepl("19,512", stage2_text, fixed = TRUE),
  grepl("gap-timing-unaware dataset", stage2_text_lower, fixed = TRUE),
  grepl("working zero mass", stage2_text_lower, fixed = TRUE),
  grepl("geometric mean of the site-specific expected values", stage2_text_lower, fixed = TRUE),
  grepl("not a sample or fitted-model change", stage2_text_lower, fixed = TRUE),
  grepl("descriptive fixed-effect r²", stage2_text_lower, fixed = TRUE),
  grepl("interaction partial", stage2_text_lower, fixed = TRUE),
  grepl("diagnostic comparison", stage2_text_lower, fixed = TRUE),
  grepl("not uniformly a better empirical fit", stage2_text_lower, fixed = TRUE),
  grepl(
    "every participant-hour pearson residual",
    stage2_text_lower,
    fixed = TRUE
  ),
  grepl("raw-scale gaussian did not fit better", stage2_text_lower, fixed = TRUE),
  grepl("light-grey regions", stage2_text_lower, fixed = TRUE),
  grepl("no simulation", stage2_text_lower, fixed = TRUE),
  grepl("full convergence", stage2_text_lower, fixed = TRUE),
  grepl("not an equivalence test", stage2_text_lower, fixed = TRUE),
  grepl("<0.001", stage2_text, fixed = TRUE),
  grepl("F(48, 139) = 79.99", stage2_text, fixed = TRUE),
  !grepl("F(, )", stage2_text, fixed = TRUE),
  !grepl("p = 0.000", stage2_text_lower, fixed = TRUE),
  !grepl("p 0.000", stage2_text_lower, fixed = TRUE)
)

cat(
  paste0(
    "H03 Stage 2 tests passed: seven-category primary inference, full ",
    "interaction gates, fixed-effect R-squared/Gaussian checks, registered ",
    "sensitivities, exact V0 bridge, and global-plus-sz exploratory temporal ",
    "context.\n"
  )
)
