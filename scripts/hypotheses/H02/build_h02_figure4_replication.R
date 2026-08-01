#!/usr/bin/env Rscript

# Rebuild the submitted Figure 4 visual contract from the audited H02 models.
# This script does not refit a model or run a new simulation. The near-eye and
# chest figures use the same builder and pointwise conditional 95% intervals.

suppressPackageStartupMessages({
  library(cowplot)
  library(dplyr)
  library(ggplot2)
  library(ggtext)
  library(legendry)
  library(mgcv)
  library(patchwork)
  library(readr)
  library(tibble)
  library(tidyr)
})

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
source(file.path(root, "scripts/pipeline/paths_io.R"))
source(file.path(root, "scripts/pipeline/assertions.R"))
source(file.path(root, "scripts/hypotheses/H02/h02_contract.R"))
source(file.path(root, "scripts/hypotheses/H02/h02_data.R"))
source(file.path(root, "scripts/hypotheses/H02/h02_modeling.R"))
source(file.path(root, "scripts/Brown_bracket.R"))

if (getRversion() != "4.6.1") {
  h02_abort("H02 requires R 4.6.1; running %s", getRversion())
}

# Fail closed if a coordinator-approved shared identity changes.
input_audit <- h02_validate_inputs(root)
paths <- pipeline_paths(root)
producer <- "scripts/hypotheses/H02/build_h02_figure4_replication.R"
run_id <- "main__glasses__all_available"
chest_run_id <- "main__chest__all_available"

figure_directory <- file.path(paths$figures, "H02")
table_directory <- file.path(paths$tables, "H02")
source_directory <- file.path(paths$source_data, "H02")
manifest_directory <- file.path(paths$manifests, "H02")
invisible(vapply(
  c(
    figure_directory,
    table_directory,
    source_directory,
    manifest_directory
  ),
  dir.create,
  logical(1),
  recursive = TRUE,
  showWarnings = FALSE
))

artifact_metadata <- list()
record_metadata <- function(metadata, id) {
  artifact_metadata[[id]] <<- metadata
  invisible(metadata)
}
write_h02_csv <- function(data, path, id) {
  record_metadata(write_csv_artifact(data, path, producer), id)
}
write_h02_rds <- function(object, path, id, metadata = list()) {
  record_metadata(
    write_rds_artifact(object, path, producer, metadata),
    id
  )
}
write_h02_plot <- function(plot, path, id, width, height) {
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
    bg = "white",
    limitsize = FALSE
  )
  atomic_replace_artifact(temporary, path)
  info <- file.info(path)
  record_metadata(
    list(
      path = normalizePath(path, winslash = "/", mustWork = TRUE),
      sha256 = artifact_sha256(path),
      bytes = unname(info$size),
      producer = producer,
      r_version = as.character(getRversion()),
      written_utc = format(Sys.time(), tz = "UTC", usetz = TRUE)
    ),
    id
  )
}

registry_path <- file.path(root, "config/site_display_registry.csv")
legacy_figure_path <- file.path(root, "figures/Fig4.png")
frame_path <- file.path(
  paths$model_data,
  "H02",
  paste0(run_id, ".rds")
)
model_path <- file.path(
  paths$models,
  "H02",
  paste0(run_id, "__selected_model.rds")
)
prediction_path <- file.path(
  paths$source_data,
  "H02",
  "site_curve_predictions.csv"
)
contribution_path <- file.path(
  paths$source_data,
  "H02",
  paste0(run_id, "__fitted_contributions.rds")
)
base_path <- file.path(
  paths$model_data,
  "base",
  "metrics_glasses_30_minute_context.rds"
)
chest_frame_path <- file.path(
  paths$model_data,
  "H02",
  paste0(chest_run_id, ".rds")
)
chest_model_path <- file.path(
  paths$models,
  "H02",
  paste0(chest_run_id, "__selected_model.rds")
)
chest_contribution_path <- file.path(
  paths$source_data,
  "H02",
  paste0(chest_run_id, "__fitted_contributions.rds")
)
chest_base_path <- file.path(
  paths$model_data,
  "base",
  "metrics_chest_30_minute_context.rds"
)

required_inputs <- c(
  registry_path,
  legacy_figure_path,
  frame_path,
  model_path,
  prediction_path,
  contribution_path,
  base_path,
  chest_frame_path,
  chest_model_path,
  chest_contribution_path,
  chest_base_path
)
if (any(!file.exists(required_inputs))) {
  h02_abort(
    "Missing Figure 4 input(s): %s",
    paste(required_inputs[!file.exists(required_inputs)], collapse = ", ")
  )
}

site_registry <- readr::read_csv(
  registry_path,
  show_col_types = FALSE
) |>
  dplyr::arrange(.data$display_order)
