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
qa_root <- file.path(owner_root, "qa")
evidence_dir <- file.path(qa_root, "evidence")
serve_root <- file.path(qa_root, "serve")
qa_manifest_path <- file.path(qa_root, "qa_non_circular_manifest.csv")
stop_handoff_path <- file.path(
  qa_root,
  "REPORT018-ORDER72J-VISUAL-LEASE-003-STOP.md"
)
stopifnot(
  dir.exists(qa_root),
  dir.exists(evidence_dir),
  dir.exists(serve_root),
  !file.exists(qa_manifest_path),
  !file.exists(stop_handoff_path)
)

sha256_file <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
}

assert_owner_target <- function(path) {
  normalized <- normalizePath(path, winslash = "/", mustWork = FALSE)
  stopifnot(startsWith(normalized, paste0(owner_root, "/")))
  normalized
}

write_csv_once <- function(object, path) {
  assert_owner_target(path)
  stopifnot(!file.exists(path))
  utils::write.csv(
    object,
    path,
    row.names = FALSE,
    na = "",
    fileEncoding = "UTF-8"
  )
}

write_lines_once <- function(lines, path) {
  assert_owner_target(path)
  stopifnot(!file.exists(path))
  writeLines(lines, path, useBytes = TRUE)
}

rehash_manifest <- function(path, manifest_id, expected_rows) {
  manifest <- readr::read_csv(path, show_col_types = FALSE)
  stopifnot(
    nrow(manifest) == expected_rows,
    identical(names(manifest), c("path", "sha256", "bytes")),
    !anyDuplicated(manifest$path)
  )
  resolved <- ifelse(
    startsWith(manifest$path, "/"),
    manifest$path,
    file.path(root, manifest$path)
  )
  exists <- file.exists(resolved)
  observed_sha256 <- rep(NA_character_, nrow(manifest))
  observed_bytes <- rep(NA_real_, nrow(manifest))
  observed_sha256[exists] <- vapply(
    resolved[exists],
    sha256_file,
    character(1)
  )
  observed_bytes[exists] <- as.numeric(file.info(resolved[exists])$size)
  result <- data.frame(
    manifest = manifest_id,
    path = manifest$path,
    expected_sha256 = manifest$sha256,
    observed_sha256 = observed_sha256,
    expected_bytes = manifest$bytes,
    observed_bytes = observed_bytes,
    exists = exists,
    status = ifelse(
      exists &
        observed_sha256 == manifest$sha256 &
        observed_bytes == manifest$bytes,
      "PASS",
      "FAIL"
    ),
    stringsAsFactors = FALSE
  )
  stopifnot(all(result$status == "PASS"))
  result
}

release_root <- file.path(
  root,
  "audit/report_harmonization/report018_order72j_component_exports_release"
)
post_pin_rehash <- rbind(
  rehash_manifest(
    file.path(release_root, "release_manifest.csv"),
    "release_manifest",
    123L
  ),
  rehash_manifest(
    file.path(release_root, "H07_execution_input_pins.csv"),
    "H07_execution_inputs",
    39L
  ),
  rehash_manifest(
    file.path(release_root, "H07_preservation_inventory.csv"),
    "H07_preservation",
    1451L
  )
)
stopifnot(nrow(post_pin_rehash) == 1613L)
pre_pin_rehash <- readr::read_csv(
  file.path(evidence_dir, "preflight_rehash.csv"),
  show_col_types = FALSE
)
stopifnot(
  identical(pre_pin_rehash$manifest, post_pin_rehash$manifest),
  identical(pre_pin_rehash$path, post_pin_rehash$path),
  identical(
    pre_pin_rehash$expected_sha256,
    post_pin_rehash$expected_sha256
  ),
  identical(
    pre_pin_rehash$observed_sha256,
    post_pin_rehash$observed_sha256
  ),
  all(pre_pin_rehash$expected_bytes == post_pin_rehash$expected_bytes),
  all(pre_pin_rehash$observed_bytes == post_pin_rehash$observed_bytes),
  all(pre_pin_rehash$status == "PASS"),
  all(post_pin_rehash$status == "PASS")
)

