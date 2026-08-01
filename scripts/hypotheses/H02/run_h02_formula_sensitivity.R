#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(dplyr)
  library(mgcv)
  library(readr)
  library(tibble)
  library(tidyr)
})

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
source(file.path(root, "scripts/pipeline/paths_io.R"))
source(file.path(root, "scripts/pipeline/assertions.R"))
source(file.path(root, "scripts/hypotheses/H02/h02_contract.R"))
source(file.path(root, "scripts/hypotheses/H02/h02_modeling.R"))

if (getRversion() != "4.6.1") {
  h02_abort("H02 requires R 4.6.1; running %s", getRversion())
}

# Apply the identical approved shared-input contract before fitting either
# declared near-eye model-form sensitivity.
input_audit <- h02_validate_inputs(root)

paths <- pipeline_paths(root)
producer <- "scripts/hypotheses/H02/run_h02_formula_sensitivity.R"
directories <- file.path(
  c(
    paths$models,
    paths$diagnostics,
    paths$tables,
    paths$source_data,
    paths$manifests
  ),
  "H02"
)
invisible(vapply(
  directories,
  dir.create,
  logical(1),
  recursive = TRUE,
  showWarnings = FALSE
))

artifact_metadata <- list()
record_metadata <- function(metadata, id) {
  artifact_metadata[[id]] <<- metadata
  invisible(metadata)
}
write_h02_csv <- function(data, path, id) {
  record_metadata(write_csv_artifact(data, path, producer), id)
}
write_h02_rds <- function(object, path, id, metadata = list()) {
  record_metadata(
    write_rds_artifact(object, path, producer, metadata),
    id
  )
}

formula_id <- "cyclic_ordered_sensitivity"
scenarios <- tibble::tribble(
  ~data_scenario_id,
  ~base_run_id,
  "main",
  "main__glasses__all_available",
  "manuscript_prepared_data",
  "manuscript_prepared_data__glasses__all_available"
) |>
  dplyr::mutate(
    sensitivity_run_id = paste0(
      .data$base_run_id,
      "__",
      formula_id
    )
  )

model_tables <- list()
variation_tables <- list()
residual_acf_tables <- list()
residual_summary_tables <- list()
k_check_tables <- list()
site_prediction_tables <- list()

