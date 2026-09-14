#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE, warn = 2)
suppressPackageStartupMessages({
  library(jpeg)
  library(openssl)
  library(readr)
  library(xml2)
})

stopifnot(identical(as.character(getRversion()), "4.6.1"))

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
setwd(root)

output_dir <- Sys.getenv(
  "H11_ORDER61A_ACCEPTANCE_DIR",
  unset = file.path(
    root,
    paste0(
      "audit/report_harmonization/",
      "report018_h11_order61a_result_companion_acceptance"
    )
  )
)
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
output_dir <- normalizePath(output_dir, winslash = "/", mustWork = TRUE)

owner_dir <- paste0(
  "audit/hypotheses/H11/",
  "report018_order61a_no_rerender_completion"
)
render_dir <- paste0(
  "audit/hypotheses/H11/",
  "report018_order61_companion_render"
)

sha256_file <- function(path) {
  connection <- file(path, open = "rb")
  on.exit(close(connection), add = TRUE)
  paste0(openssl::sha256(connection))
}

sha256_raw <- function(value) paste0(openssl::sha256(value))

file_bytes <- function(path) unname(as.numeric(file.info(path)$size))

read_raw_file <- function(path) {
  readBin(path, what = "raw", n = file_bytes(path))
}

replace_ranges <- function(content, starts, ends, replacements) {
  for (index in order(starts, decreasing = TRUE)) {
    before <- if (starts[[index]] > 1L) {
      content[seq_len(starts[[index]] - 1L)]
    } else {
      raw()
    }
    after <- if (ends[[index]] < length(content)) {
      content[seq.int(ends[[index]] + 1L, length(content))]
    } else {
      raw()
    }
    content <- c(
      before,
      charToRaw(enc2utf8(replacements[[index]])),
      after
    )
  }
  content
}

checks <- list()
add_check <- function(domain, check_id, pass, detail) {
  checks[[length(checks) + 1L]] <<- data.frame(
    domain = domain,
    check_id = check_id,
    pass = isTRUE(pass),
    detail = as.character(detail),
    stringsAsFactors = FALSE
  )
}

audit_manifest <- function(manifest_path, expected_rows, output_name) {
  manifest <- readr::read_csv(manifest_path, show_col_types = FALSE)
  exists <- file.exists(manifest$path) & !dir.exists(manifest$path)
  live_sha256 <- rep(NA_character_, nrow(manifest))
  live_bytes <- rep(NA_real_, nrow(manifest))
  live_sha256[exists] <- vapply(
    manifest$path[exists],
    sha256_file,
    character(1)
  )
  live_bytes[exists] <- unname(
    as.numeric(file.info(manifest$path[exists])$size)
  )
  exact <- exists &
    live_sha256 == manifest$sha256 &
    live_bytes == as.numeric(manifest$bytes)
  audit <- data.frame(
    path = manifest$path,
    sealed_sha256 = manifest$sha256,
    live_sha256 = live_sha256,
    sealed_bytes = manifest$bytes,
    live_bytes = live_bytes,
    exact = exact,
    stringsAsFactors = FALSE
  )
  readr::write_csv(audit, file.path(output_dir, output_name))
  list(
    manifest = manifest,
    audit = audit,
    pass = nrow(manifest) == expected_rows &&
      !anyDuplicated(manifest$path) &&
      !manifest_path %in% manifest$path &&
      all(exact)
  )
}

audit_snapshot <- function(path, output_name, has_type = FALSE) {
  snapshot <- readr::read_csv(path, show_col_types = FALSE)
  is_directory <- if (has_type) {
    snapshot$type == "directory"
  } else {
    rep(FALSE, nrow(snapshot))
  }
  exists <- ifelse(
    is_directory,
    dir.exists(snapshot$path),
    file.exists(snapshot$path)
  )
  live_sha256 <- rep(NA_character_, nrow(snapshot))
  live_bytes <- rep(NA_real_, nrow(snapshot))
  file_rows <- !is_directory & exists
  live_sha256[file_rows] <- vapply(
    snapshot$path[file_rows],
    sha256_file,
    character(1)
  )
  live_bytes[file_rows] <- unname(
    as.numeric(file.info(snapshot$path[file_rows])$size)
  )
  exact <- ifelse(
    is_directory,
    exists,
    exists &
      live_sha256 == snapshot$sha256 &
      live_bytes == as.numeric(snapshot$bytes)
  )
  audit <- data.frame(
    path = snapshot$path,
    type = if (has_type) snapshot$type else "file",
    sealed_sha256 = snapshot$sha256,
    live_sha256 = live_sha256,
    sealed_bytes = snapshot$bytes,
    live_bytes = live_bytes,
    exact = exact,
    stringsAsFactors = FALSE
  )
  readr::write_csv(audit, file.path(output_dir, output_name))
  list(snapshot = snapshot, audit = audit, pass = all(exact))
}

