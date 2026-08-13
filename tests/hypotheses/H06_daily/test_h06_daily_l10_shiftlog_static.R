#!/usr/bin/env Rscript

# Focused no-fit verification of the H06-D-003 shifted-log static contract.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
.libPaths(c(
  file.path(root, "renv/library/macos/R-4.6/aarch64-apple-darwin23"),
  .libPaths()
))
required_packages <- c("digest", "dplyr", "lme4", "readr")
stopifnot(
  identical(as.character(getRversion()), "4.6.1"),
  all(vapply(required_packages, requireNamespace, logical(1), quietly = TRUE))
)

sha256 <- function(path) digest::digest(path, algo = "sha256", file = TRUE)
object_sha256 <- function(object) {
  digest::digest(object, algo = "sha256", serialize = TRUE)
}
read_csv <- function(relative_path) {
  readr::read_csv(
    file.path(root, relative_path),
    show_col_types = FALSE,
    na = c("", "NA")
  )
}

decision_path <- file.path(
  root,
  "audit/decisions/h06_daily_l10_shifted_log_amendment.md"
)
decision_text <- paste(readLines(decision_path, warn = FALSE), collapse = "\n")
stopifnot(
  sha256(decision_path) ==
    "4ddc2cd9ebdf0c98ca5ef7b56b0965e0c661dc85680db34bcfbde6b61342ec3a",
  grepl("Decision ID: `H06-D-003`", decision_text, fixed = TRUE),
  grepl("Gate: `H06-D-G2P-L10-SHIFTLOG`", decision_text, fixed = TRUE),
  grepl("compute-queued", decision_text, fixed = TRUE),
  grepl("must not\\s+launch concurrently", decision_text)
)

input_contract <- read_csv(paste0(
  "artifacts/08_diagnostics/H06_daily/",
  "H06_daily_l10_shiftlog_input_contract.csv"
))
stopifnot(
  nrow(input_contract) == 14L,
  all(input_contract$identity_pass),
  identical(input_contract$expected_sha256, input_contract$actual_sha256)
)

verdict <- read_csv(paste0(
  "artifacts/08_diagnostics/H06_daily/",
  "H06_daily_l10_shiftlog_static_verdict.csv"
))
stopifnot(
  nrow(verdict) == 1L,
  verdict$decision_id == "H06-D-003",
  verdict$change_id == "CHG-111",
  verdict$gate_id == "H06-D-G2P-L10-SHIFTLOG",
  verdict$input_pins_pass,
  verdict$historical_manifest_entries == 118L,
  verdict$historical_entries_preserved == 118L,
  verdict$pilot_frames == 3L,
  verdict$current_source_frame_rebuilds_identical,
  verdict$exact_reusable_additive_reml_objects == 3L,
  verdict$model_fits_run == 0L,
  verdict$bh_fields_updated == 0L,
  verdict$deletion_refits_run == 0L,
  verdict$compute_status == "HELD_AWAITING_SEPARATE_COORDINATOR_CLEARANCE"
)

frame_registry <- read_csv(paste0(
  "artifacts/06_model_data/H06_daily/",
  "H06_daily_l10_shiftlog_pilot_frame_registry.csv"
))
stopifnot(
  nrow(frame_registry) == 3L,
  setequal(
    frame_registry$predictor_id,
    c(
      "work_free_day",
      "activity_status",
      "previous_sleep_duration_centered_h"
    )
  ),
  all(frame_registry$sites == 9L),
  identical(
    as.integer(frame_registry$participant_days),
    c(784L, 734L, 784L)
  ),
  identical(
    as.integer(frame_registry$exact_zeros),
    c(107L, 92L, 107L)
  ),
  all(frame_registry$current_source_rebuild_identical),
  all(frame_registry$transformed_minimum == -1),
  all(frame_registry$historical_internal_component_label == "zero_occurrence"),
  all(grepl(
    "unused historical container field",
    frame_registry$internal_component_label_role,
    fixed = TRUE
  ))
)
for (index in seq_len(nrow(frame_registry))) {
  row <- frame_registry[index, ]
  path <- file.path(root, row$frame_path[[1L]])
  frame <- readRDS(path)
  stopifnot(
    sha256(path) == row$frame_file_sha256[[1L]],
    object_sha256(frame) == row$frame_object_sha256[[1L]],
    nrow(frame) == row$participant_days[[1L]],
    all(is.finite(frame$response_value)),
    identical(frame$response_value, log10(frame$response_source + 0.1)),
    all(frame$response_value[frame$response_source == 0] == -1)
  )
}

