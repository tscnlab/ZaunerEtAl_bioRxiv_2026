#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE)
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

seal_paths <- function(paths, roles, output_path) {
  stopifnot(
    length(paths) == length(roles),
    !anyDuplicated(paths),
    !output_path %in% paths,
    all(file.exists(paths)),
    !any(dir.exists(paths))
  )
  seal <- data.frame(
    path = paths,
    sha256 = vapply(paths, sha256_file, character(1)),
    bytes = unname(as.numeric(file.info(paths)$size)),
    role = roles,
    stringsAsFactors = FALSE
  )
  readr::write_csv(seal, output_path)
  reread <- readr::read_csv(output_path, show_col_types = FALSE)
  stopifnot(
    nrow(reread) == nrow(seal),
    !anyDuplicated(reread$path),
    !output_path %in% reread$path,
    all(file.exists(reread$path)),
    all(vapply(reread$path, sha256_file, character(1)) == reread$sha256),
    all(unname(as.numeric(file.info(reread$path)$size)) == reread$bytes)
  )
  invisible(seal)
}

review_dir <- paste0(
  "audit/report_harmonization/",
  "report018_h11_order61_stopped_acceptance_and_no_rerender_preflight"
)
acceptance_path <- paste0(
  "audit/report_harmonization/",
  "report018_h11_order61_rendered_stop_independent_acceptance.md"
)
acceptance_manifest_path <- paste0(
  "audit/report_harmonization/",
  "report018_h11_order61_rendered_stop_independent_acceptance_manifest.csv"
)

acceptance_paths <- c(
  acceptance_path,
  "scripts/report_harmonization/check_report018_h11_order61_stop_and_no_rerender_completion.R",
  file.path(review_dir, "order61_stop_and_no_rerender_checks.csv"),
  file.path(review_dir, "owner_manifest_audit.csv"),
  file.path(review_dir, "fixed_identity_audit.csv"),
  file.path(review_dir, "preparation_manifest_live_audit.csv"),
  file.path(review_dir, "table_header_resolution_audit.csv"),
  file.path(review_dir, "shared_source_link_convention_audit.csv"),
  file.path(review_dir, "prospective_no_rerender_contract.csv"),
  file.path(review_dir, "prospective_direct_transitions.csv"),
  file.path(review_dir, "prospective_preparation_test_output.txt"),
  "audit/hypotheses/H11/report018_order61_companion_render/order61_rendered_test_failure.md",
  "audit/hypotheses/H11/report018_order61_companion_render/order61_fail_closed_non_circular_manifest.csv",
  "notebooks/hypotheses/H11.qmd",
  "_build/nathealth/notebooks/hypotheses/H11.html",
  "audit/hypotheses/H11/H11_analysis_preparation.qmd",
  "_build/nathealth/audit/hypotheses/H11/H11_analysis_preparation.qmd",
  "_build/nathealth/audit/hypotheses/H11/H11_analysis_preparation.html",
  "tests/hypotheses/H11/test_h11_preparation_report.R",
  "scripts/hypotheses/H11/build_h11_preparation_report_manifest.R",
  "artifacts/12_manifests/H11/H11_preparation_report_manifest.csv",
  "scripts/pipeline/hypothesis_preparation_provenance_contract.R",
  "tests/hypotheses/H11/test_h11_stage3_reader_report.R",
  "tests/hypotheses/H11/test_h11_report016_hourly_disposition.R",
  "artifacts/12_manifests/H11/H11_stage3_artifact_manifest.csv",
  "audit/handoffs/H11_worker_handoff.md",
  "_quarto-nathealth.yml",
  "renv.lock",
  "notebooks/sensitivity_battery.qmd",
  "_build/nathealth/notebooks/sensitivity_battery.html",
  "audit/report_harmonization/coordination_matrix.csv"
)
acceptance_roles <- c(
  "independent stopped acceptance",
  "independent R 4.6.1 checker",
  "independent check summary",
  "owner-seal audit",
  "fixed-identity audit",
  "preparation-manifest audit",
  "semantic header-token audit",
  "project-wide source-link audit",
  "prospective no-rerender contract",
  "prospective direct transitions",
  "prospective full-test output",
  "owner fail-closed record",
  "owner non-circular seal",
  "accepted result source",
  "accepted result endpoint",
  "accepted companion source",
  "source-identical build QMD",
  "fresh companion endpoint",
  "current preparation-test preimage",
  "dedicated helper",
  "truthful current preparation manifest",
  "unchanged shared verifier",
  "accepted Stage 3 test",
  "accepted REPORT-016 test",
  "immutable Stage 3 manifest",
  "H11 handoff",
  "normal profile",
  "environment lock",
  "held sensitivity source",
  "held sensitivity endpoint",
  "coordination invariant"
)
seal_paths(
  acceptance_paths,
  acceptance_roles,
  acceptance_manifest_path
)

