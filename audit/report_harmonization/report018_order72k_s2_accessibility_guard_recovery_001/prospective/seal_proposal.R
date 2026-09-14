options(stringsAsFactors = FALSE)
stopifnot(getRversion() == "4.6.1")
out <- "/private/tmp/order72k-s2-hidden-guard.ddOH0Z"
sha <- function(path) {
  con <- file(path, "rb"); on.exit(close(con))
  unname(unclass(as.character(openssl::sha256(con))))
}
manifest <- file.path(out, "proposal_manifest.csv")
seal <- file.path(out, "proposal_seal.json")
stopifnot(!file.exists(manifest), !file.exists(seal))
paths <- list.files(out, full.names = TRUE, recursive = TRUE, all.files = TRUE, no.. = TRUE)
stopifnot(all(Sys.readlink(paths) == ""), !anyDuplicated(paths))
pins <- data.frame(path = paths, sha256 = unname(vapply(paths, sha, character(1))), bytes = file.info(paths)$size)
write.csv(pins, manifest, row.names = FALSE)
jsonlite::write_json(list(status = "TEMP_ONLY_STATIC_PROPOSAL", canonical_or_owner_edit = FALSE,
  browser_runs = 0L, capture_runs = 0L, render_runs = 0L, dispatches = 0L,
  manifest = list(path = manifest, sha256 = sha(manifest), members = nrow(pins)),
  prospective = list(path = file.path(out, "capture_word_tables.mjs"), sha256 = sha(file.path(out, "capture_word_tables.mjs")), bytes = file.info(file.path(out, "capture_word_tables.mjs"))$size),
  static_tests = 404L, reverse_proof_exact = TRUE,
  exclusion = "Manifest and companion seal excluded from the manifest; no self hash.",
  requirement = "Independent central review and a separate explicit release are required before any live edit or new capture."),
  seal, auto_unbox = TRUE, pretty = TRUE)
cat("TEMP_PROPOSAL_MANIFEST members=",nrow(pins)," SHA256=",sha(manifest),"\nSEAL SHA256=",sha(seal),"\n",sep="")
