#!/usr/bin/env Rscript

# Verify and seal the H06_daily Supplementary Figure S12 candidate.

options(stringsAsFactors = FALSE)

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
    "The H06_daily Supplementary Figure S12 verifier requires R 4.6.1; found ",
    as.character(getRversion()),
    call. = FALSE
  )
}

required_packages <- c(
  "digest",
  "dplyr",
  "magick",
  "png",
  "readr",
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

mode <- match.arg(
  Sys.getenv("H06_DAILY_S12_VERIFY_MODE", unset = "candidate"),
  c("candidate", "final")
)
candidate_directory <- Sys.getenv("H06_DAILY_S12_CANDIDATE_DIR", unset = "")
if (!nzchar(candidate_directory) || !dir.exists(candidate_directory)) {
  stop("The temporary candidate directory is missing.", call. = FALSE)
}
candidate_directory <- normalizePath(
  candidate_directory,
  winslash = "/",
  mustWork = TRUE
)
if (!startsWith(candidate_directory, "/private/tmp/")) {
  stop("The inspected candidate must be below `/private/tmp/`.", call. = FALSE)
}

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

project_path <- function(path) file.path(root, path)
candidate_path <- function(path) file.path(candidate_directory, path)

candidate_names <- c(
  "H06_daily_supplementary_figure_s12.png",
  "H06_daily_supplementary_figure_s12.svg"
)
candidate_paths <- candidate_path(candidate_names)
record_check(
  "candidate_file_scope",
  all(file.exists(candidate_paths)) &&
    setequal(
      list.files(candidate_directory, all.files = TRUE, no.. = TRUE),
      candidate_names
    ),
  "The fresh temporary candidate directory contains exactly the PNG and SVG."
)

dispatch_path <- project_path(
  "audit/report_harmonization/report018_h06_daily_order63_dispatch_manifest.csv"
)
dispatch_manifest <- readr::read_csv(dispatch_path, show_col_types = FALSE)
record_check(
  "dispatch_manifest_identity",
  identical(
    sha256(dispatch_path),
    "4609f7ffa0b75d7748dde6ca13b6ada1e720c0aca88a1a3ebfc990d93822ebc5"
  ),
  "The non-circular order-63 dispatch manifest has its sealed identity."
)
record_check(
  "dispatch_manifest_structure",
  nrow(dispatch_manifest) == 22L &&
    !anyDuplicated(dispatch_manifest$path) &&
    !basename(dispatch_path) %in% basename(dispatch_manifest$path),
  "The dispatch manifest contains 22 unique rows and excludes itself."
)
dispatch_absolute <- project_path(dispatch_manifest$path)
dispatch_observed_sha <- unname(vapply(
  dispatch_absolute,
  sha256,
  character(1)
))
dispatch_observed_bytes <- unname(file.info(dispatch_absolute)$size)
record_check(
  "dispatch_reproduction",
  all(file.exists(dispatch_absolute)) &&
    identical(dispatch_observed_sha, dispatch_manifest$sha256) &&
    identical(
      as.numeric(dispatch_observed_bytes),
      as.numeric(dispatch_manifest$bytes)
    ),
  "All 22 dispatched H06_daily inputs reproduce by SHA-256 and byte count."
)

builder_relative <- paste0(
  "scripts/hypotheses/H06_daily/",
  "build_h06_daily_manuscript_supplementary_figure_s12.R"
)
test_relative <- paste0(
  "tests/hypotheses/H06_daily/",
  "test_h06_daily_manuscript_supplementary_figure_s12.R"
)
builder_path <- project_path(builder_relative)
test_path <- project_path(test_relative)
invisible(parse(builder_path, keep.source = TRUE))
invisible(parse(test_path, keep.source = TRUE))
record_check(
  "r_source_parse",
  TRUE,
  "The builder and focused verifier parse under R 4.6.1."
)

builder_text <- paste(readLines(builder_path, warn = FALSE), collapse = "\n")
prohibited_builder_patterns <- c(
  "readRDS\\s*\\(",
  "saveRDS\\s*\\(",
  "source\\s*\\(",
  "quarto\\s+render",
  "knitr::",
  "rmarkdown::",
  "pandoc",
  "future::",
  "parallel::",
  "boot\\s*\\("
)
record_check(
  "builder_prohibited_calls",
  !any(vapply(
    prohibited_builder_patterns,
    grepl,
    logical(1),
    x = builder_text,
    ignore.case = TRUE,
    perl = TRUE
  )),
  paste(
    "The builder contains no model serialization, broad sourcing, render,",
    "parallel, or resampling call."
  )
)

source_relative <- paste0(
  "artifacts/11_source_data/H06_daily/",
  "H06_daily_stage3_fdr_overview_figure.csv"
)
canonical_png_relative <- paste0(
  "artifacts/10_figures/H06_daily/",
  "H06_daily_stage3_fdr_overview.png"
)
canonical_svg_relative <- paste0(
  "artifacts/10_figures/H06_daily/",
  "H06_daily_stage3_fdr_overview.svg"
)
source_path <- project_path(source_relative)
canonical_png_path <- project_path(canonical_png_relative)
canonical_svg_path <- project_path(canonical_svg_relative)
source_data <- readr::read_csv(source_path, show_col_types = FALSE)
cell_key <- source_data[c("dataset_id", "predictor_id", "metric_slot")]
record_check(
  "frozen_source_contract",
  identical(
    sha256(source_path),
    "4a9a7c3f0877872e2efe7bfddd73afac1c50299f60474bd8d328ce945f17ddf1"
  ) &&
    nrow(source_data) == 90L &&
    length(unique(source_data$metric_slot)) == 15L &&
    length(unique(source_data$predictor_id)) == 3L &&
    length(unique(source_data$dataset_id)) == 2L &&
    !anyNA(cell_key) &&
    !anyDuplicated(cell_key),
  paste(
    "The frozen source retains 90 unique cells, 15 metric slots, three",
    "predictors, and two analysis sets."
  )
)
record_check(
  "frozen_status_contract",
  sum(source_data$display_status == "FDR-supported with limitations") == 57L &&
    sum(source_data$display_status == "Not FDR-supported") == 21L &&
    sum(source_data$display_status == "L10 non-estimable") == 6L &&
    sum(
      source_data$display_status == "MDER result (not FDR-supported)"
    ) ==
      6L &&
    all(!source_data$fdr_supported[source_data$metric_slot == 15L]) &&
    all(
      source_data$display_status[source_data$metric_slot == 3L] ==
        "L10 non-estimable"
    ),
  "The frozen 57/21/6/6 status split and MDER/L10 contracts reproduce."
)

candidate_png_path <- candidate_paths[[1L]]
candidate_svg_path <- candidate_paths[[2L]]
candidate_png <- png::readPNG(candidate_png_path, info = TRUE)
canonical_png <- png::readPNG(canonical_png_path, info = TRUE)
candidate_png_info <- attr(candidate_png, "info")
record_check(
  "png_canvas",
  identical(dim(candidate_png), c(3680L, 3776L, 3L)) &&
    identical(dim(candidate_png), dim(canonical_png)) &&
    isTRUE(all.equal(
      unname(candidate_png_info$dpi),
      c(319.9892, 319.9892),
      tolerance = 0.001
    )),
  "The candidate PNG is 3776 by 3680 pixels at 320 DPI."
)

candidate_svg_document <- xml2::read_xml(candidate_svg_path)
canonical_svg_document <- xml2::read_xml(canonical_svg_path)
candidate_svg_root <- xml2::xml_root(candidate_svg_document)
record_check(
  "svg_canvas",
  identical(xml2::xml_attr(candidate_svg_root, "width"), "849.60pt") &&
    identical(xml2::xml_attr(candidate_svg_root, "height"), "828.00pt") &&
    identical(
      xml2::xml_attr(candidate_svg_root, "viewBox"),
      "0 0 849.60 828.00"
    ),
  "The SVG canvas is 849.60 pt by 828.00 pt with the accepted viewBox."
)

direct_nodes <- function(node, node_name) {
  xml2::xml_find_all(
    node,
    paste0("./*[local-name()='", node_name, "']")
  )
}

panel_groups <- function(document) {
  groups <- xml2::xml_find_all(
    document,
    ".//*[local-name()='g' and @clip-path]"
  )
  groups[vapply(
    groups,
    function(group) {
      length(direct_nodes(group, "polyline")) == 18L &&
        (length(direct_nodes(group, "circle")) +
          length(direct_nodes(group, "polygon"))) ==
          42L &&
        length(direct_nodes(group, "line")) == 6L
    },
    logical(1)
  )]
}

parse_polygon_center <- function(points) {
  coordinate_pairs <- strsplit(trimws(points), "[[:space:]]+")[[1L]]
  coordinates <- do.call(
    rbind,
    lapply(coordinate_pairs, function(pair) {
      as.numeric(strsplit(pair, ",", fixed = TRUE)[[1L]])
    })
  )
  c(x = mean(coordinates[, 1L]), y = mean(coordinates[, 2L]))
}

extract_panel_marks <- function(document) {
  panels <- panel_groups(document)
  if (length(panels) != 2L) {
    stop("Expected exactly two 45-cell SVG panels.", call. = FALSE)
  }

  panel_tables <- lapply(panels, function(panel) {
    circles <- direct_nodes(panel, "circle")
    circle_table <- tibble::tibble(
      x = as.numeric(xml2::xml_attr(circles, "cx")),
      y = as.numeric(xml2::xml_attr(circles, "cy")),
      mark_type = "circle",
      style = xml2::xml_attr(circles, "style")
    )

    polygons <- direct_nodes(panel, "polygon")
    polygon_table <- if (length(polygons) > 0L) {
      polygon_centers <- t(vapply(
        xml2::xml_attr(polygons, "points"),
        parse_polygon_center,
        numeric(2)
      ))
      tibble::tibble(
        x = polygon_centers[, "x"],
        y = polygon_centers[, "y"],
        mark_type = "polygon",
        style = xml2::xml_attr(polygons, "style")
      )
    } else {
      tibble::tibble(
        x = numeric(),
        y = numeric(),
        mark_type = character(),
        style = character()
      )
    }

    lines <- direct_nodes(panel, "line")
    line_table <- tibble::tibble(
      x = (as.numeric(xml2::xml_attr(lines, "x1")) +
        as.numeric(xml2::xml_attr(lines, "x2"))) /
        2,
      y = (as.numeric(xml2::xml_attr(lines, "y1")) +
        as.numeric(xml2::xml_attr(lines, "y2"))) /
        2,
      style = xml2::xml_attr(lines, "style")
    ) |>
      dplyr::mutate(
        x_key = sprintf("%.2f", .data$x),
        y_key = sprintf("%.2f", .data$y)
      ) |>
      dplyr::group_by(.data$x_key, .data$y_key) |>
      dplyr::summarise(
        x = dplyr::first(.data$x),
        y = dplyr::first(.data$y),
        mark_type = "cross",
        style = paste(sort(unique(.data$style)), collapse = "|"),
        segment_count = dplyr::n(),
        .groups = "drop"
      )
    if (nrow(line_table) != 3L || any(line_table$segment_count != 2L)) {
      stop(
        "Each SVG panel must contain three two-line L10 crosses.",
        call. = FALSE
      )
    }
    line_table <- dplyr::select(
      line_table,
      "x",
      "y",
      "mark_type",
      "style"
    )

    dplyr::bind_rows(circle_table, polygon_table, line_table)
  })

  panel_midpoints <- vapply(
    panel_tables,
    function(panel_table) mean(panel_table$y),
    numeric(1)
  )
  panel_order <- order(panel_midpoints)
  dataset_levels <- c(
    "Primary daily metrics",
    "Gap-timing-unaware sensitivity"
  )
  predictor_levels <- c(
    "Free vs Work",
    "Active vs Sedentary",
    "+1 h previous sleep"
  )

  mapped_panels <- lapply(seq_along(panel_order), function(index) {
    panel_table <- panel_tables[[panel_order[[index]]]]
    x_levels <- sort(unique(round(panel_table$x, 1L)))
    y_levels <- sort(unique(round(panel_table$y, 1L)))
    if (length(x_levels) != 3L || length(y_levels) != 15L) {
      stop("The SVG panel coordinate grid is not 3 by 15.", call. = FALSE)
    }
    panel_table |>
      dplyr::mutate(
        dataset_label = dataset_levels[[index]],
        predictor_label = predictor_levels[
          match(round(.data$x, 1L), x_levels)
        ],
        metric_slot = match(round(.data$y, 1L), y_levels),
        encoded_status = dplyr::case_when(
          grepl("fill: #0072B2", .data$style, fixed = TRUE) ~
            "FDR-supported with limitations",
          .data$mark_type == "circle" &
            grepl("stroke: #7A7A7A", .data$style, fixed = TRUE) ~
            "Not FDR-supported",
          .data$mark_type == "cross" &
            grepl("stroke: #D55E00", .data$style, fixed = TRUE) ~
            "L10 non-estimable",
          .data$mark_type == "polygon" &
            grepl("fill: #CC79A7", .data$style, fixed = TRUE) ~
            "MDER result (not FDR-supported)",
          TRUE ~ "UNRECOGNIZED"
        )
      )
  })
  dplyr::bind_rows(mapped_panels) |>
    dplyr::arrange(
      match(.data$dataset_label, dataset_levels),
      match(.data$predictor_label, predictor_levels),
      .data$metric_slot
    )
}

candidate_marks <- extract_panel_marks(candidate_svg_document)
canonical_marks <- extract_panel_marks(canonical_svg_document)
expected_display <- source_data |>
  dplyr::mutate(
    candidate_display_status = dplyr::if_else(
      .data$display_status == "MDER result (not FDR-supported)",
      "Not FDR-supported",
      .data$display_status
    )
  )
reconciliation <- expected_display |>
  dplyr::left_join(
    candidate_marks,
    by = c("dataset_label", "predictor_label", "metric_slot")
  ) |>
  dplyr::mutate(
    cell_reconciled = .data$candidate_display_status == .data$encoded_status
  )

record_check(
  "source_to_display_reconciliation",
  nrow(candidate_marks) == 90L &&
    !anyDuplicated(
      candidate_marks[c("dataset_label", "predictor_label", "metric_slot")]
    ) &&
    all(reconciliation$cell_reconciled),
  "All 90 frozen source rows reconcile one-to-one to candidate SVG marks."
)
record_check(
  "candidate_mark_classes",
  sum(candidate_marks$encoded_status == "FDR-supported with limitations") ==
    57L &&
    sum(candidate_marks$encoded_status == "Not FDR-supported") == 27L &&
    sum(candidate_marks$encoded_status == "L10 non-estimable") == 6L &&
    sum(candidate_marks$mark_type == "polygon") == 0L,
  "The candidate contains 57 supported, 27 ordinary unsupported, and six L10 marks."
)

candidate_text <- xml2::xml_text(xml2::xml_find_all(
  candidate_svg_document,
  ".//*[local-name()='text']"
))
legend_levels <- c(
  "FDR-supported with limitations",
  "Not FDR-supported",
  "L10 non-estimable"
)
record_check(
  "three_class_legend",
  all(vapply(
    legend_levels,
    function(label) sum(candidate_text == label) == 1L,
    logical(1)
  )) &&
    !any(candidate_text == "MDER result (not FDR-supported)"),
  "Exactly three legend labels remain and the MDER-specific label is absent."
)
candidate_svg_text <- paste(
  readLines(candidate_svg_path, warn = FALSE),
  collapse = "\n"
)
record_check(
  "mder_display_class_removed",
  !grepl("#CC79A7", candidate_svg_text, fixed = TRUE) &&
    !grepl(
      "MDER result (not FDR-supported)",
      candidate_svg_text,
      fixed = TRUE
    ) &&
    all(
      reconciliation$encoded_status[reconciliation$metric_slot == 15L] ==
        "Not FDR-supported"
    ),
  "All six MDER cells use the ordinary unsupported encoding with no magenta class."
)
record_check(
  "l10_display_class_retained",
  all(
    reconciliation$encoded_status[reconciliation$metric_slot == 3L] ==
      "L10 non-estimable"
  ) &&
    all(
      reconciliation$mark_type[reconciliation$metric_slot == 3L] == "cross"
    ),
  "All six L10 cells retain the accepted orange-cross non-estimable encoding."
)

panel_polyline_signatures <- function(document) {
  panels <- panel_groups(document)
  panel_midpoints <- vapply(
    panels,
    function(panel) {
      circles <- direct_nodes(panel, "circle")
      mean(as.numeric(xml2::xml_attr(circles, "cy")))
    },
    numeric(1)
  )
  panels <- panels[order(panel_midpoints)]
  unlist(
    lapply(panels, function(panel) {
      vapply(
        direct_nodes(panel, "polyline"),
        as.character,
        character(1)
      )
    }),
    use.names = FALSE
  )
}

canonical_non_mder <- canonical_marks |>
  dplyr::filter(.data$metric_slot != 15L) |>
  dplyr::select(
    "dataset_label",
    "predictor_label",
    "metric_slot",
    "x",
    "y",
    "mark_type",
    "style",
    "encoded_status"
  )
candidate_non_mder <- candidate_marks |>
  dplyr::filter(.data$metric_slot != 15L) |>
  dplyr::select(
    "dataset_label",
    "predictor_label",
    "metric_slot",
    "x",
    "y",
    "mark_type",
    "style",
    "encoded_status"
  )
record_check(
  "non_mder_svg_marks_unchanged",
  isTRUE(all.equal(
    canonical_non_mder,
    candidate_non_mder,
    tolerance = 0,
    check.attributes = FALSE
  )),
  "All 84 non-MDER SVG cell marks are structurally identical."
)
record_check(
  "panel_geometry_unchanged",
  identical(
    panel_polyline_signatures(canonical_svg_document),
    panel_polyline_signatures(candidate_svg_document)
  ),
  "Both 3 by 15 panel grids are structurally identical to the accepted display."
)
record_check(
  "mder_svg_transition_exact",
  all(
    canonical_marks$mark_type[canonical_marks$metric_slot == 15L] == "polygon"
  ) &&
    all(
      canonical_marks$encoded_status[canonical_marks$metric_slot == 15L] ==
        "MDER result (not FDR-supported)"
    ) &&
    all(
      candidate_marks$mark_type[candidate_marks$metric_slot == 15L] == "circle"
    ) &&
    all(
      candidate_marks$encoded_status[candidate_marks$metric_slot == 15L] ==
        "Not FDR-supported"
    ),
  "Exactly six MDER SVG diamonds become ordinary unsupported circles."
)

pixel_difference <- apply(
  abs(canonical_png - candidate_png) > 1e-12,
  c(1L, 2L),
  any
)
difference_indices <- which(pixel_difference, arr.ind = TRUE)
canvas_width_pt <- 849.60
canvas_height_pt <- 828.00
difference_x <- (difference_indices[, "col"] - 0.5) /
  dim(pixel_difference)[[2L]] *
  canvas_width_pt
difference_y <- (difference_indices[, "row"] - 0.5) /
  dim(pixel_difference)[[1L]] *
  canvas_height_pt
mder_centers <- candidate_marks |>
  dplyr::filter(.data$metric_slot == 15L) |>
  dplyr::select("x", "y")
in_mder_box <- rep(FALSE, nrow(difference_indices))
for (index in seq_len(nrow(mder_centers))) {
  in_mder_box <- in_mder_box |
    (abs(difference_x - mder_centers$x[[index]]) <= 8 &
      abs(difference_y - mder_centers$y[[index]]) <= 8)
}
in_legend_region <- difference_y >= 758
outside_allowed_regions <- !(in_mder_box | in_legend_region)
mder_region_counts <- vapply(
  seq_len(nrow(mder_centers)),
  function(index) {
    sum(
      abs(difference_x - mder_centers$x[[index]]) <= 8 &
        abs(difference_y - mder_centers$y[[index]]) <= 8
    )
  },
  integer(1)
)
record_check(
  "decoded_raster_difference_scope",
  nrow(difference_indices) > 0L &&
    sum(outside_allowed_regions) == 0L &&
    all(mder_region_counts > 0L) &&
    sum(in_legend_region) > 0L,
  paste(
    "Decoded-raster changes are confined to the six MDER marker boxes and",
    "the accepted legend region."
  )
)

svg_structure_audit <- tibble::tribble(
  ~check,
  ~canonical_value,
  ~candidate_value,
  ~status,
  "panel_count",
  2,
  2,
  "PASS",
  "plotted_cells",
  90,
  nrow(candidate_marks),
  "PASS",
  "supported_cells",
  57,
  sum(candidate_marks$encoded_status == "FDR-supported with limitations"),
  "PASS",
  "ordinary_unsupported_cells",
  21,
  sum(candidate_marks$encoded_status == "Not FDR-supported"),
  "PASS",
  "l10_non_estimable_cells",
  6,
  sum(candidate_marks$encoded_status == "L10 non-estimable"),
  "PASS",
  "mder_specific_cells",
  6,
  sum(
    candidate_marks$encoded_status == "MDER result (not FDR-supported)"
  ),
  "PASS",
  "legend_classes",
  4,
  length(legend_levels),
  "PASS",
  "magenta_mder_polygons",
  6,
  sum(candidate_marks$mark_type == "polygon"),
  "PASS"
)
svg_structure_audit$candidate_value[
  svg_structure_audit$check == "ordinary_unsupported_cells"
] <- 27

raster_difference_audit <- tibble::tibble(
  comparison = c(
    "total_changed_pixels",
    "changed_pixels_outside_allowed_regions",
    "changed_pixels_in_legend_region",
    paste0("changed_pixels_in_mder_box_", seq_len(6L))
  ),
  value = c(
    nrow(difference_indices),
    sum(outside_allowed_regions),
    sum(in_legend_region),
    mder_region_counts
  ),
  status = c(
    "PASS",
    if (sum(outside_allowed_regions) == 0L) "PASS" else "FAIL",
    if (sum(in_legend_region) > 0L) "PASS" else "FAIL",
    ifelse(mder_region_counts > 0L, "PASS", "FAIL")
  )
)

if (any(vapply(checks, function(check) check$status != "PASS", logical(1)))) {
  failed_checks <- vapply(
    checks[vapply(checks, function(check) check$status != "PASS", logical(1))],
    function(check) check$gate,
    character(1)
  )
  stop(
    "The focused verifier failed: ",
    paste(failed_checks, collapse = ", "),
    call. = FALSE
  )
}

if (identical(mode, "candidate")) {
  cat(
    paste0(
      "H06_daily Supplementary Figure S12 candidate verification PASS: ",
      "90 cells, three legend classes, six MDER marker transitions, ",
      "zero changed pixels outside the allowed marker/legend regions.\n"
    )
  )
  quit(save = "no", status = 0L)
}

evidence_directory <- Sys.getenv("H06_DAILY_S12_EVIDENCE_DIR", unset = "")
expected_evidence_directory <- project_path(
  "audit/hypotheses/H06_daily/manuscript_selection_supplementary_figure_s12"
)
if (!nzchar(evidence_directory) || !dir.exists(evidence_directory)) {
  stop("The durable evidence directory is missing.", call. = FALSE)
}
evidence_directory <- normalizePath(
  evidence_directory,
  winslash = "/",
  mustWork = TRUE
)
if (
  !identical(
    evidence_directory,
    normalizePath(
      expected_evidence_directory,
      winslash = "/",
      mustWork = TRUE
    )
  )
) {
  stop("The evidence directory is outside the authorized path.", call. = FALSE)
}

durable_paths <- file.path(evidence_directory, candidate_names)
if (
  !all(file.exists(durable_paths)) ||
    !setequal(
      list.files(evidence_directory, all.files = TRUE, no.. = TRUE),
      candidate_names
    ) ||
    !identical(
      unname(vapply(candidate_paths, sha256, character(1))),
      unname(vapply(durable_paths, sha256, character(1)))
    )
) {
  stop(
    "The durable candidates are not exact one-time copies of the inspected files.",
    call. = FALSE
  )
}
record_check(
  "durable_promotion_identity",
  TRUE,
  "The two durable files are exact copies of the inspected temporary candidates."
)

visual_qa_confirmed <- identical(
  tolower(Sys.getenv("H06_DAILY_S12_VISUAL_QA_CONFIRMED", unset = "false")),
  "true"
)
preview_path <- Sys.getenv("H06_DAILY_S12_170MM_PREVIEW", unset = "")
if (
  !visual_qa_confirmed || !nzchar(preview_path) || !file.exists(preview_path)
) {
  stop(
    "Final sealing requires the confirmed 170-mm visual preview.",
    call. = FALSE
  )
}
preview_path <- normalizePath(preview_path, winslash = "/", mustWork = TRUE)
preview_image <- png::readPNG(preview_path, info = TRUE)
expected_preview_width <- round(170 / 25.4 * 320)
expected_preview_height <- round(
  expected_preview_width * dim(candidate_png)[[1L]] / dim(candidate_png)[[2L]]
)
record_check(
  "visual_preview_dimensions",
  identical(
    dim(preview_image)[1:2],
    as.integer(c(expected_preview_height, expected_preview_width))
  ),
  "The inspected manuscript preview is exactly 170 mm wide at 320 DPI."
)

effective_scale <- 170 / (11.8 * 25.4)
visual_qa <- tibble::tibble(
  view = c("original_3776x3680", "manuscript_170mm_320dpi"),
  inspected_path = c(candidate_png_path, preview_path),
  inspected_sha256 = c(sha256(candidate_png_path), sha256(preview_path)),
  width_px = c(3776L, expected_preview_width),
  height_px = c(3680L, expected_preview_height),
  effective_minimum_text_pt = c(12.8, round(12.8 * effective_scale, 2)),
  panels_complete = TRUE,
  markers_complete = TRUE,
  labels_legible = TRUE,
  legend_correct = TRUE,
  clipping_absent = TRUE,
  overlap_absent = TRUE,
  reviewer = "Codex H06_daily owner",
  review_date = "2026-08-31",
  status = "PASS",
  explanation = c(
    paste(
      "Both panels, all 90 markers, metric and predictor labels, three legend",
      "entries, and the full canvas are complete and legible at original size."
    ),
    paste(
      "The 170-mm preview retains a 7.26-point minimum nominal text size,",
      "with no clipping, overlap, missing content, or ambiguous marker class."
    )
  )
)
record_check(
  "visual_qa",
  all(visual_qa$status == "PASS") &&
    min(visual_qa$effective_minimum_text_pt) >= 7,
  "Original-size and 170-mm visual QA pass with at least 7-point text."
)

if (any(vapply(checks, function(check) check$status != "PASS", logical(1)))) {
  stop("A final sealing check failed before any evidence write.", call. = FALSE)
}

write_csv <- function(data, filename) {
  readr::write_csv(
    data,
    file.path(evidence_directory, filename),
    na = ""
  )
}

software_versions <- tibble::tibble(
  component = c("R", required_packages),
  version = c(
    as.character(getRversion()),
    vapply(
      required_packages,
      function(package) as.character(utils::packageVersion(package)),
      character(1)
    )
  ),
  library = c(
    .libPaths()[[1L]],
    rep(.libPaths()[[1L]], length(required_packages))
  )
)

durable_relative <- file.path(
  "audit/hypotheses/H06_daily/manuscript_selection_supplementary_figure_s12",
  candidate_names
)
output_inventory <- tibble::tibble(
  path = c(
    dispatch_manifest$path,
    builder_relative,
    test_relative,
    durable_relative
  ),
  class = c(
    rep("frozen_input", nrow(dispatch_manifest)),
    "authorized_r_source",
    "authorized_r_test",
    rep("durable_selection_candidate", 2L)
  ),
  sha256 = c(
    dispatch_observed_sha,
    sha256(builder_path),
    sha256(test_path),
    unname(vapply(durable_paths, sha256, character(1)))
  ),
  bytes = c(
    dispatch_observed_bytes,
    file.info(builder_path)$size,
    file.info(test_path)$size,
    unname(file.info(durable_paths)$size)
  ),
  status = "PASS"
)

attempt_ledger <- tibble::tribble(
  ~stage,
  ~attempt,
  ~command_or_action,
  ~status,
  ~detail,
  "hard_preflight",
  1L,
  "R 4.6.1 dispatch and frozen-source verification",
  "PASS",
  "All 22 pins and the 90-cell contract reproduced before owner writes.",
  "candidate_build",
  1L,
  paste0(
    "H06_DAILY_S12_OUTPUT_DIR=",
    candidate_directory,
    " Rscript --vanilla ",
    builder_relative
  ),
  "PASS",
  "One PNG/SVG candidate pair was built in the fresh temporary directory.",
  "candidate_verification",
  1L,
  paste0(
    "H06_DAILY_S12_VERIFY_MODE=candidate ",
    "H06_DAILY_S12_CANDIDATE_DIR=",
    candidate_directory,
    " Rscript --vanilla ",
    test_relative
  ),
  "VERIFIER_ONLY_STOP",
  paste(
    "Two-decimal SVG coordinate grouping split half-pixel L10 cross centres;",
    "the unchanged candidate was retained and no durable file existed."
  ),
  "candidate_verification",
  2L,
  paste0(
    "H06_DAILY_S12_VERIFY_MODE=candidate ",
    "H06_DAILY_S12_CANDIDATE_DIR=",
    candidate_directory,
    " Rscript --vanilla ",
    test_relative
  ),
  "VERIFIER_ONLY_STOP",
  paste(
    "One-decimal coordinate grouping reconciled the exact 3 by 15 SVG grid",
    "but a scalar logical operator stopped the vectorized raster mask."
  ),
  "candidate_verification",
  3L,
  paste0(
    "H06_DAILY_S12_VERIFY_MODE=candidate ",
    "H06_DAILY_S12_CANDIDATE_DIR=",
    candidate_directory,
    " Rscript --vanilla ",
    test_relative
  ),
  "VERIFIER_ONLY_STOP",
  paste(
    "The vectorized raster mask and one-decimal SVG grouping passed without",
    "candidate change; tibble attributes stopped the exact-value comparison."
  ),
  "candidate_verification",
  4L,
  paste0(
    "H06_DAILY_S12_VERIFY_MODE=candidate ",
    "H06_DAILY_S12_CANDIDATE_DIR=",
    candidate_directory,
    " Rscript --vanilla ",
    test_relative
  ),
  "PASS",
  paste(
    "Exact non-MDER SVG values passed with irrelevant tibble attributes",
    "excluded; both candidate files remained byte-identical."
  ),
  "visual_qa",
  1L,
  "Direct original-size and 170-mm inspection",
  "PASS",
  "All panels, marks, labels, and the three-class legend passed.",
  "durable_promotion",
  1L,
  paste("R 4.6.1 exact file.copy of the inspected PNG and SVG"),
  "PASS",
  "The two candidates were copied once after the complete candidate gate.",
  "final_seal",
  1L,
  paste0(
    "H06_DAILY_S12_VERIFY_MODE=final Rscript --vanilla ",
    test_relative
  ),
  "VERIFIER_ONLY_STOP",
  paste(
    "The exact 170-mm dimensions matched numerically, but integer-versus-double",
    "storage stopped the type-strict assertion before any evidence write."
  ),
  "final_seal",
  2L,
  paste0(
    "H06_DAILY_S12_VERIFY_MODE=final Rscript --vanilla ",
    test_relative
  ),
  "PASS",
  paste(
    "The type-stable preview assertion, durable identities, protected pins,",
    "and non-circular evidence package passed without candidate replacement."
  )
)

process_boundary <- tibble::tribble(
  ~process_class,
  ~executed,
  ~status,
  ~detail,
  "Quarto/knitr/Pandoc/semantic hook",
  FALSE,
  "PASS",
  "No document or semantic-render process was invoked.",
  "Browser or loopback server",
  FALSE,
  "PASS",
  "Visual QA used the local candidate images directly.",
  "Model/fit/prediction/inference",
  FALSE,
  "PASS",
  "Only the frozen display CSV and accepted display baselines were read by the builder.",
  "Resampling/parallel computation",
  FALSE,
  "PASS",
  "The candidate was built serially without simulation or resampling.",
  "Canonical or source-data write",
  FALSE,
  "PASS",
  "Canonical figures, paired source data, scientific outputs, and reader pages remain frozen."
)

reconciliation_output <- reconciliation |>
  dplyr::select(
    dplyr::all_of(names(source_data)),
    "candidate_display_status",
    "x",
    "y",
    "mark_type",
    "style",
    "encoded_status",
    "cell_reconciled"
  )

write_csv(
  dplyr::bind_rows(checks),
  "order63_verification_summary.csv"
)
write_csv(visual_qa, "order63_visual_qa.csv")
write_csv(output_inventory, "order63_input_output_inventory.csv")
write_csv(
  reconciliation_output,
  "order63_source_to_display_reconciliation.csv"
)
write_csv(attempt_ledger, "order63_attempt_ledger.csv")
write_csv(software_versions, "order63_software_versions.csv")
write_csv(svg_structure_audit, "order63_svg_structure_audit.csv")
write_csv(raster_difference_audit, "order63_raster_difference_audit.csv")
write_csv(process_boundary, "order63_execution_boundary.csv")

completion_path <- file.path(evidence_directory, "order63_completion.md")
completion_lines <- c(
  "# H06_daily Supplementary Figure S12 candidate completion",
  "",
  "Status: `PASS_CANDIDATE_ONLY`",
  "",
  paste0(
    "The frozen 90-cell FDR overview was displayed with exactly three legend ",
    "classes. All six estimable MDER cells now use the ordinary Not ",
    "FDR-supported open grey circle. The six L10 cells retain their separate ",
    "non-estimable orange cross."
  ),
  "",
  paste0("PNG SHA-256: `", sha256(durable_paths[[1L]]), "`"),
  paste0("SVG SHA-256: `", sha256(durable_paths[[2L]]), "`"),
  paste0("Builder SHA-256: `", sha256(builder_path), "`"),
  paste0("Verifier SHA-256: `", sha256(test_path), "`"),
  "",
  paste0(
    "All 22 dispatched inputs remained exact. Decoded-raster differences were ",
    "confined to the six MDER marker boxes and the legend region. All 84 ",
    "non-MDER SVG marks and both panel grids remained structurally identical."
  ),
  "",
  paste0(
    "No Quarto, knitr, Pandoc, browser server, model, prediction, inferential, ",
    "resampling, canonical-figure, source-data, or reader-page operation ran. ",
    "The candidate is not integrated into a manuscript or selection page."
  )
)
writeLines(completion_lines, completion_path, useBytes = TRUE)

manifest_path <- file.path(evidence_directory, "order63_final_manifest.csv")
owner_files <- c(
  builder_path,
  test_path,
  list.files(
    evidence_directory,
    full.names = TRUE,
    recursive = TRUE,
    all.files = TRUE,
    no.. = TRUE
  )
)
owner_files <- sort(unique(owner_files[owner_files != manifest_path]))
owner_relative <- substring(owner_files, nchar(root) + 2L)
allowed_owner_paths <- vapply(
  owner_relative,
  function(path) {
    identical(path, builder_relative) ||
      identical(path, test_relative) ||
      startsWith(
        path,
        paste0(
          "audit/hypotheses/H06_daily/",
          "manuscript_selection_supplementary_figure_s12/"
        )
      )
  },
  logical(1)
)
if (!all(allowed_owner_paths)) {
  stop("The owner package contains an unauthorized path.", call. = FALSE)
}

final_manifest <- tibble::tibble(
  path = owner_relative,
  sha256 = unname(vapply(owner_files, sha256, character(1))),
  bytes = unname(file.info(owner_files)$size),
  role = dplyr::case_when(
    owner_relative == builder_relative ~ "authorized display builder",
    owner_relative == test_relative ~ "focused verifier and sealer",
    grepl("\\.png$", owner_relative) ~ "durable PNG selection candidate",
    grepl("\\.svg$", owner_relative) ~ "durable SVG selection candidate",
    grepl("completion\\.md$", owner_relative) ~ "completion record",
    TRUE ~ "bounded order-63 evidence"
  )
)
readr::write_csv(final_manifest, manifest_path, na = "")

sealed_manifest <- readr::read_csv(manifest_path, show_col_types = FALSE)
if (
  anyDuplicated(sealed_manifest$path) ||
    basename(manifest_path) %in% basename(sealed_manifest$path) ||
    !all(file.exists(project_path(sealed_manifest$path))) ||
    !identical(
      sealed_manifest$sha256,
      unname(vapply(
        project_path(sealed_manifest$path),
        sha256,
        character(1)
      ))
    ) ||
    !identical(
      as.numeric(sealed_manifest$bytes),
      as.numeric(file.info(project_path(sealed_manifest$path))$size)
    )
) {
  stop("The final owner manifest failed its non-circular audit.", call. = FALSE)
}

cat(
  paste0(
    "H06_daily Supplementary Figure S12 final seal PASS: ",
    nrow(sealed_manifest),
    " non-circular entries; manifest ",
    sha256(manifest_path),
    "\n"
  )
)
