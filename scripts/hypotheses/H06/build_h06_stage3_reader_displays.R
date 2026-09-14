#!/usr/bin/env Rscript

# Build Stage 3 H06 reader displays from frozen estimates and predictions.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)

source(file.path(root, "scripts/pipeline/paths_io.R"))
source(file.path(root, "scripts/hypotheses/H06/h06_contract.R"))

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop(
    sprintf(
      "H06 Stage 3 reader displays require R 4.6.1; found %s",
      as.character(getRversion())
    ),
    call. = FALSE
  )
}

required_packages <- c(
  "cowplot",
  "dplyr",
  "ggplot2",
  "LightLogR",
  "patchwork",
  "readr",
  "scales",
  "svglite",
  "tibble",
  "tidyr"
)
missing_packages <- required_packages[!vapply(
  required_packages,
  requireNamespace,
  logical(1),
  quietly = TRUE
)]
if (length(missing_packages) > 0L) {
  stop(
    "Missing project package(s): ",
    paste(missing_packages, collapse = ", "),
    call. = FALSE
  )
}

qa_status <- Sys.getenv("H06_FIGURE_QA_STATUS", unset = "NOT TESTED")
if (!qa_status %in% c("NOT TESTED", "PASS")) {
  stop(
    "H06_FIGURE_QA_STATUS must be `NOT TESTED` or `PASS`",
    call. = FALSE
  )
}

producer <- paste0(
  "scripts/hypotheses/H06/",
  "build_h06_stage3_reader_displays.R"
)
figure_root <- file.path(root, "artifacts/10_figures/H06")
source_root <- file.path(root, "artifacts/11_source_data/H06")
manifest_root <- file.path(root, "artifacts/12_manifests/H06")
qa_root <- file.path(manifest_root, "qa")
invisible(vapply(
  c(figure_root, source_root, manifest_root, qa_root),
  dir.create,
  logical(1),
  recursive = TRUE,
  showWarnings = FALSE
))

write_h06_csv <- function(data, path) {
  write_csv_artifact(data, path, producer = producer)
  invisible(path)
}

h06_relative_path <- function(path) {
  normalized <- normalizePath(path, winslash = "/", mustWork = TRUE)
  substring(normalized, nchar(root) + 2L)
}

input_contract <- h06_input_contract(root)
input_hashes_match <- vapply(
  seq_len(nrow(input_contract)),
  function(index) {
    identical(
      artifact_sha256(input_contract$path[[index]]),
      input_contract$expected_sha256[[index]]
    )
  },
  logical(1)
)
if (any(!input_hashes_match)) {
  stop(
    "Frozen H06 Stage 3 input(s) changed: ",
    paste(input_contract$input_role[!input_hashes_match], collapse = ", "),
    call. = FALSE
  )
}

stage2_manifest_path <- file.path(
  manifest_root,
  "H06_stage2_artifacts.csv"
)
stage2_manifest <- readr::read_csv(
  stage2_manifest_path,
  show_col_types = FALSE
)
stage2_relative <- c(
  "artifacts/11_source_data/H06/H06_core_effects_figure.csv",
  paste0(
    "artifacts/11_source_data/H06/",
    "H06_exploratory_two_part_day_type_expected_figure.csv"
  ),
  paste0(
    "artifacts/11_source_data/H06/",
    "H06_exploratory_two_part_activity_expected_figure.csv"
  )
)
stage2_rows <- stage2_manifest[
  match(stage2_relative, stage2_manifest$path),
  ,
  drop = FALSE
]
stage2_paths <- file.path(root, stage2_rows$path)
if (
  anyNA(stage2_rows$path) ||
    !all(file.exists(stage2_paths)) ||
    !identical(
      unname(vapply(stage2_paths, artifact_sha256, character(1))),
      stage2_rows$sha256
    )
) {
  stop("A frozen H06 Stage 2 display source changed", call. = FALSE)
}

contrast_path <- file.path(
  source_root,
  "H06_exploratory_two_part_temporal_contrasts.csv"
)
if (!file.exists(contrast_path)) {
  stop("The H06 Stage 3 temporal contrast source is missing", call. = FALSE)
}

