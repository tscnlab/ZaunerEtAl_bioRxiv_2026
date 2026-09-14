#!/usr/bin/env Rscript

# Rebuild the four H09 reader-figure families from frozen display CSVs only.

options(stringsAsFactors = FALSE, warn = 2)

assert_true <- function(value, message) {
  if (!isTRUE(value)) stop(message, call. = FALSE)
}

assert_all <- function(value, message) {
  if (!length(value) || !all(value)) stop(message, call. = FALSE)
}

required_packages <- c(
  "digest",
  "dplyr",
  "ggplot2",
  "patchwork",
  "ragg",
  "readr",
  "stringr"
)
missing_packages <- required_packages[
  !vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
]
if (length(missing_packages)) {
  stop(
    "Missing synchronized project package(s): ",
    paste(missing_packages, collapse = ", "),
    call. = FALSE
  )
}

assert_true(
  identical(as.character(getRversion()), "4.6.1"),
  sprintf("Order 56a requires R 4.6.1, found %s.", getRversion())
)

sha256_file <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
}

# Preserve the accepted builder geometry while containing its ggplot2 4.0
# lifecycle warning inside this exact historical-display reconstruction.
geom_errorbarh_frozen <- function(...) {
  suppressWarnings(ggplot2::geom_errorbarh(...))
}

normalize_output_directory <- function(path, project_root) {
  assert_true(
    length(path) == 1L && !is.na(path) && nzchar(path),
    "`output_dir` must be one explicit absolute directory."
  )
  assert_true(
    startsWith(path, "/private/tmp/"),
    "`output_dir` must be a fresh directory under `/private/tmp`."
  )
  dir.create(path, recursive = TRUE, showWarnings = FALSE)
  output_dir <- normalizePath(path, winslash = "/", mustWork = TRUE)
  root_prefix <- paste0(
    normalizePath(project_root, winslash = "/", mustWork = TRUE),
    "/"
  )
  assert_true(
    !startsWith(output_dir, root_prefix),
    "`output_dir` must be outside the project."
  )
  members <- list.files(output_dir, all.files = TRUE, no.. = TRUE)
  assert_true(
    length(members) == 0L,
    "`output_dir` must be empty before the refresh starts."
  )
  output_dir
}

read_frozen_inputs <- function(project_root) {
  input_paths <- c(
    primary = file.path(
      project_root,
      "artifacts/11_source_data/H09/H09_primary_effects_data.csv"
    ),
    paired = file.path(
      project_root,
      "artifacts/11_source_data/H09/H09_paired_placement_effects_data.csv"
    ),
    diagnostic = file.path(
      project_root,
      "artifacts/11_source_data/H09/H09_primary_diagnostic_figure_data.csv"
    ),
    figure_manifest = file.path(
      project_root,
      "artifacts/12_manifests/H09/H09_figure_manifest.csv"
    )
  )
  expected_hashes <- c(
    primary = "3972ae75c9aef8551cc85f50d7a438b35b7a55dca58d81f3630133132a25aaf6",
    paired = "ecc9fe09a1e823ec6b45b2b28239e56bf773a6d8a8c0bb458413e1e2e9b170b0",
    diagnostic = "b3119775c6725295b54af0fea735d89b892f4e9dcea94c9ff564248e5345854a"
  )
  assert_all(file.exists(input_paths), "An allowed display input is missing.")
  observed_hashes <- vapply(
    input_paths[names(expected_hashes)],
    sha256_file,
    character(1)
  )
  assert_true(
    identical(unname(observed_hashes), unname(expected_hashes)),
    "A frozen H09 display CSV does not match its Order 56a pin."
  )

  primary <- readr::read_csv(input_paths[["primary"]], show_col_types = FALSE)
  paired <- readr::read_csv(input_paths[["paired"]], show_col_types = FALSE)
  diagnostic <- readr::read_csv(
    input_paths[["diagnostic"]],
    show_col_types = FALSE
  )
  figure_manifest <- readr::read_csv(
    input_paths[["figure_manifest"]],
    show_col_types = FALSE
  )

  expected_figure_ids <- c(
    "primary_effects",
    "paired_placement_effects",
    "diagnostics_near_eye",
    "diagnostics_chest"
  )
  display_rows <- figure_manifest[
    match(expected_figure_ids, figure_manifest$figure_id),
    ,
    drop = FALSE
  ]
  assert_true(
    identical(display_rows$figure_id, expected_figure_ids),
    "The current H09 display manifest is missing an Order 56a figure row."
  )
  assert_true(
    identical(display_rows$base_width_in, c(10.5, 8, 10.5, 10.5)) &&
      identical(display_rows$export_scale_multiplier, rep(1.5, 4L)) &&
      identical(display_rows$raster_dpi, rep(300, 4L)) &&
      identical(display_rows$intended_display_width_mm, rep(170, 4L)),
    "The fixed width, export scale, DPI, or display-width contract changed."
  )
  assert_true(
    nrow(primary) == 20L &&
      nrow(paired) == 10L &&
      nrow(diagnostic) == 18026L,
    "A frozen H09 display source has an unexpected row count."
  )

  list(
    paths = input_paths,
    expected_hashes = expected_hashes,
    primary = primary,
    paired = paired,
    diagnostic = diagnostic,
    figure_manifest = figure_manifest,
    display_rows = display_rows
  )
}

