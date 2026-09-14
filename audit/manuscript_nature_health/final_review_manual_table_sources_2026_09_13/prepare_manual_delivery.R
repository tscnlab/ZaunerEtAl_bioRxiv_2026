# Copy passing static pages and generate a local index/guide. No rendering.
stopifnot(getRversion() == "4.6.1")
library(openssl)
library(jsonlite)
project <- "/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026"
package <- file.path(project, "audit/manuscript_nature_health/final_review_manual_table_sources_2026_09_13")
attempt <- file.path(package, "attempt_02")
sha <- function(p) { con <- file(p, "rb"); on.exit(close(con)); paste0(as.character(sha256(con))) }
map <- read.csv(file.path(attempt, "page_manifest.csv"))
checks <- read.csv(file.path(attempt, "verification/checks.csv"))
stopifnot(nrow(checks) == 411, all(checks$pass))
same <- data.frame(page = map$page, attempt_01_sha256 = vapply(file.path(package, "attempt_01", map$page), sha, character(1)), attempt_02_sha256 = vapply(file.path(attempt, map$page), sha, character(1)))
stopifnot(all(same$attempt_01_sha256 == same$attempt_02_sha256), all(same$attempt_02_sha256 == map$page_sha256))
for (i in seq_len(nrow(map))) {
  p <- file.path(package, map$page[i]); stopifnot(!file.exists(p))
  stopifnot(file.copy(file.path(attempt, map$page[i]), p), sha(p) == map$page_sha256[i])
}
write.csv(map, file.path(package, "page_manifest.csv"), row.names = FALSE)
write.csv(same, file.path(package, "attempt_comparison.csv"), row.names = FALSE)
escape <- function(x) {
  x <- gsub("&", "&amp;", x, fixed = TRUE); x <- gsub("<", "&lt;", x, fixed = TRUE)
  x <- gsub(">", "&gt;", x, fixed = TRUE); gsub('"', "&quot;", x, fixed = TRUE)
}
style <- paste(c(
  "html { background:#f4f6f8; color:#1b2838; }",
  "body { font:16px/1.6 Arial,sans-serif; max-width:1120px; margin:40px auto; padding:0 24px 64px; }",
  "h1 { font-size:30px; line-height:1.2; margin-bottom:12px; }",
  "h2 { font-size:21px; margin-top:32px; }",
  "a { color:#174f95; }",
  "code { font-size:12px; overflow-wrap:anywhere; }",
  "table { width:100%; border-collapse:collapse; background:white; }",
  "th,td { padding:12px; border-bottom:1px solid #d8e0e8; text-align:left; vertical-align:top; }",
  "thead th { background:#e8eef5; }",
  ".notice { border-left:4px solid #997022; background:#fff8e8; padding:12px 16px; }",
  ".hashes { font-size:14px; }",
  "li { margin:8px 0; }"
), collapse = "\n")
html_document <- function(title, body) paste0('<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta http-equiv="Content-Security-Policy" content="default-src &#39;none&#39;; style-src &#39;unsafe-inline&#39;; font-src &#39;none&#39;; connect-src &#39;none&#39;; base-uri &#39;none&#39;; form-action &#39;none&#39;"><title>', escape(title), '</title><style>', style, '</style></head><body>', body, '</body></html>\n')
rows <- vapply(seq_len(nrow(map)), function(i) {
  m <- map[i, ]
  paste0('<tr><th scope="row"><a href="', m$page, '">', escape(m$page_title), '</a></th><td>', m$css_width, ' CSS px</td><td>', m$columns, ' columns; ', m$row_end-m$row_start, ' body rows', if (m$key == 'supp_table_s2') paste0('; ', m$expected_whole_units, ' mean ± SD units') else '', '</td><td><code>', m$output_png, '</code></td></tr>')
}, character(1))
page_table <- paste0('<table><thead><tr><th scope="col">Page</th><th scope="col">Width</th><th scope="col">Required content</th><th scope="col">Output filename</th></tr></thead><tbody>', paste(rows, collapse=''), '</tbody></table>')
hash_table <- paste0('<table class="hashes"><thead><tr><th scope="col">Exact page</th><th scope="col">SHA-256</th></tr></thead><tbody>', paste(vapply(seq_len(nrow(map)), function(i) paste0('<tr><th scope="row"><a href="', map$page[i], '">', map$page[i], '</a></th><td><code>', map$page_sha256[i], '</code></td></tr>'), character(1)), collapse=''), '</tbody></table>')
intro <- '<h1>Seven manual table captures</h1><p class="notice"><strong>Static source pages are ready. Images are not yet supplied.</strong> Content and source checks pass, but no browser has been opened and no automated visual inspection or capture has occurred. These are not final manuscript pages.</p>'
steps <- paste0('<h2>How to provide the images</h2><ol>',
  '<li>Open each exact page yourself from the links below. Use 100% browser zoom. The page states the source hash and required table width outside the capture rectangle.</li>',
  '<li>Inspect the full white rectangle inside the blue guide border. Include its original table title, repeated column headers, every row and all notes that are present. Exclude the blue border, instructions and provenance text outside the rectangle.</li>',
  '<li>Use a manual element screenshot for <code>#capture-rectangle</code> if your browser provides one, or an operating-system region screenshot only when the complete rectangle is visible. No scripts, automation, server or command-line capture are needed. If the entire rectangle cannot be captured, report that rather than stitching scrolling screenshots or shrinking it to fit.</li>',
  '<li>Save the original lossless PNG under the exact filename below. Do not convert to JPEG, resize, retouch, crop off content or use a photograph of the screen. Keep the original device-resolution image. At minimum, the PNG width must match the stated CSS width; twice that width is preferable on a Retina/high-density display.</li>',
  '<li>For each PNG, retain the source page filename and SHA-256 from this guide, browser name and zoom, capture method, original PNG dimensions and any observed issue. If practical, also include a separate uncropped context screenshot showing the page heading/provenance. The context screenshot is supporting evidence, not the table image.</li>',
  '<li>Attach the seven PNGs and those notes in this task. If any value overlaps, a mean ± SD unit breaks, a plot is clipped or a header/note is missing, report the page and location instead of supplying an altered image. A bounded correction can then be considered.</li></ol>')
