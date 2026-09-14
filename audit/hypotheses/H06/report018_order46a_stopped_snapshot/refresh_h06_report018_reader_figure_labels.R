#!/usr/bin/env Rscript

# Refresh only the reader-visible labels in four frozen H06 figure families.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
mode <- Sys.getenv("H06_REPORT018_MODE", unset = "prepare")
if (!mode %in% c("prepare", "promote")) {
  stop("H06_REPORT018_MODE must be `prepare` or `promote`", call. = FALSE)
}
if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("REPORT-018 H06 order 46 requires R 4.6.1", call. = FALSE)
}

required_packages <- c(
  "cowplot",
  "digest",
  "dplyr",
  "ggplot2",
  "LightLogR",
  "magick",
  "patchwork",
  "png",
  "readr",
  "scales",
  "svglite",
  "tibble"
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
    "Missing project package(s): ",
    paste(missing_packages, collapse = ", "),
    call. = FALSE
  )
}

evidence_rel <- paste0(
  "audit/hypotheses/H06/",
  "report018_order46_figure_label_refresh"
)
evidence_dir <- file.path(root, evidence_rel)
dir.create(evidence_dir, recursive = TRUE, showWarnings = FALSE)

sha256_file <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
}

file_bytes <- function(path) {
  unname(file.info(path)$size)
}

assert_true <- function(value, message) {
  if (!isTRUE(value)) {
    stop(message, call. = FALSE)
  }
  invisible(TRUE)
}

assert_file <- function(path, sha256, bytes) {
  absolute <- file.path(root, path)
  assert_true(file.exists(absolute), paste("Missing required file:", path))
  assert_true(
    identical(sha256_file(absolute), sha256),
    paste("SHA-256 drift:", path)
  )
  assert_true(
    identical(file_bytes(absolute), as.numeric(bytes)),
    paste("Byte-count drift:", path)
  )
  invisible(TRUE)
}

source_pins <- tibble::tribble(
  ~path,
  ~sha256,
  ~bytes,
  "artifacts/11_source_data/H06/H06_reader_primary_effects_figure.csv",
  "8a5482eb687a707ec193e2021233d954ca0ca21c322e75a9cd136042d0b51bfe",
  4668,
  paste0(
    "artifacts/11_source_data/H06/",
    "H06_stage3_site_specific_significance_screen_figure.csv"
  ),
  "8d15804a66a6589b6c6f408db147e65c0fa2a42f71cd32fb1dcd2acd6657d642",
  49970,
  "artifacts/11_source_data/H06/H06_reader_temporal_day_type_curves.csv",
  "838dc1485dd1c20caaa1693ec8d9969dc60619601a5fb11f9c1f1b350f7bfdab",
  132409,
  "artifacts/11_source_data/H06/H06_reader_temporal_day_type_ratios.csv",
  "789c3375b8e7d9db16862c0d084a9484d88123523a7524b1280bee5f13bfce03",
  89294,
  "artifacts/11_source_data/H06/H06_reader_temporal_day_type_support.csv",
  "597b72279bf499cecf63c95b11004b29dd388e1858f687ec6a21c0a1e95dfc60",
  2918,
  "artifacts/11_source_data/H06/H06_reader_temporal_activity_curves.csv",
  "c947918e14c3d83fc51e8b4c9216d3ad9e5a18002d3b5f3f877b3d30b18cfa6d",
  130390,
  "artifacts/11_source_data/H06/H06_reader_temporal_activity_ratios.csv",
  "1a12833bf7fa7aabdc91c23c1c28be26e685d3db4c7ddcea546720efafeb2b14",
  95026,
  "artifacts/11_source_data/H06/H06_reader_temporal_activity_support.csv",
  "cac58f8236192d20fbf52ad2c8bd9a2f2809293a841d686969d47275e665fd08",
  2870,
  "config/site_display_registry.csv",
  "3d669d459ecc27d3154bbb5ff5b0d64cb510805d486b45264443228c44a6d809",
  295
)

builder_pins <- tibble::tribble(
  ~path,
  ~sha256,
  ~bytes,
  "scripts/hypotheses/H06/build_h06_stage3_reader_displays.R",
  "b50bc1396f8d59647d7401849dd1cc23d6a988442fbc03cb2efdfe53d0b83c35",
  20870,
  "scripts/hypotheses/H06/build_h06_stage3_site_specific_screening.R",
  "9bde77139aff4b38009b8db70c0c152d516d31bf120fd86a9fc362140522378e",
  27541
)

export_pins <- tibble::tribble(
  ~family,
  ~path,
  ~sha256,
  ~bytes,
  ~width_mm,
  ~height_mm,
  "primary",
  "artifacts/10_figures/H06/H06_reader_primary_effects.png",
  "bc553dcb5dce302dc11a837d4a7a56e33cd35020b85bf0fadf8fe42603d331c9",
  159608,
  170,
  118,
  "primary",
  "artifacts/10_figures/H06/H06_reader_primary_effects.pdf",
  "efdf03a92d36645aceb842b4ef83bd4af95b724cd787e6ad589122ddd18984fa",
  6921,
  170,
  118,
  "primary",
  "artifacts/10_figures/H06/H06_reader_primary_effects.svg",
  "4b4c4734024ab9b9bb31ba7986cd5fbedbc0bf2be9b5bedc7ff7092de9b9724c",
  22665,
  170,
  118,
  "site",
  paste0(
    "artifacts/10_figures/H06/",
    "H06_stage3_site_specific_significance_screen.png"
  ),
  "c1c8c332a0fb75ceea95b125d0696f893db5b27503760fe7ae454715d5920dea",
  192301,
  170,
  135,
  "site",
  paste0(
    "artifacts/10_figures/H06/",
    "H06_stage3_site_specific_significance_screen.pdf"
  ),
  "3d8255dee326b9a38c327d39be3535b526179b47773402675473b0c82041620b",
  32639,
  170,
  135,
  "day_type",
  "artifacts/10_figures/H06/H06_reader_temporal_day_type.png",
  "df2322474720c7357dd5e45003bca0a85bc8afa1e5cd55d3e692c1b557214e92",
  367048,
  170,
  205,
  "day_type",
  "artifacts/10_figures/H06/H06_reader_temporal_day_type.pdf",
  "f66da1d75b59244c84cbd0e571e54d85657daccc52dcf6d70d0a93fc4209422a",
  16572,
  170,
  205,
  "day_type",
  "artifacts/10_figures/H06/H06_reader_temporal_day_type.svg",
  "5e14c8f45006cb15459720c4058bf184a4bacfc52dabfe07cf1eecbdc9664059",
  58033,
  170,
  205,
  "activity",
  "artifacts/10_figures/H06/H06_reader_temporal_activity.png",
  "01354dbbbb6156f8813a76a75762c82010d8c5fb0d70b5846a21725c0ed13e5c",
  368603,
  170,
  205,
  "activity",
  "artifacts/10_figures/H06/H06_reader_temporal_activity.pdf",
  "9e61383178a1f4e85aa8b4ed007891590c4513e6ccbc1780094e1900a7c50ceb",
  16661,
  170,
  205,
  "activity",
  "artifacts/10_figures/H06/H06_reader_temporal_activity.svg",
  "f09c9fd1fca5fb5670355da6f9189d791cbe27bb5299d17c91ff348ad8220c60",
  58545,
  170,
  205
)

manifest_rel <- "artifacts/12_manifests/H06/H06_stage3_artifacts.csv"
manifest_pre_sha <- "d77054228581a2700f80f0c571536ae2799a7e5ac0f6869d189767e0dfe3bb21"
manifest_pre_bytes <- 73277
refresh_rel <- paste0(
  "scripts/hypotheses/H06/",
  "refresh_h06_report018_reader_figure_labels.R"
)
test_rel <- paste0(
  "tests/hypotheses/H06/",
  "test_h06_report018_figure_label_refresh.R"
)

if (mode == "prepare") {
  for (index in seq_len(nrow(source_pins))) {
    assert_file(
      source_pins$path[[index]],
      source_pins$sha256[[index]],
      source_pins$bytes[[index]]
    )
  }
  for (index in seq_len(nrow(builder_pins))) {
    assert_file(
      builder_pins$path[[index]],
      builder_pins$sha256[[index]],
      builder_pins$bytes[[index]]
    )
  }
  for (index in seq_len(nrow(export_pins))) {
    assert_file(
      export_pins$path[[index]],
      export_pins$sha256[[index]],
      export_pins$bytes[[index]]
    )
  }
  assert_file(manifest_rel, manifest_pre_sha, manifest_pre_bytes)
}

