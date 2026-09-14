#!/usr/bin/env Rscript

# Build descriptive displays for the H10 preparation companion from frozen
# model-frame indexes and reader source data. No model is fit, refit, predicted
# from, simulated, or resampled.

suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
  library(readr)
  library(scales)
  library(tibble)
})

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
source(file.path(root, "scripts/pipeline/paths_io.R"))

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop(
    sprintf(
      "H10 preparation artifacts require R 4.6.1; running %s",
      getRversion()
    ),
    call. = FALSE
  )
}

producer <- paste0(
  "scripts/hypotheses/H10/",
  "build_h10_preparation_artifacts.R"
)
stage2_manifest <- readr::read_csv(
  file.path(
    root,
    "artifacts/12_manifests/H10/H10_stage2_artifacts.csv"
  ),
  show_col_types = FALSE
)
stage3_manifest <- readr::read_csv(
  file.path(
    root,
    "artifacts/12_manifests/H10/H10_stage3_artifacts.csv"
  ),
  show_col_types = FALSE
)

verified_path <- function(relative_path, manifest) {
  manifest_row <- manifest |>
    filter(.data$path == .env$relative_path)
  if (nrow(manifest_row) != 1L) {
    stop(
      paste0("The frozen H10 inventory does not identify ", relative_path),
      call. = FALSE
    )
  }
  path <- file.path(root, relative_path)
  if (!file.exists(path)) {
    stop(paste0("Missing frozen H10 artifact: ", relative_path), call. = FALSE)
  }
  if (!identical(artifact_sha256(path), manifest_row$sha256[[1L]])) {
    stop(
      paste0("Frozen H10 artifact identity changed: ", relative_path),
      call. = FALSE
    )
  }
  path
}

read_verified_csv <- function(relative_path, manifest) {
  readr::read_csv(
    verified_path(relative_path, manifest),
    show_col_types = FALSE,
    progress = FALSE
  )
}

frame_index <- read_verified_csv(
  "artifacts/06_model_data/H10/H10_model_frame_index.csv",
  stage2_manifest
)
metric_registry <- read_verified_csv(
  "artifacts/06_model_data/H10/H10_metric_registry.csv",
  stage2_manifest
)
reader_source <- read_verified_csv(
  paste0(
    "artifacts/11_source_data/H10/",
    "H10_age_site_significant_associations_data.csv"
  ),
  stage3_manifest
)
site_registry <- read_verified_csv(
  "config/site_display_registry.csv",
  stage3_manifest
) |>
  arrange(.data$display_order)

placement_names <- c(
  glasses = "Near eye (primary)",
  chest = "Chest (complementary)"
)
placement_colors <- c(
  glasses = "#0072B2",
  chest = "#D55E00"
)
site_colors <- stats::setNames(site_registry$color_hex, site_registry$site)

age_distribution <- reader_source |>
  filter(.data$panel == "age_distribution") |>
  select(
    "placement",
    "placement_label",
    "site",
    "site_display_order",
    "site_display_name",
    "site_color_hex",
    "participant_display_index",
    "age",
    "biological_sex"
  ) |>
  arrange(
    match(.data$placement, c("glasses", "chest")),
    .data$site_display_order,
    .data$age,
    .data$participant_display_index
  )

age_counts <- age_distribution |>
  count(.data$placement, name = "participants") |>
  arrange(match(.data$placement, c("glasses", "chest")))
if (
  nrow(age_distribution) != 295L ||
    !identical(age_counts$participants, c(141L, 154L)) ||
    anyDuplicated(age_distribution[
      c("placement", "site", "participant_display_index")
    ]) ||
    anyNA(age_distribution)
) {
  stop("Invalid H10 preparation age-distribution data", call. = FALSE)
}

base_observations <- c(glasses = 816, chest = 902)
base_participants <- c(glasses = 141, chest = 154)
sample_support <- frame_index |>
  filter(.data$data_scenario == "primary") |>
  left_join(
    metric_registry |>
      select("metric_id", "display_analysis_unit", "display_unit"),
    by = "metric_id",
    relationship = "many-to-one"
  ) |>
  mutate(
    placement_label = unname(placement_names[.data$placement]),
    analysis_unit_label = if_else(
      .data$analysis_unit == "participant",
      "Participant-level metrics",
      "Participant-day metrics"
    ),
    base_rows = if_else(
      .data$analysis_unit == "participant",
      unname(base_participants[.data$placement]),
      unname(base_observations[.data$placement])
    ),
    retention_fraction = .data$observations / .data$base_rows,
    rows_not_fitted = .data$base_rows - .data$observations
  ) |>
  select(
    "placement",
    "placement_label",
    "metric_order",
    "metric_id",
    "manuscript_name",
    "analysis_unit",
    "analysis_unit_label",
    "display_unit",
    "observations",
    "base_rows",
    "retention_fraction",
    "rows_not_fitted",
    "participants",
    "participant_days",
    "contributing_participant_days",
    "metric_support_valid_hours",
    "metric_support_expected_hours",
    "sites",
    "female_participants",
    "male_participants",
    "age_min",
    "age_max",
    "row_key_hash",
    "model_frame_sha256"
  ) |>
  arrange(.data$metric_order, match(.data$placement, c("glasses", "chest")))

if (
  nrow(sample_support) != 34L ||
    anyDuplicated(sample_support[c("placement", "metric_id")]) ||
    any(sample_support$retention_fraction <= 0) ||
    any(sample_support$retention_fraction > 1) ||
    !all(sample_support$sites %in% c(8L, 9L))
) {
  stop("Invalid H10 preparation sample-support data", call. = FALSE)
}

