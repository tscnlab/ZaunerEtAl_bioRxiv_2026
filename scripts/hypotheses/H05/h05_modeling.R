h05_required_model_columns <- function() {
  c(
    "data_scenario_id",
    "model_implementation_id",
    "placement",
    "scenario",
    "metric_order",
    "metric_id",
    "analysis_unit",
    "site",
    "Id",
    "local_date",
    "participant_days_contributing",
    "value",
    "metric_estimable",
    "metric_failure_reason",
    "metric_support_available",
    "metric_support_unavailability_reason",
    "metric_support_valid_minutes",
    "metric_support_expected_minutes",
    "metric_any_censored",
    "participant_key",
    "scenario_estimable",
    "scenario_failure_reason"
  )
}

h05_verified_leba <- function(leba, factor_registry) {
  required <- c(
    "site",
    "Id",
    factor_registry$factor_id,
    unlist(lapply(seq_len(nrow(factor_registry)), function(index) {
      row <- factor_registry[index, , drop = FALSE]
      sprintf(
        "%s_%02d",
        row$factor_id,
        seq.int(row$first_item, row$last_item)
      )
    }))
  )
  missing <- setdiff(required, names(leba))
  if (length(missing) > 0L) {
    h05_abort(
      "LEBA input is missing required column(s): %s",
      paste(missing, collapse = ", ")
    )
  }
  if (anyDuplicated(leba[c("site", "Id")])) {
    h05_abort("LEBA input must contain one row per site and participant")
  }
  expected_levels <- c("Never", "Rarely", "Sometimes", "Often", "Always")
  audit_rows <- vector("list", nrow(factor_registry))
  for (index in seq_len(nrow(factor_registry))) {
    contract <- factor_registry[index, , drop = FALSE]
    item_ids <- sprintf(
      "%s_%02d",
      contract$factor_id,
      seq.int(contract$first_item, contract$last_item)
    )
    items <- lapply(leba[item_ids], function(value) {
      if (!is.factor(value) || !identical(levels(value), expected_levels)) {
        h05_abort("LEBA item coding differs from the ordered response levels")
      }
      as.integer(value)
    })
    item_matrix <- do.call(cbind, items)
    colnames(item_matrix) <- item_ids
    if (!is.na(contract$reverse_item)) {
      item_matrix[, contract$reverse_item] <-
        6L - item_matrix[, contract$reverse_item]
    }
    calculated <- rowSums(item_matrix)
    stored <- leba[[contract$factor_id]]
    mismatch <- sum(calculated != stored, na.rm = TRUE)
    audit_rows[[index]] <- tibble::tibble(
      factor_order = contract$factor_order,
      factor_id = contract$factor_id,
      factor_label = contract$factor_label,
      participants = nrow(leba),
      item_count = length(item_ids),
      missing_item_cells = sum(is.na(item_matrix)),
      missing_scores = sum(is.na(stored)),
      possible_min = contract$possible_min,
      possible_max = contract$possible_max,
      observed_min = min(stored, na.rm = TRUE),
      observed_max = max(stored, na.rm = TRUE),
      floor_n = sum(stored == contract$possible_min, na.rm = TRUE),
      ceiling_n = sum(stored == contract$possible_max, na.rm = TRUE),
      unique_scores = dplyr::n_distinct(stored, na.rm = TRUE),
      tied_participants = nrow(leba) - dplyr::n_distinct(stored, na.rm = TRUE),
      mismatch_n = mismatch,
      score_verified = mismatch == 0L
    )
  }
  audit <- dplyr::bind_rows(audit_rows)
  if (
    nrow(leba) == 0L ||
      any(audit$missing_item_cells != 0L) ||
      any(audit$missing_scores != 0L) ||
      any(!audit$score_verified)
  ) {
    h05_abort("The LEBA input fails the score specification")
  }
  audit
}

