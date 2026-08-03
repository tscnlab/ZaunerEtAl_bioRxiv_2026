# Verify the H08 Stage 2 contracts and generated analytical artifacts.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)

source(file.path(root, "scripts/pipeline/paths_io.R"))
source(file.path(root, "scripts/pipeline/p_value_display.R"))
source(file.path(root, "scripts/hypotheses/H08/h08_contract.R"))

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("H08 Stage 2 tests require R 4.6.1", call. = FALSE)
}

read_h08 <- function(...) {
  readr::read_csv(file.path(root, ...), show_col_types = FALSE, na = "")
}

for (path in c(
  "scripts/hypotheses/H08/h08_contract.R",
  "scripts/hypotheses/H08/h08_modeling.R",
  "scripts/hypotheses/H08/run_h08_stage2.R",
  "tests/hypotheses/H08/test_h08_stage2.R"
)) {
  parse(file.path(root, path))
}

input_contract <- h08_input_contract(root)
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

approvals <- read_h08(
  "artifacts/06_model_data/H08/H08_author_approvals.csv"
)
metrics <- read_h08("artifacts/06_model_data/H08/H08_metric_registry.csv")
runs <- read_h08("artifacts/06_model_data/H08/H08_run_registry.csv")
families <- read_h08("artifacts/06_model_data/H08/H08_family_registry.csv")
formulas <- read_h08("artifacts/06_model_data/H08/H08_formula_registry.csv")
frames <- read_h08("artifacts/06_model_data/H08/H08_model_frame_index.csv")
frame_sites <- read_h08(
  "artifacts/06_model_data/H08/H08_model_frame_by_site.csv"
)
paired_audit <- read_h08(
  "artifacts/06_model_data/H08/H08_paired_sample_audit.csv"
)
common_audit <- read_h08(
  "artifacts/06_model_data/H08/H08_main_gap_common_sample_audit.csv"
)
fit_index <- read_h08("artifacts/07_models/H08/H08_model_fit_index.csv")
tests <- read_h08("artifacts/09_tables/H08/H08_model_tests.csv")
effects <- read_h08("artifacts/09_tables/H08/H08_model_effects.csv")
master <- read_h08("artifacts/09_tables/H08/H08_model_results_master.csv")
site_slopes <- read_h08(
  "artifacts/09_tables/H08/H08_site_specific_slopes.csv"
)
predictions <- read_h08(
  "artifacts/09_tables/H08/H08_centered_predictions.csv"
)
family_audit <- read_h08("artifacts/09_tables/H08/H08_family_audit.csv")
diagnostics <- read_h08(
  "artifacts/08_diagnostics/H08/H08_model_diagnostics.csv"
)
response_gate <- read_h08(
  "artifacts/08_diagnostics/H08/H08_response_family_gate.csv"
)
gap <- read_h08(
  "artifacts/09_tables/H08/H08_gap_timing_unaware_sensitivity.csv"
)
photoperiod <- read_h08(
  "artifacts/09_tables/H08/H08_photoperiod_sensitivity.csv"
)
participant <- read_h08(
  "artifacts/09_tables/H08/H08_participant_summary_sensitivity.csv"
)
exact_longest <- read_h08(
  paste0(
    "artifacts/09_tables/H08/",
    "H08_exactly_identified_longest_period_sensitivity.csv"
  )
)
observed_dose <- read_h08(
  "artifacts/09_tables/H08/H08_observed_dose_sensitivity.csv"
)
loo <- read_h08("artifacts/08_diagnostics/H08/H08_leave_one_site_out.csv")
v0 <- read_h08("artifacts/09_tables/H08/H08_v0_reproduction.csv")
v0_comparison <- read_h08(
  "artifacts/09_tables/H08/H08_v0_to_new_comparison.csv"
)
figure_manifest <- read_h08(
  "artifacts/12_manifests/H08/H08_figure_manifest.csv"
)

stopifnot(
  nrow(approvals) == 14L,
  all(approvals$approved),
  nrow(metrics) == 9L,
  all(metrics$metric_order == seq_len(9L)),
  !anyDuplicated(metrics$metric_id),
  nrow(runs) == 12L,
  !anyDuplicated(runs$run_id),
  nrow(families) == 8L,
  all(families$planned_n == 9L),
  nrow(formulas) == 13L,
  all(!grepl("temperature|latitude", formulas$formula, ignore.case = TRUE))
)

expected_formulas <- c(
  "response_value ~ site + (1 | site:Id)",
  "response_value ~ site + VLSQ8_c + (1 | site:Id)",
  "response_value ~ site * VLSQ8_c + (1 | site:Id)",
  "response_value ~ site + photoperiod_c + (1 | site:Id)",
  paste0(
    "response_value ~ site + photoperiod_c + VLSQ8_c + (1 | ",
    "site:Id)"
  ),
  paste0(
    "response_value ~ site * VLSQ8_c + photoperiod_c + (1 | ",
    "site:Id)"
  ),
  "participant_response ~ site",
  "participant_response ~ site + VLSQ8_c",
  "participant_response ~ site * VLSQ8_c"
)
stopifnot(all(expected_formulas %in% formulas$formula))

stopifnot(
  nrow(frames) == 108L,
  all(frames$participants > 0L),
  all(frames$participant_days > 0L),
  all(frames$sites %in% c(8L, 9L)),
  all(!is.na(frames$row_key_hash)),
  all(!is.na(frames$model_frame_hash)),
  nrow(frame_sites) > nrow(frames),
  nrow(paired_audit) == 18L,
  all(paired_audit$exact_counts_match),
  all(paired_audit$exact_row_keys_match),
  nrow(common_audit) == 18L,
  all(common_audit$exact_counts_match),
  all(common_audit$exact_row_keys_match)
)

