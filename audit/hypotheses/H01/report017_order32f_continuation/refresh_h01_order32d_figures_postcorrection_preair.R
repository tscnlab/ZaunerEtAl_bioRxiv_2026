#!/usr/bin/env Rscript

# REPORT-017 order 32d display-only refresh for H01 Figures 1, 5, and 6.
#
# This script is deliberately independent of the H01 scientific pipeline. It
# reads only the three frozen reader-display CSVs authorized by order 32d and
# writes baseline and candidate display files to a caller-supplied temporary
# directory. It does not read models or scientific RDS files and never writes
# a durable figure target.

suppressPackageStartupMessages({
  library(cowplot)
  library(digest)
  library(dplyr)
  library(ggplot2)
  library(ggrepel)
  library(png)
  library(readr)
  library(tibble)
  library(xml2)
})

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("The order-32d display refresh requires R 4.6.1", call. = FALSE)
}

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2L) {
  stop(
    "Usage: refresh_h01_order32d_figures.R <candidate-root> <attempt-id>",
    call. = FALSE
  )
}

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
candidate_root <- normalizePath(args[[1]], winslash = "/", mustWork = TRUE)
attempt_id <- args[[2]]
if (!grepl("^[A-Za-z0-9_-]+$", attempt_id)) {
  stop("The attempt ID contains an unsupported character", call. = FALSE)
}

source_specs <- tribble(
  ~figure_id,
  ~path,
  ~sha256,
  ~rows,
  "model_support",
  "artifacts/11_source_data/H01/stage3/H01_stage3_METRIC011_l10_mean_medi_model_support_figure_source.csv",
  "cf869aa233aca9230a9d295f7efae69fc51c1258a80daf90258d08122f5effc0",
  136L,
  "paired_placement",
  "artifacts/11_source_data/H01/stage3/H01_stage3_METRIC011_l10_mean_medi_paired_placement_figure_source.csv",
  "8e1672e499e6bee05cde70647165e780dfa5cb9195ed0c3f1bd203da5d838853",
  30L,
  "diagnostic_assessment",
  "artifacts/11_source_data/H01/stage3/H01_stage3_diagnostic_figure_source.csv",
  "d9b424ae246fc688670a77a561717701fec3ddffaf000af72ea6b68f214b9397",
  204L
)

baseline_specs <- tribble(
  ~figure_id,
  ~width,
  ~height,
  ~png_width,
  ~png_height,
  ~png_sha256,
  ~svg_sha256,
  ~source_png_sha256,
  ~source_svg_sha256,
  "model_support",
  10.5,
  7.4,
  3360L,
  2368L,
  "2244f043d4fb676200524440098be223e23106578513f4ac61567ba3f636da8b",
  "602dd62de063d3e12ac53ca7d22dd2563e64213255b9cdc7e138941450ce1966",
  "2e3b1ddb7954584a70ff9d434cc862f9d1769dc45be607d2ca34840cbc9c1760",
  "12e4cf421a844da11844444e41601dec5e559e28b4ad77ac0081bd9ef2cfddcd",
  "paired_placement",
  12.0,
  6.8,
  3840L,
  2176L,
  "866670f47457bf304467e787481589298d9b7cf7c2c5de560ac9500f044c4608",
  "fe101f32cb0ffd4912b81ddbad4090c9558263aa85cc4f13ecad73369ac074f0",
  "866670f47457bf304467e787481589298d9b7cf7c2c5de560ac9500f044c4608",
  "fe101f32cb0ffd4912b81ddbad4090c9558263aa85cc4f13ecad73369ac074f0",
  "diagnostic_assessment",
  11.5,
  7.6,
  3680L,
  2432L,
  "95f46b0909b43c9b281a93a860d577b38a7753cb4d151ad751e2aca8a017b12d",
  "a15b3bae14b1b76d5a48ae9a21d0eb86dfd264db238179fb2a4486c002876a52",
  "95f46b0909b43c9b281a93a860d577b38a7753cb4d151ad751e2aca8a017b12d",
  "a15b3bae14b1b76d5a48ae9a21d0eb86dfd264db238179fb2a4486c002876a52"
)

sha256_file <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
}

