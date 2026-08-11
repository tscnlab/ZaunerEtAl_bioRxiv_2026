# Fit, diagnose, and display the approved H04 exploratory temporal models.

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
source(file.path(root, "scripts/hypotheses/H04/h04_contract.R"))
source(file.path(root, "scripts/hypotheses/H04/h04_stage1_support.R"))
source(file.path(root, "scripts/hypotheses/H04/h04_data.R"))
source(file.path(root, "scripts/hypotheses/H04/h04_modeling.R"))
source(file.path(root, "scripts/hypotheses/H04/h04_reporting.R"))
source(file.path(root, "scripts/hypotheses/H04/h04_temporal.R"))

if (!identical(as.character(getRversion()), "4.6.1")) {
  h04_abort(
    "H04 temporal analysis requires R 4.6.1; found %s",
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
  "ggplot2",
  "scales",
  "LightLogR",
  "patchwork"
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
  h04_abort(
    "Missing synchronized project package(s): %s",
    paste(missing_packages, collapse = ", ")
  )
}

producer <- "scripts/hypotheses/H04/run_h04_temporal.R"
roots <- list(
  model_data = file.path(root, "artifacts/06_model_data/H04"),
  models = file.path(root, "artifacts/07_models/H04"),
  diagnostics = file.path(root, "artifacts/08_diagnostics/H04"),
  tables = file.path(root, "artifacts/09_tables/H04"),
  figures = file.path(root, "artifacts/10_figures/H04"),
  source_data = file.path(root, "artifacts/11_source_data/H04"),
  manifests = file.path(root, "artifacts/12_manifests/H04")
)
invisible(vapply(
  roots,
  dir.create,
  logical(1),
  recursive = TRUE,
  showWarnings = FALSE
))

frame_path <- file.path(roots$model_data, "H04_model_frames.rds")
if (!file.exists(frame_path)) {
  h04_abort("Run the H04 Stage 2 mean-model pipeline before temporal fitting")
}
frames <- readRDS(frame_path)$main
placement_registry <- list(
  near_eye = list(
    placement = "Near-eye",
    frame = frames$near_eye,
    id = "near_eye"
  ),
  chest = list(
    placement = "Chest",
    frame = frames$chest,
    id = "chest"
  )
)
requested <- trimws(strsplit(
  Sys.getenv("H04_TEMPORAL_PLACEMENTS", unset = "near_eye,chest"),
  ",",
  fixed = TRUE
)[[1L]])
if (!all(requested %in% names(placement_registry))) {
  h04_abort(
    "Unknown H04 temporal placement(s): %s",
    paste(setdiff(requested, names(placement_registry)), collapse = ", ")
  )
}

h04_temporal_cache <- function(entry, formula_id) {
  path <- file.path(
    roots$models,
    paste0("H04_", formula_id, "_", entry$id, ".rds")
  )
  expected_formula <- h04_formula_set()[[formula_id]]
  if (file.exists(path)) {
    object <- readRDS(path)
    valid <- identical(object$placement, entry$placement) &&
      identical(object$formula_id, formula_id) &&
      identical(
        h04_formula_text(object$formula),
        h04_formula_text(expected_formula)
      ) &&
      nrow(object$data) == nrow(entry$frame) &&
      dplyr::n_distinct(object$data$analysis_hour_id) ==
        dplyr::n_distinct(entry$frame$analysis_hour_id) &&
      abs(
        sum(object$data$analysis_weight) -
          sum(entry$frame$analysis_weight)
      ) <
        1e-10 &&
      identical(
        object$basis_variant,
        "global_cc_activity_site_thin_plate_sz"
      )
    if (!valid) {
      h04_abort("Existing temporal cache violates its contract: %s", path)
    }
    message("Using validated H04 temporal cache: ", basename(path))
    return(object)
  }
  message("Fitting ", formula_id, " for ", entry$placement)
  object <- h04_fit_temporal_model(entry$frame, entry$placement, formula_id)
  write_rds_artifact(object, path, producer)
  object
}

basis_contract <- h04_temporal_basis_contract()
stopifnot(
  basis_contract$marginal_basis[
    basis_contract$component == "activity deviation"
  ] ==
    "tp.smooth.spec / tprs.smooth",
  basis_contract$marginal_basis[basis_contract$component == "site deviation"] ==
    "tp.smooth.spec / tprs.smooth",
  basis_contract$cyclic[basis_contract$component == "global time"],
  !basis_contract$cyclic[basis_contract$component == "activity deviation"],
  !basis_contract$cyclic[basis_contract$component == "site deviation"]
)

objects <- list()
summaries <- list()
comparisons <- list()
smooth_tables <- list()
k_checks <- list()
concurvity <- list()
acf <- list()
run_diagnostics <- list()
cluster_diagnostics <- list()
activity_endpoints <- list()
site_endpoints <- list()
global_endpoints <- list()
curves <- list()
support <- list()
retention <- list()
uncertainty <- list()

for (id in requested) {
  entry <- placement_registry[[id]]
  activity <- h04_temporal_cache(entry, "temporal_activity_long")
  no_activity <- h04_temporal_cache(entry, "temporal_no_activity")
  objects[[id]] <- list(activity = activity, no_activity = no_activity)

  activity_summary <- h04_temporal_model_summary(activity)
  no_activity_summary <- h04_temporal_model_summary(no_activity)
  summaries[[id]] <- dplyr::bind_rows(activity_summary, no_activity_summary)
  comparisons[[id]] <- h04_temporal_comparison(activity, no_activity)
  smooth_tables[[id]] <- dplyr::bind_rows(
    h04_temporal_smooth_table(activity),
    h04_temporal_smooth_table(no_activity)
  )
  k_checks[[id]] <- h04_temporal_k_check(activity)
  concurvity[[id]] <- h04_temporal_concurvity(activity)
  acf[[id]] <- h04_temporal_residual_acf(activity)
  run_diagnostics[[id]] <- h04_temporal_run_diagnostics(activity)
  cluster_diagnostics[[id]] <- h04_temporal_cluster_diagnostics(activity)
  curves[[id]] <- h04_temporal_curves(activity)
  uncertainty[[id]] <- h04_temporal_uncertainty_contract(curves[[id]])
  support[[id]] <- h04_temporal_support(activity)
  endpoints <- h04_temporal_endpoint_diagnostics(activity, curves[[id]])
  activity_endpoints[[id]] <- endpoints$activity
  site_endpoints[[id]] <- endpoints$site
  global_endpoints[[id]] <- endpoints$global

  comparison <- comparisons[[id]]
  activity_comparison <- comparison |>
    dplyr::filter(.data$formula_id == "temporal_activity_long")
  no_activity_comparison <- comparison |>
    dplyr::filter(.data$formula_id == "temporal_no_activity")
  run_check <- run_diagnostics[[id]]
  k <- k_checks[[id]]
  relevant_k <- k |>
    dplyr::filter(grepl(
      "s\\(time_hour\\)|activity|site",
      .data$term
    ))
  finite_k <- relevant_k$k_index[is.finite(relevant_k$k_index)]
  k_adequate <- length(finite_k) == 0L || min(finite_k) >= 0.70
  run_adequate <- run_check$runs_with_duplicate_timestamps == 0L &&
    run_check$nonconsecutive_utc_within_runs == 0L &&
    run_check$nonconsecutive_wall_within_runs == 0L &&
    run_check$mixed_activity_runs == 0L &&
    run_check$mixed_participant_day_runs == 0L &&
    run_check$hours_with_row_k_mismatch == 0L &&
    run_check$maximum_hour_weight_error < 1e-10
  added_context <- activity_comparison$aic + 2 < no_activity_comparison$aic &&
    activity_comparison$deviance_explained >
      no_activity_comparison$deviance_explained
  retained <- activity_summary$converged &&
    activity_summary$final_warning_count == 0L &&
    run_adequate &&
    k_adequate &&
    added_context &&
    all(is.finite(curves[[id]]$estimated_mel_edi_lx)) &&
    endpoints$global$endpoint_absolute_log_ratio < 1e-8
  retention[[id]] <- tibble::tibble(
    placement = entry$placement,
    temporal_component = "fractionally weighted activity-long temporal context",
    convergence_pass = activity_summary$converged,
    warning_pass = activity_summary$final_warning_count == 0L,
    run_boundary_and_weight_pass = run_adequate,
    minimum_finite_k_index = if (length(finite_k) == 0L) {
      NA_real_
    } else {
      min(finite_k)
    },
    basis_capacity_pass = k_adequate,
    activity_model_aic = activity_comparison$aic,
    no_activity_model_aic = no_activity_comparison$aic,
    activity_model_delta_aic = activity_comparison$aic -
      no_activity_comparison$aic,
    activity_model_deviance_explained = activity_comparison$deviance_explained,
    no_activity_model_deviance_explained = no_activity_comparison$deviance_explained,
    genuine_added_context = added_context,
    residual_lag1 = activity_summary$standardized_residual_lag1,
    global_cyclic_endpoint_pass = endpoints$global$endpoint_absolute_log_ratio <
      1e-8,
    maximum_activity_endpoint_ratio = max(
      endpoints$activity$endpoint_ratio_24_to_0,
      1 / endpoints$activity$endpoint_ratio_24_to_0
    ),
    maximum_site_endpoint_ratio = max(
      endpoints$site$endpoint_ratio_24_to_0,
      1 / endpoints$site$endpoint_ratio_24_to_0
    ),
    locally_sparse_clock_activity_cells = sum(
      support[[id]]$locally_sparse
    ),
    retained_for_context = retained,
    assessment = if (retained) {
      "ACCEPTABLE WITH LIMITATION"
    } else {
      "NOT ACCEPTABLE"
    },
    interpretation = if (retained) {
      paste(
        "The activity smooth adds temporal context and passes construction",
        "checks. Residual dependence, sparse clock/category cells, accepted",
        "thin-plate midnight separation, and pointwise-only model-based",
        "uncertainty remain explicit limitations."
      )
    } else {
      paste(
        "The temporal model failed at least one predeclared adequacy",
        "component and is not retained for reader-facing context."
      )
    }
  )

  write_csv_artifact(
    curves[[id]],
    file.path(
      roots$source_data,
      paste0("H04_temporal_", id, "_curves.csv")
    ),
    producer
  )
  write_csv_artifact(
    support[[id]],
    file.path(
      roots$source_data,
      paste0("H04_temporal_", id, "_support.csv")
    ),
    producer
  )
  figure <- h04_temporal_figure(
    curves[[id]],
    support[[id]],
    entry$placement,
    interval = "pointwise"
  )
  invisible(h04_save_plot(
    figure,
    paste0("H04_temporal_", id),
    roots$figures,
    width = 14,
    height = 12,
    producer = producer
  ))
}

model_summary <- dplyr::bind_rows(summaries)
model_comparison <- dplyr::bind_rows(comparisons)
smooth_table <- dplyr::bind_rows(smooth_tables)
k_check <- dplyr::bind_rows(k_checks)
concurvity_table <- dplyr::bind_rows(concurvity)
residual_acf <- dplyr::bind_rows(acf)
run_check <- dplyr::bind_rows(run_diagnostics)
cluster_table <- dplyr::bind_rows(cluster_diagnostics)
activity_endpoint <- dplyr::bind_rows(activity_endpoints)
site_endpoint <- dplyr::bind_rows(site_endpoints)
global_endpoint <- dplyr::bind_rows(global_endpoints)
retention_decision <- dplyr::bind_rows(retention)
uncertainty_contract <- dplyr::bind_rows(uncertainty)

write_csv_artifact(
  basis_contract,
  file.path(roots$diagnostics, "H04_temporal_basis_contract.csv"),
  producer
)
write_csv_artifact(
  model_summary,
  file.path(roots$diagnostics, "H04_temporal_model_summary.csv"),
  producer
)
write_csv_artifact(
  k_check,
  file.path(roots$diagnostics, "H04_temporal_k_check.csv"),
  producer
)
write_csv_artifact(
  concurvity_table,
  file.path(roots$diagnostics, "H04_temporal_concurvity.csv"),
  producer
)
write_csv_artifact(
  residual_acf,
  file.path(roots$diagnostics, "H04_temporal_residual_acf.csv"),
  producer
)
write_csv_artifact(
  run_check,
  file.path(roots$diagnostics, "H04_temporal_run_diagnostics.csv"),
  producer
)
write_csv_artifact(
  cluster_table,
  file.path(roots$diagnostics, "H04_temporal_cluster_diagnostics.csv"),
  producer
)
write_csv_artifact(
  activity_endpoint,
  file.path(
    roots$diagnostics,
    "H04_temporal_activity_midnight_diagnostics.csv"
  ),
  producer
)
write_csv_artifact(
  site_endpoint,
  file.path(
    roots$diagnostics,
    "H04_temporal_site_midnight_diagnostics.csv"
  ),
  producer
)
write_csv_artifact(
  global_endpoint,
  file.path(
    roots$diagnostics,
    "H04_temporal_global_midnight_diagnostics.csv"
  ),
  producer
)
write_csv_artifact(
  retention_decision,
  file.path(roots$diagnostics, "H04_temporal_retention_decision.csv"),
  producer
)
write_csv_artifact(
  uncertainty_contract,
  file.path(roots$diagnostics, "H04_temporal_uncertainty_contract.csv"),
  producer
)
write_csv_artifact(
  model_comparison,
  file.path(roots$tables, "H04_temporal_model_comparison.csv"),
  producer
)
write_csv_artifact(
  smooth_table,
  file.path(roots$tables, "H04_temporal_smooth_table.csv"),
  producer
)
write_rds_artifact(
  objects,
  file.path(roots$models, "H04_temporal_model_objects.rds"),
  producer
)

bootstrap_gate <- retention_decision |>
  dplyr::transmute(
    .data$placement,
    temporal_retained = .data$retained_for_context,
    required_next_step = paste(
      "none for temporal interval construction; use the H03-aligned",
      "model-based pointwise intervals"
    ),
    production_status = paste(
      "SUPERSEDED BY AUTHOR DECISION 2026-08-11;",
      "NO BOOTSTRAP OR SIMULATION USED"
    )
  )
write_csv_artifact(
  bootstrap_gate,
  file.path(roots$tables, "H04_temporal_bootstrap_gate.csv"),
  producer
)

bootstrap_supersession <- h04_temporal_bootstrap_supersession(file.path(
  roots$models,
  "temporal_bootstrap_pilot_checkpoints"
))
write_csv_artifact(
  bootstrap_supersession,
  file.path(roots$diagnostics, "H04_temporal_bootstrap_supersession.csv"),
  producer
)

message("H04 temporal fitting and adequacy assessment complete")
print(retention_decision)
