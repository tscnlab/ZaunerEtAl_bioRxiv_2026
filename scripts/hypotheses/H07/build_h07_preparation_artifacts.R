#!/usr/bin/env Rscript

# Build bounded descriptive and display artifacts for the H07 analysis-
# preparation companion from frozen H07 frames and tabulated results. This
# script does not fit, refit, predict from, resample, or simulate a model.

suppressPackageStartupMessages({
  library(digest)
  library(dplyr)
  library(ggplot2)
  library(readr)
  library(stringr)
  library(tibble)
  library(tidyr)
})

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
source(file.path(root, "scripts/pipeline/paths_io.R"))

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("H07 preparation artifacts require R 4.6.1", call. = FALSE)
}

producer <- paste0(
  "scripts/hypotheses/H07/",
  "build_h07_preparation_artifacts.R"
)
source_data_dir <- file.path(
  root,
  "artifacts/11_source_data/H07/preparation"
)
figure_dir <- file.path(root, "artifacts/10_figures/H07/preparation")
dir.create(source_data_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)

read_h07_csv <- function(relative_path) {
  path <- file.path(root, relative_path)
  if (!file.exists(path)) {
    stop("Missing H07 preparation input: ", relative_path, call. = FALSE)
  }
  readr::read_csv(path, show_col_types = FALSE)
}

write_h07_csv <- function(data, filename) {
  write_csv_artifact(
    data,
    file.path(source_data_dir, filename),
    producer = producer
  )
}

table_dir <- "artifacts/09_tables/H07"
frame_dir <- "artifacts/07_models/H07/frames"
main_samples <- read_h07_csv(file.path(table_dir, "H07_main_samples.csv"))
main_site_support <- read_h07_csv(
  file.path(table_dir, "H07_main_site_support.csv")
)
input_manifest <- read_h07_csv(
  file.path(table_dir, "H07_input_manifest.csv")
)
formula_registry <- read_h07_csv(
  file.path(table_dir, "H07_formula_registry.csv")
)
plateau <- read_h07_csv(
  file.path(table_dir, "H07_revised_plateau_summary.csv")
) |>
  filter(
    .data$method_id == "REVISED_CENTRAL_UNCONDITIONAL_POINTWISE"
  ) |>
  arrange(
    factor(.data$placement, levels = c("near_eye", "chest")),
    .data$metric_order
  )
diagnostics <- read_h07_csv(
  file.path(table_dir, "H07_main_diagnostics.csv")
) |>
  filter(.data$model_id == "adapted_photoperiod_smooth")
pairwise_concurvity <- read_h07_csv(
  file.path(table_dir, "H07_main_pairwise_concurvity.csv")
) |>
  filter(
    .data$model_id == "adapted_photoperiod_smooth",
    .data$measure == "estimate",
    .data$supplier_term == "s(site_participant)",
    .data$target_term == "s(photoperiod_hours)"
  )
site_registry <- read_h07_csv("config/site_display_registry.csv") |>
  arrange(.data$display_order)

stopifnot(
  nrow(main_samples) == 18L,
  nrow(plateau) == 18L,
  nrow(formula_registry) == 9L,
  nrow(diagnostics) == 18L,
  nrow(pairwise_concurvity) == 18L,
  !anyDuplicated(main_samples[c("run_id", "metric_id")])
)

metric_contract <- plateau |>
  distinct(
    .data$metric_order,
    .data$metric_id,
    .data$manuscript_name,
    .data$display_unit,
    .data$response_family,
    .data$response_transform
  ) |>
  arrange(.data$metric_order)
stopifnot(
  nrow(metric_contract) == 9L,
  identical(as.integer(metric_contract$metric_order), 1:9)
)
write_h07_csv(metric_contract, "H07_preparation_metric_contract.csv")

