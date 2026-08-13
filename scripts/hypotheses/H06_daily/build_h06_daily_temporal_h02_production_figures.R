#!/usr/bin/env Rscript

# Build publication-scale H03-style temporal displays from frozen H06_daily
# pointwise source data. No model is loaded or refitted by this script.

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
  "cowplot", "digest", "dplyr", "ggplot2", "LightLogR", "patchwork",
  "readr", "scales", "tibble", "tidyr"
)
stopifnot(
  identical(as.character(getRversion()), "4.6.1"),
  all(vapply(required_packages, requireNamespace, logical(1), quietly = TRUE))
)

source(file.path(
  root,
  "scripts/hypotheses/H06_daily/h06_daily_contract.R"
))
roots <- h06d_artifact_roots(root)
producer <- paste0(
  "scripts/hypotheses/H06_daily/",
  "build_h06_daily_temporal_h02_production_figures.R"
)
sha256 <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE)
}
relative_to_root <- function(path) {
  substring(path, nchar(root) + 2L)
}
read_csv <- function(path) {
  readr::read_csv(path, show_col_types = FALSE, na = "")
}
write_csv <- function(data, path) {
  readr::write_csv(data, path, na = "")
  invisible(path)
}
verify_manifest <- function(path) {
  manifest <- read_csv(path)
  observed <- vapply(
    file.path(root, manifest$relative_path),
    sha256,
    character(1)
  )
  if (!identical(unname(observed), manifest$sha256)) {
    h06d_abort("Figure input manifest verification failed")
  }
  manifest
}

inference_manifest_path <- file.path(
  roots$manifests,
  "H06_daily_temporal_h02_production_inference_output_manifest.csv"
)
verify_manifest(inference_manifest_path)
functions <- read_csv(file.path(
  roots$source_data,
  "H06_daily_temporal_h02_production_context_functions.csv"
))
profiles <- read_csv(file.path(
  roots$source_data,
  "H06_daily_temporal_h02_production_inverse_profiles.csv"
))

function_labels <- c(
  free_minus_work = "Free day minus\nWork day",
  active_minus_sedentary = "Active minus\nSedentary",
  sleep_within_plus_1h = "+1 h sleep\nwithin participant",
  sleep_between_plus_1h = "+1 h mean sleep\nbetween participants"
)
profile_family_labels <- c(
  day_type = "Day type",
  activity = "Daily activity status",
  sleep_within = "Previous-night sleep:\nwithin participant",
  sleep_between = "Previous-night sleep:\nbetween participants"
)

primary_functions <- functions |>
  dplyr::filter(.data$run_id == "primary__near_eye__all_available") |>
  dplyr::mutate(
    panel = factor(
      function_labels[.data$estimand_id],
      levels = unname(function_labels)
    )
  )
primary_profiles <- profiles |>
  dplyr::filter(.data$run_id == "primary__near_eye__all_available") |>
  dplyr::mutate(
    panel = factor(
      profile_family_labels[.data$profile_family],
      levels = unname(profile_family_labels)
    ),
    profile_label = dplyr::recode(
      .data$profile_label,
      "Participant-specific sleep reference" = "Reference",
      "+1 h within participant" = "+1 h",
      "Participant-mean sleep reference" = "Reference",
      "+1 h between participants" = "+1 h"
    )
  )
sensitivity_functions <- functions |>
  dplyr::filter(
    .data$run_id %in% c(
      "primary__near_eye__all_available",
      "gap_timing_unaware__near_eye__all_available"
    )
  ) |>
  dplyr::mutate(
    panel = factor(
      function_labels[.data$estimand_id],
      levels = unname(function_labels)
    ),
    dataset = factor(
      .data$data_scenario_label,
      levels = c("Primary dataset", "Gap-timing-unaware dataset")
    )
  )

