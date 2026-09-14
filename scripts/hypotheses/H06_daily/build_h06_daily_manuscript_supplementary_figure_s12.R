#!/usr/bin/env Rscript

# Build the H06_daily Supplementary Figure S12 display-only candidate.

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
    "The H06_daily Supplementary Figure S12 builder requires R 4.6.1; found ",
    as.character(getRversion()),
    call. = FALSE
  )
}

required_packages <- c(
  "digest",
  "dplyr",
  "ggplot2",
  "png",
  "readr",
  "svglite"
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

output_directory <- Sys.getenv("H06_DAILY_S12_OUTPUT_DIR", unset = "")
if (!nzchar(output_directory) || !dir.exists(output_directory)) {
  stop(
    "Set `H06_DAILY_S12_OUTPUT_DIR` to one existing temporary directory.",
    call. = FALSE
  )
}
output_directory <- normalizePath(
  output_directory,
  winslash = "/",
  mustWork = TRUE
)
if (!startsWith(output_directory, "/private/tmp/")) {
  stop(
    "The candidate output directory must be below `/private/tmp/`.",
    call. = FALSE
  )
}
if (length(list.files(output_directory, all.files = TRUE, no.. = TRUE)) > 0L) {
  stop("The candidate output directory must be empty.", call. = FALSE)
}

sha256 <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE)
}

input_paths <- c(
  source = file.path(
    root,
    paste0(
      "artifacts/11_source_data/H06_daily/",
      "H06_daily_stage3_fdr_overview_figure.csv"
    )
  ),
  canonical_png = file.path(
    root,
    paste0(
      "artifacts/10_figures/H06_daily/",
      "H06_daily_stage3_fdr_overview.png"
    )
  ),
  canonical_svg = file.path(
    root,
    paste0(
      "artifacts/10_figures/H06_daily/",
      "H06_daily_stage3_fdr_overview.svg"
    )
  )
)
expected_hashes <- c(
  source = "4a9a7c3f0877872e2efe7bfddd73afac1c50299f60474bd8d328ce945f17ddf1",
  canonical_png = "3dc2cf8de4597c1ce85d1acd65404778c14e75fa9f4920e7bfe1b83571bc048a",
  canonical_svg = "1ecfc0156b7ee6ddedc96f1943c597a583516732383c6ac9c799a4dba2e362bd"
)
if (!all(file.exists(input_paths))) {
  stop("A frozen display input is missing.", call. = FALSE)
}
observed_hashes <- unname(vapply(input_paths, sha256, character(1)))
if (!identical(observed_hashes, unname(expected_hashes))) {
  stop("A frozen display input identity has drifted.", call. = FALSE)
}

canonical_png <- png::readPNG(input_paths[["canonical_png"]], info = TRUE)
canonical_png_info <- attr(canonical_png, "info")
canonical_svg_root <- readLines(
  input_paths[["canonical_svg"]],
  n = 2L,
  warn = FALSE
)[[2L]]
if (
  !identical(dim(canonical_png), c(3680L, 3776L, 3L)) ||
    !isTRUE(all.equal(
      unname(canonical_png_info$dpi),
      c(319.9892, 319.9892),
      tolerance = 0.001
    )) ||
    !grepl(
      "width='849.60pt' height='828.00pt' viewBox='0 0 849.60 828.00'",
      canonical_svg_root,
      fixed = TRUE
    )
) {
  stop("The accepted display baseline has an unexpected canvas.", call. = FALSE)
}

source_data <- readr::read_csv(
  input_paths[["source"]],
  show_col_types = FALSE
)
expected_columns <- c(
  "dataset_id",
  "dataset_label",
  "predictor_order",
  "predictor_id",
  "predictor_label",
  "metric_slot",
  "metric_id",
  "manuscript_name",
  "abbreviation",
  "metric_label",
  "raw_p_value",
  "bh_adjusted_p_value",
  "fdr_supported",
  "h01_claim_eligible",
  "participant_days",
  "participants",
  "sites",
  "display_status"
)
cell_key <- source_data[c("dataset_id", "predictor_id", "metric_slot")]
if (
  !identical(names(source_data), expected_columns) ||
    nrow(source_data) != 90L ||
    length(unique(source_data$metric_slot)) != 15L ||
    length(unique(source_data$predictor_id)) != 3L ||
    length(unique(source_data$dataset_id)) != 2L ||
    anyNA(cell_key) ||
    anyDuplicated(cell_key) ||
    sum(source_data$display_status == "FDR-supported with limitations") !=
      57L ||
    sum(source_data$display_status == "Not FDR-supported") != 21L ||
    sum(source_data$display_status == "L10 non-estimable") != 6L ||
    sum(
      source_data$display_status == "MDER result (not FDR-supported)"
    ) !=
      6L
) {
  stop(
    "The frozen 90-cell source failed its structural contract.",
    call. = FALSE
  )
}

mder_rows <- source_data$metric_slot == 15L
l10_rows <- source_data$metric_slot == 3L
if (
  sum(mder_rows) != 6L ||
    sum(l10_rows) != 6L ||
    any(source_data$fdr_supported[mder_rows]) ||
    !all(
      source_data$display_status[mder_rows] == "MDER result (not FDR-supported)"
    ) ||
    !all(source_data$display_status[l10_rows] == "L10 non-estimable")
) {
  stop("The frozen MDER or L10 display contract has drifted.", call. = FALSE)
}

