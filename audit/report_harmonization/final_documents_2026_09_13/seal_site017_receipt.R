stopifnot(getRversion() == "4.6.1")
d <- "audit/report_harmonization/final_documents_2026_09_13"
output <- file.path(d, "site_reader_scope_cleanup_order_017_dispatch_receipt_manifest.csv")
stopifnot(!file.exists(output))
paths <- file.path(d, c("site_reader_scope_cleanup_order_017_dispatch_receipt.md",
  "site_reader_scope_cleanup_order_017.md", "site_reader_scope_cleanup_order_017_dispatch_manifest.csv",
  "site017_readonly_independent_acceptance.md", "reader_scope_author_direction_017.md",
  "reader_scope_017_independent/dispatch_review_summary.json", "seal_site017_receipt.R"))
sha <- function(p) digest::digest(file = p, algo = "sha256")
stopifnot(!anyDuplicated(paths), !output %in% paths, all(file.exists(paths)))
m <- data.frame(path = paths, bytes = file.info(paths)$size,
  sha256 = vapply(paths, sha, character(1)), stringsAsFactors = FALSE)
write.csv(m, output, row.names = FALSE)
r <- read.csv(output, stringsAsFactors = FALSE)
stopifnot(nrow(r) == 7L, all(vapply(r$path, sha, character(1)) == r$sha256),
  all(file.info(r$path)$size == r$bytes))
cat("ORDER017_RECEIPT=PASS 7/7\n")
for (p in c(paths[[1]], output)) cat(sha(p), file.info(p)$size, p, "\n")
