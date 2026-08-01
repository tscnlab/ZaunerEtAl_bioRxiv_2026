#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(dplyr)
  library(gratia)
  library(mgcv)
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

if (getRversion() != "4.6.1") {
  h02_abort("H02 requires R 4.6.1; running %s", getRversion())
}

# Fail closed if the coordinator-approved shared bundle changes after fitting.
input_audit <- h02_validate_inputs(root)

paths <- pipeline_paths(root)
producer <- "scripts/hypotheses/H02/run_h02_temporal_diagnostics.R"
diagnostic_directory <- file.path(paths$diagnostics, "H02")
manifest_directory <- file.path(paths$manifests, "H02")
dir.create(diagnostic_directory, recursive = TRUE, showWarnings = FALSE)
dir.create(manifest_directory, recursive = TRUE, showWarnings = FALSE)

artifact_metadata <- list()
write_h02_csv <- function(data, path, id) {
  artifact_metadata[[id]] <<- write_csv_artifact(data, path, producer)
  invisible(artifact_metadata[[id]])
}

find_exact_smooth <- function(fit, label) {
  index <- which(h02_smooth_labels(fit) == label)
  if (length(index) != 1L) {
    h02_abort("Expected exactly one smooth labelled '%s'", label)
  }
  index
}

component_endpoint_rows <- function(
  values,
  group,
  component,
  run_id,
  cyclic_expected,
  step_hours
) {
  value_at <- function(time) values[match(time, values$time_hour), "eta"][[1L]]
  value_0 <- value_at(0)
  value_step <- value_at(step_hours)
  value_before_24 <- value_at(24 - step_hours)
  value_24 <- value_at(24)
  derivative_0 <- (value_step - value_0) / step_hours
  derivative_24 <- (value_24 - value_before_24) / step_hours
  tibble::tibble(
    run_id = run_id,
    component = component,
    group = group,
    cyclic_continuity_imposed = cyclic_expected,
    finite_difference_step_hours = step_hours,
    eta_at_00 = value_0,
    eta_at_24 = value_24,
    midnight_value_jump_eta = value_24 - value_0,
    midnight_ratio_24_to_00 = 10^(value_24 - value_0),
    derivative_at_00_eta_per_hour = derivative_0,
    derivative_at_24_eta_per_hour = derivative_24,
    midnight_derivative_jump_eta_per_hour = derivative_24 - derivative_0
  )
}

