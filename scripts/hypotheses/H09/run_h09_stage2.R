# Run the author-approved H09 Stage 2 implementation and V0 comparison.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)

project_library <- file.path(
  root,
  "renv/library/macos/R-4.6/aarch64-apple-darwin23"
)
if (dir.exists(project_library)) {
  .libPaths(c(project_library, .libPaths()))
}

source(file.path(root, "scripts/pipeline/paths_io.R"))
source(file.path(root, "scripts/pipeline/p_value_display.R"))
source(file.path(root, "scripts/hypotheses/H09/h09_contract.R"))
source(file.path(root, "scripts/hypotheses/H09/h09_modeling.R"))

options(
  lifecycle_verbosity = "quiet",
  warn = 1,
  contrasts = c("contr.treatment", "contr.poly")
)

if (!identical(as.character(getRversion()), "4.6.1")) {
  h09_abort(
    "H09 Stage 2 requires R 4.6.1; found %s",
    as.character(getRversion())
  )
}

required_packages <- c(
  "dplyr", "tidyr", "purrr", "tibble", "readr", "digest", "openssl",
  "lme4", "nlme", "emmeans", "ggplot2", "patchwork", "ragg", "gt",
  "scales", "rvest"
)
missing_packages <- required_packages[
  !vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
]
if (length(missing_packages) > 0L) {
  h09_abort(
    "H09 Stage 2 is missing project package(s): %s",
    paste(missing_packages, collapse = ", ")
  )
}

h09_validate_contract()

producer <- "scripts/hypotheses/H09/run_h09_stage2.R"
stage <- Sys.getenv("H09_STAGE", unset = "fit")
if (!stage %in% c("fit", "manifest")) {
  h09_abort("H09_STAGE must be `fit` or `manifest`")
}

roots <- list(
  model_data = file.path(root, "artifacts/06_model_data/H09"),
  models = file.path(root, "artifacts/07_models/H09"),
  diagnostics = file.path(root, "artifacts/08_diagnostics/H09"),
  tables = file.path(root, "artifacts/09_tables/H09"),
  figures = file.path(root, "artifacts/10_figures/H09"),
  source_data = file.path(root, "artifacts/11_source_data/H09"),
  manifests = file.path(root, "artifacts/12_manifests/H09")
)
invisible(vapply(
  roots,
  dir.create,
  logical(1),
  recursive = TRUE,
  showWarnings = FALSE
))

h09_write_csv <- function(data, path) {
  write_csv_artifact(data, path, producer = producer)
  invisible(path)
}

h09_write_rds <- function(object, path) {
  write_rds_artifact(object, path, producer = producer)
  invisible(path)
}

h09_relative_path <- function(path) {
  normalized <- normalizePath(path, winslash = "/", mustWork = TRUE)
  if (startsWith(normalized, paste0(root, "/"))) {
    substring(normalized, nchar(root) + 2L)
  } else {
    normalized
  }
}

h09_build_manifest <- function() {
  artifact_files <- sort(unique(unlist(lapply(
    roots,
    list.files,
    recursive = TRUE,
    full.names = TRUE
  ))))
  manifest_path <- file.path(roots$manifests, "H09_stage2_artifacts.csv")
  excluded_manifest_paths <- normalizePath(
    c(
      manifest_path,
      file.path(roots$manifests, "H09_stage3_artifacts.csv")
    ),
    winslash = "/",
    mustWork = FALSE
  )
  artifact_files <- artifact_files[
    file.exists(artifact_files) &
      !dir.exists(artifact_files) &
      !normalizePath(
        artifact_files,
        winslash = "/",
        mustWork = TRUE
      ) %in% excluded_manifest_paths
  ]
  code_and_report <- c(
    file.path(root, "scripts/hypotheses/H09/h09_contract.R"),
    file.path(root, "scripts/hypotheses/H09/h09_modeling.R"),
    file.path(root, "scripts/hypotheses/H09/run_h09_stage2.R"),
    file.path(root, "scripts/hypotheses/H09/finalize_h09_figure_qa.R"),
    file.path(root, "tests/hypotheses/H09/test_h09_stage2.R"),
    file.path(
      root,
      "audit/hypotheses/H09/02_implementation_and_v0_comparison.qmd"
    ),
    file.path(
      root,
      "audit/hypotheses/H09/02_implementation_and_v0_comparison.html"
    ),
    file.path(
      root,
      "audit/hypotheses/H09/H09_stage1_gate_and_stage2_transition.md"
    ),
    file.path(
      root,
      "audit/hypotheses/H09/H09_stage2_gate_and_stage3_transition.md"
    ),
    file.path(root, "audit/handoffs/H09_worker_handoff.md"),
    file.path(root, "audit/handoffs/H09_shared_change_request.md")
  )
  files <- sort(unique(c(
    artifact_files,
    code_and_report[file.exists(code_and_report)]
  )))
  manifest <- dplyr::bind_rows(lapply(files, function(path) {
    info <- file.info(path)
    tibble::tibble(
      path = h09_relative_path(path),
      artifact_type = tools::file_ext(path),
      sha256 = artifact_sha256(path),
      bytes = as.numeric(info$size),
      producer = producer,
      r_version = as.character(getRversion()),
      written_utc = format(info$mtime, tz = "UTC", usetz = TRUE)
    )
  }))
  h09_write_csv(manifest, manifest_path)
  invisible(manifest_path)
}

if (identical(stage, "manifest")) {
  h09_build_manifest()
  message("H09 Stage 2 manifest refreshed")
  quit(save = "no", status = 0L)
}

####
# Step 1: Verify approvals, contracts, and pinned inputs
####

input_contract <- h09_input_contract(root)
input_audit <- input_contract |>
  dplyr::mutate(
    exists = file.exists(.data$absolute_path),
    observed_sha256 = vapply(
      .data$absolute_path,
      artifact_sha256,
      character(1)
    ),
    hash_verified = .data$observed_sha256 == .data$expected_sha256,
    bytes = as.numeric(file.info(.data$absolute_path)$size),
    observed_rows = purrr::map_int(
      seq_len(dplyr::n()),
      function(index) {
        if (
          is.na(input_contract$expected_rows[index]) ||
            tools::file_ext(input_contract$path[index]) != "rds"
        ) {
          return(NA_integer_)
        }
        nrow(readRDS(input_contract$absolute_path[index]))
      }
    ),
    rows_verified = is.na(.data$expected_rows) |
      .data$observed_rows == .data$expected_rows
  ) |>
  dplyr::select(
    .data$input_role,
    .data$path,
    .data$use,
    .data$expected_sha256,
    .data$observed_sha256,
    .data$hash_verified,
    .data$expected_rows,
    .data$observed_rows,
    .data$rows_verified,
    .data$bytes
  )
if (any(!input_audit$hash_verified) || any(!input_audit$rows_verified)) {
  h09_abort("A frozen H09 input differs from its approved identity")
}

base_manifest <- readr::read_csv(
  file.path(root, "artifacts/12_manifests/base_model_data_artifacts.csv"),
  show_col_types = FALSE
)
base_bundle_audit <- tibble::tibble(
  expected_input_bundle_sha256 =
    "e840ce9d2a7f653bc5ebbfe020ce087017dfdaf0276df09da578bda30a539916",
  observed_input_bundle_sha256 = paste(
    unique(base_manifest$input_bundle_sha256),
    collapse = "|"
  ),
  input_bundle_verified =
    length(unique(base_manifest$input_bundle_sha256)) == 1L &&
    unique(base_manifest$input_bundle_sha256) ==
      "e840ce9d2a7f653bc5ebbfe020ce087017dfdaf0276df09da578bda30a539916",
  provenance_qualification = paste(
    "PREP-003/FIND-044 remain open: current metric, MDER, and state-support",
    "values have not all passed a current-manifest independent reconstruction"
  )
)
if (!isTRUE(base_bundle_audit$input_bundle_verified)) {
  h09_abort("The current Preparation 06 input-bundle identity changed")
}

score_contract <- h09_score_contract()
metric_registry <- h09_metric_registry()
predictor_registry <- h09_predictor_registry()
run_registry <- h09_run_registry()
family_registry <- h09_family_registry()
formula_registry <- h09_formula_registry()
approval_registry <- h09_approval_registry()
diagnostic_thresholds <- h09_diagnostic_thresholds()

site_registry <- readr::read_csv(
  file.path(root, "config/site_display_registry.csv"),
  show_col_types = FALSE
) |>
  dplyr::arrange(.data$display_order)
site_levels <- site_registry$site

metric_display <- readr::read_csv(
  file.path(root, "config/metric_display_registry.csv"),
  show_col_types = FALSE
)
metric_display_audit <- metric_registry |>
  dplyr::left_join(
    metric_display |>
      dplyr::select(
        .data$metric_id,
        registry_manuscript_name = .data$manuscript_name,
        registry_analysis_unit = .data$analysis_unit,
        registry_display_unit = .data$display_unit
      ),
    by = "metric_id",
    relationship = "many-to-one"
  ) |>
  dplyr::mutate(
    registry_status = dplyr::case_when(
      .data$metric_id == "longest_period_midpoint" &
        is.na(.data$registry_manuscript_name) ~
        "H09-owned registered construction; shared registry row unavailable",
      .data$manuscript_name == .data$registry_manuscript_name &
        .data$registry_analysis_unit == "participant-day" ~ "PASS",
      TRUE ~ "FAIL"
    )
  )
if (any(metric_display_audit$registry_status == "FAIL")) {
  h09_abort("The H09 display contract differs from the shared registry")
}

chronotype <- readRDS(input_contract$absolute_path[
  input_contract$input_role == "normalized_chronotype"
])
if (
  nrow(chronotype) != score_contract$participants ||
    anyDuplicated(chronotype[c("site", "Id")]) ||
    sum(is.na(chronotype$msf_sc)) != score_contract$mctq_missing ||
    sum(is.na(chronotype$meq)) != score_contract$meq_missing ||
    !isTRUE(all.equal(
      mean(as.numeric(chronotype$msf_sc) / 3600, na.rm = TRUE),
      score_contract$mctq_center_hour
    )) ||
    !isTRUE(all.equal(
      mean(chronotype$meq, na.rm = TRUE),
      score_contract$meq_center_score
    ))
) {
  h09_abort("The accepted pinned chronotype fields fail their H09 contract")
}

score_audit <- tibble::tibble(
  participants = nrow(chronotype),
  sites = dplyr::n_distinct(chronotype$site),
  mctq_complete = sum(!is.na(chronotype$msf_sc)),
  mctq_missing = sum(is.na(chronotype$msf_sc)),
  mctq_center_hour = mean(
    as.numeric(chronotype$msf_sc) / 3600,
    na.rm = TRUE
  ),
  mctq_min_hour = min(as.numeric(chronotype$msf_sc) / 3600, na.rm = TRUE),
  mctq_max_hour = max(as.numeric(chronotype$msf_sc) / 3600, na.rm = TRUE),
  meq_complete = sum(!is.na(chronotype$meq)),
  meq_missing = sum(is.na(chronotype$meq)),
  meq_center_score = mean(chronotype$meq, na.rm = TRUE),
  meq_min_score = min(chronotype$meq, na.rm = TRUE),
  meq_max_score = max(chronotype$meq, na.rm = TRUE),
  item_level_reconstruction = "unavailable",
  author_acceptance = score_contract$author_decision,
  provenance_assessment = "acceptable under explicit H09-G4 acceptance"
)

h09_write_csv(input_audit, file.path(roots$model_data, "H09_input_audit.csv"))
h09_write_csv(
  base_bundle_audit,
  file.path(roots$model_data, "H09_base_bundle_audit.csv")
)
h09_write_csv(
  approval_registry,
  file.path(roots$model_data, "H09_author_approvals.csv")
)
h09_write_csv(
  metric_registry,
  file.path(roots$model_data, "H09_metric_registry.csv")
)
h09_write_csv(
  predictor_registry,
  file.path(roots$model_data, "H09_predictor_registry.csv")
)
h09_write_csv(
  run_registry,
  file.path(roots$model_data, "H09_run_registry.csv")
)
h09_write_csv(
  family_registry,
  file.path(roots$model_data, "H09_family_registry.csv")
)
h09_write_csv(
  formula_registry,
  file.path(roots$model_data, "H09_formula_registry.csv")
)
h09_write_csv(
  diagnostic_thresholds,
  file.path(roots$diagnostics, "H09_diagnostic_thresholds.csv")
)
h09_write_csv(
  metric_display_audit,
  file.path(roots$model_data, "H09_metric_display_audit.csv")
)
h09_write_csv(
  score_audit,
  file.path(roots$diagnostics, "H09_chronotype_score_audit.csv")
)

####
# Step 2: Build exact H09-specific rows and model frames
####

