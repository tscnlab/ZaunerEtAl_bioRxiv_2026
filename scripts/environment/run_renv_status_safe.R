# Run the final renv status check in a timeout-controlled child R process.

options(warn = 2)

arguments <- commandArgs(trailingOnly = TRUE)
project <- if (length(arguments) >= 1L) arguments[[1L]] else getwd()
timeout_seconds <- if (length(arguments) >= 2L) {
  as.numeric(arguments[[2L]])
} else {
  300
}
sources <- if (length(arguments) >= 3L) {
  identical(tolower(arguments[[3L]]), "true")
} else {
  TRUE
}
project <- normalizePath(project, winslash = "/", mustWork = TRUE)

source(file.path(
  project,
  "scripts",
  "environment",
  "renv_status_timeout.R"
))

metadata <- run_renv_status_with_timeout(
  project = project,
  library = renv::paths$library(project = project),
  timeout_seconds = timeout_seconds,
  sources = sources
)

if (isTRUE(metadata$timed_out)) {
  stop(
    sprintf(
      "renv status exceeded %.1f seconds and was terminated",
      metadata$timeout_seconds
    ),
    call. = FALSE
  )
}
if (!identical(metadata$exit_status, 0L)) {
  stop(
    sprintf(
      "renv status completed with exit status %d; inspect retained output",
      metadata$exit_status
    ),
    call. = FALSE
  )
}

message("Timeout-controlled renv status passed")
