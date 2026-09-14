options(stringsAsFactors = FALSE)
stopifnot(getRversion() == "4.6.1")
root <- normalizePath(getwd(), mustWork = TRUE)
owner <- file.path(root, "audit/manuscript_nature_health/revision_2026_09_11/consolidated_display_repair_order72k")
record <- file.path(owner, "s2_width_repair_001")
resolve <- function(p) if (startsWith(p, "/")) p else file.path(root, p)
sha <- function(p) {
  con <- file(p, "rb")
  on.exit(close(con))
  unname(unclass(as.character(openssl::sha256(con))))
}
stopifnot(!file.exists(file.path(record, "stopped_2309_rows.csv")))
transitions <- read.csv(file.path(record, "authorized_transitions.csv"))
stopifnot(nrow(transitions) == 3L, !anyDuplicated(transitions$live))
transitions$live_after_sha256 <- vapply(transitions$live, sha, character(1))
transitions$preimage_after_sha256 <- vapply(transitions$preimage, sha, character(1))
stopifnot(all(transitions$live_after_sha256 == transitions$post_sha256),
          all(transitions$preimage_after_sha256 == transitions$pre_sha256))
write.csv(transitions, file.path(record, "stopped_live_transitions.csv"), row.names = FALSE)
pins <- read.csv(file.path(record, "preflight_2309_rows.csv"))
paths <- vapply(pins$path, resolve, character(1))
idx <- match(paths, transitions$live)
aliased <- !is.na(idx)
stopifnot(nrow(pins) == 2309L,
          setequal(unique(paths[aliased]), transitions$live),
          all(pins$expected_sha256[aliased] == transitions$pre_sha256[idx[aliased]]))
resolved <- paths
resolved[aliased] <- transitions$preimage[idx[aliased]]
pins$historical_preimage_resolution <- aliased
pins$resolved_path <- resolved
pins$stopped_sha256 <- vapply(resolved, sha, character(1))
pins$stopped_bytes <- file.info(resolved)$size
pins$exact <- pins$stopped_sha256 == pins$expected_sha256 & pins$stopped_bytes == pins$expected_bytes
stopifnot(all(pins$exact), all(Sys.readlink(resolved) == ""))
write.csv(pins, file.path(record, "stopped_2309_rows.csv"), row.names = FALSE)
served <- read.csv(file.path(record, "served_preflight.csv"))
served$after_exact <- vapply(served$source, sha, character(1)) == served$sha256 &
  vapply(served$served, sha, character(1)) == served$sha256
stopifnot(nrow(served) == 12L, all(served$after_exact), all(Sys.readlink(served$served) == ""))
write.csv(served, file.path(record, "served_after.csv"), row.names = FALSE)
for (spec in list(
  list(input = file.path(record, "completed_captures_before.csv"), output = "completed_captures_after.csv", rows = 19L),
  list(input = file.path(owner, "environment_capture_recovery_001/attempt3_output_pins.csv"), output = "attempt3_after.csv", rows = 8L))) {
  old <- read.csv(spec$input)
  old$after_exact <- vapply(old$path, sha, character(1)) == old$sha256 & file.info(old$path)$size == old$bytes
  stopifnot(nrow(old) == spec$rows, all(old$after_exact))
  write.csv(old, file.path(record, spec$output), row.names = FALSE)
}
capture <- file.path(owner, "capture_s2_attempt4")
files <- list.files(capture, recursive = TRUE, full.names = TRUE, all.files = TRUE, no.. = TRUE)
stopifnot(length(files) == 1L, basename(files) == "supp_table_s2_source.html", all(Sys.readlink(files) == ""))
write.csv(data.frame(path = files, sha256 = vapply(files, sha, character(1)), bytes = file.info(files)$size),
          file.path(record, "attempt4_partial_output_pins.csv"), row.names = FALSE)
main <- xml2::read_html(file.path(owner, "project/render_html_attempt1/ZaunerEtAl2026_NatHealth_phase3_brown.html"))
rendered <- xml2::xml_find_first(main, ".//table[@id='tbl-near-eye-metrics'] | .//*[@id='tbl-near-eye-metrics']//table")
stopifnot(!inherits(rendered, "xml_missing"))
source <- xml2::read_html(files[[1]])
prior_source <- xml2::read_html(file.path(owner, "capture_s2_attempt3/supp_table_s2_source.html"))
fragment <- xml2::read_html(file.path(root, "audit/manuscript_nature_health/figure_table_selection_assets/tbl-near-eye-metrics.html"))
cells <- function(doc) unname(xml2::xml_text(xml2::xml_find_all(doc, ".//tbody/tr/*")))
payloads <- function(doc) unname(xml2::xml_attr(xml2::xml_find_all(doc, ".//tbody//img"), "src"))
compact <- function(x) gsub("[[:space:]]+", " ", trimws(x))
body <- cells(source)
stopifnot(length(body) == 244L, identical(body, cells(rendered)), identical(body, cells(prior_source)),
          identical(compact(body), compact(cells(fragment))), length(payloads(source)) == 17L,
          identical(payloads(source), payloads(rendered)), identical(payloads(source), payloads(fragment)))
