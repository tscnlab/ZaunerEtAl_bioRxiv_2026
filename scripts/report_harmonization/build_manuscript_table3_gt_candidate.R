#!/usr/bin/env Rscript

# Build a candidate-only compact gt redesign of the frozen Nature Health
# manuscript-selection Table 3. This script reads the accepted static table
# fragment and changes only its display structure. It does not calculate or
# alter a scientific value and never writes the accepted fragment or preview.

suppressPackageStartupMessages({
  library(digest)
  library(gt)
  library(xml2)
})

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("This candidate builder must run under R 4.6.1.")
}

project_root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
setwd(project_root)

source_path <- paste0(
  "audit/manuscript_nature_health/figure_table_selection_assets/",
  "tbl-plan-h01-metric-synthesis.html"
)
candidate_dir <- paste0(
  "audit/manuscript_nature_health/figure_table_selection_assets/",
  "table3_gt_candidate"
)
candidate_fragment_path <- file.path(
  candidate_dir,
  "tbl-plan-h01-metric-synthesis-candidate.html"
)
candidate_preview_path <- file.path(
  candidate_dir,
  "tbl-plan-h01-metric-synthesis-candidate-preview.html"
)
candidate_inventory_path <- file.path(
  candidate_dir,
  "table3_candidate_content_inventory.csv"
)
dir.create(candidate_dir, recursive = TRUE, showWarnings = FALSE)

sha256_file <- function(path) {
  if (!file.exists(path) || dir.exists(path)) {
    stop("Expected a regular file: ", path)
  }
  digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
}

pins <- c(
  source = "0ce8eb1e6cbeb63b7819dbce4e03f669529bcb0c20754ba684e6002eccc3e43f",
  selection_qmd = "5a66303527c131cd0f0dc0c45f6d6170ddcc773bcf6ecbc76f90d1b7ea21e83f",
  selection_html = "140a0c380aff46200846ac8c31ed69ac136989c02c99726b1b35e6e4dd1756c3",
  selection_builder = "23be5e1ecf1829288e2e4b2a752e8d71c4c53b0d59a466a2374ce8f99e8cc9d2"
)
pin_paths <- c(
  source = source_path,
  selection_qmd = "audit/manuscript_nature_health/manuscript_figure_table_selection.qmd",
  selection_html = "audit/manuscript_nature_health/manuscript_figure_table_selection.html",
  selection_builder = "scripts/report_harmonization/build_manuscript_figure_table_selection.R"
)
observed_pins <- vapply(pin_paths, sha256_file, character(1))
if (!identical(unname(observed_pins), unname(pins))) {
  stop("A frozen Table 3 candidate boundary changed.")
}

normalize_text <- function(node) {
  trimws(gsub("[[:space:]]+", " ", xml_text(node)))
}

escape_html <- function(value) {
  value <- gsub("&", "&amp;", value, fixed = TRUE)
  value <- gsub("<", "&lt;", value, fixed = TRUE)
  value <- gsub(">", "&gt;", value, fixed = TRUE)
  value <- gsub('"', "&quot;", value, fixed = TRUE)
  value
}

label_line <- function(label, value) {
  paste0(
    '<div class="compact-line"><span class="mini-label">',
    escape_html(label),
    "</span> ",
    escape_html(value),
    "</div>"
  )
}

source_document <- read_html(source_path)
source_table <- xml_find_first(source_document, "//table")
body_rows <- xml_find_all(source_table, ".//tbody/tr")

