# Verify the H05 Stage 2 contracts and generated analytical artifacts.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)

source(file.path(root, "scripts/pipeline/paths_io.R"))
source(file.path(root, "scripts/pipeline/multiplicity.R"))
source(file.path(root, "scripts/pipeline/p_value_display.R"))
source(file.path(root, "scripts/hypotheses/H01/h01_contract.R"))
source(file.path(root, "scripts/hypotheses/H05/h05_contract.R"))

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("H05 Stage 2 tests require R 4.6.1", call. = FALSE)
}

read_h05 <- function(...) {
  readr::read_csv(
    file.path(root, ...),
    show_col_types = FALSE,
    na = ""
  )
}

input_contract <- h05_input_contract(root)
for (item in input_contract) {
  stopifnot(identical(artifact_sha256(item$path), item$sha256))
  if (!is.null(item$manifest)) {
    stopifnot(
      identical(
        artifact_sha256(item$manifest),
        item$manifest_sha256
      )
    )
  }
}

approvals <- read_h05(
  "artifacts/06_model_data/H05/H05_author_approvals.csv"
)
factors <- read_h05("artifacts/06_model_data/H05/H05_factor_registry.csv")
metrics <- read_h05("artifacts/06_model_data/H05/H05_metric_registry.csv")
runs <- read_h05("artifacts/06_model_data/H05/H05_run_registry.csv")
frames <- read_h05(
  "artifacts/06_model_data/H05/H05_model_frame_index.csv"
)
effects <- read_h05("artifacts/09_tables/H05/H05_model_effects.csv")
tests <- read_h05("artifacts/09_tables/H05/H05_model_tests.csv")
master <- read_h05("artifacts/09_tables/H05/H05_model_results_master.csv")
family_audit <- read_h05("artifacts/09_tables/H05/H05_family_audit.csv")
diagnostics <- read_h05(
  "artifacts/08_diagnostics/H05/H05_model_diagnostics.csv"
)
random_site <- read_h05(
  "artifacts/09_tables/H05/H05_random_site_sensitivity.csv"
)
loo <- read_h05(
  "artifacts/09_tables/H05/H05_leave_one_site_out_refits.csv"
)
paired <- read_h05(
  "artifacts/09_tables/H05/H05_paired_placement_comparison.csv"
)
exact_bout <- read_h05(
  paste0(
    "artifacts/09_tables/H05/",
    "H05_exactly_identified_longest_bout_sensitivity.csv"
  )
)
v0 <- read_h05("artifacts/09_tables/H05/H05_v0_reproduction.csv")
paired_display <- read_h05(
  "artifacts/11_source_data/H05/H05_paired_effect_comparison_data.csv"
)
reader_near <- read_h05(
  "artifacts/11_source_data/H05/H05_reader_near_eye_results.csv"
)
reader_chest <- read_h05(
  "artifacts/11_source_data/H05/H05_reader_chest_results.csv"
)
mder_upper_tail <- read_h05(
  "artifacts/08_diagnostics/H05/H05_mder_metric010_upper_tail_summary.csv"
)
mder_influence <- read_h05(
  "artifacts/08_diagnostics/H05/H05_mder_metric010_influence_refits.csv"
)
mder_gap_influence <- read_h05(
  paste0(
    "artifacts/08_diagnostics/H05/",
    "H05_mder_metric010_gap_influence_refits.csv"
  )
)
mder_gap_paired <- read_h05(
  paste0(
    "artifacts/09_tables/H05/",
    "H05_mder_metric010_gap_paired_placement_comparison.csv"
  )
)
mder_reconciliation <- read_h05(
  "artifacts/12_manifests/H05/H05_metric010_reconciliation.csv"
)
mder_gap_reconciliation <- read_h05(
  paste0(
    "artifacts/12_manifests/H05/",
    "H05_metric010_gap_reseal_reconciliation.csv"
  )
)
l10_reconciliation <- read_h05(
  "artifacts/12_manifests/H05/H05_metric011_reconciliation.csv"
)
l10_frame_audit <- read_h05(
  paste0(
    "artifacts/12_manifests/H05/",
    "H05_metric011_primary_l10_frame_audit.csv"
  )
)
l10_bh_audit <- read_h05(
  "artifacts/12_manifests/H05/H05_metric011_bh_change_audit.csv"
)
l10_result_change <- read_h05(
  paste0(
    "artifacts/12_manifests/H05/",
    "H05_metric011_l10_result_change_audit.csv"
  )
)
l10_input_cells <- read_h05(
  "artifacts/12_manifests/H05/H05_metric011_input_cell_audit.csv"
)
l10_artifact_manifest <- read_h05(
  paste0(
    "artifacts/12_manifests/H05/",
    "H05_metric011_artifact_update_manifest.csv"
  )
)

