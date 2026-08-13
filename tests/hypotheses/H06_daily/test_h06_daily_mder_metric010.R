#!/usr/bin/env Rscript

# Focused no-refit verification of the H06_daily METRIC-010 amendment.

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
stopifnot(
  identical(as.character(getRversion()), "4.6.1"),
  requireNamespace("digest", quietly = TRUE),
  requireNamespace("readr", quietly = TRUE)
)

sha256 <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE)
}
read_csv <- function(path) {
  readr::read_csv(path, show_col_types = FALSE, na = "")
}
verify_manifest <- function(
  path,
  allowed_mismatch = character(),
  allowed_role_pattern = NULL
) {
  manifest <- read_csv(path)
  observed <- vapply(
    file.path(root, manifest$relative_path),
    sha256,
    character(1)
  )
  mismatched <- manifest$relative_path[observed != manifest$sha256]
  if (!is.null(allowed_role_pattern)) {
    allowed_mismatch <- union(
      allowed_mismatch,
      manifest$relative_path[
        grepl(allowed_role_pattern, manifest$role)
      ]
    )
  }
  stopifnot(setequal(mismatched, allowed_mismatch))
  invisible(manifest)
}
artifact <- function(stage, file) {
  file.path(root, "artifacts", stage, "H06_daily", file)
}

manifest_names <- c(
  "H06_daily_mder_metric010_static_input_manifest.csv",
  "H06_daily_mder_metric010_static_code_manifest.csv",
  "H06_daily_mder_metric010_static_output_manifest.csv",
  "H06_daily_mder_metric010_family_pilot_input_manifest.csv",
  "H06_daily_mder_metric010_family_pilot_code_manifest.csv",
  "H06_daily_mder_metric010_family_pilot_output_manifest.csv",
  "H06_daily_mder_metric010_influence_pilot_input_manifest.csv",
  "H06_daily_mder_metric010_influence_pilot_code_manifest.csv",
  "H06_daily_mder_metric010_influence_pilot_output_manifest.csv",
  "H06_daily_mder_metric010_production_input_manifest.csv",
  "H06_daily_mder_metric010_production_code_manifest.csv",
  "H06_daily_mder_metric010_production_output_manifest.csv",
  "H06_daily_mder_metric010_gap_refresh_input_manifest.csv",
  "H06_daily_mder_metric010_gap_refresh_code_manifest.csv",
  "H06_daily_mder_metric010_gap_refresh_output_manifest.csv",
  "H06_daily_mder_metric010_reader_input_manifest.csv",
  "H06_daily_mder_metric010_reader_code_manifest.csv",
  "H06_daily_mder_metric010_reader_output_manifest.csv"
)
frame_registry_path <- paste0(
  "artifacts/06_model_data/H06_daily/",
  "H06_daily_mder_metric010_frame_registry.csv"
)
for (name in manifest_names) {
  allowed <- if (name %in% c(
    "H06_daily_mder_metric010_family_pilot_code_manifest.csv",
    "H06_daily_mder_metric010_influence_pilot_code_manifest.csv"
  )) {
    paste0(
      "scripts/hypotheses/H06_daily/",
      c(
        "h06_daily_mder_metric010_contract.R",
        "h06_daily_mder_metric010_data.R",
        "h06_daily_mder_metric010_modeling.R"
      )
    )
  } else if (
    name == "H06_daily_mder_metric010_family_pilot_input_manifest.csv"
  ) {
    c(
      frame_registry_path,
      paste0(
        "artifacts/12_manifests/H06_daily/",
        "H06_daily_mder_metric010_static_output_manifest.csv"
      )
    )
  } else if (
    name == "H06_daily_mder_metric010_influence_pilot_input_manifest.csv"
  ) {
    frame_registry_path
  } else {
    character()
  }
  verify_manifest(
    artifact("12_manifests", name),
    allowed_mismatch = allowed,
    allowed_role_pattern = if (
      name == "H06_daily_mder_metric010_production_input_manifest.csv"
    ) {
      "^pre-refresh"
    } else {
      NULL
    }
  )
}
verify_manifest(file.path(
  root,
  "audit/hypotheses/H06_daily/",
  "H06_daily_mder_metric010_report_manifest.csv"
))

