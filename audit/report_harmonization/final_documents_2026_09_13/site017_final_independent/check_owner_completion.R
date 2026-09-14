stopifnot(getRversion() == "4.6.1")
suppressPackageStartupMessages({library(digest); library(jsonlite)})
args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) == 1L, !dir.exists(args[[1]]))
out <- args[[1]]
project <- "/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026"
owner <- file.path(project, "audit/report_harmonization/final_site_reader_cleanup_2026_09_14")
evidence <- file.path(owner, "evidence")
sha <- function(p) digest(file = p, algo = "sha256")
exact <- function(p, h, size) file.exists(p) && !dir.exists(p) &&
  !nzchar(Sys.readlink(p)) && file.info(p)$size == size && sha(p) == h
csv <- function(p) read.csv(p, check.names = FALSE, stringsAsFactors = FALSE)
js <- function(p) fromJSON(p, simplifyVector = FALSE)
manifest <- csv(file.path(owner, "completion_manifest.csv"))
seal <- js(file.path(owner, "completion_seal.json"))
stopifnot(!anyDuplicated(manifest$path),
  !any(manifest$path %in% c("completion_manifest.csv", "completion_seal.json")),
  !any(grepl("(^/|(^|/)\\.\\.(/|$))", manifest$path)),
  seal$non_circular, nrow(manifest) == seal$members,
  sha(file.path(owner, "completion_manifest.csv")) == seal$manifest_sha256)
member_pass <- vapply(seq_len(nrow(manifest)), function(i)
  exact(file.path(owner, manifest$path[[i]]), manifest$sha256[[i]], manifest$bytes[[i]]), logical(1))
stopifnot(all(member_pass))
tree <- list.files(owner, recursive = TRUE, all.files = TRUE, no.. = TRUE,
  include.dirs = TRUE, full.names = TRUE)
stopifnot(!any(nzchar(Sys.readlink(tree))))
tree <- tree[!file.info(tree)$isdir]
relative_tree <- substring(tree, nchar(owner) + 2L)
stopifnot(setequal(relative_tree, c(manifest$path, "completion_manifest.csv", "completion_seal.json")))
plan <- csv(file.path(evidence, "planned_operations.csv"))
stopifnot(nrow(plan) == 62L, !anyDuplicated(plan$target), sum(plan$action == "retire") == 15L,
  sum(plan$action == "replace") == 47L,
  tail(plan$target, 1L) == "audit/report_harmonization/phase4_corpus_manifest.csv")
plan_checks <- lapply(seq_len(nrow(plan)), function(i) {
  p <- plan[i, ]
  live <- file.path(project, p$target)
  stopifnot(exact(file.path(owner, p$backup), p$pre_sha256, p$pre_bytes))
  if (p$action == "retire") {
    stopifnot(!file.exists(live),
      exact(file.path(owner, "live_retired", p$target), p$pre_sha256, p$pre_bytes))
  } else {
    stopifnot(exact(live, p$post_sha256, p$post_bytes),
      exact(file.path(owner, p$candidate), p$post_sha256, p$post_bytes))
  }
  stopifnot(!file.exists(file.path(dirname(live), paste0(".order017-stage-", basename(live)))),
    !file.exists(file.path(dirname(live), paste0(".order017-rollback-", basename(live)))))
  data.frame(target = p$target, action = p$action, backup_exact = TRUE,
    installed_or_retired_exact = TRUE, staging_absent = TRUE)
})
journal <- lapply(readLines(file.path(evidence, "live_transaction_journal.jsonl")), fromJSON)
installed <- Filter(function(x) x$event == "installed", journal)
stopifnot(length(installed) == 62L,
  identical(vapply(installed, function(x) x$target, character(1)), plan$target),
  !file.exists(file.path(evidence, "live_rollback.json")))
