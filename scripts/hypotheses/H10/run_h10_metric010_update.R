#!/usr/bin/env Rscript

# Selectively replace the repaired gap-timing-unaware H10 MDER branch after
# FIND-049/CHG-101. Primary MDER and the other 16 metric branches are loaded
# from the accepted H10 artifacts and guarded for exact identity. This script
# never refits a primary all-available or non-MDER model.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
project_library <- file.path(
  root,
  "renv/library/macos/R-4.6/aarch64-apple-darwin23"
)
if (!dir.exists(project_library)) {
  stop("The authoritative R 4.6 project library is unavailable", call. = FALSE)
}
.libPaths(c(project_library, .libPaths()))

source(file.path(root, "scripts/pipeline/paths_io.R"))
source(file.path(root, "scripts/pipeline/assertions.R"))
source(file.path(root, "scripts/pipeline/multiplicity.R"))
source(file.path(root, "scripts/pipeline/p_value_display.R"))
source(file.path(root, "scripts/pipeline/verify_base_model_data_artifacts.R"))
source(file.path(root, "scripts/hypotheses/H10/h10_contract.R"))
source(file.path(root, "scripts/hypotheses/H10/h10_modeling.R"))

options(lifecycle_verbosity = "quiet", warn = 1)
if (!identical(as.character(getRversion()), "4.6.1")) {
  h10_abort(
    "H10 METRIC-010 update requires R 4.6.1; found %s",
    as.character(getRversion())
  )
}

required_packages <- c(
  "dplyr", "tidyr", "tibble", "readr", "digest", "openssl", "lme4",
  "reformulas", "glmmTMB", "performance"
)
missing_packages <- required_packages[!vapply(
  required_packages,
  requireNamespace,
  logical(1),
  quietly = TRUE
)]
if (length(missing_packages) > 0L) {
  h10_abort(
    "H10 METRIC-010 update is missing project package(s): %s",
    paste(missing_packages, collapse = ", ")
  )
}

h10_validate_contract()
producer <- "scripts/hypotheses/H10/run_h10_metric010_update.R"
old_mder_id <- "mder_ratio_of_integrals"
mder_id <- "mder_mean_of_viable_ratios"
mder_ids <- c(old_mder_id, mder_id)

roots <- list(
  model_data = file.path(root, "artifacts/06_model_data/H10"),
  models = file.path(root, "artifacts/07_models/H10"),
  diagnostics = file.path(root, "artifacts/08_diagnostics/H10"),
  sensitivity = file.path(root, "artifacts/08_diagnostics/H10/sensitivity"),
  tables = file.path(root, "artifacts/09_tables/H10"),
  source_data = file.path(root, "artifacts/11_source_data/H10"),
  manifests = file.path(root, "artifacts/12_manifests/H10")
)
invisible(vapply(
  roots,
  dir.create,
  logical(1),
  recursive = TRUE,
  showWarnings = FALSE
))

h10_write_csv <- function(data, path) {
  write_csv_artifact(data, path, producer = producer)
  invisible(path)
}

h10_write_rds <- function(object, path) {
  write_rds_artifact(object, path, producer = producer)
  invisible(path)
}

h10_hash_object <- function(object) {
  digest::digest(object, algo = "sha256", serialize = TRUE)
}

h10_hash_canonical_csv_rows <- function(data) {
  text <- readr::format_csv(data, na = "")
  lines <- strsplit(text, "\n", fixed = TRUE)[[1L]]
  lines <- lines[nzchar(lines)]
  header <- if (length(lines) > 0L) lines[[1L]] else ""
  rows <- if (length(lines) > 1L) sort(lines[-1L]) else character()
  digest::digest(
    paste(c(header, rows), collapse = "\n"),
    algo = "sha256",
    serialize = FALSE
  )
}

h10_non_mder_rows <- function(data) {
  if (!"metric_id" %in% names(data)) {
    return(data)
  }
  data[!data$metric_id %in% mder_ids, , drop = FALSE]
}

h10_replace_metric_rows <- function(old, replacement) {
  dplyr::bind_rows(h10_non_mder_rows(old), replacement)
}

h10_replace_metric_scenarios <- function(old, replacement, scenarios) {
  required <- c("metric_id", "data_scenario")
  if (!all(required %in% names(old)) || !all(required %in% names(replacement))) {
    h10_abort("Scenario-specific metric replacement requires metric and scenario fields")
  }
  keep <- !(
    old$metric_id %in% mder_ids &
      old$data_scenario %in% scenarios
  )
  dplyr::bind_rows(old[keep, , drop = FALSE], replacement)
}

h10_keep_non_mder_list <- function(object) {
  object[!grepl("mder", names(object), ignore.case = TRUE)]
}

h10_frame_summary <- function(frame) {
  tibble::tibble(
    observations = nrow(frame),
    participants = dplyr::n_distinct(frame$participant_key),
    participant_days = if (all(is.na(frame$local_date))) NA_integer_ else nrow(frame),
    contributing_participant_days = if (
      all(is.na(frame$participant_days_contributing))
    ) {
      NA_real_
    } else {
      sum(frame$participant_days_contributing, na.rm = TRUE)
    },
    metric_support_valid_hours = if (
      all(is.na(frame$metric_support_valid_minutes))
    ) {
      NA_real_
    } else {
      sum(frame$metric_support_valid_minutes, na.rm = TRUE) / 60
    },
    metric_support_expected_hours = if (
      all(is.na(frame$metric_support_expected_minutes))
    ) {
      NA_real_
    } else {
      sum(frame$metric_support_expected_minutes, na.rm = TRUE) / 60
    },
    sites = dplyr::n_distinct(frame$site),
    female_participants = dplyr::n_distinct(
      frame$participant_key[frame$biological_sex == "Female"]
    ),
    male_participants = dplyr::n_distinct(
      frame$participant_key[frame$biological_sex == "Male"]
    ),
    age_min = min(frame$age),
    age_max = max(frame$age),
    row_key_hash = h10_key_hash(frame),
    model_frame_sha256 = h10_frame_hash(frame)
  )
}

h10_add_age_per_year <- function(effect, spec) {
  if (effect$predictor != "age") {
    return(effect |>
      dplyr::mutate(
        estimate_practical_per_year = NA_real_,
        conf_low_practical_per_year = NA_real_,
        conf_high_practical_per_year = NA_real_
      ))
  }
  per_year <- h10_effect_transform(
    effect$estimate_model / 10,
    effect$conf_low_model / 10,
    effect$conf_high_model / 10,
    spec
  )
  effect |>
    dplyr::mutate(
      estimate_practical_per_year = per_year$estimate_practical,
      conf_low_practical_per_year = per_year$conf_low_practical,
      conf_high_practical_per_year = per_year$conf_high_practical
    )
}

h10_effect_row <- function(bundle, frame, predictor, spec) {
  model_name <- if (predictor == "age") "M_age" else "M_sex"
  effect <- h10_coefficient_summary(
    bundle$final_fits[[model_name]]$model,
    predictor,
    spec
  ) |>
    h10_add_age_per_year(spec)
  response_sd <- stats::sd(frame$response)
  effect |>
    dplyr::mutate(
      response_model_scale_sd = response_sd,
      standardized_estimate = .data$estimate_model / response_sd,
      standardized_conf_low = .data$conf_low_model / response_sd,
      standardized_conf_high = .data$conf_high_model / response_sd
    ) |>
    dplyr::bind_cols(h10_frame_summary(frame))
}

h10_fit_main_sensitivity <- function(frame, spec, predictor) {
  formula_name <- if (predictor == "age") "M_age" else "M_sex"
  formulas <- h10_formula_set(spec$analysis_unit)
  reduced <- h10_fit_model(frame, formulas$M0, spec, reml = FALSE)
  full_ml <- h10_fit_model(
    frame,
    formulas[[formula_name]],
    spec,
    reml = FALSE
  )
  comparison <- h10_compare_models(reduced, full_ml)
  final <- h10_fit_model(
    frame,
    formulas[[formula_name]],
    spec,
    reml = TRUE
  )
  effect <- h10_coefficient_summary(final$model, predictor, spec) |>
    h10_add_age_per_year(spec)
  response_sd <- stats::sd(frame$response)
  summary <- dplyr::bind_cols(
    comparison,
    effect |>
      dplyr::mutate(
        response_model_scale_sd = response_sd,
        standardized_estimate = .data$estimate_model / response_sd,
        standardized_conf_low = .data$conf_low_model / response_sd,
        standardized_conf_high = .data$conf_high_model / response_sd
      ),
    h10_frame_summary(frame),
    h10_model_fit_status(final$model) |>
      dplyr::rename_with(~ paste0("final_", .x)),
    tibble::tibble(
      reduced_formula = deparse1(formulas$M0),
      full_formula = deparse1(formulas[[formula_name]]),
      reduced_warnings = paste(reduced$warnings, collapse = " | "),
      full_ml_warnings = paste(full_ml$warnings, collapse = " | "),
      final_warnings = paste(final$warnings, collapse = " | "),
      fit_errors = paste(
        stats::na.omit(c(reduced$error, full_ml$error, final$error)),
        collapse = " | "
      )
    )
  )
  list(
    summary = summary,
    models = list(reduced_ml = reduced, full_ml = full_ml, final = final)
  )
}

h10_common_key <- function(rows, analysis_unit) {
  if (analysis_unit == "participant") {
    paste(rows$site, rows$Id, sep = "|")
  } else {
    paste(rows$site, rows$Id, as.character(rows$local_date), sep = "|")
  }
}

h10_adjust_families <- function(
  data,
  family_columns,
  selected_scenarios = NULL
) {
  if (!"p_adjusted" %in% names(data)) {
    data$p_adjusted <- NA_real_
  }
  groups <- interaction(data[family_columns], drop = TRUE, lex.order = TRUE)
  for (group in unique(groups)) {
    rows <- which(groups == group)
    if (length(rows) != 17L) {
      h10_abort("An H10 multiplicity family is not a 17-row registry")
    }
    selected <- is.null(selected_scenarios) ||
      !"data_scenario" %in% names(data) ||
      data$data_scenario[[rows[[1L]]]] %in% selected_scenarios
    if (selected) {
      data$p_adjusted[rows] <- adjust_p_family(
        data$p_raw[rows],
        method = "BH",
        n = 17L
      )
    } else if (any(
      is.finite(data$p_raw[rows]) & !is.finite(data$p_adjusted[rows])
    )) {
      h10_abort("A frozen multiplicity family has an unavailable adjusted p-value")
    }
  }
  update_rows <- if (
    is.null(selected_scenarios) || !"data_scenario" %in% names(data)
  ) {
    rep(TRUE, nrow(data))
  } else {
    data$data_scenario %in% selected_scenarios
  }
  data$raw_significant[update_rows] <-
    is.finite(data$p_raw[update_rows]) & data$p_raw[update_rows] <= 0.05
  data$adjusted_significant[update_rows] <-
    is.finite(data$p_adjusted[update_rows]) &
      data$p_adjusted[update_rows] <= 0.05
  data$p_raw_display[update_rows] <- nh_format_p_value(data$p_raw[update_rows])
  data$p_adjusted_display[update_rows] <-
    nh_format_p_value(data$p_adjusted[update_rows])
  data
}

####
# Verify the controlling amendment and shared inputs
####

input_contract <- h10_input_contract(root)
input_audit <- input_contract |>
  dplyr::mutate(
    exists = file.exists(.data$absolute_path),
    observed_sha256 = vapply(
      .data$absolute_path,
      artifact_sha256,
      character(1)
    ),
    hash_verified = .data$observed_sha256 == .data$expected_sha256,
    bytes = as.numeric(file.info(.data$absolute_path)$size)
  ) |>
  dplyr::select(
    .data$input_role,
    .data$path,
    .data$exists,
    .data$expected_sha256,
    .data$observed_sha256,
    .data$hash_verified,
    .data$bytes
  )
