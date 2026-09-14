options(warn = 2, stringsAsFactors = FALSE)
stopifnot(getRversion() == "4.6.1")
d <- "audit/decisions/brown_main_linkage_b_stage2_estimand_bookkeeping_recovery_001"
out <- file.path(d, "dispatch_receipt_manifest.csv")
stopifnot(!file.exists(out))
paths <- file.path(d, c("decision.md", "dispatch_manifest.csv", "dispatch_tool_result.json", "dispatch_receipt.md", "seal_receipt.R"))
hash <- function(p) unname(digest::digest(file = p, algo = "sha256", serialize = FALSE))
stopifnot(hash(paths[1]) == "b47806df8791e726ab29842b6bc015a95e92c4e559c0b5c14d85eb0abba7f200",
          hash(paths[2]) == "50fdd634da0529d097263aee95722cc33b75bda045ac999d24bb46f4a2efa23d")
m <- read.csv(paths[2])
stopifnot(nrow(m) == 456L, all(vapply(m$path, hash, character(1)) == m$sha256), all(file.info(m$path)$size == m$bytes),
          !anyDuplicated(paths), !out %in% paths)
write.csv(data.frame(path = paths, sha256 = unname(vapply(paths, hash, character(1))), bytes = as.numeric(file.info(paths)$size)), out, row.names = FALSE)
cat(sprintf("BA018_ESTIMAND_RECOVERY_RECEIPT=PASS 5/5 manifest=%s\n", hash(out)))
