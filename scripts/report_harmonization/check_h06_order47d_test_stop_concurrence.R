#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(openssl)
  library(xml2)
})

args <- commandArgs(trailingOnly = TRUE)
project_root <- if (length(args) >= 1L) args[[1L]] else getwd()
project_root <- normalizePath(project_root, mustWork = TRUE)
setwd(project_root)

fail <- function(message) {
  stop(message, call. = FALSE)
}

expect_true <- function(value, message) {
  if (!isTRUE(value)) {
    fail(message)
  }
}

sha256_file <- function(path) {
  connection <- file(path, "rb")
  on.exit(close(connection), add = TRUE)
  unclass(as.character(openssl::sha256(connection)))
}

fixed_count <- function(text, pattern) {
  matches <- gregexpr(pattern, text, fixed = TRUE)[[1L]]
  if (identical(matches[[1L]], -1L)) 0L else length(matches)
}

normalize_visible <- function(text) {
  trimws(gsub("[[:space:]]+", " ", text))
}

expected_sha <- c(
  "audit/hypotheses/H06/H06_analysis_preparation.qmd" = "f952d5ec72066ee86fded4888aaa815bdf763c11f466806ebc7391c79e22918b",
  "_build/nathealth/audit/hypotheses/H06/H06_analysis_preparation.qmd" = "f952d5ec72066ee86fded4888aaa815bdf763c11f466806ebc7391c79e22918b",
  "_build/nathealth/audit/hypotheses/H06/H06_analysis_preparation.html" = "f9a4f51db555454a2e7cd0ea70895978b71016e6bd2c7310ae5033ad3c7ed378",
  "artifacts/12_manifests/H06/H06_preparation_report_manifest.csv" = "a3bd413daf9e154d78f32e49caea0697303c8d86ce387892ab081b06ae8b6bbc",
  "tests/hypotheses/H06/test_h06_preparation_report.R" = "2b9f02f7caa448a3c7fdb88b0febc5ce306239002ebe220b6f5f7a7c4285a4fc",
  "scripts/hypotheses/H06/build_h06_preparation_report_manifest.R" = "bc53e754478a3fa17de0aaf498aea8720d58b958949050f7447d25c5ec23e2fb",
  "notebooks/hypotheses/H06.qmd" = "d65c197cb37db32101d8a43fcdc80198ab599a95cb73259abd187c9b2b58d350",
  "_build/nathealth/notebooks/hypotheses/H06.html" = "8b5f1b0ada997290ec5324de35e0c874fd25e2e9ef052281acaab07d0a3dccaa",
  "scripts/hypotheses/H06/h06_contract.R" = "b11447a49a52a6a1a66618f9f471c0cda5284cbb8a251f7dffb2512d9ede231f",
  "_quarto-nathealth.yml" = "80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3",
  "/private/tmp/h06_order47d_semantic.7o8aQn/gt_html_semantic_post_render_summary.csv" = "d520b2660419f896eb3733846e9347e0d254849bc31c2b9bdc5d9bd4032d8ecd",
  "/private/tmp/h06_order47d_semantic.7o8aQn/001__build__nathealth__audit__hypotheses__H06__H06_analysis_preparation.html_gt_semantic_ledger.csv" = "c2bc57a6606c0dfb118b8405cb153e044a8c96e4008609e0c8b40b12892b6100"
)

for (path in names(expected_sha)) {
  expect_true(file.exists(path), paste("Missing protected path:", path))
  expect_true(
    identical(sha256_file(path), unname(expected_sha[[path]])),
    paste("Protected identity drift:", path)
  )
}

source_path <- "audit/hypotheses/H06/H06_analysis_preparation.qmd"
html_path <- "_build/nathealth/audit/hypotheses/H06/H06_analysis_preparation.html"
test_path <- "tests/hypotheses/H06/test_h06_preparation_report.R"
manifest_path <- "artifacts/12_manifests/H06/H06_preparation_report_manifest.csv"