primary_samples <- frames[
  frames$run_id == "main__glasses__all_available",
  ,
  drop = FALSE
]
chest_samples <- frames[
  frames$run_id == "main__chest__all_available",
  ,
  drop = FALSE
]
stopifnot(
  all(
    primary_samples$participants ==
      c(141, 141, 141, 141, 141, 139, 141, 141, 141)
  ),
  all(
    primary_samples$participant_days ==
      c(816, 816, 816, 816, 737, 655, 778, 816, 761)
  ),
  all(
    chest_samples$participants == c(154, 154, 154, 154, 154, 153, 154, 154, 154)
  ),
  all(
    chest_samples$participant_days ==
      c(902, 902, 902, 902, 818, 743, 861, 902, 851)
  )
)

stopifnot(
  nrow(fit_index) == 324L,
  all(fit_index$fit_status == "FITTED"),
  all(fit_index$observations > 0L),
  all(fit_index$converged),
  all(fit_index$positive_definite_hessian),
  all(fit_index$fixed_full_rank),
  nrow(effects) == 108L,
  all(effects$effect_status == "PASS"),
  nrow(master) == 108L,
  nrow(predictions) == 216L,
  all(
    predictions$interval_method == "delta_normal; physical lower bound applied"
  )
)

inferential <- tests[!is.na(tests$family_id), , drop = FALSE]
stopifnot(
  nrow(tests) == 216L,
  nrow(inferential) == 72L,
  all(inferential$comparison_status == "PASS"),
  all(inferential$n_obs_reduced == inferential$n_obs_full),
  all(is.finite(inferential$p_raw)),
  all(is.finite(inferential$p_adjusted)),
  !any(inferential$adjusted_significant),
  nrow(family_audit) == 8L,
  all(family_audit$registered_rows == 9L),
  all(family_audit$observed_raw_p == 9L),
  all(family_audit$observed_adjusted_p == 9L),
  all(family_audit$complete_nine_member_family),
  all(family_audit$independent_recalculation_matches)
)
for (family_id in families$family_id) {
  rows <- inferential$family_id == family_id
  stopifnot(sum(rows) == 9L)
  stopifnot(isTRUE(all.equal(
    inferential$p_adjusted[rows],
    stats::p.adjust(inferential$p_raw[rows], method = "BH", n = 9L)
  )))
}

stopifnot(
  nrow(diagnostics) == 108L,
  !any(diagnostics$diagnostic_status == "FAIL_MAJOR_GATE"),
  all(diagnostics$average_effect_status == "ESTIMABLE"),
  all(diagnostics$interaction_effect_status == "ESTIMABLE"),
  nrow(response_gate) == 9L,
  !any(response_gate$family_gate_status == "OPEN_COMMON_RESPONSE_FAMILY_GATE"),
  all(response_gate$major_failures == 0L)
)
sleep_zero <- diagnostics[
  diagnostics$metric_id == "duration_below_1_sleep_environment" &
    diagnostics$inferential_run,
  ,
  drop = FALSE
]
stopifnot(
  nrow(sleep_zero) == 4L,
  all(sleep_zero$observed_zero_fraction < 0.006),
  all(sleep_zero$expected_zero_fraction < 1e-6),
  all(
    sleep_zero$zero_mass_status ==
      "REVIEW_ABSOLUTE_STANDARDIZED_DIFFERENCE_AT_LEAST_3.29"
  )
)

stopifnot(
  nrow(site_slopes) == sum(frames$sites),
  all(site_slopes$slope_status == "PASS"),
  nrow(gap) == 36L,
  all(
    gap$stability_classification %in%
      c(
        "stable within model uncertainty",
        "precision-sensitive"
      )
  ),
  all(gap$exact_common_keys[gap$sample_scenario == "main_gap_common_sample"]),
  nrow(photoperiod) == 18L,
  all(photoperiod$converged),
  nrow(participant) == 18L,
  all(participant$converged),
  nrow(exact_longest) == 4L,
  all(exact_longest$converged),
  nrow(observed_dose) == 4L,
  all(observed_dose$converged),
  nrow(loo) == 153L,
  all(loo$refit_status == "PASS")
)

stopifnot(
  nrow(v0) == 18L,
  nrow(v0_comparison) == 18L,
  identical(
    v0$displayed_adjusted_p[v0$placement == "Near eye"],
    rep(">0.9", 9L)
  ),
  identical(
    v0$displayed_adjusted_p[v0$placement == "Chest"],
    c("0.4", "0.7", ">0.9", ">0.9", ">0.9", "0.3", ">0.9", ">0.9", ">0.9")
  ),
  !any(v0_comparison$new_average_adjusted_significant)
)

stopifnot(
  nrow(figure_manifest) == 5L,
  all(file.exists(file.path(root, figure_manifest$figure_path))),
  all(file.exists(file.path(root, figure_manifest$source_data_path))),
  all(nzchar(figure_manifest$alt_text))
)

display_boundary <- nh_format_p_value(c(0.0009999, 0.001, 0.247, NA_real_))
stopifnot(identical(display_boundary, c("<0.001", "0.001", "0.247", "—")))

cat("H08 Stage 2 tests passed\n")