prepare_plot_data <- function(inputs) {
  metric_levels <- inputs$primary |>
    dplyr::distinct(.data$metric_order, .data$metric_label) |>
    dplyr::arrange(.data$metric_order) |>
    dplyr::pull(.data$metric_label)
  assert_true(
    length(metric_levels) == 5L && !anyDuplicated(metric_levels),
    "The five registered timing-metric labels are not unique."
  )

  primary <- inputs$primary |>
    dplyr::mutate(
      metric_label = factor(.data$metric_label, levels = rev(metric_levels)),
      instrument_label = factor(
        .data$instrument_label,
        levels = c("MCTQ MSFsc", "MEQ")
      ),
      placement_label = factor(
        .data$placement_label,
        levels = c("Near eye", "Chest")
      )
    )

  paired <- inputs$paired |>
    dplyr::mutate(
      metric_label = factor(.data$abbreviation, levels = metric_levels),
      instrument_label = factor(
        .data$instrument_name,
        levels = c("MCTQ MSFsc", "MEQ")
      )
    )

  list(
    metric_levels = metric_levels,
    primary = primary,
    paired = paired,
    diagnostic = inputs$diagnostic
  )
}

theme_values <- function(theme_mode) {
  theme_mode <- match.arg(theme_mode, c("historical", "repaired"))
  if (theme_mode == "historical") {
    return(list(
      primary_minimum = 12,
      paired_minimum = 12,
      diagnostic_minimum = 12,
      primary_height = 6,
      paired_height = 6,
      diagnostic_height = 14,
      diagnostic_wrap_width = Inf
    ))
  }
  list(
    primary_minimum = 17,
    paired_minimum = 13,
    diagnostic_minimum = 17,
    primary_height = 6.5,
    paired_height = 6.5,
    diagnostic_height = 17.5,
    diagnostic_wrap_width = 26
  )
}

make_primary_plot <- function(data, theme_mode) {
  plot <- ggplot2::ggplot(
    data,
    ggplot2::aes(
      x = .data$estimate,
      y = .data$metric_label,
      colour = .data$placement_label,
      shape = .data$placement_label
    )
  ) +
    ggplot2::geom_vline(
      xintercept = 0,
      colour = "grey55",
      linewidth = 0.45
    ) +
    geom_errorbarh_frozen(
      ggplot2::aes(xmin = .data$conf_low, xmax = .data$conf_high),
      height = 0.12,
      position = ggplot2::position_dodge(width = 0.42),
      linewidth = 0.7
    ) +
    ggplot2::geom_point(
      position = ggplot2::position_dodge(width = 0.42),
      size = 2.8,
      stroke = 0.9
    ) +
    ggplot2::facet_wrap(~instrument_label, scales = "free_x", nrow = 1) +
    ggplot2::scale_colour_manual(
      values = c("Near eye" = "#0072B2", "Chest" = "#D55E00")
    ) +
    ggplot2::scale_shape_manual(values = c("Near eye" = 16, "Chest" = 17)) +
    ggplot2::labs(
      x = "Difference in local exposure timing (hours)",
      y = NULL,
      colour = "Placement",
      shape = "Placement"
    ) +
    ggplot2::theme_bw(base_size = 14) +
    ggplot2::theme(
      legend.position = "top",
      strip.text = ggplot2::element_text(face = "bold", size = 14),
      axis.text = ggplot2::element_text(size = 12),
      axis.title = ggplot2::element_text(size = 14),
      panel.grid.minor = ggplot2::element_blank()
    )

  if (theme_mode == "repaired") {
    plot <- plot +
      ggplot2::theme(
        text = ggplot2::element_text(size = 17),
        legend.text = ggplot2::element_text(size = 17),
        legend.title = ggplot2::element_text(size = 17),
        strip.text = ggplot2::element_text(face = "bold", size = 17),
        axis.text = ggplot2::element_text(size = 17),
        axis.title = ggplot2::element_text(size = 17),
        panel.spacing = grid::unit(12, "pt"),
        plot.margin = ggplot2::margin(12, 16, 12, 12)
      )
  }
  plot
}

