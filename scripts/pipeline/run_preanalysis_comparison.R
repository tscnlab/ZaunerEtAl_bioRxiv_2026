# Rebuild and independently verify the pre-analysis comparison gate.

#####
# Step 1: Parse exact Preparation 06 hashes
#####

arguments <- commandArgs(trailingOnly = TRUE)
normalization_argument <- arguments[
  grepl("^--expected-normalization-sha256=", arguments)
]
base_argument <- arguments[
  grepl("^--expected-base-sha256=", arguments)
]
if (
  length(arguments) != 2L ||
    length(normalization_argument) != 1L ||
    length(base_argument) != 1L
) {
  stop(
    paste(
      "Supply exactly `--expected-normalization-sha256=<64 hex>` and",
      "`--expected-base-sha256=<64 hex>`."
    ),
    call. = FALSE
  )
}
expected_normalization_sha256 <- sub(
  "^--expected-normalization-sha256=",
  "",
  normalization_argument
)
expected_base_sha256 <- sub(
  "^--expected-base-sha256=",
  "",
  base_argument
)
if (
  !grepl("^[0-9a-f]{64}$", expected_normalization_sha256) ||
    !grepl("^[0-9a-f]{64}$", expected_base_sha256)
) {
  stop("Both expected hashes must be lowercase 64-character SHA-256 values.")
}

#####
# Step 2: Load the isolated builder and verifier
#####

Sys.setenv(TZ = "UTC")
options(stringsAsFactors = FALSE, warn = 2)

source("scripts/pipeline/paths_io.R")
source("scripts/pipeline/assertions.R")
source("scripts/pipeline/metric_display_registry.R")
source("scripts/pipeline/preanalysis_comparison.R")
source("scripts/pipeline/build_preanalysis_comparison.R")
source("scripts/pipeline/verify_preanalysis_comparison_artifacts.R")

root <- project_root()

#####
# Step 3: Build and verify
#####

build <- build_preanalysis_comparison_artifacts(
  root = root,
  output_root = root,
  expected_normalization_manifest_sha256 = expected_normalization_sha256,
  expected_base_manifest_sha256 = expected_base_sha256
)
verification <- verify_preanalysis_comparison_artifacts(
  root = root,
  output_root = root,
  expected_normalization_manifest_sha256 = expected_normalization_sha256,
  expected_base_manifest_sha256 = expected_base_sha256
)
if (
  !identical(build$status, "PASS") ||
    !identical(verification$status, "PASS")
) {
  stop("Pre-analysis comparison gate did not reach verified PASS.")
}
message(
  "Pre-analysis comparison gate PASS: ",
  build$paths$manifest
)
