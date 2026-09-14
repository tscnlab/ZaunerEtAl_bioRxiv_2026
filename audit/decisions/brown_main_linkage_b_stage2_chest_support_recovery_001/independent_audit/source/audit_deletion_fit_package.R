# Read-only independent audit of all fourteen registered site/participant deletion fits.
# Do not run until the Brown owner is at a safe scientific checkpoint.

args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) == 1L, !file.exists(args[[1L]]))
output <- args[[1L]]
stopifnot(startsWith(output, "/private/tmp/ba018-completion-audit.ekpsA4/"))
dir.create(output, recursive = FALSE)
author_root <- "/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026"
brown_root <- "/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026"
stage2 <- file.path(
  brown_root,
  "audit/analyses/brown_adherence/main_linkage_b_amendment/stage2"
)
.libPaths(c(
  file.path(author_root, "renv/library/macos/R-4.6/aarch64-apple-darwin23"),
  .libPaths()
))
stopifnot(as.character(getRversion()) == "4.6.1")
sha <- function(path) unname(digest::digest(path, file = TRUE, algo = "sha256"))
csv <- function(path)
  read.csv(path, check.names = FALSE, stringsAsFactors = FALSE)
inputs_used <- character()
read_input <- function(path, reader = csv) {
  stopifnot(file.exists(path), !dir.exists(path))
  inputs_used <<- unique(c(inputs_used, path))
  reader(path)
}
checks <- list()
check <- function(id, value, detail = "") {
  checks[[length(checks) + 1L]] <<- data.frame(
    check = id,
    pass = isTRUE(value),
    detail = detail
  )
  if (!isTRUE(value)) {
    write.csv(
      do.call(rbind, checks),
      file.path(output, "checks_stopped.csv"),
      row.names = FALSE
    )
    stop(id, call. = FALSE)
  }
}
audit_manifest <- function(path, expected_count = NULL) {
  table <- read_input(path)
  check(
    paste0(basename(path), "_columns"),
    all(c("path", "bytes", "sha256") %in% names(table))
  )
  check(
    paste0(basename(path), "_shape"),
    !anyNA(table[, c("path", "bytes", "sha256")]) &&
      !anyDuplicated(table$path) &&
      !(normalizePath(path) %in% table$path) &&
      (is.null(expected_count) || nrow(table) == expected_count)
  )
  check(
    paste0(basename(path), "_members"),
    all(file.exists(table$path)) &&
      all(unname(file.info(table$path)$size) == table$bytes) &&
      identical(unname(vapply(table$path, sha, character(1))), table$sha256)
  )
  inputs_used <<- unique(c(inputs_used, table$path))
  invisible(table)
}
immutable <- c(
  "models/BA-LB-PRIMARY-ANY.rds" = "494b4647e7394b8efcaaf7cd7ae2922ba0669ac609529328d0a5e67cab60c245",
  "models/BA-LB-PRIMARY-80.rds" = "72cc742f3d60941a5a4fc44361f09a671fea00a4183b85ab932d1d7292a02a74",
  "estimands/manifest.csv" = "baff7f3cb89565235193a2a74dc64afd82a58e3fea3d519c55fce08318d4863a",
  "estimands/validation.csv" = "bf182db7ccc2546972e1e7352ef40e82a913832c0a9432488e79ffd7c03f831f",
  "influence/deletion_inputs_recovery_001/model_inputs.rds" = "b124c3ea2613418f765dc016e50eab71fbc4207645e3df380df040fc4f6cf20b"
)
immutable_paths <- file.path(stage2, names(immutable))
check(
  "frozen_before",
  identical(
    unname(vapply(immutable_paths, sha, character(1))),
    unname(immutable)
  )
)
inputs_used <- unique(c(inputs_used, immutable_paths))
registry_path <- file.path(
  stage2,
  "preflight/deletion_target_recovery_001/deletion_fit_job_registry.csv"
)
registry <- read_input(registry_path)
expected_ids <- c(
  paste0(
    "LOSO-",
    c(
      "RISE",
      "THUAS",
      "BAUA",
      "MPI",
      "TUM",
      "FUSPCEU",
      "IZTECH",
      "UCR",
      "KNUST"
    )
  ),
  paste0("INFLUENCE-", seq_len(5L))
)
check(
  "fourteen_exact_jobs",
  identical(registry$job_id, expected_ids) &&
    !anyDuplicated(registry$job_id) &&
    all(registry$model_fit_count == 1L) &&
    all(registry$diagnostic_draws == 0L) &&
    all(!registry$primary_gate_rewrite)
)
audit_manifest(
  file.path(stage2, "influence/deletion_inputs_recovery_001/manifest.csv"),
  6L
)
started <- proc.time()[["elapsed"]]
started_utc <- format(Sys.time(), tz = "UTC", usetz = TRUE)
source_inputs <- read_input(
  file.path(stage2, "influence/deletion_inputs_recovery_001/model_inputs.rds"),
  readRDS
)
model_summary <- list()
for (i in seq_len(nrow(registry))) {
  job <- registry[i, , drop = FALSE]
  audit_manifest(job$manifest_path, 7L)
  bundle <- read_input(job$model_path, readRDS)
  checkpoint <- read_input(
    sub("\\.rds$", "_input.rds", job$model_path),
    readRDS
  )
  frozen_input <- source_inputs[[job$job_id]]
  check(
    paste0(job$job_id, "_exact_input"),
    identical(bundle$design_object, frozen_input$design_object) &&
      identical(checkpoint$design_object, frozen_input$design_object) &&
      identical(bundle$initial_parameters, frozen_input$initial_parameters) &&
      identical(
        checkpoint$initial_parameters,
        frozen_input$initial_parameters
      ) &&
      identical(bundle$frames_sha256, job$input_sha256) &&
      identical(
        bundle$primary_reference_sha256,
        frozen_input$source_primary_sha256
      ) &&
      identical(bundle$deletion, frozen_input$deletion) &&
      identical(checkpoint, frozen_input)
  )
  frame <- bundle$design_object$frame
  data <- bundle$design_object$data
  check(
    paste0(job$job_id, "_counts"),
    nrow(frame) == job$rows &&
      nlevels(frame$participant_id) == job$participants &&
      nlevels(frame$behavioral_day_id) == job$cycles &&
      sum(frame$valid_minutes) == job$valid_minutes &&
      identical(data$y, as.integer(frame$brown_yes)) &&
      identical(data$n, as.integer(frame$valid_minutes)) &&
      if (startsWith(job$job_id, "INFLUENCE-"))
        nlevels(frame$participant_id) == 139L && nlevels(frame$site) == 9L else
        nlevels(frame$site) == 8L
  )
  gate <- as.data.frame(bundle$fit_gate)
  gate_types <- vapply(
    gate,
    function(x) {
      if (is.double(x)) "numeric" else typeof(x)
    },
    character(1)
  )
  stopifnot(all(
    gate_types %in% c("numeric", "integer", "logical", "character")
  ))
  csv_gate <- read_input(
    sub("\\.rds$", "_fit_gate.csv", job$model_path),
    function(path) {
      read.csv(
        path,
        check.names = FALSE,
        stringsAsFactors = FALSE,
        colClasses = gate_types
      )
    }
  )
  check(
    paste0(job$job_id, "_exported_gate"),
    isTRUE(all.equal(
      gate,
      csv_gate,
      tolerance = 1e-12,
      check.attributes = FALSE
    ))
  )
  check(
    paste0(job$job_id, "_purpose"),
    identical(bundle$accepted, FALSE) &&
      identical(bundle$purpose, "finite_primary_sample_deletion_sensitivity") &&
      identical(bundle$model_id, job$model_id) &&
      identical(bundle$sample_id, job$sample_id)
  )
  expected_hard <- gate$convergence != 0L ||
    !is.finite(gate$objective) ||
    !is.finite(gate$maximum_absolute_gradient) ||
    gate$maximum_absolute_gradient > 0.01 ||
    !gate$positive_definite_hessian ||
    !gate$fixed_parameters_finite ||
    !gate$covariance_finite ||
    !is.finite(gate$minimum_covariance_eigenvalue) ||
    gate$minimum_covariance_eigenvalue <= 0 ||
    !gate$endpoint_probability_interior
  expected_separation <- is.finite(gate$maximum_endpoint_coefficient) &&
    (gate$maximum_endpoint_coefficient > 15 ||
      !is.finite(gate$maximum_endpoint_standard_error) ||
      gate$maximum_endpoint_standard_error > 10)
  # A missing/invalid report is already a structural failure. Do not reinterpret it.
  expected_structural <- expected_hard ||
    expected_separation ||
    gate$mean_random_boundary ||
    gate$all_no_random_boundary ||
    gate$all_yes_random_boundary
  check(
    paste0(job$job_id, "_gate_consistency"),
    (!expected_structural || gate$structural_failure) &&
      identical(
        gate$fit_status == "structural_failure",
        gate$structural_failure
      )
  )
  selected <- as.data.frame(bundle$optimization_log)
  selected <- selected[which(selected$selected), , drop = FALSE]
  check(
    paste0(job$job_id, "_selected_optimizer"),
    nrow(selected) == 1L &&
      selected$convergence == gate$convergence &&
      isTRUE(all.equal(selected$objective, gate$objective, tolerance = 1e-12))
  )
  finish_path <- file.path(
    stage2,
    "preflight/execution_jobs",
    job$job_id,
    "finish.json"
  )
  finish <- read_input(
    finish_path,
    function(path) jsonlite::read_json(path, simplifyVector = TRUE)
  )
  check(
    paste0(job$job_id, "_execution"),
    finish$job_id == job$job_id &&
      finish$exit_code == 0L &&
      !finish$timed_out &&
      finish$child_reaped &&
      finish$driver_sha256 == job$driver_sha256 &&
      finish$effective_wall_limit_seconds <= 120 &&
      length(finish$command) == 4L &&
      finish$command[[4L]] == job$job_id
  )
  model_summary[[i]] <- gate[,
    c(
      "model_id",
      "sample_id",
      "rows",
      "participants",
      "behavioral_days",
      "fit_status",
      "structural_failure",
      "failure_components",
      "maximum_absolute_gradient",
      "positive_definite_hessian",
      "endpoint_probability_interior"
    ),
    drop = FALSE
  ]
}
scientific_elapsed <- proc.time()[["elapsed"]] - started
check(
  "frozen_after",
  identical(
    unname(vapply(immutable_paths, sha, character(1))),
    unname(immutable)
  )
)
write.csv(
  do.call(rbind, checks),
  file.path(output, "checks.csv"),
  row.names = FALSE
)
write.csv(
  do.call(rbind, model_summary),
  file.path(output, "model_summary.csv"),
  row.names = FALSE
)
write.csv(
  data.frame(
    started_utc = started_utc,
    finished_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
    r_version = R.version.string,
    scientific_audit_seconds = scientific_elapsed,
    fits = 0L,
    predictions = 0L,
    diagnostic_draws = 0L,
    scope = "stored model input/gate consistency, not scientific sensitivity acceptance"
  ),
  file.path(output, "audit_runtime.csv"),
  row.names = FALSE
)
write.csv(
  data.frame(
    path = inputs_used,
    bytes = unname(file.info(inputs_used)$size),
    sha256 = vapply(inputs_used, sha, character(1))
  ),
  file.path(output, "input_manifest.csv"),
  row.names = FALSE
)
writeLines(capture.output(sessionInfo()), file.path(output, "session.txt"))
cat(sprintf(
  "DELETION_FIT_PACKAGE_AUDIT=PASS jobs=14 checks=%d scientific_audit_seconds=%.6f fits=0 draws=0\n",
  length(checks),
  scientific_elapsed
))
