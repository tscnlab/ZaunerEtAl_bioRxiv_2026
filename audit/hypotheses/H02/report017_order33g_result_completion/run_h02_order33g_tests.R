stopifnot(identical(as.character(getRversion()), "4.6.1"))

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
setwd(root)

evidence_dir <- file.path(
  root,
  "audit/hypotheses/H02/report017_order33g_result_completion"
)
rscript <- file.path(R.home("bin"), "Rscript")

tests <- data.frame(
  test_id = c("reader_complete", "paired_placement"),
  path = c(
    "tests/hypotheses/H02/test_h02_reader_report.R",
    "tests/hypotheses/H02/test_h02_paired_placement_display.R"
  ),
  stringsAsFactors = FALSE
)

run_one <- function(test_id, path) {
  start <- Sys.time()
  output <- system2(
    rscript,
    c("--vanilla", path),
    stdout = TRUE,
    stderr = TRUE,
    env = paste0("NATHEALTH_PROJECT_ROOT=", root)
  )
  end <- Sys.time()
  status <- attr(output, "status")
  if (is.null(status)) status <- 0L
  data.frame(
    test_id = test_id,
    command = paste("Rscript --vanilla", path),
    start_utc = format(start, "%Y-%m-%dT%H:%M:%OS6Z", tz = "UTC"),
    end_utc = format(end, "%Y-%m-%dT%H:%M:%OS6Z", tz = "UTC"),
    elapsed_seconds = as.numeric(difftime(end, start, units = "secs")),
    exit_status = as.integer(status),
    output = paste(output, collapse = "\n"),
    stringsAsFactors = FALSE
  )
}

results <- do.call(
  rbind,
  Map(run_one, tests$test_id, tests$path)
)

utils::write.csv(
  results,
  file.path(evidence_dir, "project_test_results.csv"),
  row.names = FALSE,
  na = "",
  fileEncoding = "UTF-8"
)

stopifnot(
  identical(results$test_id, c("reader_complete", "paired_placement")),
  all(results$exit_status == 0L),
  grepl("All H02 reader-report tests passed", results$output[[1L]], fixed = TRUE),
  grepl(
    "All H02 paired-placement display tests passed",
    results$output[[2L]],
    fixed = TRUE
  )
)

cat(sprintf(
  "H02_ORDER33G_TESTS=PASS reader=%.3fs paired=%.3fs preparation_test_executed=FALSE\n",
  results$elapsed_seconds[[1L]],
  results$elapsed_seconds[[2L]]
))