h06_reader_theme <- function() {
  cowplot::theme_cowplot(font_size = 10.5) +
    ggplot2::theme(
      axis.text = ggplot2::element_text(size = 8.5, colour = "black"),
      axis.title = ggplot2::element_text(size = 9.5),
      strip.background = ggplot2::element_rect(fill = "#D9D9D9", colour = NA),
      strip.text = ggplot2::element_text(size = 9.5, face = "bold"),
      plot.title = ggplot2::element_text(size = 10.5, face = "bold"),
      plot.subtitle = ggplot2::element_text(size = 8.5),
      plot.caption = ggplot2::element_text(
        size = 7.5,
        hjust = 0,
        lineheight = 1.03
      ),
      plot.tag = ggplot2::element_text(size = 10.5, face = "bold"),
      legend.text = ggplot2::element_text(size = 8.5),
      legend.title = ggplot2::element_text(size = 8.5),
      panel.grid.major.y = ggplot2::element_line(
        colour = "#E3E6E8",
        linewidth = 0.35
      ),
      panel.grid.major.x = ggplot2::element_blank(),
      panel.grid.minor = ggplot2::element_blank(),
      plot.title.position = "plot",
      plot.caption.position = "plot"
    )
}

h06_wrap_text <- function(text, width = 95L) {
  lines <- strsplit(text, "\n", fixed = TRUE)[[1L]]
  paste(
    vapply(
      lines,
      function(line) paste(strwrap(line, width = width), collapse = "\n"),
      character(1)
    ),
    collapse = "\n"
  )
}

read_frozen_csv <- function(path) {
  readr::read_csv(file.path(root, path), show_col_types = FALSE, na = "")
}

build_primary_plot <- function(data, repaired = FALSE) {
  scenario_order <- c(
    "Primary near-eye",
    "Chest (all available)",
    "Near-eye (paired days)",
    "Chest (paired days)",
    "Gap-timing-unaware near-eye",
    "Gap-timing-unaware chest"
  )
  data <- data |>
    dplyr::mutate(
      effect_display = factor(
        .data$effect_display,
        levels = c(
          "Free day versus\nwork day",
          "Active versus\nsedentary",
          "Previous sleep\n(per additional hour)"
        )
      ),
      scenario = factor(.data$scenario, levels = rev(scenario_order)),
      placement = factor(.data$placement, levels = c("Near-eye", "Chest"))
    )
  title <- if (repaired) {
    "Primary and contextual mean hourly melEDI ratios"
  } else {
    "Primary and contextual expected-hour melEDI ratios"
  }
  x_title <- if (repaired) {
    "Ratio of estimated mean hourly melEDI (log scale)"
  } else {
    "Ratio of expected supported-hour melEDI (log scale)"
  }

  ggplot2::ggplot(
    data,
    ggplot2::aes(
      x = .data$ratio,
      y = .data$scenario,
      xmin = .data$conf_low,
      xmax = .data$conf_high,
      colour = .data$placement,
      shape = .data$placement
    )
  ) +
    ggplot2::geom_vline(
      xintercept = 1,
      colour = "grey45",
      linetype = "dashed",
      linewidth = 0.55
    ) +
    ggplot2::geom_errorbar(orientation = "y", width = 0, linewidth = 0.65) +
    ggplot2::geom_point(size = 2.8) +
    ggplot2::facet_wrap(ggplot2::vars(.data$effect_display), ncol = 3) +
    ggplot2::scale_x_log10(
      breaks = c(0.5, 0.75, 1, 1.5, 2, 3),
      labels = scales::label_number(accuracy = 0.01)
    ) +
    ggplot2::scale_colour_manual(
      values = c("Near-eye" = "#0072B2", "Chest" = "#D55E00")
    ) +
    ggplot2::scale_shape_manual(values = c("Near-eye" = 17, "Chest" = 16)) +
    ggplot2::labs(
      title = title,
      subtitle = paste(
        "Dashed line: null ratio 1; points and bars: estimates and",
        "participant-cluster HC3 95% confidence intervals"
      ),
      x = x_title,
      y = NULL,
      colour = "Placement",
      shape = "Placement",
      caption = h06_wrap_text(paste0(
        "The primary near-eye row is the prespecified analysis; chest, paired-day, and gap-timing-unaware rows provide placement and data context.\n",
        "Only primary and gap-sensitivity near-eye estimates carry their declared multiplicity adjustment in the report table; no significance encoding is applied here."
      ))
    ) +
    h06_reader_theme() +
    ggplot2::theme(
      legend.position = "top",
      axis.text.y = ggplot2::element_text(size = 8),
      panel.spacing = grid::unit(1.1, "lines"),
      plot.margin = ggplot2::margin(t = 7, r = 8, b = 10, l = 7)
    )
}

build_site_plot <- function(data, site_registry, repaired = FALSE) {
  data <- data |>
    dplyr::mutate(
      predictor_display = factor(
        .data$predictor_display,
        levels = c(
          "Free day versus\nwork day",
          "Active versus\nsedentary",
          "Previous sleep\n(per additional hour)"
        )
      ),
      display_name = factor(
        .data$display_name,
        levels = rev(site_registry$display_name)
      )
    )
  interaction_references <- data |>
    dplyr::distinct(
      .data$predictor_display,
      .data$interaction_equal_site_ratio
    )
  if (repaired) {
    title <- "Site-specific mean hourly near-eye melEDI ratios"
    subtitle <- paste(
      "Dashed line: site-average estimate from this model; filled points:",
      "retained after separate nine-site FDR adjustments; open points:",
      "not retained"
    )
    caption <- paste0(
      "Bars are participant-cluster HC3 pointwise 95% confidence intervals from the current\n",
      "predictor-by-site interaction model. The grey line at 1 is the site-specific association null.\n",
      "The dashed line is the site-average geometric mean of the nine ratios in this same model.\n",
      "Filled points pass a separate nine-site FDR adjustment within that predictor; this does\n",
      "not test deviation from the site-average estimate or the overall predictor-by-site interaction."
    )
  } else {
    title <- "Site-specific expected-hour near-eye melEDI ratios"
    subtitle <- paste(
      "Dashed line: equal-site average from this model; filled points:",
      "retained after separate nine-site BH adjustments; open points:",
      "not retained"
    )
    caption <- paste0(
      "Bars are participant-cluster HC3 pointwise 95% confidence intervals from the frozen\n",
      "full site-interaction model. The grey line at 1 is the site-specific association null.\n",
      "The dashed line is the equal-site geometric mean of the nine ratios in this same model.\n",
      "Filled points pass a separate nine-site BH adjustment within that predictor; this does\n",
      "not test deviation from the equal-site average or between-site heterogeneity."
    )
  }

  ggplot2::ggplot(
    data,
    ggplot2::aes(
      x = .data$estimate_ratio,
      y = .data$display_name,
      xmin = .data$conf_low_ratio,
      xmax = .data$conf_high_ratio,
      colour = .data$site
    )
  ) +
    ggplot2::geom_vline(xintercept = 1, colour = "grey70", linewidth = 0.45) +
    ggplot2::geom_vline(
      data = interaction_references,
      ggplot2::aes(xintercept = .data$interaction_equal_site_ratio),
      inherit.aes = FALSE,
      colour = "grey30",
      linetype = "dashed",
      linewidth = 0.65
    ) +
    ggplot2::geom_errorbar(orientation = "y", width = 0, linewidth = 0.6) +
    ggplot2::geom_point(
      data = dplyr::filter(data, !.data$adjusted_significant_0_05),
      shape = 21,
      fill = "white",
      size = 3,
      stroke = 0.8
    ) +
    ggplot2::geom_point(
      data = dplyr::filter(data, .data$adjusted_significant_0_05),
      ggplot2::aes(fill = .data$site),
      shape = 21,
      size = 3.4,
      stroke = 0.7
    ) +
    ggplot2::facet_wrap(~predictor_display, ncol = 3) +
    ggplot2::scale_x_log10(
      breaks = c(0.25, 0.5, 1, 2, 4, 8),
      labels = scales::label_number(accuracy = 0.01)
    ) +
    ggplot2::scale_colour_manual(
      values = stats::setNames(site_registry$color_hex, site_registry$site),
      guide = "none"
    ) +
    ggplot2::scale_fill_manual(
      values = stats::setNames(site_registry$color_hex, site_registry$site),
      guide = "none"
    ) +
    ggplot2::labs(
      title = title,
      subtitle = subtitle,
      x = "Site-specific ratio (log scale)",
      y = NULL,
      caption = caption
    ) +
    cowplot::theme_cowplot(font_size = 10.5) +
    ggplot2::theme(
      axis.text = ggplot2::element_text(size = 8, colour = "black"),
      axis.title = ggplot2::element_text(size = 9),
      strip.background = ggplot2::element_rect(fill = "#D9D9D9", colour = NA),
      strip.text = ggplot2::element_text(size = 9, face = "bold"),
      plot.title = ggplot2::element_text(size = 10.5, face = "bold"),
      plot.subtitle = ggplot2::element_text(size = 8.5),
      plot.caption = ggplot2::element_text(
        size = 7.5,
        hjust = 0,
        lineheight = 1.03,
        margin = ggplot2::margin(t = 8, b = 4)
      ),
      panel.grid.major.y = ggplot2::element_line(
        colour = "#E3E6E8",
        linewidth = 0.35
      ),
      panel.grid.major.x = ggplot2::element_blank(),
      panel.grid.minor = ggplot2::element_blank(),
      panel.spacing = grid::unit(1.1, "lines"),
      plot.title.position = "plot",
      plot.caption.position = "plot",
      plot.margin = ggplot2::margin(t = 7, r = 8, b = 10, l = 7)
    )
}

