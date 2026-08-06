#!/usr/bin/env Rscript

# Result-only H11 Stage 2 display builder. This script reads persisted model
# outputs and diagnostics; it does not fit, refit, bootstrap, or simulate.

suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
  library(patchwork)
  library(readr)
  library(scales)
  library(tibble)
  library(tidyr)
})

options(
  stringsAsFactors = FALSE,
  scipen = 999,
  dplyr.summarise.inform = FALSE
)

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
source(file.path(root, "scripts/hypotheses/H02/h02_contract.R"))
source(file.path(root, "scripts/hypotheses/H02/h02_modeling.R"))
source(file.path(root, "scripts/hypotheses/H11/h11_stage1.R"))
source(file.path(root, "scripts/hypotheses/H11/h11_stage2.R"))

if (getRversion() != "4.6.1") {
  h11_stage2_abort("H11 display building requires R 4.6.1")
}

paths <- h11_stage2_paths(root)
h11_stage2_create_directories(paths)

read_stage2_csv <- function(directory, filename) {
  path <- file.path(directory, filename)
  if (!file.exists(path)) {
    h11_stage2_abort("Missing H11 Stage 2 display input: %s", path)
  }
  readr::read_csv(path, show_col_types = FALSE)
}

curves <- read_stage2_csv(
  paths$source_data,
  "sex_specific_curves_pointwise.csv"
)
contrasts <- read_stage2_csv(
  paths$source_data,
  "female_minus_male_pointwise_contrasts.csv"
)
residual_acf <- read_stage2_csv(
  paths$diagnostics,
  "boundary_aware_residual_acf.csv"
)
sample_counts <- read_stage2_csv(paths$tables, "sample_counts.csv")
registry <- h11_stage2_registry(root)

sex_palette <- c(Female = "#CC79A7", Male = "#0072B2")
figure_spec <- list(
  pointwise_width_inches = 7.2,
  pointwise_height_inches = 8.2,
  diagnostic_width_inches = 7.2,
  diagnostic_height_inches = 4.4,
  minimum_important_text_pt = 7
)
wrap_label <- function(text, width) {
  paste(strwrap(text, width = width), collapse = "\n")
}
theme_h11 <- function() {
  ggplot2::theme_minimal(base_size = 10) +
    ggplot2::theme(
      panel.grid.minor = ggplot2::element_blank(),
      legend.position = "top",
      legend.title = ggplot2::element_blank(),
      legend.text = ggplot2::element_text(size = 8.5),
      plot.title.position = "plot",
      plot.caption.position = "plot",
      plot.title = ggplot2::element_text(
        face = "bold", size = 11, lineheight = 1.05
      ),
      plot.subtitle = ggplot2::element_text(size = 8.5, lineheight = 1.12),
      plot.caption = ggplot2::element_text(size = 7, lineheight = 1.1),
      axis.title = ggplot2::element_text(face = "plain", size = 9),
      axis.text = ggplot2::element_text(size = 8.5),
      plot.margin = ggplot2::margin(8, 10, 8, 8)
    )
}

format_minutes <- function(x) {
  sprintf("%02d:%02d", (x %/% 60L) %% 24L, x %% 60L)
}

solar_context_rows <- list()
for (index in seq_len(nrow(registry))) {
  run <- registry[index, , drop = FALSE]
  frame <- readRDS(file.path(
    paths$model_data,
    paste0(run$run_id, "__frame.rds")
  ))
  base_path <- file.path(
    root,
    "artifacts/06_model_data/base",
    paste0("metrics_", run$placement, "_30_minute_context.rds")
  )
  base <- readRDS(base_path)
  fitted_days <- frame |>
    dplyr::distinct(.data$site, .data$Id, .data$local_date)
  solar <- base |>
    dplyr::select(
      "site", "Id", "local_date",
      "civil_dawn_wall_minute", "civil_dusk_wall_minute"
    ) |>
    dplyr::distinct() |>
    dplyr::semi_join(
      fitted_days,
      by = c("site", "Id", "local_date")
    ) |>
    dplyr::group_by(.data$site) |>
    dplyr::summarise(
      participant_days = dplyr::n(),
      mean_civil_dawn_hour = mean(.data$civil_dawn_wall_minute) / 60,
      mean_civil_dusk_hour = mean(.data$civil_dusk_wall_minute) / 60,
      .groups = "drop"
    ) |>
    dplyr::summarise(
      sites = dplyr::n(),
      equal_site_mean_civil_dawn_hour = mean(.data$mean_civil_dawn_hour),
      equal_site_mean_civil_dusk_hour = mean(.data$mean_civil_dusk_hour)
    ) |>
    dplyr::mutate(
      run_id = run$run_id,
      placement = run$placement,
      data_scenario_id = run$data_scenario_id,
      .before = 1L
    )
  solar_context_rows[[run$run_id]] <- solar
}
solar_context <- dplyr::bind_rows(solar_context_rows)
readr::write_csv(
  solar_context,
  file.path(paths$source_data, "equal_site_solar_context.csv"),
  na = ""
)

