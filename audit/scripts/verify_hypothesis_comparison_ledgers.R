# Verify the submitted-versus-audited hypothesis comparison records.

options(warn = 2)

stopifnot(identical(as.character(getRversion()), "4.6.1"))

source("scripts/pipeline/paths_io.R")

root <- project_root()
ledger_dir <- file.path(root, "audit", "ledgers")

read_ledger <- function(name) {
  path <- file.path(ledger_dir, name)
  stopifnot(file.exists(path))
  utils::read.csv(
    path,
    stringsAsFactors = FALSE,
    check.names = FALSE,
    na.strings = character()
  )
}

implementation <- read_ledger("hypothesis_implementation_audit.csv")
results <- read_ledger("hypothesis_result_comparisons.csv")
data_sensitivity <- read_ledger(
  "hypothesis_data_sensitivity_comparisons.csv"
)
status <- read_ledger("hypothesis_comparison_status.csv")

expected_implementation_columns <- c(
  "implementation_audit_id",
  "hypothesis_id",
  "estimand_id",
  "analysis_role",
  "placement",
  "scenario",
  "outcome_id",
  "predictor_or_contrast_family",
  "submitted_implementation",
  "submitted_implementation_locator",
  "submitted_producer_artifact",
  "submitted_artifact_sha256",
  "audited_implementation",
  "audited_implementation_locator",
  "audited_producer_artifact",
  "audited_artifact_sha256",
  "change_class",
  "change_rationale",
  "change_ids",
  "decision_ids",
  "finding_ids",
  "preregistration_relation",
  "preregistration_disposition",
  "preregistration_locator",
  "workflow_status",
  "verification_status",
  "gate_status",
  "reopened_by",
  "notes"
)
expected_result_columns <- c(
  "comparison_id",
  "implementation_audit_id",
  "hypothesis_id",
  "result_id",
  "result_role",
  "outcome",
  "predictor_or_contrast",
  "quantity",
  "scale",
  "unit",
  "submitted_result_status",
  "submitted_result",
  "submitted_estimate",
  "submitted_se",
  "submitted_ci_lower",
  "submitted_ci_upper",
  "submitted_ci_method",
  "submitted_p_raw",
  "submitted_p_adjusted",
  "submitted_adjustment_method",
  "submitted_family_id",
  "submitted_family_n",
  "submitted_family_rank",
  "submitted_n_participants",
  "submitted_n_participant_days",
  "submitted_n_participant_rows",
  "submitted_n_hours",
  "submitted_support_hours",
  "submitted_n_30_minute_observations",
  "submitted_n_observations",
  "submitted_n_sites",
  "submitted_sample_flow_id",
  "audited_result_status",
  "audited_result",
  "audited_estimate",
  "audited_se",
  "audited_ci_lower",
  "audited_ci_upper",
  "audited_ci_method",
  "audited_p_raw",
  "audited_p_adjusted",
  "audited_adjustment_method",
  "audited_family_id",
  "audited_family_n",
  "audited_family_rank",
  "audited_n_participants",
  "audited_n_participant_days",
  "audited_n_participant_rows",
  "audited_n_hours",
  "audited_support_hours",
  "audited_n_30_minute_observations",
  "audited_n_observations",
  "audited_n_sites",
  "audited_sample_flow_id",
  "absolute_change",
  "relative_change",
  "practical_change_class",
  "direction_change",
  "uncertainty_change",
  "inference_change",
  "participant_delta",
  "participant_day_delta",
  "participant_row_delta",
  "hour_delta",
  "support_hour_delta",
  "thirty_minute_observation_delta",
  "observation_delta",
  "site_delta",
  "same_sample_keys",
  "sample_change_class",
  "submitted_claim",
  "audited_claim",
  "claim_change",
  "result_difference_ids",
  "evidence_locator",
  "comparison_status",
  "verification_status",
  "notes"
)
expected_status_columns <- c(
  "hypothesis_id",
  "submitted_analysis_source",
  "submitted_result_source",
  "audited_notebook",
  "implementation_comparison_status",
  "result_comparison_status",
  "claim_comparison_status",
  "preregistration_comparison_status",
  "data_sensitivity_definition_status",
  "data_sensitivity_run_status",
  "data_sensitivity_verification_status",
  "workflow_status",
  "verification_status",
  "gate_status",
  "notes"
)
expected_data_sensitivity_columns <- c(
  "sensitivity_comparison_id",
  "hypothesis_id",
  "result_id",
  "analysis_role",
  "placement",
  "outcome",
  "predictor_or_contrast",
  "quantity",
  "scale",
  "unit",
  "model_implementation_id",
  "main_data_artifact",
  "main_data_sha256",
  "main_model_artifact",
  "main_result_status",
  "main_estimate",
  "main_ci_lower",
  "main_ci_upper",
  "main_interval_method",
  "main_p_raw",
  "main_p_adjusted",
  "main_adjustment_method",
  "main_family_id",
  "main_family_n",
  "main_family_rank",
  "main_n_participants",
  "main_n_participant_days",
  "main_n_participant_rows",
  "main_n_hours",
  "main_support_hours",
  "main_n_30_minute_observations",
  "main_n_other_observations",
  "main_n_sites",
  "sensitivity_data_artifact",
  "sensitivity_data_sha256",
  "sensitivity_model_artifact",
  "sensitivity_result_status",
  "sensitivity_estimate",
  "sensitivity_ci_lower",
  "sensitivity_ci_upper",
  "sensitivity_interval_method",
  "sensitivity_p_raw",
  "sensitivity_p_adjusted",
  "sensitivity_adjustment_method",
  "sensitivity_family_id",
  "sensitivity_family_n",
  "sensitivity_family_rank",
  "sensitivity_n_participants",
  "sensitivity_n_participant_days",
  "sensitivity_n_participant_rows",
  "sensitivity_n_hours",
  "sensitivity_support_hours",
  "sensitivity_n_30_minute_observations",
  "sensitivity_n_other_observations",
  "sensitivity_n_sites",
  "common_n_participants",
  "common_n_participant_days",
  "common_n_participant_rows",
  "common_n_hours",
  "common_support_hours",
  "common_n_30_minute_observations",
  "common_n_other_observations",
  "common_n_sites",
  "absolute_change",
  "relative_change",
  "direction_change",
  "inference_change",
  "stability_class",
  "main_fit_status",
  "sensitivity_fit_status",
  "main_diagnostic_status",
  "sensitivity_diagnostic_status",
  "data_correction_ids",
  "decision_ids",
  "evidence_locator",
  "verification_status",
  "notes"
)

