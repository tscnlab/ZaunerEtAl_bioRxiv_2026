#!/usr/bin/env Rscript

# Focused no-refit verification of the H02-aligned temporal production report.

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
stopifnot(
  identical(as.character(getRversion()), "4.6.1"),
  identical(as.character(utils::packageVersion("mgcv")), "1.9.4"),
  requireNamespace("digest", quietly = TRUE),
  requireNamespace("readr", quietly = TRUE)
)

sha256 <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE)
}
read_csv <- function(path) {
  readr::read_csv(path, show_col_types = FALSE, na = "")
}
verify_manifest <- function(path) {
  manifest <- read_csv(path)
  observed <- vapply(
    file.path(root, manifest$relative_path),
    sha256,
    character(1)
  )
  stopifnot(identical(unname(observed), manifest$sha256))
  invisible(manifest)
}
artifact <- function(stage, file) {
  file.path(root, "artifacts", stage, "H06_daily", file)
}

manifest_names <- c(
  "H06_daily_temporal_h02_production_gate_output_manifest.csv",
  "H06_daily_temporal_h02_production_frame_output_manifest.csv",
  "H06_daily_temporal_h02_production_model_output_manifest.csv",
  "H06_daily_temporal_h02_production_diagnostic_output_manifest.csv",
  "H06_daily_temporal_h02_production_inference_output_manifest.csv",
  "H06_daily_temporal_h02_figure_output_manifest.csv"
)
for (name in manifest_names) {
  verify_manifest(artifact("12_manifests", name))
}
verify_manifest(file.path(
  root,
  "audit/hypotheses/H06_daily/",
  "H06_daily_temporal_h02_production_report_manifest.csv"
))

registry <- read_csv(artifact(
  "06_model_data",
  "H06_daily_temporal_h02_production_run_registry.csv"
))
formula_registry <- read_csv(artifact(
  "06_model_data",
  "H06_daily_temporal_h02_formula_registry.csv"
))
support <- read_csv(artifact(
  "08_diagnostics",
  "H06_daily_temporal_h02_production_support_overall.csv"
))
runtime <- read_csv(artifact(
  "08_diagnostics",
  "H06_daily_temporal_h02_production_fit_runtime.csv"
))
verdict <- read_csv(artifact(
  "08_diagnostics",
  "H06_daily_temporal_h02_production_diagnostic_verdict.csv"
))
tests <- read_csv(artifact(
  "09_tables",
  "H06_daily_temporal_h02_production_whole_function_tests.csv"
))
not_extracted <- read_csv(artifact(
  "09_tables",
  "H06_daily_temporal_h02_production_not_extracted_frames.csv"
))
functions <- read_csv(artifact(
  "11_source_data",
  "H06_daily_temporal_h02_production_context_functions.csv"
))
profiles <- read_csv(artifact(
  "11_source_data",
  "H06_daily_temporal_h02_production_inverse_profiles.csv"
))
qa <- read_csv(artifact(
  "08_diagnostics",
  "H06_daily_temporal_h02_figure_readability_qa.csv"
))
alt <- read_csv(artifact(
  "11_source_data",
  "H06_daily_temporal_h02_figure_alt_text.csv"
))

overall <- verdict[
  verdict$domain == "Overall base-model diagnostic gate",
  ,
  drop = FALSE
]
primary <- tests[
  tests$run_id == "primary__near_eye__all_available",
  ,
  drop = FALSE
]
gap <- tests[
  tests$run_id == "gap_timing_unaware__near_eye__all_available",
  ,
  drop = FALSE
]

stopifnot(
  nrow(registry) == 6L,
  nrow(formula_registry) == 1L,
  !grepl("xt", formula_registry$formula, fixed = TRUE),
  grepl("bs = \\\"cc\\\", k = 12", formula_registry$formula),
  grepl("bs = \\\"fs\\\", k = 10", formula_registry$formula),
  nrow(support) == 6L,
  identical(support$observations_30_minute,
    c(33057, 36558, 25583, 25583, 32969, 36404)
  ),
  identical(support$participant_days, c(715, 789, 553, 553, 710, 782)),
  identical(round(runtime$rho, 7),
    round(c(0.5787385, 0.5696938, 0.5790932, 0.5611254,
      0.5764556, 0.5635329), 7)
  ),
  nrow(overall) == 6L,
  sum(overall$status == "ACCEPTABLE") == 5L,
  sum(overall$status == "NOT_ACCEPTABLE") == 1L,
  overall$run_id[overall$status == "NOT_ACCEPTABLE"] ==
    "primary__chest__paired_common",
  nrow(not_extracted) == 1L,
  not_extracted$run_id == "primary__chest__paired_common",
  grepl("0.313", not_extracted$reason, fixed = TRUE),
  nrow(functions) == 960L,
  nrow(profiles) == 1920L,
  identical(unique(functions$interval_type),
    "pointwise 95% confidence interval"
  ),
  identical(unique(profiles$interval_type),
    "pointwise 95% confidence interval"
  ),
  !any(grepl("simultaneous", functions$interval_type, ignore.case = TRUE)),
  !any(grepl("simultaneous", profiles$interval_type, ignore.case = TRUE)),
  nrow(primary) == 4L,
  nrow(gap) == 4L,
  all(primary$bh_decision),
  all(gap$bh_decision),
  all(primary$bh_adjusted_p_value < 0.001),
  all(gap$bh_adjusted_p_value < 0.001),
  sum(tests$raw_p_value_unclamped < 0, na.rm = TRUE) == 1L,
  all(qa$visual_qa_status == "PASS_AFTER_170MM_LAYOUT_REVIEW"),
  all(qa$paired_source_data == "PASS"),
  all(qa$alt_text == "PASS"),
  nrow(alt) == 3L
)

qmd_path <- file.path(
  root,
  "audit/hypotheses/H06_daily/04_temporal_h02_production.qmd"
)
html_path <- file.path(
  root,
  "audit/hypotheses/H06_daily/04_temporal_h02_production.html"
)
qmd <- paste(readLines(qmd_path, warn = FALSE), collapse = "\n")
html <- paste(readLines(html_path, warn = FALSE), collapse = "\n")
stopifnot(
  grepl("pointwise 95% confidence interval", qmd, fixed = TRUE),
  grepl("No simultaneous interval was constructed", qmd, fixed = TRUE),
  grepl("Z = \\log_{10}", qmd, fixed = TRUE),
  !grepl("Z = _{10}", qmd, fixed = TRUE),
  grepl("H06 daily metrics — exploratory temporal production", html,
    fixed = TRUE
  ),
  !grepl("Z = _{10}", html, fixed = TRUE)
)

message("H06_daily H02-aligned temporal production verification passed")
