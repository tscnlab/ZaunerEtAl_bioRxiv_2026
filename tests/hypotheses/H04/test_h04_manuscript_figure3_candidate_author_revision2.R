#!/usr/bin/env Rscript

# Verify the second isolated H04 manuscript Figure 3 author revision.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
project_library <- file.path(
  root,
  "renv/library/macos/R-4.6/aarch64-apple-darwin23"
)
.libPaths(c(project_library, .libPaths()))

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop(
    "The H04 Figure 3 revision-2 verifier requires R 4.6.1; found ",
    as.character(getRversion()),
    call. = FALSE
  )
}

required_packages <- c("digest", "png", "readr", "stringr", "tibble", "xml2")
missing_packages <- required_packages[
  !vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
]
if (length(missing_packages) > 0L) {
  stop(
    "Missing synchronized project package(s): ",
    paste(missing_packages, collapse = ", "),
    call. = FALSE
  )
}

candidate_directory <- Sys.getenv("H04_FIGURE3_CANDIDATE_DIR", unset = "")
evidence_directory <- Sys.getenv("H04_FIGURE3_EVIDENCE_DIR", unset = "")
if (!nzchar(candidate_directory) || !dir.exists(candidate_directory)) {
  stop("The revision-2 candidate directory is missing.", call. = FALSE)
}
if (!nzchar(evidence_directory)) {
  stop("The revision-2 evidence directory is not set.", call. = FALSE)
}
candidate_directory <- normalizePath(
  candidate_directory,
  winslash = "/",
  mustWork = TRUE
)
authorized_parent <- file.path(
  root,
  "audit/hypotheses/H04/manuscript_figure3_candidate"
)
expected_evidence_directory <- file.path(
  authorized_parent,
  "author_revision3_other_label_acceptance_2026_09_01"
)
if (
  !identical(
    normalizePath(dirname(evidence_directory), winslash = "/", mustWork = TRUE),
    normalizePath(authorized_parent, winslash = "/", mustWork = TRUE)
  ) ||
    !identical(basename(evidence_directory), basename(expected_evidence_directory))
) {
  stop("The revision-2 evidence path is outside H04 ownership.", call. = FALSE)
}
if (!dir.exists(evidence_directory)) {
  dir.create(evidence_directory, recursive = TRUE, showWarnings = FALSE)
}
evidence_directory <- normalizePath(
  evidence_directory,
  winslash = "/",
  mustWork = TRUE
)
if (length(list.files(evidence_directory, all.files = TRUE, no.. = TRUE)) > 0L) {
  stop("The revision-2 evidence directory must be empty.", call. = FALSE)
}

input_path <- function(path) file.path(root, path)
candidate_path <- function(path) file.path(candidate_directory, path)
sha256 <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE)
}

checks <- list()
record_check <- function(gate, condition, detail) {
  checks[[length(checks) + 1L]] <<- tibble::tibble(
    gate = gate,
    status = if (isTRUE(condition)) "PASS" else "FAIL",
    detail = detail
  )
  invisible(condition)
}

builder_path <- input_path(paste0(
  "scripts/hypotheses/H04/",
  "build_h04_manuscript_figure3_candidate_author_revision2.R"
))
test_path <- input_path(paste0(
  "tests/hypotheses/H04/",
  "test_h04_manuscript_figure3_candidate_author_revision2.R"
))
invisible(parse(builder_path, keep.source = TRUE))
invisible(parse(test_path, keep.source = TRUE))
record_check(
  "revision2_source_parse_and_builder_identity",
  identical(
    sha256(builder_path),
    "d162b72a96d2d76732f7529473b810eaf1276bbedbdac0d80d92e65b7b6d9ce6"
  ),
  "The new builder and verifier parse, and the selected builder is frozen."
)

required_outputs <- c(
  "H04_manuscript_figure3_panel_d_source.csv",
  "H04_manuscript_figure3_category_support.csv",
  "H04_manuscript_figure3_frame_contract.csv",
  "H04_manuscript_figure3_input_identities.csv",
  "H04_manuscript_figure3_temporal_tag_boxes.csv",
  "H04_manuscript_figure3_panel_d.svg",
  "H04_manuscript_figure3_panel_d.png",
  "H04_manuscript_figure3_candidate.svg",
  "H04_manuscript_figure3_candidate.png",
  "H04_manuscript_figure3_candidate_170mm.png",
  "H04_manuscript_figure3_candidate_vector_170mm.png",
  "H04_manuscript_figure3_candidate_caption.txt",
  "H04_manuscript_figure3_candidate_outputs.csv"
)
record_check(
  "candidate_output_scope",
  setequal(list.files(candidate_directory), required_outputs) &&
    all(file.exists(candidate_path(required_outputs))),
  "Exactly the 13 authorized revision-2 candidate products exist."
)

