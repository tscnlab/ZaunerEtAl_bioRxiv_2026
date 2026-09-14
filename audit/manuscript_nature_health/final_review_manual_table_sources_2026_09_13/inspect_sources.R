# Static HTML metadata only. No browser or rendering operation.
stopifnot(getRversion() == "4.6.1")
library(xml2)
library(openssl)
root <- "/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026"
package <- file.path(root, "audit/manuscript_nature_health/final_review_manual_table_sources_2026_09_13")
map_path <- file.path(root, "audit/manuscript_nature_health/brown_final_integration_2026_09_13/specifications/seven_missing_source_matched_artifacts.csv")
sha <- function(p) { con <- file(p, "rb"); on.exit(close(con)); paste0(as.character(sha256(con))) }
stopifnot(sha(map_path) == "efb61fdf50abf8674b55be1aa1bf8d6e9d21379682cbda87e5745221634e3f69")
map <- read.csv(map_path)
output <- file.path(package, "inspection")
dir.create(output, showWarnings = FALSE)
summary <- character()
for (p in unique(map$source)) {
  stopifnot(sha(p) == unique(map$source_sha256[map$source == p]))
  d <- read_html(p); tables <- xml_find_all(d, "//table")
  stopifnot(length(tables) == 1)
  rows <- xml_find_all(tables, "./tbody/tr")
  summary <- c(summary, paste("SOURCE", p), paste("TABLE", xml_attr(tables, "id"), "class", xml_attr(tables, "class")), paste("ROWS", length(rows)), paste("COLS", paste(xml_attr(xml_find_all(tables, "./colgroup/col"), "style"), collapse = " | ")))
  for (i in seq_along(rows)) summary <- c(summary, paste(i - 1L, xml_attr(rows[[i]], "class"), substr(gsub("\\s+", " ", xml_text(xml_find_first(rows[[i]], "./th|./td"))), 1, 180), sep = " | "))
  spans <- xml_find_all(tables, ".//span[contains(@style, 'nowrap')]")
  units <- spans[grepl("±", xml_text(spans), fixed = TRUE)]
  summary <- c(summary, paste("COMPLETE_NOWRAP_UNITS", length(units)), if (length(units)) paste("EXAMPLE UNIT", as.character(units[[1]])) else "", paste("FOOTER ROWS", length(xml_find_all(tables, "./tfoot/tr"))), paste("IMAGE TYPES", paste(unique(sub(";.*", "", xml_attr(xml_find_all(tables, ".//img"), "src"))), collapse = ", ")))
  ids <- xml_attr(xml_find_all(tables, ".//*[@id]"), "id")
  refs <- unique(unlist(strsplit(xml_attr(xml_find_all(tables, ".//*[@headers]"), "headers"), "\\s+")))
  summary <- c(summary, paste("UNRESOLVED SOURCE HEADERS", paste(setdiff(refs, ids), collapse = " | ")), "")
  writeLines(xml_text(xml_find_all(d, "//style")), file.path(output, paste0(basename(p), ".css")))
}
writeLines(summary, file.path(output, "source_structure.txt"))
capture.output(sessionInfo(), file = file.path(output, "sessionInfo.txt"))
cat(paste(summary, collapse = "\n"), "\n")
