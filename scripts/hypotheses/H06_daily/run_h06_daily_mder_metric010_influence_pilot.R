#!/usr/bin/env Rscript

# Time 50 deterministic production-code participant-deletion refits.  This
# script does not run the complete influence batch.

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
  "digest", "dplyr", "lme4", "performance", "readr", "tibble"
)
stopifnot(
  identical(as.character(getRversion()), "4.6.1"),
  all(vapply(required_packages, requireNamespace, logical(1), quietly = TRUE))
)

source(file.path(
  root,
  "scripts/hypotheses/H06_daily/h06_daily_mder_metric010_contract.R"
))
source(file.path(
  root,
  "scripts/hypotheses/H06_daily/h06_daily_mder_metric010_data.R"
))
source(file.path(
  root,
  "scripts/hypotheses/H06_daily/h06_daily_mder_metric010_modeling.R"
))

roots <- h06d_m10_artifact_roots(root)
producer <- paste0(
  "scripts/hypotheses/H06_daily/",
  "run_h06_daily_mder_metric010_influence_pilot.R"
)
frame_registry_path <- paste0(
  "artifacts/06_model_data/H06_daily/",
  "H06_daily_mder_metric010_frame_registry.csv"
)
family_model_path <- paste0(
  "artifacts/07_models/H06_daily/",
  "H06_daily_mder_metric010_family_pilot.rds"
)
family_verdict_path <- paste0(
  "artifacts/08_diagnostics/H06_daily/",
  "H06_daily_mder_metric010_family_pilot_verdict.csv"
)
frame_registry <- readr::read_csv(
  file.path(root, frame_registry_path),
  show_col_types = FALSE
)
family_models <- readRDS(file.path(root, family_model_path))
family_verdict <- readr::read_csv(
  file.path(root, family_verdict_path),
  show_col_types = FALSE
)
h06d_m10_assert(
  all(grepl("RETAIN_GAUSSIAN_IDENTITY", family_verdict$family_disposition)),
  "The METRIC-010 influence pilot requires a passed family pilot"
)

predictors <- h06d_m10_predictor_registry()
task_rows <- list()
frames <- list()
full_effects <- list()
for (index in seq_len(nrow(predictors))) {
  predictor <- predictors[index, ]
  registry_row <- frame_registry |>
    dplyr::filter(
      .data$run_id == "primary__near_eye__all_available",
      .data$predictor_id == predictor$predictor_id[[1L]]
    )
  frame <- readRDS(file.path(root, registry_row$frame_path[[1L]]))
  key <- predictor$predictor_id[[1L]]
  frames[[key]] <- frame
  full_model <- family_models[[key]]$gaussian_reml$value
  full_effects[[key]] <- h06d_m10_effect_row(full_model, predictor)
  participant_values <- sort(unique(as.character(frame$participant_key)))
  task_rows[[key]] <- tibble::tibble(
    predictor_order = predictor$predictor_order[[1L]],
    predictor_id = key,
    deletion_value = participant_values
  )
}
all_tasks <- dplyr::bind_rows(task_rows) |>
  dplyr::mutate(
    task_hash = vapply(
      paste(.data$predictor_id, .data$deletion_value, sep = "::"),
      digest::digest,
      character(1),
      algo = "sha256"
    )
  ) |>
  dplyr::arrange(.data$task_hash)
pilot_tasks <- all_tasks |>
  dplyr::slice_head(n = 50L) |>
  dplyr::mutate(pilot_replicate = dplyr::row_number())
h06d_m10_assert(nrow(pilot_tasks) == 50L, "Influence pilot is not 50 refits")

started <- proc.time()[["elapsed"]]
results <- list()
for (index in seq_len(nrow(pilot_tasks))) {
  task <- pilot_tasks[index, ]
  predictor <- predictors |>
    dplyr::filter(.data$predictor_id == task$predictor_id[[1L]])
  full <- full_effects[[task$predictor_id[[1L]]]]
  results[[index]] <- h06d_m10_deletion_refit(
    frame = frames[[task$predictor_id[[1L]]]],
    predictor = predictor,
    deletion_type = "participant",
    deletion_value = task$deletion_value[[1L]],
    full_estimate = full$estimate,
    full_standard_error = full$standard_error
  ) |>
    dplyr::mutate(
      pilot_replicate = task$pilot_replicate[[1L]],
      predictor_order = predictor$predictor_order[[1L]],
      predictor_id = predictor$predictor_id[[1L]],
      deletion_hash = substr(task$task_hash[[1L]], 1L, 12L)
    )
}
wall_seconds <- unname(proc.time()[["elapsed"]] - started)
results <- dplyr::bind_rows(results) |>
  dplyr::arrange(.data$pilot_replicate)

