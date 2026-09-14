#!/usr/bin/env Rscript

# Independent read-only audit of the Order 67a protected-postflight stop.
# This script performs structural inventory and HTML-shell checks only. It does
# not execute a QMD, render a document, or calculate a scientific result.

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

read_exact_inventory <- function(path, rows) {
  value <- readr::read_csv(path, show_col_types = FALSE)
  stopifnot(
    nrow(value) == rows,
    identical(names(value), c("path", "sha256", "bytes")),
    !anyDuplicated(value$path)
  )
  value
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

implementation_path <- file.path(
  evidence_dir,
  "order67a_transform_verify_promote_verifier_corrected.R"
)
require_file(
  implementation_path,
  "e3f1b14a7e6c2a4a51b52a3bfac78d484c71446cc7ad04cce8d8889c450e3c66",
  65208
)
implementation <- read_raw_text(implementation_path)
stopifnot(
  count_fixed(
    '"_build/nathealth/notebooks/hypotheses/H06.html"\n  )',
    implementation
  ) == 1L,
  count_fixed(
    '"_build/nathealth/audit/hypotheses/H06/H06_analysis_preparation.html"',
    implementation
  ) == 0L
)

preflight_path <- file.path(evidence_dir, "preflight_protected_inventory.csv")
require_file(
  preflight_path,
  "db1edf1fed336983389ce0463c87ed96c9692dd1434e7781b490d19e2dda223c",
  8623
)
protected_pre <- read_exact_inventory(preflight_path, 54L)
protected_paths <- file.path(project_root, protected_pre$path)
stopifnot(
  all(file.exists(protected_paths)),
  !any(dir.exists(protected_paths)),
  !any(nzchar(Sys.readlink(protected_paths)))
)
post_sha256 <- unname(vapply(protected_paths, sha256_file, character(1)))
post_bytes <- unname(as.numeric(file.info(protected_paths)$size))
changed_index <- which(
  protected_pre$sha256 != post_sha256 |
    as.numeric(protected_pre$bytes) != post_bytes
)
changed <- data.frame(
  path = protected_pre$path[changed_index],
  pre_sha256 = protected_pre$sha256[changed_index],
  post_sha256 = post_sha256[changed_index],
  pre_bytes = as.numeric(protected_pre$bytes[changed_index]),
  post_bytes = post_bytes[changed_index],
  stringsAsFactors = FALSE
)
changed <- changed[order(changed$path), ]
rownames(changed) <- NULL

expected_changed <- data.frame(
  path = sort(c(
    "_includes/nathealth-mobile-toc.html",
    "audit/report_harmonization/phase4_corpus_manifest.csv",
    "_build/nathealth/notebooks/hypotheses/H06.html",
    paste0(
      "_build/nathealth/audit/hypotheses/H06/",
      "H06_analysis_preparation.html"
    )
  )),
  stringsAsFactors = FALSE
)
expected_values <- list(
  "_includes/nathealth-mobile-toc.html" = c(
    "926a5fc051f032100714ae01b53c5ba2937c91ff2406ab5354484bf8fd7f553d",
    "153967734707cccf0fb2e910327cebfadb552f3c752b70e67b5346fb9acd8980",
    "1388",
    "1542"
  ),
  "audit/report_harmonization/phase4_corpus_manifest.csv" = c(
    "c42c326230818a93aa89322155b933c2f536f09bd447ab09b72f934fba75e76f",
    "5d66d43ddfa2858193603db656c0cd25c0c2229ea9bee3678dc4c56a9705855b",
    "11479",
    "11479"
  ),
  "_build/nathealth/notebooks/hypotheses/H06.html" = c(
    "b701a6d6e10e37fbe143117b70c0ba78e2d65ade0b973f3e1cd3e43a6f658dc9",
    "4883b77a2e225c8bad8628f1a04274f5d19d81aeb7cc493949707cdc6cd98e2f",
    "4898662",
    "4898816"
  ),
  "_build/nathealth/audit/hypotheses/H06/H06_analysis_preparation.html" = c(
    "ae3dd53c5c3947e163a6048807f1e639197548e8e824c9d52709da3a65f74683",
    "aeac00b6806ae10368e133e904784e7c2fcc79747bb8c8e2dc95fe2d721a944e",
    "849545",
    "849699"
  )
)
expected_changed$pre_sha256 <- vapply(
  expected_changed$path,
  function(path) expected_values[[path]][[1L]],
  character(1)
)
expected_changed$post_sha256 <- vapply(
  expected_changed$path,
  function(path) expected_values[[path]][[2L]],
  character(1)
)
expected_changed$pre_bytes <- as.numeric(vapply(
  expected_changed$path,
  function(path) expected_values[[path]][[3L]],
  character(1)
))
expected_changed$post_bytes <- as.numeric(vapply(
  expected_changed$path,
  function(path) expected_values[[path]][[4L]],
  character(1)
))
stopifnot(identical(changed, expected_changed))

promotion_path <- file.path(evidence_dir, "candidate_promotion_manifest.csv")
require_file(
  promotion_path,
  "068e760ad759b73c6d2d8849af00c65d4e4d8251c5e1e11138dd336e750332d6",
  11975
)
promotion <- readr::read_csv(promotion_path, show_col_types = FALSE)
companion_rel <- paste0(
  "_build/nathealth/audit/hypotheses/H06/",
  "H06_analysis_preparation.html"
)
companion_row <- promotion[promotion$target_path == companion_rel, , drop = FALSE]
stopifnot(
  nrow(promotion) == 38L,
  nrow(companion_row) == 1L,
  companion_row$order[[1L]] == 25L,
  companion_row$pre_sha256[[1L]] == expected_values[[companion_rel]][[1L]],
  companion_row$post_sha256[[1L]] == expected_values[[companion_rel]][[2L]],
  companion_row$pre_bytes[[1L]] == 849545,
  companion_row$post_bytes[[1L]] == 849699
)

backup_root <- trimws(readLines(
  file.path(evidence_dir, "backup_root.txt"),
  warn = FALSE
)[[1L]])
stopifnot(startsWith(backup_root, "/private/tmp/"))
backup_companion <- file.path(backup_root, "preimages", companion_rel)
live_companion <- file.path(project_root, companion_rel)
backup_include <- file.path(
  backup_root,
  "preimages/_includes/nathealth-mobile-toc.html"
)
live_include <- file.path(project_root, "_includes/nathealth-mobile-toc.html")
require_file(
  backup_companion,
  expected_values[[companion_rel]][[1L]],
  849545
)
require_file(
  live_companion,
  expected_values[[companion_rel]][[2L]],
  849699
)
require_file(
  backup_include,
  expected_values[["_includes/nathealth-mobile-toc.html"]][[1L]],
  1388
)
require_file(
  live_include,
  expected_values[["_includes/nathealth-mobile-toc.html"]][[2L]],
  1542
)

script_pattern <- "<script>([\\s\\S]*?)</script>"
include_pre <- read_raw_text(backup_include)
include_post <- read_raw_text(live_include)
script_pre <- sub(
  script_pattern,
  "\\1",
  regmatches(include_pre, regexpr(script_pattern, include_pre, perl = TRUE)),
  perl = TRUE
)
script_post <- sub(
  script_pattern,
  "\\1",
  regmatches(include_post, regexpr(script_pattern, include_post, perl = TRUE)),
  perl = TRUE
)
stopifnot(
  count_fixed(script_pre, read_raw_text(backup_companion)) == 1L,
  count_fixed(script_post, read_raw_text(live_companion)) == 1L,
  identical(
    replace_one_fixed(read_raw_text(live_companion), script_post, script_pre),
    read_raw_text(backup_companion)
  )
)

corpus_path <- file.path(
  project_root,
  "audit/report_harmonization/phase4_corpus_manifest.csv"
)
historical_corpus_path <- file.path(evidence_dir, "corpus_manifest_pre.csv")
require_file(
  corpus_path,
  expected_values[["audit/report_harmonization/phase4_corpus_manifest.csv"]][[2L]],
  11479
)
require_file(
  historical_corpus_path,
  expected_values[["audit/report_harmonization/phase4_corpus_manifest.csv"]][[1L]],
  11479
)
corpus <- readr::read_csv(corpus_path, show_col_types = FALSE)
historical_corpus <- readr::read_csv(
  historical_corpus_path,
  show_col_types = FALSE
)
live_html_sha <- vapply(corpus$expected_html, sha256_file, character(1))
source_columns <- setdiff(names(corpus), c("html_exists", "html_sha256"))
stopifnot(
  nrow(corpus) == 37L,
  nrow(historical_corpus) == 37L,
  !anyDuplicated(corpus$expected_html),
  identical(corpus[source_columns], historical_corpus[source_columns]),
  all(corpus$html_exists),
  identical(unname(corpus$html_sha256), unname(live_html_sha)),
  corpus$html_sha256[corpus$expected_html == companion_rel] ==
    expected_values[[companion_rel]][[2L]]
)

candidate_inventory_path <- file.path(evidence_dir, "candidate_build_inventory.csv")
post_inventory_path <- file.path(evidence_dir, "post_promotion_build_inventory.csv")
require_file(
  candidate_inventory_path,
  "a45ec438ae36fcba8ae420d6824e342f8822cce182f9351e41e624ed4ae8a5c5",
  124510
)
require_file(
  post_inventory_path,
  "a45ec438ae36fcba8ae420d6824e342f8822cce182f9351e41e624ed4ae8a5c5",
  124510
)
candidate_inventory <- read_exact_inventory(candidate_inventory_path, 892L)
sealed_post_inventory <- read_exact_inventory(post_inventory_path, 892L)
live_inventory <- inventory_files(file.path(project_root, "_build/nathealth"))
stopifnot(
  same_inventory(candidate_inventory, sealed_post_inventory),
  same_inventory(candidate_inventory, live_inventory)
)

production_route_path <- file.path(evidence_dir, "production_browser_route_qa.json")
production_desktop_path <- file.path(
  evidence_dir,
  "production_browser_desktop_qa.json"
)
h06_qa_path <- file.path(evidence_dir, "production_h06_extended_qa.json")
lifecycle_path <- file.path(evidence_dir, "production_server_lifecycle.csv")
require_file(
  production_route_path,
  "9571ee93bebb87baa1f6a9ed73ea2041c170f5aced434bb64ff601a3c0fe3720",
  75495
)
require_file(
  production_desktop_path,
  "94e3108ecbb938cc9451904951c21515fabd91291d8586a3e9a23386e270e925",
  1259
)
require_file(
  h06_qa_path,
  "a2a8e762a10a4606ef7926c2941a31bd7ca2ffb33d3c93db17e98df6914c5c60",
  4613
)
require_file(
  lifecycle_path,
  "02f8a9483b78219271f6296870765f1a3856e3fb6d3405649c83d20c837f744e",
  184
)
production_route <- jsonlite::fromJSON(
  production_route_path,
  simplifyDataFrame = TRUE
)
production_desktop <- jsonlite::fromJSON(
  production_desktop_path,
  simplifyDataFrame = TRUE
)
h06_qa <- jsonlite::fromJSON(h06_qa_path, simplifyDataFrame = TRUE)
lifecycle <- readr::read_csv(lifecycle_path, show_col_types = FALSE)
stopifnot(
  nrow(production_route) == 74L,
  all(production_route$pass),
  nrow(production_desktop) == 3L,
  all(production_desktop$pass),
  nrow(h06_qa) == 4L,
  all(h06_qa$pass),
  all(h06_qa$content_bearing_disclosures_usable),
  all(h06_qa$inherited_inert_marker_exact),
  all(h06_qa$technical_sections_visible_before_toggle),
  all(h06_qa$technical_sections_visible_after_toggle),
  all(h06_qa$mobile_toc_link_count == 10L),
  all(h06_qa$canonical_toc_link_count == 10L),
  nrow(lifecycle) == 1L,
  lifecycle$served_production_only[[1L]],
  lifecycle$pre_serve_symlinks[[1L]] == 0L,
  lifecycle$server_stopped[[1L]],
  lifecycle$listener_cleared[[1L]],
  lifecycle$viewport_reset[[1L]],
  lifecycle$session_tabs_closed[[1L]]
)

screenshot_paths <- sort(list.files(
  file.path(evidence_dir, "screenshots"),
  pattern = "\\.png$",
  full.names = TRUE
))
stopifnot(length(screenshot_paths) >= 8L, all(file_bytes(screenshot_paths) > 0L))
require_file(
  file.path(project_root, "styles-nathealth.css"),
  "051d9468f636df71e2408687661369a443029407426fef98850ff56def9aac87",
  4548
)
require_file(
  file.path(project_root, "_build/nathealth/styles-nathealth.css"),
  "051d9468f636df71e2408687661369a443029407426fef98850ff56def9aac87",
  4548
)

cat(
  paste0(
    "ORDER67A_PROTECTED_POSTFLIGHT_STOP=PASS protected=54 exact=50 ",
    "authorized=4 companion_shell_reverse=TRUE corpus=37/37 build=892/892 ",
    "route_qa=74/74 desktop=3/3 h06=4/4 screenshots>=8 ",
    "listener_cleared=TRUE downstream_masked=NONE R=4.6.1\n"
  )
)
