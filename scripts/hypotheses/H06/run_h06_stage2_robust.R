# Run H06-002 Stage 2 population-mean models, diagnostics, and comparisons.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)

source(file.path(root, "scripts/pipeline/paths_io.R"))
source(file.path(root, "scripts/hypotheses/H06/h06_contract.R"))
source(file.path(root, "scripts/hypotheses/H06/h06_modeling.R"))
source(file.path(root, "scripts/hypotheses/H06/h06_robust_modeling.R"))

options(lifecycle_verbosity = "quiet", warn = 1)

if (!identical(as.character(getRversion()), "4.6.1")) {
  h06_abort(
    "H06 Stage 2 requires R 4.6.1; found %s",
    as.character(getRversion())
  )
}

required_packages <- c(
  "dplyr", "tidyr", "purrr", "tibble", "readr", "digest", "openssl",
  "sandwich", "statmod", "glmmTMB", "performance", "emmeans", "LightLogR"
)
missing_packages <- required_packages[!vapply(
  required_packages,
  requireNamespace,
  logical(1),
  quietly = TRUE
)]
if (length(missing_packages) > 0L) {
  h06_abort(
    "H06 Stage 2 is missing project package(s): %s",
    paste(missing_packages, collapse = ", ")
  )
}

producer <- "scripts/hypotheses/H06/run_h06_stage2.R"
stage <- Sys.getenv("H06_STAGE", unset = "fit")
allowed_stages <- c(
  "prepare", "core", "sensitivities", "influence", "v0", "fit", "manifest"
)
if (!stage %in% allowed_stages) {
  h06_abort(
    "H06_STAGE must be one of: %s",
    paste(allowed_stages, collapse = ", ")
  )
}

roots <- list(
  model_data = file.path(root, "artifacts/06_model_data/H06"),
  models = file.path(root, "artifacts/07_models/H06"),
  diagnostics = file.path(root, "artifacts/08_diagnostics/H06"),
  tables = file.path(root, "artifacts/09_tables/H06"),
  figures = file.path(root, "artifacts/10_figures/H06"),
  source_data = file.path(root, "artifacts/11_source_data/H06"),
  manifests = file.path(root, "artifacts/12_manifests/H06")
)
invisible(vapply(
  roots,
  dir.create,
  logical(1),
  recursive = TRUE,
  showWarnings = FALSE
))

h06_write_csv <- function(data, path) {
  write_csv_artifact(data, path, producer = producer)
  invisible(path)
}

h06_write_rds <- function(object, path) {
  write_rds_artifact(object, path, producer = producer)
  invisible(path)
}

h06_relative_path <- function(path) {
  normalized <- normalizePath(path, winslash = "/", mustWork = TRUE)
  if (startsWith(normalized, paste0(root, "/"))) {
    substring(normalized, nchar(root) + 2L)
  } else {
    normalized
  }
}

h06_build_manifest <- function() {
  artifact_files <- sort(unique(unlist(lapply(
    roots,
    list.files,
    recursive = TRUE,
    full.names = TRUE
  ))))
  manifest_path <- file.path(roots$manifests, "H06_stage2_artifacts.csv")
  artifact_files <- artifact_files[
    file.exists(artifact_files) & !dir.exists(artifact_files) &
      normalizePath(artifact_files, winslash = "/", mustWork = TRUE) !=
        normalizePath(manifest_path, winslash = "/", mustWork = FALSE)
  ]
  code_and_report <- c(
    list.files(
      file.path(root, "scripts/hypotheses/H06"),
      pattern = "[.]R$", full.names = TRUE
    ),
    list.files(
      file.path(root, "tests/hypotheses/H06"),
      pattern = "[.]R$", full.names = TRUE
    ),
    list.files(
      file.path(root, "audit/hypotheses/H06"),
      pattern = "[.](qmd|html)$", full.names = TRUE
    ),
    list.files(
      file.path(root, "audit/handoffs"),
      pattern = "^H06.*[.]md$", full.names = TRUE
    )
  )
  files <- sort(unique(c(
    artifact_files,
    code_and_report[file.exists(code_and_report)]
  )))
  manifest <- dplyr::bind_rows(lapply(files, function(path) {
    info <- file.info(path)
    tibble::tibble(
      path = h06_relative_path(path),
      artifact_type = tools::file_ext(path),
      sha256 = artifact_sha256(path),
      bytes = as.numeric(info$size),
      producer = producer,
      r_version = as.character(getRversion()),
      written_utc = format(info$mtime, tz = "UTC", usetz = TRUE)
    )
  }))
  h06_write_csv(manifest, manifest_path)
  invisible(manifest_path)
}

if (identical(stage, "manifest")) {
  h06_build_manifest()
  message("H06 Stage 2 manifest refreshed")
  quit(save = "no", status = 0L)
}

h06_validate_contract()
input_contract <- h06_input_contract(root)
input_audit <- input_contract |>
  dplyr::rowwise() |>
  dplyr::mutate(
    observed_sha256 = artifact_sha256(.data$path),
    hash_verified = identical(.data$observed_sha256, .data$expected_sha256)
  ) |>
  dplyr::ungroup() |>
  dplyr::select(
    .data$input_role, .data$relative_path, .data$expected_sha256,
    .data$observed_sha256, .data$hash_verified
  )
