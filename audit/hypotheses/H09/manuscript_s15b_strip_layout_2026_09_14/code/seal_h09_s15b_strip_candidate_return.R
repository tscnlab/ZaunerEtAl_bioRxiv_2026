#!/usr/bin/env Rscript

# Verify and seal the H09 S15B order 010a candidate return.

options(stringsAsFactors = FALSE, warn = 2)

required_packages <- c(
  digest = "0.6.39",
  xml2 = "1.6.0"
)
missing_packages <- names(required_packages)[
  !vapply(
    names(required_packages),
    requireNamespace,
    logical(1),
    quietly = TRUE
  )
]
if (length(missing_packages)) {
  stop(
    "Missing pinned package(s): ",
    paste(missing_packages, collapse = ", "),
    call. = FALSE
  )
}
observed_versions <- vapply(
  names(required_packages),
  function(package) as.character(utils::packageVersion(package)),
  character(1)
)
if (!identical(unname(observed_versions), unname(required_packages))) {
  stop("A verification package does not match its order pin.", call. = FALSE)
}
if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("H09 S15B return sealing requires R 4.6.1.", call. = FALSE)
}

assert_true <- function(value, message) {
  if (!isTRUE(value)) stop(message, call. = FALSE)
}

assert_all <- function(value, message) {
  if (!length(value) || !all(value)) stop(message, call. = FALSE)
}

sha256_file <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
}

sha256_raw <- function(value) {
  digest::digest(value, algo = "sha256", serialize = FALSE)
}

read_raw_file <- function(path) {
  readBin(path, what = "raw", n = file.info(path)$size)
}

count_fixed <- function(text, pattern) {
  matches <- gregexpr(pattern, text, fixed = TRUE, useBytes = TRUE)[[1L]]
  if (matches[[1L]] == -1L) 0L else length(matches)
}

