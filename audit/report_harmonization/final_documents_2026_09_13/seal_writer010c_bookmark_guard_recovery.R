stopifnot(as.character(getRversion()) == "4.6.1")
root <- normalizePath(getwd(), mustWork = TRUE)
coord <- "audit/report_harmonization/final_documents_2026_09_13"
owner <- "audit/manuscript_nature_health/final_pagination_completion_2026_09_14"
prior <- "audit/manuscript_nature_health/final_format_completion_2026_09_14"
tmp <- "/private/tmp/writer010c-bookmark.IjDfbw"
out <- file.path(coord, "writer010c_bookmark_guard_recovery")
order <- file.path(coord, "writer010c_bookmark_guard_recovery.md")
manifest <- file.path(coord, "writer010c_bookmark_guard_recovery_manifest.csv")
sha <- function(p) {con <- file(p, "rb"); on.exit(close(con)); as.character(openssl::sha256(con))}
verify <- function(path, base, n, pin) {
  stopifnot(sha(path) == pin)
  m <- read.csv(path, stringsAsFactors = FALSE)
  p <- ifelse(startsWith(m$path, "/"), m$path, file.path(base, m$path))
  stopifnot(nrow(m) == n, !anyDuplicated(m$path), all(file.exists(p)),
    !anyDuplicated(normalizePath(p)), !normalizePath(path) %in% normalizePath(p),
    all(file.info(p)$size == m$bytes), all(vapply(p, sha, "") == m$sha256))
}
stopifnot(!dir.exists(out), !file.exists(manifest))
verify(file.path(coord, "writer_s9_pagination_completion_order_010c_dispatch_manifest.csv"), root, 36L,
  "4aae03a4e5417706673cdee9ff21a7b6a053ffccdb847ac1797e9ded5172df37")
verify(file.path(prior, "completion_manifest.csv"), prior, 271L,
  "86ba7e46cdf106090d8ceaee3109d751dddc32f0f80d62da325ce6b7698583e2")
files <- list.files(owner, recursive = TRUE, full.names = FALSE)
expected <- c("code/patch_s9_break.py", "code/render_final.py", "code/verify_final.R", "evidence/dispatch36_preflight.csv",
  "evidence/preflight_R_session.txt", "evidence/preflight.json", "evidence/prior271_preflight.csv", "evidence/initial_patch_preflight_stop.json",
  "evidence/in_memory_postimage_R.json")
stopifnot(setequal(files, expected),
  sha(file.path(owner, "code/patch_s9_break.py")) == "6370bf176b1a10a7dd6fa81e6cd8282158f920d80317d589c4b2215e64affe8c")
check <- jsonlite::fromJSON(file.path(tmp, "prewrite_check.json"))
stopifnot(check$status == "PASS", check$output_DOCX_absent, check$patch_proof_absent, check$renderer_unconsumed,
  check$document_xml_after == "98e2924ccc67952165ada5b01d1904b40eacea517908480b47faf0a0e58ffb7f",
  sha(file.path(tmp, "prospective_patch_s9_break.py")) == "df4e9e2d267e2c7b1dfcf178fc8243ce0fcb52e6888870da33fc017faedb4e27")
dir.create(out)
scratch <- list.files(tmp, full.names = TRUE)
stopifnot(all(file.copy(scratch, file.path(out, basename(scratch)), overwrite = FALSE)))
dir.create(file.path(out, "stopped_owner_preimage"))
for (f in files) {
  p <- file.path(out, "stopped_owner_preimage", f)
  dir.create(dirname(p), recursive = TRUE, showWarnings = FALSE)
  stopifnot(file.copy(file.path(owner, f), p, overwrite = FALSE))
}
writeLines(capture.output(sessionInfo()), file.path(out, "seal_R_session.txt"))
paths <- sort(unique(c(order, file.path(coord, "seal_writer010c_bookmark_guard_recovery.R"),
  file.path(coord, c("writer_s9_pagination_completion_order_010c.md", "writer_s9_pagination_completion_order_010c_dispatch_manifest.csv",
    "writer010b_independent_completion_disposition.md", "writer010b_independent_completion_manifest.csv")),
  file.path(prior, c("completion_manifest.csv", "completion_handoff.md", "deliverables/Nature_Health_manuscript_round2.docx")),
  file.path(owner, files), list.files(out, full.names = TRUE, recursive = TRUE))))
stopifnot(!anyDuplicated(normalizePath(paths)), !manifest %in% paths)
m <- data.frame(path = paths, bytes = file.info(paths)$size, sha256 = vapply(paths, sha, ""))
write.csv(m, manifest, row.names = FALSE)
verify(manifest, root, nrow(m), sha(manifest))
cat(sprintf("BOOKMARK_GUARD_RECOVERY=SEALED inputs=271/271 dispatch=36/36 stopped_files=%d manifest=%d/%d no_document_write=TRUE\n", length(files), nrow(m), nrow(m)))
cat("order ", sha(order), " ", file.info(order)$size, "\nmanifest ", sha(manifest), " ", file.info(manifest)$size, "\n", sep = "")
