stopifnot(as.character(getRversion()) == "4.6.1")
root <- "audit/report_harmonization/final_documents_2026_09_13"
sha <- function(path) {
  con <- file(path, "rb")
  on.exit(close(con))
  as.character(openssl::sha256(con))
}
out <- file.path(root, "writer_candidate_production_order_009_receipt_manifest.csv")
stopifnot(!file.exists(out))
paths <- file.path(root, c(
  "writer_candidate_production_order_009_dispatch_receipt.md",
  "writer_candidate_production_order_009.md",
  "writer_candidate_production_order_009_dispatch_manifest.csv",
  "writer_candidate_production_order_009_preflight.csv",
  "writer_candidate_production_order_009_path_resolution.md",
  "seal_writer_candidate_production_009_receipt.R"
))
stopifnot(sha(paths[[2]]) == "d30503c17b78f96310acad458c1993288116617a6d9c063813eb8ef8ab2516df")
stopifnot(sha(paths[[3]]) == "07ceb88e078b9a470b5c8835f955dc52e8129dd1549c4a4b79807f3b4041e899")
dispatch <- read.csv(paths[[3]], stringsAsFactors = FALSE)
stopifnot(nrow(dispatch) == 45L, !anyDuplicated(dispatch$path))
stopifnot(all(file.info(dispatch$path)$size == dispatch$bytes))
stopifnot(all(vapply(dispatch$path, sha, "") == dispatch$sha256))
receipt <- data.frame(path = paths, bytes = file.info(paths)$size, sha256 = vapply(paths, sha, ""))
stopifnot(!anyDuplicated(receipt$path), !out %in% receipt$path)
write.csv(receipt, out, row.names = FALSE, na = "")
check <- read.csv(out, stringsAsFactors = FALSE)
stopifnot(nrow(check) == 6L, all(vapply(check$path, sha, "") == check$sha256))
cat("WRITER_ORDER009_RECEIPT=PASS dispatch=45/45 receipt=6/6\n")
cat("receipt ", sha(paths[[1]]), "\nmanifest ", sha(out), "\n", sep = "")
