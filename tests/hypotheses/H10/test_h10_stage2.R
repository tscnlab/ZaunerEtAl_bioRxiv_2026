# Verify the author-approved H10 Stage 2 contract and generated artifacts.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)

project_library <- file.path(
  root,
  "renv/library/macos/R-4.6/aarch64-apple-darwin23"
)
if (!dir.exists(project_library)) {
  stop("The authoritative R 4.6 project library is unavailable", call. = FALSE)
}
.libPaths(c(project_library, .libPaths()))

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(tibble)
})

source(file.path(root, "scripts/pipeline/paths_io.R"))
source(file.path(root, "scripts/pipeline/p_value_display.R"))
source(file.path(root, "scripts/hypotheses/H10/h10_contract.R"))

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("H10 Stage 2 tests require R 4.6.1", call. = FALSE)
}

read_h10 <- function(...) {
  readr::read_csv(
    file.path(root, ...),
    show_col_types = FALSE,
    na = ""
  )
}

for (path in c(
  "scripts/hypotheses/H10/h10_contract.R",
  "scripts/hypotheses/H10/h10_modeling.R",
  "scripts/hypotheses/H10/run_h10_stage2.R",
  "scripts/hypotheses/H10/run_h10_metric010_update.R",
  "scripts/hypotheses/H10/audit_h10_metric010_multiplicity_changes.R",
  "scripts/hypotheses/H10/build_h10_metric010_figures.R",
  "scripts/hypotheses/H10/run_h10_metric011_update.R",
  "scripts/hypotheses/H10/build_h10_metric011_figures.R",
  "tests/hypotheses/H10/test_h10_stage2.R"
)) {
  invisible(parse(file = file.path(root, path)))
}

####
# Approved contract, formulas, and input pins
####

h10_validate_contract()
metrics <- h10_metric_registry()
comparisons <- h10_comparison_registry()
approvals <- h10_approval_registry()
input_contract <- h10_input_contract(root)

tbt10 <- metrics |>
  filter(.data$metric_id == "duration_below_10_pre_sleep")
mder <- metrics |>
  filter(.data$metric_id == "mder_mean_of_viable_ratios")
stopifnot(
  nrow(metrics) == 17L,
  nrow(comparisons) == 4L,
  all(comparisons$planned_n == 17L),
  nrow(approvals) == 13L,
  all(approvals$approved),
  nrow(tbt10) == 1L,
  tbt10$response_family == "gaussian",
  tbt10$response_transform == "identity",
  tbt10$effect_scale == "difference",
  nrow(mder) == 1L,
  mder$response_family == "gaussian",
  mder$response_transform == "identity",
  mder$effect_scale == "difference",
  nrow(input_contract) == 36L,
  all(c(
    "metric_manifest",
    "site_context_manifest",
    "base_manifest",
    "metric011_decision",
    "metric011_evidence_manifest",
    "mder_decision",
    "mder_audit_manifest",
    "state_support_manifest",
    "gap_mder_support",
    "gap_preparation_manifest",
    "primary_h01_prepared_manifest",
    "gap_h01_prepared_manifest",
    "preanalysis_comparison_manifest",
    "gap_repair_evidence_manifest",
    "downstream_rebuild_manifest"
  ) %in% input_contract$input_role)
)

participant_formulas <- vapply(
  h10_formula_set("participant"),
  deparse1,
  character(1)
)
participant_day_formulas <- vapply(
  h10_formula_set("participant_day"),
  deparse1,
  character(1)
)
stopifnot(
  identical(
    unname(participant_formulas),
    c(
      "response ~ site",
      "response ~ site + age_decade",
      "response ~ site * age_decade",
      "response ~ site + biological_sex",
      "response ~ site * biological_sex"
    )
  ),
  identical(
    unname(participant_day_formulas),
    c(
      "response ~ site + (1 | site:Id)",
      "response ~ site + age_decade + (1 | site:Id)",
      "response ~ site * age_decade + (1 | site:Id)",
      "response ~ site + biological_sex + (1 | site:Id)",
      "response ~ site * biological_sex + (1 | site:Id)"
    )
  ),
  !any(grepl(
    "temperature|weather|gender",
    c(
      participant_formulas,
      participant_day_formulas
    ),
    ignore.case = TRUE
  ))
)

