# Run the approved production bootstrap for the eight changed H01 targets.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
source(file.path(root, "scripts/pipeline/paths_io.R"))
source(file.path(root, "scripts/hypotheses/H01/h01_contract.R"))
source(file.path(root, "scripts/hypotheses/H01/h01_modeling.R"))

if (!identical(as.character(getRversion()), "4.6.1")) {
  h01_abort(
    "The H01 production bootstrap requires R 4.6.1; found %s",
    as.character(getRversion())
  )
}

producer <-
  "scripts/hypotheses/H01/run_h01_response_family_bootstrap_production.R"
metric_id <- "duration_below_10_pre_sleep"
successful_refits <- as.integer(Sys.getenv(
  "H01_PRODUCTION_REFITS",
  unset = "1000"
))
production_cores <- as.integer(Sys.getenv(
  "H01_PRODUCTION_CORES",
  unset = "4"
))
author_approval <- Sys.getenv("H01_AUTHOR_APPROVAL", unset = "")
validate_only <- identical(
  tolower(Sys.getenv("H01_PRODUCTION_VALIDATE_ONLY", unset = "false")),
  "true"
)

if (successful_refits != 1000L) {
  h01_abort("H01 production requires exactly 1,000 successful refits")
}
if (!is.finite(production_cores) || production_cores < 1L) {
  h01_abort("H01_PRODUCTION_CORES must be a positive integer")
}
if (!identical(author_approval, "approved")) {
  h01_abort(
    paste0(
      "H01 production requires explicit post-pilot author approval; ",
      "set H01_AUTHOR_APPROVAL=approved only after approval"
    )
  )
}

spec <- h01_metric_registry() |>
  dplyr::filter(.data$metric_id == !!metric_id)
if (
  nrow(spec) != 1L ||
    spec$response_family != "gaussian" ||
    spec$response_transform != "identity" ||
    spec$effect_scale != "difference"
) {
  h01_abort("The approved H01 pre-sleep Gaussian contract is not active")
}

selection_path <- file.path(
  root,
  paste0(
    "artifacts/09_tables/H01/response_family_candidates/",
    "H01_response_family_candidate_selection.csv"
  )
)
selection <- readr::read_csv(selection_path, show_col_types = FALSE) |>
  dplyr::filter(.data$metric_id == !!metric_id)
if (
  nrow(selection) != 1L ||
    selection$selected_candidate_id != "gaussian_identity" ||
    !selection$canonical_update_required
) {
  h01_abort("The H01 candidate selection does not authorize production")
}

diagnostic_path <- file.path(
  root,
  "artifacts/08_diagnostics/H01/H01_model_diagnostics.csv"
)
diagnostics <- readr::read_csv(diagnostic_path, show_col_types = FALSE) |>
  dplyr::filter(.data$metric_id == !!metric_id)
if (
  nrow(diagnostics) != 8L ||
    any(diagnostics$diagnostic_status == "FAIL_MAJOR_GATE") ||
    any(startsWith(diagnostics$residual_status, "WARN_STRONG")) ||
    any(startsWith(diagnostics$prediction_bound_status, "WARN"))
) {
  h01_abort("The selected H01 production target failed its point-model gate")
}

input_contract <- h01_input_contract(root)
if (
  !identical(
    artifact_sha256(input_contract$main$manifest),
    input_contract$main$manifest_sha256
  ) ||
    !identical(
      artifact_sha256(input_contract$manuscript_prepared_data$manifest),
      input_contract$manuscript_prepared_data$manifest_sha256
    )
) {
  h01_abort("Pinned H01 model-data manifests changed before production")
}

point_path <- file.path(
  root,
  "artifacts/09_tables/H01/H01_r2_point_summaries.csv"
)
summary_path <- file.path(
  root,
  "artifacts/09_tables/H01/H01_r2_bootstrap_summaries.csv"
)
audit_path <- file.path(
  root,
  "artifacts/08_diagnostics/H01/H01_r2_bootstrap_audit.csv"
)
failure_path <- file.path(
  root,
  "artifacts/08_diagnostics/H01/H01_r2_bootstrap_failures.csv"
)
pilot_provenance_path <- file.path(
  root,
  paste0(
    "artifacts/08_diagnostics/H01/bootstrap_pilot/",
    "response_family_change/",
    "H01_response_family_bootstrap_pilot_provenance.csv"
  )
)

