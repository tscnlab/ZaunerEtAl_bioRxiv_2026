#!/usr/bin/env Rscript

# Refresh only Stage 2 displays whose stored source contains primary L10
# results updated under METRIC-011. No model, diagnostic, or sensitivity is
# calculated here.

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

suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
  library(readr)
  library(scales)
  library(stringr)
  library(tidyr)
})
source(file.path(root, "scripts/pipeline/paths_io.R"))

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("H05 METRIC-011 display refresh requires R 4.6.1", call. = FALSE)
}

producer <- "scripts/hypotheses/H05/build_h05_metric011_displays.R"
read_h05 <- function(path) {
  readr::read_csv(file.path(root, path), show_col_types = FALSE, na = "")
}
write_h05 <- function(data, path) {
  invisible(write_csv_artifact(
    data,
    file.path(root, path),
    producer = producer
  ))
}

scientific_manifest_path <- file.path(
  root,
  paste0(
    "artifacts/12_manifests/H05/",
    "H05_metric011_artifact_update_manifest.csv"
  )
)
scientific_manifest <- readr::read_csv(
  scientific_manifest_path,
  show_col_types = FALSE
)
required_inputs <- c(
  "artifacts/09_tables/H05/H05_model_results_master.csv",
  "artifacts/09_tables/H05/H05_paired_placement_comparison.csv"
)
input_rows <- scientific_manifest |>
  filter(.data$path %in% .env$required_inputs) |>
  arrange(match(.data$path, required_inputs))
if (
  nrow(input_rows) != length(required_inputs) ||
    !identical(input_rows$path, required_inputs) ||
    !identical(
      unname(vapply(
        file.path(root, input_rows$path),
        artifact_sha256,
        character(1)
      )),
      input_rows$sha256
    )
) {
  stop("A sealed METRIC-011 display input changed", call. = FALSE)
}

master <- read_h05(required_inputs[[1L]])
paired_effects <- read_h05(required_inputs[[2L]])
primary_master <- master |>
  filter(.data$run_id == "main__glasses__all_available")
if (nrow(primary_master) != 68L || nrow(paired_effects) != 68L) {
  stop("The H05 display inputs are incomplete", call. = FALSE)
}

primary_figure_data <- primary_master |>
  mutate(
    metric_display = factor(
      .data$manuscript_name,
      levels = rev(unique(
        .data$manuscript_name[order(.data$metric_order)]
      ))
    ),
    factor_display = paste0(
      str_to_upper(str_remove(.data$factor_id, "leba_")),
      ": ",
      .data$factor_label
    ),
    factor_display = factor(
      .data$factor_display,
      levels = unique(.data$factor_display[order(.data$factor_order)])
    ),
    effect_label = if_else(
      .data$effect_type %in% c("ratio", "odds_ratio"),
      sprintf("x%.2f", .data$estimate_practical_per_sd),
      sprintf("%+.2f", .data$estimate_practical_per_sd)
    ),
    q_label = ifelse(
      .data$p_adjusted <= 0.05,
      paste0("q=", scales::pvalue(.data$p_adjusted, accuracy = 0.001)),
      ""
    )
  )
write_h05(
  primary_figure_data,
  "artifacts/11_source_data/H05/H05_primary_effect_overview_data.csv"
)

effect_limit <- max(
  abs(primary_figure_data$estimate_model_per_sd),
  na.rm = TRUE
)
primary_plot <- ggplot(
  primary_figure_data,
  aes(x = .data$factor_display, y = .data$metric_display)
) +
  geom_tile(
    aes(fill = .data$estimate_model_per_sd),
    colour = "white",
    linewidth = 0.4
  ) +
  geom_tile(
    data = primary_figure_data[
      primary_figure_data$p_adjusted <= 0.05,
      ,
      drop = FALSE
    ],
    fill = NA,
    colour = "black",
    linewidth = 1.1
  ) +
  geom_text(
    aes(label = paste(.data$effect_label, .data$q_label, sep = "\n")),
    size = 2.4,
    lineheight = 0.9
  ) +
  scale_fill_gradient2(
    low = "#3B4CC0",
    mid = "white",
    high = "#B40426",
    midpoint = 0,
    limits = c(-effect_limit, effect_limit),
    name = "Model-scale effect\nper LEBA SD"
  ) +
  labs(
    title = "H05 primary fixed-site effects",
    subtitle = paste0(
      "Cell text is the reader-scale effect per participant SD of LEBA; ",
      "black borders mark BH-adjusted p <= 0.050"
    ),
    x = NULL,
    y = NULL
  ) +
  theme_minimal(base_size = 10) +
  theme(
    panel.grid = element_blank(),
    axis.text.x = element_text(angle = 30, hjust = 1),
    plot.title.position = "plot"
  )
ggsave(
  file.path(root, "artifacts/10_figures/H05/H05_primary_effect_overview.png"),
  primary_plot,
  width = 11,
  height = 9,
  dpi = 300
)
ggsave(
  file.path(root, "artifacts/10_figures/H05/H05_primary_effect_overview.pdf"),
  primary_plot,
  width = 11,
  height = 9
)

