options(stringsAsFactors = FALSE)
stopifnot(getRversion() == "4.6.1")
root <- normalizePath(getwd(), mustWork = TRUE)
out <- file.path(root, "audit/report_harmonization/report018_order72k_non_s5_integration_dispatch")
release <- "audit/report_harmonization/report018_order72k_s2_accessibility_guard_recovery_001/"
owner <- file.path(root, "audit/manuscript_nature_health/revision_2026_09_11/consolidated_display_repair_order72k")
resolve <- function(path) if (startsWith(path, "/")) path else file.path(root, path)
cache <- new.env(parent = emptyenv())
sha <- function(path) {
  path <- normalizePath(path, mustWork = TRUE)
  if (exists(path, envir = cache, inherits = FALSE)) return(get(path, envir = cache))
  con <- file(path, "rb"); on.exit(close(con))
  value <- unname(unclass(as.character(openssl::sha256(con))))
  assign(path, value, envir = cache); value
}
specs <- data.frame(
  path = c(paste0(release, c("input_pins.csv", "release_manifest.csv", "dispatch_manifest.csv", "independent_stop_manifest.csv")),
    file.path(owner, "s2_width_repair_001/stopped_check_owner_manifest.csv"),
    file.path(out, "s2_attempt4_stop_independent_manifest.csv")),
  sha256 = c("a3d4a2e2ab567cad9a1dae0ca21bb32469d0f9f1ec3bae1c6d59f864c2530e15",
    "fc63e43d43b37864cb5cfce4fcef676092c4088aefe60a043593b90ed267177c",
    "81e732d098461138bbede6b006c4da6d78320db5e165227d8026768f035a6dbd",
    "370c1a4a1942906138d6e709371a05ca3dc7a74b39032b14baa397c186018674",
    "75259255f98f19a291471e617a42be6bd304db523450167a1eb2c2b9a90045f9",
    "b0e6dfa9d9855bc8bd6a200c4eaecc4dc6887e66e9003db20b015688283d10c6"),
  rows = c(632L, 688L, 15L, 353L, 335L, 7L))
verified <- lapply(seq_len(nrow(specs)), function(i) {
  path <- resolve(specs$path[i])
  stopifnot(sha(path) == specs$sha256[i])
  pins <- read.csv(path, check.names = FALSE)
  paths <- vapply(pins$path, resolve, character(1))
  canonical <- normalizePath(paths, mustWork = TRUE)
  observed <- unname(vapply(paths, sha, character(1)))
  bytes <- as.numeric(file.info(paths)$size)
  stopifnot(nrow(pins) == specs$rows[i], !anyDuplicated(pins$path),
    !normalizePath(path) %in% canonical, all(observed == pins$sha256), all(bytes == pins$bytes))
  if (i == 4L) {
    duplicates <- unique(canonical[duplicated(canonical)])
    expected <- normalizePath(file.path(owner, "s2_width_repair_001", c("capture_word_tables.preimage.mjs", "main_layout.preimage.css", "selection_layout.preimage.css")))
    stopifnot(length(unique(canonical)) == 350L, setequal(duplicates, expected))
    for (p in duplicates) {
      j <- which(canonical == p)
      stopifnot(length(j) == 2L, length(unique(pins$sha256[j])) == 1L, length(unique(pins$bytes[j])) == 1L)
    }
  } else stopifnot(!anyDuplicated(canonical))
  data.frame(manifest = specs$path[i], path = pins$path, resolved_path = paths,
    expected_sha256 = pins$sha256, observed_sha256 = observed, expected_bytes = pins$bytes, observed_bytes = bytes)
})
prior <- read.csv(file.path(out, "s2_width_repair_001_predispatch_rehash.csv"), check.names = FALSE)
transitions <- read.csv(file.path(owner, "s2_width_repair_001/authorized_transitions.csv"), check.names = FALSE)
prior_paths <- vapply(prior$path, resolve, character(1))
mapped <- prior_paths
for (i in seq_len(nrow(transitions))) {
  j <- which(prior_paths == transitions$live[i] & prior$expected_sha256 == transitions$pre_sha256[i])
  mapped[j] <- transitions$preimage[i]
}
observed <- unname(vapply(mapped, sha, character(1)))
bytes <- as.numeric(file.info(mapped)$size)
stopifnot(nrow(prior) == 2309L, length(unique(prior_paths[mapped != prior_paths])) == 3L,
  all(observed == prior$expected_sha256), all(bytes == prior$expected_bytes))
verified[[length(verified) + 1L]] <- data.frame(manifest = "s2_width_repair_001_predispatch_rehash.csv", path = prior$path,
  resolved_path = mapped, expected_sha256 = prior$expected_sha256, observed_sha256 = observed,
  expected_bytes = prior$expected_bytes, observed_bytes = bytes)
order <- resolve("audit/report_harmonization/owner_orders/72k_s2_accessibility_guard_recovery_001.md")
stopifnot(sha(order) == "016b67d9d2ed689f69ccfe9eea84ea9ad2794f0770b5cd07a77e57d54e5657c8", file.info(order)$size == 11287L,
  sha(resolve(paste0(release, "prospective/capture_word_tables.mjs"))) == "ecf7525cb5a89438b43588c8ac2acd9ed8e8bcb568b3fc78676ba349792871ec",
  sha(file.path(owner, "helpers/capture_word_tables.mjs")) == "7f5cdeb35280de680dfc6135dca462ba5e16cbc2e5085539810805d34f70331a")
served <- read.csv(file.path(owner, "stopped_final_checks/served_output_identities.csv"))
stopifnot(nrow(served) == 12L, all(unname(vapply(served$source, sha, character(1))) == served$sha256),
  all(unname(vapply(served$served, sha, character(1))) == served$sha256),
  length(list.files(file.path(owner, "capture_attempt1"), recursive = TRUE, all.files = TRUE, no.. = TRUE)) == 19L,
  length(list.files(file.path(owner, "capture_s2_attempt3"), recursive = TRUE, all.files = TRUE, no.. = TRUE)) == 8L,
  identical(list.files(file.path(owner, "capture_s2_attempt4"), recursive = TRUE, all.files = TRUE, no.. = TRUE), "supp_table_s2_source.html"),
  !file.exists(file.path(owner, "capture_s2_attempt5")), !file.exists(file.path(owner, "s2_accessibility_guard_recovery_001")),
  dir.exists("/private/tmp/order72k_3ok569jd"), identical(Sys.readlink("/private/tmp/order72k_3ok569jd"), ""))
result <- do.call(rbind, verified)
write.csv(result, file.path(out, "s2_accessibility_recovery_001_predispatch_rehash.csv"), row.names = FALSE)
writeLines(c("Command: RENV_CONFIG_AUTOLOADER_ENABLED=FALSE Rscript --vanilla audit/report_harmonization/report018_order72k_non_s5_integration_dispatch/verify_s2_accessibility_recovery_001.R",
  paste("UTC:", format(Sys.time(), "%Y-%m-%d %H:%M:%S", tz = "UTC")),
  "All new seals canonical-unique. Old central353 seal: exactly three documented same-hash spelling pairs, 350 canonical files. Historical aliases match both path and expected hash. Served12, completedcapture19, attempt3eight and attempt4single-source remain exact; new destinations absent.",
  capture.output(sessionInfo())), file.path(out, "s2_accessibility_recovery_001_predispatch_session.txt"))
cat("S2_ACCESSIBILITY_RECOVERY_001_PREDISPATCH=PASS rows=", nrow(result), " unique_files=", length(ls(cache)), "\n", sep = "")
