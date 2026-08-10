# Recreate the V0-style H03 temporal display from the accepted old GAM fit.

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
source(file.path(root, "scripts/hypotheses/H03/h03_reporting.R"))

if (!identical(as.character(getRversion()), "4.6.1")) {
  h03_abort(
    "H03 temporal display pilot requires R 4.6.1; found %s",
    as.character(getRversion())
  )
}

required_packages <- c(
  "dplyr", "tidyr", "tibble", "readr", "mgcv", "gratia", "ggplot2",
  "scales", "LightLogR", "cowplot", "patchwork", "svglite", "ragg"
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

producer <- paste0(
  "scripts/hypotheses/H03/",
  "run_h03_temporal_log_gaussian_v0_display_pilot.R"
)
source_model_producer <- "scripts/hypotheses/H03/run_h03_temporal.R"
run_id <- "temporal_log_gaussian_v0_display_pilot__near_eye"
model_path <- file.path(
  root,
  "artifacts/07_models/H03/H03_temporal_model_objects.rds"
)
if (!file.exists(model_path)) {
  h03_abort("Missing accepted H03 temporal model object: %s", model_path)
}

table_root <- file.path(root, "artifacts/09_tables/H03")
figure_root <- file.path(root, "artifacts/10_figures/H03")
source_root <- file.path(root, "artifacts/11_source_data/H03")
manifest_root <- file.path(root, "artifacts/12_manifests/H03")
invisible(lapply(
  c(table_root, figure_root, source_root, manifest_root),
  dir.create,
  recursive = TRUE,
  showWarnings = FALSE
))

h03_existing_artifact_metadata <- function(path, producer) {
  info <- file.info(path)
  list(
    path = normalizePath(path, winslash = "/", mustWork = TRUE),
    sha256 = artifact_sha256(path),
    bytes = unname(info$size),
    producer = producer,
    r_version = as.character(getRversion()),
    written_utc = format(info$mtime, tz = "UTC", usetz = TRUE)
  )
}

message("Loading accepted H03 temporal model object")
models <- readRDS(model_path)
object <- models$near_eye
rm(models)
invisible(gc())
if (is.null(object$final) || !inherits(object$final, "gam")) {
  h03_abort("Accepted near-eye temporal GAM was not found in the model object")
}
fit <- object$final
data <- object$data
expected_formula <- h03_formula_set()$temporal_category
if (!identical(
  paste(deparse(object$formula), collapse = " "),
  paste(deparse(expected_formula), collapse = " ")
)) {
  h03_abort("Accepted near-eye temporal GAM formula differs from the contract")
}

inputs <- h03_load_inputs(root)
registry <- inputs$categories |>
  dplyr::transmute(
    .data$category_order,
    .data$category_code,
    light_source = .data$category_label,
    .data$short_label,
    .data$figure_label
  )
time_grid <- seq(0.5, 23.5, by = 1)
excluded_population_smooths <- c(
  "s(time_hour,site)",
  "s(time_hour,participant)",
  "s(participant_day)"
)

prediction_grid <- tidyr::crossing(
  time_hour = time_grid,
  light_source = factor(
    levels(data$light_source),
    levels = levels(data$light_source)
  )
) |>
  dplyr::mutate(
    site = factor(levels(data$site)[1L], levels = levels(data$site)),
    participant = factor(
      levels(data$participant)[1L],
      levels = levels(data$participant)
    ),
    participant_day = factor(
      levels(data$participant_day)[1L],
      levels = levels(data$participant_day)
    ),
    AR_start = TRUE
  )

message("Evaluating V0-style Panel A with gratia::fitted_values()")
curve_link <- gratia::fitted_values(
  fit,
  data = prediction_grid,
  scale = "link",
  ci_level = 0.95,
  exclude = excluded_population_smooths,
  unconditional = FALSE
)
curves <- curve_link |>
  dplyr::transmute(
    run_id = .env$run_id,
    placement = "Near-eye",
    time_hour = .data$time_hour,
    light_source = as.character(.data$light_source),
    estimated_mel_edi_lx = pmax(10^.data$.fitted - 0.1, 0),
    pointwise_conf_low_lx = pmax(10^.data$.lower_ci - 0.1, 0),
    pointwise_conf_high_lx = pmax(10^.data$.upper_ci - 0.1, 0),
    pointwise_link_se = .data$.se,
    site_effects_excluded = TRUE,
    participant_effects_excluded = TRUE,
    participant_day_effects_excluded = TRUE,
    response_transform = "log10(geo_medi_1h + 0.1)",
    extraction = paste0(
      "gratia::fitted_values(scale = 'link', unconditional = FALSE, ",
      "exclude = site/participant/participant-day smooths)"
    ),
    interval_type = "pointwise_95_percent_conditional"
  ) |>
  dplyr::left_join(registry, by = "light_source", relationship = "many-to-one") |>
  dplyr::arrange(.data$category_order, .data$time_hour)

global_grid <- prediction_grid |>
  dplyr::filter(
    as.character(.data$light_source) == levels(data$light_source)[1L]
  )
message("Evaluating the global curve with gratia::fitted_values()")
global_link <- gratia::fitted_values(
  fit,
  data = global_grid,
  scale = "link",
  ci_level = 0.95,
  exclude = c(
    "s(time_hour,light_source)",
    excluded_population_smooths
  ),
  unconditional = FALSE
)
global <- global_link |>
  dplyr::transmute(
    run_id = .env$run_id,
    placement = "Near-eye",
    time_hour = .data$time_hour,
    global_mel_edi_lx = pmax(10^.data$.fitted - 0.1, 0),
    pointwise_conf_low_lx = pmax(10^.data$.lower_ci - 0.1, 0),
    pointwise_conf_high_lx = pmax(10^.data$.upper_ci - 0.1, 0),
    pointwise_link_se = .data$.se,
    response_transform = "log10(geo_medi_1h + 0.1)",
    estimand = paste(
      "global log-Gaussian conditional smooth; category, site, participant,",
      "and participant-day smooths excluded"
    ),
    extraction = paste0(
      "gratia::fitted_values(scale = 'link', unconditional = FALSE, ",
      "exclude = category/site/participant/participant-day smooths)"
    )
  )

message("Evaluating V0-style Panel B with gratia::smooth_estimates()")
ratios <- gratia::smooth_estimates(
  fit,
  select = "s(time_hour,light_source)",
  n = length(time_grid),
  unconditional = FALSE,
  overall_uncertainty = TRUE
) |>
  dplyr::transmute(
    run_id = .env$run_id,
    placement = "Near-eye",
    time_hour = .data$time_hour,
    light_source = as.character(.data$light_source),
    ratio_to_global = 10^.data$.estimate,
    ratio_conf_low = 10^(.data$.estimate - 1.96 * .data$.se),
    ratio_conf_high = 10^(.data$.estimate + 1.96 * .data$.se),
    pointwise_log10_ratio_se = .data$.se,
    reference = "global smooth on the log10(melEDI + 0.1) scale",
    extraction = paste0(
      "gratia::smooth_estimates(unconditional = FALSE, ",
      "overall_uncertainty = TRUE)"
    ),
    interval_type = "pointwise_95_percent_conditional"
  ) |>
  dplyr::left_join(registry, by = "light_source", relationship = "many-to-one") |>
  dplyr::arrange(.data$category_order, .data$time_hour)

if (!identical(nrow(curves), 7L * 24L) ||
    !identical(nrow(ratios), 7L * 24L) ||
    !identical(nrow(global), 24L)) {
  h03_abort("Unexpected row count in the V0-style temporal display data")
}
ratio_constraint <- ratios |>
  dplyr::group_by(.data$time_hour) |>
  dplyr::summarise(
    geometric_mean_ratio = exp(mean(log(.data$ratio_to_global))),
    .groups = "drop"
  )
maximum_constraint_error <- max(abs(
  ratio_constraint$geometric_mean_ratio - 1
))
if (!is.finite(maximum_constraint_error) ||
    maximum_constraint_error > 1e-10) {
  h03_abort(
    "Light-source sz ratios violate their sum-to-zero constraint (max = %.3g)",
    maximum_constraint_error
  )
}

support <- readr::read_csv(
  file.path(source_root, "H03_temporal_clock_support.csv"),
  show_col_types = FALSE
) |>
  dplyr::filter(.data$placement == "Near-eye")

figure <- h03_temporal_figure(
  curves = curves,
  deviations = ratios,
  global = global,
  support = support,
  category_registry = inputs$categories,
  placement = "Near-eye",
  ratio_data = ratios,
  curve_title = paste(
    "Near-eye: V0-style log-Gaussian one-hour melEDI curves"
  ),
  model_caption = paste(
    "Inherited Gaussian GAM for log10(melEDI + 0.1), identity link;",
    "exploratory context."
  ),
  facet_ncol = 7L,
  curve_breaks = c(0, 1, 10, 100, 250, 1000, 10000),
  ratio_title = "Light-source factor relative to the global smooth",
  ratio_y_label = "Factor for melEDI + 0.1",
  ratio_caption = paste(
    "Panel B exponentiates the light-source sz smooth with base 10;",
    "the factor applies to melEDI + 0.1, not exactly to the Panel A",
    "values after subtracting 0.1. The dashed null is 1 and no",
    "V0-style red significance segments are drawn without simultaneous bands."
  )
)

metadata <- list(
  source_model = h03_existing_artifact_metadata(
    model_path,
    source_model_producer
  )
)
stem <- "H03_temporal_log_gaussian_v0_display_near_eye_pilot"
metadata$curves <- write_csv_artifact(
  curves,
  file.path(source_root, paste0(stem, "_curves.csv")),
  producer
)
metadata$ratios <- write_csv_artifact(
  ratios,
  file.path(source_root, paste0(stem, "_ratios.csv")),
  producer
)
metadata$global <- write_csv_artifact(
  global,
  file.path(source_root, paste0(stem, "_global.csv")),
  producer
)

specification <- tibble::tibble(
  run_id = run_id,
  placement = "Near-eye",
  fitted_model = "accepted inherited log-Gaussian H03 temporal GAM",
  fit_engine = "mgcv::bam",
  formula = paste(deparse(object$formula), collapse = " "),
  family = fit$family$family,
  link = fit$family$link,
  response = "log10(geo_medi_1h + 0.1)",
  rho = object$rho,
  observations = stats::nobs(fit),
  participants = nlevels(data$participant),
  participant_days = nlevels(data$participant_day),
  sites = nlevels(data$site),
  categories = nlevels(data$light_source),
  panel_a_extraction = "gratia::fitted_values",
  panel_a_excluded_smooths = paste(
    excluded_population_smooths,
    collapse = " | "
  ),
  panel_b_extraction = "gratia::smooth_estimates",
  panel_b_estimand = "factor for melEDI + 0.1 relative to global smooth",
  covariance = "conditional coefficient covariance; smoothing uncertainty unavailable",
  simultaneous_bands = FALSE,
  new_model_fitted = FALSE
)
metadata$specification <- write_csv_artifact(
  specification,
  file.path(table_root, paste0(stem, "_specification.csv")),
  producer
)

saved <- h03_save_plot(
  figure,
  stem,
  figure_root,
  width = 18,
  height = 11.5,
  producer = producer
)
for (extension in names(saved)) {
  metadata[[paste0("figure_", extension)]] <- saved[[extension]]
}

environment <- tibble::tibble(
  component = c("R", required_packages),
  version = c(
    as.character(getRversion()),
    vapply(
      required_packages,
      function(package) as.character(utils::packageVersion(package)),
      character(1)
    )
  )
)
metadata$environment <- write_csv_artifact(
  environment,
  file.path(manifest_root, paste0(stem, "_environment.csv")),
  producer
)

manifest <- dplyr::bind_rows(lapply(metadata, manifest_row)) |>
  dplyr::arrange(.data$path)
write_csv_artifact(
  manifest,
  file.path(manifest_root, paste0(stem, "_manifest.csv")),
  producer
)
message("H03 old-GAM V0-style near-eye display pilot complete; no model refit")
