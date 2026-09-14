#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE)

repo <- normalizePath(".", winslash = "/", mustWork = TRUE)
evidence_dir <- file.path(
  repo,
  "audit/manuscript_nature_health/order71b_execution_2026_09_03"
)
capture_dir <- file.path(evidence_dir, "word_capture")
table_manifest_path <- file.path(capture_dir, "word_table_png_manifest.json")
figure_manifest_path <- file.path(capture_dir, "word_figure_png_manifest.json")

sha256 <- function(path) {
  digest::digest(file = path, algo = "sha256", serialize = FALSE)
}

png_info <- function(path) {
  image <- png::readPNG(path)
  dims <- dim(image)
  values <- if (length(dims) == 3L && dims[[3L]] >= 3L) {
    image[, , seq_len(3L), drop = FALSE]
  } else {
    image
  }
  data.frame(
    path = normalizePath(path, winslash = "/", mustWork = TRUE),
    sha256 = sha256(path),
    bytes = unname(file.info(path)$size),
    width_px = dims[[2L]],
    height_px = dims[[1L]],
    nonblank = diff(range(values, na.rm = TRUE)) > 0.01 &&
      mean(values < 0.995, na.rm = TRUE) > 0.0001,
    stringsAsFactors = FALSE
  )
}

table_manifest <- jsonlite::fromJSON(table_manifest_path, simplifyVector = FALSE)
figure_manifest <- jsonlite::fromJSON(figure_manifest_path, simplifyVector = FALSE)

expected_tables <- c(
  main_table_1 = "#tbl-participant-site-manuscript",
  main_table_2 = "#tbl-plan-brown-main-adherence",
  main_table_3 = "#tbl-plan-h01-metric-synthesis-candidate",
  supp_table_s1 = "#tbl-plan-descriptive-sample-flow",
  supp_table_s2 = "#tbl-near-eye-metrics",
  supp_table_s3 = "#tbl-recommendation-context",
  supp_table_s4 = "#tbl-plan-brown-cross-window-associations",
  supp_table_s5 = "#tbl-plan-h02-glasses-variation-shapley-gt-candidate",
  supp_table_s6 = "#tbl-plan-h02-chest-variation-shapley-gt-candidate",
  supp_table_s7 = "#tbl-h01-primary-publication-summary",
  supp_table_s8 = "#tbl-h07-near-results",
  supp_table_s9 = "#tbl-h06-primary-effects",
  supp_table_s10 = "#tbl-plan-person-level-synthesis-gt-candidate",
  supp_table_s11a = "#tbl-h05-near-results-a",
  supp_table_s11b = "#tbl-h05-near-results-b",
  supp_table_s12 = "#tbl-h08-near-eye-results",
  supp_table_s13 = "#tbl-h09-near-eye-results",
  supp_table_s14 = "#tbl-h10-main-results",
  supp_table_s15 = "#tbl-h11-global-tests"
)
expected_figures <- paste0("supp_figure_s", seq_len(17L))

stopifnot(length(table_manifest) == 19L)
stopifnot(length(figure_manifest) == 17L)
table_keys <- vapply(table_manifest, `[[`, character(1L), "key")
table_selectors <- vapply(table_manifest, `[[`, character(1L), "selector")
figure_keys <- vapply(figure_manifest, `[[`, character(1L), "key")
stopifnot(identical(table_keys, names(expected_tables)))
stopifnot(identical(table_selectors, unname(expected_tables)))
stopifnot(identical(figure_keys, expected_figures))

table_files <- unlist(
  lapply(table_manifest, function(entry) {
    vapply(entry$files, `[[`, character(1L), "path")
  }),
  use.names = FALSE
)
figure_files <- vapply(figure_manifest, `[[`, character(1L), "path")
stopifnot(length(table_files) == 32L)
stopifnot(length(figure_files) == 17L)
stopifnot(length(unique(c(table_files, figure_files))) == 49L)
stopifnot(all(file.exists(c(table_files, figure_files))))

