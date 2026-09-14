#!/usr/bin/env Rscript

# Build the second isolated H04 manuscript Figure 3 author-revision candidate.
# The accepted temporal panels and five-category interaction display are reused
# without scientific recomputation. Other is added only from its
# frozen additive display-only estimand and support records.

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
    "The H04 manuscript Figure 3 revision-2 candidate requires R 4.6.1; found ",
    as.character(getRversion()),
    call. = FALSE
  )
}

required_packages <- c(
  "digest",
  "magick",
  "png",
  "readr",
  "stringr",
  "tibble",
  "xml2"
)
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

output_directory <- Sys.getenv("H04_FIGURE3_CANDIDATE_DIR", unset = "")
if (!nzchar(output_directory) || !dir.exists(output_directory)) {
  stop(
    "Set `H04_FIGURE3_CANDIDATE_DIR` to one fresh existing directory.",
    call. = FALSE
  )
}
output_directory <- normalizePath(
  output_directory,
  winslash = "/",
  mustWork = TRUE
)
if (length(list.files(output_directory, all.files = TRUE, no.. = TRUE)) > 0L) {
  stop("The candidate output directory must be empty.", call. = FALSE)
}

input_path <- function(path) file.path(root, path)
sha256 <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE)
}

supplemental_inputs <- tibble::tribble(
  ~path,
  ~sha256,
  "artifacts/10_figures/H04/H04_temporal_near_eye.png",
  "8f048e0716e036413f541054a03c521941b4728f661871223b3e4c238991b3d4",
  "artifacts/10_figures/H04/H04_temporal_near_eye.svg",
  "2a804065daa8550523f90391350ed9ec654f3ad66dbc3d5e410ef408739a7678",
  paste0(
    "artifacts/09_tables/H04/",
    "H04_reader_heterogeneity_category_estimands.csv"
  ),
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
supplemental_inputs$absolute_path <- input_path(supplemental_inputs$path)
missing_inputs <- supplemental_inputs$path[
  !file.exists(supplemental_inputs$absolute_path)
]
if (length(missing_inputs) > 0L) {
  stop(
    "Missing frozen revision-2 input(s): ",
    paste(missing_inputs, collapse = ", "),
    call. = FALSE
  )
}
supplemental_inputs$observed_sha256 <- vapply(
  supplemental_inputs$absolute_path,
  sha256,
  character(1)
)
if (!all(supplemental_inputs$sha256 == supplemental_inputs$observed_sha256)) {
  failed <- supplemental_inputs$path[
    supplemental_inputs$sha256 != supplemental_inputs$observed_sha256
  ]
  stop(
    "Frozen H04 revision-2 input identity drift: ",
    paste(failed, collapse = ", "),
    call. = FALSE
  )
}

input_identities <- supplemental_inputs[c(
  "path",
  "sha256",
  "observed_sha256"
)]
if (
  anyDuplicated(input_identities$path) ||
    !all(input_identities$sha256 == input_identities$observed_sha256)
) {
  stop("The combined frozen-input registry is invalid.", call. = FALSE)
}

format_p <- function(value) {
  ifelse(value < 0.001, "<0.001", sprintf("%.3f", value))
}

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

category_support <- readr::read_csv(
  input_path("artifacts/11_source_data/H04/H04_preparation_category_support.csv"),
  show_col_types = FALSE
)
category_support <- category_support[
  category_support$placement == "Near-eye" &
    category_support$activity %in% activity_order,
  ,
  drop = FALSE
]
category_support <- category_support[
  match(activity_order, category_support$activity),
  ,
  drop = FALSE
]
if (
  !identical(as.character(category_support$activity), activity_order) ||
    any(category_support$sites != 9L)
) {
  stop("The six-category support order or site support has drifted.", call. = FALSE)
}
other_support <- category_support[
  category_support$activity == "Other/unspecified activity",
  ,
  drop = FALSE
]
if (
  nrow(other_support) != 1L ||
    other_support$participants != 72L ||
    other_support$participant_days != 159L ||
    other_support$unique_participant_hours != 391L ||
    other_support$long_rows != 391L ||
    abs(other_support$effective_weighted_hours - 391) > 1e-10 ||
    other_support$sites != 9L
) {
  stop("The accepted Other support contract has drifted.", call. = FALSE)
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
if (!identical(as.character(named_estimands$activity), named_activity_order)) {
  stop("The accepted named-category estimand order has drifted.", call. = FALSE)
}

other_estimands <- readr::read_csv(
  input_path("artifacts/09_tables/H04/H04_reader_category_estimands.csv"),
  show_col_types = FALSE
)
other_estimand <- other_estimands[
  other_estimands$placement == "Near-eye" &
    other_estimands$activity == "Other/unspecified activity",
  ,
  drop = FALSE
]
if (
  nrow(other_estimand) != 1L ||
    other_estimand$model_source != "additive_display_only" ||
    other_estimand$inferential_role != "DISPLAY_ONLY" ||
    !is.na(other_estimand$ratio_p_adjusted) ||
    other_estimand$participants != 72L ||
    other_estimand$participant_days != 159L ||
    other_estimand$unique_participant_hours != 391L ||
    other_estimand$long_rows != 391L ||
    abs(other_estimand$effective_weighted_hours - 391) > 1e-10 ||
    other_estimand$sites != 9L
) {
  stop("The accepted Other display-only estimand has drifted.", call. = FALSE)
}

display_estimands <- rbind(
  named_estimands[c(
    "placement",
    "activity",
    "standardized_mean_lx",
    "mean_conf_low_lx",
    "mean_conf_high_lx",
    "ratio_to_home",
    "ratio_conf_low",
    "ratio_conf_high",
    "ratio_p_adjusted"
  )],
  other_estimand[c(
    "placement",
    "activity",
    "standardized_mean_lx",
    "mean_conf_low_lx",
    "mean_conf_high_lx",
    "ratio_to_home",
    "ratio_conf_low",
    "ratio_conf_high",
    "ratio_p_adjusted"
  )]
)
display_estimands$model_source <- c(
  rep("activity_by_site_interaction", 5L),
  "additive_display_only"
)
if (!identical(as.character(display_estimands$activity), activity_order)) {
  stop("The six displayed estimands are not in reader order.", call. = FALSE)
}

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
if (
  nrow(site_estimands) != 54L ||
    sum(site_estimands$reporting_status == "ESTIMABLE") != 44L ||
    sum(
      site_estimands$reporting_status == "ESTIMABLE" &
        site_estimands$site_deviation_p_adjusted < 0.05,
      na.rm = TRUE
    ) != 17L
) {
  stop("The accepted site-factorization source has drifted.", call. = FALSE)
}

named_overall_rows <- tibble::tibble(
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

other_overall_row <- tibble::tibble(
  row_type = "site_average",
  site = "Site-average estimate",
  site_color = NA_character_,
  activity = "Other/unspecified activity",
  display_activity = "Other",
  estimate = sprintf(
    "%.1f (%.1f–%.1f) lx",
    other_estimand$standardized_mean_lx,
    other_estimand$mean_conf_low_lx,
    other_estimand$mean_conf_high_lx
  ),
  confidence_interval = sprintf(
    "%.3f (%.3f–%.3f)× At home",
    other_estimand$ratio_to_home,
    other_estimand$ratio_conf_low,
    other_estimand$ratio_conf_high
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
if (
  nrow(site_registry) != 9L ||
    !identical(as.character(site_registry$display_name), site_order) ||
    any(!grepl("^#[0-9A-F]{6}$", site_registry$color_hex))
) {
  stop("The accepted site display registry has drifted.", call. = FALSE)
}
site_palette <- stats::setNames(
  site_registry$color_hex,
  site_registry$display_name
)
site_estimands <- site_estimands[
  order(
    match(site_estimands$site_display_name, site_order),
    match(site_estimands$activity, activity_order)
  ),
  ,
  drop = FALSE
]
site_rows <- tibble::tibble(
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

overall_rows <- rbind(named_overall_rows, other_overall_row)
panel_d_data <- rbind(overall_rows, site_rows)
if (
  nrow(panel_d_data) != 60L ||
    nrow(site_rows) != 54L ||
    sum(site_rows$estimable) != 44L ||
    sum(site_rows$fdr_label) != 17L ||
    sum(
      site_rows$activity == "Other/unspecified activity" &
        !site_rows$estimable
    ) != 9L
) {
  stop("The six-column display contract is invalid.", call. = FALSE)
}

frame_contract <- tibble::tibble(
  participants = 126L,
  participant_days = 724L,
  unique_participant_hours = 16135L,
  generated_long_rows = 16875L,
  effective_weighted_hours = 16135,
  sites = 9L,
  exact_zero_participant_hours = 4746L,
  interaction_categories = 5L,
  display_categories = 6L,
  interaction_site_cells = 45L,
  display_site_cells = 54L,
  estimable_family_members = 44L,
  fdr_labelled_site_deviations = 17L,
  other_participants = 72L,
  other_participant_days = 159L,
  other_participant_hours = 391L
)

panel_d_source_path <- file.path(
  output_directory,
  "H04_manuscript_figure3_panel_d_source.csv"
)
support_source_path <- file.path(
  output_directory,
  "H04_manuscript_figure3_category_support.csv"
)
frame_contract_path <- file.path(
  output_directory,
  "H04_manuscript_figure3_frame_contract.csv"
)
input_identity_path <- file.path(
  output_directory,
  "H04_manuscript_figure3_input_identities.csv"
)
readr::write_csv(panel_d_data, panel_d_source_path)
readr::write_csv(category_support, support_source_path)
readr::write_csv(frame_contract, frame_contract_path)
readr::write_csv(input_identities, input_identity_path)

xml_escape <- function(value) {
  value <- gsub("&", "&amp;", value, fixed = TRUE)
  value <- gsub("<", "&lt;", value, fixed = TRUE)
  value <- gsub(">", "&gt;", value, fixed = TRUE)
  value <- gsub('"', "&quot;", value, fixed = TRUE)
  gsub("'", "&apos;", value, fixed = TRUE)
}

svg_text <- function(
  x,
  y,
  label,
  size = 14,
  weight = "normal",
  anchor = "start",
  fill = "#20262D",
  style = "normal"
) {
  sprintf(
    paste0(
      "<text x='%.2f' y='%.2f' text-anchor='%s' ",
      "style='font-size: %.2fpx; font-weight: %s; font-style: %s; ",
      "font-family: &quot;Arial&quot;; fill: %s;'>%s</text>"
    ),
    x,
    y,
    anchor,
    size,
    weight,
    style,
    fill,
    xml_escape(label)
  )
}

panel_width <- 1134
panel_height <- 795
left_margin <- 68.89
right_margin <- 24
site_width <- 145
category_width <- (panel_width - left_margin - right_margin - site_width) /
  length(activity_order)
column_lefts <- c(
  left_margin,
  left_margin + site_width + (seq_along(activity_order) - 1) * category_width
)
column_rights <- c(
  left_margin + site_width,
  left_margin + site_width + seq_along(activity_order) * category_width
)

panel_d_lines <- c(
  sprintf(
    "<rect x='0' y='0' width='%d' height='%d' style='stroke: none; fill: #FFFFFF;'/>",
    panel_width,
    panel_height
  ),
  svg_text(15.94, 28, "D", size = 14, weight = "bold"),
  svg_text(
    left_margin,
    28,
    "Near-eye activity-by-site interaction model",
    size = 18,
    weight = "bold"
  ),
  svg_text(
    left_margin,
    48,
    paste(
      "Site-average estimates and site-specific deviation ratios;",
      "bold site cells pass the complete near-eye FDR adjustment"
    ),
    size = 13.5
  )
)

header_top <- 60
header_bottom <- 126
overall_bottom <- 214
site_row_height <- 46
site_bottom <- overall_bottom + 9 * site_row_height
panel_d_lines <- c(
  panel_d_lines,
  sprintf(
    paste0(
      "<rect x='%.2f' y='%d' width='%.2f' height='%d' ",
      "style='stroke: none; fill: #D0D4D8;'/>") ,
    left_margin,
    header_top,
    panel_width - left_margin - right_margin,
    header_bottom - header_top
  ),
  sprintf(
    paste0(
      "<rect x='%.2f' y='%d' width='%.2f' height='%d' ",
      "style='stroke: none; fill: #E8EEF3;'/>") ,
    left_margin,
    header_bottom,
    panel_width - left_margin - right_margin,
    overall_bottom - header_bottom
  )
)
for (row_index in seq_along(site_order)) {
  row_top <- overall_bottom + (row_index - 1L) * site_row_height
  fill <- if (row_index %% 2L == 0L) "#F4F6F8" else "#FFFFFF"
  panel_d_lines <- c(
    panel_d_lines,
    sprintf(
      paste0(
        "<rect x='%.2f' y='%.2f' width='%.2f' height='%.2f' ",
        "style='stroke: none; fill: %s;'/>") ,
      left_margin,
      row_top,
      panel_width - left_margin - right_margin,
      site_row_height,
      fill
    )
  )
}

header_line_breaks <- list(
  c("At home"),
  c("Office/home", "working"),
  c("Outdoors"),
  c("Vehicle/public", "transport"),
  c("Sleeping"),
  c("Other")
)
for (index in seq_along(activity_order)) {
  center <- column_lefts[[index + 1L]] + category_width / 2
  header_lines <- header_line_breaks[[index]]
  title_y <- if (length(header_lines) == 1L) 82 else c(74, 89)
  support <- category_support[index, , drop = FALSE]
  support_line <- sprintf(
    "P %d · D %d · H %s",
    support$participants,
    support$participant_days,
    format(
      support$unique_participant_hours,
      big.mark = ",",
      scientific = FALSE
    )
  )
  header_fill <- if (index == 6L) "#4F5963" else "#20262D"
  header_style <- if (index == 6L) "italic" else "normal"
  panel_d_lines <- c(
    panel_d_lines,
    sprintf(
      paste0(
        "<g class='category-support' data-activity='%s' ",
        "data-participants='%d' data-participant-days='%d' ",
        "data-unique-hours='%d' data-long-rows='%d' ",
        "data-weighted-hours='%s' data-sites='%d'>"
      ),
      xml_escape(activity_order[[index]]),
      support$participants,
      support$participant_days,
      support$unique_participant_hours,
      support$long_rows,
      sprintf("%.17g", support$effective_weighted_hours),
      support$sites
    ),
    vapply(
      seq_along(header_lines),
      function(line_index) {
        svg_text(
          center,
          title_y[[line_index]],
          header_lines[[line_index]],
          size = 12.8,
          weight = "bold",
          anchor = "middle",
          fill = header_fill,
          style = header_style
        )
      },
      character(1)
    ),
    svg_text(
      center,
      112,
      support_line,
      size = 9.2,
      anchor = "middle",
      fill = "#46515C"
    ),
    "</g>"
  )
}

panel_d_lines <- c(
  panel_d_lines,
  svg_text(
    left_margin + 8,
    header_bottom + 34,
    "Site-average",
    size = 15,
    weight = "bold"
  ),
  svg_text(
    left_margin + 8,
    header_bottom + 52,
    "estimate",
    size = 15,
    weight = "bold"
  )
)

for (index in seq_along(activity_order)) {
  row <- display_estimands[index, , drop = FALSE]
  x <- column_lefts[[index + 1L]] + 5
  ratio_line <- if (index == 1L) {
    "Reference category"
  } else {
    sprintf("%.3f× home", row$ratio_to_home)
  }
  status_line <- if (index == 1L) {
    "FDR p (reference)"
  } else if (index == 6L) {
    "Additive display only"
  } else {
    paste("FDR p", format_p(row$ratio_p_adjusted))
  }
  panel_d_lines <- c(
    panel_d_lines,
    sprintf(
      paste0(
        "<g class='panel-d-cell' data-row-type='site_average' ",
        "data-site='Site-average estimate' data-activity='%s' ",
        "data-estimable='true' data-fdr-label='%s' ",
        "data-model-source='%s' data-mean='%.17g' ",
        "data-mean-low='%.17g' data-mean-high='%.17g' ",
        "data-ratio='%.17g' data-ratio-low='%.17g' ",
        "data-ratio-high='%.17g' data-p-text='%s'>"
      ),
      xml_escape(row$activity),
      tolower(as.character(index %in% 2:5)),
      xml_escape(row$model_source),
      row$standardized_mean_lx,
      row$mean_conf_low_lx,
      row$mean_conf_high_lx,
      row$ratio_to_home,
      row$ratio_conf_low,
      row$ratio_conf_high,
      xml_escape(status_line)
    ),
    svg_text(
      x,
      header_bottom + 20,
      sprintf(
        "%.1f lx (%.1f–%.1f)",
        row$standardized_mean_lx,
        row$mean_conf_low_lx,
        row$mean_conf_high_lx
      ),
      size = 10.8,
      weight = "bold"
    ),
    svg_text(
      x,
      header_bottom + 46,
      if (index == 1L) {
        ratio_line
      } else {
        sprintf(
          "%s (%.3f–%.3f)",
          ratio_line,
          row$ratio_conf_low,
          row$ratio_conf_high
        )
      },
      size = 10.2,
      weight = "bold"
    )
  )
  panel_d_lines <- c(
    panel_d_lines,
    svg_text(
      x,
      header_bottom + 70,
      status_line,
      size = if (index == 6L) 10.1 else 10.6,
      weight = if (index %in% 2:5) "bold" else "normal",
      fill = "#46515C",
      style = if (index == 6L) "italic" else "normal"
    ),
    "</g>"
  )
}

for (site_index in seq_along(site_order)) {
  site_name <- site_order[[site_index]]
  row_data <- site_rows[site_rows$site == site_name, , drop = FALSE]
  row_data <- row_data[match(activity_order, row_data$activity), , drop = FALSE]
  row_top <- overall_bottom + (site_index - 1L) * site_row_height
  site_color <- row_data$site_color[[1]]
  panel_d_lines <- c(
    panel_d_lines,
    sprintf(
      paste0(
        "<circle cx='%.2f' cy='%.2f' r='5.5' ",
        "style='stroke: none; fill: %s;'/>") ,
      left_margin + 13,
      row_top + site_row_height / 2,
      site_color
    ),
    svg_text(left_margin + 25, row_top + 29, site_name, size = 14)
  )
  for (activity_index in seq_along(activity_order)) {
    cell <- row_data[activity_index, , drop = FALSE]
    x <- column_lefts[[activity_index + 1L]] + 5
    panel_d_lines <- c(
      panel_d_lines,
      sprintf(
        paste0(
          "<g class='panel-d-cell' data-row-type='site_deviation' ",
          "data-site='%s' data-activity='%s' data-estimable='%s' ",
          "data-fdr-label='%s' data-model-source='%s'>"
        ),
        xml_escape(cell$site),
        xml_escape(cell$activity),
        tolower(as.character(cell$estimable)),
        tolower(as.character(cell$fdr_label)),
        xml_escape(cell$model_source)
      )
    )
    if (!cell$estimable) {
      panel_d_lines <- c(
        panel_d_lines,
        svg_text(
          x,
          row_top + 29,
          "Not estimable",
          size = 12.2,
          fill = "#46515C",
          style = "italic"
        )
      )
    } else {
      weight <- if (cell$fdr_label) "bold" else "normal"
      estimate_with_interval <- paste0(
        cell$estimate,
        " (",
        sub("^95% CI\\s*", "", cell$confidence_interval),
        ")"
      )
      panel_d_lines <- c(
        panel_d_lines,
        svg_text(
          x,
          row_top + 18,
          estimate_with_interval,
          size = 10.6,
          weight = weight
        ),
        svg_text(
          x,
          row_top + 37,
          cell$fdr_p,
          size = 10.6,
          weight = weight,
          fill = "#46515C"
        )
      )
    }
    panel_d_lines <- c(panel_d_lines, "</g>")
  }
}

grid_x <- unique(c(column_lefts, column_rights))
panel_d_lines <- c(
  panel_d_lines,
  vapply(
    grid_x,
    function(x) {
      sprintf(
        paste0(
          "<line x1='%.2f' y1='%d' x2='%.2f' y2='%d' ",
          "style='stroke-width: 0.8; stroke: #BCC6CE;'/>") ,
        x,
        header_top,
        x,
        site_bottom
      )
    },
    character(1)
  ),
  vapply(
    c(header_top, header_bottom, overall_bottom, site_bottom),
    function(y) {
      sprintf(
        paste0(
          "<line x1='%.2f' y1='%.2f' x2='%.2f' y2='%.2f' ",
          "style='stroke-width: 1.1; stroke: #8192A3;'/>") ,
        left_margin,
        y,
        panel_width - right_margin,
        y
      )
    },
    character(1)
  )
)

footer_lines <- c(
  paste(
    "Site-average estimates and comparisons for the five named categories use",
    "the activity-by-site interaction model."
  ),
  paste(
    "Other is the additive display-only estimate and was excluded",
    "from the interaction model."
  ),
  paste(
    "Site rows are deviation ratios around each category estimate; parentheses",
    "show 95% confidence intervals."
  ),
  paste(
    "Bold site ratios and FDR p-values pass the complete 44-member near-eye",
    "family; unsupported cells are not estimable."
  ),
  paste(
    "Five-category interaction frame: 126 participants; 724 participant-days;",
    "16,135 unique participant-hours; 16,875 generated long rows;"
  ),
  paste(
    "16,135 effective weighted hours; nine sites; 4,746 exact-zero participant-hours.",
    "Each multi-select hour contributes 1/k."
  ),
  paste(
    "Other-only display support: P 72 · D 159 · H 391.",
    "P, participants; D, participant-days; H, unique participant-hours."
  )
)
panel_d_lines <- c(
  panel_d_lines,
  vapply(
    seq_along(footer_lines),
    function(index) {
      svg_text(
        left_margin,
        site_bottom + 24 + (index - 1) * 18,
        footer_lines[[index]],
        size = 11.0,
        fill = "#343C44"
      )
    },
    character(1)
  )
)

panel_d_svg_lines <- c(
  "<?xml version='1.0' encoding='UTF-8' ?>",
  sprintf(
    paste0(
      "<svg xmlns='http://www.w3.org/2000/svg' width='%d.00pt' ",
      "height='%d.00pt' viewBox='0 0 %d.00 %d.00'>"
    ),
    panel_width,
    panel_height,
    panel_width,
    panel_height
  ),
  paste0(
    "<g id='panel-d' data-source-model='activity-by-site interaction model' ",
    "data-other-source-model='additive_display_only'>"
  ),
  panel_d_lines,
  "</g>",
  "</svg>"
)
panel_d_svg_path <- file.path(
  output_directory,
  "H04_manuscript_figure3_panel_d.svg"
)
writeLines(panel_d_svg_lines, panel_d_svg_path, useBytes = TRUE)

accepted_svg_lines <- readLines(
  input_path("artifacts/10_figures/H04/H04_temporal_near_eye.svg"),
  warn = FALSE,
  encoding = "UTF-8"
)
root_open <- grep("^<svg ", accepted_svg_lines)
root_close <- tail(grep("^</svg>$", accepted_svg_lines), 1L)
if (length(root_open) != 1L || length(root_close) != 1L) {
  stop("Unexpected accepted temporal SVG root structure.", call. = FALSE)
}
temporal_inner <- accepted_svg_lines[(root_open + 1L):(root_close - 1L)]
tag_specification <- tibble::tribble(
  ~panel,
  ~upper,
  ~old_x,
  ~new_x,
  ~y,
  ~old_box_x,
  ~old_box_y,
  ~old_box_width,
  ~old_box_height,
  ~new_box_x,
  ~new_box_y,
  ~new_box_width,
  ~new_box_height,
  "A", "A", 1102.64, 15.94, 27.29, 1080, 7, 30, 28, 8, 7, 30, 28,
  "B", "B", 1102.64, 15.94, 308.04, 1080, 288, 30, 28, 8, 288, 30, 28,
  "C", "C", 1102.64, 15.94, 564.24, 1080, 544, 30, 28, 8, 544, 30, 28
)
for (index in seq_len(nrow(tag_specification))) {
  old_tag <- sprintf(
    paste0(
      "<text x='%.2f' y='%.2f' text-anchor='end' ",
      "style='font-size: 14.00px; font-weight: bold; ",
      "font-family: \"Arial\";' textLength='10.11px' ",
      "lengthAdjust='spacingAndGlyphs'>%s</text>"
    ),
    tag_specification$old_x[[index]],
    tag_specification$y[[index]],
    tag_specification$upper[[index]]
  )
  new_tag <- sprintf(
    paste0(
      "<text x='%.2f' y='%.2f' text-anchor='start' ",
      "style='font-size: 14.00px; font-weight: bold; ",
      "font-family: \"Arial\";' textLength='10.11px' ",
      "lengthAdjust='spacingAndGlyphs'>%s</text>"
    ),
    tag_specification$new_x[[index]],
    tag_specification$y[[index]],
    tag_specification$upper[[index]]
  )
  matched <- which(temporal_inner == old_tag)
  if (length(matched) != 1L) {
    stop(
      "Expected exactly one accepted temporal panel tag ",
      tag_specification$upper[[index]],
      ".",
      call. = FALSE
    )
  }
  temporal_inner[[matched]] <- new_tag
}
other_strip_specification <- tibble::tribble(
  ~panel,
  ~strip_y,
  ~text_y,
  "A", 53.97, 68.81,
  "B", 334.84, 349.68,
  "C", 591.17, 606.00
)
for (index in seq_len(nrow(other_strip_specification))) {
  matched <- which(
    grepl(
      sprintf("y='%.2f'", other_strip_specification$text_y[[index]]),
      temporal_inner,
      fixed = TRUE
    ) &
      grepl(">Other/unspecified</text>", temporal_inner, fixed = TRUE)
  )
  if (length(matched) != 1L) {
    stop("Expected exactly one accepted Other strip per panel.", call. = FALSE)
  }
  temporal_inner[[matched]] <- sprintf(
    paste0(
      "<text x='1024.40' y='%.2f' text-anchor='middle' ",
      "style='font-size: 12.00px; font-weight: bold; ",
      "font-family: \"Arial\";'>Other</text>"
    ),
    other_strip_specification$text_y[[index]]
  )
}
old_caption_text <- paste0(
  "<text x='15.94' y='820.96' style='font-size: 10.50px; ",
  "font-family: \"Arial\";' textLength='722.12px' ",
  "lengthAdjust='spacingAndGlyphs'>Panel B divides each displayed activity ",
  "curve by the displayed global time-of-day mean; the dashed reference is ",
  "1. Other/unspecified activity is display-only.</text>"
)
new_caption_label <- paste(
  "Panel B divides each displayed activity curve by the displayed global",
  "time-of-day mean; the dashed reference is 1. Other is display-only."
)
caption_index <- which(temporal_inner == old_caption_text)
if (length(caption_index) != 1L) {
  stop("Expected exactly one accepted temporal Other caption.", call. = FALSE)
}
temporal_inner[[caption_index]] <- paste0(
  "<text x='15.94' y='820.96' style='font-size: 10.50px; ",
  "font-family: \"Arial\";'>",
  new_caption_label,
  "</text>"
)
old_b_axis_label <- paste0(
  "<text transform='translate(25.96,437.76) rotate(-90)' ",
  "text-anchor='middle' style='font-size: 14.00px; ",
  "font-family: \"Arial\";' textLength='184.34px' ",
  "lengthAdjust='spacingAndGlyphs'>Factor relative to global mean</text>"
)
new_b_axis_label <- paste0(
  "<text transform='translate(25.96,437.76) rotate(-90)' ",
  "text-anchor='middle' style='font-size: 14.00px; ",
  "font-family: \"Arial\";'>Ratio to global mean</text>"
)
axis_index <- which(temporal_inner == old_b_axis_label)
if (length(axis_index) != 1L) {
  stop("Expected exactly one panel-B axis title.", call. = FALSE)
}
temporal_inner[[axis_index]] <- new_b_axis_label
temporal_block <- c(
  "<!-- BEGIN TEMPORAL PANELS -->",
  "<g id='temporal-panels'>",
  temporal_inner,
  "</g>",
  "<!-- END TEMPORAL PANELS -->"
)
composite_height <- 900 + panel_height
composite_svg_lines <- c(
  "<?xml version='1.0' encoding='UTF-8' ?>",
  sprintf(
    paste0(
      "<svg xmlns='http://www.w3.org/2000/svg' ",
      "xmlns:xlink='http://www.w3.org/1999/xlink' width='1134.00pt' ",
      "height='%d.00pt' viewBox='0 0 1134.00 %d.00'>"
    ),
    composite_height,
    composite_height
  ),
  temporal_block,
  "<g id='factorization-panel' transform='translate(0 900)'>",
  panel_d_lines,
  "</g>",
  "</svg>"
)
composite_svg_path <- file.path(
  output_directory,
  "H04_manuscript_figure3_candidate.svg"
)
writeLines(composite_svg_lines, composite_svg_path, useBytes = TRUE)

accepted_temporal_png <- png::readPNG(
  input_path("artifacts/10_figures/H04/H04_temporal_near_eye.png")
)
if (!identical(dim(accepted_temporal_png), c(3750L, 4725L, 3L))) {
  stop("The accepted temporal raster dimensions have drifted.", call. = FALSE)
}
candidate_top <- accepted_temporal_png
pixels_per_point <- dim(candidate_top)[[2]] / panel_width
old_tag_pixels <- tibble::tibble(
  panel = tag_specification$panel,
  box = "removed_right_tag",
  label = tag_specification$upper,
  x = tag_specification$old_x,
  y = tag_specification$y,
  box_x = tag_specification$old_box_x,
  box_y = tag_specification$old_box_y,
  box_width = tag_specification$old_box_width,
  box_height = tag_specification$old_box_height
)
new_tag_pixels <- tibble::tibble(
  panel = tag_specification$panel,
  box = "added_left_tag",
  label = tag_specification$upper,
  x = tag_specification$new_x,
  y = tag_specification$y,
  box_x = tag_specification$new_box_x,
  box_y = tag_specification$new_box_y,
  box_width = tag_specification$new_box_width,
  box_height = tag_specification$new_box_height
)
pixel_coordinates <- function(data) {
  data$x_start <- floor(data$box_x * pixels_per_point) + 1L
  data$x_end <- ceiling((data$box_x + data$box_width) * pixels_per_point)
  data$y_start <- floor(data$box_y * pixels_per_point) + 1L
  data$y_end <- ceiling((data$box_y + data$box_height) * pixels_per_point)
  data
}
old_tag_pixels <- pixel_coordinates(old_tag_pixels)
new_tag_pixels <- pixel_coordinates(new_tag_pixels)
for (index in seq_len(nrow(old_tag_pixels))) {
  candidate_top[
    old_tag_pixels$y_start[[index]]:old_tag_pixels$y_end[[index]],
    old_tag_pixels$x_start[[index]]:old_tag_pixels$x_end[[index]],
  ] <- 1
}
for (index in seq_len(nrow(new_tag_pixels))) {
  pixel_width <- new_tag_pixels$x_end[[index]] -
    new_tag_pixels$x_start[[index]] + 1L
  pixel_height <- new_tag_pixels$y_end[[index]] -
    new_tag_pixels$y_start[[index]] + 1L
  tile_svg <- paste0(
    "<svg xmlns='http://www.w3.org/2000/svg' width='",
    pixel_width,
    "px' height='",
    pixel_height,
    "px' viewBox='0 0 ",
    new_tag_pixels$box_width[[index]],
    " ",
    new_tag_pixels$box_height[[index]],
    "'>",
    "<rect width='100%' height='100%' style='stroke:none;fill:#FFFFFF;'/>",
    svg_text(
      new_tag_pixels$x[[index]] - new_tag_pixels$box_x[[index]],
      new_tag_pixels$y[[index]] - new_tag_pixels$box_y[[index]],
      new_tag_pixels$label[[index]],
      size = 14,
      weight = "bold",
      anchor = "start"
    ),
    "</svg>"
  )
  tile_image <- magick::image_read(charToRaw(tile_svg))
  tile_image <- magick::image_background(tile_image, "white", flatten = TRUE)
  tile_image <- magick::image_convert(
    tile_image,
    type = "truecolor",
    matte = FALSE
  )
  tile_pixels <- png::readPNG(
    magick::image_write(tile_image, format = "png")
  )
  expected_tile_dimension <- as.integer(c(pixel_height, pixel_width, 3L))
  if (!identical(dim(tile_pixels), expected_tile_dimension)) {
    stop("Unexpected rasterized panel-tag dimensions.", call. = FALSE)
  }
  candidate_top[
    new_tag_pixels$y_start[[index]]:new_tag_pixels$y_end[[index]],
    new_tag_pixels$x_start[[index]]:new_tag_pixels$x_end[[index]],
  ] <- tile_pixels
}
other_repair_boxes <- tibble::tibble(
  panel = c("A", "B", "C", "Caption"),
  box = c(rep("other_strip_label", 3L), "other_caption"),
  label = c(rep("Other", 3L), new_caption_label),
  x = c(rep(1024.40, 3L), 15.94),
  y = c(other_strip_specification$text_y, 820.96),
  box_x = c(rep(940.71, 3L), 14),
  box_y = c(other_strip_specification$strip_y, 808),
  box_width = c(rep(167.39, 3L), 740),
  box_height = c(rep(21.08, 3L), 17)
)
other_repair_boxes <- pixel_coordinates(other_repair_boxes)
for (index in seq_len(nrow(other_repair_boxes))) {
  pixel_width <- other_repair_boxes$x_end[[index]] -
    other_repair_boxes$x_start[[index]] + 1L
  pixel_height <- other_repair_boxes$y_end[[index]] -
    other_repair_boxes$y_start[[index]] + 1L
  is_caption <- other_repair_boxes$box[[index]] == "other_caption"
  tile_fill <- if (is_caption) "#FFFFFF" else "#CCCCCC"
  tile_svg <- paste0(
    "<svg xmlns='http://www.w3.org/2000/svg' width='",
    pixel_width,
    "px' height='",
    pixel_height,
    "px' viewBox='0 0 ",
    other_repair_boxes$box_width[[index]],
    " ",
    other_repair_boxes$box_height[[index]],
    "'>",
    "<rect width='100%' height='100%' style='stroke:none;fill:",
    tile_fill,
    ";'/>",
    svg_text(
      other_repair_boxes$x[[index]] - other_repair_boxes$box_x[[index]],
      other_repair_boxes$y[[index]] - other_repair_boxes$box_y[[index]],
      other_repair_boxes$label[[index]],
      size = if (is_caption) 10.5 else 12,
      weight = if (is_caption) "normal" else "bold",
      anchor = if (is_caption) "start" else "middle"
    ),
    "</svg>"
  )
  tile_image <- magick::image_read(charToRaw(tile_svg))
  tile_image <- magick::image_background(tile_image, tile_fill, flatten = TRUE)
  tile_image <- magick::image_convert(
    tile_image,
    type = "truecolor",
    matte = FALSE
  )
  tile_pixels <- png::readPNG(
    magick::image_write(tile_image, format = "png")
  )
  expected_tile_dimension <- as.integer(c(pixel_height, pixel_width, 3L))
  if (!identical(dim(tile_pixels), expected_tile_dimension)) {
    stop("Unexpected rasterized Other-label repair dimensions.", call. = FALSE)
  }
  candidate_top[
    other_repair_boxes$y_start[[index]]:other_repair_boxes$y_end[[index]],
    other_repair_boxes$x_start[[index]]:other_repair_boxes$x_end[[index]],
  ] <- tile_pixels
}
axis_label_box <- tibble::tibble(
  panel = "B/C",
  box = "axis_label_and_c_tag",
  label = "Ratio to global mean; C",
  x = 25.96,
  y = 437.76,
  box_x = 7,
  box_y = 335,
  box_width = 42,
  box_height = 250
)
axis_label_box$x_start <-
  floor(axis_label_box$box_x * pixels_per_point) + 1L
axis_label_box$x_end <- ceiling(
  (axis_label_box$box_x + axis_label_box$box_width) * pixels_per_point
)
axis_label_box$y_start <-
  floor(axis_label_box$box_y * pixels_per_point) + 1L
axis_label_box$y_end <- ceiling(
  (axis_label_box$box_y + axis_label_box$box_height) * pixels_per_point
)
axis_tile_width <- axis_label_box$x_end - axis_label_box$x_start + 1L
axis_tile_height <- axis_label_box$y_end - axis_label_box$y_start + 1L
axis_tile_svg <- paste0(
  "<svg xmlns='http://www.w3.org/2000/svg' width='",
  axis_tile_width,
  "px' height='",
  axis_tile_height,
  "px' viewBox='0 0 ",
  axis_label_box$box_width,
  " ",
  axis_label_box$box_height,
  "'>",
  "<rect width='100%' height='100%' style='stroke:none;fill:#FFFFFF;'/>",
  "<text transform='translate(",
  sprintf("%.2f", 25.96 - axis_label_box$box_x),
  ",",
  sprintf("%.2f", 437.76 - axis_label_box$box_y),
  ") rotate(-90)' text-anchor='middle' style='font-size: 14.00px; ",
  "font-family: &quot;Arial&quot;;'>Ratio to global mean</text>",
  "<text x='",
  sprintf("%.2f", 15.94 - axis_label_box$box_x),
  "' y='",
  sprintf("%.2f", 564.24 - axis_label_box$box_y),
  "' text-anchor='start' style='font-size: 14.00px; font-weight: bold; ",
  "font-family: &quot;Arial&quot;;' textLength='10.11px' ",
  "lengthAdjust='spacingAndGlyphs'>C</text>",
  "</svg>"
)
axis_tile_image <- magick::image_read(charToRaw(axis_tile_svg))
axis_tile_image <- magick::image_background(
  axis_tile_image,
  "white",
  flatten = TRUE
)
axis_tile_image <- magick::image_convert(
  axis_tile_image,
  type = "truecolor",
  matte = FALSE
)
axis_tile_pixels <- png::readPNG(
  magick::image_write(axis_tile_image, format = "png")
)
if (length(dim(axis_tile_pixels)) == 2L) {
  axis_tile_pixels <- array(
    rep(axis_tile_pixels, 3L),
    dim = c(dim(axis_tile_pixels), 3L)
  )
}
if (!identical(
  dim(axis_tile_pixels),
  as.integer(c(axis_tile_height, axis_tile_width, 3L))
)) {
  stop("Unexpected rasterized H04 panel-B/C repair tile.", call. = FALSE)
}
candidate_top[
  axis_label_box$y_start:axis_label_box$y_end,
  axis_label_box$x_start:axis_label_box$x_end,
] <- axis_tile_pixels
tag_box_path <- file.path(
  output_directory,
  "H04_manuscript_figure3_temporal_tag_boxes.csv"
)
tag_boxes <- rbind(
  old_tag_pixels,
  new_tag_pixels,
  other_repair_boxes
)[c(
  "panel",
  "box",
  "label",
  "x",
  "y",
  "box_x",
  "box_y",
  "box_width",
  "box_height",
  "x_start",
  "x_end",
  "y_start",
  "y_end"
)]
axis_box_record <- axis_label_box[names(tag_boxes)]
readr::write_csv(rbind(tag_boxes, axis_box_record), tag_box_path)

panel_d_image <- magick::image_read(panel_d_svg_path, density = 300)
panel_d_image <- magick::image_background(
  panel_d_image,
  "white",
  flatten = TRUE
)
panel_d_image <- magick::image_convert(
  panel_d_image,
  type = "truecolor",
  matte = FALSE
)
panel_d_png_path <- file.path(
  output_directory,
  "H04_manuscript_figure3_panel_d.png"
)
magick::image_write(panel_d_image, panel_d_png_path, format = "png")
panel_d_png <- png::readPNG(panel_d_png_path)
if (
  dim(panel_d_png)[[2]] != dim(candidate_top)[[2]] ||
    dim(panel_d_png)[[3]] != 3L
) {
  stop("The revision-2 panel D raster width has drifted.", call. = FALSE)
}

candidate_png <- array(
  NA_real_,
  dim = c(
    dim(candidate_top)[[1]] + dim(panel_d_png)[[1]],
    dim(candidate_top)[[2]],
    3L
  )
)
candidate_png[seq_len(dim(candidate_top)[[1]]), , ] <- candidate_top
panel_rows <- seq.int(dim(candidate_top)[[1]] + 1L, dim(candidate_png)[[1]])
candidate_png[panel_rows, , ] <- panel_d_png
candidate_png_path <- file.path(
  output_directory,
  "H04_manuscript_figure3_candidate.png"
)
png::writePNG(candidate_png, candidate_png_path, dpi = 300)
rm(
  accepted_temporal_png,
  candidate_top,
  panel_d_png,
  candidate_png
)
invisible(gc())

preview_width <- round(170 / 25.4 * 300)
candidate_image <- magick::image_read(candidate_png_path)
candidate_preview <- magick::image_resize(
  candidate_image,
  paste0(preview_width, "x")
)
candidate_preview_path <- file.path(
  output_directory,
  "H04_manuscript_figure3_candidate_170mm.png"
)
magick::image_write(candidate_preview, candidate_preview_path, format = "png")

vector_preview <- magick::image_read(composite_svg_path, density = 150)
vector_preview <- magick::image_background(
  vector_preview,
  "white",
  flatten = TRUE
)
vector_preview <- magick::image_resize(
  vector_preview,
  paste0(preview_width, "x")
)
vector_preview_path <- file.path(
  output_directory,
  "H04_manuscript_figure3_candidate_vector_170mm.png"
)
magick::image_write(vector_preview, vector_preview_path, format = "png")

caption <- paste(
  paste(
    "Exploratory near-eye time-of-day patterns and site-specific activity",
    "context. Panels **A**, **B**, and **C** show site-average",
    "activity-associated melEDI by local time, ratios to the global cyclic",
    "smooth, and effective weighted support."
  ),
  paste(
    "Panel **D** shows site-average estimates and site-specific deviation",
    "ratios. The five named categories use the activity-by-site interaction",
    "model. Other is the accepted additive display-only estimate",
    "and is excluded from that interaction model."
  ),
  paste(
    "Parentheses contain 95% confidence intervals. Bold site ratios and FDR",
    "p-values pass the complete 44-member near-eye family. Unsupported",
    "activity-by-site cells, including all Other site cells, are",
    "not estimable."
  ),
  paste(
    "The five-category interaction frame comprises 126 participants, 724",
    "participant-days, 16,135 unique participant-hours, 16,875 generated long",
    "rows, 16,135 effective weighted hours, nine sites, and 4,746 exact-zero",
    "participant-hours."
  ),
  paste(
    "Each multi-select participant-hour contributes 1/k across retained",
    "categories. Other-only display support comprises 72 participants, 159",
    "participant-days, and 391 unique participant-hours. P denotes",
    "participants, D participant-days, and H unique participant-hours."
  )
)
caption_path <- file.path(
  output_directory,
  "H04_manuscript_figure3_candidate_caption.txt"
)
writeLines(caption, caption_path, useBytes = TRUE)

output_paths <- c(
  panel_d_source_path,
  support_source_path,
  frame_contract_path,
  input_identity_path,
  tag_box_path,
  panel_d_svg_path,
  panel_d_png_path,
  composite_svg_path,
  candidate_png_path,
  candidate_preview_path,
  vector_preview_path,
  caption_path
)
output_manifest <- tibble::tibble(
  role = c(
    "panel_d_source",
    "category_support",
    "frame_contract",
    "input_identities",
    "temporal_tag_boxes",
    "panel_d_svg",
    "panel_d_png",
    "candidate_svg",
    "candidate_png",
    "candidate_png_170mm",
    "candidate_vector_170mm",
    "candidate_caption"
  ),
  path = output_paths,
  sha256 = vapply(output_paths, sha256, character(1)),
  bytes = as.numeric(file.info(output_paths)$size),
  r_version = as.character(getRversion())
)
readr::write_csv(
  output_manifest,
  file.path(output_directory, "H04_manuscript_figure3_candidate_outputs.csv")
)

message(
  "H04 manuscript Figure 3 revision-2 candidate written to ",
  output_directory
)
