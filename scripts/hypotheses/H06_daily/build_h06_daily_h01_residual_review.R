#!/usr/bin/env Rscript

# Build per-cell visual residual evidence from frozen H06_daily fits only.

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
  "digest", "dplyr", "ggplot2", "lme4", "patchwork", "readr",
  "tibble", "tidyr", "glmmTMB"
)
missing_packages <- required_packages[!vapply(
  required_packages,
  requireNamespace,
  logical(1L),
  quietly = TRUE
)]
if (length(missing_packages)) {
  stop(
    sprintf("Missing synchronized packages: %s", paste(missing_packages, collapse = ", ")),
    call. = FALSE
  )
}

source(file.path(
  root,
  "scripts/hypotheses/H06_daily/h06_daily_h01_diagnostic_alignment_contract.R"
))

h06d_h01_assert(
  identical(as.character(getRversion()), "4.6.1"),
  "H06-D-014 visual review requires R 4.6.1; found %s",
  as.character(getRversion())
)

roots <- h06d_h01_artifact_roots(root)
plot_root <- file.path(roots$figures, "h01_diagnostic_alignment", "cells")
atlas_root <- file.path(roots$figures, "h01_diagnostic_alignment", "atlases")
source_root <- file.path(roots$source_data, "h01_diagnostic_alignment", "cells")
dir.create(plot_root, recursive = TRUE, showWarnings = FALSE)
dir.create(atlas_root, recursive = TRUE, showWarnings = FALSE)
dir.create(source_root, recursive = TRUE, showWarnings = FALSE)

input_manifest <- h06d_h01_verify_direct_inputs(root)
h06d_h01_write_csv(
  input_manifest,
  file.path(roots$manifests, "H06_daily_h01_diagnostic_alignment_input_manifest.csv")
)

production_manifest_path <- file.path(
  roots$manifests,
  "H06_daily_non_l10_production_output_manifest.csv"
)
production_manifest <- readr::read_csv(
  production_manifest_path,
  show_col_types = FALSE
)
observed_production_hash <- vapply(
  file.path(root, production_manifest$relative_path),
  h06d_h01_sha256,
  character(1L)
)
h06d_h01_assert(
  identical(unname(observed_production_hash), production_manifest$sha256),
  "A frozen H06-D-G2 scientific output changed before visual review"
)

cell_manifest <- production_manifest |>
  dplyr::filter(.data$role == "sealed base-cell model object") |>
  dplyr::mutate(
    cell_index = as.integer(sub("^cell_([0-9]{3})_.*$", "\\1", basename(.data$relative_path)))
  ) |>
  dplyr::arrange(.data$cell_index)
h06d_h01_assert(
  nrow(cell_manifest) == 468L &&
    identical(cell_manifest$cell_index, seq_len(468L)),
  "The frozen Stage 2 cell-model inventory is not exactly 468 ordered cells"
)

diagnostics <- readr::read_csv(
  file.path(
    roots$diagnostics,
    "H06_daily_non_l10_production_diagnostic_assessment.csv"
  ),
  show_col_types = FALSE
)
h06d_h01_assert(
  nrow(diagnostics) == 468L &&
    !anyDuplicated(diagnostics$frame_key),
  "The historical H06-D-G2 diagnostic table is not the expected 468-cell inventory"
)

theme_review <- function() {
  ggplot2::theme_minimal(base_size = 10) +
    ggplot2::theme(
      panel.grid.minor = ggplot2::element_blank(),
      plot.title = ggplot2::element_text(face = "bold", size = 10),
      plot.subtitle = ggplot2::element_text(size = 8.5),
      axis.title = ggplot2::element_text(size = 8.5),
      axis.text = ggplot2::element_text(size = 7.5),
      plot.margin = ggplot2::margin(4, 5, 4, 5)
    )
}

