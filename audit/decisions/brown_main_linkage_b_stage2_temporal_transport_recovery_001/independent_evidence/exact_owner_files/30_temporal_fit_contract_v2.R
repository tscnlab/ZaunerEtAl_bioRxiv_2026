# Define the frozen temporal ladders with defensive input transport.

lb_load_assignments <- function(path, names, target) {
  expressions <- as.list(parse(path, keep.source = FALSE))
  assignment_name <- function(x)
    if (is.call(x) && identical(x[[1L]], as.name("<-")) && is.symbol(x[[2L]]))
      as.character(x[[2L]]) else ""
  positions <- match(names, vapply(expressions, assignment_name, character(1)))
  stopifnot(!anyNA(positions), !anyDuplicated(positions))
  for (position in positions) eval(expressions[[position]], envir = target)
  invisible(positions)
}

lb_endpoint_ou <- new.env(parent = environment())
lb_load_assignments(
  file.path(historical_root, "08_fit_temporal_ou.R"),
  c(
    "make_temporal_design",
    "make_parameters",
    "make_object",
    "validate_exact_objective",
    "make_grid",
    "make_estimand_object"
  ),
  lb_endpoint_ou
)
lb_bb_ou <- new.env(parent = environment())
lb_load_assignments(
  file.path(historical_root, "08b_fit_temporal_ou_glmmtmb.R"),
  c(
    "formula_r0_ou",
    "formula_r3_ou",
    "prepare_ou_frame",
    "fit_model",
    "extract_ou_parameters",
    "assess_fit",
    "make_grid"
  ),
  lb_bb_ou
)

