# File metadata only.
author <- "/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026"
.libPaths(c(file.path(author, "renv/library/macos/R-4.6/aarch64-apple-darwin23"), .libPaths()))
root <- file.path(author, "audit/decisions/brown_main_linkage_b_stage2_chest_prefit_recovery_001")
paths <- file.path(root, c("decision.md", "independent_acceptance.md", "dispatch_manifest.csv", "dispatch_message.md",
  "dispatch_receipt.md", "exact_owner_copy_map.csv", "process_preflight.json", "seal_receipt.R"))
out <- file.path(root, "dispatch_receipt_manifest.csv")
sha <- function(p) unname(digest::digest(p, algo = "sha256", file = TRUE))
stopifnot(as.character(getRversion()) == "4.6.1", !file.exists(out), !anyDuplicated(paths), !(out %in% paths))
m <- data.frame(path = paths, bytes = unname(file.info(paths)$size), sha256 = unname(vapply(paths, sha, character(1))))
write.csv(m, out, row.names = FALSE)
v <- read.csv(out)
stopifnot(nrow(v) == 8L, identical(v$sha256, unname(vapply(v$path, sha, character(1)))))
cat(sprintf("CHEST_PREFIT_RECEIPT=PASS rows=8 sha=%s\n", sha(out)))
