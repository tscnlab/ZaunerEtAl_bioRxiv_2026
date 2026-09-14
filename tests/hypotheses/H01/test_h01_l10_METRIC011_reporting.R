# Verify the bounded H01 METRIC-011 reporting integration without refitting.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
source(file.path(root, "scripts/pipeline/paths_io.R"))
stopifnot(identical(as.character(getRversion()), "4.6.1"))

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
})

metric_id <- "l10_mean_medi"
target_runs <- c(
  "main__chest__all_available",
  "main__chest__paired_common_sample",
  "main__glasses__all_available",
  "main__glasses__paired_common_sample"
)
selected_runs <- c(
  "main__glasses__all_available",
  "main__chest__all_available"
)
integration_root <- file.path(
  root,
  "audit/hypotheses/H01/l10_METRIC-011/production_integration"
)
reporting_root <- file.path(integration_root, "reporting")

read_current <- function(path) {
  stopifnot(file.exists(path))
  readr::read_csv(path, show_col_types = FALSE, progress = FALSE)
}
verify_manifest <- function(path) {
  manifest <- read_current(path)
  files <- file.path(root, manifest$path)
  stopifnot(
    !anyDuplicated(manifest$path),
    all(file.exists(files)),
    identical(
      unname(vapply(files, artifact_sha256, character(1))),
      unname(manifest$sha256)
    )
  )
  invisible(manifest)
}
key <- function(data, columns) {
  do.call(paste, c(lapply(data[columns], as.character), sep = "::"))
}

message("Checking accepted four-target production and frozen artifact edge")
source(file.path(
  root,
  "tests/hypotheses/H01/test_h01_l10_METRIC011_production.R"
))

reporting_summary <- read_current(file.path(
  reporting_root,
  "H01_METRIC-011_reporting_integration_summary.csv"
))
stopifnot(
  nrow(reporting_summary) == 1L,
  reporting_summary$updated_primary_targets == 4L,
  reporting_summary$successful_joint_refits_per_target == 1000L,
  reporting_summary$support_changes == 0L,
  reporting_summary$diagnostic_disposition_changes == 0L,
  reporting_summary$sensitivity_disposition_changes == 0L,
  reporting_summary$claim_disposition_changes == 0L,
  reporting_summary$protected_mixed_source_files_overwritten == 0L,
  reporting_summary$status == "PASS_NO_NEW_AUTHOR_GATE"
)

message("Checking Stage 3 L10 model tests, effects, samples, and diagnostics")
canonical_tests <- read_current(file.path(
  root,
  "artifacts/09_tables/H01/H01_model_level_tests.csv"
)) |>
  filter(.data$run_id %in% selected_runs, .data$metric_id == .env$metric_id)
stage3_results <- read_current(file.path(
  root,
  "artifacts/09_tables/H01/stage3/H01_stage3_model_results.csv"
)) |>
  filter(.data$run_id %in% selected_runs, .data$metric_id == .env$metric_id)
family_map <- c(
  `H01-F1-site` = "site",
  `H01-F2-photoperiod` = "photoperiod",
  `H01-F3-latitude` = "latitude",
  `H01-F4-site-latitude-adequacy` = "adequacy"
)
for (family in names(family_map)) {
  prefix <- family_map[[family]]
  expected <- canonical_tests |>
    filter(.data$family_id == family) |>
    arrange(.data$run_id)
  observed <- stage3_results |>
    arrange(.data$run_id)
  raw_column <- if (prefix %in% c("photoperiod", "latitude")) {
    paste0(prefix, "_p_raw.x")
  } else {
    paste0(prefix, "_p_raw")
  }
  stopifnot(
    identical(observed[[raw_column]], expected$p_raw),
    identical(observed[[paste0(prefix, "_p_adjusted")]], expected$p_adjusted),
    identical(
      observed[[paste0(prefix, "_comparison_status")]],
      expected$comparison_status
    )
  )
}