required_inputs <- c(
  point_path,
  summary_path,
  audit_path,
  failure_path,
  pilot_provenance_path
)
if (!all(file.exists(required_inputs))) {
  h01_abort("A required H01 production or pilot artifact is missing")
}

pilot_provenance <- readr::read_csv(
  pilot_provenance_path,
  show_col_types = FALSE
)
if (
  nrow(pilot_provenance) != 1L ||
    pilot_provenance$pilot_status !=
      "PASS_AWAITING_AUTHOR_PRODUCTION_APPROVAL" ||
    pilot_provenance$planned_targets != 8L ||
    pilot_provenance$completed_targets != 8L ||
    pilot_provenance$successful_refits_per_target < 50L ||
    pilot_provenance$total_failed_refits != 0L ||
    pilot_provenance$total_warning_refits != 0L
) {
  h01_abort("The COMPUTE-001 H01 pilot is not production-eligible")
}

recomputed_pilot_contract_sha256 <- digest::digest(
  list(
    metric_id = metric_id,
    response_family = spec$response_family,
    response_transform = spec$response_transform,
    successful_refits = as.integer(
      pilot_provenance$successful_refits_per_target
    ),
    candidate_selection_sha256 = artifact_sha256(selection_path),
    h01_contract_sha256 = artifact_sha256(file.path(
      root,
      "scripts/hypotheses/H01/h01_contract.R"
    )),
    h01_modeling_sha256 = artifact_sha256(file.path(
      root,
      "scripts/hypotheses/H01/h01_modeling.R"
    )),
    main_manifest_sha256 = input_contract$main$manifest_sha256,
    manuscript_manifest_sha256 =
      input_contract$manuscript_prepared_data$manifest_sha256
  ),
  algo = "sha256",
  serialize = TRUE
)
if (!identical(
  recomputed_pilot_contract_sha256,
  pilot_provenance$pilot_contract_sha256
)) {
  h01_abort("The H01 scientific contract changed after the approved pilot")
}

if (
  !identical(
    artifact_sha256(selection_path),
    pilot_provenance$selection_sha256
  ) ||
    !identical(
      artifact_sha256(point_path),
      pilot_provenance$point_results_sha256
    ) ||
    !identical(
      artifact_sha256(diagnostic_path),
      pilot_provenance$diagnostics_sha256
    ) ||
    !identical(
      artifact_sha256(file.path(root, "renv.lock")),
      pilot_provenance$renv_lock_sha256
    )
) {
  h01_abort("A pinned H01 pilot input changed before production")
}

point_results <- readr::read_csv(point_path, show_col_types = FALSE)
preserved_summaries <- readr::read_csv(
  summary_path,
  show_col_types = FALSE
) |>
  dplyr::filter(.data$metric_id != !!metric_id)
preserved_audits <- readr::read_csv(
  audit_path,
  show_col_types = FALSE
) |>
  dplyr::filter(.data$metric_id != !!metric_id)
preserved_failures <- readr::read_csv(
  failure_path,
  show_col_types = FALSE
) |>
  dplyr::filter(.data$metric_id != !!metric_id)

target_key <- function(data) {
  paste(data$run_id, data$metric_id, sep = "::")
}
if (
  nrow(preserved_audits) != 120L ||
    length(unique(target_key(preserved_audits))) != 120L ||
    any(preserved_audits$status != "PASS") ||
    any(preserved_audits$used_refits < 1000L) ||
    nrow(preserved_failures) != sum(preserved_audits$failed_refits)
) {
  h01_abort("The 120 preserved H01 bootstrap targets failed validation")
}

model_root <- file.path(root, "artifacts/07_models/H01")
preserved_draw_paths <- sort(list.files(
  model_root,
  pattern = "_r2_bootstrap_draws[.]rds$",
  recursive = TRUE,
  full.names = TRUE
))
preserved_draw_paths <- preserved_draw_paths[
  !grepl(paste0("/", metric_id, "_r2_bootstrap_draws[.]rds$"),
    preserved_draw_paths
  )
]
if (length(preserved_draw_paths) != 120L) {
  h01_abort("Expected exactly 120 preserved canonical H01 draw files")
}
preserved_draw_hashes <- stats::setNames(
  vapply(
    preserved_draw_paths,
    artifact_sha256,
    character(1)
  ),
  preserved_draw_paths
)