if (any(!input_audit$hash_verified)) {
  failed <- input_audit$input_role[!input_audit$hash_verified]
  h06_abort("A frozen H06 input differs from its approved SHA-256: %s", paste(failed, collapse = ", "))
}

package_audit <- tibble::tibble(
  package = required_packages,
  version = vapply(
    required_packages,
    function(package) as.character(utils::packageVersion(package)),
    character(1)
  )
) |>
  dplyr::add_row(package = "R", version = as.character(getRversion()), .before = 1L)

site_registry <- readr::read_csv(
  file.path(root, "config/site_display_registry.csv"),
  show_col_types = FALSE
) |>
  dplyr::arrange(.data$display_order)
site_levels <- site_registry$site

input_path <- function(role) {
  input_contract$path[input_contract$input_role == role]
}
near_main <- readRDS(input_path("primary_near_eye_hourly"))
chest_main <- readRDS(input_path("complementary_chest_hourly"))
gap_hour <- readRDS(input_path("gap_timing_unaware_hourly"))
exercise_raw <- readRDS(input_path("normalized_exercise_diary"))
sleep_raw <- readRDS(input_path("normalized_sleep_diary"))
temporal_raw <- readr::read_csv(
  input_path("temporal_provenance"),
  col_types = readr::cols(.default = readr::col_character()),
  show_col_types = FALSE
)

prepared <- h06_build_run_frames(
  near_main = near_main,
  chest_main = chest_main,
  gap_hour = gap_hour,
  exercise_raw = exercise_raw,
  sleep_raw = sleep_raw,
  temporal_raw = temporal_raw,
  site_levels = site_levels
)
run_registry <- h06_run_registry()

gap_common_by_placement <- stats::setNames(
  lapply(c("glasses", "chest"), function(placement) {
    h06_exact_common_hour_frames(
      prepared$runs[[paste0("main__", placement, "__all_available")]],
      prepared$runs[[paste0(
        "gap_timing_unaware__", placement, "__all_available"
      )]]
    )
  }),
  c("glasses", "chest")
)
gap_common_frames <- list(
  main__glasses__gap_exact_common =
    gap_common_by_placement$glasses$reference,
  gap_timing_unaware__glasses__gap_exact_common =
    gap_common_by_placement$glasses$alternative,
  main__chest__gap_exact_common =
    gap_common_by_placement$chest$reference,
  gap_timing_unaware__chest__gap_exact_common =
    gap_common_by_placement$chest$alternative
)
gap_common_samples <- dplyr::bind_rows(lapply(
  names(gap_common_by_placement),
  function(placement) {
    gap_common_by_placement[[placement]]$summary |>
      dplyr::mutate(placement = placement, .before = 1L)
  }
))

sample_summary <- dplyr::bind_rows(lapply(seq_len(nrow(run_registry)), function(index) {
  run_id <- run_registry$run_id[[index]]
  h06_sample_summary(prepared$runs[[run_id]], run_id)
})) |>
  dplyr::left_join(run_registry, by = "run_id", relationship = "one-to-one") |>
  dplyr::arrange(.data$run_order)
expected_counts <- c(
  main__glasses__all_available = 16596L,
  main__chest__all_available = 18352L,
  main__glasses__paired_common = 12842L,
  main__chest__paired_common = 12842L,
  gap_timing_unaware__glasses__all_available = 16329L,
  gap_timing_unaware__chest__all_available = 18112L
)
observed_counts <- stats::setNames(
  sample_summary$one_hour_observations,
  sample_summary$run_id
)
if (!identical(as.integer(observed_counts[names(expected_counts)]), as.integer(expected_counts))) {
  h06_abort("The H06 Stage 2 candidate counts differ from the approved contract")
}

category_cells <- dplyr::bind_rows(lapply(names(prepared$runs), function(run_id) {
  h06_category_cells(prepared$runs[[run_id]], run_id)
}))
design_diagnostics <- dplyr::bind_rows(lapply(names(prepared$runs), function(run_id) {
  h06_design_diagnostics(prepared$runs[[run_id]], run_id)
}))
sequence_summary <- dplyr::bind_rows(lapply(names(prepared$runs), function(run_id) {
  prepared$runs[[run_id]] |>
    dplyr::summarise(
      one_hour_observations = dplyr::n(),
      irregular_elapsed_bins = sum(.data$irregular_elapsed_bin),
      sequence_starts = sum(.data$AR_start),
      true_time_sequences = dplyr::n_distinct(.data$hour_sequence_id),
      maximum_sequence_hours = max(.data$hour_sequence_position),
      non_3600_second_rows = sum(abs(.data$interval_seconds - 3600) > 1e-6),
      .by = "data_scenario_id"
    ) |>
    dplyr::mutate(run_id = run_id, .before = 1L)
}))
clock_composition <- dplyr::bind_rows(lapply(names(prepared$runs), function(run_id) {
  prepared$runs[[run_id]] |>
    dplyr::mutate(clock_hour_bin = floor(.data$clock_hour)) |>
    dplyr::summarise(
      one_hour_observations = dplyr::n(),
      participant_days = dplyr::n_distinct(.data$participant_day_key),
      participants = dplyr::n_distinct(.data$participant_key),
      .by = c("site", "work_free_day", "activity_status", "clock_hour_bin")
    ) |>
    dplyr::mutate(run_id = run_id, .before = 1L)
}))
candidate_flow_objects <- list(
  main__glasses = h06_candidate_flow(near_main, "glasses", "main", prepared$diaries),
  main__chest = h06_candidate_flow(chest_main, "chest", "main", prepared$diaries),
  gap_timing_unaware__glasses = h06_candidate_flow(
    gap_hour, "glasses", "gap_timing_unaware", prepared$diaries
  ),
  gap_timing_unaware__chest = h06_candidate_flow(
    gap_hour, "chest", "gap_timing_unaware", prepared$diaries
  )
)
candidate_flow <- dplyr::bind_rows(lapply(candidate_flow_objects, `[[`, "flow"))
candidate_missingness <- dplyr::bind_rows(lapply(candidate_flow_objects, `[[`, "fields"))
sleep_linkage <- h06_sleep_linkage_audit(sleep_raw)
tum_identity_summary <- tibble::tibble(
  source = "verified normalized exercise-diary artifact",
  tum_s001_rows = sum(exercise_raw$site == "TUM" & exercise_raw$Id == "TUM_S001"),
  tum_s101_rows = sum(exercise_raw$site == "TUM" & exercise_raw$Id == "TUM_S101"),
  local_identifier_rewrite = FALSE,
  assertion_pass = tum_s001_rows == 7L & tum_s101_rows == 0L
)

