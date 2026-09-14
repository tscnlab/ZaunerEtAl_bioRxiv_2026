options(warn = 2, stringsAsFactors = FALSE)
stopifnot(getRversion() == "4.6.1")
root <- normalizePath(getwd(), mustWork = TRUE)
owner <- file.path(root, "audit/manuscript_nature_health/revision_2026_09_11/consolidated_display_repair_order72k")
evidence <- "/private/tmp/order72k-docx-package-independent.S6mIE2"
inputs <- file.path(owner, c("manuscript_assembled_attempt1.docx", "Nature_Health_non_S5_preview_attempt1.docx", "svg_embedding_attempt1.json"))
sha <- function(p) digest::digest(file = p, algo = "sha256", serialize = FALSE)
input_before <- vapply(inputs, sha, character(1))
stopifnot(input_before[[2]] == "f055f0c0f6225e372ed83ddb6bbe189e64f35d7306e7e54af563687991f6492c")
zip_reader <- function(p) {
  z <- unzip(p, list = TRUE)
  stopifnot(!anyDuplicated(z$Name), !any(grepl("(^/|(^|/)\\.\\.(/|$))", z$Name)))
  list(names = z$Name, read = function(member) {
    j <- match(member, z$Name); stopifnot(!is.na(j))
    con <- unz(p, member, "rb"); on.exit(close(con))
    readBin(con, "raw", n = z$Length[j])
  })
}
prior <- zip_reader(inputs[[1]]); post <- zip_reader(inputs[[2]])
report <- jsonlite::fromJSON(inputs[[3]], simplifyVector = FALSE)
ns <- c(w = "http://schemas.openxmlformats.org/wordprocessingml/2006/main",
  wp = "http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing",
  a = "http://schemas.openxmlformats.org/drawingml/2006/main",
  r = "http://schemas.openxmlformats.org/officeDocument/2006/relationships",
  asvg = "http://schemas.microsoft.com/office/drawing/2016/SVG/main",
  pr = "http://schemas.openxmlformats.org/package/2006/relationships",
  ct = "http://schemas.openxmlformats.org/package/2006/content-types")
