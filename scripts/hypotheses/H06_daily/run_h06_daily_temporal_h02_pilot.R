#!/usr/bin/env Rscript

# Run the corrected, bounded, H02-aligned H06-daily temporal pilot.
# This script does not run MDER, daily-metric models, chest models, or resampling.

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
  "dplyr", "tidyr", "tibble", "readr", "digest", "mgcv", "melidosData"
)
missing_packages <- required_packages[!vapply(
  required_packages,
  requireNamespace,
  logical(1),
  quietly = TRUE
)]
if (length(missing_packages) > 0L) {
  stop(
    "Missing synchronized project package(s): ",
    paste(missing_packages, collapse = ", "),
    call. = FALSE
  )
}

library(mgcv)
library(dplyr)

source(file.path(
  root,
  "scripts/hypotheses/H06_daily/h06_daily_contract.R"
))
source(file.path(
  root,
  "scripts/hypotheses/H06_daily/h06_daily_data.R"
))
source(file.path(
  root,
  "scripts/hypotheses/H06_daily/h06_daily_modeling.R"
))
source(file.path(
  root,
  "scripts/hypotheses/H06_daily/h06_daily_temporal_h02_contract.R"
))
source(file.path(
  root,
  "scripts/hypotheses/H06_daily/h06_daily_temporal_h02_data.R"
))
source(file.path(
  root,
  "scripts/hypotheses/H06_daily/h06_daily_temporal_h02_modeling.R"
))

if (!identical(as.character(getRversion()), "4.6.1")) {
  h06d_abort(
    "H02-aligned H06-daily pilot requires R 4.6.1; found %s",
    as.character(getRversion())
  )
}
if (!identical(as.character(utils::packageVersion("mgcv")), "1.9.4")) {
  h06d_abort("H02-aligned H06-daily pilot requires mgcv 1.9-4")
}
if (!identical(as.character(utils::packageVersion("melidosData")), "1.0.6")) {
  h06d_abort("H06-daily pilot requires immutable melidosData 1.0.6")
}

producer <- paste0(
  "scripts/hypotheses/H06_daily/",
  "run_h06_daily_temporal_h02_pilot.R"
)
roots <- h06d_artifact_roots(root)
invisible(lapply(roots, dir.create, recursive = TRUE, showWarnings = FALSE))

write_csv <- function(data, path) {
  readr::write_csv(data, path, na = "")
  invisible(path)
}
write_rds <- function(object, path) {
  saveRDS(object, path, version = 3)
  invisible(path)
}
sha256 <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE)
}
relative_to_root <- function(path) {
  substring(path, nchar(root) + 2L)
}

input_paths <- c(
  near_eye_30_minute =
    "artifacts/06_model_data/base/metrics_glasses_30_minute_context.rds",
  temporal_provenance =
    "artifacts/06_model_data/temporal_provenance/wall_outcome_links.rds",
  exercise_diary =
    "artifacts/06_model_data/normalized_inputs/exercisediary.rds",
  sleep_diary =
    "artifacts/06_model_data/normalized_inputs/sleepdiaries.rds",
  site_registry = "config/site_display_registry.csv",
  base_model_manifest = "artifacts/12_manifests/base_model_data_artifacts.csv",
  metric_manifest = "artifacts/12_manifests/metric_artifacts.csv",
  minute_aggregation_decision = "audit/decisions/minute_aggregation.md",
  preparation_06_gate =
    "audit/decisions/preparation06_current_base_model_gate.md",
  h02_selected_specification =
    "artifacts/07_models/H02/selected_temporal_model_specification.csv",
  h02_selected_near_eye_fit = paste0(
    "artifacts/07_models/H02/",
    "main__glasses__all_available__selected_model.rds"
  ),
  h06d_author_transition = paste0(
    "audit/hypotheses/H06_daily/",
    "H06_daily_temporal_h02_estimand_transition.md"
  )
)
if (any(!file.exists(file.path(root, input_paths)))) {
  h06d_abort(
    "Missing H02-aligned pilot input(s): %s",
    paste(input_paths[!file.exists(file.path(root, input_paths))], collapse = ", ")
  )
}
input_manifest <- tibble::tibble(
  input_id = names(input_paths),
  relative_path = unname(input_paths),
  sha256 = vapply(
    file.path(root, unname(input_paths)),
    sha256,
    character(1)
  ),
  bytes = unname(file.info(file.path(root, unname(input_paths)))$size)
)

expected_h02_hashes <- c(
  h02_selected_specification =
    "c3c95e97dbf7a260e4aa7513a15bb8c3c7e98bdb754d97c54700e4d82629310f",
  h02_selected_near_eye_fit =
    "45fa9d6b28a10a7c09d1bd4541c009977eebb8ccdbcda5f33ba306934b20acc7"
)
observed_h02 <- input_manifest |>
  dplyr::filter(.data$input_id %in% names(.env$expected_h02_hashes)) |>
  dplyr::mutate(
    expected_sha256 = unname(.env$expected_h02_hashes[.data$input_id])
  )
