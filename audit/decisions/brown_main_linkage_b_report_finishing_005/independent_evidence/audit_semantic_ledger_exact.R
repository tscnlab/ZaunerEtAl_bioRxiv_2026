# Independent linear-piece raw-byte reconstruction. Does not repair or write HTML.
args <- commandArgs(TRUE)
stopifnot(length(args) == 6L, !dir.exists(args[1]))
out <- args[1]
stopifnot(startsWith(out, "/private/tmp/ba018-completion-audit.ekpsA4/"))
dir.create(out)
author <- "/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026"
.libPaths(c(
  file.path(author, "renv/library/macos/R-4.6/aarch64-apple-darwin23"),
  .libPaths()
))
stopifnot(getRversion() == "4.6.1")
sha <- function(p) unname(digest::digest(p, file = TRUE, algo = "sha256"))
stopifnot(sha(args[2]) == args[5], sha(args[3]) == args[6])
read_raw <- function(p) readBin(p, "raw", n = file.info(p)$size)
raw <- read_raw(args[2])
candidate <- read_raw(args[3])
ledger <- read.csv(args[4], check.names = FALSE, stringsAsFactors = FALSE)
stopifnot(nrow(ledger) > 0L, all(ledger$attribute %in% c("id", "headers")))
reconstruct <- function(input, start, end, expected, replacement) {
  stopifnot(
    length(start) == nrow(ledger),
    all(is.finite(start)),
    all(is.finite(end)),
    all(start == as.integer(start)),
    all(end == as.integer(end))
  )
  ord <- order(start)
  start <- start[ord]
  end <- end[ord]
  expected <- expected[ord]
  replacement <- replacement[ord]
  stopifnot(
    all(start > 0L),
    all(end >= start),
    all(end <= length(input)),
    all(start[-1L] > head(end, -1L))
  )
  chunks <- vector("list", 2L * length(start) + 1L)
  cursor <- 1L
  for (i in seq_along(start)) {
    stopifnot(identical(
      input[seq.int(start[i], end[i])],
      charToRaw(enc2utf8(expected[i]))
    ))
    chunks[[2L * i - 1L]] <- if (start[i] > cursor)
      input[seq.int(cursor, start[i] - 1L)] else raw()
    chunks[[2L * i]] <- charToRaw(enc2utf8(replacement[i]))
    cursor <- end[i] + 1L
  }
  chunks[[length(chunks)]] <- if (cursor <= length(input))
    input[seq.int(cursor, length(input))] else raw()
  do.call(c, chunks)
}
forward <- reconstruct(
  raw,
  ledger$pre_value_start_byte,
  ledger$pre_value_end_byte,
  ledger$pre_value,
  ledger$post_value
)
reverse <- reconstruct(
  candidate,
  ledger$post_value_start_byte,
  ledger$post_value_end_byte,
  ledger$post_value,
  ledger$pre_value
)
checks <- data.frame(
  check = c(
    "all_exact_nonoverlapping_value_intervals",
    "exact_forward_bytes",
    "exact_reverse_bytes",
    "input_files_stable"
  ),
  pass = c(
    TRUE,
    identical(forward, candidate),
    identical(reverse, raw),
    sha(args[2]) == args[5] && sha(args[3]) == args[6]
  )
)
write.csv(checks, file.path(out, "checks.csv"), row.names = FALSE)
stopifnot(all(checks$pass))
write.csv(
  data.frame(
    path = args[2:4],
    bytes = file.info(args[2:4])$size,
    sha256 = unname(vapply(args[2:4], sha, character(1)))
  ),
  file.path(out, "input_manifest.csv"),
  row.names = FALSE
)
write.csv(
  as.data.frame(table(ledger$attribute)),
  file.path(out, "attribute_counts.csv"),
  row.names = FALSE
)
writeLines(
  c(commandArgs(), capture.output(sessionInfo())),
  file.path(out, "session_and_command.txt")
)
cat(
  "INDEPENDENT_SEMANTIC_BYTES=PASS substitutions=",
  nrow(ledger),
  " exact_forward=TRUE exact_reverse=TRUE\n",
  sep = ""
)
