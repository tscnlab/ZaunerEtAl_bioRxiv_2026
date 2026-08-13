#!/usr/bin/env Rscript

# Focused no-refit identity test for H06-D-011 timing-route acceptance.

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
missing_packages <- required_packages[
  !vapply(
    required_packages,
    requireNamespace,
    logical(1L),
    quietly = TRUE
  )
]
if (length(missing_packages)) {
  stop(
    sprintf(
      "Missing synchronized packages: %s",
      paste(missing_packages, collapse = ", ")
    ),
    call. = FALSE
  )
}

assert_h06d <- function(condition, message) {
  if (!isTRUE(condition)) {
    stop(message, call. = FALSE)
  }
  invisible(TRUE)
}
sha256 <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE)
}
read_csv <- function(relative_path) {
  readr::read_csv(
    file.path(root, relative_path),
    show_col_types = FALSE,
    na = c("", "NA")
  )
}
verify_file_manifest <- function(relative_path) {
  manifest <- read_csv(relative_path)
  assert_h06d(
    identical(
      names(manifest),
      c("relative_path", "sha256", "bytes", "role", "producer", "r_version")
    ),
    "The acceptance-manifest schema changed"
  )
  assert_h06d(nrow(manifest) > 0L, "The acceptance manifest is empty")
  assert_h06d(
    !anyDuplicated(manifest$relative_path),
    "The acceptance manifest contains duplicate paths"
  )
  absolute <- file.path(root, manifest$relative_path)
  assert_h06d(
    all(file.exists(absolute)),
    "An acceptance-manifest path is missing"
  )
  assert_h06d(
    identical(unname(vapply(absolute, sha256, character(1L))), manifest$sha256),
    "An acceptance-manifest SHA-256 identity failed"
  )
  assert_h06d(
    identical(as.numeric(file.info(absolute)$size), as.numeric(manifest$bytes)),
    "An acceptance-manifest byte count failed"
  )
  manifest
}

assert_h06d(
  identical(as.character(getRversion()), "4.6.1"),
  "The focused acceptance test requires R 4.6.1"
)
assert_h06d(
  identical(as.character(utils::packageVersion("digest")), "0.6.39") &&
    identical(as.character(utils::packageVersion("dplyr")), "1.2.1") &&
    identical(as.character(utils::packageVersion("readr")), "2.2.0") &&
    identical(as.character(utils::packageVersion("tibble")), "3.3.1"),
  "A focused acceptance-test package identity changed"
)

decision_pins <- tibble::tribble(
  ~relative_path,
  ~expected_sha256,
  ~decision_token,
  "audit/decisions/h06_daily_timing_repair_pilot_gate.md",
  "f398f748369351e084f19caba05a11636e8aead3df9ccd3586c8338100083461",
  "H06-D-010",
  "audit/decisions/h06_daily_timing_repair_acceptance.md",
  "739c654b9920f08b7da44fe3ecd667cfd30eb56fece91a3efae137c256623869",
  "H06-D-011"
)
for (index in seq_len(nrow(decision_pins))) {
  decision_path <- file.path(root, decision_pins$relative_path[[index]])
  decision_text <- paste(
    readLines(decision_path, warn = FALSE),
    collapse = "\n"
  )
  assert_h06d(
    sha256(decision_path) == decision_pins$expected_sha256[[index]],
    sprintf(
      "%s decision identity failed",
      decision_pins$decision_token[[index]]
    )
  )
  assert_h06d(
    grepl(decision_pins$decision_token[[index]], decision_text, fixed = TRUE),
    sprintf(
      "%s decision token is absent",
      decision_pins$decision_token[[index]]
    )
  )
}

