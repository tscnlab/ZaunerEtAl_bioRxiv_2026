options(stringsAsFactors = FALSE)
stopifnot(getRversion() == "4.6.1")
root <- normalizePath(getwd(), mustWork = TRUE)
owner <- "audit/manuscript_nature_health/revision_2026_09_11/consolidated_display_repair_order72k/"
out <- file.path(root, owner, "environment_capture_recovery_001")
release <- "audit/report_harmonization/report018_order72k_s2_capture_recovery_001/"
original <- "audit/report_harmonization/report018_order72k_non_s5_integration_release/"
sha <- function(p) { con <- file(p, "rb"); on.exit(close(con)); unname(unclass(as.character(openssl::sha256(con)))) }
resolve <- function(p) if (startsWith(p, "/")) p else file.path(root, p)
specs <- data.frame(path = c(paste0(release, c("input_pins.csv", "release_manifest.csv", "dispatch_manifest.csv")), paste0(owner, "stopped_owner_manifest.csv"), paste0(original, c("release_manifest.csv", "integration_input_pins.csv", "dispatch_manifest.csv")), "audit/report_harmonization/report018_order72k_non_s5_integration_dispatch/dependency_closure_pins.csv"), sha256 = c("58a345f5903961b75da94bbfcadd29dee2d7e13dae6a41bdcd3c6ddfcf134c17", "2d685fddb6af0d8bb1806d400cb0caa85ba248577d55408bae85c83640920687", "a7d377af85eea91861a07ed80a042a58addebca545ce554ac03a17a0a21f2b58", "445ba04dd59cd3ef1be2d1d7bc625c8b4f8ce3852b97d48a9d80f86c3f667d25", "07ca15e8d42663c12a2ce5d1ea5d724ee7ecf7480efe2e767654061b8ab9433d", "af995052b2c58e531a1e710a09942dcee275aca93433aff3d89533ce52b2c340", "c1f3921d85b83f6adee86362c7d16730e7a8c8a576ee6bde34d36fbc215fa8f1", "c43661fc9595057ead1272b9d02a9750c32a43484e4584d6c8d0b3a9fa36a88f"), rows = c(72L,83L,7L,263L,216L,186L,6L,21L))
stopifnot(!file.exists(file.path(out, "preflight_854_rows.csv")))
checks <- lapply(seq_len(nrow(specs)), function(i) {
  path <- resolve(specs$path[i]); stopifnot(sha(path) == specs$sha256[i])
  x <- read.csv(path, check.names = FALSE); p <- vapply(x$path, resolve, character(1))
  observed <- vapply(p, sha, character(1)); bytes <- file.info(p)$size
  stopifnot(nrow(x) == specs$rows[i], all(observed == x$sha256), all(bytes == x$bytes), all(Sys.readlink(p) == ""), !anyDuplicated(x$path))
  data.frame(manifest = specs$path[i], path = x$path, expected_sha256 = x$sha256, actual_sha256 = unname(observed), bytes = bytes, exact = TRUE)
})
checks <- do.call(rbind, checks); stopifnot(nrow(checks) == 854L)
stopifnot(sha(resolve("audit/report_harmonization/owner_orders/72k_s2_capture_environment_recovery_001.md")) == "3399f0aa937333f8ac512b016b742004f6779f82dc6cb13484017e7d9f1cf4e8")
captures <- list.files(resolve(paste0(owner, "capture_attempt1")), recursive = TRUE, full.names = TRUE, all.files = TRUE, no.. = TRUE)
stopifnot(length(captures) == 19L)
served <- read.csv(resolve(paste0(owner, "stopped_final_checks/served_output_identities.csv")))
served_root <- resolve(paste0(owner, "preview_attempt1"))
served_actual <- list.files(served_root, recursive = TRUE, full.names = TRUE, all.files = TRUE, no.. = TRUE)
stopifnot(nrow(served) == 12L, setequal(served_actual, served$served), all(Sys.readlink(served_actual) == ""), all(vapply(served$served, sha, character(1)) == served$sha256), all(vapply(served$source, sha, character(1)) == served$sha256))
stopifnot(!file.exists(resolve(paste0(owner, "capture_s2_attempt2"))), !file.exists(resolve(paste0(owner, "capture_s2_attempt3"))), dir.exists("/private/tmp/order72k_3ok569jd"), Sys.readlink("/private/tmp/order72k_3ok569jd") == "", file.info("/private/tmp/order72k_3ok569jd")$uname == Sys.info()[["user"]])
write.csv(checks, file.path(out, "preflight_854_rows.csv"), row.names = FALSE)
write.csv(served, file.path(out, "served_preflight.csv"), row.names = FALSE)
write.csv(data.frame(path = captures, sha256 = vapply(captures, sha, character(1)), bytes = file.info(captures)$size), file.path(out, "completed_captures_before.csv"), row.names = FALSE)
writeLines(c("R 4.6.1 file identity and structure checks only. No analytical computation.", "854 rows exact; 19 completed capture files; 12 immutable served pairs; both correction destinations absent; task TMPDIR owned and nonsymlink.", capture.output(sessionInfo())), file.path(out, "preflight_session.txt"))
cat("PASS: 854 recovery/stopped/original rows; 19 captures; 12 served pairs.\n")
