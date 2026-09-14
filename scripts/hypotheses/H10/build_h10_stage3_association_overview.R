#!/usr/bin/env Rscript

# Build the reader-facing H10 association overview from the sealed numerical
# package. The figure combines participant-level age distributions, retained
# main associations, and retained site heterogeneity. It never fits, refits,
# predicts from, or simulates a model.

suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
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

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop(
    sprintf(
      "H10 reader-figure build requires R 4.6.1; running %s",
      getRversion()
    ),
    call. = FALSE
  )
}

producer <- paste0(
  "scripts/hypotheses/H10/",
  "build_h10_stage3_association_overview.R"
)
stage2_manifest_path <- file.path(
  root,
  "artifacts/12_manifests/H10/H10_stage2_artifacts.csv"
)
stage2_manifest <- readr::read_csv(
  stage2_manifest_path,
  show_col_types = FALSE
)

verified_path <- function(relative_path) {
  manifest_row <- stage2_manifest |>
    filter(.data$path == .env$relative_path)
  if (nrow(manifest_row) != 1L) {
    stop(
      paste0("Frozen H10 inventory does not uniquely identify ", relative_path),
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

read_verified_csv <- function(relative_path) {
  readr::read_csv(
    verified_path(relative_path),
    show_col_types = FALSE,
    progress = FALSE
  )
}

prepared <- readRDS(verified_path(
  "artifacts/06_model_data/H10/H10_approved_prepared_rows.rds"
))
main_results <- read_verified_csv(
  "artifacts/09_tables/H10/H10_primary_main_results.csv"
)
interactions <- read_verified_csv(
  "artifacts/09_tables/H10/H10_primary_interaction_results.csv"
)
site_effects <- read_verified_csv(
  "artifacts/09_tables/H10/H10_site_specific_effects.csv"
)
site_registry_path <- file.path(root, "config/site_display_registry.csv")
site_registry <- readr::read_csv(
  site_registry_path,
  show_col_types = FALSE
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
site_labels <- stats::setNames(site_registry$display_name, site_registry$site)

age_participants_private <- prepared$all_available_rows |>
  filter(.data$data_scenario == "primary") |>
  distinct(
    .data$placement,
    .data$site,
    .data$Id,
    .data$age,
    .data$biological_sex
  ) |>
  left_join(
    site_registry,
    by = "site",
    relationship = "many-to-one"
  ) |>
  arrange(.data$placement, .data$display_order, .data$age, .data$Id) |>
  group_by(.data$placement, .data$site) |>
  mutate(participant_display_index = dplyr::row_number()) |>
  ungroup() |>
  mutate(
    placement_label = factor(
      unname(placement_names[.data$placement]),
      levels = unname(placement_names[c("glasses", "chest")])
    ),
    site_display_name = factor(
      .data$display_name,
      levels = rev(site_registry$display_name)
    )
  )

age_counts <- age_participants_private |>
  count(.data$placement, name = "participants") |>
  arrange(match(.data$placement, c("glasses", "chest")))
stopifnot(
  identical(age_counts$placement, c("glasses", "chest")),
  identical(age_counts$participants, c(141L, 154L)),
  all(age_participants_private$age >= 18),
  all(age_participants_private$age <= 68),
  !anyNA(age_participants_private$display_order),
  !anyNA(age_participants_private$color_hex)
)

main_retained <- main_results |>
  filter(.data$adjusted_significant) |>
  mutate(
    placement_label = unname(placement_names[.data$placement]),
    association_label = if_else(
      .data$predictor == "age",
      "Age, per 10 years",
      "Female minus Male"
    ),
    association_panel = case_when(
      .data$placement == "glasses" & .data$predictor == "age" ~ "Near-eye age",
      .data$placement == "chest" & .data$predictor == "age" ~ "Chest age",
      TRUE ~ "Chest Female–Male"
    ),
    association_panel = factor(
      .data$association_panel,
      levels = c(
        "Near-eye age",
        "Chest age",
        "Chest Female–Male"
      )
    ),
    metric_display = factor(
      .data$manuscript_name,
      levels = rev(unique(
        .data$manuscript_name[
          order(.data$predictor, .data$placement, .data$metric_order)
        ]
      ))
    )
  )
stopifnot(
  nrow(main_retained) == 11L,
  sum(main_retained$placement == "glasses") == 3L,
  sum(
    main_retained$placement == "chest" &
      main_retained$predictor == "age"
  ) ==
    6L,
  sum(main_retained$predictor == "biological_sex") == 2L
)

supported_interaction_metrics <- interactions |>
  filter(.data$adjusted_significant) |>
  select(
    "placement",
    "metric_id",
    "predictor",
    interaction_p_raw = "p_raw",
    interaction_p_adjusted = "p_adjusted",
    interaction_p_raw_display = "p_raw_display",
    interaction_p_adjusted_display = "p_adjusted_display"
  )
stopifnot(
  nrow(supported_interaction_metrics) == 2L,
  all(supported_interaction_metrics$placement == "chest"),
  all(supported_interaction_metrics$predictor == "age")
)

heterogeneity_retained <- site_effects |>
  inner_join(
    supported_interaction_metrics,
    by = c("placement", "metric_id", "predictor"),
    relationship = "many-to-one"
  ) |>
  filter(
    .data$data_scenario == "primary",
    .data$weighting == "site_specific"
  ) |>
  left_join(
    site_registry |>
      select("site", "display_order", "display_name", "color_hex"),
    by = "site",
    relationship = "many-to-one",
    suffix = c("", "_registry")
  ) |>
  mutate(
    site_display_name = factor(
      .data$display_name,
      levels = rev(site_registry$display_name)
    ),
    metric_display = factor(
      .data$manuscript_name,
      levels = c(
        "Midpoint of the brightest 10 hours",
        "Last light timing above 250 lx melEDI"
      )
    )
  )
stopifnot(
  nrow(heterogeneity_retained) == 16L,
  !anyNA(heterogeneity_retained$display_order),
  !anyNA(heterogeneity_retained$color_hex)
)

theme_h10_overview <- function(base_size = 10) {
  theme_minimal(base_size = base_size) +
    theme(
      plot.title.position = "plot",
      plot.title = element_text(face = "bold", size = rel(1.15)),
      plot.subtitle = element_text(size = rel(0.96), color = "grey25"),
      plot.caption = element_text(
        size = rel(0.72),
        hjust = 0,
        color = "grey25"
      ),
      panel.grid.minor = element_blank(),
      panel.grid.major.y = element_blank(),
      strip.text = element_text(face = "bold", size = rel(0.9)),
      axis.title = element_text(size = rel(0.92)),
      axis.text = element_text(size = rel(0.82)),
      legend.position = "bottom",
      legend.title = element_text(size = rel(0.85)),
      legend.text = element_text(size = rel(0.82)),
      plot.margin = margin(5.5, 8, 5.5, 8)
    )
}

p_age <- ggplot(
  age_participants_private,
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
    size = 1.25,
    stroke = 0,
    show.legend = c(color = FALSE, shape = TRUE)
  ) +
  facet_wrap(~placement_label, ncol = 2) +
  scale_color_manual(
    values = site_colors,
    breaks = site_registry$site,
    labels = site_labels,
    drop = FALSE
  ) +
  scale_shape_manual(
    values = c(Female = 16, Male = 17),
    name = "Measured biological sex"
  ) +
  scale_x_continuous(
    breaks = seq(20, 70, 10),
    limits = c(17, 70),
    expand = expansion(mult = c(0.01, 0.01))
  ) +
  labs(
    title = "Participant age distribution in each fitted placement sample",
    subtitle = paste0(
      "One point per participant; sites follow submitted-manuscript order and colours (",
      "near eye n = 141; chest n = 154)"
    ),
    x = "Age (years)",
    y = NULL
  ) +
  theme_h10_overview(10)

p_main <- ggplot(
  main_retained,
  aes(
    x = .data$standardized_estimate,
    y = .data$metric_display,
    xmin = .data$standardized_conf_low,
    xmax = .data$standardized_conf_high,
    color = .data$placement,
    shape = .data$predictor
  )
) +
  geom_vline(xintercept = 0, color = "grey50", linewidth = 0.45) +
  geom_errorbar(orientation = "y", width = 0, linewidth = 0.7) +
  geom_point(size = 2.35, stroke = 0.25) +
  facet_wrap(
    ~association_panel,
    ncol = 3,
    scales = "free"
  ) +
  scale_color_manual(
    values = placement_colors,
    breaks = c("glasses", "chest"),
    labels = placement_names,
    name = "Placement"
  ) +
  scale_shape_manual(
    values = c(age = 16, biological_sex = 17),
    breaks = c("age", "biological_sex"),
    labels = c("Age, per 10 years", "Female minus Male"),
    name = "Association"
  ) +
  scale_y_discrete(
    labels = function(x) stringr::str_wrap(x, width = 24)
  ) +
  scale_x_continuous(
    breaks = function(x) {
      candidates <- pretty(x, n = 3)
      sort(unique(c(
        0,
        candidates[candidates >= x[[1]] & candidates <= x[[2]]]
      )))
    },
    expand = expansion(mult = c(0.08, 0.08))
  ) +
  labs(
    title = "All main associations retained after multiplicity correction",
    subtitle = paste0(
      "Points and bars are standardized fitted-frame effects and 95% confidence intervals; ",
      "all 11 shown estimates meet their separate 17-metric BH rule"
    ),
    x = "Effect on model scale, divided by the fitted-frame response SD",
    y = NULL
  ) +
  theme_h10_overview(10) +
  theme(
    legend.position = "none",
    panel.spacing.x = unit(12, "pt")
  )

p_heterogeneity <- ggplot(
  heterogeneity_retained,
  aes(
    x = .data$estimate_practical,
    y = .data$site_display_name,
    xmin = .data$conf_low_practical,
    xmax = .data$conf_high_practical,
    color = .data$site
  )
) +
  geom_vline(xintercept = 0, color = "grey50", linewidth = 0.45) +
  geom_errorbar(orientation = "y", width = 0, linewidth = 0.7) +
  geom_point(size = 2.2) +
  facet_wrap(~metric_display, ncol = 2) +
  scale_color_manual(
    values = site_colors,
    breaks = site_registry$site,
    labels = site_labels,
    drop = FALSE
  ) +
  labs(
    title = "Site-specific age estimates for the two retained heterogeneity results",
    subtitle = paste0(
      "Chest placement; site-specific estimates are descriptive components of the ",
      "two omnibus age-by-site comparisons, not separate site-level tests"
    ),
    x = "Clock-time difference per decade (minutes; 95% CI)",
    y = NULL
  ) +
  theme_h10_overview(10) +
  theme(legend.position = "none")

overview <- p_age /
  p_main /
  p_heterogeneity +
  plot_layout(heights = c(1.0, 1.2, 1.15)) +
  plot_annotation(
    title = "H10 age structure and statistically supported associations",
    subtitle = paste0(
      "Near-eye evidence is primary and chest evidence complementary; ",
      "placements are not pooled"
    ),
    caption = paste0(
      "Main-effect standardization is for display only; practical estimates, exact samples, raw p-values, and BH-adjusted p-values are reported in the accompanying tables and paired source CSV."
    ),
    tag_levels = "A",
    theme = theme(
      plot.title = element_text(face = "bold", size = 15),
      plot.subtitle = element_text(size = 11, color = "grey25"),
      plot.caption = element_text(size = 7, hjust = 0, color = "grey25"),
      plot.tag = element_text(face = "bold", size = 12)
    )
  )

figure_dir <- file.path(root, "artifacts/10_figures/H10")
source_dir <- file.path(root, "artifacts/11_source_data/H10")
manifest_dir <- file.path(root, "artifacts/12_manifests/H10")
dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(source_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(manifest_dir, recursive = TRUE, showWarnings = FALSE)

figure_stem <- "H10_age_site_significant_associations"
png_path <- file.path(figure_dir, paste0(figure_stem, ".png"))
pdf_path <- file.path(figure_dir, paste0(figure_stem, ".pdf"))
source_path <- file.path(source_dir, paste0(figure_stem, "_data.csv"))
manifest_path <- file.path(
  manifest_dir,
  "H10_stage3_reader_figure_manifest.csv"
)

grDevices::cairo_pdf(
  pdf_path,
  width = 9.4,
  height = 13,
  onefile = FALSE,
  family = "sans"
)
print(overview)
grDevices::dev.off()

ragg::agg_png(
  png_path,
  width = 9.4,
  height = 13,
  units = "in",
  res = 300,
  background = "white"
)
print(overview)
grDevices::dev.off()

age_source <- age_participants_private |>
  transmute(
    panel = "age_distribution",
    placement = .data$placement,
    placement_label = .data$placement_label,
    site = .data$site,
    site_display_order = .data$display_order,
    site_display_name = as.character(.data$site_display_name),
    site_color_hex = .data$color_hex,
    participant_display_index = .data$participant_display_index,
    age = .data$age,
    biological_sex = .data$biological_sex
  )

main_source <- main_retained |>
  transmute(
    panel = "retained_main_association",
    placement = .data$placement,
    placement_label = .data$placement_label,
    predictor = .data$predictor,
    association_label = .data$association_label,
    metric_order = .data$metric_order,
    metric_id = .data$metric_id,
    manuscript_name = .data$manuscript_name,
    standardized_estimate = .data$standardized_estimate,
    standardized_conf_low = .data$standardized_conf_low,
    standardized_conf_high = .data$standardized_conf_high,
    estimate_practical = .data$estimate_practical,
    conf_low_practical = .data$conf_low_practical,
    conf_high_practical = .data$conf_high_practical,
    effect_95_ci_display = .data$effect_95_ci_display,
    p_raw = .data$p_raw,
    p_adjusted = .data$p_adjusted,
    p_raw_display = .data$p_raw_display,
    p_adjusted_display = .data$p_adjusted_display,
    observations = .data$observations,
    participants = .data$participants,
    participant_days = .data$participant_days,
    contributing_participant_days = .data$contributing_participant_days,
    metric_support_valid_hours = .data$metric_support_valid_hours,
    sites = .data$sites
  )

heterogeneity_source <- heterogeneity_retained |>
  transmute(
    panel = "retained_site_heterogeneity",
    placement = .data$placement,
    placement_label = unname(placement_names[.data$placement]),
    site = .data$site,
    site_display_order = .data$display_order,
    site_display_name = as.character(.data$site_display_name),
    site_color_hex = .data$color_hex,
    predictor = .data$predictor,
    association_label = "Age, per 10 years",
    metric_order = .data$metric_order,
    metric_id = .data$metric_id,
    manuscript_name = .data$manuscript_name,
    estimate_practical = .data$estimate_practical,
    conf_low_practical = .data$conf_low_practical,
    conf_high_practical = .data$conf_high_practical,
    participants = .data$participants,
    interaction_p_raw = .data$interaction_p_raw,
    interaction_p_adjusted = .data$interaction_p_adjusted,
    interaction_p_raw_display = .data$interaction_p_raw_display,
    interaction_p_adjusted_display = .data$interaction_p_adjusted_display
  )

source_data <- bind_rows(age_source, main_source, heterogeneity_source)
stopifnot(
  nrow(source_data) == 322L,
  sum(source_data$panel == "age_distribution") == 295L,
  sum(source_data$panel == "retained_main_association") == 11L,
  sum(source_data$panel == "retained_site_heterogeneity") == 16L,
  !"Id" %in% names(source_data),
  !"participant_key" %in% names(source_data)
)
invisible(write_csv_artifact(source_data, source_path, producer))

alt_text <- paste(
  "Composite H10 figure with three sections. The first shows near-eye and",
  "chest participant age distributions as site-coloured horizontal boxplots",
  "with one point per participant and sites in submitted-manuscript order.",
  "The second shows all 11 BH-retained main associations as standardized",
  "model-scale points with 95% confidence intervals in separate near-eye age,",
  "chest age, and chest Female-minus-Male panels. The third shows site-specific",
  "age estimates with 95% confidence intervals for the two retained chest",
  "age-by-site comparisons, using the same submitted site colours and order."
)

manifest <- tibble(
  figure_path = substring(png_path, nchar(root) + 2L),
  pdf_path = substring(pdf_path, nchar(root) + 2L),
  source_data_path = substring(source_path, nchar(root) + 2L),
  width_in = 9.4,
  height_in = 13,
  dpi = 300,
  pixel_width = 2820L,
  pixel_height = 3900L,
  display_width_mm = 170,
  smallest_essential_nominal_text_pt = 8,
  alt_text = alt_text,
  figure_sha256 = artifact_sha256(png_path),
  pdf_sha256 = artifact_sha256(pdf_path),
  source_data_sha256 = artifact_sha256(source_path),
  site_registry_sha256 = artifact_sha256(site_registry_path),
  stage2_manifest_sha256 = artifact_sha256(stage2_manifest_path),
  producer = producer,
  r_version = as.character(getRversion())
)
stopifnot(
  file.info(png_path)$size > 0,
  file.info(pdf_path)$size > 0,
  nchar(manifest$alt_text) >= 300L,
  all(
    nchar(c(
      manifest$figure_sha256,
      manifest$pdf_sha256,
      manifest$source_data_sha256,
      manifest$site_registry_sha256,
      manifest$stage2_manifest_sha256
    )) ==
      64L
  )
)
invisible(write_csv_artifact(manifest, manifest_path, producer))

message(
  "Built H10 age/site association overview: 295 participant displays, ",
  "11 retained main associations, and 16 site-specific heterogeneity estimates"
)