source_dir <- file.path(root, "artifacts/11_source_data/H10")
figure_dir <- file.path(root, "artifacts/10_figures/H10")
dir.create(source_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)

age_source_path <- file.path(
  source_dir,
  "H10_preparation_age_distribution_data.csv"
)
support_source_path <- file.path(
  source_dir,
  "H10_preparation_sample_support_data.csv"
)
invisible(write_csv_artifact(age_distribution, age_source_path, producer))
invisible(write_csv_artifact(sample_support, support_source_path, producer))

age_plot_data <- age_distribution |>
  mutate(
    placement_label = factor(
      .data$placement_label,
      levels = unname(placement_names[c("glasses", "chest")])
    ),
    site_display_name = factor(
      .data$site_display_name,
      levels = rev(site_registry$display_name)
    )
  )

age_plot <- ggplot(
  age_plot_data,
  aes(x = .data$age, y = .data$site_display_name)
) +
  geom_boxplot(
    aes(color = .data$site),
    width = 0.56,
    outlier.shape = NA,
    linewidth = 0.65,
    show.legend = FALSE
  ) +
  geom_jitter(
    aes(color = .data$site, shape = .data$biological_sex),
    width = 0,
    height = 0.12,
    alpha = 0.68,
    size = 1.35,
    stroke = 0,
    show.legend = c(color = FALSE, shape = TRUE)
  ) +
  facet_wrap(~placement_label, ncol = 2) +
  scale_color_manual(values = site_colors, drop = FALSE) +
  scale_shape_manual(
    values = c(Female = 16, Male = 17),
    name = "Measured biological sex"
  ) +
  scale_x_continuous(
    breaks = seq(20, 70, 10),
    limits = c(17, 70),
    expand = expansion(mult = c(0.01, 0.01))
  ) +
  labs(x = "Age (years)", y = NULL) +
  theme_minimal(base_size = 10) +
  theme(
    panel.grid.minor = element_blank(),
    panel.grid.major.y = element_blank(),
    strip.text = element_text(face = "bold", size = 10),
    axis.text = element_text(size = 9),
    axis.title = element_text(size = 10),
    legend.position = "bottom",
    legend.title = element_text(size = 9),
    legend.text = element_text(size = 9),
    plot.margin = margin(8, 10, 8, 10)
  )

sample_plot_data <- sample_support |>
  mutate(
    placement_label = factor(
      .data$placement_label,
      levels = unname(placement_names[c("glasses", "chest")])
    ),
    analysis_unit_label = factor(
      .data$analysis_unit_label,
      levels = c("Participant-level metrics", "Participant-day metrics")
    ),
    metric_label = factor(
      .data$manuscript_name,
      levels = rev(metric_registry$manuscript_name)
    )
  )

sample_plot <- ggplot(
  sample_plot_data,
  aes(
    x = .data$retention_fraction,
    y = .data$metric_label,
    color = .data$placement,
    shape = .data$placement
  )
) +
  geom_vline(xintercept = 1, color = "grey70", linewidth = 0.45) +
  geom_point(
    position = position_dodge(width = 0.5),
    size = 2.25,
    stroke = 0.3
  ) +
  facet_grid(
    rows = vars(analysis_unit_label),
    scales = "free_y",
    space = "free_y"
  ) +
  scale_color_manual(
    values = placement_colors,
    breaks = c("glasses", "chest"),
    labels = unname(placement_names[c("glasses", "chest")]),
    name = "Placement"
  ) +
  scale_shape_manual(
    values = c(glasses = 16, chest = 17),
    breaks = c("glasses", "chest"),
    labels = unname(placement_names[c("glasses", "chest")]),
    name = "Placement"
  ) +
  scale_x_continuous(
    labels = label_percent(accuracy = 1),
    breaks = seq(0.7, 1, 0.1),
    limits = c(0.7, 1.01),
    expand = expansion(mult = c(0.01, 0.01))
  ) +
  scale_y_discrete(
    labels = function(x) stringr::str_wrap(x, width = 34)
  ) +
  labs(
    x = "Fitted observations as a proportion of placement base rows",
    y = NULL
  ) +
  theme_minimal(base_size = 10) +
  theme(
    panel.grid.minor = element_blank(),
    panel.grid.major.y = element_blank(),
    strip.text.y = element_text(face = "bold", size = 9),
    axis.text = element_text(size = 8.5),
    axis.title = element_text(size = 10),
    legend.position = "bottom",
    legend.title = element_text(size = 9),
    legend.text = element_text(size = 9),
    plot.margin = margin(8, 12, 8, 10)
  )

save_figure <- function(plot, stem, width, height) {
  png_path <- file.path(figure_dir, paste0(stem, ".png"))
  pdf_path <- file.path(figure_dir, paste0(stem, ".pdf"))
  ggplot2::ggsave(
    filename = png_path,
    plot = plot,
    width = width,
    height = height,
    units = "in",
    dpi = 300,
    bg = "white"
  )
  ggplot2::ggsave(
    filename = pdf_path,
    plot = plot,
    width = width,
    height = height,
    units = "in",
    device = grDevices::cairo_pdf,
    bg = "white"
  )
}

save_figure(
  age_plot,
  "H10_preparation_age_distribution",
  width = 9.4,
  height = 5.2
)
save_figure(
  sample_plot,
  "H10_preparation_sample_support",
  width = 9.4,
  height = 8.2
)

message(
  "Built H10 preparation displays from ",
  nrow(age_distribution),
  " participant rows and ",
  nrow(sample_support),
  " metric-placement sample records"
)
