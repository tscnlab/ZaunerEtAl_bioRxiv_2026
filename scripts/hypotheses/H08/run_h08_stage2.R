# Run the author-approved H08 Stage 2 implementation and V0 comparison.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)

source(file.path(root, "scripts/pipeline/paths_io.R"))
source(file.path(root, "scripts/pipeline/multiplicity.R"))
source(file.path(root, "scripts/pipeline/p_value_display.R"))
source(file.path(root, "scripts/hypotheses/H08/h08_contract.R"))
source(file.path(root, "scripts/hypotheses/H08/h08_modeling.R"))

options(lifecycle_verbosity = "quiet", warn = 1)

if (!identical(as.character(getRversion()), "4.6.1")) {
  h08_abort(
    "H08 Stage 2 requires R 4.6.1; found %s",
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
  h08_abort(
    "H08 Stage 2 is missing project package(s): %s",
    paste(missing_packages, collapse = ", ")
  )
}

h08_validate_contract()

producer <- "scripts/hypotheses/H08/run_h08_stage2.R"
stage <- Sys.getenv("H08_STAGE", unset = "fit")
if (!stage %in% c("fit", "manifest")) {
  h08_abort("H08_STAGE must be `fit` or `manifest`")
}

roots <- list(
  model_data = file.path(root, "artifacts/06_model_data/H08"),
  models = file.path(root, "artifacts/07_models/H08"),
  diagnostics = file.path(root, "artifacts/08_diagnostics/H08"),
  tables = file.path(root, "artifacts/09_tables/H08"),
  figures = file.path(root, "artifacts/10_figures/H08"),
  source_data = file.path(root, "artifacts/11_source_data/H08"),
  manifests = file.path(root, "artifacts/12_manifests/H08")
)
invisible(vapply(
  roots,
  dir.create,
  logical(1),
  recursive = TRUE,
  showWarnings = FALSE
))

h08_write_csv <- function(data, path) {
  write_csv_artifact(data, path, producer = producer)
  invisible(path)
}

h08_write_rds <- function(object, path) {
  write_rds_artifact(object, path, producer = producer)
  invisible(path)
}

h08_relative_path <- function(path) {
  normalized <- normalizePath(path, winslash = "/", mustWork = TRUE)
  if (startsWith(normalized, paste0(root, "/"))) {
    substring(normalized, nchar(root) + 2L)
  } else {
    normalized
  }
}

h08_build_manifest <- function() {
  artifact_files <- sort(unique(unlist(lapply(
    roots,
    list.files,
    recursive = TRUE,
    full.names = TRUE
  ))))
  manifest_path <- file.path(roots$manifests, "H08_stage2_artifacts.csv")
  artifact_files <- artifact_files[
    file.exists(artifact_files) &
      !dir.exists(artifact_files) &
      normalizePath(artifact_files, winslash = "/", mustWork = TRUE) !=
        normalizePath(manifest_path, winslash = "/", mustWork = FALSE)
  ]
  artifact_relative <- vapply(
    artifact_files,
    h08_relative_path,
    character(1)
  )
  downstream_artifact <-
    grepl(
      "^artifacts/11_source_data/H08/H08_preparation_",
      artifact_relative
    ) |
    startsWith(
      artifact_relative,
      "artifacts/12_manifests/H08/physical_size_qa/"
    ) |
    artifact_relative %in%
      c(
        "artifacts/12_manifests/H08/H08_figure_physical_size_qa.csv",
        "artifacts/12_manifests/H08/H08_preparation_report_manifest.csv",
        "artifacts/12_manifests/H08/H08_stage3_artifacts.csv"
      )
  artifact_files <- artifact_files[!downstream_artifact]
  code_and_report <- c(
    file.path(root, "scripts/hypotheses/H08/h08_contract.R"),
    file.path(root, "scripts/hypotheses/H08/h08_modeling.R"),
    file.path(root, "scripts/hypotheses/H08/run_h08_stage2.R"),
    file.path(
      root,
      "scripts/hypotheses/H08/reseal_h08_l10_metric011.R"
    ),
    file.path(root, "tests/hypotheses/H08/test_h08_stage2.R"),
    file.path(
      root,
      "tests/hypotheses/H08/test_h08_metric011_reseal.R"
    ),
    file.path(
      root,
      "audit/hypotheses/H08/02_implementation_and_v0_comparison.qmd"
    ),
    file.path(
      root,
      "audit/hypotheses/H08/02_implementation_and_v0_comparison.html"
    ),
    file.path(
      root,
      "audit/decisions/l10_numerical_zero_normalization.md"
    ),
    file.path(
      root,
      paste0(
        "audit/reconciliation/l10_METRIC-011/",
        "METRIC-011_evidence_manifest.csv"
      )
    ),
    file.path(
      root,
      paste0(
        "audit/reconciliation/l10_METRIC-011/",
        "primary_scientific_cell_changes.csv"
      )
    ),
    file.path(root, "audit/handoffs/H08_worker_handoff.md")
  )
  files <- sort(unique(c(
    artifact_files,
    code_and_report[file.exists(code_and_report)]
  )))
  manifest <- dplyr::bind_rows(lapply(files, function(path) {
    info <- file.info(path)
    tibble::tibble(
      path = h08_relative_path(path),
      artifact_type = tools::file_ext(path),
      sha256 = artifact_sha256(path),
      bytes = as.numeric(info$size),
      producer = producer,
      r_version = as.character(getRversion()),
      written_utc = format(info$mtime, tz = "UTC", usetz = TRUE)
    )
  }))
  h08_write_csv(manifest, manifest_path)
  invisible(manifest_path)
}

if (identical(stage, "manifest")) {
  h08_build_manifest()
  message("H08 Stage 2 manifest refreshed")
  quit(save = "no", status = 0L)
}

####
# Step 1: Verify contracts and inputs
####

input_contract <- h08_input_contract(root)
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
    .data$use,
    .data$expected_sha256,
    .data$observed_sha256,
    .data$hash_verified,
    .data$bytes
  )
if (any(!input_audit$hash_verified)) {
  h08_abort("A frozen H08 input differs from its approved SHA-256")
}

score_contract <- h08_score_contract()
metric_registry <- h08_metric_registry()
run_registry <- h08_run_registry()
family_registry <- h08_family_registry()
sensitivity_registry <- h08_sensitivity_registry()
formula_registry <- h08_formula_registry()
approval_registry <- h08_approval_registry()

site_registry <- readr::read_csv(
  file.path(root, "config/site_display_registry.csv"),
  show_col_types = FALSE
) |>
  dplyr::arrange(.data$display_order)
site_levels <- site_registry$site

metric_display <- readr::read_csv(
  file.path(root, "config/metric_display_registry.csv"),
  show_col_types = FALSE
) |>
  dplyr::filter(.data$metric_id %in% metric_registry$metric_id) |>
  dplyr::select(
    .data$metric_id,
    display_manuscript_name = .data$manuscript_name,
    display_unit_registry = .data$display_unit
  )
metric_display_audit <- metric_registry |>
  dplyr::left_join(
    metric_display,
    by = "metric_id",
    relationship = "one-to-one"
  ) |>
  dplyr::mutate(
    name_matches = .data$manuscript_name == .data$display_manuscript_name,
    unit_matches = .data$display_unit == .data$display_unit_registry
  )
if (
  any(!metric_display_audit$name_matches | !metric_display_audit$unit_matches)
) {
  h08_abort("The H08 metric display contract differs from the shared registry")
}

h05_response <- readr::read_csv(
  file.path(root, "artifacts/06_model_data/H05/H05_metric_registry.csv"),
  show_col_types = FALSE
) |>
  dplyr::filter(.data$metric_id %in% metric_registry$metric_id) |>
  dplyr::select(
    .data$metric_id,
    inherited_response_family = .data$response_family,
    inherited_response_transform = .data$response_transform,
    inherited_effect_scale = .data$effect_scale
  )
response_contract_audit <- metric_registry |>
  dplyr::left_join(
    h05_response,
    by = "metric_id",
    relationship = "one-to-one"
  ) |>
  dplyr::mutate(
    response_family_matches = .data$response_family ==
      .data$inherited_response_family,
    response_transform_matches = .data$response_transform ==
      .data$inherited_response_transform,
    effect_scale_matches = .data$effect_scale == .data$inherited_effect_scale
  )
if (
  any(
    !response_contract_audit$response_family_matches |
      !response_contract_audit$response_transform_matches |
      !response_contract_audit$effect_scale_matches
  )
) {
  h08_abort(
    "The H08 response package differs from the approved H01/H05 contract"
  )
}

vlsq <- readRDS(input_contract$absolute_path[
  input_contract$input_role == "normalized_vlsq8"
])
item_names <- c(
  "sensitivity",
  "glare",
  "flicker",
  "sensitivity_severity",
  "headache",
  "blurry_vision",
  "ability",
  "glasses"
)
item_matrix <- do.call(cbind, lapply(vlsq[item_names], as.integer))
score_audit_rows <- vlsq |>
  dplyr::transmute(
    .data$site,
    .data$Id,
    stored_VLSQ8 = .data$VLSQ8,
    item_sum_1_to_5 = rowSums(item_matrix),
    stored_minus_item_sum = .data$VLSQ8 - rowSums(item_matrix),
    scoring_rule_verified = .data$stored_minus_item_sum == 5
  )
