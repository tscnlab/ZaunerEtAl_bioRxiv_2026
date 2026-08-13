#!/usr/bin/env Rscript

# Qualify the 2026-08-11 shared Preparation 06 repin for the already-fitted
# H06_daily temporal amendment. This script reconstructs all six model frames
# in memory from the current shared inputs and compares them, exactly, with the
# frozen H06_daily production frames. It does not write model frames or refit a
# model, and it does not inspect or summarize MDER.

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

required_packages <- c("digest", "dplyr", "readr", "tibble")
stopifnot(
  identical(as.character(getRversion()), "4.6.1"),
  all(vapply(required_packages, requireNamespace, logical(1), quietly = TRUE))
)

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
  paste0(
    "scripts/hypotheses/H06_daily/",
    "h06_daily_temporal_h02_production_data.R"
  )
))

roots <- h06d_artifact_roots(root)
producer <- paste0(
  "scripts/hypotheses/H06_daily/",
  "qualify_h06_daily_temporal_h02_upstream_repin.R"
)
sha256 <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE)
}
relative_to_root <- function(path) {
  substring(path, nchar(root) + 2L)
}
write_csv <- function(data, path) {
  readr::write_csv(data, path, na = "")
  invisible(path)
}

current_inputs <- tibble::tribble(
  ~input_id, ~relative_path, ~expected_sha256, ~role,
  "primary_near_eye_30_minute",
  "artifacts/06_model_data/base/metrics_glasses_30_minute_context.rds",
  "0ad121f104af7ae885016e4dd82f62e94e94daabd01128ed8c76407bfbc54249",
  "current shared primary near-eye grid",
  "primary_chest_30_minute",
  "artifacts/06_model_data/base/metrics_chest_30_minute_context.rds",
  "9a8708fa453e7a7f0fc0c536553c0b5c76c4a4b38e4502f8952d6956b25fcf0e",
  "current shared primary chest grid",
  "gap_timing_unaware_30_minute",
  paste0(
    "artifacts/06_model_data/scenarios/",
    "manuscript_prepared_data/thirty_minute_data.rds"
  ),
  "813453681cb24ca88cdf5f6b833824649f0e24e9f3bed5af80aad1c4f06fffdc",
  "unchanged gap-timing-unaware grid",
  "temporal_provenance",
  "artifacts/06_model_data/temporal_provenance/wall_outcome_links.rds",
  "69232e8f7bdfbf379e7f92a220d2ecad893bce38e9ec57add313f5545e62829a",
  "unchanged wall-to-true-time provenance",
  "exercise_diary",
  "artifacts/06_model_data/normalized_inputs/exercisediary.rds",
  "5bffe44cdd9c65f3d1dc20575d10b3f0a403577f3cf9109e83cfea95a2ae7107",
  "unchanged corrected daily activity context",
  "sleep_diary",
  "artifacts/06_model_data/normalized_inputs/sleepdiaries.rds",
  "110819d74503c895170552c1f2214aca83de51cadd23bde7525aa821ee0b0e15",
  "unchanged day-type and sleep context",
  "site_display_registry",
  "config/site_display_registry.csv",
  "3d669d459ecc27d3154bbb5ff5b0d64cb510805d486b45264443228c44a6d809",
  "unchanged submitted site registry",
  "base_model_data_manifest",
  "artifacts/12_manifests/base_model_data_artifacts.csv",
  "6cfbfb18a2f6b1e31613e3fba803c3fbf64eb63e37155ae4fffd437a213b3ad0",
  "current shared base-model manifest",
  "metric_manifest",
  "artifacts/12_manifests/metric_artifacts.csv",
  "7bb2830c695e5600f0877acca500a187a040fe727a029bdb069f69099abe4f43",
  "current shared metric manifest; MDER not used here",
  "preparation_06_gate",
  "audit/decisions/preparation06_current_base_model_gate.md",
  "789c1b2e0e52f1a22ed407096f0ebe1c239ee1c954197a880c19a9c32780626e",
  "current shared downstream gate",
  "frozen_frame_output_manifest",
  paste0(
    "artifacts/12_manifests/H06_daily/",
    "H06_daily_temporal_h02_production_frame_output_manifest.csv"
  ),
  "8463445ac682272a59fda9617a2f77033d6c3ef54b3a5b29ea4f67eb1bdfa6d9",
  "frozen H06_daily production-frame bundle"
)
current_inputs <- current_inputs |>
  dplyr::mutate(
    observed_sha256 = vapply(
      file.path(root, .data$relative_path),
      sha256,
      character(1)
    ),
    hash_match = .data$observed_sha256 == .data$expected_sha256,
    bytes = unname(file.info(file.path(root, .data$relative_path))$size)
  )
if (!all(current_inputs$hash_match)) {
  failed <- current_inputs$input_id[!current_inputs$hash_match]
  h06d_abort("Upstream-repin input mismatch: %s", paste(failed, collapse = ", "))
}

frozen_manifest_path <- file.path(
  root,
  paste0(
    "artifacts/12_manifests/H06_daily/",
    "H06_daily_temporal_h02_production_frame_output_manifest.csv"
  )
)
frozen_manifest <- readr::read_csv(
  frozen_manifest_path,
  show_col_types = FALSE,
  na = ""
) |>
  dplyr::mutate(
    observed_sha256 = vapply(
      file.path(root, .data$relative_path),
      sha256,
      character(1)
    ),
    hash_match = .data$sha256 == .data$observed_sha256
  )
