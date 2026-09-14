# Run the author-approved H01 METRIC-010 MDER production bootstrap.

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
    "The H01 METRIC-010 production bootstrap requires R 4.6.1; found %s",
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
normalized_libraries <- normalizePath(
  .libPaths(),
  winslash = "/",
  mustWork = TRUE
)
if (
  !project_library %in% normalized_libraries ||
    !requireNamespace("lme4", quietly = TRUE) ||
    !requireNamespace("performance", quietly = TRUE)
) {
  h01_abort(
    paste0(
      "The H01 METRIC-010 production bootstrap requires the pinned ",
      "project R library: %s"
    ),
    project_library
  )
}

producer <- paste0(
  "scripts/hypotheses/H01/",
  "run_h01_mder_METRIC010_bootstrap_production.R"
)
metric_id <- "mder_mean_of_viable_ratios"
production_label <- "PRODUCTION - 1,000 successful joint bootstrap refits"
successful_refits <- as.integer(Sys.getenv(
  "H01_MDER_PRODUCTION_REFITS",
  unset = "1000"
))
production_cores <- as.integer(Sys.getenv(
  "H01_MDER_PRODUCTION_CORES",
  unset = "4"
))
approval_token <- "approved_2026-08-31"
author_approval <- Sys.getenv("H01_MDER_PRODUCTION_APPROVAL", unset = "")
validate_only <- identical(
  tolower(Sys.getenv(
    "H01_MDER_PRODUCTION_VALIDATE_ONLY",
    unset = "false"
  )),
  "true"
)
if (!identical(successful_refits, 1000L)) {
  h01_abort("H01_MDER_PRODUCTION_REFITS must equal 1000")
}
if (!is.finite(production_cores) || production_cores < 1L) {
  h01_abort("H01_MDER_PRODUCTION_CORES must be a positive integer")
}
if (!identical(author_approval, approval_token)) {
  h01_abort(
    paste0(
      "The H01 METRIC-010 production bootstrap requires author approval ",
      "token `",
      approval_token,
      "`"
    )
  )
}

relative_to_root <- function(path) {
  normalized <- normalizePath(path, winslash = "/", mustWork = TRUE)
  if (startsWith(normalized, paste0(root, "/"))) {
    return(substring(normalized, nchar(root) + 2L))
  }
  normalized
}

metric_root <- file.path(
  root,
  "audit/hypotheses/H01/mder_METRIC-010"
)
point_root <- file.path(metric_root, "point_refit_repaired_gap")
pilot_root <- file.path(metric_root, "bootstrap_pilot")
production_root <- file.path(metric_root, "bootstrap_production")
code_root <- file.path(production_root, "code")
draw_root <- file.path(production_root, "draws")
checkpoint_root <- file.path(production_root, "checkpoints")
diagnostic_root <- file.path(production_root, "diagnostics")
table_root <- file.path(production_root, "tables")

