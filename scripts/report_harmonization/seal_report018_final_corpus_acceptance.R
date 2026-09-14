#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE, warn = 2)
suppressPackageStartupMessages({
  library(openssl)
  library(readr)
})

stopifnot(identical(as.character(getRversion()), "4.6.1"))

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
setwd(root)

evidence_dir <- paste0(
  "audit/report_harmonization/",
  "report018_final_corpus_integration"
)
manifest_path <- "audit/report_harmonization/phase4_corpus_manifest.csv"
matrix_path <- "audit/report_harmonization/coordination_matrix.csv"
acceptance_path <- paste0(
  "audit/report_harmonization/",
  "report018_final_corpus_independent_acceptance.md"
)
acceptance_manifest_path <- paste0(
  "audit/report_harmonization/",
  "report018_final_corpus_independent_acceptance_manifest.csv"
)

sha256_file <- function(path) {
  connection <- file(path, open = "rb")
  on.exit(close(connection), add = TRUE)
  paste0(openssl::sha256(connection))
}

file_bytes <- function(path) unname(as.numeric(file.info(path)$size))

raw_identical <- function(first, second) {
  identical(readr::read_file_raw(first), readr::read_file_raw(second))
}

checks <- list()
add_check <- function(check_id, pass, detail) {
  checks[[length(checks) + 1L]] <<- data.frame(
    check_id = check_id,
    pass = isTRUE(pass),
    detail = as.character(detail),
    stringsAsFactors = FALSE
  )
}

corpus <- readr::read_csv(manifest_path, show_col_types = FALSE)
source_exact <- file.exists(corpus$source) &
  vapply(corpus$source, sha256_file, character(1)) == corpus$source_sha256
html_exact <- file.exists(corpus$expected_html) &
  vapply(corpus$expected_html, sha256_file, character(1)) == corpus$html_sha256
add_check(
  "corpus_manifest",
  nrow(corpus) == 37L &&
    sha256_file(manifest_path) ==
      "983b16136c1115d5a6b8dceb135c10de8d347743c694c5027c4ead9b2c7aa605" &&
    all(source_exact) &&
    all(html_exact),
  "37/37 source and HTML identities are live exact"
)

historical_manifest <- file.path(
  evidence_dir,
  "historical_phase4_corpus_manifest_pre.csv"
)
rebuild <- readr::read_csv(
  file.path(evidence_dir, "manifest_rebuild_execution.csv"),
  show_col_types = FALSE
)
add_check(
  "single_manifest_rebuild",
  sha256_file(historical_manifest) ==
    "73f1a371f8352f1baf69d38f1613de1a662112642370b0cc89798b4d6d469334" &&
    nrow(rebuild) == 6L &&
    all(rebuild$status == "PASS") &&
    rebuild$value[rebuild$field == "builder_execution_count"] == "1",
  "historical preimage exact and builder count is one"
)

final_checks <- readr::read_csv(
  file.path(evidence_dir, "final_corpus_checks.csv"),
  show_col_types = FALSE
)
add_check(
  "final_corpus_checks",
  nrow(final_checks) == 6L && all(final_checks$pass),
  "6/6 final corpus checks pass"
)

structural <- readr::read_csv(
  file.path(evidence_dir, "structural_test_classification.csv"),
  show_col_types = FALSE
)
add_check(
  "structural_test_classification",
  nrow(structural) == 9L &&
    all(structural$accepted) &&
    sum(structural$disposition == "PASS") == 6L &&
    sum(structural$disposition != "PASS") == 3L,
  "six current tests pass and three historical stops are exact"
)

