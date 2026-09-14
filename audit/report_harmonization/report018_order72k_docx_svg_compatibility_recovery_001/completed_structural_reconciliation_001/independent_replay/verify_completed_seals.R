options(warn = 2, stringsAsFactors = FALSE)
stopifnot(getRversion() == "4.6.1")
root <- normalizePath(getwd(), mustWork = TRUE)
owner <- "audit/manuscript_nature_health/revision_2026_09_11/consolidated_display_repair_order72k"
record <- file.path(owner, "docx_svg_compatibility_recovery_001")
harm <- "audit/report_harmonization/report018_order72k_non_s5_integration_dispatch"
evidence <- "/private/tmp/order72k-docx-package-independent.S6mIE2"
absolute <- function(p) ifelse(startsWith(p, "/"), p, file.path(root, p))
pin <- function(p) {
  f <- absolute(p)
  stopifnot(file.exists(f), !dir.exists(f), identical(Sys.readlink(f), ""))
  data.frame(path = p, sha256 = digest::digest(file = f, algo = "sha256", serialize = FALSE), bytes = unname(file.info(f)$size))
}
pins <- function(p) do.call(rbind, lapply(p, pin))
keys <- c(file.path(record, c("recovery_return.md", "completion_manifest.csv", "completion_seal.json")),
  file.path(harm, c("completed_svg_handoff_disposition.md", "completed_svg_handoff_independent_manifest.csv", "completed_svg_handoff_independent_seal.json")),
  file.path(owner, "Nature_Health_non_S5_preview_attempt1.docx"))
expected <- c("dda8061bf2133e17a510f16ae22d6532d22c802eb5da5fb4f857607c33e87c35", "aa4ccbbd1bf9f2e796dd18bc3e7d228d99b3031130c902b95af06e862cba5e01", "a63fed0cd0c8597a557679cd3946b48c7aa9213a5e22af057fe1a411b12c3a83", "757158bc00479e69b243286104f7d2267124cba926cb5f25f0f5737811cb228a", "9f7354263a547114acef547eaeaefcba8091a2bdfcc4d6df1bb1a8d5825baba6", "a8c88219be7671ad10128f3ba20aa84290961cd8947281b91b01d633c1b57c43", "f055f0c0f6225e372ed83ddb6bbe189e64f35d7306e7e54af563687991f6492c")
key_rows <- pins(keys)
stopifnot(identical(key_rows$sha256, expected), key_rows$bytes[[7]] == 13498777)
audit_manifest <- function(path, count) {
  m <- read.csv(absolute(path))
  canonical <- normalizePath(absolute(m$path), mustWork = TRUE)
  stopifnot(nrow(m) == count, !anyDuplicated(canonical), !normalizePath(absolute(path)) %in% canonical)
  observed <- pins(m$path)
  stopifnot(identical(observed$sha256, m$sha256), all(observed$bytes == m$bytes))
  data.frame(manifest = path, path = m$path, expected_sha256 = m$sha256, expected_bytes = m$bytes, observed_sha256 = observed$sha256, observed_bytes = observed$bytes, exact = TRUE)
}
owner_rows <- audit_manifest(file.path(record, "completion_manifest.csv"), 507L)
harm_rows <- audit_manifest(file.path(harm, "completed_svg_handoff_independent_manifest.csv"), 26L)
owner_seal <- jsonlite::fromJSON(absolute(file.path(record, "completion_seal.json")))
harm_seal <- jsonlite::fromJSON(absolute(file.path(harm, "completed_svg_handoff_independent_seal.json")))
stopifnot(identical(owner_seal$status, "VISUAL_QA_PENDING"), identical(harm_seal$status, "STRUCTURAL_PASS_VISUAL_QA_PENDING"), !owner_seal$visual_acceptance, !harm_seal$visual_acceptance,
  !owner_seal$canonical_promotion, !harm_seal$canonical_promotion, owner_seal$Brown_S5_hold, harm_seal$Brown_S5_hold,
  owner_seal$invocations$assembly == 1L, owner_seal$invocations$embedding == 1L,
  all(unlist(owner_seal$invocations[setdiff(names(owner_seal$invocations), c("assembly", "embedding"))]) == 0L),
  identical(owner_seal$manifest_sha256, expected[[2]]), identical(harm_seal$manifest_sha256, expected[[5]]), owner_seal$members == 507L, harm_seal$members == 26L)
output_rows <- pins(owner_seal$outputs$path)
stopifnot(identical(output_rows$sha256, owner_seal$outputs$sha256), all(output_rows$bytes == owner_seal$outputs$bytes))
nested <- read.csv(absolute(file.path(record, "harmonizer_independent_evidence_pins.csv")))
stopifnot(nrow(nested) == 5L, !anyDuplicated(normalizePath(nested$path)))
nested_observed <- pins(nested$path)
stopifnot(identical(nested_observed$sha256, nested$sha256), all(nested_observed$bytes == nested$bytes))
hist <- read.csv(file.path(evidence, "after_embedding_preservation_rows.csv"))
stopifnot(nrow(hist) == 7347L, all(hist$exact))
hist_observed <- pins(hist$resolved)
hist$coordinator_final_sha256 <- hist_observed$sha256
hist$coordinator_final_bytes <- hist_observed$bytes
hist$coordinator_final_exact <- hist$expected_sha256 == hist_observed$sha256 & hist$expected_bytes == hist_observed$bytes
stopifnot(all(hist$coordinator_final_exact))
check_paths <- c(file.path(record, "final_document_checks.csv"), file.path(harm, "completed_svg_docx_independent_001/independent_package_checks.csv"),
  file.path(harm, "completed_svg_handoff_independent_verified_001/checks.csv"), file.path(evidence, "verified_document_checks.csv"), file.path(evidence, "embedding_independent_checks.csv"))
counts <- c(57L, 64L, 24L, 57L, 190L)
for (i in seq_along(check_paths)) {
  x <- read.csv(absolute(check_paths[[i]])); stopifnot(nrow(x) == counts[[i]], all(x$pass))
}
write.csv(key_rows, file.path(evidence, "final_key_identities.csv"), row.names = FALSE)
write.csv(rbind(owner_rows, harm_rows), file.path(evidence, "final_manifests_rehash_533.csv"), row.names = FALSE)
write.csv(hist, file.path(evidence, "final_history_rehash_7347.csv"), row.names = FALSE)
write.csv(nested_observed, file.path(evidence, "final_nested_evidence_rehash_5.csv"), row.names = FALSE)
write.csv(data.frame(path = check_paths, passing_checks = counts, pass = TRUE), file.path(evidence, "final_checks_summary.csv"), row.names = FALSE)
writeLines(c("Read-only structural and exact-byte final reconciliation. No producer or visual operation.", capture.output(sessionInfo())), file.path(evidence, "final_reconciliation_session.txt"))
cat("COORDINATOR_COMPLETED_DOCX_SEALS=PASS owner=507/507 harmonizer=26/26 nested=5/5 history=7347/7347 document=57/57 package=190/190 final_status=STRUCTURAL_PASS_VISUAL_QA_PENDING\n")