stopifnot(
  all(file.exists(input_contract$absolute_path)),
  all(
    vapply(
      input_contract$absolute_path,
      artifact_sha256,
      character(1)
    ) ==
      input_contract$expected_sha256
  )
)

input_audit <- read_h10("artifacts/06_model_data/H10/H10_input_audit.csv")
provenance <- read_h10(
  "artifacts/06_model_data/H10/H10_provenance_qualification.csv"
)
stopifnot(
  nrow(input_audit) == nrow(input_contract),
  all(input_audit$exists),
  all(input_audit$hash_verified),
  any(grepl("PREP-003/FIND-044", unlist(provenance), fixed = TRUE)),
  any(grepl(
    "not evidence that stored values are incorrect",
    unlist(provenance),
    fixed = TRUE
  )),
  any(grepl(
    "METRIC-010 MDER values were independently verified",
    unlist(provenance),
    fixed = TRUE
  )),
  any(grepl(
    "FIND-049/CHG-101",
    unlist(provenance),
    fixed = TRUE
  )),
  any(grepl(
    "METRIC-011 normalized eight primary L10 means",
    unlist(provenance),
    fixed = TRUE
  ))
)

####
# Model frames, fits, confidence intervals, and multiplicity
####

frames <- read_h10(
  "artifacts/06_model_data/H10/H10_model_frame_index.csv"
)
demographic_cells <- read_h10(
  "artifacts/06_model_data/H10/H10_demographic_coding_and_site_cells.csv"
)
model_manifest <- read_h10(
  "artifacts/07_models/H10/H10_model_manifest.csv"
)
effects <- read_h10("artifacts/09_tables/H10/H10_model_effects.csv")
model_tests <- read_h10("artifacts/09_tables/H10/H10_model_tests.csv")
family_audit <- read_h10(
  "artifacts/09_tables/H10/H10_multiplicity_family_audit.csv"
)

stopifnot(
  nrow(frames) == 68L,
  all(table(frames$run_id) == 17L),
  all(frames$observations > 0L),
  all(frames$participants > 0L),
  all(frames$sites >= 8L),
  all(nzchar(frames$row_key_hash)),
  all(nzchar(frames$model_frame_sha256)),
  nrow(demographic_cells) > 0L,
  all(demographic_cells$biological_sex %in% c("Male", "Female"))
)

stopifnot(
  nrow(model_manifest) == 612L,
  all(model_manifest$fit_status == "FITTED"),
  all(model_manifest$converged),
  all(model_manifest$positive_definite_hessian),
  all(!model_manifest$singular),
  all(model_manifest$fixed_full_rank),
  all(is.na(model_manifest$warnings) | !nzchar(model_manifest$warnings)),
  all(is.na(model_manifest$error) | !nzchar(model_manifest$error)),
  nrow(effects) == 136L,
  all(effects$estimate_status == "ESTIMABLE"),
  all(is.finite(effects$standard_error)),
  all(is.finite(effects$conf_low_model)),
  all(is.finite(effects$conf_high_model)),
  all(effects$conf_low_model <= effects$estimate_model),
  all(effects$estimate_model <= effects$conf_high_model),
  all(
    effects$interval_distribution == "normal" |
      grepl("^t\\([0-9]+\\)$", effects$interval_distribution)
  )
)
interval_degrees_freedom <- suppressWarnings(as.numeric(sub(
  "^t\\(([0-9]+)\\)$",
  "\\1",
  effects$interval_distribution
)))
interval_critical <- ifelse(
  effects$interval_distribution == "normal",
  stats::qnorm(0.975),
  stats::qt(0.975, interval_degrees_freedom)
)
stopifnot(
  isTRUE(all.equal(
    effects$conf_low_model,
    effects$estimate_model - interval_critical * effects$standard_error,
    tolerance = 1e-12
  )),
  isTRUE(all.equal(
    effects$conf_high_model,
    effects$estimate_model + interval_critical * effects$standard_error,
    tolerance = 1e-12
  ))
)

