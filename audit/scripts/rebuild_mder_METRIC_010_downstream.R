# Rebuild the shared Preparation 06 artifacts affected by METRIC-010.
#
# This script deliberately stops at prepared analysis inputs. It does not fit
# or refit a hypothesis model. Hypothesis-specific MDER updates remain owned
# by the corresponding hypothesis tasks.

Sys.setenv(TZ = "UTC")
options(stringsAsFactors = FALSE, warn = 2)

root <- normalizePath(".", winslash = "/", mustWork = TRUE)
if (!identical(as.character(getRversion()), "4.6.1")) {
  stop(
    "METRIC-010 downstream rebuild requires R 4.6.1; found ",
    as.character(getRversion()),
    call. = FALSE
  )
}

source("scripts/pipeline/paths_io.R")
source("scripts/pipeline/assertions.R")
source("scripts/pipeline/metric_display_registry.R")
source("scripts/pipeline/time_support.R")

source("scripts/pipeline/manuscript_prepared_data.R")
source("scripts/pipeline/build_manuscript_prepared_data.R")
source("scripts/pipeline/verify_manuscript_prepared_data_artifacts.R")

source("scripts/pipeline/site_solar_context.R")
source("scripts/pipeline/build_site_solar_context.R")
source("scripts/pipeline/verify_site_solar_context_artifacts.R")

source("scripts/pipeline/base_model_data.R")
source("scripts/pipeline/build_base_model_data.R")
source("scripts/pipeline/verify_base_model_data_artifacts.R")

source("scripts/pipeline/h01_model_data.R")
source("scripts/pipeline/build_h01_model_data.R")
source("scripts/pipeline/verify_h01_model_data_artifacts.R")

source("scripts/pipeline/h01_manuscript_prepared_adapter.R")
source("scripts/pipeline/build_h01_manuscript_prepared_data.R")
source("scripts/pipeline/verify_h01_manuscript_prepared_data_artifacts.R")

source("scripts/pipeline/preanalysis_comparison.R")
source("scripts/pipeline/build_preanalysis_comparison.R")
source("scripts/pipeline/verify_preanalysis_comparison_artifacts.R")

audit_root <- file.path(
  root,
  "artifacts",
  "08_diagnostics",
  "mder_METRIC-010",
  "downstream_rebuild"
)
dir.create(audit_root, recursive = TRUE, showWarnings = FALSE)

manifest_paths <- c(
  metric = file.path(root, "artifacts", "12_manifests", "metric_artifacts.csv"),
  manuscript_prepared = file.path(
    root,
    "artifacts",
    "12_manifests",
    "manuscript_prepared_data_artifacts.csv"
  ),
  site_context = file.path(
    root,
    "artifacts",
    "12_manifests",
    "site_solar_context_artifacts.csv"
  ),
  base_model = file.path(
    root,
    "artifacts",
    "12_manifests",
    "base_model_data_artifacts.csv"
  ),
  h01_main = file.path(
    root,
    "artifacts",
    "12_manifests",
    "H01_model_data_artifacts.csv"
  ),
  h01_gap_timing_unaware = file.path(
    root,
    "artifacts",
    "12_manifests",
    "H01_manuscript_prepared_data_artifacts.csv"
  ),
  preanalysis = file.path(
    root,
    "artifacts",
    "12_manifests",
    "preanalysis_comparison_artifacts.csv"
  ),
  normalization = file.path(
    root,
    "artifacts",
    "12_manifests",
    "model_input_normalization.csv"
  )
)

missing_manifests <- !file.exists(manifest_paths)
if (any(missing_manifests)) {
  stop(
    "Missing downstream manifest(s): ",
    paste(manifest_paths[missing_manifests], collapse = ", "),
    call. = FALSE
  )
}

