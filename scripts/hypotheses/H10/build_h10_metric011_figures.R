#!/usr/bin/env Rscript

# Rebuild only durable H10 displays whose sealed source tables can contain the
# METRIC-011 L10 slot or its BH-derived fields. This script never fits,
# predicts from, simulates, or resamples a model.

suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
  library(readr)
  library(tidyr)
})

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
source(file.path(root, "scripts/pipeline/paths_io.R"))
if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("H10 METRIC-011 figure rebuild requires R 4.6.1", call. = FALSE)
}

producer <- "scripts/hypotheses/H10/build_h10_metric011_figures.R"
figure_dir <- file.path(root, "artifacts/10_figures/H10")
source_dir <- file.path(root, "artifacts/11_source_data/H10")
dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(source_dir, recursive = TRUE, showWarnings = FALSE)

stage2_manifest <- readr::read_csv(
  file.path(root, "artifacts/12_manifests/H10/H10_stage2_artifacts.csv"),
  show_col_types = FALSE,
  progress = FALSE
)
verified_csv <- function(relative_path) {
  record <- stage2_manifest |>
    dplyr::filter(.data$path == .env$relative_path)
  path <- file.path(root, relative_path)
  if (
    nrow(record) != 1L ||
      !file.exists(path) ||
      artifact_sha256(path) != record$sha256[[1L]]
  ) {
    stop("Changed or unregistered H10 figure input: ", relative_path, call. = FALSE)
  }
  readr::read_csv(path, show_col_types = FALSE, progress = FALSE)
}

main_results <- verified_csv(
  "artifacts/09_tables/H10/H10_primary_main_results.csv"
)
paired_results <- verified_csv(
  paste0(
    "artifacts/08_diagnostics/H10/sensitivity/",
    "H10_paired_placement_main_effects.csv"
  )
)
gap_common_results <- verified_csv(
  paste0(
    "artifacts/08_diagnostics/H10/sensitivity/",
    "H10_primary_gap_common_sample_effects.csv"
  )
)
diagnostic_assessment <- verified_csv(
  "artifacts/08_diagnostics/H10/H10_primary_diagnostic_assessment.csv"
)
metric_registry <- verified_csv(
  "artifacts/06_model_data/H10/H10_metric_registry.csv"
)

if (
  nrow(main_results) != 68L ||
    nrow(paired_results) != 136L ||
    nrow(gap_common_results) != 136L ||
    nrow(diagnostic_assessment) != 68L ||
    nrow(metric_registry) != 17L
) {
  stop("An H10 METRIC-011 figure input has an unexpected registry size", call. = FALSE)
}

write_source <- function(data, file) {
  write_csv_artifact(
    data,
    file.path(source_dir, file),
    producer = producer
  )
}

save_plot <- function(plot, stem, width, height) {
  ggplot2::ggsave(
    file.path(figure_dir, paste0(stem, ".png")),
    plot,
    width = width,
    height = height,
    units = "in",
    dpi = 300,
    bg = "white"
  )
  ggplot2::ggsave(
    file.path(figure_dir, paste0(stem, ".pdf")),
    plot,
    width = width,
    height = height,
    units = "in",
    device = grDevices::cairo_pdf,
    bg = "white"
  )
}

