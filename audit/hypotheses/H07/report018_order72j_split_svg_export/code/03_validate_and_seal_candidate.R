#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE, warn = 2)

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
project_library <- file.path(
  root,
  "renv/library/macos/R-4.6/aarch64-apple-darwin23"
)
stopifnot(dir.exists(project_library))
.libPaths(c(project_library, .libPaths()))

suppressPackageStartupMessages({
  library(digest)
  library(dplyr)
  library(readr)
  library(stringr)
  library(tibble)
  library(tidyr)
  library(xml2)
})

stopifnot(
  identical(as.character(getRversion()), "4.6.1"),
  Sys.getenv("RENV_CONFIG_AUTOLOADER_ENABLED", unset = "") == "FALSE"
)

owner_relative <-
  "audit/hypotheses/H07/report018_order72j_split_svg_export"
owner_root <- normalizePath(
  file.path(root, owner_relative),
  winslash = "/",
  mustWork = TRUE
)
attempt_path <- file.path(
  owner_root,
  "attempts/attempt_01/H07_revised_smooth_derivative_pairs_near_eye.svg"
)
candidate_dir <- file.path(owner_root, "candidate")
candidate_path <- file.path(
  candidate_dir,
  "H07_revised_smooth_derivative_pairs_near_eye.svg"
)
evidence_dir <- file.path(owner_root, "evidence")
stopifnot(
  dir.exists(evidence_dir),
  file.exists(attempt_path),
  !file.exists(candidate_path)
)

sha256_file <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
}

assert_owner_target <- function(path) {
  normalized <- normalizePath(path, winslash = "/", mustWork = FALSE)
  stopifnot(startsWith(normalized, paste0(owner_root, "/")))
  normalized
}

write_evidence <- function(object, filename) {
  target <- assert_owner_target(file.path(evidence_dir, filename))
  stopifnot(!file.exists(target))
  utils::write.csv(
    object,
    target,
    row.names = FALSE,
    na = "",
    fileEncoding = "UTF-8"
  )
}

attempt_expected_sha256 <-
  "f12465fd629c44bbcc7f09a13fccd88b41eda9b80d1cba1310bbdab4ce52ba57"
attempt_expected_bytes <- 1238493
stopifnot(
  identical(sha256_file(attempt_path), attempt_expected_sha256),
  identical(as.numeric(file.info(attempt_path)$size), attempt_expected_bytes)
)

input_paths <- c(
  curves = "artifacts/09_tables/H07/H07_main_curve_points.csv",
  derivatives = "artifacts/09_tables/H07/H07_revised_derivative_points.csv",
  plateaus = "artifacts/09_tables/H07/H07_revised_plateau_summary.csv",
  rugs = "artifacts/09_tables/H07/H07_revised_derivative_photoperiod_rows.csv",
  settings = "artifacts/09_tables/H07/H07_revised_paired_figure_settings.csv",
  metric_registry = "artifacts/06_model_data/H05/H05_metric_registry.csv"
)
input_hashes <- c(
  curves = "e92a5a89e0eda37c57de0dfa6a68d2e8c4f08b08d0ebfab5e7f2c332c9bdb034",
  derivatives = "8fd527ef2800217e78d4de4ce9dc55246dfd301f6a85b47cbfa91236131540e4",
  plateaus = "e8ad47e76a8386fea3a9115cab2f0d477700ac55d82cc4133bd712d377fa15c1",
  rugs = "541dc9f86fcb7bd4740016815c988d05a6d69580af41d1e941fae46085f849cb",
  settings = "e7fe343dca5b2d10efce3cea245f95f52bfbd27f997933346c50696b949ee4e2",
  metric_registry = "25a3df408dad73b657ea1ee20631195c93fe33340fafa7250ed6e76727c65bb7"
)
input_files <- stats::setNames(
  file.path(root, unname(input_paths)),
  names(input_paths)
)
stopifnot(
  all(file.exists(input_files)),
  identical(
    unname(vapply(input_files, sha256_file, character(1))),
    unname(input_hashes)
  )
)

