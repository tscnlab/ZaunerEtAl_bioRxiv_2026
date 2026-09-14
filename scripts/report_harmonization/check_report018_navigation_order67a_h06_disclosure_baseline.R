#!/usr/bin/env Rscript

# Independent structural audit for the inherited H06 disclosure marker found
# during the final Order 67a production QA. This script does not execute a QMD,
# alter the build, or calculate a scientific result.

options(stringsAsFactors = FALSE, warn = 2)
suppressPackageStartupMessages({
  library(digest)
  library(readr)
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

read_raw_text <- function(path) {
  size <- file_bytes(path)
  connection <- file(path, open = "rb")
  on.exit(close(connection), add = TRUE)
  rawToChar(readBin(connection, what = "raw", n = size))
}

count_fixed <- function(pattern, text) {
  matches <- gregexpr(pattern, text, fixed = TRUE)[[1L]]
  if (identical(matches[[1L]], -1L)) return(0L)
  length(matches)
}

replace_one_fixed <- function(text, old, new) {
  stopifnot(count_fixed(old, text) == 1L)
  match <- regexpr(old, text, fixed = TRUE)
  start <- as.integer(match[[1L]])
  width <- as.integer(attr(match, "match.length")[[1L]])
  before <- if (start > 1L) substr(text, 1L, start - 1L) else ""
  after_start <- start + width
  after <- if (after_start <= nchar(text)) {
    substr(text, after_start, nchar(text))
  } else {
    ""
  }
  paste0(before, new, after)
}

normalize_text <- function(x) {
  gsub("[[:space:]]+", " ", trimws(x))
}

audit_details <- function(path) {
  document <- xml2::read_html(path)
  main <- xml2::xml_find_all(
    document,
    "//main[@id='quarto-document-content']"
  )
  stopifnot(length(main) == 1L)

  nodes <- xml2::xml_find_all(
    main,
    paste0(
      ".//details[not(ancestor::*[contains(",
      "concat(' ', normalize-space(@class), ' '), ",
      "' nathealth-mobile-toc ')])]"
    )
  )

  data.frame(
    summary = vapply(nodes, function(node) {
      summary <- xml2::xml_find_all(node, "./summary")
      stopifnot(length(summary) == 1L)
      normalize_text(xml2::xml_text(summary))
    }, character(1)),
    direct_after = vapply(nodes, function(node) {
      sum(xml2::xml_name(xml2::xml_children(node)) != "summary")
    }, integer(1)),
    descendants_after = vapply(nodes, function(node) {
      length(xml2::xml_find_all(
        node,
        ".//*[not(self::summary) and not(ancestor::summary)]"
      ))
    }, integer(1)),
    containing_section = vapply(nodes, function(node) {
      section <- xml2::xml_find_all(node, "ancestor::section[1]")
      stopifnot(length(section) == 1L)
      xml2::xml_attr(section, "id")
    }, character(1)),
    stringsAsFactors = FALSE
  )
}

include_path <- file.path(project_root, "_includes/nathealth-mobile-toc.html")
corpus_path <- file.path(
  project_root,
  "audit/report_harmonization/phase4_corpus_manifest.csv"
)
h06_path <- file.path(
  project_root,
  "_build/nathealth/notebooks/hypotheses/H06.html"
)
backup_root_path <- file.path(evidence_dir, "backup_root.txt")

require_file(
  include_path,
  "153967734707cccf0fb2e910327cebfadb552f3c752b70e67b5346fb9acd8980",
  1542
)
require_file(
  corpus_path,
  "5d66d43ddfa2858193603db656c0cd25c0c2229ea9bee3678dc4c56a9705855b",
  11479
)
require_file(
  h06_path,
  "4883b77a2e225c8bad8628f1a04274f5d19d81aeb7cc493949707cdc6cd98e2f",
  4898816
)
stopifnot(file.exists(backup_root_path), !dir.exists(backup_root_path))
backup_root <- trimws(readLines(backup_root_path, warn = FALSE)[[1L]])
stopifnot(startsWith(backup_root, "/private/tmp/"))
backup_h06_path <- file.path(
  backup_root,
  "preimages/_build/nathealth/notebooks/hypotheses/H06.html"
)
backup_include_path <- file.path(
  backup_root,
  "preimages/_includes/nathealth-mobile-toc.html"
)
require_file(
  backup_h06_path,
  "b701a6d6e10e37fbe143117b70c0ba78e2d65ade0b973f3e1cd3e43a6f658dc9",
  4898662
)
require_file(
  backup_include_path,
  "926a5fc051f032100714ae01b53c5ba2937c91ff2406ab5354484bf8fd7f553d",
  1388
)

corpus <- readr::read_csv(corpus_path, show_col_types = FALSE)
h06_row <- corpus[
  corpus$expected_html == "_build/nathealth/notebooks/hypotheses/H06.html",
  ,
  drop = FALSE
]
stopifnot(
  nrow(corpus) == 37L,
  nrow(h06_row) == 1L,
  identical(
    h06_row$html_sha256[[1L]],
    "4883b77a2e225c8bad8628f1a04274f5d19d81aeb7cc493949707cdc6cd98e2f"
  )
)

script_pattern <- "<script>([\\s\\S]*?)</script>"
include_pre <- read_raw_text(backup_include_path)
include_post <- read_raw_text(include_path)
script_pre_match <- regmatches(
  include_pre,
  regexpr(script_pattern, include_pre, perl = TRUE)
)
script_post_match <- regmatches(
  include_post,
  regexpr(script_pattern, include_post, perl = TRUE)
)
script_pre <- sub(script_pattern, "\\1", script_pre_match, perl = TRUE)
script_post <- sub(script_pattern, "\\1", script_post_match, perl = TRUE)

h06_pre <- read_raw_text(backup_h06_path)
h06_post <- read_raw_text(h06_path)
stopifnot(
  count_fixed(script_pre, h06_pre) == 1L,
  count_fixed(script_post, h06_post) == 1L,
  identical(replace_one_fixed(h06_post, script_post, script_pre), h06_pre)
)

pre_audit <- audit_details(backup_h06_path)
post_audit <- audit_details(h06_path)
rownames(pre_audit) <- NULL
rownames(post_audit) <- NULL
stopifnot(identical(pre_audit, post_audit), nrow(post_audit) == 5L)

expected_summary <- c(
  "Show site-specific estimates and interaction details",
  "Show complementary placement and sensitivity results",
  "Show detailed model checks and influence analyses",
  "Show exploratory clock-time and diary analyses",
  "Show technical source and figure checks"
)
stopifnot(identical(post_audit$summary, expected_summary))

content_bearing <- post_audit$direct_after > 0L &
  post_audit$descendants_after > 0L
empty_marker <- !content_bearing
stopifnot(
  sum(content_bearing) == 4L,
  sum(empty_marker) == 1L,
  identical(
    post_audit$summary[empty_marker],
    "Show technical source and figure checks"
  ),
  identical(
    post_audit$containing_section[empty_marker],
    "models-and-inference"
  )
)

post_document <- xml2::read_html(h06_path)
marker <- xml2::xml_find_all(
  post_document,
  paste0(
    "//main[@id='quarto-document-content']//details[",
    "normalize-space(summary)='Show technical source and figure checks']"
  )
)
stopifnot(length(marker) == 1L)
marker_section <- xml2::xml_find_all(marker, "ancestor::section[1]")
next_sections <- xml2::xml_find_all(
  marker_section,
  "following-sibling::section[position() <= 2]"
)
stopifnot(
  length(next_sections) == 2L,
  identical(
    xml2::xml_attr(next_sections, "id"),
    c("technical-source-and-figure-checks", "figure-reproducibility")
  ),
  normalize_text(xml2::xml_text(next_sections[[1L]])) ==
    "Technical source and figure checks",
  grepl(
    "All six reader-facing figures were assessed at 170 mm",
    normalize_text(xml2::xml_text(next_sections[[2L]])),
    fixed = TRUE
  )
)

cat(
  paste0(
    "H06_DISCLOSURE_BASELINE=PASS details=5 content_bearing=4 ",
    "empty_markers=1 exact_pre_post=TRUE next_sections=2 ",
    "shell_reverse=TRUE R=4.6.1\n"
  )
)
