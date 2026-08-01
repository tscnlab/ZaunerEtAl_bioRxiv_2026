# Run the COMPUTE-001 pilot for the changed H01 response-family targets.

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
    "The H01 bootstrap pilot requires R 4.6.1; found %s",
    as.character(getRversion())
  )
}

producer <-
  "scripts/hypotheses/H01/run_h01_response_family_bootstrap_pilot.R"
pilot_label <- "PILOT — NOT FOR INFERENCE OR MANUSCRIPT REPORTING"
metric_id <- "duration_below_10_pre_sleep"
successful_refits <- as.integer(Sys.getenv(
  "H01_PILOT_REFITS",
  unset = "50"
))
pilot_cores <- as.integer(Sys.getenv(
  "H01_PILOT_CORES",
  unset = "4"
))
if (!successful_refits %in% c(50L, 100L)) {
  h01_abort("H01_PILOT_REFITS must be 50 or 100 under COMPUTE-001")
}
if (!is.finite(pilot_cores) || pilot_cores < 1L) {
  h01_abort("H01_PILOT_CORES must be a positive integer")
}

spec <- h01_metric_registry() |>
  dplyr::filter(.data$metric_id == !!metric_id)
if (
  nrow(spec) != 1L ||
    spec$response_family != "gaussian" ||
    spec$response_transform != "identity" ||
    spec$effect_scale != "difference"
) {
  h01_abort("The selected H01 pre-sleep Gaussian contract is not active")
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
  h01_abort("The H01 candidate selection does not authorize this pilot")
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
  h01_abort("The selected H01 pilot target failed its point-model gate")
}

pilot_model_root <- file.path(
  root,
  "artifacts/07_models/H01/bootstrap_pilot/response_family_change"
)
pilot_diagnostic_root <- file.path(
  root,
  "artifacts/08_diagnostics/H01/bootstrap_pilot/response_family_change"
)
pilot_table_root <- file.path(
  root,
  "artifacts/09_tables/H01/bootstrap_pilot/response_family_change"
)
pilot_manifest_path <- file.path(
  root,
  "artifacts/12_manifests/H01_response_family_bootstrap_pilot_artifacts.csv"
)
invisible(vapply(
  c(
    pilot_model_root,
    pilot_diagnostic_root,
    pilot_table_root,
    dirname(pilot_manifest_path)
  ),
  dir.create,
  logical(1),
  recursive = TRUE,
  showWarnings = FALSE
))

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
  h01_abort("Pinned H01 model-data manifests changed before the pilot")
}