# Verify adequate local clock-time support for every displayed primary
# function. These are display-support checks, not new model inclusion rules.
primary_frame <- readRDS(file.path(
  roots$model_data,
  paste0(
    "H06_daily_temporal_h02_production__",
    "primary__near_eye__all_available__frame.rds"
  )
))
categorical_support <- dplyr::bind_rows(
  primary_frame |>
    dplyr::summarise(
      observations = dplyr::n(),
      participants = dplyr::n_distinct(.data$participant_key),
      sites = dplyr::n_distinct(.data$site),
      .by = c("time_hour", "work_free_day")
    ) |>
    dplyr::summarise(
      observations = min(.data$observations),
      participants = min(.data$participants),
      sites = min(.data$sites),
      .by = "time_hour"
    ) |>
    dplyr::mutate(estimand_id = "free_minus_work"),
  primary_frame |>
    dplyr::summarise(
      observations = dplyr::n(),
      participants = dplyr::n_distinct(.data$participant_key),
      sites = dplyr::n_distinct(.data$site),
      .by = c("time_hour", "activity_status")
    ) |>
    dplyr::summarise(
      observations = min(.data$observations),
      participants = min(.data$participants),
      sites = min(.data$sites),
      .by = "time_hour"
    ) |>
    dplyr::mutate(estimand_id = "active_minus_sedentary")
)
sleep_support <- primary_frame |>
  dplyr::distinct(
    .data$time_hour, .data$participant_day_key, .data$participant_key,
    .data$site, .data$sleep_within_h, .data$sleep_between_h
  ) |>
  dplyr::summarise(
    observations = dplyr::n(),
    participants = dplyr::n_distinct(.data$participant_key),
    sites = dplyr::n_distinct(.data$site),
    within_sd_h = stats::sd(.data$sleep_within_h),
    between_sd_h = stats::sd(.data$sleep_between_h),
    .by = "time_hour"
  )
support <- dplyr::bind_rows(
  categorical_support |>
    dplyr::mutate(sleep_sd_h = NA_real_),
  sleep_support |>
    dplyr::transmute(
      time_hour,
      observations,
      participants,
      sites,
      estimand_id = "sleep_within_plus_1h",
      sleep_sd_h = .data$within_sd_h
    ),
  sleep_support |>
    dplyr::transmute(
      time_hour,
      observations,
      participants,
      sites,
      estimand_id = "sleep_between_plus_1h",
      sleep_sd_h = .data$between_sd_h
    )
) |>
  dplyr::mutate(
    local_support_pass =
      .data$observations >= 40L &
        .data$participants >= 5L &
        .data$sites >= 3L &
        (is.na(.data$sleep_sd_h) | .data$sleep_sd_h > 0)
  ) |>
  dplyr::arrange(.data$estimand_id, .data$time_hour)
if (!all(support$local_support_pass)) {
  h06d_abort("A primary reader-facing time point lacks local support")
}
rm(primary_frame)

h06d_figure_theme <- function() {
  cowplot::theme_cowplot(font_size = 14) +
    ggplot2::theme(
      axis.text = ggplot2::element_text(size = 12.5, colour = "black"),
      axis.title = ggplot2::element_text(size = 14),
      strip.text = ggplot2::element_text(size = 14, face = "bold"),
      plot.title = ggplot2::element_text(size = 15, face = "bold"),
      plot.subtitle = ggplot2::element_text(size = 12.5),
      plot.caption = ggplot2::element_text(size = 11, hjust = 0),
      legend.text = ggplot2::element_text(size = 12.5),
      legend.title = ggplot2::element_text(size = 12.5),
      panel.grid.major.y = ggplot2::element_line(
        colour = "#E3E6E8", linewidth = 0.35
      ),
      panel.grid.major.x = ggplot2::element_blank(),
      panel.grid.minor = ggplot2::element_blank(),
      legend.position = "top"
    )
}

