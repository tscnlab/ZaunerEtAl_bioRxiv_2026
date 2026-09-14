options(stringsAsFactors = FALSE)
stopifnot(getRversion() == "4.6.1")
root <- normalizePath(getwd(), mustWork = TRUE)
out <- file.path(root, "audit/report_harmonization/report018_order72k_non_s5_integration_dispatch")
release <- "audit/report_harmonization/report018_order72k_s2_capture_recovery_001/"
original <- "audit/report_harmonization/report018_order72k_non_s5_integration_release/"
owner <- "audit/manuscript_nature_health/revision_2026_09_11/consolidated_display_repair_order72k/"
sha <- function(path) {
  con <- file(path, "rb")
  on.exit(close(con))
  unname(unclass(as.character(openssl::sha256(con))))
}
resolve <- function(path) if (startsWith(path, "/")) path else file.path(root, path)
specs <- data.frame(
  path = c(paste0(release, c("input_pins.csv", "release_manifest.csv", "dispatch_manifest.csv")),
    paste0(owner, "stopped_owner_manifest.csv"),
    paste0(original, c("release_manifest.csv", "integration_input_pins.csv", "dispatch_manifest.csv")),
    "audit/report_harmonization/report018_order72k_non_s5_integration_dispatch/dependency_closure_pins.csv"),
  sha256 = c("58a345f5903961b75da94bbfcadd29dee2d7e13dae6a41bdcd3c6ddfcf134c17",
    "2d685fddb6af0d8bb1806d400cb0caa85ba248577d55408bae85c83640920687",
    "a7d377af85eea91861a07ed80a042a58addebca545ce554ac03a17a0a21f2b58",
    "445ba04dd59cd3ef1be2d1d7bc625c8b4f8ce3852b97d48a9d80f86c3f667d25",
    "07ca15e8d42663c12a2ce5d1ea5d724ee7ecf7480efe2e767654061b8ab9433d",
    "af995052b2c58e531a1e710a09942dcee275aca93433aff3d89533ce52b2c340",
    "c1f3921d85b83f6adee86362c7d16730e7a8c8a576ee6bde34d36fbc215fa8f1",
    "c43661fc9595057ead1272b9d02a9750c32a43484e4584d6c8d0b3a9fa36a88f"),
  rows = c(72L, 83L, 7L, 263L, 216L, 186L, 6L, 21L))
verified <- lapply(seq_len(nrow(specs)), function(i) {
  path <- resolve(specs$path[i])
  stopifnot(sha(path) == specs$sha256[i])
  pins <- read.csv(path, check.names = FALSE)
  paths <- vapply(pins$path, resolve, character(1))
  observed <- unname(vapply(paths, sha, character(1)))
  bytes <- as.numeric(file.info(paths)$size)
  stopifnot(nrow(pins) == specs$rows[i], !anyDuplicated(pins$path),
    !normalizePath(path) %in% normalizePath(paths),
    all(observed == pins$sha256), all(bytes == pins$bytes))
  data.frame(manifest = specs$path[i], path = pins$path, expected_sha256 = pins$sha256,
    observed_sha256 = observed, expected_bytes = pins$bytes, observed_bytes = bytes)
})
stopifnot(sha(resolve("audit/report_harmonization/owner_orders/72k_s2_capture_environment_recovery_001.md")) ==
  "3399f0aa937333f8ac512b016b742004f6779f82dc6cb13484017e7d9f1cf4e8")
stopped <- read.csv(resolve(paste0(owner, "stopped_owner_manifest.csv")))
capture_files <- list.files(resolve(paste0(owner, "capture_attempt1")), recursive = TRUE, full.names = TRUE, all.files = TRUE, no.. = TRUE)
stopifnot(length(capture_files) == 19L)
relative <- substring(capture_files, nchar(root) + 2L)
idx <- match(relative, stopped$path)
stopifnot(!anyNA(idx), all(unname(vapply(capture_files, sha, character(1))) == stopped$sha256[idx]))
served <- read.csv(resolve(paste0(owner, "stopped_final_checks/served_output_identities.csv")))
stopifnot(nrow(served) == 12L,
  all(unname(vapply(served$source, sha, character(1))) == served$sha256),
  all(unname(vapply(served$served, sha, character(1))) == served$sha256))
stopifnot(!file.exists(resolve(paste0(owner, "capture_s2_attempt2"))),
  !file.exists(resolve(paste0(owner, "capture_s2_attempt3"))),
  dir.exists("/private/tmp/order72k_3ok569jd"),
  identical(Sys.readlink("/private/tmp/order72k_3ok569jd"), ""))
write.csv(do.call(rbind, verified), file.path(out, "s2_recovery_001_predispatch_rehash.csv"), row.names = FALSE)
writeLines(c(
  "Command: RENV_CONFIG_AUTOLOADER_ENABLED=FALSE Rscript --vanilla audit/report_harmonization/report018_order72k_non_s5_integration_dispatch/verify_s2_recovery_001.R",
  "Additional checks: 19 completed capture files; 12 served source/copy pairs; attempt2 and attempt3 destinations absent; task TMPDIR exists and is nonsymlink.",
  capture.output(sessionInfo())), file.path(out, "s2_recovery_001_predispatch_session.txt"))
cat("S2_RECOVERY_001_PREDISPATCH=PASS manifest_rows=854 captures=19 served_pairs=12\n")
