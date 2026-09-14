#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE)

stopifnot(identical(as.character(getRversion()), "4.6.1"))

suppressPackageStartupMessages({
  library(digest)
  library(readr)
  library(rvest)
  library(xml2)
})

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
setwd(root)

old_evidence <- file.path(
  root,
  "audit/hypotheses/H07/report018_order53_companion_render"
)
evidence_dir <- file.path(
  root,
  "audit/hypotheses/H07/report018_order53a_companion_no_rerender_completion"
)
html_rel <-
  "_build/nathealth/audit/hypotheses/H07/H07_analysis_preparation.html"
html_path <- file.path(root, html_rel)
qmd_path <- file.path(root, "audit/hypotheses/H07/H07_analysis_preparation.qmd")
build_root <- file.path(root, "_build/nathealth")

sha256_file <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
}

hash_text <- function(value) {
  digest::digest(enc2utf8(value), algo = "sha256", serialize = FALSE)
}

clean_text <- function(node) {
  value <- rvest::html_text2(node)
  value <- gsub("[[:space:]]+", " ", value)
  trimws(value)
}

outside_source_modal <- function(nodes) {
  if (!length(nodes)) return(logical())
  !vapply(
    nodes,
    function(node) {
      length(xml2::xml_find_all(
        node,
        "ancestor::*[@id='quarto-embedded-source-code-modal']"
      )) > 0L
    },
    logical(1)
  )
}

write_evidence <- function(object, name) {
  write.csv(
    object,
    file.path(evidence_dir, name),
    row.names = FALSE,
    na = ""
  )
}

checks <- data.frame(
  domain = character(),
  check = character(),
  observed = character(),
  expected = character(),
  status = character(),
  stringsAsFactors = FALSE
)

add_check <- function(domain, check, observed, expected, pass) {
  checks <<- rbind(
    checks,
    data.frame(
      domain = domain,
      check = check,
      observed = paste(observed, collapse = " | "),
      expected = paste(expected, collapse = " | "),
      status = if (isTRUE(pass)) "PASS" else "FAIL",
      stringsAsFactors = FALSE
    )
  )
}

stopifnot(
  file.exists(html_path),
  identical(
    sha256_file(html_path),
    "4c03a3e3cdfa1c6eac13d5785ceee8306e6d0941278b679a1eb88e357b270d93"
  ),
  file.exists(qmd_path),
  dir.exists(old_evidence),
  dir.exists(evidence_dir)
)

central_verification <- read.csv(
  file.path(
    root,
    "audit/report_harmonization/report018_h07_order53_stopped_independent_verification.csv"
  ),
  check.names = FALSE
)
add_check(
  "central replay",
  "exactly-once central checker output",
  paste(sum(central_verification$status == "PASS"), nrow(central_verification), sep = "/"),
  "41/41",
  nrow(central_verification) == 41L && all(central_verification$status == "PASS")
)

dispatch_audit <- read.csv(
  file.path(evidence_dir, "dispatch_reconciliation_preqa.csv"),
  check.names = FALSE
)
add_check(
  "preflight",
  "non-matrix dispatch identities",
  paste(sum(dispatch_audit$status == "PASS"), nrow(dispatch_audit), sep = "/"),
  "26/26",
  nrow(dispatch_audit) == 26L && all(dispatch_audit$status == "PASS")
)

engine <- new.env(parent = globalenv())
sys.source(
  file.path(root, "scripts/report_harmonization/repair_gt_html_semantics.R"),
  envir = engine
)
semantic_summary <- read.csv(
  file.path(old_evidence, "gt_html_semantic_post_render_summary.csv"),
  check.names = FALSE
)
semantic_ledger <- read.csv(
  file.path(
    old_evidence,
    "001__build__nathealth__audit__hypotheses__H07__H07_analysis_preparation.html_gt_semantic_ledger.csv"
  ),
  check.names = FALSE
)
final_raw <- engine$read_file_raw(html_path)
reversed_raw <- engine$apply_raw_replacements(
  final_raw,
  semantic_ledger,
  reverse = TRUE
)
reapplied_raw <- engine$apply_raw_replacements(
  reversed_raw,
  semantic_ledger,
  reverse = FALSE
)
semantic_replay <- data.frame(
  check = c(
    "post identity",
    "reverse identity",
    "reapplication identity",
    "ledger rows",
    "ledger id substitutions",
    "ledger header substitutions"
  ),
  observed = c(
    engine$sha256_raw(final_raw),
    engine$sha256_raw(reversed_raw),
    engine$sha256_raw(reapplied_raw),
    nrow(semantic_ledger),
    sum(semantic_ledger$attribute == "id"),
    sum(semantic_ledger$attribute == "headers")
  ),
  expected = c(
    semantic_summary$post_sha256,
    "7dadaaaa92c89346af7a46490419c2af98602235cf655daa49a756c9b76dec4a",
    semantic_summary$post_sha256,
    850L,
    116L,
    734L
  ),
  stringsAsFactors = FALSE
)
semantic_replay$status <- ifelse(
  semantic_replay$observed == semantic_replay$expected,
  "PASS",
  "FAIL"
)
write_evidence(semantic_replay, "semantic_replay.csv")
add_check(
  "semantics",
  "exact reversal and reapplication",
  sum(semantic_replay$status == "PASS"),
  nrow(semantic_replay),
  all(semantic_replay$status == "PASS") && identical(final_raw, reapplied_raw)
)

