#!/usr/bin/env Rscript

# Refresh only the H05 result slice that depends on the author-approved
# METRIC-010 MDER estimand. The other 16 metrics and their fitted objects are
# inherited from the accepted H05 archive and verified unchanged. The only
# permitted derived change outside MDER is BH adjustment/rank after replacing
# four raw MDER p-values in each complete 68-test family.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)

source(file.path(root, "scripts/pipeline/paths_io.R"))

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("The H05 METRIC-010 refresh requires R 4.6.1", call. = FALSE)
}

producer <- "scripts/hypotheses/H05/refresh_h05_mder_metric010.R"
mode <- Sys.getenv("H05_METRIC010_MODE", unset = "fit")
if (!mode %in% c("fit", "manifest")) {
  stop("H05_METRIC010_MODE must be `fit` or `manifest`", call. = FALSE)
}

h05_relative_path <- function(path) {
  normalized <- normalizePath(path, winslash = "/", mustWork = TRUE)
  if (startsWith(normalized, paste0(root, "/"))) {
    substring(normalized, nchar(root) + 2L)
  } else {
    normalized
  }
}

if (identical(mode, "manifest")) {
  # The shared H01 contract can receive coordinator-owned provenance pin
  # updates after the bounded H05 fit. Repin it only when its complete
  # H05-relevant metric/model registry is exactly the one stored with H05.
  source(file.path(root, "scripts/hypotheses/H01/h01_contract.R"))
  source(file.path(root, "scripts/hypotheses/H05/h05_contract.R"))
  registry_fields <- c(
    "metric_order", "metric_id", "analysis_unit", "response_family",
    "response_transform", "effect_scale"
  )
  current_registry <- h01_metric_registry()[registry_fields]
  stored_registry <- readr::read_csv(
    file.path(root, "artifacts/06_model_data/H05/H05_metric_registry.csv"),
    show_col_types = FALSE
  )[registry_fields]
  if (!isTRUE(all.equal(
    current_registry,
    stored_registry,
    check.attributes = FALSE
  ))) {
    stop(
      "The current shared H01 contract changes the stored H05 model registry",
      call. = FALSE
    )
  }
  input_audit_path <- file.path(
    root,
    "artifacts/06_model_data/H05/H05_input_audit.csv"
  )
  input_audit <- readr::read_csv(input_audit_path, show_col_types = FALSE)
  contract_row <- input_audit$input_role == "h01_contract_source"
  if (sum(contract_row) != 1L) {
    stop("The H05 input audit lacks one H01 contract row", call. = FALSE)
  }
  current_contract_pin <- h05_input_contract(root)$h01_contract_source$sha256
  input_audit$expected_sha256[contract_row] <- current_contract_pin
  input_audit$observed_sha256 <- vapply(
    file.path(root, input_audit$path),
    artifact_sha256,
    character(1)
  )
  input_audit$hash_verified <-
    input_audit$observed_sha256 == input_audit$expected_sha256
  if (any(!input_audit$hash_verified)) {
    stop("A current H05 input identity no longer matches its pin", call. = FALSE)
  }
  write_csv_artifact(input_audit, input_audit_path, producer = producer)

  manifest_path <- file.path(
    root,
    "artifacts/12_manifests/H05/H05_stage2_artifacts.csv"
  )
  manifest <- readr::read_csv(manifest_path, show_col_types = FALSE)
  expected_columns <- c(
    "path", "artifact_type", "sha256", "bytes", "producer", "r_version",
    "written_utc"
  )
  if (!identical(names(manifest), expected_columns)) {
    stop("Unexpected H05 Stage 2 manifest schema", call. = FALSE)
  }
  additions <- c(
    producer,
    paste0(
      "scripts/hypotheses/H05/",
      "finalize_h05_metric010_reconciliation.R"
    ),
    paste0(
      "scripts/hypotheses/H05/",
      "reseal_h05_gap_mder_metric010.R"
    ),
    "artifacts/08_diagnostics/H05/H05_mder_metric010_upper_tail.csv",
    "artifacts/08_diagnostics/H05/H05_mder_metric010_upper_tail_summary.csv",
    "artifacts/08_diagnostics/H05/H05_mder_metric010_influence_refits.csv",
    paste0(
      "artifacts/08_diagnostics/H05/",
      "H05_mder_metric010_gap_influence_refits.csv"
    ),
    paste0(
      "artifacts/09_tables/H05/",
      "H05_mder_metric010_gap_paired_placement_comparison.csv"
    ),
    paste0(
      "artifacts/11_source_data/H05/",
      "H05_mder_metric010_gap_paired_placement_comparison.csv"
    ),
    "artifacts/12_manifests/H05/H05_metric010_reconciliation.csv",
    paste0(
      "artifacts/12_manifests/H05/",
      "H05_metric010_gap_reseal_reconciliation.csv"
    )
  )
  paths <- sort(unique(c(manifest$path, additions)))
  absolute <- file.path(root, paths)
  if (any(!file.exists(absolute))) {
    stop(
      paste0(
        "Missing H05 Stage 2 manifest path(s): ",
        paste(paths[!file.exists(absolute)], collapse = ", ")
      ),
      call. = FALSE
    )
  }
  written_utc <- format(Sys.time(), tz = "UTC", usetz = TRUE)
  refreshed <- tibble::tibble(
    path = paths,
    artifact_type = tools::file_ext(paths),
    sha256 = unname(vapply(absolute, artifact_sha256, character(1))),
    bytes = as.numeric(file.info(absolute)$size),
    producer = producer,
    r_version = as.character(getRversion()),
    written_utc = written_utc
  )
  write_csv_artifact(refreshed, manifest_path, producer = producer)
  message("H05 Stage 2 manifest refreshed for METRIC-010: ", nrow(refreshed))
  quit(save = "no", status = 0L)
}

source(file.path(root, "scripts/pipeline/multiplicity.R"))
source(file.path(root, "scripts/hypotheses/H01/h01_contract.R"))
source(file.path(root, "scripts/hypotheses/H01/h01_modeling.R"))
source(file.path(root, "scripts/hypotheses/H05/h05_contract.R"))
source(file.path(root, "scripts/hypotheses/H05/h05_modeling.R"))

options(lifecycle_verbosity = "quiet", warn = 1)

required_packages <- c(
  "dplyr", "tidyr", "purrr", "tibble", "readr", "digest", "openssl",
  "lme4", "glmmTMB", "performance", "DHARMa", "ggplot2", "scales",
  "stringr"
)
missing_packages <- required_packages[!vapply(
  required_packages,
  requireNamespace,
  logical(1),
  quietly = TRUE
)]
if (length(missing_packages) > 0L) {
  stop(
    "Missing project package(s): ",
    paste(missing_packages, collapse = ", "),
    call. = FALSE
  )
}

old_metric_id <- "mder_ratio_of_integrals"
metric_id <- "mder_mean_of_viable_ratios"

