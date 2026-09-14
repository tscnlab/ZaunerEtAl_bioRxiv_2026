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

sealed_final_wrapper <- paste0(
  "scripts/report_harmonization/",
  "check_report018_sensitivity_order62_no_rerender_final.R"
)
sealed_sha <- sha256_file(sealed_final_wrapper)
stopifnot(identical(
  sealed_sha,
  "9657996be5fcc3a6d7588339fd3094c26d63371b6f4c3af844ab367661e72961"
))

wrapper_text <- paste(
  readLines(sealed_final_wrapper, warn = FALSE, encoding = "UTF-8"),
  collapse = "\n"
)
insertion_point <- paste0(
  "wrapper_text <- sub(absence_guard, \"\", wrapper_text, fixed = TRUE)\n\n",
  "temporary_wrapper <- tempfile("
)
insertion <- paste0(
  "wrapper_text <- sub(absence_guard, \"\", wrapper_text, fixed = TRUE)\n\n",
  "unsafe_link_target <- paste0(\n",
  "  \"  \\\"  !any(nzchar(build_now$link_target)) &&\\\\n\\\",\"\n",
  ")\n",
  "safe_link_target <- paste0(\n",
  "  \"  \\\"  !any(nzchar(build_now$link_target[!is.na(build_now$link_target)])) &&\\\\n\\\",\"\n",
  ")\n",
  "stopifnot(sum(grepl(unsafe_link_target, wrapper_text, fixed = TRUE)) == 1L)\n",
  "wrapper_text <- sub(\n",
  "  unsafe_link_target, safe_link_target, wrapper_text, fixed = TRUE\n",
  ")\n\n",
  "temporary_wrapper <- tempfile("
)
stopifnot(sum(grepl(insertion_point, wrapper_text, fixed = TRUE)) == 1L)
wrapper_text <- sub(insertion_point, insertion, wrapper_text, fixed = TRUE)

temporary_final_wrapper <- tempfile(
  "report018-sensitivity-order62-final-import-",
  tmpdir = tempdir(),
  fileext = ".R"
)
writeLines(wrapper_text, temporary_final_wrapper, useBytes = TRUE)
on.exit(unlink(temporary_final_wrapper, force = TRUE), add = TRUE)
invisible(parse(file = temporary_final_wrapper))

semantic_dir <- normalizePath(
  Sys.getenv("SENSITIVITY_SEMANTIC_DIR"),
  winslash = "/",
  mustWork = TRUE
)
output <- suppressWarnings(system2(
  file.path(R.home("bin"), "Rscript"),
  c("--vanilla", shQuote(temporary_final_wrapper), phase),
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
  paste0("completion_checker_", phase, "_output.txt")
)
writeLines(enc2utf8(output), output_path, useBytes = TRUE)
stopifnot(
  status == 0L,
  any(grepl(
    paste0(
      "REPORT018_SENSITIVITY_ORDER62_FINAL_WRAPPER=PASS phase=",
      phase
    ),
    output,
    fixed = TRUE
  )),
  identical(sealed_sha, sha256_file(sealed_final_wrapper))
)

cat(sprintf(
  paste0(
    "REPORT018_SENSITIVITY_ORDER62_COMPLETION=PASS phase=%s ",
    "zero_symlinks=TRUE sealed=%s R=%s\n"
  ),
  phase,
  sealed_sha,
  as.character(getRversion())
))
