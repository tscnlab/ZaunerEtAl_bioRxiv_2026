#!/usr/bin/env Rscript

# Compare the post-METRIC-010 multiplicity fields with the preserved
# pre-amendment H10 website copies. This script reads stored tables only; it
# does not fit a model or recalculate any scientific estimate.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
project_library <- file.path(
  root,
  "renv/library/macos/R-4.6/aarch64-apple-darwin23"
)
if (!dir.exists(project_library)) {
  stop("The authoritative R 4.6 project library is unavailable", call. = FALSE)
}
.libPaths(c(project_library, .libPaths()))

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop(
    sprintf(
      "H10 multiplicity audit requires R 4.6.1; found %s",
      as.character(getRversion())
    ),
    call. = FALSE
  )
}

required_packages <- c("dplyr", "readr", "tibble")
missing_packages <- required_packages[!vapply(
  required_packages,
  requireNamespace,
  logical(1),
  quietly = TRUE
)]
if (length(missing_packages) > 0L) {
  stop(
    sprintf(
      "Missing project package(s): %s",
      paste(missing_packages, collapse = ", ")
    ),
    call. = FALSE
  )
}

source(file.path(root, "scripts/pipeline/paths_io.R"))

old_mder_ids <- c(
  "mder_ratio_of_integrals",
  "mder_mean_of_viable_ratios"
)
comparison_tolerance <- 0

artifact_pairs <- tibble::tribble(
  ~artifact_component, ~current_path, ~previous_path,
  "primary_main_effects",
  "artifacts/09_tables/H10/H10_primary_main_results.csv",
  "_build/nathealth/artifacts/09_tables/H10/H10_primary_main_results.csv",
  "primary_interactions",
  "artifacts/09_tables/H10/H10_primary_interaction_results.csv",
  "_build/nathealth/artifacts/09_tables/H10/H10_primary_interaction_results.csv",
  "paired_placement",
  "artifacts/08_diagnostics/H10/sensitivity/H10_paired_placement_main_effects.csv",
  "_build/nathealth/artifacts/08_diagnostics/H10/sensitivity/H10_paired_placement_main_effects.csv",
  "primary_gap_common",
  "artifacts/08_diagnostics/H10/sensitivity/H10_primary_gap_common_sample_effects.csv",
  "_build/nathealth/artifacts/08_diagnostics/H10/sensitivity/H10_primary_gap_common_sample_effects.csv",
  "preregistered_exclusion",
  "artifacts/08_diagnostics/H10/sensitivity/H10_preregistered_exclusion_effects.csv",
  "_build/nathealth/artifacts/08_diagnostics/H10/sensitivity/H10_preregistered_exclusion_effects.csv"
)

stable_key_candidates <- c(
  "data_scenario", "placement", "sample_scenario", "metric_id",
  "predictor", "comparison_id", "site"
)

compare_pair <- function(artifact_component, current_path, previous_path) {
  current <- readr::read_csv(
    file.path(root, current_path),
    show_col_types = FALSE
  ) |>
    dplyr::filter(!.data$metric_id %in% old_mder_ids)
  previous <- readr::read_csv(
    file.path(root, previous_path),
    show_col_types = FALSE
  ) |>
    dplyr::filter(!.data$metric_id %in% old_mder_ids)

  keys <- stable_key_candidates[
    stable_key_candidates %in% names(current) &
      stable_key_candidates %in% names(previous)
  ]
  if (length(keys) == 0L) {
    stop(sprintf("No stable comparison key for %s", artifact_component))
  }
  if (anyDuplicated(current[keys]) || anyDuplicated(previous[keys])) {
    stop(sprintf("Non-unique comparison key for %s", artifact_component))
  }

  compared <- current |>
    dplyr::select(
      dplyr::all_of(keys),
      "p_adjusted",
      "adjusted_significant"
    ) |>
    dplyr::rename(
      p_adjusted_current = "p_adjusted",
      adjusted_significant_current = "adjusted_significant"
    ) |>
    dplyr::inner_join(
      previous |>
        dplyr::select(
          dplyr::all_of(keys),
          "p_adjusted",
          "adjusted_significant"
        ) |>
        dplyr::rename(
          p_adjusted_previous = "p_adjusted",
          adjusted_significant_previous = "adjusted_significant"
        ),
      by = keys
    )

  if (nrow(compared) != nrow(current) || nrow(compared) != nrow(previous)) {
    stop(sprintf("Incomplete pre/post match for %s", artifact_component))
  }

  p_change <- abs(
    compared$p_adjusted_current - compared$p_adjusted_previous
  )
  decision_change <-
    compared$adjusted_significant_current !=
    compared$adjusted_significant_previous

  tibble::tibble(
    artifact_component = artifact_component,
    previous_snapshot_available = TRUE,
    non_mder_rows = nrow(compared),
    changed_adjusted_p_rows = sum(
      is.finite(p_change) & p_change > comparison_tolerance
    ),
    maximum_absolute_change = max(p_change, na.rm = TRUE),
    changed_adjusted_decision_rows = sum(decision_change, na.rm = TRUE),
    comparison_tolerance = comparison_tolerance,
    previous_snapshot_source = previous_path,
    interpretation = paste0(
      "The MDER slot changed the BH ordering for some non-MDER adjusted ",
      "p-values; raw non-MDER outputs were identity-guarded. No non-MDER ",
      "adjusted significance decision changed."
    )
  )
}

audited <- dplyr::bind_rows(lapply(
  seq_len(nrow(artifact_pairs)),
  function(index) {
    compare_pair(
      artifact_pairs$artifact_component[[index]],
      artifact_pairs$current_path[[index]],
      artifact_pairs$previous_path[[index]]
    )
  }
))

unavailable <- tibble::tibble(
  artifact_component = c("all_available_gap", "leave_one_site_out"),
  previous_snapshot_available = FALSE,
  non_mder_rows = c(64L, 576L),
  changed_adjusted_p_rows = NA_integer_,
  maximum_absolute_change = NA_real_,
  changed_adjusted_decision_rows = NA_integer_,
  comparison_tolerance = comparison_tolerance,
  previous_snapshot_source = NA_character_,
  interpretation = paste0(
    "No row-level pre-amendment snapshot remains for this component. ",
    "Current adjusted p-values were recomputed for the complete approved ",
    "family, while raw non-MDER outputs were identity-guarded; no ",
    "row-change count is claimed."
  )
)

result <- dplyr::bind_rows(audited, unavailable)
expected_counts <- c(
  primary_main_effects = 30L,
  primary_interactions = 43L,
  paired_placement = 27L,
  primary_gap_common = 44L,
  preregistered_exclusion = 29L
)
observed_counts <- stats::setNames(
  audited$changed_adjusted_p_rows,
  audited$artifact_component
)
if (!identical(observed_counts[names(expected_counts)], expected_counts)) {
  stop(
    sprintf(
      "Recovered H10 multiplicity-change counts differ: %s",
      paste(
        sprintf(
          "%s=%s",
          names(observed_counts),
          observed_counts
        ),
        collapse = ", "
      )
    )
  )
}
if (any(audited$changed_adjusted_decision_rows != 0L)) {
  stop("A non-MDER adjusted significance decision changed unexpectedly")
}

output_path <- file.path(
  root,
  "artifacts/12_manifests/H10/H10_METRIC010_multiplicity_change_audit.csv"
)
write_csv_artifact(
  result,
  output_path,
  producer = "scripts/hypotheses/H10/audit_h10_metric010_multiplicity_changes.R"
)

message("H10 METRIC-010 multiplicity-change audit complete")
