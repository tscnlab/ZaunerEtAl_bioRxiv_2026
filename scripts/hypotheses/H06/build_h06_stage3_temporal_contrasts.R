# Derive Stage 3 temporal contrasts from the frozen H06 two-part GAMMs.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)

source(file.path(root, "scripts/pipeline/paths_io.R"))
source(file.path(root, "scripts/hypotheses/H06/h06_contract.R"))

if (!identical(as.character(getRversion()), "4.6.1")) {
  h06_abort(
    "H06 Stage 3 temporal contrasts require R 4.6.1; found %s",
    as.character(getRversion())
  )
}

required_packages <- c(
  "dplyr",
  "tidyr",
  "tibble",
  "readr",
  "ggplot2",
  "scales",
  "mgcv"
)
missing_packages <- required_packages[
  !vapply(
    required_packages,
    requireNamespace,
    logical(1),
    quietly = TRUE
  )
]
if (length(missing_packages) > 0L) {
  h06_abort(
    "H06 Stage 3 temporal contrasts are missing project package(s): %s",
    paste(missing_packages, collapse = ", ")
  )
}

producer <- paste0(
  "scripts/hypotheses/H06/",
  "build_h06_stage3_temporal_contrasts.R"
)
paths <- pipeline_paths(root)
roots <- list(
  model_data = file.path(paths$model_data, "H06"),
  models = file.path(paths$models, "H06"),
  figures = file.path(paths$figures, "H06"),
  source_data = file.path(paths$source_data, "H06"),
  manifests = file.path(paths$manifests, "H06"),
  qa = file.path(paths$manifests, "H06", "qa")
)
invisible(vapply(
  roots,
  dir.create,
  logical(1),
  recursive = TRUE,
  showWarnings = FALSE
))

write_h06_csv <- function(data, path) {
  write_csv_artifact(data, path, producer = producer)
  invisible(path)
}

h06_relative_path <- function(path) {
  normalized <- normalizePath(path, winslash = "/", mustWork = TRUE)
  if (startsWith(normalized, paste0(root, "/"))) {
    substring(normalized, nchar(root) + 2L)
  } else {
    normalized
  }
}

input_contract <- h06_input_contract(root)
input_hashes_match <- vapply(
  seq_len(nrow(input_contract)),
  function(index) {
    identical(
      artifact_sha256(input_contract$path[[index]]),
      input_contract$expected_sha256[[index]]
    )
  },
  logical(1)
)
if (any(!input_hashes_match)) {
  h06_abort(
    "Frozen H06 Stage 3 input(s) changed: %s",
    paste(
      input_contract$input_role[!input_hashes_match],
      collapse = ", "
    )
  )
}

frame_path <- file.path(
  roots$model_data,
  "main__glasses__all_available__frame.rds"
)
model_path <- file.path(
  roots$models,
  "H06_exploratory_time_of_day_two_part.rds"
)
day_type_path <- file.path(
  roots$source_data,
  "H06_exploratory_two_part_day_type_predictions.csv"
)
activity_path <- file.path(
  roots$source_data,
  "H06_exploratory_two_part_activity_predictions.csv"
)

stage2_manifest <- readr::read_csv(
  file.path(roots$manifests, "H06_stage2_artifacts.csv"),
  show_col_types = FALSE
)
required_stage2_paths <- c(
  "artifacts/06_model_data/H06/main__glasses__all_available__frame.rds",
  "artifacts/07_models/H06/H06_exploratory_time_of_day_two_part.rds",
  paste0(
    "artifacts/11_source_data/H06/",
    "H06_exploratory_two_part_day_type_predictions.csv"
  ),
  paste0(
    "artifacts/11_source_data/H06/",
    "H06_exploratory_two_part_activity_predictions.csv"
  )
)
required_stage2 <- stage2_manifest[
  match(required_stage2_paths, stage2_manifest$path),
  ,
  drop = FALSE
]
required_files <- file.path(root, required_stage2$path)
if (
  anyNA(required_stage2$path) ||
    !all(file.exists(required_files)) ||
    !identical(
      unname(vapply(required_files, artifact_sha256, character(1))),
      required_stage2$sha256
    )
) {
  h06_abort("A frozen Stage 2 temporal-model artifact changed")
}