output_manifest <- readr::read_csv(
  candidate_path("H04_manuscript_figure3_candidate_outputs.csv"),
  show_col_types = FALSE
)
record_check(
  "candidate_output_manifest_non_circular",
  nrow(output_manifest) == 12L &&
    !any(
      basename(output_manifest$path) ==
        "H04_manuscript_figure3_candidate_outputs.csv"
    ) &&
    all(dirname(output_manifest$path) == candidate_directory),
  "The 12-row candidate manifest excludes itself and stays in the temp root."
)
record_check(
  "candidate_output_identities",
  all(file.exists(output_manifest$path)) &&
    all(output_manifest$sha256 == vapply(
      output_manifest$path,
      sha256,
      character(1)
    )),
  "Every candidate product has the identity recorded by its manifest."
)

expected_inputs <- tibble::tribble(
  ~path,
  ~sha256,
  "artifacts/10_figures/H04/H04_temporal_near_eye.png",
  "8f048e0716e036413f541054a03c521941b4728f661871223b3e4c238991b3d4",
  "artifacts/10_figures/H04/H04_temporal_near_eye.svg",
  "2a804065daa8550523f90391350ed9ec654f3ad66dbc3d5e410ef408739a7678",
  "artifacts/09_tables/H04/H04_reader_heterogeneity_category_estimands.csv",
  "733086079d21a6bb13ea36a43020c6a0d0204f648797337dff1d6ea4dcd32084",
  "artifacts/09_tables/H04/H04_reader_category_estimands.csv",
  "e27bc81e0c6dd2ff50dd0c6ffa4e95d9c7e9c16e5b20ce45fb4df7d1e89f3652",
  "artifacts/09_tables/H04/H04_site_activity_estimands.csv",
  "f07f54bc288bd660b0e3a107016c7852a64ce72c0f1594df052519062a2c5caf",
  "artifacts/11_source_data/H04/H04_preparation_category_support.csv",
  "58f0ffda98fbc486a5cb720088a5183c57e894488350a1759047876a3cd9174f",
  "config/site_display_registry.csv",
  "3d669d459ecc27d3154bbb5ff5b0d64cb510805d486b45264443228c44a6d809",
  "scripts/hypotheses/H03/build_h03_manuscript_supplementary_figure_s7.R",
  "5e662069c2d6412334d2ace2d9989aca90f329a25171d97601be021edb46c6e4",
  "artifacts/10_figures/H03/H03_manuscript_supplementary_figure_S7.png",
  "ae5174afa8d9b57b5d9a635dfe2320482105d72007882db7513e29380271f52d",
  "artifacts/10_figures/H03/H03_manuscript_supplementary_figure_S7.svg",
  "a510c6bc356bba1ed748d4f0f4a308669b218af36af0b06e0fc18f82014674b3"
)
input_identity_output <- readr::read_csv(
  candidate_path("H04_manuscript_figure3_input_identities.csv"),
  show_col_types = FALSE
)
record_check(
  "frozen_input_identities",
  identical(input_identity_output$path, expected_inputs$path) &&
    identical(input_identity_output$sha256, expected_inputs$sha256) &&
    identical(
      input_identity_output$observed_sha256,
      expected_inputs$sha256
    ) &&
    all(vapply(input_path(expected_inputs$path), sha256, character(1)) ==
      expected_inputs$sha256),
  "All frozen H04, H03, and site-registry display-reference identities are exact."
)

activity_order <- c(
  "At home",
  "Working in the office/from home",
  "Outdoors",
  "On the road with public transport/car",
  "Sleeping",
  "Other/unspecified activity"
)
named_activity_order <- activity_order[seq_len(5L)]
activity_labels <- c(
  "At home" = "At home",
  "Working in the office/from home" = "Office/home working",
  "Outdoors" = "Outdoors",
  "On the road with public transport/car" = "Vehicle/public transport",
  "Sleeping" = "Sleeping",
  "Other/unspecified activity" = "Other"
)

expected_support <- readr::read_csv(
  input_path("artifacts/11_source_data/H04/H04_preparation_category_support.csv"),
  show_col_types = FALSE
)
expected_support <- expected_support[
  expected_support$placement == "Near-eye" &
    expected_support$activity %in% activity_order,
  ,
  drop = FALSE
]
expected_support <- expected_support[
  match(activity_order, expected_support$activity),
  ,
  drop = FALSE
]
candidate_support <- readr::read_csv(
  candidate_path("H04_manuscript_figure3_category_support.csv"),
  show_col_types = FALSE
)
record_check(
  "six_category_support_source",
  identical(as.data.frame(candidate_support), as.data.frame(expected_support)) &&
    identical(as.character(candidate_support$activity), activity_order) &&
    identical(
      as.numeric(candidate_support$participants),
      c(126, 124, 121, 111, 126, 72)
    ) &&
    identical(
      as.numeric(candidate_support$participant_days),
      c(709, 511, 480, 369, 714, 159)
    ) &&
    identical(
      as.numeric(candidate_support$unique_participant_hours),
      c(5105, 3624, 1422, 818, 5906, 391)
    ),
  "All six P, D, and H header supports match the accepted source."
)

