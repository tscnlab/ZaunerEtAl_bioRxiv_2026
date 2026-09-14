stopifnot(getRversion() == numeric_version("4.6.1"))
audit_root <- "/private/tmp/brown-ba018-derivative-audit.p5VNOC"
shared <- "/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026"
brown <- "/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026"
stage2 <- file.path(brown, "audit/analyses/brown_adherence/main_linkage_b_amendment/stage2")
sha <- function(p) unname(digest::digest(file = p, algo = "sha256", serialize = FALSE))
verify <- function(path, count, expected = NULL) {
  if (!is.null(expected)) stopifnot(sha(path) == expected)
  m <- read.csv(path, stringsAsFactors = FALSE)
  stopifnot(nrow(m) == count, !anyDuplicated(m$path), !path %in% m$path)
  paths <- ifelse(startsWith(m$path, "/"), m$path, file.path(shared, m$path))
  m$observed_sha256 <- vapply(paths, sha, "")
  m$observed_bytes <- as.numeric(file.info(paths)$size)
  m$pass <- m$sha256 == m$observed_sha256 & m$bytes == m$observed_bytes
  stopifnot(all(m$pass))
  m
}
owner <- verify(file.path(stage2, "final_manifest.csv"), 54L, "c32e37760fea1226a420d8d42552f48862adfca41d044fbc56581497761328f0")
stopifnot(sha(file.path(stage2, "final_manifest_verification.csv")) == "7272f682e0fd4cbb560d2f54179fdbab924ed13b014f0e21eb0cbd98c5a56cab")
pins <- verify(file.path(shared, "audit/decisions/brown_main_linkage_b_stage2_release/execution_input_pins.csv"), 2174L)
protected <- verify(file.path(stage2, "preflight/preservation_before.csv"), 2066L)
stage1 <- verify(file.path(dirname(stage2), "stage1/final_manifest.csv"), 89L)
implementation <- verify(file.path(stage2, "likelihood/implementation_manifest.csv"), 23L)
for (name in c("owner", "pins", "protected", "stage1", "implementation")) write.csv(get(name), file.path(audit_root, paste0(name, "_rehash.csv")), row.names = FALSE)
files <- sort(list.files(stage2, recursive = TRUE, full.names = TRUE, all.files = TRUE, no.. = TRUE))
files <- files[!file.info(files)$isdir]
stopifnot(length(files) == 56L, setequal(files, c(owner$path, file.path(stage2, c("final_manifest.csv", "final_manifest_verification.csv")))))
write.csv(data.frame(path = files, sha256 = vapply(files, sha, ""), bytes = as.numeric(file.info(files)$size)), file.path(audit_root, "stopped_file_inventory.csv"), row.names = FALSE)
env <- new.env(parent = baseenv())
new_checker <- file.path(audit_root, "05_saved_derivative_gate_v2.R")
expressions <- as.list(parse(new_checker, keep.source = FALSE))
for (expression in head(expressions, -1L)) eval(expression, env)
raw <- read.csv(file.path(stage2, "likelihood/derivative_checks.csv"), check.names = FALSE)
result <- env$ba018_verify_saved_inputs(stage2)
write.csv(result$reconciliation, file.path(audit_root, "independent_saved_value_reconciliation.csv"), row.names = FALSE)
write.csv(result$gate, file.path(audit_root, "prospective_additive_gate.csv"), row.names = FALSE)
owner_reconciliation <- read.csv(file.path(stage2, "likelihood/derivative_gate_stop/saved_value_reconciliation.csv"))
stopifnot(identical(owner_reconciliation$parameter, result$reconciliation$parameter), all(abs(owner_reconciliation$absolute_difference - result$reconciliation$absolute_difference) < 1e-12))
bad <- list()
bad$empty <- raw[FALSE, , drop = FALSE]
bad$missing_column <- raw[, -2L]
bad$duplicate_parameter <- raw
bad$duplicate_parameter$parameter[[2L]] <- "beta_mu"
bad$wrong_order <- raw[c(2L, 1L, 3L, 4L), ]
bad$nonfinite_automatic <- raw
bad$nonfinite_automatic$automatic.1[[1L]] <- NA_real_
bad$nonfinite_finite_difference <- raw
bad$nonfinite_finite_difference$finite_difference[[1L]] <- Inf
bad$non_numeric <- raw
bad$non_numeric$automatic.1 <- as.character(bad$non_numeric$automatic.1)
bad$unequal_repeated_row <- raw
bad$unequal_repeated_row$automatic.1[[2L]] <- 0
bad$inconsistent_saved_difference <- raw
bad$inconsistent_saved_difference$absolute_difference.4 <- rep(0, 4L)
bad$above_threshold <- raw
bad$above_threshold$finite_difference[[4L]] <- raw$automatic.4[[1L]] + 0.001
bad$above_threshold$absolute_difference.4 <- rep(0.001, 4L)
negative <- data.frame(check = names(bad), rejected = vapply(bad, function(x) inherits(tryCatch(env$ba018_reconcile_saved_derivatives(x), error = identity), "error"), logical(1)))
stopifnot(all(negative$rejected))
write.csv(negative, file.path(audit_root, "negative_schema_checks.csv"), row.names = FALSE)
old_driver <- file.path(stage2, "code/02_fit_primary.R")
new_driver <- file.path(audit_root, "02_fit_primary_gate_v2.R")
old <- readChar(old_driver, file.info(old_driver)$size, useBytes = TRUE)
new <- readChar(new_driver, file.info(new_driver)$size, useBytes = TRUE)
old_gate <- "stopifnot(all(validation$pass), all(mapping$pass))"
new_gate <- paste(c("stopifnot(all(mapping$pass))", "source(file.path(code_root, \"05_saved_derivative_gate_v2.R\"))", "ba018_assert_additive_gate(stage2_root)"), collapse = "\n")
stopifnot(length(gregexpr(old_gate, old, fixed = TRUE)[[1L]]) == 1L)
stopifnot(identical(sub(old_gate, new_gate, old, fixed = TRUE), new), identical(sub(new_gate, old_gate, new, fixed = TRUE), old))
write.csv(data.frame(pre_path = old_driver, pre_sha256 = sha(old_driver), post_path = new_driver, post_sha256 = sha(new_driver), exact_forward = TRUE, exact_reverse = TRUE, fit_code_changed = FALSE), file.path(audit_root, "driver_reverse_proof.csv"), row.names = FALSE)
prob <- read.csv(file.path(stage2, "likelihood/exact_probability_moment_checks.csv"))
stopifnot(nrow(prob) == 24L, all(is.finite(as.matrix(prob[vapply(prob, is.numeric, logical(1))]))))
stopifnot(max(prob$normalization_error) < 1e-12, max(prob$objective_error) < 1e-7, max(prob$pmf_error) < 1e-12, max(prob$mean_error) < 1e-12, max(prob$variance_error) < 1e-12, min(prob$cdf_minimum_increment) >= -1e-14, max(prob$cdf_terminal_error) < 1e-12, all(prob$zero_restriction_exact & prob$one_restriction_exact))
runtime <- as.list(parse(file.path(stage2, "code/runtime_contract.R"), keep.source = FALSE))
assignment <- function(x) if (is.call(x) && identical(x[[1L]], as.name("<-")) && is.symbol(x[[2L]])) as.character(x[[2L]]) else ""
runtime_names <- vapply(runtime, assignment, "")
sandbox <- file.path(audit_root, "sandbox")
stopifnot(!dir.exists(sandbox))
dir.create(sandbox)
for (relative in c("likelihood/implementation_manifest.csv", "likelihood/derivative_checks.csv", "likelihood/validation.csv", "frames/construction_checks.csv", "frames/design_rank.csv")) {
  target <- file.path(sandbox, relative)
  dir.create(dirname(target), recursive = TRUE, showWarnings = FALSE)
  stopifnot(file.copy(file.path(stage2, relative), target), sha(target) == sha(file.path(stage2, relative)))
}
dir.create(file.path(sandbox, "code"))
for (p in c(new_checker, new_driver)) stopifnot(file.copy(p, file.path(sandbox, "code", basename(p))))
env$stage2_root <- sandbox
env$code_root <- file.path(sandbox, "code")
env$sha256 <- sha
for (name in c("lb_write_csv", "lb_manifest", "lb_assert_manifest")) eval(runtime[[match(name, runtime_names)]], env)
main <- as.list(tail(expressions, 1L)[[1L]][[3L]])[-1L]
stopifnot(is.call(main[[1L]]), identical(main[[1L]][[1L]], as.name("source")))
for (expression in main[-1L]) eval(expression, env)
driver_expressions <- as.list(parse(new_driver, keep.source = FALSE))
gate_index <- which(vapply(driver_expressions, function(x) is.call(x) && identical(x[[1L]], as.name("ba018_assert_additive_gate")), logical(1)))
stopifnot(length(gate_index) == 1L)
for (job in c("PRIMARY-ANY", "PRIMARY-80")) {
  env$commandArgs <- local({ value <- job; function(trailingOnly = FALSE) value })
  for (expression in driver_expressions[seq.int(2L, gate_index)]) eval(expression, env)
}
jobs <- lapply(c("VALIDATE-AND-PREPARE", "AUDIT-DERIVATIVE-STOP"), function(id) jsonlite::fromJSON(file.path(stage2, "preflight/execution_jobs", id, "finish.json")))
stopifnot(all(vapply(jobs, function(x) identical(x$exit_code, 0L) && identical(x$timed_out, FALSE) && identical(x$child_reaped, TRUE), logical(1))))
used <- sum(vapply(jobs, function(x) x$elapsed_seconds, numeric(1)))
stopifnot(abs(used - 11.036231749982107) < 1e-10)
stopifnot(!dir.exists(file.path(stage2, "models")), !dir.exists(file.path(stage2, "estimands")), !file.exists(file.path(stage2, "preflight/computation.lock")))
checks <- data.frame(check = c("owner_seal", "execution_inputs", "stage1", "historical_protected", "all_stopped_files", "historical_implementation", "saved_derivative_schema", "saved_derivative_reconciliation", "finite_scalar_threshold", "negative_schema_tests", "nonderivative_validation", "saved_probability_moment_records", "versioned_driver_forward_reverse", "standalone_gate_sandbox", "both_primary_gate_paths_no_fit", "two_jobs_reaped_and_no_lock", "runtime_preserved", "no_primary_or_estimand_outputs", "stopped_history_postcheck"), expected = c("54/54", "2174/2174", "89/89", "2066/2066", "56/56", "23/23", "4 named finite pairs", "componentwise <1e-12", "finite max <1e-4", "10/10 rejected", "14/14", "24/24", "exact single gate-interface change", "PASS", "2/2", "PASS", format(used, digits = 17), "absent", "54/54"), status = "PASS")
stopifnot(all(vapply(owner$path, sha, "") == owner$sha256))
write.csv(checks, file.path(audit_root, "independent_checks.csv"), row.names = FALSE)
write.csv(data.frame(path = c(new_checker, new_driver), sha256 = vapply(c(new_checker, new_driver), sha, ""), bytes = as.numeric(file.info(c(new_checker, new_driver))$size)), file.path(audit_root, "prospective_code_pins.csv"), row.names = FALSE)
writeLines(c("R --vanilla, independent saved-CSV reconciliation and sandboxed gate-only replay; no owner writes, TMB/objective/gradient/compile/fit/frame replay or random draws.", paste("digest", packageVersion("digest")), paste("jsonlite", packageVersion("jsonlite")), capture.output(sessionInfo())), file.path(audit_root, "session_and_scope.txt"))
cat("BA018_DERIVATIVE_RECOVERY_AUDIT=PASS checks=19/19 negative=10/10 sandbox_gate=PASS primary_prefix=2/2 maximum_saved_difference=", format(max(result$reconciliation$absolute_difference), digits=17), " prior_compute=", format(used,digits=17), "\n", sep="")
