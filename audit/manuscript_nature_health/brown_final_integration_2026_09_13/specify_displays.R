# Metadata-only source/part specification. No scientific calculation, renderer,
# browser, office process, helper implementation, or output assembly is invoked.
options(stringsAsFactors = FALSE)
library(xml2)
library(openssl)
library(jsonlite)
project <- "/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026"
pkg <- file.path(project, "audit/manuscript_nature_health/brown_final_integration_2026_09_13")
prior <- file.path(project, "audit/report_harmonization/final_documents_2026_09_12/writer_layout_preflight_archival_001/package")
overlay <- file.path(project, "audit/manuscript_nature_health/revision_2026_09_11/consolidated_display_repair_order72k")
out <- file.path(pkg, "specifications")
dir.create(out, showWarnings = FALSE)
sha <- function(path) { con <- file(path, "rb"); on.exit(close(con)); paste0(as.character(sha256(con))) }
pins <- list()
pin <- function(path, expected = NULL) {
  actual <- sha(path)
  if (!is.null(expected)) stopifnot(identical(actual, expected))
  pins[[length(pins) + 1L]] <<- data.frame(path, sha256 = actual)
  actual
}
read_csv <- function(path) { pin(path); read.csv(path, check.names = FALSE) }
old_parts <- read_csv(file.path(prior, "old_image_part_dispositions.csv"))
tables <- read_csv(file.path(prior, "editable_table_reuse_and_source_bindings.csv"))
svg <- read_csv(file.path(prior, "svg_source_bindings_and_dispositions.csv"))
changes <- read_csv(file.path(prior, "prospective_s2_s7_part_map.csv"))
geometry <- read_csv(file.path(overlay, "docx_svg_compatibility_recovery_001/final_table_part_geometry.csv"))
extracts <- read_csv(file.path(pkg, "records/exact_display_extractions.csv"))
copy <- read_csv(file.path(pkg, "records/copy_manifest.csv"))
# Explicit names avoid case-dependent inferred numbering.
tables$key <- c("main_table_1", "main_table_2", "main_table_3", "supp_table_s1", "supp_table_s2", "supp_table_s3", "supp_table_s4", "supp_table_s5", "supp_table_s6", "supp_table_s7", "supp_table_s8", "supp_table_s9", "supp_table_s10", "supp_table_s11a", "supp_table_s11b", "supp_table_s12", "supp_table_s13", "supp_table_s14", "supp_table_s15")
stopifnot(nrow(tables) == 19, nrow(old_parts) == 29)
tables$in_B <- tables$label == "Table_2"
tables$native_action <- ifelse(tables$in_B, "NEW: one Table_2.docx containing two native tables, panels A and B", ifelse(tables$label == "Table_S2", "NEW: width/whole-mean-SD no-break repair only; first trial has no font reduction", "REUSE byte-exact native DOCX; do not re-export"))
tables$new_native_tables_in_document <- ifelse(tables$in_B, 2L, 1L)
tables$candidate_source <- file.path(project, tables$canonical_source_fragment)
tables$candidate_source_sha256 <- tables$fragment_whole_file_sha256
tables$source_status <- "Unchanged pinned fragment; retain latest display overlay and prior accepted appearance"
tables$candidate_source[tables$in_B] <- paste(extracts$destination, collapse = " | ")
tables$candidate_source_sha256[tables$in_B] <- paste(vapply(extracts$destination, sha, character(1)), collapse = " | ")
tables$source_status[tables$in_B] <- "Exact accepted current report gt excerpts. 12-row levels plus 6-row contrasts/coverage, not the historical 3-row combined table"
tables$source_status[tables$label == "Table_S3"] <- "Unchanged descriptive pooled-minute fractions; not replaced by main-model period estimates"
tables$source_status[tables$label == "Table_S4"] <- "Unchanged four-effect exploratory extension; sample, CIs, FDR and withheld within-participant claim checked against final accepted sources"
for (i in seq_len(nrow(tables))) {
  pin(tables$current_editable_docx[i], tables$current_editable_docx_sha256[i])
  pin(file.path(project, tables$canonical_source_fragment[i]), tables$fragment_whole_file_sha256[i])
}
for (i in seq_len(nrow(old_parts))) pin(old_parts$path[i], old_parts$sha256[i])
for (i in seq_len(nrow(svg))) pin(svg$path[i], svg$sha256[i])
write.csv(tables, file.path(out, "native_table_dispositions.csv"), row.names = FALSE)
write.csv(tables[tables$label %in% c("Table_2", "Table_S3", "Table_S4"), ], file.path(out, "Brown_native_set_B.csv"), row.names = FALSE)

