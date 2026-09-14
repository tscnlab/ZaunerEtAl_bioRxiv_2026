stopifnot(getRversion() == "4.6.1")
suppressPackageStartupMessages({library(digest);library(jsonlite)})
d <- "audit/report_harmonization/final_documents_2026_09_13"
owner <- "audit/report_harmonization/final_site_reader_cleanup_2026_09_14/evidence/semantic_preflight_R"
dest <- file.path(d, "order017_inherited_classification")
output <- file.path(d, "order017_inherited_nonreader_classification_manifest.csv")
stopifnot(!dir.exists(dest), !file.exists(output))
sha <- function(p) digest(file = p, algo = "sha256")
five <- read.csv("/private/tmp/site017-central-audit.96EdQYvx/five_inherited_links.csv", stringsAsFactors = FALSE)
stopifnot(nrow(five) == 5L, all(five$unchanged_reference), all(five$occurrences == 1L), !anyDuplicated(five$path))
summary <- fromJSON(file.path(owner, "semantics_summary_R.json"))
stopifnot(summary$status == "PASS", summary$routes == 44L, summary$inherited_failure_tokens == 12839L,
  summary$affected_routes == 11L, summary$no_new_or_concealed_failures, summary$strict_entries_valid)
before <- read.csv(file.path(owner, "complete_inherited_semantic_failures_R.csv"), stringsAsFactors = FALSE)
after <- read.csv(file.path(owner, "complete_candidate_semantic_failures_R.csv"), stringsAsFactors = FALSE)
stopifnot(identical(before, after), nrow(before) == 12839L)
dir.create(dest)
inputs <- c("/private/tmp/site017-central-audit.96EdQYvx/five_inherited_links.csv",
  file.path(owner, c("semantics_summary_R.json", "complete_inherited_semantic_failures_R.csv",
    "complete_candidate_semantic_failures_R.csv", "all44_semantic_contract_R.csv", "semantics_R_sessionInfo.txt")),
  "/private/tmp/site017-central-audit.96EdQYvx/candidate_independent/independent_summary.json")
for (p in inputs) {
  target <- file.path(dest, basename(p))
  stopifnot(!file.exists(target), file.copy(p, target), sha(p) == sha(target))
}
paths <- c(file.path(d, c("order017_inherited_nonreader_classification.md", "seal_order017_inherited_classification.R")),
  list.files(dest, full.names = TRUE))
stopifnot(!anyDuplicated(paths), !output %in% paths)
m <- data.frame(path = paths, bytes = file.info(paths)$size, sha256 = vapply(paths, sha, character(1)))
write.csv(m, output, row.names = FALSE)
r <- read.csv(output, stringsAsFactors = FALSE)
stopifnot(all(vapply(r$path, sha, character(1)) == r$sha256), all(file.info(r$path)$size == r$bytes))
cat("ORDER017_INHERITED_CLASSIFICATION=PASS members=", nrow(r), "\n", sep = "")
for (p in c(paths[[1]], output)) cat(sha(p), file.info(p)$size, p, "\n")
