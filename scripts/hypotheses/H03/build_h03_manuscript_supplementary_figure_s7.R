#!/usr/bin/env Rscript

# Build H03 manuscript Supplementary Figure S7 from frozen displays.

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
    "The H03 Supplementary Figure S7 builder requires R 4.6.1; found ",
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

output_root <- Sys.getenv("H03_S7_OUTPUT_ROOT", unset = "")
if (!nzchar(output_root) || !dir.exists(output_root)) {
  stop(
    "Set `H03_S7_OUTPUT_ROOT` to an existing candidate or project root.",
    call. = FALSE
  )
}
output_root <- normalizePath(output_root, winslash = "/", mustWork = TRUE)
final_mode <- identical(
  tolower(Sys.getenv("H03_S7_FINAL_MODE", unset = "false")),
  "true"
)
visual_qa_confirmed <- identical(
  tolower(Sys.getenv("H03_S7_VISUAL_QA_CONFIRMED", unset = "false")),
  "true"
)
candidate_root <- Sys.getenv("H03_S7_CANDIDATE_ROOT", unset = "")
if (final_mode) {
  if (!visual_qa_confirmed) {
    stop(
      "Final mode requires confirmed candidate-first visual QA.",
      call. = FALSE
    )
  }
  if (!nzchar(candidate_root) || !dir.exists(candidate_root)) {
    stop("Final mode requires the inspected candidate root.", call. = FALSE)
  }
  candidate_root <- normalizePath(
    candidate_root,
    winslash = "/",
    mustWork = TRUE
  )
}

input_path <- function(path) file.path(root, path)
sha256 <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE)
}

frozen_inputs <- tibble::tribble(
  ~role,
  ~path,
  ~sha256_expected,
  "reader_source",
  "notebooks/hypotheses/H03.qmd",
  "45ea5a009efd3b451c392dfc23bef584c7b16e087bf4093780b051cfde42ae41",
  "site_display_registry",
  "config/site_display_registry.csv",
  "3d669d459ecc27d3154bbb5ff5b0d64cb510805d486b45264443228c44a6d809",
  "accepted_reader_html",
  "_build/nathealth/notebooks/hypotheses/H03.html",
  "1ad80c1574ada455e978ce905a1e5bb4f53b0392bf5e4433cdeac41da85f7cac",
  "accepted_temporal_png",
  "artifacts/10_figures/H03/H03_reader_temporal_near_eye.png",
  "8455a5824c3b232040a92ee604cc7ce30360c814bf1f5e2293fc5b8ef74c7a00",
  "accepted_temporal_svg",
  "artifacts/10_figures/H03/H03_reader_temporal_near_eye.svg",
  "15b590b38c1b9e2f7559560a1854513a85c5c4920ffdd387f480793f5c15d3e1",
  "accepted_temporal_pdf",
  "artifacts/10_figures/H03/H03_reader_temporal_near_eye.pdf",
  "41d3658cd344f454d986eaa5c757460218360c384349a5a2deed2ab4251f4bd6",
  "temporal_curves",
  "artifacts/11_source_data/H03/H03_reader_temporal_near_eye_curves.csv",
  "75de4f208a2b2c36c425df9418227efce59c97e4d1224b664f609e479c8855ff",
  "temporal_ratios",
  "artifacts/11_source_data/H03/H03_reader_temporal_near_eye_ratios.csv",
  "a54048d97a94b76a8ed73d12c367898e999666deb9ba17226dd684ce9fe89163",
  "temporal_global",
  "artifacts/11_source_data/H03/H03_reader_temporal_near_eye_global.csv",
  "0405c3409866199f714a48ba030516bcff913f674b50828477a6f950bdb8a18a",
  "temporal_support",
  "artifacts/11_source_data/H03/H03_reader_temporal_near_eye_support.csv",
  "066fdec22f4d43b9f5458253ec20a4f91fb3f65c65ca88cd1d06f2da0227ca3a",
  "temporal_model_summary",
  "artifacts/09_tables/H03/H03_reader_temporal_model_summary.csv",
  "289e5900afefc964c3d119f874ebc909daf9b51972807d3ea14659b509dc036b",
  "site_factorization_source",
  "artifacts/09_tables/H03/H03_site_context_estimands.csv",
  "cfc977c1251d95ca158cfb6cedc778c6a81c2215a7aa13981f6b44f976e71903",
  "category_support",
  "artifacts/06_model_data/H03/H03_category_support.csv",
  "41e373fabddb3b77cd66c1ed822f42a597754c4c65bbf90782f9f7425bce8ad5",
  "accepted_factorization_fragment",
  paste0(
    "audit/manuscript_nature_health/figure_table_selection_assets/",
    "tbl-h03-near-site-factorization.html"
  ),
  "0cfa95366ddae4d83725e6983908ac23c23f40fefb6a32346caa83279cc964c8"
)
frozen_inputs$absolute_path <- input_path(frozen_inputs$path)
missing_inputs <- frozen_inputs$path[!file.exists(frozen_inputs$absolute_path)]
if (length(missing_inputs) > 0L) {
  stop(
    "Missing frozen H03 input(s): ",
    paste(missing_inputs, collapse = ", "),
    call. = FALSE
  )
}
frozen_inputs$sha256_observed <- vapply(
  frozen_inputs$absolute_path,
  sha256,
  character(1)
)
if (!all(frozen_inputs$sha256_expected == frozen_inputs$sha256_observed)) {
  failed <- frozen_inputs$path[
    frozen_inputs$sha256_expected != frozen_inputs$sha256_observed
  ]
  stop(
    "Frozen H03 input identity drift: ",
    paste(failed, collapse = ", "),
    call. = FALSE
  )
}