input_contract <- read_csv(artifact(
  "08_diagnostics",
  "H06_daily_mder_metric010_input_contract.csv"
))
metric_contract <- read_csv(artifact(
  "06_model_data",
  "H06_daily_mder_metric010_metric_contract.csv"
))
support <- read_csv(artifact(
  "08_diagnostics",
  "H06_daily_mder_metric010_support_summary.csv"
))
support_failures <- read_csv(artifact(
  "08_diagnostics",
  "H06_daily_mder_metric010_support_failure_summary.csv"
))
frames <- read_csv(artifact(
  "06_model_data",
  "H06_daily_mder_metric010_frame_registry.csv"
))
effects <- read_csv(artifact(
  "09_tables",
  "H06_daily_mder_metric010_effect_estimates.csv"
))
tests <- read_csv(artifact(
  "09_tables",
  "H06_daily_mder_metric010_model_tests.csv"
))
bh <- read_csv(artifact(
  "09_tables",
  "H06_daily_mder_metric010_bh_slot_families.csv"
))
diagnostics <- read_csv(artifact(
  "08_diagnostics",
  "H06_daily_mder_metric010_model_diagnostics.csv"
))
ar <- read_csv(artifact(
  "08_diagnostics",
  "H06_daily_mder_metric010_ar_counterparts.csv"
))
influence <- read_csv(artifact(
  "08_diagnostics",
  "H06_daily_mder_metric010_influence_summary.csv"
))
verdict <- read_csv(artifact(
  "08_diagnostics",
  "H06_daily_mder_metric010_production_verdict.csv"
))
benchmark <- read_csv(artifact(
  "08_diagnostics",
  "H06_daily_mder_metric010_registered_benchmark.csv"
))
qa <- read_csv(artifact(
  "08_diagnostics",
  "H06_daily_mder_metric010_figure_readability_qa.csv"
))
frame_comparison <- read_csv(artifact(
  "08_diagnostics",
  "H06_daily_mder_metric010_gap_refresh_frame_comparison.csv"
))
preservation <- read_csv(artifact(
  "08_diagnostics",
  "H06_daily_mder_metric010_gap_refresh_preservation.csv"
))
refresh_provenance <- read_csv(artifact(
  "08_diagnostics",
  "H06_daily_mder_metric010_gap_refresh_provenance.csv"
))

primary <- effects[
  effects$dataset_id == "primary" &
    effects$placement_id == "near_eye" &
    effects$sample_role == "all_available",
  ,
  drop = FALSE
]
primary_g <- primary[primary$family == "Gaussian", , drop = FALSE]
primary_t <- primary[primary$family == "Student-t", , drop = FALSE]
primary_d <- diagnostics[
  diagnostics$dataset_id == "primary" &
    diagnostics$placement_id == "near_eye" &
    diagnostics$sample_role == "all_available",
  ,
  drop = FALSE
]
primary_ar <- ar[
  ar$dataset_id == "primary" &
    ar$placement_id == "near_eye" &
    ar$sample_role == "all_available",
  ,
  drop = FALSE
]
gap <- effects[
  effects$dataset_id == "gap_timing_unaware" &
    effects$placement_id == "near_eye" &
    effects$sample_role == "all_available",
  ,
  drop = FALSE
]
gap_g <- gap[gap$family == "Gaussian", , drop = FALSE]
gap_t <- gap[gap$family == "Student-t", , drop = FALSE]
gap_d <- diagnostics[
  diagnostics$dataset_id == "gap_timing_unaware" &
    diagnostics$placement_id == "near_eye" &
    diagnostics$sample_role == "all_available",
  ,
  drop = FALSE
]
gap_ar <- ar[
  ar$dataset_id == "gap_timing_unaware" &
    ar$placement_id == "near_eye" &
    ar$sample_role == "all_available",
  ,
  drop = FALSE
]
gap_tests <- tests[tests$dataset_id == "gap_timing_unaware", , drop = FALSE]