endpoint_diagnostics <- function(fit, data, run_id, step_hours = 0.01) {
  endpoint_times <- c(0, step_hours, 24 - step_hours, 24)
  common_index <- find_exact_smooth(fit, "s(time_hour)")
  site_index <- find_exact_smooth(fit, "s(time_hour,site)")
  participant_index <- find_exact_smooth(
    fit,
    "s(time_hour,participant)"
  )

  representative <- tibble::tibble(
    time_hour = endpoint_times,
    site = factor(levels(data$site)[1L], levels = levels(data$site)),
    site_smooth = ordered(
      levels(data$site)[1L],
      levels = levels(data$site)
    ),
    participant = factor(
      levels(data$participant)[1L],
      levels = levels(data$participant)
    ),
    participant_day = factor(
      levels(data$participant_day)[1L],
      levels = levels(data$participant_day)
    )
  )
  representative$eta <- h02_term_contribution(
    fit,
    representative,
    common_index
  )
  common <- component_endpoint_rows(
    representative[, c("time_hour", "eta")],
    "equal-site common curve",
    "common_time_curve",
    run_id,
    TRUE,
    step_hours
  )

  site_grid <- tidyr::crossing(
    site = factor(levels(data$site), levels = levels(data$site)),
    time_hour = endpoint_times
  ) |>
    dplyr::mutate(
      site_smooth = ordered(
        as.character(.data$site),
        levels = levels(data$site)
      ),
      participant = factor(
        levels(data$participant)[1L],
        levels = levels(data$participant)
      ),
      participant_day = factor(
        levels(data$participant_day)[1L],
        levels = levels(data$participant_day)
      )
    )
  site_grid$site_eta <- h02_term_contribution(fit, site_grid, site_index)
  site_grid$common_eta <- h02_term_contribution(
    fit,
    site_grid,
    common_index
  )
  site_deviation <- site_grid |>
    dplyr::transmute(
      group = as.character(.data$site),
      time_hour = .data$time_hour,
      eta = .data$site_eta
    ) |>
    dplyr::group_split(.data$group) |>
    lapply(function(x) {
      component_endpoint_rows(
        x[, c("time_hour", "eta")],
        x$group[[1L]],
        "site_deviation_curve",
        run_id,
        FALSE,
        step_hours
      )
    }) |>
    dplyr::bind_rows()
  full_site <- site_grid |>
    dplyr::transmute(
      group = as.character(.data$site),
      time_hour = .data$time_hour,
      eta = .data$site_eta + .data$common_eta
    ) |>
    dplyr::group_split(.data$group) |>
    lapply(function(x) {
      component_endpoint_rows(
        x[, c("time_hour", "eta")],
        x$group[[1L]],
        "full_site_curve",
        run_id,
        FALSE,
        step_hours
      )
    }) |>
    dplyr::bind_rows()

  participant_info <- data |>
    dplyr::distinct(.data$site, .data$participant)
  participant_grid <- tidyr::crossing(
    participant_info,
    time_hour = endpoint_times
  ) |>
    dplyr::mutate(
      site_smooth = ordered(
        as.character(.data$site),
        levels = levels(data$site)
      ),
      participant_day = factor(
        levels(data$participant_day)[1L],
        levels = levels(data$participant_day)
      )
    )
  participant_grid$eta <- h02_term_contribution(
    fit,
    participant_grid,
    participant_index
  )
  participant <- participant_grid |>
    dplyr::transmute(
      group = as.character(.data$participant),
      time_hour = .data$time_hour,
      eta = .data$eta
    ) |>
    dplyr::group_split(.data$group) |>
    lapply(function(x) {
      component_endpoint_rows(
        x[, c("time_hour", "eta")],
        x$group[[1L]],
        "participant_deviation_curve",
        run_id,
        FALSE,
        step_hours
      )
    }) |>
    dplyr::bind_rows()

  dplyr::bind_rows(common, site_deviation, full_site, participant)
}

site_constraint_diagnostic <- function(fit, data, run_id) {
  site_index <- find_exact_smooth(fit, "s(time_hour,site)")
  grid <- tidyr::crossing(
    site = factor(levels(data$site), levels = levels(data$site)),
    time_hour = (seq.int(0L, 1410L, by = 30L) + 15) / 60
  ) |>
    dplyr::mutate(
      site_smooth = ordered(
        as.character(.data$site),
        levels = levels(data$site)
      ),
      participant = factor(
        levels(data$participant)[1L],
        levels = levels(data$participant)
      ),
      participant_day = factor(
        levels(data$participant_day)[1L],
        levels = levels(data$participant_day)
      )
    )
  grid$site_deviation_eta <- h02_term_contribution(fit, grid, site_index)
  sums <- grid |>
    dplyr::group_by(.data$time_hour) |>
    dplyr::summarise(
      sum_site_deviation_eta = sum(.data$site_deviation_eta),
      .groups = "drop"
    )
  tolerance <- 1e-8
  maximum_absolute_sum <- max(abs(sums$sum_site_deviation_eta))
  tibble::tibble(
    run_id = run_id,
    sites = dplyr::n_distinct(data$site),
    clock_bins = nrow(sums),
    maximum_absolute_sum_site_deviation_eta = maximum_absolute_sum,
    root_mean_square_sum_site_deviation_eta = sqrt(mean(
      sums$sum_site_deviation_eta^2
    )),
    numerical_tolerance = tolerance,
    sum_to_zero_constraint_verified = maximum_absolute_sum <= tolerance,
    coefficient_rank = fit$rank,
    coefficients = length(stats::coef(fit)),
    full_coefficient_rank = fit$rank == length(stats::coef(fit)),
    diagnostic_definition = paste(
      "sum of fitted sz site-deviation contributions across all factor",
      "levels at each of the 48 equal-clock bins"
    )
  )
}

