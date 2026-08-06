# Focused output-integrity tests for the complete H11 Stage 2 run.

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(tibble)
})

options(
  stringsAsFactors = FALSE,
  scipen = 999,
  dplyr.summarise.inform = FALSE
)

test_argument <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
if (length(test_argument) != 1L) {
  stop("Could not determine the H11 Stage 2 output test location", call. = FALSE)
}
test_path <- normalizePath(
  sub("^--file=", "", test_argument),
  winslash = "/",
  mustWork = TRUE
)
root <- dirname(dirname(dirname(dirname(test_path))))

source(file.path(root, "scripts/hypotheses/H02/h02_contract.R"))
source(file.path(root, "scripts/hypotheses/H02/h02_modeling.R"))
source(file.path(root, "scripts/hypotheses/H02/h02_dominance.R"))
source(file.path(root, "scripts/hypotheses/H11/h11_stage1.R"))
source(file.path(root, "scripts/hypotheses/H11/h11_stage2.R"))
source(file.path(root, "scripts/pipeline/p_value_display.R"))
paths <- h11_stage2_paths(root)

read_output <- function(directory, filename) {
  path <- file.path(directory, filename)
  stopifnot(file.exists(path), file.info(path)$size > 0)
  readr::read_csv(path, show_col_types = FALSE)
}

message("Testing exact fitted samples and model identities")
samples <- read_output(paths$tables, "sample_counts.csv")
models <- read_output(paths$tables, "model_fit_summary.csv")
rho <- read_output(paths$tables, "rho_summary.csv")
comparisons <- read_output(paths$tables, "model_comparisons.csv")
expected <- tibble::tribble(
  ~run_id, ~participants, ~participant_days, ~observations_30_minute, ~sites,
  "main__glasses__all_available", 141L, 816L, 37756L, 9L,
  "main__chest__all_available", 154L, 902L, 41842L, 8L,
  "manuscript_prepared_data__glasses__all_available", 141L, 809L, 37603L, 9L,
  "manuscript_prepared_data__chest__all_available", 154L, 894L, 41664L, 8L
)
observed <- samples |>
  dplyr::select(
    "run_id", "participants", "participant_days",
    "observations_30_minute", "sites"
  ) |>
  dplyr::arrange(match(.data$run_id, expected$run_id))
stopifnot(
  isTRUE(all.equal(observed, expected, check.attributes = FALSE)),
  nrow(models) == 8L,
  nrow(rho) == 4L,
  nrow(comparisons) == 12L,
  all(is.finite(rho$rho)),
  all(abs(rho$rho) <= 0.95),
  all(models$n == samples$observations_30_minute[
    match(models$run_id, samples$run_id)
  ]),
  all(models$frame_sha256 == samples$frame_sha256[
    match(models$run_id, samples$run_id)
  ]),
  all(models$R_version == "4.6.1"),
  all(models$mgcv_version == "1.9.4")
)
model_contract <- tibble::tribble(
  ~model_id, ~method, ~discrete,
  "mpattern_preliminary_rho0_fREML", "fREML", TRUE,
  "mpattern_final_fREML", "fREML", TRUE
)
stopifnot(all(vapply(seq_len(nrow(model_contract)), function(index) {
  selected <- models$method[models$model_id == model_contract$model_id[index]]
  discrete <- models$discrete[models$model_id == model_contract$model_id[index]]
  length(selected) == 4L &&
    all(selected == model_contract$method[index]) &&
    all(discrete == model_contract$discrete[index])
}, logical(1))))

message("Testing exact multiplicity families and robust post-fit tests")
family_sizes <- comparisons |>
  dplyr::count(.data$run_id, .data$family_id, name = "observed") |>
  dplyr::left_join(
    comparisons |>
      dplyr::distinct(.data$run_id, .data$family_id, .data$planned_n),
    by = c("run_id", "family_id"),
    relationship = "one-to-one"
  )
stopifnot(
  all(family_sizes$observed == family_sizes$planned_n),
  all(comparisons$p_raw >= 0 & comparisons$p_raw <= 1),
  all(comparisons$p_adjusted_BH >= 0 & comparisons$p_adjusted_BH <= 1),
  all(comparisons$test_df > 0),
  all(comparisons$denominator_df > 0),
  all(comparisons$test_statistic >= 0),
  all(is.na(comparisons$reduced_AIC)),
  all(is.na(comparisons$full_AIC)),
  all(is.na(comparisons$delta_AIC_reduced_minus_full)),
  all(grepl("participant-cluster CR1 Wald", comparisons$test_method, fixed = TRUE)),
  all(grepl("Participant-summed AR-whitened scores", comparisons$covariance_method, fixed = TRUE)),
  all(comparisons$comparison_role == "global" |
    comparisons$comparison_role == "decomposition"),
  all(comparisons$support_status %in% c(
    "supported",
    "not_supported",
    "decomposition_component_supported",
    "decomposition_component_not_supported"
  )),
  all(is.na(comparisons$AIC_supported)),
  all(comparisons$adjusted_p_supported ==
    (comparisons$p_adjusted_BH < 0.05))
)
stopifnot(
  setequal(
    unique(models$model_id),
    c("mpattern_preliminary_rho0_fREML", "mpattern_final_fREML")
  ),
  all(models$method == "fREML"),
  all(models$discrete)
)

