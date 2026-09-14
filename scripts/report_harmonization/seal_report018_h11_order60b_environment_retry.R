#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE, warn = 2)

required_packages <- c("digest", "readr")
missing_packages <- required_packages[
  !vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
]
if (length(missing_packages)) {
  stop(
    "Missing synchronized project package(s): ",
    paste(missing_packages, collapse = ", "),
    call. = FALSE
  )
}

assert_true <- function(value, message) {
  if (!isTRUE(value)) stop(message, call. = FALSE)
}

sha256_file <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
}

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = "."),
  winslash = "/",
  mustWork = TRUE
)
setwd(root)

assert_true(
  identical(as.character(getRversion()), "4.6.1"),
  sprintf("Order 60b sealing requires R 4.6.1, found %s.", getRversion())
)

identity_rows <- function(paths, roles) {
  assert_true(length(paths) == length(roles), "Path and role counts differ")
  assert_true(all(file.exists(paths)), "A seal member is missing")
  data.frame(
    path = paths,
    sha256 = vapply(paths, sha256_file, character(1)),
    bytes = as.numeric(file.info(paths)$size),
    role = roles,
    stringsAsFactors = FALSE
  )
}

acceptance_path <- paste0(
  "audit/report_harmonization/",
  "report018_h11_order60a_preflight_stop_independent_acceptance.md"
)
acceptance_manifest_path <- paste0(
  "audit/report_harmonization/",
  "report018_h11_order60a_preflight_stop_independent_acceptance_manifest.csv"
)
verification_path <- paste0(
  "audit/report_harmonization/",
  "report018_h11_order60a_preflight_stop_independent_verification.csv"
)
checker_path <- paste0(
  "scripts/report_harmonization/",
  "check_report018_h11_order60a_preflight_stop.R"
)
sealer_path <- paste0(
  "scripts/report_harmonization/",
  "seal_report018_h11_order60b_environment_retry.R"
)
owner60a_root <- "audit/hypotheses/H11/report018_order60a_environment_retry"

acceptance_paths <- c(
  acceptance_path,
  verification_path,
  checker_path,
  sealer_path,
  file.path(owner60a_root, "order60a_preflight_fail_closed_record.md"),
  file.path(owner60a_root, "order60a_preflight_fail_closed_non_circular_manifest.csv"),
  file.path(owner60a_root, "owner_seal_mismatch.csv"),
  file.path(owner60a_root, "independent_checker_execution.csv"),
  file.path(owner60a_root, "independent_checker_output.txt"),
  file.path(owner60a_root, "render_and_qa_status.csv"),
  "audit/report_harmonization/report018_h11_order60_environment_stop_independent_acceptance.md",
  "audit/report_harmonization/report018_h11_order60_environment_stop_independent_acceptance_manifest.csv",
  "audit/hypotheses/H11/report018_order60_result_fail_closed/order60_fail_closed_non_circular_evidence_manifest.csv",
  "audit/report_harmonization/report018_h11_order60a_dispatch_manifest.csv",
  "audit/report_harmonization/coordination_matrix.csv",
  "notebooks/hypotheses/H11.qmd",
  "audit/hypotheses/H11/H11_analysis_preparation.qmd",
  "_build/nathealth/notebooks/hypotheses/H11.html",
  "_build/nathealth/audit/hypotheses/H11/H11_analysis_preparation.html",
  "notebooks/sensitivity_battery.qmd",
  "_build/nathealth/notebooks/sensitivity_battery.html",
  "_quarto-nathealth.yml",
  "renv.lock"
)
acceptance_roles <- c(
  "independent acceptance",
  "independent verification",
  "transition-aware checker",
  "non-circular sealer",
  "owner Order 60a stop record",
  "owner Order 60a stop seal",
  "exact matrix mismatch",
  "historical checker execution",
  "historical checker output",
  "unconsumed render and held scopes",
  "Order 60 environment acceptance",
  "Order 60 environment acceptance seal",
  "historical Order 60 owner seal",
  "Order 60a dispatch seal",
  "current coordination matrix",
  "held result source",
  "held companion source",
  "stale result endpoint",
  "held companion endpoint",
  "held sensitivity source",
  "held sensitivity endpoint",
  "normal profile",
  "lockfile"
)
acceptance <- identity_rows(acceptance_paths, acceptance_roles)
assert_true(!anyDuplicated(acceptance$path), "Duplicate acceptance path")
assert_true(!acceptance_manifest_path %in% acceptance$path, "Circular acceptance seal")
readr::write_csv(acceptance, acceptance_manifest_path)

