h07_path <- function(...) file.path(h07_root, ...)

h07_abort <- function(...) stop(sprintf(...), call. = FALSE)

h07_dir <- function(path) {
  dir.create(path, recursive = TRUE, showWarnings = FALSE)
  normalizePath(path, winslash = "/", mustWork = TRUE)
}

h07_formula_text <- function(formula) {
  paste(deparse(formula), collapse = " ")
}

h07_read_primary_long <- function(path, placement) {
  source <- readRDS(path)
  source |>
    select(
      "site",
      "Id",
      "local_date",
      "latitude_deg",
      "photoperiod_hours",
      all_of(h07_metric_source_map$source_column)
    ) |>
    pivot_longer(
      cols = all_of(h07_metric_source_map$source_column),
      names_to = "source_column",
      values_to = "original_value"
    ) |>
    left_join(h07_metric_source_map, by = "source_column") |>
    transmute(
      data_scenario = "primary",
      placement = .env$placement,
      site = as.character(.data$site),
      Id = as.character(.data$Id),
      local_date = as.Date(.data$local_date),
      abs_latitude_deg = abs(.data$latitude_deg),
      photoperiod_hours = .data$photoperiod_hours,
      metric_order = .data$metric_order,
      metric_id = .data$metric_id,
      source_column = .data$source_column,
      original_value = .data$original_value
    )
}

h07_read_gap_long <- function() {
  solar <- readRDS(h07_input_paths[["solar_context"]]) |>
    transmute(
      site = as.character(.data$site),
      local_date = as.Date(.data$local_date),
      abs_latitude_deg = abs(.data$latitude_deg),
      photoperiod_hours = .data$photoperiod_hours
    )
  readRDS(h07_input_paths[["gap_metrics"]]) |>
    filter(.data$metric_id %in% h07_metric_ids) |>
    mutate(
      site = as.character(.data$site),
      local_date = as.Date(.data$local_date)
    ) |>
    left_join(
      solar,
      by = c("site", "local_date"),
      relationship = "many-to-one"
    ) |>
    left_join(
      h07_metric_source_map |>
        select("metric_id", "metric_order", "source_column"),
      by = "metric_id"
    ) |>
    transmute(
      data_scenario = "gap_timing_unaware",
      placement = if_else(.data$position == "glasses", "near_eye", "chest"),
      site = .data$site,
      Id = as.character(.data$Id),
      local_date = .data$local_date,
      abs_latitude_deg = .data$abs_latitude_deg,
      photoperiod_hours = .data$photoperiod_hours,
      metric_order = .data$metric_order,
      metric_id = .data$metric_id,
      source_column = .data$source_column,
      original_value = .data$alternative_preprocessing_value
    )
}

h07_load_long <- function() {
  out <- bind_rows(
    h07_read_primary_long(
      h07_input_paths[["primary_near_eye"]],
      "near_eye"
    ),
    h07_read_primary_long(
      h07_input_paths[["primary_chest"]],
      "chest"
    ),
    h07_read_gap_long()
  )
  key <- c(
    "data_scenario", "placement", "site", "Id", "local_date", "metric_id"
  )
  if (anyDuplicated(out[key])) {
    h07_abort("H07 long inputs have duplicate participant-day keys")
  }
  if (anyNA(out$abs_latitude_deg) || anyNA(out$photoperiod_hours)) {
    h07_abort("H07 predictor context is incomplete")
  }
  out
}

h07_transform_response <- function(value, spec) {
  if (identical(spec$response_family[[1L]], "tweedie_log")) {
    transformed <- value
  } else if (identical(spec$response_transform[[1L]], "log10_offset_0.1")) {
    transformed <- log10(value + 0.1)
  } else if (identical(spec$response_transform[[1L]], "identity")) {
    transformed <- value
  } else {
    h07_abort(
      "Unsupported H07 response contract for %s",
      spec$metric_id[[1L]]
    )
  }
  if (any(!is.finite(transformed))) {
    h07_abort(
      "Response transformation produced non-finite values for %s",
      spec$metric_id[[1L]]
    )
  }
  transformed
}

h07_family <- function(spec) {
  if (identical(spec$response_family[[1L]], "tweedie_log")) {
    return(mgcv::tw(link = "log", a = 1.01, b = 1.99))
  }
  stats::gaussian(link = "identity")
}