frame_contract <- readr::read_csv(
  candidate_path("H04_manuscript_figure3_frame_contract.csv"),
  show_col_types = FALSE
)
expected_frame <- tibble::tibble(
  participants = 126,
  participant_days = 724,
  unique_participant_hours = 16135,
  generated_long_rows = 16875,
  effective_weighted_hours = 16135,
  sites = 9,
  exact_zero_participant_hours = 4746,
  interaction_categories = 5,
  display_categories = 6,
  interaction_site_cells = 45,
  display_site_cells = 54,
  estimable_family_members = 44,
  fdr_labelled_site_deviations = 17,
  other_participants = 72,
  other_participant_days = 159,
  other_participant_hours = 391
)
record_check(
  "exact_frame_contract",
  identical(as.data.frame(frame_contract), as.data.frame(expected_frame)),
  paste(
    "The five-category interaction frame and separate Other-only display",
    "support remain exact."
  )
)

format_p <- function(value) {
  ifelse(value < 0.001, "<0.001", sprintf("%.3f", value))
}

named_estimands <- readr::read_csv(
  input_path(
    "artifacts/09_tables/H04/H04_reader_heterogeneity_category_estimands.csv"
  ),
  show_col_types = FALSE
)
named_estimands <- named_estimands[
  named_estimands$placement == "Near-eye" &
    named_estimands$activity %in% named_activity_order,
  ,
  drop = FALSE
]
named_estimands <- named_estimands[
  match(named_activity_order, named_estimands$activity),
  ,
  drop = FALSE
]
expected_named_overall <- tibble::tibble(
  row_type = "site_average",
  site = "Site-average estimate",
  site_color = NA_character_,
  activity = named_estimands$activity,
  display_activity = unname(activity_labels[named_estimands$activity]),
  estimate = sprintf(
    "%.1f (%.1f–%.1f) lx",
    named_estimands$standardized_mean_lx,
    named_estimands$mean_conf_low_lx,
    named_estimands$mean_conf_high_lx
  ),
  confidence_interval = ifelse(
    named_estimands$activity == "At home",
    "Reference category",
    sprintf(
      "%.3f (%.3f–%.3f)× At home",
      named_estimands$ratio_to_home,
      named_estimands$ratio_conf_low,
      named_estimands$ratio_conf_high
    )
  ),
  fdr_p = ifelse(
    named_estimands$activity == "At home",
    "FDR p (reference)",
    paste("FDR p", format_p(named_estimands$ratio_p_adjusted))
  ),
  estimable = TRUE,
  fdr_label = named_estimands$activity != "At home" &
    named_estimands$ratio_p_adjusted < 0.05,
  model_source = "activity_by_site_interaction"
)

