#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2L) {
  stop(
    "Usage: verify_rendered_manuscript.R <main|si> <html-path>",
    call. = FALSE
  )
}

kind <- args[[1L]]
html_path <- normalizePath(args[[2L]], mustWork = TRUE)

if (!kind %in% c("main", "si")) {
  stop("Render kind must be main or si.", call. = FALSE)
}
if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("R 4.6.1 is required.", call. = FALSE)
}
if (!requireNamespace("xml2", quietly = TRUE)) {
  stop("The xml2 package is required.", call. = FALSE)
}

assert_true <- function(value, message) {
  if (!isTRUE(value)) {
    stop(message, call. = FALSE)
  }
}

has_class_xpath <- function(class_name) {
  sprintf(
    "contains(concat(' ', normalize-space(@class), ' '), ' %s ')",
    class_name
  )
}

document <- xml2::read_html(html_path)
main_nodes <- xml2::xml_find_all(
  document,
  "//main[@id='quarto-document-content']"
)
assert_true(
  length(main_nodes) == 1L,
  "The document does not have exactly one main element."
)

id_nodes <- xml2::xml_find_all(document, "//*[@id]")
ids <- xml2::xml_attr(id_nodes, "id")
assert_true(
  !anyNA(ids) && !anyDuplicated(ids),
  "The document contains duplicate IDs."
)

expected_figures <- if (identical(kind, "main")) {
  c(
    "fig-study-overview",
    "fig-daily-architecture",
    "fig-activity-context",
    paste0("fig-s", seq_len(16L))
  )
} else {
  paste0("fig-s", seq_len(16L))
}

figure_endpoint_nodes <- xml2::xml_find_all(
  main_nodes,
  ".//*[@id and starts-with(@id, 'fig-')]"
)
figure_endpoint_ids <- xml2::xml_attr(figure_endpoint_nodes, "id")
figure_nodes <- figure_endpoint_nodes[figure_endpoint_ids %in% expected_figures]
figure_ids <- xml2::xml_attr(figure_nodes, "id")
assert_true(
  identical(figure_ids, expected_figures),
  "Figure endpoints are missing, duplicated, or out of order."
)

figure_image_counts <- vapply(
  figure_nodes,
  function(node) length(xml2::xml_find_all(node, ".//img")),
  integer(1)
)
figure_caption_counts <- vapply(
  figure_nodes,
  function(node) length(xml2::xml_find_all(node, ".//figcaption")),
  integer(1)
)
figure_alts <- vapply(
  figure_nodes,
  function(node) {
    image <- xml2::xml_find_first(node, ".//img")
    xml2::xml_attr(image, "alt")
  },
  character(1)
)
assert_true(
  all(figure_image_counts == 1L),
  "A figure does not contain exactly one image."
)
assert_true(
  all(figure_caption_counts >= 1L),
  "A figure does not contain a caption."
)
assert_true(
  all(!is.na(figure_alts) & nzchar(trimws(figure_alts))),
  "A figure lacks alt text."
)

table_xpath <- paste0(".//table[", has_class_xpath("gt_table"), "]")
table_nodes <- xml2::xml_find_all(main_nodes, table_xpath)
expected_tables <- if (identical(kind, "main")) 20L else 17L
assert_true(
  length(table_nodes) == expected_tables,
  sprintf(
    "Expected %d native gt tables, found %d.",
    expected_tables,
    length(table_nodes)
  )
)

header_tokens <- 0L
unresolved_header_tokens <- 0L
for (table in table_nodes) {
  table_header_ids <- xml2::xml_attr(
    xml2::xml_find_all(table, ".//th[@id]"),
    "id"
  )
  header_nodes <- xml2::xml_find_all(table, ".//*[@headers]")
  if (!length(header_nodes)) {
    next
  }
  token_lists <- strsplit(
    xml2::xml_attr(header_nodes, "headers"),
    "[[:space:]]+"
  )
  token_lists <- lapply(token_lists, function(x) x[nzchar(x)])
  header_tokens <- header_tokens + sum(lengths(token_lists))
  unresolved_header_tokens <- unresolved_header_tokens +
    sum(vapply(
      token_lists,
      function(tokens)
        sum(vapply(
          tokens,
          function(token) sum(table_header_ids == token) != 1L,
          logical(1)
        )),
      integer(1)
    ))
}
assert_true(header_tokens > 0L, "No semantic table-header tokens were found.")
assert_true(
  unresolved_header_tokens == 0L,
  "A table-header token is unresolved or nonunique."
)

fragment_hrefs <- xml2::xml_attr(
  xml2::xml_find_all(main_nodes, ".//a[starts-with(@href, '#')]"),
  "href"
)
fragment_ids <- sub("^#", "", fragment_hrefs)
fragment_ids <- fragment_ids[nzchar(fragment_ids)]
unresolved_fragments <- fragment_ids[vapply(
  fragment_ids,
  function(value) sum(ids == value) != 1L,
  logical(1)
)]
assert_true(
  length(unresolved_fragments) == 0L,
  "An internal fragment link is unresolved."
)

html_text <- paste(
  readLines(html_path, warn = FALSE, encoding = "UTF-8"),
  collapse = "\n"
)
forbidden <- c(
  "quarto-unresolved-ref",
  "citation-needed",
  "citeproc warning",
  "not found in bibliography",
  "ERROR:",
  "Traceback"
)
assert_true(
  !any(vapply(forbidden, grepl, logical(1), x = html_text, fixed = TRUE)),
  "The rendered HTML contains an unresolved or error marker."
)

if (identical(kind, "main")) {
  table3 <- xml2::xml_find_first(main_nodes, ".//*[@id='tbl-metric-context']")
  assert_true(!inherits(table3, "xml_missing"), "Main Table 3 is missing.")
  table3_table <- xml2::xml_find_all(
    table3,
    paste0(".//table[", has_class_xpath("gt_table"), "]")
  )
  assert_true(
    length(table3_table) == 1L,
    "Main Table 3 is not one native gt table."
  )
  expected_groups <- c(
    "Duration",
    "Dynamics",
    "Exposure history",
    "Level",
    "Spectrum",
    "Timing"
  )
  observed_groups <- unique(trimws(gsub(
    "[[:space:]]+",
    " ",
    xml2::xml_text(xml2::xml_find_all(
      table3_table,
      ".//*[contains(concat(' ', normalize-space(@class), ' '), ' gt_group_heading ')]"
    ))
  )))
  assert_true(
    identical(observed_groups, expected_groups),
    "Main Table 3 group order changed."
  )
}

cat(sprintf(
  paste0(
    "FINAL_RENDER_DOM=PASS kind=%s tables=%d figures=%d ids=%d ",
    "header_tokens=%d internal_fragments=%d bytes=%.0f R=%s\n"
  ),
  kind,
  length(table_nodes),
  length(figure_nodes),
  length(ids),
  header_tokens,
  length(fragment_ids),
  file.info(html_path)$size,
  getRversion()
))