read_frozen <- function(spec) {
  path <- file.path(root, spec$path[[1]])
  if (!file.exists(path) || !identical(sha256_file(path), spec$sha256[[1]])) {
    stop("Frozen source identity mismatch: ", spec$path[[1]], call. = FALSE)
  }
  value <- readr::read_csv(path, show_col_types = FALSE, progress = FALSE)
  if (!identical(nrow(value), as.integer(spec$rows[[1]]))) {
    stop("Frozen source row-count mismatch: ", spec$path[[1]], call. = FALSE)
  }
  value
}

support_source <- read_frozen(source_specs[1, ])
paired_source <- read_frozen(source_specs[2, ])
diagnostic_source <- read_frozen(source_specs[3, ])

required_unique <- function(data, columns, expected_rows, label) {
  key_rows <- data |>
    distinct(across(all_of(columns))) |>
    nrow()
  if (!identical(key_rows, as.integer(expected_rows))) {
    stop(label, " key is not unique", call. = FALSE)
  }
  invisible(TRUE)
}

required_unique(
  support_source,
  c("placement_label", "metric_order", "question_order"),
  136L,
  "Model-support"
)
required_unique(
  paired_source,
  c("effect_scale", "point_label"),
  30L,
  "Paired-placement"
)
required_unique(
  diagnostic_source,
  c("placement_label", "metric_order", "check_order"),
  204L,
  "Diagnostic-assessment"
)

if (
  !identical(
    sort(unique(support_source$support_status)),
    c("Not supported", "Supported")
  ) ||
    !identical(
      sort(unique(diagnostic_source$check_status)),
      c("Not applicable", "Pass", "Review")
    ) ||
    !identical(
      sort(unique(paired_source$effect_scale)),
      c("Difference", "Ratio")
    ) ||
    !all(paired_source$sample_exactly_matched)
) {
  stop(
    "A frozen display category or matched-sample flag is invalid",
    call. = FALSE
  )
}

metric_levels_support <- support_source |>
  distinct(.data$metric_order, .data$manuscript_name) |>
  arrange(desc(.data$metric_order)) |>
  pull(.data$manuscript_name)
question_levels <- support_source |>
  distinct(.data$question_order, .data$question_label) |>
  arrange(.data$question_order) |>
  pull(.data$question_label)
metric_levels_diagnostic <- diagnostic_source |>
  distinct(.data$metric_order, .data$manuscript_name) |>
  arrange(desc(.data$metric_order)) |>
  pull(.data$manuscript_name)
diagnostic_levels <- diagnostic_source |>
  distinct(.data$check_order, .data$diagnostic_check) |>
  arrange(.data$check_order) |>
  pull(.data$diagnostic_check)

make_support_plot <- function(candidate = FALSE) {
  symbol_size <- if (candidate) 4.0 else 3.2
  text_size <- if (candidate) 11.2 else NULL
  plot <- support_source |>
    mutate(
      manuscript_name = factor(
        .data$manuscript_name,
        levels = metric_levels_support
      ),
      question_label = factor(.data$question_label, levels = question_levels),
      placement_label = factor(
        .data$placement_label,
        levels = c("Near eye", "Chest")
      )
    ) |>
    ggplot(aes(x = .data$question_label, y = .data$manuscript_name)) +
    geom_tile(
      aes(fill = .data$support_status),
      colour = "white",
      linewidth = 0.35
    ) +
    geom_text(
      aes(label = .data$support_symbol),
      size = symbol_size,
      colour = "#111111"
    ) +
    facet_wrap(vars(.data$placement_label), ncol = 2) +
    scale_fill_manual(
      values = c(
        Supported = "#88CCEE",
        `Not supported` = "#ECECEC",
        `Not estimable` = "#CC6677"
      ),
      drop = FALSE
    ) +
    labs(x = NULL, y = NULL, fill = "FDR-adjusted result") +
    theme_minimal(base_size = 9) +
    theme(
      panel.grid = element_blank(),
      axis.text.x = element_text(angle = 28, hjust = 1),
      strip.text = element_text(face = "bold"),
      legend.position = "bottom"
    )
  if (candidate) {
    plot <- plot +
      theme(
        axis.text.x = element_text(size = text_size, angle = 28, hjust = 1),
        axis.text.y = element_text(size = text_size),
        strip.text = element_text(size = text_size, face = "bold"),
        legend.text = element_text(size = text_size),
        legend.title = element_text(size = text_size)
      )
  }
  plot
}