h06_write_csv(input_audit, file.path(roots$model_data, "H06_input_audit.csv"))
h06_write_csv(package_audit, file.path(roots$model_data, "H06_package_versions.csv"))
h06_write_csv(sample_summary, file.path(roots$model_data, "H06_exact_samples.csv"))
h06_write_csv(category_cells, file.path(roots$model_data, "H06_category_cells.csv"))
h06_write_csv(design_diagnostics, file.path(roots$model_data, "H06_design_diagnostics.csv"))
h06_write_csv(sequence_summary, file.path(roots$model_data, "H06_true_time_sequences.csv"))
h06_write_csv(clock_composition, file.path(roots$model_data, "H06_clock_composition.csv"))
h06_write_csv(candidate_flow, file.path(roots$model_data, "H06_candidate_flow.csv"))
h06_write_csv(candidate_missingness, file.path(roots$model_data, "H06_candidate_missingness.csv"))
h06_write_csv(sleep_linkage, file.path(roots$model_data, "H06_previous_night_linkage_audit.csv"))
h06_write_csv(prepared$diaries$tum_correction, file.path(roots$model_data, "H06_TUM_S001_assertion.csv"))
h06_write_csv(
  tum_identity_summary,
  file.path(roots$model_data, "H06_TUM_identity_summary.csv")
)
h06_write_csv(
  prepared$diaries$sedentary_reinterpreted,
  file.path(roots$model_data, "H06_KNUST_S005_exploratory_adapter.csv")
)
h06_write_csv(h06_predictor_registry(), file.path(roots$model_data, "H06_predictor_registry.csv"))
h06_write_csv(run_registry, file.path(roots$model_data, "H06_run_registry.csv"))
h06_write_csv(
  gap_common_samples,
  file.path(roots$model_data, "H06_gap_exact_common_samples.csv")
)
h06_write_csv(h06_multiplicity_registry(), file.path(roots$model_data, "H06_multiplicity_registry.csv"))
invisible(lapply(names(prepared$runs), function(run_id) {
  h06_write_rds(
    prepared$runs[[run_id]],
    file.path(roots$model_data, paste0(run_id, "__frame.rds"))
  )
}))
invisible(lapply(names(gap_common_frames), function(run_id) {
  h06_write_rds(
    gap_common_frames[[run_id]],
    file.path(roots$model_data, paste0(run_id, "__frame.rds"))
  )
}))

if (identical(stage, "prepare")) {
  h06_build_manifest()
  message("H06 Stage 2 preparation artifacts complete")
  quit(save = "no", status = 0L)
}

reuse_fits <- !identical(tolower(Sys.getenv("H06_REUSE_FITS", unset = "true")), "false")
frame_hashes <- stats::setNames(
  vapply(prepared$runs, h06_model_frame_hash, character(1)),
  names(prepared$runs)
)
formulas <- h06_formula_set()
core_path <- file.path(roots$models, "H06_robust_core_models.rds")
core_models <- if (reuse_fits && file.exists(core_path)) readRDS(core_path) else NULL
valid_core <- !is.null(core_models) &&
  identical(core_models$contract_version, "h06_002_robust_core_v1") &&
  identical(core_models$frame_hashes, frame_hashes)
if (!valid_core) {
  core_models <- list(
    contract_version = "h06_002_robust_core_v1",
    frame_hashes = frame_hashes,
    runs = stats::setNames(lapply(names(prepared$runs), function(run_id) {
      frame <- prepared$runs[[run_id]]
      list(
        additive = h06_fit_marginal(frame, formulas$additive, working_power = 1),
        full = h06_fit_marginal(frame, formulas$full, working_power = 1)
      )
    }), names(prepared$runs))
  )
  h06_write_rds(core_models, core_path)
}

fit_diagnostics <- list()
covariance_diagnostics <- list()
cluster_diagnostics <- list()
core_effects <- list()
site_effects <- list()
reference_means <- list()
residual_calibration <- list()
residual_bins <- list()
residual_clock <- list()
residual_acf <- list()
residual_rows <- list()
response_distribution <- list()

