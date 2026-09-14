#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE, warn = 2)
suppressPackageStartupMessages({
  library(openssl)
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

identity_rows <- function(paths, roles) {
  stopifnot(length(paths) == length(roles), all(file.exists(paths)))
  data.frame(
    path = paths,
    sha256 = vapply(paths, sha256_file, character(1)),
    bytes = unname(as.numeric(file.info(paths)$size)),
    role = roles,
    stringsAsFactors = FALSE
  )
}

acceptance_path <- paste0(
  "audit/report_harmonization/",
  "report018_h11_order60b_rendered_stop_independent_acceptance.md"
)
acceptance_manifest_path <- paste0(
  "audit/report_harmonization/",
  "report018_h11_order60b_rendered_stop_independent_acceptance_manifest.csv"
)
checker_path <- paste0(
  "scripts/report_harmonization/",
  "check_report018_h11_order60b_rendered_stop_and_downstream_replay.R"
)
replay_root <- paste0(
  "audit/report_harmonization/",
  "report018_h11_order60b_downstream_replay"
)
owner_root <- "audit/hypotheses/H11/report018_order60b_environment_retry"

acceptance_paths <- c(
  acceptance_path,
  checker_path,
  file.path(replay_root, "independent_downstream_replay_checks.csv"),
  file.path(replay_root, "fixed_identity_audit.csv"),
  file.path(replay_root, "rendered_literal_transition_audit.csv"),
  file.path(replay_root, "prospective_stage3_test_transition.csv"),
  file.path(replay_root, "table_header_reference_audit.csv"),
  file.path(replay_root, "prospective_postrender_checker_output.txt"),
  file.path(
    replay_root,
    "prospective_postrender_replay/report018_h10_h11_checks_postrender.csv"
  ),
  file.path(
    replay_root,
    "prospective_postrender_replay/h11_transition_test_execution_postrender.csv"
  ),
  file.path(owner_root, "order60b_rendered_unaccepted_stop.md"),
  file.path(
    owner_root,
    "order60b_rendered_unaccepted_non_circular_manifest.csv"
  ),
  file.path(owner_root, "gt_html_semantic_post_render_summary.csv"),
  file.path(owner_root, "H11_gt_semantic_ledger.csv"),
  file.path(owner_root, "build_delta_postcheckerfailure.csv"),
  file.path(owner_root, "protected_inventory_postcheckerfailure.csv"),
  file.path(owner_root, "sass_cache_inventory_postrender.csv"),
  "_build/nathealth/notebooks/hypotheses/H11.html",
  "notebooks/hypotheses/H11.qmd",
  "audit/hypotheses/H11/H11_analysis_preparation.qmd",
  "tests/hypotheses/H11/test_h11_stage3_reader_report.R",
  "tests/hypotheses/H11/test_h11_report016_hourly_disposition.R",
  "artifacts/12_manifests/H11/H11_stage3_artifact_manifest.csv",
  "artifacts/12_manifests/H11/H11_preparation_report_manifest.csv",
  "audit/report_harmonization/coordination_matrix.csv"
)
acceptance_roles <- c(
  "independent acceptance",
  "independent checker",
  "independent checks",
  "fixed identities",
  "rendered literal transitions",
  "prospective test transition",
  "table header audit",
  "prospective checker output",
  "complete prospective postrender replay",
  "complete prospective test executions",
  "owner stop record",
  "owner stop seal",
  "semantic summary",
  "semantic ledger",
  "exact build delta",
  "protected inventory",
  "Sass cache inventory",
  "rendered result endpoint",
  "result source",
  "held companion source",
  "historical Stage 3 test",
  "historical REPORT-016 test",
  "historical Stage 3 manifest",
  "held preparation manifest",
  "unchanged coordination matrix"
)
acceptance <- identity_rows(acceptance_paths, acceptance_roles)
stopifnot(
  nrow(acceptance) == 25L,
  !anyDuplicated(acceptance$path),
  !acceptance_manifest_path %in% acceptance$path,
  sha256_file(file.path(owner_root, "order60b_rendered_unaccepted_stop.md")) ==
    "665347251001dc4ec8b2adb24529b846f4ff1f3d215831d1c11070f901a1b324",
  sha256_file("_build/nathealth/notebooks/hypotheses/H11.html") ==
    "2c8a34ec47c10b3b4b1be600093cb03837bd0beb3b617f7e04f156529076d21a",
  sha256_file("tests/hypotheses/H11/test_h11_stage3_reader_report.R") ==
    "088e0a1235d2561515613271e497ae55124a2bbe39f5fa9e2173583df131dea8",
  sha256_file("audit/report_harmonization/coordination_matrix.csv") ==
    "c8990a95151ebfd5deb0a1abca3a69ad2c4a1720f30537de13deebab2386b6ac"
)
utils::write.csv(
  acceptance,
  acceptance_manifest_path,
  row.names = FALSE,
  na = ""
)

order_path <- paste0(
  "audit/report_harmonization/owner_orders/",
  "60c_h11_no_rerender_test_contract_and_result_completion.md"
)
sealer_path <- paste0(
  "scripts/report_harmonization/",
  "seal_report018_h11_order60b_acceptance_and_order60c.R"
)
dispatch_manifest_path <- paste0(
  "audit/report_harmonization/",
  "report018_h11_order60c_dispatch_manifest.csv"
)
dispatch_paths <- c(
  order_path,
  acceptance_path,
  acceptance_manifest_path,
  checker_path,
  sealer_path,
  file.path(replay_root, "independent_downstream_replay_checks.csv"),
  file.path(replay_root, "prospective_stage3_test_transition.csv"),
  file.path(
    replay_root,
    "prospective_postrender_replay/report018_h10_h11_checks_postrender.csv"
  ),
  file.path(owner_root, "order60b_rendered_unaccepted_stop.md"),
  file.path(
    owner_root,
    "order60b_rendered_unaccepted_non_circular_manifest.csv"
  ),
  file.path(owner_root, "gt_html_semantic_post_render_summary.csv"),
  file.path(owner_root, "H11_gt_semantic_ledger.csv"),
  "_build/nathealth/notebooks/hypotheses/H11.html",
  "notebooks/hypotheses/H11.qmd",
  "audit/hypotheses/H11/H11_analysis_preparation.qmd",
  "_build/nathealth/audit/hypotheses/H11/H11_analysis_preparation.html",
  "tests/hypotheses/H11/test_h11_stage3_reader_report.R",
  "tests/hypotheses/H11/test_h11_report016_hourly_disposition.R",
  "tests/hypotheses/H11/test_h11_preparation_report.R",
  "scripts/report_harmonization/check_report018_h10_order59a_and_h11_result_preflight.R",
  "artifacts/12_manifests/H11/H11_stage3_artifact_manifest.csv",
  "artifacts/12_manifests/H11/H11_preparation_report_manifest.csv",
  "audit/handoffs/H11_worker_handoff.md",
  "_quarto-nathealth.yml",
  "renv.lock",
  "notebooks/sensitivity_battery.qmd",
  "_build/nathealth/notebooks/sensitivity_battery.html",
  "audit/report_harmonization/coordination_matrix.csv"
)
dispatch_roles <- c(
  "controlling owner order",
  "independent acceptance",
  "independent acceptance seal",
  "independent downstream checker",
  "non-circular sealer",
  "independent checks",
  "exact prospective test transition",
  "complete prospective postrender replay",
  "owner Order 60b stop record",
  "owner Order 60b stop seal",
  "semantic summary",
  "semantic ledger",
  "fixed rendered endpoint",
  "fixed result source",
  "held companion source",
  "held companion endpoint",
  "pre-edit Stage 3 test",
  "held REPORT-016 test",
  "held preparation test",
  "accepted complete checker baseline",
  "historical Stage 3 manifest",
  "held preparation manifest",
  "held handoff",
  "normal profile",
  "lockfile",
  "held sensitivity source",
  "held sensitivity endpoint",
  "unchanged coordination matrix"
)
dispatch <- identity_rows(dispatch_paths, dispatch_roles)
stopifnot(
  nrow(dispatch) == 28L,
  !anyDuplicated(dispatch$path),
  !dispatch_manifest_path %in% dispatch$path
)
utils::write.csv(
  dispatch,
  dispatch_manifest_path,
  row.names = FALSE,
  na = ""
)

cat(sprintf(
  paste0(
    "REPORT018_H11_ORDER60C_SEAL=PASS acceptance=%d/%d ",
    "dispatch=%d/%d matrix=unchanged R=%s\n"
  ),
  nrow(acceptance),
  nrow(acceptance),
  nrow(dispatch),
  nrow(dispatch),
  as.character(getRversion())
))
