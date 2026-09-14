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
  "audit/hypotheses/H01/report017_order32k_companion_acceptance"
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
  deviations = paste0(
    "tests/report_harmonization/",
    "test_preregistration_deviations.R"
  ),
  global_country_sites = paste0(
    "tests/report_harmonization/",
    "test_country_coded_site_names.R"
  )
)
stopifnot(all(file.exists(tests)))

results <- vector("list", length(tests))
names(results) <- names(tests)
outputs <- vector("list", length(tests))
names(outputs) <- names(tests)
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
  outputs[[index]] <- output
  writeLines(
    enc2utf8(output),
    file.path(evidence_dir, paste0("order32k_test_", names(tests)[[index]], ".log")),
    useBytes = TRUE
  )
  expected_status <- if (names(tests)[[index]] == "global_country_sites") {
    1L
  } else {
    0L
  }
  results[[index]] <- data.frame(
    test = names(tests)[[index]],
    path = tests[[index]],
    status = status,
    expected_status = expected_status,
    elapsed_seconds = elapsed,
    last_output = if (length(output)) tail(output, 1L) else "",
    stringsAsFactors = FALSE
  )
}
results <- do.call(rbind, results)

country_output <- outputs$global_country_sites
country_bullets <- country_output[grepl("^- ", country_output)]
expected_bullets <- c(
  "- notebooks/hypotheses/H04.qmd:886 -> use Delft (NL)",
  paste0(
    "- audit/hypotheses/H04/H04_analysis_preparation.qmd:914 ",
    "-> use Munich (DE)"
  )
)
stopifnot(
  identical(results$status[results$test == "global_country_sites"], 1L),
  identical(country_bullets, expected_bullets),
  all(results$status == results$expected_status)
)
country_findings <- data.frame(
  path = c(
    "notebooks/hypotheses/H04.qmd",
    "audit/hypotheses/H04/H04_analysis_preparation.qmd"
  ),
  line = c(886L, 914L),
  bare_name = c("Delft", "Munich"),
  required_display = c("Delft (NL)", "Munich (DE)"),
  scope = "H04_ONLY_SOURCE_WRAP",
  stringsAsFactors = FALSE
)
write.csv(
  country_findings,
  file.path(evidence_dir, "order32k_h04_global_country_findings.csv"),
  row.names = FALSE,
  na = ""
)
results$contract_pass <- results$status == results$expected_status
write.csv(
  results,
  file.path(evidence_dir, "order32k_test_results.csv"),
  row.names = FALSE,
  na = ""
)
cat(sprintf(
  "checks=%d/%d contract-pass; ordinary_pass=%d expected_country_failure=%d\n",
  sum(results$contract_pass),
  nrow(results),
  sum(results$status == 0L),
  sum(results$test == "global_country_sites" & results$status == 1L)
))
