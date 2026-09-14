#!/usr/bin/env Rscript

# Reseal only the H05 primary L10-mean branches affected by METRIC-011.
# The gap-timing-unaware L10 frames/fits, all MDER outputs, and every fit for
# the other 16 metrics are immutable. Complete-family BH fields are refreshed
# only as mathematical derivatives of the eight new primary L10 raw tests.

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
source(file.path(root, "scripts/hypotheses/H01/h01_contract.R"))
source(file.path(root, "scripts/hypotheses/H01/h01_modeling.R"))
source(file.path(root, "scripts/hypotheses/H05/h05_contract.R"))
source(file.path(root, "scripts/hypotheses/H05/h05_modeling.R"))

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("The H05 METRIC-011 reseal requires R 4.6.1", call. = FALSE)
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
  "glmmTMB",
  "performance",
  "DHARMa"
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

producer <- "scripts/hypotheses/H05/reseal_h05_l10_metric011.R"
metric_id <- "l10_mean_medi"
primary_id <- "main"
gap_id <- "manuscript_prepared_data"
target_family_ids <- c("H05-F1-primary", "H05-F2-complementary-chest")

roots <- list(
  model_data = file.path(root, "artifacts/06_model_data/H05"),
  models = file.path(root, "artifacts/07_models/H05"),
  diagnostics = file.path(root, "artifacts/08_diagnostics/H05"),
  tables = file.path(root, "artifacts/09_tables/H05"),
  source_data = file.path(root, "artifacts/11_source_data/H05"),
  manifests = file.path(root, "artifacts/12_manifests/H05")
)
invisible(vapply(
  roots,
  dir.create,
  logical(1),
  recursive = TRUE,
  showWarnings = FALSE
))

relative_path <- function(path) {
  normalized <- normalizePath(path, winslash = "/", mustWork = TRUE)
  if (startsWith(normalized, paste0(root, "/"))) {
    substring(normalized, nchar(root) + 2L)
  } else {
    normalized
  }
}

read_h05_csv <- function(path) {
  readr::read_csv(path, show_col_types = FALSE, na = "")
}

write_h05_csv <- function(data, path) {
  write_csv_artifact(data, path, producer = producer)
  invisible(path)
}

write_h05_rds <- function(object, path) {
  write_rds_artifact(object, path, producer = producer)
  invisible(path)
}

align_to_baseline <- function(new, base) {
  missing <- setdiff(names(base), names(new))
  if (length(missing) > 0L) {
    stop(
      "Replacement rows are missing column(s): ",
      paste(missing, collapse = ", "),
      call. = FALSE
    )
  }
  new <- new[names(base)]
  for (name in names(base)) {
    if (inherits(base[[name]], "Date")) {
      new[[name]] <- as.Date(new[[name]])
    } else if (is.character(base[[name]])) {
      new[[name]] <- as.character(new[[name]])
    } else if (is.double(base[[name]])) {
      new[[name]] <- as.numeric(new[[name]])
    } else if (is.integer(base[[name]])) {
      new[[name]] <- as.integer(new[[name]])
    } else if (is.logical(base[[name]])) {
      new[[name]] <- as.logical(new[[name]])
    }
  }
  tibble::as_tibble(new)
}

target_primary_l10 <- function(data) {
  metric_match <- data$metric_id == metric_id
  if ("data_scenario_id" %in% names(data)) {
    return(data$data_scenario_id == primary_id & metric_match)
  }
  if ("run_id" %in% names(data)) {
    return(startsWith(data$run_id, paste0(primary_id, "__")) & metric_match)
  }
  metric_match
}

replace_primary_l10 <- function(base, replacement) {
  replacement <- align_to_baseline(replacement, base)
  dplyr::bind_rows(base[!target_primary_l10(base), , drop = FALSE], replacement)
}

replace_fields_by_key <- function(base, updates, keys, fields) {
  base_key <- do.call(paste, c(base[keys], sep = "\r"))
  update_key <- do.call(paste, c(updates[keys], sep = "\r"))
  index <- match(base_key, update_key)
  if (anyNA(index)) {
    stop("A field-only update did not match every row", call. = FALSE)
  }
  for (field in fields) {
    base[[field]] <- updates[[field]][index]
  }
  base
}

