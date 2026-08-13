# Run the H06-D-007 bounded remaining-non-L10 production-code pilot.

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

required_packages <- c(
  "digest", "dplyr", "tidyr", "tibble", "readr", "lme4", "glmmTMB",
  "performance", "emmeans", "mgcv", "melidosData", "LightLogR"
)
missing_packages <- required_packages[!vapply(
  required_packages,
  requireNamespace,
  logical(1),
  quietly = TRUE
)]
if (length(missing_packages) > 0L) {
  stop(
    "Missing synchronized project package(s): ",
    paste(missing_packages, collapse = ", "),
    call. = FALSE
  )
}

suppressPackageStartupMessages({
  library(digest)
  library(dplyr)
  library(tidyr)
  library(tibble)
  library(readr)
  library(lme4)
  library(glmmTMB)
  library(performance)
  library(emmeans)
})

source(file.path(
  root,
  "scripts/hypotheses/H06_daily/h06_daily_non_l10_pilot_contract.R"
))
source(file.path(
  root,
  "scripts/hypotheses/H06_daily/h06_daily_non_l10_pilot_data.R"
))
source(file.path(
  root,
  "scripts/hypotheses/H06_daily/h06_daily_non_l10_pilot_modeling.R"
))

h06d_nl_assert(
  identical(as.character(getRversion()), "4.6.1"),
  "H06-D-007 pilot requires R 4.6.1; found %s",
  as.character(getRversion())
)
h06d_nl_assert(
  identical(as.character(utils::packageVersion("melidosData")), "1.0.6"),
  "H06-D-007 pilot requires immutable melidosData 1.0.6"
)

pilot_id <- "H06-D-G2P-NONL10"
producer <- "scripts/hypotheses/H06_daily/run_h06_daily_non_l10_pilot.R"
artifact_roots <- h06d_nl_artifact_roots(root)
invisible(lapply(
  artifact_roots,
  dir.create,
  recursive = TRUE,
  showWarnings = FALSE
))

write_csv_atomic <- function(data, path) {
  temporary <- tempfile(
    pattern = paste0(basename(path), "-"),
    tmpdir = dirname(path),
    fileext = ".tmp"
  )
  readr::write_csv(data, temporary, na = "")
  if (!file.rename(temporary, path)) {
    unlink(temporary)
    h06d_nl_abort("Could not atomically write `%s`", path)
  }
  invisible(path)
}

write_rds_atomic <- function(object, path) {
  temporary <- tempfile(
    pattern = paste0(basename(path), "-"),
    tmpdir = dirname(path),
    fileext = ".tmp"
  )
  saveRDS(object, temporary, version = 3)
  if (!file.rename(temporary, path)) {
    unlink(temporary)
    h06d_nl_abort("Could not atomically write `%s`", path)
  }
  invisible(path)
}

relative_path <- function(path) {
  sub(paste0("^", root, "/?"), "", normalizePath(
    path,
    winslash = "/",
    mustWork = FALSE
  ))
}

file_identity <- function(path) {
  h06d_nl_assert(file.exists(path), "Missing file `%s`", path)
  tibble::tibble(
    relative_path = relative_path(path),
    sha256 = h06d_nl_sha256(path),
    bytes = unname(file.info(path)$size)
  )
}

message("H06-D-007: verifying the current-source contract")
input_contract <- h06d_nl_input_contract() |>
  dplyr::mutate(
    absolute_path = file.path(root, .data$relative_path),
    actual_sha256 = vapply(
      .data$absolute_path,
      h06d_nl_sha256,
      character(1)
    ),
    bytes = unname(file.info(.data$absolute_path)$size),
    verification_status = ifelse(
      .data$actual_sha256 == .data$expected_sha256,
      "PASS",
      "FAIL"
    )
  ) |>
  dplyr::select(-"absolute_path")
h06d_nl_assert(
  all(input_contract$verification_status == "PASS"),
  "A sealed H06-D-007 input identity changed; no model was fitted"
)

primary_invariance <- readr::read_csv(
  file.path(
    root,
    "artifacts/08_diagnostics/mder_METRIC-010/non_mder_invariance.csv"
  ),
  show_col_types = FALSE
)
gap_invariance <- readr::read_csv(
  file.path(
    root,
    paste0(
      "audit/reconciliation/mder_METRIC-010_gap_repair/",
      "gap_non_mder_invariance.csv"
    )
  ),
  show_col_types = FALSE
)
l10_invariance <- readr::read_csv(
  file.path(
    root,
    "audit/reconciliation/l10_METRIC-011/invariance_summary.csv"
  ),
  show_col_types = FALSE
)
h06d_nl_assert(
  nrow(primary_invariance) == 2L &&
    all(primary_invariance$shared_non_mder_columns == 43L) &&
    all(primary_invariance$columns_with_any_difference == 0L) &&
    all(primary_invariance$differing_cells == 0L) &&
    all(primary_invariance$exact_non_mder_invariance),
  "METRIC-010 primary non-MDER invariance evidence failed"
)
h06d_nl_assert(
  identical(
    gap_invariance$value[gap_invariance$check == "non_mder_rows_before"],
    "25620"
  ) && identical(
    gap_invariance$value[gap_invariance$check == "non_mder_rows_after"],
    "25620"
  ) && identical(
    gap_invariance$value[
      gap_invariance$check == "non_mder_cells_exactly_unchanged"
    ],
    "TRUE"
  ) && identical(
    gap_invariance$value[
      gap_invariance$check == "shared_independent_verifier_status"
    ],
    "PASS"
  ),
  "METRIC-010 gap non-MDER invariance evidence failed"
)
h06d_nl_assert(
  identical(
    l10_invariance$status[
      l10_invariance$check == "primary_non_L10_metrics"
    ],
    "PASS"
  ) && identical(
    l10_invariance$status[
      l10_invariance$check == "H01_gap_timing_unaware_data"
    ],
    "PASS"
  ),
  "METRIC-011 non-L10 invariance evidence failed"
)