other_estimands <- readr::read_csv(
  input_path("artifacts/09_tables/H04/H04_reader_category_estimands.csv"),
  show_col_types = FALSE
)
other <- other_estimands[
  other_estimands$placement == "Near-eye" &
    other_estimands$activity == "Other/unspecified activity",
  ,
  drop = FALSE
]
expected_other_overall <- tibble::tibble(
  row_type = "site_average",
  site = "Site-average estimate",
  site_color = NA_character_,
  activity = "Other/unspecified activity",
  display_activity = "Other",
  estimate = sprintf(
    "%.1f (%.1f–%.1f) lx",
    other$standardized_mean_lx,
    other$mean_conf_low_lx,
    other$mean_conf_high_lx
  ),
  confidence_interval = sprintf(
    "%.3f (%.3f–%.3f)× At home",
    other$ratio_to_home,
    other$ratio_conf_low,
    other$ratio_conf_high
  ),
  fdr_p = "Display only",
  estimable = TRUE,
  fdr_label = FALSE,
  model_source = "additive_display_only"
)
site_registry <- readr::read_csv(
  input_path("config/site_display_registry.csv"),
  show_col_types = FALSE
)
site_registry <- site_registry[order(site_registry$display_order), , drop = FALSE]
site_order <- as.character(site_registry$display_name)
site_palette <- stats::setNames(
  site_registry$color_hex,
  site_registry$display_name
)
site_estimands <- readr::read_csv(
  input_path("artifacts/09_tables/H04/H04_site_activity_estimands.csv"),
  show_col_types = FALSE
)
site_estimands <- site_estimands[
  site_estimands$placement == "Near-eye" &
    site_estimands$activity %in% activity_order,
  ,
  drop = FALSE
]
site_estimands <- site_estimands[
  order(
    match(site_estimands$site_display_name, site_order),
    match(site_estimands$activity, activity_order)
  ),
  ,
  drop = FALSE
]
expected_site_rows <- tibble::tibble(
  row_type = "site_deviation",
  site = site_estimands$site_display_name,
  site_color = unname(site_palette[site_estimands$site_display_name]),
  activity = site_estimands$activity,
  display_activity = unname(activity_labels[site_estimands$activity]),
  estimate = ifelse(
    site_estimands$reporting_status == "ESTIMABLE",
    sprintf("%.2f×", site_estimands$site_deviation_ratio),
    "Not estimable"
  ),
  confidence_interval = ifelse(
    site_estimands$reporting_status == "ESTIMABLE",
    sprintf(
      "95%% CI %.2f–%.2f",
      site_estimands$site_deviation_conf_low,
      site_estimands$site_deviation_conf_high
    ),
    NA_character_
  ),
  fdr_p = ifelse(
    site_estimands$reporting_status == "ESTIMABLE",
    paste("FDR p", format_p(site_estimands$site_deviation_p_adjusted)),
    NA_character_
  ),
  estimable = site_estimands$reporting_status == "ESTIMABLE",
  fdr_label = site_estimands$reporting_status == "ESTIMABLE" &
    site_estimands$site_deviation_p_adjusted < 0.05,
  model_source = ifelse(
    site_estimands$activity == "Other/unspecified activity",
    "excluded_from_activity_by_site_interaction",
    "activity_by_site_interaction"
  )
)
expected_named_sites <- expected_site_rows[
  expected_site_rows$activity %in% named_activity_order,
  ,
  drop = FALSE
]
expected_panel <- rbind(
  rbind(expected_named_overall, expected_other_overall),
  expected_site_rows
)
candidate_panel <- readr::read_csv(
  candidate_path("H04_manuscript_figure3_panel_d_source.csv"),
  show_col_types = FALSE
)
record_check(
  "panel_d_source_exactness",
  identical(as.data.frame(candidate_panel), as.data.frame(expected_panel)),
  paste(
    "All 60 source rows preserve the 50 accepted named-category rows and add",
    "only one frozen Other summary plus nine explicit non-estimable cells."
  )
)
record_check(
  "interaction_family_preservation",
  nrow(expected_named_sites) == 45L &&
    sum(expected_named_sites$estimable) == 44L &&
    sum(expected_named_sites$fdr_label) == 17L &&
    identical(
      expected_named_sites$site[!expected_named_sites$estimable],
      "San José (CR)"
    ) &&
    identical(
      expected_named_sites$activity[!expected_named_sites$estimable],
      "Outdoors"
    ),
  "The 44-member named interaction family and its 17 FDR labels are unchanged."
)
record_check(
  "other_display_only_source_contract",
  nrow(other) == 1L &&
    other$model_source == "additive_display_only" &&
    other$inferential_role == "DISPLAY_ONLY" &&
    is.na(other$ratio_p_adjusted) &&
    other$participants == 72L &&
    other$participant_days == 159L &&
    other$unique_participant_hours == 391L,
  "Other is the sole frozen additive display-only estimate and has no p-value."
)

panel_d_svg <- xml2::read_xml(
  candidate_path("H04_manuscript_figure3_panel_d.svg")
)
panel_root <- xml2::xml_find_first(panel_d_svg, '//*[@id="panel-d"]')
record_check(
  "panel_d_model_source_flags",
  identical(
    xml2::xml_attr(panel_root, "data-source-model"),
    "activity-by-site interaction model"
  ) &&
    identical(
      xml2::xml_attr(panel_root, "data-other-source-model"),
      "additive_display_only"
    ),
  "The vector exposes the named interaction and Other additive source flags."
)