category_order <- c(
  "Indoor electric",
  "Outdoor electric",
  "Indoor daylight",
  "Outdoor daylight",
  "Emissive display",
  "Sleep darkness",
  "External light during sleep"
)
category_palette <- stats::setNames(
  c(
    "#4477AA",
    "#EE6677",
    "#228833",
    "#CCBB44",
    "#66CCEE",
    "#AA3377",
    "#777777"
  ),
  category_order
)
site_order <- c(
  "Borås (SE)",
  "Delft (NL)",
  "Dortmund (DE)",
  "Tübingen (DE)",
  "Munich (DE)",
  "Madrid (ES)",
  "Izmir (TR)",
  "San José (CR)",
  "Kumasi (GH)"
)
site_registry <- readr::read_csv(
  input_path("config/site_display_registry.csv"),
  show_col_types = FALSE
)
site_registry <- site_registry[
  match(site_order, site_registry$display_name),
  ,
  drop = FALSE
]
site_palette <- stats::setNames(
  site_registry$color_hex,
  site_registry$display_name
)
if (
  anyNA(site_registry$display_name) ||
    !identical(as.integer(site_registry$display_order), seq_along(site_order)) ||
    !identical(names(site_palette), site_order) ||
    length(intersect(unname(category_palette), unname(site_palette))) != 0L
) {
  stop("The accepted site display registry has drifted.", call. = FALSE)
}

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
  "_build/nathealth/notebooks/hypotheses/H03.html"
))
factorization_table <- xml2::xml_find_first(
  accepted_html,
  '//*[@id="tbl-h03-near-site-factorization"]//table'
)
if (inherits(factorization_table, "xml_missing")) {
  stop("The accepted H03 factorization table is missing.", call. = FALSE)
}
header_nodes <- xml2::xml_find_all(factorization_table, ".//thead//th")
header_labels <- vapply(
  header_nodes,
  function(node) paste(node_lines(node), collapse = " "),
  character(1)
)
if (!identical(header_labels, c("Site", category_order))) {
  stop("Accepted H03 factorization headers have drifted.", call. = FALSE)
}

body_rows <- xml2::xml_find_all(factorization_table, ".//tbody/tr")
if (length(body_rows) != 11L) {
  stop(
    "Expected one overall row, one separator, and nine site rows.",
    call. = FALSE
  )
}
body_cell_counts <- vapply(
  body_rows,
  function(row) length(xml2::xml_find_all(row, "./td")),
  integer(1)
)
if (!identical(body_cell_counts, rep(8L, 11L))) {
  stop("Accepted H03 factorization row structure has drifted.", call. = FALSE)
}

overall_cells <- xml2::xml_find_all(body_rows[[1]], "./td")
overall_html <- do.call(
  rbind,
  lapply(seq_along(category_order), function(index) {
    tibble::tibble(
      category = category_order[[index]],
      accepted_lines = list(node_lines(overall_cells[[index + 1L]]))
    )
  })
)

site_html <- do.call(
  rbind,
  lapply(body_rows[3:11], function(row) {
    cells <- xml2::xml_find_all(row, "./td")
    site <- sub("^●[[:space:]]*", "", node_lines(cells[[1]])[[1]])
    do.call(
      rbind,
      lapply(seq_along(category_order), function(index) {
        cell <- cells[[index + 1L]]
        lines <- node_lines(cell)
        tibble::tibble(
          site = site,
          category = category_order[[index]],
          accepted_lines = list(lines),
          estimable = !identical(lines[[1]], "Not estimable"),
          fdr_label = length(xml2::xml_find_all(cell, ".//strong")) > 0L
        )
      })
    )
  })
)
if (
  !identical(unique(site_html$site), site_order) ||
    nrow(site_html) != 63L ||
    sum(site_html$fdr_label) != 21L
) {
  stop("Accepted H03 site rows or FDR labels have drifted.", call. = FALSE)
}

site_context <- readr::read_csv(
  input_path("artifacts/09_tables/H03/H03_site_context_estimands.csv"),
  show_col_types = FALSE
)
site_context <- site_context[
  site_context$placement == "Near-eye" &
    site_context$short_label %in% category_order,
  ,
  drop = FALSE
]
site_context <- site_context[
  order(site_context$display_order, site_context$category_order),
  ,
  drop = FALSE
]
if (
  nrow(site_context) != 63L ||
    !identical(unique(site_context$site_display_name), site_order)
) {
  stop("The frozen H03 site-context structure has drifted.", call. = FALSE)
}

