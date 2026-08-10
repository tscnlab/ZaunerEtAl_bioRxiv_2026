# Bounded comparison of inherited and fully cyclic H03 temporal sz bases.

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
source(file.path(root, "scripts/hypotheses/H03/h03_contract.R"))
source(file.path(root, "scripts/hypotheses/H03/h03_data.R"))
source(file.path(root, "scripts/hypotheses/H03/h03_modeling.R"))
source(file.path(root, "scripts/hypotheses/H03/h03_temporal.R"))
source(file.path(root, "scripts/hypotheses/H03/h03_reporting.R"))

options(lifecycle_verbosity = "quiet", warn = 1)
if (!identical(as.character(getRversion()), "4.6.1")) {
  h03_abort(
    "H03 cyclic-sz comparison requires R 4.6.1; found %s",
    as.character(getRversion())
  )
}
required_packages <- c(
  "dplyr", "tidyr", "tibble", "readr", "openssl", "mgcv", "gratia",
  "ggplot2", "cowplot", "patchwork", "svglite", "ragg"
)
missing_packages <- required_packages[!vapply(
  required_packages,
  requireNamespace,
  logical(1),
  quietly = TRUE
)]
if (length(missing_packages) > 0L) {
  h03_abort(
    "Missing project package(s): %s",
    paste(missing_packages, collapse = ", ")
  )
}

producer <- paste0(
  "scripts/hypotheses/H03/",
  "run_h03_temporal_cyclic_sz_comparison.R"
)
roots <- list(
  model_data = file.path(root, "artifacts/06_model_data/H03"),
  models = file.path(root, "artifacts/07_models/H03"),
  diagnostics = file.path(root, "artifacts/08_diagnostics/H03"),
  tables = file.path(root, "artifacts/09_tables/H03"),
  figures = file.path(root, "artifacts/10_figures/H03"),
  source_data = file.path(root, "artifacts/11_source_data/H03"),
  manifests = file.path(root, "artifacts/12_manifests/H03")
)
invisible(vapply(
  roots,
  dir.create,
  logical(1),
  recursive = TRUE,
  showWarnings = FALSE
))

metadata <- list()
h03_write_csv <- function(data, path, id) {
  metadata[[id]] <<- write_csv_artifact(data, path, producer)
  invisible(path)
}
h03_record_plot_metadata <- function(items, prefix) {
  for (extension in names(items)) {
    metadata[[paste(prefix, extension, sep = "_")]] <<- items[[extension]]
  }
}

h03_validate_inputs(root)
frame_path <- file.path(roots$model_data, "H03_model_frames.rds")
current_model_path <- file.path(
  roots$models,
  "H03_temporal_model_objects.rds"
)
if (!file.exists(frame_path) || !file.exists(current_model_path)) {
  h03_abort("Run the approved H03 Stage 2 temporal analysis first")
}
frames <- readRDS(frame_path)$main
current_models <- readRDS(current_model_path)
for (id in names(current_models)) {
  if (is.null(current_models[[id]]$basis_variant)) {
    current_models[[id]]$basis_variant <- "inherited_thin_plate_sz"
  }
}
placements <- c(near_eye = "Near-eye", chest = "Chest")

frame_index <- readr::read_csv(
  file.path(roots$model_data, "H03_model_frame_index.csv"),
  show_col_types = FALSE
) |>
  dplyr::filter(.data$run_id %in% c("main__near_eye", "main__chest")) |>
  dplyr::arrange(match(.data$run_id, c("main__near_eye", "main__chest")))
expected_frame_hashes <- stats::setNames(
  frame_index$frame_sha256,
  frame_index$run_id
)
current_cache <- attr(current_models, "h03_temporal_cache")
current_formula_text <- paste(
  deparse(h03_formula_set()$temporal_category),
  collapse = " "
)
if (
  !identical(names(current_models), c("near_eye", "chest")) ||
    !identical(current_cache$r_version, as.character(getRversion())) ||
    !identical(current_cache$frame_sha256, expected_frame_hashes) ||
    !identical(current_cache$formula, current_formula_text)
) {
  h03_abort("Approved H03 temporal checkpoint failed provenance validation")
}