expected_registry_columns <- c(
  "site",
  "display_order",
  "display_name",
  "color_hex"
)
if (
  !identical(names(site_registry), expected_registry_columns) ||
    anyDuplicated(site_registry$site) ||
    anyDuplicated(site_registry$display_order) ||
    !identical(
      as.integer(site_registry$display_order),
      seq_len(nrow(site_registry))
    )
) {
  h02_abort("DISPLAY-001 registry is malformed")
}
display_levels <- site_registry$display_name
site_palette <- stats::setNames(
  site_registry$color_hex,
  site_registry$display_name
)

frame <- readRDS(frame_path)
fit <- readRDS(model_path)
contributions <- readRDS(contribution_path)
predictions <- readr::read_csv(
  prediction_path,
  show_col_types = FALSE
) |>
  dplyr::filter(.data$run_id == .env$run_id)

fitted_sites <- sort(unique(as.character(frame$site)))
if (!setequal(fitted_sites, site_registry$site)) {
  h02_abort(
    "DISPLAY-001 sites do not match the primary fitted sites"
  )
}
if (nrow(predictions) != length(fitted_sites) * 48L) {
  h02_abort("Primary site predictions must contain 48 bins per site")
}

prepared <- h02_prepare_fit_data(frame)
sites <- levels(prepared$site)
time_hour <- (seq.int(0L, 1410L, by = 30L) + 15) / 60
grid <- tidyr::crossing(
  site = factor(sites, levels = sites),
  time_hour = time_hour
) |>
  dplyr::mutate(
    site_smooth = ordered(as.character(.data$site), levels = sites),
    participant = factor(
      levels(prepared$participant)[1],
      levels = levels(prepared$participant)
    ),
    participant_day = factor(
      levels(prepared$participant_day)[1],
      levels = levels(prepared$participant_day)
    )
  )
L <- mgcv::predict.gam(
  fit,
  newdata = as.data.frame(grid),
  type = "lpmatrix",
  newdata.guaranteed = TRUE
)
random_columns <- h02_random_smooth_indices(fit)
if (length(random_columns) > 0L) {
  L[, random_columns] <- 0
}

beta <- stats::coef(fit)
Vp <- fit$Vp
Vc <- stats::vcov(fit, unconditional = TRUE)
eta <- drop(L %*% beta)
se_conditional <- sqrt(pmax(0, rowSums((L %*% Vp) * L)))
se_unconditional <- sqrt(pmax(0, rowSums((L %*% Vc) * L)))

prediction_check <- grid |>
  dplyr::transmute(
    site = as.character(.data$site),
    time_hour = .data$time_hour,
    eta_reconstructed = eta,
    se_reconstructed = se_conditional
  ) |>
  dplyr::left_join(
    predictions |>
      dplyr::select(
        "site",
        "time_hour",
        "eta",
        "standard_error"
      ),
    by = c("site", "time_hour"),
    relationship = "one-to-one"
  )
if (
  anyNA(prediction_check) ||
    max(abs(
      prediction_check$eta_reconstructed - prediction_check$eta
    )) > 1e-8 ||
    max(abs(
      prediction_check$se_reconstructed -
        prediction_check$standard_error
    )) > 1e-8
) {
  h02_abort("Stored and reconstructed H02 site predictions disagree")
}

time_rows <- split(seq_len(nrow(grid)), grid$time_hour)
L_common <- do.call(
  rbind,
  lapply(time_rows, function(rows) {
    colMeans(L[rows, , drop = FALSE])
  })
)
time_lookup <- match(grid$time_hour, sort(unique(grid$time_hour)))
L_deviation <- L - L_common[time_lookup, , drop = FALSE]
common_eta <- drop(L_common %*% beta)
common_se_conditional <- sqrt(pmax(
  0,
  rowSums((L_common %*% Vp) * L_common)
))
common_se_unconditional <- sqrt(pmax(
  0,
  rowSums((L_common %*% Vc) * L_common)
))
deviation_eta <- drop(L_deviation %*% beta)
deviation_se_conditional <- sqrt(pmax(
  0,
  rowSums((L_deviation %*% Vp) * L_deviation)
))
deviation_se_unconditional <- sqrt(pmax(
  0,
  rowSums((L_deviation %*% Vc) * L_deviation)
))

deviation_check <- grid |>
  dplyr::transmute(
    site = as.character(.data$site),
    time_hour = .data$time_hour,
    eta_reconstructed = deviation_eta,
    se_reconstructed = deviation_se_conditional
  ) |>
  dplyr::left_join(
    predictions |>
      dplyr::select(
        "site",
        "time_hour",
        "equal_site_deviation_eta",
        "deviation_standard_error"
      ),
    by = c("site", "time_hour"),
    relationship = "one-to-one"
  )
if (
  anyNA(deviation_check) ||
    max(abs(
      deviation_check$eta_reconstructed -
        deviation_check$equal_site_deviation_eta
    )) > 1e-8 ||
    max(abs(
      deviation_check$se_reconstructed -
        deviation_check$deviation_standard_error
    )) > 1e-8
) {
  h02_abort("Stored and reconstructed H02 site deviations disagree")
}

