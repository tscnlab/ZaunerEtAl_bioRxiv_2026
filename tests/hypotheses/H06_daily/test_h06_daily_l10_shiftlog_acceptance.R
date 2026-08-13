#!/usr/bin/env Rscript

# Focused no-refit identity test for H06-D-005 shifted-log acceptance.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
.libPaths(c(
  file.path(root, "renv/library/macos/R-4.6/aarch64-apple-darwin23"),
  .libPaths()
))
required_packages <- c("digest", "dplyr", "readr", "tibble")
stopifnot(
  identical(as.character(getRversion()), "4.6.1"),
  all(vapply(required_packages, requireNamespace, logical(1), quietly = TRUE))
)

sha256 <- function(path) digest::digest(path, algo = "sha256", file = TRUE)
read_csv <- function(relative_path) {
  readr::read_csv(
    file.path(root, relative_path),
    show_col_types = FALSE,
    na = c("", "NA")
  )
}
verify_file_manifest <- function(relative_path) {
  manifest <- read_csv(relative_path)
  stopifnot(
    identical(
      names(manifest),
      c("relative_path", "sha256", "bytes", "role", "producer", "r_version")
    ),
    nrow(manifest) > 0L,
    !anyDuplicated(manifest$relative_path)
  )
  absolute <- file.path(root, manifest$relative_path)
  stopifnot(
    all(file.exists(absolute)),
    identical(
      unname(vapply(absolute, sha256, character(1))),
      manifest$sha256
    ),
    identical(unname(file.info(absolute)$size), manifest$bytes)
  )
  manifest
}

acceptance_path <- file.path(
  root,
  "audit/decisions/h06_daily_l10_shifted_log_pilot_acceptance.md"
)
gate_path <- file.path(
  root,
  "audit/decisions/h06_daily_l10_shifted_log_pilot_gate.md"
)
acceptance_text <- paste(
  readLines(acceptance_path, warn = FALSE),
  collapse = "\n"
)
gate_text <- paste(readLines(gate_path, warn = FALSE), collapse = "\n")
stopifnot(
  sha256(acceptance_path) ==
    "6485e1d6fdd950aed6c8c983407a55c72085c10059bd4a03120a6746109b9fbb",
  sha256(gate_path) ==
    "7e17e0b12ca8295a40c66cfbde5f574eb1019a54d1248445a46743fbc29bfda6",
  grepl("Decision ID: `H06-D-005`", acceptance_text, fixed = TRUE),
  grepl("shifted-log production stopped", acceptance_text, fixed = TRUE),
  grepl("closes `H06-D-G2P-L10-SHIFTLOG`", acceptance_text, fixed = TRUE),
  grepl("Decision ID: `H06-D-004`", gate_text, fixed = TRUE),
  grepl("do not release the full", tolower(gate_text), fixed = TRUE)
)