dom <- readr::read_csv(
  file.path(evidence_dir, "corpus_dom_audit.csv"),
  show_col_types = FALSE
)
tables <- readr::read_csv(
  file.path(evidence_dir, "corpus_table_semantic_audit.csv"),
  show_col_types = FALSE
)
links <- readr::read_csv(
  file.path(evidence_dir, "corpus_internal_link_audit.csv"),
  show_col_types = FALSE
)
add_check(
  "live_dom_and_links",
  nrow(dom) == 37L &&
    all(dom$main_count == 1L) &&
    all(dom$error_nodes == 0L) &&
    all(dom$unresolved_local_links == 0L) &&
    all(dom$outside_build_links == 0L) &&
    sum(dom$gt_tables) == 572L &&
    sum(dom$header_tokens) == 46120L &&
    sum(dom$figures) == 160L &&
    nrow(links) == 10192L &&
    all(links$resolved) &&
    nrow(tables) == 572L,
  "37 mains, 572 tables, 160 figures, and 10192 local links"
)

semantic <- readr::read_csv(
  file.path(evidence_dir, "corpus_semantic_disposition.csv"),
  show_col_types = FALSE
)
alt <- readr::read_csv(
  file.path(evidence_dir, "corpus_image_alt_disposition.csv"),
  show_col_types = FALSE
)
add_check(
  "legacy_accessibility_classification",
  nrow(semantic) == 9L &&
    all(semantic$exact) &&
    sum(semantic$category == "LEGACY_TABLE_SEMANTICS_LIMITATION") == 8L &&
    sum(semantic$expected_duplicate_ids) == 63L &&
    sum(semantic$expected_unresolved_header_tokens) == 5509L &&
    nrow(alt) == 2L &&
    all(alt$exact) &&
    alt$informative_missing_alt[alt$source == "index.qmd"] == 24L &&
    alt$decorative_missing_alt[
      alt$source == "notebooks/descriptives.qmd"
    ] ==
      17L,
  "eight legacy table pages and 24 informative index images classified"
)

build_pre <- file.path(evidence_dir, "build_inventory_pre.csv")
build_post <- file.path(evidence_dir, "build_inventory_post.csv")
build <- readr::read_csv(build_post, show_col_types = FALSE)
add_check(
  "build_inventory_stability",
  raw_identical(build_pre, build_post) &&
    sha256_file(build_pre) ==
      "bc1656c63470deefeae55bfd7014035cfbbec11652135667e74bdf5fc51283b7" &&
    nrow(build) == 1180L &&
    sum(build$type == "file") == 871L &&
    sum(build$type == "directory") == 309L &&
    all(is.na(build$link_target) | !nzchar(build$link_target)),
  "1180 build members are byte stable with zero symlinks"
)

protected_pre <- readr::read_csv(
  file.path(evidence_dir, "protected_inventory_pre.csv"),
  show_col_types = FALSE
)
protected_post <- readr::read_csv(
  file.path(evidence_dir, "protected_inventory_post.csv"),
  show_col_types = FALSE
)
common <- intersect(protected_pre$path, protected_post$path)
same_member <- vapply(
  common,
  function(path) {
    pre_row <- protected_pre[protected_pre$path == path, , drop = FALSE]
    post_row <- protected_post[protected_post$path == path, , drop = FALSE]
    identical(pre_row$type, post_row$type) &&
      identical(pre_row$sha256, post_row$sha256) &&
      identical(pre_row$bytes, post_row$bytes) &&
      identical(pre_row$link_target, post_row$link_target)
  },
  logical(1)
)
changed <- common[!same_member]
added <- setdiff(protected_post$path, protected_pre$path)
removed <- setdiff(protected_pre$path, protected_post$path)
expected_added <- c(
  "scripts/report_harmonization/check_report018_final_corpus_integration.R",
  "scripts/report_harmonization/run_report018_final_corpus_structural_tests.R"
)
add_check(
  "protected_inventory_classification",
  nrow(protected_pre) == 13087L &&
    nrow(protected_post) == 13089L &&
    identical(sort(added), sort(expected_added)) &&
    !length(removed) &&
    identical(changed, manifest_path),
  "13086 common paths exact, one manifest transition, two bounded scripts"
)