if (
  nrow(observed_h02) != length(expected_h02_hashes) ||
    any(observed_h02$sha256 != observed_h02$expected_sha256)
) {
  h06d_abort("Frozen H02 inheritance artifacts failed their exact hash check")
}

code_paths <- c(
  "scripts/hypotheses/H06_daily/h06_daily_contract.R",
  "scripts/hypotheses/H06_daily/h06_daily_data.R",
  "scripts/hypotheses/H06_daily/h06_daily_modeling.R",
  "scripts/hypotheses/H06_daily/h06_daily_temporal_h02_contract.R",
  "scripts/hypotheses/H06_daily/h06_daily_temporal_h02_data.R",
  "scripts/hypotheses/H06_daily/h06_daily_temporal_h02_modeling.R",
  producer
)
code_manifest <- tibble::tibble(
  relative_path = code_paths,
  sha256 = vapply(file.path(root, code_paths), sha256, character(1)),
  bytes = unname(file.info(file.path(root, code_paths))$size)
)

message("Constructing exact near-eye H02-aligned H06-daily frame")
frame <- h06d_h02_temporal_frame(root, placement = "near_eye")
support <- h06d_h02_temporal_support(frame)

frame_path <- file.path(
  roots$model_data,
  "H06_daily_temporal_h02_near_eye_frame.rds"
)
formula_path <- file.path(
  roots$model_data,
  "H06_daily_temporal_h02_formula_registry.csv"
)
specification_path <- file.path(
  roots$model_data,
  "H06_daily_temporal_h02_specification.csv"
)
write_rds(frame, frame_path)
write_csv(h06d_h02_temporal_formula_registry(), formula_path)

specification <- h06d_h02_temporal_specification()
specification_table <- tibble::tibble(
  field = names(specification),
  value = vapply(
    specification,
    function(value) paste(value, collapse = " | "),
    character(1)
  )
)
write_csv(specification_table, specification_path)

message("Running bounded H02-aligned near-eye temporal pilot")
pilot_started <- proc.time()[["elapsed"]]
pilot <- h06d_h02_fit_temporal_pilot(frame)

component <- h06d_h02_residual_diagnostics(pilot)
site_acf <- h06d_h02_site_residual_acf(pilot)
day_acf <- h06d_h02_participant_day_residual_acf(pilot)
k_check <- h06d_deterministic_k_check(pilot$final$value) |>
  dplyr::mutate(
    edf_fraction = .data$effective_df / .data$k_prime,
    deterministic_seed = 61062026L,
    permutation_replicates = 0L
  )
identifiability <- h06d_term_concurvity_fallback(
  pilot$final$value,
  candidate_id = specification$implementation_id,
  component = "joint_context_model",
  maximum_rows = 5000L,
  seed = 61062026L
)
closure <- h06d_h02_global_closure(pilot)
smooth_registry <- h06d_h02_smooth_registry(pilot$final$value)
verdict <- h06d_h02_diagnostic_verdict(
  support = support,
  component = component,
  site_acf = site_acf,
  k_check = k_check,
  identifiability = identifiability,
  closure = closure,
  smooth_registry = smooth_registry
)

calibration <- tibble::tibble(
  observed = frame$response,
  fitted = as.numeric(stats::fitted(pilot$final$value))
) |>
  dplyr::mutate(fitted_decile = dplyr::ntile(.data$fitted, 10L)) |>
  dplyr::summarise(
    observations = dplyr::n(),
    observed_mean = mean(.data$observed),
    fitted_mean = mean(.data$fitted),
    mean_residual = mean(.data$observed - .data$fitted),
    residual_rmse = sqrt(mean((.data$observed - .data$fitted)^2)),
    .by = "fitted_decile"
  )

residual <- h06d_h02_standardized_residual(pilot$final$value)
residual_quantiles <- tibble::tibble(
  probability = c(0, 0.01, 0.05, 0.25, 0.5, 0.75, 0.95, 0.99, 1),
  standardized_residual = unname(stats::quantile(
    residual,
    probs = c(0, 0.01, 0.05, 0.25, 0.5, 0.75, 0.95, 0.99, 1),
    na.rm = TRUE
  ))
)

pilot_total_seconds <- proc.time()[["elapsed"]] - pilot_started

runtime <- tibble::tribble(
  ~scope, ~fits, ~observed_or_projected_seconds, ~basis, ~status,
  "Corrected near-eye bounded pilot", 2L, pilot_total_seconds,
  "measured wall time: preliminary plus fixed-rho final fit and diagnostics",
  "completed after author estimand confirmation",
  "Six declared placement/scenario frames", 12L, 6 * component$total_fit_elapsed_seconds,
  "linear fit-only projection from two BAM fits per frame",
  "not authorized",
  "Uncertainty or deletion resampling", NA_integer_, NA_real_,
  "not timed; requires a 50/100-replicate or bounded deletion pilot",
  "not authorized"
)

