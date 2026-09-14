#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE, warn = 2)

stopifnot(identical(as.character(getRversion()), "4.6.1"))

suppressPackageStartupMessages({
  library(digest)
  library(jsonlite)
  library(readr)
})

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
setwd(root)

evidence_relative <-
  "audit/hypotheses/H07/report018_order52_result_render"
evidence_dir <- file.path(root, evidence_relative)
semantic_dir <- normalizePath(
  Sys.getenv("GT_HTML_SEMANTIC_AUDIT_DIR"),
  winslash = "/",
  mustWork = TRUE
)
html_relative <- "_build/nathealth/notebooks/hypotheses/H07.html"
html_path <- file.path(root, html_relative)

stopifnot(dir.exists(evidence_dir), dir.exists(semantic_dir), file.exists(html_path))

sha256_file <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
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

read_evidence <- function(name) {
  readr::read_csv(file.path(evidence_dir, name), show_col_types = FALSE)
}

inventory_identity <- function(pre_name, post_name, domain) {
  pre_path <- file.path(evidence_dir, pre_name)
  post_path <- file.path(evidence_dir, post_name)
  pre <- read_evidence(pre_name)
  post <- read_evidence(post_name)
  fields <- c(
    "relative_path", "role", "sha256", "bytes", "modified_utc",
    "is_symlink", "symlink_target"
  )
  stopifnot(identical(names(pre), names(post)), all(fields %in% names(pre)))
  pre <- pre[order(pre$relative_path), fields, drop = FALSE]
  post <- post[order(post$relative_path), fields, drop = FALSE]
  same_rows <- identical(pre, post)
  same_bytes <- identical(readBin(pre_path, "raw", n = file.info(pre_path)$size),
                          readBin(post_path, "raw", n = file.info(post_path)$size))
  data.frame(
    domain = domain,
    postrender_rows = nrow(pre),
    postqa_rows = nrow(post),
    row_identity = same_rows,
    csv_byte_identity = same_bytes,
    postrender_sha256 = sha256_file(pre_path),
    postqa_sha256 = sha256_file(post_path),
    status = ifelse(same_rows && same_bytes, "PASS", "FAIL"),
    stringsAsFactors = FALSE
  )
}

postqa_reconciliation <- rbind(
  inventory_identity(
    "build_inventory_postrender.csv",
    "build_inventory_postqa.csv",
    "complete build inventory"
  ),
  inventory_identity(
    "protected_inventory_postrender.csv",
    "protected_inventory_postqa.csv",
    "complete protected inventory"
  )
)
stopifnot(all(postqa_reconciliation$status == "PASS"))
write_evidence(postqa_reconciliation, "postqa_rehash_reconciliation.csv")

