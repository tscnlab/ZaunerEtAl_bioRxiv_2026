#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(digest)
  library(jsonlite)
  library(xml2)
})

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("This structural verifier requires R 4.6.1.")
}

args <- commandArgs(trailingOnly = TRUE)
if (!length(args) || !args[[1]] %in% c("source", "html")) {
  stop("Usage: verify_selection_svg_revision.R source|html QMD [HTML]")
}

phase <- args[[1]]
project_root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
owner_root <- file.path(
  project_root,
  "audit/manuscript_nature_health/figure_table_selection_svg_revision_2026_09_11"
)
contract_root <- file.path(owner_root, "contracts")
preimage_qmd <- file.path(
  owner_root,
  "preimages/manuscript_figure_table_selection.qmd"
)
qmd_path <- normalizePath(args[[2]], winslash = "/", mustWork = TRUE)
selection_source_dir <- file.path(
  project_root,
  "audit/manuscript_nature_health"
)
html_path <- if (phase == "html") {
  normalizePath(args[[3]], winslash = "/", mustWork = TRUE)
} else {
  NA_character_
}

sha256_file <- function(path) {
  digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
}

file_bytes <- function(path) {
  as.numeric(file.info(path)$size)
}

count_fixed <- function(text, pattern) {
  if (!nzchar(pattern)) return(0L)
  hits <- gregexpr(pattern, text, fixed = TRUE)[[1]]
  if (identical(hits[[1]], -1L)) 0L else length(hits)
}

replace_once <- function(text, old, new, label) {
  observed <- count_fixed(text, old)
  if (!identical(observed, 1L)) {
    stop(label, " expected one exact preimage but found ", observed, ".")
  }
  sub(old, new, text, fixed = TRUE)
}

extract_attr <- function(tags, attribute) {
  pattern <- paste0(attribute, "=\"([^\"]*)\"")
  out <- sub(paste0(".*", pattern, ".*"), "\\1", tags, perl = TRUE)
  out[!grepl(pattern, tags, perl = TRUE)] <- ""
  out
}

normalize_text <- function(node) {
  trimws(gsub("[[:space:]]+", " ", xml_text(node)))
}

checks <- list()
add_check <- function(check, observed, expected, pass) {
  checks[[length(checks) + 1L]] <<- data.frame(
    check = check,
    observed = paste(observed, collapse = ";"),
    expected = paste(expected, collapse = ";"),
    pass = isTRUE(pass),
    stringsAsFactors = FALSE
  )
}

known_contract_hashes <- c(
  "72e_selection_svg_reconciliation_and_preview.md" =
    "58eec65aae5da801f994c64eb7f874f267a098837c891e2c096640ce5452509f",
  "release_manifest.csv" =
    "32e8c92f740d57267e32c63aa46e509ffc8b0d58d387047999a3d29df808fdf8",
  "figure_reconciliation.csv" =
    "42043f4f7bb308284ce8ac720d94d3008978db778f21f12216213e9a614cc529",
  "retained_table_contract.csv" =
    "9e392e02f824a944588bcfd0b85ec20c2aff9d17c31c198df9b720a9e2ee0e90",
  "approved_insert_caption_blocks.json" =
    "86edb84cfea2c64d67c4228f9f0b77037f20536bbfb3b797b2fdfb15881c76a3",
  "input_and_preservation_pins.csv" =
    "04226607b95164a3cb6da81cde646ec35e3550d9ed4e902e1f5b6e10805bacfb",
  "standalone_render_context.json" =
    "c9f21257526eaf9e12532d9502a4d4fc2b08c96382905a707dfcacf6e56479e6",
  "coordinator_preflight_checks.csv" =
    "ceac837b19df32e8d8ee7f33c4d8c16d7e719003e13b1a76cfe976a3f11cc8ff",
  "combined_accepted_svg_manifest.json" =
    "0e0618520fedb387ef030b685e11597e7332ae46fa7ad9ad76d865c24b1c91b2"
)
contract_paths <- file.path(contract_root, names(known_contract_hashes))
observed_contract_hashes <- vapply(contract_paths, sha256_file, character(1))
add_check(
  "copied_contract_hashes",
  sum(observed_contract_hashes == known_contract_hashes),
  length(known_contract_hashes),
  identical(unname(observed_contract_hashes), unname(known_contract_hashes))
)

