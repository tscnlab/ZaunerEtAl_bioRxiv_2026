#!/usr/bin/env Rscript

# Reseal only the H08 primary-dataset L10 branch after METRIC-011. The six
# primary L10 participant-day bundles, their directly inherited sensitivities,
# and complete-family BH derivatives may change. Every gap-timing-unaware
# model, every non-L10 fit/raw test, V0, longest-period and observed-dose
# sensitivity, and all MDER work are immutable.

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
  stop("The verified R 4.6 project library is unavailable", call. = FALSE)
}
.libPaths(c(project_library, .libPaths()))

source(file.path(root, "scripts/pipeline/paths_io.R"))
source(file.path(root, "scripts/pipeline/multiplicity.R"))
source(file.path(root, "scripts/pipeline/p_value_display.R"))
source(file.path(root, "scripts/hypotheses/H08/h08_contract.R"))
source(file.path(root, "scripts/hypotheses/H08/h08_modeling.R"))

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("The H08 METRIC-011 reseal requires R 4.6.1", call. = FALSE)
}

required_packages <- c(
  "dplyr",
  "tidyr",
  "tibble",
  "readr",
  "digest",
  "openssl",
  "lme4",
  "reformulas",
  "glmmTMB",
  "performance"
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
  stop(
    "Missing project package(s): ",
    paste(missing_packages, collapse = ", "),
    call. = FALSE
  )
}

options(lifecycle_verbosity = "quiet", warn = 1)

producer <- "scripts/hypotheses/H08/reseal_h08_l10_metric011.R"
metric_id <- "l10_mean_medi"
decision_id <- "METRIC-011"

roots <- list(
  model_data = file.path(root, "artifacts/06_model_data/H08"),
  models = file.path(root, "artifacts/07_models/H08"),
  diagnostics = file.path(root, "artifacts/08_diagnostics/H08"),
  tables = file.path(root, "artifacts/09_tables/H08"),
  source_data = file.path(root, "artifacts/11_source_data/H08"),
  manifests = file.path(root, "artifacts/12_manifests/H08")
)

read_h08_csv <- function(path) {
  readr::read_csv(path, show_col_types = FALSE, na = "")
}

relative_path <- function(path) {
  normalized <- normalizePath(path, winslash = "/", mustWork = TRUE)
  substring(normalized, nchar(root) + 2L)
}

row_key <- function(data, keys) {
  if (!all(keys %in% names(data))) {
    stop("A row-key column is missing", call. = FALSE)
  }
  do.call(paste, c(lapply(data[keys], as.character), sep = "\r"))
}

align_to_baseline <- function(new, baseline) {
  missing <- setdiff(names(baseline), names(new))
  if (length(missing) > 0L) {
    stop(
      "Replacement rows are missing column(s): ",
      paste(missing, collapse = ", "),
      call. = FALSE
    )
  }
  new <- new[names(baseline)]
  for (name in names(baseline)) {
    if (inherits(baseline[[name]], "Date")) {
      new[[name]] <- as.Date(new[[name]])
    } else if (is.character(baseline[[name]])) {
      new[[name]] <- as.character(new[[name]])
    } else if (is.double(baseline[[name]])) {
      new[[name]] <- as.numeric(new[[name]])
    } else if (is.integer(baseline[[name]])) {
      new[[name]] <- as.integer(new[[name]])
    } else if (is.logical(baseline[[name]])) {
      new[[name]] <- as.logical(new[[name]])
    }
  }
  tibble::as_tibble(new)
}

replace_rows_by_key <- function(baseline, replacement, target, keys) {
  if (length(target) != nrow(baseline) || anyNA(target)) {
    stop("A replacement target is invalid", call. = FALSE)
  }
  replacement <- align_to_baseline(replacement, baseline)
  expected <- baseline[target, , drop = FALSE]
  if (nrow(expected) != nrow(replacement)) {
    stop("Replacement row count differs from its target", call. = FALSE)
  }
  expected_key <- row_key(expected, keys)
  replacement_key <- row_key(replacement, keys)
  index <- match(expected_key, replacement_key)
  if (
    anyNA(index) ||
      anyDuplicated(expected_key) ||
      anyDuplicated(replacement_key)
  ) {
    stop("Replacement keys are incomplete or duplicated", call. = FALSE)
  }
  replacement <- replacement[index, , drop = FALSE]
  output <- baseline
  for (name in names(output)) {
    output[[name]][target] <- replacement[[name]]
  }
  tibble::as_tibble(output)
}

update_fields_by_key <- function(
  baseline,
  replacement,
  target,
  keys,
  fields
) {
  if (length(target) != nrow(baseline) || anyNA(target)) {
    stop("A field-update target is invalid", call. = FALSE)
  }
  if (!all(c(keys, fields) %in% names(replacement))) {
    stop("A field-update replacement is incomplete", call. = FALSE)
  }
  replacement <- align_to_baseline(replacement, baseline)
  expected <- baseline[target, , drop = FALSE]
  if (nrow(expected) != nrow(replacement)) {
    stop("Field-update row count differs from its target", call. = FALSE)
  }
  expected_key <- row_key(expected, keys)
  replacement_key <- row_key(replacement, keys)
  index <- match(expected_key, replacement_key)
  if (
    anyNA(index) ||
      anyDuplicated(expected_key) ||
      anyDuplicated(replacement_key)
  ) {
    stop("Field-update keys are incomplete or duplicated", call. = FALSE)
  }
  replacement <- replacement[index, , drop = FALSE]
  output <- baseline
  for (name in fields) {
    output[[name]][target] <- replacement[[name]]
  }
  tibble::as_tibble(output)
}

split_csv_tokens <- function(line) {
  characters <- strsplit(line, "", fixed = TRUE)[[1L]]
  tokens <- character()
  current <- character()
  in_quotes <- FALSE
  index <- 1L
  while (index <= length(characters)) {
    character <- characters[[index]]
    if (character == '"') {
      current <- c(current, character)
      if (
        in_quotes &&
          index < length(characters) &&
          characters[[index + 1L]] == '"'
      ) {
        current <- c(current, characters[[index + 1L]])
        index <- index + 2L
        next
      }
      in_quotes <- !in_quotes
    } else if (character == "," && !in_quotes) {
      tokens <- c(tokens, paste0(current, collapse = ""))
      current <- character()
    } else {
      current <- c(current, character)
    }
    index <- index + 1L
  }
  if (in_quotes) {
    stop("An accepted CSV line has unbalanced quotation marks", call. = FALSE)
  }
  c(tokens, paste0(current, collapse = ""))
}

format_csv_row <- function(data, row) {
  connection <- textConnection(readr::format_csv(
    data[row, , drop = FALSE],
    na = ""
  ))
  on.exit(close(connection), add = TRUE)
  lines <- readLines(connection, warn = FALSE)
  if (length(lines) > 0L && identical(tail(lines, 1L), "")) {
    lines <- head(lines, -1L)
  }
  if (length(lines) != 2L) {
    stop(
      "A replacement CSV row contains an unsupported line break",
      call. = FALSE
    )
  }
  lines[[2L]]
}

format_csv_field <- function(data, row, field) {
  connection <- textConnection(readr::format_csv(
    data[row, field, drop = FALSE],
    na = ""
  ))
  on.exit(close(connection), add = TRUE)
  lines <- readLines(connection, warn = FALSE)
  if (length(lines) > 0L && identical(tail(lines, 1L), "")) {
    lines <- head(lines, -1L)
  }
  if (length(lines) != 2L) {
    stop(
      "A replacement CSV field contains an unsupported line break",
      call. = FALSE
    )
  }
  lines[[2L]]
}

scoped_allowed_matrix <- function(
  data,
  target,
  fields,
  additional_scopes = list()
) {
  scopes <- c(
    list(list(target = target, fields = fields)),
    additional_scopes
  )
  allowed <- matrix(
    FALSE,
    nrow = nrow(data),
    ncol = ncol(data),
    dimnames = list(NULL, names(data))
  )
  for (scope in scopes) {
    if (
      length(scope$target) != nrow(data) ||
        anyNA(scope$target) ||
        !all(scope$fields %in% names(data))
    ) {
      stop("A scoped CSV cell contract is invalid", call. = FALSE)
    }
    allowed[scope$target, scope$fields] <- TRUE
  }
  allowed
}