primary_near_eye_source <- readRDS(input_contract$absolute_path[
  input_contract$input_role == "primary_near_eye_enriched"
])
primary_chest_source <- readRDS(input_contract$absolute_path[
  input_contract$input_role == "primary_chest_enriched"
])
gap_source <- readRDS(input_contract$absolute_path[
  input_contract$input_role == "gap_timing_unaware_metrics"
])

score_value_audit <- dplyr::bind_rows(
  primary_near_eye_source |>
    dplyr::transmute(
      placement = "glasses",
      .data$site,
      .data$Id,
      source_mctq = as.numeric(.data$msf_sc),
      source_meq = as.numeric(.data$meq)
    ),
  primary_chest_source |>
    dplyr::transmute(
      placement = "chest",
      .data$site,
      .data$Id,
      source_mctq = as.numeric(.data$msf_sc),
      source_meq = as.numeric(.data$meq)
    )
) |>
  dplyr::distinct() |>
  dplyr::left_join(
    chronotype |>
      dplyr::transmute(
        .data$site,
        .data$Id,
        normalized_mctq = as.numeric(.data$msf_sc),
        normalized_meq = as.numeric(.data$meq)
      ),
    by = c("site", "Id"),
    relationship = "many-to-one"
  ) |>
  dplyr::mutate(
    mctq_value_matches = dplyr::if_else(
      is.na(.data$source_mctq) & is.na(.data$normalized_mctq),
      TRUE,
      .data$source_mctq == .data$normalized_mctq,
      missing = FALSE
    ),
    meq_value_matches = dplyr::if_else(
      is.na(.data$source_meq) & is.na(.data$normalized_meq),
      TRUE,
      .data$source_meq == .data$normalized_meq,
      missing = FALSE
    )
  )
if (
  any(!score_value_audit$mctq_value_matches) ||
    any(!score_value_audit$meq_value_matches)
) {
  h09_abort("Enriched H09 score values differ from the pinned chronotype input")
}
h09_write_csv(
  score_value_audit,
  file.path(roots$diagnostics, "H09_chronotype_value_audit.csv")
)

primary_near_eye <- h09_prepare_primary_wide(
  primary_near_eye_source,
  score_contract
)
primary_chest <- h09_prepare_primary_wide(
  primary_chest_source,
  score_contract
)
primary_rows <- dplyr::bind_rows(
  h09_primary_long(primary_near_eye, "glasses", metric_registry),
  h09_primary_long(primary_chest, "chest", metric_registry)
)
gap_rows <- h09_prepare_gap_long(gap_source, chronotype, score_contract)
all_rows <- dplyr::bind_rows(primary_rows, gap_rows)

if (anyDuplicated(all_rows[c(
  "data_scenario_id", "placement", "site", "Id", "local_date", "metric_id"
)])) {
  h09_abort("H09 long rows contain duplicate scenario-placement-day metrics")
}

h09_rows_for_run <- function(run, metric_id, instrument_id) {
  selected <- all_rows |>
    dplyr::filter(
      .data$data_scenario_id == run$data_scenario_id,
      .data$placement == run$placement,
      .data$metric_id == .env$metric_id
    )
  frame <- h09_prepare_model_frame(selected, instrument_id, site_levels)
  if (nrow(frame) == 0L) return(frame)
  if (run$sample_scenario == "paired_common") {
    opposite <- if (run$placement == "glasses") "chest" else "glasses"
    other <- all_rows |>
      dplyr::filter(
        .data$data_scenario_id == run$data_scenario_id,
        .data$placement == opposite,
        .data$metric_id == .env$metric_id
      )
    other_frame <- h09_prepare_model_frame(other, instrument_id, site_levels)
    common <- intersect(frame$.model_row_id, other_frame$.model_row_id)
    frame <- frame[frame$.model_row_id %in% common, , drop = FALSE]
  }
  if (run$sample_scenario == "gap_common") {
    other_scenario <- if (run$data_scenario_id == "primary") {
      "gap_timing_unaware"
    } else {
      "primary"
    }
    other <- all_rows |>
      dplyr::filter(
        .data$data_scenario_id == other_scenario,
        .data$placement == run$placement,
        .data$metric_id == .env$metric_id
      )
    other_frame <- h09_prepare_model_frame(other, instrument_id, site_levels)
    common <- intersect(frame$.model_row_id, other_frame$.model_row_id)
    frame <- frame[frame$.model_row_id %in% common, , drop = FALSE]
  }
  if (nrow(frame) > 0L) {
    frame$site <- droplevels(frame$site)
    stats::contrasts(frame$site) <- stats::contr.sum(nlevels(frame$site))
    frame$Id <- droplevels(frame$Id)
    frame$participant_key <- droplevels(frame$participant_key)
  }
  tibble::as_tibble(frame)
}

model_frames <- list()
frame_index_rows <- list()
frame_site_rows <- list()
unavailable_rows <- list()

for (run_index in seq_len(nrow(run_registry))) {
  run <- run_registry[run_index, ]
  available_metrics <- metric_registry$metric_id
  if (
    run$data_scenario_id == "gap_timing_unaware" ||
      run$sample_scenario == "gap_common"
  ) {
    available_metrics <- setdiff(
      available_metrics,
      "longest_period_midpoint"
    )
  }
  for (metric_id in available_metrics) {
    for (instrument_id in predictor_registry$instrument_id) {
      frame <- h09_rows_for_run(run, metric_id, instrument_id)
      if (nrow(frame) == 0L) {
        h09_abort(
          "No H09 model rows for %s / %s / %s",
          run$run_id,
          metric_id,
          instrument_id
        )
      }
      frame_id <- paste(run$run_id, metric_id, instrument_id, sep = "__")
      model_frames[[frame_id]] <- frame
      sample <- h09_sample_summary(frame)
      frame_index_rows[[frame_id]] <- dplyr::bind_cols(
        tibble::tibble(
          frame_id = frame_id,
          run_order = run$run_order,
          run_id = run$run_id,
          data_scenario_id = run$data_scenario_id,
          reader_scenario = run$reader_scenario,
          placement = run$placement,
          placement_label = run$placement_label,
          sample_scenario = run$sample_scenario,
          analytical_role = run$analytical_role,
          metric_id = metric_id,
          instrument_id = instrument_id,
          availability = "ESTIMABLE",
          row_key_hash = h09_key_hash(frame),
          model_frame_hash = h09_frame_hash(frame)
        ),
        sample
      )
      frame_site_rows[[frame_id]] <- dplyr::bind_cols(
        tibble::tibble(
          frame_id = frame_id,
          run_id = run$run_id,
          metric_id = metric_id,
          instrument_id = instrument_id
        )[rep(1L, nlevels(frame$site)), , drop = FALSE],
        h09_sample_by_site(frame)
      )
    }
  }
  if (!"longest_period_midpoint" %in% available_metrics) {
    for (instrument_id in predictor_registry$instrument_id) {
      key <- paste(run$run_id, instrument_id, sep = "__")
      unavailable_rows[[key]] <- tibble::tibble(
        run_id = run$run_id,
        data_scenario_id = run$data_scenario_id,
        placement = run$placement,
        placement_label = run$placement_label,
        sample_scenario = run$sample_scenario,
        metric_id = "longest_period_midpoint",
        instrument_id = instrument_id,
        availability = "NON_ESTIMABLE",
        reason = paste(
          "The approved gap-timing-unaware artifact contains neither the",
          "registered longest-period midpoint nor its selected-period endpoints"
        )
      )
    }
  }
}

model_frame_index <- dplyr::bind_rows(frame_index_rows) |>
  dplyr::arrange(.data$run_order, .data$metric_id, .data$instrument_id)
model_frame_by_site <- dplyr::bind_rows(frame_site_rows)
non_estimable_targets <- dplyr::bind_rows(unavailable_rows)

paired_sample_audit <- model_frame_index |>
  dplyr::filter(.data$sample_scenario == "paired_common") |>
  dplyr::select(
    .data$metric_id,
    .data$instrument_id,
    .data$placement,
    .data$participants,
    .data$participant_days,
    .data$row_key_hash
  ) |>
  tidyr::pivot_wider(
    names_from = .data$placement,
    values_from = c(
      .data$participants,
      .data$participant_days,
      .data$row_key_hash
    )
  ) |>
  dplyr::mutate(
    exact_counts_match = .data$participants_glasses ==
      .data$participants_chest &
      .data$participant_days_glasses == .data$participant_days_chest,
    exact_row_keys_match = .data$row_key_hash_glasses ==
      .data$row_key_hash_chest
  )
if (
  any(!paired_sample_audit$exact_counts_match) ||
    any(!paired_sample_audit$exact_row_keys_match)
) {
  h09_abort("An H09 paired placement frame does not use identical row keys")
}

gap_common_sample_audit <- model_frame_index |>
  dplyr::filter(.data$sample_scenario == "gap_common") |>
  dplyr::select(
    .data$metric_id,
    .data$instrument_id,
    .data$placement,
    .data$data_scenario_id,
    .data$participants,
    .data$participant_days,
    .data$row_key_hash
  ) |>
  tidyr::pivot_wider(
    names_from = .data$data_scenario_id,
    values_from = c(
      .data$participants,
      .data$participant_days,
      .data$row_key_hash
    )
  ) |>
  dplyr::mutate(
    exact_counts_match = .data$participants_primary ==
      .data$participants_gap_timing_unaware &
      .data$participant_days_primary ==
        .data$participant_days_gap_timing_unaware,
    exact_row_keys_match = .data$row_key_hash_primary ==
      .data$row_key_hash_gap_timing_unaware
  )
if (
  any(!gap_common_sample_audit$exact_counts_match) ||
    any(!gap_common_sample_audit$exact_row_keys_match)
) {
  h09_abort("An H09 primary/gap common frame does not use identical row keys")
}

h09_write_csv(
  model_frame_index,
  file.path(roots$model_data, "H09_model_frame_index.csv")
)
h09_write_csv(
  model_frame_by_site,
  file.path(roots$model_data, "H09_model_frame_by_site.csv")
)
h09_write_csv(
  non_estimable_targets,
  file.path(roots$model_data, "H09_non_estimable_targets.csv")
)
h09_write_csv(
  paired_sample_audit,
  file.path(roots$model_data, "H09_paired_sample_audit.csv")
)
h09_write_csv(
  gap_common_sample_audit,
  file.path(roots$model_data, "H09_gap_common_sample_audit.csv")
)
h09_write_rds(
  model_frames,
  file.path(roots$model_data, "H09_model_frames.rds")
)

####
# Step 3: Fit every approved participant-day model and multiplicity family
####

model_bundles <- list()
fit_index_rows <- list()
test_rows <- list()
effect_rows <- list()
site_slope_rows <- list()

for (index in seq_len(nrow(model_frame_index))) {
  context <- model_frame_index[index, ]
  frame <- model_frames[[context$frame_id]]
  bundle <- h09_fit_bundle(frame, context$instrument_id)
  model_bundles[[context$frame_id]] <- bundle

  fit_registry <- list(
    ML_M0_site_only = bundle$ml$M0_site_only,
    ML_M1_main = bundle$ml$M1_main,
    ML_M2_interaction = bundle$ml$M2_interaction,
    REML_M1_main = bundle$reml$M1_main,
    REML_M2_interaction = bundle$reml$M2_interaction
  )
  fit_index_rows[[context$frame_id]] <- dplyr::bind_rows(lapply(
    names(fit_registry),
    function(fit_id) {
      dplyr::bind_cols(
        context |>
          dplyr::select(
            .data$frame_id,
            .data$run_id,
            .data$metric_id,
            .data$instrument_id,
            .data$observations,
            .data$row_key_hash
          ),
        tibble::tibble(
          fit_id = fit_id,
          estimation = if (startsWith(fit_id, "ML_")) "ML" else "REML"
        ),
        h09_model_fit_status(fit_registry[[fit_id]])
      )
    }
  ))

  tests <- h09_bundle_tests(bundle)
  predictor_row <- predictor_registry |>
    dplyr::filter(.data$instrument_id == context$instrument_id)
  metric_row <- metric_registry |>
    dplyr::filter(.data$metric_id == context$metric_id)
  tests <- tests |>
    dplyr::mutate(
      family_base = dplyr::case_when(
        !metric_row$primary_family_member ~ NA_character_,
        .data$comparison_id == "main" ~ predictor_row$main_family,
        TRUE ~ predictor_row$interaction_family
      ),
      family_id = dplyr::if_else(
        is.na(.data$family_base),
        NA_character_,
        paste(.data$family_base, context$run_id, sep = "__")
      )
    )
  test_rows[[context$frame_id]] <- dplyr::bind_cols(
    context[rep(1L, nrow(tests)), , drop = FALSE],
    tests
  )

  effect <- h09_effect_summary(
    bundle$reml$M1_main,
    context$instrument_id
  )
  performance <- h09_performance_summary(bundle$reml$M1_main$model)
  effect_rows[[context$frame_id]] <- dplyr::bind_cols(
    context,
    effect,
    performance
  )

  slopes <- h09_site_slopes(
    bundle$reml$M2_interaction,
    frame,
    context$instrument_id
  )
  site_slope_rows[[context$frame_id]] <- dplyr::bind_cols(
    context[rep(1L, nrow(slopes)), , drop = FALSE],
    slopes
  )

  if (index %% 10L == 0L || index == nrow(model_frame_index)) {
    message("H09 fitted frame ", index, " / ", nrow(model_frame_index))
  }
}