run_registry <- h01_run_registry()
checkpoint_root <- file.path(
  model_root,
  "bootstrap_checkpoints/response_family_change"
)
runtime_root <- file.path(
  root,
  "artifacts/08_diagnostics/H01/bootstrap_production/response_family_change"
)
runtime_path <- file.path(
  runtime_root,
  "H01_response_family_bootstrap_production_runtime.csv"
)
provenance_path <- file.path(
  runtime_root,
  "H01_response_family_bootstrap_production_provenance.csv"
)
manifest_path <- file.path(
  root,
  "artifacts/12_manifests/H01_response_family_bootstrap_production_artifacts.csv"
)
invisible(vapply(
  c(checkpoint_root, runtime_root, dirname(manifest_path)),
  dir.create,
  logical(1),
  recursive = TRUE,
  showWarnings = FALSE
))

production_contract_sha256 <- digest::digest(
  list(
    pilot_contract_sha256 = pilot_provenance$pilot_contract_sha256,
    metric_id = metric_id,
    response_family = spec$response_family,
    response_transform = spec$response_transform,
    effect_scale = spec$effect_scale,
    successful_refits = successful_refits,
    target_run_ids = run_registry$run_id,
    main_manifest_sha256 = input_contract$main$manifest_sha256,
    manuscript_manifest_sha256 =
      input_contract$manuscript_prepared_data$manifest_sha256
  ),
  algo = "sha256",
  serialize = TRUE
)

if (validate_only) {
  message(
    "H01 production preflight passed for 8 targets × ",
    successful_refits,
    " successful refits; contract ",
    production_contract_sha256
  )
  quit(save = "no", status = 0L)
}

h01_production_identity <- function(data, run) {
  if (nrow(data) == 0L) {
    return(data)
  }
  identity <- tibble::tibble(
    run_id = run$run_id,
    data_scenario_id = run$data_scenario_id,
    placement = run$placement,
    sample_scenario = run$sample_scenario,
    analytical_role = run$analytical_role,
    metric_order = spec$metric_order,
    metric_id = spec$metric_id,
    analysis_unit = spec$analysis_unit,
    response_family = spec$response_family,
    response_transform = spec$response_transform
  )
  dplyr::bind_cols(identity[rep(1L, nrow(data)), , drop = FALSE], data)
}

summary_rows <- list()
audit_rows <- list()
failure_rows <- list()
runtime_rows <- list()
summary_index <- 1L
audit_index <- 1L
failure_index <- 1L
runtime_index <- 1L
production_started <- Sys.time()

