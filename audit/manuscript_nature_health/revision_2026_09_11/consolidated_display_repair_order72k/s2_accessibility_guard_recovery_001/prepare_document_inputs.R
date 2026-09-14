options(stringsAsFactors = FALSE)
stopifnot(getRversion() == "4.6.1")
root <- normalizePath(getwd(), mustWork = TRUE)
owner <- file.path(root, "audit/manuscript_nature_health/revision_2026_09_11/consolidated_display_repair_order72k")
selection <- file.path(root, "audit/manuscript_nature_health/consolidated_display_repair_2026_09_11/integration_candidate_order72k")
record <- file.path(owner, "s2_accessibility_guard_recovery_001")
sha <- function(p) { con <- file(p, "rb"); on.exit(close(con)); unname(unclass(as.character(openssl::sha256(con)))) }
read_json <- function(p) jsonlite::fromJSON(p, simplifyVector = FALSE)
target <- file.path(record, "word_table_manifest_attempt5.json")
stopifnot(!file.exists(target), all(read.csv(file.path(record, "capture_checks.csv"))$pass))
base <- read_json(file.path(owner, "frozen_table_manifest_rebased.json"))
initial <- read_json(file.path(owner, "capture_attempt1/word_table_png_manifest.json"))
s2 <- read_json(file.path(owner, "capture_s2_attempt5/word_table_png_manifest.json"))
keys <- vapply(base, function(x) x$key, character(1))
stopifnot(length(keys) == 19L, !anyDuplicated(keys), length(s2) == 1L,
          sha(file.path(owner, "capture_s2_attempt5/word_table_png_manifest.json")) == "ca9b338b1eb8ee35251190048973b3a37ff09c06cfc2ddefe5f9f511512b0ead")
replacement_keys <- c("supp_table_s5", "supp_table_s6", "supp_table_s10")
replacement <- initial[vapply(initial, function(x) x$key %in% replacement_keys, logical(1))]
stopifnot(length(replacement) == 3L, sum(vapply(replacement, function(x) length(x$files), integer(1))) == 4L)
for (x in c(replacement, s2)) base[[match(x$key, keys)]] <- x
mapping <- do.call(rbind, lapply(base, function(x) do.call(rbind, lapply(seq_along(x$files), function(i) {
  f <- x$files[[i]]
  data.frame(key = x$key, part = i, path = f$path, sha256 = sha(f$path), bytes = file.info(f$path)$size,
             source_role = if (x$key == "supp_table_s2") "Attempt5 visually verified S2" else if (x$key %in% replacement_keys) "Initial font-verified capture reused unchanged" else "Unaffected frozen capture reused unchanged")
}))))
stopifnot(nrow(mapping) == 29L, !anyDuplicated(mapping$path), all(file.exists(mapping$path)))
jsonlite::write_json(base, target, auto_unbox = TRUE, pretty = TRUE, digits = NA)
write.csv(mapping, file.path(record, "assembly_table_mapping.csv"), row.names = FALSE)
svg <- read_json(file.path(owner, "expanded_svg_manifest.json"))$accepted_figures
stopifnot(length(svg) == 22L, sum(vapply(svg, function(x) x$appearances, integer(1))) == 23L,
          all(vapply(svg, function(x) sha(x$path) == x$sha256, logical(1))))
drawings <- c(lapply(seq_len(nrow(mapping)), function(i) list(kind = "table_capture", label = mapping$key[i], part = mapping$part[i], path = mapping$path[i], sha256 = mapping$sha256[i])),
  do.call(c, lapply(svg, function(x) lapply(seq_len(x$appearances), function(i) list(kind = "SVG", label = x$word_label, appearance = i, path = x$path, sha256 = x$sha256)))))
stopifnot(length(drawings) == 52L)
jsonlite::write_json(drawings, file.path(record, "explicit_52_drawing_map.json"), auto_unbox = TRUE, pretty = TRUE)
fresh <- c(file.path(selection, "project/render_attempt2"), file.path(owner, "project/render_html_attempt2"), file.path(owner, "project/render_docx_attempt2"), file.path(owner, "manuscript_assembled_attempt1.docx"), file.path(owner, "Nature_Health_non_S5_preview_attempt1.docx"), file.path(owner, "office_qa_attempt1"))
stopifnot(!any(file.exists(fresh)))
lua <- read.csv(file.path(owner, "correction_preflight/lua_dependency_copies.csv"))
stopifnot(nrow(lua) == 3L, all(vapply(lua$source, sha, character(1)) == lua$source_sha256), all(vapply(lua$copy, sha, character(1)) == lua$copy_sha256))
sources <- c(file.path(owner, "project/ZaunerEtAl2026_NatHealth_phase3_brown.qmd"), file.path(owner, "project/supplementary_information_outline.qmd"), file.path(selection, "project/selection.qmd"))
text <- lapply(sources, readLines, warn = FALSE)
stopifnot(!any(vapply(text, function(x) any(grepl("^```\\{(r|python|julia)|`r[[:space:]]", x)), logical(1))))
write.csv(data.frame(path = sources, sha256 = vapply(sources, sha, character(1)), bytes = file.info(sources)$size), file.path(record, "pre_render_authoring_sources.csv"), row.names = FALSE)
pins <- read.csv(file.path(root, "audit/report_harmonization/report018_order72k_s2_accessibility_guard_recovery_001/input_pins.csv"))
cache <- pins[grepl("/project/\\.quarto/", pins$path), ]
stopifnot(nrow(cache) == 8L)
cache$live <- file.path(root, cache$path)
cache$preimage <- file.path(record, "quarto_metadata_preimages", paste0(seq_len(nrow(cache)), "_", basename(cache$path)))
stopifnot(!dir.exists(file.path(record, "quarto_metadata_preimages")))
dir.create(file.path(record, "quarto_metadata_preimages"))
stopifnot(all(vapply(cache$live, sha, character(1)) == cache$sha256), all(file.copy(cache$live, cache$preimage, overwrite = FALSE, copy.date = TRUE)),
          all(vapply(cache$preimage, sha, character(1)) == cache$sha256))
write.csv(cache, file.path(record, "quarto_runtime_metadata_preimages.csv"), row.names = FALSE)
jsonlite::write_json(list(status = "S2 capture and content PASS; document generation not yet run", table_manifest = target, table_manifest_sha256 = sha(target), table_count = 19L, table_drawings = 29L,
  SVG_sources = 22L, SVG_appearances = 23L, total_drawings = 52L, source_copy_authority = file.path(owner, "source_copy_map.json"),
  render_command_authority = file.path(owner, "correction_preflight/correction_manifest.json"), fresh_destinations = fresh,
  mutation_boundary = "Only normal Quarto-owned candidate cache/xref updates are classified separately under the environment-cache recovery order; the eight exact pre-render versions are retained. No cache repair or source mutation.",
  historical_prepare_correction_manifest_rerun = FALSE), file.path(record, "document_input_gate.json"), auto_unbox = TRUE, pretty = TRUE)
cat("PASS: new exact19-table/29-part mapping plus22 SVG sources/23 appearances =52 drawings; all destinations fresh; three Lua dependencies exact; no analytical cells; eight runtime-metadata preimages preserved.\n")
