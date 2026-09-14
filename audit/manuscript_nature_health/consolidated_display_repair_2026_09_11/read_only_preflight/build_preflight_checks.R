#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE)

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
out_dir <- file.path(
  root,
  "audit/manuscript_nature_health/consolidated_display_repair_2026_09_11/read_only_preflight"
)

if (getRversion() != "4.6.1") {
  stop("Order72i requires R 4.6.1", call. = FALSE)
}
if (!requireNamespace("openssl", quietly = TRUE)) {
  stop("The established openssl package is required for SHA-256", call. = FALSE)
}
if (!requireNamespace("xml2", quietly = TRUE)) {
  stop("The established xml2 package is required for static HTML checks", call. = FALSE)
}
if (!requireNamespace("jsonlite", quietly = TRUE)) {
  stop("The established jsonlite package is required for manifest checks", call. = FALSE)
}

sha256_file <- function(path) {
  con <- file(path, open = "rb")
  on.exit(close(con), add = TRUE)
  as.character(openssl::sha256(con))
}

rec <- function(id, display, role, path, authority_state, vector_state, owner, notes) {
  data.frame(
    id = id,
    display = display,
    role = role,
    path = path,
    authority_state = authority_state,
    vector_state = vector_state,
    owner = owner,
    notes = notes,
    stringsAsFactors = FALSE
  )
}

brown_root <- paste0(
  "/Users/zauner/.codex/worktrees/82ab/ZaunerEtAl_bioRxiv_2026/",
  "audit/analyses/brown_adherence/manuscript_selection/supplementary_figure_s5"
)
brown_day <- file.path(brown_root, "daytime_label_continuation")
brown_tag <- file.path(brown_root, "tag_size_18_continuation")

