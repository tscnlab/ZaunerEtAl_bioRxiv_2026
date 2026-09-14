#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE, warn = 2)

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

evidence_relative <-
  "audit/hypotheses/H07/report018_order53_companion_render"
evidence_dir <- file.path(root, evidence_relative)
semantic_dir <- normalizePath(
  Sys.getenv("GT_HTML_SEMANTIC_AUDIT_DIR"),
  winslash = "/",
  mustWork = TRUE
)
qmd_relative <- "audit/hypotheses/H07/H07_analysis_preparation.qmd"
qmd_path <- file.path(root, qmd_relative)
html_relative <- paste0(
  "_build/nathealth/audit/hypotheses/H07/",
  "H07_analysis_preparation.html"
)
html_path <- file.path(root, html_relative)
build_root <- file.path(root, "_build/nathealth")

stopifnot(
  dir.exists(evidence_dir),
  dir.exists(semantic_dir),
  file.exists(qmd_path),
  file.exists(html_path)
)

sha256_file <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
}

hash_text <- function(value) {
  digest::digest(enc2utf8(value), algo = "sha256", serialize = FALSE)
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
      status = ifelse(isTRUE(pass), "PASS", "FAIL"),
      stringsAsFactors = FALSE
    )
  )
}

engine <- new.env(parent = globalenv())
sys.source(
  file.path(root, "scripts/report_harmonization/repair_gt_html_semantics.R"),
  envir = engine
)

summary_path <- file.path(
  semantic_dir,
  "gt_html_semantic_post_render_summary.csv"
)
semantic_summary <- readr::read_csv(summary_path, show_col_types = FALSE)
ledger_path <- file.path(semantic_dir, semantic_summary$ledger_file)
ledger <- readr::read_csv(ledger_path, show_col_types = FALSE)
final_raw <- engine$read_file_raw(html_path)
reversed_raw <- engine$apply_raw_replacements(final_raw, ledger, reverse = TRUE)
reapplied_raw <- engine$apply_raw_replacements(
  reversed_raw,
  ledger,
  reverse = FALSE
)

