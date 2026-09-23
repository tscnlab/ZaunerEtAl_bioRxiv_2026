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


# Append a regenerated vector table panel to the regenerated temporal panels.
assemble_context_figure <- function(temporal_filename, panel_lines, panel_height, stem) {
  temporal_path <- find_result(temporal_filename, "results/images")
  temporal <- xml2::read_xml(temporal_path)
  root <- xml2::xml_root(temporal)
  viewbox <- as.numeric(strsplit(xml2::xml_attr(root, "viewBox"), "[[:space:]]+")[[1]])
  if (length(viewbox) != 4L || anyNA(viewbox)) stop("The temporal SVG requires a viewBox.", call. = FALSE)
  width <- 1134
  temporal_height <- viewbox[[4]] * width / viewbox[[3]]
  # Shorten display wording while retaining the same curves and estimands.
  text_nodes <- xml2::xml_find_all(root, ".//*[local-name()='text']")
  for (node in text_nodes) {
    label <- xml2::xml_text(node)
    label <- gsub("Factor relative to global mean", "Ratio to global mean", label, fixed = TRUE)
    label <- gsub("Other/unspecified activity", "Other", label, fixed = TRUE)
    label <- gsub("Other/unspecified", "Other", label, fixed = TRUE)
    xml2::xml_set_text(node, label)
  }
  # Keep publication panel tags in the left margin in both vector and raster outputs.
  tags <- text_nodes[xml2::xml_text(text_nodes) %in% c("A", "B", "C")]
  stopifnot(length(tags) == 3L)
  xml2::xml_set_attr(tags, "x", as.character(15.94 * viewbox[[3]] / width))
  xml2::xml_set_attr(tags, "text-anchor", "start")
  xml2::xml_set_attr(root, "width", as.character(width))
  xml2::xml_set_attr(root, "height", as.character(temporal_height))
  output <- file.path("results/images/publication", paste0(stem, ".svg"))
  dir.create(dirname(output), recursive = TRUE, showWarnings = FALSE)
  svg <- c(
    sprintf("<svg xmlns='http://www.w3.org/2000/svg' width='%spt' height='%spt' viewBox='0 0 %s %s'>", width, temporal_height + panel_height, width, temporal_height + panel_height),
    sub("^<\\?xml[^>]+>[[:space:]]*", "", as.character(root)),
    sprintf("<g transform='translate(0 %s)'>", temporal_height),
    panel_lines, "</g></svg>"
  )
  writeLines(svg, output, useBytes = TRUE)
  raster <- magick::image_read(output, density = 300)
  raster <- magick::image_background(raster, "white", flatten = TRUE)
  magick::image_write(raster, sub("[.]svg$", ".png", output), format = "png")
  invisible(output)
}

build_light_source_publication_figure <- function() {
  category_order <- c("Indoor electric", "Outdoor electric", "Indoor daylight", "Outdoor daylight", "Emissive display", "Sleep darkness", "External light during sleep")
  category_palette <- stats::setNames(c("#4477AA", "#EE6677", "#228833", "#CCBB44", "#66CCEE", "#AA3377", "#777777"), category_order)
  site_registry <- readr::read_csv("config/site_display_registry.csv", show_col_types = FALSE)
  site_registry <- site_registry[order(site_registry$display_order), , drop = FALSE]
  site_order <- site_registry$display_name
  site_palette <- stats::setNames(site_registry$color_hex, site_order)
  site_context <- read_result_csv("H03_site_context_estimands.csv") |>
    dplyr::filter(.data$placement == "Near-eye", .data$short_label %in% .env$category_order) |>
    dplyr::arrange(.data$display_order, .data$category_order)
  overall_source <- site_context[!duplicated(site_context$category_order), , drop = FALSE]
  overall_source <- overall_source[match(category_order, overall_source$short_label), , drop = FALSE]
  site_context$fdr_label <- site_context$reporting_status == "ESTIMABLE" & !is.na(site_context$site_deviation_p_adjusted) & site_context$site_deviation_p_adjusted < 0.05
  category_support <- read_result_csv("H03_category_support.csv") |>
    dplyr::filter(.data$placement == "Near-eye", .data$short_label %in% .env$category_order)
  category_support <- category_support[match(category_order, category_support$short_label), , drop = FALSE]
  temporal_summary <- read_result_csv("H03_reader_temporal_model_summary.csv") |>
    dplyr::filter(.data$placement == "Near-eye")
  stopifnot(nrow(temporal_summary) == 1L, !anyNA(category_support$short_label))
  format_p <- function(value) ifelse(value < 0.001, "<0.001", sprintf("%.3f", value))
panel_width <- 1134
# End the canvas just below the seventh footer line.
panel_d_height <- 784
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
site_bottom <- overall_bottom + length(site_order) * site_row_height
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
    sprintf("Bold site ratios and FDR p-values pass the complete %s-member near-eye", sum(site_context$reporting_status == "ESTIMABLE")),
    "family; unsupported cells are not estimable."
  ),
  sprintf("Near-eye frame: %s participant-hours; %s participants; %s participant-days; %s sites.", format(temporal_summary$observations, big.mark = ","), temporal_summary$participants, temporal_summary$participant_days, temporal_summary$sites),
  paste(
    "Each participant-hour has one primary light-source category; 1/k",
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


  dir.create("results/csv/source_data/publication", recursive = TRUE, showWarnings = FALSE)
  readr::write_csv(site_context, "results/csv/source_data/publication/H03_manuscript_site_context.csv")
  readr::write_csv(category_support, "results/csv/source_data/publication/H03_manuscript_category_support.csv")
  assemble_context_figure("H03_reader_temporal_near_eye.svg", panel_d_lines, panel_d_height, "H03_light_source_patterns")
}