cyclic_formula <- h03_formula_set()$temporal_category_cyclic_sz
cyclic_formula_text <- paste(deparse(cyclic_formula), collapse = " ")
cyclic_model_path <- file.path(
  roots$models,
  "H03_temporal_cyclic_sz_candidate_objects.rds"
)
cyclic_cache_valid <- FALSE
if (file.exists(cyclic_model_path)) {
  cyclic_models <- readRDS(cyclic_model_path)
  cyclic_cache <- attr(cyclic_models, "h03_temporal_cyclic_cache")
  cyclic_cache_valid <-
    identical(names(cyclic_models), c("near_eye", "chest")) &&
    identical(cyclic_cache$r_version, as.character(getRversion())) &&
    identical(cyclic_cache$frame_sha256, expected_frame_hashes) &&
    identical(cyclic_cache$formula, cyclic_formula_text) &&
    stats::nobs(cyclic_models$near_eye$final) == nrow(frames$near_eye) &&
    stats::nobs(cyclic_models$chest$final) == nrow(frames$chest)
}

if (cyclic_cache_valid) {
  message("Reusing validated H03 fully cyclic sz candidate checkpoint")
} else {
  message("Fitting H03 fully cyclic sz candidate: Near-eye")
  cyclic_near <- h03_fit_temporal_model(
    frames$near_eye,
    "temporal_cyclic_sz__near_eye",
    formula = cyclic_formula,
    basis_variant = "cyclic_sz"
  )
  message("Fitting H03 fully cyclic sz candidate: Chest")
  cyclic_chest <- h03_fit_temporal_model(
    frames$chest,
    "temporal_cyclic_sz__chest",
    formula = cyclic_formula,
    basis_variant = "cyclic_sz"
  )
  cyclic_models <- list(near_eye = cyclic_near, chest = cyclic_chest)
  attr(cyclic_models, "h03_temporal_cyclic_cache") <- list(
    r_version = as.character(getRversion()),
    frame_sha256 = expected_frame_hashes,
    formula = cyclic_formula_text
  )
  metadata[["cyclic_models"]] <- write_rds_artifact(
    cyclic_models,
    cyclic_model_path,
    producer
  )
}
if (cyclic_cache_valid) {
  model_info <- file.info(cyclic_model_path)
  metadata[["cyclic_models"]] <- list(
    path = normalizePath(cyclic_model_path, winslash = "/", mustWork = TRUE),
    sha256 = artifact_sha256(cyclic_model_path),
    bytes = unname(model_info$size),
    producer = producer,
    r_version = as.character(getRversion()),
    written_utc = format(model_info$mtime, tz = "UTC", usetz = TRUE)
  )
}

model_registry <- tibble::tribble(
  ~model_id, ~model_label, ~basis_variant, ~exact_formula,
  "inherited_sz", "Inherited thin-plate sz", "inherited_thin_plate_sz",
  current_formula_text,
  "cyclic_sz", "Fully cyclic sz", "cyclic_sz", cyclic_formula_text
)

model_sets <- list(
  inherited_sz = current_models,
  cyclic_sz = cyclic_models
)

h03_safe_loglik <- function(fit) {
  tryCatch(stats::logLik(fit), error = function(condition) NULL)
}