pin_paths <- c(
  production_authorization = paste0(
    "audit/hypotheses/H01/mder_METRIC-010/",
    "H01_METRIC-010_production_authorization.md"
  ),
  central_pilot_authority = paste0(
    "audit/report_harmonization/",
    "report018_h01_metric010_point_baseline_acceptance_and_pilot_",
    "authority.md"
  ),
  metric_decision = "audit/decisions/mder_mean_of_viable_ratios.md",
  compute_policy = "audit/decisions/bootstrap_execution_policy.md",
  point_acceptance = paste0(
    "audit/hypotheses/H01/mder_METRIC-010/",
    "H01_METRIC-010_point_baseline_acceptance.md"
  ),
  point_manifest = paste0(
    "audit/hypotheses/H01/mder_METRIC-010/point_refit_repaired_gap/",
    "artifacts/12_manifests/H01_model_results_artifacts.csv"
  ),
  point_results = paste0(
    "audit/hypotheses/H01/mder_METRIC-010/point_refit_repaired_gap/",
    "artifacts/09_tables/H01/H01_r2_point_summaries.csv"
  ),
  point_diagnostics = paste0(
    "audit/hypotheses/H01/mder_METRIC-010/point_refit_repaired_gap/",
    "artifacts/08_diagnostics/H01/H01_model_diagnostics.csv"
  ),
  pilot_manifest = paste0(
    "audit/hypotheses/H01/mder_METRIC-010/bootstrap_pilot/",
    "H01_METRIC-010_bootstrap_pilot_manifest.csv"
  ),
  pilot_review = paste0(
    "audit/hypotheses/H01/mder_METRIC-010/bootstrap_pilot/",
    "H01_METRIC-010_bootstrap_pilot_review.md"
  ),
  pilot_audit = paste0(
    "audit/hypotheses/H01/mder_METRIC-010/bootstrap_pilot/diagnostics/",
    "H01_METRIC-010_bootstrap_pilot_audit.csv"
  ),
  pilot_provenance = paste0(
    "audit/hypotheses/H01/mder_METRIC-010/bootstrap_pilot/diagnostics/",
    "H01_METRIC-010_bootstrap_pilot_provenance.csv"
  ),
  primary_rds = "artifacts/06_model_data/H01.rds",
  primary_manifest = "artifacts/12_manifests/H01_model_data_artifacts.csv",
  gap_rds = paste0(
    "artifacts/06_model_data/H01/scenarios/",
    "manuscript_prepared_data/H01.rds"
  ),
  gap_manifest = paste0(
    "artifacts/12_manifests/",
    "H01_manuscript_prepared_data_artifacts.csv"
  )
)
pin_sha256 <- c(
  production_authorization = "f9279a46c73b5feede48adaeee98306a4841183468688446ce91cf09045e33af",
  central_pilot_authority = "fb9a333926928aa1d48732133ceaf5a5f0f55a5794842ed23d3ee9732fcdc536",
  metric_decision = "1664347de976057807fcb5ac6e24bd4b66af1fe32378fabd1f2acafcfc9266de",
  compute_policy = "8bc2f8d31d23dec94b8735b6b913f6886f89fb07adc9d9d33f345e9c2b81871a",
  point_acceptance = "e0681c3488e75059fd5721d3c743843a31f258f55fe680a8d2831d3423c4b7b6",
  point_manifest = "f9e8d2414b1242d3d71510837c9c086791bfd72292b5af615131291e491bd41e",
  point_results = "347a42f6c68070e45cf2431324f31bee958d1ab0148dbcadeb92dc70054ad43b",
  point_diagnostics = "607220a71da9f0df7571b685649b220edea1d7cceb4812285069497d353fdd40",
  pilot_manifest = "deeb5dab9a5b63163f932dfdf4e23cc74ebc6848bd6d4ef8335d921ddd0c8764",
  pilot_review = "a0bdccd82e51fc1d8dac7c4b651a33c0e493fb3c3959f6d839407e7d74ba93da",
  pilot_audit = "790c0c7ed6d285b3a4ef4be7d5610f3db02c03aab394051d86d1303758055a97",
  pilot_provenance = "e16914696a81278195ed01cca175df04884673c3c9e6ee7b5695aa4aa87211d9",
  primary_rds = "0328fe1a698bc13965feb0b68b03ccf0fd20f32b55d6148635811b0d674e0a00",
  primary_manifest = "25978c5d6903e6e835c1aff6a9bc2e7552b85295e8d840d3dd65bbf9b1eb6b72",
  gap_rds = "3c70363fc0468202a431904aa9d9444f2858af2e3add3475a56c872b49a18bd6",
  gap_manifest = "e0d98178ede61b74353e3a654e7f1b53d7e1c915833a2cda74eea45ed02f383b"
)
absolute_pin_paths <- stats::setNames(
  file.path(root, unname(pin_paths)),
  names(pin_paths)
)
if (!all(file.exists(absolute_pin_paths))) {
  h01_abort("A required H01 METRIC-010 production input is missing")
}
actual_pin_sha256 <- vapply(
  absolute_pin_paths,
  artifact_sha256,
  character(1)
)
if (!identical(unname(actual_pin_sha256), unname(pin_sha256))) {
  h01_abort("A sealed H01 METRIC-010 production identity changed")
}