build_temporal_plot <- function(
  curves,
  ratios,
  support,
  group_column,
  group_levels,
  colours,
  linetypes,
  title,
  ratio_title,
  legend_title,
  standardization_text,
  repaired = FALSE
) {
  curves <- curves |>
    dplyr::mutate(
      display_group = factor(.data$display_group, levels = group_levels),
      integer_hour = as.logical(.data$integer_hour)
    )
  ratios <- ratios |>
    dplyr::mutate(
      integer_hour = as.logical(.data$integer_hour),
      pointwise_ci_excludes_one = as.logical(
        .data$pointwise_ci_excludes_one
      )
    )
  support <- support |>
    dplyr::mutate(
      display_group = factor(.data$display_group, levels = group_levels)
    )
  assert_true(
    identical(as.character(unique(curves[[group_column]])), group_levels),
    paste("Unexpected temporal group order for", group_column)
  )
  contrast_colour <- unname(colours[[group_levels[[2L]]]])

  curve_plot <- ggplot2::ggplot(
    curves,
    ggplot2::aes(
      x = .data$clock_hour,
      y = .data$expected_melEDI_lx,
      colour = .data$display_group,
      fill = .data$display_group,
      linetype = .data$display_group
    )
  ) +
    ggplot2::geom_ribbon(
      ggplot2::aes(
        ymin = .data$expected_low_melEDI_lx,
        ymax = .data$expected_high_melEDI_lx
      ),
      alpha = 0.18,
      colour = NA
    ) +
    ggplot2::geom_line(linewidth = 0.9) +
    ggplot2::geom_point(
      data = dplyr::filter(curves, .data$integer_hour),
      shape = 21,
      size = 1.8,
      stroke = 0.5
    ) +
    ggplot2::scale_x_continuous(
      breaks = c(0, 6, 12, 18, 24),
      limits = c(0, 24),
      expand = ggplot2::expansion(mult = c(0, 0.01))
    ) +
    ggplot2::scale_y_continuous(
      trans = LightLogR::symlog_trans(base = 10, thr = 1, scale = 1),
      breaks = c(0, 1, 10, 250, 1000),
      labels = scales::label_number(big.mark = ",", accuracy = 1),
      limits = c(0, NA),
      expand = ggplot2::expansion(mult = c(0, 0.04))
    ) +
    ggplot2::scale_colour_manual(values = colours, name = legend_title) +
    ggplot2::scale_fill_manual(values = colours, guide = "none") +
    ggplot2::scale_linetype_manual(values = linetypes, name = legend_title) +
    ggplot2::labs(
      title = paste0("A  ", title),
      subtitle = paste(
        "Overlaid curves and pointwise 95% bands; circles mark integer",
        "hours with support in all nine sites"
      ),
      x = NULL,
      y = if (repaired) "Estimated melEDI (lx)" else "Expected melEDI (lx)"
    ) +
    h06_reader_theme() +
    ggplot2::theme(
      legend.position = "top",
      legend.justification = "left",
      legend.box.just = "left"
    )

  ratio_plot <- ggplot2::ggplot(
    ratios,
    ggplot2::aes(x = .data$clock_hour, y = .data$expected_melEDI_ratio)
  ) +
    ggplot2::geom_hline(
      yintercept = 1,
      colour = "grey35",
      linetype = "dashed",
      linewidth = 0.6
    ) +
    ggplot2::geom_ribbon(
      ggplot2::aes(
        ymin = .data$pointwise_low_ratio,
        ymax = .data$pointwise_high_ratio
      ),
      fill = contrast_colour,
      alpha = 0.22,
      colour = NA
    ) +
    ggplot2::geom_line(colour = contrast_colour, linewidth = 0.9) +
    ggplot2::geom_point(
      data = dplyr::filter(ratios, .data$integer_hour),
      ggplot2::aes(fill = .data$pointwise_ci_excludes_one),
      colour = contrast_colour,
      shape = 21,
      size = 1.8,
      stroke = 0.5
    ) +
    ggplot2::scale_fill_manual(
      values = c(`TRUE` = contrast_colour, `FALSE` = "white"),
      guide = "none"
    ) +
    ggplot2::scale_x_continuous(
      breaks = c(0, 6, 12, 18, 24),
      limits = c(0, 24),
      expand = ggplot2::expansion(mult = c(0, 0.01))
    ) +
    ggplot2::scale_y_log10(
      breaks = c(0.125, 0.25, 0.5, 1, 2, 4, 8),
      labels = scales::label_number(accuracy = 0.01)
    ) +
    ggplot2::labs(
      title = paste0("B  ", ratio_title),
      subtitle = paste(
        "Filled point: pointwise CI excludes 1; hollow: it includes 1;",
        "no simultaneous or whole-curve test"
      ),
      x = NULL,
      y = if (repaired) "Estimated melEDI ratio" else "Expected melEDI ratio"
    ) +
    h06_reader_theme()

  support_plot <- ggplot2::ggplot(
    support,
    ggplot2::aes(
      x = .data$clock_hour,
      y = .data$participant_hours,
      fill = .data$display_group
    )
  ) +
    ggplot2::geom_col(width = 0.84) +
    ggplot2::facet_wrap(ggplot2::vars(.data$display_group), ncol = 2) +
    ggplot2::scale_x_continuous(
      breaks = c(0, 6, 12, 18, 24),
      limits = c(-0.5, 24),
      expand = ggplot2::expansion(mult = c(0, 0))
    ) +
    ggplot2::scale_fill_manual(values = colours, guide = "none") +
    ggplot2::labs(
      title = "C  Available participant-hours by local time",
      subtitle = "Bars show the supported fitted rows at each integer hour",
      x = "Local clock hour",
      y = "Participant-hours"
    ) +
    h06_reader_theme()

  old_footer <- h06_wrap_text(paste0(
    "The accepted exploratory two-part model multiplies binomial-logit occurrence by Gamma-log positive magnitude. ",
    standardization_text,
    "\n",
    "Participant and participant-day random-effect smooths are omitted from displayed curves. Smoothing parameters are fixed and occurrence-magnitude cross-component covariance is set to zero.\n",
    "The ratio panel is a complete response-scale paired contrast. Filled points mark integer hours whose pointwise interval excludes 1; hollow points mark intervals that include 1. This encoding is exploratory and is not a multiplicity-controlled or simultaneous whole-curve test. The melEDI transformation in panel A is display-only."
  ))
  new_footer <- h06_wrap_text(paste0(
    "Exploratory nonlinear two-part generalized additive model (GAM) display. ",
    standardization_text,
    "\n",
    "Displayed curves omit participant and participant-day random effects. Bands and ratio intervals are approximate pointwise 95% intervals with fixed smoothing parameters; uncertainty does not include covariance between the occurrence and positive-magnitude components.\n",
    "Filled and hollow points distinguish intervals that exclude and include 1. These intervals apply to individual displayed hours, not a simultaneous or multiplicity-controlled whole-curve test. The panel-A transformation is display-only."
  ))

  patchwork::wrap_plots(
    curve_plot,
    ratio_plot,
    support_plot,
    ncol = 1,
    heights = c(1.15, 1, 0.75)
  ) +
    patchwork::plot_annotation(
      caption = if (repaired) new_footer else old_footer,
      theme = h06_reader_theme() +
        ggplot2::theme(
          plot.caption = ggplot2::element_text(
            size = 7.5,
            hjust = 0,
            lineheight = 1.03,
            margin = ggplot2::margin(t = 7, b = 4)
          ),
          plot.margin = ggplot2::margin(t = 6, r = 7, b = 8, l = 7)
        )
    )
}

export_plot <- function(plot, path, width_mm, height_mm, cairo_pdf = FALSE) {
  extension <- tools::file_ext(path)
  arguments <- list(
    filename = path,
    plot = plot,
    width = width_mm / 25.4,
    height = height_mm / 25.4,
    units = "in",
    dpi = 320,
    bg = "white",
    limitsize = FALSE
  )
  if (identical(extension, "pdf") && cairo_pdf) {
    arguments$device <- grDevices::cairo_pdf
  }
  do.call(ggplot2::ggsave, arguments)
  invisible(path)
}

render_pdf_png <- function(pdf_path, png_path) {
  prefix <- sub("[.]png$", "", png_path)
  result <- system2(
    "/opt/homebrew/bin/pdftoppm",
    c("-r", "320", "-png", "-singlefile", pdf_path, prefix),
    stdout = TRUE,
    stderr = TRUE
  )
  assert_true(
    identical(attr(result, "status"), NULL) ||
      identical(attr(result, "status"), 0L),
    paste("PDF rasterization failed:", pdf_path)
  )
  assert_true(
    file.exists(png_path),
    paste("Missing rendered PDF PNG:", png_path)
  )
  invisible(png_path)
}

