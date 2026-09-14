stopifnot(getRversion() == "4.6.1")
suppressPackageStartupMessages({library(digest); library(jsonlite)})
d <- "audit/report_harmonization/final_documents_2026_09_13"
src <- "/private/tmp/reader-scope-audit-20260914.nnDbyu"
scratch <- "/private/tmp/site017-central-audit.96EdQYvx"
dest <- file.path(d, "reader_scope_017_independent")
owner <- file.path(dest, "owner_readonly")
output <- file.path(d, "site_reader_scope_cleanup_order_017_dispatch_manifest.csv")
stopifnot(!dir.exists(dest), !file.exists(output))
sha <- function(p) digest(file = p, algo = "sha256")
exact <- function(p, h, n = NULL) {
  stopifnot(file.exists(p), !dir.exists(p), !nzchar(Sys.readlink(p)), sha(p) == h)
  if (!is.null(n)) stopifnot(file.info(p)$size == n)
}
exact(file.path(src, "audit_manifest.csv"), "82076b28a892beeecf7aff98f3e15d81fd34a9c15760435dc3ae77616b94a60e")
exact(file.path(src, "impact_report.md"), "0746245fe0afbe8c7d1beab093ed300a0ab2c5e55b50e50be6b349bc8c904a85")
exact(file.path(src, "proposed_public_replacement_matrix.csv"), "ad0b4a2dcf955e7b923a7e7dbd06bc99167f776ff4375c9be4157e1ef60d6a55")
m <- read.csv(file.path(src, "audit_manifest.csv"), stringsAsFactors = FALSE)
stopifnot(nrow(m) == 100L, !anyDuplicated(m$path), !"audit_manifest.csv" %in% m$path,
  !any(grepl("^/|(^|/)\\.\\.(/|$)", m$path)))
for (i in seq_len(nrow(m))) exact(file.path(src, m$path[[i]]), m$sha256[[i]], m$bytes[[i]])
paths <- list.files(src, recursive = TRUE, all.files = TRUE, no.. = TRUE, full.names = TRUE, include.dirs = TRUE)
stopifnot(!any(nzchar(Sys.readlink(paths))))
paths <- paths[!file.info(paths)$isdir]
stopifnot(setequal(paths, file.path(src, c(m$path, "audit_manifest.csv"))))
live <- read.csv(file.path(src, "live_inventory_before.csv"), stringsAsFactors = FALSE)
stopifnot(nrow(live) == 914L, !anyDuplicated(live$path))
for (i in seq_len(nrow(live))) exact(file.path("_build/nathealth", live$path[[i]]), live$sha256[[i]], live$bytes[[i]])
pre <- read.csv(file.path(src, "preimage_manifest.csv"), stringsAsFactors = FALSE)
stopifnot(nrow(pre) == 64L, !anyDuplicated(pre$path))
for (i in seq_len(nrow(pre))) {
  exact(pre$path[[i]], pre$sha256[[i]], pre$bytes[[i]])
  exact(file.path(src, pre$temporary_preimage[[i]]), pre$sha256[[i]], pre$bytes[[i]])
}
summary <- fromJSON(file.path(scratch, "independent_boundary_summary.json"))
stopifnot(summary$status == "PASS", summary$live == 914L,
  summary$replacements == 45L, summary$retirements == 15L,
  summary$scientific_content_baselines == 36L)
dir.create(owner, recursive = TRUE)
copy_exact <- function(p, q) {
  stopifnot(!file.exists(q))
  dir.create(dirname(q), recursive = TRUE, showWarnings = FALSE)
  stopifnot(file.copy(p, q), sha(p) == sha(q))
}
for (p in paths) copy_exact(p, file.path(owner, substring(p, nchar(src) + 2L)))
ind <- list.files(scratch, recursive = TRUE, full.names = TRUE)
ind <- ind[!file.info(ind)$isdir]
for (p in ind) copy_exact(p, file.path(dest, "central_readonly", substring(p, nchar(scratch) + 2L)))
capture.output(sessionInfo(), file = file.path(dest, "dispatch_R_sessionInfo.txt"))
write_json(list(status = "ACCEPTED_FOR_ORDER017_DISPATCH", owner_members = 100L,
  archived_preimages = 64L, live = 914L, public_replacements = 45L, retirements = 15L,
  prospective_live = 899L, prospective_reader_routes = 36L, prospective_search_records = 938L,
  prospective_sitemap_urls = 38L, render_allowance = 0L, live_transactions = 1L),
  file.path(dest, "dispatch_review_summary.json"), pretty = TRUE, auto_unbox = TRUE)
archived <- list.files(dest, recursive = TRUE, full.names = TRUE)
archived <- archived[!file.info(archived)$isdir]
selected <- sort(unique(c(archived, file.path(d, c("reader_scope_author_direction_017.md",
  "site017_readonly_independent_acceptance.md", "site_reader_scope_cleanup_order_017.md",
  "seal_site017_dispatch.R", "site016_final_independent_acceptance.md",
  "site016_final_independent_acceptance_manifest.csv")), pre$path,
  "_quarto.yml", "notebooks/sensitivity_battery.qmd", "renv.lock")))
stopifnot(!output %in% selected, !anyDuplicated(normalizePath(selected)),
  all(file.exists(selected)), !any(nzchar(Sys.readlink(selected))))
seal <- data.frame(path = selected, bytes = file.info(selected)$size,
  sha256 = vapply(selected, sha, character(1)), stringsAsFactors = FALSE)
write.csv(seal, output, row.names = FALSE)
check <- read.csv(output, stringsAsFactors = FALSE)
stopifnot(nrow(check) == nrow(seal), !anyDuplicated(check$path))
for (i in seq_len(nrow(check))) exact(check$path[[i]], check$sha256[[i]], check$bytes[[i]])
cat(sprintf("ORDER017_DISPATCH_SEAL=PASS members=%d owner100 live914 preimages64\n", nrow(check)))
for (p in c(file.path(d, "site017_readonly_independent_acceptance.md"),
  file.path(d, "site_reader_scope_cleanup_order_017.md"), output)) cat(sha(p), file.info(p)$size, p, "\n")
