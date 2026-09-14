# Run the author-approved H01 METRIC-011 production bootstrap in isolation.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
base::source(file.path(root, "scripts/pipeline/paths_io.R"))
base::source(file.path(root, "scripts/hypotheses/H01/h01_contract.R"))
base::source(file.path(root, "scripts/hypotheses/H01/h01_modeling.R"))

if (!identical(as.character(getRversion()), "4.6.1")) {
  h01_abort(
    "The H01 METRIC-011 production bootstrap requires R 4.6.1; found %s",
    as.character(getRversion())
  )
}
project_library <- normalizePath(
  file.path(
    root,
    "renv/library/macos/R-4.6/aarch64-apple-darwin23"
  ),
  winslash = "/",
  mustWork = TRUE
)
if (
  !project_library %in% normalizePath(
    .libPaths(),
    winslash = "/",
    mustWork = TRUE
  ) ||
    !requireNamespace("lme4", quietly = TRUE) ||
    !requireNamespace("performance", quietly = TRUE)
) {
  h01_abort(
    paste0(
      "The H01 METRIC-011 production workers require the pinned project ",
      "R 4.6 library via R_LIBS_USER: %s"
    ),
    project_library
  )
}

producer <- paste0(
  "scripts/hypotheses/H01/",
  "run_h01_l10_METRIC011_bootstrap_production.R"
)
metric_id <- "l10_mean_medi"
successful_refits <- as.integer(Sys.getenv(
  "H01_L10_PRODUCTION_REFITS",
  unset = "1000"
))
production_cores <- as.integer(Sys.getenv(
  "H01_L10_PRODUCTION_CORES",
  unset = "4"
))
author_approval <- Sys.getenv("H01_L10_AUTHOR_APPROVAL", unset = "")
validate_only <- identical(
  tolower(Sys.getenv("H01_L10_PRODUCTION_VALIDATE_ONLY", unset = "false")),
  "true"
)
approval_token <- "accepted_2026-08-12"
production_label <-
  "PRODUCTION — 1,000 successful joint bootstrap refits"

if (successful_refits != 1000L) {
  h01_abort("H01 METRIC-011 production requires exactly 1,000 refits")
}
if (!is.finite(production_cores) || production_cores < 1L) {
  h01_abort("H01_L10_PRODUCTION_CORES must be a positive integer")
}
if (!identical(author_approval, approval_token)) {
  h01_abort(
    paste0(
      "H01 METRIC-011 production requires the explicit author approval ",
      "token `", approval_token, "`"
    )
  )
}

audit_root <- file.path(
  root,
  "audit/hypotheses/H01/l10_METRIC-011"
)
point_root <- file.path(audit_root, "point_refit")
pilot_root <- file.path(audit_root, "bootstrap_pilot")
gate_root <- file.path(audit_root, "author_gate")
production_root <- file.path(audit_root, "bootstrap_production")
incident_path <- file.path(
  production_root,
  "H01_METRIC-011_execution_incident.md"
)
draw_root <- file.path(production_root, "draws")
checkpoint_root <- file.path(production_root, "checkpoints")
diagnostic_root <- file.path(production_root, "diagnostics")
table_root <- file.path(production_root, "tables")
manifest_path <- file.path(
  production_root,
  "H01_METRIC-011_bootstrap_production_manifest.csv"
)
invisible(vapply(
  c(
    draw_root,
    checkpoint_root,
    diagnostic_root,
    table_root
  ),
  dir.create,
  logical(1),
  recursive = TRUE,
  showWarnings = FALSE
))