source_text <- paste(readLines(source_path, warn = FALSE), collapse = "\n")
test_text <- paste(readLines(test_path, warn = FALSE), collapse = "\n")
result_qmd_target <- "../../../notebooks/hypotheses/H06.qmd"
result_html_target <- "../../../notebooks/hypotheses/H06.html"

expect_true(
  identical(fixed_count(source_text, result_qmd_target), 3L),
  "The companion source does not contain exactly three dynamic result-QMD links."
)
expect_true(
  identical(fixed_count(source_text, result_html_target), 0L),
  "The companion source contains a hard-coded result-HTML link."
)
expect_true(
  identical(fixed_count(test_text, result_html_target), 1L),
  "The unchanged test does not contain exactly one stale result-HTML literal."
)
expect_true(
  identical(
    fixed_count(
      source_text,
      paste0(result_qmd_target, "#h06-preregistration-deviations")
    ),
    1L
  ),
  "The dynamic result anchor link is not present exactly once."
)

manifest <- read.csv(
  manifest_path,
  stringsAsFactors = FALSE,
  check.names = FALSE
)
expect_true(
  nrow(manifest) == 411L,
  "The preparation manifest does not have 411 rows."
)
expect_true(
  !anyDuplicated(manifest$path),
  "The preparation manifest has duplicate paths."
)
expect_true(
  !manifest_path %in% manifest$path,
  "The preparation manifest is circular."
)
expect_true(
  all(file.exists(manifest$path)),
  "The preparation manifest contains a missing path."
)
manifest_sha <- unname(vapply(manifest$path, sha256_file, character(1)))
manifest_bytes <- unname(as.numeric(file.info(manifest$path)$size))
expect_true(
  identical(manifest_sha, unname(manifest$sha256)),
  "At least one preparation-manifest SHA-256 identity is not live-exact."
)
expect_true(
  identical(manifest_bytes, unname(as.numeric(manifest$bytes))),
  "At least one preparation-manifest byte count is not live-exact."
)

document <- read_html(html_path)
all_ids <- xml_attr(xml_find_all(document, "//*[@id]"), "id")
expect_true(
  !anyDuplicated(all_ids),
  "The companion HTML has duplicate document IDs."
)

tables <- xml_find_all(
  document,
  "//table[contains(concat(' ', normalize-space(@class), ' '), ' gt_table ')]"
)
expect_true(
  length(tables) == 30L,
  "The companion HTML does not contain 30 native gt tables."
)

header_attribute_count <- 0L
header_token_count <- 0L
for (table in tables) {
  table_ids <- xml_attr(xml_find_all(table, ".//*[@id]"), "id")
  table_th_ids <- xml_attr(xml_find_all(table, ".//th[@id]"), "id")
  header_values <- xml_attr(xml_find_all(table, ".//*[@headers]"), "headers")
  header_attribute_count <- header_attribute_count + length(header_values)
  tokens <- unlist(strsplit(header_values, "[[:space:]]+"), use.names = FALSE)
  tokens <- tokens[nzchar(tokens)]
  header_token_count <- header_token_count + length(tokens)
  if (length(tokens)) {
    expect_true(
      all(vapply(
        tokens,
        function(token) sum(table_ids == token) == 1L,
        logical(1)
      )),
      "A headers token does not resolve exactly once inside its own table."
    )
    expect_true(
      all(tokens %in% table_th_ids),
      "A headers token does not resolve to a th element inside its own table."
    )
  }
}
expect_true(
  header_attribute_count == 816L,
  "The HTML does not contain 816 table headers attributes."
)

