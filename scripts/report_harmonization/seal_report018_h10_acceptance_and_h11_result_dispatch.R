suppressPackageStartupMessages({
  library(openssl)
  library(readr)
})

project_root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
setwd(project_root)

sha256_file <- function(path) {
  stopifnot(file.exists(path), !dir.exists(path))
  unclass(as.character(openssl::sha256(file(path))))
}

bytes_file <- function(path) {
  as.numeric(file.info(path)$size)
}

require_hash <- function(path, expected) {
  observed <- sha256_file(path)
  if (!identical(unname(observed), unname(expected))) {
    stop(
      sprintf(
        "Identity mismatch for %s: expected %s, observed %s",
        path,
        expected,
        observed
      ),
      call. = FALSE
    )
  }
  invisible(TRUE)
}

write_manifest <- function(path, members) {
  stopifnot(!path %in% members$path)
  stopifnot(!anyDuplicated(members$path))
  stopifnot(all(file.exists(members$path)))
  members$sha256 <- vapply(members$path, sha256_file, character(1))
  members$bytes <- vapply(members$path, bytes_file, numeric(1))
  members <- members[, c("path", "sha256", "bytes", "role")]
  readr::write_csv(members, path)
  replay <- readr::read_csv(path, show_col_types = FALSE)
  stopifnot(!anyDuplicated(replay$path), !path %in% replay$path)
  stopifnot(identical(
    replay$sha256,
    unname(vapply(replay$path, sha256_file, character(1)))
  ))
  stopifnot(identical(
    as.numeric(replay$bytes),
    unname(vapply(replay$path, bytes_file, numeric(1)))
  ))
  invisible(members)
}

fixed <- c(
  "notebooks/hypotheses/H10.qmd" = "0cf302f74c482168c5f5d4c640bbc6a80ef451333f7d76f3c3be204ac1b5f64d",
  "audit/hypotheses/H10/H10_analysis_preparation.qmd" = "706fe46f293bd09bfd3cb75c14bc3082410a452acfff666d76219f266fded1a6",
  "_build/nathealth/notebooks/hypotheses/H10.html" = "37d5ffb4b5e33f23690e222c90ac6c26b70a222298c7c631005d41e3db4bee14",
  "_build/nathealth/audit/hypotheses/H10/H10_analysis_preparation.html" = "dc2aa864a1b1edf01043444af425df40564779e83b72f00c206068fdba19a7b9",
  "scripts/hypotheses/H10/build_h10_preparation_report_manifest.R" = "26619260657ec0cb1d7ac7614af9e3e349a524ee242dd5645b27e31f4cb142f0",
  "artifacts/12_manifests/H10/H10_preparation_report_manifest.csv" = "4ebb3e9a32a09f3b289920aea325fadf3eaf0f727087d457f3f568b910a39fe0",
  "audit/hypotheses/H10/report018_order59a_companion_recovery_completion/order59a_acceptance_record.md" = "cc4768d579ca48c2fbd3b2d4fd663e7f30bb2e4dfc9a7fc8c228d593ee8eee80",
  "audit/hypotheses/H10/report018_order59a_companion_recovery_completion/order59a_non_circular_evidence_manifest.csv" = "84ccc551255ffe366bd6dc6040f13ebd2f6530f2887440f266aed458885dc2ca",
  "notebooks/hypotheses/H11.qmd" = "7909ba06782c84223197ab7fcd16493d7ee6e6d8b63c750aa81f17cb97977867",
  "audit/hypotheses/H11/H11_analysis_preparation.qmd" = "3f5a0d2ead03d2cb149451709110b59ba1387401f9ff633dfba1a0663f4b0816",
  "_build/nathealth/notebooks/hypotheses/H11.html" = "c5724711ad1aa94631df0b6186fee92398d414ae02690ade08f320b29d6b6db7",
  "_build/nathealth/audit/hypotheses/H11/H11_analysis_preparation.html" = "fd6307a6a2e9365f95f18f1fd668165cf833847cab58bac9d3be1e8a9b6dde11",
  "tests/hypotheses/H11/test_h11_stage3_reader_report.R" = "088e0a1235d2561515613271e497ae55124a2bbe39f5fa9e2173583df131dea8",
  "tests/hypotheses/H11/test_h11_report016_hourly_disposition.R" = "3d945c2b813ffaa2291ddebbe01f1f45c5c4ae7fe10256c9a1c8b15c3b531e7b",
  "tests/hypotheses/H11/test_h11_preparation_report.R" = "7c565618a4d3ec1c2240419b1daead2189616fce97931dde68e0a9450db8f41f",
  "scripts/hypotheses/H11/build_h11_preparation_report_manifest.R" = "317f31069e6019475023b3097b1d7f1b00435755e0a109e40535fab89b570bf8",
  "artifacts/12_manifests/H11/H11_stage3_artifact_manifest.csv" = "2f55cef62117af71beab6e320fac842489b24be149209ea60a1d54cbd172f645",
  "artifacts/12_manifests/H11/H11_preparation_report_manifest.csv" = "00ce783a5958f6f958db1d2d6d78076760953ad1c51cc18c30abb697557c8e5c",
  "audit/handoffs/H11_worker_handoff.md" = "5f01ac88745d55d749854b41d22ce3bd0afe43f42dbbaded98da7a61e1b53289",
  "_quarto-nathealth.yml" = "80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3",
  "notebooks/sensitivity_battery.qmd" = "d2d1777062dbf58eca69cc58eadd6ad17a7ce80f4a8f335b6828f54ffcbfeb70",
  "_build/nathealth/notebooks/sensitivity_battery.html" = "b9af89c035391db6e39c55064b1de7309220702d626fa2fa274000b22b879780"
)
invisible(Map(require_hash, names(fixed), unname(fixed)))

