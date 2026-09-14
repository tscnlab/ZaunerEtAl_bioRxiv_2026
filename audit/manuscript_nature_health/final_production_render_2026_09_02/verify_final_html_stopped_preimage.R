#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1L) {
  stop("Usage: verify_final_html.R <html-path>", call. = FALSE)
}
if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("R 4.6.1 is required.", call. = FALSE)
}
if (!requireNamespace("xml2", quietly = TRUE)) {
  stop("The xml2 package is required.", call. = FALSE)
}

html_path <- normalizePath(args[[1L]], mustWork = TRUE)
assert_true <- function(value, message) {
  if (!isTRUE(value)) stop(message, call. = FALSE)
}
has_class <- function(name) {
  sprintf("contains(concat(' ', normalize-space(@class), ' '), ' %s ')", name)
}

document <- xml2::read_html(html_path)
main <- xml2::xml_find_all(document, "//main[@id='quarto-document-content']")
assert_true(length(main) == 1L, "Expected exactly one manuscript main element.")

title <- trimws(xml2::xml_text(xml2::xml_find_first(document, "//title")))
assert_true(
  identical(title, "The multiscale architecture of personal light exposure"),
  "The document title is missing or changed."
)
authors <- xml2::xml_attr(
  xml2::xml_find_all(document, "//meta[@name='author']"),
  "content"
)
assert_true(length(authors) == 28L, "The complete 28-author metadata roster is missing.")
assert_true(
  identical(authors[[1L]], "Johannes Zauner") &&
    identical(authors[[28L]], "Manuel Spitschan"),
  "The author metadata order changed."
)

id_nodes <- xml2::xml_find_all(document, "//*[@id]")
ids <- xml2::xml_attr(id_nodes, "id")
assert_true(!anyNA(ids) && !anyDuplicated(ids), "The HTML contains duplicate IDs.")

expected_figures <- c(
  "fig-study-overview",
  "fig-daily-architecture",
  "fig-activity-context",
  paste0("fig-s", seq_len(17L))
)
figures <- xml2::xml_find_all(
  main,
  ".//figure[@id and starts-with(@id, 'fig-')]"
)
figure_ids <- xml2::xml_attr(figures, "id")
assert_true(
  identical(figure_ids, expected_figures),
  "Figure endpoints are missing, duplicated, or out of topic order."
)
assert_true(
  all(vapply(figures, function(x) length(xml2::xml_find_all(x, ".//img")) == 1L,
             logical(1))),
  "A manuscript figure does not contain exactly one image."
)
assert_true(
  all(vapply(figures, function(x) length(xml2::xml_find_all(x, ".//figcaption")) >= 1L,
             logical(1))),
  "A manuscript figure lacks a caption."
)
alts <- vapply(
  figures,
  function(x) xml2::xml_attr(xml2::xml_find_first(x, ".//img"), "alt"),
  character(1)
)
assert_true(all(!is.na(alts) & nzchar(trimws(alts))), "A manuscript figure lacks alt text.")

table_xpath <- paste0(".//table[", has_class("gt_table"), "]")
tables <- xml2::xml_find_all(main, table_xpath)
assert_true(length(tables) == 19L, "Expected exactly 19 accepted native gt tables.")

