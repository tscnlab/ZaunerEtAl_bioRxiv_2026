#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(jsonlite)
  library(xml2)
})

normalize_text <- function(node) trimws(gsub("[[:space:]]+", " ", xml_text(node)))

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
owner_root <- file.path(
  root,
  "audit/manuscript_nature_health/figure_table_selection_svg_revision_2026_09_11"
)
html <- read_html(file.path(owner_root, "rendered/manuscript_figure_table_selection.html"))
contract <- read.csv(
  file.path(owner_root, "contracts/retained_table_contract.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)

for (endpoint in c("tbl-participant-site-manuscript", "tbl-h08-near-eye-results")) {
  index <- match(endpoint, contract$endpoint)
  source <- read_html(contract$path[[index]])
  source_node <- xml_find_first(source, paste0("//*[@id='", endpoint, "']"))
  rendered_node <- xml_find_first(html, paste0("//*[@id='", endpoint, "']"))
  source_cells <- vapply(xml_find_all(source_node, ".//th|.//td"), normalize_text, character(1))
  rendered_cells <- vapply(xml_find_all(rendered_node, ".//th|.//td"), normalize_text, character(1))
  comparison <- data.frame(
    index = seq_len(max(length(source_cells), length(rendered_cells))),
    source = c(source_cells, rep(NA_character_, max(0L, length(rendered_cells) - length(source_cells)))),
    rendered = c(rendered_cells, rep(NA_character_, max(0L, length(source_cells) - length(rendered_cells)))),
    stringsAsFactors = FALSE
  )
  comparison$same <- comparison$source == comparison$rendered
  write.csv(
    comparison,
    file.path(owner_root, "qa", paste0(endpoint, "_cell_diagnostic.csv")),
    row.names = FALSE,
    na = ""
  )
  cat("\nENDPOINT ", endpoint, " source=", length(source_cells),
      " rendered=", length(rendered_cells), "\n", sep = "")
  print(utils::head(comparison[is.na(comparison$same) | !comparison$same, ], 25L), row.names = FALSE)
}

blocks <- fromJSON(
  file.path(owner_root, "contracts/approved_insert_caption_blocks.json"),
  simplifyVector = FALSE
)
rendered_text <- normalize_text(html)
for (endpoint in c("fig-s6", "fig-s12")) {
  block <- Filter(function(item) identical(item$endpoint, endpoint), blocks)[[1]]
  fragment <- read_html(block$html)
  caption <- normalize_text(xml_find_first(fragment, "//figcaption"))
  exact_count <- lengths(regmatches(rendered_text, gregexpr(caption, rendered_text, fixed = TRUE)))
  rendered_caption <- normalize_text(xml_find_first(html, paste0("//*[@id='", endpoint, "']//figcaption")))
  cat("\nCAPTION ", endpoint, " exact_count=", exact_count,
      " identical=", identical(caption, rendered_caption), "\n", sep = "")
  if (!identical(caption, rendered_caption)) {
    cat("SOURCE: ", caption, "\nRENDERED: ", rendered_caption, "\n", sep = "")
  }
}
