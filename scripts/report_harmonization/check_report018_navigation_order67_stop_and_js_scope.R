#!/usr/bin/env Rscript

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)

stopifnot(identical(as.character(getRversion()), "4.6.1"))
required_packages <- c("digest", "jsonlite", "readr", "xml2")
stopifnot(all(vapply(
  required_packages,
  requireNamespace,
  logical(1),
  quietly = TRUE
)))

sha256_file <- function(path) {
  digest::digest(
    path,
    file = TRUE,
    algo = "sha256",
    serialize = FALSE
  )
}

read_raw_text <- function(path) {
  readChar(path, file.info(path)$size, useBytes = TRUE)
}

fixed_count <- function(pattern, text) {
  hits <- gregexpr(pattern, text, fixed = TRUE)[[1L]]
  if (identical(hits[[1L]], -1L)) {
    return(0L)
  }
  length(hits)
}

stop_dir <- file.path(
  root,
  "audit/report_harmonization/navigation_mobile_toc_collapse_repair_2026_09_02"
)
record_path <- file.path(stop_dir, "order67_fail_closed.md")
manifest_path <- file.path(stop_dir, "order67_fail_closed_manifest.csv")
observation_path <- file.path(stop_dir, "candidate_browser_observation.json")
screenshot_path <- file.path(stop_dir, "candidate_h06_708_open_failure.png")

stopifnot(
  identical(
    sha256_file(record_path),
    "7fbf139addab800060de16d4688853f1e426cf55a04451d5814aa709f24f9396"
  ),
  unname(file.info(record_path)$size) == 2501,
  identical(
    sha256_file(manifest_path),
    "e5bd594c9ffe6bdbbb675307646b130bf141ba00eef59896f356ca3e38ce2240"
  ),
  unname(file.info(manifest_path)$size) == 7934,
  identical(
    sha256_file(screenshot_path),
    "2e44f4e1660833d59738fa50882dc08fc71dacfaa1e95a55b450a0dd8ac095ff"
  )
)

manifest <- read.csv(
  manifest_path,
  check.names = FALSE,
  stringsAsFactors = FALSE
)
stopifnot(
  nrow(manifest) == 43L,
  !anyDuplicated(manifest$path),
  !manifest_path %in% file.path(root, manifest$path),
  all(file.exists(manifest$path)),
  identical(
    unname(vapply(manifest$path, sha256_file, character(1))),
    unname(manifest$sha256)
  ),
  identical(
    as.numeric(unname(file.info(manifest$path)$size)),
    as.numeric(manifest$bytes)
  )
)

observation <- jsonlite::fromJSON(observation_path, simplifyVector = TRUE)
stopifnot(
  identical(observation$status, "FAIL_CLOSED_BEFORE_PROMOTION"),
  identical(observation$route, "notebooks/hypotheses/H06.html"),
  observation$viewport$width == 708L,
  observation$viewport$height == 1000L,
  isTRUE(observation$mobile_toc$details_open),
  observation$mobile_toc$cloned_link_count == 10L,
  observation$mobile_toc$visible_link_count == 0L,
  identical(observation$mobile_toc$computed_list_display, "none"),
  observation$stylesheet_boundary$h06_external_stylesheet_reference_count == 0L,
  isTRUE(observation$stylesheet_boundary$h06_embeds_mobile_toc_css),
  observation$stylesheet_boundary$h06_embedded_override_selector_count == 0L
)

source_css <- file.path(root, "styles-nathealth.css")
build_css <- file.path(root, "_build/nathealth/styles-nathealth.css")
css_preimage <- "051d9468f636df71e2408687661369a443029407426fef98850ff56def9aac87"
stopifnot(
  identical(sha256_file(source_css), css_preimage),
  identical(sha256_file(build_css), css_preimage),
  unname(file.info(source_css)$size) == 4548,
  unname(file.info(build_css)$size) == 4548
)