pilot_provenance <- readr::read_csv(
  absolute_pin_paths[["pilot_provenance"]],
  show_col_types = FALSE,
  progress = FALSE
)
pilot_audit <- readr::read_csv(
  absolute_pin_paths[["pilot_audit"]],
  show_col_types = FALSE,
  progress = FALSE
)
if (
  nrow(pilot_provenance) != 1L ||
    pilot_provenance$pilot_status !=
      "PASS_AWAITING_AUTHOR_PRODUCTION_APPROVAL" ||
    pilot_provenance$planned_targets != 8L ||
    pilot_provenance$completed_targets != 8L ||
    pilot_provenance$successful_refits_per_target != 50L ||
    pilot_provenance$total_failed_refits != 0L ||
    pilot_provenance$total_warning_refits != 0L ||
    nrow(pilot_audit) != 8L ||
    any(pilot_audit$status != "PASS") ||
    any(pilot_audit$used_refits != 50L)
) {
  h01_abort("The verified METRIC-010 pilot is not production-eligible")
}

input_contract <- h01_input_contract(root)
if (
  !identical(
    input_contract$main$manifest_sha256,
    pin_sha256[["primary_manifest"]]
  ) ||
    !identical(
      input_contract$manuscript_prepared_data$manifest_sha256,
      pin_sha256[["gap_manifest"]]
    )
) {
  h01_abort("The active H01 input contract is not the accepted contract")
}
objects <- list(
  main = readRDS(absolute_pin_paths[["primary_rds"]]),
  manuscript_prepared_data = readRDS(absolute_pin_paths[["gap_rds"]])
)
for (name in names(objects)) {
  metadata <- objects[[name]]$metadata
  if (
    !identical(metadata$data_scenario_id, name) ||
      !identical(
        metadata$model_implementation_id,
        input_contract$model_implementation_id
      ) ||
      !identical(
        metadata$implementation_contract_sha256,
        input_contract$implementation_contract_sha256
      ) ||
      !identical(
        metadata$shared_implementation_sha256,
        input_contract$shared_implementation_sha256
      )
  ) {
    h01_abort("The current `%s` H01 input metadata failed", name)
  }
}

spec <- h01_metric_registry() |>
  dplyr::filter(.data$metric_id == !!metric_id)
if (
  nrow(spec) != 1L ||
    spec$metric_order != 17L ||
    spec$analysis_unit != "participant_day" ||
    spec$response_family != "gaussian" ||
    spec$response_transform != "identity" ||
    spec$effect_scale != "difference"
) {
  h01_abort("The approved H01 METRIC-010 model contract is not active")
}
run_registry <- h01_run_registry()
if (nrow(run_registry) != 8L || dplyr::n_distinct(run_registry$run_id) != 8L) {
  h01_abort("H01 METRIC-010 production requires exactly eight targets")
}

point_results <- readr::read_csv(
  absolute_pin_paths[["point_results"]],
  show_col_types = FALSE,
  progress = FALSE
)
point_diagnostics <- readr::read_csv(
  absolute_pin_paths[["point_diagnostics"]],
  show_col_types = FALSE,
  progress = FALSE
)
if (
  nrow(point_results) != 8L ||
    nrow(point_diagnostics) != 8L ||
    any(point_results$metric_id != metric_id) ||
    any(point_diagnostics$metric_id != metric_id) ||
    any(point_diagnostics$diagnostic_status == "FAIL_MAJOR_GATE")
) {
  h01_abort("The sealed METRIC-010 point package blocks production")
}

