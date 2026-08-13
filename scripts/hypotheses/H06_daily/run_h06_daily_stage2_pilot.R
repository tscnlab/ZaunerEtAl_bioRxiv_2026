# Run the bounded H06-daily Stage 2 production-code and temporal-family pilot.

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
  "dplyr", "tidyr", "tibble", "readr", "digest", "lme4", "glmmTMB",
  "performance", "mgcv", "gratia", "melidosData", "LightLogR"
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

# Attach mgcv because mgcv 1.9-4 tw() likelihood evaluation can require its
# internal Tweedie helpers on the search path.
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

if (!identical(as.character(getRversion()), "4.6.1")) {
  h06d_abort(
    "H06-daily Stage 2 pilot requires R 4.6.1; found %s",
    as.character(getRversion())
  )
}
if (!identical(as.character(utils::packageVersion("melidosData")), "1.0.6")) {
  h06d_abort("H06-daily pilot requires immutable melidosData 1.0.6")
}

producer <- "scripts/hypotheses/H06_daily/run_h06_daily_stage2_pilot.R"
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

input_paths <- c(
  near_eye_daily =
    "artifacts/06_model_data/base/metrics_glasses_participant_day_enriched.rds",
  chest_daily =
    "artifacts/06_model_data/base/metrics_chest_participant_day_enriched.rds",
  near_eye_30_minute =
    "artifacts/06_model_data/base/metrics_glasses_30_minute_context.rds",
  chest_30_minute =
    "artifacts/06_model_data/base/metrics_chest_30_minute_context.rds",
  temporal_provenance =
    "artifacts/06_model_data/temporal_provenance/wall_outcome_links.rds",
  exercise_diary =
    "artifacts/06_model_data/normalized_inputs/exercisediary.rds",
  sleep_diary =
    "artifacts/06_model_data/normalized_inputs/sleepdiaries.rds",
  metric_registry = "artifacts/06_model_data/H05/H05_metric_registry.csv",
  site_registry = "config/site_display_registry.csv"
)
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

message("Running bounded H06-daily representative family pilots")
pilot_started <- proc.time()[["elapsed"]]
daily <- h06d_daily_pilot(root, placement = "near_eye")
daily_elapsed <- proc.time()[["elapsed"]] - pilot_started

message("Running bounded H06-daily near-eye 30-minute temporal family pilot")
temporal_started <- proc.time()[["elapsed"]]
temporal <- h06d_fit_temporal_pilot(root, placement = "near_eye")
temporal_diagnostics <- h06d_temporal_pilot_diagnostics(temporal)
temporal_elapsed <- proc.time()[["elapsed"]] - temporal_started

daily_checkpoint <- lapply(daily$fits, function(entry) {
  list(
    formula = entry$formula,
    registry = entry$registry %||% NULL,
    frame = entry$frame,
    model = entry$fit$value,
    warnings = entry$fit$warnings,
    error = entry$fit$error,
    elapsed_seconds = entry$fit$elapsed_seconds
  )
})

trim_temporal <- function(entry, include_power = FALSE) {
  output <- list(
    formula = entry$formula,
    data = entry$data,
    model = entry$final$value,
    rho = entry$rho,
    preliminary_elapsed_seconds = entry$preliminary$elapsed_seconds,
    final_elapsed_seconds = entry$final$elapsed_seconds,
    preliminary_warnings = entry$preliminary$warnings,
    final_warnings = entry$final$warnings
  )
  if (include_power) {
    output$tweedie_power <- entry$tweedie_power
  }
  output
}

temporal_checkpoint <- list(
  one_part = trim_temporal(temporal$one_part, include_power = TRUE),
  occurrence = trim_temporal(temporal$occurrence),
  positive = trim_temporal(temporal$positive),
  specification = h06d_temporal_specification(),
  formula_registry = h06d_temporal_formula_registry(),
  input_manifest = input_manifest,
  r_version = as.character(getRversion()),
  package_versions = vapply(
    required_packages,
    function(package) as.character(utils::packageVersion(package)),
    character(1)
  )
)

daily_model_path <- file.path(
  roots$models,
  "H06_daily_stage2_pilot_daily_models.rds"
)
temporal_model_path <- file.path(
  roots$models,
  "H06_daily_30_minute_temporal_family_pilot.rds"
)
write_rds(daily_checkpoint, daily_model_path)
write_rds(temporal_checkpoint, temporal_model_path)

daily_diagnostic_path <- file.path(
  roots$diagnostics,
  "H06_daily_stage2_pilot_daily_diagnostics.csv"
)
daily_effect_path <- file.path(
  roots$tables,
  "H06_daily_stage2_pilot_effect_preview.csv"
)
temporal_component_path <- file.path(
  roots$diagnostics,
  "H06_daily_30_minute_temporal_component_diagnostics.csv"
)
temporal_calibration_path <- file.path(
  roots$diagnostics,
  "H06_daily_30_minute_temporal_calibration.csv"
)
temporal_k_path <- file.path(
  roots$diagnostics,
  "H06_daily_30_minute_temporal_k_check.csv"
)

write_csv(daily$diagnostics, daily_diagnostic_path)
write_csv(daily$effects, daily_effect_path)
write_csv(temporal_diagnostics$component, temporal_component_path)
write_csv(temporal_diagnostics$calibration, temporal_calibration_path)
write_csv(temporal_diagnostics$k_check, temporal_k_path)
write_csv(
  h06d_daily_pilot_registry(),
  file.path(roots$model_data, "H06_daily_stage2_pilot_registry.csv")
)
write_csv(
  h06d_temporal_formula_registry(),
  file.path(
    roots$model_data,
    "H06_daily_30_minute_temporal_formula_registry.csv"
  )
)
write_csv(
  input_manifest,
  file.path(roots$manifests, "H06_daily_stage2_pilot_input_manifest.csv")
)

