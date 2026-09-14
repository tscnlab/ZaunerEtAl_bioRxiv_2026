#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) == 4L)
root <- normalizePath(args[[1L]], winslash = "/", mustWork = TRUE)
pre_dir <- normalizePath(args[[2L]], winslash = "/", mustWork = TRUE)
semantic_dir <- normalizePath(args[[3L]], winslash = "/", mustWork = TRUE)
out_dir <- normalizePath(args[[4L]], winslash = "/", mustWork = TRUE)
stopifnot(identical(as.character(getRversion()), "4.6.1"))

suppressPackageStartupMessages({
  library(data.table)
  library(digest)
  library(xml2)
})

sha256_file <- function(path) {
  digest::digest(file = path, algo = "sha256", serialize = FALSE)
}

sha256_raw <- function(value) {
  digest::digest(value, algo = "sha256", serialize = FALSE)
}

live_table <- function(relative) {
  absolute <- file.path(root, relative)
  exists <- file.exists(absolute)
  sha256 <- rep(NA_character_, length(relative))
  bytes <- rep(NA_real_, length(relative))
  sha256[exists] <- unname(vapply(
    absolute[exists],
    sha256_file,
    character(1)
  ))
  bytes[exists] <- as.numeric(file.info(absolute[exists])$size)
  data.table(
    path = relative,
    exists = exists,
    sha256 = sha256,
    bytes = bytes
  )
}

inventory_files <- function(base) {
  entries <- list.files(
    base,
    all.files = TRUE,
    recursive = TRUE,
    full.names = TRUE,
    include.dirs = TRUE,
    no.. = TRUE
  )
  files <- sort(entries[file.exists(entries) & !dir.exists(entries)])
  data.table(
    path = substring(files, nchar(root) + 2L),
    sha256 = unname(vapply(files, sha256_file, character(1))),
    bytes = as.numeric(file.info(files)$size),
    mtime = as.numeric(file.info(files)$mtime)
  )
}

replace_raw_ranges <- function(
    bytes,
    ledger,
    start_column,
    end_column,
    from_column,
    to_column) {
  starts <- as.numeric(ledger[[start_column]])
  ends <- as.numeric(ledger[[end_column]])
  for (index in order(starts, decreasing = TRUE)) {
    start <- starts[[index]]
    end <- ends[[index]]
    expected <- charToRaw(as.character(ledger[[from_column]][[index]]))
    observed <- bytes[start:end]
    stopifnot(identical(observed, expected))
    before <- if (start > 1L) bytes[seq_len(start - 1L)] else raw()
    after <- if (end < length(bytes)) bytes[(end + 1L):length(bytes)] else raw()
    replacement <- charToRaw(as.character(ledger[[to_column]][[index]]))
    bytes <- c(before, replacement, after)
  }
  bytes
}

png_dimensions <- function(path) {
  header <- readBin(path, what = "raw", n = 24L)
  signature <- as.raw(c(137, 80, 78, 71, 13, 10, 26, 10))
  stopifnot(length(header) == 24L, identical(header[1:8], signature))
  decode_u32 <- function(value) {
    sum(as.numeric(as.integer(value)) * 256^(3:0))
  }
  c(width = decode_u32(header[17:20]), height = decode_u32(header[21:24]))
}

check_rows <- list()
add_check <- function(name, passed, detail) {
  check_rows[[length(check_rows) + 1L]] <<- data.table(
    check = name,
    status = if (isTRUE(passed)) "PASS" else "FAIL",
    detail = as.character(detail)
  )
}

manifest_relative <- paste0(
  "artifacts/12_manifests/H06/",
  "H06_preparation_report_manifest.csv"
)
manifest <- fread(file.path(root, manifest_relative))
manifest_live <- live_table(manifest$path)
manifest_check <- cbind(manifest, manifest_live[, .(
  live_exists = exists,
  live_sha256 = sha256,
  live_bytes = bytes
)])
manifest_check[, exact := live_exists &
  sha256 == live_sha256 &
  as.numeric(bytes) == as.numeric(live_bytes)]