stopifnot(
  nrow(model_tests) == 272L,
  all(model_tests$comparison_status == "ESTIMABLE"),
  nrow(family_audit) == 16L,
  all(family_audit$planned_n == 17L),
  all(family_audit$registered_rows == 17L),
  all(family_audit$complete_17_member_family),
  all(family_audit$independent_recalculation_matches)
)
for (family_id in unique(model_tests$family_id)) {
  rows <- model_tests$family_id == family_id
  reproduced <- stats::p.adjust(
    model_tests$p_raw[rows],
    method = "BH",
    n = 17L
  )
  stopifnot(isTRUE(all.equal(
    model_tests$p_adjusted[rows],
    reproduced,
    tolerance = 1e-14
  )))
}
stopifnot(
  all(model_tests$raw_significant == (model_tests$p_raw < 0.05)),
  all(
    model_tests$adjusted_significant == (model_tests$p_adjusted < 0.05)
  ),
  identical(
    nh_format_p_value(c(0.001, 0.000999, 0.05)),
    c("0.001", "<0.001", "0.050")
  )
)

####
# Primary results and the Gaussian pre-sleep TBT10 amendment
####

primary_main <- read_h10(
  "artifacts/09_tables/H10/H10_primary_main_results.csv"
)
primary_interactions <- read_h10(
  "artifacts/09_tables/H10/H10_primary_interaction_results.csv"
)

expected_main_findings <- c(
  "chest|age|daily_geometric_mean_medi",
  "chest|age|m10_mean_medi",
  "chest|age|duration_above_1000",
  "chest|age|duration_above_250_wake",
  "chest|age|longest_bout_above_250",
  "chest|age|dose_time_sensitive_corrected_medi",
  "chest|biological_sex|daily_geometric_mean_medi",
  "chest|biological_sex|l10_mean_medi",
  "glasses|age|m10_mean_medi",
  "glasses|age|duration_above_1000",
  "glasses|age|dose_time_sensitive_corrected_medi"
)
observed_main_findings <- primary_main |>
  filter(.data$adjusted_significant) |>
  transmute(
    key = paste(.data$placement, .data$predictor, .data$metric_id, sep = "|")
  ) |>
  pull(.data$key)
expected_interaction_findings <- c(
  "chest|AGE-SITE|m10_midpoint",
  "chest|AGE-SITE|last_timing_above_250"
)
observed_interaction_findings <- primary_interactions |>
  filter(.data$adjusted_significant) |>
  transmute(
    key = paste(
      .data$placement,
      .data$comparison_id,
      .data$metric_id,
      sep = "|"
    )
  ) |>
  pull(.data$key)

stopifnot(
  nrow(primary_main) == 68L,
  setequal(observed_main_findings, expected_main_findings),
  nrow(primary_interactions) == 68L,
  setequal(observed_interaction_findings, expected_interaction_findings),
  !any(
    primary_interactions$adjusted_significant[
      primary_interactions$comparison_id == "SEX-SITE"
    ]
  )
)

primary_tbt10 <- primary_main |>
  filter(.data$metric_id == "duration_below_10_pre_sleep")
chest_age_tbt10 <- primary_tbt10 |>
  filter(.data$placement == "chest", .data$predictor == "age")