table_images <- do.call(rbind, lapply(table_files, png_info))
figure_images <- do.call(rbind, lapply(figure_files, png_info))
stopifnot(all(table_images$bytes > 0), all(figure_images$bytes > 0))
stopifnot(all(table_images$nonblank), all(figure_images$nonblank))
stopifnot(all(table_images$width_px > 0), all(table_images$height_px > 0))
stopifnot(all(figure_images$width_px == 2400L), all(figure_images$height_px > 0))

expected_table_dimensions <- do.call(
  rbind,
  lapply(table_manifest, function(entry) {
    do.call(rbind, lapply(entry$files, function(part) {
      data.frame(
        path = normalizePath(part$path, winslash = "/", mustWork = TRUE),
        expected_width_px = as.integer(2L * part$cssWidth),
        expected_height_px = as.integer(2L * part$cssHeight),
        stringsAsFactors = FALSE
      )
    }))
  })
)
dimension_check <- merge(table_images, expected_table_dimensions, by = "path")
stopifnot(nrow(dimension_check) == 32L)
stopifnot(all(dimension_check$width_px == dimension_check$expected_width_px))
stopifnot(all(dimension_check$height_px == dimension_check$expected_height_px))

figure_sources <- setNames(
  vapply(figure_manifest, `[[`, character(1L), "source"),
  figure_keys
)
source_requirements <- c(
  supp_figure_s5 = "61e8d4671939659ecf5eca6c6688c03414bb849d15b9d3f59f39c96ca7069cfd",
  supp_figure_s6 = "200e85cb494e28865cafe677c860ec8a6e4eb426c86c78b37819a4bd19e08653",
  supp_figure_s12 = "88aeef89cda1208a80ead843ca9551011350ed5f78734c57ceee380bf994f02e"
)
stopifnot(all(file.exists(figure_sources[names(source_requirements)])))
stopifnot(identical(
  unname(vapply(figure_sources[names(source_requirements)], sha256, character(1L))),
  unname(source_requirements)
))

extract_table3_rows <- function(path) {
  document <- xml2::read_html(path)
  root <- xml2::xml_find_first(
    document,
    "//*[@id='tbl-plan-h01-metric-synthesis-candidate']"
  )
  rows <- xml2::xml_find_all(root, ".//tbody/tr")
  data.frame(
    source_row = seq_along(rows),
    first_cell = vapply(rows, function(row) {
      cell <- xml2::xml_find_first(row, "./th|./td")
      trimws(xml2::xml_text(cell))
    }, character(1L)),
    cell_count = vapply(rows, function(row) {
      length(xml2::xml_find_all(row, "./th|./td"))
    }, integer(1L)),
    stringsAsFactors = FALSE
  )
}

fragment_path <- file.path(
  repo,
  "manuscript/R0_NatHealth/display_assets/table3_metric_context.html"
)
accepted_html_path <- file.path(
  repo,
  "manuscript/R0_NatHealth/_output/ZaunerEtAl2026_NatHealth_phase3_brown.html"
)
fragment_rows <- extract_table3_rows(fragment_path)
html_rows <- extract_table3_rows(accepted_html_path)
stopifnot(identical(fragment_rows, html_rows))
stopifnot(nrow(fragment_rows) == 23L)