matrix_path <- "audit/report_harmonization/coordination_matrix.csv"
matrix_snapshot <- "audit/report_harmonization/report018_h11_result_preflight/coordination_matrix_pre_dispatch.csv"
if (!file.exists(matrix_snapshot)) {
  stopifnot(file.copy(matrix_path, matrix_snapshot, overwrite = FALSE))
}
require_hash(
  matrix_snapshot,
  "8302b4906daa98c247025281d23bb1b896f456f0a6adf34b4068d17542a6c7fa"
)

h10_acceptance_manifest <-
  "audit/report_harmonization/report018_h10_order59a_companion_independent_acceptance_manifest.csv"
h10_members <- data.frame(
  path = c(
    "audit/report_harmonization/report018_h10_order59a_companion_independent_acceptance.md",
    "audit/hypotheses/H10/report018_order59a_companion_recovery_completion/order59a_acceptance_record.md",
    "audit/hypotheses/H10/report018_order59a_companion_recovery_completion/order59a_non_circular_evidence_manifest.csv",
    "notebooks/hypotheses/H10.qmd",
    "audit/hypotheses/H10/H10_analysis_preparation.qmd",
    "_build/nathealth/notebooks/hypotheses/H10.html",
    "_build/nathealth/audit/hypotheses/H10/H10_analysis_preparation.html",
    "scripts/hypotheses/H10/build_h10_preparation_report_manifest.R",
    "tests/hypotheses/H10/test_h10_preparation_report.R",
    "artifacts/12_manifests/H10/H10_preparation_report_manifest.csv",
    "audit/hypotheses/H10/report018_order59a_companion_recovery_completion/static_checks_postqa.csv",
    "audit/hypotheses/H10/report018_order59a_companion_recovery_completion/visual_qa_observations.csv",
    "audit/hypotheses/H10/report018_order59a_companion_recovery_completion/server_lifecycle.csv",
    "audit/hypotheses/H10/report018_order59a_companion_recovery_completion/build_inventory_preqa.csv",
    "audit/hypotheses/H10/report018_order59a_companion_recovery_completion/build_inventory_postqa.csv",
    "audit/hypotheses/H10/report018_order59a_companion_recovery_completion/protected_inventory_preqa.csv",
    "audit/hypotheses/H10/report018_order59a_companion_recovery_completion/protected_inventory_postqa.csv",
    "scripts/report_harmonization/check_report018_h10_order59a_and_h11_result_preflight.R",
    "audit/report_harmonization/report018_h11_result_preflight/report018_h10_h11_checks_preflight.csv"
  ),
  role = c(
    "independent acceptance",
    "owner acceptance",
    "owner non-circular seal",
    "accepted result source",
    "accepted companion source",
    "accepted result endpoint",
    "accepted companion endpoint",
    "accepted helper",
    "accepted preparation test",
    "live-exact preparation manifest",
    "post-QA static checks",
    "visual observations",
    "loopback lifecycle",
    "pre-QA build inventory",
    "post-QA build inventory",
    "pre-QA protected inventory",
    "post-QA protected inventory",
    "independent R 4.6.1 checker",
    "independent checker results"
  ),
  stringsAsFactors = FALSE
)
write_manifest(h10_acceptance_manifest, h10_members)