score_audit <- tibble::tibble(
  participants = nrow(vlsq),
  sites = dplyr::n_distinct(vlsq$site),
  missing_scores = sum(is.na(vlsq$VLSQ8)),
  missing_item_cells = sum(is.na(item_matrix)),
  observed_min = min(vlsq$VLSQ8),
  observed_max = max(vlsq$VLSQ8),
  observed_mean = mean(vlsq$VLSQ8),
  observed_participant_sd = stats::sd(vlsq$VLSQ8),
  stored_minus_item_sum_unique = paste(
    sort(unique(score_audit_rows$stored_minus_item_sum)),
    collapse = "|"
  ),
  scoring_rule = score_contract$scoring_rule,
  scoring_rule_verified = all(score_audit_rows$scoring_rule_verified),
  author_approved = TRUE
)
if (
  nrow(vlsq) != score_contract$participants ||
    anyDuplicated(vlsq[c("site", "Id")]) ||
    !isTRUE(score_audit$scoring_rule_verified) ||
    !isTRUE(all.equal(score_audit$observed_mean, score_contract$center)) ||
    !isTRUE(all.equal(
      score_audit$observed_participant_sd,
      score_contract$participant_sd
    ))
) {
  h08_abort("The H08 VLSQ-8 score input fails its approved contract")
}

h08_write_csv(input_audit, file.path(roots$model_data, "H08_input_audit.csv"))
h08_write_csv(
  approval_registry,
  file.path(roots$model_data, "H08_author_approvals.csv")
)
h08_write_csv(
  metric_registry,
  file.path(roots$model_data, "H08_metric_registry.csv")
)
h08_write_csv(run_registry, file.path(roots$model_data, "H08_run_registry.csv"))
h08_write_csv(
  family_registry,
  file.path(roots$model_data, "H08_family_registry.csv")
)
h08_write_csv(
  sensitivity_registry,
  file.path(roots$model_data, "H08_sensitivity_registry.csv")
)
h08_write_csv(
  formula_registry,
  file.path(roots$model_data, "H08_formula_registry.csv")
)
h08_write_csv(
  score_audit,
  file.path(roots$diagnostics, "H08_vlsq_score_audit.csv")
)
h08_write_csv(
  score_audit_rows,
  file.path(roots$diagnostics, "H08_vlsq_score_rows.csv")
)
h08_write_csv(
  response_contract_audit,
  file.path(roots$model_data, "H08_response_contract_audit.csv")
)

####
# Step 2: Build exact participant-day rows
####

main_near_eye <- readRDS(input_contract$absolute_path[
  input_contract$input_role == "primary_near_eye_metrics"
])
main_chest <- readRDS(input_contract$absolute_path[
  input_contract$input_role == "primary_chest_metrics"
])
gap_source <- readRDS(input_contract$absolute_path[
  input_contract$input_role == "gap_timing_unaware_metrics"
])
h01_main <- readRDS(input_contract$absolute_path[
  input_contract$input_role == "primary_support_provenance"
])
h01_gap <- readRDS(input_contract$absolute_path[
  input_contract$input_role == "gap_support_provenance"
])

h08_support_rows <- function(object, scenario_id) {
  object$model_rows |>
    dplyr::filter(
      .data$scenario == "all_available",
      .data$metric_id %in% metric_registry$metric_id
    ) |>
    dplyr::transmute(
      data_scenario_id = scenario_id,
      .data$placement,
      .data$site,
      .data$Id,
      local_date = as.Date(.data$local_date),
      .data$metric_id,
      h01_value = .data$value,
      .data$metric_estimable,
      .data$metric_failure_reason,
      .data$metric_support_available,
      .data$metric_support_unavailability_reason,
      .data$metric_support_valid_minutes,
      .data$metric_support_expected_minutes
    )
}

support_rows <- dplyr::bind_rows(
  h08_support_rows(h01_main, "main"),
  h08_support_rows(h01_gap, "gap_timing_unaware")
)
if (
  anyDuplicated(support_rows[c(
    "data_scenario_id",
    "placement",
    "site",
    "Id",
    "local_date",
    "metric_id"
  )])
) {
  h08_abort("H08 support provenance contains duplicate participant-day keys")
}

h08_main_long <- function(data, placement) {
  source_columns <- metric_registry$source_column
  data |>
    dplyr::select(
      .data$site,
      .data$Id,
      .data$local_date,
      .data$VLSQ8,
      .data$photoperiod_hours,
      .data$valid_medi_real_minutes,
      dplyr::all_of(source_columns),
      longest_exact_value = .data$longest_bout_above_250_exact_only_sensitivity_h,
      longest_exact_identifiable = .data$longest_bout_above_250_exact_identifiable,
      dose_observed_value = .data$dose_observed_medi_lx_h
    ) |>
    tidyr::pivot_longer(
      cols = dplyr::all_of(source_columns),
      names_to = "source_column",
      values_to = "value"
    ) |>
    dplyr::left_join(
      metric_registry,
      by = "source_column",
      relationship = "many-to-one"
    ) |>
    dplyr::mutate(
      data_scenario_id = "main",
      placement = placement,
      local_date = as.Date(.data$local_date),
      .before = 1L
    )
}

main_rows <- dplyr::bind_rows(
  h08_main_long(main_near_eye, "glasses"),
  h08_main_long(main_chest, "chest")
)

gap_rows <- gap_source |>
  dplyr::filter(.data$metric_id %in% metric_registry$metric_id) |>
  dplyr::transmute(
    data_scenario_id = "gap_timing_unaware",
    placement = .data$position,
    .data$site,
    .data$Id,
    local_date = as.Date(.data$local_date),
    .data$metric_id,
    value = .data$manuscript_prepared_value,
    photoperiod_hours = NA_real_,
    valid_medi_real_minutes = NA_real_,
    longest_exact_value = NA_real_,
    longest_exact_identifiable = NA,
    dose_observed_value = NA_real_
  ) |>
  dplyr::left_join(
    vlsq |>
      dplyr::select(.data$site, .data$Id, .data$VLSQ8),
    by = c("site", "Id"),
    relationship = "many-to-one"
  ) |>
  dplyr::left_join(
    metric_registry,
    by = "metric_id",
    relationship = "many-to-one"
  )

model_rows <- dplyr::bind_rows(main_rows, gap_rows) |>
  dplyr::left_join(
    support_rows,
    by = c(
      "data_scenario_id",
      "placement",
      "site",
      "Id",
      "local_date",
      "metric_id"
    ),
    relationship = "one-to-one"
  )

if (nrow(model_rows) != nrow(main_rows) + nrow(gap_rows)) {
  h08_abort("H08 support join changed the model-row count")
}
if (any(is.na(model_rows$h01_value) != is.na(model_rows$value))) {
  h08_abort(
    "H08 direct inputs and H01 support provenance differ in missingness"
  )
}
finite_pair <- is.finite(model_rows$value) & is.finite(model_rows$h01_value)
value_difference <- abs(
  model_rows$value[finite_pair] - model_rows$h01_value[finite_pair]
)
if (length(value_difference) > 0L && max(value_difference) > 1e-10) {
  h08_abort(
    "H08 direct inputs and H01 support provenance differ in metric values"
  )
}
if (any(is.na(model_rows$VLSQ8))) {
  h08_abort("H08 model rows contain an unmatched VLSQ-8 score")
}
if (
  anyDuplicated(model_rows[c(
    "data_scenario_id",
    "placement",
    "site",
    "Id",
    "local_date",
    "metric_id"
  )])
) {
  h08_abort("H08 model rows contain duplicate participant-day keys")
}

missingness <- model_rows |>
  dplyr::mutate(
    availability_reason = dplyr::case_when(
      is.finite(.data$value) ~ "available",
      !is.na(.data$metric_failure_reason) &
        nzchar(.data$metric_failure_reason) ~
        .data$metric_failure_reason,
      TRUE ~ "unavailable_without_more_specific_reason_in_input"
    )
  ) |>
  dplyr::count(
    .data$data_scenario_id,
    .data$placement,
    .data$metric_order,
    .data$metric_id,
    .data$availability_reason,
    name = "participant_days"
  ) |>
  dplyr::arrange(
    .data$data_scenario_id,
    .data$placement,
    .data$metric_order,
    .data$availability_reason
  )
h08_write_csv(
  missingness,
  file.path(roots$model_data, "H08_metric_missingness.csv")
)

h08_key_columns <- c("site", "Id", "local_date", "metric_id")

paired_keys <- model_rows |>
  dplyr::filter(is.finite(.data$value), is.finite(.data$VLSQ8)) |>
  dplyr::group_by(
    .data$data_scenario_id,
    .data$site,
    .data$Id,
    .data$local_date,
    .data$metric_id
  ) |>
  dplyr::summarise(
    placements = dplyr::n_distinct(.data$placement),
    .groups = "drop"
  ) |>
  dplyr::filter(.data$placements == 2L) |>
  dplyr::select(-.data$placements)

main_gap_common_keys <- model_rows |>
  dplyr::filter(is.finite(.data$value), is.finite(.data$VLSQ8)) |>
  dplyr::group_by(
    .data$placement,
    .data$site,
    .data$Id,
    .data$local_date,
    .data$metric_id
  ) |>
  dplyr::summarise(
    scenarios = dplyr::n_distinct(.data$data_scenario_id),
    .groups = "drop"
  ) |>
  dplyr::filter(.data$scenarios == 2L) |>
  dplyr::select(-.data$scenarios)

