#!/usr/bin/env Rscript

# Seal four independent candidate acceptances without creating the seven-row
# aggregate that remains contingent on H05.

stopifnot(as.character(getRversion()) == "4.6.1")
stopifnot(requireNamespace("digest", quietly = TRUE))

root <- normalizePath(".", mustWork = TRUE)
review_root <- file.path(
  root,
  "audit/report_harmonization/report018_order72_qa_recovery/reviewer"
)

shared <- c(
  "audit/report_harmonization/owner_orders/72b_consolidated_svg_qa_and_unstarted_h05_export.md",
  "audit/report_harmonization/report018_order72_qa_recovery/recovery_release_manifest.csv",
  "audit/report_harmonization/report018_order72_qa_recovery/qa_svg_canvas.R",
  "audit/report_harmonization/report018_order72_qa_recovery/reviewer/build_visual_proofs.R",
  "audit/report_harmonization/report018_order72_qa_recovery/reviewer/run_independent_svg_audit.R",
  "audit/report_harmonization/report018_order72_qa_recovery/reviewer/release_pin_recheck.csv",
  "audit/report_harmonization/report018_order72_qa_recovery/reviewer/candidate_structure_qa.csv",
  "audit/report_harmonization/report018_order72_qa_recovery/reviewer/candidate_visible_text.csv",
  "audit/report_harmonization/report018_order72_qa_recovery/reviewer/visual_proof_inventory.csv",
  "audit/report_harmonization/report018_order72_qa_recovery/reviewer/package_versions.csv",
  "audit/report_harmonization/report018_order72_qa_recovery/reviewer/session_info.txt"
)

case_inputs <- list(
  h02 = c(
    "audit/hypotheses/H02/report018_order72_svg_export/candidate/figure4_exact_layout_replication.svg",
    "artifacts/10_figures/H02/figure4_exact_layout_replication.png"
  ),
  h08 = c(
    "audit/hypotheses/H08/report018_order72_svg_export/candidate/H08_near_eye_effects.svg",
    "artifacts/10_figures/H08/H08_near_eye_effects.png"
  ),
  h10 = c(
    "audit/hypotheses/H10/report018_order72_svg_export/candidate/H10_age_site_significant_associations_selection_candidate.svg",
    "audit/manuscript_nature_health/figure_table_selection_assets/H10_age_site_significant_associations_selection_candidate.png",
    "audit/report_harmonization/report018_order72_qa_recovery/reviewer/h10_tag_occurrence.csv"
  ),
  h11 = c(
    "audit/hypotheses/H11/report018_order72_svg_export/candidate/H11_reader_primary_near_eye_curves.svg",
    "artifacts/10_figures/H11/stage3/H11_reader_primary_near_eye_curves.png"
  )
)

sha256 <- function(path) digest::digest(file = path, algo = "sha256")
relative <- function(path) sub(paste0("^", root, "/"), "", normalizePath(path, mustWork = TRUE))

for (case in names(case_inputs)) {
  manifest_path <- file.path(review_root, paste0(case, "_independent_acceptance_manifest.csv"))
  stopifnot(!file.exists(manifest_path))
  case_dirs <- file.path(review_root, c(case, paste0(case, "_original"), paste0(case, "_reader")))
  generated <- unlist(lapply(
    case_dirs,
    function(path) list.files(path, recursive = TRUE, full.names = TRUE)
  ), use.names = FALSE)
  record <- file.path(review_root, paste0(case, "_independent_acceptance.md"))
  members <- sort(unique(c(
    file.path(root, shared),
    file.path(root, case_inputs[[case]]),
    generated,
    record
  )))
  stopifnot(length(members) > 0L, all(file.exists(members)))
  manifest <- data.frame(
    path = vapply(members, relative, character(1)),
    sha256 = vapply(members, sha256, character(1)),
    bytes = unname(file.info(members)$size),
    stringsAsFactors = FALSE
  )
  stopifnot(length(unique(manifest$path)) == nrow(manifest))
  write.csv(manifest, manifest_path, row.names = FALSE)
  cat(
    toupper(case), "_INDIVIDUAL_SEAL=PASS rows=", nrow(manifest),
    " manifest_sha256=", sha256(manifest_path), "\n",
    sep = ""
  )
}
