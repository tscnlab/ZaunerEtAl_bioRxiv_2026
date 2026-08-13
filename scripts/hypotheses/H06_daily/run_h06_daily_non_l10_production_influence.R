#!/usr/bin/env Rscript

# H06-D-013 phase 2: complete serial participant/site deletion diagnostics.

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
diagnostic_dir <- file.path(root, "artifacts/08_diagnostics/H06_daily")
model_data_dir <- file.path(root, "artifacts/06_model_data/H06_daily")
influence_dir <- file.path(
  diagnostic_dir,
  "H06_daily_non_l10_production_influence_cells"
)
dir.create(influence_dir, recursive = TRUE, showWarnings = FALSE)

message("H06-D-013 phase 2: verifying sealed inputs and completed base objects")
invisible(h06d_prod_verify_contract(root, h06d_prod_input_contract()))
invisible(h06d_prod_verify_contract(
  root,
  h06d_prod_main_h06_contract() |>
    dplyr::mutate(input_id = paste0("main_h06_", dplyr::row_number()), .before = 1L)
))
preservation_baseline <- readr::read_csv(
  file.path(
    diagnostic_dir,
    "H06_daily_non_l10_production_preservation_baseline.csv"
  ),
  show_col_types = FALSE
)
h06d_prod_recheck_preservation(
  root,
  preservation_baseline,
  "pre_influence"
) |>
  h06d_prod_write_csv(file.path(
    diagnostic_dir,
    "H06_daily_non_l10_production_preservation_pre_influence.csv"
  ))

base_index <- readr::read_csv(paths$base_index, show_col_types = FALSE)
h06d_prod_assert(
  nrow(base_index) == 468L && all(base_index$outer_success) &&
    !anyDuplicated(base_index$frame_key) &&
    length(unique(base_index$fit_code_sha256)) == 1L,
  "The completed 468-cell base checkpoint is missing or inconsistent"
)
base_paths <- file.path(root, base_index$checkpoint_relative_path)
h06d_prod_assert(
  all(file.exists(base_paths)) && all(vapply(
    seq_along(base_paths),
    function(index) {
      h06d_prod_sha256(base_paths[[index]]) ==
        base_index$checkpoint_sha256[[index]]
    },
    logical(1)
  )),
  "A completed base-cell object changed before influence fitting"
)
state <- readRDS(paths$state)
h06d_prod_assert(
  identical(state$authorization, "H06-D-013") &&
    identical(state$phase, "BASE_COMPLETE") &&
    state$completed_cells == 468L,
  "The H06-D-013 production state is not ready for influence fitting"
)

message("H06-D-013 phase 2: rebuilding and identity-checking 468 frames")
frame_build <- h06d_nl_build_frames(
  h06d_nl_load_sources(root),
  retain_frames = TRUE
)
frames <- frame_build$frames
frame_inventory <- readr::read_csv(
  file.path(
    model_data_dir,
    "H06_daily_non_l10_pilot_frame_inventory.csv"
  ),
  show_col_types = FALSE
)
h06d_prod_assert(
  nrow(frame_inventory) == 468L &&
    setequal(names(frames), frame_inventory$frame_key) &&
    all(vapply(frame_inventory$frame_key, function(frame_key) {
      digest::digest(
        frames[[frame_key]],
        algo = "sha256",
        serialize = TRUE
      ) == frame_inventory$frame_object_sha256[
        frame_inventory$frame_key == frame_key
      ][[1L]]
    }, logical(1))),
  "A rebuilt production frame changed before influence fitting"
)

metrics <- h06d_nl_metric_registry()
predictors <- h06d_nl_predictor_registry()
site_order <- h06d_nl_site_levels(root)
ordered_index <- base_index |>
  dplyr::arrange(.data$metric_slot, .data$predictor_order, .data$run_order) |>
  dplyr::mutate(cell_order = dplyr::row_number(), .before = 1L)