primary_critical <- unique(predictions$deviation_simultaneous_critical_value)
if (length(primary_critical) != 1L || !is.finite(primary_critical)) {
  h02_abort("Primary simultaneous critical value is not unique")
}
method_specification <- tibble::tribble(
  ~method_id,
  ~method_label,
  ~critical_value,
  ~standard_error_source,
  ~family_scope,
  ~inferential_role,
  "pointwise_conditional_95",
  "Pointwise conditional 95% intervals",
  stats::qnorm(0.975),
  "Vp; smoothing parameters treated as fixed",
  "Each site-bin contrast separately",
  "Legacy-equivalent visual sensitivity; not simultaneous",
  "bonferroni_within_site_95",
  "Bonferroni 95% band within each site",
  stats::qnorm(1 - 0.05 / (2 * 48)),
  "Vp; smoothing parameters treated as fixed",
  "48 clock bins within one site",
  "Analytic site-wise familywise sensitivity",
  "global_covariance_aware_95",
  "Primary covariance-aware simultaneous 95% band",
  primary_critical,
  "Vp; smoothing parameters treated as fixed",
  "All 9 sites and 48 clock bins jointly",
  "Primary time-resolved inference; reuses completed simulation",
  "global_bonferroni_conditional_95",
  "Global Bonferroni 95% band",
  stats::qnorm(1 - 0.05 / (2 * nrow(grid))),
  "Vp; smoothing parameters treated as fixed",
  "All 9 sites and 48 clock bins jointly",
  "Analytic conservative sensitivity",
  "global_bonferroni_unconditional_95",
  "Global Bonferroni 95% band with smoothing uncertainty",
  stats::qnorm(1 - 0.05 / (2 * nrow(grid))),
  "Vc; smoothing-parameter uncertainty included",
  "All 9 sites and 48 clock bins jointly",
  "Most conservative implemented sensitivity"
)

base_interval_grid <- grid |>
  dplyr::transmute(
    site = as.character(.data$site),
    clock_bin = as.integer(round(.data$time_hour * 60 - 15)),
    time_hour = .data$time_hour,
    deviation_eta = deviation_eta,
    se_conditional = deviation_se_conditional,
    se_unconditional = deviation_se_unconditional
  ) |>
  dplyr::left_join(site_registry, by = "site", relationship = "many-to-one")

intervals <- dplyr::bind_rows(lapply(
  seq_len(nrow(method_specification)),
  function(i) {
    specification <- method_specification[i, ]
    standard_error <- if (
      specification$method_id ==
        "global_bonferroni_unconditional_95"
    ) {
      base_interval_grid$se_unconditional
    } else {
      base_interval_grid$se_conditional
    }
    base_interval_grid |>
      dplyr::mutate(
        method_id = specification$method_id,
        method_label = specification$method_label,
        critical_value = specification$critical_value,
        standard_error = standard_error,
        lower_eta = .data$deviation_eta -
          .data$critical_value * .data$standard_error,
        upper_eta = .data$deviation_eta +
          .data$critical_value * .data$standard_error,
        ratio = 10^.data$deviation_eta,
        ratio_lower = 10^.data$lower_eta,
        ratio_upper = 10^.data$upper_eta,
        direction = dplyr::case_when(
          .data$ratio_lower > 1 ~ "higher",
          .data$ratio_upper < 1 ~ "lower",
          TRUE ~ "not_distinguishable"
        )
      )
  }
)) |>
  dplyr::mutate(
    display_name = factor(.data$display_name, levels = display_levels)
  ) |>
  dplyr::arrange(
    .data$method_id,
    .data$display_order,
    .data$clock_bin
  )

# Require the primary interval reconstruction to match the stored output.
primary_reconstruction <- intervals |>
  dplyr::filter(.data$method_id == "global_covariance_aware_95") |>
  dplyr::left_join(
    predictions |>
      dplyr::select("site", "clock_bin", "ratio_lower", "ratio_upper"),
    by = c("site", "clock_bin"),
    suffix = c("_reconstructed", "_stored"),
    relationship = "one-to-one"
  )
if (
  anyNA(primary_reconstruction) ||
    max(abs(
      primary_reconstruction$ratio_lower_reconstructed -
        primary_reconstruction$ratio_lower_stored
    )) > 1e-8 ||
    max(abs(
      primary_reconstruction$ratio_upper_reconstructed -
        primary_reconstruction$ratio_upper_stored
    )) > 1e-8
) {
  h02_abort("Primary simultaneous intervals were not reproduced exactly")
}