for (run_index in seq_len(nrow(run_registry))) {
  run <- run_registry[run_index, , drop = FALSE]
  model_directory <- file.path(
    model_root,
    run$data_scenario_id,
    run$placement,
    run$sample_scenario
  )
  bundle_path <- file.path(
    model_directory,
    paste0(metric_id, "_models.rds")
  )
  frame_path <- file.path(
    model_directory,
    paste0(metric_id, "_model_frame.rds")
  )
  bundle <- readRDS(bundle_path)
  frame <- readRDS(frame_path)
  if (
    !identical(bundle$spec$response_family, spec$response_family) ||
      !identical(bundle$spec$response_transform, spec$response_transform) ||
      !identical(bundle$frame_keys, frame$.model_row_id)
  ) {
    h01_abort("H01 production point-model mismatch in `%s`", run$run_id)
  }

  target_contract_sha256 <- digest::digest(
    list(
      production_contract_sha256 = production_contract_sha256,
      run_id = run$run_id,
      bundle_sha256 = artifact_sha256(bundle_path),
      frame_sha256 = artifact_sha256(frame_path)
    ),
    algo = "sha256",
    serialize = TRUE
  )
  draws_path <- file.path(
    model_directory,
    paste0(metric_id, "_r2_bootstrap_draws.rds")
  )
  checkpoint_directory <- file.path(
    checkpoint_root,
    run$data_scenario_id,
    run$placement,
    run$sample_scenario
  )
  dir.create(checkpoint_directory, recursive = TRUE, showWarnings = FALSE)
  checkpoint_path <- file.path(
    checkpoint_directory,
    paste0(metric_id, "_checkpoint.rds")
  )
  checkpoint <- if (file.exists(checkpoint_path)) {
    readRDS(checkpoint_path)
  } else {
    NULL
  }
  reuse <- !is.null(checkpoint) &&
    identical(checkpoint$target_contract_sha256, target_contract_sha256) &&
    file.exists(draws_path) &&
    identical(artifact_sha256(draws_path), checkpoint$draws_sha256)

  if (reuse) {
    draws <- readRDS(draws_path)
    audit <- checkpoint$audit
    failures <- checkpoint$failures
    runtime <- checkpoint$runtime
    if (
      nrow(draws) != successful_refits ||
        audit$used_refits != successful_refits ||
        audit$status != "PASS"
    ) {
      h01_abort(
        "H01 production checkpoint mismatch in `%s`",
        run$run_id
      )
    }
    checkpoint_status <- "REUSED_COMPLETED_TARGET_CHECKPOINT"
  } else {
    message("Bootstrapping approved H01 target: ", run$run_id)
    started <- Sys.time()
    process_started <- proc.time()
    seed <- h01_primary_seed(
      spec$metric_order,
      run$data_scenario_id,
      run$placement,
      run$sample_scenario
    )
    production <- h01_bootstrap_r2(
      bundle,
      frame,
      seed = seed,
      successful_refits = successful_refits,
      cores = production_cores
    )
    completed <- Sys.time()
    process_elapsed <- proc.time() - process_started
    draws <- production$draws
    audit <- production$audit
    failures <- production$failures
    if (
      nrow(draws) != successful_refits ||
        audit$successful_refits < successful_refits ||
        audit$used_refits != successful_refits ||
        audit$status != "PASS"
    ) {
      h01_abort("H01 production target failed in `%s`", run$run_id)
    }
    write_rds_artifact(draws, draws_path, producer = producer)
    runtime <- tibble::tibble(
      started_utc = format(started, tz = "UTC", usetz = TRUE),
      completed_utc = format(completed, tz = "UTC", usetz = TRUE),
      wall_seconds = as.numeric(difftime(
        completed,
        started,
        units = "secs"
      )),
      user_cpu_seconds = unname(process_elapsed[["user.self"]]),
      system_cpu_seconds = unname(process_elapsed[["sys.self"]]),
      requested_parallel_workers = production_cores,
      detected_logical_cores = parallel::detectCores(),
      omp_threads = Sys.getenv("OMP_NUM_THREADS", unset = NA_character_),
      openblas_threads = Sys.getenv(
        "OPENBLAS_NUM_THREADS",
        unset = NA_character_
      ),
      mkl_threads = Sys.getenv("MKL_NUM_THREADS", unset = NA_character_),
      veclib_maximum_threads = Sys.getenv(
        "VECLIB_MAXIMUM_THREADS",
        unset = NA_character_
      )
    )
    checkpoint <- list(
      target_contract_sha256 = target_contract_sha256,
      draws_sha256 = artifact_sha256(draws_path),
      audit = audit,
      failures = failures,
      runtime = runtime
    )
    write_rds_artifact(checkpoint, checkpoint_path, producer = producer)
    checkpoint_status <- "WROTE_COMPLETED_TARGET_CHECKPOINT"
  }

  point <- point_results |>
    dplyr::filter(
      .data$run_id == run$run_id,
      .data$metric_id == !!metric_id
    )
  summary_rows[[summary_index]] <- h01_production_identity(
    h01_summarize_bootstrap(point, draws),
    run
  )
  summary_index <- summary_index + 1L
  audit_rows[[audit_index]] <- h01_production_identity(audit, run)
  audit_index <- audit_index + 1L
  if (nrow(failures) > 0L) {
    failure_rows[[failure_index]] <- h01_production_identity(
      failures,
      run
    )
    failure_index <- failure_index + 1L
  }
  runtime_rows[[runtime_index]] <- h01_production_identity(
    dplyr::bind_cols(
      runtime,
      tibble::tibble(
        checkpoint_status = checkpoint_status,
        target_contract_sha256 = target_contract_sha256,
        draws_path = substring(draws_path, nchar(root) + 2L),
        draws_sha256 = artifact_sha256(draws_path),
        successful_draws = nrow(draws)
      )
    ),
    run
  )
  runtime_index <- runtime_index + 1L
}

