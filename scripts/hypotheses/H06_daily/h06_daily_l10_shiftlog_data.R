# H06_daily L10 shifted-log frame construction and exact-reuse checks.

h06d_shiftlog_set_factor_contrasts <- function(frame) {
  if (nlevels(frame$site) > 1L) {
    contrasts(frame$site) <- stats::contr.sum(nlevels(frame$site))
  }
  if (nlevels(frame$work_free_day) > 1L) {
    contrast <- stats::contr.treatment(nlevels(frame$work_free_day), base = 1L)
    colnames(contrast) <- levels(frame$work_free_day)[-1L]
    contrasts(frame$work_free_day) <- contrast
  }
  if (nlevels(frame$activity_status) > 1L) {
    contrast <- stats::contr.treatment(
      nlevels(frame$activity_status),
      base = 1L
    )
    colnames(contrast) <- levels(frame$activity_status)[-1L]
    contrasts(frame$activity_status) <- contrast
  }
  frame
}

h06d_shiftlog_read_frame_registry <- function(root) {
  readr::read_csv(
    file.path(
      root,
      "artifacts/06_model_data/H06_daily/",
      "H06_daily_l10_metric011_frame_registry.csv"
    ),
    show_col_types = FALSE,
    na = c("", "NA")
  )
}

h06d_shiftlog_read_parent_frame <- function(root, predictor_id) {
  registry <- h06d_shiftlog_read_frame_registry(root) |>
    dplyr::filter(
      .data$run_id == h06d_shiftlog_pilot_run_id(),
      .data$predictor_id == .env$predictor_id,
      .data$component == "zero_occurrence"
    )
  h06d_shiftlog_assert(
    nrow(registry) == 1L,
    "Shifted-log parent-frame lookup returned %d rows for `%s`",
    nrow(registry),
    predictor_id
  )
  path <- file.path(root, registry$frame_path[[1L]])
  h06d_shiftlog_assert(
    file.exists(path) &&
      h06d_shiftlog_sha256(path) == registry$frame_file_sha256[[1L]],
    "Shifted-log parent-frame file identity failed for `%s`",
    predictor_id
  )
  frame <- readRDS(path)
  h06d_shiftlog_assert(
    h06d_shiftlog_object_sha256(frame) == registry$frame_object_sha256[[1L]],
    "Shifted-log parent-frame object identity failed for `%s`",
    predictor_id
  )
  list(frame = frame, registry = registry)
}

h06d_shiftlog_prepare_frame <- function(parent_frame, predictor) {
  column <- predictor$column[[1L]]
  offset_lx <- h06d_shiftlog_offset_lx()
  h06d_shiftlog_assert(
    all(
      c(
        "site",
        "participant_key",
        "local_date",
        "response_source",
        column
      ) %in%
        names(parent_frame)
    ),
    "Shifted-log parent frame omits required columns for `%s`",
    predictor$predictor_id[[1L]]
  )
  h06d_shiftlog_assert(
    all(is.finite(parent_frame$response_source)) &&
      all(parent_frame$response_source >= 0),
    "Shifted-log source response is nonfinite or below zero"
  )
  frame <- parent_frame |>
    dplyr::mutate(
      response_value = log10(.data$response_source + .env$offset_lx)
    )
  duplicate <- frame |>
    dplyr::count(.data$site, .data$participant_key, .data$local_date) |>
    dplyr::filter(.data$n != 1L)
  h06d_shiftlog_assert(
    nrow(duplicate) == 0L &&
      all(is.finite(frame$response_value)) &&
      all(frame$response_value[frame$response_source == 0] == -1),
    "Shifted-log response or participant-day key contract failed"
  )
  frame
}

h06d_shiftlog_formula_text <- function(formula) {
  paste(deparse(formula, width.cutoff = 500L), collapse = " ")
}

h06d_shiftlog_fixed_matrix <- function(formula, frame) {
  fixed_formula <- reformulas::nobars(formula)
  stats::model.matrix(fixed_formula, data = frame)
}