h05_row_is_eligible <- function(rows) {
  included <- !is.na(rows$scenario_estimable) & rows$scenario_estimable &
    !is.na(rows$metric_estimable) & rows$metric_estimable &
    is.finite(rows$value) &
    !is.na(rows$site) &
    !is.na(rows$Id) &
    !is.na(rows$participant_key)
  included[is.na(included)] <- FALSE
  included
}

h05_prepare_metric_rows <- function(
  object,
  spec,
  placement,
  sample_scenario,
  leba,
  site_levels
) {
  rows <- object$model_rows
  missing <- setdiff(h05_required_model_columns(), names(rows))
  if (length(missing) > 0L) {
    h05_abort(
      "H05 model input is missing column(s): %s",
      paste(missing, collapse = ", ")
    )
  }

  paired_participant_derived <-
    sample_scenario == "paired_common_sample" &&
    spec$analysis_unit == "participant"

  if (paired_participant_derived) {
    candidate <- rows[
      rows$scenario == "all_available" &
        rows$metric_id == spec$metric_id &
        rows$placement %in% c("glasses", "chest"),
      ,
      drop = FALSE
    ]
    candidate <- candidate[h05_row_is_eligible(candidate), , drop = FALSE]
    common_keys <- Reduce(
      intersect,
      lapply(c("glasses", "chest"), function(position) {
        unique(candidate$participant_key[candidate$placement == position])
      })
    )
    source <- candidate[
      candidate$placement == placement &
        candidate$participant_key %in% common_keys,
      ,
      drop = FALSE
    ]
    source_rows_before_eligibility <- sum(
      rows$scenario == "all_available" &
        rows$metric_id == spec$metric_id &
        rows$placement == placement
    )
  } else {
    source <- rows[
      rows$scenario == sample_scenario &
        rows$metric_id == spec$metric_id &
        rows$placement == placement,
      ,
      drop = FALSE
    ]
    source_rows_before_eligibility <- nrow(source)
    source <- source[h05_row_is_eligible(source), , drop = FALSE]
  }

  if (nrow(source) == 0L) {
    return(list(
      rows = tibble::tibble(),
      base_flow = tibble::tibble(
        source_rows = source_rows_before_eligibility,
        eligible_metric_rows = 0L,
        missing_leba_rows = NA_integer_,
        observations = 0L,
        participants = 0L,
        participant_days = 0L,
        represented_days = 0L,
        sites = 0L,
        paired_participant_rows_derived = paired_participant_derived,
        sample_status = "NON_ESTIMABLE"
      )
    ))
  }

  key <- if (spec$analysis_unit == "participant") {
    source["participant_key"]
  } else {
    source[c("participant_key", "local_date")]
  }
  if (anyDuplicated(key)) {
    h05_abort(
      "H05 `%s` frame contains duplicate %s keys",
      spec$metric_id,
      spec$analysis_unit
    )
  }

  leba_scores <- leba |>
    dplyr::select(
      .data$site,
      .data$Id,
      dplyr::all_of(h05_factor_registry()$factor_id)
    )
  source <- dplyr::left_join(
    source,
    leba_scores,
    by = c("site", "Id"),
    relationship = "many-to-one"
  )
  factor_ids <- h05_factor_registry()$factor_id
  missing_leba <- !stats::complete.cases(source[factor_ids])
  missing_leba_n <- sum(missing_leba)
  source <- source[!missing_leba, , drop = FALSE]
  source$site <- factor(as.character(source$site), levels = site_levels)
  if (any(is.na(source$site))) {
    h05_abort("H05 frame contains a site absent from the display registry")
  }
  source$site <- droplevels(source$site)
  source$participant_key <- factor(source$participant_key)
  source <- source[
    order(
      source$site,
      source$participant_key,
      source$local_date,
      na.last = TRUE
    ),
    ,
    drop = FALSE
  ]
  source$.model_row_id <- if (spec$analysis_unit == "participant") {
    as.character(source$participant_key)
  } else {
    paste(source$participant_key, source$local_date, sep = "::")
  }
  if (anyDuplicated(source$.model_row_id)) {
    h05_abort("H05 model-row identifiers are not unique")
  }
  represented_days <- if (spec$analysis_unit == "participant") {
    sum(source$participant_days_contributing, na.rm = TRUE)
  } else {
    nrow(source)
  }
  list(
    rows = tibble::as_tibble(source),
    base_flow = tibble::tibble(
      source_rows = source_rows_before_eligibility,
      eligible_metric_rows = nrow(source),
      missing_leba_rows = missing_leba_n,
      observations = nrow(source),
      participants = dplyr::n_distinct(source$participant_key),
      participant_days = if (spec$analysis_unit == "participant_day") {
        nrow(source)
      } else {
        NA_integer_
      },
      represented_days = as.integer(represented_days),
      sites = nlevels(source$site),
      paired_participant_rows_derived = paired_participant_derived,
      sample_status = if (nrow(source) > 0L) "AVAILABLE" else "NON_ESTIMABLE"
    )
  )
}