new_summaries <- dplyr::bind_rows(summary_rows)
new_audits <- dplyr::bind_rows(audit_rows)
new_failures <- if (length(failure_rows) == 0L) {
  preserved_failures[0, , drop = FALSE]
} else {
  dplyr::bind_rows(failure_rows)
}
runtimes <- dplyr::bind_rows(runtime_rows)

if (
  nrow(new_audits) != 8L ||
    length(unique(target_key(new_audits))) != 8L ||
    any(new_audits$status != "PASS") ||
    any(new_audits$successful_refits < successful_refits) ||
    any(new_audits$used_refits != successful_refits) ||
    any(runtimes$successful_draws != successful_refits) ||
    any(new_summaries$bootstrap_successful_used != successful_refits)
) {
  h01_abort("H01 changed-target production aggregate validation failed")
}

run_order <- stats::setNames(seq_len(nrow(run_registry)), run_registry$run_id)
measure_order <- c(
  "marginal_r2",
  "conditional_r2",
  "participant_associated_share",
  "site_part_r2",
  "photoperiod_part_r2",
  "latitude_model_marginal_r2",
  "latitude_part_r2",
  "unrepresented_share"
)
merged_summaries <- dplyr::bind_rows(
  preserved_summaries,
  new_summaries
) |>
  dplyr::mutate(
    .run_order = unname(run_order[.data$run_id]),
    .measure_order = match(.data$measure, measure_order),
    .approximation_order = match(
      .data$approximation,
      c("lognormal", "delta")
    )
  ) |>
  dplyr::arrange(
    .data$.run_order,
    .data$metric_order,
    .data$.approximation_order,
    .data$.measure_order
  ) |>
  dplyr::select(-dplyr::starts_with("."))
merged_audits <- dplyr::bind_rows(
  preserved_audits,
  new_audits
) |>
  dplyr::mutate(.run_order = unname(run_order[.data$run_id])) |>
  dplyr::arrange(.data$.run_order, .data$metric_order) |>
  dplyr::select(-.data$.run_order)
merged_failures <- dplyr::bind_rows(
  preserved_failures,
  new_failures
) |>
  dplyr::mutate(.run_order = unname(run_order[.data$run_id])) |>
  dplyr::arrange(.data$.run_order, .data$metric_order, .data$attempt) |>
  dplyr::select(-.data$.run_order)

summary_key <- paste(
  merged_summaries$run_id,
  merged_summaries$metric_id,
  merged_summaries$approximation,
  merged_summaries$measure,
  sep = "::"
)
if (
  nrow(merged_audits) != 128L ||
    length(unique(target_key(merged_audits))) != 128L ||
    sum(merged_audits$metric_id == metric_id) != 8L ||
    any(merged_audits$status != "PASS") ||
    any(merged_audits$used_refits < 1000L) ||
    nrow(merged_failures) != sum(merged_audits$failed_refits) ||
    anyDuplicated(summary_key) ||
    !setequal(
      unique(target_key(merged_summaries)),
      unique(target_key(merged_audits))
    ) ||
    any(merged_summaries$bootstrap_successful_used < 1000L)
) {
  h01_abort("The complete 128-target H01 bootstrap package is inconsistent")
}

current_preserved_hashes <- vapply(
  names(preserved_draw_hashes),
  artifact_sha256,
  character(1)
)
if (!identical(unname(current_preserved_hashes), unname(preserved_draw_hashes))) {
  h01_abort("A preserved H01 production draw file changed during the run")
}

all_draw_paths <- sort(list.files(
  model_root,
  pattern = "_r2_bootstrap_draws[.]rds$",
  recursive = TRUE,
  full.names = TRUE
))
if (length(all_draw_paths) != 128L) {
  h01_abort("The completed H01 package does not contain 128 draw files")
}