read_input <- function(name) {
  readr::read_csv(input_files[[name]], show_col_types = FALSE, na = "")
}

curve_points <- read_input("curves")
derivative_points_all <- read_input("derivatives")
plateau_summary_all <- read_input("plateaus")
photoperiod_rows <- read_input("rugs")
figure_settings <- read_input("settings")
metric_registry <- read_input("metric_registry")

metric_source_map <- tibble::tribble(
  ~metric_order, ~metric_id,
  1L, "daily_geometric_mean_medi",
  2L, "m10_mean_medi",
  3L, "l10_mean_medi",
  4L, "duration_above_1000",
  5L, "duration_above_250_wake",
  6L, "duration_below_10_pre_sleep",
  7L, "duration_below_1_sleep_environment",
  8L, "longest_bout_above_250",
  9L, "dose_time_sensitive_corrected_medi"
)
metric_ids <- metric_source_map$metric_id
method_id <- "REVISED_CENTRAL_UNCONDITIONAL_POINTWISE"
panel_levels <- c("Fitted metric value", "First derivative")

metric_display <- metric_registry |>
  dplyr::filter(.data$metric_id %in% .env$metric_ids) |>
  dplyr::select("metric_id", "manuscript_name", "display_unit") |>
  dplyr::inner_join(metric_source_map, by = "metric_id") |>
  dplyr::arrange(.data$metric_order)
stopifnot(
  nrow(metric_display) == 9L,
  identical(metric_display$metric_id, metric_ids),
  !anyNA(metric_display$manuscript_name),
  !anyNA(metric_display$display_unit)
)

facet_registry <- tidyr::crossing(
  metric_id = metric_ids,
  panel_kind = factor(panel_levels, levels = panel_levels)
) |>
  dplyr::left_join(metric_display, by = "metric_id") |>
  dplyr::arrange(.data$metric_order, .data$panel_kind) |>
  dplyr::mutate(
    facet_label = dplyr::if_else(
      .data$panel_kind == "Fitted metric value",
      paste0(
        stringr::str_wrap(.data$manuscript_name, width = 36),
        "\nFitted value (",
        .data$display_unit,
        ")"
      ),
      paste0(
        stringr::str_wrap(.data$manuscript_name, width = 36),
        "\nFirst derivative (model scale/h)"
      )
    )
  )
facet_levels <- facet_registry$facet_label

derivative_points <- derivative_points_all |>
  dplyr::filter(.data$method_id == .env$method_id)
plateau_summary <- plateau_summary_all |>
  dplyr::filter(.data$method_id == .env$method_id)
recorded_ranges <- derivative_points |>
  dplyr::group_by(.data$placement, .data$metric_id) |>
  dplyr::summarise(
    recorded_min = min(.data$photoperiod_hours),
    recorded_max = max(.data$photoperiod_hours),
    .groups = "drop"
  )

smooth <- curve_points |>
  dplyr::inner_join(recorded_ranges, by = c("placement", "metric_id")) |>
  dplyr::filter(
    .data$placement == "near_eye",
    .data$photoperiod_hours >= .data$recorded_min,
    .data$photoperiod_hours <= .data$recorded_max
  ) |>
  dplyr::transmute(
    metric_id = .data$metric_id,
    photoperiod_hours = .data$photoperiod_hours,
    estimate = .data$response_estimate,
    lower = .data$response_lower_pointwise,
    upper = .data$response_upper_pointwise
  ) |>
  dplyr::arrange(
    match(.data$metric_id, .env$metric_ids),
    .data$photoperiod_hours
  )
derivative <- derivative_points |>
  dplyr::filter(.data$placement == "near_eye") |>
  dplyr::transmute(
    metric_id = .data$metric_id,
    photoperiod_hours = .data$photoperiod_hours,
    estimate = .data$derivative_estimate,
    lower = .data$derivative_lower,
    upper = .data$derivative_upper
  ) |>
  dplyr::arrange(
    match(.data$metric_id, .env$metric_ids),
    .data$photoperiod_hours
  )