save_primary_effect <- function(predictor) {
  source <- main_results |>
    dplyr::filter(.data$predictor == .env$predictor) |>
    dplyr::mutate(
      placement_label = factor(
        .data$placement_label,
        levels = c("Near eye (primary)", "Chest (complementary)")
      ),
      metric_label = factor(
        .data$manuscript_name,
        levels = rev(metric_registry$manuscript_name)
      )
    )
  stem <- if (predictor == "age") {
    "H10_primary_age_associations"
  } else {
    "H10_primary_biological_sex_associations"
  }
  write_source(source, paste0(stem, "_data.csv"))
  plot <- ggplot2::ggplot(
    source,
    ggplot2::aes(
      x = .data$standardized_estimate,
      y = .data$metric_label,
      xmin = .data$standardized_conf_low,
      xmax = .data$standardized_conf_high,
      colour = .data$placement_label,
      shape = .data$placement_label
    )
  ) +
    ggplot2::geom_vline(xintercept = 0, colour = "grey55", linewidth = 0.5) +
    ggplot2::geom_errorbar(
      orientation = "y",
      position = ggplot2::position_dodge(width = 0.55),
      width = 0.18,
      linewidth = 0.55
    ) +
    ggplot2::geom_point(
      position = ggplot2::position_dodge(width = 0.55),
      size = 2.2,
      stroke = 0.85
    ) +
    ggplot2::scale_colour_manual(values = c(
      "Near eye (primary)" = "#0072B2",
      "Chest (complementary)" = "#D55E00"
    )) +
    ggplot2::labs(
      title = if (predictor == "age") {
        "Age associations, adjusted for site"
      } else {
        "Measured biological-sex contrasts, adjusted for site"
      },
      subtitle = if (predictor == "age") {
        "Per 10-year increase; estimates and 95% confidence intervals"
      } else {
        "Female minus Male; estimates and 95% confidence intervals"
      },
      x = "Effect on model scale, divided by the fitted-frame response SD",
      y = NULL,
      colour = NULL,
      shape = NULL,
      caption = paste0(
        "Standardization is for display only; models are separate by placement.\n",
        "Practical-scale estimates, exact denominators, raw p-values, and ",
        "BH-adjusted p-values are retained in the paired source CSV."
      )
    ) +
    ggplot2::theme_minimal(base_size = 10) +
    ggplot2::theme(
      plot.title.position = "plot",
      legend.position = "bottom",
      panel.grid.minor = ggplot2::element_blank(),
      axis.text.y = ggplot2::element_text(size = 8),
      plot.caption = ggplot2::element_text(hjust = 0, size = 7)
    )
  save_plot(plot, stem, 9.4, 8.5)
}

save_primary_effect("age")
save_primary_effect("biological_sex")

paired_source <- paired_results |>
  dplyr::filter(.data$data_scenario == "primary") |>
  dplyr::left_join(
    metric_registry |>
      dplyr::select(.data$metric_id, .data$manuscript_category),
    by = "metric_id",
    relationship = "many-to-one"
  ) |>
  dplyr::mutate(included_in_plot = .data$comparison_status == "ESTIMABLE") |>
  dplyr::select(
    .data$metric_order,
    .data$metric_id,
    .data$manuscript_name,
    .data$abbreviation,
    .data$manuscript_category,
    .data$predictor,
    .data$placement,
    .data$included_in_plot,
    .data$unavailable_reason,
    .data$standardized_estimate,
    .data$standardized_conf_low,
    .data$standardized_conf_high,
    .data$participants,
    .data$participant_days,
    .data$row_key_hash
  ) |>
  tidyr::pivot_wider(
    names_from = .data$placement,
    values_from = c(
      .data$included_in_plot,
      .data$unavailable_reason,
      .data$standardized_estimate,
      .data$standardized_conf_low,
      .data$standardized_conf_high,
      .data$participants,
      .data$participant_days,
      .data$row_key_hash
    )
  ) |>
  dplyr::mutate(
    included_in_plot = .data$included_in_plot_glasses &
      .data$included_in_plot_chest,
    predictor_label = dplyr::if_else(
      .data$predictor == "age",
      "Age per 10 years",
      "Female minus Male"
    )
  )
write_source(paired_source, "H10_paired_placement_effects_data.csv")
paired_plot_data <- paired_source |>
  dplyr::filter(.data$included_in_plot)