pin_paths <- c(
  coordinator_authorization = paste0(
    "audit/decisions/",
    "h01_metric011_l10_production_authorization.md"
  ),
  coordinator_gate =
    "audit/decisions/h01_metric011_l10_production_gate.md",
  metric_decision =
    "audit/decisions/l10_numerical_zero_normalization.md",
  author_gate = paste0(
    "audit/hypotheses/H01/l10_METRIC-011/",
    "H01_METRIC-011_author_gate.md"
  ),
  author_gate_manifest = paste0(
    "audit/hypotheses/H01/l10_METRIC-011/author_gate/",
    "H01_METRIC-011_author_gate_manifest.csv"
  ),
  point_manifest = paste0(
    "audit/hypotheses/H01/l10_METRIC-011/point_refit/",
    "artifacts/12_manifests/H01_model_results_artifacts.csv"
  ),
  pilot_manifest = paste0(
    "audit/hypotheses/H01/l10_METRIC-011/bootstrap_pilot/",
    "H01_METRIC-011_bootstrap_pilot_manifest.csv"
  )
)
pin_sha256 <- c(
  coordinator_authorization =
    "ab0764bb55144d9c69caafc8373010f497561757ad2c576d88e32b450817ed4f",
  coordinator_gate =
    "30b43ef447a2310edd05b245c0c36d0c6a6966f2394f1a149db13d4afe384445",
  metric_decision =
    "23b9f70d1d16f7fd3ebbdbc57aaf78c0a701fe1f9d22bd667d926cd320d40797",
  author_gate =
    "2c1743203d40b0405563ecfed0b8d212eb55d66af2f2f67741f60e8e1ba3e4cc",
  author_gate_manifest =
    "4ea6b40205796078821bbd35911fb26e3a793ead4f5104c42e785b5b35c08c29",
  point_manifest =
    "51d3462833724af0238810b88b6d9e75e93d2d3a0aebcb2f5077e8adb0354346",
  pilot_manifest =
    "7d7970368b94a0dfa5dcbce7b3b42fe712f11bdd2475c8d5addb7426a53d4f0e"
)
absolute_pin_paths <- stats::setNames(
  file.path(root, unname(pin_paths)),
  names(pin_paths)
)
if (
  !all(file.exists(absolute_pin_paths)) ||
    !identical(
      unname(vapply(absolute_pin_paths, artifact_sha256, character(1))),
      unname(pin_sha256)
    )
) {
  h01_abort("A verified H01 METRIC-011 gate identity changed")
}

gate_summary <- readr::read_csv(
  file.path(gate_root, "H01_METRIC-011_gate_summary.csv"),
  show_col_types = FALSE,
  progress = FALSE
)
if (
  nrow(gate_summary) != 1L ||
    gate_summary$gate_status !=
      "STOP_AUTHOR_GATE_PRODUCTION_BOOTSTRAP_APPROVAL" ||
    gate_summary$pilot_targets != 4L ||
    gate_summary$pilot_successful_refits_per_target != 50L ||
    gate_summary$pilot_failed_refits != 0L ||
    gate_summary$pilot_warning_refits != 0L ||
    gate_summary$l10_support_changes != 0L ||
    gate_summary$non_l10_BH_support_changes != 0L ||
    gate_summary$major_diagnostic_failures != 0L
) {
  h01_abort("The verified H01 METRIC-011 author gate is not eligible")
}

pilot_provenance_path <- file.path(
  pilot_root,
  "diagnostics/H01_METRIC-011_bootstrap_pilot_provenance.csv"
)
pilot_provenance <- readr::read_csv(
  pilot_provenance_path,
  show_col_types = FALSE,
  progress = FALSE
)
if (
  nrow(pilot_provenance) != 1L ||
    pilot_provenance$pilot_status !=
      "PASS_AWAITING_AUTHOR_PRODUCTION_APPROVAL" ||
    pilot_provenance$planned_targets != 4L ||
    pilot_provenance$completed_targets != 4L ||
    pilot_provenance$successful_refits_per_target != 50L ||
    pilot_provenance$total_failed_refits != 0L ||
    pilot_provenance$total_warning_refits != 0L
) {
  h01_abort("The verified METRIC-011 pilot is not production-eligible")
}

spec <- h01_metric_registry() |>
  dplyr::filter(.data$metric_id == !!metric_id)
if (
  nrow(spec) != 1L ||
    spec$metric_order != 5L ||
    spec$response_family != "gaussian" ||
    spec$response_transform != "log10_offset_0.1" ||
    spec$effect_scale != "ratio"
) {
  h01_abort("The approved H01 L10-mean model contract is not active")
}
run_registry <- h01_run_registry() |>
  dplyr::filter(.data$data_scenario_id == "main")
