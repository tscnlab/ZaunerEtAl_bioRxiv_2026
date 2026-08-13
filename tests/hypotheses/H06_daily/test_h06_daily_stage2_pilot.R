# Focused, no-refit verification of the H06-daily Stage 2 bounded pilot.

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

library(dplyr)
library(readr)

source(file.path(
  root,
  "scripts/hypotheses/H06_daily/h06_daily_contract.R"
))
source(file.path(
  root,
  "scripts/hypotheses/H06_daily/h06_daily_data.R"
))

stopifnot(
  identical(as.character(getRversion()), "4.6.1"),
  identical(as.character(packageVersion("melidosData")), "1.0.6")
)

roots <- h06d_artifact_roots(root)
read_h06d <- function(stage, file) {
  readr::read_csv(
    file.path(root, "artifacts", stage, "H06_daily", file),
    show_col_types = FALSE,
    na = ""
  )
}

input_manifest <- read_h06d(
  "12_manifests",
  "H06_daily_stage2_pilot_input_manifest.csv"
)
output_manifest <- read_h06d(
  "12_manifests",
  "H06_daily_stage2_pilot_output_manifest.csv"
)
code_manifest <- read_h06d(
  "12_manifests",
  "H06_daily_stage2_pilot_code_manifest.csv"
)
report_manifest <- readr::read_csv(
  file.path(
    root,
    "audit/hypotheses/H06_daily/H06_daily_stage2_pilot_report_manifest.csv"
  ),
  show_col_types = FALSE
)

hash_files <- function(paths) {
  unname(vapply(
    file.path(root, paths),
    digest::digest,
    character(1),
    algo = "sha256",
    file = TRUE
  ))
}

stopifnot(
  identical(hash_files(input_manifest$relative_path), input_manifest$sha256),
  identical(hash_files(output_manifest$relative_path), output_manifest$sha256),
  identical(hash_files(code_manifest$relative_path), code_manifest$sha256),
  identical(hash_files(report_manifest$relative_path), report_manifest$sha256),
  identical(
    unname(file.info(file.path(root, report_manifest$relative_path))$size),
    report_manifest$size_bytes
  )
)

diaries <- h06d_load_diaries(root)
near_temporal <- h06d_temporal_frame(
  root,
  placement = "near_eye",
  positive_only = FALSE,
  diaries = diaries
)
near_positive <- h06d_temporal_frame(
  root,
  placement = "near_eye",
  positive_only = TRUE,
  diaries = diaries
)

stopifnot(
  nrow(near_temporal) == 33057L,
  dplyr::n_distinct(near_temporal$participant_day) == 715L,
  dplyr::n_distinct(near_temporal$participant) == 137L,
  dplyr::n_distinct(near_temporal$site) == 9L,
  sum(near_temporal$geometric_mean_medi_lx == 0) == 10225L,
  nrow(near_positive) == 22832L,
  sum(near_temporal$AR_start) == 1217L,
  sum(near_positive$AR_start) == 1604L,
  all(near_temporal$elapsed_from_previous_seconds[!near_temporal$AR_start] == 0),
  all(near_positive$elapsed_from_previous_seconds[!near_positive$AR_start] == 0)
)

formula_registry <- read_h06d(
  "06_model_data",
  "H06_daily_30_minute_temporal_formula_registry.csv"
)
stopifnot(
  nrow(formula_registry) == 3L,
  all(grepl("s(time_hour, bs = \"cc\", k = 12)", formula_registry$formula, fixed = TRUE)),
  all(grepl("previous_sleep_duration_centered_h", formula_registry$formula, fixed = TRUE)),
  all(grepl("s(participant_day, bs = \"re\")", formula_registry$formula, fixed = TRUE))
)

temporal_checkpoint <- readRDS(file.path(
  roots$models,
  "H06_daily_30_minute_temporal_family_pilot.rds"
))
stopifnot(
  inherits(temporal_checkpoint$one_part$model, "bam"),
  inherits(temporal_checkpoint$occurrence$model, "bam"),
  inherits(temporal_checkpoint$positive$model, "bam"),
  abs(temporal_checkpoint$one_part$tweedie_power - 1.75456727398341) < 1e-10,
  abs(temporal_checkpoint$one_part$rho - 0.3053) < 0.001,
  abs(temporal_checkpoint$occurrence$rho - 0.2608) < 0.001,
  abs(temporal_checkpoint$positive$rho - 0.3081) < 0.001
)

component <- read_h06d(
  "08_diagnostics",
  "H06_daily_30_minute_temporal_component_diagnostics.csv"
)
closure <- read_h06d(
  "08_diagnostics",
  "H06_daily_30_minute_temporal_cyclic_closure.csv"
)
site_acf <- read_h06d(
  "08_diagnostics",
  "H06_daily_30_minute_temporal_site_residual_acf.csv"
)
verdict <- read_h06d(
  "08_diagnostics",
  "H06_daily_30_minute_temporal_diagnostic_verdict.csv"
)

stopifnot(
  nrow(component) == 3L,
  all(component$convergence == "full convergence"),
  component$working_zero_fraction[component$candidate_id == "one_part_tweedie"] > 0.40,
  component$observed_zero_fraction[component$candidate_id == "one_part_tweedie"] < 0.32,
  all(component$standardized_residual_lag1 > 0.20),
  all(closure$cyclic_closure_pass),
  max(closure$maximum_absolute_endpoint_difference_link) < 1e-8,
  nrow(site_acf) == 27L,
  max(abs(site_acf$residual_lag1[site_acf$candidate_id == "one_part_tweedie"])) > 0.30,
  any(verdict$status == "RETAIN_ARCHITECTURE_REPAIR_SPECIFICATION"),
  any(
    verdict$candidate == "One-part Tweedie" &
      verdict$domain == "Zero calibration" &
      verdict$status == "FAIL"
  )
)

daily_diagnostics <- read_h06d(
  "08_diagnostics",
  "H06_daily_stage2_pilot_daily_diagnostics.csv"
)
daily_verdict <- read_h06d(
  "08_diagnostics",
  "H06_daily_stage2_pilot_daily_verdict.csv"
)
l10 <- read_h06d(
  "08_diagnostics",
  "H06_daily_l10_zero_mass_family_pilot.csv"
)
stopifnot(
  nrow(daily_diagnostics) == 9L,
  isTRUE(daily_diagnostics$singular[
    daily_diagnostics$model_id == "registered_random_site"
  ]),
  all(daily_diagnostics$converged[
    daily_diagnostics$model_id != "registered_random_site"
  ]),
  any(daily_verdict$status == "NON_ESTIMABLE"),
  any(daily_verdict$status == "AR1_TRIGGERED"),
  l10$direction_agrees,
  abs(l10$one_part_free_vs_work_ratio - l10$two_part_free_vs_work_ratio) > 0.20
)

qmd_path <- file.path(
  root,
  "audit/hypotheses/H06_daily/02_stage2_pilot.qmd"
)
html_path <- file.path(
  root,
  "audit/hypotheses/H06_daily/02_stage2_pilot.html"
)
stopifnot(file.exists(qmd_path), file.exists(html_path))
html <- paste(readLines(html_path, warn = FALSE), collapse = "\n")
stopifnot(
  grepl("H06-D-G2P", html, fixed = TRUE),
  grepl("No temporal effect claim passes this pilot gate", html, fixed = TRUE),
  !grepl("Execution halted", html, fixed = TRUE),
  !grepl("Error in ", html, fixed = TRUE)
)

cat("H06-daily Stage 2 bounded pilot verification: PASS\n")
