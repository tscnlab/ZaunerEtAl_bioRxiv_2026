# Run the author-approved H10 Stage 2 implementation and V0 comparison.

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
    "H10 Stage 2 requires R 4.6.1; found %s",
    as.character(getRversion())
  )
}

required_packages <- c(
  "dplyr",
  "tidyr",
  "purrr",
  "tibble",
  "readr",
  "digest",
  "openssl",
  "lme4",
  "reformulas",
  "glmmTMB",
  "performance",
  "ggplot2",
  "patchwork",
  "sass",
  "scales",
  "rvest",
  "gt"
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
  h10_abort(
    "H10 Stage 2 is missing project package(s): %s",
    paste(missing_packages, collapse = ", ")
  )
}

h10_validate_contract()

producer <- "scripts/hypotheses/H10/run_h10_stage2.R"
stage <- Sys.getenv("H10_STAGE", unset = "fit")
if (!stage %in% c("fit", "manifest")) {
  h10_abort("H10_STAGE must be `fit` or `manifest`")
}

roots <- list(
  model_data = file.path(root, "artifacts/06_model_data/H10"),
  models = file.path(root, "artifacts/07_models/H10"),
  diagnostics = file.path(root, "artifacts/08_diagnostics/H10"),
  sensitivity = file.path(root, "artifacts/08_diagnostics/H10/sensitivity"),
  tables = file.path(root, "artifacts/09_tables/H10"),
  figures = file.path(root, "artifacts/10_figures/H10"),
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

h10_relative_path <- function(path) {
  normalized <- normalizePath(path, winslash = "/", mustWork = TRUE)
  if (startsWith(normalized, paste0(root, "/"))) {
    substring(normalized, nchar(root) + 2L)
  } else {
    normalized
  }
}

h10_build_manifest <- function() {
  artifact_files <- sort(unique(unlist(lapply(
    roots,
    list.files,
    recursive = TRUE,
    full.names = TRUE
  ))))
  manifest_path <- file.path(roots$manifests, "H10_stage2_artifacts.csv")
  downstream_manifest_paths <- file.path(
    roots$manifests,
    c(
      "H10_stage3_artifacts.csv",
      "H10_preparation_report_manifest.csv"
    )
  )
  normalized_downstream_manifests <- normalizePath(
    downstream_manifest_paths,
    winslash = "/",
    mustWork = FALSE
  )
  artifact_files <- artifact_files[
    file.exists(artifact_files) &
      !dir.exists(artifact_files) &
      normalizePath(artifact_files, winslash = "/", mustWork = TRUE) !=
        normalizePath(manifest_path, winslash = "/", mustWork = FALSE) &
      !normalizePath(
        artifact_files,
        winslash = "/",
        mustWork = TRUE
      ) %in% normalized_downstream_manifests
  ]
  code_and_report <- c(
    file.path(root, "scripts/hypotheses/H10/h10_contract.R"),
    file.path(root, "scripts/hypotheses/H10/h10_modeling.R"),
    file.path(root, "scripts/hypotheses/H10/run_h10_stage2.R"),
    file.path(root, "scripts/hypotheses/H10/run_h10_metric010_update.R"),
    file.path(root, "scripts/hypotheses/H10/run_h10_metric011_update.R"),
    file.path(
      root,
      "scripts/hypotheses/H10/audit_h10_metric010_multiplicity_changes.R"
    ),
    file.path(root, "scripts/hypotheses/H10/build_h10_metric010_figures.R"),
    file.path(root, "scripts/hypotheses/H10/build_h10_metric011_figures.R"),
    file.path(root, "tests/hypotheses/H10/test_h10_stage2.R"),
    file.path(root, "audit/hypotheses/H10/01_audit_and_plan.qmd"),
    file.path(root, "audit/hypotheses/H10/01_audit_and_plan.html"),
    file.path(root, "audit/hypotheses/H10/01_author_decision.md"),
    file.path(
      root,
      "audit/hypotheses/H10/01_response_contract_amendment.md"
    ),
    file.path(
      root,
      "audit/hypotheses/H10/02_implementation_and_v0_comparison.qmd"
    ),
    file.path(
      root,
      "audit/hypotheses/H10/02_implementation_and_v0_comparison.html"
    ),
    file.path(root, "audit/hypotheses/H10/02_figure_visual_qa.md"),
    file.path(
      root,
      "audit/hypotheses/H10/05_METRIC010_author_continuation.md"
    ),
    file.path(root, "audit/handoffs/H10_worker_handoff.md"),
    file.path(root, "audit/handoffs/H10_shared_change_request.md")
  )
  files <- sort(unique(c(
    artifact_files,
    code_and_report[file.exists(code_and_report)]
  )))
  manifest <- dplyr::bind_rows(lapply(files, function(path) {
    info <- file.info(path)
    tibble::tibble(
      path = h10_relative_path(path),
      artifact_type = tools::file_ext(path),
      sha256 = artifact_sha256(path),
      bytes = as.numeric(info$size),
      producer = producer,
      r_version = as.character(getRversion()),
      written_utc = format(info$mtime, tz = "UTC", usetz = TRUE),
      provenance_qualification = paste0(
        "PREP-003/FIND-044: current Preparation 06 base layer and METRIC-010 ",
        "MDER values independently verified, including the FIND-049/CHG-101 ",
        "gap-MDER repair; METRIC-011 normalized eight primary L10 means from ",
        "numerical noise to exact zero without changing samples or non-L10 ",
        "scientific values; complete ",
        "independent reconstruction of the exact current state-support ",
        "classification remains open; this is not evidence that the data ",
        "are incorrect"
      )
    )
  }))
  h10_write_csv(manifest, manifest_path)
  invisible(manifest_path)
}

if (identical(stage, "manifest")) {
  h10_build_manifest()
  message("H10 Stage 2 manifest refreshed")
  quit(save = "no", status = 0L)
}

####
# Step 1: Verify the approved contract and every pinned input
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
  failed <- input_audit |>
    dplyr::filter(!.data$exists | !.data$hash_verified) |>
    dplyr::pull(.data$input_role)
  h10_abort(
    "An approved H10 input pin differs: %s",
    paste(failed, collapse = ", ")
  )
}

base_verification <- verify_base_model_data_artifacts(
  root = root,
  output_root = root
)
if (
  base_verification$status != "PASS" ||
    base_verification$manifest_sha256 !=
      input_contract$expected_sha256[
        input_contract$input_role == "base_manifest"
      ] ||
    base_verification$input_bundle_sha256 !=
      "e840ce9d2a7f653bc5ebbfe020ce087017dfdaf0276df09da578bda30a539916"
) {
  h10_abort("PREP06-BASE-002 independent verification did not reproduce")
}

metric_registry <- h10_metric_registry()
comparison_registry <- h10_comparison_registry()
run_registry <- h10_primary_run_registry()
approval_registry <- h10_approval_registry()

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
  dplyr::left_join(
    metric_display,
    by = "metric_id",
    relationship = "one-to-one"
  )
if (
  nrow(metric_registry) != 17L ||
    any(is.na(metric_registry$manuscript_name)) ||
    any(
      gsub("-", "_", metric_registry$display_analysis_unit) !=
        metric_registry$analysis_unit
    )
) {
  h10_abort("H10 metric display registry reconciliation failed")
}

h01_primary <- readRDS(file.path(root, "artifacts/06_model_data/H01.rds"))
h01_gap <- readRDS(file.path(
  root,
  "artifacts/06_model_data/H01/scenarios/manuscript_prepared_data/H01.rds"
))
if (
  h01_primary$metadata$base_manifest_sha256 !=
    "8344bdc0339a53079bf9eeb7d86de1ad7c15373641c3a0a5a01d040b418895ce" ||
    h01_primary$metadata$metric_manifest_sha256 !=
      "028bce108339c1277df4a070597430ea20b49c34c2888f4eef42741c1fe76a5e" ||
    h01_primary$metadata$paired_participant_metric_status !=
      "unavailable_pending_minute_level_recomputation" ||
    h01_gap$metadata$paired_participant_metric_status !=
      "unavailable_pending_minute_level_recomputation"
) {
  h10_abort("H10 inherited prepared-row provenance differs from the gate")
}

daily_counts <- c(
  glasses = nrow(readRDS(file.path(
    root,
    "artifacts/06_model_data/base/metrics_glasses_participant_day_enriched.rds"
  ))),
  chest = nrow(readRDS(file.path(
    root,
    "artifacts/06_model_data/base/metrics_chest_participant_day_enriched.rds"
  )))
)
if (!identical(unname(daily_counts), c(816L, 902L))) {
  h10_abort("PREP06-BASE-002 daily row counts differ from 816/902")
}