h05_add_factor_to_frame <- function(rows, spec, factor_row) {
  if (nrow(rows) == 0L) {
    return(list(
      frame = tibble::tibble(),
      scaling = tibble::tibble(
        leba_participant_mean = NA_real_,
        leba_participant_sd = NA_real_
      )
    ))
  }
  factor_id <- factor_row$factor_id
  participant_scores <- rows |>
    dplyr::transmute(
      participant_key = as.character(.data$participant_key),
      leba_score = as.numeric(.data[[factor_id]])
    ) |>
    dplyr::distinct()
  if (anyDuplicated(participant_scores$participant_key)) {
    h05_abort("LEBA score varies within participant for `%s`", factor_id)
  }
  center <- mean(participant_scores$leba_score)
  scale <- stats::sd(participant_scores$leba_score)
  if (!is.finite(center) || !is.finite(scale) || scale <= 0) {
    h05_abort("LEBA centering constants are invalid for `%s`", factor_id)
  }
  frame <- rows
  frame$leba_score <- as.numeric(frame[[factor_id]])
  frame$leba_centered <- frame$leba_score - center
  frame$response_value <- h01_transform_response(
    frame$value,
    spec$response_transform
  )
  frame$site <- droplevels(frame$site)
  if (nlevels(frame$site) < 2L) {
    h05_abort("H05 frame contains fewer than two sites")
  }
  stats::contrasts(frame$site) <- stats::contr.sum(nlevels(frame$site))
  frame$participant_key <- droplevels(frame$participant_key)
  list(
    frame = tibble::as_tibble(frame),
    scaling = tibble::tibble(
      leba_participant_mean = center,
      leba_participant_sd = scale
    )
  )
}

h05_capture_fit <- function(expression) {
  warnings <- character()
  model <- tryCatch(
    withCallingHandlers(
      expression,
      warning = function(condition) {
        warnings <<- c(warnings, conditionMessage(condition))
        invokeRestart("muffleWarning")
      }
    ),
    error = function(condition) condition
  )
  if (inherits(model, "error")) {
    return(list(
      model = NULL,
      warnings = unique(warnings),
      error = conditionMessage(model)
    ))
  }
  list(model = model, warnings = unique(warnings), error = NA_character_)
}

h05_fit_model <- function(
  frame,
  formula,
  spec,
  site_structure = c("fixed", "random"),
  estimation = c("comparison", "final")
) {
  site_structure <- match.arg(site_structure)
  estimation <- match.arg(estimation)
  if (nrow(frame) == 0L) {
    return(list(model = NULL, warnings = character(), error = "No estimable rows"))
  }
  if (spec$analysis_unit == "participant" && site_structure == "fixed") {
    return(h05_capture_fit(stats::lm(formula = formula, data = frame)))
  }
  if (spec$response_family == "gaussian") {
    return(h05_capture_fit(
      lme4::lmer(
        formula = formula,
        data = frame,
        REML = identical(estimation, "final"),
        control = lme4::lmerControl(
          optimizer = "nloptwrap",
          calc.derivs = TRUE
        )
      )
    ))
  }
  h05_capture_fit(
    glmmTMB::glmmTMB(
      formula = formula,
      data = frame,
      family = glmmTMB::tweedie(link = "log"),
      REML = FALSE,
      control = glmmTMB::glmmTMBControl(
        optCtrl = list(iter.max = 10000L, eval.max = 10000L)
      )
    )
  )
}

