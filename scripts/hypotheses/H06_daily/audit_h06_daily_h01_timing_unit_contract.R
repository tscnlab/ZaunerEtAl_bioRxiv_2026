#!/usr/bin/env Rscript

# Audit the stored H06_daily clock-value unit contract without modifying or
# refitting any model. This script was added after H06-D-014 hard-gate replay
# exposed missing clock-support evidence for mean timing.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
.libPaths(c(
  file.path(root, "renv/library/macos/R-4.6/aarch64-apple-darwin23"),
  .libPaths()
))

required_packages <- c("digest", "dplyr", "readr", "tibble", "tidyr")
missing_packages <- required_packages[!vapply(
  required_packages,
  requireNamespace,
  logical(1L),
  quietly = TRUE
)]
if (length(missing_packages)) {
  stop(
    sprintf("Missing synchronized packages: %s", paste(missing_packages, collapse = ", ")),
    call. = FALSE
  )
}

source(file.path(
  root,
  "scripts/hypotheses/H06_daily/h06_daily_h01_diagnostic_alignment_contract.R"
))

h06d_h01_assert(
  identical(as.character(getRversion()), "4.6.1"),
  "Timing-unit audit requires R 4.6.1; found %s",
  as.character(getRversion())
)
invisible(h06d_h01_verify_direct_inputs(root))
roots <- h06d_h01_artifact_roots(root)

timing_registry <- tibble::tribble(
  ~metric_slot, ~metric_id, ~primary_source_column,
  9L, "m10_midpoint", "m10_midpoint_clock_minute",
  10L, "l10_midpoint", "l10_midpoint_clock_minute",
  11L, "mean_timing_above_250", "mean_timing_above_250_clock_minute",
  12L, "first_timing_above_250", "first_timing_above_250_clock_minute",
  13L, "last_timing_above_250", "last_timing_above_250_clock_minute"
)
placements <- tibble::tribble(
  ~placement_id, ~position_role, ~primary_relative_path,
  "near_eye", "near_eye_primary",
  "artifacts/06_model_data/base/metrics_glasses_participant_day_enriched.rds",
  "chest", "complementary_chest",
  "artifacts/06_model_data/base/metrics_chest_participant_day_enriched.rds"
)

gap <- readRDS(file.path(
  root,
  "artifacts/06_model_data/scenarios/manuscript_prepared_data/participant_day_metrics.rds"
))
diagnostics <- readr::read_csv(
  file.path(
    roots$diagnostics,
    "H06_daily_non_l10_production_diagnostic_assessment.csv"
  ),
  show_col_types = FALSE
)
plot_index <- readr::read_csv(
  file.path(
    roots$diagnostics,
    "H06_daily_h01_visual_residual_plot_index.csv"
  ),
  show_col_types = FALSE
) |>
  dplyr::filter(.data$scope == "non_l10_stage2_production")

stored_cells <- diagnostics |>
  dplyr::filter(
    .data$dataset_id == "gap_timing_unaware",
    .data$metric_slot %in% timing_registry$metric_slot
  ) |>
  dplyr::select(
    "frame_key", "placement_id", "metric_slot", "metric_id",
    "source_minimum", "source_maximum"
  ) |>
  dplyr::left_join(
    plot_index |>
      dplyr::select(
        "frame_key", "observed_minimum", "observed_maximum",
        "fitted_minimum", "fitted_maximum"
      ),
    by = "frame_key",
    relationship = "one-to-one"
  ) |>
  dplyr::mutate(
    stored_response_is_source_divided_by_60 =
      abs(.data$observed_minimum * 60 - .data$source_minimum) < 1e-10 &
      abs(.data$observed_maximum * 60 - .data$source_maximum) < 1e-10
  )
h06d_h01_assert(
  nrow(stored_cells) == 90L &&
    all(stored_cells$stored_response_is_source_divided_by_60),
  "The expected 90-cell stored gap timing double-conversion was not reproduced"
)

