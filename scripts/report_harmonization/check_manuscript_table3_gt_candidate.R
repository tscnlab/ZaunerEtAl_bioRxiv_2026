#!/usr/bin/env Rscript

# Verify the candidate-only compact gt redesign of the frozen Nature Health
# manuscript-selection Table 3. This checker is read-only except for its
# selection-owned check-results CSV.

suppressPackageStartupMessages({
  library(digest)
  library(xml2)
})

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("This candidate checker must run under R 4.6.1.")
}

project_root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
setwd(project_root)

source_path <- paste0(
  "audit/manuscript_nature_health/figure_table_selection_assets/",
  "tbl-plan-h01-metric-synthesis.html"
)
candidate_dir <- paste0(
  "audit/manuscript_nature_health/figure_table_selection_assets/",
  "table3_gt_candidate"
)
fragment_path <- file.path(
  candidate_dir,
  "tbl-plan-h01-metric-synthesis-candidate.html"
)
preview_path <- file.path(
  candidate_dir,
  "tbl-plan-h01-metric-synthesis-candidate-preview.html"
)
inventory_path <- file.path(
  candidate_dir,
  "table3_candidate_content_inventory.csv"
)
browser_qa_path <- file.path(
  candidate_dir,
  "table3_candidate_browser_qa.csv"
)
check_path <- file.path(candidate_dir, "table3_candidate_checks.csv")

sha256_file <- function(path) {
  if (!file.exists(path) || dir.exists(path)) {
    stop("Expected a regular file: ", path)
  }
  digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
}

normalize_text <- function(node) {
  trimws(gsub("[[:space:]]+", " ", xml_text(node)))
}

checks <- list()
add_check <- function(name, observed, expected, pass) {
  checks[[length(checks) + 1L]] <<- data.frame(
    check = name,
    observed = paste(observed, collapse = ";"),
    expected = paste(expected, collapse = ";"),
    pass = isTRUE(pass),
    stringsAsFactors = FALSE
  )
}

pins <- c(
  source = "0ce8eb1e6cbeb63b7819dbce4e03f669529bcb0c20754ba684e6002eccc3e43f",
  selection_qmd = "5a66303527c131cd0f0dc0c45f6d6170ddcc773bcf6ecbc76f90d1b7ea21e83f",
  selection_html = "140a0c380aff46200846ac8c31ed69ac136989c02c99726b1b35e6e4dd1756c3",
  selection_builder = "23be5e1ecf1829288e2e4b2a752e8d71c4c53b0d59a466a2374ce8f99e8cc9d2"
)
pin_paths <- c(
  source = source_path,
  selection_qmd = "audit/manuscript_nature_health/manuscript_figure_table_selection.qmd",
  selection_html = "audit/manuscript_nature_health/manuscript_figure_table_selection.html",
  selection_builder = "scripts/report_harmonization/build_manuscript_figure_table_selection.R"
)
observed_pins <- vapply(pin_paths, sha256_file, character(1))
add_check(
  "frozen_boundary",
  unname(observed_pins),
  unname(pins),
  identical(unname(observed_pins), unname(pins))
)

source_doc <- read_html(source_path)
candidate_doc <- read_html(fragment_path)
source_table <- xml_find_first(source_doc, "//table")
candidate_table <- xml_find_first(candidate_doc, "//table")

extract_rows <- function(table) {
  rows <- xml_find_all(table, ".//tbody/tr")
  current_group <- NA_character_
  records <- list()
  groups <- character()
  for (row in rows) {
    cells <- xml_children(row)
    if (
      length(cells) == 1L &&
        grepl(
          "gt_group_heading",
          xml_attr(cells[[1L]], "class"),
          fixed = TRUE
        )
    ) {
      current_group <- normalize_text(cells[[1L]])
      groups <- c(groups, current_group)
      next
    }
    records[[length(records) + 1L]] <- list(
      group = current_group,
      cells = vapply(cells, normalize_text, character(1)),
      text = normalize_text(row),
      image_src = xml_attr(xml_find_first(row, ".//img"), "src"),
      image_alt = xml_attr(xml_find_first(row, ".//img"), "alt")
    )
  }
  list(records = records, groups = groups)
}

source_rows <- extract_rows(source_table)
candidate_rows <- extract_rows(candidate_table)
source_metrics <- vapply(
  source_rows$records,
  function(row) row$cells[[1L]],
  character(1)
)
candidate_metrics <- vapply(
  candidate_rows$records,
  function(row) row$cells[[1L]],
  character(1)
)
expected_groups <- c(
  "Dynamics",
  "Level",
  "Duration",
  "Timing",
  "Exposure history",
  "Spectrum"
)
add_check(
  "row_and_group_contract",
  c(length(candidate_rows$records), candidate_rows$groups),
  c(17L, expected_groups),
  length(candidate_rows$records) == 17L &&
    identical(candidate_rows$groups, expected_groups)
)
add_check(
  "metric_row_order",
  candidate_metrics,
  source_metrics,
  identical(candidate_metrics, source_metrics)
)

inventory <- read.csv(
  inventory_path,
  check.names = FALSE,
  stringsAsFactors = FALSE
)
inventory_values <- strsplit(inventory$source_values, "\u241f", fixed = TRUE)
source_values <- lapply(source_rows$records, function(row) row$cells)
add_check(
  "source_inventory_exact",
  length(inventory_values),
  length(source_values),
  length(inventory_values) == 17L &&
    all(vapply(
      seq_along(source_values),
      function(index)
        identical(inventory_values[[index]], source_values[[index]]),
      logical(1)
    ))
)