stopifnot(
  nrow(approvals) == 13L,
  all(approvals$approved),
  nrow(factors) == 4L,
  identical(factors$factor_id, c("leba_f2", "leba_f3", "leba_f4", "leba_f5")),
  nrow(metrics) == 17L,
  all(metrics$metric_order == seq_len(17L)),
  metrics$metric_id[metrics$metric_order == 17L] ==
    "mder_mean_of_viable_ratios",
  nrow(runs) == 8L,
  sum(runs$inferential_family) == 3L,
  all(runs$family_n[runs$inferential_family] == 68L),
  nrow(frames) == 544L,
  nrow(effects) == 544L,
  nrow(tests) == 544L,
  nrow(master) == 544L,
  nrow(diagnostics) == 544L,
  all(!is.na(frames$model_frame_hash)),
  all(frames$missing_leba_rows == 0L)
)

inference <- tests[tests$inferential_family, , drop = FALSE]
stopifnot(
  nrow(inference) == 204L,
  all(inference$comparison_status == "PASS"),
  all(inference$n_obs_full == inference$n_obs_reduced),
  all(is.finite(inference$p_raw)),
  all(is.finite(inference$p_adjusted))
)
for (family in unique(inference$family_id)) {
  rows <- inference[inference$family_id == family, , drop = FALSE]
  reproduced <- adjust_p_family(rows$p_raw, method = "BH", n = 68L)
  stopifnot(
    nrow(rows) == 68L,
    isTRUE(all.equal(rows$p_adjusted, reproduced, tolerance = 1e-14))
  )
}
stopifnot(
  nrow(family_audit) == 3L,
  all(family_audit$registry_rows == 68L),
  all(family_audit$observed_tests == 68L),
  all(family_audit$vector_bh_verified),
  all(family_audit$passes_bh_0_05 == 0L)
)

primary <- master[
  master$run_id == "main__glasses__all_available",
  ,
  drop = FALSE
]
stopifnot(
  nrow(primary) == 68L,
  sum(primary$model_adequacy == "acceptable") == 19L,
  sum(
    primary$model_adequacy == "acceptable_with_specified_limitations"
  ) ==
    49L,
  sum(primary$model_adequacy == "not_acceptable") == 0L,
  sum(primary$p_adjusted <= 0.05) == 0L
)

sleep_diagnostics <- diagnostics[
  diagnostics$run_id == "main__glasses__all_available" &
    diagnostics$metric_id == "duration_below_1_sleep_environment",
  ,
  drop = FALSE
]
stopifnot(
  nrow(sleep_diagnostics) == 4L,
  all(sleep_diagnostics$residual_status == "WARN_STRONG_TWEEDIE_MISFIT"),
  all(sleep_diagnostics$prediction_bound_status == "WARN_PREDICTED_BOUND"),
  all(
    sleep_diagnostics$model_adequacy == "acceptable_with_specified_limitations"
  )
)

stopifnot(
  nrow(reader_near) == 68L,
  nrow(reader_chest) == 68L,
  sum(reader_near$reader_inference_status == "unfit_for_inference") == 4L,
  sum(reader_chest$reader_inference_status == "unfit_for_inference") == 4L,
  identical(
    nh_format_p_value(c(0.0009, 0.001, 0.032, 0.247, 1, NA_real_)),
    c("<0.001", "0.001", "0.032", "0.247", "1.000", "—")
  )
)

paired_participant <- unique(frames[
  frames$data_scenario_id == "main" &
    frames$sample_scenario == "paired_common_sample" &
    frames$metric_order %in% 1:2,
  c(
    "placement",
    "metric_id",
    "observations",
    "participants",
    "sites",
    "paired_participant_rows_derived"
  )
])
stopifnot(
  nrow(paired_participant) == 4L,
  all(paired_participant$observations == 112L),
  all(paired_participant$participants == 112L),
  all(paired_participant$sites == 8L),
  all(paired_participant$paired_participant_rows_derived)
)

