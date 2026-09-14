#!/usr/bin/env Rscript

# Build the isolated H04 manuscript Figure 3 candidate from frozen displays.

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
    "The H04 manuscript Figure 3 candidate requires R 4.6.1; found ",
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
  !vapply(
    required_packages,
    requireNamespace,
    logical(1),
    quietly = TRUE
  )
]
if (length(missing_packages) > 0L) {
  stop(
    "Missing synchronized project package(s): ",
    paste(missing_packages, collapse = ", "),
    call. = FALSE
  )
}

output_directory <- Sys.getenv("H04_FIGURE3_CANDIDATE_DIR", unset = "")
if (!nzchar(output_directory)) {
  stop(
    "Set `H04_FIGURE3_CANDIDATE_DIR` to one fresh temporary directory.",
    call. = FALSE
  )
}
if (!dir.exists(output_directory)) {
  stop("The candidate output directory does not exist.", call. = FALSE)
}
output_directory <- normalizePath(
  output_directory,
  winslash = "/",
  mustWork = TRUE
)
if (length(list.files(output_directory, all.files = TRUE, no.. = TRUE)) > 0L) {
  stop("The candidate output directory must be empty.", call. = FALSE)
}

frozen_inputs <- tibble::tribble(
  ~path,
  ~sha256,
  "notebooks/hypotheses/H04.qmd",
  "f8adb6d78be041ce296dd7e89eb92769b128631c1b4227ce5d8ab3d526daf1d5",
  "_build/nathealth/notebooks/hypotheses/H04.html",
  "edb592760ee086c4b58abf7ab8946dbdf2be2c4b35bb7e6f11d84f66f71160e0",
  "artifacts/10_figures/H04/H04_temporal_near_eye.png",
  "8f048e0716e036413f541054a03c521941b4728f661871223b3e4c238991b3d4",
  "artifacts/10_figures/H04/H04_temporal_near_eye.svg",
  "2a804065daa8550523f90391350ed9ec654f3ad66dbc3d5e410ef408739a7678",
  "artifacts/10_figures/H04/H04_temporal_near_eye.pdf",
  "627376f457ec710793834755d7bde8f37389c213e10763334dfaab7b77f2d379",
  "artifacts/11_source_data/H04/H04_reader_temporal_near_eye_curves.csv",
  "97025e3f0166b8d4c896cd7504ac75c32aa49a7b315b8b17aef9929c1669d7e1",
  "artifacts/11_source_data/H04/H04_reader_temporal_near_eye_ratios.csv",
  "26a5c2de41e46894171b1442cb41da8053c633bda97d8a68b1ba514262bfc613",
  "artifacts/11_source_data/H04/H04_reader_temporal_near_eye_global.csv",
  "4f4445bb359bf3023d97b4e2445e3905950c22d570f9d47fc3ed554d12d34749",
  "artifacts/11_source_data/H04/H04_reader_temporal_near_eye_support.csv",
  "6d0a3a3b82d7c4dbbbb8863bf09307ec1ffa719f09e71593c5e9eae69516e508",
  "artifacts/09_tables/H04/H04_reader_heterogeneity_category_estimands.csv",
  "733086079d21a6bb13ea36a43020c6a0d0204f648797337dff1d6ea4dcd32084",
  "artifacts/06_model_data/H04/H04_category_support.csv",
  "bd8b8837e2357ca18466c080c6121eee6b857e4440554e662d3632cb308cd463",
  "scripts/hypotheses/H04/build_h04_stage3_reader_figures.R",
  "2ae1ae770d4b0cf3725b04cd337d883659d429ff9a8f7c482d38f0af516c158a",
  "scripts/hypotheses/H04/build_h04_stage3_reader_assets.R",
  "9fef4f87941e28c0db784d5e9ef2971cd96e1d5f8ffd55847b51ccbcc2a24c60",
  "artifacts/12_manifests/H04/H04_stage3_reader_asset_manifest.csv",
  "b7963a6bf11617ea4831ce8e53baaf1e9d6746a0bd147ca866cd1fbbb8901be3",
  "artifacts/12_manifests/H04/H04_stage3_artifacts.csv",
  "6215a9496f5f542ff92c19536b5601aa49c1ca804523eb7f9ff8bfdff852e115"
)
frozen_inputs$absolute_path <- file.path(root, frozen_inputs$path)
missing_inputs <- frozen_inputs$path[!file.exists(frozen_inputs$absolute_path)]
if (length(missing_inputs) > 0L) {
  stop(
    "Missing frozen input(s): ",
    paste(missing_inputs, collapse = ", "),
    call. = FALSE
  )
}
frozen_inputs$observed_sha256 <- vapply(
  frozen_inputs$absolute_path,
  digest::digest,
  character(1),
  algo = "sha256",
  file = TRUE
)
if (!all(frozen_inputs$sha256 == frozen_inputs$observed_sha256)) {
  failed <- frozen_inputs$path[
    frozen_inputs$sha256 != frozen_inputs$observed_sha256
  ]
  stop(
    "Frozen H04 input identity drift: ",
    paste(failed, collapse = ", "),
    call. = FALSE
  )
}

