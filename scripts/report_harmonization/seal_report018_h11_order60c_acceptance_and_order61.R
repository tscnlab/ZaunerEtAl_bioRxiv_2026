#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE, warn = 2)
suppressPackageStartupMessages({
  library(openssl)
  library(readr)
})

stopifnot(identical(as.character(getRversion()), "4.6.1"))

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
setwd(root)

sha256_file <- function(path) {
  connection <- file(path, open = "rb")
  on.exit(close(connection), add = TRUE)
  paste0(openssl::sha256(connection))
}

file_bytes <- function(path) unname(as.numeric(file.info(path)$size))

audit_manifest <- function(path, expected_rows) {
  manifest <- readr::read_csv(
    path,
    show_col_types = FALSE,
    col_types = readr::cols(
      path = readr::col_character(),
      sha256 = readr::col_character(),
      bytes = readr::col_double(),
      role = readr::col_character()
    )
  )
  stopifnot(
    nrow(manifest) == expected_rows,
    !anyDuplicated(manifest$path),
    !path %in% manifest$path,
    all(file.exists(manifest$path)),
    all(!dir.exists(manifest$path))
  )
  live_sha <- vapply(manifest$path, sha256_file, character(1))
  live_bytes <- unname(as.numeric(file.info(manifest$path)$size))
  stopifnot(
    identical(unname(live_sha), manifest$sha256),
    identical(as.numeric(live_bytes), as.numeric(manifest$bytes))
  )
  invisible(manifest)
}

write_manifest <- function(path, members, roles) {
  stopifnot(
    length(members) == length(roles),
    !anyDuplicated(members),
    !path %in% members,
    all(file.exists(members)),
    all(!dir.exists(members))
  )
  manifest <- data.frame(
    path = members,
    sha256 = vapply(members, sha256_file, character(1)),
    bytes = unname(as.numeric(file.info(members)$size)),
    role = roles,
    stringsAsFactors = FALSE
  )
  readr::write_csv(manifest, path)
  audit_manifest(path, nrow(manifest))
  invisible(manifest)
}

acceptance_path <- paste0(
  "audit/report_harmonization/",
  "report018_h11_order60c_result_independent_acceptance.md"
)
acceptance_manifest_path <- paste0(
  "audit/report_harmonization/",
  "report018_h11_order60c_result_independent_acceptance_manifest.csv"
)
order_path <- paste0(
  "audit/report_harmonization/owner_orders/",
  "61_h11_companion_test_link_and_target_render.md"
)
dispatch_manifest_path <- paste0(
  "audit/report_harmonization/",
  "report018_h11_order61_dispatch_manifest.csv"
)
checker_path <- paste0(
  "scripts/report_harmonization/",
  "check_report018_h11_order60c_acceptance_and_companion_preflight.R"
)
sealer_path <- paste0(
  "scripts/report_harmonization/",
  "seal_report018_h11_order60c_acceptance_and_order61.R"
)
preflight_dir <- paste0(
  "audit/report_harmonization/",
  "report018_h11_order60c_acceptance_and_companion_preflight"
)
owner_dir <- paste0(
  "audit/hypotheses/H11/",
  "report018_order60c_no_rerender_completion"
)

stopifnot(
  identical(
    sha256_file(acceptance_path),
    "383e8df225e6af343f1e8c7c3fb25c9281953e992e3f30ba829348ec4bd835ae"
  ),
  identical(
    sha256_file(order_path),
    "7fcd372fb8a723a3d89f490c10a39f7792da1e88d96976b7168d85205a0c0a7a"
  ),
  identical(
    sha256_file(checker_path),
    "709c1b9d974da2e614bce1b96e3fdac62fbc185289f5268c03743fd46ea434fa"
  ),
  identical(
    sha256_file("audit/report_harmonization/coordination_matrix.csv"),
    "c8990a95151ebfd5deb0a1abca3a69ad2c4a1720f30537de13deebab2386b6ac"
  )
)

checks <- readr::read_csv(
  file.path(preflight_dir, "acceptance_and_companion_preflight_checks.csv"),
  show_col_types = FALSE
)
stopifnot(nrow(checks) == 11L, all(checks$pass))

owner_manifest_path <- file.path(
  owner_dir,
  "order60c_non_circular_completion_manifest.csv"
)
audit_manifest(owner_manifest_path, 107L)

matrix <- readr::read_csv(
  "audit/report_harmonization/coordination_matrix.csv",
  show_col_types = FALSE,
  col_types = readr::cols(.default = readr::col_character())
)
stopifnot(nrow(matrix) == 15L, ncol(matrix) == 16L)
h11 <- matrix$logical_order == "13"
stopifnot(
  sum(h11) == 1L,
  identical(
    matrix$current_task_status_2026_08_12[h11],
    "active_order60_h11_result_target_render"
  )
)