stopifnot(
  nrow(random_site) == 136L,
  sum(random_site$random_site_status == "DESCRIPTIVE_UNSTABLE") == 15L,
  nrow(loo) == 612L,
  all(loo$refit_status == "PASS"),
  nrow(paired) == 68L,
  nrow(exact_bout) == 4L,
  all(exact_bout$observations == 500L),
  all(exact_bout$participants == 132L),
  all(exact_bout$sites == 9L),
  all(exact_bout$sign_concordant)
)

stopifnot(
  nrow(paired_display) == 68L,
  all(paired_display$exact_sample_match),
  all(
    paired_display$analysis_unit__near_eye ==
      paired_display$analysis_unit__chest
  ),
  all(
    paired_display$observations__near_eye == paired_display$observations__chest
  ),
  all(
    paired_display$participants__near_eye == paired_display$participants__chest
  ),
  all(paired_display$sites__near_eye == 8L),
  min(paired_display$participants__near_eye) == 107L,
  max(paired_display$participants__near_eye) == 112L,
  min(paired_display$participant_days__near_eye, na.rm = TRUE) == 489L,
  max(paired_display$participant_days__near_eye, na.rm = TRUE) == 643L
)

mder_primary <- primary[
  primary$metric_id == "mder_mean_of_viable_ratios",
  ,
  drop = FALSE
]
mder_chest <- master[
  master$run_id == "main__chest__all_available" &
    master$metric_id == "mder_mean_of_viable_ratios",
  ,
  drop = FALSE
]
mder_gap_near <- master[
  master$run_id == "manuscript_prepared_data__glasses__all_available" &
    master$metric_id == "mder_mean_of_viable_ratios",
  ,
  drop = FALSE
]
mder_gap_chest <- master[
  master$run_id == "manuscript_prepared_data__chest__all_available" &
    master$metric_id == "mder_mean_of_viable_ratios",
  ,
  drop = FALSE
]
stopifnot(
  nrow(mder_primary) == 4L,
  nrow(mder_chest) == 4L,
  all(mder_primary$observations == 702L),
  all(mder_primary$participants == 137L),
  all(mder_primary$participant_days == 702L),
  all(mder_primary$sites == 9L),
  all(mder_chest$observations == 732L),
  all(mder_chest$participants == 152L),
  all(mder_chest$participant_days == 732L),
  all(mder_chest$sites == 8L),
  isTRUE(all.equal(
    mder_primary$estimate_model_per_sd[mder_primary$factor_id == "leba_f2"],
    0.0040602820470024403,
    tolerance = 1e-12
  )),
  isTRUE(all.equal(
    mder_primary$p_adjusted[mder_primary$factor_id == "leba_f5"],
    0.16901794240238349,
    tolerance = 1e-12
  )),
  all(mder_primary$p_adjusted > 0.05),
  all(mder_chest$p_adjusted > 0.05),
  nrow(mder_gap_near) == 4L,
  all(mder_gap_near$observations == 687L),
  all(mder_gap_near$participants == 137L),
  all(mder_gap_near$participant_days == 687L),
  all(mder_gap_near$sites == 9L),
  all(mder_gap_near$p_adjusted > 0.05),
  nrow(mder_gap_chest) == 4L,
  all(mder_gap_chest$observations == 723L),
  all(mder_gap_chest$participants == 152L),
  all(mder_gap_chest$participant_days == 723L),
  all(mder_gap_chest$sites == 8L),
  nrow(mder_upper_tail) == 8L,
  nrow(mder_influence) == 44L,
  all(mder_influence$refit_status == "PASS"),
  sum(mder_influence$sensitivity_interval_contains_zero) == 40L,
  all(
    mder_influence$sensitivity_interval_contains_zero[
      mder_influence$run_id == "main__chest__all_available"
    ]
  ),
  nrow(mder_gap_influence) == 44L,
  all(mder_gap_influence$refit_status == "PASS"),
  sum(mder_gap_influence$sensitivity_interval_contains_zero) == 40L,
  nrow(mder_gap_paired) == 4L,
  all(mder_gap_paired$exact_sample_match),
  all(mder_gap_paired$participant_days__glasses == 478L),
  all(mder_gap_paired$participants__glasses == 107L),
  all(mder_gap_paired$sites__glasses == 8L),
  all(mder_gap_paired$sign_concordant),
  all(mder_gap_paired$component_intervals_overlap),
  nrow(mder_reconciliation) == 20L,
  all(mder_reconciliation$invariant_verified),
  nrow(mder_gap_reconciliation) == 16L,
  all(mder_gap_reconciliation$invariant_verified),
  mder_gap_reconciliation$changed_rows[
    mder_gap_reconciliation$check_id == "H05_F3_non_MDER_BH_derivatives"
  ] ==
    27L
)