h11_preflight_manifest <-
  "audit/report_harmonization/report018_h11_result_complete_preflight_manifest.csv"
h11_preflight_members <- data.frame(
  path = c(
    "audit/report_harmonization/report018_h11_result_complete_preflight.md",
    "audit/report_harmonization/report018_h11_result_preflight/process_inventory_pre_dispatch.csv",
    matrix_snapshot,
    "scripts/report_harmonization/check_report018_h10_order59a_and_h11_result_preflight.R",
    "scripts/report_harmonization/seal_report018_h10_acceptance_and_h11_result_dispatch.R",
    "audit/report_harmonization/report018_h11_result_preflight/h11_fixed_identities_preflight.csv",
    "audit/report_harmonization/report018_h11_result_preflight/h11_held_preparation_manifest_transitions_preflight.csv",
    "audit/report_harmonization/report018_h11_result_preflight/h11_scientific_assets_preflight.csv",
    "audit/report_harmonization/report018_h11_result_preflight/h11_source_link_audit.csv",
    "audit/report_harmonization/report018_h11_result_preflight/h11_stage3_transitions_preflight.csv",
    "audit/report_harmonization/report018_h11_result_preflight/h11_transition_test_execution_preflight.csv",
    "audit/report_harmonization/report018_h11_result_preflight/report018_h10_h11_checks_preflight.csv",
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
    "_quarto-nathealth.yml",
    "notebooks/sensitivity_battery.qmd",
    "_build/nathealth/notebooks/sensitivity_battery.html",
    "audit/report_harmonization/report018_h10_order59a_companion_independent_acceptance.md",
    h10_acceptance_manifest
  ),
  role = c(
    "complete H11 read-only preflight",
    "pre-dispatch process classification",
    "pre-dispatch coordination snapshot",
    "independent preflight checker",
    "non-circular sealer",
    "fixed identity audit",
    "held preparation transition set",
    "scientific asset inventory",
    "source and link audit",
    "Stage 3 transition set",
    "complete transition-aware test replay",
    "preflight domain checks",
    "held result source",
    "held companion source",
    "stale result endpoint",
    "held companion endpoint",
    "historical Stage 3 test",
    "historical REPORT-016 test",
    "held preparation test",
    "held helper",
    "immutable Stage 3 manifest",
    "held preparation manifest",
    "H11 handoff",
    "normal profile",
    "held sensitivity source",
    "held sensitivity endpoint",
    "controlling H10 closure",
    "H10 closure seal"
  ),
  stringsAsFactors = FALSE
)
write_manifest(h11_preflight_manifest, h11_preflight_members)

h11_dispatch_manifest <-
  "audit/report_harmonization/report018_h11_order60_dispatch_manifest.csv"
h11_dispatch_members <- data.frame(
  path = c(
    "audit/report_harmonization/owner_orders/60_h11_result_report018_render.md",
    "audit/report_harmonization/report018_h11_result_complete_preflight.md",
    h11_preflight_manifest,
    "audit/report_harmonization/report018_h10_order59a_companion_independent_acceptance.md",
    h10_acceptance_manifest,
    "scripts/report_harmonization/check_report018_h10_order59a_and_h11_result_preflight.R",
    "scripts/report_harmonization/seal_report018_h10_acceptance_and_h11_result_dispatch.R",
    matrix_snapshot,
    "audit/report_harmonization/report018_h11_result_preflight/process_inventory_pre_dispatch.csv",
    "audit/report_harmonization/report018_h11_result_preflight/h11_fixed_identities_preflight.csv",
    "audit/report_harmonization/report018_h11_result_preflight/h11_held_preparation_manifest_transitions_preflight.csv",
    "audit/report_harmonization/report018_h11_result_preflight/h11_scientific_assets_preflight.csv",
    "audit/report_harmonization/report018_h11_result_preflight/h11_source_link_audit.csv",
    "audit/report_harmonization/report018_h11_result_preflight/h11_stage3_transitions_preflight.csv",
    "audit/report_harmonization/report018_h11_result_preflight/h11_transition_test_execution_preflight.csv",
    "audit/report_harmonization/report018_h11_result_preflight/report018_h10_h11_checks_preflight.csv",
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
    "_quarto-nathealth.yml",
    "notebooks/sensitivity_battery.qmd",
    "_build/nathealth/notebooks/sensitivity_battery.html"
  ),
  role = c(
    "controlling owner order",
    "complete read-only preflight",
    "preflight non-circular seal",
    "H10 serial closure",
    "H10 serial closure seal",
    "durable preflight and post-render checker",
    "dispatch sealer",
    "coordination snapshot",
    "process inventory",
    "fixed pins",
    "held preparation transition set",
    "scientific inventory",
    "source and link audit",
    "Stage 3 transition set",
    "complete test replay",
    "preflight checks",
    "result source",
    "held companion source",
    "stale result HTML",
    "held companion HTML",
    "historical Stage 3 test",
    "historical REPORT-016 test",
    "held preparation test",
    "held preparation helper",
    "immutable Stage 3 manifest",
    "held preparation manifest",
    "H11 handoff",
    "normal profile",
    "held sensitivity source",
    "held sensitivity endpoint"
  ),
  stringsAsFactors = FALSE
)
write_manifest(h11_dispatch_manifest, h11_dispatch_members)

