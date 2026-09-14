# Update renv.lock from the verified R 4.6.1 project library.

options(warn = 2)

project <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
if (!identical(as.character(getRversion()), "4.6.1")) {
  stop(
    sprintf(
      "The lockfile snapshot requires R 4.6.1; found R %s",
      as.character(getRversion())
    ),
    call. = FALSE
  )
}

source(file.path(
  project,
  "scripts",
  "environment",
  "environment_audit.R"
))

project_library <- renv::paths$library(project = project)
libraries <- unique(c(project_library, .Library.site, .Library))
missing_libraries <- libraries[!dir.exists(libraries)]
if (length(missing_libraries) > 0L) {
  stop(
    sprintf(
      "Required R library path(s) not found: %s",
      paste(missing_libraries, collapse = ", ")
    ),
    call. = FALSE
  )
}

scan <- scan_project_dependencies(project)
policy <- runtime_dependency_policy()
base_packages <- rownames(
  utils::installed.packages(priority = "base", noCache = TRUE)
)
snapshot_packages <- sort(unique(c(
  setdiff(scan$packages$package, base_packages),
  policy$package[policy$explicit_lock_expected]
)))

installed <- utils::installed.packages(
  lib.loc = libraries,
  noCache = TRUE
)
missing_packages <- setdiff(snapshot_packages, installed[, "Package"])
if (length(missing_packages) > 0L) {
  stop(
    sprintf(
      "Required package(s) are not installed: %s",
      paste(missing_packages, collapse = ", ")
    ),
    call. = FALSE
  )
}

lockfile <- file.path(project, "renv.lock")
old_lock <- read_lock_metadata(lockfile)
old_hash <- unname(tools::md5sum(lockfile))
repositories <- c(CRAN = "https://cloud.r-project.org")

started <- proc.time()[["elapsed"]]
renv::snapshot(
  project = project,
  library = libraries,
  lockfile = lockfile,
  packages = snapshot_packages,
  repos = repositories,
  prompt = FALSE,
  update = TRUE,
  force = FALSE
)
elapsed <- proc.time()[["elapsed"]] - started

new_lock <- read_lock_metadata(lockfile)
new_hash <- unname(tools::md5sum(lockfile))
if (!identical(new_lock$r_version, "4.6.1")) {
  stop("The updated lockfile does not record R 4.6.1", call. = FALSE)
}

message(sprintf(
  paste(
    "Updated renv.lock in %.3f seconds:",
    "%d requested packages, %d -> %d records, MD5 %s -> %s"
  ),
  elapsed,
  length(snapshot_packages),
  nrow(old_lock$packages),
  nrow(new_lock$packages),
  old_hash,
  new_hash
))
