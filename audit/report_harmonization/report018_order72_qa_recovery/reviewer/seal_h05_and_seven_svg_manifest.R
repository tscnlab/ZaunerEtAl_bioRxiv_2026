#!/usr/bin/env Rscript

# Seal H05's independent acceptance, then emit the exact seven-candidate SVG
# identity manifest authorized by REPORT-018 Orders 72b and 72c.

stopifnot(as.character(getRversion()) == "4.6.1")
stopifnot(requireNamespace("digest", quietly = TRUE))

root <- normalizePath(".", mustWork = TRUE)
review_root <- file.path(
  root,
  "audit/report_harmonization/report018_order72_qa_recovery/reviewer"
)
acceptance_root <- file.path(
  root,
  "audit/report_harmonization/report018_order72_svg_acceptance"
)
dir.create(acceptance_root, recursive = TRUE, showWarnings = FALSE)

sha256 <- function(path) digest::digest(file = path, algo = "sha256")
relative <- function(path) sub(paste0("^", root, "/"), "", normalizePath(path, mustWork = TRUE))

verify_manifest <- function(relative_path) {
  path <- file.path(root, relative_path)
  manifest <- read.csv(path, stringsAsFactors = FALSE)
  stopifnot(all(c("path", "sha256", "bytes") %in% names(manifest)))
  stopifnot(length(unique(manifest$path)) == nrow(manifest))
  actual_sha <- vapply(manifest$path, sha256, character(1))
  actual_bytes <- unname(file.info(manifest$path)$size)
  stopifnot(all(actual_sha == manifest$sha256 & actual_bytes == manifest$bytes))
  invisible(manifest)
}

h05_manifest_rel <- paste0(
  "audit/report_harmonization/report018_order72_qa_recovery/reviewer/",
  "h05_independent_acceptance_manifest.csv"
)
h05_manifest_path <- file.path(root, h05_manifest_rel)
stopifnot(!file.exists(h05_manifest_path))
h05_case_dirs <- file.path(
  review_root,
  c("h05", "h05_original", "h05_reader")
)
h05_generated <- unlist(lapply(
  h05_case_dirs,
  function(path) list.files(path, recursive = TRUE, full.names = TRUE)
), use.names = FALSE)
h05_inputs <- c(
  "audit/report_harmonization/owner_orders/72b_consolidated_svg_qa_and_unstarted_h05_export.md",
  "audit/report_harmonization/owner_orders/72c_h05_native_vector_colour_legend_repair.md",
  "audit/report_harmonization/report018_order72_qa_recovery/qa_svg_canvas.R",
  "audit/report_harmonization/report018_order72_qa_recovery/recovery_release_manifest.csv",
  "audit/report_harmonization/report018_order72c_h05_native_legend/release_manifest.csv",
  "audit/report_harmonization/report018_order72_qa_recovery/reviewer/build_h05_visual_proofs.R",
  "audit/report_harmonization/report018_order72_qa_recovery/reviewer/run_h05_independent_svg_audit.R",
  "audit/report_harmonization/report018_order72_qa_recovery/reviewer/h05_release_pin_recheck.csv",
  "audit/report_harmonization/report018_order72_qa_recovery/reviewer/h05_candidate_structure_qa.csv",
  "audit/report_harmonization/report018_order72_qa_recovery/reviewer/h05_candidate_visible_text.csv",
  "audit/report_harmonization/report018_order72_qa_recovery/reviewer/h05_independent_acceptance.md",
  "audit/hypotheses/H05/report018_order72_svg_export/vector_legend_repair/candidate/H05_reader_near_eye_effects.svg",
  "audit/hypotheses/H05/report018_order72_svg_export/vector_legend_repair/owner_manifest.csv",
  "audit/hypotheses/H05/report018_order72_svg_export/vector_legend_repair/order72c_final_manifest.csv",
  "audit/hypotheses/H05/report018_order72_svg_export/vector_legend_repair/legend_only_preservation_checks.csv",
  "artifacts/10_figures/H05/H05_reader_near_eye_effects.png"
)
h05_members <- sort(unique(c(file.path(root, h05_inputs), h05_generated)))
stopifnot(all(file.exists(h05_members)))
h05_manifest <- data.frame(
  path = vapply(h05_members, relative, character(1)),
  sha256 = vapply(h05_members, sha256, character(1)),
  bytes = unname(file.info(h05_members)$size),
  stringsAsFactors = FALSE
)
stopifnot(length(unique(h05_manifest$path)) == nrow(h05_manifest))
write.csv(h05_manifest, h05_manifest_path, row.names = FALSE)
verify_manifest(h05_manifest_rel)

individual_manifest_paths <- c(
  "audit/report_harmonization/report018_order72_qa_recovery/reviewer/h02_independent_acceptance_manifest.csv",
  "audit/report_harmonization/report018_order72_svg_acceptance/h06_independent_acceptance_manifest.csv",
  h05_manifest_rel,
  "audit/report_harmonization/report018_order72_qa_recovery/reviewer/h08_independent_acceptance_manifest.csv",
  "audit/report_harmonization/report018_order72_qa_recovery/reviewer/h10_independent_acceptance_manifest.csv",
  "audit/report_harmonization/report018_order72_qa_recovery/reviewer/h11_independent_acceptance_manifest.csv"
)
invisible(lapply(individual_manifest_paths, verify_manifest))

