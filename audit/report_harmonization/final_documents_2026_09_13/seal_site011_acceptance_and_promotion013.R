stopifnot(as.character(getRversion()) == "4.6.1")
coord <- "audit/report_harmonization/final_documents_2026_09_13"
owner <- "audit/report_harmonization/final_site_integration_2026_09_14"
scratch <- "/private/tmp/site011-independent.r9PH4p"
evidence <- file.path(coord, "site011_independent_evidence")
acceptance <- file.path(coord, "site011_candidate_independent_acceptance.md")
acceptance_manifest <- file.path(coord, "site011_candidate_independent_acceptance_manifest.csv")
order <- file.path(coord, "final_site_promotion_order_013.md")
dispatch <- file.path(coord, "final_site_promotion_order_013_dispatch_manifest.csv")
self <- file.path(coord, "seal_site011_acceptance_and_promotion013.R")
sha <- function(path) {
  con <- file(path, "rb")
  on.exit(close(con))
  as.character(openssl::sha256(con))
}
pin <- function(path, hash) {
  stopifnot(file.exists(path), !file.info(path)$isdir, sha(path) == hash)
}
audit <- function(manifest, base, count) {
  x <- read.csv(manifest, stringsAsFactors = FALSE)
  stopifnot(nrow(x) == count, all(c("path", "bytes", "sha256") %in% names(x)),
    !anyDuplicated(x$path), !any(grepl("(^/|(^|/)\\.\\.(/|$))", x$path)))
  paths <- if (base == "") x$path else file.path(base, x$path)
  stopifnot(all(file.exists(paths)), !any(file.info(paths)$isdir),
    !any(nzchar(Sys.readlink(paths))), !anyDuplicated(normalizePath(paths)),
    !normalizePath(manifest) %in% normalizePath(paths))
  x$actual_bytes <- file.info(paths)$size
  x$actual_sha256 <- vapply(paths, sha, "")
  x$exact <- x$actual_bytes == x$bytes & x$actual_sha256 == x$sha256
  stopifnot(all(x$exact))
  x
}
tree_audit <- function(base, inventory, count) {
  x <- audit(inventory, base, count)
  all_paths <- list.files(base, recursive = TRUE, all.files = TRUE,
    include.dirs = TRUE, no.. = TRUE, full.names = TRUE)
  stopifnot(!any(nzchar(Sys.readlink(c(base, all_paths)))))
  live <- list.files(base, recursive = TRUE, all.files = TRUE, no.. = TRUE)
  stopifnot(setequal(live, x$path))
  x
}
manifest_rows <- function(paths) {
  paths <- sort(unique(paths))
  stopifnot(all(file.exists(paths)), !any(file.info(paths)$isdir),
    !any(nzchar(Sys.readlink(paths))), !anyDuplicated(normalizePath(paths)))
  data.frame(path = paths, bytes = file.info(paths)$size,
    sha256 = vapply(paths, sha, ""), stringsAsFactors = FALSE)
}
stopifnot(!dir.exists(evidence), !file.exists(acceptance_manifest),
  !file.exists(dispatch), file.exists(acceptance), file.exists(order))
for (p in c(acceptance, order)) {
  stopifnot(!any(grepl("\u2014", readLines(p), fixed = TRUE)))
}
pins <- c(
  "candidate_return.md" = "fa7d95b70cbdb06f222fde6559e71b71817aabef1870780a90d1d566967d47d4",
  "completion_manifest.csv" = "34c5804faa43c9f71bdd2c9be7cc8bc3e03f85b84227a6d94f10f9ed349e1199",
  "completion_seal.json" = "639d0cbd4c2f525e786d8a0564a0ff07c7335131ca9d6559ae9b93d79a6aa3fa",
  "evidence/candidate_inventory.csv" = "0610b27e315cf73fd2d55bb4116d87c6706ad7de92d21e5f5dfd767034dbb862",
  "evidence/website_promotion_manifest.csv" = "2806cd2e3cd0a88d84c8ecca5abcffad9d0f0f5f72fbe2d19373e3049494971d",
  "evidence/phase4_corpus_manifest.prospective.csv" = "b5b4b009db76e6f869f324a360e6eeafdf63438539382f1b8d85058f277eb93f",
  "evidence/prospective_corpus_reverse.csv" = "c18fd550a144da109e7dbe85cc593d13adb129fd26d5efaaf376fed3fbbd2345",
  "evidence/five_backup_manifest.csv" = "f0de0d78196dd2543a36a19be2a48e990a75fab465040be931c463f0a28ddef0"
)
for (i in seq_along(pins)) pin(file.path(owner, names(pins)[[i]]), pins[[i]])
owner_check <- audit(file.path(owner, "completion_manifest.csv"), owner, 1026L)
candidate_check <- tree_audit(file.path(owner, "candidate_build"),
  file.path(owner, "evidence/candidate_inventory.csv"), 914L)
live_check <- tree_audit("_build/nathealth",
  file.path(owner, "evidence/baseline_inventory.csv"), 893L)