model_path <- file.path(
  roots$models,
  "H06_daily_temporal_h02_near_eye_pilot.rds"
)
checkpoint <- list(
  implementation_id = specification$implementation_id,
  formula = pilot$formula,
  specification = specification,
  model = pilot$final$value,
  rho_unclamped = pilot$rho_unclamped,
  rho = pilot$rho,
  preliminary_response_residuals = as.numeric(stats::residuals(
    pilot$preliminary$value,
    type = "response"
  )),
  preliminary_elapsed_seconds = pilot$preliminary$elapsed_seconds,
  final_elapsed_seconds = pilot$final$elapsed_seconds,
  preliminary_warnings = pilot$preliminary$warnings,
  final_warnings = pilot$final$warnings,
  frame_relative_path = relative_to_root(frame_path),
  input_manifest = input_manifest,
  code_manifest = code_manifest,
  r_version = as.character(getRversion()),
  package_versions = vapply(
    required_packages,
    function(package) as.character(utils::packageVersion(package)),
    character(1)
  )
)
write_rds(checkpoint, model_path)

diagnostic_paths <- c(
  component = file.path(
    roots$diagnostics,
    "H06_daily_temporal_h02_component_diagnostics.csv"
  ),
  site_acf = file.path(
    roots$diagnostics,
    "H06_daily_temporal_h02_site_residual_acf.csv"
  ),
  day_acf = file.path(
    roots$diagnostics,
    "H06_daily_temporal_h02_participant_day_residual_acf.csv"
  ),
  k_check = file.path(
    roots$diagnostics,
    "H06_daily_temporal_h02_k_check.csv"
  ),
  identifiability = file.path(
    roots$diagnostics,
    "H06_daily_temporal_h02_identifiability_screen.csv"
  ),
  closure = file.path(
    roots$diagnostics,
    "H06_daily_temporal_h02_global_closure.csv"
  ),
  smooth_registry = file.path(
    roots$diagnostics,
    "H06_daily_temporal_h02_smooth_registry.csv"
  ),
  verdict = file.path(
    roots$diagnostics,
    "H06_daily_temporal_h02_diagnostic_verdict.csv"
  ),
  calibration = file.path(
    roots$diagnostics,
    "H06_daily_temporal_h02_transformed_calibration.csv"
  ),
  residual_quantiles = file.path(
    roots$diagnostics,
    "H06_daily_temporal_h02_residual_quantiles.csv"
  ),
  support_overall = file.path(
    roots$diagnostics,
    "H06_daily_temporal_h02_support_overall.csv"
  ),
  context_cells = file.path(
    roots$diagnostics,
    "H06_daily_temporal_h02_context_cells.csv"
  ),
  sleep_by_site = file.path(
    roots$diagnostics,
    "H06_daily_temporal_h02_sleep_support_by_site.csv"
  ),
  ar_boundaries = file.path(
    roots$diagnostics,
    "H06_daily_temporal_h02_ar_boundaries.csv"
  ),
  runtime = file.path(
    roots$diagnostics,
    "H06_daily_temporal_h02_runtime.csv"
  )
)
diagnostic_objects <- list(
  component,
  site_acf,
  day_acf,
  k_check,
  identifiability,
  closure,
  smooth_registry,
  verdict,
  calibration,
  residual_quantiles,
  support$overall,
  support$context_cells,
  support$sleep_by_site,
  support$ar_boundaries,
  runtime
)
invisible(Map(write_csv, diagnostic_objects, diagnostic_paths))

software_path <- file.path(
  roots$manifests,
  "H06_daily_temporal_h02_software_manifest.csv"
)
input_manifest_path <- file.path(
  roots$manifests,
  "H06_daily_temporal_h02_input_manifest.csv"
)
code_manifest_path <- file.path(
  roots$manifests,
  "H06_daily_temporal_h02_code_manifest.csv"
)
software <- tibble::tibble(
  item = c("R", required_packages),
  version = c(
    as.character(getRversion()),
    vapply(
      required_packages,
      function(package) as.character(utils::packageVersion(package)),
      character(1)
    )
  ),
  role = c(
    "authoritative computation",
    rep("synchronized project library", length(required_packages))
  )
)
write_csv(software, software_path)
write_csv(input_manifest, input_manifest_path)
write_csv(code_manifest, code_manifest_path)

output_paths <- c(
  frame_path,
  formula_path,
  specification_path,
  model_path,
  unname(diagnostic_paths),
  software_path,
  input_manifest_path,
  code_manifest_path
)
output_manifest <- tibble::tibble(
  relative_path = vapply(output_paths, relative_to_root, character(1)),
  sha256 = vapply(output_paths, sha256, character(1)),
  bytes = unname(file.info(output_paths)$size),
  producer = producer,
  r_version = as.character(getRversion())
)
output_manifest_path <- file.path(
  roots$manifests,
  "H06_daily_temporal_h02_output_manifest.csv"
)
write_csv(output_manifest, output_manifest_path)

message(sprintf(
  paste0(
    "H02-aligned H06-daily temporal pilot complete in %.1f minutes; ",
    "rho %.4f; overall gate %s"
  ),
  pilot_total_seconds / 60,
  pilot$rho,
  dplyr::last(verdict$status)
))