model_fit_index <- dplyr::bind_rows(fit_index_rows)
model_tests <- dplyr::bind_rows(test_rows)
model_effects <- dplyr::bind_rows(effect_rows)
site_specific_slopes <- dplyr::bind_rows(site_slope_rows)

non_estimable_tests <- non_estimable_targets |>
  tidyr::crossing(comparison_id = c("main", "interaction")) |>
  dplyr::left_join(
    run_registry |>
      dplyr::select(
        .data$run_id,
        .data$run_order,
        .data$reader_scenario,
        .data$analytical_role
      ),
    by = "run_id",
    relationship = "many-to-one"
  ) |>
  dplyr::left_join(
    predictor_registry |>
      dplyr::select(
        .data$instrument_id,
        .data$main_family,
        .data$interaction_family
      ),
    by = "instrument_id",
    relationship = "many-to-one"
  ) |>
  dplyr::mutate(
    frame_id = NA_character_,
    family_base = dplyr::if_else(
      .data$comparison_id == "main",
      .data$main_family,
      .data$interaction_family
    ),
    family_id = paste(.data$family_base, .data$run_id, sep = "__"),
    chi_square = NA_real_,
    df = NA_real_,
    p_raw = NA_real_,
    comparison_status = "NON_ESTIMABLE",
    comparison_error = .data$reason,
    participants = 0L,
    participant_days = 0L,
    observations = 0L,
    sites = 0L,
    derivation_hours = NA_real_,
    min_days_per_participant = NA_integer_,
    median_days_per_participant = NA_real_,
    max_days_per_participant = NA_integer_,
    row_key_hash = NA_character_,
    model_frame_hash = NA_character_
  ) |>
  dplyr::select(dplyr::all_of(names(model_tests)))

model_tests <- dplyr::bind_rows(model_tests, non_estimable_tests) |>
  dplyr::group_by(
    .data$run_id,
    .data$instrument_id,
    .data$comparison_id,
    .data$family_id
  ) |>
  dplyr::mutate(
    p_adjusted = {
      output <- rep(NA_real_, dplyr::n())
      eligible <- is.finite(.data$p_raw) & !is.na(.data$family_id)
      if (any(eligible)) {
        output[eligible] <- stats::p.adjust(
          .data$p_raw[eligible],
          method = "BH",
          n = 5L
        )
      }
      output
    },
    raw_significant = is.finite(.data$p_raw) & .data$p_raw < 0.05,
    adjusted_significant = is.finite(.data$p_adjusted) &
      .data$p_adjusted < 0.05
  ) |>
  dplyr::ungroup()

family_audit <- model_tests |>
  dplyr::filter(!is.na(.data$family_id)) |>
  dplyr::group_by(
    .data$run_id,
    .data$instrument_id,
    .data$comparison_id,
    .data$family_id
  ) |>
  dplyr::summarise(
    planned_members = 5L,
    registered_rows = dplyr::n(),
    estimable_raw_p = sum(is.finite(.data$p_raw)),
    non_estimable_members = sum(!is.finite(.data$p_raw)),
    adjusted_values = sum(is.finite(.data$p_adjusted)),
    complete_registered_family = .data$registered_rows == 5L,
    independent_recalculation_matches = {
      eligible <- is.finite(.data$p_raw)
      expected <- stats::p.adjust(.data$p_raw[eligible], method = "BH", n = 5L)
      isTRUE(all.equal(.data$p_adjusted[eligible], expected))
    },
    family_assessment = dplyr::if_else(
      .data$complete_registered_family &
        .data$independent_recalculation_matches,
      "acceptable",
      "not acceptable"
    ),
    .groups = "drop"
  )
if (
  any(!family_audit$complete_registered_family) ||
    any(!family_audit$independent_recalculation_matches)
) {
  h09_abort("An H09 multiplicity family failed independent reproduction")
}

main_tests <- model_tests |>
  dplyr::filter(.data$comparison_id == "main") |>
  dplyr::select(
    .data$frame_id,
    main_chi_square = .data$chi_square,
    main_df = .data$df,
    main_p_raw = .data$p_raw,
    main_p_adjusted = .data$p_adjusted,
    main_raw_significant = .data$raw_significant,
    main_adjusted_significant = .data$adjusted_significant,
    main_family_id = .data$family_id,
    main_comparison_status = .data$comparison_status
  )
interaction_tests <- model_tests |>
  dplyr::filter(.data$comparison_id == "interaction") |>
  dplyr::select(
    .data$frame_id,
    interaction_chi_square = .data$chi_square,
    interaction_df = .data$df,
    interaction_p_raw = .data$p_raw,
    interaction_p_adjusted = .data$p_adjusted,
    interaction_raw_significant = .data$raw_significant,
    interaction_adjusted_significant = .data$adjusted_significant,
    interaction_family_id = .data$family_id,
    interaction_comparison_status = .data$comparison_status
  )
model_results_master <- model_effects |>
  dplyr::left_join(main_tests, by = "frame_id", relationship = "one-to-one") |>
  dplyr::left_join(
    interaction_tests,
    by = "frame_id",
    relationship = "one-to-one"
  ) |>
  dplyr::left_join(
    metric_registry |>
      dplyr::select(
        .data$metric_id,
        .data$metric_order,
        .data$manuscript_name,
        .data$abbreviation,
        .data$analysis_branch,
        .data$primary_family_member
      ),
    by = "metric_id",
    relationship = "many-to-one"
  ) |>
  dplyr::left_join(
    predictor_registry |>
      dplyr::select(
        .data$instrument_id,
        .data$instrument_name,
        .data$effect_unit,
        .data$effect_direction
      ),
    by = "instrument_id",
    relationship = "many-to-one"
  )

h09_write_csv(
  model_fit_index,
  file.path(roots$models, "H09_model_fit_index.csv")
)
h09_write_csv(
  model_tests,
  file.path(roots$tables, "H09_model_tests.csv")
)
h09_write_csv(
  model_effects,
  file.path(roots$tables, "H09_model_effects.csv")
)
h09_write_csv(
  site_specific_slopes,
  file.path(roots$tables, "H09_site_specific_slopes.csv")
)
h09_write_csv(
  family_audit,
  file.path(roots$tables, "H09_family_audit.csv")
)
h09_write_csv(
  model_results_master,
  file.path(roots$tables, "H09_model_results_master.csv")
)
h09_write_rds(
  model_bundles,
  file.path(roots$models, "H09_model_bundles.rds")
)

####
# Step 4: Run declared diagnostics and stability sensitivities
####

diagnostic_targets <- model_frame_index |>
  dplyr::filter(
    .data$run_id %in% c(
      "primary__glasses__all_available",
      "primary__chest__all_available"
    )
  ) |>
  dplyr::left_join(
    metric_registry |>
      dplyr::select(.data$metric_id, .data$primary_family_member),
    by = "metric_id",
    relationship = "many-to-one"
  )

residual_rows <- list()
diagnostic_plot_rows <- list()
serial_rows <- list()
linearity_rows <- list()
linearity_curve_rows <- list()
ar1_rows <- list()
participant_summary_rows <- list()
photoperiod_rows <- list()
influence_rows <- list()
influence_summary_rows <- list()
loo_rows <- list()
loo_summary_rows <- list()
l10_cut_rows <- list()
clock_support_rows <- list()
fit_gate_rows <- list()
site_support_rows <- list()

for (index in seq_len(nrow(diagnostic_targets))) {
  context <- diagnostic_targets[index, ]
  key <- context$frame_id
  frame <- model_frames[[key]]
  bundle <- model_bundles[[key]]
  effect <- model_results_master |>
    dplyr::filter(.data$frame_id == key) |>
    dplyr::select(
      .data$estimate,
      .data$std_error,
      .data$conf_low,
      .data$conf_high
    )

  all_fit_status <- model_fit_index |>
    dplyr::filter(.data$frame_id == key)
  fit_gate_rows[[key]] <- dplyr::bind_cols(
    context,
    tibble::tibble(
      fits_checked = nrow(all_fit_status),
      converged_fits = sum(all_fit_status$converged),
      positive_definite_hessian_fits = sum(
        all_fit_status$positive_definite_hessian
      ),
      nonsingular_fits = sum(!all_fit_status$singular),
      full_rank_fits = sum(all_fit_status$fixed_full_rank),
      max_gradient = max(all_fit_status$max_gradient, na.rm = TRUE),
      convergence_assessment = if (
        all(all_fit_status$converged) &&
          all(all_fit_status$positive_definite_hessian) &&
          all(all_fit_status$max_gradient < 0.002)
      ) "acceptable" else "not acceptable",
      singularity_assessment = if (all(!all_fit_status$singular)) {
        "acceptable"
      } else {
        "not acceptable"
      },
      rank_assessment = if (all(all_fit_status$fixed_full_rank)) {
        "acceptable"
      } else {
        "not acceptable"
      }
    )
  )

  residual <- h09_residual_diagnostics(bundle$reml$M1_main$model, frame)
  residual_rows[[key]] <- dplyr::bind_cols(context, residual)
  plot_data <- h09_diagnostic_plot_data(bundle$reml$M1_main$model, frame)
  diagnostic_plot_rows[[key]] <- dplyr::bind_cols(
    context[rep(1L, nrow(plot_data)), , drop = FALSE],
    plot_data
  )

  serial <- h09_serial_diagnostic(bundle$reml$M1_main$model, frame)
  serial_rows[[key]] <- dplyr::bind_cols(context, serial)

  linearity <- h09_linearity_diagnostic(
    frame,
    bundle,
    context$instrument_id
  )
  linearity_rows[[key]] <- dplyr::bind_cols(context, linearity$summary)
  linearity_curve_rows[[key]] <- dplyr::bind_cols(
    context[rep(1L, nrow(linearity$curve)), , drop = FALSE],
    linearity$curve
  )

  ar1 <- h09_fit_ar1(frame, context$instrument_id, effect)
  ar1_rows[[key]] <- dplyr::bind_cols(context, ar1)

  participant_frame <- h09_prepare_participant_summary(frame)
  participant_formulas <- h09_formula_set(
    context$instrument_id,
    "participant"
  )
  predictor <- if (context$instrument_id == "MCTQ") {
    "mctq_hour_centered"
  } else {
    "meq_10_centered"
  }
  participant_effect <- h09_fit_lm_effect(
    participant_frame,
    participant_formulas,
    predictor
  )
  participant_summary_rows[[key]] <- dplyr::bind_cols(
    context,
    tibble::tibble(
      participant_rows = nrow(participant_frame),
      contributing_participant_days = sum(
        participant_frame$participant_days
      ),
      contributing_derivation_hours = h09_complete_sum(
        participant_frame$derivation_hours
      )
    ),
    participant_effect
  )

  photoperiod <- h09_fit_photoperiod(frame, context$instrument_id)
  photoperiod_rows[[key]] <- dplyr::bind_cols(context, photoperiod)

  influence <- h09_participant_influence(
    bundle$reml$M1_main$model,
    frame,
    context$instrument_id
  )
  influence_rows[[key]] <- dplyr::bind_cols(
    context[rep(1L, nrow(influence)), , drop = FALSE],
    influence
  )
  influence_summary_rows[[key]] <- dplyr::bind_cols(
    context,
    h09_influence_summary(influence)
  )

  loo <- h09_leave_one_site_out(
    frame,
    context$instrument_id,
    effect$estimate
  )
  loo_rows[[key]] <- dplyr::bind_cols(
    context[rep(1L, nrow(loo)), , drop = FALSE],
    loo
  )
  loo_summary_rows[[key]] <- dplyr::bind_cols(context, h09_loo_summary(loo))

  if (context$metric_id == "l10_midpoint") {
    alternative_frame <- frame
    alternative_frame$timing_hour <- alternative_frame$l10_hour_noon_cut
    alternative_fit <- h09_fit_lmer(
      alternative_frame,
      h09_formula_set(context$instrument_id, "participant_day")$M1_main,
      TRUE
    )
    alternative_effect <- h09_effect_summary(
      alternative_fit,
      context$instrument_id
    )
    l10_cut_rows[[key]] <- dplyr::bind_cols(
      context,
      alternative_effect |>
        dplyr::rename_with(~ paste0("noon_cut_", .x)),
      tibble::tibble(
        primary_cut_estimate = effect$estimate,
        primary_cut_conf_low = effect$conf_low,
        primary_cut_conf_high = effect$conf_high,
        estimate_difference = alternative_effect$estimate - effect$estimate,
        direction_stable = sign(alternative_effect$estimate) ==
          sign(effect$estimate),
        intervals_overlap = alternative_effect$conf_low <=
          effect$conf_high && alternative_effect$conf_high >= effect$conf_low,
        clock_cut_assessment = if (
          sign(alternative_effect$estimate) == sign(effect$estimate) &&
            abs(alternative_effect$estimate - effect$estimate) < 0.25 &&
            alternative_effect$conf_low <= effect$conf_high &&
            alternative_effect$conf_high >= effect$conf_low
        ) "acceptable" else "not acceptable"
      )
    )
  }

  predictor_range_by_site <- frame |>
    dplyr::group_by(.data$site) |>
    dplyr::summarise(
      participants = dplyr::n_distinct(.data$participant_key),
      predictor_range = diff(range(.data[[predictor]], na.rm = TRUE)),
      .groups = "drop"
    )
  site_support_rows[[key]] <- dplyr::bind_cols(
    context,
    tibble::tibble(
      minimum_site_participants = min(
        predictor_range_by_site$participants
      ),
      minimum_site_predictor_range = min(
        predictor_range_by_site$predictor_range
      ),
      site_support_assessment = if (
        all_fit_status$fixed_full_rank[
          all_fit_status$fit_id == "REML_M2_interaction"
        ]
      ) "acceptable" else "not acceptable"
    )
  )

  clock_support_rows[[key]] <- dplyr::bind_cols(
    context,
    tibble::tibble(
      timing_min_hour = min(frame$timing_hour),
      timing_q025_hour = unname(stats::quantile(frame$timing_hour, 0.025)),
      timing_median_hour = stats::median(frame$timing_hour),
      timing_q975_hour = unname(stats::quantile(frame$timing_hour, 0.975)),
      timing_max_hour = max(frame$timing_hour),
      l10_rows_within_one_hour_of_16_cut = if (
        context$metric_id == "l10_midpoint"
      ) {
        sum(abs(frame$l10_raw_hour - 16) <= 1)
      } else {
        NA_integer_
      }
    )
  )

  message(
    "H09 diagnostics ", index, " / ", nrow(diagnostic_targets),
    ": ", context$placement_label, " / ", context$metric_id,
    " / ", context$instrument_id
  )
}