expected_frozen <- tibble::tribble(
  ~relative_path,
  ~expected_sha256,
  "audit/hypotheses/H06_daily/09_l10_shiftlog_pilot.qmd",
  "7cf38c446a6bb769abcfe6ce07a70a1df153145ef8cdbe6cc37c0bec65d54480",
  "audit/hypotheses/H06_daily/09_l10_shiftlog_pilot.html",
  "15655a82cf165b6fa927197519a50c552e85e2aa8d7048ab119509836c9c4581",
  "audit/hypotheses/H06_daily/H06_daily_l10_shiftlog_pilot_transition.md",
  "0941cfb61c811ab8b850ecb1fb9cb1569812d00830c4064e597b79f3fa7a3350",
  "artifacts/07_models/H06_daily/H06_daily_l10_shiftlog_pilot_new_models.rds",
  "4631d958521918a5ba9f16743322a1b2bb56dbdb9d8b6e4315c07c45c2b2799d",
  "artifacts/12_manifests/H06_daily/H06_daily_l10_shiftlog_pilot_input_manifest.csv",
  "01c9882d3dbd3d74960e352c93045b383b98a71abc717a0655595c4d8e030336",
  "artifacts/12_manifests/H06_daily/H06_daily_l10_shiftlog_pilot_code_manifest.csv",
  "ac6534b843d48e1a1054da6c9ce5b74f70a5914070b90d1b26079f8f8da54fa2",
  "artifacts/12_manifests/H06_daily/H06_daily_l10_shiftlog_pilot_output_manifest.csv",
  "13ede7841b4bccbc1441c54de048b09983eea08e5159ec86d568ecd0b530e66c",
  "artifacts/12_manifests/H06_daily/H06_daily_l10_shiftlog_pilot_software_manifest.csv",
  "bad5b21b51dc79e83f2e64c10ca4af282d2b7c37f96157c6b3451208bc81a898",
  "audit/hypotheses/H06_daily/H06_daily_l10_shiftlog_pilot_report_manifest.csv",
  "3bd0ef69940f61f263963e99c78bd5f2d6f39812758ddc265bca6fcf4105c93d",
  "tests/hypotheses/H06_daily/test_h06_daily_l10_shiftlog_static.R",
  "8c52d58c630f958b05260ed926de6f4f743047cf1572599ecb2c6fb3cce89d2e",
  "tests/hypotheses/H06_daily/test_h06_daily_l10_shiftlog_pilot.R",
  "6a8476e25397b17cf63545a62bd8c367c1ae3f2b01ea33e9203a296209a72ff6",
  "artifacts/08_diagnostics/H06_daily/H06_daily_l10_shiftlog_historical_preservation_final.csv",
  "f215052bf42ed0e35626dc0064d4c15ac162d7ec36f88b70ce2dfc314ba386f9"
)
frozen_absolute <- file.path(root, expected_frozen$relative_path)
stopifnot(
  all(file.exists(frozen_absolute)),
  identical(
    unname(vapply(frozen_absolute, sha256, character(1))),
    expected_frozen$expected_sha256
  )
)

for (relative_path in expected_frozen$relative_path[grepl(
  "pilot_(input|code|output)_manifest[.]csv$",
  expected_frozen$relative_path
)]) {
  verify_file_manifest(relative_path)
}
report_manifest <- verify_file_manifest(
  "audit/hypotheses/H06_daily/H06_daily_l10_shiftlog_pilot_report_manifest.csv"
)
stopifnot(nrow(report_manifest) == 37L)

pilot_verdict <- read_csv(
  "artifacts/08_diagnostics/H06_daily/H06_daily_l10_shiftlog_pilot_verdict.csv"
)
stopifnot(
  nrow(pilot_verdict) == 3L,
  setequal(
    pilot_verdict$predictor_id,
    c(
      "work_free_day",
      "activity_status",
      "previous_sleep_duration_centered_h"
    )
  ),
  all(
    pilot_verdict$temporal_disposition ==
      "NOT_ACCEPTABLE_POST_AR_RESIDUAL_DEPENDENCE"
  ),
  all(pilot_verdict$overall_pilot_disposition == "NOT_ACCEPTABLE"),
  all(
    pilot_verdict$recommendation == "DO_NOT_RELEASE_FULL_L10_SHIFTED_LOG_BATCH"
  )
)

pilot_tests <- read_csv(
  "artifacts/09_tables/H06_daily/H06_daily_l10_shiftlog_pilot_model_tests.csv"
)
stopifnot(
  nrow(pilot_tests) == 6L,
  all(pilot_tests$metric_slot == 3L),
  all(pilot_tests$test_status == "ESTIMABLE_PILOT_RAW_ONLY"),
  all(pilot_tests$multiplicity_status == "PILOT_RAW_ONLY_NO_BH_UPDATE"),
  all(is.na(pilot_tests$bh_adjusted_p_value)),
  all(is.na(pilot_tests$adjusted_decision))
)

two_part_tests <- read_csv(
  "artifacts/09_tables/H06_daily/H06_daily_l10_metric011_model_tests.csv"
) |>
  dplyr::filter(.data$component == "joint_two_part")
stopifnot(
  nrow(two_part_tests) == 12L,
  setequal(two_part_tests$dataset_id, c("primary", "gap_timing_unaware")),
  all(two_part_tests$placement_id == "near_eye"),
  all(two_part_tests$metric_slot == 3L),
  all(two_part_tests$test_status == "NON_ESTIMABLE_COMPONENT_FAILURE"),
  all(is.na(two_part_tests$raw_p_value)),
  all(is.na(two_part_tests$diagnostic_raw_p_value))
)

