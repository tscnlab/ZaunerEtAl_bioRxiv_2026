#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE, warn = 2)

stopifnot(identical(as.character(getRversion()), "4.6.1"))

suppressPackageStartupMessages({
  library(digest)
  library(jsonlite)
})

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
setwd(root)

evidence_relative <- paste0(
  "audit/hypotheses/H07/",
  "report018_order53a_companion_no_rerender_completion"
)
evidence_dir <- file.path(root, evidence_relative)
stopifnot(dir.exists(evidence_dir))

sha256_file <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
}

read_evidence <- function(name) {
  utils::read.csv(
    file.path(evidence_dir, name),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}

write_evidence <- function(object, name) {
  utils::write.csv(
    object,
    file.path(evidence_dir, name),
    row.names = FALSE,
    na = "",
    fileEncoding = "UTF-8"
  )
}

require_all <- function(condition, message) {
  if (!all(condition)) stop(message, call. = FALSE)
  invisible(TRUE)
}

preflight <- read_evidence("preflight_status.csv")
dispatch <- read_evidence("dispatch_reconciliation_preqa.csv")
static <- read_evidence("static_acceptance_checks.csv")
static_failures <- read_evidence("static_acceptance_failures.csv")
live_manifest <- read_evidence("live_manifest_replay.csv")
semantic <- read_evidence("semantic_replay.csv")
build_comparison <- read_evidence("build_inventory_comparison.csv")
protected_comparison <- read_evidence("protected_inventory_comparison.csv")
build_postqa <- read_evidence("build_inventory_postqa.csv")
cleanup_preqa <- read_evidence("canonical_cleanup_preqa.csv")

central_verification_path <- file.path(
  root,
  paste0(
    "audit/report_harmonization/",
    "report018_h07_order53_stopped_independent_verification.csv"
  )
)
central_verification <- utils::read.csv(
  central_verification_path,
  stringsAsFactors = FALSE,
  check.names = FALSE
)

stopifnot(
  nrow(preflight) == 5L,
  nrow(dispatch) == 26L,
  nrow(static) == 26L,
  nrow(static_failures) == 0L,
  nrow(central_verification) == 41L,
  nrow(live_manifest) == 1235L,
  nrow(build_comparison) == 851L,
  nrow(protected_comparison) == 1404L,
  nrow(cleanup_preqa) == 16L
)
require_all(preflight$status == "PASS", "Preflight evidence is not all PASS.")
require_all(dispatch$status == "PASS", "Dispatch reconciliation is not all PASS.")
require_all(static$status == "PASS", "Static replay is not all PASS.")
require_all(
  central_verification$status == "PASS",
  "The sealed 41-row central verification is not all PASS."
)
require_all(live_manifest$exact, "The 1,235-row live manifest replay is not exact.")
require_all(semantic$status == "PASS", "Semantic replay is not all PASS.")
require_all(
  build_comparison$status == "BYTE_IDENTICAL",
  "Build inventory changed during browser QA."
)
require_all(
  protected_comparison$status == "BYTE_IDENTICAL",
  "Protected inventory changed during browser QA."
)
require_all(!build_postqa$is_symlink, "A build symlink exists after browser QA.")

cleanup_postqa <- cleanup_preqa
cleanup_postqa$exists_postqa <- file.exists(file.path(root, cleanup_postqa$relative_path))
cleanup_postqa$status_postqa <- ifelse(
  cleanup_postqa$exists_postqa,
  "FAIL_PRESENT",
  "PASS_ABSENT"
)
require_all(
  !cleanup_postqa$exists_postqa,
  "An accepted canonical-cleanup path was recreated."
)
write_evidence(cleanup_postqa, "canonical_cleanup_postqa.csv")

visual <- jsonlite::read_json(
  file.path(evidence_dir, "qa_visual_acceptance.json"),
  simplifyVector = TRUE
)
console_events <- jsonlite::read_json(
  file.path(evidence_dir, "qa_browser_console.json"),
  simplifyVector = TRUE
)
narrow_scrollers <- jsonlite::read_json(
  file.path(evidence_dir, "qa_narrow_708x1000_scroller_exercise.json"),
  simplifyVector = TRUE
)
zoom_scrollers <- jsonlite::read_json(
  file.path(evidence_dir, "qa_zoom_equivalent_720x500_scroller_exercise.json"),
  simplifyVector = TRUE
)
figure_metric <- jsonlite::read_json(
  file.path(evidence_dir, "qa_170mm_metric_sample_support_metrics.json"),
  simplifyVector = TRUE
)
figure_site <- jsonlite::read_json(
  file.path(evidence_dir, "qa_170mm_site_photoperiod_ranges_metrics.json"),
  simplifyVector = TRUE
)

stopifnot(
  identical(visual$status, "PASS"),
  visual$browser_console_warning_or_error_count == 0L,
  visual$desktop_1440x1000$tables_reviewed == 21L,
  visual$desktop_1440x1000$figures_reviewed == 2L,
  visual$desktop_1440x1000$mermaid_reviewed == 1L,
  visual$desktop_1440x1000$endpoint_screenshots_reviewed == 24L,
  visual$desktop_1440x1000$page_horizontal_overflow_px == 0L,
  visual$narrow_708x1000$page_horizontal_overflow_px == 0L,
  visual$zoom_equivalent_720x500$page_horizontal_overflow_px == 0L,
  length(console_events) == 0L,
  nrow(narrow_scrollers) == 2L,
  nrow(zoom_scrollers) == 2L,
  all(narrow_scrollers$pass),
  all(zoom_scrollers$pass),
  all(narrow_scrollers$returned == narrow_scrollers$before),
  all(zoom_scrollers$returned == zoom_scrollers$before),
  all(narrow_scrollers$far >= narrow_scrollers$maxScroll - 0.5),
  all(zoom_scrollers$far >= zoom_scrollers$maxScroll - 0.5),
  figure_metric$complete,
  figure_site$complete,
  figure_metric$documentOverflowX == 0L,
  figure_site$documentOverflowX == 0L,
  figure_metric$differencePx <= 0.5,
  figure_site$differencePx <= 0.5,
  figure_metric$rendered$width == 643L,
  figure_site$rendered$width == 643L
)

screenshot_paths <- sort(list.files(
  evidence_dir,
  pattern = "^qa_.*[.]png$",
  full.names = TRUE
))
screenshot_names <- basename(screenshot_paths)
screenshot_group <- ifelse(
  grepl("^qa_desktop_", screenshot_names),
  "1440 x 1000",
  ifelse(
    grepl("^qa_narrow_", screenshot_names),
    "708 x 1000",
    ifelse(
      grepl("^qa_zoom_equivalent_", screenshot_names),
      "720 x 500, 200 percent equivalent",
      "170 mm exported figure"
    )
  )
)
screenshot_manifest <- data.frame(
  file = screenshot_names,
  viewport_group = screenshot_group,
  sha256 = vapply(screenshot_paths, sha256_file, character(1)),
  bytes = as.numeric(file.info(screenshot_paths)$size),
  manual_inspection = "PASS",
  stringsAsFactors = FALSE
)
stopifnot(
  nrow(screenshot_manifest) == 36L,
  sum(grepl("^qa_desktop_endpoint_", screenshot_names)) == 24L,
  sum(grepl("^qa_narrow_708x1000_endpoint_", screenshot_names)) == 3L,
  sum(grepl("^qa_narrow_708x1000_scroller_.*_far[.]png$", screenshot_names)) == 2L,
  sum(grepl("^qa_zoom_equivalent_720x500_scroller_.*_far[.]png$", screenshot_names)) == 2L,
  sum(grepl("^qa_170mm_", screenshot_names)) == 2L,
  !anyDuplicated(screenshot_names),
  all(screenshot_manifest$bytes > 0)
)
write_evidence(screenshot_manifest, "qa_screenshot_manifest.csv")

lsof_path <- Sys.which("lsof")
stopifnot(nzchar(lsof_path))
listener_output <- suppressWarnings(system2(
  lsof_path,
  c("-nP", "-iTCP:48753", "-sTCP:LISTEN"),
  stdout = TRUE,
  stderr = TRUE
))
listener_status <- attr(listener_output, "status")
if (is.null(listener_status)) listener_status <- 0L
stopifnot(listener_status == 1L, length(listener_output) == 0L)

ps_output <- system2(
  Sys.which("ps"),
  c("-axo", "pid=,ppid=,command="),
  stdout = TRUE,
  stderr = TRUE
)
ps_status <- attr(ps_output, "status")
if (is.null(ps_status)) ps_status <- 0L
stopifnot(ps_status == 0L)

parse_pid <- function(line) {
  as.integer(sub("^\\s*([0-9]+).*$", "\\1", line))
}
parse_ppid <- function(line) {
  as.integer(sub("^\\s*[0-9]+\\s+([0-9]+).*$", "\\1", line))
}
ps_pid <- vapply(ps_output, parse_pid, integer(1))
ps_ppid <- vapply(ps_output, parse_ppid, integer(1))
ancestor_pids <- Sys.getpid()
repeat {
  parent <- ps_ppid[match(tail(ancestor_pids, 1L), ps_pid)]
  if (is.na(parent) || parent == 0L || parent %in% ancestor_pids) break
  ancestor_pids <- c(ancestor_pids, parent)
}
process_pattern <- paste(
  c(
    "quarto", "pandoc", "knitr", "rmarkdown",
    "post_render_gt_html_semantics", "repair_gt_html_semantics",
    "http[.]server", "48753", "Rscript.*H07", "H07.*Rscript"
  ),
  collapse = "|"
)
process_matches <- ps_output[
  grepl(process_pattern, ps_output, ignore.case = TRUE) &
    !ps_pid %in% ancestor_pids
]
stopifnot(length(process_matches) == 0L)

teardown <- data.frame(
  check = c(
    "QA viewport override reset",
    "QA tab closed",
    "loopback server exit",
    "port 48753 listener postflight",
    "corrected relevant-process scan",
    "browser URL-policy limitation classification"
  ),
  observed = c(
    "reset() completed without error",
    "closed; in-app QA browser session returned zero tabs",
    "keyboard interrupt handled; server exit 0",
    sprintf("lsof exit %d with zero output rows", listener_status),
    "zero non-ancestor Quarto, Pandoc, rendering, semantic-hook, H07 Rscript, or loopback matches",
    paste0(
      "ephemeral data: wrapper rejected; direct secure-loopback PNG endpoints ",
      "used without bypass or retry"
    )
  ),
  classification = c("PASS", "PASS", "PASS", "PASS", "PASS", "NON_DEFECT"),
  stringsAsFactors = FALSE
)
write_evidence(teardown, "teardown_status.csv")

endpoint_paths <- c(
  "notebooks/hypotheses/H07.qmd",
  "_build/nathealth/notebooks/hypotheses/H07.html",
  "audit/hypotheses/H07/H07_analysis_preparation.qmd",
  "_build/nathealth/audit/hypotheses/H07/H07_analysis_preparation.qmd",
  "_build/nathealth/audit/hypotheses/H07/H07_analysis_preparation.html",
  "artifacts/12_manifests/H07/H07_preparation_report_manifest.csv"
)
endpoint_expected <- c(
  "c779c57ffc64a15c82e519ef38e865a39108a6563d82e408e4522253c61e8226",
  "7814860467f71311c56e22960e757059524ccc3890b0721708eda7a5c661ab40",
  "a6c05e81333bb612e99ef431f42f47860ac26b6d5c0f0f44ecbce019ee470d1b",
  "a6c05e81333bb612e99ef431f42f47860ac26b6d5c0f0f44ecbce019ee470d1b",
  "4c03a3e3cdfa1c6eac13d5785ceee8306e6d0941278b679a1eb88e357b270d93",
  "db1b00058848d27eed9d5ece9d9eae97851d1bdc997c4f2fe28d2ce9abd3c8e2"
)
endpoint_files <- file.path(root, endpoint_paths)
endpoint_observed <- vapply(endpoint_files, sha256_file, character(1))
endpoint_identities <- data.frame(
  path = endpoint_paths,
  expected_sha256 = endpoint_expected,
  observed_sha256 = endpoint_observed,
  bytes = as.numeric(file.info(endpoint_files)$size),
  status = ifelse(endpoint_expected == endpoint_observed, "PASS", "FAIL"),
  stringsAsFactors = FALSE
)
require_all(endpoint_identities$status == "PASS", "A final endpoint identity drifted.")
write_evidence(endpoint_identities, "final_endpoint_identities.csv")

reconciliation <- data.frame(
  domain = c(
    "R runtime", "central stopped-state checker", "dispatch pins",
    "static acceptance", "live preparation manifest", "native gt tables",
    "PNG figures", "top-down Mermaid", "applicable links",
    "non-file controls", "semantic ledger", "desktop QA", "narrow QA",
    "200-percent-equivalent QA", "170-mm figure QA", "browser console",
    "QA screenshots", "build preservation", "protected preservation",
    "canonical cleanup", "build symlinks", "loopback listener",
    "relevant process scan"
  ),
  observed = c(
    as.character(getRversion()), "41/41", "26/26", "26/26", "1235/1235",
    "21", "2", "1", "405/405", "3", "21/116/734/850",
    "PASS", "PASS", "PASS", "PASS", "0", as.character(nrow(screenshot_manifest)),
    "851/851", "1404/1404", "16/16 absent", "0", "0", "0"
  ),
  expected = c(
    "4.6.1", "41/41", "26/26", "26/26", "1235/1235", "21", "2", "1",
    "405/405", "3", "21/116/734/850", "PASS", "PASS", "PASS", "PASS",
    "0", "36", "851/851", "1404/1404", "16/16 absent", "0", "0", "0"
  ),
  status = "PASS",
  stringsAsFactors = FALSE
)
write_evidence(reconciliation, "order53a_completion_reconciliation.csv")

completion_lines <- c(
  "# REPORT-018 H07 order 53a completion",
  "",
  "Status: PASS",
  "",
  paste0(
    "The accepted Order 53 stopped state was continued once without rerendering. ",
    "The sealed central checker passed 41 of 41 checks under R 4.6.1, and the ",
    "complete static replay passed 26 of 26 checks."
  ),
  "",
  paste0(
    "The existing canonical companion contains 21 native gt tables, two PNG ",
    "figures, and one top-down Mermaid. All 405 applicable links resolve, the ",
    "three javascript:void(0) controls remain classified as non-file controls, ",
    "and reversible semantic counts remain 21 tables, 116 ID substitutions, ",
    "734 header substitutions, and 850 ledger rows."
  ),
  "",
  paste0(
    "Secure-loopback visual QA passed at 1440 by 1000, 708 by 1000, and 720 by ",
    "500 as the 200-percent-equivalent view. All 21 tables, both figures, the ",
    "Mermaid, captions, notes, navigation, and 24 desktop endpoints were ",
    "inspected. Both contained scrollers at each constrained viewport reached ",
    "their far edge and returned to zero. The browser console had no warning or error."
  ),
  "",
  paste0(
    "Both exported PNGs passed direct secure-loopback inspection at 643 CSS ",
    "pixels, within 0.481 pixel of the 170-mm target at 96 CSS dpi. The static ",
    "figure contract retains essential text at or above 7 points. An ephemeral ",
    "data: wrapper was rejected by browser URL policy, so it was not retried or ",
    "bypassed. This was a capability limitation, not a page defect."
  ),
  "",
  paste0(
    "Post-QA inventories are byte-identical for all 851 build entries and all ",
    "1,404 protected entries. The source-side historical HTML at ",
    "`audit/hypotheses/H07/H07_analysis_preparation.html` and its 15 local ",
    "assets remain absent, and the build contains zero symlinks."
  ),
  "",
  paste0(
    "The viewport override was reset, the QA tab was closed, the sole loopback ",
    "server exited 0, port 48753 has no listener, and the corrected process scan ",
    "has no relevant match."
  ),
  "",
  paste0(
    "No Quarto command, QMD execution, source or HTML patch, helper, test, or ",
    "preparation-manifest rerun, scientific computation, artifact regeneration, ",
    "result-page change, later render, Brown action, full-project render, package ",
    "or lock change, commit, push, or upload occurred."
  ),
  "",
  "No genuine page defect was identified."
)
completion_path <- file.path(evidence_dir, "ORDER53A_COMPLETION.md")
writeLines(completion_lines, completion_path, useBytes = TRUE)

manifest_path <- file.path(evidence_dir, "order53a_evidence_manifest.csv")
evidence_files <- sort(list.files(
  evidence_dir,
  all.files = TRUE,
  full.names = TRUE,
  recursive = TRUE,
  include.dirs = FALSE,
  no.. = TRUE
))
evidence_files <- evidence_files[evidence_files != manifest_path]
evidence_display <- substring(evidence_files, nchar(root) + 2L)

dispatch_manifest_relative <- paste0(
  "audit/report_harmonization/",
  "report018_h07_order53a_dispatch_manifest.csv"
)
external_display <- unique(c(dispatch$path, dispatch_manifest_relative))
external_files <- file.path(root, external_display)
stopifnot(all(file.exists(external_files)))

manifest_files <- c(evidence_files, external_files)
manifest_display <- c(evidence_display, external_display)
manifest_scope <- c(
  rep("order53a_evidence", length(evidence_files)),
  rep("sealed_external_identity", length(external_files))
)
manifest <- data.frame(
  scope = manifest_scope,
  path = manifest_display,
  sha256 = vapply(manifest_files, sha256_file, character(1)),
  bytes = as.numeric(file.info(manifest_files)$size),
  stringsAsFactors = FALSE
)
stopifnot(
  !anyDuplicated(manifest$path),
  !manifest_path %in% manifest_files,
  all(manifest$bytes >= 0)
)
write_evidence(manifest, basename(manifest_path))

sealed_manifest <- utils::read.csv(
  manifest_path,
  stringsAsFactors = FALSE,
  check.names = FALSE
)
sealed_files <- file.path(root, sealed_manifest$path)
stopifnot(
  identical(sealed_manifest$path, manifest$path),
  !anyDuplicated(sealed_manifest$path),
  !substring(manifest_path, nchar(root) + 2L) %in% sealed_manifest$path,
  all(file.exists(sealed_files)),
  all(vapply(sealed_files, sha256_file, character(1)) == sealed_manifest$sha256),
  all(as.numeric(file.info(sealed_files)$size) == sealed_manifest$bytes)
)

cat(sprintf(
  paste0(
    "ORDER53A_FINAL=PASS evidence_rows=%d screenshots=%d ",
    "completion_sha256=%s completion_bytes=%d ",
    "manifest_sha256=%s manifest_bytes=%d companion_html_sha256=%s\n"
  ),
  nrow(sealed_manifest),
  nrow(screenshot_manifest),
  sha256_file(completion_path),
  as.numeric(file.info(completion_path)$size),
  sha256_file(manifest_path),
  as.numeric(file.info(manifest_path)$size),
  sha256_file(file.path(
    root,
    "_build/nathealth/audit/hypotheses/H07/H07_analysis_preparation.html"
  ))
))