stopifnot(
  nrow(primary_tbt10) == 4L,
  all(primary_tbt10$response_family == "gaussian"),
  all(primary_tbt10$response_transform == "identity"),
  all(primary_tbt10$practical_effect_type == "difference"),
  all(primary_tbt10$practical_unit == "h"),
  all(is.finite(primary_tbt10$estimate_minutes)),
  nrow(chest_age_tbt10) == 1L,
  abs(chest_age_tbt10$estimate_minutes - (-6.3213104)) < 1e-7,
  chest_age_tbt10$participants == 153L,
  chest_age_tbt10$participant_days == 743L
)

primary_mder <- primary_main |>
  filter(.data$metric_id == "mder_mean_of_viable_ratios")
gap_repair <- read_h10(
  "artifacts/06_model_data/H10/H10_METRIC010_gap_repair_record.csv"
)
stopifnot(
  nrow(primary_mder) == 4L,
  all(primary_mder$response_family == "gaussian"),
  all(primary_mder$response_transform == "identity"),
  all(primary_mder$practical_effect_type == "difference"),
  setequal(primary_mder$participants, c(137L, 152L)),
  setequal(primary_mder$participant_days, c(702L, 732L)),
  all(!primary_mder$adjusted_significant),
  nrow(gap_repair) == 1L,
  gap_repair$placement == "chest",
  gap_repair$site == "THUAS",
  gap_repair$Id == "THUAS_S002",
  as.Date(gap_repair$local_date) == as.Date("2025-03-09"),
  is.na(gap_repair$stored_mder),
  gap_repair$viable_ratio_minutes == 0L,
  !gap_repair$estimable,
  gap_repair$failure_reason == "no_viable_momentary_ratio",
  gap_repair$repair_status == "REPAIRED_IN_SHARED_PREPARATION"
)

####
# Diagnostics, sample-matched comparisons, and sensitivities
####

diagnostics <- read_h10(
  "artifacts/08_diagnostics/H10/H10_primary_diagnostic_assessment.csv"
)
participant_influence <- read_h10(
  "artifacts/08_diagnostics/H10/H10_participant_deletion_influence.csv"
)
site_influence <- read_h10(
  "artifacts/08_diagnostics/H10/H10_leave_one_site_out_summary.csv"
)
stopifnot(
  nrow(diagnostics) == 68L,
  sum(diagnostics$final_assessment == "acceptable") == 25L,
  sum(
    diagnostics$final_assessment == "acceptable with specified limitations"
  ) ==
    43L,
  !any(diagnostics$final_assessment == "not acceptable for inference"),
  sum(diagnostics$serial_status == "PASS_DESCRIPTIVE_CHECK") == 60L,
  sum(
    diagnostics$serial_status == "NOT_APPLICABLE_PARTICIPANT_LEVEL"
  ) ==
    8L,
  max(
    abs(diagnostics$pooled_consecutive_day_residual_correlation),
    na.rm = TRUE
  ) <
    0.30,
  all(diagnostics$prediction_bound_status == "PASS"),
  nrow(participant_influence) == 68L,
  all(participant_influence$deletion_status == "PASS_DESCRIPTIVE_CHECK"),
  max(participant_influence$change_in_full_standard_errors) < 0.50,
  nrow(site_influence) == 68L,
  all(site_influence$failed_or_nonconverged == 0L),
  max(site_influence$max_change_in_full_standard_errors) < 2
)