transition_path <- paste0(
  "audit/report_harmonization/",
  "report018_final_corpus_matrix_transition.csv"
)
transition <- readr::read_csv(transition_path, show_col_types = FALSE)
matrix <- readr::read_csv(matrix_path, show_col_types = FALSE)
shared <- matrix[matrix$logical_order == "00", , drop = FALSE]
expected_status <- paste0(
  "complete_report018_final_37_page_corpus_accepted_with_",
  "documented_legacy_accessibility_limitations"
)
add_check(
  "matrix_transition",
  nrow(transition) == 1L &&
    transition$pre_sha256 ==
      "01b3438ff097c7ea31486f20932ec3fed72e2eac0361732ada3bedc69408d960" &&
    transition$post_sha256 ==
      "63b5f469c0270cd0c8d5570591e69f1b35c0b96e291ffb28c879ada95c43a582" &&
    sha256_file(matrix_path) == transition$post_sha256 &&
    nrow(matrix) == 15L &&
    ncol(matrix) == 16L &&
    nrow(shared) == 1L &&
    shared$current_task_status_2026_08_12 == expected_status,
  "shared matrix row records final REPORT-018 closure"
)

add_check(
  "acceptance_record",
  sha256_file(acceptance_path) ==
    "3d1f52ae56b7961a3249bf3a764992ba1da3084aaa68d80845a4b35364dbf8fb",
  "acceptance record is exact"
)

checks_frame <- do.call(rbind, checks)
stopifnot(nrow(checks_frame) == 10L, all(checks_frame$pass))
readr::write_csv(
  checks_frame,
  paste0(
    "audit/report_harmonization/",
    "report018_final_corpus_acceptance_checks.csv"
  )
)

integration_members <- sort(list.files(
  evidence_dir,
  recursive = TRUE,
  full.names = TRUE,
  all.files = TRUE,
  include.dirs = FALSE,
  no.. = TRUE
))
members <- unique(c(
  corpus$source,
  corpus$expected_html,
  integration_members,
  manifest_path,
  matrix_path,
  transition_path,
  acceptance_path,
  "audit/report_harmonization/report018_final_corpus_acceptance_checks.csv",
  "scripts/report_harmonization/capture_report018_final_corpus_inventory.R",
  "scripts/report_harmonization/run_report018_final_corpus_structural_tests.R",
  "scripts/report_harmonization/check_report018_final_corpus_integration.R",
  "scripts/report_harmonization/update_report018_final_corpus_matrix.R",
  "scripts/report_harmonization/seal_report018_final_corpus_acceptance.R",
  "tests/report_harmonization/test_navigation_contract.R",
  "_quarto-nathealth.yml",
  "renv.lock"
))
stopifnot(
  !acceptance_manifest_path %in% members,
  !anyDuplicated(members),
  all(file.exists(members)),
  !any(dir.exists(members)),
  !any(nzchar(Sys.readlink(members)))
)
acceptance_manifest <- data.frame(
  path = members,
  sha256 = vapply(members, sha256_file, character(1)),
  bytes = vapply(members, file_bytes, numeric(1)),
  stringsAsFactors = FALSE
)
readr::write_csv(acceptance_manifest, acceptance_manifest_path)

replay <- readr::read_csv(
  acceptance_manifest_path,
  show_col_types = FALSE
)
stopifnot(
  nrow(replay) == nrow(acceptance_manifest),
  !anyDuplicated(replay$path),
  !acceptance_manifest_path %in% replay$path,
  all(file.exists(replay$path)),
  all(vapply(replay$path, sha256_file, character(1)) == replay$sha256),
  all(vapply(replay$path, file_bytes, numeric(1)) == replay$bytes)
)

cat(sprintf(
  paste0(
    "REPORT018_FINAL_CORPUS_ACCEPTANCE=PASS checks=%d/%d ",
    "corpus=37/37 tables=572 figures=160 links=10192 build=1180 ",
    "manifest=%d/%d R=%s\n"
  ),
  sum(checks_frame$pass),
  nrow(checks_frame),
  nrow(replay),
  nrow(replay),
  as.character(getRversion())
))
