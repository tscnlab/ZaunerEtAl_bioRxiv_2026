#!/usr/bin/env Rscript

# REPORT-018 Order 72, H10 only: verify native SVG structure and privacy, then
# rasterize the already exported candidate for comparison with the accepted PNG.
# This script does not reconstruct the plot or execute any scientific analysis.

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(tibble)
})

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
if (!identical(as.character(getRversion()), "4.6.1")) {
  stop(sprintf("Order 72 verification requires R 4.6.1; running %s", getRversion()), call. = FALSE)
}

sha256_file <- function(path) {
  digest::digest(file = path, algo = "sha256")
}

output_root <- file.path(
  root,
  "audit/hypotheses/H10/report018_order72_svg_export"
)
candidate_relative <- paste0(
  "audit/hypotheses/H10/report018_order72_svg_export/candidate/",
  "H10_age_site_significant_associations_selection_candidate.svg"
)
candidate_path <- file.path(root, candidate_relative)
accepted_relative <- paste0(
  "audit/manuscript_nature_health/figure_table_selection_assets/",
  "H10_age_site_significant_associations_selection_candidate.png"
)
accepted_path <- file.path(root, accepted_relative)
source_relative <- paste0(
  "artifacts/11_source_data/H10/",
  "H10_age_site_significant_associations_data.csv"
)
display_relative <- paste0(
  "audit/hypotheses/H10/manuscript_selection_figure_candidate/",
  "candidate_display_text.csv"
)
release_relative <- paste0(
  "audit/report_harmonization/report018_order72_release/",
  "release_manifest.csv"
)

required_input_hashes <- c(
  candidate = readr::read_csv(
    file.path(output_root, "export_contract.csv"),
    show_col_types = FALSE,
    progress = FALSE
  ) |>
    filter(.data$contract_item == "svg_sha256") |>
    pull(.data$value),
  accepted = "e989646f21543203ef07916dde8917e85243667d54b5aa492815476edc6c4b60",
  source = "5f06ab98bada441d02123e56d073e52bfacae75c0277ab73803efd401c33c8fd",
  display = "e34ffd6de2bf1abb1e50a1474fd8c84611a2cef9ee7a8b9b4e7b971a25bb3ce5",
  release = "8e25aa779f0115a3a5da9ffcdc3913b81cd6fb06df0c17c9f6d5825356263526"
)
required_input_paths <- c(
  candidate = candidate_path,
  accepted = accepted_path,
  source = file.path(root, source_relative),
  display = file.path(root, display_relative),
  release = file.path(root, release_relative)
)
if (length(required_input_hashes[["candidate"]]) != 1L) {
  stop("Candidate hash is absent or non-unique in the export contract", call. = FALSE)
}
if (!all(file.exists(required_input_paths))) {
  stop("One or more Order 72 verification inputs are absent", call. = FALSE)
}
observed_input_hashes <- vapply(required_input_paths, sha256_file, character(1))
if (!identical(unname(observed_input_hashes), unname(required_input_hashes))) {
  print(tibble(
    input = names(required_input_hashes),
    expected = unname(required_input_hashes),
    observed = unname(observed_input_hashes)
  ))
  stop("One or more Order 72 verification input hashes differ", call. = FALSE)
}

qa_dir <- file.path(output_root, "qa")
structure_path <- file.path(output_root, "svg_structure_privacy_checks.csv")
semantic_path <- file.path(output_root, "display_semantic_checks.csv")
raster_metrics_path <- file.path(output_root, "raster_comparison_metrics.csv")
qa_command_path <- file.path(output_root, "qa_command.csv")
exact_raster_path <- file.path(
  qa_dir,
  "H10_selection_candidate_svg_raster_2820x3900.png"
)
reader_svg_path <- file.path(
  qa_dir,
  "H10_selection_candidate_svg_raster_170mm_300dpi.png"
)
reader_accepted_path <- file.path(
  qa_dir,
  "H10_selection_accepted_png_raster_170mm_300dpi.png"
)
comparison_path <- file.path(
  qa_dir,
  "H10_selection_accepted_vs_svg_comparison.png"
)
new_outputs <- c(
  structure_path,
  semantic_path,
  raster_metrics_path,
  qa_command_path,
  exact_raster_path,
  reader_svg_path,
  reader_accepted_path,
  comparison_path
)
if (any(file.exists(new_outputs))) {
  stop(
    paste(
      "Refusing to overwrite an Order 72 verification output:",
      paste(new_outputs[file.exists(new_outputs)], collapse = ", ")
    ),
    call. = FALSE
  )
}
dir.create(qa_dir, recursive = TRUE, showWarnings = FALSE)