write_scoped_csv_artifact <- function(
  data,
  path,
  producer,
  baseline_data,
  baseline_lines,
  target,
  fields = names(data),
  additional_scopes = list()
) {
  if (
    !identical(names(data), names(baseline_data)) ||
      nrow(data) != nrow(baseline_data) ||
      length(target) != nrow(data) ||
      anyNA(target) ||
      !all(fields %in% names(data)) ||
      length(baseline_lines) != nrow(baseline_data) + 1L
  ) {
    stop("A scoped CSV write contract is invalid", call. = FALSE)
  }
  allowed <- scoped_allowed_matrix(
    data,
    target,
    fields,
    additional_scopes
  )
  for (field in names(data)) {
    protected_rows <- !allowed[, field]
    if (
      !identical(
        data[[field]][protected_rows],
        baseline_data[[field]][protected_rows]
      )
    ) {
      stop(
        "A scoped CSV write would alter a protected cell in ",
        field,
        call. = FALSE
      )
    }
  }

  output_lines <- baseline_lines
  header_tokens <- split_csv_tokens(output_lines[[1L]])
  if (!identical(header_tokens, names(data))) {
    stop("An accepted CSV header does not match its parsed data", call. = FALSE)
  }
  target_rows <- which(rowSums(allowed) > 0L)
  for (row in target_rows) {
    row_fields <- names(data)[allowed[row, ]]
    if (identical(row_fields, names(data))) {
      output_lines[[row + 1L]] <- format_csv_row(data, row)
    } else {
      tokens <- split_csv_tokens(output_lines[[row + 1L]])
      if (length(tokens) != ncol(data)) {
        stop("An accepted CSV row has an unexpected field count", call. = FALSE)
      }
      field_index <- match(row_fields, names(data))
      for (index in seq_along(row_fields)) {
        tokens[[field_index[[index]]]] <- format_csv_field(
          data,
          row,
          row_fields[[index]]
        )
      }
      output_lines[[row + 1L]] <- paste0(tokens, collapse = ",")
    }
  }

  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  temporary <- tempfile(
    pattern = paste0(basename(path), "."),
    tmpdir = dirname(path)
  )
  on.exit(unlink(temporary), add = TRUE)
  writeLines(output_lines, temporary, useBytes = TRUE)
  atomic_replace_artifact(temporary, path)
  info <- file.info(path)
  list(
    path = normalizePath(path, winslash = "/", mustWork = TRUE),
    sha256 = artifact_sha256(path),
    bytes = unname(info$size),
    rows = nrow(data),
    columns = ncol(data),
    producer = producer,
    r_version = as.character(getRversion()),
    written_utc = format(Sys.time(), tz = "UTC", usetz = TRUE)
  )
}

canonical_digest <- function(data, drop = character()) {
  data <- data[, setdiff(names(data), drop), drop = FALSE]
  keys <- intersect(
    c(
      "run_order",
      "run_id",
      "data_scenario_id",
      "placement",
      "sample_scenario",
      "metric_order",
      "metric_id",
      "model_name",
      "comparison_id",
      "site",
      "prediction_id",
      "model_row_id",
      ".model_row_id",
      "participant_key",
      "screen_rank",
      "omitted_site",
      "sensitivity_id",
      "family_id"
    ),
    names(data)
  )
  if (length(keys) > 0L && nrow(data) > 1L) {
    ordering <- do.call(
      order,
      c(lapply(data[keys], as.character), list(na.last = TRUE))
    )
    data <- data[ordering, , drop = FALSE]
  }
  data <- as.data.frame(data, stringsAsFactors = FALSE)
  row.names(data) <- NULL
  digest::digest(data, algo = "sha256", serialize = TRUE)
}