value_containment <- vapply(
  seq_along(source_rows$records),
  function(index) {
    expected <- source_rows$records[[index]]$cells
    observed <- candidate_rows$records[[index]]$text
    all(vapply(
      expected,
      function(value) !nzchar(value) || grepl(value, observed, fixed = TRUE),
      logical(1)
    ))
  },
  logical(1)
)
add_check(
  "all_accepted_cell_values_preserved",
  sum(value_containment),
  17L,
  all(value_containment)
)

number_tokens <- function(text) {
  matches <- gregexpr(
    "[+-]?[0-9]+(?:[,.][0-9]+)*(?::[0-9]+)?(?:%|×)?",
    text,
    perl = TRUE
  )
  sort(regmatches(text, matches)[[1L]])
}
source_numbers <- number_tokens(paste(
  vapply(source_rows$records, function(row) row$text, character(1)),
  collapse = " "
))
candidate_numbers <- number_tokens(paste(
  vapply(candidate_rows$records, function(row) row$text, character(1)),
  collapse = " "
))
add_check(
  "numeric_token_multiset",
  length(candidate_numbers),
  length(source_numbers),
  identical(candidate_numbers, source_numbers)
)

source_image_src <- vapply(
  source_rows$records,
  function(row) row$image_src,
  character(1)
)
candidate_image_src <- vapply(
  candidate_rows$records,
  function(row) row$image_src,
  character(1)
)
source_image_alt <- vapply(
  source_rows$records,
  function(row) row$image_alt,
  character(1)
)
candidate_image_alt <- vapply(
  candidate_rows$records,
  function(row) row$image_alt,
  character(1)
)
add_check(
  "thumbnail_source_and_alt_multisets",
  c(length(candidate_image_src), length(candidate_image_alt)),
  c(17L, 17L),
  identical(candidate_image_src, source_image_src) &&
    identical(candidate_image_alt, source_image_alt)
)

source_note <- normalize_text(
  xml_find_first(source_table, ".//tfoot//td")
)
candidate_note <- normalize_text(
  xml_find_first(candidate_table, ".//tfoot//td")
)
add_check(
  "source_note_exact",
  candidate_note,
  source_note,
  identical(candidate_note, source_note)
)

candidate_html <- paste(
  readLines(fragment_path, warn = FALSE, encoding = "UTF-8"),
  collapse = "\n"
)
widths <- c(175L, 235L, 135L, 155L, 125L, 180L, 155L)
add_check(
  "bounded_intrinsic_and_stable_column_widths",
  c(grepl("width:1160px", candidate_html, fixed = TRUE), widths),
  c(TRUE, widths),
  grepl("width:1160px", candidate_html, fixed = TRUE) &&
    all(vapply(
      widths,
      function(width)
        grepl(
          paste0("width:", width, "px"),
          candidate_html,
          fixed = TRUE
        ),
      logical(1)
    ))
)

scoped_headers <- xml_find_all(candidate_table, ".//th[@scope]")
idref_cells <- xml_find_all(candidate_table, ".//td[@headers]")
add_check(
  "semantic_header_contract",
  c(length(scoped_headers), length(idref_cells)),
  c(33L, 102L),
  length(scoped_headers) == 33L && length(idref_cells) == 102L
)

browser_qa <- read.csv(
  browser_qa_path,
  check.names = FALSE,
  stringsAsFactors = FALSE,
  na.strings = "NA"
)
add_check(
  "browser_qa_viewports",
  browser_qa$viewport,
  c("desktop", "narrow", "manuscript_width"),
  nrow(browser_qa) == 3L &&
    identical(
      browser_qa$viewport,
      c("desktop", "narrow", "manuscript_width")
    ) &&
    all(browser_qa$status == "PASS") &&
    all(browser_qa$document_overflow_px == 0) &&
    all(browser_qa$contained) &&
    all(browser_qa$broken_images == 0L)
)
add_check(
  "row_thumbnail_height_fit",
  c(
    browser_qa$row_height_min_px[[1L]],
    browser_qa$row_height_max_px[[1L]],
    browser_qa$image_height_px[[1L]]
  ),
  "row minus image between 5 and 15 px",
  browser_qa$row_height_min_px[[1L]] -
    browser_qa$image_height_px[[1L]] >=
    5 &&
    browser_qa$row_height_max_px[[1L]] -
      browser_qa$image_height_px[[1L]] <=
      15
)

add_check(
  "no_unaccepted_h10_candidate_reference",
  grepl("selection_candidate 2", candidate_html, fixed = TRUE),
  FALSE,
  !grepl("selection_candidate 2", candidate_html, fixed = TRUE)
)

results <- do.call(rbind, checks)
write.csv(results, check_path, row.names = FALSE, na = "")
if (!all(results$pass)) {
  stop(
    "Table 3 candidate checks failed: ",
    paste(results$check[!results$pass], collapse = ", ")
  )
}

cat(
  "TABLE3_GT_CANDIDATE_CHECK=PASS",
  paste0("checks=", nrow(results)),
  "rows=17",
  "groups=6",
  "images=17",
  "width_px=1160",
  "semantics=33/102",
  paste0("fragment=", sha256_file(fragment_path)),
  paste0("R=", as.character(getRversion())),
  "\n"
)