order_path <- paste0(
  "audit/report_harmonization/owner_orders/",
  "61a_h11_companion_no_rerender_local_test_and_acceptance.md"
)
dispatch_manifest_path <- paste0(
  "audit/report_harmonization/",
  "report018_h11_order61a_dispatch_manifest.csv"
)
dispatch_paths <- c(
  order_path,
  acceptance_path,
  acceptance_manifest_path,
  "scripts/report_harmonization/check_report018_h11_order61_stop_and_no_rerender_completion.R",
  "scripts/report_harmonization/seal_report018_h11_order61_acceptance_and_order61a.R",
  file.path(review_dir, "order61_stop_and_no_rerender_checks.csv"),
  file.path(review_dir, "owner_manifest_audit.csv"),
  file.path(review_dir, "fixed_identity_audit.csv"),
  file.path(review_dir, "preparation_manifest_live_audit.csv"),
  file.path(review_dir, "table_header_resolution_audit.csv"),
  file.path(review_dir, "shared_source_link_convention_audit.csv"),
  file.path(review_dir, "prospective_no_rerender_contract.csv"),
  file.path(review_dir, "prospective_direct_transitions.csv"),
  file.path(review_dir, "prospective_preparation_test_output.txt"),
  "audit/hypotheses/H11/report018_order61_companion_render/order61_rendered_test_failure.md",
  "audit/hypotheses/H11/report018_order61_companion_render/order61_fail_closed_non_circular_manifest.csv",
  "audit/report_harmonization/owner_orders/61_h11_companion_test_link_and_target_render.md",
  "audit/report_harmonization/report018_h11_order61_dispatch_manifest.csv",
  "audit/report_harmonization/report018_h11_order61_dispatch_receipt.md",
  "audit/report_harmonization/report018_h11_order61_dispatch_receipt_manifest.csv",
  "notebooks/hypotheses/H11.qmd",
  "_build/nathealth/notebooks/hypotheses/H11.html",
  "audit/hypotheses/H11/H11_analysis_preparation.qmd",
  "_build/nathealth/audit/hypotheses/H11/H11_analysis_preparation.qmd",
  "_build/nathealth/audit/hypotheses/H11/H11_analysis_preparation.html",
  "tests/hypotheses/H11/test_h11_preparation_report.R",
  "scripts/hypotheses/H11/build_h11_preparation_report_manifest.R",
  "artifacts/12_manifests/H11/H11_preparation_report_manifest.csv",
  "scripts/pipeline/hypothesis_preparation_provenance_contract.R",
  "tests/hypotheses/H11/test_h11_stage3_reader_report.R",
  "tests/hypotheses/H11/test_h11_report016_hourly_disposition.R",
  "artifacts/12_manifests/H11/H11_stage3_artifact_manifest.csv",
  "audit/handoffs/H11_worker_handoff.md",
  "_quarto-nathealth.yml",
  "renv.lock",
  "notebooks/sensitivity_battery.qmd",
  "_build/nathealth/notebooks/sensitivity_battery.html",
  "audit/report_harmonization/coordination_matrix.csv"
)
dispatch_roles <- c(
  "controlling owner order",
  "independent stopped acceptance",
  "independent acceptance seal",
  "independent R 4.6.1 checker",
  "dispatch sealer",
  "independent check summary",
  "owner-seal audit",
  "fixed-identity audit",
  "preparation-manifest audit",
  "semantic header-token audit",
  "project-wide source-link audit",
  "prospective no-rerender contract",
  "prospective direct transitions",
  "prospective full-test output",
  "owner fail-closed record",
  "owner non-circular seal",
  "prior controlling owner order",
  "prior dispatch manifest",
  "prior dispatch receipt",
  "prior receipt seal",
  "accepted result source",
  "accepted result endpoint",
  "accepted companion source",
  "source-identical build QMD",
  "fresh companion endpoint",
  "current preparation-test preimage",
  "dedicated helper",
  "truthful current preparation manifest",
  "unchanged shared verifier",
  "accepted Stage 3 test",
  "accepted REPORT-016 test",
  "immutable Stage 3 manifest",
  "H11 handoff",
  "normal profile",
  "environment lock",
  "held sensitivity source",
  "held sensitivity endpoint",
  "coordination invariant"
)
seal_paths(dispatch_paths, dispatch_roles, dispatch_manifest_path)

message(sprintf(
  paste0(
    "REPORT018_H11_ORDER61A_SEAL=PASS acceptance=%d dispatch=%d ",
    "acceptance_sha=%s dispatch_sha=%s order_sha=%s R=%s"
  ),
  length(acceptance_paths),
  length(dispatch_paths),
  sha256_file(acceptance_manifest_path),
  sha256_file(dispatch_manifest_path),
  sha256_file(order_path),
  as.character(getRversion())
))
