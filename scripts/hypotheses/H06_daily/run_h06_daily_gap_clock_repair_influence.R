#!/usr/bin/env Rscript

# H06_daily targeted gap clock-hour repair: serial participant/site deletion
# diagnostics. Run with argument `pilot` for exactly 50 representative refits
# or `full` for the complete checkpointed 90-cell battery.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
.libPaths(c(
  file.path(root, "renv/library/macos/R-4.6/aarch64-apple-darwin23"),
  .libPaths()
))
mode <- if (length(commandArgs(trailingOnly = TRUE))) {
  commandArgs(trailingOnly = TRUE)[[1L]]
} else {
  "pilot"
}
if (!mode %in% c("pilot", "full")) {
  stop("Mode must be `pilot` or `full`", call. = FALSE)
}

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
    sprintf("Missing package(s): %s", paste(missing_packages, collapse = ", ")),
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
  "The repair influence battery requires R 4.6.1"
)
paths <- h06d_gap_paths(root)
dir.create(paths$influence_cells, recursive = TRUE, showWarnings = FALSE)
invisible(h06d_gap_verify_direct_pins(root))
invisible(h06d_gap_verify_protected_1011(root, paste0("pre_influence_", mode)))

state <- readRDS(paths$state)
h06d_gap_assert(
  identical(state$phase, "BASE_COMPLETE") && state$completed_cells == 90L,
  "The completed repaired base phase is required"
)
base_index <- readr::read_csv(paths$base_index, show_col_types = FALSE) |>
  dplyr::arrange(.data$metric_slot, .data$predictor_order, .data$run_order) |>
  dplyr::mutate(cell_order = dplyr::row_number(), .before = 1L)
h06d_gap_assert(
  nrow(base_index) == 90L && all(base_index$outer_success) &&
    !anyDuplicated(base_index$frame_key),
  "The repaired base index is incomplete"
)
bundle <- readRDS(file.path(
  paths$model_data,
  "H06_daily_gap_clock_repair_frame_bundle.rds"
))
frames <- bundle$frames
h06d_gap_assert(
  identical(names(frames), base_index$frame_key) &&
    all(vapply(base_index$frame_key, function(key) {
      h06d_gap_object_sha256(frames[[key]]) ==
        base_index$frame_object_sha256[base_index$frame_key == key][[1L]]
    }, logical(1L))),
  "A corrected frame differs from its base-fit identity"
)

metrics <- h06d_nl_metric_registry()
predictors <- h06d_nl_predictor_registry()
site_order <- h06d_nl_site_levels(root)

cell_tasks <- function(meta, frame, global_start) {
  participant_values <- sort(unique(as.character(frame$participant_key)))
  participant_hash <- vapply(
    participant_values,
    digest::digest,
    character(1L),
    algo = "sha256",
    serialize = FALSE
  )
  order_index <- order(participant_hash)
  participant_values <- participant_values[order_index]
  participant_hash <- participant_hash[order_index]
  site_values <- site_order[site_order %in% as.character(frame$site)]
  h06d_gap_assert(
    length(participant_values) == meta$participants[[1L]] &&
      length(site_values) == meta$sites[[1L]],
    "Deletion support changed for `%s`",
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

message("Gap clock repair: constructing the deletion task inventory")
task_lists <- vector("list", nrow(base_index))
global_start <- 1L
for (index in seq_len(nrow(base_index))) {
  meta <- base_index[index, , drop = FALSE]
  tasks <- cell_tasks(meta, frames[[meta$frame_key[[1L]]]], global_start)
  global_start <- max(tasks$global_task_id) + 1L
  task_lists[[index]] <- tasks |>
    dplyr::mutate(
      cell_order = index,
      frame_key = meta$frame_key[[1L]],
      route = meta$route[[1L]],
      metric_slot = meta$metric_slot[[1L]],
      metric_id = meta$metric_id[[1L]],
      placement_id = meta$placement_id[[1L]],
      sample_role = meta$sample_role[[1L]],
      predictor_order = meta$predictor_order[[1L]],
      predictor_id = meta$predictor_id[[1L]],
      .before = 1L
    )
}
task_inventory_internal <- dplyr::bind_rows(task_lists)
task_inventory <- task_inventory_internal |>
  dplyr::select(-"deletion_value_internal")
h06d_gap_assert(
  nrow(task_inventory) == 12837L &&
    identical(task_inventory$global_task_id, seq_len(12837L)) &&
    !anyDuplicated(task_inventory[c("frame_key", "deletion_label")]),
  "The repair did not resolve to the expected 12,837 deletion refits"
)
task_inventory_path <- file.path(
  paths$model_data,
  "H06_daily_gap_clock_repair_influence_task_inventory.csv"
)
h06d_gap_write_csv(task_inventory, task_inventory_path)
task_inventory_sha256 <- h06d_gap_sha256(task_inventory_path)

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
  "run_h06_daily_gap_clock_repair_influence.R"
))
influence_code_sha256 <- h06d_gap_object_sha256(vapply(
  code_paths,
  h06d_gap_sha256,
  character(1L)
))