source_pins <- data.frame(
  path = c(
    "notebooks/hypotheses/H07.qmd",
    "audit/hypotheses/H07/H07_analysis_preparation.qmd",
    "_build/nathealth/audit/hypotheses/H07/H07_analysis_preparation.html",
    "_quarto-nathealth.yml",
    "scripts/report_harmonization/post_render_gt_html_semantics.R",
    "scripts/report_harmonization/repair_gt_html_semantics.R",
    "tests/hypotheses/H07/test_h07_stage3_reader_report.R",
    "tests/hypotheses/H07/test_h07_preparation_report.R",
    "artifacts/08_figures/H07/H07_revised_smooth_derivative_pairs_near_eye.png",
    "artifacts/08_figures/H07/H07_revised_smooth_derivative_pairs_chest.png",
    "audit/report_harmonization/phase4_corpus_manifest.csv",
    "renv.lock"
  ),
  expected_sha256 = c(
    "c779c57ffc64a15c82e519ef38e865a39108a6563d82e408e4522253c61e8226",
    "a6c05e81333bb612e99ef431f42f47860ac26b6d5c0f0f44ecbce019ee470d1b",
    "53c261b88b5d10238e18e33323ad705c61c92215c040fc84880385cdc434fd2f",
    "80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3",
    "28c1105840834e95a37f84eaded9a2c595b9febd568fbc763daef247a53d7205",
    "7c949930fec862a4ce783c28d0256d36cb45de7c017bd9fcbb7cb910599463d1",
    "84e96a523bf1d9051be8abe3cabbef9837dfe98ab978a30bd846d0f2d728cd17",
    "89fd3eaa2f4f9928234280844e480ff5b863e104366af17675fe36366c456558",
    "f19763fe3c14c723ac38846bf735c0465ba2ee18765777a4f7304c677be71113",
    "2a714e192bd5c266d03c6f74bdabae9424f5a3663940f0bc3ae5a9ae4e066cd5",
    "73f1a371f8352f1baf69d38f1613de1a662112642370b0cc89798b4d6d469334",
    "3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350"
  ),
  stringsAsFactors = FALSE
)
source_pins$observed_sha256 <- vapply(
  file.path(root, source_pins$path),
  sha256_file,
  character(1)
)
source_pins$bytes <- as.numeric(file.info(file.path(root, source_pins$path))$size)
source_pins$status <- ifelse(
  source_pins$observed_sha256 == source_pins$expected_sha256,
  "PASS",
  "FAIL"
)
stopifnot(all(source_pins$status == "PASS"))
write_evidence(source_pins, "final_source_freeze_audit.csv")

order_path <- file.path(
  root,
  "audit/report_harmonization/owner_orders/52_h07_result_report018_render.md"
)
dispatch_path <- file.path(
  root,
  "audit/report_harmonization/report018_h07_result_order52_dispatch_manifest.csv"
)
authority <- data.frame(
  path = c(
    "audit/report_harmonization/owner_orders/52_h07_result_report018_render.md",
    "audit/report_harmonization/report018_h07_result_order52_dispatch_manifest.csv"
  ),
  expected_sha256 = c(
    "9c7977f93dd3425b10dfe5831836ace779df3d1e505358789df1046972ebfd19",
    "b981c8ef99e7e881ad35ceac13f1963a27fa0fa2b58c66bea9e703b13389456e"
  ),
  expected_bytes = c(9513, 5255),
  stringsAsFactors = FALSE
)
authority$observed_sha256 <- vapply(
  file.path(root, authority$path),
  sha256_file,
  character(1)
)
authority$observed_bytes <- as.numeric(file.info(file.path(root, authority$path))$size)
authority$status <- ifelse(
  authority$expected_sha256 == authority$observed_sha256 &
    authority$expected_bytes == authority$observed_bytes,
  "PASS",
  "FAIL"
)
stopifnot(all(authority$status == "PASS"))
write_evidence(authority, "authority_identity_audit.csv")

semantic_summary_path <- file.path(
  semantic_dir,
  "gt_html_semantic_post_render_summary.csv"
)
semantic_summary <- readr::read_csv(
  semantic_summary_path,
  show_col_types = FALSE
)
stopifnot(
  nrow(semantic_summary) == 1L,
  semantic_summary$target == html_relative,
  semantic_summary$disposition == "REPAIRED",
  semantic_summary$table_count == 11L,
  semantic_summary$post_sha256 == sha256_file(html_path)
)
ledger_path <- file.path(semantic_dir, semantic_summary$ledger_file)
semantic_files <- sort(c(semantic_summary_path, ledger_path))
stopifnot(length(semantic_files) == 2L, all(file.exists(semantic_files)))
semantic_external <- data.frame(
  path = semantic_files,
  sha256 = vapply(semantic_files, sha256_file, character(1)),
  bytes = as.numeric(file.info(semantic_files)$size),
  copied_evidence_path = file.path(
    evidence_relative,
    basename(semantic_files)
  ),
  stringsAsFactors = FALSE
)
semantic_external$copy_sha256 <- vapply(
  file.path(evidence_dir, basename(semantic_files)),
  sha256_file,
  character(1)
)
semantic_external$status <- ifelse(
  semantic_external$sha256 == semantic_external$copy_sha256,
  "PASS",
  "FAIL"
)
stopifnot(all(semantic_external$status == "PASS"))
write_evidence(semantic_external, "external_semantic_evidence_audit.csv")

