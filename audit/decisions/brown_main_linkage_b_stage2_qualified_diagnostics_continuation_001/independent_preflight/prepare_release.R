args <- commandArgs(trailingOnly = TRUE)
stopifnot(as.character(getRversion()) == "4.6.1", length(args) == 0L)
scratch <- "/private/tmp/ba018-qualified-continuation.sCpljO"
author <- "/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026"
brown <- "/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026"
stage1 <- file.path(brown, "audit/analyses/brown_adherence/main_linkage_b_amendment/stage1")
stage2 <- file.path(brown, "audit/analyses/brown_adherence/main_linkage_b_amendment/stage2")
stop_root <- file.path(stage2, "completion_v2/continued_final_package_002")
sha <- function(p) unname(digest::digest(p, algo = "sha256", file = TRUE))
resolve <- function(p) ifelse(startsWith(p, "/"), p, file.path(author, p))
checks <- data.frame(check = character(), pass = logical(), detail = character())
check <- function(id, ok, detail = "") {
  checks[nrow(checks) + 1L, ] <<- list(id, isTRUE(ok), detail)
  stopifnot(isTRUE(ok))
}
verify <- function(p, n, hash) {
  check(paste0(basename(dirname(p)), "_manifest_pin"), sha(p) == hash)
  x <- read.csv(p, stringsAsFactors = FALSE)
  full <- resolve(x$path)
  check(paste0(basename(dirname(p)), "_shape"), nrow(x) == n && !anyDuplicated(full) && !p %in% full)
  x$observed_sha256 <- vapply(full, sha, character(1))
  x$observed_bytes <- unname(file.info(full)$size)
  x$exact <- x$sha256 == x$observed_sha256 & x$bytes == x$observed_bytes
  check(paste0(basename(dirname(p)), "_exact"), all(x$exact))
  x
}
owner <- verify(file.path(stop_root, "final_manifest.csv"), 182L, "5753221dd6a001c1715e2ba8e3e34ec2a83976e6d4ed0f637fa2cf3ac22baa80")
utils::write.csv(owner, file.path(scratch, "owner_182_verification.csv"), row.names = FALSE)
central_path <- file.path(author, "audit/decisions/brown_main_linkage_b_stage2_m1_coverage_gate_stop_001/independent_manifest.csv")
central <- verify(central_path, 198L, "db5cc06168c99ec3f0997483357a2cca6c70f3a54fe5673d58510e98822f52b8")
utils::write.csv(central, file.path(scratch, "central_198_verification.csv"), row.names = FALSE)
estimands <- verify(file.path(stage2, "estimands/manifest.csv"), 23L, "baff7f3cb89565235193a2a74dc64afd82a58e3fea3d519c55fce08318d4863a")
utils::write.csv(estimands, file.path(scratch, "estimand_23_verification.csv"), row.names = FALSE)
protected <- read.csv(file.path(stop_root, "protected_identity_verification.csv"), stringsAsFactors = FALSE)
check("protected_group_rows", nrow(protected) == 4533L)
protected <- protected[!duplicated(protected$path), c("path", "expected_sha256", "expected_bytes")]
protected$observed_sha256 <- vapply(protected$path, sha, character(1))
protected$observed_bytes <- unname(file.info(protected$path)$size)
protected$exact <- with(protected, expected_sha256 == observed_sha256 & expected_bytes == observed_bytes)
check("protected_unique_exact", nrow(protected) == 2287L && all(protected$exact))
utils::write.csv(protected, file.path(scratch, "protected_2287_verification.csv"), row.names = FALSE)
validation <- read.csv(file.path(stage2, "estimands/validation.csv"), stringsAsFactors = FALSE)
check("real_gate_remains_failed", sum(validation$pass) == 12L && nrow(validation) == 13L)
job_files <- list.files(file.path(stage2, "preflight/execution_jobs"), full.names = TRUE, recursive = TRUE)
job_inventory <- data.frame(path = job_files, sha256 = vapply(job_files, sha, character(1)), bytes = unname(file.info(job_files)$size))
utils::write.csv(job_inventory, file.path(scratch, "historical_job_pins.csv"), row.names = FALSE)
finishes <- job_files[basename(job_files) == "finish.json"]
jobs <- lapply(finishes, jsonlite::fromJSON)
job_summary <- do.call(rbind, lapply(jobs, function(x) data.frame(job_id = x$job_id, exit_code = x$exit_code, elapsed_seconds = x$elapsed_seconds, timed_out = x$timed_out, child_reaped = x$child_reaped, driver_sha256 = x$driver_sha256, supervisor_sha256 = x$supervisor_sha256)))
check("seven_consumed_jobs", nrow(job_summary) == 7L && all(job_summary$child_reaped) && !any(job_summary$timed_out))
check("exact_two_stopped_jobs", setequal(job_summary$job_id[job_summary$exit_code != 0L], c("DERIVE-PRIMARY-ESTIMANDS", "DERIVE-PRIMARY-ESTIMANDS-V2")))
check("runtime_not_reset", abs(sum(job_summary$elapsed_seconds) - 99.408186624990776) < 1e-10)
check("no_computation_lock", !file.exists(file.path(stage2, "preflight/computation.lock")))
utils::write.csv(job_summary, file.path(scratch, "historical_job_summary.csv"), row.names = FALSE)
critical <- c(file.path(stage2, c("models/BA-LB-PRIMARY-ANY.rds", "models/BA-LB-PRIMARY-80.rds", "estimands/manifest.csv", "estimands/boundary_estimands.rds", "estimands/validation.csv", "estimands/B_to_B80_claim_gate.csv")), file.path(stop_root, "final_manifest.csv"), central_path)
critical_pins <- data.frame(path = critical, sha256 = vapply(critical, sha, character(1)), bytes = unname(file.info(critical)$size))
utils::write.csv(critical_pins, file.path(scratch, "critical_pins.csv"), row.names = FALSE)
planned <- read.csv(file.path(stage1, "prospective_model_jobs.csv"), stringsAsFactors = FALSE)
planned <- planned[!planned$job_id %in% c("PRIMARY-ANY", "PRIMARY-80"), ]
check("exact_remaining_nominal_model_slots", nrow(planned) == 28L)
utils::write.csv(planned, file.path(scratch, "remaining_nominal_model_jobs.csv"), row.names = FALSE)
old_path <- file.path(stage2, "code/run_bounded_job_v2.py")
check("old_supervisor_pin", sha(old_path) == "1d108833c89ac2815b01075db8d43a1f527c4fabdd09968c4f89a77efe4f1698")
old <- paste0(paste(readLines(old_path, warn = FALSE), collapse = "\n"), "\n")
start <- regexpr('recovery_job_id = ', old, fixed = TRUE)[1]
end <- regexpr('used = 0.0\n', old, fixed = TRUE)[1]
old_prefix <- substr(old, start, end - 1L)
pin_map <- function(paths, indent = "    ") paste(vapply(paths, function(p) sprintf('%s%s: %s,', indent, encodeString(p, quote = '"'), encodeString(sha(p), quote = '"')), character(1)), collapse = "\n")
allowed <- c(planned$job_id, "SENS-EXCLUDE-ZERO-NOZERO", as.vector(outer(c("TEMPORAL-ANY", "TEMPORAL-80"), c("ENDPOINT-R3", "BB-R0", "BB-R3"), paste, sep = "-")))
new_prefix <- paste0(
  '# Author-approved qualified diagnostics/sensitivities only. Neither failed job becomes PASS.\n',
  'assert not job_id.startswith(("PRIMARY-", "DERIVE-PRIMARY-ESTIMANDS")), "Completed primary fits and estimands are frozen."\n',
  'assert driver_path.name not in {"00_preflight.R", "01_validate_and_prepare.R", "02_fit_primary.R", "02_fit_primary_gate_v2.R", "03_audit_derivative_gate_stop.R", "04_seal_prefit_stop.R", "05_saved_derivative_gate_v2.R", "06_derive_primary_estimands.R", "06_derive_primary_estimands_v2.R"}, "No consumed scientific driver may rerun."\n',
  'allowed_fit_jobs = {\n', paste(sprintf('    "%s",', allowed), collapse = "\n"), '\n}\n',
  'allowed_support_prefixes = ("DIAGNOSTICS-", "CONSTRUCT-CHEST-", "CONSTRUCT-CALENDAR-", "SCREEN-INFLUENCE-", "DERIVE-SENSITIVITY-", "VERIFY-SENSITIVITY-", "COMPARE-SENSITIVITY-")\n',
  'assert job_id in allowed_fit_jobs or job_id.startswith(allowed_support_prefixes), "Job is outside this diagnostic/sensitivity continuation."\n',
  'frozen_continuation_inputs = {\n', pin_map(critical), '\n}\n',
  'for frozen_path, expected_hash in frozen_continuation_inputs.items():\n',
  '    assert hashlib.sha256(Path(frozen_path).read_bytes()).hexdigest() == expected_hash, "A frozen scientific stop or primary output changed."\n',
  'for required_job in ("DERIVE-PRIMARY-ESTIMANDS", "DERIVE-PRIMARY-ESTIMANDS-V2"):\n',
  '    assert (jobs_root / required_job / "finish.json").is_file(), "Both preserved failed jobs must remain in the accumulator."\n'
)
next_start <- regexpr('    if previous.name == "DERIVE-PRIMARY-ESTIMANDS":', old, fixed = TRUE)[1]
next_end <- regexpr('    used += record["elapsed_seconds"]', old, fixed = TRUE)[1]
old_block <- substr(old, next_start, next_end - 1L)
new_blocks <- vapply(c("DERIVE-PRIMARY-ESTIMANDS", "DERIVE-PRIMARY-ESTIMANDS-V2"), function(id) {
  j <- jobs[[which(vapply(jobs, function(x) x$job_id == id, logical(1)))]]
  files <- file.path(stage2, "preflight/execution_jobs", id, c("start.json", "finish.json", "execution.log"))
  fields <- paste(sprintf('            "%s": "%s",', basename(files), vapply(files, sha, character(1))), collapse = "\n")
  paste0(if (id == "DERIVE-PRIMARY-ESTIMANDS") '    if ' else '    elif ', 'previous.name == "', id, '":\n',
    '        historical_pins = {\n', fields, '\n        }\n',
    '        for name, expected_sha256 in historical_pins.items():\n',
    '            assert hashlib.sha256((previous / name).read_bytes()).hexdigest() == expected_sha256\n',
    '        assert record["job_id"] == previous.name\n',
    '        assert record["driver_sha256"] == "', j$driver_sha256, '"\n',
    '        assert record["supervisor_sha256"] == "', j$supervisor_sha256, '"\n',
    '        assert record["exit_code"] == 1 and not record["timed_out"] and record["child_reaped"]\n',
    '        assert record["elapsed_seconds"] == ', sprintf("%.17g", j$elapsed_seconds), '\n')
}, character(1))
new_block <- paste0(paste(new_blocks, collapse = ""), '    else:\n        assert record["exit_code"] == 0 and not record["timed_out"] and record["child_reaped"], "A new failed execution requires a separate recovery decision."\n')
prospective <- sub(old_prefix, new_prefix, old, fixed = TRUE)
prospective <- sub(old_block, new_block, prospective, fixed = TRUE)
reverse <- sub(new_prefix, old_prefix, prospective, fixed = TRUE)
reverse <- sub(new_block, old_block, reverse, fixed = TRUE)
check("exact_two_block_reverse", identical(reverse, old))
writeChar(prospective, file.path(scratch, "run_bounded_job_v3.py"), eos = NULL, useBytes = TRUE)
writeChar(reverse, file.path(scratch, "reconstructed_run_bounded_job_v2.py"), eos = NULL, useBytes = TRUE)
check("reverse_file_hash", sha(file.path(scratch, "reconstructed_run_bounded_job_v2.py")) == sha(old_path))
utils::write.csv(checks, file.path(scratch, "independent_checks.csv"), row.names = FALSE)
writeLines(c("R 4.6.1. Read-only file, job-ledger and stored-check audit.", "No model/RDS/objective/prediction/diagnostic or scientific driver loaded or run.", "Supervisor preparation is mechanical infrastructure only.", capture.output(sessionInfo())), file.path(scratch, "audit_scope_and_session.txt"))
cat(sprintf("BA018_QUALIFIED_CONTINUATION_PREFLIGHT=PASS checks=%s owner=182 central=198 estimands=23 protected=2287 jobs=7 seconds=%.15f supervisor=%s\n", nrow(checks), sum(job_summary$elapsed_seconds), sha(file.path(scratch, "run_bounded_job_v3.py"))))