if (any(!input_audit$exists | !input_audit$hash_verified)) {
  h10_abort(
    "A METRIC-010 H10 input pin differs: %s",
    paste(
      input_audit$input_role[!input_audit$exists | !input_audit$hash_verified],
      collapse = ", "
    )
  )
}

base_verification <- verify_base_model_data_artifacts(
  root = root,
  output_root = root
)
if (
  base_verification$status != "PASS" ||
    base_verification$manifest_sha256 !=
      "b6fa22836faee5243bb6ce1cc9dceab5d5403f94d688f8f74472a19dbf6e3e09" ||
    base_verification$input_bundle_sha256 !=
      "168f25e18b6e494aa7a0272923041ad8249e25adb9ff3742d22e2f4cacf1bdf8"
) {
  h10_abort("METRIC-010 base-model verification did not reproduce")
}

metric_registry <- h10_metric_registry()
comparison_registry <- h10_comparison_registry()
run_registry <- h10_primary_run_registry()
site_registry <- readr::read_csv(
  file.path(root, "config/site_display_registry.csv"),
  show_col_types = FALSE,
  progress = FALSE
) |>
  dplyr::arrange(.data$display_order)
site_levels <- site_registry$site
metric_display <- readr::read_csv(
  file.path(root, "config/metric_display_registry.csv"),
  show_col_types = FALSE,
  progress = FALSE
) |>
  dplyr::filter(.data$metric_id %in% metric_registry$metric_id) |>
  dplyr::select(
    .data$metric_id,
    .data$manuscript_name,
    .data$abbreviation,
    .data$manuscript_category,
    display_analysis_unit = .data$analysis_unit,
    .data$display_unit,
    .data$variant_label
  )
metric_registry <- metric_registry |>
  dplyr::left_join(metric_display, by = "metric_id", relationship = "one-to-one")
if (nrow(metric_registry) != 17L || anyNA(metric_registry$manuscript_name)) {
  h10_abort("The current H10 metric/display registry is incomplete")
}
mder_spec <- metric_registry |>
  dplyr::filter(.data$metric_id == mder_id)
if (
  nrow(mder_spec) != 1L ||
    mder_spec$response_family != "gaussian" ||
    mder_spec$response_transform != "identity"
) {
  h10_abort("The H10 METRIC-010 Gaussian identity contract differs")
}

h01_primary <- readRDS(file.path(root, "artifacts/06_model_data/H01.rds"))
h01_gap <- readRDS(file.path(
  root,
  "artifacts/06_model_data/H01/scenarios/manuscript_prepared_data/H01.rds"
))
if (
  h01_primary$metadata$base_manifest_sha256 !=
    "b6fa22836faee5243bb6ce1cc9dceab5d5403f94d688f8f74472a19dbf6e3e09" ||
    h01_primary$metadata$metric_manifest_sha256 !=
      "7bb2830c695e5600f0877acca500a187a040fe727a029bdb069f69099abe4f43" ||
  h01_gap$metadata$scenario_input_manifest_sha256 !=
      "4ed62fbe58de65a6d05d8cfc6b5d870d7c74a3c83fe89bcd72bd1dd838698935"
) {
  h10_abort("The current H01 prepared-row provenance differs")
}

demographics <- readRDS(file.path(
  root,
  "artifacts/06_model_data/normalized_inputs/demographics.rds"
)) |>
  dplyr::transmute(
    .data$site,
    .data$Id,
    age = as.numeric(.data$age),
    biological_sex = as.character(.data$sex),
    .data$employment_status
  )
if (
  anyDuplicated(demographics[c("site", "Id")]) ||
    any(!demographics$biological_sex %in% c("Male", "Female")) ||
    any(!is.finite(demographics$age))
) {
  h10_abort("H10 demographic provenance or coding is not admissible")
}

h10_source_mder_rows <- function(object, data_scenario, scenario) {
  object$model_rows |>
    dplyr::filter(
      .data$scenario == .env$scenario,
      .data$metric_id == .env$mder_id,
      .data$metric_estimable,
      .data$scenario_estimable,
      is.finite(.data$value)
    ) |>
    dplyr::transmute(
      data_scenario = data_scenario,
      .data$placement,
      .data$site,
      .data$Id,
      local_date = as.Date(.data$local_date),
      .data$metric_id,
      .data$analysis_unit,
      value = as.numeric(.data$value),
      .data$participant_days_contributing,
      .data$metric_support_available,
      .data$metric_support_valid_minutes,
      .data$metric_support_expected_minutes,
      .data$prepared_record_support_available,
      .data$prepared_record_valid_melEDI_minutes,
      .data$prepared_record_valid_illuminance_minutes
    ) |>
    dplyr::left_join(
      demographics,
      by = c("site", "Id"),
      relationship = "many-to-one"
    ) |>
    dplyr::arrange(.data$placement, .data$site, .data$Id, .data$local_date)
}

all_mder_rows <- dplyr::bind_rows(
  h10_source_mder_rows(h01_primary, "primary", "all_available"),
  h10_source_mder_rows(h01_gap, "gap_timing_unaware", "all_available")
)
paired_mder_rows <- dplyr::bind_rows(
  h10_source_mder_rows(h01_primary, "primary", "paired_common_sample"),
  h10_source_mder_rows(
    h01_gap,
    "gap_timing_unaware",
    "paired_common_sample"
  )
)

mder_availability <- all_mder_rows |>
  dplyr::summarise(
    observations = dplyr::n(),
    participants = dplyr::n_distinct(paste(.data$site, .data$Id)),
    mean = mean(.data$value),
    median = stats::median(.data$value),
    nonpositive = sum(.data$value <= 0),
    .by = c(.data$data_scenario, .data$placement)
  )
expected_counts <- tibble::tribble(
  ~data_scenario, ~placement, ~observations, ~participants,
  "primary", "glasses", 702L, 137L,
  "primary", "chest", 732L, 152L,
  "gap_timing_unaware", "glasses", 687L, 137L,
  "gap_timing_unaware", "chest", 723L, 152L
)
count_check <- mder_availability |>
  dplyr::select(
    .data$data_scenario,
    .data$placement,
    .data$observations,
    .data$participants
  ) |>
  dplyr::arrange(.data$data_scenario, .data$placement)
expected_check <- expected_counts |>
  dplyr::arrange(.data$data_scenario, .data$placement)
if (!identical(count_check, expected_check)) {
  h10_abort("The current H10 MDER availability counts differ")
}
nonpositive <- all_mder_rows |>
  dplyr::filter(.data$value <= 0) |>
  dplyr::select(
    .data$data_scenario,
    .data$placement,
    .data$site,
    .data$Id,
    .data$local_date,
    .data$value
  )
if (nrow(nonpositive) != 0L) {
  h10_abort("The repaired H10 MDER inputs contain a nonpositive finite value")
}

gap_mder_support <- readRDS(file.path(
  root,
  "artifacts/06_model_data/scenarios/manuscript_prepared_data/mder_support.rds"
))
repaired_zero_day <- gap_mder_support |>
  dplyr::filter(
    .data$position == "chest",
    .data$site == "THUAS",
    .data$Id == "THUAS_S002",
    as.Date(.data$local_date) == as.Date("2025-03-09")
  )
if (
  nrow(repaired_zero_day) != 1L ||
    isTRUE(repaired_zero_day$estimable[[1L]]) ||
    !is.na(repaired_zero_day$manuscript_prepared_value[[1L]]) ||
    repaired_zero_day$viable_ratio_minutes[[1L]] != 0L ||
    repaired_zero_day$failure_reason[[1L]] != "no_viable_momentary_ratio"
) {
  h10_abort("The FIND-049 repaired comparator day invariant differs")
}

gap_repair_record <- repaired_zero_day |>
  dplyr::transmute(
    finding_id = "FIND-049",
    change_id = "CHG-101",
    placement = .data$position,
    .data$site,
    .data$Id,
    .data$local_date,
    stored_mder = .data$manuscript_prepared_value,
    .data$viable_ratio_minutes,
    .data$expected_minutes,
    .data$estimable,
    .data$failure_reason,
    repair_status = "REPAIRED_IN_SHARED_PREPARATION"
  )

provenance_qualification <- tibble::tibble(
  decision_id = "METRIC-010",
  finding_ids = "PREP-003/FIND-044; FIND-049/CHG-101 resolved",
  base_verification_status = base_verification$status,
  base_manifest_sha256 = base_verification$manifest_sha256,
  base_input_bundle_sha256 = base_verification$input_bundle_sha256,
  metric_manifest_sha256 =
    "7bb2830c695e5600f0877acca500a187a040fe727a029bdb069f69099abe4f43",
  mder_audit_manifest_sha256 =
    "5bd34fd4ac26dc2761540393d40e096cde835d8dd4b4edda9253243c9083d4bb",
  near_eye_participant_days = 816L,
  chest_participant_days = 902L,
  qualification = paste0(
    "The current Preparation 06 model-ready layer and METRIC-010 MDER values ",
    "were independently verified, including the repaired gap-timing-unaware ",
    "MDER under FIND-049/CHG-101. The former chest comparator zero is now a ",
    "reason-coded missing MDER with no viable momentary ratio. The remaining ",
    "PREP-003/FIND-044 boundary concerns only complete independent ",
    "reconstruction of every state-support classification; it is not evidence ",
    "that stored values are incorrect."
  )
)

####
# Build and fit only the two repaired gap all-available MDER frames
####

mder_frames <- list()
mder_frame_rows <- list()
mder_bundles <- list()
mder_manifest_rows <- list()
mder_test_rows <- list()
mder_effect_rows <- list()
mder_site_effect_rows <- list()
mder_diagnostic_rows <- list()
mder_diagnostic_plot_rows <- list()
mder_influence_rows <- list()

gap_run_registry <- run_registry |>
  dplyr::filter(.data$data_scenario == "gap_timing_unaware")
for (run_index in seq_len(nrow(gap_run_registry))) {
  run <- gap_run_registry[run_index, , drop = FALSE]
  source <- all_mder_rows |>
    dplyr::filter(
      .data$data_scenario == run$data_scenario,
      .data$placement == run$placement
    )
  frame <- h10_prepare_model_frame(
    source,
    mder_spec,
    site_levels = site_levels,
    sample_scenario = "all_available"
  )
  key <- paste(run$run_id, mder_id, sep = "__")
  mder_frames[[key]] <- frame
  context <- tibble::tibble(
    run_id = run$run_id,
    data_scenario = run$data_scenario,
    placement = run$placement,
    sample_scenario = run$sample_scenario,
    analytical_role = run$analytical_role,
    metric_order = mder_spec$metric_order,
    metric_id = mder_spec$metric_id,
    manuscript_name = mder_spec$manuscript_name,
    abbreviation = mder_spec$abbreviation,
    manuscript_category = mder_spec$manuscript_category,
    analysis_unit = mder_spec$analysis_unit,
    response_family = mder_spec$response_family,
    response_transform = mder_spec$response_transform,
    effect_scale = mder_spec$effect_scale,
    display_unit = mder_spec$display_unit
  )
  mder_frame_rows[[key]] <- dplyr::bind_cols(
    context |>
      dplyr::select(-.data$abbreviation, -.data$manuscript_category, -.data$display_unit),
    h10_frame_summary(frame)
  )
  message("H10 METRIC-010 fit: ", run$run_id)
  bundle <- h10_fit_bundle(frame, mder_spec)
  mder_bundles[[key]] <- bundle
  manifest <- h10_model_manifest_rows(bundle)
  mder_manifest_rows[[key]] <- dplyr::bind_cols(
    context[rep(1L, nrow(manifest)), , drop = FALSE],
    manifest
  )
  tests <- dplyr::bind_rows(lapply(
    seq_len(nrow(comparison_registry)),
    function(index) {
      comparison <- comparison_registry[index, , drop = FALSE]
      dplyr::bind_cols(
        comparison |>
          dplyr::select(
            .data$comparison_order,
            .data$comparison_id,
            .data$predictor,
            .data$comparison_role,
            .data$reduced_model,
            .data$full_model,
            .data$adjustment_method,
            .data$planned_n
          ),
        h10_compare_models(
          bundle$ml_fits[[comparison$reduced_model]],
          bundle$ml_fits[[comparison$full_model]]
        )
      )
    }
  ))
  mder_test_rows[[key]] <- dplyr::bind_cols(
    context[rep(1L, nrow(tests)), , drop = FALSE],
    tests
  )
  for (predictor in c("age", "biological_sex")) {
    effect_key <- paste(key, predictor, sep = "__")
    effect <- h10_effect_row(bundle, frame, predictor, mder_spec)
    mder_effect_rows[[effect_key]] <- dplyr::bind_cols(context, effect)
    interaction_name <- if (predictor == "age") "M_age_site" else "M_sex_site"
    site_effect <- h10_site_effects(
      bundle$final_fits[[interaction_name]]$model,
      frame,
      predictor,
      mder_spec
    )
    mder_site_effect_rows[[effect_key]] <- dplyr::bind_cols(
      context[rep(1L, nrow(site_effect)), , drop = FALSE],
      site_effect
    )
    main_name <- if (predictor == "age") "M_age" else "M_sex"
    diagnostic <- h10_model_diagnostics(
      bundle$final_fits[[main_name]],
      frame,
      mder_spec
    )
    mder_diagnostic_rows[[effect_key]] <- dplyr::bind_cols(
      context,
      tibble::tibble(predictor = predictor),
      diagnostic
    )
  }
}