lb_temporal_prepare <- function(raw_frame) {
  before <- digest::digest(raw_frame, algo = "sha256", serializeVersion = 3L)
  stopifnot(
    inherits(raw_frame$behavior_date, "Date"),
    !anyNA(raw_frame$behavior_date)
  )
  key <- paste(
    raw_frame$participant_state_id,
    as.character(raw_frame$behavior_date),
    sep = "\r"
  )
  stopifnot(!anyDuplicated(key))
  endpoint <- lb_endpoint_ou$make_temporal_design(data.table::copy(raw_frame))
  bb <- lb_bb_ou$prepare_ou_frame(data.table::copy(raw_frame))
  endpoint_index <- match(
    paste(
      endpoint$frame$participant_state_id,
      as.character(endpoint$frame$behavior_date),
      sep = "\r"
    ),
    key
  )
  bb_index <- match(
    paste(bb$participant_state_id, as.character(bb$behavior_date), sep = "\r"),
    key
  )
  endpoint_date <- as.numeric(endpoint$frame$behavior_date)
  previous_date <- c(NA_real_, head(endpoint_date, -1L))
  same_series <- c(
    FALSE,
    head(as.character(endpoint$frame$participant_state_id), -1L) ==
      tail(as.character(endpoint$frame$participant_state_id), -1L)
  )
  expected_gap <- ifelse(same_series, endpoint_date - previous_date, 0)
  coordinates <- as.numeric(glmmTMB::parseNumLevels(levels(
    bb$behavior_date_factor
  ))[, 1L])
  decoded <- coordinates[as.integer(bb$behavior_date_factor)]
  checks <- data.frame(
    check = c(
      "caller_serialization_unchanged",
      "endpoint_rows_permutation",
      "BB_rows_permutation",
      "literal_endpoint_Y_N",
      "literal_BB_Y_N",
      "actual_dates_preserved",
      "date_classes_preserved",
      "endpoint_order_exact",
      "actual_gap_lengths_exact",
      "all_noninitial_gaps_positive",
      "BB_coordinates_are_real_days",
      "factor_levels_preserved"
    ),
    pass = c(
      identical(
        before,
        digest::digest(raw_frame, algo = "sha256", serializeVersion = 3L)
      ),
      !anyNA(endpoint_index) &&
        setequal(endpoint_index, seq_len(nrow(raw_frame))),
      !anyNA(bb_index) && setequal(bb_index, seq_len(nrow(raw_frame))),
      identical(
        as.integer(endpoint$data$y),
        as.integer(raw_frame$brown_yes[endpoint_index])
      ) &&
        identical(
          as.integer(endpoint$data$n),
          as.integer(raw_frame$valid_minutes[endpoint_index])
        ),
      identical(bb$brown_yes, raw_frame$brown_yes[bb_index]) &&
        identical(bb$brown_no, raw_frame$brown_no[bb_index]),
      identical(
        as.numeric(endpoint$frame$behavior_date),
        as.numeric(raw_frame$behavior_date[endpoint_index])
      ) &&
        identical(
          as.numeric(bb$behavior_date),
          as.numeric(raw_frame$behavior_date[bb_index])
        ),
      identical(
        class(endpoint$frame$behavior_date),
        class(raw_frame$behavior_date)
      ) &&
        identical(class(bb$behavior_date), class(raw_frame$behavior_date)),
      identical(
        order(
          as.character(endpoint$frame$participant_state_id),
          endpoint_date,
          method = "radix"
        ),
        seq_len(nrow(raw_frame))
      ),
      identical(
        as.numeric(endpoint$data$ou_gap_days),
        as.numeric(expected_gap)
      ) &&
        identical(
          as.integer(endpoint$data$ou_new_series),
          as.integer(!same_series)
        ),
      all(expected_gap[same_series] > 0),
      identical(
        decoded,
        as.numeric(bb$behavior_date) - min(as.numeric(bb$behavior_date))
      ),
      all(vapply(
        c(
          "analysis_state",
          "site",
          "day_type",
          "participant_id",
          "behavioral_day_id"
        ),
        function(column) {
          expected_levels <- if (column == "behavioral_day_id")
            levels(droplevels(raw_frame[[column]])) else
            levels(raw_frame[[column]])
          identical(expected_levels, levels(endpoint$frame[[column]])) &&
            identical(expected_levels, levels(bb[[column]])) &&
            identical(
              as.character(raw_frame[[column]][endpoint_index]),
              as.character(endpoint$frame[[column]])
            ) &&
            identical(
              as.character(raw_frame[[column]][bb_index]),
              as.character(bb[[column]])
            )
        },
        logical(1)
      ))
    )
  )
  stopifnot(!anyNA(checks$pass), all(checks$pass))
  list(
    endpoint = endpoint,
    bb = bb,
    transport_checks = checks,
    parent_object_sha256 = before
  )
}

# Extract the approved optimizer block verbatim, without the primary likelihood or gate.
source(file.path(code_root, "fit_candidate_interface.R"))
optimizer_body <- as.list(body(ba_lb_fit_candidate))
body_assignment <- function(x)
  if (is.call(x) && identical(x[[1L]], as.name("<-")) && is.symbol(x[[2L]]))
    as.character(x[[2L]]) else ""
optimizer_names <- vapply(optimizer_body, body_assignment, character(1))
optimizer_start <- which(optimizer_names == "fit_started_utc")
optimizer_end <- which(optimizer_names == "optimizer") + 1L
stopifnot(
  length(optimizer_start) == 1L,
  length(optimizer_end) == 1L,
  optimizer_end > optimizer_start,
  identical(
    optimizer_body[[optimizer_end]],
    quote(optimization_log[, selected := seq_len(.N) == selected_index])
  )
)
lb_temporal_optimize <- function(objective) NULL
body(lb_temporal_optimize) <- as.call(c(
  list(as.name("{")),
  optimizer_body[optimizer_start:optimizer_end],
  list(quote(list(
    optimizer = optimizer,
    log = optimization_log,
    seconds = optimization_seconds
  )))
))