fwrite(manifest_check, file.path(out_dir, "manifest_live_post.csv"))
add_check(
  "preparation_manifest",
  nrow(manifest) == 411L &&
    !anyDuplicated(manifest$path) &&
    !manifest_relative %in% manifest$path &&
    all(manifest_check$exact),
  sprintf(
    "%d rows; %d duplicate paths; %d live mismatches; self row %s",
    nrow(manifest),
    anyDuplicated(manifest$path),
    sum(!manifest_check$exact),
    manifest_relative %in% manifest$path
  )
)

authoring_relative <- "audit/hypotheses/H06/H06_analysis_preparation.qmd"
website_qmd_relative <- paste0(
  "_build/nathealth/audit/hypotheses/H06/",
  "H06_analysis_preparation.qmd"
)
authoring_raw <- readBin(file.path(root, authoring_relative), "raw", n = 1e8)
website_qmd_raw <- readBin(file.path(root, website_qmd_relative), "raw", n = 1e8)
add_check(
  "website_qmd_copy",
  identical(authoring_raw, website_qmd_raw) &&
    sha256_raw(authoring_raw) ==
      "f952d5ec72066ee86fded4888aaa815bdf763c11f466806ebc7391c79e22918b",
  paste0(
    "authoring=", sha256_raw(authoring_raw),
    "; website=", sha256_raw(website_qmd_raw)
  )
)

html_relative <- paste0(
  "_build/nathealth/audit/hypotheses/H06/",
  "H06_analysis_preparation.html"
)
html_path <- file.path(root, html_relative)
summary_path <- file.path(
  semantic_dir,
  "gt_html_semantic_post_render_summary.csv"
)
ledger_path <- list.files(
  semantic_dir,
  pattern = "_gt_semantic_ledger[.]csv$",
  full.names = TRUE
)
stopifnot(length(ledger_path) == 1L)
semantic_summary <- fread(summary_path)
ledger <- fread(ledger_path)
html_raw <- readBin(html_path, "raw", n = file.info(html_path)$size)
reversed_raw <- replace_raw_ranges(
  html_raw,
  ledger,
  "post_value_start_byte",
  "post_value_end_byte",
  "post_value",
  "pre_value"
)
reapplied_raw <- replace_raw_ranges(
  reversed_raw,
  ledger,
  "pre_value_start_byte",
  "pre_value_end_byte",
  "pre_value",
  "post_value"
)
semantic_reversal <- data.table(
  item = c("pre_hook_reconstruction", "post_hook_reapplication"),
  expected_sha256 = c(
    semantic_summary$pre_sha256[[1L]],
    semantic_summary$post_sha256[[1L]]
  ),
  observed_sha256 = c(sha256_raw(reversed_raw), sha256_raw(reapplied_raw))
)
semantic_reversal[, exact := expected_sha256 == observed_sha256]
fwrite(semantic_reversal, file.path(out_dir, "semantic_reversal.csv"))
add_check(
  "semantic_ledger",
  nrow(semantic_summary) == 1L &&
    semantic_summary$disposition[[1L]] == "REPAIRED" &&
    nrow(ledger) == semantic_summary$total_substitutions[[1L]] &&
    all(semantic_reversal$exact) &&
    sha256_file(html_path) == semantic_summary$post_sha256[[1L]],
  sprintf(
    "%s; %d substitutions; reverse=%s; reapply=%s",
    semantic_summary$disposition[[1L]],
    nrow(ledger),
    semantic_reversal$exact[[1L]],
    semantic_reversal$exact[[2L]]
  )
)