dispatch <- readr::read_csv(dispatch_path, show_col_types = FALSE)
matrix_relative <- "audit/report_harmonization/coordination_matrix.csv"
preserved <- dispatch[
  !dispatch$path %in% c(matrix_relative, html_relative),
  ,
  drop = FALSE
]
preserved$observed_sha256 <- vapply(
  file.path(root, preserved$path),
  sha256_file,
  character(1)
)
preserved$observed_bytes <- as.numeric(file.info(file.path(root, preserved$path))$size)
preserved$status <- ifelse(
  preserved$sha256 == preserved$observed_sha256 &
    preserved$bytes == preserved$observed_bytes,
  "PASS",
  "FAIL"
)
stopifnot(nrow(dispatch) == 35L, nrow(preserved) == 33L, all(preserved$status == "PASS"))
write_evidence(preserved, "dispatch_preservation_postqa.csv")

browser_path <- file.path(evidence_dir, "browser_qa_measurements.json")
browser <- jsonlite::fromJSON(browser_path, simplifyVector = FALSE)
console_events <- jsonlite::fromJSON(
  file.path(evidence_dir, "browser_console_warn_error.json"),
  simplifyVector = FALSE
)

desktop <- browser$desktop
narrow <- browser$narrow
zoom <- browser$zoom200Equivalent
narrow_figure_width <- narrow$figures[[1L]]$imageRect$width
narrow_width_mm <- narrow_figure_width / 96 * 25.4
visual_qa <- data.frame(
  view = c("desktop", "narrow 170 mm", "200 percent equivalent"),
  viewport = c("1440 x 1000", "708 x 1000", "720 x 500"),
  table_count = c(
    length(desktop$tables),
    length(narrow$tables),
    length(zoom$tables)
  ),
  figure_count = c(
    length(desktop$figures),
    length(narrow$figures),
    length(zoom$figures)
  ),
  page_overflow = c(
    desktop$document$pageOverflow,
    narrow$document$pageOverflow,
    zoom$document$overflow != 0
  ),
  contained_scrollers = c(
    sum(vapply(desktop$tables, function(x) isTRUE(x$hasScroller), logical(1))),
    sum(vapply(narrow$tables, function(x) isTRUE(x$hasScroller), logical(1))),
    sum(vapply(zoom$tables, function(x) isTRUE(x$containedOverflow), logical(1)))
  ),
  figure_display_width_px = c(
    desktop$figures[[1L]]$imageRect$width,
    narrow_figure_width,
    zoom$figures[[1L]]$displayWidth
  ),
  figure_display_width_mm_at_96_css_dpi = c(
    desktop$figures[[1L]]$imageRect$width / 96 * 25.4,
    narrow_width_mm,
    zoom$figures[[1L]]$displayWidth / 96 * 25.4
  ),
  visual_review = c(
    browser$manualReview$desktop,
    browser$manualReview$narrow170mm,
    browser$manualReview$zoom200Equivalent
  ),
  status = "PASS",
  stringsAsFactors = FALSE
)
stopifnot(
  all(visual_qa$table_count == 11L),
  all(visual_qa$figure_count == 2L),
  !any(visual_qa$page_overflow),
  visual_qa$contained_scrollers[[1L]] == 0L,
  visual_qa$contained_scrollers[[2L]] == 1L,
  visual_qa$contained_scrollers[[3L]] == 1L,
  abs(narrow_width_mm - 170) < 0.2,
  browser$narrowScroller$right$documentOverflow == 0,
  browser$narrowScroller$right$scrollLeft >=
    browser$narrowScroller$right$max - 1,
  browser$narrowScroller$reset$scrollLeft == 0,
  browser$zoom200EquivalentScroller$right$documentOverflow == 0,
  browser$zoom200EquivalentScroller$right$scrollLeft >=
    browser$zoom200EquivalentScroller$right$max - 1,
  browser$zoom200EquivalentScroller$reset$scrollLeft == 0,
  length(console_events) == 0L
)
write_evidence(visual_qa, "visual_qa_status.csv")

