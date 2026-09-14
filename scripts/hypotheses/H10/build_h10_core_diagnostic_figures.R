#!/usr/bin/env Rscript

# Build residual-versus-fitted and normal Q-Q displays from the frozen H10
# diagnostic point data. No model is fitted, refitted, or predicted here.

suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
  library(readr)
  library(stringr)
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
      "H10 diagnostic displays require R 4.6.1; running %s",
      getRversion()
    ),
    call. = FALSE
  )
}

producer <- paste0(
  "scripts/hypotheses/H10/",
  "build_h10_core_diagnostic_figures.R"
)
figure_dir <- file.path(root, "artifacts/10_figures/H10")
source_dir <- file.path(root, "artifacts/11_source_data/H10")
manifest_dir <- file.path(root, "artifacts/12_manifests/H10")
dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(source_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(manifest_dir, recursive = TRUE, showWarnings = FALSE)

diagnostic_points_relative <- paste0(
  "artifacts/11_source_data/H10/",
  "H10_primary_diagnostic_plot_data.csv"
)
main_results_relative <- paste0(
  "artifacts/09_tables/H10/",
  "H10_primary_main_results.csv"
)
diagnostic_assessment_relative <- paste0(
  "artifacts/08_diagnostics/H10/",
  "H10_primary_diagnostic_assessment.csv"
)
model_frame_index_relative <- paste0(
  "artifacts/06_model_data/H10/",
  "H10_model_frame_index.csv"
)
site_registry_relative <- "config/site_display_registry.csv"

stage2_manifest <- readr::read_csv(
  file.path(
    root,
    "artifacts/12_manifests/H10/H10_stage2_artifacts.csv"
  ),
  show_col_types = FALSE,
  progress = FALSE
)
input_audit <- readr::read_csv(
  file.path(root, "artifacts/06_model_data/H10/H10_input_audit.csv"),
  show_col_types = FALSE,
  progress = FALSE
)

assert_stage2_identity <- function(relative_path) {
  record <- stage2_manifest |>
    filter(.data$path == .env$relative_path)
  if (nrow(record) != 1L) {
    stop(
      "Missing unique H10 Stage 2 identity for `",
      relative_path,
      "`",
      call. = FALSE
    )
  }
  observed <- artifact_sha256(file.path(root, relative_path))
  if (!identical(observed, record$sha256[[1L]])) {
    stop(
      "Frozen H10 Stage 2 input changed: `",
      relative_path,
      "`",
      call. = FALSE
    )
  }
  invisible(TRUE)
}

invisible(lapply(
  c(
    diagnostic_points_relative,
    main_results_relative,
    diagnostic_assessment_relative,
    model_frame_index_relative
  ),
  assert_stage2_identity
))
site_record <- input_audit |>
  filter(.data$input_role == "site_display_registry")
if (
  nrow(site_record) != 1L ||
    !identical(
      artifact_sha256(file.path(root, site_registry_relative)),
      site_record$observed_sha256[[1L]]
    )
) {
  stop("The submitted site-display registry identity changed", call. = FALSE)
}

diagnostic_points <- readr::read_csv(
  file.path(root, diagnostic_points_relative),
  show_col_types = FALSE,
  progress = FALSE
)
main_results <- readr::read_csv(
  file.path(root, main_results_relative),
  show_col_types = FALSE,
  progress = FALSE
)
diagnostic_assessment <- readr::read_csv(
  file.path(root, diagnostic_assessment_relative),
  show_col_types = FALSE,
  progress = FALSE
)
model_frame_index <- readr::read_csv(
  file.path(root, model_frame_index_relative),
  show_col_types = FALSE,
  progress = FALSE
)
expected_diagnostic_points <- model_frame_index |>
  filter(.data$data_scenario == "primary") |>
  summarise(expected = 2L * sum(.data$observations)) |>
  pull(.data$expected)
site_registry <- readr::read_csv(
  file.path(root, site_registry_relative),
  show_col_types = FALSE,
  progress = FALSE
) |>
  arrange(.data$display_order)

model_keys <- c("placement", "predictor", "metric_id")
if (
  nrow(diagnostic_points) != expected_diagnostic_points ||
    nrow(main_results) != 68L ||
    nrow(diagnostic_assessment) != 68L ||
    nrow(site_registry) != 9L ||
    anyDuplicated(main_results[model_keys]) ||
    anyDuplicated(diagnostic_assessment[model_keys]) ||
    nrow(distinct(diagnostic_points, across(all_of(model_keys)))) != 68L ||
    sum(main_results$adjusted_significant) != 11L ||
    any(!is.finite(diagnostic_points$fitted_model_scale)) ||
    any(!is.finite(diagnostic_points$residual_pearson)) ||
    any(!is.finite(diagnostic_points$qq_theoretical)) ||
    any(!is.finite(diagnostic_points$qq_observed))
) {
  stop("Frozen H10 diagnostic-point invariants changed", call. = FALSE)
}

site_levels <- site_registry$display_name
site_colours <- stats::setNames(
  site_registry$color_hex,
  site_registry$display_name
)
placement_levels <- c("glasses", "chest")
predictor_levels <- c("age", "biological_sex")

model_index <- diagnostic_points |>
  distinct(
    across(all_of(model_keys)),
    metric_order,
    manuscript_name,
    abbreviation,
    response_family,
    response_transform,
    analysis_unit
  ) |>
  left_join(
    main_results |>
      select(
        all_of(model_keys),
        adjusted_significant,
        p_adjusted,
        effect_95_ci_display
      ),
    by = model_keys
  ) |>
  left_join(
    diagnostic_assessment |>
      select(
        all_of(model_keys),
        final_assessment,
        diagnostic_issues,
        residual_qq_correlation,
        residual_absolute_fitted_spearman,
        serial_status,
        deletion_status,
        site_influence_assessment
      ),
    by = model_keys
  ) |>
  mutate(
    placement_rank = match(.data$placement, placement_levels),
    predictor_rank = match(.data$predictor, predictor_levels),
    placement_display = recode(
      .data$placement,
      glasses = "Near eye (primary)",
      chest = "Chest (complementary)"
    ),
    predictor_display = recode(
      .data$predictor,
      age = "Age, per 10 years",
      biological_sex = "Measured biological sex, Female minus Male"
    ),
    model_key = paste(
      .data$placement,
      .data$predictor,
      .data$metric_id,
      sep = "__"
    )
  ) |>
  arrange(
    .data$placement_rank,
    .data$predictor_rank,
    .data$metric_order
  ) |>
  mutate(page = dplyr::row_number())

if (
  nrow(model_index) != 68L ||
    anyDuplicated(model_index$model_key) ||
    anyNA(model_index$final_assessment) ||
    sum(model_index$adjusted_significant) != 11L
) {
  stop("Invalid H10 diagnostic model index", call. = FALSE)
}

qq_reference <- diagnostic_points |>
  group_by(across(all_of(model_keys))) |>
  summarise(
    observed_q25 = stats::quantile(
      .data$qq_observed,
      probs = 0.25,
      names = FALSE,
      na.rm = TRUE
    ),
    observed_q75 = stats::quantile(
      .data$qq_observed,
      probs = 0.75,
      names = FALSE,
      na.rm = TRUE
    ),
    .groups = "drop"
  ) |>
  mutate(
    theoretical_q25 = stats::qnorm(0.25),
    theoretical_q75 = stats::qnorm(0.75),
    reference_slope = (.data$observed_q75 - .data$observed_q25) /
      (.data$theoretical_q75 - .data$theoretical_q25),
    reference_intercept = .data$observed_q25 -
      .data$reference_slope * .data$theoretical_q25
  ) |>
  select(
    all_of(model_keys),
    reference_intercept,
    reference_slope
  )

point_context <- diagnostic_points |>
  select(
    all_of(model_keys),
    metric_order,
    manuscript_name,
    model_row_id,
    site,
    fitted_model_scale,
    residual_pearson,
    qq_theoretical,
    qq_observed
  ) |>
  left_join(
    site_registry |>
      transmute(
        site = .data$site,
        site_display_order = .data$display_order,
        site_display_name = .data$display_name,
        site_color_hex = .data$color_hex
      ),
    by = "site"
  ) |>
  left_join(
    model_index |>
      select(
        all_of(model_keys),
        model_key,
        page,
        placement_rank,
        predictor_rank,
        placement_display,
        predictor_display,
        adjusted_significant,
        final_assessment,
        diagnostic_issues
      ),
    by = model_keys
  )

residual_fitted <- point_context |>
  transmute(
    across(all_of(model_keys)),
    .data$model_key,
    .data$page,
    .data$placement_rank,
    .data$predictor_rank,
    .data$metric_order,
    .data$manuscript_name,
    .data$placement_display,
    .data$predictor_display,
    .data$adjusted_significant,
    .data$final_assessment,
    .data$diagnostic_issues,
    .data$model_row_id,
    .data$site,
    .data$site_display_order,
    .data$site_display_name,
    .data$site_color_hex,
    diagnostic_order = 1L,
    diagnostic_type = "Residuals vs fitted",
    x = .data$fitted_model_scale,
    y = .data$residual_pearson,
    reference_intercept = 0,
    reference_slope = 0
  )

normal_qq <- point_context |>
  left_join(qq_reference, by = model_keys) |>
  transmute(
    across(all_of(model_keys)),
    .data$model_key,
    .data$page,
    .data$placement_rank,
    .data$predictor_rank,
    .data$metric_order,
    .data$manuscript_name,
    .data$placement_display,
    .data$predictor_display,
    .data$adjusted_significant,
    .data$final_assessment,
    .data$diagnostic_issues,
    .data$model_row_id,
    .data$site,
    .data$site_display_order,
    .data$site_display_name,
    .data$site_color_hex,
    diagnostic_order = 2L,
    diagnostic_type = "Normal Q-Q",
    x = .data$qq_theoretical,
    y = .data$qq_observed,
    .data$reference_intercept,
    .data$reference_slope
  )

all_plot_data <- bind_rows(residual_fitted, normal_qq) |>
  mutate(
    site_display_name = factor(
      .data$site_display_name,
      levels = site_levels
    ),
    panel_label = paste0(
      .data$placement_display,
      " · ",
      stringr::str_wrap(.data$manuscript_name, width = 35),
      "\n",
      .data$diagnostic_type
    )
  ) |>
  arrange(
    .data$page,
    .data$diagnostic_order,
    .data$model_row_id
  )

if (
  nrow(all_plot_data) != 2L * nrow(diagnostic_points) ||
    anyDuplicated(all_plot_data[c(
      "model_key",
      "diagnostic_type",
      "model_row_id"
    )]) ||
    anyNA(all_plot_data$site_display_name) ||
    any(!is.finite(all_plot_data$x)) ||
    any(!is.finite(all_plot_data$y)) ||
    any(!is.finite(all_plot_data$reference_intercept)) ||
    any(!is.finite(all_plot_data$reference_slope))
) {
  stop("Invalid H10 core-diagnostic plot data", call. = FALSE)
}

retained_age <- all_plot_data |>
  filter(.data$adjusted_significant, .data$predictor == "age")
retained_sex <- all_plot_data |>
  filter(
    .data$adjusted_significant,
    .data$predictor == "biological_sex"
  )
if (
  nrow(distinct(retained_age, model_key)) != 9L ||
    nrow(distinct(retained_sex, model_key)) != 2L
) {
  stop("Unexpected retained H10 diagnostic-model set", call. = FALSE)
}

all_source_relative <- paste0(
  "artifacts/11_source_data/H10/",
  "H10_all_primary_core_diagnostic_data.csv"
)
age_source_relative <- paste0(
  "artifacts/11_source_data/H10/",
  "H10_retained_age_core_diagnostic_data.csv"
)
sex_source_relative <- paste0(
  "artifacts/11_source_data/H10/",
  "H10_retained_biological_sex_core_diagnostic_data.csv"
)
index_relative <- paste0(
  "artifacts/11_source_data/H10/",
  "H10_all_primary_core_diagnostic_index.csv"
)

invisible(write_csv_artifact(
  all_plot_data,
  file.path(root, all_source_relative),
  producer
))
invisible(write_csv_artifact(
  retained_age,
  file.path(root, age_source_relative),
  producer
))
invisible(write_csv_artifact(
  retained_sex,
  file.path(root, sex_source_relative),
  producer
))
invisible(write_csv_artifact(
  model_index |>
    select(
      page,
      model_key,
      all_of(model_keys),
      metric_order,
      manuscript_name,
      placement_display,
      predictor_display,
      analysis_unit,
      response_family,
      response_transform,
      adjusted_significant,
      p_adjusted,
      effect_95_ci_display,
      final_assessment,
      diagnostic_issues,
      residual_qq_correlation,
      residual_absolute_fitted_spearman,
      serial_status,
      deletion_status,
      site_influence_assessment
    ),
  file.path(root, index_relative),
  producer
))

make_core_plot <- function(data, title, subtitle) {
  panel_levels <- data |>
    distinct(
      page,
      diagnostic_order,
      panel_label
    ) |>
    arrange(.data$page, .data$diagnostic_order) |>
    pull("panel_label")
  plot_data <- data |>
    mutate(
      panel_label = factor(.data$panel_label, levels = panel_levels)
    )
  residual_reference <- plot_data |>
    filter(.data$diagnostic_type == "Residuals vs fitted") |>
    distinct(panel_label, reference_intercept)
  qq_line <- plot_data |>
    filter(.data$diagnostic_type == "Normal Q-Q") |>
    distinct(
      panel_label,
      reference_intercept,
      reference_slope
    )
  displayed_sites <- site_registry$display_name[
    site_registry$display_name %in% as.character(plot_data$site_display_name)
  ]

  ggplot(
    plot_data,
    aes(x = .data$x, y = .data$y, colour = .data$site_display_name)
  ) +
    geom_hline(
      data = residual_reference,
      aes(yintercept = .data$reference_intercept),
      inherit.aes = FALSE,
      colour = "grey35",
      linewidth = 0.35
    ) +
    geom_abline(
      data = qq_line,
      aes(
        intercept = .data$reference_intercept,
        slope = .data$reference_slope
      ),
      inherit.aes = FALSE,
      colour = "grey35",
      linewidth = 0.35
    ) +
    geom_point(size = 0.55, alpha = 0.42, stroke = 0) +
    facet_wrap(vars(.data$panel_label), ncol = 2, scales = "free") +
    scale_colour_manual(
      values = site_colours,
      breaks = displayed_sites,
      drop = TRUE
    ) +
    labs(
      title = title,
      subtitle = subtitle,
      x = NULL,
      y = "Pearson residual",
      colour = "Site"
    ) +
    guides(
      colour = guide_legend(
        nrow = 2,
        byrow = TRUE,
        override.aes = list(alpha = 1, size = 2)
      )
    ) +
    theme_minimal(base_size = 10) +
    theme(
      plot.title.position = "plot",
      plot.title = element_text(
        face = "bold",
        size = 12,
        hjust = 0,
        lineheight = 1.05
      ),
      plot.subtitle = element_text(
        size = 9,
        colour = "grey25",
        hjust = 0,
        lineheight = 1.05
      ),
      strip.text = element_text(face = "bold", size = 8.2),
      panel.grid.minor = element_blank(),
      panel.grid.major = element_line(linewidth = 0.25, colour = "grey90"),
      axis.text = element_text(size = 8),
      axis.title.y = element_text(size = 9),
      legend.position = "bottom",
      legend.text = element_text(size = 8.3),
      legend.title = element_text(size = 8.5),
      legend.margin = margin(t = 2),
      plot.margin = margin(7, 8, 5, 7)
    )
}

age_plot <- make_core_plot(
  retained_age,
  "Core diagnostics for retained age associations",
  paste(
    "Nine site-adjusted models; residual-fitted and descriptive normal Q-Q",
    "panels use independent limits. Colours follow the submitted site convention."
  )
)
sex_plot <- make_core_plot(
  retained_sex,
  "Core diagnostics for retained biological-sex associations",
  paste(
    "Two complementary chest models; residual-fitted and descriptive normal",
    "Q-Q panels use independent limits. Colours follow the submitted site convention."
  )
)

age_png_relative <- paste0(
  "artifacts/10_figures/H10/",
  "H10_retained_age_core_diagnostics.png"
)
age_pdf_relative <- paste0(
  "artifacts/10_figures/H10/",
  "H10_retained_age_core_diagnostics.pdf"
)
sex_png_relative <- paste0(
  "artifacts/10_figures/H10/",
  "H10_retained_biological_sex_core_diagnostics.png"
)
sex_pdf_relative <- paste0(
  "artifacts/10_figures/H10/",
  "H10_retained_biological_sex_core_diagnostics.pdf"
)
appendix_pdf_relative <- paste0(
  "artifacts/10_figures/H10/",
  "H10_all_primary_model_core_diagnostics.pdf"
)

ggsave(
  file.path(root, age_png_relative),
  age_plot,
  width = 9.4,
  height = 13,
  dpi = 300,
  bg = "white"
)
ggsave(
  file.path(root, age_pdf_relative),
  age_plot,
  width = 9.4,
  height = 13,
  device = grDevices::cairo_pdf,
  bg = "white"
)
ggsave(
  file.path(root, sex_png_relative),
  sex_plot,
  width = 9.4,
  height = 5.5,
  dpi = 300,
  bg = "white"
)
ggsave(
  file.path(root, sex_pdf_relative),
  sex_plot,
  width = 9.4,
  height = 5.5,
  device = grDevices::cairo_pdf,
  bg = "white"
)

grDevices::cairo_pdf(
  file.path(root, appendix_pdf_relative),
  width = 9.4,
  height = 6.6,
  onefile = TRUE,
  family = "sans"
)
for (current_key in model_index$model_key) {
  current_index <- model_index |>
    filter(.data$model_key == .env$current_key)
  current_data <- all_plot_data |>
    filter(.data$model_key == .env$current_key)
  issue_text <- ifelse(
    is.na(current_index$diagnostic_issues),
    "no residual/distribution threshold flag",
    stringr::str_replace_all(current_index$diagnostic_issues, "_", " ")
  )
  issue_display <- ifelse(
    issue_text == "RESIDUAL QQ REVIEW",
    "Q-Q review",
    issue_text
  )
  assessment_display <- stringr::str_replace(
    current_index$final_assessment,
    "acceptable with specified limitations",
    "acceptable with limitations"
  )
  page_plot <- make_core_plot(
    current_data,
    stringr::str_wrap(
      paste0(
        current_index$placement_display,
        " - ",
        current_index$predictor_display,
        " - ",
        current_index$manuscript_name
      ),
      width = 42
    ),
    stringr::str_wrap(
      paste0(
        "Assessment: ",
        assessment_display,
        "; residual screen: ",
        issue_display,
        "."
      ),
      width = 105
    )
  ) +
    theme(
      plot.title = element_text(
        face = "bold",
        size = 10.5,
        hjust = 0,
        lineheight = 1.05
      ),
      plot.subtitle = element_text(
        size = 8.5,
        colour = "grey25",
        hjust = 0,
        lineheight = 1.05,
        margin = margin(b = 5)
      ),
      strip.text = element_text(face = "bold", size = 9),
      plot.margin = margin(7, 10, 5, 12)
    )
  print(page_plot)
}
grDevices::dev.off()

expected_outputs <- file.path(
  root,
  c(
    age_png_relative,
    age_pdf_relative,
    sex_png_relative,
    sex_pdf_relative,
    appendix_pdf_relative,
    all_source_relative,
    age_source_relative,
    sex_source_relative,
    index_relative
  )
)
if (
  any(!file.exists(expected_outputs)) ||
    any(file.info(expected_outputs)$size <= 0)
) {
  stop(
    "One or more H10 core-diagnostic artifacts were not created",
    call. = FALSE
  )
}

age_alt <- paste(
  "Eighteen small panels show residual-versus-fitted and normal Q-Q plots for",
  "the nine main age-association models that met their separately labelled",
  "17-metric BH rule: three primary near-eye models and six complementary",
  "chest models. Points are coloured by submitted site. Every residual-fitted",
  "panel includes a horizontal zero line, and every Q-Q panel includes its",
  "quartile reference line. Independent panel limits expose metric-specific",
  "spread without forcing unrelated fitted scales to share an axis."
)
sex_alt <- paste(
  "Four small panels show residual-versus-fitted and normal Q-Q plots for the",
  "two complementary chest biological-sex models that met their separately",
  "labelled 17-metric BH rule: mean melEDI and darkest-10-hour mean melEDI.",
  "Points are coloured by submitted site. Residual-fitted panels include zero",
  "lines and Q-Q panels include quartile reference lines; limits are separate",
  "for each model and diagnostic type."
)

manifest_relative <- paste0(
  "artifacts/12_manifests/H10/",
  "H10_core_diagnostic_figure_manifest.csv"
)
manifest <- tibble::tribble(
  ~figure_id,
  ~figure_path,
  ~pdf_path,
  ~source_data_path,
  ~model_index_path,
  ~models,
  ~pages,
  ~width_in,
  ~height_in,
  ~dpi,
  ~intended_display_width_mm,
  ~alt_text,
  "fig-h10-core-diagnostics-age",
  age_png_relative,
  age_pdf_relative,
  age_source_relative,
  index_relative,
  9L,
  1L,
  9.4,
  13,
  300L,
  170,
  age_alt,
  "fig-h10-core-diagnostics-biological-sex",
  sex_png_relative,
  sex_pdf_relative,
  sex_source_relative,
  index_relative,
  2L,
  1L,
  9.4,
  5.5,
  300L,
  170,
  sex_alt,
  "fig-h10-all-primary-core-diagnostics",
  NA_character_,
  appendix_pdf_relative,
  all_source_relative,
  index_relative,
  68L,
  68L,
  9.4,
  6.6,
  NA_integer_,
  170,
  paste(
    "A 68-page appendix gives one residual-versus-fitted panel and one normal",
    "Q-Q panel for every primary metric-placement-association model. Each page",
    "states the final acceptability assessment and any residual or distribution",
    "threshold flag. Points use submitted site colours and all pages share the",
    "same layout while retaining model-specific axis limits."
  )
) |>
  mutate(
    figure_sha256 = vapply(
      .data$figure_path,
      function(path) {
        if (is.na(path)) {
          return(NA_character_)
        }
        artifact_sha256(file.path(root, path))
      },
      character(1)
    ),
    pdf_sha256 = vapply(
      file.path(root, .data$pdf_path),
      artifact_sha256,
      character(1)
    ),
    source_data_sha256 = vapply(
      file.path(root, .data$source_data_path),
      artifact_sha256,
      character(1)
    ),
    model_index_sha256 = vapply(
      file.path(root, .data$model_index_path),
      artifact_sha256,
      character(1)
    ),
    producer = producer,
    r_version = as.character(getRversion()),
    diagnostic_basis = paste(
      "Stored Pearson residuals, stored fitted values, and stored Q-Q points;",
      "no model fit, refit, or prediction"
    )
  )

if (
  nrow(manifest) != 3L ||
    anyDuplicated(manifest$figure_id) ||
    any(nchar(manifest$pdf_sha256) != 64L) ||
    any(nchar(manifest$source_data_sha256) != 64L) ||
    any(nchar(manifest$model_index_sha256) != 64L) ||
    any(nchar(manifest$alt_text) < 300L)
) {
  stop("Invalid H10 core-diagnostic figure manifest", call. = FALSE)
}

invisible(write_csv_artifact(
  manifest,
  file.path(root, manifest_relative),
  producer
))
message(
  "Built H10 core diagnostic displays for 11 retained models and a ",
  "68-page all-model appendix from frozen plot data"
)
