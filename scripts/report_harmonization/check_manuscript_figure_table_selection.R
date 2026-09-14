suppressPackageStartupMessages({
  library(digest)
  library(xml2)
})

required_r <- "4.6.1"
if (!identical(as.character(getRversion()), required_r)) {
  stop("This structural check must run under R ", required_r, ".")
}

project_root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
setwd(project_root)

qmd_path <- Sys.getenv(
  "NATHEALTH_SELECTION_QMD",
  unset = "audit/manuscript_nature_health/manuscript_figure_table_selection.qmd"
)
html_path <- Sys.getenv(
  "NATHEALTH_SELECTION_HTML",
  unset = "audit/manuscript_nature_health/manuscript_figure_table_selection.html"
)
asset_dir <- "audit/manuscript_nature_health/figure_table_selection_assets"
asset_manifest_path <- file.path(asset_dir, "selection_asset_manifest.csv")
output_inventory_path <- file.path(asset_dir, "accepted_output_inventory.csv")
semantic_summary_path <- file.path(
  asset_dir,
  "table_preview_semantic_summary.csv"
)
semantic_ledger_path <- file.path(
  asset_dir,
  "table_preview_semantic_ledger.csv"
)
qa_dir <- Sys.getenv(
  "NATHEALTH_SELECTION_QA_DIR",
  unset = "audit/manuscript_nature_health/figure_table_selection_qa"
)
dir.create(qa_dir, recursive = TRUE, showWarnings = FALSE)
check_path <- file.path(qa_dir, "structural_checks.csv")

sha256_file <- function(path) {
  if (!file.exists(path) || dir.exists(path)) {
    stop("Expected a regular file: ", path)
  }
  digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
}

file_bytes <- function(path) {
  as.numeric(file.info(path)$size)
}

normalize_text <- function(node) {
  trimws(gsub("[[:space:]]+", " ", xml_text(node)))
}

checks <- list()
add_check <- function(name, observed, expected, pass) {
  checks[[length(checks) + 1L]] <<- data.frame(
    check = name,
    observed = paste(observed, collapse = ";"),
    expected = paste(expected, collapse = ";"),
    pass = isTRUE(pass),
    stringsAsFactors = FALSE
  )
}

qmd_lines <- readLines(qmd_path, warn = FALSE, encoding = "UTF-8")
qmd <- paste(qmd_lines, collapse = "\n")
include_pattern <- "\\{\\{< include ([^ >]+\\.html) >\\}\\}"
include_lines <- grep(include_pattern, qmd_lines, value = TRUE)
selected_fragment_relative <- sub(include_pattern, "\\1", include_lines)
selected_fragment_paths <- file.path(
  dirname(qmd_path),
  selected_fragment_relative
)
if (
  length(selected_fragment_paths) != 20L ||
    anyDuplicated(selected_fragment_paths)
) {
  stop("The selection QMD must contain 20 unique table-fragment includes.")
}
document <- read_html(html_path)

asset_manifest <- read.csv(
  asset_manifest_path,
  check.names = FALSE,
  stringsAsFactors = FALSE
)
add_check(
  "selection_asset_manifest_rows",
  nrow(asset_manifest),
  37L,
  nrow(asset_manifest) == 37L
)
add_check(
  "selection_asset_manifest_unique_paths",
  anyDuplicated(asset_manifest$path),
  0L,
  !anyDuplicated(asset_manifest$path)
)
asset_manifest_exact <- vapply(
  seq_len(nrow(asset_manifest)),
  function(index) {
    path <- asset_manifest$path[[index]]
    file.exists(path) &&
      identical(sha256_file(path), asset_manifest$sha256[[index]]) &&
      identical(file_bytes(path), as.numeric(asset_manifest$bytes[[index]]))
  },
  logical(1)
)
add_check(
  "selection_asset_manifest_live_exact",
  sum(asset_manifest_exact),
  nrow(asset_manifest),
  all(asset_manifest_exact)
)
selected_manifest_paths <- asset_manifest$path[
  asset_manifest$role == "selected_table_fragment"
]
add_check(
  "selected_table_fragment_manifest_exact",
  selected_manifest_paths,
  selected_fragment_paths,
  identical(selected_manifest_paths, selected_fragment_paths)
)