figure_ids <- unique(all_ids[grepl("^fig-h06-prep-", all_ids)])
figure_ids <- figure_ids[!grepl("-caption-", figure_ids, fixed = TRUE)]
expected_figure_ids <- c(
  "fig-h06-prep-response-distribution",
  "fig-h06-prep-site-day-activity-support",
  "fig-h06-prep-clock-support"
)
expect_true(
  setequal(figure_ids, expected_figure_ids) && length(figure_ids) == 3L,
  "The HTML figure endpoint set is not the accepted three-endpoint set."
)
for (figure_id in expected_figure_ids) {
  nodes <- xml_find_all(document, sprintf("//*[@id='%s']", figure_id))
  expect_true(length(nodes) == 1L, paste("Missing figure endpoint:", figure_id))
  images <- xml_find_all(nodes, ".//img")
  expect_true(
    length(images) == 1L,
    paste("Figure does not contain one image:", figure_id)
  )
  alt <- xml_attr(images, "alt")
  expect_true(
    !is.na(alt) && nzchar(normalize_visible(alt)),
    paste("Figure alt text is empty:", figure_id)
  )
}

mermaids <- xml_find_all(
  document,
  "//pre[contains(concat(' ', normalize-space(@class), ' '), ' mermaid ')]"
)
expect_true(
  length(mermaids) == 1L,
  "The HTML does not contain exactly one Mermaid."
)
expect_true(
  grepl("flowchart TD", xml_text(mermaids), fixed = TRUE),
  "The Mermaid is not top-down."
)

summary_path <- "/private/tmp/h06_order47d_semantic.7o8aQn/gt_html_semantic_post_render_summary.csv"
ledger_path <- "/private/tmp/h06_order47d_semantic.7o8aQn/001__build__nathealth__audit__hypotheses__H06__H06_analysis_preparation.html_gt_semantic_ledger.csv"
semantic_summary <- read.csv(
  summary_path,
  stringsAsFactors = FALSE,
  check.names = FALSE
)
semantic_ledger <- read.csv(
  ledger_path,
  stringsAsFactors = FALSE,
  check.names = FALSE
)
expect_true(
  nrow(semantic_summary) == 1L,
  "The semantic summary does not contain one target row."
)
expect_true(
  semantic_summary$disposition[[1L]] == "REPAIRED",
  "The semantic disposition is not REPAIRED."
)
expect_true(
  semantic_summary$table_count[[1L]] == 30L,
  "The semantic table count is not 30."
)
expect_true(
  semantic_summary$id_count[[1L]] == 169L,
  "The semantic ID count is not 169."
)
expect_true(
  semantic_summary$headers_count[[1L]] == 816L,
  "The semantic headers count is not 816."
)
expect_true(
  semantic_summary$total_substitutions[[1L]] == 985L,
  "The semantic substitution count is not 985."
)
expect_true(
  semantic_summary$post_sha256[[1L]] == expected_sha[[html_path]],
  "The semantic summary post-hash does not match the fresh companion HTML."
)
expect_true(
  nrow(semantic_ledger) == 985L,
  "The semantic ledger does not have 985 rows."
)
expect_true(
  sum(semantic_ledger$attribute == "id") == 169L,
  "The semantic ledger ID count is not 169."
)
expect_true(
  sum(semantic_ledger$attribute == "headers") == 816L,
  "The semantic ledger headers count is not 816."
)

hrefs <- unique(xml_attr(xml_find_all(document, "//a[@href]"), "href"))
hrefs <- hrefs[!is.na(hrefs) & nzchar(hrefs)]
result_hrefs <- hrefs[
  hrefs == result_html_target |
    startsWith(hrefs, paste0(result_html_target, "#"))
]
expect_true(
  length(result_hrefs) >= 2L,
  "The rendered page lacks reciprocal result links."
)
expect_true(
  paste0(result_html_target, "#h06-preregistration-deviations") %in%
    result_hrefs,
  "The rendered result-anchor link is absent."
)