owner_manifest_path <- file.path(
  owner_dir,
  "order61a_fail_closed_non_circular_manifest.csv"
)
owner_manifest_result <- audit_manifest(
  owner_manifest_path,
  47L,
  "owner_manifest_audit.csv"
)
add_check(
  "owner seal",
  "owner_manifest_exact_and_non_circular",
  owner_manifest_result$pass,
  sprintf(
    "exact=%d/%d",
    sum(owner_manifest_result$audit$exact),
    nrow(owner_manifest_result$audit)
  )
)

fixed <- data.frame(
  path = c(
    file.path(owner_dir, "order61a_fail_closed_stop.md"),
    owner_manifest_path,
    file.path(owner_dir, "preparation_test_execution.txt"),
    file.path(owner_dir, "static_acceptance_checks.csv"),
    file.path(owner_dir, "loopback_visual_qa.md"),
    file.path(owner_dir, "loopback_server_lifecycle.md"),
    file.path(owner_dir, "screenshot_representation_audit.csv"),
    "tests/hypotheses/H11/test_h11_preparation_report.R",
    "artifacts/12_manifests/H11/H11_preparation_report_manifest.csv",
    "notebooks/hypotheses/H11.qmd",
    "_build/nathealth/notebooks/hypotheses/H11.html",
    "audit/hypotheses/H11/H11_analysis_preparation.qmd",
    paste0(
      "_build/nathealth/audit/hypotheses/H11/",
      "H11_analysis_preparation.qmd"
    ),
    paste0(
      "_build/nathealth/audit/hypotheses/H11/",
      "H11_analysis_preparation.html"
    ),
    "notebooks/sensitivity_battery.qmd",
    "_build/nathealth/notebooks/sensitivity_battery.html",
    "_quarto-nathealth.yml",
    "renv.lock",
    "audit/report_harmonization/coordination_matrix.csv"
  ),
  expected_sha256 = c(
    "e4a2371c6183e9ade3bb1b9d22afb3c57fc37a3c19a18e677ad442f800331ab8",
    "84bf23a1f3f7caaaa6a0c308fe8d96b44141639bf0580cb83571307e544733b1",
    "c7d261abf6ef782084f5762054d07e871a0258f4bcea617728d6e6086bc5233d",
    "41590fbe5a28d4f3d6e6b6b9fcaf34d1491b5951eeb47e83e8de19da8cd4761b",
    "408da6d3f8b3369b28ba0fc208a00540de384c602d38e287683e268e276cc112",
    "3d8192824bbb3950fe7c4a19fa2d7c63df9fd1a71b729ace50c64be17fac3dd4",
    "75b33b866d910f6d0360921de44664e5923d2d69dc07fb7a3c3e80b2ec3274d5",
    "64b427b4bc11f79a1ea2cd539eee7e30184271ef05cbba7b3f511a2f105a15a3",
    "bd34dbfd6d2e929c825fe76281dfd384d8b0ef851b3d99a52b155c3216cfc6d9",
    "7909ba06782c84223197ab7fcd16493d7ee6e6d8b63c750aa81f17cb97977867",
    "2c8a34ec47c10b3b4b1be600093cb03837bd0beb3b617f7e04f156529076d21a",
    "3f5a0d2ead03d2cb149451709110b59ba1387401f9ff633dfba1a0663f4b0816",
    "3f5a0d2ead03d2cb149451709110b59ba1387401f9ff633dfba1a0663f4b0816",
    "58518d708e4feb6145bd8eb773b6b9ae4937afdf4a9e44e19d4215d9ca86162c",
    "d2d1777062dbf58eca69cc58eadd6ad17a7ce80f4a8f335b6828f54ffcbfeb70",
    "b9af89c035391db6e39c55064b1de7309220702d626fa2fa274000b22b879780",
    "80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3",
    "3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350",
    "c8990a95151ebfd5deb0a1abca3a69ad2c4a1720f30537de13deebab2386b6ac"
  ),
  stringsAsFactors = FALSE
)
fixed$exists <- file.exists(fixed$path) & !dir.exists(fixed$path)
fixed$live_sha256 <- NA_character_
fixed$live_sha256[fixed$exists] <- vapply(
  fixed$path[fixed$exists],
  sha256_file,
  character(1)
)
fixed$exact <- fixed$exists & fixed$live_sha256 == fixed$expected_sha256
readr::write_csv(fixed, file.path(output_dir, "fixed_identity_audit.csv"))
add_check(
  "identity",
  "accepted_and_held_endpoints_exact",
  all(fixed$exact),
  sprintf("exact=%d/%d", sum(fixed$exact), nrow(fixed))
)

