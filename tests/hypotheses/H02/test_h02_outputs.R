# Standalone H02 fitted-output and reporting tests.

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
})

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
source(file.path(root, "scripts/pipeline/paths_io.R"))
source(file.path(root, "scripts/hypotheses/H02/h02_contract.R"))

read_output <- function(...) {
  readr::read_csv(file.path(root, ...), show_col_types = FALSE)
}

message("Testing the selected H02 model and H11 inheritance contract")
primary_path <- file.path(
  root,
  paste0(
    "artifacts/07_models/H02/",
    "main__glasses__all_available__selected_model.rds"
  )
)
manuscript_path <- file.path(
  root,
  paste0(
    "artifacts/07_models/H02/",
    "manuscript_prepared_data__glasses__all_available__",
    "selected_model.rds"
  )
)
primary <- readRDS(primary_path)
manuscript <- readRDS(manuscript_path)
primary_formula <- paste(deparse(stats::formula(primary)), collapse = " ")
manuscript_formula <- paste(
  deparse(stats::formula(manuscript)),
  collapse = " "
)
stopifnot(
  identical(primary_formula, manuscript_formula),
  grepl("bs = \"sz\"", primary_formula, fixed = TRUE),
  !grepl("site_smooth", primary_formula, fixed = TRUE),
  grepl("bs = \"cc\"", primary_formula, fixed = TRUE),
  grepl("participant_day", primary_formula, fixed = TRUE),
  primary$rank == length(stats::coef(primary))
)

spec <- read_output(
  "artifacts",
  "07_models",
  "H02",
  "selected_temporal_model_specification.csv"
)
spec_value <- stats::setNames(spec$value, spec$field)
stopifnot(
  spec_value[["selected_model_id"]] == "site_pattern",
  spec_value[["response_transform"]] == "log10(melEDI + 0.1 lx)",
  as.integer(spec_value[["overall_k"]]) == 12L,
  as.integer(spec_value[["site_pattern_k"]]) == 12L,
  as.integer(spec_value[["participant_k"]]) == 10L
)

message("Testing structure selection and the single multiplicity family")
comparisons <- read_output(
  "artifacts",
  "09_tables",
  "H02",
  "model_structure_comparisons.csv"
)
site_test <- comparisons |>
  dplyr::filter(.data$comparison_id == "site_pattern_vs_no_site")
stopifnot(
  nrow(site_test) == 1L,
  site_test$delta_AIC_reduced_minus_full >= 2,
  site_test$family_id == "H02-F1-site-pattern",
  site_test$family_n == 1L,
  site_test$adjustment_method == "BH",
  is.finite(site_test$p_raw),
  identical(site_test$p_raw, site_test$p_adjusted),
  site_test$p_raw < 0.001
)

message("Testing AR-standardized residual dependence")
acf <- read_output(
  "artifacts",
  "08_diagnostics",
  "H02",
  "residual_acf.csv"
)
primary_acf <- acf |>
  dplyr::filter(
    .data$run_id == "main__glasses__all_available",
    .data$lag_30_minute_bins == 1L
  )
preliminary <- primary_acf$correlation[
  primary_acf$stage == "preliminary_no_AR1"
]
final <- primary_acf$correlation[
  primary_acf$stage == "final_AR1_standardized"
]
stopifnot(
  length(preliminary) == 1L,
  length(final) == 1L,
  abs(final) < 0.10,
  abs(final) < abs(preliminary)
)

