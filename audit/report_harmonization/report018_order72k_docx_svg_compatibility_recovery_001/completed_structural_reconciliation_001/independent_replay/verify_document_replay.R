options(stringsAsFactors = FALSE)
stopifnot(getRversion() == "4.6.1")
root <- normalizePath(getwd(), mustWork = TRUE)
owner <- file.path(root, "audit/manuscript_nature_health/revision_2026_09_11/consolidated_display_repair_order72k")
owner_record <- file.path(owner, "docx_svg_compatibility_recovery_001")
record <- "/private/tmp/order72k-docx-package-independent.S6mIE2"
old <- file.path(owner, "s2_accessibility_guard_recovery_001")
output <- file.path(owner, "Nature_Health_non_S5_preview_attempt1.docx")
assembled <- file.path(owner, "manuscript_assembled_attempt1.docx")
raw_docx <- file.path(owner, "project/render_docx_attempt2/ZaunerEtAl2026_NatHealth_phase3_brown.docx")
stopifnot(digest::digest(file = output, algo = "sha256", serialize = FALSE) == "f055f0c0f6225e372ed83ddb6bbe189e64f35d7306e7e54af563687991f6492c")
protected_read_inputs <- c(output, assembled, raw_docx,
 file.path(owner, "helpers/prepare_word_manuscript.py"),
 file.path(owner, "helpers/embed_accepted_svg_figures.py"),
 file.path(owner, "expanded_svg_manifest.json"),
 file.path(owner_record, "assembly_execution_receipt.json"),
 file.path(owner, "svg_embedding_attempt1.json"))
protected_hashes_before <- vapply(protected_read_inputs, function(p) digest::digest(file = p, algo = "sha256", serialize = FALSE), character(1))
stopifnot(!file.exists(file.path(record, "verified_document_checks.csv")))
hash_raw <- function(x) unname(unclass(as.character(openssl::sha256(x))))
hash_file <- function(p) { con <- file(p, "rb"); on.exit(close(con)); hash_raw(con) }
zip_reader <- function(p) {
  z <- unzip(p, list = TRUE); stopifnot(!anyDuplicated(z$Name))
  list(names = z$Name, read = function(member) {
    j <- match(member, z$Name); stopifnot(!is.na(j))
    con <- unz(p, member, "rb"); on.exit(close(con))
    readBin(con, "raw", n = z$Length[j])
  })
}
out <- zip_reader(output); prior <- zip_reader(assembled); raw <- zip_reader(raw_docx)
ns <- c(w = "http://schemas.openxmlformats.org/wordprocessingml/2006/main",
 wp = "http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing",
 a = "http://schemas.openxmlformats.org/drawingml/2006/main",
 r = "http://schemas.openxmlformats.org/officeDocument/2006/relationships",
 asvg = "http://schemas.microsoft.com/office/drawing/2016/SVG/main")
