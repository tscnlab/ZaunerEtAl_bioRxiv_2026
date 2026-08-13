#!/usr/bin/env Rscript

# Focused no-refit verifier for H06-D-014 / H06-D-G2A.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
.libPaths(c(
  file.path(root, "renv/library/macos/R-4.6/aarch64-apple-darwin23"),
  .libPaths()
))

required_packages <- c("digest", "dplyr", "readr", "tibble")
missing_packages <- required_packages[!vapply(
  required_packages,
  requireNamespace,
  logical(1L),
  quietly = TRUE
)]
if (length(missing_packages)) {
  stop(
    sprintf("Missing synchronized packages: %s", paste(missing_packages, collapse = ", ")),
    call. = FALSE
  )
}

source(file.path(
  root,
  "scripts/hypotheses/H06_daily/h06_daily_h01_diagnostic_alignment_contract.R"
))

assert_h06d <- function(condition, message) {
  if (!isTRUE(condition)) stop(message, call. = FALSE)
  invisible(TRUE)
}

read_h06d <- function(relative_path) {
  readr::read_csv(
    file.path(root, relative_path),
    show_col_types = FALSE,
    na = c("", "NA")
  )
}

verify_manifest <- function(relative_path, expected_schema) {
  manifest <- read_h06d(relative_path)
  assert_h06d(
    identical(names(manifest), expected_schema),
    sprintf("Manifest schema changed: %s", relative_path)
  )
  assert_h06d(nrow(manifest) > 0L, sprintf("Manifest is empty: %s", relative_path))
  assert_h06d(
    !anyDuplicated(manifest$relative_path) &&
      !relative_path %in% manifest$relative_path,
    sprintf("Manifest is duplicated or circular: %s", relative_path)
  )
  absolute <- file.path(root, manifest$relative_path)
  assert_h06d(all(file.exists(absolute)), sprintf("Manifest path missing: %s", relative_path))
  observed_hash <- vapply(absolute, h06d_h01_sha256, character(1L))
  observed_bytes <- as.numeric(file.info(absolute)$size)
  assert_h06d(
    identical(unname(observed_hash), manifest$sha256) &&
      identical(observed_bytes, as.numeric(manifest$bytes)),
    sprintf("Manifest identity failed: %s", relative_path)
  )
  manifest
}

assert_h06d(
  identical(as.character(getRversion()), "4.6.1"),
  "The H06-D-014 focused test requires R 4.6.1"
)

# Controlling decision and all direct frozen inputs.
direct <- h06d_h01_verify_direct_inputs(root)
assert_h06d(
  nrow(direct) == 24L && all(direct$identity_verified) &&
    all(direct$authorization == "H06-D-014") &&
    all(direct$gate == "H06-D-G2A"),
  "The 24-entry direct-input contract failed"
)
decision_text <- paste(
  readLines(file.path(root, direct$relative_path[[1L]]), warn = FALSE),
  collapse = "\n"
)
assert_h06d(
  grepl("H06-D-014", decision_text, fixed = TRUE) &&
    grepl("judged visually", decision_text, fixed = TRUE) &&
    grepl(
      "no numeric residual test or threshold automatically sets",
      decision_text,
      fixed = TRUE
    ),
  "The controlling H06-D-014 visual-review rule changed"
)

input_manifest <- read_h06d(
  "artifacts/12_manifests/H06_daily/H06_daily_h01_diagnostic_alignment_input_manifest.csv"
)
assert_h06d(
  nrow(input_manifest) == 24L &&
    identical(input_manifest$relative_path, direct$relative_path) &&
    identical(input_manifest$expected_sha256, direct$expected_sha256) &&
    all(input_manifest$identity_verified),
  "The serialized H06-D-014 input manifest changed"
)

# Required pre-visual implementation replay.
previsual <- read_h06d(
  "artifacts/08_diagnostics/H06_daily/H06_daily_h01_previsual_replay.csv"
)
expected_previsual <- tibble::tribble(
  ~scope, ~provisional_h01_class, ~cells,
  "all_468_cells", "PASS", 311,
  "all_468_cells", "WARN_REVIEW", 157,
  "all_468_cells", "FAIL_MAJOR_GATE", 0,
  "primary_near_eye_all_available_39_cells", "PASS", 26,
  "primary_near_eye_all_available_39_cells", "WARN_REVIEW", 13,
  "primary_near_eye_all_available_39_cells", "FAIL_MAJOR_GATE", 0
)
assert_h06d(
  identical(
    previsual[, c("scope", "provisional_h01_class", "cells")],
    expected_previsual
  ),
  "The required 311/157/0 and 26/13/0 replay changed"
)