doc <- read_html(html_path)
all_id_nodes <- xml_find_all(doc, "//*[@id]")
all_ids <- xml_attr(all_id_nodes, "id")
gt_tables <- xml_find_all(
  doc,
  "//table[contains(concat(' ', normalize-space(@class), ' '), ' gt_table ')]"
)
headers_diagnostic <- rbindlist(lapply(seq_along(gt_tables), function(index) {
  table <- gt_tables[[index]]
  endpoints <- xml_attr(
    xml_find_all(table, "ancestor::*[starts-with(@id, 'tbl-h06-prep-')]"),
    "id"
  )
  endpoint <- if (length(endpoints)) endpoints[[length(endpoints)]] else NA_character_
  th_ids <- xml_attr(xml_find_all(table, ".//th[@id]"), "id")
  header_nodes <- xml_find_all(table, ".//*[@headers]")
  tokens <- unlist(strsplit(xml_attr(header_nodes, "headers"), "[[:space:]]+"))
  tokens <- tokens[nzchar(tokens)]
  counts <- if (length(tokens)) vapply(tokens, function(token) {
    sum(th_ids == token)
  }, integer(1)) else integer()
  data.table(
    table_index = index,
    endpoint = endpoint,
    th_id_count = length(th_ids),
    headers_token_count = length(tokens),
    unresolved = sum(counts == 0L),
    ambiguous = sum(counts > 1L)
  )
}))
fwrite(headers_diagnostic, file.path(out_dir, "semantic_table_diagnostic.csv"))
add_check(
  "document_ids_and_table_headers",
  length(gt_tables) == 30L &&
    !anyDuplicated(all_ids) &&
    all(!is.na(headers_diagnostic$endpoint)) &&
    !anyDuplicated(headers_diagnostic$endpoint) &&
    sum(headers_diagnostic$unresolved) == 0L &&
    sum(headers_diagnostic$ambiguous) == 0L,
  sprintf(
    "%d gt tables; %d ids/%d unique; %d header tokens; %d unresolved; %d ambiguous",
    length(gt_tables),
    length(all_ids),
    uniqueN(all_ids),
    sum(headers_diagnostic$headers_token_count),
    sum(headers_diagnostic$unresolved),
    sum(headers_diagnostic$ambiguous)
  )
)

qmd_lines <- readLines(
  file.path(root, authoring_relative),
  warn = FALSE,
  encoding = "UTF-8"
)
chunk_labels <- sub(
  "^#\\| label:[[:space:]]*",
  "",
  grep("^#\\| label:[[:space:]]*", qmd_lines, value = TRUE)
)
table_labels <- chunk_labels[startsWith(chunk_labels, "tbl-h06-prep-")]
figure_labels <- chunk_labels[startsWith(chunk_labels, "fig-h06-prep-")]
table_endpoints <- headers_diagnostic$endpoint
figure_nodes <- xml_find_all(
  doc,
  "//*[@id and starts-with(@id, 'fig-h06-prep-') and not(contains(@id, '-caption-'))]"
)
figure_endpoints <- xml_attr(figure_nodes, "id")
table_caption_rows <- rbindlist(lapply(table_labels, function(label) {
  node <- xml_find_first(doc, sprintf("//*[@id='%s']", label))
  table <- xml_find_first(node, ".//table[contains(concat(' ', normalize-space(@class), ' '), ' gt_table ')]")
  caption <- xml_text(
    xml_find_first(
      node,
      ".//*[contains(concat(' ', normalize-space(@class), ' '), ' quarto-float-caption ')]"
    ),
    trim = TRUE
  )
  source_notes <- xml_find_all(table, ".//*[contains(concat(' ', normalize-space(@class), ' '), ' gt_sourcenotes ')]")
  data.table(
    endpoint = label,
    caption = caption,
    source_note_count = length(source_notes),
    source_note_text = paste(xml_text(source_notes, trim = TRUE), collapse = " | "),
    row_count = length(xml_find_all(table, ".//tbody/tr")),
    column_count = length(xml_find_all(table, ".//thead/tr[last()]/th"))
  )
}))
figure_caption_rows <- rbindlist(lapply(figure_labels, function(label) {
  node <- xml_find_first(doc, sprintf("//*[@id='%s']", label))
  figcaption <- xml_text(xml_find_first(node, ".//figcaption"), trim = TRUE)
  image <- xml_find_first(node, ".//img")
  data.table(
    endpoint = label,
    caption = figcaption,
    alt = xml_attr(image, "alt"),
    src = xml_attr(image, "src")
  )
}))
fwrite(table_caption_rows, file.path(out_dir, "table_display_inventory.csv"))
fwrite(figure_caption_rows, file.path(out_dir, "figure_display_inventory.csv"))
mermaid_source_count <- sum(grepl("flowchart TD", qmd_lines, fixed = TRUE))
mermaid_html_count <- length(xml_find_all(
  doc,
  "//*[contains(concat(' ', normalize-space(@class), ' '), ' mermaid ')]"
))
add_check(
  "ordered_endpoints",
  identical(table_labels, table_endpoints) &&
    identical(figure_labels, figure_endpoints) &&
    length(table_labels) == 30L &&
    length(figure_labels) == 3L &&
    mermaid_source_count == 1L &&
    mermaid_html_count == 1L &&
    all(nzchar(table_caption_rows$caption)) &&
    all(nzchar(figure_caption_rows$caption)) &&
    all(!is.na(figure_caption_rows$alt) & nzchar(figure_caption_rows$alt)),
  sprintf(
    "%d ordered table endpoints; %d ordered figure endpoints; Mermaid source/html %d/%d",
    length(table_labels),
    length(figure_labels),
    mermaid_source_count,
    mermaid_html_count
  )
)