release <- read.csv(
  file.path(contract_root, "release_manifest.csv"),
  check.names = FALSE,
  stringsAsFactors = FALSE
)
release_hashes <- vapply(release$path, sha256_file, character(1))
release_sizes <- as.numeric(file.info(release$path)$size)
authorized_transition_paths <- c(
  "audit/manuscript_nature_health/manuscript_figure_table_selection.qmd",
  "audit/manuscript_nature_health/manuscript_figure_table_selection.html"
)
preserved_release <- !release$path %in% authorized_transition_paths
add_check("release_manifest_rows", nrow(release), 63L, nrow(release) == 63L)
add_check(
  "release_manifest_unique",
  anyDuplicated(release$path),
  0L,
  !anyDuplicated(release$path)
)
add_check(
  "release_manifest_preserved_inputs_live_exact",
  sum(
    release_hashes[preserved_release] == release$sha256[preserved_release] &
      release_sizes[preserved_release] == release$bytes[preserved_release]
  ),
  sum(preserved_release),
  identical(
    unname(release_hashes[preserved_release]),
    release$sha256[preserved_release]
  ) && identical(
    unname(release_sizes[preserved_release]),
    as.numeric(release$bytes[preserved_release])
  )
)

figure_contract <- read.csv(
  file.path(contract_root, "figure_reconciliation.csv"),
  check.names = FALSE,
  stringsAsFactors = FALSE,
  na.strings = "NA"
)
table_contract <- read.csv(
  file.path(contract_root, "retained_table_contract.csv"),
  check.names = FALSE,
  stringsAsFactors = FALSE
)
accepted20 <- fromJSON(
  file.path(contract_root, "combined_accepted_svg_manifest.json"),
  simplifyDataFrame = TRUE
)$accepted_figures
insert_blocks <- fromJSON(
  file.path(contract_root, "approved_insert_caption_blocks.json"),
  simplifyVector = FALSE
)

selected_figures <- figure_contract[!is.na(figure_contract$svg_path), , drop = FALSE]
add_check(
  "accepted_figure_contract",
  c(nrow(selected_figures), anyDuplicated(selected_figures$svg_path)),
  c(20L, 0L),
  nrow(selected_figures) == 20L && !anyDuplicated(selected_figures$svg_path)
)
add_check(
  "accepted20_order_matches_reconciliation",
  accepted20$word_label,
  selected_figures$manuscript_display,
  identical(accepted20$word_label, selected_figures$manuscript_display) &&
    identical(accepted20$path, selected_figures$svg_path) &&
    identical(accepted20$sha256, selected_figures$sha256)
)

svg_hashes <- vapply(selected_figures$svg_path, sha256_file, character(1))
svg_documents <- lapply(selected_figures$svg_path, read_xml)
svg_embedded_images <- vapply(
  svg_documents,
  function(document) length(xml_find_all(document, "//*[local-name()='image']")),
  integer(1)
)
svg_native_elements <- vapply(
  svg_documents,
  function(document) {
    length(xml_find_all(
      document,
      paste0(
        "//*[local-name()='path' or local-name()='rect' or local-name()='circle' or ",
        "local-name()='ellipse' or local-name()='line' or local-name()='polyline' or ",
        "local-name()='polygon' or local-name()='text']"
      )
    ))
  },
  integer(1)
)
svg_forbidden_nodes <- vapply(
  svg_documents,
  function(document) {
    length(xml_find_all(
      document,
      "//*[local-name()='script' or local-name()='foreignObject']"
    ))
  },
  integer(1)
)
add_check(
  "accepted_svg_live_exact",
  sum(svg_hashes == selected_figures$sha256),
  20L,
  identical(unname(svg_hashes), selected_figures$sha256)
)
add_check(
  "accepted_svg_not_raster_wrapped",
  c(sum(svg_native_elements > 0L), sum(svg_embedded_images), sum(svg_forbidden_nodes)),
  c(20L, "accepted embedded components allowed", 0L),
  all(svg_native_elements > 0L) && all(svg_forbidden_nodes == 0L)
)

preimage_text <- paste(
  readLines(preimage_qmd, warn = FALSE, encoding = "UTF-8"),
  collapse = "\n"
)
candidate_text <- paste(
  readLines(qmd_path, warn = FALSE, encoding = "UTF-8"),
  collapse = "\n"
)
add_check(
  "qmd_preimage_identity",
  c(sha256_file(preimage_qmd), file_bytes(preimage_qmd)),
  c("1e29b5f4a83343978bbb4bf8e841072d1b941832991e3fa78139517738044676", 48345),
  identical(
    sha256_file(preimage_qmd),
    "1e29b5f4a83343978bbb4bf8e841072d1b941832991e3fa78139517738044676"
  ) && file_bytes(preimage_qmd) == 48345
)

