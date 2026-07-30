# Run the deterministic lockfile-versus-library environment audit.

options(warn = 2)

arguments <- commandArgs(trailingOnly = TRUE)
project <- if (length(arguments) >= 1L) arguments[[1L]] else getwd()
project <- normalizePath(project, winslash = "/", mustWork = TRUE)

source(file.path(
  project,
  "scripts",
  "environment",
  "environment_audit.R"
))

library <- renv::paths$library(project = project)
result <- run_environment_audit(
  project = project,
  library = library
)

failed <- result$summary$check[result$summary$status == "FAIL"]
if (length(failed) > 0L) {
  stop(
    sprintf(
      "Environment audit failed: %s",
      paste(failed, collapse = ", ")
    ),
    call. = FALSE
  )
}

message("Deterministic environment audit passed; lock snapshot remains gated")