transitions <- tidyr::crossing(
  plateau_summary |>
    dplyr::filter(
      .data$placement == "near_eye",
      .data$revised_plateau_pattern
    ),
  panel_kind = panel_levels
) |>
  dplyr::select(
    "metric_id",
    "panel_kind",
    "plateau_start",
    "recorded_photoperiod_max",
    "revised_plateau_pattern"
  ) |>
  dplyr::arrange(
    match(.data$metric_id, .env$metric_ids),
    .data$panel_kind
  )
rugs <- photoperiod_rows |>
  dplyr::filter(.data$placement == "near_eye") |>
  dplyr::select("metric_id", "photoperiod_hours") |>
  dplyr::arrange(
    match(.data$metric_id, .env$metric_ids),
    .data$photoperiod_hours
  )

frame_hash <- function(frame) {
  digest::digest(frame, algo = "sha256", serialize = TRUE)
}
numeric_expected <- c(
  smooth = "3864924670d2bde1c7246f831473ea629e46ccddcc6a56705a42ece7e9e45b3d",
  derivative = "7d8cb91b12a29d5778b6c18e76bcf9c0c405a04df37b3d968c774b1d7ea52546",
  transitions = "2f88583e51f80f7413225012d9a51ba1ad0cf7b4c8ec2f0cc4a65fccdf641bd8",
  rugs = "c297ae67957a060ebac21224818c314a595e1dc5546c0c490e575ad0a1a5fcba"
)
numeric_frames <- list(
  smooth = smooth,
  derivative = derivative,
  transitions = transitions,
  rugs = rugs
)
numeric_observed <- vapply(numeric_frames, frame_hash, character(1))
numeric_checks <- data.frame(
  component = names(numeric_frames),
  rows = vapply(numeric_frames, nrow, integer(1)),
  columns = vapply(numeric_frames, ncol, integer(1)),
  expected_serialized_sha256 = unname(numeric_expected),
  observed_serialized_sha256 = unname(numeric_observed),
  missing_values = vapply(
    numeric_frames,
    function(frame) sum(!stats::complete.cases(frame)),
    integer(1)
  ),
  status = ifelse(
    unname(numeric_observed) == unname(numeric_expected),
    "PASS",
    "FAIL"
  ),
  stringsAsFactors = FALSE
)
stopifnot(
  identical(numeric_checks$rows, c(918L, 900L, 12L, 7011L)),
  identical(numeric_checks$columns, c(5L, 5L, 5L, 2L)),
  all(numeric_checks$missing_values == 0L),
  all(numeric_checks$status == "PASS")
)

layer_expected <- data.frame(
  layer = 1:6,
  layer_name = c(
    "qualifying-tail rectangles",
    "derivative zero reference",
    "pointwise interval ribbons",
    "fitted and derivative lines",
    "qualifying-transition lines",
    "observed photoperiod rugs"
  ),
  source_rows = c(12L, 9L, 1818L, 1818L, 12L, 7011L),
  built_rows = c(12L, 9L, 1818L, 1818L, 12L, 7011L),
  panels = c(12L, 9L, 18L, 18L, 12L, 9L),
  stringsAsFactors = FALSE
)
layer_observed <- readr::read_csv(
  file.path(evidence_dir, "attempt_01_layer_row_map.csv"),
  show_col_types = FALSE
)
stopifnot(
  all(layer_observed$layer == layer_expected$layer),
  identical(layer_observed$layer_name, layer_expected$layer_name),
  all(layer_observed$source_rows == layer_expected$source_rows),
  all(layer_observed$built_rows == layer_expected$built_rows),
  all(layer_observed$panels == layer_expected$panels),
  all(layer_observed$status == "PASS")
)
layer_checks <- layer_observed |>
  dplyr::mutate(validation_status = "PASS")

