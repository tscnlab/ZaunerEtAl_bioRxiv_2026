#!/usr/bin/env Rscript
options(stringsAsFactors = FALSE)
stopifnot(getRversion() == "4.6.1")
task_root <- normalizePath(getwd(), mustWork = TRUE)
audit_root <- normalizePath(commandArgs(trailingOnly = TRUE)[[1]], mustWork = TRUE)
dispatch_root <- file.path(task_root, "audit/report_harmonization/report018_order72j_component_exports_dispatch")
sha <- function(path) {
  con <- file(path, "rb")
  on.exit(close(con))
  unname(unclass(as.character(openssl::sha256(con))))
}
resolve <- function(path) if (startsWith(path, "/")) path else file.path(task_root, path)
pin_rows <- function(paths) {
  data.frame(path = paths, sha256 = vapply(paths, function(x) sha(resolve(x)), character(1)),
             bytes = unname(file.info(vapply(paths, resolve, character(1)))$size))
}
checks <- list()
add <- function(id, pass, detail) {
  checks[[length(checks) + 1L]] <<- data.frame(check = id, pass = isTRUE(pass), detail = detail)
}
audit_manifest <- function(path, expected_rows) {
  x <- read.csv(resolve(path), check.names = FALSE)
  observed <- pin_rows(x$path)
  good <- identical(observed$sha256, x$sha256) && all(observed$bytes == x$bytes) &&
    !anyDuplicated(x$path) && !any(vapply(x$path, resolve, character(1)) == resolve(path)) &&
    nrow(x) == expected_rows
  add(basename(path), good, sprintf("%d/%d live-exact, unique, non-circular", sum(observed$sha256 == x$sha256 & observed$bytes == x$bytes), nrow(x)))
  stopifnot(good)
  x
}
review_manifest <- audit_manifest("audit/report_harmonization/report018_order72j_component_exports_dispatch/component_review_manifest.csv", 28L)
before_review <- pin_rows(c(review_manifest$path, "audit/report_harmonization/report018_order72j_component_exports_dispatch/component_review_manifest.csv"))
for (spec in list(
  list(script = "review_h07_static.R", output = "h07_static_independent_review.csv", count = 32L),
  list(script = "review_h09_static.R", output = "h09_static_independent_review.csv", count = 41L),
  list(script = "finalize_component_review.R", output = "component_review_checks.csv", count = 30L)
)) {
  replay_env <- new.env(parent = globalenv())
  replay_env$write.csv <- function(x, file, ...) {
    stopifnot(identical(dirname(file), dispatch_root), basename(file) %in% c("h07_static_independent_review.csv", "h09_static_independent_review.csv", "component_review_checks.csv", "component_status.csv"))
    utils::write.csv(x, file.path(audit_root, basename(file)), ...)
  }
  replay_env$writeLines <- function(text, con = stdout(), ...) {
    stopifnot(is.character(con), identical(dirname(con), dispatch_root), basename(con) %in% c("h07_static_independent_session.txt", "h09_static_independent_session.txt", "component_review_session.txt"))
    base::writeLines(text, file.path(audit_root, basename(con)), ...)
  }
  sys.source(file.path(dispatch_root, spec$script), envir = replay_env)
  observed <- read.csv(file.path(audit_root, spec$output), check.names = FALSE)
  original <- read.csv(file.path(dispatch_root, spec$output), check.names = FALSE)
  add(spec$script, nrow(observed) == spec$count && all(observed$status == "PASS") && identical(observed, original), sprintf("%d/%d, exact sealed check-table reproduction, outputs redirected to temporary audit root", sum(observed$status == "PASS"), nrow(observed)))
}
after_review <- pin_rows(before_review$path)
add("sealed_review_unchanged", identical(before_review, after_review), "All 28 members and review manifest unchanged by replay")
inventory_path <- "audit/manuscript_nature_health/consolidated_display_repair_2026_09_11/read_only_preflight/source_authority_inventory.csv"
authority <- read.csv(resolve(inventory_path), check.names = FALSE)
authority_observed <- pin_rows(authority$path)
authority_ok <- authority_observed$sha256 == authority$sha256 & authority_observed$bytes == authority$bytes
write.csv(cbind(authority[, c("id", "path", "sha256", "bytes")], actual_sha256 = authority_observed$sha256, actual_bytes = authority_observed$bytes, pass = authority_ok), file.path(audit_root, "authority_pin_recheck.csv"), row.names = FALSE)
add("source_authority_inventory", all(authority_ok), sprintf("%d/%d frozen source, manuscript, display, and implementation pins exact", sum(authority_ok), nrow(authority)))
components <- c(
  "artifacts/10_figures/H01/stage3/H01_stage3_model_support.svg",
  "audit/hypotheses/H07/report018_order72j_split_svg_export/candidate/H07_revised_smooth_derivative_pairs_near_eye.svg",
  "audit/hypotheses/H09/report018_order72j_split_svg_export/candidate/H09_primary_effects.svg",
  "audit/hypotheses/H09/report018_order72j_split_svg_export/candidate/H09_observed_timing_patterns.svg",
  "audit/hypotheses/H06/report018_order72_svg_export/candidate/H06_stage3_site_specific_significance_screen.svg",
  "audit/hypotheses/H11/report018_order72_svg_export/candidate/H11_reader_primary_near_eye_curves.svg"
)
structure <- do.call(rbind, lapply(components, function(path) {
  doc <- xml2::read_xml(resolve(path))
  ids <- xml2::xml_attr(xml2::xml_find_all(doc, "//*[@id]"), "id")
  data.frame(path = path, image_nodes = length(xml2::xml_find_all(doc, "//*[local-name()='image']")), script_nodes = length(xml2::xml_find_all(doc, "//*[local-name()='script' or local-name()='foreignObject']")), duplicate_ids = anyDuplicated(ids), width = xml2::xml_attr(xml2::xml_root(doc), "width"), height = xml2::xml_attr(xml2::xml_root(doc), "height"))
}))
write.csv(structure, file.path(audit_root, "component_structure.csv"), row.names = FALSE)
add("six_integration_svg_structure", all(structure$image_nodes == 0L & structure$script_nodes == 0L & structure$duplicate_ids == 0L), "H01, H07, both H09, accepted S12 and accepted S17 parse and contain no raster/image/script/foreignObject or duplicate IDs")
s12 <- paste(readLines(resolve(components[[5]]), warn = FALSE), collapse = "\n")
add("s12_mder_legend_absent", !grepl("MDER", s12, ignore.case = TRUE), "Accepted S12 exact and contains no MDER text")
lease_rows <- do.call(rbind, lapply(1:3, function(i) read.csv(file.path(dispatch_root, sprintf("visual_lease_%03d_return.csv", i)), check.names = FALSE)))
write.csv(lease_rows, file.path(audit_root, "closed_leases.csv"), row.names = FALSE)
add("visual_not_overclaimed", all(grepl("REJECT|STOP", lease_rows$return_status)), "All returned leases stopped before content load; no component visual acceptance asserted")
selection_path <- "audit/manuscript_nature_health/manuscript_figure_table_selection.qmd"
supp_path <- "manuscript/R0_NatHealth/supplementary_information_outline.qmd"
main_path <- "manuscript/R0_NatHealth/ZaunerEtAl2026_NatHealth_phase3_brown.qmd"
read_text <- function(path) paste(readLines(resolve(path), warn = FALSE), collapse = "\n")
selection <- read_text(selection_path)
supp <- read_text(supp_path)
main <- read_text(main_path)
blocks <- function(x) regmatches(x, gregexpr("(?s)<figure\\b.*?</figure>", x, perl = TRUE))[[1]]
sel_blocks <- blocks(selection)
supp_blocks <- blocks(supp)
for (id in c("fig-s5", "fig-s7", "fig-s15", "fig-s17")) {
  sel <- sel_blocks[grepl(paste0('id="', id, '"'), sel_blocks, fixed = TRUE)]
  sp <- supp_blocks[grepl(paste0('id="', id, '"'), supp_blocks, fixed = TRUE)]
  stopifnot(length(sel) == 1L, length(sp) == 1L)
  writeLines(sel, file.path(audit_root, paste0("selection_", id, "_baseline.html")), useBytes = TRUE)
  writeLines(sp, file.path(audit_root, paste0("supplement_", id, "_baseline.html")), useBytes = TRUE)
}
add("source_engine_boundary", !any(grepl("```\\{(r|python|julia)|`r[[:space:]]", c(selection, supp, main))), "Selection and manuscript sources have no analytical code cells or inline R")
add("twenty_numbered_figures", length(sel_blocks) == 20L, paste("Selection figure blocks:", length(sel_blocks)))
add("h06_daily_excluded", !grepl("H06_daily|H06.daily", paste(sel_blocks, collapse = "\n")) && !grepl("H06_daily|H06.daily", paste(supp_blocks, collapse = "\n")), "No H06_daily figure source or numbered-figure caption in selection or supplement")
additional <- c("_quarto.yml", "_quarto-nathealth.yml", "manuscript/R0_NatHealth/_quarto.yml", "manuscript/R0_NatHealth/supplementary_information_standalone.qmd", "scripts/manuscript_nature_health/capture_word_tables.mjs", "scripts/manuscript_nature_health/prepare_word_manuscript.py", "scripts/manuscript_nature_health/embed_accepted_svg_figures.py", "audit/manuscript_nature_health/consolidated_display_repair_2026_09_11/read_only_preflight/proposed_change_matrix.csv", "audit/manuscript_nature_health/consolidated_display_repair_2026_09_11/read_only_preflight/display_component_caption_map.csv", "audit/manuscript_nature_health/consolidated_display_repair_2026_09_11/read_only_preflight/owner_path_and_serial_order.md", "audit/manuscript_nature_health/consolidated_display_repair_2026_09_11/read_only_preflight/prospective_checks.md", "audit/decisions/brown_main_linkage_b_stage2_derivative_gate_recovery_001/dispatch_rejection.md", "audit/decisions/brown_main_linkage_b_stage2_derivative_gate_recovery_001/dispatch_rejection_manifest.csv")
all_pins <- unique(c(authority$path, components, review_manifest$path, "audit/report_harmonization/report018_order72j_component_exports_dispatch/component_review_manifest.csv", additional))
write.csv(pin_rows(all_pins), file.path(audit_root, "integration_input_pins.csv"), row.names = FALSE)
result <- do.call(rbind, checks)
write.csv(result, file.path(audit_root, "independent_checks.csv"), row.names = FALSE)
writeLines(c(capture.output(sessionInfo()), paste("openssl", packageVersion("openssl")), paste("xml2", packageVersion("xml2")), paste("command:", paste(commandArgs(), collapse = " "))), file.path(audit_root, "session_info.txt"))
print(result[, c("check", "pass")], row.names = FALSE)
stopifnot(all(result$pass))
cat(sprintf("ORDER72K_INDEPENDENT_PREFLIGHT=PASS checks=%d pins=%d static=32+41+30 visual=pending Brown=held\n", nrow(result), length(all_pins)))
