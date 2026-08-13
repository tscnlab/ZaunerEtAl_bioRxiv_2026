#!/usr/bin/env Rscript

# Fit the approved six-frame H02-aligned H06-daily temporal production batch.
# The selected primary near-eye pilot is reused only after exact frame and
# formula verification; every other frame receives its own rho-zero and fixed-
# rho fit.

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

required_packages <- c("digest", "dplyr", "mgcv", "readr", "tibble")
stopifnot(
  identical(as.character(getRversion()), "4.6.1"),
  identical(as.character(utils::packageVersion("mgcv")), "1.9.4"),
  all(vapply(required_packages, requireNamespace, logical(1), quietly = TRUE))
)

sources <- c(
  "scripts/hypotheses/H06_daily/h06_daily_contract.R",
  "scripts/hypotheses/H06_daily/h06_daily_data.R",
  "scripts/hypotheses/H06_daily/h06_daily_modeling.R",
  "scripts/hypotheses/H06_daily/h06_daily_temporal_h02_contract.R",
  paste0(
    "scripts/hypotheses/H06_daily/",
    "h06_daily_temporal_h02_production_data.R"
  ),
  paste0(
    "scripts/hypotheses/H06_daily/",
    "h06_daily_temporal_h02_production_modeling.R"
  )
)
invisible(lapply(file.path(root, sources), source))

roots <- h06d_artifact_roots(root)
producer <- paste0(
  "scripts/hypotheses/H06_daily/",
  "run_h06_daily_temporal_h02_production_models.R"
)
sha256 <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE)
}
relative_to_root <- function(path) {
  substring(path, nchar(root) + 2L)
}
read_csv <- function(path) {
  readr::read_csv(path, show_col_types = FALSE, na = "")
}
write_csv <- function(data, path) {
  readr::write_csv(data, path, na = "")
  invisible(path)
}

frame_manifest_relative <- paste0(
  "artifacts/12_manifests/H06_daily/",
  "H06_daily_temporal_h02_production_frame_output_manifest.csv"
)
frame_manifest_path <- file.path(root, frame_manifest_relative)
if (
  !identical(
    sha256(frame_manifest_path),
    "8463445ac682272a59fda9617a2f77033d6c3ef54b3a5b29ea4f67eb1bdfa6d9"
  )
) {
  h06d_abort("Static production-frame manifest identity changed")
}
frame_manifest <- read_csv(frame_manifest_path)
observed_frame_hash <- vapply(
  file.path(root, frame_manifest$relative_path),
  sha256,
  character(1)
)
if (!identical(unname(observed_frame_hash), frame_manifest$sha256)) {
  h06d_abort("Static production-frame output manifest verification failed")
}

gate_relative <- paste0(
  "artifacts/08_diagnostics/H06_daily/",
  "H06_daily_temporal_h02_production_gate_contract.csv"
)
gate <- read_csv(file.path(root, gate_relative))
if (
  sum(gate$status == "APPROVED") != 3L ||
    sum(gate$status == "APPROVED_POINTWISE_ONLY") != 1L ||
    sum(gate$status == "WITHHELD_PENDING_PILOT") != 1L ||
    sum(gate$status == "UPSTREAM_HOLD") != 1L
) {
  h06d_abort("H06-D-G2P-H02 production gate is not in the approved state")
}

registry <- read_csv(file.path(
  roots$model_data,
  "H06_daily_temporal_h02_production_run_registry.csv"
)) |>
  dplyr::arrange(.data$run_order)
if (!identical(registry$run_id, h06d_h02_production_registry()$run_id)) {
  h06d_abort("Production run registry differs from the approved contract")
}

frame_path <- function(run_id) {
  file.path(
    roots$model_data,
    paste0(
      "H06_daily_temporal_h02_production__",
      run_id,
      "__frame.rds"
    )
  )
}
model_path <- function(run_id) {
  file.path(
    roots$models,
    paste0(
      "H06_daily_temporal_h02_production__",
      run_id,
      "__model.rds"
    )
  )
}
frame_hash_from_manifest <- function(path) {
  relative <- relative_to_root(path)
  hash <- frame_manifest$sha256[frame_manifest$relative_path == relative]
  if (length(hash) != 1L) {
    h06d_abort("Frame is absent from the verified output manifest: %s", relative)
  }
  hash
}

batch_started <- proc.time()[["elapsed"]]
timings <- vector("list", nrow(registry))
model_paths <- character(nrow(registry))

