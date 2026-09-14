options(stringsAsFactors = FALSE)
stopifnot(getRversion() == "4.6.1")
root <- normalizePath(getwd(), mustWork = TRUE)
owner <- file.path(root, "audit/manuscript_nature_health/revision_2026_09_11/consolidated_display_repair_order72k")
selection <- file.path(root, "audit/manuscript_nature_health/consolidated_display_repair_2026_09_11/integration_candidate_order72k")
record <- file.path(owner, "s2_accessibility_guard_recovery_001")
sha <- function(p) { con <- file(p, "rb"); on.exit(close(con)); unname(unclass(as.character(openssl::sha256(con)))) }
resolve <- function(p) if (startsWith(p, "/")) p else file.path(root, p)
output <- file.path(record, "stopped_render_preservation_4339_rows.csv")
stopifnot(!file.exists(output))
pins <- read.csv(file.path(record, "preflight_4339_rows.csv"))
aliases <- read.csv(file.path(record, "version_specific_aliases.csv"))
cache <- read.csv(file.path(record, "quarto_runtime_metadata_preimages.csv"))
stopifnot(nrow(pins) == 4339L, nrow(aliases) == 4L, nrow(cache) == 8L,
          !anyDuplicated(paste(cache$live, cache$sha256)),
          all(vapply(cache$preimage, sha, character(1)) == cache$sha256),
          all(file.info(cache$preimage)$size == cache$bytes))
paths <- vapply(pins$path, resolve, character(1))
mapped <- paths
classification <- rep("live exact", nrow(pins))
for (i in seq_len(nrow(aliases))) {
  j <- which(paths == aliases$live[i] & pins$expected_sha256 == aliases$expected_sha256[i])
  mapped[j] <- aliases$preimage[i]
  classification[j] <- "authorized path-and-version source preimage"
}
cache$post_sha256 <- unname(vapply(cache$live, sha, character(1)))
cache$post_bytes <- file.info(cache$live)$size
cache$changed_by_render <- cache$post_sha256 != cache$sha256 | cache$post_bytes != cache$bytes
for (i in seq_len(nrow(cache))) {
  stopifnot(grepl("/project/\\.quarto/", cache$live[i]))
  j <- which(paths == cache$live[i] & pins$expected_sha256 == cache$sha256[i] & cache$changed_by_render[i])
  mapped[j] <- cache$preimage[i]
  classification[j] <- "ordinary candidate Quarto runtime update; exact pre-render version preserved"
}
pins$current_resolution <- mapped
pins$current_sha256 <- unname(vapply(mapped, sha, character(1)))
pins$current_bytes <- file.info(mapped)$size
pins$classification <- classification
pins$exact <- pins$current_sha256 == pins$expected_sha256 & pins$current_bytes == pins$expected_bytes
write.csv(pins, output, row.names = FALSE)
write.csv(cache, file.path(record, "stopped_quarto_runtime_metadata_transitions.csv"), row.names = FALSE)
stopifnot(all(pins$exact), all(Sys.readlink(mapped) == ""))

sources <- read.csv(file.path(record, "pre_render_authoring_sources.csv"))
sources$current_sha256 <- unname(vapply(sources$path, sha, character(1)))
sources$exact <- sources$current_sha256 == sources$sha256 & file.info(sources$path)$size == sources$bytes
write.csv(sources, file.path(record, "stopped_authoring_source_identity.csv"), row.names = FALSE)
stopifnot(all(sources$exact))
for (name in c("frozen_css.csv", "earlier_capture_files_before.csv", "attempt5_output_pins.csv")) {
  p <- read.csv(file.path(record, name))
  stopifnot(all(vapply(p$path, sha, character(1)) == p$sha256), all(file.info(p$path)$size == p$bytes))
}
served <- read.csv(file.path(record, "served_preflight.csv"))
stopifnot(all(vapply(served$source, sha, character(1)) == served$sha256),
          all(vapply(served$served, sha, character(1)) == served$sha256))
table_map <- read.csv(file.path(record, "assembly_table_mapping.csv"))
stopifnot(nrow(table_map) == 29L, all(vapply(table_map$path, sha, character(1)) == table_map$sha256))
figures <- jsonlite::fromJSON(file.path(owner, "expanded_svg_manifest.json"))$accepted_figures
stopifnot(nrow(figures) == 22L, sum(figures$appearances) == 23L)
figures$current_sha256 <- unname(vapply(figures$path, sha, character(1)))
figures$source_sha256 <- unname(vapply(vapply(figures$source_path, resolve, character(1)), sha, character(1)))
figures$exact <- figures$current_sha256 == figures$sha256 & figures$source_sha256 == figures$sha256
write.csv(figures, file.path(record, "stopped_all_svg_identities.csv"), row.names = FALSE)
stopifnot(all(figures$exact))