context_for <- function(run, spec) {
  tibble::tibble(
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
}

frame_index_row <- function(run, spec, frame, score_contract) {
  tibble::tibble(
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
}

frame_export_rows <- function(run, spec, frame) {
  frame |>
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
if (
  any(!file.exists(input_contract$absolute_path)) ||
    any(!input_audit$hash_verified)
) {
  stop("A sealed H08 METRIC-011 input fails its pin", call. = FALSE)
}

base_manifest <- read_h08_csv(file.path(
  root,
  "artifacts/12_manifests/base_model_data_artifacts.csv"
))
if (
  !all(
    base_manifest$input_bundle_sha256 ==
      "e840ce9d2a7f653bc5ebbfe020ce087017dfdaf0276df09da578bda30a539916"
  ) ||
    !all(
      base_manifest$metric_manifest_sha256 ==
        "028bce108339c1277df4a070597430ea20b49c34c2888f4eef42741c1fe76a5e"
    ) ||
    !all(
      base_manifest$site_context_manifest_sha256 ==
        "c0c6d7f97782c0d880a213050f576213f5d56b3204a02732f6399e7e4aeb8518"
    )
) {
  stop(
    "The sealed base-model provenance columns fail METRIC-011",
    call. = FALSE
  )
}

score_contract <- h08_score_contract()
metric_registry <- h08_metric_registry()
run_registry <- h08_run_registry()
family_registry <- h08_family_registry()
spec <- metric_registry[metric_registry$metric_id == metric_id, , drop = FALSE]
target_runs <- run_registry |>
  dplyr::filter(.data$data_scenario_id == "main")
target_frame_keys <- paste(target_runs$run_id, metric_id, sep = "__")
if (nrow(spec) != 1L || nrow(target_runs) != 6L) {
  stop("The bounded H08 L10 target registry is invalid", call. = FALSE)
}

site_registry <- read_h08_csv(file.path(
  root,
  "config/site_display_registry.csv"
)) |>
  dplyr::arrange(.data$display_order)
site_levels <- site_registry$site

paths <- c(
  input_audit = file.path(roots$model_data, "H08_input_audit.csv"),
  frame_index = file.path(roots$model_data, "H08_model_frame_index.csv"),
  frame_site = file.path(roots$model_data, "H08_model_frame_by_site.csv"),
  frame_rows = file.path(roots$model_data, "H08_model_frame_rows.csv"),
  frames_archive = file.path(roots$model_data, "H08_model_frames.rds"),
  fit_index = file.path(roots$models, "H08_model_fit_index.csv"),
  bundles_archive = file.path(roots$models, "H08_model_bundles.rds"),
  sensitivity_archive = file.path(roots$models, "H08_sensitivity_models.rds"),
  tests = file.path(roots$tables, "H08_model_tests.csv"),
  effects = file.path(roots$tables, "H08_model_effects.csv"),
  site_slopes = file.path(roots$tables, "H08_site_specific_slopes.csv"),
  predictions = file.path(roots$tables, "H08_centered_predictions.csv"),
  family_audit = file.path(roots$tables, "H08_family_audit.csv"),
  master = file.path(roots$tables, "H08_model_results_master.csv"),
  photoperiod = file.path(roots$tables, "H08_photoperiod_sensitivity.csv"),
  participant = file.path(
    roots$tables,
    "H08_participant_summary_sensitivity.csv"
  ),
  gap = file.path(roots$tables, "H08_gap_timing_unaware_sensitivity.csv"),
  v0_comparison = file.path(roots$tables, "H08_v0_to_new_comparison.csv"),
  diagnostics = file.path(roots$diagnostics, "H08_model_diagnostics.csv"),
  influence = file.path(
    roots$diagnostics,
    "H08_participant_influence_screen.csv"
  ),
  loo = file.path(roots$diagnostics, "H08_leave_one_site_out.csv"),
  loo_summary = file.path(
    roots$diagnostics,
    "H08_leave_one_site_out_summary.csv"
  ),
  response_gate = file.path(roots$diagnostics, "H08_response_family_gate.csv"),
  diagnostic_plot = file.path(
    roots$source_data,
    "H08_primary_diagnostic_plot_data.csv"
  ),
  near_effects = file.path(roots$source_data, "H08_near_eye_effects_data.csv"),
  chest_effects = file.path(roots$source_data, "H08_chest_effects_data.csv"),
  paired_effects = file.path(
    roots$source_data,
    "H08_paired_placement_effects_data.csv"
  ),
  gap_effects = file.path(
    roots$source_data,
    "H08_gap_common_sample_effects_data.csv"
  ),
  near_adequacy = file.path(
    roots$source_data,
    "H08_near_eye_model_adequacy_data.csv"
  )
)
if (any(!file.exists(paths))) {
  stop("A required accepted H08 artifact is missing", call. = FALSE)
}

csv_ids <- names(paths)[tolower(tools::file_ext(paths)) == "csv"]
baseline <- lapply(paths[csv_ids], read_h08_csv)
baseline_lines <- lapply(paths[csv_ids], readLines, warn = FALSE)
baseline_sha <- unname(vapply(paths, artifact_sha256, character(1)))
names(baseline_sha) <- names(paths)

frames_archive <- readRDS(paths[["frames_archive"]])
bundles_archive <- readRDS(paths[["bundles_archive"]])
sensitivity_archive <- readRDS(paths[["sensitivity_archive"]])
if (
  length(frames_archive$model_frames) != 108L ||
    length(bundles_archive$model_bundles) != 108L ||
    length(sensitivity_archive$sensitivity_models) != 44L
) {
  stop("The accepted H08 model archives have unexpected sizes", call. = FALSE)
}

main_near_eye <- readRDS(input_contract$absolute_path[
  input_contract$input_role == "primary_near_eye_metrics"
])
main_chest <- readRDS(input_contract$absolute_path[
  input_contract$input_role == "primary_chest_metrics"
])
h01_main <- readRDS(input_contract$absolute_path[
  input_contract$input_role == "primary_support_provenance"
])

direct_l10 <- dplyr::bind_rows(
  main_near_eye |>
    dplyr::transmute(
      placement = "glasses",
      .data$site,
      .data$Id,
      local_date = as.Date(.data$local_date),
      value = .data$l10_mean_medi_lx
    ),
  main_chest |>
    dplyr::transmute(
      placement = "chest",
      .data$site,
      .data$Id,
      local_date = as.Date(.data$local_date),
      value = .data$l10_mean_medi_lx
    )
)

h01_l10 <- h01_main$model_rows |>
  dplyr::filter(
    .data$scenario == "all_available",
    .data$metric_id == .env$metric_id
  ) |>
  dplyr::transmute(
    .data$placement,
    .data$site,
    .data$Id,
    local_date = as.Date(.data$local_date),
    h01_value = .data$value,
    .data$metric_estimable,
    .data$metric_failure_reason,
    .data$metric_support_available,
    .data$metric_support_unavailability_reason,
    .data$metric_support_valid_minutes,
    .data$metric_support_expected_minutes
  )

current_l10 <- dplyr::bind_rows(lapply(
  c(
    "main__glasses__all_available__l10_mean_medi",
    "main__chest__all_available__l10_mean_medi"
  ),
  function(key) {
    frames_archive$model_frames[[key]] |>
      dplyr::transmute(
        .data$placement,
        site = as.character(.data$site),
        Id = as.character(.data$Id),
        local_date = as.Date(.data$local_date),
        old_value = .data$value
      )
  }
))

new_l10 <- direct_l10 |>
  dplyr::inner_join(
    h01_l10,
    by = c("placement", "site", "Id", "local_date"),
    relationship = "one-to-one"
  )
if (
  nrow(new_l10) != 1718L ||
    any(is.na(new_l10$value) != is.na(new_l10$h01_value)) ||
    any(abs(new_l10$value - new_l10$h01_value) > 1e-12, na.rm = TRUE)
) {
  stop("The direct and H01 L10 inputs do not agree", call. = FALSE)
}

cell_changes <- current_l10 |>
  dplyr::left_join(
    new_l10 |>
      dplyr::select(
        .data$placement,
        .data$site,
        .data$Id,
        .data$local_date,
        new_value = .data$value
      ),
    by = c("placement", "site", "Id", "local_date"),
    relationship = "one-to-one"
  ) |>
  dplyr::filter(.data$old_value != .data$new_value)

evidence_manifest <- read_h08_csv(input_contract$absolute_path[
  input_contract$input_role == "metric011_evidence_manifest"
])
expected_change_record <- evidence_manifest |>
  dplyr::filter(.data$artifact == "primary_scientific_cell_changes")
if (
  nrow(expected_change_record) != 1L ||
    !identical(expected_change_record$status, "PASS") ||
    !identical(expected_change_record$r_version, "4.6.1")
) {
  stop("The METRIC-011 cell-change evidence record is invalid", call. = FALSE)
}
expected_change_path <- file.path(root, expected_change_record$path)
if (
  !file.exists(expected_change_path) ||
    artifact_sha256(expected_change_path) != expected_change_record$sha256 ||
    as.numeric(file.info(expected_change_path)$size) !=
      expected_change_record$bytes
) {
  stop("The METRIC-011 cell-change evidence file fails its pin", call. = FALSE)
}
expected_changes <- read_h08_csv(expected_change_path) |>
  dplyr::rename(placement = .data$position) |>
  dplyr::mutate(local_date = as.Date(.data$local_date))
change_keys <- c("placement", "site", "Id", "local_date")
if (
  nrow(cell_changes) != 8L ||
    sum(cell_changes$placement == "glasses") != 3L ||
    sum(cell_changes$placement == "chest") != 5L ||
    !setequal(
      row_key(cell_changes, change_keys),
      row_key(expected_changes, change_keys)
    ) ||
    any(cell_changes$old_value != 4.163336342344337e-17) ||
    any(cell_changes$new_value != 0)
) {
  stop("The H08 L10 cell transition differs from METRIC-011", call. = FALSE)
}

updated_frames_archive <- frames_archive
frame_index_replacement <- list()
frame_row_replacement <- list()

for (index in seq_len(nrow(target_runs))) {
  run <- target_runs[index, , drop = FALSE]
  key <- target_frame_keys[[index]]
  frame <- updated_frames_archive$model_frames[[key]]
  lookup <- new_l10[new_l10$placement == run$placement, , drop = FALSE]
  frame_key <- paste(
    as.character(frame$site),
    as.character(frame$Id),
    as.character(frame$local_date),
    sep = "\r"
  )
  lookup_key <- paste(
    lookup$site,
    lookup$Id,
    as.character(lookup$local_date),
    sep = "\r"
  )
  match_index <- match(frame_key, lookup_key)
  if (anyNA(match_index)) {
    stop("A primary L10 frame could not be repinned", call. = FALSE)
  }
  before_key_hash <- h08_key_hash(frame)
  frame$value <- lookup$value[match_index]
  frame$h01_value <- lookup$h01_value[match_index]
  for (name in c(
    "metric_estimable",
    "metric_failure_reason",
    "metric_support_available",
    "metric_support_unavailability_reason",
    "metric_support_valid_minutes",
    "metric_support_expected_minutes"
  )) {
    frame[[name]] <- lookup[[name]][match_index]
  }
  frame$response_value <- h08_transform_response(frame$value, spec)
  if (!identical(before_key_hash, h08_key_hash(frame))) {
    stop("METRIC-011 changed a primary L10 model sample", call. = FALSE)
  }
  updated_frames_archive$model_frames[[key]] <- frame
  frame_index_replacement[[key]] <- frame_index_row(
    run,
    spec,
    frame,
    score_contract
  )
  frame_row_replacement[[key]] <- frame_export_rows(run, spec, frame)
}

updated_frame_index <- replace_rows_by_key(
  baseline$frame_index,
  dplyr::bind_rows(frame_index_replacement),
  baseline$frame_index$data_scenario_id == "main" &
    baseline$frame_index$metric_id == metric_id,
  c("run_id", "metric_id")
)
updated_frame_rows <- replace_rows_by_key(
  baseline$frame_rows,
  dplyr::bind_rows(frame_row_replacement),
  grepl("^main__", baseline$frame_rows$run_id) &
    baseline$frame_rows$metric_id == metric_id,
  c("run_id", "metric_id", ".model_row_id")
)

if (
  !identical(
    canonical_digest(
      baseline$frame_index[baseline$frame_index$metric_id != metric_id, ]
    ),
    canonical_digest(
      updated_frame_index[updated_frame_index$metric_id != metric_id, ]
    )
  )
) {
  stop("A non-L10 frame summary changed", call. = FALSE)
}

updated_bundles_archive <- bundles_archive
fit_replacement <- list()
test_replacement <- list()
effect_replacement <- list()
slope_replacement <- list()
prediction_replacement <- list()
diagnostic_replacement <- list()
diagnostic_plot_replacement <- list()
influence_replacement <- list()

for (index in seq_len(nrow(target_runs))) {
  run <- target_runs[index, , drop = FALSE]
  key <- target_frame_keys[[index]]
  frame <- updated_frames_archive$model_frames[[key]]
  message("H08 METRIC-011 L10 fit: ", run$run_id)
  bundle <- h08_fit_bundle(frame, spec, formula_kind = "participant_day")
  updated_bundles_archive$model_bundles[[key]] <- bundle
  context <- context_for(run, spec)
  fit_replacement[[key]] <- dplyr::bind_cols(
    context[rep(1L, 3L), , drop = FALSE],
    h08_model_manifest_rows(bundle)
  )
  test_replacement[[key]] <- dplyr::bind_cols(
    context[rep(1L, 2L), , drop = FALSE],
    h08_bundle_tests(bundle, inferential = run$inferential_run)
  )
  effect_replacement[[key]] <- dplyr::bind_cols(
    context,
    h08_effect_summary(
      bundle$fits$additive$model,
      spec,
      score_contract$participant_sd
    )
  )
  slopes <- h08_site_slopes(
    bundle$fits$interaction$model,
    frame,
    spec,
    score_contract$participant_sd
  ) |>
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
    )
  slope_replacement[[key]] <- dplyr::bind_cols(
    context[rep(1L, nrow(slopes)), , drop = FALSE],
    slopes
  )
  predictions <- h08_centered_predictions(
    bundle$fits$additive$model,
    frame,
    spec,
    score_contract$participant_sd
  )
  prediction_replacement[[key]] <- dplyr::bind_cols(
    context[rep(1L, nrow(predictions)), , drop = FALSE],
    predictions
  )
  diagnostic <- h08_model_diagnostics(bundle, frame)
  diagnostic_replacement[[key]] <- dplyr::bind_cols(context, diagnostic)
  if (run$sample_scenario == "all_available") {
    plot_data <- h08_diagnostic_plot_data(bundle$fits$additive$model, frame)
    diagnostic_plot_replacement[[key]] <- dplyr::bind_cols(
      context[rep(1L, nrow(plot_data)), , drop = FALSE],
      plot_data
    )
    influence <- h08_participant_influence_screen(
      bundle$fits$additive$model,
      frame,
      n = 5L
    )
    influence_replacement[[key]] <- dplyr::bind_cols(
      context[rep(1L, nrow(influence)), , drop = FALSE],
      influence
    )
  }
}

target_main_l10 <- function(data) {
  data$data_scenario_id == "main" & data$metric_id == metric_id
}

updated_fit_index <- replace_rows_by_key(
  baseline$fit_index,
  dplyr::bind_rows(fit_replacement),
  target_main_l10(baseline$fit_index),
  c("run_id", "metric_id", "model_name")
)
replacement_tests <- dplyr::bind_rows(test_replacement) |>
  dplyr::left_join(
    family_registry,
    by = c("run_id", "comparison_id"),
    relationship = "many-to-one"
  ) |>
  dplyr::mutate(
    p_adjusted = NA_real_,
    raw_significant = !is.na(.data$p_raw) & .data$p_raw <= 0.05,
    adjusted_significant = FALSE,
    raw_p_display = nh_format_p_value(.data$p_raw),
    adjusted_p_display = nh_format_p_value(.data$p_adjusted)
  )
updated_tests <- replace_rows_by_key(
  baseline$tests,
  replacement_tests,
  target_main_l10(baseline$tests),
  c("run_id", "metric_id", "comparison_id")
)
updated_effects <- replace_rows_by_key(
  baseline$effects,
  dplyr::bind_rows(effect_replacement),
  target_main_l10(baseline$effects),
  c("run_id", "metric_id")
)
updated_slopes <- replace_rows_by_key(
  baseline$site_slopes,
  dplyr::bind_rows(slope_replacement),
  target_main_l10(baseline$site_slopes),
  c("run_id", "metric_id", "site")
)
updated_predictions <- replace_rows_by_key(
  baseline$predictions,
  dplyr::bind_rows(prediction_replacement),
  target_main_l10(baseline$predictions),
  c("run_id", "metric_id", "prediction_id")
)
updated_diagnostics <- replace_rows_by_key(
  baseline$diagnostics,
  dplyr::bind_rows(diagnostic_replacement),
  target_main_l10(baseline$diagnostics),
  c("run_id", "metric_id")
)
updated_diagnostic_plot <- replace_rows_by_key(
  baseline$diagnostic_plot,
  dplyr::bind_rows(diagnostic_plot_replacement),
  grepl("^main__", baseline$diagnostic_plot$run_id) &
    baseline$diagnostic_plot$metric_id == metric_id,
  c("run_id", "metric_id", "model_row_id")
)
updated_influence <- replace_rows_by_key(
  baseline$influence,
  dplyr::bind_rows(influence_replacement),
  grepl("^main__", baseline$influence$run_id) &
    baseline$influence$metric_id == metric_id,
  c("run_id", "metric_id", "participant_key")
)

affected_families <- family_registry |>
  dplyr::filter(grepl("^main__", .data$run_id)) |>
  dplyr::pull(.data$family_id)
affected_run_ids <- family_registry |>
  dplyr::filter(.data$family_id %in% affected_families) |>
  dplyr::pull(.data$run_id) |>
  unique()
for (family_id in affected_families) {
  rows <- which(updated_tests$family_id == family_id)
  if (length(rows) != 9L) {
    stop("An affected H08 family is incomplete", call. = FALSE)
  }
  updated_tests$p_adjusted[rows] <- adjust_p_family(
    updated_tests$p_raw[rows],
    method = "BH",
    n = 9L
  )
  updated_tests$raw_significant[rows] <-
    !is.na(updated_tests$p_raw[rows]) & updated_tests$p_raw[rows] <= 0.05
  updated_tests$adjusted_significant[rows] <-
    !is.na(updated_tests$p_adjusted[rows]) &
    updated_tests$p_adjusted[rows] <= 0.05
  updated_tests$raw_p_display[rows] <- nh_format_p_value(
    updated_tests$p_raw[rows]
  )
  updated_tests$adjusted_p_display[rows] <- nh_format_p_value(
    updated_tests$p_adjusted[rows]
  )
}

non_l10_rows <- updated_tests$metric_id != metric_id
non_l10_bh_conclusion_changed <- any(
  !mapply(
    identical,
    updated_tests$adjusted_significant[non_l10_rows],
    baseline$tests$adjusted_significant[non_l10_rows]
  )
)
non_l10_bh_display_changed <- any(
  !mapply(
    identical,
    updated_tests$adjusted_p_display[non_l10_rows],
    baseline$tests$adjusted_p_display[non_l10_rows]
  )
)

bh_recalculation <- baseline$tests |>
  dplyr::filter(.data$family_id %in% affected_families) |>
  dplyr::select(
    .data$family_id,
    .data$run_id,
    .data$comparison_id,
    .data$metric_order,
    .data$metric_id,
    old_p_raw = .data$p_raw,
    old_p_adjusted = .data$p_adjusted,
    old_adjusted_p_display = .data$adjusted_p_display,
    old_adjusted_significant = .data$adjusted_significant
  ) |>
  dplyr::left_join(
    updated_tests |>
      dplyr::filter(.data$family_id %in% affected_families) |>
      dplyr::select(
        .data$family_id,
        .data$run_id,
        .data$comparison_id,
        .data$metric_id,
        new_p_raw = .data$p_raw,
        new_p_adjusted = .data$p_adjusted,
        new_adjusted_p_display = .data$adjusted_p_display,
        new_adjusted_significant = .data$adjusted_significant
      ),
    by = c("family_id", "run_id", "comparison_id", "metric_id"),
    relationship = "one-to-one"
  ) |>
  dplyr::mutate(
    raw_p_identical = mapply(
      identical,
      .data$old_p_raw,
      .data$new_p_raw
    ),
    adjusted_p_identical = mapply(
      identical,
      .data$old_p_adjusted,
      .data$new_p_adjusted
    ),
    adjusted_p_delta = .data$new_p_adjusted - .data$old_p_adjusted,
    adjusted_display_identical = .data$old_adjusted_p_display ==
      .data$new_adjusted_p_display,
    adjusted_conclusion_identical = .data$old_adjusted_significant ==
      .data$new_adjusted_significant,
    decision_id = decision_id,
    r_version = as.character(getRversion())
  ) |>
  dplyr::arrange(
    .data$family_id,
    .data$metric_order,
    .data$comparison_id
  )

recalculated_family_audit <- updated_tests |>
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
updated_family_audit <- replace_rows_by_key(
  baseline$family_audit,
  recalculated_family_audit |>
    dplyr::filter(.data$family_id %in% affected_families),
  baseline$family_audit$family_id %in% affected_families,
  "family_id"
)
if (
  any(!updated_family_audit$complete_nine_member_family) ||
    any(!updated_family_audit$independent_recalculation_matches)
) {
  stop("An H08 BH family fails exact verification", call. = FALSE)
}

protected_test_fields <- c(
  "p_adjusted",
  "adjusted_significant",
  "adjusted_p_display"
)
protected_master_fields <- c(
  "average_p_adjusted",
  "average_adjusted_significant",
  "interaction_p_adjusted",
  "interaction_adjusted_significant"
)

average_tests <- updated_tests |>
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
interaction_tests <- updated_tests |>
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

rebuilt_master <- updated_frame_index |>
  dplyr::left_join(
    updated_effects,
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
    updated_diagnostics |>
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
rebuilt_master <- align_to_baseline(rebuilt_master, baseline$master)
updated_master <- replace_rows_by_key(
  baseline$master,
  rebuilt_master |>
    dplyr::filter(
      .data$data_scenario_id == "main",
      .data$metric_id == .env$metric_id
    ),
  baseline$master$data_scenario_id == "main" &
    baseline$master$metric_id == metric_id,
  c("run_id", "metric_id")
)
non_l10_bh_master_target <-
  baseline$master$run_id %in%
  affected_run_ids &
  baseline$master$metric_id != metric_id
updated_master <- update_fields_by_key(
  updated_master,
  rebuilt_master[non_l10_bh_master_target, , drop = FALSE],
  non_l10_bh_master_target,
  c("run_id", "metric_id"),
  protected_master_fields
)

updated_sensitivity_archive <- sensitivity_archive
photo_replacement <- list()
participant_replacement <- list()

for (placement in c("glasses", "chest")) {
  run_id <- paste("main", placement, "all_available", sep = "__")
  frame_key <- paste(run_id, metric_id, sep = "__")
  frame <- updated_frames_archive$model_frames[[frame_key]]
  if (any(!is.finite(frame$photoperiod_c))) {
    stop("Primary L10 photoperiod is incomplete", call. = FALSE)
  }

  photo_key <- paste("photoperiod", placement, metric_id, sep = "__")
  photo_bundle <- h08_fit_bundle(frame, spec, formula_kind = "photoperiod")
  updated_sensitivity_archive$sensitivity_models[[photo_key]] <- photo_bundle
  photo_replacement[[photo_key]] <- dplyr::bind_cols(
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
    h08_effect_summary(
      photo_bundle$fits$additive$model,
      spec,
      score_contract$participant_sd
    ),
    h08_model_fit_status(photo_bundle$fits$additive$model),
    h08_model_condition(photo_bundle$fits$additive$model)
  )

  participant_frame <- h08_prepare_participant_summary(
    frame,
    spec,
    site_levels
  )
  participant_key <- paste("participant", placement, metric_id, sep = "__")
  participant_bundle <- h08_fit_bundle(
    participant_frame,
    spec,
    formula_kind = "participant"
  )
  updated_sensitivity_archive$sensitivity_models[[participant_key]] <-
    participant_bundle
  participant_replacement[[participant_key]] <- dplyr::bind_cols(
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
    h08_effect_summary(
      participant_bundle$fits$additive$model,
      spec,
      score_contract$participant_sd
    ),
    h08_model_fit_status(participant_bundle$fits$additive$model),
    h08_model_condition(participant_bundle$fits$additive$model)
  )
}

updated_photoperiod <- replace_rows_by_key(
  baseline$photoperiod,
  dplyr::bind_rows(photo_replacement),
  baseline$photoperiod$metric_id == metric_id,
  c("placement", "metric_id")
)
updated_participant <- replace_rows_by_key(
  baseline$participant,
  dplyr::bind_rows(participant_replacement),
  baseline$participant$metric_id == metric_id,
  c("placement", "metric_id")
)

loo_replacement <- list()
for (placement in c("glasses", "chest")) {
  run_id <- paste("main", placement, "all_available", sep = "__")
  frame_key <- paste(run_id, metric_id, sep = "__")
  frame <- updated_frames_archive$model_frames[[frame_key]]
  full_effect <- updated_effects |>
    dplyr::filter(
      .data$run_id == .env$run_id,
      .data$metric_id == .env$metric_id
    )
  loo <- h08_leave_one_site_out(
    frame,
    spec,
    score_contract$participant_sd,
    full_effect$estimate_model_per_point
  ) |>
    dplyr::left_join(
      site_registry |>
        dplyr::select(
          omitted_site = .data$site,
          omitted_site_display_order = .data$display_order,
          omitted_site_name = .data$display_name
        ),
      by = "omitted_site",
      relationship = "many-to-one"
    )
  loo_replacement[[placement]] <- dplyr::bind_cols(
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
updated_loo <- replace_rows_by_key(
  baseline$loo,
  dplyr::bind_rows(loo_replacement),
  baseline$loo$metric_id == metric_id,
  c("placement", "metric_id", "omitted_site")
)

updated_loo_summary <- updated_loo |>
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
updated_loo_summary <- replace_rows_by_key(
  baseline$loo_summary,
  updated_loo_summary |>
    dplyr::filter(.data$metric_id == .env$metric_id),
  baseline$loo_summary$metric_id == metric_id,
  c("placement", "metric_id")
)

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
    any(
      !is.finite(c(
        estimate_a,
        low_a,
        high_a,
        estimate_b,
        low_b,
        high_b
      ))
    )
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
  if (excludes_zero_a != excludes_zero_b) return("precision-sensitive")
  mutually_contained <-
    estimate_a >= low_b &&
    estimate_a <= high_b &&
    estimate_b >= low_a &&
    estimate_b <= high_a
  if (!mutually_contained) return("magnitude-sensitive")
  "stable within model uncertainty"
}

updated_gap <- updated_master |>
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
rebuilt_gap <- align_to_baseline(updated_gap, baseline$gap)
gap_primary_fields <- c(
  "estimate_main",
  "conf_low_main",
  "conf_high_main",
  "p_adjusted_main",
  "adjusted_significant_main",
  "participants_main",
  "participant_days_main",
  "sites_main",
  "row_key_hash_main",
  "exact_common_keys",
  "stability_classification"
)
updated_gap <- update_fields_by_key(
  baseline$gap,
  rebuilt_gap |>
    dplyr::filter(.data$metric_id == .env$metric_id),
  baseline$gap$metric_id == metric_id,
  c("placement", "sample_scenario", "metric_id"),
  gap_primary_fields
)
gap_bh_fields <- c("p_adjusted_main", "adjusted_significant_main")
gap_bh_target <-
  baseline$gap$sample_scenario == "all_available" &
  baseline$gap$metric_id != metric_id
updated_gap <- update_fields_by_key(
  updated_gap,
  rebuilt_gap[gap_bh_target, , drop = FALSE],
  gap_bh_target,
  c("placement", "sample_scenario", "metric_id"),
  gap_bh_fields
)

updated_response_gate <- updated_diagnostics |>
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
updated_response_gate <- replace_rows_by_key(
  baseline$response_gate,
  updated_response_gate |>
    dplyr::filter(.data$metric_id == .env$metric_id),
  baseline$response_gate$metric_id == metric_id,
  "metric_id"
)

v0_results <- read_h08_csv(file.path(
  roots$tables,
  "H08_v0_reproduction.csv"
))
new_main <- updated_master |>
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
updated_v0_comparison <- v0_results |>
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
  ) |>
  dplyr::arrange(.data$placement, .data$metric_order)
rebuilt_v0_comparison <- align_to_baseline(
  updated_v0_comparison,
  baseline$v0_comparison
)
v0_new_fields <- c(
  "new_participants",
  "new_participant_days",
  "new_sites",
  "new_average_p_raw",
  "new_average_p_adjusted",
  "new_average_adjusted_significant",
  "new_interaction_p_raw",
  "new_interaction_p_adjusted",
  "new_estimate_practical_per_sd",
  "new_conf_low_practical_per_sd",
  "new_conf_high_practical_per_sd",
  "new_effect_type",
  "participant_change",
  "participant_day_change",
  "new_conclusion_differs_from_v0_scalar"
)
updated_v0_comparison <- update_fields_by_key(
  baseline$v0_comparison,
  rebuilt_v0_comparison |>
    dplyr::filter(.data$metric_id == .env$metric_id),
  baseline$v0_comparison$metric_id == metric_id,
  c("placement", "metric_id"),
  v0_new_fields
)
v0_bh_fields <- c(
  "new_average_p_adjusted",
  "new_average_adjusted_significant",
  "new_interaction_p_adjusted",
  "new_conclusion_differs_from_v0_scalar"
)
v0_bh_target <- baseline$v0_comparison$metric_id != metric_id
updated_v0_comparison <- update_fields_by_key(
  updated_v0_comparison,
  rebuilt_v0_comparison[v0_bh_target, , drop = FALSE],
  v0_bh_target,
  c("placement", "metric_id"),
  v0_bh_fields
)

effect_plot_data <- updated_master |>
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
updated_near_effects <- replace_rows_by_key(
  baseline$near_effects,
  align_to_baseline(
    effect_plot_data |>
      dplyr::filter(
        .data$placement == "glasses",
        .data$metric_id == .env$metric_id
      ),
    baseline$near_effects
  ),
  baseline$near_effects$metric_id == metric_id,
  "metric_id"
)
near_bh_target <- baseline$near_effects$metric_id != metric_id
updated_near_effects <- update_fields_by_key(
  updated_near_effects,
  align_to_baseline(
    effect_plot_data |>
      dplyr::filter(
        .data$placement == "glasses",
        .data$metric_id != .env$metric_id
      ),
    baseline$near_effects
  ),
  near_bh_target,
  "metric_id",
  protected_master_fields
)
updated_chest_effects <- replace_rows_by_key(
  baseline$chest_effects,
  align_to_baseline(
    effect_plot_data |>
      dplyr::filter(
        .data$placement == "chest",
        .data$metric_id == .env$metric_id
      ),
    baseline$chest_effects
  ),
  baseline$chest_effects$metric_id == metric_id,
  "metric_id"
)
chest_bh_target <- baseline$chest_effects$metric_id != metric_id
updated_chest_effects <- update_fields_by_key(
  updated_chest_effects,
  align_to_baseline(
    effect_plot_data |>
      dplyr::filter(
        .data$placement == "chest",
        .data$metric_id != .env$metric_id
      ),
    baseline$chest_effects
  ),
  chest_bh_target,
  "metric_id",
  protected_master_fields
)

updated_paired_effects <- updated_master |>
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
updated_paired_effects <- replace_rows_by_key(
  baseline$paired_effects,
  align_to_baseline(
    updated_paired_effects |>
      dplyr::filter(.data$metric_id == .env$metric_id),
    baseline$paired_effects
  ),
  baseline$paired_effects$metric_id == metric_id,
  "metric_id"
)

updated_gap_effects <- updated_gap |>
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
rebuilt_gap_effects <- align_to_baseline(
  updated_gap_effects,
  baseline$gap_effects
)
gap_effect_fields <- c(gap_primary_fields, "primary_log_ratio")
updated_gap_effects <- update_fields_by_key(
  baseline$gap_effects,
  rebuilt_gap_effects |>
    dplyr::filter(.data$metric_id == .env$metric_id),
  baseline$gap_effects$metric_id == metric_id,
  c("placement", "sample_scenario", "metric_id"),
  gap_effect_fields
)

updated_near_adequacy <- updated_diagnostic_plot |>
  dplyr::filter(.data$run_id == "main__glasses__all_available") |>
  dplyr::mutate(
    manuscript_name = factor(
      .data$manuscript_name,
      levels = metric_registry$manuscript_name
    )
  )
updated_near_adequacy <- replace_rows_by_key(
  baseline$near_adequacy,
  align_to_baseline(
    updated_near_adequacy |>
      dplyr::filter(.data$metric_id == .env$metric_id),
    baseline$near_adequacy
  ),
  baseline$near_adequacy$metric_id == metric_id,
  c("run_id", "metric_id", "model_row_id")
)

old_non_l10_tests <- baseline$tests[baseline$tests$metric_id != metric_id, ]
new_non_l10_tests <- updated_tests[updated_tests$metric_id != metric_id, ]
if (
  !identical(
    canonical_digest(old_non_l10_tests, drop = protected_test_fields),
    canonical_digest(new_non_l10_tests, drop = protected_test_fields)
  )
) {
  stop("A non-L10 fit or raw test changed", call. = FALSE)
}
old_non_l10_master <- baseline$master[baseline$master$metric_id != metric_id, ]
new_non_l10_master <- updated_master[updated_master$metric_id != metric_id, ]
if (
  !identical(
    canonical_digest(old_non_l10_master, drop = protected_master_fields),
    canonical_digest(new_non_l10_master, drop = protected_master_fields)
  )
) {
  stop("A non-L10 scientific result changed", call. = FALSE)
}

protected_table_updates <- list(
  fit_index = updated_fit_index,
  effects = updated_effects,
  site_slopes = updated_slopes,
  predictions = updated_predictions,
  diagnostics = updated_diagnostics,
  diagnostic_plot = updated_diagnostic_plot,
  influence = updated_influence,
  photoperiod = updated_photoperiod,
  participant = updated_participant,
  loo = updated_loo
)
for (id in names(protected_table_updates)) {
  updated <- protected_table_updates[[id]]
  old_scope <- baseline[[id]][baseline[[id]]$metric_id != metric_id, ]
  new_scope <- updated[updated$metric_id != metric_id, ]
  if (!identical(canonical_digest(old_scope), canonical_digest(new_scope))) {
    stop("A protected non-L10 artifact slice changed: ", id, call. = FALSE)
  }
}

old_gap_l10 <- baseline$master[
  baseline$master$data_scenario_id == "gap_timing_unaware" &
    baseline$master$metric_id == metric_id,
]
new_gap_l10 <- updated_master[
  updated_master$data_scenario_id == "gap_timing_unaware" &
    updated_master$metric_id == metric_id,
]
if (!identical(canonical_digest(old_gap_l10), canonical_digest(new_gap_l10))) {
  stop("A gap-timing-unaware L10 result changed", call. = FALSE)
}

protected_bundle_names <- setdiff(
  names(bundles_archive$model_bundles),
  target_frame_keys
)
if (
  !identical(
    digest::digest(
      bundles_archive$model_bundles[protected_bundle_names],
      algo = "sha256",
      serialize = TRUE
    ),
    digest::digest(
      updated_bundles_archive$model_bundles[protected_bundle_names],
      algo = "sha256",
      serialize = TRUE
    )
  )
) {
  stop("A protected model bundle changed", call. = FALSE)
}

protected_frame_names <- setdiff(
  names(frames_archive$model_frames),
  target_frame_keys
)
if (
  !identical(
    digest::digest(
      frames_archive$model_frames[protected_frame_names],
      algo = "sha256",
      serialize = TRUE
    ),
    digest::digest(
      updated_frames_archive$model_frames[protected_frame_names],
      algo = "sha256",
      serialize = TRUE
    )
  )
) {
  stop("A protected model frame changed", call. = FALSE)
}

target_sensitivity_names <- c(
  "photoperiod__glasses__l10_mean_medi",
  "participant__glasses__l10_mean_medi",
  "photoperiod__chest__l10_mean_medi",
  "participant__chest__l10_mean_medi"
)
protected_sensitivity_names <- setdiff(
  names(sensitivity_archive$sensitivity_models),
  target_sensitivity_names
)
if (
  !identical(
    digest::digest(
      sensitivity_archive$sensitivity_models[protected_sensitivity_names],
      algo = "sha256",
      serialize = TRUE
    ),
    digest::digest(
      updated_sensitivity_archive$sensitivity_models[
        protected_sensitivity_names
      ],
      algo = "sha256",
      serialize = TRUE
    )
  )
) {
  stop("A protected sensitivity model changed", call. = FALSE)
}

protected_paths <- c(
  v0_results = file.path(roots$tables, "H08_v0_reproduction.csv"),
  v0_rows = file.path(roots$model_data, "H08_v0_model_rows.csv"),
  v0_models = file.path(roots$models, "H08_v0_models.rds"),
  exact_longest = file.path(
    roots$tables,
    "H08_exactly_identified_longest_period_sensitivity.csv"
  ),
  observed_dose = file.path(
    roots$tables,
    "H08_observed_dose_sensitivity.csv"
  )
)
protected_sha_before <- unname(vapply(
  protected_paths,
  artifact_sha256,
  character(1)
))
names(protected_sha_before) <- names(protected_paths)

old_primary <- baseline$master |>
  dplyr::filter(
    .data$sample_scenario == "all_available",
    .data$data_scenario_id == "main",
    .data$metric_id == .env$metric_id
  ) |>
  dplyr::arrange(.data$placement)
new_primary <- updated_master |>
  dplyr::filter(
    .data$sample_scenario == "all_available",
    .data$data_scenario_id == "main",
    .data$metric_id == .env$metric_id
  ) |>
  dplyr::arrange(.data$placement)

result_comparison <- old_primary |>
  dplyr::select(
    .data$placement,
    .data$placement_label,
    old_estimate = .data$estimate_practical_per_sd,
    old_conf_low = .data$conf_low_practical_per_sd,
    old_conf_high = .data$conf_high_practical_per_sd,
    old_average_p_raw = .data$average_p_raw,
    old_average_p_adjusted = .data$average_p_adjusted,
    old_interaction_p_raw = .data$interaction_p_raw,
    old_interaction_p_adjusted = .data$interaction_p_adjusted,
    old_average_retained = .data$average_adjusted_significant,
    old_interaction_retained = .data$interaction_adjusted_significant,
    old_diagnostic_status = .data$diagnostic_status,
    old_diagnostic_issues = .data$diagnostic_issues
  ) |>
  dplyr::left_join(
    new_primary |>
      dplyr::select(
        .data$placement,
        new_estimate = .data$estimate_practical_per_sd,
        new_conf_low = .data$conf_low_practical_per_sd,
        new_conf_high = .data$conf_high_practical_per_sd,
        new_average_p_raw = .data$average_p_raw,
        new_average_p_adjusted = .data$average_p_adjusted,
        new_interaction_p_raw = .data$interaction_p_raw,
        new_interaction_p_adjusted = .data$interaction_p_adjusted,
        new_average_retained = .data$average_adjusted_significant,
        new_interaction_retained = .data$interaction_adjusted_significant,
        new_diagnostic_status = .data$diagnostic_status,
        new_diagnostic_issues = .data$diagnostic_issues
      ),
    by = "placement",
    relationship = "one-to-one"
  ) |>
  dplyr::mutate(
    estimate_delta = .data$new_estimate - .data$old_estimate,
    conf_low_delta = .data$new_conf_low - .data$old_conf_low,
    conf_high_delta = .data$new_conf_high - .data$old_conf_high,
    average_p_raw_delta = .data$new_average_p_raw - .data$old_average_p_raw,
    average_p_adjusted_delta = .data$new_average_p_adjusted -
      .data$old_average_p_adjusted,
    interaction_p_raw_delta = .data$new_interaction_p_raw -
      .data$old_interaction_p_raw,
    interaction_p_adjusted_delta = .data$new_interaction_p_adjusted -
      .data$old_interaction_p_adjusted,
    old_effect_display = sprintf(
      "%.3f (%.3f to %.3f)",
      .data$old_estimate,
      .data$old_conf_low,
      .data$old_conf_high
    ),
    new_effect_display = sprintf(
      "%.3f (%.3f to %.3f)",
      .data$new_estimate,
      .data$new_conf_low,
      .data$new_conf_high
    ),
    old_average_raw_display = nh_format_p_value(.data$old_average_p_raw),
    new_average_raw_display = nh_format_p_value(.data$new_average_p_raw),
    old_average_bh_display = nh_format_p_value(
      .data$old_average_p_adjusted
    ),
    new_average_bh_display = nh_format_p_value(
      .data$new_average_p_adjusted
    ),
    old_interaction_raw_display = nh_format_p_value(
      .data$old_interaction_p_raw
    ),
    new_interaction_raw_display = nh_format_p_value(
      .data$new_interaction_p_raw
    ),
    old_interaction_bh_display = nh_format_p_value(
      .data$old_interaction_p_adjusted
    ),
    new_interaction_bh_display = nh_format_p_value(
      .data$new_interaction_p_adjusted
    ),
    reader_display_changed = .data$old_effect_display !=
      .data$new_effect_display |
      .data$old_average_raw_display != .data$new_average_raw_display |
      .data$old_average_bh_display != .data$new_average_bh_display |
      .data$old_interaction_raw_display != .data$new_interaction_raw_display |
      .data$old_interaction_bh_display != .data$new_interaction_bh_display,
    retained_conclusion_changed = .data$old_average_retained !=
      .data$new_average_retained |
      .data$old_interaction_retained != .data$new_interaction_retained,
    diagnostic_disposition_changed = .data$old_diagnostic_status !=
      .data$new_diagnostic_status |
      dplyr::coalesce(.data$old_diagnostic_issues, "") !=
        dplyr::coalesce(.data$new_diagnostic_issues, ""),
    author_review_required = .data$reader_display_changed |
      .data$retained_conclusion_changed |
      .data$diagnostic_disposition_changed,
    decision_id = decision_id,
    r_version = as.character(getRversion())
  )

old_l10_gap_class <- baseline$gap |>
  dplyr::filter(.data$metric_id == .env$metric_id) |>
  dplyr::arrange(.data$sample_scenario, .data$placement) |>
  dplyr::pull(.data$stability_classification)
new_l10_gap_class <- updated_gap |>
  dplyr::filter(.data$metric_id == .env$metric_id) |>
  dplyr::arrange(.data$sample_scenario, .data$placement) |>
  dplyr::pull(.data$stability_classification)
if (!identical(old_l10_gap_class, new_l10_gap_class)) {
  result_comparison$author_review_required <- TRUE
}

old_l10_loo <- baseline$loo_summary |>
  dplyr::filter(.data$metric_id == .env$metric_id) |>
  dplyr::arrange(.data$placement) |>
  dplyr::pull(.data$influence_status)
new_l10_loo <- updated_loo_summary |>
  dplyr::filter(.data$metric_id == .env$metric_id) |>
  dplyr::arrange(.data$placement) |>
  dplyr::pull(.data$influence_status)
if (!identical(old_l10_loo, new_l10_loo)) {
  result_comparison$author_review_required <- TRUE
}
if (non_l10_bh_conclusion_changed || non_l10_bh_display_changed) {
  result_comparison$author_review_required <- TRUE
}

reader_display_digest <- function(data, numeric_fields, character_fields) {
  selected <- data[, c(numeric_fields, character_fields), drop = FALSE]
  for (name in numeric_fields) {
    selected[[name]] <- ifelse(
      is.finite(selected[[name]]),
      sprintf("%.3f", selected[[name]]),
      NA_character_
    )
  }
  canonical_digest(selected)
}

reader_display_checks <- dplyr::bind_rows(
  tibble::tibble(
    output = "all primary-dataset L10 participant-day effects",
    before = reader_display_digest(
      baseline$master[
        baseline$master$data_scenario_id == "main" &
          baseline$master$metric_id == metric_id,
      ],
      c(
        "estimate_practical_per_sd",
        "conf_low_practical_per_sd",
        "conf_high_practical_per_sd",
        "average_p_raw",
        "average_p_adjusted",
        "interaction_p_raw",
        "interaction_p_adjusted"
      ),
      c(
        "run_id",
        "diagnostic_status",
        "diagnostic_issues",
        "average_adjusted_significant",
        "interaction_adjusted_significant"
      )
    ),
    after = reader_display_digest(
      updated_master[
        updated_master$data_scenario_id == "main" &
          updated_master$metric_id == metric_id,
      ],
      c(
        "estimate_practical_per_sd",
        "conf_low_practical_per_sd",
        "conf_high_practical_per_sd",
        "average_p_raw",
        "average_p_adjusted",
        "interaction_p_raw",
        "interaction_p_adjusted"
      ),
      c(
        "run_id",
        "diagnostic_status",
        "diagnostic_issues",
        "average_adjusted_significant",
        "interaction_adjusted_significant"
      )
    )
  ),
  tibble::tibble(
    output = "primary L10 site-specific slopes",
    before = reader_display_digest(
      baseline$site_slopes[
        baseline$site_slopes$data_scenario_id == "main" &
          baseline$site_slopes$metric_id == metric_id,
      ],
      c(
        "estimate_practical_per_sd",
        "conf_low_practical_per_sd",
        "conf_high_practical_per_sd"
      ),
      c("run_id", "site", "slope_status")
    ),
    after = reader_display_digest(
      updated_slopes[
        updated_slopes$data_scenario_id == "main" &
          updated_slopes$metric_id == metric_id,
      ],
      c(
        "estimate_practical_per_sd",
        "conf_low_practical_per_sd",
        "conf_high_practical_per_sd"
      ),
      c("run_id", "site", "slope_status")
    )
  ),
  tibble::tibble(
    output = "primary L10 centred predictions",
    before = reader_display_digest(
      baseline$predictions[
        baseline$predictions$data_scenario_id == "main" &
          baseline$predictions$metric_id == metric_id,
      ],
      c("estimate", "conf_low", "conf_high"),
      c("run_id", "prediction_id")
    ),
    after = reader_display_digest(
      updated_predictions[
        updated_predictions$data_scenario_id == "main" &
          updated_predictions$metric_id == metric_id,
      ],
      c("estimate", "conf_low", "conf_high"),
      c("run_id", "prediction_id")
    )
  ),
  tibble::tibble(
    output = "L10 photoperiod sensitivity",
    before = reader_display_digest(
      baseline$photoperiod[baseline$photoperiod$metric_id == metric_id, ],
      c(
        "estimate_practical_per_sd",
        "conf_low_practical_per_sd",
        "conf_high_practical_per_sd"
      ),
      c("placement", "converged", "convergence_message")
    ),
    after = reader_display_digest(
      updated_photoperiod[updated_photoperiod$metric_id == metric_id, ],
      c(
        "estimate_practical_per_sd",
        "conf_low_practical_per_sd",
        "conf_high_practical_per_sd"
      ),
      c("placement", "converged", "convergence_message")
    )
  ),
  tibble::tibble(
    output = "L10 participant-summary sensitivity",
    before = reader_display_digest(
      baseline$participant[baseline$participant$metric_id == metric_id, ],
      c(
        "estimate_practical_per_sd",
        "conf_low_practical_per_sd",
        "conf_high_practical_per_sd"
      ),
      c("placement", "converged", "convergence_message")
    ),
    after = reader_display_digest(
      updated_participant[updated_participant$metric_id == metric_id, ],
      c(
        "estimate_practical_per_sd",
        "conf_low_practical_per_sd",
        "conf_high_practical_per_sd"
      ),
      c("placement", "converged", "convergence_message")
    )
  ),
  tibble::tibble(
    output = "non-L10 BH derivatives in the four affected families",
    before = canonical_digest(
      baseline$tests |>
        dplyr::filter(
          .data$family_id %in% affected_families,
          .data$metric_id != .env$metric_id
        ) |>
        dplyr::select(
          .data$run_id,
          .data$metric_id,
          .data$comparison_id,
          .data$adjusted_p_display,
          .data$adjusted_significant
        )
    ),
    after = canonical_digest(
      updated_tests |>
        dplyr::filter(
          .data$family_id %in% affected_families,
          .data$metric_id != .env$metric_id
        ) |>
        dplyr::select(
          .data$run_id,
          .data$metric_id,
          .data$comparison_id,
          .data$adjusted_p_display,
          .data$adjusted_significant
        )
    )
  )
) |>
  dplyr::mutate(
    display_identical = .data$before == .data$after,
    decision_id = decision_id,
    r_version = as.character(getRversion())
  )
if (any(!reader_display_checks$display_identical)) {
  result_comparison$author_review_required <- TRUE
}

if (any(result_comparison$author_review_required)) {
  stop(
    "A retained H08 result, reader display, diagnostic disposition, or claim changed; author review is required before installation",
    call. = FALSE
  )
}

output_objects <- list(
  input_audit = input_audit,
  frame_index = updated_frame_index,
  frame_rows = updated_frame_rows,
  frames_archive = updated_frames_archive,
  fit_index = updated_fit_index,
  bundles_archive = updated_bundles_archive,
  sensitivity_archive = updated_sensitivity_archive,
  tests = updated_tests,
  effects = updated_effects,
  site_slopes = updated_slopes,
  predictions = updated_predictions,
  family_audit = updated_family_audit,
  master = updated_master,
  photoperiod = updated_photoperiod,
  participant = updated_participant,
  gap = updated_gap,
  v0_comparison = updated_v0_comparison,
  diagnostics = updated_diagnostics,
  influence = updated_influence,
  loo = updated_loo,
  loo_summary = updated_loo_summary,
  response_gate = updated_response_gate,
  diagnostic_plot = updated_diagnostic_plot,
  near_effects = updated_near_effects,
  chest_effects = updated_chest_effects,
  paired_effects = updated_paired_effects,
  gap_effects = updated_gap_effects,
  near_adequacy = updated_near_adequacy
)

main_l10_rows <- function(data) {
  if ("data_scenario_id" %in% names(data)) {
    data$data_scenario_id == "main" & data$metric_id == metric_id
  } else {
    grepl("^main__", data$run_id) & data$metric_id == metric_id
  }
}
metric_l10_rows <- function(data) data$metric_id == metric_id
scoped_csv_specs <- list(
  frame_index = list(target = main_l10_rows(updated_frame_index)),
  frame_rows = list(target = main_l10_rows(updated_frame_rows)),
  fit_index = list(target = main_l10_rows(updated_fit_index)),
  tests = list(
    target = main_l10_rows(updated_tests),
    additional_scopes = list(list(
      target = updated_tests$family_id %in%
        affected_families &
        updated_tests$metric_id != metric_id,
      fields = protected_test_fields
    ))
  ),
  effects = list(target = main_l10_rows(updated_effects)),
  site_slopes = list(target = main_l10_rows(updated_slopes)),
  predictions = list(target = main_l10_rows(updated_predictions)),
  family_audit = list(
    target = updated_family_audit$family_id %in% affected_families
  ),
  master = list(
    target = main_l10_rows(updated_master),
    additional_scopes = list(list(
      target = non_l10_bh_master_target,
      fields = protected_master_fields
    ))
  ),
  photoperiod = list(target = metric_l10_rows(updated_photoperiod)),
  participant = list(target = metric_l10_rows(updated_participant)),
  gap = list(
    target = metric_l10_rows(updated_gap),
    fields = gap_primary_fields,
    additional_scopes = list(list(
      target = gap_bh_target,
      fields = gap_bh_fields
    ))
  ),
  v0_comparison = list(
    target = metric_l10_rows(updated_v0_comparison),
    fields = v0_new_fields,
    additional_scopes = list(list(
      target = v0_bh_target,
      fields = v0_bh_fields
    ))
  ),
  diagnostics = list(target = main_l10_rows(updated_diagnostics)),
  influence = list(target = main_l10_rows(updated_influence)),
  loo = list(target = metric_l10_rows(updated_loo)),
  loo_summary = list(target = metric_l10_rows(updated_loo_summary)),
  response_gate = list(target = metric_l10_rows(updated_response_gate)),
  diagnostic_plot = list(target = main_l10_rows(updated_diagnostic_plot)),
  near_effects = list(
    target = metric_l10_rows(updated_near_effects),
    additional_scopes = list(list(
      target = near_bh_target,
      fields = protected_master_fields
    ))
  ),
  chest_effects = list(
    target = metric_l10_rows(updated_chest_effects),
    additional_scopes = list(list(
      target = chest_bh_target,
      fields = protected_master_fields
    ))
  ),
  paired_effects = list(target = metric_l10_rows(updated_paired_effects)),
  gap_effects = list(
    target = metric_l10_rows(updated_gap_effects),
    fields = gap_effect_fields
  ),
  near_adequacy = list(target = metric_l10_rows(updated_near_adequacy))
)

for (id in names(output_objects)) {
  message("H08 METRIC-011 install: ", id)
  if (tolower(tools::file_ext(paths[[id]])) == "rds") {
    write_rds_artifact(output_objects[[id]], paths[[id]], producer = producer)
  } else if (id %in% names(scoped_csv_specs)) {
    spec <- scoped_csv_specs[[id]]
    write_scoped_csv_artifact(
      output_objects[[id]],
      paths[[id]],
      producer = producer,
      baseline_data = baseline[[id]],
      baseline_lines = baseline_lines[[id]],
      target = spec$target,
      fields = if (is.null(spec$fields)) {
        names(output_objects[[id]])
      } else {
        spec$fields
      },
      additional_scopes = if (is.null(spec$additional_scopes)) {
        list()
      } else {
        spec$additional_scopes
      }
    )
  } else {
    write_csv_artifact(output_objects[[id]], paths[[id]], producer = producer)
  }
}

result_comparison_path <- file.path(
  roots$tables,
  "H08_metric011_result_comparison.csv"
)
write_csv_artifact(
  result_comparison,
  result_comparison_path,
  producer = producer
)
display_invariance_path <- file.path(
  roots$tables,
  "H08_metric011_display_invariance.csv"
)
write_csv_artifact(
  reader_display_checks,
  display_invariance_path,
  producer = producer
)
bh_recalculation_path <- file.path(
  roots$tables,
  "H08_metric011_bh_recalculation.csv"
)
write_csv_artifact(
  bh_recalculation,
  bh_recalculation_path,
  producer = producer
)

protected_sha_after <- unname(vapply(
  protected_paths,
  artifact_sha256,
  character(1)
))
names(protected_sha_after) <- names(protected_paths)
if (!identical(protected_sha_before, protected_sha_after)) {
  stop("A protected V0 or non-L10 sensitivity artifact changed", call. = FALSE)
}

reconciliation_rows <- dplyr::bind_rows(lapply(
  names(output_objects),
  function(id) {
    updated_data <- output_objects[[id]]
    is_archive <- tolower(tools::file_ext(paths[[id]])) == "rds"
    invariant_verified <- TRUE
    if (id == "input_audit") {
      old_digest <- canonical_digest(input_audit)
      new_digest <- canonical_digest(input_audit)
      scope <- paste0(
        "provenance-only repin to 20 verified inputs; accepted scientific ",
        "content is checked in downstream artifact rows"
      )
    } else if (id == "family_audit") {
      old_scope <- baseline$family_audit[
        !baseline$family_audit$family_id %in% affected_families,
      ]
      new_scope <- updated_family_audit[
        !updated_family_audit$family_id %in% affected_families,
      ]
      old_digest <- canonical_digest(old_scope)
      new_digest <- canonical_digest(new_scope)
      scope <- "all four unaffected gap-timing-unaware BH-family audits"
    } else if (is_archive) {
      if (id == "frames_archive") {
        old_digest <- digest::digest(
          frames_archive$model_frames[protected_frame_names],
          algo = "sha256",
          serialize = TRUE
        )
        new_digest <- digest::digest(
          updated_frames_archive$model_frames[protected_frame_names],
          algo = "sha256",
          serialize = TRUE
        )
        scope <- "all 102 non-target model-frame objects"
      } else if (id == "bundles_archive") {
        old_digest <- digest::digest(
          bundles_archive$model_bundles[protected_bundle_names],
          algo = "sha256",
          serialize = TRUE
        )
        new_digest <- digest::digest(
          updated_bundles_archive$model_bundles[protected_bundle_names],
          algo = "sha256",
          serialize = TRUE
        )
        scope <- "all 102 non-target participant-day model bundles"
      } else {
        old_digest <- digest::digest(
          sensitivity_archive$sensitivity_models[protected_sensitivity_names],
          algo = "sha256",
          serialize = TRUE
        )
        new_digest <- digest::digest(
          updated_sensitivity_archive$sensitivity_models[
            protected_sensitivity_names
          ],
          algo = "sha256",
          serialize = TRUE
        )
        scope <- "all 40 non-target sensitivity model bundles"
      }
    } else {
      old_data <- baseline[[id]]
      if (id %in% names(scoped_csv_specs)) {
        write_spec <- scoped_csv_specs[[id]]
        target <- write_spec$target
        fields <- if (is.null(write_spec$fields)) {
          names(old_data)
        } else {
          write_spec$fields
        }
        additional_scopes <- if (is.null(write_spec$additional_scopes)) {
          list()
        } else {
          write_spec$additional_scopes
        }
        allowed <- scoped_allowed_matrix(
          old_data,
          target,
          fields,
          additional_scopes
        )
        protected_slice <- function(data) {
          output <- lapply(
            seq_along(data),
            function(index) data[[index]][!allowed[, index]]
          )
          names(output) <- names(data)
          output
        }
        old_digest <- digest::digest(
          protected_slice(old_data),
          algo = "sha256",
          serialize = TRUE
        )
        new_digest <- digest::digest(
          protected_slice(updated_data),
          algo = "sha256",
          serialize = TRUE
        )
        scope <- paste0(
          "every cell outside ",
          format(sum(allowed), big.mark = ",", scientific = FALSE),
          " explicitly permitted target cells"
        )
      } else {
        old_digest <- canonical_digest(old_data)
        new_digest <- canonical_digest(updated_data)
        scope <- "complete artifact where no metric-specific selector exists"
      }
    }
    tibble::tibble(
      artifact_id = id,
      path = relative_path(paths[[id]]),
      file_sha256_before = baseline_sha[[id]],
      file_sha256_after = artifact_sha256(paths[[id]]),
      invariant_scope = scope,
      baseline_invariant_digest = old_digest,
      updated_invariant_digest = new_digest,
      invariant_verified = invariant_verified &&
        identical(old_digest, new_digest),
      decision_id = decision_id,
      producer = producer,
      r_version = as.character(getRversion())
    )
  }
))

protected_rows <- tibble::tibble(
  artifact_id = names(protected_paths),
  path = vapply(protected_paths, relative_path, character(1)),
  file_sha256_before = protected_sha_before,
  file_sha256_after = protected_sha_after,
  invariant_scope = "complete protected artifact",
  baseline_invariant_digest = protected_sha_before,
  updated_invariant_digest = protected_sha_after,
  invariant_verified = protected_sha_before == protected_sha_after,
  decision_id = decision_id,
  producer = producer,
  r_version = as.character(getRversion())
)
reconciliation <- dplyr::bind_rows(reconciliation_rows, protected_rows)
if (any(!reconciliation$invariant_verified)) {
  stop("An H08 METRIC-011 invariance record failed", call. = FALSE)
}

reconciliation_path <- file.path(
  roots$manifests,
  "H08_metric011_reconciliation.csv"
)
write_csv_artifact(reconciliation, reconciliation_path, producer = producer)

message(
  "H08 METRIC-011 reseal installed: eight L10 cells, six participant-day ",
  "bundles, four sensitivity bundles, 17 leave-one-site-out refits, and ",
  "four complete-family BH recalculations; no reader-facing result changed"
)