expected_text <- preimage_text
replacement_rows <- which(
  !is.na(figure_contract$current_src) &
    !is.na(figure_contract$proposed_src) &
    figure_contract$current_src != figure_contract$proposed_src
)
for (index in replacement_rows) {
  expected_text <- replace_once(
    expected_text,
    figure_contract$current_src[[index]],
    figure_contract$proposed_src[[index]],
    paste0("figure source ", figure_contract$manuscript_display[[index]])
  )
}

block_by_endpoint <- function(endpoint) {
  matches <- vapply(insert_blocks, function(x) x$endpoint, character(1)) == endpoint
  if (sum(matches) != 1L) stop("Missing unique approved insert block: ", endpoint)
  insert_blocks[[which(matches)]]$html
}

s6_html <- block_by_endpoint("fig-s6")
s6_html <- replace_once(
  s6_html,
  "<img src=",
  "<img class=\"display-image\" src=",
  "S6 selection wrapper"
)
s6_html <- replace_once(
  s6_html,
  "display_assets/brown_participant_state_raincloud.svg",
  selected_figures$proposed_src[selected_figures$manuscript_display ==
    "Supplementary Figure S6"],
  "S6 selection path"
)
s6_block <- paste0(
  "#### Supplementary Figure S6. Anonymous participant recommendation-adherence profiles\n\n",
  s6_html
)
expected_text <- replace_once(
  expected_text,
  "\n### Daily architecture\n",
  paste0("\n", s6_block, "\n\n### Daily architecture\n"),
  "S6 insertion anchor"
)

s12_html <- block_by_endpoint("fig-s12")
s12_html <- replace_once(
  s12_html,
  "<img src=",
  "<img class=\"display-image\" src=",
  "S12 selection wrapper"
)
s12_html <- replace_once(
  s12_html,
  "../../artifacts/10_figures/H06/H06_stage3_site_specific_significance_screen.png",
  selected_figures$proposed_src[selected_figures$manuscript_display ==
    "Supplementary Figure S12"],
  "S12 selection path"
)
s12_block <- paste0(
  "#### Supplementary Figure S12. Site-specific hourly routine associations\n\n",
  s12_html,
  "\n"
)
old_h06_pattern <- paste0(
  "(?s)#### Supplementary Figure S11\\. Complementary H06_daily FDR overview",
  ".*?(?=### Person-level findings)"
)
old_h06_match <- regexpr(old_h06_pattern, expected_text, perl = TRUE)
if (old_h06_match[[1]] < 0L) stop("The exact H06_daily source block was not found.")
old_h06_block <- regmatches(expected_text, old_h06_match)
expected_text <- sub(old_h06_pattern, paste0(s12_block, "\n"), expected_text, perl = TRUE)