make_paired_plot <- function(data, theme_mode) {
  limits <- range(
    c(
      data$conf_low_glasses,
      data$conf_high_glasses,
      data$conf_low_chest,
      data$conf_high_chest,
      0
    ),
    na.rm = TRUE
  )
  padding <- diff(limits) * 0.08
  limits <- limits + c(-padding, padding)

  plot <- ggplot2::ggplot(
    data,
    ggplot2::aes(
      x = .data$estimate_glasses,
      y = .data$estimate_chest,
      colour = .data$metric_label,
      shape = .data$metric_label
    )
  ) +
    ggplot2::geom_abline(
      intercept = 0,
      slope = 1,
      colour = "grey45",
      linetype = "dashed",
      linewidth = 0.6
    ) +
    ggplot2::geom_vline(
      xintercept = 0,
      colour = "grey70",
      linewidth = 0.45
    ) +
    ggplot2::geom_hline(
      yintercept = 0,
      colour = "grey70",
      linewidth = 0.45
    ) +
    ggplot2::geom_errorbar(
      ggplot2::aes(
        ymin = .data$conf_low_chest,
        ymax = .data$conf_high_chest
      ),
      width = 0,
      linewidth = 0.55
    ) +
    geom_errorbarh_frozen(
      ggplot2::aes(
        xmin = .data$conf_low_glasses,
        xmax = .data$conf_high_glasses
      ),
      height = 0,
      linewidth = 0.55
    ) +
    ggplot2::geom_point(size = 3.1, stroke = 0.9) +
    ggplot2::facet_wrap(~instrument_label, nrow = 1) +
    ggplot2::coord_equal(xlim = limits, ylim = limits) +
    ggplot2::scale_colour_brewer(palette = "Dark2", drop = FALSE) +
    ggplot2::scale_shape_manual(
      values = c(16, 17, 15, 18, 3),
      drop = FALSE
    ) +
    ggplot2::labs(
      x = "Near-eye estimate (hours)",
      y = "Chest estimate (hours)",
      colour = "Timing metric",
      shape = "Timing metric"
    ) +
    ggplot2::theme_bw(base_size = 14) +
    ggplot2::theme(
      legend.position = "bottom",
      strip.text = ggplot2::element_text(face = "bold", size = 14),
      axis.text = ggplot2::element_text(size = 12),
      axis.title = ggplot2::element_text(size = 14),
      panel.grid.minor = ggplot2::element_blank()
    )

  if (theme_mode == "repaired") {
    plot <- plot +
      ggplot2::theme(
        text = ggplot2::element_text(size = 13),
        legend.text = ggplot2::element_text(size = 13),
        legend.title = ggplot2::element_text(size = 13),
        strip.text = ggplot2::element_text(face = "bold", size = 14),
        axis.text = ggplot2::element_text(size = 13),
        axis.title = ggplot2::element_text(size = 14),
        panel.spacing = grid::unit(10, "pt"),
        plot.margin = ggplot2::margin(10, 14, 12, 10)
      )
  }
  plot
}