for (run_id in names(core_models$runs)) {
  frame <- prepared$runs[[run_id]]
  for (model_role in c("additive", "full")) {
    bundle <- core_models$runs[[run_id]][[model_role]]
    fit_diagnostics[[paste(run_id, model_role, sep = "__")]] <-
      h06_fit_diagnostics_robust(bundle, run_id, model_role)
    covariance_diagnostics[[paste(run_id, model_role, sep = "__")]] <-
      h06_covariance_diagnostic_rows(bundle, run_id, model_role)
    cluster_diagnostics[[paste(run_id, model_role, sep = "__")]] <-
      h06_cluster_diagnostics(bundle, run_id, model_role)
  }
  additive <- core_models$runs[[run_id]]$additive
  full <- core_models$runs[[run_id]]$full
  core_effects[[run_id]] <- dplyr::bind_rows(
    h06_core_estimands(additive, run_id, distribution = "equal_site"),
    h06_core_estimands(additive, run_id, distribution = "observed_sample")
  )
  site_effects[[run_id]] <- h06_core_estimands(
    full,
    run_id,
    model_role = "full",
    distribution = "equal_site",
    site_specific = TRUE
  )
  reference_means[[run_id]] <- dplyr::bind_rows(
    h06_reference_mean(additive, run_id, distribution = "equal_site"),
    h06_reference_mean(additive, run_id, distribution = "observed_sample")
  )
  residual <- h06_residual_outputs(additive, run_id, "additive")
  residual_calibration[[run_id]] <- residual$calibration
  residual_bins[[run_id]] <- residual$fitted_bins
  residual_clock[[run_id]] <- residual$clock
  residual_acf[[run_id]] <- residual$acf
  residual_rows[[run_id]] <- residual$row_source
  response_distribution[[run_id]] <- frame |>
    dplyr::summarise(
      observations = dplyr::n(),
      exact_zero_hours = sum(.data$response_value == 0),
      exact_zero_fraction = mean(.data$response_value == 0),
      minimum = min(.data$response_value),
      q01 = unname(stats::quantile(.data$response_value, 0.01)),
      median = stats::median(.data$response_value),
      q99 = unname(stats::quantile(.data$response_value, 0.99)),
      maximum = max(.data$response_value)
    ) |>
    dplyr::mutate(run_id = run_id, .before = 1L)
}

fit_diagnostics <- dplyr::bind_rows(fit_diagnostics)
covariance_diagnostics <- dplyr::bind_rows(covariance_diagnostics)
cluster_diagnostics <- dplyr::bind_rows(cluster_diagnostics)
core_effects <- dplyr::bind_rows(core_effects)
site_effects <- dplyr::bind_rows(site_effects)
reference_means <- dplyr::bind_rows(reference_means)

main_tests <- h06_primary_tests(
  core_models$runs$main__glasses__all_available$additive,
  core_models$runs$main__glasses__all_available$full,
  "main__glasses__all_available",
  "H06-F1-main",
  "H06-F2-heterogeneity"
)
gap_tests <- h06_primary_tests(
  core_models$runs$gap_timing_unaware__glasses__all_available$additive,
  core_models$runs$gap_timing_unaware__glasses__all_available$full,
  "gap_timing_unaware__glasses__all_available",
  "H06-F1-gap",
  "H06-F2-gap"
)
wald_tests <- dplyr::bind_rows(
  main_tests$main,
  main_tests$heterogeneity,
  gap_tests$main,
  gap_tests$heterogeneity
)
f3 <- core_effects |>
  dplyr::filter(
    .data$run_id == "main__glasses__all_available",
    .data$distribution == "equal_site"
  ) |>
  h06_f3_family()
main_effect_p <- main_tests$main |>
  dplyr::select(.data$run_id, .data$predictor_id, .data$family_id, .data$p_adjusted)
gap_effect_p <- gap_tests$main |>
  dplyr::select(.data$run_id, .data$predictor_id, .data$family_id, .data$p_adjusted)
core_effects <- core_effects |>
  dplyr::left_join(
    dplyr::bind_rows(main_effect_p, gap_effect_p),
    by = c("run_id", "predictor_id"),
    relationship = "many-to-one"
  )

h06_write_csv(fit_diagnostics, file.path(roots$diagnostics, "H06_robust_fit_diagnostics.csv"))
h06_write_csv(
  covariance_diagnostics,
  file.path(roots$diagnostics, "H06_robust_covariance_diagnostics.csv")
)
h06_write_csv(
  cluster_diagnostics,
  file.path(roots$diagnostics, "H06_robust_cluster_influence.csv")
)
h06_write_csv(
  dplyr::bind_rows(residual_calibration),
  file.path(roots$diagnostics, "H06_robust_fitted_decile_calibration.csv")
)
h06_write_csv(
  dplyr::bind_rows(residual_bins),
  file.path(roots$diagnostics, "H06_robust_residual_fitted_bins.csv")
)
h06_write_csv(
  dplyr::bind_rows(residual_clock),
  file.path(roots$diagnostics, "H06_robust_residuals_by_local_clock.csv")
)
h06_write_csv(
  dplyr::bind_rows(residual_acf),
  file.path(roots$diagnostics, "H06_robust_residual_acf.csv")
)
h06_write_csv(
  dplyr::bind_rows(response_distribution),
  file.path(roots$diagnostics, "H06_robust_response_distribution.csv")
)
h06_write_csv(
  dplyr::bind_rows(residual_rows),
  file.path(roots$source_data, "H06_robust_residual_row_source.csv")
)
h06_write_csv(wald_tests, file.path(roots$tables, "H06_robust_wald_tests.csv"))
h06_write_csv(core_effects, file.path(roots$tables, "H06_robust_core_effects.csv"))
h06_write_csv(site_effects, file.path(roots$tables, "H06_robust_site_specific_effects.csv"))
h06_write_csv(reference_means, file.path(roots$tables, "H06_robust_reference_means.csv"))
h06_write_csv(f3, file.path(roots$tables, "H06_robust_F3_practical_contrasts.csv"))

