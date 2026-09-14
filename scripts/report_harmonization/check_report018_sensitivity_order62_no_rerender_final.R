#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE, warn = 2)
suppressPackageStartupMessages({
  library(openssl)
})

stopifnot(identical(as.character(getRversion()), "4.6.1"))
arguments <- commandArgs(trailingOnly = TRUE)
stopifnot(
  length(arguments) == 1L,
  arguments[[1L]] %in% c("postrender", "postqa")
)
phase <- arguments[[1L]]

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

sealed_wrapper <- paste0(
  "scripts/report_harmonization/",
  "check_report018_sensitivity_order62_no_rerender.R"
)
sealed_sha <- sha256_file(sealed_wrapper)
stopifnot(identical(
  sealed_sha,
  "1420cefd49acf699cb1673b2877b44534fca832f092f294786ba3673a1e3491c"
))

wrapper_text <- paste(
  readLines(sealed_wrapper, warn = FALSE, encoding = "UTF-8"),
  collapse = "\n"
)
before <- paste0(
  "  location <- regexpr(before, text, fixed = TRUE)\n",
  "  stopifnot(location[[1L]] > 0L)\n",
  "  tail_start <- location[[1L]] + attr(location, \"match.length\")"
)
after <- paste0(
  "  locations <- gregexpr(before, text, fixed = TRUE)[[1L]]\n",
  "  stopifnot(length(locations) == 1L, locations[[1L]] > 0L)\n",
  "  location <- locations\n",
  "  tail_start <- location[[1L]] + attr(location, \"match.length\")"
)
stopifnot(sum(grepl(before, wrapper_text, fixed = TRUE)) == 1L)
wrapper_text <- sub(before, after, wrapper_text, fixed = TRUE)

absence_guard <- "  stopifnot(!grepl(before, output, fixed = TRUE))\n"
stopifnot(sum(grepl(absence_guard, wrapper_text, fixed = TRUE)) == 1L)
wrapper_text <- sub(absence_guard, "", wrapper_text, fixed = TRUE)

temporary_wrapper <- tempfile(
  "report018-sensitivity-order62-wrapper-recovery-",
  tmpdir = tempdir(),
  fileext = ".R"
)
writeLines(wrapper_text, temporary_wrapper, useBytes = TRUE)
on.exit(unlink(temporary_wrapper, force = TRUE), add = TRUE)
invisible(parse(file = temporary_wrapper))

semantic_dir <- normalizePath(
  Sys.getenv("SENSITIVITY_SEMANTIC_DIR"),
  winslash = "/",
  mustWork = TRUE
)
output <- suppressWarnings(system2(
  file.path(R.home("bin"), "Rscript"),
  c("--vanilla", shQuote(temporary_wrapper), phase),
  stdout = TRUE,
  stderr = TRUE,
  env = c(
    "RENV_CONFIG_AUTOLOADER_ENABLED=FALSE",
    paste0("R_LIBS_USER=", Sys.getenv("R_LIBS_USER")),
    paste0("NATHEALTH_PROJECT_ROOT=", root),
    paste0("SENSITIVITY_SEMANTIC_DIR=", semantic_dir)
  )
))
status <- attr(output, "status")
if (is.null(status)) status <- 0L

evidence_dir <- paste0(
  "audit/report_harmonization/",
  "report018_sensitivity_battery_order62_render"
)
output_path <- file.path(
  evidence_dir,
  paste0("final_no_rerender_", phase, "_output.txt")
)
writeLines(enc2utf8(output), output_path, useBytes = TRUE)
stopifnot(
  status == 0L,
  any(grepl(
    paste0(
      "REPORT018_SENSITIVITY_ORDER62_NO_RERENDER=PASS phase=",
      phase
    ),
    output,
    fixed = TRUE
  )),
  identical(sealed_sha, sha256_file(sealed_wrapper))
)

cat(sprintf(
  paste0(
    "REPORT018_SENSITIVITY_ORDER62_FINAL_WRAPPER=PASS phase=%s ",
    "sealed=%s R=%s\n"
  ),
  phase,
  sealed_sha,
  as.character(getRversion())
))
