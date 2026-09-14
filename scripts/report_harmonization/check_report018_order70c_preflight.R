#!/usr/bin/env Rscript

# Read-only, in-memory preflight for REPORT-018 Order 70c.
# This script does not write to the candidate or production website.

options(stringsAsFactors = FALSE, warn = 2)
suppressPackageStartupMessages({
  library(digest)
  library(jsonlite)
  library(readr)
  library(xml2)
})

stopifnot(identical(as.character(getRversion()), "4.6.1"))

site_path <- "_build/nathealth/index.html"
manuscript_path <- paste0(
  "manuscript/R0_NatHealth/_output/",
  "ZaunerEtAl2026_NatHealth_phase3_brown.html"
)
implementation_path <- paste0(
  "audit/report_harmonization/",
  "nathealth_final_landing_integration_2026_09_02/",
  "order70_integrate_verify_promote.R"
)
output_path <- paste0(
  "audit/report_harmonization/",
  "report018_navigation_order70c_literal_selector_preflight.csv"
)

sha_file <- function(path) {
  digest(path, file = TRUE, algo = "sha256", serialize = FALSE)
}
stopifnot(
  identical(sha_file(site_path), "600b7a3d5eb244e99e841b5c4e3b6c1c7440004303fe0e9da1bc0c874add1184"),
  identical(sha_file(manuscript_path), "8fba7308cf0f06362419a144628fe91ec9a2741551c72c7014fd278d76114fac"),
  identical(sha_file(implementation_path), "5c9d894b1e337059caa3e9ebe395747e07a7269a47780abdc73669544b23b64f")
)

read_text <- function(path) {
  size <- unname(as.numeric(file.info(path)$size))
  con <- file(path, open = "rb")
  on.exit(close(con), add = TRUE)
  rawToChar(readBin(con, what = "raw", n = size))
}
count_fixed <- function(pattern, text) {
  found <- gregexpr(pattern, text, fixed = TRUE)[[1L]]
  if (identical(found[[1L]], -1L)) return(0L)
  length(found)
}
positions_expected <- function(text, token, expected, label) {
  found <- gregexpr(token, text, fixed = TRUE)[[1L]]
  observed <- if (identical(found[[1L]], -1L)) 0L else length(found)
  if (observed != expected) stop(label, ": expected ", expected, ", observed ", observed)
  unname(found)
}
find_after <- function(text, token, after, label) {
  found <- regexpr(token, substr(text, after, nchar(text)), fixed = TRUE)[[1L]]
  if (found < 1L) stop(label, " not found")
  after + found - 1L
}
extract_outer <- function(text, start_token, expected_starts, close_token, label) {
  start <- positions_expected(text, start_token, expected_starts, label)[[1L]]
  close <- find_after(text, close_token, start + nchar(start_token), paste0(label, " close"))
  substr(text, start, close + nchar(close_token) - 1L)
}
extract_inner <- function(text, open_tag, close_tag, label) {
  start <- positions_expected(text, open_tag, 1L, label)[[1L]]
  close <- find_after(text, close_tag, start + nchar(open_tag), paste0(label, " close"))
  substr(text, start + nchar(open_tag), close - 1L)
}
replace_once <- function(text, old, replacement, label) {
  if (count_fixed(old, text) != 1L) stop(label, " replacement preimage not unique")
  value <- sub(old, replacement, text, fixed = TRUE)
  stopifnot(!identical(value, text), count_fixed(old, value) == 0L)
  value
}
insert_before_once <- function(text, boundary, insertion, label) {
  if (count_fixed(boundary, text) != 1L) stop(label, " boundary not unique")
  if (count_fixed(insertion, text) != 0L) stop(label, " insertion already present")
  value <- sub(boundary, paste0(insertion, boundary), text, fixed = TRUE)
  stopifnot(
    !identical(value, text),
    count_fixed(boundary, value) == 1L,
    count_fixed(insertion, value) == 1L
  )
  value
}

site_text <- read_text(site_path)
manuscript_text <- read_text(manuscript_path)
literal_rows <- list()
add_literal <- function(context, token, expected) {
  text <- switch(context, site = site_text, manuscript = manuscript_text)
  observed <- count_fixed(token, text)
  literal_rows[[length(literal_rows) + 1L]] <<- data.frame(
    kind = "literal",
    context = context,
    expression = token,
    observed = observed,
    expected = expected,
    pass = observed == expected
  )
  stopifnot(observed == expected)
}

