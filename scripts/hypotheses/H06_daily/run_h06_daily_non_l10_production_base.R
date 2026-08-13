#!/usr/bin/env Rscript

# H06-D-013 phase 1: seal inputs, rebuild 468 frames, and fit base models.

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

required_packages <- c(
  "digest", "dplyr", "tidyr", "tibble", "readr", "lme4", "glmmTMB",
  "performance", "emmeans", "sandwich", "melidosData", "LightLogR"
)
missing_packages <- required_packages[!vapply(
  required_packages,
  requireNamespace,
  logical(1),
  quietly = TRUE
)]
if (length(missing_packages)) {
  stop(
    "Missing synchronized project package(s): ",
    paste(missing_packages, collapse = ", "),
    call. = FALSE
  )
}
suppressPackageStartupMessages({
  library(digest)
  library(dplyr)
  library(tidyr)
  library(tibble)
  library(readr)
  library(lme4)
  library(glmmTMB)
  library(performance)
  library(emmeans)
  library(sandwich)
})

source(file.path(
  root,
  "scripts/hypotheses/H06_daily/h06_daily_non_l10_pilot_contract.R"
))
source(file.path(
  root,
  "scripts/hypotheses/H06_daily/h06_daily_non_l10_pilot_data.R"
))
source(file.path(
  root,
  "scripts/hypotheses/H06_daily/h06_daily_non_l10_pilot_modeling.R"
))
source(file.path(
  root,
  "scripts/hypotheses/H06_daily/h06_daily_timing_repair_contract.R"
))
source(file.path(
  root,
  "scripts/hypotheses/H06_daily/h06_daily_timing_repair_modeling.R"
))
source(file.path(
  root,
  "scripts/hypotheses/H06_daily/h06_daily_non_l10_production_contract.R"
))
source(file.path(
  root,
  "scripts/hypotheses/H06_daily/h06_daily_non_l10_production_modeling.R"
))

h06d_prod_assert(
  identical(as.character(getRversion()), "4.6.1"),
  "H06-D-013 requires R 4.6.1; found %s",
  as.character(getRversion())
)
h06d_prod_assert(
  identical(as.character(utils::packageVersion("melidosData")), "1.0.6"),
  "H06-D-013 requires immutable melidosData 1.0.6"
)

paths <- h06d_prod_checkpoint_paths(root)
dir.create(paths$model_dir, recursive = TRUE, showWarnings = FALSE)
diagnostic_dir <- file.path(root, "artifacts/08_diagnostics/H06_daily")
manifest_dir <- file.path(root, "artifacts/12_manifests/H06_daily")
model_data_dir <- file.path(root, "artifacts/06_model_data/H06_daily")

message("H06-D-013 phase 1: verifying all sealed input identities")
input_contract <- h06d_prod_verify_contract(root, h06d_prod_input_contract())
main_contract <- h06d_prod_verify_contract(
  root,
  h06d_prod_main_h06_contract() |>
    dplyr::mutate(input_id = paste0("main_h06_", dplyr::row_number()), .before = 1L)
)
h06d_prod_write_csv(
  input_contract,
  file.path(
    manifest_dir,
    "H06_daily_non_l10_production_input_manifest.csv"
  )
)
h06d_prod_write_csv(
  main_contract,
  file.path(
    manifest_dir,
    "H06_daily_non_l10_production_main_h06_pins.csv"
  )
)

baseline_path <- file.path(
  diagnostic_dir,
  "H06_daily_non_l10_production_preservation_baseline.csv"
)
if (file.exists(baseline_path)) {
  preservation_baseline <- readr::read_csv(
    baseline_path,
    show_col_types = FALSE
  )
  historical_only <- !grepl(
    "h06_daily_non_l10_production",
    tolower(preservation_baseline$relative_path),
    fixed = TRUE
  )
  if (!all(historical_only)) {
    preservation_baseline <- preservation_baseline[historical_only, , drop = FALSE]
    h06d_prod_write_csv(preservation_baseline, baseline_path)
  }
} else {
  preservation_baseline <- h06d_prod_build_preservation_baseline(root)
  h06d_prod_write_csv(preservation_baseline, baseline_path)
}
h06d_prod_recheck_preservation(
  root,
  preservation_baseline,
  "pre_fit"
) |>
  h06d_prod_write_csv(file.path(
    diagnostic_dir,
    "H06_daily_non_l10_production_preservation_pre_fit.csv"
  ))

message("H06-D-013 phase 1: rebuilding and verifying all 468 frames")
source_data <- h06d_nl_load_sources(root)
frame_build <- h06d_nl_build_frames(source_data, retain_frames = TRUE)
current_inventory <- frame_build$inventory
frames <- frame_build$frames
frozen_inventory <- readr::read_csv(
  file.path(
    model_data_dir,
    "H06_daily_non_l10_pilot_frame_inventory.csv"
  ),
  show_col_types = FALSE
)

