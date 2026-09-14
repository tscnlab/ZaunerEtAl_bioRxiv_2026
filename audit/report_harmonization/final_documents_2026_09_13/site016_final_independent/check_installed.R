stopifnot(getRversion() == "4.6.1")
suppressPackageStartupMessages({library(digest); library(jsonlite)})
root <- "/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026"
out <- "/private/tmp/site016-independent.QIbkxZ50"
old <- file.path(root, "audit/report_harmonization/final_site_a4_delta_2026_09_14")
accepted <- file.path(old, "verification_recovery_015a/evidence")
prom <- file.path(root, "audit/report_harmonization/final_site_a4_promotion_2026_09_14")
sha <- function(p) digest(file = p, algo = "sha256")
exact <- function(p, hash, bytes) {
  stopifnot(file.exists(p), !dir.exists(p), !nzchar(Sys.readlink(p)),
            sha(p) == hash, file.info(p)$size == bytes)
}
m <- read.csv(file.path(accepted, "website_promotion_manifest.csv"), stringsAsFactors = FALSE)
back <- read.csv(file.path(accepted, "seven_backup_manifest.csv"), stringsAsFactors = FALSE)
plan <- fromJSON(file.path(prom, "transaction_plan.json"))$entries
stopifnot(nrow(m) == 6L, nrow(back) == 7L, nrow(plan) == 7L,
          identical(plan$target[1:6], m$target), all(plan$action == "replace"),
          identical(plan$sequence, 1:7), identical(plan$post_sha256[1:6], m$candidate_sha256),
          identical(plan$pre_sha256[1:6], m$preimage_sha256),
          plan$target[[7]] == "audit/report_harmonization/phase4_corpus_manifest.csv",
          plan$post_sha256[[7]] == "642161dfc1ec18572b8b8c124546060c8f889683ebf7ceb8e5e43dc785f77669")
for (i in seq_len(7L)) {
  exact(file.path(root, plan$target[[i]]), plan$post_sha256[[i]], plan$bytes[[i]])
  exact(file.path(root, plan$source[[i]]), plan$post_sha256[[i]], plan$bytes[[i]])
  exact(file.path(root, plan$staged[[i]]), plan$post_sha256[[i]], plan$bytes[[i]])
  exact(file.path(root, plan$backup[[i]]), plan$pre_sha256[[i]], plan$pre_bytes[[i]])
  exact(file.path(root, plan$historical_backup[[i]]), plan$pre_sha256[[i]], plan$pre_bytes[[i]])
  stopifnot(!file.exists(file.path(root, plan$temporary[[i]])))
}
journal <- lapply(readLines(file.path(prom, "transaction_journal.jsonl")), fromJSON)
completed <- Filter(function(z) identical(z$event, "replace_complete"), journal)
stopifnot(length(completed) == 7L,
 identical(vapply(completed, function(z) z$target, character(1)), plan$target),
 identical(tail(journal, 1L)[[1]]$event, "transaction_complete"),
 !any(vapply(journal, function(z) grepl("rollback|failure", z$event), logical(1))))
inventory <- read.csv(file.path(accepted, "candidate_inventory.csv"), stringsAsFactors = FALSE)
stopifnot(nrow(inventory) == 914L, !anyDuplicated(inventory$path))
for (base in c(file.path(root, "_build/nathealth"), file.path(old, "candidate_build"))) {
  files <- list.files(base, recursive = TRUE, all.files = TRUE, full.names = TRUE, no.. = TRUE, include.dirs = TRUE)
  stopifnot(!any(nzchar(Sys.readlink(c(base, files)))))
  files <- files[!file.info(files)$isdir]
  stopifnot(setequal(files, file.path(base, inventory$path)))
  for (i in seq_len(nrow(inventory))) exact(file.path(base, inventory$path[[i]]), inventory$sha256[[i]], inventory$bytes[[i]])
}
protected <- read.csv(file.path(accepted, "post_protected_checks.csv"), stringsAsFactors = FALSE)
stopifnot(nrow(protected) == 4617L)
protected$classification <- "unchanged_live_exact"
for (i in seq_len(nrow(protected))) {
  hit <- which(plan$target == protected$path[[i]] & plan$pre_sha256 == protected$expected_sha256[[i]])
  if (length(hit)) {
    stopifnot(length(hit) == 1L, protected$bytes[[i]] == plan$pre_bytes[[hit]])
    exact(file.path(root, plan$target[[hit]]), plan$post_sha256[[hit]], plan$bytes[[hit]])
    exact(file.path(root, plan$backup[[hit]]), protected$expected_sha256[[i]], protected$bytes[[i]])
    protected$classification[[i]] <- "exact_authorized_live_transition_with_retained_preimage"
  } else {
    protected_path <- protected$path[[i]]
    if (!startsWith(protected_path, "/")) protected_path <- file.path(root, protected_path)
    exact(protected_path, protected$expected_sha256[[i]], protected$bytes[[i]])
  }
}
transition_rows <- protected$classification != "unchanged_live_exact"
stopifnot(setequal(protected$path[transition_rows], plan$target), sum(transition_rows) == 24L)
old_corpus <- read.csv(file.path(root, plan$backup[[7]]), stringsAsFactors = FALSE)
new_corpus <- read.csv(file.path(root, plan$target[[7]]), stringsAsFactors = FALSE)
stopifnot(nrow(new_corpus) == 37L,
 identical(old_corpus[setdiff(names(old_corpus), "html_sha256")], new_corpus[setdiff(names(new_corpus), "html_sha256")]),
 identical(which(old_corpus$html_sha256 != new_corpus$html_sha256), 1:2))
for (f in c("content_reconciliation_R.csv", "targeted_index.html.csv", "targeted_supplementary_information.html.csv")) {
  x <- read.csv(file.path(prom, "evidence", f), stringsAsFactors = FALSE)
  stopifnot(nrow(x) == if (startsWith(f, "content")) 75L else 15L, all(x$pass))
}
static <- fromJSON(file.path(prom, "evidence/production_static_summary.json"))
http <- fromJSON(file.path(prom, "evidence/http_download_summary.json"))
stopifnot(static$all_pass, static$checks == 53724L, http$all_exact, http$downloads == 22L)
write.csv(protected, file.path(out, "protected4617_classified.csv"), row.names = FALSE)
write.csv(plan, file.path(out, "installed_seven_targets.csv"), row.names = FALSE)
write.csv(inventory, file.path(out, "installed914_exact.csv"), row.names = FALSE)
capture.output(sessionInfo(), file = file.path(out, "R_sessionInfo.txt"))
write_json(list(status = "PASS", installed = 914L, candidate = 914L, exact_replacements = 7L,
 corpus_last = TRUE, protected_rows = 4617L, classified_transition_rows = sum(transition_rows),
 changed_corpus_cells = 2L, recorded_content_checks = c(75L, 15L, 15L),
 static_checks = 53724L, HTTP_checks = 22L, browser_completion = "owner still finishing at audit time",
 R = as.character(getRversion()), no_project_writes = TRUE),
 file.path(out, "installed_summary.json"), pretty = TRUE, auto_unbox = TRUE)
cat("ORDER016_INDEPENDENT_INSTALLED=PASS live914 candidate914 replacements7 corpus_last protected4617=4593+24 R75+15+15 static53724 HTTP22 browser_pending\n")