paired_audit <- read_h10(
  "artifacts/06_model_data/H10/H10_paired_placement_sample_audit.csv"
)
paired <- read_h10(
  paste0(
    "artifacts/08_diagnostics/H10/sensitivity/",
    "H10_paired_placement_main_effects.csv"
  )
)
gap_common_audit <- read_h10(
  "artifacts/06_model_data/H10/H10_primary_gap_common_sample_audit.csv"
)
gap_common <- read_h10(
  paste0(
    "artifacts/08_diagnostics/H10/sensitivity/",
    "H10_primary_gap_common_sample_effects.csv"
  )
)
excluded_people <- read_h10(
  "artifacts/06_model_data/H10/H10_preregistered_exclusion_participants.csv"
)
preregistered_exclusion <- read_h10(
  paste0(
    "artifacts/08_diagnostics/H10/sensitivity/",
    "H10_preregistered_exclusion_effects.csv"
  )
)
metric_sensitivities <- read_h10(
  paste0(
    "artifacts/08_diagnostics/H10/sensitivity/",
    "H10_metric_specific_sensitivities.csv"
  )
)
mder_amendment <- read_h10(
  "artifacts/09_tables/H10/H10_METRIC010_amendment_results.csv"
)
mder_distribution <- read_h10(
  paste0(
    "artifacts/08_diagnostics/H10/sensitivity/",
    "H10_mder_current_distribution.csv"
  )
)
mder_influence <- read_h10(
  paste0(
    "artifacts/08_diagnostics/H10/sensitivity/",
    "H10_mder_current_influence_assessment.csv"
  )
)
mder_identity <- read_h10(
  paste0(
    "artifacts/12_manifests/H10/",
    "H10_METRIC010_gap_repair_non_mder_identity_audit.csv"
  )
)
mder_primary_identity <- read_h10(
  paste0(
    "artifacts/12_manifests/H10/",
    "H10_METRIC010_gap_repair_primary_identity_audit.csv"
  )
)
mder_multiplicity <- read_h10(
  paste0(
    "artifacts/12_manifests/H10/",
    "H10_METRIC010_gap_repair_multiplicity_change_audit.csv"
  )
)
l10_cell_changes <- read_h10(
  "artifacts/06_model_data/H10/H10_METRIC011_l10_cell_changes.csv"
)
l10_identity <- read_h10(
  paste0(
    "artifacts/12_manifests/H10/",
    "H10_METRIC011_frozen_identity_audit.csv"
  )
)
l10_multiplicity <- read_h10(
  paste0(
    "artifacts/12_manifests/H10/",
    "H10_METRIC011_multiplicity_audit.csv"
  )
)
l10_update <- read_h10(
  paste0(
    "artifacts/12_manifests/H10/",
    "H10_METRIC011_update_summary.csv"
  )
)
waking_mder <- read_h10(
  paste0(
    "artifacts/08_diagnostics/H10/sensitivity/",
    "H10_waking_mder_unavailable.csv"
  )
)
stability <- read_h10(
  paste0(
    "artifacts/08_diagnostics/H10/sensitivity/",
    "H10_sensitivity_stability_summary.csv"
  )
)

unavailable_paired <- paired |>
  filter(.data$comparison_status == "UNAVAILABLE")
gap_mder <- mder_amendment |>
  filter(.data$data_scenario == "gap_timing_unaware")
paired_mder <- paired |>
  filter(.data$metric_id == "mder_mean_of_viable_ratios")
gap_paired_mder <- paired_mder |>
  filter(.data$data_scenario == "gap_timing_unaware")
primary_paired_mder <- paired_mder |>
  filter(.data$data_scenario == "primary")
common_mder <- gap_common |>
  filter(.data$metric_id == "mder_mean_of_viable_ratios")
gap_mder_distribution <- mder_distribution |>
  filter(.data$data_scenario == "gap_timing_unaware")