label_observed <- readr::read_csv(
  file.path(evidence_dir, "attempt_01_label_and_panel_order.csv"),
  show_col_types = FALSE
)
label_expected <- facet_registry |>
  dplyr::transmute(
    metric_order = .data$metric_order,
    metric_id = .data$metric_id,
    manuscript_name = .data$manuscript_name,
    display_unit = .data$display_unit,
    panel_kind = as.character(.data$panel_kind),
    facet_label = .data$facet_label
  )
stopifnot(
  nrow(label_observed) == 18L,
  all(label_observed$metric_order == label_expected$metric_order),
  identical(label_observed$metric_id, label_expected$metric_id),
  identical(label_observed$manuscript_name, label_expected$manuscript_name),
  identical(label_observed$display_unit, label_expected$display_unit),
  identical(label_observed$panel_kind, label_expected$panel_kind),
  identical(
    label_observed$facet_label,
    as.character(label_expected$facet_label)
  ),
  all(label_observed$status == "PASS")
)

near_setting <- figure_settings |>
  dplyr::filter(.data$placement == "near_eye")
stopifnot(
  nrow(near_setting) == 1L,
  near_setting$filename ==
    "H07_revised_smooth_derivative_pairs_near_eye.png",
  near_setting$arrangement ==
    "nine rows; fitted value left and first derivative right",
  near_setting$width_in == 9,
  near_setting$height_in == 18,
  near_setting$interval ==
    "unconditional pointwise 95% confidence interval",
  near_setting$derivative_method == method_id
)

doc <- xml2::read_xml(attempt_path, options = c("NOBLANKS", "NONET"))
svg_root <- xml2::xml_root(doc)
all_nodes <- xml2::xml_find_all(doc, "//*")
tag_counts <- table(xml2::xml_name(all_nodes))
expected_tags <- c(
  svg = 1L,
  clipPath = 37L,
  g = 74L,
  line = 7032L,
  polygon = 18L,
  polyline = 211L,
  rect = 69L,
  text = 201L,
  image = 0L,
  script = 0L,
  foreignObject = 0L
)
observed_tags <- vapply(
  names(expected_tags),
  function(tag) {
    value <- unname(tag_counts[tag])
    if (length(value) == 0L || is.na(value)) 0L else as.integer(value)
  },
  integer(1)
)
tag_checks <- data.frame(
  tag = names(expected_tags),
  expected = unname(expected_tags),
  observed = unname(observed_tags),
  status = ifelse(
    unname(observed_tags) == unname(expected_tags),
    "PASS",
    "FAIL"
  ),
  stringsAsFactors = FALSE
)
stopifnot(all(tag_checks$status == "PASS"))

node_attributes <- lapply(all_nodes, xml2::xml_attrs)
attribute_names <- unlist(lapply(node_attributes, names), use.names = FALSE)
attribute_values <- unlist(node_attributes, use.names = FALSE)
ids <- unlist(lapply(
  node_attributes,
  function(values) unname(values[names(values) == "id"])
), use.names = FALSE)
stopifnot(length(ids) > 0L, !anyDuplicated(ids))

url_matches <- regmatches(
  attribute_values,
  gregexpr("url\\(#[^)]+\\)", attribute_values, perl = TRUE)
)
url_refs <- unique(sub(
  "^url\\(#([^)]+)\\)$",
  "\\1",
  unlist(url_matches, use.names = FALSE),
  perl = TRUE
))
url_refs <- url_refs[nzchar(url_refs)]
href_values <- attribute_values[
  attribute_names %in% c("href", "xlink:href")
]
local_href_refs <- sub("^#", "", href_values[startsWith(href_values, "#")])
external_hrefs <- href_values[!startsWith(href_values, "#")]
all_local_refs <- unique(c(url_refs, local_href_refs))
stopifnot(
  length(external_hrefs) == 0L,
  all(all_local_refs %in% ids)
)

svg_lines <- readLines(attempt_path, warn = FALSE, encoding = "UTF-8")
svg_text <- paste(svg_lines, collapse = "\n")
stopifnot(
  !grepl("data:image|base64,|@import", svg_text, ignore.case = TRUE),
  !grepl(
    "participant|subject|record_id|site_participant|person_id",
    svg_text,
    ignore.case = TRUE,
    perl = TRUE
  )
)