protected_roots <- c(
  "audit/hypotheses/H06_daily",
  "scripts/hypotheses/H06_daily",
  "tests/hypotheses/H06_daily",
  "artifacts/06_model_data/H06_daily",
  "artifacts/07_models/H06_daily",
  "artifacts/08_diagnostics/H06_daily",
  "artifacts/09_tables/H06_daily",
  "artifacts/10_figures/H06_daily",
  "artifacts/11_source_data/H06_daily",
  "artifacts/12_manifests/H06_daily"
)
protected_explicit <- c(
  "audit/handoffs/H06_daily_worker_handoff.md",
  "audit/handoffs/H06_daily_shared_change_request.md"
)
protected_files <- unique(c(
  unlist(lapply(protected_roots, function(path) {
    full <- file.path(root, path)
    if (!dir.exists(full)) return(character())
    list.files(full, recursive = TRUE, full.names = TRUE, all.files = TRUE)
  }), use.names = FALSE),
  file.path(root, protected_explicit)
))
protected_files <- protected_files[
  file.exists(protected_files) &
    !dir.exists(protected_files) &
    !grepl("non_l10", protected_files, ignore.case = TRUE)
]
protected_files <- sort(normalizePath(protected_files, winslash = "/"))
protected_baseline <- dplyr::bind_rows(lapply(
  protected_files,
  file_identity
)) |>
  dplyr::arrange(.data$relative_path)
h06d_nl_assert(
  nrow(protected_baseline) >= 100L,
  "The frozen H06_daily preservation baseline is unexpectedly small"
)

message("H06-D-007: reconciling current scientific sources and frames")
representation_reconciliation <- h06d_nl_current_long_reconciliation(root)
h06d_nl_assert(
  nrow(representation_reconciliation) == 26L &&
    all(representation_reconciliation$exact_reconciliation) &&
    max(representation_reconciliation$maximum_relative_difference) <= 1e-12,
  "Current wide and long non-L10 metric representations do not reconcile"
)

source_data <- h06d_nl_load_sources(root)
frame_build <- h06d_nl_build_frames(source_data, retain_frames = TRUE)
frame_inventory <- frame_build$inventory
frames <- frame_build$frames
h06d_nl_assert(
  nrow(frame_inventory) == 13L * 3L * 12L &&
    all(frame_inventory$metric_slot %in% c(1L, 2L, 4L:14L)) &&
    !any(frame_inventory$metric_slot %in% c(3L, 15L)),
  "The current H06_daily non-L10 frame inventory is not the authorized grid"
)

input_manifest_path <- file.path(
  artifact_roots$manifests,
  "H06_daily_non_l10_pilot_input_manifest.csv"
)
inventory_path <- file.path(
  artifact_roots$model_data,
  "H06_daily_non_l10_pilot_frame_inventory.csv"
)
reconciliation_path <- file.path(
  artifact_roots$diagnostics,
  "H06_daily_non_l10_pilot_source_reconciliation.csv"
)
preservation_baseline_path <- file.path(
  artifact_roots$diagnostics,
  "H06_daily_non_l10_pilot_preservation_baseline.csv"
)
write_csv_atomic(input_contract, input_manifest_path)
write_csv_atomic(frame_inventory, inventory_path)
write_csv_atomic(representation_reconciliation, reconciliation_path)
write_csv_atomic(protected_baseline, preservation_baseline_path)

message("H06-D-007: verifying exact historical analytical-frame reuse")
historical_environment <- new.env(parent = globalenv())
sys.source(
  file.path(root, "scripts/hypotheses/H06_daily/h06_daily_contract.R"),
  historical_environment
)
sys.source(
  file.path(root, "scripts/hypotheses/H06_daily/h06_daily_data.R"),
  historical_environment
)
sys.source(
  file.path(root, "scripts/hypotheses/H06_daily/h06_daily_modeling.R"),
  historical_environment
)
historical_composite_path <- file.path(
  artifact_roots$models,
  "H06_daily_stage2_pilot_daily_models.rds"
)
historical_composite <- readRDS(historical_composite_path)
reuse_registry <- h06d_nl_reuse_registry()
historical_diaries <- historical_environment$h06d_load_diaries(root)
historical_software <- readr::read_csv(
  file.path(
    artifact_roots$manifests,
    "H06_daily_stage2_pilot_software_manifest.csv"
  ),
  show_col_types = FALSE
)
installed_versions <- c(
  R = as.character(getRversion()),
  vapply(
    setdiff(historical_software$item, "R"),
    function(package) as.character(utils::packageVersion(package)),
    character(1)
  )
)
software_exact <- all(
  historical_software$version == installed_versions[historical_software$item]
)
h06d_nl_assert(
  software_exact,
  "Historical pilot software does not match the synchronized project library"
)

strip_metric_settings <- function(frame) {
  attr(frame, "metric_settings") <- NULL
  frame
}

model_family_identity <- function(model) {
  family <- stats::family(model)
  paste(family$family, family$link, sep = "/")
}