href_nodes <- xml_find_all(doc, "//a[@href]")
hrefs <- unique(xml_attr(href_nodes, "href"))
build_root <- file.path(root, "_build/nathealth")
html_dir <- dirname(html_path)
target_id_cache <- new.env(parent = emptyenv())
link_rows <- lapply(hrefs, function(href) {
  no_query <- sub("[?].*$", "", href)
  path_part <- sub("#.*$", "", no_query)
  fragment <- if (grepl("#", no_query, fixed = TRUE)) {
    sub("^[^#]*#", "", no_query)
  } else {
    ""
  }
  external <- grepl("^[A-Za-z][A-Za-z0-9+.-]*:", href)
  if (external) {
    return(data.table(
      href = href,
      class = "external",
      target = NA_character_,
      target_exists = NA,
      fragment = fragment,
      fragment_count = NA_integer_
    ))
  }
  target <- if (!nzchar(path_part)) {
    html_path
  } else if (startsWith(path_part, "/")) {
    file.path(build_root, URLdecode(sub("^/+", "", path_part)))
  } else {
    file.path(html_dir, URLdecode(path_part))
  }
  target <- normalizePath(target, winslash = "/", mustWork = FALSE)
  target_exists <- file.exists(target)
  fragment_count <- NA_integer_
  if (target_exists && nzchar(fragment) && grepl("[.]html$", target)) {
    if (!exists(target, envir = target_id_cache, inherits = FALSE)) {
      target_doc <- read_html(target)
      assign(
        target,
        xml_attr(xml_find_all(target_doc, "//*[@id]"), "id"),
        envir = target_id_cache
      )
    }
    target_ids <- get(target, envir = target_id_cache, inherits = FALSE)
    fragment_count <- sum(target_ids == URLdecode(fragment))
  }
  data.table(
    href = href,
    class = "internal",
    target = substring(target, nchar(root) + 2L),
    target_exists = target_exists,
    fragment = fragment,
    fragment_count = fragment_count
  )
})
link_diagnostic <- rbindlist(link_rows, fill = TRUE)
link_diagnostic[, forbidden := grepl(
  "file:|/Users/|_build/|/private/tmp/",
  href,
  perl = TRUE
)]
fwrite(link_diagnostic, file.path(out_dir, "link_diagnostic.csv"))
internal <- link_diagnostic[class == "internal"]
fragment_rows <- internal[nzchar(fragment) & target_exists]
missing_target_count <- internal[target_exists == FALSE, .N]
invalid_fragment_count <- fragment_rows[fragment_count != 1L, .N]
add_check(
  "internal_links",
  missing_target_count == 0L &&
    invalid_fragment_count == 0L &&
    sum(link_diagnostic$forbidden) == 0L,
  sprintf(
    "%d unique hrefs; %d internal; %d missing targets; %d invalid fragments; %d forbidden",
    nrow(link_diagnostic),
    nrow(internal),
    missing_target_count,
    invalid_fragment_count,
    sum(link_diagnostic$forbidden)
  )
)