screenshot_paths <- sort(list.files(
  evidence_dir,
  pattern = "^visual_.*[.]png$",
  full.names = TRUE
))
screenshot_manifest <- data.frame(
  file = basename(screenshot_paths),
  viewport_group = ifelse(
    startsWith(basename(screenshot_paths), "visual_1440x1000_"),
    "1440 x 1000",
    ifelse(
      startsWith(basename(screenshot_paths), "visual_708x1000_"),
      "708 x 1000",
      "720 x 500"
    )
  ),
  sha256 = vapply(screenshot_paths, sha256_file, character(1)),
  bytes = as.numeric(file.info(screenshot_paths)$size),
  manual_inspection = "PASS",
  stringsAsFactors = FALSE
)
stopifnot(
  nrow(screenshot_manifest) == 52L,
  all(screenshot_manifest$bytes > 0),
  !anyDuplicated(screenshot_manifest$file),
  identical(
    as.integer(table(screenshot_manifest$viewport_group)[c(
      "1440 x 1000", "708 x 1000", "720 x 500"
    )]),
    c(11L, 18L, 23L)
  )
)
write_evidence(screenshot_manifest, "visual_screenshot_manifest.csv")

reader_contract <- read_evidence("reader_contract_audit.csv")
reader_test <- read_evidence("reader_test_audit.csv")
held_test <- read_evidence("held_preparation_test_audit.csv")
nonvisual <- read_evidence("nonvisual_status.csv")
stopifnot(
  all(reader_contract$status == "PASS"),
  all(reader_test$status == "PASS"),
  all(held_test$status == "PASS"),
  !held_test$executed,
  all(nonvisual$status == "PASS")
)

render_execution <- data.frame(
  order = "REPORT-018 H07 order 52",
  attempts = 1L,
  command = paste0(
    "GT_HTML_SEMANTIC_AUDIT_DIR=", semantic_dir,
    " quarto render notebooks/hypotheses/H07.qmd --profile nathealth"
  ),
  exit_status = 0L,
  r_version = as.character(getRversion()),
  quarto_version = read_evidence("versions_prerender.csv")$version[[2L]],
  result_html = html_relative,
  result_html_sha256 = sha256_file(html_path),
  result_html_bytes = as.numeric(file.info(html_path)$size),
  semantic_disposition = semantic_summary$disposition,
  semantic_substitutions = semantic_summary$total_substitutions,
  native_gt_tables = 11L,
  figures = 2L,
  rerendered = FALSE,
  status = "PASS",
  stringsAsFactors = FALSE
)
stopifnot(
  render_execution$result_html_sha256 == semantic_summary$post_sha256,
  render_execution$quarto_version == "1.9.37"
)
write_evidence(render_execution, "render_execution.csv")

render_console <- data.frame(
  item = c(
    "render exit",
    "renv dependency-discovery timing note",
    "embedded error warning stderr cross-reference or raw trace"
  ),
  classification = c(
    "exit 0",
    "advisory only",
    "absent"
  ),
  details = c(
    "The sole authorized render completed without retry.",
    "The console emitted only the renv snapshot dependency-discovery timing note; it did not indicate a render or scientific failure.",
    "Fresh-page structural checks found none."
  ),
  status = "PASS",
  stringsAsFactors = FALSE
)
write_evidence(render_console, "render_console_classification.csv")