h08_rows_for_run <- function(rows, run) {
  selected <- rows |>
    dplyr::filter(
      .data$data_scenario_id == run$data_scenario_id,
      .data$placement == run$placement
    )
  if (run$sample_scenario == "paired_common_sample") {
    selected <- selected |>
      dplyr::inner_join(
        paired_keys |>
          dplyr::filter(.data$data_scenario_id == run$data_scenario_id),
        by = c("data_scenario_id", h08_key_columns),
        relationship = "many-to-one"
      )
  }
  if (run$sample_scenario == "main_gap_common_sample") {
    selected <- selected |>
      dplyr::inner_join(
        main_gap_common_keys |>
          dplyr::filter(.data$placement == run$placement),
        by = c("placement", h08_key_columns),
        relationship = "many-to-one"
      )
  }
  selected
}

model_frames <- list()
frame_index_rows <- list()
frame_site_rows <- list()
frame_row_exports <- list()

for (run_index in seq_len(nrow(run_registry))) {
  run <- run_registry[run_index, , drop = FALSE]
  run_rows <- h08_rows_for_run(model_rows, run)
  for (metric_index in seq_len(nrow(metric_registry))) {
    spec <- metric_registry[metric_index, , drop = FALSE]
    frame <- h08_prepare_model_frame(
      run_rows[run_rows$metric_id == spec$metric_id, , drop = FALSE],
      spec,
      site_levels,
      score_contract
    )
    frame_key <- paste(run$run_id, spec$metric_id, sep = "__")
    model_frames[[frame_key]] <- frame
    frame_index_rows[[frame_key]] <- tibble::tibble(
      run_order = run$run_order,
      run_id = run$run_id,
      data_scenario_id = run$data_scenario_id,
      reader_scenario = run$reader_scenario,
      placement = run$placement,
      placement_label = run$placement_label,
      sample_scenario = run$sample_scenario,
      inferential_run = run$inferential_run,
      metric_order = spec$metric_order,
      metric_id = spec$metric_id,
      manuscript_name = spec$manuscript_name,
      participants = dplyr::n_distinct(frame$participant_key),
      participant_days = nrow(frame),
      sites = dplyr::n_distinct(frame$site),
      metric_support_valid_hours = h08_complete_sum(
        frame$metric_support_valid_minutes
      ) /
        60,
      metric_support_expected_hours = h08_complete_sum(
        frame$metric_support_expected_minutes
      ) /
        60,
      metric_support_missing_rows = sum(
        !is.finite(frame$metric_support_valid_minutes) |
          !is.finite(frame$metric_support_expected_minutes)
      ),
      site_levels = paste(levels(frame$site), collapse = "|"),
      site_contrasts = paste0("contr.sum(", nlevels(frame$site), ")"),
      score_center = score_contract$center,
      score_participant_sd = score_contract$participant_sd,
      row_key_hash = h08_key_hash(frame),
      model_frame_hash = h08_frame_hash(frame)
    )
    frame_site_rows[[frame_key]] <- frame |>
      dplyr::group_by(.data$site) |>
      dplyr::summarise(
        participants = dplyr::n_distinct(.data$participant_key),
        participant_days = dplyr::n(),
        metric_support_valid_hours = h08_complete_sum(
          .data$metric_support_valid_minutes
        ) /
          60,
        metric_support_expected_hours = h08_complete_sum(
          .data$metric_support_expected_minutes
        ) /
          60,
        .groups = "drop"
      ) |>
      dplyr::mutate(
        run_id = run$run_id,
        metric_order = spec$metric_order,
        metric_id = spec$metric_id,
        .before = 1L
      )
    frame_row_exports[[frame_key]] <- frame |>
      dplyr::transmute(
        run_id = run$run_id,
        sample_scenario = run$sample_scenario,
        metric_order = spec$metric_order,
        metric_id = spec$metric_id,
        .data$.model_row_id,
        site = as.character(.data$site),
        Id = as.character(.data$Id),
        .data$local_date,
        .data$value,
        .data$response_value,
        .data$VLSQ8,
        .data$VLSQ8_c,
        .data$photoperiod_hours,
        .data$metric_support_valid_minutes,
        .data$metric_support_expected_minutes
      )
  }
}

model_frame_index <- dplyr::bind_rows(frame_index_rows) |>
  dplyr::arrange(.data$run_order, .data$metric_order)
model_frame_site <- dplyr::bind_rows(frame_site_rows) |>
  dplyr::left_join(
    site_registry |>
      dplyr::select(.data$site, .data$display_order, .data$display_name),
    by = "site",
    relationship = "many-to-one"
  ) |>
  dplyr::arrange(.data$run_id, .data$metric_order, .data$display_order)
model_frame_rows <- dplyr::bind_rows(frame_row_exports)

h08_write_csv(
  model_frame_index,
  file.path(roots$model_data, "H08_model_frame_index.csv")
)
h08_write_csv(
  model_frame_site,
  file.path(roots$model_data, "H08_model_frame_by_site.csv")
)
h08_write_csv(
  model_frame_rows,
  file.path(roots$model_data, "H08_model_frame_rows.csv")
)
h08_write_rds(
  list(
    hypothesis_id = "H08",
    score_contract = score_contract,
    metric_registry = metric_registry,
    run_registry = run_registry,
    model_frames = model_frames
  ),
  file.path(roots$model_data, "H08_model_frames.rds")
)

paired_sample_audit <- model_frame_index |>
  dplyr::filter(.data$sample_scenario == "paired_common_sample") |>
  dplyr::select(
    .data$data_scenario_id,
    .data$metric_order,
    .data$metric_id,
    .data$placement,
    .data$participants,
    .data$participant_days,
    .data$sites,
    .data$row_key_hash
  ) |>
  tidyr::pivot_wider(
    names_from = .data$placement,
    values_from = c(
      .data$participants,
      .data$participant_days,
      .data$sites,
      .data$row_key_hash
    )
  ) |>
  dplyr::mutate(
    exact_counts_match = .data$participants_glasses ==
      .data$participants_chest &
      .data$participant_days_glasses == .data$participant_days_chest &
      .data$sites_glasses == .data$sites_chest,
    exact_row_keys_match = .data$row_key_hash_glasses ==
      .data$row_key_hash_chest
  )
if (
  any(
    !paired_sample_audit$exact_counts_match |
      !paired_sample_audit$exact_row_keys_match
  )
) {
  h08_abort("An H08 paired placement frame does not use identical row keys")
}
h08_write_csv(
  paired_sample_audit,
  file.path(roots$model_data, "H08_paired_sample_audit.csv")
)

main_gap_sample_audit <- model_frame_index |>
  dplyr::filter(.data$sample_scenario == "main_gap_common_sample") |>
  dplyr::select(
    .data$placement,
    .data$metric_order,
    .data$metric_id,
    .data$data_scenario_id,
    .data$participants,
    .data$participant_days,
    .data$sites,
    .data$row_key_hash
  ) |>
  tidyr::pivot_wider(
    names_from = .data$data_scenario_id,
    values_from = c(
      .data$participants,
      .data$participant_days,
      .data$sites,
      .data$row_key_hash
    )
  ) |>
  dplyr::mutate(
    exact_counts_match = .data$participants_main ==
      .data$participants_gap_timing_unaware &
      .data$participant_days_main == .data$participant_days_gap_timing_unaware &
      .data$sites_main == .data$sites_gap_timing_unaware,
    exact_row_keys_match = .data$row_key_hash_main ==
      .data$row_key_hash_gap_timing_unaware
  )
if (
  any(
    !main_gap_sample_audit$exact_counts_match |
      !main_gap_sample_audit$exact_row_keys_match
  )
) {
  h08_abort(
    "An H08 primary--gap common-sample frame does not use identical keys"
  )
}
h08_write_csv(
  main_gap_sample_audit,
  file.path(roots$model_data, "H08_main_gap_common_sample_audit.csv")
)

####
# Step 3: Fit the approved participant-day models
####

model_bundles <- list()
model_manifest_rows <- list()
model_test_rows <- list()
model_effect_rows <- list()
model_site_slope_rows <- list()
model_prediction_rows <- list()
model_diagnostic_rows <- list()
diagnostic_plot_rows <- list()
influence_rows <- list()