h06d_shiftlog_reuse_verification <- function(
  current_frame,
  predictor,
  historical_capture,
  bundle_package_versions
) {
  model <- historical_capture$value
  formulas <- h06d_shiftlog_formula_set(predictor$column[[1L]])
  expected_formula <- formulas$fixed_site_additive
  expected_matrix <- h06d_shiftlog_fixed_matrix(expected_formula, current_frame)
  model_matrix <- lme4::getME(model, "X")
  model_response <- stats::model.response(stats::model.frame(model))
  current_package_versions <- vapply(
    names(bundle_package_versions),
    function(package) as.character(utils::packageVersion(package)),
    character(1)
  )
  optimization_messages <- unlist(
    model@optinfo$conv$lme4$messages,
    use.names = FALSE
  )
  gradient <- model@optinfo$derivs$gradient
  maximum_gradient <- if (is.null(gradient)) 0 else max(abs(gradient))

  verification <- tibble::tibble(
    predictor_order = predictor$predictor_order[[1L]],
    predictor_id = predictor$predictor_id[[1L]],
    historical_subobject_path = paste0(
      "$models$`",
      h06d_shiftlog_model_key(
        h06d_shiftlog_pilot_run_id(),
        predictor$predictor_id[[1L]]
      ),
      "`$one_part"
    ),
    frame_object_identical = identical(current_frame, historical_capture$frame),
    response_identical = identical(
      current_frame$response_value,
      historical_capture$frame$response_value
    ) &&
      isTRUE(all.equal(
        model_response,
        current_frame$response_value,
        check.attributes = FALSE
      )),
    source_response_identical = identical(
      current_frame$response_source,
      historical_capture$frame$response_source
    ),
    formula_identical = identical(
      h06d_shiftlog_formula_text(stats::formula(model)),
      h06d_shiftlog_formula_text(expected_formula)
    ),
    fixed_matrix_identical = isTRUE(all.equal(
      expected_matrix,
      model_matrix,
      check.attributes = FALSE,
      tolerance = 0
    )) &&
      identical(dim(expected_matrix), dim(model_matrix)) &&
      identical(colnames(expected_matrix), colnames(model_matrix)),
    contrast_attributes_identical = identical(
      attr(expected_matrix, "contrasts"),
      attr(model_matrix, "contrasts")
    ),
    gaussian_identity_lmm = inherits(model, "lmerMod") && lme4::isLMM(model),
    reml_identical = isTRUE(lme4::isREML(model)),
    optimizer_identical = identical(model@optinfo$optimizer, "nloptwrap"),
    r_version_identical = identical(as.character(getRversion()), "4.6.1"),
    package_versions_identical = identical(
      unname(current_package_versions),
      unname(bundle_package_versions)
    ) &&
      identical(
        names(current_package_versions),
        names(bundle_package_versions)
      ),
    no_captured_error = is.na(historical_capture$error),
    no_captured_warning = length(historical_capture$warnings) == 0L,
    converged = length(optimization_messages) == 0L &&
      is.finite(maximum_gradient) &&
      maximum_gradient <= 0.002,
    singular = lme4::isSingular(model, tol = 1e-4),
    maximum_absolute_gradient = maximum_gradient,
    historical_model_object_sha256 = h06d_shiftlog_object_sha256(model),
    historical_capture_object_sha256 = h06d_shiftlog_object_sha256(
      historical_capture
    )
  )
  required <- verification |>
    dplyr::select(
      "frame_object_identical",
      "response_identical",
      "source_response_identical",
      "formula_identical",
      "fixed_matrix_identical",
      "contrast_attributes_identical",
      "gaussian_identity_lmm",
      "reml_identical",
      "optimizer_identical",
      "r_version_identical",
      "package_versions_identical",
      "no_captured_error",
      "no_captured_warning",
      "converged"
    )
  verification |>
    dplyr::mutate(
      exact_reuse_authorized = all(unlist(required, use.names = FALSE)) &&
        !.data$singular,
      reuse_disposition = ifelse(
        .data$exact_reuse_authorized,
        "REUSE_EXACT_HISTORICAL_REML_ADDITIVE_OBJECT",
        "REFIT_REQUIRED_AFTER_COMPUTE_CLEARANCE"
      )
    )
}

h06d_shiftlog_frame_summary <- function(frame, predictor) {
  column <- predictor$column[[1L]]
  categorical_cells <- if (predictor$type[[1L]] == "categorical") {
    frame |>
      dplyr::count(
        .data$site,
        category = as.character(.data[[column]]),
        name = "participant_days"
      )
  } else {
    tibble::tibble()
  }
  tibble::tibble(
    predictor_order = predictor$predictor_order[[1L]],
    predictor_id = predictor$predictor_id[[1L]],
    participant_days = nrow(frame),
    participants = dplyr::n_distinct(frame$participant_key),
    sites = dplyr::n_distinct(frame$site),
    exact_zeros = sum(frame$response_source == 0),
    exact_zero_fraction = mean(frame$response_source == 0),
    positive_values = sum(frame$response_source > 0),
    response_source_minimum_lx = min(frame$response_source),
    response_source_median_lx = stats::median(frame$response_source),
    response_source_maximum_lx = max(frame$response_source),
    transformed_minimum = min(frame$response_value),
    transformed_median = stats::median(frame$response_value),
    transformed_maximum = max(frame$response_value),
    category_cells = if (nrow(categorical_cells)) nrow(categorical_cells) else
      NA_integer_,
    minimum_category_cell_days = if (nrow(categorical_cells)) {
      min(categorical_cells$participant_days)
    } else {
      NA_integer_
    },
    frame_object_sha256 = h06d_shiftlog_object_sha256(frame)
  )
}