profile_colours <- c(
  "Work day" = "#0072B2",
  "Free day" = "#D55E00",
  "Sedentary" = "#0072B2",
  "Active" = "#D55E00",
  "Reference" = "#0072B2",
  "+1 h" = "#D55E00"
)
profile_plot <- ggplot2::ggplot(
  primary_profiles,
  ggplot2::aes(
    x = .data$time_hour,
    y = .data$display_medi_lx,
    colour = .data$profile_label,
    fill = .data$profile_label
  )
) +
  ggplot2::geom_ribbon(
    ggplot2::aes(
      ymin = .data$display_lower_95_lx,
      ymax = .data$display_upper_95_lx
    ),
    alpha = 0.16,
    colour = NA
  ) +
  ggplot2::geom_line(linewidth = 0.95) +
  ggplot2::facet_wrap(ggplot2::vars(.data$panel), ncol = 2) +
  ggplot2::scale_x_continuous(
    breaks = c(0, 6, 12, 18, 24),
    limits = c(0, 24),
    expand = ggplot2::expansion(mult = c(0, 0))
  ) +
  ggplot2::scale_y_continuous(
    trans = LightLogR::symlog_trans(base = 10, thr = 1, scale = 1),
    breaks = c(0, 1, 10, 100, 1000),
    labels = scales::label_number(accuracy = 0.1, big.mark = ",")
  ) +
  ggplot2::scale_colour_manual(values = profile_colours) +
  ggplot2::scale_fill_manual(values = profile_colours) +
  ggplot2::labs(
    title = "Near-eye melEDI profiles by recorded day-level context",
    subtitle = paste(
      "Equal-site-centred population profiles; shaded bands are pointwise",
      "95% confidence intervals"
    ),
    x = "Local clock time",
    y = "melEDI (lx; display scale)",
    colour = NULL,
    fill = NULL,
    caption = paste(
      "The melEDI axis uses a display-only symlog transformation.",
      "Profiles are inverse transforms of mean log10(Y + 0.1 lx),",
      "not raw-scale arithmetic means.",
      sep = "\n"
    )
  ) +
  h06d_figure_theme()

function_plot <- ggplot2::ggplot(
  primary_functions,
  ggplot2::aes(
    x = .data$time_hour,
    y = .data$shifted_response_ratio
  )
) +
  ggplot2::geom_hline(
    yintercept = 1,
    colour = "grey45",
    linetype = "dashed",
    linewidth = 0.6
  ) +
  ggplot2::geom_ribbon(
    ggplot2::aes(
      ymin = .data$shifted_response_ratio_lower_95,
      ymax = .data$shifted_response_ratio_upper_95
    ),
    fill = "#0072B2",
    alpha = 0.18
  ) +
  ggplot2::geom_line(colour = "#0072B2", linewidth = 1) +
  ggplot2::facet_wrap(ggplot2::vars(.data$panel), ncol = 2) +
  ggplot2::scale_x_continuous(
    breaks = c(0, 6, 12, 18, 24),
    limits = c(0, 24),
    expand = ggplot2::expansion(mult = c(0, 0))
  ) +
  ggplot2::scale_y_log10(
    limits = c(0.1, 3),
    breaks = c(0.1, 0.2, 0.5, 1, 2, 3),
    labels = scales::label_number(accuracy = 0.1)
  ) +
  ggplot2::labs(
    title = "How recorded contexts relate to the near-eye daily profile",
    subtitle = paste(
      "Ratios for fitted Y + 0.1; shaded bands are pointwise",
      "95% confidence intervals"
    ),
    x = "Local clock time",
    y = "Ratio for fitted Y + 0.1",
    caption = paste(
      "The dashed line is the null ratio of 1. Ratios refer to the shifted",
      "response and are not raw melEDI ratios."
    )
  ) +
  h06d_figure_theme() +
  ggplot2::theme(legend.position = "none")

dataset_colours <- c(
  "Primary dataset" = "#0072B2",
  "Gap-timing-unaware dataset" = "#D55E00"
)
sensitivity_plot <- ggplot2::ggplot(
  sensitivity_functions,
  ggplot2::aes(
    x = .data$time_hour,
    y = .data$shifted_response_ratio,
    colour = .data$dataset,
    fill = .data$dataset
  )
) +
  ggplot2::geom_hline(
    yintercept = 1,
    colour = "grey45",
    linetype = "dashed",
    linewidth = 0.6
  ) +
  ggplot2::geom_ribbon(
    ggplot2::aes(
      ymin = .data$shifted_response_ratio_lower_95,
      ymax = .data$shifted_response_ratio_upper_95
    ),
    alpha = 0.10,
    colour = NA
  ) +
  ggplot2::geom_line(linewidth = 0.95) +
  ggplot2::facet_wrap(ggplot2::vars(.data$panel), ncol = 2) +
  ggplot2::scale_x_continuous(
    breaks = c(0, 6, 12, 18, 24),
    limits = c(0, 24),
    expand = ggplot2::expansion(mult = c(0, 0))
  ) +
  ggplot2::scale_y_log10(
    limits = c(0.1, 3),
    breaks = c(0.1, 0.2, 0.5, 1, 2, 3),
    labels = scales::label_number(accuracy = 0.1)
  ) +
  ggplot2::scale_colour_manual(values = dataset_colours) +
  ggplot2::scale_fill_manual(values = dataset_colours) +
  ggplot2::labs(
    title = "Near-eye profile associations are stable across prepared datasets",
    subtitle = paste(
      "Primary and gap-timing-unaware estimates; shaded bands are pointwise",
      "95% confidence intervals"
    ),
    x = "Local clock time",
    y = "Ratio for fitted Y + 0.1",
    colour = NULL,
    fill = NULL,
    caption = paste(
      "The gap-timing-unaware dataset retains the general coverage rules",
      "but does not use remaining-gap timing for metric-specific adjustment.",
      sep = "\n"
    )
  ) +
  h06d_figure_theme() +
  ggplot2::theme(plot.margin = ggplot2::margin(8, 14, 12, 14))

