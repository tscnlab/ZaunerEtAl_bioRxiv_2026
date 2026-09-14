#!/usr/bin/env Rscript

# Selectively reseal H10 after METRIC-011 normalized eight primary L10 means
# from numerical noise (4.163336342344337e-17 lx) to exact zero. Only primary
# L10 all-available, placement-matched, primary--gap common-sample, diagnostic,
# influence, and LOSO branches are refitted. All non-L10 fits and every
# METRIC-010 MDER object are identity-guarded and retained.

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
    "H10 METRIC-011 update requires R 4.6.1; found %s",
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
    "H10 METRIC-011 update is missing project package(s): %s",
    paste(missing_packages, collapse = ", ")
  )
}

h10_validate_contract()
producer <- "scripts/hypotheses/H10/run_h10_metric011_update.R"
l10_id <- "l10_mean_medi"
mder_id <- "mder_mean_of_viable_ratios"

roots <- list(
  model_data = file.path(root, "artifacts/06_model_data/H10"),
  models = file.path(root, "artifacts/07_models/H10"),
  diagnostics = file.path(root, "artifacts/08_diagnostics/H10"),
  sensitivity = file.path(root, "artifacts/08_diagnostics/H10/sensitivity"),
  tables = file.path(root, "artifacts/09_tables/H10"),
  source_data = file.path(root, "artifacts/11_source_data/H10"),
  manifests = file.path(root, "artifacts/12_manifests/H10")
)

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

