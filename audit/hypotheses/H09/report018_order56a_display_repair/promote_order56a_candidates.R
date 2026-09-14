#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE, warn = 2)

assert_true <- function(value, message) {
  if (!isTRUE(value)) stop(message, call. = FALSE)
}

assert_all <- function(value, message) {
  if (!length(value) || !all(value)) stop(message, call. = FALSE)
}

assert_true(
  identical(as.character(getRversion()), "4.6.1"),
  sprintf("Order 56a promotion requires R 4.6.1, found %s.", getRversion())
)
assert_true(
  requireNamespace("digest", quietly = TRUE),
  "The synchronized digest package is required."
)
assert_true(
  requireNamespace("readr", quietly = TRUE),
  "The synchronized readr package is required."
)

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
setwd(root)

candidate_root <- Sys.getenv("H09_ORDER56A_WORK_DIR", unset = "")
assert_true(
  nzchar(candidate_root) && startsWith(candidate_root, "/private/tmp/"),
  "H09_ORDER56A_WORK_DIR must be an absolute directory under /private/tmp."
)
candidate_root <- normalizePath(candidate_root, winslash = "/", mustWork = TRUE)
candidate_dir <- file.path(candidate_root, "repaired")
assert_true(
  dir.exists(candidate_dir),
  "The accepted candidate directory is missing."
)

evidence_dir <- file.path(
  root,
  "audit/hypotheses/H09/report018_order56a_display_repair"
)
receipt_path <- file.path(evidence_dir, "durable_promotion_receipt.csv")
assert_true(
  !file.exists(receipt_path),
  "The one-time Order 56a promotion receipt already exists."
)

figure_files <- c(
  "H09_primary_effects.png",
  "H09_paired_placement_effects.png",
  "H09_diagnostics_near_eye.png",
  "H09_diagnostics_chest.png",
  "H09_primary_effects.pdf",
  "H09_paired_placement_effects.pdf",
  "H09_diagnostics_near_eye.pdf",
  "H09_diagnostics_chest.pdf"
)
expected_preimage <- c(
  H09_primary_effects.png = "f288cfaff6e555715af30c778974e50d9bcc8c9a90c643b5e994ad2d8b95be1f",
  H09_paired_placement_effects.png = "4cffc5339801d25e817639064b6f40e0b0a6bbe69a735e5f245d97cee898e185",
  H09_diagnostics_near_eye.png = "df6a267517ea08635a00fcfa153a1e3a7f6dbbbe764745860c16bd3b53165e96",
  H09_diagnostics_chest.png = "e82b32d5d69a73e45a7d93e8b1bb8357dc3104e67c5f128eba4f3f5538961a75",
  H09_primary_effects.pdf = "b354077d2c1225104ecef7af1d879acd2037a7b740940392092b2d09f2f833e0",
  H09_paired_placement_effects.pdf = "5d8f8e95c4642ca29391941f63852776ee6d4ee3cb0cbdedfe74d24ec645ff7c",
  H09_diagnostics_near_eye.pdf = "a01d7184d3fc68bf33375f950c9ba422ac7f86f803cd214064ddf86d003ca5ac",
  H09_diagnostics_chest.pdf = "614b46f3cb2026ea1f6c7350959482ce4473c114b0c90ec066a176f73c635596"
)

sha256_file <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
}

candidate_inventory <- readr::read_csv(
  file.path(evidence_dir, "candidate_inventory.csv"),
  show_col_types = FALSE
)
assert_true(
  identical(candidate_inventory$figure_file, figure_files),
  "The accepted candidate inventory does not have the exact eight-file order."
)

candidate_paths <- file.path(candidate_dir, figure_files)
durable_paths <- file.path(root, "artifacts/10_figures/H09", figure_files)
assert_all(
  file.exists(candidate_paths),
  "An accepted candidate file is missing."
)
assert_all(file.exists(durable_paths), "A durable preimage file is missing.")

candidate_hashes <- vapply(candidate_paths, sha256_file, character(1))
durable_preimage_hashes <- vapply(durable_paths, sha256_file, character(1))
assert_true(
  identical(unname(candidate_hashes), candidate_inventory$sha256),
  "A candidate file differs from the accepted candidate inventory."
)
assert_true(
  identical(
    unname(durable_preimage_hashes),
    unname(expected_preimage[figure_files])
  ),
  "A durable figure no longer has its accepted preimage identity."
)

stage_dir <- file.path(
  root,
  "artifacts/10_figures/H09/.order56a_promotion_stage"
)
assert_true(
  !file.exists(stage_dir),
  "The one-time promotion stage already exists."
)
assert_true(
  dir.create(stage_dir),
  "Could not create the one-time promotion stage."
)

stage_paths <- file.path(stage_dir, figure_files)
copied <- file.copy(candidate_paths, stage_paths, overwrite = FALSE)
assert_all(copied, "Could not stage the complete candidate set.")
stage_hashes <- vapply(stage_paths, sha256_file, character(1))
assert_true(
  identical(unname(stage_hashes), unname(candidate_hashes)),
  "The staged files are not candidate-identical."
)

ledger <- data.frame(
  figure_file = figure_files,
  durable_path = sub(paste0("^", root, "/"), "", durable_paths),
  candidate_path = candidate_paths,
  preimage_sha256 = durable_preimage_hashes,
  postimage_sha256 = candidate_hashes,
  preimage_bytes = as.numeric(file.info(durable_paths)$size),
  postimage_bytes = as.numeric(file.info(candidate_paths)$size),
  stringsAsFactors = FALSE
)
readr::write_csv(
  ledger,
  file.path(evidence_dir, "preimage_to_postimage_ledger.csv"),
  na = ""
)

promoted <- file.rename(stage_paths, durable_paths)
assert_all(promoted, "The complete candidate set was not promoted.")
assert_true(
  identical(
    unname(vapply(durable_paths, sha256_file, character(1))),
    unname(candidate_hashes)
  ),
  "A promoted durable output is not candidate-identical."
)
assert_true(
  length(list.files(stage_dir, all.files = TRUE, no.. = TRUE)) == 0L,
  "The one-time promotion stage is not empty."
)
assert_true(unlink(stage_dir, recursive = TRUE) == 0L, "Stage cleanup failed.")

receipt <- data.frame(
  order = "REPORT-018 H09 owner order 56a",
  promotion_count = 1L,
  files_promoted = length(figure_files),
  all_postimages_candidate_identical = TRUE,
  status = "PASS",
  stringsAsFactors = FALSE
)
readr::write_csv(receipt, receipt_path, na = "")

cat(sprintf(
  "H09_ORDER56A_PROMOTION=PASS promotion_count=1 outputs=%d\n",
  length(figure_files)
))
