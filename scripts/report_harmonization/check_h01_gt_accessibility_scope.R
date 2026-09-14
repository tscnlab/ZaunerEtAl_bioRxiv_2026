suppressPackageStartupMessages({
  library(gt)
  library(sass)
  library(xml2)
  library(rvest)
})

stopifnot(as.character(getRversion()) == "4.6.1")

html_path <- "_build/nathealth/notebooks/hypotheses/H01.html"
stopifnot(file.exists(html_path))

doc <- read_html(html_path)
main <- html_element(doc, "main#quarto-document-content")
tables <- html_elements(
  main,
  ".quarto-float[id^='tbl-h01-'] table.gt_table"
)
stopifnot(length(tables) == 36L)

audit <- do.call(
  rbind,
  lapply(tables, function(table) {
    endpoint <- xml_find_first(
      table,
      "ancestor::*[starts-with(@id,'tbl-h01-')][1]"
    )
    ids <- xml_attr(xml_find_all(table, ".//*[@id]"), "id")
    ids <- ids[!is.na(ids) & nzchar(ids)]
    header_nodes <- xml_find_all(table, ".//*[@headers]")
    header_values <- xml_attr(header_nodes, "headers")
    header_token_lists <- strsplit(header_values, "[[:space:]]+")
    invalid_by_cell <- vapply(
      header_token_lists,
      function(tokens) any(!tokens %in% ids),
      logical(1)
    )
    data.frame(
      endpoint = xml_attr(endpoint, "id"),
      internal_ids = length(ids),
      within_table_duplicate_ids = sum(duplicated(ids)),
      header_cells = length(header_nodes),
      invalid_header_cells = sum(invalid_by_cell),
      header_tokens = sum(lengths(header_token_lists)),
      invalid_header_tokens = sum(vapply(
        header_token_lists,
        function(tokens) sum(!tokens %in% ids),
        integer(1)
      )),
      stringsAsFactors = FALSE
    )
  })
)

all_id_nodes <- html_elements(main, "[id]")
all_ids <- html_attr(all_id_nodes, "id")
all_ids <- all_ids[!is.na(all_ids) & nzchar(all_ids)]
duplicate_names <- unique(all_ids[duplicated(all_ids)])
duplicate_nodes <- all_id_nodes[
  html_attr(all_id_nodes, "id") %in% duplicate_names
]
duplicates_outside_gt <- vapply(
  duplicate_nodes,
  function(node) {
    length(xml_find_all(
      node,
      paste0(
        "ancestor::table[contains(concat(' ', normalize-space(@class), ' '),",
        " ' gt_table ')]"
      )
    )) ==
      0L
  },
  logical(1)
)

options(sass.cache = tempdir())
minimal_html <- as_raw_html(
  gt(data.frame(`Model unit` = "a", check.names = FALSE)),
  inline_css = FALSE
)

stopifnot(
  all(audit$within_table_duplicate_ids == 0L),
  nrow(audit) == 36L,
  sum(audit$invalid_header_cells > 0L) == 33L,
  sum(audit$header_cells) == 4798L,
  sum(audit$invalid_header_cells) == 3275L,
  sum(audit$header_tokens) == 22023L,
  sum(audit$invalid_header_tokens) == 14777L,
  length(duplicate_names) == 109L,
  sum(all_ids %in% duplicate_names) == 720L,
  sum(all_ids %in% duplicate_names) - length(duplicate_names) == 611L,
  !any(duplicates_outside_gt),
  grepl('id="Model-unit"', minimal_html, fixed = TRUE),
  grepl('headers="Model unit"', minimal_html, fixed = TRUE)
)

cat(paste0(
  "H01 gt accessibility scope audit PASS: 36 native gt tables; zero ",
  "within-table duplicate IDs; 109 document-level duplicate ID names across ",
  "720 occurrences, all confined to separate gt tables; 33 tables and 3,275 ",
  "of 4,798 body cells have at least one headers token that does not resolve ",
  "to an ID within its own table. A minimal gt 1.3.0 table independently ",
  "reproduces id=Model-unit with headers=Model unit.\n"
))
