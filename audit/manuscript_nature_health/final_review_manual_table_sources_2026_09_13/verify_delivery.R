# Final static delivered-file check only; no browser, capture or rendering.
stopifnot(getRversion() == "4.6.1")
library(xml2)
library(openssl)
library(jsonlite)
project <- "/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026"
package <- file.path(project, "audit/manuscript_nature_health/final_review_manual_table_sources_2026_09_13")
accepted <- file.path(project, "audit/manuscript_nature_health/brown_final_integration_2026_09_13")
out <- file.path(package, "delivery_verification")
stopifnot(!file.exists(out)); dir.create(out)
sha <- function(p) { con <- file(p, "rb"); on.exit(close(con)); paste0(as.character(sha256(con))) }
map <- read.csv(file.path(package, "page_manifest.csv"))
checks <- list()
check <- function(name, pass) {
  checks[[length(checks) + 1L]] <<- data.frame(check = name, pass = isTRUE(pass))
  write.csv(do.call(rbind, checks), file.path(out, "checks.csv"), row.names = FALSE)
  stopifnot(isTRUE(pass))
}
check("controlling_order_exact", sha(file.path(project, "audit/report_harmonization/final_documents_2026_09_13/writer_source_acceptance_and_manual_sources_002.md")) == "8f666099974e1fdbadb80d22e12933421409b57cac4d3303ce656b6b813e9acd")
check("all_411_source_checks_passed", all(read.csv(file.path(package, "attempt_02/verification/checks.csv"))$pass) && nrow(read.csv(file.path(package, "attempt_02/verification/checks.csv"))) == 411)
check("seven_final_pages_exact", all(vapply(file.path(package, map$page), sha, character(1)) == map$page_sha256))
check("seven_page_bytes_same_across_attempts", all(read.csv(file.path(package, "attempt_comparison.csv"))$attempt_01_sha256 == map$page_sha256))
html <- c(map$page, "index.html", "manual_capture_guide.html")
for (name in html) {
  page <- read_html(file.path(package, name))
  check(paste(name, "no active script, frame, object, form or fetch links"), length(xml_find_all(page, "//script|//iframe|//object|//embed|//form|//link|//base|//video|//audio|//source")) == 0)
  check(paste(name, "no remote CSS resources"), !grepl("url\\s*\\(|@import|@font-face", paste(xml_text(xml_find_all(page, "//style")), collapse = "\n"), ignore.case = TRUE))
  links <- xml_attr(xml_find_all(page, "//a[@href]"), "href")
  check(paste(name, "links confined to delivered local pages"), all(links %in% html))
  check(paste(name, "local links resolve"), all(file.exists(file.path(package, links))))
  ids <- xml_attr(xml_find_all(page, "//*[@id]"), "id")
  check(paste(name, "unique page IDs"), !anyDuplicated(ids))
}
for (name in c("index.html", "manual_capture_guide.html", "manual_capture_guide.md")) {
  text <- paste(readLines(file.path(package, name), warn = FALSE), collapse = "\n")
  check(paste(name, "lists every exact source page and hash"), all(vapply(map$page, grepl, logical(1), x = text, fixed = TRUE)) && all(vapply(map$page_sha256, grepl, logical(1), x = text, fixed = TRUE)))
}
members <- read.csv(file.path(accepted, "package_manifest.csv"))
check("accepted_84_member_source_package_unchanged", nrow(members) == 84 && all(vapply(file.path(accepted, members$path), sha, character(1)) == members$sha256))
check("no_captured_PNG_or_document_output", length(list.files(package, recursive = TRUE, pattern = "\\.(png|docx|pdf|zip)$", ignore.case = TRUE)) == 0)
all_files <- list.files(package, recursive = TRUE, full.names = TRUE, all.files = TRUE, no.. = TRUE)
check("no_symlinks", all(is.na(Sys.readlink(all_files)) | !nzchar(Sys.readlink(all_files))))
capture.output(sessionInfo(), file = file.path(out, "sessionInfo.txt"))
write_json(list(status = "DELIVERED_STATIC_SOURCES_ONLY", passing_delivery_checks = length(checks), source_checks = 411, exact_pages = 7, visuals_assessed = FALSE, images_supplied = FALSE, final_documents_produced = FALSE), file.path(out, "result.json"), auto_unbox = TRUE, pretty = TRUE)
cat("PASS:", length(checks), "delivery checks. Static content only; no visual PASS.\n")
