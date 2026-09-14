#!/usr/bin/env Rscript

# Bounded non-scientific evidence seal for REPORT-017 order 32b.
# This script writes only inside the order-32b evidence directory.

stopifnot(identical(as.character(getRversion()), "4.6.1"))

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
setwd(root)

evidence_relative <-
  "audit/hypotheses/H01/report017_order32b_final_verifier_classification"
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

audit_manifest <- function(relative) {
  manifest <- utils::read.csv(
    file.path(root, relative),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  manifest$current_sha256 <- vapply(
    file.path(root, manifest$path),
    sha256_file,
    character(1)
  )
  manifest$current_bytes <- vapply(
    file.path(root, manifest$path),
    bytes_file,
    numeric(1)
  )
  manifest$status <- ifelse(
    manifest$sha256 == manifest$current_sha256 &
      manifest$bytes == manifest$current_bytes,
    "PASS",
    "FAIL"
  )
  manifest
}

dispatch32b <- audit_manifest(
  "audit/report_harmonization/report017_h01_order32b_dispatch_manifest.csv"
)
write_csv(dispatch32b, "H01_order32b_dispatch_preservation.csv")

owner32a <- audit_manifest(
  paste0(
    "audit/hypotheses/H01/report017_order32a_verifier_repair/",
    "H01_order32a_stopped_non_circular_manifest.csv"
  )
)
write_csv(owner32a, "H01_order32a_owner_evidence_preservation.csv")

dispatch32a <- audit_manifest(
  "audit/report_harmonization/report017_h01_order32a_dispatch_manifest.csv"
)
write_csv(dispatch32a, "H01_order32a_dispatch_preservation.csv")

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
baseline_files <- sort(list.files(
  baseline_dir,
  recursive = TRUE,
  full.names = FALSE,
  all.files = FALSE
))
baseline_file_set_exact <- identical(baseline_files, sort(baseline$path))
write_csv(baseline, "H01_order32b_baseline_identities.csv")

order32a_relative <- paste0(
  "audit/hypotheses/H01/report017_order32a_verifier_repair/",
  "run_h01_order32a_source_audit.R"
)
order32b_relative <- file.path(
  evidence_relative,
  "run_h01_order32b_source_audit.R"
)
order32a_text <- readChar(
  file.path(root, order32a_relative),
  nchars = bytes_file(file.path(root, order32a_relative)),
  useBytes = TRUE
)
order32b_text <- readChar(
  file.path(root, order32b_relative),
  nchars = bytes_file(file.path(root, order32b_relative)),
  useBytes = TRUE
)
old_wrapper <- paste0(
  "  unlist(\n",
  "    lapply(\n",
  "      names(difference)[difference > 0L],\n",
  "      function(value) rep(value, difference[[value]])\n",
  "    ),\n",
  "    use.names = FALSE\n",
  "  )\n"
)
new_wrapper <- paste0(
  "  as.character(unlist(\n",
  "    lapply(\n",
  "      names(difference)[difference > 0L],\n",
  "      function(value) rep(value, difference[[value]])\n",
  "    ),\n",
  "    use.names = FALSE\n",
  "  ))\n"
)
numeric_line <-
  "  text <- gsub(\"SHA-256\", \"SHA\", text, fixed = TRUE)\n"
fixed_count <- function(text, pattern) {
  positions <- gregexpr(pattern, text, fixed = TRUE)[[1L]]
  if (identical(positions, -1L)) 0L else length(positions)
}
wrapper_count <- fixed_count(order32b_text, new_wrapper)
numeric_line_count <- fixed_count(order32b_text, numeric_line)
reverse_text <- sub(new_wrapper, old_wrapper, order32b_text, fixed = TRUE)
reverse_text <- sub(numeric_line, "", reverse_text, fixed = TRUE)
reverse_path <- tempfile("H01-order32b-reverse-", tmpdir = evidence_dir)
writeChar(reverse_text, reverse_path, eos = NULL, useBytes = TRUE)
reverse_sha256 <- sha256_file(reverse_path)
reverse_bytes <- bytes_file(reverse_path)
unlink(reverse_path)
reverse_proof <- data.frame(
  check_id = c(
    "order32a_verifier_sha256",
    "order32a_verifier_bytes",
    "order32b_wrapper_change_count",
    "order32b_numeric_line_change_count",
    "two_change_reverse_sha256",
    "two_change_reverse_bytes",
    "two_change_reverse_byte_identity"
  ),
  expected = c(
    "620b2fe71fcf25c542afa9c435f925887454db895059cbd4aa8617046369ea18",
    "34808",
    "1",
    "1",
    "620b2fe71fcf25c542afa9c435f925887454db895059cbd4aa8617046369ea18",
    "34808",
    "TRUE"
  ),
  observed = c(
    sha256_file(file.path(root, order32a_relative)),
    as.character(bytes_file(file.path(root, order32a_relative))),
    as.character(wrapper_count),
    as.character(numeric_line_count),
    reverse_sha256,
    as.character(reverse_bytes),
    as.character(identical(reverse_text, order32a_text))
  ),
  stringsAsFactors = FALSE
)
reverse_proof$status <- ifelse(
  reverse_proof$expected == reverse_proof$observed,
  "PASS",
  "FAIL"
)
write_csv(reverse_proof, "H01_order32b_verifier_reverse_proof.csv")

source_audit <- utils::read.csv(
  file.path(evidence_dir, "H01_order32_source_audit.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
test_results <- utils::read.csv(
  file.path(evidence_dir, "H01_order32_test_results.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)

execution <- data.frame(
  step = "complete_verifier_execution",
  command = paste(
    "/usr/bin/time -p env R_PROFILE_USER=/dev/null",
    paste0("R_LIBS_USER=", root, "/renv/library/macos/R-4.6/aarch64-apple-darwin23"),
    paste0("NATHEALTH_PROJECT_ROOT=", root),
    "Rscript --vanilla",
    order32b_relative,
    baseline_dir,
    evidence_relative
  ),
  exit_status = 0L,
  elapsed_seconds = 6.68,
  source_contracts = paste0(sum(source_audit$status == "PASS"), "/", nrow(source_audit)),
  focused_tests = paste0(sum(test_results$exit_status == 0L), "/", nrow(test_results)),
  preliminary_parse_test_or_dry_run = FALSE,
  stringsAsFactors = FALSE
)
write_csv(execution, "H01_order32b_execution_record.csv")

environment <- data.frame(
  key = c(
    "R_VERSION",
    "R_PROFILE_USER",
    "R_LIBS_USER",
    "NATHEALTH_PROJECT_ROOT",
    "BASELINE_PATH",
    "VERIFIER_EXIT_STATUS",
    "VERIFIER_ELAPSED_SECONDS"
  ),
  value = c(
    as.character(getRversion()),
    "/dev/null",
    paste0(root, "/renv/library/macos/R-4.6/aarch64-apple-darwin23"),
    root,
    baseline_dir,
    "0",
    "6.68"
  ),
  stringsAsFactors = FALSE
)
write_csv(environment, "H01_order32b_environment.csv")

diff_paths <- unique(c(
  dispatch32b$path,
  dispatch32a$path,
  evidence_relative
))
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
  file.path(evidence_dir, "H01_order32b_git_diff_check.txt"),
  useBytes = TRUE
)
scoped_status <- system2(
  "git",
  c("status", "--short", "--", diff_paths),
  stdout = TRUE,
  stderr = TRUE
)
writeLines(
  scoped_status,
  file.path(evidence_dir, "H01_order32b_scoped_status.txt"),
  useBytes = TRUE
)

stopifnot(
  nrow(dispatch32b) == 24L,
  all(dispatch32b$status == "PASS"),
  nrow(owner32a) == 20L,
  all(owner32a$status == "PASS"),
  nrow(dispatch32a) == 28L,
  all(dispatch32a$status == "PASS"),
  all(baseline$status == "PASS"),
  baseline_file_set_exact,
  all(reverse_proof$status == "PASS"),
  nrow(source_audit) == 66L,
  all(source_audit$status == "PASS"),
  nrow(test_results) == 4L,
  all(test_results$exit_status == 0L),
  diff_status == 0L
)

summary_lines <- c(
  "# H01 order-32b final verifier classification acceptance",
  "",
  "Date: 2026-08-15",
  "Status: **PASS**",
  "",
  paste0("Order-32b verifier SHA-256: `", sha256_file(file.path(root, order32b_relative)), "`"),
  paste0("Order-32b verifier bytes: ", bytes_file(file.path(root, order32b_relative))),
  paste0("Retained baseline: `", baseline_dir, "`"),
  "R version: 4.6.1",
  "Verifier exit status: 0",
  "Verifier elapsed time: 6.68 seconds",
  paste0("Source contracts passed: ", sum(source_audit$status == "PASS"), "/", nrow(source_audit)),
  paste0("Focused tests passed: ", sum(test_results$exit_status == 0L), "/", nrow(test_results)),
  "",
  "The verifier was executed exactly once with no preliminary parse, focused test, partial run, or dry run. Reversing only the two approved classification changes reproduces the order-32a verifier byte-for-byte. All 24 order-32b dispatch identities, 20 order-32a owner-evidence rows, 28 prior dispatch identities, and six baseline identities remain exact.",
  "",
  "No Quarto render or QMD execution occurred. No model, prediction, bootstrap, simulation, scientific recomputation, reporting builder, or artifact regeneration ran. No protected source, test, current manifest, handoff, held HTML, profile, prior verifier, or prior evidence file changed."
)
writeLines(
  summary_lines,
  file.path(evidence_dir, "H01_order32b_acceptance.md"),
  useBytes = TRUE
)

manifest_path <- file.path(
  evidence_dir,
  "H01_order32b_non_circular_manifest.csv"
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

