stopifnot(as.character(getRversion()) == "4.6.1")
d <- "audit/report_harmonization/final_documents_2026_09_13"
p <- "audit/report_harmonization/final_site_promotion_2026_09_14"
s <- "audit/report_harmonization/final_site_integration_2026_09_14"
sha <- function(path) {
  con <- file(path, "rb")
  on.exit(close(con))
  as.character(openssl::sha256(con))
}
out1 <- file.path(d, "site013_independent_completion_acceptance_manifest.csv")
out2 <- file.path(d, "writer012_html_visual_release_order_014_receipt_manifest.csv")
stopifnot(!file.exists(out1), !file.exists(out2))
owner <- read.csv(file.path(p, "completion_manifest.csv"), stringsAsFactors = FALSE)
stopifnot(nrow(owner) == 89L, !anyDuplicated(owner$path),
  !"completion_manifest.csv" %in% owner$path,
  all(file.info(file.path(p, owner$path))$size == owner$bytes),
  all(vapply(file.path(p, owner$path), sha, "") == owner$sha256))
plan <- read.csv(file.path(p, "evidence/changed_paths26.csv"), stringsAsFactors = FALSE, na.strings = character())
allowed <- read.csv(file.path(s, "evidence/website_promotion_manifest.csv"), stringsAsFactors = FALSE, na.strings = character())
stopifnot(nrow(plan) == 26L, identical(plan$sequence, 1:26), !anyDuplicated(plan$target),
  identical(plan$target[1:25], allowed$target),
  identical(plan$post_sha256[1:25], allowed$candidate_sha256),
  identical(plan$action[1:25], allowed$action),
  plan$target[[26]] == "audit/report_harmonization/phase4_corpus_manifest.csv",
  all(vapply(plan$target, sha, "") == plan$post_sha256),
  all(vapply(plan$staged, sha, "") == plan$post_sha256),
  all(file.info(plan$target)$size == plan$bytes))
journal <- lapply(readLines(file.path(p, "transaction_journal.jsonl")), jsonlite::fromJSON)
done <- Filter(function(x) identical(x$event, "replace_complete"), journal)
stopifnot(length(done) == 26L, identical(vapply(done, function(x) x$sequence, 0L), 1:26),
  identical(vapply(done, function(x) x$target, ""), plan$target),
  identical(vapply(done, function(x) x$sha256, ""), plan$post_sha256),
  tail(journal, 1)[[1]]$event == "transaction_complete", tail(journal, 1)[[1]]$corpus_last)
old <- read.csv(file.path(s, "backup/audit/report_harmonization/phase4_corpus_manifest.csv"),
  colClasses = "character", na.strings = character(), check.names = FALSE)
new <- read.csv("audit/report_harmonization/phase4_corpus_manifest.csv",
  colClasses = "character", na.strings = character(), check.names = FALSE)
stopifnot(identical(dim(old), dim(new)), nrow(new) == 37L, identical(names(old), names(new)),
  identical(old$source_sha256, new$source_sha256), identical(old$source, new$source))
delta <- which(old != new, arr.ind = TRUE)
stopifnot(nrow(delta) == 2L, identical(delta[, "row"], 1:2),
  all(colnames(new)[delta[, "col"]] == "html_sha256"),
  identical(new$expected_html[1:2], plan$target[1:2]))
http <- read.csv(file.path(p, "evidence/http_download_checks.csv"), stringsAsFactors = FALSE)
stopifnot(nrow(http) == 22L, all(http$head_status == 200L), all(http$get_status == 200L),
  all(vapply(file.path("_build/nathealth", http$path), sha, "") == http$sha256))
seal <- function(paths, output) {
  paths <- sort(unique(paths))
  stopifnot(!output %in% paths, all(file.exists(paths)), !any(file.info(paths)$isdir),
    !anyDuplicated(normalizePath(paths)), !any(nzchar(Sys.readlink(paths))))
  write.csv(data.frame(path = paths, bytes = file.info(paths)$size,
    sha256 = vapply(paths, sha, "")), output, row.names = FALSE)
  x <- read.csv(output, stringsAsFactors = FALSE)
  stopifnot(!anyDuplicated(x$path), !output %in% x$path,
    all(file.info(x$path)$size == x$bytes), all(vapply(x$path, sha, "") == x$sha256))
  nrow(x)
}
self <- file.path(d, "seal_site013_completion_and_html014_receipt.R")
site_paths <- file.path(p, c("promotion_return.md", "completion_manifest.csv", "completion_seal.json",
  "transaction_plan.json", "transaction_journal.jsonl", "evidence/changed_paths26.csv",
  "evidence/production_safe_point.json", "evidence/post_closure_summary.json",
  "evidence/browser_observations.json", "evidence/server_lifecycle.json",
  "evidence/no_listener_check.txt", "evidence/production_static_summary.json",
  "evidence/content_reconciliation_R.csv", "evidence/http_download_checks.csv"))
a <- seal(c(file.path(d, "site013_independent_completion_acceptance.md"), self,
  site_paths, file.path(d, "writer012_independent_evidence/site013_safe_fixed3869_recheck.csv"),
  file.path(d, "writer012_independent_evidence/site013_safe_live914_recheck.csv"),
  file.path(d, "writer012_independent_evidence/site013_independent_browser_safe_point.txt")), out1)
b <- seal(c(file.path(d, c("writer012_html_visual_release_order_014_receipt.md",
  "writer012_html_visual_release_order_014.md", "writer012_html_visual_release_order_014_manifest.csv",
  "writer012_nonbrowser_independent_review.md", "writer012_nonbrowser_independent_review_manifest.csv")),
  out1, self), out2)
cat(sprintf("SITE013_ACCEPTED_HTML014_RECEIPT=PASS site89 transaction26 corpus2cells http22 acceptance%d receipt%d R=4.6.1\n", a, b))
for (f in c(file.path(d, "site013_independent_completion_acceptance.md"), out1,
  file.path(d, "writer012_html_visual_release_order_014_receipt.md"), out2)) {
  cat(sha(f), file.info(f)$size, f, "\n")
}
