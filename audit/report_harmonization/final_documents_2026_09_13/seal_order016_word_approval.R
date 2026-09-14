stopifnot(getRversion() == "4.6.1")
suppressPackageStartupMessages(library(digest))
d <- "audit/report_harmonization/final_documents_2026_09_13"
w <- "audit/manuscript_nature_health/a4_display_revision_2026_09_14"
approval <- "audit/manuscript_nature_health/a4_display_word_author_approval_2026_09_14.md"
document <- file.path(w, "deliverables/Nature_Health_manuscript.docx")
manifest <- file.path(w, "word_candidate_manifest.csv")
out <- file.path(d, "order016_word_author_approval_addendum_manifest.csv")
check_path <- file.path(d, "order016_word_author_approval_318_rehash.csv")
stopifnot(!file.exists(out), !file.exists(check_path))
sha <- function(p) digest(file = p, algo = "sha256")
stopifnot(sha(approval) == "93b63ed97e02431e3365c2920dfeb1509ef24dad3a73599c4e5d9fe51bb8504d",
 sha(document) == "6f0ce7a50b608f91d24c31ae0b9b0edefe15828ed4f966732ea616c6e395a570",
 sha(manifest) == "996e138233eff74da4754aae6c2fbc1a6b5785c9d196fa2c64df2fe8eeccb464")
m <- read.csv(manifest, stringsAsFactors = FALSE)
full <- file.path(w, m$path)
stopifnot(nrow(m) == 318L, !anyDuplicated(m$path), !normalizePath(manifest) %in% normalizePath(full),
 !any(nzchar(Sys.readlink(full))))
m$observed_sha256 <- vapply(full, sha, character(1))
m$observed_bytes <- file.info(full)$size
m$exact <- m$sha256 == m$observed_sha256 & m$bytes == m$observed_bytes
stopifnot(all(m$exact))
write.csv(m, check_path, row.names = FALSE)
paths <- c(approval, document, manifest, check_path,
 file.path(w, "html_visual_qa/qa_handoff.md"),
 file.path(d, c("order016_word_author_approval_addendum.md", "seal_order016_word_approval.R",
 "site_a4_delta_promotion_order_016.md", "site_a4_delta_promotion_order_016_dispatch_manifest.csv",
 "site_a4_delta_promotion_order_016_dispatch_receipt.md", "site_a4_delta_promotion_order_016_dispatch_receipt_manifest.csv")))
stopifnot(all(file.exists(paths)), !anyDuplicated(paths), !out %in% paths)
x <- data.frame(path = paths, bytes = file.info(paths)$size, sha256 = vapply(paths, sha, character(1)))
write.csv(x, out, row.names = FALSE)
z <- read.csv(out, stringsAsFactors = FALSE)
stopifnot(nrow(z) == 11L, all(vapply(z$path, sha, character(1)) == z$sha256),
 all(file.info(z$path)$size == z$bytes))
cat("ORDER016_WORD_APPROVAL=SEALED author_document=exact candidate=318/318 manifest=11/11\n")
for (p in c(file.path(d, "order016_word_author_approval_addendum.md"), out)) cat(sha(p), file.info(p)$size, p, "\n")
