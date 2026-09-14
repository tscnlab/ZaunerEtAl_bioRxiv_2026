root <- "/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026/audit/decisions/brown_main_linkage_b_stage2_temporal_transport_recovery_001"
.libPaths(c(
  "/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026/renv/library/macos/R-4.6/aarch64-apple-darwin23",
  .libPaths()
))
stopifnot(as.character(getRversion()) == "4.6.1")
sha <- function(p) unname(digest::digest(p, file = TRUE, algo = "sha256"))
paths <- file.path(
  root,
  c(
    "dispatch_receipt.md",
    "decision.md",
    "independent_acceptance.md",
    "dispatch_manifest.csv",
    "exact_owner_copy_map.csv",
    "audit_compute_accounting.csv",
    "independent_evidence/supervisor_checks.csv",
    "seal_receipt.R"
  )
)
manifest <- file.path(root, "dispatch_receipt_manifest.csv")
stopifnot(
  !file.exists(manifest),
  all(file.exists(paths)),
  !anyDuplicated(paths),
  !manifest %in% paths
)
m <- data.frame(
  path = paths,
  bytes = unname(file.info(paths)$size),
  sha256 = unname(vapply(paths, sha, character(1)))
)
write.csv(m, manifest, row.names = FALSE)
z <- read.csv(manifest)
stopifnot(
  identical(z$sha256, unname(vapply(z$path, sha, character(1)))),
  all(z$bytes == unname(file.info(z$path)$size))
)
cat(sprintf(
  "TEMPORAL_TRANSPORT_RECEIPT=PASS rows=%d sha=%s\n",
  nrow(z),
  sha(manifest)
))