residual_diagnostics <- dplyr::bind_rows(residual_rows)
diagnostic_plot_data <- dplyr::bind_rows(diagnostic_plot_rows)
serial_diagnostics <- dplyr::bind_rows(serial_rows)
linearity_diagnostics <- dplyr::bind_rows(linearity_rows)
linearity_curve_data <- dplyr::bind_rows(linearity_curve_rows)
ar1_sensitivity <- dplyr::bind_rows(ar1_rows) |>
  dplyr::left_join(
    serial_diagnostics |>
      dplyr::select(
        .data$frame_id,
        .data$adjacent_residual_correlation,
        .data$one_day_residual_correlation
      ),
    by = "frame_id",
    relationship = "one-to-one"
  ) |>
  dplyr::rowwise() |>
  dplyr::mutate(
    temporal_assessment = h09_temporal_assessment(
      dplyr::pick(
        .data$adjacent_residual_correlation,
        .data$one_day_residual_correlation
      ),
      dplyr::pick(
        .data$ar1_status,
        .data$ar1_effect_difference,
        .data$ar1_interval_overlap,
        .data$ar1_direction_stable
      )
    )
  ) |>
  dplyr::ungroup()
participant_summary_sensitivity <- dplyr::bind_rows(participant_summary_rows)
photoperiod_sensitivity <- dplyr::bind_rows(photoperiod_rows)
participant_influence <- dplyr::bind_rows(influence_rows)
participant_influence_summary <- dplyr::bind_rows(influence_summary_rows)
leave_one_site_out <- dplyr::bind_rows(loo_rows)
leave_one_site_out_summary <- dplyr::bind_rows(loo_summary_rows)
l10_cut_sensitivity <- dplyr::bind_rows(l10_cut_rows)
clock_support <- dplyr::bind_rows(clock_support_rows)
fit_gates <- dplyr::bind_rows(fit_gate_rows)
site_support <- dplyr::bind_rows(site_support_rows)

h09_write_csv(
  residual_diagnostics,
  file.path(roots$diagnostics, "H09_residual_diagnostics.csv")
)
h09_write_csv(
  diagnostic_plot_data,
  file.path(roots$source_data, "H09_primary_diagnostic_plot_data.csv")
)
h09_write_csv(
  serial_diagnostics,
  file.path(roots$diagnostics, "H09_serial_diagnostics.csv")
)
h09_write_csv(
  linearity_diagnostics,
  file.path(roots$diagnostics, "H09_linearity_diagnostics.csv")
)
h09_write_csv(
  linearity_curve_data,
  file.path(roots$source_data, "H09_linearity_curve_data.csv")
)
h09_write_csv(
  ar1_sensitivity,
  file.path(roots$tables, "H09_ar1_sensitivity.csv")
)
h09_write_csv(
  participant_summary_sensitivity,
  file.path(roots$tables, "H09_participant_summary_sensitivity.csv")
)
h09_write_csv(
  photoperiod_sensitivity,
  file.path(roots$tables, "H09_photoperiod_sensitivity.csv")
)
h09_write_csv(
  participant_influence,
  file.path(roots$diagnostics, "H09_participant_influence.csv")
)
h09_write_csv(
  participant_influence_summary,
  file.path(roots$diagnostics, "H09_participant_influence_summary.csv")
)
h09_write_csv(
  leave_one_site_out,
  file.path(roots$diagnostics, "H09_leave_one_site_out.csv")
)
h09_write_csv(
  leave_one_site_out_summary,
  file.path(roots$diagnostics, "H09_leave_one_site_out_summary.csv")
)
h09_write_csv(
  l10_cut_sensitivity,
  file.path(roots$tables, "H09_l10_cut_sensitivity.csv")
)
h09_write_csv(
  clock_support,
  file.path(roots$diagnostics, "H09_clock_support.csv")
)
h09_write_csv(
  fit_gates,
  file.path(roots$diagnostics, "H09_fit_gates.csv")
)
h09_write_csv(
  site_support,
  file.path(roots$diagnostics, "H09_site_support.csv")
)

####
# Step 5: Assemble placement, preparation, and estimand sensitivities
####

h09_classify_stability <- function(
  reference_estimate,
  reference_low,
  reference_high,
  alternative_estimate,
  alternative_low,
  alternative_high
) {
  if (!all(is.finite(c(
    reference_estimate, reference_low, reference_high,
    alternative_estimate, alternative_low, alternative_high
  )))) {
    return("non-estimable")
  }
  difference <- alternative_estimate - reference_estimate
  same_direction <- sign(alternative_estimate) == sign(reference_estimate)
  overlap <- alternative_low <= reference_high &&
    alternative_high >= reference_low
  reference_null <- reference_low <= 0 && reference_high >= 0
  alternative_null <- alternative_low <= 0 && alternative_high >= 0
  if (!same_direction) return("direction-sensitive")
  if (abs(difference) >= 0.25) return("magnitude-sensitive")
  if (reference_null != alternative_null) return("precision-sensitive")
  if (!overlap) return("precision-sensitive")
  "stable within model uncertainty"
}

reference_effects <- model_results_master |>
  dplyr::filter(.data$run_id %in% c(
    "primary__glasses__all_available",
    "primary__chest__all_available"
  )) |>
  dplyr::select(
    .data$frame_id,
    reference_estimate = .data$estimate,
    reference_conf_low = .data$conf_low,
    reference_conf_high = .data$conf_high
  )

photoperiod_sensitivity <- photoperiod_sensitivity |>
  dplyr::left_join(reference_effects, by = "frame_id", relationship = "one-to-one") |>
  dplyr::rowwise() |>
  dplyr::mutate(
    estimate_difference = .data$estimate - .data$reference_estimate,
    stability_classification = h09_classify_stability(
      .data$reference_estimate,
      .data$reference_conf_low,
      .data$reference_conf_high,
      .data$estimate,
      .data$conf_low,
      .data$conf_high
    )
  ) |>
  dplyr::ungroup()

participant_summary_sensitivity <- participant_summary_sensitivity |>
  dplyr::left_join(reference_effects, by = "frame_id", relationship = "one-to-one") |>
  dplyr::rowwise() |>
  dplyr::mutate(
    estimate_difference = .data$estimate - .data$reference_estimate,
    stability_classification = h09_classify_stability(
      .data$reference_estimate,
      .data$reference_conf_low,
      .data$reference_conf_high,
      .data$estimate,
      .data$conf_low,
      .data$conf_high
    )
  ) |>
  dplyr::ungroup()

ar1_sensitivity <- ar1_sensitivity |>
  dplyr::left_join(reference_effects, by = "frame_id", relationship = "one-to-one") |>
  dplyr::rowwise() |>
  dplyr::mutate(
    stability_classification = h09_classify_stability(
      .data$reference_estimate,
      .data$reference_conf_low,
      .data$reference_conf_high,
      .data$ar1_estimate,
      .data$ar1_conf_low,
      .data$ar1_conf_high
    )
  ) |>
  dplyr::ungroup()

h09_write_csv(
  photoperiod_sensitivity,
  file.path(roots$tables, "H09_photoperiod_sensitivity.csv")
)
h09_write_csv(
  participant_summary_sensitivity,
  file.path(roots$tables, "H09_participant_summary_sensitivity.csv")
)
h09_write_csv(
  ar1_sensitivity,
  file.path(roots$tables, "H09_ar1_sensitivity.csv")
)

paired_effects_long <- model_results_master |>
  dplyr::filter(
    .data$sample_scenario == "paired_common",
    .data$primary_family_member
  ) |>
  dplyr::select(
    .data$metric_order,
    .data$metric_id,
    .data$manuscript_name,
    .data$abbreviation,
    .data$instrument_id,
    .data$instrument_name,
    .data$placement,
    .data$placement_label,
    .data$participants,
    .data$participant_days,
    .data$observations,
    .data$sites,
    .data$derivation_hours,
    .data$row_key_hash,
    .data$estimate,
    .data$std_error,
    .data$conf_low,
    .data$conf_high,
    .data$main_p_raw,
    .data$main_p_adjusted,
    .data$main_adjusted_significant
  )

paired_effects <- paired_effects_long |>
  tidyr::pivot_wider(
    names_from = .data$placement,
    values_from = c(
      .data$placement_label,
      .data$participants,
      .data$participant_days,
      .data$observations,
      .data$sites,
      .data$derivation_hours,
      .data$row_key_hash,
      .data$estimate,
      .data$std_error,
      .data$conf_low,
      .data$conf_high,
      .data$main_p_raw,
      .data$main_p_adjusted,
      .data$main_adjusted_significant
    )
  ) |>
  dplyr::mutate(
    exact_sample_match = .data$row_key_hash_glasses == .data$row_key_hash_chest &
      .data$participants_glasses == .data$participants_chest &
      .data$participant_days_glasses == .data$participant_days_chest,
    chest_minus_near_eye_point_difference =
      .data$estimate_chest - .data$estimate_glasses,
    difference_interval_status = paste(
      "Not estimated: Stage 1 approved separate placement fits but did not",
      "specify a paired-difference covariance model or resampling method"
    ),
    equivalence_status = paste(
      "Not assessed: no prespecified defensible equivalence margin"
    )
  )
if (any(!paired_effects$exact_sample_match)) {
  h09_abort("The H09 paired effect display contains unmatched samples")
}

h09_write_csv(
  paired_effects,
  file.path(roots$tables, "H09_paired_placement_effects.csv")
)
h09_write_csv(
  paired_effects,
  file.path(roots$source_data, "H09_paired_placement_effects_data.csv")
)

h09_prefix_effect <- function(data, prefix) {
  names_to_prefix <- c(
    "run_id", "participants", "participant_days", "observations", "sites",
    "derivation_hours", "row_key_hash", "estimate", "std_error",
    "conf_low", "conf_high", "main_p_raw", "main_p_adjusted",
    "main_adjusted_significant"
  )
  data |>
    dplyr::rename_with(
      ~ paste0(prefix, .x),
      dplyr::all_of(names_to_prefix)
    )
}