groups <- character()
records <- list()
current_group <- NA_character_
for (row in body_rows) {
  cells <- xml_children(row)
  if (
    length(cells) == 1L &&
      grepl(
        "gt_group_heading",
        xml_attr(cells[[1L]], "class"),
        fixed = TRUE
      )
  ) {
    current_group <- normalize_text(cells[[1L]])
    groups <- c(groups, current_group)
    next
  }
  if (length(cells) != 16L || is.na(current_group)) {
    stop("The accepted Table 3 row structure changed.")
  }
  values <- vapply(cells, normalize_text, character(1))
  image <- xml_find_first(cells[[8L]], ".//img")
  if (inherits(image, "xml_missing")) {
    stop("A Table 3 distribution thumbnail is missing.")
  }
  image_src <- xml_attr(image, "src")
  image_alt <- xml_attr(image, "alt")
  image_html <- paste0(
    '<img class="metric-density-thumb" src="',
    escape_html(image_src),
    '" alt="',
    escape_html(image_alt),
    '">'
  )
  records[[length(records) + 1L]] <- data.frame(
    metric_family = current_group,
    metric = values[[1L]],
    definition = values[[2L]],
    descriptive = paste0(
      label_line("Unit", values[[3L]]),
      label_line("Median", values[[4L]]),
      label_line("IQR", values[[5L]]),
      label_line("N", values[[6L]]),
      label_line("Days", values[[7L]])
    ),
    distribution = image_html,
    overall_site = paste0(
      label_line("FDR", values[[9L]]),
      label_line("Part R-squared", values[[10L]])
    ),
    photoperiod = paste0(
      label_line("Estimate", values[[11L]]),
      label_line("FDR", values[[12L]]),
      label_line("Part R-squared", values[[13L]])
    ),
    modelled_variation = paste0(
      label_line("Marginal", values[[14L]]),
      label_line("Conditional", values[[15L]]),
      label_line("Participant-associated", values[[16L]])
    ),
    source_values = paste(values, collapse = "\u241f"),
    image_src = image_src,
    image_alt = image_alt,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}

candidate_rows <- do.call(rbind, records)
expected_groups <- c(
  "Dynamics",
  "Level",
  "Duration",
  "Timing",
  "Exposure history",
  "Spectrum"
)
if (
  nrow(candidate_rows) != 17L ||
    !identical(unique(candidate_rows$metric_family), expected_groups) ||
    anyDuplicated(candidate_rows$metric) ||
    anyDuplicated(candidate_rows$image_src) ||
    anyDuplicated(candidate_rows$image_alt)
) {
  stop("The accepted 17-row Table 3 inventory changed.")
}

display_rows <- candidate_rows[c(
  "metric_family",
  "metric",
  "definition",
  "descriptive",
  "distribution",
  "overall_site",
  "photoperiod",
  "modelled_variation"
)]

candidate_gt <- gt(
  display_rows,
  rowname_col = "metric",
  groupname_col = "metric_family",
  id = "plan_h01_metric_synthesis_candidate"
) |>
  tab_header(
    title = md(
      "**Near-eye personal light-exposure metrics and their geographic and photoperiod context**"
    )
  ) |>
  tab_spanner(
    label = "Descriptive summary",
    columns = c(descriptive, distribution)
  ) |>
  tab_spanner(
    label = "Association evidence",
    columns = c(overall_site, photoperiod)
  ) |>
  tab_spanner(
    label = "Modelled variation",
    columns = modelled_variation
  ) |>
  cols_label(
    metric = "Metric",
    definition = "Definition/relevance",
    descriptive = "Overall distribution",
    distribution = "Site distribution",
    overall_site = "Overall site",
    photoperiod = "Civil photoperiod",
    modelled_variation = "R² summary"
  ) |>
  fmt(
    columns = c(
      descriptive,
      distribution,
      overall_site,
      photoperiod,
      modelled_variation
    ),
    fn = function(values) lapply(values, html)
  ) |>
  cols_align(
    align = "left",
    columns = c(
      definition,
      descriptive,
      overall_site,
      photoperiod,
      modelled_variation
    )
  ) |>
  cols_align(align = "center", columns = distribution) |>
  cols_width(
    metric ~ px(175),
    definition ~ px(235),
    descriptive ~ px(135),
    distribution ~ px(155),
    overall_site ~ px(125),
    photoperiod ~ px(180),
    modelled_variation ~ px(155)
  ) |>
  tab_style(
    style = cell_text(weight = "bold"),
    locations = cells_row_groups()
  ) |>
  tab_style(
    style = cell_text(v_align = "middle"),
    locations = cells_body()
  ) |>
  opt_row_striping() |>
  tab_options(
    table.width = px(1160),
    table.font.size = px(10.5),
    data_row.padding = px(2),
    heading.align = "left",
    column_labels.padding = px(5),
    row_group.padding = px(4),
    source_notes.font.size = px(10)
  ) |>
  tab_source_note(
    source_note = md(paste0(
      "Overall distributions are median (interquartile range). N is the ",
      "participant count and Days is the participant-day count. Site and ",
      "photoperiod part-R² values can contain overlapping fitted information ",
      "and must not be summed. Participant-associated R² is the ",
      "conditional-minus-marginal contribution associated with the participant ",
      "random intercept and is undefined for participant-level outcomes. The ",
      "MDER uses the accepted mean of viable minute-level ratios in both the ",
      "descriptive and H01 model cells."
    ))
  )

raw_table <- as_raw_html(candidate_gt, inline_css = TRUE)
candidate_css <- paste0(
  "<style>",
  ".table3-candidate-scroll{max-width:100%;overflow-x:auto;}",
  ".table3-candidate-scroll .gt_table{width:1160px!important;min-width:1160px!important;}",
  ".table3-candidate-scroll .gt_row{line-height:1.18;}",
  ".table3-candidate-scroll .metric-density-thumb{display:block;width:145px;height:92px;object-fit:contain;margin:auto;}",
  ".table3-candidate-scroll .compact-line{margin:0 0 2px 0;overflow-wrap:normal;word-break:normal;}",
  ".table3-candidate-scroll .mini-label{font-weight:700;white-space:nowrap;}",
  ".table3-candidate-scroll tbody tr:not(.gt_group_heading) td,",
  ".table3-candidate-scroll tbody tr:not(.gt_group_heading) th{height:96px;max-height:104px;vertical-align:middle;}",
  "</style>"
)
candidate_fragment <- paste0(
  '<div id="tbl-plan-h01-metric-synthesis-candidate" class="table3-candidate-scroll">',
  candidate_css,
  raw_table,
  "</div>"
)
writeLines(candidate_fragment, candidate_fragment_path, useBytes = TRUE)

preview <- paste0(
  "<!doctype html><html lang=\"en\"><head><meta charset=\"utf-8\">",
  "<meta name=\"viewport\" content=\"width=device-width,initial-scale=1\">",
  "<title>Table 3 gt candidate</title>",
  "<style>body{margin:24px;font-family:Arial,sans-serif;color:#20262e;}</style>",
  "</head><body><main><h1>Table 3 candidate</h1>",
  candidate_fragment,
  "</main></body></html>"
)
writeLines(preview, candidate_preview_path, useBytes = TRUE)

inventory <- candidate_rows[c(
  "metric_family",
  "metric",
  "source_values",
  "image_src",
  "image_alt"
)]
write.csv(inventory, candidate_inventory_path, row.names = FALSE, na = "")

cat(
  "TABLE3_GT_CANDIDATE=PASS",
  paste0("rows=", nrow(candidate_rows)),
  paste0("groups=", length(unique(candidate_rows$metric_family))),
  paste0("images=", length(unique(candidate_rows$image_src))),
  "width_px=1160",
  paste0("fragment=", sha256_file(candidate_fragment_path)),
  paste0("preview=", sha256_file(candidate_preview_path)),
  paste0("R=", as.character(getRversion())),
  "\n"
)
