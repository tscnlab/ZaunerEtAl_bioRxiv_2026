stopifnot(getRversion() == "4.6.1")
suppressPackageStartupMessages({library(digest); library(jsonlite)})
d <- "audit/report_harmonization/final_documents_2026_09_13"
p <- "audit/report_harmonization/final_site_a4_promotion_2026_09_14"
t <- "audit/report_harmonization/final_site_a4_delta_2026_09_14"
scratch <- "/private/tmp/site016-independent.QIbkxZ50"
dest <- file.path(d, "site016_final_independent")
record <- file.path(d, "site016_final_independent_acceptance.md")
output <- file.path(d, "site016_final_independent_acceptance_manifest.csv")
self <- file.path(d, "seal_site016_final_acceptance.R")
stopifnot(!dir.exists(dest), !file.exists(output))
sha <- function(path) digest(file = path, algo = "sha256")
exact <- function(path, hash, bytes = NULL) {
  stopifnot(file.exists(path), !dir.exists(path), !nzchar(Sys.readlink(path)), sha(path) == hash)
  if (!is.null(bytes)) stopifnot(file.info(path)$size == bytes)
}
manifest <- file.path(p, "completion_manifest.csv")
exact(manifest, "160d3c47ca07419ba26fb57900637efa7a93f5c3ed48dcede44d6a2d4cab43eb", 174930)
exact(file.path(p, "completion_seal.json"), "f7eb885667564d84107fea24c8f222a6f12e6444cf528943a4226d68ac7883bd")
exact(file.path(p, "completion_report.md"), "9cddf8dbbabbbf14382295e15f228f8257ab3d9ce5e3e8e45ee564385bff4eb2", 8635)
m <- read.csv(manifest, stringsAsFactors = FALSE)
stopifnot(nrow(m) == 1120L, !anyDuplicated(m$path),
 !any(c("completion_manifest.csv", "completion_seal.json") %in% m$path))
full <- file.path(p, m$path)
for (i in seq_len(nrow(m))) exact(full[[i]], m$sha256[[i]], m$bytes[[i]])
files <- list.files(p, recursive = TRUE, all.files = TRUE, full.names = TRUE, no.. = TRUE, include.dirs = TRUE)
stopifnot(!any(nzchar(Sys.readlink(files))))
files <- files[!file.info(files)$isdir]
stopifnot(setequal(files, c(full, manifest, file.path(p, "completion_seal.json"))))
installed <- fromJSON(file.path(scratch, "installed_summary.json"))
stopifnot(installed$status == "PASS", installed$installed == 914L, installed$protected_rows == 4617L,
 installed$classified_transition_rows == 24L, installed$exact_replacements == 7L, installed$corpus_last)
inventory <- read.csv(file.path(scratch, "installed914_exact.csv"), stringsAsFactors = FALSE)
for (base in c("_build/nathealth", file.path(t, "candidate_build"))) {
  paths <- list.files(base, recursive = TRUE, all.files = TRUE, full.names = TRUE, no.. = TRUE, include.dirs = TRUE)
  stopifnot(!any(nzchar(Sys.readlink(paths))))
  paths <- paths[!file.info(paths)$isdir]
  stopifnot(setequal(paths, file.path(base, inventory$path)))
  for (i in seq_len(nrow(inventory))) exact(file.path(base, inventory$path[[i]]), inventory$sha256[[i]], inventory$bytes[[i]])
}
seven <- read.csv(file.path(p, "evidence/final_seven_identities.csv"), stringsAsFactors = FALSE)
stopifnot(nrow(seven) == 7L, identical(seven$sequence, 1:7))
for (i in seq_len(7L)) {
  exact(seven$target[[i]], seven$sha256[[i]], seven$bytes[[i]])
  exact(seven$backup[[i]], seven$preimage_sha256[[i]], seven$preimage_bytes[[i]])
}
closure <- fromJSON(file.path(p, "evidence/final_post_summary.json"))
browser <- fromJSON(file.path(p, "evidence/browser_observations.json"))
life <- fromJSON(file.path(p, "evidence/server_lifecycle.json"))
stopifnot(closure$all_exact, closure$checks == 7763L, closure$authorized_transition_rows == 46L,
 browser$short_production_QA_complete, !browser$genuinely_new_defect, browser$viewport_reset,
 browser$own_tabs_closed, length(browser$final_tabs) == 0L,
 life$status == "stopped", life$host == "127.0.0.1", life$port == 59586L)
