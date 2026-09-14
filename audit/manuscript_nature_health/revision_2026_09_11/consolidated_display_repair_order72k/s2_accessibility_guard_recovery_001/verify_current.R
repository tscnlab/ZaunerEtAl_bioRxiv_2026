options(stringsAsFactors = FALSE)
stopifnot(getRversion() == "4.6.1")
phase <- commandArgs(trailingOnly = TRUE)
stopifnot(length(phase) == 1L, phase %in% c("before_capture", "after_capture"))
root <- normalizePath(getwd(), mustWork = TRUE)
owner <- file.path(root, "audit/manuscript_nature_health/revision_2026_09_11/consolidated_display_repair_order72k")
record <- file.path(owner, "s2_accessibility_guard_recovery_001")
sha <- function(p) { con <- file(p, "rb"); on.exit(close(con)); unname(unclass(as.character(openssl::sha256(con)))) }
resolve <- function(p) if (startsWith(p, "/")) p else file.path(root, p)
output <- file.path(record, paste0(phase, "_4339_rows.csv"))
stopifnot(!file.exists(output))
aliases <- read.csv(file.path(record, "version_specific_aliases.csv"))
pins <- read.csv(file.path(record, "preflight_4339_rows.csv"))
paths <- vapply(pins$path, resolve, character(1)); mapped <- paths
for (i in seq_len(nrow(aliases))) {
  j <- which(paths == aliases$live[i] & pins$expected_sha256 == aliases$expected_sha256[i])
  mapped[j] <- aliases$preimage[i]
}
stopifnot(nrow(aliases) == 4L, nrow(pins) == 4339L)
pins$current_resolution <- mapped
pins$current_sha256 <- unname(vapply(mapped, sha, character(1)))
pins$current_bytes <- file.info(mapped)$size
pins$exact <- pins$current_sha256 == pins$expected_sha256 & pins$current_bytes == pins$expected_bytes
stopifnot(all(pins$exact), all(Sys.readlink(mapped) == ""))
write.csv(pins, output, row.names = FALSE)
live <- file.path(owner, "helpers/capture_word_tables.mjs")
preimage <- file.path(record, "capture_word_tables.preimage.mjs")
reverse <- file.path(record, "capture_word_tables.reverse_proof.mjs")
stopifnot(sha(live) == "ecf7525cb5a89438b43588c8ac2acd9ed8e8bcb568b3fc78676ba349792871ec", file.info(live)$size == 42404L,
          sha(preimage) == "7f5cdeb35280de680dfc6135dca462ba5e16cbc2e5085539810805d34f70331a",
          sha(reverse) == sha(preimage), file.info(reverse)$size == 21562L)
css <- read.csv(file.path(record, "frozen_css.csv"))
stopifnot(all(vapply(css$path, sha, character(1)) == css$sha256), all(file.info(css$path)$size == css$bytes))
served <- read.csv(file.path(record, "served_preflight.csv"))
stopifnot(all(vapply(served$source, sha, character(1)) == served$sha256), all(vapply(served$served, sha, character(1)) == served$sha256))
earlier <- read.csv(file.path(record, "earlier_capture_files_before.csv"))
stopifnot(all(vapply(earlier$path, sha, character(1)) == earlier$sha256), all(file.info(earlier$path)$size == earlier$bytes))
write.csv(data.frame(path = c(live, preimage, reverse, css$path), sha256 = vapply(c(live, preimage, reverse, css$path), sha, character(1)),
                     bytes = file.info(c(live, preimage, reverse, css$path))$size),
          file.path(record, paste0(phase, "_live_and_reverse_identities.csv")), row.names = FALSE)
writeLines(c("Read-only file identities and exact reverse-proof check; no scientific computation.",
             paste("Phase:", phase), paste("All earlier capture files preserved:", nrow(earlier)),
             "Historical resolution matched both exact live path and expected hash, using only the four authorized version-specific aliases.",
             capture.output(sessionInfo())), file.path(record, paste0(phase, "_session.txt")))
cat("PASS", phase, ":4339 preserved rows, exact ecf752 helper, exact7f5c zero-fuzz reverse, both CSS frozen, served12 and all earlier captures preserved.\n")
