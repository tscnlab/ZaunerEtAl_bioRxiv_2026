stopifnot(getRversion() == "4.6.1")
suppressPackageStartupMessages({library(digest); library(jsonlite); library(xml2)})
args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) == 4L)
site <- normalizePath(args[[1]], mustWork = TRUE)
profile <- args[[2]]
corpus_path <- args[[3]]
out <- args[[4]]
stopifnot(!dir.exists(out))
project <- "/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026"
base <- file.path(project, "audit/report_harmonization/final_documents_2026_09_13/reader_scope_017_independent/owner_readonly")
sha <- function(p) digest(file = p, algo = "sha256")
hash <- function(s) digest(s, algo = "sha256", serialize = FALSE)
exact <- function(p, h, bytes) stopifnot(file.exists(p), !dir.exists(p),
  !nzchar(Sys.readlink(p)), sha(p) == h, file.info(p)$size == bytes)
read_raw_text <- function(p) rawToChar(readBin(p, "raw", n = file.info(p)$size))
old <- read.csv(file.path(base, "live_inventory_before.csv"), check.names = FALSE)
change <- read.csv(file.path(base, "proposed_public_replacement_matrix.csv"), check.names = FALSE)
retire <- read.csv(file.path(base, "proposed_public_retirements.csv"), check.names = FALSE)
ref <- read.csv(file.path(base, "sensitivity_inbound_exact.csv"), check.names = FALSE)
all <- list.files(site, recursive = TRUE, all.files = TRUE, no.. = TRUE, include.dirs = TRUE, full.names = TRUE)
stopifnot(!any(nzchar(Sys.readlink(all))))
all <- all[!file.info(all)$isdir]
new_paths <- substring(all, nchar(site) + 2L)
stopifnot(length(all) == 899L, setequal(new_paths, setdiff(old$path, retire$path)),
  !any(file.exists(file.path(site, retire$path))))
unchanged <- old[!old$path %in% c(change$path, retire$path), ]
stopifnot(nrow(unchanged) == 854L)
for (i in seq_len(nrow(unchanged))) exact(file.path(site, unchanged$path[[i]]), unchanged$sha256[[i]], unchanged$bytes[[i]])
stopifnot(all(vapply(change$path, function(p) sha(file.path(site, p)), character(1)) != change$sha256))
old_doc <- function(p) read_html(file.path(base, "preimages/_build/nathealth", p), options = "HUGE")
norm <- function(d) {
  xml_remove(xml_find_all(d, "//text()[normalize-space(.)='']"))
  as.character(d)
}
dom_checks <- lapply(change$path[grepl("[.]html$", change$path)], function(p) {
  pre <- old_doc(p)
  post <- read_html(file.path(site, p), options = "HUGE")
  rows <- ref[ref$route == p, ]
  targets <- lapply(seq_len(nrow(rows)), function(i) {
    node <- xml_find_all(pre, rows$xpath[[i]])
    stopifnot(length(node) == 1L, xml_attr(node[[1]], "href") == rows$ref[[i]])
    area <- rows$area[[i]]
    if (area %in% c("navbar", "sidebar")) {
      node <- xml_find_all(node[[1]], "ancestor::li[1]")
    } else if (area == "previous_next") {
      node <- xml_find_all(node[[1]], "ancestor::div[contains(concat(' ',normalize-space(@class),' '),' nav-page-next ')][1]")
    } else stopifnot(area == "head", xml_name(node[[1]]) == "link")
    stopifnot(length(node) == 1L)
    node[[1]]
  })
  for (node in targets) xml_remove(node)
  if (p == "index.html") {
    utility <- xml_find_all(pre, "//section[@data-site-utility='true' and @aria-labelledby='site-downloads-title']")
    stopifnot(length(utility) == 1L)
    xml_remove(utility)
    stopifnot(length(xml_find_all(post, "//section[@data-site-utility='true' and @aria-labelledby='site-downloads-title']")) == 0L)
  }
  if (p == "supplementary_information.html") {
    for (query in c("//section[@data-site-utility='true' and @aria-labelledby='site-downloads-title']/p[a[contains(@href,'manuscript_changes.csv')]]",
      "//section[@data-site-utility='true' and @aria-labelledby='site-passage-changes']",
      "//nav[@role='doc-toc']//a[@href='#site-passage-changes']/ancestor::li[1]")) {
      node <- xml_find_all(pre, query)
      stopifnot(length(node) == 1L)
      xml_remove(node)
    }
    stopifnot(length(xml_find_all(post, "//section[@data-site-utility='true' and @aria-labelledby='site-downloads-title']//a")) == 21L)
  }
  stopifnot(identical(norm(pre), norm(post)))
  data.frame(path = p, only_exact_authorized_dom_removals = TRUE, stringsAsFactors = FALSE)
})
old_search <- fromJSON(file.path(base, "preimages/_build/nathealth/search.json"), simplifyVector = FALSE)
drop <- vapply(old_search, function(x) sub("#.*$", "", x$href) == "notebooks/sensitivity_battery.html", logical(1))
new_search <- fromJSON(file.path(site, "search.json"), simplifyVector = FALSE)
stopifnot(sum(drop) == 4L, length(new_search) == 938L, identical(old_search[!drop], new_search))
old_map <- read_xml(file.path(base, "preimages/_build/nathealth/sitemap.xml"))
new_map <- read_xml(file.path(site, "sitemap.xml"))
old_urls <- xml_find_all(old_map, "//*[local-name()='url']")
stopifnot(length(old_urls) == 39L)
drop_url <- xml_find_all(old_map, "//*[local-name()='url'][*[local-name()='loc' and contains(text(),'/notebooks/sensitivity_battery.html')]]")
stopifnot(length(drop_url) == 1L)
xml_remove(drop_url)
stopifnot(length(xml_find_all(new_map, "//*[local-name()='url']")) == 38L,
  identical(norm(old_map), norm(new_map)))