write.csv(data.frame(cell = seq_along(body), attempt4_source = body, frozen_render = cells(rendered),
                     original_fragment = cells(fragment), rendered_exact = body == cells(rendered),
                     original_fragment_whitespace_equal = compact(body) == compact(cells(fragment))),
          file.path(record, "partial_source_cell_comparison.csv"), row.names = FALSE)
description_nodes <- function(doc) xml2::xml_find_all(doc,
  ".//tbody//span[contains(., 'distribution by site. Exact numerical summaries are in the adjacent cells.')]")
hidden <- description_nodes(source)
style <- "position:absolute;width:1px;height:1px;padding:0;margin:-1px;overflow:hidden;clip:rect(0,0,0,0);clip-path:inset(50%);white-space:nowrap;border:0"
stopifnot(length(hidden) == 17L, all(xml2::xml_attr(hidden, "style") == style),
          identical(xml2::xml_text(hidden), xml2::xml_text(description_nodes(rendered))),
          identical(xml2::xml_text(hidden), xml2::xml_text(description_nodes(fragment))))
receipt <- jsonlite::fromJSON(file.path(record, "execution_receipt.json"))
lines <- strsplit(receipt$completion$output, "\n", fixed = TRUE)[[1]]
prefix <- "page.evaluate: Error: S2 all-cell text clipping: "
flag_line <- lines[startsWith(lines, prefix)]
stopifnot(length(flag_line) == 1L, receipt$exit_code == 1L)
flags <- jsonlite::fromJSON(substring(flag_line, nchar(prefix) + 1L))
stopifnot(nrow(flags) == 7L, identical(flags$text, xml2::xml_text(hidden)[1:7]))
flags$source_node <- "span"
flags$source_style <- style
flags$classification <- "Intentionally visually hidden accessibility description; source-based guard false positive, not a visual pass"
write.csv(flags, file.path(record, "guard_flag_classification.csv"), row.names = FALSE)
write.csv(data.frame(description = seq_along(hidden), text = xml2::xml_text(hidden), style = xml2::xml_attr(hidden, "style"),
                     flagged_in_attempt4 = seq_along(hidden) <= 7L),
          file.path(record, "hidden_description_source_evidence.csv"), row.names = FALSE)
harmonizer <- file.path(root, "audit/report_harmonization/report018_order72k_non_s5_integration_dispatch")
evidence <- file.path(harmonizer, c("s2_attempt4_guard_diagnosis.md", "diagnose_s2_attempt4_guard.R", "s2_attempt4_guard_classification.csv", "s2_attempt4_guard_classification_session.txt"))
write.csv(data.frame(path = evidence, sha256 = vapply(evidence, sha, character(1)), bytes = file.info(evidence)$size),
          file.path(record, "independent_diagnosis_pins.csv"), row.names = FALSE)
server <- jsonlite::fromJSON(file.path(record, "server_session.json"))
stopifnot(server$pid == 40429L, server$status == "closed", server$ended == "2026-09-11T20:28:53Z")
checks <- data.frame(
  check = c("historical_2309_rows_exact_with_only_three_authorized_preimages", "three_live_postimages_exact", "immutable_12_served_pairs_exact", "19_prior_capture_files_exact", "eight_attempt3_files_exact", "attempt4_source_only_no_png_or_capture_manifest", "244_source_cells_exact_to_frozen_render", "17_source_image_payloads_exact", "all_seven_flags_are_source_hidden_descriptions", "server_closed", "S2_visual_acceptance"),
  status = c(rep("PASS", 10), "NOT_PERFORMED"),
  scope = c(rep("File identity, structural or protected-content check only", 10), "Capture stopped before first PNG; Unit/Scaling widths are not visually accepted"))
write.csv(checks, file.path(record, "stopped_checks.csv"), row.names = FALSE)
writeLines(c("Read-only file identities, exact protected content and source-markup classification. No scientific result was calculated or adjudicated.",
             "Command: RENV_CONFIG_AUTOLOADER_ENABLED=FALSE R_LIBS_USER=/Users/zauner/Library/R/arm64/4.6/library Rscript --vanilla audit/manuscript_nature_health/revision_2026_09_11/consolidated_display_repair_order72k/s2_width_repair_001/verify_stopped.R",
             paste("openssl", packageVersion("openssl")), paste("xml2", packageVersion("xml2")), paste("jsonlite", packageVersion("jsonlite")),
             capture.output(sessionInfo())), file.path(record, "stopped_verification_session.txt"))
cat("PASS: 2309 historical rows using only three preimages; three exact live postimages; 12 served pairs, 19 initial and eight attempt3 files preserved. Attempt4 contains source HTML only. All 244 source cells and 17 images are unchanged. Seven flags match explicitly hidden spans. Server closed. No visual acceptance.\n")