code_paths <- file.path(root, c(
  "scripts/hypotheses/H06_daily/h06_daily_non_l10_pilot_contract.R",
  "scripts/hypotheses/H06_daily/h06_daily_non_l10_pilot_data.R",
  "scripts/hypotheses/H06_daily/h06_daily_non_l10_pilot_modeling.R",
  "scripts/hypotheses/H06_daily/h06_daily_timing_repair_contract.R",
  "scripts/hypotheses/H06_daily/h06_daily_timing_repair_modeling.R",
  "scripts/hypotheses/H06_daily/h06_daily_non_l10_production_contract.R",
  "scripts/hypotheses/H06_daily/h06_daily_non_l10_production_modeling.R",
  "scripts/hypotheses/H06_daily/run_h06_daily_non_l10_production_influence.R"
))
influence_code_sha256 <- digest::digest(
  vapply(code_paths, h06d_prod_sha256, character(1)),
  algo = "sha256",
  serialize = TRUE
)

cell_tasks <- function(meta, frame, global_start = 1L) {
  participant_values <- sort(unique(as.character(frame$participant_key)))
  participant_hash <- vapply(
    participant_values,
    digest::digest,
    character(1),
    algo = "sha256",
    serialize = FALSE
  )
  participant_order <- order(participant_hash)
  participant_values <- participant_values[participant_order]
  participant_hash <- participant_hash[participant_order]
  site_values <- site_order[site_order %in% as.character(frame$site)]
  h06d_prod_assert(
    length(participant_values) == meta$participants[[1L]] &&
      length(site_values) == meta$sites[[1L]],
    "Deletion support differs from the frozen inventory for `%s`",
    meta$frame_key[[1L]]
  )
  internal_values <- c(participant_values, site_values)
  types <- c(
    rep("participant", length(participant_values)),
    rep("site", length(site_values))
  )
  labels <- c(
    paste0("participant_sha256:", participant_hash),
    site_values
  )
  tibble::tibble(
    task_within_cell = seq_along(internal_values),
    global_task_id = global_start - 1L + seq_along(internal_values),
    deletion_type = types,
    deletion_value_internal = internal_values,
    deletion_label = labels
  )
}

message("H06-D-013 phase 2: sealing the 66,664-refit task inventory")
task_inventory <- vector("list", nrow(ordered_index))
global_start <- 1L
for (cell_index in seq_len(nrow(ordered_index))) {
  meta <- ordered_index[cell_index, , drop = FALSE]
  tasks <- cell_tasks(meta, frames[[meta$frame_key[[1L]]]], global_start)
  global_start <- max(tasks$global_task_id) + 1L
  task_inventory[[cell_index]] <- tasks |>
    dplyr::select(-"deletion_value_internal") |>
    dplyr::mutate(
      cell_order = cell_index,
      frame_key = meta$frame_key[[1L]],
      run_id = meta$run_id[[1L]],
      metric_slot = meta$metric_slot[[1L]],
      metric_id = meta$metric_id[[1L]],
      predictor_order = meta$predictor_order[[1L]],
      predictor_id = meta$predictor_id[[1L]],
      route = meta$route[[1L]],
      .before = 1L
    )
}
task_inventory <- dplyr::bind_rows(task_inventory)
h06d_prod_assert(
  nrow(task_inventory) == 66664L &&
    identical(task_inventory$global_task_id, seq_len(66664L)) &&
    !anyDuplicated(task_inventory[c("frame_key", "deletion_label")]),
  "The influence task inventory is not the authorized 66,664-refit battery"
)
task_inventory_path <- file.path(
  model_data_dir,
  "H06_daily_non_l10_production_influence_task_inventory.csv"
)
h06d_prod_write_csv(task_inventory, task_inventory_path)
task_inventory_sha256 <- h06d_prod_sha256(task_inventory_path)

if (file.exists(paths$influence)) {
  influence_index <- readr::read_csv(paths$influence, show_col_types = FALSE)
  h06d_prod_assert(
    !anyDuplicated(influence_index$frame_key) &&
      all(influence_index$frame_key %in% ordered_index$frame_key) &&
      all(influence_index$influence_code_sha256 == influence_code_sha256) &&
      all(influence_index$task_inventory_sha256 == task_inventory_sha256),
    "An existing influence checkpoint belongs to a different code or task contract"
  )
} else {
  influence_index <- tibble::tibble()
}

