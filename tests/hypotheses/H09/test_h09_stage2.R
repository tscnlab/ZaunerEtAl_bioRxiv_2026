# Verify the author-approved H09 Stage 2 contract and generated artifacts.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)

project_library <- file.path(
  root,
  "renv/library/macos/R-4.6/aarch64-apple-darwin23"
)
if (dir.exists(project_library)) {
  .libPaths(c(project_library, .libPaths()))
}

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(tibble)
})

source(file.path(root, "scripts/pipeline/paths_io.R"))
source(file.path(root, "scripts/pipeline/p_value_display.R"))
source(file.path(root, "scripts/hypotheses/H09/h09_contract.R"))

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("H09 Stage 2 tests require R 4.6.1", call. = FALSE)
}

read_h09 <- function(...) {
  readr::read_csv(file.path(root, ...), show_col_types = FALSE, na = "")
}

for (path in c(
  "scripts/hypotheses/H09/h09_contract.R",
  "scripts/hypotheses/H09/h09_modeling.R",
  "scripts/hypotheses/H09/run_h09_stage2.R",
  "tests/hypotheses/H09/test_h09_stage2.R"
)) {
  invisible(parse(file.path(root, path)))
}

h09_validate_contract()
input_contract <- h09_input_contract(root)
stopifnot(
  all(file.exists(input_contract$absolute_path)),
  all(
    vapply(
      input_contract$absolute_path,
      artifact_sha256,
      character(1)
    ) == input_contract$expected_sha256
  )
)

approvals <- read_h09(
  "artifacts/06_model_data/H09/H09_author_approvals.csv"
)
inputs <- read_h09("artifacts/06_model_data/H09/H09_input_audit.csv")
base_bundle <- read_h09(
  "artifacts/06_model_data/H09/H09_base_bundle_audit.csv"
)
metrics <- read_h09("artifacts/06_model_data/H09/H09_metric_registry.csv")
predictors <- read_h09(
  "artifacts/06_model_data/H09/H09_predictor_registry.csv"
)
runs <- read_h09("artifacts/06_model_data/H09/H09_run_registry.csv")
families <- read_h09("artifacts/06_model_data/H09/H09_family_registry.csv")
formulas <- read_h09("artifacts/06_model_data/H09/H09_formula_registry.csv")
frames <- read_h09("artifacts/06_model_data/H09/H09_model_frame_index.csv")
frame_sites <- read_h09(
  "artifacts/06_model_data/H09/H09_model_frame_by_site.csv"
)
paired_audit <- read_h09(
  "artifacts/06_model_data/H09/H09_paired_sample_audit.csv"
)
gap_common_audit <- read_h09(
  "artifacts/06_model_data/H09/H09_gap_common_sample_audit.csv"
)
non_estimable <- read_h09(
  "artifacts/06_model_data/H09/H09_non_estimable_targets.csv"
)

stopifnot(
  nrow(approvals) == 16L,
  all(approvals$approved),
  approvals$decision[approvals$gate_id == "H09-G4"] ==
    "Pinned aggregate calculated fields msf_sc and meq explicitly accepted",
  nrow(inputs) == 16L,
  all(inputs$hash_verified),
  all(inputs$rows_verified),
  isTRUE(base_bundle$input_bundle_verified),
  grepl("PREP-003/FIND-044 remain open", base_bundle$provenance_qualification),
  nrow(metrics) == 6L,
  sum(metrics$primary_family_member) == 5L,
  metrics$metric_id[metrics$metric_order == 5L] ==
    "longest_period_midpoint",
  metrics$analysis_branch[metrics$metric_id == "mean_timing_above_250"] ==
    "adapted_mean_timing_sensitivity",
  nrow(predictors) == 2L,
  identical(sort(predictors$predictor_column), sort(c("mctq_hour", "meq_score"))),
  nrow(runs) == 10L,
  !anyDuplicated(runs$run_id),
  nrow(families) == 4L,
  all(families$planned_n == 5L),
  nrow(formulas) == 31L,
  !any(grepl("temperature|weather", formulas$formula, ignore.case = TRUE))
)

