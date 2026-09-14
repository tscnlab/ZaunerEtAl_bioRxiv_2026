stopifnot(as.character(getRversion()) == "4.6.1")
coord <- "audit/report_harmonization/final_documents_2026_09_13"
owner <- "audit/manuscript_nature_health/a4_display_revision_2026_09_14"
site <- "audit/report_harmonization/final_site_integration_2026_09_14"
promotion <- "audit/report_harmonization/final_site_promotion_2026_09_14"
scratch <- "/private/tmp/writer012-independent.cieJLM"
evidence <- file.path(coord, "writer012_independent_evidence")
review <- file.path(coord, "writer012_nonbrowser_independent_review.md")
review_seal <- file.path(coord, "writer012_nonbrowser_independent_review_manifest.csv")
order <- file.path(coord, "writer012_html_visual_release_order_014.md")
dispatch <- file.path(coord, "writer012_html_visual_release_order_014_manifest.csv")
self <- file.path(coord, "seal_writer012_review_and_html014.R")
sha <- function(p) {
  con <- file(p, "rb")
  on.exit(close(con))
  as.character(openssl::sha256(con))
}
audit <- function(manifest, base, count) {
  x <- read.csv(manifest, stringsAsFactors = FALSE)
  stopifnot(nrow(x) == count, !anyDuplicated(x$path),
    !any(grepl("^/|(^|/)\\.\\.(/|$)", x$path)))
  paths <- if (base == "") x$path else file.path(base, x$path)
  stopifnot(all(file.exists(paths)), !any(nzchar(Sys.readlink(paths))),
    !normalizePath(manifest) %in% normalizePath(paths),
    all(file.info(paths)$size == x$bytes), all(vapply(paths, sha, "") == x$sha256))
  x
}
rows <- function(paths) {
  paths <- sort(unique(paths))
  stopifnot(all(file.exists(paths)), !any(file.info(paths)$isdir),
    !any(nzchar(Sys.readlink(paths))), !anyDuplicated(normalizePath(paths)))
  data.frame(path = paths, bytes = file.info(paths)$size,
    sha256 = vapply(paths, sha, ""), stringsAsFactors = FALSE)
}
stopifnot(!dir.exists(evidence), !file.exists(review_seal), !file.exists(dispatch))
stopifnot(sha(file.path(owner, "word_candidate_manifest.csv")) ==
  "996e138233eff74da4754aae6c2fbc1a6b5785c9d196fa2c64df2fe8eeccb464")
invisible(audit(file.path(owner, "word_candidate_manifest.csv"), owner, 318L))
safe_path <- file.path(promotion, "evidence/production_safe_point.json")
stopifnot(sha(safe_path) == "2cd05bd9e9bd8162ac34e0d10fa7ea64a0ef7675e512626a3634868d865aced8")
safe <- jsonlite::read_json(safe_path, simplifyVector = TRUE)
stopifnot(safe$safe_point, safe$port_closed, safe$own_tabs_closed, safe$viewport_reset,
  safe$live914_matches_accepted, safe$complete_fixed_source_and_candidate_closure_exact,
  safe$port == 55182L, safe$operations_exact_once == 26L, safe$corpus_last)
stopifnot(sha(file.path(promotion, "completion_manifest.csv")) ==
  "01e01dadccead1ade67c19df561be524e08b6c3ef008098f7ebd4aac767a06c3")
invisible(audit(file.path(promotion, "completion_manifest.csv"), promotion, 89L))
inventory <- file.path(site, "evidence/candidate_inventory.csv")
live <- audit(inventory, "_build/nathealth", 914L)
invisible(audit(inventory, file.path(site, "candidate_build"), 914L))
all_live <- list.files("_build/nathealth", recursive = TRUE, all.files = TRUE,
  include.dirs = TRUE, no.. = TRUE, full.names = TRUE)
stopifnot(!any(nzchar(Sys.readlink(c("_build/nathealth", all_live)))),
  setequal(list.files("_build/nathealth", recursive = TRUE, all.files = TRUE, no.. = TRUE), live$path))
closure <- read.csv(file.path(promotion, "evidence/post_fixed_closure_checks.csv"), stringsAsFactors = FALSE)
directory_row <- file.info(closure$path)$isdir
stopifnot(nrow(closure) == 3869L, all(file.exists(closure$path)),
  sum(directory_row) == 1L,
  identical(closure$path[directory_row], "_build/nathealth"),
  identical(closure$category[directory_row], "complete_live_inventory"),
  identical(closure$expected_sha256[directory_row], ""),
  identical(closure$actual_sha256[directory_row], ""),
  all(vapply(closure$path[!directory_row], sha, "") == closure$expected_sha256[!directory_row]))
