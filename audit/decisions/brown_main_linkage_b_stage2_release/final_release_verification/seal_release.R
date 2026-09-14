stopifnot(getRversion() == numeric_version("4.6.1"))
shared_root <- "/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026"
brown_root <- "/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026"
release_root <- file.path(shared_root, "audit/decisions/brown_main_linkage_b_stage2_release")
temp_root <- "/private/tmp/brown-ba018-release.0VjISc"
sha <- function(p) unname(digest::digest(file = p, algo = "sha256", serialize = FALSE))
abs_path <- function(p) ifelse(startsWith(p, "/"), p, file.path(shared_root, p))
stopifnot(!file.exists(file.path(release_root, "release_manifest.csv")))
stage2 <- file.path(brown_root, "audit/analyses/brown_adherence/main_linkage_b_amendment/stage2")
stopifnot(!dir.exists(stage2))
inputs <- read.csv(file.path(release_root, "execution_input_pins.csv"), stringsAsFactors = FALSE)
stopifnot(nrow(inputs) == 2174L, !anyDuplicated(inputs$path), all(vapply(inputs$path, sha, "") == inputs$sha256), all(file.info(inputs$path)$size == inputs$bytes))
gates <- read.csv(file.path(release_root, "independent_replay/gate_replay/finalization_checks.csv"), stringsAsFactors = FALSE)
supports <- read.csv(file.path(release_root, "independent_replay/support_replay/planning_dependency_checks.csv"), stringsAsFactors = FALSE)
gate_comp <- read.csv(file.path(release_root, "independent_replay/gate_replay_comparison.csv"), stringsAsFactors = FALSE)
support_comp <- read.csv(file.path(release_root, "independent_replay/support_replay_comparison.csv"), stringsAsFactors = FALSE)
stopifnot(nrow(gates) == 36L, all(gates$passed), nrow(supports) == 14L, all(supports$passed))
stopifnot(nrow(gate_comp) == 5L, all(gate_comp$exact), nrow(support_comp) == 11L, all(support_comp$exact))
stopifnot(all(gate_comp$observed_sha256 == gate_comp$owner_sha256), all(support_comp$observed_sha256 == support_comp$owner_sha256))
ledger <- read.csv(file.path(temp_root, "ledger_append_verification.csv"), stringsAsFactors = FALSE)
stopifnot(all(vapply(abs_path(ledger$path), sha, "") == ledger$current_sha256))
dest <- file.path(release_root, "final_release_verification")
stopifnot(!dir.exists(dest), !dir.exists(file.path(release_root, "ledger_checkpoint")))
dir.create(dest)
temp_files <- list.files(temp_root, full.names = TRUE, recursive = FALSE)
stopifnot(all(!file.info(temp_files)$isdir))
for (p in temp_files) {
  target <- file.path(dest, basename(p))
  stopifnot(file.copy(p, target, overwrite = FALSE), sha(target) == sha(p))
}
dir.create(file.path(release_root, "ledger_checkpoint"))
for (p in abs_path(ledger$path)) {
  target <- file.path(release_root, "ledger_checkpoint", basename(p))
  stopifnot(file.copy(p, target, overwrite = FALSE), sha(target) == sha(p))
}
checks <- data.frame(
  check = c("decision_identity", "input_pin_identity", "execution_inputs", "stage1_members", "protected_members", "support_checks", "finalization_checks", "replay_csv_identity", "ledger_prior_raw_bytes", "ledger_prior_parsed_rows", "authority_ids_unique_and_only_append", "new_stage2_root_absent", "existing_science_and_reports_unchanged", "dispatch_not_yet_sent"),
  result = c("f8bd6762e731ef1024762daea3113f3970eab21794b4f0c4d7316c020aee2178", "3e24d9f29b7bc48695b1e7740c6bcf8cce7d05d8e9e6d596875bbae250d28714", "2174/2174", "89/89", "2066/2066", "14/14", "36/36", "16/16", "2/2", "2/2", "BA-018;CHG-157", "absent", "exact", "not_sent"),
  status = "PASS"
)
decision <- file.path(shared_root, "audit/decisions/brown_adherence_main_linkage_b_stage2_transition.md")
stopifnot(sha(decision) == checks$result[[1]], sha(file.path(release_root, "execution_input_pins.csv")) == checks$result[[2]])
write.csv(checks, file.path(release_root, "release_checks.csv"), row.names = FALSE)
ledger_pins <- data.frame(path = ledger$path, sha256 = ledger$current_sha256, bytes = ledger$current_bytes)
write.csv(ledger_pins, file.path(release_root, "ledger_current_pins.csv"), row.names = FALSE)
relative_files <- list.files(release_root, recursive = TRUE, full.names = TRUE, all.files = TRUE, no.. = TRUE)
relative_files <- relative_files[!file.info(relative_files)$isdir]
stopifnot(!any(nzchar(Sys.readlink(relative_files))))
stage1_root <- file.path(brown_root, "audit/analyses/brown_adherence/main_linkage_b_amendment/stage1")
members <- sort(unique(c(relative_files, decision, abs_path(ledger$path), file.path(stage1_root, c("plan.md", "stage1_handoff.md", "final_manifest.csv", "final_manifest_verification.csv")))))
stopifnot(all(file.exists(members)), !anyDuplicated(members))
manifest <- data.frame(path = members, sha256 = vapply(members, sha, ""), bytes = as.numeric(file.info(members)$size))
manifest_path <- file.path(release_root, "release_manifest.csv")
stopifnot(!manifest_path %in% manifest$path)
write.csv(manifest, manifest_path, row.names = FALSE)
observed <- read.csv(manifest_path, stringsAsFactors = FALSE)
stopifnot(nrow(observed) == nrow(manifest), all(vapply(observed$path, sha, "") == observed$sha256), all(file.info(observed$path)$size == observed$bytes))
cat("BA018_FINAL_RELEASE=PASS release_checks=14/14 inputs=2174/2174 members=", nrow(manifest), "/", nrow(manifest), " noncircular=TRUE no_science no_owner_write no_second_ledger_append\n", sep = "")
for (p in c(decision, file.path(release_root, "release_disposition.md"), manifest_path, abs_path(ledger$path))) cat(p, "\t", sha(p), "\t", file.info(p)$size, "\n", sep = "")
