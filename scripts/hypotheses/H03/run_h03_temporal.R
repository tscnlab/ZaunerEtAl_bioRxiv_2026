# Run the approved exploratory H03 global-plus-sz temporal GAM/GAMM models.

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
source(file.path(root, "scripts/hypotheses/H03/h03_data.R"))
source(file.path(root, "scripts/hypotheses/H03/h03_modeling.R"))
source(file.path(root, "scripts/hypotheses/H03/h03_temporal.R"))
source(file.path(root, "scripts/hypotheses/H03/h03_reporting.R"))

options(lifecycle_verbosity = "quiet", warn = 1)
if (!identical(as.character(getRversion()), "4.6.1")) {
  h03_abort(
    "H03 temporal analysis requires R 4.6.1; found %s",
    as.character(getRversion())
  )
}
required_packages <- c(
  "dplyr", "tidyr", "purrr", "tibble", "readr", "digest", "openssl",
  "mgcv", "gratia", "ggplot2", "scales", "LightLogR", "cowplot",
  "patchwork"
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

producer <- "scripts/hypotheses/H03/run_h03_temporal.R"
roots <- list(
  model_data = file.path(root, "artifacts/06_model_data/H03"),
  models = file.path(root, "artifacts/07_models/H03"),
  diagnostics = file.path(root, "artifacts/08_diagnostics/H03"),
  tables = file.path(root, "artifacts/09_tables/H03"),
  figures = file.path(root, "artifacts/10_figures/H03"),
  source_data = file.path(root, "artifacts/11_source_data/H03"),
  manifests = file.path(root, "artifacts/12_manifests/H03")
)
invisible(vapply(
  roots,
  dir.create,
  logical(1),
  recursive = TRUE,
  showWarnings = FALSE
))

metadata <- list()
h03_write_csv <- function(data, path, id) {
  metadata[[id]] <<- write_csv_artifact(data, path, producer)
  invisible(path)
}
h03_write_rds <- function(object, path, id) {
  metadata[[id]] <<- write_rds_artifact(object, path, producer)
  invisible(path)
}
h03_record_plot_metadata <- function(items, prefix) {
  for (extension in names(items)) {
    metadata[[paste(prefix, extension, sep = "_")]] <<- items[[extension]]
  }
}

h03_validate_inputs(root)
inputs <- h03_load_inputs(root)
spec <- h03_specification()
frame_path <- file.path(roots$model_data, "H03_model_frames.rds")
if (!file.exists(frame_path)) {
  h03_abort("Run H03 Stage 2 primary execution before the temporal analysis")
}
frames <- readRDS(frame_path)$main
stopifnot(
  nrow(frames$near_eye) == 17935L,
  nrow(frames$chest) == 19512L,
  dplyr::n_distinct(frames$near_eye$participant) == 140L,
  dplyr::n_distinct(frames$chest$participant) == 151L
)

frame_index <- readr::read_csv(
  file.path(roots$model_data, "H03_model_frame_index.csv"),
  show_col_types = FALSE
) |>
  dplyr::filter(.data$run_id %in% c("main__near_eye", "main__chest")) |>
  dplyr::arrange(match(.data$run_id, c("main__near_eye", "main__chest")))
expected_frame_hashes <- stats::setNames(
  frame_index$frame_sha256,
  frame_index$run_id
)
expected_formula <- paste(
  deparse(h03_formula_set()$temporal_category),
  collapse = " "
)
model_path <- file.path(roots$models, "H03_temporal_model_objects.rds")
cache_valid <- FALSE
if (file.exists(model_path)) {
  cached <- readRDS(model_path)
  cache_metadata <- attr(cached, "h03_temporal_cache")
  cache_valid <-
    identical(names(cached), c("near_eye", "chest")) &&
    identical(cache_metadata$r_version, as.character(getRversion())) &&
    identical(cache_metadata$frame_sha256, expected_frame_hashes) &&
    identical(cache_metadata$formula, expected_formula) &&
    stats::nobs(cached$near_eye$final) == nrow(frames$near_eye) &&
    stats::nobs(cached$chest$final) == nrow(frames$chest)
}
if (cache_valid) {
  message("Reusing validated H03 temporal fit checkpoint")
  models <- cached
} else {
  message("Fitting H03 exploratory near-eye temporal model")
  near_eye <- h03_fit_temporal_model(frames$near_eye, "temporal__near_eye")
  message("Fitting H03 exploratory chest temporal model")
  chest <- h03_fit_temporal_model(frames$chest, "temporal__chest")
  models <- list(near_eye = near_eye, chest = chest)
  attr(models, "h03_temporal_cache") <- list(
    r_version = as.character(getRversion()),
    frame_sha256 = expected_frame_hashes,
    formula = paste(deparse(h03_formula_set()$temporal_category), collapse = " ")
  )
}
cache_metadata <- attr(models, "h03_temporal_cache")
cache_already_trimmed <- cache_valid && all(vapply(
  models,
  function(object) is.null(object$preliminary),
  logical(1)
))
models <- lapply(models, function(object) {
  # The preliminary rho-estimation fit is not an analysis result and roughly
  # doubles the checkpoint. Retain only the final fit, rho, data, and formula.
  object$preliminary <- NULL
  if (is.null(object$basis_variant)) {
    object$basis_variant <- "inherited_thin_plate_sz"
  }
  object
})
attr(models, "h03_temporal_cache") <- cache_metadata
placements <- c(near_eye = "Near-eye", chest = "Chest")

# Save the fitted-model checkpoint before any diagnostic or reporting
# extraction so a post-processing failure cannot force scientifically
# identical models to be refitted.
if (cache_already_trimmed) {
  model_info <- file.info(model_path)
  metadata[["temporal_models"]] <- list(
    path = normalizePath(model_path, winslash = "/", mustWork = TRUE),
    sha256 = artifact_sha256(model_path),
    bytes = unname(model_info$size),
    producer = producer,
    r_version = as.character(getRversion()),
    written_utc = format(model_info$mtime, tz = "UTC", usetz = TRUE)
  )
} else {
  h03_write_rds(models, model_path, "temporal_models")
}

message("Extracting H03 temporal curves, diagnostics, and GAM-only summaries")
curves <- list()
supports <- list()
model_summary <- list()
k_checks <- list()
concurvity <- list()
constraints <- list()
midnight <- list()
acf <- list()
weighted_r2 <- list()
variance_components <- list()
partitions <- list()
residuals <- list()
cluster_diagnostics <- list()
smooth_tests <- list()
appraise_plots <- list()

for (id in names(models)) {
  object <- models[[id]]
  placement <- placements[[id]]
  message("  post-processing ", placement)
  curves[[id]] <- h03_temporal_curves(object, inputs$categories)
  supports[[id]] <- h03_temporal_support(object, inputs$categories, spec)
  model_summary[[id]] <- h03_temporal_model_summary(object, placement)
  k_checks[[id]] <- h03_temporal_k_check(object, placement)
  concurvity[[id]] <- h03_temporal_concurvity(object, placement)
  constraints[[id]] <- h03_temporal_constraint_diagnostics(
    object,
    curves[[id]],
    placement
  )
  midnight[[id]] <- h03_temporal_midnight_diagnostic(object, placement)
  acf[[id]] <- h03_temporal_residual_acf(object, placement)
  weighted_r2[[id]] <- h03_temporal_weighted_r_squared(object, placement)
  variance_components[[id]] <- h03_temporal_variance_components(
    object,
    placement
  )
  partitions[[id]] <- h03_temporal_variance_partition(object, placement)
  residuals[[id]] <- h03_temporal_residual_data(object, placement)
  cluster_diagnostics[[id]] <- h03_temporal_cluster_diagnostics(
    object,
    placement
  )
  smooth_table <- as.data.frame(summary(object$final)$s.table) |>
    tibble::rownames_to_column("term") |>
    tibble::as_tibble()
  names(smooth_table) <- c(
    "term", "effective_df", "reference_df", "f_statistic", "p_raw"
  )
  smooth_tests[[id]] <- smooth_table |>
    dplyr::mutate(
      run_id = object$run_id,
      placement = placement,
      inferential_role = paste(
        "exploratory approximate whole-term test conditional on smoothing"
      ),
      .before = 1
    )
  appraise_plots[[id]] <- gratia::appraise(
    object$final,
    method = "normal",
    type = "deviance",
    n_simulate = 0L,
    n_uniform = 0L,
    ncol = 2
  )
}

curve_data <- dplyr::bind_rows(lapply(names(curves), function(id) {
  curves[[id]]$curves |>
    dplyr::mutate(
      run_id = models[[id]]$run_id,
      placement = placements[[id]],
      .before = 1
    )
}))
deviation_data <- dplyr::bind_rows(lapply(names(curves), function(id) {
  curves[[id]]$deviations |>
    dplyr::mutate(
      run_id = models[[id]]$run_id,
      placement = placements[[id]],
      .before = 1
    )
}))
global_data <- dplyr::bind_rows(lapply(names(curves), function(id) {
  curves[[id]]$global |>
    dplyr::mutate(
      run_id = models[[id]]$run_id,
      placement = placements[[id]],
      .before = 1
    )
}))
support_data <- dplyr::bind_rows(lapply(names(supports), function(id) {
  supports[[id]] |>
    dplyr::mutate(
      run_id = models[[id]]$run_id,
      placement = placements[[id]],
      .before = 1
    )
}))
model_summary_data <- dplyr::bind_rows(model_summary)
k_check_data <- dplyr::bind_rows(k_checks)
concurvity_data <- dplyr::bind_rows(concurvity)
constraint_data <- dplyr::bind_rows(constraints)
midnight_data <- dplyr::bind_rows(midnight)
acf_data <- dplyr::bind_rows(acf)
weighted_r2_data <- dplyr::bind_rows(weighted_r2)
variance_component_data <- dplyr::bind_rows(variance_components)
partition_data <- dplyr::bind_rows(lapply(partitions, `[[`, "allocation"))
partition_covariance <- dplyr::bind_rows(lapply(partitions, `[[`, "covariance"))
residual_data <- dplyr::bind_rows(residuals)
cluster_data <- dplyr::bind_rows(cluster_diagnostics)
smooth_test_data <- dplyr::bind_rows(smooth_tests)

if (any(abs(partition_data$shapley_efficiency_error) > 1e-10)) {
  h03_abort("H03 temporal Shapley point allocation failed efficiency")
}
if (any(!constraint_data$passes)) {
  warning(
    "One or more H03 temporal sum-to-zero diagnostics exceeded tolerance",
    call. = FALSE
  )
}

h03_write_csv(model_summary_data, file.path(roots$tables, "H03_temporal_model_summary.csv"), "model_summary")
h03_write_csv(weighted_r2_data, file.path(roots$tables, "H03_temporal_weighted_r_squared.csv"), "weighted_r2")
h03_write_csv(variance_component_data, file.path(roots$tables, "H03_temporal_variance_components.csv"), "variance_components")
h03_write_csv(partition_data, file.path(roots$tables, "H03_temporal_shapley_allocation.csv"), "partition")
h03_write_csv(partition_covariance, file.path(roots$tables, "H03_temporal_component_covariance.csv"), "partition_covariance")
h03_write_csv(smooth_test_data, file.path(roots$tables, "H03_temporal_smooth_tests.csv"), "smooth_tests")

h03_write_csv(k_check_data, file.path(roots$diagnostics, "H03_temporal_k_check.csv"), "k_check")
h03_write_csv(concurvity_data, file.path(roots$diagnostics, "H03_temporal_concurvity.csv"), "concurvity")
h03_write_csv(constraint_data, file.path(roots$diagnostics, "H03_temporal_sz_constraints.csv"), "constraints")
h03_write_csv(midnight_data, file.path(roots$diagnostics, "H03_temporal_midnight_diagnostics.csv"), "midnight")
h03_write_csv(acf_data, file.path(roots$diagnostics, "H03_temporal_residual_acf.csv"), "acf")
h03_write_csv(cluster_data, file.path(roots$diagnostics, "H03_temporal_cluster_diagnostics.csv"), "cluster_diagnostics")

h03_write_csv(curve_data, file.path(roots$source_data, "H03_temporal_category_curves.csv"), "curves")
h03_write_csv(deviation_data, file.path(roots$source_data, "H03_temporal_category_deviations.csv"), "deviations")
h03_write_csv(global_data, file.path(roots$source_data, "H03_temporal_global_curves.csv"), "global")
h03_write_csv(support_data, file.path(roots$source_data, "H03_temporal_clock_support.csv"), "support")
h03_write_csv(residual_data, file.path(roots$source_data, "H03_temporal_residual_diagnostic_data.csv"), "residuals")

for (id in names(models)) {
  placement <- placements[[id]]
  figure <- h03_temporal_figure(
    curves[[id]]$curves,
    curves[[id]]$deviations,
    curves[[id]]$global,
    supports[[id]],
    inputs$categories,
    placement
  )
  h03_record_plot_metadata(
    h03_save_plot(
      figure,
      paste0("H03_temporal_", id),
      roots$figures,
      width = 16,
      height = 19.5,
      producer = producer
    ),
    paste0("temporal_", id)
  )
  h03_record_plot_metadata(
    h03_save_plot(
      appraise_plots[[id]],
      paste0("H03_temporal_appraise_", id),
      roots$figures,
      width = 11,
      height = 8,
      producer = producer
    ),
    paste0("appraise_", id)
  )
}

environment <- tibble::tibble(
  component = c("R", paste0("R package: ", required_packages)),
  version = c(
    as.character(getRversion()),
    vapply(
      required_packages,
      function(package) as.character(utils::packageVersion(package)),
      character(1)
    )
  )
)
h03_write_csv(
  environment,
  file.path(roots$manifests, "H03_temporal_execution_environment.csv"),
  "environment"
)
manifest <- dplyr::bind_rows(lapply(metadata, manifest_row))
write_csv_artifact(
  manifest,
  file.path(roots$manifests, "H03_temporal_run_manifest.csv"),
  producer
)

message("H03 exploratory temporal execution complete; no simulation was run")
print(as.data.frame(model_summary_data), row.names = FALSE)
print(as.data.frame(constraint_data), row.names = FALSE)
