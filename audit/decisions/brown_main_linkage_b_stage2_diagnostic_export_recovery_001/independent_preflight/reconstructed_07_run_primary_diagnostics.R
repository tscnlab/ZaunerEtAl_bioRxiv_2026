# Diagnose one frozen primary model without changing its fit or estimands.

source(file.path(
  Sys.getenv("BROWN_ADHERENCE_PROJECT_ROOT"),
  "audit/analyses/brown_adherence/main_linkage_b_amendment/stage2/code/runtime_contract.R"
))
args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) == 1L, args[[1L]] %in% c("PRIMARY-ANY", "PRIMARY-80"))
key <- args[[1L]]
job_id <- paste0("DIAGNOSTICS-", key)
sample_id <- if (key == "PRIMARY-ANY") "primary_any_valid" else "support_80"
sample_slot <- if (key == "PRIMARY-ANY") "B_any" else "B_80"
output_prefix <- paste0("diagnostics/", sample_id)
stopifnot(!file.exists(file.path(stage2_root, output_prefix)))
registry_root <- file.path(stage2_root, "preflight/qualified_continuation_001")
lb_assert_manifest(file.path(
  registry_root,
  "primary_diagnostic_source_manifest.csv"
))
registry <- read.csv(
  file.path(registry_root, "job_registry_0001.csv"),
  stringsAsFactors = FALSE
)
job <- registry[registry$job_id == job_id, , drop = FALSE]
stopifnot(nrow(job) == 1L)
driver_path <- file.path(code_root, "07_run_primary_diagnostics.R")
stopifnot(sha256(driver_path) == job$driver_sha256)
model_path <- file.path(stage2_root, "models", paste0("BA-LB-", key, ".rds"))
stopifnot(sha256(model_path) == job$model_sha256)
seeds <- read.csv(
  file.path(registry_root, "diagnostic_seed_registry.csv"),
  stringsAsFactors = FALSE
)
seed_row <- seeds[seeds$sample_slot == sample_slot, , drop = FALSE]
stopifnot(
  nrow(seed_row) == 1L,
  seed_row$draws == 250L,
  seed_row$predictive_seed == 20260814L,
  seed_row$residual_seed == 20260815L
)
source(file.path(code_root, "boundary_model_contract.R"))
source(file.path(code_root, "diagnostic_interface.R"))
state_label <- c(
  "Wake outside the three hours before sleep" = "Daytime",
  "Pre-sleep" = "Pre-sleep",
  "Sleep environment" = "Sleep"
)

#####
# Step 1: Compute the registered diagnostics
#####

result <- derive_diagnostics(sample_id, model_path)
row_data <- result$row_data
state_daytype_calibration <- summarize_calibration(
  row_data,
  c("analysis_state", "day_type"),
  "state_day_type"
)
state_daytype_calibration[, sample_id := sample_id]
result$calibration <- data.table::rbindlist(
  list(result$calibration, state_daytype_calibration),
  use.names = TRUE,
  fill = TRUE
)
result$participant_influence[,
  deletion_screen_role := if (sample_slot == "B_any")
    "primary five-participant screen" else
    "diagnostic summary only; no support-sample deletion slots"
]
gate <- read.csv(file.path(stage2_root, "estimands/B_to_B80_claim_gate.csv"))
qualification <- data.frame(
  sample_id = sample_id,
  analysis_state = gate$analysis_state,
  direction_preserved = gate$direction_preserved,
  interval_exclusion_preserved = gate$interval_exclusion_preserved,
  absolute_shift_percentage_points = gate$absolute_shift_percentage_points,
  original_M1_coverage_gate_passed = gate$passed,
  author_qualified_continuation = TRUE,
  status = ifelse(
    gate$passed,
    "passed",
    "failed_coverage_sensitive_author_qualified"
  )
)

#####
# Step 2: Verify diagnostic construction, not scientific success
#####