specific <- paste0('<h2>Checks specific to these tables</h2><ul>',
  '<li><strong>Table 2:</strong> A and B are two parts of one main table. Keep both panels and all their columns. Panel B includes the accepted notes. Do not reuse the older single-panel Table 2 image.</li>',
  '<li><strong>S2:</strong> all three parts must retain all 14 columns. The original 16 CSS px base is unchanged; the archived 12px capture override and a font reduction are not used. The complete mean ± SD counts are 70, 50 and 50. Preserve all 17 plots, seven/five/five across the parts, and check their complete visible extent. Source notes are on part 3 only.</li>',
  '<li><strong>S7:</strong> only tail parts 3 and 4 need new images; existing parts 1 and 2 remain unchanged. Both new parts have eight columns and the same 896 CSS px width. Notes are on part 4 only.</li>',
  '<li>Neither CSS declarations nor content checks establish actual pixel height, overlap, clipping, intended-size readability or Word compatibility. Those checks remain outstanding. Do not interpret the static pass as visual acceptance.</li></ul>')
guide_body <- paste0(intro, '<p><a href="index.html">Return to the page index</a></p>', steps, page_table, specific, '<h2>Exact page identities</h2>', hash_table, '<p>These identities refer to the seven delivered HTML files in this directory. The package is sealed separately. Final Word assembly, editable-table exports and the complete website remain outside this source-preparation step.</p>')
writeLines(html_document("Manual table-capture guide", guide_body), file.path(package, "manual_capture_guide.html"), useBytes = TRUE)
index_body <- paste0(intro, '<p><a href="manual_capture_guide.html"><strong>Read the manual-capture guide first</strong></a>. It specifies the complete capture rectangle, filenames, lossless format and source evidence. The underlying manuscript science and language are unchanged by these pages.</p>', page_table, '<h2>Exact page identities</h2>', hash_table, '<p>Seven pages, 411 passing static checks, 170 preserved mean ± SD units and 17 unchanged embedded PNG payloads. No visual PASS, browser opening, capture, Quarto render, office conversion, assembly or site promotion is claimed.</p>')
writeLines(html_document("Nature Health manual table sources", index_body), file.path(package, "index.html"), useBytes = TRUE)
md <- c("# Manual table-capture guide", "", "Static source preparation only. No automated visual inspection, browser opening, capture or document render has occurred. The seven images remain to be supplied.", "", "Open the local HTML guide for complete instructions: [manual_capture_guide.html](manual_capture_guide.html).", "", "Capture only the complete white #capture-rectangle inside the blue guide border, at 100% browser zoom. Include the original table title, headers, all rows and all notes present; exclude the border, instructions and provenance outside it. Use a manual element screenshot if available, or an OS region screenshot only when the full rectangle is visible. Do not run scripts, stitch, resize, clip or convert to JPEG. Preserve the lossless original PNG and record page identity, browser/zoom, capture method and image dimensions. If anything does not fit, report it without changing it.", "", "S2 retains its canonical 16 CSS px base. The historical 12px capture override and a font reduction are not used. It contains all 14 columns and 170 whole mean ± SD units (70/50/50). All 17 original plot payloads remain unchanged (7/5/5). S7 parts 1/2 are reused; only parts 3/4 need images. S2 notes are on its last part; S7 notes on part 4. Table 2 requires both A and B, with B's accepted notes.", "", "| Page | Source slice | Width / columns | Required PNG | Page SHA-256 |", "|---|---|---|---|---|")
for (i in seq_len(nrow(map))) md <- c(md, paste0("| [", map$page[i], "](", map$page[i], ") | [", map$row_start[i], ",", map$row_end[i], ") | ", map$css_width[i], " CSS px / ", map$columns[i], " | ", map$output_png[i], " | ", map$page_sha256[i], " |"))
md <- c(md, "", "Provide the original PNGs at device resolution, ideally twice the stated CSS width on a high-density display and never below the stated width. Include page filename/hash and capture notes; a separate full-page context screenshot showing provenance is helpful. Images are not considered accepted merely because they are supplied. Content matching, complete extents, intended-size readability and later Word compatibility still need checking.", "", "The scientific source package, all live manuscript files and old previews remain unchanged. No final Word or full website is produced in this step.")
writeLines(md, file.path(package, "manual_capture_guide.md"), useBytes = TRUE)
cat("Delivered seven byte-exact static pages, index and guide. No images were captured.\n")
