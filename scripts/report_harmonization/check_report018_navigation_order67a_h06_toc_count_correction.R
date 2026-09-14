#!/usr/bin/env Rscript

# Exact correction audit for the H06 mobile-TOC link count in the Order 67a
# disclosure disposition. This script is structural only and performs no QMD
# execution or scientific calculation.

options(stringsAsFactors = FALSE, warn = 2)
suppressPackageStartupMessages({
  library(digest)
  library(jsonlite)
  library(xml2)
})

stopifnot(identical(as.character(getRversion()), "4.6.1"))

project_root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
evidence_rel <- paste0(
  "audit/report_harmonization/",
  "navigation_mobile_toc_collapse_repair_2026_09_02/",
  "order67a_clone_state_repair"
)
evidence_dir <- file.path(project_root, evidence_rel)

sha256_file <- function(path) {
  digest::digest(path, file = TRUE, algo = "sha256", serialize = FALSE)
}

file_bytes <- function(path) {
  unname(as.numeric(file.info(path)$size))
}

require_file <- function(path, sha256, bytes) {
  stopifnot(
    file.exists(path),
    !dir.exists(path),
    !nzchar(Sys.readlink(path)),
    identical(sha256_file(path), sha256),
    file_bytes(path) == bytes
  )
  invisible(TRUE)
}

require_file(
  file.path(
    project_root,
    "audit/report_harmonization/report018_navigation_order67a_h06_disclosure_disposition.md"
  ),
  "4d625dceab42b6c4a92c1862a169cf35451e0c963bc66da43e135f2e78d97873",
  4032
)
require_file(
  file.path(
    project_root,
    "scripts/report_harmonization/check_report018_navigation_order67a_h06_disclosure_baseline.R"
  ),
  "c6a6a550452594f93d863e04366bb42aaf983d69ead1b05a8dac49659e92fbd2",
  7621
)
require_file(
  file.path(
    project_root,
    "audit/report_harmonization/report018_navigation_order67a_h06_disclosure_disposition_manifest.csv"
  ),
  "5163733aacb6de9edb0177974e666256d9f6ae34eb97afbf8e5fd12d9bc87ba7",
  3585
)

production_qa_path <- file.path(evidence_dir, "production_browser_route_qa.json")
candidate_qa_path <- file.path(evidence_dir, "candidate_browser_route_qa.json")
require_file(
  production_qa_path,
  "9571ee93bebb87baa1f6a9ed73ea2041c170f5aced434bb64ff601a3c0fe3720",
  75495
)
require_file(
  candidate_qa_path,
  "862ed0190f295a9cc415566d7c05d2c21f25ff267c35264deadcc45758c0fa95",
  75526
)

backup_root <- trimws(readLines(
  file.path(evidence_dir, "backup_root.txt"),
  warn = FALSE
)[[1L]])
stopifnot(startsWith(backup_root, "/private/tmp/"))
html_paths <- c(
  preimage = file.path(
    backup_root,
    "preimages/_build/nathealth/notebooks/hypotheses/H06.html"
  ),
  production = file.path(
    project_root,
    "_build/nathealth/notebooks/hypotheses/H06.html"
  )
)
require_file(
  html_paths[["preimage"]],
  "b701a6d6e10e37fbe143117b70c0ba78e2d65ade0b973f3e1cd3e43a6f658dc9",
  4898662
)
require_file(
  html_paths[["production"]],
  "4883b77a2e225c8bad8628f1a04274f5d19d81aeb7cc493949707cdc6cd98e2f",
  4898816
)

toc_inventory <- lapply(html_paths, function(path) {
  document <- xml2::read_html(path)
  direct_links <- xml2::xml_find_all(
    document,
    "//*[@id='quarto-margin-sidebar']/nav[@id='TOC']/ul//a[@href]"
  )
  all_links <- xml2::xml_find_all(
    document,
    "//nav[@id='TOC']//a[@href]"
  )
  list(
    direct = xml2::xml_attr(direct_links, "href"),
    all = xml2::xml_attr(all_links, "href")
  )
})

expected_direct <- c(
  "#scientific-question",
  "#reader-orientation",
  "#principal-hourly-result",
  "#site-dependence",
  "#sensitivity-and-complementary-sensor-evidence",
  "#model-check-qualification",
  "#exploratory-diary-and-clock-time-analyses",
  "#interpretation-and-limitations",
  "#h06-preregistration-deviations",
  "#detailed-analysis-record"
)
expected_repository_actions <- c(
  paste0(
    "https://github.com/tscnlab/ZaunerEtAl_bioRxiv_2026/",
    "edit/main/notebooks/hypotheses/H06.qmd"
  ),
  "https://github.com/tscnlab/ZaunerEtAl_bioRxiv_2026/issues"
)

for (inventory in toc_inventory) {
  stopifnot(
    identical(inventory$direct, expected_direct),
    length(inventory$all) == 12L,
    identical(setdiff(inventory$all, inventory$direct), expected_repository_actions)
  )
}
stopifnot(identical(toc_inventory$preimage, toc_inventory$production))

check_browser_qa <- function(path) {
  qa <- jsonlite::fromJSON(path, simplifyDataFrame = TRUE)
  h06 <- qa[qa$route == "notebooks/hypotheses/H06.html", , drop = FALSE]
  h06 <- h06[order(h06$viewport_width, decreasing = TRUE), , drop = FALSE]
  stopifnot(
    nrow(qa) == 74L,
    nrow(h06) == 2L,
    identical(as.integer(h06$viewport_width), c(708L, 390L)),
    identical(as.integer(h06$mobile_link_count), c(10L, 10L)),
    identical(as.integer(h06$visible_link_count), c(10L, 10L)),
    identical(as.integer(h06$focusable_link_count), c(10L, 10L)),
    all(h06$link_order_matches_desktop),
    all(h06$mobile_initially_closed),
    all(h06$disclosure_closed_after_follow),
    all(h06$toc_open_added_width == 0),
    all(h06$pass)
  )
  invisible(TRUE)
}

check_browser_qa(candidate_qa_path)
check_browser_qa(production_qa_path)

cat(
  paste0(
    "H06_TOC_COUNT_CORRECTION=PASS direct_links=10 nav_links=12 ",
    "repository_actions=2 candidate_rows=2 production_rows=2 ",
    "viewports=708,390 visible=10/10 focusable=10/10 order=TRUE R=4.6.1\n"
  )
)