input_path <- function(path) file.path(root, path)

activity_order <- c(
  "At home",
  "Working in the office/from home",
  "Outdoors",
  "On the road with public transport/car",
  "Sleeping"
)
activity_labels <- c(
  "At home" = "At home",
  "Working in the office/from home" = "Office/home working",
  "Outdoors" = "Outdoors",
  "On the road with public transport/car" = "Vehicle/public transport",
  "Sleeping" = "Sleeping"
)
header_to_activity <- stats::setNames(
  names(activity_labels),
  unname(activity_labels)
)

xml_escape <- function(value) {
  value <- gsub("&", "&amp;", value, fixed = TRUE)
  value <- gsub("<", "&lt;", value, fixed = TRUE)
  value <- gsub(">", "&gt;", value, fixed = TRUE)
  value <- gsub('"', "&quot;", value, fixed = TRUE)
  gsub("'", "&apos;", value, fixed = TRUE)
}

node_lines <- function(node) {
  collect_text <- function(current) {
    node_type <- xml2::xml_type(current)
    if (identical(node_type, "text")) {
      return(xml2::xml_text(current))
    }
    if (identical(xml2::xml_name(current), "br")) {
      return("\n")
    }
    paste(
      vapply(
        xml2::xml_contents(current),
        collect_text,
        character(1)
      ),
      collapse = ""
    )
  }
  lines <- strsplit(collect_text(node), "\n", fixed = TRUE)[[1]]
  lines <- trimws(gsub("\u00a0", " ", lines, fixed = TRUE))
  lines[nzchar(lines)]
}

accepted_html <- xml2::read_html(input_path(
  "_build/nathealth/notebooks/hypotheses/H04.html"
))
factorization_table <- xml2::xml_find_first(
  accepted_html,
  '//*[@id="tbl-h04-near-site-factorization"]//table'
)
if (inherits(factorization_table, "xml_missing")) {
  stop("The accepted near-eye factorization table is missing.", call. = FALSE)
}

header_nodes <- xml2::xml_find_all(factorization_table, ".//thead//th")
header_labels <- vapply(
  header_nodes,
  function(node) paste(node_lines(node), collapse = " "),
  character(1)
)
expected_headers <- c("Site", unname(activity_labels))
if (!identical(header_labels, expected_headers)) {
  stop("Accepted panel-d category headers have drifted.", call. = FALSE)
}