message("H06-D-013 phase 2: running deletions serially with within-cell checkpoints")
influence_session_started <- proc.time()[["elapsed"]]
for (cell_index in seq_len(nrow(ordered_index))) {
  meta <- ordered_index[cell_index, , drop = FALSE]
  if (
    nrow(influence_index) &&
      meta$frame_key[[1L]] %in% influence_index$frame_key
  ) {
    next
  }
  frame_key <- meta$frame_key[[1L]]
  frame <- frames[[frame_key]]
  metric <- dplyr::filter(
    metrics,
    .data$metric_id == meta$metric_id[[1L]]
  )
  predictor <- dplyr::filter(
    predictors,
    .data$predictor_id == meta$predictor_id[[1L]]
  )
  h06d_prod_assert(
    nrow(metric) == 1L && nrow(predictor) == 1L,
    "Registry lookup failed for influence cell `%s`",
    frame_key
  )
  task_start <- min(task_inventory$global_task_id[
    task_inventory$frame_key == frame_key
  ])
  tasks <- cell_tasks(meta, frame, task_start)
  labels_hash <- h06d_prod_object_sha256(tasks |>
    dplyr::select(-"deletion_value_internal"))
  checkpoint_path <- file.path(
    influence_dir,
    paste0(sprintf("cell_%03d_", cell_index), digest::digest(
      frame_key,
      algo = "sha256",
      serialize = FALSE
    ), ".rds")
  )
  if (file.exists(checkpoint_path)) {
    partial <- readRDS(checkpoint_path)
    h06d_prod_assert(
      identical(partial$authorization, "H06-D-013") &&
        identical(partial$frame_key, frame_key) &&
        identical(partial$frame_object_sha256, meta$frame_object_sha256[[1L]]) &&
        identical(partial$influence_code_sha256, influence_code_sha256) &&
        identical(partial$task_labels_sha256, labels_hash) &&
        !anyDuplicated(partial$results$task_within_cell),
      "An existing partial influence checkpoint is incompatible for `%s`",
      frame_key
    )
    results <- partial$results
    prior_cell_wall_seconds <- partial$cell_wall_seconds
  } else {
    results <- tibble::tibble()
    prior_cell_wall_seconds <- 0
  }
  base_object <- readRDS(file.path(root, meta$checkpoint_relative_path[[1L]]))
  h06d_prod_assert(
    identical(base_object$frame_key, frame_key) &&
      !is.null(base_object$result$influence_reference),
    "The base influence reference is missing for `%s`",
    frame_key
  )
  full_effect <- base_object$result$influence_reference$estimate
  full_standard_error <- base_object$result$influence_reference$standard_error
  h06d_prod_assert(
    length(full_effect) == 1L && is.finite(full_effect) &&
      length(full_standard_error) == 1L && is.finite(full_standard_error) &&
      full_standard_error > 0,
    "The full-model effect is not an estimable influence reference for `%s`",
    frame_key
  )
  message(sprintf(
    "  influence cell %03d/468: %s (%d refits)",
    cell_index,
    frame_key,
    nrow(tasks)
  ))
  cell_session_started <- proc.time()[["elapsed"]]
  for (task_index in seq_len(nrow(tasks))) {
    task <- tasks[task_index, , drop = FALSE]
    if (
      nrow(results) &&
        task$task_within_cell[[1L]] %in% results$task_within_cell
    ) {
      next
    }
    capture <- h06d_prod_capture(h06d_prod_deletion_refit(
      frame = frame,
      metric = metric,
      predictor = predictor,
      route = meta$route[[1L]],
      deletion_type = task$deletion_type[[1L]],
      deletion_value = task$deletion_value_internal[[1L]],
      full_effect = full_effect,
      full_standard_error = full_standard_error
    ))
    result <- if (is.null(capture$value)) {
      tibble::tibble(
        participant_days = NA_integer_,
        participants = NA_integer_,
        sites = NA_integer_,
        estimate = NA_real_,
        standard_error = NA_real_,
        lower_95 = NA_real_,
        upper_95 = NA_real_,
        absolute_shift_in_full_se = NA_real_,
        direction_reversal = NA,
        converged = FALSE,
        warning_count = length(capture$warnings),
        warnings = paste(capture$warnings, collapse = " | "),
        fit_error = capture$error,
        elapsed_seconds = capture$elapsed_seconds,
        influence_classification = "NON_ESTIMABLE_DELETION_REFIT"
      )
    } else {
      capture$value |>
        dplyr::select(-dplyr::any_of(c("deletion_type", "deletion_value")))
    }
    result <- result |>
      dplyr::mutate(
        cell_order = cell_index,
        task_within_cell = task$task_within_cell[[1L]],
        global_task_id = task$global_task_id[[1L]],
        frame_key = frame_key,
        run_id = meta$run_id[[1L]],
        dataset_id = meta$dataset_id[[1L]],
        placement_id = meta$placement_id[[1L]],
        sample_role = meta$sample_role[[1L]],
        analysis_role = meta$analysis_role[[1L]],
        metric_slot = meta$metric_slot[[1L]],
        metric_id = meta$metric_id[[1L]],
        predictor_order = meta$predictor_order[[1L]],
        predictor_id = meta$predictor_id[[1L]],
        route = meta$route[[1L]],
        deletion_type = task$deletion_type[[1L]],
        deletion_label = task$deletion_label[[1L]],
        full_effect = full_effect,
        full_standard_error = full_standard_error,
        .before = 1L
      )
    results <- dplyr::bind_rows(results, result) |>
      dplyr::arrange(.data$task_within_cell)

    if (task_index %% 25L == 0L || task_index == nrow(tasks)) {
      current_cell_wall_seconds <- prior_cell_wall_seconds + unname(
        proc.time()[["elapsed"]] - cell_session_started
      )
      h06d_prod_write_rds(
        list(
          authorization = "H06-D-013",
          gate = "H06-D-G2",
          frame_key = frame_key,
          frame_object_sha256 = meta$frame_object_sha256[[1L]],
          base_checkpoint_sha256 = meta$checkpoint_sha256[[1L]],
          influence_code_sha256 = influence_code_sha256,
          task_inventory_sha256 = task_inventory_sha256,
          task_labels_sha256 = labels_hash,
          expected_tasks = nrow(tasks),
          results = results,
          cell_wall_seconds = current_cell_wall_seconds,
          r_version = as.character(getRversion()),
          package_versions = vapply(
            required_packages,
            function(package) as.character(utils::packageVersion(package)),
            character(1)
          )
        ),
        checkpoint_path
      )
    }

    completed_before <- if (nrow(influence_index)) {
      sum(influence_index$completed_refits)
    } else {
      0L
    }
    completed_total <- completed_before + nrow(results)
    failures_total <- if (nrow(influence_index)) {
      sum(influence_index$failed_refits)
    } else {
      0L
    }
    failures_total <- failures_total + sum(
      results$influence_classification == "NON_ESTIMABLE_DELETION_REFIT"
    )
    current_cell_wall_seconds <- prior_cell_wall_seconds + unname(
      proc.time()[["elapsed"]] - cell_session_started
    )
    completed_influence_wall <- if (nrow(influence_index)) {
      sum(influence_index$cell_wall_seconds)
    } else {
      0
    }
    total_production_wall <- state$base_elapsed_seconds +
      completed_influence_wall + current_cell_wall_seconds
    if (total_production_wall > 3600) {
      h06d_prod_abort(
        paste0(
          "The checkpointed base-plus-influence runtime exceeded the one-hour ",
          "H06-D-013 boundary after %d influence refits"
        ),
        completed_total
      )
    }
    if (completed_total >= 500L && failures_total / completed_total > 0.10) {
      h06d_prod_abort(
        "Systemic deletion-refit failure rate exceeded 10%% (%d/%d)",
        failures_total,
        completed_total
      )
    }
  }

  h06d_prod_assert(
    nrow(results) == nrow(tasks) &&
      identical(results$task_within_cell, seq_len(nrow(tasks))) &&
      identical(results$global_task_id, tasks$global_task_id),
    "Influence cell `%s` did not complete exactly",
    frame_key
  )
  checkpoint_sha256 <- h06d_prod_sha256(checkpoint_path)
  failed_refits <- sum(
    results$influence_classification == "NON_ESTIMABLE_DELETION_REFIT"
  )
  row <- meta |>
    dplyr::mutate(
      cell_order = cell_index,
      expected_refits = nrow(tasks),
      completed_refits = nrow(results),
      failed_refits = .env$failed_refits,
      warning_count = sum(results$warning_count, na.rm = TRUE),
      direction_reversals = sum(results$direction_reversal, na.rm = TRUE),
      maximum_absolute_shift_in_full_se = if (any(is.finite(
        results$absolute_shift_in_full_se
      ))) {
        max(results$absolute_shift_in_full_se, na.rm = TRUE)
      } else {
        NA_real_
      },
      substantial_limitations = sum(
        results$influence_classification == "SUBSTANTIAL_LIMITATION",
        na.rm = TRUE
      ),
      unstable_refits = sum(
        results$influence_classification == "UNSTABLE",
        na.rm = TRUE
      ),
      cell_wall_seconds = prior_cell_wall_seconds + unname(
        proc.time()[["elapsed"]] - cell_session_started
      ),
      checkpoint_relative_path = h06d_prod_relative_path(root, checkpoint_path),
      checkpoint_sha256 = checkpoint_sha256,
      checkpoint_bytes = as.numeric(file.info(checkpoint_path)$size),
      influence_code_sha256 = influence_code_sha256,
      task_inventory_sha256 = task_inventory_sha256
    )
  influence_index <- dplyr::bind_rows(influence_index, row) |>
    dplyr::arrange(.data$cell_order)
  h06d_prod_write_csv(influence_index, paths$influence)

  if (cell_index %% 25L == 0L) {
    h06d_prod_recheck_preservation(
      root,
      preservation_baseline,
      sprintf("influence_checkpoint_%03d", cell_index)
    )
  }
}