acceptance_text <- paste(
  readLines(
    file.path(root, "audit/decisions/h06_daily_timing_repair_acceptance.md"),
    warn = FALSE
  ),
  collapse = "\n"
)
assert_h06d(
  grepl(
    "participant-cluster HC3 route exactly as recommended",
    acceptance_text,
    fixed = TRUE
  ) &&
    grepl("production not authorized", acceptance_text, fixed = TRUE) &&
    grepl(
      "does **not** accept any pilot estimate or p-value",
      acceptance_text,
      fixed = TRUE
    ),
  "The controlling acceptance disposition changed"
)

frame_contract <- read_csv(
  "artifacts/06_model_data/H06_daily/H06_daily_timing_repair_frame_contract.csv"
)
candidate_cells <- read_csv(
  "artifacts/08_diagnostics/H06_daily/H06_daily_timing_repair_candidate_cells.csv"
)
expected_metrics <- c(
  "m10_midpoint",
  "l10_midpoint",
  "first_timing_above_250",
  "last_timing_above_250"
)
expected_predictors <- c(
  "work_free_day",
  "activity_status",
  "previous_sleep_duration_centered_h"
)
expected_cells <- as.vector(outer(
  expected_metrics,
  expected_predictors,
  paste,
  sep = "__"
))
assert_h06d(
  nrow(frame_contract) == 12L &&
    nrow(candidate_cells) == 12L &&
    setequal(frame_contract$cell_id, expected_cells) &&
    setequal(candidate_cells$cell_id, expected_cells) &&
    all(frame_contract$frame_verification_status == "PASS") &&
    all(candidate_cells$candidate_gate_pass) &&
    all(
      candidate_cells$candidate_disposition ==
        "NUMERICALLY_ACCEPTABLE_CANDIDATE_ROUTE"
    ),
  "The 12 accepted timing candidate cells changed"
)

model_bundle_path <- file.path(
  root,
  "artifacts/07_models/H06_daily/H06_daily_timing_repair_pilot_models.rds"
)
assert_h06d(
  sha256(model_bundle_path) ==
    "769af576e4dd8ce2e5c059b49a57d7b7fa567b5b2bc5186cc5525fddbe6683ad",
  "The accepted timing-repair model-bundle identity changed"
)
model_bundle <- readRDS(model_bundle_path)
assert_h06d(
  identical(model_bundle$gate, "H06-D-G2P-TIMING-REPAIR") &&
    length(model_bundle$cells) == 12L &&
    setequal(names(model_bundle$cells), expected_cells),
  "The accepted timing-repair model-bundle contract changed"
)

raw_tests <- read_csv(
  "artifacts/09_tables/H06_daily/H06_daily_timing_repair_raw_tests.csv"
)
assert_h06d(
  nrow(raw_tests) == 24L &&
    setequal(raw_tests$cell_id, expected_cells) &&
    all(table(raw_tests$cell_id) == 2L) &&
    setequal(
      raw_tests$test_id,
      c(
        "association_predictor_block",
        "heterogeneity_predictor_by_site_block"
      )
    ) &&
    all(raw_tests$test_status == "PILOT_RAW_ONLY_NO_BH_UPDATE") &&
    all(raw_tests$multiplicity_status == "PILOT_RAW_ONLY_NO_BH_UPDATE") &&
    all(is.finite(raw_tests$raw_p_value)) &&
    all(is.na(raw_tests$adjusted_p_value)),
  "The 24 raw-only timing tests or no-BH boundary changed"
)

sensitivity <- read_csv(
  paste0(
    "artifacts/08_diagnostics/H06_daily/",
    "H06_daily_timing_repair_sensitivity_stability.csv"
  )
)
student_major <- sensitivity |>
  dplyr::filter(
    .data$metric_id == "first_timing_above_250",
    .data$predictor_id == "work_free_day",
    .data$sensitivity_id == "student_t_identity",
    .data$component == "predictor_additive"
  )
ar_major <- sensitivity |>
  dplyr::filter(
    .data$metric_id == "l10_midpoint",
    .data$predictor_id == "activity_status",
    .data$sensitivity_id == "no_nugget_gap_aware_ar1",
    .data$component == "predictor_additive"
  )
