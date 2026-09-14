#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE, warn = 2)
suppressPackageStartupMessages(library(openssl))

stopifnot(identical(as.character(getRversion()), "4.6.1"))

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT"),
  winslash = "/",
  mustWork = TRUE
)
setwd(root)

evidence_dir <- file.path(
  root,
  "audit/hypotheses/H10/report018_order59_companion_no_rerender_completion"
)
stopifnot(dir.exists(evidence_dir))

sha256_file <- function(path) {
  connection <- file(path, open = "rb")
  on.exit(close(connection), add = TRUE)
  paste0(openssl::sha256(connection))
}

file_bytes <- function(path) as.numeric(file.info(path)$size)

file_exact <- function(path, sha256, bytes = NULL) {
  pass <- file.exists(path) &&
    !dir.exists(path) &&
    identical(sha256_file(path), sha256)
  if (!is.null(bytes)) {
    pass <- pass && identical(file_bytes(path), as.numeric(bytes))
  }
  pass
}

fixed <- data.frame(
  path = c(
    "notebooks/hypotheses/H10.qmd",
    "_build/nathealth/notebooks/hypotheses/H10.html",
    "audit/hypotheses/H10/H10_analysis_preparation.qmd",
    "_build/nathealth/audit/hypotheses/H10/H10_analysis_preparation.qmd",
    "_build/nathealth/audit/hypotheses/H10/H10_analysis_preparation.html",
    "scripts/hypotheses/H10/build_h10_preparation_report_manifest.R",
    "tests/hypotheses/H10/test_h10_preparation_report.R",
    "tests/hypotheses/H10/test_h10_stage3_reader_report.R",
    "_quarto-nathealth.yml",
    "notebooks/hypotheses/H11.qmd"
  ),
  sha256 = c(
    "0cf302f74c482168c5f5d4c640bbc6a80ef451333f7d76f3c3be204ac1b5f64d",
    "37d5ffb4b5e33f23690e222c90ac6c26b70a222298c7c631005d41e3db4bee14",
    "706fe46f293bd09bfd3cb75c14bc3082410a452acfff666d76219f266fded1a6",
    "706fe46f293bd09bfd3cb75c14bc3082410a452acfff666d76219f266fded1a6",
    "dc2aa864a1b1edf01043444af425df40564779e83b72f00c206068fdba19a7b9",
    "292ad3335dac8241f317983d5017a5a1d5dbce51fef245d2c30889cf4a3dcf97",
    "8b206d4cf565b6f5a767e6e99afb9e587db8255f2239cb3761eebaa8e69d1608",
    "dac8e70f9389bac48bfb91fd0640f86b3a65e468d52aa2dbb37a63d9aa0303af",
    "80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3",
    "7909ba06782c84223197ab7fcd16493d7ee6e6d8b63c750aa81f17cb97977867"
  ),
  stringsAsFactors = FALSE
)
fixed$exact <- vapply(
  seq_len(nrow(fixed)),
  function(index) file_exact(fixed$path[[index]], fixed$sha256[[index]]),
  logical(1)
)

preflight <- read.csv(
  file.path(evidence_dir, "independent_preflight_checks.csv"),
  check.names = FALSE
)
transition <- read.csv(
  file.path(evidence_dir, "transition_checks.csv"),
  check.names = FALSE
)
execution <- read.csv(
  file.path(evidence_dir, "execution_record.csv"),
  check.names = FALSE
)
diagnosis <- read.csv(
  file.path(evidence_dir, "helper_mismatch_diagnosis.csv"),
  check.names = FALSE
)

live_manifest_path <-
  "artifacts/12_manifests/H10/H10_preparation_report_manifest.csv"
preview_path <- paste0(
  "audit/report_harmonization/report018_h10_companion_preflight/",
  "prospective_preparation_report_manifest_preview.csv"
)
live_manifest <- read.csv(live_manifest_path, check.names = FALSE)
preview <- read.csv(preview_path, check.names = FALSE)
extra <- sort(setdiff(live_manifest$path, preview$path))
missing <- sort(setdiff(preview$path, live_manifest$path))
expected_extra <- sort(diagnosis$path)
live_paths <- file.path(root, live_manifest$path)
live_member_exact <- vapply(
  seq_len(nrow(live_manifest)),
  function(index) {
    file_exact(
      live_paths[[index]],
      live_manifest$sha256[[index]],
      live_manifest$bytes[[index]]
    )
  },
  logical(1)
)

checks <- data.frame(
  domain = c(
    "preflight",
    "transition",
    "helper_gate",
    "manifest",
    "identity",
    "execution_scope",
    "source_side_html"
  ),
  check_id = c(
    "complete_read_only_preflight",
    "sealed_postimages_and_exact_reversals",
    "required_269_row_manifest",
    "live_275_member_manifest_integrity",
    "preserved_sources_html_profile_and_h11",
    "stopped_before_test_render_and_visual_qa",
    "obsolete_source_side_html_absent"
  ),
  status = c(
    if (nrow(preflight) == 12L && all(preflight$pass)) "PASS" else "FAIL",
    if (nrow(transition) == 2L && all(transition$status == "PASS")) "PASS" else "FAIL",
    "FAIL_CLOSED",
    if (
      nrow(live_manifest) == 275L &&
        !anyDuplicated(live_manifest$path) &&
        all(live_member_exact)
    ) "PASS" else "FAIL",
    if (all(fixed$exact)) "PASS" else "FAIL",
    if (
      execution$invocation_count[execution$operation == "preparation_manifest_helper"] == 1L &&
        execution$invocation_count[execution$operation == "preparation_test"] == 0L &&
        execution$invocation_count[execution$operation == "quarto_knitr_pandoc_semantic_hook"] == 0L &&
        execution$invocation_count[execution$operation == "loopback_visual_qa"] == 0L
    ) "PASS" else "FAIL",
    if (!file.exists("audit/hypotheses/H10/H10_analysis_preparation.html")) "PASS" else "FAIL"
  ),
  detail = c(
    sprintf("checks=%d/%d", sum(preflight$pass), nrow(preflight)),
    sprintf("postimages=%d/2 reversals=%d/2", sum(transition$status == "PASS"), sum(transition$expected_pre_sha256 == transition$reconstructed_pre_sha256)),
    sprintf("required=269 observed=%d extra=%d missing=%d", nrow(live_manifest), length(extra), length(missing)),
    sprintf("rows=%d unique=%s members_exact=%d/%d", nrow(live_manifest), !anyDuplicated(live_manifest$path), sum(live_member_exact), nrow(live_manifest)),
    sprintf("exact=%d/%d", sum(fixed$exact), nrow(fixed)),
    "helper=1 preparation_test=0 render_or_hook=0 visual_qa=0",
    sprintf("present=%s", file.exists("audit/hypotheses/H10/H10_analysis_preparation.html"))
  ),
  stringsAsFactors = FALSE
)

