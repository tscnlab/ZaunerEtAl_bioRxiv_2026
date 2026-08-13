#!/usr/bin/env Rscript

# Generate indexed residual-vs-fitted and Q-Q evidence for manual visual review
# of the 90 repaired gap timing cells. This script does not assign verdicts.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
.libPaths(c(
  file.path(root, "renv/library/macos/R-4.6/aarch64-apple-darwin23"),
  .libPaths()
))
required_packages <- c(
  "digest", "dplyr", "tidyr", "tibble", "readr", "ggplot2", "patchwork",
  "lme4", "glmmTMB", "sandwich", "emmeans", "performance"
)
missing_packages <- required_packages[!vapply(
  required_packages,
  requireNamespace,
  logical(1L),
  quietly = TRUE
)]
if (length(missing_packages)) {
  stop(
    sprintf("Missing package(s): %s", paste(missing_packages, collapse = ", ")),
    call. = FALSE
  )
}
suppressPackageStartupMessages({
  library(digest)
  library(dplyr)
  library(tidyr)
  library(tibble)
  library(readr)
  library(ggplot2)
  library(patchwork)
})
for (script in c(
  "h06_daily_non_l10_pilot_contract.R",
  "h06_daily_non_l10_pilot_data.R",
  "h06_daily_gap_clock_repair_contract.R"
)) {
  source(file.path(root, "scripts/hypotheses/H06_daily", script))
}
h06d_gap_assert(
  identical(as.character(getRversion()), "4.6.1"),
  "Residual review generation requires R 4.6.1"
)
paths <- h06d_gap_paths(root)
invisible(h06d_gap_verify_direct_pins(root))
invisible(h06d_gap_verify_protected_1011(root, "pre_residual_plots"))
state <- readRDS(paths$state)
h06d_gap_assert(
  identical(state$phase, "POSTPROCESS_COMPLETE"),
  "Postprocessed repaired cells are required before plotting"
)
dir.create(paths$figures, recursive = TRUE, showWarnings = FALSE)
dir.create(paths$source_data, recursive = TRUE, showWarnings = FALSE)
cell_figure_dir <- file.path(paths$figures, "cells")
atlas_dir <- file.path(paths$figures, "atlases")
cell_source_dir <- file.path(paths$source_data, "cells")
dir.create(cell_figure_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(atlas_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(cell_source_dir, recursive = TRUE, showWarnings = FALSE)

base_index <- readr::read_csv(paths$base_index, show_col_types = FALSE) |>
  dplyr::arrange(.data$metric_slot, .data$predictor_order, .data$run_order) |>
  dplyr::mutate(repair_cell_index = dplyr::row_number(), .before = 1L)
historical_index <- readr::read_csv(
  file.path(
    paths$diagnostic,
    "H06_daily_non_l10_production_base_checkpoint.csv"
  ),
  show_col_types = FALSE
)
bundle <- readRDS(file.path(
  paths$model_data,
  "H06_daily_gap_clock_repair_frame_bundle.rds"
))
frames <- bundle$frames
site_registry <- readr::read_csv(
  file.path(root, "config/site_display_registry.csv"),
  show_col_types = FALSE
) |>
  dplyr::arrange(.data$display_order)
site_colours <- stats::setNames(site_registry$color_hex, site_registry$site)

primary_model <- function(object, route) {
  if (identical(route, "participant_cluster_HC3")) {
    object$result$models$models$additive
  } else {
    object$result$models$additive_reml$value
  }
}

atomic_ggsave <- function(plot, path, width, height, dpi = 170) {
  temporary <- tempfile(
    pattern = paste0(basename(path), "_"),
    tmpdir = dirname(path),
    fileext = ".png"
  )
  on.exit(unlink(temporary), add = TRUE)
  ggplot2::ggsave(
    temporary,
    plot = plot,
    width = width,
    height = height,
    units = "in",
    dpi = dpi,
    bg = "white"
  )
  h06d_gap_assert(file.rename(temporary, path), "Could not write `%s`", path)
  invisible(path)
}

plot_rows <- list()
plot_objects <- list()
scale_rows <- list()
message("Gap clock repair: generating 90 cell residual plots")
for (index in seq_len(nrow(base_index))) {
  meta <- base_index[index, , drop = FALSE]
  key <- meta$frame_key[[1L]]
  repaired_object <- readRDS(file.path(
    root,
    meta$checkpoint_relative_path[[1L]]
  ))
  old_meta <- historical_index |>
    dplyr::filter(.data$frame_key == .env$key)
  h06d_gap_assert(nrow(old_meta) == 1L, "Historical cell not found for `%s`", key)
  historical_object <- readRDS(file.path(
    root,
    old_meta$checkpoint_relative_path[[1L]]
  ))
  model <- primary_model(repaired_object, meta$route[[1L]])
  historical_model <- primary_model(historical_object, meta$route[[1L]])
  h06d_gap_assert(
    !is.null(model) && !is.null(historical_model),
    "A primary residual model is unavailable for `%s`",
    key
  )
  fitted <- as.numeric(stats::fitted(model))
  residual <- as.numeric(stats::residuals(model))
  historical_fitted <- as.numeric(stats::fitted(historical_model))
  historical_residual <- as.numeric(stats::residuals(historical_model))
  sigma <- if (inherits(model, "lm")) {
    summary(model)$sigma
  } else {
    stats::sigma(model)
  }
  historical_sigma <- if (inherits(historical_model, "lm")) {
    summary(historical_model)$sigma
  } else {
    stats::sigma(historical_model)
  }
  standardized <- residual / sigma
  historical_standardized <- historical_residual / historical_sigma
  scale_rows[[index]] <- tibble::tibble(
    repair_cell_index = index,
    frame_key = key,
    metric_slot = meta$metric_slot,
    predictor_id = meta$predictor_id,
    route = meta$route,
    fitted_scale_maximum_absolute_error = max(abs(
      fitted - historical_fitted * 60
    )),
    residual_scale_maximum_absolute_error = max(abs(
      residual - historical_residual * 60
    )),
    sigma_scale_absolute_error = abs(sigma - historical_sigma * 60),
    standardized_residual_maximum_absolute_error = max(abs(
      standardized - historical_standardized
    )),
    scale_equivariance_verified =
      max(abs(fitted - historical_fitted * 60)) <= 2e-6 &
      max(abs(residual - historical_residual * 60)) <= 2e-6 &
      abs(sigma - historical_sigma * 60) <= 2e-6 &
      max(abs(standardized - historical_standardized)) <= 2e-6
  )
  frame <- frames[[key]]
  h06d_gap_assert(
    length(fitted) == nrow(frame) && length(residual) == nrow(frame),
    "Residual evidence has the wrong length for `%s`",
    key
  )
  qq_index <- order(standardized)
  qq_sample <- standardized[qq_index]
  residual_source <- tibble::tibble(
    observation_index = seq_len(nrow(frame)),
    site = as.character(frame$site),
    fitted_clock_hour = fitted,
    residual_clock_hour = residual,
    standardized_residual = standardized
  )
  qq_source <- tibble::tibble(
    qq_order = seq_along(qq_index),
    theoretical_quantile = stats::qnorm(stats::ppoints(length(qq_index))),
    sample_quantile = qq_sample
  )
  source <- dplyr::bind_cols(residual_source, qq_source)
  source_path <- file.path(
    cell_source_dir,
    sprintf("cell_%03d_residual_source.csv", index)
  )
  h06d_gap_write_csv(source, source_path)

  p_residual <- ggplot2::ggplot(
    residual_source,
    ggplot2::aes(
      x = .data$fitted_clock_hour,
      y = .data$standardized_residual,
      colour = .data$site
    )
  ) +
    ggplot2::geom_hline(yintercept = 0, colour = "grey45", linewidth = 0.35) +
    ggplot2::geom_point(alpha = 0.46, size = 0.75) +
    ggplot2::geom_smooth(
      ggplot2::aes(group = 1),
      method = "loess",
      formula = y ~ x,
      se = FALSE,
      colour = "black",
      linewidth = 0.55
    ) +
    ggplot2::scale_colour_manual(values = site_colours, drop = FALSE) +
    ggplot2::labs(
      x = "Fitted clock time (h)",
      y = "Standardized residual",
      title = "Residuals vs fitted"
    ) +
    ggplot2::theme_minimal(base_size = 9) +
    ggplot2::theme(
      legend.position = "none",
      panel.grid.minor = ggplot2::element_blank(),
      plot.title = ggplot2::element_text(face = "bold", size = 9)
    )
  p_qq <- ggplot2::ggplot(
    qq_source,
    ggplot2::aes(x = .data$theoretical_quantile, y = .data$sample_quantile)
  ) +
    ggplot2::geom_abline(
      slope = 1,
      intercept = 0,
      colour = "grey45",
      linewidth = 0.35
    ) +
    ggplot2::geom_point(alpha = 0.55, size = 0.75, colour = "#2C3E50") +
    ggplot2::labs(
      x = "Theoretical normal quantile",
      y = "Standardized residual",
      title = "Normal Q-Q"
    ) +
    ggplot2::theme_minimal(base_size = 9) +
    ggplot2::theme(
      panel.grid.minor = ggplot2::element_blank(),
      plot.title = ggplot2::element_text(face = "bold", size = 9)
    )
  subtitle <- paste(
    meta$placement_id[[1L]],
    meta$sample_role[[1L]],
    meta$predictor_id[[1L]],
    sep = " | "
  )
  plot <- (p_residual | p_qq) +
    patchwork::plot_annotation(
      title = sprintf(
        "%02d. %s",
        index,
        meta$manuscript_name[[1L]]
      ),
      subtitle = subtitle,
      theme = ggplot2::theme(
        plot.title = ggplot2::element_text(face = "bold", size = 11),
        plot.subtitle = ggplot2::element_text(size = 8, colour = "grey30")
      )
    )
  plot_path <- file.path(cell_figure_dir, sprintf("cell_%03d.png", index))
  atomic_ggsave(plot, plot_path, width = 9.4, height = 3.4)
  group_number <- ceiling(index / 9)
  group_key <- sprintf("atlas_%02d", group_number)
  plot_objects[[index]] <- plot
  plot_rows[[index]] <- tibble::tibble(
    audit_cell_id = sprintf("gap_clock_repair_cell_%03d", index),
    repair_cell_index = index,
    frame_key = key,
    dataset_id = meta$dataset_id,
    placement_id = meta$placement_id,
    sample_role = meta$sample_role,
    metric_slot = meta$metric_slot,
    metric_id = meta$metric_id,
    manuscript_name = meta$manuscript_name,
    predictor_id = meta$predictor_id,
    route = meta$route,
    response_family = meta$response_family,
    diagnostic_plot_relative_path = h06d_gap_relative(root, plot_path),
    diagnostic_plot_sha256 = h06d_gap_sha256(plot_path),
    diagnostic_plot_bytes = as.numeric(file.info(plot_path)$size),
    source_data_relative_path = h06d_gap_relative(root, source_path),
    source_data_sha256 = h06d_gap_sha256(source_path),
    source_data_bytes = as.numeric(file.info(source_path)$size),
    atlas_group_key = group_key,
    fig_alt = paste0(
      "Residual diagnostic for ", meta$manuscript_name[[1L]], ", ",
      meta$placement_id[[1L]], ", ", meta$sample_role[[1L]], ", ",
      meta$predictor_id[[1L]],
      ". Left: standardized residuals versus fitted clock hours with a loess ",
      "trend and zero line. Right: normal Q-Q plot."
    ),
    verdict_source = "MANUAL_VISUAL_REVIEW_REQUIRED",
    numeric_threshold_set_verdict = FALSE,
    gate = h06d_gap_authorization()$gate,
    r_version = as.character(getRversion())
  )
}

scale_audit <- dplyr::bind_rows(scale_rows)
h06d_gap_write_csv(
  scale_audit,
  file.path(
    paths$diagnostic,
    "H06_daily_gap_clock_repair_residual_scale_equivariance.csv"
  )
)
h06d_gap_assert(
  nrow(scale_audit) == 90L && all(scale_audit$scale_equivariance_verified),
  "Residual-model scale equivariance failed"
)

atlas_rows <- list()
plot_index <- dplyr::bind_rows(plot_rows)
for (group_key in unique(plot_index$atlas_group_key)) {
  indexes <- plot_index$repair_cell_index[
    plot_index$atlas_group_key == group_key
  ]
  atlas <- patchwork::wrap_plots(plot_objects[indexes], ncol = 3L)
  atlas_path <- file.path(atlas_dir, paste0(group_key, ".png"))
  atomic_ggsave(
    atlas,
    atlas_path,
    width = 19,
    height = 4.25 * ceiling(length(indexes) / 3),
    dpi = 150
  )
  atlas_rows[[group_key]] <- tibble::tibble(
    atlas_group_key = group_key,
    first_repair_cell = min(indexes),
    last_repair_cell = max(indexes),
    cells = length(indexes),
    atlas_relative_path = h06d_gap_relative(root, atlas_path),
    atlas_sha256 = h06d_gap_sha256(atlas_path),
    atlas_bytes = as.numeric(file.info(atlas_path)$size)
  )
}
atlas_index <- dplyr::bind_rows(atlas_rows)
plot_index <- plot_index |>
  dplyr::left_join(
    atlas_index |>
      dplyr::select(
        "atlas_group_key", "atlas_relative_path", "atlas_sha256",
        "atlas_bytes"
      ),
    by = "atlas_group_key",
    relationship = "many-to-one"
  )
h06d_gap_assert(
  nrow(plot_index) == 90L && nrow(atlas_index) == 10L &&
    !anyDuplicated(plot_index$frame_key),
  "The residual review index is incomplete"
)
h06d_gap_write_csv(
  plot_index,
  file.path(
    paths$diagnostic,
    "H06_daily_gap_clock_repair_visual_plot_index.csv"
  )
)
h06d_gap_write_csv(
  atlas_index,
  file.path(
    paths$diagnostic,
    "H06_daily_gap_clock_repair_visual_atlas_index.csv"
  )
)
h06d_gap_write_csv(
  plot_index |>
    dplyr::mutate(
      visual_residual_verdict = NA_character_,
      visual_reason_codes = NA_character_,
      visual_explanation = NA_character_,
      reviewer = NA_character_,
      review_date = as.Date(NA),
      review_method = "Direct visual inspection; no numeric verdict rule"
    ),
  file.path(
    paths$diagnostic,
    "H06_daily_gap_clock_repair_visual_review_template.csv"
  )
)
invisible(h06d_gap_verify_protected_1011(root, "post_residual_plots"))
message(sprintf(
  "Gap clock repair residual evidence complete: 90 cells and 10 atlases"
))