adequacy_figure_data <- primary_figure_data
write_h05(
  adequacy_figure_data,
  "artifacts/11_source_data/H05/H05_primary_adequacy_overview_data.csv"
)
adequacy_plot <- ggplot(
  adequacy_figure_data,
  aes(x = .data$factor_display, y = .data$metric_display)
) +
  geom_tile(
    aes(fill = .data$model_adequacy),
    colour = "white",
    linewidth = 0.4
  ) +
  scale_fill_manual(
    values = c(
      acceptable = "#009E73",
      acceptable_with_specified_limitations = "#E69F00",
      not_acceptable = "#D55E00"
    ),
    labels = c(
      acceptable = "Acceptable",
      acceptable_with_specified_limitations = "Acceptable with specified limitations",
      not_acceptable = "Not acceptable"
    ),
    name = "Adequacy"
  ) +
  labs(
    title = "H05 primary model-adequacy classifications",
    subtitle = paste0(
      "Every factor-metric model is classified using the approved fit, ",
      "residual, support, and dependence checks"
    ),
    x = NULL,
    y = NULL
  ) +
  theme_minimal(base_size = 10) +
  theme(
    panel.grid = element_blank(),
    axis.text.x = element_text(angle = 30, hjust = 1),
    plot.title.position = "plot"
  )
ggsave(
  file.path(root, "artifacts/10_figures/H05/H05_primary_model_adequacy.png"),
  adequacy_plot,
  width = 11,
  height = 8.5,
  dpi = 300
)

paired_near_samples <- master |>
  filter(.data$run_id == "main__glasses__paired_common_sample") |>
  select(all_of(c(
    "metric_id",
    "factor_id",
    "analysis_unit",
    "observations",
    "participants",
    "participant_days",
    "represented_days",
    "sites",
    "model_frame_hash"
  ))) |>
  distinct() |>
  rename(
    analysis_unit__near_eye = "analysis_unit",
    observations__near_eye = "observations",
    participants__near_eye = "participants",
    participant_days__near_eye = "participant_days",
    represented_days__near_eye = "represented_days",
    sites__near_eye = "sites",
    model_frame_hash__near_eye = "model_frame_hash"
  )
paired_chest_samples <- master |>
  filter(.data$run_id == "main__chest__paired_common_sample") |>
  select(all_of(c(
    "metric_id",
    "factor_id",
    "analysis_unit",
    "observations",
    "participants",
    "participant_days",
    "represented_days",
    "sites",
    "model_frame_hash"
  ))) |>
  distinct() |>
  rename(
    analysis_unit__chest = "analysis_unit",
    observations__chest = "observations",
    participants__chest = "participants",
    participant_days__chest = "participant_days",
    represented_days__chest = "represented_days",
    sites__chest = "sites",
    model_frame_hash__chest = "model_frame_hash"
  )
paired_display <- paired_effects |>
  left_join(
    paired_near_samples,
    by = c("metric_id", "factor_id"),
    relationship = "many-to-one"
  ) |>
  left_join(
    paired_chest_samples,
    by = c("metric_id", "factor_id"),
    relationship = "many-to-one"
  ) |>
  mutate(
    comparison_scale = paste(
      "Model-scale coefficient per participant SD of the matched LEBA factor;",
      "near eye on x and chest on y; null = 0"
    ),
    exact_sample_match = .data$observations__near_eye ==
      .data$observations__chest &
      .data$participants__near_eye == .data$participants__chest &
      coalesce(
        .data$participant_days__near_eye == .data$participant_days__chest,
        is.na(.data$participant_days__near_eye) &
          is.na(.data$participant_days__chest)
      ) &
      .data$sites__near_eye == .data$sites__chest
  )
if (nrow(paired_display) != 68L || any(!paired_display$exact_sample_match)) {
  stop(
    "The METRIC-011 paired display lacks an exact matched sample",
    call. = FALSE
  )
}
write_h05(
  paired_display,
  "artifacts/11_source_data/H05/H05_paired_effect_comparison_data.csv"
)

paired_plot_data <- paired_display |>
  mutate(
    factor_label = factor(
      .data$factor_label,
      levels = unique(.data$factor_label[order(.data$factor_order)])
    )
  )
paired_limit <- 1.08 *
  max(
    abs(c(
      paired_plot_data$estimate_model_per_sd__glasses,
      paired_plot_data$estimate_model_per_sd__chest
    )),
    na.rm = TRUE
  )
paired_plot <- ggplot(
  paired_plot_data,
  aes(
    x = .data$estimate_model_per_sd__glasses,
    y = .data$estimate_model_per_sd__chest
  )
) +
  geom_hline(yintercept = 0, colour = "grey65", linewidth = 0.45) +
  geom_vline(xintercept = 0, colour = "grey65", linewidth = 0.45) +
  geom_abline(
    slope = 1,
    intercept = 0,
    linetype = 2,
    colour = "black",
    linewidth = 0.55
  ) +
  geom_point(alpha = 0.85, size = 2.1, colour = "#0072B2") +
  facet_wrap(~factor_label) +
  coord_equal(
    xlim = c(-paired_limit, paired_limit),
    ylim = c(-paired_limit, paired_limit)
  ) +
  labs(
    title = "Paired/common-sample near-eye and chest effects",
    subtitle = paste0(
      "Matched estimands: 107–112 participants, 489–643 participant-days, ",
      "and 8 sites"
    ),
    x = "Near-eye estimate",
    y = "Chest estimate",
    caption = paste0(
      "The dashed line is identity and grey lines mark the null. ",
      "Closeness does not establish equivalence."
    )
  ) +
  theme_minimal(base_size = 11) +
  theme(
    plot.title.position = "plot",
    plot.caption.position = "plot",
    plot.caption = element_text(hjust = 0)
  )
ggsave(
  file.path(root, "artifacts/10_figures/H05/H05_paired_placement_effects.png"),
  paired_plot,
  width = 10,
  height = 7.5,
  dpi = 300
)

message(
  "H05 METRIC-011 display refresh complete: two primary source tables, ",
  "one paired source table, and four display files; no scientific ",
  "computation was run."
)
