#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE, warn = 2)

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
project_library <- file.path(
  root,
  "renv/library/macos/R-4.6/aarch64-apple-darwin23"
)
stopifnot(dir.exists(project_library))
.libPaths(c(project_library, .libPaths()))

suppressPackageStartupMessages({
  library(digest)
  library(readr)
})

stopifnot(
  identical(as.character(getRversion()), "4.6.1"),
  Sys.getenv("RENV_CONFIG_AUTOLOADER_ENABLED", unset = "") == "FALSE"
)

owner_relative <-
  "audit/hypotheses/H07/report018_order72j_split_svg_export"
owner_root <- normalizePath(
  file.path(root, owner_relative),
  winslash = "/",
  mustWork = TRUE
)
candidate_path <- file.path(
  owner_root,
  "candidate/H07_revised_smooth_derivative_pairs_near_eye.svg"
)
handoff_path <- file.path(
  owner_root,
  "REPORT018-ORDER72J-COMPONENT-REVIEW.md"
)
manifest_path <- file.path(owner_root, "non_circular_manifest.csv")
stopped_dir <- file.path(owner_root, "attempts/finalization_run_01")
stopped_handoff_path <- file.path(stopped_dir, "stopped_handoff.md")
stopped_manifest_path <- file.path(
  stopped_dir,
  "stopped_non_circular_manifest.csv"
)
evidence_dir <- file.path(owner_root, "evidence")
addendum_path <- file.path(evidence_dir, "finalization_recovery_addendum.csv")

sha256_file <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
}

assert_owner_target <- function(path) {
  normalized <- normalizePath(path, winslash = "/", mustWork = FALSE)
  stopifnot(startsWith(normalized, paste0(owner_root, "/")))
  normalized
}

stopifnot(
  dir.exists(stopped_dir),
  file.exists(handoff_path),
  file.exists(manifest_path),
  file.exists(candidate_path),
  !file.exists(stopped_handoff_path),
  !file.exists(stopped_manifest_path),
  !file.exists(addendum_path),
  sha256_file(handoff_path) ==
    "cc47fd81e2264b5c3042c1c3cc8ca18a38a4d01f6e9453a08eeaa5a5a8d7f992",
  sha256_file(manifest_path) ==
    "9362df267a6d756d3c01073aeef3ab51bb98bb1433dd55643216b1db81131374",
  sha256_file(candidate_path) ==
    "f12465fd629c44bbcc7f09a13fccd88b41eda9b80d1cba1310bbdab4ce52ba57"
)

stopped_manifest <- readr::read_csv(manifest_path, show_col_types = FALSE)
stopped_files <- file.path(root, stopped_manifest$path)
stopifnot(
  nrow(stopped_manifest) == 52L,
  !anyDuplicated(stopped_manifest$path),
  all(file.exists(stopped_files)),
  identical(
    unname(stopped_manifest$sha256),
    unname(vapply(stopped_files, sha256_file, character(1)))
  ),
  all(stopped_manifest$bytes == as.numeric(file.info(stopped_files)$size))
)

move_handoff_ok <- file.rename(handoff_path, stopped_handoff_path)
move_manifest_ok <- file.rename(manifest_path, stopped_manifest_path)
stopifnot(
  isTRUE(move_handoff_ok),
  isTRUE(move_manifest_ok),
  !file.exists(handoff_path),
  !file.exists(manifest_path),
  sha256_file(stopped_handoff_path) ==
    "cc47fd81e2264b5c3042c1c3cc8ca18a38a4d01f6e9453a08eeaa5a5a8d7f992",
  sha256_file(stopped_manifest_path) ==
    "9362df267a6d756d3c01073aeef3ab51bb98bb1433dd55643216b1db81131374"
)

addendum <- data.frame(
  sequence = c(10L, 11L),
  stage = c("finalization_run_01", "finalization_recovery_run_01"),
  status = c(
    "STOPPED_CHECKER_NAME_ATTRIBUTE_STRICTNESS",
    "PASS_CORRECTED_UNNAMED_VALUE_COMPARISON"
  ),
  source_or_candidate_changed = FALSE,
  svg_device_invoked = FALSE,
  browser_qa_run = FALSE,
  listener_started = FALSE,
  scientific_computation = FALSE,
  detail = c(
    paste(
      "All substantive post-protection outputs were written; the terminal",
      "manifest check compared equal hashes with different name attributes"
    ),
    paste(
      "Stopped handoff and manifest preserved byte-for-byte; corrected",
      "verification compares un-named values and writes one final seal"
    )
  ),
  stringsAsFactors = FALSE
)
assert_owner_target(addendum_path)
utils::write.csv(
  addendum,
  addendum_path,
  row.names = FALSE,
  na = "",
  fileEncoding = "UTF-8"
)

