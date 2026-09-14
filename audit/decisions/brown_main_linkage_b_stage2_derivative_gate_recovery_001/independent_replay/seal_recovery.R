stopifnot(getRversion() == numeric_version("4.6.1"))
shared <- "/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026"
brown <- "/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026"
temp <- "/private/tmp/brown-ba018-derivative-audit.p5VNOC"
stage2 <- file.path(brown, "audit/analyses/brown_adherence/main_linkage_b_amendment/stage2")
release <- file.path(shared, "audit/decisions/brown_main_linkage_b_stage2_derivative_gate_recovery_001")
decision <- paste0(release, ".md")
sha <- function(path) unname(digest::digest(file = path, algo = "sha256", serialize = FALSE))
stopifnot(!dir.exists(release))
stopped <- read.csv(file.path(temp, "stopped_file_inventory.csv"), stringsAsFactors = FALSE)
stopifnot(nrow(stopped) == 56L, !anyDuplicated(stopped$path), all(vapply(stopped$path, sha, "") == stopped$sha256), all(file.info(stopped$path)$size == stopped$bytes))
checks <- read.csv(file.path(temp, "independent_checks.csv"))
negative <- read.csv(file.path(temp, "negative_schema_checks.csv"))
stopifnot(nrow(checks) == 19L, all(checks$status == "PASS"), nrow(negative) == 10L, all(negative$rejected))
code_names <- c("05_saved_derivative_gate_v2.R", "02_fit_primary_gate_v2.R")
expected <- c("25dfbbc1e137cf4924970dec3ad11fb673c4d74fe54511d53dac723e78036b9a", "f0b1cd0dababf36701a0254d3a32f5918f42026525cd7778749fc39d158bff1e")
stopifnot(all(vapply(file.path(temp, code_names), sha, "") == expected))
stopifnot(!any(file.exists(file.path(stage2, "code", code_names))), !dir.exists(file.path(stage2, "likelihood/derivative_gate_recovery_v2")), !dir.exists(file.path(stage2, "completion_v2")), !dir.exists(file.path(stage2, "models")), !file.exists(file.path(stage2, "preflight/computation.lock")))
dir.create(file.path(release, "independent_replay"), recursive = TRUE)
files <- list.files(temp, recursive = TRUE, full.names = TRUE, all.files = TRUE, no.. = TRUE)
files <- files[!file.info(files)$isdir]
for (path in files) {
  target <- file.path(release, "independent_replay", substring(path, nchar(temp) + 2L))
  dir.create(dirname(target), recursive = TRUE, showWarnings = FALSE)
  stopifnot(file.copy(path, target, overwrite = FALSE), sha(target) == sha(path))
}
dir.create(file.path(release, "prospective_code"))
for (name in code_names) {
  target <- file.path(release, "prospective_code", name)
  stopifnot(file.copy(file.path(temp, name), target, overwrite = FALSE), sha(target) == sha(file.path(temp, name)))
}
writeLines(c("Read-only /bin/ps -p 28004,28174 -o pid=,ppid=,stat=,command= returned exit 1 and no rows. Both recorded children are absent. No process was terminated or modified.", "Air format --check passed for both supplied prospective R files; parse and gate-only sandbox execution passed."), file.path(release, "process_and_format_checks.txt"))
write.csv(data.frame(check = c("independent_checks", "negative_schema_cases", "prospective_code_pins", "stopped_history", "new_owner_paths_absent", "no_fit_or_lock", "no_ledger_edit", "one_gate_job_then_original_unconsumed_scope"), result = c("19/19", "10/10", "2/2", "56/56", "PASS", "PASS", "unchanged", "BA018 limits retained"), status = "PASS"), file.path(release, "release_checks.csv"), row.names = FALSE)
own <- list.files(release, recursive = TRUE, full.names = TRUE, all.files = TRUE, no.. = TRUE)
own <- own[!file.info(own)$isdir]
authority <- file.path(shared, c("audit/decisions/brown_adherence_main_linkage_b_stage2_transition.md", "audit/decisions/brown_main_linkage_b_stage2_release/release_manifest.csv", "audit/decisions/brown_main_linkage_b_stage2_release/execution_input_pins.csv", "audit/ledgers/decision_register.csv", "audit/ledgers/change_log.csv"))
members <- sort(unique(c(own, decision, stopped$path, authority)))
stopifnot(!anyDuplicated(members), all(file.exists(members)))
manifest <- data.frame(path = members, sha256 = vapply(members, sha, ""), bytes = as.numeric(file.info(members)$size))
manifest_path <- file.path(release, "release_manifest.csv")
stopifnot(!file.exists(manifest_path), !manifest_path %in% members)
write.csv(manifest, manifest_path, row.names = FALSE)
stopifnot(all(vapply(manifest$path, sha, "") == manifest$sha256), all(file.info(manifest$path)$size == manifest$bytes))
cat("BA018_RECOVERY_RELEASE=PASS members=", nrow(manifest), "/", nrow(manifest), " owner_history=56/56 independent=19/19 negative=10/10 no_science\n", sep="")
for (path in c(decision, manifest_path)) cat(path, "\t", sha(path), "\t", file.info(path)$size, "\n", sep="")
