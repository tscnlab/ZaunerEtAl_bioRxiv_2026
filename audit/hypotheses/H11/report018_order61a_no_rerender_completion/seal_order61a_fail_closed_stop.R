#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE, warn = 2)
stopifnot(identical(as.character(getRversion()), "4.6.1"))
suppressPackageStartupMessages({
  library(openssl)
  library(readr)
})

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
setwd(root)
evidence_dir <- file.path(
  root,
  "audit/hypotheses/H11/report018_order61a_no_rerender_completion"
)

sha256_file <- function(path) {
  connection <- file(path, open = "rb")
  on.exit(close(connection), add = TRUE)
  paste0(openssl::sha256(connection))
}

file_bytes <- function(path) unname(as.numeric(file.info(path)$size))

relative_path <- function(path) {
  normalized <- normalizePath(path, winslash = "/", mustWork = FALSE)
  prefix <- paste0(root, "/")
  ifelse(
    startsWith(normalized, prefix),
    substring(normalized, nchar(prefix) + 1L),
    normalized
  )
}

raw_identical <- function(first, second) {
  first_bytes <- readBin(first, what = "raw", n = file_bytes(first))
  second_bytes <- readBin(second, what = "raw", n = file_bytes(second))
  identical(first_bytes, second_bytes)
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

test_path <- "tests/hypotheses/H11/test_h11_preparation_report.R"
manifest_path <- "artifacts/12_manifests/H11/H11_preparation_report_manifest.csv"
source_exact <-
  sha256_file(test_path) ==
    "64b427b4bc11f79a1ea2cd539eee7e30184271ef05cbba7b3f511a2f105a15a3" &&
  file_bytes(test_path) == 11831 &&
  sha256_file(manifest_path) ==
    "bd34dbfd6d2e929c825fe76281dfd384d8b0ef851b3d99a52b155c3216cfc6d9" &&
  file_bytes(manifest_path) == 73184
add_check("authorized_source_postimages", source_exact, "test=64b427b4/11831 manifest=bd34dbfd/73184")

inventory_names <- c(
  "build_inventory",
  "protected_inventory",
  "scientific_inventory",
  "critical_identities"
)
for (name in inventory_names) {
  pre <- file.path(evidence_dir, paste0(name, "_preqa.csv"))
  post <- file.path(evidence_dir, paste0(name, "_postqa.csv"))
  pass <- file.exists(pre) && file.exists(post) && raw_identical(pre, post)
  add_check(paste0(name, "_pre_post_raw_identity"), pass, ifelse(pass, "byte-identical", "mismatch"))
}

representation <- readr::read_csv(
  file.path(evidence_dir, "screenshot_representation_audit.csv"),
  show_col_types = FALSE
)
screen_paths <- file.path(evidence_dir, representation$file)
signature_exact <- all(vapply(screen_paths, function(path) {
  signature <- readBin(path, what = "raw", n = 10L)
  identical(
    as.integer(signature),
    c(255L, 216L, 255L, 224L, 0L, 16L, 74L, 70L, 73L, 70L)
  )
}, logical(1)))
representation_pass <- nrow(representation) == 9L &&
  all(representation$actual_representation == "JPEG JFIF") &&
  all(representation$visual_inspection_complete) &&
  all(!representation$representation_match) &&
  signature_exact
add_check(
  "exact_screenshot_representation_mismatch",
  representation_pass,
  "9/9 JPEG-JFIF payloads stored under .png suffixes"
)

failure_text <- paste(
  readLines(
    file.path(evidence_dir, "finalizer_failure.txt"),
    warn = FALSE,
    encoding = "UTF-8"
  ),
  collapse = "\n"
)
failure_exact <-
  grepl("Run count: 1", failure_text, fixed = TRUE) &&
  grepl("Exit status: 1", failure_text, fixed = TRUE) &&
  grepl("FAIL_CLOSED_NO_RETRY", failure_text, fixed = TRUE)
add_check("single_finalizer_failure_record", failure_exact, "run=1 exit=1 no-retry")

lifecycle_text <- paste(
  readLines(
    file.path(evidence_dir, "loopback_server_lifecycle.md"),
    warn = FALSE,
    encoding = "UTF-8"
  ),
  collapse = "\n"
)
lifecycle_exact <-
  grepl("Final disposition: PASS", lifecycle_text, fixed = TRUE) &&
  grepl("No listener or server process remained", lifecycle_text, fixed = TRUE)
add_check("loopback_teardown_record", lifecycle_exact, "listener=none process=none")

checks_frame <- do.call(rbind, checks)
readr::write_csv(
  checks_frame,
  file.path(evidence_dir, "order61a_fail_closed_checks.csv"),
  na = ""
)
stopifnot(all(checks_frame$pass))

seal_path <- file.path(evidence_dir, "order61a_fail_closed_non_circular_manifest.csv")
members <- list.files(
  evidence_dir,
  recursive = TRUE,
  full.names = TRUE,
  all.files = TRUE,
  no.. = TRUE
)
members <- sort(unique(members[
  file.exists(members) &
    !dir.exists(members) &
    normalizePath(members, winslash = "/", mustWork = FALSE) !=
      normalizePath(seal_path, winslash = "/", mustWork = FALSE)
]))
stopifnot(all(!nzchar(Sys.readlink(members))))
seal <- data.frame(
  path = relative_path(members),
  sha256 = vapply(members, sha256_file, character(1)),
  bytes = unname(as.numeric(file.info(members)$size)),
  stringsAsFactors = FALSE
)
stopifnot(!anyDuplicated(seal$path), !relative_path(seal_path) %in% seal$path)
readr::write_csv(seal, seal_path, na = "")

message(sprintf(
  paste0(
    "REPORT018_H11_ORDER61A_FAIL_CLOSED=SEALED checks=%d evidence=%d ",
    "reason=JPEG_JFIF_UNDER_PNG_SUFFIX no_retry=TRUE R=4.6.1"
  ),
  nrow(checks_frame),
  nrow(seal)
))
