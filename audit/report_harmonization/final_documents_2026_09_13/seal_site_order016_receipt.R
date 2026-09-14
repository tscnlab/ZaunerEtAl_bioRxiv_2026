stopifnot(getRversion() == "4.6.1")
suppressPackageStartupMessages(library(digest))
d <- "audit/report_harmonization/final_documents_2026_09_13"
out <- file.path(d, "site_a4_delta_promotion_order_016_dispatch_receipt_manifest.csv")
stopifnot(!file.exists(out))
paths <- file.path(d, c("site_a4_delta_promotion_order_016_dispatch_receipt.md",
 "site_a4_delta_promotion_order_016.md", "site_a4_delta_promotion_order_016_dispatch_manifest.csv",
 "site015a_candidate_independent_acceptance.md", "site015a_candidate_independent_acceptance_manifest.csv",
 "seal_site015a_acceptance_and_order016.R", "seal_site_order016_receipt.R"))
sha <- function(p) digest(file = p, algo = "sha256")
expected <- c("93d5f8afd2579fbd93b3fb07bd906b7ca3cf9a9f7c64d96fd3b8fd9d022a0f5c",
 "90d5759e5862ae86541a69bb3af129a1bc48d8983a8912afdd8d958fed192546",
 "8f04a34880a5d8e280a2171e08cad97fa6a11e785e31e16f7a97f108cc38daa9",
 "c20a7026033021acee1fcadcfccab37c99ea867e8913db87e73fbf68534c5ac5")
stopifnot(identical(unname(vapply(paths[2:5], sha, character(1))), expected),
 !anyDuplicated(paths), !out %in% paths, !any(nzchar(Sys.readlink(paths))))
x <- data.frame(path = paths, bytes = file.info(paths)$size, sha256 = vapply(paths, sha, character(1)))
write.csv(x, out, row.names = FALSE)
y <- read.csv(out, stringsAsFactors = FALSE)
stopifnot(nrow(y) == 7L, all(vapply(y$path, sha, character(1)) == y$sha256),
 all(file.info(y$path)$size == y$bytes))
cat("ORDER016_RECEIPT=SEALED 7/7 exact unique non-circular\n")
for (p in c(paths[[1]], out)) cat(sha(p), file.info(p)$size, p, "\n")