frame <- readRDS(frame_path)
model_bundle <- readRDS(model_path)
day_type_stage2 <- readr::read_csv(day_type_path, show_col_types = FALSE)
activity_stage2 <- readr::read_csv(activity_path, show_col_types = FALSE)

if (
  !identical(
    model_bundle$contract_version,
    paste0(
      "v3_two_part_cyclic_factor_by_group_equal_site_",
      "k16_selected_discrete_working_ar"
    )
  ) ||
    !identical(
      sort(names(model_bundle$base_fits)),
      c("occurrence", "positive_magnitude")
    ) ||
    !all(vapply(
      model_bundle$base_fits,
      function(fit) identical(fit$k, 16L),
      logical(1)
    )) ||
    nrow(frame) != 16596L ||
    sum(frame$response_value == 0) != 4697L ||
    artifact_sha256(frame_path) != model_bundle$frame_sha256
) {
  h06_abort("The accepted H06 two-part model bundle failed validation")
}

factor_columns <- c(
  "site",
  "work_free_day",
  "activity_status",
  "participant_key",
  "participant_day_key"
)
occurrence_data <- frame |>
  dplyr::mutate(
    dplyr::across(dplyr::all_of(factor_columns), droplevels),
    day_activity_group = h06_day_activity_group(
      work_free_day,
      activity_status
    )
  )
positive_data <- occurrence_data |>
  dplyr::filter(response_value > 0) |>
  dplyr::mutate(
    dplyr::across(
      dplyr::all_of(c(factor_columns, "day_activity_group")),
      droplevels
    )
  )
component_data <- list(
  occurrence = occurrence_data,
  positive_magnitude = positive_data
)

site_levels <- levels(occurrence_data$site)
day_type_grid <- tidyr::expand_grid(
  clock_hour = seq(0, 24, by = 0.25),
  work_free_day = factor(
    levels(occurrence_data$work_free_day),
    levels = levels(occurrence_data$work_free_day)
  )
) |>
  dplyr::mutate(
    previous_sleep_duration_centered_h = 0,
    prediction_row_id = dplyr::row_number()
  )
day_type_standardization <- tidyr::expand_grid(
  day_type_grid,
  activity_status = factor(
    levels(occurrence_data$activity_status),
    levels = levels(occurrence_data$activity_status)
  ),
  site = factor(site_levels, levels = site_levels)
) |>
  dplyr::mutate(
    day_activity_group = h06_day_activity_group(
      work_free_day,
      activity_status
    )
  )

activity_grid <- tidyr::expand_grid(
  clock_hour = seq(0, 24, by = 0.25),
  activity_status = factor(
    levels(occurrence_data$activity_status),
    levels = levels(occurrence_data$activity_status)
  )
) |>
  dplyr::mutate(
    previous_sleep_duration_centered_h = 0,
    prediction_row_id = dplyr::row_number()
  )
activity_standardization <- tidyr::expand_grid(
  activity_grid,
  work_free_day = factor(
    levels(occurrence_data$work_free_day),
    levels = levels(occurrence_data$work_free_day)
  ),
  site = factor(site_levels, levels = site_levels)
) |>
  dplyr::mutate(
    day_activity_group = h06_day_activity_group(
      work_free_day,
      activity_status
    )
  )

gradient_standard_error <- function(gradient, covariance) {
  active <- which(colSums(abs(gradient)) > 0)
  if (length(active) == 0L) {
    return(rep(0, nrow(gradient)))
  }
  gradient_active <- gradient[, active, drop = FALSE]
  covariance_active <- covariance[active, active, drop = FALSE]
  sqrt(pmax(
    rowSums((gradient_active %*% covariance_active) * gradient_active),
    0
  ))
}