pre_document <- xml2::read_html(rawToChar(reversed_raw))
post_document <- xml2::read_html(rawToChar(final_raw))
pre_main <- rvest::html_element(pre_document, "main#quarto-document-content")
post_main <- rvest::html_element(post_document, "main#quarto-document-content")
pre_elements <- xml2::xml_find_all(pre_document, "//*")
post_elements <- xml2::xml_find_all(post_document, "//*")
pre_links <- xml2::xml_attr(xml2::xml_find_all(pre_document, "//a[@href]"), "href")
post_links <- xml2::xml_attr(xml2::xml_find_all(post_document, "//a[@href]"), "href")
pre_captions <- vapply(
  rvest::html_elements(pre_main, "figcaption.quarto-float-caption"),
  clean_text,
  character(1)
)
post_captions <- vapply(
  rvest::html_elements(post_main, "figcaption.quarto-float-caption"),
  clean_text,
  character(1)
)
pre_notes <- vapply(
  rvest::html_elements(pre_main, ".gt_sourcenotes"),
  clean_text,
  character(1)
)
post_notes <- vapply(
  rvest::html_elements(post_main, ".gt_sourcenotes"),
  clean_text,
  character(1)
)
semantic_invariance <- data.frame(
  check = c(
    "normalized DOM excluding repaired values",
    "document visible text",
    "main visible text",
    "element sequence",
    "link sequence",
    "caption sequence",
    "source-note sequence"
  ),
  pre_value = c(
    hash_text(engine$normalized_dom_without_mutable_values(pre_document)),
    hash_text(xml2::xml_text(pre_document)),
    hash_text(xml2::xml_text(pre_main)),
    hash_text(paste(xml2::xml_name(pre_elements), collapse = "|")),
    hash_text(paste(pre_links, collapse = "|")),
    hash_text(paste(pre_captions, collapse = "|")),
    hash_text(paste(pre_notes, collapse = "|"))
  ),
  post_value = c(
    hash_text(engine$normalized_dom_without_mutable_values(post_document)),
    hash_text(xml2::xml_text(post_document)),
    hash_text(xml2::xml_text(post_main)),
    hash_text(paste(xml2::xml_name(post_elements), collapse = "|")),
    hash_text(paste(post_links, collapse = "|")),
    hash_text(paste(post_captions, collapse = "|")),
    hash_text(paste(post_notes, collapse = "|"))
  ),
  stringsAsFactors = FALSE
)
semantic_invariance$status <- ifelse(
  semantic_invariance$pre_value == semantic_invariance$post_value,
  "PASS",
  "FAIL"
)
write_evidence(semantic_invariance, "semantic_invariance_replay.csv")
add_check(
  "semantics",
  "visible and structural invariance",
  sum(semantic_invariance$status == "PASS"),
  nrow(semantic_invariance),
  all(semantic_invariance$status == "PASS")
)

# Reparse because the semantic normalizer mutates its DOM input.
post_document <- xml2::read_html(rawToChar(final_raw))
post_main <- rvest::html_element(post_document, "main#quarto-document-content")
qmd_lines <- readLines(qmd_path, warn = FALSE, encoding = "UTF-8")
expected_tables <- sub(
  "^#\\| label: ",
  "",
  grep("^#\\| label: tbl-h07-", qmd_lines, value = TRUE)
)
expected_figures <- sub(
  "^#\\| label: ",
  "",
  grep("^#\\| label: fig-h07-", qmd_lines, value = TRUE)
)