build_root <- file.path(root, "_build/nathealth")
baseline_path <- file.path(
  root,
  paste0(
    "audit/hypotheses/H06/employment_eligibility_sensitivity/",
    "order66b_result_no_rerender_completion/post_qa_build_inventory.csv"
  )
)
baseline <- read.csv(
  baseline_path,
  check.names = FALSE,
  stringsAsFactors = FALSE
)
build_files <- list.files(
  build_root,
  all.files = TRUE,
  full.names = TRUE,
  recursive = TRUE,
  include.dirs = FALSE,
  no.. = TRUE
)
live_build <- data.frame(
  path = substring(build_files, nchar(build_root) + 2L),
  sha256 = unname(vapply(build_files, sha256_file, character(1))),
  bytes = as.numeric(unname(file.info(build_files)$size)),
  stringsAsFactors = FALSE
)
baseline <- baseline[order(baseline$path), , drop = FALSE]
live_build <- live_build[order(live_build$path), , drop = FALSE]
rownames(baseline) <- NULL
rownames(live_build) <- NULL
stopifnot(
  nrow(baseline) == 892L,
  identical(live_build$path, baseline$path),
  identical(live_build$sha256, baseline$sha256),
  identical(
    as.numeric(live_build$bytes),
    as.numeric(baseline$bytes)
  ),
  !any(nzchar(Sys.readlink(build_files)))
)

corpus_manifest_path <- file.path(
  root,
  "audit/report_harmonization/phase4_corpus_manifest.csv"
)
stopifnot(
  identical(
    sha256_file(corpus_manifest_path),
    "c42c326230818a93aa89322155b933c2f536f09bd447ab09b72f934fba75e76f"
  )
)
corpus_manifest <- read.csv(
  corpus_manifest_path,
  check.names = FALSE,
  stringsAsFactors = FALSE
)
html_paths <- unique(corpus_manifest$expected_html)
stopifnot(length(html_paths) == 37L, all(file.exists(html_paths)))

include_path <- file.path(root, "_includes/nathealth-mobile-toc.html")
include_pre <- read_raw_text(include_path)
stopifnot(
  identical(
    digest::digest(charToRaw(include_pre), algo = "sha256", serialize = FALSE),
    "926a5fc051f032100714ae01b53c5ba2937c91ff2406ab5354484bf8fd7f553d"
  ),
  nchar(include_pre, type = "bytes") == 1388L
)

script_open <- "<script>\n"
script_close <- "</script>\n"
stopifnot(
  startsWith(include_pre, script_open),
  endsWith(include_pre, script_close)
)
script_pre <- substr(
  include_pre,
  nchar(script_open) + 1L,
  nchar(include_pre) - nchar(script_close)
)
stopifnot(nchar(script_pre, type = "bytes") == 1369L)

clone_line <- "    const list = sourceList.cloneNode(true);\n"
clone_fix <- paste0(
  clone_line,
  "\n",
  "    list.classList.remove(\"collapse\");\n",
  "    list.querySelectorAll(\".collapse\").forEach((element) => {\n",
  "      element.classList.remove(\"collapse\");\n",
  "    });\n"
)
stopifnot(length(gregexpr(clone_line, include_pre, fixed = TRUE)[[1L]]) == 1L)
include_post <- sub(clone_line, clone_fix, include_pre, fixed = TRUE)
script_post <- sub(clone_line, clone_fix, script_pre, fixed = TRUE)
stopifnot(
  nchar(include_post, type = "bytes") == 1542L,
  identical(
    digest::digest(charToRaw(include_post), algo = "sha256", serialize = FALSE),
    "153967734707cccf0fb2e910327cebfadb552f3c752b70e67b5346fb9acd8980"
  ),
  identical(
    sub(clone_fix, clone_line, include_post, fixed = TRUE),
    include_pre
  ),
  nchar(script_post, type = "bytes") == 1523L,
  identical(
    sub(clone_fix, clone_line, script_post, fixed = TRUE),
    script_pre
  )
)