format_clock <- function(minutes) {
  ifelse(
    is.na(minutes),
    NA_character_,
    sprintf("%02d:%02d", (minutes %/% 60L) %% 24L, minutes %% 60L)
  )
}
intervals_segmented <- intervals |>
  dplyr::group_by(.data$method_id, .data$site) |>
  dplyr::mutate(
    segment_start = dplyr::row_number() == 1L |
      .data$direction != dplyr::lag(
        .data$direction,
        default = dplyr::first(.data$direction)
      ),
    segment_id = cumsum(.data$segment_start)
  ) |>
  dplyr::ungroup()

interval_windows <- intervals_segmented |>
  dplyr::filter(.data$direction != "not_distinguishable") |>
  dplyr::group_by(
    .data$method_id,
    .data$method_label,
    .data$site,
    .data$display_order,
    .data$display_name,
    .data$segment_id,
    .data$direction
  ) |>
  dplyr::summarise(
    start_clock_bin = min(.data$clock_bin),
    end_clock_bin_exclusive = max(.data$clock_bin) + 30L,
    bins_30_minute = dplyr::n(),
    minimum_ratio = min(.data$ratio),
    maximum_ratio = max(.data$ratio),
    .groups = "drop"
  ) |>
  dplyr::mutate(
    start_local_clock = format_clock(.data$start_clock_bin),
    end_local_clock = dplyr::if_else(
      .data$end_clock_bin_exclusive == 1440L,
      "24:00",
      format_clock(.data$end_clock_bin_exclusive)
    )
  ) |>
  dplyr::arrange(
    .data$method_id,
    .data$display_order,
    .data$start_clock_bin
  )

window_text <- interval_windows |>
  dplyr::transmute(
    method_id = .data$method_id,
    site = .data$site,
    direction = .data$direction,
    interval = paste0(
      .data$start_local_clock,
      "–",
      .data$end_local_clock
    )
  ) |>
  dplyr::group_by(.data$method_id, .data$site, .data$direction) |>
  dplyr::summarise(
    intervals = paste(.data$interval, collapse = "; "),
    .groups = "drop"
  ) |>
  tidyr::pivot_wider(
    names_from = "direction",
    values_from = "intervals"
  )

primary_direction <- intervals |>
  dplyr::filter(.data$method_id == "global_covariance_aware_95") |>
  dplyr::select("site", "clock_bin", primary_direction = "direction")

robustness <- intervals |>
  dplyr::left_join(
    primary_direction,
    by = c("site", "clock_bin"),
    relationship = "many-to-one"
  ) |>
  dplyr::group_by(
    .data$method_id,
    .data$method_label,
    .data$site,
    .data$display_order,
    .data$display_name
  ) |>
  dplyr::summarise(
    higher_bins = sum(.data$direction == "higher"),
    lower_bins = sum(.data$direction == "lower"),
    significant_bins = sum(.data$direction != "not_distinguishable"),
    primary_significant_bins = sum(
      .data$primary_direction != "not_distinguishable"
    ),
    primary_bins_retained = sum(
      .data$direction == .data$primary_direction &
        .data$primary_direction != "not_distinguishable"
    ),
    contradictory_bins = sum(
      .data$direction != "not_distinguishable" &
        .data$primary_direction != "not_distinguishable" &
        .data$direction != .data$primary_direction
    ),
    .groups = "drop"
  ) |>
  dplyr::mutate(
    retained_fraction_of_primary = dplyr::if_else(
      .data$primary_significant_bins > 0,
      .data$primary_bins_retained / .data$primary_significant_bins,
      NA_real_
    )
  ) |>
  dplyr::left_join(
    window_text,
    by = c("method_id", "site"),
    relationship = "one-to-one"
  ) |>
  dplyr::mutate(
    higher = dplyr::coalesce(.data$higher, "None"),
    lower = dplyr::coalesce(.data$lower, "None")
  ) |>
  dplyr::arrange(.data$display_order, .data$method_id)

input_manifest <- tibble::tibble(
  input_role = c(
    "DISPLAY-001 registry",
    "submitted Figure 4 visual reference",
    "primary H02 model frame",
    "primary H02 selected fitted model",
    "H02 site-curve predictions",
    "H02 fitted contributions",
    "verified prepared near-eye base",
    "complementary chest H02 model frame",
    "complementary chest H02 selected fitted model",
    "complementary chest H02 fitted contributions",
    "verified prepared chest base"
  ),
  path = normalizePath(
    required_inputs,
    winslash = "/",
    mustWork = TRUE
  ),
  sha256 = vapply(required_inputs, artifact_sha256, character(1)),
  bytes = unname(file.info(required_inputs)$size)
)

# Civil-night shading is descriptive context calculated from the exact fitted
# participant-days. Each participant-day contributes once within its site;
# the overall shading then gives each fitted site equal weight.
base <- readRDS(base_path)
fitted_days <- frame |>
  dplyr::distinct(.data$site, .data$Id, .data$local_date)