expected_formulas <- c(
  "timing_hour ~ site + (1 | site:Id)",
  "timing_hour ~ site + mctq_hour_centered + (1 | site:Id)",
  "timing_hour ~ site * mctq_hour_centered + (1 | site:Id)",
  "timing_hour ~ site + meq_10_centered + (1 | site:Id)",
  "timing_hour ~ site * meq_10_centered + (1 | site:Id)",
  paste0(
    "timing_hour ~ site + photoperiod_within_site + ",
    "mctq_hour_centered + (1 | site:Id)"
  ),
  paste0(
    "timing_hour ~ site + photoperiod_within_site + ",
    "meq_10_centered + (1 | site:Id)"
  )
)
normalize_formula <- function(x) gsub("[[:space:]]+", " ", trimws(x))
stopifnot(all(
  normalize_formula(expected_formulas) %in%
    normalize_formula(formulas$formula)
))

stopifnot(
  nrow(frames) == 108L,
  all(frames$availability == "ESTIMABLE"),
  all(frames$participants > 0L),
  all(frames$participant_days > 0L),
  all(frames$observations == frames$participant_days),
  all(frames$sites %in% c(8L, 9L)),
  all(nzchar(frames$row_key_hash)),
  all(nzchar(frames$model_frame_hash)),
  nrow(frame_sites) > nrow(frames),
  nrow(paired_audit) == 12L,
  all(paired_audit$exact_counts_match),
  all(paired_audit$exact_row_keys_match),
  nrow(gap_common_audit) == 20L,
  all(gap_common_audit$exact_counts_match),
  all(gap_common_audit$exact_row_keys_match),
  nrow(non_estimable) == 12L,
  all(non_estimable$metric_id == "longest_period_midpoint"),
  all(non_estimable$availability == "NON_ESTIMABLE")
)

expected_primary_samples <- tibble::tribble(
  ~placement, ~metric_id, ~instrument_id, ~participants, ~participant_days,
  "chest", "first_timing_above_250", "MCTQ", 153, 797,
  "chest", "first_timing_above_250", "MEQ", 154, 802,
  "chest", "l10_midpoint", "MCTQ", 153, 896,
  "chest", "l10_midpoint", "MEQ", 154, 902,
  "chest", "last_timing_above_250", "MCTQ", 153, 783,
  "chest", "last_timing_above_250", "MEQ", 154, 787,
  "chest", "longest_period_midpoint", "MCTQ", 149, 547,
  "chest", "longest_period_midpoint", "MEQ", 150, 549,
  "chest", "m10_midpoint", "MCTQ", 153, 896,
  "chest", "m10_midpoint", "MEQ", 154, 902,
  "chest", "mean_timing_above_250", "MCTQ", 153, 825,
  "chest", "mean_timing_above_250", "MEQ", 154, 831,
  "glasses", "first_timing_above_250", "MCTQ", 139, 722,
  "glasses", "first_timing_above_250", "MEQ", 140, 727,
  "glasses", "l10_midpoint", "MCTQ", 140, 810,
  "glasses", "l10_midpoint", "MEQ", 141, 816,
  "glasses", "last_timing_above_250", "MCTQ", 140, 683,
  "glasses", "last_timing_above_250", "MEQ", 141, 687,
  "glasses", "longest_period_midpoint", "MCTQ", 131, 478,
  "glasses", "longest_period_midpoint", "MEQ", 132, 482,
  "glasses", "m10_midpoint", "MCTQ", 140, 810,
  "glasses", "m10_midpoint", "MEQ", 141, 816,
  "glasses", "mean_timing_above_250", "MCTQ", 140, 736,
  "glasses", "mean_timing_above_250", "MEQ", 141, 742
)
observed_primary_samples <- frames |>
  filter(
    .data$data_scenario_id == "primary",
    .data$sample_scenario == "all_available"
  ) |>
  arrange(.data$placement, .data$metric_id, .data$instrument_id) |>
  select(
    "placement",
    "metric_id",
    "instrument_id",
    "participants",
    "participant_days"
  )