mder_frame_index <- dplyr::bind_rows(mder_frame_rows)
mder_model_manifest <- dplyr::bind_rows(mder_manifest_rows)
mder_model_tests <- dplyr::bind_rows(mder_test_rows)
mder_model_effects <- dplyr::bind_rows(mder_effect_rows)
mder_site_effects <- dplyr::bind_rows(mder_site_effect_rows) |>
  dplyr::left_join(
    site_registry |>
      dplyr::select(
        .data$site,
        site_display_order = .data$display_order,
        site_display_name = .data$display_name,
        site_color_hex = .data$color_hex
      ),
    by = "site",
    relationship = "many-to-one"
  )
mder_model_diagnostics <- dplyr::bind_rows(mder_diagnostic_rows)
mder_diagnostic_plot_data <- dplyr::bind_rows(mder_diagnostic_plot_rows)
mder_participant_influence <- dplyr::bind_rows(mder_influence_rows)

if (
  nrow(mder_frame_index) != 2L ||
    nrow(mder_model_manifest) != 18L ||
    nrow(mder_model_tests) != 8L ||
    nrow(mder_model_effects) != 4L ||
    nrow(mder_model_diagnostics) != 4L ||
    nrow(mder_diagnostic_plot_data) != 0L ||
    nrow(mder_participant_influence) != 0L
) {
  h10_abort("The selective repaired-gap MDER output registry is incomplete")
}

####
# Merge all-available results into the frozen 16-metric package
####

old_prepared <- readRDS(file.path(
  roots$model_data,
  "H10_approved_prepared_rows.rds"
))
old_frames <- readRDS(file.path(roots$model_data, "H10_model_frames.rds"))
old_bundle_object <- readRDS(file.path(
  roots$models,
  "H10_primary_and_gap_model_bundles.rds"
))
old_frame_index <- readr::read_csv(
  file.path(roots$model_data, "H10_model_frame_index.csv"),
  show_col_types = FALSE
)
old_model_manifest <- readr::read_csv(
  file.path(roots$models, "H10_model_manifest.csv"),
  show_col_types = FALSE
)
old_model_tests <- readr::read_csv(
  file.path(roots$tables, "H10_model_tests.csv"),
  show_col_types = FALSE
)
old_model_effects <- readr::read_csv(
  file.path(roots$tables, "H10_model_effects.csv"),
  show_col_types = FALSE
)
old_site_effects <- readr::read_csv(
  file.path(roots$tables, "H10_site_specific_effects.csv"),
  show_col_types = FALSE
)
old_model_diagnostics <- readr::read_csv(
  file.path(roots$diagnostics, "H10_model_diagnostics.csv"),
  show_col_types = FALSE
)
old_diagnostic_plot_data <- readr::read_csv(
  file.path(roots$source_data, "H10_primary_diagnostic_plot_data.csv"),
  show_col_types = FALSE
)
old_participant_influence <- readr::read_csv(
  file.path(roots$diagnostics, "H10_participant_deletion_influence.csv"),
  show_col_types = FALSE
)

# Retain the accepted primary MDER frames, fits, estimates, diagnostics, plots,
# and participant-deletion results exactly. Only the repaired gap branches
# above replace their matching entries.
gap_mder_frames <- mder_frames
gap_mder_bundles <- mder_bundles
mder_frames <- c(
  old_frames[
    grepl("mder", names(old_frames), ignore.case = TRUE) &
      grepl("^primary__", names(old_frames))
  ],
  gap_mder_frames
)
mder_bundles <- c(
  old_bundle_object$model_bundles[
    grepl("mder", names(old_bundle_object$model_bundles), ignore.case = TRUE) &
      grepl("^primary__", names(old_bundle_object$model_bundles))
  ],
  gap_mder_bundles
)
mder_frame_index <- dplyr::bind_rows(
  old_frame_index |>
    dplyr::filter(
      .data$metric_id %in% mder_ids,
      .data$data_scenario == "primary"
    ),
  mder_frame_index
)
mder_model_manifest <- dplyr::bind_rows(
  old_model_manifest |>
    dplyr::filter(
      .data$metric_id %in% mder_ids,
      .data$data_scenario == "primary"
    ),
  mder_model_manifest
)
mder_model_tests <- dplyr::bind_rows(
  old_model_tests |>
    dplyr::filter(
      .data$metric_id %in% mder_ids,
      .data$data_scenario == "primary"
    ),
  mder_model_tests
)
mder_model_effects <- dplyr::bind_rows(
  old_model_effects |>
    dplyr::filter(
      .data$metric_id %in% mder_ids,
      .data$data_scenario == "primary"
    ),
  mder_model_effects
)
mder_site_effects <- dplyr::bind_rows(
  old_site_effects |>
    dplyr::filter(
      .data$metric_id %in% mder_ids,
      .data$data_scenario == "primary"
    ),
  mder_site_effects
)
mder_model_diagnostics <- dplyr::bind_rows(
  old_model_diagnostics |>
    dplyr::filter(
      .data$metric_id %in% mder_ids,
      .data$data_scenario == "primary"
    ),
  mder_model_diagnostics
)
mder_diagnostic_plot_data <- old_diagnostic_plot_data |>
  dplyr::filter(.data$metric_id %in% mder_ids)
mder_participant_influence <- old_participant_influence |>
  dplyr::filter(.data$metric_id %in% mder_ids)

if (
  length(mder_frames) != 4L ||
    length(mder_bundles) != 4L ||
    nrow(mder_frame_index) != 4L ||
    nrow(mder_model_manifest) != 36L ||
    nrow(mder_model_tests) != 16L ||
    nrow(mder_model_effects) != 8L ||
    nrow(mder_model_diagnostics) != 8L ||
    nrow(mder_participant_influence) != 4L
) {
  h10_abort("The frozen-primary plus repaired-gap MDER registry is incomplete")
}

prepared <- old_prepared
prepared$all_available_rows <- h10_replace_metric_scenarios(
  old_prepared$all_available_rows,
  all_mder_rows |>
    dplyr::filter(.data$data_scenario == "gap_timing_unaware"),
  "gap_timing_unaware"
)
prepared$paired_common_rows <- h10_replace_metric_scenarios(
  old_prepared$paired_common_rows,
  paired_mder_rows |>
    dplyr::filter(.data$data_scenario == "gap_timing_unaware"),
  "gap_timing_unaware"
)
prepared$primary_prepared_metadata <- h01_primary$metadata
prepared$gap_prepared_metadata <- h01_gap$metadata
prepared$provenance_qualification <- provenance_qualification

model_frames <- c(h10_keep_non_mder_list(old_frames), mder_frames)
model_bundles <- c(
  h10_keep_non_mder_list(old_bundle_object$model_bundles),
  mder_bundles
)
if (length(model_frames) != 68L || length(model_bundles) != 68L) {
  h10_abort("The merged H10 68-model registry is incomplete")
}

model_frame_index <- h10_replace_metric_rows(
  old_frame_index,
  mder_frame_index
) |>
  dplyr::arrange(
    .data$data_scenario,
    .data$placement,
    .data$metric_order
  )
model_manifest <- h10_replace_metric_rows(
  old_model_manifest,
  mder_model_manifest
) |>
  dplyr::arrange(
    .data$data_scenario,
    .data$placement,
    .data$metric_order,
    .data$fit_role,
    .data$model_name
  )

model_tests <- h10_replace_metric_rows(old_model_tests, mder_model_tests) |>
  dplyr::mutate(
    family_id = paste(
      .data$data_scenario,
      dplyr::if_else(
        .data$placement == "glasses",
        dplyr::case_when(
          .data$comparison_id == "AGE-MAIN" ~ "H10-F1-age-main",
          .data$comparison_id == "SEX-MAIN" ~ "H10-F2-sex-main",
          .data$comparison_id == "AGE-SITE" ~ "H10-F3-age-site-interaction",
          TRUE ~ "H10-F4-sex-site-interaction"
        ),
        dplyr::case_when(
          .data$comparison_id == "AGE-MAIN" ~ "H10-C1-age-main",
          .data$comparison_id == "SEX-MAIN" ~ "H10-C2-sex-main",
          .data$comparison_id == "AGE-SITE" ~ "H10-C3-age-site-interaction",
          TRUE ~ "H10-C4-sex-site-interaction"
        )
      ),
      sep = "__"
    )
  )
model_tests <- model_tests |>
  h10_adjust_families(
    "family_id",
    selected_scenarios = "gap_timing_unaware"
  ) |>
  dplyr::arrange(
    .data$data_scenario,
    .data$placement,
    .data$comparison_order,
    .data$metric_order
  )

family_audit <- model_tests |>
  dplyr::group_by(
    .data$family_id,
    .data$data_scenario,
    .data$placement,
    .data$comparison_id,
    .data$planned_n,
    .data$adjustment_method
  ) |>
  dplyr::summarise(
    registered_rows = dplyr::n(),
    observed_raw_p = sum(is.finite(.data$p_raw)),
    observed_adjusted_p = sum(is.finite(.data$p_adjusted)),
    raw_significant_n = sum(.data$raw_significant),
    adjusted_significant_n = sum(.data$adjusted_significant),
    complete_17_member_family = .data$registered_rows == 17L,
    independent_recalculation_matches = isTRUE(all.equal(
      .data$p_adjusted,
      stats::p.adjust(.data$p_raw, method = "BH", n = 17L)
    )),
    .groups = "drop"
  )
if (any(!family_audit$independent_recalculation_matches)) {
  h10_abort("A METRIC-010 multiplicity family failed verification")
}

model_effects <- h10_replace_metric_rows(old_model_effects, mder_model_effects) |>
  dplyr::arrange(
    .data$data_scenario,
    .data$placement,
    .data$predictor,
    .data$metric_order
  )
site_effects <- h10_replace_metric_rows(old_site_effects, mder_site_effects) |>
  dplyr::arrange(
    .data$data_scenario,
    .data$placement,
    .data$predictor,
    .data$metric_order,
    .data$weighting,
    .data$site_display_order
  )
model_diagnostics <- h10_replace_metric_rows(
  old_model_diagnostics,
  mder_model_diagnostics
) |>
  dplyr::arrange(
    .data$data_scenario,
    .data$placement,
    .data$predictor,
    .data$metric_order
  )