table_endpoints <- rvest::html_elements(
  post_main,
  '.quarto-float[id^="tbl-h07-"]'
)
table_endpoints <- table_endpoints[outside_source_modal(table_endpoints)]
table_ids <- rvest::html_attr(table_endpoints, "id")
table_rows <- do.call(rbind, lapply(seq_along(table_endpoints), function(index) {
  endpoint <- table_endpoints[[index]]
  table <- rvest::html_element(endpoint, "table.gt_table")
  data.frame(
    order = index,
    endpoint = table_ids[[index]],
    native_gt_count = length(rvest::html_elements(endpoint, "table.gt_table")),
    caption_count = length(rvest::html_elements(
      endpoint,
      "figcaption.quarto-float-caption"
    )),
    caption = clean_text(rvest::html_element(
      endpoint,
      "figcaption.quarto-float-caption"
    )),
    rows = length(rvest::html_elements(table, "tr")),
    header_cells = length(rvest::html_elements(table, "th")),
    body_cells = length(rvest::html_elements(table, "td")),
    note_count = length(rvest::html_elements(endpoint, ".gt_sourcenotes")),
    stringsAsFactors = FALSE
  )
}))
accepted_tables <- read.csv(
  file.path(old_evidence, "table_endpoint_audit.csv"),
  check.names = FALSE
)
compare_columns <- c(
  "order", "endpoint", "native_gt_count", "caption_count", "caption",
  "rows", "header_cells", "body_cells"
)
table_exact <- identical(
  table_rows[, compare_columns],
  accepted_tables[, compare_columns]
)
table_rows$status <- ifelse(
  table_rows$native_gt_count == 1L &
    table_rows$caption_count == 1L &
    nzchar(table_rows$caption),
  "PASS",
  "FAIL"
)
write_evidence(table_rows, "table_endpoint_replay.csv")
add_check(
  "reader structure",
  "21 native gt tables in exact source order with captions",
  paste(table_ids, collapse = "|"),
  paste(expected_tables, collapse = "|"),
  length(table_ids) == 21L &&
    identical(table_ids, expected_tables) &&
    table_exact &&
    all(table_rows$status == "PASS")
)
add_check(
  "reader structure",
  "table source notes preserved",
  paste(length(post_notes), hash_text(paste(post_notes, collapse = "|")), sep = "/"),
  paste(length(pre_notes), hash_text(paste(pre_notes, collapse = "|")), sep = "/"),
  identical(post_notes, pre_notes) && length(post_notes) > 0L
)

png_endpoints <- rvest::html_elements(
  post_main,
  '.quarto-float[id^="fig-h07-"]'
)
png_endpoints <- png_endpoints[outside_source_modal(png_endpoints)]
png_ids <- rvest::html_attr(png_endpoints, "id")
expected_png_ids <- setdiff(expected_figures, "fig-h07-preparation-map")
png_expected_hashes <- c(
  "603afa8def8ff640003daaef806ee390d513df9bb6f6307fa300dba4ad5ba8a7",
  "00d687082780c65d07467fdf730ac8bcf0bd97af11a03af156dc38020b815eb4"
)
png_rows <- do.call(rbind, lapply(seq_along(png_endpoints), function(index) {
  endpoint <- png_endpoints[[index]]
  image <- rvest::html_element(endpoint, "img")
  src <- rvest::html_attr(image, "src")
  resolved <- normalizePath(
    file.path(dirname(html_path), URLdecode(src)),
    winslash = "/",
    mustWork = FALSE
  )
  data.frame(
    order = index,
    endpoint = png_ids[[index]],
    src = src,
    resolved_path = resolved,
    image_exists = file.exists(resolved),
    image_sha256 = if (file.exists(resolved)) sha256_file(resolved) else "",
    expected_sha256 = png_expected_hashes[[index]],
    alt = rvest::html_attr(image, "alt"),
    alt_length = nchar(rvest::html_attr(image, "alt")),
    caption = clean_text(rvest::html_element(
      endpoint,
      "figcaption.quarto-float-caption"
    )),
    stringsAsFactors = FALSE
  )
}))
png_rows$status <- ifelse(
  png_rows$image_exists &
    png_rows$image_sha256 == png_rows$expected_sha256 &
    png_rows$alt_length >= 200L &
    nzchar(png_rows$caption),
  "PASS",
  "FAIL"
)
write_evidence(png_rows, "png_endpoint_replay.csv")
add_check(
  "reader structure",
  "two PNG figures with captions and alt text",
  paste(png_ids, collapse = "|"),
  paste(expected_png_ids, collapse = "|"),
  identical(png_ids, expected_png_ids) && all(png_rows$status == "PASS")
)