candidate_path <- file.path(
  owner_root,
  "candidate/H07_revised_smooth_derivative_pairs_near_eye.svg"
)
attempt_path <- file.path(
  owner_root,
  "attempts/attempt_01/H07_revised_smooth_derivative_pairs_near_eye.svg"
)
png_path <- file.path(
  root,
  "artifacts/08_figures/H07/H07_revised_smooth_derivative_pairs_near_eye.png"
)
static_manifest_path <- file.path(owner_root, "non_circular_manifest.csv")
static_handoff_path <- file.path(
  owner_root,
  "REPORT018-ORDER72J-COMPONENT-REVIEW.md"
)
lease_path <- file.path(
  root,
  paste0(
    "audit/report_harmonization/",
    "report018_order72j_component_exports_dispatch/visual_lease_003.csv"
  )
)
svg_copy <- file.path(
  serve_root,
  "assets/H07_revised_smooth_derivative_pairs_near_eye.svg"
)
png_copy <- file.path(
  serve_root,
  "assets/H07_revised_smooth_derivative_pairs_near_eye.png"
)
anchor_paths <- c(
  candidate_path,
  attempt_path,
  png_path,
  static_manifest_path,
  static_handoff_path,
  lease_path,
  svg_copy,
  png_copy
)
anchor_expected <- c(
  "f12465fd629c44bbcc7f09a13fccd88b41eda9b80d1cba1310bbdab4ce52ba57",
  "f12465fd629c44bbcc7f09a13fccd88b41eda9b80d1cba1310bbdab4ce52ba57",
  "f19763fe3c14c723ac38846bf735c0465ba2ee18765777a4f7304c677be71113",
  "b0952d912f00abb6be3c4ada6a54f86d25c87080bf933fa627a4f18351091b1f",
  "26c2ee98e535258db3c993f0d805aa0251d5404a60c8359f2cdda32ea1365e95",
  "cf72005894273b322f7374d5297f6a073b6bf578d1fc3475c769855f62ec96a9",
  "f12465fd629c44bbcc7f09a13fccd88b41eda9b80d1cba1310bbdab4ce52ba57",
  "f19763fe3c14c723ac38846bf735c0465ba2ee18765777a4f7304c677be71113"
)
anchor_observed <- vapply(anchor_paths, sha256_file, character(1))
stopifnot(identical(unname(anchor_observed), anchor_expected))
post_anchor_rehash <- data.frame(
  role = c(
    "immutable SVG candidate",
    "retained SVG attempt",
    "pinned accepted PNG comparator",
    "accepted static non-circular seal",
    "accepted static owner handoff",
    "exclusive visual lease 003",
    "bounded serve SVG copy",
    "bounded serve PNG copy"
  ),
  path = substring(anchor_paths, nchar(root) + 2L),
  expected_sha256 = anchor_expected,
  observed_sha256 = unname(anchor_observed),
  bytes = as.numeric(file.info(anchor_paths)$size),
  status = "PASS",
  stringsAsFactors = FALSE
)

serve_inventory <- readr::read_csv(
  file.path(evidence_dir, "serve_inventory.csv"),
  show_col_types = FALSE
)
serve_files <- sort(list.files(
  serve_root,
  recursive = TRUE,
  all.files = TRUE,
  no.. = TRUE,
  include.dirs = FALSE
))
serve_paths <- file.path(serve_root, serve_files)
stopifnot(
  nrow(serve_inventory) == 4L,
  identical(
    serve_inventory$path,
    file.path("qa/serve", serve_files)
  ),
  identical(
    unname(serve_inventory$sha256),
    unname(vapply(serve_paths, sha256_file, character(1)))
  ),
  all(serve_inventory$bytes == as.numeric(file.info(serve_paths)$size)),
  all(Sys.readlink(serve_paths) == "")
)