acceptance_members <- c(
  acceptance_path,
  file.path(owner_dir, "order60c_completion.md"),
  owner_manifest_path,
  file.path(owner_dir, "complete_verifier_execution.csv"),
  file.path(owner_dir, "completion_contract_audit.csv"),
  file.path(owner_dir, "visual_qa_observations.csv"),
  file.path(owner_dir, "server_lifecycle.csv"),
  file.path(owner_dir, "no_drift_audit.csv"),
  file.path(owner_dir, "stage3_test_transition_audit.csv"),
  file.path(
    owner_dir,
    "check_report018_h11_order60c_no_rerender_completion.R"
  ),
  checker_path,
  file.path(preflight_dir, "acceptance_and_companion_preflight_checks.csv"),
  file.path(preflight_dir, "independent_complete_replay_checks.csv"),
  file.path(preflight_dir, "independent_complete_replay_execution.csv"),
  file.path(preflight_dir, "prospective_preparation_test_audit.csv"),
  file.path(preflight_dir, "prospective_helper_path_inventory.csv"),
  file.path(preflight_dir, "companion_source_endpoint_inventory.csv"),
  file.path(preflight_dir, "companion_source_link_audit.csv"),
  file.path(preflight_dir, "held_preparation_manifest_transitions.csv"),
  file.path(preflight_dir, "held_companion_integration_state.csv"),
  "notebooks/hypotheses/H11.qmd",
  "_build/nathealth/notebooks/hypotheses/H11.html",
  "tests/hypotheses/H11/test_h11_stage3_reader_report.R",
  "audit/hypotheses/H11/H11_analysis_preparation.qmd",
  paste0(
    "_build/nathealth/audit/hypotheses/H11/",
    "H11_analysis_preparation.html"
  ),
  "_quarto-nathealth.yml",
  "renv.lock",
  "notebooks/sensitivity_battery.qmd",
  "_build/nathealth/notebooks/sensitivity_battery.html",
  "audit/report_harmonization/coordination_matrix.csv"
)
acceptance_roles <- c(
  "independent acceptance",
  "owner completion",
  "owner non-circular seal",
  "owner verifier execution",
  "owner completion contract",
  "owner visual QA",
  "owner lifecycle",
  "owner no-drift audit",
  "authorized test transition",
  "owner complete verifier",
  "independent checker",
  "independent acceptance and companion preflight checks",
  "independent complete replay checks",
  "independent complete replay execution",
  "prospective preparation-test audit",
  "prospective helper inventory",
  "companion endpoint inventory",
  "companion link audit",
  "held manifest transition set",
  "held companion integration state",
  "accepted result source",
  "accepted result endpoint",
  "accepted result test",
  "held companion source",
  "held companion endpoint",
  "normal profile",
  "environment lock",
  "held sensitivity source",
  "held sensitivity endpoint",
  "coordination invariant"
)
acceptance_manifest <- write_manifest(
  acceptance_manifest_path,
  acceptance_members,
  acceptance_roles
)

dispatch_members <- c(
  order_path,
  acceptance_path,
  acceptance_manifest_path,
  checker_path,
  sealer_path,
  file.path(preflight_dir, "acceptance_and_companion_preflight_checks.csv"),
  file.path(preflight_dir, "prospective_preparation_test_audit.csv"),
  file.path(preflight_dir, "prospective_helper_path_inventory.csv"),
  file.path(preflight_dir, "held_preparation_manifest_transitions.csv"),
  file.path(preflight_dir, "companion_source_endpoint_inventory.csv"),
  file.path(preflight_dir, "companion_source_link_audit.csv"),
  file.path(preflight_dir, "held_companion_integration_state.csv"),
  file.path(owner_dir, "order60c_completion.md"),
  owner_manifest_path,
  "notebooks/hypotheses/H11.qmd",
  "_build/nathealth/notebooks/hypotheses/H11.html",
  "audit/hypotheses/H11/H11_analysis_preparation.qmd",
  paste0(
    "_build/nathealth/audit/hypotheses/H11/",
    "H11_analysis_preparation.html"
  ),
  "tests/hypotheses/H11/test_h11_stage3_reader_report.R",
  "tests/hypotheses/H11/test_h11_report016_hourly_disposition.R",
  "tests/hypotheses/H11/test_h11_preparation_report.R",
  "scripts/hypotheses/H11/build_h11_preparation_report_manifest.R",
  "artifacts/12_manifests/H11/H11_stage3_artifact_manifest.csv",
  "artifacts/12_manifests/H11/H11_preparation_report_manifest.csv",
  "audit/handoffs/H11_worker_handoff.md",
  "_quarto-nathealth.yml",
  "renv.lock",
  "notebooks/sensitivity_battery.qmd",
  "_build/nathealth/notebooks/sensitivity_battery.html",
  "audit/hypotheses/H11/report018_order60b_environment_retry/H11_gt_semantic_ledger.csv",
  paste0(
    "audit/hypotheses/H11/report018_order60b_environment_retry/",
    "gt_html_semantic_post_render_summary.csv"
  ),
  "audit/report_harmonization/coordination_matrix.csv"
)
dispatch_roles <- c(
  "controlling owner order",
  "result independent acceptance",
  "result acceptance seal",
  "complete preflight checker",
  "dispatch sealer",
  "complete preflight checks",
  "prospective test contract",
  "prospective helper contract",
  "held manifest classifications",
  "companion endpoint contract",
  "companion link contract",
  "held integration state",
  "owner result completion",
  "owner result seal",
  "accepted result source",
  "accepted result endpoint",
  "held companion source",
  "stale companion endpoint",
  "accepted result test",
  "accepted REPORT-016 test",
  "preparation-test preimage",
  "dedicated helper",
  "immutable Stage 3 manifest",
  "held preparation manifest",
  "H11 handoff",
  "normal profile",
  "environment lock",
  "held sensitivity source",
  "held sensitivity endpoint",
  "accepted result semantic ledger",
  "accepted result semantic summary",
  "coordination invariant"
)
dispatch_manifest <- write_manifest(
  dispatch_manifest_path,
  dispatch_members,
  dispatch_roles
)

cat(sprintf(
  paste0(
    "REPORT018_H11_ORDER61_DISPATCH_SEAL=PASS ",
    "checks=11/11 owner=107/107 acceptance=%d/%d dispatch=%d/%d ",
    "matrix=%s R=%s\n"
  ),
  nrow(acceptance_manifest),
  nrow(acceptance_manifest),
  nrow(dispatch_manifest),
  nrow(dispatch_manifest),
  sha256_file("audit/report_harmonization/coordination_matrix.csv"),
  as.character(getRversion())
))