result_html_relative <- "_build/nathealth/notebooks/hypotheses/H06.html"
result_doc <- read_html(file.path(root, result_html_relative))
result_hrefs <- unique(xml_attr(xml_find_all(result_doc, "//a[@href]"), "href"))
companion_to_result <- sum(grepl(
  "notebooks/hypotheses/H06[.]html(?:#.*)?$",
  hrefs,
  perl = TRUE
))
result_to_companion <- sum(grepl(
  "audit/hypotheses/H06/H06_analysis_preparation[.]html(?:#.*)?$",
  result_hrefs,
  perl = TRUE
))
dev_ids <- c("dev-015", "dev-030", "dev-031", "dev-032")
dev_rows <- rbindlist(lapply(dev_ids, function(dev) {
  rows <- link_diagnostic[fragment == dev]
  data.table(
    deviation = toupper(dev),
    link_count = nrow(rows),
    target_exists = nrow(rows) == 1L && isTRUE(rows$target_exists[[1L]]),
    fragment_count = if (nrow(rows) == 1L) rows$fragment_count[[1L]] else NA_integer_
  )
}))
fwrite(dev_rows, file.path(out_dir, "deviation_link_diagnostic.csv"))
active_navigation <- length(xml_find_all(
  doc,
  "//a[contains(concat(' ', normalize-space(@class), ' '), ' active ') and contains(normalize-space(.), 'H06 preparation and provenance')]"
)) == 1L
page_text <- xml_text(doc)
site_labels <- c(
  "Borås (SE)", "Delft (NL)", "Dortmund (DE)", "Tübingen (DE)",
  "Munich (DE)", "Madrid (ES)", "Izmir (TR)", "San José (CR)",
  "Kumasi (GH)"
)
site_present <- vapply(site_labels, grepl, logical(1), x = page_text, fixed = TRUE)
add_check(
  "reciprocal_deviation_navigation_site_links",
  companion_to_result >= 1L &&
    result_to_companion >= 1L &&
    all(dev_rows$link_count == 1L) &&
    all(dev_rows$target_exists) &&
    all(dev_rows$fragment_count == 1L) &&
    active_navigation &&
    all(site_present),
  sprintf(
    "companion-to-result=%d; result-to-companion=%d; DEV exact=%s; active nav=%s; sites=%d/9",
    companion_to_result,
    result_to_companion,
    all(dev_rows$fragment_count == 1L),
    active_navigation,
    sum(site_present)
  )
)

error_nodes <- xml_find_all(
  doc,
  "//*[contains(@class, 'cell-output-error') or contains(@class, 'cell-output-warning') or contains(@class, 'cell-output-stderr')]"
)
html_text_raw <- paste(readLines(html_path, warn = FALSE), collapse = "\n")
unresolved_patterns <- c(
  "ERROR:", "Execution halted", "cell-output-error", "cell-output-stderr",
  "\\?@(?:tbl|fig|sec)-", "file://", "/Users/zauner/", "/private/tmp/"
)
pattern_hits <- vapply(
  unresolved_patterns,
  function(pattern) grepl(pattern, html_text_raw, perl = TRUE),
  logical(1)
)
fwrite(
  data.table(pattern = unresolved_patterns, present = pattern_hits),
  file.path(out_dir, "embedded_diagnostic.csv")
)
add_check(
  "embedded_execution_and_paths",
  length(error_nodes) == 0L && !any(pattern_hits),
  sprintf(
    "%d error/warning/stderr nodes; %d forbidden or unresolved pattern hits",
    length(error_nodes),
    sum(pattern_hits)
  )
)

qa_relative <- paste0(
  "artifacts/12_manifests/H06/",
  "H06_preparation_figure_readability_qa.csv"
)
qa <- fread(file.path(root, qa_relative))
qa_live <- rbindlist(lapply(seq_len(nrow(qa)), function(index) {
  relative <- qa$path[[index]]
  absolute <- file.path(root, relative)
  dimensions <- png_dimensions(absolute)
  data.table(
    figure_id = qa$figure_id[[index]],
    path = relative,
    expected_sha256 = qa$sha256[[index]],
    live_sha256 = sha256_file(absolute),
    expected_bytes = qa$bytes[[index]],
    live_bytes = as.numeric(file.info(absolute)$size),
    expected_width = qa$pixel_width[[index]],
    live_width = dimensions[["width"]],
    expected_height = qa$pixel_height[[index]],
    live_height = dimensions[["height"]]
  )
}))
qa_live[, exact := expected_sha256 == live_sha256 &
  as.numeric(expected_bytes) == live_bytes &
  as.numeric(expected_width) == live_width &
  as.numeric(expected_height) == live_height]