h03_fit_row <- function(object, placement, candidate_id) {
  registry_index <- match(candidate_id, model_registry$model_id)
  if (is.na(registry_index)) {
    h03_abort("Unknown temporal basis candidate: %s", candidate_id)
  }
  model_label <- model_registry$model_label[[registry_index]]
  summary_row <- h03_temporal_model_summary(object, placement)
  k_check <- h03_temporal_k_check(object, placement)
  category_midnight <- h03_temporal_midnight_diagnostic(object, placement)
  site_midnight <- h03_temporal_site_midnight_diagnostic(object, placement)
  acf <- h03_temporal_residual_acf(object, placement)
  constraints <- h03_temporal_constraint_diagnostics(
    object,
    h03_temporal_curves(object, h03_category_registry(root)),
    placement
  )
  log_likelihood <- h03_safe_loglik(object$final)
  global_index <- match("s(time_hour)", k_check$term)
  if (is.na(global_index)) {
    h03_abort(
      "Global time k diagnostic missing for %s: %s",
      candidate_id,
      placement
    )
  }
  row_values <- list(
    placement = placement,
    model_id = candidate_id,
    model_label = model_label,
    basis_variant = summary_row$basis_variant,
    formula = summary_row$formula,
    observations = summary_row$observations,
    rho = summary_row$rho,
    rank = summary_row$rank,
    coefficients = summary_row$coefficients,
    total_edf = summary_row$total_edf,
    adjusted_r_squared = summary_row$adjusted_r_squared,
    deviance_explained = summary_row$deviance_explained,
    residual_scale = summary_row$residual_scale,
    f_reml_score = as.numeric(object$final$gcv.ubre),
    log_likelihood = if (is.null(log_likelihood)) {
      NA_real_
    } else {
      as.numeric(log_likelihood)
    },
    log_likelihood_df = if (is.null(log_likelihood)) {
      NA_real_
    } else {
      as.numeric(attr(log_likelihood, "df"))
    },
    aic = tryCatch(
      as.numeric(stats::AIC(object$final)),
      error = function(condition) NA_real_
    ),
    converged = summary_row$converged,
    convergence = summary_row$convergence,
    warning_count = if (
      is.na(summary_row$warnings) || !nzchar(summary_row$warnings)
    ) {
      0L
    } else {
      length(strsplit(summary_row$warnings, " | ", fixed = TRUE)[[1L]])
    },
    smoothing_gradient_maximum_absolute =
      summary_row$smoothing_gradient_maximum_absolute,
    smoothing_hessian_minimum_eigenvalue =
      summary_row$smoothing_hessian_minimum_eigenvalue,
    smoothing_hessian_positive_definite =
      summary_row$smoothing_hessian_positive_definite,
    standardized_residual_lag1 = summary_row$standardized_residual_lag1,
    residual_skewness = summary_row$residual_skewness,
    residual_excess_kurtosis = summary_row$residual_excess_kurtosis,
    absolute_residual_fitted_spearman =
      summary_row$absolute_residual_fitted_spearman,
    global_time_k_index = k_check$k_index[[global_index]],
    global_time_edf = k_check$effective_df[[global_index]],
    global_time_k_prime = k_check$k_prime[[global_index]],
    maximum_category_endpoint_difference_log10 = max(
      category_midnight$endpoint_difference_abs
    ),
    maximum_site_endpoint_difference_log10 = max(
      site_midnight$endpoint_difference_abs
    ),
    maximum_sz_constraint_sum = max(constraints$maximum_absolute_sum),
    constraints_pass = all(constraints$passes),
    acf_lags_1_to_6_maximum_absolute = max(abs(acf$correlation)),
    comparison_role = paste(
      "bounded same-data Gaussian bam basis comparison;",
      "no simulation and no preregistered inference"
    )
  )
  value_lengths <- lengths(row_values)
  if (any(value_lengths != 1L)) {
    h03_abort(
      "Temporal comparison row fields must be scalar for %s (%s): %s",
      candidate_id,
      placement,
      paste(
        paste0(names(row_values)[value_lengths != 1L], "=", value_lengths[
          value_lengths != 1L
        ]),
        collapse = ", "
      )
    )
  }
  tibble::as_tibble(row_values)
}

fit_rows <- list()
residual_rows <- list()
acf_rows <- list()
category_midnight_rows <- list()
site_midnight_rows <- list()
appraise_plots <- list()
for (candidate_id in names(model_sets)) {
  registry_index <- match(candidate_id, model_registry$model_id)
  if (is.na(registry_index)) {
    h03_abort("Unknown temporal basis candidate: %s", candidate_id)
  }
  candidate_label <- model_registry$model_label[[registry_index]]
  for (id in names(model_sets[[candidate_id]])) {
    object <- model_sets[[candidate_id]][[id]]
    placement <- placements[[id]]
    key <- paste(candidate_id, id, sep = "__")
    message("Post-processing ", candidate_id, ": ", placement)
    fit_rows[[key]] <- h03_fit_row(object, placement, candidate_id)
    if (nrow(fit_rows[[key]]) != 1L) {
      h03_abort("Temporal fit summary did not return one row: %s", key)
    }
    residual_rows[[key]] <- h03_temporal_residual_data(object, placement) |>
      dplyr::mutate(
        model_id = .env$candidate_id,
        model_label = .env$candidate_label,
        .after = "placement"
      )
    acf_rows[[key]] <- h03_temporal_residual_acf(object, placement) |>
      dplyr::mutate(
        model_id = .env$candidate_id,
        model_label = .env$candidate_label,
        .after = "placement"
      )
    category_midnight_rows[[key]] <-
      h03_temporal_midnight_diagnostic(object, placement) |>
      dplyr::mutate(
        model_id = .env$candidate_id,
        model_label = .env$candidate_label,
        component = "Light-source deviations",
        .after = "placement"
      )
    site_midnight_rows[[key]] <-
      h03_temporal_site_midnight_diagnostic(object, placement) |>
      dplyr::mutate(
        model_id = .env$candidate_id,
        model_label = .env$candidate_label,
        component = "Site deviations",
        .after = "placement"
      )
    if (identical(candidate_id, "cyclic_sz")) {
      appraise_plots[[id]] <- gratia::appraise(
        object$final,
        method = "normal",
        type = "deviance",
        n_simulate = 0L,
        n_uniform = 0L,
        ncol = 2
      )
    }
  }
}