extract_pdf_text <- function(pdf_path, text_path) {
  result <- system2(
    "/opt/homebrew/bin/pdftotext",
    c("-layout", pdf_path, text_path),
    stdout = TRUE,
    stderr = TRUE
  )
  assert_true(
    identical(attr(result, "status"), NULL) ||
      identical(attr(result, "status"), 0L),
    paste("PDF text extraction failed:", pdf_path)
  )
  paste(readLines(text_path, warn = FALSE), collapse = "\n")
}

pdf_page_size <- function(pdf_path) {
  output <- system2(
    "/opt/homebrew/bin/pdfinfo",
    pdf_path,
    stdout = TRUE,
    stderr = TRUE
  )
  page_line <- output[grepl("^Page size:", output)]
  assert_true(
    length(page_line) == 1L,
    paste("Missing PDF page size:", pdf_path)
  )
  sub(
    "[[:space:]]+[(].*$",
    "",
    trimws(sub("^Page size:[[:space:]]*", "", page_line))
  )
}

normalized_svg_structure <- function(path) {
  text <- paste(readLines(path, warn = FALSE), collapse = "\n")
  text <- gsub("(<text[^>]*>).*?(</text>)", "\\1__TEXT__\\2", text)
  text <- gsub("<title>.*?</title>", "<title>__TEXT__</title>", text)
  text
}

png_dimensions <- function(path) {
  info <- magick::image_info(magick::image_read(path))
  c(width = info$width[[1L]], height = info$height[[1L]])
}

png_difference_summary <- function(old_path, new_path, family) {
  old <- png::readPNG(old_path)
  new <- png::readPNG(new_path)
  assert_true(
    identical(dim(old), dim(new)),
    paste("PNG dimension drift:", family)
  )
  changed <- apply(abs(old - new) > (1 / 255), c(1, 2), any)
  height <- nrow(changed)
  width <- ncol(changed)
  allowed <- matrix(FALSE, nrow = height, ncol = width)
  mark <- function(x1, x2, y1, y2) {
    x1 <- max(1L, as.integer(x1))
    x2 <- min(width, as.integer(x2))
    y1 <- max(1L, as.integer(y1))
    y2 <- min(height, as.integer(y2))
    allowed[y1:y2, x1:x2] <<- TRUE
  }
  if (identical(family, "primary")) {
    mark(1, width, 1, 175)
    mark(1, width, 1160, 1340)
  } else if (identical(family, "site")) {
    mark(1, width, 1, 220)
    mark(1, width, 1370, height)
  } else {
    mark(1, width, 1, 205)
    mark(1, 240, 205, 930)
    mark(1, 240, 900, 1650)
    mark(1, width, 2050, height)
  }
  unexplained <- changed & !allowed
  tibble::tibble(
    family = family,
    changed_pixels = sum(changed),
    explained_pixels = sum(changed & allowed),
    unexplained_pixels = sum(unexplained),
    data_region_identical = !any(unexplained),
    width_px = width,
    height_px = height
  )
}

create_visual_views <- function(candidate_png, family, width_mm, height_mm) {
  image <- magick::image_read(candidate_png)
  original <- file.path(evidence_dir, paste0(family, "_original.png"))
  width_708 <- file.path(evidence_dir, paste0(family, "_708px.png"))
  width_200 <- file.path(evidence_dir, paste0(family, "_200_percent.png"))
  a4 <- file.path(evidence_dir, paste0(family, "_170mm_A4.png"))
  magick::image_write(image, original, format = "png")
  magick::image_write(
    magick::image_resize(image, "708x"),
    width_708,
    format = "png"
  )
  magick::image_write(
    magick::image_resize(image, "1416x"),
    width_200,
    format = "png"
  )
  a4_canvas <- magick::image_blank(width = 1240, height = 1754, color = "white")
  final_width <- 1004L
  final_height <- as.integer(round(final_width * height_mm / width_mm))
  final_image <- magick::image_resize(
    image,
    paste0(final_width, "x", final_height, "!")
  )
  x_offset <- as.integer((1240 - final_width) / 2)
  y_offset <- as.integer((1754 - final_height) / 2)
  a4_canvas <- magick::image_composite(
    a4_canvas,
    final_image,
    offset = paste0("+", x_offset, "+", y_offset)
  )
  magick::image_write(a4_canvas, a4, format = "png")
  c(original = original, width_708 = width_708, width_200 = width_200, a4 = a4)
}

write_authorized_transitions <- function() {
  transitions <- tibble::tribble(
    ~family,
    ~location,
    ~old_label,
    ~new_label,
    "primary",
    "title",
    "Primary and contextual expected-hour melEDI ratios",
    "Primary and contextual mean hourly melEDI ratios",
    "primary",
    "x_axis",
    "Ratio of expected supported-hour melEDI (log scale)",
    "Ratio of estimated mean hourly melEDI (log scale)",
    "site",
    "title",
    "Site-specific expected-hour near-eye melEDI ratios",
    "Site-specific mean hourly near-eye melEDI ratios",
    "site",
    "subtitle",
    "equal-site average; BH adjustments",
    "site-average estimate; FDR adjustments",
    "site",
    "caption",
    "frozen full site-interaction model; equal-site; BH; heterogeneity",
    "current predictor-by-site interaction model; site-average; FDR; overall interaction",
    "day_type",
    "panel_A_title",
    "Expected near-eye melEDI by day type and local time",
    "Estimated near-eye melEDI by day type and local time",
    "activity",
    "panel_A_title",
    "Expected near-eye melEDI by activity status and local time",
    "Estimated near-eye melEDI by activity status and local time",
    "day_type",
    "panel_A_y",
    "Expected melEDI (lx)",
    "Estimated melEDI (lx)",
    "activity",
    "panel_A_y",
    "Expected melEDI (lx)",
    "Estimated melEDI (lx)",
    "day_type",
    "panel_B_y",
    "Expected melEDI ratio",
    "Estimated melEDI ratio",
    "activity",
    "panel_B_y",
    "Expected melEDI ratio",
    "Estimated melEDI ratio",
    "day_type",
    "footer",
    "accepted exploratory two-part model technical footer",
    "three-paragraph exploratory nonlinear GAM display footer",
    "activity",
    "footer",
    "accepted exploratory two-part model technical footer",
    "three-paragraph exploratory nonlinear GAM display footer"
  )
  readr::write_csv(
    transitions,
    file.path(evidence_dir, "authorized_label_transitions.csv"),
    na = ""
  )
}

write_package_versions <- function() {
  versions <- tibble::tibble(
    package = required_packages,
    version = vapply(
      required_packages,
      function(package) as.character(utils::packageVersion(package)),
      character(1)
    ),
    r_version = as.character(getRversion())
  )
  readr::write_csv(
    versions,
    file.path(evidence_dir, "package_versions.csv"),
    na = ""
  )
}

mutable_existing <- c(builder_pins$path, export_pins$path, manifest_rel)

collect_protected_paths <- function() {
  manifest <- readr::read_csv(
    file.path(root, manifest_rel),
    show_col_types = FALSE,
    col_types = readr::cols(.default = readr::col_character())
  )
  dispatch <- readr::read_csv(
    file.path(
      root,
      "audit/report_harmonization/report018_h06_order46_dispatch_manifest.csv"
    ),
    show_col_types = FALSE,
    col_types = readr::cols(.default = readr::col_character())
  )
  dispatch <- dplyr::filter(
    dispatch,
    .data$path != "audit/report_harmonization/coordination_matrix.csv"
  )
  extra_roots <- c(
    "_build",
    "audit/hypotheses/H06",
    "audit/hypotheses/H06_daily",
    "artifacts/07_models/H06_daily",
    "artifacts/08_diagnostics/H06_daily",
    "artifacts/09_tables/H06_daily",
    "artifacts/10_figures/H06_daily",
    "artifacts/11_source_data/H06_daily",
    "artifacts/12_manifests/H06_daily",
    "notebooks/hypotheses",
    "scripts/hypotheses/H06_daily",
    "tests/hypotheses/H06_daily"
  )
  extra <- unlist(lapply(extra_roots, function(relative) {
    absolute <- file.path(root, relative)
    if (!dir.exists(absolute)) {
      return(character())
    }
    files <- list.files(absolute, recursive = TRUE, full.names = TRUE)
    files[file.exists(files) & !dir.exists(files)]
  }))
  extra <- substring(extra, nchar(root) + 2L)
  daily_notebooks <- extra[
    grepl("^notebooks/hypotheses/H06_daily([.]|/)", extra)
  ]
  historical_h06 <- extra[
    grepl("^audit/hypotheses/H06/", extra) &
      !grepl(paste0("^", evidence_rel, "/"), extra)
  ]
  build_paths <- extra[grepl("^_build/", extra)]
  unique(sort(setdiff(
    c(
      manifest$path,
      dispatch$path,
      daily_notebooks,
      historical_h06,
      build_paths
    ),
    c(
      mutable_existing,
      refresh_rel,
      test_rel,
      paste0(evidence_rel, "/protected_inventory.csv")
    )
  )))
}

