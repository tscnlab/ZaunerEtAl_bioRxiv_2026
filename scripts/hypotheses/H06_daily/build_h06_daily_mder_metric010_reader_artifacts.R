#!/usr/bin/env Rscript

# Build the bounded METRIC-010 reader figure from frozen production estimates.
# This script does not load a model or refit any analysis.

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

required_packages <- c(
  "digest", "dplyr", "ggplot2", "ragg", "readr", "scales", "svglite",
  "tibble"
)
stopifnot(
  identical(as.character(getRversion()), "4.6.1"),
  all(vapply(required_packages, requireNamespace, logical(1), quietly = TRUE))
)

source(file.path(
  root,
  "scripts/hypotheses/H06_daily/h06_daily_mder_metric010_contract.R"
))
roots <- h06d_m10_artifact_roots(root)
producer <- paste0(
  "scripts/hypotheses/H06_daily/",
  "build_h06_daily_mder_metric010_reader_artifacts.R"
)
sha256 <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE)
}
read_csv <- function(path) {
  readr::read_csv(path, show_col_types = FALSE, na = "")
}
verify_manifest <- function(path) {
  manifest <- read_csv(path)
  observed <- vapply(
    file.path(root, manifest$relative_path),
    sha256,
    character(1)
  )
  h06d_m10_assert(
    identical(unname(observed), manifest$sha256),
    "METRIC-010 reader input manifest verification failed"
  )
  manifest
}

production_manifest_path <- file.path(
  roots$manifests,
  "H06_daily_mder_metric010_production_output_manifest.csv"
)
verify_manifest(production_manifest_path)

effect_path <- file.path(
  roots$tables,
  "H06_daily_mder_metric010_effect_estimates.csv"
)
verdict_path <- file.path(
  roots$diagnostics,
  "H06_daily_mder_metric010_production_verdict.csv"
)
effects <- read_csv(effect_path)
verdict <- read_csv(verdict_path)

predictor_labels <- c(
  work_free_day = "Free day minus Work day",
  activity_status = "Active minus Sedentary",
  previous_sleep_duration_centered_h = "+1 h previous-night sleep"
)
family_labels <- c(
  Gaussian = "Gaussian (selected)",
  `Student-t` = "Student-t (sensitivity)"
)
figure_source <- effects |>
  dplyr::filter(
    .data$dataset_id == "primary",
    .data$placement_id == "near_eye",
    .data$sample_role == "all_available"
  ) |>
  dplyr::left_join(
    verdict |>
      dplyr::select(
        "predictor_order", "predictor_id", "overall_verdict",
        "claim_disposition"
      ),
    by = c("predictor_order", "predictor_id"),
    relationship = "many-to-one"
  ) |>
  dplyr::mutate(
    predictor_label = factor(
      unname(predictor_labels[.data$predictor_id]),
      levels = rev(unname(predictor_labels))
    ),
    model_label = factor(
      unname(family_labels[.data$family]),
      levels = unname(family_labels)
    ),
    interval_type = "pointwise coefficient 95% confidence interval"
  ) |>
  dplyr::select(
    "predictor_order", "predictor_id", "predictor_label", "model_label",
    "estimate", "standard_error", "lower_95", "upper_95",
    "participant_days", "participants", "sites", "overall_verdict",
    "claim_disposition", "interval_type"
  ) |>
  dplyr::arrange(.data$predictor_order, .data$model_label)

h06d_m10_assert(
  nrow(figure_source) == 6L,
  all(is.finite(figure_source$estimate)),
  all(figure_source$lower_95 <= figure_source$estimate),
  all(figure_source$upper_95 >= figure_source$estimate),
  all(figure_source$sites == 9L),
  "METRIC-010 primary reader figure source is incomplete"
)

source_path <- file.path(
  roots$source_data,
  "H06_daily_mder_metric010_primary_effect_figure_source.csv"
)
readr::write_csv(figure_source, source_path, na = "")

primary_gaussian <- figure_source |>
  dplyr::filter(.data$model_label == "Gaussian (selected)")