h05_fit_bundle <- function(frame, spec, inferential = FALSE) {
  formulas <- h05_formula_set(spec$analysis_unit)
  comparison_full <- if (inferential) {
    h05_fit_model(
      frame,
      formulas$fixed_full,
      spec,
      site_structure = "fixed",
      estimation = "comparison"
    )
  } else {
    list(model = NULL, warnings = character(), error = "Not an inferential family")
  }
  comparison_reduced <- if (inferential) {
    h05_fit_model(
      frame,
      formulas$fixed_reduced,
      spec,
      site_structure = "fixed",
      estimation = "comparison"
    )
  } else {
    list(model = NULL, warnings = character(), error = "Not an inferential family")
  }
  final <- if (
    inferential &&
      (spec$analysis_unit == "participant" || spec$response_family == "tweedie_log")
  ) {
    comparison_full
  } else {
    h05_fit_model(
      frame,
      formulas$fixed_full,
      spec,
      site_structure = "fixed",
      estimation = "final"
    )
  }
  list(
    spec = spec,
    formulas = formulas,
    inferential = inferential,
    comparison_full = comparison_full,
    comparison_reduced = comparison_reduced,
    final = final,
    frame_keys = frame$.model_row_id
  )
}

h05_empty_effect <- function() {
  tibble::tibble(
    estimate_model_per_point = NA_real_,
    std_error_model_per_point = NA_real_,
    conf_low_model_per_point = NA_real_,
    conf_high_model_per_point = NA_real_,
    wald_p_raw = NA_real_,
    effect_type = NA_character_,
    estimate_practical_per_point = NA_real_,
    conf_low_practical_per_point = NA_real_,
    conf_high_practical_per_point = NA_real_,
    estimate_model_per_sd = NA_real_,
    std_error_model_per_sd = NA_real_,
    conf_low_model_per_sd = NA_real_,
    conf_high_model_per_sd = NA_real_,
    estimate_practical_per_sd = NA_real_,
    conf_low_practical_per_sd = NA_real_,
    conf_high_practical_per_sd = NA_real_,
    interval_method = "wald_normal",
    effect_status = "NON_ESTIMABLE"
  )
}

h05_effect_summary <- function(model, spec, leba_sd) {
  if (is.null(model) || !is.finite(leba_sd) || leba_sd <= 0) {
    return(h05_empty_effect())
  }
  effect <- h01_extract_term_effect(
    model,
    term = "leba_centered",
    term_label = "LEBA score per raw point",
    spec = spec,
    confidence_level = 0.95
  )
  if (nrow(effect) != 1L || effect$status != "PASS") {
    return(h05_empty_effect())
  }
  estimate_sd <- effect$estimate_model * leba_sd
  se_sd <- effect$std_error * leba_sd
  low_sd <- effect$conf_low_model * leba_sd
  high_sd <- effect$conf_high_model * leba_sd
  practical_sd <- h01_transform_effect(
    estimate_sd,
    low_sd,
    high_sd,
    spec
  )
  tibble::tibble(
    estimate_model_per_point = effect$estimate_model,
    std_error_model_per_point = effect$std_error,
    conf_low_model_per_point = effect$conf_low_model,
    conf_high_model_per_point = effect$conf_high_model,
    wald_p_raw = effect$p_raw,
    effect_type = effect$effect_type,
    estimate_practical_per_point = effect$estimate_practical,
    conf_low_practical_per_point = effect$conf_low_practical,
    conf_high_practical_per_point = effect$conf_high_practical,
    estimate_model_per_sd = estimate_sd,
    std_error_model_per_sd = se_sd,
    conf_low_model_per_sd = low_sd,
    conf_high_model_per_sd = high_sd,
    estimate_practical_per_sd = practical_sd$estimate_practical,
    conf_low_practical_per_sd = practical_sd$conf_low_practical,
    conf_high_practical_per_sd = practical_sd$conf_high_practical,
    interval_method = "wald_normal",
    effect_status = "PASS"
  )
}