provenance_qualification <- tibble::tibble(
  decision_id = "METRIC-010",
  finding_ids = "PREP-003/FIND-044",
  base_verification_status = base_verification$status,
  base_manifest_sha256 = base_verification$manifest_sha256,
  base_input_bundle_sha256 = base_verification$input_bundle_sha256,
  near_eye_participant_days = daily_counts[["glasses"]],
  chest_participant_days = daily_counts[["chest"]],
  qualification = paste0(
    "The current Preparation 06 model-ready layer and METRIC-010 MDER values ",
    "were independently verified. Complete independent reconstruction of the ",
    "exact current state-support classification remains open under ",
    "PREP-003/FIND-044; this is not evidence that stored values are incorrect."
  )
)

h10_write_csv(input_audit, file.path(roots$model_data, "H10_input_audit.csv"))
h10_write_csv(
  provenance_qualification,
  file.path(roots$model_data, "H10_provenance_qualification.csv")
)
h10_write_csv(
  approval_registry,
  file.path(roots$model_data, "H10_author_approvals.csv")
)
h10_write_csv(
  metric_registry,
  file.path(roots$model_data, "H10_metric_registry.csv")
)
h10_write_csv(
  comparison_registry,
  file.path(roots$model_data, "H10_comparison_registry.csv")
)
h10_write_csv(
  run_registry,
  file.path(roots$model_data, "H10_run_registry.csv")
)

####
# Step 2: Build exact H10 model frames from approved prepared rows
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
if (
  anyDuplicated(demographics[c("site", "Id")]) ||
    any(!demographics$biological_sex %in% c("Male", "Female")) ||
    any(!is.finite(demographics$age))
) {
  h10_abort("H10 demographic provenance or coding is not admissible")
}

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

all_rows <- dplyr::bind_rows(
  h10_source_rows(h01_primary, "primary", "all_available"),
  h10_source_rows(h01_gap, "gap_timing_unaware", "all_available")
)
paired_rows <- dplyr::bind_rows(
  h10_source_rows(h01_primary, "primary", "paired_common_sample"),
  h10_source_rows(h01_gap, "gap_timing_unaware", "paired_common_sample")
)
if (
  nrow(all_rows) == 0L ||
    nrow(paired_rows) == 0L ||
    any(is.na(all_rows$age)) ||
    any(is.na(all_rows$biological_sex)) ||
    any(paired_rows$analysis_unit != "participant_day")
) {
  h10_abort("H10 prepared model rows failed demographic or unit checks")
}

h10_write_rds(
  list(
    hypothesis_id = "H10",
    all_available_rows = all_rows,
    paired_common_rows = paired_rows,
    demographics = demographics,
    primary_prepared_metadata = h01_primary$metadata,
    gap_prepared_metadata = h01_gap$metadata,
    provenance_qualification = provenance_qualification
  ),
  file.path(roots$model_data, "H10_approved_prepared_rows.rds")
)

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

model_frames <- list()
model_frame_rows <- list()
for (run_index in seq_len(nrow(run_registry))) {
  run <- run_registry[run_index, , drop = FALSE]
  for (metric_index in seq_len(nrow(metric_registry))) {
    spec <- metric_registry[metric_index, , drop = FALSE]
    source <- all_rows |>
      dplyr::filter(
        .data$data_scenario == run$data_scenario,
        .data$placement == run$placement,
        .data$metric_id == spec$metric_id
      )
    frame <- h10_prepare_model_frame(
      source,
      spec,
      site_levels = site_levels,
      sample_scenario = "all_available"
    )
    key <- paste(run$run_id, spec$metric_id, sep = "__")
    model_frames[[key]] <- frame
    context <- tibble::tibble(
      run_id = run$run_id,
      data_scenario = run$data_scenario,
      placement = run$placement,
      sample_scenario = run$sample_scenario,
      analytical_role = run$analytical_role,
      metric_order = spec$metric_order,
      metric_id = spec$metric_id,
      manuscript_name = spec$manuscript_name,
      analysis_unit = spec$analysis_unit,
      response_family = spec$response_family,
      response_transform = spec$response_transform,
      effect_scale = spec$effect_scale
    )
    model_frame_rows[[key]] <- dplyr::bind_cols(
      context,
      h10_frame_summary(frame)
    )
  }
}
model_frame_index <- dplyr::bind_rows(model_frame_rows) |>
  dplyr::arrange(
    .data$data_scenario,
    .data$placement,
    .data$metric_order
  )
if (
  nrow(model_frame_index) != 68L ||
    any(model_frame_index$observations <= 0L) ||
    any(model_frame_index$sites < 2L)
) {
  h10_abort("H10 all-available model-frame registry is incomplete")
}
h10_write_csv(
  model_frame_index,
  file.path(roots$model_data, "H10_model_frame_index.csv")
)
h10_write_rds(
  model_frames,
  file.path(roots$model_data, "H10_model_frames.rds")
)

demographic_audit <- all_rows |>
  dplyr::filter(.data$data_scenario == "primary") |>
  dplyr::distinct(
    .data$placement,
    .data$site,
    .data$Id,
    .data$age,
    .data$biological_sex,
    .data$employment_status
  ) |>
  dplyr::count(
    .data$placement,
    .data$site,
    .data$biological_sex,
    name = "participants"
  ) |>
  dplyr::left_join(
    all_rows |>
      dplyr::filter(.data$data_scenario == "primary") |>
      dplyr::distinct(
        .data$placement,
        .data$site,
        .data$Id,
        .data$age
      ) |>
      dplyr::group_by(.data$placement, .data$site) |>
      dplyr::summarise(
        age_min = min(.data$age),
        age_median = stats::median(.data$age),
        age_max = max(.data$age),
        .groups = "drop"
      ),
    by = c("placement", "site"),
    relationship = "many-to-one"
  )
h10_write_csv(
  demographic_audit,
  file.path(roots$model_data, "H10_demographic_coding_and_site_cells.csv")
)

####
# Step 3: Fit the approved all-available model family
####