expected_estimates <- c(
  work_free_day = -0.0013367695452255822,
  activity_status = 0.008277399038077799,
  previous_sleep_duration_centered_h = 0.001733201547750926
)
observed_estimates <- setNames(primary_g$estimate, primary_g$predictor_id)
expected_gap_estimates <- c(
  work_free_day = -0.001619123155536,
  activity_status = 0.009020499990256,
  previous_sleep_duration_centered_h = 0.001818193389273
)
observed_gap_estimates <- setNames(gap_g$estimate, gap_g$predictor_id)

stopifnot(
  nrow(input_contract) == 16L,
  all(input_contract$verified),
  input_contract$observed_sha256[
    input_contract$input_id == "metric010_decision"
  ] == "1664347de976057807fcb5ac6e24bd4b66af1fe32378fabd1f2acafcfc9266de",
  nrow(metric_contract) == 1L,
  metric_contract$metric_id == "mder_mean_of_viable_ratios",
  metric_contract$source_column == "mder",
  metric_contract$display_unit == "dimensionless",
  identical(support$available_days, c(702, 732, 687, 723)),
  identical(support$participants_with_value, c(137, 152, 137, 152)),
  support$exact_zeros[
    support$dataset_id == "gap_timing_unaware" &
      support$placement_id == "chest"
  ] == 0L,
  support_failures$participant_days[
    support_failures$dataset_id == "gap_timing_unaware" &
      support_failures$placement_id == "near_eye" &
      support_failures$support_status == "below_viable_ratio_fraction"
  ] == 122L,
  support_failures$participant_days[
    support_failures$dataset_id == "gap_timing_unaware" &
      support_failures$placement_id == "near_eye" &
      support_failures$support_status == "no_viable_momentary_ratio"
  ] == 2L,
  support_failures$participant_days[
    support_failures$dataset_id == "gap_timing_unaware" &
      support_failures$placement_id == "chest" &
      support_failures$support_status == "below_viable_ratio_fraction"
  ] == 171L,
  support_failures$participant_days[
    support_failures$dataset_id == "gap_timing_unaware" &
      support_failures$placement_id == "chest" &
      support_failures$support_status == "no_viable_momentary_ratio"
  ] == 3L,
  nrow(frames) == 36L,
  nrow(effects) == 72L,
  nrow(primary_g) == 3L,
  nrow(primary_t) == 3L,
  isTRUE(all.equal(
    unname(observed_estimates[names(expected_estimates)]),
    unname(expected_estimates),
    tolerance = 1e-10
  )),
  all(primary_g$lower_95 < 0),
  all(primary_g$upper_95 > 0),
  all(primary_t$lower_95 < 0),
  all(primary_t$upper_95 > 0),
  all(primary_g$student_t_shift_in_gaussian_se < 1),
  nrow(gap_g) == 3L,
  nrow(gap_t) == 3L,
  isTRUE(all.equal(
    unname(observed_gap_estimates[names(expected_gap_estimates)]),
    unname(expected_gap_estimates),
    tolerance = 1e-12
  )),
  all(gap_g$lower_95 < 0),
  all(gap_g$upper_95 > 0),
  gap_t$lower_95[
    gap_t$predictor_id == "previous_sleep_duration_centered_h"
  ] > 0,
  all(gap_g$student_t_shift_in_gaussian_se < 1),
  nrow(tests) == 12L,
  nrow(gap_tests) == 6L,
  nrow(bh) == 180L,
  all(is.na(bh$bh_adjusted_p_value)),
  all(bh$family_slots_available == 1L),
  all(bh$family_slots_required == 15L),
  all(bh$family_status == "INCOMPLETE_1_OF_15_NO_BH_DECISION"),
  nrow(primary_d) == 3L,
  all(primary_d$gaussian_converged),
  all(primary_d$gaussian_positive_definite_hessian),
  all(!primary_d$gaussian_singular),
  all(primary_d$student_t_converged),
  all(primary_d$student_t_positive_definite_hessian),
  all(!primary_d$student_t_singular),
  all(primary_d$gaussian_residual_qq_correlation < 0.95),
  all(primary_d$student_t_quantile_residual_qq_correlation > 0.99),
  nrow(primary_ar) == 3L,
  all(primary_ar$ar_trigger),
  all(primary_ar$ar_converged),
  all(primary_ar$ar_positive_definite_hessian),
  all(primary_ar$ar_singular),
  all(abs(primary_ar$ar_rho) < 0.95),
  all(primary_ar$ar_effect_shift_in_primary_se < 1),
  nrow(gap_d) == 3L,
  all(gap_d$gaussian_converged),
  all(gap_d$student_t_converged),
  all(gap_d$diagnostic_disposition ==
    "ACCEPTABLE_WITH_HEAVY_TAIL_LIMITATION"),
  nrow(gap_ar) == 3L,
  all(gap_ar$ar_trigger),
  all(gap_ar$ar_converged),
  all(gap_ar$ar_positive_definite_hessian),
  all(gap_ar$ar_singular),
  all(abs(gap_ar$ar_rho) < 0.95),
  all(gap_ar$ar_effect_shift_in_primary_se < 1),
  nrow(influence) == 3L,
  all(influence$participant_failures == 0L),
  all(influence$site_failures == 0L),
  all(influence$estimate_magnitude_reportable),
  influence$site_direction_reversal_count[
    influence$predictor_id == "work_free_day"
  ] == 3L,
  influence$site_direction_reversal_count[
    influence$predictor_id == "activity_status"
  ] == 0L,
  influence$site_direction_reversal_count[
    influence$predictor_id ==
      "previous_sleep_duration_centered_h"
  ] == 1L,
  all(verdict$claim_disposition != "NO_ASSOCIATION_CLAIM"),
  benchmark$disposition[
    benchmark$dataset_id == "primary" &
      benchmark$predictor_id == "previous_sleep_duration_centered_h"
  ] == "NON_ESTIMABLE",
  benchmark$disposition[
    benchmark$dataset_id == "gap_timing_unaware" &
      benchmark$predictor_id == "previous_sleep_duration_centered_h"
  ] == "NON_ESTIMABLE",
  nrow(frame_comparison) == 36L,
  sum(!frame_comparison$object_identical) == 24L,
  all(frame_comparison$object_identical[
    frame_comparison$dataset_id == "primary" &
      frame_comparison$sample_role != "dataset_common"
  ]),
  nrow(preservation) == 12L,
  all(preservation$preserved),
  all(refresh_provenance$verdict %in% c(
    "PASS",
    "INCOMPLETE_NO_BH_DECISION"
  )),
  all(qa$verdict == "PASS"),
  all(qa$source_data_paired),
  all(qa$alt_text_present)
)