for (i in seq_len(nrow(scenarios))) {
  scenario <- scenarios[i, ]
  message(
    "Fitting H02 formula sensitivity ",
    i,
    "/",
    nrow(scenarios),
    ": ",
    scenario$sensitivity_run_id
  )
  frame <- readRDS(file.path(
    paths$model_data,
    "H02",
    paste0(scenario$base_run_id, ".rds")
  ))
  fitted <- h02_fit_selected_run(
    frame,
    scenario$sensitivity_run_id,
    formula_id
  )
  predictions <- h02_site_predictions(
    fitted$final,
    fitted$data,
    scenario$sensitivity_run_id
  )
  variation <- h02_variation_summary(
    fitted$final,
    fitted$data,
    predictions,
    scenario$sensitivity_run_id
  )

  model_tables[[scenario$sensitivity_run_id]] <- fitted$model_table |>
    dplyr::mutate(
      data_scenario_id = scenario$data_scenario_id,
      formula_role = "model-form sensitivity",
      .before = 1L
    )
  variation_tables[[scenario$sensitivity_run_id]] <- variation$summary |>
    dplyr::mutate(
      data_scenario_id = scenario$data_scenario_id,
      formula_role = "model-form sensitivity",
      .before = 1L
    )
  residual_acf_tables[[scenario$sensitivity_run_id]] <- dplyr::bind_rows(
    h02_residual_acf(
      fitted$preliminary,
      fitted$data,
      "preliminary_no_AR1",
      scenario$sensitivity_run_id
    ),
    h02_residual_acf(
      fitted$final,
      fitted$data,
      "final_AR1_standardized",
      scenario$sensitivity_run_id
    )
  ) |>
    dplyr::mutate(
      data_scenario_id = scenario$data_scenario_id,
      .before = 1L
    )
  residual_summary_tables[[scenario$sensitivity_run_id]] <-
    h02_residual_summary(
      fitted$final,
      fitted$data,
      scenario$sensitivity_run_id
    ) |>
    dplyr::mutate(
      data_scenario_id = scenario$data_scenario_id,
      .before = 1L
    )
  k_check_tables[[scenario$sensitivity_run_id]] <- h02_k_check(
    fitted$final,
    scenario$sensitivity_run_id
  ) |>
    dplyr::mutate(
      data_scenario_id = scenario$data_scenario_id,
      .before = 1L
    )
  site_prediction_tables[[scenario$sensitivity_run_id]] <- predictions |>
    dplyr::mutate(
      data_scenario_id = scenario$data_scenario_id,
      .before = 1L
    )

  write_h02_rds(
    fitted$final,
    file.path(
      paths$models,
      "H02",
      paste0(scenario$sensitivity_run_id, "__selected_model.rds")
    ),
    paste0(scenario$sensitivity_run_id, "__model"),
    metadata = list(
      base_run_id = scenario$base_run_id,
      formula_id = formula_id,
      rho = fitted$rho,
      participants = dplyr::n_distinct(fitted$data$participant),
      participant_days = dplyr::n_distinct(fitted$data$participant_day),
      observations = nrow(fitted$data),
      sites = dplyr::n_distinct(fitted$data$site)
    )
  )
  write_h02_rds(
    variation$contributions,
    file.path(
      paths$source_data,
      "H02",
      paste0(scenario$sensitivity_run_id, "__fitted_contributions.rds")
    ),
    paste0(scenario$sensitivity_run_id, "__contributions")
  )
  write_h02_rds(
    variation$bootstrap,
    file.path(
      paths$diagnostics,
      "H02",
      paste0(scenario$sensitivity_run_id, "__variation_bootstrap.rds")
    ),
    paste0(scenario$sensitivity_run_id, "__variation_bootstrap")
  )
  rm(frame, fitted, predictions, variation)
  invisible(gc())
}

model_summary <- dplyr::bind_rows(model_tables)
variation_summary <- dplyr::bind_rows(variation_tables)
residual_acf <- dplyr::bind_rows(residual_acf_tables)
residual_summary <- dplyr::bind_rows(residual_summary_tables)
k_check <- dplyr::bind_rows(k_check_tables)
site_predictions <- dplyr::bind_rows(site_prediction_tables)

primary_variation <- readr::read_csv(
  file.path(paths$tables, "H02", "variation_summary.csv"),
  show_col_types = FALSE
) |>
  dplyr::filter(.data$run_id %in% scenarios$base_run_id) |>
  dplyr::inner_join(
    scenarios |>
      dplyr::select("data_scenario_id", "base_run_id"),
    by = c("run_id" = "base_run_id"),
    relationship = "many-to-one"
  )