atomic_ggsave <- function(plot, path, width, height, dpi) {
  temporary <- tempfile(
    pattern = paste0(basename(path), "_"),
    tmpdir = dirname(path),
    fileext = ".png"
  )
  on.exit(unlink(temporary), add = TRUE)
  ggplot2::ggsave(
    filename = temporary,
    plot = plot,
    width = width,
    height = height,
    units = "in",
    dpi = dpi,
    bg = "white",
    limitsize = FALSE
  )
  h06d_h01_assert(file.rename(temporary, path), "Could not write `%s`", path)
  invisible(path)
}

safe_correlation <- function(x, y, method = "pearson") {
  if (length(x) < 3L || stats::sd(x, na.rm = TRUE) == 0 ||
      stats::sd(y, na.rm = TRUE) == 0) return(NA_real_)
  suppressWarnings(stats::cor(x, y, method = method, use = "complete.obs"))
}

extract_plot_data <- function(model, response_family, cell_key) {
  frame <- stats::model.frame(model)
  observed <- as.numeric(stats::model.response(frame))
  fitted <- as.numeric(stats::fitted(model))
  residual_type <- if (identical(response_family, "tweedie_log")) {
    "pearson"
  } else {
    "response"
  }
  residual <- as.numeric(stats::residuals(model, type = residual_type))
  h06d_h01_assert(
    length(observed) == length(fitted) && length(fitted) == length(residual) &&
      length(observed) > 2L &&
      all(is.finite(observed)) && all(is.finite(fitted)) &&
      all(is.finite(residual)),
    "Stored plot inputs are incomplete for `%s`",
    cell_key
  )
  residual_scale <- stats::sd(residual)
  h06d_h01_assert(
    is.finite(residual_scale) && residual_scale > 0,
    "Stored residual scale is invalid for `%s`",
    cell_key
  )
  standardized <- residual / residual_scale
  order_index <- order(standardized)
  theoretical <- stats::qnorm(stats::ppoints(length(standardized)))
  qq_sample <- sort(standardized)
  quartile_sample <- stats::quantile(
    standardized,
    probs = c(0.25, 0.75),
    names = FALSE,
    type = 8
  )
  quartile_theoretical <- stats::qnorm(c(0.25, 0.75))
  qq_slope <- diff(quartile_sample) / diff(quartile_theoretical)
  qq_intercept <- quartile_sample[[1L]] - qq_slope * quartile_theoretical[[1L]]

  model_rows <- tibble::tibble(
    observation_index = seq_along(observed),
    observed_response = observed,
    fitted_value = fitted,
    residual = residual,
    standardized_residual = standardized,
    absolute_standardized_residual = abs(standardized),
    square_root_absolute_standardized_residual = sqrt(abs(standardized)),
    observed_exact_zero = observed == 0
  )
  qq_rows <- tibble::tibble(
    qq_order = seq_along(theoretical),
    observation_index = order_index,
    theoretical_quantile = theoretical,
    sample_quantile = qq_sample
  )
  bin_count <- min(10L, nrow(model_rows))
  fitted_rank <- rank(model_rows$fitted_value, ties.method = "first")
  model_rows$fitted_bin <- pmin(
    bin_count,
    ceiling(fitted_rank / nrow(model_rows) * bin_count)
  )
  zero_rows <- model_rows |>
    dplyr::group_by(.data$fitted_bin) |>
    dplyr::summarise(
      mean_fitted_value = mean(.data$fitted_value),
      observed_zero_fraction = mean(.data$observed_exact_zero),
      observations = dplyr::n(),
      .groups = "drop"
    )
  list(
    model_rows = model_rows,
    qq_rows = qq_rows,
    zero_rows = zero_rows,
    qq_intercept = qq_intercept,
    qq_slope = qq_slope,
    navigation = tibble::tibble(
      residual_mean = mean(residual),
      residual_median = stats::median(residual),
      residual_sd = residual_scale,
      residual_qq_correlation = safe_correlation(theoretical, qq_sample),
      absolute_residual_fitted_spearman = abs(safe_correlation(
        abs(residual), fitted, method = "spearman"
      )),
      standardized_residual_gt4_fraction = mean(abs(standardized) > 4),
      observed_zero_fraction = mean(observed == 0),
      fitted_minimum = min(fitted),
      fitted_maximum = max(fitted),
      observed_minimum = min(observed),
      observed_maximum = max(observed),
      numeric_navigation_only = TRUE
    )
  )
}