predict_component <- function(fit, newdata_grid) {
  data <- component_data[[fit$component]]
  newdata <- newdata_grid |>
    dplyr::mutate(
      participant_key = factor(
        levels(data$participant_key)[[1L]],
        levels = levels(data$participant_key)
      ),
      participant_day_key = factor(
        levels(data$participant_day_key)[[1L]],
        levels = levels(data$participant_day_key)
      )
    )
  lpmatrix <- stats::predict(
    fit$model,
    newdata = newdata,
    type = "lpmatrix",
    exclude = c("s(participant_key)", "s(participant_day_key)")
  )
  linear_predictor <- as.numeric(lpmatrix %*% stats::coef(fit$model))
  response <- if (fit$component == "occurrence") {
    stats::plogis(linear_predictor)
  } else {
    exp(linear_predictor)
  }
  list(
    newdata = newdata,
    lpmatrix = lpmatrix,
    response = response
  )
}

standardize_expected <- function(target_grid, newdata_grid) {
  occurrence_fit <- model_bundle$base_fits$occurrence
  magnitude_fit <- model_bundle$base_fits$positive_magnitude
  occurrence <- predict_component(occurrence_fit, newdata_grid)
  magnitude <- predict_component(magnitude_fit, newdata_grid)
  if (
    !identical(
      occurrence$newdata$prediction_row_id,
      magnitude$newdata$prediction_row_id
    ) ||
      !identical(occurrence$newdata$site, magnitude$newdata$site)
  ) {
    h06_abort("The Stage 3 occurrence and magnitude grids differ")
  }

  expected_row <- occurrence$response * magnitude$response
  expected_mean <- numeric(nrow(target_grid))
  occurrence_gradient <- matrix(
    0,
    nrow = nrow(target_grid),
    ncol = ncol(occurrence$lpmatrix)
  )
  magnitude_gradient <- matrix(
    0,
    nrow = nrow(target_grid),
    ncol = ncol(magnitude$lpmatrix)
  )
  for (row_id in seq_len(nrow(target_grid))) {
    index <- which(occurrence$newdata$prediction_row_id == row_id)
    expected_mean[[row_id]] <- mean(expected_row[index])
    occurrence_gradient[row_id, ] <- colMeans(
      occurrence$lpmatrix[index, , drop = FALSE] *
        magnitude$response[index] *
        occurrence$response[index] *
        (1 - occurrence$response[index])
    )
    magnitude_gradient[row_id, ] <- colMeans(
      magnitude$lpmatrix[index, , drop = FALSE] * expected_row[index]
    )
  }
  list(
    target = target_grid,
    expected_mean = expected_mean,
    occurrence_gradient = occurrence_gradient,
    magnitude_gradient = magnitude_gradient
  )
}

day_type_expected <- standardize_expected(
  day_type_grid,
  day_type_standardization
)
activity_expected <- standardize_expected(
  activity_grid,
  activity_standardization
)

build_support <- function(source, target_column, numerator, denominator) {
  support_columns <- c(
    "observations",
    "positive_observations",
    "zero_observations",
    "participants",
    "participant_days",
    "sites_with_support"
  )
  numerator_support <- source |>
    dplyr::filter(as.character(.data[[target_column]]) == numerator) |>
    dplyr::select(clock_hour, dplyr::all_of(support_columns)) |>
    dplyr::rename_with(
      function(name) paste0("numerator_", name),
      dplyr::all_of(support_columns)
    )
  denominator_support <- source |>
    dplyr::filter(as.character(.data[[target_column]]) == denominator) |>
    dplyr::select(clock_hour, dplyr::all_of(support_columns)) |>
    dplyr::rename_with(
      function(name) paste0("denominator_", name),
      dplyr::all_of(support_columns)
    )
  dplyr::left_join(
    numerator_support,
    denominator_support,
    by = "clock_hour",
    relationship = "one-to-one"
  )
}

