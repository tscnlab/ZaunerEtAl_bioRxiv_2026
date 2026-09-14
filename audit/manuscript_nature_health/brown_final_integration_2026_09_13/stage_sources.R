#!/usr/bin/env Rscript
# Copy/extract frozen sources only. Does not evaluate a QMD or load a model.
stopifnot(getRversion() == "4.6.1")
library(openssl)
library(xml2)
options(stringsAsFactors = FALSE)
project <- "/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026"
brown <- "/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026/audit/analyses/brown_adherence"
package <- file.path(project, "audit/manuscript_nature_health/brown_final_integration_2026_09_13")
hash <- function(path) { con <- file(path, "rb"); on.exit(close(con)); paste0(as.character(sha256(con))) }
copy_exact <- function(from, to, expected = NULL) {
  stopifnot(file.exists(from))
  if (!is.null(expected)) stopifnot(identical(hash(from), expected))
  dir.create(dirname(to), recursive = TRUE, showWarnings = FALSE)
  if (!file.exists(to)) stopifnot(file.copy(from, to))
  stopifnot(identical(hash(from), hash(to)))
  data.frame(source = from, destination = to, sha256 = hash(from), bytes = file.info(from)$size)
}
records <- list()
main_name <- "ZaunerEtAl2026_NatHealth_phase3_brown.qmd"
si_name <- "supplementary_information_outline.qmd"
for (name in c(main_name, si_name, "_quarto.yml", "references_merged.bib", "manuscript_displays.css")) {
  from <- file.path(project, "manuscript/R0_NatHealth", name)
  expected <- switch(name,
    ZaunerEtAl2026_NatHealth_phase3_brown.qmd = "c6beb79ca34128c0b69d882c1e3ea332cb88664ce9a3c0883b39d1569db0a0d0",
    supplementary_information_outline.qmd = "fbfdde52cd24a60a5ff19eefb7901d3b7dcb268d97c2c922e0e87e7c944c652e",
    `_quarto.yml` = "3ed50e7dc3339bd42fc19393f10480baf733f485a65f34c03980fe4d466c5cf0", NULL)
  records[[length(records) + 1L]] <- copy_exact(from, file.path(package, "preimages", name), expected)
  if (name %in% c(main_name, si_name)) records[[length(records) + 1L]] <- copy_exact(from, file.path(package, "source", name), expected)
}
report_path <- file.path(brown, "13_cross_state_association_results_amendment.html")
stopifnot(hash(report_path) == "3075b160cebedd20db35f97ee47302c77ac259676f04faec4ba9effa68ce2dd9")
raw_report <- readBin(report_path, "raw", n = file.info(report_path)$size)
text_report <- rawToChar(raw_report)
Encoding(text_report) <- "UTF-8"
doc <- read_html(report_path)
extractions <- list()
for (id in c("tbl-main-adherence-levels", "tbl-main-primary-results")) {
  table <- xml_find_first(doc, sprintf("//*[@id='%s']//table", id))
  wrapper <- xml_find_first(table, "ancestor::div[@id][1]")
  wrapper_id <- xml_attr(wrapper, "id")
  # Locate the exact gt wrapper, including its unmodified scoped CSS.
  start <- regexpr(paste0('<div id="', wrapper_id, '"'), text_report, fixed = TRUE, useBytes = TRUE)[1]
  stopifnot(start > 0)
  tail_raw <- raw_report[start:length(raw_report)]
  tail <- rawToChar(tail_raw)
  tags <- gregexpr("</?div\\b[^>]*>", tail, perl = TRUE, useBytes = TRUE)[[1]]
  lengths <- attr(tags, "match.length")
  depth <- 0L; end <- NA_integer_
  for (i in seq_along(tags)) {
    tag <- rawToChar(tail_raw[tags[i]:(tags[i] + lengths[i] - 1L)])
    depth <- depth + if (startsWith(tag, "</")) -1L else 1L
    if (depth == 0L) { end <- tags[i] + lengths[i] - 1L; break }
  }
  stopifnot(!is.na(end))
  exact <- tail_raw[seq_len(end)]
  to <- file.path(package, "source/brown_assets", paste0(id, ".html"))
  dir.create(dirname(to), recursive = TRUE, showWarnings = FALSE)
  stopifnot(!file.exists(to)); writeBin(exact, to)
  stopifnot(identical(exact, raw_report[start:(start + end - 1L)]))
  extractions[[length(extractions) + 1L]] <- data.frame(
    report = report_path, report_sha256 = hash(report_path), table_id = id,
    gt_wrapper_id = wrapper_id, byte_start_1_based = start,
    byte_end_inclusive = start + end - 1L, destination = to, sha256 = hash(to),
    tbody_rows = length(xml_find_all(table, "./tbody/tr")),
    columns = length(xml_find_all(table, "./thead/tr[last()]/th")))
}
for (name in c("main_adherence_levels.svg", "main_site_workday.svg", "main_site_free_work.svg")) {
  records[[length(records) + 1L]] <- copy_exact(
    file.path(brown, "main_linkage_b_amendment/stage3/figures", name),
    file.path(package, "source/brown_assets", name))
}
for (name in c("main_adherence_levels_source.csv", "main_site_workday_source.csv", "main_site_free_work_source.csv")) {
  records[[length(records) + 1L]] <- copy_exact(
    file.path(brown, "main_linkage_b_amendment/stage3/source_data", name),
    file.path(package, "frozen", name))
}
for (key in c("samples", "levels", "primary", "interactions", "coverage", "r2", "shapley_global", "shapley_within", "chest", "multiplicity", "localizations", "grouping", "pair_eligibility", "diagnostics", "measurement", "model_components")) {
  name <- paste0("table_", key, "_source.csv")
  records[[length(records) + 1L]] <- copy_exact(
    file.path(brown, "main_linkage_b_amendment/stage3/source_data", name),
    file.path(package, "frozen", name))
}
for (key in c("table_association_effects", "table_coverage_gate", "table_selected_sample")) {
  records[[length(records) + 1L]] <- copy_exact(
    file.path(brown, "stage3_cross_state_association/source_data", paste0(key, ".csv")),
    file.path(package, "frozen", paste0(key, ".csv")))
}
dir.create(file.path(package, "records"), showWarnings = FALSE)
write.csv(do.call(rbind, records), file.path(package, "records/copy_manifest.csv"), row.names = FALSE)
write.csv(do.call(rbind, extractions), file.path(package, "records/exact_display_extractions.csv"), row.names = FALSE)
capture.output(sessionInfo(), file = file.path(package, "records/staging_session.txt"))
cat("Preimages, candidate QMD copies, exact accepted table excerpts and three SVG copies staged. No render.\n")