body_rows <- xml2::xml_find_all(factorization_table, ".//tbody/tr")
body_rows <- body_rows[vapply(
  body_rows,
  function(row) {
    cells <- xml2::xml_find_all(row, "./td")
    length(cells) == 6L && length(node_lines(cells[[1]])) > 0L
  },
  logical(1)
)]
if (length(body_rows) != 10L) {
  stop("Expected one site-average row and nine site rows.", call. = FALSE)
}

overall_cells <- xml2::xml_find_all(body_rows[[1]], "./td")
overall_rows <- lapply(seq_along(activity_order), function(index) {
  cell <- overall_cells[[index + 1L]]
  lines <- node_lines(cell)
  if (length(lines) != 3L) {
    stop("Unexpected site-average cell structure.", call. = FALSE)
  }
  tibble::tibble(
    row_type = "site_average",
    site = "Site-average estimate",
    site_color = NA_character_,
    activity = activity_order[[index]],
    display_activity = unname(activity_labels[activity_order[[index]]]),
    estimate = lines[[1]],
    confidence_interval = lines[[2]],
    fdr_p = lines[[3]],
    estimable = TRUE,
    fdr_label = !identical(activity_order[[index]], "At home")
  )
})
overall_rows <- do.call(rbind, overall_rows)

site_rows <- lapply(body_rows[-1L], function(row) {
  cells <- xml2::xml_find_all(row, "./td")
  site_lines <- node_lines(cells[[1]])
  site <- sub("^●[[:space:]]*", "", site_lines[[1]])
  color_style <- xml2::xml_attr(
    xml2::xml_find_first(cells[[1]], ".//span"),
    "style"
  )
  site_color <- sub(".*color:([^;]+).*", "\\1", color_style)
  do.call(
    rbind,
    lapply(seq_along(activity_order), function(index) {
      cell <- cells[[index + 1L]]
      lines <- node_lines(cell)
      estimable <- !identical(lines[[1]], "Not estimable")
      expected_line_count <- if (estimable) 3L else 1L
      if (length(lines) != expected_line_count) {
        stop("Unexpected site-cell structure for ", site, call. = FALSE)
      }
      tibble::tibble(
        row_type = "site_deviation",
        site = site,
        site_color = site_color,
        activity = activity_order[[index]],
        display_activity = unname(activity_labels[activity_order[[index]]]),
        estimate = lines[[1]],
        confidence_interval = if (estimable) lines[[2]] else NA_character_,
        fdr_p = if (estimable) lines[[3]] else NA_character_,
        estimable = estimable,
        fdr_label = length(xml2::xml_find_all(cell, ".//strong")) > 0L
      )
    })
  )
})
site_rows <- do.call(rbind, site_rows)
panel_d_data <- rbind(overall_rows, site_rows)

if (nrow(site_rows) != 45L || sum(site_rows$estimable) != 44L) {
  stop("The accepted panel-d estimability contract has drifted.", call. = FALSE)
}
non_estimable <- site_rows[!site_rows$estimable, , drop = FALSE]
if (
  nrow(non_estimable) != 1L ||
    non_estimable$site[[1]] != "San José (CR)" ||
    non_estimable$activity[[1]] != "Outdoors"
) {
  stop("The accepted support-non-estimable cell has drifted.", call. = FALSE)
}
if (sum(site_rows$fdr_label) != 17L) {
  stop("The accepted 17-label near-eye FDR family has drifted.", call. = FALSE)
}

