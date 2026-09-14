# Reseal the five active aggregate rows in the H01 bootstrap manifest after
# the approved METRIC-010 MDER replacement. No scientific value is computed.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
source(file.path(root, "scripts/pipeline/paths_io.R"))

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("H01 METRIC-010 manifest reseal requires R 4.6.1", call. = FALSE)
}

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(tibble)
})

approval <- Sys.getenv("H01_MDER_INTEGRATION_APPROVAL", unset = "")
if (!identical(approval, "approved_2026-08-31")) {
  stop("Missing exact H01 METRIC-010 integration approval token", call. = FALSE)
}

producer <- paste0(
  "scripts/hypotheses/H01/",
  "reseal_h01_mder_METRIC010_bootstrap_manifest.R"
)
manifest_path <- file.path(
  root,
  "artifacts/12_manifests/H01_response_family_bootstrap_production_artifacts.csv"
)
expected_pre_sha256 <-
  "55af5644f35c8e81eaed7bb3b4ec7486ce070c6e1012181afe1a5d5a985431ea"
if (!identical(artifact_sha256(manifest_path), expected_pre_sha256)) {
  stop("H01 bootstrap manifest pre-integration identity drift", call. = FALSE)
}

integration_root <- file.path(
  root,
  "audit/hypotheses/H01/mder_METRIC-010/production_integration"
)
historical_path <- file.path(
  integration_root,
  "preintegration_H01_response_family_bootstrap_production_artifacts.csv"
)
if (file.exists(historical_path)) {
  if (!identical(artifact_sha256(historical_path), expected_pre_sha256)) {
    stop("Existing historical bootstrap manifest differs", call. = FALSE)
  }
} else if (!file.copy(
  manifest_path,
  historical_path,
  overwrite = FALSE,
  copy.mode = TRUE
)) {
  stop("Could not preserve the historical bootstrap manifest", call. = FALSE)
}

manifest <- readr::read_csv(
  manifest_path,
  show_col_types = FALSE,
  progress = FALSE
)
dependent_paths <- c(
  "artifacts/08_diagnostics/H01/H01_model_diagnostics.csv",
  "artifacts/08_diagnostics/H01/H01_r2_bootstrap_audit.csv",
  "artifacts/08_diagnostics/H01/H01_r2_bootstrap_failures.csv",
  "artifacts/09_tables/H01/H01_r2_bootstrap_summaries.csv",
  "artifacts/09_tables/H01/H01_r2_point_summaries.csv"
)
index <- match(dependent_paths, manifest$path)
stopifnot(!anyNA(index), length(index) == 5L)
files <- file.path(root, dependent_paths)
before <- manifest[index, c("path", "sha256", "bytes")]
manifest$sha256[index] <- unname(vapply(
  files,
  artifact_sha256,
  character(1)
))
manifest$bytes[index] <- as.numeric(file.info(files)$size)
manifest$producer[index] <- producer
write_csv_artifact(manifest, manifest_path, producer = producer)

all_files <- file.path(root, manifest$path)
stopifnot(
  all(file.exists(all_files)),
  identical(
    unname(vapply(all_files, artifact_sha256, character(1))),
    unname(manifest$sha256)
  )
)
after <- manifest[index, c("path", "sha256", "bytes")]
transition <- before |>
  rename(sha256_before = "sha256", bytes_before = "bytes") |>
  left_join(
    after |>
      rename(sha256_after = "sha256", bytes_after = "bytes"),
    by = "path",
    relationship = "one-to-one"
  ) |>
  mutate(
    transition = "METRIC-010_ACTIVE_AGGREGATE_RESEAL",
    producer = producer,
    r_version = as.character(getRversion())
  )
transition_path <- file.path(
  integration_root,
  "H01_METRIC-010_response_family_manifest_transition.csv"
)
write_csv_artifact(transition, transition_path, producer = producer)

message("H01 METRIC-010 dependent bootstrap manifest resealed: 5 rows")
