options(warn = 2)

project <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
source(file.path(
  project,
  "scripts",
  "environment",
  "environment_audit.R"
))

lockfile <- file.path(project, "renv.lock")
lock_hash_before <- unname(tools::md5sum(lockfile))
output_dir <- tempfile("environment-audit-")
on.exit(unlink(output_dir, recursive = TRUE, force = TRUE), add = TRUE)

result <- run_environment_audit(
  project = project,
  library = renv::paths$library(project = project),
  output_dir = output_dir,
  max_scan_seconds = 15
)
lock_hash_after <- unname(tools::md5sum(lockfile))

stopifnot(
  identical(lock_hash_before, lock_hash_after),
  result$audit$scan$elapsed_seconds <= 15,
  nrow(result$audit$scan$dependencies) > 0L,
  length(unique(result$audit$scan$dependencies$Package)) > 0L
)

reconciliation <- result$audit$reconciliation
required_columns <- c(
  "package",
  "static_detected",
  "installed_version",
  "installed_library",
  "lock_version",
  "lock_source",
  "lock_repository",
  "installed_repository",
  "dependency_policy",
  "reconciliation_status",
  "source_metadata_status"
)
stopifnot(all(required_columns %in% names(reconciliation)))

see_row <- reconciliation[reconciliation$package == "see", ]
dharma_row <- reconciliation[reconciliation$package == "DHARMa", ]
shiny_row <- reconciliation[reconciliation$package == "shiny", ]
matrix_row <- reconciliation[reconciliation$package == "Matrix", ]
sf_row <- reconciliation[reconciliation$package == "sf", ]

stopifnot(
  nrow(see_row) == 1L,
  !see_row$static_detected,
  see_row$runtime_required,
  see_row$installed,
  !see_row$locked,
  see_row$reconciliation_status == "missing_from_lock_pending_snapshot",
  nrow(dharma_row) == 1L,
  !dharma_row$static_detected,
  dharma_row$runtime_required,
  dharma_row$installed,
  !dharma_row$locked,
  dharma_row$reconciliation_status == "missing_from_lock_pending_snapshot",
  nrow(shiny_row) == 1L,
  shiny_row$static_detected,
  shiny_row$static_source_count == 11L,
  !shiny_row$runtime_required,
  isTRUE(shiny_row$scanner_false_positive_confirmed),
  shiny_row$installed,
  !shiny_row$locked,
  matrix_row$reconciliation_status == "version_mismatch_pending_snapshot",
  sf_row$reconciliation_status == "version_mismatch_pending_snapshot"
)

stopifnot(
  !any(result$summary$status == "FAIL"),
  identical(
    result$summary$status[
      result$summary$check == "lock_r_version"
    ],
    "PENDING_LOCK_SNAPSHOT"
  ),
  identical(
    result$summary$status[
      result$summary$check == "dependency_scan_seconds"
    ],
    "PASS"
  )
)

expected_outputs <- c(
  "dependency-reconciliation.csv",
  "environment-summary.csv",
  "repository-reconciliation.csv",
  "deterministic-environment-audit.md"
)
stopifnot(all(file.exists(file.path(output_dir, expected_outputs))))

written_reconciliation <- utils::read.csv(
  file.path(output_dir, "dependency-reconciliation.csv"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)
stopifnot(
  nrow(written_reconciliation) == nrow(reconciliation),
  identical(written_reconciliation$package, reconciliation$package)
)

message("Deterministic environment-audit tests passed")
