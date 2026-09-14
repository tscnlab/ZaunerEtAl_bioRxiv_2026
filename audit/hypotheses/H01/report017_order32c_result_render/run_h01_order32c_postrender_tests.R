#!/usr/bin/env Rscript

stopifnot(identical(as.character(getRversion()), "4.6.1"))
root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
setwd(root)
evidence_dir <- file.path(
  root,
  "audit/hypotheses/H01/report017_order32c_result_render"
)

tests <- data.frame(
  test_id = c(
    "h01_reporting_fresh_render",
    "navigation_contract",
    "reader_link_contract",
    "country_code_contract",
    "h01_deviation_link_contract"
  ),
  path = c(
    "tests/hypotheses/H01/test_h01_reporting_inputs.R",
    "tests/report_harmonization/test_navigation_contract.R",
    "tests/report_harmonization/test_reader_links.R",
    "tests/report_harmonization/test_country_coded_site_names.R",
    "tests/hypotheses/H01/test_h01_report016_deviation_reconciliation.R"
  ),
  stringsAsFactors = FALSE
)

results <- lapply(seq_len(nrow(tests)), function(index) {
  started <- Sys.time()
  output <- system2(
    file.path(R.home("bin"), "Rscript"),
    c("--vanilla", tests$path[[index]]),
    stdout = TRUE,
    stderr = TRUE,
    env = paste0("NATHEALTH_PROJECT_ROOT=", root)
  )
  ended <- Sys.time()
  status <- attr(output, "status")
  if (is.null(status)) status <- 0L
  data.frame(
    test_id = tests$test_id[[index]],
    command = paste(
      paste0("NATHEALTH_PROJECT_ROOT=", root),
      shQuote(file.path(R.home("bin"), "Rscript")),
      "--vanilla",
      tests$path[[index]]
    ),
    start_utc = format(started, "%Y-%m-%dT%H:%M:%OS6Z", tz = "UTC"),
    end_utc = format(ended, "%Y-%m-%dT%H:%M:%OS6Z", tz = "UTC"),
    elapsed_seconds = as.numeric(difftime(ended, started, units = "secs")),
    exit_status = as.integer(status),
    output = paste(output, collapse = "\n"),
    stringsAsFactors = FALSE
  )
})
results <- do.call(rbind, results)
utils::write.csv(
  results,
  file.path(evidence_dir, "postrender_test_results.csv"),
  row.names = FALSE,
  na = "",
  fileEncoding = "UTF-8"
)

for (index in seq_len(nrow(results))) {
  cat(sprintf(
    "%s exit=%d elapsed=%.3f output=%s\n",
    results$test_id[[index]],
    results$exit_status[[index]],
    results$elapsed_seconds[[index]],
    gsub("[\r\n]+", " | ", results$output[[index]])
  ))
}

if (any(results$exit_status != 0L)) {
  quit(save = "no", status = 1L)
}

