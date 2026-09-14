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
  sprintf("Order 60a sealing requires R 4.6.1, found %s.", getRversion())
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
  "report018_h11_order60_environment_stop_independent_acceptance.md"
)
acceptance_manifest_path <- paste0(
  "audit/report_harmonization/",
  "report018_h11_order60_environment_stop_independent_acceptance_manifest.csv"
)
verification_path <- paste0(
  "audit/report_harmonization/",
  "report018_h11_order60_environment_stop_independent_verification.csv"
)
probe_path <- paste0(
  "audit/report_harmonization/",
  "report018_h11_order60_sass_cache_probe.md"
)
checker_path <- paste0(
  "scripts/report_harmonization/",
  "check_report018_h11_order60_environment_stop.R"
)
sealer_path <- paste0(
  "scripts/report_harmonization/",
  "seal_report018_h11_order60a_environment_retry.R"
)
owner_root <- "audit/hypotheses/H11/report018_order60_result_fail_closed"

acceptance_paths <- c(
  acceptance_path,
  verification_path,
  probe_path,
  checker_path,
  sealer_path,
  file.path(owner_root, "order60_fail_closed_record.md"),
  file.path(owner_root, "order60_fail_closed_non_circular_evidence_manifest.csv"),
  file.path(owner_root, "render_execution.csv"),
  file.path(owner_root, "render_output.txt"),
  file.path(owner_root, "build_inventory_prerender.csv"),
  file.path(owner_root, "build_inventory_postfailure.csv"),
  file.path(owner_root, "protected_inventory_prerender.csv"),
  file.path(owner_root, "protected_inventory_postfailure.csv"),
  file.path(owner_root, "semantic_inventory_postfailure.csv"),
  file.path(owner_root, "process_inventory_postfailure.csv"),
  "audit/report_harmonization/owner_orders/60_h11_result_report018_render.md",
  "audit/report_harmonization/report018_h11_order60_dispatch_manifest.csv",
  "audit/report_harmonization/report018_h11_result_complete_preflight.md",
  "audit/report_harmonization/report018_h11_result_complete_preflight_manifest.csv",
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
  "Sass-cache probe",
  "independent checker",
  "non-circular sealer",
  "owner stopped record",
  "owner stopped seal",
  "sole render execution",
  "sole render console",
  "pre-render build inventory",
  "post-failure build inventory",
  "pre-render protected inventory",
  "post-failure protected inventory",
  "empty semantic inventory",
  "owner process teardown",
  "original owner order",
  "original dispatch seal",
  "complete preflight",
  "complete preflight seal",
  "held result source",
  "held companion source",
  "stale result endpoint",
  "held companion endpoint",
  "held sensitivity source",
  "held sensitivity endpoint",
  "normal profile",
  "lockfile"
)
acceptance_manifest <- identity_rows(acceptance_paths, acceptance_roles)
assert_true(!anyDuplicated(acceptance_manifest$path), "Acceptance paths are duplicated")
assert_true(
  !acceptance_manifest_path %in% acceptance_manifest$path,
  "Acceptance manifest is circular"
)
readr::write_csv(acceptance_manifest, acceptance_manifest_path)

order_path <- "audit/report_harmonization/owner_orders/60a_h11_sass_cache_environment_retry.md"
release_path <- "audit/report_harmonization/report018_h11_order60a_environment_retry_release.md"
dispatch_manifest_path <- "audit/report_harmonization/report018_h11_order60a_dispatch_manifest.csv"

dispatch_paths <- c(
  order_path,
  release_path,
  acceptance_path,
  acceptance_manifest_path,
  verification_path,
  probe_path,
  checker_path,
  sealer_path,
  file.path(owner_root, "order60_fail_closed_record.md"),
  file.path(owner_root, "order60_fail_closed_non_circular_evidence_manifest.csv"),
  file.path(owner_root, "render_execution.csv"),
  file.path(owner_root, "render_output.txt"),
  file.path(owner_root, "build_inventory_postfailure.csv"),
  file.path(owner_root, "protected_inventory_postfailure.csv"),
  "audit/report_harmonization/owner_orders/60_h11_result_report018_render.md",
  "audit/report_harmonization/report018_h11_order60_dispatch_manifest.csv",
  "audit/report_harmonization/report018_h11_order60_dispatch_receipt_manifest.csv",
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
  "controlling retry order",
  "retry release record",
  "independent stop acceptance",
  "independent stop seal",
  "independent verification",
  "Sass-cache probe",
  "independent checker",
  "non-circular sealer",
  "owner stopped record",
  "owner stopped seal",
  "sole failed render execution",
  "sole failed render console",
  "unchanged build inventory",
  "unchanged protected inventory",
  "original owner order",
  "original dispatch seal",
  "original dispatch receipt seal",
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
  "pre-dispatch coordination matrix"
)
dispatch_manifest <- identity_rows(dispatch_paths, dispatch_roles)
assert_true(!anyDuplicated(dispatch_manifest$path), "Dispatch paths are duplicated")
assert_true(
  !dispatch_manifest_path %in% dispatch_manifest$path,
  "Dispatch manifest is circular"
)
readr::write_csv(dispatch_manifest, dispatch_manifest_path)

cat(
  sprintf(
    paste0(
      "REPORT018_H11_ORDER60A_SEAL=PASS acceptance=%d/%d ",
      "dispatch=%d/%d R=%s\n"
    ),
    nrow(acceptance_manifest),
    nrow(acceptance_manifest),
    nrow(dispatch_manifest),
    nrow(dispatch_manifest),
    getRversion()
  )
)