comparison <- dplyr::inner_join(
  primary_variation |>
    dplyr::transmute(
      data_scenario_id = .data$data_scenario_id,
      summary_id = .data$summary_id,
      primary_sz_estimate = .data$estimate,
      primary_sz_lower_95 = .data$lower_95,
      primary_sz_upper_95 = .data$upper_95
    ),
  variation_summary |>
    dplyr::transmute(
      data_scenario_id = .data$data_scenario_id,
      summary_id = .data$summary_id,
      cyclic_sensitivity_estimate = .data$estimate,
      cyclic_sensitivity_lower_95 = .data$lower_95,
      cyclic_sensitivity_upper_95 = .data$upper_95
    ),
  by = c("data_scenario_id", "summary_id"),
  relationship = "one-to-one"
) |>
  dplyr::mutate(
    relative_change = (.data$cyclic_sensitivity_estimate -
      .data$primary_sz_estimate) /
      .data$primary_sz_estimate,
    confidence_intervals_overlap = pmax(
      .data$primary_sz_lower_95,
      .data$cyclic_sensitivity_lower_95
    ) <=
      pmin(
        .data$primary_sz_upper_95,
        .data$cyclic_sensitivity_upper_95
      ),
    ratio_summary = grepl("ratio$", .data$summary_id),
    primary_relation_to_one = dplyr::case_when(
      !.data$ratio_summary ~ "not_applicable",
      .data$primary_sz_lower_95 > 1 ~ "above_one",
      .data$primary_sz_upper_95 < 1 ~ "below_one",
      TRUE ~ "includes_one"
    ),
    sensitivity_relation_to_one = dplyr::case_when(
      !.data$ratio_summary ~ "not_applicable",
      .data$cyclic_sensitivity_lower_95 > 1 ~ "above_one",
      .data$cyclic_sensitivity_upper_95 < 1 ~ "below_one",
      TRUE ~ "includes_one"
    ),
    stability_classification = dplyr::case_when(
      .data$ratio_summary &
        sign(.data$primary_sz_estimate - 1) !=
          sign(.data$cyclic_sensitivity_estimate - 1) ~
        "unstable",
      .data$ratio_summary &
        .data$primary_relation_to_one != .data$sensitivity_relation_to_one ~
        "inference-sensitive",
      abs(.data$relative_change) <= 0.20 &
        .data$confidence_intervals_overlap ~
        "stable",
      abs(.data$relative_change) <= 0.50 &
        .data$confidence_intervals_overlap ~
        "directionally stable",
      TRUE ~ "magnitude-sensitive"
    ),
    scenario_change = paste(
      "Only the model formula and associated basis dimensions changed:",
      "primary overall cc(k=12) + site sz(k=12) + participant fs(k=10)",
      "versus cyclic sensitivity with parametric site + overall cc(k=12) +",
      "ordered-factor site cc(k=12,id=1) + participant fs(cc,k=8);",
      "data, transform, rho algorithm, AR boundaries, summaries, and",
      "conditional interval algorithm were identical."
    )
  )

tables <- list(
  formula_sensitivity_model_fit_summary = model_summary,
  formula_sensitivity_variation_summary = variation_summary,
  formula_sensitivity_comparison = comparison,
  formula_sensitivity_residual_acf = residual_acf,
  formula_sensitivity_residual_summary = residual_summary,
  formula_sensitivity_basis_dimension_checks = k_check
)
table_locations <- c(
  formula_sensitivity_model_fit_summary = file.path(
    paths$tables,
    "H02",
    "formula_sensitivity_model_fit_summary.csv"
  ),
  formula_sensitivity_variation_summary = file.path(
    paths$tables,
    "H02",
    "formula_sensitivity_variation_summary.csv"
  ),
  formula_sensitivity_comparison = file.path(
    paths$tables,
    "H02",
    "formula_sensitivity_comparison.csv"
  ),
  formula_sensitivity_residual_acf = file.path(
    paths$diagnostics,
    "H02",
    "formula_sensitivity_residual_acf.csv"
  ),
  formula_sensitivity_residual_summary = file.path(
    paths$diagnostics,
    "H02",
    "formula_sensitivity_residual_summary.csv"
  ),
  formula_sensitivity_basis_dimension_checks = file.path(
    paths$diagnostics,
    "H02",
    "formula_sensitivity_basis_dimension_checks.csv"
  )
)
for (name in names(tables)) {
  write_h02_csv(
    tables[[name]],
    table_locations[[name]],
    paste0("table__", name)
  )
}
write_h02_csv(
  site_predictions,
  file.path(
    paths$source_data,
    "H02",
    "formula_sensitivity_site_curve_predictions.csv"
  ),
  "source__formula_sensitivity_site_curve_predictions"
)

manifest <- dplyr::bind_rows(lapply(artifact_metadata, manifest_row)) |>
  dplyr::mutate(
    path = sub(
      paste0(
        "^",
        gsub("([][{}()+*^$|\\\\?.])", "\\\\\\1", root),
        "/"
      ),
      "",
      .data$path
    )
  )
write_csv_artifact(
  manifest,
  file.path(
    paths$manifests,
    "H02",
    "H02_formula_sensitivity_manifest.csv"
  ),
  producer
)

message(
  "Completed H02 cyclic ordered-factor formula sensitivity for ",
  nrow(scenarios),
  " near-eye scenarios"
)
