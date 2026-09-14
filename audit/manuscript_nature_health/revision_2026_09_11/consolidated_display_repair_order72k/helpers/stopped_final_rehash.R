options(stringsAsFactors = FALSE)
stopifnot(getRversion() == "4.6.1")
root <- normalizePath(getwd(), mustWork = TRUE)
out <- file.path(root, "audit/manuscript_nature_health/revision_2026_09_11/consolidated_display_repair_order72k")
record <- file.path(out, "stopped_final_checks")
stopifnot(!dir.exists(record)); dir.create(record)
sha <- function(p) { con <- file(p, "rb"); on.exit(close(con)); unname(unclass(as.character(openssl::sha256(con)))) }
pins <- read.csv(file.path(out, "input_identity_before.csv"), check.names = FALSE)
paths <- ifelse(startsWith(pins$path, "/"), pins$path, file.path(root, pins$path))
pins$final_sha256 <- vapply(paths, sha, character(1))
pins$final_exact <- pins$final_sha256 == pins$expected_sha256 & file.info(paths)$size == pins$bytes
write.csv(pins, file.path(record, "original_429_identities.csv"), row.names = FALSE)
stopifnot(all(pins$final_exact))
copies <- jsonlite::fromJSON(file.path(out, "source_copy_map.json"))
copies$final_source_sha256 <- vapply(copies$source, sha, character(1))
copies$final_copy_sha256 <- vapply(copies$copy, sha, character(1))
copies$exact <- copies$final_source_sha256 == copies$sha256 & copies$final_copy_sha256 == copies$sha256
write.csv(copies, file.path(record, "resource_copy_identities.csv"), row.names = FALSE)
stopifnot(all(copies$exact))
lua <- read.csv(file.path(out, "correction_preflight/lua_dependency_copies.csv"))
lua$final_exact <- vapply(lua$source, sha, character(1)) == lua$sha256 & vapply(lua$copy, sha, character(1)) == lua$sha256
write.csv(lua, file.path(record, "lua_copy_identities.csv"), row.names = FALSE)
stopifnot(all(lua$final_exact))
served <- jsonlite::fromJSON(file.path(out, "server_preflight.json"))$files
served$exact <- vapply(served$source, sha, character(1)) == served$sha256 & vapply(served$served, sha, character(1)) == served$sha256
write.csv(served, file.path(record, "served_output_identities.csv"), row.names = FALSE)
stopifnot(all(served$exact))
env <- read.csv(file.path(root, "audit/report_harmonization/report018_order72k_environment_cache_recovery_001/environment_input_pins.csv"), check.names = FALSE)
qmd <- env[grepl("\\.qmd$", env$path), ]
qpaths <- ifelse(startsWith(qmd$path, "/"), qmd$path, file.path(root, qmd$path))
qmd$final_sha256 <- vapply(qpaths, sha, character(1)); qmd$exact <- qmd$final_sha256 == qmd$sha256
write.csv(qmd, file.path(record, "unchanged_candidate_qmds.csv"), row.names = FALSE)
stopifnot(nrow(qmd) >= 3L, all(qmd$exact))
manifest <- jsonlite::fromJSON(file.path(out, "capture_attempt1/word_table_png_manifest.json"), simplifyVector = FALSE)
body_rows <- function(doc) vapply(xml2::xml_find_all(doc, ".//tbody/tr"), function(row) paste(xml2::xml_text(xml2::xml_children(row)), collapse = "\u001f"), character(1))
image_payloads <- function(doc) xml2::xml_attr(xml2::xml_find_all(doc, ".//tbody//img"), "src")
checks <- lapply(manifest, function(item) {
  source <- xml2::read_html(file.path(out, "capture_attempt1", paste0(item$key, "_source.html")))
  parts <- lapply(item$files, function(part) xml2::read_html(sub("\\.png$", ".html", part$path)))
  captured_rows <- unlist(lapply(parts, body_rows), use.names = FALSE)
  captured_images <- unlist(lapply(parts, image_payloads), use.names = FALSE)
  no_images <- length(captured_images) == 0L && length(image_payloads(source)) == 0L
  data.frame(table = item$key, all_source_rows_once = identical(unname(body_rows(source)), captured_rows), source_rows = length(body_rows(source)), all_image_payloads_exact = no_images || identical(unname(image_payloads(source)), captured_images), image_count = length(image_payloads(source)), visual_status = if (item$key == "supp_table_s2") "FAIL: numerical text clipping in first capture; attempted correction produced no files" else "Initial font capture visually inspected; final Word integration not run")
})
checks <- do.call(rbind, checks)
write.csv(checks, file.path(record, "initial_capture_cell_image_preservation.csv"), row.names = FALSE)
stopifnot(all(checks$all_source_rows_once), all(checks$all_image_payloads_exact))
stopifnot(!dir.exists(file.path(out, "capture_s2_attempt2")), !dir.exists(file.path(out, "project/render_html_attempt2")), !dir.exists(file.path(out, "project/render_docx_attempt2")))
writeLines(c("Preservation checks only, not a scientific recalculation. Initial S2 layout failed despite exact source content; no final visual acceptance.", capture.output(sessionInfo())), file.path(record, "session.txt"))
cat("PASS: 429 original pins;", nrow(copies), "source/resource pairs; 3 Lua copies;", nrow(served), "served files;", nrow(qmd), "candidate QMDs; four initial table cell/image maps.\n")