visible_nodes <- xml2::xml_find_all(doc, "//*[local-name()='text']")
visible_text <- stringr::str_squish(
  paste(xml2::xml_text(visible_nodes), collapse = " ")
)
required_visible <- c(
  metric_display$manuscript_name,
  "Fitted value (lx)",
  "Fitted value (h)",
  "Fitted value (lx·h)",
  "First derivative (model scale/h)",
  "Civil photoperiod (h)",
  "Each row pairs the response-scale fitted metric value (left)",
  "with the model-scale first derivative used for classification (right).",
  "Grey ribbons are unconditional pointwise 95% intervals; dashed lines",
  "and blue tails mark the derivative-defined plateau pattern.",
  "Near-eye — primary"
)
visible_present <- vapply(
  required_visible,
  function(label) grepl(label, visible_text, fixed = TRUE),
  logical(1)
)
stopifnot(all(visible_present))
visible_checks <- data.frame(
  text = required_visible,
  present = visible_present,
  status = "PASS",
  stringsAsFactors = FALSE
)

colour_matches <- unlist(
  regmatches(
    svg_text,
    gregexpr("#[0-9A-Fa-f]{6}", svg_text, perl = TRUE)
  ),
  use.names = FALSE
)
colour_counts <- table(toupper(colour_matches))
expected_colours <- c(
  `#000000` = 7012L,
  `#0072B2` = 12L,
  `#111827` = 18L,
  `#1A1A1A` = 38L,
  `#4B5563` = 9L,
  `#4D4D4D` = 157L,
  `#56B4E9` = 12L,
  `#9CA3AF` = 18L,
  `#EBEBEB` = 157L,
  `#F3F4F6` = 18L,
  `#FFFFFF` = 2L
)
observed_colours <- vapply(
  names(expected_colours),
  function(colour) {
    value <- unname(colour_counts[colour])
    if (length(value) == 0L || is.na(value)) 0L else as.integer(value)
  },
  integer(1)
)
colour_checks <- data.frame(
  colour = names(expected_colours),
  expected = unname(expected_colours),
  observed = unname(observed_colours),
  status = ifelse(
    unname(observed_colours) == unname(expected_colours),
    "PASS",
    "FAIL"
  ),
  stringsAsFactors = FALSE
)
stopifnot(
  all(colour_checks$status == "PASS"),
  length(colour_counts) == length(expected_colours)
)

structure_checks <- data.frame(
  check = c(
    "parseable XML",
    "root element",
    "intrinsic width",
    "intrinsic height",
    "viewBox",
    "native vector tag census",
    "raster image elements",
    "script elements",
    "foreignObject elements",
    "raster payload literals",
    "external href dependencies",
    "unique IDs",
    "resolving local references",
    "visible participant identifiers",
    "accepted visible labels and qualifications",
    "accepted colour census"
  ),
  observed = c(
    "PASS",
    xml2::xml_name(svg_root),
    xml2::xml_attr(svg_root, "width"),
    xml2::xml_attr(svg_root, "height"),
    xml2::xml_attr(svg_root, "viewBox"),
    paste0(sum(tag_checks$status == "PASS"), "/", nrow(tag_checks)),
    as.character(observed_tags[["image"]]),
    as.character(observed_tags[["script"]]),
    as.character(observed_tags[["foreignObject"]]),
    "0",
    as.character(length(external_hrefs)),
    sprintf("%d IDs; 0 duplicates", length(ids)),
    sprintf("%d/%d", sum(all_local_refs %in% ids), length(all_local_refs)),
    "0",
    sprintf("%d/%d", sum(visible_present), length(visible_present)),
    sprintf("%d/%d", sum(colour_checks$status == "PASS"), nrow(colour_checks))
  ),
  expected = c(
    "PASS",
    "svg",
    "648.00pt",
    "1296.00pt",
    "0 0 648.00 1296.00",
    paste0(nrow(tag_checks), "/", nrow(tag_checks)),
    "0",
    "0",
    "0",
    "0",
    "0",
    "unique",
    "all",
    "0",
    paste0(length(visible_present), "/", length(visible_present)),
    paste0(nrow(colour_checks), "/", nrow(colour_checks))
  ),
  status = "PASS",
  stringsAsFactors = FALSE
)
stopifnot(
  xml2::xml_name(svg_root) == "svg",
  xml2::xml_attr(svg_root, "width") == "648.00pt",
  xml2::xml_attr(svg_root, "height") == "1296.00pt",
  xml2::xml_attr(svg_root, "viewBox") == "0 0 648.00 1296.00"
)