canonical_effects <- read_current(file.path(
  root,
  "artifacts/09_tables/H01/H01_term_effects.csv"
)) |>
  filter(
    .data$run_id %in% selected_runs,
    .data$metric_id == .env$metric_id,
    .data$term %in% c(
      "photoperiod_centered_hours",
      "absolute_latitude_10deg_centered"
    )
  )
term_map <- c(
  photoperiod = "photoperiod_centered_hours",
  latitude = "absolute_latitude_10deg_centered"
)
for (prefix in names(term_map)) {
  term_name <- term_map[[prefix]]
  expected <- canonical_effects |>
    filter(.data$term == .env$term_name) |>
    arrange(.data$run_id)
  observed <- stage3_results |>
    arrange(.data$run_id)
  stopifnot(
    identical(
      observed[[paste0(prefix, "_estimate_practical")]],
      expected$estimate_practical
    ),
    identical(
      observed[[paste0(prefix, "_conf_low_practical")]],
      expected$conf_low_practical
    ),
    identical(
      observed[[paste0(prefix, "_conf_high_practical")]],
      expected$conf_high_practical
    )
  )
}

canonical_samples <- read_current(file.path(
  root,
  "artifacts/09_tables/H01/H01_exact_samples.csv"
)) |>
  filter(.data$run_id %in% target_runs, .data$metric_id == .env$metric_id) |>
  arrange(.data$run_id)
stage3_samples <- read_current(file.path(
  root,
  "artifacts/09_tables/H01/stage3/H01_stage3_exact_samples.csv"
)) |>
  filter(.data$run_id %in% target_runs, .data$metric_id == .env$metric_id) |>
  arrange(.data$run_id)
stopifnot(
  identical(stage3_samples$participants, canonical_samples$participants),
  identical(stage3_samples$participant_days, canonical_samples$participant_days),
  identical(stage3_samples$observations, canonical_samples$observations),
  identical(stage3_samples$sites, canonical_samples$sites)
)

current_diagnostics <- read_current(file.path(
  integration_root,
  "current_overlays/H01_model_diagnostics_current.csv"
)) |>
  filter(.data$run_id %in% selected_runs, .data$metric_id == .env$metric_id) |>
  arrange(.data$run_id)
stage3_diagnostics <- read_current(file.path(
  root,
  "artifacts/09_tables/H01/stage3/H01_stage3_diagnostic_details.csv"
)) |>
  filter(.data$run_id %in% selected_runs, .data$metric_id == .env$metric_id) |>
  arrange(.data$run_id)
stopifnot(
  identical(
    stage3_diagnostics$diagnostic_status,
    current_diagnostics$diagnostic_status
  ),
  identical(stage3_diagnostics$residual_status, current_diagnostics$residual_status),
  identical(
    stage3_diagnostics$prediction_bound_status,
    current_diagnostics$prediction_bound_status
  )
)

message("Checking production R-squared intervals and dependent tables")
canonical_r2 <- read_current(file.path(
  root,
  "artifacts/09_tables/H01/H01_r2_bootstrap_summaries.csv"
)) |>
  filter(
    .data$run_id %in% selected_runs,
    .data$metric_id == .env$metric_id,
    .data$approximation == "lognormal"
  ) |>
  arrange(.data$run_id, .data$measure)
stage3_r2 <- read_current(file.path(
  root,
  "artifacts/09_tables/H01/stage3/H01_stage3_r2.csv"
)) |>
  filter(
    .data$run_id %in% selected_runs,
    .data$metric_id == .env$metric_id,
    .data$approximation == "lognormal"
  ) |>
  arrange(.data$run_id, .data$measure)