make_diagnostic_components <- function(
  data,
  placement,
  placement_label,
  theme_mode
) {
  values <- theme_values(theme_mode)
  plot_data <- data |>
    dplyr::filter(.data$placement == .env$placement) |>
    dplyr::mutate(
      panel = paste(.data$abbreviation, .data$instrument_name, sep = " — ")
    )
  facet_layer <- if (theme_mode == "historical") {
    ggplot2::facet_wrap(~panel, scales = "free_x", ncol = 3)
  } else {
    ggplot2::facet_wrap(
      ~panel,
      scales = "free_x",
      ncol = 3,
      labeller = ggplot2::label_wrap_gen(
        width = values$diagnostic_wrap_width
      )
    )
  }
  qq_facet_layer <- if (theme_mode == "historical") {
    ggplot2::facet_wrap(~panel, scales = "free", ncol = 3)
  } else {
    ggplot2::facet_wrap(
      ~panel,
      scales = "free",
      ncol = 3,
      labeller = ggplot2::label_wrap_gen(
        width = values$diagnostic_wrap_width
      )
    )
  }

  residual_plot <- ggplot2::ggplot(
    plot_data,
    ggplot2::aes(x = .data$fitted, y = .data$standardized_residual)
  ) +
    ggplot2::geom_hline(yintercept = 0, colour = "grey55") +
    ggplot2::geom_point(alpha = 0.32, size = 0.8) +
    facet_layer +
    ggplot2::labs(
      x = "Fitted timing (hours)",
      y = "Standardized residual"
    ) +
    ggplot2::theme_bw(base_size = 14) +
    ggplot2::theme(
      strip.text = ggplot2::element_text(size = 12, face = "bold"),
      axis.text = ggplot2::element_text(size = 12),
      axis.title = ggplot2::element_text(size = 13),
      panel.grid.minor = ggplot2::element_blank()
    )
  qq_plot <- ggplot2::ggplot(
    plot_data,
    ggplot2::aes(
      x = .data$theoretical_quantile,
      y = .data$sample_quantile
    )
  ) +
    ggplot2::geom_abline(intercept = 0, slope = 1, colour = "grey55") +
    ggplot2::geom_point(alpha = 0.32, size = 0.8) +
    qq_facet_layer +
    ggplot2::labs(
      x = "Normal-score quantile",
      y = "Standardized residual"
    ) +
    ggplot2::theme_bw(base_size = 14) +
    ggplot2::theme(
      strip.text = ggplot2::element_text(size = 12, face = "bold"),
      axis.text = ggplot2::element_text(size = 12),
      axis.title = ggplot2::element_text(size = 13),
      panel.grid.minor = ggplot2::element_blank()
    )
  annotation_theme <- ggplot2::theme(
    plot.title = ggplot2::element_text(face = "bold", size = 16)
  )
  if (theme_mode == "repaired") {
    repaired_theme <- ggplot2::theme(
      text = ggplot2::element_text(size = 17),
      strip.text = ggplot2::element_text(size = 17, face = "bold"),
      axis.text = ggplot2::element_text(size = 17),
      axis.title = ggplot2::element_text(size = 17),
      plot.tag = ggplot2::element_text(size = 17, face = "bold"),
      panel.spacing = grid::unit(10, "pt"),
      plot.margin = ggplot2::margin(10, 12, 10, 10)
    )
    residual_plot <- residual_plot + repaired_theme
    qq_plot <- qq_plot + repaired_theme
    annotation_theme <- ggplot2::theme(
      plot.title = ggplot2::element_text(face = "bold", size = 18),
      plot.margin = ggplot2::margin(12, 12, 8, 12)
    )
  }

  combined <- patchwork::wrap_plots(residual_plot, qq_plot, ncol = 1) +
    patchwork::plot_annotation(
      title = paste0(
        "H09 mixed-model residual diagnostics — ",
        placement_label
      ),
      tag_levels = "A",
      theme = annotation_theme
    )
  list(
    data = plot_data,
    residual = residual_plot,
    qq = qq_plot,
    combined = combined
  )
}

build_h09_order56_plots <- function(inputs, theme_mode) {
  theme_mode <- match.arg(theme_mode, c("historical", "repaired"))
  prepared <- prepare_plot_data(inputs)
  near_eye <- make_diagnostic_components(
    prepared$diagnostic,
    "glasses",
    "Near eye",
    theme_mode
  )
  chest <- make_diagnostic_components(
    prepared$diagnostic,
    "chest",
    "Chest",
    theme_mode
  )
  list(
    plots = list(
      primary_effects = make_primary_plot(prepared$primary, theme_mode),
      paired_placement_effects = make_paired_plot(
        prepared$paired,
        theme_mode
      ),
      diagnostics_near_eye = near_eye$combined,
      diagnostics_chest = chest$combined
    ),
    components = list(
      primary_effects = list(
        main = make_primary_plot(
          prepared$primary,
          theme_mode
        )
      ),
      paired_placement_effects = list(
        main = make_paired_plot(
          prepared$paired,
          theme_mode
        )
      ),
      diagnostics_near_eye = near_eye[c("residual", "qq")],
      diagnostics_chest = chest[c("residual", "qq")]
    ),
    prepared = list(
      primary_effects = prepared$primary,
      paired_placement_effects = prepared$paired,
      diagnostics_near_eye = near_eye$data,
      diagnostics_chest = chest$data
    ),
    values = theme_values(theme_mode)
  )
}

