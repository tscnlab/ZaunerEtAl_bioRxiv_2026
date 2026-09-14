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
output_dir <- paste0(
  "audit/report_harmonization/",
  "report018_final_corpus_integration/structural_tests"
)
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

sha256_file <- function(path) {
  connection <- file(path, open = "rb")
  on.exit(close(connection), add = TRUE)
  paste0(openssl::sha256(connection))
}

tests <- list(
  reader_links = c("tests/report_harmonization/test_reader_links.R"),
  country_coded_sites = c(
    "tests/report_harmonization/test_country_coded_site_names.R"
  ),
  phase4_gt_source = c(
    "tests/report_harmonization/test_phase4_gt_source_contract.R"
  ),
  phase4_gt_render_strict = c(
    "tests/report_harmonization/test_phase4_gt_render_contract.R",
    "--strict"
  ),
  phase4_gt_table_strict = c(
    "tests/report_harmonization/test_gt_table_contract.R",
    "--strict"
  ),
  h06_daily_gt_source = c(
    "tests/report_harmonization/test_h06_daily_gt_source_contract.R"
  ),
  descriptives_render = c(
    "tests/report_harmonization/test_descriptives_render.R"
  ),
  preregistration_deviations = c(
    "tests/report_harmonization/test_preregistration_deviations.R"
  ),
  preparation_source_only = c(
    "tests/report_harmonization/test_preparation_source_only_harmonization.R"
  )
)

rscript <- file.path(R.home("bin"), "Rscript")
runs <- list()
for (label in names(tests)) {
  arguments <- c("--vanilla", tests[[label]])
  output <- suppressWarnings(system2(
    rscript,
    arguments,
    stdout = TRUE,
    stderr = TRUE,
    env = c("RENV_CONFIG_AUTOLOADER_ENABLED=FALSE")
  ))
  status <- attr(output, "status")
  if (is.null(status)) status <- 0L
  output_path <- file.path(output_dir, paste0(label, "_output.txt"))
  writeLines(enc2utf8(output), output_path, useBytes = TRUE)
  runs[[length(runs) + 1L]] <- data.frame(
    label = label,
    command = paste(c("Rscript --vanilla", tests[[label]]), collapse = " "),
    exit_status = as.integer(status),
    output_sha256 = sha256_file(output_path),
    pass = identical(as.integer(status), 0L),
    stringsAsFactors = FALSE
  )
}

runs_frame <- do.call(rbind, runs)
readr::write_csv(
  runs_frame,
  file.path(output_dir, "structural_test_runs.csv")
)
stopifnot(nrow(runs_frame) == 9L, all(runs_frame$pass))

cat(sprintf(
  "REPORT018_FINAL_CORPUS_STRUCTURAL_TESTS=PASS tests=%d/%d R=%s\n",
  sum(runs_frame$pass),
  nrow(runs_frame),
  as.character(getRversion())
))
