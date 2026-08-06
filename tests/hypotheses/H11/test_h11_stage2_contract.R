# Focused pre-fit contract tests for H11 Stage 2.

suppressPackageStartupMessages({
  library(dplyr)
  library(gratia)
  library(mgcv)
  library(tibble)
  library(tidyr)
})

options(
  stringsAsFactors = FALSE,
  scipen = 999,
  dplyr.summarise.inform = FALSE
)

test_argument <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
if (length(test_argument) != 1L) {
  stop("Could not determine the H11 Stage 2 test location", call. = FALSE)
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

stopifnot(
  getRversion() == "4.6.1",
  as.character(packageVersion("mgcv")) == "1.9.4",
  as.character(packageVersion("gratia")) == "0.11.2"
)

message("Testing the author gate and reconciled upstream drift")
reconciliation <- h11_stage2_gate_reconciliation(root)
stopifnot(
  nrow(reconciliation) == 44L,
  all(reconciliation$acceptable_for_stage2),
  sum(reconciliation$drift_class == "reconciled_post_gate_drift") == 7L,
  all(
    reconciliation$drift_class[
      grepl("^h02_manifest_item_", reconciliation$input_id)
    ] == "unchanged_since_stage1"
  )
)
decision <- paste(
  readLines(
    file.path(root, "audit/hypotheses/H11/01_author_decision.md"),
    warn = FALSE
  ),
  collapse = "\n"
)
method_decision <- paste(
  readLines(
    file.path(
      root,
      "audit/hypotheses/H11/02_inferential_method_decision.md"
    ),
    warn = FALSE
  ),
  collapse = "\n"
)
stopifnot(
  grepl("pointwise 95% confidence intervals", decision, fixed = TRUE),
  grepl("50-replicate pilot", decision, fixed = TRUE),
  grepl("cannot open, rescue, or", decision, fixed = TRUE),
  grepl("Status: **approved**", method_decision, fixed = TRUE),
  grepl("H11-METHOD-001", method_decision, fixed = TRUE),
  grepl("H11-METHOD-007", method_decision, fixed = TRUE),
  grepl("Remove the planned `ML`, `discrete = FALSE`", method_decision, fixed = TRUE),
  grepl("participant-cluster-robust pointwise 95%", method_decision, fixed = TRUE),
  grepl("global robust raw p-value is below 0.050", method_decision, fixed = TRUE)
)

message("Testing the four mandatory Stage 2 samples")
registry <- h11_stage2_registry(root)
stopifnot(
  nrow(registry) == 4L,
  identical(
    registry$run_id,
    c(
      "main__glasses__all_available",
      "main__chest__all_available",
      "manuscript_prepared_data__glasses__all_available",
      "manuscript_prepared_data__chest__all_available"
    )
  )
)
demographics <- readRDS(file.path(
  root,
  "artifacts/06_model_data/normalized_inputs/demographics.rds"
))
expected <- tibble::tribble(
  ~participants, ~participant_days, ~observations, ~sites, ~female, ~male,
  141L, 816L, 37756L, 9L, 79L, 62L,
  154L, 902L, 41842L, 8L, 86L, 68L,
  141L, 809L, 37603L, 9L, 79L, 62L,
  154L, 894L, 41664L, 8L, 86L, 68L
)
for (index in seq_len(nrow(registry))) {
  run <- registry[index, , drop = FALSE]
  frame <- readRDS(run$frame_path)
  data <- h11_stage2_prepare_frame(frame, demographics, run$run_id)
  sample <- h11_stage2_sample_row(data, run)
  stopifnot(
    sample$participants == expected$participants[index],
    sample$participant_days == expected$participant_days[index],
    sample$observations_30_minute == expected$observations[index],
    sample$sites == expected$sites[index],
    sample$female_participants == expected$female[index],
    sample$male_participants == expected$male[index],
    all(!is.na(data$sex)),
    identical(levels(data$sex), c("Male", "Female")),
    is.ordered(data$sex_smooth),
    identical(levels(data$sex_smooth), c("Male", "Female")),
    identical(unname(contrasts(data$sex)), matrix(c(0, 1), ncol = 1L)),
    identical(colnames(contrasts(data$sex)), "Female"),
    all(frame$AR_start == data$AR_start),
    all(frame$response == data$response)
  )
}

message("Testing the exact approved formulas")
formulas <- h11_formula_set(root)
formula_terms <- function(x) attr(stats::terms(x), "term.labels")
stopifnot(
  identical(
    h11_formula_text(formulas$proposed_m0),
    h11_formula_text(h11_h02_formula_set(root)$site_pattern)
  ),
  "sex" %in% formula_terms(formulas$proposed_mlevel),
  "sex" %in% formula_terms(formulas$proposed_mpattern),
  any(grepl(
    "by = sex_smooth, bs = \"cc\", k = 12",
    h11_formula_text(formulas$proposed_mpattern),
    fixed = TRUE
  )),
  !grepl("gender", h11_formula_text(formulas$proposed_mpattern), fixed = TRUE),
  !grepl("photoperiod", h11_formula_text(formulas$proposed_mpattern), fixed = TRUE),
  !grepl("activity", h11_formula_text(formulas$proposed_mpattern), fixed = TRUE)
)

message("Testing multiplicity and support decisions without fitting")
mock <- tibble::tribble(
  ~run_id, ~family_id, ~planned_n, ~comparison_role, ~p_raw,
  "a", "g", 1L, "global", 0.01,
  "a", "d", 2L, "decomposition", 0.01,
  "a", "d", 2L, "decomposition", 0.04,
  "b", "g", 1L, "global", 0.20
)
adjusted <- h11_stage2_adjust_multiplicity(mock)
stopifnot(
  adjusted$support_status[adjusted$run_id == "a" &
    adjusted$comparison_role == "global"] == "supported",
  adjusted$support_status[adjusted$run_id == "b"] == "not_supported",
  all(is.na(adjusted$AIC_supported)),
  identical(
    adjusted$p_adjusted_BH[adjusted$family_id == "d"],
    c(0.02, 0.04)
  )
)

message("Testing H02-like effect-size calculations")
response <- c(-1, 0, 1, 2)
baseline <- c(-0.5, 0, 0.5, 1.5)
full <- c(-0.8, 0.1, 0.9, 1.9)
effect <- h11_stage2_r2_point(response, baseline, full)
stopifnot(
  length(effect) == 5L,
  effect["full_in_sample_R2"] > effect["baseline_in_sample_R2"],
  isTRUE(all.equal(
    unname(effect["sex_block_allocated_R2"]),
    unname(effect["full_in_sample_R2"] - effect["baseline_in_sample_R2"])
  )),
  effect["sex_block_share_of_full_R2"] > 0
)
invalid_pilot <- try(
  h11_stage2_bootstrap_r2(
    response,
    baseline,
    full,
    data.frame(site = 1, participant = 1, participant_day = 1),
    replicates = 20L,
    seed = 1L
  ),
  silent = TRUE
)
stopifnot(inherits(invalid_pilot, "try-error"))

message("Testing REPORT-008, REPORT-009, REPORT-010, and REPORT-011 integration")
p_display <- nh_p_value_display(
  c(0.247, 0.032, 0.000999, 0.001, NA_real_),
  c(FALSE, TRUE, TRUE, TRUE, TRUE),
  na_label = "—"
)
stopifnot(
  identical(
    p_display$p_display,
    c("0.247", "0.032", "<0.001", "0.001", "—")
  ),
  identical(p_display$p_bold, c(FALSE, TRUE, TRUE, TRUE, FALSE))
)
report_008 <- paste(
  readLines(
    file.path(root, "audit/decisions/p_value_display_conventions.md"),
    warn = FALSE
  ),
  collapse = "\n"
)
report_009 <- paste(
  readLines(
    file.path(root, "audit/decisions/paired_placement_comparison_display.md"),
    warn = FALSE
  ),
  collapse = "\n"
)
terminology_decision <- paste(
  readLines(
    file.path(
      root,
      "audit/hypotheses/H11/02_reader_facing_terminology_decision.md"
    ),
    warn = FALSE
  ),
  collapse = "\n"
)
report_010 <- paste(
  readLines(
    file.path(
      root,
      "audit/decisions/gap_timing_unaware_dataset_terminology.md"
    ),
    warn = FALSE
  ),
  collapse = "\n"
)
report_011 <- paste(
  readLines(
    file.path(
      root,
      "audit/decisions/figure_readability_and_layout.md"
    ),
    warn = FALSE
  ),
  collapse = "\n"
)
report_012 <- paste(
  readLines(
    file.path(
      root,
      "audit/decisions/answer_in_brief_callout.md"
    ),
    warn = FALSE
  ),
  collapse = "\n"
)
report_code <- paste(
  readLines(
    file.path(
      root,
      "audit/hypotheses/H11/02_implementation_and_v0_comparison.qmd"
    ),
    warn = FALSE
  ),
  collapse = "\n"
)
display_code <- paste(
  readLines(
    file.path(
      root,
      "scripts/hypotheses/H11/build_h11_stage2_displays.R"
    ),
    warn = FALSE
  ),
  collapse = "\n"
)
stopifnot(
  grepl("Decision ID: `REPORT-008`", report_008, fixed = TRUE),
  grepl("Decision ID: `REPORT-009`", report_009, fixed = TRUE),
  grepl("scripts/pipeline/p_value_display.R", report_code, fixed = TRUE),
  grepl("add_independent_p_displays", report_code, fixed = TRUE),
  grepl("nh_p_value_display", report_code, fixed = TRUE),
  grepl("Raw and[[:space:]]+adjusted p-values", report_code),
  grepl("H05-style near-eye-on-x/chest-on-y", report_code, fixed = TRUE),
  grepl("No paired source-data CSV is[[:space:]]+created", report_code),
  grepl("gap-timing-unaware dataset", terminology_decision, fixed = TRUE),
  grepl("50%-per-hour", terminology_decision, fixed = TRUE),
  grepl("80%-per-day", terminology_decision, fixed = TRUE),
  grepl("time-sensitive primary metric dataset", terminology_decision, fixed = TRUE),
  grepl("does not alter or reopen any scientific calculation", terminology_decision, fixed = TRUE),
  grepl("Decision ID: `REPORT-010`", report_010, fixed = TRUE),
  grepl("This is a terminology change only", report_010, fixed = TRUE),
  grepl("Decision ID: `REPORT-011`", report_011, fixed = TRUE),
  grepl("Required post-adjustment visual QA", report_011, fixed = TRUE),
  grepl("Decision ID: `REPORT-012`", report_012, fixed = TRUE),
  grepl("Answer in brief", report_012, fixed = TRUE),
  grepl("minimum_important_text_pt", display_code, fixed = TRUE),
  grepl("figure_readability_qa", report_code, fixed = TRUE),
  grepl("REPORT-011", report_code, fixed = TRUE),
  grepl("Stage 3 will add the required", report_code, fixed = TRUE),
  !grepl("callout-note title=\"Answer in brief\"", report_code, fixed = TRUE)
)

stage2_code <- paste(
  readLines(
    file.path(root, "scripts/hypotheses/H11/h11_stage2.R"),
    warn = FALSE
  ),
  collapse = "\n"
)
runner_code <- paste(
  readLines(
    file.path(root, "scripts/hypotheses/H11/run_h11_stage2_analysis.R"),
    warn = FALSE
  ),
  collapse = "\n"
)
stopifnot(
  !grepl("simulations = 10000", stage2_code, fixed = TRUE),
  !grepl("simulations = 10000", runner_code, fixed = TRUE),
  !grepl("replicates = 2000", runner_code, fixed = TRUE),
  grepl("replicates = 50L", runner_code, fixed = TRUE),
  grepl("not simultaneous over the day", stage2_code, fixed = TRUE),
  grepl("paired_placement_display_assessment.csv", runner_code, fixed = TRUE),
  grepl("h11_stage2_robust_tests", runner_code, fixed = TRUE),
  !grepl("m0_comparison_ML", runner_code, fixed = TRUE),
  !grepl("mlevel_comparison_ML", runner_code, fixed = TRUE),
  !grepl("mpattern_comparison_ML", runner_code, fixed = TRUE)
)

cat("H11 Stage 2 pre-fit contract tests: PASS\n")