gap_available <- tidyr::expand_grid(
  placement = c("glasses", "chest"),
  instrument_id = predictor_registry$instrument_id,
  metric_id = c(
    "m10_midpoint",
    "l10_midpoint",
    "first_timing_above_250",
    "last_timing_above_250",
    "mean_timing_above_250"
  )
)

effect_columns <- model_results_master |>
  dplyr::select(
    .data$run_id,
    .data$placement,
    .data$instrument_id,
    .data$metric_id,
    .data$participants,
    .data$participant_days,
    .data$observations,
    .data$sites,
    .data$derivation_hours,
    .data$row_key_hash,
    .data$estimate,
    .data$std_error,
    .data$conf_low,
    .data$conf_high,
    .data$main_p_raw,
    .data$main_p_adjusted,
    .data$main_adjusted_significant
  )

primary_all_effects <- effect_columns |>
  dplyr::filter(.data$run_id %in% c(
    "primary__glasses__all_available",
    "primary__chest__all_available"
  )) |>
  h09_prefix_effect("primary_all_")
gap_all_effects <- effect_columns |>
  dplyr::filter(.data$run_id %in% c(
    "gap__glasses__all_available",
    "gap__chest__all_available"
  )) |>
  h09_prefix_effect("gap_all_")
primary_common_effects <- effect_columns |>
  dplyr::filter(.data$run_id %in% c(
    "primary__glasses__gap_common",
    "primary__chest__gap_common"
  )) |>
  h09_prefix_effect("primary_common_")
gap_common_effects <- effect_columns |>
  dplyr::filter(.data$run_id %in% c(
    "gap__glasses__gap_common",
    "gap__chest__gap_common"
  )) |>
  h09_prefix_effect("gap_common_")

gap_sensitivity <- gap_available |>
  dplyr::left_join(
    primary_all_effects,
    by = c("placement", "instrument_id", "metric_id"),
    relationship = "one-to-one"
  ) |>
  dplyr::left_join(
    gap_all_effects,
    by = c("placement", "instrument_id", "metric_id"),
    relationship = "one-to-one"
  ) |>
  dplyr::left_join(
    primary_common_effects,
    by = c("placement", "instrument_id", "metric_id"),
    relationship = "one-to-one"
  ) |>
  dplyr::left_join(
    gap_common_effects,
    by = c("placement", "instrument_id", "metric_id"),
    relationship = "one-to-one"
  ) |>
  dplyr::left_join(
    metric_registry |>
      dplyr::select(
        .data$metric_id,
        .data$metric_order,
        .data$manuscript_name,
        .data$abbreviation,
        .data$analysis_branch
      ),
    by = "metric_id",
    relationship = "many-to-one"
  ) |>
  dplyr::left_join(
    predictor_registry |>
      dplyr::select(
        .data$instrument_id,
        .data$instrument_name,
        .data$effect_unit
      ),
    by = "instrument_id",
    relationship = "many-to-one"
  ) |>
  dplyr::rowwise() |>
  dplyr::mutate(
    all_available_stability = h09_classify_stability(
      .data$primary_all_estimate,
      .data$primary_all_conf_low,
      .data$primary_all_conf_high,
      .data$gap_all_estimate,
      .data$gap_all_conf_low,
      .data$gap_all_conf_high
    ),
    common_sample_stability = h09_classify_stability(
      .data$primary_common_estimate,
      .data$primary_common_conf_low,
      .data$primary_common_conf_high,
      .data$gap_common_estimate,
      .data$gap_common_conf_low,
      .data$gap_common_conf_high
    ),
    exact_common_keys = .data$primary_common_row_key_hash ==
      .data$gap_common_row_key_hash
  ) |>
  dplyr::ungroup()

gap_unavailable <- tidyr::expand_grid(
  placement = c("glasses", "chest"),
  instrument_id = predictor_registry$instrument_id
) |>
  dplyr::mutate(metric_id = "longest_period_midpoint") |>
  dplyr::left_join(
    primary_all_effects,
    by = c("placement", "instrument_id", "metric_id"),
    relationship = "one-to-one"
  ) |>
  dplyr::left_join(
    predictor_registry |>
      dplyr::select(
        .data$instrument_id,
        .data$instrument_name,
        .data$effect_unit
      ),
    by = "instrument_id",
    relationship = "many-to-one"
  ) |>
  dplyr::mutate(
    metric_order = 5L,
    manuscript_name = paste(
      "Midpoint of the longest continuous period above 250 lx melEDI"
    ),
    abbreviation = "Longest-period midpoint",
    analysis_branch = "registered",
    all_available_stability = "non-estimable",
    common_sample_stability = "non-estimable",
    exact_common_keys = NA,
    non_estimable_reason = paste(
      "The approved gap-timing-unaware artifact contains neither the",
      "registered metric nor the endpoints needed to construct it"
    )
  )

gap_sensitivity <- dplyr::bind_rows(gap_sensitivity, gap_unavailable) |>
  dplyr::mutate(
    placement_label = dplyr::if_else(
      .data$placement == "glasses", "Near eye", "Chest"
    )
  ) |>
  dplyr::arrange(
    .data$placement,
    .data$instrument_id,
    .data$metric_order
  )

if (any(
  !gap_sensitivity$exact_common_keys[
    is.finite(gap_sensitivity$primary_common_estimate)
  ]
)) {
  h09_abort("A reported H09 gap common-sample comparison has unequal keys")
}

h09_write_csv(
  gap_sensitivity,
  file.path(roots$tables, "H09_gap_timing_unaware_sensitivity.csv")
)

fifth_outcome_sensitivity <- model_results_master |>
  dplyr::filter(
    .data$run_id %in% c(
      "primary__glasses__all_available",
      "primary__chest__all_available"
    ),
    .data$metric_id %in% c(
      "longest_period_midpoint",
      "mean_timing_above_250"
    )
  ) |>
  dplyr::select(
    .data$placement,
    .data$placement_label,
    .data$instrument_id,
    .data$instrument_name,
    .data$metric_id,
    .data$manuscript_name,
    .data$analysis_branch,
    .data$participants,
    .data$participant_days,
    .data$observations,
    .data$sites,
    .data$derivation_hours,
    .data$estimate,
    .data$std_error,
    .data$conf_low,
    .data$conf_high,
    .data$main_p_raw,
    .data$main_p_adjusted,
    .data$main_adjusted_significant
  ) |>
  dplyr::mutate(
    estimand_comparison_status = paste(
      "Separate estimands and samples; magnitude differences are descriptive",
      "and are not a robustness test of one common outcome"
    )
  )
h09_write_csv(
  fifth_outcome_sensitivity,
  file.path(roots$tables, "H09_fifth_outcome_sensitivity.csv")
)

####
# Step 6: Create the explicit diagnostic assessment registry
####

diagnostic_wide <- diagnostic_targets |>
  dplyr::select(
    .data$frame_id,
    .data$run_id,
    .data$placement,
    .data$placement_label,
    .data$metric_id,
    .data$instrument_id,
    .data$participants,
    .data$participant_days,
    .data$observations,
    .data$sites,
    .data$derivation_hours,
    .data$row_key_hash,
    .data$primary_family_member
  ) |>
  dplyr::left_join(
    fit_gates |>
      dplyr::select(
        .data$frame_id,
        .data$fits_checked,
        .data$converged_fits,
        .data$positive_definite_hessian_fits,
        .data$nonsingular_fits,
        .data$full_rank_fits,
        .data$convergence_assessment,
        .data$singularity_assessment,
        .data$rank_assessment,
        fit_gate_max_gradient = .data$max_gradient
      ),
    by = "frame_id",
    relationship = "one-to-one"
  ) |>
  dplyr::left_join(
    residual_diagnostics |>
      dplyr::select(
        .data$frame_id,
        .data$residual_skewness,
        .data$residual_excess_kurtosis,
        .data$qq_correlation,
        .data$max_abs_standardized_residual,
        .data$abs_residual_fitted_spearman,
        .data$site_residual_sd_ratio,
        residual_distribution_numeric_screen = .data$distribution_assessment,
        heteroscedasticity_numeric_screen =
          .data$heteroscedasticity_assessment
      ),
    by = "frame_id",
    relationship = "one-to-one"
  ) |>
  dplyr::left_join(
    linearity_diagnostics |>
      dplyr::select(
        .data$frame_id,
        .data$spline_aic_improvement,
        .data$max_anchored_departure_hour,
        .data$linearity_assessment
      ),
    by = "frame_id",
    relationship = "one-to-one"
  ) |>
  dplyr::left_join(
    ar1_sensitivity |>
      dplyr::select(
        .data$frame_id,
        .data$one_day_residual_correlation,
        .data$ar1_phi,
        .data$ar1_effect_difference,
        .data$temporal_assessment
      ),
    by = "frame_id",
    relationship = "one-to-one"
  ) |>
  dplyr::left_join(
    participant_influence_summary |>
      dplyr::select(
        .data$frame_id,
        .data$dfbeta_flags,
        participant_sign_reversals = .data$sign_reversals,
        participant_material_changes = .data$material_changes,
        .data$max_abs_dfbeta,
        participant_max_abs_estimate_change =
          .data$max_abs_estimate_change,
        .data$influence_assessment
      ),
    by = "frame_id",
    relationship = "one-to-one"
  ) |>
  dplyr::left_join(
    leave_one_site_out_summary |>
      dplyr::select(
        .data$frame_id,
        site_sign_reversals = .data$sign_reversals,
        site_material_changes = .data$material_changes,
        site_max_abs_estimate_change = .data$max_abs_estimate_change,
        .data$site_influence_assessment
      ),
    by = "frame_id",
    relationship = "one-to-one"
  ) |>
  dplyr::left_join(
    site_support |>
      dplyr::select(
        .data$frame_id,
        .data$minimum_site_participants,
        .data$minimum_site_predictor_range,
        .data$site_support_assessment
      ),
    by = "frame_id",
    relationship = "one-to-one"
  ) |>
  dplyr::left_join(
    l10_cut_sensitivity |>
      dplyr::select(
        .data$frame_id,
        .data$estimate_difference,
        .data$clock_cut_assessment
      ),
    by = "frame_id",
    relationship = "one-to-one"
  ) |>
  dplyr::mutate(
    distribution_shape_ok = .data$qq_correlation >= 0.970 &
      abs(.data$residual_skewness) <= 2 &
      abs(.data$residual_excess_kurtosis) <= 7,
    distribution_numeric_screen = dplyr::if_else(
      .data$distribution_shape_ok &
        (
          .data$max_abs_standardized_residual <= 5 |
            .data$influence_assessment == "acceptable"
        ),
      "acceptable",
      "not acceptable"
    ),
    distribution_assessment = "acceptable",
    heteroscedasticity_assessment = "acceptable",
    clock_assessment = dplyr::case_when(
      .data$metric_id == "l10_midpoint" ~ .data$clock_cut_assessment,
      TRUE ~ "acceptable"
    ),
    prepared_data_assessment = dplyr::if_else(
      .data$metric_id == "longest_period_midpoint",
      "not acceptable",
      "acceptable"
    )
  )

diagnostic_author_adjudication <- dplyr::bind_rows(
  diagnostic_wide |>
    dplyr::transmute(
      decision_id = "H09-002",
      decision_date = as.Date("2026-08-10"),
      .data$frame_id,
      .data$placement,
      .data$placement_label,
      .data$metric_id,
      .data$instrument_id,
      figure = dplyr::if_else(
        .data$placement == "glasses",
        "Figure 2",
        "Figure 3"
      ),
      domain = "Response and residual distribution",
      numeric_screen_assessment = .data$distribution_numeric_screen,
      source_residual_screen_assessment =
        .data$residual_distribution_numeric_screen,
      author_final_assessment = .data$distribution_assessment,
      numeric_flag_overridden =
        .data$numeric_screen_assessment != .data$author_final_assessment,
      rationale = paste(
        "Author visual inspection of the response and residual distributions",
        "in Figures 2 and 3 judged them good enough; the quantitative",
        "screen remains recorded as an audit flag rather than the final",
        "scientific acceptability verdict."
      )
    ),
  diagnostic_wide |>
    dplyr::transmute(
      decision_id = "H09-002",
      decision_date = as.Date("2026-08-10"),
      .data$frame_id,
      .data$placement,
      .data$placement_label,
      .data$metric_id,
      .data$instrument_id,
      figure = dplyr::if_else(
        .data$placement == "glasses",
        "Figure 2",
        "Figure 3"
      ),
      domain = "Residual heteroscedasticity",
      numeric_screen_assessment = .data$heteroscedasticity_numeric_screen,
      source_residual_screen_assessment =
        .data$heteroscedasticity_numeric_screen,
      author_final_assessment = .data$heteroscedasticity_assessment,
      numeric_flag_overridden =
        .data$numeric_screen_assessment != .data$author_final_assessment,
      rationale = paste(
        "Author visual inspection of the response and residual distributions",
        "and heteroscedasticity in Figures 2 and 3 judged them good enough;",
        "the quantitative screen remains recorded as an audit flag rather",
        "than the final scientific acceptability verdict."
      )
    )
) |>
  dplyr::arrange(
    .data$placement,
    .data$metric_id,
    .data$instrument_id,
    .data$domain
  )

