stopifnot(as.character(getRversion()) == "4.6.1")
root <- normalizePath(getwd(), mustWork = TRUE)
out <- "/private/tmp/writer010b-acceptance.28Rk3C"
candidate <- file.path(root, "audit/manuscript_nature_health/final_format_completion_2026_09_14")
prior <- file.path(root, "audit/manuscript_nature_health/final_review_production_2026_09_14")
coord <- file.path(root, "audit/report_harmonization/final_documents_2026_09_13")
sha <- function(path) { con <- file(path, "rb"); on.exit(close(con)); as.character(openssl::sha256(con)) }
sha_raw <- function(x) as.character(openssl::sha256(charToRaw(x)))
verify <- function(path, base, count, pin, label) {
  stopifnot(sha(path) == pin)
  m <- read.csv(path, stringsAsFactors = FALSE)
  p <- ifelse(startsWith(m$path, "/"), m$path, file.path(base, m$path))
  stopifnot(nrow(m) == count, !anyDuplicated(m$path), all(file.exists(p)),
    !normalizePath(path) %in% normalizePath(p), !anyDuplicated(normalizePath(p)))
  m$observed_bytes <- file.info(p)$size
  m$observed_sha256 <- vapply(p, sha, "")
  m$exact <- m$bytes == m$observed_bytes & m$sha256 == m$observed_sha256
  stopifnot(all(m$exact))
  write.csv(m, file.path(out, paste0(label, "_rehash.csv")), row.names = FALSE)
  invisible(m)
}
owner <- verify(file.path(candidate, "completion_manifest.csv"), candidate, 271L,
  "86ba7e46cdf106090d8ceaee3109d751dddc32f0f80d62da325ce6b7698583e2", "owner271")
verify(file.path(prior, "candidate_package_manifest.csv"), prior, 439L,
  "624753fabeb69a47cc9fe7262cba25849963e8ab8aca201512f47fbb5ec65b32", "prior439")
verify(file.path(coord, "writer_format_completion_order_010b_dispatch_manifest.csv"), root, 60L,
  "26e9b4fbe415e61c3a818286b397999c7f0411dd6c2877787b1ca153980562b1", "dispatch60")
stopifnot(sha(file.path(candidate, "completion_handoff.md")) == "b3f8b4cd969f67b54d99f69f1d6530fc7bbd3ec90e7c725f4a56d560b6bd5a1d",
  sha(file.path(candidate, "completion_seal.json")) == "bb558fe7280183cf354b574d150374b0307a31fc89572828770555bd7bda28a2")

# Replay the unchanged owner verifier with exactly four evidence writes redirected
# to new temporary files. No owner, candidate, source, or build path may be written.
allowed <- c("evidence/native19_identity.csv", "evidence/complete_structural_checks.csv",
  "evidence/complete_verification_R_session.txt", "evidence/structural_summary.json")
dir.create(file.path(out, "replay"))
dest <- function(path) {
  actual <- normalizePath(path, mustWork = FALSE)
  expected <- file.path(candidate, allowed)
  stopifnot(length(actual) == 1L, actual %in% expected)
  file.path(out, "replay", basename(actual))
}
env <- new.env(parent = globalenv())
env$write.csv <- function(x, file, ...) utils::write.csv(x, dest(file), ...)
env$writeLines <- function(text, con = stdout(), ...) base::writeLines(text, dest(con), ...)
env$write_json <- function(x, path, ...) jsonlite::write_json(x, dest(path), ...)
source(file.path(candidate, "helpers/verify_completion.R"), local = env)
stopifnot(identical(read.csv(file.path(out, "replay/complete_structural_checks.csv")),
  read.csv(file.path(candidate, "evidence/complete_structural_checks.csv"))))
checks <- read.csv(file.path(out, "replay/complete_structural_checks.csv"))
stopifnot(nrow(checks) == 114L, all(checks$pass))
native <- read.csv(file.path(out, "replay/native19_identity.csv"))
stopifnot(nrow(native) == 19L, all(native$sha256 == native$prior_sha256),
  sha(file.path(candidate, "editable_tables/Table_S2.docx")) == "0c834387ff6462b737381d028f0482636c5e55ad0443234f1cb8c165dda75334")
pages <- read.csv(file.path(candidate, "evidence/full_page_review_103.csv"), stringsAsFactors = FALSE)
stopifnot(nrow(pages) == 103L, identical(pages$page, 1:103), all(pages$visually_reviewed),
  all(vapply(file.path(candidate, pages$image), sha, "") == pages$image_sha256),
  all(pages$main_docx_sha256 == "d6dd418054fb8287efe2a4d49fc2d4adaf5a4a56b8a6ded503645ca34c599701"))
write.csv(pages[, c("page", "status", "observation")], file.path(out, "owner_review_classifications.csv"), row.names = FALSE)

docx <- file.path(candidate, "deliverables/Nature_Health_manuscript_round2.docx")
stopifnot(sha(docx) == "d6dd418054fb8287efe2a4d49fc2d4adaf5a4a56b8a6ded503645ca34c599701")
members <- unzip(docx, list = TRUE)
con <- unz(docx, "word/document.xml", "rb")
xml <- rawToChar(readBin(con, "raw", n = members$Length[match("word/document.xml", members$Name)]))
close(con)
blocks <- regmatches(xml, gregexpr("<w:p(?:[[:space:]][^>]*)?>.*?</w:p>", xml, perl = TRUE))[[1]]
i <- which(grepl("Supplementary Figure S9. Paired sensor-position hourly associations", blocks, fixed = TRUE))
stopifnot(length(i) == 1L, grepl("Hourly routine analyses", blocks[[i - 1L]], fixed = TRUE))
before <- blocks[[i]]
after <- sub("<w:pageBreakBefore/>", "", before, fixed = TRUE)
post <- sub(before, after, xml, fixed = TRUE)
stopifnot(sha_raw(xml) == "cb767c3e378f5b08cb7251fbe5f3a306bfe73ac0d10ec3e3b67bafc0fdd6e393",
  sha_raw(post) == "98e2924ccc67952165ada5b01d1904b40eacea517908480b47faf0a0e58ffb7f",
  sha_raw(before) == "836b1402a77c1d81fbd0fbdd06992a3f05398a12fc6ab9d110f67035bb295ec8",
  sha_raw(after) == "046cac3f3089d05dd76487e1e415e5f088d9ea88aa6df856ca3392ea8492c311",
  identical(charToRaw(sub(after, before, post, fixed = TRUE)), charToRaw(xml)))
prospective <- data.frame(item = c("document_xml_before", "document_xml_after", "S9_before", "S9_after"),
  bytes = nchar(c(xml, post, before, after), type = "bytes"),
  sha256 = vapply(c(xml, post, before, after), sha_raw, ""))
write.csv(prospective, file.path(out, "prospective_xml_identities.csv"), row.names = FALSE)
stopifnot(all(vapply(file.path(candidate, owner$path), sha, "") == owner$sha256))
writeLines(capture.output(sessionInfo()), file.path(out, "session.txt"))
writeLines(c("WRITER010B_INDEPENDENT=PASS owner=271/271 prior=439/439 dispatch=60/60 checks=114/114 native=19/19 review_rows=103/103 XML_reverse=PASS",
  "One genuine pagination finding remains. No new DOCX, render, owner evidence write, or source/scientific mutation."), file.path(out, "result.txt"))
cat(readLines(file.path(out, "result.txt")), sep = "\n")
