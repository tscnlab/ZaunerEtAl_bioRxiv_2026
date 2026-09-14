#!/usr/bin/env Rscript

stopifnot(identical(as.character(getRversion()), "4.6.1"))
root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
setwd(root)
source(file.path(root, "scripts/pipeline/paths_io.R"))
evidence_dir <- file.path(
  root,
  "audit/hypotheses/H01/report017_order32j_no_render_finalization"
)
manifest <- read.csv(
  "artifacts/12_manifests/H01_worker_artifacts.csv",
  stringsAsFactors = FALSE,
  check.names = FALSE
)
stopifnot(nrow(manifest) == 1659L, !anyDuplicated(manifest$path))
exists <- file.exists(manifest$path) & !dir.exists(manifest$path)
current_sha256 <- rep(NA_character_, nrow(manifest))
current_bytes <- rep(NA_real_, nrow(manifest))
current_sha256[exists] <- vapply(
  manifest$path[exists],
  artifact_sha256,
  character(1)
)
current_bytes[exists] <- as.numeric(file.info(manifest$path[exists])$size)
status <- ifelse(
  !exists,
  "MISSING",
  ifelse(
    manifest$sha256 == current_sha256 & manifest$bytes == current_bytes,
    "PASS_LIVE_EXACT",
    "HASH_OR_SIZE_MISMATCH"
  )
)
audit <- data.frame(
  path = manifest$path,
  expected_sha256 = manifest$sha256,
  current_sha256 = current_sha256,
  expected_bytes = manifest$bytes,
  current_bytes = current_bytes,
  status = status,
  stringsAsFactors = FALSE
)
mismatches <- audit[audit$status != "PASS_LIVE_EXACT", , drop = FALSE]
expected_mismatches <- c(
  "_build/nathealth/audit/hypotheses/H01/H01_analysis_preparation.html",
  "_build/nathealth/audit/hypotheses/H01/H01_analysis_preparation.qmd",
  "_build/nathealth/notebooks/hypotheses/H01.html",
  "_quarto-nathealth.yml",
  "artifacts/12_manifests/H01/H01_preparation_report_manifest.csv",
  "scripts/hypotheses/H01/build_h01_preparation_report_manifest.R"
)
stopifnot(identical(sort(mismatches$path), sort(expected_mismatches)))
mismatches$classification <- ifelse(
  mismatches$path %in% c(
    "_build/nathealth/notebooks/hypotheses/H01.html",
    "_quarto-nathealth.yml"
  ),
  "ACCEPTED_HISTORICAL_TRANSITION",
  "AUTHORIZED_DIRECT_RESEAL_WITHHELD_AFTER_NEW_GATE_FAILURE"
)
write.csv(
  mismatches,
  file.path(evidence_dir, "order32j_worker_manifest_mismatches_at_stop.csv"),
  row.names = FALSE,
  na = ""
)
summary <- data.frame(
  total_rows = nrow(audit),
  live_exact = sum(audit$status == "PASS_LIVE_EXACT"),
  mismatches = nrow(mismatches),
  historical = sum(
    mismatches$classification == "ACCEPTED_HISTORICAL_TRANSITION"
  ),
  withheld_direct_reseal = sum(
    mismatches$classification ==
      "AUTHORIZED_DIRECT_RESEAL_WITHHELD_AFTER_NEW_GATE_FAILURE"
  ),
  stringsAsFactors = FALSE
)
write.csv(
  summary,
  file.path(evidence_dir, "order32j_worker_manifest_summary_at_stop.csv"),
  row.names = FALSE,
  na = ""
)
cat(sprintf(
  "worker_at_stop=%d/%d exact; mismatches=%d historical=%d withheld=%d\n",
  summary$live_exact,
  summary$total_rows,
  summary$mismatches,
  summary$historical,
  summary$withheld_direct_reseal
))
