# Standalone COMPUTE-001 checks for the non-inferential H02 dominance pilot.

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

pilot_id <- "dominance_pilot_50rep"
pilot_table_directory <- file.path(
  root,
  "artifacts/09_tables/H02/pilots",
  pilot_id
)
pilot_manifest_directory <- file.path(
  root,
  "artifacts/12_manifests/H02/pilots",
  pilot_id
)
read_pilot <- function(name) {
  readr::read_csv(
    file.path(pilot_table_directory, name),
    show_col_types = FALSE
  )
}

message("Testing the separate non-inferential dominance pilot")
execution <- read_pilot("dominance_execution_summary.csv")
allocation <- read_pilot("dominance_summary.csv")
comparison <- read_pilot("dominance_comparison_summary.csv")
stopifnot(
  nrow(execution) == 2L,
  all(execution$execution_mode == "pilot"),
  all(execution$bootstrap_replicates == 50L),
  all(execution$bootstrap_failed_replicates == 0L),
  all(execution$noninferential_pilot),
  all(execution$subset_fit_elapsed_seconds > 0),
  all(execution$bootstrap_elapsed_seconds > 0),
  all(execution$run_elapsed_seconds > 0),
  all(execution$maximum_r_heap_megabytes > 0),
  all(execution$projected_2000rep_run_seconds > 0),
  nrow(allocation) == 8L,
  nrow(comparison) == 8L,
  all(allocation$execution_mode == "pilot"),
  all(comparison$execution_mode == "pilot"),
  all(allocation$bootstrap_replicates == 50L),
  all(comparison$bootstrap_replicates == 50L),
  all(grepl("NON-INFERENTIAL", allocation$inferential_role)),
  all(grepl("NON-INFERENTIAL", comparison$inferential_role))
)

manifest <- readr::read_csv(
  file.path(pilot_manifest_directory, "H02_dominance_pilot_manifest.csv"),
  show_col_types = FALSE
)
stopifnot(nrow(manifest) >= 12L)
for (i in seq_len(nrow(manifest))) {
  path <- file.path(root, manifest$path[i])
  stopifnot(
    file.exists(path),
    identical(artifact_sha256(path), manifest$sha256[i])
  )
}

production_manifest <- file.path(
  root,
  "artifacts/12_manifests/H02/H02_dominance_manifest.csv"
)
stopifnot(
  file.exists(production_manifest),
  all(grepl(
    paste0("/pilots/", pilot_id, "/"),
    manifest$path,
    fixed = TRUE
  ))
)

message("All H02 dominance-pilot tests passed")