stopifnot(
  identical(names(implementation), expected_implementation_columns),
  identical(names(results), expected_result_columns),
  identical(
    names(data_sensitivity),
    expected_data_sensitivity_columns
  ),
  identical(names(status), expected_status_columns)
)

expected_hypotheses <- sprintf("H%02d", seq_len(11))
stopifnot(
  identical(status$hypothesis_id, expected_hypotheses),
  !anyDuplicated(status$hypothesis_id),
  all(file.exists(file.path(root, status$audited_notebook)))
)

workflow_values <- c(
  "planned",
  "model_data_build",
  "implemented",
  "run_complete",
  "comparison_complete",
  "closed",
  "blocked",
  "reopened"
)
verification_values <- c(
  "not_tested",
  "structural_pass",
  "producer_pass",
  "clean_run_pass",
  "independent_pass",
  "fail",
  "blocked"
)
gate_values <- c(
  "not_required",
  "open",
  "author_approval_required",
  "method_approved_result_pending",
  "approved",
  "closed",
  "reopened"
)
data_sensitivity_definition_values <- c("defined", "not_defined")
data_sensitivity_run_values <- c(
  "not_started",
  "in_progress",
  "complete",
  "failed",
  "blocked"
)
stopifnot(
  all(status$workflow_status %in% workflow_values),
  all(status$verification_status %in% verification_values),
  all(
    status$data_sensitivity_definition_status %in%
      data_sensitivity_definition_values
  ),
  all(
    status$data_sensitivity_run_status %in%
      data_sensitivity_run_values
  ),
  all(
    status$data_sensitivity_verification_status %in%
      c("not_started", verification_values)
  ),
  all(status$gate_status %in% gate_values)
)