for (run_index in seq_len(nrow(run_registry))) {
  run <- run_registry[run_index, , drop = FALSE]
  for (metric_index in seq_len(nrow(metric_registry))) {
    spec <- metric_registry[metric_index, , drop = FALSE]
    frame_key <- paste(run$run_id, spec$metric_id, sep = "__")
    frame <- model_frames[[frame_key]]
    message("H08 fit: ", run$run_id, " / ", spec$metric_id)
    bundle <- h08_fit_bundle(frame, spec, formula_kind = "participant_day")
    model_bundles[[frame_key]] <- bundle
    context <- tibble::tibble(
      run_order = run$run_order,
      run_id = run$run_id,
      data_scenario_id = run$data_scenario_id,
      reader_scenario = run$reader_scenario,
      placement = run$placement,
      placement_label = run$placement_label,
      sample_scenario = run$sample_scenario,
      analytical_role = run$analytical_role,
      inferential_run = run$inferential_run,
      metric_order = spec$metric_order,
      metric_id = spec$metric_id,
      manuscript_name = spec$manuscript_name,
      response_family = spec$response_family,
      response_transform = spec$response_transform,
      effect_scale = spec$effect_scale
    )
    model_manifest_rows[[frame_key]] <- dplyr::bind_cols(
      context[rep(1L, 3L), , drop = FALSE],
      h08_model_manifest_rows(bundle)
    )
    model_test_rows[[frame_key]] <- dplyr::bind_cols(
      context[rep(1L, 2L), , drop = FALSE],
      h08_bundle_tests(bundle, inferential = run$inferential_run)
    )
    model_effect_rows[[frame_key]] <- dplyr::bind_cols(
      context,
      h08_effect_summary(
        bundle$fits$additive$model,
        spec,
        score_contract$participant_sd
      )
    )
    site_slopes <- h08_site_slopes(
      bundle$fits$interaction$model,
      frame,
      spec,
      score_contract$participant_sd
    )
    model_site_slope_rows[[frame_key]] <- dplyr::bind_cols(
      context[rep(1L, nrow(site_slopes)), , drop = FALSE],
      site_slopes
    )
    predictions <- h08_centered_predictions(
      bundle$fits$additive$model,
      frame,
      spec,
      score_contract$participant_sd
    )
    model_prediction_rows[[frame_key]] <- dplyr::bind_cols(
      context[rep(1L, nrow(predictions)), , drop = FALSE],
      predictions
    )
    diagnostic <- h08_model_diagnostics(bundle, frame)
    model_diagnostic_rows[[frame_key]] <- dplyr::bind_cols(context, diagnostic)
    if (
      run$run_id %in%
        c(
          "main__glasses__all_available",
          "main__chest__all_available"
        )
    ) {
      plot_data <- h08_diagnostic_plot_data(bundle$fits$additive$model, frame)
      diagnostic_plot_rows[[frame_key]] <- dplyr::bind_cols(
        context[rep(1L, nrow(plot_data)), , drop = FALSE],
        plot_data
      )
      influence <- h08_participant_influence_screen(
        bundle$fits$additive$model,
        frame,
        n = 5L
      )
      influence_rows[[frame_key]] <- dplyr::bind_cols(
        context[rep(1L, nrow(influence)), , drop = FALSE],
        influence
      )
    }
  }
}

model_manifest <- dplyr::bind_rows(model_manifest_rows) |>
  dplyr::arrange(.data$run_order, .data$metric_order, .data$model_name)
model_tests <- dplyr::bind_rows(model_test_rows) |>
  dplyr::left_join(
    family_registry,
    by = c("run_id", "comparison_id"),
    relationship = "many-to-one"
  )
model_tests$p_adjusted <- NA_real_
for (family_id in family_registry$family_id) {
  rows <- which(model_tests$family_id == family_id)
  planned_n <- unique(model_tests$planned_n[rows])
  if (length(rows) != 9L || length(planned_n) != 1L || planned_n != 9L) {
    h08_abort(
      "Multiplicity family `%s` is not a complete nine-row family",
      family_id
    )
  }
  model_tests$p_adjusted[rows] <- adjust_p_family(
    model_tests$p_raw[rows],
    method = "BH",
    n = 9L
  )
}
model_tests <- model_tests |>
  dplyr::mutate(
    raw_significant = !is.na(.data$p_raw) & .data$p_raw <= 0.05,
    adjusted_significant = !is.na(.data$p_adjusted) & .data$p_adjusted <= 0.05,
    raw_p_display = nh_format_p_value(.data$p_raw),
    adjusted_p_display = nh_format_p_value(.data$p_adjusted)
  ) |>
  dplyr::arrange(.data$run_order, .data$comparison_id, .data$metric_order)

family_audit <- model_tests |>
  dplyr::filter(!is.na(.data$family_id)) |>
  dplyr::group_by(
    .data$family_id,
    .data$run_id,
    .data$comparison_id,
    .data$planned_n,
    .data$multiplicity_method,
    .data$role
  ) |>
  dplyr::summarise(
    registered_rows = dplyr::n(),
    observed_raw_p = sum(is.finite(.data$p_raw)),
    observed_adjusted_p = sum(is.finite(.data$p_adjusted)),
    raw_significant_n = sum(.data$raw_significant),
    adjusted_significant_n = sum(.data$adjusted_significant),
    complete_nine_member_family = .data$registered_rows == 9L,
    independent_recalculation_matches = isTRUE(all.equal(
      .data$p_adjusted,
      stats::p.adjust(.data$p_raw, method = "BH", n = 9L)
    )),
    .groups = "drop"
  )
if (
  any(
    !family_audit$complete_nine_member_family |
      !family_audit$independent_recalculation_matches
  )
) {
  h08_abort("An H08 multiplicity family failed independent verification")
}

model_effects <- dplyr::bind_rows(model_effect_rows)
model_site_slopes <- dplyr::bind_rows(model_site_slope_rows) |>
  dplyr::left_join(
    site_registry |>
      dplyr::select(
        .data$site,
        .data$display_order,
        .data$display_name,
        .data$color_hex
      ),
    by = "site",
    relationship = "many-to-one"
  ) |>
  dplyr::arrange(.data$run_order, .data$metric_order, .data$display_order)
model_predictions <- dplyr::bind_rows(model_prediction_rows)
model_diagnostics <- dplyr::bind_rows(model_diagnostic_rows) |>
  dplyr::arrange(.data$run_order, .data$metric_order)
diagnostic_plot_data <- dplyr::bind_rows(diagnostic_plot_rows)
participant_influence <- dplyr::bind_rows(influence_rows)

average_tests <- model_tests |>
  dplyr::filter(.data$comparison_id == "average_vlsq") |>
  dplyr::select(
    .data$run_id,
    .data$metric_id,
    average_lrt_statistic = .data$statistic,
    average_lrt_df = .data$df,
    average_p_raw = .data$p_raw,
    average_p_adjusted = .data$p_adjusted,
    average_adjusted_significant = .data$adjusted_significant,
    average_comparison_status = .data$comparison_status
  )
interaction_tests <- model_tests |>
  dplyr::filter(.data$comparison_id == "site_heterogeneity") |>
  dplyr::select(
    .data$run_id,
    .data$metric_id,
    interaction_lrt_statistic = .data$statistic,
    interaction_lrt_df = .data$df,
    interaction_p_raw = .data$p_raw,
    interaction_p_adjusted = .data$p_adjusted,
    interaction_adjusted_significant = .data$adjusted_significant,
    interaction_comparison_status = .data$comparison_status
  )

model_results_master <- model_frame_index |>
  dplyr::left_join(
    model_effects,
    by = c(
      "run_order",
      "run_id",
      "data_scenario_id",
      "reader_scenario",
      "placement",
      "placement_label",
      "sample_scenario",
      "inferential_run",
      "metric_order",
      "metric_id",
      "manuscript_name"
    ),
    relationship = "one-to-one"
  ) |>
  dplyr::left_join(
    average_tests,
    by = c("run_id", "metric_id"),
    relationship = "one-to-one"
  ) |>
  dplyr::left_join(
    interaction_tests,
    by = c("run_id", "metric_id"),
    relationship = "one-to-one"
  ) |>
  dplyr::left_join(
    model_diagnostics |>
      dplyr::select(
        .data$run_id,
        .data$metric_id,
        .data$diagnostic_status,
        .data$diagnostic_issues,
        .data$average_effect_status,
        .data$interaction_effect_status
      ),
    by = c("run_id", "metric_id"),
    relationship = "one-to-one"
  )

h08_write_csv(
  model_manifest,
  file.path(roots$models, "H08_model_fit_index.csv")
)
h08_write_csv(model_tests, file.path(roots$tables, "H08_model_tests.csv"))
h08_write_csv(model_effects, file.path(roots$tables, "H08_model_effects.csv"))
h08_write_csv(
  model_site_slopes,
  file.path(roots$tables, "H08_site_specific_slopes.csv")
)
h08_write_csv(
  model_predictions,
  file.path(roots$tables, "H08_centered_predictions.csv")
)
h08_write_csv(family_audit, file.path(roots$tables, "H08_family_audit.csv"))
h08_write_csv(
  model_results_master,
  file.path(roots$tables, "H08_model_results_master.csv")
)
h08_write_csv(
  model_diagnostics,
  file.path(roots$diagnostics, "H08_model_diagnostics.csv")
)
h08_write_csv(
  diagnostic_plot_data,
  file.path(roots$source_data, "H08_primary_diagnostic_plot_data.csv")
)
h08_write_csv(
  participant_influence,
  file.path(roots$diagnostics, "H08_participant_influence_screen.csv")
)
h08_write_rds(
  list(
    hypothesis_id = "H08",
    score_contract = score_contract,
    metric_registry = metric_registry,
    run_registry = run_registry,
    model_bundles = model_bundles
  ),
  file.path(roots$models, "H08_model_bundles.rds")
)

####
# Step 4: Fit the approved descriptive sensitivities
####

sensitivity_models <- list()
photoperiod_rows <- list()
participant_rows <- list()