preparation_manifest <- audit_snapshot(
  "artifacts/12_manifests/H11/H11_preparation_report_manifest.csv",
  "preparation_manifest_live_audit.csv"
)
preparation_manifest_shape <- nrow(preparation_manifest$snapshot) == 283L &&
  !anyDuplicated(preparation_manifest$snapshot$path)
add_check(
  "manifest",
  "current_preparation_manifest_live_exact",
  preparation_manifest$pass && preparation_manifest_shape,
  sprintf(
    "exact=%d/%d",
    sum(preparation_manifest$audit$exact),
    nrow(preparation_manifest$audit)
  )
)

test_execution <- paste(
  readLines(
    file.path(owner_dir, "preparation_test_execution.txt"),
    warn = FALSE
  ),
  collapse = "\n"
)
test_execution_pass <- grepl("Run count: 1", test_execution, fixed = TRUE) &&
  grepl("Exit status: 0", test_execution, fixed = TRUE) &&
  grepl(
    "H11 preparation companion verified after shared-site integration",
    test_execution,
    fixed = TRUE
  ) &&
  grepl("Disposition: PASS", test_execution, fixed = TRUE)
add_check(
  "test",
  "single_preparation_test_pass",
  test_execution_pass,
  "run=1 exit=0 disposition=PASS"
)

semantic_summary <- readr::read_csv(
  file.path(render_dir, "gt_html_semantic_post_render_summary.csv"),
  show_col_types = FALSE
)
semantic_ledger <- readr::read_csv(
  file.path(render_dir, "H11_gt_semantic_ledger.csv"),
  show_col_types = FALSE
)
post_raw <- read_raw_file(
  "_build/nathealth/audit/hypotheses/H11/H11_analysis_preparation.html"
)
pre_raw <- replace_ranges(
  post_raw,
  as.integer(semantic_ledger$post_value_start_byte),
  as.integer(semantic_ledger$post_value_end_byte),
  semantic_ledger$pre_value
)
reapplied_raw <- replace_ranges(
  pre_raw,
  as.integer(semantic_ledger$pre_value_start_byte),
  as.integer(semantic_ledger$pre_value_end_byte),
  semantic_ledger$post_value
)
semantic_pass <- nrow(semantic_summary) == 1L &&
  semantic_summary$disposition == "REPAIRED" &&
  semantic_summary$table_count == 26L &&
  semantic_summary$id_count == 179L &&
  semantic_summary$headers_count == 801L &&
  semantic_summary$total_substitutions == 980L &&
  nrow(semantic_ledger) == 980L &&
  semantic_summary$pre_sha256 == sha256_raw(pre_raw) &&
  semantic_summary$post_sha256 == sha256_raw(post_raw) &&
  identical(reapplied_raw, post_raw)
semantic_audit <- data.frame(
  table_count = semantic_summary$table_count,
  id_count = semantic_summary$id_count,
  headers_count = semantic_summary$headers_count,
  substitutions = nrow(semantic_ledger),
  pre_sha256 = sha256_raw(pre_raw),
  post_sha256 = sha256_raw(post_raw),
  reverse_and_reapply = semantic_pass,
  stringsAsFactors = FALSE
)
readr::write_csv(semantic_audit, file.path(output_dir, "semantic_audit.csv"))
add_check(
  "semantic",
  "exact_reverse_and_reapplication",
  semantic_pass,
  "tables=26 ids=179 headers=801 substitutions=980"
)

