stopifnot(as.character(getRversion()) == "4.6.1")
root <- normalizePath(getwd(), mustWork = TRUE)
coord <- "audit/report_harmonization/final_documents_2026_09_13"
out <- file.path(coord, "writer010c_final_independent_evidence")
tmp <- "/private/tmp/writer010c-acceptance.3w4Yzr"
wordroot <- "audit/manuscript_nature_health/final_pagination_completion_2026_09_14"
candidate <- "audit/manuscript_nature_health/final_format_completion_2026_09_14"
plan <- "audit/report_harmonization/final_integration_reconciliation_2026_09_14"
acceptance <- file.path(coord, "writer010c_final_independent_acceptance.md")
aseal <- file.path(coord, "writer010c_final_independent_acceptance_manifest.csv")
order <- file.path(coord, "final_site_candidate_order_011.md")
dispatch <- file.path(coord, "final_site_candidate_order_011_dispatch_manifest.csv")
sha <- function(p) {z <- file(p, "rb"); on.exit(close(z)); as.character(openssl::sha256(z))}
verify <- function(file, base, count, pin) {
  stopifnot(sha(file) == pin)
  m <- read.csv(file, stringsAsFactors = FALSE)
  p <- ifelse(startsWith(m$path, "/"), m$path, file.path(base, m$path))
  stopifnot(nrow(m) == count, !anyDuplicated(m$path), all(file.exists(p)),
    !anyDuplicated(normalizePath(p)), !normalizePath(file) %in% normalizePath(p),
    all(vapply(p, sha, "") == m$sha256), all(file.info(p)$size == m$bytes))
}
stopifnot(!dir.exists(out), !file.exists(aseal), !file.exists(dispatch),
  !dir.exists("audit/report_harmonization/final_site_integration_2026_09_14"))
verify(file.path(wordroot, "completion_manifest.csv"), wordroot, 145L, "7fce1f1e88980219a1e8199c5440af0ed19070cbf28b3906bcce13d7bd529ad2")
verify(file.path(candidate, "completion_manifest.csv"), candidate, 271L, "86ba7e46cdf106090d8ceaee3109d751dddc32f0f80d62da325ce6b7698583e2")
verify(file.path(plan, "completion_manifest.csv"), plan, 25L, "6a4e78f7952a467d4e3dfd629313500c4380b2cdc7288b5182214df26183fe91")
stopifnot(grepl("WRITER010C_INDEPENDENT=PASS", readLines(file.path(tmp, "result.txt"))[1], fixed = TRUE),
  grepl("FINAL_INTEGRATION_PLAN=PASS", readLines(file.path(tmp, "integration_result.txt"))[1], fixed = TRUE))
dir.create(out)
for (f in list.files(tmp, recursive = TRUE, full.names = FALSE)) {
  target <- file.path(out, f)
  dir.create(dirname(target), recursive = TRUE, showWarnings = FALSE)
  stopifnot(file.copy(file.path(tmp, f), target, overwrite = FALSE))
}
seal <- function(paths, destination) {
  paths <- sort(unique(paths))
  stopifnot(!file.exists(destination), all(file.exists(paths)), !any(file.info(paths)$isdir),
    !anyDuplicated(normalizePath(paths)), !destination %in% paths)
  m <- data.frame(path = paths, bytes = file.info(paths)$size, sha256 = vapply(paths, sha, ""))
  write.csv(m, destination, row.names = FALSE)
  verify(destination, root, nrow(m), sha(destination))
  nrow(m)
}
a <- seal(c(acceptance, list.files(out, recursive = TRUE, full.names = TRUE),
  file.path(wordroot, c("completion_manifest.csv", "completion_handoff.md", "completion_seal.json", "deliverables/Nature_Health_manuscript.docx",
    "evidence/final_full_page_review.csv", "evidence/final_immutability_checks.csv", "evidence/member_delta.csv", "evidence/patch_proof.json", "qa/main/page-83.png")),
  file.path(candidate, c("completion_manifest.csv", "evidence/native19_identity.csv")),
  file.path(plan, c("completion_manifest.csv", "reconciliation.md", "proposed_integration_matrix.csv")),
  file.path(coord, "seal_final_word_and_site_candidate_011.R")), aseal)
native <- list.files(file.path(candidate, "editable_tables"), pattern = "[.]docx$", full.names = TRUE)
stopifnot(length(native) == 19L)
d <- seal(c(order, acceptance, aseal, native,
  file.path(wordroot, c("completion_manifest.csv", "completion_handoff.md", "deliverables/Nature_Health_manuscript.docx")),
  file.path(candidate, c("completion_manifest.csv", "completion_handoff.md", "project/html_round2/ZaunerEtAl2026_NatHealth_phase3_brown.html")),
  file.path(plan, c("completion_manifest.csv", "completion_seal.json", "reconciliation.md", "proposed_integration_matrix.csv",
    "input_identities.csv", "reader_routes.csv", "build_inventory.csv", "integration_component_identities.csv", "local_reference_audit.csv",
    "editable_table_bindings.csv", "search_entry_audit.csv", "source_transition_status.csv", "public_dependency_closure.csv")),
  "audit/manuscript_nature_health/table_layout_visual_corrections_2026_09_14/attempt_02/evidence/cumulative_passage_changes.csv",
  "audit/manuscript_nature_health/table_layout_visual_corrections_2026_09_14/attempt_02/evidence/cumulative_passage_changes.md",
  "audit/report_harmonization/phase4_corpus_manifest.csv", "_quarto-nathealth.yml", "renv.lock",
  file.path(coord, "seal_final_word_and_site_candidate_011.R")), dispatch)
cat(sprintf("FINAL_WORD_ACCEPTED=145/145 structural=22/22 prior=271/271 acceptance=%d/%d SITE011_CANDIDATE_SEALED=%d/%d plan=25/25\n", a, a, d, d))
for (p in c(acceptance, aseal, order, dispatch)) cat(sha(p), file.info(p)$size, p, "\n")