canonical_digest <- function(data, drop = character()) {
  data <- data[, setdiff(names(data), drop), drop = FALSE]
  keys <- intersect(
    c(
      "run_id",
      "data_scenario_id",
      "placement",
      "sample_scenario",
      "family_id",
      "metric_order",
      "metric_id",
      "factor_order",
      "factor_id",
      "model_name",
      "omitted_site",
      "site",
      "panel",
      "model_row_id",
      "participant_key",
      "local_date",
      "screen_rank",
      "v0_plot_order",
      "v0_order"
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
  # Rebuild from columns so custom provenance attributes do not masquerade as
  # scientific cell differences in canonical comparisons.
  data <- as.data.frame(
    lapply(data, identity),
    stringsAsFactors = FALSE,
    optional = TRUE
  )
  row.names(data) <- NULL
  digest::digest(data, algo = "sha256", serialize = TRUE)
}

identity_row <- function(run, spec, factor_row) {
  tibble::tibble(
    run_id = run$run_id,
    data_scenario_id = run$data_scenario_id,
    placement = run$placement,
    sample_scenario = run$sample_scenario,
    analytical_role = run$analytical_role,
    family_id = run$family_id,
    inferential_family = run$inferential_family,
    family_n = run$family_n,
    metric_order = spec$metric_order,
    metric_id = spec$metric_id,
    manuscript_name = spec$manuscript_name,
    analysis_unit = spec$analysis_unit,
    response_family = spec$response_family,
    response_transform = spec$response_transform,
    effect_scale = spec$effect_scale,
    factor_order = factor_row$factor_order,
    factor_id = factor_row$factor_id,
    factor_label = factor_row$factor_label
  )
}

bind_identity <- function(identity, data) {
  if (nrow(data) == 0L) {
    return(data)
  }
  dplyr::bind_cols(identity[rep(1L, nrow(data)), , drop = FALSE], data)
}

input_contract <- h05_input_contract(root)
input_audit <- dplyr::bind_rows(lapply(names(input_contract), function(role) {
  item <- input_contract[[role]]
  paths <- c(item$path, if (!is.null(item$manifest)) item$manifest)
  expected <- c(
    item$sha256,
    if (!is.null(item$manifest_sha256)) item$manifest_sha256
  )
  labels <- c(
    role,
    if (!is.null(item$manifest)) paste0(role, "_manifest")
  )
  dplyr::bind_rows(lapply(seq_along(paths), function(index) {
    observed <- artifact_sha256(paths[[index]])
    tibble::tibble(
      input_role = labels[[index]],
      path = relative_path(paths[[index]]),
      expected_sha256 = expected[[index]],
      observed_sha256 = observed,
      hash_verified = identical(observed, expected[[index]])
    )
  }))
}))
if (any(!input_audit$hash_verified)) {
  stop(
    "A METRIC-011 input differs from its H05 pin: ",
    paste(input_audit$path[!input_audit$hash_verified], collapse = ", "),
    call. = FALSE
  )
}

base_manifest <- read_h05_csv(input_contract$base_model_manifest$path)
base_bundle <- unique(base_manifest$input_bundle_sha256)
if (
  length(base_bundle) != 1L ||
    base_bundle !=
      "e840ce9d2a7f653bc5ebbfe020ce087017dfdaf0276df09da578bda30a539916"
) {
  stop("The METRIC-011 base input bundle pin is invalid", call. = FALSE)
}

objects <- list(
  main = readRDS(input_contract$main$path),
  manuscript_prepared_data = readRDS(
    input_contract$manuscript_prepared_data$path
  )
)
leba <- readRDS(input_contract$leba$path)
site_levels <- readr::read_csv(
  file.path(root, "config/site_display_registry.csv"),
  show_col_types = FALSE
) |>
  dplyr::arrange(.data$display_order) |>
  dplyr::pull(.data$site)

factor_registry <- h05_factor_registry()
metric_registry <- h05_metric_registry(objects$main$metric_contract)
run_registry <- h05_run_registry()
h05_validate_contract(metric_registry, factor_registry, run_registry)
spec <- metric_registry |>
  dplyr::filter(.data$metric_id == .env$metric_id)
primary_runs <- run_registry |>
  dplyr::filter(.data$data_scenario_id == .env$primary_id)
if (
  nrow(spec) != 1L ||
    spec$metric_order != 5L ||
    nrow(primary_runs) != 4L ||
    sum(primary_runs$inferential_family) != 2L
) {
  stop("The bounded H05 METRIC-011 contract is invalid", call. = FALSE)
}

changes_path <- file.path(
  root,
  "audit/reconciliation/l10_METRIC-011/primary_scientific_cell_changes.csv"
)
changes <- read_h05_csv(changes_path) |>
  dplyr::mutate(local_date = as.Date(.data$local_date))
if (
  nrow(changes) != 8L ||
    sum(changes$position == "glasses") != 3L ||
    sum(changes$position == "chest") != 5L ||
    any(changes$metric != metric_id) ||
    any(changes$new_value_lx != 0) ||
    any(changes$old_value_lx != 4.163336342344337e-17)
) {
  stop(
    "The upstream METRIC-011 changed-cell contract is invalid",
    call. = FALSE
  )
}

artifact_paths <- c(
  frames = file.path(roots$model_data, "H05_model_frame_index.csv"),
  effects = file.path(roots$tables, "H05_model_effects.csv"),
  tests = file.path(roots$tables, "H05_model_tests.csv"),
  master = file.path(roots$tables, "H05_model_results_master.csv"),
  diagnostics = file.path(roots$diagnostics, "H05_model_diagnostics.csv"),
  model_manifest = file.path(roots$models, "H05_model_manifest.csv"),
  influence = file.path(
    roots$diagnostics,
    "H05_participant_influence_screen.csv"
  ),
  random_site = file.path(roots$tables, "H05_random_site_sensitivity.csv"),
  loo = file.path(roots$tables, "H05_leave_one_site_out_refits.csv"),
  loo_summary = file.path(
    roots$tables,
    "H05_leave_one_site_out_summary.csv"
  ),
  spearman = file.path(roots$tables, "H05_descriptive_spearman.csv"),
  site_spearman = file.path(
    roots$diagnostics,
    "H05_site_stratified_spearman.csv"
  ),
  loo_spearman = file.path(
    roots$diagnostics,
    "H05_leave_one_site_out_spearman.csv"
  ),
  paired = file.path(roots$tables, "H05_paired_placement_comparison.csv"),
  gap = file.path(roots$tables, "H05_manuscript_prepared_comparison.csv"),
  v0 = file.path(roots$tables, "H05_v0_reproduction.csv"),
  v0_to_new = file.path(roots$tables, "H05_v0_to_new_comparison.csv"),
  diagnostic_plot = file.path(
    roots$source_data,
    "H05_primary_diagnostic_plot_data.csv"
  )
)
if (any(!file.exists(artifact_paths))) {
  stop("A required accepted H05 artifact is missing", call. = FALSE)
}
baseline <- lapply(artifact_paths, read_h05_csv)
baseline_sha256 <- unname(vapply(
  artifact_paths,
  artifact_sha256,
  character(1)
))

family_audit_path <- file.path(roots$tables, "H05_family_audit.csv")
primary_highlights_path <- file.path(
  roots$tables,
  "H05_primary_bh_highlights.csv"
)
frame_archive_path <- file.path(roots$model_data, "H05_model_frames.rds")
model_archive_path <- file.path(
  roots$models,
  "H05_inferential_model_objects.rds"
)
required_structural <- c(
  family_audit_path,
  primary_highlights_path,
  frame_archive_path,
  model_archive_path
)
if (any(!file.exists(required_structural))) {
  stop("A required H05 structural artifact is missing", call. = FALSE)
}
baseline_family_audit <- read_h05_csv(family_audit_path)
baseline_primary_highlights <- read_h05_csv(primary_highlights_path)
baseline_frame_archive_sha <- artifact_sha256(frame_archive_path)
baseline_model_archive_sha <- artifact_sha256(model_archive_path)
frame_archive <- readRDS(frame_archive_path)
model_archive <- readRDS(model_archive_path)

primary_frame_names <- paste(primary_runs$run_id, metric_id, sep = "::")
primary_model_names <- unlist(
  lapply(
    primary_runs$run_id[primary_runs$inferential_family],
    function(run_id)
      paste(run_id, metric_id, factor_registry$factor_id, sep = "::")
  ),
  use.names = FALSE
)
gap_frame_names <- grep(
  paste0("^", gap_id, ".*::", metric_id, "$"),
  names(frame_archive$model_frames),
  value = TRUE
)
gap_model_names <- grep(
  paste0("^", gap_id, ".*::", metric_id, "::"),
  names(model_archive),
  value = TRUE
)
if (
  !all(primary_frame_names %in% names(frame_archive$model_frames)) ||
    !all(primary_model_names %in% names(model_archive)) ||
    length(gap_frame_names) != 4L ||
    length(gap_model_names) != 4L
) {
  stop("The accepted H05 archives lack the expected L10 slices", call. = FALSE)
}

immutable_frame_names <- setdiff(
  names(frame_archive$model_frames),
  primary_frame_names
)
immutable_model_names <- setdiff(names(model_archive), primary_model_names)
immutable_frame_digest <- digest::digest(
  frame_archive$model_frames[immutable_frame_names],
  algo = "sha256",
  serialize = TRUE
)
immutable_model_digest <- digest::digest(
  model_archive[immutable_model_names],
  algo = "sha256",
  serialize = TRUE
)
gap_frame_digest <- digest::digest(
  frame_archive$model_frames[gap_frame_names],
  algo = "sha256",
  serialize = TRUE
)
gap_model_digest <- digest::digest(
  model_archive[gap_model_names],
  algo = "sha256",
  serialize = TRUE
)

model_rows_current <- objects$main$model_rows |>
  dplyr::filter(.data$metric_id == .env$metric_id) |>
  dplyr::mutate(local_date = as.Date(.data$local_date))
changed_model_rows <- changes |>
  dplyr::select(
    .data$position,
    .data$site,
    .data$Id,
    .data$local_date,
    .data$old_value_lx,
    .data$new_value_lx
  ) |>
  dplyr::left_join(
    model_rows_current |>
      dplyr::select(
        .data$position,
        .data$site,
        .data$Id,
        .data$local_date,
        .data$scenario,
        current_value_lx = .data$value,
        .data$participant_key
      ),
    by = c("position", "site", "Id", "local_date"),
    relationship = "many-to-many"
  ) |>
  dplyr::arrange(
    .data$position,
    .data$site,
    .data$Id,
    .data$local_date,
    .data$scenario
  )
if (
  nrow(changed_model_rows) != 16L ||
    any(changed_model_rows$current_value_lx != 0) ||
    any(
      !changed_model_rows$scenario %in%
        c(
          "all_available",
          "paired_common_sample"
        )
    )
) {
  stop(
    "The H01 primary L10 model rows do not reflect METRIC-011",
    call. = FALSE
  )
}

gap_l10 <- objects$manuscript_prepared_data$model_rows |>
  dplyr::filter(.data$metric_id == .env$metric_id) |>
  dplyr::mutate(local_date = as.Date(.data$local_date))
gap_changed_keys <- changes |>
  dplyr::select(.data$position, .data$site, .data$Id, .data$local_date) |>
  dplyr::left_join(
    gap_l10 |>
      dplyr::select(
        .data$position,
        .data$site,
        .data$Id,
        .data$local_date,
        .data$scenario,
        gap_value_lx = .data$value
      ),
    by = c("position", "site", "Id", "local_date"),
    relationship = "many-to-many"
  )
if (nrow(gap_changed_keys) != 16L || any(gap_changed_keys$gap_value_lx != 0)) {
  stop(
    "The gap-timing-unaware L10 scientific frame is not frozen",
    call. = FALSE
  )
}

new_results <- list(
  effects = list(),
  tests = list(),
  diagnostics = list(),
  samples = list(),
  model_manifest = list(),
  random_site = list(),
  loo = list(),
  influence = list(),
  spearman = list(),
  site_spearman = list(),
  loo_spearman = list(),
  diagnostic_plot = list()
)
new_frames <- list()
new_models <- list()
factor_cache <- list()
bundle_cache <- list()
frame_change_audit <- list()

for (run_index in seq_len(nrow(primary_runs))) {
  run <- primary_runs[run_index, , drop = FALSE]
  original_run_index <- match(run$run_id, run_registry$run_id)
  message("H05 METRIC-011 primary L10 run ", run_index, "/4: ", run$run_id)
  prepared <- h05_prepare_metric_rows(
    objects$main,
    spec,
    placement = run$placement,
    sample_scenario = run$sample_scenario,
    leba = leba,
    site_levels = site_levels
  )
  frame_key <- paste(run$run_id, metric_id, sep = "::")
  new_frame <- prepared$rows |>
    dplyr::select(
      .data$.model_row_id,
      .data$site,
      .data$Id,
      .data$participant_key,
      .data$local_date,
      .data$participant_days_contributing,
      .data$value,
      .data$metric_support_available,
      .data$metric_support_valid_minutes,
      .data$metric_support_expected_minutes,
      .data$metric_any_censored,
      dplyr::all_of(factor_registry$factor_id)
    )
  old_frame <- frame_archive$model_frames[[frame_key]]
  if (
    !identical(names(old_frame), names(new_frame)) ||
      nrow(old_frame) != nrow(new_frame)
  ) {
    stop("A METRIC-011 L10 frame changed structure", call. = FALSE)
  }
  non_value_columns <- setdiff(names(old_frame), "value")
  if (
    !identical(
      canonical_digest(old_frame[non_value_columns]),
      canonical_digest(new_frame[non_value_columns])
    )
  ) {
    stop("A non-value field changed in a primary L10 frame", call. = FALSE)
  }
  old_custom_attributes <- setdiff(
    names(attributes(old_frame)),
    c("names", "row.names", "class")
  )
  new_custom_attributes <- setdiff(
    names(attributes(new_frame)),
    c("names", "row.names", "class")
  )
  if (!setequal(old_custom_attributes, new_custom_attributes)) {
    stop(
      "A primary L10 frame changed custom attribute structure",
      call. = FALSE
    )
  }
  provenance_attribute_updated <- !identical(
    attr(old_frame, "metric_settings"),
    attr(new_frame, "metric_settings")
  )
  changed_index <- which(old_frame$value != new_frame$value)
  expected_keys <- changes |>
    dplyr::filter(.data$position == run$placement) |>
    dplyr::transmute(
      key = paste(.data$site, .data$Id, .data$local_date, sep = "\r")
    ) |>
    dplyr::pull(.data$key)
  observed_keys <- paste(
    as.character(new_frame$site[changed_index]),
    new_frame$Id[changed_index],
    new_frame$local_date[changed_index],
    sep = "\r"
  )
  if (
    !setequal(observed_keys, expected_keys) ||
      any(old_frame$value[changed_index] != 4.163336342344337e-17) ||
      any(new_frame$value[changed_index] != 0)
  ) {
    stop(
      "A primary L10 frame changed outside the eight approved cells",
      call. = FALSE
    )
  }
  new_frames[[frame_key]] <- new_frame
  frame_change_audit[[frame_key]] <- tibble::tibble(
    run_id = run$run_id,
    placement = run$placement,
    sample_scenario = run$sample_scenario,
    rows = nrow(new_frame),
    participants = dplyr::n_distinct(new_frame$participant_key),
    sites = nlevels(new_frame$site),
    changed_l10_cells = length(changed_index),
    old_value_lx = unique(old_frame$value[changed_index]),
    new_value_lx = unique(new_frame$value[changed_index]),
    non_value_fields_identical = TRUE,
    metric_settings_provenance_updated = provenance_attribute_updated,
    changed_keys_verified = TRUE
  )

  for (factor_index in seq_len(nrow(factor_registry))) {
    factor_row <- factor_registry[factor_index, , drop = FALSE]
    identity <- identity_row(run, spec, factor_row)
    factor_frame <- h05_add_factor_to_frame(prepared$rows, spec, factor_row)
    frame <- factor_frame$frame
    cache_key <- paste(run$run_id, factor_row$factor_id, sep = "::")
    factor_cache[[cache_key]] <- factor_frame
    sample_row <- dplyr::bind_cols(prepared$base_flow, factor_frame$scaling)
    new_results$samples[[cache_key]] <- bind_identity(identity, sample_row)

    bundle <- h05_fit_bundle(
      frame,
      spec,
      inferential = run$inferential_family
    )
    bundle_cache[[cache_key]] <- bundle
    effect <- h05_effect_summary(
      bundle$final$model,
      spec,
      factor_frame$scaling$leba_participant_sd
    )
    test <- h05_lrt_summary(bundle) |>
      dplyr::mutate(
        family_instance_id = if (run$inferential_family) {
          run$family_id
        } else {
          NA_character_
        },
        p_adjusted = NA_real_,
        family_observed_tests = if (run$inferential_family) {
          68L
        } else {
          NA_integer_
        },
        family_rank = NA_integer_
      )
    diagnostic_seed <- as.integer(
      500000L +
        original_run_index * 10000L +
        spec$metric_order * 100L +
        factor_index
    )
    diagnostics <- h05_diagnostic_summary(
      bundle,
      frame,
      seed = diagnostic_seed
    )
    model_manifest <- h05_model_manifest_rows(bundle)
    participant_summary <- h05_participant_summary(frame, spec)
    spearman <- h05_spearman_summary(participant_summary)
    influence <- h05_influence_candidates(bundle$final$model, frame, n = 3L)

    new_results$effects[[cache_key]] <- bind_identity(identity, effect)
    new_results$tests[[cache_key]] <- bind_identity(identity, test)
    new_results$diagnostics[[cache_key]] <- bind_identity(identity, diagnostics)
    new_results$model_manifest[[cache_key]] <- bind_identity(
      identity,
      model_manifest
    )
    new_results$spearman[[cache_key]] <- bind_identity(identity, spearman)
    new_results$influence[[cache_key]] <- bind_identity(identity, influence)

    if (run$inferential_family) {
      model_key <- paste(
        run$run_id,
        metric_id,
        factor_row$factor_id,
        sep = "::"
      )
      new_models[[model_key]] <- bundle
    }

    if (run$sample_scenario == "all_available") {
      random_site <- h05_random_site_summary(
        frame,
        spec,
        factor_frame$scaling$leba_participant_sd
      )
      new_results$random_site[[cache_key]] <- bind_identity(
        identity,
        random_site
      )
      new_results$site_spearman[[cache_key]] <- bind_identity(
        identity,
        h05_site_stratified_spearman(participant_summary)
      )
      new_results$loo_spearman[[cache_key]] <- bind_identity(
        identity,
        h05_leave_one_site_out_spearman(participant_summary)
      )
    }

    primary_near_eye <- run$placement == "glasses" &&
      run$sample_scenario == "all_available"
    if (primary_near_eye) {
      new_results$loo[[cache_key]] <- bind_identity(
        identity,
        h05_leave_one_site_out(
          frame,
          spec,
          factor_frame$scaling$leba_participant_sd,
          full_estimate = effect$estimate_model_per_point
        )
      )
      new_results$diagnostic_plot[[cache_key]] <- bind_identity(
        identity,
        h01_diagnostic_plot_data(bundle$final$model, frame)
      )
    }
  }
}

new_results <- lapply(new_results, dplyr::bind_rows)
frame_change_audit <- dplyr::bind_rows(frame_change_audit) |>
  dplyr::arrange(match(.data$run_id, primary_runs$run_id))

expected_counts <- c(
  effects = 16L,
  tests = 16L,
  diagnostics = 16L,
  samples = 16L,
  model_manifest = 48L,
  random_site = 8L,
  loo = 36L,
  influence = 48L,
  spearman = 16L,
  site_spearman = 68L,
  loo_spearman = 68L,
  diagnostic_plot = 6528L
)
observed_counts <- vapply(new_results[names(expected_counts)], nrow, integer(1))
if (!identical(observed_counts, expected_counts)) {
  stop(
    "The bounded L10 result dimensions differ from contract: ",
    paste(names(observed_counts), observed_counts, sep = "=", collapse = ", "),
    call. = FALSE
  )
}
if (length(new_frames) != 4L || length(new_models) != 8L) {
  stop("The bounded L10 archive dimensions differ from contract", call. = FALSE)
}

sample_check <- new_results$samples |>
  dplyr::distinct(
    .data$run_id,
    .data$observations,
    .data$participants,
    .data$participant_days,
    .data$sites
  ) |>
  dplyr::arrange(match(.data$run_id, primary_runs$run_id))
expected_samples <- tibble::tribble(
  ~run_id,
  ~observations,
  ~participants,
  ~participant_days,
  ~sites,
  "main__chest__all_available",
  902L,
  154L,
  902L,
  8L,
  "main__chest__paired_common_sample",
  643L,
  112L,
  643L,
  8L,
  "main__glasses__all_available",
  816L,
  141L,
  816L,
  9L,
  "main__glasses__paired_common_sample",
  643L,
  112L,
  643L,
  8L
) |>
  dplyr::arrange(match(.data$run_id, primary_runs$run_id))
if (
  !isTRUE(all.equal(sample_check, expected_samples, check.attributes = FALSE))
) {
  stop("METRIC-011 changed an H05 L10 fitted sample", call. = FALSE)
}

effects <- replace_primary_l10(baseline$effects, new_results$effects) |>
  dplyr::arrange(
    match(.data$run_id, run_registry$run_id),
    .data$metric_order,
    .data$factor_order
  )
samples <- replace_primary_l10(baseline$frames, new_results$samples) |>
  dplyr::arrange(
    match(.data$run_id, run_registry$run_id),
    .data$metric_order,
    .data$factor_order
  )
diagnostics <- replace_primary_l10(
  baseline$diagnostics,
  new_results$diagnostics
) |>
  dplyr::arrange(
    match(.data$run_id, run_registry$run_id),
    .data$metric_order,
    .data$factor_order
  )
tests_seed <- replace_primary_l10(baseline$tests, new_results$tests) |>
  dplyr::arrange(
    match(.data$run_id, run_registry$run_id),
    .data$metric_order,
    .data$factor_order
  )

inferential_tests <- tests_seed |>
  dplyr::filter(.data$inferential_family) |>
  dplyr::select(
    -.data$p_adjusted,
    -.data$family_observed_tests,
    -.data$family_rank
  ) |>
  adjust_result_families(
    family_col = "family_instance_id",
    p_col = "p_raw",
    family_n_col = "family_n",
    output_col = "p_adjusted",
    method = "BH"
  ) |>
  dplyr::group_by(.data$family_instance_id) |>
  dplyr::mutate(
    family_observed_tests = sum(!is.na(.data$p_raw)),
    family_rank = ifelse(
      is.na(.data$p_raw),
      NA_integer_,
      rank(.data$p_raw, ties.method = "min", na.last = "keep")
    )
  ) |>
  dplyr::ungroup()
noninferential_tests <- tests_seed |>
  dplyr::filter(!.data$inferential_family) |>
  dplyr::mutate(
    family_instance_id = NA_character_,
    p_adjusted = NA_real_,
    family_observed_tests = NA_integer_,
    family_rank = NA_integer_
  )
tests <- dplyr::bind_rows(inferential_tests, noninferential_tests) |>
  dplyr::select(dplyr::all_of(names(baseline$tests))) |>
  dplyr::arrange(
    match(.data$run_id, run_registry$run_id),
    .data$metric_order,
    .data$factor_order
  )
tests <- align_to_baseline(tests, baseline$tests)

family_audit <- tests |>
  dplyr::filter(.data$inferential_family) |>
  dplyr::group_by(.data$family_id) |>
  dplyr::summarise(
    planned_tests = dplyr::first(.data$family_n),
    registry_rows = dplyr::n(),
    observed_tests = sum(!is.na(.data$p_raw)),
    estimable_adjusted_tests = sum(!is.na(.data$p_adjusted)),
    passes_bh_0_05 = sum(.data$p_adjusted <= 0.05, na.rm = TRUE),
    vector_bh_verified = isTRUE(all.equal(
      .data$p_adjusted,
      adjust_p_family(.data$p_raw, method = "BH", n = 68L),
      tolerance = 1e-14
    )),
    .groups = "drop"
  )
if (
  nrow(family_audit) != 3L ||
    any(family_audit$registry_rows != 68L) ||
    any(family_audit$observed_tests != 68L) ||
    any(!family_audit$vector_bh_verified) ||
    any(family_audit$passes_bh_0_05 != 0L)
) {
  stop("The METRIC-011 complete-family BH audit failed", call. = FALSE)
}

computed_master <- effects |>
  dplyr::left_join(
    tests |>
      dplyr::select(
        .data$run_id,
        .data$metric_id,
        .data$factor_id,
        .data$statistic,
        .data$df,
        .data$p_raw,
        .data$p_adjusted,
        .data$family_rank,
        .data$family_observed_tests,
        .data$comparison_status
      ),
    by = c("run_id", "metric_id", "factor_id"),
    relationship = "one-to-one"
  ) |>
  dplyr::left_join(
    diagnostics |>
      dplyr::select(
        .data$run_id,
        .data$metric_id,
        .data$factor_id,
        .data$diagnostic_status,
        .data$model_adequacy,
        .data$specified_limitations
      ),
    by = c("run_id", "metric_id", "factor_id"),
    relationship = "one-to-one"
  ) |>
  dplyr::left_join(
    samples |>
      dplyr::select(
        .data$run_id,
        .data$metric_id,
        .data$factor_id,
        .data$observations,
        .data$participants,
        .data$participant_days,
        .data$represented_days,
        .data$sites,
        .data$leba_participant_mean,
        .data$leba_participant_sd,
        .data$model_frame_hash
      ),
    by = c("run_id", "metric_id", "factor_id"),
    relationship = "one-to-one"
  ) |>
  dplyr::select(dplyr::all_of(names(baseline$master)))
master <- computed_master |>
  dplyr::arrange(
    match(.data$run_id, run_registry$run_id),
    .data$metric_order,
    .data$factor_order
  )
master <- align_to_baseline(master, baseline$master)

model_manifest <- replace_primary_l10(
  baseline$model_manifest,
  new_results$model_manifest
) |>
  dplyr::arrange(
    match(.data$run_id, run_registry$run_id),
    .data$metric_order,
    .data$factor_order,
    match(
      .data$model_name,
      c("comparison_full", "comparison_reduced", "final_full")
    )
  )
influence <- replace_primary_l10(
  baseline$influence,
  new_results$influence
) |>
  dplyr::arrange(
    match(.data$run_id, run_registry$run_id),
    .data$metric_order,
    .data$factor_order,
    .data$screen_rank
  )

new_random_site <- new_results$random_site |>
  dplyr::left_join(
    effects |>
      dplyr::select(
        .data$run_id,
        .data$metric_id,
        .data$factor_id,
        fixed_estimate_model_per_point = .data$estimate_model_per_point
      ),
    by = c("run_id", "metric_id", "factor_id"),
    relationship = "many-to-one"
  ) |>
  dplyr::mutate(
    estimate_change_random_minus_fixed = .data$estimate_model_per_point -
      .data$fixed_estimate_model_per_point,
    sign_concordant = dplyr::if_else(
      is.finite(.data$estimate_model_per_point) &
        is.finite(.data$fixed_estimate_model_per_point) &
        .data$fixed_estimate_model_per_point != 0,
      sign(.data$estimate_model_per_point) ==
        sign(.data$fixed_estimate_model_per_point),
      NA
    ),
    relative_absolute_change = dplyr::if_else(
      is.finite(.data$fixed_estimate_model_per_point) &
        abs(.data$fixed_estimate_model_per_point) > 1e-12,
      abs(
        .data$estimate_change_random_minus_fixed /
          .data$fixed_estimate_model_per_point
      ),
      NA_real_
    ),
    stability_class = dplyr::case_when(
      .data$random_site_status != "DESCRIPTIVE_PASS" ~ "fit_unstable",
      .data$sign_concordant %in% FALSE ~ "direction_unstable",
      is.finite(.data$relative_absolute_change) &
        .data$relative_absolute_change > 0.5 ~
        "direction_stable_magnitude_sensitive",
      TRUE ~ "stable"
    )
  )
random_site <- replace_primary_l10(
  baseline$random_site,
  new_random_site
) |>
  dplyr::arrange(
    match(.data$run_id, run_registry$run_id),
    .data$metric_order,
    .data$factor_order
  )

loo <- replace_primary_l10(baseline$loo, new_results$loo) |>
  dplyr::arrange(
    .data$metric_order,
    .data$factor_order,
    match(.data$omitted_site, site_levels)
  )
new_loo_summary <- new_results$loo |>
  dplyr::group_by(
    .data$run_id,
    .data$metric_order,
    .data$metric_id,
    .data$manuscript_name,
    .data$factor_order,
    .data$factor_id,
    .data$factor_label
  ) |>
  dplyr::summarise(
    omitted_sites = dplyr::n(),
    successful_refits = sum(.data$refit_status == "PASS"),
    sign_reversal_sites = sum(.data$sign_reversal %in% TRUE, na.rm = TRUE),
    maximum_relative_absolute_change = max(
      .data$relative_absolute_change,
      na.rm = TRUE
    ),
    minimum_estimate = min(.data$estimate_model_per_point, na.rm = TRUE),
    maximum_estimate = max(.data$estimate_model_per_point, na.rm = TRUE),
    stability_class = dplyr::case_when(
      successful_refits < omitted_sites ~ "fit_unstable",
      sign_reversal_sites > 0L ~ "direction_unstable",
      is.finite(maximum_relative_absolute_change) &
        maximum_relative_absolute_change > 0.5 ~
        "direction_stable_magnitude_sensitive",
      TRUE ~ "stable"
    ),
    .groups = "drop"
  )
loo_summary <- replace_primary_l10(
  baseline$loo_summary,
  new_loo_summary
) |>
  dplyr::arrange(.data$metric_order, .data$factor_order)

spearman <- replace_primary_l10(baseline$spearman, new_results$spearman) |>
  dplyr::arrange(
    match(.data$run_id, run_registry$run_id),
    .data$metric_order,
    .data$factor_order
  )
site_spearman <- replace_primary_l10(
  baseline$site_spearman,
  new_results$site_spearman
) |>
  dplyr::arrange(
    match(.data$run_id, run_registry$run_id),
    .data$metric_order,
    .data$factor_order,
    match(.data$site, site_levels)
  )
loo_spearman <- replace_primary_l10(
  baseline$loo_spearman,
  new_results$loo_spearman
) |>
  dplyr::arrange(
    match(.data$run_id, run_registry$run_id),
    .data$metric_order,
    .data$factor_order,
    match(.data$omitted_site, site_levels)
  )
diagnostic_plot <- replace_primary_l10(
  baseline$diagnostic_plot,
  new_results$diagnostic_plot
) |>
  dplyr::arrange(
    .data$metric_order,
    .data$factor_order,
    .data$panel,
    .data$model_row_id
  )

computed_paired <- effects |>
  dplyr::filter(
    .data$data_scenario_id == .env$primary_id,
    .data$sample_scenario == "paired_common_sample",
    .data$metric_id == .env$metric_id
  ) |>
  dplyr::select(
    .data$placement,
    .data$metric_order,
    .data$metric_id,
    .data$manuscript_name,
    .data$factor_order,
    .data$factor_id,
    .data$factor_label,
    .data$effect_type,
    .data$estimate_model_per_sd,
    .data$conf_low_model_per_sd,
    .data$conf_high_model_per_sd,
    .data$estimate_practical_per_sd,
    .data$conf_low_practical_per_sd,
    .data$conf_high_practical_per_sd
  ) |>
  tidyr::pivot_wider(
    names_from = .data$placement,
    values_from = c(
      .data$effect_type,
      .data$estimate_model_per_sd,
      .data$conf_low_model_per_sd,
      .data$conf_high_model_per_sd,
      .data$estimate_practical_per_sd,
      .data$conf_low_practical_per_sd,
      .data$conf_high_practical_per_sd
    ),
    names_sep = "__"
  ) |>
  dplyr::mutate(
    estimate_difference_chest_minus_near_eye = .data$estimate_model_per_sd__chest -
      .data$estimate_model_per_sd__glasses,
    sign_concordant = dplyr::if_else(
      is.finite(.data$estimate_model_per_sd__chest) &
        is.finite(.data$estimate_model_per_sd__glasses),
      sign(.data$estimate_model_per_sd__chest) ==
        sign(.data$estimate_model_per_sd__glasses),
      NA
    ),
    component_intervals_overlap = .data$conf_low_model_per_sd__chest <=
      .data$conf_high_model_per_sd__glasses &
      .data$conf_low_model_per_sd__glasses <=
        .data$conf_high_model_per_sd__chest,
    stability_class = dplyr::case_when(
      .data$sign_concordant %in% FALSE ~ "direction_differs",
      .data$component_intervals_overlap %in% FALSE ~
        "direction_same_component_intervals_separated",
      TRUE ~ "direction_and_component_intervals_compatible"
    ),
    difference_interval_status = paste0(
      "deferred: paired participant-cluster interval requires an approved ",
      "expensive resampling run"
    )
  ) |>
  dplyr::select(dplyr::all_of(names(baseline$paired)))
paired <- dplyr::bind_rows(
  baseline$paired[baseline$paired$metric_id != metric_id, , drop = FALSE],
  align_to_baseline(computed_paired, baseline$paired)
) |>
  dplyr::arrange(.data$metric_order, .data$factor_order)
if (nrow(computed_paired) != 4L) {
  stop("The primary paired/common L10 comparison is incomplete", call. = FALSE)
}

computed_gap <- effects |>
  dplyr::filter(
    .data$placement == "glasses",
    .data$sample_scenario == "all_available",
    .data$data_scenario_id %in% c(.env$primary_id, .env$gap_id),
    .data$metric_id == .env$metric_id
  ) |>
  dplyr::select(
    .data$data_scenario_id,
    .data$metric_order,
    .data$metric_id,
    .data$manuscript_name,
    .data$factor_order,
    .data$factor_id,
    .data$factor_label,
    .data$estimate_model_per_sd,
    .data$conf_low_model_per_sd,
    .data$conf_high_model_per_sd
  ) |>
  tidyr::pivot_wider(
    names_from = .data$data_scenario_id,
    values_from = c(
      .data$estimate_model_per_sd,
      .data$conf_low_model_per_sd,
      .data$conf_high_model_per_sd
    ),
    names_sep = "__"
  ) |>
  dplyr::mutate(
    estimate_difference_mpd_minus_main = .data$estimate_model_per_sd__manuscript_prepared_data -
      .data$estimate_model_per_sd__main,
    sign_concordant = sign(
      .data$estimate_model_per_sd__manuscript_prepared_data
    ) ==
      sign(.data$estimate_model_per_sd__main),
    component_intervals_overlap = .data$conf_low_model_per_sd__manuscript_prepared_data <=
      .data$conf_high_model_per_sd__main &
      .data$conf_low_model_per_sd__main <=
        .data$conf_high_model_per_sd__manuscript_prepared_data
  ) |>
  dplyr::select(dplyr::all_of(names(baseline$gap)))
gap_comparison <- dplyr::bind_rows(
  baseline$gap[baseline$gap$metric_id != metric_id, , drop = FALSE],
  align_to_baseline(computed_gap, baseline$gap)
) |>
  dplyr::arrange(.data$metric_order, .data$factor_order)
if (nrow(computed_gap) != 4L) {
  stop("The primary-versus-gap L10 comparison is incomplete", call. = FALSE)
}

v0 <- baseline$v0
computed_v0_to_new <- v0 |>
  dplyr::filter(.data$placement == "near-eye") |>
  dplyr::left_join(
    spearman |>
      dplyr::filter(
        .data$data_scenario_id == .env$primary_id,
        .data$placement == "glasses",
        .data$sample_scenario == "all_available"
      ) |>
      dplyr::select(
        metric_id_current = .data$metric_id,
        .data$factor_id,
        new_descriptive_rho = .data$spearman_rho,
        new_descriptive_rho_low = .data$conf_low,
        new_descriptive_rho_high = .data$conf_high,
        new_pairs = .data$pairs
      ),
    by = c("metric_id_current", "factor_id"),
    relationship = "one-to-one"
  ) |>
  dplyr::left_join(
    master |>
      dplyr::filter(
        .data$data_scenario_id == .env$primary_id,
        .data$placement == "glasses",
        .data$sample_scenario == "all_available"
      ) |>
      dplyr::select(
        metric_id_current = .data$metric_id,
        .data$factor_id,
        fixed_site_effect_per_sd = .data$estimate_practical_per_sd,
        fixed_site_effect_low = .data$conf_low_practical_per_sd,
        fixed_site_effect_high = .data$conf_high_practical_per_sd,
        effect_type = .data$effect_type,
        fixed_site_p_raw = .data$p_raw,
        fixed_site_p_adjusted = .data$p_adjusted,
        model_adequacy = .data$model_adequacy,
        specified_limitations = .data$specified_limitations,
        new_observations = .data$observations,
        new_participants = .data$participants,
        new_sites = .data$sites
      ),
    by = c("metric_id_current", "factor_id"),
    relationship = "one-to-one"
  ) |>
  dplyr::mutate(
    v0_repaired_rho_change = .data$new_descriptive_rho - .data$spearman_rho,
    primary_bh_flag = .data$fixed_site_p_adjusted <= 0.05
  ) |>
  dplyr::select(dplyr::all_of(names(baseline$v0_to_new))) |>
  dplyr::arrange(.data$v0_plot_order, .data$factor_order)
inherited_v0_to_new <- baseline$v0_to_new |>
  dplyr::filter(.data$metric_id_current != .env$metric_id)
inherited_v0_to_new <- replace_fields_by_key(
  inherited_v0_to_new,
  computed_v0_to_new |>
    dplyr::filter(.data$metric_id_current != .env$metric_id),
  keys = c("metric_id_current", "factor_id"),
  fields = c("fixed_site_p_adjusted", "primary_bh_flag")
)
v0_to_new <- dplyr::bind_rows(
  inherited_v0_to_new,
  computed_v0_to_new |>
    dplyr::filter(.data$metric_id_current == .env$metric_id)
) |>
  dplyr::arrange(.data$v0_plot_order, .data$factor_order)
v0_to_new <- align_to_baseline(v0_to_new, baseline$v0_to_new)

primary <- master |>
  dplyr::filter(.data$run_id == "main__glasses__all_available")
primary_highlights <- primary |>
  dplyr::filter(.data$p_adjusted <= 0.05) |>
  dplyr::arrange(.data$p_adjusted)
if (nrow(primary_highlights) != 0L) {
  stop(
    "METRIC-011 unexpectedly created a BH-retained H05 result",
    call. = FALSE
  )
}

for (name in primary_frame_names) {
  frame_archive$model_frames[[name]] <- new_frames[[name]]
}
for (name in primary_model_names) {
  model_archive[[name]] <- new_models[[name]]
}
frame_archive$input_contract <- input_contract
frame_archive$status <- "metric011_primary_l10_slice_resealed"
frame_archive$metadata$metric011_decision_id <- "METRIC-011"
frame_archive$metadata$l10_numerical_zero_rule <- paste0(
  "Offset geometric-mean residuals within the unit-aware numerical ",
  "tolerance are set to exact zero only with exact-zero source provenance"
)
frame_archive$metadata$metric011_scope <- paste0(
  "Only four primary L10 frames were replaced; all gap-timing-unaware ",
  "frames and all non-L10 frames are frozen"
)

if (
  !identical(
    immutable_frame_digest,
    digest::digest(
      frame_archive$model_frames[immutable_frame_names],
      algo = "sha256",
      serialize = TRUE
    )
  ) ||
    !identical(
      immutable_model_digest,
      digest::digest(
        model_archive[immutable_model_names],
        algo = "sha256",
        serialize = TRUE
      )
    ) ||
    !identical(
      gap_frame_digest,
      digest::digest(
        frame_archive$model_frames[gap_frame_names],
        algo = "sha256",
        serialize = TRUE
      )
    ) ||
    !identical(
      gap_model_digest,
      digest::digest(
        model_archive[gap_model_names],
        algo = "sha256",
        serialize = TRUE
      )
    )
) {
  stop("A frozen H05 frame or fitted-model object changed", call. = FALSE)
}

comparison_objects <- list(
  frames = samples,
  effects = effects,
  tests = tests,
  master = master,
  diagnostics = diagnostics,
  model_manifest = model_manifest,
  influence = influence,
  random_site = random_site,
  loo = loo,
  loo_summary = loo_summary,
  spearman = spearman,
  site_spearman = site_spearman,
  loo_spearman = loo_spearman,
  paired = paired,
  gap = gap_comparison,
  v0 = v0,
  v0_to_new = v0_to_new,
  diagnostic_plot = diagnostic_plot
)
allowed_derived <- list(
  tests = c("p_adjusted", "family_rank"),
  master = c("p_adjusted", "family_rank"),
  v0_to_new = c("fixed_site_p_adjusted", "primary_bh_flag")
)
reconciliation <- dplyr::bind_rows(lapply(
  names(comparison_objects),
  function(name) {
    before <- baseline[[name]]
    after <- comparison_objects[[name]]
    if (name %in% c("v0", "v0_to_new")) {
      id_column <- "metric_id_current"
      before_frozen <- before[before[[id_column]] != metric_id, , drop = FALSE]
      after_frozen <- after[after[[id_column]] != metric_id, , drop = FALSE]
    } else if (name %in% c("paired", "gap")) {
      before_frozen <- before[before$metric_id != metric_id, , drop = FALSE]
      after_frozen <- after[after$metric_id != metric_id, , drop = FALSE]
    } else {
      before_frozen <- before[!target_primary_l10(before), , drop = FALSE]
      after_frozen <- after[!target_primary_l10(after), , drop = FALSE]
    }
    dropped <- allowed_derived[[name]]
    if (is.null(dropped)) {
      dropped <- character()
    }
    before_digest <- canonical_digest(before_frozen, drop = dropped)
    after_digest <- canonical_digest(after_frozen, drop = dropped)
    tibble::tibble(
      artifact_id = name,
      baseline_path = relative_path(artifact_paths[[name]]),
      baseline_file_sha256 = baseline_sha256[[match(
        name,
        names(artifact_paths)
      )]],
      invariant_scope = paste0(
        "all rows outside primary L10, excluding declared BH-derived fields"
      ),
      allowed_derived_fields = paste(dropped, collapse = ";"),
      baseline_frozen_digest = before_digest,
      updated_frozen_digest = after_digest,
      invariant_verified = identical(before_digest, after_digest),
      frozen_rows = nrow(after_frozen)
    )
  }
))
if (any(!reconciliation$invariant_verified)) {
  if (
    "v0_to_new" %in%
      reconciliation$artifact_id[
        !reconciliation$invariant_verified
      ]
  ) {
    before_debug <- baseline$v0_to_new |>
      dplyr::filter(.data$metric_id_current != .env$metric_id) |>
      dplyr::arrange(.data$v0_plot_order, .data$factor_order)
    after_debug <- v0_to_new |>
      dplyr::filter(.data$metric_id_current != .env$metric_id) |>
      dplyr::arrange(.data$v0_plot_order, .data$factor_order)
    debug_fields <- setdiff(
      names(before_debug),
      c("fixed_site_p_adjusted", "primary_bh_flag")
    )
    differing_fields <- debug_fields[
      !vapply(
        debug_fields,
        function(field) identical(before_debug[[field]], after_debug[[field]]),
        logical(1)
      )
    ]
    message(
      "v0_to_new frozen-field diagnostics: ",
      paste(differing_fields, collapse = ", ")
    )
  }
  stop(
    "A frozen H05 scientific artifact changed: ",
    paste(
      reconciliation$artifact_id[!reconciliation$invariant_verified],
      collapse = ", "
    ),
    call. = FALSE
  )
}

reconciliation <- dplyr::bind_rows(
  reconciliation,
  tibble::tibble(
    artifact_id = c(
      "model_frame_objects",
      "inferential_model_objects",
      "gap_l10_frame_objects",
      "gap_l10_inferential_model_objects"
    ),
    baseline_path = c(
      relative_path(frame_archive_path),
      relative_path(model_archive_path),
      relative_path(frame_archive_path),
      relative_path(model_archive_path)
    ),
    baseline_file_sha256 = c(
      baseline_frame_archive_sha,
      baseline_model_archive_sha,
      baseline_frame_archive_sha,
      baseline_model_archive_sha
    ),
    invariant_scope = c(
      "all 132 stored frames outside the four primary L10 frames",
      "all 196 fitted bundles outside the eight primary L10 bundles",
      "all four gap-timing-unaware L10 frames",
      "all four gap-timing-unaware L10 inferential bundles"
    ),
    allowed_derived_fields = "",
    baseline_frozen_digest = c(
      immutable_frame_digest,
      immutable_model_digest,
      gap_frame_digest,
      gap_model_digest
    ),
    updated_frozen_digest = c(
      immutable_frame_digest,
      immutable_model_digest,
      gap_frame_digest,
      gap_model_digest
    ),
    invariant_verified = TRUE,
    frozen_rows = c(
      length(immutable_frame_names),
      length(immutable_model_names),
      length(gap_frame_names),
      length(gap_model_names)
    )
  )
)

bh_change_audit <- baseline$tests |>
  dplyr::filter(.data$inferential_family) |>
  dplyr::select(
    .data$run_id,
    .data$data_scenario_id,
    .data$placement,
    .data$family_id,
    .data$metric_order,
    .data$metric_id,
    .data$factor_order,
    .data$factor_id,
    before_p_raw = .data$p_raw,
    before_p_adjusted = .data$p_adjusted,
    before_family_rank = .data$family_rank
  ) |>
  dplyr::inner_join(
    tests |>
      dplyr::filter(.data$inferential_family) |>
      dplyr::select(
        .data$run_id,
        .data$metric_id,
        .data$factor_id,
        after_p_raw = .data$p_raw,
        after_p_adjusted = .data$p_adjusted,
        after_family_rank = .data$family_rank
      ),
    by = c("run_id", "metric_id", "factor_id"),
    relationship = "one-to-one"
  ) |>
  dplyr::mutate(
    raw_p_changed = abs(.data$before_p_raw - .data$after_p_raw) > 1e-15,
    adjusted_p_changed = abs(.data$before_p_adjusted - .data$after_p_adjusted) >
      1e-15,
    family_rank_changed = .data$before_family_rank != .data$after_family_rank,
    permitted_raw_change = .data$data_scenario_id == .env$primary_id &
      .data$metric_id == .env$metric_id
  ) |>
  dplyr::arrange(
    .data$family_id,
    .data$after_p_raw,
    .data$metric_order,
    .data$factor_order
  )
if (
  any(bh_change_audit$raw_p_changed & !bh_change_audit$permitted_raw_change) ||
    sum(bh_change_audit$raw_p_changed) > 8L
) {
  stop("A frozen raw H05 test changed during BH refresh", call. = FALSE)
}

l10_result_change_audit <- baseline$master |>
  dplyr::filter(
    .data$data_scenario_id == .env$primary_id,
    .data$metric_id == .env$metric_id
  ) |>
  dplyr::select(
    .data$run_id,
    .data$placement,
    .data$sample_scenario,
    .data$family_id,
    .data$factor_order,
    .data$factor_id,
    before_estimate_per_point = .data$estimate_model_per_point,
    before_conf_low_per_point = .data$conf_low_model_per_point,
    before_conf_high_per_point = .data$conf_high_model_per_point,
    before_p_raw = .data$p_raw,
    before_p_adjusted = .data$p_adjusted,
    before_family_rank = .data$family_rank,
    before_model_frame_hash = .data$model_frame_hash,
    before_diagnostic_status = .data$diagnostic_status,
    before_model_adequacy = .data$model_adequacy,
    before_specified_limitations = .data$specified_limitations
  ) |>
  dplyr::inner_join(
    master |>
      dplyr::filter(
        .data$data_scenario_id == .env$primary_id,
        .data$metric_id == .env$metric_id
      ) |>
      dplyr::select(
        .data$run_id,
        .data$factor_id,
        after_estimate_per_point = .data$estimate_model_per_point,
        after_conf_low_per_point = .data$conf_low_model_per_point,
        after_conf_high_per_point = .data$conf_high_model_per_point,
        after_p_raw = .data$p_raw,
        after_p_adjusted = .data$p_adjusted,
        after_family_rank = .data$family_rank,
        after_model_frame_hash = .data$model_frame_hash,
        after_diagnostic_status = .data$diagnostic_status,
        after_model_adequacy = .data$model_adequacy,
        after_specified_limitations = .data$specified_limitations
      ),
    by = c("run_id", "factor_id"),
    relationship = "one-to-one"
  ) |>
  dplyr::mutate(
    estimate_change_per_point = .data$after_estimate_per_point -
      .data$before_estimate_per_point,
    bh_retained_after = .data$after_p_adjusted <= 0.05
  ) |>
  dplyr::arrange(
    match(.data$run_id, primary_runs$run_id),
    .data$factor_order
  )
if (
  nrow(l10_result_change_audit) != 16L ||
    any(
      l10_result_change_audit$bh_retained_after,
      na.rm = TRUE
    )
) {
  stop("The L10 result-change audit is incomplete", call. = FALSE)
}

execution_environment <- tibble::tibble(
  field = c(
    "decision_id",
    "r_version",
    "platform",
    "script",
    "primary_l10_frames_rebuilt",
    "primary_l10_core_cells_refit",
    "inferential_model_bundles_replaced",
    "random_site_sensitivities_refit",
    "near_eye_leave_one_site_out_refits",
    "gap_l10_models_refit",
    "non_l10_models_refit",
    "resampling_run",
    "base_input_bundle_sha256"
  ),
  value = c(
    "METRIC-011",
    as.character(getRversion()),
    R.version$platform,
    producer,
    "4",
    "16",
    "8",
    "8",
    "36",
    "0",
    "0",
    "FALSE",
    base_bundle
  )
)
package_environment <- tibble::tibble(
  package = required_packages,
  version = vapply(
    required_packages,
    function(package) as.character(utils::packageVersion(package)),
    character(1)
  )
)

reconciliation_path <- file.path(
  roots$manifests,
  "H05_metric011_reconciliation.csv"
)
frame_audit_path <- file.path(
  roots$manifests,
  "H05_metric011_primary_l10_frame_audit.csv"
)
bh_audit_path <- file.path(
  roots$manifests,
  "H05_metric011_bh_change_audit.csv"
)
result_audit_path <- file.path(
  roots$manifests,
  "H05_metric011_l10_result_change_audit.csv"
)
input_cell_audit_path <- file.path(
  roots$manifests,
  "H05_metric011_input_cell_audit.csv"
)
environment_path <- file.path(
  roots$manifests,
  "H05_metric011_execution_environment.csv"
)
package_path <- file.path(
  roots$manifests,
  "H05_metric011_package_versions.csv"
)

# Install only after every scientific and frozen-identity assertion above has
# passed. Each write uses the project's atomic artifact writer.
write_h05_csv(input_audit, file.path(roots$model_data, "H05_input_audit.csv"))
write_h05_csv(samples, artifact_paths[["frames"]])
write_h05_rds(frame_archive, frame_archive_path)
write_h05_rds(model_archive, model_archive_path)
write_h05_csv(model_manifest, artifact_paths[["model_manifest"]])
write_h05_csv(effects, artifact_paths[["effects"]])
write_h05_csv(tests, artifact_paths[["tests"]])
write_h05_csv(master, artifact_paths[["master"]])
write_h05_csv(family_audit, family_audit_path)
write_h05_csv(primary_highlights, primary_highlights_path)
write_h05_csv(diagnostics, artifact_paths[["diagnostics"]])
write_h05_csv(influence, artifact_paths[["influence"]])
write_h05_csv(random_site, artifact_paths[["random_site"]])
write_h05_csv(loo, artifact_paths[["loo"]])
write_h05_csv(loo_summary, artifact_paths[["loo_summary"]])
write_h05_csv(spearman, artifact_paths[["spearman"]])
write_h05_csv(site_spearman, artifact_paths[["site_spearman"]])
write_h05_csv(loo_spearman, artifact_paths[["loo_spearman"]])
write_h05_csv(paired, artifact_paths[["paired"]])
write_h05_csv(gap_comparison, artifact_paths[["gap"]])
write_h05_csv(v0_to_new, artifact_paths[["v0_to_new"]])
write_h05_csv(diagnostic_plot, artifact_paths[["diagnostic_plot"]])
write_h05_csv(reconciliation, reconciliation_path)
write_h05_csv(frame_change_audit, frame_audit_path)
write_h05_csv(bh_change_audit, bh_audit_path)
write_h05_csv(l10_result_change_audit, result_audit_path)
write_h05_csv(changed_model_rows, input_cell_audit_path)
write_h05_csv(execution_environment, environment_path)
write_h05_csv(package_environment, package_path)

updated_artifact_paths <- c(
  h05_input_audit = file.path(roots$model_data, "H05_input_audit.csv"),
  artifact_paths[names(artifact_paths) != "v0"],
  family_audit = family_audit_path,
  primary_highlights = primary_highlights_path,
  model_frames_rds = frame_archive_path,
  inferential_model_objects_rds = model_archive_path,
  metric011_reconciliation = reconciliation_path,
  metric011_primary_l10_frame_audit = frame_audit_path,
  metric011_bh_change_audit = bh_audit_path,
  metric011_l10_result_change_audit = result_audit_path,
  metric011_input_cell_audit = input_cell_audit_path,
  metric011_execution_environment = environment_path,
  metric011_package_versions = package_path
)
artifact_manifest <- dplyr::bind_rows(lapply(
  names(updated_artifact_paths),
  function(artifact_id) {
    path <- updated_artifact_paths[[artifact_id]]
    info <- file.info(path)
    rows <- if (grepl("\\.csv$", path)) nrow(read_h05_csv(path)) else
      NA_integer_
    tibble::tibble(
      artifact_id = artifact_id,
      path = relative_path(path),
      sha256 = artifact_sha256(path),
      bytes = as.numeric(info$size),
      rows = rows,
      producer = producer,
      r_version = as.character(getRversion()),
      decision_id = "METRIC-011",
      status = "PASS"
    )
  }
))
artifact_manifest_path <- file.path(
  roots$manifests,
  "H05_metric011_artifact_update_manifest.csv"
)
write_h05_csv(artifact_manifest, artifact_manifest_path)

post_gap_frame_digest <- digest::digest(
  readRDS(frame_archive_path)$model_frames[gap_frame_names],
  algo = "sha256",
  serialize = TRUE
)
post_gap_model_digest <- digest::digest(
  readRDS(model_archive_path)[gap_model_names],
  algo = "sha256",
  serialize = TRUE
)
if (
  !identical(post_gap_frame_digest, gap_frame_digest) ||
    !identical(post_gap_model_digest, gap_model_digest)
) {
  stop("Installed archives violate the frozen gap L10 identity", call. = FALSE)
}

message(
  "H05 METRIC-011 reseal complete: 4 primary L10 frames, 16 core cells, ",
  "8 inferential bundles, 8 random-site sensitivities, and 36 LOSO refits; ",
  "0 gap L10 or non-L10 refits; all three 68-test families retain 0 BH ",
  "associations."
)
message(
  "Artifact manifest SHA-256: ",
  artifact_sha256(artifact_manifest_path)
)
