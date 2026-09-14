# Fit and audit the approved exploratory two-part H06 time-of-day GAMM.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)

source(file.path(root, "scripts/pipeline/paths_io.R"))
source(file.path(root, "scripts/hypotheses/H06/h06_contract.R"))
source(file.path(root, "scripts/hypotheses/H06/h06_modeling.R"))

options(lifecycle_verbosity = "quiet", warn = 1)

if (!identical(as.character(getRversion()), "4.6.1")) {
  h06_abort(
    "The H06 exploratory two-part GAMM requires R 4.6.1; found %s",
    as.character(getRversion())
  )
}

required_packages <- c(
  "dplyr",
  "tidyr",
  "tibble",
  "readr",
  "digest",
  "openssl",
  "mgcv",
  "gratia"
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
    "The H06 exploratory two-part GAMM is missing project package(s): %s",
    paste(missing_packages, collapse = ", ")
  )
}

producer <-
  "scripts/hypotheses/H06/run_h06_exploratory_time_of_day_two_part.R"
paths <- pipeline_paths(root)
roots <- list(
  model_data = file.path(paths$model_data, "H06"),
  models = file.path(paths$models, "H06"),
  diagnostics = file.path(paths$diagnostics, "H06"),
  source_data = file.path(paths$source_data, "H06")
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

write_h06_rds <- function(object, path) {
  write_rds_artifact(object, path, producer = producer)
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

frame_path <- file.path(
  roots$model_data,
  "main__glasses__all_available__frame.rds"
)
if (!file.exists(frame_path)) {
  h06_abort("Missing approved H06 primary frame: %s", frame_path)
}
frame <- readRDS(frame_path)
if (
  nrow(frame) != 16596L ||
    sum(frame$response_value == 0) != 4697L ||
    any(frame$response_value < 0) ||
    anyDuplicated(frame$.model_row_id)
) {
  h06_abort("The approved H06 primary frame no longer matches the GAMM gate")
}

factor_columns <- c(
  "site",
  "work_free_day",
  "activity_status",
  "participant_key",
  "participant_day_key",
  "hour_sequence_id"
)
ordered <- frame |>
  dplyr::arrange(hour_sequence_id, hour_sequence_position) |>
  dplyr::mutate(
    dplyr::across(dplyr::all_of(factor_columns), droplevels),
    day_activity_group = h06_day_activity_group(
      work_free_day,
      activity_status
    ),
    melEDI_positive = as.integer(response_value > 0),
    analysis_sequence_id = droplevels(hour_sequence_id),
    analysis_sequence_position = hour_sequence_position,
    analysis_AR_start = AR_start
  )

positive <- ordered |>
  dplyr::filter(response_value > 0) |>
  dplyr::group_by(hour_sequence_id) |>
  dplyr::mutate(
    positive_run_start = dplyr::row_number() == 1L |
      hour_sequence_position -
        dplyr::lag(
          hour_sequence_position,
          default = dplyr::first(hour_sequence_position) - 2L
        ) !=
        1L,
    positive_run = cumsum(positive_run_start)
  ) |>
  dplyr::ungroup() |>
  dplyr::mutate(
    analysis_sequence_id = factor(paste(
      as.character(hour_sequence_id),
      positive_run,
      sep = "::positive_run::"
    ))
  ) |>
  dplyr::group_by(analysis_sequence_id) |>
  dplyr::mutate(
    analysis_sequence_position = dplyr::row_number(),
    analysis_AR_start = dplyr::row_number() == 1L
  ) |>
  dplyr::ungroup() |>
  dplyr::mutate(
    dplyr::across(
      dplyr::all_of(c(
        "site",
        "work_free_day",
        "activity_status",
        "participant_key",
        "participant_day_key",
        "analysis_sequence_id",
        "day_activity_group"
      )),
      droplevels
    )
  )

if (
  nrow(positive) != 11899L ||
    any(positive$response_value <= 0) ||
    sum(positive$analysis_AR_start) !=
      dplyr::n_distinct(positive$analysis_sequence_id)
) {
  h06_abort("The positive-melEDI analysis sequences failed validation")
}

component_data <- list(
  occurrence = ordered,
  positive_magnitude = positive
)
component_families <- list(
  occurrence = stats::binomial(link = "logit"),
  positive_magnitude = stats::Gamma(link = "log")
)
component_family_labels <- c(
  occurrence = "Binomial occurrence with logit link",
  positive_magnitude = "Gamma positive magnitude with log link"
)
knots <- list(clock_hour = c(0, 24))

lag_pairs <- function(data, residual) {
  tibble::tibble(
    sequence = data$analysis_sequence_id,
    position = data$analysis_sequence_position,
    residual = as.numeric(residual)
  ) |>
    dplyr::arrange(sequence, position) |>
    dplyr::group_by(sequence) |>
    dplyr::mutate(previous = dplyr::lag(residual)) |>
    dplyr::ungroup() |>
    dplyr::filter(is.finite(residual), is.finite(previous))
}

fit_component <- function(component, k, seed) {
  data <- component_data[[component]]
  family <- component_families[[component]]
  formula <- h06_exploratory_two_part_gamm_formulas(k = k)[[component]]
  environment(formula) <- environment()
  initial <- h06_capture_fit(mgcv::bam(
    formula = formula,
    data = data,
    family = family,
    method = "fREML",
    discrete = TRUE,
    knots = knots,
    nthreads = 1L,
    gc.level = 1L
  ))
  if (is.null(initial$model)) {
    h06_abort(
      "The initial %s two-part GAMM failed: %s",
      component,
      initial$error
    )
  }
  initial_residual <- stats::residuals(initial$model, type = "deviance")
  pairs <- lag_pairs(data, initial_residual)
  rho <- if (nrow(pairs) >= 3L) {
    suppressWarnings(stats::cor(pairs$residual, pairs$previous))
  } else {
    0
  }
  rho <- max(min(rho, 0.95), -0.95)
  ar_start <- data$analysis_AR_start
  set.seed(seed)
  final <- h06_capture_fit(mgcv::bam(
    formula = formula,
    data = data,
    family = family,
    method = "fREML",
    discrete = TRUE,
    knots = knots,
    rho = rho,
    AR.start = ar_start,
    nthreads = 1L,
    gc.level = 1L
  ))
  if (is.null(final$model)) {
    h06_abort(
      "The AR-aware %s two-part GAMM failed: %s",
      component,
      final$error
    )
  }
  list(
    component = component,
    k = as.integer(k),
    formula = formula,
    model = final$model,
    rho = rho,
    initial_residual_pairs = nrow(pairs),
    initial_elapsed_seconds = initial$elapsed_seconds,
    final_elapsed_seconds = final$elapsed_seconds,
    initial_warnings = initial$warnings,
    final_warnings = final$warnings
  )
}

fixed_smooth_rank <- function(component, k) {
  formula <- h06_exploratory_two_part_fixed_smooth_formulas(k = k)[[component]]
  environment(formula) <- environment()
  prefit <- mgcv::gam(
    formula = formula,
    data = component_data[[component]],
    family = component_families[[component]],
    knots = knots,
    fit = FALSE
  )
  tibble::tibble(
    component = component,
    basis_k = as.integer(k),
    fixed_smooth_columns = ncol(prefit$X),
    fixed_smooth_rank = qr(prefit$X)$rank,
    full_fixed_smooth_rank = qr(prefit$X)$rank == ncol(prefit$X)
  )
}

model_output_path <- file.path(
  roots$models,
  "H06_exploratory_time_of_day_two_part.rds"
)
cached_bundle <- if (file.exists(model_output_path)) {
  tryCatch(readRDS(model_output_path), error = function(error) NULL)
} else {
  NULL
}
two_part_contract_version <- paste0(
  "v3_two_part_cyclic_factor_by_group_equal_site_",
  "k16_selected_discrete_working_ar"
)
valid_fit_set <- function(fits, k) {
  !is.null(fits) &&
    identical(sort(names(fits)), c("occurrence", "positive_magnitude")) &&
    all(vapply(
      fits,
      function(fit) identical(fit$k, as.integer(k)) && !is.null(fit$model),
      logical(1)
    ))
}
valid_cached_bundle <-
  !is.null(cached_bundle) &&
  identical(cached_bundle$contract_version, two_part_contract_version) &&
  valid_fit_set(cached_bundle$base_fits, 16L) &&
  valid_fit_set(cached_bundle$lower_basis_sensitivity, 12L)
base_fits <- if (valid_cached_bundle) {
  cached_bundle$lower_basis_sensitivity
} else {
  list(
    occurrence = fit_component("occurrence", k = 12L, seed = 6201L),
    positive_magnitude = fit_component(
      "positive_magnitude",
      k = 12L,
      seed = 6202L
    )
  )
}
message("H06 two-part lower-basis k = 12 fits available")
k_sensitivity_fits <- if (valid_cached_bundle) {
  cached_bundle$base_fits
} else {
  list(
    occurrence = fit_component("occurrence", k = 16L, seed = 6211L),
    positive_magnitude = fit_component(
      "positive_magnitude",
      k = 16L,
      seed = 6212L
    )
  )
}
message("H06 two-part selected k = 16 fits complete")

prediction_grid <- tidyr::expand_grid(
  clock_hour = seq(0, 24, by = 0.25),
  work_free_day = factor(
    levels(ordered$work_free_day),
    levels = levels(ordered$work_free_day)
  ),
  activity_status = factor(
    levels(ordered$activity_status),
    levels = levels(ordered$activity_status)
  )
) |>
  dplyr::mutate(
    day_activity_group = h06_day_activity_group(
      work_free_day,
      activity_status
    ),
    previous_sleep_duration_centered_h = 0,
    prediction_row_id = dplyr::row_number()
  )

site_levels <- levels(ordered$site)
standardization_grid <- prediction_grid[
  rep(seq_len(nrow(prediction_grid)), each = length(site_levels)),
  ,
  drop = FALSE
]
standardization_grid$site <- factor(
  rep(site_levels, times = nrow(prediction_grid)),
  levels = site_levels
)

day_type_prediction_grid <- tidyr::expand_grid(
  clock_hour = seq(0, 24, by = 0.25),
  work_free_day = factor(
    levels(ordered$work_free_day),
    levels = levels(ordered$work_free_day)
  )
) |>
  dplyr::mutate(
    previous_sleep_duration_centered_h = 0,
    prediction_row_id = dplyr::row_number()
  )
day_type_standardization_grid <- tidyr::expand_grid(
  day_type_prediction_grid,
  activity_status = factor(
    levels(ordered$activity_status),
    levels = levels(ordered$activity_status)
  ),
  site = factor(site_levels, levels = site_levels)
) |>
  dplyr::mutate(
    day_activity_group = h06_day_activity_group(
      work_free_day,
      activity_status
    )
  )

activity_prediction_grid <- tidyr::expand_grid(
  clock_hour = seq(0, 24, by = 0.25),
  activity_status = factor(
    levels(ordered$activity_status),
    levels = levels(ordered$activity_status)
  )
) |>
  dplyr::mutate(
    previous_sleep_duration_centered_h = 0,
    prediction_row_id = dplyr::row_number()
  )
activity_standardization_grid <- tidyr::expand_grid(
  activity_prediction_grid,
  work_free_day = factor(
    levels(ordered$work_free_day),
    levels = levels(ordered$work_free_day)
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

standardize_component <- function(fit, target_grid, newdata_grid) {
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
  response_derivative <- if (fit$component == "occurrence") {
    response * (1 - response)
  } else {
    response
  }
  response_mean <- numeric(nrow(target_grid))
  response_gradient <- matrix(
    0,
    nrow = nrow(target_grid),
    ncol = ncol(lpmatrix)
  )
  for (row_id in seq_len(nrow(target_grid))) {
    index <- which(newdata$prediction_row_id == row_id)
    response_mean[[row_id]] <- mean(response[index])
    response_gradient[row_id, ] <- colMeans(
      lpmatrix[index, , drop = FALSE] * response_derivative[index]
    )
  }
  transformed_mean <- if (fit$component == "occurrence") {
    stats::qlogis(response_mean)
  } else {
    log(response_mean)
  }
  transformed_gradient <- response_gradient /
    if (fit$component == "occurrence") {
      response_mean * (1 - response_mean)
    } else {
      response_mean
    }
  transformed_standard_error <- gradient_standard_error(
    transformed_gradient,
    fit$model$Vp
  )
  critical_value <- stats::qnorm(0.975)
  response_low <- if (fit$component == "occurrence") {
    stats::plogis(
      transformed_mean - critical_value * transformed_standard_error
    )
  } else {
    exp(transformed_mean - critical_value * transformed_standard_error)
  }
  response_high <- if (fit$component == "occurrence") {
    stats::plogis(
      transformed_mean + critical_value * transformed_standard_error
    )
  } else {
    exp(transformed_mean + critical_value * transformed_standard_error)
  }
  list(
    fit = fit,
    newdata = newdata,
    lpmatrix = lpmatrix,
    response = response,
    response_mean = response_mean,
    response_gradient = response_gradient,
    transformed_mean = transformed_mean,
    transformed_standard_error = transformed_standard_error,
    response_low = response_low,
    response_high = response_high
  )
}

combine_standardized_predictions <- function(
  occurrence_fit,
  magnitude_fit,
  target_grid,
  newdata_grid,
  standardization_description
) {
  occurrence <- standardize_component(
    occurrence_fit,
    target_grid,
    newdata_grid
  )
  magnitude <- standardize_component(
    magnitude_fit,
    target_grid,
    newdata_grid
  )
  if (
    !identical(
      occurrence$newdata$prediction_row_id,
      magnitude$newdata$prediction_row_id
    ) ||
      !identical(occurrence$newdata$site, magnitude$newdata$site)
  ) {
    h06_abort("The occurrence and magnitude standardization grids differ")
  }
  site_expected <- occurrence$response * magnitude$response
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
    expected_mean[[row_id]] <- mean(site_expected[index])
    occurrence_gradient[row_id, ] <- colMeans(
      occurrence$lpmatrix[index, , drop = FALSE] *
        magnitude$response[index] *
        occurrence$response[index] *
        (1 - occurrence$response[index])
    )
    magnitude_gradient[row_id, ] <- colMeans(
      magnitude$lpmatrix[index, , drop = FALSE] * site_expected[index]
    )
  }
  occurrence_expected_standard_error <- gradient_standard_error(
    occurrence_gradient,
    occurrence_fit$model$Vp
  )
  magnitude_expected_standard_error <- gradient_standard_error(
    magnitude_gradient,
    magnitude_fit$model$Vp
  )
  expected_log_standard_error <- sqrt(
    occurrence_expected_standard_error^2 +
      magnitude_expected_standard_error^2
  ) /
    expected_mean
  critical_value <- stats::qnorm(0.975)
  target_grid |>
    dplyr::select(-prediction_row_id) |>
    dplyr::mutate(
      basis_k = occurrence_fit$k,
      occurrence_link = occurrence$transformed_mean,
      occurrence_standard_error_link = occurrence$transformed_standard_error,
      positive_probability = occurrence$response_mean,
      positive_probability_low = occurrence$response_low,
      positive_probability_high = occurrence$response_high,
      positive_magnitude_link = magnitude$transformed_mean,
      positive_magnitude_standard_error_link = magnitude$transformed_standard_error,
      conditional_positive_mean_melEDI_lx = magnitude$response_mean,
      conditional_positive_mean_low_melEDI_lx = magnitude$response_low,
      conditional_positive_mean_high_melEDI_lx = magnitude$response_high,
      expected_melEDI_lx = expected_mean,
      expected_log_standard_error = expected_log_standard_error,
      expected_low_melEDI_lx = exp(
        log(expected_mean) - critical_value * expected_log_standard_error
      ),
      expected_high_melEDI_lx = exp(
        log(expected_mean) + critical_value * expected_log_standard_error
      ),
      product_of_standardized_components_melEDI_lx = positive_probability *
        conditional_positive_mean_melEDI_lx,
      sites_standardized = length(site_levels),
      standardization = standardization_description,
      population_prediction = paste(
        "Participant and participant-day random-effect smooths are excluded"
      )
    )
}

lower_basis_predictions <- combine_standardized_predictions(
  base_fits$occurrence,
  base_fits$positive_magnitude,
  target_grid = prediction_grid,
  newdata_grid = standardization_grid,
  standardization_description = paste(
    "Response-scale predictions give equal weight to each submitted site",
    "within every work/free-day by activity-status combination"
  )
)
selected_predictions <- combine_standardized_predictions(
  k_sensitivity_fits$occurrence,
  k_sensitivity_fits$positive_magnitude,
  target_grid = prediction_grid,
  newdata_grid = standardization_grid,
  standardization_description = paste(
    "Response-scale predictions give equal weight to each submitted site",
    "within every work/free-day by activity-status combination"
  )
)
selected_day_type_predictions <- combine_standardized_predictions(
  k_sensitivity_fits$occurrence,
  k_sensitivity_fits$positive_magnitude,
  target_grid = day_type_prediction_grid,
  newdata_grid = day_type_standardization_grid,
  standardization_description = paste(
    "Response-scale predictions give equal weight to sedentary and active",
    "status and to each of the nine submitted sites"
  )
)
selected_activity_predictions <- combine_standardized_predictions(
  k_sensitivity_fits$occurrence,
  k_sensitivity_fits$positive_magnitude,
  target_grid = activity_prediction_grid,
  newdata_grid = activity_standardization_grid,
  standardization_description = paste(
    "Response-scale predictions give equal weight to work and free days and",
    "to each of the nine submitted sites"
  )
)

support <- ordered |>
  dplyr::mutate(clock_hour_bin = floor(clock_hour) %% 24L) |>
  dplyr::summarise(
    observations = dplyr::n(),
    positive_observations = sum(response_value > 0),
    zero_observations = sum(response_value == 0),
    zero_fraction = mean(response_value == 0),
    participants = dplyr::n_distinct(participant_key),
    participant_days = dplyr::n_distinct(participant_day_key),
    .by = c(site, work_free_day, activity_status, clock_hour_bin)
  ) |>
  dplyr::arrange(site, work_free_day, activity_status, clock_hour_bin)

display_support <- ordered |>
  dplyr::mutate(clock_hour_bin = floor(clock_hour) %% 24L) |>
  dplyr::summarise(
    observations = dplyr::n(),
    positive_observations = sum(response_value > 0),
    zero_observations = sum(response_value == 0),
    zero_fraction = mean(response_value == 0),
    participants = dplyr::n_distinct(participant_key),
    participant_days = dplyr::n_distinct(participant_day_key),
    sites_with_support = dplyr::n_distinct(site),
    .by = c(work_free_day, activity_status, clock_hour_bin)
  ) |>
  dplyr::arrange(work_free_day, activity_status, clock_hour_bin)

day_type_support <- ordered |>
  dplyr::mutate(clock_hour_bin = floor(clock_hour) %% 24L) |>
  dplyr::summarise(
    observations = dplyr::n(),
    positive_observations = sum(response_value > 0),
    zero_observations = sum(response_value == 0),
    zero_fraction = mean(response_value == 0),
    participants = dplyr::n_distinct(participant_key),
    participant_days = dplyr::n_distinct(participant_day_key),
    sites_with_support = dplyr::n_distinct(site),
    .by = c(work_free_day, clock_hour_bin)
  ) |>
  dplyr::arrange(work_free_day, clock_hour_bin)

activity_support <- ordered |>
  dplyr::mutate(clock_hour_bin = floor(clock_hour) %% 24L) |>
  dplyr::summarise(
    observations = dplyr::n(),
    positive_observations = sum(response_value > 0),
    zero_observations = sum(response_value == 0),
    zero_fraction = mean(response_value == 0),
    participants = dplyr::n_distinct(participant_key),
    participant_days = dplyr::n_distinct(participant_day_key),
    sites_with_support = dplyr::n_distinct(site),
    .by = c(activity_status, clock_hour_bin)
  ) |>
  dplyr::arrange(activity_status, clock_hour_bin)

attach_prediction_support <- function(predictions, support, join_by) {
  predictions |>
    dplyr::mutate(clock_hour_bin = floor(clock_hour) %% 24L) |>
    dplyr::left_join(
      support,
      by = join_by,
      relationship = "many-to-one"
    ) |>
    dplyr::mutate(
      sparse_fewer_than_5_participants = participants < 5L,
      sparse_fewer_than_10_participants = participants < 10L,
      interval_scope = paste(
        "Approximate pointwise 95% interval; smoothing parameters treated as",
        "fixed and occurrence-magnitude cross-component covariance set to zero;",
        "not simultaneous"
      ),
      inferential_role = paste(
        "exploratory_time_of_day_context_not_primary_inference;",
        "standardized population prediction excluding random-effect smooths"
      )
    )
}

selected_predictions <- attach_prediction_support(
  selected_predictions,
  display_support,
  c("work_free_day", "activity_status", "clock_hour_bin")
)
selected_day_type_predictions <- attach_prediction_support(
  selected_day_type_predictions,
  day_type_support,
  c("work_free_day", "clock_hour_bin")
)
selected_activity_predictions <- attach_prediction_support(
  selected_activity_predictions,
  activity_support,
  c("activity_status", "clock_hour_bin")
)

closure_diagnostics <- function(predictions, label) {
  predictions |>
    dplyr::filter(clock_hour %in% c(0, 24)) |>
    dplyr::arrange(work_free_day, activity_status, clock_hour) |>
    dplyr::summarise(
      occurrence_probability_closure_difference = abs(diff(
        positive_probability
      )),
      positive_mean_closure_difference = abs(diff(
        conditional_positive_mean_melEDI_lx
      )),
      expected_mean_closure_difference = abs(diff(expected_melEDI_lx)),
      .by = c(work_free_day, activity_status)
    ) |>
    tidyr::pivot_longer(
      dplyr::ends_with("_closure_difference"),
      names_to = "quantity",
      values_to = "absolute_closure_difference"
    ) |>
    dplyr::summarise(
      maximum_absolute_closure_difference = max(
        absolute_closure_difference,
        na.rm = TRUE
      ),
      median_absolute_closure_difference = stats::median(
        absolute_closure_difference,
        na.rm = TRUE
      ),
      .by = quantity
    ) |>
    dplyr::mutate(model_set = label, .before = 1L)
}

fit_summary <- function(fit, rank_row) {
  model_summary <- summary(fit$model)
  tibble::tibble(
    component = fit$component,
    component_question = if (fit$component == "occurrence") {
      "Probability that hourly melEDI is greater than zero"
    } else {
      "Conditional mean hourly melEDI among positive hours"
    },
    response_family = component_family_labels[[fit$component]],
    formula = paste(deparse(fit$formula), collapse = " "),
    observations = stats::nobs(fit$model),
    participants = dplyr::n_distinct(
      component_data[[fit$component]]$participant_key
    ),
    participant_days = dplyr::n_distinct(
      component_data[[fit$component]]$participant_day_key
    ),
    analysis_sequences = dplyr::n_distinct(
      component_data[[fit$component]]$analysis_sequence_id
    ),
    positive_run_sequences_split_after_zero_exclusion = fit$component ==
      "positive_magnitude",
    basis_k = fit$k,
    selected_for_exploratory_display = fit$k == 16L,
    method = "fREML",
    discrete = TRUE,
    working_ar_rho = fit$rho,
    initial_residual_pairs = fit$initial_residual_pairs,
    converged = isTRUE(fit$model$converged),
    adjusted_r_squared = model_summary$r.sq,
    deviance_explained = model_summary$dev.expl,
    scale_parameter = model_summary$scale,
    fREML_score = unname(fit$model$gcv.ubre),
    fixed_smooth_columns = rank_row$fixed_smooth_columns,
    fixed_smooth_rank = rank_row$fixed_smooth_rank,
    full_fixed_smooth_rank = rank_row$full_fixed_smooth_rank,
    initial_elapsed_seconds = fit$initial_elapsed_seconds,
    final_elapsed_seconds = fit$final_elapsed_seconds,
    initial_warnings = paste(fit$initial_warnings, collapse = " | "),
    final_warnings = paste(fit$final_warnings, collapse = " | "),
    working_ar_interpretation = paste(
      "Non-Gaussian bam rho is a working-residual GEE approximation, not a",
      "fully generative joint AR likelihood"
    ),
    inferential_role = "exploratory_time_of_day_context_not_primary_inference"
  )
}

rank_rows <- dplyr::bind_rows(
  fixed_smooth_rank("occurrence", 12L),
  fixed_smooth_rank("positive_magnitude", 12L),
  fixed_smooth_rank("occurrence", 16L),
  fixed_smooth_rank("positive_magnitude", 16L)
)
fit_summaries <- dplyr::bind_rows(lapply(
  c(base_fits, k_sensitivity_fits),
  function(fit) {
    rank_row <- rank_rows |>
      dplyr::filter(component == fit$component, basis_k == fit$k)
    fit_summary(fit, rank_row)
  }
))

smooth_tables <- dplyr::bind_rows(lapply(
  c(base_fits, k_sensitivity_fits),
  function(fit) {
    table <- as.data.frame(summary(fit$model)$s.table)
    tibble::as_tibble(table, rownames = "smooth") |>
      dplyr::mutate(
        component = fit$component,
        basis_k = fit$k,
        .before = 1L
      )
  }
))

parametric_tables <- dplyr::bind_rows(lapply(
  c(base_fits, k_sensitivity_fits),
  function(fit) {
    table <- as.data.frame(summary(fit$model)$p.table)
    tibble::as_tibble(table, rownames = "term") |>
      dplyr::mutate(
        component = fit$component,
        basis_k = fit$k,
        .before = 1L
      )
  }
))

k_check_tables <- dplyr::bind_rows(lapply(
  c(base_fits, k_sensitivity_fits),
  function(fit) {
    check <- tryCatch(mgcv::k.check(fit$model), error = function(error) NULL)
    if (is.null(check)) {
      return(tibble::tibble())
    }
    tibble::as_tibble(as.data.frame(check), rownames = "smooth") |>
      dplyr::mutate(
        component = fit$component,
        basis_k = fit$k,
        .before = 1L
      )
  }
))

concurvity_tables <- dplyr::bind_rows(lapply(
  c(base_fits, k_sensitivity_fits),
  function(fit) {
    gratia::model_concurvity(fit$model) |>
      tibble::as_tibble() |>
      dplyr::mutate(
        component = fit$component,
        basis_k = fit$k,
        .before = 1L
      )
  }
))

variance_tables <- dplyr::bind_rows(lapply(
  c(base_fits, k_sensitivity_fits),
  function(fit) {
    variance <- NULL
    invisible(utils::capture.output(
      variance <- mgcv::gam.vcomp(fit$model)
    ))
    variance_table <- if (is.list(variance) && !is.null(variance$vc)) {
      as.data.frame(variance$vc)
    } else if (is.atomic(variance) && length(variance) > 0L) {
      data.frame(std.dev = as.numeric(variance), row.names = names(variance))
    } else {
      data.frame()
    }
    if (nrow(variance_table) == 0L) {
      return(tibble::tibble())
    }
    tibble::as_tibble(variance_table, rownames = "component_term") |>
      dplyr::mutate(
        component = fit$component,
        basis_k = fit$k,
        .before = 1L
      )
  }
))
message("H06 two-part smooth, basis, concurvity, and variance audits complete")

residual_series <- function(fit) {
  data <- component_data[[fit$component]]
  raw <- as.numeric(stats::residuals(fit$model, type = "deviance"))
  standardized <- if (
    !is.null(fit$model$std.rsd) &&
      length(fit$model$std.rsd) == nrow(data)
  ) {
    as.numeric(fit$model$std.rsd)
  } else {
    rep(NA_real_, nrow(data))
  }
  dplyr::bind_rows(
    tibble::tibble(
      sequence = data$analysis_sequence_id,
      position = data$analysis_sequence_position,
      residual = raw,
      residual_type = "deviance"
    ),
    tibble::tibble(
      sequence = data$analysis_sequence_id,
      position = data$analysis_sequence_position,
      residual = standardized,
      residual_type = "AR_standardized"
    )
  ) |>
    dplyr::arrange(residual_type, sequence, position) |>
    dplyr::summarise(
      observations = dplyr::n(),
      lag1 = if (dplyr::n() >= 3L) {
        suppressWarnings(stats::cor(
          residual[-1L],
          residual[-dplyr::n()]
        ))
      } else {
        NA_real_
      },
      .by = c(residual_type, sequence)
    ) |>
    dplyr::filter(is.finite(lag1)) |>
    dplyr::mutate(
      component = fit$component,
      basis_k = fit$k,
      .before = 1L
    )
}

residual_series_table <- dplyr::bind_rows(lapply(
  c(base_fits, k_sensitivity_fits),
  residual_series
))
residual_summary <- residual_series_table |>
  dplyr::summarise(
    sequences_with_lag1 = dplyr::n(),
    median_sequence_lag1 = stats::median(lag1),
    first_quartile_sequence_lag1 = stats::quantile(lag1, 0.25),
    third_quartile_sequence_lag1 = stats::quantile(lag1, 0.75),
    minimum_sequence_lag1 = min(lag1),
    maximum_sequence_lag1 = max(lag1),
    .by = c(component, basis_k, residual_type)
  )

prediction_keys <- c(
  "clock_hour",
  "work_free_day",
  "activity_status",
  "day_activity_group",
  "previous_sleep_duration_centered_h",
  "sites_standardized"
)
k_sensitivity <- lower_basis_predictions |>
  dplyr::select(
    dplyr::all_of(prediction_keys),
    base_positive_probability = positive_probability,
    base_conditional_positive_mean = conditional_positive_mean_melEDI_lx,
    base_expected_mean = expected_melEDI_lx
  ) |>
  dplyr::inner_join(
    selected_predictions |>
      dplyr::select(
        dplyr::all_of(prediction_keys),
        sensitivity_positive_probability = positive_probability,
        sensitivity_conditional_positive_mean = conditional_positive_mean_melEDI_lx,
        sensitivity_expected_mean = expected_melEDI_lx
      ),
    by = prediction_keys,
    relationship = "one-to-one"
  ) |>
  tidyr::pivot_longer(
    -dplyr::all_of(prediction_keys),
    names_to = c("model_set", "quantity"),
    names_pattern = "(base|sensitivity)_(.*)",
    values_to = "value"
  ) |>
  tidyr::pivot_wider(names_from = model_set, values_from = value) |>
  dplyr::mutate(
    absolute_difference = abs(sensitivity - base),
    relative_difference = absolute_difference / pmax(abs(base), 1e-8)
  ) |>
  dplyr::summarise(
    lower_basis_k = 12L,
    selected_k = 16L,
    median_absolute_difference = stats::median(absolute_difference),
    percentile_95_absolute_difference = stats::quantile(
      absolute_difference,
      0.95
    ),
    maximum_absolute_difference = max(absolute_difference),
    median_relative_difference = stats::median(relative_difference),
    percentile_95_relative_difference = stats::quantile(
      relative_difference,
      0.95
    ),
    .by = quantity
  )

formula_registry <- dplyr::bind_rows(lapply(
  c("occurrence", "positive_magnitude"),
  function(component) {
    tibble::tibble(
      component = component,
      response_family = component_family_labels[[component]],
      selected_formula = paste(
        deparse(h06_exploratory_two_part_gamm_formulas(16L)[[component]]),
        collapse = " "
      ),
      lower_basis_sensitivity_formula = paste(
        deparse(h06_exploratory_two_part_gamm_formulas(12L)[[component]]),
        collapse = " "
      ),
      duplicated_parametric_site_day_activity_terms = FALSE,
      cyclic_factor_by_group_smooths = TRUE,
      shared_smoothing_parameter_across_four_group_curves = TRUE,
      sum_to_zero_smooths = FALSE,
      site_specific_clock_smooth = FALSE,
      site_adjustment = paste(
        "Parametric fixed site; response-scale predictions standardized with",
        "equal weight across the nine submitted sites"
      ),
      method = "fREML",
      discrete = TRUE,
      selected_basis_k = 16L,
      lower_basis_sensitivity_k = 12L,
      inferential_role = "exploratory_time_of_day_context_not_primary_inference"
    )
  }
))

package_versions <- tibble::tibble(
  package = c("R", required_packages),
  version = c(
    as.character(getRversion()),
    vapply(
      required_packages,
      function(package) as.character(utils::packageVersion(package)),
      character(1)
    )
  )
)

model_bundle <- list(
  contract_version = two_part_contract_version,
  frame_path = h06_relative_path(frame_path),
  frame_sha256 = artifact_sha256(frame_path),
  model_frame_sha256 = h06_model_frame_hash(ordered),
  response_definition = list(
    occurrence = "response_value > 0",
    positive_magnitude = "response_value conditional on response_value > 0",
    combined = paste(
      "Within each submitted site, Pr(response_value > 0) multiplied by the",
      "conditional positive mean; those site-specific expected means are",
      "then averaged with equal site weight"
    )
  ),
  base_fits = k_sensitivity_fits,
  lower_basis_sensitivity = base_fits,
  package_versions = package_versions
)

write_h06_rds(
  model_bundle,
  file.path(roots$models, "H06_exploratory_time_of_day_two_part.rds")
)
write_h06_csv(
  formula_registry,
  file.path(roots$model_data, "H06_exploratory_two_part_formula_registry.csv")
)
write_h06_csv(
  support,
  file.path(roots$model_data, "H06_exploratory_two_part_support.csv")
)
write_h06_csv(
  package_versions,
  file.path(roots$model_data, "H06_exploratory_two_part_package_versions.csv")
)
write_h06_csv(
  fit_summaries,
  file.path(roots$diagnostics, "H06_exploratory_two_part_fit_summary.csv")
)
write_h06_csv(
  smooth_tables,
  file.path(roots$diagnostics, "H06_exploratory_two_part_smooths.csv")
)
write_h06_csv(
  parametric_tables,
  file.path(roots$diagnostics, "H06_exploratory_two_part_parametric.csv")
)
write_h06_csv(
  k_check_tables,
  file.path(roots$diagnostics, "H06_exploratory_two_part_k_check.csv")
)
write_h06_csv(
  concurvity_tables,
  file.path(roots$diagnostics, "H06_exploratory_two_part_concurvity.csv")
)
write_h06_csv(
  variance_tables,
  file.path(
    roots$diagnostics,
    "H06_exploratory_two_part_variance_components.csv"
  )
)
write_h06_csv(
  residual_series_table,
  file.path(
    roots$diagnostics,
    "H06_exploratory_two_part_per_sequence_residual_lag.csv"
  )
)
write_h06_csv(
  residual_summary,
  file.path(roots$diagnostics, "H06_exploratory_two_part_residual_summary.csv")
)
write_h06_csv(
  dplyr::bind_rows(
    closure_diagnostics(lower_basis_predictions, "lower_basis_k12"),
    closure_diagnostics(selected_predictions, "selected_k16")
  ),
  file.path(roots$diagnostics, "H06_exploratory_two_part_cyclic_closure.csv")
)
write_h06_csv(
  k_sensitivity,
  file.path(roots$diagnostics, "H06_exploratory_two_part_k_sensitivity.csv")
)
write_h06_csv(
  selected_predictions,
  file.path(roots$source_data, "H06_exploratory_two_part_predictions.csv")
)
write_h06_csv(
  selected_day_type_predictions,
  file.path(
    roots$source_data,
    "H06_exploratory_two_part_day_type_predictions.csv"
  )
)
write_h06_csv(
  selected_activity_predictions,
  file.path(
    roots$source_data,
    "H06_exploratory_two_part_activity_predictions.csv"
  )
)

message("H06 exploratory two-part time-of-day GAMM complete")