message("Testing pointwise curve outputs and midnight closure")
curves <- read_output(
  paths$source_data,
  "sex_specific_curves_pointwise.csv"
)
contrast <- read_output(
  paths$source_data,
  "female_minus_male_pointwise_contrasts.csv"
)
closure <- read_output(paths$diagnostics, "cyclic_curve_closure.csv")
parametric <- read_output(paths$tables, "parametric_sex_component.csv")
stopifnot(
  nrow(curves) == 4L * 2L * 48L,
  nrow(contrast) == 4L * 48L,
  nrow(closure) == 4L * 2L,
  nrow(parametric) == 4L,
  all(curves$lower_eta_pointwise_95 <= curves$eta),
  all(curves$upper_eta_pointwise_95 >= curves$eta),
  all(contrast$ratio_lower_pointwise_95 <=
    contrast$female_to_male_shifted_ratio),
  all(contrast$ratio_upper_pointwise_95 >=
    contrast$female_to_male_shifted_ratio),
  all(grepl("not simultaneous", curves$interval_scope, fixed = TRUE)),
  all(grepl("cannot identify", contrast$interval_scope, fixed = TRUE)),
  all(closure$cyclic_closure_verified),
  max(abs(closure$midnight_value_jump_eta)) <= 1e-8,
  all(parametric$shifted_ratio_lower_95 <= parametric$shifted_ratio),
  all(parametric$shifted_ratio_upper_95 >= parametric$shifted_ratio)
)

message("Testing diagnostics and explicit acceptance assessments")
acf <- read_output(paths$diagnostics, "boundary_aware_residual_acf.csv")
residual <- read_output(paths$diagnostics, "residual_summary.csv")
k_check <- read_output(paths$diagnostics, "basis_dimension_check.csv")
site_constraint <- read_output(
  paths$diagnostics,
  "site_sum_to_zero_constraint.csv"
)
assessment <- read_output(paths$diagnostics, "diagnostic_assessment.csv")
concurvity <- read_output(paths$diagnostics, "formal_concurvity.csv")
robust_diagnostics <- read_output(
  paths$diagnostics,
  "robust_inference_diagnostics.csv"
)
stopifnot(
  nrow(acf) == 4L * 2L * 12L,
  nrow(residual) == 4L * 3L,
  nrow(site_constraint) == 4L,
  nrow(assessment) == 4L,
  nrow(robust_diagnostics) == 4L,
  nrow(k_check) > 0L,
  nrow(concurvity) > 0L,
  all(site_constraint$sum_to_zero_constraint_verified),
  all(assessment$classification %in% c(
    "acceptable with specified limitations",
    "not acceptable for inference"
  )),
  all(nzchar(assessment$plain_language_interpretation)),
  all(robust_diagnostics$residual_contract_maximum_absolute_error == 0),
  all(robust_diagnostics$delete_one_participant_p_maximum < 0.05),
  all(robust_diagnostics$maximum_participant_unscaled_meat_share < 0.10),
  all(robust_diagnostics$method_status ==
    "accepted_H11_METHOD_001_through_007")
)

message("Testing the conditional effect-size gate and pilot-only computation")
gate <- read_output(paths$tables, "effect_size_gate.csv")
stopifnot(
  nrow(gate) == 2L,
  all(gate$effect_size_gate_open == (gate$p_raw < 0.050)),
  all(gate$effect_size_gate_open == (gate$support_status == "supported"))
)
open_runs <- gate$run_id[gate$effect_size_gate_open]
pilot_path <- file.path(paths$tables, "effect_size_pilot_50rep.csv")
variation_path <- file.path(paths$tables, "effect_size_curve_variation.csv")
if (length(open_runs) > 0L) {
  pilot <- read_output(paths$tables, "effect_size_pilot_50rep.csv")
  variation <- read_output(paths$tables, "effect_size_curve_variation.csv")
  stopifnot(
    setequal(unique(pilot$run_id), open_runs),
    setequal(unique(variation$run_id), open_runs),
    nrow(pilot) == length(open_runs) * 5L,
    nrow(variation) == length(open_runs),
    all(pilot$bootstrap_replicates == 50L),
    all(pilot$bootstrap_failed_replicates == 0L),
    all(grepl("PILOT", pilot$interval_method, fixed = TRUE)),
    all(is.finite(pilot$projected_2000_seconds_point)),
    all(variation$lower_95 <= variation$estimate),
    all(variation$upper_95 >= variation$estimate)
  )
} else {
  stopifnot(file.exists(pilot_path), file.exists(variation_path))
}