fit_data <- dplyr::bind_rows(fit_rows)
residual_data <- dplyr::bind_rows(residual_rows)
acf_data <- dplyr::bind_rows(acf_rows)
category_midnight_data <- dplyr::bind_rows(category_midnight_rows)
site_midnight_data <- dplyr::bind_rows(site_midnight_rows)

comparison_metrics <- c(
  "aic",
  "f_reml_score",
  "adjusted_r_squared",
  "deviance_explained",
  "residual_scale",
  "standardized_residual_lag1",
  "maximum_category_endpoint_difference_log10",
  "maximum_site_endpoint_difference_log10",
  "converged",
  "smoothing_hessian_positive_definite"
)
inherited_comparison <- fit_data |>
  dplyr::filter(.data$model_id == "inherited_sz") |>
  dplyr::select(
    .data$placement,
    dplyr::all_of(comparison_metrics)
  ) |>
  dplyr::rename_with(
    function(name) paste0(name, "__inherited_sz"),
    -"placement"
  )
cyclic_comparison <- fit_data |>
  dplyr::filter(.data$model_id == "cyclic_sz") |>
  dplyr::select(
    .data$placement,
    dplyr::all_of(comparison_metrics)
  ) |>
  dplyr::rename_with(
    function(name) paste0(name, "__cyclic_sz"),
    -"placement"
  ) |>
  dplyr::arrange(.data$placement)
if (nrow(inherited_comparison) != 2L || nrow(cyclic_comparison) != 2L) {
  h03_abort(
    "Temporal basis comparison expected two placements for each model: %s",
    paste(
      paste(fit_data$model_id, fit_data$placement, sep = "="),
      collapse = ", "
    )
  )
}
comparison <- dplyr::inner_join(
  inherited_comparison,
  cyclic_comparison,
  by = "placement",
  relationship = "one-to-one"
) |>
  dplyr::mutate(
    cyclic_minus_inherited_aic =
      .data$aic__cyclic_sz - .data$aic__inherited_sz,
    cyclic_minus_inherited_f_reml =
      .data$f_reml_score__cyclic_sz - .data$f_reml_score__inherited_sz,
    cyclic_minus_inherited_adjusted_r_squared =
      .data$adjusted_r_squared__cyclic_sz -
      .data$adjusted_r_squared__inherited_sz,
    cyclic_minus_inherited_residual_lag1 =
      .data$standardized_residual_lag1__cyclic_sz -
      .data$standardized_residual_lag1__inherited_sz,
    continuity_result = dplyr::if_else(
      .data$maximum_category_endpoint_difference_log10__cyclic_sz < 1e-8 &
        .data$maximum_site_endpoint_difference_log10__cyclic_sz < 1e-8,
      "cyclic category and site endpoints continuous",
      "cyclic endpoint tolerance not met"
    ),
    comparison_interpretation = paste(
      "Lower AIC/fREML and residual scale, higher adjusted R-squared, and",
      "lower residual autocorrelation favour a candidate; endpoint",
      "continuity is a separate structural requirement. No single metric",
      "automatically selects the exploratory model."
    )
  )

if (
  nrow(fit_data) != 4L ||
    any(!fit_data$converged) ||
    any(fit_data$rank != fit_data$coefficients) ||
    any(!fit_data$constraints_pass) ||
    any(!is.finite(fit_data$aic)) ||
    any(!is.finite(fit_data$f_reml_score))
) {
  h03_abort("H03 cyclic-sz comparison failed a numerical assertion")
}