if (identical(stage, "core")) {
  h06_build_manifest()
  message("H06 Stage 2 robust core models and diagnostics complete")
  quit(save = "no", status = 0L)
}

p18_path <- file.path(roots$models, "H06_robust_p18_models.rds")
p18_models <- if (reuse_fits && file.exists(p18_path)) readRDS(p18_path) else NULL
valid_p18 <- !is.null(p18_models) &&
  identical(p18_models$contract_version, "h06_002_p18_sensitivity_v1") &&
  identical(p18_models$frame_hashes, frame_hashes)
if (!valid_p18) {
  p18_models <- list(
    contract_version = "h06_002_p18_sensitivity_v1",
    frame_hashes = frame_hashes,
    runs = stats::setNames(lapply(names(prepared$runs), function(run_id) {
      frame <- prepared$runs[[run_id]]
      list(
        additive = h06_fit_marginal(frame, formulas$additive, working_power = 1.8),
        full = h06_fit_marginal(frame, formulas$full, working_power = 1.8)
      )
    }), names(prepared$runs))
  )
  h06_write_rds(p18_models, p18_path)
}
p18_diagnostics <- dplyr::bind_rows(lapply(names(p18_models$runs), function(run_id) {
  dplyr::bind_rows(
    h06_fit_diagnostics_robust(p18_models$runs[[run_id]]$additive, run_id, "p18_additive"),
    h06_fit_diagnostics_robust(p18_models$runs[[run_id]]$full, run_id, "p18_full")
  )
}))
p18_effects <- dplyr::bind_rows(lapply(names(p18_models$runs), function(run_id) {
  h06_core_estimands(
    p18_models$runs[[run_id]]$additive,
    run_id,
    model_role = "p18_additive",
    distribution = "equal_site"
  )
}))
p18_main_tests <- h06_primary_tests(
  p18_models$runs$main__glasses__all_available$additive,
  p18_models$runs$main__glasses__all_available$full,
  "main__glasses__all_available",
  "H06-F1-main",
  "H06-F2-heterogeneity"
)
p18_gap_tests <- h06_primary_tests(
  p18_models$runs$gap_timing_unaware__glasses__all_available$additive,
  p18_models$runs$gap_timing_unaware__glasses__all_available$full,
  "gap_timing_unaware__glasses__all_available",
  "H06-F1-gap",
  "H06-F2-gap"
)
p18_tests <- dplyr::bind_rows(
  p18_main_tests$main,
  p18_main_tests$heterogeneity,
  p18_gap_tests$main,
  p18_gap_tests$heterogeneity
) |>
  dplyr::mutate(sensitivity_role = "fixed_working_power_p1_8_no_new_family")
p18_main_effect_p <- p18_main_tests$main |>
  dplyr::select(.data$run_id, .data$predictor_id, .data$p_adjusted)
p18_gap_effect_p <- p18_gap_tests$main |>
  dplyr::select(.data$run_id, .data$predictor_id, .data$p_adjusted)
p18_effects <- p18_effects |>
  dplyr::left_join(
    dplyr::bind_rows(p18_main_effect_p, p18_gap_effect_p),
    by = c("run_id", "predictor_id"),
    relationship = "many-to-one"
  )

gap_common_frame_hashes <- stats::setNames(
  vapply(gap_common_frames, h06_model_frame_hash, character(1)),
  names(gap_common_frames)
)
gap_common_path <- file.path(
  roots$models,
  "H06_robust_gap_exact_common_models.rds"
)
gap_common_models <- if (
  reuse_fits && file.exists(gap_common_path)
) {
  readRDS(gap_common_path)
} else {
  NULL
}
valid_gap_common <- !is.null(gap_common_models) &&
  identical(
    gap_common_models$contract_version,
    "h06_002_gap_exact_common_v1"
  ) &&
  identical(gap_common_models$frame_hashes, gap_common_frame_hashes)
