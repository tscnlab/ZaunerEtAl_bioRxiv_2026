options(stringsAsFactors = FALSE)
stopifnot(getRversion() == "4.6.1")
root <- normalizePath(getwd(), mustWork = TRUE)
out <- file.path(root, "audit/report_harmonization/report018_order72k_non_s5_integration_dispatch")
release <- file.path(root, "audit/report_harmonization/report018_order72k_environment_cache_recovery_001")
sha <- function(path) {
  con <- file(path, "rb")
  on.exit(close(con))
  unname(unclass(as.character(openssl::sha256(con))))
}
resolve <- function(path) if (startsWith(path, "/")) path else file.path(root, path)
specs <- data.frame(
  file = c("release_manifest.csv", "environment_input_pins.csv", "dispatch_manifest.csv"),
  hash = c("87f2c204e95fb05c8faab14dfca06ea65c8d13040fc65edd497a2637282ad471", "d109efc0ed9b6169f4786475da448d360b45a99617ac79cf18e64619cb33aefd", "50f83361597d370b5eeab89f53c55cd8f8467d7cb1009a2f56568b576765bfae"),
  rows = c(198L, 175L, 7L)
)
checks <- lapply(seq_len(nrow(specs)), function(i) {
  filename <- file.path(release, specs$file[i])
  stopifnot(identical(sha(filename), specs$hash[i]))
  pins <- read.csv(filename, check.names = FALSE)
  stopifnot(nrow(pins) == specs$rows[i], !anyDuplicated(pins$path))
  paths <- vapply(pins$path, resolve, character(1))
  stopifnot(!normalizePath(filename) %in% normalizePath(paths))
  hashes <- unname(vapply(paths, sha, character(1)))
  bytes <- as.numeric(file.info(paths)$size)
  result <- data.frame(manifest = specs$file[i], path = pins$path,
    expected_sha256 = pins$sha256, observed_sha256 = hashes,
    expected_bytes = pins$bytes, observed_bytes = bytes,
    status = ifelse(hashes == pins$sha256 & bytes == pins$bytes, "PASS", "FAIL"))
  stopifnot(all(result$status == "PASS"))
  result
})
stopifnot(sha(file.path(root, "audit/report_harmonization/owner_orders/72k_environment_cache_recovery_001.md")) ==
  "3001ae31f934579937124f9f2087e2d8f57ef5a5a674f538bd5d4d107d9a308a")
write.csv(do.call(rbind, checks), file.path(out, "environment_recovery_001_predispatch_rehash.csv"), row.names = FALSE)
writeLines(c(
  "Command: RENV_CONFIG_AUTOLOADER_ENABLED=FALSE Rscript --vanilla audit/report_harmonization/report018_order72k_non_s5_integration_dispatch/verify_environment_recovery_001.R",
  capture.output(sessionInfo())), file.path(out, "environment_recovery_001_predispatch_session.txt"))
cat("ENVIRONMENT_RECOVERY_001_PREDISPATCH=PASS rehashes=380\n")