strip_frame_container_metadata <- function(frame) {
  attr(frame, "metric_settings") <- NULL
  frame
}
bridge_rows <- vector("list", nrow(run_registry))
target_inputs <- vector("list", nrow(run_registry))
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
    h01_abort("The sealed point target `%s` is incomplete", run$run_id)
  }
  bundle <- readRDS(bundle_path)
  sealed_frame <- readRDS(frame_path)
  current_frame <- h01_prepare_model_frame(
    objects[[run$data_scenario_id]],
    spec,
    placement = run$placement,
    sample_scenario = run$sample_scenario
  )
  scientific_frame_identical <- identical(
    strip_frame_container_metadata(current_frame),
    strip_frame_container_metadata(sealed_frame)
  )
  metric_settings_identical <- identical(
    attr(current_frame, "metric_settings"),
    attr(sealed_frame, "metric_settings")
  )
  spec_fields <- c(
    "metric_order",
    "metric_id",
    "analysis_unit",
    "response_family",
    "response_transform",
    "effect_scale",
    "lower_bound",
    "upper_bound"
  )
  bundle_spec_identical <- identical(
    unname(as.list(bundle$spec[1L, spec_fields, drop = FALSE])),
    unname(as.list(spec[1L, spec_fields, drop = FALSE]))
  )
  row_keys_identical <- identical(
    bundle$frame_keys,
    current_frame$.model_row_id
  )
  response_values_identical <- identical(
    current_frame$response_value,
    sealed_frame$response_value
  )
  if (
    !scientific_frame_identical ||
      !bundle_spec_identical ||
      !row_keys_identical ||
      !response_values_identical
  ) {
    h01_abort("The current MDER frame differs in `%s`", run$run_id)
  }
  current_scientific_frame_sha256 <- digest::digest(
    strip_frame_container_metadata(current_frame),
    algo = "sha256",
    serialize = TRUE
  )
  bridge_rows[[run_index]] <- tibble::tibble(
    run_id = run$run_id,
    data_scenario_id = run$data_scenario_id,
    placement = run$placement,
    sample_scenario = run$sample_scenario,
    participants = dplyr::n_distinct(current_frame$participant_key),
    participant_days = nrow(current_frame),
    observations = nrow(current_frame),
    sites = dplyr::n_distinct(current_frame$site),
    scientific_frame_identical = scientific_frame_identical,
    model_specification_identical = bundle_spec_identical,
    row_keys_identical = row_keys_identical,
    response_values_identical = response_values_identical,
    container_metric_settings_identical = metric_settings_identical,
    container_difference_classification = if (metric_settings_identical) {
      "NONE"
    } else {
      "NON_ANALYTICAL_METRIC_SETTINGS_ATTRIBUTE_ONLY"
    },
    current_scientific_frame_sha256 = current_scientific_frame_sha256,
    sealed_frame_file_sha256 = artifact_sha256(frame_path),
    sealed_bundle_file_sha256 = artifact_sha256(bundle_path)
  )
  target_inputs[[run_index]] <- list(
    run = run,
    bundle = bundle,
    frame = current_frame,
    bundle_path = bundle_path,
    frame_path = frame_path,
    current_scientific_frame_sha256 = current_scientific_frame_sha256
  )
}
bridge <- dplyr::bind_rows(bridge_rows)
if (
  nrow(bridge) != 8L ||
    any(!bridge$scientific_frame_identical) ||
    any(!bridge$model_specification_identical) ||
    any(!bridge$row_keys_identical) ||
    any(!bridge$response_values_identical) ||
    any(
      !bridge$container_difference_classification %in%
        c("NONE", "NON_ANALYTICAL_METRIC_SETTINGS_ATTRIBUTE_ONLY")
    )
) {
  h01_abort("The H01 METRIC-010 production input bridge failed")
}

