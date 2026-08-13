#!/usr/bin/env Rscript

# H06_daily targeted gap clock-hour repair: exact frame normalization and
# serial checkpointed base fits for the 90 authorized cells.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
.libPaths(c(
  file.path(root, "renv/library/macos/R-4.6/aarch64-apple-darwin23"),
  .libPaths()
))

required_packages <- c(
  "digest", "dplyr", "tidyr", "tibble", "readr", "lme4", "glmmTMB",
  "performance", "emmeans", "sandwich", "melidosData", "LightLogR"
)
missing_packages <- required_packages[!vapply(
  required_packages,
  requireNamespace,
  logical(1L),
  quietly = TRUE
)]
if (length(missing_packages)) {
  stop(
    sprintf(
      "Missing synchronized package(s): %s",
      paste(missing_packages, collapse = ", ")
    ),
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

for (script in c(
  "h06_daily_non_l10_pilot_contract.R",
  "h06_daily_non_l10_pilot_data.R",
  "h06_daily_non_l10_pilot_modeling.R",
  "h06_daily_timing_repair_contract.R",
  "h06_daily_timing_repair_modeling.R",
  "h06_daily_non_l10_production_contract.R",
  "h06_daily_non_l10_production_modeling.R",
  "h06_daily_gap_clock_repair_contract.R",
  "h06_daily_gap_clock_repair_data.R"
)) {
  source(file.path(root, "scripts/hypotheses/H06_daily", script))
}

h06d_gap_assert(
  identical(as.character(getRversion()), "4.6.1"),
  "The repair requires R 4.6.1; found %s",
  as.character(getRversion())
)
h06d_gap_assert(
  identical(as.character(utils::packageVersion("melidosData")), "1.0.6"),
  "The repair requires immutable melidosData 1.0.6"
)

paths <- h06d_gap_paths(root)
invisible(lapply(
  paths[c(
    "model_data", "model_cells", "diagnostic", "influence_cells",
    "tables", "figures", "source_data", "manifests", "audit"
  )],
  dir.create,
  recursive = TRUE,
  showWarnings = FALSE
))

message("Gap clock repair: verifying direct pins and protected histories")
direct <- h06d_gap_verify_direct_pins(root)
h06d_gap_write_csv(
  direct,
  file.path(paths$manifests, "H06_daily_gap_clock_repair_input_manifest.csv")
)
protected_1011 <- h06d_gap_verify_protected_1011(root, "pre_repair")
h06d_gap_write_csv(
  protected_1011,
  file.path(
    paths$diagnostic,
    "H06_daily_gap_clock_repair_protected_pre_repair.csv"
  )
)
protected_g2a <- h06d_gap_verify_manifest(
  root,
  file.path(
    paths$manifests,
    "H06_daily_h01_diagnostic_alignment_output_manifest.csv"
  ),
  "pre_repair"
)
h06d_gap_write_csv(
  protected_g2a,
  file.path(
    paths$diagnostic,
    "H06_daily_gap_clock_repair_g2a_outputs_pre_repair.csv"
  )
)

message("Gap clock repair: rebuilding and auditing 90 corrected frames")
frame_build <- h06d_gap_build_and_verify_frames(root, retain_frames = TRUE)
frames <- frame_build$frames
inventory <- frame_build$inventory
h06d_gap_assert(
  nrow(inventory) == 90L && length(frames) == 90L &&
    identical(names(frames), inventory$frame_key),
  "The corrected frame bundle is incomplete or out of order"
)
h06d_gap_write_csv(
  inventory,
  file.path(
    paths$model_data,
    "H06_daily_gap_clock_repair_frame_inventory.csv"
  )
)
h06d_gap_write_csv(
  frame_build$change_audit,
  file.path(
    paths$diagnostic,
    "H06_daily_gap_clock_repair_90_cell_change_audit.csv"
  )
)
h06d_gap_write_csv(
  frame_build$unaffected,
  file.path(
    paths$diagnostic,
    "H06_daily_gap_clock_repair_378_frame_invariance.csv"
  )
)
h06d_gap_write_rds(
  list(
    authorization = h06d_gap_authorization()$authorization,
    gate = h06d_gap_authorization()$gate,
    normalization = list(
      dataset_id = "gap_timing_unaware",
      metric_slots = 9:13,
      input_unit = "clock hour",
      frame_contract_unit = "clock minute",
      multiplier = 60,
      shared_source_modified = FALSE
    ),
    frames = frames,
    inventory = inventory,
    r_version = as.character(getRversion()),
    package_versions = h06d_gap_package_versions(required_packages)
  ),
  file.path(
    paths$model_data,
    "H06_daily_gap_clock_repair_frame_bundle.rds"
  )
)

metrics <- h06d_nl_metric_registry()
predictors <- h06d_nl_predictor_registry()
code_paths <- file.path(root, "scripts/hypotheses/H06_daily", c(
  "h06_daily_non_l10_pilot_contract.R",
  "h06_daily_non_l10_pilot_data.R",
  "h06_daily_non_l10_pilot_modeling.R",
  "h06_daily_timing_repair_contract.R",
  "h06_daily_timing_repair_modeling.R",
  "h06_daily_non_l10_production_contract.R",
  "h06_daily_non_l10_production_modeling.R",
  "h06_daily_gap_clock_repair_contract.R",
  "h06_daily_gap_clock_repair_data.R",
  "run_h06_daily_gap_clock_repair_base.R"
))
fit_code_sha256 <- h06d_gap_object_sha256(vapply(
  code_paths,
  h06d_gap_sha256,
  character(1L)
))

if (file.exists(paths$base_index)) {
  base_index <- readr::read_csv(paths$base_index, show_col_types = FALSE)
  h06d_gap_assert(
    !anyDuplicated(base_index$frame_key) &&
      all(base_index$frame_key %in% inventory$frame_key),
    "An existing repair base checkpoint is incompatible"
  )
} else {
  base_index <- tibble::tibble()
}

message("Gap clock repair: fitting 90 cells serially with checkpoints")
session_started <- proc.time()[["elapsed"]]
for (index in seq_len(nrow(inventory))) {
  meta <- inventory[index, , drop = FALSE]
  prior <- if (nrow(base_index)) {
    which(base_index$frame_key == meta$frame_key[[1L]])
  } else {
    integer()
  }
  reusable <- length(prior) == 1L &&
    identical(base_index$fit_code_sha256[[prior]], fit_code_sha256) &&
    isTRUE(base_index$outer_success[[prior]]) &&
    identical(
      base_index$frame_object_sha256[[prior]],
      meta$frame_object_sha256[[1L]]
    ) &&
    file.exists(file.path(root, base_index$checkpoint_relative_path[[prior]])) &&
    identical(
      h06d_gap_sha256(file.path(
        root,
        base_index$checkpoint_relative_path[[prior]]
      )),
      base_index$checkpoint_sha256[[prior]]
    )
  if (isTRUE(reusable)) next
  if (length(prior)) base_index <- base_index[-prior, , drop = FALSE]

  key <- meta$frame_key[[1L]]
  metric <- dplyr::filter(metrics, .data$metric_id == meta$metric_id[[1L]])
  predictor <- dplyr::filter(
    predictors,
    .data$predictor_id == meta$predictor_id[[1L]]
  )
  h06d_gap_assert(
    nrow(metric) == 1L && nrow(predictor) == 1L,
    "Registry lookup failed for `%s`",
    key
  )
  message(sprintf("  repaired base cell %02d/90: %s", index, key))
  capture <- h06d_prod_capture(h06d_prod_fit_cell(
    frames[[key]],
    metric,
    predictor,
    meta
  ))
  route <- if (meta$metric_slot[[1L]] %in% c(9L, 10L, 12L, 13L)) {
    "participant_cluster_HC3"
  } else {
    "mixed_model"
  }
  checkpoint_path <- file.path(
    paths$model_cells,
    paste0(
      sprintf("cell_%03d_", index),
      digest::digest(key, algo = "sha256", serialize = FALSE),
      ".rds"
    )
  )
  object <- list(
    authorization = h06d_gap_authorization()$authorization,
    parent_authorization = "H06-D-014",
    gate = h06d_gap_authorization()$gate,
    frame_key = key,
    frame_object_sha256 = meta$frame_object_sha256[[1L]],
    route = route,
    result = capture$value,
    outer_warnings = capture$warnings,
    outer_error = capture$error,
    elapsed_seconds = capture$elapsed_seconds,
    fit_code_sha256 = fit_code_sha256,
    r_version = as.character(getRversion()),
    package_versions = h06d_gap_package_versions(required_packages)
  )
  h06d_gap_write_rds(object, checkpoint_path)
  row <- meta |>
    dplyr::mutate(
      route = .env$route,
      outer_success = !is.null(.env$capture$value),
      outer_warning_count = length(.env$capture$warnings),
      outer_warnings = paste(.env$capture$warnings, collapse = " | "),
      outer_error = .env$capture$error,
      elapsed_seconds = .env$capture$elapsed_seconds,
      fit_code_sha256 = .env$fit_code_sha256,
      checkpoint_relative_path = h06d_gap_relative(root, checkpoint_path),
      checkpoint_sha256 = h06d_gap_sha256(checkpoint_path),
      checkpoint_bytes = as.numeric(file.info(checkpoint_path)$size)
    )
  base_index <- dplyr::bind_rows(base_index, row) |>
    dplyr::arrange(.data$metric_slot, .data$predictor_order, .data$run_order)
  h06d_gap_write_csv(base_index, paths$base_index)

  current <- base_index$fit_code_sha256 == fit_code_sha256
  failures <- sum(!base_index$outer_success[current])
  if (sum(current) >= 20L && failures / sum(current) > 0.10) {
    h06d_gap_abort(
      "Systemic repaired-base failure rate exceeded 10%% (%d/%d)",
      failures,
      sum(current)
    )
  }
  if (index %% 15L == 0L) {
    invisible(h06d_gap_verify_protected_1011(
      root,
      sprintf("base_checkpoint_%03d", index)
    ))
  }
}

h06d_gap_assert(
  nrow(base_index) == 90L && all(base_index$outer_success) &&
    all(base_index$fit_code_sha256 == fit_code_sha256) &&
    !anyDuplicated(base_index$frame_key),
  "The 90-cell repaired base phase did not complete"
)
base_elapsed <- unname(proc.time()[["elapsed"]] - session_started)
post_base <- h06d_gap_verify_protected_1011(root, "post_base")
h06d_gap_write_csv(
  post_base,
  file.path(
    paths$diagnostic,
    "H06_daily_gap_clock_repair_protected_post_base.csv"
  )
)
h06d_gap_write_rds(
  list(
    authorization = h06d_gap_authorization()$authorization,
    parent_authorization = "H06-D-014",
    gate = h06d_gap_authorization()$gate,
    phase = "BASE_COMPLETE",
    completed_cells = 90L,
    base_elapsed_seconds = base_elapsed,
    base_failures = sum(!base_index$outer_success),
    fit_code_sha256 = fit_code_sha256,
    frame_inventory_sha256 = h06d_gap_sha256(file.path(
      paths$model_data,
      "H06_daily_gap_clock_repair_frame_inventory.csv"
    )),
    updated = format(Sys.time(), tz = "UTC", usetz = TRUE)
  ),
  paths$state
)
message(sprintf(
  "Gap clock repair base complete: 90 cells in %.1f seconds",
  base_elapsed
))
