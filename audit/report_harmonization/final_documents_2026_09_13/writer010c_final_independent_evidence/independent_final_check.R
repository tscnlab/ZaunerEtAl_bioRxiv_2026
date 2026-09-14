stopifnot(as.character(getRversion()) == "4.6.1")
root <- normalizePath(getwd(), mustWork = TRUE)
out <- "/private/tmp/writer010c-acceptance.3w4Yzr"
newroot <- file.path(root, "audit/manuscript_nature_health/final_pagination_completion_2026_09_14")
prior <- file.path(root, "audit/manuscript_nature_health/final_format_completion_2026_09_14")
coord <- file.path(root, "audit/report_harmonization/final_documents_2026_09_13")
plan <- file.path(root, "audit/report_harmonization/final_integration_reconciliation_2026_09_14")
sha <- function(p) { con <- file(p, "rb"); on.exit(close(con)); as.character(openssl::sha256(con)) }
verify <- function(path, base, count, pin, label) {
  stopifnot(sha(path) == pin)
  m <- read.csv(path, stringsAsFactors = FALSE)
  p <- ifelse(startsWith(m$path, "/"), m$path, file.path(base, m$path))
  stopifnot(nrow(m) == count, !anyDuplicated(m$path), all(file.exists(p)),
    !anyDuplicated(normalizePath(p)), !normalizePath(path) %in% normalizePath(p))
  m$observed_sha256 <- vapply(p, sha, "")
  m$observed_bytes <- file.info(p)$size
  m$exact <- m$observed_sha256 == m$sha256 & m$observed_bytes == m$bytes
  stopifnot(all(m$exact))
  write.csv(m, file.path(out, paste0(label, "_rehash.csv")), row.names = FALSE)
  invisible(m)
}
owner <- verify(file.path(newroot, "completion_manifest.csv"), newroot, 145L,
  "7fce1f1e88980219a1e8199c5440af0ed19070cbf28b3906bcce13d7bd529ad2", "owner145")
verify(file.path(prior, "completion_manifest.csv"), prior, 271L,
  "86ba7e46cdf106090d8ceaee3109d751dddc32f0f80d62da325ce6b7698583e2", "prior271")
verify(file.path(coord, "writer_s9_pagination_completion_order_010c_dispatch_manifest.csv"), root, 36L,
  "4aae03a4e5417706673cdee9ff21a7b6a053ffccdb847ac1797e9ded5172df37", "dispatch36")
stopifnot(sha(file.path(newroot, "completion_handoff.md")) == "2e7a75b1dacd901aeb30cccbc01477269825eae5815055191f48971dcfe26283")

# Independent complete replay, redirecting only the three existing evidence
# writes. The input script and all sealed outputs remain untouched.
dir.create(file.path(out, "replay"), showWarnings = FALSE)
allowed <- file.path(newroot, c("evidence/final_structural_checks.csv", "evidence/final_structural_summary.json", "evidence/final_verification_R_session.txt"))
dest <- function(p) {
  p <- normalizePath(p, mustWork = FALSE)
  stopifnot(length(p) == 1L, p %in% allowed)
  file.path(out, "replay", basename(p))
}
env <- new.env(parent = globalenv())
env$write.csv <- function(x, file, ...) utils::write.csv(x, dest(file), ...)
env$write_json <- function(x, path, ...) jsonlite::write_json(x, dest(path), ...)
env$writeLines <- function(text, con = stdout(), ...) base::writeLines(text, dest(con), ...)
source(file.path(newroot, "code/verify_final.R"), local = env)
checks <- read.csv(file.path(out, "replay/final_structural_checks.csv"))
stopifnot(nrow(checks) == 22L, all(checks$pass),
  identical(checks, read.csv(file.path(newroot, "evidence/final_structural_checks.csv"))))
immutable <- read.csv(file.path(newroot, "evidence/final_immutability_checks.csv"))
stopifnot(nrow(immutable) == 9L, all(immutable$pass))
review <- read.csv(file.path(newroot, "evidence/final_full_page_review.csv"), stringsAsFactors = FALSE)
print(names(review))
stopifnot(nrow(review) == 102L, identical(review$page, 1:102), all(review$visually_reviewed),
  all(vapply(file.path(newroot, review$image), sha, "") == review$image_sha256),
  sha(file.path(newroot, "evidence/final_full_page_review.csv")) == "ff72ffe3a66735d34e67cdebe053af87c4bb0a701d5fbc24938583d094b5e759")
write.csv(review, file.path(out, "review102_reproduced.csv"), row.names = FALSE)
pages <- paste0("page-", 1:82, ".png")
stopifnot(all(vapply(file.path(prior, "qa/main_round2", pages), sha, "") == vapply(file.path(newroot, "qa/main", pages), sha, "")))
rec <- read.csv(file.path(coord, "writer010c_bookmark_guard_recovery_manifest.csv"), stringsAsFactors = FALSE)
stopifnot(nrow(rec) == 33L, !anyDuplicated(rec$path))
rec$observed_sha256 <- vapply(rec$path, sha, "")
rec$observed_bytes <- file.info(rec$path)$size
i <- which(rec$sha256 != rec$observed_sha256 | rec$bytes != rec$observed_bytes)
stopifnot(length(i) == 1L,
  rec$path[i] == "audit/manuscript_nature_health/final_pagination_completion_2026_09_14/code/patch_s9_break.py",
  rec$sha256[i] == "6370bf176b1a10a7dd6fa81e6cd8282158f920d80317d589c4b2215e64affe8c",
  rec$observed_sha256[i] == "df4e9e2d267e2c7b1dfcf178fc8243ce0fcb52e6888870da33fc017faedb4e27",
  rec$observed_bytes[i] == 5585)
write.csv(rec, file.path(out, "recovery33_classified.csv"), row.names = FALSE)
stopmanifest <- file.path(newroot, "evidence/bookmark_guard_stop/preserved_manifest.csv")
stop_m <- read.csv(stopmanifest, stringsAsFactors = FALSE)
print(head(stop_m, 1))
stopifnot(nrow(stop_m) == 9L, !anyDuplicated(stop_m$path))
stop_p <- file.path(newroot, "evidence/bookmark_guard_stop", stop_m$copy)
stopifnot(all(vapply(stop_p, sha, "") == stop_m$sha256), all(file.info(stop_p)$size == stop_m$bytes))
stopifnot(sha(file.path(newroot, "deliverables/Nature_Health_manuscript.docx")) == "325c3a8e3a76ea225970f80e177ceed0bbdd592b72e79196d154597f3581250b",
  all(vapply(file.path(newroot, owner$path), sha, "") == owner$sha256))
writeLines(capture.output(sessionInfo()), file.path(out, "session.txt"))
writeLines("WRITER010C_INDEPENDENT=PASS owner=145/145 prior=271/271 dispatch=36/36 structural=22/22 immutability=9/9 recovery=32exact+1authorized stop=9/9 pages=102 first82=exact no_render=TRUE", file.path(out, "result.txt"))
cat(readLines(file.path(out, "result.txt")), "\n")