audit_rows <- list()
row_index <- 0L
for (placement_row in seq_len(nrow(placements))) {
  placement <- placements[placement_row, ]
  primary <- readRDS(file.path(root, placement$primary_relative_path[[1L]]))
  h06d_h01_assert(
    all(timing_registry$primary_source_column %in% names(primary)),
    "A primary source lacks required clock-minute fields"
  )

  for (metric_row in seq_len(nrow(timing_registry))) {
    metric <- timing_registry[metric_row, ]
    primary_value <- as.numeric(primary[[metric$primary_source_column[[1L]]]])
    primary_value <- primary_value[is.finite(primary_value)]
    gap_value <- gap |>
      dplyr::filter(
        .data$position_role == placement$position_role[[1L]],
        .data$metric_id == metric$metric_id[[1L]],
        is.finite(.data$manuscript_prepared_value)
      ) |>
      dplyr::pull(.data$manuscript_prepared_value)
    cell <- stored_cells |>
      dplyr::filter(
        .data$placement_id == placement$placement_id[[1L]],
        .data$metric_id == metric$metric_id[[1L]]
      )

    primary_unit_valid <-
      length(primary_value) > 0L &&
      all(primary_value >= 0 & primary_value < 1440)
    gap_unit_valid <- if (metric$metric_id[[1L]] == "l10_midpoint") {
      length(gap_value) > 0L && all(gap_value > -12 & gap_value < 24)
    } else {
      length(gap_value) > 0L && all(gap_value >= 0 & gap_value < 24)
    }

    row_index <- row_index + 1L
    audit_rows[[row_index]] <- tibble::tibble(
      placement_id = placement$placement_id[[1L]],
      metric_slot = metric$metric_slot[[1L]],
      metric_id = metric$metric_id[[1L]],
      primary_source_column = metric$primary_source_column[[1L]],
      primary_expected_unit = "clock_minute",
      primary_finite_values = length(primary_value),
      primary_source_minimum = min(primary_value),
      primary_source_maximum = max(primary_value),
      primary_unit_contract_valid = primary_unit_valid,
      gap_expected_unit = "clock_hour",
      gap_finite_values = length(gap_value),
      gap_source_minimum = min(gap_value),
      gap_source_maximum = max(gap_value),
      gap_unit_contract_valid = gap_unit_valid,
      audited_reference_adapter =
        "h01_clock_hour_to_minute(manuscript_prepared_value)",
      h06_daily_stored_adapter =
        "clock_hours transform divides manuscript_prepared_value by 60 again",
      affected_stored_cells = nrow(cell),
      all_stored_responses_equal_gap_hours_divided_by_60 =
        all(cell$stored_response_is_source_divided_by_60),
      stored_response_minimum = min(cell$observed_minimum),
      stored_response_maximum = max(cell$observed_maximum),
      construct_gate = "FAIL_CONSTRUCT_UNIT_DOUBLE_CONVERSION",
      required_handling = paste(
        "Do not use stored gap timing estimates, p-values, or BH derivatives;",
        "a separately authorized task-owned frame/model/FDR repair is required"
      ),
      authorization = "H06-D-014",
      gate = "H06-D-G2A",
      r_version = as.character(getRversion())
    )
  }
}

unit_audit <- dplyr::bind_rows(audit_rows) |>
  dplyr::arrange(.data$metric_slot, .data$placement_id)
h06d_h01_assert(
  nrow(unit_audit) == 10L &&
    all(unit_audit$primary_unit_contract_valid) &&
    all(unit_audit$gap_unit_contract_valid) &&
    all(unit_audit$affected_stored_cells == 9L) &&
    all(unit_audit$all_stored_responses_equal_gap_hours_divided_by_60) &&
    sum(unit_audit$affected_stored_cells) == 90L,
  "The timing-unit construct audit is incomplete"
)

family_impact <- diagnostics |>
  dplyr::filter(
    .data$dataset_id == "gap_timing_unaware",
    .data$placement_id == "near_eye",
    .data$sample_role == "all_available",
    .data$metric_slot %in% timing_registry$metric_slot
  ) |>
  dplyr::distinct(
    .data$predictor_id,
    .data$association_family_id,
    .data$heterogeneity_family_id
  ) |>
  tidyr::pivot_longer(
    cols = c("association_family_id", "heterogeneity_family_id"),
    names_to = "test_type_source",
    values_to = "multiplicity_family_id"
  ) |>
  dplyr::mutate(
    test_type = dplyr::if_else(
      .data$test_type_source == "association_family_id",
      "association",
      "heterogeneity"
    ),
    multiplicity_family_id = paste0(
      "gap_timing_unaware__",
      .data$multiplicity_family_id
    ),
    invalid_timing_slots = 5L,
    family_slots = 15L,
    frozen_bh_values_must_not_be_interpreted = TRUE,
    required_handling =
      "Recompute all six gap-timing-unaware BH families only after timing repair",
    authorization = "H06-D-014",
    gate = "H06-D-G2A"
  ) |>
  dplyr::select(-"test_type_source")
h06d_h01_assert(
  nrow(family_impact) == 6L &&
    !anyDuplicated(family_impact$multiplicity_family_id),
  "The six affected gap multiplicity families were not identified"
)

h06d_h01_write_csv(
  unit_audit,
  file.path(
    roots$diagnostics,
    "H06_daily_h01_timing_unit_contract_audit.csv"
  )
)
h06d_h01_write_csv(
  family_impact,
  file.path(
    roots$diagnostics,
    "H06_daily_h01_timing_unit_family_impact.csv"
  )
)

cat(paste0(
  "H06-D-014 timing-unit audit: 90 stored gap timing cells hard-failed; ",
  "six gap BH families blocked; no model or p/FDR field changed.\n"
))