write_csv_artifact(merged_summaries, summary_path, producer = producer)
write_csv_artifact(merged_audits, audit_path, producer = producer)
write_csv_artifact(merged_failures, failure_path, producer = producer)
write_csv_artifact(runtimes, runtime_path, producer = producer)

production_completed <- Sys.time()
write_csv_artifact(
  tibble::tibble(
    inference_status =
      "PRODUCTION — 1,000 successful joint bootstrap refits",
    author_approval =
      "Explicit author approval in H01 task on 2026-08-01",
    production_contract_sha256 = production_contract_sha256,
    pilot_contract_sha256 = pilot_provenance$pilot_contract_sha256,
    r_version = as.character(getRversion()),
    lme4_version = as.character(utils::packageVersion("lme4")),
    performance_version =
      as.character(utils::packageVersion("performance")),
    successful_refits_per_target = successful_refits,
    planned_targets = 8L,
    completed_targets = nrow(new_audits),
    total_attempted_refits = sum(new_audits$attempted_refits),
    total_successful_refits = sum(new_audits$successful_refits),
    total_used_refits = sum(new_audits$used_refits),
    total_failed_refits = sum(new_audits$failed_refits),
    total_warning_refits = sum(new_audits$warning_refits),
    preserved_targets = nrow(preserved_audits),
    preserved_draw_hashes_unchanged = TRUE,
    requested_parallel_workers = production_cores,
    total_wall_seconds = as.numeric(difftime(
      production_completed,
      production_started,
      units = "secs"
    )),
    checkpoint_granularity = "completed run-metric target",
    checkpoint_directory = substring(
      checkpoint_root,
      nchar(root) + 2L
    ),
    command = paste0(
      "H01_AUTHOR_APPROVAL=approved H01_PRODUCTION_REFITS=",
      successful_refits,
      " H01_PRODUCTION_CORES=",
      production_cores,
      " Rscript --vanilla ",
      producer
    ),
    main_input_manifest_sha256 = input_contract$main$manifest_sha256,
    manuscript_prepared_input_manifest_sha256 =
      input_contract$manuscript_prepared_data$manifest_sha256,
    selection_sha256 = artifact_sha256(selection_path),
    point_results_sha256 = artifact_sha256(point_path),
    diagnostics_sha256 = artifact_sha256(diagnostic_path),
    renv_lock_sha256 = artifact_sha256(file.path(root, "renv.lock")),
    producer_path = producer,
    producer_sha256 = artifact_sha256(file.path(root, producer)),
    production_status = "PASS",
    completed_utc = format(production_completed, tz = "UTC", usetz = TRUE)
  ),
  provenance_path,
  producer = producer
)

manifest_files <- sort(unique(c(
  all_draw_paths[grepl(
    paste0("/", metric_id, "_r2_bootstrap_draws[.]rds$"),
    all_draw_paths
  )],
  list.files(
    checkpoint_root,
    recursive = TRUE,
    full.names = TRUE
  ),
  runtime_path,
  provenance_path,
  summary_path,
  audit_path,
  failure_path,
  file.path(root, producer),
  selection_path,
  pilot_provenance_path,
  point_path,
  diagnostic_path
)))
manifest_files <- manifest_files[
  file.exists(manifest_files) & !dir.exists(manifest_files)
]
production_manifest <- dplyr::bind_rows(lapply(manifest_files, function(path) {
  tibble::tibble(
    path = if (startsWith(path, paste0(root, "/"))) {
      substring(path, nchar(root) + 2L)
    } else {
      path
    },
    sha256 = artifact_sha256(path),
    bytes = as.numeric(file.info(path)$size),
    producer = producer,
    r_version = as.character(getRversion()),
    inference_status =
      "PRODUCTION — 1,000 successful joint bootstrap refits",
    production_contract_sha256 = production_contract_sha256
  )
}))
write_csv_artifact(production_manifest, manifest_path, producer = producer)

message(
  "H01 changed-family production bootstrap completed: ",
  nrow(new_audits),
  " targets × ",
  successful_refits,
  " used refits; 120 preserved targets unchanged"
)