input_labels <- tibble::tribble(
  ~input_id, ~input_label,
  "primary_near_eye", "Primary near-eye participant-day metrics",
  "primary_chest", "Primary chest participant-day metrics",
  "gap_metrics", "Gap-timing-unaware participant-day metrics",
  "solar_context", "Site-by-date civil-photoperiod context"
)

input_identities <- input_manifest |>
  left_join(input_labels, by = "input_id", relationship = "one-to-one") |>
  mutate(
    absolute_path = normalizePath(
      .data$path,
      winslash = "/",
      mustWork = TRUE
    ),
    relative_path = substring(.data$absolute_path, nchar(root) + 2L),
    current_sha256 = vapply(
      .data$absolute_path,
      artifact_sha256,
      character(1)
    ),
    identity_status = if_else(
      .data$current_sha256 == .data$sha256,
      "PASS",
      "FAIL"
    )
  ) |>
  select(
    .data$input_id,
    .data$input_label,
    .data$relative_path,
    recorded_sha256 = .data$sha256,
    .data$current_sha256,
    .data$identity_status
  )
stopifnot(
  nrow(input_identities) == 4L,
  !anyNA(input_identities$input_label),
  all(input_identities$identity_status == "PASS")
)
write_h07_csv(input_identities, "H07_preparation_input_identities.csv")

frame_integrity_rows <- lapply(seq_len(nrow(main_samples)), function(index) {
  sample_row <- main_samples[index, , drop = FALSE]
  placement <- sub("^primary__", "", sample_row$run_id[[1L]])
  relative_path <- file.path(
    frame_dir,
    sample_row$run_id[[1L]],
    paste0(sample_row$metric_id[[1L]], ".rds")
  )
  absolute_path <- file.path(root, relative_path)
  if (!file.exists(absolute_path)) {
    stop("Missing frozen H07 frame: ", relative_path, call. = FALSE)
  }
  frame <- readRDS(absolute_path)
  contract <- metric_contract |>
    filter(.data$metric_id == sample_row$metric_id[[1L]])
  stopifnot(nrow(contract) == 1L)

  required_columns <- c(
    "data_scenario", "placement", "site", "Id", "local_date",
    "abs_latitude_deg", "photoperiod_hours", "metric_order",
    "metric_id", "source_column", "original_value",
    "site_participant", "response_value", "row_key", "run_id"
  )
  frame_hash <- digest::digest(frame, algo = "sha256", serialize = TRUE)
  observed_participants <- n_distinct(
    paste(as.character(frame$site), as.character(frame$Id), sep = "::")
  )
  observed_sites <- n_distinct(frame$site)
  reconstructed_response <- if (
    contract$response_family[[1L]] == "tweedie_log"
  ) {
    frame$original_value
  } else if (
    contract$response_transform[[1L]] == "log10_offset_0.1"
  ) {
    log10(frame$original_value + 0.1)
  } else {
    frame$original_value
  }
  response_error <- max(abs(
    frame$response_value - reconstructed_response
  ))
  latitude_levels_per_site <- frame |>
    mutate(site = as.character(.data$site)) |>
    group_by(.data$site) |>
    summarise(
      latitude_levels = n_distinct(.data$abs_latitude_deg),
      .groups = "drop"
    )
  schema_complete <- all(required_columns %in% names(frame))
  count_matches <-
    nrow(frame) == sample_row$observations[[1L]] &&
    nrow(frame) == sample_row$participant_days[[1L]] &&
    observed_participants == sample_row$participants[[1L]] &&
    observed_sites == sample_row$sites[[1L]]
  values_valid <- all(
    is.finite(frame$original_value) &
      is.finite(frame$response_value) &
      is.finite(frame$abs_latitude_deg) &
      is.finite(frame$photoperiod_hours)
  )
  keys_unique <- !anyDuplicated(frame$row_key) &&
    !anyDuplicated(frame[c("site", "Id", "local_date")])
  labels_consistent <-
    all(frame$data_scenario == "primary") &&
    all(frame$placement == placement) &&
    all(frame$metric_id == sample_row$metric_id[[1L]]) &&
    all(frame$run_id == sample_row$run_id[[1L]])
  identity_matches <- identical(frame_hash, sample_row$frame_sha256[[1L]])
  overall <- all(c(
    schema_complete,
    count_matches,
    values_valid,
    keys_unique,
    labels_consistent,
    identity_matches,
    response_error < 1e-12,
    all(latitude_levels_per_site$latitude_levels == 1L)
  ))

  tibble::tibble(
    run_id = sample_row$run_id,
    placement = placement,
    metric_order = contract$metric_order,
    metric_id = sample_row$metric_id,
    manuscript_name = contract$manuscript_name,
    relative_path = relative_path,
    recorded_frame_sha256 = sample_row$frame_sha256,
    current_frame_sha256 = frame_hash,
    frame_identity = if_else(identity_matches, "PASS", "FAIL"),
    participants = observed_participants,
    participant_days = nrow(frame),
    observations = nrow(frame),
    sites = observed_sites,
    schema_complete = schema_complete,
    duplicate_row_keys = sum(duplicated(frame$row_key)),
    response_reconstruction_maximum_absolute_error = response_error,
    latitude_constant_within_site = all(
      latitude_levels_per_site$latitude_levels == 1L
    ),
    stored_sample_counts_match = count_matches,
    overall_status = if_else(overall, "PASS", "FAIL")
  )
})