semantic_summary <- read.csv(
  semantic_summary_path,
  check.names = FALSE,
  stringsAsFactors = FALSE
)
semantic_ledger <- read.csv(
  semantic_ledger_path,
  check.names = FALSE,
  stringsAsFactors = FALSE
)
add_check(
  "table_preview_semantic_summary_rows",
  nrow(semantic_summary),
  20L,
  nrow(semantic_summary) == 20L &&
    !anyDuplicated(semantic_summary$preview_endpoint)
)
selected_fragment_endpoints <- vapply(
  selected_fragment_paths,
  function(path) {
    fragment <- read_html(path)
    table <- xml_find_first(
      fragment,
      paste0(
        "//table[contains(concat(' ', normalize-space(@class), ' '), ",
        "' gt_table ')]"
      )
    )
    endpoint <- xml_find_first(
      table,
      "ancestor::*[@id and starts-with(@id,'tbl-')][1]"
    )
    if (inherits(endpoint, "xml_missing")) "" else xml_attr(endpoint, "id")
  },
  character(1)
)
add_check(
  "table_preview_semantic_endpoint_order",
  semantic_summary$preview_endpoint,
  selected_fragment_endpoints,
  identical(
    unname(semantic_summary$preview_endpoint),
    unname(selected_fragment_endpoints)
  )
)
add_check(
  "table_preview_semantic_reverse",
  sum(semantic_summary$pre_sha256 == semantic_summary$reversed_sha256),
  nrow(semantic_summary),
  all(semantic_summary$pre_sha256 == semantic_summary$reversed_sha256)
)
add_check(
  "table_preview_semantic_ledger_rows",
  nrow(semantic_ledger),
  sum(semantic_summary$total_substitutions),
  identical(
    nrow(semantic_ledger),
    as.integer(sum(semantic_summary$total_substitutions))
  )
)
add_check(
  "table_preview_semantic_supported_scope",
  paste(sort(unique(semantic_ledger$attribute)), collapse = ","),
  "headers,id",
  nrow(semantic_ledger) > 0L &&
    identical(sort(unique(semantic_ledger$attribute)), c("headers", "id")) &&
    all(semantic_summary$unsupported_id_references == 0L)
)

inventory <- read.csv(
  output_inventory_path,
  check.names = FALSE,
  stringsAsFactors = FALSE
)
add_check("accepted_output_rows", nrow(inventory), 13L, nrow(inventory) == 13L)
add_check(
  "accepted_output_endpoint_uniqueness",
  sum(c(
    anyDuplicated(inventory$analysis),
    anyDuplicated(inventory$table_id),
    anyDuplicated(inventory$figure_id)
  )),
  0L,
  !anyDuplicated(inventory$analysis) &&
    !anyDuplicated(inventory$table_id) &&
    !anyDuplicated(inventory$figure_id)
)

inventory_exact <- vapply(
  seq_len(nrow(inventory)),
  function(index) {
    row <- inventory[index, , drop = FALSE]
    exact <- c(
      identical(
        sha256_file(row$source_qmd[[1]]),
        row$current_source_qmd_sha256[[1]]
      ),
      identical(sha256_file(row$reader_html[[1]]), row$reader_html_sha256[[1]]),
      identical(
        sha256_file(row$figure_artifact[[1]]),
        row$figure_artifact_sha256[[1]]
      ),
      identical(
        sha256_file(row$table_fragment[[1]]),
        row$table_fragment_sha256[[1]]
      )
    )
    if (nzchar(row$table_continuation_fragment[[1]])) {
      exact <- c(
        exact,
        identical(
          sha256_file(row$table_continuation_fragment[[1]]),
          row$table_continuation_fragment_sha256[[1]]
        )
      )
    }
    all(exact)
  },
  logical(1)
)
add_check(
  "accepted_output_inventory_live_exact",
  sum(inventory_exact),
  nrow(inventory),
  all(inventory_exact)
)
add_check(
  "h09_source_ready_transition_is_explicit",
  inventory$source_identity_status[inventory$analysis == "H09"],
  "Owner-verified H09 source-ready transition",
  sum(inventory$analysis == "H09") == 1L &&
    grepl(
      "Owner-verified H09 source-ready transition",
      inventory$source_identity_status[inventory$analysis == "H09"],
      fixed = TRUE
    )
)