matrix_before <- readr::read_csv(
  matrix_snapshot,
  col_types = readr::cols(.default = readr::col_character())
)
matrix_after <- matrix_before
h10 <- matrix_after$logical_order == "12"
h11 <- matrix_after$logical_order == "13"
stopifnot(sum(h10) == 1L, sum(h11) == 1L)

matrix_after$current_task_status_2026_08_12[h10] <-
  "idle_result_and_companion_accepted"
matrix_after$harmonization_review_status[h10] <-
  "report018_result_and_companion_independently_accepted"
matrix_after$notes[h10] <- paste0(
  matrix_after$notes[h10],
  " Order 59a is independently accepted: the helper ran once after the sealed file-state gate, the current preparation manifest is 269/269 live exact, the strict preparation test passed once, and complete semantic, link, protected, desktop, narrow, 200-percent-equivalent, 170-mm, and teardown checks pass. H10 result and companion are closed under the central order59a acceptance."
)

matrix_after$current_task_status_2026_08_12[h11] <-
  "active_order60_h11_result_target_render"
matrix_after$instruction_sent[h11] <- "yes"
matrix_after$harmonization_review_status[h11] <-
  "report018_order60_result_render_released"
matrix_after$notes[h11] <- paste0(
  matrix_after$notes[h11],
  " Complete REPORT-018 result-only preflight passes under R 4.6.1: 15 tables, eight figures, 193 scientific assets, 34 source-identical build resources, exact two-row Stage 3 and four-row held preparation transition sets, complete transition-aware Stage 3 and REPORT-016 tests, zero build symlinks, and no competing H11 process. Order 60 releases exactly one H11 result target. The companion and sensitivity battery remain held."
)

unchanged_rows <- !matrix_before$logical_order %in% c("12", "13")
stopifnot(identical(
  matrix_before[unchanged_rows, ],
  matrix_after[unchanged_rows, ]
))
readr::write_csv(matrix_after, matrix_path)

matrix_replay <- readr::read_csv(
  matrix_path,
  col_types = readr::cols(.default = readr::col_character())
)
stopifnot(nrow(matrix_replay) == 15L, ncol(matrix_replay) == 16L)
stopifnot(!anyDuplicated(matrix_replay$logical_order))
stopifnot(
  identical(
    matrix_replay$current_task_status_2026_08_12[
      matrix_replay$logical_order == "12"
    ],
    "idle_result_and_companion_accepted"
  )
)
stopifnot(
  identical(
    matrix_replay$current_task_status_2026_08_12[
      matrix_replay$logical_order == "13"
    ],
    "active_order60_h11_result_target_render"
  )
)

cat(
  sprintf(
    paste0(
      "REPORT018_H10_H11_DISPATCH_SEAL=PASS ",
      "H10=%d/%d H11_preflight=%d/%d H11_dispatch=%d/%d matrix=%dx%d\n"
    ),
    nrow(h10_members),
    nrow(h10_members),
    nrow(h11_preflight_members),
    nrow(h11_preflight_members),
    nrow(h11_dispatch_members),
    nrow(h11_dispatch_members),
    nrow(matrix_replay),
    ncol(matrix_replay)
  )
)