plot_cell <- function(plot_data, response_family, title, subtitle) {
  rows <- plot_data$model_rows
  residual_panel_title <- if (identical(response_family, "tweedie_log")) {
    "Pearson residuals versus fitted"
  } else {
    "Residuals versus fitted"
  }
  p_residual <- ggplot2::ggplot(
    rows,
    ggplot2::aes(x = .data$fitted_value, y = .data$standardized_residual)
  ) +
    ggplot2::geom_hline(yintercept = 0, colour = "grey35", linewidth = 0.45) +
    ggplot2::geom_point(alpha = 0.28, size = 0.8, colour = "#294C60") +
    ggplot2::geom_smooth(
      method = "loess", formula = y ~ x, se = FALSE,
      colour = "#B4432C", linewidth = 0.7
    ) +
    ggplot2::labs(
      title = paste(title, residual_panel_title, sep = "\n"),
      subtitle = subtitle,
      x = "Stored fitted value",
      y = "Residual / residual SD"
    ) +
    theme_review()

  if (identical(response_family, "tweedie_log")) {
    p_second <- ggplot2::ggplot() +
      ggplot2::geom_jitter(
        data = rows,
        ggplot2::aes(
          x = .data$fitted_value,
          y = as.numeric(.data$observed_exact_zero)
        ),
        height = 0.035,
        width = 0,
        alpha = 0.10,
        size = 0.65,
        colour = "#294C60"
      ) +
      ggplot2::geom_line(
        data = plot_data$zero_rows,
        ggplot2::aes(
          x = .data$mean_fitted_value,
          y = .data$observed_zero_fraction
        ),
        colour = "#B4432C",
        linewidth = 0.75
      ) +
      ggplot2::geom_point(
        data = plot_data$zero_rows,
        ggplot2::aes(
          x = .data$mean_fitted_value,
          y = .data$observed_zero_fraction
        ),
        colour = "#B4432C",
        size = 1.5
      ) +
      ggplot2::scale_y_continuous(
        limits = c(-0.08, 1.08),
        breaks = c(0, 0.5, 1),
        labels = c("positive", "0.5", "zero")
      ) +
      ggplot2::labs(
        title = "Observed zero mass across fitted means",
        x = "Stored fitted mean",
        y = "Exact-zero indicator / binned fraction"
      ) +
      theme_review()

    support_rows <- dplyr::mutate(
      rows,
      log10_fitted_plus_0_1 = log10(.data$fitted_value + 0.1),
      log10_observed_plus_0_1 = log10(.data$observed_response + 0.1)
    )
    support_min <- min(
      support_rows$log10_fitted_plus_0_1,
      support_rows$log10_observed_plus_0_1
    )
    support_max <- max(
      support_rows$log10_fitted_plus_0_1,
      support_rows$log10_observed_plus_0_1
    )
    p_third <- ggplot2::ggplot(
      support_rows,
      ggplot2::aes(
        x = .data$log10_fitted_plus_0_1,
        y = .data$log10_observed_plus_0_1
      )
    ) +
      ggplot2::geom_abline(
        intercept = 0, slope = 1, colour = "grey45", linewidth = 0.5
      ) +
      ggplot2::geom_point(alpha = 0.22, size = 0.75, colour = "#294C60") +
      ggplot2::coord_equal(xlim = c(support_min, support_max),
                           ylim = c(support_min, support_max)) +
      ggplot2::labs(
        title = "Observed versus fitted support",
        x = expression(log[10](fitted + 0.1)),
        y = expression(log[10](observed + 0.1))
      ) +
      theme_review()
  } else {
    p_second <- ggplot2::ggplot(
      plot_data$qq_rows,
      ggplot2::aes(x = .data$theoretical_quantile, y = .data$sample_quantile)
    ) +
      ggplot2::geom_abline(
        intercept = plot_data$qq_intercept,
        slope = plot_data$qq_slope,
        colour = "grey35",
        linewidth = 0.55
      ) +
      ggplot2::geom_point(alpha = 0.45, size = 0.8, colour = "#294C60") +
      ggplot2::labs(
        title = "Normal Q-Q (gross departures only)",
        x = "Theoretical normal quantile",
        y = "Ordered residual / residual SD"
      ) +
      theme_review()

    p_third <- ggplot2::ggplot(
      rows,
      ggplot2::aes(
        x = .data$fitted_value,
        y = .data$square_root_absolute_standardized_residual
      )
    ) +
      ggplot2::geom_point(alpha = 0.25, size = 0.8, colour = "#294C60") +
      ggplot2::geom_smooth(
        method = "loess", formula = y ~ x, se = FALSE,
        colour = "#B4432C", linewidth = 0.7
      ) +
      ggplot2::labs(
        title = "Scale-location",
        x = "Stored fitted value",
        y = expression(sqrt("|residual / residual SD|"))
      ) +
      theme_review()
  }

  p_residual | p_second | p_third
}