pilot_contract_sha256 <- digest::digest(
  list(
    metric_id = metric_id,
    response_family = spec$response_family,
    response_transform = spec$response_transform,
    successful_refits = successful_refits,
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

point_path <- file.path(
  root,
  "artifacts/09_tables/H01/H01_r2_point_summaries.csv"
)
point_results <- readr::read_csv(point_path, show_col_types = FALSE)
run_registry <- h01_run_registry()

h01_pilot_identity <- function(data, run) {
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
    response_transform = spec$response_transform,
    inference_status = pilot_label,
    pilot_contract_sha256 = pilot_contract_sha256
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

for (run_index in seq_len(nrow(run_registry))) {
  run <- run_registry[run_index, , drop = FALSE]
  canonical_directory <- file.path(
    root,
    "artifacts/07_models/H01",
    run$data_scenario_id,
    run$placement,
    run$sample_scenario
  )
  bundle_path <- file.path(
    canonical_directory,
    paste0(metric_id, "_models.rds")
  )
  frame_path <- file.path(
    canonical_directory,
    paste0(metric_id, "_model_frame.rds")
  )
  bundle <- readRDS(bundle_path)
  frame <- readRDS(frame_path)
  if (
    !identical(bundle$spec$response_family, spec$response_family) ||
      !identical(bundle$spec$response_transform, spec$response_transform) ||
      !identical(bundle$frame_keys, frame$.model_row_id)
  ) {
    h01_abort("H01 pilot point-model identity mismatch in `%s`", run$run_id)
  }
  target_contract_sha256 <- digest::digest(
    list(
      pilot_contract_sha256 = pilot_contract_sha256,
      run_id = run$run_id,
      bundle_sha256 = artifact_sha256(bundle_path),
      frame_sha256 = artifact_sha256(frame_path)
    ),
    algo = "sha256",
    serialize = TRUE
  )
  target_directory <- file.path(
    pilot_model_root,
    run$data_scenario_id,
    run$placement,
    run$sample_scenario
  )
  dir.create(target_directory, recursive = TRUE, showWarnings = FALSE)
  draws_path <- file.path(target_directory, paste0(metric_id, "_draws.rds"))
  checkpoint_path <- file.path(
    target_directory,
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
    if (nrow(draws) != successful_refits) {
      h01_abort("H01 pilot checkpoint draw count mismatch in `%s`", run$run_id)
    }
    pilot <- checkpoint$pilot
    runtime <- checkpoint$runtime
    checkpoint_status <- "REUSED_COMPLETED_TARGET_CHECKPOINT"
  } else {
    message("Piloting H01 target: ", run$run_id, " / ", metric_id)
    started <- Sys.time()
    process_started <- proc.time()
    seed <- h01_primary_seed(
      spec$metric_order,
      run$data_scenario_id,
      run$placement,
      run$sample_scenario
    ) + 9000000L
    pilot <- h01_bootstrap_r2(
      bundle,
      frame,
      seed = seed,
      successful_refits = successful_refits,
      cores = pilot_cores
    )
    process_elapsed <- proc.time() - process_started
    completed <- Sys.time()
    draws <- pilot$draws
    if (
      nrow(draws) != successful_refits ||
        pilot$audit$successful_refits < successful_refits ||
        pilot$audit$used_refits != successful_refits ||
        pilot$audit$status != "PASS"
    ) {
      h01_abort("H01 pilot target did not reach its success requirement")
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
      requested_parallel_workers = pilot_cores,
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
      pilot = pilot,
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
  summary_rows[[summary_index]] <- h01_pilot_identity(
    h01_summarize_bootstrap(point, draws),
    run
  )
  summary_index <- summary_index + 1L
  audit_rows[[audit_index]] <- h01_pilot_identity(pilot$audit, run)
  audit_index <- audit_index + 1L
  if (nrow(pilot$failures) > 0L) {
    failure_rows[[failure_index]] <- h01_pilot_identity(
      pilot$failures,
      run
    )
    failure_index <- failure_index + 1L
  }
  runtime_rows[[runtime_index]] <- h01_pilot_identity(
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

summaries <- dplyr::bind_rows(summary_rows)
audits <- dplyr::bind_rows(audit_rows)
failures <- dplyr::bind_rows(failure_rows)
runtimes <- dplyr::bind_rows(runtime_rows)
if (
  nrow(audits) != 8L ||
    any(audits$status != "PASS") ||
    any(audits$used_refits < successful_refits) ||
    any(runtimes$successful_draws != successful_refits) ||
    any(summaries$bootstrap_successful_used < successful_refits)
) {
  h01_abort("H01 pilot aggregate validation failed")
}

summary_path <- file.path(
  pilot_table_root,
  "H01_response_family_bootstrap_pilot_r2_summaries.csv"
)
audit_path <- file.path(
  pilot_diagnostic_root,
  "H01_response_family_bootstrap_pilot_audit.csv"
)
failure_path <- file.path(
  pilot_diagnostic_root,
  "H01_response_family_bootstrap_pilot_failures.csv"
)
runtime_path <- file.path(
  pilot_diagnostic_root,
  "H01_response_family_bootstrap_pilot_runtime.csv"
)
provenance_path <- file.path(
  pilot_diagnostic_root,
  "H01_response_family_bootstrap_pilot_provenance.csv"
)
write_csv_artifact(summaries, summary_path, producer = producer)
write_csv_artifact(audits, audit_path, producer = producer)
write_csv_artifact(failures, failure_path, producer = producer)
write_csv_artifact(runtimes, runtime_path, producer = producer)
write_csv_artifact(
  tibble::tibble(
    inference_status = pilot_label,
    pilot_contract_sha256 = pilot_contract_sha256,
    r_version = as.character(getRversion()),
    lme4_version = as.character(utils::packageVersion("lme4")),
    performance_version = as.character(utils::packageVersion("performance")),
    successful_refits_per_target = successful_refits,
    planned_targets = 8L,
    completed_targets = nrow(audits),
    total_attempted_refits = sum(audits$attempted_refits),
    total_successful_refits = sum(audits$successful_refits),
    total_used_refits = sum(audits$used_refits),
    total_failed_refits = sum(audits$failed_refits),
    total_warning_refits = sum(audits$warning_refits),
    total_wall_seconds = sum(runtimes$wall_seconds),
    checkpoint_granularity = "completed run-metric target",
    checkpoint_directory = substring(
      pilot_model_root,
      nchar(root) + 2L
    ),
    command = paste0(
      "H01_PILOT_REFITS=", successful_refits,
      " H01_PILOT_CORES=", pilot_cores,
      " Rscript --vanilla ", producer
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
    pilot_status = "PASS_AWAITING_AUTHOR_PRODUCTION_APPROVAL",
    completed_utc = format(Sys.time(), tz = "UTC", usetz = TRUE)
  ),
  provenance_path,
  producer = producer
)

manifest_roots <- c(
  pilot_model_root,
  pilot_diagnostic_root,
  pilot_table_root
)
manifest_files <- sort(unique(c(
  unlist(lapply(
    manifest_roots,
    list.files,
    recursive = TRUE,
    full.names = TRUE
  )),
  file.path(root, producer),
  selection_path,
  point_path,
  diagnostic_path
)))
manifest_files <- manifest_files[
  file.exists(manifest_files) & !dir.exists(manifest_files)
]
manifest <- dplyr::bind_rows(lapply(manifest_files, function(path) {
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
    inference_status = pilot_label,
    pilot_contract_sha256 = pilot_contract_sha256
  )
}))
write_csv_artifact(manifest, pilot_manifest_path, producer = producer)

message(
  "H01 COMPUTE-001 response-family pilot completed: ",
  nrow(audits),
  " targets × ",
  successful_refits,
  " used refits; awaiting author production approval"
)