residual_bins <- residual_data |>
  dplyr::group_by(.data$placement, .data$model_id, .data$model_label) |>
  dplyr::mutate(fitted_bin = dplyr::ntile(.data$fitted_log10, 30L)) |>
  dplyr::group_by(
    .data$placement,
    .data$model_id,
    .data$model_label,
    .data$fitted_bin
  ) |>
  dplyr::summarise(
    observations = dplyr::n(),
    fitted_mean_log10 = mean(.data$fitted_log10),
    residual_mean = mean(.data$standardized_residual),
    residual_q25 = stats::quantile(.data$standardized_residual, 0.25),
    residual_q75 = stats::quantile(.data$standardized_residual, 0.75),
    .groups = "drop"
  )

qq_points <- residual_data |>
  dplyr::group_by(.data$placement, .data$model_id, .data$model_label) |>
  dplyr::arrange(.data$theoretical_normal_quantile, .by_group = TRUE) |>
  dplyr::group_modify(function(data, key) {
    indices <- unique(as.integer(round(seq(
      1,
      nrow(data),
      length.out = min(400L, nrow(data))
    ))))
    data[indices, c("theoretical_normal_quantile", "standardized_residual")]
  }) |>
  dplyr::ungroup()

endpoint_summary <- dplyr::bind_rows(
  category_midnight_data |>
    dplyr::group_by(
      .data$placement,
      .data$model_id,
      .data$model_label,
      .data$component
    ) |>
    dplyr::summarise(
      maximum_absolute_endpoint_difference = max(
        .data$endpoint_difference_abs
      ),
      .groups = "drop"
    ),
  site_midnight_data |>
    dplyr::group_by(
      .data$placement,
      .data$model_id,
      .data$model_label,
      .data$component
    ) |>
    dplyr::summarise(
      maximum_absolute_endpoint_difference = max(
        .data$endpoint_difference_abs
      ),
      .groups = "drop"
    )
)

model_colours <- c(
  "Inherited thin-plate sz" = "#0072B2",
  "Fully cyclic sz" = "#D55E00"
)
qq_plot <- ggplot2::ggplot(
  qq_points,
  ggplot2::aes(
    x = .data$theoretical_normal_quantile,
    y = .data$standardized_residual,
    colour = .data$model_label
  )
) +
  ggplot2::geom_abline(slope = 1, intercept = 0, colour = "grey55") +
  ggplot2::geom_point(alpha = 0.55, size = 0.8) +
  ggplot2::facet_wrap(ggplot2::vars(.data$placement)) +
  ggplot2::scale_colour_manual(values = model_colours) +
  ggplot2::labs(
    title = "Residual normal-quantile comparison",
    x = "Theoretical normal quantile",
    y = "Standardized residual",
    colour = "Temporal basis"
  ) +
  h03_figure_theme() +
  ggplot2::theme(legend.position = "top")

residual_plot <- ggplot2::ggplot(
  residual_bins,
  ggplot2::aes(
    x = .data$fitted_mean_log10,
    y = .data$residual_mean,
    colour = .data$model_label,
    fill = .data$model_label
  )
) +
  ggplot2::geom_hline(yintercept = 0, colour = "grey55", linetype = "dashed") +
  ggplot2::geom_ribbon(
    ggplot2::aes(ymin = .data$residual_q25, ymax = .data$residual_q75),
    alpha = 0.15,
    colour = NA
  ) +
  ggplot2::geom_line(linewidth = 0.8) +
  ggplot2::facet_wrap(ggplot2::vars(.data$placement)) +
  ggplot2::scale_colour_manual(values = model_colours) +
  ggplot2::scale_fill_manual(values = model_colours) +
  ggplot2::labs(
    title = "Binned residuals versus fitted values",
    x = "Fitted log10(melEDI + 0.1)",
    y = "Standardized residual",
    colour = "Temporal basis",
    fill = "Temporal basis"
  ) +
  h03_figure_theme() +
  ggplot2::theme(legend.position = "none")

