#!/usr/bin/env Rscript

# Focused no-refit verifier for H06-D-G2P-NONL10.

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
stopifnot(
  identical(as.character(getRversion()), "4.6.1"),
  all(vapply(required_packages, requireNamespace, logical(1), quietly = TRUE))
)
suppressPackageStartupMessages({
  library(digest)
  library(dplyr)
  library(readr)
  library(tibble)
})

sha256 <- function(path) digest::digest(path, algo = "sha256", file = TRUE)
read_csv <- function(relative_path) {
  readr::read_csv(
    file.path(root, relative_path),
    show_col_types = FALSE,
    na = c("", "NA")
  )
}
verify_manifest <- function(relative_path) {
  manifest <- read_csv(relative_path)
  absolute <- file.path(root, manifest$relative_path)
  stopifnot(
    nrow(manifest) > 0L,
    !anyDuplicated(manifest$relative_path),
    all(file.exists(absolute)),
    identical(
      unname(vapply(absolute, sha256, character(1))),
      manifest$sha256
    ),
    identical(unname(file.info(absolute)$size), manifest$bytes)
  )
  manifest
}

selection_path <- file.path(
  root,
  "audit/decisions/h06_primary_selection_and_daily_complement.md"
)
reopening_path <- file.path(
  root,
  "audit/decisions/h06_daily_non_l10_grid_reopening.md"
)
stopifnot(
  sha256(selection_path) ==
    "c5c08a454ba94a4d955d9821be50b422b697d779b2b5ec921a316c508dd248c1",
  sha256(reopening_path) ==
    "0c16d2c89d79aa25a7e8bcfb0404a653186108232c93222af0a3c60695d3cdaa"
)

input <- read_csv(paste0(
  "artifacts/12_manifests/H06_daily/",
  "H06_daily_non_l10_pilot_input_manifest.csv"
))
stopifnot(
  nrow(input) == 26L,
  all(input$verification_status == "PASS"),
  identical(input$expected_sha256, input$actual_sha256)
)
input_absolute <- file.path(root, input$relative_path)
stopifnot(
  identical(
    unname(vapply(input_absolute, sha256, character(1))),
    input$expected_sha256
  )
)

code <- verify_manifest(paste0(
  "artifacts/12_manifests/H06_daily/",
  "H06_daily_non_l10_pilot_code_manifest.csv"
))
output <- verify_manifest(paste0(
  "artifacts/12_manifests/H06_daily/",
  "H06_daily_non_l10_pilot_output_manifest.csv"
))
stopifnot(
  nrow(code) == 8L,
  nrow(output) == 24L,
  !any(grepl("report_manifest", output$relative_path))
)

inventory <- read_csv(paste0(
  "artifacts/06_model_data/H06_daily/",
  "H06_daily_non_l10_pilot_frame_inventory.csv"
))
stopifnot(
  nrow(inventory) == 468L,
  setequal(inventory$metric_slot, c(1L, 2L, 4L:14L)),
  !any(inventory$metric_slot %in% c(3L, 15L)),
  all(table(inventory$metric_slot) == 36L),
  all(table(inventory$predictor_id) == 156L),
  all(table(inventory$run_id) == 39L),
  min(inventory$participant_days) == 458L,
  max(inventory$participant_days) == 870L
)

reconciliation <- read_csv(paste0(
  "artifacts/08_diagnostics/H06_daily/",
  "H06_daily_non_l10_pilot_source_reconciliation.csv"
))
stopifnot(
  nrow(reconciliation) == 26L,
  all(reconciliation$exact_reconciliation),
  all(reconciliation$estimability_mismatches == 0L),
  sum(reconciliation$representation_differences) == 1191L,
  max(reconciliation$maximum_relative_difference) <= 3e-16,
  all(reconciliation$numeric_relative_tolerance == 1e-12)
)

reuse <- read_csv(paste0(
  "artifacts/08_diagnostics/H06_daily/",
  "H06_daily_non_l10_pilot_reuse_verification.csv"
))
stopifnot(
  nrow(reuse) == 3L,
  !any(reuse$raw_frame_object_identical),
  all(reuse$only_global_metric_settings_attribute_changed),
  all(reuse$analytical_frame_identical),
  all(reuse$model_frame_identical),
  all(reuse$response_and_source_identical),
  all(reuse$formula_identical),
  all(reuse$design_matrix_identical),
  all(reuse$site_contrasts_identical),
  all(reuse$family_link_identical),
  all(reuse$optimizer_identical),
  all(reuse$warnings_identical_empty),
  all(reuse$software_identity),
  all(reuse$converged),
  all(reuse$positive_definite_hessian),
  !any(reuse$singular),
  all(
    reuse$reuse_disposition ==
      "REUSE_EXACT_HISTORICAL_REML_ADDITIVE_OBJECT"
  )
)

