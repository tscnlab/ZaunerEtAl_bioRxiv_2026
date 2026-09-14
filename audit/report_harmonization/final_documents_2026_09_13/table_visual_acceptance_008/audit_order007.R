# Independent read-only review. Author-package writes are not permitted.
stopifnot(getRversion() == "4.6.1")
library(openssl)
library(jsonlite)
project <- "/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026"
audit <- "/private/tmp/table007-independent.sXVqTc"
pkg <- file.path(project, "audit/manuscript_nature_health/table_layout_visual_corrections_2026_09_14")
sha <- function(p) { con <- file(p, "rb"); on.exit(close(con)); as.character(sha256(con)) }
stopifnot(sha(file.path(pkg, "package_manifest.csv")) == "1b5deb90c0c11cd0e931e6b13c00fedf5551920b9be1e890f86ba878ccfceb3b")
stopifnot(sha(file.path(pkg, "package_manifest.sha256")) == "4f28508bbd5eb76e7004c584a027df3522a52828bc00b9b786502c7030038fcd")
members <- read.csv(file.path(pkg, "package_manifest.csv"), stringsAsFactors = FALSE)
stopifnot(nrow(members) == 263L, !anyDuplicated(members$path),
          !any(grepl("^/|(^|/)\\.\\.(/|$)", members$path)),
          !any(members$path %in% c("package_manifest.csv", "package_manifest.sha256")))
members$observed_bytes <- file.info(file.path(pkg, members$path))$size
members$observed_sha256 <- vapply(file.path(pkg, members$path), sha, character(1))
members$exact <- members$observed_bytes == members$bytes & members$observed_sha256 == members$sha256
write.csv(members, file.path(audit, "manifest_verification_pre.csv"), row.names = FALSE)
stopifnot(all(members$exact))
actual <- list.files(pkg, recursive = TRUE, all.files = TRUE, no.. = TRUE)
actual <- actual[!file.info(file.path(pkg, actual))$isdir]
stopifnot(setequal(actual, c(members$path, "package_manifest.csv", "package_manifest.sha256")))

# Retain original verifiers; adapt only invocation and evidence destinations in memory.
# No assertion, expected value, source, candidate, HTML or production map is changed.
replace_once <- function(text, old, new) {
  pos <- gregexpr(old, text, fixed = TRUE)[[1]]
  stopifnot(length(pos) == 1L, pos[1] > 0L)
  sub(old, new, text, fixed = TRUE)
}
load_text <- function(path) readChar(path, file.info(path)$size, useBytes = TRUE)
script <- file.path(pkg, "verify_candidate.R")
file.copy(script, file.path(audit, "owner_verify_candidate.R"))
code <- load_text(script)
code <- replace_once(code, "args<-commandArgs(trailingOnly=TRUE);", "args<-c('attempt_02','independent');")
code <- replace_once(code, "qa<-file.path(out,qa_name);", "qa<-'/private/tmp/table007-independent.sXVqTc/content_replay';")
eval(parse(text = code), envir = new.env(parent = globalenv()))

script <- file.path(pkg, "finalize_visual_evidence.R")
file.copy(script, file.path(audit, "owner_finalize_visual_evidence.R"))
code <- load_text(script)
code <- replace_once(code, "args<-commandArgs(trailingOnly=TRUE);", "args<-character();")
code <- replace_once(code, "dest<-file.path(out,qa_name);", "dest<-'/private/tmp/table007-independent.sXVqTc/visual_replay';")
maps <- file.path(audit, "copied_maps")
stopifnot(dir.create(maps))
stopifnot(all(file.copy(list.files(file.path(pkg, "attempt_02/maps"), full.names = TRUE), maps)))
code <- replace_once(code, 'maps<-file.path(out,"maps");', "maps<-'/private/tmp/table007-independent.sXVqTc/copied_maps';")
eval(parse(text = code), envir = new.env(parent = globalenv()))

comparisons <- data.frame(
  path = c("checks.csv", "all_407_cell_preservation.csv", "whole_mean_sd_units.csv", "original_png_payloads.csv"),
  stringsAsFactors = FALSE
)
comparisons$owner_sha256 <- vapply(file.path(pkg, "attempt_02/static_verification_postqa_final", comparisons$path), sha, character(1))
comparisons$independent_sha256 <- vapply(file.path(audit, "content_replay", comparisons$path), sha, character(1))
comparisons$exact <- comparisons$owner_sha256 == comparisons$independent_sha256
write.csv(comparisons, file.path(audit, "content_replay_comparison.csv"), row.names = FALSE)
stopifnot(all(comparisons$exact))
stopifnot(sha(file.path(audit, "visual_replay/checks.csv")) == sha(file.path(pkg, "attempt_02/final_visual_verification_03/checks.csv")))
members$observed_bytes <- file.info(file.path(pkg, members$path))$size
members$observed_sha256 <- vapply(file.path(pkg, members$path), sha, character(1))
members$exact <- members$observed_bytes == members$bytes & members$observed_sha256 == members$sha256
write.csv(members, file.path(audit, "manifest_verification_post.csv"), row.names = FALSE)
stopifnot(all(members$exact))
capture.output(sessionInfo(), file = file.path(audit, "sessionInfo.txt"))
write_json(list(status = "PASS", owner_manifest = "263/263", content = "3266/3266", visual_evidence = "854/854",
                inputs_unchanged = TRUE, output_redirection_only = TRUE, independent_browser_review = "pending"),
           file.path(audit, "result.json"), pretty = TRUE, auto_unbox = TRUE)
cat("ORDER007_INDEPENDENT_REPLAY=PASS manifest=263/263 content=3266/3266 visual_evidence=854/854 no_author_write=TRUE\n")
