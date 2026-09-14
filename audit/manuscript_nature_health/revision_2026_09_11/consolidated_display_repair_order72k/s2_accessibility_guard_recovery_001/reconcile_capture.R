options(stringsAsFactors = FALSE)
stopifnot(getRversion() == "4.6.1")
root <- normalizePath(getwd(), mustWork = TRUE)
owner <- file.path(root, "audit/manuscript_nature_health/revision_2026_09_11/consolidated_display_repair_order72k")
record <- file.path(owner, "s2_accessibility_guard_recovery_001")
capture <- file.path(owner, "capture_s2_attempt5")
sha <- function(p) { con <- file(p, "rb"); on.exit(close(con)); unname(unclass(as.character(openssl::sha256(con)))) }
stopifnot(!file.exists(file.path(record, "capture_checks.csv")))
manifest_path <- file.path(capture, "word_table_png_manifest.json")
m <- jsonlite::fromJSON(manifest_path, simplifyVector = FALSE)
stopifnot(length(m) == 1L, m[[1]]$key == "supp_table_s2", length(m[[1]]$files) == 3L)
parts <- lapply(m[[1]]$files, function(x) xml2::read_html(sub("\\.png$", ".html", x$path)))
source <- xml2::read_html(file.path(capture, "supp_table_s2_source.html"))
frozen <- xml2::read_html(file.path(owner, "capture_s2_attempt4/supp_table_s2_source.html"))
fragment <- xml2::read_html(file.path(root, "audit/manuscript_nature_health/figure_table_selection_assets/tbl-near-eye-metrics.html"))
cells <- function(x) unname(xml2::xml_text(xml2::xml_find_all(x, ".//tbody/tr/*")))
imgs <- function(x) unname(xml2::xml_attr(xml2::xml_find_all(x, ".//tbody//img"), "src"))
compact <- function(x) gsub("[[:space:]]+", " ", trimws(x))
body <- unlist(lapply(parts, cells), use.names = FALSE)
images <- unlist(lapply(parts, imgs), use.names = FALSE)
header <- function(x) xml2::xml_text(xml2::xml_find_first(x, ".//thead"))
footer <- function(x) xml2::xml_text(xml2::xml_find_first(x, ".//tfoot"))
desc <- function(x) xml2::xml_find_all(x, ".//tbody//span[contains(., 'distribution by site. Exact numerical summaries are in the adjacent cells.')]")
source_desc <- desc(source)
part_desc <- unlist(lapply(parts, function(x) xml2::xml_text(desc(x))), use.names = FALSE)
style <- "position:absolute;width:1px;height:1px;padding:0;margin:-1px;overflow:hidden;clip:rect(0,0,0,0);clip-path:inset(50%);white-space:nowrap;border:0"
widths <- lengths(lapply(xml2::xml_find_all(source, ".//tbody/tr"), xml2::xml_children))
proof <- do.call(c, lapply(m[[1]]$files, function(x) x$verification$screenReaderDescriptions))
contract <- read.csv(file.path(root, "audit/report_harmonization/report018_order72k_s2_accessibility_guard_recovery_001/proposal_replay/independent_contract.csv"))
proof_ok <- vapply(seq_along(proof), function(i) {
  x <- proof[[i]]
  identical(x$description, xml2::xml_text(source_desc)[i]) && identical(x$style, style) &&
    x$source_body_row == which(widths == 14L)[i] && x$source_column == 14L &&
    identical(x$parent_tag, "td") && identical(x$description_tag, "span") &&
    identical(x$image_aria_hidden, "true") && is.null(x$image_alt) &&
    identical(x$image_payload_sha256, unname(unclass(as.character(openssl::sha256(charToRaw(images[i]))))))) &&
    isTRUE(x$hiddenStylePreserved) && isTRUE(x$sourceImageMatched)
}, logical(1))
checks <- data.frame(check = c("244_cells_exact_to_frozen_rendered_source", "244_cells_exact_to_attempt5_source", "original_fragment_whitespace_only", "17_image_payloads_exact", "23_rows_17_metrics_six_groups_14_columns", "three_complete_headers", "final_notes_only_last_part", "all_three_full_column_sets", "runtime_hidden_proof_counts_7_5_5", "17_hidden_proofs_match_source_text_style_location_image", "hidden_styles_preserved_in_all_part_HTML", "all_visible_cell_edge_checks_empty", "source_17_descriptions_retained"),
  pass = c(length(body) == 244L && identical(body, cells(frozen)), identical(body, cells(source)), identical(compact(body), compact(cells(fragment))),
    length(images) == 17L && identical(images, imgs(source)) && identical(images, imgs(fragment)),
    length(widths) == 23L && sum(widths == 14L) == 17L && sum(widths == 1L) == 6L,
    all(vapply(parts, function(x) identical(header(x), header(source)), logical(1))),
    all(vapply(parts[1:2], function(x) length(xml2::xml_find_all(x, ".//tfoot")) == 0L, logical(1))) && identical(footer(parts[[3]]), footer(source)),
    all(vapply(m[[1]]$files, function(x) identical(as.integer(unlist(x$columns)), 0:13), logical(1))),
    identical(as.integer(vapply(m[[1]]$files, function(x) length(x$verification$screenReaderDescriptions), integer(1))), c(7L, 5L, 5L)),
    length(proof) == 17L && all(proof_ok),
    all(unlist(lapply(parts, function(x) xml2::xml_attr(desc(x), "style")), use.names = FALSE) == style),
    all(vapply(m[[1]]$files, function(x) length(x$verification$numericalTextOverflow) == 0L, logical(1))),
    length(source_desc) == 17L && identical(part_desc, xml2::xml_text(source_desc)) && identical(part_desc, xml2::xml_text(desc(frozen)))))
