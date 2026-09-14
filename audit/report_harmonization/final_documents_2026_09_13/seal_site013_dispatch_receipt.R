stopifnot(as.character(getRversion()) == "4.6.1")
coord <- "audit/report_harmonization/final_documents_2026_09_13"
sha <- function(path) {
  con <- file(path, "rb")
  on.exit(close(con))
  as.character(openssl::sha256(con))
}
files <- c("final_site_promotion_order_013_receipt.md",
  "final_site_promotion_order_013.md",
  "final_site_promotion_order_013_dispatch_manifest.csv",
  "site011_candidate_independent_acceptance.md",
  "site011_candidate_independent_acceptance_manifest.csv",
  "seal_site011_acceptance_and_promotion013.R",
  "seal_site013_dispatch_receipt.R")
paths <- file.path(coord, files)
out <- file.path(coord, "final_site_promotion_order_013_receipt_manifest.csv")
stopifnot(!file.exists(out), all(file.exists(paths)), !anyDuplicated(paths),
  !out %in% paths, !any(nzchar(Sys.readlink(paths))))
stopifnot(sha(paths[[2]]) == "6c5003debe69f12deb854a28fee72f12f656fe90dec9a546ebc9d5f7e59d0741",
  sha(paths[[3]]) == "53f4b75477bf939c1239135db9b6ed6c930e3239df5ad88449c82828dc0b2d69",
  sha(paths[[4]]) == "02b67a21fecb875fd2727ad1a34840676613e1f21881553b18c61e11cd1efb5b",
  sha(paths[[5]]) == "262bd42ee46da79a662f044b6e4fa9e4787b289ba0fe1d7a4c413bd87a80bb00")
manifest <- data.frame(path = paths, bytes = file.info(paths)$size,
  sha256 = vapply(paths, sha, ""), stringsAsFactors = FALSE)
write.csv(manifest, out, row.names = FALSE)
check <- read.csv(out, stringsAsFactors = FALSE)
stopifnot(nrow(check) == 7L, !anyDuplicated(check$path),
  all(file.info(check$path)$size == check$bytes),
  all(vapply(check$path, sha, "") == check$sha256))
cat("SITE013_DISPATCH_RECEIPT=PASS 7/7 exact unique non-circular R=4.6.1\n")
for (p in c(paths[[1]], out)) cat(sha(p), file.info(p)$size, p, "\n")
