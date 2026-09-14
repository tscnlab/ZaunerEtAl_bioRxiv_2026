stopifnot(as.character(getRversion()) == "4.6.1")
author <- "/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026"
scratch <- "/private/tmp/ba018-diagnostic-bookkeeping-review.zoYV0w"
root <- file.path(author, "audit/decisions/brown_main_linkage_b_stage2_diagnostic_status_export_stop_001")
owner_root <- "/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026/audit/analyses/brown_adherence/main_linkage_b_amendment/stage2/completion_v2/continued_final_package_003"
sha <- function(p) unname(digest::digest(p, algo = "sha256", file = TRUE))
stopifnot(!dir.exists(file.path(root, "independent_audit")), !file.exists(file.path(root, "independent_manifest.csv")))
files <- list.files(scratch, full.names = TRUE, recursive = TRUE, all.files = TRUE, no.. = TRUE)
stopifnot(all(Sys.readlink(files) == ""))
relative <- substring(files, nchar(scratch) + 2L)
dest <- file.path(root, "independent_audit", relative)
for (i in seq_along(files)) {
  dir.create(dirname(dest[i]), recursive = TRUE, showWarnings = FALSE)
  stopifnot(file.copy(files[i], dest[i], overwrite = FALSE, copy.date = TRUE))
}
stopifnot(identical(unname(vapply(files, sha, character(1))), unname(vapply(dest, sha, character(1)))))
m <- read.csv(file.path(owner_root, "final_manifest.csv"), stringsAsFactors = FALSE)
stopifnot(nrow(m) == 223L, !anyDuplicated(m$path), all(vapply(m$path, sha, character(1)) == m$sha256))
all_paths <- unique(c(list.files(root, recursive = TRUE, full.names = TRUE), m$path, file.path(owner_root, c("final_manifest.csv", "final_manifest_verification.csv"))))
stopifnot(!file.path(root, "independent_manifest.csv") %in% all_paths)
seal <- data.frame(path = all_paths, sha256 = vapply(all_paths, sha, character(1)), bytes = unname(file.info(all_paths)$size))
write.csv(seal, file.path(root, "independent_manifest.csv"), row.names = FALSE)
stopifnot(all(vapply(seal$path, sha, character(1)) == seal$sha256))
cat(sprintf("BROWN_DIAGNOSTIC_STOP_SEAL=PASS members=%s decision=%s manifest=%s\n", nrow(seal), sha(file.path(root, "disposition.md")), sha(file.path(root, "independent_manifest.csv"))))