site_main_open <- '<main class="content column-body" id="quarto-document-content">'
manuscript_main_open <- '<main class="content page-columns page-full" id="quarto-document-content">'
for (item in list(
  list("site", site_main_open, 1L),
  list("manuscript", manuscript_main_open, 1L),
  list("site", '<meta name="author"', 1L),
  list("manuscript", '<meta name="author"', 28L),
  list("site", "</title>", 1L),
  list("manuscript", "</title>", 1L),
  list("site", '<nav id="TOC"', 1L),
  list("manuscript", '<nav id="TOC"', 1L),
  list("manuscript", '<h2 id="toc-title">Table of contents</h2>', 1L),
  list("manuscript", '<style type="text/css">div.manuscript-table,', 1L),
  list("site", "</head>", 1L),
  list("site", '<div class="modal fade" id="quarto-embedded-source-code-modal"', 1L),
  list("site", "</div> <!-- /content -->", 1L),
  list("site", '<header id="quarto-header"', 1L),
  list("site", '<footer class="footer">', 1L),
  list("site", '<nav class="page-navigation column-body">', 1L)
)) add_literal(item[[1L]], item[[2L]], item[[3L]])

manuscript_main_inner <- extract_inner(
  manuscript_text, manuscript_main_open, "</main>", "manuscript main"
)
site_main_inner <- extract_inner(site_text, site_main_open, "</main>", "site main")
candidate <- replace_once(site_text, site_main_inner, manuscript_main_inner, "main")

site_meta_start <- positions_expected(site_text, '<meta name="author"', 1L, "site author")[[1L]]
site_meta_end <- find_after(site_text, "</title>", site_meta_start, "site title") + nchar("</title>") - 1L
site_meta <- substr(site_text, site_meta_start, site_meta_end)
manuscript_author_positions <- positions_expected(
  manuscript_text, '<meta name="author"', 28L, "manuscript authors"
)
manuscript_meta_start <- manuscript_author_positions[[1L]]
manuscript_meta_end <- find_after(
  manuscript_text, "</title>", manuscript_meta_start, "manuscript title"
) + nchar("</title>") - 1L
manuscript_meta <- substr(manuscript_text, manuscript_meta_start, manuscript_meta_end)
candidate <- replace_once(candidate, site_meta, manuscript_meta, "metadata")

site_toc <- extract_outer(site_text, '<nav id="TOC"', 1L, "</nav>", "site TOC")
manuscript_toc <- extract_outer(
  manuscript_text, '<nav id="TOC"', 1L, "</nav>", "manuscript TOC"
)
stopifnot(
  count_fixed('<div class="toc-actions">', site_toc) == 1L,
  count_fixed("</nav>", site_toc) == 1L,
  count_fixed("</nav>", manuscript_toc) == 1L
)
toc_actions <- extract_outer(
  site_toc, '<div class="toc-actions">', 1L, "</div>", "site TOC actions"
)
site_toc_open_end <- find_after(site_toc, ">", 1L, "site TOC opening")
site_toc_open <- substr(site_toc, 1L, site_toc_open_end)
manuscript_toc_open_end <- find_after(manuscript_toc, ">", 1L, "manuscript TOC opening")
manuscript_toc_open <- substr(manuscript_toc, 1L, manuscript_toc_open_end)
new_toc <- replace_once(manuscript_toc, manuscript_toc_open, site_toc_open, "TOC opening")
new_toc <- replace_once(
  new_toc,
  '<h2 id="toc-title">Table of contents</h2>',
  '<h2 id="toc-title">On this page</h2>',
  "TOC title"
)
new_toc <- insert_before_once(new_toc, "</nav>", toc_actions, "TOC actions")
candidate <- replace_once(candidate, site_toc, new_toc, "TOC")

custom_style <- extract_outer(
  manuscript_text,
  '<style type="text/css">div.manuscript-table,',
  1L,
  "</style>",
  "manuscript style"
)
stopifnot(count_fixed(custom_style, site_text) == 0L)
candidate <- insert_before_once(candidate, "</head>", paste0(custom_style, "\n"), "style")

modal_start <- positions_expected(
  candidate,
  '<div class="modal fade" id="quarto-embedded-source-code-modal"',
  1L,
  "source modal"
)[[1L]]
content_close <- find_after(candidate, "</div> <!-- /content -->", modal_start, "content close")
candidate <- paste0(substr(candidate, 1L, modal_start - 1L), substr(candidate, content_close, nchar(candidate)))