stopifnot(isTRUE(all.equal(observed_primary_samples, expected_primary_samples)))

fit_index <- read_h09("artifacts/07_models/H09/H09_model_fit_index.csv")
effects <- read_h09("artifacts/09_tables/H09/H09_model_effects.csv")
model_tests <- read_h09("artifacts/09_tables/H09/H09_model_tests.csv")
master <- read_h09("artifacts/09_tables/H09/H09_model_results_master.csv")
family_audit <- read_h09("artifacts/09_tables/H09/H09_family_audit.csv")

stopifnot(
  nrow(fit_index) == 540L,
  all(fit_index$fit_status == "FITTED"),
  all(fit_index$positive_definite_hessian),
  all(fit_index$fixed_full_rank),
  sum(!fit_index$converged) == 3L,
  sum(fit_index$singular) == 3L,
  all(
    fit_index$frame_id[fit_index$singular] %in% c(
      "primary__chest__all_available__longest_period_midpoint__MEQ",
      "primary__glasses__paired_common__longest_period_midpoint__MEQ",
      "primary__chest__paired_common__longest_period_midpoint__MEQ"
    )
  ),
  all(fit_index$fit_id[fit_index$singular] == "ML_M2_interaction"),
  nrow(effects) == 108L,
  all(effects$effect_status == "PASS"),
  nrow(model_tests) == 240L,
  sum(model_tests$comparison_status == "PASS") == 216L,
  sum(model_tests$comparison_status == "NON_ESTIMABLE") == 24L,
  sum(!is.na(model_tests$family_id)) == 200L,
  sum(is.na(model_tests$family_id)) == 40L,
  nrow(master) == 108L,
  all(master$interval_method == "Wald normal 95% confidence interval"),
  nrow(family_audit) == 40L,
  all(family_audit$planned_members == 5L),
  all(family_audit$registered_rows == 5L),
  all(family_audit$complete_registered_family),
  all(family_audit$independent_recalculation_matches),
  all(family_audit$family_assessment == "acceptable")
)

for (family_id in unique(model_tests$family_id[!is.na(model_tests$family_id)])) {
  rows <- model_tests$family_id == family_id & is.finite(model_tests$p_raw)
  expected_adjusted <- stats::p.adjust(
    model_tests$p_raw[rows],
    method = "BH",
    n = 5L
  )
  stopifnot(isTRUE(all.equal(
    model_tests$p_adjusted[rows],
    expected_adjusted,
    tolerance = 1e-12
  )))
}
finite_tests <- is.finite(model_tests$p_raw)
finite_adjusted <- is.finite(model_tests$p_adjusted)
stopifnot(
  all(
    model_tests$raw_significant[finite_tests] ==
      (model_tests$p_raw[finite_tests] < 0.05)
  ),
  all(
    model_tests$adjusted_significant[finite_adjusted] ==
      (model_tests$p_adjusted[finite_adjusted] < 0.05)
  )
)

primary_registered <- master |>
  filter(
    .data$data_scenario_id == "primary",
    .data$sample_scenario == "all_available",
    .data$primary_family_member
  )
stopifnot(
  nrow(primary_registered) == 20L,
  sum(primary_registered$main_adjusted_significant) == 10L,
  !any(primary_registered$interaction_adjusted_significant),
  all(is.finite(primary_registered$estimate)),
  all(is.finite(primary_registered$conf_low)),
  all(is.finite(primary_registered$conf_high))
)

