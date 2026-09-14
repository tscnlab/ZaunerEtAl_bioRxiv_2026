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
  "audit/hypotheses/H01/report017_order32j_no_render_finalization"
)
tests <- c(
  preparation = "tests/hypotheses/H01/test_h01_preparation_report.R",
  reporting = "tests/hypotheses/H01/test_h01_reporting_inputs.R",
  report016 = paste0(
    "tests/hypotheses/H01/",
    "test_h01_report016_deviation_reconciliation.R"
  ),
  navigation = "tests/report_harmonization/test_navigation_contract.R",
  reader_links = "tests/report_harmonization/test_reader_links.R",
  country_sites = paste0(
    "tests/report_harmonization/",
    "test_country_coded_site_names.R"
  ),
  deviations = paste0(
    "tests/report_harmonization/",
    "test_preregistration_deviations.R"
  )
)
stopifnot(all(file.exists(tests)))

results <- vector("list", length(tests))
names(results) <- names(tests)
for (index in seq_along(tests)) {
  started <- Sys.time()
  output <- system2(
    file.path(R.home("bin"), "Rscript"),
    c("--vanilla", tests[[index]]),
    stdout = TRUE,
    stderr = TRUE,
    env = c(
      "R_PROFILE_USER=/dev/null",
      paste0("R_LIBS_USER=", Sys.getenv("R_LIBS_USER")),
      paste0("NATHEALTH_PROJECT_ROOT=", root)
    )
  )
  status <- attr(output, "status")
  if (is.null(status)) {
    status <- 0L
  }
  elapsed <- as.numeric(difftime(Sys.time(), started, units = "secs"))
  writeLines(
    enc2utf8(output),
    file.path(evidence_dir, paste0("order32j_test_", names(tests)[[index]], ".log")),
    useBytes = TRUE
  )
  results[[index]] <- data.frame(
    test = names(tests)[[index]],
    path = tests[[index]],
    status = status,
    elapsed_seconds = elapsed,
    last_output = if (length(output)) tail(output, 1L) else "",
    stringsAsFactors = FALSE
  )
}
results <- do.call(rbind, results)
write.csv(
  results,
  file.path(evidence_dir, "order32j_stopped_test_results.csv"),
  row.names = FALSE,
  na = ""
)
cat(sprintf(
  "stopped_checks complete: %d pass, %d fail\n",
  sum(results$status == 0L),
  sum(results$status != 0L)
))