make_diagnostic_plot <- function(candidate = FALSE) {
  symbol_size <- if (candidate) 4.3 else 3.0
  text_size <- if (candidate) 12.2 else NULL
  plot <- diagnostic_source |>
    mutate(
      manuscript_name = factor(
        .data$manuscript_name,
        levels = metric_levels_diagnostic
      ),
      diagnostic_check = factor(
        .data$diagnostic_check,
        levels = diagnostic_levels
      ),
      placement_label = factor(
        .data$placement_label,
        levels = c("Near eye", "Chest")
      )
    ) |>
    ggplot(aes(x = .data$diagnostic_check, y = .data$manuscript_name)) +
    geom_tile(
      aes(fill = .data$check_status),
      colour = "white",
      linewidth = 0.35
    ) +
    geom_text(aes(label = .data$check_symbol), size = symbol_size) +
    facet_wrap(vars(.data$placement_label), ncol = 2) +
    scale_fill_manual(
      values = c(
        Pass = "#88CCEE",
        Review = "#DDCC77",
        Fail = "#CC6677",
        `Not applicable` = "#ECECEC"
      ),
      drop = FALSE
    ) +
    labs(x = NULL, y = NULL, fill = "Assessment") +
    theme_minimal(base_size = 9.5) +
    theme(
      panel.grid = element_blank(),
      axis.text.x = element_text(angle = 28, hjust = 1),
      strip.text = element_text(face = "bold"),
      legend.position = "bottom"
    )
  if (candidate) {
    plot <- plot +
      theme(
        axis.text.x = element_text(size = text_size, angle = 28, hjust = 1),
        axis.text.y = element_text(size = text_size),
        strip.text = element_text(size = text_size, face = "bold"),
        legend.text = element_text(size = text_size),
        legend.title = element_text(size = text_size)
      )
  }
  plot
}

make_paired_panel <- function(data, scale_name, candidate = FALSE) {
  panel_data <- data |>
    filter(.data$effect_scale == scale_name)
  axis_range <- range(
    c(
      panel_data$near_estimate_practical,
      panel_data$chest_estimate_practical,
      panel_data$null_value
    ),
    na.rm = TRUE
  )
  padding <- max(diff(axis_range) * 0.12, 0.02)
  axis_limits <- axis_range + c(-padding, padding)
  repel_arguments <- if (candidate) {
    list(
      size = 3.1,
      seed = 20260801,
      min.segment.length = 0,
      box.padding = 0.55,
      point.padding = 0.32,
      force = 8,
      force_pull = 0.05,
      max.iter = 100000,
      max.time = 10,
      max.overlaps = Inf,
      show.legend = FALSE
    )
  } else {
    list(
      size = 3.1,
      seed = 20260801,
      min.segment.length = 0,
      box.padding = 0.22,
      point.padding = 0.14,
      max.overlaps = Inf,
      show.legend = FALSE
    )
  }
  plot <- ggplot(
    panel_data,
    aes(
      x = .data$near_estimate_practical,
      y = .data$chest_estimate_practical
    )
  ) +
    geom_abline(
      intercept = 0,
      slope = 1,
      colour = "#555555",
      linewidth = 0.55,
      linetype = 2
    ) +
    geom_vline(
      xintercept = unique(panel_data$null_value),
      colour = "#111111",
      linewidth = 0.45,
      linetype = 3
    ) +
    geom_hline(
      yintercept = unique(panel_data$null_value),
      colour = "#111111",
      linewidth = 0.45,
      linetype = 3
    ) +
    geom_point(
      aes(colour = .data$predictor, shape = .data$predictor),
      size = 2.1
    )
  plot <- plot +
    do.call(
      ggrepel::geom_text_repel,
      c(
        list(
          mapping = aes(label = .data$point_label, colour = .data$predictor)
        ),
        repel_arguments
      )
    )
  plot +
    scale_colour_manual(
      values = c(Photoperiod = "#117733", `Latitude per 10°` = "#332288")
    ) +
    scale_shape_manual(
      values = c(Photoperiod = 16, `Latitude per 10°` = 17)
    ) +
    coord_equal(xlim = axis_limits, ylim = axis_limits, expand = TRUE) +
    labs(
      title = scale_name,
      x = "Near-eye estimate",
      y = "Chest estimate",
      colour = NULL,
      shape = NULL
    ) +
    theme_minimal(base_size = 10.5) +
    theme(
      panel.grid.minor = element_blank(),
      plot.title = element_text(face = "bold"),
      legend.position = "bottom"
    )
}