paired_limits <- range(c(
  paired_plot_data$standardized_conf_low_glasses,
  paired_plot_data$standardized_conf_high_glasses,
  paired_plot_data$standardized_conf_low_chest,
  paired_plot_data$standardized_conf_high_chest
), finite = TRUE)
paired_plot <- ggplot2::ggplot(
  paired_plot_data,
  ggplot2::aes(
    x = .data$standardized_estimate_glasses,
    y = .data$standardized_estimate_chest,
    colour = .data$manuscript_category
  )
) +
  ggplot2::geom_abline(
    intercept = 0,
    slope = 1,
    linetype = "dashed",
    colour = "grey45"
  ) +
  ggplot2::geom_vline(xintercept = 0, colour = "grey70") +
  ggplot2::geom_hline(yintercept = 0, colour = "grey70") +
  ggplot2::geom_errorbar(
    ggplot2::aes(
      ymin = .data$standardized_conf_low_chest,
      ymax = .data$standardized_conf_high_chest
    ),
    width = 0,
    linewidth = 0.4
  ) +
  ggplot2::geom_errorbar(
    ggplot2::aes(
      xmin = .data$standardized_conf_low_glasses,
      xmax = .data$standardized_conf_high_glasses
    ),
    orientation = "y",
    width = 0,
    linewidth = 0.4
  ) +
  ggplot2::geom_point(size = 2.5, stroke = 0.85) +
  ggplot2::facet_wrap(ggplot2::vars(.data$predictor_label), nrow = 1) +
  ggplot2::coord_equal(xlim = paired_limits, ylim = paired_limits) +
  ggplot2::labs(
    title = "Placement-matched H10 associations",
    subtitle = paste0(
      "Separate near-eye and chest models on identical participant-days; ",
      "15 estimable participant-day metrics"
    ),
    x = "Near-eye standardized model-scale effect",
    y = "Chest standardized model-scale effect",
    colour = "Metric category",
    caption = paste0(
      "Bars are component 95% confidence intervals; the dashed line marks ",
      "identical estimates,\nnot an equivalence margin. IS and IV are not ",
      "shown because paired participant-level estimates are unavailable."
    )
  ) +
  ggplot2::theme_minimal(base_size = 10) +
  ggplot2::theme(
    plot.title.position = "plot",
    legend.position = "bottom",
    legend.text = ggplot2::element_text(size = 8),
    panel.grid.minor = ggplot2::element_blank(),
    plot.caption = ggplot2::element_text(hjust = 0, size = 7)
  ) +
  ggplot2::guides(colour = ggplot2::guide_legend(nrow = 2, byrow = TRUE))
save_plot(paired_plot, "H10_paired_placement_effects", 9.4, 5.8)

gap_source <- gap_common_results |>
  dplyr::select(
    .data$metric_order,
    .data$metric_id,
    .data$manuscript_name,
    .data$abbreviation,
    .data$predictor,
    .data$placement,
    .data$data_scenario,
    .data$standardized_estimate,
    .data$standardized_conf_low,
    .data$standardized_conf_high,
    .data$participants,
    .data$participant_days,
    .data$row_key_hash
  ) |>
  tidyr::pivot_wider(
    names_from = .data$data_scenario,
    values_from = c(
      .data$standardized_estimate,
      .data$standardized_conf_low,
      .data$standardized_conf_high,
      .data$participants,
      .data$participant_days,
      .data$row_key_hash
    )
  ) |>
  dplyr::mutate(
    placement_label = dplyr::if_else(
      .data$placement == "glasses",
      "Near eye",
      "Chest"
    ),
    predictor_label = dplyr::if_else(
      .data$predictor == "age",
      "Age per 10 years",
      "Female minus Male"
    )
  )