for (f in c("candidate_checks.json", "fixture_suite.json", "candidate_browser_acceptance.json",
  "live_checks.json", "live_browser_acceptance.json")) {
  stopifnot(js(file.path(evidence, f))$status == "PASS")
}
browser_rows <- list()
for (mode in c("candidate", "live")) {
  qa <- file.path(evidence, paste0(mode, "_qa"))
  life <- js(file.path(qa, "server_lifecycle.json"))
  stopifnot(life$status == "stopped", js(file.path(qa, "http_summary.json"))$status == "PASS",
    js(file.path(qa, "teardown.json"))$status == "PASS")
  captures <- csv(file.path(qa, "browser_capture_manifest.csv"))
  stopifnot(nrow(captures) > 0L, !anyDuplicated(captures$image_path))
  for (i in seq_len(nrow(captures))) stopifnot(exact(file.path(owner, captures$image_path[[i]]),
    captures$sha256[[i]], captures$bytes[[i]]))
  browser_rows[[mode]] <- data.frame(mode = mode, captures = nrow(captures),
    lifecycle_stopped = TRUE, http_pass = TRUE, teardown_pass = TRUE)
}
stopifnot(sha(file.path(evidence, "helper_manifest.csv")) ==
  "f40d68b06f4878b5303672db00a56558b6b924d7b126d18710549424fea81d92")
summary <- js(file.path(evidence, "completion_summary.json"))
stopifnot(summary$status == "LOCAL_READER_SCOPE_COMPLETE_WITH_INHERITED_QUALIFICATIONS",
  summary$public_files == 899L, summary$public_replacements == 45L,
  summary$retirements == 15L, summary$unchanged_survivors == 854L,
  summary$reader_routes == 36L, summary$search_records == 938L,
  summary$sitemap_entries == 38L, summary$download_payloads_unchanged == 20L,
  summary$no_render_or_analysis, summary$no_writer_wakeup, summary$no_commit_push_upload)
protected <- csv(file.path(evidence, "protected_unique_baseline.csv"))
stopifnot(!anyDuplicated(protected$path))
protected$classification <- "unchanged"
protected$independently_exact <- FALSE
for (i in seq_len(nrow(protected))) {
  r <- protected[i, ]
  p <- if (startsWith(r$path, "/")) r$path else file.path(project, r$path)
  j <- match(r$path, plan$target)
  if (is.na(j)) {
    protected$independently_exact[[i]] <- exact(p, r$sha256, r$bytes)
  } else {
    stopifnot(r$sha256 == plan$pre_sha256[[j]], r$bytes == plan$pre_bytes[[j]])
    protected$classification[[i]] <- paste0("authorized_", plan$action[[j]])
    protected$independently_exact[[i]] <- if (plan$action[[j]] == "retire") !file.exists(p) else
      exact(p, plan$post_sha256[[j]], plan$post_bytes[[j]])
  }
}
stopifnot(all(protected$independently_exact))
dir.create(out, recursive = TRUE)
write.csv(cbind(manifest, independently_exact = member_pass),
  file.path(out, "owner_manifest_independent_verification.csv"), row.names = FALSE)
write.csv(do.call(rbind, plan_checks), file.path(out, "62_operation_independent_verification.csv"), row.names = FALSE)
write.csv(do.call(rbind, browser_rows), file.path(out, "browser_evidence_independent_verification.csv"), row.names = FALSE)
write.csv(protected, file.path(out, "protected_independent_verification.csv"), row.names = FALSE)
write_json(list(status = "PASS", R = as.character(getRversion()), members = nrow(manifest),
  operations = 62L, exact_retired_archives = 15L, protected_paths = nrow(protected),
  independent_visual_inspection = "recorded separately",
  owner_completion_manifest_sha256 = seal$manifest_sha256,
  preserved_inherited_qualifications = summary$qualifications),
  file.path(out, "owner_evidence_summary.json"), pretty = TRUE, auto_unbox = TRUE)
capture.output(sessionInfo(), file = file.path(out, "R_sessionInfo.txt"))
cat("ORDER017_OWNER_INDEPENDENT=PASS members=", nrow(manifest), " operations62 archives15 browser2\n", sep = "")