make_paired_plot <- function(candidate = FALSE) {
  cowplot::plot_grid(
    make_paired_panel(paired_source, "Difference", candidate),
    make_paired_panel(paired_source, "Ratio", candidate),
    nrow = 1,
    align = "hv",
    axis = "tblr",
    rel_widths = c(1, 1)
  )
}

save_pair <- function(plot, output_dir, figure_id, width, height) {
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  png_path <- file.path(output_dir, paste0("H01_stage3_", figure_id, ".png"))
  svg_path <- file.path(output_dir, paste0("H01_stage3_", figure_id, ".svg"))
  ggsave(
    png_path,
    plot,
    width = width,
    height = height,
    units = "in",
    dpi = 320,
    bg = "white"
  )
  ggsave(
    svg_path,
    plot,
    width = width,
    height = height,
    units = "in",
    bg = "white"
  )
  c(png = png_path, svg = svg_path)
}

build_set <- function(output_dir, candidate = FALSE) {
  list(
    model_support = save_pair(
      make_support_plot(candidate),
      output_dir,
      "model_support",
      10.5,
      7.4
    ),
    paired_placement = save_pair(
      make_paired_plot(candidate),
      output_dir,
      "paired_placement",
      12.0,
      6.8
    ),
    diagnostic_assessment = save_pair(
      make_diagnostic_plot(candidate),
      output_dir,
      "diagnostic_assessment",
      11.5,
      7.6
    )
  )
}

png_metadata <- function(path) {
  image <- png::readPNG(path, native = TRUE, info = TRUE)
  info <- attr(image, "info")
  tibble(
    png_width = dim(image)[[2]],
    png_height = dim(image)[[1]],
    dpi_x = unname(info$dpi[[1]]),
    dpi_y = unname(info$dpi[[2]])
  )
}

svg_inventory <- function(path) {
  doc <- xml2::read_xml(path)
  nodes <- xml2::xml_find_all(doc, ".//*")
  tibble(node_name = xml2::xml_name(nodes)) |>
    count(.data$node_name, name = "n") |>
    arrange(.data$node_name)
}

svg_text_inventory <- function(path) {
  doc <- xml2::read_xml(path)
  nodes <- xml2::xml_find_all(doc, ".//*[local-name()='text']")
  tibble(text = xml2::xml_text(nodes)) |>
    count(.data$text, name = "n") |>
    arrange(.data$text)
}

label_boxes <- function(svg_path, labels) {
  doc <- xml2::read_xml(svg_path)
  nodes <- xml2::xml_find_all(doc, ".//*[local-name()='text']")
  values <- xml2::xml_text(nodes)
  nodes <- nodes[values %in% labels]
  values <- xml2::xml_text(nodes)
  if (
    length(values) != length(labels) ||
      anyDuplicated(values) ||
      !identical(sort(values), sort(labels))
  ) {
    stop(
      "A paired-placement point label is missing or duplicated in the SVG",
      call. = FALSE
    )
  }
  styles <- xml2::xml_attr(nodes, "style")
  x <- as.numeric(xml2::xml_attr(nodes, "x"))
  y <- as.numeric(xml2::xml_attr(nodes, "y"))
  raw_width <- xml2::xml_attr(nodes, "textLength")
  if (
    length(raw_width) != length(values) ||
      anyNA(raw_width) ||
      !all(grepl("^[0-9]+(?:\\.[0-9]+)?px$", raw_width, perl = TRUE))
  ) {
    stop(
      "A paired-placement SVG textLength is missing, duplicated, or malformed",
      call. = FALSE
    )
  }
  width <- as.numeric(sub("px$", "", raw_width))
  if (any(!is.finite(width))) {
    stop(
      "A paired-placement SVG textLength is nonfinite",
      call. = FALSE
    )
  }
  font_size <- vapply(
    styles,
    function(value) {
      match <- regmatches(value, regexpr("font-size: [0-9.]+px", value))
      as.numeric(sub(
        "font-size: ",
        "",
        sub("px", "", match, fixed = TRUE),
        fixed = TRUE
      ))
    },
    numeric(1)
  )
  anchor <- xml2::xml_attr(nodes, "text-anchor")
  xmin <- ifelse(anchor == "middle", x - width / 2, x)
  xmax <- ifelse(anchor == "middle", x + width / 2, x + width)
  tibble(
    text = values,
    x = x,
    y = y,
    width = width,
    font_size = font_size,
    xmin = xmin,
    xmax = xmax,
    ymin = y - 0.82 * font_size,
    ymax = y + 0.22 * font_size
  )
}