long_source <- function(plot_data, cell_metadata) {
  residual_rows <- plot_data$model_rows |>
    dplyr::transmute(
      panel = "residual_fitted",
      row_index = .data$observation_index,
      x = .data$fitted_value,
      y = .data$standardized_residual,
      observed_response = .data$observed_response,
      fitted_value = .data$fitted_value,
      residual = .data$residual,
      standardized_residual = .data$standardized_residual,
      observed_exact_zero = .data$observed_exact_zero,
      fitted_bin = .data$fitted_bin,
      observations_in_bin = NA_integer_
    )
  qq_rows <- plot_data$qq_rows |>
    dplyr::transmute(
      panel = "normal_qq",
      row_index = .data$observation_index,
      x = .data$theoretical_quantile,
      y = .data$sample_quantile,
      observed_response = NA_real_,
      fitted_value = NA_real_,
      residual = NA_real_,
      standardized_residual = .data$sample_quantile,
      observed_exact_zero = NA,
      fitted_bin = NA_integer_,
      observations_in_bin = NA_integer_
    )
  scale_rows <- plot_data$model_rows |>
    dplyr::transmute(
      panel = "scale_location",
      row_index = .data$observation_index,
      x = .data$fitted_value,
      y = .data$square_root_absolute_standardized_residual,
      observed_response = .data$observed_response,
      fitted_value = .data$fitted_value,
      residual = .data$residual,
      standardized_residual = .data$standardized_residual,
      observed_exact_zero = .data$observed_exact_zero,
      fitted_bin = .data$fitted_bin,
      observations_in_bin = NA_integer_
    )
  zero_rows <- plot_data$zero_rows |>
    dplyr::transmute(
      panel = "zero_mass_binned",
      row_index = NA_integer_,
      x = .data$mean_fitted_value,
      y = .data$observed_zero_fraction,
      observed_response = NA_real_,
      fitted_value = .data$mean_fitted_value,
      residual = NA_real_,
      standardized_residual = NA_real_,
      observed_exact_zero = NA,
      fitted_bin = .data$fitted_bin,
      observations_in_bin = .data$observations
    )
  output <- if (identical(cell_metadata$response_family[[1L]], "tweedie_log")) {
    support_rows <- plot_data$model_rows |>
      dplyr::transmute(
        panel = "prediction_support",
        row_index = .data$observation_index,
        x = log10(.data$fitted_value + 0.1),
        y = log10(.data$observed_response + 0.1),
        observed_response = .data$observed_response,
        fitted_value = .data$fitted_value,
        residual = .data$residual,
        standardized_residual = .data$standardized_residual,
        observed_exact_zero = .data$observed_exact_zero,
        fitted_bin = .data$fitted_bin,
        observations_in_bin = NA_integer_
      )
    dplyr::bind_rows(residual_rows, zero_rows, support_rows)
  } else {
    dplyr::bind_rows(residual_rows, qq_rows, scale_rows)
  }
  dplyr::bind_cols(
    cell_metadata[rep(1L, nrow(output)), , drop = FALSE],
    output
  )
}