svg_doc <- xml2::read_xml(candidate_path)
svg_root <- xml2::xml_root(svg_doc)
svg_raw <- paste(readLines(candidate_path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
svg_resource_scan <- gsub(
  "http://www.w3.org/2000/svg|http://www.w3.org/1999/xlink",
  "",
  svg_raw,
  perl = TRUE
)
all_elements <- xml2::xml_find_all(svg_doc, ".//*")
element_names <- xml2::xml_name(all_elements)
element_counts <- table(element_names)
count_element <- function(name) {
  value <- unname(element_counts[name])
  if (length(value) == 0L || is.na(value)) 0L else as.integer(value)
}

text_nodes <- xml2::xml_find_all(svg_doc, ".//*[local-name()='text']")
text_values <- xml2::xml_text(text_nodes)
text_styles <- xml2::xml_attr(text_nodes, "style")
visible_text <- paste(text_values, collapse = " ")
normalize_text <- function(x) {
  trimws(gsub("[[:space:]]+", " ", x, perl = TRUE))
}
visible_text_normalized <- normalize_text(visible_text)

all_attrs <- unlist(lapply(all_elements, xml2::xml_attrs), use.names = FALSE)
all_attr_names <- unlist(lapply(all_elements, function(node) names(xml2::xml_attrs(node))), use.names = FALSE)
href_values <- unlist(lapply(all_elements, function(node) {
  attrs <- xml2::xml_attrs(node)
  attrs[names(attrs) %in% c("href", "xlink:href")]
}), use.names = FALSE)
external_href <- href_values[!grepl("^#", href_values)]
event_attrs <- all_attr_names[grepl("^on", all_attr_names, ignore.case = TRUE)]

tag_index <- which(text_values %in% c("A", "B", "C"))
tag_values <- text_values[tag_index]
tag_styles <- text_styles[tag_index]
tag_bold <- length(tag_index) == 3L && all(grepl("font-weight: bold", tag_styles, fixed = TRUE))

source_data <- readr::read_csv(
  file.path(root, source_relative),
  show_col_types = FALSE,
  progress = FALSE
)
display_spec <- readr::read_csv(
  file.path(root, display_relative),
  show_col_types = FALSE,
  progress = FALSE
)
display_text <- stats::setNames(display_spec$text, display_spec$key)
visible_display_keys <- c(
  "overall_title", "overall_subtitle", "overall_caption",
  "age_title", "age_subtitle", "age_x", "biological_sex_legend",
  "placement_near_eye", "placement_chest", "main_title",
  "main_subtitle", "main_x", "panel_near_age", "panel_chest_age",
  "panel_chest_sex", "interaction_title", "interaction_subtitle",
  "interaction_x"
)
display_semantic_checks <- tibble(
  check_type = "accepted display text",
  item = visible_display_keys,
  expected = unname(display_text[visible_display_keys]),
  status = vapply(
    unname(display_text[visible_display_keys]),
    function(x) grepl(normalize_text(x), visible_text_normalized, fixed = TRUE),
    logical(1)
  )
)

site_contract <- source_data |>
  filter(.data$panel == "age_distribution") |>
  distinct(
    .data$site,
    .data$site_display_order,
    .data$site_display_name,
    .data$site_color_hex
  ) |>
  arrange(.data$site_display_order)
site_semantic_checks <- tibble(
  check_type = "submitted-manuscript site label",
  item = site_contract$site,
  expected = site_contract$site_display_name,
  status = vapply(
    site_contract$site_display_name,
    function(x) grepl(normalize_text(x), visible_text_normalized, fixed = TRUE),
    logical(1)
  )
)

main_metric_lines <- source_data |>
  filter(.data$panel == "retained_main_association") |>
  distinct(.data$manuscript_name) |>
  mutate(lines = stringr::str_split(stringr::str_wrap(.data$manuscript_name, width = 24), "\\n")) |>
  tidyr::unnest(.data$lines) |>
  distinct(.data$manuscript_name, .data$lines)
main_metric_checks <- tibble(
  check_type = "retained main metric label line",
  item = main_metric_lines$manuscript_name,
  expected = main_metric_lines$lines,
  status = main_metric_lines$lines %in% text_values
)
interaction_metrics <- source_data |>
  filter(.data$panel == "retained_site_heterogeneity") |>
  distinct(.data$manuscript_name) |>
  pull(.data$manuscript_name)
interaction_metric_checks <- tibble(
  check_type = "retained interaction metric label",
  item = interaction_metrics,
  expected = interaction_metrics,
  status = interaction_metrics %in% text_values
)
semantic_checks <- bind_rows(
  display_semantic_checks,
  site_semantic_checks,
  main_metric_checks,
  interaction_metric_checks
)

required_colors <- toupper(unique(c(
  "#0072B2",
  "#D55E00",
  site_contract$site_color_hex
)))
observed_colors <- unique(toupper(unlist(
  regmatches(svg_raw, gregexpr("#[0-9A-Fa-f]{6}", svg_raw, perl = TRUE))
)))
missing_colors <- setdiff(required_colors, observed_colors)

structure_checks <- tribble(
  ~check, ~observed, ~requirement, ~status,
  "root element", xml2::xml_name(svg_root), "svg", identical(xml2::xml_name(svg_root), "svg"),
  "width", xml2::xml_attr(svg_root, "width"), "676.80pt", identical(xml2::xml_attr(svg_root, "width"), "676.80pt"),
  "height", xml2::xml_attr(svg_root, "height"), "936.00pt", identical(xml2::xml_attr(svg_root, "height"), "936.00pt"),
  "viewBox", xml2::xml_attr(svg_root, "viewBox"), "0 0 676.80 936.00", identical(xml2::xml_attr(svg_root, "viewBox"), "0 0 676.80 936.00"),
  "native path elements", as.character(count_element("path")), "> 0", count_element("path") > 0L,
  "native line elements", as.character(count_element("line")), "> 0", count_element("line") > 0L,
  "native rect elements", as.character(count_element("rect")), "> 0", count_element("rect") > 0L,
  "native circle elements", as.character(count_element("circle")), "> 0", count_element("circle") > 0L,
  "native polygon elements", as.character(count_element("polygon")), "> 0", count_element("polygon") > 0L,
  "text elements", as.character(count_element("text")), "> 0", count_element("text") > 0L,
  "raster image elements", as.character(count_element("image")), "0", count_element("image") == 0L,
  "script elements", as.character(count_element("script")), "0", count_element("script") == 0L,
  "foreignObject elements", as.character(count_element("foreignObject")), "0", count_element("foreignObject") == 0L,
  "metadata elements", as.character(count_element("metadata")), "0", count_element("metadata") == 0L,
  "external href values", paste(external_href, collapse = " | "), "none", length(external_href) == 0L,
  "event-handler attributes", paste(event_attrs, collapse = " | "), "none", length(event_attrs) == 0L,
  "embedded raster payload", as.character(grepl("data:image|base64,", svg_raw, ignore.case = TRUE, perl = TRUE)), "FALSE", !grepl("data:image|base64,", svg_raw, ignore.case = TRUE, perl = TRUE),
  "external URL or import", as.character(grepl("https?://|file:|@import|@font-face|url\\((?!#)", svg_resource_scan, ignore.case = TRUE, perl = TRUE)), "FALSE", !grepl("https?://|file:|@import|@font-face|url\\((?!#)", svg_resource_scan, ignore.case = TRUE, perl = TRUE),
  "hidden source or script path", as.character(grepl("participant_display_index|p_raw|\\.csv|\\.R([<\"'])|/Users/|artifacts/", svg_raw, ignore.case = TRUE, perl = TRUE)), "FALSE", !grepl("participant_display_index|p_raw|\\.csv|\\.R([<\"'])|/Users/|artifacts/", svg_raw, ignore.case = TRUE, perl = TRUE),
  "participant identifier pattern", as.character(grepl("::|THUAS_|[A-Z]{2,}[_-]S?[0-9]{2,}", visible_text, perl = TRUE)), "FALSE", !grepl("::|THUAS_|[A-Z]{2,}[_-]S?[0-9]{2,}", visible_text, perl = TRUE),
  "panel tags", paste(tag_values, collapse = ","), "A,B,C exactly once", identical(tag_values, c("A", "B", "C")),
  "bold panel tags", as.character(tag_bold), "TRUE", tag_bold,
  "reader-facing internal H10 label", as.character(grepl("\\bH10\\b", visible_text, perl = TRUE)), "FALSE", !grepl("\\bH10\\b", visible_text, perl = TRUE),
  "reader-facing BH label", as.character(grepl("\\bBH\\b", visible_text, perl = TRUE)), "FALSE", !grepl("\\bBH\\b", visible_text, perl = TRUE),
  "reader-facing FDR label", as.character(grepl("\\bFDR\\b", visible_text, perl = TRUE)), "TRUE", grepl("\\bFDR\\b", visible_text, perl = TRUE),
  "required display colours", paste(missing_colors, collapse = " | "), "none missing", length(missing_colors) == 0L,
  "Arial font references", as.character(sum(grepl('font-family: "Arial"', text_styles, fixed = TRUE))), "all text elements", all(grepl('font-family: "Arial"', text_styles, fixed = TRUE)),
  "Arial system font resolution", systemfonts::match_fonts("Arial")$path[[1]], "existing local file", file.exists(systemfonts::match_fonts("Arial")$path[[1]])
)
if (!all(structure_checks$status)) {
  print(filter(structure_checks, !.data$status))
  stop("Native SVG structure or privacy contract failed", call. = FALSE)
}
if (!all(semantic_checks$status)) {
  print(filter(semantic_checks, !.data$status))
  stop("Native SVG display-semantic contract failed", call. = FALSE)
}

temp_qa <- tempfile(pattern = "H10-order72-svg-qa-")
dir.create(temp_qa, recursive = TRUE, showWarnings = FALSE)
on.exit(unlink(temp_qa, recursive = TRUE, force = TRUE), add = TRUE)
candidate_qa_source <- file.path(temp_qa, "candidate.svg")
accepted_qa_source <- file.path(temp_qa, "accepted.png")
if (
  !file.copy(candidate_path, candidate_qa_source, overwrite = FALSE) ||
    !file.copy(accepted_path, accepted_qa_source, overwrite = FALSE) ||
    !identical(sha256_file(candidate_qa_source), sha256_file(candidate_path)) ||
    !identical(sha256_file(accepted_qa_source), sha256_file(accepted_path))
) {
  stop("Could not create identity-preserved private QA inputs", call. = FALSE)
}

write_wrapper <- function(path, body, width, height) {
  html <- c(
    "<!doctype html>",
    "<html><head><meta charset='utf-8'>",
    sprintf(
      paste0(
        "<style>html,body{margin:0;padding:0;width:%dpx;height:%dpx;",
        "overflow:hidden;background:white}</style>"
      ),
      width,
      height
    ),
    "</head><body>",
    body,
    "</body></html>"
  )
  writeLines(html, path, useBytes = TRUE)
  invisible(path)
}

rasterize_local_wrapper <- function(html_path, output_path, width, height) {
  webshot2::webshot(
    paste0("file://", normalizePath(html_path, winslash = "/", mustWork = TRUE)),
    file = output_path,
    vwidth = width,
    vheight = height,
    cliprect = "viewport",
    delay = 0.5,
    zoom = 1
  )
  if (!file.exists(output_path) || file.info(output_path)$size <= 0) {
    stop(sprintf("Rasterization did not produce %s", basename(output_path)), call. = FALSE)
  }
  dims <- dim(png::readPNG(output_path))[1:2]
  if (!identical(as.integer(dims), c(as.integer(height), as.integer(width)))) {
    stop(sprintf("Raster dimensions differ for %s", basename(output_path)), call. = FALSE)
  }
  invisible(output_path)
}

candidate_uri <- paste0("file://", normalizePath(candidate_qa_source, winslash = "/"))
accepted_uri <- paste0("file://", normalizePath(accepted_qa_source, winslash = "/"))
exact_tmp <- file.path(temp_qa, "candidate_exact.png")
reader_svg_tmp <- file.path(temp_qa, "candidate_reader.png")
reader_accepted_tmp <- file.path(temp_qa, "accepted_reader.png")
comparison_tmp <- file.path(temp_qa, "comparison.png")

exact_html <- file.path(temp_qa, "candidate_exact.html")
write_wrapper(
  exact_html,
  sprintf(
    "<img src='%s' style='display:block;width:2820px;height:3900px' alt=''>",
    candidate_uri
  ),
  2820,
  3900
)
rasterize_local_wrapper(exact_html, exact_tmp, 2820, 3900)

reader_width <- as.integer(round(170 / 25.4 * 300))
reader_height <- as.integer(round(reader_width * 3900 / 2820))
reader_svg_html <- file.path(temp_qa, "candidate_reader.html")
write_wrapper(
  reader_svg_html,
  sprintf(
    "<img src='%s' style='display:block;width:%dpx;height:%dpx' alt=''>",
    candidate_uri,
    reader_width,
    reader_height
  ),
  reader_width,
  reader_height
)
rasterize_local_wrapper(reader_svg_html, reader_svg_tmp, reader_width, reader_height)

reader_accepted_html <- file.path(temp_qa, "accepted_reader.html")
write_wrapper(
  reader_accepted_html,
  sprintf(
    "<img src='%s' style='display:block;width:%dpx;height:%dpx' alt=''>",
    accepted_uri,
    reader_width,
    reader_height
  ),
  reader_width,
  reader_height
)
rasterize_local_wrapper(reader_accepted_html, reader_accepted_tmp, reader_width, reader_height)

comparison_html <- file.path(temp_qa, "comparison.html")
write_wrapper(
  comparison_html,
  paste0(
    "<style>",
    ".wrap{display:grid;grid-template-columns:1fr 1fr;gap:20px;padding:10px;",
    "box-sizing:border-box;font-family:Arial,sans-serif;color:#111}",
    ".label{font-size:18px;font-weight:bold;height:28px}",
    ".panel img{display:block;width:690px;height:auto;border:1px solid #bbb}",
    "</style><div class='wrap'>",
    "<div class='panel'><div class='label'>Accepted PNG</div>",
    sprintf("<img src='%s' alt='accepted'></div>", accepted_uri),
    "<div class='panel'><div class='label'>Native SVG rasterization</div>",
    sprintf("<img src='file://%s' alt='svg raster'></div>", normalizePath(exact_tmp, winslash = "/")),
    "</div>"
  ),
  1440,
  1000
)
rasterize_local_wrapper(comparison_html, comparison_tmp, 1440, 1000)

read_rgb <- function(path) {
  x <- png::readPNG(path)
  if (length(dim(x)) != 3L || dim(x)[3] < 3L) {
    stop(sprintf("Raster is not RGB/RGBA: %s", basename(path)), call. = FALSE)
  }
  x[, , 1:3, drop = FALSE]
}
accepted_rgb <- read_rgb(accepted_path)
svg_rgb <- read_rgb(exact_tmp)
if (!identical(dim(accepted_rgb), dim(svg_rgb))) {
  stop("Accepted and SVG comparison rasters have different dimensions", call. = FALSE)
}
sample_rows <- unique(as.integer(round(seq(1, dim(svg_rgb)[1], length.out = 390))))
sample_cols <- unique(as.integer(round(seq(1, dim(svg_rgb)[2], length.out = 282))))
accepted_sample <- accepted_rgb[sample_rows, sample_cols, , drop = FALSE]
svg_sample <- svg_rgb[sample_rows, sample_cols, , drop = FALSE]
accepted_luma <- rowMeans(matrix(accepted_sample, ncol = 3L))
svg_luma <- rowMeans(matrix(svg_sample, ncol = 3L))
ink_union <- accepted_luma < 0.98 | svg_luma < 0.98
raster_metrics <- tribble(
  ~metric, ~value, ~interpretation,
  "accepted_width_px", as.character(dim(accepted_rgb)[2]), "must equal 2820",
  "accepted_height_px", as.character(dim(accepted_rgb)[1]), "must equal 3900",
  "svg_raster_width_px", as.character(dim(svg_rgb)[2]), "must equal 2820",
  "svg_raster_height_px", as.character(dim(svg_rgb)[1]), "must equal 3900",
  "reader_width_px", as.character(reader_width), "170 mm at 300 dpi, rounded",
  "reader_height_px", as.character(reader_height), "preserves accepted canvas ratio",
  "sampled_rgb_mean_absolute_difference", format(mean(abs(accepted_sample - svg_sample)), digits = 16), "descriptive device and antialias difference",
  "sampled_ink_union_luminance_mean_absolute_difference", format(mean(abs(accepted_luma[ink_union] - svg_luma[ink_union])), digits = 16), "descriptive device and antialias difference on non-white union",
  "sampled_luminance_correlation", format(stats::cor(accepted_luma, svg_luma), digits = 16), "descriptive structural similarity",
  "sampled_ink_union_pixels", as.character(sum(ink_union)), "descriptive comparison support",
  "accepted_sha256", sha256_file(accepted_path), "must equal released pin",
  "svg_sha256", sha256_file(candidate_path), "must equal export contract",
  "svg_exact_raster_sha256", sha256_file(exact_tmp), "QA proof",
  "svg_reader_raster_sha256", sha256_file(reader_svg_tmp), "QA proof",
  "accepted_reader_raster_sha256", sha256_file(reader_accepted_tmp), "QA proof",
  "comparison_contact_sheet_sha256", sha256_file(comparison_tmp), "QA proof"
)

readr::write_csv(structure_checks, structure_path, na = "")
readr::write_csv(semantic_checks, semantic_path, na = "")
readr::write_csv(raster_metrics, raster_metrics_path, na = "")
readr::write_csv(
  tibble(
    sequence = 2L,
    purpose = "single native-SVG structural, privacy, semantic and raster QA run",
    command = paste(
      "RENV_CONFIG_AUTOLOADER_ENABLED=FALSE Rscript --vanilla",
      "audit/hypotheses/H10/report018_order72_svg_export/verify_h10_selection_svg.R"
    ),
    status = "PASS"
  ),
  qa_command_path,
  na = ""
)
file.copy(exact_tmp, exact_raster_path, overwrite = FALSE)
file.copy(reader_svg_tmp, reader_svg_path, overwrite = FALSE)
file.copy(reader_accepted_tmp, reader_accepted_path, overwrite = FALSE)
file.copy(comparison_tmp, comparison_path, overwrite = FALSE)
if (!all(file.exists(new_outputs)) || !all(file.info(new_outputs)$size > 0)) {
  stop("One or more Order 72 verification outputs were not sealed", call. = FALSE)
}

message(
  "REPORT018_ORDER72_H10_QA_AUTOMATED_PASS structure=",
  nrow(structure_checks),
  "/",
  nrow(structure_checks),
  " semantic=",
  nrow(semantic_checks),
  "/",
  nrow(semantic_checks),
  " exact_raster=2820x3900 reader_raster=",
  reader_width,
  "x",
  reader_height
)