# Complete plot/source-data evidence and manual visual review.
plot_index <- read_h06d(
  "artifacts/08_diagnostics/H06_daily/H06_daily_h01_visual_residual_plot_index.csv"
)
atlas_index <- read_h06d(
  "artifacts/08_diagnostics/H06_daily/H06_daily_h01_visual_residual_atlas_index.csv"
)
visual <- read_h06d(
  "artifacts/08_diagnostics/H06_daily/H06_daily_h01_visual_residual_review.csv"
)
assert_h06d(
  nrow(plot_index) == 471L && nrow(atlas_index) == 37L && nrow(visual) == 471L &&
    !anyDuplicated(plot_index$audit_cell_id) &&
    !anyDuplicated(plot_index$diagnostic_plot_relative_path) &&
    !anyDuplicated(plot_index$source_data_relative_path) &&
    !anyDuplicated(visual$audit_cell_id) &&
    all(plot_index$numeric_navigation_only),
  "The 471-cell/37-atlas visual-evidence inventory changed"
)

plot_paths <- file.path(root, plot_index$diagnostic_plot_relative_path)
source_paths <- file.path(root, plot_index$source_data_relative_path)
atlas_paths <- file.path(root, atlas_index$atlas_relative_path)
assert_h06d(
  all(file.exists(plot_paths)) && all(file.exists(source_paths)) &&
    all(file.exists(atlas_paths)) &&
    identical(
      unname(vapply(plot_paths, h06d_h01_sha256, character(1L))),
      plot_index$diagnostic_plot_sha256
    ) &&
    identical(
      unname(vapply(source_paths, h06d_h01_sha256, character(1L))),
      plot_index$source_data_sha256
    ) &&
    identical(
      unname(vapply(atlas_paths, h06d_h01_sha256, character(1L))),
      atlas_index$atlas_sha256
    ),
  "A diagnostic plot, paired source CSV, or atlas identity failed"
)
assert_h06d(
  all(visual$visual_residual_verdict == "REVIEW_LIMITATION") &&
    !any(visual$visual_residual_verdict == "FAIL_GROSS") &&
    !any(visual$numeric_threshold_set_verdict) &&
    all(nzchar(visual$reviewer)) && all(nzchar(visual$review_date)) &&
    all(nzchar(visual$visual_reason_codes)) &&
    all(nzchar(visual$visual_explanation)),
  "The complete manual visual review changed or used a numeric verdict"
)

# Exact hard clock-unit defect and unaffected cells.
unit_audit <- read_h06d(
  "artifacts/08_diagnostics/H06_daily/H06_daily_h01_timing_unit_contract_audit.csv"
)
family_impact <- read_h06d(
  "artifacts/08_diagnostics/H06_daily/H06_daily_h01_timing_unit_family_impact.csv"
)
classification <- read_h06d(
  "artifacts/08_diagnostics/H06_daily/H06_daily_h01_aligned_cell_classification.csv"
)
affected <- dplyr::filter(classification, !.data$timing_construct_unit_valid)
expected_timing <- c(
  "m10_midpoint", "l10_midpoint", "mean_timing_above_250",
  "first_timing_above_250", "last_timing_above_250"
)
assert_h06d(
  nrow(unit_audit) == 10L &&
    sum(unit_audit$affected_stored_cells) == 90L &&
    all(unit_audit$primary_unit_contract_valid) &&
    all(unit_audit$gap_unit_contract_valid) &&
    all(unit_audit$all_stored_responses_equal_gap_hours_divided_by_60) &&
    setequal(unit_audit$metric_id, expected_timing) &&
    setequal(unit_audit$placement_id, c("near_eye", "chest")) &&
    all(unit_audit$construct_gate == "FAIL_CONSTRUCT_UNIT_DOUBLE_CONVERSION"),
  "The source-unit or erroneous-adapter evidence changed"
)
assert_h06d(
  nrow(classification) == 468L && nrow(affected) == 90L &&
    all(affected$dataset_id == "gap_timing_unaware") &&
    setequal(affected$metric_id, expected_timing) &&
    setequal(affected$placement_id, c("near_eye", "chest")) &&
    setequal(
      affected$sample_role,
      c("all_available", "paired_common", "dataset_common")
    ) &&
    setequal(
      affected$predictor_id,
      c("work_free_day", "activity_status", "previous_sleep_duration_centered_h")
    ) &&
    all(table(affected$metric_id) == 18L) &&
    all(table(affected$placement_id) == 45L) &&
    all(table(affected$sample_role) == 30L) &&
    all(table(affected$predictor_id) == 30L) &&
    all(affected$hard_gate_reason_codes == "TIMING_CONSTRUCT_UNIT_DOUBLE_CONVERSION"),
  "The exact 90-cell gap clock-unit failure changed"
)
unaffected <- dplyr::filter(classification, .data$timing_construct_unit_valid)
assert_h06d(
  nrow(unaffected) == 378L &&
    sum(unaffected$dataset_id == "primary") == 234L &&
    sum(unaffected$dataset_id == "gap_timing_unaware") == 144L &&
    all(unaffected$dataset_id == "primary" |
          !unaffected$metric_slot %in% c(9L, 10L, 11L, 12L, 13L)),
  "The exact 378-cell unaffected inventory changed"
)
assert_h06d(
  nrow(family_impact) == 6L &&
    all(family_impact$invalid_timing_slots == 5L) &&
    all(family_impact$family_slots == 15L) &&
    all(family_impact$frozen_bh_values_must_not_be_interpreted) &&
    setequal(family_impact$test_type, c("association", "heterogeneity")) &&
    length(unique(family_impact$multiplicity_family_id)) == 6L,
  "The six contaminated gap-family inventory changed"
)