diagnostic_plot_data <- h10_replace_metric_rows(
  old_diagnostic_plot_data,
  mder_diagnostic_plot_data
)
participant_influence <- h10_replace_metric_rows(
  old_participant_influence,
  mder_participant_influence
)

####
# Refit only the accepted MDER sample comparisons
####

old_sample_model_object <- readRDS(file.path(
  roots$models,
  "H10_sample_sensitivity_models.rds"
))
old_paired_results <- readr::read_csv(
  file.path(roots$sensitivity, "H10_paired_placement_main_effects.csv"),
  show_col_types = FALSE
)
old_paired_audit <- readr::read_csv(
  file.path(roots$model_data, "H10_paired_placement_sample_audit.csv"),
  show_col_types = FALSE
)
old_gap_common_results <- readr::read_csv(
  file.path(roots$sensitivity, "H10_primary_gap_common_sample_effects.csv"),
  show_col_types = FALSE
)
old_gap_common_audit <- readr::read_csv(
  file.path(roots$model_data, "H10_primary_gap_common_sample_audit.csv"),
  show_col_types = FALSE
)
old_prereg_results <- readr::read_csv(
  file.path(roots$sensitivity, "H10_preregistered_exclusion_effects.csv"),
  show_col_types = FALSE
)

paired_mder_summary_rows <- list()
paired_mder_models <- list()
paired_mder_audit_rows <- list()
for (data_scenario in "gap_timing_unaware") {
  metric_rows <- paired_mder_rows |>
    dplyr::filter(.data$data_scenario == .env$data_scenario)
  placement_keys <- lapply(c("glasses", "chest"), function(placement) {
    rows <- metric_rows |>
      dplyr::filter(.data$placement == .env$placement)
    sort(unique(h10_common_key(rows, "participant_day")))
  })
  if (!identical(placement_keys[[1L]], placement_keys[[2L]])) {
    h10_abort("The METRIC-010 paired placement keys differ")
  }
  paired_mder_audit_rows[[data_scenario]] <- tibble::tibble(
    data_scenario = data_scenario,
    metric_order = mder_spec$metric_order,
    metric_id = mder_id,
    paired_keys = length(placement_keys[[1L]]),
    paired_key_sha256 = h10_hash_object(placement_keys[[1L]]),
    exact_key_match = TRUE
  )
  for (placement in c("glasses", "chest")) {
    source <- metric_rows |>
      dplyr::filter(.data$placement == .env$placement)
    frame <- h10_prepare_model_frame(
      source,
      mder_spec,
      site_levels = site_levels,
      sample_scenario = "paired_common_sample"
    )
    for (predictor in c("age", "biological_sex")) {
      key <- paste(
        "paired",
        data_scenario,
        placement,
        mder_id,
        predictor,
        sep = "__"
      )
      fit <- h10_fit_main_sensitivity(frame, mder_spec, predictor)
      paired_mder_summary_rows[[key]] <- dplyr::bind_cols(
        tibble::tibble(
          data_scenario = data_scenario,
          placement = placement,
          sample_scenario = "paired_common_sample",
          metric_order = mder_spec$metric_order,
          metric_id = mder_id,
          manuscript_name = mder_spec$manuscript_name,
          abbreviation = mder_spec$abbreviation,
          unavailable_reason = NA_character_
        ),
        fit$summary
      )
      paired_mder_models[[key]] <- fit$models
    }
  }
}
paired_frame_audit <- h10_replace_metric_scenarios(
  old_paired_audit,
  dplyr::bind_rows(paired_mder_audit_rows),
  "gap_timing_unaware"
) |>
  dplyr::arrange(.data$data_scenario, .data$metric_order)
paired_results <- h10_replace_metric_scenarios(
  old_paired_results,
  dplyr::bind_rows(paired_mder_summary_rows),
  "gap_timing_unaware"
) |>
  h10_adjust_families(
    c("data_scenario", "placement", "predictor"),
    selected_scenarios = "gap_timing_unaware"
  ) |>
  dplyr::arrange(
    .data$data_scenario,
    .data$placement,
    .data$predictor,
    .data$metric_order
  )

gap_common_mder_summary_rows <- list()
gap_common_mder_models <- list()
gap_common_mder_audit_rows <- list()
for (placement in c("glasses", "chest")) {
  primary_source <- all_mder_rows |>
    dplyr::filter(
      .data$data_scenario == "primary",
      .data$placement == .env$placement
    )
  gap_source <- all_mder_rows |>
    dplyr::filter(
      .data$data_scenario == "gap_timing_unaware",
      .data$placement == .env$placement
    )
  common_keys <- intersect(
    h10_common_key(primary_source, "participant_day"),
    h10_common_key(gap_source, "participant_day")
  )
  primary_common <- primary_source[
    h10_common_key(primary_source, "participant_day") %in% common_keys,
    ,
    drop = FALSE
  ]
  gap_common <- gap_source[
    h10_common_key(gap_source, "participant_day") %in% common_keys,
    ,
    drop = FALSE
  ]
  primary_hash <- h10_hash_object(sort(h10_common_key(
    primary_common,
    "participant_day"
  )))
  gap_hash <- h10_hash_object(sort(h10_common_key(
    gap_common,
    "participant_day"
  )))
  if (nrow(primary_common) != nrow(gap_common) || primary_hash != gap_hash) {
    h10_abort("The METRIC-010 primary--gap common keys differ")
  }
  expected_common <- if (placement == "glasses") 687L else 723L
  if (length(common_keys) != expected_common) {
    h10_abort("The METRIC-010 primary--gap common count differs")
  }
  gap_common_mder_audit_rows[[placement]] <- tibble::tibble(
    placement = placement,
    metric_order = mder_spec$metric_order,
    metric_id = mder_id,
    common_observations = length(common_keys),
    primary_key_sha256 = primary_hash,
    gap_key_sha256 = gap_hash,
    exact_key_match = TRUE
  )
  for (data_scenario in c("primary", "gap_timing_unaware")) {
    source <- if (data_scenario == "primary") primary_common else gap_common
    frame <- h10_prepare_model_frame(
      source,
      mder_spec,
      site_levels = site_levels,
      sample_scenario = "primary_gap_common_sample"
    )
    for (predictor in c("age", "biological_sex")) {
      key <- paste(
        "gap_common",
        data_scenario,
        placement,
        mder_id,
        predictor,
        sep = "__"
      )
      fit <- h10_fit_main_sensitivity(frame, mder_spec, predictor)
      gap_common_mder_summary_rows[[key]] <- dplyr::bind_cols(
        tibble::tibble(
          data_scenario = data_scenario,
          placement = placement,
          sample_scenario = "primary_gap_common_sample",
          metric_order = mder_spec$metric_order,
          metric_id = mder_id,
          manuscript_name = mder_spec$manuscript_name,
          abbreviation = mder_spec$abbreviation
        ),
        fit$summary
      )
      gap_common_mder_models[[key]] <- fit$models
    }
  }
}
gap_common_audit <- h10_replace_metric_rows(
  old_gap_common_audit,
  dplyr::bind_rows(gap_common_mder_audit_rows)
) |>
  dplyr::arrange(.data$placement, .data$metric_order)
gap_common_results <- h10_replace_metric_rows(
  old_gap_common_results,
  dplyr::bind_rows(gap_common_mder_summary_rows)
) |>
  h10_adjust_families(c("data_scenario", "placement", "predictor")) |>
  dplyr::arrange(
    .data$data_scenario,
    .data$placement,
    .data$predictor,
    .data$metric_order
  )

prereg_exclusion_ids <- demographics |>
  dplyr::filter(
    .data$age > 65 |
      .data$employment_status %in%
        c("Not employed", "Marginally employed (Minijob)")
  ) |>
  dplyr::mutate(
    exclusion_reason = paste(
      dplyr::if_else(.data$age > 65, "age above 65", NA_character_),
      dplyr::if_else(
        .data$employment_status %in%
          c("Not employed", "Marginally employed (Minijob)"),
        paste0("employment: ", .data$employment_status),
        NA_character_
      ),
      sep = " | "
    )
  )
if (nrow(prereg_exclusion_ids) != 9L) {
  h10_abort("The documented preregistration exclusions are not nine people")
}
prereg_results <- old_prereg_results

sample_model_object <- old_sample_model_object
sample_model_object$paired_placement_models <- c(
  old_sample_model_object$paired_placement_models[
    !grepl(
      "^paired__gap_timing_unaware__.*mder",
      names(old_sample_model_object$paired_placement_models),
      ignore.case = TRUE
    )
  ],
  paired_mder_models
)
sample_model_object$primary_gap_common_models <- c(
  h10_keep_non_mder_list(old_sample_model_object$primary_gap_common_models),
  gap_common_mder_models
)
sample_model_object$preregistered_exclusion_models <-
  old_sample_model_object$preregistered_exclusion_models
sample_model_object$provenance_qualification <- provenance_qualification

####
# Remove superseded MDER scenarios and add current-distribution evidence
####

old_metric_sensitivities <- readr::read_csv(
  file.path(roots$sensitivity, "H10_metric_specific_sensitivities.csv"),
  show_col_types = FALSE
)
metric_sensitivities <- h10_non_mder_rows(old_metric_sensitivities)
if (nrow(metric_sensitivities) != 8L) {
  h10_abort("The retained non-MDER metric-specific sensitivity registry differs")
}
old_metric_model_object <- readRDS(file.path(
  roots$models,
  "H10_metric_sensitivity_models.rds"
))
old_mder_distribution <- readr::read_csv(
  file.path(roots$sensitivity, "H10_mder_current_distribution.csv"),
  show_col_types = FALSE
)
waking_mder_unavailable <- tibble::tibble(
  sensitivity_id = "waking_only_mder",
  placement = c("glasses", "chest"),
  metric_id = mder_id,
  status = "UNAVAILABLE",
  reason = paste0(
    "No approved current artifact derives waking-only METRIC-010 MDER; H10 ",
    "did not approximate or recompute that construct"
  )
)
metric_model_object <- old_metric_model_object
metric_model_object$metric_sensitivity_models <- h10_keep_non_mder_list(
  old_metric_model_object$metric_sensitivity_models
)
metric_model_object$waking_mder_status <- waking_mder_unavailable
metric_model_object$provenance_qualification <- provenance_qualification

mder_distribution_overall <- all_mder_rows |>
  dplyr::filter(.data$data_scenario == "gap_timing_unaware") |>
  dplyr::summarise(
    scope = "overall",
    site = NA_character_,
    observations = dplyr::n(),
    participants = dplyr::n_distinct(paste(.data$site, .data$Id)),
    mean = mean(.data$value),
    standard_deviation = stats::sd(.data$value),
    minimum = min(.data$value),
    q01 = stats::quantile(.data$value, 0.01, names = FALSE),
    q05 = stats::quantile(.data$value, 0.05, names = FALSE),
    q25 = stats::quantile(.data$value, 0.25, names = FALSE),
    median = stats::median(.data$value),
    q75 = stats::quantile(.data$value, 0.75, names = FALSE),
    q95 = stats::quantile(.data$value, 0.95, names = FALSE),
    q99 = stats::quantile(.data$value, 0.99, names = FALSE),
    maximum = max(.data$value),
    nonpositive_n = sum(.data$value <= 0),
    above_1_n = sum(.data$value > 1),
    above_1_5_n = sum(.data$value > 1.5),
    .by = c(.data$data_scenario, .data$placement)
  )