parts <- list()
for (i in seq_len(nrow(tables))) {
  key <- tables$key[i]
  old <- old_parts[old_parts$key == key, , drop = FALSE]
  if (key == "main_table_2") {
    for (j in seq_len(nrow(extracts))) {
      src <- extracts$destination[j]; d <- read_html(src)
      nr <- length(xml_find_all(d, "//table/tbody/tr"))
      nc <- max(vapply(xml_find_all(d, "//table/tbody/tr"), function(z) length(xml_find_all(z, "./td|./th")), integer(1)))
      parts[[length(parts) + 1L]] <- data.frame(key, part = j, panel = c("A: adherence levels", "B: contrasts and coverage")[j], source = src, source_sha256 = pin(src), row_start = 0L, row_end = nr, columns = nc, css_width = 896, fixed_word_width_in = 10.55, max_word_height_in = 6.2, old_image = old$path, old_image_sha256 = old$sha256, reuse_image = "", reuse_image_sha256 = "", action = "NEW source-matched artifact required; no capture produced", notes = if (j == 1) "No source notes; repeat exact column headers" else "Retain all accepted source notes on this panel; do not substitute footnotes from old Table 2", actual_css_height = NA_real_, actual_word_height_in = NA_real_)
    }
  } else {
    src <- tables$candidate_source[i]; d <- read_html(src)
    total_rows <- length(xml_find_all(d, "//table/tbody/tr"))
    nc <- max(vapply(xml_find_all(d, "//table/tbody/tr"), function(z) {
      cells <- xml_find_all(z, "./td|./th"); spans <- suppressWarnings(as.integer(xml_attr(cells, "colspan"))); spans[is.na(spans)] <- 1L; sum(spans)
    }, integer(1)))
    prop <- changes[changes$key == key, , drop = FALSE]
    if (!nrow(prop)) prop <- data.frame(key, part = old$part, row_start = old$row_start, row_end = old$row_end, columns = nc, action = "reuse_byte_exact", css_width = old$css_width, fixed_word_width_in = geometry$width_inches[match(paste(key, old$part), paste(geometry$key, geometry$part))], max_word_height_in = 6.2)
    stopifnot(prop$row_start[1] == 0, tail(prop$row_end, 1) == total_rows, all(head(prop$row_end, -1) == tail(prop$row_start, -1)))
    for (j in seq_len(nrow(prop))) {
      k <- prop$part[j]; o <- old[old$part == min(k, max(old$part)), , drop = FALSE]
      reuse <- prop$action[j] == "reuse_byte_exact"
      g <- geometry[geometry$key == key & geometry$part == k, , drop = FALSE]
      parts[[length(parts) + 1L]] <- data.frame(key, part = k, panel = "", source = src, source_sha256 = pin(src), row_start = prop$row_start[j], row_end = prop$row_end[j], columns = prop$columns[j], css_width = prop$css_width[j], fixed_word_width_in = prop$fixed_word_width_in[j], max_word_height_in = prop$max_word_height_in[j], old_image = o$path, old_image_sha256 = o$sha256, reuse_image = if (reuse) o$path else "", reuse_image_sha256 = if (reuse) o$sha256 else "", action = if (reuse) "REUSE image byte-exact" else "NEW source-matched artifact required after layout implementation; no capture produced", notes = if (j == nrow(prop)) "Retain exact source notes and final caption; repeat exact column headers" else "Retain all rows/group labels; repeat column headers; final notes only on last part", actual_css_height = if (reuse) o$css_height else NA_real_, actual_word_height_in = if (reuse && nrow(g)) g$height_inches else NA_real_)
    }
  }
}
parts <- do.call(rbind, parts)
stopifnot(nrow(parts) == 31, sum(!nzchar(parts$reuse_image)) == 7)
write.csv(parts, file.path(out, "complete_table_part_map.csv"), row.names = FALSE)
write.csv(parts[!nzchar(parts$reuse_image), ], file.path(out, "seven_missing_source_matched_artifacts.csv"), row.names = FALSE)
counts <- setNames(lapply(tables$key, function(k) sum(parts$key == k)), tables$key)
write_json(counts, file.path(out, "part_count_contract_PROPOSED.json"), auto_unbox = TRUE, pretty = TRUE)