site_document <- read_html(site_text)
manuscript_document <- read_html(manuscript_text)
candidate_document <- read_html(candidate)
selector_rows <- list()
add_selector <- function(context, document, xpath, expected) {
  observed <- length(xml_find_all(document, xpath))
  selector_rows[[length(selector_rows) + 1L]] <<- data.frame(
    kind = "xpath",
    context = context,
    expression = xpath,
    observed = observed,
    expected = expected,
    pass = observed == expected
  )
  stopifnot(observed == expected)
}

for (spec in list(
  list("site", site_document, "//main", 1L),
  list("site", site_document, "//nav[@id='TOC']", 1L),
  list("site", site_document, "//header[@id='quarto-header']", 1L),
  list("site", site_document, "//footer[contains(concat(' ',normalize-space(@class),' '),' footer ')]", 1L),
  list("site", site_document, "//nav[contains(concat(' ',normalize-space(@class),' '),' page-navigation ')]", 1L),
  list("site", site_document, "//meta[@name='author']", 1L),
  list("manuscript", manuscript_document, "//main", 1L),
  list("manuscript", manuscript_document, "//nav[@id='TOC']", 1L),
  list("manuscript", manuscript_document, "//meta[@name='author']", 28L),
  list("manuscript", manuscript_document, "//main//p[contains(concat(' ',normalize-space(@class),' '),' author ')]", 28L),
  list("manuscript", manuscript_document, "//table[contains(concat(' ',normalize-space(@class),' '),' gt_table ')]", 19L),
  list("manuscript", manuscript_document, "//main//img", 74L),
  list("manuscript", manuscript_document, "//main//a[starts-with(@href,'#')]", 124L),
  list("candidate", candidate_document, "//main", 1L),
  list("candidate", candidate_document, "//nav[@id='TOC']", 1L),
  list("candidate", candidate_document, "//header[@id='quarto-header']", 1L),
  list("candidate", candidate_document, "//meta[@name='author']", 28L),
  list("candidate", candidate_document, "//main//p[contains(concat(' ',normalize-space(@class),' '),' author ')]", 28L),
  list("candidate", candidate_document, "//table[contains(concat(' ',normalize-space(@class),' '),' gt_table ')]", 19L),
  list("candidate", candidate_document, "//main//img", 74L),
  list("candidate", candidate_document, "//main//a[starts-with(@href,'#')]", 124L),
  list("candidate", candidate_document, "//a[contains(translate(@href,'DOCX','docx'),'.docx')]", 1L),
  list("candidate", candidate_document, "//*[@id='fig-s6']//img", 1L),
  list("candidate", candidate_document, "//*[@id='fig-s8']//img", 1L),
  list("candidate", candidate_document, "//*[@id='fig-s12']//img", 1L),
  list("candidate", candidate_document, "//*[@id='tbl-metric-context']//img[contains(concat(' ',normalize-space(@class),' '),' metric-density-thumb ')]", 17L),
  list("candidate", candidate_document, "//nav[@id='TOC']//a", 42L),
  list("candidate", candidate_document, "//nav[@id='TOC']//a[starts-with(@href,'#')]", 39L),
  list("candidate", candidate_document, "//script", 20L)
)) add_selector(spec[[1L]], spec[[2L]], spec[[3L]], spec[[4L]])

source_author_meta <- xml_attr(xml_find_all(manuscript_document, "//meta[@name='author']"), "content")
candidate_author_meta <- xml_attr(xml_find_all(candidate_document, "//meta[@name='author']"), "content")
stopifnot(
  length(source_author_meta) == 28L,
  !anyNA(source_author_meta),
  all(nzchar(source_author_meta)),
  identical(candidate_author_meta, source_author_meta)
)

ids <- xml_attr(xml_find_all(candidate_document, "//*[@id]"), "id")
ids <- ids[!is.na(ids) & nzchar(ids)]
stopifnot(!anyDuplicated(ids))
idrefs <- c("aria-labelledby", "aria-describedby", "aria-controls", "aria-owns",
            "aria-flowto", "aria-activedescendant", "headers", "for", "list", "form")
for (attribute in idrefs) {
  nodes <- xml_find_all(candidate_document, paste0("//*[@", attribute, "]"))
  if (!length(nodes)) next
  values <- xml_attr(nodes, attribute)
  tokens <- unlist(strsplit(trimws(values), "[[:space:]]+"), use.names = FALSE)
  tokens <- tokens[nzchar(tokens)]
  stopifnot(all(vapply(tokens, function(token) sum(ids == token) == 1L, logical(1))))
}
for (attribute in c("data-bs-target", "data-target")) {
  values <- xml_attr(xml_find_all(candidate_document, paste0("//*[@", attribute, "]")), attribute)
  values <- values[!is.na(values) & startsWith(values, "#")]
  tokens <- substring(values, 2L)
  stopifnot(all(vapply(tokens, function(token) sum(ids == token) == 1L, logical(1))))
}