roots <- list(
  model_data = file.path(root, "artifacts/06_model_data/H05"),
  models = file.path(root, "artifacts/07_models/H05"),
  diagnostics = file.path(root, "artifacts/08_diagnostics/H05"),
  tables = file.path(root, "artifacts/09_tables/H05"),
  figures = file.path(root, "artifacts/10_figures/H05"),
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

input_contract <- h05_input_contract(root)
input_audit <- dplyr::bind_rows(lapply(names(input_contract), function(role) {
  item <- input_contract[[role]]
  paths <- c(item$path, if (!is.null(item$manifest)) item$manifest)
  expected <- c(item$sha256, if (!is.null(item$manifest_sha256)) {
    item$manifest_sha256
  })
  labels <- c(role, if (!is.null(item$manifest)) paste0(role, "_manifest"))
  dplyr::bind_rows(lapply(seq_along(paths), function(index) {
    observed <- artifact_sha256(paths[[index]])
    tibble::tibble(
      input_role = labels[[index]],
      path = h05_relative_path(paths[[index]]),
      expected_sha256 = expected[[index]],
      observed_sha256 = observed,
      hash_verified = identical(observed, expected[[index]])
    )
  }))
}))
if (any(!input_audit$hash_verified)) {
  failed <- input_audit$path[!input_audit$hash_verified]
  stop(
    "A METRIC-010 input differs from its H05 pin: ",
    paste(failed, collapse = ", "),
    call. = FALSE
  )
}

objects <- list(
  main = readRDS(input_contract$main$path),
  manuscript_prepared_data = readRDS(
    input_contract$manuscript_prepared_data$path
  )
)
leba <- readRDS(input_contract$leba$path)
site_registry <- readr::read_csv(
  file.path(root, "config/site_display_registry.csv"),
  show_col_types = FALSE
) |>
  dplyr::arrange(.data$display_order)
site_levels <- site_registry$site

factor_registry <- h05_factor_registry()
metric_registry <- h05_metric_registry(objects$main$metric_contract)
run_registry <- h05_run_registry()
h05_validate_contract(metric_registry, factor_registry, run_registry)
spec <- metric_registry |>
  dplyr::filter(.data$metric_id == .env$metric_id)
if (nrow(spec) != 1L || spec$metric_order != 17L) {
  stop("METRIC-010 did not resolve to H05 metric 17", call. = FALSE)
}

metric_contract_comparison <- tibble::tibble(
  field = intersect(
    names(objects$main$metric_contract),
    names(objects$manuscript_prepared_data$metric_contract)
  )
) |>
  dplyr::rowwise() |>
  dplyr::mutate(
    identical = isTRUE(all.equal(
      objects$main$metric_contract[[.data$field]],
      objects$manuscript_prepared_data$metric_contract[[.data$field]],
      check.attributes = TRUE
    )),
    differing_rows = paste(
      which(!vapply(
        seq_len(nrow(objects$main$metric_contract)),
        function(index) {
          isTRUE(all.equal(
            objects$main$metric_contract[[.data$field]][[index]],
            objects$manuscript_prepared_data$metric_contract[[.data$field]][[index]],
            check.attributes = TRUE
          ))
        },
        logical(1)
      )),
      collapse = ";"
    )
  ) |>
  dplyr::ungroup()

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
  gap = file.path(
    roots$tables,
    "H05_manuscript_prepared_comparison.csv"
  ),
  v0 = file.path(roots$tables, "H05_v0_reproduction.csv"),
  v0_to_new = file.path(roots$tables, "H05_v0_to_new_comparison.csv"),
  diagnostic_plot = file.path(
    roots$source_data,
    "H05_primary_diagnostic_plot_data.csv"
  )
)
baseline_sha256 <- unname(vapply(
  artifact_paths,
  artifact_sha256,
  character(1)
))
baseline <- lapply(artifact_paths, read_h05_csv)
frame_archive_path <- file.path(roots$model_data, "H05_model_frames.rds")
model_archive_path <- file.path(
  roots$models,
  "H05_inferential_model_objects.rds"
)
baseline_frame_archive_sha <- artifact_sha256(frame_archive_path)
baseline_model_archive_sha <- artifact_sha256(model_archive_path)
frame_archive <- readRDS(frame_archive_path)
model_archive <- readRDS(model_archive_path)

if (
  sum(frame_archive$metric_registry$metric_id == old_metric_id) != 1L ||
    any(frame_archive$metric_registry$metric_id == metric_id) ||
    sum(grepl(old_metric_id, names(frame_archive$model_frames), fixed = TRUE)) != 8L ||
    sum(grepl(old_metric_id, names(model_archive), fixed = TRUE)) != 12L
) {
  stop("The accepted H05 baseline is not the expected pre-METRIC-010 archive", call. = FALSE)
}

identity_row <- function(run, metric_spec, factor_row) {
  tibble::tibble(
    run_id = run$run_id,
    data_scenario_id = run$data_scenario_id,
    placement = run$placement,
    sample_scenario = run$sample_scenario,
    analytical_role = run$analytical_role,
    family_id = run$family_id,
    inferential_family = run$inferential_family,
    family_n = run$family_n,
    metric_order = metric_spec$metric_order,
    metric_id = metric_spec$metric_id,
    manuscript_name = metric_spec$manuscript_name,
    analysis_unit = metric_spec$analysis_unit,
    response_family = metric_spec$response_family,
    response_transform = metric_spec$response_transform,
    effect_scale = metric_spec$effect_scale,
    factor_order = factor_row$factor_order,
    factor_id = factor_row$factor_id,
    factor_label = factor_row$factor_label
  )
}