stopifnot(
  nrow(paired_audit) == 30L,
  all(paired_audit$exact_key_match),
  nrow(paired) == 136L,
  nrow(unavailable_paired) == 16L,
  all(
    unavailable_paired$metric_id %in%
      c(
        "interdaily_stability",
        "intradaily_variability"
      )
  ),
  all(grepl(
    "no approximation was made",
    unavailable_paired$unavailable_reason,
    fixed = TRUE
  )),
  all(
    paired$comparison_status[
      !paired$metric_id %in%
        c(
          "interdaily_stability",
          "intradaily_variability"
        )
    ] ==
      "ESTIMABLE"
  ),
  nrow(gap_common_audit) == 34L,
  all(gap_common_audit$exact_key_match),
  nrow(gap_common) == 136L,
  all(gap_common$comparison_status == "ESTIMABLE"),
  nrow(excluded_people) == 9L,
  nrow(preregistered_exclusion) == 68L,
  all(preregistered_exclusion$comparison_status == "ESTIMABLE"),
  nrow(metric_sensitivities) == 8L,
  all(metric_sensitivities$comparison_status == "ESTIMABLE"),
  !any(grepl("mder", metric_sensitivities$sensitivity_id, ignore.case = TRUE)),
  nrow(mder_amendment) == 8L,
  all(!mder_amendment$adjusted_significant),
  setequal(gap_mder$observations, c(687L, 723L)),
  setequal(gap_mder$participants, c(137L, 152L)),
  nrow(gap_paired_mder) == 4L,
  all(gap_paired_mder$participant_days == 478L),
  all(gap_paired_mder$participants == 107L),
  nrow(primary_paired_mder) == 4L,
  all(primary_paired_mder$participant_days == 489L),
  all(primary_paired_mder$participants == 107L),
  nrow(common_mder) == 8L,
  setequal(common_mder$participant_days, c(687L, 723L)),
  setequal(common_mder$participants, c(137L, 152L)),
  nrow(mder_distribution) == 38L,
  sum(
    mder_distribution$scope == "overall" &
      mder_distribution$data_scenario == "primary"
  ) == 2L,
  all(gap_mder_distribution$nonpositive_n == 0L),
  nrow(mder_influence) == 4L,
  all(mder_influence$metric_id == "mder_mean_of_viable_ratios"),
  all(mder_influence$deletion_status == "PASS_DESCRIPTIVE_CHECK"),
  all(mder_influence$final_assessment ==
    "acceptable with specified limitations"),
  nrow(mder_identity) == 16L,
  all(mder_identity$identity_status == "PASS"),
  nrow(mder_primary_identity) == 19L,
  all(mder_primary_identity$identity_status == "PASS"),
  nrow(mder_multiplicity) == 5L,
  all(mder_multiplicity$changed_adjusted_p_rows_above_1e_12 == 0L),
  all(mder_multiplicity$changed_adjusted_decision_rows == 0L),
  nrow(l10_cell_changes) == 8L,
  all(l10_cell_changes$data_scenario == "primary"),
  all(l10_cell_changes$metric_id == "l10_mean_medi"),
  sum(l10_cell_changes$placement == "glasses") == 3L,
  sum(l10_cell_changes$placement == "chest") == 5L,
  all(l10_cell_changes$old_value_lx == 4.163336342344337e-17),
  all(l10_cell_changes$new_value_lx == 0),
  all(l10_cell_changes$in_all_available),
  all(l10_cell_changes$in_paired_common_sample),
  all(l10_cell_changes$controlling_decision == "METRIC-011"),
  nrow(l10_identity) == 15L,
  all(l10_identity$passed),
  all(l10_identity$expected_sha256 == l10_identity$observed_sha256),
  nrow(l10_multiplicity) == 884L,
  all(l10_multiplicity$raw_p_identical[
    l10_multiplicity$metric_id != "l10_mean_medi"
  ]),
  sum(!l10_multiplicity$raw_p_identical) == 47L,
  sum(l10_multiplicity$adjusted_p_changed) == 162L,
  sum(
    l10_multiplicity$adjusted_p_changed &
      l10_multiplicity$metric_id != "l10_mean_medi"
  ) == 128L,
  nrow(l10_update) == 1L,
  l10_update$changed_primary_l10_cells == 8L,
  l10_update$primary_all_available_bundles_refitted == 2L,
  l10_update$primary_paired_main_models_refitted == 4L,
  l10_update$primary_gap_common_main_models_refitted == 4L,
  l10_update$primary_loso_rows_refitted == 36L,
  l10_update$participant_deletion_models_refitted == 4L,
  l10_update$non_l10_raw_p_values_changed == 0L,
  l10_update$significance_decisions_changed == 0L,
  l10_update$maximum_absolute_raw_p_change < 1e-12,
  l10_update$maximum_absolute_adjusted_p_change < 1e-12,
  l10_update$mder_models_changed == 0L,
  l10_update$resampling_replicates == 0L,
  !l10_update$pilot_runtime_gate_triggered,
  l10_update$boundary_assessment == "PASS",
  nrow(waking_mder) == 2L,
  all(waking_mder$metric_id == "mder_mean_of_viable_ratios"),
  all(waking_mder$status == "UNAVAILABLE"),
  all(stability$direction_stable[stability$baseline_supported]),
  sum(
    stability$adjusted_support_stable[stability$baseline_supported]
  ) ==
    8L
)

