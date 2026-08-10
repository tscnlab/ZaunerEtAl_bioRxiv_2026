#!/usr/bin/env Rscript

# Build the approved Stage 3 descriptive revision: interaction-model category
# summaries and an exploratory category-specific linear absolute-latitude
# replacement for site. The latitude fits are bounded GLMs with leave-one-site-
# out checks; no bootstrap or simulation is run.

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
source(file.path(root, "scripts/hypotheses/H03/h03_reporting.R"))

if (!identical(as.character(getRversion()), "4.6.1")) {
  h03_abort(
    "H03 Stage 3 revision requires R 4.6.1; found %s",
    as.character(getRversion())
  )
}

required_packages <- c(
  "dplyr", "tidyr", "tibble", "readr", "ggplot2", "scales",
  "sandwich", "statmod", "LightLogR", "cowplot", "patchwork",
  "svglite", "ragg"
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

producer <- "scripts/hypotheses/H03/build_h03_stage3_revision.R"
model_data_root <- file.path(root, "artifacts/06_model_data/H03")
diagnostic_root <- file.path(root, "artifacts/08_diagnostics/H03")
table_root <- file.path(root, "artifacts/09_tables/H03")
figure_root <- file.path(root, "artifacts/10_figures/H03")
source_root <- file.path(root, "artifacts/11_source_data/H03")
manifest_root <- file.path(root, "artifacts/12_manifests/H03")
invisible(lapply(
  c(diagnostic_root, table_root, figure_root, source_root, manifest_root),
  dir.create,
  recursive = TRUE,
  showWarnings = FALSE
))

metadata <- list()
write_revision_csv <- function(data, path, role) {
  metadata[[role]] <<- write_csv_artifact(data, path, producer)
  invisible(path)
}

inputs <- h03_load_inputs(root)
working_power <- h03_specification()$working_tweedie_power
primary <- readr::read_csv(
  file.path(table_root, "H03_primary_category_estimands.csv"),
  show_col_types = FALSE
)
site_context <- readr::read_csv(
  file.path(table_root, "H03_site_context_estimands.csv"),
  show_col_types = FALSE
)
frames <- readRDS(file.path(model_data_root, "H03_model_frames.rds"))$main

first_finite <- function(value) {
  available <- value[is.finite(value)]
  if (length(available) == 0L) NA_real_ else available[[1L]]
}
first_text <- function(value) {
  available <- value[!is.na(value) & nzchar(value)]
  if (length(available) == 0L) NA_character_ else available[[1L]]
}

interaction_overall <- site_context |>
  dplyr::group_by(
    .data$placement,
    .data$category_order,
    .data$category_code,
    .data$light_source,
    .data$short_label
  ) |>
  dplyr::summarise(
    architecture = first_text(.data$architecture),
    expected_mel_edi_lx = first_finite(
      .data$site_standardized_category_mean_lx
    ),
    expected_conf_low_lx = first_finite(.data$category_mean_conf_low_lx),
    expected_conf_high_lx = first_finite(.data$category_mean_conf_high_lx),
    ratio_to_indoor = first_finite(.data$category_ratio_to_indoor),
    ratio_conf_low = first_finite(.data$category_ratio_conf_low),
    ratio_conf_high = first_finite(.data$category_ratio_conf_high),
    standardization_sites = dplyr::n_distinct(
      .data$site[is.finite(.data$model_cell_mean_lx)]
    ),
    supported_sites = dplyr::n_distinct(
      .data$site[.data$reporting_status == "ESTIMABLE"]
    ),
    .groups = "drop"
  )

interaction_category <- primary |>
  dplyr::select(
    "placement", "category_order", "category_code", "light_source",
    "short_label", "hours", "participants", "participant_days", "sites",
    primary_additive_p_raw = "p_raw",
    primary_additive_p_adjusted = "p_adjusted"
  ) |>
  dplyr::left_join(
    interaction_overall,
    by = c(
      "placement", "category_order", "category_code", "light_source",
      "short_label"
    ),
    relationship = "one-to-one"
  ) |>
  dplyr::mutate(
    run_id = paste0(
      "reader_interaction_summary__",
      gsub("-", "_", tolower(.data$placement))
    ),
    distribution = "site_standardized",
    standardization_status = dplyr::if_else(
      is.finite(.data$expected_mel_edi_lx) &
        is.finite(.data$ratio_to_indoor),
      "ESTIMABLE",
      "CATEGORY_STANDARDIZATION_NON_ESTIMABLE"
    ),
    inferential_role = paste(
      "descriptive site-standardized estimate from accepted heterogeneity",
      "model; primary additive omnibus remains separate"
    ),
    .before = 1
  ) |>
  dplyr::arrange(
    match(.data$placement, c("Near-eye", "Chest")),
    .data$category_order
  )

write_revision_csv(
  interaction_category,
  file.path(table_root, "H03_reader_heterogeneity_category_estimands.csv"),
  "heterogeneity_category_estimands"
)
write_revision_csv(
  interaction_category,
  file.path(
    source_root,
    "H03_reader_heterogeneity_category_figure_data.csv"
  ),
  "heterogeneity_category_figure_data"
)

interaction_figure <- h03_primary_category_figure(
  interaction_category,
  inputs$categories,
  caption_extra = paste0(
    "Estimates come from the accepted category-by-site heterogeneity model.\n",
    "The complementary chest external-light category cannot be standardized ",
    "across all eight sites because one site-category cell is absent."
  )
)
saved_interaction <- h03_save_plot(
  interaction_figure,
  "H03_reader_heterogeneity_category_estimates",
  figure_root,
  width = 12.8,
  height = 10.2,
  producer = producer
)
for (extension in names(saved_interaction)) {
  metadata[[paste0("heterogeneity_category_figure_", extension)]] <-
    saved_interaction[[extension]]
}

latitude_formula <- stats::as.formula(paste(
  "geo_medi_1h ~ 0 + light_source +",
  "light_source:absolute_latitude_10deg_centered"
))

capture_warnings <- function(expression) {
  warnings <- character()
  value <- withCallingHandlers(
    expression,
    warning = function(condition) {
      warnings <<- c(warnings, conditionMessage(condition))
      invokeRestart("muffleWarning")
    }
  )
  list(value = value, warnings = unique(warnings))
}

prepare_latitude_frame <- function(data) {
  site_latitudes <- data |>
    dplyr::distinct(.data$site, .data$latitude_deg) |>
    dplyr::mutate(absolute_latitude_10deg = abs(.data$latitude_deg) / 10)
  if (
    any(!is.finite(site_latitudes$absolute_latitude_10deg)) ||
      anyDuplicated(site_latitudes$site)
  ) {
    h03_abort("Latitude is missing or non-unique within an H03 site")
  }
  center <- mean(site_latitudes$absolute_latitude_10deg)
  list(
    data = data |>
      dplyr::mutate(
        absolute_latitude_10deg_centered =
          abs(.data$latitude_deg) / 10 - center
      ),
    site_latitudes = site_latitudes,
    center_absolute_latitude_deg = center * 10
  )
}

fit_latitude <- function(data) {
  prepared <- prepare_latitude_frame(data)
  fit_capture <- capture_warnings(stats::glm(
    formula = latitude_formula,
    data = prepared$data,
    family = statmod::tweedie(
      var.power = working_power,
      link.power = 0
    )
  ))
  fit <- fit_capture$value
  covariance_capture <- capture_warnings(sandwich::vcovCL(
    fit,
    cluster = prepared$data$site,
    type = "HC1",
    cadjust = TRUE,
    fix = FALSE
  ))
  covariance <- covariance_capture$value
  list(
    data = prepared$data,
    site_latitudes = prepared$site_latitudes,
    center_absolute_latitude_deg =
      prepared$center_absolute_latitude_deg,
    fit = fit,
    covariance = covariance,
    warnings = unique(c(
      fit_capture$warnings,
      covariance_capture$warnings
    ))
  )
}

extract_latitude_slopes <- function(bundle, placement, run_id) {
  categories <- levels(bundle$data$light_source)
  coefficient_names <- names(stats::coef(bundle$fit))
  df <- dplyr::n_distinct(bundle$data$site) - 1L
  critical <- stats::qt(0.975, df = df)
  result <- lapply(seq_along(categories), function(index) {
    category <- categories[[index]]
    new_data <- tibble::tibble(
      light_source = factor(category, levels = categories),
      absolute_latitude_10deg_centered = c(0, 1)
    )
    design <- stats::model.matrix(
      stats::delete.response(stats::terms(bundle$fit)),
      data = new_data,
      contrasts.arg = bundle$fit$contrasts
    )
    design <- design[, coefficient_names, drop = FALSE]
    contrast <- design[2L, ] - design[1L, ]
    estimate <- drop(contrast %*% stats::coef(bundle$fit))
    variance <- drop(contrast %*% bundle$covariance %*% contrast)
    standard_error <- if (is.finite(variance) && variance >= 0) {
      sqrt(variance)
    } else {
      NA_real_
    }
    statistic <- estimate / standard_error
    p_raw <- 2 * stats::pt(-abs(statistic), df = df)
    support <- bundle$data |>
      dplyr::filter(as.character(.data$light_source) == .env$category)
    tibble::tibble(
      run_id = run_id,
      placement = placement,
      category_order = index,
      light_source = category,
      estimate_log_ratio_per_10deg = estimate,
      standard_error = standard_error,
      statistic = statistic,
      df = df,
      p_raw = p_raw,
      ratio_per_10deg = exp(estimate),
      ratio_conf_low = exp(estimate - critical * standard_error),
      ratio_conf_high = exp(estimate + critical * standard_error),
      hours = nrow(support),
      participants = dplyr::n_distinct(support$participant),
      participant_days = dplyr::n_distinct(support$participant_day),
      category_sites = dplyr::n_distinct(support$site),
      model_sites = dplyr::n_distinct(bundle$data$site),
      centered_at_absolute_latitude_deg =
        bundle$center_absolute_latitude_deg
    )
  }) |>
    dplyr::bind_rows() |>
    dplyr::left_join(
      inputs$categories |>
        dplyr::transmute(
          light_source = .data$category_label,
          .data$category_code,
          .data$short_label
        ),
      by = "light_source",
      relationship = "many-to-one"
    )
  result$p_adjusted <- stats::p.adjust(result$p_raw, method = "BH")
  result$family_id <- paste0(
    "H03-exploratory-latitude-slopes__",
    gsub("-", "_", tolower(placement))
  )
  result$family_n <- nrow(result)
  result
}

placement_frames <- list(
  near_eye = list(placement = "Near-eye", data = frames$near_eye),
  chest = list(placement = "Chest", data = frames$chest)
)
latitude_bundles <- list()
latitude_slopes <- list()
latitude_diagnostics <- list()
latitude_site_support <- list()
latitude_loso <- list()

for (key in names(placement_frames)) {
  entry <- placement_frames[[key]]
  message("Fitting exploratory latitude replacement: ", entry$placement)
  bundle <- fit_latitude(entry$data)
  latitude_bundles[[key]] <- bundle
  latitude_slopes[[key]] <- extract_latitude_slopes(
    bundle,
    entry$placement,
    paste0("latitude_full__", key)
  )
  design <- stats::model.matrix(bundle$fit)
  latitude_diagnostics[[key]] <- tibble::tibble(
    run_id = paste0("latitude_full__", key),
    placement = entry$placement,
    formula = paste(deparse(latitude_formula), collapse = " "),
    response = "raw one-hour zero-aware geometric melEDI (lx)",
    family = paste0(
      "quasi-Tweedie working mean, log link, p = ",
      sprintf("%.6f", working_power)
    ),
    observations = nrow(bundle$data),
    participants = dplyr::n_distinct(bundle$data$participant),
    participant_days = dplyr::n_distinct(bundle$data$participant_day),
    sites = dplyr::n_distinct(bundle$data$site),
    center_absolute_latitude_deg =
      bundle$center_absolute_latitude_deg,
    converged = isTRUE(bundle$fit$converged),
    iterations = bundle$fit$iter,
    design_rank = qr(design)$rank,
    coefficients = ncol(design),
    covariance_rank = qr(bundle$covariance)$rank,
    covariance_dimension = nrow(bundle$covariance),
    covariance_finite = all(is.finite(bundle$covariance)),
    covariance_diagonal_positive = all(diag(bundle$covariance) > 0),
    warning_count = length(bundle$warnings),
    warnings = if (length(bundle$warnings) == 0L) {
      NA_character_
    } else {
      paste(bundle$warnings, collapse = " | ")
    },
    inference = paste(
      "site-cluster HC1 coefficient-wise t tests with sites minus one df;",
      "seven slope p-values BH-adjusted within placement; no joint slope",
      "omnibus because the cluster covariance rank is bounded by sites minus one"
    )
  )
  latitude_site_support[[key]] <- bundle$site_latitudes |>
    dplyr::mutate(
      placement = entry$placement,
      centered_absolute_latitude_10deg =
        .data$absolute_latitude_10deg -
        bundle$center_absolute_latitude_deg / 10,
      .before = 1
    )

  sites <- levels(droplevels(bundle$data$site))
  for (omitted_site in sites) {
    reduced <- bundle$data |>
      dplyr::filter(as.character(.data$site) != .env$omitted_site) |>
      droplevels()
    reduced_capture <- tryCatch(
      list(value = fit_latitude(reduced), error = NA_character_),
      error = function(condition) {
        list(value = NULL, error = conditionMessage(condition))
      }
    )
    if (is.null(reduced_capture$value)) {
      latitude_loso[[paste(key, omitted_site, sep = "__")]] <-
        inputs$categories |>
        dplyr::transmute(
          placement = entry$placement,
          omitted_site = omitted_site,
          .data$category_order,
          .data$category_code,
          .data$short_label,
          estimate_log_ratio_per_10deg = NA_real_,
          ratio_per_10deg = NA_real_,
          converged = FALSE,
          error = reduced_capture$error
        )
      next
    }
    reduced_slopes <- extract_latitude_slopes(
      reduced_capture$value,
      entry$placement,
      paste0("latitude_loso__", key, "__", omitted_site)
    )
    latitude_loso[[paste(key, omitted_site, sep = "__")]] <-
      reduced_slopes |>
      dplyr::transmute(
        .data$placement,
        omitted_site = omitted_site,
        .data$category_order,
        .data$category_code,
        .data$short_label,
        .data$estimate_log_ratio_per_10deg,
        .data$ratio_per_10deg,
        converged = isTRUE(reduced_capture$value$fit$converged),
        error = NA_character_
      )
  }
}

latitude_slope_data <- dplyr::bind_rows(latitude_slopes)
latitude_diagnostic_data <- dplyr::bind_rows(latitude_diagnostics)
latitude_site_support_data <- dplyr::bind_rows(latitude_site_support)
latitude_loso_data <- dplyr::bind_rows(latitude_loso)

latitude_loso_summary <- latitude_loso_data |>
  dplyr::left_join(
    latitude_slope_data |>
      dplyr::select(
        "placement",
        "category_code",
        full_estimate = "estimate_log_ratio_per_10deg"
      ),
    by = c("placement", "category_code"),
    relationship = "many-to-one"
  ) |>
  dplyr::group_by(
    .data$placement,
    .data$category_order,
    .data$category_code,
    .data$short_label
  ) |>
  dplyr::summarise(
    omissions = dplyr::n(),
    successful = sum(.data$converged & is.finite(.data$ratio_per_10deg)),
    sign_agreement = sum(
      sign(.data$estimate_log_ratio_per_10deg) == sign(.data$full_estimate),
      na.rm = TRUE
    ),
    ratio_min = min(.data$ratio_per_10deg, na.rm = TRUE),
    ratio_max = max(.data$ratio_per_10deg, na.rm = TRUE),
    .groups = "drop"
  )

latitude_slope_data <- latitude_slope_data |>
  dplyr::left_join(
    latitude_loso_summary,
    by = c(
      "placement", "category_order", "category_code", "short_label"
    ),
    relationship = "one-to-one"
  ) |>
  dplyr::mutate(
    inferential_role = paste(
      "exploratory ecological association per 10-degree increase in",
      "absolute latitude; latitude replaces fixed site"
    )
  ) |>
  dplyr::arrange(
    match(.data$placement, c("Near-eye", "Chest")),
    .data$category_order
  )

write_revision_csv(
  latitude_slope_data,
  file.path(table_root, "H03_reader_latitude_category_slopes.csv"),
  "latitude_category_slopes"
)
write_revision_csv(
  latitude_diagnostic_data,
  file.path(diagnostic_root, "H03_reader_latitude_model_diagnostics.csv"),
  "latitude_model_diagnostics"
)
write_revision_csv(
  latitude_loso_data,
  file.path(diagnostic_root, "H03_reader_latitude_leave_one_site_out.csv"),
  "latitude_leave_one_site_out"
)
write_revision_csv(
  latitude_site_support_data,
  file.path(source_root, "H03_reader_latitude_site_support.csv"),
  "latitude_site_support"
)
write_revision_csv(
  latitude_slope_data,
  file.path(source_root, "H03_reader_latitude_figure_data.csv"),
  "latitude_figure_data"
)

latitude_display <- latitude_slope_data |>
  dplyr::mutate(
    placement = factor(.data$placement, levels = c("Near-eye", "Chest")),
    short_label = factor(
      .data$short_label,
      levels = rev(inputs$categories$short_label)
    ),
    adjusted_label = .data$p_adjusted < 0.05
  )
latitude_palette <- stats::setNames(
  c(
    "#4477AA", "#EE6677", "#228833", "#CCBB44", "#66CCEE",
    "#AA3377", "#777777"
  ),
  inputs$categories$category_code
)
latitude_figure <- ggplot2::ggplot(
  latitude_display,
  ggplot2::aes(
    x = .data$ratio_per_10deg,
    y = .data$short_label,
    colour = .data$category_code
  )
) +
  ggplot2::geom_vline(
    xintercept = 1,
    linetype = "dashed",
    colour = "grey45"
  ) +
  ggplot2::geom_errorbar(
    ggplot2::aes(
      xmin = .data$ratio_conf_low,
      xmax = .data$ratio_conf_high
    ),
    orientation = "y",
    width = 0,
    linewidth = 0.7
  ) +
  ggplot2::geom_point(
    data = dplyr::filter(latitude_display, !.data$adjusted_label),
    shape = 21,
    fill = "white",
    size = 3,
    stroke = 0.7
  ) +
  ggplot2::geom_point(
    data = dplyr::filter(latitude_display, .data$adjusted_label),
    ggplot2::aes(fill = .data$category_code),
    shape = 21,
    size = 3,
    stroke = 0.7
  ) +
  ggplot2::facet_wrap(ggplot2::vars(.data$placement), nrow = 1) +
  ggplot2::scale_x_log10(
    breaks = c(0.5, 0.75, 1, 1.5, 2, 3),
    labels = scales::label_number(accuracy = 0.01)
  ) +
  ggplot2::scale_colour_manual(values = latitude_palette, guide = "none") +
  ggplot2::scale_fill_manual(values = latitude_palette, guide = "none") +
  ggplot2::labs(
    title = "Exploratory linear absolute-latitude gradient by light source",
    subtitle = paste(
      "Factor change in expected melEDI per 10° farther from the equator;",
      "site-level robust 95% intervals"
    ),
    x = "Ratio per +10° absolute latitude",
    y = NULL,
    caption = paste0(
      "Latitude replaces categorical site in a separate model. Filled points pass BH adjustment across seven category slopes within placement.\n",
      "Only nine near-eye and eight chest site latitudes are available; leave-one-site-out ranges are reported in the table."
    )
  ) +
  h03_figure_theme()

saved_latitude <- h03_save_plot(
  latitude_figure,
  "H03_reader_latitude_category_slopes",
  figure_root,
  width = 12.8,
  height = 6.4,
  producer = producer
)
for (extension in names(saved_latitude)) {
  metadata[[paste0("latitude_figure_", extension)]] <-
    saved_latitude[[extension]]
}

figure_qa <- tibble::tribble(
  ~figure, ~base_width_in, ~base_height_in, ~raster_dpi,
  ~intended_display_width_mm, ~smallest_essential_nominal_pt,
  ~smallest_essential_effective_pt, ~final_asset_tightly_bounded,
  "H03_reader_heterogeneity_category_estimates", 12.8, 10.2, 300,
  170, 12, 12 * (170 / 25.4) / 12.8, TRUE,
  "H03_reader_latitude_category_slopes", 12.8, 6.4, 300,
  170, 12, 12 * (170 / 25.4) / 12.8, TRUE
)
write_revision_csv(
  figure_qa,
  file.path(manifest_root, "H03_stage3_revision_figure_readability_qa.csv"),
  "revision_figure_readability_qa"
)

manifest <- dplyr::bind_rows(lapply(metadata, manifest_row)) |>
  dplyr::arrange(.data$path)
invisible(write_csv_artifact(
  manifest,
  file.path(manifest_root, "H03_stage3_revision_asset_manifest.csv"),
  producer
))

message(
  "H03 Stage 3 revision assets complete: interaction summaries, two bounded ",
  "latitude models, and leave-one-site-out checks; no bootstrap or simulation"
)