h07_prepare_frame <- function(
    long_data,
    data_scenario,
    placement,
    metric_id,
    keys = NULL,
    value_override = NULL,
    run_id = paste(data_scenario, placement, sep = "__")) {
  spec <- h07_metric_contract |>
    filter(.data$metric_id == .env$metric_id)
  if (nrow(spec) != 1L) {
    h07_abort("Unknown H07 metric: %s", metric_id)
  }
  frame <- long_data |>
    filter(
      .data$data_scenario == .env$data_scenario,
      .data$placement == .env$placement,
      .data$metric_id == .env$metric_id
    )
  if (!is.null(keys)) {
    frame <- frame |>
      semi_join(
        keys |>
          transmute(
            site = as.character(.data$site),
            Id = as.character(.data$Id),
            local_date = as.Date(.data$local_date)
          ) |>
          distinct(),
        by = c("site", "Id", "local_date")
      )
  }
  if (!is.null(value_override)) {
    if (!is.function(value_override)) {
      h07_abort("value_override must be a function")
    }
    frame <- value_override(frame)
  }
  frame <- frame |>
    filter(
      !is.na(.data$original_value),
      is.finite(.data$abs_latitude_deg),
      is.finite(.data$photoperiod_hours)
    ) |>
    mutate(
      site = factor(
        .data$site,
        levels = h07_site_levels[h07_site_levels %in% .data$site]
      ),
      Id = factor(.data$Id),
      site_participant = interaction(.data$site, .data$Id, drop = TRUE),
      response_value = h07_transform_response(.data$original_value, spec),
      row_key = paste(.data$site, .data$Id, .data$local_date, sep = "__"),
      run_id = run_id
    ) |>
    arrange(.data$site, .data$Id, .data$local_date) |>
    droplevels()
  if (nrow(frame) == 0L || anyDuplicated(frame$row_key)) {
    h07_abort("Invalid exact H07 frame for %s / %s", run_id, metric_id)
  }
  if (identical(spec$response_family[[1L]], "tweedie_log") &&
      any(frame$response_value < 0)) {
    h07_abort("Tweedie H07 response contains negative values")
  }
  attr(frame, "h07_spec") <- spec
  frame
}

h07_sample_row <- function(frame, run_id, metric_id) {
  tibble::tibble(
    run_id = run_id,
    metric_id = metric_id,
    participants = n_distinct(frame$site, frame$Id),
    participant_days = nrow(frame),
    observations = nrow(frame),
    sites = n_distinct(frame$site),
    first_date = min(frame$local_date),
    last_date = max(frame$local_date),
    photoperiod_min = min(frame$photoperiod_hours),
    photoperiod_max = max(frame$photoperiod_hours),
    unique_photoperiod = n_distinct(frame$photoperiod_hours),
    unique_latitude = n_distinct(frame$abs_latitude_deg)
  )
}

h07_model_directory <- function(run_id, metric_id) {
  h07_dir(file.path(
    h07_paths$models,
    "fits",
    run_id,
    metric_id
  ))
}

h07_frame_directory <- function(run_id) {
  h07_dir(file.path(h07_paths$models, "frames", run_id))
}

h07_save_frame <- function(frame, run_id, metric_id) {
  directory <- h07_frame_directory(run_id)
  rds <- file.path(directory, paste0(metric_id, ".rds"))
  csv <- file.path(directory, paste0(metric_id, ".csv"))
  saveRDS(frame, rds, compress = "xz")
  readr::write_csv(
    frame |>
      mutate(
        site = as.character(.data$site),
        Id = as.character(.data$Id),
        site_participant = as.character(.data$site_participant)
      ),
    csv,
    na = ""
  )
  c(rds = rds, csv = csv)
}