internal_hrefs <- hrefs[!grepl("^(https?:|mailto:|javascript:|data:)", hrefs)]
broken_links <- character()
for (href in internal_hrefs) {
  if (startsWith(href, "#")) {
    fragment <- substring(href, 2L)
    if (nzchar(fragment) && !fragment %in% all_ids) {
      broken_links <- c(broken_links, href)
    }
    next
  }
  target_part <- sub("[?#].*$", "", href)
  fragment <- if (grepl("#", href, fixed = TRUE)) sub("^[^#]*#", "", href) else
    ""
  target_path <- normalizePath(
    file.path(dirname(html_path), target_part),
    mustWork = FALSE
  )
  if (!file.exists(target_path)) {
    broken_links <- c(broken_links, href)
    next
  }
  if (nzchar(fragment) && endsWith(tolower(target_part), ".html")) {
    target_document <- read_html(target_path)
    target_ids <- xml_attr(xml_find_all(target_document, "//*[@id]"), "id")
    if (!fragment %in% target_ids) {
      broken_links <- c(broken_links, href)
    }
  }
}
expect_true(
  !length(unique(broken_links)),
  paste("Broken internal links:", paste(unique(broken_links), collapse = "; "))
)
expect_true(
  !any(grepl("(^file:|/Users/|_build/)", hrefs)),
  "The rendered page contains a forbidden local or build-path link."
)

active_links <- xml_find_all(
  document,
  "//a[contains(concat(' ', normalize-space(@class), ' '), ' active ')]"
)
active_hrefs <- xml_attr(active_links, "href")
expect_true(
  any(grepl("H06_analysis_preparation.html", active_hrefs, fixed = TRUE)),
  "The H06 preparation navigation entry is not active."
)

visible_text <- normalize_visible(xml_text(document))
country_sites <- c(
  "Borås (SE)",
  "Delft (NL)",
  "Dortmund (DE)",
  "Tübingen (DE)",
  "Madrid (ES)",
  "Munich (DE)",
  "Izmir (TR)",
  "San José (CR)",
  "Kumasi (GH)"
)
expect_true(
  all(vapply(country_sites, grepl, logical(1), x = visible_text, fixed = TRUE)),
  "At least one country-coded study site is absent from the rendered page."
)

problem_nodes <- xml_find_all(
  document,
  "//*[contains(concat(' ', normalize-space(@class), ' '), ' cell-output-error ') or contains(concat(' ', normalize-space(@class), ' '), ' cell-output-warning ') or contains(concat(' ', normalize-space(@class), ' '), ' cell-output-stderr ') or contains(concat(' ', normalize-space(@class), ' '), ' quarto-error ')]"
)
expect_true(
  length(problem_nodes) == 0L,
  "The rendered page contains an embedded problem node."
)
expect_true(
  !grepl(
    "quarto-unresolved-ref|\\?@(?:fig|tbl|sec)-",
    paste(readLines(html_path, warn = FALSE), collapse = "\n")
  ),
  "The rendered page contains an unresolved cross-reference."
)

build_entries <- list.files(
  "_build/nathealth",
  recursive = TRUE,
  all.files = TRUE,
  full.names = TRUE
)
build_entries <- build_entries[!basename(build_entries) %in% c(".", "..")]
symlink_targets <- Sys.readlink(build_entries)
expect_true(
  !any(nzchar(symlink_targets)),
  "The build tree contains a symbolic link."
)

cat("H06 order 47d test-stop central concurrence PASS\n")
cat("R version:", R.version.string, "\n")
cat("Protected post-render pins: 12/12 exact\n")
cat("Dynamic source links: 3 QMD links; stale test literal isolated\n")
cat("Preparation manifest: 411/411 live-exact, unique, non-circular\n")
cat("HTML: 30 tables, 3 figures, 1 TD Mermaid\n")
cat("Semantic repair: 169 IDs, 816 headers attributes, 985 substitutions\n")
cat("Table header tokens resolving within table:", header_token_count, "\n")
cat(
  "Internal links, active navigation, country labels, problem nodes, and symlinks PASS\n"
)
cat(
  "Disposition: concur with no-rerender continuation after durable owner stop seal\n"
)
