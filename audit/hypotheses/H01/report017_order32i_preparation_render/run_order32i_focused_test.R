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
  "audit/hypotheses/H01/report017_order32i_preparation_render"
)
test_path <- "tests/hypotheses/H01/test_h01_preparation_report.R"
project_library <- file.path(
  root,
  "renv/library/macos/R-4.6/aarch64-apple-darwin23"
)

started <- Sys.time()
output <- system2(
  file.path(R.home("bin"), "Rscript"),
  c("--vanilla", test_path),
  stdout = TRUE,
  stderr = TRUE,
  env = c(
    paste0("NATHEALTH_PROJECT_ROOT=", root),
    "R_PROFILE_USER=/dev/null",
    paste0("R_LIBS_USER=", project_library)
  )
)
ended <- Sys.time()
status <- attr(output, "status")
if (is.null(status)) status <- 0L

utils::write.csv(
  data.frame(
    test = test_path,
    r_version = as.character(getRversion()),
    started_utc = format(started, "%Y-%m-%dT%H:%M:%OS6Z", tz = "UTC"),
    ended_utc = format(ended, "%Y-%m-%dT%H:%M:%OS6Z", tz = "UTC"),
    elapsed_seconds = as.numeric(difftime(ended, started, units = "secs")),
    exit_status = as.integer(status),
    stringsAsFactors = FALSE
  ),
  file.path(evidence_dir, "order32i_focused_test_summary.csv"),
  row.names = FALSE,
  na = "",
  fileEncoding = "UTF-8"
)
writeLines(
  enc2utf8(output),
  file.path(evidence_dir, "order32i_focused_test_output.txt"),
  useBytes = TRUE
)

cat(paste(output, collapse = "\n"), "\n", sep = "")
cat(sprintf(
  "focused_test_exit=%d elapsed_seconds=%.3f\n",
  as.integer(status),
  as.numeric(difftime(ended, started, units = "secs"))
))
quit(save = "no", status = as.integer(status))
