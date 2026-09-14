options(warn = 2, stringsAsFactors = FALSE)
stopifnot(getRversion() == "4.6.1")
root <- normalizePath(getwd(), mustWork = TRUE)
out <- "/private/tmp/brown-author-reconfirmation.nEph0q"
release <- "audit/decisions/brown_main_linkage_b_stage2_derivative_gate_recovery_001"
owner <- "/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026/audit/analyses/brown_adherence/main_linkage_b_amendment/stage2"
absolute <- function(p) ifelse(startsWith(p, "/"), p, file.path(root, p))
hash <- function(p) digest::digest(file = p, algo = "sha256", serialize = FALSE)
specs <- data.frame(name = c("release", "dispatch", "stopped", "inputs", "protected", "stage1", "implementation"),
 path = c(file.path(release, "release_manifest.csv"), file.path(release, "dispatch_manifest.csv"),
 file.path(release, "independent_replay/stopped_file_inventory.csv"),
 "audit/decisions/brown_main_linkage_b_stage2_release/execution_input_pins.csv",
 file.path(release, "independent_replay/protected_rehash.csv"),
 file.path(release, "independent_replay/stage1_rehash.csv"),
 file.path(release, "independent_replay/implementation_rehash.csv")), expected = c(96L, 7L, 56L, 2174L, 2066L, 89L, 23L))
rows <- do.call(rbind, lapply(seq_len(nrow(specs)), function(i) {
 m <- read.csv(specs$path[[i]])
 stopifnot(nrow(m) == specs$expected[[i]], all(c("path", "sha256", "bytes") %in% names(m)), !anyDuplicated(m$path))
 full <- absolute(m$path)
 exists <- file.exists(full) & !dir.exists(full)
 observed <- rep(NA_character_, nrow(m))
 observed[exists] <- vapply(full[exists], hash, character(1))
 data.frame(group = specs$name[[i]], path = m$path, expected_sha256 = m$sha256, expected_bytes = m$bytes, observed_sha256 = observed, observed_bytes = unname(file.info(full)$size), exact = exists & !is.na(observed) & observed == m$sha256 & file.info(full)$size == m$bytes)
}))
write.csv(rows, file.path(out, "brown_readiness_identity_rehash.csv"), row.names = FALSE)
summary <- do.call(rbind, lapply(specs$name, function(g) { z <- rows[rows$group == g, ]; data.frame(group = g, rows = nrow(z), exact = sum(z$exact), unexpected = sum(!z$exact)) }))
write.csv(summary, file.path(out, "brown_readiness_summary.csv"), row.names = FALSE)
new_paths <- file.path(owner, c("code/05_saved_derivative_gate_v2.R", "code/02_fit_primary_gate_v2.R", "likelihood/derivative_gate_recovery_v2", "completion_v2"))
write.csv(data.frame(path = new_paths, absent = !file.exists(new_paths)), file.path(out, "brown_unconsumed_path_state.csv"), row.names = FALSE)
writeLines(c("Read-only file-identity readiness audit only. No Brown fit, derivative, likelihood, frame, compiler, data-dependent calculation, source mutation, job restart or render.",
 "The previous tool dispatch remains historically rejected. A later direct author message says can you continue? after the fitting hold; the coordinator is recording that new confirmation separately. This read-only audit itself grants no execution authority.", capture.output(sessionInfo())), file.path(out, "brown_readiness_session.txt"))
print(summary, row.names = FALSE)
stopifnot(all(rows$exact), all(!file.exists(new_paths)))
cat("BROWN_READONLY_READINESS=PASS all_frozen_groups_exact new_code_and_completion_absent scientific_dispatch=held\n")