port <- 43137L
lsof_path <- Sys.which("lsof")
stopifnot(nzchar(lsof_path))
lsof_output <- suppressWarnings(system2(
  lsof_path,
  args = c(
    "-nP",
    paste0("-iTCP:", port),
    "-sTCP:LISTEN"
  ),
  stdout = TRUE,
  stderr = TRUE
))
lsof_status <- attr(lsof_output, "status")
if (is.null(lsof_status)) lsof_status <- 0L
stopifnot(lsof_status == 1L, length(lsof_output) == 0L)

exact_command <- paste(
  "python3 -m http.server 43137 --bind 127.0.0.1 --directory",
  file.path(owner_root, "qa/serve")
)
loopback_attempt <- data.frame(
  lease = "ORDER72J-VISUAL-LEASE-003",
  attempt = 1L,
  bind_address = "127.0.0.1",
  port = port,
  serve_root = file.path(owner_relative, "qa/serve"),
  allowed_methods = "GET_HEAD",
  exact_command = exact_command,
  python_version = "Python 3.14.3",
  command_exit = 1L,
  listener_created = FALSE,
  content_loaded = FALSE,
  browser_tab_created = FALSE,
  escalation_requested = FALSE,
  alternate_route_attempted = FALSE,
  status = "STOP_POLICY_BIND_REJECTED",
  error = "PermissionError: [Errno 1] Operation not permitted",
  stringsAsFactors = FALSE
)
browser_status <- data.frame(
  lease = "ORDER72J-VISUAL-LEASE-003",
  route_inventory = "http://127.0.0.1:43137/index.html",
  intrinsic_route =
    "http://127.0.0.1:43137/compare.html?width=intrinsic",
  width_642_route =
    "http://127.0.0.1:43137/compare.html?width=642",
  width_708_route =
    "http://127.0.0.1:43137/compare.html?width=708",
  content_loaded = FALSE,
  viewport = "NOT_AVAILABLE",
  intrinsic_comparison = "NOT_RUN",
  width_642_comparison = "NOT_RUN",
  width_708_comparison = "NOT_RUN",
  nine_metric_rows = "NOT_INSPECTED",
  fitted_left_derivative_right = "NOT_INSPECTED",
  transitions_intervals_rugs = "NOT_INSPECTED",
  labels_and_references = "NOT_INSPECTED",
  uppercase_left_outer_panel_readiness = "NOT_INSPECTED",
  text_legibility_aspect_ratio_clipping = "NOT_INSPECTED",
  console_result = "NOT_AVAILABLE",
  screenshots = 0L,
  genuine_page_defect = FALSE,
  visual_acceptance = FALSE,
  status = "STOPPED_BEFORE_CONTENT_LOAD",
  stringsAsFactors = FALSE
)
teardown_status <- data.frame(
  lease = "ORDER72J-VISUAL-LEASE-003",
  task_browser_tabs_created = 0L,
  task_browser_tabs_closed = 0L,
  task_browser_tabs_remaining = 0L,
  listener_created = FALSE,
  listener_stop_action = "NOT_APPLICABLE_PROCESS_EXITED_ON_BIND_REJECTION",
  lsof_port = port,
  lsof_command_status_after_stop = lsof_status,
  lsof_listener_rows_after_stop = length(lsof_output),
  listener_remaining = FALSE,
  persistent_task_process_remaining = FALSE,
  status = "PASS",
  stringsAsFactors = FALSE
)
lease_disposition <- data.frame(
  lease = "ORDER72J-VISUAL-LEASE-003",
  owner = "H07",
  incoming_state = "ACTIVE",
  outgoing_state = "EXPLICITLY_RELEASED_WITHOUT_VISUAL_ACCEPTANCE",
  visual_disposition = "STOPPED_POLICY_BIND_REJECTED_BEFORE_CONTENT_LOAD",
  candidate_disposition = "UNCHANGED_NOT_PROMOTED",
  mandatory_gate = "REPORT018-ORDER72J-COMPONENT-REVIEW",
  coordinator_action =
    "Independent receipt of stopped visual package; lease may advance",
  stringsAsFactors = FALSE
)
summary <- data.frame(
  check = c(
    "R version",
    "release manifest exact",
    "H07 execution inputs exact",
    "H07 preservation exact",
    "candidate and protected anchors exact",
    "bounded serve files",
    "bounded serve symlinks",
    "loopback bind",
    "browser content loaded",
    "browser tabs created",
    "listener rows after stop",
    "candidate changed",
    "renderer correction consumed",
    "scientific computation",
    "visual acceptance",
    "lease disposition"
  ),
  expected = c(
    "4.6.1",
    "123/123",
    "39/39",
    "1451/1451",
    "8/8",
    "4",
    "0",
    "STOP_POLICY_BIND_REJECTED",
    "FALSE",
    "0",
    "0",
    "FALSE",
    "FALSE",
    "FALSE",
    "FALSE",
    "EXPLICITLY_RELEASED_WITHOUT_VISUAL_ACCEPTANCE"
  ),
  observed = c(
    as.character(getRversion()),
    paste0(sum(post_pin_rehash$manifest == "release_manifest"), "/123"),
    paste0(sum(post_pin_rehash$manifest == "H07_execution_inputs"), "/39"),
    paste0(sum(post_pin_rehash$manifest == "H07_preservation"), "/1451"),
    paste0(sum(post_anchor_rehash$status == "PASS"), "/8"),
    as.character(nrow(serve_inventory)),
    as.character(sum(serve_inventory$symlink)),
    loopback_attempt$status,
    as.character(loopback_attempt$content_loaded),
    as.character(as.integer(loopback_attempt$browser_tab_created)),
    as.character(teardown_status$lsof_listener_rows_after_stop),
    "FALSE",
    "FALSE",
    "FALSE",
    as.character(browser_status$visual_acceptance),
    lease_disposition$outgoing_state
  ),
  status = "PASS",
  stringsAsFactors = FALSE
)
stopifnot(identical(summary$expected, summary$observed))