estimands <- readr::read_csv(
  input_path(
    "artifacts/09_tables/H04/H04_reader_heterogeneity_category_estimands.csv"
  ),
  show_col_types = FALSE
)
estimands <- estimands[
  estimands$placement == "Near-eye" & estimands$activity %in% activity_order,
  ,
  drop = FALSE
]
estimands <- estimands[
  match(activity_order, estimands$activity),
  ,
  drop = FALSE
]
if (!identical(as.character(estimands$activity), activity_order)) {
  stop("The accepted site-average estimand order has drifted.", call. = FALSE)
}
expected_overall_mean <- sprintf(
  "%.1f (%.1f–%.1f) lx",
  estimands$standardized_mean_lx,
  estimands$mean_conf_low_lx,
  estimands$mean_conf_high_lx
)
expected_overall_context <- c(
  "Reference category",
  sprintf(
    "%.3f (%.3f–%.3f)× At home",
    estimands$ratio_to_home[-1L],
    estimands$ratio_conf_low[-1L],
    estimands$ratio_conf_high[-1L]
  )
)
format_p <- function(value) {
  ifelse(value < 0.001, "<0.001", sprintf("%.3f", value))
}
expected_overall_p <- c(
  "FDR p (reference)",
  paste("FDR p", format_p(estimands$ratio_p_adjusted[-1L]))
)
if (
  !identical(overall_rows$estimate, expected_overall_mean) ||
    !identical(overall_rows$confidence_interval, expected_overall_context) ||
    !identical(overall_rows$fdr_p, expected_overall_p)
) {
  stop(
    "Accepted panel-d site-average values do not match their source.",
    call. = FALSE
  )
}

category_support <- readr::read_csv(
  input_path("artifacts/06_model_data/H04/H04_category_support.csv"),
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
if (!identical(as.character(category_support$activity), activity_order)) {
  stop("The accepted five-category support order has drifted.", call. = FALSE)
}
if (
  sum(category_support$long_rows) != 16875L ||
    abs(sum(category_support$effective_weighted_hours) - 16135) > 1e-8 ||
    any(category_support$sites != 9L)
) {
  stop("The accepted five-category support totals have drifted.", call. = FALSE)
}

sensitivity_table <- xml2::xml_find_first(
  accepted_html,
  '//*[@id="tbl-h04-sensitivities"]//table'
)
sensitivity_text <- stringr::str_squish(xml2::xml_text(sensitivity_table))
frame_token <- "126 / 724 / 16,135 / 16,875 / 16,135"
if (!stringr::str_detect(sensitivity_text, stringr::fixed(frame_token))) {
  stop("The accepted five-category frame token is missing.", call. = FALSE)
}

frame_contract <- tibble::tibble(
  participants = 126L,
  participant_days = 724L,
  unique_participant_hours = 16135L,
  generated_long_rows = 16875L,
  effective_weighted_hours = 16135,
  sites = 9L,
  exact_zero_participant_hours = 4746L,
  retained_categories = 5L,
  site_category_cells = 45L,
  estimable_family_members = 44L,
  fdr_labelled_site_deviations = 17L
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
readr::write_csv(
  frozen_inputs[c("path", "sha256", "observed_sha256")],
  input_identity_path
)

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
panel_height <- 730
left_margin <- 68.89
right_margin <- 31.36
site_width <- 160
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
  ),
  svg_text(
    16,
    28,
    "D",
    size = 14,
    weight = "bold",
    anchor = "start"
  )
)

header_top <- 60
header_bottom <- 138
overall_bottom <- 218
site_row_height <- 40
site_bottom <- overall_bottom + 9 * site_row_height
panel_d_lines <- c(
  panel_d_lines,
  sprintf(
    paste0(
      "<rect x='%.2f' y='%d' width='%.2f' height='%d' ",
      "style='stroke: none; fill: #D0D4D8;'/>"
    ),
    left_margin,
    header_top,
    panel_width - left_margin - right_margin,
    header_bottom - header_top
  ),
  sprintf(
    paste0(
      "<rect x='%.2f' y='%d' width='%.2f' height='%d' ",
      "style='stroke: none; fill: #E8EEF3;'/>"
    ),
    left_margin,
    header_bottom,
    panel_width - left_margin - right_margin,
    overall_bottom - header_bottom
  )
)
for (row_index in seq_len(9L)) {
  row_top <- overall_bottom + (row_index - 1L) * site_row_height
  fill <- if (row_index %% 2L == 0L) "#F4F6F8" else "#FFFFFF"
  panel_d_lines <- c(
    panel_d_lines,
    sprintf(
      paste0(
        "<rect x='%.2f' y='%.2f' width='%.2f' height='%.2f' ",
        "style='stroke: none; fill: %s;'/>"
      ),
      left_margin,
      row_top,
      panel_width - left_margin - right_margin,
      site_row_height,
      fill
    )
  )
}