reuse <- read_csv(paste0(
  "artifacts/08_diagnostics/H06_daily/",
  "H06_daily_l10_shiftlog_exact_reuse_verification.csv"
))
required_reuse_fields <- c(
  "frame_object_identical",
  "response_identical",
  "source_response_identical",
  "formula_identical",
  "fixed_matrix_identical",
  "contrast_attributes_identical",
  "gaussian_identity_lmm",
  "reml_identical",
  "optimizer_identical",
  "r_version_identical",
  "package_versions_identical",
  "no_captured_error",
  "no_captured_warning",
  "converged",
  "exact_reuse_authorized"
)
stopifnot(
  nrow(reuse) == 3L,
  all(vapply(
    required_reuse_fields,
    function(column) all(reuse[[column]]),
    logical(1)
  )),
  !any(reuse$singular),
  all(reuse$reuse_disposition == "REUSE_EXACT_HISTORICAL_REML_ADDITIVE_OBJECT")
)

reference <- read_csv(paste0(
  "artifacts/08_diagnostics/H06_daily/",
  "H06_daily_l10_shiftlog_reference_registry.csv"
))
bundle_path <- file.path(root, reference$parent_path[[1L]])
bundle <- readRDS(bundle_path)
stopifnot(
  nrow(reference) == 3L,
  length(unique(reference$parent_path)) == 1L,
  length(unique(reference$parent_sha256)) == 1L,
  sha256(bundle_path) == reference$parent_sha256[[1L]],
  all(grepl("$one_part", reference$subobject_path, fixed = TRUE)),
  all(grepl("first fitted as a diagnostic sensitivity", reference$disclosure))
)
for (index in seq_len(nrow(reference))) {
  key <- paste(
    "primary__near_eye__all_available",
    reference$predictor_id[[index]],
    sep = "__"
  )
  capture <- bundle$models[[key]]$one_part
  stopifnot(
    object_sha256(capture) == reference$capture_object_sha256[[index]],
    object_sha256(capture$value) == reference$model_object_sha256[[index]]
  )
}

formulas <- read_csv(paste0(
  "artifacts/09_tables/H06_daily/",
  "H06_daily_l10_shiftlog_formula_registry.csv"
))
stopifnot(
  nrow(formulas) == 21L,
  all(table(formulas$predictor_id) == 7L),
  all(grepl("response_value ~", formulas$formula, fixed = TRUE)),
  all(!grepl("zero_occurrence|positive_magnitude", formulas$formula)),
  sum(formulas$fit_action == "REUSE_EXACT_VERIFIED_OBJECT") == 3L,
  sum(grepl("FIT_AFTER_COMPUTE_CLEARANCE", formulas$fit_action)) == 15L,
  sum(
    formulas$fit_action == "FIT_ONLY_IF_LAG_TRIGGER_AFTER_COMPUTE_CLEARANCE"
  ) ==
    3L
)

historical <- read_csv(paste0(
  "artifacts/08_diagnostics/H06_daily/",
  "H06_daily_l10_shiftlog_historical_preservation_baseline.csv"
))
stopifnot(
  nrow(historical) == 118L,
  all(historical$file_exists),
  all(historical$preserved_byte_for_byte),
  all(historical$sha256 == historical$actual_sha256),
  all(historical$bytes == historical$actual_bytes),
  sha256(file.path(
    root,
    "audit/hypotheses/H06_daily/08_l10_metric011_amendment.qmd"
  )) ==
    "2a13894ed53f0cbe660f2855e3f994ce2041d6408ac36b650a0a4bbff2d6cade",
  sha256(file.path(
    root,
    "audit/hypotheses/H06_daily/08_l10_metric011_amendment.html"
  )) ==
    "db255bc7d5aba1f71fa8c42ab4de0ebef3807210d45c99f805cfad6074b8a109"
)

cat(
  paste0(
    "H06-D-003 shifted-log static tests passed: 14 input pins; ",
    "118 historical entries preserved; 3 current-source frames exact; ",
    "3 Gaussian additive REML objects exactly reusable; 0 fits; ",
    "compute remains held.\n"
  )
)
