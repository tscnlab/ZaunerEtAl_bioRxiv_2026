#!/usr/bin/env Rscript

# Bounded, non-scientific evidence seal for REPORT-017 order 32a.
# This script writes only inside the order-32a evidence directory.

stopifnot(identical(as.character(getRversion()), "4.6.1"))

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
setwd(root)

evidence_relative <-
  "audit/hypotheses/H01/report017_order32a_verifier_repair"
evidence_dir <- normalizePath(
  file.path(root, evidence_relative),
  winslash = "/",
  mustWork = TRUE
)
baseline_dir <- normalizePath(
  "/private/tmp/H01-order32a-baseline.A5iuk8",
  winslash = "/",
  mustWork = TRUE
)

sha256_file <- function(path) {
  output <- system2(
    "/usr/bin/shasum",
    c("-a", "256", path),
    stdout = TRUE,
    stderr = TRUE
  )
  status <- attr(output, "status")
  if (!is.null(status) && status != 0L) {
    stop("shasum failed for ", path, call. = FALSE)
  }
  strsplit(output[[1L]], "[[:space:]]+", perl = TRUE)[[1L]][[1L]]
}

bytes_file <- function(path) unname(file.info(path)$size)

write_csv <- function(object, filename) {
  utils::write.csv(
    object,
    file.path(evidence_dir, filename),
    row.names = FALSE,
    na = "",
    fileEncoding = "UTF-8"
  )
}

dispatch_relative <-
  "audit/report_harmonization/report017_h01_order32a_dispatch_manifest.csv"