message("Testing extended temporal and grouping diagnostics")
constraint <- read_output(
  "artifacts",
  "08_diagnostics",
  "H02",
  "sz_constraint_identifiability.csv"
)
midnight <- read_output(
  "artifacts",
  "08_diagnostics",
  "H02",
  "midnight_continuity.csv"
)
term_dependence <- read_output(
  "artifacts",
  "08_diagnostics",
  "H02",
  "fitted_term_dependence.csv"
)
formal_concurvity <- read_output(
  "artifacts",
  "08_diagnostics",
  "H02",
  "formal_concurvity.csv"
)
cluster_acf <- read_output(
  "artifacts",
  "08_diagnostics",
  "H02",
  "cluster_residual_acf_summary.csv"
)
stopifnot(
  nrow(constraint) == 2L,
  all(constraint$sum_to_zero_constraint_verified),
  all(constraint$full_coefficient_rank),
  all(
    constraint$maximum_absolute_sum_site_deviation_eta <=
      constraint$numerical_tolerance
  ),
  nrow(midnight) > 2L,
  all(
    abs(
      midnight$midnight_value_jump_eta[
        midnight$component == "common_time_curve"
      ]
    ) <
      1e-8
  ),
  all(is.finite(term_dependence$estimate)),
  all(is.finite(formal_concurvity$.concurvity)),
  all(formal_concurvity$.concurvity >= -1e-8),
  all(formal_concurvity$.concurvity <= 1 + 1e-8),
  setequal(formal_concurvity$.type, c("worst", "observed", "estimate")),
  setequal(
    cluster_acf$cluster_level,
    c("participant", "participant_day", "AR_sequence")
  ),
  nrow(cluster_acf) == 6L,
  all(cluster_acf$stage == "final_AR1_standardized"),
  all(cluster_acf$eligible_pairs > 0L)
)
temporal_diagnostic_manifest <- read_output(
  "artifacts",
  "12_manifests",
  "H02",
  "H02_temporal_diagnostics_manifest.csv"
)
stopifnot(nrow(temporal_diagnostic_manifest) == 6L)
for (i in seq_len(nrow(temporal_diagnostic_manifest))) {
  path <- file.path(root, temporal_diagnostic_manifest$path[i])
  stopifnot(
    file.exists(path),
    identical(
      artifact_sha256(path),
      temporal_diagnostic_manifest$sha256[i]
    )
  )
}

message("Testing fitted-variation intervals and data sensitivity")
variation <- read_output(
  "artifacts",
  "09_tables",
  "H02",
  "variation_summary.csv"
)
stopifnot(
  all(is.finite(variation$estimate)),
  all(is.finite(variation$lower_95)),
  all(is.finite(variation$upper_95)),
  all(variation$lower_95 <= variation$estimate),
  all(variation$estimate <= variation$upper_95),
  all(grepl(
    "conditional on fitted smoothing structure",
    variation$confidence_interval_method,
    fixed = TRUE
  ))
)
primary_ratio <- variation |>
  dplyr::filter(
    .data$run_id == "main__glasses__all_available",
    .data$summary_id == "participant_plus_day_to_site_ratio"
  )
stopifnot(
  nrow(primary_ratio) == 1L,
  primary_ratio$estimate > 1,
  primary_ratio$lower_95 > 1
)
stability <- read_output(
  "artifacts",
  "09_tables",
  "H02",
  "manuscript_prepared_stability.csv"
)
stopifnot(
  nrow(stability) == 6L,
  all(stability$stability_classification == "stable")
)

message("Testing the submitted-versus-current sample comparison")
submitted_comparison <- read_output(
  "artifacts",
  "09_tables",
  "H02",
  "submitted_implementation_comparison.csv"
)
sample_counts <- read_output(
  "artifacts",
  "06_model_data",
  "H02",
  "sample_counts.csv"
) |>
  dplyr::filter(
    .data$site == "ALL_SITES",
    .data$run_id %in%
      c(
        "main__glasses__all_available",
        "main__chest__all_available"
      )
  ) |>
  dplyr::mutate(
    placement = dplyr::if_else(
      grepl("__glasses__", .data$run_id, fixed = TRUE),
      "glasses",
      "chest"
    )
  )