write_csv_once(
  loopback_attempt,
  file.path(evidence_dir, "loopback_attempt.csv")
)
write_csv_once(
  browser_status,
  file.path(evidence_dir, "browser_qa_status.csv")
)
write_csv_once(
  teardown_status,
  file.path(evidence_dir, "teardown_status.csv")
)
write_csv_once(
  post_pin_rehash,
  file.path(evidence_dir, "post_pin_rehash.csv")
)
write_csv_once(
  post_anchor_rehash,
  file.path(evidence_dir, "post_anchor_rehash.csv")
)
write_csv_once(
  lease_disposition,
  file.path(evidence_dir, "visual_lease_disposition.csv")
)
write_csv_once(
  summary,
  file.path(evidence_dir, "qa_final_summary.csv")
)
write_lines_once(
  c(
    "Traceback (most recent call last):",
    "  Python 3.14.3 http.server failed during TCPServer.server_bind().",
    "  self.socket.bind(self.server_address)",
    "PermissionError: [Errno 1] Operation not permitted"
  ),
  file.path(evidence_dir, "loopback_stderr_exact_summary.txt")
)

stop_handoff <- c(
  "# REPORT-018 Order72j H07 visual lease 003 stop",
  "",
  "Status: `STOPPED_POLICY_BIND_REJECTED_BEFORE_CONTENT_LOAD`.",
  "",
  "Visual acceptance: `FALSE`. This is a route-policy stop, not a demonstrated component or page defect.",
  "",
  "Lease `ORDER72J-VISUAL-LEASE-003` is explicitly released with no browser content load. Mandatory gate: `REPORT018-ORDER72J-COMPONENT-REVIEW`.",
  "",
  "## Exact stop",
  "",
  paste0("- Command: `", exact_command, "`."),
  "- Exit status: `1`.",
  "- Error: `PermissionError: [Errno 1] Operation not permitted` during `TCPServer.server_bind()`.",
  "- Per the dispatch instruction, no escalation and no alternate browser or serving route were attempted.",
  "- No content loaded, no browser tab was created, no screenshot was taken, and browser console evidence is unavailable.",
  "",
  "## Prepared immutable route",
  "",
  "The narrow serve root contains exactly four non-symlink files: a byte-exact candidate SVG copy, a byte-exact pinned PNG comparator copy, one route index, and one local comparison page. The page exposes intrinsic proportion, 642 CSS px and 708 px routes with no external resources. Because binding was rejected, all requested visual observations are `NOT_INSPECTED`.",
  "",
  "## Teardown and preservation",
  "",
  "The server process exited on bind rejection. A post-stop `lsof` check found zero listeners on 127.0.0.1:43137. No task-created browser tabs or persistent processes remain.",
  "",
  "The SVG candidate remains unchanged at SHA-256 `f12465fd629c44bbcc7f09a13fccd88b41eda9b80d1cba1310bbdab4ce52ba57` and was not promoted. The accepted static handoff and static non-circular manifest remain byte-exact. Post-stop R 4.6.1 replay passes the 123-row release manifest, 39 H07 execution pins and 1,451-entry H07 preservation inventory.",
  "",
  "No renderer correction, Quarto, Word, LibreOffice, scientific computation, source mutation or accepted-artifact replacement occurred."
)
write_lines_once(stop_handoff, stop_handoff_path)

