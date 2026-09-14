#!/usr/bin/env Rscript

accepted_library <- "/Users/zauner/Library/R/arm64/4.6/library"
.libPaths(unique(c(accepted_library, .libPaths())))

stopifnot(
  getRversion() == "4.6.1",
  requireNamespace("digest", quietly = TRUE),
  requireNamespace("jsonlite", quietly = TRUE)
)

project_root <- normalizePath(".", winslash = "/", mustWork = TRUE)
recovery_rel <- paste0(
  "audit/manuscript_nature_health/",
  "figure_table_selection_svg_revision_2026_09_11/",
  "order72h_scroll_recovery"
)
recovery_root <- file.path(project_root, recovery_rel)

sha256 <- function(path) {
  digest::digest(file = path, algo = "sha256", serialize = FALSE)
}

assert_sha <- function(rel, expected) {
  path <- file.path(project_root, rel)
  stopifnot(file.exists(path), identical(unname(sha256(path)), expected))
  invisible(path)
}

qmd_rel <- "audit/manuscript_nature_health/manuscript_figure_table_selection.qmd"
canonical_rel <- "audit/manuscript_nature_health/manuscript_figure_table_selection.html"
candidate_rel <- file.path(recovery_rel, "rendered/manuscript_figure_table_selection.html")
served_rel <- file.path(recovery_rel, "served/manuscript_figure_table_selection.html")
preimage_rel <- file.path(recovery_rel, "preimages/manuscript_figure_table_selection_before_72h.html")
prior_candidate_rel <- paste0(
  "audit/manuscript_nature_health/",
  "figure_table_selection_svg_revision_2026_09_11/rendered/",
  "manuscript_figure_table_selection.html"
)
verifier_rel <- file.path(recovery_rel, "verify_selection_svg_scroll_recovery.R")
accepted_svg_manifest_rel <- paste0(
  "audit/report_harmonization/",
  "report018_order72d_writer_svg_integration/",
  "combined_accepted_svg_manifest.json"
)
release_manifest_rel <- paste0(
  "audit/report_harmonization/",
  "report018_order72h_mobile_coordination_scroll/",
  "release_manifest.csv"
)

qmd_sha <- "197e571f3aaa2be34747ee742a20018f98d541eed87851250b4f3eda131c72a9"
candidate_sha <- "7055fc384bd845f8b42e3d37901c846060aeef6b8248536dc75240070e7a51e4"
old_canonical_sha <- "82100e0d3990dec39f61e94970e7a434b02cf94a6d25819ede1be4d24f4130a6"
prior_candidate_sha <- "7688f8ea58e0045fca25c6de971e418b7c6c873dc83f75ed34d942fdcb1c36b4"
verifier_sha <- "ae2e8a3a4a43c99dc7e0bccf49b812d26cfd695d775e6da001822dbb97983cd7"
accepted_svg_manifest_sha <- "0e0618520fedb387ef030b685e11597e7332ae46fa7ad9ad76d865c24b1c91b2"
release_manifest_sha <- "8e0ee4567115cdcabd380dccc2a367195fa5d6890f42232dd8e949797e1aac8e"

assert_sha(qmd_rel, qmd_sha)
assert_sha(canonical_rel, candidate_sha)
assert_sha(candidate_rel, candidate_sha)
assert_sha(served_rel, candidate_sha)
assert_sha(preimage_rel, old_canonical_sha)
assert_sha(prior_candidate_rel, prior_candidate_sha)
assert_sha(verifier_rel, verifier_sha)
assert_sha(accepted_svg_manifest_rel, accepted_svg_manifest_sha)
assert_sha(release_manifest_rel, release_manifest_sha)

source_checks <- read.csv(
  file.path(recovery_root, "qa/source_checks.csv"),
  stringsAsFactors = FALSE
)
html_checks <- read.csv(
  file.path(recovery_root, "qa/html_checks.csv"),
  stringsAsFactors = FALSE
)
visual_checks <- read.csv(
  file.path(recovery_root, "qa/visual_qa.csv"),
  stringsAsFactors = FALSE
)
stopifnot(
  nrow(source_checks) == 21L,
  all(source_checks$pass),
  nrow(html_checks) == 43L,
  all(html_checks$pass),
  nrow(visual_checks) == 3L,
  all(visual_checks$visual_result == "PASS"),
  all(!visual_checks$page_horizontal_overflow),
  all(visual_checks$svg_count == 20L),
  all(visual_checks$broken_svg_count == 0L),
  all(visual_checks$table_count == 22L),
  all(visual_checks$open_disclosure_count == 11L),
  all(visual_checks$all_table_cells_within_local_scroll_range),
  all(visual_checks$coordination_cells == 45L),
  all(visual_checks$coordination_focusable)
)

