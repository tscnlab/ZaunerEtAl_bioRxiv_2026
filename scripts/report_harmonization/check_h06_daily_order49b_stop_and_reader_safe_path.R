#!/usr/bin/env Rscript

stopf <- function(...) {
  stop(sprintf(...), call. = FALSE)
}

if (!identical(as.character(getRversion()), "4.6.1")) {
  stopf("This check requires R 4.6.1")
}

suppressPackageStartupMessages({
  library(digest)
  library(knitr)
  library(readr)
  library(xfun)
  library(xml2)
})

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
setwd(root)

sha256 <- function(path) {
  digest::digest(
    file = path,
    algo = "sha256",
    serialize = FALSE
  )
}

assert_file <- function(path, expected_sha, expected_bytes) {
  if (!file.exists(path)) {
    stopf("Required file is absent: %s", path)
  }
  observed_sha <- sha256(path)
  observed_bytes <- as.numeric(file.info(path)$size)
  if (!identical(observed_sha, expected_sha)) {
    stopf("SHA-256 mismatch for %s", path)
  }
  if (!identical(observed_bytes, as.numeric(expected_bytes))) {
    stopf("Byte-count mismatch for %s", path)
  }
  invisible(TRUE)
}

owner_dir <- file.path(
  "audit",
  "hypotheses",
  "H06_daily",
  "report018_order49b_companion_render"
)
owner_record <- file.path(owner_dir, "order49b_fail_closed.md")
owner_manifest <- file.path(
  owner_dir,
  "order49b_fail_closed_manifest.csv"
)
companion_qmd <- file.path(
  "audit",
  "hypotheses",
  "H06_daily",
  "H06_daily_analysis_preparation.qmd"
)
companion_html <- file.path(
  "_build",
  "nathealth",
  "audit",
  "hypotheses",
  "H06_daily",
  "H06_daily_analysis_preparation.html"
)
historical_source_html <- file.path(
  "audit",
  "hypotheses",
  "H06_daily",
  "H06_daily_analysis_preparation.html"
)
result_qmd <- file.path("notebooks", "hypotheses", "H06_daily.qmd")
result_html <- file.path(
  "_build",
  "nathealth",
  "notebooks",
  "hypotheses",
  "H06_daily.html"
)
figure_png <- file.path(
  "artifacts",
  "10_figures",
  "H06_daily",
  "H06_daily_preparation_primary_sample_support.png"
)
build_figure_png <- file.path("_build", "nathealth", figure_png)

assert_file(
  owner_record,
  "a7d66b5f3c8ba2a9316b46a134db75e265062dbf7b4773087c6c99aa56407cb7",
  4320
)
assert_file(
  owner_manifest,
  "b19a5d64967665ee9e0e2e8c128ce224c35478f81fb95590f2049d3046b909ed",
  12641
)
assert_file(
  companion_qmd,
  "cc0647d1519cd9b76313dafb3dcb3b77af38169f8c71ec278e210e6044854dc2",
  35450
)
assert_file(
  companion_html,
  "896cc3797ab570eeb3b36dc9811ce9cc5ed378dc0e0bb7d15b75d7f77ac35584",
  5349983
)
assert_file(
  result_qmd,
  "8f696f3f89fe9ea18c8066b756a01fc5da6b41e86f8ac7d37d1e16f9c10ba639",
  65349
)
assert_file(
  result_html,
  "74a63bd09b266709630e92241a17735298dffd5fc6d1746887621eb6288f2e6c",
  11946551
)
assert_file(
  figure_png,
  "f9be57236f5fa9b658c7adac0940ba7befa856cbc19df770602e32270dccf8ff",
  165458
)
assert_file(
  build_figure_png,
  "f9be57236f5fa9b658c7adac0940ba7befa856cbc19df770602e32270dccf8ff",
  165458
)

manifest <- readr::read_csv(owner_manifest, show_col_types = FALSE)
if (nrow(manifest) != 65L) {
  stopf("Owner manifest must contain exactly 65 rows")
}
if (anyDuplicated(manifest$path)) {
  stopf("Owner manifest contains duplicate paths")
}
if (any(grepl("order49b_fail_closed_manifest[.]csv$", manifest$path))) {
  stopf("Owner manifest is circular")
}
manifest_paths <- file.path(root, manifest$path)
if (!all(file.exists(manifest_paths))) {
  stopf("An owner-manifest member is absent")
}
manifest_sha <- unname(vapply(
  manifest_paths,
  sha256,
  character(1)
))
manifest_bytes <- as.numeric(file.info(manifest_paths)$size)
if (!all(manifest_sha == manifest$sha256)) {
  stopf("An owner-manifest SHA-256 identity differs")
}
if (!all(manifest_bytes == manifest$bytes)) {
  stopf("An owner-manifest byte count differs")
}

if (file.exists(historical_source_html)) {
  stopf("The obsolete source-side companion HTML unexpectedly exists")
}

semantic_summary <- readr::read_csv(
  file.path(owner_dir, "gt_html_semantic_post_render_summary.csv"),
  show_col_types = FALSE
)
if (
  nrow(semantic_summary) != 1L ||
    semantic_summary$disposition[[1L]] != "REPAIRED" ||
    semantic_summary$table_count[[1L]] != 17L ||
    semantic_summary$id_count[[1L]] != 98L ||
    semantic_summary$headers_count[[1L]] != 905L ||
    semantic_summary$total_substitutions[[1L]] != 1003L
) {
  stopf("The order-49b semantic summary differs")
}