if (nrow(run_registry) != 4L) {
  h01_abort("H01 METRIC-011 production requires four main-data targets")
}

point_results_path <- file.path(
  point_root,
  "artifacts/09_tables/H01/H01_r2_point_summaries.csv"
)
point_diagnostics_path <- file.path(
  point_root,
  "artifacts/08_diagnostics/H01/H01_model_diagnostics.csv"
)
point_results <- readr::read_csv(
  point_results_path,
  show_col_types = FALSE,
  progress = FALSE
)
point_diagnostics <- readr::read_csv(
  point_diagnostics_path,
  show_col_types = FALSE,
  progress = FALSE
)
if (
  nrow(point_results) != 4L ||
    nrow(point_diagnostics) != 4L ||
    any(point_results$metric_id != metric_id) ||
    any(point_diagnostics$metric_id != metric_id) ||
    any(point_diagnostics$diagnostic_status == "FAIL_MAJOR_GATE")
) {
  h01_abort("The isolated METRIC-011 point package failed preflight")
}

protected_path <- file.path(
  gate_root,
  "H01_METRIC-011_protected_artifact_baseline.csv"
)
protected <- readr::read_csv(
  protected_path,
  show_col_types = FALSE,
  progress = FALSE
)
protected_paths <- file.path(root, protected$path)
if (
  !all(file.exists(protected_paths)) ||
    !identical(
      unname(vapply(protected_paths, artifact_sha256, character(1))),
      unname(protected$sha256)
    )
) {
  h01_abort("A protected H01 artifact changed before L10 production")
}

production_contract_sha256 <- digest::digest(
  list(
    pilot_contract_sha256 = pilot_provenance$pilot_contract_sha256,
    author_approval = approval_token,
    coordinator_authorization_sha256 =
      pin_sha256[["coordinator_authorization"]],
    coordinator_gate_sha256 = pin_sha256[["coordinator_gate"]],
    author_gate_sha256 = pin_sha256[["author_gate"]],
    author_gate_manifest_sha256 = pin_sha256[["author_gate_manifest"]],
    point_manifest_sha256 = pin_sha256[["point_manifest"]],
    pilot_manifest_sha256 = pin_sha256[["pilot_manifest"]],
    metric_id = metric_id,
    response_family = spec$response_family,
    response_transform = spec$response_transform,
    effect_scale = spec$effect_scale,
    successful_refits = successful_refits,
    target_run_ids = run_registry$run_id,
    execution_incident_sha256 = artifact_sha256(incident_path),
    project_library = project_library,
    lme4_version = as.character(utils::packageVersion("lme4")),
    performance_version = as.character(
      utils::packageVersion("performance")
    ),
    h01_contract_sha256 = artifact_sha256(file.path(
      root,
      "scripts/hypotheses/H01/h01_contract.R"
    )),
    h01_modeling_sha256 = artifact_sha256(file.path(
      root,
      "scripts/hypotheses/H01/h01_modeling.R"
    ))
  ),
  algo = "sha256",
  serialize = TRUE
)

if (validate_only) {
  message(
    "H01 METRIC-011 production preflight passed for 4 targets × ",
    successful_refits,
    " successful refits; contract ",
    production_contract_sha256
  )
  quit(save = "no", status = 0L)
}

add_identity <- function(data, run) {
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
    inference_status = production_label,
    production_contract_sha256 = production_contract_sha256
  )
  dplyr::bind_cols(identity[rep(1L, nrow(data)), , drop = FALSE], data)
}

summary_rows <- list()
audit_rows <- list()
failure_rows <- list()
runtime_rows <- list()
production_started <- Sys.time()