stopifnot(
  identical(extra, expected_extra),
  length(extra) == 6L,
  length(missing) == 0L,
  checks$status[checks$check_id == "required_269_row_manifest"] == "FAIL_CLOSED",
  all(checks$status[checks$check_id != "required_269_row_manifest"] == "PASS")
)

write.csv(
  fixed,
  file.path(evidence_dir, "fixed_identity_at_stop.csv"),
  row.names = FALSE,
  na = ""
)
write.csv(
  checks,
  file.path(evidence_dir, "fail_closed_checks.csv"),
  row.names = FALSE,
  na = ""
)

record <- c(
  "# REPORT-018 H10 order 59 fail-closed stop",
  "",
  paste0("Sealed UTC: ", format(Sys.time(), tz = "UTC", usetz = TRUE)),
  "",
  "## Disposition",
  "",
  "Order 59 stopped at the helper-output gate. The one authorized helper execution exited successfully but reported 275 current files rather than the required 269. The preparation test, static completion, and browser QA were not run. No retry occurred.",
  "",
  "The exact six additional manifest rows are task-owned Order 59 evidence files that existed before the helper ran. This is an execution-sequencing defect in the owner workflow, not a source-QMD, scientific-result, or rendered-HTML defect. The sealed helper and preparation-test postimages remain exact, and both exact reversals were proven before helper execution.",
  "",
  paste0("The resulting 275-row manifest is unique and all 275 listed members are live-exact at SHA-256 `", sha256_file(live_manifest_path), "`. It is not accepted as the required 269-row completion manifest."),
  "",
  "The H10 result source and HTML, companion source and preserved fresh HTML, normal profile, reader test, scientific assets represented by the passed preflight, and H11 source remain unchanged. The obsolete source-side companion HTML remains absent. No Quarto, knitr, Pandoc, semantic hook, model, scientific builder, preparation test, browser QA, commit, push, or upload was invoked after the gate failure.",
  "",
  "A new separately sealed recovery order is required to authorize any cleanup or second helper execution. H11 and all later targets remain held.",
  ""
)
record_path <- file.path(evidence_dir, "order59_fail_closed_stop_record.md")
writeLines(record, record_path, useBytes = TRUE)

manifest_path <- file.path(
  evidence_dir,
  "order59_fail_closed_non_circular_evidence_manifest.csv"
)
local_files <- list.files(
  evidence_dir,
  full.names = TRUE,
  recursive = FALSE,
  all.files = TRUE,
  no.. = TRUE
)
local_files <- local_files[
  !dir.exists(local_files) & basename(local_files) != basename(manifest_path)
]
external_files <- file.path(
  root,
  c(
    "audit/report_harmonization/owner_orders/59_h10_companion_no_rerender_integration_completion.md",
    "audit/report_harmonization/report018_h10_order59_dispatch.md",
    "audit/report_harmonization/report018_h10_order59_dispatch_manifest.csv",
    "audit/report_harmonization/report018_h10_result_independent_acceptance.md",
    "audit/report_harmonization/report018_h10_companion_preflight_execution_path_disposition.md",
    "audit/report_harmonization/report018_h10_companion_preflight/gt_html_semantic_post_render_summary.csv",
    "audit/report_harmonization/report018_h10_companion_preflight/H10_analysis_preparation_gt_semantic_ledger.csv",
    fixed$path,
    live_manifest_path,
    preview_path
  )
)
files <- unique(c(sort(local_files), external_files))
stopifnot(all(file.exists(files)), !manifest_path %in% files)

manifest <- data.frame(
  path = ifelse(
    startsWith(files, paste0(root, "/")),
    substring(files, nchar(root) + 2L),
    files
  ),
  sha256 = vapply(files, sha256_file, character(1)),
  bytes = vapply(files, file_bytes, numeric(1)),
  role = c(
    rep("order59_fail_closed_evidence", length(local_files)),
    rep("protected_external_identity", length(files) - length(local_files))
  ),
  stringsAsFactors = FALSE
)
stopifnot(!anyDuplicated(manifest$path), !basename(manifest_path) %in% basename(manifest$path))
write.csv(manifest, manifest_path, row.names = FALSE, na = "")

cat(sprintf(
  paste0(
    "REPORT018_H10_ORDER59=FAIL_CLOSED helper=1 manifest=275/269 ",
    "extra=6 missing=0 test=0 render=0 visual=0 evidence=%s\n"
  ),
  sha256_file(manifest_path)
))