frame_identity_columns <- names(frozen_inventory)
h06d_prod_assert(
  nrow(current_inventory) == 468L &&
    identical(names(current_inventory), frame_identity_columns),
  "The rebuilt non-L10 frame inventory structure changed"
)
inventory_comparison <- current_inventory |>
  dplyr::rename_with(~ paste0("current_", .x), -"frame_key") |>
  dplyr::left_join(
    frozen_inventory |>
      dplyr::rename_with(~ paste0("frozen_", .x), -"frame_key"),
    by = "frame_key",
    relationship = "one-to-one"
  )
inventory_comparison$all_fields_identical <- vapply(
  seq_len(nrow(inventory_comparison)),
  function(index) {
    all(vapply(setdiff(frame_identity_columns, "frame_key"), function(column) {
      current <- inventory_comparison[[paste0("current_", column)]][[index]]
      frozen <- inventory_comparison[[paste0("frozen_", column)]][[index]]
      if (column %in% c("source_minimum", "source_median", "source_maximum")) {
        return(
          is.finite(current) && is.finite(frozen) &&
            abs(current - frozen) / max(1, abs(current), abs(frozen)) <= 1e-12
        )
      }
      if (is.numeric(current) && is.numeric(frozen)) {
        return(length(current) == 1L && length(frozen) == 1L && current == frozen)
      }
      identical(current, frozen)
    }, logical(1)))
  },
  logical(1)
)
inventory_comparison$serialized_frame_hash_identical <-
  inventory_comparison$current_frame_object_sha256 ==
    inventory_comparison$frozen_frame_object_sha256
h06d_prod_assert(
  nrow(inventory_comparison) == 468L &&
    all(inventory_comparison$all_fields_identical) &&
    all(inventory_comparison$serialized_frame_hash_identical) &&
    setequal(names(frames), frozen_inventory$frame_key),
  "At least one of the 468 rebuilt frames differs from its sealed inventory"
)
h06d_prod_write_csv(
  inventory_comparison,
  file.path(
    model_data_dir,
    "H06_daily_non_l10_production_frame_identity_check.csv"
  )
)

metrics <- h06d_nl_metric_registry()
predictors <- h06d_nl_predictor_registry()
ordered_inventory <- frozen_inventory |>
  dplyr::arrange(.data$metric_slot, .data$predictor_order, .data$run_order)
fit_code_paths <- file.path(root, c(
  "scripts/hypotheses/H06_daily/h06_daily_non_l10_pilot_contract.R",
  "scripts/hypotheses/H06_daily/h06_daily_non_l10_pilot_data.R",
  "scripts/hypotheses/H06_daily/h06_daily_non_l10_pilot_modeling.R",
  "scripts/hypotheses/H06_daily/h06_daily_timing_repair_contract.R",
  "scripts/hypotheses/H06_daily/h06_daily_timing_repair_modeling.R",
  "scripts/hypotheses/H06_daily/h06_daily_non_l10_production_contract.R",
  "scripts/hypotheses/H06_daily/h06_daily_non_l10_production_modeling.R"
))
fit_code_sha256 <- digest::digest(
  vapply(fit_code_paths, h06d_prod_sha256, character(1)),
  algo = "sha256",
  serialize = TRUE
)

if (file.exists(paths$base_index)) {
  base_checkpoint <- readr::read_csv(paths$base_index, show_col_types = FALSE)
  h06d_prod_assert(
    !anyDuplicated(base_checkpoint$frame_key) &&
      all(base_checkpoint$frame_key %in% ordered_inventory$frame_key),
    "Existing base checkpoint is incompatible with H06-D-013"
  )
} else {
  base_checkpoint <- tibble::tibble()
}

