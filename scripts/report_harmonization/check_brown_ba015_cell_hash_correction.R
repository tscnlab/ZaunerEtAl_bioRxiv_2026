#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2L) {
  stop(paste0(
    "Usage: check_brown_ba015_cell_hash_correction.R ",
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

count_fixed <- function(text, pattern) {
  matches <- gregexpr(pattern, text, fixed = TRUE)[[1]]
  if (identical(matches[[1]], -1L)) 0L else length(matches)
}

correction_manifest_path <- file.path(
  central_root,
  paste0(
    "audit/decisions/",
    "brown_adherence_ba015_cell_prediction_hash_clerical_correction_manifest.csv"
  )
)
manifest <- read.csv(
  correction_manifest_path,
  stringsAsFactors = FALSE,
  check.names = FALSE
)
stopifnot(
  nrow(manifest) == 16L,
  identical(
    names(manifest),
    c("root", "path", "bytes", "sha256", "role")
  ),
  all(manifest$root %in% c("central", "brown")),
  !anyDuplicated(paste(manifest$root, manifest$path, sep = "\r")),
  !any(grepl(
    "clerical_correction_manifest[.]csv$",
    manifest$path
  ))
)
member_paths <- ifelse(
  manifest$root == "central",
  file.path(central_root, manifest$path),
  file.path(brown_root, manifest$path)
)
stopifnot(all(file.exists(member_paths)))
actual_bytes <- unname(file.info(member_paths)$size)
actual_hashes <- unname(vapply(member_paths, sha256, character(1)))
stopifnot(
  identical(as.numeric(manifest$bytes), as.numeric(actual_bytes)),
  identical(manifest$sha256, actual_hashes)
)

wrong_hash <- paste0(
  "86bc7c1c043e267f888a324c174d074",
  "a1062e8c81b829416c3c8cd076d3c6d"
)
correct_hash <- paste0(
  "86bc7c1c043e267f888a324c17474d074",
  "a1062e8c81b829416c3c8cd076d3c6d"
)

decision_path <- file.path(
  central_root,
  paste0(
    "audit/decisions/",
    "brown_adherence_site_daytype_vs_equal_site_stage2_stage3_reopening.md"
  )
)
correction_path <- file.path(
  central_root,
  paste0(
    "audit/decisions/",
    "brown_adherence_ba015_cell_prediction_hash_clerical_correction.md"
  )
)
ba015_checker_path <- file.path(
  central_root,
  "scripts/report_harmonization/check_brown_ba015_site_daytype_reopening.R"
)
decision_text <- paste(readLines(decision_path, warn = FALSE), collapse = "\n")
correction_text <- paste(
  readLines(correction_path, warn = FALSE),
  collapse = "\n"
)
ba015_checker_text <- paste(
  readLines(ba015_checker_path, warn = FALSE),
  collapse = "\n"
)
stopifnot(
  count_fixed(decision_text, wrong_hash) == 1L,
  count_fixed(decision_text, correct_hash) == 0L,
  count_fixed(correction_text, wrong_hash) >= 1L,
  count_fixed(correction_text, correct_hash) >= 1L,
  count_fixed(ba015_checker_text, wrong_hash) == 0L,
  count_fixed(ba015_checker_text, correct_hash) == 1L,
  grepl("Correction ID: `BA-015-CORR-001`", correction_text, fixed = TRUE),
  grepl("No scientific contract", correction_text, fixed = TRUE)
)

stage2_root <- file.path(
  brown_root,
  "audit/analyses/brown_adherence/stage2_boundary"
)
cell_path <- file.path(stage2_root, "estimand_cell_predictions.csv")
estimand_manifest_path <- file.path(stage2_root, "estimand_manifest.csv")
boundary_manifest_path <- file.path(
  stage2_root,
  "boundary_stage2_final_manifest.csv"
)
stopifnot(sha256(cell_path) == correct_hash)

estimand_manifest <- read.csv(
  estimand_manifest_path,
  stringsAsFactors = FALSE,
  check.names = FALSE
)
boundary_manifest <- read.csv(
  boundary_manifest_path,
  stringsAsFactors = FALSE,
  check.names = FALSE
)
estimand_row <- estimand_manifest[
  estimand_manifest$artifact == "estimand_cell_predictions.csv",
  ,
  drop = FALSE
]
boundary_row <- boundary_manifest[
  boundary_manifest$project_relative_path ==
    paste0(
      "audit/analyses/brown_adherence/stage2_boundary/",
      "estimand_cell_predictions.csv"
    ),
  ,
  drop = FALSE
]
stopifnot(
  nrow(estimand_row) == 1L,
  nrow(boundary_row) == 1L,
  estimand_row$sha256 == correct_hash,
  boundary_row$sha256 == correct_hash,
  estimand_row$bytes == 74860,
  boundary_row$bytes == 74860
)

decision_register <- read.csv(
  file.path(central_root, "audit/ledgers/decision_register.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
change_log <- read.csv(
  file.path(central_root, "audit/ledgers/change_log.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
stopifnot(
  sum(decision_register$decision_id == "BA-015") == 1L,
  sum(change_log$change_id == "CHG-154") == 1L,
  !anyDuplicated(decision_register$decision_id),
  !anyDuplicated(change_log$change_id)
)

amendment_root <- file.path(
  stage2_root,
  "site_free_work_vs_equal_site_amendment"
)
expected_top_level <- sort(c(
  "00_preflight_ba_m6.R",
  "authority_verification.csv",
  "central_authority_manifest_verification.csv",
  "frozen_input_verification.csv",
  "ledger_verification.csv"
))
observed_top_level <- sort(list.files(
  amendment_root,
  recursive = FALSE,
  all.files = FALSE,
  include.dirs = FALSE
))
stopifnot(identical(observed_top_level, expected_top_level))

authority <- read.csv(
  file.path(amendment_root, "authority_verification.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
central_manifest <- read.csv(
  file.path(amendment_root, "central_authority_manifest_verification.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
ledger <- read.csv(
  file.path(amendment_root, "ledger_verification.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
frozen <- read.csv(
  file.path(amendment_root, "frozen_input_verification.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
failed_frozen <- frozen[!frozen$passed, , drop = FALSE]
stopifnot(
  nrow(authority) == 6L,
  all(authority$passed),
  nrow(central_manifest) == 7L,
  all(central_manifest$passed),
  nrow(ledger) == 30L,
  all(ledger$passed),
  nrow(frozen) == 12L,
  sum(frozen$passed) == 11L,
  nrow(failed_frozen) == 1L,
  failed_frozen$input == "cell_predictions",
  failed_frozen$expected_sha256 == wrong_hash,
  failed_frozen$observed_sha256 == correct_hash
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
cat("correction manifest: 16/16 exact, unique, non-circular\n")
cat(
  "correct cell hash: actual file, estimand manifest, and Stage 2 manifest agree\n"
)
cat("failed preflight: authority 6/6; manifest 7/7; ledgers 30/30\n")
cat("frozen inputs: 11/12 pass; sole mismatch is the mistyped expected token\n")
cat("no BA-M6 calculation or later preflight output exists\n")
