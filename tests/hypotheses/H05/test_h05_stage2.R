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

stopifnot(
  nrow(approvals) == 13L,
  all(approvals$approved),
  nrow(factors) == 4L,
  identical(factors$factor_id, c("leba_f2", "leba_f3", "leba_f4", "leba_f5")),
  nrow(metrics) == 17L,
  all(metrics$metric_order == seq_len(17L)),
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
  ) == 49L,
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
  all(sleep_diagnostics$model_adequacy ==
    "acceptable_with_specified_limitations")
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
    "placement", "metric_id", "observations", "participants", "sites",
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
    paired_display$observations__near_eye ==
      paired_display$observations__chest
  ),
  all(
    paired_display$participants__near_eye ==
      paired_display$participants__chest
  ),
  all(paired_display$sites__near_eye == 8L),
  min(paired_display$participants__near_eye) == 110L,
  max(paired_display$participants__near_eye) == 112L,
  min(paired_display$participant_days__near_eye, na.rm = TRUE) == 505L,
  max(paired_display$participant_days__near_eye, na.rm = TRUE) == 643L
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
  grepl("different response variable or model structure", stage2_text_lower, fixed = TRUE),
  !grepl("0.1245", stage2_text, fixed = TRUE),
  !grepl("0.0377", stage2_text, fixed = TRUE),
  !grepl("0.0325", stage2_text, fixed = TRUE),
  !grepl(">0.999", stage2_text, fixed = TRUE)
)

cat(
  paste0(
    "H05 Stage 2 tests passed: 544 fixed-site cells, three complete ",
    "68-test BH families, 612 primary leave-one-site-out refits, and exact ",
    "V0 reconstruction.\n"
  )
)
