stopifnot(as.character(getRversion()) == "4.6.1")
.libPaths(c("/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026/renv/library/macos/R-4.6/aarch64-apple-darwin23", .libPaths()))
library(data.table)
root <- "/private/tmp/ba018-diagnostic-recovery.DfiQe9"
stage2 <- "/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026/audit/analyses/brown_adherence/main_linkage_b_amendment/stage2"
central <- "/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026"
sha <- function(p) unname(digest::digest(p, algo = "sha256", file = TRUE))
candidate <- file.path(root, "07_run_primary_diagnostics_v2.R")
code <- parse(candidate)
fixture_script <- parse(file.path(central, "audit/decisions/brown_main_linkage_b_stage2_diagnostic_status_export_stop_001/independent_audit/review_driver.R"))
fixture_expression <- which(vapply(fixture_script, function(x) is.call(x) && identical(x[[1]], as.name("<-")) && identical(x[[2]], as.name("result_template")), logical(1)))
stopifnot(length(fixture_expression) == 1L)
eval(fixture_script[[fixture_expression]])
registry <- read.csv(file.path(root, "job_registry_0001.csv"), stringsAsFactors = FALSE)
seeds <- read.csv(file.path(stage2, "preflight/qualified_continuation_001/diagnostic_seed_registry.csv"), stringsAsFactors = FALSE)
gate <- read.csv(file.path(stage2, "estimands/B_to_B80_claim_gate.csv"), stringsAsFactors = FALSE)
checks <- data.frame(check = character(), pass = logical())
suite_root <- tempfile("driver_suite_", tmpdir = root)
dir.create(suite_root)
normalize_fixture <- function(x) {
  if (is.data.table(x)) return(as.data.frame(x))
  if (is.list(x)) return(lapply(x, normalize_fixture))
  x
}
check <- function(id, pass) {
  checks[nrow(checks) + 1L, ] <<- list(id, isTRUE(pass))
  stopifnot(isTRUE(pass))
}
run_case <- function(name, key = "PRIMARY-ANY", fault = "none") {
  dst <- file.path(suite_root, paste0("driver_fixture_", name))
  stopifnot(!file.exists(dst))
  dir.create(dst)
  e <- new.env(parent = globalenv())
  e$stage2_root <- dst
  e$code_root <- file.path(dst, "code")
  e$derive_calls <- 0L
  e$events <- character()
  e$commandArgs <- function(...) key
  e$source <- function(path, ...) {
    stopifnot(basename(path) %in% c("runtime_contract.R", "boundary_model_contract.R", "diagnostic_interface.R"))
    e$events <- c(e$events, paste0("mock_source:", basename(path)))
    invisible(NULL)
  }
  e$lb_assert_manifest <- function(path) {
    stopifnot(basename(path) == "primary_diagnostic_source_manifest.csv")
    if (fault == "source_manifest") stop("SYNTHETIC source manifest mismatch")
    invisible(TRUE)
  }
  e$sha256 <- function(path) {
    name <- basename(path)
    if (name == "07_run_primary_diagnostics_v2.R") return(if (fault == "driver_hash") "WRONG" else sha(candidate))
    idx <- if (grepl("PRIMARY-ANY", name, fixed = TRUE)) 1L else 2L
    if (endsWith(name, "_fit_gate.csv")) return(registry$fit_gate_sha256[idx])
    if (name %in% c("BA-LB-PRIMARY-ANY.rds", "BA-LB-PRIMARY-80.rds")) return(registry$model_sha256[idx])
    stop("Unexpected hash path in fixture")
  }
  e$read.csv <- function(path, ...) {
    name <- basename(path)
    if (name == "job_registry_0001.csv") {
      x <- registry
      if (fault == "duplicate_job") x <- rbind(x, x[1L, ])
      if (fault == "missing_job") x <- x[0L, ]
      return(x)
    }
    if (name == "diagnostic_seed_registry.csv") {
      x <- seeds
      if (fault == "seed") x$predictive_seed <- 123L
      return(x)
    }
    if (name == "B_to_B80_claim_gate.csv") return(gate)
    if (endsWith(name, "_fit_gate.csv")) {
      x <- data.frame(model_id = paste0("BA-LB-", key), sample_id = if (key == "PRIMARY-ANY") "B_any" else "B_80", fit_status = "acceptable_with_cautions")
      if (fault == "missing_status") x$fit_status <- NULL
      if (fault == "duplicate_fit") x <- rbind(x, x)
      if (fault == "NA_status") x$fit_status <- NA_character_
      if (fault == "empty_status") x$fit_status <- ""
      if (fault == "wrong_model") x$model_id <- "WRONG"
      e$events <- c(e$events, "fit_schema_read")
      return(x)
    }
    stop("Forbidden data read in synthetic fixture")
  }
  e$derive_diagnostics <- function(sample_id, model_path) {
    e$derive_calls <- e$derive_calls + 1L
    e$events <- c(e$events, "mock_diagnostic_return")
    x <- result_template(sample_id)
    if (fault == "return_status") x$bundle$fit_gate$fit_status <- "WRONG"
    if (fault == "return_missing_status") x$bundle$fit_gate$fit_status <- NULL
    if (fault == "construction") x$simulated_response <- matrix(-1L, nrow = 18L, ncol = 250L)
    x
  }
  e$summarize_calibration <- function(...) {
    e$events <- c(e$events, "mock_calibration")
    data.table(grouping = rep("state_day_type", 6))
  }
  e$lb_write_csv <- function(x, path) {
    if (fault == "export") stop("SYNTHETIC later export failure")
    full <- file.path(dst, path)
    stopifnot(startsWith(full, paste0(root, "/")), !file.exists(full))
    dir.create(dirname(full), recursive = TRUE, showWarnings = FALSE)
    utils::write.csv(x, full, row.names = FALSE)
    e$events <- c(e$events, paste0("csv:", basename(path)))
  }
  e$lb_save_rds <- function(x, path) {
    full <- file.path(dst, path)
    stopifnot(startsWith(full, paste0(root, "/")), !file.exists(full))
    dir.create(dirname(full), recursive = TRUE, showWarnings = FALSE)
    saveRDS(x, full, version = 3L)
    e$events <- c(e$events, paste0("rds:", basename(path)))
  }
  e$lb_manifest <- function(paths, path) {
    stopifnot(!anyDuplicated(paths), !file.path(dst, path) %in% paths)
    e$lb_write_csv(data.frame(path = paths, sha256 = vapply(paths, sha, character(1)), bytes = file.info(paths)$size), path)
  }
  e$simulate_conditional <- e$randomized_quantile_residuals <- e$conditional_predictions <- e$readRDS <- function(...) stop("Forbidden scientific or model-RDS call in synthetic replay")
  if (fault == "existing_output") dir.create(file.path(dst, "diagnostics/primary_any_valid"), recursive = TRUE)
  error <- NULL
  log <- capture.output(tryCatch(for (expr in code) eval(expr, e), error = function(x) error <<- conditionMessage(x)))
  writeLines(c(log, paste("error:", if (is.null(error)) "NONE" else error), e$events), file.path(root, paste0("driver_", name, ".log")))
  list(env = e, error = error, root = dst)
}
for (key in c("PRIMARY-ANY", "PRIMARY-80")) {
  x <- run_case(key, key)
  check(paste0(key, "_complete_driver"), is.null(x$error) && x$env$derive_calls == 1L)
  check(paste0(key, "_14_construction_checks"), nrow(x$env$checks) == 14L && all(x$env$checks$pass))
  pos <- match("mock_diagnostic_return", x$env$events)
  check(paste0(key, "_immediate_raw_checkpoint"), x$env$events[pos + 1L] == "rds:raw_diagnostic_checkpoint.rds")
  raw <- readRDS(file.path(x$root, x$env$output_prefix, "raw_diagnostic_checkpoint.rds"))
  check(paste0(key, "_raw_return_unmodified"), identical(normalize_fixture(raw), normalize_fixture(result_template(x$env$sample_id))))
  check(paste0(key, "_fit_status_not_overall_gate"), identical(x$env$technical$status, "acceptable_with_cautions") && "not_acceptable" %in% x$env$result$assessment$status)
  check(paste0(key, "_M1_false_retained"), identical(as.character(x$env$qualification$analysis_state[!x$env$qualification$original_M1_coverage_gate_passed]), "Pre-sleep"))
  m <- read.csv(file.path(x$root, x$env$output_prefix, "manifest.csv"), stringsAsFactors = FALSE)
  check(paste0(key, "_15_exact_non_circular_members"), nrow(m) == 15L && !anyDuplicated(m$path) && all(vapply(m$path, sha, character(1)) == m$sha256) && !any(basename(m$path) == "manifest.csv"))
}
for (fault in c("source_manifest", "driver_hash", "duplicate_job", "missing_job", "seed", "missing_status", "duplicate_fit", "NA_status", "empty_status", "wrong_model", "existing_output")) {
  x <- run_case(fault, fault = fault)
  check(paste0(fault, "_stops_before_diagnostics"), !is.null(x$error) && x$env$derive_calls == 0L)
}
for (fault in c("return_status", "return_missing_status", "export", "construction")) {
  x <- run_case(fault, fault = fault)
  check(paste0(fault, "_stops_with_checkpoint"), !is.null(x$error) && x$env$derive_calls == 1L && file.exists(file.path(x$root, x$env$output_prefix, "raw_diagnostic_checkpoint.rds")))
}
old <- file.path(stage2, "code/07_run_primary_diagnostics.R")
check("exact_six_change_reverse", sha(file.path(root, "reconstructed_07_run_primary_diagnostics.R")) == sha(old))
check("author_driver_unchanged", sha(old) == "20c8a54701b7cd1772ce78aa5b18588dfa9459d08a13dd879ac4716ba58eb5f3")
check("scientific_interface_unchanged", sha(file.path(stage2, "code/diagnostic_interface.R")) == "6026e55cdb9a1d09920ce796084d32b0d714a990cd894d0bbbbef18efb518f38")
write.csv(checks, file.path(root, "driver_checks.csv"), row.names = FALSE)
writeLines(c("Full prospective driver executed only with synthetic functions and fixed fixtures. No model RDS, prediction, real residual or diagnostic draw was read or calculated. Scope: metadata, schema, checkpoint, registry and export behavior, not scientific success.", capture.output(sessionInfo())), file.path(root, "driver_scope_and_session.txt"))
cat("BROWN_RECOVERY_DRIVER=PASS", nrow(checks), "/", nrow(checks), "mock_only=TRUE real_draws=0\n")