message("Testing the V0/model/preparation separation and deferred registry")
v0 <- read_output(paths$tables, "v0_new_implementation_comparison.csv")
preparation <- read_output(paths$tables, "data_preparation_comparison.csv")
deferred <- read_output(paths$model_data, "deferred_analysis_registry.csv")
reporting <- read_output(paths$model_data, "reporting_decision_record.csv")
paired_display <- read_output(
  paths$model_data,
  "paired_placement_display_assessment.csv"
)
figure_manifest <- read_output(
  paths$manifests,
  "H11_stage2_figure_manifest.csv"
)
figure_qa <- read_output(
  paths$manifests,
  "H11_stage2_figure_readability_qa.csv"
)
stopifnot(
  nrow(v0) == 6L,
  nrow(preparation) == 2L,
  nrow(deferred) == 6L,
  all(c(
    "V0 recovered result",
    "New implementation on gap-timing-unaware data",
    "New implementation on main repaired data"
  ) %in% v0$comparison_layer),
  all(nzchar(v0$change_attributed_to)),
  all(nzchar(deferred$could_change_interpretation)),
  nrow(reporting) == 7L,
  all(reporting$verified),
  all(c(
    "REPORT-008", "REPORT-009", "REPORT-010", "REPORT-011", "REPORT-012",
    "H11-REPORT-010-APPLICATION"
  ) %in% reporting$decision_id),
  nrow(paired_display) == 1L,
  paired_display$stored_paired_frame_participants == 112L,
  paired_display$stored_paired_frame_participant_days == 643L,
  paired_display$stored_paired_frame_observations == 29786L,
  paired_display$stored_paired_frame_sites == 8L,
  paired_display$stored_h02_paired_frames_available,
  !paired_display$h11_paired_fitted_outputs_available,
  !paired_display$predeclared_scalar_temporal_estimand_available,
  !paired_display$scalar_identity_plot_applicable,
  is.na(paired_display$paired_source_data_csv),
  paired_display$all_available_near_eye_participants !=
    paired_display$all_available_chest_participants,
  paired_display$all_available_near_eye_observations !=
    paired_display$all_available_chest_observations,
  nrow(figure_manifest) == 10L,
  all(figure_manifest$policy_id == "REPORT-011"),
  all(figure_manifest$minimum_important_text_pt >= 7),
  all(figure_manifest$canvas_width_inches > 0),
  all(figure_manifest$canvas_height_inches > 0),
  setequal(
    unique(figure_qa$figure_id),
    c(
      "h11_near_eye_pointwise",
      "h11_chest_pointwise",
      "h11_v0_prepared_near_eye_pointwise",
      "h11_v0_prepared_chest_pointwise",
      "h11_near_eye_pointwise_residual_acf",
      "h11_chest_pointwise_residual_acf",
      "v0_near_eye_frozen",
      "v0_chest_frozen"
    )
  ),
  all(figure_qa$minimum_important_text_pt >= 7),
  all(figure_qa$no_clipping),
  all(figure_qa$no_overlap),
  all(figure_qa$undistorted_text),
  all(figure_qa$wrapping_acceptable),
  all(figure_qa$important_text_readable),
  all(figure_qa$data_region_proportionate),
  all(figure_qa$marks_distinguishable),
  all(figure_qa$colour_greyscale_caption_alt_text_pass),
  all(figure_qa$overall_status == "PASS")
)

formatted <- nh_p_value_display(
  comparisons$p_adjusted_BH,
  comparisons$p_adjusted_BH < 0.05,
  na_label = "—"
)
stopifnot(
  all(grepl("^(<0\\.001|0\\.[0-9]{3}|1\\.000)$", formatted$p_display)),
  identical(formatted$p_bold, comparisons$p_adjusted_BH < 0.05)
)

display_code <- paste(
  readLines(
    file.path(root, "scripts/hypotheses/H11/build_h11_stage2_displays.R"),
    warn = FALSE
  ),
  collapse = "\n"
)
stopifnot(
  !grepl("mgcv::bam[[:space:]]*\\(", display_code, perl = TRUE),
  !grepl("mgcv::gam[[:space:]]*\\(", display_code, perl = TRUE),
  !grepl("bootstrap", display_code, ignore.case = TRUE) ||
    grepl("does not fit, refit, bootstrap", display_code, fixed = TRUE)
)

cat("H11 Stage 2 focused output tests: PASS\n")