h05_lrt_summary <- function(bundle) {
  if (!isTRUE(bundle$inferential)) {
    return(tibble::tibble(
      statistic = NA_real_,
      df = NA_real_,
      p_raw = NA_real_,
      log_lik_reduced = NA_real_,
      log_lik_full = NA_real_,
      n_obs_reduced = NA_integer_,
      n_obs_full = NA_integer_,
      comparison_status = "NOT_INFERENTIAL"
    ))
  }
  h01_loglik_test(
    bundle$comparison_reduced$model,
    bundle$comparison_full$model,
    comparison_id = "fixed_site_full_vs_no_leba"
  ) |>
    dplyr::select(-.data$comparison_id)
}

h05_residual_serial_dependence <- function(model, frame) {
  if (is.null(model) || all(is.na(frame$local_date))) {
    return(tibble::tibble(
      participants_with_lag1 = 0L,
      median_participant_lag1 = NA_real_,
      pooled_within_participant_lag1 = NA_real_,
      serial_dependence_status = "NOT_APPLICABLE"
    ))
  }
  residual <- tryCatch(
    stats::residuals(model, type = "pearson"),
    error = function(error) stats::residuals(model)
  )
  data <- tibble::tibble(
    participant_key = as.character(frame$participant_key),
    local_date = as.Date(frame$local_date),
    residual = as.numeric(residual)
  ) |>
    dplyr::arrange(.data$participant_key, .data$local_date) |>
    dplyr::group_by(.data$participant_key) |>
    dplyr::mutate(previous_residual = dplyr::lag(.data$residual)) |>
    dplyr::ungroup()
  lag_rows <- data |>
    dplyr::filter(is.finite(.data$residual), is.finite(.data$previous_residual))
  participant_correlations <- data |>
    dplyr::group_by(.data$participant_key) |>
    dplyr::filter(dplyr::n() >= 3L) |>
    dplyr::summarise(
      lag1 = suppressWarnings(stats::cor(
        .data$residual[-1L],
        .data$residual[-dplyr::n()]
      )),
      .groups = "drop"
    ) |>
    dplyr::filter(is.finite(.data$lag1))
  pooled <- if (nrow(lag_rows) >= 3L) {
    suppressWarnings(stats::cor(
      lag_rows$residual,
      lag_rows$previous_residual
    ))
  } else {
    NA_real_
  }
  median_lag <- if (nrow(participant_correlations) > 0L) {
    stats::median(participant_correlations$lag1)
  } else {
    NA_real_
  }
  tibble::tibble(
    participants_with_lag1 = nrow(participant_correlations),
    median_participant_lag1 = median_lag,
    pooled_within_participant_lag1 = pooled,
    serial_dependence_status = if (
      is.finite(pooled) && abs(pooled) >= 0.3
    ) {
      "WARN_DESCRIPTIVE_SERIAL_DEPENDENCE"
    } else {
      "PASS_DESCRIPTIVE_CHECK"
    }
  )
}