reuse_rows <- list()
reuse_bundle <- list()
for (reuse_index in seq_len(nrow(reuse_registry))) {
  reuse <- reuse_registry[reuse_index, ]
  member <- reuse$historical_member[[1L]]
  h06d_nl_assert(
    member %in% names(historical_composite),
    "Missing authorized historical non-L10 member `%s`",
    member
  )
  stored <- historical_composite[[member]]
  current <- historical_environment$h06d_daily_frame(
    root = root,
    placement = "near_eye",
    metric_id = reuse$metric_id[[1L]],
    predictor_id = reuse$predictor_id[[1L]],
    diaries = historical_diaries
  ) |>
    historical_environment$h06d_prepare_daily_response(
      reuse$response_transform[[1L]]
    )
  current_without_settings <- strip_metric_settings(current)
  stored_without_settings <- strip_metric_settings(stored$frame)
  raw_frame_identical <- identical(current, stored$frame)
  analytical_frame_identical <- identical(
    current_without_settings,
    stored_without_settings
  )
  only_metric_settings_attribute_changed <-
    !raw_frame_identical && analytical_frame_identical
  stored_model_frame <- stats::model.frame(stored$model)
  model_frame_columns <- names(stored_model_frame)
  model_frame_identical <- all(model_frame_columns %in% names(current)) &&
    nrow(stored_model_frame) == nrow(current) &&
    identical(row.names(stored_model_frame), row.names(current)) &&
    all(vapply(
      model_frame_columns,
      function(column) identical(
        current[[column]],
        stored_model_frame[[column]]
      ),
      logical(1)
    ))
  current_design <- stats::model.matrix(
    reformulas::nobars(stored$formula),
    data = current
  )
  stored_design <- if (inherits(stored$model, "merMod")) {
    lme4::getME(stored$model, "X")
  } else {
    stats::model.matrix(stored$model)
  }
  design_matrix_identical <- identical(dim(current_design), dim(stored_design)) &&
    identical(colnames(current_design), colnames(stored_design)) &&
    identical(as.vector(current_design), as.vector(stored_design))
  formula_identical <- identical(
    paste(deparse(stored$formula), collapse = " "),
    paste(deparse(stats::formula(stored$model)), collapse = " ")
  )
  response_identical <- identical(
    current$response_value,
    stored$frame$response_value
  ) && identical(current$response_source, stored$frame$response_source)
  contrasts_identical <- identical(
    contrasts(current$site),
    contrasts(stored$frame$site)
  )
  expected_family <- if (reuse$response_family[[1L]] == "gaussian") {
    "gaussian/identity"
  } else {
    "tweedie/log"
  }
  family_identical <- identical(
    model_family_identity(stored$model),
    expected_family
  )
  status <- h06d_nl_model_status(stored$model)
  optimizer_identical <- if (inherits(stored$model, "merMod")) {
    identical(as.character(stored$model@optinfo$optimizer), "nloptwrap")
  } else {
    grepl("10000", paste(deparse(stored$model$call$control), collapse = " "))
  }
  warning_identity <- identical(stored$warnings, character())
  reuse_pass <- analytical_frame_identical && model_frame_identical &&
    design_matrix_identical && formula_identical && response_identical &&
    contrasts_identical && family_identical && optimizer_identical &&
    warning_identity && software_exact && isTRUE(status$converged) &&
    isTRUE(status$positive_definite_hessian) && !isTRUE(status$singular)
  reuse_rows[[member]] <- dplyr::bind_cols(
    reuse,
    tibble::tibble(
      historical_composite_sha256 = h06d_nl_sha256(
        historical_composite_path
      ),
      historical_subobject_path = member,
      historical_model_serialized_sha256 = digest::digest(
        stored$model,
        algo = "sha256",
        serialize = TRUE
      ),
      raw_frame_object_identical = raw_frame_identical,
      only_global_metric_settings_attribute_changed =
        only_metric_settings_attribute_changed,
      analytical_frame_identical = analytical_frame_identical,
      model_frame_identical = model_frame_identical,
      response_and_source_identical = response_identical,
      formula_identical = formula_identical,
      design_matrix_identical = design_matrix_identical,
      site_contrasts_identical = contrasts_identical,
      family_link_identical = family_identical,
      optimizer_identical = optimizer_identical,
      warnings_identical_empty = warning_identity,
      software_identity = software_exact,
      converged = status$converged,
      positive_definite_hessian = status$positive_definite_hessian,
      singular = status$singular,
      participant_days = nrow(current),
      participants = dplyr::n_distinct(current$participant_key),
      sites = dplyr::n_distinct(current$site),
      reuse_disposition = ifelse(
        reuse_pass,
        "REUSE_EXACT_HISTORICAL_REML_ADDITIVE_OBJECT",
        "REFIT_REQUIRED_NOT_AUTHORIZED_IN_REUSE_STEP"
      )
    )
  )
  reuse_bundle[[member]] <- list(
    parent_path = relative_path(historical_composite_path),
    parent_sha256 = h06d_nl_sha256(historical_composite_path),
    subobject_path = member,
    frame = stored$frame,
    formula = stored$formula,
    model = stored$model,
    warnings = stored$warnings,
    error = stored$error,
    elapsed_seconds = stored$elapsed_seconds,
    registry = stored$registry
  )
}
reuse_verification <- dplyr::bind_rows(reuse_rows)
reuse_path <- file.path(
  artifact_roots$models,
  "H06_daily_non_l10_pilot_reused_historical_objects.rds"
)
reuse_verification_path <- file.path(
  artifact_roots$diagnostics,
  "H06_daily_non_l10_pilot_reuse_verification.csv"
)
write_csv_atomic(reuse_verification, reuse_verification_path)
h06d_nl_assert(
  nrow(reuse_verification) == 3L && all(
    reuse_verification$reuse_disposition ==
      "REUSE_EXACT_HISTORICAL_REML_ADDITIVE_OBJECT"
  ),
  "At least one authorized historical analytical object failed exact reuse"
)
write_rds_atomic(reuse_bundle, reuse_path)

message("H06-D-007: fitting 15 primary near-eye timing cells serially")
metrics <- h06d_nl_metric_registry()
predictors <- h06d_nl_predictor_registry()
timing_metrics <- metrics |>
  dplyr::filter(.data$is_timing) |>
  dplyr::arrange(.data$metric_slot)
timing_results <- list()
timing_meta <- list()
timing_diagnostics <- list()
timing_effects <- list()
timing_marginals <- list()
timing_tests <- list()
timing_lag <- list()
timing_post_ar_lag <- list()
timing_ar_effects <- list()
timing_benchmarks <- list()
timing_model_counts <- list()
timing_started <- proc.time()[["elapsed"]]