before_corpus <- read.csv(file.path(base, "preimages/audit/report_harmonization/phase4_corpus_manifest.csv"), check.names = FALSE)
expect_corpus <- before_corpus[before_corpus$source != "notebooks/sensitivity_battery.qmd", ]
expect_corpus$render_position[expect_corpus$source == "index.qmd"] <- 35L
expect_corpus$render_position[expect_corpus$source == "supplementary_information.qmd"] <- 36L
for (i in seq_len(nrow(expect_corpus))) {
  rel <- sub("^_build/nathealth/", "", expect_corpus$expected_html[[i]])
  expect_corpus$html_sha256[[i]] <- sha(file.path(site, rel))
}
new_corpus <- read.csv(corpus_path, check.names = FALSE)
rownames(expect_corpus) <- NULL
stopifnot(nrow(new_corpus) == 36L, identical(expect_corpus, new_corpus))
pre_profile <- read_raw_text(file.path(base, "preimages/_quarto-nathealth.yml"))
post_profile <- read_raw_text(profile)
spans <- c("    - notebooks/sensitivity_battery.qmd\n",
  "          - text: \"Sensitivity checks\"\n            href: notebooks/sensitivity_battery.qmd\n",
  paste0("    - id: robustness\n      title: \"Robustness\"\n      style: \"floating\"\n      search: false\n",
    "      collapse-level: 1\n      contents:\n        - section: \"Sensitivity analyses\"\n          contents:\n",
    "            - href: notebooks/sensitivity_battery.qmd\n              text: \"Sensitivity checks\"\n"))
for (span in spans) {
  stopifnot(lengths(regmatches(pre_profile, gregexpr(span, pre_profile, fixed = TRUE))) == 1L)
  pre_profile <- sub(span, "", pre_profile, fixed = TRUE)
}
stopifnot(identical(pre_profile, post_profile))
dir.create(out, recursive = TRUE)
write.csv(do.call(rbind, dom_checks), file.path(out, "independent43_exact_dom_delta.csv"), row.names = FALSE)
write.csv(data.frame(path = new_paths, bytes = file.info(all)$size, sha256 = vapply(all, sha, character(1))),
  file.path(out, "independent899_inventory.csv"), row.names = FALSE)
write_json(list(status = "PASS", files = 899L, exact_unchanged = 854L, only_authorized_dom = 43L,
  retirements = 15L, profile_exact_three_removals = TRUE, corpus = 36L,
  retained_search = 938L, sitemap = 38L, R = as.character(getRversion())),
  file.path(out, "independent_summary.json"), pretty = TRUE, auto_unbox = TRUE)
capture.output(sessionInfo(), file = file.path(out, "R_sessionInfo.txt"))
cat("ORDER017_INDEPENDENT_DELIVERY=PASS public899 unchanged854 DOM43 retired15 corpus36 search938 sitemap38\n")