diagnostics <- read_csv(paste0(
  "artifacts/08_diagnostics/H06_daily/",
  "H06_daily_non_l10_pilot_timing_diagnostics.csv"
))
expected_dispositions <- tibble::tribble(
  ~metric_id, ~acceptable, ~gaussian_failures, ~temporal_failures,
  "m10_midpoint", 0L, 0L, 3L,
  "l10_midpoint", 0L, 3L, 0L,
  "mean_timing_above_250", 3L, 0L, 0L,
  "first_timing_above_250", 0L, 2L, 1L,
  "last_timing_above_250", 0L, 0L, 3L
)
observed_dispositions <- diagnostics |>
  dplyr::summarise(
    acceptable = sum(grepl("^ACCEPTABLE", .data$diagnostic_disposition)),
    gaussian_failures = sum(
      .data$diagnostic_disposition == "NOT_ACCEPTABLE_GAUSSIAN_CORE"
    ),
    temporal_failures = sum(
      .data$diagnostic_disposition == "NOT_ACCEPTABLE_TEMPORAL_STABILITY"
    ),
    .by = "metric_id"
  ) |>
  dplyr::arrange(.data$metric_id)
stopifnot(
  nrow(diagnostics) == 15L,
  all(diagnostics$source_clock_acceptable),
  all(diagnostics$additive_converged),
  all(diagnostics$additive_positive_definite_hessian),
  !any(diagnostics$additive_singular),
  all(diagnostics$prediction_bound_acceptable),
  sum(diagnostics$ar_trigger) == 9L,
  sum(diagnostics$ar_fitted) == 9L,
  sum(diagnostics$ar_singular, na.rm = TRUE) == 1L,
  identical(
    observed_dispositions,
    expected_dispositions |>
      dplyr::arrange(.data$metric_id)
  )
)

counts <- read_csv(paste0(
  "artifacts/08_diagnostics/H06_daily/",
  "H06_daily_non_l10_pilot_timing_model_counts.csv"
))
registered <- read_csv(paste0(
  "artifacts/08_diagnostics/H06_daily/",
  "H06_daily_non_l10_pilot_timing_registered_benchmarks.csv"
))
pilot_tests <- read_csv(paste0(
  "artifacts/09_tables/H06_daily/",
  "H06_daily_non_l10_pilot_timing_raw_tests.csv"
))
stopifnot(
  nrow(counts) == 15L,
  sum(counts$model_components_attempted) == 99L,
  sum(counts$model_components_fitted) == 99L,
  sum(registered$benchmark_disposition == "ESTIMABLE_BENCHMARK_ONLY") == 2L,
  nrow(pilot_tests) == 30L,
  all(pilot_tests$test_status == "PILOT_RAW_ONLY"),
  all(pilot_tests$multiplicity_status == "PILOT_RAW_ONLY_NO_BH"),
  !any(grepl("adjust|BH|q_value", names(pilot_tests), ignore.case = TRUE))
)

deletions <- read_csv(paste0(
  "artifacts/08_diagnostics/H06_daily/",
  "H06_daily_non_l10_pilot_deletion_checkpoint.csv"
))
stopifnot(
  nrow(deletions) == 50L,
  !anyDuplicated(deletions$task_id),
  identical(sort(as.integer(deletions$task_id)), seq_len(50L)),
  all(table(deletions$class_id) == 10L),
  sum(deletions$deletion_type == "participant") == 25L,
  sum(deletions$deletion_type == "site") == 25L,
  all(deletions$converged),
  all(deletions$positive_definite_hessian),
  !any(deletions$singular),
  all(is.na(deletions$fit_error)),
  sum(deletions$warning_count) == 0L,
  sum(deletions$direction_reversal) == 0L,
  max(
    deletions$absolute_shift_in_full_se[
      deletions$class_id != "strict_clock"
    ]
  ) < 1,
  max(
    deletions$absolute_shift_in_full_se[
      deletions$class_id == "strict_clock"
    ]
  ) > 1,
  max(
    deletions$absolute_shift_in_full_se[
      deletions$class_id == "strict_clock"
    ]
  ) < 2
)

runtime <- read_csv(paste0(
  "artifacts/08_diagnostics/H06_daily/",
  "H06_daily_non_l10_pilot_runtime_and_projection.csv"
))
all_projection <- runtime |>
  dplyr::filter(grepl("all_authorized_scenarios", .data$component))