overall_source <- site_context[
  !duplicated(site_context$category_order),
  ,
  drop = FALSE
]
overall_source <- overall_source[
  match(category_order, overall_source$short_label),
  ,
  drop = FALSE
]
if (!identical(as.character(overall_source$short_label), category_order)) {
  stop("The frozen H03 category order has drifted.", call. = FALSE)
}

expected_overall_lines <- lapply(seq_along(category_order), function(index) {
  row <- overall_source[index, , drop = FALSE]
  result <- c(
    sprintf("%.1f lx", row$site_standardized_category_mean_lx),
    sprintf(
      "mean CI %.1f–%.1f",
      row$category_mean_conf_low_lx,
      row$category_mean_conf_high_lx
    )
  )
  if (index == 1L) {
    c(result, "1.000× reference")
  } else {
    c(
      result,
      sprintf("%.3f× indoor", row$category_ratio_to_indoor),
      sprintf(
        "ratio CI %.3f–%.3f",
        row$category_ratio_conf_low,
        row$category_ratio_conf_high
      )
    )
  }
})
if (
  !all(vapply(
    seq_along(category_order),
    function(index) {
      identical(
        overall_html$accepted_lines[[index]],
        expected_overall_lines[[index]]
      )
    },
    logical(1)
  ))
) {
  stop("Accepted H03 site-average printed values have drifted.", call. = FALSE)
}

site_context$key <- paste(
  site_context$site_display_name,
  site_context$short_label,
  sep = "\r"
)
site_html$key <- paste(site_html$site, site_html$category, sep = "\r")
site_html <- site_html[match(site_context$key, site_html$key), , drop = FALSE]
if (anyNA(site_html$key)) {
  stop(
    "Accepted H03 site cells did not join to frozen source rows.",
    call. = FALSE
  )
}
expected_site_lines <- lapply(seq_len(nrow(site_context)), function(index) {
  row <- site_context[index, , drop = FALSE]
  if (!identical(row$reporting_status[[1]], "ESTIMABLE")) {
    "Not estimable"
  } else {
    c(
      sprintf("%.2f×", row$site_deviation_ratio),
      sprintf(
        "95%% CI %.2f–%.2f",
        row$site_deviation_conf_low,
        row$site_deviation_conf_high
      )
    )
  }
})
if (
  !all(vapply(
    seq_len(nrow(site_context)),
    function(index) {
      identical(site_html$accepted_lines[[index]], expected_site_lines[[index]])
    },
    logical(1)
  ))
) {
  stop("Accepted H03 site-cell printed values have drifted.", call. = FALSE)
}
site_context$fdr_label <- site_html$fdr_label

category_support <- readr::read_csv(
  input_path("artifacts/06_model_data/H03/H03_category_support.csv"),
  show_col_types = FALSE
)
category_support <- category_support[
  category_support$placement == "Near-eye" &
    category_support$short_label %in% category_order,
  ,
  drop = FALSE
]
category_support <- category_support[
  match(category_order, category_support$short_label),
  ,
  drop = FALSE
]
if (
  !identical(as.character(category_support$short_label), category_order) ||
    !identical(
      as.integer(category_support$hours),
      c(4629L, 203L, 4804L, 1557L, 664L, 5225L, 853L)
    ) ||
    !identical(
      as.integer(category_support$participants),
      c(138L, 54L, 138L, 135L, 88L, 130L, 66L)
    ) ||
    !identical(
      as.integer(category_support$participant_days),
      c(695L, 118L, 692L, 512L, 235L, 712L, 233L)
    ) ||
    !identical(as.integer(category_support$sites), rep(9L, 7L))
) {
  stop("The frozen H03 category-support contract has drifted.", call. = FALSE)
}

temporal_summary <- readr::read_csv(
  input_path("artifacts/09_tables/H03/H03_reader_temporal_model_summary.csv"),
  show_col_types = FALSE
)
temporal_summary <- temporal_summary[
  temporal_summary$placement == "Near-eye",
  ,
  drop = FALSE
]
if (
  nrow(temporal_summary) != 1L ||
    temporal_summary$observations[[1]] != 17935L ||
    temporal_summary$participants[[1]] != 140L ||
    temporal_summary$participant_days[[1]] != 801L ||
    temporal_summary$sites[[1]] != 9L ||
    temporal_summary$categories[[1]] != 7L
) {
  stop("The frozen H03 temporal frame contract has drifted.", call. = FALSE)
}

temporal_curves <- readr::read_csv(
  input_path(
    "artifacts/11_source_data/H03/H03_reader_temporal_near_eye_curves.csv"
  ),
  show_col_types = FALSE
)
if (
  !all(temporal_curves$site_effects_excluded) ||
    !identical(unique(temporal_curves$placement), "Near-eye")
) {
  stop("The frozen H03 temporal source-model flag has drifted.", call. = FALSE)
}

