# Run one child process with a hard wall-clock timeout and retained metadata.

validate_timeout_inputs <- function(
  command,
  args,
  timeout_seconds,
  working_directory,
  stdout_path,
  stderr_path
) {
  if (!is.character(command) || length(command) != 1L || !nzchar(command)) {
    stop("`command` must be one non-empty path", call. = FALSE)
  }
  if (!file.exists(command)) {
    stop(sprintf("Command not found: %s", command), call. = FALSE)
  }
  if (!is.character(args) || anyNA(args)) {
    stop(
      "`args` must be a character vector without missing values",
      call. = FALSE
    )
  }
  if (
    !is.numeric(timeout_seconds) ||
      length(timeout_seconds) != 1L ||
      !is.finite(timeout_seconds) ||
      timeout_seconds <= 0
  ) {
    stop("`timeout_seconds` must be one positive finite number", call. = FALSE)
  }
  if (!dir.exists(working_directory)) {
    stop(
      sprintf("Working directory not found: %s", working_directory),
      call. = FALSE
    )
  }
  if (
    !is.character(stdout_path) ||
      length(stdout_path) != 1L ||
      !nzchar(stdout_path) ||
      !is.character(stderr_path) ||
      length(stderr_path) != 1L ||
      !nzchar(stderr_path)
  ) {
    stop(
      "`stdout_path` and `stderr_path` must be non-empty paths",
      call. = FALSE
    )
  }
}

run_process_with_timeout <- function(
  command,
  args,
  timeout_seconds,
  working_directory,
  stdout_path,
  stderr_path,
  environment = character()
) {
  validate_timeout_inputs(
    command = command,
    args = args,
    timeout_seconds = timeout_seconds,
    working_directory = working_directory,
    stdout_path = stdout_path,
    stderr_path = stderr_path
  )
  if (!requireNamespace("processx", quietly = TRUE)) {
    stop(
      "Package `processx` is required for the status timeout",
      call. = FALSE
    )
  }
  if (!is.character(environment) || anyNA(environment)) {
    stop(
      "`environment` must be a named character vector without missing values",
      call. = FALSE
    )
  }

  dir.create(dirname(stdout_path), recursive = TRUE, showWarnings = FALSE)
  dir.create(dirname(stderr_path), recursive = TRUE, showWarnings = FALSE)
  file.create(stdout_path)
  file.create(stderr_path)

  started <- Sys.time()
  process <- processx::process$new(
    command = command,
    args = args,
    wd = working_directory,
    stdout = stdout_path,
    stderr = stderr_path,
    env = environment,
    cleanup_tree = FALSE
  )

  invisible(process$wait(as.integer(ceiling(timeout_seconds * 1000))))
  timed_out <- process$is_alive()
  termination_attempted <- timed_out
  termination_succeeded <- NA
  termination_error <- ""

  if (timed_out) {
    termination <- tryCatch(
      list(
        succeeded = isTRUE(process$kill(grace = 0.2)),
        error = ""
      ),
      error = function(error) {
        list(
          succeeded = FALSE,
          error = conditionMessage(error)
        )
      }
    )
    termination_succeeded <- termination$succeeded
    termination_error <- termination$error
    invisible(process$wait(5000L))
    termination_succeeded <- termination_succeeded && !process$is_alive()
  }

  finished <- Sys.time()
  alive_after <- process$is_alive()
  exit_status <- process$get_exit_status()
  if (is.null(exit_status)) {
    exit_status <- NA_integer_
  }

  metadata <- data.frame(
    command = command,
    argument_count = length(args),
    working_directory = normalizePath(
      working_directory,
      winslash = "/",
      mustWork = TRUE
    ),
    started_utc = format(started, tz = "UTC", usetz = TRUE),
    finished_utc = format(finished, tz = "UTC", usetz = TRUE),
    elapsed_seconds = as.numeric(difftime(
      finished,
      started,
      units = "secs"
    )),
    timeout_seconds = timeout_seconds,
    timed_out = timed_out,
    termination_attempted = termination_attempted,
    termination_succeeded = termination_succeeded,
    termination_error = termination_error,
    process_alive_after = alive_after,
    exit_status = as.integer(exit_status),
    stdout_path = normalizePath(
      stdout_path,
      winslash = "/",
      mustWork = TRUE
    ),
    stderr_path = normalizePath(
      stderr_path,
      winslash = "/",
      mustWork = TRUE
    ),
    stringsAsFactors = FALSE
  )

  metadata
}