for (placement in c("glasses", "chest")) {
  run_id <- paste("main", placement, "all_available", sep = "__")
  for (metric_index in seq_len(nrow(metric_registry))) {
    spec <- metric_registry[metric_index, , drop = FALSE]
    key <- paste(run_id, spec$metric_id, sep = "__")
    frame <- model_frames[[key]]

    if (any(!is.finite(frame$photoperiod_c))) {
      h08_abort("Primary H08 photoperiod is incomplete for `%s`", key)
    }
    photo_key <- paste("photoperiod", placement, spec$metric_id, sep = "__")
    photo_bundle <- h08_fit_bundle(frame, spec, formula_kind = "photoperiod")
    sensitivity_models[[photo_key]] <- photo_bundle
    photo_effect <- h08_effect_summary(
      photo_bundle$fits$additive$model,
      spec,
      score_contract$participant_sd
    )
    photo_status <- h08_model_fit_status(photo_bundle$fits$additive$model)
    photo_condition <- h08_model_condition(photo_bundle$fits$additive$model)
    photoperiod_rows[[photo_key]] <- dplyr::bind_cols(
      tibble::tibble(
        sensitivity_id = "photoperiod_adjusted",
        placement = placement,
        placement_label = ifelse(placement == "glasses", "Near eye", "Chest"),
        metric_order = spec$metric_order,
        metric_id = spec$metric_id,
        manuscript_name = spec$manuscript_name,
        participants = dplyr::n_distinct(frame$participant_key),
        participant_days = nrow(frame),
        sites = dplyr::n_distinct(frame$site),
        row_key_hash = h08_key_hash(frame),
        formula = paste(
          deparse(h08_formula_set("photoperiod")$additive),
          collapse = " "
        )
      ),
      photo_effect,
      photo_status,
      photo_condition
    )

    participant_frame <- h08_prepare_participant_summary(
      frame,
      spec,
      site_levels
    )
    participant_key <- paste(
      "participant",
      placement,
      spec$metric_id,
      sep = "__"
    )
    participant_bundle <- h08_fit_bundle(
      participant_frame,
      spec,
      formula_kind = "participant"
    )
    sensitivity_models[[participant_key]] <- participant_bundle
    participant_effect <- h08_effect_summary(
      participant_bundle$fits$additive$model,
      spec,
      score_contract$participant_sd
    )
    participant_status <- h08_model_fit_status(
      participant_bundle$fits$additive$model
    )
    participant_condition <- h08_model_condition(
      participant_bundle$fits$additive$model
    )
    participant_rows[[participant_key]] <- dplyr::bind_cols(
      tibble::tibble(
        sensitivity_id = "participant_summary",
        placement = placement,
        placement_label = ifelse(placement == "glasses", "Near eye", "Chest"),
        metric_order = spec$metric_order,
        metric_id = spec$metric_id,
        manuscript_name = spec$manuscript_name,
        participants = nrow(participant_frame),
        participant_days_contributing = sum(participant_frame$participant_days),
        sites = dplyr::n_distinct(participant_frame$site),
        metric_support_valid_hours = h08_complete_sum(
          participant_frame$metric_support_valid_minutes
        ) /
          60,
        metric_support_expected_hours = h08_complete_sum(
          participant_frame$metric_support_expected_minutes
        ) /
          60,
        row_key_hash = h08_key_hash(participant_frame),
        formula = paste(
          deparse(h08_formula_set("participant")$additive),
          collapse = " "
        )
      ),
      participant_effect,
      participant_status,
      participant_condition
    )
  }
}

photoperiod_sensitivity <- dplyr::bind_rows(photoperiod_rows) |>
  dplyr::arrange(.data$placement, .data$metric_order)
participant_summary_sensitivity <- dplyr::bind_rows(participant_rows) |>
  dplyr::arrange(.data$placement, .data$metric_order)

h08_write_csv(
  photoperiod_sensitivity,
  file.path(roots$tables, "H08_photoperiod_sensitivity.csv")
)
h08_write_csv(
  participant_summary_sensitivity,
  file.path(roots$tables, "H08_participant_summary_sensitivity.csv")
)

h08_metric_variant_runs <- function(
  variant = c("exact_longest", "observed_dose")
) {
  variant <- match.arg(variant)
  if (variant == "exact_longest") {
    metric_id <- "longest_bout_above_250"
    value_column <- "longest_exact_value"
    sensitivity_id <- "longest_period_exact_only"
  } else {
    metric_id <- "dose_time_sensitive_corrected_medi"
    value_column <- "dose_observed_value"
    sensitivity_id <- "observed_dose_common_sample"
  }
  source <- model_rows |>
    dplyr::filter(
      .data$data_scenario_id == "main",
      .data$metric_id == .env$metric_id,
      is.finite(.data$value),
      is.finite(.data[[value_column]])
    )
  variant_pair_keys <- source |>
    dplyr::group_by(
      .data$site,
      .data$Id,
      .data$local_date,
      .data$metric_id
    ) |>
    dplyr::summarise(
      placements = dplyr::n_distinct(.data$placement),
      .groups = "drop"
    ) |>
    dplyr::filter(.data$placements == 2L) |>
    dplyr::select(-.data$placements)
  runs <- run_registry |>
    dplyr::filter(
      .data$data_scenario_id == "main",
      .data$sample_scenario %in% c("all_available", "paired_common_sample")
    )
  result_rows <- list()
  models <- list()
  for (index in seq_len(nrow(runs))) {
    run <- runs[index, , drop = FALSE]
    selected <- source |>
      dplyr::filter(.data$placement == run$placement)
    if (run$sample_scenario == "paired_common_sample") {
      selected <- selected |>
        dplyr::inner_join(
          variant_pair_keys,
          by = h08_key_columns,
          relationship = "many-to-one"
        )
    }
    selected$value <- selected[[value_column]]
    spec <- metric_registry[
      metric_registry$metric_id == metric_id,
      ,
      drop = FALSE
    ]
    frame <- h08_prepare_model_frame(
      selected,
      spec,
      site_levels,
      score_contract
    )
    key <- paste(sensitivity_id, run$placement, run$sample_scenario, sep = "__")
    bundle <- h08_fit_bundle(frame, spec, formula_kind = "participant_day")
    models[[key]] <- bundle
    result_rows[[key]] <- dplyr::bind_cols(
      tibble::tibble(
        sensitivity_id = sensitivity_id,
        placement = run$placement,
        placement_label = run$placement_label,
        sample_scenario = run$sample_scenario,
        metric_order = spec$metric_order,
        metric_id = metric_id,
        manuscript_name = spec$manuscript_name,
        participants = dplyr::n_distinct(frame$participant_key),
        participant_days = nrow(frame),
        sites = dplyr::n_distinct(frame$site),
        metric_support_valid_hours = h08_complete_sum(
          frame$metric_support_valid_minutes
        ) /
          60,
        metric_support_expected_hours = h08_complete_sum(
          frame$metric_support_expected_minutes
        ) /
          60,
        row_key_hash = h08_key_hash(frame),
        model_frame_hash = h08_frame_hash(frame)
      ),
      h08_effect_summary(
        bundle$fits$additive$model,
        spec,
        score_contract$participant_sd
      ),
      h08_model_fit_status(bundle$fits$additive$model)
    )
  }
  list(results = dplyr::bind_rows(result_rows), models = models)
}

exact_longest <- h08_metric_variant_runs("exact_longest")
observed_dose <- h08_metric_variant_runs("observed_dose")
sensitivity_models <- c(
  sensitivity_models,
  exact_longest$models,
  observed_dose$models
)
h08_write_csv(
  exact_longest$results,
  file.path(
    roots$tables,
    "H08_exactly_identified_longest_period_sensitivity.csv"
  )
)
h08_write_csv(
  observed_dose$results,
  file.path(roots$tables, "H08_observed_dose_sensitivity.csv")
)

leave_one_site_out_rows <- list()
for (placement in c("glasses", "chest")) {
  run_id <- paste("main", placement, "all_available", sep = "__")
  for (metric_index in seq_len(nrow(metric_registry))) {
    spec <- metric_registry[metric_index, , drop = FALSE]
    key <- paste(run_id, spec$metric_id, sep = "__")
    frame <- model_frames[[key]]
    full_effect <- model_effects |>
      dplyr::filter(
        .data$run_id == .env$run_id,
        .data$metric_id == spec$metric_id
      )
    loo <- h08_leave_one_site_out(
      frame,
      spec,
      score_contract$participant_sd,
      full_effect$estimate_model_per_point
    )
    leave_one_site_out_rows[[key]] <- dplyr::bind_cols(
      tibble::tibble(
        placement = placement,
        placement_label = ifelse(placement == "glasses", "Near eye", "Chest"),
        metric_order = spec$metric_order,
        metric_id = spec$metric_id,
        manuscript_name = spec$manuscript_name
      )[rep(1L, nrow(loo)), , drop = FALSE],
      loo
    )
  }
}
leave_one_site_out <- dplyr::bind_rows(leave_one_site_out_rows) |>
  dplyr::left_join(
    site_registry |>
      dplyr::select(
        omitted_site = .data$site,
        omitted_site_display_order = .data$display_order,
        omitted_site_name = .data$display_name
      ),
    by = "omitted_site",
    relationship = "many-to-one"
  ) |>
  dplyr::arrange(
    .data$placement,
    .data$metric_order,
    .data$omitted_site_display_order
  )