incremental_code <- file.path(
  owner_root,
  c(
    "code/06_prepare_visual_qa_lease_003.R",
    "code/07_seal_visual_qa_lease_003_stop.R"
  )
)
qa_files <- list.files(
  qa_root,
  recursive = TRUE,
  full.names = TRUE,
  all.files = TRUE,
  no.. = TRUE
)
qa_files <- qa_files[file.info(qa_files)$isdir %in% FALSE]
manifest_files <- sort(unique(c(
  normalizePath(incremental_code, winslash = "/", mustWork = TRUE),
  normalizePath(qa_files, winslash = "/", mustWork = TRUE)
)))
manifest_files <- setdiff(
  manifest_files,
  normalizePath(qa_manifest_path, winslash = "/", mustWork = FALSE)
)
qa_manifest <- data.frame(
  path = substring(manifest_files, nchar(root) + 2L),
  sha256 = unname(vapply(manifest_files, sha256_file, character(1))),
  bytes = as.numeric(file.info(manifest_files)$size),
  stringsAsFactors = FALSE
)
stopifnot(
  nrow(qa_manifest) > 0L,
  !anyDuplicated(qa_manifest$path),
  !any(qa_manifest$path == substring(qa_manifest_path, nchar(root) + 2L))
)
write_csv_once(qa_manifest, qa_manifest_path)

manifest_live <- readr::read_csv(
  qa_manifest_path,
  show_col_types = FALSE
)
current_qa_files <- list.files(
  qa_root,
  recursive = TRUE,
  full.names = TRUE,
  all.files = TRUE,
  no.. = TRUE
)
current_qa_files <- current_qa_files[
  file.info(current_qa_files)$isdir %in% FALSE
]
current_manifest_files <- sort(unique(c(
  normalizePath(incremental_code, winslash = "/", mustWork = TRUE),
  normalizePath(current_qa_files, winslash = "/", mustWork = TRUE)
)))
current_manifest_files <- setdiff(
  current_manifest_files,
  normalizePath(qa_manifest_path, winslash = "/", mustWork = TRUE)
)
stopifnot(
  identical(
    unname(manifest_live$path),
    unname(substring(current_manifest_files, nchar(root) + 2L))
  ),
  identical(
    unname(manifest_live$sha256),
    unname(vapply(current_manifest_files, sha256_file, character(1)))
  ),
  all(
    manifest_live$bytes ==
      as.numeric(file.info(current_manifest_files)$size)
  ),
  sha256_file(candidate_path) == anchor_expected[[1L]],
  sha256_file(static_manifest_path) == anchor_expected[[4L]],
  sha256_file(static_handoff_path) == anchor_expected[[5L]]
)

cat(sprintf(
  paste0(
    "ORDER72J_H07_VISUAL_STOP=SEALED status=%s candidate=%s ",
    "qa_manifest=%s rows=%d listener_rows=0 lease=EXPLICITLY_RELEASED\n"
  ),
  browser_status$status,
  sha256_file(candidate_path),
  sha256_file(qa_manifest_path),
  nrow(manifest_live)
))
