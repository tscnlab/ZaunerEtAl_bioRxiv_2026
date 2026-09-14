options(stringsAsFactors = FALSE)
stopifnot(getRversion() == "4.6.1")
root <- normalizePath(getwd(), mustWork = TRUE)
out <- file.path(root, "audit/manuscript_nature_health/revision_2026_09_11/consolidated_display_repair_order72k")
phase <- commandArgs(trailingOnly = TRUE)
stopifnot(length(phase) == 1L, phase %in% c("before", "after"))
sha <- function(p) {
  con <- file(p, "rb"); on.exit(close(con))
  unname(unclass(as.character(openssl::sha256(con))))
}
resolve <- function(p) normalizePath(if (startsWith(p, "/")) p else file.path(root, p), mustWork = TRUE)
inventory <- c(
  release = "audit/report_harmonization/report018_order72k_non_s5_integration_release/release_manifest.csv",
  inputs = "audit/report_harmonization/report018_order72k_non_s5_integration_release/integration_input_pins.csv",
  dispatch = "audit/report_harmonization/report018_order72k_non_s5_integration_release/dispatch_manifest.csv",
  added = "audit/report_harmonization/report018_order72k_non_s5_integration_dispatch/dependency_closure_pins.csv"
)
expected <- c(
  release = "07ca15e8d42663c12a2ce5d1ea5d724ee7ecf7480efe2e767654061b8ab9433d",
  inputs = "af995052b2c58e531a1e710a09942dcee275aca93433aff3d89533ce52b2c340",
  dispatch = "c1f3921d85b83f6adee86362c7d16730e7a8c8a576ee6bde34d36fbc215fa8f1",
  added = "c43661fc9595057ead1272b9d02a9750c32a43484e4584d6c8d0b3a9fa36a88f"
)
rows <- lapply(names(inventory), function(k) {
  p <- resolve(inventory[[k]])
  stopifnot(identical(sha(p), expected[[k]]))
  x <- read.csv(p, check.names = FALSE)
  paths <- vapply(x$path, resolve, character(1))
  actual <- vapply(paths, sha, character(1))
  size <- file.info(paths)$size
  stopifnot(!any(file.info(paths)$isdir), all(Sys.readlink(paths) == ""))
  data.frame(inventory = k, path = x$path, expected_sha256 = x$sha256,
    actual_sha256 = actual, bytes = size, hash_exact = actual == x$sha256,
    size_exact = size == as.numeric(x$bytes), regular_non_symlink = TRUE)
})
checks <- do.call(rbind, rows)
write.csv(checks, file.path(out, paste0("input_identity_", phase, ".csv")), row.names = FALSE)
writeLines(c("File-identity verification only. No analytical or Brown code executed.", capture.output(sessionInfo())), file.path(out, paste0("input_identity_session_", phase, ".txt")))
stopifnot(nrow(checks) == 429L, all(checks$hash_exact), all(checks$size_exact))
cat("PASS:", nrow(checks), "exact pinned rows; 21 added dependencies checked; R", as.character(getRversion()), "\n")
