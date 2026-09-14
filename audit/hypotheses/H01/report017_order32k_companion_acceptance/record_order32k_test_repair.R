#!/usr/bin/env Rscript

stopifnot(identical(as.character(getRversion()), "4.6.1"))
root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
setwd(root)
source(file.path(root, "scripts/pipeline/paths_io.R"))
evidence_dir <- file.path(
  root,
  "audit/hypotheses/H01/report017_order32k_companion_acceptance"
)
pre <- file.path(evidence_dir, "test_h01_preparation_report.pre.R")
post <- "tests/hypotheses/H01/test_h01_preparation_report.R"
diff_path <- file.path(evidence_dir, "order32k_test_literal_exact.diff")

diff_status <- system2(
  "diff",
  c("-u", pre, post),
  stdout = diff_path,
  stderr = FALSE
)
stopifnot(identical(diff_status, 1L), file.exists(diff_path))
diff_text <- readLines(diff_path, warn = FALSE, encoding = "UTF-8")
stopifnot(
  sum(startsWith(diff_text, "@@")) == 1L,
  sum(grepl("^-.*17 prespecified light-exposure metrics", diff_text)) == 1L,
  sum(grepl("^\\+.*17-response package", diff_text)) == 1L
)

read_raw <- function(path) {
  connection <- file(path, open = "rb")
  on.exit(close(connection), add = TRUE)
  readBin(connection, what = "raw", n = as.numeric(file.info(path)$size))
}
post_text <- rawToChar(read_raw(post))
old_literal <- "17 prespecified light-exposure metrics"
new_literal <- "17-response package"
stopifnot(
  lengths(regmatches(post_text, gregexpr(old_literal, post_text, fixed = TRUE))) == 0L,
  lengths(regmatches(post_text, gregexpr(new_literal, post_text, fixed = TRUE))) == 1L
)
reversed_text <- sub(new_literal, old_literal, post_text, fixed = TRUE)
reversed <- tempfile("order32k-test-reverse-", fileext = ".R")
on.exit(unlink(reversed), add = TRUE)
writeBin(charToRaw(reversed_text), reversed)
invisible(parse(file = post))

proof <- data.frame(
  item = c("pre", "post", "diff", "reverse_reconstruction"),
  sha256 = c(
    artifact_sha256(pre),
    artifact_sha256(post),
    artifact_sha256(diff_path),
    artifact_sha256(reversed)
  ),
  bytes = c(
    file.info(pre)$size,
    file.info(post)$size,
    file.info(diff_path)$size,
    file.info(reversed)$size
  ),
  stringsAsFactors = FALSE
)
proof$reverse_exact <- proof$sha256[proof$item == "pre"] ==
  proof$sha256[proof$item == "reverse_reconstruction"] &&
  proof$bytes[proof$item == "pre"] ==
    proof$bytes[proof$item == "reverse_reconstruction"]
stopifnot(
  proof$sha256[proof$item == "pre"] ==
    "379414830e5bcd656ac460c2ad93616ecbcab104259c56a8fcf9296da8c0f2c4",
  all(proof$reverse_exact)
)
write.csv(
  proof,
  file.path(evidence_dir, "order32k_test_literal_reverse_proof.csv"),
  row.names = FALSE,
  na = ""
)
cat(sprintf(
  "test_repair=PASS pre=%s post=%s reverse=%s\n",
  proof$sha256[proof$item == "pre"],
  proof$sha256[proof$item == "post"],
  proof$sha256[proof$item == "reverse_reconstruction"]
))
