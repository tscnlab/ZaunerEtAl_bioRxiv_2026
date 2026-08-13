#!/usr/bin/env Rscript

# Full serial deletion diagnostic for the descriptive positive-L10 component.

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
projection <- readr::read_csv(
  file.path(
    roots$diagnostics,
    "H06_daily_l10_metric011_positive_influence_runtime_projection.csv"
  ),
  show_col_types = FALSE
)
h06d_l10_assert(
  nrow(projection) == 1L &&
    !projection$classified_heavy &&
    projection$pilot_failures == 0L,
  "Full positive-L10 influence batch lacks a passed 50-refit pilot"
)
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
predictors <- h06d_l10_predictor_registry()
h06d_l10_assert(nrow(registry) == 3L && nrow(effects) == 3L, "Influence registry failed")

participant_rows <- list()
site_rows <- list()
summary_rows <- list()
started <- proc.time()[["elapsed"]]
for (index in seq_len(nrow(registry))) {
  row <- registry[index, ]
  predictor <- predictors |>
    dplyr::filter(.data$predictor_id == row$predictor_id[[1L]])
  effect <- effects |>
    dplyr::filter(.data$predictor_id == row$predictor_id[[1L]])
  frame <- readRDS(file.path(root, row$frame_path[[1L]]))
  participants <- sort(unique(as.character(frame$participant_key)))
  sites <- sort(unique(as.character(frame$site)))

  participant_result <- dplyr::bind_rows(lapply(participants, function(value) {
    h06d_l10_deletion_refit_positive(
      frame,
      predictor,
      "participant",
      value,
      effect$link_estimate[[1L]],
      effect$link_standard_error[[1L]]
    ) |>
      dplyr::mutate(
        participant_hash = substr(
          digest::digest(value, algo = "sha256"),
          1L,
          12L
        )
      ) |>
      dplyr::select(-"deletion_value")
  })) |>
    dplyr::mutate(
      predictor_order = predictor$predictor_order[[1L]],
      predictor_id = predictor$predictor_id[[1L]],
      full_link_estimate = effect$link_estimate[[1L]],
      full_link_standard_error = effect$link_standard_error[[1L]],
      .before = 1L
    )
  site_result <- dplyr::bind_rows(lapply(sites, function(value) {
    h06d_l10_deletion_refit_positive(
      frame,
      predictor,
      "site",
      value,
      effect$link_estimate[[1L]],
      effect$link_standard_error[[1L]]
    ) |>
      dplyr::rename(deleted_site = "deletion_value")
  })) |>
    dplyr::mutate(
      predictor_order = predictor$predictor_order[[1L]],
      predictor_id = predictor$predictor_id[[1L]],
      full_link_estimate = effect$link_estimate[[1L]],
      full_link_standard_error = effect$link_standard_error[[1L]],
      .before = 1L
    )
  participant_rows[[row$predictor_id[[1L]]]] <- participant_result
  site_rows[[row$predictor_id[[1L]]]] <- site_result
  maximum_participant <- participant_result |>
    dplyr::slice_max(.data$absolute_shift_in_full_se, n = 1L, with_ties = FALSE)
  maximum_site <- site_result |>
    dplyr::slice_max(.data$absolute_shift_in_full_se, n = 1L, with_ties = FALSE)
  summary_rows[[row$predictor_id[[1L]]]] <- tibble::tibble(
    predictor_order = predictor$predictor_order[[1L]],
    predictor_id = predictor$predictor_id[[1L]],
    component = "positive_magnitude",
    estimand = "association conditional on L10 > 0",
    participant_deletions = nrow(participant_result),
    participant_failures = sum(!participant_result$converged),
    maximum_participant_shift_in_full_se =
      maximum_participant$absolute_shift_in_full_se,
    maximum_participant_hash = maximum_participant$participant_hash,
    participant_direction_reversals = sum(
      participant_result$direction_reversal,
      na.rm = TRUE
    ),
    site_deletions = nrow(site_result),
    site_failures = sum(!site_result$converged),
    maximum_site_shift_in_full_se = maximum_site$absolute_shift_in_full_se,
    maximum_shift_site = maximum_site$deleted_site,
    site_direction_reversals = sum(site_result$direction_reversal, na.rm = TRUE),
    influence_disposition = dplyr::case_when(
      any(!participant_result$converged) || any(!site_result$converged) ~
        "NOT_ACCEPTABLE_REFIT_FAILURE",
      maximum_participant$absolute_shift_in_full_se > 2 ||
        maximum_site$absolute_shift_in_full_se > 2 ~
        "NOT_ACCEPTABLE_SHIFT_GT2_SE",
      maximum_participant$absolute_shift_in_full_se >= 1 ||
        maximum_site$absolute_shift_in_full_se >= 1 ||
        any(participant_result$direction_reversal) ||
        any(site_result$direction_reversal) ~
        "MAJOR_INFLUENCE_LIMITATION_NO_DIRECTIONAL_CLAIM",
      TRUE ~ "ACCEPTABLE_FOR_DESCRIPTIVE_POSITIVE_COMPONENT"
    ),
    scope_limitation = paste0(
      "does not repair the non-estimable zero-occurrence or joint two-part ",
      "association"
    )
  )
}

participant_result <- dplyr::bind_rows(participant_rows) |>
  dplyr::arrange(.data$predictor_order, .data$participant_hash)
site_result <- dplyr::bind_rows(site_rows) |>
  dplyr::arrange(.data$predictor_order, .data$deleted_site)
summary_result <- dplyr::bind_rows(summary_rows) |>
  dplyr::arrange(.data$predictor_order)
runtime <- tibble::tibble(
  refits = nrow(participant_result) + nrow(site_result),
  failures = sum(!participant_result$converged) + sum(!site_result$converged),
  elapsed_seconds = unname(proc.time()[["elapsed"]] - started),
  serial_processes = 1L,
  component = "positive_magnitude",
  occurrence_or_joint_refits = 0L
)

readr::write_csv(
  participant_result,
  file.path(
    roots$diagnostics,
    "H06_daily_l10_metric011_positive_participant_deletion_influence.csv"
  )
)
readr::write_csv(
  site_result,
  file.path(
    roots$diagnostics,
    "H06_daily_l10_metric011_positive_site_deletion_influence.csv"
  )
)
readr::write_csv(
  summary_result,
  file.path(
    roots$diagnostics,
    "H06_daily_l10_metric011_positive_influence_summary.csv"
  )
)
readr::write_csv(
  runtime,
  file.path(
    roots$diagnostics,
    "H06_daily_l10_metric011_positive_influence_runtime.csv"
  )
)
message(
  "METRIC-011 positive-component influence complete: ",
  runtime$refits,
  " serial refits in ",
  sprintf("%.2f", runtime$elapsed_seconds),
  " s."
)