frame_integrity <- bind_rows(frame_integrity_rows) |>
  arrange(
    factor(.data$placement, levels = c("near_eye", "chest")),
    .data$metric_order
  )
if (
  nrow(frame_integrity) != 18L ||
    any(frame_integrity$overall_status != "PASS")
) {
  print(frame_integrity |> filter(.data$overall_status != "PASS"), width = Inf)
  stop("One or more frozen H07 frames failed integrity checks", call. = FALSE)
}
write_h07_csv(frame_integrity, "H07_preparation_frame_integrity.csv")

sample_support <- main_samples |>
  mutate(
    placement = sub("^primary__", "", .data$run_id),
    placement_label = recode(
      .data$placement,
      near_eye = "Near eye — primary",
      chest = "Chest — complementary"
    )
  ) |>
  left_join(
    metric_contract |>
      select(
        .data$metric_order,
        .data$metric_id,
        .data$manuscript_name,
        .data$display_unit
      ),
    by = "metric_id",
    relationship = "many-to-one"
  ) |>
  arrange(
    .data$metric_order,
    factor(.data$placement, levels = c("near_eye", "chest"))
  ) |>
  select(
    .data$run_id,
    .data$placement,
    .data$placement_label,
    .data$metric_order,
    .data$metric_id,
    .data$manuscript_name,
    .data$display_unit,
    .data$participants,
    .data$participant_days,
    .data$observations,
    .data$sites,
    .data$first_date,
    .data$last_date,
    .data$photoperiod_min,
    .data$photoperiod_max,
    .data$unique_photoperiod,
    .data$unique_latitude
  )
write_h07_csv(sample_support, "H07_preparation_sample_support.csv")

site_support <- main_site_support |>
  left_join(
    site_registry |>
      select(
        .data$site,
        .data$display_order,
        site_name = .data$display_name,
        site_color = .data$color_hex
      ),
    by = "site",
    relationship = "many-to-one"
  ) |>
  mutate(
    placement_label = recode(
      .data$placement,
      near_eye = "Near eye — primary",
      chest = "Chest — complementary"
    )
  ) |>
  arrange(
    .data$metric_order,
    factor(.data$placement, levels = c("near_eye", "chest")),
    .data$display_order
  )
stopifnot(
  nrow(site_support) == 153L,
  !anyNA(site_support$site_name),
  !anyNA(site_support$site_color)
)
write_h07_csv(site_support, "H07_preparation_site_support.csv")