h07_fit_and_save <- function(
    frame,
    spec,
    run_id,
    metric_id,
    model_id) {
  if (!model_id %in% names(h07_formulas)) {
    h07_abort("Unknown H07 model id: %s", model_id)
  }
  directory <- h07_model_directory(run_id, metric_id)
  path <- file.path(directory, paste0(model_id, ".rds"))
  warnings <- character()
  started <- proc.time()[["elapsed"]]
  fit <- tryCatch(
    withCallingHandlers(
      mgcv::gam(
        formula = h07_formulas[[model_id]],
        family = h07_family(spec),
        data = frame,
        method = "REML",
        na.action = stats::na.fail,
        drop.unused.levels = TRUE,
        control = mgcv::gam.control(trace = FALSE)
      ),
      warning = function(warning) {
        warnings <<- c(warnings, conditionMessage(warning))
        invokeRestart("muffleWarning")
      }
    ),
    error = function(error) error
  )
  elapsed <- proc.time()[["elapsed"]] - started
  error <- if (inherits(fit, "error")) conditionMessage(fit) else NA_character_
  if (inherits(fit, "error")) fit <- NULL
  fit_bundle <- list(
    r_version = as.character(getRversion()),
    mgcv_version = as.character(utils::packageVersion("mgcv")),
    gratia_version = as.character(utils::packageVersion("gratia")),
    run_id = run_id,
    metric_id = metric_id,
    model_id = model_id,
    formula = h07_formula_text(h07_formulas[[model_id]]),
    family_contract = spec$response_family[[1L]],
    response_transform = spec$response_transform[[1L]],
    observations = nrow(frame),
    warnings = unique(warnings),
    error = error,
    elapsed_seconds = elapsed,
    fit = fit
  )
  saveRDS(fit_bundle, path, compress = "xz")
  fit_bundle
}

h07_outer_diagnostics <- function(fit) {
  outer <- fit$outer.info
  gradient <- if (!is.null(outer$grad)) max(abs(outer$grad)) else NA_real_
  hessian_min <- if (!is.null(outer$hess)) {
    min(eigen((outer$hess + t(outer$hess)) / 2, symmetric = TRUE)$values)
  } else {
    NA_real_
  }
  tibble::tibble(
    converged = isTRUE(fit$converged),
    optimizer_message = if (!is.null(outer$conv)) {
      paste(outer$conv, collapse = " | ")
    } else {
      NA_character_
    },
    gradient_max_abs = gradient,
    hessian_min_eigenvalue = hessian_min
  )
}

h07_smooth_row <- function(fit, pattern) {
  table <- as.data.frame(summary(fit)$s.table)
  if (nrow(table) == 0L) {
    return(tibble::tibble(
      smooth_label = NA_character_,
      smooth_edf = NA_real_,
      smooth_reference_df = NA_real_,
      smooth_statistic = NA_real_,
      smooth_p_raw = NA_real_
    ))
  }
  table$smooth_label <- rownames(table)
  match <- which(grepl(pattern, table$smooth_label))
  if (length(match) != 1L) {
    return(tibble::tibble(
      smooth_label = NA_character_,
      smooth_edf = NA_real_,
      smooth_reference_df = NA_real_,
      smooth_statistic = NA_real_,
      smooth_p_raw = NA_real_
    ))
  }
  row <- table[match, , drop = FALSE]
  statistic_col <- intersect(c("F", "Chi.sq"), names(row))
  p_col <- grep("p-value|Pr\\(", names(row), value = TRUE)
  tibble::tibble(
    smooth_label = row$smooth_label,
    smooth_edf = as.numeric(row$edf),
    smooth_reference_df = as.numeric(row$Ref.df),
    smooth_statistic = if (length(statistic_col)) {
      as.numeric(row[[statistic_col[[1L]]]])
    } else {
      NA_real_
    },
    smooth_p_raw = if (length(p_col)) as.numeric(row[[p_col[[1L]]]]) else NA_real_
  )
}

h07_k_check <- function(fit, pattern) {
  out <- tryCatch(
    withr::with_seed(7300L, mgcv::k.check(fit, n.rep = 400L)),
    error = function(error) NULL
  )
  if (is.null(out) || nrow(out) == 0L) {
    return(tibble::tibble(
      k_prime = NA_real_,
      k_edf = NA_real_,
      k_index = NA_real_,
      k_p_value = NA_real_
    ))
  }
  rows <- which(grepl(pattern, rownames(out)))
  if (length(rows) != 1L) {
    return(tibble::tibble(
      k_prime = NA_real_,
      k_edf = NA_real_,
      k_index = NA_real_,
      k_p_value = NA_real_
    ))
  }
  row <- out[rows, , drop = FALSE]
  tibble::tibble(
    k_prime = as.numeric(row[, "k'"]),
    k_edf = as.numeric(row[, "edf"]),
    k_index = as.numeric(row[, "k-index"]),
    k_p_value = as.numeric(row[, "p-value"])
  )
}