if (!valid_gap_common) {
  gap_common_models <- list(
    contract_version = "h06_002_gap_exact_common_v1",
    frame_hashes = gap_common_frame_hashes,
    runs = stats::setNames(lapply(names(gap_common_frames), function(run_id) {
      frame <- gap_common_frames[[run_id]]
      list(
        additive = h06_fit_marginal(
          frame,
          formulas$additive,
          working_power = 1
        ),
        full = h06_fit_marginal(
          frame,
          formulas$full,
          working_power = 1
        )
      )
    }), names(gap_common_frames))
  )
  h06_write_rds(gap_common_models, gap_common_path)
}
gap_common_diagnostics <- dplyr::bind_rows(lapply(
  names(gap_common_models$runs),
  function(run_id) {
    dplyr::bind_rows(
      h06_fit_diagnostics_robust(
        gap_common_models$runs[[run_id]]$additive,
        run_id,
        "gap_exact_common_additive"
      ),
      h06_fit_diagnostics_robust(
        gap_common_models$runs[[run_id]]$full,
        run_id,
        "gap_exact_common_full"
      )
    )
  }
))
gap_common_effects <- dplyr::bind_rows(lapply(
  names(gap_common_models$runs),
  function(run_id) {
    h06_core_estimands(
      gap_common_models$runs[[run_id]]$additive,
      run_id,
      model_role = "gap_exact_common_additive",
      distribution = "equal_site"
    )
  }
))
gap_common_main_tests <- h06_primary_tests(
  gap_common_models$runs$main__glasses__gap_exact_common$additive,
  gap_common_models$runs$main__glasses__gap_exact_common$full,
  "main__glasses__gap_exact_common",
  "H06-F1-main",
  "H06-F2-heterogeneity"
)
gap_common_alternative_tests <- h06_primary_tests(
  gap_common_models$runs$gap_timing_unaware__glasses__gap_exact_common$additive,
  gap_common_models$runs$gap_timing_unaware__glasses__gap_exact_common$full,
  "gap_timing_unaware__glasses__gap_exact_common",
  "H06-F1-gap",
  "H06-F2-gap"
)
gap_common_tests <- dplyr::bind_rows(
  gap_common_main_tests$main,
  gap_common_main_tests$heterogeneity,
  gap_common_alternative_tests$main,
  gap_common_alternative_tests$heterogeneity
) |>
  dplyr::mutate(
    sensitivity_role = "exact_common_hour_refit_no_new_family"
  )
gap_common_effect_p <- dplyr::bind_rows(
  gap_common_main_tests$main,
  gap_common_alternative_tests$main
) |>
  dplyr::select(.data$run_id, .data$predictor_id, .data$p_adjusted)
gap_common_effects <- gap_common_effects |>
  dplyr::left_join(
    gap_common_effect_p,
    by = c("run_id", "predictor_id"),
    relationship = "many-to-one"
  )

primary_additive <- core_models$runs$main__glasses__all_available$additive
covariance_effects <- dplyr::bind_rows(lapply(c("HC0", "HC1", "HC2", "HC3"), function(type) {
  h06_core_estimands(
    primary_additive,
    "main__glasses__all_available",
    covariance_type = type
  )
}))

weekend_bundle <- h06_fit_marginal(
  prepared$runs$main__glasses__all_available,
  formulas$weekend_additive,
  working_power = 1
)
weekend_effects <- dplyr::bind_rows(
  h06_standardized_contrast(
    weekend_bundle,
    "weekday_weekend",
    high = "Weekend",
    low = "Weekday"
  ) |>
    dplyr::mutate(predictor_id = "weekday_weekend", effect_id = "weekend_vs_weekday"),
  h06_standardized_contrast(
    weekend_bundle,
    "activity_status",
    high = h06_activity_levels()[[2L]],
    low = h06_activity_levels()[[1L]]
  ) |>
    dplyr::mutate(predictor_id = "activity_status", effect_id = "active_vs_sedentary"),
  h06_standardized_contrast(
    weekend_bundle,
    "previous_sleep_duration_centered_h",
    increment = 1
  ) |>
    dplyr::mutate(
      predictor_id = "previous_sleep_duration_centered_h",
      effect_id = "per_hour_previous_sleep"
    )
) |>
  dplyr::mutate(
    run_id = "main__glasses__all_available",
    sensitivity_role = "weekday_weekend_estimate_CI_no_new_family",
    statistic = NA_real_,
    p_raw = NA_real_,
    .before = 1L
  )

primary_equal <- core_effects |>
  dplyr::filter(
    .data$run_id == "main__glasses__all_available",
    .data$distribution == "equal_site"
  )
gap_equal <- core_effects |>
  dplyr::filter(
    .data$run_id == "gap_timing_unaware__glasses__all_available",
    .data$distribution == "equal_site"
  )
main_gap_common_equal <- gap_common_effects |>
  dplyr::filter(.data$run_id == "main__glasses__gap_exact_common")
alternative_gap_common_equal <- gap_common_effects |>
  dplyr::filter(
    .data$run_id ==
      "gap_timing_unaware__glasses__gap_exact_common"
  )
p18_primary <- p18_effects |>
  dplyr::filter(.data$run_id == "main__glasses__all_available")
hc1_primary <- covariance_effects |>
  dplyr::filter(.data$covariance_type == "HC1")
hc2_primary <- covariance_effects |>
  dplyr::filter(.data$covariance_type == "HC2")
primary_observed <- core_effects |>
  dplyr::filter(
    .data$run_id == "main__glasses__all_available",
    .data$distribution == "observed_sample"
  )
paired_near <- core_effects |>
  dplyr::filter(
    .data$run_id == "main__glasses__paired_common",
    .data$distribution == "equal_site"
  )
paired_chest <- core_effects |>
  dplyr::filter(
    .data$run_id == "main__chest__paired_common",
    .data$distribution == "equal_site"
  )
chest_all <- core_effects |>
  dplyr::filter(
    .data$run_id == "main__chest__all_available",
    .data$distribution == "equal_site"
  )