h05_diagnostic_summary <- function(bundle, frame, seed) {
  model <- bundle$final$model
  fit_status <- h01_model_fit_status(model)
  timing <- h01_timing_diagnostic(frame, bundle$spec)
  residual <- h01_residual_diagnostics(model, bundle$spec, seed)
  bounds <- h01_prediction_bounds(model, frame, bundle$spec)
  serial <- h05_residual_serial_dependence(model, frame)
  fit_warnings <- paste(bundle$final$warnings, collapse = " | ")
  major_failure <-
    !is.na(bundle$final$error) ||
    !isTRUE(fit_status$converged) ||
    !isTRUE(fit_status$positive_definite_hessian) ||
    isTRUE(fit_status$singular) ||
    startsWith(timing$timing_status, "FAIL") ||
    identical(bounds$prediction_bound_status, "FAIL_OBSERVED_SUPPORT")
  review_warning <-
    startsWith(residual$residual_status, "WARN") ||
    startsWith(bounds$prediction_bound_status, "WARN") ||
    startsWith(bounds$audit_threshold_status, "WARN") ||
    startsWith(serial$serial_dependence_status, "WARN") ||
    nzchar(fit_warnings)
  adequacy <- if (major_failure) {
    "not_acceptable"
  } else if (review_warning) {
    "acceptable_with_specified_limitations"
  } else {
    "acceptable"
  }
  limitations <- c(
    if (startsWith(residual$residual_status, "WARN")) residual$residual_status,
    if (startsWith(bounds$prediction_bound_status, "WARN")) {
      bounds$prediction_bound_status
    },
    if (startsWith(bounds$audit_threshold_status, "WARN")) {
      bounds$audit_threshold_status
    },
    if (startsWith(serial$serial_dependence_status, "WARN")) {
      serial$serial_dependence_status
    },
    if (nzchar(fit_warnings)) "FIT_WARNING",
    if (major_failure) "MAJOR_MODEL_CHECK"
  )
  dplyr::bind_cols(
    fit_status,
    timing,
    residual,
    bounds,
    serial,
    tibble::tibble(
      fit_error = bundle$final$error,
      fit_warnings = fit_warnings,
      diagnostic_status = if (major_failure) {
        "MODEL_CHECK_FAILED"
      } else if (review_warning) {
        "WARN_REVIEW"
      } else {
        "PASS"
      },
      model_adequacy = adequacy,
      specified_limitations = if (length(limitations) == 0L) {
        NA_character_
      } else {
        paste(unique(limitations), collapse = " | ")
      }
    )
  )
}

h05_fit_index_rows <- function(bundle) {
  fits <- list(
    comparison_full = bundle$comparison_full,
    comparison_reduced = bundle$comparison_reduced,
    final_full = bundle$final
  )
  dplyr::bind_rows(lapply(names(fits), function(name) {
    fit <- fits[[name]]
    model <- fit$model
    status <- h01_model_fit_status(model)
    tibble::tibble(
      model_name = name,
      formula = if (name == "comparison_reduced") {
        paste(deparse(bundle$formulas$fixed_reduced), collapse = " ")
      } else {
        paste(deparse(bundle$formulas$fixed_full), collapse = " ")
      },
      engine = if (is.null(model)) {
        NA_character_
      } else {
        class(model)[1L]
      },
      observations = if (is.null(model)) NA_integer_ else stats::nobs(model),
      log_likelihood = if (is.null(model)) {
        NA_real_
      } else {
        as.numeric(stats::logLik(model))
      },
      aic = if (is.null(model)) NA_real_ else stats::AIC(model),
      converged = status$converged,
      positive_definite_hessian = status$positive_definite_hessian,
      singular = status$singular,
      max_gradient = status$max_gradient,
      warnings = paste(fit$warnings, collapse = " | "),
      error = fit$error,
      status = if (is.null(model)) "NOT_FITTED" else "FITTED"
    )
  }))
}