line_replacements <- list(
  c(
    "The H01/H07 geographic composite, H03 light-source composite, hourly H06 displays, and H06_daily displays remain in Supplementary Information. H03 must keep study-site and light-source colours distinct. The accepted H04 revision 3 composite uses consistent panel sizes, printed values, and registry-based site colours.",
    "The Brown participant profile, H01/H07 geographic composite, H03 light-source composite, and hourly H06 displays remain in Supplementary Information. H03 must keep study-site and light-source colours distinct. The accepted H04 revision 3 composite uses consistent panel sizes, printed values, and registry-based site colours."
  ),
  c("#### Supplementary Figure S6. H01 support and H07 nonlinear classifications", "#### Supplementary Figure S7. H01 support and H07 nonlinear classifications"),
  c("<details class=\"table-preview\"><summary>Accepted H01 near-eye result table</summary>", "<details class=\"table-preview\"><summary>Supplementary Table S7. Accepted H01 near-eye result table</summary>"),
  c("<details class=\"table-preview\"><summary>Accepted H07 near-eye classification table</summary>", "<details class=\"table-preview\"><summary>Supplementary Table S8. Accepted H07 near-eye classification table</summary>"),
  c("#### Supplementary Figure S7. Light-source category and local-clock pattern of near-eye melanopic EDI", "#### Supplementary Figure S8. Light-source category and local-clock pattern of near-eye melanopic EDI"),
  c("#### Supplementary Figures S8 to S10. Hourly H06", "#### Supplementary Figures S9 to S11. Hourly H06"),
  c("<figcaption><strong>S8.</strong> Stage 3 Figure 3, paired near-eye and complementary chest estimates.</figcaption>", "<figcaption><strong>S9.</strong> Stage 3 Figure 3, paired near-eye and complementary chest estimates.</figcaption>"),
  c("<figcaption><strong>S9.</strong> Stage 3 Figure 5, exploratory Free-versus-Work timing.</figcaption>", "<figcaption><strong>S10.</strong> Stage 3 Figure 5, exploratory Free-versus-Work timing.</figcaption>"),
  c("<figcaption><strong>S10.</strong> Stage 3 Figure 6, exploratory Active-versus-Sedentary timing.</figcaption>", "<figcaption><strong>S11.</strong> Stage 3 Figure 6, exploratory Active-versus-Sedentary timing.</figcaption>"),
  c("<details class=\"table-preview\"><summary>Accepted hourly H06 main table</summary>", "<details class=\"table-preview\"><summary>Supplementary Table S9. Accepted hourly H06 main table</summary>"),
  c("#### Supplementary Table S8. Person-level evidence synthesis", "#### Supplementary Table S10. Person-level evidence synthesis"),
  c("#### Supplementary Figure S12 and Table S9. H05 light-exposure behaviour and awareness", "#### Supplementary Figure S13 and Table S11. H05 light-exposure behaviour and awareness"),
  c("#### Supplementary Figure S13 and Table S10. H08 visual light sensitivity", "#### Supplementary Figure S14 and Table S12. H08 visual light sensitivity"),
  c("#### Supplementary Figure S14 and Table S11. H09 chronotype and timing", "#### Supplementary Figure S15 and Table S13. H09 chronotype and timing"),
  c("#### Supplementary Figure S15 and Table S12. H10 age and biological sex", "#### Supplementary Figure S16 and Table S14. H10 age and biological sex"),
  c("#### Supplementary Figure S16 and Table S13. H11 daily curves and global tests", "#### Supplementary Figure S17 and Table S15. H11 daily curves and global tests"),
  c("| Brown participant raincloud | Encourages a participant-trait interpretation that the accepted analysis does not support |", "| Complementary H06_daily figure and table | Omitted at the author's request; the selected hourly H06 displays remain in Supplementary Information |"),
  c("| Dense H03 and H04 category-only figures | H03 is planned as Supplementary Figure S7 and H04 as main Figure 3; the category-only exports remain repository material |", "| Dense H03 and H04 category-only figures | H03 is planned as Supplementary Figure S8 and H04 as main Figure 3; the category-only exports remain repository material |"),
  c("- Keep hourly H06 and complementary daily H06_daily analyses distinct. Never pool near-eye and complementary chest evidence.", "- Never pool near-eye and complementary chest evidence."),
  c("| Brown cross-window results | Brown owner | Separate Supplementary Table S4 assembled from the accepted four-row source; within-participant claims remain withheld |", "| Brown cross-window results | Brown owner | Separate Supplementary Table S4 assembled from the accepted four-row source; within-participant claims remain withheld |\n| Brown participant raincloud | Brown owner | Accepted anonymous participant-profile SVG integrated as Supplementary Figure S6; interpretation remains window-specific and non-ranking |"),
  c("| H03 Supplementary Figure S7 | H03 | Accepted owner-combined four-panel display integrated with distinct site and light-source palettes |", "| H03 Supplementary Figure S8 | H03 | Accepted owner-combined four-panel display integrated with distinct site and light-source palettes |"),
  c("| H06 Stage 3 Figures 3, 5, and 6 | H06 | Accepted outputs shown in requested order |\n| H06_daily blank table preview | Planning document only | Repaired by removing page-layout classes and adding a contained scroller; scientific table unchanged |\n| H06_daily MDER legend | H06_daily | Owner-sealed three-class legend repair integrated; all six estimable MDER cells use the ordinary not-supported symbol |", "| H06 Supplementary Figures S9 to S12 | H06 | Accepted hourly outputs shown in requested order; the site-specific significance screen has no MDER legend |"),
  c("| Supplementary Figure S6 | Harmonizer display assembly | One owner-sealed H01/H07 composite integrated with uppercase left-side A/B tags; accepted component images remain unchanged |", "| Supplementary Figure S7 | Harmonizer display assembly | One owner-sealed H01/H07 composite integrated with uppercase left-side A/B tags; accepted component images remain unchanged |"),
  c("| Supplementary Figure S14 | Harmonizer display assembly | One owner-sealed H09 composite integrated with uppercase left-side A/B tags; accepted component images remain unchanged |", "| Supplementary Figure S15 | Harmonizer display assembly | One owner-sealed H09 composite integrated with uppercase left-side A/B tags; accepted component images remain unchanged |"),
  c("The static previews were generated by `scripts/report_harmonization/build_manuscript_figure_table_selection.R` under R 4.6.1. The builder checks each accepted source and HTML identity, extracts only selected reader endpoints, removes raw p-value columns or cell text only in the planning copies requested by the author, preserves FDR information, namespaces native `gt` semantics, and records source and artifact identities. It does not execute a hypothesis QMD or calculate a new result.", "The table previews were generated by `scripts/report_harmonization/build_manuscript_figure_table_selection.R` under R 4.6.1. The builder checks each accepted source and HTML identity, extracts only selected reader endpoints, removes raw p-value columns or cell text only in the planning copies requested by the author, preserves FDR information, namespaces native `gt` semantics, and records source and artifact identities. It does not execute a hypothesis QMD or calculate a new result. Figure references and current numbering were reconciled under REPORT-018 Order 72e against the accepted 20-SVG manifest; the historical builder remains provenance for the unchanged table extraction and planning assets."),
  c("- [Selection-asset manifest](figure_table_selection_assets/selection_asset_manifest.csv)", "- [Selection-asset manifest](figure_table_selection_assets/selection_asset_manifest.csv)\n- [Accepted 20-SVG manifest](../report_harmonization/report018_order72d_writer_svg_integration/combined_accepted_svg_manifest.json)"),
  c("This document fixes the selection logic and caption language for review. It does not itself authorize a hypothesis artifact replacement, source edit, render, manuscript edit, or final publication numbering.", "This document records the author-approved display selection and SVG preview. It does not itself authorize a hypothesis artifact replacement, manuscript promotion, or final publication submission.")
)
for (index in seq_along(line_replacements)) {
  expected_text <- replace_once(
    expected_text,
    line_replacements[[index]][[1]],
    line_replacements[[index]][[2]],
    paste0("approved source transition ", index)
  )
}
add_check(
  "source_exact_forward_and_reverse_contract",
  digest(charToRaw(candidate_text), algo = "sha256", serialize = FALSE),
  digest(charToRaw(expected_text), algo = "sha256", serialize = FALSE),
  identical(candidate_text, expected_text)
)

