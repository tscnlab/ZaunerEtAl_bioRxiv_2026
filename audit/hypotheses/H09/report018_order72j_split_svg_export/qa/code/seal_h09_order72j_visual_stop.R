#!/usr/bin/env Rscript

# Seal the fail-closed H09 Order72j visual-lease package.

options(stringsAsFactors = FALSE, warn = 2)

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("Order72j visual-stop sealing requires R 4.6.1.", call. = FALSE)
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

write_csv_once <- function(data, path) {
  assert_true(!file.exists(path), paste0("Evidence already exists: ", path))
  temporary <- tempfile(
    pattern = paste0(basename(path), "."),
    tmpdir = dirname(path),
    fileext = ".tmp"
  )
  on.exit(unlink(temporary), add = TRUE)
  utils::write.csv(data, temporary, row.names = FALSE, na = "")
  assert_true(file.rename(temporary, path), "Could not seal CSV evidence.")
  invisible(path)
}

write_lines_once <- function(lines, path) {
  assert_true(!file.exists(path), paste0("Evidence already exists: ", path))
  temporary <- tempfile(
    pattern = paste0(basename(path), "."),
    tmpdir = dirname(path),
    fileext = ".tmp"
  )
  on.exit(unlink(temporary), add = TRUE)
  writeLines(lines, temporary, useBytes = TRUE)
  assert_true(file.rename(temporary, path), "Could not seal text evidence.")
  invisible(path)
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
  "The visual-stop sealing root is not the sole H09 owner root."
)
qa_root <- file.path(owner_root, "qa")
serve_root <- file.path(qa_root, "serve")
release_root <- file.path(
  project_root,
  "audit/report_harmonization/report018_order72j_component_exports_release"
)