fitted_term_dependence <- function(fit, data, run_id) {
  terms <- mgcv::predict.gam(
    fit,
    newdata = as.data.frame(data),
    type = "terms",
    block.size = 1000L,
    newdata.guaranteed = TRUE
  )
  terms <- as.matrix(terms)
  labels <- colnames(terms)
  if (ncol(terms) < 2L) {
    h02_abort("Fitted-term dependence requires at least two model terms")
  }
  pairwise <- utils::combn(
    seq_len(ncol(terms)),
    2L,
    simplify = FALSE
  ) |>
    lapply(function(index) {
      tibble::tibble(
        run_id = run_id,
        diagnostic = "pairwise_fitted_term_correlation",
        target_term = labels[index[1L]],
        comparison_terms = labels[index[2L]],
        estimate = stats::cor(
          terms[, index[1L]],
          terms[, index[2L]],
          use = "complete.obs"
        ),
        observations = nrow(terms)
      )
    }) |>
    dplyr::bind_rows()
  multiple <- dplyr::bind_rows(lapply(seq_len(ncol(terms)), function(i) {
    target <- terms[, i]
    others <- terms[, -i, drop = FALSE]
    fitted <- stats::lm.fit(cbind(intercept = 1, others), target)$fitted.values
    denominator <- sum((target - mean(target))^2)
    r_squared <- if (denominator > 0) {
      1 - sum((target - fitted)^2) / denominator
    } else {
      NA_real_
    }
    tibble::tibble(
      run_id = run_id,
      diagnostic = "fitted_term_multiple_R2_proxy",
      target_term = labels[i],
      comparison_terms = paste(labels[-i], collapse = " + "),
      estimate = r_squared,
      observations = nrow(terms)
    )
  }))
  dplyr::bind_rows(pairwise, multiple) |>
    dplyr::mutate(
      interpretation = paste(
        "empirical dependence among fitted term contributions on the exact",
        "model rows; this is not mgcv's design-matrix worst-case",
        "concurvity statistic"
      )
    )
}

formal_concurvity <- function(fit, run_id) {
  started <- Sys.time()
  result <- gratia::model_concurvity(
    fit,
    type = "all",
    pairwise = FALSE
  )
  tibble::as_tibble(result) |>
    dplyr::mutate(
      run_id = run_id,
      method = paste(
        "gratia::model_concurvity() wrapper around",
        "mgcv::concurvity(full = TRUE)"
      ),
      elapsed_seconds = as.numeric(
        difftime(Sys.time(), started, units = "secs")
      ),
      .before = 1L
    )
}

residual_pair_table <- function(fit, data, run_id) {
  residual <- if (!is.null(fit$std.rsd) && length(fit$std.rsd) == nrow(data)) {
    fit$std.rsd
  } else {
    stats::residuals(fit, type = "response")
  }
  sequence_id <- cumsum(data$AR_start)
  index <- seq_along(residual)
  previous <- index - 1L
  eligible <- previous >= 1L
  eligible[eligible] <- sequence_id[index[eligible]] ==
    sequence_id[previous[eligible]]
  current_index <- index[eligible]
  previous_index <- previous[eligible]
  tibble::tibble(
    run_id = run_id,
    participant = as.character(data$participant[current_index]),
    participant_day = as.character(data$participant_day[current_index]),
    sequence_id = sequence_id[current_index],
    residual_current = residual[current_index],
    residual_previous = residual[previous_index]
  ) |>
    dplyr::filter(
      is.finite(.data$residual_current),
      is.finite(.data$residual_previous)
    )
}

cluster_residual_acf <- function(fit, data, run_id) {
  pairs <- residual_pair_table(fit, data, run_id)
  bind_cluster <- function(group, level) {
    pairs |>
      dplyr::group_by(across(all_of(group))) |>
      dplyr::summarise(
        eligible_pairs = dplyr::n(),
        lag1_correlation = if (dplyr::n() >= 3L) {
          stats::cor(.data$residual_current, .data$residual_previous)
        } else {
          NA_real_
        },
        .groups = "drop"
      ) |>
      dplyr::transmute(
        run_id = run_id,
        cluster_level = level,
        cluster_id = as.character(.data[[group]]),
        eligible_pairs = .data$eligible_pairs,
        lag1_correlation = .data$lag1_correlation
      )
  }
  dplyr::bind_rows(
    bind_cluster("participant", "participant"),
    bind_cluster("participant_day", "participant_day"),
    bind_cluster("sequence_id", "AR_sequence")
  )
}