fwrite(qa_live, file.path(out_dir, "figure_png_identity.csv"))
add_check(
  "companion_figure_pngs",
  nrow(qa_live) == 3L && all(qa_live$exact),
  sprintf("%d/%d exact SHA-256, byte, and pixel-dimension pins", sum(qa_live$exact), nrow(qa_live))
)

protected_pre <- fread(file.path(pre_dir, "protected_live_pre.csv"))
protected_post <- live_table(protected_pre$path)
protected_reconciliation <- merge(
  protected_pre,
  protected_post,
  by = "path",
  all = TRUE,
  suffixes = c("_pre", "_post")
)
protected_reconciliation[, status := fcase(
  is.na(exists_pre), "ADDED",
  is.na(exists_post) | !exists_post, "REMOVED",
  sha256_pre != sha256_post | as.numeric(bytes_pre) != as.numeric(bytes_post),
    "CONTENT_CHANGED",
  default = "UNCHANGED"
)]
allowed_protected_changes <- c(
  html_relative,
  website_qmd_relative,
  manifest_relative
)
protected_reconciliation[, allowed := status == "UNCHANGED" |
  path %in% allowed_protected_changes]
fwrite(
  protected_reconciliation,
  file.path(out_dir, "protected_reconciliation.csv")
)
add_check(
  "protected_paths",
  all(protected_reconciliation$allowed) &&
    all(c(
      "notebooks/hypotheses/H06.qmd",
      result_html_relative,
      "scripts/hypotheses/H06/h06_contract.R",
      "notebooks/hypotheses/H06_daily.qmd",
      "audit/hypotheses/H06_daily/H06_daily_analysis_preparation.qmd",
      "_quarto-nathealth.yml",
      "renv.lock"
    ) %in% protected_reconciliation[status == "UNCHANGED", path]),
  sprintf(
    "%d protected rows; %d changed; %d unexpected",
    nrow(protected_reconciliation),
    sum(protected_reconciliation$status != "UNCHANGED"),
    sum(!protected_reconciliation$allowed)
  )
)

build_pre <- fread(file.path(pre_dir, "build_pre.csv"))
build_post <- inventory_files(build_root)
build_reconciliation <- merge(
  build_pre,
  build_post,
  by = "path",
  all = TRUE,
  suffixes = c("_pre", "_post")
)
build_reconciliation[, status := fcase(
  is.na(sha256_pre), "ADDED",
  is.na(sha256_post), "REMOVED",
  sha256_pre != sha256_post | as.numeric(bytes_pre) != as.numeric(bytes_post),
    "CONTENT_CHANGED",
  as.numeric(mtime_pre) != as.numeric(mtime_post), "MTIME_ONLY",
  default = "UNCHANGED"
)]
allowed_content <- build_reconciliation$path %in% c(
  html_relative,
  website_qmd_relative,
  "_build/nathealth/search.json",
  "_build/nathealth/sitemap.xml"
) | startsWith(
  build_reconciliation$path,
  paste0(
    "_build/nathealth/audit/hypotheses/H06/",
    "H06_analysis_preparation_files/"
  )
)
build_reconciliation[, allowed := status %in% c("UNCHANGED", "MTIME_ONLY") |
  (status %in% c("ADDED", "REMOVED", "CONTENT_CHANGED") & allowed_content)]
fwrite(build_reconciliation, file.path(out_dir, "build_reconciliation.csv"))
build_entries <- list.files(
  build_root,
  all.files = TRUE,
  recursive = TRUE,
  full.names = TRUE,
  include.dirs = TRUE,
  no.. = TRUE
)
symlink_count <- sum(nzchar(Sys.readlink(build_entries)))
add_check(
  "build_delta_and_symlinks",
  all(build_reconciliation$allowed) && symlink_count == 0L,
  sprintf(
    "%d pre/%d post files; %d added, %d removed, %d content-changed, %d mtime-only; %d unexpected; %d symlinks",
    nrow(build_pre),
    nrow(build_post),
    sum(build_reconciliation$status == "ADDED"),
    sum(build_reconciliation$status == "REMOVED"),
    sum(build_reconciliation$status == "CONTENT_CHANGED"),
    sum(build_reconciliation$status == "MTIME_ONLY"),
    sum(!build_reconciliation$allowed),
    symlink_count
  )
)

