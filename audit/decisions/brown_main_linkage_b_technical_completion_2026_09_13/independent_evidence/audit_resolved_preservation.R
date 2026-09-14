# Non-mutating checksum audit of an explicit historical resolver inventory.
args <- commandArgs(TRUE)
stopifnot(length(args) == 3L, !dir.exists(args[1]))
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
input <- normalizePath(args[2], mustWork = TRUE)
leaf_input <- normalizePath(args[3], mustWork = TRUE)
input_sha <- sha(input)
leaf_sha <- sha(leaf_input)
m <- read.csv(input, check.names = FALSE)
stopifnot(
  all(c("path", "resolved_path", "sha256", "bytes", "passed") %in% names(m)),
  all(m$passed),
  all(file.exists(m$resolved_path))
)
paths <- unique(m$resolved_path)
observed <- setNames(vapply(paths, sha, character(1)), paths)
m$independent_sha256 <- unname(observed[m$resolved_path])
m$independent_bytes <- file.info(m$resolved_path)$size
m$independent_pass <- m$independent_sha256 == m$sha256 &
  m$independent_bytes == m$bytes
stopifnot(all(m$independent_pass), sha(input) == input_sha)
models <- grepl("\\.(rds|RDS)$", m$path)
stopifnot(all(m$path[models] == m$resolved_path[models]))
leaf <- read.csv(leaf_input, check.names = FALSE)
stopifnot(
  nrow(leaf) == 211L,
  !anyDuplicated(leaf$path),
  all(leaf$passed),
  identical(unname(vapply(leaf$path, sha, character(1))), leaf$sha256),
  all(file.info(leaf$path)$size == leaf$bytes),
  sha(leaf_input) == leaf_sha
)
write.csv(
  m,
  file.path(out, "resolved_protection_rehash.csv"),
  row.names = FALSE
)
write.csv(
  data.frame(
    check = c(
      "resolved_historical_bytes",
      "RDS_live_not_remapped",
      "211_live_leaves",
      "input_evidence_stable"
    ),
    count = c(nrow(m), sum(models), 211L, 2L),
    passed = TRUE
  ),
  file.path(out, "checks.csv"),
  row.names = FALSE
)
write.csv(
  data.frame(path = c(input, leaf_input), sha256 = c(input_sha, leaf_sha)),
  file.path(out, "input_pins.csv"),
  row.names = FALSE
)
writeLines(
  c(commandArgs(), capture.output(sessionInfo())),
  file.path(out, "session_and_command.txt")
)
cat(
  "RESOLVED_PRESERVATION=PASS rows=",
  nrow(m),
  " unique_files=",
  length(paths),
  " current_leaves=211\n",
  sep = ""
)