write_protected_inventory <- function() {
  paths <- collect_protected_paths()
  absolute <- file.path(root, paths)
  assert_true(
    all(file.exists(absolute)),
    "Protected inventory contains a missing file"
  )
  inventory <- tibble::tibble(
    path = paths,
    sha256 = unname(vapply(absolute, sha256_file, character(1))),
    bytes = unname(vapply(absolute, file_bytes, numeric(1)))
  )
  readr::write_csv(
    inventory,
    file.path(evidence_dir, "protected_inventory.csv"),
    na = ""
  )
  invisible(inventory)
}

verify_protected_inventory <- function() {
  inventory <- readr::read_csv(
    file.path(evidence_dir, "protected_inventory.csv"),
    show_col_types = FALSE,
    col_types = readr::cols(
      path = readr::col_character(),
      sha256 = readr::col_character(),
      bytes = readr::col_double()
    )
  )
  absolute <- file.path(root, inventory$path)
  present <- file.exists(absolute)
  actual_sha <- rep(NA_character_, nrow(inventory))
  actual_bytes <- rep(NA_real_, nrow(inventory))
  actual_sha[present] <- vapply(absolute[present], sha256_file, character(1))
  actual_bytes[present] <- vapply(absolute[present], file_bytes, numeric(1))
  assert_true(
    all(present) &&
      identical(unname(actual_sha), inventory$sha256) &&
      identical(unname(actual_bytes), inventory$bytes),
    "A protected file changed after candidate preparation"
  )
  invisible(inventory)
}

read_plot_sources <- function() {
  list(
    primary = read_frozen_csv(source_pins$path[[1L]]),
    site = read_frozen_csv(source_pins$path[[2L]]),
    day_curves = read_frozen_csv(source_pins$path[[3L]]),
    day_ratios = read_frozen_csv(source_pins$path[[4L]]),
    day_support = read_frozen_csv(source_pins$path[[5L]]),
    activity_curves = read_frozen_csv(source_pins$path[[6L]]),
    activity_ratios = read_frozen_csv(source_pins$path[[7L]]),
    activity_support = read_frozen_csv(source_pins$path[[8L]]),
    site_registry = read_frozen_csv(source_pins$path[[9L]]) |>
      dplyr::arrange(.data$display_order)
  )
}

build_plot_set <- function(sources, repaired = FALSE) {
  day_title <- if (repaired) {
    "Estimated near-eye melEDI by day type and local time"
  } else {
    "Expected near-eye melEDI by day type and local time"
  }
  activity_title <- if (repaired) {
    "Estimated near-eye melEDI by activity status and local time"
  } else {
    "Expected near-eye melEDI by activity status and local time"
  }
  list(
    primary = build_primary_plot(sources$primary, repaired = repaired),
    site = build_site_plot(
      sources$site,
      sources$site_registry,
      repaired = repaired
    ),
    day_type = build_temporal_plot(
      curves = sources$day_curves,
      ratios = sources$day_ratios,
      support = sources$day_support,
      group_column = "work_free_day",
      group_levels = c("Work day", "Free day"),
      colours = c("Work day" = "#0072B2", "Free day" = "#E69F00"),
      linetypes = c("Work day" = "solid", "Free day" = "22"),
      title = day_title,
      ratio_title = "Free day relative to work day across local time",
      legend_title = "Day type",
      standardization_text = paste(
        "Curves give sedentary and active status equal weight and standardize",
        "equally across the nine study sites."
      ),
      repaired = repaired
    ),
    activity = build_temporal_plot(
      curves = sources$activity_curves,
      ratios = sources$activity_ratios,
      support = sources$activity_support,
      group_column = "activity_status",
      group_levels = c("Sedentary", "Active"),
      colours = c("Sedentary" = "#009E73", "Active" = "#CC79A7"),
      linetypes = c("Sedentary" = "solid", "Active" = "22"),
      title = activity_title,
      ratio_title = "Active relative to sedentary across local time",
      legend_title = "Activity status",
      standardization_text = paste(
        "Curves give work and free days equal weight and standardize equally",
        "across the nine study sites."
      ),
      repaired = repaired
    )
  )
}

family_specs <- tibble::tribble(
  ~family,
  ~stem,
  ~width_mm,
  ~height_mm,
  ~extensions,
  "primary",
  "H06_reader_primary_effects",
  170,
  118,
  "png;pdf;svg",
  "site",
  "H06_stage3_site_specific_significance_screen",
  170,
  135,
  "png;pdf",
  "day_type",
  "H06_reader_temporal_day_type",
  170,
  205,
  "png;pdf;svg",
  "activity",
  "H06_reader_temporal_activity",
  170,
  205,
  "png;pdf;svg"
)

export_plot_set <- function(plots, target_dir, prefix) {
  paths <- list()
  for (index in seq_len(nrow(family_specs))) {
    family <- family_specs$family[[index]]
    extensions <- strsplit(
      family_specs$extensions[[index]],
      ";",
      fixed = TRUE
    )[[1L]]
    for (extension in extensions) {
      path <- file.path(
        target_dir,
        paste0(prefix, "_", family_specs$stem[[index]], ".", extension)
      )
      export_plot(
        plots[[family]],
        path,
        family_specs$width_mm[[index]],
        family_specs$height_mm[[index]],
        cairo_pdf = identical(family, "site")
      )
      paths[[paste(family, extension, sep = "_")]] <- path
    }
  }
  paths
}

plot_build_signature <- function(plot) {
  built <- ggplot2::ggplot_build(plot)
  list(
    layer_count = length(built$data),
    layer_data_sha256 = digest::digest(built$data, algo = "sha256"),
    coordinate_class = class(built$layout$coord)[[1L]],
    panel_count = length(built$layout$panel_params)
  )
}

expected_png_dimensions <- function(family) {
  if (identical(family, "primary")) {
    return(c(width = 2141, height = 1486))
  }
  if (identical(family, "site")) {
    return(c(width = 2141, height = 1700))
  }
  c(width = 2141, height = 2582)
}

candidate_visible_text_requirements <- list(
  primary = c(
    "Primary and contextual mean hourly melEDI ratios",
    "Ratio of estimated mean hourly melEDI (log scale)"
  ),
  site = c(
    "Site-specific mean hourly near-eye melEDI ratios",
    "site-average estimate from this model",
    "nine-site FDR adjustments",
    "current predictor-by-site interaction model",
    "overall predictor-by-site interaction"
  ),
  day_type = c(
    "Estimated near-eye melEDI by day type and local time",
    "Estimated melEDI (lx)",
    "Estimated melEDI ratio",
    "Exploratory nonlinear two-part generalized additive model (GAM) display",
    "individual displayed hours"
  ),
  activity = c(
    "Estimated near-eye melEDI by activity status and local time",
    "Estimated melEDI (lx)",
    "Estimated melEDI ratio",
    "Exploratory nonlinear two-part generalized additive model (GAM) display",
    "individual displayed hours"
  )
)

normalize_visible_text <- function(text) {
  trimws(gsub("[[:space:]]+", " ", text))
}

validate_plot_objects <- function(old_plots, new_plots) {
  checks <- lapply(names(old_plots), function(family) {
    old_signature <- plot_build_signature(old_plots[[family]])
    new_signature <- plot_build_signature(new_plots[[family]])
    tibble::tibble(
      family = family,
      check = c(
        "mapped_layer_data",
        "layer_count",
        "coordinate_system",
        "panel_count"
      ),
      status = c(
        identical(
          old_signature$layer_data_sha256,
          new_signature$layer_data_sha256
        ),
        identical(old_signature$layer_count, new_signature$layer_count),
        identical(
          old_signature$coordinate_class,
          new_signature$coordinate_class
        ),
        identical(old_signature$panel_count, new_signature$panel_count)
      ),
      detail = c(
        old_signature$layer_data_sha256,
        as.character(old_signature$layer_count),
        old_signature$coordinate_class,
        as.character(old_signature$panel_count)
      )
    )
  })
  dplyr::bind_rows(checks)
}