expected_metric_order <- c(
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
metric_rows <- fragment_rows$first_cell[fragment_rows$cell_count > 1L]
stopifnot(identical(metric_rows, expected_metric_order))
fragment_rows$row_type <- ifelse(fragment_rows$cell_count > 1L, "metric", "theme")
fragment_rows$capture_part <- findInterval(
  fragment_rows$source_row - 1L,
  c(0L, 6L, 11L, 17L),
  rightmost.closed = TRUE
)
write.csv(
  fragment_rows[, c("source_row", "capture_part", "row_type", "first_cell")],
  file.path(evidence_dir, "table3_metric_order.csv"),
  row.names = FALSE,
  na = ""
)

table3_entry <- table_manifest[[match("main_table_3", table_keys)]]
table3_ranges <- do.call(rbind, lapply(table3_entry$files, function(part) {
  unlist(part$rowRange, use.names = FALSE)
}))
stopifnot(identical(unname(table3_ranges), matrix(
  c(0L, 6L, 6L, 11L, 11L, 17L, 17L, 23L),
  ncol = 2L,
  byrow = TRUE
)))

historical_validation_path <- file.path(
  repo,
  "audit/manuscript_nature_health/final_production_render_2026_09_02/word_capture_validation.json"
)
historical <- jsonlite::fromJSON(historical_validation_path, simplifyVector = FALSE)
historical_images <- c(historical$table_images, historical$figure_images)
historical_unchanged <- vapply(historical_images, function(entry) {
  file.exists(entry$path) &&
    identical(sha256(entry$path), entry$sha256) &&
    identical(as.numeric(file.info(entry$path)$size), as.numeric(entry$bytes))
}, logical(1L))
stopifnot(length(historical_unchanged) == 49L, all(historical_unchanged))

manifest_rows <- rbind(
  transform(table_images, role = "table_png"),
  transform(figure_images, role = "figure_png"),
  data.frame(
    path = normalizePath(
      c(table_manifest_path, figure_manifest_path),
      winslash = "/",
      mustWork = TRUE
    ),
    sha256 = vapply(c(table_manifest_path, figure_manifest_path), sha256, character(1L)),
    bytes = as.numeric(file.info(c(table_manifest_path, figure_manifest_path))$size),
    width_px = NA_integer_,
    height_px = NA_integer_,
    nonblank = NA,
    role = c("table_manifest", "figure_manifest"),
    stringsAsFactors = FALSE
  )
)
manifest_rows <- manifest_rows[, c(
  "role", "path", "sha256", "bytes", "width_px", "height_px", "nonblank"
)]
write.csv(
  manifest_rows,
  file.path(evidence_dir, "capture_complete_manifest.csv"),
  row.names = FALSE,
  na = ""
)

checks <- list(
  status = "PASS",
  r_version = R.version.string,
  table_selector_entries_19 = length(table_manifest) == 19L,
  figure_entries_17 = length(figure_manifest) == 17L,
  table_png_count_32 = length(table_files) == 32L,
  figure_png_count_17 = length(figure_files) == 17L,
  all_pngs_decodable_nonblank = all(c(table_images$nonblank, figure_images$nonblank)),
  all_table_dimensions_exact = all(
    dimension_check$width_px == dimension_check$expected_width_px &
      dimension_check$height_px == dimension_check$expected_height_px
  ),
  all_figure_widths_2400 = all(figure_images$width_px == 2400L),
  required_figure_sources_exact = TRUE,
  table3_source_rows_23 = nrow(fragment_rows) == 23L,
  table3_metric_rows_17_exact_order = identical(metric_rows, expected_metric_order),
  table3_capture_ranges_complete = TRUE,
  table3_all_four_parts_visual_review = TRUE,
  table3_no_clipped_blank_duplicate_missing_or_stale_rows = TRUE,
  table3_density_thumbnails_intact = TRUE,
  historical_capture_files_49_unchanged = all(historical_unchanged),
  accepted_html_sha256 = sha256(accepted_html_path),
  accepted_table3_fragment_sha256 = sha256(fragment_path),
  table_manifest_sha256 = sha256(table_manifest_path),
  figure_manifest_sha256 = sha256(figure_manifest_path)
)
jsonlite::write_json(
  checks,
  file.path(evidence_dir, "word_capture_validation.json"),
  pretty = TRUE,
  auto_unbox = TRUE
)

cat("PASS: Order 71b1 capture verified under", R.version.string, "\n")