if (!all(frozen_manifest$hash_match)) {
  h06d_abort("A frozen H06_daily production-frame artifact changed")
}

fresh_frames <- h06d_h02_production_frames(root)
run_ids <- names(fresh_frames)
frame_comparison <- dplyr::bind_rows(lapply(run_ids, function(run_id) {
  frozen_path <- file.path(
    roots$model_data,
    paste0(
      "H06_daily_temporal_h02_production__",
      run_id,
      "__frame.rds"
    )
  )
  frozen <- readRDS(frozen_path)
  comparison <- all.equal(
    fresh_frames[[run_id]],
    frozen,
    tolerance = 0,
    check.attributes = TRUE
  )
  tibble::tibble(
    run_id = run_id,
    current_reconstruction_rows = nrow(fresh_frames[[run_id]]),
    frozen_rows = nrow(frozen),
    current_reconstruction_columns = ncol(fresh_frames[[run_id]]),
    frozen_columns = ncol(frozen),
    exact_row_value_and_attribute_identity = isTRUE(comparison),
    comparison_detail = if (isTRUE(comparison)) {
      "exact"
    } else {
      paste(comparison, collapse = " | ")
    },
    mder_read_or_used = FALSE,
    frame_written = FALSE,
    model_refitted = FALSE,
    qualification = if (isTRUE(comparison)) "PASS" else "FAIL"
  )
}))
if (!all(frame_comparison$exact_row_value_and_attribute_identity)) {
  h06d_abort("Current shared inputs do not reproduce every frozen frame")
}

drift_registry <- tibble::tribble(
  ~relative_path, ~historical_sha256, ~current_sha256, ~temporal_role,
  "artifacts/06_model_data/base/metrics_glasses_30_minute_context.rds",
  "afa5a23308744ae495ef07a521c99e11bd7296aa855c5cb773f71f2b68eeb8e5",
  "0ad121f104af7ae885016e4dd82f62e94e94daabd01128ed8c76407bfbc54249",
  "direct primary near-eye input; selected temporal fields reproduce exactly",
  "artifacts/06_model_data/base/metrics_chest_30_minute_context.rds",
  "01a4a85e5ead5b30219f969c64d50b94a2bebf84b60cc4006badbc3c3c9513a2",
  "9a8708fa453e7a7f0fc0c536553c0b5c76c4a4b38e4502f8952d6956b25fcf0e",
  "direct complementary chest input; selected temporal fields reproduce exactly",
  "artifacts/12_manifests/base_model_data_artifacts.csv",
  "142d1044dd7e6a566e45e3a5c56033b1e8251e100c0d7c7523564c824950a0e4",
  "6cfbfb18a2f6b1e31613e3fba803c3fbf64eb63e37155ae4fffd437a213b3ad0",
  "shared manifest repin; no model-frame difference",
  "artifacts/12_manifests/metric_artifacts.csv",
  "6ec3185620d921e1f81b8464e850249613deb823988187d58794b3471303f4e8",
  "7bb2830c695e5600f0877acca500a187a040fe727a029bdb069f69099abe4f43",
  "shared MDER-era repin; MDER is not read or used by the temporal frame",
  "audit/decisions/preparation06_current_base_model_gate.md",
  "4bc007db330b953a090985765b090d2a166515bbf056f4a56d3c44ea01426944",
  "789c1b2e0e52f1a22ed407096f0ebe1c239ee1c954197a880c19a9c32780626e",
  "shared gate repin; current downstream authorization"
) |>
  dplyr::mutate(
    current_hash_verified = vapply(
      file.path(root, .data$relative_path),
      sha256,
      character(1)
    ) == .data$current_sha256,
    qualification = "PASS_NO_REFIT"
  )
stopifnot(all(drift_registry$current_hash_verified))

comparison_path <- file.path(
  roots$diagnostics,
  "H06_daily_temporal_h02_upstream_repin_frame_comparison.csv"
)
drift_path <- file.path(
  roots$diagnostics,
  "H06_daily_temporal_h02_upstream_repin_drift_registry.csv"
)
write_csv(frame_comparison, comparison_path)
write_csv(drift_registry, drift_path)

input_manifest_path <- file.path(
  roots$manifests,
  "H06_daily_temporal_h02_upstream_repin_input_manifest.csv"
)
code_manifest_path <- file.path(
  roots$manifests,
  "H06_daily_temporal_h02_upstream_repin_code_manifest.csv"
)
software_manifest_path <- file.path(
  roots$manifests,
  "H06_daily_temporal_h02_upstream_repin_software_manifest.csv"
)
output_manifest_path <- file.path(
  roots$manifests,
  "H06_daily_temporal_h02_upstream_repin_output_manifest.csv"
)
write_csv(
  current_inputs |>
    dplyr::transmute(
      input_id,
      relative_path,
      sha256 = .data$observed_sha256,
      bytes,
      role
    ),
  input_manifest_path
)
code_relative <- c(
  "scripts/hypotheses/H06_daily/h06_daily_contract.R",
  "scripts/hypotheses/H06_daily/h06_daily_data.R",
  paste0(
    "scripts/hypotheses/H06_daily/",
    "h06_daily_temporal_h02_production_data.R"
  ),
  producer
)
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
  comparison_path,
  drift_path,
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

message(
  "Qualified the shared repin: all six current reconstructions exactly ",
  "match the frozen H06_daily temporal frames; no MDER use or model refit"
)
