options(warn = 2, stringsAsFactors = FALSE)
stopifnot(getRversion() == "4.6.1")
d <- "audit/decisions/brown_main_linkage_b_stage2_m1_coverage_gate_stop_001"
tmp <- "/private/tmp/ba018-m1-coverage-review.RaumiZ"
root <- "/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026/audit/analyses/brown_adherence/main_linkage_b_amendment/stage2"
stopped <- file.path(root, "completion_v2/continued_final_package_002")
hash <- function(p) unname(digest::digest(file = p, algo = "sha256", serialize = FALSE))
out <- file.path(d, "independent_manifest.csv")
stopifnot(!file.exists(out), !dir.exists(file.path(d, "independent_audit")))
sm <- file.path(stopped, "final_manifest.csv")
stopifnot(hash(sm) == "5753221dd6a001c1715e2ba8e3e34ec2a83976e6d4ed0f637fa2cf3ac22baa80")
m <- read.csv(sm)
stopifnot(nrow(m) == 182L, !anyDuplicated(m$path), !sm %in% m$path,
          all(vapply(m$path, hash, character(1)) == m$sha256), all(file.info(m$path)$size == m$bytes))
final <- read.csv(file.path(stopped, "finalization_checks.csv"))
check <- read.csv(file.path(tmp, "independent_checks.csv"))
stopifnot(nrow(final) == 16L, all(final$pass), nrow(check) == 18L, all(check$pass))
p <- read.csv(file.path(stopped, "protected_identity_verification.csv"))
u <- unique(p[c("path", "expected_sha256", "expected_bytes")])
stopifnot(nrow(p) == 4533L, nrow(u) == 2287L, !anyDuplicated(u$path))
u$independent_sha256 <- unname(vapply(u$path, hash, character(1)))
u$independent_bytes <- as.numeric(file.info(u$path)$size)
u$pass <- u$independent_sha256 == u$expected_sha256 & u$independent_bytes == u$expected_bytes
stopifnot(all(u$pass))
stopifnot(dir.create(file.path(d, "independent_audit")))
f <- list.files(tmp, full.names = TRUE)
stopifnot(all(file.copy(f, file.path(d, "independent_audit"), overwrite = FALSE)))
write.csv(u, file.path(d, "protected_independent_verification.csv"), row.names = FALSE)
writeLines(c("Fresh read-only /bin/ps -p 70118 -o pid=,ppid=,state=,comm= returned exit 1 and no output. PID absent. No termination.",
             "The scientific child is also recorded as reaped in the sealed finish.json; the computation lock is absent.", capture.output(sessionInfo())),
           file.path(d, "process_and_session.txt"))
paths <- unique(c(list.files(d, recursive = TRUE, full.names = TRUE), m$path, list.files(stopped, full.names = TRUE),
                  "audit/decisions/brown_adherence_main_linkage_b_stage2_transition.md",
                  "audit/decisions/brown_main_linkage_b_stage2_estimand_bookkeeping_recovery_001/decision.md",
                  "audit/decisions/brown_main_linkage_b_stage2_estimand_bookkeeping_recovery_001/dispatch_manifest.csv",
                  "audit/decisions/brown_main_linkage_b_stage2_estimand_bookkeeping_recovery_001/dispatch_receipt_manifest.csv"))
stopifnot(!anyDuplicated(normalizePath(paths)), !normalizePath(out, mustWork = FALSE) %in% normalizePath(paths), all(Sys.readlink(paths) == ""))
write.csv(data.frame(path = paths, sha256 = unname(vapply(paths, hash, character(1))), bytes = as.numeric(file.info(paths)$size)), out, row.names = FALSE)
again <- read.csv(out)
stopifnot(all(vapply(again$path, hash, character(1)) == again$sha256), all(file.info(again$path)$size == again$bytes))
cat(sprintf("BA018_SCIENTIFIC_STOP_DISPOSITION=PASS owner=182/182 estimands=23/23 audit=18/18 protected=2287/2287 rows=%d disposition=%s seal=%s\n", nrow(again), hash(file.path(d, "disposition.md")), hash(out)))