image_matches <- gregexpr("<img\\b[^>]*>", candidate_text, perl = TRUE)[[1]]
image_tags <- if (image_matches[[1]] < 0L) character() else {
  regmatches(candidate_text, list(image_matches))[[1]]
}
image_src <- extract_attr(image_tags, "src")
image_alt <- extract_attr(image_tags, "alt")
add_check(
  "source_selected_figure_order",
  image_src,
  selected_figures$proposed_src,
  identical(image_src, selected_figures$proposed_src)
)
resolved_image_paths <- normalizePath(
  file.path(selection_source_dir, image_src),
  winslash = "/",
  mustWork = TRUE
)
expected_image_paths <- normalizePath(
  selected_figures$svg_path,
  winslash = "/",
  mustWork = TRUE
)
add_check(
  "source_selected_figure_paths",
  resolved_image_paths,
  expected_image_paths,
  identical(resolved_image_paths, expected_image_paths)
)
add_check(
  "source_selected_figure_alt",
  sum(nzchar(image_alt)),
  20L,
  length(image_alt) == 20L && all(nzchar(image_alt))
)
add_check(
  "source_selected_figure_svg_only",
  sum(tolower(tools::file_ext(image_src)) == "svg"),
  20L,
  length(image_src) == 20L && all(tolower(tools::file_ext(image_src)) == "svg")
)

