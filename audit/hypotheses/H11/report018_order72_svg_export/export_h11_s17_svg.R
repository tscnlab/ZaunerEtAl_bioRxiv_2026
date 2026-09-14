#!/usr/bin/env Rscript

# REPORT-018 Order 72, H11 S17 candidate-only native SVG export.
# This script reads only frozen display inputs and reproduces the accepted
# plotting expression. It does not read a model or calculate a scientific
# estimate, interval, test, or source-data summary.

options(warn = 1)

required_packages <- c(
  "cowplot", "dplyr", "ggplot2", "LightLogR", "patchwork", "png",
  "ragg", "readr", "scales", "svglite", "systemfonts", "tibble", "xml2"
)

missing_packages <- required_packages[
  !vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
]
if (length(missing_packages)) {
  stop(
    paste("Required installed packages are unavailable:", paste(missing_packages, collapse = ", ")),
    call. = FALSE
  )
}

suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
  library(LightLogR)
  library(patchwork)
  library(readr)
  library(scales)
  library(tibble)
})

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop(
    paste("REPORT-018 Order 72 requires R 4.6.1; found", getRversion()),
    call. = FALSE
  )
}

project_root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
evidence_root <- file.path(
  project_root,
  "audit/hypotheses/H11/report018_order72_svg_export"
)
candidate_dir <- file.path(evidence_root, "candidate")
qa_dir <- file.path(evidence_root, "qa")
evidence_dir <- file.path(evidence_root, "evidence")
script_path <- file.path(evidence_root, "export_h11_s17_svg.R")
stopped_path <- file.path(evidence_root, "REPORT018-ORDER72-SVG-STOPPED.md")

candidate_path <- file.path(
  candidate_dir,
  "H11_reader_primary_near_eye_curves.svg"
)
candidate_native_png <- file.path(
  qa_dir,
  "H11_reader_primary_near_eye_curves_svg_raster_3150x3300.png"
)
accepted_reader_png <- file.path(
  qa_dir,
  "H11_reader_primary_near_eye_curves_accepted_642x673.png"
)
candidate_reader_png <- file.path(
  qa_dir,
  "H11_reader_primary_near_eye_curves_svg_raster_642x673.png"
)
comparison_native_png <- file.path(
  qa_dir,
  "H11_reader_primary_near_eye_curves_comparison_original_size.png"
)
comparison_reader_png <- file.path(
  qa_dir,
  "H11_reader_primary_near_eye_curves_comparison_170mm.png"
)