summarise_cluster_residual_acf <- function(detail) {
  detail |>
    dplyr::group_by(.data$run_id, .data$cluster_level) |>
    dplyr::summarise(
      clusters = dplyr::n(),
      clusters_with_estimable_correlation = sum(
        is.finite(.data$lag1_correlation)
      ),
      eligible_pairs = sum(.data$eligible_pairs),
      median_lag1_correlation = stats::median(
        .data$lag1_correlation,
        na.rm = TRUE
      ),
      q05_lag1_correlation = unname(stats::quantile(
        .data$lag1_correlation,
        0.05,
        na.rm = TRUE
      )),
      q25_lag1_correlation = unname(stats::quantile(
        .data$lag1_correlation,
        0.25,
        na.rm = TRUE
      )),
      q75_lag1_correlation = unname(stats::quantile(
        .data$lag1_correlation,
        0.75,
        na.rm = TRUE
      )),
      q95_lag1_correlation = unname(stats::quantile(
        .data$lag1_correlation,
        0.95,
        na.rm = TRUE
      )),
      .groups = "drop"
    ) |>
    dplyr::mutate(
      stage = "final_AR1_standardized",
      pair_definition = paste(
        "lag-1 30-minute pairs within verified AR sequences only; no pair",
        "crosses participant-day or a declared discontinuity"
      ),
      .after = "run_id"
    )
}

diagnostic_runs <- tibble::tribble(
  ~run_id,
  ~placement,
  "main__glasses__all_available",
  "glasses",
  "main__chest__all_available",
  "chest"
)

endpoint_tables <- list()
constraint_tables <- list()
dependence_tables <- list()
concurvity_tables <- list()
cluster_tables <- list()

for (i in seq_len(nrow(diagnostic_runs))) {
  run_id <- diagnostic_runs$run_id[[i]]
  message("Computing extended H02 temporal diagnostics: ", run_id)
  model_path <- file.path(
    paths$models,
    "H02",
    paste0(run_id, "__selected_model.rds")
  )
  frame_path <- file.path(paths$model_data, "H02", paste0(run_id, ".rds"))
  if (!file.exists(model_path) || !file.exists(frame_path)) {
    h02_abort("Missing selected model or model frame for %s", run_id)
  }
  fit <- readRDS(model_path)
  data <- h02_prepare_fit_data(readRDS(frame_path))
  if (stats::nobs(fit) != nrow(data)) {
    h02_abort("Model/frame row mismatch for %s", run_id)
  }
  endpoint_tables[[run_id]] <- endpoint_diagnostics(fit, data, run_id)
  constraint_tables[[run_id]] <- site_constraint_diagnostic(
    fit,
    data,
    run_id
  )
  dependence_tables[[run_id]] <- fitted_term_dependence(fit, data, run_id)
  cluster_tables[[run_id]] <- cluster_residual_acf(fit, data, run_id)
  message("  computing formal full-model concurvity via gratia/mgcv")
  concurvity_tables[[run_id]] <- formal_concurvity(fit, run_id)
  rm(fit, data)
  invisible(gc())
}

endpoint_table <- dplyr::bind_rows(endpoint_tables)
constraint_table <- dplyr::bind_rows(constraint_tables)
dependence_table <- dplyr::bind_rows(dependence_tables)
concurvity_table <- dplyr::bind_rows(concurvity_tables)
cluster_detail <- dplyr::bind_rows(cluster_tables)
cluster_summary <- summarise_cluster_residual_acf(cluster_detail)

tables <- list(
  midnight_continuity = endpoint_table,
  sz_constraint_identifiability = constraint_table,
  formal_concurvity = concurvity_table,
  fitted_term_dependence = dependence_table,
  cluster_residual_acf_detail = cluster_detail,
  cluster_residual_acf_summary = cluster_summary
)
table_paths <- file.path(
  diagnostic_directory,
  paste0(names(tables), ".csv")
)
names(table_paths) <- names(tables)
for (name in names(tables)) {
  write_h02_csv(
    tables[[name]],
    table_paths[[name]],
    paste0("diagnostic__", name)
  )
}

manifest <- dplyr::bind_rows(lapply(artifact_metadata, manifest_row)) |>
  dplyr::mutate(
    path = sub(
      paste0(
        "^",
        gsub("([][{}()+*^$|\\\\?.])", "\\\\\\1", root),
        "/"
      ),
      "",
      .data$path
    )
  )
write_csv_artifact(
  manifest,
  file.path(
    manifest_directory,
    "H02_temporal_diagnostics_manifest.csv"
  ),
  producer
)

message("Completed extended H02 temporal diagnostics")
