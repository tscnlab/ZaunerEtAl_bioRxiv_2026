#!/usr/bin/env Rscript

# Candidate-only native gt conversion for the three manuscript-selection
# tables that are not yet constructed with gt. Scientific text and values are
# read from the current accepted selection artifacts without recomputation.

suppressPackageStartupMessages({
  library(digest)
  library(gt)
  library(xml2)
})

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("This display builder requires R 4.6.1.")
}

root <- normalizePath(Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/", mustWork = TRUE
)
setwd(root)

asset_root <- "audit/manuscript_nature_health/figure_table_selection_assets"
candidate_dir <- file.path(asset_root, "remaining_gt_candidates")
dir.create(candidate_dir, recursive = TRUE, showWarnings = FALSE)

sha256_file <- function(path) {
  digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
}

normalize_text <- function(node) {
  trimws(gsub("[[:space:]]+", " ", xml_text(node)))
}

write_candidate <- function(table, id, title) {
  html_body <- paste(
    paste0(
      '<div id="', id, '" class="manuscript-gt-scroll" ',
      'role="region" aria-label="', title, '" tabindex="0">'
    ),
    paste0(
      '<style>.manuscript-gt-scroll{max-width:100%;overflow-x:auto;}',
      '.manuscript-gt-scroll .gt_table{min-width:900px;}',
      '.manuscript-gt-scroll .gt_row{line-height:1.2;}</style>'
    ),
    as_raw_html(table, inline_css = TRUE),
    "</div>",
    sep = "\n"
  )
  fragment <- paste(
    paste0("<!-- Native gt candidate: ", title, " -->"),
    "```{=html}",
    html_body,
    "```",
    sep = "\n"
  )
  fragment_path <- file.path(candidate_dir, paste0(id, ".html"))
  preview_path <- file.path(candidate_dir, paste0(id, "-preview.html"))
  writeLines(fragment, fragment_path, useBytes = TRUE)
  writeLines(paste0(
    '<!doctype html><html lang="en"><head><meta charset="utf-8">',
    '<meta name="viewport" content="width=device-width,initial-scale=1">',
    '<title>', title, '</title><style>body{margin:24px;font-family:Arial,sans-serif;}</style>',
    '</head><body><main><h1>', title, '</h1>', html_body, '</main></body></html>'
  ), preview_path, useBytes = TRUE)
  data.frame(
    id = id,
    fragment = fragment_path,
    fragment_sha256 = sha256_file(fragment_path),
    preview = preview_path,
    preview_sha256 = sha256_file(preview_path),
    stringsAsFactors = FALSE
  )
}

build_h02 <- function(placement, label) {
  source_path <- file.path(
    asset_root,
    paste0("tbl-plan-h02-", placement, "-variation-shapley.html")
  )
  document <- read_html(source_path)
  rows <- xml_find_all(document, "//tbody/tr")
  group <- NA_character_
  records <- list()
  for (row in rows) {
    cells <- xml_children(row)
    if (length(cells) == 1L && grepl("planning-row-group", xml_attr(row, "class"))) {
      group <- normalize_text(cells[[1L]])
      next
    }
    if (length(cells) != 4L || is.na(group)) {
      stop("Unexpected H02 table structure: ", source_path)
    }
    values <- vapply(cells, normalize_text, character(1))
    records[[length(records) + 1L]] <- data.frame(
      group = group,
      quantity = values[[1L]],
      fitted_curve = values[[2L]],
      shapley = values[[3L]],
      share = values[[4L]],
      stringsAsFactors = FALSE
    )
  }
  data <- do.call(rbind, records)
  note_node <- xml_find_first(document, "//*[contains(@class,'planning-table-note')]")
  if (inherits(note_node, "xml_missing")) stop("Missing H02 source note.")
  note <- normalize_text(note_node)
  title <- paste0(label, " fitted-curve dispersion and conditional Shapley allocation")
  table <- gt(data, rowname_col = "quantity", groupname_col = "group") |>
    tab_header(title = md(paste0("**", title, "**"))) |>
    cols_label(
      fitted_curve = "Fitted-curve result (95% CI)",
      shapley = "Conditional Shapley result (95% CI)",
      share = "Share (95% CI)"
    ) |>
    cols_width(
      stub() ~ px(220),
      fitted_curve ~ px(230),
      shapley ~ px(250),
      share ~ px(190)
    ) |>
    tab_style(cell_text(weight = "bold"), cells_stub()) |>
    tab_style(cell_text(weight = "bold"), cells_row_groups()) |>
    tab_source_note(md(note)) |>
    tab_options(
      table.width = px(890),
      table.font.size = px(12),
      data_row.padding = px(5),
      row_group.padding = px(5),
      source_notes.font.size = px(10)
    )
  write_candidate(
    table,
    paste0("tbl-plan-h02-", placement, "-variation-shapley-gt-candidate"),
    title
  )
}