sensitivity_comparisons <- dplyr::bind_rows(
  h06_compare_effect_sets(
    primary_equal,
    gap_equal,
    "primary_vs_gap_timing_unaware_all_available"
  ),
  h06_compare_effect_sets(
    main_gap_common_equal,
    alternative_gap_common_equal,
    "primary_vs_gap_timing_unaware_exact_common_hours"
  ),
  h06_compare_effect_sets(
    primary_equal,
    main_gap_common_equal,
    "primary_all_available_vs_primary_exact_common_hours"
  ),
  h06_compare_effect_sets(
    gap_equal,
    alternative_gap_common_equal,
    "gap_all_available_vs_gap_exact_common_hours"
  ),
  h06_compare_effect_sets(primary_equal, p18_primary, "quasi_poisson_vs_fixed_p1_8"),
  h06_compare_effect_sets(primary_equal, hc1_primary, "HC3_vs_HC1"),
  h06_compare_effect_sets(primary_equal, hc2_primary, "HC3_vs_HC2"),
  h06_compare_effect_sets(primary_equal, primary_observed, "equal_site_vs_observed_sample"),
  h06_compare_effect_sets(primary_equal, chest_all, "near_eye_vs_chest_all_available"),
  h06_compare_effect_sets(paired_near, paired_chest, "paired_common_near_eye_vs_chest")
)

exploratory_path <- file.path(roots$models, "H06_robust_exploratory_models.rds")
exploratory_models <- if (reuse_fits && file.exists(exploratory_path)) {
  readRDS(exploratory_path)
} else {
  NULL
}
exploratory_frames <- stats::setNames(lapply(names(h06_exploratory_formula_set()), function(id) {
  h06_exploratory_frame(prepared$runs$main__glasses__all_available, id)
}), names(h06_exploratory_formula_set()))
exploratory_hashes <- vapply(exploratory_frames, h06_model_frame_hash, character(1))
valid_exploratory <- !is.null(exploratory_models) &&
  identical(exploratory_models$contract_version, "h06_002_exploratory_robust_v1") &&
  identical(exploratory_models$frame_hashes, exploratory_hashes)
if (!valid_exploratory) {
  exploratory_models <- list(
    contract_version = "h06_002_exploratory_robust_v1",
    frame_hashes = exploratory_hashes,
    analyses = stats::setNames(lapply(names(exploratory_frames), function(id) {
      h06_fit_marginal(
        exploratory_frames[[id]],
        h06_exploratory_formula_set()[[id]],
        working_power = 1
      )
    }), names(exploratory_frames))
  )
  h06_write_rds(exploratory_models, exploratory_path)
}
exploratory_effects <- dplyr::bind_rows(lapply(names(exploratory_models$analyses), function(id) {
  h06_exploratory_estimands(exploratory_models$analyses[[id]], id)
}))
exploratory_samples <- dplyr::bind_rows(lapply(names(exploratory_frames), function(id) {
  h06_sample_summary(exploratory_frames[[id]], paste0("exploratory__", id)) |>
    dplyr::mutate(analysis_id = id, inferential_role = "exploratory")
}))
exploratory_diagnostics <- dplyr::bind_rows(lapply(names(exploratory_models$analyses), function(id) {
  h06_fit_diagnostics_robust(
    exploratory_models$analyses[[id]],
    paste0("exploratory__", id),
    "exploratory"
  )
}))

v0_frames_path <- file.path(roots$model_data, "H06_current_pin_V0_method_frames.rds")
v0_frames <- if (file.exists(v0_frames_path)) readRDS(v0_frames_path) else NULL
valid_v0_frames <- !is.null(v0_frames) && all(vapply(
  v0_frames,
  function(frame) identical(
    attr(frame, "h06_v0_frame_contract_version"),
    "v1_exact_filter_out_retains_unknown_static_days"
  ),
  logical(1)
))
if (!valid_v0_frames) {
  v0_frames <- list(
    glasses = h06_v0_method_frame(input_path("v0_near_eye_light"), exercise_raw, sleep_raw, "glasses"),
    chest = h06_v0_method_frame(input_path("v0_chest_light"), exercise_raw, sleep_raw, "chest")
  )
  h06_write_rds(v0_frames, v0_frames_path)
}
if (nrow(v0_frames$glasses) != 16500L || nrow(v0_frames$chest) != 18218L) {
  h06_abort("The current-pin V0-method sample differs from the audited reconstruction")
}
v0_bundles <- list()
for (placement in c("glasses", "chest")) {
  path <- file.path(roots$models, paste0("H06_current_pin_V0_method__", placement, ".rds"))
  bundle <- if (reuse_fits && file.exists(path)) readRDS(path) else NULL
  valid_bundle <- !is.null(bundle) && identical(
    bundle$frame_sha256,
    digest::digest(
      list(
        v0_frames[[placement]]$.model_row_id,
        v0_frames[[placement]]$geo.MEDI,
        v0_frames[[placement]]$daytype,
        v0_frames[[placement]]$exercise,
        v0_frames[[placement]]$sleep_duration
      ),
      algo = "sha256",
      serialize = TRUE
    )
  )
  if (!valid_bundle) {
    bundle <- h06_fit_v0_method(v0_frames[[placement]])
    h06_write_rds(bundle, path)
  }
  v0_bundles[[placement]] <- bundle
}
v0_tests <- suppressMessages(dplyr::bind_rows(
  h06_v0_method_tests(v0_bundles$glasses, "glasses"),
  h06_v0_method_tests(v0_bundles$chest, "chest")
))
v0_effects <- suppressMessages(dplyr::bind_rows(
  h06_v0_method_effects(v0_bundles$glasses, "glasses"),
  h06_v0_method_effects(v0_bundles$chest, "chest")
))
v0_reference <- suppressMessages(dplyr::bind_rows(
  h06_v0_method_reference(v0_bundles$glasses, "glasses"),
  h06_v0_method_reference(v0_bundles$chest, "chest")
))
v0_performance <- dplyr::bind_rows(
  h06_v0_method_performance(v0_bundles$glasses, "glasses"),
  h06_v0_method_performance(v0_bundles$chest, "chest")
)