lsof_path <- Sys.which("lsof")
listener_output <- suppressWarnings(system2(
  lsof_path,
  c("-nP", "-iTCP:43871", "-sTCP:LISTEN"),
  stdout = TRUE,
  stderr = TRUE
))
listener_status <- attr(listener_output, "status")
if (is.null(listener_status)) listener_status <- 0L
loopback <- data.frame(
  event = c(
    "port preflight",
    "server bind",
    "reader route",
    "favicon request",
    "browser console",
    "viewport reset",
    "QA tab close",
    "server stop",
    "listener postflight"
  ),
  observed = c(
    "43871 unused before server start",
    "127.0.0.1:43871 only",
    "/notebooks/hypotheses/H07.html returned 200",
    "/favicon.ico returned 404",
    "zero warnings or errors",
    "restored to 1280 x 720 at device pixel ratio 2",
    "closed; QA browser session has zero remaining tabs",
    "keyboard interrupt; server exited 0",
    sprintf("lsof exit %d with no listener", listener_status)
  ),
  classification = c(
    "PASS", "PASS", "PASS", "non-report asset advisory", "PASS",
    "PASS", "PASS", "PASS", "PASS"
  ),
  stringsAsFactors = FALSE
)
stopifnot(listener_status == 1L, length(listener_output) == 0L)
write_evidence(loopback, "loopback_lifecycle.csv")

completion_lines <- c(
  "# REPORT-018 H07 order 52 completion",
  "",
  "Status: PASS",
  "",
  paste0(
    "The sole authorized result render completed once with exit 0 under R ",
    "4.6.1 and Quarto 1.9.37. No retry, source patch, companion render, ",
    "scientific recomputation, full-project render, commit, push, or upload occurred."
  ),
  "",
  paste0(
    "The fresh H07 result contains 11 native gt tables and two accepted ",
    "figure resources. Semantic disposition was REPAIRED with exact reverse ",
    "and forward proof and no visible or structural change across the hook."
  ),
  "",
  paste0(
    "The unchanged result reader test passed. The held preparation test ",
    "remained byte-identical and was not executed."
  ),
  "",
  paste0(
    "Desktop, narrow 170 mm, and 200 percent equivalent visual QA passed. ",
    "The one contained diagnostic-table scroller was exercised and reset, ",
    "with no page-level overflow."
  ),
  "",
  paste0(
    "Post-QA build and protected inventories are byte-identical to their ",
    "postrender inventories. The secure-loopback server is stopped, no ",
    "listener remains, the viewport override is reset, and the QA tab is closed."
  ),
  "",
  paste0("External semantic evidence retained at: `", semantic_dir, "`"),
  "",
  "The companion render and every later REPORT-018 target remain held."
)
writeLines(
  completion_lines,
  file.path(evidence_dir, "ORDER52_COMPLETION.md"),
  useBytes = TRUE
)

manifest_path <- file.path(evidence_dir, "order52_evidence_manifest.csv")
evidence_files <- sort(list.files(
  evidence_dir,
  all.files = TRUE,
  full.names = TRUE,
  recursive = TRUE,
  include.dirs = FALSE,
  no.. = TRUE
))
evidence_files <- evidence_files[evidence_files != manifest_path]
manifest_files <- c(evidence_files, semantic_files)
manifest_scope <- c(
  rep("project_order52_evidence", length(evidence_files)),
  rep("external_semantic_evidence", length(semantic_files))
)
manifest_display <- c(
  file.path(evidence_relative, basename(evidence_files)),
  semantic_files
)
manifest <- data.frame(
  scope = manifest_scope,
  path = manifest_display,
  sha256 = vapply(manifest_files, sha256_file, character(1)),
  bytes = as.numeric(file.info(manifest_files)$size),
  stringsAsFactors = FALSE
)
stopifnot(
  length(manifest_files) == length(unique(manifest_display)),
  !manifest_path %in% manifest_files,
  all(manifest$bytes >= 0)
)
write_evidence(manifest, basename(manifest_path))

cat(sprintf(
  paste0(
    "ORDER52_FINAL=PASS evidence_rows=%d screenshots=%d html_sha256=%s ",
    "semantic_dir=%s\n"
  ),
  nrow(manifest),
  nrow(screenshot_manifest),
  sha256_file(html_path),
  semantic_dir
))