mermaid_nodes <- rvest::html_elements(post_main, "pre.mermaid.mermaid-js")
mermaid_text <- if (length(mermaid_nodes)) clean_text(mermaid_nodes[[1L]]) else ""
mermaid_replay <- data.frame(
  endpoint = "fig-h07-preparation-map",
  nodes = length(mermaid_nodes),
  direction = ifelse(grepl("^flowchart TD", mermaid_text), "TD", ""),
  node_text_sha256 = hash_text(mermaid_text),
  stringsAsFactors = FALSE
)
mermaid_replay$status <- ifelse(
  mermaid_replay$nodes == 1L && mermaid_replay$direction == "TD",
  "PASS",
  "FAIL"
)
write_evidence(mermaid_replay, "mermaid_replay.csv")
add_check(
  "reader structure",
  "one top-down Mermaid",
  paste(mermaid_replay$nodes, mermaid_replay$direction, sep = "/"),
  "1/TD",
  mermaid_replay$status == "PASS"
)

all_ids <- rvest::html_attr(rvest::html_elements(post_document, "[id]"), "id")
all_ids <- all_ids[!is.na(all_ids) & nzchar(all_ids)]
add_check(
  "semantics",
  "unique document IDs",
  sum(duplicated(all_ids)),
  0L,
  !anyDuplicated(all_ids)
)

header_rows <- lapply(table_endpoints, function(endpoint) {
  endpoint_id <- rvest::html_attr(endpoint, "id")
  table <- rvest::html_element(endpoint, "table.gt_table")
  nodes <- rvest::html_elements(table, "[headers]")
  do.call(rbind, lapply(nodes, function(node) {
    tokens <- strsplit(
      trimws(rvest::html_attr(node, "headers")),
      "[[:space:]]+"
    )[[1L]]
    do.call(rbind, lapply(tokens[nzchar(tokens)], function(token) {
      matches <- xml2::xml_find_all(table, sprintf(".//*[@id='%s']", token))
      resolves <- length(matches) == 1L &&
        identical(xml2::xml_name(matches[[1L]]), "th")
      data.frame(
        endpoint = endpoint_id,
        header_token = token,
        matches_in_table = length(matches),
        resolves_to_th = resolves,
        status = ifelse(resolves, "PASS", "FAIL"),
        stringsAsFactors = FALSE
      )
    }))
  }))
})
header_audit <- do.call(rbind, header_rows)
write_evidence(header_audit, "table_header_replay.csv")
add_check(
  "semantics",
  "1,144 table-header tokens resolve once to th within table",
  paste(sum(header_audit$status == "PASS"), nrow(header_audit), sep = "/"),
  "1144/1144",
  nrow(header_audit) == 1144L && all(header_audit$status == "PASS")
)

document_cache <- new.env(parent = emptyenv())
fragment_resolves_once <- function(target_path, fragment) {
  if (!nzchar(fragment)) return(TRUE)
  if (!grepl("[.]html?$", target_path, ignore.case = TRUE)) return(TRUE)
  key <- normalizePath(target_path, winslash = "/", mustWork = TRUE)
  if (!exists(key, envir = document_cache, inherits = FALSE)) {
    assign(key, xml2::read_html(key), envir = document_cache)
  }
  target_document <- get(key, envir = document_cache, inherits = FALSE)
  target_ids <- rvest::html_attr(
    rvest::html_elements(target_document, "[id]"),
    "id"
  )
  sum(target_ids == fragment, na.rm = TRUE) == 1L
}