h07_concurvity <- function(fit, target_pattern) {
  full <- tryCatch(
    mgcv::concurvity(fit, full = TRUE),
    error = function(error) NULL
  )
  if (is.null(full)) {
    return(tibble::tibble(
      concurvity_worst = NA_real_,
      concurvity_observed = NA_real_,
      concurvity_estimate = NA_real_
    ))
  }
  columns <- which(grepl(target_pattern, colnames(full)))
  if (length(columns) != 1L) {
    return(tibble::tibble(
      concurvity_worst = NA_real_,
      concurvity_observed = NA_real_,
      concurvity_estimate = NA_real_
    ))
  }
  tibble::tibble(
    concurvity_worst = as.numeric(full["worst", columns]),
    concurvity_observed = as.numeric(full["observed", columns]),
    concurvity_estimate = as.numeric(full["estimate", columns])
  )
}

h07_temporal_diagnostic <- function(fit, frame) {
  residual <- as.numeric(stats::residuals(fit, type = "pearson"))
  data <- tibble::tibble(
    site_participant = frame$site_participant,
    site = frame$site,
    local_date = frame$local_date,
    residual = residual
  ) |>
    arrange(.data$site_participant, .data$local_date) |>
    group_by(.data$site_participant) |>
    mutate(
      previous_date = lag(.data$local_date),
      previous_residual = lag(.data$residual),
      date_lag = as.integer(.data$local_date - .data$previous_date)
    ) |>
    ungroup()
  pairs <- data |>
    filter(
      .data$date_lag == 1L,
      is.finite(.data$residual),
      is.finite(.data$previous_residual)
    )
  pooled <- if (nrow(pairs) >= 3L) {
    suppressWarnings(stats::cor(pairs$residual, pairs$previous_residual))
  } else {
    NA_real_
  }
  participant <- pairs |>
    group_by(.data$site_participant) |>
    filter(n() >= 3L) |>
    summarise(
      lag1 = suppressWarnings(stats::cor(
        .data$residual,
        .data$previous_residual
      )),
      .groups = "drop"
    ) |>
    filter(is.finite(.data$lag1))
  tibble::tibble(
    consecutive_day_pairs = nrow(pairs),
    participants_with_three_pairs = nrow(participant),
    pooled_consecutive_day_lag1 = pooled,
    median_participant_lag1 = if (nrow(participant)) {
      stats::median(participant$lag1)
    } else {
      NA_real_
    },
    temporal_status = if (
      nrow(pairs) >= 30L && is.finite(pooled) && abs(pooled) >= 0.30
    ) {
      "WARN_MATERIAL_RESIDUAL_DEPENDENCE"
    } else {
      "PASS_DESCRIPTIVE_DEPENDENCE_CHECK"
    }
  )
}

h07_tweedie_parameters <- function(fit, spec) {
  if (!identical(spec$response_family[[1L]], "tweedie_log")) {
    return(tibble::tibble(
      tweedie_power = NA_real_,
      dispersion = summary(fit)$dispersion,
      distance_to_lower_power_bound = NA_real_,
      distance_to_upper_power_bound = NA_real_
    ))
  }
  power <- tryCatch(
    as.numeric(fit$family$getTheta(trans = TRUE))[[1L]],
    error = function(error) NA_real_
  )
  tibble::tibble(
    tweedie_power = power,
    dispersion = summary(fit)$dispersion,
    distance_to_lower_power_bound = power - 1.01,
    distance_to_upper_power_bound = 1.99 - power
  )
}