tables <- xml_find_all(
  candidate_document,
  "//table[contains(concat(' ',normalize-space(@class),' '),' gt_table ')]"
)
header_tokens <- character()
for (table in tables) {
  table_ids <- xml_attr(xml_find_all(table, "self::*[@id] | .//*[@id]"), "id")
  values <- xml_attr(xml_find_all(table, "self::*[@headers] | .//*[@headers]"), "headers")
  values <- values[!is.na(values) & nzchar(trimws(values))]
  tokens <- unlist(strsplit(trimws(values), "[[:space:]]+"), use.names = FALSE)
  stopifnot(all(vapply(tokens, function(token) sum(table_ids == token) == 1L, logical(1))))
  header_tokens <- c(header_tokens, tokens)
}
stopifnot(length(header_tokens) == 2762L)

expected_table_ids <- c(
  "tbl-participant-site-manuscript", "tbl-plan-brown-main-adherence",
  "tbl-plan-h01-metric-synthesis-candidate", "tbl-plan-descriptive-sample-flow",
  "tbl-near-eye-metrics", "tbl-recommendation-context",
  "tbl-plan-brown-cross-window-associations",
  "tbl-plan-h02-glasses-variation-shapley-gt-candidate",
  "tbl-plan-h02-chest-variation-shapley-gt-candidate",
  "tbl-h01-primary-publication-summary", "tbl-h07-near-results",
  "tbl-h06-primary-effects", "tbl-plan-person-level-synthesis-gt-candidate",
  "tbl-h05-near-results-a", "tbl-h05-near-results-b",
  "tbl-h08-near-eye-results", "tbl-h09-near-eye-results",
  "tbl-h10-main-results", "tbl-h11-global-tests"
)
expected_figure_ids <- c(
  "fig-study-overview", "fig-daily-architecture", "fig-activity-context",
  paste0("fig-s", 1:17)
)
stopifnot(
  all(vapply(expected_table_ids, function(id) length(xml_find_all(candidate_document, paste0("//*[@id='", id, "']"))) == 1L, logical(1))),
  all(vapply(expected_figure_ids, function(id) length(xml_find_all(candidate_document, paste0("//*[@id='", id, "']"))) == 1L, logical(1)))
)

source_main <- xml_find_first(manuscript_document, "//main")
candidate_main <- xml_find_first(candidate_document, "//main")
source_children <- xml_children(source_main)
candidate_children <- xml_children(candidate_main)
stopifnot(
  length(source_children) == length(candidate_children),
  all(vapply(seq_along(source_children), function(index) {
    identical(as.character(source_children[[index]]), as.character(candidate_children[[index]]))
  }, logical(1)))
)

site_scripts <- vapply(xml_find_all(site_document, "//script"), as.character, character(1))
candidate_scripts <- vapply(xml_find_all(candidate_document, "//script"), as.character, character(1))
stopifnot(identical(candidate_scripts, site_scripts))

brown_src <- xml_attr(xml_find_first(candidate_document, "//*[@id='fig-s6']//img"), "src")
stopifnot(startsWith(brown_src, "data:image/svg+xml;base64,"))
brown_raw <- base64_dec(sub("^[^,]+,", "", brown_src))
stopifnot(
  length(brown_raw) == 108600L,
  identical(
    digest(brown_raw, algo = "sha256", serialize = FALSE),
    "200e85cb494e28865cafe677c860ec8a6e4eb426c86c78b37819a4bd19e08653"
  )
)

result <- rbind(
  do.call(rbind, literal_rows),
  do.call(rbind, selector_rows),
  data.frame(
    kind = c("semantic", "semantic", "semantic", "semantic", "semantic"),
    context = "candidate",
    expression = c(
      "ordered_author_meta_exact", "duplicate_ids", "table_header_tokens",
      "manuscript_main_children_exact", "brown_svg_exact"
    ),
    observed = c(28L, 0L, 2762L, length(source_children), 1L),
    expected = c(28L, 0L, 2762L, length(source_children), 1L),
    pass = TRUE
  )
)
stopifnot(all(result$pass), nrow(result) == 50L)
write_csv(result, output_path, na = "")

cat(
  R.version.string, "\n",
  "digest ", as.character(packageVersion("digest")), "\n",
  "literal and selector checks: ", nrow(result), "/", nrow(result), " PASS\n",
  "author metadata: 28 ordered elements preserved exactly\n",
  "prospective transform: in-memory only; no candidate or production write\n",
  sep = ""
)