h06_write_csv(p18_diagnostics, file.path(roots$diagnostics, "H06_robust_p18_fit_diagnostics.csv"))
h06_write_csv(
  gap_common_diagnostics,
  file.path(
    roots$diagnostics,
    "H06_robust_gap_exact_common_fit_diagnostics.csv"
  )
)
h06_write_csv(exploratory_diagnostics, file.path(roots$diagnostics, "H06_robust_exploratory_diagnostics.csv"))
h06_write_csv(p18_effects, file.path(roots$tables, "H06_robust_p18_effects.csv"))
h06_write_csv(p18_tests, file.path(roots$tables, "H06_robust_p18_wald_tests.csv"))
h06_write_csv(
  gap_common_effects,
  file.path(roots$tables, "H06_robust_gap_exact_common_effects.csv")
)
h06_write_csv(
  gap_common_tests,
  file.path(roots$tables, "H06_robust_gap_exact_common_wald_tests.csv")
)
h06_write_csv(covariance_effects, file.path(roots$tables, "H06_robust_covariance_effects.csv"))
h06_write_csv(weekend_effects, file.path(roots$tables, "H06_robust_weekday_weekend_effects.csv"))
h06_write_csv(sensitivity_comparisons, file.path(roots$tables, "H06_robust_sensitivity_comparisons.csv"))
h06_write_csv(exploratory_effects, file.path(roots$tables, "H06_robust_exploratory_effects.csv"))
h06_write_csv(exploratory_samples, file.path(roots$model_data, "H06_exploratory_predictor_samples.csv"))
h06_write_csv(v0_tests, file.path(roots$tables, "H06_current_pin_V0_method_tests.csv"))
h06_write_csv(v0_effects, file.path(roots$tables, "H06_current_pin_V0_method_effects.csv"))
h06_write_csv(v0_reference, file.path(roots$tables, "H06_current_pin_V0_method_reference.csv"))
h06_write_csv(v0_performance, file.path(roots$tables, "H06_current_pin_V0_method_performance.csv"))
h06_write_csv(h06_v0_output_summary(), file.path(roots$tables, "H06_frozen_V0_output_summary.csv"))

if (identical(stage, "sensitivities") || identical(stage, "v0")) {
  h06_build_manifest()
  message("H06 Stage 2 robust sensitivities, explorations, and V0 comparison complete")
  quit(save = "no", status = 0L)
}

influence_path <- file.path(roots$models, "H06_robust_influence_deletions.rds")
influence_contract <- list(
  contract_version = "h06_002_influence_v1",
  primary_frame_hash = frame_hashes[["main__glasses__all_available"]]
)
influence_object <- if (reuse_fits && file.exists(influence_path)) {
  readRDS(influence_path)
} else {
  NULL
}
if (is.null(influence_object) || !identical(influence_object$contract, influence_contract)) {
  influence_object <- list(
    contract = influence_contract,
    results = h06_deletion_battery(
      prepared$runs$main__glasses__all_available,
      core_models$runs$main__glasses__all_available$additive,
      core_models$runs$main__glasses__all_available$full
    )
  )
  h06_write_rds(influence_object, influence_path)
}
influence_deletions <- influence_object$results
extreme_exploratory_records <- h06_extreme_exploratory_records(
  prepared$runs$main__glasses__all_available
)
h06_write_csv(
  influence_deletions,
  file.path(roots$diagnostics, "H06_robust_influence_deletions.csv")
)
h06_write_csv(
  extreme_exploratory_records,
  file.path(roots$diagnostics, "H06_extreme_exploratory_records.csv")
)

model_manifest <- dplyr::bind_rows(
  fit_diagnostics |>
    dplyr::mutate(
      implementation_id = "h06_002_quasi_poisson_HC3",
      inferential_role = "primary_or_contextual_by_run_registry"
    ),
  p18_diagnostics |>
    dplyr::mutate(
      implementation_id = "h06_002_fixed_p1_8_HC3",
      inferential_role = "working_variance_sensitivity"
    ),
  gap_common_diagnostics |>
    dplyr::mutate(
      implementation_id = "h06_002_quasi_poisson_HC3",
      inferential_role = "gap_exact_common_hour_sensitivity"
    ),
  exploratory_diagnostics |>
    dplyr::mutate(
      implementation_id = "h06_002_exploratory_quasi_poisson_HC3",
      inferential_role = "exploratory_no_confirmatory_p_family"
    )
)
h06_write_csv(model_manifest, file.path(roots$models, "H06_robust_model_manifest.csv"))

if (identical(stage, "influence")) {
  h06_build_manifest()
  message("H06 Stage 2 deterministic influence battery complete")
  quit(save = "no", status = 0L)
}

h06_build_manifest()
message("H06 Stage 2 H06-002 analytical producer complete")