records <- list(
  rec("O72I-ORDER", "Order72i", "execution authority", "audit/report_harmonization/owner_orders/72i_consolidated_word_display_repair_preflight.md", "sealed execution pin", "not applicable", "Coordinator", "Read-only preflight only"),
  rec("O72H-QMD", "Selection preview", "accepted source", "audit/manuscript_nature_health/manuscript_figure_table_selection.qmd", "Order72h accepted and immutable", "not applicable", "Harmonizer", "Do not edit during Order72i"),
  rec("O72H-HTML", "Selection preview", "accepted browser output", "audit/manuscript_nature_health/manuscript_figure_table_selection.html", "Order72h accepted and immutable", "not applicable", "Harmonizer", "Do not render during Order72i"),
  rec("O72H-ACCEPT", "Selection preview", "independent acceptance", "audit/report_harmonization/report018_order72h_independent_acceptance/independent_acceptance.md", "accepted", "not applicable", "Coordinator", "Acceptance authority"),
  rec("O72H-MANIFEST", "Selection preview", "independent manifest", "audit/report_harmonization/report018_order72h_independent_acceptance/independent_manifest.csv", "accepted", "not applicable", "Coordinator", "Non-circular acceptance seal"),
  rec("O72D-DOCX", "Stopped Word candidate", "stopped candidate", "audit/manuscript_nature_health/revision_2026_09_11/svg_complete_order72d/ZaunerEtAl2026_NatHealth_svg_complete_order72d.docx", "stopped and immutable", "mixed SVG integration", "Writer", "Never overwrite or save"),
  rec("O72D-MANIFEST", "Stopped Word candidate", "stopped manifest", "audit/manuscript_nature_health/revision_2026_09_11/svg_complete_order72d/stopped_manifest.csv", "stopped and immutable", "not applicable", "Writer", "Historical seal"),
  rec("VIS-FOLLOWUP", "Post-seal review", "author follow-up", "audit/manuscript_nature_health/revision_2026_09_11/author_visual_review_followup.md", "current author direction", "not applicable", "Writer", "S5 S7 S15 and table font findings"),
  rec("VIS-S2", "Supplementary Table S2", "author addendum", "audit/manuscript_nature_health/revision_2026_09_11/author_visual_review_s2_addendum.md", "current author direction", "not applicable", "Writer", "One horizontal set and complete distributions"),
  rec("WORD-OBS", "Stopped Word candidate", "native Word observations", "audit/manuscript_nature_health/revision_2026_09_11/native_word_postseal_review/observations.md", "observational, not acceptance", "not applicable", "Writer", "Word 16.112.2, 21 appearances"),
  rec("SVG-MANIFEST", "Current Word SVG mapping", "accepted integration manifest", "audit/report_harmonization/report018_order72d_writer_svg_integration/combined_accepted_svg_manifest.json", "Order72d mapping only", "20 SVG sources, 21 appearances", "Writer", "Must be replaced prospectively after split"),
  rec("CAPTURE", "Word tables and raster placeholders", "capture script", "scripts/manuscript_nature_health/capture_word_tables.mjs", "current implementation source", "figures later replaced by authoritative SVG", "Writer", "S2 split and explicit Arial contract require revision"),
  rec("WORD-PREP", "Word assembly", "assembly script", "scripts/manuscript_nature_health/prepare_word_manuscript.py", "current implementation source", "not applicable", "Writer", "S2 page profile and S7/S15 two-block insertion require revision"),
  rec("SVG-EMBED", "Word SVG integration", "OOXML integration script", "scripts/manuscript_nature_health/embed_accepted_svg_figures.py", "current implementation source", "byte-exact SVG embedding", "Writer", "Manifest and drawing mapping require revision"),
  rec("SUPP-QMD", "Supplementary Information", "manuscript source", "manuscript/R0_NatHealth/supplementary_information_outline.qmd", "current source, no Order72i edit", "SVG references", "Writer", "S7/S15 each currently one image block"),
  rec("MAIN-QMD", "Nature Health manuscript", "manuscript source", "manuscript/R0_NatHealth/ZaunerEtAl2026_NatHealth_phase3_brown.qmd", "provisional concurrent source identity", "SVG references through includes", "Writer", "Rehash after the separately authorized editorial checkpoint"),
  rec("TABLE3", "Main Table 3", "accepted gt fragment", "audit/manuscript_nature_health/figure_table_selection_assets/table3_gt_candidate_revision/tbl-plan-h01-metric-synthesis-candidate.html", "author-approved and Order72h accepted", "embedded distribution rasters retained", "Harmonizer", "Metric order matches Descriptives and must remain pinned"),
  rec("S5-COMPOSITE", "Supplementary Figure S5", "current composite", "audit/manuscript_nature_health/figure_table_selection_assets/brown_supplementary_figure_s5.svg", "historical values; held under BA-017", "SVG wrapper with two nested SVG images", "Brown", "Fails in native Word"),
  rec("S5-A", "Supplementary Figure S5 A", "historical accepted component", file.path(brown_day, "panels/panel_a/panel_a_workday.svg"), "historical component only; held under BA-017", "genuine SVG, no image node", "Brown", "Exact component behind current composite"),
  rec("S5-B", "Supplementary Figure S5 B", "historical accepted component", file.path(brown_day, "panels/panel_b/panel_b_free_work.svg"), "historical component only; held under BA-017", "genuine SVG, no image node", "Brown", "Exact component behind current composite"),
  rec("S5-LAYOUT", "Supplementary Figure S5", "accepted historical layout", file.path(brown_tag, "final/supplementary_figure_s5_layout.csv"), "historical layout only; held under BA-017", "not applicable", "Brown", "Left/right geometry and tag placement"),
  rec("S5-CAPTION", "Supplementary Figure S5", "owner caption draft", file.path(brown_tag, "final/supplementary_figure_s5_caption_alt_text.md"), "historical and authority-conflicted", "not applicable", "Brown/Coordinator", "Sleep wording conflicts with PLACEMENT-006"),
  rec("PLACEMENT", "Sleep-period interpretation", "central decision", "audit/decisions/placement_decision.md", "approved central authority", "not applicable", "Coordinator", "Sleep-period values describe bedside environment, not nominal ocular placement"),
  rec("BA017", "Brown linkage-B reopening", "active scientific dependency", "audit/decisions/brown_adherence_main_linkage_b_stage1_reopening.md", "active and unresolved", "not applicable", "Brown", "Final S5 must use later accepted BA-017 replacement outputs"),
  rec("S7-COMPOSITE", "Supplementary Figure S7", "current composite", "audit/manuscript_nature_health/figure_table_selection_assets/supplementary_figure_s6.svg", "Order72h accepted layout, now superseded prospectively", "SVG wrapper with two embedded PNG images", "Harmonizer", "Author requests two independent blocks"),
  rec("S7-A-SVG", "Supplementary Figure S7 A", "accepted component", "artifacts/10_figures/H01/stage3/H01_stage3_model_support.svg", "accepted current H01 output", "genuine SVG, no image node", "H01", "Reuse byte-exactly"),
  rec("S7-A-PNG", "Supplementary Figure S7 A", "accepted raster comparator", "artifacts/10_figures/H01/stage3/H01_stage3_model_support.png", "accepted current H01 output", "PNG comparator", "H01", "Comparison only"),
  rec("S7-A-SOURCE", "Supplementary Figure S7 A", "frozen plotting source", "artifacts/11_source_data/H01/stage3/H01_stage3_model_support_figure_source.csv", "accepted frozen source", "not applicable", "H01", "No regeneration needed"),
  rec("S7-A-BUILDER", "Supplementary Figure S7 A", "accepted builder reference", "scripts/hypotheses/H01/refresh_h01_stage3_model_support_fdr_label.R", "accepted reference, do not broadly execute", "native SVG export already exists", "H01", "Reference only"),
  rec("S7-B-PNG", "Supplementary Figure S7 B", "accepted component comparator", "artifacts/08_figures/H07/H07_revised_smooth_derivative_pairs_near_eye.png", "accepted current H07 output", "PNG only", "H07", "Needs bounded frozen-source SVG export"),
  rec("S7-B-BUILDER", "Supplementary Figure S7 B", "accepted builder reference", "scripts/hypotheses/H07/build_h07_stage2_paired_smooth_derivative_figures.R", "accepted reference, do not broadly execute", "currently PNG-only", "H07", "Copy plotting expression only"),
  rec("S7-B-CURVES", "Supplementary Figure S7 B", "frozen plotting source", "artifacts/09_tables/H07/H07_main_curve_points.csv", "accepted frozen display rows", "not applicable", "H07", "Read-only"),
  rec("S7-B-DERIV", "Supplementary Figure S7 B", "frozen plotting source", "artifacts/09_tables/H07/H07_revised_derivative_points.csv", "accepted frozen display rows", "not applicable", "H07", "Read-only"),
  rec("S7-B-PLATEAU", "Supplementary Figure S7 B", "frozen plotting source", "artifacts/09_tables/H07/H07_revised_plateau_summary.csv", "accepted frozen display rows", "not applicable", "H07", "Read-only"),
  rec("S7-B-RUG", "Supplementary Figure S7 B", "frozen plotting source", "artifacts/09_tables/H07/H07_revised_derivative_photoperiod_rows.csv", "accepted frozen display rows", "not applicable", "H07", "Read-only"),
  rec("S7-B-SETTINGS", "Supplementary Figure S7 B", "accepted display settings", "artifacts/09_tables/H07/H07_revised_paired_figure_settings.csv", "accepted current settings", "not applicable", "H07", "9 by 18 inches at 270 dpi"),
  rec("S15-COMPOSITE", "Supplementary Figure S15", "current composite", "audit/manuscript_nature_health/figure_table_selection_assets/supplementary_figure_s14.svg", "Order72h accepted layout, now superseded prospectively", "SVG wrapper with two embedded PNG images", "Harmonizer", "Author requests two independent blocks"),
  rec("S15-A-PNG", "Supplementary Figure S15 A", "accepted component comparator", "artifacts/10_figures/H09/H09_primary_effects.png", "accepted current H09 output", "PNG", "H09", "Needs bounded frozen-source SVG export"),
  rec("S15-A-PDF", "Supplementary Figure S15 A", "accepted vector comparator", "artifacts/10_figures/H09/H09_primary_effects.pdf", "accepted current H09 output", "PDF vector reference", "H09", "Do not convert PDF as the final source when a native SVG export is feasible"),
  rec("S15-A-SOURCE", "Supplementary Figure S15 A", "frozen plotting source", "artifacts/11_source_data/H09/H09_primary_effects_data.csv", "accepted frozen display rows", "not applicable", "H09", "Read-only"),
  rec("S15-A-BUILDER", "Supplementary Figure S15 A", "accepted builder reference", "scripts/hypotheses/H09/refresh_h09_order56_figures.R", "accepted reference, do not broadly execute", "PNG and PDF only", "H09", "Extract plot construction only"),
  rec("S15-B-PNG", "Supplementary Figure S15 B", "accepted component comparator", "artifacts/10_figures/H09/H09_observed_timing_patterns.png", "accepted current H09 source-ready output", "PNG", "H09", "Needs bounded frozen-source SVG export"),
  rec("S15-B-PDF", "Supplementary Figure S15 B", "accepted vector comparator", "artifacts/10_figures/H09/H09_observed_timing_patterns.pdf", "accepted current H09 source-ready output", "PDF vector reference", "H09", "Preserve component-internal panels"),
  rec("S15-B-SOURCE", "Supplementary Figure S15 B", "frozen plotting source", "artifacts/11_source_data/H09/H09_observed_timing_patterns_data.csv", "accepted frozen display rows", "not applicable", "H09", "Read-only"),
  rec("S15-B-BUILDER", "Supplementary Figure S15 B", "accepted builder reference", "scripts/hypotheses/H09/build_h09_stage3_observed_figure.R", "accepted reference, do not broadly execute", "PNG and PDF only", "H09", "Extract plot construction only"),
  rec("S2-HTML", "Supplementary Table S2", "accepted semantic table source", "audit/manuscript_nature_health/figure_table_selection_assets/tbl-near-eye-metrics.html", "accepted and immutable input", "HTML with embedded distribution PNGs", "Descriptives/Writer", "Capture layout may change; source bytes and order may not"),
  rec("S2-CLIPPED", "Supplementary Table S2", "confirmed clipped capture", "manuscript/R0_NatHealth/_word_test/table_pngs_v2/supp_table_s2_part_04.png", "rejected derived image", "PNG", "Writer", "Cannot be repaired by Word scaling"),
  rec("TABLE-MANIFEST", "Word tables", "current PNG manifest", "manuscript/R0_NatHealth/_word_test/table_pngs_v2/word_table_png_manifest.json", "current stopped-candidate input", "PNG table captures", "Writer", "S2 has six parts from two horizontal panels"),
  rec("EDITABLE-README", "Editable tables", "format precedent", "manuscript/R0_NatHealth/editable_tables/README.md", "read-only precedent", "not applicable", "Writer", "Table S2 uses one 14-column A3 landscape table"),
  rec("EDITABLE-S2", "Supplementary Table S2", "editable-table precedent", "manuscript/R0_NatHealth/editable_tables/Table_S2.docx", "read-only and out of repair scope", "native Word table", "Writer", "Do not modify"),
  rec("S5-TABLE", "Supplementary Table S5", "accepted HTML capture source", "audit/manuscript_nature_health/figure_table_selection_assets/remaining_gt_candidates/tbl-plan-h02-glasses-variation-shapley-gt-candidate.html", "accepted source", "HTML gt", "Writer", "Explicit Arial capture override required"),
  rec("S6-TABLE", "Supplementary Table S6", "accepted HTML capture source", "audit/manuscript_nature_health/figure_table_selection_assets/remaining_gt_candidates/tbl-plan-h02-chest-variation-shapley-gt-candidate.html", "accepted source", "HTML gt", "Writer", "Explicit Arial capture override required"),
  rec("S10-TABLE", "Supplementary Table S10", "accepted HTML capture source", "manuscript/R0_NatHealth/display_assets/table_s8_person_level_synthesis.html", "accepted source", "HTML gt", "Writer", "Explicit Arial capture override required"),
  rec("EDITABLE-S5", "Supplementary Table S5", "editable-table precedent", "manuscript/R0_NatHealth/editable_tables/Table_S5.docx", "read-only and out of repair scope", "native Word table with Arial", "Writer", "Do not modify"),
  rec("EDITABLE-S6", "Supplementary Table S6", "editable-table precedent", "manuscript/R0_NatHealth/editable_tables/Table_S6.docx", "read-only and out of repair scope", "native Word table with Arial", "Writer", "Do not modify"),
  rec("EDITABLE-S10", "Supplementary Table S10", "editable-table precedent", "manuscript/R0_NatHealth/editable_tables/Table_S10.docx", "read-only and out of repair scope", "native Word table with Arial", "Writer", "Do not modify"),
  rec("S17-SVG", "Supplementary Figure S17", "accepted SVG", "audit/hypotheses/H11/report018_order72_svg_export/candidate/H11_reader_primary_near_eye_curves.svg", "accepted current source", "genuine SVG, no image node", "H11", "Native Word passes; LibreOffice substitutes serif and clips note"),
  rec("S17-PNG", "Supplementary Figure S17", "accepted raster comparator", "artifacts/10_figures/H11/stage3/H11_reader_primary_near_eye_curves.png", "accepted comparator", "PNG", "H11", "Comparison only"),
  rec("S17-PDF", "Supplementary Figure S17", "accepted vector comparator", "artifacts/10_figures/H11/stage3/H11_reader_primary_near_eye_curves.pdf", "accepted comparator", "PDF vector reference", "H11", "Comparison only"),
  rec("S17-BUILDER", "Supplementary Figure S17", "accepted builder reference", "scripts/hypotheses/H11/build_h11_stage3_figures.R", "accepted reference, do not broadly execute", "not applicable", "H11", "Source provenance only"),
  rec("S17-EXPORT", "Supplementary Figure S17", "accepted SVG export script", "audit/hypotheses/H11/report018_order72_svg_export/export_h11_s17_svg.R", "accepted export reference", "native SVG", "H11", "Compatibility candidate may change only font declaration and safe bottom canvas"),
  rec("S12-SVG", "Supplementary Figure S12", "accepted SVG protection pin", "audit/hypotheses/H06/report018_order72_svg_export/candidate/H06_stage3_site_specific_significance_screen.svg", "accepted current source", "genuine SVG", "H06", "Must remain free of the removed MDER legend")
)