semantic_reverse <- readr::read_csv(
  file.path(owner_dir, "semantic_reverse_audit.csv"),
  show_col_types = FALSE
)
if (
  nrow(semantic_reverse) != 1L ||
    semantic_reverse$status[[1L]] != "PASS" ||
    semantic_reverse$ledger_rows[[1L]] != 1003L
) {
  stopf("The order-49b semantic reversal differs")
}

document <- xml2::read_html(companion_html)
figure_node <- xml2::xml_find_first(
  document,
  "//*[@id='fig-h06d-prep-primary-sample-support']//img"
)
if (inherits(figure_node, "xml_missing")) {
  stopf("The stopped HTML has no primary-sample figure node")
}
broken_src <- xml2::xml_attr(figure_node, "src")
expected_broken_src <- paste0(
  "../../../Users/zauner/Documents/Arbeit/12-TUM/",
  "MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026/",
  "artifacts/10_figures/H06_daily/",
  "H06_daily_preparation_primary_sample_support.png"
)
if (!identical(broken_src, expected_broken_src)) {
  stopf("The stopped HTML figure source differs")
}
resolved_broken_src <- file.path(
  dirname(companion_html),
  broken_src
)
if (file.exists(resolved_broken_src)) {
  stopf("The stopped HTML figure unexpectedly resolves")
}

source_text <- readChar(
  companion_qmd,
  file.info(companion_qmd)$size,
  useBytes = TRUE
)
old_block <- paste0(
  "knitr::include_graphics(file.path(\n",
  "  project_root,\n",
  "  \"artifacts/10_figures/H06_daily\",\n",
  "  \"H06_daily_preparation_primary_sample_support.png\"\n",
  "), rel_path = FALSE)"
)
new_block <- paste0(
  "xfun::in_dir(\n",
  "  file.path(project_root, \"audit\", \"hypotheses\", \"H06_daily\"),\n",
  "  knitr::include_graphics(file.path(\n",
  "    project_root,\n",
  "    \"artifacts/10_figures/H06_daily\",\n",
  "    \"H06_daily_preparation_primary_sample_support.png\"\n",
  "  ))\n",
  ")"
)
old_matches <- gregexpr(old_block, source_text, fixed = TRUE)[[1L]]
if (length(old_matches) != 1L || old_matches[[1L]] < 1L) {
  stopf("The current source does not contain exactly one repair target")
}
prospective <- sub(old_block, new_block, source_text, fixed = TRUE)
if (
  digest::digest(prospective, algo = "sha256", serialize = FALSE) !=
    "b1d2c9ec6184e9c537af04119d94040b581ae691069e38e0a713935ab1582536" ||
    nchar(prospective, type = "bytes") != 35521L
) {
  stopf("The prospective companion source identity differs")
}
reversed <- sub(new_block, old_block, prospective, fixed = TRUE)
if (!identical(reversed, source_text)) {
  stopf("The prospective source does not reverse exactly")
}

source_lines <- strsplit(prospective, "\n", fixed = TRUE)[[1L]]
chunk_starts <- grep("^```[{]r([^}]*)[}]\\s*$", source_lines, perl = TRUE)
if (length(chunk_starts) != 19L) {
  stopf("The prospective source must contain exactly 19 R chunks")
}
for (chunk_start in chunk_starts) {
  relative_end <- which(
    grepl("^```\\s*$", source_lines[(chunk_start + 1L):length(source_lines)])
  )[[1L]]
  chunk_end <- chunk_start + relative_end
  chunk_text <- paste(
    source_lines[(chunk_start + 1L):(chunk_end - 1L)],
    collapse = "\n"
  )
  tryCatch(
    parse(text = chunk_text),
    error = function(error) {
      stopf(
        "Prospective R chunk beginning on line %d does not parse: %s",
        chunk_start,
        conditionMessage(error)
      )
    }
  )
}

companion_dir <- normalizePath(
  file.path(root, "audit", "hypotheses", "H06_daily"),
  winslash = "/",
  mustWork = TRUE
)
absolute_figure <- normalizePath(
  figure_png,
  winslash = "/",
  mustWork = TRUE
)
old_output_dir <- knitr::opts_knit$get("output.dir")
on.exit(
  knitr::opts_knit$set(output.dir = old_output_dir),
  add = TRUE
)
knitr::opts_knit$set(output.dir = companion_dir)
reader_path <- xfun::in_dir(
  companion_dir,
  knitr::include_graphics(absolute_figure)
)
reader_path <- unclass(reader_path)
expected_reader_path <- paste0(
  "../../../artifacts/10_figures/H06_daily/",
  "H06_daily_preparation_primary_sample_support.png"
)
if (!identical(reader_path, expected_reader_path)) {
  stopf("The reader-safe knitr path differs")
}
if (xfun::is_abs_path(reader_path)) {
  stopf("The reader-safe knitr path is absolute")
}
if (!file.exists(file.path(companion_dir, reader_path))) {
  stopf("The reader-safe knitr path does not resolve from the companion")
}

h07_html <- file.path(
  "_build",
  "nathealth",
  "audit",
  "hypotheses",
  "H07",
  "H07_analysis_preparation.html"
)
if (!file.exists(h07_html)) {
  stopf("The accepted H07 companion comparator is absent")
}
h07_text <- readChar(h07_html, file.info(h07_html)$size, useBytes = TRUE)
if (!grepl("src=\"../../../artifacts/", h07_text, fixed = TRUE)) {
  stopf("The accepted companion comparator lacks the same path pattern")
}

cat(
  paste0(
    "H06_DAILY_ORDER49B_STOP_AND_PATH_PROBE=PASS ",
    "owner_manifest=65 tables=17 semantic_substitutions=1003 ",
    "prospective=b1d2c9ec reader_path=../../../artifacts source_html=historical_absent\n"
  )
)
