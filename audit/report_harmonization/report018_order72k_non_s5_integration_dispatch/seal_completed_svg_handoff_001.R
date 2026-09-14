options(stringsAsFactors = FALSE)
stopifnot(getRversion() == "4.6.1")
root <- normalizePath(getwd(), mustWork = TRUE)
D <- file.path(root, "audit/report_harmonization/report018_order72k_non_s5_integration_dispatch")
R <- file.path(root, "audit/manuscript_nature_health/revision_2026_09_11/consolidated_display_repair_order72k/docx_svg_compatibility_recovery_001")
sha <- function(path) {
  con <- file(path, "rb"); on.exit(close(con))
  unname(unclass(as.character(openssl::sha256(con))))
}
manifest <- file.path(D, "completed_svg_handoff_independent_manifest.csv")
seal <- file.path(D, "completed_svg_handoff_independent_seal.json")
stopifnot(!file.exists(manifest), !file.exists(seal))
verified <- file.path(D, "completed_svg_handoff_independent_verified_001")
checks <- read.csv(file.path(verified, "checks.csv"))
current <- read.csv(file.path(verified, "current_owner_507_rows.csv"))
history <- read.csv(file.path(verified, "independent_history_current_7347_rows.csv"))
stopifnot(nrow(checks) == 24L, all(checks$pass), nrow(current) == 507L, all(current$exact),
  nrow(history) == 7347L, all(history$exact))
paths <- sort(unique(c(file.path(D, c("review_completion_seal_001.R", "review_completion_seal_verified_001.R",
  "review_completed_svg_docx_001.R", "completed_svg_handoff_disposition.md",
  "completed_svg_handoff_execution_receipts.json", "seal_completed_svg_handoff_001.R")),
  unlist(lapply(file.path(D, c("completed_svg_handoff_independent_001", "completed_svg_handoff_independent_verified_001",
  "completed_svg_docx_independent_001")), list.files, full.names = TRUE)),
  file.path(R, c("recovery_return.md", "completion_manifest.csv", "completion_seal.json")))))
stopifnot(all(file.exists(paths)), !any(file.info(paths)$isdir), all(Sys.readlink(paths) == ""))
inventory <- data.frame(path = substring(paths, nchar(root) + 2L), sha256 = vapply(paths, sha, character(1)),
  bytes = file.info(paths)$size)
rownames(inventory) <- NULL
write.csv(inventory, manifest, row.names = FALSE)
stopifnot(all(vapply(paths, sha, character(1)) == inventory$sha256))
payload <- list(status = "STRUCTURAL_PASS_VISUAL_QA_PENDING", gate = "REPORT018-ORDER72K-NON-S5-INTEGRATED-PREVIEW-REVIEW",
  created_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
  manifest = substring(manifest, nchar(root) + 2L), manifest_sha256 = sha(manifest), members = nrow(inventory),
  owner_manifest_sha256 = "aa4ccbbd1bf9f2e796dd18bc3e7d228d99b3031130c902b95af06e862cba5e01",
  owner_seal_sha256 = "a63fed0cd0c8597a557679cd3946b48c7aa9213a5e22af057fe1a411b12c3a83",
  candidate_sha256 = "f055f0c0f6225e372ed83ddb6bbe189e64f35d7306e7e54af563687991f6492c",
  current_members_verified = 507L, historical_current_rows_verified = 7347L, handoff_checks = 24L,
  independent_package_checks = 64L, source_version_aliases = 5L, new_cache_transitions = 0L,
  writer_status = "idle; completed without error", file_processing_assignment = "released",
  visual_acceptance = FALSE, Brown_S5_hold = TRUE, canonical_promotion = FALSE,
  exclusions = c(substring(manifest, nchar(root) + 2L), substring(seal, nchar(root) + 2L)))
jsonlite::write_json(payload, seal, auto_unbox = TRUE, pretty = TRUE, digits = NA)
cat(jsonlite::toJSON(list(members = nrow(inventory), manifest_sha256 = sha(manifest), seal_sha256 = sha(seal)),
  auto_unbox = TRUE, pretty = TRUE), "\n")
