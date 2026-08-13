#!/usr/bin/env Rscript

# Focused no-refit verifier for H06-D-013 production and the H06-D-G2 gate.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
.libPaths(c(
  file.path(root, "renv/library/macos/R-4.6/aarch64-apple-darwin23"),
  .libPaths()
))
suppressPackageStartupMessages({
  library(digest)
  library(dplyr)
  library(readr)
  library(tibble)
})
source(file.path(
  root,
  "scripts/hypotheses/H06_daily/h06_daily_non_l10_pilot_contract.R"
))
source(file.path(
  root,
  "scripts/hypotheses/H06_daily/h06_daily_non_l10_production_contract.R"
))

stopifnot(
  identical(as.character(getRversion()), "4.6.1"),
  identical(
    h06d_prod_sha256(file.path(
      root,
      "audit/decisions/h06_daily_non_l10_production_authorization.md"
    )),
    "0818d1618daa49d38b60680bf9585b99f51db098b4f6f7c652f1970e7cd1c547"
  ),
  identical(
    h06d_prod_sha256(file.path(
      root,
      "audit/decisions/h06_daily_timing_repair_acceptance.md"
    )),
    "739c654b9920f08b7da44fe3ecd667cfd30eb56fece91a3efae137c256623869"
  )
)

artifact <- function(stage, filename) {
  file.path(root, "artifacts", stage, "H06_daily", filename)
}
read_artifact <- function(stage, filename) {
  readr::read_csv(
    artifact(stage, filename),
    show_col_types = FALSE,
    na = c("", "NA")
  )
}
verify_manifest <- function(manifest) {
  paths <- file.path(root, manifest$relative_path)
  stopifnot(
    all(file.exists(paths)),
    identical(
      unname(vapply(paths, h06d_prod_sha256, character(1))),
      manifest$sha256
    ),
    identical(unname(as.numeric(file.info(paths)$size)), manifest$bytes)
  )
  invisible(TRUE)
}

input_manifest <- read_artifact(
  "12_manifests",
  "H06_daily_non_l10_production_input_manifest.csv"
)
stopifnot(
  all(input_manifest$verification_status == "PASS"),
  identical(input_manifest$expected_sha256, input_manifest$actual_sha256)
)
invisible(h06d_prod_verify_contract(root, h06d_prod_input_contract()))
invisible(h06d_prod_verify_contract(
  root,
  h06d_prod_main_h06_contract() |>
    dplyr::mutate(input_id = paste0("main_h06_", dplyr::row_number()), .before = 1L)
))

state <- readRDS(artifact(
  "08_diagnostics",
  "H06_daily_non_l10_production_state.rds"
))
stopifnot(
  identical(state$authorization, "H06-D-013"),
  identical(state$gate, "H06-D-G2"),
  identical(state$phase, "REPORT_READY"),
  state$completed_cells == 468L,
  state$completed_refits == 66664L,
  state$production_effects == 468L,
  state$production_raw_tests == 936L,
  state$multiplicity_families == 12L,
  state$multiplicity_slots == 180L,
  state$diagnostic_cells == 468L
)

frame_identity <- read_artifact(
  "06_model_data",
  "H06_daily_non_l10_production_frame_identity_check.csv"
)
base <- read_artifact(
  "08_diagnostics",
  "H06_daily_non_l10_production_base_checkpoint.csv"
)
influence_index <- read_artifact(
  "08_diagnostics",
  "H06_daily_non_l10_production_influence_checkpoint.csv"
)
influence_tasks <- read_artifact(
  "06_model_data",
  "H06_daily_non_l10_production_influence_task_inventory.csv"
)
stopifnot(
  nrow(frame_identity) == 468L,
  all(frame_identity$all_fields_identical),
  all(frame_identity$serialized_frame_hash_identical),
  nrow(base) == 468L,
  all(base$outer_success),
  !anyDuplicated(base$frame_key),
  nrow(influence_index) == 468L,
  sum(influence_index$completed_refits) == 66664L,
  nrow(influence_tasks) == 66664L,
  all(influence_tasks$global_task_id == seq_len(66664L))
)

effects <- read_artifact(
  "09_tables",
  "H06_daily_non_l10_production_effects.csv"
)
tests <- read_artifact(
  "09_tables",
  "H06_daily_non_l10_production_raw_tests.csv"
)
families <- read_artifact(
  "09_tables",
  "H06_daily_non_l10_production_bh_families.csv"
)
primary <- read_artifact(
  "09_tables",
  "H06_daily_non_l10_production_primary_results.csv"
)
diagnostics <- read_artifact(
  "08_diagnostics",
  "H06_daily_non_l10_production_diagnostic_assessment.csv"
)
influence <- read_artifact(
  "08_diagnostics",
  "H06_daily_non_l10_production_influence_results.csv"
)
mder <- read_artifact(
  "09_tables",
  "H06_daily_mder_metric010_model_tests.csv"
)
stopifnot(
  nrow(effects) == 468L,
  all(effects$interval_type %in% c(
    "model-based pointwise 95% confidence interval",
    "participant-cluster HC3 pointwise 95% confidence interval"
  )),
  nrow(tests) == 936L,
  table(tests$test_type)[["association"]] == 468L,
  table(tests$test_type)[["site_heterogeneity"]] == 468L,
  nrow(primary) == 39L,
  nrow(diagnostics) == 468L,
  !anyDuplicated(diagnostics$frame_key),
  all(diagnostics$diagnostic_status %in% c(
    "ACCEPTABLE", "ACCEPTABLE_WITH_LIMITATION", "NOT_ACCEPTABLE"
  )),
  nrow(influence) == 66664L,
  all(influence$global_task_id == seq_len(66664L))
)