production_contract_sha256 <- digest::digest(
  list(
    pilot_contract_sha256 = pilot_provenance$pilot_contract_sha256,
    author_approval_token = approval_token,
    production_authorization_sha256 = pin_sha256[["production_authorization"]],
    metric_decision_sha256 = pin_sha256[["metric_decision"]],
    compute_policy_sha256 = pin_sha256[["compute_policy"]],
    point_manifest_sha256 = pin_sha256[["point_manifest"]],
    pilot_manifest_sha256 = pin_sha256[["pilot_manifest"]],
    metric_id = metric_id,
    metric_order = spec$metric_order,
    response_family = spec$response_family,
    response_transform = spec$response_transform,
    effect_scale = spec$effect_scale,
    successful_refits = successful_refits,
    target_run_ids = run_registry$run_id,
    current_scientific_frame_sha256 = bridge$current_scientific_frame_sha256,
    point_bundle_sha256 = bridge$sealed_bundle_file_sha256,
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
    "H01 METRIC-010 production preflight passed for eight targets x ",
    successful_refits,
    " successful refits; contract ",
    production_contract_sha256
  )
  quit(save = "no", status = 0L)
}

invisible(vapply(
  c(code_root, draw_root, checkpoint_root, diagnostic_root, table_root),
  dir.create,
  logical(1),
  recursive = TRUE,
  showWarnings = FALSE
))
production_code_path <- file.path(code_root, basename(producer))
if (
  !file.copy(file.path(root, producer), production_code_path, overwrite = TRUE)
) {
  h01_abort("The production source snapshot could not be written")
}
if (
  !identical(
    artifact_sha256(production_code_path),
    artifact_sha256(file.path(root, producer))
  )
) {
  h01_abort("The production source snapshot differs from executed source")
}

input_pins <- tibble::tibble(
  name = names(pin_paths),
  path = unname(pin_paths),
  sha256 = unname(actual_pin_sha256),
  bytes = as.numeric(file.info(unname(absolute_pin_paths))$size)
)
input_pins_path <- file.path(
  production_root,
  "H01_METRIC-010_bootstrap_production_input_pins.csv"
)
write_csv_artifact(input_pins, input_pins_path, producer = producer)

canonical_roots <- c(
  file.path(root, "artifacts/07_models/H01"),
  file.path(root, "artifacts/08_diagnostics/H01"),
  file.path(root, "artifacts/09_tables/H01"),
  file.path(root, "artifacts/10_figures/H01"),
  file.path(root, "artifacts/11_source_data/H01")
)
canonical_files <- sort(unique(unlist(lapply(
  canonical_roots,
  list.files,
  recursive = TRUE,
  full.names = TRUE
))))
canonical_files <- canonical_files[
  file.exists(canonical_files) & !dir.exists(canonical_files)
]
report_files <- file.path(
  root,
  c(
    "notebooks/hypotheses/H01.qmd",
    "audit/hypotheses/H01/02_implementation_and_v0_comparison.qmd",
    "audit/hypotheses/H01/H01_analysis_preparation.qmd",
    "_build/nathealth/notebooks/hypotheses/H01.html",
    paste0(
      "_build/nathealth/audit/hypotheses/H01/",
      "02_implementation_and_v0_comparison.html"
    ),
    paste0(
      "_build/nathealth/audit/hypotheses/H01/",
      "H01_analysis_preparation.html"
    ),
    "artifacts/12_manifests/H01_reporting_artifacts.csv",
    "artifacts/12_manifests/H01_stage3_reporting_artifacts.csv"
  )
)
canonical_files <- sort(unique(c(
  canonical_files,
  report_files[file.exists(report_files) & !dir.exists(report_files)]
)))
protected_before <- dplyr::bind_rows(lapply(canonical_files, function(path) {
  tibble::tibble(
    path = relative_to_root(path),
    sha256 = artifact_sha256(path),
    bytes = as.numeric(file.info(path)$size)
  )
}))

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

summary_rows <- vector("list", nrow(run_registry))
audit_rows <- vector("list", nrow(run_registry))
failure_rows <- list()
runtime_rows <- vector("list", nrow(run_registry))
production_started <- Sys.time()