save_h09_order56_plots <- function(plot_set, output_dir, theme_mode) {
  theme_mode <- match.arg(theme_mode, c("historical", "repaired"))
  values <- plot_set$values
  figure_specs <- data.frame(
    figure_id = c(
      "primary_effects",
      "paired_placement_effects",
      "diagnostics_near_eye",
      "diagnostics_chest"
    ),
    stem = c(
      "H09_primary_effects",
      "H09_paired_placement_effects",
      "H09_diagnostics_near_eye",
      "H09_diagnostics_chest"
    ),
    width = c(10.5, 8, 10.5, 10.5),
    height = c(
      values$primary_height,
      values$paired_height,
      values$diagnostic_height,
      values$diagnostic_height
    ),
    scale = 1.5,
    dpi = 300,
    stringsAsFactors = FALSE
  )
  output_paths <- character()
  for (index in seq_len(nrow(figure_specs))) {
    spec <- figure_specs[index, , drop = FALSE]
    plot <- plot_set$plots[[spec$figure_id]]
    png_path <- file.path(output_dir, paste0(spec$stem, ".png"))
    pdf_path <- file.path(output_dir, paste0(spec$stem, ".pdf"))
    ggplot2::ggsave(
      png_path,
      plot,
      width = spec$width,
      height = spec$height,
      scale = spec$scale,
      dpi = spec$dpi,
      device = ragg::agg_png
    )
    ggplot2::ggsave(
      pdf_path,
      plot,
      width = spec$width,
      height = spec$height,
      scale = spec$scale,
      device = grDevices::cairo_pdf
    )
    output_paths <- c(output_paths, png_path, pdf_path)
  }
  assert_true(
    length(output_paths) == 8L && all(file.exists(output_paths)),
    "The complete eight-file figure set was not written."
  )
  list(paths = output_paths, specs = figure_specs)
}

refresh_h09_order56_figures <- function(
  output_dir,
  theme_mode,
  project_root = getwd()
) {
  theme_mode <- match.arg(theme_mode, c("historical", "repaired"))
  project_root <- normalizePath(
    project_root,
    winslash = "/",
    mustWork = TRUE
  )
  output_dir <- normalize_output_directory(output_dir, project_root)
  inputs <- read_frozen_inputs(project_root)
  plot_set <- build_h09_order56_plots(inputs, theme_mode)
  outputs <- save_h09_order56_plots(plot_set, output_dir, theme_mode)
  invisible(list(
    inputs = inputs,
    plot_set = plot_set,
    output_paths = outputs$paths,
    figure_specs = outputs$specs,
    theme_mode = theme_mode,
    output_dir = output_dir
  ))
}

parse_cli_arguments <- function(arguments) {
  values <- stats::setNames(
    rep(NA_character_, 2L),
    c("output_dir", "theme_mode")
  )
  for (argument in arguments) {
    if (startsWith(argument, "--output-dir=")) {
      values[["output_dir"]] <- sub("^--output-dir=", "", argument)
    } else if (startsWith(argument, "--theme-mode=")) {
      values[["theme_mode"]] <- sub("^--theme-mode=", "", argument)
    } else {
      stop(
        "Unsupported command-line argument: `",
        argument,
        "`.",
        call. = FALSE
      )
    }
  }
  assert_true(
    all(!is.na(values)) && all(nzchar(values)),
    "Supply `--output-dir=` and `--theme-mode=` explicitly."
  )
  values
}

if (
  sys.nframe() == 0L &&
    !identical(Sys.getenv("H09_ORDER56A_SOURCE_ONLY"), "TRUE")
) {
  cli <- parse_cli_arguments(commandArgs(trailingOnly = TRUE))
  result <- refresh_h09_order56_figures(
    output_dir = cli[["output_dir"]],
    theme_mode = cli[["theme_mode"]],
    project_root = Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd())
  )
  cat(sprintf(
    "H09_ORDER56A_REFRESH=PASS mode=%s outputs=%d output_dir=%s\n",
    result$theme_mode,
    length(result$output_paths),
    result$output_dir
  ))
}