document <- xml2::read_html(rawToChar(post_raw))
main_nodes <- xml2::xml_find_all(
  document,
  "//main[@id='quarto-document-content']"
)
stopifnot(length(main_nodes) == 1L)
main <- main_nodes[[1L]]
gt_tables <- xml2::xml_find_all(
  main,
  paste0(
    ".//table[contains(concat(' ', normalize-space(@class), ' '),",
    " ' gt_table ')]"
  )
)
images <- xml2::xml_find_all(main, ".//figure//img")
captions <- xml2::xml_find_all(main, ".//caption | .//figcaption")
mermaid <- xml2::xml_find_all(
  main,
  ".//*[contains(concat(' ', normalize-space(@class), ' '), ' mermaid ')]"
)
ids <- xml2::xml_attr(xml2::xml_find_all(document, ".//*[@id]"), "id")
ids <- ids[!is.na(ids) & nzchar(ids)]
header_rows <- list()
for (table_index in seq_along(gt_tables)) {
  table <- gt_tables[[table_index]]
  table_ids <- xml2::xml_attr(
    xml2::xml_find_all(table, "self::*[@id] | .//*[@id]"),
    "id"
  )
  headers <- xml2::xml_attr(
    xml2::xml_find_all(table, "self::*[@headers] | .//*[@headers]"),
    "headers"
  )
  for (value in headers) {
    tokens <- strsplit(trimws(value), "[[:space:]]+")[[1L]]
    tokens <- tokens[nzchar(tokens)]
    for (token in tokens) {
      header_rows[[length(header_rows) + 1L]] <- data.frame(
        table_index = table_index,
        token = token,
        resolves = sum(table_ids == token),
        stringsAsFactors = FALSE
      )
    }
  }
}
header_audit <- do.call(rbind, header_rows)
readr::write_csv(
  header_audit,
  file.path(output_dir, "table_header_resolution_audit.csv")
)
endpoint_audit <- readr::read_csv(
  file.path(owner_dir, "endpoint_order_audit.csv"),
  show_col_types = FALSE
)
dom_pass <- length(main_nodes) == 1L &&
  length(gt_tables) == 26L &&
  length(images) == 3L &&
  all(nzchar(xml2::xml_attr(images, "alt"))) &&
  length(captions) == 29L &&
  length(mermaid) == 1L &&
  !anyDuplicated(ids) &&
  nrow(header_audit) == 1193L &&
  all(header_audit$resolves == 1L) &&
  nrow(endpoint_audit) == 29L &&
  all(endpoint_audit$exact) &&
  length(xml2::xml_find_all(main, ".//*[contains(@class, 'error')]")) == 0L
dom_audit <- data.frame(
  main = length(main_nodes),
  gt_tables = length(gt_tables),
  figures = length(images),
  captions = length(captions),
  mermaid = length(mermaid),
  document_ids = length(ids),
  duplicate_ids = anyDuplicated(ids),
  scoped_header_tokens = nrow(header_audit),
  endpoint_rows = nrow(endpoint_audit),
  pass = dom_pass,
  stringsAsFactors = FALSE
)
readr::write_csv(dom_audit, file.path(output_dir, "dom_audit.csv"))
add_check(
  "DOM",
  "complete_reader_structure",
  dom_pass,
  "main=1 tables=26 figures=3 captions=29 mermaid=1 headers=1193"
)

source_links <- readr::read_csv(
  file.path(owner_dir, "source_link_audit.csv"),
  show_col_types = FALSE
)
source_links$live_exists <- file.exists(source_links$resolved_path)
source_links$live_fragment_resolves <- vapply(
  seq_len(nrow(source_links)),
  function(index) {
    fragment <- source_links$fragment[[index]]
    if (is.na(fragment) || !nzchar(fragment)) return(TRUE)
    if (!source_links$live_exists[[index]]) return(FALSE)
    source <- paste(
      readLines(source_links$resolved_path[[index]], warn = FALSE),
      collapse = "\n"
    )
    grepl(paste0("{#", fragment, "}"), source, fixed = TRUE) ||
      grepl(paste0("id=\"", fragment, "\""), source, fixed = TRUE)
  },
  logical(1)
)
readr::write_csv(source_links, file.path(output_dir, "source_link_audit.csv"))
link_head <- readr::read_csv(
  file.path(owner_dir, "loopback_link_head_checks.csv"),
  show_col_types = FALSE
)
links_pass <- nrow(source_links) == 20L &&
  length(unique(source_links$target)) == 17L &&
  sum(!is.na(source_links$fragment) & nzchar(source_links$fragment)) == 14L &&
  all(source_links$live_exists) &&
  all(source_links$live_fragment_resolves) &&
  nrow(link_head) == 9L &&
  all(link_head$pass) &&
  all(link_head$status == 200L)