box_overlap_pairs <- function(boxes, clearance = 0.5) {
  if (nrow(boxes) < 2L) {
    return(tibble(label_a = character(), label_b = character()))
  }
  pairs <- utils::combn(seq_len(nrow(boxes)), 2L)
  hit <- apply(pairs, 2L, function(index) {
    a <- boxes[index[[1]], ]
    b <- boxes[index[[2]], ]
    x_overlap <- min(a$xmax, b$xmax) - max(a$xmin, b$xmin)
    y_overlap <- min(a$ymax, b$ymax) - max(a$ymin, b$ymin)
    x_overlap > -clearance && y_overlap > -clearance
  })
  if (!any(hit)) {
    return(tibble(label_a = character(), label_b = character()))
  }
  pairs <- pairs[, hit, drop = FALSE]
  tibble(
    label_a = boxes$text[pairs[1, ]],
    label_b = boxes$text[pairs[2, ]]
  )
}

font_sizes <- function(svg_path) {
  doc <- xml2::read_xml(svg_path)
  nodes <- xml2::xml_find_all(doc, ".//*[local-name()='text']")
  styles <- xml2::xml_attr(nodes, "style")
  values <- xml2::xml_text(nodes)
  sizes <- vapply(
    styles,
    function(value) {
      match <- regmatches(value, regexpr("font-size: [0-9.]+px", value))
      if (!length(match) || identical(match, "")) NA_real_ else
        as.numeric(sub(
          "font-size: ",
          "",
          sub("px", "", match, fixed = TRUE),
          fixed = TRUE
        ))
    },
    numeric(1)
  )
  tibble(text = values, source_size_pt = sizes)
}