site_range_display <- site_support |>
  filter(.data$metric_order == 1L) |>
  select(
    .data$placement,
    .data$placement_label,
    .data$display_order,
    .data$site,
    .data$site_name,
    .data$site_color,
    .data$participants,
    .data$participant_days,
    .data$abs_latitude_deg,
    .data$photoperiod_min,
    .data$photoperiod_max,
    .data$first_date,
    .data$last_date
  )
stopifnot(nrow(site_range_display) == 17L)
write_h07_csv(
  site_range_display,
  "H07_preparation_site_photoperiod_ranges.csv"
)

diagnostic_summary <- diagnostics |>
  mutate(
    placement = sub("^primary__", "", .data$run_id),
    basis_flag =
      is.finite(.data$k_p_value) &
      .data$k_p_value < 0.05
  ) |>
  left_join(
    pairwise_concurvity |>
      select(.data$run_id, .data$metric_id, participant_concurvity = .data$concurvity),
    by = c("run_id", "metric_id"),
    relationship = "one-to-one"
  ) |>
  group_by(.data$placement) |>
  summarise(
    fitted_models = n(),
    converged_models = sum(.data$converged),
    basis_dimension_flags = sum(.data$basis_flag),
    minimum_participant_concurvity = min(.data$participant_concurvity),
    maximum_participant_concurvity = max(.data$participant_concurvity),
    maximum_absolute_consecutive_day_lag1 = max(
      abs(.data$pooled_consecutive_day_lag1)
    ),
    .groups = "drop"
  )
stopifnot(nrow(diagnostic_summary) == 2L)
write_h07_csv(
  diagnostic_summary,
  "H07_preparation_diagnostic_summary.csv"
)

plateau_display <- plateau |>
  transmute(
    .data$placement,
    placement_label = recode(
      .data$placement,
      near_eye = "Near eye — primary",
      chest = "Chest — complementary"
    ),
    .data$metric_order,
    .data$metric_id,
    .data$manuscript_name,
    derivative_defined_pattern = .data$revised_plateau_pattern,
    .data$plateau_transition_lower,
    .data$plateau_start,
    .data$recorded_photoperiod_min,
    .data$recorded_photoperiod_max,
    .data$disposition
  )
write_h07_csv(plateau_display, "H07_preparation_pattern_summary.csv")

formula_display <- formula_registry |>
  mutate(
    analysis_role = case_when(
      .data$model_id == "adapted_photoperiod_smooth" ~ "Reported pooled association",
      .data$model_id == "adapted_photoperiod_linear" ~ "Linear-shape comparison",
      .data$model_id == "adapted_photoperiod_expanded_basis" ~ "Basis-size sensitivity",
      .data$model_id == "adapted_photoperiod_fixed_site" ~ "Fixed-site sensitivity",
      .data$model_id == "registered_null" ~ "No-photoperiod comparison",
      grepl("registered_", .data$model_id) ~ "Latitude/photoperiod identifiability diagnostic",
      TRUE ~ "Supporting model"
    )
  )
write_h07_csv(formula_display, "H07_preparation_formula_registry.csv")

placement_colours <- c(
  near_eye = "#0072B2",
  chest = "#D55E00"
)
placement_shapes <- c(near_eye = 16, chest = 17)

sample_plot_data <- sample_support |>
  mutate(
    metric_label = factor(
      stringr::str_wrap(.data$manuscript_name, width = 38),
      levels = rev(unique(stringr::str_wrap(
        metric_contract$manuscript_name,
        width = 38
      )))
    )
  )