mder_distribution_site <- all_mder_rows |>
  dplyr::filter(.data$data_scenario == "gap_timing_unaware") |>
  dplyr::summarise(
    scope = "site",
    observations = dplyr::n(),
    participants = dplyr::n_distinct(.data$Id),
    mean = mean(.data$value),
    standard_deviation = stats::sd(.data$value),
    minimum = min(.data$value),
    q01 = stats::quantile(.data$value, 0.01, names = FALSE),
    q05 = stats::quantile(.data$value, 0.05, names = FALSE),
    q25 = stats::quantile(.data$value, 0.25, names = FALSE),
    median = stats::median(.data$value),
    q75 = stats::quantile(.data$value, 0.75, names = FALSE),
    q95 = stats::quantile(.data$value, 0.95, names = FALSE),
    q99 = stats::quantile(.data$value, 0.99, names = FALSE),
    maximum = max(.data$value),
    nonpositive_n = sum(.data$value <= 0),
    above_1_n = sum(.data$value > 1),
    above_1_5_n = sum(.data$value > 1.5),
    .by = c(.data$data_scenario, .data$placement, .data$site)
  )
gap_mder_distribution <- dplyr::bind_rows(
  mder_distribution_overall,
  mder_distribution_site
) |>
  dplyr::left_join(
    site_registry |>
      dplyr::select(
        .data$site,
        site_display_order = .data$display_order,
        site_display_name = .data$display_name
      ),
    by = "site",
    relationship = "many-to-one"
  ) |>
  dplyr::mutate(
    distribution_assessment = dplyr::case_when(
      .data$maximum > 3 ~
        "Strong upper tail; interpret with participant and site influence checks",
      .data$maximum > 1.5 ~
        "Moderate upper tail; interpret with participant and site influence checks",
      TRUE ~ "No nonpositive value or extreme upper-tail flag"
    )
  ) |>
  dplyr::arrange(
    .data$data_scenario,
    .data$placement,
    .data$scope,
    .data$site_display_order
  )
mder_distribution <- dplyr::bind_rows(
  old_mder_distribution |>
    dplyr::filter(.data$data_scenario == "primary"),
  gap_mder_distribution
) |>
  dplyr::arrange(
    .data$data_scenario,
    .data$placement,
    .data$scope,
    .data$site_display_order
  )

####
# Preserve all accepted primary MDER diagnostics and influence outputs
####

old_loso <- readr::read_csv(
  file.path(roots$diagnostics, "H10_leave_one_site_out.csv"),
  show_col_types = FALSE
)
old_loso_summary <- readr::read_csv(
  file.path(roots$diagnostics, "H10_leave_one_site_out_summary.csv"),
  show_col_types = FALSE
)
old_diagnostic_assessment <- readr::read_csv(
  file.path(roots$diagnostics, "H10_primary_diagnostic_assessment.csv"),
  show_col_types = FALSE
)
old_mder_influence_assessment <- readr::read_csv(
  file.path(
    roots$sensitivity,
    "H10_mder_current_influence_assessment.csv"
  ),
  show_col_types = FALSE
)

if (FALSE) {
mder_loso_rows <- list()
for (placement in c("glasses", "chest")) {
  run_id <- paste("primary", placement, "all_available", sep = "__")
  frame <- mder_frames[[paste(run_id, mder_id, sep = "__")]]
  for (predictor in c("age", "biological_sex")) {
    for (omitted_site in site_levels) {
      key <- paste(placement, predictor, omitted_site, sep = "__")
      refit <- h10_loso_refit(frame, mder_spec, predictor, omitted_site)
      mder_loso_rows[[key]] <- dplyr::bind_cols(
        tibble::tibble(
          placement = placement,
          metric_order = mder_spec$metric_order,
          metric_id = mder_id,
          manuscript_name = mder_spec$manuscript_name,
          abbreviation = mder_spec$abbreviation,
          omitted_site_present = omitted_site %in% levels(frame$site)
        ),
        refit
      )
    }
  }
}
mder_loso_base <- dplyr::bind_rows(mder_loso_rows) |>
  dplyr::left_join(
    site_registry |>
      dplyr::select(
        omitted_site = .data$site,
        omitted_site_order = .data$display_order,
        omitted_site_name = .data$display_name
      ),
    by = "omitted_site",
    relationship = "many-to-one"
  )
if (nrow(mder_loso_base) != 36L) {
  h10_abort("The selective METRIC-010 leave-one-site-out registry is incomplete")
}
loso_base_names <- names(mder_loso_base)
old_loso_base <- h10_non_mder_rows(old_loso) |>
  dplyr::select(dplyr::all_of(loso_base_names))
leave_one_site_out <- dplyr::bind_rows(old_loso_base, mder_loso_base)
leave_one_site_out$p_adjusted <- NA_real_
loso_groups <- interaction(
  leave_one_site_out[c("placement", "predictor", "omitted_site")],
  drop = TRUE,
  lex.order = TRUE
)
for (group in unique(loso_groups)) {
  rows <- which(loso_groups == group)
  if (length(rows) != 17L) {
    h10_abort("A merged leave-one-site-out family is not 17 metrics")
  }
  leave_one_site_out$p_adjusted[rows] <- adjust_p_family(
    leave_one_site_out$p_raw[rows],
    method = "BH",
    n = 17L
  )
}
leave_one_site_out <- leave_one_site_out |>
  dplyr::mutate(
    adjusted_significant = is.finite(.data$p_adjusted) &
      .data$p_adjusted <= 0.05,
    p_raw_display = nh_format_p_value(.data$p_raw),
    p_adjusted_display = nh_format_p_value(.data$p_adjusted)
  )
primary_main_tests <- model_tests |>
  dplyr::filter(
    .data$data_scenario == "primary",
    .data$comparison_id %in% c("AGE-MAIN", "SEX-MAIN")
  ) |>
  dplyr::transmute(
    .data$placement,
    .data$metric_id,
    predictor = dplyr::if_else(
      .data$comparison_id == "AGE-MAIN",
      "age",
      "biological_sex"
    ),
    full_p_adjusted = .data$p_adjusted,
    full_adjusted_significant = .data$adjusted_significant
  )
primary_main_effects <- model_effects |>
  dplyr::filter(.data$data_scenario == "primary") |>
  dplyr::select(
    .data$placement,
    .data$metric_id,
    .data$predictor,
    full_estimate_model = .data$estimate_model,
    full_standard_error = .data$standard_error
  )
leave_one_site_out <- leave_one_site_out |>
  dplyr::left_join(
    primary_main_tests,
    by = c("placement", "metric_id", "predictor"),
    relationship = "many-to-one"
  ) |>
  dplyr::left_join(
    primary_main_effects,
    by = c("placement", "metric_id", "predictor"),
    relationship = "many-to-one"
  ) |>
  dplyr::mutate(
    estimate_change_from_full = .data$estimate_model -
      .data$full_estimate_model,
    change_in_full_standard_errors = abs(.data$estimate_change_from_full) /
      .data$full_standard_error,
    sign_reversal = sign(.data$estimate_model) !=
      sign(.data$full_estimate_model),
    adjusted_support_changed = .data$adjusted_significant !=
      .data$full_adjusted_significant
  ) |>
  dplyr::arrange(
    .data$placement,
    .data$predictor,
    .data$metric_order,
    .data$omitted_site_order
  )

loso_summary <- leave_one_site_out |>
  dplyr::group_by(
    .data$placement,
    .data$predictor,
    .data$metric_order,
    .data$metric_id,
    .data$manuscript_name,
    .data$abbreviation
  ) |>
  dplyr::summarise(
    sites_checked = sum(.data$omitted_site_present),
    registered_site_rows = dplyr::n(),
    failed_or_nonconverged = sum(
      .data$comparison_status != "ESTIMABLE" |
        !.data$final_converged |
        !.data$final_positive_definite_hessian,
      na.rm = TRUE
    ),
    sign_reversals = sum(.data$sign_reversal, na.rm = TRUE),
    adjusted_support_changes = sum(
      .data$adjusted_support_changed,
      na.rm = TRUE
    ),
    max_change_in_full_standard_errors = if (
      any(is.finite(.data$change_in_full_standard_errors))
    ) {
      max(.data$change_in_full_standard_errors, na.rm = TRUE)
    } else {
      NA_real_
    },
    influential_omitted_site = if (
      any(is.finite(.data$change_in_full_standard_errors))
    ) {
      .data$omitted_site[which.max(dplyr::coalesce(
        .data$change_in_full_standard_errors,
        -Inf
      ))]
    } else {
      NA_character_
    },
    site_influence_assessment = dplyr::case_when(
      .data$failed_or_nonconverged > 0L ~ "not acceptable",
      .data$sign_reversals > 0L |
        .data$adjusted_support_changes > 0L |
        .data$max_change_in_full_standard_errors >= 1 ~
        "acceptable with specified limitations",
      TRUE ~ "acceptable"
    ),
    .groups = "drop"
  )

diagnostic_assessment <- model_diagnostics |>
  dplyr::filter(.data$data_scenario == "primary") |>
  dplyr::left_join(
    participant_influence |>
      dplyr::select(
        .data$placement,
        .data$metric_id,
        .data$predictor,
        .data$deleted_participant,
        .data$change_in_full_standard_errors,
        .data$sign_reversal,
        .data$deletion_status
      ),
    by = c("placement", "metric_id", "predictor"),
    relationship = "one-to-one",
    suffix = c("", "_participant_deletion")
  ) |>
  dplyr::left_join(
    loso_summary,
    by = c(
      "placement", "predictor", "metric_order", "metric_id",
      "manuscript_name", "abbreviation"
    ),
    relationship = "one-to-one"
  ) |>
  dplyr::mutate(
    final_assessment = dplyr::case_when(
      .data$diagnostic_assessment == "not acceptable for inference" |
        .data$site_influence_assessment == "not acceptable" ~
        "not acceptable for inference",
      .data$diagnostic_assessment == "acceptable with specified limitations" |
        .data$site_influence_assessment ==
          "acceptable with specified limitations" |
        startsWith(.data$deletion_status, "REVIEW") ~
        "acceptable with specified limitations",
      TRUE ~ "acceptable"
    ),
    interpreted_assessment = paste0(
      "Numerical/convergence gate: ",
      dplyr::if_else(
        .data$converged &
          .data$positive_definite_hessian &
          .data$fixed_full_rank,
        "passed",
        "failed"
      ),
      "; residual/distribution checks: ",
      dplyr::coalesce(.data$diagnostic_issues, "no threshold flag"),
      "; temporal check: ",
      .data$serial_status,
      "; participant deletion: ",
      .data$deletion_status,
      "; leave-one-site-out: ",
      .data$site_influence_assessment,
      ". Overall: ",
      .data$final_assessment,
      "."
    )
  )

mder_influence_assessment <- diagnostic_assessment |>
  dplyr::filter(.data$metric_id == mder_id) |>
  dplyr::left_join(
    model_effects |>
      dplyr::filter(
        .data$data_scenario == "primary",
        .data$metric_id == mder_id
      ) |>
      dplyr::select(
        .data$placement,
        .data$predictor,
        .data$observations,
        .data$participants,
        .data$estimate_practical,
        .data$conf_low_practical,
        .data$conf_high_practical
      ),
    by = c("placement", "predictor"),
    relationship = "one-to-one"
  ) |>
  dplyr::left_join(
    model_tests |>
      dplyr::filter(
        .data$data_scenario == "primary",
        .data$metric_id == mder_id,
        .data$comparison_id %in% c("AGE-MAIN", "SEX-MAIN")
      ) |>
      dplyr::mutate(
        predictor = dplyr::if_else(
          .data$comparison_id == "AGE-MAIN",
          "age",
          "biological_sex"
        )
      ) |>
      dplyr::select(
        .data$placement,
        .data$predictor,
        .data$p_raw,
        .data$p_adjusted,
        .data$adjusted_significant
      ),
    by = c("placement", "predictor"),
    relationship = "one-to-one"
  ) |>
  dplyr::left_join(
    mder_distribution_overall |>
      dplyr::filter(.data$data_scenario == "primary") |>
      dplyr::select(
        .data$placement,
        distribution_maximum = .data$maximum,
        distribution_q99 = .data$q99,
        distribution_above_1_5_n = .data$above_1_5_n
      ),
    by = "placement",
    relationship = "many-to-one"
  ) |>
  dplyr::mutate(
    current_distribution_influence_assessment = paste0(
      "Upper-tail maximum ",
      formatC(.data$distribution_maximum, digits = 3, format = "f"),
      " (99th percentile ",
      formatC(.data$distribution_q99, digits = 3, format = "f"),
      "); participant deletion ",
      .data$deletion_status,
      "; leave-one-site-out ",
      .data$site_influence_assessment,
      "; overall ",
      .data$final_assessment,
      "."
    )
  )
}