build_activity_publication_figure <- function() {
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

category_support <- read_result_csv("H04_preparation_category_support.csv")
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
other_support <- category_support[
  category_support$activity == "Other/unspecified activity",
  ,
  drop = FALSE
]

named_estimands <- read_result_csv("H04_reader_heterogeneity_category_estimands.csv")
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

other_estimands <- read_result_csv("H04_reader_category_estimands.csv")
other_estimand <- other_estimands[
  other_estimands$placement == "Near-eye" &
    other_estimands$activity == "Other/unspecified activity",
  ,
  drop = FALSE
]

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

site_estimands <- read_result_csv("H04_site_activity_estimands.csv")
site_estimands <- site_estimands[
  site_estimands$placement == "Near-eye" &
    site_estimands$activity %in% activity_order,
  ,
  drop = FALSE
]

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
      "%.2f (%.2f–%.2f)× At home",
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
    "%.2f (%.2f–%.2f)× At home",
    other_estimand$ratio_to_home,
    other_estimand$ratio_conf_low,
    other_estimand$ratio_conf_high
  ),
  fdr_p = "Display only",
  estimable = TRUE,
  fdr_label = FALSE,
  model_source = "additive_display_only"
)

site_registry <- readr::read_csv("config/site_display_registry.csv", show_col_types = FALSE)
site_registry <- site_registry[order(site_registry$display_order), , drop = FALSE]
site_order <- as.character(site_registry$display_name)
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

panel_width <- 1134
panel_height <- 897
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
overall_bottom <- 244
site_row_height <- 54
site_bottom <- overall_bottom + length(site_order) * site_row_height
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
    sprintf("%.2f× home", row$ratio_to_home)
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
      sprintf("%.1f lx", row$standardized_mean_lx),
      size = 15,
      weight = "bold"
    ),
    svg_text(x, header_bottom + 38,
      sprintf("95%% CI %.1f–%.1f", row$mean_conf_low_lx, row$mean_conf_high_lx),
      size = 11.6, fill = "#46515C"),
    svg_text(x, header_bottom + 62, ratio_line, size = 14, weight = "bold"),
    svg_text(x, header_bottom + 81,
      if (index == 1L) "" else sprintf("95%% CI %.2f–%.2f", row$ratio_conf_low, row$ratio_conf_high),
      size = 11.6, fill = "#46515C")
  )
  panel_d_lines <- c(
    panel_d_lines,
    svg_text(
      x,
      header_bottom + 104,
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
      interval <- paste0("(", sub("^95% CI\\s*", "", cell$confidence_interval), ")")
      panel_d_lines <- c(
        panel_d_lines,
        svg_text(x, row_top + 16, cell$estimate, size = 14, weight = weight),
        svg_text(x, row_top + 32, interval, size = 10.6, weight = weight),
        svg_text(
          x,
          row_top + 47,
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
  "Site-average estimates and comparisons for the five named categories use the activity-by-site interaction model.",
  "Other is the additive display-only estimate and was excluded from the interaction model.",
  "Site rows are deviation ratios around each category estimate; parentheses show 95% confidence intervals.",
  sprintf("Bold site ratios and FDR p-values pass the complete %s-member near-eye family; unsupported cells are not estimable.", sum(site_rows$estimable)),
  "Each multi-select hour contributes 1/k; the exact model samples appear on the activity analysis page.",
  sprintf("Other-only display support: P %s · D %s · H %s.", other_support$participants, other_support$participant_days, other_support$unique_participant_hours),
  "P, participants; D, participant-days; H, unique participant-hours."
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


  dir.create("results/csv/source_data/publication", recursive = TRUE, showWarnings = FALSE)
  readr::write_csv(panel_d_data, "results/csv/source_data/publication/H04_manuscript_panel_d.csv")
  readr::write_csv(category_support, "results/csv/source_data/publication/H04_manuscript_category_support.csv")
  assemble_context_figure("H04_temporal_near_eye.svg", panel_d_lines, panel_height, "H04_manuscript_figure3")
}