svg_new <- list()
for (i in seq_len(nrow(svg))) {
  row <- svg[i, , drop = FALSE]
  if (row$word_label %in% c("Supplementary Figure S4", "Supplementary Figure S5")) {
    files <- if (row$word_label == "Supplementary Figure S4") "main_adherence_levels.svg" else c("main_site_workday.svg", "main_site_free_work.svg")
    for (j in seq_along(files)) {
      r <- row; r$old_path <- row$path; r$old_sha256 <- row$sha256
      r$word_label <- if (length(files) == 1) row$word_label else paste0(row$word_label, c("A", "B")[j])
      r$path <- file.path(pkg, "source/brown_assets", files[j]); r$sha256 <- pin(r$path)
      z <- copy[copy$destination == r$path, , drop = FALSE]; stopifnot(nrow(z) == 1)
      r$source_path <- z$source; r$appearances <- 1L
      r$writer_action <- "REPLACE with exact final accepted SVG; do not regenerate; Word visibility/readability still unverified"
      r$alt <- "Use exact candidate SI alt and caption at fig-s4 or fig-s5"
      svg_new[[length(svg_new) + 1L]] <- r
    }
  } else {
    row$old_path <- row$path; row$old_sha256 <- row$sha256
    if (row$word_label == "Supplementary Figure S6") row$writer_action <- "REUSE byte-exact; final accepted anonymous 139-profile raincloud unchanged"
    svg_new[[length(svg_new) + 1L]] <- row
  }
}
svg_new <- do.call(rbind, svg_new)
stopifnot(nrow(svg_new) == 23, sum(svg_new$appearances) == 24)
write.csv(svg_new, file.path(out, "complete_SVG_source_map.csv"), row.names = FALSE)
appearances <- list()
for (i in seq_len(nrow(svg_new))) for (j in seq_len(svg_new$appearances[i])) {
  s8 <- svg_new$word_label[i] == "Supplementary Figure S8"
  appearances[[length(appearances) + 1L]] <- data.frame(figure_order = length(appearances) + 1L, label = svg_new$word_label[i], appearance = j, source = svg_new$path[i], sha256 = svg_new$sha256[i], crop_top_fraction = if (s8 && j == 2) 0.42305 else 0, crop_bottom_fraction = if (s8 && j == 1) 0.57695 else 0, crop_left_fraction = 0, crop_right_fraction = 0, disposition = svg_new$writer_action[i], geometry = if (s8) "Retain existing two complementary Word crops of the same SVG" else "Preserve accepted display geometry; new Brown extents require QA, not a scientific redraw")
}
appearances <- do.call(rbind, appearances)
embedding_record <- file.path(overlay, "svg_embedding_attempt1.json")
pin(embedding_record)
embed <- fromJSON(embedding_record, simplifyVector = FALSE)
preview <- file.path(overlay, "Nature_Health_non_S5_preview_attempt1.docx")
pin(preview, "f055f0c0f6225e372ed83ddb6bbe189e64f35d7306e7e54af563687991f6492c")
con <- unz(preview, "word/document.xml", open = "rb")
document <- read_xml(con); close(con)
ns <- xml_ns(document)
old_drawings <- xml_find_all(document, "//w:drawing", ns)
stopifnot(length(old_drawings) == 52)
old_drawing_descriptions <- data.frame(index = seq_along(old_drawings), description = vapply(old_drawings, function(z) xml_attr(xml_find_first(z, ".//wp:docPr", ns), "descr"), character(1)))
write.csv(old_drawing_descriptions, file.path(out, "preview_52_drawing_descriptions.csv"), row.names = FALSE)
old_s8 <- xml_find_all(document, "//w:drawing[.//wp:docPr[contains(@descr, 'Supplementary Figure S8')]]", ns)
stopifnot(length(old_s8) == 2)
old_crops <- lapply(old_s8, function(z) xml_attrs(xml_find_first(z, ".//a:srcRect", ns)))
stopifnot(old_crops[[1]][["b"]] == "57695", old_crops[[2]][["t"]] == "42305")
appearances$crop_authority <- ifelse(appearances$label == "Supplementary Figure S8", paste0(preview, " :: word/document.xml; ", embedding_record), "No crop")
write.csv(appearances, file.path(out, "complete_figure_appearance_map.csv"), row.names = FALSE)
drawings <- list()
add_table <- function(k) {
  for (j in which(parts$key == k)) drawings[[length(drawings) + 1L]] <<- data.frame(order = length(drawings) + 1L, kind = "TABLE_IMAGE", label = k, part = parts$part[j], source = parts$source[j], source_sha256 = parts$source_sha256[j], image = parts$reuse_image[j], image_sha256 = parts$reuse_image_sha256[j], crop_top_fraction = 0, crop_bottom_fraction = 0, status = parts$action[j])
}
add_figure <- function(label) {
  z <- appearances[appearances$label == label, , drop = FALSE]; stopifnot(nrow(z) > 0)
  for (j in seq_len(nrow(z))) drawings[[length(drawings) + 1L]] <<- data.frame(order = length(drawings) + 1L, kind = "FIGURE_SVG", label, part = z$appearance[j], source = z$source[j], source_sha256 = z$sha256[j], image = z$source[j], image_sha256 = z$sha256[j], crop_top_fraction = z$crop_top_fraction[j], crop_bottom_fraction = z$crop_bottom_fraction[j], status = z$disposition[j])
}
# Narrative order, preserving the current non-Brown display overlay.
add_figure("Main Figure 1"); add_table("main_table_1"); add_table("main_table_2")
add_figure("Main Figure 2"); add_table("main_table_3"); add_figure("Main Figure 3")
for (k in c("supp_table_s1", "supp_table_s2", "supp_table_s3")) add_table(k)
for (f in c("S1", "S2", "S3", "S4", "S5A", "S5B")) add_figure(paste("Supplementary Figure", f))
add_table("supp_table_s4"); add_figure("Supplementary Figure S6")
add_table("supp_table_s5"); add_table("supp_table_s6")
add_figure("Supplementary Figure S7A"); add_figure("Supplementary Figure S7B")
add_table("supp_table_s7"); add_table("supp_table_s8")
add_figure("Supplementary Figure S8")
for (f in c("S9", "S10", "S11", "S12")) add_figure(paste("Supplementary Figure", f))
add_table("supp_table_s9"); add_table("supp_table_s10"); add_figure("Supplementary Figure S13")
add_table("supp_table_s11a"); add_table("supp_table_s11b"); add_figure("Supplementary Figure S14"); add_table("supp_table_s12")
add_figure("Supplementary Figure S15A"); add_figure("Supplementary Figure S15B"); add_table("supp_table_s13")
add_figure("Supplementary Figure S16"); add_table("supp_table_s14"); add_figure("Supplementary Figure S17"); add_table("supp_table_s15")
drawings <- do.call(rbind, drawings)
stopifnot(nrow(drawings) == 55, !anyDuplicated(paste(drawings$kind, drawings$label, drawings$part)))
before_labels <- character(52); before_parts <- integer(52)
for (i in seq_len(52)) {
  g <- geometry[geometry$index == i, , drop = FALSE]
  if (nrow(g)) {
    before_labels[i] <- g$key; before_parts[i] <- g$part
  } else {
    before_labels[i] <- sub(",.*", "", old_drawing_descriptions$description[i])
    before_parts[i] <- sum(before_labels[seq_len(i)] == before_labels[i])
  }
}
collapsed <- drawings[!(drawings$label == "main_table_2" & drawings$part == 2) & !(drawings$label == "supp_table_s7" & drawings$part == 4) & drawings$label != "Supplementary Figure S5B", ]
collapsed$label[collapsed$label == "Supplementary Figure S5A"] <- "Supplementary Figure S5"
stopifnot(identical(collapsed$label, before_labels), identical(as.integer(collapsed$part), before_parts))
writeLines("PASS: collapsing only the added Table 2B, S7 part 4 and Figure S5B recovers all 52 prior Word drawing positions exactly. New S7 tail row partitions and accepted Brown source replacements are explicit in the part/source maps. This is a structural-order check, not visual QA.", file.path(out, "drawing_order_reverse_check.txt"))
write.csv(drawings, file.path(out, "complete_55_drawing_order_PROPOSED.csv"), row.names = FALSE)
write_json(list(status = "SOURCE SPECIFICATION ONLY; zero production allowance", native_documents = 19, changed_Brown_native_set_B = "Table_2", changed_native_documents = c("Table_S2", "Table_2"), native_table_elements_across_documents = 20, main_table_images = 31, unique_SVG_files = 23, figure_appearances = 24, proposed_main_drawings = 55, missing_source_matched_table_images = 7, document_QA_commands_proposed = 3, maximum_office_processes_if_three_per_command_expressly_allowed = 9, rendered = FALSE, captured = FALSE, assembled = FALSE, visually_verified = FALSE), file.path(out, "production_counts_PROPOSED.json"), auto_unbox = TRUE, pretty = TRUE)
write.csv(unique(do.call(rbind, pins)), file.path(out, "structural_input_pins.csv"), row.names = FALSE)
capture.output(sessionInfo(), file = file.path(out, "sessionInfo.txt"))
cat("Source specifications: 19 native documents; B={Table_2}; 31 table parts; 24 figure appearances; 55 proposed drawings; 7 missing artifacts. No production performed.\n")
