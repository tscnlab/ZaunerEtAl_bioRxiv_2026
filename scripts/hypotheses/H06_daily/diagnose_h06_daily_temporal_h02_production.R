#!/usr/bin/env Rscript

# Run the prespecified no-refit diagnostics for all six selected H02-aligned
# H06-daily temporal production models. This script does not extract context
# association functions or inspect their p-values.

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
  "digest", "dplyr", "mgcv", "readr", "rlang", "tibble", "tidyr"
)
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
  "scripts/hypotheses/H06_daily/h06_daily_temporal_h02_modeling.R",
  paste0(
    "scripts/hypotheses/H06_daily/",
    "h06_daily_temporal_h02_production_data.R"
  ),
  paste0(
    "scripts/hypotheses/H06_daily/",
    "h06_daily_temporal_h02_production_inference.R"
  )
)
invisible(lapply(file.path(root, sources), source))

roots <- h06d_artifact_roots(root)
producer <- paste0(
  "scripts/hypotheses/H06_daily/",
  "diagnose_h06_daily_temporal_h02_production.R"
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
verify_output_manifest <- function(relative, expected_sha256) {
  path <- file.path(root, relative)
  if (!identical(sha256(path), expected_sha256)) {
    h06d_abort("Manifest identity changed: %s", relative)
  }
  manifest <- read_csv(path)
  observed <- vapply(
    file.path(root, manifest$relative_path),
    sha256,
    character(1)
  )
  if (!identical(unname(observed), manifest$sha256)) {
    h06d_abort("Manifest contents do not verify: %s", relative)
  }
  manifest
}

frame_manifest_relative <- paste0(
  "artifacts/12_manifests/H06_daily/",
  "H06_daily_temporal_h02_production_frame_output_manifest.csv"
)
model_manifest_relative <- paste0(
  "artifacts/12_manifests/H06_daily/",
  "H06_daily_temporal_h02_production_model_output_manifest.csv"
)
frame_manifest <- verify_output_manifest(
  frame_manifest_relative,
  "8463445ac682272a59fda9617a2f77033d6c3ef54b3a5b29ea4f67eb1bdfa6d9"
)
model_manifest <- verify_output_manifest(
  model_manifest_relative,
  "3386633a579406b262ab2f43aee86f908a140b08c674b1b01348be522db64684"
)

registry <- read_csv(file.path(
  roots$model_data,
  "H06_daily_temporal_h02_production_run_registry.csv"
)) |>
  dplyr::arrange(.data$run_order)
static_gate <- read_csv(file.path(
  roots$diagnostics,
  "H06_daily_temporal_h02_production_static_gate.csv"
))
stopifnot(
  identical(registry$run_id, h06d_h02_production_registry()$run_id),
  identical(static_gate$run_id, registry$run_id),
  all(static_gate$static_gate == "PASS")
)

frame_path <- function(run_id) {
  file.path(
    roots$model_data,
    paste0(
      "H06_daily_temporal_h02_production__", run_id, "__frame.rds"
    )
  )
}
model_path <- function(run_id) {
  file.path(
    roots$models,
    paste0(
      "H06_daily_temporal_h02_production__", run_id, "__model.rds"
    )
  )
}

diagnostic_started <- proc.time()[["elapsed"]]
results <- vector("list", nrow(registry))
runtime <- vector("list", nrow(registry))
for (index in seq_len(nrow(registry))) {
  run <- registry[index, ]
  run_id <- run$run_id[[1L]]
  message("Diagnosing ", run_id)
  started <- proc.time()[["elapsed"]]
  current_frame_path <- frame_path(run_id)
  current_model_path <- model_path(run_id)
  frame <- readRDS(current_frame_path)
  checkpoint <- readRDS(current_model_path)
  if (
    !identical(checkpoint$frame_sha256, sha256(current_frame_path)) ||
      checkpoint$run_id != run_id ||
      stats::nobs(checkpoint$model) != nrow(frame)
  ) {
    h06d_abort("Model/frame checkpoint mismatch for %s", run_id)
  }
  results[[index]] <- h06d_h02_production_diagnostics(
    checkpoint,
    frame,
    run,
    static_gate[index, ]
  )
  runtime[[index]] <- tibble::tibble(
    run_order = run$run_order,
    run_id = run_id,
    diagnostic_elapsed_seconds = proc.time()[["elapsed"]] - started
  )
  rm(frame, checkpoint)
  invisible(gc())
}

combined <- lapply(names(results[[1L]]), function(component) {
  dplyr::bind_rows(lapply(results, `[[`, component))
})
names(combined) <- names(results[[1L]])
runtime <- dplyr::bind_rows(runtime) |>
  dplyr::mutate(
    full_diagnostic_wall_seconds =
      proc.time()[["elapsed"]] - diagnostic_started
  )

paths <- c(
  component = file.path(
    roots$diagnostics,
    "H06_daily_temporal_h02_production_component_diagnostics.csv"
  ),
  smooth_registry = file.path(
    roots$diagnostics,
    "H06_daily_temporal_h02_production_smooth_registry.csv"
  ),
  k_check = file.path(
    roots$diagnostics,
    "H06_daily_temporal_h02_production_k_check.csv"
  ),
  site_acf = file.path(
    roots$diagnostics,
    "H06_daily_temporal_h02_production_site_residual_acf.csv"
  ),
  identifiability = file.path(
    roots$diagnostics,
    "H06_daily_temporal_h02_production_identifiability_screen.csv"
  ),
  closure = file.path(
    roots$diagnostics,
    "H06_daily_temporal_h02_production_global_closure.csv"
  ),
  verdict = file.path(
    roots$diagnostics,
    "H06_daily_temporal_h02_production_diagnostic_verdict.csv"
  ),
  residual_quantiles = file.path(
    roots$diagnostics,
    "H06_daily_temporal_h02_production_residual_quantiles.csv"
  )
)
invisible(Map(write_csv, combined[names(paths)], paths))
runtime_path <- file.path(
  roots$diagnostics,
  "H06_daily_temporal_h02_production_diagnostic_runtime.csv"
)
write_csv(runtime, runtime_path)

input_manifest_path <- file.path(
  roots$manifests,
  "H06_daily_temporal_h02_production_diagnostic_input_manifest.csv"
)
code_manifest_path <- file.path(
  roots$manifests,
  "H06_daily_temporal_h02_production_diagnostic_code_manifest.csv"
)
software_manifest_path <- file.path(
  roots$manifests,
  "H06_daily_temporal_h02_production_diagnostic_software_manifest.csv"
)
output_manifest_path <- file.path(
  roots$manifests,
  "H06_daily_temporal_h02_production_diagnostic_output_manifest.csv"
)

input_relative <- c(frame_manifest_relative, model_manifest_relative)
write_csv(
  tibble::tibble(
    relative_path = input_relative,
    sha256 = vapply(file.path(root, input_relative), sha256, character(1)),
    bytes = unname(file.info(file.path(root, input_relative))$size),
    role = c("verified_frame_bundle", "verified_selected_model_bundle")
  ),
  input_manifest_path
)
code_relative <- c(sources, producer)
write_csv(
  tibble::tibble(
    relative_path = code_relative,
    sha256 = vapply(file.path(root, code_relative), sha256, character(1)),
    bytes = unname(file.info(file.path(root, code_relative))$size)
  ),
  code_manifest_path
)
write_csv(
  tibble::tibble(
    component = c("R", required_packages),
    version = c(
      as.character(getRversion()),
      vapply(
        required_packages,
        function(package) as.character(utils::packageVersion(package)),
        character(1)
      )
    )
  ),
  software_manifest_path
)
output_paths <- c(
  unname(paths),
  runtime_path,
  input_manifest_path,
  code_manifest_path,
  software_manifest_path
)
write_csv(
  tibble::tibble(
    relative_path = vapply(output_paths, relative_to_root, character(1)),
    sha256 = vapply(output_paths, sha256, character(1)),
    bytes = unname(file.info(output_paths)$size),
    producer = producer,
    r_version = as.character(getRversion())
  ),
  output_manifest_path
)

overall <- combined$verdict |>
  dplyr::filter(.data$domain == "Overall base-model diagnostic gate")
message(
  "H06-D-G2P-H02 production diagnostics: ",
  sum(overall$status == "ACCEPTABLE"),
  " of ",
  nrow(overall),
  " frames acceptable"
)