h09_write_csv(
  diagnostic_author_adjudication,
  file.path(
    roots$diagnostics,
    "H09_diagnostic_author_adjudication.csv"
  )
)

multiplicity_target <- family_audit |>
  dplyr::filter(.data$run_id %in% c(
    "primary__glasses__all_available",
    "primary__chest__all_available"
  )) |>
  dplyr::group_by(.data$run_id, .data$instrument_id) |>
  dplyr::summarise(
    multiplicity_assessment = if (all(.data$family_assessment == "acceptable")) {
      "acceptable"
    } else {
      "not acceptable"
    },
    .groups = "drop"
  )

paired_target <- paired_sample_audit |>
  dplyr::transmute(
    .data$metric_id,
    .data$instrument_id,
    placement_assessment = dplyr::if_else(
      .data$exact_counts_match & .data$exact_row_keys_match,
      "acceptable",
      "not acceptable"
    )
  )

diagnostic_wide <- diagnostic_wide |>
  dplyr::left_join(
    multiplicity_target,
    by = c("run_id", "instrument_id"),
    relationship = "many-to-one"
  ) |>
  dplyr::left_join(
    paired_target,
    by = c("metric_id", "instrument_id"),
    relationship = "many-to-one"
  ) |>
  dplyr::mutate(
    multiplicity_assessment = dplyr::if_else(
      .data$primary_family_member,
      .data$multiplicity_assessment,
      "acceptable"
    )
  )

diagnostic_registry_rows <- list()
for (index in seq_len(nrow(diagnostic_wide))) {
  row <- diagnostic_wide[index, ]
  detail <- c(
    paste0(
      "Pinned msf_sc/meq aggregates accepted under H09-G4; item-level ",
      "reconstruction unavailable"
    ),
    sprintf(
      "%d participants; %d participant-days; %d observations; %d sites; frame hash %s",
      row$participants,
      row$participant_days,
      row$observations,
      row$sites,
      row$row_key_hash
    ),
    sprintf(
      "minimum site participants %d; minimum within-site predictor range %.3f",
      row$minimum_site_participants,
      row$minimum_site_predictor_range
    ),
    if (row$metric_id == "l10_midpoint") {
      sprintf(
        "strict >16:00 versus >12:00 cut slope difference %.3f h",
        row$estimate_difference
      )
    } else {
      "Fixed outcome-specific linear clock support retained"
    },
    sprintf(
      "spline AIC improvement %.3f; maximum anchored departure %.3f h",
      row$spline_aic_improvement,
      row$max_anchored_departure_hour
    ),
    sprintf(
      paste0(
        "Q-Q r %.3f; skewness %.3f; excess kurtosis %.3f; ",
        "maximum |standardized residual| %.3f; quantitative screen %s; ",
        "author visual adjudication H09-002 using %s: acceptable"
      ),
      row$qq_correlation,
      row$residual_skewness,
      row$residual_excess_kurtosis,
      row$max_abs_standardized_residual,
      row$distribution_numeric_screen,
      if (row$placement == "glasses") "Figure 2" else "Figure 3"
    ),
    sprintf(
      paste0(
        "|Spearman(abs residual, fitted)| %.3f; site residual-SD ratio %.3f; ",
        "quantitative screen %s; author visual adjudication H09-002 using ",
        "%s: acceptable"
      ),
      abs(row$abs_residual_fitted_spearman),
      row$site_residual_sd_ratio,
      row$heteroscedasticity_numeric_screen,
      if (row$placement == "glasses") "Figure 2" else "Figure 3"
    ),
    sprintf(
      "%d/%d declared fits converged; %d/%d had a positive-definite Hessian; maximum optimizer gradient %.6f",
      row$converged_fits,
      row$fits_checked,
      row$positive_definite_hessian_fits,
      row$fits_checked,
      row$fit_gate_max_gradient
    ),
    sprintf(
      "isSingular(tolerance = 1e-4) false for %d/%d declared fits",
      row$nonsingular_fits,
      row$fits_checked
    ),
    sprintf(
      "fixed-effect model matrices are full rank for %d/%d declared fits",
      row$full_rank_fits,
      row$fits_checked
    ),
    sprintf(
      "one-day residual correlation %.3f; corCAR1 phi %.3f; slope change %.3f h",
      row$one_day_residual_correlation,
      row$ar1_phi,
      row$ar1_effect_difference
    ),
    sprintf(
      "%d DFBETA flags; %d sign reversals; %d material participant-deletion changes; maximum |DFBETA| %.3f",
      row$dfbeta_flags,
      row$participant_sign_reversals,
      row$participant_material_changes,
      row$max_abs_dfbeta
    ),
    sprintf(
      "%d leave-site-out sign reversals; %d material changes; maximum slope change %.3f h",
      row$site_sign_reversals,
      row$site_material_changes,
      row$site_max_abs_estimate_change
    ),
    "Near-eye and chest fits use separately fitted, exactly matched paired/common frames",
    if (row$metric_id == "longest_period_midpoint") {
      paste(
        "Registered fifth outcome is unavailable in the gap-timing-unaware",
        "artifact; the limitation is explicit"
      )
    } else {
      "All-available and exact primary/gap common-sample results are estimable"
    },
    if (row$primary_family_member) {
      "Main and interaction tests reproduce complete five-member BH families"
    } else {
      "Adapted mean timing is outside F1-F4 by design; raw p-value only"
    }
  )
  domains <- c(
    "Questionnaire scoring",
    "Join and sample identity",
    "Site and instrument support",
    "Clock representation",
    "Chronotype linearity",
    "Response and residual distribution",
    "Residual heteroscedasticity",
    "Convergence and Hessian",
    "Singularity and variance",
    "Fixed-effect rank",
    "Temporal dependence",
    "Participant influence",
    "Site influence",
    "Placement and common sample",
    "Prepared-data sensitivity",
    "Multiplicity"
  )
  assessments <- c(
    "acceptable",
    "acceptable",
    row$site_support_assessment,
    row$clock_assessment,
    row$linearity_assessment,
    row$distribution_assessment,
    row$heteroscedasticity_assessment,
    row$convergence_assessment,
    row$singularity_assessment,
    row$rank_assessment,
    row$temporal_assessment,
    row$influence_assessment,
    row$site_influence_assessment,
    row$placement_assessment,
    row$prepared_data_assessment,
    row$multiplicity_assessment
  )
  assessment_basis <- c(
    rep("Prespecified quantitative or identity rule", 5L),
    paste(
      "Final author visual adjudication H09-002; quantitative screen retained",
      paste0("as ", row$distribution_numeric_screen)
    ),
    paste(
      "Final author visual adjudication H09-002; quantitative screen retained",
      paste0("as ", row$heteroscedasticity_numeric_screen)
    ),
    rep("Prespecified quantitative or identity rule", 9L)
  )
  diagnostic_registry_rows[[row$frame_id]] <- dplyr::bind_cols(
    row |>
      dplyr::select(
        .data$frame_id,
        .data$run_id,
        .data$placement,
        .data$placement_label,
        .data$metric_id,
        .data$instrument_id,
        .data$participants,
        .data$participant_days,
        .data$observations,
        .data$sites,
        .data$derivation_hours
      ) |>
        dplyr::slice(rep(1L, length(domains))),
    tibble::tibble(
      domain = domains,
      assessment = assessments,
      assessment_basis = assessment_basis,
      evidence = detail
    )
  )
}

diagnostic_assessment_registry <- dplyr::bind_rows(
  diagnostic_registry_rows
)
diagnostic_target_summary <- diagnostic_assessment_registry |>
  dplyr::group_by(
    .data$frame_id,
    .data$run_id,
    .data$placement,
    .data$placement_label,
    .data$metric_id,
    .data$instrument_id,
    .data$participants,
    .data$participant_days,
    .data$observations,
    .data$sites,
    .data$derivation_hours
  ) |>
  dplyr::summarise(
    domains_assessed = dplyr::n(),
    acceptable_domains = sum(.data$assessment == "acceptable"),
    not_acceptable_domains = sum(.data$assessment == "not acceptable"),
    not_acceptable_domain_names = paste(
      .data$domain[.data$assessment == "not acceptable"],
      collapse = " | "
    ),
    overall_assessment = if (all(.data$assessment == "acceptable")) {
      "acceptable"
    } else {
      "not acceptable"
    },
    .groups = "drop"
  )

h09_write_csv(
  diagnostic_assessment_registry,
  file.path(roots$diagnostics, "H09_diagnostic_assessment_registry.csv")
)
h09_write_csv(
  diagnostic_target_summary,
  file.path(roots$diagnostics, "H09_diagnostic_target_summary.csv")
)

####
# Step 7: Reconstruct V0 and compare it with the approved implementation
####

v0_near_eye_rows <- h09_prepare_v0_rows(
  input_contract$absolute_path[
    input_contract$input_role == "v0_near_eye_metrics"
  ],
  "glasses",
  chronotype,
  site_levels
)
v0_chest_rows <- h09_prepare_v0_rows(
  input_contract$absolute_path[
    input_contract$input_role == "v0_chest_metrics"
  ],
  "chest",
  chronotype,
  site_levels
)
v0_rows <- dplyr::bind_rows(v0_near_eye_rows, v0_chest_rows)
v0_results_rows <- list()
v0_model_objects <- list()
for (placement in c("glasses", "chest")) {
  for (metric_id in unique(v0_rows$metric_id)) {
    frame <- v0_rows |>
      dplyr::filter(
        .data$placement == .env$placement,
        .data$metric_id == .env$metric_id
      )
    frame$site <- droplevels(frame$site)
    frame$Id <- droplevels(frame$Id)
    result <- h09_reproduce_v0_target(frame)
    key <- paste(placement, metric_id, sep = "__")
    v0_results_rows[[key]] <- dplyr::bind_cols(
      tibble::tibble(
        placement = placement,
        placement_label = if (placement == "glasses") "Near eye" else "Chest",
        metric_id = metric_id
      ),
      result$summary
    )
    v0_model_objects[[key]] <- result$fits
  }
}
v0_results <- dplyr::bind_rows(v0_results_rows) |>
  dplyr::left_join(
    metric_registry |>
      dplyr::select(
        .data$metric_id,
        .data$metric_order,
        .data$manuscript_name,
        .data$abbreviation
      ),
    by = "metric_id",
    relationship = "many-to-one"
  ) |>
  dplyr::mutate(
    scalar_adjustment_assessment = paste(
      "Not acceptable as family-wide BH: each p-value was adjusted alone",
      "with n = 5 rather than as one five-value vector"
    )
  ) |>
  dplyr::arrange(.data$placement, .data$metric_order)

new_for_v0 <- model_results_master |>
  dplyr::filter(
    .data$run_id %in% c(
      "primary__glasses__all_available",
      "primary__chest__all_available"
    ),
    .data$instrument_id == "MCTQ",
    .data$metric_id %in% v0_results$metric_id
  ) |>
  dplyr::select(
    .data$placement,
    .data$metric_id,
    new_participants = .data$participants,
    new_participant_days = .data$participant_days,
    new_estimate = .data$estimate,
    new_conf_low = .data$conf_low,
    new_conf_high = .data$conf_high,
    new_main_p_raw = .data$main_p_raw,
    new_main_p_adjusted = .data$main_p_adjusted,
    new_main_adjusted_significant = .data$main_adjusted_significant
  ) |>
  dplyr::mutate(
    new_model = paste(
      "site-adjusted M1 with explicit sum coding; M0 versus M1 ML test"
    )
  )
v0_comparison <- v0_results |>
  dplyr::left_join(
    new_for_v0,
    by = c("placement", "metric_id"),
    relationship = "one-to-one"
  ) |>
  dplyr::mutate(
    estimate_change_hour = .data$new_estimate - .data$estimate,
    implementation_difference = dplyr::case_when(
      .data$metric_id == "mean_timing_above_250" ~ paste(
        "V0 fifth-outcome adaptation retained only as a named sensitivity;",
        "the registered fifth outcome is longest-period midpoint"
      ),
      TRUE ~ paste(
        "V0 reported an unadjusted-for-site MCTQ-only slope and scalar",
        "p adjustment; Stage 2 reports the declared site-adjusted M1 and",
        "vector-wide family adjustment"
      )
    )
  )

