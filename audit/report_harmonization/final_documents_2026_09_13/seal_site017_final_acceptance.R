stopifnot(getRversion() == "4.6.1")
suppressPackageStartupMessages({library(digest); library(jsonlite)})
root <- normalizePath(".", mustWork = TRUE)
d <- "audit/report_harmonization/final_documents_2026_09_13"
owner <- "audit/report_harmonization/final_site_reader_cleanup_2026_09_14"
scratch <- "/private/tmp/site017-central-audit.96EdQYvx"
dest <- file.path(d, "site017_final_independent")
output <- file.path(d, "site017_final_independent_acceptance_manifest.csv")
stopifnot(!dir.exists(dest), !file.exists(output))
sha <- function(p) digest(file = p, algo = "sha256")
owner_summary <- fromJSON(file.path(scratch, "owner_final_independent/owner_evidence_summary.json"))
delivery <- fromJSON(file.path(scratch, "live_independent/independent_summary.json"))
stopifnot(owner_summary$status == "PASS", owner_summary$members == 2318L,
  owner_summary$operations == 62L, owner_summary$protected_paths == 5681L,
  delivery$status == "PASS", delivery$files == 899L, delivery$exact_unchanged == 854L)
stopifnot(sha(file.path(owner, "completion_manifest.csv")) ==
  "7fd82555c49ece7e5d34d2509ad06850935df9ad03fad6128fe8c4f5759e3859",
  sha(file.path(owner, "completion_seal.json")) ==
  "ddbbf063ce776cc146777d7c7e03581f765c69de866d4ce568a39baed5554165")
classification_path <- file.path(d, "order017_inherited_nonreader_classification_manifest.csv")
classification_sha <- "aa7bda0793288cd83c0357dd7ab33e3ebec17c179482e3b48e75c4d28a135f77"
stopifnot(sha(classification_path) == classification_sha)
classification <- read.csv(classification_path, stringsAsFactors = FALSE)
stopifnot(nrow(classification) == 9L, !anyDuplicated(classification$path),
  all(file.info(classification$path)$size == classification$bytes),
  all(vapply(classification$path, sha, character(1)) == classification$sha256))
initial_protected <- read.csv(file.path(owner, "evidence/protected_unique_baseline.csv"))
full_protected <- read.csv(file.path(owner, "evidence/final_protected_checks.csv"))
extra_paths <- c(classification_path, classification$path)
stopifnot(length(extra_paths) == 10L, !anyDuplicated(extra_paths),
  setequal(setdiff(unique(full_protected$path), initial_protected$path), extra_paths),
  length(unique(full_protected$path)) == 5691L,
  setequal(unique(full_protected$path), c(initial_protected$path, extra_paths)))
inputs <- c("check_owner_completion.R", "check_delivered_site.R",
  "candidate_visual_independent.json", "live_visual_independent.json",
  "central_seal_attempt001.R", "central_seal_count_reconciliation.md",
  list.files(file.path(scratch, "live_independent"), full.names = FALSE),
  list.files(file.path(scratch, "owner_final_independent"), full.names = FALSE))
stopifnot(all(file.exists(file.path(scratch, inputs[1:6]))))
dir.create(dest)
for (p in inputs[1:6]) {
  source <- file.path(scratch, p)
  target <- file.path(dest, p)
  stopifnot(file.copy(source, target), sha(source) == sha(target))
}
write.csv(data.frame(path = extra_paths, bytes = file.info(extra_paths)$size,
  sha256 = vapply(extra_paths, sha, character(1)), independently_exact = TRUE),
  file.path(dest, "10_classification_protected_paths.csv"), row.names = FALSE)
for (name in c("live_independent", "owner_final_independent")) {
  dir.create(file.path(dest, name))
  for (source in list.files(file.path(scratch, name), full.names = TRUE)) {
    target <- file.path(dest, name, basename(source))
    stopifnot(!dir.exists(source), file.copy(source, target), sha(source) == sha(target))
  }
}
operations <- read.csv(file.path(owner, "evidence/planned_operations.csv"), stringsAsFactors = FALSE)
downloads <- read.csv(file.path(owner, "evidence/live_download_inventory.csv"), stringsAsFactors = FALSE)
download_paths <- file.path("_build/nathealth", downloads$path)
stopifnot(nrow(downloads) == 20L, length(download_paths) == 20L, all(file.exists(download_paths)))
owner_evidence <- c("completion_manifest.csv", "completion_seal.json", "combined_return.md",
  "evidence/completion_summary.json", "evidence/planned_operations.csv",
  "evidence/live_transaction_journal.jsonl", "evidence/promotion_freeze.json",
  "evidence/helper_manifest.csv", "evidence/final_protected_summary.json",
  "evidence/final_protected_checks.csv", "evidence/candidate_checks.json",
  "evidence/fixture_suite.json", "evidence/live_checks.json",
  "evidence/candidate_browser_acceptance.json", "evidence/live_browser_acceptance.json",
  "evidence/promotion_permission_review_001.md", "evidence/promotion_permission_review_002.md",
  "evidence/promotion_permission_blocked.json", "evidence/promotion_direct_user_authorization.md",
  "evidence/promotion_permission_resolution.json",
  unlist(lapply(c("candidate", "live"), function(mode) file.path("evidence", paste0(mode, "_qa"),
    c("browser_capture_manifest.csv", "server_lifecycle.json", "teardown.json", "http_summary.json")))))
paths <- unique(c(file.path(d, c("site017_final_independent_acceptance.md",
  "seal_site017_final_acceptance.R", "site_reader_scope_cleanup_order_017.md",
  "site_reader_scope_cleanup_order_017_dispatch_manifest.csv",
  "order017_inherited_nonreader_classification.md", "order017_inherited_nonreader_classification_manifest.csv",
  "order017_direct_user_authorization_provenance.md")),
  list.files(dest, recursive = TRUE, full.names = TRUE), file.path(owner, owner_evidence),
  operations$target[operations$action == "replace"],
  file.path(owner, operations$backup),
  file.path(owner, "live_retired", operations$target[operations$action == "retire"]),
  download_paths, "notebooks/sensitivity_battery.qmd", "_quarto.yml", "renv.lock"))
stopifnot(!anyDuplicated(paths), !output %in% paths, all(file.exists(paths)),
  !any(file.info(paths)$isdir), !any(nzchar(Sys.readlink(paths))))
manifest <- data.frame(path = paths, bytes = file.info(paths)$size,
  sha256 = vapply(paths, sha, character(1)), stringsAsFactors = FALSE)
write.csv(manifest, output, row.names = FALSE)
check <- read.csv(output, stringsAsFactors = FALSE)
stopifnot(nrow(check) == nrow(manifest), !anyDuplicated(check$path),
  all(file.info(check$path)$size == check$bytes),
  all(vapply(check$path, sha, character(1)) == check$sha256))
cat("ORDER017_CENTRAL_FINAL_ACCEPTANCE=PASS members=", nrow(check), "\n", sep = "")
for (p in c(file.path(d, "site017_final_independent_acceptance.md"), output))
  cat(sha(p), file.info(p)$size, p, "\n")