checks <- data.frame(
  check = c(
    "draw_dimensions",
    "draw_bounds",
    "randomized_cdf_order",
    "finite_residuals",
    "probability_bounds",
    "nonnegative_conditional_variance",
    "nine_endpoint_rows",
    "five_applicable_endpoints",
    "all_six_state_daytype_calibrations",
    "actual_date_unique_series",
    "three_state_temporal_assessments",
    "five_primary_screen_positions",
    "frozen_model_unchanged",
    "failed_Pre_sleep_coverage_gate_retained"
  ),
  pass = c(
    nrow(result$simulated_response) == nrow(row_data) &&
      ncol(result$simulated_response) == 250L,
    all(
      result$simulated_response >= 0 &
        result$simulated_response <= row_data$valid_minutes
    ),
    all(
      row_data$lower_cdf <= row_data$upper_cdf &
        row_data$lower_cdf >= 0 &
        row_data$upper_cdf <= 1
    ),
    all(
      is.finite(row_data$pearson_residual) &
        is.finite(row_data$quantile_residual)
    ),
    all(
      row_data$conditional_mean >= 0 &
        row_data$conditional_mean <= 1 &
        row_data$exact_zero_probability >= 0 &
        row_data$exact_zero_probability <= 1 &
        row_data$exact_one_probability >= 0 &
        row_data$exact_one_probability <= 1
    ),
    all(
      is.finite(row_data$conditional_variance) &
        row_data$conditional_variance > 0
    ),
    sum(result$boundary_prediction$grouping == "state") == 9L,
    sum(result$boundary_prediction$claim_gate_applicable) == 5L,
    nrow(state_daytype_calibration) == 6L,
    !anyDuplicated(as.data.frame(row_data[, .(
      participant_state_id,
      behavior_date
    )])),
    sum(result$temporal_correlation$residual_type == "Pearson") == 3L,
    sum(result$participant_influence$selected_for_bounded_refit) == 5L,
    sha256(model_path) == job$model_sha256,
    identical(as.character(gate$analysis_state[!gate$passed]), "Pre-sleep") &&
      !gate$interval_exclusion_preserved[gate$analysis_state == "Pre-sleep"]
  )
)
technical <- data.frame(
  sample_id = sample_id,
  target = "frozen_primary_numerical_fit",
  status = as.character(result$bundle$fit_gate$status),
  detail = "Stored numerical status; primary model was not refitted"
)
result$assessment <- data.table::rbindlist(
  list(result$assessment, technical),
  fill = TRUE
)
result$bundle <- NULL
result$model_path <- model_path
result$model_sha256 <- sha256(model_path)
result$M1_coverage_qualification <- qualification
result$construction_validation <- checks
result$seed_slot <- seed_row

#####
# Step 3: Export once and retain each scientific assessment separately
#####

tables <- c(
  "row_data",
  "calibration",
  "boundary_prediction",
  "residual_group_summary",
  "residual_patterns",
  "state_residual_covariance",
  "temporal_correlation",
  "temporal_gap_summary",
  "participant_influence",
  "assessment"
)
for (item in tables) {
  lb_write_csv(result[[item]], paste0(output_prefix, "/", item, ".csv"))
}
lb_write_csv(
  qualification,
  paste0(output_prefix, "/coverage_qualification.csv")
)
lb_write_csv(checks, paste0(output_prefix, "/construction_checks.csv"))
lb_write_csv(seed_row, paste0(output_prefix, "/draw_usage.csv"))
lb_save_rds(result, paste0(output_prefix, "/diagnostics.rds"))
files <- list.files(file.path(stage2_root, output_prefix), full.names = TRUE)
lb_manifest(files, paste0(output_prefix, "/manifest.csv"))
print(checks)
print(result$assessment)
print(result$temporal_correlation)
cat(
  "M1 coverage remains failed and author-qualified. No fit, primary inference or gate rewrite.\n"
)
stopifnot(all(checks$pass))
