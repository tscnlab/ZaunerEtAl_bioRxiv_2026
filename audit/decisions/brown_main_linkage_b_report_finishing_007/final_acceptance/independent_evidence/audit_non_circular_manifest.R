# Reusable read-only exact acceptance-manifest verification.
args <- commandArgs(TRUE)
stopifnot(length(args) == 4L, !dir.exists(args[1]))
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
manifest <- args[2]
stopifnot(sha(manifest) == args[3])
m <- read.csv(manifest, check.names = FALSE)
stopifnot(
  nrow(m) == as.integer(args[4]),
  all(c("path", "bytes", "sha256") %in% names(m)),
  !anyDuplicated(m$path),
  !manifest %in% m$path,
  all(file.exists(m$path)),
  !any(file.info(m$path)$isdir)
)
m$observed_sha256 <- unname(vapply(m$path, sha, character(1)))
m$observed_bytes <- file.info(m$path)$size
m$passed <- m$sha256 == m$observed_sha256 & m$bytes == m$observed_bytes
write.csv(m, file.path(out, "manifest_verification.csv"), row.names = FALSE)
stopifnot(all(m$passed), sha(manifest) == args[3])
write.csv(
  data.frame(
    path = manifest,
    bytes = file.info(manifest)$size,
    sha256 = args[3]
  ),
  file.path(out, "input_manifest.csv"),
  row.names = FALSE
)
writeLines(
  c(commandArgs(), capture.output(sessionInfo())),
  file.path(out, "session_and_command.txt")
)
cat(
  "NONCIRCULAR_MANIFEST=PASS members=",
  nrow(m),
  "/",
  nrow(m),
  " R=",
  as.character(getRversion()),
  "\n",
  sep = ""
)