core_effects <- readr::read_csv(
  stage2_paths[[1L]],
  show_col_types = FALSE,
  na = ""
)
day_type_curves <- readr::read_csv(
  stage2_paths[[2L]],
  show_col_types = FALSE,
  na = ""
)
activity_curves <- readr::read_csv(
  stage2_paths[[3L]],
  show_col_types = FALSE,
  na = ""
)
temporal_contrasts <- readr::read_csv(
  contrast_path,
  show_col_types = FALSE,
  na = ""
)

if (
  nrow(core_effects) != 18L ||
    nrow(day_type_curves) != 194L ||
    nrow(activity_curves) != 194L ||
    nrow(temporal_contrasts) != 194L ||
    !identical(
      sort(unique(temporal_contrasts$contrast_id)),
      c("active_vs_sedentary", "free_vs_work")
    ) ||
    any(day_type_curves$sites_with_support != 9L) ||
    any(activity_curves$sites_with_support != 9L) ||
    any(temporal_contrasts$pointwise_low_ratio <= 0) ||
    any(temporal_contrasts$pointwise_high_ratio <= 0)
) {
  stop("An H06 Stage 3 reader-display source failed validation", call. = FALSE)
}

h06_reader_theme <- function() {
  cowplot::theme_cowplot(font_size = 10.5) +
    ggplot2::theme(
      axis.text = ggplot2::element_text(size = 8.5, colour = "black"),
      axis.title = ggplot2::element_text(size = 9.5),
      strip.background = ggplot2::element_rect(
        fill = "#D9D9D9",
        colour = NA
      ),
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

saved_qa_rows <- list()
save_reader_figure <- function(
  plot,
  figure_id,
  height_mm,
  source_csvs,
  greyscale_note
) {
  native_width_mm <- 170
  native_width_in <- native_width_mm / 25.4
  native_height_in <- height_mm / 25.4
  for (extension in c("png", "pdf", "svg")) {
    ggplot2::ggsave(
      filename = file.path(
        figure_root,
        paste0(figure_id, ".", extension)
      ),
      plot = plot,
      width = native_width_in,
      height = native_height_in,
      units = "in",
      dpi = 320,
      bg = "white",
      limitsize = FALSE
    )
  }

  preview_path <- file.path(
    qa_root,
    paste0(figure_id, "_A4_preview.pdf")
  )
  grDevices::cairo_pdf(
    preview_path,
    width = 210 / 25.4,
    height = 297 / 25.4,
    bg = "white"
  )
  grid::grid.newpage()
  grid::grid.rect(gp = grid::gpar(fill = "white", col = NA))
  grid::pushViewport(grid::viewport(
    width = grid::unit(native_width_mm, "mm"),
    height = grid::unit(height_mm, "mm")
  ))
  print(plot, newpage = FALSE)
  grid::popViewport()
  grDevices::dev.off()

  inspection <- if (qa_status == "PASS") {
    paste0(
      "PASS at 170 mm on an A4 portrait page with 20-mm side margins: ",
      "no clipping, overlap, harmful wrapping, distortion, or materially ",
      "imbalanced data region; titles, facets, intervals, support marks, ",
      "and captions remain legible."
    )
  } else {
    paste0(
      "NOT TESTED: inspect the A4 physical-size preview for clipping, ",
      "overlap, wrapping, distortion, data-region balance, and mark ",
      "differentiation."
    )
  }
  saved_qa_rows[[figure_id]] <<- tibble::tibble(
    figure_id = figure_id,
    source_csvs = paste(source_csvs, collapse = "; "),
    a4_preview = h06_relative_path(preview_path),
    native_width_mm = native_width_mm,
    native_height_mm = height_mm,
    base_width_in = native_width_in,
    base_height_in = native_height_in,
    export_scale_multiplier = 1,
    export_width_in = native_width_in,
    export_height_in = native_height_in,
    raster_dpi = 320L,
    intended_html_display_width_mm = native_width_mm,
    intended_print_display_width_mm = native_width_mm,
    scale_factor = 1,
    smallest_essential_nominal_text_pt = 7.5,
    effective_final_text_pt = 7.5,
    physical_size_inspection = inspection,
    clipping_overlap_wrapping_distortion_balance = inspection,
    greyscale_and_redundant_encoding = greyscale_note,
    report_011_status = qa_status
  )
  invisible(preview_path)
}

effect_order <- c(
  "Free day versus work day",
  "Active versus sedentary",
  "Per additional hour of previous sleep"
)
scenario_order <- c(
  "Primary near-eye",
  "Chest (all available)",
  "Near-eye (paired days)",
  "Chest (paired days)",
  "Gap-timing-unaware near-eye",
  "Gap-timing-unaware chest"
)
primary_source <- core_effects |>
  dplyr::mutate(
    effect = factor(.data$effect, levels = effect_order),
    effect_display = factor(
      dplyr::recode(
        as.character(.data$effect),
        `Free day versus work day` = "Free day versus\nwork day",
        `Active versus sedentary` = "Active versus\nsedentary",
        `Per additional hour of previous sleep` =
          "Previous sleep\n(per additional hour)"
      ),
      levels = c(
        "Free day versus\nwork day",
        "Active versus\nsedentary",
        "Previous sleep\n(per additional hour)"
      )
    ),
    scenario = factor(.data$scenario, levels = rev(scenario_order)),
    placement = factor(.data$placement, levels = c("Near-eye", "Chest"))
  )
primary_source_path <- file.path(
  source_root,
  "H06_reader_primary_effects_figure.csv"
)
write_h06_csv(primary_source, primary_source_path)

primary_plot <- ggplot2::ggplot(
  primary_source,
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
  ggplot2::geom_errorbar(
    orientation = "y",
    width = 0,
    linewidth = 0.65
  ) +
  ggplot2::geom_point(size = 2.8) +
  ggplot2::facet_wrap(
    ggplot2::vars(.data$effect_display),
    ncol = 3
  ) +
  ggplot2::scale_x_log10(
    breaks = c(0.5, 0.75, 1, 1.5, 2, 3),
    labels = scales::label_number(accuracy = 0.01)
  ) +
  ggplot2::scale_colour_manual(
    values = c("Near-eye" = "#0072B2", "Chest" = "#D55E00")
  ) +
  ggplot2::scale_shape_manual(
    values = c("Near-eye" = 17, "Chest" = 16)
  ) +
  ggplot2::labs(
    title = "Primary and contextual mean hourly melEDI ratios",
    subtitle = paste(
      "Dashed line: null ratio 1; points and bars: estimates and",
      "participant-cluster HC3 95% confidence intervals"
    ),
    x = "Ratio of estimated mean hourly melEDI (log scale)",
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

save_reader_figure(
  primary_plot,
  "H06_reader_primary_effects",
  height_mm = 118,
  source_csvs = h06_relative_path(primary_source_path),
  greyscale_note = paste(
    "Near-eye and chest are redundantly encoded by colour and distinct",
    "point shape; the null reference does not depend on colour"
  )
)

build_temporal_reader_figure <- function(
  curves,
  group_column,
  group_levels,
  colours,
  linetypes,
  contrast_id,
  figure_id,
  title,
  ratio_title,
  legend_title,
  standardization_text
) {
  contrast_colour <- unname(colours[[group_levels[[2L]]]])
  curves <- curves |>
    dplyr::mutate(
      display_group = factor(
        as.character(.data[[group_column]]),
        levels = group_levels
      ),
      integer_hour = abs(.data$clock_hour - round(.data$clock_hour)) < 1e-9
    )
  ratio <- temporal_contrasts |>
    dplyr::filter(.data$contrast_id == .env$contrast_id) |>
    dplyr::mutate(
      integer_hour = abs(.data$clock_hour - round(.data$clock_hour)) < 1e-9,
      pointwise_ci_excludes_one =
        .data$pointwise_low_ratio > 1 |
        .data$pointwise_high_ratio < 1
    )
  support <- curves |>
    dplyr::filter(
      .data$integer_hour,
      .data$clock_hour < 24
    ) |>
    dplyr::transmute(
      .data$clock_hour,
      .data$display_group,
      participant_hours = .data$observations,
      .data$participants,
      .data$participant_days,
      .data$sites_with_support,
      support_state = "Observed in all nine study sites"
    )

  if (
    anyNA(curves$display_group) ||
      nrow(ratio) != 97L ||
      nrow(support) != 48L ||
      any(support$sites_with_support != 9L) ||
      any(support$participant_hours <= 0)
  ) {
    stop(
      sprintf("Reader temporal source failed for `%s`", figure_id),
      call. = FALSE
    )
  }

  curve_source_path <- file.path(
    source_root,
    paste0(figure_id, "_curves.csv")
  )
  ratio_source_path <- file.path(
    source_root,
    paste0(figure_id, "_ratios.csv")
  )
  support_source_path <- file.path(
    source_root,
    paste0(figure_id, "_support.csv")
  )
  write_h06_csv(curves, curve_source_path)
  write_h06_csv(ratio, ratio_source_path)
  write_h06_csv(support, support_source_path)

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
      y = "Estimated melEDI (lx)"
    ) +
    h06_reader_theme() +
    ggplot2::theme(
      legend.position = "top",
      legend.justification = "left",
      legend.box.just = "left"
    )

  ratio_breaks <- c(0.125, 0.25, 0.5, 1, 2, 4, 8)
  ratio_plot <- ggplot2::ggplot(
    ratio,
    ggplot2::aes(
      x = .data$clock_hour,
      y = .data$expected_melEDI_ratio
    )
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
      data = dplyr::filter(ratio, .data$integer_hour),
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
      breaks = ratio_breaks,
      labels = scales::label_number(accuracy = 0.01)
    ) +
    ggplot2::labs(
      title = paste0("B  ", ratio_title),
      subtitle = paste(
        "Filled point: pointwise CI excludes 1; hollow: it includes 1;",
        "no simultaneous or whole-curve test"
      ),
      x = NULL,
      y = "Estimated melEDI ratio"
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
    ggplot2::facet_wrap(
      ggplot2::vars(.data$display_group),
      ncol = 2
    ) +
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

  figure <- patchwork::wrap_plots(
    curve_plot,
    ratio_plot,
    support_plot,
    ncol = 1,
    heights = c(1.15, 1, 0.75)
  ) +
    patchwork::plot_annotation(
      caption = h06_wrap_text(paste0(
        "Exploratory nonlinear two-part generalized additive model (GAM) display.\n",
        standardization_text,
        "\n",
        "Displayed curves omit participant and participant-day random effects. Bands and ratio intervals are approximate pointwise 95% intervals with fixed smoothing parameters; uncertainty does not include covariance between the occurrence and positive-magnitude components.\n",
        "Filled and hollow points distinguish intervals that exclude and include 1. These intervals apply to individual displayed hours, not a simultaneous or multiplicity-controlled whole-curve test.\n",
        "The panel-A transformation is display-only."
      )),
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

  save_reader_figure(
    figure,
    figure_id,
    height_mm = 205,
    source_csvs = vapply(
      c(curve_source_path, ratio_source_path, support_source_path),
      h06_relative_path,
      character(1)
    ),
    greyscale_note = paste(
      "Overlaid predictor curves use line type as well as colour; filled and",
      "hollow ratio points encode pointwise interval inclusion, and the",
      "support panels remain interpretable without colour"
    )
  )
}

build_temporal_reader_figure(
  curves = day_type_curves,
  group_column = "work_free_day",
  group_levels = c("Work day", "Free day"),
  colours = c("Work day" = "#0072B2", "Free day" = "#E69F00"),
  linetypes = c("Work day" = "solid", "Free day" = "22"),
  contrast_id = "free_vs_work",
  figure_id = "H06_reader_temporal_day_type",
  title = "Estimated near-eye melEDI by day type and local time",
  ratio_title = "Free day relative to work day across local time",
  legend_title = "Day type",
  standardization_text = paste(
    "Curves give sedentary and active status equal weight and standardize",
    "equally across the nine study sites."
  )
)

build_temporal_reader_figure(
  curves = activity_curves,
  group_column = "activity_status",
  group_levels = c("Sedentary", "Active"),
  colours = c("Sedentary" = "#009E73", "Active" = "#CC79A7"),
  linetypes = c("Sedentary" = "solid", "Active" = "22"),
  contrast_id = "active_vs_sedentary",
  figure_id = "H06_reader_temporal_activity",
  title = "Estimated near-eye melEDI by activity status and local time",
  ratio_title = "Active relative to sedentary across local time",
  legend_title = "Activity status",
  standardization_text = paste(
    "Curves give work and free days equal weight and standardize equally",
    "across the nine study sites."
  )
)

reader_qa <- dplyr::bind_rows(saved_qa_rows)
qa_path <- file.path(
  manifest_root,
  "H06_stage3_reader_display_figure_readability_qa.csv"
)
write_h06_csv(reader_qa, qa_path)

message(
  sprintf(
    "H06 Stage 3 reader displays built from stored outputs; figure QA %s",
    qa_status
  )
)