h05_random_site_summary <- function(frame, spec, leba_sd) {
  formula <- h05_formula_set(spec$analysis_unit)$random_site
  fit <- h05_fit_model(
    frame,
    formula,
    spec,
    site_structure = "random",
    estimation = "final"
  )
  status <- h01_model_fit_status(fit$model)
  effect <- h05_effect_summary(fit$model, spec, leba_sd)
  site_sd <- tryCatch(
    {
      if (inherits(fit$model, "glmmTMB")) {
        conditional <- glmmTMB::VarCorr(fit$model)$cond
        if (!"site" %in% names(conditional)) {
          NA_real_
        } else {
          unname(attr(conditional$site, "stddev")[[1L]])
        }
      } else {
        variance <- as.data.frame(lme4::VarCorr(fit$model))
        variance$sdcor[variance$grp == "site"][1L]
      }
    },
    error = function(error) NA_real_
  )
  dplyr::bind_cols(
    tibble::tibble(
      formula = paste(deparse(formula), collapse = " "),
      site_random_effect_sd = site_sd,
      converged = status$converged,
      positive_definite_hessian = status$positive_definite_hessian,
      singular = status$singular,
      max_gradient = status$max_gradient,
      warnings = paste(fit$warnings, collapse = " | "),
      error = fit$error,
      random_site_status = if (
        is.null(fit$model)
      ) {
        "NON_ESTIMABLE"
      } else if (
        isTRUE(status$converged) &&
          isTRUE(status$positive_definite_hessian) &&
          !isTRUE(status$singular)
      ) {
        "DESCRIPTIVE_PASS"
      } else {
        "DESCRIPTIVE_UNSTABLE"
      }
    ),
    effect
  )
}

h05_leave_one_site_out <- function(frame, spec, leba_sd, full_estimate) {
  sites <- levels(frame$site)
  dplyr::bind_rows(lapply(sites, function(omitted_site) {
    subset <- frame[
      as.character(frame$site) != omitted_site,
      ,
      drop = FALSE
    ]
    subset$site <- droplevels(subset$site)
    subset$participant_key <- droplevels(subset$participant_key)
    if (nlevels(subset$site) >= 2L) {
      stats::contrasts(subset$site) <- stats::contr.sum(nlevels(subset$site))
    }
    formula <- h05_formula_set(spec$analysis_unit)$fixed_full
    fit <- h05_fit_model(
      subset,
      formula,
      spec,
      site_structure = "fixed",
      estimation = "final"
    )
    status <- h01_model_fit_status(fit$model)
    effect <- h05_effect_summary(fit$model, spec, leba_sd)
    estimate <- effect$estimate_model_per_point
    tibble::tibble(
      omitted_site = omitted_site,
      observations = nrow(subset),
      participants = dplyr::n_distinct(subset$participant_key),
      sites = nlevels(subset$site),
      estimate_model_per_point = estimate,
      conf_low_model_per_point = effect$conf_low_model_per_point,
      conf_high_model_per_point = effect$conf_high_model_per_point,
      estimate_change_from_full = estimate - full_estimate,
      relative_absolute_change = if (
        is.finite(full_estimate) && abs(full_estimate) > 1e-12
      ) {
        abs((estimate - full_estimate) / full_estimate)
      } else {
        NA_real_
      },
      sign_reversal = if (
        is.finite(estimate) && is.finite(full_estimate) && full_estimate != 0
      ) {
        sign(estimate) != sign(full_estimate)
      } else {
        NA
      },
      converged = status$converged,
      positive_definite_hessian = status$positive_definite_hessian,
      singular = status$singular,
      warnings = paste(fit$warnings, collapse = " | "),
      error = fit$error,
      refit_status = if (
        is.null(fit$model) ||
          !isTRUE(status$converged) ||
          !isTRUE(status$positive_definite_hessian) ||
          isTRUE(status$singular)
      ) {
        "UNSTABLE_OR_NON_ESTIMABLE"
      } else {
        "PASS"
      }
    )
  }))
}