dir.create(candidate_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(qa_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(evidence_dir, recursive = TRUE, showWarnings = FALSE)

sha256_file <- function(path) {
  output <- system2(
    "/usr/bin/shasum",
    c("-a", "256", shQuote(path)),
    stdout = TRUE,
    stderr = TRUE
  )
  status <- attr(output, "status")
  if (is.null(status)) {
    status <- 0L
  }
  if (status != 0L || length(output) != 1L) {
    stop(paste("SHA-256 failed for", path, paste(output, collapse = "\n")), call. = FALSE)
  }
  strsplit(output[[1L]], "[[:space:]]+")[[1L]][[1L]]
}

run_command <- function(command, args, label) {
  output <- system2(command, args, stdout = TRUE, stderr = TRUE)
  status <- attr(output, "status")
  if (is.null(status)) {
    status <- 0L
  }
  if (status != 0L) {
    stop(
      paste(label, "failed with status", status, paste(output, collapse = "\n")),
      call. = FALSE
    )
  }
  list(status = status, output = output)
}

write_csv_stable <- function(data, path) {
  utils::write.csv(data, path, row.names = FALSE, na = "")
}

normalize_visible_text <- function(text) {
  trimws(gsub("[[:space:]]+", " ", paste(text, collapse = " ")))
}

rasterize_svg <- function(svg_path, max_size_px, output_path, label) {
  scratch <- tempfile(paste0("h11_order72_", label, "_"))
  dir.create(scratch)
  on.exit(unlink(scratch, recursive = TRUE), add = TRUE)
  args <- c(
    "-t", "-s", as.character(max_size_px),
    "-o", shQuote(scratch), shQuote(svg_path)
  )
  result <- run_command("/usr/bin/qlmanage", args, paste(label, "Quick Look rasterization"))
  generated <- list.files(scratch, pattern = "[.]png$", full.names = TRUE)
  if (length(generated) != 1L) {
    stop(paste(label, "did not produce exactly one PNG"), call. = FALSE)
  }
  if (!file.copy(generated[[1L]], output_path, overwrite = FALSE)) {
    stop(paste("Could not copy", label, "rasterization to evidence root"), call. = FALSE)
  }
  list(
    command = paste(c("/usr/bin/qlmanage", args), collapse = " "),
    output = result$output
  )
}

resize_png <- function(input_path, width_px, height_px, output_path) {
  args <- c(
    "-z", as.character(height_px), as.character(width_px),
    shQuote(input_path), "--out", shQuote(output_path)
  )
  result <- run_command("/usr/bin/sips", args, "accepted PNG reader-size resize")
  list(
    command = paste(c("/usr/bin/sips", args), collapse = " "),
    output = result$output
  )
}

compose_comparison <- function(left_path, right_path, output_path, gap_px = 20L) {
  left <- png::readPNG(left_path, native = TRUE)
  right <- png::readPNG(right_path, native = TRUE)
  if (!identical(dim(left), dim(right))) {
    stop("Comparison rasters do not have identical dimensions", call. = FALSE)
  }
  height_px <- nrow(left)
  width_px <- ncol(left)
  canvas_width <- 2L * width_px + gap_px
  ragg::agg_png(
    output_path,
    width = canvas_width,
    height = height_px,
    units = "px",
    res = 300,
    background = "white"
  )
  grid::grid.newpage()
  grid::grid.raster(
    left,
    x = grid::unit(width_px / (2 * canvas_width), "npc"),
    y = grid::unit(0.5, "npc"),
    width = grid::unit(width_px / canvas_width, "npc"),
    height = grid::unit(1, "npc"),
    interpolate = FALSE
  )
  grid::grid.rect(
    x = grid::unit((width_px + gap_px / 2) / canvas_width, "npc"),
    y = grid::unit(0.5, "npc"),
    width = grid::unit(gap_px / canvas_width, "npc"),
    height = grid::unit(1, "npc"),
    gp = grid::gpar(col = NA, fill = "grey85")
  )
  grid::grid.raster(
    right,
    x = grid::unit((width_px + gap_px + width_px / 2) / canvas_width, "npc"),
    y = grid::unit(0.5, "npc"),
    width = grid::unit(width_px / canvas_width, "npc"),
    height = grid::unit(1, "npc"),
    interpolate = FALSE
  )
  grDevices::dev.off()
  invisible(c(width = canvas_width, height = height_px))
}

read_rgb <- function(path) {
  image <- png::readPNG(path)
  if (length(dim(image)) != 3L || dim(image)[[3L]] < 3L) {
    stop(paste("Unexpected PNG channel structure:", path), call. = FALSE)
  }
  rgb <- image[, , 1:3, drop = FALSE]
  if (dim(image)[[3L]] == 4L) {
    alpha <- image[, , 4L]
    for (channel in seq_len(3L)) {
      rgb[, , channel] <- rgb[, , channel] * alpha + (1 - alpha)
    }
  }
  rgb
}

main <- function() {
  if (!file.exists(script_path)) {
    stop("Export script is not at the released evidence-root path", call. = FALSE)
  }
  existing_outputs <- c(
    candidate_path, candidate_native_png, accepted_reader_png,
    candidate_reader_png, comparison_native_png, comparison_reader_png
  )
  if (any(file.exists(existing_outputs))) {
    stop("A candidate or QA endpoint already exists; refusing to overwrite", call. = FALSE)
  }

  release_order <- "audit/report_harmonization/owner_orders/72_manuscript_svg_exports_released.md"
  proposal_order <- "audit/report_harmonization/owner_orders/72_manuscript_svg_exports_proposed.md"
  release_manifest_path <- "audit/report_harmonization/report018_order72_release/release_manifest.csv"
  release_identity <- data.frame(
    role = c("released_order", "incorporated_specification", "release_manifest"),
    path = c(release_order, proposal_order, release_manifest_path),
    expected_sha256 = c(
      "d14575d7c262b01fe58ba85d343f966d5953601a0fb41cc0f61c25279eb4071c",
      "d3f329a2149149663c47e5db4514cbb7771b0afb6362afc8b911871068d0ebcd",
      "8e25aa779f0115a3a5da9ffcdc3913b81cd6fb06df0c17c9f6d5825356263526"
    ),
    stringsAsFactors = FALSE
  )
  release_identity$actual_sha256 <- vapply(
    release_identity$path,
    sha256_file,
    character(1)
  )
  release_identity$status <- ifelse(
    release_identity$actual_sha256 == release_identity$expected_sha256,
    "PASS", "FAIL"
  )
  if (any(release_identity$status != "PASS")) {
    stop("A controlling release identity changed", call. = FALSE)
  }

  release_manifest <- utils::read.csv(
    release_manifest_path,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  if (
    !identical(names(release_manifest), c("path", "sha256", "bytes")) ||
      nrow(release_manifest) != 71L ||
      anyDuplicated(release_manifest$path) ||
      !all(file.exists(release_manifest$path))
  ) {
    stop("The release manifest is not the exact 71-row unique contract", call. = FALSE)
  }
  release_manifest$actual_sha256 <- unname(vapply(
    release_manifest$path,
    sha256_file,
    character(1)
  ))
  release_manifest$actual_bytes <- unname(as.numeric(
    file.info(release_manifest$path)$size
  ))
  release_manifest$status <- ifelse(
    release_manifest$actual_sha256 == release_manifest$sha256 &
      release_manifest$actual_bytes == as.numeric(release_manifest$bytes),
    "PASS", "FAIL"
  )
  if (any(release_manifest$status != "PASS")) {
    stop("At least one release-manifest member changed before export", call. = FALSE)
  }

  input_paths <- c(
    accepted_png = "artifacts/10_figures/H11/stage3/H11_reader_primary_near_eye_curves.png",
    accepted_pdf = "artifacts/10_figures/H11/stage3/H11_reader_primary_near_eye_curves.pdf",
    curves = "artifacts/11_source_data/H11/stage3/H11_reader_sex_specific_curves.csv",
    contrasts = "artifacts/11_source_data/H11/stage3/H11_reader_female_minus_male_contrasts.csv",
    solar = "artifacts/11_source_data/H11/stage3/H11_reader_solar_context.csv",
    samples = "artifacts/09_tables/H11/stage3/H11_reader_samples.csv",
    builder_reference = "scripts/hypotheses/H11/build_h11_stage3_figures.R"
  )
  input_expected_sha256 <- c(
    accepted_png = "33ac814200fc1d69dcf462d0a156b2b950ef0588f47974881fb56f140a414f70",
    accepted_pdf = "ff99643a56830938de7c70cfb60acce43282c0de4a300a8e28231776c6a3616a",
    curves = "76d733c5d04dd6e359aa85b578e54c5d4f292296fa2f5a17e03282856fbc72f3",
    contrasts = "f1950da8a8ffc9d4e344604e384dc2c1facd99610039226d82df1210780cf5fb",
    solar = "acdb226b5e93123f893cb8a6f59382fc87c0fc2a39a9be1d9648f92acdddd793",
    samples = "2aa7c87705db6068c410319eccbc35036b65fbac678c5ab4409581109315d58c",
    builder_reference = "405b357920ce9ba15d4fadd3f34d4ebd33f19ab463b89d856d46ab125318fde2"
  )
  input_preflight <- data.frame(
    role = names(input_paths),
    path = unname(input_paths),
    expected_sha256 = unname(input_expected_sha256),
    actual_sha256 = unname(vapply(input_paths, sha256_file, character(1))),
    bytes = unname(as.numeric(file.info(input_paths)$size)),
    stringsAsFactors = FALSE
  )
  input_preflight$status <- ifelse(
    input_preflight$actual_sha256 == input_preflight$expected_sha256,
    "PASS", "FAIL"
  )
  if (any(input_preflight$status != "PASS")) {
    stop("At least one H11 input pin changed before export", call. = FALSE)
  }

  accepted_png <- input_paths[["accepted_png"]]
  accepted_pdf <- input_paths[["accepted_pdf"]]
  accepted_native <- png::readPNG(accepted_png, native = TRUE)
  if (!identical(dim(accepted_native), c(3300L, 3150L))) {
    stop("Accepted PNG is not 3150 x 3300 pixels", call. = FALSE)
  }

  curves <- readr::read_csv(input_paths[["curves"]], show_col_types = FALSE)
  contrasts <- readr::read_csv(input_paths[["contrasts"]], show_col_types = FALSE)
  solar_context <- readr::read_csv(input_paths[["solar"]], show_col_types = FALSE)
  samples <- readr::read_csv(input_paths[["samples"]], show_col_types = FALSE)

  if (
    nrow(curves) != 384L || nrow(contrasts) != 192L ||
      nrow(solar_context) != 4L || nrow(samples) != 4L
  ) {
    stop("Frozen H11 display input dimensions changed", call. = FALSE)
  }

  run_id <- "main__glasses__all_available"
  run_curves <- curves |>
    dplyr::filter(.data$run_id == .env$run_id) |>
    dplyr::mutate(sex = factor(.data$sex, levels = c("Female", "Male")))
  run_contrast <- contrasts |>
    dplyr::filter(.data$run_id == .env$run_id)
  solar <- solar_context |>
    dplyr::filter(.data$run_id == .env$run_id)
  sample <- samples |>
    dplyr::filter(.data$run_id == .env$run_id)
  if (
    nrow(run_curves) != 96L || nrow(run_contrast) != 48L ||
      nrow(solar) != 1L || nrow(sample) != 1L
  ) {
    stop("The frozen near-eye display rows are incomplete", call. = FALSE)
  }

  night <- tibble::tibble(
    xmin = c(0, solar$equal_site_mean_civil_dusk_hour),
    xmax = c(solar$equal_site_mean_civil_dawn_hour, 24)
  )
  sex_palette <- c(Female = "#CC79A7", Male = "#0072B2")
  wrap_label <- function(text, width) {
    paste(strwrap(text, width = width), collapse = "\n")
  }
  theme_h11 <- function() {
    cowplot::theme_cowplot(font_size = 14) +
      ggplot2::theme(
        panel.grid.minor = ggplot2::element_blank(),
        panel.grid.major.y = ggplot2::element_line(
          colour = "grey88",
          linewidth = 0.35
        ),
        panel.spacing = grid::unit(5, "pt"),
        legend.position = "top",
        legend.title = ggplot2::element_blank(),
        legend.text = ggplot2::element_text(size = 12),
        plot.title.position = "plot",
        plot.caption.position = "plot",
        plot.title = ggplot2::element_text(
          face = "bold", size = 14, lineheight = 1.06
        ),
        plot.subtitle = ggplot2::element_text(size = 12, lineheight = 1.13),
        plot.caption = ggplot2::element_text(size = 11, lineheight = 1.12),
        axis.title = ggplot2::element_text(size = 14),
        axis.text = ggplot2::element_text(size = 12),
        strip.text = ggplot2::element_text(size = 14, face = "bold"),
        plot.tag = ggplot2::element_text(size = 14, face = "bold"),
        plot.margin = ggplot2::margin(8, 10, 8, 8)
      )
  }

  curve_panel <- ggplot2::ggplot(run_curves) +
    ggplot2::geom_rect(
      data = night,
      ggplot2::aes(xmin = .data$xmin, xmax = .data$xmax),
      ymin = -Inf,
      ymax = Inf,
      inherit.aes = FALSE,
      fill = "grey92"
    ) +
    ggplot2::geom_ribbon(
      ggplot2::aes(
        x = .data$time_hour,
        ymin = .data$lower_melEDI_lx_pointwise_95,
        ymax = .data$upper_melEDI_lx_pointwise_95,
        fill = .data$sex
      ),
      alpha = 0.24,
      colour = NA
    ) +
    ggplot2::geom_line(
      ggplot2::aes(
        x = .data$time_hour,
        y = .data$estimate_melEDI_lx,
        colour = .data$sex
      ),
      linewidth = 1.5
    ) +
    ggplot2::scale_colour_manual(values = sex_palette, drop = FALSE) +
    ggplot2::scale_fill_manual(values = sex_palette, drop = FALSE) +
    ggplot2::scale_x_continuous(
      breaks = seq(0, 24, by = 6),
      limits = c(0, 24),
      expand = c(0, 0)
    ) +
    ggplot2::scale_y_continuous(
      trans = LightLogR::symlog_trans(base = 10, thr = 1, scale = 1),
      breaks = c(0, 1, 10, 250, 1000, 10000),
      labels = scales::label_number(big.mark = ",")
    ) +
    ggplot2::labs(
      title = wrap_label("A  Sex-specific near-eye curves", 70),
      subtitle = wrap_label(
        paste0(
          "Equal-site conditional means; ",
          sample$participants, " participants, ",
          sample$participant_days, " participant-days, ",
          format(sample$observations_30_minute, big.mark = ","),
          " 30-minute observations"
        ),
        78
      ),
      x = NULL,
      y = "melEDI (lx)"
    ) +
    theme_h11()

  pointwise_marks <- run_contrast |>
    dplyr::filter(
      .data$pointwise_direction != "not_distinguishable_pointwise"
    )
  all_bins_marked <- nrow(pointwise_marks) == nrow(run_contrast)
  pointwise_marks_for_plot <- if (all_bins_marked) {
    pointwise_marks[0, , drop = FALSE]
  } else {
    pointwise_marks
  }
  ratio_subtitle <- if (all_bins_marked) {
    paste(
      "All 48 displayed pointwise intervals exclude 1; circles are omitted",
      "to keep the curve readable. Intervals are not simultaneous."
    )
  } else {
    paste(
      "Ribbons are participant-cluster-robust pointwise 95% intervals;",
      "open circles mark displayed bins whose interval excludes 1."
    )
  }

  ratio_panel <- ggplot2::ggplot(run_contrast) +
    ggplot2::geom_rect(
      data = night,
      ggplot2::aes(xmin = .data$xmin, xmax = .data$xmax),
      ymin = -Inf,
      ymax = Inf,
      inherit.aes = FALSE,
      fill = "grey92"
    ) +
    ggplot2::geom_hline(
      yintercept = 1,
      linetype = "dashed",
      colour = "grey30"
    ) +
    ggplot2::geom_ribbon(
      ggplot2::aes(
        x = .data$time_hour,
        ymin = .data$ratio_lower_pointwise_95,
        ymax = .data$ratio_upper_pointwise_95
      ),
      fill = "grey55",
      alpha = 0.45
    ) +
    ggplot2::geom_line(
      ggplot2::aes(
        x = .data$time_hour,
        y = .data$female_to_male_shifted_ratio
      ),
      colour = "black",
      linewidth = 1.5
    ) +
    ggplot2::geom_point(
      data = pointwise_marks_for_plot,
      ggplot2::aes(
        x = .data$time_hour,
        y = .data$female_to_male_shifted_ratio
      ),
      shape = 21,
      size = 3,
      stroke = 1,
      fill = "white",
      colour = "black"
    ) +
    ggplot2::scale_x_continuous(
      breaks = seq(0, 24, by = 6),
      limits = c(0, 24),
      expand = c(0, 0)
    ) +
    ggplot2::scale_y_log10(
      breaks = c(0.5, 0.75, 1, 1.5, 2),
      labels = scales::label_number(accuracy = 0.01)
    ) +
    ggplot2::labs(
      title = "B  Female-to-Male shifted-value ratio",
      subtitle = wrap_label(ratio_subtitle, 78),
      x = "Local clock time (hours)",
      y = "Female / Male ratio"
    ) +
    theme_h11()

  plot <- curve_panel / ratio_panel +
    patchwork::plot_layout(heights = c(1.7, 1)) +
    patchwork::plot_annotation(
      caption = wrap_label(
        paste(
          "Grey shading spans midnight to equal-site mean civil dawn and",
          "equal-site mean civil dusk to midnight. Intervals are pointwise,",
          "not simultaneous; the global participant-cluster-robust curve",
          "test is the inferential test and the display cannot establish a",
          "familywise-significant time period. The melEDI axis uses the",
          "approved symlog scale: linear from 0 to 1 lx and base-10 above 1 lx."
        ),
        104
      ),
      theme = theme_h11()
    )

  font_match <- systemfonts::match_fonts("Helvetica")
  if (nrow(font_match) != 1L || !file.exists(font_match$path[[1L]])) {
    stop("Helvetica did not resolve to a local system font", call. = FALSE)
  }

  svglite::svglite(
    candidate_path,
    width = 10.5,
    height = 11,
    bg = "white",
    standalone = TRUE,
    system_fonts = list(sans = "Helvetica"),
    fix_text_size = TRUE
  )
  print(plot)
  grDevices::dev.off()
  if (!file.exists(candidate_path) || file.info(candidate_path)$size <= 0) {
    stop("Native SVG candidate was not written", call. = FALSE)
  }

  native_raster_log <- rasterize_svg(
    candidate_path,
    3300L,
    candidate_native_png,
    "original_size"
  )
  reader_raster_log <- rasterize_svg(
    candidate_path,
    673L,
    candidate_reader_png,
    "reader_size"
  )
  accepted_resize_log <- resize_png(
    accepted_png,
    642L,
    673L,
    accepted_reader_png
  )

  accepted_native_dim <- dim(png::readPNG(accepted_png, native = TRUE))
  candidate_native_dim <- dim(png::readPNG(candidate_native_png, native = TRUE))
  accepted_reader_dim <- dim(png::readPNG(accepted_reader_png, native = TRUE))
  candidate_reader_dim <- dim(png::readPNG(candidate_reader_png, native = TRUE))
  if (
    !identical(accepted_native_dim, c(3300L, 3150L)) ||
      !identical(candidate_native_dim, c(3300L, 3150L)) ||
      !identical(accepted_reader_dim, c(673L, 642L)) ||
      !identical(candidate_reader_dim, c(673L, 642L))
  ) {
    stop("Rasterized comparison dimensions do not match the contract", call. = FALSE)
  }

  compose_comparison(
    accepted_png,
    candidate_native_png,
    comparison_native_png
  )
  compose_comparison(
    accepted_reader_png,
    candidate_reader_png,
    comparison_reader_png
  )

  accepted_reader_rgb <- read_rgb(accepted_reader_png)
  candidate_reader_rgb <- read_rgb(candidate_reader_png)
  if (!identical(dim(accepted_reader_rgb), dim(candidate_reader_rgb))) {
    stop("Reader-size RGB arrays do not match", call. = FALSE)
  }
  pixel_difference <- accepted_reader_rgb - candidate_reader_rgb
  raster_metrics <- data.frame(
    metric = c(
      "accepted_original_width_px", "accepted_original_height_px",
      "candidate_original_width_px", "candidate_original_height_px",
      "intended_width_mm", "reader_width_px", "reader_height_px",
      "mean_absolute_rgb_difference", "root_mean_square_rgb_difference",
      "maximum_absolute_rgb_difference"
    ),
    value = c(
      accepted_native_dim[[2L]], accepted_native_dim[[1L]],
      candidate_native_dim[[2L]], candidate_native_dim[[1L]],
      170, accepted_reader_dim[[2L]], accepted_reader_dim[[1L]],
      mean(abs(pixel_difference)), sqrt(mean(pixel_difference^2)),
      max(abs(pixel_difference))
    ),
    stringsAsFactors = FALSE
  )

  svg_doc <- xml2::read_xml(candidate_path)
  svg_root <- xml2::xml_root(svg_doc)
  root_attributes <- xml2::xml_attrs(svg_root)
  view_box <- unname(root_attributes[["viewBox"]])
  svg_width <- unname(root_attributes[["width"]])
  svg_height <- unname(root_attributes[["height"]])
  if (is.null(view_box) || is.null(svg_width) || is.null(svg_height)) {
    stop("SVG root dimensions are incomplete", call. = FALSE)
  }
  view_box_numbers <- as.numeric(strsplit(view_box, "[[:space:]]+")[[1L]])
  if (
    length(view_box_numbers) != 4L ||
      !isTRUE(all.equal(view_box_numbers[[3L]] / view_box_numbers[[4L]], 10.5 / 11))
  ) {
    stop("SVG viewBox ratio differs from the accepted canvas", call. = FALSE)
  }

  xml_count <- function(local_name) {
    length(xml2::xml_find_all(
      svg_doc,
      paste0("//*[local-name()='", local_name, "']")
    ))
  }
  vector_element_count <- sum(vapply(
    c("path", "rect", "line", "polyline", "polygon", "circle", "text"),
    xml_count,
    integer(1)
  ))
  svg_raw <- paste(readLines(candidate_path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  all_nodes <- xml2::xml_find_all(svg_doc, "//*")
  all_attributes <- lapply(all_nodes, xml2::xml_attrs)
  href_values <- unlist(lapply(all_attributes, function(attrs) {
    if (!length(attrs)) return(character())
    attrs[names(attrs) %in% c("href", "xlink:href")]
  }), use.names = FALSE)
  external_hrefs <- href_values[
    nzchar(href_values) & !startsWith(href_values, "#")
  ]
  forbidden_tokens <- c(
    "data:image", "<script", "<image", "<foreignObject", "<metadata",
    "@font-face", "/Users/", "file://", "url(http://", "url(https://",
    "main__glasses__all_available", "participant_id", "subject_id",
    "device_id", "frame_sha256", ".csv", ".rds"
  )
  forbidden_found <- forbidden_tokens[
    vapply(forbidden_tokens, grepl, logical(1), x = svg_raw, fixed = TRUE)
  ]
  if (
    vector_element_count <= 0L || xml_count("image") != 0L ||
      xml_count("script") != 0L || xml_count("foreignObject") != 0L ||
      xml_count("metadata") != 0L || length(external_hrefs) != 0L ||
      length(forbidden_found) != 0L
  ) {
    stop("SVG native-vector or privacy contract failed", call. = FALSE)
  }

  pdf_text_path <- tempfile(fileext = ".txt")
  on.exit(unlink(pdf_text_path), add = TRUE)
  pdf_text_result <- run_command(
    "/opt/homebrew/bin/pdftotext",
    c("-layout", shQuote(accepted_pdf), shQuote(pdf_text_path)),
    "accepted PDF text extraction"
  )
  accepted_pdf_text <- normalize_visible_text(
    readLines(pdf_text_path, warn = FALSE, encoding = "UTF-8")
  )
  svg_visible_text <- normalize_visible_text(xml2::xml_text(
    xml2::xml_find_all(svg_doc, "//*[local-name()='text']")
  ))
  required_visible_tokens <- c(
    "Sex-specific near-eye curves",
    "Equal-site conditional means; 141 participants, 816 participant-days, 37,756",
    "30-minute observations",
    "Female", "Male", "melEDI (lx)",
    "Female-to-Male shifted-value ratio",
    "participant-cluster-robust pointwise 95% intervals",
    "displayed bins whose interval excludes 1",
    "Female / Male ratio", "Local clock time (hours)",
    "Grey shading spans midnight to equal-site mean civil dawn and equal-site mean civil dusk to midnight.",
    "Intervals are pointwise, not simultaneous",
    "global participant-cluster-robust curve test",
    "familywise-significant time period",
    "linear from 0 to 1 lx and base-10 above 1 lx."
  )
  visible_text_contract <- data.frame(
    token = required_visible_tokens,
    accepted_pdf = vapply(
      required_visible_tokens,
      grepl,
      logical(1),
      x = accepted_pdf_text,
      fixed = TRUE
    ),
    candidate_svg = vapply(
      required_visible_tokens,
      grepl,
      logical(1),
      x = svg_visible_text,
      fixed = TRUE
    ),
    stringsAsFactors = FALSE
  )
  if (!all(visible_text_contract$accepted_pdf & visible_text_contract$candidate_svg)) {
    stop("Accepted visible-text tokens are not preserved in the SVG", call. = FALSE)
  }

  svg_checks <- data.frame(
    check = c(
      "native_vector_elements_present", "embedded_raster_absent",
      "script_absent", "foreign_object_absent", "metadata_absent",
      "external_resource_absent", "forbidden_private_payload_absent",
      "viewbox_ratio_matches_10.5_by_11", "local_helvetica_resolved"
    ),
    status = rep("PASS", 9L),
    detail = c(
      as.character(vector_element_count), as.character(xml_count("image")),
      as.character(xml_count("script")), as.character(xml_count("foreignObject")),
      as.character(xml_count("metadata")), as.character(length(external_hrefs)),
      as.character(length(forbidden_found)), view_box,
      font_match$path[[1L]]
    ),
    stringsAsFactors = FALSE
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
  candidate_identity <- data.frame(
    path = substring(candidate_path, nchar(project_root) + 2L),
    sha256 = sha256_file(candidate_path),
    bytes = as.numeric(file.info(candidate_path)$size),
    width = svg_width,
    height = svg_height,
    viewBox = view_box,
    native_raster_width_px = candidate_native_dim[[2L]],
    native_raster_height_px = candidate_native_dim[[1L]],
    intended_reader_width_mm = 170,
    intended_reader_width_px = candidate_reader_dim[[2L]],
    intended_reader_height_px = candidate_reader_dim[[1L]],
    stringsAsFactors = FALSE
  )

  command_log <- c(
    paste(
      "env RENV_CONFIG_AUTOLOADER_ENABLED=FALSE",
      "R_LIBS_USER=/Users/zauner/Library/R/arm64/4.6/library",
      "Rscript --vanilla",
      substring(script_path, nchar(project_root) + 2L)
    ),
    native_raster_log$command,
    reader_raster_log$command,
    accepted_resize_log$command,
    paste(
      "/opt/homebrew/bin/pdftotext -layout",
      accepted_pdf,
      "<private temporary text file>"
    )
  )

  write_csv_stable(release_identity, file.path(evidence_dir, "release_identities.csv"))
  write_csv_stable(
    release_manifest,
    file.path(evidence_dir, "release_manifest_preflight_71.csv")
  )
  write_csv_stable(input_preflight, file.path(evidence_dir, "h11_input_preflight.csv"))
  write_csv_stable(candidate_identity, file.path(evidence_dir, "candidate_identity.csv"))
  write_csv_stable(svg_checks, file.path(evidence_dir, "svg_native_vector_privacy_checks.csv"))
  write_csv_stable(visible_text_contract, file.path(evidence_dir, "visible_text_contract.csv"))
  write_csv_stable(raster_metrics, file.path(evidence_dir, "raster_comparison_metrics.csv"))
  write_csv_stable(package_versions, file.path(evidence_dir, "package_versions.csv"))
  writeLines(command_log, file.path(evidence_dir, "commands.txt"), useBytes = TRUE)
  writeLines(capture.output(sessionInfo()), file.path(evidence_dir, "session_info.txt"), useBytes = TRUE)
  writeLines(
    c(
      "REPORT018-ORDER72-SVG-REVIEW",
      "",
      "Automated export, native-vector, privacy, text, dimension, and protected-input checks passed.",
      "Human side-by-side review remains mandatory before owner completion."
    ),
    file.path(evidence_root, "AUTOMATED_PASS_REVIEW_REQUIRED.md"),
    useBytes = TRUE
  )

  post_manifest <- utils::read.csv(
    release_manifest_path,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  post_manifest$actual_sha256 <- unname(vapply(
    post_manifest$path,
    sha256_file,
    character(1)
  ))
  post_manifest$actual_bytes <- unname(as.numeric(file.info(post_manifest$path)$size))
  post_manifest$status <- ifelse(
    post_manifest$actual_sha256 == post_manifest$sha256 &
      post_manifest$actual_bytes == as.numeric(post_manifest$bytes),
    "PASS", "FAIL"
  )
  if (any(post_manifest$status != "PASS")) {
    stop("A protected release-manifest member changed during export QA", call. = FALSE)
  }
  write_csv_stable(
    post_manifest,
    file.path(evidence_dir, "post_qa_protected_rehash_71.csv")
  )

  cat(
    sprintf(
      paste0(
        "AUTOMATED PASS candidate=%s sha256=%s bytes=%d ",
        "viewBox=%s native=%dx%d reader=%dx%d\n"
      ),
      candidate_identity$path,
      candidate_identity$sha256,
      as.integer(candidate_identity$bytes),
      candidate_identity$viewBox,
      candidate_identity$native_raster_width_px,
      candidate_identity$native_raster_height_px,
      candidate_identity$intended_reader_width_px,
      candidate_identity$intended_reader_height_px
    )
  )
}

status <- tryCatch(
  {
    main()
    0L
  },
  error = function(error) {
    writeLines(
      c(
        "# REPORT018-ORDER72-SVG-REVIEW: STOPPED",
        "",
        paste("Time:", format(Sys.time(), tz = "Europe/Berlin", usetz = TRUE)),
        paste("R:", as.character(getRversion())),
        paste("Error:", conditionMessage(error)),
        "",
        "No retry is authorized under this order."
      ),
      stopped_path,
      useBytes = TRUE
    )
    message(conditionMessage(error))
    1L
  }
)

quit(save = "no", status = status)