message("H06-D-013 phase 1: fitting 468 cells serially with checkpoints")
phase_started <- proc.time()[["elapsed"]]
for (index in seq_len(nrow(ordered_inventory))) {
  meta <- ordered_inventory[index, , drop = FALSE]
  existing <- if (nrow(base_checkpoint)) {
    which(base_checkpoint$frame_key == meta$frame_key[[1L]])
  } else {
    integer()
  }
  existing_current <- length(existing) == 1L &&
    "fit_code_sha256" %in% names(base_checkpoint) &&
    isTRUE(base_checkpoint$outer_success[[existing]]) &&
    identical(base_checkpoint$fit_code_sha256[[existing]], fit_code_sha256)
  if (existing_current) {
    next
  }
  if (length(existing)) {
    base_checkpoint <- base_checkpoint[-existing, , drop = FALSE]
  }
  frame_key <- meta$frame_key[[1L]]
  frame <- frames[[frame_key]]
  metric <- dplyr::filter(metrics, .data$metric_id == meta$metric_id[[1L]])
  predictor <- dplyr::filter(
    predictors,
    .data$predictor_id == meta$predictor_id[[1L]]
  )
  h06d_prod_assert(
    nrow(metric) == 1L && nrow(predictor) == 1L,
    "Registry lookup failed for `%s`",
    frame_key
  )
  message(sprintf("  base cell %03d/468: %s", index, frame_key))
  fit <- h06d_prod_capture(h06d_prod_fit_cell(frame, metric, predictor, meta))
  route <- if (metric$metric_slot[[1L]] %in% c(9L, 10L, 12L, 13L)) {
    "participant_cluster_HC3"
  } else {
    "mixed_model"
  }
  checkpoint_path <- file.path(
    paths$model_dir,
    paste0(sprintf("cell_%03d_", index), digest::digest(
      frame_key,
      algo = "sha256",
      serialize = FALSE
    ), ".rds")
  )
  object <- list(
    authorization = "H06-D-013",
    frame_key = frame_key,
    frame_object_sha256 = meta$frame_object_sha256[[1L]],
    route = route,
    result = fit$value,
    outer_warnings = fit$warnings,
    outer_error = fit$error,
    elapsed_seconds = fit$elapsed_seconds,
    r_version = as.character(getRversion()),
    package_versions = vapply(
      required_packages,
      function(package) as.character(utils::packageVersion(package)),
      character(1)
    )
  )
  h06d_prod_write_rds(object, checkpoint_path, compress = "gzip")
  row <- meta |>
    dplyr::mutate(
      route = route,
      outer_success = !is.null(fit$value),
      outer_warning_count = length(fit$warnings),
      outer_warnings = paste(fit$warnings, collapse = " | "),
      outer_error = fit$error,
      elapsed_seconds = fit$elapsed_seconds,
      fit_code_sha256 = fit_code_sha256,
      checkpoint_relative_path = h06d_prod_relative_path(root, checkpoint_path),
      checkpoint_sha256 = h06d_prod_sha256(checkpoint_path),
      checkpoint_bytes = as.numeric(file.info(checkpoint_path)$size)
    )
  base_checkpoint <- dplyr::bind_rows(base_checkpoint, row) |>
    dplyr::arrange(.data$metric_slot, .data$predictor_order, .data$run_order)
  h06d_prod_write_csv(base_checkpoint, paths$base_index)

  elapsed <- unname(proc.time()[["elapsed"]] - phase_started)
  if (elapsed > 3600) {
    h06d_prod_abort(
      "Base phase exceeded the one-hour H06-D-013 runtime boundary after %d cells",
      nrow(base_checkpoint)
    )
  }
  current_code_rows <- dplyr::coalesce(
    base_checkpoint$fit_code_sha256 == fit_code_sha256,
    FALSE
  )
  failures <- sum(!base_checkpoint$outer_success[current_code_rows])
  current_code_n <- sum(current_code_rows)
  if (current_code_n >= 20L && failures / current_code_n > 0.10) {
    h06d_prod_abort(
      "Systemic base-cell failure rate exceeded 10%% (%d/%d)",
      failures,
      current_code_n
    )
  }
  if (index %% 25L == 0L) {
    h06d_prod_recheck_preservation(
      root,
      preservation_baseline,
      sprintf("base_checkpoint_%03d", index)
    )
  }
}

h06d_prod_assert(
  nrow(base_checkpoint) == 468L &&
    all(base_checkpoint$outer_success) &&
    all(base_checkpoint$fit_code_sha256 == fit_code_sha256) &&
    !anyDuplicated(base_checkpoint$frame_key),
  "The 468-cell base production phase did not complete"
)
base_elapsed <- unname(proc.time()[["elapsed"]] - phase_started)
h06d_prod_recheck_preservation(
  root,
  preservation_baseline,
  "post_base"
) |>
  h06d_prod_write_csv(file.path(
    diagnostic_dir,
    "H06_daily_non_l10_production_preservation_post_base.csv"
  ))

h06d_prod_write_rds(
  list(
    gate = "H06-D-G2",
    authorization = "H06-D-013",
    phase = "BASE_COMPLETE",
    completed_cells = nrow(base_checkpoint),
    base_elapsed_seconds = base_elapsed,
    frame_inventory_sha256 =
      "639eaa04595f5fc83ef9633da4b66bd14123480a1322c43e5e6ac4d80eb40bce",
    preservation_baseline_sha256 = h06d_prod_sha256(baseline_path),
    updated = format(Sys.time(), tz = "UTC", usetz = TRUE)
  ),
  paths$state
)
message(sprintf(
  "H06-D-013 base phase complete: 468 cells in %.1f seconds",
  base_elapsed
))