cell_groups <- xml2::xml_find_all(
  panel_d_svg,
  '//*[contains(concat(" ", normalize-space(@class), " "), " panel-d-cell ")]'
)
cell_metadata <- do.call(
  rbind,
  lapply(cell_groups, function(group) {
    tibble::tibble(
      row_type = xml2::xml_attr(group, "data-row-type"),
      site = xml2::xml_attr(group, "data-site"),
      activity = xml2::xml_attr(group, "data-activity"),
      estimable = identical(xml2::xml_attr(group, "data-estimable"), "true"),
      fdr_label = identical(xml2::xml_attr(group, "data-fdr-label"), "true"),
      model_source = xml2::xml_attr(group, "data-model-source"),
      text = paste(
        xml2::xml_text(xml2::xml_find_all(group, './*[local-name()="text"]')),
        collapse = " | "
      )
    )
  })
)
other_site_metadata <- cell_metadata[
  cell_metadata$row_type == "site_deviation" &
    cell_metadata$activity == "Other/unspecified activity",
  ,
  drop = FALSE
]
record_check(
  "other_site_cells_non_estimable",
  nrow(other_site_metadata) == 9L &&
    !any(other_site_metadata$estimable) &&
    !any(other_site_metadata$fdr_label) &&
    all(other_site_metadata$text == "Not estimable") &&
    all(
      other_site_metadata$model_source ==
        "excluded_from_activity_by_site_interaction"
    ),
  "All nine Other site cells contain only an explicit non-estimable status."
)
record_check(
  "vector_cell_counts",
  nrow(cell_metadata) == 60L &&
    sum(cell_metadata$row_type == "site_average") == 6L &&
    sum(cell_metadata$row_type == "site_deviation") == 54L &&
    sum(
      cell_metadata$row_type == "site_deviation" & cell_metadata$estimable
    ) == 44L &&
    sum(
      cell_metadata$row_type == "site_deviation" & cell_metadata$fdr_label
    ) == 17L,
  "The vector has six summaries, 54 site cells, 44 estimable cells, and 17 labels."
)

other_overall_group <- xml2::xml_find_first(
  panel_d_svg,
  paste0(
    '//*[contains(concat(" ", normalize-space(@class), " "), ',
    '" panel-d-cell ") and @data-row-type="site_average" and ',
    '@data-activity="Other/unspecified activity"]'
  )
)
record_check(
  "other_vector_numeric_tokens",
  isTRUE(all.equal(
    as.numeric(xml2::xml_attr(other_overall_group, "data-mean")),
    other$standardized_mean_lx,
    tolerance = 1e-12
  )) &&
    isTRUE(all.equal(
      as.numeric(xml2::xml_attr(other_overall_group, "data-mean-low")),
      other$mean_conf_low_lx,
      tolerance = 1e-12
    )) &&
    isTRUE(all.equal(
      as.numeric(xml2::xml_attr(other_overall_group, "data-mean-high")),
      other$mean_conf_high_lx,
      tolerance = 1e-12
    )) &&
    isTRUE(all.equal(
      as.numeric(xml2::xml_attr(other_overall_group, "data-ratio")),
      other$ratio_to_home,
      tolerance = 1e-12
    )) &&
    isTRUE(all.equal(
      as.numeric(xml2::xml_attr(other_overall_group, "data-ratio-low")),
      other$ratio_conf_low,
      tolerance = 1e-12
    )) &&
    isTRUE(all.equal(
      as.numeric(xml2::xml_attr(other_overall_group, "data-ratio-high")),
      other$ratio_conf_high,
      tolerance = 1e-12
    )) &&
    identical(
      xml2::xml_attr(other_overall_group, "data-p-text"),
      "Additive display only"
    ),
  "The vector Other summary carries exactly the accepted numeric tokens and no p-value."
)

support_groups <- xml2::xml_find_all(
  panel_d_svg,
  '//*[contains(concat(" ", normalize-space(@class), " "), " category-support ")]'
)
support_text <- vapply(
  support_groups,
  function(group) {
    texts <- xml2::xml_text(
      xml2::xml_find_all(group, './*[local-name()="text"]')
    )
    tail(texts, 1L)
  },
  character(1)
)
expected_support_text <- sprintf(
  "P %d · D %d · H %s",
  expected_support$participants,
  expected_support$participant_days,
  trimws(format(
    expected_support$unique_participant_hours,
    big.mark = ",",
    scientific = FALSE
  ))
)
support_nodes <- xml2::xml_find_all(
  panel_d_svg,
  '//*[contains(concat(" ", normalize-space(@class), " "), " category-support ")]/*[local-name()="text"]'
)
record_check(
  "compact_header_support",
  nrow(expected_support) == 6L &&
    length(support_groups) == 6L &&
    identical(unname(support_text), unname(expected_support_text)) &&
    identical(
      sort(unique(as.numeric(xml2::xml_attr(support_nodes, "y")))),
      c(74, 82, 89, 112)
    ) &&
    !any(stringr::str_detect(support_text, "R |WH |S ")),
  "Every header has one exact P/D/H support line and no R, WH, or S line."
)