replace_fixed <- function(text, old, new) {
  gsub(old, new, text, fixed = TRUE, useBytes = TRUE)
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

configured_project_root <- Sys.getenv(
  "H09_S15B_ORDER010A_PROJECT_ROOT",
  unset = ""
)
configured_owner_root <- Sys.getenv("H09_S15B_ORDER010A_OWNER_ROOT", unset = "")
assert_true(
  nzchar(configured_project_root) && nzchar(configured_owner_root),
  "Both H09 S15B order root variables must be explicit."
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
assert_true(
  identical(
    owner_root,
    file.path(
      project_root,
      "audit/hypotheses/H09/manuscript_s15b_strip_layout_2026_09_14"
    )
  ),
  "The return root is not the sole authorized H09 owner root."
)

evidence_dir <- file.path(owner_root, "evidence")
candidate_path <- file.path(
  owner_root,
  "candidate/H09_observed_timing_patterns.svg"
)
input_path <- file.path(
  project_root,
  "audit/hypotheses/H09/report018_order72j_split_svg_export/candidate/H09_observed_timing_patterns.svg"
)
source_csv_path <- file.path(
  project_root,
  "artifacts/11_source_data/H09/H09_observed_timing_patterns_data.csv"
)
primary_path <- file.path(
  project_root,
  "audit/hypotheses/H09/report018_order72j_split_svg_export/candidate/H09_primary_effects.svg"
)
order_path <- file.path(
  project_root,
  "audit/report_harmonization/final_documents_2026_09_13/h09_s15b_strip_candidate_order_010a.md"
)
dispatch_path <- file.path(
  project_root,
  "audit/report_harmonization/final_documents_2026_09_13/h09_s15b_strip_candidate_order_010a_dispatch_manifest.csv"
)
preview_root <- "/private/tmp/h09-s15b-order010a-preview.rHnqmH"
wrapper_path <- file.path(owner_root, "qa/preview_wrapper.html")

assert_true(
  identical(
    sha256_file(order_path),
    "d57812fe4cfb8242a51ff8e716aa02e30889ff22d7fe9e8ef806100bab4ff68d"
  ) &&
    file.info(order_path)$size == 6407 &&
    identical(
      sha256_file(dispatch_path),
      "5461baf4380ef285a4df9156edac3f4b3fbcd40ff0c396a437f7e338373546f8"
    ) &&
    file.info(dispatch_path)$size == 5711,
  "The controlling order or dispatch identity changed before final sealing."
)

assert_true(
  identical(
    sort(list.files(file.path(owner_root, "candidate"))),
    "H09_observed_timing_patterns.svg"
  ) &&
    identical(
      sort(list.files(file.path(owner_root, "qa"))),
      "preview_wrapper.html"
    ),
  "The candidate or QA directory contains an unexpected file."
)
owner_paths_before <- list.files(
  owner_root,
  recursive = TRUE,
  full.names = TRUE,
  all.files = TRUE,
  no.. = TRUE,
  include.dirs = FALSE
)
assert_true(
  length(owner_paths_before) > 0L &&
    all(Sys.readlink(owner_paths_before) == ""),
  "The candidate package contains a symlink."
)

dispatch <- utils::read.csv(
  dispatch_path,
  stringsAsFactors = FALSE,
  check.names = FALSE
)
assert_true(
  nrow(dispatch) == 32L &&
    !anyDuplicated(dispatch$path) &&
    !sub(paste0("^", project_root, "/"), "", dispatch_path) %in%
      dispatch$path,
  "The dispatch manifest is not exact, unique, and non-circular."
)
dispatch_resolved <- file.path(project_root, dispatch$path)
dispatch_exists <- file.exists(dispatch_resolved)
dispatch_actual_sha256 <- rep(NA_character_, nrow(dispatch))
dispatch_actual_bytes <- rep(NA_real_, nrow(dispatch))
dispatch_actual_sha256[dispatch_exists] <- vapply(
  dispatch_resolved[dispatch_exists],
  sha256_file,
  character(1)
)
dispatch_actual_bytes[dispatch_exists] <- unname(
  file.info(dispatch_resolved[dispatch_exists])$size
)
final_dispatch_rehash <- data.frame(
  path = dispatch$path,
  expected_sha256 = dispatch$sha256,
  actual_sha256 = dispatch_actual_sha256,
  expected_bytes = as.numeric(dispatch$bytes),
  actual_bytes = dispatch_actual_bytes,
  status = ifelse(
    dispatch_exists &
      dispatch_actual_sha256 == dispatch$sha256 &
      dispatch_actual_bytes == as.numeric(dispatch$bytes),
    "PASS",
    "FAIL"
  ),
  stringsAsFactors = FALSE
)
assert_all(
  final_dispatch_rehash$status == "PASS",
  "A dispatch member changed before final sealing."
)

protected <- data.frame(
  path = c(
    input_path,
    source_csv_path,
    primary_path,
    candidate_path,
    wrapper_path
  ),
  expected_sha256 = c(
    "c937252509c5de9448944358a9846842c973bac26b0f0fb4640728fcf8a908b3",
    "34640aba210181b973902e00cd6924f79f6ae76faf01fa3c5b66078e2e2e7cee",
    "a3f9bdb969c075d33adf9a0e6e751a1f967d5111856fcd0db07cbc36575a745a",
    "0a3d0cabcd6cdb67db072cfa566448a885a774db519bea442a973896a7d616e8",
    "c0596044f09a3b28c457091a1e555e8df5b139c8ef49ecf47b701085d01e7a64"
  ),
  expected_bytes = c(1245097, 3028981, 20707, 1245095, 4070),
  stringsAsFactors = FALSE
)
protected$actual_sha256 <- vapply(protected$path, sha256_file, character(1))
protected$actual_bytes <- unname(file.info(protected$path)$size)
protected$status <- ifelse(
  protected$actual_sha256 == protected$expected_sha256 &
    protected$actual_bytes == protected$expected_bytes,
  "PASS",
  "FAIL"
)
protected$path <- ifelse(
  startsWith(protected$path, project_root),
  sub(paste0("^", project_root, "/"), "", protected$path),
  protected$path
)
assert_all(protected$status == "PASS", "A protected or candidate file changed.")

input_raw <- read_raw_file(input_path)
candidate_raw <- read_raw_file(candidate_path)
input_text <- rawToChar(input_raw)
candidate_text <- rawToChar(candidate_raw)
old_patterns <- sprintf(
  "x='%s' y='86.06' width='158.96' height='47.66'",
  c("105.65", "324.73", "543.80")
)
new_patterns <- sprintf(
  "x='%s' y='86.06' width='192.00' height='47.66'",
  c("89.13", "308.21", "527.28")
)
reconstructed <- input_text
for (index in seq_along(old_patterns)) {
  assert_true(
    count_fixed(reconstructed, old_patterns[[index]]) == 2L,
    "A final old-prefix count changed."
  )
  reconstructed <- replace_fixed(
    reconstructed,
    old_patterns[[index]],
    new_patterns[[index]]
  )
}
assert_true(
  identical(charToRaw(reconstructed), candidate_raw),
  "The final candidate is not the exact six-change forward image."
)
reversed <- candidate_text
for (index in seq_along(new_patterns)) {
  assert_true(
    count_fixed(reversed, new_patterns[[index]]) == 2L,
    "A final new-prefix count changed."
  )
  reversed <- replace_fixed(
    reversed,
    new_patterns[[index]],
    old_patterns[[index]]
  )
}
assert_true(
  identical(charToRaw(reversed), input_raw),
  "The final candidate does not reverse to the accepted input."
)

mask_selected <- function(text, patterns) {
  output <- text
  for (index in seq_along(patterns)) {
    output <- replace_fixed(
      output,
      patterns[[index]],
      paste0("{{ORDER010A_RECTANGLE_", index, "}}")
    )
  }
  output
}
masked_input <- mask_selected(input_text, old_patterns)
masked_candidate <- mask_selected(candidate_text, new_patterns)
assert_true(
  identical(masked_input, masked_candidate),
  "A final non-selected SVG byte changed."
)

candidate_document <- xml2::read_xml(
  candidate_raw,
  options = c("NOBLANKS", "NONET")
)
nodes <- xml2::xml_find_all(candidate_document, ".//*")
ids <- xml2::xml_attr(nodes, "id")
ids <- ids[!is.na(ids) & nzchar(ids)]
assert_true(!anyDuplicated(ids), "The candidate contains duplicate IDs.")
root <- xml2::xml_root(candidate_document)
assert_true(
  identical(xml2::xml_attr(root, "width"), "1134.00pt") &&
    identical(xml2::xml_attr(root, "height"), "918.00pt") &&
    identical(xml2::xml_attr(root, "viewBox"), "0 0 1134.00 918.00"),
  "The final candidate dimensions changed."
)

required_evidence <- c(
  "adjacent_strip_gaps.csv",
  "browser_attempts.csv",
  "browser_console.csv",
  "browser_qa_summary.csv",
  "browser_routes.csv",
  "browser_screenshot_identities.csv",
  "browser_visual_findings.csv",
  "candidate_summary.csv",
  "construction_attempts.csv",
  "dispatch_rehash.csv",
  "execution_command.md",
  "forward_reverse_checks.csv",
  "label_geometry.csv",
  "package_versions.csv",
  "preflight_attempts.csv",
  "preview_serve_inventory.csv",
  "protected_inputs_post_candidate.csv",
  "protected_inputs_pre.csv",
  "rectangle_change_map.csv",
  "server_access_log.txt",
  "server_session.csv",
  "session_info.txt",
  "svg_structure_checks.csv",
  "teardown.csv"
)
assert_true(
  identical(sort(list.files(evidence_dir)), sort(required_evidence)),
  "The pre-seal evidence inventory is incomplete or contains an extra file."
)

status_files <- c(
  "dispatch_rehash.csv" = "status",
  "forward_reverse_checks.csv" = "status",
  "svg_structure_checks.csv" = "status",
  "label_geometry.csv" = "status",
  "adjacent_strip_gaps.csv" = "status",
  "protected_inputs_pre.csv" = "status",
  "protected_inputs_post_candidate.csv" = "post_status",
  "rectangle_change_map.csv" = "status",
  "browser_routes.csv" = "status",
  "browser_console.csv" = "status",
  "server_session.csv" = "status",
  "teardown.csv" = "status"
)
for (filename in names(status_files)) {
  data <- utils::read.csv(
    file.path(evidence_dir, filename),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  status_column <- status_files[[filename]]
  assert_true(
    status_column %in% names(data) && all(data[[status_column]] == "PASS"),
    paste0("A recorded status failed in ", filename)
  )
}

routes <- utils::read.csv(
  file.path(evidence_dir, "browser_routes.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
assert_true(
  nrow(routes) == 3L &&
    identical(routes$mode, c("original", "600", "narrow")) &&
    identical(routes$viewport_width_css_px, c(1600L, 1280L, 390L)) &&
    isTRUE(all.equal(routes$rendered_width_css_px, c(1512, 600, 358))) &&
    all(routes$external_resources == 0L),
  "The browser route evidence is incomplete."
)
console <- utils::read.csv(
  file.path(evidence_dir, "browser_console.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
assert_true(
  nrow(console) == 3L &&
    all(console$error_count == 0L) &&
    all(console$warning_count == 0L) &&
    all(console$external_resources == 0L),
  "The browser console was not clean."
)
screenshots <- utils::read.csv(
  file.path(evidence_dir, "browser_screenshot_identities.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
assert_true(
  nrow(screenshots) == 3L &&
    !anyDuplicated(screenshots$mode) &&
    !anyDuplicated(screenshots$sha256) &&
    all(nchar(screenshots$sha256) == 64L) &&
    all(screenshots$bytes > 0L),
  "The browser screenshot identity record is incomplete."
)
findings <- utils::read.csv(
  file.path(evidence_dir, "browser_visual_findings.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
assert_true(
  nrow(findings) == 16L &&
    !any(findings$assessment == "FAIL") &&
    all(findings$assessment %in% c("PASS", "EXPECTED_SCALE_LIMITATION")),
  "The visual findings contain an unclassified or failed observation."
)
summary <- utils::read.csv(
  file.path(evidence_dir, "browser_qa_summary.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
assert_true(
  nrow(summary) == 1L &&
    identical(
      summary$visual_disposition[[1L]],
      "CANDIDATE_VISUAL_PASS_FOR_COORDINATOR_ACCEPTANCE"
    ),
  "The visual disposition is missing."
)
server <- utils::read.csv(
  file.path(evidence_dir, "server_session.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
assert_true(
  nrow(server) == 1L &&
    server$port[[1L]] == 43137L &&
    server$pid[[1L]] == 7663L &&
    server$task_tabs_remaining[[1L]] == 0L &&
    server$viewport_reset[[1L]] &&
    server$server_exit[[1L]] == 0L &&
    server$listener_rows_after_stop[[1L]] == 0L,
  "The server or browser teardown record is incomplete."
)
assert_true(!dir.exists(preview_root), "The temporary preview root remains.")
wrapper_text <- paste(readLines(wrapper_path, warn = FALSE), collapse = "\n")
assert_true(
  !grepl("https?://", wrapper_text, perl = TRUE) &&
    !grepl("<script[^>]+src=", wrapper_text, perl = TRUE) &&
    !grepl("<link[^>]+href=", wrapper_text, perl = TRUE),
  "The preserved preview wrapper contains an external resource."
)

lsof_path <- Sys.which("lsof")
assert_true(nzchar(lsof_path), "lsof is unavailable for the final port check.")
lsof_output <- tempfile(pattern = "h09-order010a-lsof-", tmpdir = tempdir())
on.exit(unlink(lsof_output), add = TRUE)
lsof_status <- suppressWarnings(system2(
  lsof_path,
  c("-nP", "-iTCP:43137", "-sTCP:LISTEN"),
  stdout = lsof_output,
  stderr = lsof_output
))
lsof_lines <- readLines(lsof_output, warn = FALSE)
assert_true(
  identical(as.integer(lsof_status), 1L) && length(lsof_lines) == 0L,
  "A listener remains on the H09 preview port."
)

final_candidate_checks <- data.frame(
  check = c(
    "candidate_sha256",
    "candidate_bytes",
    "exact_forward_image",
    "exact_reverse_image",
    "nonselected_bytes_exact",
    "dispatch_final_exact",
    "protected_final_exact",
    "browser_routes",
    "browser_console_errors",
    "browser_console_warnings",
    "browser_screenshot_identities",
    "visual_findings_failed",
    "temporary_viewport_reset",
    "task_tabs_remaining",
    "temporary_preview_root_remaining",
    "listener_rows_remaining",
    "package_symlinks"
  ),
  expected = c(
    "0a3d0cabcd6cdb67db072cfa566448a885a774db519bea442a973896a7d616e8",
    "1245095",
    "TRUE",
    "TRUE",
    "TRUE",
    "32/32",
    "5/5",
    "3/3",
    "0",
    "0",
    "3/3",
    "0",
    "TRUE",
    "0",
    "FALSE",
    "0",
    "0"
  ),
  actual = c(
    sha256_file(candidate_path),
    as.character(file.info(candidate_path)$size),
    as.character(identical(charToRaw(reconstructed), candidate_raw)),
    as.character(identical(charToRaw(reversed), input_raw)),
    as.character(identical(masked_input, masked_candidate)),
    paste0(sum(final_dispatch_rehash$status == "PASS"), "/32"),
    paste0(sum(protected$status == "PASS"), "/5"),
    paste0(sum(routes$status == "PASS"), "/3"),
    as.character(sum(console$error_count)),
    as.character(sum(console$warning_count)),
    paste0(nrow(screenshots), "/3"),
    as.character(sum(findings$assessment == "FAIL")),
    as.character(server$viewport_reset[[1L]]),
    as.character(server$task_tabs_remaining[[1L]]),
    as.character(dir.exists(preview_root)),
    as.character(length(lsof_lines)),
    as.character(sum(Sys.readlink(owner_paths_before) != ""))
  ),
  stringsAsFactors = FALSE
)
final_candidate_checks$status <- ifelse(
  final_candidate_checks$expected == final_candidate_checks$actual,
  "PASS",
  "FAIL"
)
assert_all(
  final_candidate_checks$status == "PASS",
  "A final candidate return check failed."
)

final_dispatch_path <- file.path(evidence_dir, "final_dispatch_rehash.csv")
final_protected_path <- file.path(evidence_dir, "final_protected_rehash.csv")
final_checks_path <- file.path(evidence_dir, "final_candidate_checks.csv")
final_session_path <- file.path(evidence_dir, "final_session_info.txt")
manifest_path <- file.path(owner_root, "non_circular_manifest.csv")
assert_true(
  !any(file.exists(c(
    final_dispatch_path,
    final_protected_path,
    final_checks_path,
    final_session_path,
    manifest_path
  ))),
  "A final seal output already exists."
)
write_csv_once(final_dispatch_rehash, final_dispatch_path)
write_csv_once(protected, final_protected_path)
write_csv_once(final_candidate_checks, final_checks_path)
write_lines_once(
  c(
    paste0("R_VERSION=", getRversion()),
    paste0("LIB_PATHS=", paste(.libPaths(), collapse = "|")),
    paste0("LSOF_STATUS=", lsof_status),
    "LISTENER_ROWS=0",
    capture.output(utils::sessionInfo())
  ),
  final_session_path
)

relative_paths <- sort(list.files(
  owner_root,
  recursive = TRUE,
  all.files = TRUE,
  no.. = TRUE,
  include.dirs = FALSE
))
relative_paths <- setdiff(relative_paths, "non_circular_manifest.csv")
absolute_paths <- file.path(owner_root, relative_paths)
assert_true(
  length(relative_paths) > 0L &&
    !anyDuplicated(relative_paths) &&
    all(Sys.readlink(absolute_paths) == ""),
  "The final package contains a duplicate path or symlink."
)
manifest <- data.frame(
  path = relative_paths,
  sha256 = vapply(absolute_paths, sha256_file, character(1)),
  bytes = unname(file.info(absolute_paths)$size),
  stringsAsFactors = FALSE
)
assert_true(
  !"non_circular_manifest.csv" %in% manifest$path,
  "The final package manifest is circular."
)
write_csv_once(manifest, manifest_path)

sealed <- utils::read.csv(
  manifest_path,
  stringsAsFactors = FALSE,
  check.names = FALSE
)
assert_true(
  identical(sealed$path, manifest$path) &&
    identical(sealed$sha256, manifest$sha256) &&
    identical(as.numeric(sealed$bytes), as.numeric(manifest$bytes)),
  "The final package manifest did not round-trip exactly."
)

cat(sprintf(
  paste0(
    "H09_S15B_ORDER010A_RETURN=PASS candidate=%s dispatch=32/32 ",
    "protected=5/5 browser=3/3 console=0/0 listener=0 tabs=0 ",
    "manifest_rows=%d manifest_sha256=%s R=%s\n"
  ),
  sha256_file(candidate_path),
  nrow(sealed),
  sha256_file(manifest_path),
  as.character(getRversion())
))
