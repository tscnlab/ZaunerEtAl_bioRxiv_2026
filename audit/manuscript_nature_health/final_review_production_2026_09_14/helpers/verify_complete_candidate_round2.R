stopifnot(as.character(getRversion()) == "4.6.1")
suppressPackageStartupMessages(library(xml2))
suppressPackageStartupMessages(library(jsonlite))
suppressPackageStartupMessages(library(digest))
root <- normalizePath(getwd())
p <- file.path(root, "audit/manuscript_nature_health/final_review_production_2026_09_14")
sha <- function(f) digest(f, file = TRUE, algo = "sha256")
checks <- list()
check <- function(id, ok, detail = "") checks[[length(checks) + 1L]] <<-
  data.frame(id = id, pass = isTRUE(ok), detail = detail)
docx <- file.path(p, "deliverables/Nature_Health_manuscript_round2.docx")
check("main_post_native_inspection_identity", sha(docx) == "3f33431ed4e85b042f8a98e232b25b9617d8dae16bc8eff8df9595c05a80d611")
check("S2_post_native_inspection_identity", sha(file.path(p, "editable_tables/round2/Table_S2.docx")) == "0c834387ff6462b737381d028f0482636c5e55ad0443234f1cb8c165dda75334")
members <- unzip(docx, list = TRUE)
zip_sha <- function(name) {
  con <- unz(docx, name, open = "rb")
  on.exit(close(con))
  digest(readBin(con, "raw", n = members$Length[match(name, members$Name)]), algo = "sha256", serialize = FALSE)
}
ns <- c(w = "http://schemas.openxmlformats.org/wordprocessingml/2006/main",
        wp = "http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing",
        a = "http://schemas.openxmlformats.org/drawingml/2006/main",
        r = "http://schemas.openxmlformats.org/officeDocument/2006/relationships")
d <- read_xml(unz(docx, "word/document.xml"))
before <- read_xml(unz(file.path(p, "deliverables/manuscript_assembled_round2.docx"), "word/document.xml"))
check("text_exact_before_after_SVG_embedding", identical(xml_text(xml_find_all(d, "//w:t", ns)), xml_text(xml_find_all(before, "//w:t", ns))))
check("54_inline_drawings", length(xml_find_all(d, "//wp:inline", ns)) == 54L)
check("no_unexpected_floating_drawings", length(xml_find_all(d, "//wp:anchor", ns)) == 0L)
check("no_main_native_table_substitution", length(xml_find_all(d, "//w:body/w:tbl", ns)) == 0L)
tables <- fromJSON(file.path(p, "maps/word_table_png_manifest.json"), simplifyVector = FALSE)
parts <- unlist(lapply(tables, `[[`, "files"), recursive = FALSE)
check("19_table_keys_30_parts", length(tables) == 19L && length(parts) == 30L)
rels <- read_xml(unz(docx, "word/_rels/document.xml.rels"))
rel_nodes <- xml_find_all(rels, "//*[local-name()='Relationship']")
rel_map <- setNames(xml_attr(rel_nodes, "Target"), xml_attr(rel_nodes, "Id"))
inline_nodes <- xml_find_all(d, "//wp:inline", ns)
drawing_ids <- vapply(inline_nodes, function(z) {
  ids <- unique(xml_attr(xml_find_all(z, ".//*[@r:embed]", xml_ns(d)), "embed"))
  stopifnot(length(ids) == 1L)
  ids
}, character(1))
drawing_targets <- paste0("word/", unname(rel_map[drawing_ids]))
pngs <- drawing_targets[grepl("[.]png$", drawing_targets)]
check("30_visible_table_PNG_drawings_exact", length(pngs) == 30L && identical(sort(unname(vapply(pngs, zip_sha, character(1)))), sort(unname(vapply(parts, `[[`, character(1), "sha256")))))
check("24_visible_SVG_drawings", sum(grepl("[.]svg$", drawing_targets)) == 24L)
all_pngs <- members$Name[grepl("^word/media/.*[.]png$", members$Name)]
unused_pngs <- setdiff(all_pngs, pngs)
check("17_inherited_unreferenced_PNG_parts_preserved", length(unused_pngs) == 17L,
      "These original S2 density payloads remain in the OOXML package but are not additional manuscript drawings. No package part was deleted.")