for (index in seq_len(nrow(registry))) {
  run <- registry[index, ]
  run_id <- run$run_id[[1L]]
  current_frame_path <- frame_path(run_id)
  frame <- readRDS(current_frame_path)
  started <- proc.time()[["elapsed"]]

  if (identical(run_id, "primary__near_eye__all_available")) {
    pilot_path <- file.path(
      roots$models,
      "H06_daily_temporal_h02_near_eye_pilot.rds"
    )
    if (
      !identical(
        sha256(pilot_path),
        "ad911b2f7948b940b0045ad4dff3ec043c0c3008fbf076af823cbfc363d9349e"
      )
    ) {
      h06d_abort("Selected near-eye pilot checkpoint identity changed")
    }
    selected_pilot <- readRDS(pilot_path)
    checkpoint <- h06d_h02_reuse_selected_pilot(
      frame,
      run_id,
      selected_pilot
    )
    checkpoint$selected_pilot_checkpoint_relative_path <-
      relative_to_root(pilot_path)
    checkpoint$selected_pilot_checkpoint_sha256 <- sha256(pilot_path)
    rm(selected_pilot)
  } else {
    checkpoint <- h06d_h02_fit_production_model(frame, run_id)
  }

  checkpoint$frame_relative_path <- relative_to_root(current_frame_path)
  checkpoint$frame_sha256 <- frame_hash_from_manifest(current_frame_path)
  checkpoint$model_formula <- paste(
    deparse(stats::formula(checkpoint$model)),
    collapse = " "
  )
  checkpoint$fit_completed_at <- format(
    Sys.time(),
    "%Y-%m-%dT%H:%M:%S%z"
  )
  current_model_path <- model_path(run_id)
  saveRDS(checkpoint, current_model_path, version = 3)
  model_paths[[index]] <- current_model_path

  timings[[index]] <- tibble::tibble(
    run_order = run$run_order,
    run_id = run_id,
    reused_selected_pilot = checkpoint$reused_selected_pilot,
    rho_unclamped = checkpoint$rho_unclamped,
    rho = checkpoint$rho,
    preliminary_elapsed_seconds = checkpoint$preliminary_elapsed_seconds,
    final_elapsed_seconds = checkpoint$final_elapsed_seconds,
    inherited_or_new_fit_seconds =
      checkpoint$preliminary_elapsed_seconds + checkpoint$final_elapsed_seconds,
    current_batch_elapsed_seconds = proc.time()[["elapsed"]] - started,
    preliminary_warning_count = length(checkpoint$preliminary_warnings),
    final_warning_count = length(checkpoint$final_warnings),
    preliminary_warnings = paste(
      checkpoint$preliminary_warnings,
      collapse = " | "
    ),
    final_warnings = paste(checkpoint$final_warnings, collapse = " | ")
  )
  rm(frame, checkpoint)
  invisible(gc())
}

timing <- dplyr::bind_rows(timings) |>
  dplyr::mutate(
    full_batch_wall_seconds = proc.time()[["elapsed"]] - batch_started
  )
timing_path <- file.path(
  roots$diagnostics,
  "H06_daily_temporal_h02_production_fit_runtime.csv"
)
write_csv(timing, timing_path)

input_manifest_path <- file.path(
  roots$manifests,
  "H06_daily_temporal_h02_production_model_input_manifest.csv"
)
code_manifest_path <- file.path(
  roots$manifests,
  "H06_daily_temporal_h02_production_model_code_manifest.csv"
)
software_manifest_path <- file.path(
  roots$manifests,
  "H06_daily_temporal_h02_production_model_software_manifest.csv"
)
output_manifest_path <- file.path(
  roots$manifests,
  "H06_daily_temporal_h02_production_model_output_manifest.csv"
)

input_relative <- c(
  frame_manifest_relative,
  gate_relative,
  paste0(
    "artifacts/07_models/H06_daily/",
    "H06_daily_temporal_h02_near_eye_pilot.rds"
  )
)
input_manifest <- tibble::tibble(
  relative_path = input_relative,
  sha256 = vapply(file.path(root, input_relative), sha256, character(1)),
  bytes = unname(file.info(file.path(root, input_relative))$size),
  role = c(
    "verified_static_frame_bundle",
    "author_approved_pointwise_production_gate",
    "exact_selected_primary_pilot_reuse"
  )
)
write_csv(input_manifest, input_manifest_path)

code_relative <- c(sources, producer)
code_manifest <- tibble::tibble(
  relative_path = code_relative,
  sha256 = vapply(file.path(root, code_relative), sha256, character(1)),
  bytes = unname(file.info(file.path(root, code_relative))$size)
)
write_csv(code_manifest, code_manifest_path)

software <- tibble::tibble(
  component = c("R", required_packages),
  version = c(
    as.character(getRversion()),
    vapply(
      required_packages,
      function(package) as.character(utils::packageVersion(package)),
      character(1)
    )
  )
)
write_csv(software, software_manifest_path)

output_paths <- c(
  model_paths,
  timing_path,
  input_manifest_path,
  code_manifest_path,
  software_manifest_path
)
output_manifest <- tibble::tibble(
  relative_path = vapply(output_paths, relative_to_root, character(1)),
  sha256 = vapply(output_paths, sha256, character(1)),
  bytes = unname(file.info(output_paths)$size),
  producer = producer,
  r_version = as.character(getRversion())
)
write_csv(output_manifest, output_manifest_path)

message(sprintf(
  "H06-D-G2P-H02 production model batch complete: %.1f minutes wall time",
  (proc.time()[["elapsed"]] - batch_started) / 60
))