main_anchors <- rvest::html_elements(post_main, "a[href]")
main_anchors <- main_anchors[outside_source_modal(main_anchors)]
main_hrefs <- rvest::html_attr(main_anchors, "href")
main_link_text <- vapply(main_anchors, clean_text, character(1))
link_rows <- lapply(seq_along(main_hrefs), function(index) {
  href <- main_hrefs[[index]]
  control <- grepl("^javascript:", href, ignore.case = TRUE)
  external <- grepl("^(https?|mailto|tel):", href, ignore.case = TRUE)
  path_part <- sub("[?#].*$", "", href)
  fragment <- if (grepl("#", href, fixed = TRUE)) {
    URLdecode(sub("^[^#]*#", "", href))
  } else {
    ""
  }
  if (control || external) {
    resolved <- ""
    target_exists <- TRUE
    fragment_ok <- TRUE
  } else {
    resolved <- if (!nzchar(path_part)) {
      html_path
    } else if (startsWith(path_part, "/")) {
      normalizePath(
        file.path(build_root, sub("^/+", "", path_part)),
        winslash = "/",
        mustWork = FALSE
      )
    } else {
      normalizePath(
        file.path(dirname(html_path), URLdecode(path_part)),
        winslash = "/",
        mustWork = FALSE
      )
    }
    target_exists <- file.exists(resolved)
    fragment_ok <- target_exists && fragment_resolves_once(resolved, fragment)
  }
  forbidden <- !control && !external && (
    grepl("[.]qmd($|[?#])", href, ignore.case = TRUE) ||
      grepl("file://", href, fixed = TRUE) ||
      grepl("/Users/", href, fixed = TRUE)
  )
  status <- if (control) {
    "EXCLUDED_QUARTO_CONTROL"
  } else if (target_exists && fragment_ok && !forbidden) {
    "PASS"
  } else {
    "FAIL"
  }
  data.frame(
    order = index,
    link_text = main_link_text[[index]],
    href = href,
    resolved_path = resolved,
    target_exists = target_exists,
    fragment = fragment,
    fragment_resolves_once = fragment_ok,
    forbidden_target = forbidden,
    status = status,
    stringsAsFactors = FALSE
  )
})
link_audit <- do.call(rbind, link_rows)
write_evidence(link_audit, "reader_link_replay.csv")
applicable <- link_audit$status != "EXCLUDED_QUARTO_CONTROL"
add_check(
  "reader links",
  "405 applicable links and three non-file controls",
  paste(
    sum(link_audit$status[applicable] == "PASS"),
    sum(applicable),
    sum(!applicable),
    sep = "/"
  ),
  "405/405/3",
  sum(applicable) == 405L &&
    all(link_audit$status[applicable] == "PASS") &&
    sum(!applicable) == 3L &&
    all(link_audit$href[!applicable] == "javascript:void(0)")
)

result_href <- "../../../notebooks/hypotheses/H07.html"
result_links <- link_audit[startsWith(link_audit$href, result_href), , drop = FALSE]
expected_result_links <- c(
  result_href,
  result_href,
  paste0(result_href, "#h07-preregistration-deviations")
)
add_check(
  "reader links",
  "three dynamic result links",
  paste(sort(result_links$href), collapse = "|"),
  paste(sort(expected_result_links), collapse = "|"),
  identical(sort(result_links$href), sort(expected_result_links))
)

expected_source_files <- c(
  "H07_preparation_metric_contract.csv" = 9L,
  "H07_preparation_input_identities.csv" = 4L,
  "H07_preparation_frame_integrity.csv" = 18L,
  "H07_preparation_sample_support.csv" = 18L,
  "H07_preparation_site_support.csv" = 153L,
  "H07_preparation_site_photoperiod_ranges.csv" = 17L,
  "H07_preparation_diagnostic_summary.csv" = 2L,
  "H07_preparation_pattern_summary.csv" = 18L,
  "H07_preparation_formula_registry.csv" = 9L
)
reader_linked_source_files <- c(
  "H07_preparation_input_identities.csv",
  "H07_preparation_frame_integrity.csv",
  "H07_preparation_sample_support.csv",
  "H07_preparation_site_support.csv",
  "H07_preparation_site_photoperiod_ranges.csv",
  "H07_preparation_formula_registry.csv"
)
source_dir <- file.path(root, "artifacts/11_source_data/H07/preparation")
source_rows <- data.frame(
  file = names(expected_source_files),
  expected_rows = unname(expected_source_files),
  observed_rows = vapply(
    names(expected_source_files),
    function(filename) nrow(readr::read_csv(
      file.path(source_dir, filename),
      show_col_types = FALSE
    )),
    integer(1)
  ),
  linked_from_page = vapply(
    names(expected_source_files),
    function(filename) any(grepl(filename, link_audit$href, fixed = TRUE)),
    logical(1)
  ),
  reader_link_required = names(expected_source_files) %in%
    reader_linked_source_files,
  stringsAsFactors = FALSE
)
source_rows$status <- ifelse(
  source_rows$expected_rows == source_rows$observed_rows &
    (!source_rows$reader_link_required | source_rows$linked_from_page),
  "PASS",
  "FAIL"
)
write_evidence(source_rows, "source_data_relationship_replay.csv")
add_check(
  "source data",
  "nine row contracts and six reader-facing source links",
  paste(
    sum(source_rows$status == "PASS"),
    nrow(source_rows),
    sum(source_rows$linked_from_page[source_rows$reader_link_required]),
    sum(source_rows$reader_link_required),
    sep = "/"
  ),
  "9/9/6/6",
  all(source_rows$status == "PASS") &&
    sum(source_rows$reader_link_required) == 6L
)