h10_add_age_per_year <- function(effect, spec) {
  if (effect$predictor != "age") {
    return(
      effect |>
        dplyr::mutate(
          estimate_practical_per_year = NA_real_,
          conf_low_practical_per_year = NA_real_,
          conf_high_practical_per_year = NA_real_
        )
    )
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

model_bundles <- list()
model_manifest_rows <- list()
model_test_rows <- list()
model_effect_rows <- list()
site_effect_rows <- list()
diagnostic_rows <- list()
diagnostic_plot_rows <- list()
influence_rows <- list()

for (run_index in seq_len(nrow(run_registry))) {
  run <- run_registry[run_index, , drop = FALSE]
  for (metric_index in seq_len(nrow(metric_registry))) {
    spec <- metric_registry[metric_index, , drop = FALSE]
    key <- paste(run$run_id, spec$metric_id, sep = "__")
    frame <- model_frames[[key]]
    message("H10 fit: ", run$run_id, " / ", spec$metric_id)
    bundle <- h10_fit_bundle(frame, spec)
    model_bundles[[key]] <- bundle
    context <- tibble::tibble(
      run_id = run$run_id,
      data_scenario = run$data_scenario,
      placement = run$placement,
      sample_scenario = run$sample_scenario,
      analytical_role = run$analytical_role,
      metric_order = spec$metric_order,
      metric_id = spec$metric_id,
      manuscript_name = spec$manuscript_name,
      abbreviation = spec$abbreviation,
      manuscript_category = spec$manuscript_category,
      analysis_unit = spec$analysis_unit,
      response_family = spec$response_family,
      response_transform = spec$response_transform,
      effect_scale = spec$effect_scale,
      display_unit = spec$display_unit
    )
    manifest <- h10_model_manifest_rows(bundle)
    model_manifest_rows[[key]] <- dplyr::bind_cols(
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
    model_test_rows[[key]] <- dplyr::bind_cols(
      context[rep(1L, nrow(tests)), , drop = FALSE],
      tests
    )
    for (predictor in c("age", "biological_sex")) {
      effect <- h10_effect_row(bundle, frame, predictor, spec)
      effect_key <- paste(key, predictor, sep = "__")
      model_effect_rows[[effect_key]] <- dplyr::bind_cols(context, effect)
      interaction_name <- if (predictor == "age") {
        "M_age_site"
      } else {
        "M_sex_site"
      }
      site_effect <- h10_site_effects(
        bundle$final_fits[[interaction_name]]$model,
        frame,
        predictor,
        spec
      )
      site_effect_rows[[effect_key]] <- dplyr::bind_cols(
        context[rep(1L, nrow(site_effect)), , drop = FALSE],
        site_effect
      )
      diagnostic <- h10_model_diagnostics(
        bundle$final_fits[[if (predictor == "age") "M_age" else "M_sex"]],
        frame,
        spec
      )
      diagnostic_rows[[effect_key]] <- dplyr::bind_cols(
        context,
        tibble::tibble(predictor = predictor),
        diagnostic
      )
      if (run$data_scenario == "primary") {
        plot_data <- h10_diagnostic_plot_data(
          bundle$final_fits[[
            if (predictor == "age") "M_age" else "M_sex"
          ]]$model,
          frame
        )
        diagnostic_plot_rows[[effect_key]] <- dplyr::bind_cols(
          context[rep(1L, nrow(plot_data)), , drop = FALSE],
          tibble::tibble(predictor = predictor)[
            rep(1L, nrow(plot_data)),
            ,
            drop = FALSE
          ],
          plot_data
        )
        influence <- h10_delete_participant_influence(
          bundle$final_fits[[
            if (predictor == "age") "M_age" else "M_sex"
          ]]$model,
          frame,
          spec,
          predictor,
          effect
        )
        influence_rows[[effect_key]] <- dplyr::bind_cols(
          context,
          tibble::tibble(predictor = predictor),
          influence
        )
      }
    }
  }
}

model_manifest <- dplyr::bind_rows(model_manifest_rows) |>
  dplyr::arrange(
    .data$data_scenario,
    .data$placement,
    .data$metric_order,
    .data$fit_role,
    .data$model_name
  )
model_tests <- dplyr::bind_rows(model_test_rows) |>
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
    ),
    p_adjusted = NA_real_
  )
for (family_id in unique(model_tests$family_id)) {
  rows <- which(model_tests$family_id == family_id)
  if (length(rows) != 17L || any(model_tests$planned_n[rows] != 17L)) {
    h10_abort(
      "Multiplicity family `%s` is not a complete 17-member family",
      family_id
    )
  }
  model_tests$p_adjusted[rows] <- adjust_p_family(
    model_tests$p_raw[rows],
    method = "BH",
    n = 17L
  )
}
model_tests <- model_tests |>
  dplyr::mutate(
    raw_significant = is.finite(.data$p_raw) & .data$p_raw <= 0.05,
    adjusted_significant = is.finite(.data$p_adjusted) &
      .data$p_adjusted <= 0.05,
    p_raw_display = nh_format_p_value(.data$p_raw),
    p_adjusted_display = nh_format_p_value(.data$p_adjusted)
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
if (
  any(
    !family_audit$complete_17_member_family |
      !family_audit$independent_recalculation_matches
  )
) {
  h10_abort("An H10 multiplicity family failed independent verification")
}

model_effects <- dplyr::bind_rows(model_effect_rows) |>
  dplyr::arrange(
    .data$data_scenario,
    .data$placement,
    .data$predictor,
    .data$metric_order
  )
site_effects <- dplyr::bind_rows(site_effect_rows) |>
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
  ) |>
  dplyr::arrange(
    .data$data_scenario,
    .data$placement,
    .data$predictor,
    .data$metric_order,
    .data$weighting,
    .data$site_display_order
  )
model_diagnostics <- dplyr::bind_rows(diagnostic_rows) |>
  dplyr::arrange(
    .data$data_scenario,
    .data$placement,
    .data$predictor,
    .data$metric_order
  )
diagnostic_plot_data <- dplyr::bind_rows(diagnostic_plot_rows)
participant_influence <- dplyr::bind_rows(influence_rows)

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
h10_write_csv(
  model_manifest,
  file.path(roots$models, "H10_model_manifest.csv")
)
h10_write_csv(model_tests, file.path(roots$tables, "H10_model_tests.csv"))
h10_write_csv(
  family_audit,
  file.path(roots$tables, "H10_multiplicity_family_audit.csv")
)
h10_write_csv(
  model_effects,
  file.path(roots$tables, "H10_model_effects.csv")
)
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

####
# Step 4: Run approved placement, dataset, and preregistration sensitivities
####

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
  final <- if (
    spec$response_family == "gaussian" &&
      spec$analysis_unit == "participant_day"
  ) {
    h10_fit_model(
      frame,
      formulas[[formula_name]],
      spec,
      reml = TRUE
    )
  } else {
    full_ml
  }
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

h10_adjust_sensitivity_families <- function(data, family_columns) {
  data$p_adjusted <- NA_real_
  groups <- interaction(data[family_columns], drop = TRUE, lex.order = TRUE)
  for (group in unique(groups)) {
    rows <- which(groups == group)
    if (length(rows) != 17L) {
      h10_abort("An H10 sensitivity family is not a 17-row registry")
    }
    data$p_adjusted[rows] <- adjust_p_family(
      data$p_raw[rows],
      method = "BH",
      n = 17L
    )
  }
  data |>
    dplyr::mutate(
      raw_significant = is.finite(.data$p_raw) & .data$p_raw <= 0.05,
      adjusted_significant = is.finite(.data$p_adjusted) &
        .data$p_adjusted <= 0.05,
      p_raw_display = nh_format_p_value(.data$p_raw),
      p_adjusted_display = nh_format_p_value(.data$p_adjusted)
    )
}

# Exact paired participant-day frames. Participant-level IS and IV are retained
# as explicit unavailable registry rows and are never approximated.
paired_summary_rows <- list()
paired_model_objects <- list()
paired_frame_audit_rows <- list()
for (data_scenario in c("primary", "gap_timing_unaware")) {
  for (metric_index in seq_len(nrow(metric_registry))) {
    spec <- metric_registry[metric_index, , drop = FALSE]
    if (spec$analysis_unit == "participant") {
      for (placement in c("glasses", "chest")) {
        for (predictor in c("age", "biological_sex")) {
          key <- paste(
            "paired",
            data_scenario,
            placement,
            spec$metric_id,
            predictor,
            sep = "__"
          )
          paired_summary_rows[[key]] <- tibble::tibble(
            data_scenario = data_scenario,
            placement = placement,
            sample_scenario = "paired_common_sample",
            metric_order = spec$metric_order,
            metric_id = spec$metric_id,
            manuscript_name = spec$manuscript_name,
            abbreviation = spec$abbreviation,
            predictor = predictor,
            comparison_status = "UNAVAILABLE",
            p_raw = NA_real_,
            observations = NA_integer_,
            participants = NA_integer_,
            participant_days = NA_integer_,
            unavailable_reason = paste0(
              "No current artifact recomputes participant-level IS or IV on ",
              "identical paired participant-day sets; no approximation was made"
            )
          )
        }
      }
      next
    }
    metric_rows <- paired_rows |>
      dplyr::filter(
        .data$data_scenario == .env$data_scenario,
        .data$metric_id == spec$metric_id
      )
    placement_keys <- lapply(c("glasses", "chest"), function(placement) {
      rows <- metric_rows |>
        dplyr::filter(.data$placement == .env$placement)
      sort(unique(h10_common_key(rows, spec$analysis_unit)))
    })
    if (!identical(placement_keys[[1L]], placement_keys[[2L]])) {
      h10_abort(
        "Paired H10 keys differ between placements for `%s` / `%s`",
        data_scenario,
        spec$metric_id
      )
    }
    paired_frame_audit_rows[[paste(data_scenario, spec$metric_id)]] <-
      tibble::tibble(
        data_scenario = data_scenario,
        metric_order = spec$metric_order,
        metric_id = spec$metric_id,
        paired_keys = length(placement_keys[[1L]]),
        paired_key_sha256 = digest::digest(
          placement_keys[[1L]],
          algo = "sha256",
          serialize = TRUE
        ),
        exact_key_match = TRUE
      )
    for (placement in c("glasses", "chest")) {
      source <- metric_rows |>
        dplyr::filter(.data$placement == .env$placement)
      frame <- h10_prepare_model_frame(
        source,
        spec,
        site_levels = site_levels,
        sample_scenario = "paired_common_sample"
      )
      for (predictor in c("age", "biological_sex")) {
        key <- paste(
          "paired",
          data_scenario,
          placement,
          spec$metric_id,
          predictor,
          sep = "__"
        )
        fit <- h10_fit_main_sensitivity(frame, spec, predictor)
        paired_summary_rows[[key]] <- dplyr::bind_cols(
          tibble::tibble(
            data_scenario = data_scenario,
            placement = placement,
            sample_scenario = "paired_common_sample",
            metric_order = spec$metric_order,
            metric_id = spec$metric_id,
            manuscript_name = spec$manuscript_name,
            abbreviation = spec$abbreviation,
            unavailable_reason = NA_character_
          ),
          fit$summary
        )
        paired_model_objects[[key]] <- fit$models
      }
    }
  }
}
paired_results <- dplyr::bind_rows(paired_summary_rows) |>
  h10_adjust_sensitivity_families(
    c("data_scenario", "placement", "predictor")
  ) |>
  dplyr::arrange(
    .data$data_scenario,
    .data$placement,
    .data$predictor,
    .data$metric_order
  )
paired_frame_audit <- dplyr::bind_rows(paired_frame_audit_rows) |>
  dplyr::arrange(.data$data_scenario, .data$metric_order)

# The primary and gap-timing-unaware datasets are also fitted on identical
# within-placement keys so that changes in values are separated from sample
# changes.
gap_common_summary_rows <- list()
gap_common_model_objects <- list()
gap_common_audit_rows <- list()
for (placement in c("glasses", "chest")) {
  for (metric_index in seq_len(nrow(metric_registry))) {
    spec <- metric_registry[metric_index, , drop = FALSE]
    primary_source <- all_rows |>
      dplyr::filter(
        .data$data_scenario == "primary",
        .data$placement == .env$placement,
        .data$metric_id == spec$metric_id
      )
    gap_source <- all_rows |>
      dplyr::filter(
        .data$data_scenario == "gap_timing_unaware",
        .data$placement == .env$placement,
        .data$metric_id == spec$metric_id
      )
    common_keys <- intersect(
      h10_common_key(primary_source, spec$analysis_unit),
      h10_common_key(gap_source, spec$analysis_unit)
    )
    primary_common <- primary_source[
      h10_common_key(primary_source, spec$analysis_unit) %in% common_keys,
      ,
      drop = FALSE
    ]
    gap_common <- gap_source[
      h10_common_key(gap_source, spec$analysis_unit) %in% common_keys,
      ,
      drop = FALSE
    ]
    primary_hash <- digest::digest(
      sort(h10_common_key(primary_common, spec$analysis_unit)),
      algo = "sha256",
      serialize = TRUE
    )
    gap_hash <- digest::digest(
      sort(h10_common_key(gap_common, spec$analysis_unit)),
      algo = "sha256",
      serialize = TRUE
    )
    if (
      nrow(primary_common) != nrow(gap_common) ||
        primary_hash != gap_hash
    ) {
      h10_abort(
        "Primary--gap common keys differ for `%s` / `%s`",
        placement,
        spec$metric_id
      )
    }
    gap_common_audit_rows[[paste(placement, spec$metric_id)]] <-
      tibble::tibble(
        placement = placement,
        metric_order = spec$metric_order,
        metric_id = spec$metric_id,
        common_observations = length(common_keys),
        primary_key_sha256 = primary_hash,
        gap_key_sha256 = gap_hash,
        exact_key_match = primary_hash == gap_hash
      )
    for (data_scenario in c("primary", "gap_timing_unaware")) {
      source <- if (data_scenario == "primary") {
        primary_common
      } else {
        gap_common
      }
      frame <- h10_prepare_model_frame(
        source,
        spec,
        site_levels = site_levels,
        sample_scenario = "primary_gap_common_sample"
      )
      for (predictor in c("age", "biological_sex")) {
        key <- paste(
          "gap_common",
          data_scenario,
          placement,
          spec$metric_id,
          predictor,
          sep = "__"
        )
        fit <- h10_fit_main_sensitivity(frame, spec, predictor)
        gap_common_summary_rows[[key]] <- dplyr::bind_cols(
          tibble::tibble(
            data_scenario = data_scenario,
            placement = placement,
            sample_scenario = "primary_gap_common_sample",
            metric_order = spec$metric_order,
            metric_id = spec$metric_id,
            manuscript_name = spec$manuscript_name,
            abbreviation = spec$abbreviation
          ),
          fit$summary
        )
        gap_common_model_objects[[key]] <- fit$models
      }
    }
  }
}
gap_common_results <- dplyr::bind_rows(gap_common_summary_rows) |>
  h10_adjust_sensitivity_families(
    c("data_scenario", "placement", "predictor")
  ) |>
  dplyr::arrange(
    .data$data_scenario,
    .data$placement,
    .data$predictor,
    .data$metric_order
  )
gap_common_audit <- dplyr::bind_rows(gap_common_audit_rows) |>
  dplyr::arrange(.data$placement, .data$metric_order)

# Documented preregistration-exclusion sensitivity: age above 65, not employed,
# or marginally employed. Students and trainees are not removed solely for that
# status.
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
  h10_abort("The documented H10 preregistration exclusions are not nine people")
}
prereg_summary_rows <- list()
prereg_model_objects <- list()
for (placement in c("glasses", "chest")) {
  for (metric_index in seq_len(nrow(metric_registry))) {
    spec <- metric_registry[metric_index, , drop = FALSE]
    source <- all_rows |>
      dplyr::filter(
        .data$data_scenario == "primary",
        .data$placement == .env$placement,
        .data$metric_id == spec$metric_id
      ) |>
      dplyr::anti_join(
        prereg_exclusion_ids |>
          dplyr::select(.data$site, .data$Id),
        by = c("site", "Id")
      )
    frame <- h10_prepare_model_frame(
      source,
      spec,
      site_levels = site_levels,
      sample_scenario = "preregistered_exclusions_applied"
    )
    for (predictor in c("age", "biological_sex")) {
      key <- paste(
        "prereg",
        placement,
        spec$metric_id,
        predictor,
        sep = "__"
      )
      fit <- h10_fit_main_sensitivity(frame, spec, predictor)
      prereg_summary_rows[[key]] <- dplyr::bind_cols(
        tibble::tibble(
          data_scenario = "primary",
          placement = placement,
          sample_scenario = "preregistered_exclusions_applied",
          metric_order = spec$metric_order,
          metric_id = spec$metric_id,
          manuscript_name = spec$manuscript_name,
          abbreviation = spec$abbreviation
        ),
        fit$summary
      )
      prereg_model_objects[[key]] <- fit$models
    }
  }
}
prereg_results <- dplyr::bind_rows(prereg_summary_rows) |>
  h10_adjust_sensitivity_families(c("placement", "predictor")) |>
  dplyr::arrange(.data$placement, .data$predictor, .data$metric_order)

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
h10_write_csv(
  prereg_exclusion_ids,
  file.path(roots$model_data, "H10_preregistered_exclusion_participants.csv")
)
h10_write_csv(
  prereg_results,
  file.path(roots$sensitivity, "H10_preregistered_exclusion_effects.csv")
)
h10_write_rds(
  list(
    hypothesis_id = "H10",
    paired_placement_models = paired_model_objects,
    primary_gap_common_models = gap_common_model_objects,
    preregistered_exclusion_models = prereg_model_objects,
    provenance_qualification = provenance_qualification
  ),
  file.path(roots$models, "H10_sample_sensitivity_models.rds")
)

