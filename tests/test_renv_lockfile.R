options(warn = 2)

project <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
source(file.path(
  project,
  "scripts",
  "environment",
  "environment_audit.R"
))

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop(
    sprintf("Expected R 4.6.1; found R %s", as.character(getRversion())),
    call. = FALSE
  )
}

lockfile <- file.path(project, "renv.lock")
lock_object <- renv::lockfile_read(lockfile)
stopifnot(
  inherits(lock_object, "renv_lockfile"),
  identical(lock_object$R$Version, "4.6.1")
)

audit <- build_dependency_reconciliation(
  project = project,
  library = renv::paths$library(project = project),
  lockfile = lockfile
)
reconciliation <- audit$reconciliation
expected <- reconciliation$lock_expected & !reconciliation$base_package

stopifnot(
  audit$scan$elapsed_seconds <= 15,
  all(reconciliation$installed[expected]),
  all(reconciliation$locked[expected]),
  all(reconciliation$version_equal[expected]),
  !any(reconciliation$reconciliation_status %in% c(
    "required_missing_from_library",
    "locked_missing_from_library",
    "version_mismatch_pending_snapshot",
    "missing_from_lock_pending_snapshot"
  ))
)

explicit_packages <- c("see", "DHARMa", "shiny")
explicit_rows <- reconciliation[
  match(explicit_packages, reconciliation$package),
]
stopifnot(
  identical(explicit_rows$package, explicit_packages),
  all(explicit_rows$installed),
  all(explicit_rows$locked),
  all(explicit_rows$version_equal)
)

matrix_row <- reconciliation[reconciliation$package == "Matrix", ]
sf_row <- reconciliation[reconciliation$package == "sf", ]
stopifnot(
  nrow(matrix_row) == 1L,
  nrow(sf_row) == 1L,
  matrix_row$lock_version == "1.7-6",
  sf_row$lock_version == "1.1-2",
  matrix_row$version_equal,
  sf_row$version_equal,
  utils::packageVersion("LightLogR") >= "0.10.3"
)

message("R 4.6.1 renv lockfile tests passed")