h08_write_csv(
  leave_one_site_out,
  file.path(roots$diagnostics, "H08_leave_one_site_out.csv")
)
h08_write_rds(
  list(
    hypothesis_id = "H08",
    sensitivity_registry = sensitivity_registry,
    sensitivity_models = sensitivity_models
  ),
  file.path(roots$models, "H08_sensitivity_models.rds")
)

####
# Step 5: Reconstruct V0 and compare implementations
####

message("H08 V0 reconstruction: near eye")
v0_near_eye <- h08_reproduce_v0_placement(
  input_contract$absolute_path[
    input_contract$input_role == "v0_near_eye_metrics"
  ],
  "Near eye",
  vlsq,
  metric_registry
)
message("H08 V0 reconstruction: chest")
v0_chest <- h08_reproduce_v0_placement(
  input_contract$absolute_path[input_contract$input_role == "v0_chest_metrics"],
  "Chest",
  vlsq,
  metric_registry
)

h08_extract_v0_render <- function(path, placement) {
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
  table_index <- which(grepl("H8: Model results", titles, fixed = TRUE))
  if (length(table_index) != 1L) {
    h08_abort("Could not uniquely identify the V0 H08 table in `%s`", path)
  }
  result <- rvest::html_table(tables[[table_index]], fill = TRUE)
  result <- result[
    result[[1L]] %in% c("level", "duration", "exposure history"),
    seq_len(4L),
    drop = FALSE
  ]
  names(result) <- c(
    "metric_type",
    "v0_name",
    "displayed_adjusted_p",
    "displayed_supported"
  )
  tibble::as_tibble(result) |>
    dplyr::mutate(placement = placement, .before = 1L)
}

v0_render <- dplyr::bind_rows(
  h08_extract_v0_render(
    input_contract$absolute_path[
      input_contract$input_role == "v0_near_eye_render"
    ],
    "Near eye"
  ),
  h08_extract_v0_render(
    input_contract$absolute_path[
      input_contract$input_role == "v0_chest_render"
    ],
    "Chest"
  )
)
v0_results <- dplyr::bind_rows(v0_near_eye$results, v0_chest$results) |>
  dplyr::left_join(
    v0_render,
    by = c("placement", "v0_name"),
    relationship = "one-to-one"
  ) |>
  dplyr::arrange(.data$placement, .data$metric_order)

new_main <- model_results_master |>
  dplyr::filter(
    .data$run_id %in%
      c(
        "main__glasses__all_available",
        "main__chest__all_available"
      )
  ) |>
  dplyr::mutate(
    placement_join = dplyr::if_else(
      .data$placement == "glasses",
      "Near eye",
      "Chest"
    )
  )
v0_to_new <- v0_results |>
  dplyr::left_join(
    new_main |>
      dplyr::select(
        placement_join,
        .data$metric_id,
        new_participants = .data$participants,
        new_participant_days = .data$participant_days,
        new_sites = .data$sites,
        new_average_p_raw = .data$average_p_raw,
        new_average_p_adjusted = .data$average_p_adjusted,
        new_average_adjusted_significant = .data$average_adjusted_significant,
        new_interaction_p_raw = .data$interaction_p_raw,
        new_interaction_p_adjusted = .data$interaction_p_adjusted,
        new_estimate_practical_per_sd = .data$estimate_practical_per_sd,
        new_conf_low_practical_per_sd = .data$conf_low_practical_per_sd,
        new_conf_high_practical_per_sd = .data$conf_high_practical_per_sd,
        new_effect_type = .data$effect_type
      ),
    by = c("placement" = "placement_join", "metric_id"),
    relationship = "one-to-one"
  ) |>
  dplyr::mutate(
    participant_change = .data$new_participants - .data$participants,
    participant_day_change = .data$new_participant_days -
      .data$participant_days,
    v0_scalar_significant = .data$association_scalar_adjusted_p <= 0.05,
    v0_vector_bh_significant = .data$consistent_vector_bh_p <= 0.05,
    new_conclusion_differs_from_v0_scalar = .data$new_average_adjusted_significant !=
      .data$v0_scalar_significant,
    comparison_note = paste0(
      "V0 tests the joint score-plus-interaction block with treatment coding; ",
      "the audited primary test is the additive average score slope with explicit sum coding"
    )
  )

h08_write_csv(v0_results, file.path(roots$tables, "H08_v0_reproduction.csv"))
h08_write_csv(
  v0_to_new,
  file.path(roots$tables, "H08_v0_to_new_comparison.csv")
)
h08_write_csv(
  dplyr::bind_rows(v0_near_eye$model_rows, v0_chest$model_rows),
  file.path(roots$model_data, "H08_v0_model_rows.csv")
)
h08_write_rds(
  list(
    hypothesis_id = "H08",
    near_eye = v0_near_eye$models,
    chest = v0_chest$models
  ),
  file.path(roots$models, "H08_v0_models.rds")
)

####
# Step 6: Classify stability and diagnostic gates
####

h08_stability_class <- function(
  estimate_a,
  low_a,
  high_a,
  estimate_b,
  low_b,
  high_b,
  conclusion_a = NA,
  conclusion_b = NA
) {
  if (
    any(!is.finite(c(estimate_a, low_a, high_a, estimate_b, low_b, high_b)))
  ) {
    return("non-estimable")
  }
  if (
    sign(estimate_a) != sign(estimate_b) && estimate_a != 0 && estimate_b != 0
  ) {
    return("direction-sensitive")
  }
  if (
    !is.na(conclusion_a) && !is.na(conclusion_b) && conclusion_a != conclusion_b
  ) {
    return("multiplicity-conclusion-sensitive")
  }
  excludes_zero_a <- low_a > 0 || high_a < 0
  excludes_zero_b <- low_b > 0 || high_b < 0
  if (excludes_zero_a != excludes_zero_b) {
    return("precision-sensitive")
  }
  mutually_contained <-
    estimate_a >= low_b &&
    estimate_a <= high_b &&
    estimate_b >= low_a &&
    estimate_b <= high_a
  if (!mutually_contained) {
    return("magnitude-sensitive")
  }
  "stable within model uncertainty"
}

scenario_effects <- model_results_master |>
  dplyr::filter(
    .data$sample_scenario %in% c("all_available", "main_gap_common_sample"),
    .data$data_scenario_id %in% c("main", "gap_timing_unaware")
  ) |>
  dplyr::select(
    .data$placement,
    .data$sample_scenario,
    .data$metric_order,
    .data$metric_id,
    .data$manuscript_name,
    .data$data_scenario_id,
    estimate = .data$estimate_model_per_sd,
    conf_low = .data$conf_low_model_per_sd,
    conf_high = .data$conf_high_model_per_sd,
    p_adjusted = .data$average_p_adjusted,
    adjusted_significant = .data$average_adjusted_significant,
    participants = .data$participants,
    participant_days = .data$participant_days,
    sites = .data$sites,
    row_key_hash = .data$row_key_hash
  ) |>
  tidyr::pivot_wider(
    names_from = .data$data_scenario_id,
    values_from = c(
      .data$estimate,
      .data$conf_low,
      .data$conf_high,
      .data$p_adjusted,
      .data$adjusted_significant,
      .data$participants,
      .data$participant_days,
      .data$sites,
      .data$row_key_hash
    )
  ) |>
  dplyr::rowwise() |>
  dplyr::mutate(
    exact_common_keys = dplyr::if_else(
      .data$sample_scenario == "main_gap_common_sample",
      .data$row_key_hash_main == .data$row_key_hash_gap_timing_unaware,
      NA
    ),
    stability_classification = h08_stability_class(
      .data$estimate_main,
      .data$conf_low_main,
      .data$conf_high_main,
      .data$estimate_gap_timing_unaware,
      .data$conf_low_gap_timing_unaware,
      .data$conf_high_gap_timing_unaware,
      .data$adjusted_significant_main,
      .data$adjusted_significant_gap_timing_unaware
    )
  ) |>
  dplyr::ungroup() |>
  dplyr::arrange(.data$sample_scenario, .data$placement, .data$metric_order)

loo_summary <- leave_one_site_out |>
  dplyr::group_by(
    .data$placement,
    .data$placement_label,
    .data$metric_order,
    .data$metric_id,
    .data$manuscript_name
  ) |>
  dplyr::summarise(
    refits = dplyr::n(),
    successful_refits = sum(.data$refit_status == "PASS"),
    sign_reversal_any = any(.data$sign_reversal, na.rm = TRUE),
    maximum_relative_absolute_change = max(
      .data$relative_absolute_change,
      na.rm = TRUE
    ),
    most_influential_omitted_site = .data$omitted_site_name[
      which.max(.data$relative_absolute_change)
    ],
    influence_status = dplyr::case_when(
      .data$successful_refits < .data$refits ~ "non-estimable refit present",
      .data$sign_reversal_any ~ "direction-sensitive to one site",
      .data$maximum_relative_absolute_change >= 0.5 ~
        "magnitude-sensitive to one site",
      TRUE ~ "direction stable in leave-one-site-out refits"
    ),
    .groups = "drop"
  )