####
# Step 5: Declared metric-specific sensitivities
####

h10_fit_variant <- function(
  source,
  spec,
  placement,
  sensitivity_id,
  transform_variant = "primary"
) {
  frame <- h10_prepare_model_frame(
    source,
    spec,
    site_levels = site_levels,
    sample_scenario = sensitivity_id,
    transform_variant = transform_variant
  )
  rows <- list()
  models <- list()
  for (predictor in c("age", "biological_sex")) {
    fit <- h10_fit_main_sensitivity(frame, spec, predictor)
    rows[[predictor]] <- dplyr::bind_cols(
      tibble::tibble(
        sensitivity_id = sensitivity_id,
        placement = placement,
        metric_order = spec$metric_order,
        metric_id = spec$metric_id,
        manuscript_name = spec$manuscript_name,
        abbreviation = spec$abbreviation
      ),
      fit$summary
    )
    models[[predictor]] <- fit$models
  }
  list(summary = dplyr::bind_rows(rows), models = models)
}

metric_sensitivity_rows <- list()
metric_sensitivity_models <- list()

for (placement in c("glasses", "chest")) {
  daily <- readRDS(file.path(
    root,
    "artifacts/06_model_data/base",
    paste0("metrics_", placement, "_participant_day_enriched.rds")
  ))

  # Exactly identified longest-period values only.
  longest_spec <- metric_registry |>
    dplyr::filter(.data$metric_id == "longest_bout_above_250")
  exact_values <- daily |>
    dplyr::filter(
      .data$longest_bout_above_250_exact_identifiable,
      is.finite(.data$longest_bout_above_250_exact_only_sensitivity_h)
    ) |>
    dplyr::transmute(
      .data$site,
      .data$Id,
      local_date = as.Date(.data$local_date),
      exact_value = .data$longest_bout_above_250_exact_only_sensitivity_h
    )
  exact_source <- all_rows |>
    dplyr::filter(
      .data$data_scenario == "primary",
      .data$placement == .env$placement,
      .data$metric_id == "longest_bout_above_250"
    ) |>
    dplyr::inner_join(
      exact_values,
      by = c("site", "Id", "local_date"),
      relationship = "one-to-one"
    ) |>
    dplyr::mutate(value = .data$exact_value) |>
    dplyr::select(-.data$exact_value)
  exact_fit <- h10_fit_variant(
    exact_source,
    longest_spec,
    placement,
    "exactly_identified_longest_period"
  )
  metric_sensitivity_rows[[paste(placement, "exact")]] <- exact_fit$summary
  metric_sensitivity_models[[paste(placement, "exact")]] <- exact_fit$models

  # L10 midnight unwrap at noon rather than 16:00, on the same rows.
  l10_spec <- metric_registry |>
    dplyr::filter(.data$metric_id == "l10_midpoint")
  l10_source <- all_rows |>
    dplyr::filter(
      .data$data_scenario == "primary",
      .data$placement == .env$placement,
      .data$metric_id == "l10_midpoint"
    )
  l10_fit <- h10_fit_variant(
    l10_source,
    l10_spec,
    placement,
    "l10_midnight_unwrap_noon",
    transform_variant = "l10_noon"
  )
  metric_sensitivity_rows[[paste(placement, "l10_noon")]] <- l10_fit$summary
  metric_sensitivity_models[[paste(placement, "l10_noon")]] <- l10_fit$models

}