leave_one_site_out <- old_loso
loso_summary <- old_loso_summary
diagnostic_assessment <- old_diagnostic_assessment
mder_influence_assessment <- old_mder_influence_assessment

####
# Rebuild MDER-dependent result tables from the merged package
####

h10_effect_display <- function(data) {
  dplyr::case_when(
    data$practical_effect_type == "ratio" ~ sprintf(
      "%.2f× (%.2f–%.2f)",
      data$estimate_practical,
      data$conf_low_practical,
      data$conf_high_practical
    ),
    data$practical_effect_type == "odds ratio" ~ sprintf(
      "OR %.2f (%.2f–%.2f)",
      data$estimate_practical,
      data$conf_low_practical,
      data$conf_high_practical
    ),
    data$practical_unit == "h" ~ sprintf(
      "%.1f min (%.1f–%.1f)",
      data$estimate_minutes,
      data$conf_low_minutes,
      data$conf_high_minutes
    ),
    data$practical_unit == "min" ~ sprintf(
      "%.1f min (%.1f–%.1f)",
      data$estimate_practical,
      data$conf_low_practical,
      data$conf_high_practical
    ),
    TRUE ~ sprintf(
      "%.3f (%.3f–%.3f)",
      data$estimate_practical,
      data$conf_low_practical,
      data$conf_high_practical
    )
  )
}

primary_main_tests_for_join <- model_tests |>
  dplyr::filter(
    .data$data_scenario == "primary",
    .data$comparison_id %in% c("AGE-MAIN", "SEX-MAIN")
  ) |>
  dplyr::mutate(
    predictor = dplyr::if_else(
      .data$comparison_id == "AGE-MAIN",
      "age",
      "biological_sex"
    )
  ) |>
  dplyr::select(
    .data$placement,
    .data$metric_id,
    .data$predictor,
    .data$comparison_id,
    .data$family_id,
    .data$p_raw,
    .data$p_adjusted,
    .data$p_raw_display,
    .data$p_adjusted_display,
    .data$raw_significant,
    .data$adjusted_significant,
    .data$comparison_method
  )
primary_results <- model_effects |>
  dplyr::filter(.data$data_scenario == "primary") |>
  dplyr::left_join(
    primary_main_tests_for_join,
    by = c("placement", "metric_id", "predictor"),
    relationship = "one-to-one"
  ) |>
  dplyr::left_join(
    diagnostic_assessment |>
      dplyr::select(
        .data$placement,
        .data$metric_id,
        .data$predictor,
        .data$final_assessment,
        .data$interpreted_assessment
      ),
    by = c("placement", "metric_id", "predictor"),
    relationship = "one-to-one"
  ) |>
  dplyr::mutate(
    placement_label = dplyr::if_else(
      .data$placement == "glasses",
      "Near eye (primary)",
      "Chest (complementary)"
    ),
    predictor_label = dplyr::if_else(
      .data$predictor == "age",
      "Age, per 10 years",
      "Measured biological sex, Female minus Male"
    ),
    effect_95_ci_display = h10_effect_display(dplyr::pick(dplyr::everything())),
    significance_rule =
      "BH-adjusted p ≤ 0.05 within the labelled 17-member family"
  ) |>
  dplyr::arrange(.data$placement, .data$predictor, .data$metric_order)

primary_interactions <- model_tests |>
  dplyr::filter(
    .data$data_scenario == "primary",
    .data$comparison_id %in% c("AGE-SITE", "SEX-SITE")
  ) |>
  dplyr::mutate(
    predictor = dplyr::if_else(
      .data$comparison_id == "AGE-SITE",
      "age",
      "biological_sex"
    ),
    heterogeneity_interpretation = dplyr::if_else(
      .data$adjusted_significant,
      paste0(
        "Evidence of site heterogeneity under the labelled BH family; ",
        "inspect all non-selective site-specific estimates"
      ),
      paste0(
        "No multiplicity-adjusted evidence of site heterogeneity; ",
        "site-specific estimates remain descriptive"
      )
    )
  )

baseline <- primary_results |>
  dplyr::select(
    .data$placement,
    .data$metric_order,
    .data$metric_id,
    .data$manuscript_name,
    .data$abbreviation,
    .data$predictor,
    baseline_estimate = .data$estimate_model,
    baseline_low = .data$conf_low_model,
    baseline_high = .data$conf_high_model,
    baseline_p_adjusted = .data$p_adjusted,
    baseline_supported = .data$adjusted_significant
  )
gap_all <- model_effects |>
  dplyr::filter(.data$data_scenario == "gap_timing_unaware") |>
  dplyr::left_join(
    model_tests |>
      dplyr::filter(
        .data$data_scenario == "gap_timing_unaware",
        .data$comparison_id %in% c("AGE-MAIN", "SEX-MAIN")
      ) |>
      dplyr::mutate(
        predictor = dplyr::if_else(
          .data$comparison_id == "AGE-MAIN",
          "age",
          "biological_sex"
        )
      ) |>
      dplyr::select(
        .data$placement,
        .data$metric_id,
        .data$predictor,
        gap_p_adjusted = .data$p_adjusted,
        gap_supported = .data$adjusted_significant
      ),
    by = c("placement", "metric_id", "predictor"),
    relationship = "one-to-one"
  ) |>
  dplyr::select(
    .data$placement,
    .data$metric_id,
    .data$predictor,
    gap_estimate = .data$estimate_model,
    .data$gap_p_adjusted,
    .data$gap_supported
  )
common_wide <- gap_common_results |>
  dplyr::select(
    .data$data_scenario,
    .data$placement,
    .data$metric_id,
    .data$predictor,
    .data$estimate_model,
    .data$p_adjusted,
    .data$adjusted_significant
  ) |>
  tidyr::pivot_wider(
    names_from = .data$data_scenario,
    values_from = c(
      .data$estimate_model,
      .data$p_adjusted,
      .data$adjusted_significant
    ),
    names_glue = "common_{data_scenario}_{.value}"
  )
prereg_for_join <- prereg_results |>
  dplyr::select(
    .data$placement,
    .data$metric_id,
    .data$predictor,
    prereg_estimate = .data$estimate_model,
    prereg_p_adjusted = .data$p_adjusted,
    prereg_supported = .data$adjusted_significant
  )
paired_for_join <- paired_results |>
  dplyr::filter(.data$data_scenario == "primary") |>
  dplyr::select(
    .data$placement,
    .data$metric_id,
    .data$predictor,
    paired_status = .data$comparison_status,
    paired_estimate = .data$estimate_model,
    paired_p_adjusted = .data$p_adjusted,
    paired_supported = .data$adjusted_significant
  )
sensitivity_stability <- baseline |>
  dplyr::left_join(
    gap_all,
    by = c("placement", "metric_id", "predictor"),
    relationship = "one-to-one"
  ) |>
  dplyr::left_join(
    common_wide,
    by = c("placement", "metric_id", "predictor"),
    relationship = "one-to-one"
  ) |>
  dplyr::left_join(
    prereg_for_join,
    by = c("placement", "metric_id", "predictor"),
    relationship = "one-to-one"
  ) |>
  dplyr::left_join(
    paired_for_join,
    by = c("placement", "metric_id", "predictor"),
    relationship = "one-to-one"
  ) |>
  dplyr::rowwise() |>
  dplyr::mutate(
    direction_stable = {
      estimates <- c(
        .data$baseline_estimate,
        .data$gap_estimate,
        .data$common_primary_estimate_model,
        .data$common_gap_timing_unaware_estimate_model,
        .data$prereg_estimate,
        .data$paired_estimate
      )
      estimates <- estimates[is.finite(estimates)]
      length(estimates) > 0L &&
        all(sign(estimates) == sign(.data$baseline_estimate))
    },
    adjusted_support_stable = {
      support <- c(
        .data$baseline_supported,
        .data$gap_supported,
        .data$common_primary_adjusted_significant,
        .data$common_gap_timing_unaware_adjusted_significant,
        .data$prereg_supported,
        .data$paired_supported
      )
      support <- support[!is.na(support)]
      length(support) > 0L && all(support == .data$baseline_supported)
    },
    stability_class = dplyr::case_when(
      .data$direction_stable & .data$adjusted_support_stable ~
        "direction and adjusted-support stable",
      .data$direction_stable ~ "direction stable; adjusted support changes",
      TRUE ~ "direction changes in at least one approved sensitivity"
    )
  ) |>
  dplyr::ungroup() |>
  dplyr::arrange(.data$placement, .data$predictor, .data$metric_order)

h10_parse_v0_support <- function(value) {
  value <- trimws(value)
  numeric <- suppressWarnings(as.numeric(value))
  dplyr::case_when(
    startsWith(value, "<") ~ TRUE,
    startsWith(value, ">") ~ FALSE,
    is.finite(numeric) ~ numeric <= 0.05,
    TRUE ~ NA
  )
}
v0_display_rows <- readr::read_csv(
  file.path(roots$model_data, "H10_v0_display_rows.csv"),
  show_col_types = FALSE
) |>
  dplyr::mutate(
    metric_id = dplyr::if_else(
      .data$metric_id == old_mder_id,
      mder_id,
      .data$metric_id
    )
  )
v0_overall <- readr::read_csv(
  file.path(roots$tables, "H10_v0_overall_results_recreated.csv"),
  show_col_types = FALSE
) |>
  dplyr::mutate(
    metric_id = dplyr::if_else(
      .data$metric_id == old_mder_id,
      mder_id,
      .data$metric_id
    )
  )
v0_comparisons <- v0_overall |>
  tidyr::pivot_longer(
    cols = c(
      .data$displayed_sex_adjusted_p,
      .data$displayed_age_adjusted_p,
      .data$displayed_age_site_adjusted_p
    ),
    names_to = "v0_test",
    values_to = "v0_displayed_adjusted_p"
  ) |>
  dplyr::mutate(
    comparison_id = dplyr::recode(
      .data$v0_test,
      displayed_sex_adjusted_p = "SEX-MAIN",
      displayed_age_adjusted_p = "AGE-MAIN",
      displayed_age_site_adjusted_p = "AGE-SITE"
    ),
    v0_adjusted_supported = h10_parse_v0_support(
      .data$v0_displayed_adjusted_p
    )
  ) |>
  dplyr::left_join(
    model_tests |>
      dplyr::filter(.data$data_scenario == "primary") |>
      dplyr::select(
        .data$placement,
        .data$metric_id,
        .data$comparison_id,
        current_p_raw = .data$p_raw,
        current_p_adjusted = .data$p_adjusted,
        current_p_adjusted_display = .data$p_adjusted_display,
        current_adjusted_supported = .data$adjusted_significant,
        current_comparison_method = .data$comparison_method
      ),
    by = c("placement", "metric_id", "comparison_id"),
    relationship = "one-to-one"
  ) |>
  dplyr::mutate(
    conclusion_changed = .data$v0_adjusted_supported !=
      .data$current_adjusted_supported,
    v0_multiplicity_implementation =
      "Scalar p.adjust call per p-value with FDR and n=34",
    current_multiplicity_implementation = paste0(
      "Vector BH adjustment within a complete, separately labelled ",
      "17-member family"
    )
  ) |>
  dplyr::arrange(
    .data$placement,
    .data$comparison_id,
    .data$metric_order
  )