predictor_levels <- c(
  "Free vs Work",
  "Active vs Sedentary",
  "+1 h previous sleep"
)
dataset_levels <- c(
  "Primary daily metrics",
  "Gap-timing-unaware sensitivity"
)
status_levels <- c(
  "FDR-supported with limitations",
  "Not FDR-supported",
  "L10 non-estimable"
)

display_data <- source_data |>
  dplyr::mutate(
    display_status = dplyr::if_else(
      .data$display_status == "MDER result (not FDR-supported)",
      "Not FDR-supported",
      .data$display_status
    ),
    predictor_label = factor(
      .data$predictor_label,
      levels = predictor_levels
    ),
    dataset_label = factor(.data$dataset_label, levels = dataset_levels),
    metric_label = factor(
      .data$metric_label,
      levels = rev(unique(.data$metric_label[order(.data$metric_slot)]))
    ),
    display_status = factor(.data$display_status, levels = status_levels)
  )

if (
  anyNA(display_data[c("predictor_label", "dataset_label", "metric_label")]) ||
    sum(display_data$display_status == "FDR-supported with limitations") !=
      57L ||
    sum(display_data$display_status == "Not FDR-supported") != 27L ||
    sum(display_data$display_status == "L10 non-estimable") != 6L ||
    length(unique(display_data$display_status)) != 3L
) {
  stop("The bounded display reclassification failed.", call. = FALSE)
}

figure_s12 <- ggplot2::ggplot(
  display_data,
  ggplot2::aes(
    x = .data$predictor_label,
    y = .data$metric_label,
    shape = .data$display_status,
    colour = .data$display_status
  )
) +
  ggplot2::geom_point(size = 4.2, stroke = 1.15) +
  ggplot2::facet_grid(
    rows = ggplot2::vars(.data$dataset_label),
    scales = "free_y"
  ) +
  ggplot2::scale_shape_manual(
    values = c(
      "FDR-supported with limitations" = 16,
      "Not FDR-supported" = 1,
      "L10 non-estimable" = 4
    ),
    drop = FALSE
  ) +
  ggplot2::scale_colour_manual(
    values = c(
      "FDR-supported with limitations" = "#0072B2",
      "Not FDR-supported" = "#7A7A7A",
      "L10 non-estimable" = "#D55E00"
    ),
    drop = FALSE
  ) +
  ggplot2::labs(
    x = NULL,
    y = NULL,
    shape = NULL,
    colour = NULL
  ) +
  ggplot2::theme_minimal(base_size = 12.5) +
  ggplot2::theme(
    panel.grid.major.x = ggplot2::element_line(
      colour = "#E8E8E8",
      linewidth = 0.4
    ),
    panel.grid.major.y = ggplot2::element_line(
      colour = "#F0F0F0",
      linewidth = 0.35
    ),
    panel.grid.minor = ggplot2::element_blank(),
    axis.text.x = ggplot2::element_text(
      size = 12.8,
      face = "bold",
      margin = ggplot2::margin(t = 7)
    ),
    axis.text.y = ggplot2::element_text(size = 12.8, colour = "#202020"),
    strip.text = ggplot2::element_text(
      size = 13.2,
      face = "bold",
      colour = "#202020"
    ),
    strip.background = ggplot2::element_rect(
      fill = "#F4F4F4",
      colour = NA
    ),
    legend.position = "bottom",
    legend.text = ggplot2::element_text(size = 12.8),
    legend.box = "vertical",
    text = ggplot2::element_text(size = 12.8),
    plot.margin = ggplot2::margin(12, 16, 10, 10)
  ) +
  ggplot2::guides(
    shape = ggplot2::guide_legend(nrow = 2L, byrow = TRUE),
    colour = ggplot2::guide_legend(nrow = 2L, byrow = TRUE)
  )

png_path <- file.path(
  output_directory,
  "H06_daily_supplementary_figure_s12.png"
)
svg_path <- file.path(
  output_directory,
  "H06_daily_supplementary_figure_s12.svg"
)

ggplot2::ggsave(
  png_path,
  figure_s12,
  width = 11.8,
  height = 11.5,
  units = "in",
  dpi = 320,
  bg = "white"
)
ggplot2::ggsave(
  svg_path,
  figure_s12,
  width = 11.8,
  height = 11.5,
  units = "in",
  device = svglite::svglite,
  bg = "white"
)

expected_outputs <- c(png_path, svg_path)
if (
  !all(file.exists(expected_outputs)) ||
    !setequal(list.files(output_directory, full.names = TRUE), expected_outputs)
) {
  stop("The builder wrote an unexpected candidate file set.", call. = FALSE)
}

candidate_png <- png::readPNG(png_path, info = TRUE)
candidate_png_info <- attr(candidate_png, "info")
candidate_svg <- paste(readLines(svg_path, warn = FALSE), collapse = "\n")
if (
  !identical(dim(candidate_png), c(3680L, 3776L, 3L)) ||
    !isTRUE(all.equal(
      unname(candidate_png_info$dpi),
      c(319.9892, 319.9892),
      tolerance = 0.001
    )) ||
    !grepl(
      "width='849.60pt' height='828.00pt' viewBox='0 0 849.60 828.00'",
      candidate_svg,
      fixed = TRUE
    ) ||
    grepl("MDER result (not FDR-supported)", candidate_svg, fixed = TRUE) ||
    grepl("#CC79A7", candidate_svg, fixed = TRUE)
) {
  stop(
    "The candidate failed its immediate canvas or legend check.",
    call. = FALSE
  )
}

cat(
  paste0(
    "H06_daily Supplementary Figure S12 candidate built: ",
    "PNG ",
    sha256(png_path),
    "; SVG ",
    sha256(svg_path),
    "\n"
  )
)