validate_baselines_and_candidates <- function(
  old_plots,
  new_plots,
  baselines,
  candidates,
  temporary_dir
) {
  rows <- list()
  add_row <- function(family, format, check, status, detail = "") {
    rows[[length(rows) + 1L]] <<- tibble::tibble(
      family = family,
      format = format,
      check = check,
      status = as.logical(status),
      detail = as.character(detail)
    )
  }
  structure_checks <- validate_plot_objects(old_plots, new_plots)
  for (index in seq_len(nrow(structure_checks))) {
    add_row(
      structure_checks$family[[index]],
      "plot_object",
      structure_checks$check[[index]],
      structure_checks$status[[index]],
      structure_checks$detail[[index]]
    )
  }

  for (index in seq_len(nrow(export_pins))) {
    family <- export_pins$family[[index]]
    extension <- tools::file_ext(export_pins$path[[index]])
    key <- paste(family, extension, sep = "_")
    sealed <- file.path(root, export_pins$path[[index]])
    baseline <- baselines[[key]]
    candidate <- candidates[[key]]
    if (extension %in% c("png", "svg")) {
      add_row(
        family,
        extension,
        "old_label_baseline_exact_bytes",
        identical(sha256_file(baseline), sha256_file(sealed)),
        sha256_file(baseline)
      )
    }
    if (identical(extension, "png")) {
      expected_dimensions <- expected_png_dimensions(family)
      add_row(
        family,
        extension,
        "candidate_dimensions",
        identical(png_dimensions(candidate), expected_dimensions),
        paste(png_dimensions(candidate), collapse = "x")
      )
      difference <- png_difference_summary(baseline, candidate, family)
      add_row(
        family,
        extension,
        "authorized_pixel_regions_only",
        difference$data_region_identical[[1L]],
        paste0(
          "changed=",
          difference$changed_pixels[[1L]],
          "; unexplained=",
          difference$unexplained_pixels[[1L]]
        )
      )
      readr::write_csv(
        difference,
        file.path(temporary_dir, paste0(family, "_png_difference.csv")),
        na = ""
      )
    }
    if (identical(extension, "svg")) {
      add_row(
        family,
        extension,
        "normalized_structure",
        identical(
          normalized_svg_structure(baseline),
          normalized_svg_structure(candidate)
        ),
        "All non-text SVG structure retained"
      )
      candidate_text <- normalize_visible_text(
        paste(readLines(candidate, warn = FALSE), collapse = " ")
      )
      required <- candidate_visible_text_requirements[[family]]
      add_row(
        family,
        extension,
        "required_visible_labels",
        all(vapply(
          required,
          grepl,
          logical(1),
          x = candidate_text,
          fixed = TRUE
        )),
        paste(required, collapse = " | ")
      )
    }
    if (identical(extension, "pdf")) {
      baseline_png <- file.path(
        temporary_dir,
        paste0("baseline_rendered_", family, ".png")
      )
      sealed_png <- file.path(
        temporary_dir,
        paste0("sealed_rendered_", family, ".png")
      )
      candidate_png <- file.path(
        temporary_dir,
        paste0("candidate_rendered_", family, ".png")
      )
      render_pdf_png(baseline, baseline_png)
      render_pdf_png(sealed, sealed_png)
      render_pdf_png(candidate, candidate_png)
      baseline_text <- extract_pdf_text(
        baseline,
        file.path(temporary_dir, paste0("baseline_", family, ".txt"))
      )
      sealed_text <- extract_pdf_text(
        sealed,
        file.path(temporary_dir, paste0("sealed_", family, ".txt"))
      )
      candidate_text <- extract_pdf_text(
        candidate,
        file.path(temporary_dir, paste0("candidate_", family, ".txt"))
      )
      add_row(
        family,
        extension,
        "old_label_baseline_rendered_pixels",
        identical(sha256_file(baseline_png), sha256_file(sealed_png)),
        sha256_file(baseline_png)
      )
      add_row(
        family,
        extension,
        "old_label_baseline_visible_text",
        identical(baseline_text, sealed_text),
        "pdftotext -layout"
      )
      add_row(
        family,
        extension,
        "page_geometry",
        identical(pdf_page_size(candidate), pdf_page_size(sealed)),
        pdf_page_size(candidate)
      )
      difference <- png_difference_summary(
        baseline_png,
        candidate_png,
        family
      )
      add_row(
        family,
        extension,
        "authorized_rendered_page_regions_only",
        difference$data_region_identical[[1L]],
        paste0("unexplained=", difference$unexplained_pixels[[1L]])
      )
      required <- candidate_visible_text_requirements[[family]]
      normalized_candidate <- normalize_visible_text(candidate_text)
      add_row(
        family,
        extension,
        "required_visible_labels",
        all(vapply(
          required,
          grepl,
          logical(1),
          x = normalized_candidate,
          fixed = TRUE
        )),
        paste(required, collapse = " | ")
      )
      retired <- c(
        "expected-hour",
        "supported-hour",
        "equal-site",
        " BH ",
        "heterogeneity",
        "frozen"
      )
      add_row(
        family,
        extension,
        "retired_visible_terms_absent",
        !any(vapply(
          retired,
          grepl,
          logical(1),
          x = paste0(" ", normalized_candidate, " "),
          fixed = TRUE
        )),
        paste(retired, collapse = " | ")
      )
    }
  }
  checks <- dplyr::bind_rows(rows)
  readr::write_csv(
    checks,
    file.path(evidence_dir, "source_value_and_geometry_checks.csv"),
    na = ""
  )
  assert_true(
    all(checks$status),
    paste(
      "Candidate validation failed:",
      paste(unique(checks$check[!checks$status]), collapse = ", ")
    )
  )
  invisible(checks)
}

write_visual_qa_pending <- function(candidates) {
  rows <- lapply(seq_len(nrow(family_specs)), function(index) {
    family <- family_specs$family[[index]]
    views <- create_visual_views(
      candidates[[paste(family, "png", sep = "_")]],
      family,
      family_specs$width_mm[[index]],
      family_specs$height_mm[[index]]
    )
    tibble::tibble(
      family = family,
      native_width_mm = family_specs$width_mm[[index]],
      native_height_mm = family_specs$height_mm[[index]],
      scale_factor = 1,
      smallest_essential_nominal_text_pt = 7.5,
      effective_final_text_pt = 7.5,
      original_resolution = basename(views[["original"]]),
      intended_170mm_a4 = basename(views[["a4"]]),
      width_708_px = basename(views[["width_708"]]),
      width_200_percent = basename(views[["width_200"]]),
      source_rows_preserved = "PASS",
      marks_intervals_curves_support_preserved = "PASS",
      required_labels_and_site_names = "PENDING MANUAL INSPECTION",
      clipping_overlap_wrapping_distortion_balance = "PENDING MANUAL INSPECTION",
      retired_visible_terms_absent = "PASS BY PDF AND SVG TEXT CHECK",
      overall_status = "PENDING MANUAL INSPECTION"
    )
  })
  readr::write_csv(
    dplyr::bind_rows(rows),
    file.path(evidence_dir, "visual_qa.csv"),
    na = ""
  )
}

write_temporary_inventory <- function(temporary_dir) {
  files <- list.files(temporary_dir, recursive = TRUE, full.names = TRUE)
  files <- files[!dir.exists(files)]
  inventory <- tibble::tibble(
    path = files,
    sha256 = vapply(files, sha256_file, character(1)),
    bytes = vapply(files, file_bytes, numeric(1))
  )
  readLines_safe <- function(path) readLines(path, warn = FALSE)
  readr::write_csv(
    inventory,
    file.path(evidence_dir, "temporary_inventory.csv"),
    na = ""
  )
  writeLines(
    c(
      paste0("temporary_directory=", temporary_dir),
      paste0("inventory_rows=", nrow(inventory)),
      paste0("recorded_utc=", format(Sys.time(), tz = "UTC", usetz = TRUE))
    ),
    file.path(evidence_dir, "temporary_directory.txt"),
    useBytes = TRUE
  )
  invisible(readLines_safe)
}

prepare_candidates <- function() {
  write_authorized_transitions()
  write_package_versions()
  write_protected_inventory()
  temporary_dir <- tempfile(
    pattern = "h06_report018_order46_",
    tmpdir = "/private/tmp"
  )
  dir.create(temporary_dir, recursive = TRUE, showWarnings = FALSE)
  sources <- read_plot_sources()
  assert_true(
    identical(
      vapply(
        c(
          sources$primary,
          sources$site,
          sources$day_curves,
          sources$day_ratios,
          sources$day_support,
          sources$activity_curves,
          sources$activity_ratios,
          sources$activity_support
        ),
        nrow,
        integer(1)
      ),
      c(18L, 27L, 194L, 97L, 48L, 194L, 97L, 48L)
    ),
    "A frozen figure-source row count changed"
  )
  old_plots <- build_plot_set(sources, repaired = FALSE)
  new_plots <- build_plot_set(sources, repaired = TRUE)
  baselines <- export_plot_set(old_plots, temporary_dir, "baseline")
  candidates <- export_plot_set(new_plots, temporary_dir, "candidate")
  validate_baselines_and_candidates(
    old_plots,
    new_plots,
    baselines,
    candidates,
    temporary_dir
  )
  file.copy(
    file.path(root, builder_pins$path),
    file.path(temporary_dir, paste0("pre_", basename(builder_pins$path))),
    overwrite = FALSE
  )
  file.copy(
    file.path(root, manifest_rel),
    file.path(temporary_dir, "pre_H06_stage3_artifacts.csv"),
    overwrite = FALSE
  )
  write_visual_qa_pending(candidates)
  write_temporary_inventory(temporary_dir)
  message("REPORT-018 H06 order 46 candidate set prepared: ", temporary_dir)
  invisible(temporary_dir)
}

read_temporary_directory <- function() {
  lines <- readLines(
    file.path(evidence_dir, "temporary_directory.txt"),
    warn = FALSE
  )
  path <- sub(
    "^temporary_directory=",
    "",
    lines[grepl(
      "^temporary_directory=",
      lines
    )]
  )
  assert_true(
    length(path) == 1L && dir.exists(path),
    "Retained temporary directory is missing"
  )
  path
}