for (part in parts) check(paste0("table_source_", basename(part$path)), sha(part$path) == part$sha256)
embedding <- fromJSON(file.path(p, "evidence/svg_embedding_round2.json"), simplifyVector = FALSE)
svgs <- embedding$embedded_svgs
check("23_SVG_sources_24_appearances", length(svgs) == 23L && sum(vapply(svgs, `[[`, numeric(1), "appearances")) == 24L)
for (f in svgs) {
  check(paste0("SVG_source_and_embedded_", f$word_label), sha(f$path) == f$sha256 && zip_sha(f$embedded_part) == f$sha256)
}
paragraphs <- xml_find_all(d, "//w:body/w:p", ns)
texts <- vapply(paragraphs, function(z) paste0(xml_text(xml_find_all(z, ".//w:t", ns)), collapse = ""), character(1))
styles <- xml_attr(xml_find_first(paragraphs, "./w:pPr/w:pStyle", ns), "val")
heading_names <- c("Abstract", "Introduction", "Results", "Discussion", "Methods", "Data availability", "Code availability", "References", "Acknowledgements", "Funding", "Author contributions", "Competing interests", "Supplementary Information")
h <- paragraphs[!is.na(styles) & styles == "berschrift1"]
ht <- vapply(h, function(z) paste0(xml_text(xml_find_all(z, ".//w:t", ns)), collapse = ""), character(1))
breaks <- !is.na(xml_name(xml_find_first(h, "./w:pPr/w:pageBreakBefore", ns)))
check("13_major_headings_exact_order", identical(ht, heading_names))
check("13_major_headings_new_page", length(breaks) == 13L && all(breaks))
check("93_reference_paragraphs", sum(styles == "Literaturverzeichnis", na.rm = TRUE) == 93L)
check("one_preserved_author_block", sum(styles == "Author", na.rm = TRUE) == 1L)
check("AI_declaration_present", any(grepl("artificial intelligence|AI-assisted|AI assistance|generative AI", texts, ignore.case = TRUE)))
check("no_unresolved_citations", !any(grepl("\\?\\?\\?|CITATION_NOT_FOUND", texts)))
check("107_complete_QA_page_images", length(list.files(file.path(p, "qa/main_round2"), pattern = "^page-[0-9]+[.]png$")) == 107L)
for (item in list(c("009_members.csv", "dispatch"), c("owner_members.csv", "owner"))) {
  baseline <- read.csv(file.path(p, "evidence/environment_recovery_009a", item[1]), check.names = FALSE)
  base <- if (item[2] == "owner") file.path(root, "audit/manuscript_nature_health/table_layout_visual_corrections_2026_09_14") else root
  paths <- ifelse(startsWith(baseline$path, "/"), baseline$path, file.path(base, baseline$path))
  baseline$post_sha256 <- vapply(paths, sha, character(1))
  baseline$post_unchanged <- baseline$post_sha256 == baseline$sha256
  write.csv(baseline, file.path(p, "evidence", paste0(item[2], "_post_production_preservation.csv")), row.names = FALSE)
  check(paste0(item[2], "_all_protected_members_unchanged"), all(baseline$post_unchanged), paste(nrow(baseline), "members"))
}
browser <- fromJSON(file.path(p, "evidence/html_browser_round2/teardown.json"))
check("browser_listener_closed_content_unchanged", browser$closed && browser$content_unchanged)
result <- do.call(rbind, checks)
write.csv(result, file.path(p, "evidence/complete_candidate_checks_round2_final.csv"), row.names = FALSE)
write.csv(data.frame(heading = ht, new_page = breaks), file.path(p, "evidence/major_sections_round2.csv"), row.names = FALSE)
writeLines(capture.output(sessionInfo()), file.path(p, "evidence/complete_candidate_R_session_round2.txt"))
write_json(list(structural_status = if (all(result$pass)) "PASS" else "FAIL", checks = nrow(result), passed = sum(result$pass), validation_adjudication = "Initial check counted every ZIP PNG rather than visible drawings. Second check missed the three original SVG-only extension references. Final check resolves every inline drawing to its unique relationship, including native SVG extensions; both earlier failure records are retained. No document was changed.", visual_status = "REQUIRES_BOUNDED_LAYOUT_CORRECTION", scientific_recalculation = FALSE), file.path(p, "evidence/complete_candidate_result_round2_final.json"), auto_unbox = TRUE, pretty = TRUE)
print(result[!result$pass, ], row.names = FALSE)
cat(sum(result$pass), "/", nrow(result), "structural and preservation checks passed. Visual correction remains separate.\n")
stopifnot(all(result$pass))