add_check(
  "links",
  "source_and_served_link_contract",
  links_pass,
  "source=20/17 fragments=14 served_HEAD=9/9"
)

static_checks <- readr::read_csv(
  file.path(owner_dir, "static_acceptance_checks.csv"),
  show_col_types = FALSE
)
static_pass <- nrow(static_checks) == 9L && all(static_checks$pass)
add_check(
  "static",
  "owner_static_acceptance",
  static_pass,
  sprintf("pass=%d/%d", sum(static_checks$pass), nrow(static_checks))
)

screenshot_paths <- sort(list.files(
  owner_dir,
  pattern = "\\.png$",
  full.names = TRUE
))
expected_screenshots <- sort(file.path(
  owner_dir,
  c(
    "figure_1_170mm_642px.png",
    "figure_2_170mm_642px.png",
    "figure_3_170mm_642px.png",
    "loopback_1440_figure1_section.png",
    "loopback_1440x1000_full.png",
    "loopback_708_activity_section.png",
    "loopback_708_bottom_tables.png",
    "loopback_708_main_tables.png",
    "loopback_708x1000_full.png",
    "loopback_708x1000_viewport.png",
    "loopback_720_navigation_open.png",
    "loopback_720x500_full.png",
    "loopback_720x500_viewport.png"
  )
))
screenshot_rows <- lapply(screenshot_paths, function(path) {
  bytes <- readBin(path, what = "raw", n = 10L)
  signature <- paste(sprintf("%02x", as.integer(bytes)), collapse = "")
  image <- jpeg::readJPEG(path, native = TRUE)
  dimensions <- dim(image)
  data.frame(
    path = path,
    suffix = tools::file_ext(path),
    payload = if (startsWith(signature, "ffd8ffe000104a464946")) {
      "JPEG JFIF"
    } else {
      "unexpected"
    },
    signature = signature,
    width = dimensions[[2L]],
    height = dimensions[[1L]],
    decodes = TRUE,
    stringsAsFactors = FALSE
  )
})
screenshot_audit <- do.call(rbind, screenshot_rows)
readr::write_csv(
  screenshot_audit,
  file.path(output_dir, "screenshot_payload_audit.csv")
)
figure_metrics <- readr::read_csv(
  file.path(owner_dir, "loopback_figure_642px_metrics.csv"),
  show_col_types = FALSE
)
table_containment <- readr::read_csv(
  file.path(owner_dir, "loopback_table_containment.csv"),
  show_col_types = FALSE
)
visual_text <- paste(
  readLines(file.path(owner_dir, "loopback_visual_qa.md"), warn = FALSE),
  collapse = "\n"
)
screenshot_pass <- identical(screenshot_paths, expected_screenshots) &&
  nrow(screenshot_audit) == 13L &&
  all(screenshot_audit$payload == "JPEG JFIF") &&
  all(screenshot_audit$decodes) &&
  all(screenshot_audit$width > 0L) &&
  all(screenshot_audit$height > 0L)
visual_pass <- screenshot_pass &&
  nrow(figure_metrics) == 3L &&
  all(figure_metrics$rendered_width_px == 642L) &&
  all(figure_metrics$complete) &&
  all(figure_metrics$effective_essential_text_pt >= 7) &&
  all(figure_metrics$effective_minor_text_pt >= 7) &&
  all(figure_metrics$visual_status == "PASS") &&
  nrow(table_containment) == 78L &&
  all(table_containment$contained) &&
  grepl("## Disposition\n\nPASS", visual_text, fixed = TRUE)
add_check(
  "visual",
  "bounded_visual_QA_and_evidence_payloads",
  visual_pass,
  paste0(
    "screenshots=13/13 JPEG-JFIF; figures=3/3 >=7pt; ",
    "tables=78/78 contained"
  )
)
add_check(
  "evidence",
  "screenshot_suffix_mismatch_nonblocking",
  screenshot_pass,
  "valid JPEG/JFIF bytes retained unchanged under .png evidence suffixes"
)