total_participant_tasks <- nrow(all_tasks)
total_site_tasks <- sum(vapply(
  frames,
  function(frame) dplyr::n_distinct(frame$site),
  integer(1)
))
total_production_tasks <- total_participant_tasks + total_site_tasks
per_refit_seconds <- wall_seconds / nrow(results)
projected_seconds <- per_refit_seconds * total_production_tasks
runtime <- tibble::tibble(
  pilot_refits = nrow(results),
  pilot_failures = sum(!results$converged | is.na(results$estimate)),
  pilot_wall_seconds = wall_seconds,
  median_refit_seconds = stats::median(results$elapsed_seconds),
  maximum_refit_seconds = max(results$elapsed_seconds),
  participant_deletion_tasks = total_participant_tasks,
  site_deletion_tasks = total_site_tasks,
  total_production_tasks = total_production_tasks,
  projected_production_seconds = projected_seconds,
  projected_production_minutes = projected_seconds / 60,
  heavy_batch_threshold_minutes = 2,
  classified_heavy = projected_seconds > 120,
  authorization_disposition = ifelse(
    projected_seconds > 120,
    "STOP_FOR_AUTHOR_RUNTIME_APPROVAL",
    "BOUNDED_NOT_HEAVY_MAY_PROCEED"
  )
)

result_relative <- paste0(
  "artifacts/08_diagnostics/H06_daily/",
  "H06_daily_mder_metric010_influence_pilot_50.csv"
)
runtime_relative <- paste0(
  "artifacts/08_diagnostics/H06_daily/",
  "H06_daily_mder_metric010_influence_runtime_projection.csv"
)
readr::write_csv(results, file.path(root, result_relative), na = "")
readr::write_csv(runtime, file.path(root, runtime_relative), na = "")

manifest <- function(relative_paths, roles) {
  absolute <- file.path(root, relative_paths)
  tibble::tibble(
    relative_path = relative_paths,
    sha256 = vapply(absolute, h06d_m10_sha256, character(1)),
    bytes = unname(file.info(absolute)$size),
    role = roles,
    producer = producer,
    r_version = as.character(getRversion())
  )
}
input_relative <- c(
  frame_registry_path,
  family_model_path,
  family_verdict_path,
  frame_registry |>
    dplyr::filter(.data$run_id == "primary__near_eye__all_available") |>
    dplyr::arrange(.data$predictor_order) |>
    dplyr::pull(.data$frame_path)
)
input_manifest <- manifest(input_relative, c(
  "frame registry",
  "family pilot models",
  "family pilot verdict",
  rep("primary near-eye frame", 3L)
))
code_relative <- c(
  producer,
  "scripts/hypotheses/H06_daily/h06_daily_mder_metric010_contract.R",
  "scripts/hypotheses/H06_daily/h06_daily_mder_metric010_data.R",
  "scripts/hypotheses/H06_daily/h06_daily_mder_metric010_modeling.R"
)
code_manifest <- manifest(code_relative, c(
  "influence pilot runner",
  "METRIC-010 contract",
  "METRIC-010 data adapters",
  "production deletion-refit helper"
))
output_manifest <- manifest(
  c(result_relative, runtime_relative),
  c("50-refit influence pilot", "full influence runtime projection")
)
software_manifest <- tibble::tibble(
  component = c("R", required_packages),
  version = c(
    as.character(getRversion()),
    vapply(
      required_packages,
      function(package) as.character(utils::packageVersion(package)),
      character(1)
    )
  )
)
readr::write_csv(
  input_manifest,
  file.path(roots$manifests, "H06_daily_mder_metric010_influence_pilot_input_manifest.csv"),
  na = ""
)
readr::write_csv(
  code_manifest,
  file.path(roots$manifests, "H06_daily_mder_metric010_influence_pilot_code_manifest.csv"),
  na = ""
)
readr::write_csv(
  output_manifest,
  file.path(roots$manifests, "H06_daily_mder_metric010_influence_pilot_output_manifest.csv"),
  na = ""
)
readr::write_csv(
  software_manifest,
  file.path(roots$manifests, "H06_daily_mder_metric010_influence_pilot_software_manifest.csv"),
  na = ""
)

message(
  sprintf(
    "METRIC-010 influence pilot: 50 refits in %.2f s; projected full batch %.2f min (%s).",
    wall_seconds,
    projected_seconds / 60,
    runtime$authorization_disposition
  )
)
