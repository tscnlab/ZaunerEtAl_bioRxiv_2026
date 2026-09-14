stopifnot(as.character(getRversion()) == "4.6.1")
setwd("/Users/zauner/Documents/Arbeit/12-TUM/MeLiDos/WP2.2.5_Data_Analysis/ZaunerEtAl_bioRxiv_2026")
dest <- "audit/report_harmonization/report018_order72i_consolidated_display_preflight"
owner_root <- "audit/manuscript_nature_health/consolidated_display_repair_2026_09_11/read_only_preflight"
stopifnot(!dir.exists(dest), !dir.exists(owner_root))
sha <- function(p) unname(digest::digest(file = p, algo = "sha256"))
owner_seal <- "audit/manuscript_nature_health/figure_table_selection_svg_revision_2026_09_11/order72h_scroll_recovery/completion_manifest.csv"
native_seal <- "audit/manuscript_nature_health/revision_2026_09_11/native_word_postseal_review/observational_record_manifest.csv"
stopifnot(sha(owner_seal) == "13a469421ff156b6357c26564aed0b088960eecafe388efbad4cc7b2fe6295f2",
  sha(native_seal) == "f2546a0505ba94aacb61d0d2844b624c5c14cac6faf20adf5caac1e3efa64a85")
for (p in c(owner_seal, native_seal)) {
  m <- read.csv(p, stringsAsFactors = FALSE)
  resolved <- if (identical(p, owner_seal)) file.path(dirname(p), m$path) else m$path
  stopifnot(!anyDuplicated(m$path), all(file.exists(resolved)),
    !normalizePath(p) %in% normalizePath(resolved))
  stopifnot(identical(unname(vapply(resolved, sha, character(1))), m$sha256),
    identical(as.numeric(file.info(resolved)$size), as.numeric(m$bytes)))
}
paths <- c("audit/report_harmonization/owner_orders/72i_consolidated_word_display_repair_preflight.md",
  "audit/report_harmonization/report018_order72h_independent_acceptance/independent_acceptance.md",
  "audit/report_harmonization/report018_order72h_independent_acceptance/independent_manifest.csv",
  "audit/manuscript_nature_health/manuscript_figure_table_selection.qmd",
  "audit/manuscript_nature_health/manuscript_figure_table_selection.html", owner_seal, native_seal,
  "audit/manuscript_nature_health/revision_2026_09_11/author_visual_review_followup.md",
  "audit/manuscript_nature_health/revision_2026_09_11/author_visual_review_s2_addendum.md",
  "audit/manuscript_nature_health/revision_2026_09_11/native_word_postseal_review/observations.md",
  "audit/manuscript_nature_health/revision_2026_09_11/native_word_postseal_review/svg_structure.json",
  "audit/manuscript_nature_health/revision_2026_09_11/svg_complete_order72d/ZaunerEtAl2026_NatHealth_svg_complete_order72d.docx",
  "audit/manuscript_nature_health/revision_2026_09_11/svg_complete_order72d/stopped_manifest.csv",
  "audit/report_harmonization/report018_order72d_writer_svg_integration/combined_accepted_svg_manifest.json",
  "scripts/manuscript_nature_health/capture_word_tables.mjs",
  "manuscript/R0_NatHealth/_word_test/table_pngs_v2/word_table_png_manifest.json",
  "audit/decisions/brown_adherence_main_linkage_b_stage1_reopening.md")
stopifnot(!anyDuplicated(paths), all(file.exists(paths)))
dir.create(dest)
manifest <- data.frame(path = paths, sha256 = unname(vapply(paths, sha, character(1))),
  bytes = as.numeric(file.info(paths)$size), stringsAsFactors = FALSE)
write.csv(manifest, file.path(dest, "dispatch_manifest.csv"), row.names = FALSE)
stopifnot(file.copy("/private/tmp/order72h-independent.Hfsk8K/seal_order72i_dispatch.R",
  file.path(dest, "seal_dispatch.R"), overwrite = FALSE))
cat("ORDER72I_DISPATCH_PREFLIGHT=PASS owner72h=35/35 native_observations=28/28 pins=",
 nrow(manifest), "/", nrow(manifest), " order=", sha(paths[1]), " dispatch=",
 sha(file.path(dest, "dispatch_manifest.csv")), "\n", sep = "")