####
# Frozen V0 reconciliation, durable figures, and final artifact manifest
####

v0_comparison <- read_h10(
  "artifacts/09_tables/H10/H10_v0_to_current_comparison.csv"
)
v0_sex_site <- read_h10(
  "artifacts/09_tables/H10/H10_v0_sex_site_comparison_unavailable.csv"
)
figure_manifest <- read_h10(
  "artifacts/12_manifests/H10/H10_figure_manifest.csv"
)
execution <- read_h10(
  "artifacts/12_manifests/H10/H10_execution_environment.csv"
)
stopifnot(
  nrow(v0_comparison) == 102L,
  sum(v0_comparison$conclusion_changed) == 7L,
  nrow(v0_sex_site) == 2L,
  all(v0_sex_site$v0_status == "NOT_COMPARED_OR_REPORTED"),
  nrow(figure_manifest) == 9L,
  all(file.exists(file.path(root, figure_manifest$figure_path))),
  all(file.exists(file.path(root, figure_manifest$pdf_path))),
  all(file.exists(file.path(root, figure_manifest$source_data_path))),
  !anyDuplicated(figure_manifest$figure_path),
  !anyDuplicated(figure_manifest$pdf_path),
  any(
    execution$component == "resampling" &
      grepl("None", execution$version_or_status, fixed = TRUE)
  )
)

report_qmd <- file.path(
  root,
  "audit/hypotheses/H10/02_implementation_and_v0_comparison.qmd"
)
report_html <- file.path(
  root,
  "audit/hypotheses/H10/02_implementation_and_v0_comparison.html"
)
stopifnot(file.exists(report_qmd), file.exists(report_html))
report_text <- paste(readLines(report_qmd, warn = FALSE), collapse = "\n")
stopifnot(
  grepl("H10-G2", report_text, fixed = TRUE),
  grepl("Gaussian/identity", report_text, fixed = TRUE),
  grepl("METRIC-010", report_text, fixed = TRUE),
  grepl("METRIC-011", report_text, fixed = TRUE),
  grepl("eight primary L10 means", report_text, fixed = TRUE),
  grepl("all 36 current pins", report_text, fixed = TRUE),
  grepl("arithmetic mean of viable one-minute", report_text, fixed = TRUE),
  grepl("FIND-049/CHG-101", report_text, fixed = TRUE),
  grepl("reason-coded missing", report_text, fixed = TRUE),
  grepl("PREP-003/FIND-044", report_text, fixed = TRUE),
  grepl("gap-timing-unaware dataset", report_text, fixed = TRUE)
)

artifact_manifest <- read_h10(
  "artifacts/12_manifests/H10/H10_stage2_artifacts.csv"
)
manifest_paths <- file.path(root, artifact_manifest$path)
stopifnot(
  nrow(artifact_manifest) > 50L,
  all(file.exists(manifest_paths)),
  all(
    vapply(manifest_paths, artifact_sha256, character(1)) ==
      artifact_manifest$sha256
  ),
  all(grepl(
    "PREP-003/FIND-044",
    artifact_manifest$provenance_qualification,
    fixed = TRUE
  ))
)

message("H10 Stage 2 tests PASS")
