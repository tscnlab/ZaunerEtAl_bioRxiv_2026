# Reseal the METRIC-010 integration summary after classifying non-estimable
# support rows. This script performs no fitting or resampling.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
base::source(file.path(root, "scripts/pipeline/paths_io.R"))

stopifnot(identical(as.character(getRversion()), "4.6.1"))

producer <- "scripts/hypotheses/H01/reseal_h01_mder_METRIC010_integration_summary.R"
integration_root <- file.path(
  root,
  "audit/hypotheses/H01/mder_METRIC-010/production_integration"
)
support_path <- file.path(
  integration_root,
  "H01_METRIC-010_support_disposition.csv"
)
summary_path <- file.path(
  integration_root,
  "H01_METRIC-010_production_integration_summary.csv"
)
manifest_path <- file.path(
  integration_root,
  "H01_METRIC-010_production_integration_manifest.csv"
)
production_manifest_path <- file.path(
  root,
  paste0(
    "audit/hypotheses/H01/mder_METRIC-010/bootstrap_production/",
    "H01_METRIC-010_bootstrap_production_manifest.csv"
  )
)

support <- readr::read_csv(
  support_path,
  show_col_types = FALSE,
  progress = FALSE
)
summary <- readr::read_csv(
  summary_path,
  show_col_types = FALSE,
  progress = FALSE
)
manifest <- readr::read_csv(
  manifest_path,
  show_col_types = FALSE,
  progress = FALSE
)
production_manifest <- readr::read_csv(
  production_manifest_path,
  show_col_types = FALSE,
  progress = FALSE
)

stopifnot(
  nrow(summary) == 1L,
  nrow(support) == 544L,
  sum(is.na(support$disposition_changed)) == 32L,
  !any(support$disposition_changed, na.rm = TRUE),
  all(is.na(support$gate_supported) == is.na(support$current_supported)),
  all(
    support$gate_supported[!is.na(support$gate_supported)] ==
      support$current_supported[!is.na(support$current_supported)]
  )
)

summary$support_disposition_changes <- sum(
  support$disposition_changed,
  na.rm = TRUE
)
write_csv_artifact(summary, summary_path, producer = producer)

summary_relative <- substring(summary_path, nchar(root) + 2L)
summary_row <- which(manifest$path == summary_relative)
stopifnot(length(summary_row) == 1L)
manifest$sha256[summary_row] <- artifact_sha256(summary_path)
manifest$bytes[summary_row] <- as.numeric(file.info(summary_path)$size)
manifest$producer[summary_row] <- producer
manifest$r_version[summary_row] <- as.character(getRversion())
readr::write_csv(manifest, manifest_path, na = "")

production_files <- file.path(root, production_manifest$path)
stopifnot(all(file.exists(production_files)))
production_hashes <- vapply(
  production_files,
  artifact_sha256,
  character(1)
)
production_drift <- production_hashes != production_manifest$sha256
production_test_relative <- paste0(
  "tests/hypotheses/H01/",
  "test_h01_mder_METRIC010_production.R"
)
stopifnot(
  all(production_manifest$path[production_drift] == production_test_relative)
)
production_test_row <- which(
  production_manifest$path == production_test_relative
)
stopifnot(length(production_test_row) == 1L)
production_manifest$sha256[production_test_row] <-
  production_hashes[production_test_row]
production_manifest$bytes[production_test_row] <- as.numeric(
  file.info(production_files[production_test_row])$size
)
production_manifest$producer[production_test_row] <- producer
production_manifest$r_version[production_test_row] <- as.character(
  getRversion()
)
readr::write_csv(production_manifest, production_manifest_path, na = "")

stopifnot(
  summary$support_disposition_changes == 0L,
  identical(
    manifest$sha256[summary_row],
    artifact_sha256(summary_path)
  ),
  identical(
    production_manifest$sha256[production_test_row],
    artifact_sha256(file.path(root, production_test_relative))
  )
)

message("Resealed H01 METRIC-010 production integration summary: 0 changes")
