# Approved static source construction only. No browser, server, capture,
# Quarto, office, plotting, scientific model or assembly command is called.
stopifnot(getRversion() == "4.6.1")
options(stringsAsFactors = FALSE)
library(xml2)
library(openssl)
project <- "/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026"
package <- file.path(project, "audit/manuscript_nature_health/final_review_manual_table_sources_2026_09_13")
args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) == 1, grepl("^attempt_[0-9]{2}$", args[1]))
attempt <- file.path(package, args[1])
stopifnot(!file.exists(attempt))
dir.create(attempt)
file.copy(file.path(package, "build_static_pages.R"), file.path(attempt, "builder_executed.R"))
sha <- function(p) { con <- file(p, "rb"); on.exit(close(con)); paste0(as.character(sha256(con))) }
map_path <- file.path(project, "audit/manuscript_nature_health/brown_final_integration_2026_09_13/specifications/seven_missing_source_matched_artifacts.csv")
stopifnot(sha(map_path) == "efb61fdf50abf8674b55be1aa1bf8d6e9d21379682cbda87e5745221634e3f69")
map <- read.csv(map_path)
map$page <- c("table_2_a.html", "table_2_b.html", "table_s2_part_01.html", "table_s2_part_02.html", "table_s2_part_03.html", "table_s7_part_03.html", "table_s7_part_04.html")
map$output_png <- c("main_table_2_part_01.png", "main_table_2_part_02.png", "supp_table_s2_part_01.png", "supp_table_s2_part_02.png", "supp_table_s2_part_03.png", "supp_table_s7_part_03.png", "supp_table_s7_part_04.png")
map$page_title <- c("Table 2A: recommendation-adherence levels", "Table 2B: contrasts and coverage sensitivity", "Supplementary Table S2: part 1 of 3", "Supplementary Table S2: part 2 of 3", "Supplementary Table S2: part 3 of 3", "Supplementary Table S7: part 3 of 4", "Supplementary Table S7: part 4 of 4")
map$keep_notes <- c(TRUE, TRUE, FALSE, FALSE, TRUE, FALSE, TRUE)
map$expected_whole_units <- c(0, 0, 70, 50, 50, 0, 0)
map$source_font_px <- c(14, 14, 16, 16, 16, 12, 12)
escape <- function(x) {
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  x <- gsub(">", "&gt;", x, fixed = TRUE)
  gsub('"', "&quot;", x, fixed = TRUE)
}
page_css <- paste(c(
  "html { background:#eef1f4; color:#17202a; }",
  "body { margin:24px; }",
  ".manual-instructions, .manual-provenance { font:14px/1.5 Arial,sans-serif; max-width:1000px; }",
  ".manual-instructions { margin-bottom:20px; }",
  ".manual-instructions h1 { font-size:21px; margin:0 0 10px; }",
  ".manual-instructions p { margin:6px 0; }",
  ".manual-frame { display:inline-block; padding:8px; border:1px dashed #315d90; background:#eef1f4; }",
  "#capture-rectangle { box-sizing:border-box; background:#fff; padding:0; margin:0; overflow:visible; }",
  "#capture-rectangle > div { width:100% !important; height:auto !important; overflow:visible !important; box-sizing:border-box; }",
  "#capture-rectangle table.gt_table { width:100% !important; table-layout:fixed; box-sizing:border-box; }",
  ".manual-provenance { margin-top:18px; overflow-wrap:anywhere; }",
  ".manual-provenance code { font-size:12px; }"
), collapse = "\n")
for (i in seq_len(nrow(map))) {
  m <- map[i, ]; stopifnot(sha(m$source) == m$source_sha256)
  d <- read_html(m$source)
  table <- xml_find_first(d, "//table")
  stopifnot(!inherits(table, "xml_missing"))
  table_parent <- xml_parent(table)
  stopifnot(xml_name(table_parent) == "div", length(xml_find_all(table_parent, ".//table")) == 1)
  rows <- xml_find_all(table, "./tbody/tr")
  expected <- seq.int(m$row_start + 1L, m$row_end)
  stopifnot(length(rows) >= m$row_end)
  remove <- setdiff(seq_along(rows), expected)
  if (length(remove)) xml_remove(rows[remove])
  if (!m$keep_notes) xml_remove(xml_find_all(table, "./tfoot"))
  special_css <- ""
  if (m$key == "supp_table_s2") {
    widths <- c(200,60,103,rep(96,9),78,185)
    stopifnot(sum(widths) == 1490, length(widths) == 14)
    group <- xml_add_child(table, "colgroup", .where = 0)
    for (width in widths) xml_add_child(group, "col", style = paste0("width:", width, "px"))
    units <- xml_find_all(table, ".//span[contains(@style,'nowrap')]")
    units <- units[grepl("±", xml_text(units), fixed = TRUE)]
    stopifnot(length(units) == m$expected_whole_units)
    xml_set_attr(units, "data-manual-whole-unit", "true")
    special_css <- paste(c(
      "#capture-rectangle [data-manual-whole-unit], #capture-rectangle [data-manual-whole-unit] * { white-space:nowrap !important; overflow-wrap:normal !important; word-break:normal !important; }",
      "#capture-rectangle tbody tr:not(.gt_group_heading_row) > td:nth-child(n+3):nth-child(-n+12) { padding-left:4px; padding-right:4px; overflow:visible; }",
      "#capture-rectangle tbody tr:not(.gt_group_heading_row) > td:last-child { overflow:visible; }",
      "#capture-rectangle tbody tr:not(.gt_group_heading_row) > td:last-child img { max-width:100%; object-fit:contain; }"
    ), collapse = "\n")
  }
  rect_style <- paste0("width:", m$css_width, "px;min-width:", m$css_width, "px;max-width:", m$css_width, "px;")
  header <- paste0('<!doctype html>\n<html lang="en"><head><meta charset="utf-8">',
    '<meta name="viewport" content="width=device-width,initial-scale=1">',
    '<meta http-equiv="Content-Security-Policy" content="default-src &#39;none&#39;; img-src data:; style-src &#39;unsafe-inline&#39;; font-src &#39;none&#39;; connect-src &#39;none&#39;; frame-src &#39;none&#39;; base-uri &#39;none&#39;; form-action &#39;none&#39;">',
    '<title>', escape(m$page_title), ' | manual source</title><style id="manual-page-style">', page_css, '\n', special_css, '</style></head><body>\n',
    '<header class="manual-instructions"><h1 id="manual-page-title">', escape(m$page_title), '</h1>',
    '<p><strong>Manual source only. No automated visual inspection has occurred.</strong></p>',
    '<p>Capture the complete white rectangle inside the blue guide border, including the table title, headers, all rows and any notes. Do not include this instruction block or the guide border.</p>',
    '<p>Fixed width: <strong>', m$css_width, ' CSS pixels</strong>; all ', m$columns, ' columns. Source body-row slice: [', m$row_start, ',', m$row_end, '). ',
    if (m$key == "supp_table_s2") 'The original 16 CSS px base is retained. No font reduction is applied. Check that every mean ± SD unit fits on one line and every plot is complete. ' else '',
    if (!m$keep_notes) 'Source notes are retained on the final part, not this part. ' else 'Retain all notes visible inside the white rectangle. ',
    '</p><p>Save the lossless original as <code>', m$output_png, '</code>. If anything overlaps, is cut off or does not fit, report it without resizing, clipping or stitching the table.</p></header>\n',
    '<div class="manual-frame"><main id="capture-rectangle" aria-label="', escape(m$page_title), ': complete table capture rectangle" style="', rect_style, '">\n')
  footer <- paste0('\n</main></div><footer class="manual-provenance"><p>Outside the capture rectangle. Source: <code>', escape(m$source), '</code></p><p>Source SHA-256: <code>', m$source_sha256, '</code>. Page SHA-256 is listed in the accompanying manual guide and index; it is not embedded here to avoid a self-referential hash.</p><p>These pages contain no active JavaScript, remote fonts or automatic network resources. Static validation does not establish visual fit.</p></footer></body></html>\n')
  page <- paste0(header, as.character(table_parent), footer)
  writeLines(page, file.path(attempt, m$page), useBytes = TRUE)
}
map$page_sha256 <- vapply(file.path(attempt, map$page), sha, character(1))
write.csv(map, file.path(attempt, "page_manifest.csv"), row.names = FALSE)
capture.output(sessionInfo(), file = file.path(attempt, "sessionInfo.txt"))
writeLines(c("Static construction only; no browser, server, capture, rendering, scientific calculation or office process.", "Source S2 base 16 CSS px retained; archived 12px capture override excluded.", "Only approved row slices, final-part note disposition, width geometry and S2 full-unit nowrap/containment adjustments were made in the new copies."), file.path(attempt, "execution.txt"))
cat("Built seven static candidate pages in", attempt, "\n")
