stopifnot(as.character(getRversion()) == "4.6.1")
root <- normalizePath(getwd(), mustWork = TRUE)
coord <- "audit/report_harmonization/final_documents_2026_09_13"
scratch <- "/private/tmp/writer012-preflight.4N7hbm"
evidence <- file.path(coord, "writer012_preflight")
order <- file.path(coord, "writer_a4_display_candidate_order_012.md")
dispatch <- file.path(coord, "writer_a4_display_candidate_order_012_dispatch_manifest.csv")
sha <- function(p) {
  con <- file(p, "rb")
  on.exit(close(con))
  as.character(openssl::sha256(con))
}
stopifnot(!dir.exists(evidence), !file.exists(dispatch),
  file.exists(order), !any(grepl("\u2014", readLines(order), fixed = TRUE)))
for (f in c("C271_rehash.csv", "final145_rehash.csv", "active011_47_rehash.csv")) {
  x <- read.csv(file.path(scratch, f), stringsAsFactors = FALSE)
  stopifnot(all(x$exact))
}
pins <- read.csv(file.path(scratch, "stable_input_pins.csv"), stringsAsFactors = FALSE)
stopifnot(!anyDuplicated(pins$path), all(file.exists(pins$path)),
  all(file.info(pins$path)$size == pins$bytes),
  all(vapply(pins$path, sha, "") == pins$sha256))
native <- read.csv(file.path(scratch, "native19_rehash.csv"), stringsAsFactors = FALSE)
native_paths <- file.path("audit/manuscript_nature_health/final_format_completion_2026_09_14/editable_tables", native$file)
stopifnot(nrow(native) == 19L, all(vapply(native_paths, sha, "") == native$sha256))
dir.create(evidence)
for (f in list.files(scratch, recursive = TRUE, full.names = FALSE)) {
  destination <- file.path(evidence, f)
  dir.create(dirname(destination), recursive = TRUE, showWarnings = FALSE)
  stopifnot(file.copy(file.path(scratch, f), destination, overwrite = FALSE),
    sha(file.path(scratch, f)) == sha(destination))
}
paths <- sort(unique(c(order, pins$path, native_paths,
  list.files(evidence, recursive = TRUE, full.names = TRUE),
  file.path(coord, "seal_writer_a4_display_candidate_012.R"))))
stopifnot(!dispatch %in% paths, !anyDuplicated(normalizePath(paths)),
  all(file.exists(paths)), !any(file.info(paths)$isdir))
manifest <- data.frame(path = paths, bytes = file.info(paths)$size,
  sha256 = vapply(paths, sha, ""), stringsAsFactors = FALSE)
write.csv(manifest, dispatch, row.names = FALSE)
check <- read.csv(dispatch, stringsAsFactors = FALSE)
stopifnot(nrow(check) == length(paths), !anyDuplicated(check$path),
  !normalizePath(dispatch) %in% normalizePath(check$path),
  all(file.info(check$path)$size == check$bytes),
  all(vapply(check$path, sha, "") == check$sha256))
cat(sprintf("WRITER012_CANDIDATE_DISPATCH_SEAL=PASS %d/%d exact unique non-circular R=%s\n",
  nrow(check), nrow(check), as.character(getRversion())))
for (p in c(order, dispatch)) cat(sha(p), file.info(p)$size, p, "\n")