build_ratio_contrast <- function(
  expected,
  target_column,
  numerator,
  denominator,
  contrast_id,
  contrast_label,
  standardization,
  stage2_source
) {
  target_value <- as.character(expected$target[[target_column]])
  numerator_index <- which(target_value == numerator)
  denominator_index <- which(target_value == denominator)
  numerator_index <- numerator_index[
    order(expected$target$clock_hour[numerator_index])
  ]
  denominator_index <- denominator_index[
    order(expected$target$clock_hour[denominator_index])
  ]
  numerator_clock <- expected$target$clock_hour[numerator_index]
  denominator_clock <- expected$target$clock_hour[denominator_index]
  if (!identical(numerator_clock, denominator_clock)) {
    h06_abort("The %s contrast grids are not paired", contrast_id)
  }

  numerator_mean <- expected$expected_mean[numerator_index]
  denominator_mean <- expected$expected_mean[denominator_index]
  occurrence_gradient <-
    expected$occurrence_gradient[numerator_index, , drop = FALSE] /
    numerator_mean -
    expected$occurrence_gradient[denominator_index, , drop = FALSE] /
      denominator_mean
  magnitude_gradient <-
    expected$magnitude_gradient[numerator_index, , drop = FALSE] /
    numerator_mean -
    expected$magnitude_gradient[denominator_index, , drop = FALSE] /
      denominator_mean
  occurrence_se <- gradient_standard_error(
    occurrence_gradient,
    model_bundle$base_fits$occurrence$model$Vp
  )
  magnitude_se <- gradient_standard_error(
    magnitude_gradient,
    model_bundle$base_fits$positive_magnitude$model$Vp
  )
  se_log_ratio <- sqrt(occurrence_se^2 + magnitude_se^2)
  log_ratio <- log(numerator_mean) - log(denominator_mean)
  critical <- stats::qnorm(0.975)

  tibble::tibble(
    contrast_id = contrast_id,
    contrast_label = contrast_label,
    clock_hour = numerator_clock,
    numerator = numerator,
    denominator = denominator,
    numerator_expected_melEDI_lx = numerator_mean,
    denominator_expected_melEDI_lx = denominator_mean,
    expected_melEDI_ratio = exp(log_ratio),
    pointwise_low_ratio = exp(log_ratio - critical * se_log_ratio),
    pointwise_high_ratio = exp(log_ratio + critical * se_log_ratio),
    log_ratio = log_ratio,
    standard_error_log_ratio = se_log_ratio,
    occurrence_standard_error_contribution = occurrence_se,
    positive_magnitude_standard_error_contribution = magnitude_se
  ) |>
    dplyr::left_join(
      build_support(
        stage2_source,
        target_column,
        numerator,
        denominator
      ),
      by = "clock_hour",
      relationship = "one-to-one"
    ) |>
    dplyr::mutate(
      null_reference_ratio = 1,
      basis_k = 16L,
      sites_standardized = length(site_levels),
      other_factor_levels_standardized = 2L,
      standardization = standardization,
      model_components = paste(
        "Binomial-logit positive occurrence multiplied by Gamma-log",
        "positive magnitude"
      ),
      occurrence_working_rho = model_bundle$base_fits$occurrence$rho,
      positive_magnitude_working_rho = model_bundle$base_fits$positive_magnitude$rho,
      random_effects = paste(
        "Participant and participant-day random-effect smooths excluded"
      ),
      interval_scope = paste(
        "Approximate pointwise 95% interval for the response-scale ratio;",
        "smoothing parameters fixed and occurrence-magnitude cross-component",
        "covariance set to zero; not simultaneous or multiplicity controlled"
      ),
      inferential_role = paste(
        "exploratory_time_of_day_contrast_not_primary_inference;",
        "no confirmatory whole-curve test"
      ),
      pointwise_highlighting = "none",
      display_scale = "ggplot2::scale_y_log10()"
    )
}

active_level <- "Active (light, moderate, or vigorous exercise)"
sedentary_level <- "Sedentary (no reported exercise)"
activity_contrast <- build_ratio_contrast(
  activity_expected,
  target_column = "activity_status",
  numerator = active_level,
  denominator = sedentary_level,
  contrast_id = "active_vs_sedentary",
  contrast_label = "Active / Sedentary",
  standardization = paste(
    "Response-scale expected melEDI gives equal weight to work and free",
    "days and to each of the nine submitted sites"
  ),
  stage2_source = activity_stage2
)
day_type_contrast <- build_ratio_contrast(
  day_type_expected,
  target_column = "work_free_day",
  numerator = "Free day",
  denominator = "Work day",
  contrast_id = "free_vs_work",
  contrast_label = "Free day / Work day",
  standardization = paste(
    "Response-scale expected melEDI gives equal weight to sedentary and",
    "active status and to each of the nine submitted sites"
  ),
  stage2_source = day_type_stage2
)
contrast_source <- dplyr::bind_rows(
  activity_contrast,
  day_type_contrast
) |>
  dplyr::mutate(
    contrast_label = factor(
      contrast_label,
      levels = c("Active / Sedentary", "Free day / Work day")
    )
  ) |>
  dplyr::arrange(contrast_label, clock_hour)