stopifnot(
  nrow(all_projection) == 1L,
  all_projection$projected_units == 66664L,
  all_projection$projected_seconds > 1800,
  all_projection$projected_seconds < 1860,
  runtime$measured_seconds[
    runtime$component == "15-cell primary near-eye clock-family pilot"
  ] < 10,
  runtime$measured_seconds[
    runtime$component == "five-class deletion pilot"
  ] < 5
)

preservation <- read_csv(paste0(
  "artifacts/08_diagnostics/H06_daily/",
  "H06_daily_non_l10_pilot_preservation_final.csv"
))
protected_absolute <- file.path(root, preservation$relative_path)
stopifnot(
  nrow(preservation) == 535L,
  all(preservation$identity_status == "BYTE_IDENTICAL"),
  all(file.exists(protected_absolute)),
  identical(
    unname(vapply(protected_absolute, sha256, character(1))),
    preservation$baseline_sha256
  ),
  identical(
    unname(file.info(protected_absolute)$size),
    preservation$baseline_bytes
  )
)

verdict <- read_csv(paste0(
  "artifacts/08_diagnostics/H06_daily/",
  "H06_daily_non_l10_pilot_verdict.csv"
))
stopifnot(
  nrow(verdict) == 1L,
  verdict$gate == "H06-D-G2P-NONL10",
  verdict$timing_cells == 15L,
  verdict$timing_cells_acceptable == 3L,
  verdict$deletion_refits == 50L,
  verdict$deletion_failures == 0L,
  verdict$deletion_warnings == 0L,
  verdict$historical_files_byte_identical == 535L,
  verdict$bh_update == "NOT_RUN_NOT_AUTHORIZED",
  verdict$full_grid == "NOT_RUN_AWAITING_AUTHOR_APPROVAL",
  verdict$gate_status == "STOP_FOR_AUTHOR_REVIEW"
)

qmd_path <- file.path(
  root,
  "audit/hypotheses/H06_daily/10_non_l10_pilot.qmd"
)
html_path <- file.path(
  root,
  "audit/hypotheses/H06_daily/10_non_l10_pilot.html"
)
transition_path <- file.path(
  root,
  paste0(
    "audit/hypotheses/H06_daily/",
    "H06_daily_non_l10_pilot_transition.md"
  )
)
qmd_text <- paste(readLines(qmd_path, warn = FALSE), collapse = "\n")
html_text <- paste(readLines(html_path, warn = FALSE), collapse = "\n")
transition_text <- paste(
  readLines(transition_path, warn = FALSE),
  collapse = "\n"
)
required_report_tokens <- c(
  "H06-D-G2P-NONL10",
  "No BH family was assembled",
  "Mean timing above 250 lx melEDI is acceptable",
  "66,664",
  "Stage 3 and Stage 4 remain unauthorized"
)
stopifnot(
  file.exists(html_path),
  file.info(html_path)$size > 1000000,
  all(vapply(
    required_report_tokens[1:3],
    function(token) grepl(token, qmd_text, fixed = TRUE),
    logical(1)
  )),
  grepl("H06-D-G2P-NONL10", html_text, fixed = TRUE),
  grepl("66,664", html_text, fixed = TRUE),
  grepl("math inline", html_text, fixed = TRUE),
  grepl("overflow-x:auto", html_text, fixed = TRUE),
  all(vapply(
    required_report_tokens[c(1, 4, 5)],
    function(token) grepl(token, transition_text, fixed = TRUE),
    logical(1)
  ))
)

report_manifest_path <- file.path(
  root,
  paste0(
    "audit/hypotheses/H06_daily/",
    "H06_daily_non_l10_pilot_report_manifest.csv"
  )
)
if (file.exists(report_manifest_path)) {
  report_manifest <- verify_manifest(paste0(
    "audit/hypotheses/H06_daily/",
    "H06_daily_non_l10_pilot_report_manifest.csv"
  ))
  stopifnot(
    !"audit/hypotheses/H06_daily/H06_daily_non_l10_pilot_report_manifest.csv" %in%
      report_manifest$relative_path,
    all(c(
      "audit/hypotheses/H06_daily/10_non_l10_pilot.qmd",
      "audit/hypotheses/H06_daily/10_non_l10_pilot.html",
      paste0(
        "audit/hypotheses/H06_daily/",
        "H06_daily_non_l10_pilot_transition.md"
      ),
      "tests/hypotheses/H06_daily/test_h06_daily_non_l10_pilot.R"
    ) %in% report_manifest$relative_path)
  )
}

cat(
  paste0(
    "H06-D-G2P-NONL10 focused test passed: 26 pins, 468 frames, ",
    "15 timing cells, 99 model components, 50 deletion refits, ",
    "535 protected identities, no BH update.\n"
  )
)
