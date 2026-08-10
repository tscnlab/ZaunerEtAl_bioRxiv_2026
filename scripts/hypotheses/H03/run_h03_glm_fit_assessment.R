# Bounded descriptive R-squared and Gaussian-fit assessment for H03.

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

if (!identical(as.character(getRversion()), "4.6.1")) {
  h03_abort(
    "H03 GLM fit assessment requires R 4.6.1; found %s",
    as.character(getRversion())
  )
}
required_packages <- c(
  "dplyr", "tidyr", "tibble", "readr", "statmod", "openssl"
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

producer <- "scripts/hypotheses/H03/run_h03_glm_fit_assessment.R"
model_path <- file.path(
  root,
  "artifacts/07_models/H03/H03_additive_model_objects.rds"
)
if (!file.exists(model_path)) {
  h03_abort("Run H03 Stage 2 primary models before the GLM fit assessment")
}
objects <- readRDS(model_path)
bundles <- list(
  near_eye = objects$main_near_eye,
  chest = objects$main_chest
)
placements <- c(near_eye = "Near-eye", chest = "Chest")
working_power <- h03_specification()$working_tweedie_power

model_registry <- tibble::tribble(
  ~model_id, ~model_label, ~analysis_scale, ~family_label,
  ~exact_formula, ~outcome_target,
  "quasi_tweedie_log", "Quasi-Tweedie, log link", "melEDI (lx)",
  "quasi-Tweedie; p = 1.539919; log link",
  "geo_medi_1h ~ site + light_source",
  "conditional arithmetic mean of hourly melEDI",
  "gaussian_identity_raw", "Gaussian, identity link", "melEDI (lx)",
  "Gaussian; identity link",
  "geo_medi_1h ~ site + light_source",
  "conditional arithmetic mean of hourly melEDI",
  "gaussian_log10_response", "Gaussian on log10(melEDI + 0.1)",
  "log10(melEDI + 0.1 lx)", "Gaussian; identity link after log10 transform",
  "log10(geo_medi_1h + 0.1) ~ site + light_source",
  "conditional mean on log10 scale; direct inverse is geometric-scale target"
)

h03_candidate_response <- function(data, model_id) {
  if (identical(model_id, "gaussian_log10_response")) {
    log10(data$geo_medi_1h + 0.1)
  } else {
    data$geo_medi_1h
  }
}

h03_candidate_family <- function(model_id) {
  if (identical(model_id, "quasi_tweedie_log")) {
    statmod::tweedie(var.power = working_power, link.power = 0)
  } else {
    stats::gaussian(link = "identity")
  }
}

h03_fit_candidate <- function(data, model_id, terms) {
  fit_data <- data
  fit_data$h03_candidate_outcome <- h03_candidate_response(data, model_id)
  formula <- stats::reformulate(terms, response = "h03_candidate_outcome")
  warnings <- character()
  fit <- withCallingHandlers(
    stats::glm(
      formula = formula,
      data = fit_data,
      family = h03_candidate_family(model_id),
      control = stats::glm.control(epsilon = 1e-10, maxit = 100L),
      model = TRUE,
      x = TRUE,
      y = TRUE
    ),
    warning = function(condition) {
      warnings <<- c(warnings, conditionMessage(condition))
      invokeRestart("muffleWarning")
    }
  )
  list(fit = fit, warnings = unique(warnings), formula = formula)
}

h03_predict_candidate <- function(fit, newdata, model_id) {
  prediction_data <- newdata
  for (variable in intersect(names(fit$xlevels), names(prediction_data))) {
    # Prediction must inherit the training-fit contrasts. Reconstructing the
    # factor removes custom frame-level contrast attributes that predict.glm
    # would otherwise discard with a harmless warning.
    prediction_data[[variable]] <- factor(
      as.character(prediction_data[[variable]]),
      levels = fit$xlevels[[variable]]
    )
  }
  prediction <- as.numeric(stats::predict(
    fit,
    newdata = prediction_data,
    type = "response"
  ))
  if (identical(model_id, "gaussian_log10_response")) {
    10^prediction - 0.1
  } else {
    prediction
  }
}

h03_weights <- function(data, weighting) {
  if (identical(weighting, "participant_balanced")) {
    counts <- table(data$participant)
    weight <- 1 / as.numeric(counts[as.character(data$participant)])
  } else {
    weight <- rep(1, nrow(data))
  }
  weight / sum(weight)
}

h03_sse_components <- function(response, prediction, weight) {
  center <- sum(weight * response)
  sse <- sum(weight * (response - prediction)^2)
  sst <- sum(weight * (response - center)^2)
  list(sse = sse, sst = sst, r_squared = 1 - sse / sst)
}

h03_add_observed_cell_factor <- function(data) {
  cell_levels <- data |>
    dplyr::distinct(.data$site, .data$light_source) |>
    dplyr::arrange(.data$site, .data$light_source) |>
    dplyr::transmute(
      cell = paste(
        as.character(.data$site),
        as.character(.data$light_source),
        sep = "__"
      )
    ) |>
    dplyr::pull(.data$cell)
  data$site_source_cell <- factor(
    paste(
      as.character(data$site),
      as.character(data$light_source),
      sep = "__"
    ),
    levels = cell_levels
  )
  data
}

h03_r2_row <- function(
  data,
  model_id,
  placement,
  weighting,
  loss_basis = c("squared_error", "model_deviance")
) {
  loss_basis <- match.arg(loss_basis)
  full_architecture <- if (identical(placement, "Chest")) {
    "full_observed_cell"
  } else {
    "full_literal"
  }
  if (identical(full_architecture, "full_observed_cell")) {
    data <- h03_add_observed_cell_factor(data)
  }
  full_terms <- if (identical(full_architecture, "full_observed_cell")) {
    "0 + site_source_cell"
  } else {
    "site * light_source"
  }
  term_sets <- list(
    intercept = character(),
    site = "site",
    category = "light_source",
    additive = c("site", "light_source"),
    full = full_terms
  )
  fitted <- lapply(term_sets, function(terms) {
    h03_fit_candidate(data, model_id, terms)
  })
  if (loss_basis == "model_deviance") {
    losses <- vapply(fitted, function(item) item$fit$deviance, numeric(1))
    scale_label <- if (identical(model_id, "quasi_tweedie_log")) {
      "working quasi-Tweedie deviance"
    } else {
      "Gaussian deviance on model response scale"
    }
  } else {
    response <- h03_candidate_response(data, model_id)
    weight <- h03_weights(data, weighting)
    losses <- vapply(fitted, function(item) {
      # Stored factor contrasts that are irrelevant to a reduced formula can
      # trigger a harmless "contrasts dropped" warning during prediction.
      prediction <- as.numeric(suppressWarnings(stats::predict(
        item$fit,
        type = "response"
      )))
      sum(weight * (response - prediction)^2)
    }, numeric(1))
    scale_label <- paste(
      if (identical(weighting, "participant_balanced")) {
        "participant-balanced"
      } else {
        "participant-hour-weighted"
      },
      "squared error on model response scale"
    )
  }
  overall <- 1 - losses[["full"]] / losses[["intercept"]]
  site_partial <- 1 - losses[["additive"]] / losses[["category"]]
  category_partial <- 1 - losses[["additive"]] / losses[["site"]]
  interaction_partial <- 1 - losses[["full"]] / losses[["additive"]]
  site_shapley <- 0.5 * (
    (losses[["intercept"]] - losses[["site"]]) +
      (losses[["category"]] - losses[["additive"]])
  ) / losses[["intercept"]]
  category_shapley <- 0.5 * (
    (losses[["intercept"]] - losses[["category"]]) +
      (losses[["site"]] - losses[["additive"]])
  ) / losses[["intercept"]]
  interaction_r_squared <- (
    losses[["additive"]] - losses[["full"]]
  ) / losses[["intercept"]]
  registry <- dplyr::filter(model_registry, .data$model_id == .env$model_id)
  tibble::tibble(
    placement = placement,
    model_id = model_id,
    model_label = registry$model_label,
    heterogeneity_architecture = full_architecture,
    analysis_scale = registry$analysis_scale,
    loss_basis = loss_basis,
    weighting = if (loss_basis == "model_deviance") {
      "model-defined observation weighting"
    } else {
      weighting
    },
    scale_label = scale_label,
    overall_r_squared = overall,
    site_partial_r_squared_conditional_on_category = site_partial,
    category_partial_r_squared_conditional_on_site = category_partial,
    interaction_partial_r_squared_conditional_on_additive =
      interaction_partial,
    site_shapley_r_squared = site_shapley,
    category_shapley_r_squared = category_shapley,
    interaction_r_squared = interaction_r_squared,
    site_shapley_share_percent = if (overall == 0) {
      NA_real_
    } else {
      100 * site_shapley / overall
    },
    category_shapley_share_percent = if (overall == 0) {
      NA_real_
    } else {
      100 * category_shapley / overall
    },
    interaction_share_percent = if (overall == 0) {
      NA_real_
    } else {
      100 * interaction_r_squared / overall
    },
    intercept_loss = losses[["intercept"]],
    site_only_loss = losses[["site"]],
    category_only_loss = losses[["category"]],
    additive_loss = losses[["additive"]],
    full_heterogeneity_loss = losses[["full"]],
    full_loss = losses[["full"]],
    r_squared_formula = if (identical(model_id, "gaussian_log10_response")) {
      paste0(
        "log10(geo_medi_1h + 0.1) ~ ",
        full_terms
      )
    } else {
      paste0("geo_medi_1h ~ ", full_terms)
    },
    allocation_definition = paste(
      "hierarchy-respecting allocation: site and category main effects",
      "are averaged over both entry orders; the interaction enters only",
      "after both main effects"
    ),
    full_converged = fitted$full$fit$converged,
    full_rank = fitted$full$fit$rank,
    full_coefficients = length(stats::coef(fitted$full$fit)),
    warning_count = sum(vapply(fitted, function(x) length(x$warnings), integer(1))),
    inferential_role = paste(
      "descriptive in-sample point estimate; no cluster-bootstrap interval;",
      "not a quasi-likelihood effect test"
    )
  )
}

r_squared_rows <- list()
for (id in names(bundles)) {
  data <- bundles[[id]]$data
  placement <- placements[[id]]
  for (model_id in model_registry$model_id) {
    for (weighting in c("participant_hour_weighted", "participant_balanced")) {
      key <- paste(id, model_id, weighting, sep = "__")
      r_squared_rows[[key]] <- h03_r2_row(
        data,
        model_id,
        placement,
        weighting,
        loss_basis = "squared_error"
      )
    }
    key <- paste(id, model_id, "deviance", sep = "__")
    r_squared_rows[[key]] <- h03_r2_row(
      data,
      model_id,
      placement,
      weighting = "participant_hour_weighted",
      loss_basis = "model_deviance"
    )
  }
}
r_squared <- dplyr::bind_rows(r_squared_rows)

h03_fold_assignments <- function(data, folds = 5L) {
  participants <- data |>
    dplyr::distinct(.data$site, .data$participant) |>
    dplyr::group_by(.data$site) |>
    dplyr::arrange(as.character(.data$participant), .by_group = TRUE) |>
    dplyr::mutate(fold = (dplyr::row_number() - 1L) %% folds + 1L) |>
    dplyr::ungroup()
  dplyr::left_join(
    data,
    participants,
    by = c("site", "participant"),
    relationship = "many-to-one"
  )
}

h03_fold_metrics <- function(data, model_id, placement, fold) {
  training <- dplyr::filter(data, .data$fold != .env$fold)
  testing <- dplyr::filter(data, .data$fold == .env$fold)
  fitted <- h03_fit_candidate(
    training,
    model_id,
    c("site", "light_source")
  )
  prediction <- h03_predict_candidate(fitted$fit, testing, model_id)
  observed <- testing$geo_medi_1h
  clipped_prediction <- pmax(prediction, 0)
  hour_weight <- h03_weights(testing, "participant_hour_weighted")
  participant_weight <- h03_weights(testing, "participant_balanced")
  hour_sse <- h03_sse_components(observed, prediction, hour_weight)
  participant_sse <- h03_sse_components(
    observed,
    prediction,
    participant_weight
  )
  observed_log <- log10(observed + 0.1)
  predicted_log <- log10(clipped_prediction + 0.1)
  registry <- dplyr::filter(model_registry, .data$model_id == .env$model_id)
  tibble::tibble(
    placement = placement,
    model_id = model_id,
    model_label = registry$model_label,
    fold = fold,
    training_participants = dplyr::n_distinct(training$participant),
    test_participants = dplyr::n_distinct(testing$participant),
    test_observations = nrow(testing),
    converged = fitted$fit$converged,
    rank = fitted$fit$rank,
    coefficients = length(stats::coef(fitted$fit)),
    warning_count = length(fitted$warnings),
    negative_prediction_fraction = mean(prediction < 0),
    observed_mean_lx = sum(hour_weight * observed),
    predicted_mean_lx = sum(hour_weight * prediction),
    raw_rmse_lx = sqrt(hour_sse$sse),
    raw_mae_lx = sum(hour_weight * abs(observed - prediction)),
    raw_efron_r_squared = hour_sse$r_squared,
    participant_balanced_rmse_lx = sqrt(participant_sse$sse),
    participant_balanced_mae_lx = sum(
      participant_weight * abs(observed - prediction)
    ),
    participant_balanced_efron_r_squared = participant_sse$r_squared,
    log10_rmse = sqrt(sum(hour_weight * (observed_log - predicted_log)^2)),
    log10_mae = sum(hour_weight * abs(observed_log - predicted_log))
  )
}

fold_rows <- list()
for (id in names(bundles)) {
  data <- h03_fold_assignments(bundles[[id]]$data, folds = 5L)
  for (model_id in model_registry$model_id) {
    for (fold in 1:5) {
      key <- paste(id, model_id, fold, sep = "__")
      fold_rows[[key]] <- h03_fold_metrics(
        data,
        model_id,
        placements[[id]],
        fold
      )
    }
  }
}
fold_metrics <- dplyr::bind_rows(fold_rows)
cross_validation <- fold_metrics |>
  dplyr::group_by(.data$placement, .data$model_id, .data$model_label) |>
  dplyr::summarise(
    folds = dplyr::n(),
    all_converged = all(.data$converged),
    all_full_rank = all(.data$rank == .data$coefficients),
    warning_count = sum(.data$warning_count),
    negative_prediction_fraction = stats::weighted.mean(
      .data$negative_prediction_fraction,
      .data$test_observations
    ),
    observed_mean_lx = stats::weighted.mean(
      .data$observed_mean_lx,
      .data$test_observations
    ),
    predicted_mean_lx = stats::weighted.mean(
      .data$predicted_mean_lx,
      .data$test_observations
    ),
    raw_rmse_lx = sqrt(stats::weighted.mean(
      .data$raw_rmse_lx^2,
      .data$test_observations
    )),
    raw_mae_lx = stats::weighted.mean(
      .data$raw_mae_lx,
      .data$test_observations
    ),
    raw_efron_r_squared_fold_weighted = stats::weighted.mean(
      .data$raw_efron_r_squared,
      .data$test_observations
    ),
    participant_balanced_rmse_lx = sqrt(mean(
      .data$participant_balanced_rmse_lx^2
    )),
    participant_balanced_mae_lx = mean(
      .data$participant_balanced_mae_lx
    ),
    participant_balanced_efron_r_squared_fold_weighted = mean(
      .data$participant_balanced_efron_r_squared
    ),
    log10_rmse = sqrt(stats::weighted.mean(
      .data$log10_rmse^2,
      .data$test_observations
    )),
    log10_mae = stats::weighted.mean(
      .data$log10_mae,
      .data$test_observations
    ),
    test_observations = sum(.data$test_observations),
    test_participants_fold_sum = sum(.data$test_participants),
    comparison_role = paste(
      "deterministic five-fold participant-blocked cross-validation,",
      "stratified within site; descriptive model comparison"
    ),
    .groups = "drop"
  )

if (
  nrow(fold_metrics) != 30L ||
    any(!fold_metrics$converged) ||
    any(fold_metrics$rank != fold_metrics$coefficients) ||
    any(!is.finite(cross_validation$raw_rmse_lx)) ||
    any(!is.finite(r_squared$overall_r_squared))
) {
  h03_abort("H03 bounded GLM fit assessment failed a numerical assertion")
}

table_root <- file.path(root, "artifacts/09_tables/H03")
diagnostic_root <- file.path(root, "artifacts/08_diagnostics/H03")
manifest_root <- file.path(root, "artifacts/12_manifests/H03")
dir.create(table_root, recursive = TRUE, showWarnings = FALSE)
dir.create(diagnostic_root, recursive = TRUE, showWarnings = FALSE)
dir.create(manifest_root, recursive = TRUE, showWarnings = FALSE)
metadata <- list(
  model_registry = write_csv_artifact(
    model_registry,
    file.path(table_root, "H03_glm_candidate_model_registry.csv"),
    producer
  ),
  r_squared = write_csv_artifact(
    r_squared,
    file.path(table_root, "H03_glm_r_squared_and_effect_partition.csv"),
    producer
  ),
  cross_validation = write_csv_artifact(
    cross_validation,
    file.path(table_root, "H03_glm_candidate_cross_validation.csv"),
    producer
  ),
  fold_metrics = write_csv_artifact(
    fold_metrics,
    file.path(diagnostic_root, "H03_glm_candidate_cross_validation_folds.csv"),
    producer
  )
)
manifest <- dplyr::bind_rows(lapply(metadata, manifest_row))
write_csv_artifact(
  manifest,
  file.path(manifest_root, "H03_glm_fit_assessment_manifest.csv"),
  producer
)

message(
  "H03 bounded GLM R-squared/Gaussian assessment complete; no simulation run"
)
print(as.data.frame(cross_validation), row.names = FALSE)