assert_h06d(
  nrow(student_major) == 1L &&
    student_major$sensitivity_classification == "SUBSTANTIAL_LIMITATION" &&
    abs(student_major$maximum_shift_in_hc3_se - 1.2259803498982234) < 1e-12,
  "The first-timing Work/Free Student-t major limitation changed"
)
assert_h06d(
  nrow(ar_major) == 1L &&
    ar_major$sensitivity_classification == "SUBSTANTIAL_LIMITATION" &&
    abs(ar_major$maximum_shift_in_hc3_se - 1.2567555559969599) < 1e-12,
  "The L10-midpoint activity AR major limitation changed"
)

expected_unresolved_additive <- c(
  "m10_midpoint__previous_sleep_duration_centered_h",
  "first_timing_above_250__work_free_day",
  "last_timing_above_250__work_free_day"
)
unresolved_additive <- sensitivity |>
  dplyr::filter(
    .data$sensitivity_id == "no_nugget_gap_aware_ar1",
    .data$component == "predictor_additive",
    .data$sensitivity_classification == "UNRESOLVED_NUMERICAL_FAILURE"
  )
assert_h06d(
  nrow(unresolved_additive) == 3L &&
    setequal(unresolved_additive$cell_id, expected_unresolved_additive),
  "The three unresolved additive AR diagnostics changed"
)

ar_diagnostics <- read_csv(
  "artifacts/08_diagnostics/H06_daily/H06_daily_timing_repair_no_nugget_ar.csv"
)
assert_h06d(
  sum(!ar_diagnostics$converged & ar_diagnostics$structure == "additive") ==
    3L &&
    setequal(
      ar_diagnostics$cell_id[
        !ar_diagnostics$converged & ar_diagnostics$structure == "additive"
      ],
      expected_unresolved_additive
    ) &&
    all(!ar_diagnostics$temporal_threshold_pass),
  "The additive AR convergence or descriptive lag disposition changed"
)

student_interaction <- sensitivity |>
  dplyr::filter(
    .data$sensitivity_id == "student_t_identity",
    .data$component == "predictor_by_site_block"
  )
ar_interaction <- sensitivity |>
  dplyr::filter(
    .data$sensitivity_id == "no_nugget_gap_aware_ar1",
    .data$component == "predictor_by_site_block"
  )
assert_h06d(
  nrow(student_interaction) == 12L &&
    sum(student_interaction$sensitivity_classification == "UNSTABLE") == 10L &&
    nrow(ar_interaction) == 12L &&
    sum(ar_interaction$sensitivity_classification == "UNSTABLE") == 5L &&
    sum(
      ar_interaction$sensitivity_classification ==
        "UNRESOLVED_NUMERICAL_FAILURE"
    ) ==
      5L &&
    grepl("sensitivity-dependent", acceptance_text, fixed = TRUE) &&
    grepl(
      "cannot support an unqualified interaction",
      acceptance_text,
      fixed = TRUE
    ),
  "The sensitivity-dependent interaction qualification changed"
)

preservation <- read_csv(
  paste0(
    "artifacts/08_diagnostics/H06_daily/",
    "H06_daily_timing_repair_preservation_final.csv"
  )
)
preserved_absolute <- file.path(root, preservation$relative_path)
assert_h06d(
  nrow(preservation) == 571L &&
    all(preservation$identity_status == "BYTE_IDENTICAL") &&
    identical(preservation$sha256, preservation$baseline_sha256) &&
    identical(
      as.numeric(preservation$bytes),
      as.numeric(preservation$baseline_bytes)
    ) &&
    all(file.exists(preserved_absolute)) &&
    identical(
      unname(vapply(preserved_absolute, sha256, character(1L))),
      preservation$sha256
    ) &&
    identical(
      as.numeric(file.info(preserved_absolute)$size),
      as.numeric(preservation$bytes)
    ),
  "One or more of the 571 protected H06_daily identities changed"
)