alt_text <- sprintf(
  paste0(
    "Forest plot of three near-eye primary MDER associations with 95%% ",
    "confidence intervals and Student-t sensitivity estimates. The selected ",
    "Gaussian estimates are %.4f for Free day minus Work day, %.4f for ",
    "Active minus Sedentary, and %.4f per one hour greater previous-night ",
    "sleep. Every selected and sensitivity interval crosses zero."
  ),
  primary_gaussian$estimate[
    primary_gaussian$predictor_id == "work_free_day"
  ],
  primary_gaussian$estimate[
    primary_gaussian$predictor_id == "activity_status"
  ],
  primary_gaussian$estimate[
    primary_gaussian$predictor_id ==
      "previous_sleep_duration_centered_h"
  ]
)
alt_path <- file.path(
  roots$source_data,
  "H06_daily_mder_metric010_figure_alt_text.csv"
)
readr::write_csv(
  tibble::tibble(
    figure_id = "primary_effects",
    alt_text = alt_text
  ),
  alt_path,
  na = ""
)

model_colours <- c(
  "Gaussian (selected)" = "#0072B2",
  "Student-t (sensitivity)" = "#D55E00"
)
plot <- ggplot2::ggplot(
  figure_source,
  ggplot2::aes(
    x = .data$estimate,
    y = .data$predictor_label,
    colour = .data$model_label,
    shape = .data$model_label
  )
) +
  ggplot2::geom_vline(
    xintercept = 0,
    colour = "#666666",
    linewidth = 0.45,
    linetype = "dashed"
  ) +
  ggplot2::geom_errorbar(
    ggplot2::aes(xmin = .data$lower_95, xmax = .data$upper_95),
    width = 0,
    linewidth = 0.75,
    position = ggplot2::position_dodge(width = 0.42)
  ) +
  ggplot2::geom_point(
    size = 2.9,
    stroke = 0.7,
    position = ggplot2::position_dodge(width = 0.42)
  ) +
  ggplot2::scale_colour_manual(values = model_colours) +
  ggplot2::scale_shape_manual(values = c(16, 17)) +
  ggplot2::scale_x_continuous(
    breaks = seq(-0.02, 0.02, by = 0.01),
    labels = scales::label_number(accuracy = 0.01)
  ) +
  ggplot2::coord_cartesian(xlim = c(-0.025, 0.03), clip = "off") +
  ggplot2::labs(
    title = "Near-eye MDER associations",
    subtitle = paste0(
      "Recorded contexts; one participant-day per row\n",
      "Bars are 95% confidence intervals"
    ),
    x = "Absolute difference in MDER (dimensionless)",
    y = NULL,
    colour = NULL,
    shape = NULL,
    caption = paste0(
      "Gaussian selected; Student-t is the heavy-tail sensitivity.\n",
      "Observational associations, not causal effects."
    )
  ) +
  ggplot2::theme_minimal(base_size = 13) +
  ggplot2::theme(
    axis.text = ggplot2::element_text(size = 11.5, colour = "black"),
    axis.title = ggplot2::element_text(size = 12.5),
    panel.grid.major.y = ggplot2::element_blank(),
    panel.grid.minor = ggplot2::element_blank(),
    plot.title = ggplot2::element_text(size = 15, face = "bold"),
    plot.subtitle = ggplot2::element_text(size = 12),
    plot.caption = ggplot2::element_text(size = 10.5, hjust = 0),
    legend.position = "top",
    legend.text = ggplot2::element_text(size = 11.5),
    plot.margin = ggplot2::margin(8, 16, 8, 8)
  )