# Final classes and H01 nonblocking sidecars.
class_counts <- table(classification$h01_diagnostic_class)
assert_h06d(
  unname(class_counts[["WARN_REVIEW"]]) == 378L &&
    unname(class_counts[["FAIL_MAJOR_GATE"]]) == 90L &&
    sum(classification$h01_diagnostic_class == "PASS") == 0L &&
    all(classification$visual_residual_verdict == "REVIEW_LIMITATION") &&
    !any(classification$numeric_residual_threshold_set_verdict) &&
    all(classification$ar_sidecar_nonblocking) &&
    all(classification$influence_sidecar_nonblocking) &&
    all(classification$period_sidecar_nonblocking) &&
    all(classification$family_sensitivity_sidecar_nonblocking),
  "The 0/378/90 H01-aligned classification or sidecar rule changed"
)
sidecars <- read_h06d(
  "artifacts/08_diagnostics/H06_daily/H06_daily_h01_sidecar_retention_audit.csv"
)
assert_h06d(
  nrow(sidecars) == 4L &&
    setequal(sidecars$sidecar_group, c("ar", "influence", "period", "response_family")) &&
    all(sidecars$rows == 468L) &&
    all(sidecars$exact_in_memory_identity) &&
    !any(sidecars$overall_class_input),
  "A mandatory nonblocking sidecar changed"
)

# Frozen inferential fields and family-level claim blocks.
frozen_bh <- read_h06d(
  "artifacts/09_tables/H06_daily/H06_daily_non_l10_production_bh_families.csv"
)
claims <- read_h06d(
  "artifacts/09_tables/H06_daily/H06_daily_h01_aligned_claim_eligibility.csv"
)
for (field in c(
  "raw_p_value", "bh_adjusted_p_value", "raw_rank_within_available",
  "raw_decision", "adjusted_decision"
)) {
  assert_h06d(
    identical(claims[[field]], frozen_bh[[field]]),
    sprintf("Frozen p/FDR field changed: %s", field)
  )
}
assert_h06d(
  nrow(claims) == 180L && !any(claims$p_fdr_values_changed) &&
    sum(!claims$multiplicity_family_construct_valid) == 90L &&
    length(unique(claims$multiplicity_family_id[
      !claims$multiplicity_family_construct_valid
    ])) == 6L &&
    !any(claims$h01_claim_eligible[
      claims$dataset_id == "gap_timing_unaware"
    ]),
  "Frozen inferential fields or the six-family block changed"
)
claim_summary <- read_h06d(
  "artifacts/09_tables/H06_daily/H06_daily_h01_claim_transition_summary.csv"
)
primary_claims <- dplyr::filter(claim_summary, .data$dataset_id == "primary")
gap_claims <- dplyr::filter(claim_summary, .data$dataset_id == "gap_timing_unaware")
assert_h06d(
  sum(primary_claims$fdr_supported) == 38L &&
    sum(primary_claims$h01_claim_eligible) == 38L &&
    sum(primary_claims$became_claim_eligible_under_h01) == 32L &&
    all(primary_claims$multiplicity_family_construct_valid) &&
    sum(gap_claims$fdr_supported) == 40L &&
    sum(gap_claims$h01_claim_eligible) == 0L &&
    !any(gap_claims$multiplicity_family_construct_valid) &&
    !any(claim_summary$p_fdr_values_changed),
  "The primary claim transition or gap-family block changed"
)

