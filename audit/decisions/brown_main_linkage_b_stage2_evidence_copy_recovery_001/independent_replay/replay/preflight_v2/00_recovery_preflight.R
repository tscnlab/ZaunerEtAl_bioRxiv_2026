# Rehash continuation authority and immutable files without analytical execution.
options(warn = 2, stringsAsFactors = FALSE)
stopifnot(getRversion() == "4.6.1")
central <- "/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026"
owner <- "/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026/audit/analyses/brown_adherence/main_linkage_b_amendment/stage2"
out <- "/private/tmp/brown-ba018-recovery-preflight.OEYevX"
recovery <- file.path(central, "audit/decisions/brown_main_linkage_b_stage2_derivative_gate_recovery_001")
confirmation <- file.path(central, "audit/decisions/brown_main_linkage_b_stage2_author_confirmation_2026_09_12")
hash <- function(path) unname(digest::digest(file = path, algo = "sha256", serialize = FALSE))
absolute <- function(path) ifelse(startsWith(path, "/"), path, file.path(central, path))
authority <- data.frame(
  path = c(file.path(confirmation, "decision.md"), file.path(confirmation, "dispatch_message.md"), file.path(confirmation, "dispatch_manifest.csv"), file.path(recovery, "release_manifest.csv")),
  sha256 = c("27effcf84d1683a9571266dcb17260e5869a256d551de2ab0a816e29fabc7097", "588f560349c40e93893972f00f7d193d10c7aa668b76534bee0085369f4cd9f5", "be96d9e2b65ebbbc49cb9e7a6628418261f040f985258ff617036a258fa046c9", "4ae35e66ff3218e61ef3dc379b772fe4e4885bde62d54bf1ea67cd9f0b28f1dd"),
  bytes = c(6417, 2536, 3886, 24229)
)
authority$actual_sha256 <- vapply(authority$path, hash, character(1))
authority$actual_bytes <- unname(file.info(authority$path)$size)
authority$pass <- authority$sha256 == authority$actual_sha256 & authority$bytes == authority$actual_bytes
write.csv(authority, file.path(out, "authority_rehash.csv"), row.names = FALSE)
stopifnot(all(authority$pass))
specs <- data.frame(
  group = c("confirmation", "recovery_release", "historical_rejected_dispatch", "stopped", "execution_inputs", "historical_protected", "stage1", "implementation"),
  path = c(file.path(confirmation, "dispatch_manifest.csv"), file.path(recovery, "release_manifest.csv"), file.path(recovery, "dispatch_manifest.csv"), file.path(recovery, "independent_replay/stopped_file_inventory.csv"), file.path(central, "audit/decisions/brown_main_linkage_b_stage2_release/execution_input_pins.csv"), file.path(recovery, "independent_replay/protected_rehash.csv"), file.path(recovery, "independent_replay/stage1_rehash.csv"), file.path(recovery, "independent_replay/implementation_rehash.csv")),
  expected = c(22L, 96L, 7L, 56L, 2174L, 2066L, 89L, 23L)
)
result <- lapply(seq_len(nrow(specs)), function(i) {
  manifest <- read.csv(specs$path[[i]])
  stopifnot(nrow(manifest) == specs$expected[[i]], all(c("path", "sha256", "bytes") %in% names(manifest)), !anyDuplicated(manifest$path))
  paths <- absolute(manifest$path)
  stopifnot(!normalizePath(specs$path[[i]]) %in% normalizePath(paths, mustWork = FALSE))
  exists <- file.exists(paths) & !dir.exists(paths)
  actual <- rep(NA_character_, length(paths))
  actual[exists] <- vapply(paths[exists], hash, character(1))
  size <- unname(file.info(paths)$size)
  data.frame(group = specs$group[[i]], path = paths, expected_sha256 = manifest$sha256, expected_bytes = manifest$bytes, observed_sha256 = actual, observed_bytes = size, pass = exists & !is.na(actual) & actual == manifest$sha256 & size == manifest$bytes)
})
rows <- do.call(rbind, result)
write.csv(rows, file.path(out, "complete_identity_rehash.csv"), row.names = FALSE)
summary <- do.call(rbind, lapply(result, function(x) data.frame(group = x$group[[1L]], members = nrow(x), exact = sum(x$pass), pass = all(x$pass))))
write.csv(summary, file.path(out, "preflight_summary.csv"), row.names = FALSE)
new_paths <- file.path(owner, c("code/05_saved_derivative_gate_v2.R", "code/02_fit_primary_gate_v2.R", "likelihood/derivative_gate_recovery_v2", "completion_v2"))
state <- data.frame(path = c(new_paths, file.path(owner, "preflight/computation.lock")), absent = !file.exists(c(new_paths, file.path(owner, "preflight/computation.lock"))))
write.csv(state, file.path(out, "unconsumed_path_state.csv"), row.names = FALSE)
writeLines(c("Read-only identity preflight. No data, likelihood, derivative, frame, model, optimizer, draw or report execution.", "Command: Rscript --vanilla /private/tmp/brown-ba018-recovery-preflight.OEYevX/00_recovery_preflight.R", paste("digest", packageVersion("digest")), capture.output(sessionInfo())), file.path(out, "session.txt"))
print(summary, row.names = FALSE)
print(state, row.names = FALSE)
stopifnot(all(rows$pass), all(state$absent))
cat("BA018_RECOVERY_PREFLIGHT=PASS\n")