lb_temporal_fit_endpoint <- function(input, base_bundle, job) {
  design <- input$endpoint
  stopifnot(identical(
    levels(design$frame$participant_id),
    levels(base_bundle$design_object$frame$participant_id)
  ))
  parameters <- lb_endpoint_ou$make_parameters(design, base_bundle)
  stopifnot(
    nrow(parameters$b_mu_part) == nlevels(design$frame$participant_id),
    ncol(parameters$b_mu_part) == 1L,
    all(vapply(
      c("mu", "zero", "one", "disp"),
      function(component)
        identical(
          colnames(design$data[[paste0("X_", component)]]),
          colnames(base_bundle$design_object$data[[paste0("X_", component)]])
        ),
      logical(1)
    ))
  )
  objective <- lb_endpoint_ou$make_object(design, parameters, random = TRUE)
  warnings <- character()
  optimized <- withCallingHandlers(
    lb_temporal_optimize(objective),
    warning = function(warning) {
      warnings <<- c(warnings, conditionMessage(warning))
      invokeRestart("muffleWarning")
    }
  )
  optimizer <- optimized$optimizer
  objective$env$last.par <- optimizer$last_par_best
  objective$env$last.par.best <- optimizer$last_par_best
  invisible(objective$fn(optimizer$par))
  gradient <- tryCatch(
    objective$gr(optimizer$par),
    error = function(e) rep(NA_real_, length(optimizer$par))
  )
  sd_report <- tryCatch(
    TMB::sdreport(objective, getJointPrecision = FALSE),
    error = function(e) e
  )
  sd_error <- inherits(sd_report, "error")
  covariance <- if (sd_error)
    matrix(NA_real_, length(optimizer$par), length(optimizer$par)) else
    as.matrix(sd_report$cov.fixed)
  fixed_summary <- if (sd_error)
    data.frame(
      parameter = names(optimizer$par),
      estimate = as.numeric(optimizer$par),
      standard_error = NA_real_
    ) else
    data.frame(
      parameter = rownames(summary(sd_report, "fixed")),
      estimate = summary(sd_report, "fixed")[, "Estimate"],
      standard_error = summary(sd_report, "fixed")[, "Std. Error"],
      row.names = NULL
    )
  parameter_list <- objective$env$parList(
    x = optimizer$par,
    par = objective$env$last.par.best
  )
  report <- objective$report()
  endpoint_rows <- grepl("^beta_zero|^beta_one", fixed_summary$parameter)
  finite_covariance <- all(is.finite(covariance))
  min_eigen <- if (finite_covariance)
    min(eigen(covariance, symmetric = TRUE, only.values = TRUE)$values) else
    NA_real_
  gate <- data.frame(
    model_id = job$model_id,
    sample_id = job$sample_id,
    route = "ENDPOINT-R3",
    rows = nrow(design$frame),
    participants = nlevels(design$frame$participant_id),
    convergence = optimizer$convergence,
    maximum_absolute_gradient = if (all(is.finite(gradient)))
      max(abs(gradient)) else NA_real_,
    positive_definite_hessian = !sd_error && isTRUE(sd_report$pdHess),
    covariance_finite = finite_covariance,
    minimum_covariance_eigenvalue = min_eigen,
    maximum_endpoint_coefficient = max(abs(fixed_summary$estimate[
      endpoint_rows
    ])),
    maximum_endpoint_standard_error = max(fixed_summary$standard_error[
      endpoint_rows
    ]),
    participant_standard_deviation = as.numeric(report$participant_sd),
    ou_standard_deviation = as.numeric(report$ou_sd),
    ou_rate_per_day = as.numeric(report$ou_rate),
    ou_half_life_days = as.numeric(report$ou_half_life_days),
    elapsed_seconds = optimized$seconds,
    sdreport_message = if (sd_error) conditionMessage(sd_report) else ""
  )
  criteria <- c(
    convergence = gate$convergence == 0L,
    gradient = is.finite(gate$maximum_absolute_gradient) &&
      gate$maximum_absolute_gradient <= 0.01,
    hessian = gate$positive_definite_hessian,
    covariance = finite_covariance && is.finite(min_eigen) && min_eigen > 0,
    parameters = all(is.finite(optimizer$par)),
    endpoint_coefficient = is.finite(gate$maximum_endpoint_coefficient) &&
      gate$maximum_endpoint_coefficient <= 15,
    endpoint_uncertainty = is.finite(gate$maximum_endpoint_standard_error) &&
      gate$maximum_endpoint_standard_error <= 10,
    participant_sd = is.finite(gate$participant_standard_deviation) &&
      gate$participant_standard_deviation >= 1e-4,
    OU_sd = is.finite(gate$ou_standard_deviation) &&
      gate$ou_standard_deviation >= 1e-4,
    OU_decay = is.finite(gate$ou_rate_per_day) &&
      gate$ou_rate_per_day > 0 &&
      is.finite(gate$ou_half_life_days) &&
      gate$ou_half_life_days > 0
  )
  gate$structural_failure <- !all(criteria)
  gate$fit_status <- if (gate$structural_failure) "structural_failure" else if (
    gate$maximum_absolute_gradient > 0.001 || length(warnings) > 0L
  )
    "acceptable_with_cautions" else "acceptable"
  gate$failure_components <- paste(names(criteria)[!criteria], collapse = ";")
  list(
    model_id = job$model_id,
    sample_id = job$sample_id,
    route = "ENDPOINT-R3",
    design_object = design,
    optimizer = optimizer,
    optimization_log = optimized$log,
    fit_gate = gate,
    fixed_summary = fixed_summary,
    covariance_fixed = covariance,
    parameter_list = parameter_list,
    fixed_parameter_vector = optimizer$par,
    report = report,
    initial_parameters = parameters,
    warnings = warnings,
    accepted = FALSE,
    registered_job = job
  )
}