bh_slots <- read_csv(
  "artifacts/09_tables/H06_daily/H06_daily_l10_metric011_bh_slot_families.csv"
) |>
  dplyr::filter(.data$metric_slot == 3L)
stopifnot(
  nrow(bh_slots) == 12L,
  all(bh_slots$slot_status == "NON_ESTIMABLE_COMPONENT_FAILURE"),
  all(is.na(bh_slots$raw_p_value)),
  all(is.na(bh_slots$bh_adjusted_p_value)),
  all(is.na(bh_slots$adjusted_decision)),
  all(bh_slots$family_slots_required == 15L),
  all(bh_slots$family_status == "INCOMPLETE_1_OF_15_NO_BH_DECISION")
)

historical <- read_csv(
  "artifacts/08_diagnostics/H06_daily/H06_daily_l10_shiftlog_historical_preservation_final.csv"
)
historical_absolute <- file.path(root, historical$relative_path)
stopifnot(
  nrow(historical) == 118L,
  all(historical$file_exists),
  all(historical$preserved_byte_for_byte),
  all(historical$preserved_final),
  all(file.exists(historical_absolute)),
  identical(
    unname(vapply(historical_absolute, sha256, character(1))),
    historical$sha256
  ),
  identical(unname(file.info(historical_absolute)$size), historical$bytes),
  sha256(file.path(root, "audit/handoffs/H06_daily_worker_handoff.md")) ==
    "c3b47b326fcea06f55348a2698f9d609b495e4a03f9c73bf262fa22e4bf57055"
)

acceptance_manifest_relative <- paste0(
  "artifacts/12_manifests/H06_daily/",
  "H06_daily_l10_shiftlog_pilot_acceptance_manifest.csv"
)
acceptance_manifest <- verify_file_manifest(acceptance_manifest_relative)
stopifnot(
  !acceptance_manifest_relative %in% acceptance_manifest$relative_path,
  all(
    c(
      "audit/decisions/h06_daily_l10_shifted_log_pilot_acceptance.md",
      "audit/decisions/h06_daily_l10_shifted_log_pilot_gate.md",
      "audit/hypotheses/H06_daily/H06_daily_l10_shiftlog_pilot_acceptance.md",
      "tests/hypotheses/H06_daily/test_h06_daily_l10_shiftlog_acceptance.R"
    ) %in%
      acceptance_manifest$relative_path
  ),
  all(expected_frozen$relative_path %in% acceptance_manifest$relative_path)
)

addendum_path <- file.path(
  root,
  "audit/hypotheses/H06_daily/H06_daily_l10_shiftlog_pilot_acceptance.md"
)
addendum_text <- paste(readLines(addendum_path, warn = FALSE), collapse = "\n")
stopifnot(
  grepl("H06-D-005 / CHG-114", addendum_text, fixed = TRUE),
  grepl("approved_stopped", addendum_text, fixed = TRUE),
  grepl(
    "NOT_ACCEPTABLE_POST_AR_RESIDUAL_DEPENDENCE",
    addendum_text,
    fixed = TRUE
  ),
  grepl("PILOT_RAW_ONLY_NO_BH_UPDATE", addendum_text, fixed = TRUE),
  grepl(
    "There is no automatic analytical next step",
    addendum_text,
    fixed = TRUE
  )
)

forbidden <- unlist(lapply(
  c(
    "artifacts/06_model_data/H06_daily",
    "artifacts/07_models/H06_daily",
    "artifacts/08_diagnostics/H06_daily",
    "artifacts/09_tables/H06_daily",
    "artifacts/10_figures/H06_daily",
    "artifacts/11_source_data/H06_daily"
  ),
  function(directory) {
    list.files(
      file.path(root, directory),
      pattern = "^H06_daily_l10_shiftlog_(production|influence|bh)",
      full.names = TRUE
    )
  }
))
stopifnot(length(forbidden) == 0L)

cat(
  paste0(
    "H06-D-005 shifted-log acceptance tests passed: controlling decisions ",
    "pinned; 3 temporal failures retained; 6 pilot tests remain raw-only ",
    "with no BH update; 12 two-part joint L10 slots remain non-estimable ",
    "with p=NA; 118 historical identities preserved; full batch stopped.\n"
  )
)