all_panel_text <- xml2::xml_text(
  xml2::xml_find_all(panel_d_svg, './/*[local-name()="text"]')
)
header_rect <- xml2::xml_find_first(
  panel_d_svg,
  './/*[local-name()="rect" and @y="60" and @x="68.89"]'
)
site_circles <- xml2::xml_find_all(panel_d_svg, './/*[local-name()="circle"]')
site_registry <- readr::read_csv(
  input_path("config/site_display_registry.csv"),
  show_col_types = FALSE
)
site_registry <- site_registry[order(site_registry$display_order), , drop = FALSE]
record_check(
  "h03_aligned_table_geometry",
  !inherits(header_rect, "xml_missing") &&
    identical(xml2::xml_attr(header_rect, "height"), "66") &&
    length(site_circles) == 9L &&
    all(stringr::str_detect(
      xml2::xml_attr(site_circles, "style"),
      stringr::fixed("stroke: none")
    )) &&
    identical(
      sub(".*fill: (#[0-9A-F]{6});.*", "\\1", xml2::xml_attr(site_circles, "style")),
      site_registry$color_hex
    ) &&
    !any(all_panel_text == "Site"),
  paste(
    "Panel D uses the accepted H04 plot edge, compact 66-point header,",
    "borderless registry-coloured site markers, and no visible Site heading."
  )
)
summary_groups <- xml2::xml_find_all(
  panel_d_svg,
  paste0(
    '//*[contains(concat(" ", normalize-space(@class), " "), ',
    '" panel-d-cell ") and @data-row-type="site_average"]'
  )
)
summary_lines <- lapply(
  summary_groups,
  function(group) xml2::xml_text(
    xml2::xml_find_all(group, './*[local-name()="text"]')
  )
)
record_check(
  "compact_site_average_rows",
  length(summary_lines) == 6L &&
    all(lengths(summary_lines) == 3L) &&
    all(vapply(
      summary_lines,
      function(lines) grepl(" lx (", lines[[1]], fixed = TRUE),
      logical(1)
    )) &&
    all(vapply(
      summary_lines[2:6],
      function(lines) grepl("× home (", lines[[2]], fixed = TRUE),
      logical(1)
    )) &&
    identical(summary_lines[[1]][[2]], "Reference category"),
  paste(
    "Every site-average mean and interval shares one line; ratios and their",
    "intervals share the next line, followed by the FDR or display status."
  )
)

composite_svg <- xml2::read_xml(
  candidate_path("H04_manuscript_figure3_candidate.svg")
)
all_svg_text <- xml2::xml_text(
  xml2::xml_find_all(composite_svg, './/*[local-name()="text"]')
)
upper_tags <- xml2::xml_find_all(
  composite_svg,
  paste0(
    './/*[local-name()="text" and ',
    '(text()="A" or text()="B" or text()="C" or text()="D")]'
  )
)
record_check(
  "uppercase_left_panel_tags",
  identical(xml2::xml_text(upper_tags), c("A", "B", "C", "D")) &&
    identical(xml2::xml_attr(upper_tags, "x"), rep("15.94", 4L)),
  "The four uppercase panel tags remain at the accepted left tag edge."
)

