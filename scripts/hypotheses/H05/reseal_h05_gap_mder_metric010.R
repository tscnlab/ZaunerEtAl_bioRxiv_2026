#!/usr/bin/env Rscript

# Reseal only the H05 MDER slice that depends on the repaired
# gap-timing-unaware dataset. The accepted primary MDER fits and every fit for
# the other 16 metrics are immutable. Within H05-F3, non-MDER adjusted p-values
# and ranks may change only as the mathematical consequence of replacing its
# four MDER raw p-values.

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
  stop("The H05 gap MDER reseal requires R 4.6.1", call. = FALSE)
}

required_packages <- c(
  "dplyr", "tidyr", "purrr", "tibble", "readr", "digest", "openssl",
  "lme4", "glmmTMB", "performance", "DHARMa"
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

options(lifecycle_verbosity = "quiet", warn = 1)

producer <- "scripts/hypotheses/H05/reseal_h05_gap_mder_metric010.R"
metric_id <- "mder_mean_of_viable_ratios"
gap_id <- "manuscript_prepared_data"
gap_family_id <- "H05-F3-manuscript-prepared"

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

canonical_digest <- function(data, drop = character()) {
  data <- data[, setdiff(names(data), drop), drop = FALSE]
  keys <- intersect(
    c(
      "run_id", "data_scenario_id", "placement", "sample_scenario",
      "metric_order", "metric_id", "factor_order", "factor_id",
      "model_name", "participant_key", "local_date", "screen_rank",
      "upper_tail_rank", "candidate_id", "deletion_level"
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

target_rows <- function(data) {
  data$data_scenario_id == gap_id & data$metric_id == metric_id
}

replace_target_rows <- function(base, replacement) {
  replacement <- align_to_baseline(replacement, base)
  dplyr::bind_rows(base[!target_rows(base), , drop = FALSE], replacement)
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
    "A repaired gap-MDER input differs from its H05 pin: ",
    paste(input_audit$path[!input_audit$hash_verified], collapse = ", "),
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
gap_runs <- run_registry |>
  dplyr::filter(.data$data_scenario_id == .env$gap_id)
spec <- metric_registry |>
  dplyr::filter(.data$metric_id == .env$metric_id)
if (nrow(gap_runs) != 4L || nrow(spec) != 1L || spec$metric_order != 17L) {
  stop("The bounded H05 gap-MDER contract is invalid", call. = FALSE)
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
  spearman = file.path(roots$tables, "H05_descriptive_spearman.csv"),
  gap = file.path(roots$tables, "H05_manuscript_prepared_comparison.csv"),
  upper_tail = file.path(
    roots$diagnostics,
    "H05_mder_metric010_upper_tail.csv"
  ),
  upper_tail_summary = file.path(
    roots$diagnostics,
    "H05_mder_metric010_upper_tail_summary.csv"
  )
)
if (any(!file.exists(artifact_paths))) {
  stop("A required H05 artifact is missing", call. = FALSE)
}
baseline <- lapply(artifact_paths, read_h05_csv)
baseline_sha <- unname(vapply(
  artifact_paths,
  artifact_sha256,
  character(1)
))

frame_archive_path <- file.path(roots$model_data, "H05_model_frames.rds")
model_archive_path <- file.path(
  roots$models,
  "H05_inferential_model_objects.rds"
)
frame_archive <- readRDS(frame_archive_path)
model_archive <- readRDS(model_archive_path)
baseline_frame_archive_sha <- artifact_sha256(frame_archive_path)
baseline_model_archive_sha <- artifact_sha256(model_archive_path)

main_influence_path <- file.path(
  roots$diagnostics,
  "H05_mder_metric010_influence_refits.csv"
)
main_paired_path <- file.path(
  roots$tables,
  "H05_paired_placement_comparison.csv"
)
main_paired_source_path <- file.path(
  roots$source_data,
  "H05_paired_effect_comparison_data.csv"
)
frozen_file_paths <- c(
  main_influence = main_influence_path,
  main_paired = main_paired_path,
  main_paired_source = main_paired_source_path
)
frozen_file_sha <- vapply(
  frozen_file_paths,
  artifact_sha256,
  character(1)
)

gap_run_ids <- gap_runs$run_id
gap_frame_names <- paste(gap_run_ids, metric_id, sep = "::")
gap_model_names <- paste(
  "manuscript_prepared_data__glasses__all_available",
  metric_id,
  factor_registry$factor_id,
  sep = "::"
)
if (
  !all(gap_frame_names %in% names(frame_archive$model_frames)) ||
    !all(gap_model_names %in% names(model_archive))
) {
  stop("The accepted H05 archives lack the expected gap MDER slice", call. = FALSE)
}

immutable_frame_names <- setdiff(
  names(frame_archive$model_frames),
  gap_frame_names
)
immutable_model_names <- setdiff(names(model_archive), gap_model_names)
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
  influence = list(),
  spearman = list()
)
new_frames <- list()
new_models <- list()
prepared_cache <- list()
factor_cache <- list()
bundle_cache <- list()
upper_tail_rows <- list()
upper_tail_summary <- list()

for (gap_index in seq_len(nrow(gap_runs))) {
  run <- gap_runs[gap_index, , drop = FALSE]
  original_run_index <- match(run$run_id, run_registry$run_id)
  message("H05 repaired gap MDER run ", gap_index, "/4: ", run$run_id)
  prepared <- h05_prepare_metric_rows(
    objects$manuscript_prepared_data,
    spec,
    placement = run$placement,
    sample_scenario = run$sample_scenario,
    leba = leba,
    site_levels = site_levels
  )
  prepared_cache[[run$run_id]] <- prepared
  if (
    any(!is.finite(prepared$rows$value)) ||
      any(prepared$rows$value <= 0)
  ) {
    stop("A repaired gap MDER frame contains a nonpositive value", call. = FALSE)
  }
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
  upper_tail_summary[[gap_index]] <- tibble::tibble(
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
  upper_tail_rows[[gap_index]] <- prepared$rows |>
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
    cache_key <- paste(run$run_id, factor_row$factor_id, sep = "::")
    factor_cache[[cache_key]] <- factor_frame
    sample_row <- dplyr::bind_cols(prepared$base_flow, factor_frame$scaling)
    new_results$samples[[cache_key]] <- bind_identity(identity, sample_row)

    bundle <- h05_fit_bundle(
      factor_frame$frame,
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
      500000L + original_run_index * 10000L + 17L * 100L + factor_index
    )
    diagnostics <- h05_diagnostic_summary(
      bundle,
      factor_frame$frame,
      seed = seed
    )
    participant_summary <- h05_participant_summary(factor_frame$frame, spec)

    new_results$effects[[cache_key]] <- bind_identity(identity, effect)
    new_results$tests[[cache_key]] <- bind_identity(identity, test)
    new_results$diagnostics[[cache_key]] <- bind_identity(identity, diagnostics)
    new_results$model_manifest[[cache_key]] <- bind_identity(
      identity,
      h05_model_manifest_rows(bundle)
    )
    new_results$influence[[cache_key]] <- bind_identity(
      identity,
      h05_influence_candidates(bundle$final$model, factor_frame$frame, n = 3L)
    )
    new_results$spearman[[cache_key]] <- bind_identity(
      identity,
      h05_spearman_summary(participant_summary)
    )

    if (run$inferential_family) {
      model_key <- paste(
        run$run_id,
        metric_id,
        factor_row$factor_id,
        sep = "::"
      )
      new_models[[model_key]] <- bundle
    }
  }
}

new_results <- lapply(new_results, dplyr::bind_rows)
upper_tail_rows <- dplyr::bind_rows(upper_tail_rows)
upper_tail_summary <- dplyr::bind_rows(upper_tail_summary)

expected_counts <- c(
  effects = 16L,
  tests = 16L,
  diagnostics = 16L,
  samples = 16L,
  model_manifest = 48L,
  influence = 48L,
  spearman = 16L
)
observed_counts <- vapply(new_results[names(expected_counts)], nrow, integer(1))
if (!identical(observed_counts, expected_counts)) {
  stop("The repaired gap MDER result dimensions differ from contract", call. = FALSE)
}
if (length(new_frames) != 4L || length(new_models) != 4L) {
  stop("The repaired gap MDER archive dimensions differ from contract", call. = FALSE)
}

sample_check <- new_results$samples |>
  dplyr::distinct(
    .data$run_id,
    .data$observations,
    .data$participants,
    .data$participant_days,
    .data$sites
  ) |>
  dplyr::arrange(match(.data$run_id, gap_runs$run_id))
expected_samples <- tibble::tribble(
  ~run_id, ~observations, ~participants, ~participant_days, ~sites,
  "manuscript_prepared_data__chest__all_available", 723L, 152L, 723L, 8L,
  "manuscript_prepared_data__chest__paired_common_sample", 478L, 107L, 478L, 8L,
  "manuscript_prepared_data__glasses__all_available", 687L, 137L, 687L, 9L,
  "manuscript_prepared_data__glasses__paired_common_sample", 478L, 107L, 478L, 8L
) |>
  dplyr::arrange(match(.data$run_id, gap_runs$run_id))
if (!isTRUE(all.equal(sample_check, expected_samples, check.attributes = FALSE))) {
  stop("The repaired gap MDER fitted samples are not the verified samples", call. = FALSE)
}

effects <- replace_target_rows(baseline$effects, new_results$effects) |>
  dplyr::arrange(
    match(.data$run_id, run_registry$run_id),
    .data$metric_order,
    .data$factor_order
  )
samples <- replace_target_rows(baseline$frames, new_results$samples) |>
  dplyr::arrange(
    match(.data$run_id, run_registry$run_id),
    .data$metric_order,
    .data$factor_order
  )
diagnostics <- replace_target_rows(
  baseline$diagnostics,
  new_results$diagnostics
) |>
  dplyr::arrange(
    match(.data$run_id, run_registry$run_id),
    .data$metric_order,
    .data$factor_order
  )
model_manifest <- replace_target_rows(
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
influence <- replace_target_rows(baseline$influence, new_results$influence) |>
  dplyr::arrange(
    match(.data$run_id, run_registry$run_id),
    .data$metric_order,
    .data$factor_order,
    .data$screen_rank
  )
spearman <- replace_target_rows(baseline$spearman, new_results$spearman) |>
  dplyr::arrange(
    match(.data$run_id, run_registry$run_id),
    .data$metric_order,
    .data$factor_order
  )

tests <- replace_target_rows(baseline$tests, new_results$tests) |>
  dplyr::arrange(
    match(.data$run_id, run_registry$run_id),
    .data$metric_order,
    .data$factor_order
  )
gap_family_rows <- !is.na(tests$family_id) & tests$family_id == gap_family_id
if (sum(gap_family_rows) != 68L) {
  stop("H05-F3 is not a complete 68-test family", call. = FALSE)
}
tests$p_adjusted[gap_family_rows] <- adjust_p_family(
  tests$p_raw[gap_family_rows],
  method = "BH",
  n = 68L
)
tests$family_rank[gap_family_rows] <- rank(
  tests$p_raw[gap_family_rows],
  ties.method = "min",
  na.last = "keep"
)
tests$family_observed_tests[gap_family_rows] <- sum(
  !is.na(tests$p_raw[gap_family_rows])
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
  stop("The repaired H05 complete-family BH audit failed", call. = FALSE)
}

computed_target_master <- new_results$effects |>
  dplyr::left_join(
    tests |>
      dplyr::filter(
        .data$data_scenario_id == .env$gap_id,
        .data$metric_id == .env$metric_id
      ) |>
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
    new_results$diagnostics |>
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
    new_results$samples |>
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

master <- baseline$master
non_target_gap_family <- !target_rows(master) &
  !is.na(master$family_id) &
  master$family_id == gap_family_id
master[non_target_gap_family, ] <- replace_fields_by_key(
  master[non_target_gap_family, , drop = FALSE],
  tests[gap_family_rows & tests$metric_id != metric_id, , drop = FALSE],
  keys = c("run_id", "metric_id", "factor_id"),
  fields = c("p_adjusted", "family_rank")
)
master <- replace_target_rows(master, computed_target_master) |>
  dplyr::arrange(
    match(.data$run_id, run_registry$run_id),
    .data$metric_order,
    .data$factor_order
  )

main_gap_effects <- effects |>
  dplyr::filter(
    .data$placement == "glasses",
    .data$sample_scenario == "all_available",
    .data$data_scenario_id %in% c("main", .env$gap_id),
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
  dplyr::select(dplyr::all_of(names(baseline$gap)))
gap_comparison <- dplyr::bind_rows(
  baseline$gap[baseline$gap$metric_id != metric_id, , drop = FALSE],
  main_gap_effects
) |>
  dplyr::arrange(.data$metric_order, .data$factor_order)

gap_paired <- effects |>
  dplyr::filter(
    .data$data_scenario_id == .env$gap_id,
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
    estimate_difference_chest_minus_near_eye =
      .data$estimate_model_per_sd__chest -
        .data$estimate_model_per_sd__glasses,
    sign_concordant = sign(.data$estimate_model_per_sd__chest) ==
      sign(.data$estimate_model_per_sd__glasses),
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
      "not estimated: component comparison only; no new model or ",
      "resampling for the placement difference"
    )
  )

gap_samples <- new_results$samples |>
  dplyr::filter(.data$sample_scenario == "paired_common_sample") |>
  dplyr::select(
    .data$placement,
    .data$metric_id,
    .data$factor_id,
    .data$observations,
    .data$participants,
    .data$participant_days,
    .data$represented_days,
    .data$sites,
    .data$model_frame_hash
  ) |>
  tidyr::pivot_wider(
    names_from = .data$placement,
    values_from = c(
      .data$observations,
      .data$participants,
      .data$participant_days,
      .data$represented_days,
      .data$sites,
      .data$model_frame_hash
    ),
    names_sep = "__"
  )
gap_paired <- gap_paired |>
  dplyr::left_join(
    gap_samples,
    by = c("metric_id", "factor_id"),
    relationship = "one-to-one"
  ) |>
  dplyr::mutate(
    exact_sample_match =
      .data$observations__glasses == .data$observations__chest &
      .data$participants__glasses == .data$participants__chest &
      .data$participant_days__glasses == .data$participant_days__chest &
      .data$sites__glasses == .data$sites__chest,
    comparison_scope = paste0(
      "Matched MDER estimands in the gap-timing-unaware dataset; near eye ",
      "and chest components only; closeness does not establish equivalence"
    )
  ) |>
  dplyr::arrange(.data$factor_order)
if (
  nrow(gap_paired) != 4L ||
    any(!gap_paired$exact_sample_match) ||
    any(gap_paired$participants__glasses != 107L) ||
    any(gap_paired$participant_days__glasses != 478L) ||
    any(gap_paired$sites__glasses != 8L)
) {
  stop("The repaired gap paired/common MDER comparison is invalid", call. = FALSE)
}

upper_tail <- dplyr::bind_rows(
  baseline$upper_tail[
    !baseline$upper_tail$run_id %in% gap_run_ids,
    ,
    drop = FALSE
  ],
  align_to_baseline(upper_tail_rows, baseline$upper_tail)
) |>
  dplyr::arrange(
    match(.data$run_id, run_registry$run_id),
    .data$upper_tail_rank
  )
upper_tail_summary_all <- dplyr::bind_rows(
  baseline$upper_tail_summary[
    !baseline$upper_tail_summary$run_id %in% gap_run_ids,
    ,
    drop = FALSE
  ],
  align_to_baseline(upper_tail_summary, baseline$upper_tail_summary)
) |>
  dplyr::arrange(match(.data$run_id, run_registry$run_id))

# Bounded deletion refits for the repaired all-available gap MDER fits. These
# are diagnostics only and are not added to a multiplicity family.
gap_influence_refits <- list()
influence_index <- 1L
for (run_id in c(
  "manuscript_prepared_data__glasses__all_available",
  "manuscript_prepared_data__chest__all_available"
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
      gap_influence_refits[[influence_index]] <- tibble::tibble(
        run_id = run_id,
        data_scenario_id = gap_id,
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
        observations_removed = nrow(full_frame) -
          nrow(sensitivity_factor$frame),
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
gap_influence_refits <- dplyr::bind_rows(gap_influence_refits) |>
  dplyr::arrange(
    .data$placement,
    .data$factor_order,
    .data$deletion_level,
    .data$candidate_id
  )
if (
  nrow(gap_influence_refits) == 0L ||
    any(gap_influence_refits$refit_status != "PASS")
) {
  stop("A repaired gap MDER influence refit failed", call. = FALSE)
}

for (name in gap_frame_names) {
  frame_archive$model_frames[[name]] <- new_frames[[name]]
}
for (name in gap_model_names) {
  model_archive[[name]] <- new_models[[name]]
}
frame_archive$input_contract <- input_contract
frame_archive$status <- "metric010_gap_mder_repaired_and_resealed"
frame_archive$metadata$gap_mder_repair <- paste0(
  "Only the four gap-timing-unaware MDER frames were replaced from the ",
  "verified METRIC-010 repair; all primary and non-MDER frames are frozen"
)

updated_immutable_frame_digest <- digest::digest(
  frame_archive$model_frames[immutable_frame_names],
  algo = "sha256",
  serialize = TRUE
)
updated_immutable_model_digest <- digest::digest(
  model_archive[immutable_model_names],
  algo = "sha256",
  serialize = TRUE
)
if (
  !identical(immutable_frame_digest, updated_immutable_frame_digest) ||
    !identical(immutable_model_digest, updated_immutable_model_digest)
) {
  stop("A frozen H05 frame or fitted model changed", call. = FALSE)
}

immutable_core <- function(before, after, drop = character()) {
  before_keep <- before[!target_rows(before), , drop = FALSE]
  after_keep <- after[!target_rows(after), , drop = FALSE]
  c(
    before = canonical_digest(before_keep, drop = drop),
    after = canonical_digest(after_keep, drop = drop)
  )
}

core_pairs <- list(
  frames = immutable_core(baseline$frames, samples),
  effects = immutable_core(baseline$effects, effects),
  diagnostics = immutable_core(baseline$diagnostics, diagnostics),
  model_manifest = immutable_core(baseline$model_manifest, model_manifest),
  influence = immutable_core(baseline$influence, influence),
  spearman = immutable_core(baseline$spearman, spearman),
  gap = c(
    before = canonical_digest(
      baseline$gap[baseline$gap$metric_id != metric_id, , drop = FALSE]
    ),
    after = canonical_digest(
      gap_comparison[gap_comparison$metric_id != metric_id, , drop = FALSE]
    )
  )
)
if (any(vapply(core_pairs, function(x) !identical(x[[1L]], x[[2L]]), logical(1)))) {
  stop("A frozen H05 tabular result changed", call. = FALSE)
}

f12_before <- baseline$tests |>
  dplyr::filter(.data$family_id %in% c(
    "H05-F1-primary",
    "H05-F2-complementary-chest"
  ))
f12_after <- tests |>
  dplyr::filter(.data$family_id %in% c(
    "H05-F1-primary",
    "H05-F2-complementary-chest"
  ))
if (!identical(canonical_digest(f12_before), canonical_digest(f12_after))) {
  stop("A primary or complementary H05 test changed", call. = FALSE)
}

f3_non_mder_before <- baseline$tests |>
  dplyr::filter(
    .data$family_id == .env$gap_family_id,
    .data$metric_id != .env$metric_id
  )
f3_non_mder_after <- tests |>
  dplyr::filter(
    .data$family_id == .env$gap_family_id,
    .data$metric_id != .env$metric_id
  )
if (!identical(
  canonical_digest(f3_non_mder_before, drop = c("p_adjusted", "family_rank")),
  canonical_digest(f3_non_mder_after, drop = c("p_adjusted", "family_rank"))
)) {
  stop("A non-MDER H05-F3 raw result changed", call. = FALSE)
}

bh_change_audit <- dplyr::inner_join(
  f3_non_mder_before |>
    dplyr::select(
      .data$run_id,
      .data$metric_id,
      .data$factor_id,
      before_p_adjusted = .data$p_adjusted,
      before_family_rank = .data$family_rank
    ),
  f3_non_mder_after |>
    dplyr::select(
      .data$run_id,
      .data$metric_id,
      .data$factor_id,
      after_p_adjusted = .data$p_adjusted,
      after_family_rank = .data$family_rank
    ),
  by = c("run_id", "metric_id", "factor_id"),
  relationship = "one-to-one"
) |>
  dplyr::summarise(
    non_mder_rows = dplyr::n(),
    adjusted_p_rows_changed = sum(
      abs(.data$before_p_adjusted - .data$after_p_adjusted) > 1e-15
    ),
    family_rank_rows_changed = sum(
      .data$before_family_rank != .data$after_family_rank
    )
  )

main_tail_before <- baseline$upper_tail |>
  dplyr::filter(.data$data_scenario_id == "main")
main_tail_after <- upper_tail |>
  dplyr::filter(.data$data_scenario_id == "main")
main_tail_summary_before <- baseline$upper_tail_summary |>
  dplyr::filter(.data$data_scenario_id == "main")
main_tail_summary_after <- upper_tail_summary_all |>
  dplyr::filter(.data$data_scenario_id == "main")
if (
  !identical(
    canonical_digest(main_tail_before),
    canonical_digest(main_tail_after)
  ) ||
    !identical(
      canonical_digest(main_tail_summary_before),
      canonical_digest(main_tail_summary_after)
    )
) {
  stop("A frozen primary MDER upper-tail record changed", call. = FALSE)
}

# Install only after every scientific and preservation check has passed.
write_h05_csv(input_audit, file.path(roots$model_data, "H05_input_audit.csv"))
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
write_h05_csv(diagnostics, artifact_paths[["diagnostics"]])
write_h05_csv(influence, artifact_paths[["influence"]])
write_h05_csv(spearman, artifact_paths[["spearman"]])
write_h05_csv(gap_comparison, artifact_paths[["gap"]])
write_h05_csv(upper_tail, artifact_paths[["upper_tail"]])
write_h05_csv(
  upper_tail_summary_all,
  artifact_paths[["upper_tail_summary"]]
)

gap_influence_path <- file.path(
  roots$diagnostics,
  "H05_mder_metric010_gap_influence_refits.csv"
)
gap_paired_path <- file.path(
  roots$tables,
  "H05_mder_metric010_gap_paired_placement_comparison.csv"
)
gap_paired_source_path <- file.path(
  roots$source_data,
  "H05_mder_metric010_gap_paired_placement_comparison.csv"
)
write_h05_csv(gap_influence_refits, gap_influence_path)
write_h05_csv(gap_paired, gap_paired_path)
write_h05_csv(gap_paired, gap_paired_source_path)

observed_frozen_sha <- vapply(
  frozen_file_paths,
  artifact_sha256,
  character(1)
)
if (!identical(frozen_file_sha, observed_frozen_sha)) {
  stop("A frozen primary influence or placement artifact changed", call. = FALSE)
}

reconciliation <- dplyr::bind_rows(
  dplyr::bind_rows(lapply(names(core_pairs), function(name) {
    pair <- core_pairs[[name]]
    tibble::tibble(
      check_id = paste0("frozen_non_target_", name),
      scope = "all rows outside repaired gap MDER",
      baseline_digest = pair[["before"]],
      updated_digest = pair[["after"]],
      invariant_verified = identical(pair[["before"]], pair[["after"]]),
      allowed_change = "none",
      changed_rows = 0L,
      note = "Primary MDER and all non-MDER scientific content frozen"
    )
  })),
  tibble::tibble(
    check_id = c(
      "immutable_model_frame_objects",
      "immutable_inferential_model_objects",
      "H05_F1_F2_complete_tests",
      "H05_F3_non_MDER_raw_tests",
      "H05_F3_non_MDER_BH_derivatives",
      "primary_MDER_upper_tail",
      "primary_MDER_influence_file",
      "primary_paired_comparison_file",
      "primary_paired_source_file"
    ),
    scope = c(
      "132 stored frames excluding four repaired gap MDER frames",
      "200 fitted bundles excluding four repaired gap MDER bundles",
      "complete primary and complementary 68-test families",
      "64 non-MDER raw tests in repaired gap family",
      "mathematically derived H05-F3 BH fields only",
      "four primary MDER upper-tail runs and summaries",
      relative_path(main_influence_path),
      relative_path(main_paired_path),
      relative_path(main_paired_source_path)
    ),
    baseline_digest = c(
      immutable_frame_digest,
      immutable_model_digest,
      canonical_digest(f12_before),
      canonical_digest(
        f3_non_mder_before,
        drop = c("p_adjusted", "family_rank")
      ),
      canonical_digest(
        f3_non_mder_before,
        drop = c("p_adjusted", "family_rank")
      ),
      canonical_digest(dplyr::bind_rows(
        main_tail_before,
        main_tail_summary_before
      )),
      frozen_file_sha[["main_influence"]],
      frozen_file_sha[["main_paired"]],
      frozen_file_sha[["main_paired_source"]]
    ),
    updated_digest = c(
      updated_immutable_frame_digest,
      updated_immutable_model_digest,
      canonical_digest(f12_after),
      canonical_digest(
        f3_non_mder_after,
        drop = c("p_adjusted", "family_rank")
      ),
      canonical_digest(
        f3_non_mder_after,
        drop = c("p_adjusted", "family_rank")
      ),
      canonical_digest(dplyr::bind_rows(
        main_tail_after,
        main_tail_summary_after
      )),
      observed_frozen_sha[["main_influence"]],
      observed_frozen_sha[["main_paired"]],
      observed_frozen_sha[["main_paired_source"]]
    ),
    invariant_verified = TRUE,
    allowed_change = c(
      rep("none", 4L),
      "p_adjusted;family_rank",
      rep("none", 4L)
    ),
    changed_rows = c(
      0L,
      0L,
      0L,
      0L,
      bh_change_audit$adjusted_p_rows_changed,
      0L,
      0L,
      0L,
      0L
    ),
    note = c(
      "Only four repaired gap MDER frame objects replaced",
      "Only four repaired H05-F3 MDER fitted bundles replaced",
      "No primary or complementary test value changed",
      "Raw statistics and p-values are byte-value stable",
      paste0(
        bh_change_audit$adjusted_p_rows_changed,
        " adjusted p-values and ",
        bh_change_audit$family_rank_rows_changed,
        " family ranks changed among the 64 non-MDER H05-F3 rows"
      ),
      "Primary MDER tail diagnostics frozen",
      "All 44 accepted primary influence refits frozen",
      "Accepted primary paired/common comparison frozen",
      "Accepted paired figure source data frozen"
    )
  )
) |>
  dplyr::mutate(
    decision_id = "METRIC-010",
    repair_scope = "gap-timing-unaware MDER only",
    r_version = as.character(getRversion())
  )
if (any(!reconciliation$invariant_verified)) {
  stop("The gap MDER reseal reconciliation failed", call. = FALSE)
}

reconciliation_path <- file.path(
  roots$manifests,
  "H05_metric010_gap_reseal_reconciliation.csv"
)
write_h05_csv(reconciliation, reconciliation_path)

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

message(
  "H05 repaired gap MDER reseal complete: 16 core cells, ",
  nrow(gap_influence_refits),
  " bounded gap influence refits, ",
  bh_change_audit$adjusted_p_rows_changed,
  " non-MDER adjusted-p changes and ",
  bh_change_audit$family_rank_rows_changed,
  " non-MDER rank changes in H05-F3; primary MDER and all non-MDER fits frozen"
)