cell_index_rows <- list()
plot_groups <- list()

for (cell_index in seq_len(468L)) {
  model_record <- cell_manifest[cell_index, , drop = FALSE]
  cell <- readRDS(file.path(root, model_record$relative_path))
  historical <- diagnostics[
    match(cell$frame_key, diagnostics$frame_key),
    ,
    drop = FALSE
  ]
  h06d_h01_assert(
    nrow(historical) == 1L && !is.na(historical$frame_key) &&
    identical(cell$frame_key, historical$frame_key) &&
      identical(cell$route, historical$route),
    "Cell/model metadata mismatch at production cell %d",
    cell_index
  )

  if (identical(cell$route, "mixed_model")) {
    capture <- cell$result$models$additive_reml
    model <- capture$value
    covariance_capture <- NULL
  } else {
    capture <- cell$result$models$fits$additive
    model <- cell$result$models$models$additive
    covariance_capture <- cell$result$models$covariance$additive
  }
  h06d_h01_assert(!is.null(model), "Missing frozen additive model for `%s`", cell$frame_key)

  cell_key <- sprintf("nonl10_cell_%03d", cell_index)
  plot_data <- extract_plot_data(model, historical$response_family, cell_key)
  metadata <- tibble::tibble(
    audit_cell_id = cell_key,
    scope = "non_l10_stage2_production",
    production_cell_index = cell_index,
    frame_key = historical$frame_key,
    dataset_id = historical$dataset_id,
    placement_id = historical$placement_id,
    sample_role = historical$sample_role,
    metric_slot = historical$metric_slot,
    metric_id = historical$metric_id,
    manuscript_name = historical$manuscript_name,
    predictor_id = historical$predictor_id,
    predictor = historical$reader_name,
    route = historical$route,
    response_family = historical$response_family,
    response_transform = historical$response_transform
  )
  source_path <- file.path(source_root, paste0(cell_key, ".csv"))
  h06d_h01_write_csv(long_source(plot_data, metadata), source_path)

  title <- sprintf(
    "%03d | %s | %s",
    cell_index,
    historical$manuscript_name,
    historical$reader_name
  )
  subtitle <- sprintf(
    "%s / %s / %s | %s | n=%d participant-days, %d participants",
    historical$dataset_id,
    historical$placement_id,
    historical$sample_role,
    historical$route,
    historical$participant_days,
    historical$participants
  )
  plot <- plot_cell(plot_data, historical$response_family, title, subtitle)
  plot_path <- file.path(plot_root, paste0(cell_key, ".png"))
  atomic_ggsave(plot, plot_path, width = 13.5, height = 4.2, dpi = 170)

  group_key <- paste(
    historical$dataset_id,
    historical$placement_id,
    historical$sample_role,
    historical$predictor_id,
    sep = "__"
  )
  plot_groups[[group_key]] <- c(plot_groups[[group_key]], list(plot))
  warnings <- unique(c(
    capture$warnings,
    if (!is.null(covariance_capture)) covariance_capture$warnings else character()
  ))
  cell_index_rows[[cell_key]] <- dplyr::bind_cols(
    metadata,
    tibble::tibble(
      model_relative_path = model_record$relative_path,
      model_file_sha256 = model_record$sha256,
      model_object_sha256 = h06d_h01_object_sha256(model),
      fit_error = capture$error,
      fit_warning_count = length(warnings),
      fit_warnings = paste(warnings, collapse = " | "),
      source_data_relative_path = h06d_h01_relative(root, source_path),
      source_data_sha256 = h06d_h01_sha256(source_path),
      diagnostic_plot_relative_path = h06d_h01_relative(root, plot_path),
      diagnostic_plot_sha256 = h06d_h01_sha256(plot_path),
      atlas_group_key = group_key
    ),
    plot_data$navigation
  )
  if (cell_index %% 39L == 0L) {
    message(sprintf("Visual evidence: %d/468 non-L10 cells written", cell_index))
  }
}

