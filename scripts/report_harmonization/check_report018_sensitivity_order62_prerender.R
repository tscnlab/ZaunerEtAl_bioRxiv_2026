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

sha256_file <- function(path) {
  connection <- file(path, open = "rb")
  on.exit(close(connection), add = TRUE)
  paste0(openssl::sha256(connection))
}

audit_manifest <- function(path, expected_rows) {
  manifest <- readr::read_csv(path, show_col_types = FALSE)
  stopifnot(
    nrow(manifest) == expected_rows,
    !anyDuplicated(manifest$path),
    !path %in% manifest$path,
    all(file.exists(manifest$path)),
    all(vapply(manifest$path, sha256_file, character(1)) == manifest$sha256),
    all(
      unname(as.numeric(file.info(manifest$path)$size)) ==
        as.numeric(manifest$bytes)
    )
  )
  manifest
}

dispatch_path <- paste0(
  "audit/report_harmonization/",
  "report018_sensitivity_order62_dispatch_manifest.csv"
)
receipt_path <- paste0(
  "audit/report_harmonization/",
  "report018_sensitivity_order62_dispatch_receipt_manifest.csv"
)
invisible(audit_manifest(dispatch_path, 29L))
invisible(audit_manifest(receipt_path, 6L))

checker_path <- paste0(
  "scripts/report_harmonization/",
  "check_report018_sensitivity_battery_preflight.R"
)
checker_sha <- sha256_file(checker_path)
stopifnot(identical(
  checker_sha,
  "27ca85880beda38f82f27720735ca9c567acdac34b5b3d48d1b15d7fad4a515e"
))

matrix_path <- "audit/report_harmonization/coordination_matrix.csv"
matrix_sha <- sha256_file(matrix_path)
stopifnot(identical(
  matrix_sha,
  "7a6ce0ee4b2c97dea27d18ad3fed9759f580484ea046a2cf645ab5993f714842"
))

matrix_preimage <-
  "c8990a95151ebfd5deb0a1abca3a69ad2c4a1720f30537de13deebab2386b6ac"
checker_lines <- readLines(checker_path, warn = FALSE, encoding = "UTF-8")
stopifnot(sum(grepl(matrix_preimage, checker_lines, fixed = TRUE)) == 1L)
temporary_lines <- sub(
  matrix_preimage,
  matrix_sha,
  checker_lines,
  fixed = TRUE
)
stopifnot(
  sum(grepl(matrix_preimage, temporary_lines, fixed = TRUE)) == 0L,
  sum(grepl(matrix_sha, temporary_lines, fixed = TRUE)) == 1L
)

temporary_checker <- tempfile(
  "report018-sensitivity-order62-prerender-",
  tmpdir = tempdir(),
  fileext = ".R"
)
writeLines(temporary_lines, temporary_checker, useBytes = TRUE)
on.exit(unlink(temporary_checker, force = TRUE), add = TRUE)

output_dir <- Sys.getenv(
  "SENSITIVITY_ORDER62_PRERENDER_DIR",
  unset = file.path(
    root,
    paste0(
      "audit/report_harmonization/",
      "report018_sensitivity_battery_order62_render/prerender_preflight"
    )
  )
)
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
output_dir <- normalizePath(output_dir, winslash = "/", mustWork = TRUE)

output <- suppressWarnings(system2(
  file.path(R.home("bin"), "Rscript"),
  c("--vanilla", shQuote(temporary_checker)),
  stdout = TRUE,
  stderr = TRUE,
  env = c(
    "RENV_CONFIG_AUTOLOADER_ENABLED=FALSE",
    paste0("R_LIBS_USER=", Sys.getenv("R_LIBS_USER")),
    paste0("NATHEALTH_PROJECT_ROOT=", root),
    paste0("SENSITIVITY_PREFLIGHT_DIR=", output_dir)
  )
))
status <- attr(output, "status")
if (is.null(status)) status <- 0L
output_path <- file.path(output_dir, "prerender_preflight_output.txt")
writeLines(enc2utf8(output), output_path, useBytes = TRUE)

audit <- data.frame(
  check = c(
    "dispatch_manifest",
    "receipt_manifest",
    "original_checker_identity",
    "coordination_postimage",
    "exact_one_hash_substitution",
    "temporary_checker_exit",
    "ten_domain_pass_marker",
    "project_checker_preserved"
  ),
  pass = c(
    TRUE,
    TRUE,
    identical(checker_sha, sha256_file(checker_path)),
    identical(matrix_sha, sha256_file(matrix_path)),
    sum(checker_lines != temporary_lines) == 1L,
    status == 0L,
    any(grepl(
      "REPORT018_SENSITIVITY_PREFLIGHT=PASS checks=10/10",
      output,
      fixed = TRUE
    )),
    identical(checker_sha, sha256_file(checker_path))
  ),
  detail = c(
    "29/29 exact",
    "6/6 exact",
    checker_sha,
    matrix_sha,
    "one dispatch matrix literal only",
    as.character(status),
    paste(output, collapse = " | "),
    sha256_file(checker_path)
  ),
  stringsAsFactors = FALSE
)
readr::write_csv(audit, file.path(output_dir, "matrix_transition_audit.csv"))
stopifnot(nrow(audit) == 8L, all(audit$pass))

cat(sprintf(
  paste0(
    "REPORT018_SENSITIVITY_ORDER62_PRERENDER=PASS checks=%d/%d ",
    "dispatch=29/29 receipt=6/6 matrix=%s R=%s\n"
  ),
  sum(audit$pass),
  nrow(audit),
  matrix_sha,
  as.character(getRversion())
))