build_h11_figure <- function(run_id, placement_label) {
  run_curves <- curves |>
    dplyr::filter(.data$run_id == .env$run_id) |>
    dplyr::mutate(sex = factor(.data$sex, levels = c("Female", "Male")))
  run_contrast <- contrasts |>
    dplyr::filter(.data$run_id == .env$run_id)
  solar <- solar_context |>
    dplyr::filter(.data$run_id == .env$run_id)
  sample <- sample_counts |>
    dplyr::filter(.data$run_id == .env$run_id)
  if (
    nrow(run_curves) != 96L ||
      nrow(run_contrast) != 48L ||
      nrow(solar) != 1L ||
      nrow(sample) != 1L
  ) {
    h11_stage2_abort("Incomplete H11 display contract for %s", run_id)
  }
  night <- tibble::tibble(
    xmin = c(0, solar$equal_site_mean_civil_dusk_hour),
    xmax = c(solar$equal_site_mean_civil_dawn_hour, 24)
  )
  p_curve <- ggplot2::ggplot(run_curves) +
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
      linewidth = 1
    ) +
    ggplot2::scale_colour_manual(values = sex_palette, drop = FALSE) +
    ggplot2::scale_fill_manual(values = sex_palette, drop = FALSE) +
    ggplot2::scale_x_continuous(
      breaks = seq(0, 24, by = 6),
      limits = c(0, 24),
      expand = c(0, 0)
    ) +
    ggplot2::scale_y_continuous(
      trans = scales::pseudo_log_trans(base = 10, sigma = 0.1),
      breaks = c(0, 0.1, 1, 10, 100, 1000, 10000),
      labels = scales::label_number(big.mark = ",")
    ) +
    ggplot2::labs(
      title = wrap_label(
        paste0("A  Sex-specific ", placement_label, " curves"),
        68
      ),
      subtitle = wrap_label(
        paste0(
          "Equal-site conditional means; ",
          sample$participants, " participants, ",
          sample$participant_days, " participant-days, ",
          format(sample$observations_30_minute, big.mark = ","),
          " 30-minute observations"
        ),
        84
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
      "All 48 displayed pointwise intervals exclude 1; open circles are",
      "omitted to avoid obscuring the curve. Intervals are not simultaneous."
    )
  } else {
    paste(
      "Ribbons are participant-cluster-robust pointwise 95% intervals;",
      "open circles mark individual displayed bins whose interval excludes 1."
    )
  }
  p_ratio <- ggplot2::ggplot(run_contrast) +
    ggplot2::geom_rect(
      data = night,
      ggplot2::aes(xmin = .data$xmin, xmax = .data$xmax),
      ymin = -Inf,
      ymax = Inf,
      inherit.aes = FALSE,
      fill = "grey92"
    ) +
    ggplot2::geom_hline(yintercept = 1, linetype = "dashed", colour = "grey30") +
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
      linewidth = 1
    ) +
    ggplot2::geom_point(
      data = pointwise_marks_for_plot,
      ggplot2::aes(
        x = .data$time_hour,
        y = .data$female_to_male_shifted_ratio
      ),
      shape = 21,
      size = 2.1,
      stroke = 0.7,
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
      subtitle = wrap_label(
        ratio_subtitle,
        84
      ),
      x = "Local clock time (hours)",
      y = "Female / Male ratio"
    ) +
    theme_h11()

  figure <- p_curve / p_ratio +
    patchwork::plot_layout(heights = c(1.7, 1)) +
    patchwork::plot_annotation(
      caption = wrap_label(
        paste(
          "Grey shading spans midnight to equal-site mean civil dawn and",
          "equal-site mean civil dusk to midnight. Intervals are pointwise,",
          "not simultaneous; the global participant-cluster-robust curve test",
          "is the H11 test and",
          "the display cannot establish a familywise-significant time period."
        ),
        112
      )
    )
  list(
    figure = figure,
    pointwise_mark_rows = pointwise_marks |>
      dplyr::select(
        "run_id", "clock_bin", "time_hour", "pointwise_direction",
        "female_to_male_shifted_ratio", "ratio_lower_pointwise_95",
        "ratio_upper_pointwise_95"
      )
  )
}

display_runs <- tibble::tribble(
  ~run_id, ~placement_label, ~filename,
  "main__glasses__all_available", "near-eye", "h11_near_eye_pointwise",
  "main__chest__all_available", "chest", "h11_chest_pointwise",
  "manuscript_prepared_data__glasses__all_available",
  "near-eye, gap-timing-unaware dataset", "h11_v0_prepared_near_eye_pointwise",
  "manuscript_prepared_data__chest__all_available",
  "chest, gap-timing-unaware dataset", "h11_v0_prepared_chest_pointwise"
)
pointwise_mark_tables <- list()
for (index in seq_len(nrow(display_runs))) {
  row <- display_runs[index, , drop = FALSE]
  built <- build_h11_figure(row$run_id, row$placement_label)
  png_path <- file.path(paths$figures, paste0(row$filename, ".png"))
  pdf_path <- file.path(paths$figures, paste0(row$filename, ".pdf"))
  ggplot2::ggsave(
    png_path,
    plot = built$figure,
    width = figure_spec$pointwise_width_inches,
    height = figure_spec$pointwise_height_inches,
    units = "in",
    dpi = 300,
    bg = "white"
  )
  ggplot2::ggsave(
    pdf_path,
    plot = built$figure,
    width = figure_spec$pointwise_width_inches,
    height = figure_spec$pointwise_height_inches,
    units = "in",
    device = grDevices::cairo_pdf,
    bg = "white"
  )
  pointwise_mark_tables[[row$run_id]] <- built$pointwise_mark_rows
}
readr::write_csv(
  dplyr::bind_rows(pointwise_mark_tables),
  file.path(paths$source_data, "figure_pointwise_mark_rows.csv"),
  na = ""
)

