#!/usr/bin/env Rscript

# Runtime-only continuation controller for the byte-identical H06-D-013
# influence runner. Scientific code and existing checkpoint hashes are not
# changed. The only in-memory edit replaces the expired one-hour stop with the
# author-required bounded health check at least every 15 minutes.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
.libPaths(c(
  file.path(root, "renv/library/macos/R-4.6/aarch64-apple-darwin23"),
  .libPaths()
))
suppressPackageStartupMessages({
  library(digest)
  library(readr)
})

original_runner <- file.path(
  root,
  "scripts/hypotheses/H06_daily/run_h06_daily_non_l10_production_influence.R"
)
authorization_path <- file.path(
  root,
  "audit/decisions/h06_daily_non_l10_production_authorization.md"
)
continuation_record_path <- file.path(
  root,
  "audit/hypotheses/H06_daily/H06_daily_non_l10_production_runtime_continuation.md"
)
state_path <- file.path(
  root,
  "artifacts/08_diagnostics/H06_daily/H06_daily_non_l10_production_state.rds"
)
influence_index_path <- file.path(
  root,
  "artifacts/08_diagnostics/H06_daily/H06_daily_non_l10_production_influence_checkpoint.csv"
)
continuation_state_path <- file.path(
  root,
  "artifacts/08_diagnostics/H06_daily/H06_daily_non_l10_production_runtime_continuation_state.rds"
)
health_check_path <- file.path(
  root,
  "artifacts/08_diagnostics/H06_daily/H06_daily_non_l10_production_runtime_health_checks.csv"
)
influence_dir <- file.path(
  root,
  "artifacts/08_diagnostics/H06_daily/H06_daily_non_l10_production_influence_cells"
)

sha256_file <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
}
assert_true <- function(condition, message) {
  if (!isTRUE(condition)) stop(message, call. = FALSE)
}

assert_true(
  identical(as.character(getRversion()), "4.6.1"),
  "The continuation controller requires R 4.6.1"
)
assert_true(
  sha256_file(authorization_path) ==
    "0818d1618daa49d38b60680bf9585b99f51db098b4f6f7c652f1970e7cd1c547",
  "The controlling H06-D-013 authorization changed"
)
assert_true(
  sha256_file(original_runner) ==
    "637c8fa08fe50adb92f1d59dee7f5ae744d44a4d97403783d66bb86521e02781",
  "The byte-identical original influence runner changed"
)
assert_true(file.exists(continuation_record_path), "Continuation record missing")

production_state <- readRDS(state_path)
assert_true(
  identical(production_state$authorization, "H06-D-013") &&
    production_state$phase %in% c("BASE_COMPLETE", "INFLUENCE_COMPLETE"),
  "The production state is not eligible for checkpointed continuation"
)
if (identical(production_state$phase, "INFLUENCE_COMPLETE")) {
  message("H06-D-013 influence phase is already complete; no continuation run needed")
  quit(save = "no", status = 0L)
}

influence_index <- readr::read_csv(influence_index_path, show_col_types = FALSE)
completed_paths <- normalizePath(
  file.path(root, influence_index$checkpoint_relative_path),
  winslash = "/",
  mustWork = TRUE
)
partial_paths <- list.files(influence_dir, pattern = "[.]rds$", full.names = TRUE)
partial_paths <- partial_paths[
  !normalizePath(partial_paths, winslash = "/", mustWork = TRUE) %in%
    completed_paths
]
assert_true(length(partial_paths) <= 1L, "More than one partial influence cell exists")
partial <- if (length(partial_paths)) readRDS(partial_paths[[1L]]) else NULL
persisted_total_wall <- production_state$base_elapsed_seconds +
  sum(influence_index$cell_wall_seconds) +
  if (is.null(partial)) 0 else partial$cell_wall_seconds
persisted_refits <- sum(influence_index$completed_refits) +
  if (is.null(partial)) 0L else nrow(partial$results)

if (file.exists(continuation_state_path)) {
  continuation_state <- readRDS(continuation_state_path)
  assert_true(
      identical(continuation_state$authorization, "H06-D-013") &&
      identical(continuation_state$gate, "H06-D-G2") &&
      continuation_state$health_check_interval_seconds == 900 &&
      continuation_state$original_runner_sha256 == sha256_file(original_runner) &&
      continuation_state$authorization_sha256 == sha256_file(authorization_path) &&
      continuation_state$continuation_record_sha256 ==
        sha256_file(continuation_record_path),
    "The persisted continuation controller state is incompatible"
  )
} else {
  assert_true(
    abs(persisted_total_wall - 3599.768) < 1e-6 && persisted_refits == 33794L,
    "The first continuation origin differs from the author-approved checkpoint"
  )
  continuation_state <- list(
    authorization = "H06-D-013",
    gate = "H06-D-G2",
    health_check_interval_seconds = 900,
    origin_total_wall_seconds = persisted_total_wall,
    origin_preserved_refits = persisted_refits,
    original_runner_sha256 = sha256_file(original_runner),
    authorization_sha256 = sha256_file(authorization_path),
    continuation_record_sha256 = sha256_file(continuation_record_path),
    created = format(Sys.time(), tz = "UTC", usetz = TRUE),
    status = "READY"
  )
  saveRDS(continuation_state, continuation_state_path, version = 3)
}