primary_age_source <- primary_results |>
  dplyr::filter(.data$predictor == "age") |>
  dplyr::mutate(
    placement_label = factor(
      .data$placement_label,
      levels = c("Near eye (primary)", "Chest (complementary)")
    ),
    metric_label = factor(
      .data$manuscript_name,
      levels = rev(metric_registry$manuscript_name)
    )
  )
primary_sex_source <- primary_results |>
  dplyr::filter(.data$predictor == "biological_sex") |>
  dplyr::mutate(
    placement_label = factor(
      .data$placement_label,
      levels = c("Near eye (primary)", "Chest (complementary)")
    ),
    metric_label = factor(
      .data$manuscript_name,
      levels = rev(metric_registry$manuscript_name)
    )
  )
paired_plot_source <- paired_results |>
  dplyr::filter(.data$data_scenario == "primary") |>
  dplyr::left_join(
    metric_registry |>
      dplyr::select(.data$metric_id, .data$manuscript_category),
    by = "metric_id",
    relationship = "many-to-one"
  ) |>
  dplyr::mutate(included_in_plot = .data$comparison_status == "ESTIMABLE") |>
  dplyr::select(
    .data$metric_order,
    .data$metric_id,
    .data$manuscript_name,
    .data$abbreviation,
    .data$manuscript_category,
    .data$predictor,
    .data$placement,
    .data$included_in_plot,
    .data$unavailable_reason,
    .data$standardized_estimate,
    .data$standardized_conf_low,
    .data$standardized_conf_high,
    .data$participants,
    .data$participant_days,
    .data$row_key_hash
  ) |>
  tidyr::pivot_wider(
    names_from = .data$placement,
    values_from = c(
      .data$included_in_plot,
      .data$unavailable_reason,
      .data$standardized_estimate,
      .data$standardized_conf_low,
      .data$standardized_conf_high,
      .data$participants,
      .data$participant_days,
      .data$row_key_hash
    )
  ) |>
  dplyr::mutate(
    included_in_plot = .data$included_in_plot_glasses &
      .data$included_in_plot_chest,
    predictor_label = dplyr::if_else(
      .data$predictor == "age",
      "Age per 10 years",
      "Female minus Male"
    )
  )
gap_plot_source <- gap_common_results |>
  dplyr::select(
    .data$metric_order,
    .data$metric_id,
    .data$manuscript_name,
    .data$abbreviation,
    .data$predictor,
    .data$placement,
    .data$data_scenario,
    .data$standardized_estimate,
    .data$standardized_conf_low,
    .data$standardized_conf_high,
    .data$participants,
    .data$participant_days,
    .data$row_key_hash
  ) |>
  tidyr::pivot_wider(
    names_from = .data$data_scenario,
    values_from = c(
      .data$standardized_estimate,
      .data$standardized_conf_low,
      .data$standardized_conf_high,
      .data$participants,
      .data$participant_days,
      .data$row_key_hash
    )
  ) |>
  dplyr::mutate(
    placement_label = dplyr::if_else(
      .data$placement == "glasses",
      "Near eye",
      "Chest"
    ),
    predictor_label = dplyr::if_else(
      .data$predictor == "age",
      "Age per 10 years",
      "Female minus Male"
    )
  )
diagnostic_plot_source <- diagnostic_assessment |>
  dplyr::mutate(
    metric_label = factor(
      .data$manuscript_name,
      levels = rev(metric_registry$manuscript_name)
    ),
    model_label = factor(
      paste(
        dplyr::if_else(.data$placement == "glasses", "Near eye", "Chest"),
        dplyr::if_else(
          .data$predictor == "age",
          "Age",
          "Female-Male"
        ),
        sep = " | "
      ),
      levels = c(
        "Near eye | Age",
        "Near eye | Female-Male",
        "Chest | Age",
        "Chest | Female-Male"
      )
    )
  )

####
# Exact non-MDER identity guards and multiplicity-change audit
####

identity_rows <- list()
h10_guard_identity <- function(name, before, after, exclude = character()) {
  before <- h10_non_mder_rows(before)
  after <- h10_non_mder_rows(after)
  columns <- setdiff(intersect(names(before), names(after)), exclude)
  before <- before[columns]
  after <- after[columns]
  before_hash <- h10_hash_canonical_csv_rows(before)
  after_hash <- h10_hash_canonical_csv_rows(after)
  pass <- identical(before_hash, after_hash)
  identity_rows[[name]] <<- tibble::tibble(
    artifact_component = name,
    non_mder_rows_before = nrow(before),
    non_mder_rows_after = nrow(after),
    compared_columns = length(columns),
    excluded_columns = paste(exclude, collapse = " | "),
    before_sha256 = before_hash,
    after_sha256 = after_hash,
    identity_status = ifelse(pass, "PASS", "FAIL")
  )
  if (!pass) {
    h10_abort("Non-MDER identity guard failed for `%s`", name)
  }
  invisible(TRUE)
}

h10_guard_identity(
  "approved_prepared_all_available_rows",
  old_prepared$all_available_rows,
  prepared$all_available_rows
)
h10_guard_identity(
  "approved_prepared_paired_common_rows",
  old_prepared$paired_common_rows,
  prepared$paired_common_rows
)
h10_guard_identity("model_frame_index", old_frame_index, model_frame_index)
h10_guard_identity("model_manifest", old_model_manifest, model_manifest)
h10_guard_identity(
  "model_tests_frozen_content",
  old_model_tests,
  model_tests,
  exclude = c(
    "p_adjusted", "raw_significant", "adjusted_significant",
    "p_raw_display", "p_adjusted_display"
  )
)
h10_guard_identity("model_effects", old_model_effects, model_effects)
h10_guard_identity("site_specific_effects", old_site_effects, site_effects)
h10_guard_identity(
  "model_diagnostics",
  old_model_diagnostics,
  model_diagnostics
)
h10_guard_identity(
  "primary_diagnostic_plot_data",
  old_diagnostic_plot_data,
  diagnostic_plot_data
)
h10_guard_identity(
  "participant_deletion_influence",
  old_participant_influence,
  participant_influence
)
h10_guard_identity(
  "paired_placement_frozen_content",
  old_paired_results,
  paired_results,
  exclude = c(
    "p_adjusted", "raw_significant", "adjusted_significant",
    "p_raw_display", "p_adjusted_display"
  )
)
h10_guard_identity(
  "primary_gap_common_frozen_content",
  old_gap_common_results,
  gap_common_results,
  exclude = c(
    "p_adjusted", "raw_significant", "adjusted_significant",
    "p_raw_display", "p_adjusted_display"
  )
)
h10_guard_identity(
  "preregistered_exclusion_frozen_content",
  old_prereg_results,
  prereg_results,
  exclude = c(
    "p_adjusted", "raw_significant", "adjusted_significant",
    "p_raw_display", "p_adjusted_display"
  )
)
h10_guard_identity(
  "leave_one_site_out_frozen_content",
  old_loso,
  leave_one_site_out,
  exclude = c(
    "p_adjusted", "adjusted_significant", "p_raw_display",
    "p_adjusted_display", "full_p_adjusted", "full_adjusted_significant",
    "full_estimate_model", "full_standard_error",
    "estimate_change_from_full", "change_in_full_standard_errors",
    "sign_reversal", "adjusted_support_changed"
  )
)

old_non_mder_frames <- h10_keep_non_mder_list(old_frames)
new_non_mder_frames <- h10_keep_non_mder_list(model_frames)
old_non_mder_bundles <- h10_keep_non_mder_list(old_bundle_object$model_bundles)
new_non_mder_bundles <- h10_keep_non_mder_list(model_bundles)
for (record in list(
  list("model_frame_rds_entries", old_non_mder_frames, new_non_mder_frames),
  list(
    "primary_and_gap_model_bundle_entries",
    old_non_mder_bundles,
    new_non_mder_bundles
  )
)) {
  before_hash <- h10_hash_object(record[[2L]])
  after_hash <- h10_hash_object(record[[3L]])
  pass <- identical(before_hash, after_hash)
  identity_rows[[record[[1L]]]] <- tibble::tibble(
    artifact_component = record[[1L]],
    non_mder_rows_before = length(record[[2L]]),
    non_mder_rows_after = length(record[[3L]]),
    compared_columns = NA_integer_,
    excluded_columns = "",
    before_sha256 = before_hash,
    after_sha256 = after_hash,
    identity_status = ifelse(pass, "PASS", "FAIL")
  )
  if (!pass) h10_abort("Non-MDER RDS identity guard failed for `%s`", record[[1L]])
}
non_mder_identity_audit <- dplyr::bind_rows(identity_rows)

primary_identity_rows <- list()
h10_guard_primary_mder_identity <- function(name, before, after) {
  select_primary_mder <- function(data) {
    rows <- data$metric_id %in% mder_ids
    if ("data_scenario" %in% names(data)) {
      rows <- rows & data$data_scenario == "primary"
    }
    data[rows, , drop = FALSE]
  }
  before <- select_primary_mder(before)
  after <- select_primary_mder(after)
  columns <- intersect(names(before), names(after))
  before_hash <- h10_hash_canonical_csv_rows(before[columns])
  after_hash <- h10_hash_canonical_csv_rows(after[columns])
  pass <- identical(before_hash, after_hash)
  primary_identity_rows[[name]] <<- tibble::tibble(
    artifact_component = name,
    primary_mder_rows_before = nrow(before),
    primary_mder_rows_after = nrow(after),
    compared_columns = length(columns),
    before_sha256 = before_hash,
    after_sha256 = after_hash,
    identity_status = ifelse(pass, "PASS", "FAIL")
  )
  if (!pass) {
    h10_abort("Frozen primary MDER identity guard failed for `%s`", name)
  }
  invisible(TRUE)
}

for (record in list(
  list("approved_prepared_all_available_rows", old_prepared$all_available_rows, prepared$all_available_rows),
  list("approved_prepared_paired_common_rows", old_prepared$paired_common_rows, prepared$paired_common_rows),
  list("model_frame_index", old_frame_index, model_frame_index),
  list("model_manifest", old_model_manifest, model_manifest),
  list("model_tests", old_model_tests, model_tests),
  list("model_effects", old_model_effects, model_effects),
  list("site_specific_effects", old_site_effects, site_effects),
  list("model_diagnostics", old_model_diagnostics, model_diagnostics),
  list("primary_diagnostic_plot_data", old_diagnostic_plot_data, diagnostic_plot_data),
  list("participant_deletion_influence", old_participant_influence, participant_influence),
  list(
    "primary_mder_influence_assessment",
    old_mder_influence_assessment,
    mder_influence_assessment
  ),
  list("paired_placement", old_paired_results, paired_results),
  list("preregistered_exclusion", old_prereg_results, prereg_results),
  list("leave_one_site_out", old_loso, leave_one_site_out)
)) {
  h10_guard_primary_mder_identity(record[[1L]], record[[2L]], record[[3L]])
}

old_primary_distribution <- old_mder_distribution |>
  dplyr::filter(.data$data_scenario == "primary")
new_primary_distribution <- mder_distribution |>
  dplyr::filter(.data$data_scenario == "primary")
old_primary_distribution_hash <- h10_hash_canonical_csv_rows(
  old_primary_distribution
)
new_primary_distribution_hash <- h10_hash_canonical_csv_rows(
  new_primary_distribution
)
distribution_pass <- identical(
  old_primary_distribution_hash,
  new_primary_distribution_hash
)
primary_identity_rows[["primary_mder_distribution"]] <- tibble::tibble(
  artifact_component = "primary_mder_distribution",
  primary_mder_rows_before = nrow(old_primary_distribution),
  primary_mder_rows_after = nrow(new_primary_distribution),
  compared_columns = ncol(old_primary_distribution),
  before_sha256 = old_primary_distribution_hash,
  after_sha256 = new_primary_distribution_hash,
  identity_status = ifelse(distribution_pass, "PASS", "FAIL")
)
if (!distribution_pass) {
  h10_abort("Frozen primary MDER distribution identity guard failed")
}