h10_hash_canonical_rows <- function(data) {
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

h10_frame_summary <- function(frame) {
  tibble::tibble(
    observations = nrow(frame),
    participants = dplyr::n_distinct(frame$participant_key),
    participant_days = if (all(is.na(frame$local_date))) {
      NA_integer_
    } else {
      nrow(frame)
    },
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

h10_replace_rows <- function(old, replacement, selected) {
  dplyr::bind_rows(old[!selected, , drop = FALSE], replacement)
}

h10_adjust_selected_families <- function(
  data,
  family_columns,
  selected_rows
) {
  groups <- interaction(data[family_columns], drop = TRUE, lex.order = TRUE)
  selected_groups <- unique(groups[selected_rows])
  for (group in selected_groups) {
    rows <- which(groups == group)
    if (length(rows) != 17L) {
      h10_abort("A METRIC-011 family is not a complete 17-row registry")
    }
    data$p_adjusted[rows] <- adjust_p_family(
      data$p_raw[rows],
      method = "BH",
      n = 17L
    )
    data$raw_significant[rows] <-
      is.finite(data$p_raw[rows]) & data$p_raw[rows] <= 0.05
    data$adjusted_significant[rows] <-
      is.finite(data$p_adjusted[rows]) & data$p_adjusted[rows] <= 0.05
    data$p_raw_display[rows] <- nh_format_p_value(data$p_raw[rows])
    data$p_adjusted_display[rows] <- nh_format_p_value(data$p_adjusted[rows])
  }
  data
}

h10_context_columns <- c(
  "run_id", "data_scenario", "placement", "sample_scenario",
  "analytical_role", "metric_order", "metric_id", "manuscript_name",
  "abbreviation", "manuscript_category", "analysis_unit",
  "response_family", "response_transform", "effect_scale", "display_unit"
)

####
# Verify the controlling decision and current shared inputs
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
if (nrow(input_audit) != 36L || any(!input_audit$exists | !input_audit$hash_verified)) {
  h10_abort(
    "A METRIC-011 H10 input pin differs: %s",
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
      "8344bdc0339a53079bf9eeb7d86de1ad7c15373641c3a0a5a01d040b418895ce" ||
    base_verification$input_bundle_sha256 !=
      "e840ce9d2a7f653bc5ebbfe020ce087017dfdaf0276df09da578bda30a539916"
) {
  h10_abort("METRIC-011 base-model verification did not reproduce")
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
l10_spec <- metric_registry |>
  dplyr::filter(.data$metric_id == l10_id)
if (
  nrow(l10_spec) != 1L ||
    l10_spec$response_family != "gaussian" ||
    l10_spec$response_transform != "log10_offset_0.1" ||
    l10_spec$analysis_unit != "participant_day"
) {
  h10_abort("The H10 L10 Gaussian log10(value + 0.1) contract differs")
}

provenance_qualification <- tibble::tibble(
  decision_id = "METRIC-010/METRIC-011",
  finding_ids = "PREP-003/FIND-044; FIND-049/CHG-101 resolved",
  base_verification_status = base_verification$status,
  base_manifest_sha256 = base_verification$manifest_sha256,
  base_input_bundle_sha256 = base_verification$input_bundle_sha256,
  metric_manifest_sha256 = input_audit$observed_sha256[
    input_audit$input_role == "metric_manifest"
  ],
  mder_audit_manifest_sha256 = input_audit$observed_sha256[
    input_audit$input_role == "mder_audit_manifest"
  ],
  metric011_decision_sha256 = input_audit$observed_sha256[
    input_audit$input_role == "metric011_decision"
  ],
  metric011_evidence_manifest_sha256 = input_audit$observed_sha256[
    input_audit$input_role == "metric011_evidence_manifest"
  ],
  near_eye_participant_days = 816L,
  chest_participant_days = 902L,
  qualification = paste0(
    "The current Preparation 06 model-ready layer and METRIC-010 MDER values ",
    "were independently verified. METRIC-011 normalized eight primary L10 ",
    "means from numerical noise to exact zero without changing any sample or ",
    "non-L10 scientific value. FIND-049/CHG-101 remains resolved. Complete ",
    "independent reconstruction of the exact current state-support ",
    "classification remains open under PREP-003/FIND-044; this is not ",
    "evidence that stored values are incorrect."
  )
)

####
# Reconstruct current source rows and prove the eight-cell boundary
####

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

h10_source_rows <- function(object, data_scenario, scenario) {
  object$model_rows |>
    dplyr::filter(
      .data$scenario == .env$scenario,
      .data$metric_id %in% metric_registry$metric_id,
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
    dplyr::arrange(
      .data$placement,
      .data$metric_id,
      .data$site,
      .data$Id,
      .data$local_date
    )
}

h01_primary <- readRDS(file.path(root, "artifacts/06_model_data/H01.rds"))
h01_gap <- readRDS(file.path(
  root,
  "artifacts/06_model_data/H01/scenarios/manuscript_prepared_data/H01.rds"
))
current_all <- dplyr::bind_rows(
  h10_source_rows(h01_primary, "primary", "all_available"),
  h10_source_rows(h01_gap, "gap_timing_unaware", "all_available")
)
current_paired <- dplyr::bind_rows(
  h10_source_rows(h01_primary, "primary", "paired_common_sample"),
  h10_source_rows(h01_gap, "gap_timing_unaware", "paired_common_sample")
)

old_prepared <- readRDS(file.path(
  roots$model_data,
  "H10_approved_prepared_rows.rds"
))
source_key <- c(
  "data_scenario", "placement", "site", "Id", "local_date", "metric_id"
)

h10_source_change <- function(old, current, branch) {
  old_sorted <- old |>
    dplyr::arrange(dplyr::across(dplyr::all_of(source_key)))
  current_sorted <- current |>
    dplyr::arrange(dplyr::across(dplyr::all_of(source_key)))
  key_equal <- vapply(source_key, function(column) {
    identical(
      as.character(old_sorted[[column]]),
      as.character(current_sorted[[column]])
    )
  }, logical(1))
  if (!all(key_equal)) {
    h10_abort("METRIC-011 changed H10 source-row membership in `%s`", branch)
  }
  non_value <- setdiff(names(old_sorted), c(source_key, "value"))
  for (column in non_value) {
    old_value <- old_sorted[[column]]
    new_value <- current_sorted[[column]]
    if (is.factor(old_value)) old_value <- as.character(old_value)
    if (is.factor(new_value)) new_value <- as.character(new_value)
    if (!identical(old_value, new_value)) {
      h10_abort(
        "METRIC-011 changed non-response source field `%s` in `%s`",
        column,
        branch
      )
    }
  }
  changed <- which(old_sorted$value != current_sorted$value)
  output <- old_sorted[changed, source_key, drop = FALSE] |>
    dplyr::mutate(
      source_branch = branch,
      old_value_lx = old_sorted$value[changed],
      new_value_lx = current_sorted$value[changed]
    )
  if (
    nrow(output) != 8L ||
      any(output$data_scenario != "primary") ||
      any(output$metric_id != l10_id) ||
      any(output$old_value_lx != 4.163336342344337e-17) ||
      any(output$new_value_lx != 0)
  ) {
    h10_abort("The METRIC-011 eight-cell source boundary differs in `%s`", branch)
  }
  output
}

all_change <- h10_source_change(
  old_prepared$all_available_rows,
  current_all,
  "all_available"
)
paired_change <- h10_source_change(
  old_prepared$paired_common_rows,
  current_paired,
  "paired_common_sample"
)
if (!identical(all_change[source_key], paired_change[source_key])) {
  h10_abort("The eight METRIC-011 records are not identical across samples")
}
input_change_audit <- all_change |>
  dplyr::select(-.data$source_branch) |>
  dplyr::mutate(
    in_all_available = TRUE,
    in_paired_common_sample = TRUE,
    transformation = "log10(value + 0.1)",
    controlling_decision = "METRIC-011"
  ) |>
  dplyr::arrange(.data$placement, .data$site, .data$Id, .data$local_date)

prepared <- list(
  hypothesis_id = "H10",
  all_available_rows = current_all,
  paired_common_rows = current_paired,
  demographics = demographics,
  primary_prepared_metadata = h01_primary$metadata,
  gap_prepared_metadata = h01_gap$metadata,
  provenance_qualification = provenance_qualification
)

####
# Refit only two primary all-available L10 bundles
####

old_frames <- readRDS(file.path(roots$model_data, "H10_model_frames.rds"))
old_frame_index <- readr::read_csv(
  file.path(roots$model_data, "H10_model_frame_index.csv"),
  show_col_types = FALSE
)
old_bundle_object <- readRDS(file.path(
  roots$models,
  "H10_primary_and_gap_model_bundles.rds"
))
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
old_diagnostic_plot <- readr::read_csv(
  file.path(roots$source_data, "H10_primary_diagnostic_plot_data.csv"),
  show_col_types = FALSE
)
old_participant_influence <- readr::read_csv(
  file.path(roots$diagnostics, "H10_participant_deletion_influence.csv"),
  show_col_types = FALSE
)

model_frames <- old_frames
model_bundles <- old_bundle_object$model_bundles
replacement_frame_index <- list()
replacement_manifest <- list()
replacement_tests <- list()
replacement_effects <- list()
replacement_sites <- list()
replacement_diagnostics <- list()
replacement_diagnostic_plot <- list()
replacement_influence <- list()

for (placement in c("glasses", "chest")) {
  run_id <- paste("primary", placement, "all_available", sep = "__")
  key <- paste(run_id, l10_id, sep = "__")
  message("METRIC-011 primary all-available L10: ", placement)
  source <- current_all |>
    dplyr::filter(
      .data$data_scenario == "primary",
      .data$placement == .env$placement,
      .data$metric_id == l10_id
    )
  frame <- h10_prepare_model_frame(
    source,
    l10_spec,
    site_levels = site_levels,
    sample_scenario = "all_available"
  )
  bundle <- h10_fit_bundle(frame, l10_spec)
  model_frames[[key]] <- frame
  model_bundles[[key]] <- bundle

  context <- old_model_manifest |>
    dplyr::filter(.data$run_id == .env$run_id, .data$metric_id == l10_id) |>
    dplyr::slice(1L) |>
    dplyr::select(dplyr::all_of(h10_context_columns))
  replacement_frame_index[[key]] <- dplyr::bind_cols(
    context |>
      dplyr::select(
        .data$run_id,
        .data$data_scenario,
        .data$placement,
        .data$sample_scenario,
        .data$analytical_role,
        .data$metric_order,
        .data$metric_id,
        .data$manuscript_name,
        .data$analysis_unit,
        .data$response_family,
        .data$response_transform,
        .data$effect_scale
      ),
    h10_frame_summary(frame)
  )
  manifest <- h10_model_manifest_rows(bundle)
  replacement_manifest[[key]] <- dplyr::bind_cols(
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
  replacement_tests[[key]] <- dplyr::bind_cols(
    context[rep(1L, nrow(tests)), , drop = FALSE],
    tests
  )
  for (predictor in c("age", "biological_sex")) {
    effect_key <- paste(key, predictor, sep = "__")
    effect <- h10_effect_row(bundle, frame, predictor, l10_spec)
    replacement_effects[[effect_key]] <- dplyr::bind_cols(context, effect)
    interaction_name <- if (predictor == "age") "M_age_site" else "M_sex_site"
    site_effect <- h10_site_effects(
      bundle$final_fits[[interaction_name]]$model,
      frame,
      predictor,
      l10_spec
    )
    replacement_sites[[effect_key]] <- dplyr::bind_cols(
      context[rep(1L, nrow(site_effect)), , drop = FALSE],
      site_effect
    ) |>
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
    model_name <- if (predictor == "age") "M_age" else "M_sex"
    diagnostic <- h10_model_diagnostics(
      bundle$final_fits[[model_name]],
      frame,
      l10_spec
    )
    replacement_diagnostics[[effect_key]] <- dplyr::bind_cols(
      context,
      tibble::tibble(predictor = predictor),
      diagnostic
    )
    plot_data <- h10_diagnostic_plot_data(
      bundle$final_fits[[model_name]]$model,
      frame
    )
    replacement_diagnostic_plot[[effect_key]] <- dplyr::bind_cols(
      context[rep(1L, nrow(plot_data)), , drop = FALSE],
      tibble::tibble(predictor = predictor)[
        rep(1L, nrow(plot_data)),
        ,
        drop = FALSE
      ],
      plot_data
    )
    influence <- h10_delete_participant_influence(
      bundle$final_fits[[model_name]]$model,
      frame,
      l10_spec,
      predictor,
      effect
    )
    replacement_influence[[effect_key]] <- dplyr::bind_cols(
      context,
      tibble::tibble(predictor = predictor),
      influence
    )
  }
}

target_main <- function(data) {
  data$data_scenario == "primary" & data$metric_id == l10_id
}
model_frame_index <- h10_replace_rows(
  old_frame_index,
  dplyr::bind_rows(replacement_frame_index),
  target_main(old_frame_index)
) |>
  dplyr::arrange(.data$data_scenario, .data$placement, .data$metric_order)
model_manifest <- h10_replace_rows(
  old_model_manifest,
  dplyr::bind_rows(replacement_manifest),
  target_main(old_model_manifest)
) |>
  dplyr::arrange(
    .data$data_scenario,
    .data$placement,
    .data$metric_order,
    .data$fit_role,
    .data$model_name
  )
model_tests <- h10_replace_rows(
  old_model_tests,
  dplyr::bind_rows(replacement_tests),
  target_main(old_model_tests)
) |>
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
model_tests <- h10_adjust_selected_families(
  model_tests,
  "family_id",
  model_tests$data_scenario == "primary"
) |>
  dplyr::arrange(
    .data$data_scenario,
    .data$placement,
    .data$comparison_order,
    .data$metric_order
  )
model_effects <- h10_replace_rows(
  old_model_effects,
  dplyr::bind_rows(replacement_effects),
  target_main(old_model_effects)
) |>
  dplyr::arrange(
    .data$data_scenario,
    .data$placement,
    .data$predictor,
    .data$metric_order
  )
site_effects <- h10_replace_rows(
  old_site_effects,
  dplyr::bind_rows(replacement_sites),
  target_main(old_site_effects)
) |>
  dplyr::arrange(
    .data$data_scenario,
    .data$placement,
    .data$predictor,
    .data$metric_order,
    .data$weighting,
    .data$site_display_order
  )
model_diagnostics <- h10_replace_rows(
  old_model_diagnostics,
  dplyr::bind_rows(replacement_diagnostics),
  target_main(old_model_diagnostics)
) |>
  dplyr::arrange(
    .data$data_scenario,
    .data$placement,
    .data$predictor,
    .data$metric_order
  )
diagnostic_plot_data <- h10_replace_rows(
  old_diagnostic_plot,
  dplyr::bind_rows(replacement_diagnostic_plot),
  target_main(old_diagnostic_plot)
)
participant_influence <- h10_replace_rows(
  old_participant_influence,
  dplyr::bind_rows(replacement_influence),
  target_main(old_participant_influence)
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
if (any(!family_audit$complete_17_member_family |
  !family_audit$independent_recalculation_matches)) {
  h10_abort("A METRIC-011 all-available family failed verification")
}

####
# Refit primary placement-matched and primary--gap common L10 branches
####

old_sample_object <- readRDS(file.path(
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

paired_metric_rows <- current_paired |>
  dplyr::filter(
    .data$data_scenario == "primary",
    .data$metric_id == l10_id
  )
paired_keys <- lapply(c("glasses", "chest"), function(placement) {
  paired_metric_rows |>
    dplyr::filter(.data$placement == .env$placement) |>
    h10_common_key("participant_day") |>
    sort()
})
if (!identical(paired_keys[[1L]], paired_keys[[2L]]) ||
  length(paired_keys[[1L]]) != 643L) {
  h10_abort("The METRIC-011 primary placement-matched keys differ")
}

paired_replacement <- list()
paired_models <- list()
for (placement in c("glasses", "chest")) {
  source <- paired_metric_rows |>
    dplyr::filter(.data$placement == .env$placement)
  frame <- h10_prepare_model_frame(
    source,
    l10_spec,
    site_levels = site_levels,
    sample_scenario = "paired_common_sample"
  )
  for (predictor in c("age", "biological_sex")) {
    message("METRIC-011 paired L10: ", placement, " / ", predictor)
    key <- paste(
      "paired", "primary", placement, l10_id, predictor, sep = "__"
    )
    fit <- h10_fit_main_sensitivity(frame, l10_spec, predictor)
    paired_replacement[[key]] <- dplyr::bind_cols(
      tibble::tibble(
        data_scenario = "primary",
        placement = placement,
        sample_scenario = "paired_common_sample",
        metric_order = l10_spec$metric_order,
        metric_id = l10_id,
        manuscript_name = l10_spec$manuscript_name,
        abbreviation = l10_spec$abbreviation,
        unavailable_reason = NA_character_
      ),
      fit$summary
    )
    paired_models[[key]] <- fit$models
  }
}
paired_results <- h10_replace_rows(
  old_paired_results,
  dplyr::bind_rows(paired_replacement),
  old_paired_results$data_scenario == "primary" &
    old_paired_results$metric_id == l10_id
)
paired_results <- h10_adjust_selected_families(
  paired_results,
  c("data_scenario", "placement", "predictor"),
  paired_results$data_scenario == "primary"
) |>
  dplyr::arrange(
    .data$data_scenario,
    .data$placement,
    .data$predictor,
    .data$metric_order
  )

gap_common_replacement <- list()
gap_common_models <- list()
for (placement in c("glasses", "chest")) {
  primary_source <- current_all |>
    dplyr::filter(
      .data$data_scenario == "primary",
      .data$placement == .env$placement,
      .data$metric_id == l10_id
    )
  gap_source <- current_all |>
    dplyr::filter(
      .data$data_scenario == "gap_timing_unaware",
      .data$placement == .env$placement,
      .data$metric_id == l10_id
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
  expected_n <- if (placement == "glasses") 809L else 894L
  if (nrow(primary_common) != expected_n) {
    h10_abort("The METRIC-011 primary--gap common L10 sample differs")
  }
  frame <- h10_prepare_model_frame(
    primary_common,
    l10_spec,
    site_levels = site_levels,
    sample_scenario = "primary_gap_common_sample"
  )
  for (predictor in c("age", "biological_sex")) {
    message("METRIC-011 primary--gap common L10: ", placement, " / ", predictor)
    key <- paste(
      "gap_common", "primary", placement, l10_id, predictor, sep = "__"
    )
    fit <- h10_fit_main_sensitivity(frame, l10_spec, predictor)
    gap_common_replacement[[key]] <- dplyr::bind_cols(
      tibble::tibble(
        data_scenario = "primary",
        placement = placement,
        sample_scenario = "primary_gap_common_sample",
        metric_order = l10_spec$metric_order,
        metric_id = l10_id,
        manuscript_name = l10_spec$manuscript_name,
        abbreviation = l10_spec$abbreviation
      ),
      fit$summary
    )
    gap_common_models[[key]] <- fit$models
  }
}
gap_common_results <- h10_replace_rows(
  old_gap_common_results,
  dplyr::bind_rows(gap_common_replacement),
  old_gap_common_results$data_scenario == "primary" &
    old_gap_common_results$metric_id == l10_id
)
gap_common_results <- h10_adjust_selected_families(
  gap_common_results,
  c("data_scenario", "placement", "predictor"),
  gap_common_results$data_scenario == "primary"
) |>
  dplyr::arrange(
    .data$data_scenario,
    .data$placement,
    .data$predictor,
    .data$metric_order
  )

sample_object <- old_sample_object
sample_object$paired_placement_models[names(paired_models)] <- paired_models
sample_object$primary_gap_common_models[names(gap_common_models)] <-
  gap_common_models
sample_object$provenance_qualification <- provenance_qualification

####
# Refit only primary L10 leave-one-site-out and rebuild assessments
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

loso_replacement <- list()
for (placement in c("glasses", "chest")) {
  run_id <- paste("primary", placement, "all_available", sep = "__")
  frame <- model_frames[[paste(run_id, l10_id, sep = "__")]]
  for (predictor in c("age", "biological_sex")) {
    for (omitted_site in site_levels) {
      message(
        "METRIC-011 LOSO L10: ", placement, " / ", predictor,
        " / ", omitted_site
      )
      key <- paste(placement, predictor, omitted_site, sep = "__")
      refit <- h10_loso_refit(
        frame,
        l10_spec,
        predictor,
        omitted_site
      )
      loso_replacement[[key]] <- dplyr::bind_cols(
        tibble::tibble(
          placement = placement,
          metric_order = l10_spec$metric_order,
          metric_id = l10_id,
          manuscript_name = l10_spec$manuscript_name,
          abbreviation = l10_spec$abbreviation,
          omitted_site_present = omitted_site %in% levels(frame$site)
        ),
        refit
      )
    }
  }
}
loso_replacement <- dplyr::bind_rows(loso_replacement) |>
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
derived_loso_columns <- c(
  "p_adjusted", "adjusted_significant", "p_raw_display",
  "p_adjusted_display", "full_p_adjusted", "full_adjusted_significant",
  "full_estimate_model", "full_standard_error",
  "estimate_change_from_full", "change_in_full_standard_errors",
  "sign_reversal", "adjusted_support_changed"
)
loso_base <- old_loso |>
  dplyr::select(-dplyr::any_of(derived_loso_columns))
leave_one_site_out <- h10_replace_rows(
  loso_base,
  loso_replacement,
  loso_base$metric_id == l10_id
)
leave_one_site_out$p_adjusted <- NA_real_
leave_one_site_out$raw_significant <- FALSE
leave_one_site_out$adjusted_significant <- FALSE
leave_one_site_out$p_raw_display <- NA_character_
leave_one_site_out$p_adjusted_display <- NA_character_
leave_one_site_out <- h10_adjust_selected_families(
  leave_one_site_out,
  c("placement", "predictor", "omitted_site"),
  rep(TRUE, nrow(leave_one_site_out))
) |>
  dplyr::arrange(
    .data$placement,
    .data$predictor,
    .data$metric_order,
    .data$omitted_site_order
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

####
# Rebuild tables that directly consume the changed branches
####

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

h10_effect_display <- function(data) {
  dplyr::case_when(
    data$practical_effect_type == "ratio" ~
      sprintf(
        "%.2f× (%.2f–%.2f)",
        data$estimate_practical,
        data$conf_low_practical,
        data$conf_high_practical
      ),
    data$practical_effect_type == "odds ratio" ~
      sprintf(
        "OR %.2f (%.2f–%.2f)",
        data$estimate_practical,
        data$conf_low_practical,
        data$conf_high_practical
      ),
    data$practical_unit == "h" ~
      sprintf(
        "%.1f min (%.1f–%.1f)",
        data$estimate_minutes,
        data$conf_low_minutes,
        data$conf_high_minutes
      ),
    data$practical_unit == "min" ~
      sprintf(
        "%.1f min (%.1f–%.1f)",
        data$estimate_practical,
        data$conf_low_practical,
        data$conf_high_practical
      ),
    TRUE ~
      sprintf(
        "%.3f (%.3f–%.3f)",
        data$estimate_practical,
        data$conf_low_practical,
        data$conf_high_practical
      )
  )
}

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
    significance_rule = paste0(
      "BH-adjusted p ≤ 0.05 within the labelled 17-member family"
    )
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
prereg_for_join <- old_prereg_results |>
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

old_v0_comparison <- readr::read_csv(
  file.path(roots$tables, "H10_v0_to_current_comparison.csv"),
  show_col_types = FALSE
)
current_v0_fields <- model_tests |>
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
  )
v0_comparison <- old_v0_comparison |>
  dplyr::select(-dplyr::any_of(c(
    "current_p_raw", "current_p_adjusted", "current_p_adjusted_display",
    "current_adjusted_supported", "current_comparison_method",
    "conclusion_changed"
  ))) |>
  dplyr::left_join(
    current_v0_fields,
    by = c("placement", "metric_id", "comparison_id"),
    relationship = "one-to-one"
  ) |>
  dplyr::mutate(
    conclusion_changed = .data$v0_adjusted_supported !=
      .data$current_adjusted_supported
  ) |>
  dplyr::arrange(.data$placement, .data$comparison_id, .data$metric_order)

####
# Identity and multiplicity audits before any result artifact is replaced
####

h10_assert_frozen_rows <- function(label, old, current, frozen) {
  old_hash <- h10_hash_canonical_rows(old[frozen(old), , drop = FALSE])
  new_hash <- h10_hash_canonical_rows(current[frozen(current), , drop = FALSE])
  tibble::tibble(
    check = label,
    expected_sha256 = old_hash,
    observed_sha256 = new_hash,
    passed = identical(old_hash, new_hash)
  )
}

h10_without_bh_fields <- function(data) {
  data |>
    dplyr::select(-dplyr::any_of(c(
      "p_adjusted", "raw_significant", "adjusted_significant",
      "p_raw_display", "p_adjusted_display"
    )))
}

frozen_main <- function(data) {
  !(data$data_scenario == "primary" & data$metric_id == l10_id)
}
identity_audit <- dplyr::bind_rows(
  h10_assert_frozen_rows(
    "all-available model manifest outside primary L10",
    old_model_manifest,
    model_manifest,
    frozen_main
  ),
  h10_assert_frozen_rows(
    "all-available model effects outside primary L10",
    old_model_effects,
    model_effects,
    frozen_main
  ),
  h10_assert_frozen_rows(
    "all-available site effects outside primary L10",
    old_site_effects,
    site_effects,
    frozen_main
  ),
  h10_assert_frozen_rows(
    "all-available diagnostics outside primary L10",
    old_model_diagnostics,
    model_diagnostics,
    frozen_main
  ),
  h10_assert_frozen_rows(
    "primary diagnostic plot rows outside primary L10",
    old_diagnostic_plot,
    diagnostic_plot_data,
    function(data) data$metric_id != l10_id
  ),
  h10_assert_frozen_rows(
    "participant influence outside primary L10",
    old_participant_influence,
    participant_influence,
    function(data) data$metric_id != l10_id
  ),
  h10_assert_frozen_rows(
    "paired results outside primary L10",
    h10_without_bh_fields(old_paired_results),
    h10_without_bh_fields(paired_results),
    frozen_main
  ),
  h10_assert_frozen_rows(
    "primary--gap common results outside primary L10",
    h10_without_bh_fields(old_gap_common_results),
    h10_without_bh_fields(gap_common_results),
    frozen_main
  )
)

old_non_target_bundles <- old_bundle_object$model_bundles[
  !grepl("^primary__(glasses|chest)__all_available__l10_mean_medi$",
    names(old_bundle_object$model_bundles)
  )
]
new_non_target_bundles <- model_bundles[names(old_non_target_bundles)]
old_non_target_frames <- old_frames[
  !grepl("^primary__(glasses|chest)__all_available__l10_mean_medi$",
    names(old_frames)
  )
]
new_non_target_frames <- model_frames[names(old_non_target_frames)]
sample_target_names <- c(names(paired_models), names(gap_common_models))
old_sample_frozen <- list(
  paired = old_sample_object$paired_placement_models[
    !names(old_sample_object$paired_placement_models) %in% names(paired_models)
  ],
  common = old_sample_object$primary_gap_common_models[
    !names(old_sample_object$primary_gap_common_models) %in%
      names(gap_common_models)
  ],
  preregistered = old_sample_object$preregistered_exclusion_models
)
new_sample_frozen <- list(
  paired = sample_object$paired_placement_models[names(old_sample_frozen$paired)],
  common = sample_object$primary_gap_common_models[names(old_sample_frozen$common)],
  preregistered = sample_object$preregistered_exclusion_models
)
identity_audit <- dplyr::bind_rows(
  identity_audit,
  tibble::tibble(
    check = c(
      "all non-target model bundles, including every MDER bundle",
      "all non-target model frames, including every MDER frame",
      "all frozen sample-model objects, including MDER and preregistration"
    ),
    expected_sha256 = c(
      h10_hash_object(old_non_target_bundles),
      h10_hash_object(old_non_target_frames),
      h10_hash_object(old_sample_frozen)
    ),
    observed_sha256 = c(
      h10_hash_object(new_non_target_bundles),
      h10_hash_object(new_non_target_frames),
      h10_hash_object(new_sample_frozen)
    )
  ) |>
    dplyr::mutate(passed = .data$expected_sha256 == .data$observed_sha256)
)

h10_raw_p_identity <- function(label, old, current, keys, frozen) {
  old_selected <- old[frozen(old), c(keys, "p_raw"), drop = FALSE] |>
    dplyr::arrange(dplyr::across(dplyr::all_of(keys)))
  new_selected <- current[frozen(current), c(keys, "p_raw"), drop = FALSE] |>
    dplyr::arrange(dplyr::across(dplyr::all_of(keys)))
  tibble::tibble(
    check = label,
    expected_sha256 = h10_hash_object(old_selected),
    observed_sha256 = h10_hash_object(new_selected),
    passed = identical(old_selected, new_selected)
  )
}
identity_audit <- dplyr::bind_rows(
  identity_audit,
  h10_raw_p_identity(
    "all non-L10 and frozen-gap all-available raw p-values",
    old_model_tests,
    model_tests,
    c("run_id", "metric_id", "comparison_id"),
    frozen_main
  ),
  h10_raw_p_identity(
    "all non-L10 and frozen-gap paired raw p-values",
    old_paired_results,
    paired_results,
    c("data_scenario", "placement", "metric_id", "predictor"),
    frozen_main
  ),
  h10_raw_p_identity(
    "all non-L10 and frozen-gap common-sample raw p-values",
    old_gap_common_results,
    gap_common_results,
    c("data_scenario", "placement", "metric_id", "predictor"),
    frozen_main
  ),
  h10_raw_p_identity(
    "all non-L10 LOSO raw p-values",
    old_loso,
    leave_one_site_out,
    c("placement", "metric_id", "predictor", "omitted_site"),
    function(data) data$metric_id != l10_id
  )
)
if (any(!identity_audit$passed)) {
  h10_abort(
    "A METRIC-011 frozen-result identity guard failed: %s",
    paste(identity_audit$check[!identity_audit$passed], collapse = "; ")
  )
}

h10_multiplicity_audit <- function(branch, old, current, keys, selected) {
  old_selected <- old[selected(old), c(keys, "p_raw", "p_adjusted"), drop = FALSE] |>
    dplyr::rename(old_p_raw = .data$p_raw, old_p_adjusted = .data$p_adjusted)
  new_selected <- current[selected(current), c(keys, "p_raw", "p_adjusted"), drop = FALSE] |>
    dplyr::rename(new_p_raw = .data$p_raw, new_p_adjusted = .data$p_adjusted)
  dplyr::inner_join(old_selected, new_selected, by = keys, relationship = "one-to-one") |>
    dplyr::mutate(
      branch = branch,
      raw_p_identical =
        (is.na(.data$old_p_raw) & is.na(.data$new_p_raw)) |
        (!is.na(.data$old_p_raw) & !is.na(.data$new_p_raw) &
          .data$old_p_raw == .data$new_p_raw),
      adjusted_p_changed = dplyr::case_when(
        is.na(.data$old_p_adjusted) & is.na(.data$new_p_adjusted) ~ FALSE,
        is.na(.data$old_p_adjusted) | is.na(.data$new_p_adjusted) ~ TRUE,
        TRUE ~ .data$old_p_adjusted != .data$new_p_adjusted
      ),
      change_scope = dplyr::if_else(
        .data$metric_id == l10_id,
        "refitted L10 family member",
        "BH-derived field only; raw p-value frozen"
      ),
      .before = 1L
    )
}
multiplicity_audit <- dplyr::bind_rows(
  h10_multiplicity_audit(
    "primary_all_available",
    old_model_tests,
    model_tests,
    c("data_scenario", "placement", "comparison_id", "metric_id"),
    function(data) data$data_scenario == "primary"
  ),
  h10_multiplicity_audit(
    "primary_paired_common_sample",
    old_paired_results,
    paired_results,
    c("data_scenario", "placement", "predictor", "metric_id"),
    function(data) data$data_scenario == "primary"
  ),
  h10_multiplicity_audit(
    "primary_gap_common_sample_primary_side",
    old_gap_common_results,
    gap_common_results,
    c("data_scenario", "placement", "predictor", "metric_id"),
    function(data) data$data_scenario == "primary"
  ),
  h10_multiplicity_audit(
    "primary_leave_one_site_out",
    old_loso,
    leave_one_site_out,
    c("placement", "predictor", "omitted_site", "metric_id"),
    function(data) rep(TRUE, nrow(data))
  )
)
if (any(!multiplicity_audit$raw_p_identical &
  multiplicity_audit$metric_id != l10_id)) {
  h10_abort("METRIC-011 changed a non-L10 raw p-value")
}

model_update_summary <- tibble::tibble(
  update_id = "METRIC-011",
  changed_primary_l10_cells = 8L,
  primary_all_available_bundles_refitted = 2L,
  primary_paired_main_models_refitted = 4L,
  primary_gap_common_main_models_refitted = 4L,
  primary_loso_rows_refitted = 36L,
  participant_deletion_models_refitted = 4L,
  l10_raw_p_values_changed = sum(
    !multiplicity_audit$raw_p_identical &
      multiplicity_audit$metric_id == l10_id
  ),
  non_l10_raw_p_values_changed = 0L,
  bh_adjusted_values_changed = sum(multiplicity_audit$adjusted_p_changed),
  non_l10_bh_derived_fields_changed = sum(
    multiplicity_audit$adjusted_p_changed &
      multiplicity_audit$metric_id != l10_id
  ),
  significance_decisions_changed = sum(
    (multiplicity_audit$old_p_adjusted <= 0.05) !=
      (multiplicity_audit$new_p_adjusted <= 0.05),
    na.rm = TRUE
  ),
  maximum_absolute_raw_p_change = max(
    abs(multiplicity_audit$new_p_raw - multiplicity_audit$old_p_raw),
    na.rm = TRUE
  ),
  maximum_absolute_adjusted_p_change = max(
    abs(
      multiplicity_audit$new_p_adjusted -
        multiplicity_audit$old_p_adjusted
    ),
    na.rm = TRUE
  ),
  mder_models_changed = 0L,
  resampling_replicates = 0L,
  pilot_runtime_gate_triggered = FALSE,
  boundary_assessment = "PASS"
)

####
# Install the bounded result update atomically, one artifact at a time
####

h10_write_csv(input_audit, file.path(roots$model_data, "H10_input_audit.csv"))
h10_write_csv(
  provenance_qualification,
  file.path(roots$model_data, "H10_provenance_qualification.csv")
)
h10_write_csv(
  h10_approval_registry(),
  file.path(roots$model_data, "H10_author_approvals.csv")
)
h10_write_rds(prepared, file.path(roots$model_data, "H10_approved_prepared_rows.rds"))
h10_write_csv(
  input_change_audit,
  file.path(roots$model_data, "H10_METRIC011_l10_cell_changes.csv")
)
h10_write_rds(model_frames, file.path(roots$model_data, "H10_model_frames.rds"))
h10_write_csv(
  model_frame_index,
  file.path(roots$model_data, "H10_model_frame_index.csv")
)
h10_write_rds(
  list(
    hypothesis_id = "H10",
    formula_contract = old_bundle_object$formula_contract,
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
h10_write_csv(
  diagnostic_plot_data,
  file.path(roots$source_data, "H10_primary_diagnostic_plot_data.csv")
)
h10_write_csv(
  participant_influence,
  file.path(roots$diagnostics, "H10_participant_deletion_influence.csv")
)
h10_write_rds(
  sample_object,
  file.path(roots$models, "H10_sample_sensitivity_models.rds")
)
h10_write_csv(
  paired_results,
  file.path(roots$sensitivity, "H10_paired_placement_main_effects.csv")
)
h10_write_csv(
  gap_common_results,
  file.path(roots$sensitivity, "H10_primary_gap_common_sample_effects.csv")
)
h10_write_csv(
  leave_one_site_out,
  file.path(roots$diagnostics, "H10_leave_one_site_out.csv")
)
h10_write_csv(
  loso_summary,
  file.path(roots$diagnostics, "H10_leave_one_site_out_summary.csv")
)
h10_write_csv(
  diagnostic_assessment,
  file.path(roots$diagnostics, "H10_primary_diagnostic_assessment.csv")
)
h10_write_csv(
  primary_results,
  file.path(roots$tables, "H10_primary_main_results.csv")
)
h10_write_csv(
  primary_interactions,
  file.path(roots$tables, "H10_primary_interaction_results.csv")
)
h10_write_csv(
  sensitivity_stability,
  file.path(roots$sensitivity, "H10_sensitivity_stability_summary.csv")
)
h10_write_csv(
  v0_comparison,
  file.path(roots$tables, "H10_v0_to_current_comparison.csv")
)
h10_write_csv(
  identity_audit,
  file.path(roots$manifests, "H10_METRIC011_frozen_identity_audit.csv")
)
h10_write_csv(
  multiplicity_audit,
  file.path(roots$manifests, "H10_METRIC011_multiplicity_audit.csv")
)
h10_write_csv(
  model_update_summary,
  file.path(roots$manifests, "H10_METRIC011_update_summary.csv")
)

execution_path <- file.path(roots$manifests, "H10_execution_environment.csv")
execution_environment <- readr::read_csv(
  execution_path,
  show_col_types = FALSE
) |>
  dplyr::filter(.data$component != "METRIC-011 selective update") |>
  dplyr::bind_rows(tibble::tibble(
    component = "METRIC-011 selective update",
    version_or_status = paste0(
      "R 4.6.1; two primary all-available L10 bundles, four primary paired ",
      "main models, four primary-side common-sample main models, 36 L10 LOSO ",
      "rows, and four participant-deletion models only; every non-L10 and ",
      "METRIC-010 MDER model frozen; no resampling"
    )
  ))
h10_write_csv(execution_environment, execution_path)

message(
  "H10 METRIC-011 bounded update complete: 8 cells, 2 all-available bundles, ",
  "8 matched/common main models, 36 LOSO rows; all frozen guards PASS"
)
