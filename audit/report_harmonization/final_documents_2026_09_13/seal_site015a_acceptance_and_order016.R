stopifnot(getRversion() == "4.6.1")
suppressPackageStartupMessages({library(digest); library(jsonlite)})
d <- "audit/report_harmonization/final_documents_2026_09_13"
t <- "audit/report_harmonization/final_site_a4_delta_2026_09_14"
a <- file.path(t, "verification_recovery_015a")
e <- file.path(a, "evidence")
scratch <- "/private/tmp/site015-browser-classification.BNO0zp"
dest <- file.path(d, "site015a_final_independent")
accept <- file.path(d, "site015a_candidate_independent_acceptance.md")
accept_seal <- file.path(d, "site015a_candidate_independent_acceptance_manifest.csv")
order <- file.path(d, "site_a4_delta_promotion_order_016.md")
dispatch <- file.path(d, "site_a4_delta_promotion_order_016_dispatch_manifest.csv")
self <- file.path(d, "seal_site015a_acceptance_and_order016.R")
corpus <- "audit/report_harmonization/phase4_corpus_manifest.csv"
stopifnot(!dir.exists(dest), !file.exists(accept_seal), !file.exists(dispatch),
          !dir.exists("audit/report_harmonization/final_site_a4_promotion_2026_09_14"))
sha <- function(p) digest(file = p, algo = "sha256")
exact <- function(p, hash, size = NULL) {
  stopifnot(file.exists(p), !dir.exists(p), !nzchar(Sys.readlink(p)), sha(p) == hash)
  if (!is.null(size)) stopifnot(file.info(p)$size == size)
  invisible(TRUE)
}
verify_manifest <- function(path, base, n, hash) {
  exact(path, hash)
  x <- read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)
  stopifnot(nrow(x) == n, !anyDuplicated(x$path))
  full <- ifelse(startsWith(x$path, "/"), x$path, file.path(base, x$path))
  stopifnot(!normalizePath(path) %in% normalizePath(full))
  for (i in seq_len(nrow(x))) exact(full[[i]], x$sha256[[i]], x$bytes[[i]])
  x
}
owner <- verify_manifest(file.path(a, "pending_manifest.csv"), a, 269L,
 "15a93b1551ccd4ca40acc3b9460fb76ef0cd4114c9249271d273a8f7bbf56ca4")
history <- verify_manifest(file.path(t, "failure_manifest.csv"), t, 959L,
 "02a4f39eae1a29971598f3f84f03b6c854a5f6dc53774bd282e6f4e56f54161d")
exact(file.path(a, "pending_seal.json"), "abe0e7caf5543b1d6fca1c6973605c34ceeb62acfdba0cf5d691d8c0f6d23af3")
exact(file.path(t, "failure_seal.json"), "ff359836235d441f79e7add87471b6f092211154a7b95ab1642d53a4f8054c3f")
exact(file.path(a, "candidate_return.md"), "d0853b4349a1d762a97affd1c8a47bf65036ea2ccdd24ab51a5235a73dc6625c", 9527)
r <- fromJSON(file.path(scratch, "independent_R/summary.json"))
b <- fromJSON(file.path(scratch, "postflight.json"))
stopifnot(r$status == "PASS", r$owner == 269, r$historical == 959, r$protected == 4617,
 r$content == 75, identical(as.integer(r$targeted), c(15L, 15L)),
 b$status == "PASS", b$live_exact == 914, b$candidate_exact == 914, b$protected_exact == 9,
 b$no_listener, all(b$listeners$connect_ex == 61))
for (f in c("lifecycle.json", "candidate_lifecycle.json")) {
  life <- fromJSON(file.path(scratch, f))
  stopifnot(life$status == "stopped", life$address == "127.0.0.1", life$read_only_get_head)
}
browser <- fromJSON(file.path(scratch, "final_browser_teardown.json"))
stopifnot(length(browser$tabs) == 0L, browser$viewportReset)
protected <- read.csv(file.path(e, "post_protected_checks.csv"), stringsAsFactors = FALSE)
stopifnot(nrow(protected) == 4617L)
for (i in seq_len(nrow(protected))) exact(protected$path[[i]], protected$expected_sha256[[i]], protected$bytes[[i]])