stage2_day_check <- day_type_stage2 |>
  dplyr::select(clock_hour, work_free_day, expected_melEDI_lx) |>
  tidyr::pivot_wider(
    names_from = work_free_day,
    values_from = expected_melEDI_lx
  ) |>
  dplyr::mutate(expected_ratio = `Free day` / `Work day`)
stage2_activity_check <- activity_stage2 |>
  dplyr::mutate(
    activity_short = dplyr::if_else(
      grepl("^Active", activity_status),
      "Active",
      "Sedentary"
    )
  ) |>
  dplyr::select(clock_hour, activity_short, expected_melEDI_lx) |>
  tidyr::pivot_wider(
    names_from = activity_short,
    values_from = expected_melEDI_lx
  ) |>
  dplyr::mutate(expected_ratio = Active / Sedentary)
if (
  max(abs(
    day_type_contrast$expected_melEDI_ratio -
      stage2_day_check$expected_ratio
  )) >
    1e-10 ||
    max(abs(
      activity_contrast$expected_melEDI_ratio -
        stage2_activity_check$expected_ratio
    )) >
      1e-10 ||
    any(!is.finite(contrast_source$expected_melEDI_ratio)) ||
    any(!is.finite(contrast_source$standard_error_log_ratio)) ||
    any(contrast_source$pointwise_low_ratio <= 0) ||
    any(
      contrast_source$pointwise_low_ratio >
        contrast_source$expected_melEDI_ratio
    ) ||
    any(
      contrast_source$pointwise_high_ratio <
        contrast_source$expected_melEDI_ratio
    )
) {
  h06_abort("The H06 Stage 3 temporal contrasts failed validation")
}

closure <- contrast_source |>
  dplyr::filter(clock_hour %in% c(0, 24)) |>
  dplyr::summarise(
    closure_difference = abs(diff(expected_melEDI_ratio)),
    .by = contrast_id
  )
if (max(closure$closure_difference) > 1e-10) {
  h06_abort("The H06 Stage 3 contrast curves failed cyclic closure")
}

contrast_path <- file.path(
  roots$source_data,
  "H06_exploratory_two_part_temporal_contrasts.csv"
)
write_h06_csv(contrast_source, contrast_path)

contrast_breaks <- c(0.125, 0.25, 0.5, 1, 2, 4, 8, 16)
display_range <- range(
  contrast_source$pointwise_low_ratio,
  contrast_source$pointwise_high_ratio
)
contrast_breaks <- contrast_breaks[
  contrast_breaks >= display_range[[1L]] / 1.5 &
    contrast_breaks <= display_range[[2L]] * 1.5
]
contrast_breaks <- sort(unique(c(contrast_breaks, 1)))

contrast_plot <- ggplot2::ggplot(
  contrast_source,
  ggplot2::aes(x = clock_hour, y = expected_melEDI_ratio)
) +
  ggplot2::geom_hline(
    yintercept = 1,
    colour = "#333333",
    linetype = "22",
    linewidth = 0.65
  ) +
  ggplot2::geom_ribbon(
    ggplot2::aes(
      ymin = pointwise_low_ratio,
      ymax = pointwise_high_ratio
    ),
    fill = "#56B4E9",
    alpha = 0.24
  ) +
  ggplot2::geom_line(
    colour = "#0072B2",
    linewidth = 0.82,
    lineend = "round"
  ) +
  ggplot2::facet_wrap(ggplot2::vars(contrast_label), ncol = 2) +
  ggplot2::scale_x_continuous(
    breaks = c(0, 6, 12, 18, 24),
    limits = c(0, 24),
    expand = ggplot2::expansion(mult = c(0, 0.01))
  ) +
  ggplot2::scale_y_log10(
    breaks = contrast_breaks,
    labels = scales::label_number(accuracy = 0.01),
    expand = ggplot2::expansion(mult = c(0.05, 0.08))
  ) +
  ggplot2::labs(
    x = "Local clock hour",
    y = "Expected melEDI ratio (log scale)"
  ) +
  ggplot2::theme_minimal(base_size = 10) +
  ggplot2::theme(
    panel.grid.minor = ggplot2::element_blank(),
    panel.grid.major.x = ggplot2::element_blank(),
    axis.text = ggplot2::element_text(size = 8, colour = "#333333"),
    axis.title = ggplot2::element_text(size = 9),
    strip.text = ggplot2::element_text(size = 9, face = "bold"),
    plot.margin = ggplot2::margin(4, 5, 4, 4, unit = "mm")
  )