hash_manifest_set <- function(paths, phase) {
  data.frame(
    phase = phase,
    artifact = names(paths),
    path = vapply(
      paths,
      function(path) sub(paste0("^", root, "/?"), "", path),
      character(1L)
    ),
    sha256 = vapply(paths, artifact_sha256, character(1L)),
    stringsAsFactors = FALSE
  )
}

before_hashes <- hash_manifest_set(manifest_paths, "before_METRIC_010_rebuild")
initial_pre_rebuild_sha256 <- c(
  metric = "7bb2830c695e5600f0877acca500a187a040fe727a029bdb069f69099abe4f43",
  manuscript_prepared =
    "af74cc9fa36e426222d9b5f2328e2261c00b14436feb8d86fbf137d0ff313267",
  site_context =
    "e641560c444259cbe03606e30ebd2abc1d3d048052303e421f462255e8387fbe",
  base_model =
    "142d1044dd7e6a566e45e3a5c56033b1e8251e100c0d7c7523564c824950a0e4",
  h01_main =
    "ea9d47f624a8777f8416447612bfcc2309cf2bac40fdf4fd5021c8767806dfbf",
  h01_gap_timing_unaware =
    "cb47b3678146604aadca875a96f79909e2d73355162683ff0603f038f3b31a25",
  preanalysis =
    "1119940d2c564f464d7fd09e37b65c1815d0e6f22e5c6051f682eab22c6a97dd",
  normalization =
    "e3d484711abb54f69d63ff302e5a0329efda3fd0a8c85feaf9cc4f850005c9ab"
)

context_path <- file.path(
  root,
  "artifacts",
  "06_model_data",
  "context",
  "site_solar_context.rds"
)
old_context <- readRDS(context_path)

strip_provenance_attributes <- function(data) {
  retained <- attributes(data)[c("names", "row.names", "class")]
  attributes(data) <- retained
  data
}
old_context_values <- strip_provenance_attributes(old_context)

message("Rebuilding and verifying the gap-timing-unaware prepared data")
gap_build <- build_manuscript_prepared_data(root = root, output_root = root)
gap_verification <- verify_manuscript_prepared_data_artifacts(
  root = root,
  output_root = root
)
stopifnot(
  identical(gap_verification$status, "PASS")
)

supplemental_dates <- c(
  manuscript_prepared_participant_day = file.path(
    root,
    "artifacts",
    "06_model_data",
    "scenarios",
    manuscript_prepared_scenario_id(),
    "participant_day_metrics.rds"
  )
)

message("Repinning site/daylight context to the new metric identities")
site_build <- build_site_solar_context_artifacts(
  root = root,
  supplemental_date_paths = supplemental_dates,
  input_root = root
)
site_verification <- verify_site_solar_context_artifacts(
  root = root,
  supplemental_date_paths = supplemental_dates,
  input_root = root
)
stopifnot(
  identical(site_verification$status, "PASS")
)

new_context <- readRDS(context_path)
new_context_values <- strip_provenance_attributes(new_context)
context_values_unchanged <- identical(old_context_values, new_context_values)
if (!context_values_unchanged) {
  stop(
    "Site/daylight context values changed during an identity-only repin",
    call. = FALSE
  )
}

message("Rebuilding and verifying the shared base-model data")
base_build <- build_base_model_data_artifacts(root = root, output_root = root)
base_verification <- verify_base_model_data_artifacts(
  root = root,
  output_root = root
)
stopifnot(
  identical(base_build$status, "PASS"),
  identical(base_verification$status, "PASS")
)

message("Rebuilding and verifying H01 prepared inputs without fitting models")
h01_build <- build_h01_model_data_artifacts(root = root, output_root = root)
h01_verification <- verify_h01_model_data_artifacts(
  root = root,
  output_root = root
)
stopifnot(
  identical(h01_build$status, "PASS_WITH_DECLARED_UNAVAILABLE_SCENARIO"),
  identical(
    h01_verification$status,
    "PASS_WITH_DECLARED_UNAVAILABLE_SCENARIO"
  )
)