semantic_reverse <- data.frame(
  check = c(
    "summary post hash equals final HTML",
    "reverse hash equals pre-hook hash",
    "forward reapplication equals final HTML",
    "ledger rows equal substitutions",
    "ledger IDs equal summary IDs",
    "ledger headers equal summary headers"
  ),
  observed = c(
    engine$sha256_raw(final_raw),
    engine$sha256_raw(reversed_raw),
    engine$sha256_raw(reapplied_raw),
    nrow(ledger),
    sum(ledger$attribute == "id"),
    sum(ledger$attribute == "headers")
  ),
  expected = c(
    semantic_summary$post_sha256,
    semantic_summary$pre_sha256,
    semantic_summary$post_sha256,
    semantic_summary$total_substitutions,
    semantic_summary$id_count,
    semantic_summary$headers_count
  ),
  stringsAsFactors = FALSE
)
semantic_reverse$status <- ifelse(
  semantic_reverse$observed == semantic_reverse$expected,
  "PASS",
  "FAIL"
)
write_evidence(semantic_reverse, "semantic_reverse_audit.csv")
add_check(
  "semantics",
  "reversal and reapplication",
  sum(semantic_reverse$status == "PASS"),
  nrow(semantic_reverse),
  all(semantic_reverse$status == "PASS") && identical(final_raw, reapplied_raw)
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
    "normalized DOM excluding repaired gt attributes",
    "whole-document visible text",
    "main visible text and values",
    "element tag sequence",
    "link target sequence",
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
write_evidence(semantic_invariance, "semantic_invariance_audit.csv")
add_check(
  "semantics",
  "visible and structural invariance",
  sum(semantic_invariance$status == "PASS"),
  nrow(semantic_invariance),
  all(semantic_invariance$status == "PASS")
)

# Reparse because the normalizer mutates its supplied DOM.
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
table_audit <- do.call(rbind, lapply(seq_along(table_endpoints), function(index) {
  endpoint <- table_endpoints[[index]]
  table <- rvest::html_element(endpoint, "table.gt_table")
  caption <- rvest::html_element(endpoint, "figcaption.quarto-float-caption")
  data.frame(
    order = index,
    endpoint = table_ids[[index]],
    native_gt_count = length(rvest::html_elements(endpoint, "table.gt_table")),
    caption_count = length(rvest::html_elements(
      endpoint,
      "figcaption.quarto-float-caption"
    )),
    caption = clean_text(caption),
    rows = length(rvest::html_elements(table, "tr")),
    header_cells = length(rvest::html_elements(table, "th")),
    body_cells = length(rvest::html_elements(table, "td")),
    status = "PASS",
    stringsAsFactors = FALSE
  )
}))
table_audit$status <- ifelse(
  table_audit$native_gt_count == 1L &
    table_audit$caption_count == 1L &
    nzchar(table_audit$caption),
  "PASS",
  "FAIL"
)
write_evidence(table_audit, "table_endpoint_audit.csv")
add_check(
  "reader structure",
  "native gt table order and captions",
  paste(table_ids, collapse = "|"),
  paste(expected_tables, collapse = "|"),
  identical(table_ids, expected_tables) &&
    length(table_ids) == 21L &&
    all(table_audit$status == "PASS")
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
write_evidence(png_rows, "png_figure_endpoint_audit.csv")
add_check(
  "reader structure",
  "two accepted PNG figures",
  paste(png_ids, collapse = "|"),
  paste(expected_png_ids, collapse = "|"),
  identical(png_ids, expected_png_ids) && all(png_rows$status == "PASS")
)

mermaid_nodes <- rvest::html_elements(post_main, "pre.mermaid.mermaid-js")
mermaid_text <- if (length(mermaid_nodes)) clean_text(mermaid_nodes[[1L]]) else ""
mermaid_audit <- data.frame(
  endpoint = "fig-h07-preparation-map",
  mermaid_nodes = length(mermaid_nodes),
  direction = ifelse(grepl("^flowchart TD", mermaid_text), "TD", ""),
  node_text_sha256 = hash_text(mermaid_text),
  status = ifelse(
    length(mermaid_nodes) == 1L && grepl("^flowchart TD", mermaid_text),
    "PASS",
    "FAIL"
  ),
  stringsAsFactors = FALSE
)
write_evidence(mermaid_audit, "mermaid_endpoint_audit.csv")
add_check(
  "reader structure",
  "one top-down Mermaid",
  paste(mermaid_audit$mermaid_nodes, mermaid_audit$direction, sep = "/"),
  "1/TD",
  mermaid_audit$status == "PASS"
)

all_ids <- rvest::html_attr(rvest::html_elements(post_document, "[id]"), "id")
all_ids <- all_ids[!is.na(all_ids) & nzchar(all_ids)]
duplicate_ids <- unique(all_ids[duplicated(all_ids)])
duplicate_id_audit <- data.frame(
  document_ids = length(all_ids),
  unique_document_ids = length(unique(all_ids)),
  duplicate_ids = length(duplicate_ids),
  duplicate_values = paste(duplicate_ids, collapse = " | "),
  status = ifelse(length(duplicate_ids) == 0L, "PASS", "FAIL"),
  stringsAsFactors = FALSE
)
write_evidence(duplicate_id_audit, "duplicate_id_audit.csv")
add_check(
  "semantics",
  "unique document IDs",
  length(duplicate_ids),
  0L,
  length(duplicate_ids) == 0L
)

header_rows <- lapply(table_endpoints, function(endpoint) {
  endpoint_id <- rvest::html_attr(endpoint, "id")
  table <- rvest::html_element(endpoint, "table.gt_table")
  nodes <- rvest::html_elements(table, "[headers]")
  do.call(rbind, lapply(nodes, function(node) {
    tokens <- strsplit(trimws(rvest::html_attr(node, "headers")), "[[:space:]]+")[[1L]]
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
write_evidence(header_audit, "table_header_reference_audit.csv")
add_check(
  "semantics",
  "table header references",
  sum(header_audit$status == "PASS"),
  nrow(header_audit),
  nrow(header_audit) > 0L && all(header_audit$status == "PASS")
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
  external <- grepl("^(https?|mailto|tel):", href, ignore.case = TRUE)
  path_part <- sub("[?#].*$", "", href)
  fragment <- if (grepl("#", href, fixed = TRUE)) {
    URLdecode(sub("^[^#]*#", "", href))
  } else {
    ""
  }
  if (external) {
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
  forbidden <- !external && (
    grepl("[.]qmd($|[?#])", href, ignore.case = TRUE) ||
      grepl("file://", href, fixed = TRUE) ||
      grepl("/Users/", href, fixed = TRUE)
  )
  data.frame(
    order = index,
    link_text = main_link_text[[index]],
    href = href,
    resolved_path = resolved,
    target_exists = target_exists,
    fragment = fragment,
    fragment_resolves_once = fragment_ok,
    forbidden_target = forbidden,
    status = ifelse(
      target_exists && fragment_ok && !forbidden,
      "PASS",
      "FAIL"
    ),
    stringsAsFactors = FALSE
  )
})
link_audit <- do.call(rbind, link_rows)
write_evidence(link_audit, "reader_link_audit.csv")
add_check(
  "reader links",
  "all reader links resolve",
  sum(link_audit$status == "PASS"),
  nrow(link_audit),
  all(link_audit$status == "PASS")
)

result_href <- "../../../notebooks/hypotheses/H07.html"
result_links <- link_audit[startsWith(link_audit$href, result_href), , drop = FALSE]
add_check(
  "reader links",
  "dynamic result links",
  paste(sort(result_links$href), collapse = "|"),
  paste(sort(c(
    rep(result_href, 2L),
    paste0(result_href, "#h07-preregistration-deviations")
  )), collapse = "|"),
  identical(
    sort(result_links$href),
    sort(c(
      rep(result_href, 2L),
      paste0(result_href, "#h07-preregistration-deviations")
    ))
  )
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
reader_phrase_audit <- data.frame(
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
reader_phrase_audit$status <- ifelse(
  reader_phrase_audit$present,
  "PASS",
  "FAIL"
)
write_evidence(reader_phrase_audit, "reader_phrase_audit.csv")
add_check(
  "scientific contract",
  "required reader phrases",
  sum(reader_phrase_audit$present),
  length(required_reader_phrases),
  all(reader_phrase_audit$present)
)

site_names <- c(
  "Borås (SE)", "Delft (NL)", "Dortmund (DE)", "Tübingen (DE)",
  "Munich (DE)", "Madrid (ES)", "Izmir (TR)", "San José (CR)",
  "Kumasi (GH)"
)
site_audit <- data.frame(
  site = site_names,
  present = vapply(site_names, grepl, logical(1), x = main_text, fixed = TRUE),
  stringsAsFactors = FALSE
)
site_audit$status <- ifelse(site_audit$present, "PASS", "FAIL")
write_evidence(site_audit, "country_site_audit.csv")
add_check(
  "reader structure",
  "country-coded sites",
  sum(site_audit$present),
  9L,
  all(site_audit$present)
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
  "embedded execution defects",
  paste(embedded_defects, unresolved_crossrefs, raw_trace, sep = "/"),
  "0/FALSE/FALSE",
  embedded_defects == 0L && !unresolved_crossrefs && !raw_trace
)
add_check(
  "reader structure",
  "companion deviation anchor",
  sum(all_ids == "h07-preparation-preregistration-deviations"),
  1L,
  sum(all_ids == "h07-preparation-preregistration-deviations") == 1L
)

source_contract <- c(
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
source_dir <- file.path(root, "artifacts/11_source_data/H07/preparation")
source_rows <- data.frame(
  file = names(source_contract),
  expected_rows = unname(source_contract),
  observed_rows = vapply(
    names(source_contract),
    function(filename) nrow(readr::read_csv(
      file.path(source_dir, filename),
      show_col_types = FALSE
    )),
    integer(1)
  ),
  stringsAsFactors = FALSE
)
source_rows$status <- ifelse(
  source_rows$expected_rows == source_rows$observed_rows,
  "PASS",
  "FAIL"
)
write_evidence(source_rows, "source_data_row_contract_audit.csv")
add_check(
  "scientific contract",
  "source-data row contracts",
  sum(source_rows$status == "PASS"),
  nrow(source_rows),
  all(source_rows$status == "PASS")
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
scientific_pass <- all(input_identities$identity_status == "PASS") &&
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
  "frames samples diagnostics classifications and METRIC-011",
  scientific_pass,
  TRUE,
  scientific_pass
)

formula_registry <- readr::read_csv(
  file.path(source_dir, "H07_preparation_formula_registry.csv"),
  show_col_types = FALSE
)
normalize_formula <- function(x) gsub("[[:space:]]+", " ", trimws(x))
expected_formulas <- c(
  'response_value ~ s(site, bs = "re") + s(site_participant, bs = "re")',
  paste('response_value ~ abs_latitude_deg * photoperiod_hours +',
        's(site, bs = "re") + s(site_participant, bs = "re")'),
  paste('response_value ~ te(abs_latitude_deg, photoperiod_hours,',
        'k = c(4, 5), bs = c("tp", "tp")) +',
        's(site, bs = "re") + s(site_participant, bs = "re")'),
  paste('response_value ~ te(abs_latitude_deg, photoperiod_hours,',
        'k = c(5, 8), bs = c("tp", "tp")) +',
        's(site, bs = "re") + s(site_participant, bs = "re")'),
  paste('response_value ~ te(abs_latitude_deg, photoperiod_hours,',
        'k = c(4, 5), bs = c("tp", "tp")) + site +',
        's(site_participant, bs = "re")'),
  paste('response_value ~ photoperiod_hours + s(site, bs = "re") +',
        's(site_participant, bs = "re")'),
  paste('response_value ~ s(photoperiod_hours, k = 6, bs = "tp") +',
        's(site, bs = "re") + s(site_participant, bs = "re")'),
  paste('response_value ~ s(photoperiod_hours, k = 10, bs = "tp") +',
        's(site, bs = "re") + s(site_participant, bs = "re")'),
  paste('response_value ~ s(photoperiod_hours, k = 6, bs = "tp") + site +',
        's(site_participant, bs = "re")')
)
formula_pass <- nrow(formula_registry) == 9L &&
  !anyDuplicated(formula_registry$model_id) &&
  identical(
    normalize_formula(formula_registry$formula),
    normalize_formula(expected_formulas)
  )
add_check(
  "scientific contract",
  "exact formula registry",
  nrow(formula_registry),
  9L,
  formula_pass
)

qa <- readr::read_csv(
  file.path(root, "artifacts/12_manifests/H07/H07_figure_readability_qa.csv"),
  show_col_types = FALSE
)
prep_qa <- qa[qa$figure_id %in% expected_png_ids, , drop = FALSE]
figure_qa_pass <- nrow(prep_qa) == 2L &&
  all(prep_qa$overall_status == "PASS") &&
  all(prep_qa$visual_status == "PASS") &&
  all(prep_qa$typography_status == "PASS_BY_CALCULATION") &&
  all(prep_qa$intended_display_width_mm == 170) &&
  all(prep_qa$effective_final_essential_text_pt >= 7) &&
  all(prep_qa$effective_final_central_text_pt >= 7)
write_evidence(prep_qa, "figure_final_size_typography_audit.csv")
add_check(
  "figure contract",
  "170 mm typography and historical visual QA",
  nrow(prep_qa),
  2L,
  figure_qa_pass
)

manifest_path <- file.path(
  root,
  "artifacts/12_manifests/H07/H07_preparation_report_manifest.csv"
)
manifest <- readr::read_csv(manifest_path, show_col_types = FALSE)
manifest_files <- file.path(root, manifest$path)
manifest_exists <- file.exists(manifest_files) & !dir.exists(manifest_files)
manifest_current_sha <- rep(NA_character_, nrow(manifest))
manifest_current_bytes <- rep(NA_real_, nrow(manifest))
manifest_current_sha[manifest_exists] <- vapply(
  manifest_files[manifest_exists],
  sha256_file,
  character(1)
)
manifest_current_bytes[manifest_exists] <- as.numeric(
  file.info(manifest_files[manifest_exists])$size
)
manifest_exact <- manifest_exists &
  manifest_current_sha == manifest$sha256 &
  manifest_current_bytes == manifest$bytes
manifest_audit <- data.frame(
  path = manifest$path,
  recorded_sha256 = manifest$sha256,
  observed_sha256 = manifest_current_sha,
  recorded_bytes = manifest$bytes,
  observed_bytes = manifest_current_bytes,
  exact = manifest_exact,
  stringsAsFactors = FALSE
)
write_evidence(manifest_audit, "live_manifest_audit.csv")
manifest_self <- "artifacts/12_manifests/H07/H07_preparation_report_manifest.csv"
add_check(
  "helper manifest",
  "unique live-exact non-circular rows",
  paste(nrow(manifest), sum(manifest_exact), sum(manifest$path == manifest_self), sep = "/"),
  "1235/1235/0",
  nrow(manifest) == 1235L &&
    !anyDuplicated(manifest$path) &&
    all(manifest_exact) &&
    !manifest_self %in% manifest$path
)

required_manifest_paths <- c(
  qmd_relative,
  "_build/nathealth/audit/hypotheses/H07/H07_analysis_preparation.qmd",
  html_relative,
  "notebooks/hypotheses/H07.qmd",
  "_build/nathealth/notebooks/hypotheses/H07.html",
  "_quarto-nathealth.yml"
)
add_check(
  "helper manifest",
  "current result and companion identities present",
  sum(required_manifest_paths %in% manifest$path),
  length(required_manifest_paths),
  all(required_manifest_paths %in% manifest$path)
)

historical_relative <- "audit/hypotheses/H07/H07_analysis_preparation.html"
historical_asset_prefix <-
  "audit/hypotheses/H07/H07_analysis_preparation_files/"
historical_exists <- file.exists(file.path(root, historical_relative))
historical_manifest_present <- historical_relative %in% manifest$path
historical_asset_rows <- sum(startsWith(manifest$path, historical_asset_prefix))
add_check(
  "protected preservation",
  "source-side historical companion HTML",
  paste(historical_exists, historical_manifest_present, sep = "/"),
  "TRUE/TRUE",
  historical_exists && historical_manifest_present
)
add_check(
  "protected preservation",
  "source-side historical companion asset tree in live manifest",
  historical_asset_rows,
  15L,
  historical_asset_rows == 15L
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
  "helper manifest",
  "source-identical build QMD",
  sha256_file(build_qmd_path),
  sha256_file(qmd_path),
  identical(source_qmd_raw, build_qmd_raw)
)

accepted_pins <- data.frame(
  path = c(
    "notebooks/hypotheses/H07.qmd",
    "_build/nathealth/notebooks/hypotheses/H07.html",
    "audit/hypotheses/H07/H07_analysis_preparation.qmd",
    "_quarto-nathealth.yml",
    "scripts/hypotheses/H07/build_h07_preparation_report_manifest.R",
    "tests/hypotheses/H07/test_h07_preparation_report.R",
    "tests/hypotheses/H07/test_h07_stage3_reader_report.R",
    "scripts/report_harmonization/post_render_gt_html_semantics.R",
    "scripts/report_harmonization/repair_gt_html_semantics.R",
    "audit/report_harmonization/phase4_corpus_manifest.csv",
    "audit/handoffs/H07_worker_handoff.md",
    "renv.lock"
  ),
  expected_sha256 = c(
    "c779c57ffc64a15c82e519ef38e865a39108a6563d82e408e4522253c61e8226",
    "7814860467f71311c56e22960e757059524ccc3890b0721708eda7a5c661ab40",
    "a6c05e81333bb612e99ef431f42f47860ac26b6d5c0f0f44ecbce019ee470d1b",
    "80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3",
    "9e961ec8746f512f34d1330b227118e407a75260168619a6457413a3ecb74508",
    "89fd3eaa2f4f9928234280844e480ff5b863e104366af17675fe36366c456558",
    "84e96a523bf1d9051be8abe3cabbef9837dfe98ab978a30bd846d0f2d728cd17",
    "28c1105840834e95a37f84eaded9a2c595b9febd568fbc763daef247a53d7205",
    "7c949930fec862a4ce783c28d0256d36cb45de7c017bd9fcbb7cb910599463d1",
    "73f1a371f8352f1baf69d38f1613de1a662112642370b0cc89798b4d6d469334",
    "95351007249f187a5c6650e951a1ad1078923ca35c628d730334866cf3593a3e",
    "3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350"
  ),
  stringsAsFactors = FALSE
)
accepted_pins$observed_sha256 <- vapply(
  file.path(root, accepted_pins$path),
  sha256_file,
  character(1)
)
accepted_pins$status <- ifelse(
  accepted_pins$observed_sha256 == accepted_pins$expected_sha256,
  "PASS",
  "FAIL"
)
write_evidence(accepted_pins, "accepted_pin_preservation_audit.csv")
add_check(
  "protected preservation",
  "accepted result source HTML profile tests hooks handoff and lock",
  sum(accepted_pins$status == "PASS"),
  nrow(accepted_pins),
  all(accepted_pins$status == "PASS")
)

read_inventory <- function(name) read_evidence(name)
classify_inventory <- function(pre, post) {
  merged <- merge(
    pre,
    post,
    by = "relative_path",
    all = TRUE,
    suffixes = c("_pre", "_post")
  )
  merged$delta <- ifelse(
    is.na(merged$sha256_pre),
    "ADDED",
    ifelse(
      is.na(merged$sha256_post),
      "REMOVED",
      ifelse(
        merged$sha256_pre != merged$sha256_post,
        "CHANGED_CONTENT",
        ifelse(
          merged$modified_utc_pre != merged$modified_utc_post,
          "MTIME_ONLY",
          "UNCHANGED"
        )
      )
    )
  )
  merged
}

build_pre <- read_inventory("build_inventory_prerender.csv")
build_post <- read_inventory("build_inventory_posthelper.csv")
build_delta <- classify_inventory(build_pre, build_post)
build_delta <- build_delta[build_delta$delta != "UNCHANGED", , drop = FALSE]
build_delta$classification <- "UNCLASSIFIED"
build_delta$source_relative_path <- ""
build_delta$source_identical <- NA

artifact_rows <- startsWith(build_delta$relative_path, "_build/nathealth/artifacts/")
build_delta$classification[artifact_rows] <- "SOURCE_IDENTICAL_RESOURCE_COPY"
build_delta$source_relative_path[artifact_rows] <- sub(
  "^_build/nathealth/",
  "",
  build_delta$relative_path[artifact_rows]
)
artifact_sources <- file.path(
  root,
  build_delta$source_relative_path[artifact_rows]
)
build_delta$source_identical[artifact_rows] <-
  file.exists(artifact_sources) &
  vapply(artifact_sources, sha256_file, character(1)) ==
    build_delta$sha256_post[artifact_rows]

target_html_row <- build_delta$relative_path == html_relative &
  build_delta$delta == "CHANGED_CONTENT"
build_delta$classification[target_html_row] <- "EXPECTED_COMPANION_HTML_TRANSITION"
target_qmd_row <- build_delta$relative_path ==
  "_build/nathealth/audit/hypotheses/H07/H07_analysis_preparation.qmd" &
  build_delta$delta == "CHANGED_CONTENT"
build_delta$classification[target_qmd_row] <- "SOURCE_IDENTICAL_BUILD_QMD"
site_rows <- build_delta$relative_path %in% c(
  "_build/nathealth/search.json",
  "_build/nathealth/sitemap.xml"
) & build_delta$delta == "CHANGED_CONTENT"
build_delta$classification[site_rows] <- "EXPECTED_SITE_INTEGRATION"
mtime_rows <- build_delta$delta == "MTIME_ONLY"
build_delta$classification[mtime_rows] <- "BYTE_IDENTICAL_MTIME_ONLY"
build_delta$status <- ifelse(
  build_delta$classification != "UNCLASSIFIED" &
    (!artifact_rows | build_delta$source_identical),
  "PASS",
  "FAIL"
)
write_evidence(build_delta, "build_delta_posthelper.csv")
add_check(
  "build delta",
  "classified companion build changes",
  sum(build_delta$status == "PASS"),
  nrow(build_delta),
  all(build_delta$status == "PASS") &&
    sum(target_html_row) == 1L &&
    sum(target_qmd_row) == 1L &&
    !any(build_delta$delta == "REMOVED")
)

protected_pre <- read_inventory("protected_inventory_prerender.csv")
protected_post <- read_inventory("protected_inventory_posthelper.csv")
protected_delta <- classify_inventory(protected_pre, protected_post)
protected_delta <- protected_delta[
  protected_delta$delta != "UNCHANGED",
  ,
  drop = FALSE
]
write_evidence(protected_delta, "protected_delta_posthelper.csv")
removed_protected <- protected_delta[
  protected_delta$delta == "REMOVED",
  ,
  drop = FALSE
]
add_check(
  "protected preservation",
  "removed protected paths",
  nrow(removed_protected),
  0L,
  nrow(removed_protected) == 0L
)

reader_test <- file.path(
  root,
  "tests/hypotheses/H07/test_h07_stage3_reader_report.R"
)
test_output <- system2(
  file.path(R.home("bin"), "Rscript"),
  c("--vanilla", reader_test),
  stdout = TRUE,
  stderr = TRUE,
  env = sprintf("NATHEALTH_PROJECT_ROOT=%s", root)
)
test_status <- attr(test_output, "status")
test_pass <- identical(test_status, NULL) && any(grepl(
  "H07 Stage 3 reader-report checks passed",
  test_output,
  fixed = TRUE
))
reader_test_audit <- data.frame(
  test = "tests/hypotheses/H07/test_h07_stage3_reader_report.R",
  sha256 = sha256_file(reader_test),
  exit_status = if (is.null(test_status)) 0L else test_status,
  expected_message_present = test_pass,
  output = paste(test_output, collapse = " | "),
  status = ifelse(test_pass, "PASS", "FAIL"),
  stringsAsFactors = FALSE
)
write_evidence(reader_test_audit, "result_reader_test_audit.csv")
add_check(
  "tests",
  "unchanged result reader test",
  reader_test_audit$exit_status,
  0L,
  test_pass
)

held_test <- file.path(
  root,
  "tests/hypotheses/H07/test_h07_preparation_report.R"
)
held_test_audit <- data.frame(
  test = "tests/hypotheses/H07/test_h07_preparation_report.R",
  sha256 = sha256_file(held_test),
  expected_sha256 =
    "89fd3eaa2f4f9928234280844e480ff5b863e104366af17675fe36366c456558",
  executed = FALSE,
  status = ifelse(
    sha256_file(held_test) ==
      "89fd3eaa2f4f9928234280844e480ff5b863e104366af17675fe36366c456558",
    "PASS",
    "FAIL"
  ),
  stringsAsFactors = FALSE
)
write_evidence(held_test_audit, "held_preparation_test_audit.csv")
add_check(
  "tests",
  "held preparation test unchanged and unexecuted",
  paste(held_test_audit$sha256, held_test_audit$executed, sep = "/"),
  paste(held_test_audit$expected_sha256, FALSE, sep = "/"),
  held_test_audit$status == "PASS" && !held_test_audit$executed
)

semantic_copy_paths <- c(
  file.path(evidence_dir, "gt_html_semantic_post_render_summary.csv"),
  file.path(evidence_dir, basename(ledger_path))
)
stopifnot(
  file.copy(summary_path, semantic_copy_paths[[1L]], overwrite = TRUE),
  file.copy(ledger_path, semantic_copy_paths[[2L]], overwrite = TRUE),
  sha256_file(summary_path) == sha256_file(semantic_copy_paths[[1L]]),
  sha256_file(ledger_path) == sha256_file(semantic_copy_paths[[2L]])
)

write_evidence(checks, "nonvisual_acceptance_checks.csv")
failures <- checks[checks$status == "FAIL", , drop = FALSE]
write_evidence(failures, "fail_closed_defects.csv")

cat(sprintf(
  paste0(
    "ORDER53_NONVISUAL=%s checks=%d pass=%d fail=%d tables=%d png=%d ",
    "mermaid=%d manifest=%d/%d removed_protected=%d\n"
  ),
  ifelse(nrow(failures) == 0L, "PASS", "FAIL"),
  nrow(checks),
  sum(checks$status == "PASS"),
  nrow(failures),
  nrow(table_audit),
  nrow(png_rows),
  length(mermaid_nodes),
  sum(manifest_exact),
  nrow(manifest),
  nrow(removed_protected)
))