attempt_evidence_files <- c(
  "attempt_01_input_use.csv",
  "attempt_01_layer_row_map.csv",
  "attempt_01_numeric_input_audit.csv",
  "attempt_01_label_and_panel_order.csv",
  "attempt_01_derivative_state_counts.csv",
  "attempt_01_state_contract.csv",
  "attempt_01_export_record.csv"
)
attempt_evidence_status <- vapply(
  file.path(evidence_dir, attempt_evidence_files),
  function(path) {
    frame <- readr::read_csv(path, show_col_types = FALSE)
    status_columns <- intersect(c("status", "validation_status"), names(frame))
    if (length(status_columns) == 0L) {
      FALSE
    } else {
      all(unlist(frame[status_columns], use.names = FALSE) %in%
        c("PASS", "EXPORTED_AWAITING_STATIC_GATE"))
    }
  },
  logical(1)
)
stopifnot(all(attempt_evidence_status))

write_evidence(numeric_checks, "candidate_numeric_input_checks.csv")
write_evidence(layer_checks, "candidate_layer_row_checks.csv")
write_evidence(label_observed, "candidate_label_and_panel_order_checks.csv")
write_evidence(tag_checks, "candidate_svg_tag_census.csv")
write_evidence(colour_checks, "candidate_svg_colour_census.csv")
write_evidence(visible_checks, "candidate_visible_text_checks.csv")
write_evidence(structure_checks, "candidate_svg_structure_checks.csv")

dir.create(candidate_dir, recursive = FALSE, showWarnings = FALSE)
stopifnot(dir.exists(candidate_dir), !file.exists(candidate_path))
copy_ok <- file.copy(attempt_path, candidate_path, overwrite = FALSE)
stopifnot(
  isTRUE(copy_ok),
  file.exists(candidate_path),
  identical(sha256_file(candidate_path), attempt_expected_sha256),
  identical(as.numeric(file.info(candidate_path)$size), attempt_expected_bytes)
)

candidate_identity <- data.frame(
  status = "STATIC_PASS_AWAITING_VISUAL_LEASE_AND_INDEPENDENT_ACCEPTANCE",
  path = substring(candidate_path, nchar(root) + 2L),
  sha256 = sha256_file(candidate_path),
  bytes = as.numeric(file.info(candidate_path)$size),
  source_attempt = substring(attempt_path, nchar(root) + 2L),
  source_attempt_sha256 = sha256_file(attempt_path),
  byte_identical_to_attempt = TRUE,
  actual_svg_trials = 1L,
  renderer_corrections = 0L,
  stringsAsFactors = FALSE
)
write_evidence(candidate_identity, "candidate_identity.csv")

cat(sprintf(
  paste0(
    "ORDER72J_H07_STATIC_GATE=PASS candidate_sha256=%s bytes=%d ",
    "numeric=%d/%d layers=%d/%d svg=%d/%d visual_qa=NOT_RUN\n"
  ),
  candidate_identity$sha256,
  candidate_identity$bytes,
  sum(numeric_checks$status == "PASS"),
  nrow(numeric_checks),
  sum(layer_checks$validation_status == "PASS"),
  nrow(layer_checks),
  sum(structure_checks$status == "PASS"),
  nrow(structure_checks)
))