main_text <- clean_text(post_main)
required_reader_phrases <- c(
  "H07 analysis preparation and provenance",
  "139–141 participants",
  "655–816 participant-days",
  "153–154 participants",
  "743–902 participant-days",
  "All 18 reported photoperiod-smooth fits converged",
  "three near-eye and one chest",
  "approximately 0.9985–0.9988",
  "does not support a distinct latitude effect",
  "gap-timing-unaware dataset",
  "time-sensitive primary metric dataset",
  "No independent temperature",
  "METRIC-011"
)
phrase_audit <- data.frame(
  phrase = required_reader_phrases,
  present = vapply(
    required_reader_phrases,
    grepl,
    logical(1),
    x = main_text,
    fixed = TRUE
  ),
  stringsAsFactors = FALSE
)
phrase_audit$status <- ifelse(phrase_audit$present, "PASS", "FAIL")
write_evidence(phrase_audit, "reader_phrase_replay.csv")
add_check(
  "scientific contract",
  "required reader phrases",
  sum(phrase_audit$present),
  length(required_reader_phrases),
  all(phrase_audit$present)
)

site_names <- c(
  "Borås (SE)", "Delft (NL)", "Dortmund (DE)", "Tübingen (DE)",
  "Munich (DE)", "Madrid (ES)", "Izmir (TR)", "San José (CR)",
  "Kumasi (GH)"
)
site_present <- vapply(site_names, grepl, logical(1), x = main_text, fixed = TRUE)
add_check(
  "reader structure",
  "nine country-coded sites",
  sum(site_present),
  9L,
  all(site_present)
)

active_nodes <- rvest::html_elements(post_document, "a.sidebar-link.active")
active_text <- vapply(active_nodes, clean_text, character(1))
embedded_defects <- sum(vapply(
  c(
    ".cell-output-error", ".cell-output-warning", ".cell-output-stderr",
    ".quarto-error", ".quarto-warning", "pre.stderr"
  ),
  function(selector) length(rvest::html_elements(post_main, selector)),
  integer(1)
))
unresolved_crossrefs <- grepl(
  "[?]@(tbl|fig|sec|eq)-|@(tbl|fig|sec|eq)-[A-Za-z0-9_-]+",
  main_text,
  perl = TRUE
)
raw_trace <- any(vapply(
  c("processing file:", "output file:", "Quitting from lines", "pandoc --"),
  grepl,
  logical(1),
  x = main_text,
  fixed = TRUE
))
add_check(
  "reader structure",
  "active H07 preparation navigation",
  paste(active_text, collapse = "|"),
  "H07 preparation and provenance",
  length(active_nodes) == 1L &&
    identical(active_text, "H07 preparation and provenance")
)
add_check(
  "reader structure",
  "deviation anchor",
  sum(all_ids == "h07-preparation-preregistration-deviations"),
  1L,
  sum(all_ids == "h07-preparation-preregistration-deviations") == 1L
)
add_check(
  "reader structure",
  "zero embedded errors warnings and unresolved cross-references",
  paste(embedded_defects, unresolved_crossrefs, raw_trace, sep = "/"),
  "0/FALSE/FALSE",
  embedded_defects == 0L && !unresolved_crossrefs && !raw_trace
)

headings <- rvest::html_elements(post_main, "h1, h2, h3")
heading_rows <- data.frame(
  level = rvest::html_name(headings),
  id = rvest::html_attr(headings, "id"),
  text = vapply(headings, clean_text, character(1)),
  stringsAsFactors = FALSE
)
write_evidence(heading_rows, "heading_replay.csv")
add_check(
  "reader structure",
  "headings present with unique nonempty text",
  nrow(heading_rows),
  ">0",
  nrow(heading_rows) > 0L && all(nzchar(heading_rows$text))
)