qmd_path <- file.path(
  root,
  "audit/hypotheses/H06_daily/05_mder_metric010_amendment.qmd"
)
html_path <- file.path(
  root,
  "audit/hypotheses/H06_daily/05_mder_metric010_amendment.html"
)
qmd <- paste(readLines(qmd_path, warn = FALSE), collapse = "\n")
html <- paste(readLines(html_path, warn = FALSE), collapse = "\n")
stopifnot(
  grepl("H06-D-G2-MDER-GAP", qmd, fixed = TRUE),
  grepl("no adjusted p-value", qmd, ignore.case = TRUE),
  grepl("structured-covariance singularity", qmd, fixed = TRUE),
  grepl("no finite nonpositive", qmd, ignore.case = TRUE),
  grepl("Student-t sleep interval", qmd, fixed = TRUE),
  grepl("24 MDER-dependent frames", qmd, fixed = TRUE),
  grepl("No prior estimate", qmd, fixed = TRUE),
  grepl("METRIC-010 MDER amendment", html, fixed = TRUE),
  grepl("H06-D-G2-MDER-GAP", html, fixed = TRUE),
  file.exists(artifact(
    "10_figures",
    "H06_daily_mder_metric010_primary_effects.png"
  )),
  file.exists(artifact(
    "11_source_data",
    "H06_daily_mder_metric010_primary_effect_figure_source.csv"
  )),
  file.exists(artifact(
    "11_source_data",
    "H06_daily_mder_metric010_figure_alt_text.csv"
  ))
)

message(
  "H06_daily METRIC-010 corrected gap-refresh integrity passed; ",
  "all unaffected primary results remained frozen"
)
