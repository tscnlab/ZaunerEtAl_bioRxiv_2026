#!/usr/bin/env Rscript

# Diagnostic-only H02 sensitivity: replace the cyclic equal-site time smooth
# with a default thin-plate smooth while retaining the selected sz site term,
# participant factor smooth, participant-day intercept, data, transformation,
# and boundary-aware AR(1) algorithm. This script performs no bootstrap and
# does not replace the accepted primary model.

suppressPackageStartupMessages({
  library(dplyr)
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

# Fail closed if the coordinator-approved input bundle has changed.
input_audit <- h02_validate_inputs(root)

paths <- pipeline_paths(root)
producer <- paste0(
  "scripts/hypotheses/H02/",
  "run_h02_global_time_diagnostic_sensitivity.R"
)
directories <- file.path(
  c(
    paths$models,
    paths$diagnostics,
    paths$tables,
    paths$manifests
  ),
  "H02"
)
invisible(vapply(
  directories,
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

runs <- tibble::tribble(
  ~base_run_id, ~placement, ~placement_label,
  "main__glasses__all_available", "glasses", "Near eye",
  "main__chest__all_available", "chest", "Chest"
) |>
  dplyr::mutate(
    sensitivity_run_id = paste0(
      .data$base_run_id,
      "__global_tp_diagnostic"
    )
  )

global_tp_formula <- stats::as.formula(paste(
  "response ~",
  "s(time_hour, bs = 'tp', k = 12) +",
  "s(time_hour, site, bs = 'sz', k = 12) +",
  "s(time_hour, participant, bs = 'fs', k = 10) +",
  "s(participant_day, bs = 're')"
))

model_fit_summary <- readr::read_csv(
  file.path(paths$tables, "H02", "model_fit_summary.csv"),
  show_col_types = FALSE
)

model_convergence <- function(fit) {
  if (
    is.list(fit$outer.info) &&
      !is.null(fit$outer.info$conv)
  ) {
    return(as.character(fit$outer.info$conv))
  }
  if (
    is.list(fit$mgcv.conv) &&
      !is.null(fit$mgcv.conv$fully.converged)
  ) {
    return(if (isTRUE(fit$mgcv.conv$fully.converged)) {
      "full convergence"
    } else {
      "not fully converged"
    })
  }
  "not reported"
}

residual_pair_table <- function(fit, data) {
  residual <- if (
    !is.null(fit$std.rsd) &&
      length(fit$std.rsd) == nrow(data)
  ) {
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

cluster_residual_summary <- function(
  fit,
  data,
  base_run_id,
  placement,
  model_variant
) {
  pairs <- residual_pair_table(fit, data)
  summarise_level <- function(group, level) {
    detail <- pairs |>
      dplyr::group_by(dplyr::across(dplyr::all_of(group))) |>
      dplyr::summarise(
        eligible_pairs = dplyr::n(),
        lag1_correlation = if (dplyr::n() >= 3L) {
          stats::cor(.data$residual_current, .data$residual_previous)
        } else {
          NA_real_
        },
        .groups = "drop"
      )
    tibble::tibble(
      base_run_id = base_run_id,
      placement = placement,
      model_variant = model_variant,
      cluster_level = level,
      clusters = nrow(detail),
      clusters_with_estimable_correlation = sum(
        is.finite(detail$lag1_correlation)
      ),
      eligible_pairs = sum(detail$eligible_pairs),
      median_lag1_correlation = stats::median(
        detail$lag1_correlation,
        na.rm = TRUE
      ),
      q05_lag1_correlation = unname(stats::quantile(
        detail$lag1_correlation,
        0.05,
        na.rm = TRUE
      )),
      q95_lag1_correlation = unname(stats::quantile(
        detail$lag1_correlation,
        0.95,
        na.rm = TRUE
      ))
    )
  }
  dplyr::bind_rows(
    summarise_level("participant", "participant"),
    summarise_level("participant_day", "participant_day"),
    summarise_level("sequence_id", "AR_sequence")
  )
}

residual_metrics <- function(
  fit,
  data,
  base_run_id,
  placement,
  model_variant,
  rho
) {
  response_residual <- stats::residuals(fit, type = "response")
  standardized_residual <- if (
    !is.null(fit$std.rsd) &&
      length(fit$std.rsd) == nrow(data)
  ) {
    fit$std.rsd
  } else {
    response_residual
  }
  fitted <- stats::fitted(fit)
  qq_theoretical <- stats::qnorm(stats::ppoints(length(standardized_residual)))
  qq_observed <- sort(standardized_residual)
  fit_summary <- summary(fit)
  lag1 <- h02_boundary_lag_correlation(
    standardized_residual,
    data$AR_start,
    lag = 1L
  )
  tibble::tibble(
    base_run_id = base_run_id,
    placement = placement,
    model_variant = model_variant,
    rho = rho,
    observations = nrow(data),
    response_residual_rmse = sqrt(mean(response_residual^2)),
    response_residual_mae = mean(abs(response_residual)),
    standardized_residual_rmse = sqrt(mean(standardized_residual^2)),
    standardized_residual_mae = mean(abs(standardized_residual)),
    standardized_residual_sd = stats::sd(standardized_residual),
    standardized_residual_q99_absolute = unname(stats::quantile(
      abs(standardized_residual),
      0.99
    )),
    maximum_absolute_standardized_residual = max(
      abs(standardized_residual)
    ),
    correlation_absolute_residual_fitted = stats::cor(
      abs(standardized_residual),
      fitted,
      use = "complete.obs"
    ),
    normal_qq_correlation = stats::cor(
      qq_observed,
      qq_theoretical,
      use = "complete.obs"
    ),
    boundary_aware_lag1_correlation = unname(lag1["correlation"]),
    boundary_aware_lag1_pairs = as.integer(lag1["pairs"]),
    deviance_explained = fit_summary$dev.expl,
    adjusted_r_squared = fit_summary$r.sq
  )
}

global_midnight_diagnostic <- function(
  fit,
  data,
  base_run_id,
  placement,
  model_variant,
  cyclic_expected,
  step_hours = 0.01
) {
  common_index <- which(h02_smooth_labels(fit) == "s(time_hour)")
  if (length(common_index) != 1L) {
    h02_abort("Expected one global time smooth for %s", model_variant)
  }
  endpoint_times <- c(0, step_hours, 24 - step_hours, 24)
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
  eta <- h02_term_contribution(fit, representative, common_index)
  tibble::tibble(
    base_run_id = base_run_id,
    placement = placement,
    model_variant = model_variant,
    cyclic_continuity_imposed = cyclic_expected,
    finite_difference_step_hours = step_hours,
    eta_at_00 = eta[1L],
    eta_at_24 = eta[4L],
    midnight_value_jump_eta = eta[4L] - eta[1L],
    midnight_ratio_24_to_00 = 10^(eta[4L] - eta[1L]),
    derivative_at_00_eta_per_hour = (eta[2L] - eta[1L]) / step_hours,
    derivative_at_24_eta_per_hour = (eta[4L] - eta[3L]) / step_hours,
    midnight_derivative_jump_eta_per_hour =
      (eta[4L] - eta[3L]) / step_hours -
      (eta[2L] - eta[1L]) / step_hours
  )
}

model_tables <- list()
metric_tables <- list()
acf_tables <- list()
cluster_tables <- list()
midnight_tables <- list()
runtime_tables <- list()
input_tables <- list()

for (i in seq_len(nrow(runs))) {
  run <- runs[i, ]
  message(
    "Fitting non-cyclic global-time diagnostic ",
    i,
    "/",
    nrow(runs),
    ": ",
    run$placement_label
  )
  frame_path <- file.path(
    paths$model_data,
    "H02",
    paste0(run$base_run_id, ".rds")
  )
  primary_model_path <- file.path(
    paths$models,
    "H02",
    paste0(run$base_run_id, "__selected_model.rds")
  )
  if (!file.exists(frame_path) || !file.exists(primary_model_path)) {
    h02_abort("Missing model frame or accepted model for %s", run$base_run_id)
  }
  frame <- readRDS(frame_path)
  data <- h02_prepare_fit_data(frame)
  primary <- readRDS(primary_model_path)
  if (stats::nobs(primary) != nrow(data)) {
    h02_abort("Accepted model/frame row mismatch for %s", run$base_run_id)
  }
  primary_row <- model_fit_summary |>
    dplyr::filter(
      .data$run_id == run$base_run_id,
      .data$model_id == "site_pattern"
    )
  if (nrow(primary_row) != 1L) {
    h02_abort("Expected one accepted model-summary row for %s", run$base_run_id)
  }
  primary_rho <- primary_row$rho[[1L]]

  preliminary_time <- system.time({
    preliminary <- h02_fit_bam(
      global_tp_formula,
      data,
      method = "fREML",
      rho = 0
    )
  })
  alternative_rho <- h02_estimate_rho(preliminary, data)
  final_time <- system.time({
    alternative <- h02_fit_bam(
      global_tp_formula,
      data,
      method = "fREML",
      rho = alternative_rho
    )
  })
  if (stats::nobs(alternative) != nrow(data)) {
    h02_abort("Alternative model/frame row mismatch for %s", run$base_run_id)
  }

  primary_model_row <- h02_model_row(
    primary,
    "cyclic_global_primary",
    run$base_run_id,
    primary_rho
  )
  alternative_model_row <- h02_model_row(
    alternative,
    "noncyclic_global_tp_diagnostic",
    run$base_run_id,
    alternative_rho
  )
  model_tables[[run$base_run_id]] <- dplyr::bind_rows(
    primary_model_row,
    alternative_model_row
  ) |>
    dplyr::mutate(
      placement = run$placement,
      formula = c(
        paste(deparse(stats::formula(primary)), collapse = " "),
        paste(deparse(global_tp_formula), collapse = " ")
      ),
      global_basis = c("cc", "tp"),
      diagnostic_role = c(
        "accepted primary reference",
        "residual-diagnostic sensitivity only"
      ),
      .after = "run_id"
    )

  metric_tables[[run$base_run_id]] <- dplyr::bind_rows(
    residual_metrics(
      primary,
      data,
      run$base_run_id,
      run$placement,
      "cyclic_global_primary",
      primary_rho
    ),
    residual_metrics(
      alternative,
      data,
      run$base_run_id,
      run$placement,
      "noncyclic_global_tp_diagnostic",
      alternative_rho
    )
  )
  acf_tables[[run$base_run_id]] <- dplyr::bind_rows(
    h02_residual_acf(
      primary,
      data,
      "cyclic_global_primary",
      run$base_run_id
    ),
    h02_residual_acf(
      alternative,
      data,
      "noncyclic_global_tp_diagnostic",
      run$base_run_id
    )
  ) |>
    dplyr::rename(model_variant = "stage") |>
    dplyr::mutate(placement = run$placement, .after = "run_id")
  cluster_tables[[run$base_run_id]] <- dplyr::bind_rows(
    cluster_residual_summary(
      primary,
      data,
      run$base_run_id,
      run$placement,
      "cyclic_global_primary"
    ),
    cluster_residual_summary(
      alternative,
      data,
      run$base_run_id,
      run$placement,
      "noncyclic_global_tp_diagnostic"
    )
  )
  midnight_tables[[run$base_run_id]] <- dplyr::bind_rows(
    global_midnight_diagnostic(
      primary,
      data,
      run$base_run_id,
      run$placement,
      "cyclic_global_primary",
      TRUE
    ),
    global_midnight_diagnostic(
      alternative,
      data,
      run$base_run_id,
      run$placement,
      "noncyclic_global_tp_diagnostic",
      FALSE
    )
  )
  runtime_tables[[run$base_run_id]] <- tibble::tibble(
    base_run_id = run$base_run_id,
    placement = run$placement,
    sensitivity_run_id = run$sensitivity_run_id,
    preliminary_elapsed_seconds = unname(preliminary_time["elapsed"]),
    final_elapsed_seconds = unname(final_time["elapsed"]),
    total_fit_elapsed_seconds =
      unname(preliminary_time["elapsed"] + final_time["elapsed"]),
    bootstrap_replicates = 0L,
    inferential_role = "diagnostic-only model-form sensitivity"
  )
  input_tables[[run$base_run_id]] <- tibble::tibble(
    base_run_id = run$base_run_id,
    input_role = c("H02 model frame", "accepted selected model"),
    path = normalizePath(
      c(frame_path, primary_model_path),
      winslash = "/",
      mustWork = TRUE
    ),
    sha256 = vapply(
      c(frame_path, primary_model_path),
      artifact_sha256,
      character(1)
    ),
    bytes = unname(file.info(c(frame_path, primary_model_path))$size)
  )

  alternative_model_path <- file.path(
    paths$models,
    "H02",
    paste0(run$sensitivity_run_id, "__model.rds")
  )
  write_h02_rds(
    alternative,
    alternative_model_path,
    paste0(run$sensitivity_run_id, "__model"),
    metadata = list(
      base_run_id = run$base_run_id,
      placement = run$placement,
      global_basis = "tp",
      analytical_role = "residual-diagnostic sensitivity only",
      rho = alternative_rho,
      participants = dplyr::n_distinct(data$participant),
      participant_days = dplyr::n_distinct(data$participant_day),
      observations = nrow(data),
      sites = dplyr::n_distinct(data$site)
    )
  )
  rm(frame, data, primary, preliminary, alternative)
  invisible(gc())
}

model_comparison <- dplyr::bind_rows(model_tables)
residual_metric_table <- dplyr::bind_rows(metric_tables)
residual_acf_table <- dplyr::bind_rows(acf_tables)
cluster_table <- dplyr::bind_rows(cluster_tables)
midnight_table <- dplyr::bind_rows(midnight_tables)
runtime_table <- dplyr::bind_rows(runtime_tables)
verified_inputs <- dplyr::bind_rows(input_tables)

tables <- list(
  global_time_basis_model_comparison = list(
    data = model_comparison,
    path = file.path(
      paths$tables,
      "H02",
      "global_time_basis_model_comparison.csv"
    )
  ),
  global_time_basis_residual_metrics = list(
    data = residual_metric_table,
    path = file.path(
      paths$diagnostics,
      "H02",
      "global_time_basis_residual_metrics.csv"
    )
  ),
  global_time_basis_residual_acf = list(
    data = residual_acf_table,
    path = file.path(
      paths$diagnostics,
      "H02",
      "global_time_basis_residual_acf.csv"
    )
  ),
  global_time_basis_cluster_residual_acf = list(
    data = cluster_table,
    path = file.path(
      paths$diagnostics,
      "H02",
      "global_time_basis_cluster_residual_acf.csv"
    )
  ),
  global_time_basis_midnight_continuity = list(
    data = midnight_table,
    path = file.path(
      paths$diagnostics,
      "H02",
      "global_time_basis_midnight_continuity.csv"
    )
  ),
  global_time_basis_runtime = list(
    data = runtime_table,
    path = file.path(
      paths$diagnostics,
      "H02",
      "global_time_basis_runtime.csv"
    )
  ),
  global_time_basis_verified_inputs = list(
    data = verified_inputs,
    path = file.path(
      paths$manifests,
      "H02",
      "global_time_basis_verified_inputs.csv"
    )
  )
)
for (id in names(tables)) {
  write_h02_csv(tables[[id]]$data, tables[[id]]$path, id)
}

manifest <- dplyr::bind_rows(lapply(names(artifact_metadata), function(id) {
  tibble::as_tibble(artifact_metadata[[id]]) |>
    dplyr::mutate(artifact_id = id, .before = 1L)
})) |>
  dplyr::mutate(
    analysis_role = "diagnostic-only non-cyclic global-time sensitivity",
    bootstrap_replicates = 0L
  )
manifest_path <- file.path(
  paths$manifests,
  "H02",
  "H02_global_time_basis_diagnostic_manifest.csv"
)
invisible(write_csv_artifact(manifest, manifest_path, producer))

message(
  "Completed non-cyclic global-time residual sensitivity for ",
  nrow(runs),
  " placements; no bootstrap was run"
)