input_identities <- readr::read_csv(
  file.path(source_dir, "H07_preparation_input_identities.csv"),
  show_col_types = FALSE
)
frame_integrity <- readr::read_csv(
  file.path(source_dir, "H07_preparation_frame_integrity.csv"),
  show_col_types = FALSE
)
sample_support <- readr::read_csv(
  file.path(source_dir, "H07_preparation_sample_support.csv"),
  show_col_types = FALSE
)
diagnostic_summary <- readr::read_csv(
  file.path(source_dir, "H07_preparation_diagnostic_summary.csv"),
  show_col_types = FALSE
)
pattern_summary <- readr::read_csv(
  file.path(source_dir, "H07_preparation_pattern_summary.csv"),
  show_col_types = FALSE
)
metric011_summary <- readr::read_csv(
  file.path(
    root,
    "artifacts/12_manifests/H07/H07_METRIC-011_reconciliation_summary.csv"
  ),
  show_col_types = FALSE
)
scientific_contract_pass <- all(input_identities$identity_status == "PASS") &&
  all(frame_integrity$frame_identity == "PASS") &&
  all(frame_integrity$schema_complete) &&
  all(frame_integrity$duplicate_row_keys == 0L) &&
  all(frame_integrity$latitude_constant_within_site) &&
  all(frame_integrity$stored_sample_counts_match) &&
  all(frame_integrity$overall_status == "PASS") &&
  identical(
    range(sample_support$participants[sample_support$placement == "near_eye"]),
    c(139, 141)
  ) &&
  identical(
    range(sample_support$participant_days[sample_support$placement == "near_eye"]),
    c(655, 816)
  ) &&
  identical(
    range(sample_support$participants[sample_support$placement == "chest"]),
    c(153, 154)
  ) &&
  identical(
    range(sample_support$participant_days[sample_support$placement == "chest"]),
    c(743, 902)
  ) &&
  all(sample_support$participant_days == sample_support$observations) &&
  diagnostic_summary$basis_dimension_flags[
    diagnostic_summary$placement == "near_eye"
  ] == 3 &&
  diagnostic_summary$basis_dimension_flags[
    diagnostic_summary$placement == "chest"
  ] == 1 &&
  sum(
    pattern_summary$derivative_defined_pattern &
      pattern_summary$placement == "near_eye"
  ) == 6L &&
  sum(
    pattern_summary$derivative_defined_pattern &
      pattern_summary$placement == "chest"
  ) == 7L &&
  all(metric011_summary$status == "PASS") &&
  metric011_summary$observed[
    metric011_summary$check_id == "SCIENTIFIC_CONCLUSION_CHANGED"
  ] == "FALSE"
add_check(
  "scientific contract",
  "samples diagnostics classifications and METRIC-011",
  scientific_contract_pass,
  TRUE,
  scientific_contract_pass
)

formula_registry <- readr::read_csv(
  file.path(source_dir, "H07_preparation_formula_registry.csv"),
  show_col_types = FALSE
)
normalize_formula <- function(x) gsub("[[:space:]]+", " ", trimws(x))
expected_formulas <- c(
  'response_value ~ s(site, bs = "re") + s(site_participant, bs = "re")',
  paste(
    'response_value ~ abs_latitude_deg * photoperiod_hours +',
    's(site, bs = "re") + s(site_participant, bs = "re")'
  ),
  paste(
    'response_value ~ te(abs_latitude_deg, photoperiod_hours,',
    'k = c(4, 5), bs = c("tp", "tp")) +',
    's(site, bs = "re") + s(site_participant, bs = "re")'
  ),
  paste(
    'response_value ~ te(abs_latitude_deg, photoperiod_hours,',
    'k = c(5, 8), bs = c("tp", "tp")) +',
    's(site, bs = "re") + s(site_participant, bs = "re")'
  ),
  paste(
    'response_value ~ te(abs_latitude_deg, photoperiod_hours,',
    'k = c(4, 5), bs = c("tp", "tp")) + site +',
    's(site_participant, bs = "re")'
  ),
  paste(
    'response_value ~ photoperiod_hours + s(site, bs = "re") +',
    's(site_participant, bs = "re")'
  ),
  paste(
    'response_value ~ s(photoperiod_hours, k = 6, bs = "tp") +',
    's(site, bs = "re") + s(site_participant, bs = "re")'
  ),
  paste(
    'response_value ~ s(photoperiod_hours, k = 10, bs = "tp") +',
    's(site, bs = "re") + s(site_participant, bs = "re")'
  ),
  paste(
    'response_value ~ s(photoperiod_hours, k = 6, bs = "tp") + site +',
    's(site_participant, bs = "re")'
  )
)
formula_pass <- nrow(formula_registry) == 9L &&
  !anyDuplicated(formula_registry$model_id) &&
  identical(
    normalize_formula(formula_registry$formula),
    normalize_formula(expected_formulas)
  )
add_check(
  "scientific contract",
  "exact nine-model formula registry",
  nrow(formula_registry),
  9L,
  formula_pass
)

figure_qa <- readr::read_csv(
  file.path(root, "artifacts/12_manifests/H07/H07_figure_readability_qa.csv"),
  show_col_types = FALSE
)
prep_qa <- figure_qa[
  figure_qa$figure_id %in% expected_png_ids,
  ,
  drop = FALSE
]
figure_contract_pass <- nrow(prep_qa) == 2L &&
  all(prep_qa$overall_status == "PASS") &&
  all(prep_qa$visual_status == "PASS") &&
  all(prep_qa$typography_status == "PASS_BY_CALCULATION") &&
  all(prep_qa$intended_display_width_mm == 170) &&
  all(prep_qa$effective_final_essential_text_pt >= 7) &&
  all(prep_qa$effective_final_central_text_pt >= 7)