for (run_index in seq_len(nrow(run_registry))) {
  target <- target_inputs[[run_index]]
  run <- target$run
  target_contract_sha256 <- digest::digest(
    list(
      production_contract_sha256 = production_contract_sha256,
      run_id = run$run_id,
      bundle_sha256 = artifact_sha256(target$bundle_path),
      sealed_frame_sha256 = artifact_sha256(target$frame_path),
      current_scientific_frame_sha256 = target$current_scientific_frame_sha256
    ),
    algo = "sha256",
    serialize = TRUE
  )
  target_path <- file.path(
    run$data_scenario_id,
    run$placement,
    run$sample_scenario
  )
  target_draw_root <- file.path(draw_root, target_path)
  target_checkpoint_root <- file.path(checkpoint_root, target_path)
  dir.create(target_draw_root, recursive = TRUE, showWarnings = FALSE)
  dir.create(target_checkpoint_root, recursive = TRUE, showWarnings = FALSE)
  draws_path <- file.path(
    target_draw_root,
    paste0(metric_id, "_draws.rds")
  )
  checkpoint_path <- file.path(
    target_checkpoint_root,
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
    message("Bootstrapping H01 METRIC-010 target: ", run$run_id)
    started <- Sys.time()
    process_started <- proc.time()
    seed <- h01_primary_seed(
      spec$metric_order,
      run$data_scenario_id,
      run$placement,
      run$sample_scenario
    )
    production <- h01_bootstrap_r2(
      target$bundle,
      target$frame,
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
  if (nrow(point) != 1L) {
    h01_abort("Point R-squared row mismatch in `%s`", run$run_id)
  }
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
        draws_path = relative_to_root(draws_path),
        draws_sha256 = artifact_sha256(draws_path),
        draws_bytes = as.numeric(file.info(draws_path)$size),
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
  nrow(audits) != 8L ||
    any(audits$status != "PASS") ||
    any(audits$successful_refits < successful_refits) ||
    any(audits$used_refits != successful_refits) ||
    any(runtimes$successful_draws != successful_refits) ||
    any(summaries$bootstrap_successful_used != successful_refits) ||
    any(summaries$status != "PASS") ||
    any(!is.finite(summaries$conf_low)) ||
    any(!is.finite(summaries$conf_high))
) {
  h01_abort("H01 METRIC-010 production aggregate validation failed")
}

protected_after <- dplyr::bind_rows(lapply(canonical_files, function(path) {
  tibble::tibble(
    path = relative_to_root(path),
    sha256 = artifact_sha256(path),
    bytes = as.numeric(file.info(path)$size)
  )
}))
protected_exact <- identical(protected_before, protected_after)
if (!protected_exact) {
  h01_abort("A canonical H01 artifact changed during MDER production")
}

summary_path <- file.path(
  table_root,
  "H01_METRIC-010_bootstrap_production_r2_summaries.csv"
)
audit_path <- file.path(
  diagnostic_root,
  "H01_METRIC-010_bootstrap_production_audit.csv"
)
failure_path <- file.path(
  diagnostic_root,
  "H01_METRIC-010_bootstrap_production_failures.csv"
)
runtime_path <- file.path(
  diagnostic_root,
  "H01_METRIC-010_bootstrap_production_runtime.csv"
)
bridge_path <- file.path(
  diagnostic_root,
  "H01_METRIC-010_bootstrap_production_input_bridge.csv"
)
protected_before_path <- file.path(
  diagnostic_root,
  "H01_METRIC-010_canonical_H01_before.csv"
)
protected_after_path <- file.path(
  diagnostic_root,
  "H01_METRIC-010_canonical_H01_after.csv"
)
write_csv_artifact(summaries, summary_path, producer = producer)
write_csv_artifact(audits, audit_path, producer = producer)
write_csv_artifact(failures, failure_path, producer = producer)
write_csv_artifact(runtimes, runtime_path, producer = producer)
write_csv_artifact(bridge, bridge_path, producer = producer)
write_csv_artifact(
  protected_before,
  protected_before_path,
  producer = producer
)
write_csv_artifact(protected_after, protected_after_path, producer = producer)

production_completed <- Sys.time()
total_target_wall_seconds <- sum(runtimes$wall_seconds)
production_draw_bytes <- sum(runtimes$draws_bytes)
provenance <- tibble::tibble(
  inference_status = production_label,
  author_approval = paste0(
    "Explicit author reply `approve the 1,000-refit MDER production ",
    "bootstrap` in the H01 task on 2026-08-31"
  ),
  author_approval_token = approval_token,
  production_contract_sha256 = production_contract_sha256,
  pilot_contract_sha256 = pilot_provenance$pilot_contract_sha256,
  production_authorization_sha256 = pin_sha256[["production_authorization"]],
  r_version = as.character(getRversion()),
  lme4_version = as.character(utils::packageVersion("lme4")),
  performance_version = as.character(
    utils::packageVersion("performance")
  ),
  successful_refits_per_target = successful_refits,
  planned_targets = 8L,
  completed_targets = nrow(audits),
  total_attempted_refits = sum(audits$attempted_refits),
  total_successful_refits = sum(audits$successful_refits),
  total_used_refits = sum(audits$used_refits),
  total_failed_refits = sum(audits$failed_refits),
  total_warning_refits = sum(audits$warning_refits),
  total_target_wall_seconds = total_target_wall_seconds,
  total_command_wall_seconds = as.numeric(difftime(
    production_completed,
    production_started,
    units = "secs"
  )),
  requested_parallel_workers = production_cores,
  target_execution = "sequential targets; parallel refits within target",
  checkpoint_granularity = "completed run-metric target",
  checkpoint_targets_written = sum(
    runtimes$checkpoint_status == "WROTE_COMPLETED_TARGET_CHECKPOINT"
  ),
  checkpoint_targets_reused = sum(
    runtimes$checkpoint_status == "REUSED_COMPLETED_TARGET_CHECKPOINT"
  ),
  production_draw_bytes = production_draw_bytes,
  peak_memory_instrumentation = "not instrumented per child process",
  canonical_h01_artifacts_checked = nrow(protected_before),
  canonical_h01_artifacts_unchanged = protected_exact,
  command = paste0(
    "H01_MDER_PRODUCTION_APPROVAL=",
    approval_token,
    " H01_MDER_PRODUCTION_REFITS=",
    successful_refits,
    " H01_MDER_PRODUCTION_CORES=",
    production_cores,
    " Rscript --vanilla ",
    producer
  ),
  current_primary_manifest_sha256 = pin_sha256[["primary_manifest"]],
  current_gap_manifest_sha256 = pin_sha256[["gap_manifest"]],
  point_manifest_sha256 = pin_sha256[["point_manifest"]],
  pilot_manifest_sha256 = pin_sha256[["pilot_manifest"]],
  producer_sha256 = artifact_sha256(file.path(root, producer)),
  production_status = "PASS_PENDING_INTEGRATION_VERIFICATION",
  completed_utc = format(
    production_completed,
    tz = "UTC",
    usetz = TRUE
  )
)
provenance_path <- file.path(
  diagnostic_root,
  "H01_METRIC-010_bootstrap_production_provenance.csv"
)
write_csv_artifact(provenance, provenance_path, producer = producer)

format_interval <- function(estimate, conf_low, conf_high) {
  estimate[abs(estimate) < 0.0005] <- 0
  conf_low[abs(conf_low) < 0.0005] <- 0
  conf_high[abs(conf_high) < 0.0005] <- 0
  sprintf("%.3f [%.3f, %.3f]", estimate, conf_low, conf_high)
}
component_levels <- c(
  "marginal_r2",
  "conditional_r2",
  "participant_associated_share",
  "site_part_r2",
  "photoperiod_part_r2",
  "latitude_part_r2"
)
component_labels <- c(
  marginal_r2 = "Marginal R²",
  conditional_r2 = "Conditional R²",
  participant_associated_share = "Participant-associated share",
  site_part_r2 = "Site part R²",
  photoperiod_part_r2 = "Photoperiod part R²",
  latitude_part_r2 = "Latitude part R²"
)
review_table <- summaries |>
  dplyr::filter(.data$measure %in% component_levels) |>
  dplyr::mutate(
    Dataset = dplyr::if_else(
      data_scenario_id == "main",
      "Primary dataset",
      "Gap-timing-unaware dataset"
    ),
    Placement = dplyr::if_else(
      placement == "glasses",
      "Near eye",
      "Chest"
    ),
    Sample = dplyr::if_else(
      sample_scenario == "all_available",
      "All available",
      "Paired/common"
    ),
    component = unname(component_labels[measure]),
    value = format_interval(estimate, conf_low, conf_high)
  ) |>
  dplyr::select(Dataset, Placement, Sample, component, value) |>
  tidyr::pivot_wider(names_from = component, values_from = value)

review_path <- file.path(
  production_root,
  "H01_METRIC-010_bootstrap_production_review.md"
)
review_lines <- c(
  "# H01 METRIC-010 production-bootstrap review",
  "",
  paste0("Status: **", production_label, "**"),
  "",
  "## Execution summary",
  "",
  paste0(
    "Production completed all 8 targets with 1,000 successful joint refits ",
    "retained per target (",
    sum(audits$used_refits),
    " used refits in total). There were ",
    sum(audits$failed_refits),
    " failed and ",
    sum(audits$warning_refits),
    " warning refits."
  ),
  "",
  paste0(
    "Observed target wall time summed to ",
    sprintf("%.1f", total_target_wall_seconds),
    " seconds using four refit ",
    "workers per sequential target."
  ),
  "",
  paste0(
    "Eight completed-target checkpoints and draw files are present. The ",
    "production draws occupy ",
    format(production_draw_bytes, big.mark = ",", scientific = FALSE),
    " bytes. Peak memory was not instrumented per child process."
  ),
  "",
  paste0(
    "The current-input bridge passed for all eight MDER targets, and all ",
    nrow(protected_before),
    " canonical H01 artifacts checked before and ",
    "after production were byte-identical."
  ),
  "",
  "## Production uncertainty summary",
  "",
  paste(capture.output(knitr::kable(review_table)), collapse = "\n"),
  "",
  paste0(
    "Values are point R² summaries with production 95% joint parametric ",
    "percentile intervals. Term components can overlap and must not be summed."
  ),
  "",
  "## Integration status",
  "",
  paste0(
    "The production bootstrap itself passed. Accepted H01 report integration ",
    "remains pending the focused production verifier and disposition check."
  )
)
writeLines(review_lines, review_path, useBytes = TRUE)

manifest_path <- file.path(
  production_root,
  "H01_METRIC-010_bootstrap_production_manifest.csv"
)
manifest_files <- sort(unique(c(
  unlist(lapply(
    c(code_root, draw_root, checkpoint_root, diagnostic_root, table_root),
    list.files,
    recursive = TRUE,
    full.names = TRUE
  )),
  input_pins_path,
  review_path,
  file.path(root, producer),
  file.path(
    root,
    "tests/hypotheses/H01/test_h01_mder_METRIC010_production.R"
  ),
  file.path(root, "scripts/hypotheses/H01/h01_contract.R"),
  file.path(root, "scripts/hypotheses/H01/h01_modeling.R"),
  unname(absolute_pin_paths)
)))
manifest_files <- manifest_files[
  file.exists(manifest_files) &
    !dir.exists(manifest_files) &
    normalizePath(manifest_files, winslash = "/", mustWork = TRUE) !=
      normalizePath(manifest_path, winslash = "/", mustWork = FALSE)
]
manifest <- dplyr::bind_rows(lapply(manifest_files, function(path) {
  tibble::tibble(
    path = relative_to_root(path),
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
  "H01 METRIC-010 production completed: eight targets x ",
  successful_refits,
  " used joint refits; accepted artifacts unchanged"
)