lb_temporal_fit_bb <- function(input, job) {
  data <- input$bb
  formula <- if (job$route == "BB-R0") lb_bb_ou$formula_r0_ou else
    lb_bb_ou$formula_r3_ou
  result <- lb_bb_ou$fit_model(data, formula)
  gate <- lb_bb_ou$assess_fit(
    result,
    data,
    job$model_id,
    job$sample_id,
    job$route
  )
  valid_decay <- is.finite(gate$ou_decay_rate_per_day) &&
    gate$ou_decay_rate_per_day > 0 &&
    is.finite(gate$ou_half_life_days) &&
    gate$ou_half_life_days > 0
  gate$decay_identifiable <- valid_decay
  gate$structural_failure <- gate$structural_failure || !valid_decay
  if (gate$structural_failure) gate$fit_status <- "structural_failure"
  list(
    model_id = job$model_id,
    sample_id = job$sample_id,
    route = job$route,
    model = result$model,
    data = data,
    fit_gate = gate,
    random_sd = ba_random_sd(result$model),
    warnings = result$warnings,
    formula = formula,
    accepted = FALSE,
    registered_job = job
  )
}

lb_temporal_export_fit <- function(
  bundle,
  relative_output,
  save_rds,
  write_csv
) {
  save_rds(bundle, file.path(relative_output, "model.rds"))
  write_csv(bundle$fit_gate, file.path(relative_output, "fit_gate.csv"))
  write_csv(
    data.frame(
      model_id = bundle$model_id,
      warning = paste(bundle$warnings, collapse = " | "),
      no_primary_substitution = TRUE,
      accepted = FALSE
    ),
    file.path(relative_output, "scope.csv")
  )
  if (bundle$route == "ENDPOINT-R3") {
    write_csv(
      bundle$optimization_log,
      file.path(relative_output, "optimizer.csv")
    )
    write_csv(
      bundle$fixed_summary,
      file.path(relative_output, "fixed_summary.csv")
    )
  } else
    write_csv(bundle$random_sd, file.path(relative_output, "random_sd.csv"))
}