# Add the three already fitted shifted-log L10 pilot additive REML objects.
l10_parent_path <- file.path(
  root,
  "artifacts/07_models/H06_daily/H06_daily_l10_metric011_production_models.rds"
)
l10_parent <- readRDS(l10_parent_path)
l10_diagnostics <- readr::read_csv(
  file.path(roots$diagnostics, "H06_daily_l10_shiftlog_pilot_diagnostics.csv"),
  show_col_types = FALSE
)
l10_predictors <- c(
  "work_free_day",
  "activity_status",
  "previous_sleep_duration_centered_h"
)
l10_labels <- c(
  "Work day versus Free day",
  "Sedentary versus Active day",
  "Previous-night sleep duration"
)
l10_plots <- list()
for (predictor_index in seq_along(l10_predictors)) {
  predictor_id <- l10_predictors[[predictor_index]]
  parent_key <- paste(
    "primary", "near_eye", "all_available", predictor_id,
    sep = "__"
  )
  capture <- l10_parent$models[[parent_key]]$one_part
  h06d_h01_assert(
    !is.null(capture$value),
    "Missing frozen shifted-log L10 additive REML model for `%s`",
    predictor_id
  )
  cell_key <- paste0("l10_shiftlog_", predictor_id)
  plot_data <- extract_plot_data(capture$value, "gaussian", cell_key)
  metadata <- tibble::tibble(
    audit_cell_id = cell_key,
    scope = "shifted_log_l10_pilot",
    production_cell_index = NA_integer_,
    frame_key = parent_key,
    dataset_id = "primary",
    placement_id = "near_eye",
    sample_role = "all_available",
    metric_slot = 3L,
    metric_id = "l10_mean_medi",
    manuscript_name = "L10 mean melEDI",
    predictor_id = predictor_id,
    predictor = l10_labels[[predictor_index]],
    route = "shifted_log_gaussian_mixed_pilot",
    response_family = "gaussian",
    response_transform = "log10_offset_0.1"
  )
  source_path <- file.path(source_root, paste0(cell_key, ".csv"))
  h06d_h01_write_csv(long_source(plot_data, metadata), source_path)
  title <- sprintf("L10 shifted-log pilot | %s", l10_labels[[predictor_index]])
  subtitle <- sprintf(
    "primary / near_eye / all_available | frozen additive REML | n=%d",
    nrow(stats::model.frame(capture$value))
  )
  plot <- plot_cell(plot_data, "gaussian", title, subtitle)
  plot_path <- file.path(plot_root, paste0(cell_key, ".png"))
  atomic_ggsave(plot, plot_path, width = 13.5, height = 4.2, dpi = 170)
  l10_plots[[predictor_id]] <- plot
  diagnostic_row <- l10_diagnostics |>
    dplyr::filter(.data$predictor_id == .env$predictor_id)
  h06d_h01_assert(nrow(diagnostic_row) == 1L, "Missing L10 diagnostic row")
  cell_index_rows[[cell_key]] <- dplyr::bind_cols(
    metadata,
    tibble::tibble(
      model_relative_path = h06d_h01_relative(root, l10_parent_path),
      model_file_sha256 = h06d_h01_sha256(l10_parent_path),
      model_object_sha256 = h06d_h01_object_sha256(capture$value),
      fit_error = capture$error,
      fit_warning_count = length(capture$warnings),
      fit_warnings = paste(capture$warnings, collapse = " | "),
      source_data_relative_path = h06d_h01_relative(root, source_path),
      source_data_sha256 = h06d_h01_sha256(source_path),
      diagnostic_plot_relative_path = h06d_h01_relative(root, plot_path),
      diagnostic_plot_sha256 = h06d_h01_sha256(plot_path),
      atlas_group_key = "shifted_log_l10_pilot"
    ),
    plot_data$navigation
  )
}