verify_temporary_inventory <- function(temporary_dir) {
  inventory <- readr::read_csv(
    file.path(evidence_dir, "temporary_inventory.csv"),
    show_col_types = FALSE,
    col_types = readr::cols(
      path = readr::col_character(),
      sha256 = readr::col_character(),
      bytes = readr::col_double()
    )
  )
  assert_true(
    all(file.exists(inventory$path)),
    "A retained temporary file is missing"
  )
  assert_true(
    identical(
      vapply(inventory$path, sha256_file, character(1)),
      inventory$sha256
    ) &&
      identical(
        vapply(inventory$path, file_bytes, numeric(1)),
        inventory$bytes
      ),
    "A retained temporary file changed"
  )
  invisible(inventory)
}

create_builder_diff_and_reverse_proof <- function(temporary_dir) {
  proof_rows <- list()
  diff_lines <- character()
  for (index in seq_len(nrow(builder_pins))) {
    current <- file.path(root, builder_pins$path[[index]])
    pre <- file.path(
      temporary_dir,
      paste0("pre_", basename(builder_pins$path[[index]]))
    )
    assert_true(
      identical(sha256_file(pre), builder_pins$sha256[[index]]),
      paste("Retained builder preimage drift:", builder_pins$path[[index]])
    )
    output <- suppressWarnings(system2(
      "/usr/bin/diff",
      c("-u", pre, current),
      stdout = TRUE,
      stderr = TRUE
    ))
    status <- attr(output, "status")
    assert_true(
      identical(status, 1L),
      paste(
        "Builder diff did not contain the authorized changes:",
        builder_pins$path[[index]]
      )
    )
    diff_path <- file.path(
      temporary_dir,
      paste0(basename(builder_pins$path[[index]]), ".patch")
    )
    writeLines(output, diff_path, useBytes = TRUE)
    reverse_path <- file.path(
      temporary_dir,
      paste0("reverse_", basename(builder_pins$path[[index]]))
    )
    file.copy(current, reverse_path, overwrite = TRUE)
    patch_output <- suppressWarnings(system2(
      "/usr/bin/patch",
      c("-R", "--silent", reverse_path, "-i", diff_path),
      stdout = TRUE,
      stderr = TRUE
    ))
    patch_status <- attr(patch_output, "status")
    assert_true(
      is.null(patch_status) || identical(patch_status, 0L),
      paste("Reverse patch failed:", builder_pins$path[[index]])
    )
    reversed_sha <- sha256_file(reverse_path)
    assert_true(
      identical(reversed_sha, builder_pins$sha256[[index]]),
      paste("Builder reverse proof failed:", builder_pins$path[[index]])
    )
    diff_lines <- c(
      diff_lines,
      paste0("### ", builder_pins$path[[index]]),
      output,
      ""
    )
    proof_rows[[index]] <- tibble::tibble(
      path = builder_pins$path[[index]],
      pre_sha256 = builder_pins$sha256[[index]],
      post_sha256 = sha256_file(current),
      reversed_sha256 = reversed_sha,
      reverse_matches_preimage = TRUE
    )
  }
  writeLines(
    diff_lines,
    file.path(evidence_dir, "builder_authorized_diff.patch"),
    useBytes = TRUE
  )
  readr::write_csv(
    dplyr::bind_rows(proof_rows),
    file.path(evidence_dir, "builder_reverse_proof.csv"),
    na = ""
  )
}

validate_builder_literals <- function() {
  reader <- paste(
    readLines(file.path(root, builder_pins$path[[1L]]), warn = FALSE),
    collapse = "\n"
  )
  site <- paste(
    readLines(file.path(root, builder_pins$path[[2L]]), warn = FALSE),
    collapse = "\n"
  )
  required_reader <- c(
    "Primary and contextual mean hourly melEDI ratios",
    "Ratio of estimated mean hourly melEDI (log scale)",
    "Estimated melEDI (lx)",
    "Estimated melEDI ratio",
    "Estimated near-eye melEDI by day type and local time",
    "Estimated near-eye melEDI by activity status and local time",
    "Exploratory nonlinear two-part generalized additive model (GAM) display.",
    "individual displayed hours"
  )
  required_site <- c(
    "Site-specific mean hourly near-eye melEDI ratios",
    "site-average estimate from this model; filled points:",
    "nine-site FDR adjustments; open points:",
    "current\\n",
    "overall predictor-by-site interaction."
  )
  assert_true(
    all(vapply(required_reader, grepl, logical(1), x = reader, fixed = TRUE)),
    "A required repaired reader-builder literal is missing"
  )
  assert_true(
    all(vapply(required_site, grepl, logical(1), x = site, fixed = TRUE)),
    "A required repaired site-builder literal is missing"
  )
  forbidden_reader <- c(
    "Primary and contextual expected-hour melEDI ratios",
    "Ratio of expected supported-hour melEDI (log scale)",
    'y = "Expected melEDI (lx)"',
    'y = "Expected melEDI ratio"',
    'title = "Expected near-eye melEDI by'
  )
  forbidden_site <- c(
    "Site-specific expected-hour near-eye melEDI ratios",
    "equal-site average from this model; filled points:",
    "nine-site BH adjustments; open points:",
    "between-site heterogeneity."
  )
  assert_true(
    !any(vapply(forbidden_reader, grepl, logical(1), x = reader, fixed = TRUE)),
    "A retired reader-builder display literal remains"
  )
  assert_true(
    !any(vapply(forbidden_site, grepl, logical(1), x = site, fixed = TRUE)),
    "A retired site-builder display literal remains"
  )
}

parse_order_r_files <- function() {
  paths <- c(builder_pins$path, refresh_rel, test_rel)
  invisible(lapply(file.path(root, paths), parse))
}

candidate_path_for_export <- function(temporary_dir, family, export_path) {
  file.path(
    temporary_dir,
    paste0(
      "candidate_",
      tools::file_path_sans_ext(basename(export_path)),
      ".",
      tools::file_ext(export_path)
    )
  )
}

promote_exports <- function(temporary_dir) {
  candidate_paths <- vapply(
    seq_len(nrow(export_pins)),
    function(index)
      candidate_path_for_export(
        temporary_dir,
        export_pins$family[[index]],
        export_pins$path[[index]]
      ),
    character(1)
  )
  assert_true(
    all(file.exists(candidate_paths)),
    "A candidate export is missing"
  )
  candidate_hashes <- vapply(candidate_paths, sha256_file, character(1))
  for (index in seq_len(nrow(export_pins))) {
    copied <- file.copy(
      candidate_paths[[index]],
      file.path(root, export_pins$path[[index]]),
      overwrite = TRUE,
      copy.mode = FALSE,
      copy.date = FALSE
    )
    assert_true(
      copied,
      paste("Durable export replacement failed:", export_pins$path[[index]])
    )
  }
  durable_hashes <- vapply(
    file.path(root, export_pins$path),
    sha256_file,
    character(1)
  )
  assert_true(
    identical(unname(durable_hashes), unname(candidate_hashes)),
    "A durable export differs from its accepted candidate"
  )
  tibble::tibble(
    path = export_pins$path,
    pre_sha256 = export_pins$sha256,
    post_sha256 = durable_hashes,
    bytes = vapply(file.path(root, export_pins$path), file_bytes, numeric(1)),
    candidate_path = candidate_paths,
    durable_matches_candidate = TRUE
  )
}

manifest_row_line <- function(row) {
  paste(
    c(
      row$path,
      row$artifact_class,
      row$artifact_type,
      row$sha256,
      as.character(row$bytes),
      row$producer,
      row$r_version,
      row$written_utc
    ),
    collapse = ","
  )
}