doc <- xml2::read_xml(out$read("word/document.xml"))
before <- xml2::read_xml(prior$read("word/document.xml"))
raw_xml <- xml2::read_xml(raw$read("word/document.xml"))
attr_ns <- function(node, name) xml2::xml_attr(node, name, ns)
find <- function(node, path) xml2::xml_find_all(node, path, ns)
one <- function(node, path) { x <- find(node, path); stopifnot(length(x) == 1L); x[[1]] }
all_text <- function(node) paste(xml2::xml_text(find(node, ".//w:t")), collapse = "")
clean <- function(x) trimws(gsub("[[:space:]]+", " ", gsub("\u00a0", " ", x, fixed = TRUE)))
checks <- data.frame(check = character(), pass = logical())
add <- function(name, pass) { checks <<- rbind(checks, data.frame(check = name, pass = isTRUE(pass))) }
rels <- xml2::xml_children(xml2::read_xml(out$read("word/_rels/document.xml.rels")))
rel_ids <- xml2::xml_attr(rels, "Id"); rel_targets <- xml2::xml_attr(rels, "Target")
image_member <- function(rid) {
 j <- match(rid, rel_ids); stopifnot(!is.na(j), startsWith(rel_targets[j], "media/"))
 paste0("word/", rel_targets[j])
}
draw <- find(doc, ".//wp:inline")
figures <- jsonlite::fromJSON(file.path(owner, "expanded_svg_manifest.json"))$accepted_figures
table_map <- read.csv(file.path(old, "assembly_table_mapping.csv"))
report <- jsonlite::fromJSON(file.path(owner, "svg_embedding_attempt1.json"), simplifyVector = FALSE)
assembly_report <- jsonlite::fromJSON(file.path(owner_record, "assembly_execution_receipt.json"))$report
add("producer_embedding_all_eight_checks", length(report$checks) == 8L && all(unlist(report$checks)))
add("52_inline_drawings_no_anchors", length(draw) == 52L && length(find(doc, ".//wp:anchor")) == 0L)
add("no_native_or_float_wrapper_tables", length(find(doc, ".//w:tbl")) == 0L)
ids <- vapply(draw, function(d) xml2::xml_attr(one(d, "./wp:docPr"), "id"), character(1))
add("unique_drawing_ids", !anyNA(ids) && !anyDuplicated(ids))
rows <- do.call(rbind, lapply(seq_along(draw), function(i) {
 d <- draw[[i]]; label <- xml2::xml_attr(one(d, "./wp:docPr"), "descr")
 native <- find(d, ".//asvg:svgBlip")
 blip <- one(d, ".//a:blip")
 rid <- if (length(native)) attr_ns(native[[1]], "r:embed") else attr_ns(blip, "r:embed")
 member <- image_member(rid)
 extent <- one(d, "./wp:extent")
 data.frame(index = i, id = ids[i], label = label, kind = if (length(native)) "SVG" else "PNG",
  relationship = rid, member = member, sha256 = hash_raw(out$read(member)),
  cx = as.numeric(xml2::xml_attr(extent, "cx")), cy = as.numeric(xml2::xml_attr(extent, "cy")))
}))
svg_rows <- rows[rows$kind == "SVG", ]; png_rows <- rows[rows$kind == "PNG", ]
add("23_SVG_appearances_and_29_PNG_drawings", nrow(svg_rows) == 23L && nrow(png_rows) == 29L)
add("22_physical_SVG_sources", sum(grepl("^word/media/.*\\.svg$", out$names)) == 22L && length(unique(svg_rows$member)) == 22L)
for (i in seq_len(nrow(figures))) {
 matches <- svg_rows$label == figures$word_label[i] | startsWith(svg_rows$label, paste0(figures$word_label[i], ","))
 add(paste0("SVG_bytes_and_appearances_", figures$word_label[i]),
     sum(matches) == figures$appearances[i] && all(svg_rows$sha256[matches] == figures$sha256[i]))
}
add("29_exact_table_payloads_in_document_order", identical(png_rows$sha256, table_map$sha256))
add("19_table_keys_retained", length(unique(table_map$key)) == 19L)
png_rows$key <- table_map$key; png_rows$part <- table_map$part
png_size <- function(p) {
 con <- file(p, "rb"); on.exit(close(con)); bytes <- as.integer(readBin(con, "raw", n = 24L))
 stopifnot(identical(bytes[1:8], c(137L,80L,78L,71L,13L,10L,26L,10L)))
 c(width = sum(bytes[17:20] * 256^(3:0)), height = sum(bytes[21:24] * 256^(3:0)))
}
dimens <- t(vapply(table_map$path, png_size, c(width = 0, height = 0)))
png_rows$pixel_width <- dimens[, "width"]; png_rows$pixel_height <- dimens[, "height"]
png_rows$width_inches <- png_rows$cx/914400; png_rows$height_inches <- png_rows$cy/914400
png_rows$aspect_error <- abs(png_rows$cx - png_rows$cy * png_rows$pixel_width/png_rows$pixel_height)
ratio <- png_rows$pixel_width/png_rows$pixel_height
max_width <- ifelse(png_rows$key == "supp_table_s2", 15.55, 10.55)
max_height <- ifelse(png_rows$key == "supp_table_s2", 8.90, 6.20)
expected_width <- pmin(max_width, max_height*ratio)
expected_height <- expected_width/ratio
png_rows$expected_cx <- floor(expected_width*914400)
png_rows$expected_cy <- floor(expected_height*914400)
add("all_table_dimensions_exact_frozen_geometry_including_integer_truncation", all(png_rows$cx == png_rows$expected_cx & png_rows$cy == png_rows$expected_cy))
s2 <- png_rows$key == "supp_table_s2"
add("S2_three_parts_within_15_55_by_8_90_inches", sum(s2) == 3L && all(png_rows$width_inches[s2] <= 15.55 + 1/914400) && all(png_rows$height_inches[s2] <= 8.90 + 1/914400))
add("other_table_parts_within_existing_bounds", all(png_rows$width_inches[!s2] <= 10.55 + 1/914400) && all(png_rows$height_inches[!s2] <= 6.20 + 1/914400))
sections <- find(doc, ".//w:sectPr")
section_rows <- do.call(rbind, lapply(seq_along(sections), function(i) {
 s <- sections[[i]]; size <- one(s, "./w:pgSz"); m <- one(s, "./w:pgMar")
 orient <- attr_ns(size, "w:orient"); if (is.na(orient)) orient <- "portrait"
 data.frame(section = i, orientation = orient, width = as.numeric(attr_ns(size,"w:w")), height = as.numeric(attr_ns(size,"w:h")),
  left = as.numeric(attr_ns(m,"w:left")), right = as.numeric(attr_ns(m,"w:right")),
  top = as.numeric(attr_ns(m,"w:top")), bottom = as.numeric(attr_ns(m,"w:bottom")))
}))
add("31_section_orientation_sequence", nrow(section_rows) == 31L && identical(section_rows$orientation, c(rep(c("portrait", "landscape"),15L), "portrait")))
a3_rows <- section_rows$width == round(16.535*1440) & section_rows$height == round(11.693*1440)
add("one_A3_landscape_section_exact_margins", sum(a3_rows) == 1L && all(section_rows[a3_rows,c("left","right")] == round(0.45*1440)) && all(section_rows[a3_rows,c("top","bottom")] == round(0.55*1440)))
for (i in png_rows$index[s2]) {
 s <- xml2::xml_find_first(draw[[i]], "following::w:sectPr", ns)
 size <- one(s, "./w:pgSz")
 add(paste0("S2_part_section_", i), as.numeric(attr_ns(size,"w:w")) == round(16.535*1440) && as.numeric(attr_ns(size,"w:h")) == round(11.693*1440))
}
styles <- xml2::read_xml(out$read("word/styles.xml"))
style_nodes <- find(styles, "./w:style")
style_names <- vapply(style_nodes, function(s) attr_ns(xml2::xml_find_first(s,"./w:name",ns),"w:val"), character(1))
heading1_style_id <- attr_ns(style_nodes[tolower(style_names) == "heading 1"], "w:styleId")
stopifnot(length(heading1_style_id) == 1L)
paragraphs <- find(doc, "./w:body/w:p")
heading1 <- paragraphs[vapply(paragraphs, function(p) {
 s <- find(p, "./w:pPr/w:pStyle"); length(s) == 1L && attr_ns(s,"w:val") == heading1_style_id
}, logical(1))]
headings <- vapply(heading1, all_text, character(1))
heading_page_breaks <- vapply(heading1, function(p) {
 br <- find(p, "./w:pPr/w:pageBreakBefore"); length(br) == 1L && !isTRUE(attr_ns(br,"w:val") %in% c("0","false"))
}, logical(1))
add("all_13_top_level_sections_start_new_page", identical(headings, assembly_report$new_page_sections) && length(headings) == 13L && all(heading_page_breaks))
starts <- find(doc, ".//w:bookmarkStart"); ends <- find(doc, ".//w:bookmarkEnd")
start_names <- attr_ns(starts,"w:name"); start_ids <- attr_ns(starts,"w:id"); end_ids <- attr_ns(ends,"w:id")
add("unique_paired_bookmark_names_and_ids", !anyDuplicated(start_names) && !anyDuplicated(start_ids) && !anyDuplicated(end_ids) && identical(sort(start_ids),sort(end_ids)))
hyperlinks <- find(doc, ".//w:hyperlink[@w:anchor]"); targets <- attr_ns(hyperlinks,"w:anchor")
add("126_internal_links_104_unique_targets_all_resolve", length(targets) == 126L && length(unique(targets)) == 104L && all(targets %in% start_names))
before_ids <- attr_ns(find(raw_xml, ".//w:bookmarkStart"), "w:id")
added <- assembly_report$display_bookmarks$added
added_ids <- as.character(added$id)
add("exact_22_repaired_bookmark_ID_name_pairs", length(setdiff(start_ids,before_ids)) == 22L && setequal(setdiff(start_ids,before_ids),added_ids) && identical(start_names[match(added_ids,start_ids)],added$name))
destinations <- vapply(added$name, function(name) {
 b <- starts[[match(name,start_names)]]
 clean(all_text(xml2::xml_find_first(b, "ancestor::w:p[1]", ns)))
}, character(1))
add("22_bookmarks_at_exact_recorded_caption_or_heading", identical(unname(destinations), added$destination))
raw_texts <- vapply(find(raw_xml,"./w:body/w:p"), all_text, character(1))
final_texts <- vapply(paragraphs, all_text, character(1))
raw_texts <- raw_texts[nzchar(raw_texts)]
cursor <- 0L; subsequence <- TRUE
for (txt in raw_texts) {
 matches <- which(final_texts == txt & seq_along(final_texts) > cursor)
 if (!length(matches)) { subsequence <- FALSE; break }
 cursor <- matches[1]
}
add("all_original_body_paragraph_text_retained_in_order", subsequence)
add("author_block_fourteen_affiliations_precedes_abstract", assembly_report$author_block$affiliations == 14L && assembly_report$author_block$final_indices$affiliations < assembly_report$author_block$final_indices$abstract)
for (n in c(7L,15L)) for (tag in c("A","B")) {
 i <- which(rows$label == paste0("Supplementary Figure S",n,tag)); stopifnot(length(i) == 1L)
 p <- xml2::xml_find_first(draw[[i]], "ancestor::w:p[1]", ns)
 label <- xml2::xml_find_first(p,"preceding-sibling::w:p[1]",ns)
 alignment <- attr_ns(one(label,"./w:pPr/w:jc"),"w:val")
 add(paste0("S",n,tag,"_independent_left_tag"), clean(all_text(label)) == tag && alignment == "left")
 if (tag == "B") add(paste0("S",n,"B_page_start"), length(find(label,"./w:pPr/w:pageBreakBefore")) == 1L)
}
for (i in which(startsWith(rows$label,"Supplementary Figure S8,"))) {
 prior_draw <- find(before,".//wp:inline")[[i]]
 add(paste0("S8_crop_and_extent_preserved_",i), identical(as.character(one(draw[[i]],".//a:srcRect")),as.character(one(prior_draw,".//a:srcRect"))) && identical(as.character(one(draw[[i]],"./wp:extent")),as.character(one(prior_draw,"./wp:extent"))))
}
add("source_Brown_hold_notice_retained", any(grepl("Non-S5 display-integration preview", final_texts, fixed = TRUE)) && any(grepl("bedside sleep environment, not verified",final_texts,fixed=TRUE)))
main_members <- svg_rows$member[startsWith(svg_rows$label,"Main Figure ")]
add("three_main_member_names_unchanged", identical(main_members,c("word/media/rId21.svg","word/media/rId28.svg","word/media/rId35.svg")))
add("nineteen_new_supplemental_member_names", sum(startsWith(unique(svg_rows$member),"word/media/nh_supplementary_figure_")) == 19L)
add("embedding_output_hash_matches_report", hash_file(output) == report$output_sha256)
write.csv(rows,file.path(record,"verified_drawing_payload_identity.csv"),row.names=FALSE)
write.csv(png_rows,file.path(record,"verified_table_part_geometry.csv"),row.names=FALSE)
write.csv(section_rows,file.path(record,"verified_section_geometry.csv"),row.names=FALSE)
write.csv(checks,file.path(record,"verified_document_checks.csv"),row.names=FALSE)
writeLines(c("R4.6.1 independent package, payload, geometry, text and link checks only; no scientific calculation.",
 capture.output(sessionInfo())),file.path(record,"verified_document_verification_session.txt"))
cat(nrow(checks),"document checks;",sum(checks$pass),"PASS.\n")
if (!all(checks$pass)) { print(checks[!checks$pass,]); stop("Document postcondition failed; preserve candidate and stop") }
protected_hashes_after <- vapply(protected_read_inputs, function(p) digest::digest(file = p, algo = "sha256", serialize = FALSE), character(1))
stopifnot(identical(protected_hashes_before, protected_hashes_after))
write.csv(data.frame(path = protected_read_inputs, sha256 = unname(protected_hashes_after), bytes = unname(file.info(protected_read_inputs)$size)), file.path(record, "replay_input_identity.csv"), row.names = FALSE)
cat("COORDINATOR_DOCX_REPLAY=PASS checks=57/57 exact_input_guard=8/8 read_only package_saves=0 visual_QA=pending\n")