renv_status_expression <- function() {
  paste(
    c(
      "options(warn = 1)",
      "project <- Sys.getenv('NH_RENV_STATUS_PROJECT')",
      paste(
        "libraries <- strsplit(",
        "Sys.getenv('NH_RENV_STATUS_LIBRARIES'),",
        ".Platform$path.sep, fixed = TRUE)[[1L]]"
      ),
      "lockfile <- Sys.getenv('NH_RENV_STATUS_LOCKFILE')",
      paste(
        "sources <- identical(",
        "Sys.getenv('NH_RENV_STATUS_SOURCES'),",
        "'true')"
      ),
      paste(
        "result <- renv::status(",
        "project = project,",
        "library = libraries,",
        "lockfile = lockfile,",
        "sources = sources,",
        "cache = FALSE)"
      ),
      paste(
        "cat(sprintf(",
        "'\\nRENV_STATUS_SYNCHRONIZED=%s\\n',",
        "isTRUE(result$synchronized)))"
      ),
      "quit(status = if (isTRUE(result$synchronized)) 0L else 2L)"
    ),
    collapse = "; "
  )
}

run_renv_status_with_timeout <- function(
  project,
  library,
  lockfile = file.path(project, "renv.lock"),
  output_dir = file.path(
    project,
    "audit",
    "environment",
    "renv-status"
  ),
  timeout_seconds = 300,
  sources = TRUE
) {
  if (!is.logical(sources) || length(sources) != 1L || is.na(sources)) {
    stop("`sources` must be `TRUE` or `FALSE`", call. = FALSE)
  }

  project <- normalizePath(project, winslash = "/", mustWork = TRUE)
  library <- normalizePath(library, winslash = "/", mustWork = TRUE)
  lockfile <- normalizePath(lockfile, winslash = "/", mustWork = TRUE)
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

  stdout_path <- file.path(output_dir, "renv-status-stdout.txt")
  stderr_path <- file.path(output_dir, "renv-status-stderr.txt")
  metadata_path <- file.path(output_dir, "renv-status-metadata.csv")
  sandbox_path <- file.path(tempdir(), "nathealth-renv-status-sandbox")
  dir.create(sandbox_path, recursive = TRUE, showWarnings = FALSE)
  libraries <- unique(c(library, .Library.site, .Library))

  environment <- c(
    R_PROFILE_USER = "/dev/null",
    R_LIBS_USER = library,
    RENV_CONFIG_CACHE_ENABLED = "FALSE",
    RENV_PATHS_SANDBOX = sandbox_path,
    TAR = "internal",
    NH_RENV_STATUS_PROJECT = project,
    NH_RENV_STATUS_LIBRARIES = paste(
      libraries,
      collapse = .Platform$path.sep
    ),
    NH_RENV_STATUS_LOCKFILE = lockfile,
    NH_RENV_STATUS_SOURCES = if (sources) "true" else "false"
  )

  metadata <- run_process_with_timeout(
    command = file.path(R.home("bin"), "Rscript"),
    args = c("--vanilla", "-e", renv_status_expression()),
    timeout_seconds = timeout_seconds,
    working_directory = project,
    stdout_path = stdout_path,
    stderr_path = stderr_path,
    environment = environment
  )
  metadata$status_call <- sprintf(
    paste(
      "renv::status(project=<project>, library=<project-library>,",
      "lockfile=<renv.lock>, sources=%s, cache=FALSE)"
    ),
    sources
  )
  metadata$lockfile <- lockfile
  metadata$libraries <- paste(libraries, collapse = ";")
  metadata$sources <- sources
  metadata$cache <- FALSE

  utils::write.csv(
    metadata,
    metadata_path,
    row.names = FALSE,
    na = ""
  )
  if (metadata$process_alive_after) {
    stop(
      "The timed process remained alive after the termination attempt",
      call. = FALSE
    )
  }
  metadata
}