baseline_dir <- file.path(candidate_root, "baseline")
attempt_dir <- file.path(candidate_root, attempt_id)
if (dir.exists(baseline_dir) || dir.exists(attempt_dir)) {
  stop("Baseline or attempt output already exists", call. = FALSE)
}
dir.create(baseline_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(attempt_dir, recursive = TRUE, showWarnings = FALSE)

set.seed(20260801)
baseline_paths <- build_set(baseline_dir, candidate = FALSE)
set.seed(20260801)
candidate_paths <- build_set(attempt_dir, candidate = TRUE)

path_rows <- function(paths, set_name) {
  bind_rows(lapply(names(paths), function(current_figure_id) {
    current_paths <- paths[[current_figure_id]]
    tibble(
      set = set_name,
      figure_id = current_figure_id,
      format = names(current_paths),
      path = unname(current_paths),
      sha256 = vapply(unname(current_paths), sha256_file, character(1)),
      bytes = as.numeric(file.info(unname(current_paths))$size)
    )
  }))
}
output_inventory <- bind_rows(
  path_rows(baseline_paths, "baseline"),
  path_rows(candidate_paths, "candidate")
)
write_csv(output_inventory, file.path(attempt_dir, "output_inventory.csv"))

baseline_check <- output_inventory |>
  filter(.data$set == "baseline") |>
  select("figure_id", "format", "sha256") |>
  tidyr::pivot_wider(names_from = "format", values_from = "sha256") |>
  left_join(
    baseline_specs |>
      select(
        "figure_id",
        expected_png = "source_png_sha256",
        expected_svg = "source_svg_sha256"
      ),
    by = "figure_id",
    relationship = "one-to-one"
  ) |>
  mutate(
    png_exact = .data$png == .data$expected_png,
    svg_exact = .data$svg == .data$expected_svg
  )
write_csv(baseline_check, file.path(attempt_dir, "baseline_identity_check.csv"))
if (!all(baseline_check$png_exact) || !all(baseline_check$svg_exact)) {
  stop(
    "Source-derived baseline did not reproduce every sealed figure",
    call. = FALSE
  )
}

durable_check <- bind_rows(lapply(seq_len(nrow(baseline_specs)), function(index) {
  spec <- baseline_specs[index, ]
  stem <- file.path(
    root,
    "artifacts/10_figures/H01/stage3",
    paste0("H01_stage3_", spec$figure_id[[1]])
  )
  png_path <- paste0(stem, ".png")
  svg_path <- paste0(stem, ".svg")
  tibble(
    figure_id = spec$figure_id[[1]],
    png_path = png_path,
    svg_path = svg_path,
    png_sha256 = sha256_file(png_path),
    svg_sha256 = sha256_file(svg_path),
    png_exact = .data$png_sha256 == spec$png_sha256[[1]],
    svg_exact = .data$svg_sha256 == spec$svg_sha256[[1]]
  )
}))
write_csv(durable_check, file.path(attempt_dir, "durable_identity_check.csv"))
if (!all(durable_check$png_exact) || !all(durable_check$svg_exact)) {
  stop("A sealed durable figure identity changed", call. = FALSE)
}

figure1_sealed_png <- durable_check |>
  filter(.data$figure_id == "model_support") |>
  pull(.data$png_path)
figure1_sealed_svg <- durable_check |>
  filter(.data$figure_id == "model_support") |>
  pull(.data$svg_path)
figure1_source_png <- baseline_paths$model_support[["png"]]
figure1_source_svg <- baseline_paths$model_support[["svg"]]

figure1_sealed_raster <- png::readPNG(figure1_sealed_png)
figure1_source_raster <- png::readPNG(figure1_source_png)
if (!identical(dim(figure1_sealed_raster), dim(figure1_source_raster))) {
  stop("Figure 1 baseline raster dimensions differ", call. = FALSE)
}
figure1_raster_difference <- apply(
  abs(figure1_sealed_raster - figure1_source_raster),
  c(1, 2),
  max
)
figure1_changed_pixels <- which(
  figure1_raster_difference > 0,
  arr.ind = TRUE
)
if (
  nrow(figure1_changed_pixels) != 9477L ||
    !identical(range(figure1_changed_pixels[, "col"]), c(1927L, 2496L)) ||
    !identical(range(figure1_changed_pixels[, "row"]), c(2256L, 2325L))
) {
  stop("Figure 1 sealed-to-source raster transition is not exact", call. = FALSE)
}

figure1_sealed_lines <- readLines(
  figure1_sealed_svg,
  warn = FALSE,
  encoding = "UTF-8"
)
figure1_source_lines <- readLines(
  figure1_source_svg,
  warn = FALSE,
  encoding = "UTF-8"
)
figure1_changed_lines <- which(figure1_sealed_lines != figure1_source_lines)
expected_figure1_sealed_lines <- c(
  "<rect x='432.92' y='507.05' width='16.29' height='16.29' style='stroke-width: 0.75; stroke: #FFFFFF; stroke-linecap: butt; stroke-linejoin: miter; fill: #ECECEC;' />",
  "<rect x='504.34' y='507.05' width='16.29' height='16.29' style='stroke-width: 0.75; stroke: #FFFFFF; stroke-linecap: butt; stroke-linejoin: miter; fill: #88CCEE;' />",
  "<text x='454.19' y='517.77' style='font-size: 7.20px; font-family: \"Arial\";' textLength='45.17px' lengthAdjust='spacingAndGlyphs'>Not supported</text>",
  "<text x='525.61' y='517.77' style='font-size: 7.20px; font-family: \"Arial\";' textLength='33.19px' lengthAdjust='spacingAndGlyphs'>Supported</text>"
)
expected_figure1_source_lines <- c(
  "<rect x='435.92' y='507.05' width='16.29' height='16.29' style='stroke-width: 0.75; stroke: #FFFFFF; stroke-linecap: butt; stroke-linejoin: miter; fill: #ECECEC;' />",
  "<rect x='507.34' y='507.05' width='16.29' height='16.29' style='stroke-width: 0.75; stroke: #FFFFFF; stroke-linecap: butt; stroke-linejoin: miter; fill: #88CCEE;' />",
  "<text x='457.19' y='517.77' style='font-size: 7.20px; font-family: \"Arial\";' textLength='45.17px' lengthAdjust='spacingAndGlyphs'>Not supported</text>",
  "<text x='528.61' y='517.77' style='font-size: 7.20px; font-family: \"Arial\";' textLength='33.19px' lengthAdjust='spacingAndGlyphs'>Supported</text>"
)
if (
  length(figure1_sealed_lines) != 372L ||
    length(figure1_source_lines) != 372L ||
    !identical(figure1_changed_lines, 366:369) ||
    !identical(
      figure1_sealed_lines[figure1_changed_lines],
      expected_figure1_sealed_lines
    ) ||
    !identical(
      figure1_source_lines[figure1_changed_lines],
      expected_figure1_source_lines
    )
) {
  stop("Figure 1 sealed-to-source SVG transition is not exact", call. = FALSE)
}

figure1_provenance <- tibble(
  source_png_sha256 = sha256_file(figure1_source_png),
  sealed_png_sha256 = sha256_file(figure1_sealed_png),
  changed_pixels = nrow(figure1_changed_pixels),
  changed_x_min = min(figure1_changed_pixels[, "col"]),
  changed_x_max = max(figure1_changed_pixels[, "col"]),
  changed_y_min = min(figure1_changed_pixels[, "row"]),
  changed_y_max = max(figure1_changed_pixels[, "row"]),
  source_svg_sha256 = sha256_file(figure1_source_svg),
  sealed_svg_sha256 = sha256_file(figure1_sealed_svg),
  changed_svg_lines = paste(figure1_changed_lines, collapse = ","),
  status = "PASS"
)
write_csv(
  figure1_provenance,
  file.path(attempt_dir, "figure1_baseline_provenance.csv")
)

geometry_check <- bind_rows(lapply(names(candidate_paths), function(figure_id) {
  candidate_png <- candidate_paths[[figure_id]][["png"]]
  actual <- png_metadata(candidate_png)
  expected <- baseline_specs |>
    filter(.data$figure_id == figure_id)
  actual |>
    mutate(
      figure_id = figure_id,
      expected_width = expected$png_width,
      expected_height = expected$png_height,
      width_exact = .data$png_width == .data$expected_width,
      height_exact = .data$png_height == .data$expected_height,
      dpi_exact = abs(.data$dpi_x - 320) < 0.1 & abs(.data$dpi_y - 320) < 0.1
    )
}))
write_csv(geometry_check, file.path(attempt_dir, "geometry_check.csv"))
if (
  !all(
    geometry_check$width_exact &
      geometry_check$height_exact &
      geometry_check$dpi_exact
  )
) {
  stop("A candidate figure has unexpected geometry or DPI", call. = FALSE)
}

structure_check <- bind_rows(lapply(
  names(candidate_paths),
  function(figure_id) {
    baseline_svg <- baseline_paths[[figure_id]][["svg"]]
    candidate_svg <- candidate_paths[[figure_id]][["svg"]]
    node_equal <- identical(
      svg_inventory(baseline_svg),
      svg_inventory(candidate_svg)
    )
    text_equal <- identical(
      svg_text_inventory(baseline_svg),
      svg_text_inventory(candidate_svg)
    )
    tibble(
      figure_id = figure_id,
      node_structure_equal = node_equal,
      text_multiset_equal = text_equal
    )
  }
))
write_csv(structure_check, file.path(attempt_dir, "svg_structure_check.csv"))
if (
  !all(
    structure_check$node_structure_equal & structure_check$text_multiset_equal
  )
) {
  stop("An SVG candidate changed structure or visible text", call. = FALSE)
}

paired_boxes <- label_boxes(
  candidate_paths$paired_placement[["svg"]],
  paired_source$point_label
)
paired_collisions <- box_overlap_pairs(paired_boxes)
write_csv(paired_boxes, file.path(attempt_dir, "paired_label_boxes.csv"))
write_csv(
  paired_collisions,
  file.path(attempt_dir, "paired_label_collisions.csv")
)
if (nrow(paired_collisions) != 0L) {
  stop(
    "The paired-placement candidate retains a label collision",
    call. = FALSE
  )
}

typography <- bind_rows(
  font_sizes(candidate_paths$model_support[["svg"]]) |>
    mutate(
      figure_id = "model_support",
      final_scale_708 = 642 / (10.5 * 96)
    ),
  font_sizes(candidate_paths$diagnostic_assessment[["svg"]]) |>
    mutate(
      figure_id = "diagnostic_assessment",
      final_scale_708 = 642 / (11.5 * 96)
    )
) |>
  mutate(final_size_pt_708 = .data$source_size_pt * .data$final_scale_708)
write_csv(typography, file.path(attempt_dir, "typography_708px.csv"))
required_typography <- typography |>
  filter(!is.na(.data$source_size_pt))
min_typography <- required_typography |>
  group_by(.data$figure_id) |>
  summarise(
    minimum_source_size_pt = min(.data$source_size_pt),
    minimum_final_size_pt_708 = min(.data$final_size_pt_708),
    .groups = "drop"
  )
write_csv(min_typography, file.path(attempt_dir, "typography_minimums.csv"))
if (any(min_typography$minimum_final_size_pt_708 < 7)) {
  stop(
    "A required matrix text element remains below 7 pt at 708 px",
    call. = FALSE
  )
}

source_evidence <- source_specs |>
  mutate(
    current_sha256 = vapply(
      file.path(root, .data$path),
      sha256_file,
      character(1)
    ),
    current_bytes = as.numeric(file.info(file.path(root, .data$path))$size),
    identity_exact = .data$current_sha256 == .data$sha256
  )
write_csv(source_evidence, file.path(attempt_dir, "frozen_source_evidence.csv"))

parameters <- tribble(
  ~figure_id,
  ~parameter,
  ~baseline_value,
  ~candidate_value,
  "model_support",
  "status_symbol_size_mm",
  "3.2",
  "4.0",
  "model_support",
  "required_text_size_pt",
  "theme-derived",
  "11.2",
  "paired_placement",
  "box_padding_lines",
  "0.22",
  "0.55",
  "paired_placement",
  "point_padding_lines",
  "0.14",
  "0.32",
  "paired_placement",
  "force",
  "default",
  "8",
  "paired_placement",
  "force_pull",
  "default",
  "0.05",
  "paired_placement",
  "max_iter",
  "default",
  "100000",
  "paired_placement",
  "max_time_seconds",
  "default",
  "10",
  "diagnostic_assessment",
  "status_symbol_size_mm",
  "3.0",
  "4.3",
  "diagnostic_assessment",
  "required_text_size_pt",
  "theme-derived",
  "12.2"
)
write_csv(parameters, file.path(attempt_dir, "display_parameters.csv"))

session <- capture.output(sessionInfo())
writeLines(session, file.path(attempt_dir, "session_info.txt"), useBytes = TRUE)

attempt_log <- tibble(
  attempt_id = attempt_id,
  created_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
  baseline_exact = all(baseline_check$png_exact & baseline_check$svg_exact),
  geometry_pass = all(
    geometry_check$width_exact &
      geometry_check$height_exact &
      geometry_check$dpi_exact
  ),
  svg_structure_pass = all(
    structure_check$node_structure_equal & structure_check$text_multiset_equal
  ),
  paired_label_collisions = nrow(paired_collisions),
  matrix_minimum_final_pt = min(min_typography$minimum_final_size_pt_708),
  status = "PASS"
)
write_csv(attempt_log, file.path(attempt_dir, "attempt_summary.csv"))

cat(
  "ORDER32D_CANDIDATE_PASS=TRUE\n",
  "ATTEMPT_DIR=",
  attempt_dir,
  "\n",
  "MINIMUM_FINAL_TEXT_PT=",
  min(min_typography$minimum_final_size_pt_708),
  "\n",
  "PAIRED_LABEL_COLLISIONS=",
  nrow(paired_collisions),
  "\n",
  sep = ""
)
