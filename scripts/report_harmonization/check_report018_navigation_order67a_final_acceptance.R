#!/usr/bin/env Rscript

# Independent, read-only acceptance replay for REPORT-018 Navigation Order 67a.

options(stringsAsFactors = FALSE, warn = 2)
suppressPackageStartupMessages({
  library(digest)
  library(jsonlite)
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

resolve_path <- function(path) {
  if (startsWith(path, "/")) path else file.path(project_root, path)
}

require_file <- function(relative_path, sha256, bytes) {
  path <- resolve_path(relative_path)
  stopifnot(
    file.exists(path),
    !dir.exists(path),
    !nzchar(Sys.readlink(path)),
    identical(sha256_file(path), sha256),
    identical(file_bytes(path), as.numeric(bytes))
  )
  invisible(path)
}

same_inventory <- function(first, second) {
  first <- as.data.frame(first[order(first$path), c("path", "sha256", "bytes")])
  second <- as.data.frame(second[
    order(second$path),
    c("path", "sha256", "bytes")
  ])
  rownames(first) <- NULL
  rownames(second) <- NULL
  identical(as.character(first$path), as.character(second$path)) &&
    identical(as.character(first$sha256), as.character(second$sha256)) &&
    identical(as.numeric(first$bytes), as.numeric(second$bytes))
}

inventory_files <- function(root) {
  normalized_root <- normalizePath(root, winslash = "/", mustWork = TRUE)
  members <- sort(list.files(
    normalized_root,
    recursive = TRUE,
    full.names = TRUE,
    all.files = TRUE,
    include.dirs = TRUE,
    no.. = TRUE
  ))
  stopifnot(!any(nzchar(Sys.readlink(members))))
  paths <- members[!dir.exists(members)]
  data.frame(
    path = substring(paths, nchar(normalized_root) + 2L),
    sha256 = unname(vapply(paths, sha256_file, character(1))),
    bytes = unname(as.numeric(file.info(paths)$size)),
    stringsAsFactors = FALSE
  )
}

owner_files <- data.frame(
  path = file.path(
    evidence_rel,
    c(
      "order67a_read_only_completion_verifier.R",
      "order67a_read_only_protected_postflight.csv",
      "order67a_read_only_browser_qa_combined.csv",
      "order67a_read_only_browser_screenshot_manifest.csv",
      "order67a_read_only_completion_checks.csv",
      "order67a_read_only_completion.md",
      "order67a_read_only_completion_manifest.csv"
    )
  ),
  sha256 = c(
    "cde765e6bfbc862bf45a0f3173cc06c309b869ba3498d93f0f2955484882edd7",
    "ef1a3b3b4f0bfc7863f17e07efde806e5d541e165dae551dd7042a3ce1b8f35a",
    "e7f6d40e7c1b02871a18764c4db98167fa08b19406632dddf1b43a89e5e7ecfc",
    "f20c5d5959e69c68f9a2bbd141950120e0bf0433bff5acb0c78cd5d3a1f7e521",
    "45cd4f3c7ee92d68a77878c9fde5d1e968b7e783be05131b9b1de39d77727443",
    "ab2786c182de81d083c759428aba9af3d83a8d0f5e105d4f0c1f09687ef8ab6b",
    "52607f4c0085c740caf70bd9ca877ee6f3f450cad07751ba1f903ddf2b6b83d1"
  ),
  bytes = c(31689, 12876, 11311, 7679, 1270, 2295, 16798),
  stringsAsFactors = FALSE
)
for (index in seq_len(nrow(owner_files))) {
  require_file(
    owner_files$path[[index]],
    owner_files$sha256[[index]],
    owner_files$bytes[[index]]
  )
}

owner_manifest_rel <- file.path(
  evidence_rel,
  "order67a_read_only_completion_manifest.csv"
)
owner_manifest <- readr::read_csv(
  resolve_path(owner_manifest_rel),
  show_col_types = FALSE
)
stopifnot(
  nrow(owner_manifest) == 70L,
  identical(names(owner_manifest), c("path", "sha256", "bytes", "role")),
  !anyDuplicated(owner_manifest$path),
  !owner_manifest_rel %in% owner_manifest$path
)
owner_member_paths <- vapply(owner_manifest$path, resolve_path, character(1))
stopifnot(
  all(file.exists(owner_member_paths)),
  !any(dir.exists(owner_member_paths)),
  !any(nzchar(Sys.readlink(owner_member_paths))),
  identical(
    unname(vapply(owner_member_paths, sha256_file, character(1))),
    unname(owner_manifest$sha256)
  ),
  identical(
    unname(vapply(owner_member_paths, file_bytes, numeric(1))),
    as.numeric(owner_manifest$bytes)
  )
)

checks <- readr::read_csv(
  file.path(evidence_dir, "order67a_read_only_completion_checks.csv"),
  show_col_types = FALSE
)
stopifnot(
  nrow(checks) == 14L,
  !anyDuplicated(checks$check),
  all(checks$status == "PASS")
)

protected <- readr::read_csv(
  file.path(evidence_dir, "order67a_read_only_protected_postflight.csv"),
  show_col_types = FALSE
)
expected_authorized <- sort(c(
  "_build/nathealth/audit/hypotheses/H06/H06_analysis_preparation.html",
  "_build/nathealth/notebooks/hypotheses/H06.html",
  "_includes/nathealth-mobile-toc.html",
  "audit/report_harmonization/phase4_corpus_manifest.csv"
))
stopifnot(
  nrow(protected) == 54L,
  !anyDuplicated(protected$path),
  sum(protected$status == "EXACT") == 50L,
  sum(protected$status == "AUTHORIZED_ORDER67A_TRANSITION") == 4L,
  identical(
    sort(protected$path[protected$status == "AUTHORIZED_ORDER67A_TRANSITION"]),
    expected_authorized
  )
)
protected_paths <- vapply(protected$path, resolve_path, character(1))
stopifnot(
  identical(
    unname(vapply(protected_paths, sha256_file, character(1))),
    unname(protected$post_sha256)
  ),
  identical(
    unname(vapply(protected_paths, file_bytes, numeric(1))),
    as.numeric(protected$post_bytes)
  )
)

candidate_inventory <- readr::read_csv(
  file.path(evidence_dir, "candidate_build_inventory.csv"),
  show_col_types = FALSE
)
post_inventory <- readr::read_csv(
  file.path(evidence_dir, "post_promotion_build_inventory.csv"),
  show_col_types = FALSE
)
live_inventory <- inventory_files(file.path(project_root, "_build/nathealth"))
stopifnot(
  nrow(candidate_inventory) == 892L,
  nrow(post_inventory) == 892L,
  nrow(live_inventory) == 892L,
  same_inventory(candidate_inventory, post_inventory),
  same_inventory(candidate_inventory, live_inventory)
)

corpus_rel <- "audit/report_harmonization/phase4_corpus_manifest.csv"
require_file(
  corpus_rel,
  "5d66d43ddfa2858193603db656c0cd25c0c2229ea9bee3678dc4c56a9705855b",
  11479
)
corpus <- readr::read_csv(resolve_path(corpus_rel), show_col_types = FALSE)
stopifnot(
  nrow(corpus) == 37L,
  !anyDuplicated(corpus$expected_html),
  all(corpus$html_exists),
  identical(
    unname(vapply(corpus$expected_html, sha256_file, character(1))),
    unname(corpus$html_sha256)
  )
)

# Independently reparse all 37 canonical routes and check the integrated shell.
dom_counts <- vapply(
  corpus$expected_html,
  function(path) {
    document <- xml2::read_html(path)
    stopifnot(
      length(xml2::xml_find_all(
        document,
        "//main[@id='quarto-document-content']"
      )) ==
        1L,
      length(xml2::xml_find_all(document, "//*[@id='TOC']")) == 1L,
      length(xml2::xml_find_all(
        document,
        "//script[contains(., 'addMobileToc')]"
      )) ==
        1L
    )
    1L
  },
  integer(1)
)
stopifnot(sum(dom_counts) == 37L)

browser <- readr::read_csv(
  file.path(evidence_dir, "order67a_read_only_browser_qa_combined.csv"),
  show_col_types = FALSE
)
stopifnot(
  nrow(browser) == 158L,
  all(browser$pass),
  sum(browser$phase == "candidate_mobile") == 74L,
  sum(browser$phase == "production_mobile") == 74L,
  sum(browser$phase == "candidate_desktop") == 3L,
  sum(browser$phase == "production_desktop") == 3L,
  sum(browser$phase == "production_h06_extended") == 4L
)

screenshots <- readr::read_csv(
  file.path(evidence_dir, "order67a_read_only_browser_screenshot_manifest.csv"),
  show_col_types = FALSE
)
screenshot_paths <- vapply(screenshots$path, resolve_path, character(1))
stopifnot(
  nrow(screenshots) == 32L,
  !anyDuplicated(screenshots$path),
  all(file.exists(screenshot_paths)),
  identical(
    unname(vapply(screenshot_paths, sha256_file, character(1))),
    unname(screenshots$sha256)
  ),
  identical(
    unname(vapply(screenshot_paths, file_bytes, numeric(1))),
    as.numeric(screenshots$bytes)
  )
)

listener <- suppressWarnings(system2(
  "/usr/sbin/lsof",
  c("-nP", "-iTCP:57370", "-sTCP:LISTEN"),
  stdout = TRUE,
  stderr = TRUE
))
listener_status <- attr(listener, "status")
if (is.null(listener_status)) listener_status <- 0L
stopifnot(listener_status == 1L, length(listener) == 0L)

branch <- system2(
  "/usr/bin/git",
  c("rev-parse", "--abbrev-ref", "HEAD"),
  stdout = TRUE,
  stderr = TRUE
)
branch_status <- attr(branch, "status")
if (is.null(branch_status)) branch_status <- 0L
stopifnot(branch_status == 0L, identical(unname(branch), "rewrite/NH"))

cat(paste0(
  "REPORT018_NAVIGATION_ORDER67A_INDEPENDENT_ACCEPTANCE=PASS ",
  "owner=70/70 checks=14/14 protected=54/54 exact=50 authorized=4 ",
  "corpus=37/37 dom=37/37 build=892/892 symlinks=0 ",
  "browser=158/158 screenshots=32/32 listener_57370=cleared ",
  "branch=rewrite/NH R=",
  as.character(getRversion()),
  "\n"
))