probe <- suppressWarnings(system2("/usr/sbin/lsof", c("-nP", "-iTCP:55182", "-sTCP:LISTEN"),
  stdout = TRUE, stderr = TRUE))
stopifnot(length(probe) == 0L, identical(attr(probe, "status"), 1L))
stopifnot(sha("audit/report_harmonization/phase4_corpus_manifest.csv") ==
  "b5b4b009db76e6f869f324a360e6eeafdf63438539382f1b8d85058f277eb93f")
wc <- read.csv(file.path(scratch, "word_R/word_pre_render_checks.csv"))
hc <- read.csv(file.path(scratch, "html_R/structural_content_checks.csv"))
sc <- read.csv(file.path(scratch, "structural_checks.csv"))
stopifnot(nrow(wc) == 42L, all(wc$pass), nrow(hc) == 15L, all(hc$pass),
  nrow(sc) == 189L, all(tolower(as.character(sc$passed)) == "true"))
pr <- read.csv(file.path(scratch, "page101_identity.csv"))
stopifnot(nrow(pr) == 101L, all(tolower(as.character(pr$a4)) == "true"),
  all(tolower(as.character(pr$pixel_file_exact)) == "true"))
for (p in c(review, order)) stopifnot(!any(grepl("\u2014", readLines(p), fixed = TRUE)))
dir.create(evidence)
for (f in list.files(scratch, recursive = TRUE, full.names = FALSE, all.files = TRUE, no.. = TRUE)) {
  from <- file.path(scratch, f)
  to <- file.path(evidence, f)
  dir.create(dirname(to), recursive = TRUE, showWarnings = FALSE)
  stopifnot(file.copy(from, to, overwrite = FALSE), sha(from) == sha(to))
}
write.csv(closure, file.path(evidence, "site013_safe_fixed3869_recheck.csv"), row.names = FALSE)
write.csv(live, file.path(evidence, "site013_safe_live914_recheck.csv"), row.names = FALSE)
writeLines(c(format(Sys.time(), tz = "UTC", usetz = TRUE),
  "/usr/sbin/lsof -nP -iTCP:55182 -sTCP:LISTEN: exit1 and empty output",
  "Owner89, fixed3869, live914 and candidate914 independently exact; no symlink or listener",
  "Writer318 unchanged; browser slot released only upon Order014 dispatch"),
  file.path(evidence, "site013_independent_browser_safe_point.txt"))
capture.output(sessionInfo(), file = file.path(evidence, "seal_R_sessionInfo.txt"))
owner_paths <- file.path(owner, c("word_candidate_manifest.csv", "word_candidate_handoff.md",
  "deliverables/Nature_Health_manuscript.docx", "deliverables/Nature_Health_editable_tables.zip",
  "html_candidate_round2/ZaunerEtAl2026_NatHealth_phase3_brown.html",
  "html_candidate_round2/delta_manifest.json", "helpers/verify_word.R", "helpers/verify_html.R",
  "helpers/final_preservation.R", "evidence/final_word/review_basis.json",
  "evidence/final_word/all_101_page_review.csv"))
site_paths <- file.path(promotion, c("completion_manifest.csv", "completion_seal.json",
  "evidence/production_safe_point.json", "evidence/post_closure_summary.json",
  "evidence/server_lifecycle.json", "evidence/no_listener_check.txt"))
a <- rows(c(review, self, owner_paths, site_paths,
  list.files(evidence, recursive = TRUE, full.names = TRUE)))
write.csv(a, review_seal, row.names = FALSE)
invisible(audit(review_seal, "", nrow(a)))
native <- list.files(file.path(owner, "deliverables/editable_tables"),
  pattern = "^Table_.*\\.docx$", full.names = TRUE)
stopifnot(length(native) == 19L)
d <- rows(c(order, review, review_seal, self, owner_paths, native, site_paths,
  file.path(coord, "writer_a4_display_candidate_order_012.md"),
  file.path(coord, "writer_a4_display_candidate_order_012_dispatch_manifest.csv"),
  file.path(coord, "writer012_external_order013_corpus_classification.md"),
  file.path(coord, "writer012_external_order013_corpus_classification_manifest.csv")))
write.csv(d, dispatch, row.names = FALSE)
invisible(audit(dispatch, "", nrow(d)))
cat(sprintf("WRITER012_NONBROWSER_AND_HTML014=PASS owner318 review%d dispatch%d Word42 HTML15 structure189 site89 live914 fixed3869 port55182closed R=4.6.1\n",
  nrow(a), nrow(d)))
for (p in c(review, review_seal, order, dispatch)) cat(sha(p), file.info(p)$size, p, "\n")
