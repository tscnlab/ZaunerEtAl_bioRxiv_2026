options(warn = 2, stringsAsFactors = FALSE)
stopifnot(getRversion() == "4.6.1")
root <- normalizePath(getwd(), mustWork = TRUE)
base <- "audit/report_harmonization/final_documents_2026_09_12"
owner <- "audit/manuscript_nature_health/revision_2026_09_11/consolidated_display_repair_order72k"
coordinator <- "audit/report_harmonization/report018_order72k_docx_svg_compatibility_recovery_001/completed_structural_reconciliation_001"
pin <- function(p) {
 f <- file.path(root, p); stopifnot(file.exists(f), !dir.exists(f), identical(Sys.readlink(f), ""))
 data.frame(path = p, sha256 = digest::digest(file = f, algo = "sha256", serialize = FALSE), bytes = unname(file.info(f)$size))
}
paths <- c(file.path(owner, "Nature_Health_non_S5_preview_attempt1.docx"), file.path(owner, "docx_svg_compatibility_recovery_001/completion_manifest.csv"),
 file.path(coordinator, c("disposition.md", "reconciliation_manifest.csv", "reconciliation_seal.json")),
 file.path(base, c("native_word_read_only_review_order.md", "seal_native_word_review.R")))
expected <- c("f055f0c0f6225e372ed83ddb6bbe189e64f35d7306e7e54af563687991f6492c", "aa4ccbbd1bf9f2e796dd18bc3e7d228d99b3031130c902b95af06e862cba5e01", "c8690ec7209cf3da599b133185782923b639227b52a6b29b86ec2cd89a23663e", "00dfd5842ab298eaa43b44edc3472d09d7ee3c63bd0c4530c1f75bbad417cb18", "c192b44719fede92b2969c079d1aba2fb33c4c61e400644ad0cff2f3b7cfb5d3")
m <- do.call(rbind, lapply(paths, pin))
stopifnot(identical(m$sha256[seq_len(5)], expected), m$bytes[[1]] == 13498777, !anyDuplicated(m$path))
new_root <- "audit/manuscript_nature_health/revision_2026_09_11/final_documents_readiness_2026_09_12/native_word_review_001"
stopifnot(!file.exists(file.path(root, new_root)))
out <- file.path(base, "native_word_review_dispatch_manifest.csv")
stopifnot(!out %in% m$path, !file.exists(file.path(root, out)))
write.csv(m, file.path(root, out), row.names = FALSE)
stopifnot(identical(m, do.call(rbind, lapply(paths, pin))))
print(do.call(rbind, lapply(c(file.path(base, "native_word_read_only_review_order.md"), out), pin)), row.names = FALSE)
cat("NATIVE_WORD_READONLY_REVIEW_RELEASE=PASS manifest=7/7 unique non-circular conditional_surface_access only_no_save_no_render\n")
