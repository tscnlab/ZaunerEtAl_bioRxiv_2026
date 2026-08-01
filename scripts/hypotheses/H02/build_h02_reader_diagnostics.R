#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
  library(gratia)
  library(patchwork)
  library(readr)
  library(tibble)
})

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
source(file.path(root, "scripts/pipeline/paths_io.R"))
source(file.path(root, "scripts/hypotheses/H02/h02_contract.R"))

if (getRversion() != "4.6.1") {
  stop("H02 reader diagnostics require R 4.6.1", call. = FALSE)
}

producer <- "scripts/hypotheses/H02/build_h02_reader_diagnostics.R"
figure_directory <- file.path(root, "artifacts", "10_figures", "H02")
source_directory <- file.path(root, "artifacts", "11_source_data", "H02")
manifest_directory <- file.path(root, "artifacts", "12_manifests", "H02")
invisible(vapply(
  c(figure_directory, source_directory, manifest_directory),
  dir.create,
  logical(1),
  recursive = TRUE,
  showWarnings = FALSE
))

write_plot <- function(plot, path, width = 10.5, height = 9.5) {
  temporary <- tempfile(
    pattern = paste0(tools::file_path_sans_ext(basename(path)), "."),
    tmpdir = dirname(path),
    fileext = paste0(".", tools::file_ext(path))
  )
  on.exit(unlink(temporary), add = TRUE)
  ggplot2::ggsave(
    filename = temporary,
    plot = plot,
    width = width,
    height = height,
    units = "in",
    dpi = 300,
    bg = "white"
  )
  atomic_replace_artifact(temporary, path)
  invisible(path)
}

residual_acf <- readr::read_csv(
  file.path(root, "artifacts", "08_diagnostics", "H02", "residual_acf.csv"),
  show_col_types = FALSE
)

run_specification <- tibble::tribble(
  ~run_id, ~placement_label, ~file_stem,
  "main__glasses__all_available", "Near-eye", "near_eye",
  "main__chest__all_available", "Chest", "chest"
)

manifest_rows <- list()
for (index in seq_len(nrow(run_specification))) {
  run_id <- run_specification$run_id[[index]]
  placement_label <- run_specification$placement_label[[index]]
  file_stem <- run_specification$file_stem[[index]]
  model_path <- file.path(
    root,
    "artifacts",
    "07_models",
    "H02",
    paste0(run_id, "__selected_model.rds")
  )
  model <- readRDS(model_path)
  if (!inherits(model, "bam")) {
    stop(sprintf("Expected a bam object for %s", run_id), call. = FALSE)
  }
  if (length(model$std.rsd) != nrow(model$model)) {
    stop(sprintf("Residual/model-row mismatch for %s", run_id), call. = FALSE)
  }

  appraisal <- gratia::appraise(
    model,
    method = "normal",
    type = "pearson",
    ncol = 2,
    point_col = "grey25",
    point_alpha = 0.10,
    line_col = "#A61C3C"
  ) &
    ggplot2::theme(
      text = ggplot2::element_text(size = 12),
      plot.title = ggplot2::element_text(size = 14)
    )

  acf_data <- residual_acf |>
    dplyr::filter(.data$run_id == .env$run_id) |>
    dplyr::mutate(
      stage = factor(
        .data$stage,
        levels = c("preliminary_no_AR1", "final_AR1_standardized"),
        labels = c(
          "Before AR(1)",
          "After AR(1), standardized"
        )
      )
    )
  if (nrow(acf_data) != 12L) {
    stop(sprintf("Expected 12 residual-ACF rows for %s", run_id), call. = FALSE)
  }
  acf_plot <- ggplot2::ggplot(
    acf_data,
    ggplot2::aes(
      x = .data$lag_30_minute_bins,
      y = .data$correlation,
      colour = .data$stage,
      group = .data$stage
    )
  ) +
    ggplot2::geom_hline(yintercept = 0, colour = "grey70") +
    ggplot2::geom_line(linewidth = 1.0) +
    ggplot2::geom_point(size = 2.4) +
    ggplot2::scale_x_continuous(breaks = seq_len(6L)) +
    ggplot2::scale_colour_manual(
      values = c("Before AR(1)" = "#A61C3C", "After AR(1), standardized" = "#005A8D")
    ) +
    ggplot2::coord_cartesian(ylim = c(-0.06, 0.68)) +
    ggplot2::labs(
      x = "Lag (30-minute bins within verified sequences)",
      y = "Residual correlation",
      colour = NULL,
      title = "Remaining temporal dependence"
    ) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      legend.position = "bottom",
      panel.grid.minor = ggplot2::element_blank()
    )

  diagnostic_figure <- (appraisal / acf_plot) +
    patchwork::plot_layout(heights = c(3.1, 1)) +
    patchwork::plot_annotation(
      title = paste(placement_label, "model diagnostics"),
      tag_levels = "A",
      theme = ggplot2::theme(
        plot.title = ggplot2::element_text(size = 17, face = "bold"),
        plot.tag = ggplot2::element_text(size = 15, face = "bold")
      )
    )

  png_path <- file.path(
    figure_directory,
    paste0("model_diagnostics_", file_stem, ".png")
  )
  pdf_path <- file.path(
    figure_directory,
    paste0("model_diagnostics_", file_stem, ".pdf")
  )
  write_plot(diagnostic_figure, png_path)
  write_plot(diagnostic_figure, pdf_path)

  plot_source <- tibble::tibble(
    run_id = run_id,
    response = model$model$response,
    linear_predictor = unname(model$linear.predictors),
    fitted_value = unname(model$fitted.values),
    pearson_residual = unname(stats::residuals(model, type = "pearson")),
    ar_standardized_residual = unname(model$std.rsd),
    site = as.character(model$model$site),
    participant = as.character(model$model$participant),
    participant_day = as.character(model$model$participant_day),
    time_hour = model$model$time_hour,
    ar_start = as.logical(model$model[["(AR.start)"]])
  )
  source_path <- file.path(
    source_directory,
    paste0("model_diagnostics_", file_stem, "_source.rds")
  )
  write_rds_artifact(
    plot_source,
    source_path,
    producer,
    list(
      run_id = run_id,
      residual_appraisal = "gratia::appraise(method = normal, type = pearson)",
      temporal_panel = "boundary-aware ACF from accepted residual_acf.csv"
    )
  )

  for (path in c(model_path, png_path, pdf_path, source_path)) {
    manifest_rows[[length(manifest_rows) + 1L]] <- tibble::tibble(
      run_id = run_id,
      role = dplyr::case_when(
        identical(path, model_path) ~ "input_model",
        identical(path, source_path) ~ "figure_source",
        TRUE ~ "reader_diagnostic_figure"
      ),
      path = sub(paste0("^", root, "/"), "", path),
      sha256 = artifact_sha256(path),
      bytes = unname(file.info(path)$size),
      producer = producer,
      r_version = as.character(getRversion()),
      gratia_version = as.character(utils::packageVersion("gratia")),
      mgcv_version = as.character(utils::packageVersion("mgcv"))
    )
  }
}

manifest <- dplyr::bind_rows(manifest_rows) |>
  dplyr::arrange(.data$run_id, .data$role, .data$path)
write_csv_artifact(
  manifest,
  file.path(manifest_directory, "H02_reader_diagnostics_manifest.csv"),
  producer
)