main <- xml_find_first(document, "//main")
direct_sections <- xml_find_all(main, "./section")
expected_sections <- c(
  "author-decisions-and-display-order",
  "main-displays",
  "supplementary-information-display-sequence",
  "items-deliberately-excluded-from-supplementary-information",
  "cross-display-language-and-construction-contract",
  "coordination-status",
  "provenance-and-reproducibility"
)
add_check(
  "direct_main_section_order",
  xml_attr(direct_sections, "id"),
  expected_sections,
  identical(xml_attr(direct_sections, "id"), expected_sections)
)

html_tables <- xml_find_all(document, "//table")
gt_tables <- xml_find_all(
  document,
  "//*[contains(concat(' ', normalize-space(@class), ' '), ' gt_table ')]"
)
planning_tables <- xml_find_all(
  document,
  "//*[contains(concat(' ', normalize-space(@class), ' '), ' planning-data-table ')]"
)
images <- xml_find_all(document, "//img")
display_images <- xml_find_all(
  document,
  paste0(
    "//img[contains(concat(' ', normalize-space(@class), ' '), ",
    "' display-image ')] | ",
    "//*[contains(concat(' ', normalize-space(@class), ' '), ",
    "' display-grid ')]//img"
  )
)
details <- xml_find_all(document, "//details")
add_check(
  "all_table_count",
  length(html_tables),
  23L,
  length(html_tables) == 23L
)
add_check(
  "accepted_gt_table_count",
  length(gt_tables),
  20L,
  length(gt_tables) == 20L
)
add_check(
  "manual_planning_table_count",
  length(planning_tables),
  0L,
  length(planning_tables) == 0L
)
add_check(
  "selected_display_image_count",
  length(display_images),
  19L,
  length(display_images) == 19L
)
add_check(
  "table_disclosure_count",
  length(details),
  12L,
  length(details) == 12L
)

accessible_table_scrollers <- xml_find_all(
  document,
  "//*[@role='region' and @tabindex='0' and .//table]"
)
accessible_scroller_tables <- vapply(
  accessible_table_scrollers,
  function(node) length(xml_find_all(node, ".//table")),
  integer(1)
)
accessible_scroller_classes <- xml_attr(accessible_table_scrollers, "class")
add_check(
  "wide_tables_use_accessible_scrollers",
  c(
    length(accessible_table_scrollers),
    sum(grepl("local-table-scroll", accessible_scroller_classes, fixed = TRUE)),
    sum(grepl("manuscript-gt-scroll", accessible_scroller_classes, fixed = TRUE)),
    sum(grepl("table3-candidate-scroll", accessible_scroller_classes, fixed = TRUE))
  ),
  c(5L, 1L, 3L, 1L),
  length(accessible_table_scrollers) == 5L &&
    identical(accessible_scroller_tables, rep(1L, 5L)) &&
    sum(grepl(
      "local-table-scroll",
      accessible_scroller_classes,
      fixed = TRUE
    )) == 1L &&
    sum(grepl(
      "manuscript-gt-scroll",
      accessible_scroller_classes,
      fixed = TRUE
    )) == 3L &&
    sum(grepl(
      "table3-candidate-scroll",
      accessible_scroller_classes,
      fixed = TRUE
    )) == 1L &&
    all(nzchar(xml_attr(accessible_table_scrollers, "aria-label")))
)