inventory_pairs <- data.frame(
  scope = c("build", "protected", "scientific", "critical"),
  pre = file.path(
    owner_dir,
    c(
      "build_inventory_preqa.csv",
      "protected_inventory_preqa.csv",
      "scientific_inventory_preqa.csv",
      "critical_identities_preqa.csv"
    )
  ),
  post = file.path(
    owner_dir,
    c(
      "build_inventory_postqa.csv",
      "protected_inventory_postqa.csv",
      "scientific_inventory_postqa.csv",
      "critical_identities_postqa.csv"
    )
  ),
  stringsAsFactors = FALSE
)
inventory_pairs$raw_identical <- mapply(
  function(pre, post) identical(read_raw_file(pre), read_raw_file(post)),
  inventory_pairs$pre,
  inventory_pairs$post
)
readr::write_csv(
  inventory_pairs,
  file.path(output_dir, "pre_post_inventory_identity_audit.csv")
)

build_audit <- audit_snapshot(
  file.path(owner_dir, "build_inventory_postqa.csv"),
  "build_live_audit.csv",
  has_type = TRUE
)
current_build_paths <- sort(list.files(
  "_build/nathealth",
  recursive = TRUE,
  full.names = TRUE,
  all.files = TRUE,
  include.dirs = TRUE,
  no.. = TRUE
))
build_membership_pass <- identical(
  current_build_paths,
  sort(build_audit$snapshot$path)
)
protected_audit <- audit_snapshot(
  file.path(owner_dir, "protected_inventory_postqa.csv"),
  "protected_live_audit.csv"
)
scientific_audit <- audit_snapshot(
  file.path(owner_dir, "scientific_inventory_postqa.csv"),
  "scientific_live_audit.csv"
)
critical_audit <- audit_snapshot(
  file.path(owner_dir, "critical_identities_postqa.csv"),
  "critical_live_audit.csv"
)
inventory_pass <- all(inventory_pairs$raw_identical) &&
  build_audit$pass &&
  build_membership_pass &&
  protected_audit$pass &&
  scientific_audit$pass &&
  critical_audit$pass
add_check(
  "preservation",
  "pre_post_and_live_inventories",
  inventory_pass,
  paste0(
    "build=",
    nrow(build_audit$audit),
    " protected=",
    nrow(protected_audit$audit),
    " scientific=",
    nrow(scientific_audit$audit),
    " critical=",
    nrow(critical_audit$audit)
  )
)

lsof_output <- suppressWarnings(system2(
  "lsof",
  c("-nP", "-iTCP:53671", "-sTCP:LISTEN"),
  stdout = TRUE,
  stderr = TRUE
))
lsof_status <- attr(lsof_output, "status")
if (is.null(lsof_status)) lsof_status <- 0L
lifecycle_text <- paste(
  readLines(file.path(owner_dir, "loopback_server_lifecycle.md"), warn = FALSE),
  collapse = "\n"
)
listener_pass <- lsof_status == 1L &&
  length(lsof_output) == 0L &&
  grepl("Final disposition: PASS", lifecycle_text, fixed = TRUE) &&
  grepl("No listener or server process remained", lifecycle_text, fixed = TRUE)
listener_audit <- data.frame(
  port = 53671L,
  lsof_status = lsof_status,
  output_rows = length(lsof_output),
  lifecycle_record_pass = listener_pass,
  stringsAsFactors = FALSE
)
readr::write_csv(
  listener_audit,
  file.path(output_dir, "listener_teardown_audit.csv")
)
add_check(
  "teardown",
  "loopback_listener_absent",
  listener_pass,
  "127.0.0.1:53671 has no listening process"
)

check_table <- do.call(rbind, checks)
readr::write_csv(
  check_table,
  file.path(output_dir, "independent_acceptance_checks.csv")
)

stopifnot(nrow(check_table) == 12L, all(check_table$pass))
cat(sprintf(
  paste0(
    "REPORT018_H11_ORDER61A_ACCEPTANCE=PASS checks=%d/%d ",
    "owner=47/47 manifest=283/283 tables=26 figures=3 mermaid=1 ",
    "semantic=179+801 headers=1193 screenshots=13-JPEG-JFIF ",
    "build=1180 protected=336 science=193 listener=none R=%s\n"
  ),
  sum(check_table$pass),
  nrow(check_table),
  as.character(getRversion())
))