include_matches <- gregexpr(
  "\\{\\{< include ([^ >]+\\.html) >\\}\\}",
  candidate_text,
  perl = TRUE
)[[1]]
include_lines <- regmatches(candidate_text, list(include_matches))[[1]]
include_paths <- sub(
  "\\{\\{< include ([^ >]+\\.html) >\\}\\}",
  "\\1",
  include_lines,
  perl = TRUE
)
resolved_include_paths <- normalizePath(
  file.path(selection_source_dir, include_paths),
  winslash = "/",
  mustWork = TRUE
)
expected_include_paths <- normalizePath(
  table_contract$path,
  winslash = "/",
  mustWork = TRUE
)
add_check(
  "source_retained_table_order",
  resolved_include_paths,
  expected_include_paths,
  identical(resolved_include_paths, expected_include_paths)
)
table_hashes <- vapply(table_contract$path, sha256_file, character(1))
add_check(
  "source_retained_table_hashes",
  sum(table_hashes == table_contract$sha256),
  19L,
  identical(unname(table_hashes), table_contract$sha256)
)

forbidden_source_phrases <- c(
  "../hypotheses/H06_daily/manuscript_selection_supplementary_figure_s12/H06_daily_supplementary_figure_s12.svg",
  "figure_table_selection_assets/tbl-h06-daily-primary-matrix.html",
  "H06_daily displays remain in Supplementary Information",
  "H06_daily blank table preview",
  "H06_daily MDER legend",
  "Brown participant raincloud | Encourages a participant-trait interpretation"
)
forbidden_counts <- vapply(
  forbidden_source_phrases,
  function(pattern) count_fixed(candidate_text, pattern),
  integer(1)
)
add_check(
  "source_stale_selection_absent",
  forbidden_counts,
  rep(0L, length(forbidden_counts)),
  all(forbidden_counts == 0L)
)
add_check(
  "source_no_em_dash",
  count_fixed(candidate_text, "\u2014"),
  0L,
  count_fixed(candidate_text, "\u2014") == 0L
)
add_check(
  "source_execution_disabled",
  c(
    count_fixed(candidate_text, "execute:\n  enabled: false"),
    count_fixed(candidate_text, "embed-resources: true"),
    grepl("```\\{", candidate_text, perl = TRUE),
    grepl("`r[[:space:]]", candidate_text, perl = TRUE)
  ),
  c(1L, 1L, FALSE, FALSE),
  count_fixed(candidate_text, "execute:\n  enabled: false") == 1L &&
    count_fixed(candidate_text, "embed-resources: true") == 1L &&
    !grepl("```\\{", candidate_text, perl = TRUE) &&
    !grepl("`r[[:space:]]", candidate_text, perl = TRUE)
)

expected_groups <- c(
  "Duration", "Dynamics", "Exposure history", "Level", "Spectrum", "Timing"
)
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
table3_document <- read_html(table_contract$path[table_contract$manuscript_display ==
  "Main Table 3"])
table3_node <- xml_find_first(table3_document, "//*[@id='tbl-plan-h01-metric-synthesis-candidate']")
table3_groups <- vapply(
  xml_find_all(table3_node, ".//*[contains(concat(' ', normalize-space(@class), ' '), ' gt_group_heading ')]"),
  normalize_text,
  character(1)
)
table3_metrics <- vapply(
  xml_find_all(
    table3_node,
    paste0(
      ".//tbody/tr[not(.//*[contains(concat(' ', normalize-space(@class), ' '), ",
      "' gt_group_heading ')])]//th[contains(concat(' ', normalize-space(@class), ' '), ",
      "' gt_stub ')]"
    )
  ),
  normalize_text,
  character(1)
)
add_check(
  "source_table3_descriptives_order",
  c(table3_groups, table3_metrics),
  c(expected_groups, expected_metrics),
  identical(table3_groups, expected_groups) && identical(table3_metrics, expected_metrics)
)