sample_flow <- xml_find_all(
  document,
  "//*[@id='tbl-plan-descriptive-sample-flow']"
)
sample_flow_rows <- if (length(sample_flow) == 1L) {
  xml_find_all(
    sample_flow,
    paste0(
      ".//tbody/tr[not(contains(concat(' ', normalize-space(@class), ' '), ",
      "' gt_group_heading_row '))]"
    )
  )
} else {
  xml_find_all(document, "//*[false()]")
}
sample_flow_counts <- trimws(xml_text(xml_find_all(
  sample_flow_rows,
  "./td[last()]"
)))
expected_sample_flow_counts <- c(
  "191",
  "818",
  "2",
  "141",
  "816",
  "1,175,160",
  "905",
  "3",
  "154",
  "902",
  "1,298,880",
  "112",
  "643"
)
sample_flow_text <- if (length(sample_flow) == 1L) {
  normalize_text(sample_flow)
} else {
  ""
}
add_check(
  "descriptive_sample_flow_complete_counts",
  sample_flow_counts,
  expected_sample_flow_counts,
  length(sample_flow) == 1L &&
    length(sample_flow_rows) == 13L &&
    identical(sample_flow_counts, expected_sample_flow_counts)
)
add_check(
  "descriptive_sample_flow_has_no_not_applicable_cells",
  grepl("not applicable|\\bN/A\\b", sample_flow_text, ignore.case = TRUE),
  FALSE,
  !grepl("not applicable|\\bN/A\\b", sample_flow_text, ignore.case = TRUE)
)

image_alt <- trimws(xml_attr(images, "alt"))
image_src <- xml_attr(images, "src")
add_check(
  "image_alt_text_nonempty",
  sum(nzchar(image_alt)),
  length(images),
  all(nzchar(image_alt))
)
add_check(
  "embedded_image_sources",
  sum(startsWith(image_src, "data:")),
  length(images),
  all(startsWith(image_src, "data:"))
)

ids <- xml_attr(xml_find_all(document, "//*[@id]"), "id")
add_check(
  "document_id_uniqueness",
  sum(duplicated(ids)),
  0L,
  !anyDuplicated(ids)
)