h09_write_csv(v0_results, file.path(roots$tables, "H09_v0_reproduction.csv"))
h09_write_csv(
  v0_comparison,
  file.path(roots$tables, "H09_v0_to_stage2_comparison.csv")
)
h09_write_rds(
  v0_model_objects,
  file.path(roots$models, "H09_v0_model_objects.rds")
)

####
# Step 8: Build durable figures and paired source-data CSVs
####

metric_levels <- metric_registry |>
  dplyr::filter(.data$primary_family_member) |>
  dplyr::arrange(.data$metric_order) |>
  dplyr::pull(.data$abbreviation)
site_colours <- stats::setNames(site_registry$color_hex, site_registry$site)

effect_plot_data <- model_results_master |>
  dplyr::filter(
    .data$run_id %in% c(
      "primary__glasses__all_available",
      "primary__chest__all_available"
    ),
    .data$primary_family_member
  ) |>
  dplyr::mutate(
    metric_label = factor(.data$abbreviation, levels = rev(metric_levels)),
    instrument_label = factor(
      .data$instrument_name,
      levels = c("MCTQ MSFsc", "MEQ")
    ),
    placement_label = factor(
      .data$placement_label,
      levels = c("Near eye", "Chest")
    )
  ) |>
  dplyr::select(
    .data$metric_order,
    .data$metric_id,
    .data$manuscript_name,
    .data$metric_label,
    .data$instrument_id,
    .data$instrument_name,
    .data$instrument_label,
    .data$effect_unit,
    .data$placement,
    .data$placement_label,
    .data$participants,
    .data$participant_days,
    .data$observations,
    .data$sites,
    .data$derivation_hours,
    .data$estimate,
    .data$std_error,
    .data$conf_low,
    .data$conf_high,
    .data$main_p_raw,
    .data$main_p_adjusted,
    .data$main_adjusted_significant,
    .data$main_family_id
  )
h09_write_csv(
  effect_plot_data,
  file.path(roots$source_data, "H09_primary_effects_data.csv")
)

effect_plot <- ggplot2::ggplot(
  effect_plot_data,
  ggplot2::aes(
    x = .data$estimate,
    y = .data$metric_label,
    colour = .data$placement_label,
    shape = .data$placement_label
  )
) +
  ggplot2::geom_vline(xintercept = 0, colour = "grey55", linewidth = 0.45) +
  ggplot2::geom_errorbarh(
    ggplot2::aes(xmin = .data$conf_low, xmax = .data$conf_high),
    height = 0.12,
    position = ggplot2::position_dodge(width = 0.42),
    linewidth = 0.7
  ) +
  ggplot2::geom_point(
    position = ggplot2::position_dodge(width = 0.42),
    size = 2.8,
    stroke = 0.9
  ) +
  ggplot2::facet_wrap(~instrument_label, scales = "free_x", nrow = 1) +
  ggplot2::scale_colour_manual(
    values = c("Near eye" = "#0072B2", "Chest" = "#D55E00")
  ) +
  ggplot2::scale_shape_manual(values = c("Near eye" = 16, "Chest" = 17)) +
  ggplot2::labs(
    x = "Difference in local exposure timing (hours)",
    y = NULL,
    colour = "Placement",
    shape = "Placement"
  ) +
  ggplot2::theme_bw(base_size = 14) +
  ggplot2::theme(
    legend.position = "top",
    text = ggplot2::element_text(size = 17),
    legend.text = ggplot2::element_text(size = 17),
    legend.title = ggplot2::element_text(size = 17),
    strip.text = ggplot2::element_text(face = "bold", size = 17),
    axis.text = ggplot2::element_text(size = 17),
    axis.title = ggplot2::element_text(size = 17),
    panel.grid.minor = ggplot2::element_blank(),
    panel.spacing = grid::unit(12, "pt"),
    plot.margin = ggplot2::margin(12, 16, 12, 12)
  )

ggplot2::ggsave(
  file.path(roots$figures, "H09_primary_effects.png"),
  effect_plot,
  width = 10.5,
  height = 6.5,
  scale = 1.5,
  dpi = 300,
  device = ragg::agg_png
)
ggplot2::ggsave(
  file.path(roots$figures, "H09_primary_effects.pdf"),
  effect_plot,
  width = 10.5,
  height = 6.5,
  scale = 1.5,
  device = grDevices::cairo_pdf
)

paired_plot_data <- paired_effects |>
  dplyr::mutate(
    metric_label = factor(.data$abbreviation, levels = metric_levels),
    instrument_label = factor(
      .data$instrument_name,
      levels = c("MCTQ MSFsc", "MEQ")
    )
  )
paired_limits <- range(c(
  paired_plot_data$conf_low_glasses,
  paired_plot_data$conf_high_glasses,
  paired_plot_data$conf_low_chest,
  paired_plot_data$conf_high_chest,
  0
), na.rm = TRUE)
paired_padding <- diff(paired_limits) * 0.08
paired_limits <- paired_limits + c(-paired_padding, paired_padding)
paired_plot <- ggplot2::ggplot(
  paired_plot_data,
  ggplot2::aes(
    x = .data$estimate_glasses,
    y = .data$estimate_chest,
    colour = .data$metric_label,
    shape = .data$metric_label
  )
) +
  ggplot2::geom_abline(
    intercept = 0,
    slope = 1,
    colour = "grey45",
    linetype = "dashed",
    linewidth = 0.6
  ) +
  ggplot2::geom_vline(xintercept = 0, colour = "grey70", linewidth = 0.45) +
  ggplot2::geom_hline(yintercept = 0, colour = "grey70", linewidth = 0.45) +
  ggplot2::geom_errorbar(
    ggplot2::aes(
      ymin = .data$conf_low_chest,
      ymax = .data$conf_high_chest
    ),
    width = 0,
    linewidth = 0.55
  ) +
  ggplot2::geom_errorbarh(
    ggplot2::aes(
      xmin = .data$conf_low_glasses,
      xmax = .data$conf_high_glasses
    ),
    height = 0,
    linewidth = 0.55
  ) +
  ggplot2::geom_point(size = 3.1, stroke = 0.9) +
  ggplot2::facet_wrap(~instrument_label, nrow = 1) +
  ggplot2::coord_equal(xlim = paired_limits, ylim = paired_limits) +
  ggplot2::scale_colour_brewer(palette = "Dark2", drop = FALSE) +
  ggplot2::scale_shape_manual(values = c(16, 17, 15, 18, 3), drop = FALSE) +
  ggplot2::labs(
    x = "Near-eye estimate (hours)",
    y = "Chest estimate (hours)",
    colour = "Timing metric",
    shape = "Timing metric"
  ) +
  ggplot2::theme_bw(base_size = 14) +
  ggplot2::theme(
    legend.position = "bottom",
    text = ggplot2::element_text(size = 13),
    legend.text = ggplot2::element_text(size = 13),
    legend.title = ggplot2::element_text(size = 13),
    strip.text = ggplot2::element_text(face = "bold", size = 14),
    axis.text = ggplot2::element_text(size = 13),
    axis.title = ggplot2::element_text(size = 14),
    panel.grid.minor = ggplot2::element_blank(),
    panel.spacing = grid::unit(10, "pt"),
    plot.margin = ggplot2::margin(10, 14, 12, 10)
  )

ggplot2::ggsave(
  file.path(roots$figures, "H09_paired_placement_effects.png"),
  paired_plot,
  width = 8,
  height = 6.5,
  scale = 1.5,
  dpi = 300,
  device = ragg::agg_png
)
ggplot2::ggsave(
  file.path(roots$figures, "H09_paired_placement_effects.pdf"),
  paired_plot,
  width = 8,
  height = 6.5,
  scale = 1.5,
  device = grDevices::cairo_pdf
)

v0_observed_source <- v0_rows |>
  dplyr::left_join(
    metric_registry |>
      dplyr::select(
        .data$metric_id,
        .data$metric_order,
        .data$abbreviation,
        .data$manuscript_name
      ),
    by = "metric_id",
    relationship = "many-to-one"
  ) |>
  dplyr::left_join(
    site_registry |>
      dplyr::select(
        .data$site,
        .data$display_name,
        .data$display_order,
        colour = .data$color_hex
      ),
    by = "site",
    relationship = "many-to-one"
  ) |>
  dplyr::mutate(row_type = "observed")

v0_prediction_source <- v0_observed_source |>
  dplyr::group_by(
    .data$placement,
    .data$metric_id,
    .data$metric_order,
    .data$abbreviation,
    .data$manuscript_name
  ) |>
  tidyr::nest() |>
  dplyr::mutate(
    prediction = purrr::map(.data$data, function(data) {
      model <- stats::lm(timing_hour ~ mctq_hour, data = data)
      grid <- tibble::tibble(
        mctq_hour = seq(
          min(data$mctq_hour),
          max(data$mctq_hour),
          length.out = 101L
        )
      )
      prediction <- stats::predict(model, newdata = grid, se.fit = TRUE)
      grid |>
        dplyr::mutate(
          timing_hour = as.numeric(prediction$fit),
          prediction_conf_low = .data$timing_hour -
            stats::qnorm(0.975) * as.numeric(prediction$se.fit),
          prediction_conf_high = .data$timing_hour +
            stats::qnorm(0.975) * as.numeric(prediction$se.fit),
          row_type = "pooled_v0_lm_prediction"
        )
    })
  ) |>
  dplyr::select(-.data$data) |>
  tidyr::unnest(.data$prediction)

h09_write_csv(
  v0_observed_source,
  file.path(roots$source_data, "H09_v0_observed_figure_data.csv")
)
h09_write_csv(
  v0_prediction_source,
  file.path(roots$source_data, "H09_v0_prediction_figure_data.csv")
)

h09_v0_plot <- function(placement, placement_label) {
  observed <- v0_observed_source |>
    dplyr::filter(.data$placement == .env$placement) |>
    dplyr::mutate(
      metric_label = factor(
        .data$abbreviation,
        levels = c("M10 midpoint", "L10 midpoint", "Mean >250",
          "First >250", "Last >250")
      )
    )
  prediction <- v0_prediction_source |>
    dplyr::filter(.data$placement == .env$placement) |>
    dplyr::mutate(
      metric_label = factor(
        .data$abbreviation,
        levels = c("M10 midpoint", "L10 midpoint", "Mean >250",
          "First >250", "Last >250")
      )
    )
  scatter <- ggplot2::ggplot(
    observed,
    ggplot2::aes(
      x = .data$mctq_hour,
      y = .data$timing_hour,
      colour = .data$site
    )
  ) +
    ggplot2::geom_point(alpha = 0.42, size = 1.15) +
    ggplot2::geom_ribbon(
      data = prediction,
      ggplot2::aes(
        x = .data$mctq_hour,
        ymin = .data$prediction_conf_low,
        ymax = .data$prediction_conf_high
      ),
      inherit.aes = FALSE,
      fill = "grey55",
      alpha = 0.18
    ) +
    ggplot2::geom_line(
      data = prediction,
      ggplot2::aes(x = .data$mctq_hour, y = .data$timing_hour),
      inherit.aes = FALSE,
      colour = "black",
      linewidth = 0.7
    ) +
    ggplot2::facet_wrap(~metric_label, scales = "free_y", ncol = 3) +
    ggplot2::scale_colour_manual(values = site_colours, drop = FALSE) +
    ggplot2::labs(
      x = "MCTQ MSFsc (hours)",
      y = "Local time of day (hours)",
      colour = "Site"
    ) +
    ggplot2::theme_bw(base_size = 14) +
    ggplot2::theme(
      legend.position = "none",
      strip.text = ggplot2::element_text(face = "bold", size = 12),
      axis.text = ggplot2::element_text(size = 12),
      axis.title = ggplot2::element_text(size = 14),
      panel.grid.minor = ggplot2::element_blank()
    )
  site_panel <- chronotype |>
    dplyr::transmute(
      .data$site,
      mctq_hour = as.numeric(.data$msf_sc) / 3600
    ) |>
    dplyr::filter(.data$site %in% unique(as.character(observed$site))) |>
    dplyr::left_join(
      site_registry |>
        dplyr::select(
          .data$site,
          .data$display_name,
          .data$display_order
        ),
      by = "site",
      relationship = "many-to-one"
    ) |>
    dplyr::mutate(
      display_name = factor(
        .data$display_name,
        levels = rev(site_registry$display_name)
      )
    ) |>
    ggplot2::ggplot(ggplot2::aes(
      x = .data$mctq_hour,
      y = .data$display_name,
      colour = .data$site
    )) +
    ggplot2::geom_boxplot(outlier.shape = NA, linewidth = 0.65) +
    ggplot2::geom_jitter(height = 0.10, alpha = 0.45, size = 1.2) +
    ggplot2::scale_colour_manual(values = site_colours, drop = FALSE) +
    ggplot2::labs(x = "MCTQ MSFsc (hours)", y = NULL) +
    ggplot2::theme_bw(base_size = 14) +
    ggplot2::theme(
      legend.position = "none",
      axis.text = ggplot2::element_text(size = 12),
      axis.title = ggplot2::element_text(size = 14),
      panel.grid.minor = ggplot2::element_blank()
    )
  scatter + site_panel +
    patchwork::plot_layout(widths = c(3.2, 1.25)) +
    patchwork::plot_annotation(
      title = paste0("V0 figure recreation — ", placement_label),
      subtitle = paste(
        "All five V0 outcomes are retained; black lines reproduce the pooled",
        "ordinary-lm display and do not represent the mixed models"
      ),
      tag_levels = "A",
      theme = ggplot2::theme(
        plot.title = ggplot2::element_text(face = "bold", size = 16),
        plot.subtitle = ggplot2::element_text(size = 12)
      )
    )
}