figure_id <- "H06_exploratory_two_part_temporal_contrasts"
base_width_in <- 170 / 25.4
base_height_in <- 112 / 25.4
ggplot2::ggsave(
  file.path(roots$figures, paste0(figure_id, ".png")),
  plot = contrast_plot,
  width = base_width_in,
  height = base_height_in,
  units = "in",
  dpi = 320,
  bg = "white"
)
ggplot2::ggsave(
  file.path(roots$figures, paste0(figure_id, ".pdf")),
  plot = contrast_plot,
  width = base_width_in,
  height = base_height_in,
  units = "in",
  device = grDevices::cairo_pdf,
  bg = "white"
)
qa_preview <- file.path(
  roots$qa,
  paste0(figure_id, "_A4_preview.pdf")
)
grDevices::cairo_pdf(
  qa_preview,
  width = 210 / 25.4,
  height = 297 / 25.4,
  bg = "white"
)
grid::grid.newpage()
print(
  contrast_plot,
  vp = grid::viewport(
    width = grid::unit(170, "mm"),
    height = grid::unit(112, "mm")
  )
)
grDevices::dev.off()

qa_status <- Sys.getenv("H06_FIGURE_QA_STATUS", unset = "NOT TESTED")
if (!qa_status %in% c("NOT TESTED", "PASS")) {
  h06_abort("H06_FIGURE_QA_STATUS must be `NOT TESTED` or `PASS`")
}
inspection <- if (qa_status == "PASS") {
  paste(
    "PASS at 170 mm on A4 portrait with 20-mm side margins: no clipping,",
    "overlap, unwanted wrapping, distortion, or poor data-region balance;",
    "the null line, ratio curves, ribbons, axes, and facet labels remain clear"
  )
} else {
  paste(
    "NOT TESTED: inspect the A4 physical-size preview before classifying",
    "the temporal-contrast figure as reader ready"
  )
}
qa <- tibble::tibble(
  figure_id = figure_id,
  source_csv = h06_relative_path(contrast_path),
  a4_preview = h06_relative_path(qa_preview),
  native_width_mm = 170,
  native_height_mm = 112,
  intended_print_display_width_mm = 170,
  scale_factor = 1,
  smallest_essential_nominal_text_pt = 8,
  effective_final_text_pt = 8,
  physical_size_inspection = inspection,
  report_011_status = qa_status,
  base_width_in = base_width_in,
  base_height_in = base_height_in,
  export_scale_multiplier = 1,
  export_width_in = base_width_in,
  export_height_in = base_height_in,
  raster_dpi = 320L,
  intended_html_display_width_mm = 170,
  clipping_overlap_wrapping_distortion_balance = inspection,
  greyscale_and_redundant_encoding = paste(
    "Single blue curve per labelled facet, grey null reference, and",
    "uncertainty encoded by ribbon; interpretation does not depend on colour"
  ),
  source_values_untransformed = TRUE,
  display_scale = "ggplot2::scale_y_log10()"
)
write_h06_csv(
  qa,
  file.path(
    roots$manifests,
    "H06_stage3_temporal_contrast_figure_readability_qa.csv"
  )
)

message(
  sprintf(
    paste0(
      "H06 Stage 3 temporal contrasts built; ratio range %.3f to %.3f, ",
      "pointwise interval range %.3f to %.3f"
    ),
    min(contrast_source$expected_melEDI_ratio),
    max(contrast_source$expected_melEDI_ratio),
    min(contrast_source$pointwise_low_ratio),
    max(contrast_source$pointwise_high_ratio)
  )
)