accepted_svg_lines <- readLines(
  input_path("artifacts/10_figures/H04/H04_temporal_near_eye.svg"),
  warn = FALSE,
  encoding = "UTF-8"
)
root_open <- grep("^<svg ", accepted_svg_lines)
root_close <- tail(grep("^</svg>$", accepted_svg_lines), 1L)
expected_temporal <- accepted_svg_lines[(root_open + 1L):(root_close - 1L)]
tag_coordinates <- c("27.29" = "A", "308.04" = "B", "564.24" = "C")
tag_change_count <- 0L
for (coordinate in names(tag_coordinates)) {
  label <- unname(tag_coordinates[[coordinate]])
  match_index <- grep(
    paste0(" y='", coordinate, "'.*>", label, "</text>$"),
    expected_temporal
  )
  if (length(match_index) == 1L) {
    expected_temporal[[match_index]] <- sub(
      "x='1102.64'",
      "x='15.94'",
      expected_temporal[[match_index]]
    )
    expected_temporal[[match_index]] <- sub(
      "text-anchor='end'",
      "text-anchor='start'",
      expected_temporal[[match_index]]
    )
    tag_change_count <- tag_change_count + 1L
  }
}
other_text_coordinates <- c("68.81", "349.68", "606.00")
other_change_count <- 0L
for (coordinate in other_text_coordinates) {
  match_index <- which(
    grepl(paste0("y='", coordinate, "'"), expected_temporal, fixed = TRUE) &
      grepl(">Other/unspecified</text>", expected_temporal, fixed = TRUE)
  )
  if (length(match_index) == 1L) {
    expected_temporal[[match_index]] <- sprintf(
      paste0(
        "<text x='1024.40' y='%s' text-anchor='middle' ",
        "style='font-size: 12.00px; font-weight: bold; ",
        "font-family: \"Arial\";'>Other</text>"
      ),
      coordinate
    )
    other_change_count <- other_change_count + 1L
  }
}
caption_index <- grep(
  "Other/unspecified activity is display-only",
  expected_temporal,
  fixed = TRUE
)
if (length(caption_index) != 1L) {
  stop("Expected exactly one accepted temporal Other caption.", call. = FALSE)
}
expected_temporal[[caption_index]] <- paste0(
  "<text x='15.94' y='820.96' style='font-size: 10.50px; ",
  "font-family: \"Arial\";'>Panel B divides each displayed activity curve ",
  "by the displayed global time-of-day mean; the dashed reference is 1. ",
  "Other is display-only.</text>"
)
axis_index <- grep("Factor relative to global mean", expected_temporal, fixed = TRUE)
if (length(axis_index) != 1L) {
  stop("Expected exactly one accepted panel-B axis title.", call. = FALSE)
}
expected_temporal[[axis_index]] <- paste0(
  "<text transform='translate(25.96,437.76) rotate(-90)' ",
  "text-anchor='middle' style='font-size: 14.00px; ",
  "font-family: \"Arial\";'>Ratio to global mean</text>"
)
candidate_svg_lines <- readLines(
  candidate_path("H04_manuscript_figure3_candidate.svg"),
  warn = FALSE,
  encoding = "UTF-8"
)
begin_marker <- grep("^<!-- BEGIN TEMPORAL PANELS -->$", candidate_svg_lines)
end_marker <- grep("^<!-- END TEMPORAL PANELS -->$", candidate_svg_lines)
candidate_temporal <- candidate_svg_lines[(begin_marker + 2L):(end_marker - 2L)]
record_check(
  "temporal_svg_identity",
  tag_change_count == 3L &&
    other_change_count == 3L &&
    identical(candidate_temporal, expected_temporal),
  paste(
    "Panels A-C are byte-identical to the accepted SVG after exactly the",
    "authorized tag, Other-label, caption, and panel-B axis-title repairs."
  )
)
axis_node <- xml2::xml_find_first(
  composite_svg,
  './/*[local-name()="text" and text()="Ratio to global mean"]'
)
c_tag <- xml2::xml_find_first(
  composite_svg,
  './/*[local-name()="text" and text()="C"]'
)
record_check(
  "panel_b_axis_and_c_tag",
  !inherits(axis_node, "xml_missing") &&
    identical(
      xml2::xml_attr(axis_node, "transform"),
      "translate(25.96,437.76) rotate(-90)"
    ) &&
    !inherits(c_tag, "xml_missing") &&
    identical(xml2::xml_attr(c_tag, "x"), "15.94") &&
    !any(all_svg_text == "Factor relative to global mean"),
  "Panel B uses the shorter unclipped title at the shared axis offset, and C remains a separate left tag."
)

tag_boxes <- readr::read_csv(
  candidate_path("H04_manuscript_figure3_temporal_tag_boxes.csv"),
  show_col_types = FALSE
)
accepted_png <- png::readPNG(
  input_path("artifacts/10_figures/H04/H04_temporal_near_eye.png")
)
candidate_png <- png::readPNG(
  candidate_path("H04_manuscript_figure3_candidate.png")
)
candidate_top <- candidate_png[
  seq_len(dim(accepted_png)[[1]]),
  ,
  ,
  drop = FALSE
]
pixel_difference <- apply(
  abs(accepted_png - candidate_top),
  c(1L, 2L),
  max
)
difference_index <- which(pixel_difference > (1 / 255 + 1e-12))
difference_coordinates <- arrayInd(difference_index, dim(pixel_difference))
colnames(difference_coordinates) <- c("row", "col")
inside_authorized_box <- rep(FALSE, nrow(difference_coordinates))
for (index in seq_len(nrow(tag_boxes))) {
  inside_authorized_box <- inside_authorized_box |
    (difference_coordinates[, "row"] >= tag_boxes$y_start[[index]] &
      difference_coordinates[, "row"] <= tag_boxes$y_end[[index]] &
      difference_coordinates[, "col"] >= tag_boxes$x_start[[index]] &
      difference_coordinates[, "col"] <= tag_boxes$x_end[[index]])
}
each_box_changed <- vapply(
  seq_len(nrow(tag_boxes)),
  function(index) {
    any(
      difference_coordinates[, "row"] >= tag_boxes$y_start[[index]] &
        difference_coordinates[, "row"] <= tag_boxes$y_end[[index]] &
        difference_coordinates[, "col"] >= tag_boxes$x_start[[index]] &
        difference_coordinates[, "col"] <= tag_boxes$x_end[[index]]
    )
  },
  logical(1)
)
record_check(
  "temporal_png_decoded_pixel_identity",
  nrow(difference_coordinates) > 0L &&
    all(inside_authorized_box) &&
    all(each_box_changed),
  paste(
    "Decoded panel A-C pixels differ only inside the authorized repair boxes,",
    "and every authorized box changes."
  )
)

