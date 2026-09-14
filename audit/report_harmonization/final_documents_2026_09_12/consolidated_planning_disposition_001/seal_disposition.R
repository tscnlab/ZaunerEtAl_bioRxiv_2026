options(warn = 2, stringsAsFactors = FALSE)
stopifnot(getRversion() == "4.6.1")
d <- "audit/report_harmonization/final_documents_2026_09_12/consolidated_planning_disposition_001"
out <- file.path(d, "dispatch_manifest.csv")
plan <- "/private/tmp/final-documents-plan.JvA4OY"
review <- "/private/tmp/final-documents-plan-review.GXL1fx"
native <- "audit/manuscript_nature_health/revision_2026_09_11/final_documents_readiness_2026_09_12/native_word_review_001"
closure <- "audit/report_harmonization/report018_order72k_non_s5_integration_dispatch/native_word_review_closure_001"
hash <- function(p) unname(digest::digest(file = p, algo = "sha256", serialize = FALSE))
stopifnot(!file.exists(out), !dir.exists(file.path(d, "proposal_snapshot")))
for (p in c(file.path(plan, "planning_manifest.csv"), file.path(native, "completion_manifest.csv"), file.path(closure, "closure_manifest.csv"))) {
 m <- read.csv(p)
 stopifnot(!anyDuplicated(m$path), !p %in% m$path, all(vapply(m$path, hash, character(1)) == m$sha256), all(file.info(m$path)$size == m$bytes))
}
stopifnot(hash(file.path(native, "review_return.md")) == "b146f02cfddcded8a870cfc9027e94b965d0a002e94aa9aeea05b6eeafdc44c9")
checks <- read.csv(file.path(review, "planning_snapshot_checks.csv"))
stopifnot(nrow(checks) == 18L, all(checks$pass))
for (sub in c("proposal_snapshot", "independent_review")) stopifnot(dir.create(file.path(d, sub)))
original <- list.files(plan, full.names = TRUE)
stopifnot(length(original) == 14L, all(file.copy(original, file.path(d, "proposal_snapshot"), overwrite = FALSE)))
copied <- file.path(d, "proposal_snapshot", basename(original))
stopifnot(identical(unname(vapply(original, hash, character(1))), unname(vapply(copied, hash, character(1)))))
write.csv(data.frame(original_path = original, durable_path = copied, sha256 = unname(vapply(copied, hash, character(1))), bytes = as.numeric(file.info(copied)$size)), file.path(d, "proposal_archive_inventory.csv"), row.names = FALSE)
stopifnot(all(file.copy(list.files(review, full.names = TRUE), file.path(d, "independent_review"), overwrite = FALSE)))
writeLines(c("Read-only planning/native evidence disposition. No scientific computation, author source edit, renderer, browser, conversion or promotion.", "Native 179/179 rows rehashed; exact self-path non-circular check preserves historical same-basename manifests. Four existing screenshots inspected, not a new native session.", capture.output(sessionInfo())), file.path(d, "verification_scope_and_session.txt"))
paths <- unique(c(list.files(d, recursive = TRUE, full.names = TRUE), file.path(native, c("review_return.md", "completion_manifest.csv", "completion_seal.json", "postflight.json", "view_inventory.csv", "18_page63_s2a.png", "22_page74_s5.png", "46_page85_table_s7b.png", "47_page86_table_s7c.png")), file.path(closure, c("disposition.md", "closure_manifest.csv", "closure_seal.json"))))
stopifnot(!out %in% paths, !anyDuplicated(normalizePath(paths)), all(!dir.exists(paths)))
m <- data.frame(path = paths, sha256 = unname(vapply(paths, hash, character(1))), bytes = as.numeric(file.info(paths)$size))
write.csv(m, out, row.names = FALSE)
z <- read.csv(out)
stopifnot(all(vapply(z$path, hash, character(1)) == z$sha256), all(file.info(z$path)$size == z$bytes))
cat(sprintf("FINAL_DOCS_PREFLIGHT_DISPOSITION=PASS rows=%d/%d decision=%s manifest=%s\n", nrow(z), nrow(z), hash(file.path(d, "disposition.md")), hash(out)))
