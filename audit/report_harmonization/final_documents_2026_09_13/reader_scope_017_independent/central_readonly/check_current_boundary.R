stopifnot(getRversion() == "4.6.1")
suppressPackageStartupMessages({library(digest); library(jsonlite); library(xml2)})
project <- "/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026"
audit <- "/private/tmp/reader-scope-audit-20260914.nnDbyu"
out <- "/private/tmp/site017-central-audit.96EdQYvx"
setwd(project)
sha <- function(p) digest(file = p, algo = "sha256")
exact <- function(p, h, n) {
  stopifnot(file.exists(p), !dir.exists(p), !nzchar(Sys.readlink(p)),
    file.info(p)$size == n, sha(p) == h)
}
m <- read.csv(file.path(audit, "live_inventory_before.csv"), check.names = FALSE)
stopifnot(nrow(m) == 914L, !anyDuplicated(m$path))
files <- list.files("_build/nathealth", recursive = TRUE, all.files = TRUE,
  no.. = TRUE, include.dirs = TRUE, full.names = TRUE)
stopifnot(!any(nzchar(Sys.readlink(files))))
files <- files[!file.info(files)$isdir]
stopifnot(setequal(files, file.path("_build/nathealth", m$path)))
for (i in seq_len(nrow(m))) exact(file.path("_build/nathealth", m$path[[i]]), m$sha256[[i]], m$bytes[[i]])
replacements <- read.csv(file.path(audit, "proposed_public_replacement_matrix.csv"), check.names = FALSE)
retirements <- read.csv(file.path(audit, "proposed_public_retirements.csv"), check.names = FALSE)
stopifnot(nrow(replacements) == 45L, nrow(retirements) == 15L,
  !anyDuplicated(c(replacements$path, retirements$path)),
  sum(grepl("[.]html$", replacements$path)) == 43L,
  sum(grepl("^notebooks/sensitivity_battery_files/", retirements$path)) == 12L)
for (i in seq_len(nrow(replacements))) exact(file.path("_build/nathealth", replacements$path[[i]]), replacements$sha256[[i]], replacements$bytes[[i]])
for (i in seq_len(nrow(retirements))) exact(file.path("_build/nathealth", retirements$path[[i]]), retirements$sha256[[i]], retirements$bytes[[i]])
exact("_quarto-nathealth.yml", "e54c71794f4f763a8b50417ab83ff3db37bc9af3fef3f4d1910576ab12c61bc7", 10042)
exact("notebooks/sensitivity_battery.qmd", "d2d1777062dbf58eca69cc58eadd6ad17a7ce80f4a8f335b6828f54ffcbfeb70", 3623)
exact("audit/report_harmonization/phase4_corpus_manifest.csv", "642161dfc1ec18572b8b8c124546060c8f889683ebf7ceb8e5e43dc785f77669", 11479)
corpus <- read.csv("audit/report_harmonization/phase4_corpus_manifest.csv", check.names = FALSE)
stopifnot(nrow(corpus) == 37L, sum(corpus$source == "notebooks/sensitivity_battery.qmd") == 1L)
search <- fromJSON("_build/nathealth/search.json", simplifyVector = FALSE)
drop <- vapply(search, function(x) sub("#.*$", "", x$href) == "notebooks/sensitivity_battery.html", logical(1))
stopifnot(length(search) == 942L, sum(drop) == 4L)
kept <- corpus[corpus$source != "notebooks/sensitivity_battery.qmd", ]
fp <- read.csv(file.path(audit, "retained_reader_scientific_content_fingerprints_R.csv"), check.names = FALSE)
stopifnot(nrow(fp) == 36L, setequal(fp$path, kept$expected_html))
h <- function(x) digest(x, algo = "sha256", serialize = FALSE)
results <- lapply(kept$expected_html, function(p) {
  doc <- read_html(p, options = "HUGE")
  main <- xml_find_all(doc, "//main")
  stopifnot(length(main) == 1L)
  original <- h(as.character(main[[1]]))
  images <- xml_attr(xml_find_all(main[[1]], ".//img"), "src")
  xml_remove(xml_find_all(main[[1]], ".//*[@data-site-utility]"))
  row <- fp[fp$path == p, ]
  stopifnot(nrow(row) == 1L, original == row$raw_main_serialized_sha256,
    h(as.character(main[[1]])) == row$main_without_utility_serialized_sha256,
    h(xml_text(main[[1]])) == row$main_without_utility_text_sha256,
    h(paste(images, collapse = "\n")) == row$image_source_sequence_sha256)
  data.frame(path = p, original_main_exact = TRUE, protected_reader_content_exact = TRUE,
    images_exact = TRUE, stringsAsFactors = FALSE)
})
write.csv(do.call(rbind, results), file.path(out, "independent36_content_baseline.csv"), row.names = FALSE)
write_json(list(status = "PASS", live = 914L, replacements = 45L, retirements = 15L,
  retained_unchanged = 854L, prospective_public_files = 899L, prospective_routes = 36L,
  prospective_search_records = 938L, scientific_content_baselines = 36L,
  R = as.character(getRversion()), package_versions = list(digest = as.character(packageVersion("digest")),
  jsonlite = as.character(packageVersion("jsonlite")), xml2 = as.character(packageVersion("xml2")))),
  file.path(out, "independent_boundary_summary.json"), pretty = TRUE, auto_unbox = TRUE)
capture.output(sessionInfo(), file = file.path(out, "R_sessionInfo.txt"))
cat("ORDER017_CENTRAL_READONLY_PREFLIGHT=PASS live914 replacement45 retirement15 baseline36 R4.6.1\n")