expected_table_containers <- c(
  "tbl-participant-site-manuscript",
  "tbl-plan-brown-main-adherence",
  "tbl-plan-h01-metric-synthesis-candidate",
  "tbl-plan-descriptive-sample-flow",
  "tbl-near-eye-metrics",
  "tbl-recommendation-context",
  "tbl-plan-brown-cross-window-associations",
  "tbl-plan-h02-glasses-variation-shapley-gt-candidate",
  "tbl-plan-h02-chest-variation-shapley-gt-candidate",
  "tbl-h01-primary-publication-summary",
  "tbl-h07-near-results",
  "tbl-h06-primary-effects",
  "tbl-plan-person-level-synthesis-gt-candidate",
  "tbl-h05-near-results-a",
  "tbl-h05-near-results-b",
  "tbl-h08-near-eye-results",
  "tbl-h09-near-eye-results",
  "tbl-h10-main-results",
  "tbl-h11-global-tests"
)
for (container in expected_table_containers) {
  endpoint <- xml2::xml_find_all(main, sprintf(".//*[@id='%s']", container))
  assert_true(length(endpoint) == 1L, sprintf("Missing or duplicate table endpoint: %s", container))
  native <- xml2::xml_find_all(endpoint, paste0(".//table[", has_class("gt_table"), "]"))
  if (xml2::xml_name(endpoint[[1L]]) == "table" &&
      grepl("(^|[[:space:]])gt_table([[:space:]]|$)", xml2::xml_attr(endpoint[[1L]], "class"))) {
    native <- endpoint
  }
  assert_true(length(native) == 1L, sprintf("Table endpoint is not one gt table: %s", container))
}

header_tokens <- 0L
for (table in tables) {
  table_header_ids <- xml2::xml_attr(xml2::xml_find_all(table, ".//th[@id]"), "id")
  header_nodes <- xml2::xml_find_all(table, ".//*[@headers]")
  token_lists <- strsplit(xml2::xml_attr(header_nodes, "headers"), "[[:space:]]+")
  token_lists <- lapply(token_lists, function(x) x[nzchar(x)])
  header_tokens <- header_tokens + sum(lengths(token_lists))
  unresolved <- unlist(lapply(token_lists, function(tokens) {
    tokens[vapply(tokens, function(token) sum(table_header_ids == token) != 1L, logical(1))]
  }))
  assert_true(length(unresolved) == 0L, "A table-header token is unresolved or nonunique.")
}
assert_true(header_tokens > 0L, "No semantic table-header tokens were found.")

fragment_hrefs <- xml2::xml_attr(
  xml2::xml_find_all(main, ".//a[starts-with(@href, '#')]"),
  "href"
)
fragment_ids <- sub("^#", "", fragment_hrefs)
fragment_ids <- fragment_ids[nzchar(fragment_ids)]
unresolved_fragments <- fragment_ids[vapply(
  fragment_ids,
  function(value) sum(ids == value) != 1L,
  logical(1)
)]
assert_true(length(unresolved_fragments) == 0L, "An internal fragment link is unresolved.")

img_sources <- xml2::xml_attr(xml2::xml_find_all(document, "//img[@src]"), "src")
assert_true(
  all(startsWith(img_sources, "data:image/")),
  "The self-contained HTML contains a non-embedded image resource."
)
external_resources <- c(
  xml2::xml_attr(xml2::xml_find_all(document, "//script[@src]"), "src"),
  xml2::xml_attr(xml2::xml_find_all(document, "//link[@rel='stylesheet'][@href]"), "href")
)
external_resources <- external_resources[!is.na(external_resources) & nzchar(external_resources)]
assert_true(length(external_resources) == 0L, "The HTML contains a non-embedded script or stylesheet.")

html_text <- paste(readLines(html_path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
forbidden <- c(
  "quarto-unresolved-ref",
  "citation-needed",
  "citeproc warning",
  "not found in bibliography",
  "ERROR:",
  "Traceback",
  "/Users/zauner/"
)
assert_true(
  !any(vapply(forbidden, grepl, logical(1), x = html_text, fixed = TRUE)),
  "The HTML contains an unresolved marker, error marker, or local user path."
)

cat(sprintf(
  paste0(
    "FINAL_HTML_STRUCTURE=PASS tables=%d figures=%d authors=%d ids=%d ",
    "header_tokens=%d internal_fragments=%d bytes=%.0f R=%s\n"
  ),
  length(tables), length(figures), length(authors), length(ids),
  header_tokens, length(fragment_ids), file.info(html_path)$size, getRversion()
))
