# File-identity evidence only.
root <- "/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026"
.libPaths(c(file.path(root, "renv/library/macos/R-4.6/aarch64-apple-darwin23"), .libPaths()))
evidence <- file.path(root, "audit/decisions/brown_main_linkage_b_stage2_chest_support_recovery_001")
paths <- file.path(evidence, c("decision.md", "independent_acceptance.md", "dispatch_manifest.csv",
  "dispatch_message.md", "dispatch_receipt.md", "exact_owner_copy_map.csv", "process_preflight.json", "seal_receipt.R"))
sha <- function(x) unname(digest::digest(x, algo = "sha256", file = TRUE))
out <- file.path(evidence, "dispatch_receipt_manifest.csv")
stopifnot(as.character(getRversion()) == "4.6.1", !file.exists(out), !anyDuplicated(paths), !(out %in% paths))
m <- data.frame(path = paths, bytes = unname(file.info(paths)$size), sha256 = unname(vapply(paths, sha, character(1))))
write.csv(m, out, row.names = FALSE)
v <- read.csv(out)
stopifnot(nrow(v) == 8L, identical(v$sha256, unname(vapply(v$path, sha, character(1)))))
cat(sprintf("CHEST_RECEIPT=PASS members=8 sha=%s\n", sha(out)))