route_audit <- lapply(html_paths, function(path) {
  text <- read_raw_text(path)
  script_count <- fixed_count(script_pre, text)
  document <- xml2::read_html(path)
  collapse_lists <- xml2::xml_find_all(
    document,
    paste0(
      "//nav[@id='TOC']//ul[contains(concat(' ', normalize-space(@class), ",
      "' '), ' collapse ')]"
    )
  )
  root_collapse <- xml2::xml_find_all(
    document,
    paste0(
      "//nav[@id='TOC']/*[self::ul and contains(concat(' ', ",
      "normalize-space(@class), ' '), ' collapse ')]"
    )
  )
  external_css <- xml2::xml_find_all(
    document,
    "//link[@rel='stylesheet' and contains(@href, 'styles-nathealth.css')]"
  )
  prospective <- sub(script_pre, script_post, text, fixed = TRUE)
  reversed <- sub(script_post, script_pre, prospective, fixed = TRUE)
  data.frame(
    path = path,
    script_count = script_count,
    collapse_count = length(collapse_lists),
    root_collapse_count = length(root_collapse),
    external_css_count = length(external_css),
    pre_sha256 = sha256_file(path),
    post_sha256 = digest::digest(
      charToRaw(prospective),
      algo = "sha256",
      serialize = FALSE
    ),
    pre_bytes = nchar(text, type = "bytes"),
    post_bytes = nchar(prospective, type = "bytes"),
    reverse_exact = identical(reversed, text),
    stringsAsFactors = FALSE
  )
})
route_audit <- do.call(rbind, route_audit)

stopifnot(
  all(route_audit$script_count == 1L),
  sum(route_audit$collapse_count > 0L) == 31L,
  sum(route_audit$root_collapse_count > 0L) == 10L,
  sum(route_audit$collapse_count) == 115L,
  sum(route_audit$root_collapse_count) == 10L,
  sum(route_audit$external_css_count == 0L) == 1L,
  route_audit$external_css_count[grepl("/H06.html$", route_audit$path)] == 0L,
  all(
    route_audit$external_css_count[!grepl("/H06.html$", route_audit$path)] == 1L
  ),
  all(route_audit$post_bytes == route_audit$pre_bytes + 154L),
  all(route_audit$pre_sha256 != route_audit$post_sha256),
  length(unique(route_audit$post_sha256)) == 37L,
  all(route_audit$reverse_exact)
)

prospective_manifest <- corpus_manifest
prospective_manifest$html_exists <- TRUE
prospective_manifest$html_sha256 <- route_audit$post_sha256[
  match(prospective_manifest$expected_html, route_audit$path)
]
prospective_manifest_text <- readr::format_csv(prospective_manifest)
stopifnot(
  !anyNA(prospective_manifest$html_sha256),
  nchar(prospective_manifest_text, type = "bytes") == 11479L,
  identical(
    digest::digest(
      charToRaw(prospective_manifest_text),
      algo = "sha256",
      serialize = FALSE
    ),
    "5d66d43ddfa2858193603db656c0cd25c0c2229ea9bee3678dc4c56a9705855b"
  ),
  identical(prospective_manifest$source, corpus_manifest$source),
  identical(prospective_manifest$source_sha256, corpus_manifest$source_sha256),
  identical(
    prospective_manifest[names(prospective_manifest) != "html_sha256"],
    corpus_manifest[names(corpus_manifest) != "html_sha256"]
  )
)

cat(sprintf(
  paste0(
    "ORDER67_STOP=ACCEPTED manifest=43/43 build=892/892 routes=37/37 ",
    "collapse_routes=31 root_hidden=10 collapse_lists=115 ",
    "include_post=15396773 html_postimages=37 corpus_post=5d66d43d ",
    "reverse=38/38 R=%s\n"
  ),
  as.character(getRversion())
))