reseal_stage3_manifest <- function(export_changes, temporary_dir) {
  manifest_path <- file.path(root, manifest_rel)
  assert_file(manifest_rel, manifest_pre_sha, manifest_pre_bytes)
  pre_path <- file.path(temporary_dir, "pre_H06_stage3_artifacts.csv")
  assert_true(
    identical(sha256_file(pre_path), manifest_pre_sha),
    "Retained Stage 3 manifest preimage drift"
  )
  pre_lines <- readLines(pre_path, warn = FALSE)
  current_lines <- readLines(manifest_path, warn = FALSE)
  assert_true(
    identical(pre_lines, current_lines),
    "Stage 3 manifest changed before reseal"
  )
  pre_data <- readr::read_csv(
    pre_path,
    show_col_types = FALSE,
    col_types = readr::cols(.default = readr::col_character())
  )
  assert_true(
    nrow(pre_data) == 301L,
    "Stage 3 manifest preimage is not 301 rows"
  )
  target_paths <- c(builder_pins$path, export_pins$path)
  target_index <- match(target_paths, pre_data$path)
  assert_true(!anyNA(target_index), "A manifest target row is missing")
  assert_true(
    length(unique(target_index)) == 13L,
    "Manifest target rows are not unique"
  )
  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S UTC", tz = "UTC")
  producer <- refresh_rel
  post_lines <- pre_lines
  changes <- vector("list", length(target_paths))
  for (index in seq_along(target_paths)) {
    row_index <- target_index[[index]]
    path <- target_paths[[index]]
    absolute <- file.path(root, path)
    row <- pre_data[row_index, , drop = FALSE]
    row$sha256 <- sha256_file(absolute)
    row$bytes <- as.character(file_bytes(absolute))
    row$producer <- producer
    row$r_version <- as.character(getRversion())
    row$written_utc <- timestamp
    replacement <- manifest_row_line(row)
    changes[[index]] <- tibble::tibble(
      change_type = "updated",
      path = path,
      pre_line = pre_lines[[row_index + 1L]],
      post_line = replacement,
      pre_sha256 = pre_data$sha256[[row_index]],
      post_sha256 = row$sha256[[1L]]
    )
    post_lines[[row_index + 1L]] <- replacement
  }

  append_specs <- tibble::tribble(
    ~path,
    ~artifact_class,
    ~artifact_type,
    refresh_rel,
    "H06_code",
    "r",
    test_rel,
    "H06_test",
    "r",
    paste0(evidence_rel, "/authorized_label_transitions.csv"),
    "H06_report018_evidence",
    "csv",
    paste0(evidence_rel, "/source_value_and_geometry_checks.csv"),
    "H06_report018_evidence",
    "csv",
    paste0(evidence_rel, "/visual_qa.csv"),
    "H06_report018_evidence",
    "csv",
    paste0(evidence_rel, "/protected_inventory.csv"),
    "H06_report018_evidence",
    "csv",
    paste0(evidence_rel, "/package_versions.csv"),
    "H06_report018_evidence",
    "csv"
  )
  assert_true(
    all(file.exists(file.path(root, append_specs$path))),
    "A manifest append file is missing"
  )
  append_lines <- character(nrow(append_specs))
  append_changes <- vector("list", nrow(append_specs))
  for (index in seq_len(nrow(append_specs))) {
    absolute <- file.path(root, append_specs$path[[index]])
    row <- tibble::tibble(
      path = append_specs$path[[index]],
      artifact_class = append_specs$artifact_class[[index]],
      artifact_type = append_specs$artifact_type[[index]],
      sha256 = sha256_file(absolute),
      bytes = as.character(file_bytes(absolute)),
      producer = producer,
      r_version = as.character(getRversion()),
      written_utc = timestamp
    )
    append_lines[[index]] <- manifest_row_line(row)
    append_changes[[index]] <- tibble::tibble(
      change_type = "appended",
      path = row$path,
      pre_line = "",
      post_line = append_lines[[index]],
      pre_sha256 = "",
      post_sha256 = row$sha256
    )
  }
  post_lines <- c(post_lines, append_lines)
  writeLines(post_lines, manifest_path, useBytes = TRUE)
  post_data <- readr::read_csv(
    manifest_path,
    show_col_types = FALSE,
    col_types = readr::cols(.default = readr::col_character())
  )
  assert_true(
    nrow(post_data) == 308L && dplyr::n_distinct(post_data$path) == 308L,
    "Resealed Stage 3 manifest does not contain 308 unique rows"
  )
  assert_true(
    identical(tail(post_data$path, 7L), append_specs$path),
    "Stage 3 manifest append order drift"
  )
  reverse_lines <- post_lines[seq_len(length(post_lines) - 7L)]
  for (index in seq_along(target_index)) {
    reverse_lines[[target_index[[index]] + 1L]] <- pre_lines[[
      target_index[[index]] + 1L
    ]]
  }
  reverse_path <- file.path(temporary_dir, "reverse_H06_stage3_artifacts.csv")
  writeLines(reverse_lines, reverse_path, useBytes = TRUE)
  assert_true(
    identical(sha256_file(reverse_path), manifest_pre_sha),
    "Stage 3 manifest reverse proof failed"
  )
  change_table <- dplyr::bind_rows(c(changes, append_changes))
  assert_true(
    sum(change_table$change_type == "updated") == 13L &&
      sum(change_table$change_type == "appended") == 7L,
    "Manifest change set is not exactly 13 updates plus seven appends"
  )
  readr::write_csv(
    change_table,
    file.path(evidence_dir, "manifest_row_changes.csv"),
    na = ""
  )
  invisible(list(
    pre_sha256 = manifest_pre_sha,
    post_sha256 = sha256_file(manifest_path),
    post_bytes = file_bytes(manifest_path),
    rows = nrow(post_data),
    export_changes = export_changes
  ))
}

write_completion_and_owner_manifest <- function(
  manifest_result,
  temporary_dir
) {
  completion_path <- file.path(evidence_dir, "completion_record.md")
  export_post <- manifest_result$export_changes$post_sha256
  completion <- c(
    "# REPORT-018 H06 order 46 owner completion record",
    "",
    paste0("Completed under R ", as.character(getRversion()), "."),
    "",
    "All four frozen-source figure families and all 11 paired exports were refreshed together.",
    "Only the authorized reader-visible labels changed. No scientific source, value, geometry, model, inference, or QMD was recomputed.",
    "",
    paste0("Retained temporary directory: `", temporary_dir, "`."),
    paste0(
      "Stage 3 manifest preimage SHA-256: `",
      manifest_result$pre_sha256,
      "`."
    ),
    paste0(
      "Stage 3 manifest postimage SHA-256: `",
      manifest_result$post_sha256,
      "`."
    ),
    paste0("Stage 3 manifest rows: ", manifest_result$rows, "."),
    "",
    "Post-refresh export SHA-256 values:",
    "",
    paste0("- `", export_pins$path, "`: `", export_post, "`")
  )
  writeLines(completion, completion_path, useBytes = TRUE)

  evidence_files <- list.files(evidence_dir, full.names = TRUE)
  owner_manifest_path <- file.path(evidence_dir, "owner_evidence_manifest.csv")
  evidence_files <- setdiff(evidence_files, owner_manifest_path)
  package_paths <- unique(c(
    file.path(
      root,
      c(
        "audit/report_harmonization/owner_orders/46_h06_hourly_reader_figure_label_refresh.md",
        "audit/report_harmonization/report018_h06_order46_dispatch_manifest.csv",
        refresh_rel,
        test_rel,
        builder_pins$path,
        export_pins$path,
        manifest_rel,
        source_pins$path
      )
    ),
    evidence_files
  ))
  assert_true(
    all(file.exists(package_paths)),
    "Owner evidence package contains a missing file"
  )
  roles <- ifelse(
    startsWith(package_paths, evidence_dir),
    "order-owned evidence",
    "order input or durable output"
  )
  owner_manifest <- tibble::tibble(
    path = ifelse(
      startsWith(package_paths, paste0(root, "/")),
      substring(package_paths, nchar(root) + 2L),
      package_paths
    ),
    sha256 = vapply(package_paths, sha256_file, character(1)),
    bytes = vapply(package_paths, file_bytes, numeric(1)),
    role = roles
  ) |>
    dplyr::arrange(.data$path)
  assert_true(
    !any(
      owner_manifest$path ==
        paste0(evidence_rel, "/owner_evidence_manifest.csv")
    ),
    "Owner evidence manifest is circular"
  )
  readr::write_csv(owner_manifest, owner_manifest_path, na = "")
}

promote_candidates <- function() {
  temporary_dir <- read_temporary_directory()
  verify_temporary_inventory(temporary_dir)
  verify_protected_inventory()
  for (index in seq_len(nrow(source_pins))) {
    assert_file(
      source_pins$path[[index]],
      source_pins$sha256[[index]],
      source_pins$bytes[[index]]
    )
  }
  for (index in seq_len(nrow(export_pins))) {
    assert_file(
      export_pins$path[[index]],
      export_pins$sha256[[index]],
      export_pins$bytes[[index]]
    )
  }
  visual_qa <- readr::read_csv(
    file.path(evidence_dir, "visual_qa.csv"),
    show_col_types = FALSE,
    col_types = readr::cols(.default = readr::col_character())
  )
  assert_true(
    nrow(visual_qa) == 4L && all(visual_qa$overall_status == "PASS"),
    "Visual QA is not complete for all four figure families"
  )
  validate_builder_literals()
  parse_order_r_files()
  create_builder_diff_and_reverse_proof(temporary_dir)
  export_changes <- promote_exports(temporary_dir)
  verify_protected_inventory()
  manifest_result <- reseal_stage3_manifest(export_changes, temporary_dir)
  write_completion_and_owner_manifest(manifest_result, temporary_dir)
  verify_protected_inventory()
  message(
    "REPORT-018 H06 order 46 durable package sealed; Stage 3 manifest ",
    manifest_result$post_sha256
  )
  invisible(manifest_result)
}

run_order46 <- function() {
  if (identical(mode, "prepare")) {
    prepare_candidates()
  } else {
    promote_candidates()
  }
}

tryCatch(
  run_order46(),
  error = function(error) {
    defect <- tibble::tibble(
      phase = mode,
      status = "STOPPED",
      defect = conditionMessage(error),
      recorded_utc = format(Sys.time(), tz = "UTC", usetz = TRUE)
    )
    readr::write_csv(
      defect,
      file.path(evidence_dir, "defect_list.csv"),
      na = ""
    )
    stop(error)
  }
)
