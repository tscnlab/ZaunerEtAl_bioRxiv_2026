#!/usr/bin/env Rscript

stopifnot(identical(as.character(getRversion()), "4.6.1"))
root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
setwd(root)
source(file.path(root, "scripts/pipeline/paths_io.R"))
evidence_relative <-
  "audit/hypotheses/H01/report017_order32j_no_render_finalization"
evidence_dir <- file.path(root, evidence_relative)

summary <- read.csv(
  file.path(evidence_dir, "order32j_stopped_summary.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
tests <- read.csv(
  file.path(evidence_dir, "order32j_stopped_test_results.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
html_checks <- read.csv(
  file.path(evidence_dir, "order32j_stopped_html_contracts.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
worker <- read.csv(
  file.path(evidence_dir, "order32j_worker_manifest_summary_at_stop.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
identities <- read.csv(
  file.path(evidence_dir, "order32j_current_identities_at_stop.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
unexpected <- read.csv(
  file.path(evidence_dir, "order32j_unexpected_manifest_paths.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)

lifecycle <- data.frame(
  sequence = seq_len(9L),
  action = c(
    "Dispatch, protected, and build preflight",
    "Helper source-only correction and exact reverse proof",
    "Single normal-profile helper execution",
    "Required 62-row postcondition",
    "Direct four-row worker reseal",
    "Complete no-render test suite",
    "Read-only semantic, link, and endpoint audit",
    "Secure loopback visual QA",
    "Quarto render"
  ),
  status = c(
    "PASS",
    "PASS",
    "PASS_EXIT_0",
    "FAIL_65_ROWS_OBSERVED",
    "WITHHELD_FAIL_CLOSED",
    "COMPLETE_5_PASS_2_FAIL",
    "PASS_21_OF_21",
    "NOT_STARTED_AFTER_PREREQUISITE_FAILURE",
    "NOT_RUN_NOT_AUTHORIZED"
  ),
  stringsAsFactors = FALSE
)
write.csv(
  lifecycle,
  file.path(evidence_dir, "order32j_lifecycle.csv"),
  row.names = FALSE,
  na = ""
)

commands <- data.frame(
  sequence = seq_len(8L),
  command = c(
    paste0(
      "env R_PROFILE_USER=/dev/null R_LIBS_USER=<project-library> ",
      "NATHEALTH_PROJECT_ROOT=<project> Rscript --vanilla ",
      evidence_relative,
      "/collect_order32j_preflight.R"
    ),
    paste0(
      "env R_PROFILE_USER=/dev/null R_LIBS_USER=<project-library> ",
      "NATHEALTH_PROJECT_ROOT=<project> Rscript --vanilla ",
      evidence_relative,
      "/record_helper_change.R"
    ),
    paste0(
      "env R_PROFILE_USER=/dev/null R_LIBS_USER=<project-library> ",
      "NATHEALTH_PROJECT_ROOT=<project> Rscript --vanilla ",
      evidence_relative,
      "/verify_before_helper_run.R"
    ),
    paste0(
      "NATHEALTH_PROJECT_ROOT=<project> Rscript ",
      "scripts/hypotheses/H01/build_h01_preparation_report_manifest.R"
    ),
    paste0(
      "env R_PROFILE_USER=/dev/null R_LIBS_USER=<project-library> ",
      "NATHEALTH_PROJECT_ROOT=<project> Rscript --vanilla ",
      evidence_relative,
      "/seal_order32j_stopped_state.R"
    ),
    paste0(
      "env R_PROFILE_USER=/dev/null R_LIBS_USER=<project-library> ",
      "NATHEALTH_PROJECT_ROOT=<project> Rscript --vanilla ",
      evidence_relative,
      "/run_order32j_stopped_checks.R"
    ),
    paste0(
      "env R_PROFILE_USER=/dev/null R_LIBS_USER=<project-library> ",
      "NATHEALTH_PROJECT_ROOT=<project> Rscript --vanilla ",
      evidence_relative,
      "/audit_order32j_stopped_html.R"
    ),
    paste0(
      "env R_PROFILE_USER=/dev/null R_LIBS_USER=<project-library> ",
      "NATHEALTH_PROJECT_ROOT=<project> Rscript --vanilla ",
      evidence_relative,
      "/audit_order32j_worker_at_stop.R"
    )
  ),
  scientific_execution = FALSE,
  quarto_execution = FALSE,
  stringsAsFactors = FALSE
)
write.csv(
  commands,
  file.path(evidence_dir, "order32j_commands.csv"),
  row.names = FALSE,
  na = ""
)

scope_paths <- c(
  "scripts/hypotheses/H01/build_h01_preparation_report_manifest.R",
  paste0(
    "_build/nathealth/audit/hypotheses/H01/",
    "H01_analysis_preparation.qmd"
  ),
  paste0(
    "_build/nathealth/audit/hypotheses/H01/",
    "H01_analysis_preparation_files/source-data"
  ),
  "artifacts/12_manifests/H01/H01_preparation_report_manifest.csv",
  "artifacts/12_manifests/H01_worker_artifacts.csv",
  evidence_relative
)
git_status <- system2(
  "git",
  c("status", "--short", "--", scope_paths),
  stdout = TRUE,
  stderr = TRUE
)
writeLines(
  git_status,
  file.path(evidence_dir, "order32j_scoped_git_status.txt"),
  useBytes = TRUE
)
git_diff_check <- system2(
  "git",
  c(
    "diff",
    "--check",
    "--",
    "scripts/hypotheses/H01/build_h01_preparation_report_manifest.R",
    paste0(
      "_build/nathealth/audit/hypotheses/H01/",
      "H01_analysis_preparation.qmd"
    ),
    "artifacts/12_manifests/H01/H01_preparation_report_manifest.csv",
    "artifacts/12_manifests/H01_worker_artifacts.csv"
  ),
  stdout = TRUE,
  stderr = TRUE
)
git_diff_status <- attr(git_diff_check, "status")
if (is.null(git_diff_status)) {
  git_diff_status <- 0L
}
writeLines(
  c(
    paste0("status=", git_diff_status),
    git_diff_check
  ),
  file.path(evidence_dir, "order32j_git_diff_check.txt"),
  useBytes = TRUE
)
stopifnot(identical(git_diff_status, 0L))

value_for <- function(item, field) {
  identities[identities$item == item, field][[1L]]
}
test_failures <- tests[tests$status != 0L, , drop = FALSE]
stopifnot(
  nrow(test_failures) == 2L,
  all(html_checks$pass),
  nrow(unexpected) == 3L
)
stopped_state_path <- file.path(evidence_dir, "order32j_stopped_state.md")
stopped_lines <- c(
  "# REPORT-017 H01 order 32j stopped state",
  "",
  "Date: 2026-08-20",
  "",
  "Status: **STOPPED, new preparation-manifest cardinality defect**",
  "",
  "## Outcome",
  "",
  paste0(
    "The 28-row dispatch, 1,709-path protected inventory, 1,115-entry ",
    "build inventory, helper parse, and exact helper reverse proof passed. ",
    "The helper ran exactly once under normal R 4.6.1 project startup and ",
    "exited 0. It restored both protected downloads and synchronized the ",
    "build QMD exactly to the accepted authoring QMD."
  ),
  "",
  paste0(
    "The required 62-row postcondition failed because the unchanged dynamic ",
    "script discovery produced 65 live-exact rows. The three additional ",
    "current H01 scripts are:"
  ),
  "",
  paste0("- `", unexpected$path, "`"),
  "",
  paste0(
    "All 65 rows are live-exact and no prior row was removed. The order's ",
    "fixed cardinality is therefore incompatible with the helper's preserved ",
    "all-H01-R-script discovery contract. No scientific result changed."
  ),
  "",
  "## Fail-closed disposition",
  "",
  paste0(
    "The authorized four-row worker-manifest reseal was withheld. The worker ",
    "manifest remains byte-identical to its dispatch identity and is ",
    worker$live_exact,
    "/",
    worker$total_rows,
    " live-exact. Its six mismatches are exactly the two accepted historical ",
    "result/profile transitions plus the four rows that order 32j intended ",
    "to reseal."
  ),
  "",
  paste0(
    "The full no-render suite completed safely: five tests passed and two ",
    "failed. The H01 preparation test contains a stale fixed-literal ",
    "assertion for `17 prespecified light-exposure metrics`, while the exact ",
    "accepted source uses `17-response package`. The global country-site test ",
    "also reports two unrelated H04 line-wrap findings: Delft in the H04 ",
    "result and Munich in the H04 companion."
  ),
  "",
  paste0(
    "The read-only companion audit passed all 21 contracts: 20 native gt ",
    "tables, two figure endpoints, unique document IDs, 1,442 within-table ",
    "header tokens, 1,471 explicit ID references, 780 reader links, two ",
    "restored download links, reciprocal navigation, country-coded H01 sites, ",
    "and reversible semantic repair."
  ),
  "",
  paste0(
    "Secure loopback visual QA and its static server were not started because ",
    "the required manifest and test gates did not pass. No Quarto command, ",
    "render, QMD execution, model, prediction, bootstrap, simulation, or other ",
    "scientific computation ran."
  ),
  "",
  "## Current key identities",
  "",
  paste0(
    "- helper: `",
    value_for("helper", "sha256"),
    "`, ",
    value_for("helper", "bytes"),
    " bytes"
  ),
  paste0(
    "- authoring and build QMD: `",
    value_for("source_qmd", "sha256"),
    "`, ",
    value_for("source_qmd", "bytes"),
    " bytes each"
  ),
  paste0(
    "- accepted companion HTML: `",
    value_for("companion_html", "sha256"),
    "`, ",
    value_for("companion_html", "bytes"),
    " bytes"
  ),
  paste0(
    "- 65-row preparation manifest: `",
    value_for("preparation_manifest", "sha256"),
    "`, ",
    value_for("preparation_manifest", "bytes"),
    " bytes"
  ),
  paste0(
    "- unchanged worker manifest: `",
    value_for("worker_manifest", "sha256"),
    "`, ",
    value_for("worker_manifest", "bytes"),
    " bytes"
  ),
  "",
  "## Required coordinator disposition",
  "",
  paste0(
    "Issue one bounded continuation that either accepts the truthful 65-row ",
    "manifest and updates the fixed cardinality contract, or explicitly ",
    "defines why the three live H01 scripts must be excluded. The existing ",
    "dynamic discovery behavior favors accepting 65 rows. The continuation ",
    "must also classify the stale H01 preparation-test literal. The unrelated ",
    "H04 country-site findings belong to the H04 owner."
  )
)
writeLines(stopped_lines, stopped_state_path, useBytes = TRUE)

manifest_path <- file.path(evidence_dir, "order32j_owner_evidence_manifest.csv")
evidence_files <- sort(list.files(
  evidence_dir,
  recursive = FALSE,
  full.names = TRUE,
  all.files = TRUE,
  include.dirs = FALSE,
  no.. = TRUE
))
evidence_files <- setdiff(evidence_files, manifest_path)
stopifnot(
  length(evidence_files) > 0L,
  all(file.exists(evidence_files)),
  all(!dir.exists(evidence_files))
)
evidence_manifest <- data.frame(
  path = paste0(evidence_relative, "/", basename(evidence_files)),
  sha256 = vapply(evidence_files, artifact_sha256, character(1)),
  bytes = as.numeric(file.info(evidence_files)$size),
  role = ifelse(
    grepl("\\.R$", evidence_files),
    "bounded_evidence_code",
    ifelse(
      grepl("\\.csv$", evidence_files),
      "bounded_tabular_evidence",
      ifelse(
        grepl("\\.md$", evidence_files),
        "stopped_state_handoff",
        "bounded_text_or_snapshot_evidence"
      )
    )
  ),
  stringsAsFactors = FALSE
)
stopifnot(
  !anyDuplicated(evidence_manifest$path),
  !any(evidence_manifest$path == paste0(
    evidence_relative,
    "/order32j_owner_evidence_manifest.csv"
  ))
)
write.csv(evidence_manifest, manifest_path, row.names = FALSE, na = "")
cat(sprintf(
  paste0(
    "order32j_final_seal=STOPPED evidence=%d manifest=%s ",
    "manifest_rows=65 tests=%d/%d html=%d/%d\n"
  ),
  nrow(evidence_manifest),
  artifact_sha256(manifest_path),
  sum(tests$status == 0L),
  nrow(tests),
  sum(html_checks$pass),
  nrow(html_checks)
))