inventory <- function(path, base, expected_n) {
  x <- read.csv(path, stringsAsFactors = FALSE)
  stopifnot(nrow(x) == expected_n, !anyDuplicated(x$path))
  all_paths <- list.files(base, recursive = TRUE, full.names = TRUE, all.files = TRUE, no.. = TRUE, include.dirs = TRUE)
  stopifnot(!any(nzchar(Sys.readlink(c(base, all_paths)))))
  actual <- all_paths[!file.info(all_paths)$isdir]
  stopifnot(setequal(actual, file.path(base, x$path)))
  for (i in seq_len(nrow(x))) exact(file.path(base, x$path[[i]]), x$sha256[[i]], x$bytes[[i]])
  x
}
live <- inventory(file.path(e, "post_live_inventory.csv"), "_build/nathealth", 914L)
candidate <- inventory(file.path(e, "candidate_inventory.csv"), file.path(t, "candidate_build"), 914L)
exact(file.path(e, "candidate_inventory.csv"), "371e5fcb17cf4d7e3cd98f672bd6c27e6811a530c3e1f9d4b662164f7316f979")
exact(file.path(e, "website_promotion_manifest.csv"), "c64b71fd844b1ccdfdbaa9a33d240d7a11bbf89b23603d9b04dac417bcaf50fc")
exact(file.path(e, "seven_backup_manifest.csv"), "1f21d5315d19f97890d3cf259734634ae0dee406748e20b1b14a7dc6fca7310d")
m <- read.csv(file.path(e, "website_promotion_manifest.csv"), stringsAsFactors = FALSE)
back <- read.csv(file.path(e, "seven_backup_manifest.csv"), stringsAsFactors = FALSE)
stopifnot(nrow(m) == 6L, all(m$action == "replace"), !anyDuplicated(m$target),
 nrow(back) == 7L, !anyDuplicated(back$live_target), setequal(back$live_target, c(m$target, corpus)))
for (i in seq_len(nrow(m))) {
  exact(m$target[[i]], m$preimage_sha256[[i]])
  exact(m$candidate[[i]], m$candidate_sha256[[i]], m$bytes[[i]])
}
for (i in seq_len(nrow(back))) {
  exact(back$live_target[[i]], back$sha256[[i]], back$bytes[[i]])
  exact(back$backup[[i]], back$sha256[[i]], back$bytes[[i]])
}
matched <- match(live$path, candidate$path)
stopifnot(!anyNA(matched), setequal(live$path, candidate$path))
changed <- live$path[live$sha256 != candidate$sha256[matched] | live$bytes != candidate$bytes[matched]]
stopifnot(length(changed) == 6L, setequal(paste0("_build/nathealth/", changed), m$target))
prospective <- file.path(e, "phase4_corpus_manifest.prospective.csv")
exact(corpus, "b5b4b009db76e6f869f324a360e6eeafdf63438539382f1b8d85058f277eb93f")
exact(prospective, "642161dfc1ec18572b8b8c124546060c8f889683ebf7ceb8e5e43dc785f77669")
old <- read.csv(corpus, stringsAsFactors = FALSE, check.names = FALSE)
new <- read.csv(prospective, stringsAsFactors = FALSE, check.names = FALSE)
stopifnot(nrow(old) == 37L, identical(names(old), names(new)),
 identical(old[setdiff(names(old), "html_sha256")], new[setdiff(names(new), "html_sha256")]))
delta <- which(old$html_sha256 != new$html_sha256)
stopifnot(identical(delta, 1:2), identical(old$expected_html[delta], m$target[1:2]),
 identical(new$html_sha256[delta], m$candidate_sha256[1:2]))