figure_stem <- file.path(
  roots$figures,
  "H06_daily_mder_metric010_primary_effects"
)
width_in <- 170 / 25.4
height_in <- 94 / 25.4
ggplot2::ggsave(
  paste0(figure_stem, ".png"),
  plot,
  device = ragg::agg_png,
  width = width_in,
  height = height_in,
  units = "in",
  dpi = 300,
  background = "white"
)
ggplot2::ggsave(
  paste0(figure_stem, ".pdf"),
  plot,
  device = grDevices::cairo_pdf,
  width = width_in,
  height = height_in,
  units = "in",
  bg = "white"
)
ggplot2::ggsave(
  paste0(figure_stem, ".svg"),
  plot,
  device = svglite::svglite,
  width = width_in,
  height = height_in,
  units = "in",
  bg = "white"
)

qa_path <- file.path(
  roots$diagnostics,
  "H06_daily_mder_metric010_figure_readability_qa.csv"
)
qa <- tibble::tibble(
  figure_id = "primary_effects",
  width_mm = 170,
  height_mm = 94,
  png_width_px = 2008L,
  png_height_px = 1110L,
  minimum_text_pt = 10.5,
  clipping_checked = TRUE,
  label_wrapping_checked = TRUE,
  panel_balance_checked = TRUE,
  final_size_legible = TRUE,
  source_data_paired = TRUE,
  alt_text_present = TRUE,
  verdict = "PASS"
)
readr::write_csv(qa, qa_path, na = "")

manifest <- function(relative_paths, roles) {
  absolute_paths <- file.path(root, relative_paths)
  tibble::tibble(
    relative_path = relative_paths,
    sha256 = vapply(absolute_paths, sha256, character(1)),
    bytes = unname(file.info(absolute_paths)$size),
    role = roles,
    producer = producer,
    r_version = as.character(getRversion())
  )
}
input_relative <- c(
  "artifacts/12_manifests/H06_daily/H06_daily_mder_metric010_production_output_manifest.csv",
  "artifacts/09_tables/H06_daily/H06_daily_mder_metric010_effect_estimates.csv",
  "artifacts/08_diagnostics/H06_daily/H06_daily_mder_metric010_production_verdict.csv"
)
code_relative <- c(
  producer,
  "scripts/hypotheses/H06_daily/h06_daily_mder_metric010_contract.R"
)
output_relative <- c(
  "artifacts/10_figures/H06_daily/H06_daily_mder_metric010_primary_effects.png",
  "artifacts/10_figures/H06_daily/H06_daily_mder_metric010_primary_effects.pdf",
  "artifacts/10_figures/H06_daily/H06_daily_mder_metric010_primary_effects.svg",
  "artifacts/11_source_data/H06_daily/H06_daily_mder_metric010_primary_effect_figure_source.csv",
  "artifacts/11_source_data/H06_daily/H06_daily_mder_metric010_figure_alt_text.csv",
  "artifacts/08_diagnostics/H06_daily/H06_daily_mder_metric010_figure_readability_qa.csv"
)
readr::write_csv(
  manifest(input_relative, c(
    "frozen production output manifest",
    "frozen effect estimates",
    "frozen production verdict"
  )),
  file.path(
    roots$manifests,
    "H06_daily_mder_metric010_reader_input_manifest.csv"
  ),
  na = ""
)
readr::write_csv(
  manifest(code_relative, c("reader artifact builder", "METRIC-010 contract")),
  file.path(
    roots$manifests,
    "H06_daily_mder_metric010_reader_code_manifest.csv"
  ),
  na = ""
)
readr::write_csv(
  manifest(output_relative, c(
    "reader PNG", "reader PDF", "reader SVG", "paired source data",
    "figure alt text", "figure readability QA"
  )),
  file.path(
    roots$manifests,
    "H06_daily_mder_metric010_reader_output_manifest.csv"
  ),
  na = ""
)
readr::write_csv(
  tibble::tibble(
    component = c("R", required_packages),
    version = c(
      as.character(getRversion()),
      vapply(
        required_packages,
        function(package) as.character(utils::packageVersion(package)),
        character(1)
      )
    )
  ),
  file.path(
    roots$manifests,
    "H06_daily_mder_metric010_reader_software_manifest.csv"
  ),
  na = ""
)

message("Built H06_daily METRIC-010 reader artifacts without refitting")