for (placement_id in c("glasses", "chest")) {
  current <- sample_counts |>
    dplyr::filter(.data$placement == placement_id)
  comparison <- submitted_comparison |>
    dplyr::filter(.data$placement == placement_id)
  stopifnot(
    comparison$new_H02_value[
      comparison$comparison_item == "participants"
    ] ==
      current$participants,
    comparison$new_H02_value[
      comparison$comparison_item == "fitted_30_minute_observations"
    ] ==
      current$observations_30_minute
  )
}
submitted_recovery <- read_output(
  "audit",
  "hypotheses",
  "H02",
  "submitted_recovery.csv"
)
for (placement_id in c("glasses", "chest")) {
  for (item_id in c(
    "fitted_30_minute_observations",
    "participants",
    "site_term_share",
    "participant_term_share",
    "selected_fREML_model_AIC"
  )) {
    recovered_value <- submitted_recovery |>
      dplyr::filter(
        .data$placement == placement_id,
        .data$recovery_item == item_id
      ) |>
      dplyr::pull("recovered_value")
    comparison_value <- submitted_comparison |>
      dplyr::filter(
        .data$placement == placement_id,
        .data$comparison_item == item_id
      ) |>
      dplyr::pull("submitted_value")
    stopifnot(
      length(recovered_value) == 1L,
      length(comparison_value) == 1L,
      isTRUE(all.equal(recovered_value, comparison_value))
    )
  }
}

message("Testing simultaneous time-window claims")
windows <- read_output(
  "artifacts",
  "09_tables",
  "H02",
  "simultaneous_site_windows.csv"
) |>
  dplyr::filter(
    .data$run_id == "main__glasses__all_available",
    .data$direction != "no_simultaneous_difference"
  )
stopifnot(
  identical(
    sort(unique(windows$site)),
    sort(c("BAUA", "FUSPCEU", "KNUST", "RISE", "TUM"))
  ),
  nrow(windows) == 6L,
  all(
    windows$minimum_simultaneous_lower > 1 |
      windows$maximum_simultaneous_upper < 1
  )
)
site_claims <- read_output(
  "artifacts",
  "09_tables",
  "H02",
  "submitted_site_claim_comparison.csv"
)
expected_classification <- c(
  BAUA = "partly retained: evening increase only",
  FUSPCEU = "retained qualitatively with narrower simultaneous windows",
  IZTECH = "not retained with simultaneous intervals",
  KNUST = "partly retained: afternoon/evening reduction only",
  MPI = "retained",
  RISE = "partly retained: morning increase only",
  THUAS = "retained",
  TUM = "partly retained: evening increase only",
  UCR = "retained"
)
observed_classification <- stats::setNames(
  site_claims$comparison_classification,
  site_claims$site
)
stopifnot(
  identical(
    observed_classification[names(expected_classification)],
    expected_classification
  )
)

message("Testing the restricted cyclic model-form sensitivity")
formula_comparison <- read_output(
  "artifacts",
  "09_tables",
  "H02",
  "formula_sensitivity_comparison.csv"
)
formula_models <- read_output(
  "artifacts",
  "09_tables",
  "H02",
  "formula_sensitivity_model_fit_summary.csv"
)
stopifnot(
  nrow(formula_comparison) == 12L,
  nrow(formula_models) == 2L,
  setequal(
    formula_comparison$data_scenario_id,
    c("main", "manuscript_prepared_data")
  ),
  all(formula_comparison$stability_classification == "stable"),
  all(grepl("__glasses__all_available", formula_models$run_id)),
  !any(grepl("chest|paired", formula_models$run_id))
)
formula_manifest <- read_output(
  "artifacts",
  "12_manifests",
  "H02",
  "H02_formula_sensitivity_manifest.csv"
)
stopifnot(nrow(formula_manifest) >= 13L)
for (i in seq_len(nrow(formula_manifest))) {
  path <- file.path(root, formula_manifest$path[i])
  stopifnot(
    file.exists(path),
    identical(artifact_sha256(path), formula_manifest$sha256[i])
  )
}

