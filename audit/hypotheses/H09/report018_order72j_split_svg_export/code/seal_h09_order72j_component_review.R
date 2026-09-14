#!/usr/bin/env Rscript

# Seal the H09 Order72j static component-review package.

options(stringsAsFactors = FALSE, warn = 2)

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("Order72j sealing requires R 4.6.1.", call. = FALSE)
}
if (!requireNamespace("digest", quietly = TRUE)) {
  stop("The pinned digest package is unavailable.", call. = FALSE)
}

assert_true <- function(value, message) {
  if (!isTRUE(value)) stop(message, call. = FALSE)
}

sha256_file <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
}

configured_project_root <- Sys.getenv("H09_ORDER72J_PROJECT_ROOT", unset = "")
configured_owner_root <- Sys.getenv("H09_ORDER72J_OWNER_ROOT", unset = "")
assert_true(
  nzchar(configured_project_root) && nzchar(configured_owner_root),
  "Both Order72j root environment variables must be explicit."
)
project_root <- normalizePath(
  configured_project_root,
  winslash = "/",
  mustWork = TRUE
)
owner_root <- normalizePath(
  configured_owner_root,
  winslash = "/",
  mustWork = TRUE
)
expected_owner_root <- file.path(
  project_root,
  "audit/hypotheses/H09/report018_order72j_split_svg_export"
)
assert_true(
  identical(owner_root, expected_owner_root),
  "The sealing root is not the sole Order72j H09 owner root."
)

release_root <- file.path(
  project_root,
  "audit/report_harmonization/report018_order72j_component_exports_release"
)
verify_manifest <- function(path, expected_rows) {
  manifest <- utils::read.csv(
    path,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  assert_true(
    nrow(manifest) == expected_rows && !anyDuplicated(manifest$path),
    paste0("Invalid live pin inventory: ", path)
  )
  resolved <- ifelse(
    startsWith(manifest$path, "/"),
    manifest$path,
    file.path(project_root, manifest$path)
  )
  assert_true(all(file.exists(resolved)), "A live pinned file is missing.")
  hashes <- vapply(resolved, sha256_file, character(1))
  bytes <- unname(file.info(resolved)$size)
  assert_true(
    all(unname(hashes) == manifest$sha256) &&
      all(as.numeric(bytes) == as.numeric(manifest$bytes)),
    "A live execution or preservation pin changed before sealing."
  )
  invisible(TRUE)
}
verify_manifest(file.path(release_root, "release_manifest.csv"), 123L)
verify_manifest(file.path(release_root, "H09_execution_input_pins.csv"), 37L)
verify_manifest(file.path(release_root, "H09_preservation_inventory.csv"), 566L)

candidate_paths <- file.path(
  owner_root,
  "candidate",
  c("H09_primary_effects.svg", "H09_observed_timing_patterns.svg")
)
trial_paths <- file.path(
  owner_root,
  "attempts/trial_01",
  basename(candidate_paths)
)
expected_hashes <- c(
  "a3f9bdb969c075d33adf9a0e6e751a1f967d5111856fcd0db07cbc36575a745a",
  "c937252509c5de9448944358a9846842c973bac26b0f0fb4640728fcf8a908b3"
)
assert_true(
  identical(
    sort(list.files(file.path(owner_root, "candidate"))),
    sort(basename(candidate_paths))
  ) &&
    identical(
      sort(list.files(file.path(owner_root, "attempts/trial_01"))),
      sort(basename(trial_paths))
    ),
  "The candidate or trial directory does not contain exactly two SVGs."
)
candidate_hashes <- vapply(candidate_paths, sha256_file, character(1))
trial_hashes <- vapply(trial_paths, sha256_file, character(1))
assert_true(
  identical(unname(candidate_hashes), expected_hashes) &&
    identical(unname(candidate_hashes), unname(trial_hashes)),
  "A sealed candidate or its retained trial changed."
)
assert_true(
  length(list.files(
    file.path(owner_root, "qa"),
    all.files = TRUE,
    no.. = TRUE
  )) ==
    0L,
  "Visual-QA files exist without a serial lease."
)

required_evidence <- file.path(
  owner_root,
  c(
    "REPORT018-ORDER72J-COMPONENT-REVIEW.md",
    "evidence/attempt_inventory.csv",
    "evidence/candidate_svg_recheck.csv",
    "evidence/copied_function_checks.csv",
    "evidence/execution_commands.md",
    "evidence/package_versions.csv",
    "evidence/plot_layer_map_post.csv",
    "evidence/plot_layer_map_pre.csv",
    "evidence/post_candidate_checks.csv",
    "evidence/post_candidate_rehash.csv",
    "evidence/preflight_attempts.csv",
    "evidence/preflight_checks.csv",
    "evidence/preflight_rehash.csv",
    "evidence/session_info_post.txt",
    "evidence/session_info_pre.txt",
    "evidence/svg_structure_checks.csv",
    "evidence/svg_structure_summary.csv",
    "evidence/visual_qa_status.csv"
  )
)
assert_true(
  all(file.exists(required_evidence)),
  "Required review evidence is missing."
)
for (path in c(
  file.path(owner_root, "evidence/preflight_checks.csv"),
  file.path(owner_root, "evidence/post_candidate_checks.csv"),
  file.path(owner_root, "evidence/svg_structure_checks.csv"),
  file.path(owner_root, "evidence/candidate_svg_recheck.csv")
)) {
  checks <- utils::read.csv(path, stringsAsFactors = FALSE)
  assert_true(all(checks$status == "PASS"), paste0("A check failed in ", path))
}

manifest_path <- file.path(owner_root, "non_circular_manifest.csv")
assert_true(
  !file.exists(manifest_path),
  "The non-circular manifest already exists."
)
relative_paths <- list.files(
  owner_root,
  recursive = TRUE,
  all.files = TRUE,
  no.. = TRUE,
  include.dirs = FALSE
)
relative_paths <- sort(setdiff(relative_paths, "non_circular_manifest.csv"))
absolute_paths <- file.path(owner_root, relative_paths)
assert_true(length(relative_paths) > 0L, "The review package is empty.")
assert_true(
  !anyDuplicated(relative_paths) && all(Sys.readlink(absolute_paths) == ""),
  "The review package contains a duplicate path or symlink."
)
manifest <- data.frame(
  path = relative_paths,
  sha256 = vapply(absolute_paths, sha256_file, character(1)),
  bytes = unname(file.info(absolute_paths)$size),
  stringsAsFactors = FALSE
)
assert_true(
  !"non_circular_manifest.csv" %in% manifest$path,
  "The review manifest is circular."
)
temporary <- tempfile(
  pattern = "non_circular_manifest.",
  tmpdir = owner_root,
  fileext = ".tmp"
)
on.exit(unlink(temporary), add = TRUE)
utils::write.csv(manifest, temporary, row.names = FALSE, na = "")
assert_true(
  file.rename(temporary, manifest_path),
  "Could not seal the manifest."
)

sealed <- utils::read.csv(
  manifest_path,
  stringsAsFactors = FALSE,
  check.names = FALSE
)
assert_true(
  identical(sealed$path, manifest$path) &&
    identical(sealed$sha256, manifest$sha256) &&
    identical(as.numeric(sealed$bytes), as.numeric(manifest$bytes)),
  "The sealed manifest did not round-trip exactly."
)
cat(sprintf(
  "REPORT018_ORDER72J_H09_SEAL=PASS rows=%d manifest_sha256=%s\n",
  nrow(sealed),
  sha256_file(manifest_path)
))