atlas_rows <- list()
for (group_key in names(plot_groups)) {
  group_plots <- plot_groups[[group_key]]
  h06d_h01_assert(length(group_plots) == 13L, "Atlas `%s` does not have 13 cells", group_key)
  atlas <- patchwork::wrap_plots(group_plots, ncol = 1L)
  atlas_path <- file.path(atlas_root, paste0(group_key, ".png"))
  atomic_ggsave(
    atlas,
    atlas_path,
    width = 13.5,
    height = 4.2 * length(group_plots),
    dpi = 105
  )
  atlas_rows[[group_key]] <- tibble::tibble(
    atlas_group_key = group_key,
    cells = length(group_plots),
    atlas_relative_path = h06d_h01_relative(root, atlas_path),
    atlas_sha256 = h06d_h01_sha256(atlas_path),
    atlas_bytes = as.numeric(file.info(atlas_path)$size)
  )
  message(sprintf("Atlas written: %s", group_key))
}
l10_atlas <- patchwork::wrap_plots(l10_plots, ncol = 1L)
l10_atlas_path <- file.path(atlas_root, "shifted_log_l10_pilot.png")
atomic_ggsave(
  l10_atlas,
  l10_atlas_path,
  width = 13.5,
  height = 4.2 * length(l10_plots),
  dpi = 130
)
atlas_rows[["shifted_log_l10_pilot"]] <- tibble::tibble(
  atlas_group_key = "shifted_log_l10_pilot",
  cells = length(l10_plots),
  atlas_relative_path = h06d_h01_relative(root, l10_atlas_path),
  atlas_sha256 = h06d_h01_sha256(l10_atlas_path),
  atlas_bytes = as.numeric(file.info(l10_atlas_path)$size)
)

cell_index <- dplyr::bind_rows(cell_index_rows) |>
  dplyr::left_join(
    dplyr::bind_rows(atlas_rows),
    by = "atlas_group_key",
    relationship = "many-to-one"
  ) |>
  dplyr::mutate(
    review_rule = paste0(
      "VISUAL_ONLY_NO_NUMERIC_THRESHOLD; Gaussian/HC3: residual-fitted + Q-Q + ",
      "scale-location; Tweedie: Pearson residual-fitted + zero-mass + support"
    ),
    numeric_navigation_cannot_set_verdict = TRUE,
    authorization = "H06-D-014",
    gate = "H06-D-G2A",
    r_version = as.character(getRversion())
  )
h06d_h01_assert(
  nrow(cell_index) == 471L && !anyDuplicated(cell_index$audit_cell_id) &&
    all(cell_index$numeric_navigation_only) &&
    all(cell_index$numeric_navigation_cannot_set_verdict),
  "The visual residual index is incomplete"
)
h06d_h01_write_csv(
  cell_index,
  file.path(roots$diagnostics, "H06_daily_h01_visual_residual_plot_index.csv")
)
h06d_h01_write_csv(
  dplyr::bind_rows(atlas_rows),
  file.path(roots$diagnostics, "H06_daily_h01_visual_residual_atlas_index.csv")
)

review_template <- cell_index |>
  dplyr::transmute(
    .data$audit_cell_id,
    .data$scope,
    .data$production_cell_index,
    .data$frame_key,
    .data$dataset_id,
    .data$placement_id,
    .data$sample_role,
    .data$metric_slot,
    .data$metric_id,
    .data$manuscript_name,
    .data$predictor_id,
    .data$predictor,
    .data$route,
    .data$response_family,
    visual_residual_verdict = NA_character_,
    visual_reason_codes = NA_character_,
    visual_explanation = NA_character_,
    reviewer = NA_character_,
    review_date = as.Date(NA),
    .data$diagnostic_plot_relative_path,
    .data$diagnostic_plot_sha256,
    .data$source_data_relative_path,
    .data$source_data_sha256,
    .data$atlas_relative_path,
    .data$atlas_sha256,
    numeric_summaries_used_for_navigation_only = TRUE
  )
h06d_h01_write_csv(
  review_template,
  file.path(roots$diagnostics, "H06_daily_h01_visual_residual_review_template.csv")
)

message(sprintf(
  paste0(
    "H06-D-014 visual evidence complete: %d cells, %d atlases; ",
    "no fit, refit, simulation, or scientific prediction was run."
  ),
  nrow(cell_index),
  nrow(dplyr::bind_rows(atlas_rows))
))