order_path <- "audit/report_harmonization/owner_orders/60b_h11_matrix_transition_and_sass_retry.md"
release_path <- "audit/report_harmonization/report018_h11_order60b_environment_retry_release.md"
dispatch_manifest_path <- "audit/report_harmonization/report018_h11_order60b_dispatch_manifest.csv"

dispatch_paths <- c(
  order_path,
  release_path,
  acceptance_path,
  acceptance_manifest_path,
  verification_path,
  checker_path,
  sealer_path,
  file.path(owner60a_root, "order60a_preflight_fail_closed_record.md"),
  file.path(owner60a_root, "order60a_preflight_fail_closed_non_circular_manifest.csv"),
  file.path(owner60a_root, "owner_seal_mismatch.csv"),
  "audit/report_harmonization/owner_orders/60a_h11_sass_cache_environment_retry.md",
  "audit/report_harmonization/report018_h11_order60a_dispatch_manifest.csv",
  "audit/report_harmonization/report018_h11_order60a_dispatch_receipt_manifest.csv",
  "audit/report_harmonization/report018_h11_order60_environment_stop_independent_acceptance_manifest.csv",
  "audit/report_harmonization/report018_h11_result_complete_preflight.md",
  "audit/report_harmonization/report018_h11_result_complete_preflight_manifest.csv",
  "scripts/report_harmonization/check_report018_h10_order59a_and_h11_result_preflight.R",
  "notebooks/hypotheses/H11.qmd",
  "audit/hypotheses/H11/H11_analysis_preparation.qmd",
  "_build/nathealth/notebooks/hypotheses/H11.html",
  "_build/nathealth/audit/hypotheses/H11/H11_analysis_preparation.html",
  "tests/hypotheses/H11/test_h11_stage3_reader_report.R",
  "tests/hypotheses/H11/test_h11_report016_hourly_disposition.R",
  "tests/hypotheses/H11/test_h11_preparation_report.R",
  "scripts/hypotheses/H11/build_h11_preparation_report_manifest.R",
  "artifacts/12_manifests/H11/H11_stage3_artifact_manifest.csv",
  "artifacts/12_manifests/H11/H11_preparation_report_manifest.csv",
  "audit/handoffs/H11_worker_handoff.md",
  "notebooks/sensitivity_battery.qmd",
  "_build/nathealth/notebooks/sensitivity_battery.html",
  "_quarto-nathealth.yml",
  "renv.lock",
  "audit/report_harmonization/coordination_matrix.csv"
)
dispatch_roles <- c(
  "controlling corrected retry order",
  "corrected retry release",
  "independent Order 60a stop acceptance",
  "independent Order 60a stop seal",
  "independent verification",
  "transition-aware checker",
  "non-circular sealer",
  "owner Order 60a stop record",
  "owner Order 60a stop seal",
  "exact matrix mismatch",
  "historical Order 60a order",
  "historical Order 60a dispatch",
  "historical Order 60a dispatch receipt",
  "Order 60 environment acceptance seal",
  "complete H11 preflight",
  "complete H11 preflight seal",
  "unchanged complete H11 checker",
  "held result source",
  "held companion source",
  "stale result endpoint",
  "held companion endpoint",
  "historical Stage 3 test",
  "historical REPORT-016 test",
  "held preparation test",
  "held preparation helper",
  "immutable Stage 3 manifest",
  "held preparation manifest",
  "H11 handoff",
  "held sensitivity source",
  "held sensitivity endpoint",
  "normal profile",
  "lockfile",
  "unchanged coordination matrix"
)
dispatch <- identity_rows(dispatch_paths, dispatch_roles)
assert_true(!anyDuplicated(dispatch$path), "Duplicate dispatch path")
assert_true(!dispatch_manifest_path %in% dispatch$path, "Circular dispatch seal")
readr::write_csv(dispatch, dispatch_manifest_path)

cat(
  sprintf(
    "REPORT018_H11_ORDER60B_SEAL=PASS acceptance=%d/%d dispatch=%d/%d matrix=unchanged R=%s\n",
    nrow(acceptance),
    nrow(acceptance),
    nrow(dispatch),
    nrow(dispatch),
    getRversion()
  )
)
