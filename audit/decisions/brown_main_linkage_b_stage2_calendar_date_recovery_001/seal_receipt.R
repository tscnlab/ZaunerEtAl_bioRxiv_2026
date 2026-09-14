# Non-circular infrastructure receipt, no scientific object loading.
author <- "/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026"
.libPaths(c(
  file.path(author, "renv/library/macos/R-4.6/aarch64-apple-darwin23"),
  .libPaths()
))
stopifnot(as.character(getRversion()) == "4.6.1")
root <- file.path(
  author,
  "audit/decisions/brown_main_linkage_b_stage2_calendar_date_recovery_001"
)
paths <- file.path(
  root,
  c(
    "decision.md",
    "independent_acceptance.md",
    "dispatch_manifest.csv",
    "dispatch_message.md",
    "dispatch_receipt.md",
    "process_preflight.json",
    "exact_owner_copy_map.csv",
    "seal_receipt.R"
  )
)
target <- file.path(root, "dispatch_receipt_manifest.csv")
sha <- function(p) unname(digest::digest(p, algo = "sha256", file = TRUE))
stopifnot(
  !file.exists(target),
  !anyDuplicated(paths),
  !target %in% paths,
  all(file.exists(paths))
)
m <- data.frame(
  path = paths,
  bytes = unname(file.info(paths)$size),
  sha256 = unname(vapply(paths, sha, character(1)))
)
write.csv(m, target, row.names = FALSE)
z <- read.csv(target)
stopifnot(
  nrow(z) == 8L,
  identical(z$sha256, unname(vapply(z$path, sha, character(1)))),
  all(z$bytes == file.info(z$path)$size)
)
cat(sprintf("CALENDAR_RECEIPT=PASS rows=8 sha=%s\n", sha(target)))