solar_days <- base |>
  dplyr::select(
    "site",
    "Id",
    "local_date",
    "civil_dawn_wall_minute",
    "civil_dusk_wall_minute"
  ) |>
  dplyr::distinct() |>
  dplyr::semi_join(
    fitted_days,
    by = c("site", "Id", "local_date")
  )
if (
  nrow(solar_days) != nrow(fitted_days) ||
    anyNA(solar_days[c(
      "civil_dawn_wall_minute",
      "civil_dusk_wall_minute"
    )])
) {
  h02_abort("Civil dawn/dusk context is incomplete for fitted days")
}
site_solar <- solar_days |>
  dplyr::group_by(.data$site) |>
  dplyr::summarise(
    fitted_participant_days = dplyr::n(),
    mean_civil_dawn_hour = mean(.data$civil_dawn_wall_minute) / 60,
    mean_civil_dusk_hour = mean(.data$civil_dusk_wall_minute) / 60,
    .groups = "drop"
  ) |>
  dplyr::left_join(site_registry, by = "site", relationship = "one-to-one") |>
  dplyr::mutate(
    display_name = factor(.data$display_name, levels = display_levels)
  ) |>
  dplyr::arrange(.data$display_order)
overall_solar <- site_solar |>
  dplyr::summarise(
    mean_civil_dawn_hour = mean(.data$mean_civil_dawn_hour),
    mean_civil_dusk_hour = mean(.data$mean_civil_dusk_hour)
  )
overall_night <- tibble::tibble(
  xmin = c(0, overall_solar$mean_civil_dusk_hour),
  xmax = c(overall_solar$mean_civil_dawn_hour, 24)
)
site_night <- site_solar |>
  dplyr::select(
    "site",
    "display_name",
    "display_order",
    "mean_civil_dawn_hour",
    "mean_civil_dusk_hour"
  ) |>
  tidyr::uncount(2L, .id = "night_segment") |>
  dplyr::mutate(
    xmin = dplyr::if_else(
      .data$night_segment == 1L,
      0,
      .data$mean_civil_dusk_hour
    ),
    xmax = dplyr::if_else(
      .data$night_segment == 1L,
      .data$mean_civil_dawn_hour,
      24
    )
  )

common_curve <- tibble::tibble(
  time_hour = time_hour,
  eta = common_eta,
  standard_error_conditional = common_se_conditional,
  standard_error_unconditional = common_se_unconditional,
  estimate_melEDI_lx = h02_inverse_transform(common_eta),
  pointwise_lower_melEDI_lx = h02_inverse_transform(
    common_eta - stats::qnorm(0.975) * common_se_conditional
  ),
  pointwise_upper_melEDI_lx = h02_inverse_transform(
    common_eta + stats::qnorm(0.975) * common_se_conditional
  )
)

participant_curves <- contributions$participant |>
  dplyr::left_join(
    common_curve |>
      dplyr::select("time_hour", common_eta = "eta"),
    by = "time_hour",
    relationship = "many-to-one"
  ) |>
  dplyr::left_join(site_registry, by = "site", relationship = "many-to-one") |>
  dplyr::mutate(
    display_name = factor(.data$display_name, levels = display_levels),
    fitted_melEDI_lx = h02_inverse_transform(
      .data$common_eta + .data$participant_eta
    )
  )

site_curves <- predictions |>
  dplyr::left_join(site_registry, by = "site", relationship = "many-to-one") |>
  dplyr::mutate(
    display_name = factor(.data$display_name, levels = display_levels)
  ) |>
  dplyr::arrange(.data$display_order, .data$clock_bin)

background_site_curves <- tidyr::crossing(
  panel_display_name = factor(display_levels, levels = display_levels),
  site_curves |>
    dplyr::transmute(
      source_site = .data$site,
      time_hour = .data$time_hour,
      estimate_melEDI_lx = .data$estimate_melEDI_lx,
      lower_melEDI_lx = .data$lower_melEDI_lx,
      upper_melEDI_lx = .data$upper_melEDI_lx
    )
)

primary_deviations <- intervals_segmented |>
  dplyr::filter(.data$method_id == "global_covariance_aware_95") |>
  dplyr::arrange(.data$display_order, .data$clock_bin)

horizontal_melEDI_guides <- c(1, 10, 100, 250, 1000)
melEDI_breaks <- c(0, 1, 10, 100, 250, 1000)
clock_breaks <- c(0, 6, 12, 18, 24)
figure_theme <- cowplot::theme_cowplot(font_size = 12) +
  theme(
    panel.spacing = grid::unit(1, "lines"),
    plot.caption = ggtext::element_markdown(size = 8),
    legend.position = "none"
  )