h07_fit_diagnostic_row <- function(fit_bundle, frame, spec) {
  if (is.null(fit_bundle$fit)) {
    return(tibble::tibble(
      run_id = fit_bundle$run_id,
      metric_id = fit_bundle$metric_id,
      model_id = fit_bundle$model_id,
      fit_status = "FAIL_FIT",
      error = fit_bundle$error,
      warnings = paste(fit_bundle$warnings, collapse = " | "),
      elapsed_seconds = fit_bundle$elapsed_seconds
    ))
  }
  fit <- fit_bundle$fit
  target_pattern <- if (grepl("registered_tensor", fit_bundle$model_id)) {
    "^te\\(abs_latitude_deg"
  } else if (grepl("adapted_photoperiod_(smooth|expanded|fixed)", fit_bundle$model_id)) {
    "^s\\(photoperiod_hours"
  } else {
    "$a"
  }
  outer <- h07_outer_diagnostics(fit)
  smooth <- h07_smooth_row(fit, target_pattern)
  k <- h07_k_check(fit, target_pattern)
  concurvity <- h07_concurvity(fit, target_pattern)
  temporal <- h07_temporal_diagnostic(fit, frame)
  tweedie <- h07_tweedie_parameters(fit, spec)
  X <- stats::model.matrix(fit)
  smooth_object <- fit$smooth[
    vapply(fit$smooth, function(x) grepl(target_pattern, x$label), logical(1))
  ]
  smooth_rank <- if (length(smooth_object) == 1L) {
    index <- smooth_object[[1L]]$first.para:smooth_object[[1L]]$last.para
    qr(X[, index, drop = FALSE])$rank
  } else {
    NA_integer_
  }
  leverage <- as.numeric(fit$hat)
  participant_leverage <- tibble::tibble(
    site_participant = frame$site_participant,
    leverage = leverage
  ) |>
    group_by(.data$site_participant) |>
    summarise(leverage = sum(.data$leverage), .groups = "drop")
  fit_status <- case_when(
    !isTRUE(outer$converged[[1L]]) ~ "FAIL_CONVERGENCE",
    is.finite(outer$hessian_min_eigenvalue[[1L]]) &&
      outer$hessian_min_eigenvalue[[1L]] <= 0 ~ "FAIL_HESSIAN",
    is.finite(k$k_p_value[[1L]]) && k$k_p_value[[1L]] < 0.05 &&
      is.finite(k$k_edf[[1L]]) && is.finite(k$k_prime[[1L]]) &&
      k$k_edf[[1L]] > 0.90 * k$k_prime[[1L]] ~ "WARN_BASIS",
    is.finite(concurvity$concurvity_estimate[[1L]]) &&
      concurvity$concurvity_estimate[[1L]] >= 0.90 ~ "WARN_CONCURVITY",
    temporal$temporal_status[[1L]] == "WARN_MATERIAL_RESIDUAL_DEPENDENCE" ~
      "WARN_RESIDUAL_DEPENDENCE",
    TRUE ~ "PASS"
  )
  bind_cols(
    tibble::tibble(
      run_id = fit_bundle$run_id,
      metric_id = fit_bundle$metric_id,
      model_id = fit_bundle$model_id,
      fit_status = fit_status,
      error = fit_bundle$error,
      warnings = paste(fit_bundle$warnings, collapse = " | "),
      elapsed_seconds = fit_bundle$elapsed_seconds,
      observations = nrow(frame),
      coefficients = length(stats::coef(fit)),
      model_edf = sum(fit$edf),
      edf2_available = !is.null(fit$edf2),
      design_columns = ncol(X),
      design_rank = qr(X)$rank,
      design_condition = suppressWarnings(kappa(X)),
      target_smooth_design_rank = smooth_rank,
      maximum_hat = max(leverage),
      maximum_participant_leverage_share =
        max(participant_leverage$leverage) / sum(participant_leverage$leverage)
    ),
    outer,
    smooth,
    k,
    concurvity,
    temporal,
    tweedie
  )
}

h07_anova_p <- function(reduced, full) {
  table <- tryCatch(
    as.data.frame(stats::anova(reduced, full, test = "Chisq")),
    error = function(error) NULL
  )
  if (is.null(table) || nrow(table) < 2L) return(NA_real_)
  p_col <- grep("Pr\\(", names(table), value = TRUE)
  if (!length(p_col)) return(NA_real_)
  as.numeric(table[[p_col[[1L]]]][[nrow(table)]])
}

h07_conditional_aic <- function(full, reduced) {
  table <- stats::AIC(full, reduced)
  tibble::tibble(
    aic_full = as.numeric(table$AIC[[1L]]),
    aic_reduced = as.numeric(table$AIC[[2L]]),
    delta_aic_full_minus_reduced =
      as.numeric(table$AIC[[1L]] - table$AIC[[2L]]),
    full_edf2_available = !is.null(full$edf2),
    reduced_edf2_available = !is.null(reduced$edf2)
  )
}