panel_d_lines <- c(
  panel_d_lines,
  svg_text(left_margin + 8, 102, "Site", size = 15.5, weight = "bold")
)
header_line_breaks <- list(
  c("At home"),
  c("Office/home", "working"),
  c("Outdoors"),
  c("Vehicle/public", "transport"),
  c("Sleeping")
)
for (index in seq_along(activity_order)) {
  center <- column_lefts[[index + 1L]] + category_width / 2
  header_lines <- header_line_breaks[[index]]
  header_y <- if (length(header_lines) == 1L) 78 else c(70, 84)
  panel_d_lines <- c(
    panel_d_lines,
    vapply(
      seq_along(header_lines),
      function(line_index) {
        svg_text(
          center,
          header_y[[line_index]],
          header_lines[[line_index]],
          size = 14.5,
          weight = "bold",
          anchor = "middle"
        )
      },
      character(1)
    )
  )
  support <- category_support[index, , drop = FALSE]
  support_lines <- c(
    sprintf("P %d · D %d", support$participants, support$participant_days),
    sprintf(
      "H %s · R %s",
      format(
        support$unique_participant_hours,
        big.mark = ",",
        scientific = FALSE
      ),
      format(support$long_rows, big.mark = ",", scientific = FALSE)
    ),
    sprintf(
      "WH %s · S %d",
      formatC(
        support$effective_weighted_hours,
        format = "f",
        digits = 1,
        big.mark = ","
      ),
      support$sites
    )
  )
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
      seq_along(support_lines),
      function(line_index) {
        svg_text(
          center,
          95 + (line_index - 1) * 15,
          support_lines[[line_index]],
          size = 12.3,
          anchor = "middle",
          fill = "#46515C"
        )
      },
      character(1)
    ),
    "</g>"
  )
}