response_family_gate <- model_diagnostics |>
  dplyr::filter(.data$inferential_run) |>
  dplyr::group_by(
    .data$metric_order,
    .data$metric_id,
    .data$manuscript_name,
    .data$response_family,
    .data$response_transform
  ) |>
  dplyr::summarise(
    inferential_targets = dplyr::n(),
    major_failures = sum(.data$diagnostic_status == "FAIL_MAJOR_GATE"),
    review_targets = sum(.data$diagnostic_status == "REVIEW_WITH_LIMITATIONS"),
    average_non_estimable = sum(.data$average_effect_status != "ESTIMABLE"),
    interaction_non_estimable = sum(
      .data$interaction_effect_status != "ESTIMABLE"
    ),
    family_gate_status = dplyr::case_when(
      .data$major_failures > 0L || .data$average_non_estimable > 0L ~
        "OPEN_COMMON_RESPONSE_FAMILY_GATE",
      .data$review_targets > 0L ~ "RETAIN_WITH_EXPLICIT_LIMITATIONS",
      TRUE ~ "PASS"
    ),
    .groups = "drop"
  )

h08_write_csv(
  scenario_effects,
  file.path(roots$tables, "H08_gap_timing_unaware_sensitivity.csv")
)
h08_write_csv(
  loo_summary,
  file.path(roots$diagnostics, "H08_leave_one_site_out_summary.csv")
)
h08_write_csv(
  response_family_gate,
  file.path(roots$diagnostics, "H08_response_family_gate.csv")
)

####
# Step 7: Create reader-facing figures with paired source CSVs
####

h08_effect_plot_data <- model_results_master |>
  dplyr::filter(
    .data$run_id %in%
      c(
        "main__glasses__all_available",
        "main__chest__all_available"
      )
  ) |>
  dplyr::mutate(
    plot_estimate = dplyr::if_else(
      .data$effect_type == "ratio",
      100 * (.data$estimate_practical_per_sd - 1),
      .data$estimate_practical_per_sd
    ),
    plot_conf_low = dplyr::if_else(
      .data$effect_type == "ratio",
      100 * (.data$conf_low_practical_per_sd - 1),
      .data$conf_low_practical_per_sd
    ),
    plot_conf_high = dplyr::if_else(
      .data$effect_type == "ratio",
      100 * (.data$conf_high_practical_per_sd - 1),
      .data$conf_high_practical_per_sd
    ),
    plot_scale = dplyr::if_else(
      .data$effect_type == "ratio",
      "Percent change per one VLSQ-8 SD",
      "Difference (h) per one VLSQ-8 SD"
    ),
    metric_label = factor(
      .data$manuscript_name,
      levels = rev(metric_registry$manuscript_name)
    )
  )

h08_save_effect_plot <- function(data, placement, stem, title, colour) {
  plot_data <- data |>
    dplyr::filter(.data$placement == .env$placement)
  source_path <- file.path(
    roots$source_data,
    paste0(stem, "_data.csv")
  )
  h08_write_csv(plot_data, source_path)
  plot <- ggplot2::ggplot(
    plot_data,
    ggplot2::aes(
      x = .data$plot_estimate,
      y = .data$metric_label,
      xmin = .data$plot_conf_low,
      xmax = .data$plot_conf_high
    )
  ) +
    ggplot2::geom_vline(xintercept = 0, colour = "grey55", linewidth = 0.5) +
    ggplot2::geom_errorbar(
      orientation = "y",
      width = 0.18,
      linewidth = 0.65,
      colour = colour
    ) +
    ggplot2::geom_point(
      size = 2.3,
      shape = 21,
      fill = "white",
      colour = colour
    ) +
    ggplot2::facet_wrap(
      ggplot2::vars(.data$plot_scale),
      ncol = 1,
      scales = "free",
      space = "free_y",
      strip.position = "right"
    ) +
    ggplot2::labs(
      title = title,
      subtitle = paste0(
        "Adjusted association per ",
        sprintf("%.4f", score_contract$participant_sd),
        " VLSQ-8 points; points and bars are estimates and 95% Wald intervals"
      ),
      x = NULL,
      y = NULL,
      caption = paste0(
        "Ratios are shown as percent change. Time below 10 lx melEDI before sleep ",
        "uses an identity-Gaussian difference in hours."
      )
    ) +
    ggplot2::theme_minimal(base_size = 10) +
    ggplot2::theme(
      plot.title.position = "plot",
      panel.grid.minor = ggplot2::element_blank(),
      strip.text.y = ggplot2::element_text(angle = 0, hjust = 0),
      axis.text.y = ggplot2::element_text(size = 8),
      plot.caption = ggplot2::element_text(hjust = 0, size = 7)
    )
  ggplot2::ggsave(
    file.path(roots$figures, paste0(stem, ".png")),
    plot,
    width = 9,
    height = 7.2,
    units = "in",
    dpi = 300,
    bg = "white"
  )
  ggplot2::ggsave(
    file.path(roots$figures, paste0(stem, ".pdf")),
    plot,
    width = 9,
    height = 7.2,
    units = "in",
    bg = "white"
  )
  invisible(source_path)
}

h08_save_effect_plot(
  h08_effect_plot_data,
  "glasses",
  "H08_near_eye_effects",
  "Near-eye VLSQ-8 associations",
  "#0072B2"
)
h08_save_effect_plot(
  h08_effect_plot_data,
  "chest",
  "H08_chest_effects",
  "Chest VLSQ-8 associations",
  "#D55E00"
)

paired_effects <- model_results_master |>
  dplyr::filter(
    .data$data_scenario_id == "main",
    .data$sample_scenario == "paired_common_sample"
  ) |>
  dplyr::left_join(
    metric_registry |>
      dplyr::select(
        .data$metric_id,
        .data$abbreviation,
        .data$manuscript_category
      ),
    by = "metric_id",
    relationship = "many-to-one"
  ) |>
  dplyr::mutate(
    comparison_estimate = dplyr::if_else(
      .data$effect_type == "ratio",
      log(pmax(.data$estimate_practical_per_sd, .Machine$double.xmin)),
      .data$estimate_practical_per_sd
    ),
    comparison_low = dplyr::if_else(
      .data$effect_type == "ratio",
      log(pmax(.data$conf_low_practical_per_sd, .Machine$double.xmin)),
      .data$conf_low_practical_per_sd
    ),
    comparison_high = dplyr::if_else(
      .data$effect_type == "ratio",
      log(pmax(.data$conf_high_practical_per_sd, .Machine$double.xmin)),
      .data$conf_high_practical_per_sd
    ),
    comparison_scale = dplyr::if_else(
      .data$effect_type == "ratio",
      "Natural-log ratio per one VLSQ-8 SD",
      "Difference in hours per one VLSQ-8 SD"
    )
  ) |>
  dplyr::select(
    .data$metric_order,
    .data$metric_id,
    .data$manuscript_name,
    .data$abbreviation,
    .data$manuscript_category,
    .data$effect_type,
    .data$comparison_scale,
    .data$placement,
    .data$comparison_estimate,
    .data$comparison_low,
    .data$comparison_high,
    .data$participants,
    .data$participant_days,
    .data$sites,
    .data$row_key_hash
  ) |>
  tidyr::pivot_wider(
    names_from = .data$placement,
    values_from = c(
      .data$comparison_estimate,
      .data$comparison_low,
      .data$comparison_high,
      .data$participants,
      .data$participant_days,
      .data$sites,
      .data$row_key_hash
    )
  ) |>
  dplyr::mutate(
    exact_sample_match = .data$row_key_hash_glasses == .data$row_key_hash_chest,
    included_in_identity_plot = .data$effect_type == "ratio"
  )
if (any(!paired_effects$exact_sample_match)) {
  h08_abort("The H08 paired effect display contains unmatched samples")
}
h08_write_csv(
  paired_effects,
  file.path(roots$source_data, "H08_paired_placement_effects_data.csv")
)

paired_ratio <- paired_effects |>
  dplyr::filter(.data$included_in_identity_plot)