dir.create(dest)
files <- list.files(scratch, recursive = TRUE, full.names = TRUE, all.files = TRUE, no.. = TRUE)
files <- files[!file.info(files)$isdir]
stopifnot(!any(nzchar(Sys.readlink(files))))
for (p in files) {
  rel <- substring(p, nchar(scratch) + 2L)
  target <- file.path(dest, rel)
  dir.create(dirname(target), recursive = TRUE, showWarnings = FALSE)
  stopifnot(!file.exists(target), file.copy(p, target), sha(p) == sha(target))
}
write.csv(data.frame(path = protected$path, bytes = protected$bytes,
                    sha256 = protected$expected_sha256, exact = TRUE),
 file.path(dest, "seal_time_protected4617.csv"), row.names = FALSE)
write.csv(data.frame(target = m$target, pre_sha256 = m$preimage_sha256,
                    post_sha256 = m$candidate_sha256, bytes = m$bytes),
 file.path(dest, "seal_time_six_targets.csv"), row.names = FALSE)
capture.output(sessionInfo(), file = file.path(dest, "sealing_R_sessionInfo.txt"))
seal <- function(paths, output) {
  paths <- sort(unique(paths))
  stopifnot(!output %in% paths, all(file.exists(paths)), !any(dir.exists(paths)),
            !any(nzchar(Sys.readlink(paths))), !anyDuplicated(normalizePath(paths)))
  x <- data.frame(path = paths, bytes = file.info(paths)$size, sha256 = vapply(paths, sha, character(1)))
  write.csv(x, output, row.names = FALSE)
  check <- read.csv(output, stringsAsFactors = FALSE)
  stopifnot(nrow(check) == nrow(x), !anyDuplicated(check$path),
   all(vapply(check$path, sha, character(1)) == check$sha256), all(file.info(check$path)$size == check$bytes))
  nrow(check)
}
durable <- list.files(dest, recursive = TRUE, full.names = TRUE)
durable <- durable[!file.info(durable)$isdir]
accept_n <- seal(c(accept, self, durable, file.path(a, c("candidate_return.md", "pending_manifest.csv", "pending_seal.json")),
 file.path(t, c("failure_manifest.csv", "failure_seal.json")),
 file.path(e, c("website_promotion_manifest.csv", "candidate_inventory.csv", "seven_backup_manifest.csv",
 "phase4_corpus_manifest.prospective.csv", "prospective_corpus_reverse.csv", "candidate_static_summary.json",
 "http_download_summary.json", "browser_observations.json", "browser_capture_manifest.csv", "post_closure_summary.json")),
 file.path(d, c("writer012_014_final_independent_acceptance.md", "writer012_014_final_independent_acceptance_manifest.csv"))), accept_seal)
dispatch_n <- seal(c(order, accept, accept_seal, self,
 file.path(a, c("candidate_return.md", "pending_manifest.csv", "pending_seal.json")),
 file.path(t, c("failure_manifest.csv", "failure_seal.json")),
 file.path(e, c("website_promotion_manifest.csv", "candidate_inventory.csv", "post_live_inventory.csv",
 "seven_backup_manifest.csv", "phase4_corpus_manifest.prospective.csv", "prospective_corpus_reverse.csv",
 "post_protected_checks.csv", "candidate_static_summary.json", "http_download_summary.json")),
 file.path(d, c("site_delta_candidate_order_015_target_matrix.csv", "site_verifier_recovery_order_015a.md",
 "writer012_014_final_independent_acceptance.md", "writer012_014_final_independent_acceptance_manifest.csv",
 "site013_independent_completion_acceptance.md", "final_site_promotion_order_013.md")),
 list.files(file.path(a, "helpers"), full.names = TRUE),
 "audit/report_harmonization/final_site_promotion_2026_09_14/helpers/transaction.py",
 m$candidate, back$live_target, back$backup, file.path(dest, c("postflight.json", "independent_R/summary.json"))), dispatch)
cat(sprintf("SITE015A_ACCEPTANCE_ORDER016=SEALED acceptance=%d dispatch=%d owner=269 history=959 protected=4617 candidate=914 live=914 targets=6 corpus_cells=2\n", accept_n, dispatch_n))
for (p in c(accept, accept_seal, order, dispatch)) cat(sha(p), file.info(p)$size, p, "\n")
