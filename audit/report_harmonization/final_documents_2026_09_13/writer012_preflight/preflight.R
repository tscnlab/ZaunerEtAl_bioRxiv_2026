stopifnot(as.character(getRversion()) == "4.6.1")
root <- normalizePath(getwd(), mustWork = TRUE)
out <- "/private/tmp/writer012-preflight.4N7hbm"
croot <- "audit/manuscript_nature_health/final_format_completion_2026_09_14"
nroot <- "audit/manuscript_nature_health/final_pagination_completion_2026_09_14"
coord <- "audit/report_harmonization/final_documents_2026_09_13"
sha <- function(p) {
  con <- file(p, "rb")
  on.exit(close(con))
  as.character(openssl::sha256(con))
}
verify <- function(path, base, count, expected, name) {
  stopifnot(sha(path) == expected)
  m <- read.csv(path, stringsAsFactors = FALSE)
  paths <- ifelse(startsWith(m$path, "/"), m$path, file.path(base, m$path))
  stopifnot(nrow(m) == count, !anyDuplicated(m$path),
    all(file.exists(paths)), !any(file.info(paths)$isdir),
    !anyDuplicated(normalizePath(paths)),
    !normalizePath(path) %in% normalizePath(paths))
  m$actual_bytes <- file.info(paths)$size
  m$actual_sha256 <- vapply(paths, sha, "")
  m$exact <- m$bytes == m$actual_bytes & m$sha256 == m$actual_sha256
  write.csv(m, file.path(out, paste0(name, "_rehash.csv")), row.names = FALSE)
  stopifnot(all(m$exact))
}
verify(file.path(croot, "completion_manifest.csv"), croot, 271L,
  "86ba7e46cdf106090d8ceaee3109d751dddc32f0f80d62da325ce6b7698583e2", "C271")
verify(file.path(nroot, "completion_manifest.csv"), nroot, 145L,
  "7fce1f1e88980219a1e8199c5440af0ed19070cbf28b3906bcce13d7bd529ad2", "final145")
verify(file.path(coord, "final_site_candidate_order_011_dispatch_manifest.csv"), root, 47L,
  "ed4395ee67a03bde42f1349c97d6cad126517867863e64cc4212cc3eca458c56", "active011_47")
native <- read.csv(file.path(croot, "evidence/native19_identity.csv"), stringsAsFactors = FALSE)
native$actual_sha256 <- vapply(file.path(croot, "editable_tables", native$file), sha, "")
stopifnot(nrow(native) == 19L, !anyDuplicated(native$file), all(native$sha256 == native$actual_sha256))
write.csv(native, file.path(out, "native19_rehash.csv"), row.names = FALSE)
tables <- jsonlite::fromJSON(file.path(croot, "maps/word_table_png_manifest.json"), simplifyVector = FALSE)
selected <- Filter(function(x) x$key %in% c("main_table_2", "main_table_3", "supp_table_s4", "supp_table_s7", "supp_table_s8"), tables)
table_map <- do.call(rbind, lapply(selected, function(x) data.frame(key = x$key,
  parts = length(x$files), total_indexed_rows = tail(x$files, 1)[[1]]$row_end)))
write.csv(table_map, file.path(out, "table_part_baseline.csv"), row.names = FALSE)
stopifnot(table_map$parts[table_map$key == "supp_table_s4"] == 2L,
  table_map$parts[table_map$key == "supp_table_s7"] == 4L,
  table_map$parts[table_map$key == "supp_table_s8"] == 1L)
html <- file.path(croot, "project/html_round2/ZaunerEtAl2026_NatHealth_phase3_brown.html")
dom <- xml2::read_html(html)
checks <- list()
for (id in c("supp-table-s4", "supp-table-s7", "fig-s8", "fig-s15", "fig-s16", "fig-s17")) {
  nodes <- xml2::xml_find_all(dom, sprintf("//*[@id='%s']", id))
  checks[[id]] <- data.frame(endpoint = id, count = length(nodes), exact = length(nodes) == 1L)
}
checks <- do.call(rbind, checks)
stopifnot(all(checks$exact))
write.csv(checks, file.path(out, "exact_endpoint_baseline.csv"), row.names = FALSE)
s4 <- xml2::xml_find_first(dom, "//*[@id='supp-table-s4']")
tab <- xml2::xml_find_first(s4, ".//table")
if (inherits(tab, "xml_missing")) tab <- xml2::xml_find_first(s4, "following::table[1]")
txt <- xml2::xml_text(tab)
repeats <- gregexpr("Four prespecified primary cross-window tests", txt, fixed = TRUE)[[1]]
stopifnot(sum(repeats > 0) == 4L)
writeLines(xml2::xml_text(s4), file.path(out, "s4_reader_baseline.txt"))
pins <- c(file.path(nroot, "deliverables/Nature_Health_manuscript.docx"),
  file.path(croot, "completion_manifest.csv"), html,
  file.path(croot, c("maps/word_table_png_manifest.json", "maps/expanded_svg_manifest.json", "maps/word_figure_svg_manifest.json", "evidence/native19_identity.csv")),
  file.path(coord, c("writer010c_final_independent_acceptance.md", "writer010c_final_independent_acceptance_manifest.csv", "final_site_candidate_order_011.md", "final_site_candidate_order_011_dispatch_manifest.csv")),
  "audit/manuscript_nature_health/a4_display_revision_2026_09_14/revision_plan.md",
  "audit/manuscript_nature_health/figure_table_selection_assets/tbl-plan-brown-cross-window-associations.html",
  "audit/manuscript_nature_health/table_layout_visual_corrections_2026_09_14/attempt_02/source/supp_table_s7_complete.html",
  "audit/manuscript_nature_health/table_layout_visual_corrections_2026_09_14/attempt_02/evidence/cumulative_passage_changes.csv",
  "audit/manuscript_nature_health/table_layout_visual_corrections_2026_09_14/attempt_02/evidence/cumulative_passage_changes.md",
  "_quarto-nathealth.yml", "renv.lock", "audit/report_harmonization/phase4_corpus_manifest.csv",
  "_build/nathealth/index.html", "_build/nathealth/supplementary_information.html")
write.csv(data.frame(path = pins, bytes = file.info(pins)$size, sha256 = vapply(pins, sha, "")),
  file.path(out, "stable_input_pins.csv"), row.names = FALSE)
capture.output(sessionInfo(), file = file.path(out, "session.txt"))
cat("WRITER012_PREFLIGHT=PASS C=271/271 final=145/145 active011=47/47 native=19/19 endpoints=6/6 S4_repeated_family=4\n")