for (metric_index in seq_len(nrow(timing_metrics))) {
  metric <- timing_metrics[metric_index, ]
  for (predictor_index in seq_len(nrow(predictors))) {
    predictor <- predictors[predictor_index, ]
    key <- paste(
      "primary__near_eye__all_available",
      metric$metric_id[[1L]],
      predictor$predictor_id[[1L]],
      sep = "__"
    )
    frame <- frames[[key]]
    h06d_nl_assert(!is.null(frame), "Missing timing pilot frame `%s`", key)
    cell_id <- paste(
      metric$metric_id[[1L]],
      predictor$predictor_id[[1L]],
      sep = "__"
    )
    message("  timing cell: ", cell_id)
    outer <- h06d_nl_capture(h06d_nl_fit_clock_cell(
      frame,
      metric,
      predictor
    ))
    metadata <- tibble::tibble(
      pilot_id = pilot_id,
      cell_id = cell_id,
      frame_key = key,
      metric_slot = metric$metric_slot[[1L]],
      metric_id = metric$metric_id[[1L]],
      manuscript_name = metric$manuscript_name[[1L]],
      predictor_order = predictor$predictor_order[[1L]],
      predictor_id = predictor$predictor_id[[1L]],
      predictor = predictor$reader_name[[1L]],
      response_transform = metric$response_transform[[1L]],
      participant_days = nrow(frame),
      participants = dplyr::n_distinct(frame$participant_key),
      sites = dplyr::n_distinct(frame$site),
      exact_source_zeros = sum(frame$response_source == 0),
      frame_object_sha256 = digest::digest(
        frame,
        algo = "sha256",
        serialize = TRUE
      ),
      total_cell_elapsed_seconds = outer$elapsed_seconds,
      outer_warning_count = length(outer$warnings),
      outer_warnings = paste(outer$warnings, collapse = " | "),
      outer_error = outer$error
    )
    timing_meta[[cell_id]] <- metadata
    if (is.null(outer$value)) {
      timing_diagnostics[[cell_id]] <- metadata |>
        dplyr::mutate(
          diagnostic_disposition = "NOT_ACCEPTABLE_FIT_FAILURE"
        )
      timing_model_counts[[cell_id]] <- metadata |>
        dplyr::transmute(
          dplyr::across(dplyr::everything()),
          model_components_attempted = 1L,
          model_components_fitted = 0L
        )
      next
    }
    result <- outer$value
    timing_results[[cell_id]] <- result
    fitted_components <- sum(vapply(
      result$models,
      function(entry) {
        !is.null(entry) && !is.null(entry$value)
      },
      logical(1)
    ))
    attempted_components <- sum(vapply(
      result$models,
      function(entry) !is.null(entry),
      logical(1)
    ))
    timing_model_counts[[cell_id]] <- metadata |>
      dplyr::transmute(
        dplyr::across(dplyr::everything()),
        model_components_attempted = attempted_components,
        model_components_fitted = fitted_components
      )
    timing_diagnostics[[cell_id]] <- dplyr::bind_cols(
      metadata,
      result$diagnostics
    )
    timing_effects[[cell_id]] <- dplyr::bind_cols(
      metadata,
      result$effect |>
        dplyr::select(-dplyr::any_of(names(metadata)))
    )
    timing_marginals[[cell_id]] <- result$marginal |>
      dplyr::mutate(
        pilot_id = .env$pilot_id,
        cell_id = .env$cell_id,
        .before = 1L
      )
    timing_tests[[cell_id]] <- result$tests |>
      dplyr::mutate(
        pilot_id = .env$pilot_id,
        cell_id = .env$cell_id,
        metric_slot = metric$metric_slot[[1L]],
        metric_id = metric$metric_id[[1L]],
        predictor_order = predictor$predictor_order[[1L]],
        predictor_id = predictor$predictor_id[[1L]],
        multiplicity_status = "PILOT_RAW_ONLY_NO_BH",
        .before = 1L
      )
    timing_lag[[cell_id]] <- result$lag_by_site |>
      dplyr::mutate(
        pilot_id = .env$pilot_id,
        cell_id = .env$cell_id,
        metric_id = metric$metric_id[[1L]],
        predictor_id = predictor$predictor_id[[1L]],
        .before = 1L
      )
    timing_post_ar_lag[[cell_id]] <- result$post_ar_lag_by_site |>
      dplyr::mutate(
        pilot_id = .env$pilot_id,
        cell_id = .env$cell_id,
        metric_id = metric$metric_id[[1L]],
        predictor_id = predictor$predictor_id[[1L]],
        .before = 1L
      )
    timing_ar_effects[[cell_id]] <- result$ar_effect |>
      dplyr::mutate(
        pilot_id = .env$pilot_id,
        cell_id = .env$cell_id,
        metric_id = metric$metric_id[[1L]],
        predictor_id = predictor$predictor_id[[1L]],
        .before = 1L
      )
    timing_benchmarks[[cell_id]] <- result$benchmark |>
      dplyr::mutate(
        pilot_id = .env$pilot_id,
        cell_id = .env$cell_id,
        metric_id = metric$metric_id[[1L]],
        .before = 1L
      )
  }
}
timing_elapsed <- unname(proc.time()[["elapsed"]] - timing_started)
timing_diagnostic_table <- dplyr::bind_rows(timing_diagnostics)
timing_effect_table <- dplyr::bind_rows(timing_effects)
timing_marginal_table <- dplyr::bind_rows(timing_marginals)
timing_test_table <- dplyr::bind_rows(timing_tests)
timing_lag_table <- dplyr::bind_rows(timing_lag)
timing_post_ar_lag_table <- dplyr::bind_rows(timing_post_ar_lag)
timing_ar_effect_table <- dplyr::bind_rows(timing_ar_effects)
timing_benchmark_table <- dplyr::bind_rows(timing_benchmarks)
timing_model_count_table <- dplyr::bind_rows(timing_model_counts)
h06d_nl_assert(
  nrow(timing_diagnostic_table) == 15L,
  "The timing pilot did not return all 15 declared cells"
)
h06d_nl_assert(
  nrow(timing_test_table) <= 30L &&
    !any(grepl("adjust|BH|q_value", names(timing_test_table), ignore.case = TRUE)),
  "The bounded timing pilot unexpectedly produced multiplicity fields"
)