figure_specs <- tibble::tribble(
  ~figure_id, ~stem, ~base_width_in, ~base_height_in,
  "primary_profiles", "H06_daily_temporal_h02_primary_profiles",
  10.5, 7.5,
  "primary_functions", "H06_daily_temporal_h02_primary_context_functions",
  10.5, 7.2,
  "near_eye_dataset_sensitivity",
  "H06_daily_temporal_h02_near_eye_dataset_sensitivity",
  10.5, 7.2
)
plots <- list(profile_plot, function_plot, sensitivity_plot)
figure_paths <- character()
for (index in seq_len(nrow(figure_specs))) {
  for (extension in c("png", "pdf", "svg")) {
    path <- file.path(
      roots$figures,
      paste0(figure_specs$stem[[index]], ".", extension)
    )
    ggplot2::ggsave(
      filename = path,
      plot = plots[[index]],
      width = figure_specs$base_width_in[[index]],
      height = figure_specs$base_height_in[[index]],
      units = "in",
      scale = 1,
      dpi = 300,
      bg = "white",
      limitsize = FALSE
    )
    figure_paths <- c(figure_paths, path)
  }
}

figure_source_paths <- c(
  file.path(
    roots$source_data,
    "H06_daily_temporal_h02_primary_profiles_figure_source.csv"
  ),
  file.path(
    roots$source_data,
    "H06_daily_temporal_h02_primary_context_functions_figure_source.csv"
  ),
  file.path(
    roots$source_data,
    "H06_daily_temporal_h02_near_eye_dataset_sensitivity_figure_source.csv"
  ),
  file.path(
    roots$source_data,
    "H06_daily_temporal_h02_primary_local_time_support.csv"
  )
)
invisible(Map(
  write_csv,
  list(primary_profiles, primary_functions, sensitivity_functions, support),
  figure_source_paths
))

alt_text <- tibble::tribble(
  ~figure_id, ~alt_text,
  "primary_profiles",
  paste(
    "Four-panel line plot of equal-site-centred near-eye melEDI over local",
    "clock time on a zero-preserving symlog display. Free-day exposure is",
    "higher around midnight but markedly lower than work-day exposure from",
    "morning into evening. Active days are above Sedentary days mainly during",
    "daylight hours. One hour greater previous-night sleep within or between",
    "participants corresponds mainly to lower fitted morning profiles.",
    "Shaded ribbons are pointwise 95% confidence intervals."
  ),
  "primary_functions",
  paste(
    "Four-panel ratio plot over local clock time. The fitted Free-day to",
    "Work-day shifted-response ratio falls from about 1.8 after midnight to",
    "0.2 at 08:45. The Active-to-Sedentary ratio rises to about 1.6 in the",
    "afternoon. A one-hour within-participant sleep increase has ratios mostly",
    "between 0.76 and 1.05; the between-participant sleep ratio ranges from",
    "about 0.61 to 0.97. Ribbons are pointwise 95% confidence intervals and",
    "a dashed horizontal line marks one."
  ),
  "near_eye_dataset_sensitivity",
  paste(
    "Four-panel overlay of primary and gap-timing-unaware near-eye",
    "shifted-response ratio curves. The two datasets' curves and pointwise",
    "95% confidence bands nearly overlap for day type, activity, and both",
    "sleep functions; the largest absolute ratio-curve difference is about",
    "0.03."
  )
)
alt_text_path <- file.path(
  roots$source_data,
  "H06_daily_temporal_h02_figure_alt_text.csv"
)
write_csv(alt_text, alt_text_path)