rehash_manifest <- function(path, manifest_id, expected_rows) {
  manifest <- utils::read.csv(
    path,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  assert_true(
    nrow(manifest) == expected_rows &&
      !anyDuplicated(manifest$path) &&
      !path %in% manifest$path,
    paste0("Invalid or circular ", manifest_id, " manifest.")
  )
  resolved <- ifelse(
    startsWith(manifest$path, "/"),
    manifest$path,
    file.path(project_root, manifest$path)
  )
  exists <- file.exists(resolved)
  actual_sha256 <- rep(NA_character_, nrow(manifest))
  actual_bytes <- rep(NA_real_, nrow(manifest))
  actual_sha256[exists] <- vapply(
    resolved[exists],
    sha256_file,
    character(1)
  )
  actual_bytes[exists] <- unname(file.info(resolved[exists])$size)
  status <- ifelse(
    exists &
      actual_sha256 == manifest$sha256 &
      actual_bytes == as.numeric(manifest$bytes),
    "PASS",
    "FAIL"
  )
  output <- data.frame(
    manifest = manifest_id,
    path = manifest$path,
    expected_sha256 = manifest$sha256,
    actual_sha256 = actual_sha256,
    expected_bytes = as.numeric(manifest$bytes),
    actual_bytes = actual_bytes,
    status = status,
    stringsAsFactors = FALSE
  )
  assert_true(all(output$status == "PASS"), paste0(manifest_id, " changed."))
  output
}

final_pin_rehash <- rbind(
  rehash_manifest(
    file.path(release_root, "release_manifest.csv"),
    "release_manifest",
    123L
  ),
  rehash_manifest(
    file.path(release_root, "H09_execution_input_pins.csv"),
    "H09_execution_inputs",
    37L
  ),
  rehash_manifest(
    file.path(release_root, "H09_preservation_inventory.csv"),
    "H09_preservation",
    566L
  )
)
assert_true(
  nrow(final_pin_rehash) == 726L && all(final_pin_rehash$status == "PASS"),
  "The complete final pin gate did not pass."
)

anchor_paths <- file.path(
  owner_root,
  c(
    "candidate/H09_primary_effects.svg",
    "candidate/H09_observed_timing_patterns.svg",
    "attempts/trial_01/H09_primary_effects.svg",
    "attempts/trial_01/H09_observed_timing_patterns.svg",
    "non_circular_manifest.csv",
    "REPORT018-ORDER72J-COMPONENT-REVIEW.md"
  )
)
anchor_expected <- c(
  "a3f9bdb969c075d33adf9a0e6e751a1f967d5111856fcd0db07cbc36575a745a",
  "c937252509c5de9448944358a9846842c973bac26b0f0fb4640728fcf8a908b3",
  "a3f9bdb969c075d33adf9a0e6e751a1f967d5111856fcd0db07cbc36575a745a",
  "c937252509c5de9448944358a9846842c973bac26b0f0fb4640728fcf8a908b3",
  "a501adbbd6f7b013e3acac347460dc3c86543caab6f6a8525e7f2126ce40d76c",
  "985931f8db78c20bb2a480fc578ffcc296dc41a7f0083f7e8ed65213bd4dc725"
)
anchor_actual <- vapply(anchor_paths, sha256_file, character(1))
protected_anchor_rehash <- data.frame(
  path = sub(paste0("^", project_root, "/"), "", anchor_paths),
  expected_sha256 = anchor_expected,
  actual_sha256 = unname(anchor_actual),
  bytes = unname(file.info(anchor_paths)$size),
  status = ifelse(unname(anchor_actual) == anchor_expected, "PASS", "FAIL"),
  stringsAsFactors = FALSE
)
assert_true(
  all(protected_anchor_rehash$status == "PASS"),
  "A candidate, trial, or static seal anchor changed."
)

expected_serve_files <- sort(c(
  "assets/H09_observed_timing_patterns.pdf",
  "assets/H09_observed_timing_patterns.png",
  "assets/H09_observed_timing_patterns.svg",
  "assets/H09_primary_effects.pdf",
  "assets/H09_primary_effects.png",
  "assets/H09_primary_effects.svg",
  "compare.html",
  "index.html"
))
serve_files <- sort(list.files(
  serve_root,
  recursive = TRUE,
  all.files = TRUE,
  no.. = TRUE,
  include.dirs = FALSE
))
assert_true(
  identical(serve_files, expected_serve_files),
  "The bounded serve-root inventory changed."
)
serve_paths <- file.path(serve_root, serve_files)
assert_true(
  !anyDuplicated(serve_files) && all(Sys.readlink(serve_paths) == ""),
  "The bounded serve root contains a duplicate path or symlink."
)
serve_inventory <- data.frame(
  path = file.path("qa/serve", serve_files),
  sha256 = vapply(serve_paths, sha256_file, character(1)),
  bytes = unname(file.info(serve_paths)$size),
  symlink = FALSE,
  stringsAsFactors = FALSE
)
expected_asset_hashes <- c(
  "assets/H09_observed_timing_patterns.pdf" = "6912f7b1730219f5ece1d78c69fa96db0497156066fce9c9329039240d6293f3",
  "assets/H09_observed_timing_patterns.png" = "a23cb2a9a90a232ae9bf3f94ec7b1c5ac0e3c83933d056c0920ffd59e8e0eb59",
  "assets/H09_observed_timing_patterns.svg" = "c937252509c5de9448944358a9846842c973bac26b0f0fb4640728fcf8a908b3",
  "assets/H09_primary_effects.pdf" = "69275a6a3fbfa7bd0b47efa4f53cb61ccbe3c7a776f146148f58026f4329357f",
  "assets/H09_primary_effects.png" = "8525b9dda4a635efe2d8410e6eeb6a99722c6bc0d225f09abe684a73595dc4dd",
  "assets/H09_primary_effects.svg" = "a3f9bdb969c075d33adf9a0e6e751a1f967d5111856fcd0db07cbc36575a745a"
)
asset_rows <- match(names(expected_asset_hashes), serve_files)
assert_true(
  !anyNA(asset_rows) &&
    identical(
      unname(serve_inventory$sha256[asset_rows]),
      unname(expected_asset_hashes)
    ),
  "A bounded serve-root asset copy differs from its pinned source."
)
html_text <- paste(
  unlist(lapply(serve_paths[grepl("[.]html$", serve_paths)], readLines)),
  collapse = "\n"
)
assert_true(
  !grepl("https?://", html_text, perl = TRUE) &&
    !grepl("<script[^>]+src=", html_text, perl = TRUE) &&
    !grepl("<link[^>]+href=", html_text, perl = TRUE),
  "The static comparison route contains an external resource reference."
)

required_manual_evidence <- file.path(
  qa_root,
  c(
    "REPORT018-ORDER72J-VISUAL-LEASE-002-STOP.md",
    "loopback_attempt.csv",
    "browser_qa_status.csv",
    "teardown_status.csv",
    "preflight_attempts.csv",
    "code/seal_h09_order72j_visual_stop.R"
  )
)
assert_true(
  all(file.exists(required_manual_evidence)),
  "Required visual-stop evidence is missing."
)

loopback <- utils::read.csv(
  file.path(qa_root, "loopback_attempt.csv"),
  stringsAsFactors = FALSE
)
browser <- utils::read.csv(
  file.path(qa_root, "browser_qa_status.csv"),
  stringsAsFactors = FALSE
)
teardown <- utils::read.csv(
  file.path(qa_root, "teardown_status.csv"),
  stringsAsFactors = FALSE
)
assert_true(
  nrow(loopback) == 1L &&
    loopback$command_exit[[1L]] == 1L &&
    !loopback$listener_created[[1L]] &&
    !loopback$content_loaded[[1L]] &&
    !loopback$browser_tab_created[[1L]] &&
    identical(loopback$status[[1L]], "STOP_POLICY_BIND_REJECTED"),
  "The loopback stop record is invalid."
)
assert_true(
  nrow(browser) == 1L &&
    !browser$visual_acceptance[[1L]] &&
    identical(browser$status[[1L]], "STOPPED_BEFORE_CONTENT_LOAD"),
  "The browser stop record is invalid."
)
assert_true(
  nrow(teardown) == 1L &&
    teardown$lsof_listener_rows_after_stop[[1L]] == 0L &&
    teardown$task_browser_tabs_remaining[[1L]] == 0L &&
    !teardown$listener_remaining[[1L]] &&
    identical(teardown$status[[1L]], "PASS"),
  "The teardown record is invalid."
)

final_pin_path <- file.path(qa_root, "final_pin_rehash.csv")
serve_inventory_path <- file.path(qa_root, "serve_inventory.csv")
anchor_path <- file.path(qa_root, "protected_anchor_rehash.csv")
session_path <- file.path(qa_root, "session_info.txt")
summary_path <- file.path(qa_root, "final_check_summary.csv")
qa_manifest_path <- file.path(qa_root, "qa_non_circular_manifest.csv")
assert_true(
  !any(file.exists(c(
    final_pin_path,
    serve_inventory_path,
    anchor_path,
    session_path,
    summary_path,
    qa_manifest_path
  ))),
  "A final visual-stop seal output already exists."
)

summary <- data.frame(
  check = c(
    "R_version",
    "release_manifest_exact",
    "H09_execution_inputs_exact",
    "H09_preservation_exact",
    "candidate_trial_static_anchors_exact",
    "bounded_serve_inventory",
    "serve_symlinks",
    "serve_external_resources",
    "loopback_content_loaded",
    "browser_tabs_created",
    "listeners_remaining",
    "visual_acceptance",
    "lease_disposition"
  ),
  expected = c(
    "4.6.1",
    "123/123",
    "37/37",
    "566/566",
    "6/6",
    "8",
    "0",
    "0",
    "FALSE",
    "0",
    "0",
    "FALSE",
    "RELEASED_WITHOUT_VISUAL_ACCEPTANCE"
  ),
  actual = c(
    as.character(getRversion()),
    paste0(sum(final_pin_rehash$manifest == "release_manifest"), "/123"),
    paste0(sum(final_pin_rehash$manifest == "H09_execution_inputs"), "/37"),
    paste0(sum(final_pin_rehash$manifest == "H09_preservation"), "/566"),
    paste0(sum(protected_anchor_rehash$status == "PASS"), "/6"),
    as.character(nrow(serve_inventory)),
    as.character(sum(serve_inventory$symlink)),
    "0",
    as.character(loopback$content_loaded[[1L]]),
    as.character(as.integer(loopback$browser_tab_created[[1L]])),
    as.character(teardown$lsof_listener_rows_after_stop[[1L]]),
    as.character(browser$visual_acceptance[[1L]]),
    "RELEASED_WITHOUT_VISUAL_ACCEPTANCE"
  ),
  status = "PASS",
  stringsAsFactors = FALSE
)
summary$status <- ifelse(summary$expected == summary$actual, "PASS", "FAIL")
assert_true(all(summary$status == "PASS"), "A final visual-stop check failed.")

write_csv_once(final_pin_rehash, final_pin_path)
write_csv_once(serve_inventory, serve_inventory_path)
write_csv_once(protected_anchor_rehash, anchor_path)
write_csv_once(summary, summary_path)
write_lines_once(
  c(
    paste0("R_VERSION=", getRversion()),
    paste0("LIB_PATHS=", paste(.libPaths(), collapse = "|")),
    capture.output(utils::sessionInfo())
  ),
  session_path
)

qa_files <- sort(list.files(
  qa_root,
  recursive = TRUE,
  all.files = TRUE,
  no.. = TRUE,
  include.dirs = FALSE
))
qa_files <- setdiff(qa_files, "qa_non_circular_manifest.csv")
qa_paths <- file.path(qa_root, qa_files)
assert_true(
  length(qa_files) > 0L &&
    !anyDuplicated(qa_files) &&
    all(Sys.readlink(qa_paths) == ""),
  "The visual-stop package contains a duplicate path or symlink."
)
qa_manifest <- data.frame(
  path = file.path("qa", qa_files),
  sha256 = vapply(qa_paths, sha256_file, character(1)),
  bytes = unname(file.info(qa_paths)$size),
  stringsAsFactors = FALSE
)
assert_true(
  !"qa/qa_non_circular_manifest.csv" %in% qa_manifest$path,
  "The visual-stop manifest is circular."
)
write_csv_once(qa_manifest, qa_manifest_path)

sealed <- utils::read.csv(
  qa_manifest_path,
  stringsAsFactors = FALSE,
  check.names = FALSE
)
assert_true(
  identical(sealed$path, qa_manifest$path) &&
    identical(sealed$sha256, qa_manifest$sha256) &&
    identical(as.numeric(sealed$bytes), as.numeric(qa_manifest$bytes)),
  "The visual-stop manifest did not round-trip exactly."
)
cat(sprintf(
  paste0(
    "REPORT018_ORDER72J_H09_VISUAL_STOP=PASS pins=123+37+566 ",
    "anchors=6 serve=8 listener=0 tabs=0 rows=%d manifest_sha256=%s\n"
  ),
  nrow(sealed),
  sha256_file(qa_manifest_path)
))
