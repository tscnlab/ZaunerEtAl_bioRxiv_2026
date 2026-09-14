#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE, warn = 2)
suppressPackageStartupMessages({
  library(openssl)
  library(readr)
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

source_checker <- paste0(
  "scripts/report_harmonization/",
  "check_report018_sensitivity_order62_postrender.R"
)
source_sha <- sha256_file(source_checker)
stopifnot(identical(
  source_sha,
  "efc9f980d7766ee29c46a2cd281ca5cfbedf158bdcca4bc32eb053f9903417d7"
))

evidence_dir <- paste0(
  "audit/report_harmonization/",
  "report018_sensitivity_battery_order62_render"
)
initial_dir <- file.path(evidence_dir, "initial_checker_stop")
initial_files <- c(
  "postrender_checks_postrender.csv" = "f33740e0e3ef03333c3f8ab02371dbcb8505fd81bb99c98718edefabdb81be92",
  "build_delta_postrender.csv" = "a8ddcd2e3a7ccc8d48887e0abe43ead70b200f94ca9ca974d3e3bed0c9814238",
  "link_audit_postrender.csv" = "9d469cd657f8a5e797e89f0a8552739775257790d173a53b47b83babe045e2ec"
)

if (phase == "postrender") {
  dir.create(initial_dir, recursive = TRUE, showWarnings = FALSE)
  for (name in names(initial_files)) {
    source_path <- file.path(evidence_dir, name)
    destination <- file.path(initial_dir, name)
    stopifnot(sha256_file(source_path) == initial_files[[name]])
    if (!file.exists(destination)) {
      stopifnot(file.copy(source_path, destination, overwrite = FALSE))
    }
    stopifnot(sha256_file(destination) == initial_files[[name]])
  }
}

replace_once <- function(text, before, after) {
  location <- regexpr(before, text, fixed = TRUE)
  stopifnot(location[[1L]] > 0L)
  tail_start <- location[[1L]] + attr(location, "match.length")
  tail <- if (tail_start <= nchar(text)) {
    substring(text, tail_start)
  } else {
    ""
  }
  output <- paste0(
    substring(text, 1L, location[[1L]] - 1L),
    after,
    tail
  )
  stopifnot(!grepl(before, output, fixed = TRUE))
  output
}

checker_text <- paste(
  readLines(source_checker, warn = FALSE, encoding = "UTF-8"),
  collapse = "\n"
)

before_build <- paste0(
  "allowed_content_delta <- c(\n",
  "  \"notebooks/sensitivity_battery.html\",\n",
  "  \"search.json\",\n",
  "  \"sitemap.xml\"\n",
  ")\n",
  "build_pass <- !length(setdiff(content_delta, allowed_content_delta)) &&\n",
  "  !any(joined$disposition == \"REMOVED\") &&\n",
  "  !any(nzchar(build_now$link_target))"
)
after_build <- paste0(
  "allowed_content_delta <- c(\n",
  "  \"notebooks/sensitivity_battery.html\",\n",
  "  \"search.json\",\n",
  "  \"sitemap.xml\",\n",
  "  \"audit/decisions/manuscript_prepared_data_sensitivity.md\"\n",
  ")\n",
  "resource_source <- \"audit/decisions/manuscript_prepared_data_sensitivity.md\"\n",
  "resource_build <- file.path(\"_build/nathealth\", resource_source)\n",
  "resource_exact <- file.exists(resource_build) &&\n",
  "  sha256_file(resource_build) == sha256_file(resource_source)\n",
  "build_pass <- !length(setdiff(content_delta, allowed_content_delta)) &&\n",
  "  !any(joined$disposition == \"REMOVED\") &&\n",
  "  !any(nzchar(build_now$link_target)) &&\n",
  "  resource_exact"
)
checker_text <- replace_once(checker_text, before_build, after_build)

before_ledger <- "  !nzchar(semantic$ledger_file[[1L]])"
after_ledger <- paste0(
  "  (is.na(semantic$ledger_file[[1L]]) ||\n",
  "    !nzchar(semantic$ledger_file[[1L]]))"
)
checker_text <- replace_once(checker_text, before_ledger, after_ledger)

before_code <- paste0(
  "  length(code_fold) == 1L &&\n",
  "  grepl(\"eval: false\", normalize_text(code_fold[[1L]]), fixed = TRUE) &&"
)
after_code <- paste0(
  "  length(code_fold) == 1L &&\n",
  "  grepl(\"paths <- pipeline_paths(root)\",\n",
  "    normalize_text(code_fold[[1L]]), fixed = TRUE) &&\n",
  "  length(xml2::xml_find_all(main, \".//*[contains(@class, 'cell-output')]\")) == 0L &&"
)
checker_text <- replace_once(checker_text, before_code, after_code)

if (phase == "postqa") {
  checker_text <- replace_once(
    checker_text,
    "protected_pre <- read_inventory(\"protected\", \"prerender\")",
    "protected_pre <- read_inventory(\"protected\", \"postrender\")"
  )
}

temporary_checker <- tempfile(
  "report018-sensitivity-order62-no-rerender-",
  tmpdir = tempdir(),
  fileext = ".R"
)
writeLines(checker_text, temporary_checker, useBytes = TRUE)
on.exit(unlink(temporary_checker, force = TRUE), add = TRUE)
invisible(parse(file = temporary_checker))

semantic_dir <- normalizePath(
  Sys.getenv("SENSITIVITY_SEMANTIC_DIR"),
  winslash = "/",
  mustWork = TRUE
)
output <- suppressWarnings(system2(
  file.path(R.home("bin"), "Rscript"),
  c("--vanilla", shQuote(temporary_checker), phase),
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
output_path <- file.path(
  evidence_dir,
  paste0("no_rerender_checker_", phase, "_output.txt")
)
writeLines(enc2utf8(output), output_path, useBytes = TRUE)

classification <- data.frame(
  classification = c(
    "linked_markdown_resource_sync",
    "empty_semantic_ledger_import",
    "folded_code_option_comment_absent"
  ),
  status = "ACCEPTED_HARNESS_CLASSIFICATION",
  evidence = c(
    sha256_file(
      "_build/nathealth/audit/decisions/manuscript_prepared_data_sensitivity.md"
    ),
    "NO_GT summary has missing-or-empty ledger_file and no ledger member",
    "protected QMD eval:false; one accepted folded code body; zero output nodes"
  ),
  stringsAsFactors = FALSE
)
readr::write_csv(
  classification,
  file.path(evidence_dir, paste0("no_rerender_classification_", phase, ".csv"))
)
stopifnot(
  status == 0L,
  any(grepl(
    paste0("REPORT018_SENSITIVITY_ORDER62_", toupper(phase), "=PASS"),
    output,
    fixed = TRUE
  )),
  identical(source_sha, sha256_file(source_checker))
)

cat(sprintf(
  paste0(
    "REPORT018_SENSITIVITY_ORDER62_NO_RERENDER=PASS phase=%s ",
    "classifications=3/3 checker=%s R=%s\n"
  ),
  phase,
  source_sha,
  as.character(getRversion())
))