bind_identity <- function(identity, data) {
  dplyr::bind_cols(identity[rep(1L, nrow(data)), , drop = FALSE], data)
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
prepared_cache <- list()
factor_cache <- list()
bundle_cache <- list()
upper_tail_rows <- list()
upper_tail_summary <- list()

for (run_index in seq_len(nrow(run_registry))) {
  run <- run_registry[run_index, , drop = FALSE]
  object <- objects[[run$data_scenario_id]]
  message("METRIC-010 H05 run ", run_index, "/8: ", run$run_id)
  prepared <- h05_prepare_metric_rows(
    object,
    spec,
    placement = run$placement,
    sample_scenario = run$sample_scenario,
    leba = leba,
    site_levels = site_levels
  )
  prepared_cache[[run$run_id]] <- prepared
  frame_key <- paste(run$run_id, metric_id, sep = "::")
  new_frames[[frame_key]] <- prepared$rows |>
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

  values <- prepared$rows$value
  quantiles <- stats::quantile(
    values,
    probs = c(0, 0.25, 0.5, 0.75, 0.95, 0.99, 1),
    names = FALSE,
    type = 7
  )
  outer_fence <- quantiles[[4L]] + 3 * stats::IQR(values, type = 7)
  summary_row <- tibble::tibble(
    run_id = run$run_id,
    data_scenario_id = run$data_scenario_id,
    placement = run$placement,
    sample_scenario = run$sample_scenario,
    observations = length(values),
    participants = dplyr::n_distinct(prepared$rows$participant_key),
    sites = nlevels(prepared$rows$site),
    minimum = quantiles[[1L]],
    q1 = quantiles[[2L]],
    median = quantiles[[3L]],
    q3 = quantiles[[4L]],
    p95 = quantiles[[5L]],
    p99 = quantiles[[6L]],
    maximum = quantiles[[7L]],
    iqr = stats::IQR(values, type = 7),
    tukey_outer_fence = outer_fence,
    outer_tail_days = sum(values > outer_fence),
    outer_tail_participants = dplyr::n_distinct(
      prepared$rows$participant_key[values > outer_fence]
    ),
    screening_role = paste0(
      "Tukey Q3 + 3*IQR is a diagnostic screen only; no automatic exclusion"
    )
  )
  upper_tail_summary[[run_index]] <- summary_row
  upper_tail_rows[[run_index]] <- prepared$rows |>
    dplyr::transmute(
      run_id = run$run_id,
      data_scenario_id = run$data_scenario_id,
      placement = run$placement,
      sample_scenario = run$sample_scenario,
      participant_key = as.character(.data$participant_key),
      site = as.character(.data$site),
      Id = .data$Id,
      local_date = .data$local_date,
      mder = .data$value,
      viable_minutes = .data$metric_support_valid_minutes,
      expected_minutes = .data$metric_support_expected_minutes,
      tukey_outer_fence = outer_fence,
      outer_tail_flag = .data$value > outer_fence
    ) |>
    dplyr::arrange(dplyr::desc(.data$mder)) |>
    dplyr::mutate(upper_tail_rank = dplyr::row_number())

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
        family_observed_tests = if (run$inferential_family) 68L else NA_integer_,
        family_rank = NA_integer_
      )
    seed <- as.integer(
      500000L + run_index * 10000L + 17L * 100L + factor_index
    )
    diagnostics <- h05_diagnostic_summary(bundle, frame, seed = seed)
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
      model_key <- paste(run$run_id, metric_id, factor_row$factor_id, sep = "::")
      new_models[[model_key]] <- bundle
    }

    main_all_available <- run$data_scenario_id == "main" &&
      run$sample_scenario == "all_available"
    if (main_all_available) {
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

    primary_run <- run$data_scenario_id == "main" &&
      run$placement == "glasses" &&
      run$sample_scenario == "all_available"
    if (primary_run) {
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
upper_tail_rows <- dplyr::bind_rows(upper_tail_rows)
upper_tail_summary <- dplyr::bind_rows(upper_tail_summary)

expected_counts <- c(
  effects = 32L,
  tests = 32L,
  diagnostics = 32L,
  samples = 32L,
  model_manifest = 96L,
  random_site = 8L,
  loo = 36L,
  influence = 96L,
  spearman = 32L,
  site_spearman = 68L,
  loo_spearman = 68L,
  diagnostic_plot = 5616L
)
observed_counts <- vapply(new_results[names(expected_counts)], nrow, integer(1))
if (!identical(observed_counts, expected_counts)) {
  stop("The bounded MDER result dimensions differ from contract", call. = FALSE)
}

sample_check <- new_results$samples |>
  dplyr::distinct(
    .data$run_id,
    .data$observations,
    .data$participants,
    .data$participant_days,
    .data$sites
  ) |>
  dplyr::arrange(match(.data$run_id, run_registry$run_id))
expected_samples <- tibble::tribble(
  ~run_id, ~observations, ~participants, ~participant_days, ~sites,
  "main__chest__all_available", 732L, 152L, 732L, 8L,
  "main__chest__paired_common_sample", 489L, 107L, 489L, 8L,
  "main__glasses__all_available", 702L, 137L, 702L, 9L,
  "main__glasses__paired_common_sample", 489L, 107L, 489L, 8L,
  "manuscript_prepared_data__chest__all_available", 723L, 152L, 723L, 8L,
  "manuscript_prepared_data__chest__paired_common_sample", 478L, 107L, 478L, 8L,
  "manuscript_prepared_data__glasses__all_available", 687L, 137L, 687L, 9L,
  "manuscript_prepared_data__glasses__paired_common_sample", 478L, 107L, 478L, 8L
) |>
  dplyr::arrange(match(.data$run_id, run_registry$run_id))
if (!isTRUE(all.equal(sample_check, expected_samples, check.attributes = FALSE))) {
  stop("The MDER fitted samples differ from the verified METRIC-010 counts", call. = FALSE)
}

align_to_baseline <- function(new, base) {
  missing <- setdiff(names(base), names(new))
  if (length(missing) > 0L) {
    stop("Replacement rows are missing column(s): ", paste(missing, collapse = ", "))
  }
  new <- new[names(base)]
  for (name in names(base)) {
    if (is.logical(base[[name]]) && all(is.na(new[[name]]))) {
      new[[name]] <- rep(NA, nrow(new))
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

replace_metric_rows <- function(base, replacement) {
  replacement <- align_to_baseline(replacement, base)
  dplyr::bind_rows(
    base[!base$metric_id %in% c(old_metric_id, metric_id), , drop = FALSE],
    replacement
  )
}

replace_fields_by_key <- function(base, updates, keys, fields) {
  base_key <- do.call(paste, c(base[keys], sep = "\r"))
  update_key <- do.call(paste, c(updates[keys], sep = "\r"))
  index <- match(base_key, update_key)
  if (anyNA(index)) {
    stop("A field-only update did not match every inherited row", call. = FALSE)
  }
  for (field in fields) {
    base[[field]] <- updates[[field]][index]
  }
  base
}

effects <- replace_metric_rows(baseline$effects, new_results$effects) |>
  dplyr::arrange(
    match(.data$run_id, run_registry$run_id),
    .data$metric_order,
    .data$factor_order
  )
samples <- replace_metric_rows(baseline$frames, new_results$samples) |>
  dplyr::arrange(
    match(.data$run_id, run_registry$run_id),
    .data$metric_order,
    .data$factor_order
  )
diagnostics <- replace_metric_rows(
  baseline$diagnostics,
  new_results$diagnostics
) |>
  dplyr::arrange(
    match(.data$run_id, run_registry$run_id),
    .data$metric_order,
    .data$factor_order
  )
tests <- replace_metric_rows(baseline$tests, new_results$tests) |>
  dplyr::arrange(
    match(.data$run_id, run_registry$run_id),
    .data$metric_order,
    .data$factor_order
  )

inferential_tests <- tests |>
  dplyr::filter(.data$inferential_family) |>
  dplyr::select(-.data$p_adjusted, -.data$family_observed_tests, -.data$family_rank) |>
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
noninferential_tests <- tests |>
  dplyr::filter(!.data$inferential_family) |>
  dplyr::mutate(
    family_instance_id = NA_character_,
    p_adjusted = NA_real_,
    family_observed_tests = NA_integer_,
    family_rank = NA_integer_
  )
computed_tests <- dplyr::bind_rows(inferential_tests, noninferential_tests) |>
  dplyr::select(dplyr::all_of(names(baseline$tests))) |>
  dplyr::arrange(
    match(.data$run_id, run_registry$run_id),
    .data$metric_order,
    .data$factor_order
  )
inherited_tests <- baseline$tests |>
  dplyr::filter(!.data$metric_id %in% c(.env$old_metric_id, .env$metric_id))
inherited_tests <- replace_fields_by_key(
  inherited_tests,
  computed_tests |>
    dplyr::filter(!.data$metric_id %in% c(.env$old_metric_id, .env$metric_id)),
  keys = c("run_id", "metric_id", "factor_id"),
  fields = c("p_adjusted", "family_rank")
)
tests <- dplyr::bind_rows(
  inherited_tests,
  computed_tests |>
    dplyr::filter(.data$metric_id == .env$metric_id)
) |>
  dplyr::arrange(
    match(.data$run_id, run_registry$run_id),
    .data$metric_order,
    .data$factor_order
  )

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
    any(!family_audit$vector_bh_verified) ||
    any(family_audit$passes_bh_0_05 != 0L)
) {
  stop("The refreshed complete-family BH audit failed", call. = FALSE)
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
inherited_master <- baseline$master |>
  dplyr::filter(!.data$metric_id %in% c(.env$old_metric_id, .env$metric_id))
inherited_master <- replace_fields_by_key(
  inherited_master,
  computed_master |>
    dplyr::filter(!.data$metric_id %in% c(.env$old_metric_id, .env$metric_id)),
  keys = c("run_id", "metric_id", "factor_id"),
  fields = c("p_adjusted", "family_rank")
)
master <- dplyr::bind_rows(
  inherited_master,
  computed_master |>
    dplyr::filter(.data$metric_id == .env$metric_id)
) |>
  dplyr::arrange(
    match(.data$run_id, run_registry$run_id),
    .data$metric_order,
    .data$factor_order
  )

model_manifest <- replace_metric_rows(
  baseline$model_manifest,
  new_results$model_manifest
) |>
  dplyr::arrange(
    match(.data$run_id, run_registry$run_id),
    .data$metric_order,
    .data$factor_order,
    match(.data$model_name, c("comparison_full", "comparison_reduced", "final_full"))
  )
influence <- replace_metric_rows(baseline$influence, new_results$influence) |>
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
    estimate_change_random_minus_fixed =
      .data$estimate_model_per_point - .data$fixed_estimate_model_per_point,
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
      abs(.data$estimate_change_random_minus_fixed /
        .data$fixed_estimate_model_per_point),
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
random_site <- replace_metric_rows(baseline$random_site, new_random_site) |>
  dplyr::arrange(
    match(.data$run_id, run_registry$run_id),
    .data$metric_order,
    .data$factor_order
  )

loo <- replace_metric_rows(baseline$loo, new_results$loo) |>
  dplyr::arrange(
    .data$metric_order,
    .data$factor_order,
    match(.data$omitted_site, site_levels)
  )
new_loo_summary <- loo |>
  dplyr::filter(.data$metric_id == .env$metric_id) |>
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
loo_summary <- replace_metric_rows(baseline$loo_summary, new_loo_summary) |>
  dplyr::arrange(.data$metric_order, .data$factor_order)

spearman <- replace_metric_rows(baseline$spearman, new_results$spearman) |>
  dplyr::arrange(
    match(.data$run_id, run_registry$run_id),
    .data$metric_order,
    .data$factor_order
  )
site_spearman <- replace_metric_rows(
  baseline$site_spearman,
  new_results$site_spearman
) |>
  dplyr::arrange(
    match(.data$run_id, run_registry$run_id),
    .data$metric_order,
    .data$factor_order,
    match(.data$site, site_levels)
  )
loo_spearman <- replace_metric_rows(
  baseline$loo_spearman,
  new_results$loo_spearman
) |>
  dplyr::arrange(
    match(.data$run_id, run_registry$run_id),
    .data$metric_order,
    .data$factor_order,
    match(.data$omitted_site, site_levels)
  )
diagnostic_plot <- replace_metric_rows(
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
    .data$data_scenario_id == "main",
    .data$sample_scenario == "paired_common_sample"
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
    estimate_difference_chest_minus_near_eye =
      .data$estimate_model_per_sd__chest -
      .data$estimate_model_per_sd__glasses,
    sign_concordant = dplyr::if_else(
      is.finite(.data$estimate_model_per_sd__chest) &
        is.finite(.data$estimate_model_per_sd__glasses),
      sign(.data$estimate_model_per_sd__chest) ==
        sign(.data$estimate_model_per_sd__glasses),
      NA
    ),
    component_intervals_overlap =
      .data$conf_low_model_per_sd__chest <=
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
  dplyr::select(dplyr::all_of(names(baseline$paired))) |>
  dplyr::arrange(.data$metric_order, .data$factor_order)
paired <- replace_metric_rows(
  baseline$paired,
  computed_paired |>
    dplyr::filter(.data$metric_id == .env$metric_id)
) |>
  dplyr::arrange(.data$metric_order, .data$factor_order)

computed_gap_comparison <- effects |>
  dplyr::filter(
    .data$placement == "glasses",
    .data$sample_scenario == "all_available",
    .data$data_scenario_id %in% c("main", "manuscript_prepared_data")
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
    estimate_difference_mpd_minus_main =
      .data$estimate_model_per_sd__manuscript_prepared_data -
      .data$estimate_model_per_sd__main,
    sign_concordant = sign(
      .data$estimate_model_per_sd__manuscript_prepared_data
    ) == sign(.data$estimate_model_per_sd__main),
    component_intervals_overlap =
      .data$conf_low_model_per_sd__manuscript_prepared_data <=
        .data$conf_high_model_per_sd__main &
      .data$conf_low_model_per_sd__main <=
        .data$conf_high_model_per_sd__manuscript_prepared_data
  ) |>
  dplyr::select(dplyr::all_of(names(baseline$gap))) |>
  dplyr::arrange(.data$metric_order, .data$factor_order)
gap_comparison <- replace_metric_rows(
  baseline$gap,
  computed_gap_comparison |>
    dplyr::filter(.data$metric_id == .env$metric_id)
) |>
  dplyr::arrange(.data$metric_order, .data$factor_order)

v0 <- baseline$v0 |>
  dplyr::mutate(
    metric_id_current = dplyr::if_else(
      .data$metric_id_current == .env$old_metric_id,
      .env$metric_id,
      .data$metric_id_current
    )
  )
computed_v0_to_new <- v0 |>
  dplyr::filter(.data$placement == "near-eye") |>
  dplyr::left_join(
    spearman |>
      dplyr::filter(
        .data$data_scenario_id == "main",
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
        .data$data_scenario_id == "main",
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
  dplyr::select(dplyr::all_of(names(baseline$v0_to_new)))
inherited_v0_to_new <- baseline$v0_to_new |>
  dplyr::filter(
    !.data$metric_id_current %in% c(.env$old_metric_id, .env$metric_id)
  )
inherited_v0_to_new <- replace_fields_by_key(
  inherited_v0_to_new,
  computed_v0_to_new |>
    dplyr::filter(
      !.data$metric_id_current %in% c(.env$old_metric_id, .env$metric_id)
    ),
  keys = c("metric_id_current", "factor_id"),
  fields = c("fixed_site_p_adjusted", "primary_bh_flag")
)
v0_to_new <- dplyr::bind_rows(
  inherited_v0_to_new,
  computed_v0_to_new |>
    dplyr::filter(.data$metric_id_current == .env$metric_id)
) |>
  dplyr::arrange(.data$v0_plot_order, .data$factor_order)

primary <- master |>
  dplyr::filter(.data$run_id == "main__glasses__all_available")
primary_highlights <- primary |>
  dplyr::filter(.data$p_adjusted <= 0.05) |>
  dplyr::arrange(.data$p_adjusted)

# New-estimand upper-tail and influence sensitivity. The outer-fence rule is
# diagnostic only. Each screened day is deleted singly, and each owner/top-
# residual participant is deleted singly; no row is removed from the primary
# analysis and no p-value family is formed from these diagnostic refits.
influence_refits <- list()
influence_index <- 1L
for (run_id in c(
  "main__glasses__all_available",
  "main__chest__all_available"
)) {
  prepared <- prepared_cache[[run_id]]
  outer <- upper_tail_rows |>
    dplyr::filter(.data$run_id == .env$run_id, .data$outer_tail_flag)
  for (factor_index in seq_len(nrow(factor_registry))) {
    factor_row <- factor_registry[factor_index, , drop = FALSE]
    cache_key <- paste(run_id, factor_row$factor_id, sep = "::")
    full_frame <- factor_cache[[cache_key]]$frame
    full_effect <- h05_effect_summary(
      bundle_cache[[cache_key]]$final$model,
      spec,
      factor_cache[[cache_key]]$scaling$leba_participant_sd
    )
    residual_candidates <- new_results$influence |>
      dplyr::filter(
        .data$run_id == .env$run_id,
        .data$factor_id == factor_row$factor_id
      ) |>
      dplyr::transmute(
        deletion_level = "participant",
        candidate_id = .data$participant_key,
        participant_key = .data$participant_key,
        local_date = as.Date(NA),
        candidate_reason = paste0(
          "top_",
          .data$screen_rank,
          "_maximum_absolute_pearson_residual"
        ),
        screen_score = .data$influence_score,
        mder = NA_real_
      )
    outer_participants <- outer |>
      dplyr::transmute(
        deletion_level = "participant",
        candidate_id = .data$participant_key,
        participant_key = .data$participant_key,
        local_date = as.Date(NA),
        candidate_reason = "owns_METRIC-010_Tukey_outer-tail_day",
        screen_score = NA_real_,
        mder = .data$mder
      )
    outer_days <- outer |>
      dplyr::transmute(
        deletion_level = "participant_day",
        candidate_id = paste(.data$participant_key, .data$local_date, sep = "::"),
        participant_key = .data$participant_key,
        local_date = .data$local_date,
        candidate_reason = "METRIC-010_Tukey_outer-tail_day",
        screen_score = NA_real_,
        mder = .data$mder
      )
    candidates <- dplyr::bind_rows(
      residual_candidates,
      outer_participants,
      outer_days
    ) |>
      dplyr::group_by(.data$deletion_level, .data$candidate_id) |>
      dplyr::summarise(
        participant_key = dplyr::first(.data$participant_key),
        local_date = dplyr::first(.data$local_date),
        candidate_reason = paste(unique(.data$candidate_reason), collapse = ";"),
        screen_score = suppressWarnings(max(.data$screen_score, na.rm = TRUE)),
        mder = suppressWarnings(max(.data$mder, na.rm = TRUE)),
        .groups = "drop"
      ) |>
      dplyr::mutate(
        screen_score = dplyr::if_else(
          is.infinite(.data$screen_score),
          NA_real_,
          .data$screen_score
        ),
        mder = dplyr::if_else(is.infinite(.data$mder), NA_real_, .data$mder)
      )

    for (candidate_index in seq_len(nrow(candidates))) {
      candidate <- candidates[candidate_index, , drop = FALSE]
      keep <- if (candidate$deletion_level == "participant") {
        as.character(prepared$rows$participant_key) != candidate$participant_key
      } else {
        !(
          as.character(prepared$rows$participant_key) ==
            candidate$participant_key &
            prepared$rows$local_date == candidate$local_date
        )
      }
      sensitivity_factor <- h05_add_factor_to_frame(
        prepared$rows[keep, , drop = FALSE],
        spec,
        factor_row
      )
      sensitivity_bundle <- h05_fit_bundle(
        sensitivity_factor$frame,
        spec,
        inferential = FALSE
      )
      sensitivity_effect <- h05_effect_summary(
        sensitivity_bundle$final$model,
        spec,
        sensitivity_factor$scaling$leba_participant_sd
      )
      change <- sensitivity_effect$estimate_model_per_point -
        full_effect$estimate_model_per_point
      influence_refits[[influence_index]] <- tibble::tibble(
        run_id = run_id,
        placement = if (grepl("glasses", run_id)) "glasses" else "chest",
        factor_order = factor_row$factor_order,
        factor_id = factor_row$factor_id,
        factor_label = factor_row$factor_label,
        deletion_level = candidate$deletion_level,
        candidate_id = candidate$candidate_id,
        participant_key = candidate$participant_key,
        local_date = candidate$local_date,
        candidate_reason = candidate$candidate_reason,
        screen_score = candidate$screen_score,
        screened_mder = candidate$mder,
        observations_removed = nrow(full_frame) - nrow(sensitivity_factor$frame),
        participants_removed = dplyr::n_distinct(full_frame$participant_key) -
          dplyr::n_distinct(sensitivity_factor$frame$participant_key),
        full_estimate_per_point = full_effect$estimate_model_per_point,
        full_standard_error_per_point = full_effect$std_error_model_per_point,
        full_estimate_per_sd = full_effect$estimate_model_per_sd,
        sensitivity_estimate_per_point =
          sensitivity_effect$estimate_model_per_point,
        sensitivity_conf_low_per_point =
          sensitivity_effect$conf_low_model_per_point,
        sensitivity_conf_high_per_point =
          sensitivity_effect$conf_high_model_per_point,
        sensitivity_estimate_per_sd = sensitivity_effect$estimate_model_per_sd,
        absolute_change_per_point = abs(change),
        change_in_full_standard_errors = abs(change) /
          full_effect$std_error_model_per_point,
        sign_reversal = sign(sensitivity_effect$estimate_model_per_point) !=
          sign(full_effect$estimate_model_per_point),
        sensitivity_interval_contains_zero =
          sensitivity_effect$conf_low_model_per_point <= 0 &
          sensitivity_effect$conf_high_model_per_point >= 0,
        refit_status = if (
          !is.null(sensitivity_bundle$final$model) &&
            isTRUE(h01_model_fit_status(
              sensitivity_bundle$final$model
            )$converged)
        ) {
          "PASS"
        } else {
          "UNSTABLE_OR_NON_ESTIMABLE"
        }
      )
      influence_index <- influence_index + 1L
    }
  }
}
influence_refits <- dplyr::bind_rows(influence_refits) |>
  dplyr::arrange(
    .data$placement,
    .data$factor_order,
    .data$deletion_level,
    .data$candidate_id
  )
if (nrow(influence_refits) == 0L || any(influence_refits$refit_status != "PASS")) {
  stop("The current-estimand MDER influence refits did not all pass", call. = FALSE)
}

canonical_digest <- function(data, drop = character()) {
  data <- data[, setdiff(names(data), drop), drop = FALSE]
  keys <- intersect(
    c(
      "run_id", "data_scenario_id", "placement", "sample_scenario",
      "metric_order", "metric_id", "factor_order", "factor_id",
      "model_name", "omitted_site", "site", "panel", "model_row_id",
      "participant_key", "screen_rank", "v0_plot_order", "v0_order"
    ),
    names(data)
  )
  if (length(keys) > 0L && nrow(data) > 1L) {
    ordering <- do.call(
      order,
      c(lapply(data[keys], function(value) as.character(value)), list(na.last = TRUE))
    )
    data <- data[ordering, , drop = FALSE]
  }
  data <- as.data.frame(data, stringsAsFactors = FALSE)
  row.names(data) <- NULL
  digest::digest(data, algo = "sha256", serialize = TRUE)
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
reconciliation <- dplyr::bind_rows(lapply(names(comparison_objects), function(name) {
  before <- baseline[[name]]
  after <- comparison_objects[[name]]
  id_column <- if (name %in% c("v0", "v0_to_new")) {
    "metric_id_current"
  } else {
    "metric_id"
  }
  before_non_mder <- before[
    !before[[id_column]] %in% c(old_metric_id, metric_id),
    ,
    drop = FALSE
  ]
  after_non_mder <- after[
    !after[[id_column]] %in% c(old_metric_id, metric_id),
    ,
    drop = FALSE
  ]
  dropped <- allowed_derived[[name]]
  if (is.null(dropped)) dropped <- character()
  before_digest <- canonical_digest(before_non_mder, drop = dropped)
  after_digest <- canonical_digest(after_non_mder, drop = dropped)
  tibble::tibble(
    artifact_id = name,
    baseline_path = h05_relative_path(artifact_paths[[name]]),
    baseline_file_sha256 = baseline_sha256[[match(name, names(artifact_paths))]],
    invariant_scope = "all non-MDER fields except declared BH-derived fields",
    allowed_derived_fields = paste(dropped, collapse = ";"),
    baseline_non_mder_digest = before_digest,
    updated_non_mder_digest = after_digest,
    invariant_verified = identical(before_digest, after_digest),
    non_mder_rows = nrow(after_non_mder)
  )
}))
if (any(!reconciliation$invariant_verified)) {
  failed <- reconciliation$artifact_id[!reconciliation$invariant_verified]
  stop(
    "A non-MDER scientific artifact changed outside the BH allowance: ",
    paste(failed, collapse = ", "),
    call. = FALSE
  )
}

frame_names_non_mder <- names(frame_archive$model_frames)[
  !grepl(old_metric_id, names(frame_archive$model_frames), fixed = TRUE)
]
model_names_non_mder <- names(model_archive)[
  !grepl(old_metric_id, names(model_archive), fixed = TRUE)
]
frame_object_digest <- digest::digest(
  frame_archive$model_frames[frame_names_non_mder],
  algo = "sha256",
  serialize = TRUE
)
model_object_digest <- digest::digest(
  model_archive[model_names_non_mder],
  algo = "sha256",
  serialize = TRUE
)

old_frame_names <- names(frame_archive$model_frames)
for (index in which(grepl(old_metric_id, old_frame_names, fixed = TRUE))) {
  new_name <- sub(old_metric_id, metric_id, old_frame_names[[index]], fixed = TRUE)
  frame_archive$model_frames[[index]] <- new_frames[[new_name]]
  names(frame_archive$model_frames)[[index]] <- new_name
}
old_model_names <- names(model_archive)
for (index in which(grepl(old_metric_id, old_model_names, fixed = TRUE))) {
  new_name <- sub(old_metric_id, metric_id, old_model_names[[index]], fixed = TRUE)
  model_archive[[index]] <- new_models[[new_name]]
  names(model_archive)[[index]] <- new_name
}
frame_archive$input_contract <- input_contract
frame_archive$metric_registry <- metric_registry
frame_archive$status <- "metric010_mder_slice_refreshed"
frame_archive$metadata$mder_estimand <- paste0(
  "arithmetic mean of finite strictly-positive one-minute melEDI/illuminance ",
  "ratios; retained at >=720 viable minutes on the 1440-minute local grid"
)
frame_archive$metadata$mder_decision_id <- "METRIC-010"

if (
  !identical(
    frame_object_digest,
    digest::digest(
      frame_archive$model_frames[frame_names_non_mder],
      algo = "sha256",
      serialize = TRUE
    )
  ) ||
    !identical(
      model_object_digest,
      digest::digest(
        model_archive[model_names_non_mder],
        algo = "sha256",
        serialize = TRUE
      )
    )
) {
  stop("A non-MDER stored frame or fitted object changed", call. = FALSE)
}

reconciliation <- dplyr::bind_rows(
  reconciliation,
  tibble::tibble(
    artifact_id = c("model_frame_objects", "inferential_model_objects"),
    baseline_path = c(
      h05_relative_path(frame_archive_path),
      h05_relative_path(model_archive_path)
    ),
    baseline_file_sha256 = c(
      baseline_frame_archive_sha,
      baseline_model_archive_sha
    ),
    invariant_scope = c(
      "all 128 non-MDER model-frame objects",
      "all 192 non-MDER inferential model bundles"
    ),
    allowed_derived_fields = "",
    baseline_non_mder_digest = c(frame_object_digest, model_object_digest),
    updated_non_mder_digest = c(frame_object_digest, model_object_digest),
    invariant_verified = TRUE,
    non_mder_rows = c(length(frame_names_non_mder), length(model_names_non_mder))
  )
)

before_non_mder_bh <- baseline$tests |>
  dplyr::filter(
    .data$inferential_family,
    !.data$metric_id %in% c(.env$old_metric_id, .env$metric_id)
  ) |>
  dplyr::select(
    .data$run_id,
    .data$metric_id,
    .data$factor_id,
    before_p_adjusted = .data$p_adjusted,
    before_family_rank = .data$family_rank
  )
after_non_mder_bh <- tests |>
  dplyr::filter(
    .data$inferential_family,
    !.data$metric_id %in% c(.env$old_metric_id, .env$metric_id)
  ) |>
  dplyr::select(
    .data$run_id,
    .data$metric_id,
    .data$factor_id,
    after_p_adjusted = .data$p_adjusted,
    after_family_rank = .data$family_rank
  )
bh_change_audit <- dplyr::inner_join(
  before_non_mder_bh,
  after_non_mder_bh,
  by = c("run_id", "metric_id", "factor_id"),
  relationship = "one-to-one"
) |>
  dplyr::summarise(
    artifact_id = "complete_family_BH_derived_update",
    baseline_path = h05_relative_path(artifact_paths[["tests"]]),
    baseline_file_sha256 = baseline_sha256[[match("tests", names(artifact_paths))]],
    invariant_scope = "non-MDER raw tests unchanged; BH values may update",
    allowed_derived_fields = "p_adjusted;family_rank",
    baseline_non_mder_digest = canonical_digest(
      before_non_mder_bh,
      drop = c("before_p_adjusted", "before_family_rank")
    ),
    updated_non_mder_digest = canonical_digest(
      after_non_mder_bh,
      drop = c("after_p_adjusted", "after_family_rank")
    ),
    invariant_verified = identical(
      canonical_digest(
        before_non_mder_bh,
        drop = c("before_p_adjusted", "before_family_rank")
      ),
      canonical_digest(
        after_non_mder_bh,
        drop = c("after_p_adjusted", "after_family_rank")
      )
    ),
    non_mder_rows = dplyr::n(),
    adjusted_p_rows_changed = sum(
      abs(.data$before_p_adjusted - .data$after_p_adjusted) > 1e-15
    ),
    family_rank_rows_changed = sum(
      .data$before_family_rank != .data$after_family_rank
    )
  )
reconciliation$adjusted_p_rows_changed <- NA_integer_
reconciliation$family_rank_rows_changed <- NA_integer_
reconciliation <- dplyr::bind_rows(reconciliation, bh_change_audit)

paired_near_samples <- master |>
  dplyr::filter(.data$run_id == "main__glasses__paired_common_sample") |>
  dplyr::select(dplyr::all_of(c(
    "metric_id", "factor_id", "analysis_unit", "observations",
    "participants", "participant_days", "represented_days", "sites",
    "model_frame_hash"
  ))) |>
  dplyr::distinct() |>
  dplyr::rename(
    analysis_unit__near_eye = "analysis_unit",
    observations__near_eye = "observations",
    participants__near_eye = "participants",
    participant_days__near_eye = "participant_days",
    represented_days__near_eye = "represented_days",
    sites__near_eye = "sites",
    model_frame_hash__near_eye = "model_frame_hash"
  )
paired_chest_samples <- master |>
  dplyr::filter(.data$run_id == "main__chest__paired_common_sample") |>
  dplyr::select(dplyr::all_of(c(
    "metric_id", "factor_id", "analysis_unit", "observations",
    "participants", "participant_days", "represented_days", "sites",
    "model_frame_hash"
  ))) |>
  dplyr::distinct() |>
  dplyr::rename(
    analysis_unit__chest = "analysis_unit",
    observations__chest = "observations",
    participants__chest = "participants",
    participant_days__chest = "participant_days",
    represented_days__chest = "represented_days",
    sites__chest = "sites",
    model_frame_hash__chest = "model_frame_hash"
  )
paired_display <- paired |>
  dplyr::left_join(
    paired_near_samples,
    by = c("metric_id", "factor_id"),
    relationship = "many-to-one"
  ) |>
  dplyr::left_join(
    paired_chest_samples,
    by = c("metric_id", "factor_id"),
    relationship = "many-to-one"
  ) |>
  dplyr::mutate(
    comparison_scale = paste(
      "Model-scale coefficient per participant SD of the matched LEBA factor;",
      "near eye on x and chest on y; null = 0"
    ),
    exact_sample_match =
      .data$observations__near_eye == .data$observations__chest &
      .data$participants__near_eye == .data$participants__chest &
      dplyr::coalesce(
        .data$participant_days__near_eye == .data$participant_days__chest,
        is.na(.data$participant_days__near_eye) &
          is.na(.data$participant_days__chest)
      ) &
      .data$sites__near_eye == .data$sites__chest
  )
if (
  nrow(paired_display) != 68L ||
    any(!paired_display$exact_sample_match) ||
    min(paired_display$participants__near_eye) != 107L ||
    max(paired_display$participants__near_eye) != 112L ||
    min(paired_display$participant_days__near_eye, na.rm = TRUE) != 489L ||
    max(paired_display$participant_days__near_eye, na.rm = TRUE) != 643L
) {
  stop("The refreshed exact paired display sample is invalid", call. = FALSE)
}

# All scientific objects are validated before installation.
write_h05_csv(input_audit, file.path(roots$model_data, "H05_input_audit.csv"))
write_h05_csv(metric_registry, file.path(roots$model_data, "H05_metric_registry.csv"))
write_h05_csv(
  metric_contract_comparison,
  file.path(roots$model_data, "H05_input_metric_contract_comparison.csv")
)
write_h05_csv(samples, artifact_paths[["frames"]])
write_h05_rds(frame_archive, frame_archive_path)
write_h05_rds(model_archive, model_archive_path)
write_h05_csv(model_manifest, artifact_paths[["model_manifest"]])
write_h05_csv(effects, artifact_paths[["effects"]])
write_h05_csv(tests, artifact_paths[["tests"]])
write_h05_csv(master, artifact_paths[["master"]])
write_h05_csv(
  family_audit,
  file.path(roots$tables, "H05_family_audit.csv")
)
write_h05_csv(
  primary_highlights,
  file.path(roots$tables, "H05_primary_bh_highlights.csv")
)
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
write_h05_csv(v0, artifact_paths[["v0"]])
write_h05_csv(v0_to_new, artifact_paths[["v0_to_new"]])
write_h05_csv(diagnostic_plot, artifact_paths[["diagnostic_plot"]])
write_h05_csv(
  v0,
  file.path(roots$source_data, "H05_v0_correlation_figure_data.csv")
)
write_h05_csv(
  upper_tail_rows,
  file.path(roots$diagnostics, "H05_mder_metric010_upper_tail.csv")
)
write_h05_csv(
  upper_tail_summary,
  file.path(roots$diagnostics, "H05_mder_metric010_upper_tail_summary.csv")
)
write_h05_csv(
  influence_refits,
  file.path(roots$diagnostics, "H05_mder_metric010_influence_refits.csv")
)
write_h05_csv(
  paired_display,
  file.path(roots$source_data, "H05_paired_effect_comparison_data.csv")
)

primary_figure_data <- primary |>
  dplyr::mutate(
    metric_display = factor(
      .data$manuscript_name,
      levels = rev(unique(
        .data$manuscript_name[order(.data$metric_order)]
      ))
    ),
    factor_display = paste0(
      stringr::str_to_upper(stringr::str_remove(.data$factor_id, "leba_")),
      ": ",
      .data$factor_label
    ),
    factor_display = factor(
      .data$factor_display,
      levels = unique(.data$factor_display[order(.data$factor_order)])
    ),
    effect_label = dplyr::if_else(
      .data$effect_type %in% c("ratio", "odds_ratio"),
      sprintf("x%.2f", .data$estimate_practical_per_sd),
      sprintf("%+.2f", .data$estimate_practical_per_sd)
    ),
    q_label = ""
  )
write_h05_csv(
  primary_figure_data,
  file.path(roots$source_data, "H05_primary_effect_overview_data.csv")
)
effect_limit <- max(abs(primary_figure_data$estimate_model_per_sd), na.rm = TRUE)
primary_plot <- ggplot2::ggplot(
  primary_figure_data,
  ggplot2::aes(x = .data$factor_display, y = .data$metric_display)
) +
  ggplot2::geom_tile(
    ggplot2::aes(fill = .data$estimate_model_per_sd),
    colour = "white",
    linewidth = 0.4
  ) +
  ggplot2::geom_text(
    ggplot2::aes(label = .data$effect_label),
    size = 2.8
  ) +
  ggplot2::scale_fill_gradient2(
    low = "#3B4CC0",
    mid = "white",
    high = "#B40426",
    midpoint = 0,
    limits = c(-effect_limit, effect_limit),
    name = "Model-scale effect\nper LEBA SD"
  ) +
  ggplot2::labs(
    title = "H05 primary fixed-site effects",
    subtitle = paste0(
      "Cell text is the reader-scale effect per participant SD of LEBA; ",
      "zero of 68 associations survived BH correction"
    ),
    x = NULL,
    y = NULL
  ) +
  ggplot2::theme_minimal(base_size = 11) +
  ggplot2::theme(
    panel.grid = ggplot2::element_blank(),
    axis.text.x = ggplot2::element_text(angle = 30, hjust = 1),
    plot.title.position = "plot"
  )
ggplot2::ggsave(
  file.path(roots$figures, "H05_primary_effect_overview.png"),
  primary_plot,
  width = 11,
  height = 9,
  dpi = 300
)
ggplot2::ggsave(
  file.path(roots$figures, "H05_primary_effect_overview.pdf"),
  primary_plot,
  width = 11,
  height = 9
)

diagnostic_figure_data <- primary_figure_data
write_h05_csv(
  diagnostic_figure_data,
  file.path(roots$source_data, "H05_primary_adequacy_overview_data.csv")
)
diagnostic_plot_figure <- ggplot2::ggplot(
  diagnostic_figure_data,
  ggplot2::aes(x = .data$factor_display, y = .data$metric_display)
) +
  ggplot2::geom_tile(
    ggplot2::aes(fill = .data$model_adequacy),
    colour = "white",
    linewidth = 0.4
  ) +
  ggplot2::scale_fill_manual(
    values = c(
      acceptable = "#009E73",
      acceptable_with_specified_limitations = "#E69F00",
      not_acceptable = "#D55E00"
    ),
    labels = c(
      acceptable = "Acceptable",
      acceptable_with_specified_limitations =
        "Acceptable with specified limitations",
      not_acceptable = "Not acceptable"
    ),
    name = "Adequacy"
  ) +
  ggplot2::labs(
    title = "H05 primary model-adequacy classifications",
    subtitle = paste0(
      "Classification uses the approved fit, residual, support, and ",
      "dependence checks"
    ),
    x = NULL,
    y = NULL
  ) +
  ggplot2::theme_minimal(base_size = 11) +
  ggplot2::theme(
    panel.grid = ggplot2::element_blank(),
    axis.text.x = ggplot2::element_text(angle = 30, hjust = 1),
    plot.title.position = "plot"
  )
ggplot2::ggsave(
  file.path(roots$figures, "H05_primary_model_adequacy.png"),
  diagnostic_plot_figure,
  width = 11,
  height = 8.5,
  dpi = 300
)

paired_plot_data <- paired |>
  dplyr::mutate(
    factor_label = factor(
      .data$factor_label,
      levels = unique(.data$factor_label[order(.data$factor_order)])
    )
  )
paired_limit <- 1.08 * max(abs(c(
  paired_plot_data$estimate_model_per_sd__glasses,
  paired_plot_data$estimate_model_per_sd__chest
)), na.rm = TRUE)
paired_plot <- ggplot2::ggplot(
  paired_plot_data,
  ggplot2::aes(
    x = .data$estimate_model_per_sd__glasses,
    y = .data$estimate_model_per_sd__chest
  )
) +
  ggplot2::geom_hline(yintercept = 0, colour = "grey65", linewidth = 0.45) +
  ggplot2::geom_vline(xintercept = 0, colour = "grey65", linewidth = 0.45) +
  ggplot2::geom_abline(
    slope = 1,
    intercept = 0,
    linetype = 2,
    colour = "black",
    linewidth = 0.55
  ) +
  ggplot2::geom_point(alpha = 0.85, size = 2.1, colour = "#0072B2") +
  ggplot2::facet_wrap(~factor_label) +
  ggplot2::coord_equal(
    xlim = c(-paired_limit, paired_limit),
    ylim = c(-paired_limit, paired_limit)
  ) +
  ggplot2::labs(
    title = "Paired/common-sample near-eye and chest effects",
    subtitle = paste0(
      "Matched estimands: 107–112 participants, 489–643 participant-days, ",
      "and 8 sites"
    ),
    x = "Near-eye estimate",
    y = "Chest estimate",
    caption = paste0(
      "The dashed line is identity and grey lines mark the null. ",
      "Closeness does not establish equivalence."
    )
  ) +
  ggplot2::theme_minimal(base_size = 11) +
  ggplot2::theme(
    plot.title.position = "plot",
    plot.caption.position = "plot",
    plot.caption = ggplot2::element_text(hjust = 0)
  )
ggplot2::ggsave(
  file.path(roots$figures, "H05_paired_placement_effects.png"),
  paired_plot,
  width = 10,
  height = 7.5,
  dpi = 300
)

environment <- tibble::tibble(
  component = c("R", required_packages),
  version = c(
    R.version.string,
    vapply(
      required_packages,
      function(package) as.character(utils::packageVersion(package)),
      character(1)
    )
  )
)
write_h05_csv(
  environment,
  file.path(roots$manifests, "H05_execution_environment.csv")
)

reconciliation_path <- file.path(
  roots$manifests,
  "H05_metric010_reconciliation.csv"
)
reconciliation$updated_file_sha256 <- vapply(
  reconciliation$artifact_id,
  function(id) {
    if (id == "model_frame_objects") {
      artifact_sha256(frame_archive_path)
    } else if (id == "inferential_model_objects") {
      artifact_sha256(model_archive_path)
    } else if (id == "complete_family_BH_derived_update") {
      artifact_sha256(artifact_paths[["tests"]])
    } else {
      artifact_sha256(artifact_paths[[id]])
    }
  },
  character(1)
)
reconciliation <- reconciliation |>
  dplyr::mutate(
    decision_id = "METRIC-010",
    r_version = as.character(getRversion())
  )
write_h05_csv(reconciliation, reconciliation_path)

message(
  "H05 METRIC-010 refresh complete: 32 core MDER cells, 36 primary LOSO ",
  "refits, ",
  nrow(influence_refits),
  " current-estimand influence refits, zero BH-retained cells; all ",
  "non-MDER models and raw results verified unchanged"
)