nodes <- function(x, q) xml2::xml_find_all(x, q, ns)
one <- function(x, q) { y <- nodes(x, q); stopifnot(length(y) == 1L); y[[1]] }
att <- function(x, k) xml2::xml_attr(x, k, ns)
checks <- data.frame(check = character(), pass = logical())
add <- function(name, value) { checks <<- rbind(checks, data.frame(check = name, pass = isTRUE(value))) }
before_doc <- xml2::read_xml(prior$read("word/document.xml"))
after_doc <- xml2::read_xml(post$read("word/document.xml"))
reverse_doc <- xml2::read_xml(post$read("word/document.xml"))
bd <- nodes(before_doc, ".//wp:inline"); ad <- nodes(after_doc, ".//wp:inline"); rd <- nodes(reverse_doc, ".//wp:inline")
stopifnot(length(bd) == 52L, length(ad) == 52L, length(rd) == 52L)
before_ids <- vapply(bd, function(d) att(one(d, "./wp:docPr"), "id"), character(1))
after_ids <- vapply(ad, function(d) att(one(d, "./wp:docPr"), "id"), character(1))
add("all_52_drawing_ids_and_order_exact", identical(before_ids, after_ids) && !anyDuplicated(after_ids))
native <- vapply(bd, function(d) length(nodes(d, ".//asvg:svgBlip")), integer(1))
added <- vapply(ad, function(d) length(nodes(d, ".//asvg:svgBlip")), integer(1))
add("exact_native3_new20_and_png29_partition", sum(native == 1L) == 3L && sum(added == 1L) == 23L && all(native %in% 0:1) && all(added %in% 0:1))
native_idx <- which(native == 1L)
png_idx <- which(added == 0L)
new_idx <- which(native == 0L & added == 1L)
add("three_existing_native_drawings_XML_unchanged", all(vapply(native_idx, function(i) identical(as.character(bd[[i]]), as.character(ad[[i]])), logical(1))))
add("all_29_table_drawings_XML_unchanged", length(png_idx) == 29L && all(vapply(png_idx, function(i) identical(as.character(bd[[i]]), as.character(ad[[i]])), logical(1))))
changed_relationships <- character()
for (i in new_idx) {
  prior_blip <- one(bd[[i]], ".//a:blip")
  current_blip <- one(rd[[i]], ".//a:blip")
  base_id <- att(prior_blip, "r:embed")
  stopifnot(!is.na(base_id), identical(att(current_blip, "r:embed"), base_id), identical(att(one(current_blip, ".//asvg:svgBlip"), "r:embed"), base_id))
  changed_relationships <- c(changed_relationships, base_id)
  ext <- one(current_blip, "./a:extLst/a:ext[@uri='{96DAC541-7B7A-43D3-8B79-37D633B846F1}']")
  list_node <- one(current_blip, "./a:extLst")
  had_list <- length(nodes(prior_blip, "./a:extLst")) == 1L
  xml2::xml_remove(ext)
  if (!had_list) { stopifnot(length(xml2::xml_children(list_node)) == 0L); xml2::xml_remove(list_node) }
}
add("document_XML_exact_reverse_by_only20_extension_removals", length(new_idx) == 20L && identical(as.character(reverse_doc), as.character(before_doc)))
br <- xml2::xml_children(xml2::read_xml(prior$read("word/_rels/document.xml.rels")))
ar <- xml2::xml_children(xml2::read_xml(post$read("word/_rels/document.xml.rels")))
bid <- att(br, "Id"); aid <- att(ar, "Id")
add("relationship_identifiers_unchanged_unique", identical(bid, aid) && !anyDuplicated(aid))
changed <- unique(changed_relationships)
add("exact_19_supplemental_image_relationships", length(changed) == 19L)
for (i in seq_along(br)) {
  if (bid[[i]] %in% changed) {
    ba <- xml2::xml_attrs(br[[i]]); aa <- xml2::xml_attrs(ar[[i]])
    add(paste0("only_target_changed_", bid[[i]]), identical(ba[names(ba) != "Target"], aa[names(aa) != "Target"]) && startsWith(att(ar[[i]], "Target"), "media/nh_supplementary_figure_") && endsWith(att(ar[[i]], "Target"), ".svg"))
  } else add(paste0("other_relationship_unchanged_", bid[[i]]), identical(as.character(br[[i]]), as.character(ar[[i]])))
}
new_members <- setdiff(post$names, prior$names)
removed <- setdiff(prior$names, post$names)
add("only_19_new_SVG_members_no_new_rasters", length(new_members) == 19L && all(grepl("^word/media/nh_supplementary_figure_.*\\.svg$", new_members)))
add("removed_members_match_explicit_orphan_ledger", setequal(removed, unlist(report$removed_unreferenced_raster_parts, use.names = FALSE)))
allowed <- c("word/document.xml", "word/_rels/document.xml.rels", "[Content_Types].xml")
unchanged <- setdiff(intersect(prior$names, post$names), allowed)
add("every_unrelated_common_package_member_byte_exact", all(vapply(unchanged, function(m) identical(prior$read(m), post$read(m)), logical(1))))
image_type <- paste0(ns[["r"]], "/image")
image_rows <- which(att(ar, "Type") == image_type)
image_targets <- att(ar[image_rows], "Target")
image_modes <- att(ar[image_rows], "TargetMode")
add("all_image_targets_internal_canonical_and_resolve", all(is.na(image_modes) | image_modes == "Internal") && all(grepl("^media/[^/]+$", image_targets)) && !any(grepl("[\\\\:%?#[:space:]]", image_targets)) && all(paste0("word/", image_targets) %in% post$names))
types <- xml2::read_xml(post$read("[Content_Types].xml"))
defs <- nodes(types, "./ct:Default"); overrides <- nodes(types, "./ct:Override")
svg_defs <- defs[which(att(defs, "Extension") == "svg")]
add("SVG_content_type_exact_unique", length(svg_defs) == 1L && att(svg_defs, "ContentType") == "image/svg+xml" && !anyDuplicated(att(defs, "Extension")) && !anyDuplicated(att(overrides, "PartName")))
input_after <- vapply(inputs, sha, character(1))
add("source_assembled_final_and_report_hashes_unchanged", identical(input_before, input_after))
write.csv(checks, file.path(evidence, "embedding_independent_checks.csv"), row.names = FALSE)
writeLines(c(capture.output(sessionInfo()), "Read-only OOXML and package-byte audit. No entry point, package save, render, model or visual operation."), file.path(evidence, "embedding_independent_session.txt"))
stopifnot(all(checks$pass))
cat(sprintf("COORDINATOR_EMBEDDING_STRUCTURE=PASS checks=%d/%d reverse=20extensions native=3exact tables=29exact newSVG=19 document_saves=0 visual=pending\n", nrow(checks), nrow(checks)))