if (nrow(implementation) > 0L) {
  analysis_role_values <- c(
    "primary",
    "secondary",
    "sensitivity",
    "complementary",
    "diagnostic"
  )
  change_class_values <- c(
    "none",
    "bug_fix",
    "data_source_correction",
    "reproducibility_repair",
    "measurement_validity_repair",
    "estimand_adaptation",
    "model_adaptation",
    "reporting_only"
  )
  preregistration_relation_values <- c(
    "aligned",
    "clarified",
    "approved_deviation",
    "unapproved_deviation",
    "not_specified",
    "ambiguous",
    "non_estimable_as_registered",
    "not_applicable"
  )
  preregistration_disposition_values <- c(
    "retained_primary",
    "retained_sensitivity",
    "adapted_primary",
    "omitted_with_rationale",
    "pending_author_decision",
    "author_approved",
    "not_applicable"
  )
  stopifnot(
    !anyDuplicated(implementation$implementation_audit_id),
    all(implementation$hypothesis_id %in% expected_hypotheses),
    all(implementation$analysis_role %in% analysis_role_values),
    all(implementation$change_class %in% change_class_values),
    all(
      implementation$preregistration_relation %in%
        preregistration_relation_values
    ),
    all(
      implementation$preregistration_disposition %in%
        preregistration_disposition_values
    ),
    all(implementation$workflow_status %in% workflow_values),
    all(implementation$verification_status %in% verification_values),
    all(implementation$gate_status %in% gate_values)
  )
}

if (nrow(results) > 0L) {
  practical_change_values <- c(
    "negligible",
    "material",
    "not_classified_no_margin",
    "not_comparable",
    "not_applicable"
  )
  stopifnot(
    !anyDuplicated(results$comparison_id),
    all(results$hypothesis_id %in% expected_hypotheses),
    all(
      results$implementation_audit_id %in%
        implementation$implementation_audit_id
    ),
    all(results$practical_change_class %in% practical_change_values),
    all(results$verification_status %in% verification_values)
  )
}

if (nrow(data_sensitivity) > 0L) {
  stability_values <- c(
    "stable",
    "quantitatively_sensitive",
    "qualitatively_sensitive",
    "inconclusive",
    "invalid",
    "non_estimable"
  )
  result_status_values <- c(
    "estimated",
    "descriptive_only",
    "non_estimable",
    "failed",
    "pending"
  )
  stopifnot(
    !anyDuplicated(data_sensitivity$sensitivity_comparison_id),
    all(data_sensitivity$hypothesis_id %in% expected_hypotheses),
    all(data_sensitivity$main_result_status %in% result_status_values),
    all(
      data_sensitivity$sensitivity_result_status %in%
        result_status_values
    ),
    all(data_sensitivity$stability_class %in% stability_values),
    all(data_sensitivity$verification_status %in% verification_values),
    all(
      data_sensitivity$model_implementation_id != "" &
        data_sensitivity$main_data_artifact != "" &
        data_sensitivity$sensitivity_data_artifact != ""
    )
  )
}

contract_path <- file.path(
  root,
  "audit",
  "hypotheses",
  "implementation_result_comparison_contract.qmd"
)
stopifnot(file.exists(contract_path))
contract <- paste(
  readLines(contract_path, warn = FALSE, encoding = "UTF-8"),
  collapse = "\n"
)
stopifnot(
  grepl(
    "gap-timing-unaware dataset sensitivity",
    contract,
    fixed = TRUE
  ),
  grepl("relation to the preregistration", contract, fixed = TRUE)
)

cat(
  "Hypothesis comparison ledger verification passed\n",
  "Hypotheses: ",
  nrow(status),
  "\n",
  "Implementation rows: ",
  nrow(implementation),
  "\n",
  "Result rows: ",
  nrow(results),
  "\n",
  "Data-sensitivity rows: ",
  nrow(data_sensitivity),
  "\n",
  sep = ""
)