panel_a <- ggplot(common_curve, aes(x = .data$time_hour)) +
  geom_hline(
    yintercept = horizontal_melEDI_guides,
    colour = "grey70",
    linetype = "dashed",
    linewidth = 0.35
  ) +
  geom_rect(
    data = overall_night,
    aes(xmin = .data$xmin, xmax = .data$xmax),
    ymin = -Inf,
    ymax = Inf,
    inherit.aes = FALSE,
    fill = "grey45",
    alpha = 0.28
  ) +
  geom_ribbon(
    aes(
      ymin = .data$pointwise_lower_melEDI_lx,
      ymax = .data$pointwise_upper_melEDI_lx
    ),
    fill = "grey35",
    alpha = 0.50
  ) +
  geom_line(aes(y = .data$estimate_melEDI_lx), linewidth = 0.9) +
  scale_x_continuous(breaks = clock_breaks) +
  scale_y_continuous(
    trans = LightLogR::symlog_trans(),
    breaks = melEDI_breaks
  ) +
  coord_cartesian(xlim = c(0, 24), ylim = c(0, 1500), expand = FALSE) +
  labs(
    x = "Local time (hrs)",
    y = "Near-eye melEDI (lx)"
  ) +
  guides(y = ggplot2::guide_axis_stack(Brown_bracket, "axis")) +
  figure_theme

panel_b <- ggplot(
  participant_curves,
  aes(
    x = .data$time_hour,
    y = .data$fitted_melEDI_lx,
    group = .data$participant,
    colour = .data$display_name
  )
) +
  geom_hline(
    yintercept = horizontal_melEDI_guides,
    colour = "grey70",
    linetype = "dashed",
    linewidth = 0.35
  ) +
  geom_rect(
    data = overall_night,
    aes(xmin = .data$xmin, xmax = .data$xmax),
    ymin = -Inf,
    ymax = Inf,
    inherit.aes = FALSE,
    fill = "grey45",
    alpha = 0.28
  ) +
  geom_line(linewidth = 0.55, alpha = 0.36) +
  scale_colour_manual(values = site_palette, drop = FALSE) +
  scale_x_continuous(breaks = clock_breaks) +
  scale_y_continuous(
    trans = LightLogR::symlog_trans(),
    breaks = melEDI_breaks
  ) +
  coord_cartesian(xlim = c(0, 24), ylim = c(0, 15000), expand = FALSE) +
  labs(
    x = "Local time (hrs)",
    y = "Near-eye melEDI (lx)"
  ) +
  guides(y = ggplot2::guide_axis_stack(Brown_bracket, "axis")) +
  figure_theme

panel_c_labels <- site_registry |>
  dplyr::transmute(
    display_name = factor(.data$display_name, levels = display_levels),
    label = .data$display_name,
    x = 12,
    y = 4300
  )
panel_c <- ggplot() +
  geom_hline(
    yintercept = horizontal_melEDI_guides,
    colour = "grey70",
    linetype = "dashed",
    linewidth = 0.30
  ) +
  geom_rect(
    data = site_night,
    aes(xmin = .data$xmin, xmax = .data$xmax),
    ymin = -Inf,
    ymax = Inf,
    inherit.aes = FALSE,
    fill = "grey45",
    alpha = 0.28
  ) +
  geom_ribbon(
    data = background_site_curves,
    aes(
      x = .data$time_hour,
      ymin = .data$lower_melEDI_lx,
      ymax = .data$upper_melEDI_lx,
      group = interaction(.data$panel_display_name, .data$source_site)
    ),
    fill = "grey70",
    alpha = 0.08
  ) +
  geom_line(
    data = background_site_curves,
    aes(
      x = .data$time_hour,
      y = .data$estimate_melEDI_lx,
      group = interaction(.data$panel_display_name, .data$source_site)
    ),
    colour = "grey72",
    linewidth = 0.25,
    alpha = 0.55
  ) +
  geom_ribbon(
    data = site_curves,
    aes(
      x = .data$time_hour,
      ymin = .data$lower_melEDI_lx,
      ymax = .data$upper_melEDI_lx,
      fill = .data$display_name
    ),
    alpha = 0.50
  ) +
  geom_line(
    data = site_curves,
    aes(x = .data$time_hour, y = .data$estimate_melEDI_lx),
    colour = "black",
    linewidth = 0.8
  ) +
  geom_label(
    data = panel_c_labels,
    aes(
      x = .data$x,
      y = .data$y,
      label = .data$label,
      colour = .data$display_name
    ),
    fill = "white",
    linewidth = 0.25,
    size = 3.2,
    show.legend = FALSE
  ) +
  facet_wrap(vars(.data$display_name), ncol = 3, drop = TRUE) +
  scale_fill_manual(values = site_palette, drop = FALSE) +
  scale_colour_manual(values = site_palette, drop = FALSE) +
  scale_x_continuous(breaks = clock_breaks) +
  scale_y_continuous(
    trans = LightLogR::symlog_trans(),
    breaks = melEDI_breaks
  ) +
  coord_cartesian(xlim = c(0, 24), ylim = c(0, 10000), expand = FALSE) +
  labs(x = "Local time (hrs)", y = "Near-eye melEDI (lx)") +
  figure_theme +
  theme(
    strip.background = element_blank(),
    strip.text = element_blank()
  )