for (record in list(
  list(
    "primary_model_frame_rds_entries",
    old_frames[
      grepl("mder", names(old_frames), ignore.case = TRUE) &
        grepl("^primary__", names(old_frames))
    ],
    model_frames[
      grepl("mder", names(model_frames), ignore.case = TRUE) &
        grepl("^primary__", names(model_frames))
    ]
  ),
  list(
    "primary_model_bundle_rds_entries",
    old_bundle_object$model_bundles[
      grepl("mder", names(old_bundle_object$model_bundles), ignore.case = TRUE) &
        grepl("^primary__", names(old_bundle_object$model_bundles))
    ],
    model_bundles[
      grepl("mder", names(model_bundles), ignore.case = TRUE) &
        grepl("^primary__", names(model_bundles))
    ]
  ),
  list(
    "primary_paired_model_rds_entries",
    old_sample_model_object$paired_placement_models[
      grepl(
        "^paired__primary__.*mder",
        names(old_sample_model_object$paired_placement_models),
        ignore.case = TRUE
      )
    ],
    sample_model_object$paired_placement_models[
      grepl(
        "^paired__primary__.*mder",
        names(sample_model_object$paired_placement_models),
        ignore.case = TRUE
      )
    ]
  ),
  list(
    "primary_preregistered_model_rds_entries",
    old_sample_model_object$preregistered_exclusion_models[
      grepl(
        "mder",
        names(old_sample_model_object$preregistered_exclusion_models),
        ignore.case = TRUE
      )
    ],
    sample_model_object$preregistered_exclusion_models[
      grepl(
        "mder",
        names(sample_model_object$preregistered_exclusion_models),
        ignore.case = TRUE
      )
    ]
  )
)) {
  before_hash <- h10_hash_object(record[[2L]])
  after_hash <- h10_hash_object(record[[3L]])
  pass <- identical(before_hash, after_hash)
  primary_identity_rows[[record[[1L]]]] <- tibble::tibble(
    artifact_component = record[[1L]],
    primary_mder_rows_before = length(record[[2L]]),
    primary_mder_rows_after = length(record[[3L]]),
    compared_columns = NA_integer_,
    before_sha256 = before_hash,
    after_sha256 = after_hash,
    identity_status = ifelse(pass, "PASS", "FAIL")
  )
  if (!pass) {
    h10_abort("Frozen primary MDER RDS guard failed for `%s`", record[[1L]])
  }
}
primary_mder_identity_audit <- dplyr::bind_rows(primary_identity_rows)

h10_adjustment_change <- function(
  name,
  before,
  after,
  keys
) {
  before <- h10_non_mder_rows(before) |>
    dplyr::select(
      dplyr::all_of(keys),
      p_adjusted_before = .data$p_adjusted,
      adjusted_significant_before = .data$adjusted_significant
    )
  after <- h10_non_mder_rows(after) |>
    dplyr::select(
      dplyr::all_of(keys),
      p_adjusted_after = .data$p_adjusted,
      adjusted_significant_after = .data$adjusted_significant
    )
  joined <- dplyr::full_join(before, after, by = keys, relationship = "one-to-one")
  adjusted_p_unchanged <-
    (is.na(joined$p_adjusted_before) & is.na(joined$p_adjusted_after)) |
    (
      !is.na(joined$p_adjusted_before) &
        !is.na(joined$p_adjusted_after) &
        joined$p_adjusted_before == joined$p_adjusted_after
    )
  absolute_change <- abs(
    joined$p_adjusted_before - joined$p_adjusted_after
  )
  adjusted_p_materially_changed <-
    xor(is.na(joined$p_adjusted_before), is.na(joined$p_adjusted_after)) |
    (!is.na(absolute_change) & absolute_change > 1e-12)
  tibble::tibble(
    artifact_component = name,
    non_mder_rows = nrow(joined),
    exact_changed_adjusted_p_rows = sum(!adjusted_p_unchanged),
    changed_adjusted_p_rows_above_1e_12 = sum(
      adjusted_p_materially_changed
    ),
    maximum_absolute_change = if (
      any(is.finite(joined$p_adjusted_before) &
        is.finite(joined$p_adjusted_after))
    ) {
      max(
        abs(joined$p_adjusted_before - joined$p_adjusted_after),
        na.rm = TRUE
      )
    } else {
      NA_real_
    },
    changed_adjusted_decision_rows = sum(
      joined$adjusted_significant_before !=
        joined$adjusted_significant_after,
      na.rm = TRUE
    ),
    interpretation = paste0(
      "Only multiplicity-derived fields in authorized families containing ",
      "the repaired MDER slot may change; exact floating-point differences ",
      "are separated from changes above 1e-12. Raw non-MDER model outputs ",
      "and all primary all-available outputs are identity-guarded."
    )
  )
}
multiplicity_change_audit <- dplyr::bind_rows(
  h10_adjustment_change(
    "all_available_model_tests",
    old_model_tests,
    model_tests,
    c("run_id", "metric_id", "comparison_id")
  ),
  h10_adjustment_change(
    "paired_placement",
    old_paired_results,
    paired_results,
    c("data_scenario", "placement", "metric_id", "predictor")
  ),
  h10_adjustment_change(
    "primary_gap_common",
    old_gap_common_results,
    gap_common_results,
    c("data_scenario", "placement", "metric_id", "predictor")
  ),
  h10_adjustment_change(
    "preregistered_exclusion",
    old_prereg_results,
    prereg_results,
    c("placement", "metric_id", "predictor")
  ),
  h10_adjustment_change(
    "leave_one_site_out",
    old_loso,
    leave_one_site_out,
    c("placement", "metric_id", "predictor", "omitted_site")
  )
)

amendment_results <- model_effects |>
  dplyr::filter(.data$metric_id == mder_id) |>
  dplyr::left_join(
    model_tests |>
      dplyr::filter(
        .data$metric_id == mder_id,
        .data$comparison_id %in% c("AGE-MAIN", "SEX-MAIN")
      ) |>
      dplyr::mutate(
        predictor = dplyr::if_else(
          .data$comparison_id == "AGE-MAIN",
          "age",
          "biological_sex"
        )
      ) |>
      dplyr::select(
        .data$data_scenario,
        .data$placement,
        .data$predictor,
        .data$comparison_id,
        .data$p_raw,
        .data$p_adjusted,
        .data$raw_significant,
        .data$adjusted_significant
      ),
    by = c("data_scenario", "placement", "predictor"),
    relationship = "one-to-one"
  ) |>
  dplyr::select(
    .data$data_scenario,
    .data$placement,
    .data$predictor,
    .data$observations,
    .data$participants,
    .data$estimate_practical,
    .data$conf_low_practical,
    .data$conf_high_practical,
    .data$p_raw,
    .data$p_adjusted,
    .data$raw_significant,
    .data$adjusted_significant
  )

####
# Install the validated replacement artifacts atomically
####

h10_write_csv(input_audit, file.path(roots$model_data, "H10_input_audit.csv"))
h10_write_csv(
  provenance_qualification,
  file.path(roots$model_data, "H10_provenance_qualification.csv")
)
h10_write_csv(
  metric_registry,
  file.path(roots$model_data, "H10_metric_registry.csv")
)
h10_write_csv(
  mder_availability,
  file.path(roots$model_data, "H10_METRIC010_availability.csv")
)
h10_write_csv(
  gap_repair_record,
  file.path(roots$model_data, "H10_METRIC010_gap_repair_record.csv")
)
h10_write_rds(
  prepared,
  file.path(roots$model_data, "H10_approved_prepared_rows.rds")
)
h10_write_csv(
  model_frame_index,
  file.path(roots$model_data, "H10_model_frame_index.csv")
)
h10_write_rds(model_frames, file.path(roots$model_data, "H10_model_frames.rds"))

h10_write_rds(
  list(
    hypothesis_id = "H10",
    formula_contract = list(
      participant = h10_formula_set("participant"),
      participant_day = h10_formula_set("participant_day")
    ),
    model_bundles = model_bundles,
    provenance_qualification = provenance_qualification
  ),
  file.path(roots$models, "H10_primary_and_gap_model_bundles.rds")
)
h10_write_csv(model_manifest, file.path(roots$models, "H10_model_manifest.csv"))
h10_write_csv(model_tests, file.path(roots$tables, "H10_model_tests.csv"))
h10_write_csv(
  family_audit,
  file.path(roots$tables, "H10_multiplicity_family_audit.csv")
)
h10_write_csv(model_effects, file.path(roots$tables, "H10_model_effects.csv"))
h10_write_csv(
  site_effects,
  file.path(roots$tables, "H10_site_specific_effects.csv")
)
h10_write_csv(
  model_diagnostics,
  file.path(roots$diagnostics, "H10_model_diagnostics.csv")
)
# Primary diagnostic plot data and participant-deletion outputs are frozen.

h10_write_csv(
  paired_frame_audit,
  file.path(roots$model_data, "H10_paired_placement_sample_audit.csv")
)
h10_write_csv(
  paired_results,
  file.path(roots$sensitivity, "H10_paired_placement_main_effects.csv")
)
h10_write_csv(
  gap_common_audit,
  file.path(roots$model_data, "H10_primary_gap_common_sample_audit.csv")
)
h10_write_csv(
  gap_common_results,
  file.path(roots$sensitivity, "H10_primary_gap_common_sample_effects.csv")
)
# The primary preregistration-exclusion branch is frozen.
h10_write_rds(
  sample_model_object,
  file.path(roots$models, "H10_sample_sensitivity_models.rds")
)

# Non-MDER metric-specific and unavailable waking-only MDER records are frozen.
h10_write_rds(
  metric_model_object,
  file.path(roots$models, "H10_metric_sensitivity_models.rds")
)
h10_write_csv(
  mder_distribution,
  file.path(roots$sensitivity, "H10_mder_current_distribution.csv")
)
# All primary influence, LOSO, diagnostic, V0-comparison, and result files are
# frozen byte-for-byte under the bounded repaired-gap scope.
h10_write_csv(
  sensitivity_stability,
  file.path(roots$sensitivity, "H10_sensitivity_stability_summary.csv")
)

# Primary association and primary placement-matched figure sources are frozen.
h10_write_csv(
  gap_plot_source,
  file.path(roots$source_data, "H10_gap_common_sample_effects_data.csv")
)
# The primary diagnostic assessment figure source is frozen.

h10_write_csv(
  non_mder_identity_audit,
  file.path(
    roots$manifests,
    "H10_METRIC010_gap_repair_non_mder_identity_audit.csv"
  )
)
h10_write_csv(
  primary_mder_identity_audit,
  file.path(
    roots$manifests,
    "H10_METRIC010_gap_repair_primary_identity_audit.csv"
  )
)
h10_write_csv(
  multiplicity_change_audit,
  file.path(
    roots$manifests,
    "H10_METRIC010_gap_repair_multiplicity_change_audit.csv"
  )
)
h10_write_csv(
  amendment_results,
  file.path(roots$tables, "H10_METRIC010_amendment_results.csv")
)

execution_environment <- readr::read_csv(
  file.path(roots$manifests, "H10_execution_environment.csv"),
  show_col_types = FALSE
) |>
  dplyr::filter(.data$component != "METRIC-010 repaired gap reseal") |>
  dplyr::bind_rows(tibble::tibble(
    component = "METRIC-010 repaired gap reseal",
    version_or_status = paste0(
      "R 4.6.1; two corrected gap all-available MDER bundles, corrected gap ",
      "paired/matched branches, and both sides of the revised primary-gap ",
      "common samples only; primary all-available, primary paired, primary ",
      "preregistered-exclusion, primary LOSO, and all non-MDER fits frozen; ",
      "no resampling, so the pilot/runtime gate was not triggered"
    )
  ))
h10_write_csv(
  execution_environment,
  file.path(roots$manifests, "H10_execution_environment.csv")
)

message("H10 FIND-049/CHG-101 repaired-gap MDER reseal complete")