inventory <- do.call(rbind, records)
resolve_path <- function(path) {
  if (grepl("^/", path)) path else file.path(root, path)
}
resolved <- vapply(inventory$path, resolve_path, character(1))
inventory$exists <- file.exists(resolved)
inventory$bytes <- ifelse(inventory$exists, file.info(resolved)$size, NA_real_)
inventory$sha256 <- vapply(
  seq_along(resolved),
  function(index) if (inventory$exists[index]) sha256_file(resolved[index]) else NA_character_,
  character(1)
)
inventory <- inventory[c(
  "id", "display", "role", "path", "sha256", "bytes", "exists",
  "authority_state", "vector_state", "owner", "notes"
)]
write.csv(
  inventory,
  file.path(out_dir, "source_authority_inventory.csv"),
  row.names = FALSE,
  na = ""
)

read_text <- function(path) paste(readLines(path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
count_fixed <- function(text, token) {
  positions <- gregexpr(token, text, fixed = TRUE)[[1]]
  if (length(positions) == 1L && positions[[1]] == -1L) 0L else length(positions)
}
check_rows <- list()
add_check <- function(id, expected, observed, pass, notes = "") {
  check_rows[[length(check_rows) + 1L]] <<- data.frame(
    check_id = id,
    expected = as.character(expected),
    observed = as.character(observed),
    status = if (isTRUE(pass)) "PASS" else "FAIL",
    notes = notes,
    stringsAsFactors = FALSE
  )
}

expected_hashes <- c(
  "O72I-ORDER" = "c813c7244989d3878c09d95136162fdfd4e5923621782941586f2136a6dc85f0",
  "O72H-QMD" = "197e571f3aaa2be34747ee742a20018f98d541eed87851250b4f3eda131c72a9",
  "O72H-HTML" = "7055fc384bd845f8b42e3d37901c846060aeef6b8248536dc75240070e7a51e4",
  "O72H-ACCEPT" = "8870898213aaf300f289d81f5317a2a27faa97b1798f2d2922d7cb3cfb531c59",
  "O72H-MANIFEST" = "6ca21403fdaa2f08c069c0381e6ff3fc0a34e3ad5787dff82f4b61b087c24465",
  "O72D-DOCX" = "933249b33defbb2155b0d98da60db980302817537b06671982dc5114ce29eac9",
  "O72D-MANIFEST" = "76bebd6da0ab5985c67b229780d6c8143d82bd8fdb969b1b22d38b4d96d9ecf3",
  "MAIN-QMD" = "c6beb79ca34128c0b69d882c1e3ea332cb88664ce9a3c0883b39d1569db0a0d0",
  "S5-COMPOSITE" = "61e8d4671939659ecf5eca6c6688c03414bb849d15b9d3f59f39c96ca7069cfd",
  "S5-A" = "b3e3be0c603511efb64301ea3a5640acc49410217467f3f6850a848e33281206",
  "S5-B" = "fb75a367f8ce78acda0dfb28c00b73c75a944b81a2c4e6b9fb18292d12c13198",
  "S7-COMPOSITE" = "2dde6fd681f21feecf2acb6d693679bc56f68f809691172bb755e7aac47fa032",
  "S7-A-SVG" = "4ddf972fc4c8082594d13a3b446537ae8a525ca35077e0605967f9c4c0ce519e",
  "S7-B-PNG" = "f19763fe3c14c723ac38846bf735c0465ba2ee18765777a4f7304c677be71113",
  "S15-COMPOSITE" = "e4b1fe228897a7135bd017c7c01f80a796a43819d5c1078008f2a927093508b5",
  "S15-A-PNG" = "8525b9dda4a635efe2d8410e6eeb6a99722c6bc0d225f09abe684a73595dc4dd",
  "S15-A-PDF" = "69275a6a3fbfa7bd0b47efa4f53cb61ccbe3c7a776f146148f58026f4329357f",
  "S15-A-SOURCE" = "3972ae75c9aef8551cc85f50d7a438b35b7a55dca58d81f3630133132a25aaf6",
  "S15-B-PNG" = "a23cb2a9a90a232ae9bf3f94ec7b1c5ac0e3c83933d056c0920ffd59e8e0eb59",
  "S15-B-PDF" = "6912f7b1730219f5ece1d78c69fa96db0497156066fce9c9329039240d6293f3",
  "S15-B-SOURCE" = "34640aba210181b973902e00cd6924f79f6ae76faf01fa3c5b66078e2e2e7cee",
  "S2-HTML" = "6832c791ed3ebcf8895106dafe68c7c5118a12a74e37aacdeb8a84b02d9bfe97",
  "S2-CLIPPED" = "dfae33faff53ee52c9ff894c9788e99bb0f456b9a85cff069ffd676356daa3b8",
  "S17-SVG" = "ee82f8f1ef3f360a584a92712ea1e9e1e48341617d5d0e332743c72c956cdbfe",
  "S12-SVG" = "2b955196ce35eae1c973201a00523e538a6535ac59c8abe240160611a74c8b83"
)
for (id in names(expected_hashes)) {
  observed <- inventory$sha256[match(id, inventory$id)]
  add_check(paste0("hash_", id), expected_hashes[[id]], observed, identical(observed, expected_hashes[[id]]))
}
add_check("all_inventory_inputs_exist", nrow(inventory), sum(inventory$exists), all(inventory$exists))

s5_text <- read_text(resolved[match("S5-COMPOSITE", inventory$id)])
s5a_text <- read_text(resolved[match("S5-A", inventory$id)])
s5b_text <- read_text(resolved[match("S5-B", inventory$id)])
s7_text <- read_text(resolved[match("S7-COMPOSITE", inventory$id)])
s7a_text <- read_text(resolved[match("S7-A-SVG", inventory$id)])
s15_text <- read_text(resolved[match("S15-COMPOSITE", inventory$id)])
s17_text <- read_text(resolved[match("S17-SVG", inventory$id)])
s12_text <- read_text(resolved[match("S12-SVG", inventory$id)])
add_check("s5_current_nested_image_nodes", 2, count_fixed(s5_text, "<image"), count_fixed(s5_text, "<image") == 2L)
add_check("s5_component_a_image_nodes", 0, count_fixed(s5a_text, "<image"), count_fixed(s5a_text, "<image") == 0L)
add_check("s5_component_b_image_nodes", 0, count_fixed(s5b_text, "<image"), count_fixed(s5b_text, "<image") == 0L)
add_check("s7_current_embedded_image_nodes", 2, count_fixed(s7_text, "<image"), count_fixed(s7_text, "<image") == 2L)
add_check("s7_h01_native_image_nodes", 0, count_fixed(s7a_text, "<image"), count_fixed(s7a_text, "<image") == 0L)
add_check("s15_current_embedded_image_nodes", 2, count_fixed(s15_text, "<image"), count_fixed(s15_text, "<image") == 2L)
add_check("s17_native_image_nodes", 0, count_fixed(s17_text, "<image"), count_fixed(s17_text, "<image") == 0L)
add_check("s17_helvetica_declarations_present", "at least 1", count_fixed(s17_text, "font-family: \"Helvetica\""), count_fixed(s17_text, "font-family: \"Helvetica\"") > 0L)
add_check("s17_bottom_note_present", "present", grepl("Intervals are pointwise, not simultaneous", s17_text, fixed = TRUE), grepl("Intervals are pointwise, not simultaneous", s17_text, fixed = TRUE))
add_check("s12_mder_legend_absent", 0, count_fixed(toupper(s12_text), "MDER"), count_fixed(toupper(s12_text), "MDER") == 0L)

table3_doc <- xml2::read_html(resolved[match("TABLE3", inventory$id)])
table3_groups <- trimws(xml2::xml_text(xml2::xml_find_all(table3_doc, "//*[contains(concat(' ', normalize-space(@class), ' '), ' gt_group_heading ')]")))
table3_groups <- table3_groups[nzchar(table3_groups)]
table3_metrics <- trimws(xml2::xml_text(xml2::xml_find_all(table3_doc, "//tbody//th[contains(concat(' ', normalize-space(@class), ' '), ' gt_stub ')]")))
table3_metrics <- table3_metrics[nzchar(table3_metrics) & !table3_metrics %in% table3_groups]
expected_groups <- c("Duration", "Dynamics", "Exposure history", "Level", "Spectrum", "Timing")
expected_metrics <- c(
  "Time above 1,000 lx melEDI",
  "Time above 250 lx melEDI during wake",
  "Time below 10 lx melEDI before sleep",
  "Time below 1 lx melEDI during sleep",
  "Longest period above 250 lx melEDI",
  "Interdaily stability",
  "Intradaily variability",
  "melEDI dose",
  "Mean melEDI",
  "Brightest 10 h geometric mean",
  "Darkest 10 h geometric mean",
  "Melanopic daylight efficacy ratio",
  "Midpoint of the brightest 10 hours",
  "Midpoint of the darkest 10 hours",
  "First light timing above 250 lx melEDI",
  "Last light timing above 250 lx melEDI",
  "Mean timing of exposure above 250 lx melEDI"
)
add_check("table3_group_order", paste(expected_groups, collapse = " | "), paste(table3_groups, collapse = " | "), identical(table3_groups, expected_groups))
add_check("table3_metric_order", paste(expected_metrics, collapse = " | "), paste(table3_metrics, collapse = " | "), identical(table3_metrics, expected_metrics))

s2_doc <- xml2::read_html(resolved[match("S2-HTML", inventory$id)])
s2_table <- xml2::xml_find_first(s2_doc, "//table")
s2_last_header <- xml2::xml_find_all(s2_table, ".//thead/tr[last()]/*[self::th or self::td]")
s2_data_rows <- xml2::xml_find_all(
  s2_table,
  ".//tbody/tr[count(*[self::th or self::td])=14]"
)
s2_images <- xml2::xml_find_all(s2_table, ".//tbody//img")
add_check("s2_source_columns", 14, length(s2_last_header), length(s2_last_header) == 14L)
add_check("s2_source_metric_rows", 17, length(s2_data_rows), length(s2_data_rows) == 17L)
add_check("s2_source_distributions", 17, length(s2_images), length(s2_images) == 17L)

capture_text <- read_text(resolved[match("CAPTURE", inventory$id)])
supp_text <- read_text(resolved[match("SUPP-QMD", inventory$id)])
selection_text <- read_text(resolved[match("O72H-QMD", inventory$id)])
s2_start <- regexpr('key: "supp_table_s2"', capture_text, fixed = TRUE)[[1]]
s3_start <- regexpr('key: "supp_table_s3"', capture_text, fixed = TRUE)[[1]]
s2_segment <- substr(capture_text, s2_start, s3_start - 1L)
s2_column_set_count <- count_fixed(s2_segment, "[0, 1, 2,")
add_check("current_s2_horizontal_column_sets", 2, s2_column_set_count, s2_column_set_count == 2L, "Repair removes horizontal splitting")
add_check("supp_qmd_s7_current_single_image", 1, count_fixed(supp_text, "supplementary_figure_s6.svg"), count_fixed(supp_text, "supplementary_figure_s6.svg") == 1L)
add_check("supp_qmd_s15_current_single_image", 1, count_fixed(supp_text, "supplementary_figure_s14.svg"), count_fixed(supp_text, "supplementary_figure_s14.svg") == 1L)
h06_daily_display_refs <- count_fixed(selection_text, "H06_daily/") +
  count_fixed(selection_text, "H06_daily_")
add_check("selection_h06_daily_display_refs_excluded", 0, h06_daily_display_refs, h06_daily_display_refs == 0L, "The audit prose may name H06_daily only to record its omission")

svg_manifest <- jsonlite::fromJSON(resolved[match("SVG-MANIFEST", inventory$id)], simplifyVector = TRUE)
add_check("current_svg_source_count", 20, nrow(svg_manifest$accepted_figures), nrow(svg_manifest$accepted_figures) == 20L)
add_check("current_svg_appearance_count", 21, sum(svg_manifest$accepted_figures$appearances), sum(svg_manifest$accepted_figures$appearances) == 21L)

component_map <- read.csv(
  file.path(out_dir, "display_component_caption_map.csv"),
  check.names = FALSE
)
change_matrix <- read.csv(
  file.path(out_dir, "proposed_change_matrix.csv"),
  check.names = FALSE
)
add_check("component_map_dimensions", "13 rows x 13 columns", sprintf("%d rows x %d columns", nrow(component_map), ncol(component_map)), nrow(component_map) == 13L && ncol(component_map) == 13L)
add_check("component_map_ids_unique", 13, length(unique(component_map$map_id)), anyDuplicated(component_map$map_id) == 0L)
add_check("change_matrix_dimensions", "17 rows x 12 columns", sprintf("%d rows x %d columns", nrow(change_matrix), ncol(change_matrix)), nrow(change_matrix) == 17L && ncol(change_matrix) == 12L)
add_check("change_matrix_ids_unique", 17, length(unique(change_matrix$change_id)), anyDuplicated(change_matrix$change_id) == 0L)

checks <- do.call(rbind, check_rows)
write.csv(checks, file.path(out_dir, "preflight_checks.csv"), row.names = FALSE)

session_lines <- capture.output(sessionInfo())
writeLines(session_lines, file.path(out_dir, "session_info.txt"), useBytes = TRUE)

if (any(checks$status != "PASS")) {
  failed <- checks$check_id[checks$status != "PASS"]
  stop(paste("Preflight checks failed:", paste(failed, collapse = ", ")), call. = FALSE)
}

message(sprintf("ORDER72I_PREFLIGHT_CHECKS=PASS checks=%d inputs=%d", nrow(checks), nrow(inventory)))