panel_d <- ggplot(
  primary_deviations,
  aes(x = .data$time_hour, y = .data$ratio)
) +
  geom_hline(
    yintercept = c(0.1, 0.2, 0.5, 2, 5, 10),
    colour = "grey70",
    linetype = "dashed",
    linewidth = 0.30
  ) +
  geom_rect(
    data = site_night,
    aes(xmin = .data$xmin, xmax = .data$xmax),
    ymin = -Inf,
    ymax = Inf,
    inherit.aes = FALSE,
    fill = "grey45",
    alpha = 0.28
  ) +
  geom_ribbon(
    aes(
      ymin = .data$ratio_lower,
      ymax = .data$ratio_upper,
      fill = .data$display_name
    ),
    alpha = 0.50
  ) +
  geom_hline(yintercept = 1, linewidth = 0.8, linetype = "dashed") +
  geom_line(colour = "black", linewidth = 0.8) +
  geom_line(
    data = dplyr::filter(
      primary_deviations,
      .data$direction != "not_distinguishable"
    ),
    aes(group = interaction(.data$display_name, .data$segment_id)),
    colour = "red",
    linewidth = 1.0
  ) +
  facet_wrap(vars(.data$display_name), ncol = 3, drop = TRUE) +
  scale_fill_manual(values = site_palette, drop = FALSE) +
  scale_x_continuous(breaks = clock_breaks) +
  scale_y_log10(
    breaks = c(0.1, 0.2, 0.5, 1, 2, 5, 10),
    labels = c("0.1", "0.2", "0.5", "1", "2", "5", "10")
  ) +
  coord_cartesian(xlim = c(0, 24), ylim = c(0.05, 20), expand = FALSE) +
  labs(x = "Local time (hrs)", y = "Site / global time effect") +
  figure_theme +
  theme(
    strip.background = element_blank(),
    strip.text = element_blank()
  )

figure_caption <- paste0(
  "<i>daytime</i>, <i>evening</i>, and <i>sleep</i> mark the healthy-light ",
  "recommendation ranges used in the submitted Figure 4 (Brown et al., 2022). ",
  "Grey vertical shading shows mean civil night in the exact fitted sample. ",
  "Panel A uses a descriptive pointwise 95% band to reproduce the submitted ",
  "visual; inferential site windows in panel D use the primary joint ",
  "covariance-aware simultaneous 95% band across all nine sites and 48 bins."
)
figure4 <- ((panel_a / panel_b) | (panel_c / panel_d)) +
  patchwork::plot_annotation(
    tag_levels = "A",
    caption = figure_caption,
    theme = theme(
      plot.caption = ggtext::element_markdown(size = 8, hjust = 0)
    )
  )

# Replace the legacy visual object with the shared pointwise builder. Both
# placements therefore use the identical interval definition, styling, and
# panel construction.
source(file.path(
  root,
  "scripts/hypotheses/H02/h02_figure4_pointwise.R"
))
near_eye_contract <- h02_build_figure_contract(
  run_id = run_id,
  placement_label = "Near-eye",
  frame_path = frame_path,
  model_path = model_path,
  contribution_path = contribution_path,
  base_path = base_path,
  prediction_path = prediction_path,
  site_registry = site_registry
)
chest_contract <- h02_build_figure_contract(
  run_id = chest_run_id,
  placement_label = "Chest",
  frame_path = chest_frame_path,
  model_path = chest_model_path,
  contribution_path = chest_contribution_path,
  base_path = chest_base_path,
  prediction_path = prediction_path,
  site_registry = site_registry
)
if (
  near_eye_contract$participant_days != 816L ||
    chest_contract$participant_days != 902L
) {
  h02_abort(
    paste0(
      "Unexpected fitted participant-day count: near-eye %d, chest %d"
    ),
    near_eye_contract$participant_days,
    chest_contract$participant_days
  )
}
figure4 <- h02_build_figure4_layout(near_eye_contract)
figure4_chest <- h02_build_figure4_layout(chest_contract)
pointwise_windows <- h02_pointwise_windows(list(
  near_eye_contract,
  chest_contract
))