write_source(gap_source, "H10_gap_common_sample_effects_data.csv")
gap_limits <- range(c(
  gap_source$standardized_conf_low_primary,
  gap_source$standardized_conf_high_primary,
  gap_source$standardized_conf_low_gap_timing_unaware,
  gap_source$standardized_conf_high_gap_timing_unaware
), finite = TRUE)
gap_plot <- ggplot2::ggplot(
  gap_source,
  ggplot2::aes(
    x = .data$standardized_estimate_primary,
    y = .data$standardized_estimate_gap_timing_unaware,
    colour = .data$placement_label
  )
) +
  ggplot2::geom_abline(
    intercept = 0,
    slope = 1,
    linetype = "dashed",
    colour = "grey45"
  ) +
  ggplot2::geom_vline(xintercept = 0, colour = "grey70") +
  ggplot2::geom_hline(yintercept = 0, colour = "grey70") +
  ggplot2::geom_errorbar(
    ggplot2::aes(
      ymin = .data$standardized_conf_low_gap_timing_unaware,
      ymax = .data$standardized_conf_high_gap_timing_unaware
    ),
    width = 0,
    linewidth = 0.35,
    alpha = 0.65
  ) +
  ggplot2::geom_errorbar(
    ggplot2::aes(
      xmin = .data$standardized_conf_low_primary,
      xmax = .data$standardized_conf_high_primary
    ),
    orientation = "y",
    width = 0,
    linewidth = 0.35,
    alpha = 0.65
  ) +
  ggplot2::geom_point(size = 2.5, stroke = 0.85) +
  ggplot2::facet_wrap(ggplot2::vars(.data$predictor_label), nrow = 1) +
  ggplot2::coord_equal(xlim = gap_limits, ylim = gap_limits) +
  ggplot2::scale_colour_manual(values = c(
    "Near eye" = "#0072B2",
    "Chest" = "#D55E00"
  )) +
  ggplot2::labs(
    title = "Primary and gap-timing-unaware H10 associations",
    subtitle = "Identical within-metric samples; standardized model-scale effects",
    x = "Primary dataset effect",
    y = "Gap-timing-unaware dataset effect",
    colour = "Placement",
    caption = paste0(
      "The gap-timing-unaware dataset applies the 50%-per-hour and 80%-per-day ",
      "coverage rules but does not use the remaining gaps' time of day\n",
      "in metric-specific support decisions. Bars are component 95% confidence ",
      "intervals; the dashed line marks identical estimates."
    )
  ) +
  ggplot2::theme_minimal(base_size = 10) +
  ggplot2::theme(
    plot.title.position = "plot",
    legend.position = "bottom",
    panel.grid.minor = ggplot2::element_blank(),
    plot.caption = ggplot2::element_text(hjust = 0, size = 7)
  )
save_plot(gap_plot, "H10_gap_common_sample_effects", 9.4, 5.8)

diagnostic_source <- diagnostic_assessment |>
  dplyr::mutate(
    metric_label = factor(
      .data$manuscript_name,
      levels = rev(metric_registry$manuscript_name)
    ),
    model_label = factor(
      paste(
        dplyr::if_else(.data$placement == "glasses", "Near eye", "Chest"),
        dplyr::if_else(
          .data$predictor == "age",
          "Age",
          "Female-Male"
        ),
        sep = " | "
      ),
      levels = c(
        "Near eye | Age",
        "Near eye | Female-Male",
        "Chest | Age",
        "Chest | Female-Male"
      )
    )
  )
write_source(diagnostic_source, "H10_diagnostic_assessment_data.csv")
diagnostic_plot <- ggplot2::ggplot(
  diagnostic_source,
  ggplot2::aes(
    x = .data$model_label,
    y = .data$metric_label,
    fill = .data$final_assessment
  )
) +
  ggplot2::geom_tile(colour = "white", linewidth = 0.7) +
  ggplot2::scale_fill_manual(values = c(
    "acceptable" = "#66C2A5",
    "acceptable with specified limitations" = "#FDC086",
    "not acceptable for inference" = "#E78AC3"
  ), drop = FALSE) +
  ggplot2::labs(
    title = "H10 diagnostic acceptance assessment",
    subtitle = paste0(
      "Convergence, distributional, residual, temporal, participant-influence, ",
      "and leave-one-site-out evidence"
    ),
    x = NULL,
    y = NULL,
    fill = "Assessment",
    caption = paste0(
      "Each tile is an explicit model-level assessment.\nNumerical values, ",
      "threshold flags, and interpretations are retained in the paired source CSV."
    )
  ) +
  ggplot2::theme_minimal(base_size = 10) +
  ggplot2::theme(
    plot.title.position = "plot",
    legend.position = "bottom",
    panel.grid = ggplot2::element_blank(),
    axis.text.x = ggplot2::element_text(angle = 20, hjust = 1),
    axis.text.y = ggplot2::element_text(size = 8),
    plot.caption = ggplot2::element_text(hjust = 0, size = 7)
  )
save_plot(diagnostic_plot, "H10_diagnostic_assessment", 9.4, 8.2)

message("H10 METRIC-011 affected figure/source pairs rebuilt")