format_p <- function(value) {
  ifelse(value < 0.001, "<0.001", sprintf("%.3f", value))
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

figure_directory <- file.path(
  output_root,
  "artifacts/10_figures/H03"
)
manifest_directory <- file.path(
  output_root,
  "artifacts/12_manifests/H03"
)
diagnostic_directory <- file.path(
  output_root,
  "artifacts/08_diagnostics/H03"
)
dir.create(figure_directory, recursive = TRUE, showWarnings = FALSE)
dir.create(manifest_directory, recursive = TRUE, showWarnings = FALSE)
dir.create(diagnostic_directory, recursive = TRUE, showWarnings = FALSE)

figure_stem <- "H03_manuscript_supplementary_figure_S7"
svg_output <- file.path(figure_directory, paste0(figure_stem, ".svg"))
png_output <- file.path(figure_directory, paste0(figure_stem, ".png"))
pdf_output <- file.path(figure_directory, paste0(figure_stem, ".pdf"))
manifest_output <- file.path(
  manifest_directory,
  paste0(figure_stem, "_manifest.csv")
)
qa_output <- file.path(
  diagnostic_directory,
  paste0(figure_stem, "_display_qa.csv")
)

panel_width <- 1134
temporal_height <- 748.8
composite_height <- 1770
panel_d_height <- composite_height - temporal_height
left_margin <- 67.89
right_margin <- 24
site_width <- 145
category_width <- (panel_width - left_margin - right_margin - site_width) /
  length(category_order)
column_lefts <- c(
  left_margin,
  left_margin + site_width + (seq_along(category_order) - 1) * category_width
)
column_rights <- c(
  left_margin + site_width,
  left_margin + site_width + seq_along(category_order) * category_width
)

panel_d_lines <- c(
  sprintf(
    paste0(
      "<rect x='0' y='0' width='%d' height='%.2f' ",
      "style='stroke: none; fill: #FFFFFF;'/>"
    ),
    panel_width,
    panel_d_height
  ),
  svg_text(
    14.94,
    28,
    "D",
    size = 14,
    weight = "bold"
  ),
  svg_text(
    left_margin,
    28,
    "Near-eye light-source-by-site interaction model",
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
for (row_index in seq_along(site_order)) {
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

header_line_breaks <- list(
  c("Indoor", "electric"),
  c("Outdoor", "electric"),
  c("Indoor", "daylight"),
  c("Outdoor", "daylight"),
  c("Emissive", "display"),
  c("Sleep", "darkness"),
  c("External light", "during sleep")
)
for (index in seq_along(category_order)) {
  center <- column_lefts[[index + 1L]] + category_width / 2
  header_lines <- header_line_breaks[[index]]
  support <- category_support[index, , drop = FALSE]
  support_line <- sprintf(
    "P %d · D %d · H %s",
    support$participants,
    support$participant_days,
    format(support$hours, big.mark = ",", scientific = FALSE)
  )
  panel_d_lines <- c(
    panel_d_lines,
    sprintf(
      paste0(
        "<g class='category-support' data-category='%s' ",
        "data-participants='%d' data-participant-days='%d' ",
        "data-participant-hours='%d' data-sites='%d'>"
      ),
      xml_escape(category_order[[index]]),
      support$participants,
      support$participant_days,
      support$hours,
      support$sites
    ),
    svg_text(
      center,
      74,
      header_lines[[1]],
      size = 12.8,
      weight = "bold",
      anchor = "middle"
    ),
    svg_text(
      center,
      89,
      header_lines[[2]],
      size = 12.8,
      weight = "bold",
      anchor = "middle"
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
for (index in seq_along(category_order)) {
  row <- overall_source[index, , drop = FALSE]
  x <- column_lefts[[index + 1L]] + 5
  ratio_line <- if (index == 1L) {
    "1.000× reference"
  } else {
    sprintf("%.3f× indoor", row$category_ratio_to_indoor)
  }
  panel_d_lines <- c(
    panel_d_lines,
    sprintf(
      paste0(
        "<g class='panel-d-cell' data-row-type='site_average' ",
        "data-category='%s' data-estimable='true'>"
      ),
      xml_escape(category_order[[index]])
    ),
    svg_text(
      x,
      header_bottom + 18,
      sprintf("%.1f lx", row$site_standardized_category_mean_lx),
      size = 13.3,
      weight = "bold"
    ),
    svg_text(
      x,
      header_bottom + 36,
      sprintf(
        "95%% CI %.1f–%.1f",
        row$category_mean_conf_low_lx,
        row$category_mean_conf_high_lx
      ),
      size = 11.2,
      fill = "#46515C"
    ),
    svg_text(
      x,
      header_bottom + 55,
      ratio_line,
      size = 11.7,
      weight = "bold"
    )
  )
  if (index != 1L) {
    panel_d_lines <- c(
      panel_d_lines,
      svg_text(
        x,
        header_bottom + 73,
        sprintf(
          "95%% CI %.3f–%.3f",
          row$category_ratio_conf_low,
          row$category_ratio_conf_high
        ),
        size = 10.8,
        fill = "#46515C"
      )
    )
  }
  panel_d_lines <- c(panel_d_lines, "</g>")
}

for (site_index in seq_along(site_order)) {
  site <- site_order[[site_index]]
  row_data <- site_context[
    site_context$site_display_name == site,
    ,
    drop = FALSE
  ]
  row_data <- row_data[
    match(category_order, row_data$short_label),
    ,
    drop = FALSE
  ]
  row_top <- overall_bottom + (site_index - 1L) * site_row_height
  site_color <- site_palette[[site]]
  panel_d_lines <- c(
    panel_d_lines,
    sprintf(
      paste0(
        "<circle cx='%.2f' cy='%.2f' r='5.5' ",
        "style='stroke: none; fill: %s;'/>"
      ),
      left_margin + 13,
      row_top + site_row_height / 2,
      site_color
    ),
    svg_text(
      left_margin + 25,
      row_top + 29,
      site,
      size = 14
    )
  )
  for (category_index in seq_along(category_order)) {
    cell <- row_data[category_index, , drop = FALSE]
    x <- column_lefts[[category_index + 1L]] + 5
    estimable <- identical(cell$reporting_status[[1]], "ESTIMABLE")
    panel_d_lines <- c(
      panel_d_lines,
      sprintf(
        paste0(
          "<g class='panel-d-cell' data-row-type='site_deviation' ",
          "data-site='%s' data-category='%s' data-estimable='%s' ",
          "data-fdr-label='%s' data-hours='%d' data-participants='%d' ",
          "data-participant-days='%d' data-shared-participants='%d' ",
          "data-support-rule-pass='%s' data-reporting-status='%s' ",
          "data-architecture='%s'>"
        ),
        xml_escape(site),
        xml_escape(category_order[[category_index]]),
        tolower(as.character(estimable)),
        tolower(as.character(cell$fdr_label[[1]])),
        cell$hours,
        cell$participants,
        cell$participant_days,
        cell$shared_participants,
        tolower(as.character(cell$support_rule_pass)),
        xml_escape(cell$reporting_status),
        xml_escape(cell$architecture)
      )
    )
    if (!estimable) {
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
      weight <- if (cell$fdr_label[[1]]) "bold" else "normal"
      panel_d_lines <- c(
        panel_d_lines,
        svg_text(
          x,
          row_top + 18,
          sprintf(
            "%.2f× (%.2f–%.2f)",
            cell$site_deviation_ratio,
            cell$site_deviation_conf_low,
            cell$site_deviation_conf_high
          ),
          size = 10.6,
          weight = weight
        ),
        svg_text(
          x,
          row_top + 37,
          paste("FDR p", format_p(cell$site_deviation_p_adjusted)),
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
          "style='stroke-width: 0.8; stroke: #BCC6CE;'/>"
        ),
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
          "style='stroke-width: 1.1; stroke: #8192A3;'/>"
        ),
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
    "Site-average estimates and comparisons use the light-source-by-site",
    "interaction model."
  ),
  paste(
    "Site rows are deviation ratios around each category estimate;",
    "parentheses show 95% confidence intervals."
  ),
  paste(
    "Bold site ratios and FDR p-values pass the complete 53-member near-eye",
    "family; unsupported cells are not estimable."
  ),
  paste(
    "Near-eye frame: 17,935 participant-hours; 140 participants;",
    "801 participant-days; nine sites."
  ),
  paste(
    "Each accepted participant-hour has one primary light-source category; 1/k",
    "multi-label weighting does not apply."
  ),
  paste(
    "Panels A–C exclude site, participant, and participant-day smooths from",
    "displayed curves; panel D uses stored interaction-model estimands."
  ),
  paste(
    "P, participants; D, participant-days; H, participant-hours.",
    "Country-coded labels and row order provide non-colour site cues."
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
        size = 11.2,
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
      "<svg xmlns='http://www.w3.org/2000/svg' width='%.2fpt' ",
      "height='%.2fpt' viewBox='0 0 %.2f %.2f'>"
    ),
    panel_width,
    panel_d_height,
    panel_width,
    panel_d_height
  ),
  "<g id='panel-d' data-source-model='light-source-by-site interaction model'>",
  panel_d_lines,
  "</g>",
  "</svg>"
)
panel_d_svg_path <- tempfile("H03_S7_panel_d_", fileext = ".svg")
writeLines(panel_d_svg_lines, panel_d_svg_path, useBytes = TRUE)

accepted_svg_lines <- readLines(
  input_path("artifacts/10_figures/H03/H03_reader_temporal_near_eye.svg"),
  warn = FALSE,
  encoding = "UTF-8"
)
root_open <- grep("^<svg ", accepted_svg_lines)
root_close <- tail(grep("^</svg>$", accepted_svg_lines), 1L)
if (length(root_open) != 1L || length(root_close) != 1L) {
  stop("Unexpected accepted H03 temporal SVG root structure.", call. = FALSE)
}
temporal_inner <- accepted_svg_lines[(root_open + 1L):(root_close - 1L)]
old_b_axis_label <- paste0(
  "<text transform='translate(24.97,378.83) rotate(-90)' ",
  "text-anchor='middle' style='font-size: 14.00px; ",
  "font-family: \"Arial\";' textLength='184.34px' ",
  "lengthAdjust='spacingAndGlyphs'>Factor relative to global mean</text>"
)
new_b_axis_label <- paste0(
  "<text transform='translate(24.97,378.83) rotate(-90)' ",
  "text-anchor='middle' style='font-size: 14.00px; ",
  "font-family: \"Arial\";'>Ratio to global mean</text>"
)
matched_axis_label <- which(temporal_inner == old_b_axis_label)
if (length(matched_axis_label) != 1L) {
  stop("Expected exactly one accepted panel-B y-axis label.", call. = FALSE)
}
temporal_inner[[matched_axis_label]] <- new_b_axis_label

composite_svg_lines <- c(
  "<?xml version='1.0' encoding='UTF-8' ?>",
  sprintf(
    paste0(
      "<svg xmlns='http://www.w3.org/2000/svg' ",
      "xmlns:xlink='http://www.w3.org/1999/xlink' width='%.2fpt' ",
      "height='%.2fpt' viewBox='0 0 %.2f %.2f'>"
    ),
    panel_width,
    composite_height,
    panel_width,
    composite_height
  ),
  paste0(
    "<g id='temporal-panels' data-site-effects-excluded='true' ",
    "data-weighting='one mutually exclusive category per participant-hour'>"
  ),
  temporal_inner,
  "</g>",
  sprintf(
    paste0(
      "<g id='factorization-panel' transform='translate(0 %.2f)' ",
      "data-source-model='light-source-by-site interaction model'>"
    ),
    temporal_height
  ),
  panel_d_lines,
  "</g>",
  "</svg>"
)
writeLines(composite_svg_lines, svg_output, useBytes = TRUE)

accepted_png <- png::readPNG(input_path(
  "artifacts/10_figures/H03/H03_reader_temporal_near_eye.png"
))
if (!identical(dim(accepted_png), c(3120L, 4725L, 3L))) {
  stop("Unexpected accepted H03 temporal PNG dimensions.", call. = FALSE)
}
candidate_top <- accepted_png
pixels_per_point <- dim(accepted_png)[[2]] / panel_width
axis_label_box <- tibble::tibble(
  box_x = 7,
  box_y = 278,
  box_width = 40,
  box_height = 216,
  x = 24.97,
  y = 378.83,
  c_x = 14.94,
  c_y = 473.80
)
axis_label_box$x_start <- floor(axis_label_box$box_x * pixels_per_point) + 1L
axis_label_box$x_end <- ceiling(
  (axis_label_box$box_x + axis_label_box$box_width) * pixels_per_point
)
axis_label_box$y_start <- floor(axis_label_box$box_y * pixels_per_point) + 1L
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
  sprintf("%.2f", axis_label_box$x - axis_label_box$box_x),
  ",",
  sprintf("%.2f", axis_label_box$y - axis_label_box$box_y),
  ") rotate(-90)' text-anchor='middle' style='font-size: 14.00px; ",
  "font-family: &quot;Arial&quot;;'>Ratio to global mean</text>",
  "<text x='",
  sprintf("%.2f", axis_label_box$c_x - axis_label_box$box_x),
  "' y='",
  sprintf("%.2f", axis_label_box$c_y - axis_label_box$box_y),
  "' style='font-size: 14.00px; font-weight: bold; ",
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
axis_tile_raw <- magick::image_write(axis_tile_image, format = "png")
axis_tile_pixels <- png::readPNG(axis_tile_raw)
if (length(dim(axis_tile_pixels)) == 2L) {
  axis_tile_pixels <- array(
    rep(axis_tile_pixels, 3L),
    dim = c(dim(axis_tile_pixels), 3L)
  )
}
expected_axis_tile_dimension <- as.integer(c(
  axis_tile_height,
  axis_tile_width,
  3L
))
if (!identical(dim(axis_tile_pixels), expected_axis_tile_dimension)) {
  stop("Unexpected rasterized panel-B/C repair tile.", call. = FALSE)
}
candidate_top[
  axis_label_box$y_start:axis_label_box$y_end,
  axis_label_box$x_start:axis_label_box$x_end,
] <- axis_tile_pixels
changed_pixels <- apply(abs(candidate_top - accepted_png) > 0, c(1, 2), any)
allowed_pixels <- matrix(
  FALSE,
  nrow = dim(accepted_png)[[1]],
  ncol = dim(accepted_png)[[2]]
)
allowed_pixels[
  axis_label_box$y_start:axis_label_box$y_end,
  axis_label_box$x_start:axis_label_box$x_end
] <- TRUE
if (!any(changed_pixels) || any(changed_pixels & !allowed_pixels)) {
  stop(
    "Temporal PNG changed outside the panel-B/C repair tile.",
    call. = FALSE
  )
}

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
panel_d_raw <- magick::image_write(panel_d_image, format = "png")
panel_d_png <- png::readPNG(panel_d_raw)
if (!identical(dim(panel_d_png), c(4255L, 4725L, 3L))) {
  stop("Unexpected H03 panel-d raster dimensions.", call. = FALSE)
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
png::writePNG(candidate_png, png_output, dpi = 300)
rm(accepted_png, candidate_top, panel_d_png, candidate_png)
invisible(gc())

pdf_image <- magick::image_read(png_output)
magick::image_write(
  pdf_image,
  path = pdf_output,
  format = "pdf",
  density = "300x300"
)

preview_width <- round(170 / 25.4 * 300)
preview_path <- NA_character_
panel_d_preview_path <- NA_character_
if (!final_mode) {
  preview_directory <- file.path(
    output_root,
    "audit/hypotheses/H03/manuscript_supplementary_figure_s7_candidate"
  )
  dir.create(preview_directory, recursive = TRUE, showWarnings = FALSE)
  preview_image <- magick::image_read(png_output)
  preview_image <- magick::image_resize(
    preview_image,
    paste0(preview_width, "x")
  )
  preview_path <- file.path(
    preview_directory,
    paste0(figure_stem, "_170mm.png")
  )
  magick::image_write(preview_image, preview_path, format = "png")
  panel_d_preview <- magick::image_resize(
    panel_d_image,
    paste0(preview_width, "x")
  )
  panel_d_preview_path <- file.path(
    preview_directory,
    paste0(figure_stem, "_panel_d_170mm.png")
  )
  magick::image_write(
    panel_d_preview,
    panel_d_preview_path,
    format = "png"
  )
}

output_info <- magick::image_info(magick::image_read(png_output))
dimension_ok <-
  output_info$width[[1]] == 4725L && output_info$height[[1]] == 7375L
svg_text_all <- paste(readLines(svg_output, warn = FALSE), collapse = "\n")
capital_tags_ok <- all(vapply(
  LETTERS[1:4],
  function(tag) {
    stringr::str_count(
      svg_text_all,
      stringr::fixed(paste0(">", tag, "</text>"))
    ) ==
      1L
  },
  logical(1)
)) && all(vapply(
  letters[1:4],
  function(tag) {
    stringr::str_count(
      svg_text_all,
      stringr::fixed(paste0(">", tag, "</text>"))
    ) ==
      0L
  },
  logical(1)
))
prohibited_term_absent <- !stringr::str_detect(
  tolower(svg_text_all),
  stringr::fixed("heterogeneity")
)
embedded_support_cells <- stringr::str_count(
  svg_text_all,
  stringr::fixed("data-row-type='site_deviation'")
)
source_flags_ok <-
  stringr::str_detect(
    svg_text_all,
    stringr::fixed("data-site-effects-excluded='true'")
  ) &&
  stringr::str_detect(
    svg_text_all,
    stringr::fixed("data-source-model='light-source-by-site interaction model'")
  )

candidate_identity_ok <- NA
if (final_mode) {
  candidate_figure_directory <- file.path(
    candidate_root,
    "artifacts/10_figures/H03"
  )
  candidate_png_path <- file.path(
    candidate_figure_directory,
    paste0(figure_stem, ".png")
  )
  candidate_svg_path <- file.path(
    candidate_figure_directory,
    paste0(figure_stem, ".svg")
  )
  if (!file.exists(candidate_png_path) || !file.exists(candidate_svg_path)) {
    stop("The inspected candidate figure package is incomplete.", call. = FALSE)
  }
  candidate_identity_ok <-
    identical(sha256(candidate_png_path), sha256(png_output)) &&
    identical(sha256(candidate_svg_path), sha256(svg_output))
  if (!candidate_identity_ok) {
    stop(
      "Final PNG or SVG differs from the inspected candidate.",
      call. = FALSE
    )
  }
}

qa <- tibble::tribble(
  ~gate,
  ~status,
  ~detail,
  "frozen_input_identities",
  "PASS",
  "All frozen H03 reader, temporal, factorization, and support inputs match their sealed SHA-256 values.",
  "accepted_table_value_preservation",
  "PASS",
  "All seven site-average cells and all 63 site-category cells reproduce the accepted printed values and intervals.",
  "accepted_fdr_decisions",
  "PASS",
  "All accepted panel-d FDR emphasis decisions are preserved; displayed adjusted p-values come from the frozen site-context source.",
  "category_support_preservation",
  "PASS",
  "All seven accepted category-level participant-hour, participant, participant-day, and site support records are embedded unchanged.",
  "site_cell_support_preservation",
  if (embedded_support_cells == 63L) "PASS" else "FAIL",
  "All 63 site-category support records and reporting states are embedded as SVG data attributes.",
  "sample_contract",
  "PASS",
  "The figure states 17,935 participant-hours, 140 participants, 801 participant-days, and nine sites.",
  "weighting_contract",
  "PASS",
  "Each H03 participant-hour has one mutually exclusive primary-light-source category; 1/k multi-label weighting is explicitly not applicable.",
  "source_model_flags",
  if (source_flags_ok) "PASS" else "FAIL",
  "Panels A-C preserve the excluded site-effect display flag; panel D identifies the light-source-by-site interaction model.",
  "accepted_site_palette",
  "PASS",
  "Site colours reproduce the frozen display registry; the category and site colour sets share no hexadecimal values, and country-coded labels and fixed row order provide non-colour cues.",
  "temporal_raster_preservation",
  "PASS",
  paste(
    sum(changed_pixels),
    "decoded temporal pixels changed, all within the bounded panel-B axis-title and panel-C tag repair tile."
  ),
  "capital_panel_tags",
  if (capital_tags_ok) "PASS" else "FAIL",
  "Exactly one bold uppercase A, B, C, and D panel tag is present on the left; no lowercase panel tag remains.",
  "table_alignment_and_density",
  "PASS",
  "Panel D starts at the 67.89-point plot-content edge; the header uses one P/D/H support line with no repeated site count or site-column label, and borderless site markers precede compact rows with inline parenthesized 95% confidence intervals.",
  "reader_language",
  if (prohibited_term_absent) "PASS" else "FAIL",
  "Visible figure text uses site-average estimate and light-source-by-site interaction model language.",
  "output_dimensions",
  if (dimension_ok) "PASS" else "FAIL",
  "The raster is 4,725 by 7,375 pixels at 300 dpi; the SVG is 1,134 by 1,770 points, matching the H04 composite grammar at 170 mm width.",
  "candidate_first_visual_qa",
  if (final_mode && visual_qa_confirmed && isTRUE(candidate_identity_ok)) {
    "PASS"
  } else {
    "PENDING"
  },
  if (final_mode) {
    paste(
      "Original-size and 170 mm candidate views were confirmed before finalization;",
      "final PNG and SVG are byte-identical to the inspected candidate."
    )
  } else {
    "Candidate package awaits original-size and 170 mm visual inspection."
  }
)
if (any(qa$status == "FAIL")) {
  failed <- qa$gate[qa$status == "FAIL"]
  stop(
    "H03 S7 automated QA failed: ",
    paste(failed, collapse = ", "),
    call. = FALSE
  )
}
readr::write_csv(qa, qa_output)

output_paths <- c(svg_output, png_output, pdf_output, qa_output)
output_roles <- c(
  "supplementary_figure_svg",
  "supplementary_figure_png",
  "supplementary_figure_pdf",
  "display_qa"
)
input_manifest <- tibble::tibble(
  record_type = "input",
  role = frozen_inputs$role,
  path = frozen_inputs$path,
  identifier = NA_character_,
  sha256 = frozen_inputs$sha256_observed,
  bytes = as.numeric(file.info(frozen_inputs$absolute_path)$size),
  value = NA_character_,
  r_version = as.character(getRversion())
)
output_manifest <- tibble::tibble(
  record_type = "output",
  role = output_roles,
  path = substring(output_paths, nchar(output_root) + 2L),
  identifier = NA_character_,
  sha256 = vapply(output_paths, sha256, character(1)),
  bytes = as.numeric(file.info(output_paths)$size),
  value = NA_character_,
  r_version = as.character(getRversion())
)
palette_manifest <- rbind(
  tibble::tibble(
    record_type = "palette",
    role = "light_source_category",
    path = NA_character_,
    identifier = names(category_palette),
    sha256 = NA_character_,
    bytes = NA_real_,
    value = unname(category_palette),
    r_version = as.character(getRversion())
  ),
  tibble::tibble(
    record_type = "palette",
    role = "study_site",
    path = NA_character_,
    identifier = names(site_palette),
    sha256 = NA_character_,
    bytes = NA_real_,
    value = unname(site_palette),
    r_version = as.character(getRversion())
  )
)
contract_manifest <- tibble::tribble(
  ~record_type,
  ~role,
  ~path,
  ~identifier,
  ~sha256,
  ~bytes,
  ~value,
  ~r_version,
  "contract",
  "sample",
  NA_character_,
  "accepted_support_statement",
  NA_character_,
  NA_real_,
  "17,935 participant-hours; 140 participants; 801 participant-days; nine sites",
  as.character(getRversion()),
  "contract",
  "weighting",
  NA_character_,
  "multi_label_weighting",
  NA_character_,
  NA_real_,
  "not applicable; one mutually exclusive primary-light-source category per participant-hour",
  as.character(getRversion()),
  "contract",
  "temporal_source_model_flag",
  NA_character_,
  "site_effects_excluded",
  NA_character_,
  NA_real_,
  "true",
  as.character(getRversion()),
  "contract",
  "panel_d_source_model",
  NA_character_,
  "architecture",
  NA_character_,
  NA_real_,
  "light-source-by-site interaction model; stored full_literal estimands",
  as.character(getRversion())
)
readr::write_csv(
  rbind(input_manifest, output_manifest, palette_manifest, contract_manifest),
  manifest_output
)

unlink(panel_d_svg_path)
message(
  if (final_mode) "Final" else "Candidate",
  " H03 manuscript Supplementary Figure S7 package written to ",
  output_root
)