run_one <- function(task, meta, frame, full_effect, full_se) {
  metric <- dplyr::filter(
    metrics,
    .data$metric_id == meta$metric_id[[1L]]
  )
  predictor <- dplyr::filter(
    predictors,
    .data$predictor_id == meta$predictor_id[[1L]]
  )
  capture <- h06d_prod_capture(h06d_prod_deletion_refit(
    frame = frame,
    metric = metric,
    predictor = predictor,
    route = meta$route[[1L]],
    deletion_type = task$deletion_type[[1L]],
    deletion_value = task$deletion_value_internal[[1L]],
    full_effect = full_effect,
    full_standard_error = full_se
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
  result |>
    dplyr::mutate(
      cell_order = task$cell_order[[1L]],
      task_within_cell = task$task_within_cell[[1L]],
      global_task_id = task$global_task_id[[1L]],
      frame_key = task$frame_key[[1L]],
      route = task$route[[1L]],
      metric_slot = task$metric_slot[[1L]],
      metric_id = task$metric_id[[1L]],
      placement_id = task$placement_id[[1L]],
      sample_role = task$sample_role[[1L]],
      predictor_order = task$predictor_order[[1L]],
      predictor_id = task$predictor_id[[1L]],
      deletion_type = task$deletion_type[[1L]],
      deletion_label = task$deletion_label[[1L]],
      full_effect = full_effect,
      full_standard_error = full_se,
      .before = 1L
    )
}

if (mode == "pilot") {
  quota <- tibble::tribble(
    ~route, ~deletion_type, ~quota,
    "participant_cluster_HC3", "participant", 20L,
    "participant_cluster_HC3", "site", 5L,
    "mixed_model", "participant", 20L,
    "mixed_model", "site", 5L
  )
  pilot_tasks <- task_inventory_internal |>
    dplyr::mutate(
      selection_hash = vapply(
        paste(.data$frame_key, .data$deletion_label, sep = "::"),
        digest::digest,
        character(1L),
        algo = "sha256",
        serialize = FALSE
      )
    ) |>
    dplyr::inner_join(quota, by = c("route", "deletion_type")) |>
    dplyr::group_by(.data$route, .data$deletion_type) |>
    dplyr::arrange(.data$selection_hash, .by_group = TRUE) |>
    dplyr::filter(dplyr::row_number() <= dplyr::first(.data$quota)) |>
    dplyr::ungroup() |>
    dplyr::arrange(.data$route, .data$deletion_type, .data$selection_hash)
  h06d_gap_assert(
    nrow(pilot_tasks) == 50L &&
      identical(
        dplyr::count(pilot_tasks, .data$route, .data$deletion_type)$n,
        c(20L, 5L, 20L, 5L)
      ),
    "The representative 50-refit pilot selection failed"
  )
  pilot_started <- proc.time()[["elapsed"]]
  results <- vector("list", 50L)
  for (index in seq_len(nrow(pilot_tasks))) {
    task <- pilot_tasks[index, , drop = FALSE]
    meta <- base_index |>
      dplyr::filter(.data$frame_key == task$frame_key[[1L]])
    base_object <- readRDS(file.path(root, meta$checkpoint_relative_path[[1L]]))
    reference <- base_object$result$influence_reference
    results[[index]] <- run_one(
      task,
      meta,
      frames[[task$frame_key[[1L]]]],
      reference$estimate,
      reference$standard_error
    )
  }
  results <- dplyr::bind_rows(results)
  pilot_wall <- unname(proc.time()[["elapsed"]] - pilot_started)
  failures <- sum(
    results$influence_classification == "NON_ESTIMABLE_DELETION_REFIT"
  )
  projection <- tibble::tibble(
    pilot_refits = 50L,
    pilot_failures = failures,
    pilot_failure_rate = failures / 50,
    pilot_wall_seconds = pilot_wall,
    seconds_per_refit = pilot_wall / 50,
    full_refits = nrow(task_inventory),
    projected_full_wall_seconds = pilot_wall / 50 * nrow(task_inventory),
    projected_full_wall_minutes =
      pilot_wall / 50 * nrow(task_inventory) / 60,
    task_inventory_sha256 = task_inventory_sha256,
    influence_code_sha256 = influence_code_sha256,
    protected_identity_status = "1011/1011 BYTE_IDENTICAL",
    r_version = as.character(getRversion()),
    gate = h06d_gap_authorization()$gate
  )
  h06d_gap_write_csv(
    results,
    file.path(
      paths$diagnostic,
      "H06_daily_gap_clock_repair_influence_pilot_results.csv"
    )
  )
  h06d_gap_write_csv(
    projection,
    file.path(
      paths$diagnostic,
      "H06_daily_gap_clock_repair_influence_pilot_runtime.csv"
    )
  )
  invisible(h06d_gap_verify_protected_1011(root, "post_influence_pilot"))
  message(sprintf(
    paste0(
      "Gap clock repair influence pilot complete: 50 refits in %.2f s; ",
      "%d failures; projected full %.1f min"
    ),
    pilot_wall,
    failures,
    projection$projected_full_wall_minutes
  ))
  quit(save = "no", status = 0L)
}

message("Gap clock repair: running the complete 12,837-refit battery serially")
if (file.exists(paths$influence_index)) {
  influence_index <- readr::read_csv(
    paths$influence_index,
    show_col_types = FALSE
  )
  h06d_gap_assert(
    !anyDuplicated(influence_index$frame_key) &&
      all(influence_index$frame_key %in% base_index$frame_key) &&
      all(influence_index$task_inventory_sha256 == task_inventory_sha256) &&
      all(influence_index$influence_code_sha256 == influence_code_sha256),
    "An existing influence checkpoint is incompatible"
  )
} else {
  influence_index <- tibble::tibble()
}

health_path <- file.path(
  paths$diagnostic,
  "H06_daily_gap_clock_repair_influence_health_checks.csv"
)
health <- if (file.exists(health_path)) {
  readr::read_csv(health_path, show_col_types = FALSE)
} else {
  tibble::tibble()
}
session_started <- proc.time()[["elapsed"]]
last_health <- session_started

for (cell_index in seq_len(nrow(base_index))) {
  meta <- base_index[cell_index, , drop = FALSE]
  if (nrow(influence_index) && meta$frame_key[[1L]] %in% influence_index$frame_key) {
    next
  }
  key <- meta$frame_key[[1L]]
  tasks <- task_inventory_internal |>
    dplyr::filter(.data$frame_key == .env$key) |>
    dplyr::arrange(.data$task_within_cell)
  checkpoint_path <- file.path(
    paths$influence_cells,
    paste0(
      sprintf("cell_%03d_", cell_index),
      digest::digest(key, algo = "sha256", serialize = FALSE),
      ".rds"
    )
  )
  labels_hash <- h06d_gap_object_sha256(tasks |>
    dplyr::select(-"deletion_value_internal"))
  if (file.exists(checkpoint_path)) {
    partial <- readRDS(checkpoint_path)
    h06d_gap_assert(
      identical(partial$frame_key, key) &&
        identical(partial$frame_object_sha256, meta$frame_object_sha256[[1L]]) &&
        identical(partial$influence_code_sha256, influence_code_sha256) &&
        identical(partial$task_inventory_sha256, task_inventory_sha256) &&
        identical(partial$task_labels_sha256, labels_hash) &&
        !anyDuplicated(partial$results$task_within_cell),
      "An existing partial influence checkpoint is incompatible for `%s`",
      key
    )
    results <- partial$results
    prior_wall <- partial$cell_wall_seconds
  } else {
    results <- tibble::tibble()
    prior_wall <- 0
  }
  base_object <- readRDS(file.path(root, meta$checkpoint_relative_path[[1L]]))
  reference <- base_object$result$influence_reference
  h06d_gap_assert(
    length(reference$estimate) == 1L && is.finite(reference$estimate) &&
      length(reference$standard_error) == 1L &&
      is.finite(reference$standard_error) && reference$standard_error > 0,
    "The influence reference is unavailable for `%s`",
    key
  )
  message(sprintf(
    "  repaired influence cell %02d/90: %s (%d refits)",
    cell_index,
    key,
    nrow(tasks)
  ))
  cell_started <- proc.time()[["elapsed"]]
  for (task_index in seq_len(nrow(tasks))) {
    task <- tasks[task_index, , drop = FALSE]
    if (nrow(results) &&
        task$task_within_cell[[1L]] %in% results$task_within_cell) {
      next
    }
    result <- run_one(
      task,
      meta,
      frames[[key]],
      reference$estimate,
      reference$standard_error
    )
    results <- dplyr::bind_rows(results, result) |>
      dplyr::arrange(.data$task_within_cell)
    if (task_index %% 25L == 0L || task_index == nrow(tasks)) {
      cell_wall <- prior_wall + unname(
        proc.time()[["elapsed"]] - cell_started
      )
      h06d_gap_write_rds(
        list(
          authorization = h06d_gap_authorization()$authorization,
          gate = h06d_gap_authorization()$gate,
          frame_key = key,
          frame_object_sha256 = meta$frame_object_sha256[[1L]],
          base_checkpoint_sha256 = meta$checkpoint_sha256[[1L]],
          influence_code_sha256 = influence_code_sha256,
          task_inventory_sha256 = task_inventory_sha256,
          task_labels_sha256 = labels_hash,
          expected_tasks = nrow(tasks),
          results = results,
          cell_wall_seconds = cell_wall,
          r_version = as.character(getRversion()),
          package_versions = h06d_gap_package_versions(required_packages)
        ),
        checkpoint_path
      )
    }
    completed_prior <- if (nrow(influence_index)) {
      sum(influence_index$completed_refits)
    } else {
      0L
    }
    failures_prior <- if (nrow(influence_index)) {
      sum(influence_index$failed_refits)
    } else {
      0L
    }
    completed_total <- completed_prior + nrow(results)
    failures_total <- failures_prior + sum(
      results$influence_classification == "NON_ESTIMABLE_DELETION_REFIT"
    )
    h06d_gap_assert(
      completed_total < 500L || failures_total / completed_total <= 0.10,
      "Systemic deletion-refit failure rate exceeded 10%% (%d/%d)",
      failures_total,
      completed_total
    )
  }
  h06d_gap_assert(
    nrow(results) == nrow(tasks) &&
      identical(results$task_within_cell, tasks$task_within_cell),
    "Influence cell `%s` did not complete exactly",
    key
  )
  failed <- sum(
    results$influence_classification == "NON_ESTIMABLE_DELETION_REFIT"
  )
  row <- meta |>
    dplyr::mutate(
      cell_order = cell_index,
      expected_refits = nrow(tasks),
      completed_refits = nrow(results),
      failed_refits = failed,
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
      cell_wall_seconds = prior_wall + unname(
        proc.time()[["elapsed"]] - cell_started
      ),
      checkpoint_relative_path = h06d_gap_relative(root, checkpoint_path),
      checkpoint_sha256 = h06d_gap_sha256(checkpoint_path),
      checkpoint_bytes = as.numeric(file.info(checkpoint_path)$size),
      influence_code_sha256 = influence_code_sha256,
      task_inventory_sha256 = task_inventory_sha256
    )
  influence_index <- dplyr::bind_rows(influence_index, row) |>
    dplyr::arrange(.data$cell_order)
  h06d_gap_write_csv(influence_index, paths$influence_index)

  now <- proc.time()[["elapsed"]]
  if (now - last_health >= 15 * 60 || cell_index %% 15L == 0L ||
      cell_index == nrow(base_index)) {
    protected <- h06d_gap_verify_protected_1011(
      root,
      sprintf("influence_health_%03d", cell_index)
    )
    completed <- sum(influence_index$completed_refits)
    failures <- sum(influence_index$failed_refits)
    elapsed <- unname(now - session_started)
    health_row <- tibble::tibble(
      health_check_time_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
      completed_cells = nrow(influence_index),
      completed_refits = completed,
      total_refits = nrow(task_inventory),
      non_estimable_refits = failures,
      non_estimable_rate = failures / completed,
      invocation_elapsed_seconds = elapsed,
      observed_seconds_per_refit = elapsed / completed,
      projected_remaining_seconds =
        elapsed / completed * (nrow(task_inventory) - completed),
      repeated_checkpoint_failures = 0L,
      protected_identities_verified = sum(protected$identity_verified),
      protected_identities_expected = nrow(protected),
      protected_identity_status = "BYTE_IDENTICAL",
      gate = h06d_gap_authorization()$gate
    )
    health <- dplyr::bind_rows(health, health_row)
    h06d_gap_write_csv(health, health_path)
    message(sprintf(
      paste0(
        "  health: %d/%d refits; %d non-estimable (%.2f%%); ",
        "%.1f min elapsed; protected 1011/1011"
      ),
      completed,
      nrow(task_inventory),
      failures,
      100 * failures / completed,
      elapsed / 60
    ))
    last_health <- now
  }
}

h06d_gap_assert(
  nrow(influence_index) == 90L &&
    sum(influence_index$completed_refits) == 12837L &&
    all(influence_index$completed_refits == influence_index$expected_refits) &&
    !anyDuplicated(influence_index$frame_key),
  "The complete repaired influence battery did not finish"
)
post <- h06d_gap_verify_protected_1011(root, "post_influence_full")
h06d_gap_write_csv(
  post,
  file.path(
    paths$diagnostic,
    "H06_daily_gap_clock_repair_protected_post_influence.csv"
  )
)
state$phase <- "INFLUENCE_COMPLETE"
state$completed_refits <- sum(influence_index$completed_refits)
state$failed_refits <- sum(influence_index$failed_refits)
state$influence_wall_seconds <- sum(influence_index$cell_wall_seconds)
state$influence_invocation_seconds <- unname(
  proc.time()[["elapsed"]] - session_started
)
state$task_inventory_sha256 <- task_inventory_sha256
state$influence_code_sha256 <- influence_code_sha256
state$updated <- format(Sys.time(), tz = "UTC", usetz = TRUE)
h06d_gap_write_rds(state, paths$state)
message(sprintf(
  "Gap clock repair influence complete: 12,837 refits in %.1f seconds; %d non-estimable",
  state$influence_wall_seconds,
  state$failed_refits
))
