#!/usr/bin/env Rscript

# Fifty serial positive-component deletion refits. The joint L10 estimand is
# non-estimable because its occurrence component failed, so no occurrence or
# joint influence result is manufactured here.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
.libPaths(c(
  file.path(root, "renv/library/macos/R-4.6/aarch64-apple-darwin23"),
  .libPaths()
))
options(contrasts = c("contr.treatment", "contr.poly"))
required_packages <- c("digest", "dplyr", "lme4", "readr", "tibble")
stopifnot(
  identical(as.character(getRversion()), "4.6.1"),
  all(vapply(required_packages, requireNamespace, logical(1), quietly = TRUE))
)
source(file.path(root, "scripts/hypotheses/H06_daily/h06_daily_l10_metric011_contract.R"))
source(file.path(root, "scripts/hypotheses/H06_daily/h06_daily_l10_metric011_data.R"))
source(file.path(root, "scripts/hypotheses/H06_daily/h06_daily_l10_metric011_modeling.R"))

roots <- h06d_l10_artifact_roots(root)
registry <- readr::read_csv(
  file.path(roots$model_data, "H06_daily_l10_metric011_frame_registry.csv"),
  show_col_types = FALSE
) |>
  dplyr::filter(
    .data$run_id == "primary__near_eye__all_available",
    .data$component == "positive_magnitude"
  )
effects <- readr::read_csv(
  file.path(roots$tables, "H06_daily_l10_metric011_effect_estimates.csv"),
  show_col_types = FALSE
) |>
  dplyr::filter(
    .data$run_id == "primary__near_eye__all_available",
    .data$family == "Gaussian identity on log10-positive L10"
  )
h06d_l10_assert(
  nrow(registry) == 3L && nrow(effects) == 3L,
  "METRIC-011 influence pilot registry failed"
)

predictors <- h06d_l10_predictor_registry()
candidate_tasks <- list()
for (index in seq_len(nrow(registry))) {
  row <- registry[index, ]
  frame <- readRDS(file.path(root, row$frame_path[[1L]]))
  participant_values <- sort(unique(as.character(frame$participant_key)))
  participant_indices <- unique(round(seq(
    1,
    length(participant_values),
    length.out = 15L
  )))
  site_values <- sort(unique(as.character(frame$site)))
  selected_sites <- site_values[unique(round(seq(
    1,
    length(site_values),
    length.out = 2L
  )))]
  candidate_tasks[[row$predictor_id[[1L]]]] <- dplyr::bind_rows(
    tibble::tibble(
      predictor_id = row$predictor_id[[1L]],
      deletion_level = "participant",
      deletion_value = participant_values[participant_indices]
    ),
    tibble::tibble(
      predictor_id = row$predictor_id[[1L]],
      deletion_level = "site",
      deletion_value = selected_sites
    )
  )
}
tasks <- dplyr::bind_rows(candidate_tasks) |>
  dplyr::arrange(.data$predictor_id, .data$deletion_level, .data$deletion_value) |>
  dplyr::slice_head(n = 50L)
h06d_l10_assert(nrow(tasks) == 50L, "Influence pilot is not 50 refits")

started <- proc.time()[["elapsed"]]
results <- dplyr::bind_rows(lapply(seq_len(nrow(tasks)), function(index) {
  task <- tasks[index, ]
  row <- registry |>
    dplyr::filter(.data$predictor_id == task$predictor_id[[1L]])
  predictor <- predictors |>
    dplyr::filter(.data$predictor_id == task$predictor_id[[1L]])
  effect <- effects |>
    dplyr::filter(.data$predictor_id == task$predictor_id[[1L]])
  frame <- readRDS(file.path(root, row$frame_path[[1L]]))
  h06d_l10_deletion_refit_positive(
    frame = frame,
    predictor = predictor,
    deletion_level = task$deletion_level[[1L]],
    deletion_value = task$deletion_value[[1L]],
    full_link_estimate = effect$link_estimate[[1L]],
    full_link_standard_error = effect$link_standard_error[[1L]]
  ) |>
    dplyr::mutate(
      predictor_order = predictor$predictor_order[[1L]],
      predictor_id = predictor$predictor_id[[1L]],
      .before = 1L
    )
}))
wall_seconds <- unname(proc.time()[["elapsed"]] - started)
full_tasks <- sum(vapply(seq_len(nrow(registry)), function(index) {
  frame <- readRDS(file.path(root, registry$frame_path[[index]]))
  dplyr::n_distinct(frame$participant_key) + dplyr::n_distinct(frame$site)
}, numeric(1)))
median_seconds <- stats::median(results$elapsed_seconds)
projected_seconds <- median_seconds * full_tasks * 1.25
projection <- tibble::tibble(
  pilot_refits = nrow(results),
  pilot_failures = sum(!results$converged),
  pilot_wall_seconds = wall_seconds,
  median_refit_seconds = median_seconds,
  maximum_refit_seconds = max(results$elapsed_seconds),
  full_positive_component_tasks = full_tasks,
  projected_full_seconds = projected_seconds,
  projected_full_minutes = projected_seconds / 60,
  heavy_batch_threshold_minutes = 2,
  classified_heavy = projected_seconds / 60 >= 2,
  authorization_disposition = ifelse(
    projected_seconds / 60 >= 2,
    "STOP_FOR_FULL_DELETION_APPROVAL",
    "BOUNDED_NOT_HEAVY_MAY_PROCEED"
  ),
  scope = paste0(
    "strictly-positive Gaussian component only; occurrence and joint L10 ",
    "influence are not estimable and were not refitted"
  )
)
readr::write_csv(
  results |>
    dplyr::mutate(
      deletion_hash = substr(
        vapply(.data$deletion_value, digest::digest, character(1), algo = "sha256"),
        1L,
        12L
      )
    ) |>
    dplyr::select(-"deletion_value"),
  file.path(
    roots$diagnostics,
    "H06_daily_l10_metric011_positive_influence_pilot_50.csv"
  )
)
readr::write_csv(
  projection,
  file.path(
    roots$diagnostics,
    "H06_daily_l10_metric011_positive_influence_runtime_projection.csv"
  )
)
message(
  "METRIC-011 positive-component influence pilot: ",
  sprintf("%.2f", wall_seconds),
  " s; projected full ",
  sprintf("%.2f", projection$projected_full_minutes),
  " min (",
  projection$authorization_disposition,
  ")."
)