score_audit <- read_h09(
  "artifacts/08_diagnostics/H09/H09_chronotype_score_audit.csv"
)
value_audit <- read_h09(
  "artifacts/08_diagnostics/H09/H09_chronotype_value_audit.csv"
)
fit_gates <- read_h09("artifacts/08_diagnostics/H09/H09_fit_gates.csv")
diagnostic_registry <- read_h09(
  "artifacts/08_diagnostics/H09/H09_diagnostic_assessment_registry.csv"
)
diagnostic_summary <- read_h09(
  "artifacts/08_diagnostics/H09/H09_diagnostic_target_summary.csv"
)
diagnostic_adjudication <- read_h09(
  "artifacts/08_diagnostics/H09/H09_diagnostic_author_adjudication.csv"
)
residual_diagnostics <- read_h09(
  "artifacts/08_diagnostics/H09/H09_residual_diagnostics.csv"
)
influence <- read_h09(
  "artifacts/08_diagnostics/H09/H09_participant_influence_summary.csv"
)
serial <- read_h09(
  "artifacts/08_diagnostics/H09/H09_serial_diagnostics.csv"
)
linearity <- read_h09(
  "artifacts/08_diagnostics/H09/H09_linearity_diagnostics.csv"
)

stopifnot(
  score_audit$participants == 186L,
  score_audit$mctq_complete == 185L,
  score_audit$mctq_missing == 1L,
  score_audit$meq_complete == 186L,
  score_audit$meq_missing == 0L,
  grepl("H09-G4", score_audit$provenance_assessment),
  nrow(value_audit) == 295L,
  all(value_audit$mctq_value_matches),
  all(value_audit$meq_value_matches),
  nrow(fit_gates) == 24L,
  sum(fit_gates$convergence_assessment == "not acceptable") == 1L,
  sum(fit_gates$singularity_assessment == "not acceptable") == 1L,
  all(fit_gates$rank_assessment == "acceptable"),
  nrow(diagnostic_registry) == 24L * 16L,
  all(
    diagnostic_registry$assessment %in%
      c("acceptable", "not acceptable")
  ),
  "assessment_basis" %in% names(diagnostic_registry),
  all(
    diagnostic_registry$assessment[
      diagnostic_registry$domain %in% c(
        "Response and residual distribution",
        "Residual heteroscedasticity"
      )
    ] == "acceptable"
  ),
  all(grepl(
    "H09-002",
    diagnostic_registry$assessment_basis[
      diagnostic_registry$domain %in% c(
        "Response and residual distribution",
        "Residual heteroscedasticity"
      )
    ]
  )),
  nrow(diagnostic_summary) == 24L,
  sum(diagnostic_summary$overall_assessment == "acceptable") == 18L,
  sum(diagnostic_summary$overall_assessment == "not acceptable") == 6L,
  nrow(diagnostic_adjudication) == 48L,
  all(diagnostic_adjudication$decision_id == "H09-002"),
  all(diagnostic_adjudication$author_final_assessment == "acceptable"),
  sum(diagnostic_adjudication$numeric_flag_overridden) == 12L,
  identical(
    sort(unique(diagnostic_adjudication$figure)),
    c("Figure 2", "Figure 3")
  ),
  nrow(residual_diagnostics) == 24L,
  sum(residual_diagnostics$distribution_assessment == "not acceptable") == 14L,
  sum(
    residual_diagnostics$heteroscedasticity_assessment == "not acceptable"
  ) == 4L,
  nrow(influence) == 24L,
  all(influence$failed_deletions == 0L),
  all(influence$participants_checked == influence$participants),
  sum(influence$influence_assessment == "not acceptable") == 2L,
  nrow(serial) == 24L,
  all(
    diagnostic_registry$assessment[
      diagnostic_registry$domain == "Temporal dependence"
    ] == "acceptable"
  ),
  nrow(linearity) == 24L,
  all(linearity$linearity_assessment == "acceptable")
)

gap <- read_h09(
  "artifacts/09_tables/H09/H09_gap_timing_unaware_sensitivity.csv"
)
paired <- read_h09(
  "artifacts/09_tables/H09/H09_paired_placement_effects.csv"
)
fifth <- read_h09(
  "artifacts/09_tables/H09/H09_fifth_outcome_sensitivity.csv"
)
photoperiod <- read_h09(
  "artifacts/09_tables/H09/H09_photoperiod_sensitivity.csv"
)
participant <- read_h09(
  "artifacts/09_tables/H09/H09_participant_summary_sensitivity.csv"
)
ar1 <- read_h09("artifacts/09_tables/H09/H09_ar1_sensitivity.csv")
l10 <- read_h09("artifacts/09_tables/H09/H09_l10_cut_sensitivity.csv")
v0 <- read_h09("artifacts/09_tables/H09/H09_v0_reproduction.csv")
v0_comparison <- read_h09(
  "artifacts/09_tables/H09/H09_v0_to_stage2_comparison.csv"
)