# Shifted-log L10 remains pilot-only; historical two-part failure is retained.
l10 <- read_h06d(
  "artifacts/08_diagnostics/H06_daily/H06_daily_h01_l10_shiftlog_reclassification.csv"
)
assert_h06d(
  nrow(l10) == 3L && all(l10$h01_diagnostic_class == "WARN_REVIEW") &&
    all(l10$visual_residual_verdict == "REVIEW_LIMITATION") &&
    all(l10$temporal_disposition_is_nonblocking_sidecar) &&
    !any(l10$pilot_raw_p_values_accepted) &&
    !any(l10$l10_bh_slot_populated) &&
    !any(l10$full_l10_production_authorized) &&
    all(grepl("NON_ESTIMABLE_COMPONENT_SEPARATION", l10$historical_two_part_status)),
  "The bounded shifted-log L10 reassessment changed"
)

# Historical identities, task-local outputs, and rendered gate language.
protected <- read_h06d(
  "artifacts/08_diagnostics/H06_daily/H06_daily_h01_protected_identity_verification.csv"
)
protected_absolute <- file.path(root, protected$relative_path)
assert_h06d(
  all(file.exists(protected_absolute)) &&
    identical(
      unname(vapply(protected_absolute, h06d_h01_sha256, character(1L))),
      protected$expected_sha256
    ) &&
    identical(
      as.numeric(file.info(protected_absolute)$size),
      as.numeric(protected$bytes_after)
    ),
  "A protected identity changed after the no-refit amendment"
)
assert_h06d(
  nrow(protected) == 1011L && all(protected$identity_verified) &&
    sum(protected$record_set == "H06_D_G2_987_ENTRY_OUTPUT_MANIFEST") == 987L &&
    sum(protected$record_set == "H06_D_014_DIRECT_INPUTS") == 24L &&
    identical(protected$expected_sha256, protected$observed_before_sha256) &&
    identical(protected$expected_sha256, protected$observed_after_sha256) &&
    identical(protected$bytes_before, protected$bytes_after),
  "The 1,011 protected identities changed"
)

manifest_schema <- c("relative_path", "sha256", "bytes", "role", "producer", "r_version")
code_manifest <- verify_manifest(
  "artifacts/12_manifests/H06_daily/H06_daily_h01_diagnostic_alignment_code_manifest.csv",
  manifest_schema
)
output_manifest <- verify_manifest(
  "artifacts/12_manifests/H06_daily/H06_daily_h01_diagnostic_alignment_output_manifest.csv",
  manifest_schema
)
report_manifest <- verify_manifest(
  "audit/hypotheses/H06_daily/H06_daily_h01_diagnostic_alignment_report_manifest.csv",
  manifest_schema
)
assert_h06d(
  nrow(code_manifest) == 8L && nrow(output_manifest) == 997L &&
    nrow(report_manifest) == 3L,
  "The non-circular H06-D-014 code/output/report manifest counts changed"
)

software <- read_h06d(
  "artifacts/12_manifests/H06_daily/H06_daily_h01_diagnostic_alignment_software_manifest.csv"
)
assert_h06d(
  identical(names(software), c("component", "version", "role")) &&
    software$version[software$component == "R"] == "4.6.1" &&
    all(c("digest", "dplyr", "ggplot2", "glmmTMB", "gt", "lme4", "patchwork", "readr", "tibble", "tidyr") %in%
          software$component),
  "The H06-D-014 software manifest changed"
)

report_html <- file.path(
  root,
  "audit/hypotheses/H06_daily/13_h01_diagnostic_alignment.html"
)
html_text <- paste(readLines(report_html, warn = FALSE), collapse = "\n")
assert_h06d(
  file.exists(report_html) &&
    grepl("H06-D-G2A author stop gate", html_text, fixed = TRUE) &&
    grepl("90 stored gap timing cells", html_text, fixed = TRUE) &&
    grepl("all six gap BH families are blocked", html_text, fixed = TRUE) &&
    grepl("Stage 3 and Stage 4 remain blocked", html_text, fixed = TRUE),
  "The rendered H06-D-G2A stop/report language changed"
)

cat(paste0(
  "PASS: H06-D-014 / H06-D-G2A focused verification; ",
  "471 visual reviews, 378 WARN_REVIEW, 90 construct failures, ",
  "six blocked gap families, 32 newly eligible primary claims, ",
  "and 1,011 protected identities verified.\n"
))