timing_frame_path <- file.path(
  artifact_roots$model_data,
  "H06_daily_non_l10_pilot_timing_frames.rds"
)
timing_model_path <- file.path(
  artifact_roots$models,
  "H06_daily_non_l10_pilot_timing_models.rds"
)
timing_diagnostic_path <- file.path(
  artifact_roots$diagnostics,
  "H06_daily_non_l10_pilot_timing_diagnostics.csv"
)
timing_model_count_path <- file.path(
  artifact_roots$diagnostics,
  "H06_daily_non_l10_pilot_timing_model_counts.csv"
)
timing_lag_path <- file.path(
  artifact_roots$diagnostics,
  "H06_daily_non_l10_pilot_timing_lag_by_site.csv"
)
timing_post_ar_lag_path <- file.path(
  artifact_roots$diagnostics,
  "H06_daily_non_l10_pilot_timing_post_ar_lag_by_site.csv"
)
timing_benchmark_path <- file.path(
  artifact_roots$diagnostics,
  "H06_daily_non_l10_pilot_timing_registered_benchmarks.csv"
)
timing_effect_path <- file.path(
  artifact_roots$tables,
  "H06_daily_non_l10_pilot_timing_effects.csv"
)
timing_marginal_path <- file.path(
  artifact_roots$tables,
  "H06_daily_non_l10_pilot_timing_equal_site_marginals.csv"
)
timing_test_path <- file.path(
  artifact_roots$tables,
  "H06_daily_non_l10_pilot_timing_raw_tests.csv"
)
timing_ar_effect_path <- file.path(
  artifact_roots$tables,
  "H06_daily_non_l10_pilot_timing_ar_effects.csv"
)
timing_frames <- frames[grepl(
  "^primary__near_eye__all_available__.*(midpoint|timing)",
  names(frames)
)]
write_rds_atomic(timing_frames, timing_frame_path)
write_rds_atomic(
  list(
    gate = pilot_id,
    results = timing_results,
    metadata = dplyr::bind_rows(timing_meta),
    r_version = as.character(getRversion()),
    package_versions = vapply(
      required_packages,
      function(package) as.character(utils::packageVersion(package)),
      character(1)
    )
  ),
  timing_model_path
)
write_csv_atomic(timing_diagnostic_table, timing_diagnostic_path)
write_csv_atomic(timing_model_count_table, timing_model_count_path)
write_csv_atomic(timing_lag_table, timing_lag_path)
write_csv_atomic(timing_post_ar_lag_table, timing_post_ar_lag_path)
write_csv_atomic(timing_benchmark_table, timing_benchmark_path)
write_csv_atomic(timing_effect_table, timing_effect_path)
write_csv_atomic(timing_marginal_table, timing_marginal_path)
write_csv_atomic(timing_test_table, timing_test_path)
write_csv_atomic(timing_ar_effect_table, timing_ar_effect_path)

acceptable_cells <- timing_diagnostic_table |>
  dplyr::filter(grepl("^ACCEPTABLE", .data$diagnostic_disposition))
ordinary_candidate <- acceptable_cells |>
  dplyr::filter(.data$response_transform == "clock_hours") |>
  dplyr::arrange(.data$metric_slot, .data$predictor_order) |>
  dplyr::slice_head(n = 1L)
strict_candidate <- acceptable_cells |>
  dplyr::filter(.data$response_transform == "clock_hours_midnight_after_16") |>
  dplyr::arrange(.data$predictor_order) |>
  dplyr::slice_head(n = 1L)
if (nrow(strict_candidate) == 0L) {
  strict_candidate <- timing_diagnostic_table |>
    dplyr::filter(
      .data$response_transform == "clock_hours_midnight_after_16",
      is.na(.data$outer_error)
    ) |>
    dplyr::arrange(.data$predictor_order) |>
    dplyr::slice_head(n = 1L)
}
h06d_nl_assert(
  nrow(ordinary_candidate) == 1L && nrow(strict_candidate) == 1L,
  paste0(
    "The clock pilot lacks an acceptable ordinary candidate or a fitted ",
    "strict-after-16:00 runtime representative; the authorized deletion ",
    "pilot was not started"
  )
)

message("H06-D-007: running exactly 50 serial deletion refits")
select_metric <- function(metric_id) {
  output <- metrics |>
    dplyr::filter(.data$metric_id == .env$metric_id)
  h06d_nl_assert(nrow(output) == 1L, "Could not select metric `%s`", metric_id)
  output
}
select_predictor <- function(predictor_id) {
  output <- predictors |>
    dplyr::filter(.data$predictor_id == .env$predictor_id)
  h06d_nl_assert(
    nrow(output) == 1L,
    "Could not select predictor `%s`",
    predictor_id
  )
  output
}

deletion_classes <- list()
for (reuse_index in seq_len(nrow(reuse_registry))) {
  reuse <- reuse_registry[reuse_index, ]
  stored <- reuse_bundle[[reuse$historical_member[[1L]]]]
  metric <- select_metric(reuse$metric_id[[1L]])
  predictor <- select_predictor(reuse$predictor_id[[1L]])
  full_effect <- h06d_nl_effect_row(stored$model, predictor, metric)
  deletion_classes[[reuse$reuse_id[[1L]]]] <- list(
    class_id = reuse$reuse_id[[1L]],
    frame = stored$frame,
    model = stored$model,
    metric = metric,
    predictor = predictor,
    full_effect = full_effect$estimate[[1L]],
    full_standard_error = full_effect$standard_error[[1L]],
    source = "exact_reused_historical_additive_object"
  )
}