longest_gap <- gap$metric_id == "longest_period_midpoint"
available_gap <- !longest_gap
stopifnot(
  nrow(gap) == 24L,
  sum(longest_gap) == 4L,
  all(is.finite(gap$primary_all_estimate[longest_gap])),
  all(is.na(gap$gap_all_estimate[longest_gap])),
  all(gap$all_available_stability[longest_gap] == "non-estimable"),
  all(gap$common_sample_stability[longest_gap] == "non-estimable"),
  all(gap$exact_common_keys[available_gap]),
  nrow(paired) == 10L,
  all(paired$exact_sample_match),
  all(grepl("Not estimated", paired$difference_interval_status)),
  all(grepl("Not assessed", paired$equivalence_status)),
  nrow(fifth) == 8L,
  identical(
    sort(unique(fifth$metric_id)),
    sort(c("longest_period_midpoint", "mean_timing_above_250"))
  ),
  nrow(photoperiod) == 24L,
  nrow(participant) == 24L,
  nrow(ar1) == 24L,
  nrow(l10) == 4L,
  nrow(v0) == 10L,
  nrow(v0_comparison) == 10L,
  all(grepl("Not acceptable", v0_comparison$scalar_adjustment_assessment))
)

figure_manifest <- read_h09(
  "artifacts/12_manifests/H09/H09_figure_manifest.csv"
)
execution <- read_h09(
  "artifacts/12_manifests/H09/H09_execution_record.csv"
)
artifact_manifest <- read_h09(
  "artifacts/12_manifests/H09/H09_stage2_artifacts.csv"
)
manifest_absolute_paths <- file.path(root, artifact_manifest$path)
stopifnot(
  nrow(figure_manifest) == 6L,
  all(file.exists(file.path(root, figure_manifest$figure_path))),
  all(file.exists(file.path(root, figure_manifest$pdf_path))),
  all(file.exists(file.path(root, figure_manifest$source_data_path))),
  all(figure_manifest$effective_final_text_pt >= 5),
  all(grepl("^PASS", figure_manifest$visual_qa_status)),
  all(nzchar(figure_manifest$alt_text)),
  execution$r_version == "4.6.1",
  execution$model_frames == 108L,
  execution$fitted_model_objects == 540L,
  execution$diagnostic_targets == 24L,
  execution$production_resampling_replicates == 0L,
  grepl("NOT NEEDED", execution$resampling_gate_status),
  nrow(artifact_manifest) > 40L,
  !"artifacts/12_manifests/H09/H09_stage3_artifacts.csv" %in%
    artifact_manifest$path,
  all(file.exists(manifest_absolute_paths)),
  all(
    vapply(
      manifest_absolute_paths,
      artifact_sha256,
      character(1)
    ) == artifact_manifest$sha256
  )
)

report_paths <- file.path(
  root,
  "audit/hypotheses/H09",
  c(
    "02_implementation_and_v0_comparison.qmd",
    "02_implementation_and_v0_comparison.html"
  )
)
stopifnot(all(file.exists(report_paths)))
report_source <- paste(readLines(report_paths[1], warn = FALSE), collapse = "\n")
stopifnot(
  grepl("Stage 2 gate", report_source, fixed = TRUE),
  grepl("gap-timing-unaware dataset", report_source, fixed = TRUE),
  grepl("pinned aggregate", report_source, fixed = TRUE),
  !grepl("temperature", report_source, ignore.case = TRUE)
)

display_boundary <- nh_format_p_value(c(0.0009999, 0.001, 0.247, NA_real_))
stopifnot(identical(display_boundary, c("<0.001", "0.001", "0.247", "—")))

cat("H09 Stage 2 tests passed\n")