parse_markdown_row <- function(line) {
  cells <- strsplit(sub("^\\|", "", sub("\\|$", "", line)), "\\|", fixed = FALSE)[[1L]]
  trimws(cells)
}

qmd_path <- "audit/manuscript_nature_health/manuscript_figure_table_selection.qmd"
qmd <- readLines(qmd_path, warn = FALSE, encoding = "UTF-8")
heading <- grep("^#### Supplementary Table S8\\. Person-level evidence synthesis$", qmd)
if (length(heading) != 1L) stop("Expected one person-level table heading.")
table_lines <- which(seq_along(qmd) > heading & grepl("^\\|", qmd))
table_lines <- table_lines[table_lines < min(which(seq_along(qmd) > heading & grepl("^</div>$", qmd)))]
if (length(table_lines) != 9L) stop("Expected header, separator, and seven person-level rows.")
header <- parse_markdown_row(qmd[[table_lines[[1L]]]])
body <- lapply(qmd[table_lines[-c(1L, 2L)]], parse_markdown_row)
if (!all(vapply(body, length, integer(1)) == length(header))) {
  stop("Person-level Markdown table column count changed.")
}
person <- as.data.frame(do.call(rbind, body), stringsAsFactors = FALSE)
names(person) <- c("construct", "scale", "result", "fdr_set", "decision", "sample", "qualification")
person_title <- "Person-level evidence synthesis"
person_gt <- gt(person, rowname_col = "construct") |>
  tab_header(title = md("**Person-level evidence synthesis**")) |>
  cols_label(
    scale = "Outcome or analysis scale",
    result = "Result",
    fdr_set = "FDR-correction set",
    decision = "FDR decision",
    sample = "Exact sample",
    qualification = "Interpretation and qualification"
  ) |>
  cols_width(
    stub() ~ px(170),
    scale ~ px(190),
    result ~ px(270),
    fdr_set ~ px(180),
    decision ~ px(150),
    sample ~ px(200),
    qualification ~ px(230)
  ) |>
  tab_style(cell_text(weight = "bold"), cells_stub()) |>
  tab_options(
    table.width = px(1390),
    table.font.size = px(11),
    data_row.padding = px(5),
    source_notes.font.size = px(10)
  ) |>
  tab_source_note(md(paste0(
    "Results that did not meet the applicable FDR criterion are inconclusive rather than evidence of no association. ",
    "The two chronotype instruments were analysed separately. Biological sex and gender were recorded separately; gender was not analysed."
  )))

inventory <- rbind(
  build_h02("glasses", "Near-eye"),
  build_h02("chest", "Complementary chest"),
  write_candidate(person_gt, "tbl-plan-person-level-synthesis-gt-candidate", person_title)
)
inventory$R_version <- as.character(getRversion())
inventory_path <- file.path(candidate_dir, "remaining_gt_candidate_inventory.csv")
write.csv(inventory, inventory_path, row.names = FALSE, na = "")
cat(
  "REMAINING_GT_CANDIDATES=PASS tables=3 inventory=",
  sha256_file(inventory_path), "\n", sep = ""
)