add_timing_deletion_class <- function(candidate, class_id) {
  cell_id <- candidate$cell_id[[1L]]
  result <- timing_results[[cell_id]]
  metadata <- timing_meta[[cell_id]]
  metric <- select_metric(metadata$metric_id[[1L]])
  predictor <- select_predictor(metadata$predictor_id[[1L]])
  frame <- frames[[metadata$frame_key[[1L]]]]
  full_effect <- h06d_nl_effect_row(
    result$models$additive_reml$value,
    predictor,
    metric
  )
  list(
    class_id = class_id,
    frame = frame,
    model = result$models$additive_reml$value,
    metric = metric,
    predictor = predictor,
    full_effect = full_effect$estimate[[1L]],
    full_standard_error = full_effect$standard_error[[1L]],
    source = paste0(
      "timing_pilot_cell:",
      cell_id,
      ":",
      candidate$diagnostic_disposition[[1L]],
      if (grepl("^ACCEPTABLE", candidate$diagnostic_disposition[[1L]])) {
        ""
      } else {
        ":RUNTIME_ONLY_DOES_NOT_RESCUE_DIAGNOSTIC_FAILURE"
      }
    )
  )
}
deletion_classes$ordinary_clock <- add_timing_deletion_class(
  ordinary_candidate,
  "ordinary_clock"
)
deletion_classes$strict_clock <- add_timing_deletion_class(
  strict_candidate,
  "strict_clock"
)
h06d_nl_assert(
  length(deletion_classes) == 5L,
  "The deletion pilot does not contain five consequential family classes"
)

site_order <- h06d_nl_site_levels(root)
deletion_tasks <- list()
task_counter <- 0L
for (class_id in names(deletion_classes)) {
  entry <- deletion_classes[[class_id]]
  participant_values <- sort(unique(as.character(entry$frame$participant_key)))
  participant_rank <- order(vapply(
    participant_values,
    function(value) digest::digest(
      value,
      algo = "sha256",
      serialize = FALSE
    ),
    character(1)
  ))
  participant_values <- participant_values[participant_rank[seq_len(5L)]]
  site_values <- site_order[site_order %in% as.character(entry$frame$site)]
  h06d_nl_assert(
    length(site_values) >= 5L,
    "A deletion class has fewer than five submitted sites"
  )
  site_values <- site_values[seq_len(5L)]
  for (deletion_type in c("participant", "site")) {
    values <- if (deletion_type == "participant") {
      participant_values
    } else {
      site_values
    }
    for (value in values) {
      task_counter <- task_counter + 1L
      deletion_tasks[[task_counter]] <- tibble::tibble(
        task_id = task_counter,
        class_id = class_id,
        metric_id = entry$metric$metric_id[[1L]],
        predictor_id = entry$predictor$predictor_id[[1L]],
        deletion_type = deletion_type,
        deletion_value_internal = value,
        deletion_label = if (deletion_type == "participant") {
          paste0("participant_sha256:", digest::digest(
            value,
            algo = "sha256",
            serialize = FALSE
          ))
        } else {
          value
        },
        model_source = entry$source
      )
    }
  }
}
deletion_task_table <- dplyr::bind_rows(deletion_tasks)
h06d_nl_assert(
  nrow(deletion_task_table) == 50L &&
    dplyr::n_distinct(deletion_task_table$task_id) == 50L &&
    all(table(deletion_task_table$class_id) == 10L) &&
    sum(deletion_task_table$deletion_type == "participant") == 25L &&
    sum(deletion_task_table$deletion_type == "site") == 25L,
  "The deletion task registry is not exactly 50 balanced refits"
)

deletion_checkpoint_path <- file.path(
  artifact_roots$diagnostics,
  "H06_daily_non_l10_pilot_deletion_checkpoint.csv"
)
if (file.exists(deletion_checkpoint_path)) {
  deletion_checkpoint <- readr::read_csv(
    deletion_checkpoint_path,
    show_col_types = FALSE
  )
  h06d_nl_assert(
    all(deletion_checkpoint$task_id %in% deletion_task_table$task_id) &&
      !anyDuplicated(deletion_checkpoint$task_id),
    "The existing deletion checkpoint is incompatible with this pilot"
  )
} else {
  deletion_checkpoint <- tibble::tibble()
}
deletion_started <- proc.time()[["elapsed"]]
for (task_index in seq_len(nrow(deletion_task_table))) {
  task <- deletion_task_table[task_index, ]
  if (
    nrow(deletion_checkpoint) > 0L &&
      task$task_id[[1L]] %in% deletion_checkpoint$task_id
  ) {
    next
  }
  entry <- deletion_classes[[task$class_id[[1L]]]]
  message(
    sprintf(
      "  deletion %02d/50: %s / %s",
      task$task_id[[1L]],
      task$class_id[[1L]],
      task$deletion_type[[1L]]
    )
  )
  result <- h06d_nl_deletion_refit(
    frame = entry$frame,
    metric = entry$metric,
    predictor = entry$predictor,
    deletion_type = task$deletion_type[[1L]],
    deletion_value = task$deletion_value_internal[[1L]],
    full_effect = entry$full_effect,
    full_standard_error = entry$full_standard_error
  ) |>
    dplyr::select(-"deletion_value") |>
    dplyr::mutate(
      task_id = task$task_id[[1L]],
      class_id = task$class_id[[1L]],
      metric_id = task$metric_id[[1L]],
      predictor_id = task$predictor_id[[1L]],
      deletion_label = task$deletion_label[[1L]],
      model_source = task$model_source[[1L]],
      checkpoint_write_order = nrow(deletion_checkpoint) + 1L,
      .before = 1L
    )
  deletion_checkpoint <- dplyr::bind_rows(deletion_checkpoint, result) |>
    dplyr::arrange(.data$task_id)
  write_csv_atomic(deletion_checkpoint, deletion_checkpoint_path)
}
deletion_runner_elapsed <- unname(
  proc.time()[["elapsed"]] - deletion_started
)
deletion_elapsed <- sum(deletion_checkpoint$elapsed_seconds, na.rm = TRUE)
h06d_nl_assert(
  nrow(deletion_checkpoint) == 50L &&
    dplyr::n_distinct(deletion_checkpoint$task_id) == 50L &&
    identical(
      sort(as.integer(deletion_checkpoint$task_id)),
      seq_len(50L)
    ),
  "The serial deletion pilot did not complete exactly 50 refits"
)
checkpoint_roundtrip <- readr::read_csv(
  deletion_checkpoint_path,
  show_col_types = FALSE
)
h06d_nl_assert(
  identical(
    as.integer(checkpoint_roundtrip$task_id),
    as.integer(deletion_checkpoint$task_id)
  ) &&
    nrow(checkpoint_roundtrip) == 50L,
  "The deletion checkpoint did not round-trip exactly"
)