sample_plot <- ggplot(
  sample_plot_data,
  aes(
    x = .data$participant_days,
    y = .data$metric_label,
    colour = .data$placement,
    shape = .data$placement
  )
) +
  geom_point(
    position = position_dodge(width = 0.52),
    size = 3.1,
    stroke = 0.7
  ) +
  scale_colour_manual(
    values = placement_colours,
    breaks = c("near_eye", "chest"),
    labels = c("Near eye — primary", "Chest — complementary")
  ) +
  scale_shape_manual(
    values = placement_shapes,
    breaks = c("near_eye", "chest"),
    labels = c("Near eye — primary", "Chest — complementary")
  ) +
  scale_x_continuous(expand = expansion(mult = c(0.04, 0.06))) +
  labs(
    x = "Participant-days (= observations)",
    y = NULL,
    colour = NULL,
    shape = NULL,
    title = "Metric-specific fitted sample",
    subtitle = paste0(
      "Each point is an exact participant-day model frame.\n",
      "Placements were fitted separately."
    )
  ) +
  theme_minimal(base_size = 12) +
  theme(
    panel.grid.major.y = element_blank(),
    panel.grid.minor = element_blank(),
    plot.title = element_text(face = "bold", size = 15),
    plot.subtitle = element_text(size = 11),
    axis.text = element_text(size = 10),
    axis.title.x = element_text(size = 11),
    legend.position = "bottom",
    legend.text = element_text(size = 10),
    plot.margin = margin(12, 16, 12, 12)
  )

ggplot2::ggsave(
  file.path(figure_dir, "H07_preparation_metric_sample_support.png"),
  sample_plot,
  width = 8.5,
  height = 6.8,
  units = "in",
  dpi = 300,
  bg = "white"
)

site_levels <- rev(site_registry$display_name)
site_plot_data <- site_range_display |>
  mutate(
    site_name = factor(.data$site_name, levels = site_levels),
    placement_label = factor(
      .data$placement_label,
      levels = c("Near eye — primary", "Chest — complementary")
    )
  )

site_plot <- ggplot(
  site_plot_data,
  aes(
    y = .data$site_name,
    colour = .data$site
  )
) +
  geom_segment(
    aes(
      x = .data$photoperiod_min,
      xend = .data$photoperiod_max,
      yend = .data$site_name
    ),
    linewidth = 2.4,
    lineend = "round"
  ) +
  geom_point(aes(x = .data$photoperiod_min), shape = 21, fill = "white", size = 2.6) +
  geom_point(aes(x = .data$photoperiod_max), shape = 21, fill = "white", size = 2.6) +
  facet_wrap(vars(.data$placement_label), ncol = 2, drop = FALSE) +
  scale_colour_manual(
    values = setNames(site_registry$color_hex, site_registry$site),
    guide = "none"
  ) +
  scale_x_continuous(
    breaks = seq(10, 21, by = 2),
    limits = c(10, 21),
    expand = expansion(mult = c(0.01, 0.01))
  ) +
  labs(
    x = "Recorded civil photoperiod (h)",
    y = NULL,
    title = "Site-specific photoperiod coverage",
    subtitle = paste0(
      "Ranges use the complete mean-melEDI frame; colours and site order ",
      "follow the submitted manuscript."
    )
  ) +
  theme_minimal(base_size = 12) +
  theme(
    panel.grid.major.y = element_blank(),
    panel.grid.minor = element_blank(),
    strip.text = element_text(face = "bold", size = 11),
    strip.background = element_rect(fill = "#f3f4f6", colour = NA),
    plot.title = element_text(face = "bold", size = 15),
    plot.subtitle = element_text(size = 11),
    axis.text = element_text(size = 10),
    axis.title.x = element_text(size = 11),
    panel.spacing.x = grid::unit(1.2, "lines"),
    plot.margin = margin(12, 16, 12, 12)
  )

ggplot2::ggsave(
  file.path(figure_dir, "H07_preparation_site_photoperiod_ranges.png"),
  site_plot,
  width = 8.5,
  height = 5.8,
  units = "in",
  dpi = 300,
  bg = "white"
)

message(
  "Recorded H07 preparation artifacts: ",
  nrow(frame_integrity), " verified primary frames, ",
  nrow(sample_support), " sample rows, ",
  nrow(site_support), " metric-placement-site rows, and two display figures"
)