caption <- paste(
  readLines(
    candidate_path("H04_manuscript_figure3_candidate_caption.txt"),
    warn = FALSE
  ),
  collapse = " "
)
reader_text <- paste(caption, paste(all_svg_text, collapse = " "))
required_reader_tokens <- c(
  "activity-by-site interaction model",
  "Site-average estimates",
  "site-specific deviation ratios",
  "additive display-only",
  "Other is the accepted additive display-only estimate",
  "excluded from the interaction model",
  "P 72 · D 159 · H 391",
  "1/k",
  "95% confidence intervals",
  "44-member near-eye family"
)
record_check(
  "reader_language_contract",
  all(vapply(
    required_reader_tokens,
    function(token) stringr::str_detect(reader_text, stringr::fixed(token)),
    logical(1)
  )) &&
    !stringr::str_detect(
      tolower(reader_text),
      stringr::fixed("heterogeneity model")
    ) &&
    !stringr::str_detect(
      tolower(reader_text),
      stringr::fixed("unspecified")
    ) &&
    !stringr::str_detect(reader_text, "H04[-–]") &&
    all(vapply(
      c("**A**", "**B**", "**C**", "**D**"),
      function(token) stringr::str_detect(caption, stringr::fixed(token)),
      logical(1)
    )),
  paste(
    "Reader text uses the approved H03-aligned vocabulary, distinguishes",
    "Other, explains P/D/H and 95% CIs, and exposes no internal H04 label."
  )
)

png_paths <- c(
  candidate_path("H04_manuscript_figure3_candidate.png"),
  candidate_path("H04_manuscript_figure3_candidate_170mm.png"),
  candidate_path("H04_manuscript_figure3_candidate_vector_170mm.png"),
  candidate_path("H04_manuscript_figure3_panel_d.png")
)
png_dimensions <- do.call(
  rbind,
  lapply(png_paths, function(path) dim(png::readPNG(path, native = TRUE)))
)
record_check(
  "candidate_dimensions",
  png_dimensions[1L, 2L] == 4725L &&
    png_dimensions[2L, 2L] == round(170 / 25.4 * 300) &&
    png_dimensions[3L, 2L] == round(170 / 25.4 * 300) &&
    png_dimensions[4L, 2L] == 4725L &&
    all(png_dimensions[, 1L] > 0L),
  "The full and 170 mm raster/vector previews have the intended dimensions."
)

verification <- do.call(rbind, checks)
readr::write_csv(
  verification,
  file.path(
    evidence_directory,
    "h04_manuscript_figure3_revision2_test_results.csv"
  )
)
readr::write_csv(
  input_identity_output,
  file.path(
    evidence_directory,
    "h04_manuscript_figure3_revision2_frozen_input_verification.csv"
  )
)
readr::write_csv(
  frame_contract,
  file.path(
    evidence_directory,
    "h04_manuscript_figure3_revision2_frame_verification.csv"
  )
)
readr::write_csv(
  tibble::tibble(
    metric = c(
      "changed_decoded_pixels",
      "all_changes_inside_tag_boxes",
      "all_authorized_repair_boxes_changed",
      "accepted_temporal_width_px",
      "accepted_temporal_height_px",
      "candidate_width_px",
      "candidate_height_px"
    ),
    value = c(
      nrow(difference_coordinates),
      all(inside_authorized_box),
      all(each_box_changed),
      ncol(accepted_png),
      nrow(accepted_png),
      ncol(candidate_png),
      nrow(candidate_png)
    )
  ),
  file.path(
    evidence_directory,
    "h04_manuscript_figure3_revision2_pixel_verification.csv"
  )
)
writeLines(
  capture.output(sessionInfo()),
  file.path(
    evidence_directory,
    "h04_manuscript_figure3_revision2_session_info.txt"
  ),
  useBytes = TRUE
)

if (any(verification$status != "PASS")) {
  failed <- verification$gate[verification$status != "PASS"]
  stop(
    "H04 manuscript Figure 3 revision-2 verification failed: ",
    paste(failed, collapse = ", "),
    call. = FALSE
  )
}

message(
  "H04 manuscript Figure 3 revision-2 verification passed ",
  nrow(verification),
  "/",
  nrow(verification)
)