h05_influence_candidates <- function(model, frame, n = 3L) {
  if (is.null(model) || nrow(frame) == 0L) {
    return(tibble::tibble())
  }
  if (inherits(model, "lm") && !inherits(model, "merMod")) {
    score <- stats::cooks.distance(model)
    order_index <- order(score, decreasing = TRUE)
    order_index <- order_index[seq_len(min(n, length(order_index)))]
    return(tibble::tibble(
      participant_key = as.character(frame$participant_key[order_index]),
      influence_screen = "cooks_distance",
      influence_score = as.numeric(score[order_index]),
      screen_rank = seq_along(order_index)
    ))
  }
  residual <- tryCatch(
    abs(stats::residuals(model, type = "pearson")),
    error = function(error) abs(stats::residuals(model))
  )
  scores <- tapply(
    residual,
    as.character(frame$participant_key),
    max,
    na.rm = TRUE
  )
  scores <- sort(scores, decreasing = TRUE)
  scores <- scores[seq_len(min(n, length(scores)))]
  tibble::tibble(
    participant_key = names(scores),
    influence_screen = "maximum_absolute_pearson_residual",
    influence_score = as.numeric(scores),
    screen_rank = seq_along(scores)
  )
}

h05_spearman_interval <- function(rho, n, confidence_level = 0.95) {
  if (!is.finite(rho) || n <= 3L) {
    return(c(NA_real_, NA_real_))
  }
  bounded <- max(min(rho, 1 - 1e-12), -1 + 1e-12)
  alpha <- 1 - confidence_level
  z <- atanh(bounded)
  half_width <- stats::qnorm(1 - alpha / 2) / sqrt(n - 3)
  tanh(c(z - half_width, z + half_width))
}

h05_participant_summary <- function(frame, spec) {
  if (nrow(frame) == 0L) {
    return(tibble::tibble())
  }
  if (spec$analysis_unit == "participant") {
    return(frame |>
      dplyr::transmute(
        participant_key = as.character(.data$participant_key),
        site = as.character(.data$site),
        leba_score = .data$leba_score,
        metric_summary_model_scale = .data$response_value,
        contributing_days = .data$participant_days_contributing
      ))
  }
  frame |>
    dplyr::group_by(.data$participant_key, .data$site) |>
    dplyr::summarise(
      leba_score = dplyr::first(.data$leba_score),
      metric_summary_model_scale = mean(.data$response_value),
      contributing_days = dplyr::n(),
      .groups = "drop"
    ) |>
    dplyr::mutate(
      participant_key = as.character(.data$participant_key),
      site = as.character(.data$site)
    )
}

h05_spearman_summary <- function(participant_summary) {
  data <- participant_summary |>
    dplyr::filter(
      is.finite(.data$metric_summary_model_scale),
      is.finite(.data$leba_score)
    )
  n <- nrow(data)
  rho <- if (n >= 3L) {
    suppressWarnings(stats::cor(
      data$metric_summary_model_scale,
      data$leba_score,
      method = "spearman"
    ))
  } else {
    NA_real_
  }
  interval <- h05_spearman_interval(rho, n)
  tibble::tibble(
    spearman_rho = rho,
    conf_low = interval[[1L]],
    conf_high = interval[[2L]],
    interval_method = "asymptotic_fisher_z_for_spearman",
    pairs = n,
    sites = dplyr::n_distinct(data$site),
    metric_tied_participants = n - dplyr::n_distinct(
      data$metric_summary_model_scale
    ),
    leba_tied_participants = n - dplyr::n_distinct(data$leba_score),
    represented_days = sum(data$contributing_days, na.rm = TRUE),
    p_value_reported = FALSE
  )
}

h05_site_stratified_spearman <- function(participant_summary) {
  participant_summary |>
    dplyr::group_by(.data$site) |>
    dplyr::group_modify(function(data, key) {
      summary <- h05_spearman_summary(
        dplyr::mutate(data, site = key$site)
      )
      summary
    }) |>
    dplyr::ungroup()
}

h05_leave_one_site_out_spearman <- function(participant_summary) {
  sites <- sort(unique(participant_summary$site))
  dplyr::bind_rows(lapply(sites, function(omitted_site) {
    summary <- h05_spearman_summary(
      participant_summary[participant_summary$site != omitted_site, , drop = FALSE]
    )
    dplyr::bind_cols(
      tibble::tibble(omitted_site = omitted_site),
      summary
    )
  }))
}
