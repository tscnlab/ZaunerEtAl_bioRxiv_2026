#!/usr/bin/env Rscript

# Independent structural audit for the Order 67a candidate browser stop.
# This script does not execute a QMD or calculate a scientific result.

options(stringsAsFactors = FALSE, warn = 2)
suppressPackageStartupMessages({
  library(digest)
  library(jsonlite)
  library(readr)
})

stopifnot(identical(as.character(getRversion()), "4.6.1"))

project_root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
evidence_rel <- paste0(
  "audit/report_harmonization/",
  "navigation_mobile_toc_collapse_repair_2026_09_02/",
  "order67a_clone_state_repair"
)
evidence_dir <- file.path(project_root, evidence_rel)
candidate_root <- "/private/tmp/nathealth-order67a-continuation.37KbaZ"
candidate_build <- file.path(candidate_root, "candidate_build")

sha256_file <- function(path) {
  digest::digest(path, file = TRUE, algo = "sha256", serialize = FALSE)
}

file_bytes <- function(path) {
  unname(as.numeric(file.info(path)$size))
}

require_file <- function(path, sha256, bytes = NULL) {
  stopifnot(file.exists(path), !dir.exists(path), !nzchar(Sys.readlink(path)))
  stopifnot(identical(sha256_file(path), sha256))
  if (!is.null(bytes)) stopifnot(file_bytes(path) == bytes)
  invisible(TRUE)
}

read_exact_manifest <- function(path, rows) {
  manifest <- readr::read_csv(path, show_col_types = FALSE)
  stopifnot(
    nrow(manifest) == rows,
    !anyDuplicated(manifest$path),
    !path %in% manifest$path
  )
  paths <- ifelse(
    startsWith(manifest$path, "/"),
    manifest$path,
    file.path(project_root, manifest$path)
  )
  stopifnot(all(file.exists(paths)), !any(dir.exists(paths)))
  stopifnot(
    identical(
      unname(vapply(paths, sha256_file, character(1))),
      unname(manifest$sha256)
    ),
    identical(
      unname(vapply(paths, file_bytes, numeric(1))),
      as.numeric(manifest$bytes)
    )
  )
  manifest
}

inventory_files <- function(root) {
  normalized_root <- normalizePath(root, winslash = "/", mustWork = TRUE)
  paths <- sort(list.files(
    normalized_root,
    recursive = TRUE,
    full.names = TRUE,
    all.files = TRUE,
    include.dirs = FALSE,
    no.. = TRUE
  ))
  stopifnot(!any(nzchar(Sys.readlink(paths))))
  data.frame(
    path = substring(paths, nchar(normalized_root) + 2L),
    sha256 = unname(vapply(paths, sha256_file, character(1))),
    bytes = unname(as.numeric(file.info(paths)$size)),
    stringsAsFactors = FALSE
  )
}

