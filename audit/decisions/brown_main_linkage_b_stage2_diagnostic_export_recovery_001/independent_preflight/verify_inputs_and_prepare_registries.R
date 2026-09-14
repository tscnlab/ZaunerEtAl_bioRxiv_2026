stopifnot(as.character(getRversion()) == "4.6.1")
root <- "/private/tmp/ba018-diagnostic-recovery.DfiQe9"
central <- "/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026"
stage2 <- "/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026/audit/analyses/brown_adherence/main_linkage_b_amendment/stage2"
stage1 <- file.path(dirname(stage2), "stage1")
owner <- file.path(stage2, "completion_v2/continued_final_package_003")
sha <- function(p) unname(digest::digest(p, algo = "sha256", file = TRUE))
manifests <- list(
  owner_223 = c(file.path(owner, "final_manifest.csv"), "ef06de7af67271cfdd2b6ab4958aede173e5707d1a5d6c8c20f23f63db4877fe", 223),
  independent_stop_271 = c(file.path(central, "audit/decisions/brown_main_linkage_b_stage2_diagnostic_status_export_stop_001/independent_manifest.csv"), "2eb0131608191f045b22f1f6abd53df666c7b51d26705eba6a7b7bd0edd81ff6", 271),
  qualified_dispatch_254 = c(file.path(central, "audit/decisions/brown_main_linkage_b_stage2_qualified_diagnostics_continuation_001/dispatch_manifest.csv"), "4565e11e7d9a2cdcd34a0c8fa47bd3e7987bf381dedce4b0b817beca5a786667", 254),
  primary_estimands_23 = c(file.path(stage2, "estimands/manifest.csv"), "baff7f3cb89565235193a2a74dc64afd82a58e3fea3d519c55fce08318d4863a", 23),
  stage1_89 = c(file.path(stage1, "final_manifest.csv"), "7290ad5f2e595949cde38dcd241bc5f4cb0037094c1a0ed99e03c3252e877dc0", 89)
)
all_rows <- list()
for (name in names(manifests)) {
  spec <- manifests[[name]]
  stopifnot(sha(spec[[1]]) == spec[[2]])
  m <- read.csv(spec[[1]], stringsAsFactors = FALSE)
  stopifnot(nrow(m) == as.integer(spec[[3]]), !anyDuplicated(m$path), !spec[[1]] %in% m$path)
  m$observed_sha256 <- vapply(m$path, sha, character(1))
  m$observed_bytes <- unname(file.info(m$path)$size)
  m$exact <- m$observed_sha256 == m$sha256 & m$observed_bytes == m$bytes
  stopifnot(all(m$exact))
  write.csv(m, file.path(root, paste0(name, "_verification.csv")), row.names = FALSE)
  all_rows[[name]] <- data.frame(path = c(spec[[1]], m$path))
}
p <- read.csv(file.path(owner, "protected_identity_verification.csv"), stringsAsFactors = FALSE)
p <- p[!duplicated(p$path), c("path", "expected_sha256", "expected_bytes")]
p$observed_sha256 <- vapply(p$path, sha, character(1))
p$observed_bytes <- unname(file.info(p$path)$size)
p$exact <- p$expected_sha256 == p$observed_sha256 & p$expected_bytes == p$observed_bytes
stopifnot(nrow(p) == 2287L, all(p$exact))
write.csv(p, file.path(root, "protected_verification.csv"), row.names = FALSE)
f <- read.csv(file.path(owner, "finalization_checks.csv"))
stopifnot(nrow(f) == 20L, all(f$pass))
job_files <- list.files(file.path(stage2, "preflight/execution_jobs"), recursive = TRUE, full.names = TRUE, pattern = "^finish\\.json$")
jobs <- lapply(job_files, jsonlite::fromJSON)
stopifnot(length(jobs) == 8L, sum(vapply(jobs, function(x) x$exit_code != 0, logical(1))) == 3L, all(vapply(jobs, function(x) !x$timed_out && x$child_reaped, logical(1))))
runtime <- sum(vapply(jobs, function(x) x$elapsed_seconds, numeric(1)))
stopifnot(abs(runtime - 100.50703887498821) < 1e-10)
draws <- read.csv(file.path(owner, "diagnostic_draw_accounting.csv"), stringsAsFactors = FALSE)
stopifnot(nrow(draws) == 6L, sum(draws$attempted_draws) == 250L, sum(draws$durably_exported_draws) == 0L)
stopifnot(!dir.exists(file.path(stage2, "diagnostics")), !file.exists(file.path(stage2, "preflight/computation.lock")))
new_paths <- file.path(stage2, c("code/07_run_primary_diagnostics_v2.R", "code/run_bounded_job_v4.py", "preflight/diagnostic_export_recovery_001", "preflight/execution_jobs/DIAGNOSTICS-PRIMARY-ANY-RECOVERY-001", "preflight/execution_jobs/DIAGNOSTICS-PRIMARY-80", "completion_v2/continued_final_package_004"))
stopifnot(!any(file.exists(new_paths)))