l10_primary <- master[
  master$data_scenario_id == "main" &
    master$metric_id == "l10_mean_medi",
  ,
  drop = FALSE
]
l10_reader_near <- reader_near[
  reader_near$metric_id == "l10_mean_medi",
  ,
  drop = FALSE
]
l10_reader_chest <- reader_chest[
  reader_chest$metric_id == "l10_mean_medi",
  ,
  drop = FALSE
]
stopifnot(
  nrow(l10_primary) == 16L,
  nrow(l10_reconciliation) == 22L,
  all(l10_reconciliation$invariant_verified),
  nrow(l10_frame_audit) == 4L,
  sum(l10_frame_audit$changed_l10_cells) == 16L,
  all(l10_frame_audit$old_value_lx == 4.163336342344337e-17),
  all(l10_frame_audit$new_value_lx == 0),
  all(l10_frame_audit$non_value_fields_identical),
  all(l10_frame_audit$metric_settings_provenance_updated),
  all(l10_frame_audit$changed_keys_verified),
  nrow(l10_input_cells) == 16L,
  all(l10_input_cells$current_value_lx == 0),
  setequal(
    l10_input_cells$scenario,
    c("all_available", "paired_common_sample")
  ),
  nrow(l10_result_change) == 16L,
  !any(l10_result_change$bh_retained_after, na.rm = TRUE),
  max(abs(l10_result_change$estimate_change_per_point)) < 4e-12,
  all(
    l10_result_change$after_model_adequacy ==
      "acceptable_with_specified_limitations"
  ),
  nrow(l10_bh_audit) == 204L,
  sum(l10_bh_audit$raw_p_changed) == 7L,
  sum(l10_bh_audit$adjusted_p_changed) == 2L,
  sum(l10_bh_audit$family_rank_changed) == 0L,
  !any(
    l10_bh_audit$raw_p_changed & !l10_bh_audit$permitted_raw_change
  ),
  !any(l10_bh_audit$raw_p_changed[
    l10_bh_audit$family_id == "H05-F3-manuscript-prepared"
  ]),
  nrow(l10_reader_near) == 4L,
  nrow(l10_reader_chest) == 4L,
  isTRUE(all.equal(
    l10_reader_near$estimate_model_per_point,
    l10_primary$estimate_model_per_point[
      l10_primary$run_id == "main__glasses__all_available"
    ],
    tolerance = 1e-15
  )),
  isTRUE(all.equal(
    l10_reader_chest$estimate_model_per_point,
    l10_primary$estimate_model_per_point[
      l10_primary$run_id == "main__chest__all_available"
    ],
    tolerance = 1e-15
  )),
  nrow(l10_artifact_manifest) == 29L,
  all(l10_artifact_manifest$status == "PASS"),
  all(l10_artifact_manifest$r_version == "4.6.1")
)
l10_manifest_paths <- file.path(root, l10_artifact_manifest$path)
stopifnot(
  all(file.exists(l10_manifest_paths)),
  identical(
    unname(vapply(l10_manifest_paths, artifact_sha256, character(1))),
    l10_artifact_manifest$sha256
  )
)