dispatch <- utils::read.csv(
  file.path(root, dispatch_relative),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
dispatch$current_sha256 <- vapply(
  file.path(root, dispatch$path),
  sha256_file,
  character(1)
)
dispatch$current_bytes <- vapply(
  file.path(root, dispatch$path),
  bytes_file,
  numeric(1)
)
dispatch$status <- ifelse(
  dispatch$sha256 == dispatch$current_sha256 &
    dispatch$bytes == dispatch$current_bytes,
  "PASS",
  "FAIL"
)
write_csv(dispatch, "H01_order32a_preflight_preservation.csv")

original_relative <- paste0(
  "audit/hypotheses/H01/report017_order32_source_rewrite/",
  "run_h01_order32_source_audit.R"
)
repaired_relative <- file.path(
  evidence_relative,
  "run_h01_order32a_source_audit.R"
)
original_bytes <- readBin(
  file.path(root, original_relative),
  what = "raw",
  n = bytes_file(file.path(root, original_relative))
)
repaired_bytes <- readBin(
  file.path(root, repaired_relative),
  what = "raw",
  n = bytes_file(file.path(root, repaired_relative))
)
guard <- charToRaw(
  "    if (missing(object)) return(invisible(NULL))\n"
)
guard_text <- rawToChar(guard)
repaired_text <- rawToChar(repaired_bytes)
guard_count <- lengths(regmatches(
  repaired_text,
  gregexpr(guard_text, repaired_text, fixed = TRUE)
))
reverse_text <- sub(guard_text, "", repaired_text, fixed = TRUE)
reverse_path <- tempfile("H01-order32a-reverse-", tmpdir = evidence_dir)
writeBin(charToRaw(reverse_text), reverse_path)
reverse_sha256 <- sha256_file(reverse_path)
reverse_bytes <- bytes_file(reverse_path)
unlink(reverse_path)
reverse_proof <- data.frame(
  check_id = c(
    "original_verifier_identity",
    "repaired_verifier_guard_count",
    "repaired_verifier_reverse_sha256",
    "repaired_verifier_reverse_bytes"
  ),
  expected = c(
    "79eef03a3978b85447e93590346a69c165e05e4bfb1e64d89dd7b44ddc1e902c",
    "1",
    "79eef03a3978b85447e93590346a69c165e05e4bfb1e64d89dd7b44ddc1e902c",
    "34759"
  ),
  observed = c(
    sha256_file(file.path(root, original_relative)),
    as.character(guard_count),
    reverse_sha256,
    as.character(reverse_bytes)
  ),
  stringsAsFactors = FALSE
)
reverse_proof$status <- ifelse(
  reverse_proof$expected == reverse_proof$observed,
  "PASS",
  "FAIL"
)
write_csv(reverse_proof, "H01_order32a_verifier_reverse_proof.csv")

baseline <- data.frame(
  path = c(
    "notebooks/hypotheses/H01.qmd",
    "audit/hypotheses/H01/H01_analysis_preparation.qmd",
    "artifacts/12_manifests/H01_reporting_artifacts.csv",
    "artifacts/12_manifests/H01_stage3_reporting_artifacts.csv",
    "artifacts/12_manifests/H01/H01_preparation_report_manifest.csv",
    "artifacts/12_manifests/H01_worker_artifacts.csv"
  ),
  expected_sha256 = c(
    "31c477fae21e0506521d27147cd3f1ea33941dac4c0a6e3a6d485f5acbc129a6",
    "962b28663d115c2da216e313f6eff22afb8ed2198d4441d7b0864d207ec231a8",
    "d0ed8e0c62579597f11c3fa701af35b5016e4921bee0000d2fd700b719f25079",
    "16e752b57eafa43b9cc09d70a698ba194cb3fe83dc62bf1bcc3e08c67f85eb6e",
    "bae856c2bb75df317f476e7e993178061628c0fcdbc6795a4b88f78843f8d9d0",
    "debce70f59c8e2c401ad36291694604246349633079bcd4d706aba6cf4d548c5"
  ),
  expected_bytes = c(90640, 54405, 11054, 26497, 13841, 393672),
  stringsAsFactors = FALSE
)
baseline$current_sha256 <- vapply(
  file.path(baseline_dir, baseline$path),
  sha256_file,
  character(1)
)
baseline$current_bytes <- vapply(
  file.path(baseline_dir, baseline$path),
  bytes_file,
  numeric(1)
)
baseline$status <- ifelse(
  baseline$expected_sha256 == baseline$current_sha256 &
    baseline$expected_bytes == baseline$current_bytes,
  "PASS",
  "FAIL"
)
write_csv(baseline, "H01_order32a_baseline_identities.csv")

audit <- utils::read.csv(
  file.path(evidence_dir, "H01_order32_source_audit.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
defects <- audit[audit$status != "PASS", , drop = FALSE]
write_csv(defects, "H01_order32a_stopped_defects.csv")

tests <- utils::read.csv(
  file.path(evidence_dir, "H01_order32_test_results.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)

execution <- data.frame(
  step = c(
    "baseline_direct_launch",
    "baseline_interpreted_execution",
    "complete_verifier_execution"
  ),
  command = c(
    paste(
      "/usr/bin/time -p",
      "scripts/report_harmonization/reconstruct_h01_order32_baseline.sh",
      root,
      baseline_dir
    ),
    paste(
      "/usr/bin/time -p /bin/sh",
      "scripts/report_harmonization/reconstruct_h01_order32_baseline.sh",
      root,
      baseline_dir
    ),
    paste(
      "/usr/bin/time -p env R_PROFILE_USER=/dev/null",
      paste0("R_LIBS_USER=", root, "/renv/library/macos/R-4.6/aarch64-apple-darwin23"),
      paste0("NATHEALTH_PROJECT_ROOT=", root),
      "Rscript --vanilla",
      repaired_relative,
      baseline_dir,
      evidence_relative
    )
  ),
  exit_status = c(126L, 0L, 1L),
  elapsed_seconds = c(0.00, 0.33, 7.13),
  disposition = c(
    "Pre-interpreter permission denial; sealed script was mode 0644 and baseline remained empty",
    "Six exact reconstructed baseline identities passed",
    "62 of 66 contracts and all four focused tests passed; stopped on four source contracts"
  ),
  stringsAsFactors = FALSE
)
write_csv(execution, "H01_order32a_execution_record.csv")

diff_paths <- c(
  "notebooks/hypotheses/H01.qmd",
  "audit/hypotheses/H01/H01_analysis_preparation.qmd",
  "tests/hypotheses/H01/test_h01_reporting_inputs.R",
  "tests/hypotheses/H01/test_h01_preparation_report.R",
  "tests/hypotheses/H01/test_h01_report016_deviation_reconciliation.R",
  "tests/hypotheses/H01/test_h01_stage3_model_support_display_refresh.R",
  "artifacts/12_manifests/H01_reporting_artifacts.csv",
  "artifacts/12_manifests/H01_stage3_reporting_artifacts.csv",
  "artifacts/12_manifests/H01/H01_preparation_report_manifest.csv",
  "artifacts/12_manifests/H01_worker_artifacts.csv",
  "audit/handoffs/H01_worker_handoff.md"
)
diff_check <- system2(
  "git",
  c("diff", "--check", "--", diff_paths),
  stdout = TRUE,
  stderr = TRUE
)
diff_status <- attr(diff_check, "status")
if (is.null(diff_status)) diff_status <- 0L
writeLines(
  c(paste0("exit_status=", diff_status), diff_check),
  file.path(evidence_dir, "H01_order32a_git_diff_check.txt"),
  useBytes = TRUE
)
scoped_status <- system2(
  "git",
  c("status", "--short", "--", diff_paths, evidence_relative),
  stdout = TRUE,
  stderr = TRUE
)
writeLines(
  scoped_status,
  file.path(evidence_dir, "H01_order32a_scoped_status.txt"),
  useBytes = TRUE
)

environment <- data.frame(
  key = c(
    "R_VERSION",
    "R_PROFILE_USER",
    "R_LIBS_USER",
    "NATHEALTH_PROJECT_ROOT",
    "BASELINE_PATH",
    "BASELINE_INITIAL_MODE",
    "BASELINE_INITIAL_OWNER",
    "BASELINE_INITIAL_EMPTY",
    "VERIFIER_EXIT_STATUS",
    "VERIFIER_ELAPSED_SECONDS",
    "FOCUSED_TESTS_PASSED",
    "SOURCE_CONTRACTS_PASSED"
  ),
  value = c(
    as.character(getRversion()),
    "/dev/null",
    paste0(root, "/renv/library/macos/R-4.6/aarch64-apple-darwin23"),
    root,
    baseline_dir,
    "0700",
    "zauner:wheel",
    "TRUE",
    "1",
    "7.13",
    paste0(sum(tests$exit_status == 0L), "/", nrow(tests)),
    paste0(sum(audit$status == "PASS"), "/", nrow(audit))
  ),
  stringsAsFactors = FALSE
)
write_csv(environment, "H01_order32a_environment.csv")

stopifnot(
  nrow(dispatch) == 28L,
  all(dispatch$status == "PASS"),
  all(reverse_proof$status == "PASS"),
  all(baseline$status == "PASS"),
  nrow(audit) == 66L,
  sum(audit$status == "PASS") == 62L,
  nrow(defects) == 4L,
  nrow(tests) == 4L,
  all(tests$exit_status == 0L),
  diff_status == 0L
)

summary_lines <- c(
  "# H01 order-32a complete-verifier stopped-state seal",
  "",
  "Date: 2026-08-15",
  "Status: **STOPPED after the single authorized complete verifier execution**",
  "",
  paste0("Repaired verifier SHA-256: `", sha256_file(file.path(root, repaired_relative)), "`"),
  paste0("Fresh reconstructed baseline retained at: `", baseline_dir, "`"),
  "R version: 4.6.1",
  "Verifier exit status: 1",
  "Verifier elapsed time: 7.13 seconds",
  paste0("Source contracts passed: ", sum(audit$status == "PASS"), "/", nrow(audit)),
  paste0("Focused tests passed: ", sum(tests$exit_status == 0L), "/", nrow(tests)),
  "",
  "## Complete defect list",
  "",
  paste0(
    "- `", defects$check_id, "`: expected `", defects$expected,
    "`; observed `", defects$observed, "`."
  ),
  "",
  "No verifier retry or source repair was attempted. No Quarto render, QMD chunk, model, prediction, bootstrap, simulation, reporting builder, or scientific artifact regeneration ran. All 28 dispatch identities, the original verifier, the stopped order-32 evidence, the current assembled sources, tests, manifests, handoff, held HTML, and profile remain exact.",
  "",
  "The initial direct baseline command stopped before entering the mode-0644 script. The still-empty baseline was then reconstructed once by the sealed script through `/bin/sh`, producing the six exact required identities."
)
writeLines(
  summary_lines,
  file.path(evidence_dir, "H01_order32a_stopped_state.md"),
  useBytes = TRUE
)

manifest_path <- file.path(
  evidence_dir,
  "H01_order32a_stopped_non_circular_manifest.csv"
)
evidence_files <- sort(list.files(
  evidence_dir,
  full.names = TRUE,
  recursive = FALSE,
  all.files = FALSE
))
evidence_files <- setdiff(evidence_files, manifest_path)
manifest <- data.frame(
  path = sub(paste0(root, "/"), "", evidence_files, fixed = TRUE),
  sha256 = vapply(evidence_files, sha256_file, character(1)),
  bytes = vapply(evidence_files, bytes_file, numeric(1)),
  stringsAsFactors = FALSE
)
write_csv(manifest, basename(manifest_path))