metric_sensitivities <- dplyr::bind_rows(metric_sensitivity_rows) |>
  dplyr::mutate(
    p_raw_display = nh_format_p_value(.data$p_raw),
    inferential_role = "declared sensitivity; no new multiplicity decision"
  ) |>
  dplyr::arrange(
    .data$sensitivity_id,
    .data$placement,
    .data$predictor
  )
waking_mder_unavailable <- tibble::tibble(
  sensitivity_id = "waking_only_mder",
  placement = c("glasses", "chest"),
  metric_id = "mder_mean_of_viable_ratios",
  status = "UNAVAILABLE",
  reason = paste0(
    "No approved current artifact derives waking-only MDER; upstream ",
    "recomputation was not authorized, so H10 did not approximate it"
  )
)
h10_write_csv(
  metric_sensitivities,
  file.path(roots$sensitivity, "H10_metric_specific_sensitivities.csv")
)
h10_write_csv(
  waking_mder_unavailable,
  file.path(roots$sensitivity, "H10_waking_mder_unavailable.csv")
)
h10_write_rds(
  list(
    hypothesis_id = "H10",
    metric_sensitivity_models = metric_sensitivity_models,
    waking_mder_status = waking_mder_unavailable,
    provenance_qualification = provenance_qualification
  ),
  file.path(roots$models, "H10_metric_sensitivity_models.rds")
)

####
# Step 6: Leave-one-site-out temporal/site influence audit
####