stopifnot(
  nrow(stage3_r2) == 16L,
  all(stage3_r2$bootstrap_successful_used == 1000L),
  identical(stage3_r2$estimate, canonical_r2$estimate),
  identical(stage3_r2$conf_low, canonical_r2$conf_low),
  identical(stage3_r2$conf_high, canonical_r2$conf_high)
)
stage2_r2 <- read_current(file.path(
  root,
  "artifacts/09_tables/H01/reporting/H01_reporting_r2_preview_long.csv"
)) |>
  filter(.data$metric_id == .env$metric_id)
stopifnot(
  nrow(stage2_r2) == 8L,
  all(stage2_r2$bootstrap_successful_used == 1000L),
  all(!stage2_r2$preview_only),
  all(grepl("PRODUCTION", stage2_r2$evidence_status, fixed = TRUE))
)

message("Checking current L10 figure sources and report links")
source_root <- file.path(root, "artifacts/11_source_data/H01/stage3")
source_paths <- c(
  model_support = file.path(
    source_root,
    "H01_stage3_METRIC011_l10_mean_medi_model_support_figure_source.csv"
  ),
  site = file.path(
    source_root,
    "H01_stage3_METRIC011_l10_mean_medi_site_contrast_figure_source.csv"
  ),
  r2 = file.path(
    source_root,
    "H01_stage3_METRIC011_l10_mean_medi_r2_figure_source.csv"
  ),
  paired = file.path(
    source_root,
    "H01_stage3_METRIC011_l10_mean_medi_paired_placement_figure_source.csv"
  )
)
stopifnot(all(file.exists(source_paths)))
site_table_path <- file.path(
  root,
  "artifacts/09_tables/H01/stage3/H01_stage3_site_contrasts.csv"
)
paired_table_path <- file.path(
  root,
  "artifacts/09_tables/H01/stage3/H01_stage3_paired_placement.csv"
)
stopifnot(
  identical(artifact_sha256(source_paths[["site"]]), artifact_sha256(site_table_path)),
  identical(
    artifact_sha256(source_paths[["paired"]]),
    artifact_sha256(paired_table_path)
  )
)
r2_source <- read_current(source_paths[["r2"]])
stopifnot(
  nrow(r2_source) == 2L * 17L * 4L,
  all(r2_source$measure %in% c(
    "marginal_r2", "conditional_r2", "participant_associated_share",
    "unrepresented_share"
  )),
  all(r2_source$bootstrap_successful_used[
    r2_source$metric_id == metric_id
  ] == 1000L)
)
support_source <- read_current(source_paths[["model_support"]])
support_l10 <- support_source |>
  filter(.data$metric_id == .env$metric_id) |>
  arrange(.data$run_id, .data$family_id)
test_l10 <- canonical_tests |>
  arrange(.data$run_id, .data$family_id)
stopifnot(
  identical(support_l10$p_raw, test_l10$p_raw),
  identical(support_l10$p_adjusted, test_l10$p_adjusted)
)

qmd <- paste(readLines(
  file.path(root, "notebooks/hypotheses/H01.qmd"),
  warn = FALSE
), collapse = "\n")
for (path in basename(source_paths)) {
  stopifnot(grepl(path, qmd, fixed = TRUE))
}

message("Checking non-L10 reporting preservation and reporting manifests")
baseline <- read_current(file.path(
  integration_root,
  "H01_METRIC-011_reporting_non_l10_baseline.csv"
))
stopifnot(
  nrow(baseline) == 20L,
  any(grepl("H01_stage3", baseline$path, fixed = TRUE)),
  any(grepl("reporting", baseline$path, fixed = TRUE))
)
verify_manifest(file.path(
  root,
  "artifacts/12_manifests/H01_reporting_artifacts.csv"
))
verify_manifest(file.path(
  root,
  "artifacts/12_manifests/H01_stage3_reporting_artifacts.csv"
))
verify_manifest(file.path(
  reporting_root,
  "H01_METRIC-011_reporting_integration_manifest.csv"
))

message("H01 METRIC-011 reporting integration verification passed")