write.csv(checks, file.path(record, "capture_checks.csv"), row.names = FALSE)
stopifnot(all(checks$pass), nrow(contract) == 17L)
write.csv(data.frame(cell = seq_along(body), source = cells(frozen), capture = body, exact = body == cells(frozen)), file.path(record, "all_244_cells.csv"), row.names = FALSE)
write.csv(data.frame(source_body_row = vapply(proof, function(x) x$source_body_row, integer(1)),
                     description = vapply(proof, function(x) x$description, character(1)),
                     image_payload_sha256 = vapply(proof, function(x) x$image_payload_sha256, character(1)),
                     source_style_exact = proof_ok, runtime_hidden_semantics_passed = TRUE),
          file.path(record, "runtime_hidden_description_proof.csv"), row.names = FALSE)
files <- sort(list.files(capture, recursive = TRUE, full.names = TRUE, all.files = TRUE, no.. = TRUE))
stopifnot(length(files) == 8L, all(Sys.readlink(files) == ""))
write.csv(data.frame(path = files, sha256 = vapply(files, sha, character(1)), bytes = file.info(files)$size), file.path(record, "attempt5_output_pins.csv"), row.names = FALSE)
writeLines(c("Structural/protected-content checks only. No scientific recomputation. Visual review is recorded separately.",
             "Command: RENV_CONFIG_AUTOLOADER_ENABLED=FALSE R_LIBS_USER=/Users/zauner/Library/R/arm64/4.6/library Rscript --vanilla audit/manuscript_nature_health/revision_2026_09_11/consolidated_display_repair_order72k/s2_accessibility_guard_recovery_001/reconcile_capture.R",
             paste("openssl", packageVersion("openssl")), paste("xml2", packageVersion("xml2")), paste("jsonlite", packageVersion("jsonlite")), capture.output(sessionInfo())),
           file.path(record, "capture_reconciliation_session.txt"))
cat("PASS13/13:244 cells,17 payloads,17 source descriptions, runtime7/5/5 exact hidden proofs, visible text containment, complete rows/headers/notes. Capture manifest SHA:", sha(manifest_path), "\n")