write_evidence(prep_qa, "figure_170mm_contract_replay.csv")
add_check(
  "figure contract",
  "two 170-mm figures at least 7 pt",
  nrow(prep_qa),
  2L,
  figure_contract_pass
)

manifest_path <- file.path(
  root,
  "artifacts/12_manifests/H07/H07_preparation_report_manifest.csv"
)
manifest <- read.csv(manifest_path, check.names = FALSE)
manifest_paths <- file.path(root, manifest$path)
manifest_exists <- file.exists(manifest_paths) & !dir.exists(manifest_paths)
manifest_sha <- rep(NA_character_, nrow(manifest))
manifest_bytes <- rep(NA_real_, nrow(manifest))
manifest_sha[manifest_exists] <- vapply(
  manifest_paths[manifest_exists],
  sha256_file,
  character(1)
)
manifest_bytes[manifest_exists] <- unname(file.info(manifest_paths[manifest_exists])$size)
manifest_exact <- manifest_exists &
  manifest_sha == manifest$sha256 &
  manifest_bytes == as.numeric(manifest$bytes)
manifest_replay <- data.frame(
  path = manifest$path,
  expected_sha256 = manifest$sha256,
  observed_sha256 = manifest_sha,
  expected_bytes = manifest$bytes,
  observed_bytes = manifest_bytes,
  exact = manifest_exact,
  stringsAsFactors = FALSE
)
write_evidence(manifest_replay, "live_manifest_replay.csv")
add_check(
  "manifest",
  "unique non-circular fully live-exact manifest",
  paste(nrow(manifest), sum(manifest_exact), anyDuplicated(manifest$path), sep = "/"),
  "1235/1235/0",
  nrow(manifest) == 1235L &&
    all(manifest_exact) &&
    !anyDuplicated(manifest$path) &&
    !"artifacts/12_manifests/H07/H07_preparation_report_manifest.csv" %in%
      manifest$path
)

source_qmd_raw <- readBin(qmd_path, "raw", n = file.info(qmd_path)$size)
build_qmd_path <- file.path(
  root,
  "_build/nathealth/audit/hypotheses/H07/H07_analysis_preparation.qmd"
)
build_qmd_raw <- readBin(
  build_qmd_path,
  "raw",
  n = file.info(build_qmd_path)$size
)
add_check(
  "preservation",
  "authoring and build QMDs byte-identical",
  sha256_file(build_qmd_path),
  sha256_file(qmd_path),
  identical(source_qmd_raw, build_qmd_raw)
)

cleanup <- read.csv(
  file.path(evidence_dir, "canonical_cleanup_preqa.csv"),
  check.names = FALSE
)
add_check(
  "canonical cleanup",
  "exact 16 historical paths remain absent",
  paste(sum(cleanup$status == "PASS_ABSENT"), nrow(cleanup), sep = "/"),
  "16/16",
  nrow(cleanup) == 16L && all(cleanup$status == "PASS_ABSENT")
)

build_delta <- read.csv(
  file.path(old_evidence, "build_delta_posthelper.csv"),
  check.names = FALSE
)
add_check(
  "build integration",
  "classified build delta",
  paste(sum(build_delta$status == "PASS"), nrow(build_delta), sep = "/"),
  "21/21",
  nrow(build_delta) == 21L && all(build_delta$status == "PASS")
)

write_evidence(checks, "static_acceptance_checks.csv")
failures <- checks[checks$status != "PASS", , drop = FALSE]
write_evidence(failures, "static_acceptance_failures.csv")
if (nrow(failures)) {
  print(failures)
  stop("Order 53a static replay failed.")
}

cat(
  sprintf(
    "ORDER53A_STATIC=PASS checks=%d/%d tables=%d png=%d mermaid=%d links=%d controls=%d headers=%d manifest=%d/%d semantic=%d/%d/%d/%d\n",
    nrow(checks),
    nrow(checks),
    length(table_ids),
    length(png_ids),
    length(mermaid_nodes),
    sum(applicable),
    sum(!applicable),
    nrow(header_audit),
    sum(manifest_exact),
    nrow(manifest),
    semantic_summary$table_count,
    semantic_summary$id_count,
    semantic_summary$headers_count,
    semantic_summary$total_substitutions
  )
)