docx <- file.path(owner, "project/render_docx_attempt2/ZaunerEtAl2026_NatHealth_phase3_brown.docx")
zip_index <- unzip(docx, list = TRUE)
read_member <- function(member) {
  j <- match(member, zip_index$Name)
  stopifnot(!is.na(j))
  con <- unz(docx, member, "rb"); on.exit(close(con))
  readBin(con, what = "raw", n = zip_index$Length[j])
}
ns <- c(w = "http://schemas.openxmlformats.org/wordprocessingml/2006/main",
        a = "http://schemas.openxmlformats.org/drawingml/2006/main",
        r = "http://schemas.openxmlformats.org/officeDocument/2006/relationships",
        asvg = "http://schemas.microsoft.com/office/drawing/2016/SVG/main")
doc <- xml2::read_xml(read_member("word/document.xml"))
rels <- xml2::xml_children(xml2::read_xml(read_member("word/_rels/document.xml.rels")))
rid <- xml2::xml_attr(rels, "Id")
rtarget <- xml2::xml_attr(rels, "Target")
tables <- xml2::xml_find_all(doc, "./w:body/w:tbl", ns)
embedded <- do.call(rbind, lapply(1:3, function(i) {
  text <- vapply(tables, function(t) paste(xml2::xml_text(xml2::xml_find_all(t, ".//w:t", ns)), collapse = ""), character(1))
  text <- gsub("\u00a0", " ", text, fixed = TRUE)
  j <- which(startsWith(text, paste0("Figure ", i, ":")))
  stopifnot(length(j) == 1L)
  blip <- xml2::xml_find_all(tables[[j]], ".//a:blip", ns)
  svg <- xml2::xml_find_all(blip, ".//asvg:svgBlip", ns)
  stopifnot(length(blip) == 1L, length(svg) == 1L)
  svg_rid <- xml2::xml_attr(svg, "r:embed", ns)
  base_rid <- xml2::xml_attr(blip, "r:embed", ns)
  member <- paste0("word/", rtarget[match(svg_rid, rid)])
  actual <- unname(unclass(as.character(openssl::sha256(read_member(member)))))
  expected <- figures$sha256[figures$word_label == paste("Main Figure", i)]
  data.frame(label = paste("Main Figure", i), member = member, svg_relationship = svg_rid,
             base_relationship_missing = is.na(base_rid),
             extension_count = length(xml2::xml_find_all(blip, "./a:extLst/a:ext", ns)),
             expected_sha256 = expected, actual_sha256 = actual, exact = actual == expected)
}))
write.csv(embedded, file.path(record, "stopped_docx_main_svg_identity.csv"), row.names = FALSE)
stopifnot(all(embedded$exact), all(embedded$base_relationship_missing), all(embedded$extension_count == 2L))

render_paths <- c(file.path(selection, "project/render_attempt2/selection.html"),
                  file.path(owner, "project/render_html_attempt2/ZaunerEtAl2026_NatHealth_phase3_brown.html"), docx)
write.csv(data.frame(path = render_paths, sha256 = vapply(render_paths, sha, character(1)), bytes = file.info(render_paths)$size),
          file.path(record, "stopped_correction_render_output_pins.csv"), row.names = FALSE)
stopifnot(!any(file.exists(c(file.path(owner, "manuscript_assembled_attempt1.docx"),
                             file.path(owner, "Nature_Health_non_S5_preview_attempt1.docx"),
                             file.path(owner, "office_qa_attempt1")))))
stopifnot(all(read.csv(file.path(record, "capture_checks.csv"))$pass),
          all(read.csv(file.path(record, "html_correction_structure_checks.csv"))$pass))
writeLines(c("Read-only R4.6.1 identity and structural preservation verification; no scientific calculation.",
             "All 4339 historical/preserved rows reproduced using exact path-and-version resolution.",
             paste("Ordinary Quarto cache/xref files changed:", sum(cache$changed_by_render), "of 8 separately classified."),
             "Three main SVGs are byte-exact in DOCX; all lack a base relationship and have two extensions.",
             "Assembly and SVG-embedding were not invoked. Office/native/browser correction QA remains unperformed.",
             capture.output(sessionInfo())), file.path(record, "stopped_verification_session.txt"))
cat("PASS:4339 preserved versions;", sum(cache$changed_by_render), "ordinary cache/xref transitions; 3authoring sources; 29table PNGs; 22SVG sources; 3embedded SVGs exact.\n")
cat("STOP: frozen SVG embedder requires a base relationship and a single extension; correction DOCX supplies neither for its three main figures. No assembly or officeQA invoked.\n")
