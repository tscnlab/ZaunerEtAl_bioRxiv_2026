#!/usr/bin/env Rscript

# Candidate-only native SVG export for REPORT-018 Order 72, H08 S14.
# This script reads only the frozen plotting CSV and metric-order registry.

suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
  library(readr)
})

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("Order 72 requires R 4.6.1.", call. = FALSE)
}

project_root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
evidence_root <- file.path(
  project_root,
  "audit/hypotheses/H08/report018_order72_svg_export"
)
candidate_path <- file.path(
  evidence_root,
  "candidate/H08_near_eye_effects.svg"
)

if (file.exists(candidate_path)) {
  stop("The candidate endpoint already exists.", call. = FALSE)
}

pins <- tibble::tribble(
  ~path, ~sha256, ~bytes,
  "artifacts/10_figures/H08/H08_near_eye_effects.png",
  "f1cc8e33829cdf821140e95238d20b1516d5796f741002a1f27568d3f9fd7405",
  140448,
  "artifacts/10_figures/H08/H08_near_eye_effects.pdf",
  "4f5b3201703036fa5320433c6e600f8cc8ba84b20b6015f89ccac517381415fe",
  5823,
  "artifacts/11_source_data/H08/H08_near_eye_effects_data.csv",
  "0f7ab7b06a23a16089b000607d4cfb239c323ba39df9c549c365c4da1878dd51",
  10662,
  "artifacts/06_model_data/H08/H08_metric_registry.csv",
  "ba60163a1248a03c6c95cfa36fc0b66801f1fdd4af2fa114e024944c2aa3893f",
  2786,
  "scripts/hypotheses/H08/rebuild_h08_reader_figures.R",
  "96be883521683fbb951b715dd14b5eb1b6986abd5cfdf60f21fecc4e8857302c",
  13103
)

pin_paths <- file.path(project_root, pins$path)
pin_sha256 <- vapply(
  pin_paths,
  digest::digest,
  character(1),
  file = TRUE,
  algo = "sha256",
  serialize = FALSE
)
pin_bytes <- unname(file.info(pin_paths)$size)
stopifnot(
  all(file.exists(pin_paths)),
  identical(unname(pin_sha256), pins$sha256),
  identical(as.numeric(pin_bytes), as.numeric(pins$bytes))
)

source_path <- file.path(
  project_root,
  "artifacts/11_source_data/H08/H08_near_eye_effects_data.csv"
)
registry_path <- file.path(
  project_root,
  "artifacts/06_model_data/H08/H08_metric_registry.csv"
)

required_source_columns <- c(
  "metric_order",
  "metric_id",
  "metric_label",
  "plot_scale",
  "plot_estimate",
  "plot_conf_low",
  "plot_conf_high",
  "score_participant_sd"
)
required_registry_columns <- c(
  "metric_order",
  "metric_id",
  "manuscript_name"
)

source_data_full <- readr::read_csv(source_path, show_col_types = FALSE)
metric_registry_full <- readr::read_csv(registry_path, show_col_types = FALSE)
stopifnot(
  all(required_source_columns %in% names(source_data_full)),
  all(required_registry_columns %in% names(metric_registry_full))
)

plot_data <- source_data_full |>
  select(all_of(required_source_columns)) |>
  arrange(.data$metric_order)
metric_registry <- metric_registry_full |>
  select(all_of(required_registry_columns)) |>
  arrange(.data$metric_order)

registry_match <- match(plot_data$metric_id, metric_registry$metric_id)
score_sd <- unique(plot_data$score_participant_sd)
stopifnot(
  nrow(plot_data) == 9L,
  nrow(metric_registry) == 9L,
  !anyDuplicated(plot_data$metric_id),
  !anyDuplicated(metric_registry$metric_id),
  identical(as.integer(plot_data$metric_order), seq_len(9L)),
  identical(as.integer(metric_registry$metric_order), seq_len(9L)),
  !anyNA(registry_match),
  identical(
    plot_data$metric_label,
    metric_registry$manuscript_name[registry_match]
  ),
  identical(sort(unname(as.integer(table(plot_data$plot_scale)))), c(1L, 8L)),
  length(score_sd) == 1L,
  is.finite(score_sd),
  identical(sprintf("%.4f", score_sd), "5.5398")
)

plot_data <- plot_data |>
  mutate(
    metric_label = factor(
      .data$metric_label,
      levels = rev(metric_registry$manuscript_name)
    )
  )

wrap_caption <- function(text, width = 72L) {
  paste(strwrap(text, width = width), collapse = "\n")
}

plot <- ggplot2::ggplot(
  plot_data,
  ggplot2::aes(
    x = .data$plot_estimate,
    y = .data$metric_label,
    xmin = .data$plot_conf_low,
    xmax = .data$plot_conf_high
  )
) +
  ggplot2::geom_vline(
    xintercept = 0,
    colour = "grey55",
    linewidth = 0.45
  ) +
  ggplot2::geom_errorbar(
    orientation = "y",
    width = 0.18,
    linewidth = 0.6,
    colour = "#0072B2"
  ) +
  ggplot2::geom_point(
    size = 2.3,
    shape = 21,
    fill = "white",
    colour = "#0072B2"
  ) +
  ggplot2::facet_wrap(
    ggplot2::vars(.data$plot_scale),
    ncol = 1,
    scales = "free",
    space = "free_y",
    strip.position = "right"
  ) +
  ggplot2::labs(
    title = "Near-eye VLSQ-8 associations",
    subtitle = paste0(
      "Adjusted association per ",
      sprintf("%.4f", score_sd),
      " VLSQ-8 points; points and bars are estimates and 95% Wald intervals"
    ),
    x = NULL,
    y = NULL,
    caption = wrap_caption(paste0(
      "Ratios are shown as percent change. Time below 10 lx melEDI before ",
      "sleep uses an identity-Gaussian difference in hours."
    ))
  ) +
  ggplot2::theme_minimal(base_size = 9.5) +
  ggplot2::theme(
    plot.title.position = "plot",
    panel.grid.minor = ggplot2::element_blank(),
    strip.text.y = ggplot2::element_text(
      angle = 0,
      hjust = 0,
      size = 8
    ),
    axis.text.y = ggplot2::element_text(size = 8),
    plot.caption = ggplot2::element_text(hjust = 0, size = 7.5)
  )

ggplot2::ggsave(
  filename = candidate_path,
  plot = plot,
  device = svglite::svglite,
  width = 170,
  height = 136,
  units = "mm",
  bg = "white"
)

stopifnot(
  file.exists(candidate_path),
  file.info(candidate_path)$size > 0
)

cat(
  sprintf(
    "REPORT018_ORDER72_H08_EXPORT=PASS path=%s bytes=%d\n",
    candidate_path,
    file.info(candidate_path)$size
  )
)