acf_plot <- ggplot2::ggplot(
  acf_data,
  ggplot2::aes(
    x = .data$lag,
    y = .data$correlation,
    colour = .data$model_label,
    group = .data$model_label
  )
) +
  ggplot2::geom_hline(yintercept = 0, colour = "grey55") +
  ggplot2::geom_line(linewidth = 0.8) +
  ggplot2::geom_point(size = 2) +
  ggplot2::facet_wrap(ggplot2::vars(.data$placement)) +
  ggplot2::scale_x_continuous(breaks = 1:6) +
  ggplot2::scale_colour_manual(values = model_colours) +
  ggplot2::labs(
    title = "Boundary-aware residual autocorrelation",
    x = "Lag (hours)",
    y = "Residual correlation",
    colour = "Temporal basis"
  ) +
  h03_figure_theme() +
  ggplot2::theme(legend.position = "none")

endpoint_plot <- ggplot2::ggplot(
  endpoint_summary,
  ggplot2::aes(
    x = .data$component,
    y = .data$maximum_absolute_endpoint_difference,
    colour = .data$model_label,
    group = .data$model_label
  )
) +
  ggplot2::geom_hline(yintercept = 0, colour = "grey55") +
  ggplot2::geom_point(
    position = ggplot2::position_dodge(width = 0.45),
    size = 2.8
  ) +
  ggplot2::facet_wrap(ggplot2::vars(.data$placement)) +
  ggplot2::scale_colour_manual(values = model_colours) +
  ggplot2::labs(
    title = "Maximum midnight discontinuity",
    x = NULL,
    y = "Absolute 24:00 minus 00:00 difference\n(log10 scale)",
    colour = "Temporal basis"
  ) +
  h03_figure_theme() +
  ggplot2::theme(legend.position = "none")

diagnostic_figure <- patchwork::wrap_plots(
  qq_plot,
  residual_plot,
  acf_plot,
  endpoint_plot,
  ncol = 2
) +
  patchwork::plot_annotation(
    tag_levels = "A",
    title = "Temporal-basis diagnostic comparison",
    caption = paste(
      "All panels use the identical fitted rows. Residual displays are",
      "descriptive; no diagnostic simulation or resampling was run."
    ),
    theme = h03_figure_theme()
  )

h03_write_csv(
  model_registry,
  file.path(roots$tables, "H03_temporal_basis_model_registry.csv"),
  "model_registry"
)
h03_write_csv(
  fit_data,
  file.path(roots$tables, "H03_temporal_basis_fit_comparison.csv"),
  "fit_comparison"
)
h03_write_csv(
  comparison,
  file.path(roots$tables, "H03_temporal_basis_comparison_deltas.csv"),
  "comparison_deltas"
)
h03_write_csv(
  acf_data,
  file.path(roots$diagnostics, "H03_temporal_basis_residual_acf.csv"),
  "residual_acf"
)
h03_write_csv(
  category_midnight_data,
  file.path(
    roots$diagnostics,
    "H03_temporal_basis_category_midnight_diagnostics.csv"
  ),
  "category_midnight"
)
h03_write_csv(
  site_midnight_data,
  file.path(
    roots$diagnostics,
    "H03_temporal_basis_site_midnight_diagnostics.csv"
  ),
  "site_midnight"
)
h03_write_csv(
  residual_bins,
  file.path(roots$source_data, "H03_temporal_basis_residual_bins.csv"),
  "residual_bins"
)
h03_write_csv(
  qq_points,
  file.path(roots$source_data, "H03_temporal_basis_qq_points.csv"),
  "qq_points"
)
h03_write_csv(
  endpoint_summary,
  file.path(roots$source_data, "H03_temporal_basis_endpoint_summary.csv"),
  "endpoint_summary"
)
h03_record_plot_metadata(
  h03_save_plot(
    diagnostic_figure,
    "H03_temporal_basis_diagnostic_comparison",
    roots$figures,
    width = 14,
    height = 11,
    producer = producer
  ),
  "diagnostic_comparison"
)
for (id in names(appraise_plots)) {
  h03_record_plot_metadata(
    h03_save_plot(
      appraise_plots[[id]],
      paste0("H03_temporal_cyclic_sz_appraise_", id),
      roots$figures,
      width = 11,
      height = 8,
      producer = producer
    ),
    paste0("cyclic_appraise_", id)
  )
}

manifest <- dplyr::bind_rows(lapply(metadata, manifest_row))
write_csv_artifact(
  manifest,
  file.path(roots$manifests, "H03_temporal_cyclic_sz_comparison_manifest.csv"),
  producer
)

message("H03 fully cyclic sz comparison complete; no simulation was run")
print(as.data.frame(fit_data), row.names = FALSE)
print(as.data.frame(comparison), row.names = FALSE)
