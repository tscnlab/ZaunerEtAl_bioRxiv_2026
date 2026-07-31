options(warn = 2)

source("scripts/pipeline/paths_io.R")
source("scripts/pipeline/assertions.R")
source("scripts/pipeline/site_solar_context.R")
source("scripts/pipeline/build_site_solar_context.R")
source("scripts/pipeline/verify_site_solar_context_artifacts.R")

message("Building isolated main-analysis inputs for independent verification")
test_root <- tempfile("nathealth-site-solar-verify-")
dir.create(test_root, recursive = TRUE)
on.exit(unlink(test_root, recursive = TRUE), add = TRUE)

project_input_root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
metric_paths <- site_solar_default_metric_paths(project_input_root)
site_metadata_path <- file.path(
  project_input_root,
  "config",
  "site_metadata.csv"
)
initial_build <- build_site_solar_context_artifacts(
  root = test_root,
  site_metadata_path = site_metadata_path,
  metric_paths = metric_paths,
  input_root = project_input_root
)

message("Checking a complete independent verification pass")
verified <- verify_site_solar_context_artifacts(
  root = test_root,
  site_metadata_path = site_metadata_path,
  metric_paths = metric_paths,
  input_root = project_input_root,
  stop_on_failure = FALSE
)
stopifnot(
  verified$status == "PASS",
  verified$site_dates == nrow(initial_build$date_domain),
  verified$sites == 9L,
  verified$dst_transition_site_dates == 4L,
  verified$join_audit_rows == 6L,
  verified$unmatched_rows == 0L,
  verified$manifest_rows == 3L
)

refresh_test_manifest_row <- function(root, artifact_type, artifact_path) {
  paths <- p06_site_solar_paths(root)
  manifest <- readr::read_csv(
    paths$manifest,
    show_col_types = FALSE,
    progress = FALSE
  )
  target <- manifest$artifact_type == artifact_type
  manifest$sha256[target] <- artifact_sha256(artifact_path)
  manifest$bytes[target] <- file.info(artifact_path)$size
  readr::write_csv(manifest, paths$manifest, na = "")
  invisible(paths$manifest)
}

message("Checking scientific CSV tampering beyond refreshed hashes")
paths <- p06_site_solar_paths(test_root)
context_csv <- readr::read_csv(
  paths$context_csv,
  show_col_types = FALSE,
  progress = FALSE
)
context_csv$solar_noon_wall_minute[[1L]] <-
  context_csv$solar_noon_wall_minute[[1L]] + 1
readr::write_csv(context_csv, paths$context_csv, na = "")
refresh_test_manifest_row(
  test_root,
  "site_solar_context_csv",
  paths$context_csv
)
tampered_csv <- verify_site_solar_context_artifacts(
  root = test_root,
  site_metadata_path = site_metadata_path,
  metric_paths = metric_paths,
  input_root = project_input_root,
  stop_on_failure = FALSE
)
stopifnot(
  tampered_csv$status == "FAIL",
  grepl("context CSV differs", tampered_csv$error, fixed = TRUE)
)

message("Checking contextual-role tampering beyond refreshed hashes")
csv_restore_build <- build_site_solar_context_artifacts(
  root = test_root,
  site_metadata_path = site_metadata_path,
  metric_paths = metric_paths,
  input_root = project_input_root
)
context_rds <- readRDS(paths$context_rds)
context_rds$solar_noon_role[[1L]] <- "predictor"
saveRDS(context_rds, paths$context_rds, version = 3, compress = "xz")
refresh_test_manifest_row(
  test_root,
  "site_solar_context_rds",
  paths$context_rds
)
tampered_role <- verify_site_solar_context_artifacts(
  root = test_root,
  site_metadata_path = site_metadata_path,
  metric_paths = metric_paths,
  input_root = project_input_root,
  stop_on_failure = FALSE
)
stopifnot(
  tampered_role$status == "FAIL",
  grepl(
    "independent solar reconstruction",
    tampered_role$error,
    fixed = TRUE
  )
)

message("Restoring and rechecking the isolated main-analysis artifacts")
role_restore_build <- build_site_solar_context_artifacts(
  root = test_root,
  site_metadata_path = site_metadata_path,
  metric_paths = metric_paths,
  input_root = project_input_root
)
restored <- verify_site_solar_context_artifacts(
  root = test_root,
  site_metadata_path = site_metadata_path,
  metric_paths = metric_paths,
  input_root = project_input_root,
  stop_on_failure = FALSE
)
stopifnot(restored$status == "PASS")

message("Independent site/solar artifact verifier tests passed")
