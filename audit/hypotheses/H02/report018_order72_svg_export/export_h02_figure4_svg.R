#!/usr/bin/env Rscript

# Export the frozen H02 Main Figure 2 display as a candidate native SVG.

options(warn = 2)

project_root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
output_root <- file.path(
  project_root,
  "audit",
  "hypotheses",
  "H02",
  "report018_order72_svg_export"
)
candidate_directory <- file.path(output_root, "candidate")
qa_directory <- file.path(output_root, "qa")
stopped_path <- file.path(
  output_root,
  "REPORT018-ORDER72-SVG-REVIEW-stopped.md"
)

hash_file <- function(path) {
  digest::digest(
    object = path,
    algo = "sha256",
    file = TRUE,
    serialize = FALSE
  )
}

file_identity <- function(path) {
  info <- file.info(path)
  data.frame(
    path = path,
    sha256 = hash_file(path),
    bytes = unname(info$size),
    stringsAsFactors = FALSE
  )
}

write_csv <- function(data, path) {
  utils::write.csv(
    data,
    file = path,
    row.names = FALSE,
    na = "",
    fileEncoding = "UTF-8"
  )
}

assert_true <- function(condition, message) {
  if (!isTRUE(condition)) {
    stop(message, call. = FALSE)
  }
  invisible(TRUE)
}

assignment_name <- function(expression) {
  if (
    is.call(expression) &&
      identical(expression[[1L]], as.name("<-")) &&
      is.symbol(expression[[2L]])
  ) {
    return(as.character(expression[[2L]]))
  }
  NA_character_
}

run_sips <- function(input, output, width, height) {
  arguments <- c(
    "-s",
    "format",
    "png",
    "-z",
    as.character(height),
    as.character(width),
    input,
    "--out",
    output
  )
  status <- system2(
    command = "/usr/bin/sips",
    args = arguments,
    stdout = TRUE,
    stderr = TRUE
  )
  exit_status <- attr(status, "status")
  if (is.null(exit_status)) {
    exit_status <- 0L
  }
  assert_true(
    identical(as.integer(exit_status), 0L),
    paste("sips failed:", paste(status, collapse = " | "))
  )
  invisible(status)
}

png_dimensions <- function(path) {
  image <- png::readPNG(path, native = TRUE)
  data.frame(
    path = path,
    pixel_width = ncol(image),
    pixel_height = nrow(image),
    stringsAsFactors = FALSE
  )
}

sampled_native_comparison <- function(reference, candidate, step) {
  reference_image <- png::readPNG(reference, native = TRUE)
  candidate_image <- png::readPNG(candidate, native = TRUE)
  assert_true(
    identical(dim(reference_image), dim(candidate_image)),
    "Reference and candidate raster dimensions differ."
  )

  row_index <- seq.int(1L, nrow(reference_image), by = step)
  column_index <- seq.int(1L, ncol(reference_image), by = step)
  reference_pixels <- as.integer(reference_image[row_index, column_index])
  candidate_pixels <- as.integer(candidate_image[row_index, column_index])

  absolute_differences <- unlist(
    lapply(c(0L, 8L, 16L), function(shift) {
      reference_channel <- bitwAnd(
        bitwShiftR(reference_pixels, shift),
        255L
      )
      candidate_channel <- bitwAnd(
        bitwShiftR(candidate_pixels, shift),
        255L
      )
      abs(reference_channel - candidate_channel)
    }),
    use.names = FALSE
  )

  data.frame(
    reference = reference,
    candidate = candidate,
    sample_step_pixels = step,
    sampled_pixels = length(reference_pixels),
    sampled_channels = length(absolute_differences),
    mean_absolute_channel_difference_0_255 = mean(absolute_differences),
    root_mean_square_channel_difference_0_255 = sqrt(
      mean(absolute_differences^2)
    ),
    percentile_95_absolute_channel_difference_0_255 = unname(
      stats::quantile(absolute_differences, 0.95)
    ),
    fraction_channels_within_1 = mean(absolute_differences <= 1L),
    fraction_channels_within_8 = mean(absolute_differences <= 8L),
    fraction_exact_pixels = mean(reference_pixels == candidate_pixels),
    stringsAsFactors = FALSE
  )
}