stopifnot(
  nrow(families) == 180L,
  dplyr::n_distinct(families$multiplicity_family_id) == 12L,
  all(table(families$multiplicity_family_id) == 15L),
  all(families$family_slots_required == 15L),
  all(
    families$family_status ==
      "COMPLETE_NAMED_15_SLOT_FAMILY_WITH_NA_SLOTS"
  ),
  all(is.na(families$raw_p_value[families$metric_slot == 3L])),
  all(is.na(families$bh_adjusted_p_value[families$metric_slot == 3L])),
  all(
    families$slot_status[families$metric_slot == 3L] ==
      "FROZEN_NAMED_NA_L10_COMPONENT_FAILURE"
  ),
  all(
    families$slot_status[families$metric_slot == 15L] ==
      "FROZEN_MDER_RAW_RESULT"
  )
)
mder_family <- families |>
  dplyr::filter(.data$metric_slot == 15L) |>
  dplyr::arrange(.data$dataset_id, .data$predictor_order, .data$test_type)
mder_source <- mder |>
  dplyr::arrange(.data$dataset_id, .data$predictor_order, .data$test_type)
stopifnot(
  nrow(mder_family) == 12L,
  identical(mder_family$raw_p_value, mder_source$raw_p_value)
)

# The accepted timing limitations remain explicit in the controlling record
# and production claim fields; no production test can erase them.
acceptance_text <- paste(
  readLines(file.path(
    root,
    "audit/decisions/h06_daily_timing_repair_acceptance.md"
  ), warn = FALSE),
  collapse = "\n"
)
stopifnot(
  grepl("1.23 HC3 standard errors", acceptance_text, fixed = TRUE),
  grepl("1.26 HC3 standard errors", acceptance_text, fixed = TRUE),
  grepl("three additive no-nugget AR diagnostics remain unresolved", acceptance_text),
  all(
    diagnostics$heterogeneity_claim_status[
      diagnostics$route == "participant_cluster_HC3"
    ] == "NO_UNQUALIFIED_SITE_INTERACTION_CLAIM_SENSITIVITY_DEPENDENT"
  )
)

code_manifest <- read_artifact(
  "12_manifests",
  "H06_daily_non_l10_production_code_manifest.csv"
)
output_manifest <- read_artifact(
  "12_manifests",
  "H06_daily_non_l10_production_output_manifest.csv"
)
figure_manifest <- read_artifact(
  "12_manifests",
  "H06_daily_non_l10_production_figure_manifest.csv"
)
verify_manifest(code_manifest)
verify_manifest(output_manifest)
verify_manifest(figure_manifest)
stopifnot(
  sum(grepl("\\.png$", figure_manifest$relative_path)) == 2L,
  sum(grepl("source_data.*\\.csv$", figure_manifest$relative_path)) == 2L
)

preservation <- read_artifact(
  "08_diagnostics",
  "H06_daily_non_l10_production_preservation_final.csv"
)
stopifnot(
  nrow(preservation) >= 571L,
  all(preservation$identity_status == "BYTE_IDENTICAL")
)
protected_paths <- file.path(root, preservation$relative_path)
stopifnot(
  all(file.exists(protected_paths)),
  identical(
    unname(vapply(protected_paths, h06d_prod_sha256, character(1))),
    preservation$baseline_sha256
  ),
  identical(
    unname(as.numeric(file.info(protected_paths)$size)),
    preservation$baseline_bytes
  )
)

at_gate <- read_artifact(
  "08_diagnostics",
  "H06_daily_non_l10_production_preservation_at_gate.csv"
)
stopifnot(
  nrow(at_gate) == nrow(preservation),
  all(at_gate$identity_status == "BYTE_IDENTICAL"),
  identical(at_gate$baseline_sha256, preservation$baseline_sha256),
  identical(at_gate$current_sha256, preservation$current_sha256)
)
report_manifest <- readr::read_csv(file.path(
  root,
  "audit/hypotheses/H06_daily/",
  "H06_daily_stage2_production_report_manifest.csv"
), show_col_types = FALSE)
verify_manifest(report_manifest)
stopifnot(
  nrow(report_manifest) == 21L,
  !anyDuplicated(report_manifest$relative_path),
  file.info(file.path(
    root,
    "audit/hypotheses/H06_daily/12_stage2_production.html"
  ))$size > 100000
)

cat(sprintf(
  paste0(
    "H06-D-G2 focused verification PASS: 468 cells; 936 raw tests; ",
    "12 x 15 named BH slots; 66,664 deletion refits; %d protected identities.\n"
  ),
  nrow(preservation)
))