same_inventory <- function(first, second) {
  first <- first[order(first$path), c("path", "sha256", "bytes")]
  second <- second[order(second$path), c("path", "sha256", "bytes")]
  rownames(first) <- NULL
  rownames(second) <- NULL
  identical(first$path, second$path) &&
    identical(first$sha256, second$sha256) &&
    identical(as.numeric(first$bytes), as.numeric(second$bytes))
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

stop_manifest_path <- file.path(
  evidence_dir,
  "order67a_candidate_browser_overflow_stop_manifest.csv"
)
require_file(
  stop_manifest_path,
  "89d3238198f62650d93c900770575e81824df7e0190876299bc1f2d5c54da660",
  9694
)
stop_manifest <- read_exact_manifest(stop_manifest_path, 42L)

require_file(
  file.path(evidence_dir, "candidate_browser_overflow_stop.md"),
  "c0466a1f7d375885a6a5629983f81f8862fafc72e21f85d90febac32697e5f37",
  2294
)
require_file(
  file.path(evidence_dir, "candidate_descriptives_overflow_diagnostic.csv"),
  "93f9b567ec9718558ddfec04dd9548ff6fd5153145f284ccc1bd579d40bde0d3",
  435
)
require_file(
  file.path(evidence_dir, "candidate_browser_route_qa_partial_stop.json"),
  "42ac08848d6662552cee98c8848f0b761e6b7da89c9bea0e7fceed8bbf2135c3",
  12073
)
require_file(
  file.path(evidence_dir, "candidate_server_lifecycle_stop.csv"),
  "a247eed08dc92296121f463369b192fa9f3ccf7701a7b76d754d462d62c0e3c0",
  205
)
require_file(
  file.path(evidence_dir, "corrected_candidate_execution_console.txt"),
  "aa61e182920e2e9b61be2d3c6d423cf9e4a43170de893e2d47a0ae34f936949c",
  175
)

baseline_path <- file.path(
  project_root,
  paste0(
    "audit/hypotheses/H06/employment_eligibility_sensitivity/",
    "order66b_result_no_rerender_completion/post_qa_build_inventory.csv"
  )
)
require_file(
  baseline_path,
  "8d00db3d2a7bfe8f17526cee08027bafd83f99bb7ad0e36c73e3e46cada5f355",
  124510
)
baseline <- readr::read_csv(baseline_path, show_col_types = FALSE)
candidate_seal <- readr::read_csv(
  file.path(evidence_dir, "candidate_build_inventory.csv"),
  show_col_types = FALSE
)
live <- inventory_files(file.path(project_root, "_build/nathealth"))
candidate <- inventory_files(candidate_build)
stopifnot(
  nrow(baseline) == 892L,
  nrow(live) == 892L,
  nrow(candidate) == 892L,
  same_inventory(baseline, live),
  same_inventory(candidate_seal, candidate)
)

phase4 <- readr::read_csv(
  file.path(
    project_root,
    "audit/report_harmonization/phase4_corpus_manifest.csv"
  ),
  show_col_types = FALSE
)
stopifnot(nrow(phase4) == 37L, !anyDuplicated(phase4$expected_html))
routes <- sub("^_build/nathealth/", "", phase4$expected_html)

candidate_aligned <- candidate[match(baseline$path, candidate$path), ]
changed <- baseline$path[baseline$sha256 != candidate_aligned$sha256]
stopifnot(length(changed) == 37L, setequal(changed, routes))

include_pre <- read_raw_text(file.path(
  project_root,
  "_includes/nathealth-mobile-toc.html"
))
include_post <- read_raw_text(file.path(
  candidate_root,
  "candidate_include/nathealth-mobile-toc.html"
))
stopifnot(
  sha256_file(file.path(project_root, "_includes/nathealth-mobile-toc.html")) ==
    "926a5fc051f032100714ae01b53c5ba2937c91ff2406ab5354484bf8fd7f553d",
  sha256_file(file.path(
    candidate_root,
    "candidate_include/nathealth-mobile-toc.html"
  )) ==
    "153967734707cccf0fb2e910327cebfadb552f3c752b70e67b5346fb9acd8980"
)

script_pattern <- "<script>([\\s\\S]*?)</script>"
script_pre <- sub(
  script_pattern,
  "\\1",
  regmatches(include_pre, regexpr(script_pattern, include_pre, perl = TRUE))
)
script_post <- sub(
  script_pattern,
  "\\1",
  regmatches(include_post, regexpr(script_pattern, include_post, perl = TRUE))
)

for (route in routes) {
  accepted_text <- read_raw_text(file.path(
    project_root,
    "_build/nathealth",
    route
  ))
  candidate_text <- read_raw_text(file.path(candidate_build, route))
  stopifnot(
    count_fixed(script_pre, accepted_text) == 1L,
    count_fixed(script_post, candidate_text) == 1L,
    identical(
      sub(script_post, script_pre, candidate_text, fixed = TRUE),
      accepted_text
    )
  )
}

diagnostic <- readr::read_csv(
  file.path(evidence_dir, "candidate_descriptives_overflow_diagnostic.csv"),
  show_col_types = FALSE
)
stopifnot(
  nrow(diagnostic) == 1L,
  identical(diagnostic$route[[1L]], "notebooks/descriptives.html"),
  diagnostic$viewport_width[[1L]] == 708L,
  diagnostic$viewport_height[[1L]] == 1000L,
  diagnostic$document_client_width[[1L]] == 693L,
  diagnostic$document_scroll_width[[1L]] == 1720L,
  diagnostic$page_overflow[[1L]],
  identical(diagnostic$primary_offender_id[[1L]], "near-eye-metric-summary"),
  identical(diagnostic$primary_offender_overflow_x[[1L]], "auto"),
  diagnostic$primary_offender_client_width[[1L]] == 642L,
  diagnostic$primary_offender_scroll_width[[1L]] == 1798L,
  identical(
    diagnostic$classification[[1L]],
    "PREEXISTING_WIDE_GT_TABLE_NOT_ORDER67A_NAVIGATION_DELTA"
  )
)

partial <- jsonlite::fromJSON(
  file.path(evidence_dir, "candidate_browser_route_qa_partial_stop.json"),
  simplifyDataFrame = TRUE
)
descriptives_index <- which(partial$route == "notebooks/descriptives.html")
stopifnot(
  nrow(partial) == 20L,
  !anyDuplicated(partial$route),
  length(descriptives_index) == 1L,
  sum(partial$pass) == 19L,
  !partial$pass[[descriptives_index]],
  partial$page_overflow[[descriptives_index]],
  partial$mobile_details_count[[descriptives_index]] == 1L,
  partial$mobile_link_count[[descriptives_index]] == 17L,
  partial$visible_link_count[[descriptives_index]] == 17L,
  partial$focusable_link_count[[descriptives_index]] == 17L,
  partial$first_fragment_exists[[descriptives_index]],
  partial$disclosure_closed_after_follow[[descriptives_index]],
  partial$link_order_matches_desktop[[descriptives_index]],
  partial$broken_images[[descriptives_index]] == 0L,
  partial$console_warnings[[descriptives_index]] == 0L,
  partial$console_errors[[descriptives_index]] == 0L,
  !partial$clipping_or_overlap[[descriptives_index]]
)

lifecycle <- readr::read_csv(
  file.path(evidence_dir, "candidate_server_lifecycle_stop.csv"),
  show_col_types = FALSE
)
stopifnot(
  nrow(lifecycle) == 1L,
  lifecycle$served_candidate_only[[1L]],
  lifecycle$pre_serve_symlinks[[1L]] == 0L,
  lifecycle$server_stopped[[1L]],
  lifecycle$listener_cleared[[1L]],
  lifecycle$viewport_reset[[1L]],
  lifecycle$session_tabs_closed[[1L]]
)

cat(sprintf(
  paste0(
    "ORDER67A_BROWSER_STOP=PREEXISTING_DESCRIPTIVES_OVERFLOW ",
    "owner_seal=%d/%d build=892/892 candidate=892/892 delta=37/37 ",
    "partial=19/20 toc=17/17 live=unchanged server=stopped R=%s\n"
  ),
  nrow(stop_manifest),
  nrow(stop_manifest),
  as.character(getRversion())
))