handoff_lines <- readLines(
  stopped_handoff_path,
  warn = FALSE,
  encoding = "UTF-8"
)
stopifnot(
  sum(handoff_lines ==
    "Six construction/checker stops are preserved. Four occurred before any SVG device invocation, and two occurred only in the post-export static checker. None changed plot data, semantics or the SVG. The sole SVG export succeeded. Detailed causes and remedies are in `attempts/` and `evidence/attempt_inventory.csv`.") == 1L,
  sum(handoff_lines ==
    "The non-circular manifest covers every file in this new H07 owner root except itself. No promotion or downstream integration is authorized by this return.") == 1L
)
handoff_lines[handoff_lines ==
  "Six construction/checker stops are preserved. Four occurred before any SVG device invocation, and two occurred only in the post-export static checker. None changed plot data, semantics or the SVG. The sole SVG export succeeded. Detailed causes and remedies are in `attempts/` and `evidence/attempt_inventory.csv`."] <-
  paste(
    "Seven construction/checker stops are preserved. Four occurred before",
    "any SVG device invocation, two occurred only in the post-export static",
    "checker, and one occurred after all substantive finalization outputs",
    "because equal manifest hashes carried different R name attributes.",
    "None changed plot data, semantics or the SVG. The sole SVG export",
    "succeeded. Detailed causes and remedies are in `attempts/`,",
    "`evidence/attempt_inventory.csv`, and",
    "`evidence/finalization_recovery_addendum.csv`."
  )
handoff_lines[handoff_lines ==
  "The non-circular manifest covers every file in this new H07 owner root except itself. No promotion or downstream integration is authorized by this return."] <-
  paste(
    "The final non-circular manifest covers every file in this new H07 owner",
    "root except itself, including the byte-preserved stopped handoff and",
    "stopped manifest. The corrected final check compares un-named hash",
    "values. No promotion or downstream integration is authorized by this",
    "return."
  )
assert_owner_target(handoff_path)
writeLines(handoff_lines, handoff_path, useBytes = TRUE)

all_owner_files <- list.files(
  owner_root,
  recursive = TRUE,
  full.names = TRUE,
  all.files = TRUE,
  no.. = TRUE
)
all_owner_files <- all_owner_files[
  file.info(all_owner_files)$isdir %in% FALSE
]
all_owner_files <- sort(setdiff(
  normalizePath(all_owner_files, winslash = "/", mustWork = TRUE),
  normalizePath(manifest_path, winslash = "/", mustWork = FALSE)
))
manifest <- data.frame(
  path = substring(all_owner_files, nchar(root) + 2L),
  sha256 = unname(vapply(all_owner_files, sha256_file, character(1))),
  bytes = as.numeric(file.info(all_owner_files)$size),
  stringsAsFactors = FALSE
)
stopifnot(
  nrow(manifest) > 52L,
  !anyDuplicated(manifest$path),
  !any(manifest$path == substring(manifest_path, nchar(root) + 2L))
)
assert_owner_target(manifest_path)
utils::write.csv(
  manifest,
  manifest_path,
  row.names = FALSE,
  na = "",
  fileEncoding = "UTF-8"
)

manifest_live <- readr::read_csv(manifest_path, show_col_types = FALSE)
current_files <- list.files(
  owner_root,
  recursive = TRUE,
  full.names = TRUE,
  all.files = TRUE,
  no.. = TRUE
)
current_files <- current_files[file.info(current_files)$isdir %in% FALSE]
current_files <- sort(setdiff(
  normalizePath(current_files, winslash = "/", mustWork = TRUE),
  normalizePath(manifest_path, winslash = "/", mustWork = TRUE)
))
stopifnot(
  identical(
    unname(manifest_live$path),
    unname(substring(current_files, nchar(root) + 2L))
  ),
  identical(
    unname(manifest_live$sha256),
    unname(vapply(current_files, sha256_file, character(1)))
  ),
  all(manifest_live$bytes == as.numeric(file.info(current_files)$size)),
  !anyDuplicated(manifest_live$path),
  sha256_file(candidate_path) ==
    "f12465fd629c44bbcc7f09a13fccd88b41eda9b80d1cba1310bbdab4ce52ba57"
)

cat(sprintf(
  paste0(
    "ORDER72J_H07_FINAL_SEAL=CANDIDATE_PASS_AWAITING_INDEPENDENT_ACCEPTANCE ",
    "candidate=%s handoff=%s manifest=%s rows=%d visual_qa=NOT_RUN lease=NOT_ISSUED\n"
  ),
  sha256_file(candidate_path),
  sha256_file(handoff_path),
  sha256_file(manifest_path),
  nrow(manifest_live)
))