h01_gap_build <- build_h01_manuscript_prepared_data_artifacts(
  root = root,
  output_root = root
)
h01_gap_verification <- verify_h01_manuscript_prepared_data_artifacts(
  root = root,
  output_root = root
)
expected_h01_gap_status <- paste0(
  "PASS_WITH_DECLARED_UNAVAILABLE_SUPPORT_",
  "AND_PAIRED_PARTICIPANT_METRICS"
)
stopifnot(
  identical(h01_gap_build$status, expected_h01_gap_status),
  identical(h01_gap_verification$status, expected_h01_gap_status)
)

normalization_sha256 <- artifact_sha256(manifest_paths[["normalization"]])
base_sha256 <- artifact_sha256(manifest_paths[["base_model"]])

message("Rebuilding and verifying the descriptive pre-analysis comparison")
preanalysis_build <- build_preanalysis_comparison_artifacts(
  root = root,
  output_root = root,
  expected_normalization_manifest_sha256 = normalization_sha256,
  expected_base_manifest_sha256 = base_sha256
)
preanalysis_verification <- verify_preanalysis_comparison_artifacts(
  root = root,
  output_root = root,
  expected_normalization_manifest_sha256 = normalization_sha256,
  expected_base_manifest_sha256 = base_sha256
)
stopifnot(
  identical(preanalysis_build$status, "PASS"),
  identical(preanalysis_verification$status, "PASS")
)

after_hashes <- hash_manifest_set(manifest_paths, "after_METRIC_010_rebuild")
manifest_comparison <- merge(
  before_hashes,
  after_hashes,
  by = c("artifact", "path"),
  suffixes = c("_before", "_after"),
  sort = FALSE
)
manifest_comparison$changed <-
  manifest_comparison$sha256_before != manifest_comparison$sha256_after
manifest_comparison$sha256_initial_pre_rebuild <-
  unname(initial_pre_rebuild_sha256[manifest_comparison$artifact])
manifest_comparison$changed_from_initial_pre_rebuild <-
  manifest_comparison$sha256_initial_pre_rebuild !=
    manifest_comparison$sha256_after

context_check <- data.frame(
  check = c(
    "site_context_rows",
    "site_context_columns",
    "site_context_values_unchanged",
    "site_context_manifest_rebuilt"
  ),
  value = c(
    nrow(new_context),
    ncol(new_context),
    context_values_unchanged,
    manifest_comparison$changed[
      manifest_comparison$artifact == "site_context"
    ]
  ),
  stringsAsFactors = FALSE
)

utils::write.csv(
  manifest_comparison,
  file.path(audit_root, "manifest_comparison.csv"),
  row.names = FALSE,
  na = ""
)
utils::write.csv(
  context_check,
  file.path(audit_root, "site_context_value_check.csv"),
  row.names = FALSE,
  na = ""
)

output_paths <- c(
  manifest_comparison = file.path(audit_root, "manifest_comparison.csv"),
  site_context_value_check = file.path(
    audit_root,
    "site_context_value_check.csv"
  )
)
rebuild_manifest <- data.frame(
  artifact = names(output_paths),
  path = vapply(
    output_paths,
    function(path) sub(paste0("^", root, "/?"), "", path),
    character(1L)
  ),
  sha256 = vapply(output_paths, artifact_sha256, character(1L)),
  bytes = as.numeric(file.info(output_paths)$size),
  producer = "audit/scripts/rebuild_mder_METRIC_010_downstream.R",
  r_version = as.character(getRversion()),
  status = "PASS",
  stringsAsFactors = FALSE
)
utils::write.csv(
  rebuild_manifest,
  file.path(audit_root, "rebuild_manifest.csv"),
  row.names = FALSE,
  na = ""
)

message(
  "METRIC-010 downstream rebuild PASS; manifest SHA-256: ",
  artifact_sha256(file.path(audit_root, "rebuild_manifest.csv"))
)