panel_d_lines <- c(
  panel_d_lines,
  svg_text(
    left_margin + 8,
    header_bottom + 33,
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
  cell <- overall_rows[index, , drop = FALSE]
  x <- column_lefts[[index + 1L]] + 8
  panel_d_lines <- c(
    panel_d_lines,
    sprintf(
      paste0(
        "<g class='panel-d-cell' data-row-type='site_average' ",
        "data-site='Site-average estimate' data-activity='%s' ",
        "data-estimable='true' data-fdr-label='%s'>"
      ),
      xml_escape(cell$activity),
      tolower(as.character(cell$fdr_label))
    )
  )
  if (identical(cell$activity, "At home")) {
    panel_d_lines <- c(
      panel_d_lines,
      svg_text(
        x,
        header_bottom + 27,
        cell$estimate,
        size = 14.2,
        weight = "bold"
      ),
      svg_text(x, header_bottom + 48, cell$confidence_interval, size = 12.5),
      svg_text(x, header_bottom + 68, cell$fdr_p, size = 12.5)
    )
  } else {
    comparison_without_reference <- sub(
      " At home$",
      "",
      cell$confidence_interval
    )
    panel_d_lines <- c(
      panel_d_lines,
      svg_text(
        x,
        header_bottom + 20,
        cell$estimate,
        size = 14.2,
        weight = "bold"
      ),
      svg_text(
        x,
        header_bottom + 39,
        comparison_without_reference,
        size = 12.5
      ),
      svg_text(x, header_bottom + 53, "At home", size = 12.5),
      svg_text(x, header_bottom + 70, cell$fdr_p, size = 12.5)
    )
  }
  panel_d_lines <- c(panel_d_lines, "</g>")
}

site_order <- unique(site_rows$site)
for (site_index in seq_along(site_order)) {
  site <- site_order[[site_index]]
  row_data <- site_rows[site_rows$site == site, , drop = FALSE]
  row_data <- row_data[match(activity_order, row_data$activity), , drop = FALSE]
  row_top <- overall_bottom + (site_index - 1L) * site_row_height
  site_color <- row_data$site_color[[1]]
  panel_d_lines <- c(
    panel_d_lines,
    sprintf(
      paste0(
        "<circle cx='%.2f' cy='%.2f' r='5.2' ",
        "style='stroke: none; fill: %s;'/>"
      ),
      left_margin + 13,
      row_top + site_row_height / 2,
      site_color
    ),
    svg_text(
      left_margin + 25,
      row_top + 25,
      site,
      size = 14.2
    )
  )
  for (activity_index in seq_along(activity_order)) {
    cell <- row_data[activity_index, , drop = FALSE]
    x <- column_lefts[[activity_index + 1L]] + 8
    panel_d_lines <- c(
      panel_d_lines,
      sprintf(
        paste0(
          "<g class='panel-d-cell' data-row-type='site_deviation' ",
          "data-site='%s' data-activity='%s' data-estimable='%s' ",
          "data-fdr-label='%s'>"
        ),
        xml_escape(cell$site),
        xml_escape(cell$activity),
        tolower(as.character(cell$estimable)),
        tolower(as.character(cell$fdr_label))
      )
    )
    if (!cell$estimable) {
      panel_d_lines <- c(
        panel_d_lines,
        svg_text(
          x,
          row_top + 25,
          "Not estimable",
          size = 13.2,
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
          row_top + 16,
          estimate_with_interval,
          size = 12.8,
          weight = weight
        ),
        svg_text(
          x,
          row_top + 33,
          cell$fdr_p,
          size = 12.2,
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
    function(x)
      sprintf(
        paste0(
          "<line x1='%.2f' y1='%d' x2='%.2f' y2='%d' ",
          "style='stroke-width: 0.8; stroke: #BCC6CE;'/>"
        ),
        x,
        header_top,
        x,
        site_bottom
      ),
    character(1)
  ),
  vapply(
    c(header_top, header_bottom, overall_bottom, site_bottom),
    function(y)
      sprintf(
        paste0(
          "<line x1='%.2f' y1='%.2f' x2='%.2f' y2='%.2f' ",
          "style='stroke-width: 1.1; stroke: #8192A3;'/>"
        ),
        left_margin,
        y,
        panel_width - right_margin,
        y
      ),
    character(1)
  )
)

footer_lines <- c(
  "Site-average estimates and comparisons use the activity-by-site interaction model.",
  paste(
    "Site rows are deviation ratios around the corresponding category estimate;",
    "parentheses give 95% confidence intervals."
  ),
  paste(
    "Bold site ratios and FDR p-values pass the complete 44-member near-eye family.",
    "San José (CR), Outdoors is not estimable."
  ),
  paste(
    "Five-category frame: 126 participants; 724 participant-days;",
    "16,135 unique participant-hours; 16,875 generated long rows;"
  ),
  paste(
    "16,135 effective weighted hours; nine sites;",
    "4,746 exact-zero participant-hours."
  ),
  paste(
    "Each multi-select participant-hour contributes 1/k across retained categories.",
    "Other/unspecified activity is absent from panel d."
  ),
  paste(
    "P, participants; D, participant-days; H, unique participant-hours;",
    "R, long rows; WH, effective weighted hours; S, sites."
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
        size = 12.3,
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
  "<g id='panel-d'>",
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
  "A",
  "A",
  1102.64,
  16,
  27.29,
  1080,
  7,
  30,
  28,
  8,
  7,
  30,
  28,
  "B",
  "B",
  1102.64,
  16,
  308.04,
  1080,
  288,
  30,
  28,
  8,
  288,
  30,
  28,
  "C",
  "C",
  1102.64,
  16,
  564.24,
  1080,
  544,
  30,
  28,
  8,
  544,
  30,
  28
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
  "<!-- BEGIN TEMPORAL PANELS -->",
  "<g id='temporal-panels'>",
  temporal_inner,
  "</g>",
  "<!-- END TEMPORAL PANELS -->",
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

accepted_png <- png::readPNG(input_path(
  "artifacts/10_figures/H04/H04_temporal_near_eye.png"
))
if (!identical(dim(accepted_png), c(3750L, 4725L, 3L))) {
  stop("Unexpected accepted temporal PNG dimensions.", call. = FALSE)
}
pixels_per_point <- dim(accepted_png)[[2]] / panel_width
candidate_top <- accepted_png
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
    new_tag_pixels$x_start[[index]] +
    1L
  pixel_height <- new_tag_pixels$y_end[[index]] -
    new_tag_pixels$y_start[[index]] +
    1L
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
  tile_raw <- magick::image_write(tile_image, format = "png")
  tile_pixels <- png::readPNG(tile_raw)
  expected_tile_dimension <- as.integer(c(pixel_height, pixel_width, 3L))
  if (!identical(dim(tile_pixels), expected_tile_dimension)) {
    stop("Unexpected rasterized panel-tag dimensions.", call. = FALSE)
  }
  candidate_top[
    new_tag_pixels$y_start[[index]]:new_tag_pixels$y_end[[index]],
    new_tag_pixels$x_start[[index]]:new_tag_pixels$x_end[[index]],
  ] <- tile_pixels
}

tag_box_path <- file.path(
  output_directory,
  "H04_manuscript_figure3_temporal_tag_boxes.csv"
)
readr::write_csv(
  rbind(old_tag_pixels, new_tag_pixels)[c(
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
  )],
  tag_box_path
)

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
  stop(
    "The panel-d raster does not match the accepted temporal width.",
    call. = FALSE
  )
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
panel_rows <- seq.int(
  dim(candidate_top)[[1]] + 1L,
  dim(candidate_png)[[1]]
)
candidate_png[panel_rows, , ] <- panel_d_png

candidate_png_path <- file.path(
  output_directory,
  "H04_manuscript_figure3_candidate.png"
)
png::writePNG(candidate_png, candidate_png_path, dpi = 300)
rm(accepted_png, candidate_top, panel_d_png, candidate_png)
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
    "activity-associated melEDI by",
    "local time, ratios to the global cyclic smooth, and effective weighted",
    "support."
  ),
  paste(
    "Panel **D** shows site-average category estimates and site-specific",
    "deviation ratios from the activity-by-site interaction model."
  ),
  paste(
    "Site ratios are followed by 95% confidence intervals in parentheses.",
    "Bold site cells pass the complete near-eye FDR adjustment; San José",
    "(CR), Outdoors is not estimable."
  ),
  paste(
    "The five-category frame comprises 126 participants, 724",
    "participant-days, 16,135 unique participant-hours, 16,875 generated",
    "long rows, 16,135 effective weighted hours, nine sites, and 4,746",
    "exact-zero participant-hours."
  ),
  paste(
    "Each multi-select participant-hour contributes 1/k across retained",
    "categories. Other/unspecified activity is display-only in panels",
    "**A**, **B**, and **C** and absent from panel **D**."
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
  sha256 = vapply(
    output_paths,
    digest::digest,
    character(1),
    algo = "sha256",
    file = TRUE
  ),
  bytes = as.numeric(file.info(output_paths)$size),
  r_version = as.character(getRversion())
)
readr::write_csv(
  output_manifest,
  file.path(output_directory, "H04_manuscript_figure3_candidate_outputs.csv")
)

message(
  "H04 manuscript Figure 3 candidate written to ",
  output_directory
)