accepted <- jsonlite::fromJSON(
  file.path(project_root, accepted_svg_manifest_rel),
  simplifyDataFrame = TRUE
)$accepted_figures
stopifnot(nrow(accepted) == 20L, sum(accepted$appearances) == 21L)
accepted_live <- vapply(
  accepted$path,
  function(path) sha256(file.path(project_root, path)),
  character(1)
)
stopifnot(identical(unname(accepted_live), unname(accepted$sha256)))

all_paths <- list.files(
  recovery_root,
  recursive = TRUE,
  full.names = TRUE,
  all.files = TRUE,
  no.. = TRUE
)
all_paths <- all_paths[file.info(all_paths)$isdir %in% FALSE]
all_rel <- substring(all_paths, nchar(recovery_root) + 2L)
excluded <- c("completion_manifest.csv", "completion_seal.md")
keep <- !all_rel %in% excluded
all_paths <- all_paths[keep]
all_rel <- all_rel[keep]
ord <- order(all_rel)
all_paths <- all_paths[ord]
all_rel <- all_rel[ord]

completion_manifest <- data.frame(
  path = all_rel,
  sha256 = vapply(all_paths, sha256, character(1)),
  bytes = unname(file.info(all_paths)$size),
  stringsAsFactors = FALSE
)
manifest_path <- file.path(recovery_root, "completion_manifest.csv")
write.csv(completion_manifest, manifest_path, row.names = FALSE, quote = TRUE)
manifest_sha <- sha256(manifest_path)

seal_lines <- c(
  "# Order72h combined completion seal",
  "",
  "Date: 2026-09-11",
  "",
  "Status: PASS, pending independent Coordinator acceptance.",
  "",
  sprintf("R version: %s", as.character(getRversion())),
  sprintf("Completion manifest: `%s`", manifest_sha),
  sprintf("Manifest members: %d unique non-circular files", nrow(completion_manifest)),
  "",
  "## Exact promoted state",
  "",
  sprintf("- QMD: `%s`", qmd_sha),
  sprintf("- Accepted candidate and canonical HTML: `%s`", candidate_sha),
  sprintf("- Preserved prior canonical HTML: `%s`", old_canonical_sha),
  sprintf("- Preserved first SVG candidate: `%s`", prior_candidate_sha),
  sprintf("- Copied verifier: `%s`", verifier_sha),
  sprintf("- Accepted 20-SVG manifest: `%s`", accepted_svg_manifest_sha),
  sprintf("- Order72h central release manifest: `%s`", release_manifest_sha),
  "",
  "## Completed gates",
  "",
  "- Source verifier: 21/21.",
  "- HTML verifier: 43/43.",
  "- Accepted SVG source assets: 20/20 exact, 21 appearances.",
  "- Served viewport QA: PASS at 1440, 708 and 390 CSS pixels.",
  "- Tables: 22/22 visible and fully contained in their reachable local ranges.",
  "- Disclosures: 11/11 opened and reviewed.",
  "- Coordination status: 45/45 cells, focusable, keyboard-scrollable, local scrollbar.",
  "- Page-level horizontal overflow: absent at all three widths.",
  "- Browser tab and loopback server: torn down; port 8765 has no listener.",
  "- Canonical HTML replacement: one byte-exact promotion from the accepted candidate.",
  "",
  "Later Word/cross-display findings are queued under a separate bounded order and were not mixed into this seal."
)
writeLines(seal_lines, file.path(recovery_root, "completion_seal.md"), useBytes = TRUE)

writeLines(sprintf(
  "ORDER72H_COMPLETION=PASS members=%d manifest=%s qmd=%s html=%s R=%s",
  nrow(completion_manifest), manifest_sha, qmd_sha, candidate_sha,
  as.character(getRversion())
))