fixed_pins <- data.table(
  path = c(
    "notebooks/hypotheses/H06.qmd",
    result_html_relative,
    "scripts/hypotheses/H06/h06_contract.R",
    authoring_relative,
    "scripts/hypotheses/H06/build_h06_preparation_report_manifest.R",
    "tests/hypotheses/H06/test_h06_preparation_report.R",
    "_quarto-nathealth.yml",
    "scripts/report_harmonization/post_render_gt_html_semantics.R",
    "scripts/report_harmonization/repair_gt_html_semantics.R",
    "renv.lock",
    "notebooks/hypotheses/H06_daily.qmd",
    "audit/hypotheses/H06_daily/H06_daily_analysis_preparation.qmd",
    "_build/nathealth/notebooks/hypotheses/H06_daily.html",
    paste0(
      "_build/nathealth/audit/hypotheses/H06_daily/",
      "H06_daily_analysis_preparation.html"
    )
  ),
  expected_sha256 = c(
    "d65c197cb37db32101d8a43fcdc80198ab599a95cb73259abd187c9b2b58d350",
    "8b5f1b0ada997290ec5324de35e0c874fd25e2e9ef052281acaab07d0a3dccaa",
    "b11447a49a52a6a1a66618f9f471c0cda5284cbb8a251f7dffb2512d9ede231f",
    "f952d5ec72066ee86fded4888aaa815bdf763c11f466806ebc7391c79e22918b",
    "bc53e754478a3fa17de0aaf498aea8720d58b958949050f7447d25c5ec23e2fb",
    "2b9f02f7caa448a3c7fdb88b0febc5ce306239002ebe220b6f5f7a7c4285a4fc",
    "80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3",
    "28c1105840834e95a37f84eaded9a2c595b9febd568fbc763daef247a53d7205",
    "7c949930fec862a4ce783c28d0256d36cb45de7c017bd9fcbb7cb910599463d1",
    "3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350",
    "01213a193515c49419dcd1ed9cffcc070a88d639a7382e218275a89bd704cb08",
    "ef4fde67d5dd2ebbb14deb76c025b5ac2ac9b6a34f7b34ca62c2fdb382bde709",
    "5a20c0680011be17111f72bb6b15aed6a4f4700c8866a13ea6dcf49a589fcce3",
    "7f3adfd0d80c9e083baa34f6aa056bc12e0a30e233f786fbc55a6ad6ac176259"
  )
)
fixed_live <- live_table(fixed_pins$path)
fixed_check <- cbind(fixed_pins, fixed_live[, .(
  live_exists = exists,
  live_sha256 = sha256,
  live_bytes = bytes
)])
fixed_check[, exact := live_exists & expected_sha256 == live_sha256]
fwrite(fixed_check, file.path(out_dir, "fixed_pin_reconciliation.csv"))
add_check(
  "fixed_result_tools_and_daily_pins",
  all(fixed_check$exact),
  sprintf("%d/%d exact", sum(fixed_check$exact), nrow(fixed_check))
)

package_versions <- data.table(
  item = c("R", "data.table", "digest", "xml2"),
  version = c(
    as.character(getRversion()),
    as.character(packageVersion("data.table")),
    as.character(packageVersion("digest")),
    as.character(packageVersion("xml2"))
  )
)
fwrite(package_versions, file.path(out_dir, "package_versions.csv"))

check_table <- rbindlist(check_rows)
fwrite(check_table, file.path(out_dir, "read_only_check_summary.csv"))
cat("H06 order 47d safe post-render inspection complete\n")
cat("Checks:", sum(check_table$status == "PASS"), "PASS /", sum(check_table$status == "FAIL"), "FAIL\n")
print(check_table)
