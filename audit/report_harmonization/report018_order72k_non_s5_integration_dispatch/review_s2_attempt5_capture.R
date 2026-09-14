options(stringsAsFactors = FALSE)
stopifnot(getRversion() == "4.6.1")
root <- normalizePath(getwd(), mustWork = TRUE)
out <- file.path(root, "audit/report_harmonization/report018_order72k_non_s5_integration_dispatch")
owner <- file.path(root, "audit/manuscript_nature_health/revision_2026_09_11/consolidated_display_repair_order72k")
record <- file.path(owner, "s2_accessibility_guard_recovery_001")
capture <- file.path(owner, "capture_s2_attempt5")
sha <- function(path) { con <- file(path, "rb"); on.exit(close(con)); unname(unclass(as.character(openssl::sha256(con)))) }
checks <- list()
check <- function(label, pass) checks[[length(checks) + 1L]] <<- data.frame(check = label, pass = isTRUE(pass))
manifest_path <- file.path(capture, "word_table_png_manifest.json")
stopifnot(sha(manifest_path) == "ca9b338b1eb8ee35251190048973b3a37ff09c06cfc2ddefe5f9f511512b0ead")
payload <- jsonlite::fromJSON(manifest_path, simplifyVector = FALSE)
stopifnot(length(payload) == 1L, payload[[1L]]$key == "supp_table_s2")
entries <- payload[[1L]]$files
pins <- read.csv(file.path(record, "attempt5_output_pins.csv"), check.names = FALSE)
observed <- unname(vapply(pins$path, sha, character(1)))
check("eight_completed_capture_files_match_owner_pins", nrow(pins) == 8L && !anyDuplicated(pins$path) &&
  all(observed == pins$sha256) && all(file.info(pins$path)$size == pins$bytes))
main_path <- file.path(owner, "preview_attempt1/main/ZaunerEtAl2026_NatHealth_phase3_brown.html")
fragment_path <- file.path(root, "audit/manuscript_nature_health/figure_table_selection_assets/tbl-near-eye-metrics.html")
stopifnot(sha(main_path) == "5e6c34d6fbcf8ecdd0093514268443eff6835e56e4ffc16e335fa545e62246f8",
  sha(fragment_path) == "6832c791ed3ebcf8895106dafe68c7c5118a12a74e37aacdeb8a84b02d9bfe97")
table <- function(path) xml2::xml_find_first(xml2::read_html(path), "//*[@id='tbl-near-eye-metrics']")
source <- table(main_path); fragment <- table(fragment_path)
parts <- lapply(1:3, function(i) table(file.path(capture, sprintf("supp_table_s2_part_%02d.html", i))))
cells <- function(x) unname(xml2::xml_text(xml2::xml_find_all(x, ".//tbody/tr/*")))
images <- function(x) unname(xml2::xml_attr(xml2::xml_find_all(x, ".//tbody//img"), "src"))
header <- function(x) xml2::xml_text(xml2::xml_find_first(x, ".//thead"))
notes <- function(x) xml2::xml_text(xml2::xml_find_first(x, ".//tfoot"))
space_only <- function(x) gsub("[[:space:]]+", " ", trimws(x))
part_cells <- unlist(lapply(parts, cells), use.names = FALSE)
part_images <- unlist(lapply(parts, images), use.names = FALSE)
check("244_exact_body_cells_in_completed_parts", length(part_cells) == 244L && identical(part_cells, cells(source)))
check("original_fragment_whitespace_only", identical(space_only(part_cells), space_only(cells(fragment))))
check("17_exact_image_payloads", length(part_images) == 17L && identical(part_images, images(source)) && identical(part_images, images(fragment)))
row_widths <- unlist(lapply(parts, function(x) vapply(xml2::xml_find_all(x, ".//tbody/tr"), function(y) length(xml2::xml_children(y)), integer(1))), use.names = FALSE)
check("17_metrics_six_groups_all_14_columns", sum(row_widths == 14L) == 17L && sum(row_widths == 1L) == 6L && all(row_widths %in% c(1L,14L)))
check("three_exact_headers_and_final_notes", all(vapply(parts, function(x) identical(header(x), header(source)), logical(1))) &&
  all(vapply(parts[1:2], function(x) length(xml2::xml_find_all(x, ".//tfoot")) == 0L, logical(1))) && identical(notes(parts[[3L]]), notes(source)))
ranges <- list(c(0L,9L), c(9L,17L), c(17L,23L))
check("original_partition_ranges_and_full_column_sets", length(entries) == 3L && all(vapply(seq_along(entries), function(i)
  identical(as.integer(unlist(entries[[i]]$rowRange)), ranges[[i]]) && identical(as.integer(unlist(entries[[i]]$columns)), 0:13), logical(1))))
check("visible_text_and_image_containment_gates_pass", all(vapply(entries, function(x)
  length(x$verification$numericalTextOverflow) == 0L && all(vapply(x$verification$images, function(img)
    isTRUE(img$contained) && isTRUE(img$ratioPreserved) && img$naturalWidth > 0 && img$naturalHeight > 0, logical(1))), logical(1))))