temporal_boundary <- dplyr::bind_rows(
  temporal$one_part$data |>
    dplyr::count(.data$ar_start_reason, name = "observations") |>
    dplyr::mutate(component = "all_rows", .before = 1L),
  temporal$positive$data |>
    dplyr::count(.data$ar_start_reason, name = "observations") |>
    dplyr::mutate(component = "positive_rows", .before = 1L)
)
write_csv(
  temporal_boundary,
  file.path(
    roots$diagnostics,
    "H06_daily_30_minute_temporal_ar_boundaries.csv"
  )
)

daily_family_times <- daily$diagnostics |>
  dplyr::summarise(
    pilot_fits = dplyr::n(),
    total_seconds = sum(.data$elapsed_seconds),
    median_seconds = stats::median(.data$elapsed_seconds),
    maximum_seconds = max(.data$elapsed_seconds),
    .by = "response_family"
  )

gaussian_typical <- daily$diagnostics |>
  dplyr::filter(
    grepl("gaussian", .data$response_family),
    .data$model_id != "registered_random_site"
  ) |>
  dplyr::summarise(value = stats::median(.data$elapsed_seconds)) |>
  dplyr::pull("value")
random_site_typical <- daily$diagnostics |>
  dplyr::filter(.data$model_id == "registered_random_site") |>
  dplyr::summarise(value = max(.data$elapsed_seconds)) |>
  dplyr::pull("value")
tweedie_typical <- daily$diagnostics |>
  dplyr::filter(.data$response_family == "tweedie_log") |>
  dplyr::summarise(value = stats::median(.data$elapsed_seconds)) |>
  dplyr::pull("value")

daily_near_primary_seconds <-
  12 * 3 * (random_site_typical + 3 * gaussian_typical) +
  3 * 3 * (4 * tweedie_typical)
temporal_per_frame_seconds <- sum(
  temporal_diagnostics$component$total_elapsed_seconds
)

runtime_projection <- tibble::tribble(
  ~component, ~pilot_scope, ~production_units, ~multiplier,
  ~observed_or_projected_seconds, ~basis, ~approval_status,
  "Daily representative pilot",
  "Nine fitted model components across four response-family problems",
  "completed pilot", 1L, daily_elapsed,
  "measured wall time including frame construction",
  "completed under H06-D-G1",
  "Daily near-eye primary hierarchy",
  "15 metrics x 3 predictors x four declared formula roles",
  "180 fits", 180L, daily_near_primary_seconds,
  "family-specific pilot timing; excludes deletion diagnostics",
  "requires H06-D-G2P approval",
  "30-minute temporal family pilot",
  "one near-eye frame; one-part and two-part; six bam fits",
  "completed pilot", 1L, temporal_elapsed,
  "measured wall time including diagnostics",
  "completed under H06-D-G1",
  "30-minute declared placement/scenario set",
  "near-eye/chest all available, paired near-eye/chest, gap near-eye/chest",
  "six frames", 6L, 6 * temporal_per_frame_seconds,
  "linear projection from six near-eye bam fits per frame",
  "requires H06-D-G2P approval",
  "Participant/site deletion and uncertainty resampling",
  "accepted production models only",
  "not timed", NA_integer_, NA_real_,
  "requires a 50/100-replicate or bounded deletion pilot",
  "not authorized"
)

write_csv(
  runtime_projection,
  file.path(roots$diagnostics, "H06_daily_stage2_pilot_runtime_projection.csv")
)
write_csv(
  daily_family_times,
  file.path(roots$diagnostics, "H06_daily_stage2_pilot_family_timings.csv")
)

software_manifest <- tibble::tibble(
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
write_csv(
  software_manifest,
  file.path(roots$manifests, "H06_daily_stage2_pilot_software_manifest.csv")
)

output_paths <- c(
  daily_model_path,
  temporal_model_path,
  daily_diagnostic_path,
  daily_effect_path,
  temporal_component_path,
  temporal_calibration_path,
  temporal_k_path,
  file.path(roots$model_data, "H06_daily_stage2_pilot_registry.csv"),
  file.path(
    roots$model_data,
    "H06_daily_30_minute_temporal_formula_registry.csv"
  ),
  file.path(roots$manifests, "H06_daily_stage2_pilot_input_manifest.csv"),
  file.path(
    roots$diagnostics,
    "H06_daily_30_minute_temporal_ar_boundaries.csv"
  ),
  file.path(roots$diagnostics, "H06_daily_stage2_pilot_runtime_projection.csv"),
  file.path(roots$diagnostics, "H06_daily_stage2_pilot_family_timings.csv"),
  file.path(roots$manifests, "H06_daily_stage2_pilot_software_manifest.csv")
)
output_manifest <- tibble::tibble(
  relative_path = sub(paste0("^", root, "/"), "", output_paths),
  sha256 = vapply(output_paths, sha256, character(1)),
  bytes = unname(file.info(output_paths)$size),
  producer = producer,
  r_version = as.character(getRversion()),
  written_utc = format(Sys.time(), tz = "UTC", usetz = TRUE)
)
write_csv(
  output_manifest,
  file.path(roots$manifests, "H06_daily_stage2_pilot_output_manifest.csv")
)

message(sprintf(
  paste0(
    "H06-daily Stage 2 bounded pilot complete: daily %.1f s; ",
    "temporal %.1f s; no simulation or bootstrap run"
  ),
  daily_elapsed,
  temporal_elapsed
))
