#!/usr/bin/env Rscript

# Reconstruct the exact six-file pre-order-33 H02 baseline directly from the
# full Git blob identities sealed in the durable recovery inventory. This is
# structural recovery only. It does not execute a QMD or read research data.

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1L) {
  stop(
    "Usage: reconstruct_h02_order33_baseline_from_git_blobs.R <fresh-empty-output-dir>",
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

expected <- data.frame(
  path = c(
    "notebooks/hypotheses/H02.qmd",
    "audit/hypotheses/H02/H02_analysis_preparation.qmd",
    "tests/hypotheses/H02/test_h02_reader_report.R",
    "tests/hypotheses/H02/test_h02_preparation_report.R",
    "tests/hypotheses/H02/test_h02_paired_placement_display.R",
    "audit/handoffs/H02_worker_handoff.md"
  ),
  baseline_sha256 = c(
    "56f6ded2dae5420e36231958d0b1a50f5f938d0d9dd2172301b2340861a0ff20",
    "3d298f2f45165107bc69bbc3b35f1414a5d0cb905d8aa09c839d1e862618e808",
    "c54718734b679139a4d7f0c121c58daf8d5fe5efed49feeef2cc37eac25b185c",
    "8c42a8a42856e5b9fb190a4e44de716f41ee1c8b7ef4eadd66c12c7663fd823d",
    "17e1706ce8720ac48925e47be1b6ab2c246bbd900c7412b838834e8c39f3404a",
    "0cf26a7038e7c49dc8e9790798b5ed3e1d01a5431cf0e1d8845b02892b96bc94"
  ),
  baseline_bytes = c(56571, 54702, 7494, 5475, 3591, 39985),
  baseline_git_blob = c(
    "37e88ca1c057fb9b216867c0bbea26b1ce7cb4c0",
    "bbc96aa28ec51933de00edd406b2f1f37413ca33",
    "b2df8d0b446fd075253c9b3a38024f9f0e0fc8c3",
    "4f2e681da03c98e22e93a3183e502babae9749c9",
    "0ca61dbe48a8546ec1fc113c72e340db031dacc2",
    "f6fbf32a8665d58fd3e87db4e3962b47612373f7"
  ),
  stringsAsFactors = FALSE
)

old_wd <- getwd()
on.exit(setwd(old_wd), add = TRUE)
setwd(root)

for (index in seq_len(nrow(expected))) {
  blob_type <- system2(
    "git",
    c("cat-file", "-t", expected$baseline_git_blob[[index]]),
    stdout = TRUE,
    stderr = TRUE
  )
  if (!is.null(attr(blob_type, "status")) || !identical(blob_type, "blob")) {
    stop(
      "A sealed H02 baseline Git object is unavailable or is not a blob",
      call. = FALSE
    )
  }

  target <- file.path(output_dir, expected$path[[index]])
  dir.create(dirname(target), recursive = TRUE, showWarnings = FALSE)
  status <- system2(
    "git",
    c("cat-file", "blob", expected$baseline_git_blob[[index]]),
    stdout = target,
    stderr = FALSE
  )
  if (!identical(status, 0L) || !file.exists(target)) {
    stop("Failed to reconstruct a sealed H02 baseline blob", call. = FALSE)
  }
}

setwd(old_wd)

target_paths <- file.path(output_dir, expected$path)
actual_sha256 <- vapply(target_paths, sha256, character(1L))
actual_bytes <- as.numeric(file.info(target_paths)$size)
actual_blobs <- vapply(
  target_paths,
  function(path) {
    output <- system2(
      "git",
      c("hash-object", path),
      stdout = TRUE,
      stderr = TRUE
    )
    if (!is.null(attr(output, "status")) || length(output) != 1L) {
      stop(
        "git hash-object failed for a reconstructed baseline file",
        call. = FALSE
      )
    }
    output[[1L]]
  },
  character(1L)
)

stopifnot(
  identical(unname(actual_sha256), expected$baseline_sha256),
  identical(actual_bytes, expected$baseline_bytes),
  identical(unname(actual_blobs), expected$baseline_git_blob)
)

inventory <- expected
inventory$status <- "PASS"
write.csv(
  inventory,
  file.path(output_dir, "H02_order33_reconstructed_baseline_inventory.csv"),
  row.names = FALSE,
  quote = TRUE,
  na = ""
)

message(
  "Reconstructed six exact pre-order-33 H02 baseline files from sealed Git blobs under R ",
  as.character(getRversion()),
  "."
)
