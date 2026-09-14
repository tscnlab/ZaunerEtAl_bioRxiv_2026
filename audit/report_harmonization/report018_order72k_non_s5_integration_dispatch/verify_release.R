options(stringsAsFactors = FALSE)
stopifnot(getRversion() == "4.6.1")
root <- normalizePath(getwd(), mustWork = TRUE)
out <- file.path(root, "audit/report_harmonization/report018_order72k_non_s5_integration_dispatch")
release <- file.path(root, "audit/report_harmonization/report018_order72k_non_s5_integration_release")
sha <- function(path) {
  con <- file(path, "rb")
  on.exit(close(con))
  unname(unclass(as.character(openssl::sha256(con))))
}
resolve <- function(path) if (startsWith(path, "/")) path else file.path(root, path)
specs <- data.frame(
  file = c("release_manifest.csv", "integration_input_pins.csv", "dispatch_manifest.csv"),
  hash = c("07ca15e8d42663c12a2ce5d1ea5d724ee7ecf7480efe2e767654061b8ab9433d", "af995052b2c58e531a1e710a09942dcee275aca93433aff3d89533ce52b2c340", "c1f3921d85b83f6adee86362c7d16730e7a8c8a576ee6bde34d36fbc215fa8f1"),
  rows = c(216L, 186L, 6L)
)
checks <- lapply(seq_len(nrow(specs)), function(i) {
  filename <- file.path(release, specs$file[i])
  stopifnot(identical(sha(filename), specs$hash[i]))
  pins <- read.csv(filename, check.names = FALSE)
  stopifnot(nrow(pins) == specs$rows[i], !anyDuplicated(pins$path))
  paths <- vapply(pins$path, resolve, character(1))
  hashes <- vapply(paths, sha, character(1))
  bytes <- as.numeric(file.info(paths)$size)
  result <- data.frame(manifest = specs$file[i], path = pins$path,
    expected_sha256 = pins$sha256, observed_sha256 = unname(hashes),
    expected_bytes = pins$bytes, observed_bytes = bytes,
    status = ifelse(unname(hashes) == pins$sha256 & bytes == pins$bytes, "PASS", "FAIL"))
  stopifnot(all(result$status == "PASS"))
  result
})
roots <- file.path(root, c(
  "audit/manuscript_nature_health/consolidated_display_repair_2026_09_11/integration_candidate_order72k",
  "audit/manuscript_nature_health/revision_2026_09_11/consolidated_display_repair_order72k"
))
stopifnot(!any(file.exists(roots)))
write.csv(do.call(rbind, checks), file.path(out, "predispatch_rehash.csv"), row.names = FALSE)
writeLines(c(paste("Command: RENV_CONFIG_AUTOLOADER_ENABLED=FALSE Rscript --vanilla", "audit/report_harmonization/report018_order72k_non_s5_integration_dispatch/verify_release.R"),
  paste("Candidate roots absent:", paste(roots, collapse = "; ")),
  capture.output(sessionInfo())), file.path(out, "predispatch_session.txt"))
cat("ORDER72K_PREDISPATCH=PASS rehashes=408 candidate_roots_absent=2\n")
