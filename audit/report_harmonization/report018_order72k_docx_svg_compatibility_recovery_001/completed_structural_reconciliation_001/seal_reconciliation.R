options(warn = 2, stringsAsFactors = FALSE)
stopifnot(getRversion() == "4.6.1")
root <- normalizePath(getwd(), mustWork = TRUE)
base <- "audit/report_harmonization/report018_order72k_docx_svg_compatibility_recovery_001/completed_structural_reconciliation_001"
tmp <- "/private/tmp/order72k-docx-package-independent.S6mIE2"
owner <- "audit/manuscript_nature_health/revision_2026_09_11/consolidated_display_repair_order72k/docx_svg_compatibility_recovery_001"
harm <- "audit/report_harmonization/report018_order72k_non_s5_integration_dispatch"
abs <- function(p) ifelse(startsWith(p, "/"), p, file.path(root, p))
rel <- function(p) {
  f <- normalizePath(abs(p), mustWork = TRUE)
  ifelse(startsWith(f, paste0(root, "/")), substring(f, nchar(root) + 2L), f)
}
pin <- function(p) {
  f <- abs(p); stopifnot(file.exists(f), !dir.exists(f), identical(Sys.readlink(f), ""))
  data.frame(path = rel(p), sha256 = digest::digest(file = f, algo = "sha256", serialize = FALSE), bytes = unname(file.info(f)$size))
}
pins <- function(p) do.call(rbind, lapply(p, pin))
out <- file.path(base, "reconciliation_manifest.csv")
seal <- file.path(base, "reconciliation_seal.json")
stopifnot(!file.exists(abs(out)), !file.exists(abs(seal)))
original <- list.files(tmp, full.names = TRUE, all.files = TRUE, no.. = TRUE)
stopifnot(length(original) == 24L, !any(dir.exists(original)))
copied <- file.path(base, "independent_replay", basename(original))
stopifnot(identical(pins(original)$sha256, pins(copied)$sha256), identical(pins(original)$bytes, pins(copied)$bytes))
key <- read.csv(abs(file.path(base, "independent_replay/final_key_identities.csv")))
stopifnot(identical(pins(key$path)$sha256, key$sha256), all(pins(key$path)$bytes == key$bytes))
observed <- read.csv(abs(file.path(base, "independent_replay/final_manifests_rehash_533.csv")))
current <- pins(observed$path)
stopifnot(nrow(observed) == 533L, all(observed$exact), identical(current$sha256, observed$expected_sha256), all(current$bytes == observed$expected_bytes))
hist <- read.csv(abs(file.path(base, "independent_replay/final_history_rehash_7347.csv")))
stopifnot(nrow(hist) == 7347L, all(hist$coordinator_final_exact))
checks <- read.csv(abs(file.path(base, "independent_replay/final_checks_summary.csv")))
stopifnot(identical(checks$passing_checks, c(57L, 64L, 24L, 57L, 190L)), all(checks$pass))
paths <- unique(rel(c(observed$path, key$path, copied,
  file.path(base, c("disposition.md", "seal_reconciliation.R")),
  "audit/report_harmonization/owner_orders/72k_docx_svg_compatibility_recovery_001.md")))
stopifnot(!out %in% paths, !seal %in% paths, !anyDuplicated(paths))
m <- pins(sort(paths))
write.csv(m, abs(out), row.names = FALSE)
stopifnot(identical(pins(m$path), m))
identity <- pin(out)
info <- list(status = "STRUCTURAL_PASS_VISUAL_QA_PENDING", gate = "REPORT018-ORDER72K-NON-S5-INTEGRATED-PREVIEW-REVIEW",
  created_utc = format(Sys.time(), tz = "UTC", format = "%Y-%m-%d %H:%M:%S UTC"),
  manifest = out, manifest_sha256 = identity$sha256, members = nrow(m),
  disposition = pin(file.path(base, "disposition.md")),
  candidate_sha256 = "f055f0c0f6225e372ed83ddb6bbe189e64f35d7306e7e54af563687991f6492c",
  owner_members = 507L, harmonizer_members = 26L, historical_current_rows = 7347L,
  coordinator_document_checks = 57L, coordinator_package_checks = 190L,
  assembly_invocations = 1L, embedding_invocations = 1L, file_processing_assignment = "closed",
  office_QA_used = 0L, visual_acceptance = FALSE, new_execution_authority = FALSE,
  Brown_S5_hold = TRUE, canonical_promotion = FALSE, exclusions = c(out, seal))
jsonlite::write_json(info, abs(seal), auto_unbox = TRUE, pretty = TRUE)
print(pins(c(file.path(base, "disposition.md"), out, seal)), row.names = FALSE)
cat(sprintf("COORDINATOR_RECONCILIATION=PASS seal=%d/%d unique non-circular STRUCTURAL_PASS_VISUAL_QA_PENDING new_authority=none\n", nrow(m), nrow(m)))