loso_rows <- list()
for (placement in c("glasses", "chest")) {
  run_id <- paste("primary", placement, "all_available", sep = "__")
  for (metric_index in seq_len(nrow(metric_registry))) {
    spec <- metric_registry[metric_index, , drop = FALSE]
    frame <- model_frames[[paste(run_id, spec$metric_id, sep = "__")]]
    for (predictor in c("age", "biological_sex")) {
      for (omitted_site in site_levels) {
        key <- paste(
          placement,
          spec$metric_id,
          predictor,
          omitted_site,
          sep = "__"
        )
        refit <- h10_loso_refit(frame, spec, predictor, omitted_site)
        loso_rows[[key]] <- dplyr::bind_cols(
          tibble::tibble(
            placement = placement,
            metric_order = spec$metric_order,
            metric_id = spec$metric_id,
            manuscript_name = spec$manuscript_name,
            abbreviation = spec$abbreviation,
            omitted_site_present = omitted_site %in% levels(frame$site)
          ),
          refit
        )
      }
    }
  }
}
leave_one_site_out <- dplyr::bind_rows(loso_rows) |>
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
leave_one_site_out$p_adjusted <- NA_real_
loso_groups <- interaction(
  leave_one_site_out[c("placement", "predictor", "omitted_site")],
  drop = TRUE,
  lex.order = TRUE
)
for (group in unique(loso_groups)) {
  rows <- which(loso_groups == group)
  if (length(rows) != 17L) {
    h10_abort("An H10 leave-one-site-out family is not 17 metrics")
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
      .data$omitted_site[
        which.max(dplyr::coalesce(
          .data$change_in_full_standard_errors,
          -Inf
        ))
      ]
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

# Integrate influence evidence into the explicit diagnostic assessment.
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
      "placement",
      "predictor",
      "metric_order",
      "metric_id",
      "manuscript_name",
      "abbreviation"
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

####
# Step 7: Reconstruct the frozen V0 displays and compare conclusions
####

h10_v0_crosswalk <- tibble::tribble(
  ~metric_order,
  ~v0_name,
  ~metric_id,
  1L,
  "interdaily_stability",
  "interdaily_stability",
  2L,
  "intradaily_variability",
  "intradaily_variability",
  3L,
  "Mean",
  "daily_geometric_mean_medi",
  4L,
  "brightest_10h_mean",
  "m10_mean_medi",
  5L,
  "darkest_10h_mean",
  "l10_mean_medi",
  6L,
  "duration_above_1000",
  "duration_above_1000",
  7L,
  "duration_above_250_wake",
  "duration_above_250_wake",
  8L,
  "duration_below_10_pre-sleep",
  "duration_below_10_pre_sleep",
  9L,
  "duration_below_1_sleep",
  "duration_below_1_sleep_environment",
  10L,
  "period_above_250",
  "longest_bout_above_250",
  11L,
  "brightest_10h_midpoint",
  "m10_midpoint",
  12L,
  "darkest_10h_midpoint",
  "l10_midpoint",
  13L,
  "mean_timing_above_250",
  "mean_timing_above_250",
  14L,
  "first_timing_above_250",
  "first_timing_above_250",
  15L,
  "last_timing_above_250",
  "last_timing_above_250",
  16L,
  "dose",
  "dose_time_sensitive_corrected_medi",
  17L,
  "MDER",
  "mder_mean_of_viable_ratios"
)

h10_load_v0_metrics <- function(path) {
  environment <- new.env(parent = emptyenv())
  object_names <- load(path, envir = environment)
  if (length(object_names) != 1L) {
    h10_abort("Unexpected number of V0 objects in `%s`", path)
  }
  object <- environment[[object_names[[1L]]]]
  if (
    !is.data.frame(object) ||
      !all(c("name", "data", "metric_type") %in% names(object))
  ) {
    h10_abort("Unexpected V0 metric object in `%s`", path)
  }
  object
}

h10_v0_rows <- function(path, placement) {
  object <- h10_load_v0_metrics(path) |>
    dplyr::inner_join(
      h10_v0_crosswalk,
      by = c("name" = "v0_name"),
      relationship = "one-to-one"
    ) |>
    dplyr::arrange(.data$metric_order)
  if (nrow(object) != 17L) {
    h10_abort(
      "The frozen V0 `%s` object does not contain 17 H10 metrics",
      placement
    )
  }
  purrr::map_dfr(seq_len(nrow(object)), function(index) {
    source <- object$data[[index]]
    tibble::tibble(
      placement = placement,
      metric_order = object$metric_order[[index]],
      metric_id = object$metric_id[[index]],
      v0_name = object$name[[index]],
      metric_type = object$metric_type[[index]],
      site = as.character(source$site),
      Id = as.character(source$Id),
      local_date = if ("Date" %in% names(source)) {
        as.Date(source$Date)
      } else {
        as.Date(NA)
      },
      age = as.numeric(source$age),
      biological_sex = as.character(source$sex),
      metric_value = as.numeric(source$metric)
    )
  })
}

v0_rows <- dplyr::bind_rows(
  h10_v0_rows(
    file.path(root, "data/metrics_glasses.RData"),
    "glasses"
  ),
  h10_v0_rows(
    file.path(root, "data/metrics_chest.RData"),
    "chest"
  )
)
h10_write_csv(
  v0_rows,
  file.path(roots$model_data, "H10_v0_display_rows.csv")
)

h10_extract_v0_tables <- function(path, placement) {
  document <- rvest::read_html(path)
  tables <- rvest::html_elements(document, "table")
  titles <- vapply(
    tables,
    function(table) {
      paste(
        rvest::html_text2(rvest::html_elements(table, ".gt_title")),
        collapse = " "
      )
    },
    character(1)
  )
  overall_index <- which(titles == "H10: Overall model results")
  selected_index <- which(titles == "H10: Model results")
  if (length(overall_index) != 1L || length(selected_index) != 1L) {
    h10_abort("Could not uniquely identify frozen H10 V0 tables in `%s`", path)
  }
  overall_raw <- rvest::html_table(tables[[overall_index]], fill = TRUE)
  overall <- overall_raw[4:20, 1:5, drop = FALSE]
  names(overall) <- c(
    "metric_type",
    "v0_name",
    "displayed_sex_adjusted_p",
    "displayed_age_adjusted_p",
    "displayed_age_site_adjusted_p"
  )
  overall <- tibble::as_tibble(overall) |>
    dplyr::mutate(placement = placement, .before = 1L) |>
    dplyr::left_join(
      h10_v0_crosswalk,
      by = "v0_name",
      relationship = "one-to-one"
    ) |>
    dplyr::arrange(.data$metric_order)
  selected_raw <- rvest::html_table(tables[[selected_index]], fill = TRUE)
  selected <- selected_raw[
    4:(nrow(selected_raw) - 1L),
    ,
    drop = FALSE
  ]
  names(selected) <- paste0("column_", seq_len(ncol(selected)))
  selected <- tibble::as_tibble(selected) |>
    dplyr::mutate(
      placement = placement,
      frozen_row_order = dplyr::row_number(),
      .before = 1L
    )
  list(overall = overall, selected = selected)
}

v0_near_tables <- h10_extract_v0_tables(
  file.path(root, "docs/RQ3.html"),
  "glasses"
)
v0_chest_tables <- h10_extract_v0_tables(
  file.path(root, "docs/RQ3_chest.html"),
  "chest"
)
v0_overall <- dplyr::bind_rows(
  v0_near_tables$overall,
  v0_chest_tables$overall
)
h10_write_csv(
  v0_overall,
  file.path(roots$tables, "H10_v0_overall_results_recreated.csv")
)
h10_write_csv(
  v0_near_tables$selected,
  file.path(roots$tables, "H10_v0_near_eye_selected_table_recreated.csv")
)
h10_write_csv(
  v0_chest_tables$selected,
  file.path(roots$tables, "H10_v0_chest_selected_table_recreated.csv")
)

v0_overall_gt <- v0_overall |>
  dplyr::mutate(
    placement = dplyr::if_else(
      .data$placement == "glasses",
      "Near eye",
      "Chest"
    )
  ) |>
  dplyr::select(
    .data$placement,
    .data$metric_type,
    metric = .data$v0_name,
    sex = .data$displayed_sex_adjusted_p,
    age = .data$displayed_age_adjusted_p,
    age_by_site = .data$displayed_age_site_adjusted_p
  ) |>
  gt::gt(groupname_col = "placement") |>
  gt::tab_header(
    title = "H10: Overall model results",
    subtitle = "Frozen V0 render transcribed without reinterpretation"
  ) |>
  gt::cols_label(
    metric_type = "Type",
    metric = "Metric",
    sex = "Sex p",
    age = "Age p",
    age_by_site = "Age × site p"
  ) |>
  gt::tab_source_note(
    gt::md(
      "V0 displayed scalar FDR adjustments with `n = 34`; values are preserved exactly as rendered."
    )
  )
options(sass.cache = file.path(tempdir(), "H10-sass-cache"))
gt::gtsave(
  v0_overall_gt,
  file.path(roots$tables, "H10_v0_overall_results_recreated.html")
)

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
    v0_multiplicity_implementation = paste0(
      "Scalar p.adjust call per p-value with FDR and n=34"
    ),
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
h10_write_csv(
  v0_comparisons,
  file.path(roots$tables, "H10_v0_to_current_comparison.csv")
)

v0_sex_site_unavailable <- tibble::tibble(
  placement = c("glasses", "chest"),
  comparison_id = "SEX-SITE",
  v0_status = "NOT_COMPARED_OR_REPORTED",
  explanation = paste0(
    "V0 fitted sex-by-site models but did not create the corresponding ",
    "nested comparison or report a multiplicity decision"
  )
)
h10_write_csv(
  v0_sex_site_unavailable,
  file.path(roots$tables, "H10_v0_sex_site_comparison_unavailable.csv")
)

####
# Step 8: Build compact result tables and paired figure source data
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
h10_write_csv(
  primary_results,
  file.path(roots$tables, "H10_primary_main_results.csv")
)

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
h10_write_csv(
  primary_interactions,
  file.path(roots$tables, "H10_primary_interaction_results.csv")
)

# Cross-scenario stability table on the model scale.
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
h10_write_csv(
  sensitivity_stability,
  file.path(roots$sensitivity, "H10_sensitivity_stability_summary.csv")
)

# Frozen V0 figure source and correction. The original pooled linear smoother
# is reconstructed explicitly, including its 95% confidence ribbon.
v0_figure_sources <- list()
for (placement in c("glasses", "chest")) {
  scatter <- v0_rows |>
    dplyr::filter(
      .data$placement == .env$placement,
      .data$metric_id == "duration_above_1000",
      is.finite(.data$age),
      is.finite(.data$metric_value)
    ) |>
    dplyr::mutate(source_role = "tat1000_observation")
  pooled_lm <- stats::lm(metric_value ~ age, data = scatter)
  prediction_grid <- tibble::tibble(
    age = seq(min(scatter$age), max(scatter$age), length.out = 100L)
  )
  prediction <- stats::predict(
    pooled_lm,
    newdata = prediction_grid,
    interval = "confidence",
    level = 0.95
  )
  line <- tibble::tibble(
    placement = placement,
    metric_order = 6L,
    metric_id = "duration_above_1000",
    v0_name = "duration_above_1000",
    metric_type = "duration",
    site = NA_character_,
    Id = NA_character_,
    local_date = as.Date(NA),
    age = prediction_grid$age,
    biological_sex = NA_character_,
    metric_value = prediction[, "fit"],
    conf_low = prediction[, "lwr"],
    conf_high = prediction[, "upr"],
    source_role = "tat1000_pooled_lm"
  )
  site_age <- v0_rows |>
    dplyr::filter(
      .data$placement == .env$placement,
      .data$metric_id != "last_timing_above_250",
      is.finite(.data$age)
    ) |>
    dplyr::mutate(
      metric_value = NA_real_,
      source_role = "site_age_repeated_observation"
    )
  v0_figure_sources[[placement]] <- dplyr::bind_rows(
    scatter |>
      dplyr::mutate(conf_low = NA_real_, conf_high = NA_real_),
    line,
    site_age |>
      dplyr::mutate(conf_low = NA_real_, conf_high = NA_real_)
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
}
v0_figure_source <- dplyr::bind_rows(v0_figure_sources)
h10_write_csv(
  v0_figure_source,
  file.path(roots$source_data, "H10_v0_figure_recreated_data.csv")
)
h10_write_csv(
  v0_figure_source |>
    dplyr::mutate(
      display_correction = paste0(
        "Y-axis label corrected from local time to duration in hours; ",
        "data and pooled V0 smoother unchanged"
      )
    ),
  file.path(roots$source_data, "H10_v0_figure_corrected_data.csv")
)

h10_save_v0_figure <- function(data, placement, corrected = FALSE) {
  label <- if (placement == "glasses") "Near eye" else "Chest"
  scatter <- data |>
    dplyr::filter(
      .data$placement == .env$placement,
      .data$source_role == "tat1000_observation"
    ) |>
    dplyr::mutate(
      site_display_name = factor(
        .data$site_display_name,
        levels = site_registry$display_name
      )
    )
  line <- data |>
    dplyr::filter(
      .data$placement == .env$placement,
      .data$source_role == "tat1000_pooled_lm"
    )
  site_age <- data |>
    dplyr::filter(
      .data$placement == .env$placement,
      .data$source_role == "site_age_repeated_observation"
    ) |>
    dplyr::mutate(
      site_display_name = factor(
        .data$site_display_name,
        levels = rev(site_registry$display_name)
      )
    )
  p1 <- ggplot2::ggplot(
    scatter,
    ggplot2::aes(
      x = .data$age,
      y = .data$metric_value,
      colour = .data$site_display_name
    )
  ) +
    ggplot2::geom_point(alpha = 0.5, size = 1.1) +
    ggplot2::geom_ribbon(
      data = line,
      ggplot2::aes(
        x = .data$age,
        ymin = .data$conf_low,
        ymax = .data$conf_high
      ),
      inherit.aes = FALSE,
      fill = "grey70",
      alpha = 0.35
    ) +
    ggplot2::geom_line(
      data = line,
      ggplot2::aes(x = .data$age, y = .data$metric_value),
      inherit.aes = FALSE,
      colour = "black",
      linewidth = 0.8
    ) +
    ggplot2::scale_colour_manual(
      values = stats::setNames(
        site_registry$color_hex,
        site_registry$display_name
      ),
      drop = FALSE
    ) +
    ggplot2::labs(
      title = paste0(label, ": duration above 1,000 lx"),
      x = "Age (years)",
      y = if (corrected) {
        "Time above 1,000 lx melEDI (h)"
      } else {
        "Local time of day (hr)"
      },
      colour = NULL
    ) +
    ggplot2::theme_minimal(base_size = 10) +
    ggplot2::theme(
      legend.position = "none",
      panel.grid.minor = ggplot2::element_blank()
    )
  p2 <- ggplot2::ggplot(
    site_age,
    ggplot2::aes(
      x = .data$age,
      y = .data$site_display_name,
      colour = .data$site_display_name
    )
  ) +
    ggplot2::geom_boxplot(width = 0.65, outlier.size = 0.7) +
    ggplot2::scale_colour_manual(
      values = stats::setNames(
        site_registry$color_hex,
        site_registry$display_name
      ),
      drop = FALSE
    ) +
    ggplot2::labs(title = "Age by site", x = "Age (years)", y = NULL) +
    ggplot2::theme_minimal(base_size = 10) +
    ggplot2::theme(
      legend.position = "none",
      panel.grid.minor = ggplot2::element_blank()
    )
  combined <- p1 +
    p2 +
    patchwork::plot_layout(widths = c(3, 2)) +
    patchwork::plot_annotation(
      title = if (corrected) {
        paste0("Corrected frozen V0 H10 display - ", label)
      } else {
        paste0("Frozen V0 H10 figure recreation - ", label)
      },
      caption = if (corrected) {
        paste0(
          "Only the erroneous duration-panel y-axis label is corrected; ",
          "the pooled V0 smoother and repeated age-by-site rows are retained."
        )
      } else {
        paste0(
          "The erroneous V0 duration-panel y-axis label is intentionally ",
          "preserved here for faithful reconstruction."
        )
      }
    )
  stem <- paste0(
    "H10_v0_",
    placement,
    if (corrected) "_corrected" else "_recreated"
  )
  ggplot2::ggsave(
    file.path(roots$figures, paste0(stem, ".png")),
    combined,
    width = 10,
    height = 5,
    units = "in",
    dpi = 300,
    bg = "white"
  )
  ggplot2::ggsave(
    file.path(roots$figures, paste0(stem, ".pdf")),
    combined,
    width = 10,
    height = 5,
    units = "in",
    bg = "white"
  )
}

for (placement in c("glasses", "chest")) {
  h10_save_v0_figure(v0_figure_source, placement, corrected = FALSE)
  h10_save_v0_figure(v0_figure_source, placement, corrected = TRUE)
}

# Primary standardized-effect plots retain practical estimates and exact sample
# sizes in their paired source CSVs; standardization is display-only.
h10_save_primary_effect_plot <- function(predictor) {
  source <- primary_results |>
    dplyr::filter(.data$predictor == .env$predictor) |>
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
  stem <- if (predictor == "age") {
    "H10_primary_age_associations"
  } else {
    "H10_primary_biological_sex_associations"
  }
  h10_write_csv(
    source,
    file.path(roots$source_data, paste0(stem, "_data.csv"))
  )
  plot <- ggplot2::ggplot(
    source,
    ggplot2::aes(
      x = .data$standardized_estimate,
      y = .data$metric_label,
      xmin = .data$standardized_conf_low,
      xmax = .data$standardized_conf_high,
      colour = .data$placement_label,
      shape = .data$placement_label
    )
  ) +
    ggplot2::geom_vline(xintercept = 0, colour = "grey55", linewidth = 0.5) +
    ggplot2::geom_errorbar(
      orientation = "y",
      position = ggplot2::position_dodge(width = 0.55),
      width = 0.18,
      linewidth = 0.55
    ) +
    ggplot2::geom_point(
      position = ggplot2::position_dodge(width = 0.55),
      size = 2.2,
      stroke = 0.85
    ) +
    ggplot2::scale_colour_manual(
      values = c(
        "Near eye (primary)" = "#0072B2",
        "Chest (complementary)" = "#D55E00"
      )
    ) +
    ggplot2::labs(
      title = if (predictor == "age") {
        "Age associations, adjusted for site"
      } else {
        "Measured biological-sex contrasts, adjusted for site"
      },
      subtitle = if (predictor == "age") {
        "Per 10-year increase; estimates and 95% confidence intervals"
      } else {
        "Female minus Male; estimates and 95% confidence intervals"
      },
      x = "Effect on model scale, divided by the fitted-frame response SD",
      y = NULL,
      colour = NULL,
      shape = NULL,
      caption = paste0(
        "Standardization is for display only; models are separate by placement.\n",
        "Practical-scale estimates, exact denominators, raw p-values, and ",
        "BH-adjusted p-values are retained in the paired source CSV."
      )
    ) +
    ggplot2::theme_minimal(base_size = 10) +
    ggplot2::theme(
      plot.title.position = "plot",
      legend.position = "bottom",
      panel.grid.minor = ggplot2::element_blank(),
      axis.text.y = ggplot2::element_text(size = 8),
      plot.caption = ggplot2::element_text(hjust = 0, size = 7)
    )
  ggplot2::ggsave(
    file.path(roots$figures, paste0(stem, ".png")),
    plot,
    width = 9.4,
    height = 8.5,
    units = "in",
    dpi = 300,
    bg = "white"
  )
  ggplot2::ggsave(
    file.path(roots$figures, paste0(stem, ".pdf")),
    plot,
    width = 9.4,
    height = 8.5,
    units = "in",
    bg = "white"
  )
}

h10_save_primary_effect_plot("age")
h10_save_primary_effect_plot("biological_sex")

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
h10_write_csv(
  paired_plot_source,
  file.path(roots$source_data, "H10_paired_placement_effects_data.csv")
)
paired_plot_data <- paired_plot_source |>
  dplyr::filter(.data$included_in_plot)
paired_limits <- range(
  c(
    paired_plot_data$standardized_conf_low_glasses,
    paired_plot_data$standardized_conf_high_glasses,
    paired_plot_data$standardized_conf_low_chest,
    paired_plot_data$standardized_conf_high_chest
  ),
  finite = TRUE
)
paired_plot <- ggplot2::ggplot(
  paired_plot_data,
  ggplot2::aes(
    x = .data$standardized_estimate_glasses,
    y = .data$standardized_estimate_chest,
    colour = .data$manuscript_category
  )
) +
  ggplot2::geom_abline(
    intercept = 0,
    slope = 1,
    linetype = "dashed",
    colour = "grey45"
  ) +
  ggplot2::geom_vline(xintercept = 0, colour = "grey70") +
  ggplot2::geom_hline(yintercept = 0, colour = "grey70") +
  ggplot2::geom_errorbar(
    ggplot2::aes(
      ymin = .data$standardized_conf_low_chest,
      ymax = .data$standardized_conf_high_chest
    ),
    width = 0,
    linewidth = 0.4
  ) +
  ggplot2::geom_errorbar(
    ggplot2::aes(
      xmin = .data$standardized_conf_low_glasses,
      xmax = .data$standardized_conf_high_glasses
    ),
    orientation = "y",
    width = 0,
    linewidth = 0.4
  ) +
  ggplot2::geom_point(size = 2.5, stroke = 0.85) +
  ggplot2::facet_wrap(ggplot2::vars(.data$predictor_label), nrow = 1) +
  ggplot2::coord_equal(xlim = paired_limits, ylim = paired_limits) +
  ggplot2::labs(
    title = "Placement-matched H10 associations",
    subtitle = paste0(
      "Separate near-eye and chest models on identical participant-days; ",
      "15 estimable participant-day metrics"
    ),
    x = "Near-eye standardized model-scale effect",
    y = "Chest standardized model-scale effect",
    colour = "Metric category",
    caption = paste0(
      "Bars are component 95% confidence intervals; the dashed line marks identical estimates,\n",
      "not an equivalence margin. IS and IV are not ",
      "shown because paired participant-level estimates are unavailable."
    )
  ) +
  ggplot2::theme_minimal(base_size = 10) +
  ggplot2::theme(
    plot.title.position = "plot",
    legend.position = "bottom",
    legend.text = ggplot2::element_text(size = 8),
    panel.grid.minor = ggplot2::element_blank(),
    plot.caption = ggplot2::element_text(hjust = 0, size = 7)
  ) +
  ggplot2::guides(
    colour = ggplot2::guide_legend(nrow = 2, byrow = TRUE)
  )
ggplot2::ggsave(
  file.path(roots$figures, "H10_paired_placement_effects.png"),
  paired_plot,
  width = 9.4,
  height = 5.8,
  units = "in",
  dpi = 300,
  bg = "white"
)
ggplot2::ggsave(
  file.path(roots$figures, "H10_paired_placement_effects.pdf"),
  paired_plot,
  width = 9.4,
  height = 5.8,
  units = "in",
  bg = "white"
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
h10_write_csv(
  gap_plot_source,
  file.path(roots$source_data, "H10_gap_common_sample_effects_data.csv")
)
gap_limits <- range(
  c(
    gap_plot_source$standardized_conf_low_primary,
    gap_plot_source$standardized_conf_high_primary,
    gap_plot_source$standardized_conf_low_gap_timing_unaware,
    gap_plot_source$standardized_conf_high_gap_timing_unaware
  ),
  finite = TRUE
)
gap_plot <- ggplot2::ggplot(
  gap_plot_source,
  ggplot2::aes(
    x = .data$standardized_estimate_primary,
    y = .data$standardized_estimate_gap_timing_unaware,
    colour = .data$placement_label
  )
) +
  ggplot2::geom_abline(
    intercept = 0,
    slope = 1,
    linetype = "dashed",
    colour = "grey45"
  ) +
  ggplot2::geom_vline(xintercept = 0, colour = "grey70") +
  ggplot2::geom_hline(yintercept = 0, colour = "grey70") +
  ggplot2::geom_point(size = 2.5, stroke = 0.85) +
  ggplot2::facet_wrap(ggplot2::vars(.data$predictor_label), nrow = 1) +
  ggplot2::coord_equal(xlim = gap_limits, ylim = gap_limits) +
  ggplot2::scale_colour_manual(
    values = c("Near eye" = "#0072B2", "Chest" = "#D55E00")
  ) +
  ggplot2::labs(
    title = "Primary and gap-timing-unaware H10 associations",
    subtitle = "Identical within-metric samples; standardized model-scale effects",
    x = "Primary dataset effect",
    y = "Gap-timing-unaware dataset effect",
    colour = "Placement",
    caption = paste0(
      "The gap-timing-unaware dataset applies the 50%-per-hour and 80%-per-day ",
      "coverage rules but does not use the remaining gaps' time of day\n",
      "in metric-specific support decisions. The dashed line marks identical estimates."
    )
  ) +
  ggplot2::theme_minimal(base_size = 10) +
  ggplot2::theme(
    plot.title.position = "plot",
    legend.position = "bottom",
    panel.grid.minor = ggplot2::element_blank(),
    plot.caption = ggplot2::element_text(hjust = 0, size = 7)
  )
ggplot2::ggsave(
  file.path(roots$figures, "H10_gap_common_sample_effects.png"),
  gap_plot,
  width = 9.4,
  height = 5.8,
  units = "in",
  dpi = 300,
  bg = "white"
)
ggplot2::ggsave(
  file.path(roots$figures, "H10_gap_common_sample_effects.pdf"),
  gap_plot,
  width = 9.4,
  height = 5.8,
  units = "in",
  bg = "white"
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
h10_write_csv(
  diagnostic_plot_source,
  file.path(roots$source_data, "H10_diagnostic_assessment_data.csv")
)
diagnostic_plot <- ggplot2::ggplot(
  diagnostic_plot_source,
  ggplot2::aes(
    x = .data$model_label,
    y = .data$metric_label,
    fill = .data$final_assessment
  )
) +
  ggplot2::geom_tile(colour = "white", linewidth = 0.7) +
  ggplot2::scale_fill_manual(
    values = c(
      "acceptable" = "#66C2A5",
      "acceptable with specified limitations" = "#FDC086",
      "not acceptable for inference" = "#E78AC3"
    ),
    drop = FALSE
  ) +
  ggplot2::labs(
    title = "H10 diagnostic acceptance assessment",
    subtitle = paste0(
      "Convergence, distributional, residual, temporal, participant-influence, ",
      "and leave-one-site-out evidence"
    ),
    x = NULL,
    y = NULL,
    fill = "Assessment",
    caption = paste0(
      "Each tile is an explicit model-level assessment.\nNumerical values, ",
      "threshold flags, and interpretations are retained in the paired source CSV."
    )
  ) +
  ggplot2::theme_minimal(base_size = 10) +
  ggplot2::theme(
    plot.title.position = "plot",
    legend.position = "bottom",
    panel.grid = ggplot2::element_blank(),
    axis.text.x = ggplot2::element_text(angle = 20, hjust = 1),
    axis.text.y = ggplot2::element_text(size = 8),
    plot.caption = ggplot2::element_text(hjust = 0, size = 7)
  )
ggplot2::ggsave(
  file.path(roots$figures, "H10_diagnostic_assessment.png"),
  diagnostic_plot,
  width = 9.4,
  height = 8.2,
  units = "in",
  dpi = 300,
  bg = "white"
)
ggplot2::ggsave(
  file.path(roots$figures, "H10_diagnostic_assessment.pdf"),
  diagnostic_plot,
  width = 9.4,
  height = 8.2,
  units = "in",
  bg = "white"
)

figure_manifest <- tibble::tribble(
  ~figure_path,
  ~pdf_path,
  ~source_data_path,
  ~width_in,
  ~height_in,
  ~alt_text,
  "artifacts/10_figures/H10/H10_primary_age_associations.png",
  "artifacts/10_figures/H10/H10_primary_age_associations.pdf",
  "artifacts/11_source_data/H10/H10_primary_age_associations_data.csv",
  9.4,
  8.5,
  paste0(
    "Forest plot of site-adjusted age associations for 17 personal light-exposure ",
    "metrics, showing separate primary near-eye and complementary chest ",
    "standardized model-scale estimates with 95% confidence intervals."
  ),
  "artifacts/10_figures/H10/H10_primary_biological_sex_associations.png",
  "artifacts/10_figures/H10/H10_primary_biological_sex_associations.pdf",
  paste0(
    "artifacts/11_source_data/H10/",
    "H10_primary_biological_sex_associations_data.csv"
  ),
  9.4,
  8.5,
  paste0(
    "Forest plot of site-adjusted Female-minus-Male contrasts for 17 personal ",
    "light-exposure metrics, showing separate primary near-eye and complementary ",
    "chest standardized model-scale estimates with 95% confidence intervals."
  ),
  "artifacts/10_figures/H10/H10_paired_placement_effects.png",
  "artifacts/10_figures/H10/H10_paired_placement_effects.pdf",
  "artifacts/11_source_data/H10/H10_paired_placement_effects_data.csv",
  9.4,
  5.8,
  paste0(
    "Scatterplot comparing separately fitted near-eye and chest H10 associations ",
    "on identical participant-days for 15 estimable metrics, with component 95% ",
    "confidence intervals and a dashed identity line."
  ),
  "artifacts/10_figures/H10/H10_gap_common_sample_effects.png",
  "artifacts/10_figures/H10/H10_gap_common_sample_effects.pdf",
  "artifacts/11_source_data/H10/H10_gap_common_sample_effects_data.csv",
  9.4,
  5.8,
  paste0(
    "Scatterplot comparing primary and gap-timing-unaware H10 associations on ",
    "identical within-metric samples, with a dashed identity line."
  ),
  "artifacts/10_figures/H10/H10_diagnostic_assessment.png",
  "artifacts/10_figures/H10/H10_diagnostic_assessment.pdf",
  "artifacts/11_source_data/H10/H10_diagnostic_assessment_data.csv",
  9.4,
  8.2,
  paste0(
    "Heatmap of explicit acceptable or acceptable-with-limitations diagnostic ",
    "assessments for age and Female-minus-Male models across 17 metrics and ",
    "both placements."
  )
)
for (placement in c("glasses", "chest")) {
  for (variant in c("recreated", "corrected")) {
    figure_manifest <- dplyr::bind_rows(
      figure_manifest,
      tibble::tibble(
        figure_path = paste0(
          "artifacts/10_figures/H10/H10_v0_",
          placement,
          "_",
          variant,
          ".png"
        ),
        pdf_path = paste0(
          "artifacts/10_figures/H10/H10_v0_",
          placement,
          "_",
          variant,
          ".pdf"
        ),
        source_data_path = paste0(
          "artifacts/11_source_data/H10/H10_v0_figure_",
          variant,
          "_data.csv"
        ),
        width_in = 10,
        height_in = 5,
        alt_text = paste0(
          ifelse(variant == "recreated", "Frozen", "Corrected frozen"),
          " V0 ",
          ifelse(placement == "glasses", "near-eye", "chest"),
          " two-panel display of time above 1,000 lx melEDI against age and ",
          "the repeated V0 age-by-site boxplots."
        )
      )
    )
  }
}
if (
  any(!file.exists(file.path(root, figure_manifest$figure_path))) ||
    any(!file.exists(file.path(root, figure_manifest$pdf_path))) ||
    any(!file.exists(file.path(root, figure_manifest$source_data_path)))
) {
  h10_abort("An H10 durable figure lacks its PDF or paired source CSV")
}
h10_write_csv(
  figure_manifest,
  file.path(roots$manifests, "H10_figure_manifest.csv")
)

####
# Step 9: Record execution and provenance; no resampling was required
####

execution_environment <- tibble::tibble(
  component = c("R", "Quarto", required_packages, "resampling"),
  version_or_status = c(
    as.character(getRversion()),
    tryCatch(
      system2("quarto", "--version", stdout = TRUE, stderr = TRUE)[1L],
      error = function(condition) NA_character_
    ),
    vapply(
      required_packages,
      function(package) as.character(utils::packageVersion(package)),
      character(1)
    ),
    paste0(
      "None; no bootstrap, simulation, or other resampling was required, so ",
      "the pilot gate was not triggered"
    )
  )
)
h10_write_csv(
  execution_environment,
  file.path(roots$manifests, "H10_execution_environment.csv")
)

h10_build_manifest()
message("H10 Stage 2 fitting and artifact generation complete")