proofs <- unlist(lapply(entries, function(x) x$verification$screenReaderDescriptions), recursive = FALSE)
contract <- read.csv(file.path(out, "s2_attempt4_hidden_span_contract.csv"), check.names = FALSE)
check("runtime_7_5_5_description_counts", identical(vapply(entries, function(x) length(x$verification$screenReaderDescriptions), integer(1)), c(7L,5L,5L)))
check("all_17_runtime_proofs_exact", length(proofs) == 17L && all(vapply(seq_along(proofs), function(i) {
  p <- proofs[[i]]; e <- contract[i,]
  identical(p$description, e$description) && identical(p$style, e$style) &&
    p$source_body_row == e$source_body_row && p$source_column == 14L &&
    identical(p$parent_tag, e$parent_tag) && identical(p$description_tag, e$description_tag) &&
    identical(p$image_payload_sha256, e$image_payload_sha256) && is.null(p$image_alt) && identical(p$image_aria_hidden, "true") &&
    isTRUE(p$hiddenStylePreserved) && isTRUE(p$sourceImageMatched)
}, logical(1))))
spans <- unlist(lapply(parts, function(x) as.list(xml2::xml_find_all(x, ".//tbody/tr/*[14]/span"))), recursive = FALSE)
check("all_17_hidden_span_texts_and_inline_styles_preserved", length(spans) == 17L &&
  identical(unname(vapply(spans, xml2::xml_text, character(1))), contract$description) &&
  identical(unname(vapply(spans, function(x) xml2::xml_attr(x, "style"), character(1))), contract$style))
png_dimensions <- function(path) {
  con <- file(path, "rb"); on.exit(close(con))
  stopifnot(identical(readBin(con, "raw", 8L), as.raw(c(137,80,78,71,13,10,26,10))),
    readBin(con, "integer", 1L, size = 4L, endian = "big") == 13L,
    rawToChar(readBin(con, "raw", 4L)) == "IHDR")
  unname(readBin(con, "integer", 2L, size = 4L, endian = "big"))
}
geometry <- jsonlite::fromJSON(file.path(record, "intended_word_size_geometry.json"), simplifyVector = FALSE)
dimension_rows <- lapply(seq_along(entries), function(i) {
  original <- png_dimensions(entries[[i]]$path)
  small <- png_dimensions(geometry[[i]]$preview)
  width <- min(15.55, 8.9 * original[1] / original[2]); height <- width * original[2] / original[1]
  stopifnot(identical(original, c(2980L, c(1738L,1452L,1480L)[i])),
    entries[[i]]$cssWidth == 1490L, original[2] == 2L * entries[[i]]$cssHeight,
    max(abs(c(width,height) - c(geometry[[i]]$displayWidthInches,geometry[[i]]$displayHeightInches))) < 1e-10,
    identical(small, as.integer(round(c(width,height) * 96))))
  data.frame(part = i, png = entries[[i]]$path, png_sha256 = sha(entries[[i]]$path),
    width_pixels = original[1], height_pixels = original[2], display_width_inches = width, display_height_inches = height,
    intended_preview = geometry[[i]]$preview, intended_preview_sha256 = sha(geometry[[i]]$preview),
    preview_width = small[1], preview_height = small[2])
})
check("source_and_intended_size_dimensions_exact", length(dimension_rows) == 3L)
check("approved_Table3_and_guard_helper_exact", sha(file.path(root, "audit/manuscript_nature_health/figure_table_selection_assets/table3_gt_candidate_revision/tbl-plan-h01-metric-synthesis-candidate.html")) ==
  "d50b25afae95a95d61641349116e504a2bbf06780b43a46b195ac468246e8dc2" &&
  sha(file.path(owner, "helpers/capture_word_tables.mjs")) == "ecf7525cb5a89438b43588c8ac2acd9ed8e8bcb568b3fc78676ba349792871ec")
result <- do.call(rbind, checks)
write.csv(result, file.path(out, "s2_attempt5_independent_checks.csv"), row.names = FALSE)
write.csv(do.call(rbind, dimension_rows), file.path(out, "s2_attempt5_independent_dimensions.csv"), row.names = FALSE)
write.csv(data.frame(path = pins$path, expected_sha256 = pins$sha256, observed_sha256 = observed, bytes = pins$bytes),
  file.path(out, "s2_attempt5_independent_rehash.csv"), row.names = FALSE)
writeLines(c("Command: RENV_CONFIG_AUTOLOADER_ENABLED=FALSE Rscript --vanilla audit/report_harmonization/report018_order72k_non_s5_integration_dispatch/review_s2_attempt5_capture.R",
  paste("UTC:", format(Sys.time(), "%Y-%m-%d %H:%M:%S", tz = "UTC")),
  "Independent exact-content and layout-geometry checks only. Six existing images were inspected separately at original resolution. No new browser, capture, image editing, render or scientific computation.",
  "The full historical-file replay is deferred until Writer returns from the currently authorized correction renders, to avoid treating in-flight Quarto-owned cache changes as unexplained drift.",
  capture.output(sessionInfo())), file.path(out, "s2_attempt5_independent_session.txt"))
print(result, row.names = FALSE)
stopifnot(all(result$pass))