reviewed <- c("P1440-Table2", "P1440-Table2-right", "P1440-S4-full", "S708-S7-right", "S708-S7-bottom", "S1440-S2")
captures <- read.csv(file.path(p, "evidence/browser_capture_manifest.csv"), stringsAsFactors = FALSE)
stopifnot(nrow(captures) == 22L, all(reviewed %in% captures$observation_id))
review <- captures[match(reviewed, captures$observation_id), ]
review$central_visual_disposition <- c("Complete left portion; contained horizontal scroll", "Complete right columns and notes via scroll",
 "Table, notes and caption complete", "Exact fitted-sample column accessible at narrow width", "Lower rows and notes accessible via contained scroll", "Author-accepted secondary typography preserved")
dir.create(dest)
sources <- list.files(scratch, recursive = TRUE, all.files = TRUE, full.names = TRUE, no.. = TRUE)
sources <- sources[!file.info(sources)$isdir]
for (path in sources) {
  target <- file.path(dest, substring(path, nchar(scratch) + 2L))
  dir.create(dirname(target), recursive = TRUE, showWarnings = FALSE)
  stopifnot(!file.exists(target), file.copy(path, target), sha(path) == sha(target))
}
m$independent_exact <- TRUE
write.csv(m, file.path(dest, "owner1120_final_rehash.csv"), row.names = FALSE)
write.csv(review, file.path(dest, "central_visual_review_six.csv"), row.names = FALSE)
write_json(list(status = "INDEPENDENTLY_ACCEPTED_WITH_INHERITED_QUALIFICATIONS", owner_members = 1120L,
 live_files = 914L, candidate_files = 914L, replacements = 7L, corpus_last = TRUE,
 owner_screenshots = 22L, root_screenshots_inspected = 6L, browser_teardown_complete = TRUE,
 no_listener_independently_checked = TRUE, R = as.character(getRversion())),
 file.path(dest, "final_summary.json"), pretty = TRUE, auto_unbox = TRUE)
capture.output(sessionInfo(), file = file.path(dest, "final_seal_R_sessionInfo.txt"))
leaves <- list.files(dest, recursive = TRUE, full.names = TRUE)
leaves <- leaves[!file.info(leaves)$isdir]
paths <- sort(unique(c(record, self, leaves, manifest, file.path(p, c("completion_report.md", "completion_seal.json",
 "transaction_journal.jsonl", "evidence/final_seven_identities.csv", "evidence/final_post_summary.json",
 "evidence/browser_observations.json", "evidence/browser_capture_manifest.csv", "evidence/production_safe_point.json",
 "evidence/server_lifecycle.json")), file.path(p, "evidence", review$image_path),
 file.path(d, c("site_a4_delta_promotion_order_016.md", "site_a4_delta_promotion_order_016_dispatch_manifest.csv",
 "site_a4_delta_promotion_order_016_dispatch_receipt.md", "site015a_candidate_independent_acceptance_manifest.csv",
 "order016_word_author_approval_addendum.md", "order016_word_author_approval_addendum_manifest.csv")), seven$target)))
stopifnot(!output %in% paths, !anyDuplicated(normalizePath(paths)), !any(nzchar(Sys.readlink(paths))), all(file.exists(paths)))
seal <- data.frame(path = paths, bytes = file.info(paths)$size, sha256 = vapply(paths, sha, character(1)))
write.csv(seal, output, row.names = FALSE)
z <- read.csv(output, stringsAsFactors = FALSE)
stopifnot(!anyDuplicated(z$path), all(vapply(z$path, sha, character(1)) == z$sha256), all(file.info(z$path)$size == z$bytes))
cat(sprintf("ORDER016_FINAL_CENTRAL_ACCEPTANCE=SEALED members=%d owner1120 live914 replacements7 browser_closed\n", nrow(z)))
for (path in c(record, output)) cat(sha(path), file.info(path)$size, path, "\n")