main <- function() {
  assert_true(
    identical(as.character(getRversion()), "4.6.1"),
    paste("R 4.6.1 is required; found", as.character(getRversion()))
  )

  required_packages <- c(
    "cowplot",
    "digest",
    "dplyr",
    "ggplot2",
    "ggtext",
    "legendry",
    "LightLogR",
    "patchwork",
    "png",
    "svglite",
    "systemfonts",
    "tibble",
    "tidyr",
    "xml2"
  )
  available <- vapply(
    required_packages,
    requireNamespace,
    logical(1),
    quietly = TRUE
  )
  assert_true(
    all(available),
    paste(
      "Required packages are unavailable:",
      paste(names(available)[!available], collapse = ", ")
    )
  )

  suppressPackageStartupMessages({
    library(cowplot)
    library(dplyr)
    library(ggplot2)
    library(ggtext)
    library(legendry)
    library(patchwork)
    library(tibble)
    library(tidyr)
  })

  release_manifest_path <- file.path(
    project_root,
    "audit",
    "report_harmonization",
    "report018_order72_release",
    "release_manifest.csv"
  )
  release_order_path <- file.path(
    project_root,
    "audit",
    "report_harmonization",
    "owner_orders",
    "72_manuscript_svg_exports_released.md"
  )
  proposal_path <- file.path(
    project_root,
    "audit",
    "report_harmonization",
    "owner_orders",
    "72_manuscript_svg_exports_proposed.md"
  )
  expected_release_identities <- data.frame(
    path = c(
      release_manifest_path,
      release_order_path,
      proposal_path
    ),
    sha256 = c(
      "8e25aa779f0115a3a5da9ffcdc3913b81cd6fb06df0c17c9f6d5825356263526",
      "d14575d7c262b01fe58ba85d343f966d5953601a0fb41cc0f61c25279eb4071c",
      "d3f329a2149149663c47e5db4514cbb7771b0afb6362afc8b911871068d0ebcd"
    ),
    stringsAsFactors = FALSE
  )
  release_identity_check <- do.call(
    rbind,
    lapply(expected_release_identities$path, file_identity)
  )
  release_identity_check$expected_sha256 <- expected_release_identities$sha256
  release_identity_check$status <- ifelse(
    release_identity_check$sha256 == release_identity_check$expected_sha256,
    "PASS",
    "FAIL"
  )
  assert_true(
    all(release_identity_check$status == "PASS"),
    "A controlling Order 72 release identity changed."
  )

  release_manifest <- utils::read.csv(
    release_manifest_path,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  assert_true(
    nrow(release_manifest) == 71L && !anyDuplicated(release_manifest$path),
    "The release manifest is not the expected unique 71-row manifest."
  )
  absolute_release_paths <- file.path(project_root, release_manifest$path)
  assert_true(
    all(file.exists(absolute_release_paths)),
    "At least one released input or protected file is missing."
  )
  current_hashes <- vapply(
    absolute_release_paths,
    hash_file,
    character(1)
  )
  current_bytes <- unname(file.info(absolute_release_paths)$size)
  release_manifest_check <- transform(
    release_manifest,
    current_sha256 = current_hashes,
    current_bytes = current_bytes,
    status = ifelse(
      sha256 == current_hashes & bytes == current_bytes,
      "PASS",
      "FAIL"
    )
  )
  assert_true(
    all(release_manifest_check$status == "PASS"),
    "At least one released input or protected identity changed before export."
  )

  h02_input_paths <- c(
    "artifacts/10_figures/H02/figure4_exact_layout_replication.png",
    "artifacts/10_figures/H02/figure4_exact_layout_replication.pdf",
    "artifacts/11_source_data/H02/figure4_exact_layout_source.rds",
    "scripts/hypotheses/H02/build_h02_figure4_replication.R",
    "scripts/hypotheses/H02/h02_figure4_pointwise.R",
    "scripts/Brown_bracket.R"
  )
  h02_manifest_rows <- release_manifest_check[
    match(h02_input_paths, release_manifest_check$path),
    ,
    drop = FALSE
  ]
  assert_true(
    identical(h02_manifest_rows$path, h02_input_paths) &&
      all(h02_manifest_rows$status == "PASS"),
    "The six H02 input pins were not reproduced exactly."
  )

  dir.create(candidate_directory, recursive = TRUE, showWarnings = FALSE)
  dir.create(qa_directory, recursive = TRUE, showWarnings = FALSE)

  write_csv(
    release_identity_check,
    file.path(output_root, "release_identity_check.csv")
  )
  write_csv(
    release_manifest_check,
    file.path(output_root, "pre_export_release_manifest_check.csv")
  )
  write_csv(
    h02_manifest_rows,
    file.path(output_root, "h02_input_pin_check.csv")
  )

  package_versions <- data.frame(
    package = required_packages,
    version = vapply(
      required_packages,
      function(package) as.character(utils::packageVersion(package)),
      character(1)
    ),
    stringsAsFactors = FALSE
  )
  write_csv(package_versions, file.path(output_root, "package_versions.csv"))
  writeLines(
    c(
      paste0("R version: ", R.version.string),
      "Library paths:",
      paste0("- ", .libPaths())
    ),
    con = file.path(output_root, "environment.txt"),
    useBytes = TRUE
  )
  writeLines(
    capture.output(utils::sessionInfo()),
    con = file.path(output_root, "session_info.txt"),
    useBytes = TRUE
  )

  source_rds_path <- file.path(project_root, h02_input_paths[[3L]])
  pointwise_helper_path <- file.path(project_root, h02_input_paths[[5L]])
  bracket_helper_path <- file.path(project_root, h02_input_paths[[6L]])

  parsed_helper <- parse(pointwise_helper_path, keep.source = TRUE)
  parsed_assignment_names <- vapply(
    parsed_helper,
    assignment_name,
    character(1)
  )
  layout_index <- which(parsed_assignment_names == "h02_build_figure4_layout")
  assert_true(
    length(layout_index) == 1L,
    "The pure H02 layout function was not found exactly once."
  )

  plot_environment <- new.env(parent = globalenv())
  eval(parsed_helper[[layout_index]], envir = plot_environment)
  sys.source(
    bracket_helper_path,
    envir = plot_environment,
    keep.source = TRUE
  )
  assert_true(
    is.function(plot_environment$h02_build_figure4_layout) &&
      exists("Brown_bracket", envir = plot_environment, inherits = FALSE),
    "The isolated layout function or bracket helper was unavailable."
  )

  source_data <- readRDS(source_rds_path)
  required_source_names <- c(
    "display_registry",
    "participant_days",
    "common_curve",
    "participant_curves",
    "site_curves",
    "primary_deviations",
    "site_solar",
    "overall_solar"
  )
  assert_true(
    all(required_source_names %in% names(source_data)),
    "The frozen plotting RDS lacks a required layout field."
  )
  assert_true(
    identical(as.integer(source_data$participant_days), 816L) &&
      nrow(source_data$display_registry) == 9L &&
      nrow(source_data$common_curve) == 48L &&
      nrow(source_data$participant_curves) == 6768L &&
      nrow(source_data$site_curves) == 432L &&
      nrow(source_data$primary_deviations) == 432L &&
      nrow(source_data$site_solar) == 9L,
    "The frozen plotting-source dimensions do not match the accepted display."
  )

  display_registry <- source_data$display_registry |>
    dplyr::arrange(.data$display_order)
  display_levels <- as.character(display_registry$display_name)
  palette <- stats::setNames(
    display_registry$color_hex,
    display_registry$display_name
  )
  overall_night <- tibble::tibble(
    xmin = c(0, source_data$overall_solar$mean_civil_dusk_hour),
    xmax = c(source_data$overall_solar$mean_civil_dawn_hour, 24)
  )
  site_night <- source_data$site_solar |>
    dplyr::select(
      "site",
      "display_name",
      "display_order",
      "mean_civil_dawn_hour",
      "mean_civil_dusk_hour"
    ) |>
    tidyr::uncount(2L, .id = "night_segment") |>
    dplyr::mutate(
      xmin = dplyr::if_else(
        .data$night_segment == 1L,
        0,
        .data$mean_civil_dusk_hour
      ),
      xmax = dplyr::if_else(
        .data$night_segment == 1L,
        .data$mean_civil_dawn_hour,
        24
      )
    )
  background_site_curves <- tidyr::crossing(
    panel_display_name = factor(display_levels, levels = display_levels),
    source_data$site_curves |>
      dplyr::transmute(
        source_site = .data$site,
        time_hour = .data$time_hour,
        estimate_melEDI_lx = .data$estimate_melEDI_lx,
        pointwise_lower_melEDI_lx = .data$pointwise_lower_melEDI_lx,
        pointwise_upper_melEDI_lx = .data$pointwise_upper_melEDI_lx
      )
  )

  figure_contract <- list(
    placement_label = "Near-eye",
    participant_days = source_data$participant_days,
    display_registry = display_registry,
    display_levels = display_levels,
    palette = palette,
    common_curve = source_data$common_curve,
    participant_curves = source_data$participant_curves,
    site_curves = source_data$site_curves,
    background_site_curves = background_site_curves,
    primary_deviations = source_data$primary_deviations,
    site_solar = source_data$site_solar,
    overall_solar = source_data$overall_solar,
    overall_night = overall_night,
    site_night = site_night
  )
  figure <- plot_environment$h02_build_figure4_layout(figure_contract)
  assert_true(
    inherits(figure, "patchwork"),
    "The isolated H02 layout did not return the accepted four-panel class."
  )

  layout_expression_text <- paste(
    deparse(parsed_helper[[layout_index]], width.cutoff = 500L),
    collapse = "\n"
  )
  extraction_checks <- data.frame(
    check = c(
      "parsed_top_level_expressions",
      "layout_assignment_count",
      "broad_contract_builder_evaluated",
      "layout_expression_sha256",
      "frozen_source_rows"
    ),
    result = c(
      as.character(length(parsed_helper)),
      as.character(length(layout_index)),
      "FALSE",
      digest::digest(
        layout_expression_text,
        algo = "sha256",
        serialize = FALSE
      ),
      paste(
        nrow(source_data$common_curve),
        nrow(source_data$participant_curves),
        nrow(source_data$site_curves),
        nrow(source_data$primary_deviations),
        sep = "/"
      )
    ),
    status = "PASS",
    stringsAsFactors = FALSE
  )
  write_csv(
    extraction_checks,
    file.path(output_root, "source_extraction_checks.csv")
  )

  candidate_svg <- file.path(
    candidate_directory,
    "figure4_exact_layout_replication.svg"
  )
  svglite::svglite(
    filename = candidate_svg,
    width = 11,
    height = 14,
    bg = "white",
    pointsize = 12,
    standalone = TRUE,
    fix_text_size = TRUE
  )
  device_open <- TRUE
  tryCatch(
    print(figure),
    finally = {
      if (isTRUE(device_open)) {
        grDevices::dev.off()
        device_open <- FALSE
      }
    }
  )
  assert_true(file.exists(candidate_svg), "The candidate SVG was not written.")

  svg_text <- paste(
    readLines(candidate_svg, warn = FALSE, encoding = "UTF-8"),
    collapse = "\n"
  )
  svg_document <- xml2::read_xml(candidate_svg)
  svg_root <- xml2::xml_root(svg_document)
  svg_width <- xml2::xml_attr(svg_root, "width")
  svg_height <- xml2::xml_attr(svg_root, "height")
  svg_view_box <- xml2::xml_attr(svg_root, "viewBox")
  width_points <- as.numeric(sub("pt$", "", svg_width))
  height_points <- as.numeric(sub("pt$", "", svg_height))
  view_box_values <- as.numeric(strsplit(svg_view_box, "[ ,]+")[[1L]])
  assert_true(
    isTRUE(all.equal(width_points, 792, tolerance = 0.01)) &&
      isTRUE(all.equal(height_points, 1008, tolerance = 0.01)) &&
      length(view_box_values) == 4L &&
      isTRUE(all.equal(view_box_values, c(0, 0, 792, 1008), tolerance = 0.01)),
    "The SVG canvas or viewBox differs from the accepted 11 by 14 inch geometry."
  )

  node_count <- function(name) {
    length(xml2::xml_find_all(
      svg_document,
      paste0(".//*[local-name()='", name, "']")
    ))
  }
  vector_counts <- data.frame(
    element = c(
      "path",
      "polyline",
      "polygon",
      "line",
      "rect",
      "circle",
      "text"
    ),
    count = vapply(
      c("path", "polyline", "polygon", "line", "rect", "circle", "text"),
      node_count,
      integer(1)
    ),
    stringsAsFactors = FALSE
  )
  assert_true(
    sum(vector_counts$count[vector_counts$element != "text"]) > 0L &&
      vector_counts$count[vector_counts$element == "text"] > 0L,
    "The SVG lacks native vector drawing or text elements."
  )

  forbidden_node_counts <- data.frame(
    element = c("image", "script", "foreignObject"),
    count = vapply(
      c("image", "script", "foreignObject"),
      node_count,
      integer(1)
    ),
    stringsAsFactors = FALSE
  )
  assert_true(
    all(forbidden_node_counts$count == 0L),
    "The SVG contains a raster, script, or foreign-object node."
  )

  all_nodes <- xml2::xml_find_all(svg_document, ".//*")
  all_attributes <- unlist(lapply(all_nodes, xml2::xml_attrs), use.names = TRUE)
  href_values <- all_attributes[
    names(all_attributes) %in% c("href", "xlink:href")
  ]
  external_href_values <- href_values[!startsWith(href_values, "#")]
  assert_true(
    length(external_href_values) == 0L &&
      !grepl(
        "data:image|base64,|@font-face|@import",
        svg_text,
        ignore.case = TRUE
      ),
    "The SVG contains an embedded raster payload or external resource."
  )

  text_nodes <- trimws(xml2::xml_text(xml2::xml_find_all(
    svg_document,
    ".//*[local-name()='text']"
  )))
  expected_visible_text <- c(
    "A",
    "B",
    "C",
    "D",
    "Near-eye melEDI (lx)",
    "Local time (hrs)",
    "Site / global time effect",
    "sleep",
    "evening",
    "daytime",
    paste0(
      "n = ",
      format(source_data$participant_days, big.mark = ","),
      " participant-days (d)"
    ),
    display_levels,
    paste0(
      "n = ",
      format(source_data$site_solar$fitted_participant_days, big.mark = ","),
      " d"
    )
  )
  visible_text_check <- data.frame(
    token = expected_visible_text,
    present = expected_visible_text %in% text_nodes,
    stringsAsFactors = FALSE
  )
  assert_true(
    all(visible_text_check$present),
    paste(
      "Expected visible SVG text is missing:",
      paste(
        visible_text_check$token[!visible_text_check$present],
        collapse = ", "
      )
    )
  )

  participant_ids <- unique(as.character(
    source_data$participant_curves$participant
  ))
  participant_identifier_hits <- participant_ids[vapply(
    participant_ids,
    grepl,
    logical(1),
    x = svg_text,
    fixed = TRUE
  )]
  hidden_field_markers <- c(
    "participant_eta",
    "standard_error_conditional",
    "pointwise_lower_melEDI_lx",
    "primary_deviations"
  )
  hidden_field_hits <- hidden_field_markers[vapply(
    hidden_field_markers,
    grepl,
    logical(1),
    x = svg_text,
    fixed = TRUE
  )]
  assert_true(
    length(participant_identifier_hits) == 0L &&
      length(hidden_field_hits) == 0L,
    "The SVG exposes a participant identifier or hidden plotting-field name."
  )

  font_families <- unique(unlist(regmatches(
    svg_text,
    gregexpr('font-family: "[^"]+"', svg_text, perl = TRUE)
  )))
  font_families <- sub('^font-family: "', "", font_families)
  font_families <- sub('"$', "", font_families)
  if (length(font_families) == 0L) {
    font_families <- "sans"
  }
  matched_fonts <- systemfonts::match_fonts(font_families)
  assert_true(
    all(nzchar(matched_fonts$path) & file.exists(matched_fonts$path)),
    "At least one SVG font family did not resolve locally."
  )
  font_check <- data.frame(
    requested_family = font_families,
    resolved_path = matched_fonts$path,
    resolved_index = matched_fonts$index,
    status = "PASS",
    stringsAsFactors = FALSE
  )

  svg_metadata <- data.frame(
    path = candidate_svg,
    sha256 = hash_file(candidate_svg),
    bytes = unname(file.info(candidate_svg)$size),
    width = svg_width,
    height = svg_height,
    view_box = svg_view_box,
    native_vector_elements = sum(vector_counts$count[
      vector_counts$element != "text"
    ]),
    text_elements = vector_counts$count[vector_counts$element == "text"],
    raster_nodes = forbidden_node_counts$count[
      forbidden_node_counts$element == "image"
    ],
    script_nodes = forbidden_node_counts$count[
      forbidden_node_counts$element == "script"
    ],
    external_hrefs = length(external_href_values),
    participant_identifier_hits = length(participant_identifier_hits),
    hidden_field_hits = length(hidden_field_hits),
    stringsAsFactors = FALSE
  )
  write_csv(svg_metadata, file.path(output_root, "svg_metadata.csv"))
  write_csv(
    vector_counts,
    file.path(output_root, "svg_vector_element_counts.csv")
  )
  write_csv(
    forbidden_node_counts,
    file.path(output_root, "svg_forbidden_node_counts.csv")
  )
  write_csv(
    visible_text_check,
    file.path(output_root, "svg_visible_text_check.csv")
  )
  write_csv(font_check, file.path(output_root, "svg_font_resolution_check.csv"))

  accepted_png <- file.path(project_root, h02_input_paths[[1L]])
  original_candidate_png <- file.path(
    qa_directory,
    "candidate_raster_3300x4200.png"
  )
  reader_width_mm <- 180
  reader_dpi <- 150
  reader_width_pixels <- round(reader_width_mm / 25.4 * reader_dpi)
  reader_height_pixels <- round(reader_width_pixels * 14 / 11)
  accepted_reader_png <- file.path(
    qa_directory,
    paste0(
      "accepted_reader_",
      reader_width_pixels,
      "x",
      reader_height_pixels,
      ".png"
    )
  )
  candidate_reader_png <- file.path(
    qa_directory,
    paste0(
      "candidate_reader_",
      reader_width_pixels,
      "x",
      reader_height_pixels,
      ".png"
    )
  )

  run_sips(candidate_svg, original_candidate_png, 3300L, 4200L)
  run_sips(
    accepted_png,
    accepted_reader_png,
    reader_width_pixels,
    reader_height_pixels
  )
  run_sips(
    candidate_svg,
    candidate_reader_png,
    reader_width_pixels,
    reader_height_pixels
  )

  raster_dimensions <- do.call(
    rbind,
    lapply(
      c(
        accepted_png,
        original_candidate_png,
        accepted_reader_png,
        candidate_reader_png
      ),
      png_dimensions
    )
  )
  expected_widths <- c(3300L, 3300L, reader_width_pixels, reader_width_pixels)
  expected_heights <- c(
    4200L,
    4200L,
    reader_height_pixels,
    reader_height_pixels
  )
  raster_dimensions$status <- ifelse(
    raster_dimensions$pixel_width == expected_widths &
      raster_dimensions$pixel_height == expected_heights,
    "PASS",
    "FAIL"
  )
  assert_true(
    all(raster_dimensions$status == "PASS"),
    "A comparison raster has the wrong pixel dimensions."
  )
  write_csv(raster_dimensions, file.path(output_root, "raster_dimensions.csv"))

  original_comparison <- sampled_native_comparison(
    accepted_png,
    original_candidate_png,
    step = 4L
  )
  original_comparison$comparison_scale <- "accepted_original_dimensions"
  reader_comparison <- sampled_native_comparison(
    accepted_reader_png,
    candidate_reader_png,
    step = 1L
  )
  reader_comparison$comparison_scale <- paste0(
    "intended_reader_width_",
    reader_width_mm,
    "mm_at_",
    reader_dpi,
    "dpi"
  )
  raster_comparison <- rbind(original_comparison, reader_comparison)
  write_csv(
    raster_comparison,
    file.path(output_root, "raster_comparison_metrics.csv")
  )

  reader_size <- data.frame(
    intended_reader_width_mm = reader_width_mm,
    retained_aspect_ratio = "11:14",
    raster_comparison_dpi = reader_dpi,
    pixel_width = reader_width_pixels,
    pixel_height = reader_height_pixels,
    native_svg_width_points = width_points,
    native_svg_height_points = height_points,
    scale_factor_from_native_width = (reader_width_mm / 25.4) / 11,
    stringsAsFactors = FALSE
  )
  write_csv(reader_size, file.path(output_root, "intended_reader_size.csv"))

  script_path <- normalizePath(
    file.path(output_root, "export_h02_figure4_svg.R"),
    winslash = "/",
    mustWork = TRUE
  )
  script_identity <- file_identity(script_path)
  write_csv(
    script_identity,
    file.path(output_root, "export_script_identity.csv")
  )

  post_hashes <- vapply(
    absolute_release_paths,
    hash_file,
    character(1)
  )
  post_bytes <- unname(file.info(absolute_release_paths)$size)
  post_export_check <- transform(
    release_manifest,
    current_sha256 = post_hashes,
    current_bytes = post_bytes,
    status = ifelse(
      sha256 == post_hashes & bytes == post_bytes,
      "PASS",
      "FAIL"
    )
  )
  assert_true(
    all(post_export_check$status == "PASS"),
    "A released input or protected identity changed during export."
  )
  write_csv(
    post_export_check,
    file.path(output_root, "post_export_release_manifest_check.csv")
  )

  command_lines <- c(
    paste(
      "RENV_CONFIG_AUTOLOADER_ENABLED=FALSE",
      paste0("NATHEALTH_PROJECT_ROOT=", shQuote(project_root)),
      "Rscript --vanilla",
      shQuote(script_path)
    ),
    paste(
      "/usr/bin/sips -s format png -z 4200 3300",
      shQuote(candidate_svg),
      "--out",
      shQuote(original_candidate_png)
    ),
    paste(
      "/usr/bin/sips -s format png -z",
      reader_height_pixels,
      reader_width_pixels,
      shQuote(accepted_png),
      "--out",
      shQuote(accepted_reader_png)
    ),
    paste(
      "/usr/bin/sips -s format png -z",
      reader_height_pixels,
      reader_width_pixels,
      shQuote(candidate_svg),
      "--out",
      shQuote(candidate_reader_png)
    )
  )
  writeLines(
    command_lines,
    con = file.path(output_root, "commands.txt"),
    useBytes = TRUE
  )

  writeLines(
    c(
      "# REPORT018-ORDER72-SVG-REVIEW candidate generated",
      "",
      "The H02 candidate SVG and comparison rasters passed automated source,",
      "native-vector, privacy, dimension, text, font, and protected-file checks.",
      "Human original-size and 180 mm reader-size visual comparison remains the",
      "mandatory final review before an owner completion seal is written."
    ),
    con = file.path(output_root, "candidate_generation_record.md"),
    useBytes = TRUE
  )

  message("REPORT018-ORDER72-SVG-CANDIDATE-GENERATED")
}

tryCatch(
  main(),
  error = function(error) {
    dir.create(output_root, recursive = TRUE, showWarnings = FALSE)
    writeLines(
      c(
        "# REPORT018-ORDER72-SVG-REVIEW stopped",
        "",
        paste(
          "The single H02 export attempt stopped:",
          conditionMessage(error)
        ),
        "",
        "No patch or retry was performed."
      ),
      con = stopped_path,
      useBytes = TRUE
    )
    message(conditionMessage(error))
    quit(save = "no", status = 1L, runLast = FALSE)
  }
)