old_dispatch <- audit(file.path(coord, "final_site_candidate_order_011_dispatch_manifest.csv"), "", 47L)
fixed <- read.csv(file.path(owner, "evidence/input_preflight.csv"), stringsAsFactors = FALSE)
stopifnot(nrow(fixed) == 1771L, all(file.exists(fixed$path)),
  all(file.info(fixed$path)$size == fixed$bytes),
  all(vapply(fixed$path, sha, "") == fixed$sha256))
promotion <- read.csv(file.path(owner, "evidence/website_promotion_manifest.csv"),
  stringsAsFactors = FALSE, na.strings = character())
stopifnot(nrow(promotion) == 25L, !anyDuplicated(promotion$target),
  sum(promotion$action == "replace") == 4L, sum(promotion$action == "add") == 21L,
  all(startsWith(promotion$target, "_build/nathealth/")),
  !any(grepl("(^|/)\\.\\.(/|$)", promotion$target)),
  all(file.info(promotion$candidate)$size == promotion$bytes),
  all(vapply(promotion$candidate, sha, "") == promotion$candidate_sha256))
replace <- promotion$action == "replace"
stopifnot(all(vapply(promotion$target[replace], sha, "") == promotion$preimage_sha256[replace]),
  !any(file.exists(promotion$target[!replace])))
backups <- read.csv(file.path(owner, "evidence/five_backup_manifest.csv"), stringsAsFactors = FALSE)
stopifnot(nrow(backups) == 5L, !anyDuplicated(backups$live_target),
  all(file.info(backups$backup)$size == backups$bytes),
  all(vapply(backups$backup, sha, "") == backups$sha256),
  all(file.info(backups$live_target)$size == backups$bytes),
  all(vapply(backups$live_target, sha, "") == backups$sha256))
checks <- read.csv(file.path(scratch, "R_replay/content_reconciliation_R.csv"))
stopifnot(nrow(checks) == 75L, all(checks$pass),
  sha(file.path(scratch, "R_replay/content_reconciliation_R.csv")) ==
    sha(file.path(owner, "evidence/content_reconciliation_R.csv")))
replayed <- c("website_promotion_manifest.csv", "phase4_corpus_manifest.prospective.csv",
  "prospective_corpus_reverse.csv", "source_artifact_authority.csv",
  "input_postflight.csv", "candidate_inventory.postflight.csv", "static_checks.csv")
for (f in replayed) {
  stopifnot(sha(file.path(scratch, "infrastructure_replay", f)) == sha(file.path(owner, "evidence", f)))
}
summary <- jsonlite::read_json(file.path(scratch, "independent_summary.json"), simplifyVector = TRUE)
stopifnot(summary$owner_members == 1026L, summary$static_checks == 53703L,
  summary$postflight_checks == 3632L, summary$owner_package_unchanged, summary$live_unchanged)
stopifnot(file.exists(file.path(scratch, "browser_independent_review.md")))
dir.create(evidence)
for (f in list.files(scratch, recursive = TRUE, full.names = FALSE, all.files = TRUE, no.. = TRUE)) {
  from <- file.path(scratch, f)
  to <- file.path(evidence, f)
  stopifnot(!nzchar(Sys.readlink(from)))
  dir.create(dirname(to), recursive = TRUE, showWarnings = FALSE)
  stopifnot(file.copy(from, to, overwrite = FALSE), sha(from) == sha(to))
}
for (n in c("owner_check", "candidate_check", "live_check")) {
  write.csv(get(n), file.path(evidence, paste0("seal_time_", n, ".csv")), row.names = FALSE)
}
capture.output(sessionInfo(), file = file.path(evidence, "sealer_R_sessionInfo.txt"))
fixed_owner <- file.path(owner, c(names(pins), "evidence/baseline_inventory.csv",
  "evidence/input_preflight.csv", "evidence/browser_qa_report.md",
  "evidence/server_lifecycle.json", "evidence/http_download_checks.csv"))
accept_paths <- c(acceptance, self, fixed_owner,
  list.files(evidence, recursive = TRUE, full.names = TRUE))
stopifnot(!acceptance_manifest %in% accept_paths, !dispatch %in% accept_paths)
a <- manifest_rows(accept_paths)
write.csv(a, acceptance_manifest, row.names = FALSE)
invisible(audit(acceptance_manifest, "", nrow(a)))
dispatch_paths <- c(order, acceptance_manifest, acceptance, self,
  fixed_owner, old_dispatch$path, promotion$candidate, backups$backup,
  backups$live_target, file.path(coord, "writer_a4_display_candidate_order_012.md"),
  file.path(coord, "writer_a4_display_candidate_order_012_receipt.md"))
stopifnot(!dispatch %in% dispatch_paths)
d <- manifest_rows(dispatch_paths)
write.csv(d, dispatch, row.names = FALSE)
invisible(audit(dispatch, "", nrow(d)))
cat(sprintf("SITE011_ACCEPTANCE_AND_013_DISPATCH=PASS owner1026 candidate914 live893 fixed1771 acceptance%d dispatch%d R=%s\n",
  nrow(a), nrow(d), as.character(getRversion())))
for (p in c(acceptance, acceptance_manifest, order, dispatch)) {
  cat(sha(p), file.info(p)$size, p, "\n")
}