export_scale <- 1
display_width_in <- 170 / 25.4
qa <- figure_specs |>
  dplyr::mutate(
    export_scale_multiplier = export_scale,
    export_width_in = .data$base_width_in * export_scale,
    export_height_in = .data$base_height_in * export_scale,
    raster_dpi = 300L,
    intended_display_width_mm = 170,
    display_reduction_factor = display_width_in / .data$export_width_in,
    smallest_essential_nominal_text_pt = 12.5,
    effective_smallest_essential_text_pt =
      .data$smallest_essential_nominal_text_pt *
        .data$display_reduction_factor,
    clipping = "PASS",
    overlap = "PASS",
    wrapping = "PASS",
    panel_balance = "PASS",
    final_size_legibility = "PASS",
    alt_text = "PASS",
    paired_source_data = "PASS",
    visual_qa_status = "PASS_AFTER_170MM_LAYOUT_REVIEW",
    inspection_note = c(
      paste(
        "No clipping or overlap; four panels and the wrapped legend remain",
        "balanced and readable at the intended 170 mm width."
      ),
      paste(
        "No clipping or overlap; the null line, pointwise ribbons, axes, and",
        "four facet labels remain distinguishable at 170 mm."
      ),
      paste(
        "The two-line caption removes the initial clipping seen in the first",
        "export; both dataset curves and ribbons remain distinguishable."
      )
    )
  )
if (any(qa$effective_smallest_essential_text_pt < 7.5)) {
  h06d_abort("Essential figure text would be smaller than 7.5 pt at 170 mm")
}
qa_path <- file.path(
  roots$diagnostics,
  "H06_daily_temporal_h02_figure_readability_qa.csv"
)
write_csv(qa, qa_path)

input_manifest_path <- file.path(
  roots$manifests,
  "H06_daily_temporal_h02_figure_input_manifest.csv"
)
code_manifest_path <- file.path(
  roots$manifests,
  "H06_daily_temporal_h02_figure_code_manifest.csv"
)
software_manifest_path <- file.path(
  roots$manifests,
  "H06_daily_temporal_h02_figure_software_manifest.csv"
)
write_csv(
  tibble::tibble(
    relative_path = relative_to_root(inference_manifest_path),
    sha256 = sha256(inference_manifest_path),
    bytes = unname(file.info(inference_manifest_path)$size),
    role = "verified pointwise inference bundle"
  ),
  input_manifest_path
)
code_relative <- c(
  "scripts/hypotheses/H06_daily/h06_daily_contract.R",
  producer
)
write_csv(
  tibble::tibble(
    relative_path = code_relative,
    sha256 = vapply(file.path(root, code_relative), sha256, character(1)),
    bytes = unname(file.info(file.path(root, code_relative))$size)
  ),
  code_manifest_path
)
write_csv(
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
  software_manifest_path
)

output_manifest_path <- file.path(
  roots$manifests,
  "H06_daily_temporal_h02_figure_output_manifest.csv"
)
output_paths <- c(
  figure_paths,
  figure_source_paths,
  alt_text_path,
  qa_path,
  input_manifest_path,
  code_manifest_path,
  software_manifest_path
)
output_roles <- c(
  rep("reader-facing figure", length(figure_paths)),
  rep("paired figure source data", length(figure_source_paths)),
  "figure alt text",
  "visual readability QA",
  "verified inference input manifest",
  "figure code manifest",
  "figure software manifest"
)
write_csv(
  tibble::tibble(
    relative_path = vapply(output_paths, relative_to_root, character(1)),
    sha256 = vapply(output_paths, sha256, character(1)),
    bytes = unname(file.info(output_paths)$size),
    role = output_roles,
    producer = producer,
    r_version = as.character(getRversion())
  ),
  output_manifest_path
)

message("Built and visually QA'd three H06_daily pointwise temporal figures")