h06d_prod_assert(
  nrow(influence_index) == 468L &&
    sum(influence_index$completed_refits) == 66664L &&
    all(influence_index$completed_refits == influence_index$expected_refits) &&
    !anyDuplicated(influence_index$frame_key) &&
    all(influence_index$influence_code_sha256 == influence_code_sha256) &&
    all(influence_index$task_inventory_sha256 == task_inventory_sha256),
  "The authorized 66,664-refit influence phase did not complete"
)
influence_wall_seconds <- sum(influence_index$cell_wall_seconds)
h06d_prod_recheck_preservation(
  root,
  preservation_baseline,
  "post_influence"
) |>
  h06d_prod_write_csv(file.path(
    diagnostic_dir,
    "H06_daily_non_l10_production_preservation_post_influence.csv"
  ))

h06d_prod_write_rds(
  list(
    gate = "H06-D-G2",
    authorization = "H06-D-013",
    phase = "INFLUENCE_COMPLETE",
    completed_cells = nrow(influence_index),
    completed_refits = sum(influence_index$completed_refits),
    failed_refits = sum(influence_index$failed_refits),
    base_elapsed_seconds = state$base_elapsed_seconds,
    influence_wall_seconds = influence_wall_seconds,
    invocation_wall_seconds = unname(
      proc.time()[["elapsed"]] - influence_session_started
    ),
    task_inventory_sha256 = task_inventory_sha256,
    influence_code_sha256 = influence_code_sha256,
    updated = format(Sys.time(), tz = "UTC", usetz = TRUE)
  ),
  paths$state
)
message(sprintf(
  paste0(
    "H06-D-013 influence phase complete: %s refits across 468 cells in ",
    "%.1f seconds (%d non-estimable refits)"
  ),
  format(sum(influence_index$completed_refits), big.mark = ","),
  influence_wall_seconds,
  sum(influence_index$failed_refits)
))
