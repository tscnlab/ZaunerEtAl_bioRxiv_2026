options(stringsAsFactors = FALSE)
stopifnot(getRversion() == "4.6.1")
root <- normalizePath(getwd(), mustWork = TRUE)
out <- file.path(root, "audit/report_harmonization/report018_order72k_non_s5_integration_dispatch")
release <- "audit/report_harmonization/report018_order72k_s2_unit_scaling_width_repair/"
owner <- "audit/manuscript_nature_health/revision_2026_09_11/consolidated_display_repair_order72k/"
resolve <- function(path) if (startsWith(path, "/")) path else file.path(root, path)
cache <- new.env(parent = emptyenv())
sha <- function(path) {
  path <- normalizePath(path, mustWork = TRUE)
  if (exists(path, envir = cache, inherits = FALSE)) return(get(path, envir = cache))
  con <- file(path, "rb")
  on.exit(close(con))
  value <- unname(unclass(as.character(openssl::sha256(con))))
  assign(path, value, envir = cache)
  value
}
specs <- data.frame(
  path = c(paste0(release, c("input_pins.csv", "release_manifest.csv", "dispatch_manifest.csv")),
    paste0(owner, "environment_capture_recovery_001/stopped_visual_owner_manifest.csv"),
    "audit/report_harmonization/report018_order72k_non_s5_integration_dispatch/s2_visual_stop_independent_manifest.csv"),
  sha256 = c("8ad7e3d641d984b10bf31c6878ff8b9c998deba0d5b1767926e181113be2336c",
    "f426940e07d6768d1d529419c6064ce200c3eeace71ff970deac66ba3d043cbb",
    "037591dd82e47a7dd59fc0754f54432656c649929ee6871a52009cd2ace56a88",
    "852fca237ffb23c1e294095aebd7894e150d350f4c41be32463a857711446a7e",
    "5345d8fea206671b50f8956e361aacce2863b008de67c6525de9abea08218645"),
  rows = c(565L, 581L, 8L, 295L, 6L))
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
  data.frame(manifest = specs$path[i], path = pins$path,
    expected_sha256 = pins$sha256, observed_sha256 = observed,
    expected_bytes = pins$bytes, observed_bytes = bytes)
})
prior_path <- file.path(out, "s2_recovery_001_predispatch_rehash.csv")
prior <- read.csv(prior_path, check.names = FALSE)
stopifnot(nrow(prior) == 854L)
prior_paths <- vapply(prior$path, resolve, character(1))
prior_observed <- unname(vapply(prior_paths, sha, character(1)))
prior_bytes <- as.numeric(file.info(prior_paths)$size)
stopifnot(all(prior_observed == prior$expected_sha256), all(prior_bytes == prior$expected_bytes))
verified[[length(verified) + 1L]] <- data.frame(
  manifest = "s2_recovery_001_predispatch_rehash.csv", path = prior$path,
  expected_sha256 = prior$expected_sha256, observed_sha256 = prior_observed,
  expected_bytes = prior$expected_bytes, observed_bytes = prior_bytes)
stopifnot(sha(resolve("audit/report_harmonization/owner_orders/72k_s2_unit_scaling_width_repair.md")) ==
  "982dc5b6213ca813c0883455197140025d367388a7956b19747af61763b13d3f")
stopped <- read.csv(resolve(paste0(owner, "environment_capture_recovery_001/stopped_visual_owner_manifest.csv")))
capture_files <- list.files(resolve(paste0(owner, "capture_attempt1")), recursive = TRUE,
  full.names = TRUE, all.files = TRUE, no.. = TRUE)
stopifnot(length(capture_files) == 19L)
relative <- substring(capture_files, nchar(root) + 2L)
idx <- match(relative, stopped$path)
stopifnot(!anyNA(idx), all(unname(vapply(capture_files, sha, character(1))) == stopped$sha256[idx]))
served <- read.csv(resolve(paste0(owner, "stopped_final_checks/served_output_identities.csv")))
stopifnot(nrow(served) == 12L,
  all(unname(vapply(served$source, sha, character(1))) == served$sha256),
  all(unname(vapply(served$served, sha, character(1))) == served$sha256))
stopifnot(!file.exists(resolve(paste0(owner, "capture_s2_attempt4"))),
  !file.exists(resolve(paste0(owner, "s2_width_repair_001"))),
  dir.exists("/private/tmp/order72k_3ok569jd"),
  identical(Sys.readlink("/private/tmp/order72k_3ok569jd"), ""))
result <- do.call(rbind, verified)
write.csv(result, file.path(out, "s2_width_repair_001_predispatch_rehash.csv"), row.names = FALSE)
writeLines(c(
  "Command: RENV_CONFIG_AUTOLOADER_ENABLED=FALSE Rscript --vanilla audit/report_harmonization/report018_order72k_non_s5_integration_dispatch/verify_s2_width_repair_001.R",
  paste("UTC:", format(Sys.time(), "%Y-%m-%d %H:%M:%S", tz = "UTC")),
  "Additional checks: 19 completed capture files; 12 served source/copy pairs; attempt4 and new owner evidence destinations absent; task TMPDIR exists and is nonsymlink.",
  capture.output(sessionInfo())), file.path(out, "s2_width_repair_001_predispatch_session.txt"))
cat("S2_WIDTH_REPAIR_001_PREDISPATCH=PASS manifest_rows=", nrow(result),
  " unique_files=", length(ls(cache)), " captures=19 served_pairs=12\n", sep = "")