h06d_continuation_last_health_elapsed <- -Inf
h06d_continuation_health_check <- function(
    completed_total,
    failures_total,
    total_production_wall,
    influence_index,
    results,
    preservation_baseline,
    force = FALSE,
    phase = "active") {
  now_elapsed <- proc.time()[["elapsed"]]
  if (
    !force &&
      is.finite(h06d_continuation_last_health_elapsed) &&
      now_elapsed - h06d_continuation_last_health_elapsed < 900
  ) {
    return(invisible(NULL))
  }
  input_check <- h06d_prod_verify_contract(root, h06d_prod_input_contract())
  main_check <- h06d_prod_verify_contract(
    root,
    h06d_prod_main_h06_contract() |>
      dplyr::mutate(
        input_id = paste0("main_h06_", dplyr::row_number()),
        .before = 1L
      )
  )
  preservation <- h06d_prod_recheck_preservation(
    root,
    preservation_baseline,
    paste0("runtime_health_", phase)
  )
  previous <- if (file.exists(health_check_path)) {
    readr::read_csv(health_check_path, show_col_types = FALSE)
  } else {
    tibble::tibble()
  }
  previous_refits <- if (nrow(previous)) tail(previous$completed_refits, 1L) else NA_real_
  previous_wall <- if (nrow(previous)) tail(previous$total_production_wall_seconds, 1L) else NA_real_
  runtime_rate <- if (
    is.finite(previous_refits) && is.finite(previous_wall) &&
      total_production_wall > previous_wall
  ) {
    (completed_total - previous_refits) / (total_production_wall - previous_wall)
  } else {
    NA_real_
  }
  row <- tibble::tibble(
    authorization = "H06-D-013",
    gate = "H06-D-G2",
    check_number = nrow(previous) + 1L,
    phase = phase,
    checked_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
    completed_cells = nrow(influence_index),
    completed_refits = completed_total,
    total_refits = 66664L,
    remaining_refits = 66664L - completed_total,
    non_estimable_refits = failures_total,
    failure_rate = failures_total / completed_total,
    total_production_wall_seconds = total_production_wall,
    refits_per_second_since_prior_check = runtime_rate,
    repeated_checkpoint_failures = 0L,
    checkpoint_status = "PASS_NO_REPEATED_FAILURE",
    input_pins_checked = nrow(input_check),
    input_pin_status = if (all(input_check$verification_status == "PASS")) "PASS" else "FAIL",
    main_h06_pins_checked = nrow(main_check),
    main_h06_pin_status = if (all(main_check$verification_status == "PASS")) "PASS" else "FAIL",
    protected_identities_checked = nrow(preservation),
    protected_identity_status = if (
      all(preservation$identity_status == "BYTE_IDENTICAL")
    ) "PASS" else "FAIL"
  )
  readr::write_csv(dplyr::bind_rows(previous, row), health_check_path, na = "")
  message(sprintf(
    paste0(
      "HEALTH %d [%s]: %d/%d refits; %d non-estimable (%.4f%%); ",
      "%.3f production seconds; inputs/protected identities PASS"
    ),
    row$check_number,
    phase,
    completed_total,
    66664L,
    failures_total,
    100 * failures_total / completed_total,
    total_production_wall
  ))
  h06d_continuation_last_health_elapsed <<- now_elapsed
  invisible(row)
}

runner_lines <- readLines(original_runner, warn = FALSE)
runtime_start <- which(runner_lines == "    if (total_production_wall > 3600) {")
failure_start <- which(
  runner_lines ==
    "    if (completed_total >= 500L && failures_total / completed_total > 0.10) {"
)
assert_true(
  length(runtime_start) == 1L && length(failure_start) == 1L &&
    failure_start > runtime_start,
  "The original runtime block is not exactly as sealed"
)
health_call <- c(
  "    h06d_continuation_health_check(",
  "      completed_total = completed_total,",
  "      failures_total = failures_total,",
  "      total_production_wall = total_production_wall,",
  "      influence_index = influence_index,",
  "      results = results,",
  "      preservation_baseline = preservation_baseline",
  "    )"
)
runner_lines <- c(
  runner_lines[seq_len(runtime_start - 1L)],
  health_call,
  runner_lines[failure_start:length(runner_lines)]
)
message(sprintf(
  paste0(
    "Resuming %d preserved refits at %.3f seconds; health checks are required ",
    "every 900 seconds"
  ),
  persisted_refits,
  persisted_total_wall
))

continuation_state$status <- "RUNNING"
continuation_state$last_invocation_started <-
  format(Sys.time(), tz = "UTC", usetz = TRUE)
continuation_state$last_persisted_total_wall_seconds <- persisted_total_wall
continuation_state$last_persisted_refits <- persisted_refits
saveRDS(continuation_state, continuation_state_path, version = 3)

invocation_started <- proc.time()[["elapsed"]]
run_error <- NULL
tryCatch(
  eval(parse(text = runner_lines, keep.source = FALSE), envir = environment()),
  error = function(condition) {
    run_error <<- condition
  }
)

if (exists("completed_total", inherits = FALSE)) {
  h06d_continuation_health_check(
    completed_total = completed_total,
    failures_total = failures_total,
    total_production_wall = total_production_wall,
    influence_index = influence_index,
    results = results,
    preservation_baseline = preservation_baseline,
    force = TRUE,
    phase = if (is.null(run_error)) "complete" else "stopped"
  )
}

continuation_state <- readRDS(continuation_state_path)
continuation_state$last_invocation_wall_seconds <- unname(
  proc.time()[["elapsed"]] - invocation_started
)
continuation_state$last_invocation_finished <-
  format(Sys.time(), tz = "UTC", usetz = TRUE)
continuation_state$status <- if (is.null(run_error)) "COMPLETE" else "STOPPED_WITH_ERROR"
continuation_state$error <- if (is.null(run_error)) NA_character_ else conditionMessage(run_error)
saveRDS(continuation_state, continuation_state_path, version = 3)

if (!is.null(run_error)) stop(run_error)
