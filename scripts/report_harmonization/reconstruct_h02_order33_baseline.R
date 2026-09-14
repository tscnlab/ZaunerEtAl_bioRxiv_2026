#!/usr/bin/env Rscript

# Reconstruct the exact temporary pre-order-33 H02 source baseline from the
# sealed full source diff. This is structural recovery only. It never executes
# a QMD or reads a scientific data artifact.

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1L) {
  stop(
    "Usage: reconstruct_h02_order33_baseline.R <fresh-empty-output-dir>",
    call. = FALSE
  )
}

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("H02 baseline recovery requires R 4.6.1", call. = FALSE)
}

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
output_dir <- normalizePath(args[[1L]], winslash = "/", mustWork = TRUE)
if (length(list.files(output_dir, all.files = TRUE, no.. = TRUE)) != 0L) {
  stop("Output directory must be fresh and empty", call. = FALSE)
}

sha256 <- function(path) {
  unname(as.character(openssl::sha256(file(path))))
}

inputs <- data.frame(
  target = c(
    "notebooks/hypotheses/H02.qmd",
    "audit/hypotheses/H02/H02_analysis_preparation.qmd",
    "tests/hypotheses/H02/test_h02_reader_report.R",
    "tests/hypotheses/H02/test_h02_preparation_report.R",
    "tests/hypotheses/H02/test_h02_paired_placement_display.R",
    "audit/handoffs/H02_worker_handoff.md"
  ),
  source = c(
    "notebooks/hypotheses/H02.qmd",
    "audit/hypotheses/H02/H02_analysis_preparation.qmd",
    paste0(
      "audit/report_harmonization/",
      "report017_h02_order33_baseline_recovery/",
      "test_h02_reader_report_order33a.R"
    ),
    paste0(
      "audit/report_harmonization/",
      "report017_h02_order33_baseline_recovery/",
      "test_h02_preparation_report_order33a.R"
    ),
    "tests/hypotheses/H02/test_h02_paired_placement_display.R",
    "audit/handoffs/H02_worker_handoff.md"
  ),
  source_sha256 = c(
    "4f431eaba1fd449837186497dc988f95c30a9ece7ae83d57b2f0c377690f0f6d",
    "92424e41a7f54d05b816ff79144850a27aabc8181aa705384b22f4c7cdc3b9a1",
    "b7eed310a4939ab566faa7c1b8b818bc2f7ab105f59076d6c186bf783704d137",
    "b19c5a0beb18d9faf7506ab9dde9d73964a5d5b9fb9a13259865b5a358132a6d",
    "873c43f0d863c78c22e3e0635d054f09bc521a24d618afcda134a831ac7e7d8a",
    "fbb74b2ed98756e1e8eb7f4b0be14cc8ec4a1873d766c1828390ebd9f5793441"
  ),
  expected_current_blob_prefix = c(
    "c01458b", "cfaff78", "599d040", "fb669ea", "74b26f0", "c8f38e3"
  ),
  expected_baseline_blob_prefix = c(
    "37e88ca", "bbc96aa", "b2df8d0", "4f2e681", "0ca61db", "f6fbf32"
  ),
  stringsAsFactors = FALSE
)

source_paths <- file.path(root, inputs$source)
stopifnot(
  all(file.exists(source_paths)),
  identical(
    unname(vapply(source_paths, sha256, character(1L))),
    inputs$source_sha256
  )
)

current_blobs <- vapply(
  source_paths,
  function(path) {
    output <- system2("git", c("hash-object", path), stdout = TRUE)
    if (!identical(attr(output, "status"), NULL)) {
      stop("git hash-object failed for a recovery input", call. = FALSE)
    }
    output[[1L]]
  },
  character(1L)
)
stopifnot(startsWith(current_blobs, inputs$expected_current_blob_prefix))

target_paths <- file.path(output_dir, inputs$target)
for (index in seq_along(target_paths)) {
  dir.create(dirname(target_paths[[index]]), recursive = TRUE, showWarnings = FALSE)
  copied <- file.copy(
    source_paths[[index]],
    target_paths[[index]],
    overwrite = FALSE,
    copy.mode = TRUE,
    copy.date = TRUE
  )
  if (!isTRUE(copied)) stop("Failed to stage a recovery input", call. = FALSE)
}

sealed_patch <- file.path(
  root,
  "audit/hypotheses/H02/report017_order33_source_rewrite/",
  "H02_order33_source_diff.patch"
)
stopifnot(
  file.exists(sealed_patch),
  sha256(sealed_patch) ==
    "7e05106b5da43332b13467bddabebae0f2b427db59a6c1a96b63cd85840a6543"
)

patch_lines <- readLines(sealed_patch, warn = FALSE, encoding = "UTF-8")
patch_lines <- gsub(
  "a/private/tmp/h02_order33_baseline.Ku3U7S/",
  "a/",
  patch_lines,
  fixed = TRUE
)
patch_lines <- gsub(
  paste0(
    "b/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/",
    "WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026/"
  ),
  "b/",
  patch_lines,
  fixed = TRUE
)
relative_patch <- file.path(output_dir, "H02_order33_relative_source_diff.patch")
writeLines(patch_lines, relative_patch, useBytes = TRUE)

old_wd <- getwd()
on.exit(setwd(old_wd), add = TRUE)
setwd(output_dir)
check_output <- system2(
  "git",
  c("apply", "--reverse", "--check", relative_patch),
  stdout = TRUE,
  stderr = TRUE
)
check_status <- attr(check_output, "status")
if (!is.null(check_status) && check_status != 0L) {
  stop(
    paste("Reverse patch check failed:", paste(check_output, collapse = "\n")),
    call. = FALSE
  )
}
apply_output <- system2(
  "git",
  c("apply", "--reverse", relative_patch),
  stdout = TRUE,
  stderr = TRUE
)
apply_status <- attr(apply_output, "status")
if (!is.null(apply_status) && apply_status != 0L) {
  stop(
    paste("Reverse patch application failed:", paste(apply_output, collapse = "\n")),
    call. = FALSE
  )
}
setwd(old_wd)

baseline_blobs <- vapply(
  target_paths,
  function(path) system2("git", c("hash-object", path), stdout = TRUE)[[1L]],
  character(1L)
)
stopifnot(startsWith(baseline_blobs, inputs$expected_baseline_blob_prefix))

inventory <- data.frame(
  path = inputs$target,
  baseline_sha256 = vapply(target_paths, sha256, character(1L)),
  baseline_bytes = as.numeric(file.info(target_paths)$size),
  baseline_git_blob = baseline_blobs,
  expected_blob_prefix = inputs$expected_baseline_blob_prefix,
  status = "PASS",
  stringsAsFactors = FALSE
)
write.csv(
  inventory,
  file.path(output_dir, "H02_order33_reconstructed_baseline_inventory.csv"),
  row.names = FALSE,
  quote = TRUE,
  na = ""
)

message(
  "Reconstructed six exact pre-order-33 H02 baseline files under R ",
  as.character(getRversion()),
  ". All sealed git-blob prefixes match."
)