class_runtime <- deletion_checkpoint |>
  dplyr::summarise(
    pilot_refits = dplyr::n(),
    failures = sum(!.data$converged | !is.na(.data$fit_error)),
    warnings = sum(.data$warning_count),
    median_seconds = stats::median(.data$elapsed_seconds),
    maximum_seconds = max(.data$elapsed_seconds),
    maximum_absolute_shift_in_full_se = max(
      .data$absolute_shift_in_full_se,
      na.rm = TRUE
    ),
    direction_reversals = sum(.data$direction_reversal, na.rm = TRUE),
    .by = "class_id"
  )

classify_inventory <- function(metric_id) {
  dplyr::case_when(
    metric_id %in% c(
      "daily_geometric_mean_medi", "m10_mean_medi",
      "longest_bout_above_250", "dose_time_sensitive_corrected_medi"
    ) ~ "gaussian_offset",
    metric_id %in% c(
      "duration_above_1000", "duration_above_250_wake",
      "duration_below_1_sleep_environment"
    ) ~ "tweedie_log",
    metric_id == "duration_below_10_pre_sleep" ~ "gaussian_identity",
    metric_id == "l10_midpoint" ~ "strict_clock",
    TRUE ~ "ordinary_clock"
  )
}
influence_projection <- frame_inventory |>
  dplyr::mutate(
    class_id = classify_inventory(.data$metric_id),
    projected_deletion_refits = .data$participants + .data$sites
  ) |>
  dplyr::left_join(
    class_runtime |>
      dplyr::select("class_id", "median_seconds"),
    by = "class_id",
    relationship = "many-to-one"
  ) |>
  dplyr::summarise(
    projected_cells = dplyr::n(),
    projected_seconds = sum(
      .data$projected_deletion_refits * .data$median_seconds
    ),
    projected_deletion_refits = sum(.data$projected_deletion_refits),
    .by = c("dataset_id", "analysis_role")
  )
influence_projection <- dplyr::bind_rows(
  influence_projection,
  influence_projection |>
    dplyr::summarise(
      dataset_id = "all_datasets",
      analysis_role = "all_authorized_scenarios",
      projected_cells = sum(.data$projected_cells),
      projected_seconds = sum(.data$projected_seconds),
      projected_deletion_refits = sum(.data$projected_deletion_refits)
    )
)

historical_diagnostics <- readr::read_csv(
  file.path(
    artifact_roots$diagnostics,
    "H06_daily_stage2_pilot_daily_diagnostics.csv"
  ),
  show_col_types = FALSE
)
gaussian_offset_per_cell <- historical_diagnostics |>
  dplyr::filter(.data$pilot_id == "gaussian_offset") |>
  dplyr::summarise(seconds = sum(.data$elapsed_seconds)) |>
  dplyr::pull("seconds") * 1.5
tweedie_per_cell <- historical_diagnostics |>
  dplyr::filter(.data$pilot_id == "tweedie_duration") |>
  dplyr::summarise(seconds = stats::median(.data$elapsed_seconds)) |>
  dplyr::pull("seconds") * 4
identity_per_cell <- historical_diagnostics |>
  dplyr::filter(.data$pilot_id == "gaussian_identity") |>
  dplyr::summarise(seconds = stats::median(.data$elapsed_seconds)) |>
  dplyr::pull("seconds") * 6
timing_per_cell <- timing_elapsed / 15
per_cell_runtime <- tibble::tribble(
  ~class_id, ~projected_seconds_per_cell,
  "gaussian_offset", gaussian_offset_per_cell,
  "tweedie_log", tweedie_per_cell,
  "gaussian_identity", identity_per_cell,
  "ordinary_clock", timing_per_cell,
  "strict_clock", timing_per_cell
)
model_projection <- frame_inventory |>
  dplyr::mutate(class_id = classify_inventory(.data$metric_id)) |>
  dplyr::left_join(
    per_cell_runtime,
    by = "class_id",
    relationship = "many-to-one"
  ) |>
  dplyr::summarise(
    projected_cells = dplyr::n(),
    projected_base_model_seconds = sum(.data$projected_seconds_per_cell),
    .by = c("dataset_id", "analysis_role")
  )

runtime_summary <- dplyr::bind_rows(
  tibble::tibble(
    component = "15-cell primary near-eye clock-family pilot",
    completed_units = 15L,
    measured_seconds = timing_elapsed,
    projected_units = NA_integer_,
    projected_seconds = NA_real_,
    projection_scope = "completed bounded pilot"
  ),
  tibble::tibble(
    component = "five-class deletion pilot",
    completed_units = 50L,
    measured_seconds = deletion_elapsed,
    projected_units = NA_integer_,
    projected_seconds = NA_real_,
    projection_scope = paste0(
      "completed bounded pilot; cumulative serial fit wall time; checkpoint ",
      "after every refit; resume-process overhead ",
      sprintf("%.3f s", deletion_runner_elapsed)
    )
  ),
  influence_projection |>
    dplyr::transmute(
      component = paste0(
        "full deletion projection: ",
        .data$dataset_id,
        " / ",
        .data$analysis_role
      ),
      completed_units = 0L,
      measured_seconds = NA_real_,
      projected_units = .data$projected_deletion_refits,
      projected_seconds = .data$projected_seconds,
      projection_scope = "all participant and submitted-site deletions; not run"
    ),
  model_projection |>
    dplyr::transmute(
      component = paste0(
        "full base-grid projection: ",
        .data$dataset_id,
        " / ",
        .data$analysis_role
      ),
      completed_units = 0L,
      measured_seconds = NA_real_,
      projected_units = .data$projected_cells,
      projected_seconds = .data$projected_base_model_seconds,
      projection_scope = paste0(
        "fixed hierarchy and benchmark; excludes triggered AR overhead, ",
        "deletions, rendering; not run"
      )
    )
)