message("Testing main-only conditional Shapley dominance outputs")
dominance_runs <- c(
  "main__glasses__all_available",
  "main__chest__all_available"
)
dominance_inputs <- read_output(
  "artifacts",
  "09_tables",
  "H02",
  "dominance_run_inputs.csv"
)
dominance_models <- read_output(
  "artifacts",
  "09_tables",
  "H02",
  "dominance_subset_models.csv"
)
dominance_summary <- read_output(
  "artifacts",
  "09_tables",
  "H02",
  "dominance_summary.csv"
)
dominance_comparison <- read_output(
  "artifacts",
  "09_tables",
  "H02",
  "dominance_comparison_summary.csv"
)
stopifnot(
  setequal(dominance_inputs$run_id, dominance_runs),
  setequal(dominance_models$run_id, dominance_runs),
  setequal(dominance_summary$run_id, dominance_runs),
  setequal(dominance_comparison$run_id, dominance_runs),
  nrow(dominance_inputs) == 2L,
  nrow(dominance_models) == 16L,
  nrow(dominance_summary) == 8L,
  nrow(dominance_comparison) == 8L,
  all(dominance_inputs$subset_models == 8L),
  all(dominance_summary$bootstrap_replicates == 2000L),
  all(dominance_comparison$bootstrap_replicates == 2000L),
  all(
    dominance_summary$finite_bootstrap_replicates_allocated_R2 == 2000L
  ),
  all(
    dominance_summary$finite_bootstrap_replicates_share_full == 2000L
  ),
  all(
    dominance_comparison$finite_bootstrap_replicates >= 1900L
  ),
  all(is.na(dominance_summary$multiplicity_family)),
  all(is.na(dominance_comparison$multiplicity_family)),
  !any(grepl(
    "manuscript_prepared|paired_common|sensitivity",
    c(
      dominance_inputs$run_id,
      dominance_models$run_id,
      dominance_summary$run_id,
      dominance_comparison$run_id
    )
  ))
)
for (run_id in dominance_runs) {
  allocation <- dominance_summary |>
    dplyr::filter(.data$run_id == .env$run_id)
  comparisons <- dominance_comparison |>
    dplyr::filter(.data$run_id == .env$run_id)
  counts <- sample_counts |>
    dplyr::filter(
      .data$run_id == .env$run_id,
      .data$site == "ALL_SITES"
    )
  stopifnot(
    nrow(allocation) == 4L,
    nrow(comparisons) == 4L,
    setequal(
      allocation$component,
      c(
        "common_time",
        "site_pattern",
        "participant_pattern",
        "participant_day"
      )
    ),
    isTRUE(all.equal(
      sum(allocation$allocated_R2),
      allocation$full_model_R2[1L],
      tolerance = 1e-10
    )),
    isTRUE(all.equal(
      sum(allocation$share_of_full_model_R2),
      1,
      tolerance = 1e-10
    )),
    all(is.finite(allocation$allocated_R2)),
    all(is.finite(allocation$allocated_R2_lower_95)),
    all(is.finite(allocation$allocated_R2_upper_95)),
    all(is.finite(allocation$share_of_full_model_R2)),
    all(is.finite(comparisons$estimate)),
    all(is.finite(comparisons$lower_95)),
    all(is.finite(comparisons$upper_95)),
    all(allocation$participants == counts$participants),
    all(allocation$participant_days == counts$participant_days),
    all(
      allocation$observations_30_minute == counts$observations_30_minute
    ),
    all(allocation$sites == counts$sites)
  )
}
dominance_manifest <- read_output(
  "artifacts",
  "12_manifests",
  "H02",
  "H02_dominance_manifest.csv"
)
stopifnot(nrow(dominance_manifest) >= 11L)
for (i in seq_len(nrow(dominance_manifest))) {
  path <- file.path(root, dominance_manifest$path[i])
  stopifnot(
    file.exists(path),
    identical(artifact_sha256(path), dominance_manifest$sha256[i])
  )
}

message("Testing the output manifest")
manifest <- read_output(
  "artifacts",
  "12_manifests",
  "H02",
  "H02_analysis_manifest.csv"
)
stopifnot(nrow(manifest) >= 49L)
for (i in seq_len(nrow(manifest))) {
  path <- file.path(root, manifest$path[i])
  stopifnot(
    file.exists(path),
    identical(artifact_sha256(path), manifest$sha256[i])
  )
}

message("All H02 fitted-output tests passed")
