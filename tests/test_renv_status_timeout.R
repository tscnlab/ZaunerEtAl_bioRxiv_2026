options(warn = 2)

project <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
source(file.path(
  project,
  "scripts",
  "environment",
  "renv_status_timeout.R"
))

test_dir <- tempfile("renv-status-timeout-")
dir.create(test_dir, recursive = TRUE)
on.exit(unlink(test_dir, recursive = TRUE, force = TRUE), add = TRUE)

timeout_stdout <- file.path(test_dir, "timeout-stdout.txt")
timeout_stderr <- file.path(test_dir, "timeout-stderr.txt")
timeout_result <- run_process_with_timeout(
  command = file.path(R.home("bin"), "Rscript"),
  args = c(
    "--vanilla",
    "-e",
    "cat('fixture-start\\n'); flush.console(); Sys.sleep(5)"
  ),
  timeout_seconds = 0.2,
  working_directory = project,
  stdout_path = timeout_stdout,
  stderr_path = timeout_stderr,
  environment = c(R_PROFILE_USER = "/dev/null")
)

stopifnot(
  isTRUE(timeout_result$timed_out),
  isTRUE(timeout_result$termination_attempted),
  isTRUE(timeout_result$termination_succeeded),
  !timeout_result$process_alive_after,
  timeout_result$elapsed_seconds < 2,
  timeout_result$exit_status != 0L,
  grepl("fixture-start", paste(readLines(timeout_stdout), collapse = "\n"))
)

success_stdout <- file.path(test_dir, "success-stdout.txt")
success_stderr <- file.path(test_dir, "success-stderr.txt")
success_result <- run_process_with_timeout(
  command = file.path(R.home("bin"), "Rscript"),
  args = c("--vanilla", "-e", "cat('fixture-complete\\n')"),
  timeout_seconds = 2,
  working_directory = project,
  stdout_path = success_stdout,
  stderr_path = success_stderr,
  environment = c(R_PROFILE_USER = "/dev/null")
)

stopifnot(
  !success_result$timed_out,
  !success_result$termination_attempted,
  is.na(success_result$termination_succeeded),
  !success_result$process_alive_after,
  identical(success_result$exit_status, 0L),
  grepl(
    "fixture-complete",
    paste(readLines(success_stdout), collapse = "\n")
  )
)

expression <- renv_status_expression()
stopifnot(
  grepl("renv::status", expression, fixed = TRUE),
  grepl("library = libraries", expression, fixed = TRUE),
  grepl("sources = sources", expression, fixed = TRUE),
  grepl("cache = FALSE", expression, fixed = TRUE)
)

message("renv status timeout tests passed")