for (run_index in seq_len(nrow(run_registry))) {
  run <- run_registry[run_index, , drop = FALSE]
  point_directory <- file.path(
    point_root,
    "artifacts/07_models/H01",
    run$data_scenario_id,
    run$placement,
    run$sample_scenario
  )
  bundle_path <- file.path(
    point_directory,
    paste0(metric_id, "_models.rds")
  )
  frame_path <- file.path(
    point_directory,
    paste0(metric_id, "_model_frame.rds")
  )
  if (!file.exists(bundle_path) || !file.exists(frame_path)) {
    h01_abort("Missing isolated point fit for `%s`", run$run_id)
  }
  bundle <- readRDS(bundle_path)
  frame <- readRDS(frame_path)
  if (
    !identical(bundle$spec$metric_id, metric_id) ||
      !identical(bundle$spec$response_family, spec$response_family) ||
      !identical(
        bundle$spec$response_transform,
        spec$response_transform
      ) ||
      !identical(bundle$frame_keys, frame$.model_row_id)
  ) {
    h01_abort("Point-model identity mismatch in `%s`", run$run_id)
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
  target_directory <- file.path(
    draw_root,
    run$placement,
    run$sample_scenario
  )
  checkpoint_directory <- file.path(
    checkpoint_root,
    run$placement,
    run$sample_scenario
  )
  dir.create(target_directory, recursive = TRUE, showWarnings = FALSE)
  dir.create(checkpoint_directory, recursive = TRUE, showWarnings = FALSE)
  draws_path <- file.path(target_directory, paste0(metric_id, "_draws.rds"))
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
    production <- checkpoint$production
    runtime <- checkpoint$runtime
    checkpoint_status <- "REUSED_COMPLETED_TARGET_CHECKPOINT"
  } else {
    message("Bootstrapping H01 METRIC-011 target: ", run$run_id)
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
    process_elapsed <- proc.time() - process_started
    completed <- Sys.time()
    draws <- production$draws
    if (
      nrow(draws) != successful_refits ||
        production$audit$successful_refits < successful_refits ||
        production$audit$used_refits != successful_refits ||
        production$audit$status != "PASS"
    ) {
      h01_abort("Production target `%s` did not pass", run$run_id)
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
      production = production,
      runtime = runtime
    )
    write_rds_artifact(checkpoint, checkpoint_path, producer = producer)
    checkpoint_status <- "WROTE_COMPLETED_TARGET_CHECKPOINT"
  }

  if (
    nrow(draws) != successful_refits ||
      production$audit$used_refits != successful_refits ||
      production$audit$status != "PASS"
  ) {
    h01_abort("Production checkpoint mismatch in `%s`", run$run_id)
  }
  point <- point_results |>
    dplyr::filter(
      .data$run_id == run$run_id,
      .data$metric_id == !!metric_id
    )
  summary_rows[[run_index]] <- add_identity(
    h01_summarize_bootstrap(point, draws),
    run
  )
  audit_rows[[run_index]] <- add_identity(production$audit, run)
  if (nrow(production$failures) > 0L) {
    failure_rows[[length(failure_rows) + 1L]] <- add_identity(
      production$failures,
      run
    )
  }
  runtime_rows[[run_index]] <- add_identity(
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
}

summaries <- dplyr::bind_rows(summary_rows)
audits <- dplyr::bind_rows(audit_rows)
failures <- if (length(failure_rows) == 0L) {
  tibble::tibble(
    run_id = character(),
    data_scenario_id = character(),
    placement = character(),
    sample_scenario = character(),
    analytical_role = character(),
    metric_order = integer(),
    metric_id = character(),
    analysis_unit = character(),
    response_family = character(),
    response_transform = character(),
    inference_status = character(),
    production_contract_sha256 = character(),
    attempt = integer(),
    error = character(),
    warning_count = integer(),
    warnings = character()
  )
} else {
  dplyr::bind_rows(failure_rows)
}
runtimes <- dplyr::bind_rows(runtime_rows)
if (
  nrow(audits) != 4L ||
    any(audits$status != "PASS") ||
    any(audits$successful_refits < successful_refits) ||
    any(audits$used_refits != successful_refits) ||
    any(runtimes$successful_draws != successful_refits) ||
    any(summaries$bootstrap_successful_used != successful_refits)
) {
  h01_abort("H01 METRIC-011 production aggregate validation failed")
}

summary_path <- file.path(
  table_root,
  "H01_METRIC-011_bootstrap_production_r2_summaries.csv"
)
audit_path <- file.path(
  diagnostic_root,
  "H01_METRIC-011_bootstrap_production_audit.csv"
)
failure_path <- file.path(
  diagnostic_root,
  "H01_METRIC-011_bootstrap_production_failures.csv"
)
runtime_path <- file.path(
  diagnostic_root,
  "H01_METRIC-011_bootstrap_production_runtime.csv"
)
provenance_path <- file.path(
  diagnostic_root,
  "H01_METRIC-011_bootstrap_production_provenance.csv"
)
write_csv_artifact(summaries, summary_path, producer = producer)
write_csv_artifact(audits, audit_path, producer = producer)
write_csv_artifact(failures, failure_path, producer = producer)
write_csv_artifact(runtimes, runtime_path, producer = producer)

if (
  !all(file.exists(protected_paths)) ||
    !identical(
      unname(vapply(protected_paths, artifact_sha256, character(1))),
      unname(protected$sha256)
    )
) {
  h01_abort("A protected H01 artifact changed during L10 production")
}

production_completed <- Sys.time()
provenance <- tibble::tibble(
  inference_status = production_label,
  author_approval = paste0(
    "Explicit author reply `accept` in H01 task on 2026-08-12; ",
    "all three H01-012 dispositions accepted"
  ),
  author_approval_token = approval_token,
  production_contract_sha256 = production_contract_sha256,
  pilot_contract_sha256 = pilot_provenance$pilot_contract_sha256,
  coordinator_authorization_sha256 =
    pin_sha256[["coordinator_authorization"]],
  coordinator_gate_sha256 = pin_sha256[["coordinator_gate"]],
  r_version = as.character(getRversion()),
  lme4_version = as.character(utils::packageVersion("lme4")),
  performance_version = as.character(
    utils::packageVersion("performance")
  ),
  successful_refits_per_target = successful_refits,
  planned_targets = 4L,
  completed_targets = nrow(audits),
  total_attempted_refits = sum(audits$attempted_refits),
  total_successful_refits = sum(audits$successful_refits),
  total_used_refits = sum(audits$used_refits),
  total_failed_refits = sum(audits$failed_refits),
  total_warning_refits = sum(audits$warning_refits),
  preproduction_failed_attempts = 1L,
  preproduction_incident_path = substring(
    incident_path,
    nchar(root) + 2L
  ),
  preproduction_incident_sha256 = artifact_sha256(incident_path),
  protected_artifact_hashes_unchanged = TRUE,
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
    "H01_L10_AUTHOR_APPROVAL=", approval_token,
    " R_LIBS_USER=", project_library,
    " H01_L10_PRODUCTION_REFITS=", successful_refits,
    " H01_L10_PRODUCTION_CORES=", production_cores,
    " Rscript --vanilla ", producer
  ),
  point_manifest_sha256 = pin_sha256[["point_manifest"]],
  pilot_manifest_sha256 = pin_sha256[["pilot_manifest"]],
  producer_path = producer,
  producer_sha256 = artifact_sha256(file.path(root, producer)),
  production_status = "PASS",
  completed_utc = format(
    production_completed,
    tz = "UTC",
    usetz = TRUE
  )
)
write_csv_artifact(provenance, provenance_path, producer = producer)

manifest_files <- sort(unique(c(
  unlist(lapply(
    c(
      draw_root,
      checkpoint_root,
      diagnostic_root,
      table_root
    ),
    list.files,
    recursive = TRUE,
    full.names = TRUE
  )),
  file.path(root, producer),
  file.path(root, "scripts/hypotheses/H01/h01_contract.R"),
  file.path(root, "scripts/hypotheses/H01/h01_modeling.R"),
  file.path(root, "tests/hypotheses/H01/test_h01_l10_METRIC011_gate.R"),
  absolute_pin_paths,
  point_results_path,
  point_diagnostics_path,
  pilot_provenance_path,
  protected_path,
  incident_path
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
    inference_status = production_label,
    production_contract_sha256 = production_contract_sha256
  )
}))
write_csv_artifact(manifest, manifest_path, producer = producer)

message(
  "H01 METRIC-011 production bootstrap completed: four targets × ",
  successful_refits,
  " used joint refits; protected artifacts unchanged"
)