h07_test_rows <- function(fit_bundles, frame, spec, run_id, metric_id) {
  get_fit <- function(model_id) {
    fit_bundle <- fit_bundles[[model_id]]
    if (is.null(fit_bundle) || is.null(fit_bundle$fit)) NULL else fit_bundle$fit
  }
  tensor <- get_fit("registered_tensor")
  registered_null <- get_fit("registered_null")
  registered_linear <- get_fit("registered_linear_surface")
  adapted <- get_fit("adapted_photoperiod_smooth")
  adapted_linear <- get_fit("adapted_photoperiod_linear")
  registered <- if (
    !is.null(tensor) && !is.null(registered_null) && !is.null(registered_linear)
  ) {
    association <- h07_smooth_row(tensor, "^te\\(abs_latitude_deg")
    bind_rows(
      bind_cols(
        tibble::tibble(
          run_id = run_id,
          metric_id = metric_id,
          analysis_scope = "registered_tensor",
          test_id = "association",
          p_raw_model = association$smooth_p_raw,
          p_release_status = "WITHHELD_STRUCTURAL_LATITUDE_SITE_NONIDENTIFIABILITY"
        ),
        h07_conditional_aic(tensor, registered_null)
      ),
      bind_cols(
        tibble::tibble(
          run_id = run_id,
          metric_id = metric_id,
          analysis_scope = "registered_tensor",
          test_id = "nonlinear_shape",
          p_raw_model = h07_anova_p(registered_linear, tensor),
          p_release_status = "WITHHELD_STRUCTURAL_LATITUDE_SITE_NONIDENTIFIABILITY"
        ),
        h07_conditional_aic(tensor, registered_linear)
      )
    )
  } else {
    tibble::tibble()
  }
  adapted_rows <- if (
    !is.null(adapted) && !is.null(registered_null) && !is.null(adapted_linear)
  ) {
    association <- h07_smooth_row(adapted, "^s\\(photoperiod_hours")
    diagnostic <- h07_fit_diagnostic_row(
      fit_bundles[["adapted_photoperiod_smooth"]],
      frame,
      spec
    )
    release <- if (diagnostic$fit_status[[1L]] %in% c("PASS", "WARN_BASIS")) {
      "RELEASE_CONDITIONAL_APPROXIMATE"
    } else {
      paste0("WITHHELD_", diagnostic$fit_status[[1L]])
    }
    bind_rows(
      bind_cols(
        tibble::tibble(
          run_id = run_id,
          metric_id = metric_id,
          analysis_scope = "adapted_photoperiod",
          test_id = "association",
          p_raw_model = association$smooth_p_raw,
          p_release_status = release
        ),
        h07_conditional_aic(adapted, registered_null)
      ),
      bind_cols(
        tibble::tibble(
          run_id = run_id,
          metric_id = metric_id,
          analysis_scope = "adapted_photoperiod",
          test_id = "nonlinear_shape",
          p_raw_model = h07_anova_p(adapted_linear, adapted),
          p_release_status = release
        ),
        h07_conditional_aic(adapted, adapted_linear)
      )
    )
  } else {
    tibble::tibble()
  }
  bind_rows(registered, adapted_rows)
}

h07_run_metric <- function(
    long_data,
    run_id,
    data_scenario,
    placement,
    metric_id,
    model_ids = h07_main_model_ids,
    keys = NULL,
    value_override = NULL) {
  frame <- h07_prepare_frame(
    long_data = long_data,
    data_scenario = data_scenario,
    placement = placement,
    metric_id = metric_id,
    keys = keys,
    value_override = value_override,
    run_id = run_id
  )
  spec <- attr(frame, "h07_spec")
  frame_paths <- h07_save_frame(frame, run_id, metric_id)
  fit_bundles <- setNames(
    lapply(model_ids, function(model_id) {
      h07_fit_and_save(
        frame = frame,
        spec = spec,
        run_id = run_id,
        metric_id = metric_id,
        model_id = model_id
      )
    }),
    model_ids
  )
  diagnostics <- bind_rows(lapply(fit_bundles, function(fit_bundle) {
    h07_fit_diagnostic_row(fit_bundle, frame, spec)
  }))
  tests <- h07_test_rows(
    fit_bundles = fit_bundles,
    frame = frame,
    spec = spec,
    run_id = run_id,
    metric_id = metric_id
  )
  list(
    run_id = run_id,
    metric_id = metric_id,
    frame = frame,
    frame_paths = frame_paths,
    sample = h07_sample_row(frame, run_id, metric_id),
    fit_bundles = fit_bundles,
    diagnostics = diagnostics,
    tests = tests
  )
}

h07_write_table <- function(data, filename) {
  path <- file.path(h07_paths$tables, filename)
  readr::write_csv(data, path, na = "")
  path
}