# Retain the original nine source pins and append the exact new versioned leaves.
source_old <- file.path(stage2, "preflight/qualified_continuation_001/primary_diagnostic_source_manifest.csv")
m <- read.csv(source_old, stringsAsFactors = FALSE)
stopifnot(nrow(m) == 9L, all(vapply(m$path, sha, character(1)) == m$sha256))
sources <- c("07_run_primary_diagnostics_v2.R", "run_bounded_job_v4.py", "job_registry_0001.csv")
destinations <- file.path(stage2, c("code/07_run_primary_diagnostics_v2.R", "code/run_bounded_job_v4.py", "preflight/diagnostic_export_recovery_001/job_registry_0001.csv"))
new <- data.frame(path = destinations, bytes = unname(file.info(file.path(root, sources))$size), sha256 = vapply(file.path(root, sources), sha, character(1)))
registry <- read.csv(file.path(root, "job_registry_0001.csv"), stringsAsFactors = FALSE)
gate_rows <- data.frame(path = registry$fit_gate_path, bytes = unname(file.info(registry$fit_gate_path)$size), sha256 = registry$fit_gate_sha256)
source_manifest <- rbind(m, new, gate_rows)
stopifnot(nrow(source_manifest) == 14L, !anyDuplicated(source_manifest$path))
write.csv(source_manifest, file.path(root, "primary_diagnostic_source_manifest.csv"), row.names = FALSE)
copy_map <- data.frame(source_name = c(sources, "primary_diagnostic_source_manifest.csv"), destination = c(destinations, file.path(stage2, "preflight/diagnostic_export_recovery_001/primary_diagnostic_source_manifest.csv")))

# Historical slot accounting stays untouched. This additive allowance is explicit.
allowance <- data.frame(sample_slot = draws$sample_slot, route = draws$route, predictive_seed = draws$predictive_seed, residual_seed = draws$residual_seed, historical_attempted_draws = draws$attempted_draws, historical_exported_draws = draws$durably_exported_draws, maximum_new_attempted_draws = 250L, maximum_logical_final_draws = 250L, maximum_total_attempted_draws_for_slot = draws$attempted_draws + 250L, repetition_reason = ifelse(draws$sample_slot == "B_any", "one_same_seed_export_recovery_not_independent_evidence", "original_unconsumed_slot_only"), authority = "BA-018-DIAGNOSTIC-EXPORT-RECOVERY-001")
stopifnot(sum(allowance$maximum_total_attempted_draws_for_slot) == 1750L, sum(allowance$maximum_logical_final_draws) == 1500L)
write.csv(allowance, file.path(root, "diagnostic_draw_recovery_allowance.csv"), row.names = FALSE)
copy_map <- rbind(copy_map, data.frame(source_name = "diagnostic_draw_recovery_allowance.csv", destination = file.path(stage2, "preflight/diagnostic_export_recovery_001/diagnostic_draw_recovery_allowance.csv")))
copy_map$sha256 <- vapply(file.path(root, copy_map$source_name), sha, character(1))
copy_map$bytes <- unname(file.info(file.path(root, copy_map$source_name))$size)
stopifnot(!anyDuplicated(copy_map$destination), !any(file.exists(copy_map$destination)))
write.csv(copy_map, file.path(root, "exact_owner_copy_map.csv"), row.names = FALSE)
summary <- data.frame(owner = 223, stop = 271, qualified_dispatch = 254, estimands = 23, stage1 = 89, protected = 2287, finalization = 20, historical_jobs = 8, failures_preserved = 3, cumulative_seconds = runtime, historical_attempted_draws = 250, new_repeat_allowance = 250, maximum_attempted_draws = 1750, maximum_logical_final_draws = 1500, total_seconds_limit = 1200, scientific_execution_in_audit = FALSE)
write.csv(summary, file.path(root, "release_preflight_summary.csv"), row.names = FALSE)
pins <- unique(c(unlist(lapply(all_rows, function(x) x$path), use.names = FALSE), p$path, source_old, unlist(lapply(c("DIAGNOSTICS-PRIMARY-ANY", "DERIVE-PRIMARY-ESTIMANDS", "DERIVE-PRIMARY-ESTIMANDS-V2"), function(j) file.path(stage2, "preflight/execution_jobs", j, c("start.json", "finish.json", "execution.log"))))))
write.csv(data.frame(path = pins, sha256 = vapply(pins, sha, character(1)), bytes = unname(file.info(pins)$size)), file.path(root, "all_current_input_pins.csv"), row.names = FALSE)
writeLines(c("Independent R 4.6.1 release preflight. Checksums and stored gate/accounting fields only. No model RDS was loaded, no prediction, draw, fit, estimand or diagnostic was calculated.", capture.output(sessionInfo())), file.path(root, "input_verification_session.txt"))
cat("BA018_RECOVERY_INPUTS=PASS owner=223 stop=271 prior_dispatch=254 estimands=23 stage1=89 protected=2287 finalization=20 jobs=8 failures=3 source_manifest=14 copies=5\n")