if (phase == "html") {
  document <- read_html(html_path)
  selected_nodes <- xml_find_all(
    document,
    paste0(
      "//img[contains(concat(' ', normalize-space(@class), ' '), ' display-image ')] | ",
      "//*[contains(concat(' ', normalize-space(@class), ' '), ' display-grid ')]//img"
    )
  )
  rendered_src <- xml_attr(selected_nodes, "src")
  rendered_alt <- trimws(xml_attr(selected_nodes, "alt"))
  add_check(
    "html_selected_figure_count",
    length(selected_nodes),
    20L,
    length(selected_nodes) == 20L
  )
  add_check(
    "html_selected_figure_alt_order",
    rendered_alt,
    image_alt,
    identical(rendered_alt, image_alt)
  )
  svg_data_prefix <- "data:image/svg+xml;base64,"
  add_check(
    "html_selected_figure_svg_data_urls",
    sum(startsWith(rendered_src, svg_data_prefix)),
    20L,
    length(rendered_src) == 20L && all(startsWith(rendered_src, svg_data_prefix))
  )
  decoded <- lapply(
    rendered_src,
    function(source) base64_dec(sub(svg_data_prefix, "", source, fixed = TRUE))
  )
  decoded_hashes <- vapply(
    decoded,
    digest,
    character(1),
    algo = "sha256",
    serialize = FALSE
  )
  decoded_raster_components <- vapply(
    decoded,
    function(blob) {
      svg <- read_xml(blob)
      length(xml_find_all(svg, "//*[local-name()='image']"))
    },
    integer(1)
  )
  decoded_native_elements <- vapply(
    decoded,
    function(blob) {
      svg <- read_xml(blob)
      length(xml_find_all(
        svg,
        paste0(
          "//*[local-name()='path' or local-name()='rect' or local-name()='circle' or ",
          "local-name()='ellipse' or local-name()='line' or local-name()='polyline' or ",
          "local-name()='polygon' or local-name()='text']"
        )
      ))
    },
    integer(1)
  )
  decoded_privacy <- vapply(
    decoded,
    function(blob) {
      text <- rawToChar(blob)
      any(vapply(
        c("/Users/", "file://", "javascript:", "<script", "<foreignObject"),
        grepl,
        logical(1),
        x = text,
        fixed = TRUE
      ))
    },
    logical(1)
  )
  add_check(
    "html_selected_svg_decoded_bytes_exact",
    sum(decoded_hashes == selected_figures$sha256),
    20L,
    identical(unname(decoded_hashes), selected_figures$sha256)
  )
  add_check(
    "html_selected_svg_not_raster_wrapped_or_private",
    c(
      sum(decoded_native_elements > 0L),
      sum(decoded_raster_components),
      sum(decoded_privacy)
    ),
    c(20L, "accepted embedded components allowed", 0L),
    all(decoded_native_elements > 0L) && !any(decoded_privacy)
  )

  html_tables <- xml_find_all(document, "//table")
  gt_tables <- xml_find_all(
    document,
    "//table[contains(concat(' ', normalize-space(@class), ' '), ' gt_table ')]"
  )
  disclosures <- xml_find_all(document, "//details")
  add_check(
    "html_table_and_disclosure_counts",
    c(length(html_tables), length(gt_tables), length(disclosures)),
    c(22L, 19L, 11L),
    length(html_tables) == 22L && length(gt_tables) == 19L &&
      length(disclosures) == 11L
  )

  document_ids <- xml_attr(xml_find_all(document, "//*[@id]"), "id")
  add_check(
    "html_unique_ids",
    sum(duplicated(document_ids)),
    0L,
    !anyDuplicated(document_ids)
  )
  endpoint_order <- document_ids[document_ids %in% table_contract$endpoint]
  add_check(
    "html_retained_table_endpoint_order",
    endpoint_order,
    table_contract$endpoint,
    identical(endpoint_order, table_contract$endpoint)
  )

  table_rows <- vector("list", nrow(table_contract))
  for (index in seq_len(nrow(table_contract))) {
    endpoint <- table_contract$endpoint[[index]]
    source_document <- read_html(table_contract$path[[index]])
    source_node <- xml_find_first(source_document, paste0("//*[@id='", endpoint, "']"))
    rendered_node <- xml_find_first(document, paste0("//*[@id='", endpoint, "']"))
    source_cells <- vapply(
      xml_find_all(source_node, ".//th|.//td"),
      normalize_text,
      character(1)
    )
    rendered_cells <- vapply(
      xml_find_all(rendered_node, ".//th|.//td"),
      normalize_text,
      character(1)
    )
    table_rows[[index]] <- data.frame(
      manuscript_display = table_contract$manuscript_display[[index]],
      endpoint = endpoint,
      source_cells = length(source_cells),
      rendered_cells = length(rendered_cells),
      cell_text_exact = identical(source_cells, rendered_cells),
      stringsAsFactors = FALSE
    )
  }
  table_rows <- do.call(rbind, table_rows)
  write.csv(
    table_rows,
    file.path(owner_root, "qa/table_endpoint_checks.csv"),
    row.names = FALSE,
    na = ""
  )
  add_check(
    "html_retained_table_cell_text",
    sum(table_rows$cell_text_exact),
    nrow(table_rows),
    all(table_rows$cell_text_exact)
  )

  header_nodes <- xml_find_all(document, "//*[@headers]")
  headers_resolve <- vapply(
    header_nodes,
    function(node) {
      table <- xml_find_first(node, "ancestor::table[1]")
      if (inherits(table, "xml_missing")) return(FALSE)
      tokens <- strsplit(trimws(xml_attr(node, "headers")), "[[:space:]]+")[[1]]
      all(vapply(
        tokens,
        function(token) {
          target <- xml_find_all(table, paste0(".//*[@id='", token, "']"))
          length(target) == 1L && identical(xml_name(target[[1]]), "th")
        },
        logical(1)
      ))
    },
    logical(1)
  )
  add_check(
    "html_table_headers_resolve",
    sum(headers_resolve),
    length(headers_resolve),
    all(headers_resolve)
  )

  all_images <- xml_find_all(document, "//img")
  all_image_alt <- trimws(xml_attr(all_images, "alt"))
  all_image_src <- xml_attr(all_images, "src")
  add_check(
    "html_all_image_alt_nonempty",
    sum(nzchar(all_image_alt)),
    length(all_images),
    all(nzchar(all_image_alt))
  )
  add_check(
    "html_all_images_embedded",
    sum(startsWith(all_image_src, "data:")),
    length(all_images),
    all(startsWith(all_image_src, "data:"))
  )

  problem_nodes <- xml_find_all(
    document,
    paste0(
      "//*[contains(concat(' ', normalize-space(@class), ' '), ' cell-output-error ') or ",
      "contains(concat(' ', normalize-space(@class), ' '), ' error ') or ",
      "contains(concat(' ', normalize-space(@class), ' '), ' warning ')]"
    )
  )
  add_check(
    "html_no_embedded_problem_nodes",
    length(problem_nodes),
    0L,
    length(problem_nodes) == 0L
  )

  hrefs <- unique(xml_attr(xml_find_all(document, "//a[@href]"), "href"))
  anchor_hrefs <- hrefs[startsWith(hrefs, "#")]
  anchors_resolve <- vapply(
    substring(anchor_hrefs, 2L),
    function(id) sum(document_ids == id) == 1L,
    logical(1)
  )
  add_check(
    "html_internal_anchors_resolve",
    sum(anchors_resolve),
    length(anchor_hrefs),
    all(anchors_resolve)
  )
  relative_hrefs <- hrefs[
    !startsWith(hrefs, "#") &
      !grepl("^[A-Za-z][A-Za-z0-9+.-]*:", hrefs)
  ]
  relative_paths <- sub("[?#].*$", "", relative_hrefs)
  relative_resolve <- file.exists(file.path(selection_source_dir, relative_paths))
  add_check(
    "html_canonical_relative_links_resolve",
    sum(relative_resolve),
    length(relative_hrefs),
    all(relative_resolve)
  )

  rendered_text <- normalize_text(document)
  inserted_caption_text <- vapply(
    c("fig-s6", "fig-s12"),
    function(endpoint) {
      fragment <- read_html(block_by_endpoint(endpoint))
      normalize_text(xml_find_first(fragment, "//figcaption"))
    },
    character(1)
  )
  caption_exact <- vapply(
    seq_along(inserted_caption_text),
    function(index) count_fixed(rendered_text, inserted_caption_text[[index]]) == 1L,
    logical(1)
  )
  add_check(
    "html_approved_insert_captions_exact",
    sum(caption_exact),
    2L,
    all(caption_exact)
  )
  stale_html_counts <- vapply(
    forbidden_source_phrases[-1L],
    function(pattern) count_fixed(rendered_text, pattern),
    integer(1)
  )
  add_check(
    "html_stale_selection_absent",
    stale_html_counts,
    rep(0L, length(stale_html_counts)),
    all(stale_html_counts == 0L)
  )
}

checks <- do.call(rbind, checks)
output_path <- file.path(owner_root, "qa", paste0(phase, "_checks.csv"))
write.csv(checks, output_path, row.names = FALSE, na = "")
if (!all(checks$pass)) {
  stop(
    "Selection SVG revision ", phase, " checks failed: ",
    paste(checks$check[!checks$pass], collapse = ", ")
  )
}
cat(
  "SELECTION_SVG_", toupper(phase), "=PASS ",
  "checks=", nrow(checks), " qmd=", sha256_file(qmd_path),
  if (phase == "html") paste0(" html=", sha256_file(html_path)) else "",
  " R=", as.character(getRversion()), "\n",
  sep = ""
)
