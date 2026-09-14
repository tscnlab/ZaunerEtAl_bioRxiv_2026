options(warn = 2, stringsAsFactors = FALSE)
stopifnot(getRversion() == "4.6.1")
d <- "audit/decisions/brown_main_linkage_b_stage2_estimand_bookkeeping_recovery_001"
tmp <- "/private/tmp/ba018-estimand-driver-audit.0nN7uE"
stage2 <- "/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026/audit/analyses/brown_adherence/main_linkage_b_amendment/stage2"
hash <- function(p) unname(digest::digest(file = p, algo = "sha256", serialize = FALSE))
out <- file.path(d, "dispatch_manifest.csv")
stopifnot(!file.exists(out), !dir.exists(file.path(d, "independent_replay")))
stop_root <- file.path(stage2, "completion_v2/continued_final_package_001")
stop_manifest <- file.path(stop_root, "final_manifest.csv")
stopifnot(hash(stop_manifest) == "b15ce21db75fe4eaab7a2f74019611bbe4048a4172626a6cc1fba563fce23067")
m <- read.csv(stop_manifest)
stopifnot(nrow(m) == 133L, !anyDuplicated(m$path), !stop_manifest %in% m$path,
          all(vapply(m$path, hash, character(1)) == m$sha256), all(file.info(m$path)$size == m$bytes))
r <- read.csv(file.path(tmp, "independent_checks.csv"))
s <- read.csv(file.path(tmp, "supervisor_checks.csv"))
p <- read.csv(file.path(tmp, "protected_independent_verification.csv"))
stopifnot(nrow(r) == 29L, all(r$pass), nrow(s) == 19L, all(s$pass == "True"), nrow(p) == 2287L, all(p$pass),
          all(vapply(p$path, hash, character(1)) == p$expected_sha256), all(file.info(p$path)$size == p$expected_bytes))
names_code <- c("06_derive_primary_estimands_v2.R", "run_bounded_job_v2.py")
sha_code <- c("729ce699c57d9ab91cc16668c074742cc4929035102a079866390291964037ba", "1d108833c89ac2815b01075db8d43a1f527c4fabdd09968c4f89a77efe4f1698")
stopifnot(all(vapply(file.path(tmp, names_code), hash, character(1)) == sha_code),
          identical(as.numeric(file.info(file.path(tmp, names_code))$size), c(14641, 6103)),
          !any(file.exists(file.path(stage2, "code", names_code))),
          !any(file.exists(file.path(stage2, c("estimands", "multiplicity", "completion_v2/continued_final_package_002", "preflight/execution_jobs/DERIVE-PRIMARY-ESTIMANDS-V2", "preflight/computation.lock")))))
stopifnot(dir.create(file.path(d, "prospective_code")), dir.create(file.path(d, "independent_replay")))
stopifnot(all(file.copy(file.path(tmp, names_code), file.path(d, "prospective_code"), overwrite = FALSE)))
stopifnot(all(file.copy(list.files(tmp, full.names = TRUE), file.path(d, "independent_replay"), recursive = TRUE, overwrite = FALSE)))
source_files <- list.files(tmp, full.names = TRUE, recursive = TRUE)
rel <- substring(source_files, nchar(tmp) + 2L)
copied <- file.path(d, "independent_replay", rel)
copy_check <- data.frame(relative_path = rel, sha256 = unname(vapply(source_files, hash, character(1))), bytes = as.numeric(file.info(source_files)$size))
stopifnot(all(file.exists(copied)), all(vapply(copied, hash, character(1)) == copy_check$sha256), all(file.info(copied)$size == copy_check$bytes))
write.csv(copy_check, file.path(d, "independent_replay_copy_inventory.csv"), row.names = FALSE)
writeLines(c("R 4.6.1 independent stop and synthetic replay: 133/133 stopped, 2287/2287 protected unique files, 29/29 driver and 19/19 mocked supervisor checks.",
             "Air command passed: /Users/zauner/.local/bin/air format --check /private/tmp/ba018-estimand-driver-audit.0nN7uE/06_derive_primary_estimands_v2.R",
             "No actual model, TMB/DLL, research data, scientific output or author file was evaluated or changed by the audit.", capture.output(sessionInfo())),
           file.path(d, "scope_and_session.txt"))
authority <- c(
  "audit/decisions/brown_adherence_main_linkage_b_stage2_transition.md",
  "audit/decisions/brown_main_linkage_b_stage2_derivative_gate_recovery_001.md",
  "audit/decisions/brown_main_linkage_b_stage2_author_confirmation_2026_09_12/decision.md",
  "audit/decisions/brown_main_linkage_b_stage2_author_confirmation_2026_09_12/dispatch_receipt_manifest.csv",
  "audit/decisions/brown_main_linkage_b_stage2_evidence_copy_recovery_001/decision.md",
  "audit/decisions/brown_main_linkage_b_stage2_evidence_copy_recovery_001/dispatch_manifest.csv")
paths <- unique(c(list.files(d, recursive = TRUE, full.names = TRUE), m$path,
                  list.files(stop_root, full.names = TRUE), authority))
stopifnot(all(file.exists(paths)), all(!dir.exists(paths)), all(Sys.readlink(paths) == ""),
          !anyDuplicated(normalizePath(paths)), !normalizePath(out, mustWork = FALSE) %in% normalizePath(paths))
seal <- data.frame(path = paths, sha256 = unname(vapply(paths, hash, character(1))), bytes = as.numeric(file.info(paths)$size))
write.csv(seal, out, row.names = FALSE)
again <- read.csv(out)
stopifnot(all(vapply(again$path, hash, character(1)) == again$sha256), all(file.info(again$path)$size == again$bytes))
cat(sprintf("BA018_ESTIMAND_RECOVERY_SEAL=PASS rows=%d/%d decision=%s manifest=%s\n", nrow(again), nrow(again), hash(file.path(d, "decision.md")), hash(out)))