header_nodes <- xml_find_all(document, "//*[@headers]")
header_resolution <- vapply(
  header_nodes,
  function(node) {
    table <- xml_find_first(node, "ancestor::table[1]")
    if (inherits(table, "xml_missing")) {
      return(FALSE)
    }
    tokens <- strsplit(xml_attr(node, "headers"), "[[:space:]]+")[[1]]
    tokens <- tokens[nzchar(tokens)]
    if (!length(tokens)) {
      return(FALSE)
    }
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
header_token_count <- sum(vapply(
  header_nodes,
  function(node) {
    length(strsplit(trimws(xml_attr(node, "headers")), "[[:space:]]+")[[1]])
  },
  integer(1)
))
add_check(
  "headers_resolve_within_table",
  sum(header_resolution),
  length(header_nodes),
  all(header_resolution)
)
add_check(
  "resolved_header_token_count",
  header_token_count,
  ">0",
  header_token_count > 0L
)

hrefs <- unique(xml_attr(xml_find_all(document, "//a[@href]"), "href"))
anchor_hrefs <- hrefs[startsWith(hrefs, "#")]
anchors_resolve <- vapply(
  substring(anchor_hrefs, 2L),
  function(id) sum(ids == id) == 1L,
  logical(1)
)
add_check(
  "document_anchor_links_resolve",
  sum(anchors_resolve),
  length(anchor_hrefs),
  all(anchors_resolve)
)

relative_hrefs <- hrefs[
  !startsWith(hrefs, "#") &
    !grepl("^[A-Za-z][A-Za-z0-9+.-]*:", hrefs)
]
relative_paths <- sub("[?#].*$", "", relative_hrefs)
relative_files <- file.path(dirname(html_path), relative_paths)
relative_resolve <- file.exists(relative_files)
add_check(
  "relative_file_links_resolve",
  sum(relative_resolve),
  length(relative_hrefs),
  all(relative_resolve)
)

problem_nodes <- xml_find_all(
  document,
  paste0(
    "//*[contains(concat(' ', normalize-space(@class), ' '), ",
    "' cell-output-error ') or ",
    "contains(concat(' ', normalize-space(@class), ' '), ' error ') or ",
    "contains(concat(' ', normalize-space(@class), ' '), ' warning ')]"
  )
)
add_check(
  "embedded_problem_nodes",
  length(problem_nodes),
  0L,
  length(problem_nodes) == 0L
)

required_heading_lines <- c(
  "### Figure 1. Study protocol, sites, collection windows, civil photoperiod, and daily near-eye exposure",
  "### Table 1. Participant and site characteristics",
  "### Table 2. Recommendation adherence by Brown et al. recommendation window and day type",
  "### Figure 2. Multiscale daily pattern of near-eye melanopic EDI",
  "### Table 3. Personal light-exposure metrics and their geographic and photoperiod context",
  "### Figure 3. Activity category and local-clock pattern of near-eye melanopic EDI",
  "#### Supplementary Figure S7. Light-source category and local-clock pattern of near-eye melanopic EDI",
  "#### Supplementary Table S8. Person-level evidence synthesis"
)
heading_line_counts <- vapply(
  required_heading_lines,
  function(line) sum(qmd_lines == line),
  integer(1)
)
required_decision_phrases <- c(
  "MDER uses the accepted mean of viable minute-level ratios in both the descriptive summary and the H01 model results.",
  "Supplementary Table S1 restructured from 13 accepted scalar counts; no new count derived",
  "Owner-sealed three-class legend repair integrated; all six estimable MDER cells use the ordinary not-supported symbol",
  "The blank preview in the earlier planning document was a layout-container defect, not a missing or broken scientific table.",
  "Panel tags <strong>A</strong>, <strong>B</strong>, and <strong>C</strong> are bold and positioned at the left side of their panels.",
  "The H01 and H07 panels are embedded in one owner-sealed composite with uppercase left-side A/B tags.",
  "The two H09 panels are embedded in one owner-sealed composite with uppercase left-side A/B tags.",
  "All four primary tests form one FDR-correction set.",
  "Each row identifies the analysis-specific FDR-correction set or decision structure applied to that result."
)
decision_phrase_counts <- vapply(
  required_decision_phrases,
  function(phrase) {
    lengths(regmatches(qmd, gregexpr(phrase, qmd, fixed = TRUE)))
  },
  integer(1)
)
required_asset_tokens <- c(
  "H03_manuscript_supplementary_figure_S7.png",
  "H04_manuscript_figure3_selection_candidate.png",
  "supplementary_figure_s6.svg",
  "supplementary_figure_s14.svg",
  "H10_age_site_significant_associations_selection_candidate.png"
)
asset_token_counts <- vapply(
  required_asset_tokens,
  function(token) {
    lengths(regmatches(qmd, gregexpr(token, qmd, fixed = TRUE)))
  },
  integer(1)
)
author_decision_counts <- c(
  heading_line_counts,
  decision_phrase_counts,
  asset_token_counts
)
add_check(
  "required_author_decisions_exact",
  author_decision_counts,
  rep(1L, length(author_decision_counts)),
  identical(unname(author_decision_counts), rep(1L, length(author_decision_counts)))
)

retired_composite_component_tokens <- c(
  "../../artifacts/10_figures/H01/stage3/H01_stage3_model_support.png",
  "../../artifacts/08_figures/H07/H07_revised_smooth_derivative_pairs_near_eye.png",
  "../../artifacts/10_figures/H09/H09_primary_effects.png",
  "../../artifacts/10_figures/H09/H09_observed_timing_patterns.png"
)
retired_component_counts <- vapply(
  retired_composite_component_tokens,
  function(token) lengths(regmatches(qmd, gregexpr(token, qmd, fixed = TRUE))),
  integer(1)
)
add_check(
  "supplementary_single_composite_contract",
  c(
    author_decision_counts[c("supplementary_figure_s6.svg", "supplementary_figure_s14.svg")],
    retired_component_counts
  ),
  c(1L, 1L, rep(0L, length(retired_component_counts))),
  identical(
    unname(author_decision_counts[c("supplementary_figure_s6.svg", "supplementary_figure_s14.svg")]),
    c(1L, 1L)
  ) && all(retired_component_counts == 0L)
)

s3_desktop_display_block <- paste(
  "#fig-s3 img {",
  "  display: block;",
  "  width: 82%;",
  "  max-width: 44rem;",
  "  margin-inline: auto;",
  "}",
  sep = "\n"
)
s3_mobile_display_block <- paste(
  "@media (max-width: 708px) {",
  "  #fig-s3 img {",
  "    width: 100%;",
  "    max-width: 100%;",
  "  }",
  "}",
  sep = "\n"
)
s3_display_counts <- c(
  markup = lengths(regmatches(qmd, gregexpr(
    '<figure id="fig-s3">', qmd, fixed = TRUE
  ))),
  desktop = lengths(regmatches(qmd, gregexpr(
    s3_desktop_display_block, qmd, fixed = TRUE
  ))),
  mobile = lengths(regmatches(qmd, gregexpr(
    s3_mobile_display_block, qmd, fixed = TRUE
  )))
)
add_check(
  "supplementary_figure_s3_display_contract",
  s3_display_counts,
  rep(1L, length(s3_display_counts)),
  identical(unname(s3_display_counts), rep(1L, length(s3_display_counts)))
)

lowercase_panel_markup <- gregexpr(
  "<(strong|b)>[a-z](?:[–-][a-z])?</(strong|b)>",
  qmd,
  perl = TRUE
)[[1]]
lowercase_panel_text <- gregexpr(
  "\\b[Pp]anels? [a-z](?:[–-][a-z])?\\b",
  qmd,
  perl = TRUE
)[[1]]
add_check(
  "uppercase_panel_reference_contract",
  c(
    sum(lowercase_panel_markup > 0L),
    sum(lowercase_panel_text > 0L)
  ),
  c(0L, 0L),
  all(lowercase_panel_markup < 0L) && all(lowercase_panel_text < 0L)
)

h01_synthesis_nodes <- xml_find_all(
  document,
  "//*[@id='tbl-plan-h01-metric-synthesis-candidate']"
)
h01_synthesis <- if (length(h01_synthesis_nodes) == 1L) {
  h01_synthesis_nodes[[1]]
} else {
  xml_find_first(document, "//*[false()]")
}
h01_synthesis_text <- if (length(h01_synthesis_nodes) == 1L) {
  normalize_text(h01_synthesis)
} else {
  ""
}
h01_density_images <- xml_find_all(
  h01_synthesis,
  ".//img[contains(concat(' ', normalize-space(@class), ' '), ' metric-density-thumb ')]"
)
add_check(
  "h01_synthesis_units_labels_and_density",
  c(
    grepl("Definition/relevance", h01_synthesis_text, fixed = TRUE),
    grepl("klx·h", h01_synthesis_text, fixed = TRUE),
    length(h01_density_images),
    grepl("&lt;img", as.character(h01_synthesis), fixed = TRUE)
  ),
  c(TRUE, TRUE, 17L, FALSE),
  length(h01_synthesis_nodes) == 1L &&
    grepl("Definition/relevance", h01_synthesis_text, fixed = TRUE) &&
    grepl("klx·h", h01_synthesis_text, fixed = TRUE) &&
    length(h01_density_images) == 17L &&
    !grepl("&lt;img", as.character(h01_synthesis), fixed = TRUE)
)

h01_groups <- vapply(
  xml_find_all(
    h01_synthesis,
    ".//*[contains(concat(' ', normalize-space(@class), ' '), ' gt_group_heading ')]"
  ),
  normalize_text,
  character(1)
)
h01_metrics <- vapply(
  xml_find_all(
    h01_synthesis,
    paste0(
      ".//tbody/tr[not(.//*[contains(concat(' ', normalize-space(@class), ' '), ",
      "' gt_group_heading ')])]//th[contains(concat(' ', normalize-space(@class), ' '), ",
      "' gt_stub ')]"
    )
  ),
  normalize_text,
  character(1)
)
expected_h01_groups <- c(
  "Duration",
  "Dynamics",
  "Exposure history",
  "Level",
  "Spectrum",
  "Timing"
)
expected_h01_metrics <- c(
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
add_check(
  "h01_synthesis_matches_descriptive_metric_order",
  c(h01_groups, h01_metrics),
  c(expected_h01_groups, expected_h01_metrics),
  identical(h01_groups, expected_h01_groups) &&
    identical(h01_metrics, expected_h01_metrics)
)

brown_cross_window <- xml_find_first(
  document,
  "//*[@id='tbl-plan-brown-cross-window-associations']"
)
brown_cross_window_text <- normalize_text(brown_cross_window)
add_check(
  "brown_cross_window_interpretation_column",
  c(
    grepl(
      "Interpretation for recommendation adherence",
      brown_cross_window_text,
      fixed = TRUE
    ),
    grepl("Claim status", brown_cross_window_text, fixed = TRUE)
  ),
  c(TRUE, FALSE),
  grepl(
    "Interpretation for recommendation adherence",
    brown_cross_window_text,
    fixed = TRUE
  ) &&
    !grepl("Claim status", brown_cross_window_text, fixed = TRUE)
)

brown_section <- xml_find_first(document, "//*[@id='recommendation-adherence']")
brown_text <- normalize_text(brown_section)
evening_count <- lengths(regmatches(
  brown_text,
  gregexpr("Evening", brown_text, fixed = TRUE)
))
add_check(
  "brown_window_language",
  c(
    grepl("Daytime", brown_text, fixed = TRUE),
    grepl("Pre-sleep", brown_text, fixed = TRUE),
    grepl("Sleep", brown_text, fixed = TRUE),
    evening_count
  ),
  c(TRUE, TRUE, TRUE, 1L),
  grepl("Daytime", brown_text, fixed = TRUE) &&
    grepl("Pre-sleep", brown_text, fixed = TRUE) &&
    grepl("Sleep", brown_text, fixed = TRUE) &&
    evening_count == 1L &&
    grepl(
      "Evening” is replaced by “Pre-sleep” only when",
      brown_text,
      fixed = TRUE
    )
)

raw_p_endpoints <- c(
  "tbl-h05-near-results-a",
  "tbl-h05-near-results-b",
  "tbl-h08-near-eye-results",
  "tbl-h09-near-eye-results",
  "tbl-h10-main-results"
)
raw_p_absent <- vapply(
  raw_p_endpoints,
  function(endpoint) {
    node <- xml_find_first(document, paste0("//*[@id='", endpoint, "']"))
    !inherits(node, "xml_missing") &&
      !grepl("Raw p", normalize_text(node), fixed = TRUE)
  },
  logical(1)
)
add_check(
  "selected_person_tables_omit_raw_p",
  sum(raw_p_absent),
  length(raw_p_absent),
  all(raw_p_absent)
)

h06_daily <- xml_find_first(document, "//*[@id='tbl-h06-daily-primary-matrix']")
h06_daily_classes <- xml_attr(
  xml_find_all(h06_daily, "self::*[@class] | .//*[@class]"),
  "class"
)
add_check(
  "h06_daily_preview_layout_repaired",
  c(
    length(xml_find_all(h06_daily, ".//table")),
    sum(grepl("column-page", h06_daily_classes, fixed = TRUE))
  ),
  c(1L, 0L),
  length(xml_find_all(h06_daily, ".//table")) == 1L &&
    !any(grepl("column-page", h06_daily_classes, fixed = TRUE))
)

add_check(
  "no_em_dash_in_qmd",
  grepl("\u2014", qmd, fixed = TRUE),
  FALSE,
  !grepl("\u2014", qmd, fixed = TRUE)
)

checks <- do.call(rbind, checks)
write.csv(checks, check_path, row.names = FALSE, na = "")

if (!all(checks$pass)) {
  failed <- checks$check[!checks$pass]
  stop("Structural checks failed: ", paste(failed, collapse = ", "))
}

cat(
  "MANUSCRIPT_DISPLAY_SELECTION=PASS",
  paste0("checks=", nrow(checks)),
  paste0("tables=", length(html_tables)),
  paste0("gt=", length(gt_tables)),
  paste0("images=", length(images)),
  paste0("headers=", header_token_count),
  paste0("html=", sha256_file(html_path)),
  paste0("bytes=", file_bytes(html_path)),
  paste0("R=", as.character(getRversion())),
  "\n"
)