accepted <- data.frame(
  manuscript_display = c(
    "Main Figure 2",
    "Supplementary Figure S9",
    "Supplementary Figure S12",
    "Supplementary Figure S13",
    "Supplementary Figure S14",
    "Supplementary Figure S16",
    "Supplementary Figure S17"
  ),
  owner = c("H02", "H06", "H06", "H05", "H08", "H10", "H11"),
  candidate_path = c(
    "audit/hypotheses/H02/report018_order72_svg_export/candidate/figure4_exact_layout_replication.svg",
    "audit/hypotheses/H06/report018_order72_svg_export/candidate/H06_paired_placement_effects.svg",
    "audit/hypotheses/H06/report018_order72_svg_export/candidate/H06_stage3_site_specific_significance_screen.svg",
    "audit/hypotheses/H05/report018_order72_svg_export/vector_legend_repair/candidate/H05_reader_near_eye_effects.svg",
    "audit/hypotheses/H08/report018_order72_svg_export/candidate/H08_near_eye_effects.svg",
    "audit/hypotheses/H10/report018_order72_svg_export/candidate/H10_age_site_significant_associations_selection_candidate.svg",
    "audit/hypotheses/H11/report018_order72_svg_export/candidate/H11_reader_primary_near_eye_curves.svg"
  ),
  expected_sha256 = c(
    "2f9493540f12c9c660d213ee619bc726f1e3a0e34ce52c0e59bdf6bd8102a5cd",
    "e9d44034ace69fc82f67079fdabb266827cc06e053f948bd47e90d6ce1a47e14",
    "2b955196ce35eae1c973201a00523e538a6535ac59c8abe240160611a74c8b83",
    "e9d7d60100403aea3ac25282f9be33f981b182a09e74479cd160bdc296ae63b3",
    "f0f77bbd896739941d8ae63bb24ed889528a410a963c2123b07ca3a825f7ddee",
    "1340491390703f642e30b0284bd4e0416a704015bc717dd2a6e56a8073901799",
    "ee82f8f1ef3f360a584a92712ea1e9e1e48341617d5d0e332743c72c956cdbfe"
  ),
  expected_bytes = c(2982460, 7423, 29707, 66573, 12850, 88725, 25379),
  owner_evidence_path = c(
    "audit/hypotheses/H02/report018_order72_svg_export/stopped_artifact_manifest.csv",
    "audit/hypotheses/H06/report018_order72_svg_export/completion_manifest.csv",
    "audit/hypotheses/H06/report018_order72_svg_export/completion_manifest.csv",
    "audit/hypotheses/H05/report018_order72_svg_export/vector_legend_repair/order72c_final_manifest.csv",
    "audit/hypotheses/H08/report018_order72_svg_export/completion_manifest.csv",
    "audit/hypotheses/H10/report018_order72_svg_export/stopped_manifest.csv",
    "audit/hypotheses/H11/report018_order72_svg_export/failure_manifest.csv"
  ),
  independent_acceptance_path = c(
    "audit/report_harmonization/report018_order72_qa_recovery/reviewer/h02_independent_acceptance.md",
    "audit/report_harmonization/report018_order72_svg_acceptance/h06_independent_acceptance.md",
    "audit/report_harmonization/report018_order72_svg_acceptance/h06_independent_acceptance.md",
    "audit/report_harmonization/report018_order72_qa_recovery/reviewer/h05_independent_acceptance.md",
    "audit/report_harmonization/report018_order72_qa_recovery/reviewer/h08_independent_acceptance.md",
    "audit/report_harmonization/report018_order72_qa_recovery/reviewer/h10_independent_acceptance.md",
    "audit/report_harmonization/report018_order72_qa_recovery/reviewer/h11_independent_acceptance.md"
  ),
  independent_manifest_path = c(
    individual_manifest_paths[[1]],
    individual_manifest_paths[[2]],
    individual_manifest_paths[[2]],
    individual_manifest_paths[[3]],
    individual_manifest_paths[[4]],
    individual_manifest_paths[[5]],
    individual_manifest_paths[[6]]
  ),
  stringsAsFactors = FALSE
)
accepted$candidate_sha256 <- vapply(accepted$candidate_path, sha256, character(1))
accepted$bytes <- unname(file.info(accepted$candidate_path)$size)
accepted$owner_evidence_sha256 <- vapply(accepted$owner_evidence_path, sha256, character(1))
accepted$independent_acceptance_sha256 <- vapply(
  accepted$independent_acceptance_path,
  sha256,
  character(1)
)
accepted$independent_manifest_sha256 <- vapply(
  accepted$independent_manifest_path,
  sha256,
  character(1)
)
accepted$status <- ifelse(
  accepted$candidate_sha256 == accepted$expected_sha256 &
    accepted$bytes == accepted$expected_bytes,
  "ACCEPTED_FOR_WRITER_INTEGRATION",
  "FAIL"
)
stopifnot(
  nrow(accepted) == 7L,
  length(unique(accepted$candidate_path)) == 7L,
  length(unique(accepted$manuscript_display)) == 7L,
  all(accepted$status == "ACCEPTED_FOR_WRITER_INTEGRATION")
)

accepted <- accepted[c(
  "manuscript_display", "owner", "candidate_path", "candidate_sha256", "bytes",
  "owner_evidence_path", "owner_evidence_sha256",
  "independent_acceptance_path", "independent_acceptance_sha256",
  "independent_manifest_path", "independent_manifest_sha256", "status"
)]
aggregate_path <- file.path(acceptance_root, "seven_accepted_svg_manifest.csv")
stopifnot(!file.exists(aggregate_path))
write.csv(accepted, aggregate_path, row.names = FALSE)
cat(
  "H05_INDIVIDUAL_SEAL=PASS rows=", nrow(h05_manifest),
  " sha256=", sha256(h05_manifest_path), "\n",
  "SEVEN_ACCEPTED_SVG_MANIFEST=PASS rows=", nrow(accepted),
  " sha256=", sha256(aggregate_path), "\n",
  sep = ""
)
