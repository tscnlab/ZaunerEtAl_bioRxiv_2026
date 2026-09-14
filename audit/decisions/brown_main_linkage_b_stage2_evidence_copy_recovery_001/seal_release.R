options(warn = 2, stringsAsFactors = FALSE)
stopifnot(getRversion() == "4.6.1")
d <- "audit/decisions/brown_main_linkage_b_stage2_evidence_copy_recovery_001"
out <- file.path(d, "dispatch_manifest.csv")
tmp <- "/private/tmp/ba018-evidence-copy-audit.NV84BP"
payload <- "/private/tmp/brown-ba018-recovery-preflight.OEYevX"
stage2 <- "/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026/audit/analyses/brown_adherence/main_linkage_b_amendment/stage2"
hash <- function(p) unname(digest::digest(file = p, algo = "sha256", serialize = FALSE))
stopifnot(!file.exists(out), !dir.exists(file.path(d, "preflight_payload")))
stop_manifest <- file.path(stage2, "completion_v2/final_manifest.csv")
stopifnot(hash(stop_manifest) == "cff229763434abfb16a53aca97d990c5da86e8500d7781efd3a13c15b293447d")
m <- read.csv(stop_manifest)
stopifnot(nrow(m) == 24L, all(vapply(m$path, hash, character(1)) == m$sha256), all(file.info(m$path)$size == m$bytes), !anyDuplicated(m$path))
stopifnot(!file.exists(file.path(stage2, "completion_v2/01_complete_preflight_evidence_copy.R")), !file.exists(file.path(stage2, "completion_v2/preflight_v2")))
negative <- read.csv(file.path(tmp, "negative_checks.csv"))
stopifnot(nrow(negative) == 7L, all(negative$rejected_before_write))
script <- file.path(tmp, "01_complete_preflight_evidence_copy.R")
stopifnot(hash(script) == "4814d7ce2559de03c57f3853749fb689f07cf94d87daf0844e688be336fa8302", file.info(script)$size == 4966)
stopifnot(identical(readRDS(file.path(tmp, "prospective_pre_format_ast.rds")), parse(script, keep.source = FALSE)))
for (subdir in c("preflight_payload", "prospective_code", "independent_replay")) stopifnot(dir.create(file.path(d, subdir)))
files <- list.files(payload, full.names = TRUE)
stopifnot(length(files) == 6L, all(file.copy(files, file.path(d, "preflight_payload"), overwrite = FALSE)))
stopifnot(file.copy(file.path(tmp, "preflight_payload_pins.csv"), file.path(d, "preflight_payload_pins.csv"), overwrite = FALSE))
p <- read.csv(file.path(d, "preflight_payload_pins.csv"))
target <- file.path(d, "preflight_payload", p$name)
stopifnot(nrow(p) == 6L, all(vapply(target, hash, character(1)) == p$sha256), all(file.info(target)$size == p$bytes))
stopifnot(file.copy(script, file.path(d, "prospective_code"), overwrite = FALSE))
stopifnot(all(file.copy(list.files(tmp, full.names = TRUE), file.path(d, "independent_replay"), recursive = TRUE, overwrite = FALSE)))
writeLines(c("Independent stop/copy review: 24/24 stopped, 15/15 finalization, 6/6 full temporary copy, 7/7 negative cases, unchanged AST after Air. No owner mutation or scientific execution.", "Air command completed: air format --check /private/tmp/ba018-evidence-copy-audit.NV84BP/01_complete_preflight_evidence_copy.R. Exit 0.", capture.output(sessionInfo())), file.path(d, "release_scope_and_session.txt"))
paths <- unique(c(list.files(d, recursive = TRUE, full.names = TRUE), m$path, stop_manifest,
  file.path(stage2, "completion_v2/final_manifest_verification.csv"),
  "audit/decisions/brown_main_linkage_b_stage2_author_confirmation_2026_09_12/decision.md",
  "audit/decisions/brown_main_linkage_b_stage2_author_confirmation_2026_09_12/dispatch_manifest.csv",
  "audit/decisions/brown_main_linkage_b_stage2_author_confirmation_2026_09_12/dispatch_receipt_manifest.csv",
  "audit/decisions/brown_main_linkage_b_stage2_derivative_gate_recovery_001.md",
  "audit/decisions/brown_adherence_main_linkage_b_stage2_transition.md"))
stopifnot(!out %in% paths, !anyDuplicated(normalizePath(paths)), all(!dir.exists(paths)))
seal <- data.frame(path = paths, sha256 = unname(vapply(paths, hash, character(1))), bytes = as.numeric(file.info(paths)$size))
write.csv(seal, out, row.names = FALSE)
again <- read.csv(out)
stopifnot(all(vapply(again$path, hash, character(1)) == again$sha256), all(file.info(again$path)$size == again$bytes))
cat(sprintf("BA018_COPY_RECOVERY_SEAL=PASS rows=%d/%d decision=%s manifest=%s\n", nrow(again), nrow(again), hash(file.path(d, "decision.md")), hash(out)))