diagnostic_runs <- display_runs |>
  dplyr::filter(grepl("^main__", .data$run_id))
for (index in seq_len(nrow(diagnostic_runs))) {
  row <- diagnostic_runs[index, , drop = FALSE]
  acf <- residual_acf |>
    dplyr::filter(.data$run_id == row$run_id) |>
    dplyr::mutate(
      stage = factor(
        .data$stage,
        levels = c(
          "preliminary_rho0_response",
          "final_AR1_standardized"
        ),
        labels = c("Before AR(1)", "After AR(1)")
      )
    )
  p_acf <- ggplot2::ggplot(
    acf,
    ggplot2::aes(
      x = .data$lag_minutes,
      y = .data$correlation,
      colour = .data$stage
    )
  ) +
    ggplot2::geom_hline(yintercept = 0, colour = "grey60") +
    ggplot2::geom_line(linewidth = 0.9) +
    ggplot2::geom_point(size = 2) +
    ggplot2::scale_colour_manual(
      values = c("Before AR(1)" = "#D55E00", "After AR(1)" = "#0072B2")
    ) +
    ggplot2::labs(
      title = wrap_label(
        paste0("Boundary-aware residual dependence: ", row$placement_label),
        66
      ),
      subtitle = wrap_label(
        "No pair crosses a participant-day or declared H02 sequence boundary.",
        78
      ),
      x = "Lag (minutes)",
      y = "Residual correlation"
    ) +
    theme_h11()
  ggplot2::ggsave(
    file.path(paths$figures, paste0(row$filename, "_residual_acf.png")),
    plot = p_acf,
    width = figure_spec$diagnostic_width_inches,
    height = figure_spec$diagnostic_height_inches,
    units = "in",
    dpi = 300,
    bg = "white"
  )
}

pointwise_figure_manifest <- dplyr::bind_rows(lapply(seq_len(nrow(display_runs)), function(index) {
  row <- display_runs[index, , drop = FALSE]
  paths_out <- file.path(
    paths$figures,
    paste0(row$filename, c(".png", ".pdf"))
  )
  tibble::tibble(
    run_id = row$run_id,
    placement_label = row$placement_label,
    path = sub(paste0("^", root, "/"), "", paths_out),
    sha256 = vapply(paths_out, h11_stage2_sha256, character(1)),
    bytes = as.numeric(file.info(paths_out)$size),
    file_format = tools::file_ext(paths_out),
    display_role = ifelse(
      grepl("^main__", row$run_id),
      "reader-facing Stage 2 result",
      "audit sensitivity output"
    ),
    canvas_width_inches = figure_spec$pointwise_width_inches,
    canvas_height_inches = figure_spec$pointwise_height_inches,
    minimum_important_text_pt = figure_spec$minimum_important_text_pt,
    policy_id = "REPORT-011",
    interval_scope = paste(
      "participant-cluster-robust pointwise 95%; not simultaneous;",
      "H11-METHOD-005"
    )
  )
}))
diagnostic_figure_manifest <- dplyr::bind_rows(lapply(
  seq_len(nrow(diagnostic_runs)),
  function(index) {
    row <- diagnostic_runs[index, , drop = FALSE]
    path_out <- file.path(
      paths$figures,
      paste0(row$filename, "_residual_acf.png")
    )
    tibble::tibble(
      run_id = row$run_id,
      placement_label = row$placement_label,
      path = sub(paste0("^", root, "/"), "", path_out),
      sha256 = h11_stage2_sha256(path_out),
      bytes = as.numeric(file.info(path_out)$size),
      file_format = tools::file_ext(path_out),
      display_role = "reader-facing Stage 2 diagnostic",
      canvas_width_inches = figure_spec$diagnostic_width_inches,
      canvas_height_inches = figure_spec$diagnostic_height_inches,
      minimum_important_text_pt = figure_spec$minimum_important_text_pt,
      policy_id = "REPORT-011",
      interval_scope = "diagnostic residual correlation; no confidence interval"
    )
  }
))
figure_manifest <- dplyr::bind_rows(
  pointwise_figure_manifest,
  diagnostic_figure_manifest
)
readr::write_csv(
  figure_manifest,
  file.path(paths$manifests, "H11_stage2_figure_manifest.csv"),
  na = ""
)

message("H11 Stage 2 result-only displays complete")
