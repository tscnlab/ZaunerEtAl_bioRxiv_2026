#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2L) {
  stop(paste0(
    "Usage: check_brown_ba015_cell_hash_correction_v2.R ",
    "<central project root> <Brown worktree root>"
  ))
}

central_root <- normalizePath(args[[1]], mustWork = TRUE)
brown_root <- normalizePath(args[[2]], mustWork = TRUE)
project_library <- file.path(
  central_root,
  "renv/library/macos/R-4.6/aarch64-apple-darwin23"
)
.libPaths(c(project_library, .libPaths()))

stopifnot(R.version.string == "R version 4.6.1 (2026-06-24)")

sha256 <- function(path) {
  unname(digest::digest(
    file = path,
    algo = "sha256",
    serialize = FALSE
  ))
}

verify_manifest <- function(manifest_path, root, expected_rows) {
  manifest <- read.csv(
    manifest_path,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  stopifnot(
    nrow(manifest) == expected_rows,
    !anyDuplicated(manifest$project_relative_path),
    !normalizePath(manifest_path, mustWork = TRUE) %in%
      normalizePath(
        file.path(root, manifest$project_relative_path),
        mustWork = FALSE
      )
  )
  paths <- file.path(root, manifest$project_relative_path)
  stopifnot(all(file.exists(paths)))
  actual_bytes <- unname(file.info(paths)$size)
  actual_hashes <- unname(vapply(paths, sha256, character(1)))
  stopifnot(
    identical(as.numeric(manifest$bytes), as.numeric(actual_bytes)),
    identical(manifest$sha256, actual_hashes)
  )
  invisible(manifest)
}

correction_manifest_path <- file.path(
  central_root,
  paste0(
    "audit/decisions/",
    "brown_adherence_ba015_cell_prediction_hash_clerical_",
    "correction_manifest.csv"
  )
)
correction_manifest <- read.csv(
  correction_manifest_path,
  stringsAsFactors = FALSE,
  check.names = FALSE
)
stopifnot(
  nrow(correction_manifest) == 16L,
  identical(
    names(correction_manifest),
    c("root", "path", "bytes", "sha256", "role")
  ),
  !anyDuplicated(paste(
    correction_manifest$root,
    correction_manifest$path,
    sep = "\r"
  )),
  !any(grepl(
    "clerical_correction_manifest[.]csv$",
    correction_manifest$path
  ))
)
correction_paths <- ifelse(
  correction_manifest$root == "central",
  file.path(central_root, correction_manifest$path),
  file.path(brown_root, correction_manifest$path)
)
stopifnot(all(file.exists(correction_paths)))
stopifnot(
  identical(
    as.numeric(correction_manifest$bytes),
    as.numeric(unname(file.info(correction_paths)$size))
  ),
  identical(
    correction_manifest$sha256,
    unname(vapply(correction_paths, sha256, character(1)))
  )
)

correction_v2_path <- file.path(
  central_root,
  paste0(
    "audit/decisions/",
    "brown_adherence_ba015_checker_directory_filter_recovery.md"
  )
)
correction_v2_text <- paste(
  readLines(correction_v2_path, warn = FALSE),
  collapse = "\n"
)
stopifnot(
  grepl("Correction ID: `BA-015-CORR-002`", correction_v2_text, fixed = TRUE),
  grepl("file.info()$isdir", correction_v2_text, fixed = TRUE),
  grepl("zero `BA-M6` calculations", correction_v2_text, fixed = TRUE)
)

stage2_root <- file.path(
  brown_root,
  "audit/analyses/brown_adherence/stage2_boundary"
)
amendment_root <- file.path(
  stage2_root,
  "site_free_work_vs_equal_site_amendment"
)
stop_root <- file.path(amendment_root, "preflight_clerical_stop")

expected_top_level_files <- sort(c(
  "00_preflight_ba_m6.R",
  "authority_verification.csv",
  "central_authority_manifest_verification.csv",
  "frozen_input_verification.csv",
  "ledger_verification.csv"
))
allowed_top_level_directories <- c(
  "preflight_clerical_stop",
  "preflight_checker_recovery"
)
top_level_entries <- list.files(
  amendment_root,
  recursive = FALSE,
  full.names = TRUE,
  all.files = FALSE
)
top_level_info <- file.info(top_level_entries)
stopifnot(
  nrow(top_level_info) == length(top_level_entries),
  !anyNA(top_level_info$isdir)
)
observed_top_level_files <- sort(basename(
  top_level_entries[!top_level_info$isdir]
))
observed_top_level_directories <- sort(basename(
  top_level_entries[top_level_info$isdir]
))
stopifnot(
  identical(observed_top_level_files, expected_top_level_files),
  "preflight_clerical_stop" %in% observed_top_level_directories,
  all(observed_top_level_directories %in% allowed_top_level_directories)
)

stop_manifest_relative <- paste0(
  "audit/analyses/brown_adherence/stage2_boundary/",
  "site_free_work_vs_equal_site_amendment/preflight_clerical_stop/",
  "preflight_clerical_stop_manifest.csv"
)
stop_manifest_path <- file.path(brown_root, stop_manifest_relative)
stopifnot(
  unname(file.info(stop_manifest_path)$size) == 1982,
  sha256(stop_manifest_path) ==
    paste0(
      "ca910103f50e64e2742abe2c51005b47",
      "e3b1cebe82f5209ac66c9ced554559f6"
    )
)
stop_manifest <- verify_manifest(stop_manifest_path, brown_root, 7L)

stop_record_path <- file.path(stop_root, "clerical_recovery_stop_record.csv")
checker_output_path <- file.path(
  stop_root,
  "central_correction_checker_output.txt"
)
stopifnot(
  sha256(stop_record_path) ==
    paste0(
      "15c4dbaa4c1335f68f347d39c70b1fd4",
      "eb959a130d8d8c6335b58d753236b4ad"
    ),
  sha256(checker_output_path) ==
    paste0(
      "9d55897346a8b85681fee1c8e674856a",
      "fb490023e4d2af17554a51582f333b1e"
    )
)
stop_record <- read.csv(
  stop_record_path,
  stringsAsFactors = FALSE,
  check.names = FALSE
)
value_for <- function(field) {
  value <- stop_record$value[stop_record$field == field]
  stopifnot(length(value) == 1L)
  value
}
stopifnot(
  value_for("status") ==
    "fail_closed_correction_checker_directory_enumeration_defect",
  value_for("checker_attempts") == "1",
  value_for("live_preflight_modified") == "FALSE",
  value_for("BA_M6_calculations") == "0",
  value_for("model_fits") == "0",
  value_for("live_predictions") == "0",
  value_for("TMB_compilations") == "0",
  value_for("QMD_changes") == "0",
  value_for("renders") == "0"
)

live_preflight_path <- file.path(amendment_root, "00_preflight_ba_m6.R")
stopifnot(
  unname(file.info(live_preflight_path)$size) == 20661,
  sha256(live_preflight_path) ==
    paste0(
      "32fd4ea1b84b49a8b96665fe6d09eea",
      "aaa0c3c0536a7b182bddadf75a89a65a7"
    )
)

wrong_hash <- paste0(
  "86bc7c1c043e267f888a324c174d074",
  "a1062e8c81b829416c3c8cd076d3c6d"
)
correct_hash <- paste0(
  "86bc7c1c043e267f888a324c17474d074",
  "a1062e8c81b829416c3c8cd076d3c6d"
)
frozen <- read.csv(
  file.path(amendment_root, "frozen_input_verification.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
failed_frozen <- frozen[!frozen$passed, , drop = FALSE]
stopifnot(
  nrow(frozen) == 12L,
  sum(frozen$passed) == 11L,
  nrow(failed_frozen) == 1L,
  failed_frozen$input == "cell_predictions",
  failed_frozen$expected_sha256 == wrong_hash,
  failed_frozen$observed_sha256 == correct_hash,
  sha256(file.path(stage2_root, "estimand_cell_predictions.csv")) ==
    correct_hash
)

forbidden_outputs <- c(
  "01_derive_ba_m6.R",
  "02_verify_ba_m6.R",
  "ba_m6_family_definition.csv",
  "ba_m6_primary_site_free_work_vs_equal_site.csv",
  "ba_m6_support80_site_free_work_vs_equal_site.csv",
  "ba_m6_component_reconciliation.csv",
  "ba_m6_support_gate.csv",
  "preflight_checks.csv",
  "preflight_execution_record.csv"
)
stopifnot(!any(file.exists(file.path(amendment_root, forbidden_outputs))))

cat(R.version.string, "\n")
cat("BA-015-CORR-001 manifest: 16/16 exact and non-circular\n")
cat("clerical checker stop manifest: 7/7 exact and non-circular\n")
cat("top-level files: exact 5/5 after explicit directory filtering\n")
cat("required stop directory: present and sealed\n")
cat("live preflight: unchanged historical identity\n")
cat("no BA-M6 calculation, model work, QMD change, or render exists\n")