figure_path_png <- file.path(
  figure_directory,
  "figure4_exact_layout_replication.png"
)
figure_path_pdf <- file.path(
  figure_directory,
  "figure4_exact_layout_replication.pdf"
)
chest_figure_path_png <- file.path(
  figure_directory,
  "figure4_exact_layout_replication_chest.png"
)
chest_figure_path_pdf <- file.path(
  figure_directory,
  "figure4_exact_layout_replication_chest.pdf"
)
methods_path <- file.path(
  table_directory,
  "uncertainty_band_methods.csv"
)
windows_path <- file.path(
  table_directory,
  "uncertainty_band_windows.csv"
)
robustness_path <- file.path(
  table_directory,
  "uncertainty_band_robustness.csv"
)
pointwise_windows_path <- file.path(
  table_directory,
  "figure4_pointwise_conditional_windows.csv"
)
solar_path <- file.path(
  table_directory,
  "figure4_civil_night_context.csv"
)
source_path <- file.path(
  source_directory,
  "figure4_exact_layout_source.rds"
)
chest_source_path <- file.path(
  source_directory,
  "figure4_exact_layout_source_chest.rds"
)
inputs_path <- file.path(
  manifest_directory,
  "figure4_replication_inputs.csv"
)

write_h02_plot(
  figure4,
  figure_path_png,
  "figure4_png",
  width = 11,
  height = 14
)
write_h02_plot(
  figure4,
  figure_path_pdf,
  "figure4_pdf",
  width = 11,
  height = 14
)
write_h02_plot(
  figure4_chest,
  chest_figure_path_png,
  "figure4_chest_png",
  width = 11,
  height = 14
)
write_h02_plot(
  figure4_chest,
  chest_figure_path_pdf,
  "figure4_chest_pdf",
  width = 11,
  height = 14
)
write_h02_csv(
  method_specification,
  methods_path,
  "uncertainty_methods"
)
write_h02_csv(
  interval_windows |>
    dplyr::mutate(display_name = as.character(.data$display_name)),
  windows_path,
  "uncertainty_windows"
)
write_h02_csv(
  robustness |>
    dplyr::mutate(display_name = as.character(.data$display_name)),
  robustness_path,
  "uncertainty_robustness"
)
write_h02_csv(
  pointwise_windows,
  pointwise_windows_path,
  "pointwise_conditional_windows"
)
write_h02_csv(
  dplyr::bind_rows(
    near_eye_contract$site_solar |>
      dplyr::mutate(
        run_id = near_eye_contract$run_id,
        placement = near_eye_contract$placement_label,
        display_name = as.character(.data$display_name)
      ),
    chest_contract$site_solar |>
      dplyr::mutate(
        run_id = chest_contract$run_id,
        placement = chest_contract$placement_label,
        display_name = as.character(.data$display_name)
      )
  ) |>
    dplyr::select(
      "run_id",
      "placement",
      dplyr::everything()
    ),
  solar_path,
  "civil_night_context"
)
write_h02_rds(
  list(
    display_registry = site_registry,
    participant_days = near_eye_contract$participant_days,
    common_curve = near_eye_contract$common_curve,
    participant_curves = near_eye_contract$participant_curves,
    site_curves = near_eye_contract$site_curves,
    primary_deviations = near_eye_contract$primary_deviations,
    interval_methods = method_specification,
    interval_results = intervals,
    interval_windows = interval_windows,
    robustness = robustness,
    site_solar = near_eye_contract$site_solar,
    overall_solar = near_eye_contract$overall_solar,
    input_manifest = input_manifest
  ),
  source_path,
  "figure4_source",
  metadata = list(
    run_id = run_id,
    figure_contract = "submitted Figure 4 A-D layout",
    display_decision = "DISPLAY-001",
    primary_interval = "pointwise_conditional_95",
    new_simulation = FALSE
  )
)
write_h02_rds(
  list(
    display_registry = site_registry,
    participant_days = chest_contract$participant_days,
    common_curve = chest_contract$common_curve,
    participant_curves = chest_contract$participant_curves,
    site_curves = chest_contract$site_curves,
    primary_deviations = chest_contract$primary_deviations,
    site_solar = chest_contract$site_solar,
    overall_solar = chest_contract$overall_solar,
    input_manifest = input_manifest
  ),
  chest_source_path,
  "figure4_chest_source",
  metadata = list(
    run_id = chest_run_id,
    figure_contract = "submitted Figure 4 A-D layout",
    display_decision = "DISPLAY-001",
    primary_interval = "pointwise_conditional_95",
    new_simulation = FALSE
  )
)
write_h02_csv(input_manifest, inputs_path, "figure4_inputs")

manifest_rows <- dplyr::bind_rows(lapply(
  names(artifact_metadata),
  function(id) {
    metadata <- artifact_metadata[[id]]
    tibble::tibble(
      artifact_id = id,
      path = metadata$path,
      sha256 = metadata$sha256,
      bytes = metadata$bytes,
      producer = metadata$producer,
      r_version = metadata$r_version,
      written_utc = metadata$written_utc,
      status = "PASS"
    )
  }
))
manifest_path <- file.path(
  manifest_directory,
  "figure4_replication_manifest.csv"
)
write_csv_artifact(manifest_rows, manifest_path, producer)

message("H02 Figure 4 replication and interval robustness outputs written")
message("  figure: ", figure_path_png)
message("  methods: ", methods_path)
message("  robustness: ", robustness_path)
message("  manifest: ", manifest_path)