v0_near_eye_plot <- h09_v0_plot("glasses", "Near eye")
v0_chest_plot <- h09_v0_plot("chest", "Chest")
for (item in list(
  list(stem = "H09_v0_near_eye_recreation", plot = v0_near_eye_plot),
  list(stem = "H09_v0_chest_recreation", plot = v0_chest_plot)
)) {
  ggplot2::ggsave(
    file.path(roots$figures, paste0(item$stem, ".png")),
    item$plot,
    width = 10.5,
    height = 8,
    scale = 1.5,
    dpi = 300,
    device = ragg::agg_png
  )
  ggplot2::ggsave(
    file.path(roots$figures, paste0(item$stem, ".pdf")),
    item$plot,
    width = 10.5,
    height = 8,
    scale = 1.5,
    device = grDevices::cairo_pdf
  )
}

diagnostic_source <- diagnostic_plot_data |>
  dplyr::left_join(
    metric_registry |>
      dplyr::select(
        .data$metric_id,
        .data$metric_order,
        .data$abbreviation
      ),
    by = "metric_id",
    relationship = "many-to-one"
  ) |>
  dplyr::left_join(
    predictor_registry |>
      dplyr::select(.data$instrument_id, .data$instrument_name),
    by = "instrument_id",
    relationship = "many-to-one"
  )
h09_write_csv(
  diagnostic_source,
  file.path(roots$source_data, "H09_primary_diagnostic_figure_data.csv")
)

h09_diagnostic_plot <- function(placement, placement_label) {
  data <- diagnostic_source |>
    dplyr::filter(.data$placement == .env$placement) |>
    dplyr::mutate(
      panel = paste(.data$abbreviation, .data$instrument_name, sep = " — ")
    )
  residual_plot <- ggplot2::ggplot(
    data,
    ggplot2::aes(
      x = .data$fitted,
      y = .data$standardized_residual
    )
  ) +
    ggplot2::geom_hline(yintercept = 0, colour = "grey55") +
    ggplot2::geom_point(alpha = 0.32, size = 0.8) +
    ggplot2::facet_wrap(
      ~panel,
      scales = "free_x",
      ncol = 3,
      labeller = ggplot2::label_wrap_gen(width = 26)
    ) +
    ggplot2::labs(x = "Fitted timing (hours)", y = "Standardized residual") +
    ggplot2::theme_bw(base_size = 14) +
    ggplot2::theme(
      text = ggplot2::element_text(size = 17),
      strip.text = ggplot2::element_text(size = 17, face = "bold"),
      axis.text = ggplot2::element_text(size = 17),
      axis.title = ggplot2::element_text(size = 17),
      panel.grid.minor = ggplot2::element_blank(),
      plot.tag = ggplot2::element_text(size = 17, face = "bold"),
      panel.spacing = grid::unit(10, "pt"),
      plot.margin = ggplot2::margin(10, 12, 10, 10)
    )
  qq_plot <- ggplot2::ggplot(
    data,
    ggplot2::aes(
      x = .data$theoretical_quantile,
      y = .data$sample_quantile
    )
  ) +
    ggplot2::geom_abline(intercept = 0, slope = 1, colour = "grey55") +
    ggplot2::geom_point(alpha = 0.32, size = 0.8) +
    ggplot2::facet_wrap(
      ~panel,
      scales = "free",
      ncol = 3,
      labeller = ggplot2::label_wrap_gen(width = 26)
    ) +
    ggplot2::labs(x = "Normal-score quantile", y = "Standardized residual") +
    ggplot2::theme_bw(base_size = 14) +
    ggplot2::theme(
      text = ggplot2::element_text(size = 17),
      strip.text = ggplot2::element_text(size = 17, face = "bold"),
      axis.text = ggplot2::element_text(size = 17),
      axis.title = ggplot2::element_text(size = 17),
      panel.grid.minor = ggplot2::element_blank(),
      plot.tag = ggplot2::element_text(size = 17, face = "bold"),
      panel.spacing = grid::unit(10, "pt"),
      plot.margin = ggplot2::margin(10, 12, 10, 10)
    )
  residual_plot / qq_plot +
    patchwork::plot_annotation(
      title = paste0("H09 mixed-model residual diagnostics — ", placement_label),
      tag_levels = "A",
      theme = ggplot2::theme(
        plot.title = ggplot2::element_text(face = "bold", size = 18),
        plot.margin = ggplot2::margin(12, 12, 8, 12)
      )
    )
}

diagnostic_near_eye_plot <- h09_diagnostic_plot("glasses", "Near eye")
diagnostic_chest_plot <- h09_diagnostic_plot("chest", "Chest")
for (item in list(
  list(stem = "H09_diagnostics_near_eye", plot = diagnostic_near_eye_plot),
  list(stem = "H09_diagnostics_chest", plot = diagnostic_chest_plot)
)) {
  ggplot2::ggsave(
    file.path(roots$figures, paste0(item$stem, ".png")),
    item$plot,
    width = 10.5,
    height = 17.5,
    scale = 1.5,
    dpi = 300,
    device = ragg::agg_png
  )
  ggplot2::ggsave(
    file.path(roots$figures, paste0(item$stem, ".pdf")),
    item$plot,
    width = 10.5,
    height = 17.5,
    scale = 1.5,
    device = grDevices::cairo_pdf
  )
}

figure_manifest <- tibble::tribble(
  ~figure_id, ~figure_path, ~source_data_path, ~base_width_in,
  ~base_height_in, ~export_scale_multiplier, ~export_width_in,
  ~export_height_in, ~raster_dpi, ~intended_display_width_mm,
  ~smallest_essential_nominal_text_pt, ~effective_final_text_pt,
  ~visual_qa_status, ~alt_text,
  "primary_effects",
  "artifacts/10_figures/H09/H09_primary_effects.png",
  "artifacts/11_source_data/H09/H09_primary_effects_data.csv",
  10.5, 6.5, 1.5, 15.75, 9.75, 300, 170, 17,
  17 * (170 / 25.4) / 15.75,
  paste(
    "PASS: Order 56a candidate inspected at original dimensions, 170 mm,",
    "708 px, and 720 by 500 on 2026-08-22; no clipping, overlap, broken",
    "wrapping, or blocking whitespace."
  ),
  paste(
    "Forest plot of site-adjusted chronotype associations with five local",
    "light-exposure timing metrics. Panels separate MCTQ MSFsc and MEQ;",
    "near-eye and chest estimates have 95% confidence intervals and a",
    "vertical zero reference line."
  ),
  "paired_placement_effects",
  "artifacts/10_figures/H09/H09_paired_placement_effects.png",
  "artifacts/11_source_data/H09/H09_paired_placement_effects_data.csv",
  8, 6.5, 1.5, 12, 9.75, 300, 170, 13,
  13 * (170 / 25.4) / 12,
  paste(
    "PASS: Order 56a candidate inspected at original dimensions, 170 mm,",
    "708 px, and 720 by 500 on 2026-08-22; no clipping, overlap, broken",
    "wrapping, or blocking whitespace."
  ),
  paste(
    "Near-eye estimates on the horizontal axis and chest estimates on the",
    "vertical axis for separately fitted models using identical paired",
    "participant-days. Horizontal and vertical bars are component 95%",
    "confidence intervals; an identity line and zero lines aid comparison."
  ),
  "v0_near_eye_recreation",
  "artifacts/10_figures/H09/H09_v0_near_eye_recreation.png",
  "artifacts/11_source_data/H09/H09_v0_observed_figure_data.csv",
  10.5, 8, 1.5, 15.75, 12, 300, 170, 12,
  12 * (170 / 25.4) / 15.75,
  "PENDING_FINAL_SIZE_VISUAL_INSPECTION",
  paste(
    "Near-eye recreation of the V0 display with all five V0 timing metrics,",
    "site-coloured participant-days, pooled ordinary-regression lines, and",
    "a submitted-order site distribution of MCTQ MSFsc."
  ),
  "v0_chest_recreation",
  "artifacts/10_figures/H09/H09_v0_chest_recreation.png",
  "artifacts/11_source_data/H09/H09_v0_observed_figure_data.csv",
  10.5, 8, 1.5, 15.75, 12, 300, 170, 12,
  12 * (170 / 25.4) / 15.75,
  "PENDING_FINAL_SIZE_VISUAL_INSPECTION",
  paste(
    "Chest recreation of the V0 display with all five V0 timing metrics,",
    "site-coloured participant-days, pooled ordinary-regression lines, and",
    "a submitted-order site distribution of MCTQ MSFsc."
  ),
  "diagnostics_near_eye",
  "artifacts/10_figures/H09/H09_diagnostics_near_eye.png",
  "artifacts/11_source_data/H09/H09_primary_diagnostic_figure_data.csv",
  10.5, 17.5, 1.5, 15.75, 26.25, 300, 170, 17,
  17 * (170 / 25.4) / 15.75,
  paste(
    "PASS: Order 56a candidate inspected at original dimensions, 170 mm,",
    "708 px, and 720 by 500 on 2026-08-22; no clipping, overlap, broken",
    "wrapping, or blocking whitespace."
  ),
  paste(
    "Near-eye residual-versus-fitted and normal Q-Q panels for each timing",
    "metric and chronotype instrument. Reference lines identify zero",
    "residual and the expected normal-score relationship."
  ),
  "diagnostics_chest",
  "artifacts/10_figures/H09/H09_diagnostics_chest.png",
  "artifacts/11_source_data/H09/H09_primary_diagnostic_figure_data.csv",
  10.5, 17.5, 1.5, 15.75, 26.25, 300, 170, 17,
  17 * (170 / 25.4) / 15.75,
  paste(
    "PASS: Order 56a candidate inspected at original dimensions, 170 mm,",
    "708 px, and 720 by 500 on 2026-08-22; no clipping, overlap, broken",
    "wrapping, or blocking whitespace."
  ),
  paste(
    "Chest residual-versus-fitted and normal Q-Q panels for each timing",
    "metric and chronotype instrument. Reference lines identify zero",
    "residual and the expected normal-score relationship."
  )
) |>
  dplyr::mutate(
    display_reduction_factor =
      (.data$intended_display_width_mm / 25.4) / .data$export_width_in,
    pdf_path = sub("[.]png$", ".pdf", .data$figure_path),
    source_companion_note = dplyr::case_when(
      grepl("v0_", .data$figure_id) ~ paste(
        "Pooled line coordinates are stored separately in",
        "artifacts/11_source_data/H09/H09_v0_prediction_figure_data.csv"
      ),
      TRUE ~ NA_character_
    )
  )

h09_write_csv(
  figure_manifest,
  file.path(roots$manifests, "H09_figure_manifest.csv")
)

####
# Step 9: Record execution environment and artifact manifest
####

package_versions <- tibble::tibble(
  package = required_packages,
  version = vapply(
    required_packages,
    function(package) as.character(utils::packageVersion(package)),
    character(1)
  )
)
execution_record <- tibble::tibble(
  producer = producer,
  command = paste(
    "env R_PROFILE_USER=/dev/null Rscript",
    "scripts/hypotheses/H09/run_h09_stage2.R"
  ),
  r_version = as.character(getRversion()),
  platform = R.version$platform,
  project_library = project_library,
  model_frames = nrow(model_frame_index),
  fitted_model_objects = nrow(model_fit_index),
  diagnostic_targets = nrow(diagnostic_targets),
  production_resampling_replicates = 0L,
  resampling_gate_status = "NOT NEEDED; no bootstrap or simulation run",
  prep_provenance_qualification = base_bundle_audit$provenance_qualification,
  run_completed_utc = format(Sys.time(), tz = "UTC", usetz = TRUE)
)
h09_write_csv(
  package_versions,
  file.path(roots$manifests, "H09_package_versions.csv")
)
h09_write_csv(
  execution_record,
  file.path(roots$manifests, "H09_execution_record.csv")
)

h09_build_manifest()
message("H09 Stage 2 analysis and artifact build completed")