deletion_runtime_path <- file.path(
  artifact_roots$diagnostics,
  "H06_daily_non_l10_pilot_deletion_runtime_by_class.csv"
)
runtime_path <- file.path(
  artifact_roots$diagnostics,
  "H06_daily_non_l10_pilot_runtime_and_projection.csv"
)
write_csv_atomic(class_runtime, deletion_runtime_path)
write_csv_atomic(runtime_summary, runtime_path)

message("H06-D-007: sealing preservation and pilot manifests")
protected_final <- dplyr::bind_rows(lapply(
  protected_files,
  file_identity
)) |>
  dplyr::arrange(.data$relative_path) |>
  dplyr::left_join(
    protected_baseline |>
      dplyr::rename(
        baseline_sha256 = "sha256",
        baseline_bytes = "bytes"
      ),
    by = "relative_path",
    relationship = "one-to-one"
  ) |>
  dplyr::mutate(
    identity_status = ifelse(
      .data$sha256 == .data$baseline_sha256 &
        .data$bytes == .data$baseline_bytes,
      "BYTE_IDENTICAL",
      "CHANGED"
    )
  )
h06d_nl_assert(
  nrow(protected_final) == nrow(protected_baseline) &&
    all(protected_final$identity_status == "BYTE_IDENTICAL"),
  "A frozen H06_daily historical artifact changed during the pilot"
)
preservation_final_path <- file.path(
  artifact_roots$diagnostics,
  "H06_daily_non_l10_pilot_preservation_final.csv"
)
write_csv_atomic(protected_final, preservation_final_path)

software_manifest <- tibble::tibble(
  item = c("R", required_packages),
  version = c(
    as.character(getRversion()),
    vapply(
      required_packages,
      function(package) as.character(utils::packageVersion(package)),
      character(1)
    )
  ),
  role = "synchronized project library"
)
software_manifest_path <- file.path(
  artifact_roots$manifests,
  "H06_daily_non_l10_pilot_software_manifest.csv"
)
write_csv_atomic(software_manifest, software_manifest_path)

code_paths <- file.path(root, c(
  producer,
  "scripts/hypotheses/H06_daily/h06_daily_non_l10_pilot_contract.R",
  "scripts/hypotheses/H06_daily/h06_daily_non_l10_pilot_data.R",
  "scripts/hypotheses/H06_daily/h06_daily_non_l10_pilot_modeling.R",
  "scripts/hypotheses/H06_daily/h06_daily_contract.R",
  "scripts/hypotheses/H06_daily/h06_daily_data.R",
  "scripts/hypotheses/H06_daily/h06_daily_modeling.R"
))
code_manifest <- dplyr::bind_rows(lapply(code_paths, file_identity)) |>
  dplyr::mutate(
    role = c(
      "pilot runner", "pilot contract", "current-source adapters",
      "pilot modeling", "historical contract for exact reconstruction",
      "historical data adapter for exact reconstruction",
      "historical modeling contract for exact reconstruction"
    )
  )
code_manifest_path <- file.path(
  artifact_roots$manifests,
  "H06_daily_non_l10_pilot_code_manifest.csv"
)
write_csv_atomic(code_manifest, code_manifest_path)

output_paths <- c(
  input_manifest_path, inventory_path, reconciliation_path,
  preservation_baseline_path, reuse_path, reuse_verification_path,
  timing_frame_path, timing_model_path, timing_diagnostic_path,
  timing_model_count_path, timing_lag_path, timing_post_ar_lag_path,
  timing_benchmark_path, timing_effect_path, timing_marginal_path,
  timing_test_path, timing_ar_effect_path, deletion_checkpoint_path,
  deletion_runtime_path, runtime_path, preservation_final_path,
  software_manifest_path, code_manifest_path
)
output_manifest <- dplyr::bind_rows(lapply(output_paths, file_identity)) |>
  dplyr::mutate(
    gate = pilot_id,
    producer = producer,
    authorization = "bounded_pilot_only_no_BH_no_full_grid"
  )
output_manifest_path <- file.path(
  artifact_roots$manifests,
  "H06_daily_non_l10_pilot_output_manifest.csv"
)
write_csv_atomic(output_manifest, output_manifest_path)

pilot_verdict <- tibble::tibble(
  gate = pilot_id,
  current_input_contract = "PASS",
  non_l10_invariance = "PASS",
  frame_inventory = sprintf("PASS_%d_FRAMES", nrow(frame_inventory)),
  exact_historical_reuse = sprintf(
    "PASS_%d_ANALYTICAL_OBJECTS",
    nrow(reuse_verification)
  ),
  timing_cells = nrow(timing_diagnostic_table),
  timing_cells_acceptable = sum(grepl(
    "^ACCEPTABLE",
    timing_diagnostic_table$diagnostic_disposition
  )),
  timing_cells_not_acceptable = sum(grepl(
    "^NOT_ACCEPTABLE",
    timing_diagnostic_table$diagnostic_disposition
  )),
  deletion_refits = nrow(deletion_checkpoint),
  deletion_failures = sum(
    !deletion_checkpoint$converged | !is.na(deletion_checkpoint$fit_error)
  ),
  deletion_warnings = sum(deletion_checkpoint$warning_count),
  historical_files_byte_identical = sum(
    protected_final$identity_status == "BYTE_IDENTICAL"
  ),
  bh_update = "NOT_RUN_NOT_AUTHORIZED",
  full_grid = "NOT_RUN_AWAITING_AUTHOR_APPROVAL",
  gate_status = "STOP_FOR_AUTHOR_REVIEW"
)
verdict_path <- file.path(
  artifact_roots$diagnostics,
  "H06_daily_non_l10_pilot_verdict.csv"
)
write_csv_atomic(pilot_verdict, verdict_path)

message(
  sprintf(
    paste0(
      "H06-D-G2P-NONL10 complete: %d timing cells (%d acceptable), ",
      "%d deletion refits, %.1f + %.1f seconds; stopped for author review."
    ),
    pilot_verdict$timing_cells,
    pilot_verdict$timing_cells_acceptable,
    pilot_verdict$deletion_refits,
    timing_elapsed,
    deletion_elapsed
  )
)