paired_plot <- ggplot2::ggplot(
  paired_ratio,
  ggplot2::aes(
    x = .data$comparison_estimate_glasses,
    y = .data$comparison_estimate_chest,
    colour = .data$manuscript_category,
    shape = .data$manuscript_category
  )
) +
  ggplot2::geom_abline(
    intercept = 0,
    slope = 1,
    linetype = "dashed",
    colour = "grey45",
    linewidth = 0.6
  ) +
  ggplot2::geom_vline(xintercept = 0, colour = "grey70", linewidth = 0.5) +
  ggplot2::geom_hline(yintercept = 0, colour = "grey70", linewidth = 0.5) +
  ggplot2::geom_errorbar(
    ggplot2::aes(
      ymin = .data$comparison_low_chest,
      ymax = .data$comparison_high_chest
    ),
    width = 0,
    linewidth = 0.45
  ) +
  ggplot2::geom_errorbar(
    ggplot2::aes(
      xmin = .data$comparison_low_glasses,
      xmax = .data$comparison_high_glasses
    ),
    orientation = "y",
    width = 0,
    linewidth = 0.45
  ) +
  ggplot2::geom_point(size = 2.8, stroke = 0.9) +
  ggplot2::geom_text(
    ggplot2::aes(label = .data$abbreviation),
    nudge_y = 0.018,
    size = 2.8,
    show.legend = FALSE,
    check_overlap = TRUE
  ) +
  ggplot2::coord_equal() +
  ggplot2::scale_colour_manual(
    values = c(
      "level-based" = "#0072B2",
      "duration-based" = "#009E73",
      "exposure-history-based" = "#CC79A7"
    )
  ) +
  ggplot2::labs(
    title = "Paired near-eye and chest association estimates",
    subtitle = paste0(
      "Separate models use identical participant-days;\n",
      "ratio outcomes use the natural-log ratio scale per one VLSQ-8 SD"
    ),
    x = "Near-eye estimate",
    y = "Chest estimate",
    colour = "Metric category",
    shape = "Metric category",
    caption = paste0(
      "Dashed line: identical estimates; grey lines: null; component bars: ",
      "95% Wald intervals.\n",
      "The identity-Gaussian pre-sleep metric remains in the paired source ",
      "table because hours and log ratios must not share an axis."
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
  file.path(roots$figures, "H08_paired_placement_effects.png"),
  paired_plot,
  width = 7.2,
  height = 7.2,
  units = "in",
  dpi = 300,
  bg = "white"
)
ggplot2::ggsave(
  file.path(roots$figures, "H08_paired_placement_effects.pdf"),
  paired_plot,
  width = 7.2,
  height = 7.2,
  units = "in",
  bg = "white"
)

gap_common_plot_data <- scenario_effects |>
  dplyr::filter(.data$sample_scenario == "main_gap_common_sample") |>
  dplyr::left_join(
    metric_registry |>
      dplyr::select(.data$metric_id, .data$abbreviation, .data$effect_scale),
    by = "metric_id",
    relationship = "many-to-one"
  ) |>
  dplyr::mutate(
    included_in_identity_plot = .data$effect_scale == "ratio",
    placement_label = dplyr::if_else(
      .data$placement == "glasses",
      "Near eye",
      "Chest"
    ),
    primary_log_ratio = dplyr::if_else(
      .data$effect_scale == "ratio",
      dplyr::case_when(
        .data$metric_id %in%
          c(
            "daily_geometric_mean_medi",
            "m10_mean_medi",
            "l10_mean_medi",
            "longest_bout_above_250",
            "dose_time_sensitive_corrected_medi"
          ) ~
          log(10) * .data$estimate_main,
        TRUE ~ .data$estimate_main
      ),
      .data$estimate_main
    ),
    gap_log_ratio = dplyr::if_else(
      .data$effect_scale == "ratio",
      dplyr::case_when(
        .data$metric_id %in%
          c(
            "daily_geometric_mean_medi",
            "m10_mean_medi",
            "l10_mean_medi",
            "longest_bout_above_250",
            "dose_time_sensitive_corrected_medi"
          ) ~
          log(10) * .data$estimate_gap_timing_unaware,
        TRUE ~ .data$estimate_gap_timing_unaware
      ),
      .data$estimate_gap_timing_unaware
    )
  )
h08_write_csv(
  gap_common_plot_data,
  file.path(roots$source_data, "H08_gap_common_sample_effects_data.csv")
)
gap_plot <- ggplot2::ggplot(
  gap_common_plot_data |>
    dplyr::filter(.data$included_in_identity_plot),
  ggplot2::aes(
    x = .data$primary_log_ratio,
    y = .data$gap_log_ratio,
    colour = .data$placement_label,
    shape = .data$placement_label,
    label = .data$abbreviation
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
  ggplot2::geom_point(size = 2.6, stroke = 0.8) +
  ggplot2::geom_text(
    nudge_y = 0.015,
    size = 2.7,
    show.legend = FALSE,
    check_overlap = TRUE
  ) +
  ggplot2::coord_equal() +
  ggplot2::scale_colour_manual(
    values = c("Near eye" = "#0072B2", "Chest" = "#D55E00")
  ) +
  ggplot2::labs(
    title = "Primary and gap-timing-unaware estimates on common samples",
    subtitle = "Ratio outcomes; natural-log ratio per one VLSQ-8 SD",
    x = "Primary dataset estimate",
    y = "Gap-timing-unaware dataset estimate",
    colour = "Placement",
    shape = "Placement",
    caption = paste0(
      "Dashed line: identical estimates; grey lines: null. Each scenario uses ",
      "the same participant-days within metric and placement."
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
  file.path(roots$figures, "H08_gap_common_sample_effects.png"),
  gap_plot,
  width = 7.2,
  height = 7.2,
  units = "in",
  dpi = 300,
  bg = "white"
)

near_diagnostic <- diagnostic_plot_data |>
  dplyr::filter(.data$run_id == "main__glasses__all_available") |>
  dplyr::mutate(
    manuscript_name = factor(
      .data$manuscript_name,
      levels = metric_registry$manuscript_name
    )
  )
h08_write_csv(
  near_diagnostic,
  file.path(roots$source_data, "H08_near_eye_model_adequacy_data.csv")
)
residual_panel <- near_diagnostic |>
  dplyr::transmute(
    .data$manuscript_name,
    panel = "Residual versus fitted",
    x = .data$fitted_model_scale,
    y = .data$residual_pearson
  )
qq_panel <- near_diagnostic |>
  dplyr::transmute(
    .data$manuscript_name,
    panel = "Normal Q-Q",
    x = .data$qq_theoretical,
    y = .data$qq_observed
  )
adequacy_plot_data <- dplyr::bind_rows(residual_panel, qq_panel)
adequacy_plot <- ggplot2::ggplot(
  adequacy_plot_data,
  ggplot2::aes(x = .data$x, y = .data$y)
) +
  ggplot2::geom_hline(yintercept = 0, colour = "grey70", linewidth = 0.4) +
  ggplot2::geom_point(alpha = 0.35, size = 0.7, colour = "#0072B2") +
  ggplot2::facet_grid(
    rows = ggplot2::vars(.data$manuscript_name),
    cols = ggplot2::vars(.data$panel),
    scales = "free"
  ) +
  ggplot2::labs(
    title = "Near-eye additive-model adequacy",
    subtitle = "Conditional Pearson residual screens; no simulation or resampling",
    x = NULL,
    y = NULL,
    caption = paste0(
      "The Q-Q panels are descriptive residual-shape checks. Formal numerical ",
      "fit, bound, zero-mass, and serial-dependence diagnostics are reported separately."
    )
  ) +
  ggplot2::theme_minimal(base_size = 9) +
  ggplot2::theme(
    plot.title.position = "plot",
    strip.text.y = ggplot2::element_text(angle = 0, hjust = 0, size = 7),
    strip.text.x = ggplot2::element_text(size = 8),
    panel.grid.minor = ggplot2::element_blank(),
    plot.caption = ggplot2::element_text(hjust = 0, size = 7)
  )
ggplot2::ggsave(
  file.path(roots$figures, "H08_near_eye_model_adequacy.png"),
  adequacy_plot,
  width = 10,
  height = 15,
  units = "in",
  dpi = 240,
  bg = "white"
)

figure_manifest <- tibble::tribble(
  ~figure_path,
  ~source_data_path,
  ~width_in,
  ~height_in,
  ~alt_text,
  "artifacts/10_figures/H08/H08_near_eye_effects.png",
  "artifacts/11_source_data/H08/H08_near_eye_effects_data.csv",
  9,
  7.2,
  paste0(
    "Forest plot of nine site-adjusted near-eye associations per one VLSQ-8 ",
    "standard deviation. Points show estimates and horizontal bars show 95% ",
    "Wald intervals; a vertical zero line marks no change."
  ),
  "artifacts/10_figures/H08/H08_chest_effects.png",
  "artifacts/11_source_data/H08/H08_chest_effects_data.csv",
  9,
  7.2,
  paste0(
    "Forest plot of nine complementary chest associations per one VLSQ-8 ",
    "standard deviation. Points show estimates and horizontal bars show 95% ",
    "Wald intervals; a vertical zero line marks no change."
  ),
  "artifacts/10_figures/H08/H08_paired_placement_effects.png",
  "artifacts/11_source_data/H08/H08_paired_placement_effects_data.csv",
  7.2,
  7.2,
  paste0(
    "Scatterplot comparing separately fitted near-eye and chest log-ratio ",
    "associations on identical participant-days. Error bars show component ",
    "95% intervals, grey lines show the null, and the dashed diagonal shows ",
    "identical placement estimates."
  ),
  "artifacts/10_figures/H08/H08_gap_common_sample_effects.png",
  "artifacts/11_source_data/H08/H08_gap_common_sample_effects_data.csv",
  7.2,
  7.2,
  paste0(
    "Scatterplot comparing primary and gap-timing-unaware log-ratio ",
    "associations on identical participant-days. Grey lines show the null and ",
    "the dashed diagonal shows identical scenario estimates."
  ),
  "artifacts/10_figures/H08/H08_near_eye_model_adequacy.png",
  "artifacts/11_source_data/H08/H08_near_eye_model_adequacy_data.csv",
  10,
  15,
  paste0(
    "Eighteen-panel diagnostic plot showing residual-versus-fitted and normal ",
    "Q-Q screens for each of the nine primary near-eye additive models."
  )
)
h08_write_csv(
  figure_manifest,
  file.path(roots$manifests, "H08_figure_manifest.csv")
)

####
# Step 8: Record the execution environment and artifact manifest
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
    "None; analytical Tweedie zero-mass check used, so no bootstrap/simulation pilot was required"
  )
)
h08_write_csv(
  execution_environment,
  file.path(roots$manifests, "H08_execution_environment.csv")
)

h08_build_manifest()
message("H08 Stage 2 fitting and artifact generation complete")