acceptance_manifest_relative <- paste0(
  "artifacts/12_manifests/H06_daily/",
  "H06_daily_timing_repair_acceptance_manifest.csv"
)
acceptance_manifest <- verify_file_manifest(acceptance_manifest_relative)
required_manifest_paths <- c(
  decision_pins$relative_path,
  "audit/hypotheses/H06_daily/H06_daily_timing_repair_acceptance.md",
  "audit/hypotheses/H06_daily/11_timing_repair_pilot.qmd",
  "audit/hypotheses/H06_daily/11_timing_repair_pilot.html",
  "audit/hypotheses/H06_daily/H06_daily_timing_repair_pilot_transition.md",
  "artifacts/07_models/H06_daily/H06_daily_timing_repair_pilot_models.rds",
  "artifacts/12_manifests/H06_daily/H06_daily_timing_repair_input_manifest.csv",
  "artifacts/12_manifests/H06_daily/H06_daily_timing_repair_code_manifest.csv",
  "artifacts/12_manifests/H06_daily/H06_daily_timing_repair_output_manifest.csv",
  "artifacts/12_manifests/H06_daily/H06_daily_timing_repair_software_manifest.csv",
  "artifacts/12_manifests/H06_daily/H06_daily_timing_repair_pipeline_manifest.csv",
  "artifacts/12_manifests/H06_daily/H06_daily_timing_repair_figure_manifest.csv",
  "artifacts/12_manifests/H06_daily/H06_daily_timing_repair_report_manifest.csv",
  "tests/hypotheses/H06_daily/test_h06_daily_timing_repair_pilot.R",
  "tests/hypotheses/H06_daily/test_h06_daily_timing_repair_acceptance.R",
  "artifacts/08_diagnostics/H06_daily/H06_daily_timing_repair_preservation_final.csv",
  "artifacts/08_diagnostics/H06_daily/H06_daily_timing_repair_candidate_cells.csv",
  "artifacts/08_diagnostics/H06_daily/H06_daily_timing_repair_sensitivity_stability.csv",
  "artifacts/08_diagnostics/H06_daily/H06_daily_timing_repair_no_nugget_ar.csv",
  "artifacts/09_tables/H06_daily/H06_daily_timing_repair_raw_tests.csv"
)
assert_h06d(
  !acceptance_manifest_relative %in% acceptance_manifest$relative_path &&
    all(required_manifest_paths %in% acceptance_manifest$relative_path),
  "The non-circular acceptance manifest omitted a controlling identity"
)

addendum_path <- file.path(
  root,
  "audit/hypotheses/H06_daily/H06_daily_timing_repair_acceptance.md"
)
addendum_text <- paste(readLines(addendum_path, warn = FALSE), collapse = "\n")
assert_h06d(
  grepl("H06-D-010 / CHG-120", addendum_text, fixed = TRUE) &&
    grepl("H06-D-011 / CHG-121", addendum_text, fixed = TRUE) &&
    grepl("PILOT_RAW_ONLY_NO_BH_UPDATE", addendum_text, fixed = TRUE) &&
    grepl("1.23 HC3 standard errors", addendum_text, fixed = TRUE) &&
    grepl("1.26 HC3 standard errors", addendum_text, fixed = TRUE) &&
    grepl("sensitivity-dependent", addendum_text, fixed = TRUE) &&
    grepl("production remains unauthorized", addendum_text, fixed = TRUE) &&
    grepl(
      "There is no authorized analytical next step",
      addendum_text,
      fixed = TRUE
    ),
  "The task-owned acceptance addendum changed its accepted disposition"
)

cat(paste0(
  "H06-D-011 timing-route acceptance PASS: decisions pinned; 12 candidate ",
  "cells retained; 24 tests remain raw-only with adjusted p=NA; 2 major ",
  "limitations and 3 unresolved additive AR checks retained; interaction ",
  "claims remain sensitivity-dependent; 571 protected identities pass; ",
  "production remains unauthorized.\n"
))