v0_near <- v0[v0$placement == "near-eye", , drop = FALSE]
v0_chest <- v0[v0$placement == "chest", , drop = FALSE]
v0_named <- v0_near[
  v0_near$factor_id == "leba_f2" &
    v0_near$v0_name %in% c("dose", "duration_above_1000"),
  ,
  drop = FALSE
]
stopifnot(
  nrow(v0) == 136L,
  nrow(v0_near) == 68L,
  nrow(v0_chest) == 68L,
  sum(v0_near$v0_display_flag) == 2L,
  sum(v0_chest$v0_display_flag) == 1L,
  sum(v0_near$consistent_spearman_flag) == 2L,
  sum(v0_chest$consistent_spearman_flag) == 0L,
  isTRUE(all.equal(
    sort(v0_named$spearman_rho),
    sort(c(0.2719094, 0.2903519)),
    tolerance = 1e-6
  )),
  isTRUE(all.equal(
    sort(v0_named$consistent_spearman_vector_bh),
    sort(c(0.03765590, 0.03252746)),
    tolerance = 1e-6
  ))
)

model_objects <- readRDS(
  file.path(root, "artifacts/07_models/H05/H05_inferential_model_objects.rds")
)
stopifnot(length(model_objects) == 204L)

required_figures <- c(
  "H05_v0_near_eye_faithful.png",
  "H05_v0_near_eye_corrected.png",
  "H05_v0_chest_faithful.png",
  "H05_v0_chest_corrected.png",
  "H05_primary_effect_overview.png",
  "H05_primary_model_adequacy.png",
  "H05_paired_placement_effects.png"
)
stopifnot(all(file.exists(file.path(
  root,
  "artifacts/10_figures/H05",
  required_figures
))))

stopifnot(file.exists(file.path(
  root,
  "artifacts/11_source_data/H05/H05_gap_timing_unaware_dataset.csv"
)))

stage2_html_path <- file.path(
  root,
  "audit/hypotheses/H05/02_implementation_and_v0_comparison.html"
)
stopifnot(file.exists(stage2_html_path))
stage2_document <- xml2::read_html(stage2_html_path)
stage2_text <- xml2::xml_text(stage2_document)
stage2_text_lower <- tolower(stage2_text)
stopifnot(
  grepl("Raw p", stage2_text, fixed = TRUE),
  grepl("BH-adjusted p", stage2_text, fixed = TRUE),
  grepl("0.124", stage2_text, fixed = TRUE),
  grepl("0.038", stage2_text, fixed = TRUE),
  grepl("0.033", stage2_text, fixed = TRUE),
  grepl("unfit for inference", stage2_text_lower, fixed = TRUE),
  grepl("gap-timing-unaware dataset", stage2_text_lower, fixed = TRUE),
  grepl("mean of viable one-minute", stage2_text_lower, fixed = TRUE),
  grepl("702 participant-days", stage2_text_lower, fixed = TRUE),
  grepl("732 participant-days", stage2_text_lower, fixed = TRUE),
  grepl("687 near-eye", stage2_text_lower, fixed = TRUE),
  grepl("723 chest", stage2_text_lower, fixed = TRUE),
  grepl("478 days from 107 participants", stage2_text_lower, fixed = TRUE),
  grepl("27 non-mder adjusted p-values", stage2_text_lower, fixed = TRUE),
  grepl("26 ranks", stage2_text_lower, fixed = TRUE),
  grepl("upper-tail", stage2_text_lower, fixed = TRUE),
  grepl("metric-010", stage2_text_lower, fixed = TRUE),
  grepl("metric-011", stage2_text_lower, fixed = TRUE),
  grepl("numerical-zero", stage2_text_lower, fixed = TRUE),
  grepl("three near-eye and five", stage2_text_lower, fixed = TRUE),
  grepl("seven of the eight inferential raw", stage2_text_lower, fixed = TRUE),
  grepl("no family rank changed", stage2_text_lower, fixed = TRUE),
  grepl("zero gap l10 refits", stage2_text_lower, fixed = TRUE),
  grepl(
    "different response variable or model structure",
    stage2_text_lower,
    fixed = TRUE
  ),
  !grepl("0.1245", stage2_text, fixed = TRUE),
  !grepl("0.0377", stage2_text, fixed = TRUE),
  !grepl("0.0325", stage2_text, fixed = TRUE),
  !grepl(">0.999", stage2_text, fixed = TRUE)
)

cat(
  paste0(
    "H05 Stage 2 tests passed: 544 fixed-site cells, three complete ",
    "68-test BH families, 612 primary leave-one-site-out refits, exact ",
    "V0 reconstruction, bounded METRIC-010 MDER reconciliation, and the ",
    "METRIC-011 primary L10 reseal with frozen non-L10 and gap L10 fits.\n"
  )
)
