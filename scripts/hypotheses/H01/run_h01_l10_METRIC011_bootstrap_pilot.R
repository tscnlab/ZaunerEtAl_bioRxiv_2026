# Run the 50-refit H01 METRIC-011 L10-mean bootstrap pilot.

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
    "The H01 METRIC-011 pilot requires R 4.6.1; found %s",
    as.character(getRversion())
  )
}

producer <-
  "scripts/hypotheses/H01/run_h01_l10_METRIC011_bootstrap_pilot.R"
pilot_label <- "PILOT — NOT FOR INFERENCE OR MANUSCRIPT REPORTING"
metric_id <- "l10_mean_medi"
successful_refits <- as.integer(Sys.getenv(
  "H01_L10_PILOT_REFITS",
  unset = "50"
))
pilot_cores <- as.integer(Sys.getenv(
  "H01_L10_PILOT_CORES",
  unset = "4"
))
if (!successful_refits %in% c(50L, 100L)) {
  h01_abort("H01_L10_PILOT_REFITS must be 50 or 100")
}
if (!is.finite(pilot_cores) || pilot_cores < 1L) {
  h01_abort("H01_L10_PILOT_CORES must be a positive integer")
}

point_root <- file.path(
  root,
  "audit/hypotheses/H01/l10_METRIC-011/point_refit"
)
pilot_root <- file.path(
  root,
  "audit/hypotheses/H01/l10_METRIC-011/bootstrap_pilot"
)
pilot_model_root <- file.path(pilot_root, "draws")
pilot_diagnostic_root <- file.path(pilot_root, "diagnostics")
pilot_table_root <- file.path(pilot_root, "tables")
pilot_figure_root <- file.path(pilot_root, "figures")
pilot_source_root <- file.path(pilot_root, "source_data")
invisible(vapply(
  c(
    pilot_model_root,
    pilot_diagnostic_root,
    pilot_table_root,
    pilot_figure_root,
    pilot_source_root
  ),
  dir.create,
  logical(1),
  recursive = TRUE,
  showWarnings = FALSE
))

point_manifest_path <- file.path(
  point_root,
  "artifacts/12_manifests/H01_model_results_artifacts.csv"
)
point_results_path <- file.path(
  point_root,
  "artifacts/09_tables/H01/H01_r2_point_summaries.csv"
)
point_diagnostics_path <- file.path(
  point_root,
  "artifacts/08_diagnostics/H01/H01_model_diagnostics.csv"
)
required_point_paths <- c(
  point_manifest_path,
  point_results_path,
  point_diagnostics_path
)
if (!all(file.exists(required_point_paths))) {
  h01_abort("The H01 METRIC-011 point-refit gate is incomplete")
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
  h01_abort("The H01 METRIC-011 pilot requires four primary-data targets")
}
point_diagnostics <- readr::read_csv(
  point_diagnostics_path,
  show_col_types = FALSE,
  progress = FALSE
)
if (
  nrow(point_diagnostics) != 4L ||
    any(point_diagnostics$metric_id != metric_id) ||
    any(point_diagnostics$diagnostic_status == "FAIL_MAJOR_GATE")
) {
  h01_abort("The H01 METRIC-011 point diagnostics block the pilot")
}
point_results <- readr::read_csv(
  point_results_path,
  show_col_types = FALSE,
  progress = FALSE
)

pilot_contract_sha256 <- digest::digest(
  list(
    metric_id = metric_id,
    response_family = spec$response_family,
    response_transform = spec$response_transform,
    successful_refits = successful_refits,
    planned_run_ids = run_registry$run_id,
    metric_decision_sha256 =
      "23b9f70d1d16f7fd3ebbdbc57aaf78c0a701fe1f9d22bd667d926cd320d40797",
    main_manifest_sha256 =
      "25978c5d6903e6e835c1aff6a9bc2e7552b85295e8d840d3dd65bbf9b1eb6b72",
    main_rds_sha256 =
      "0328fe1a698bc13965feb0b68b03ccf0fd20f32b55d6148635811b0d674e0a00",
    point_manifest_sha256 = artifact_sha256(point_manifest_path),
    point_runner_sha256 = artifact_sha256(file.path(
      root,
      "scripts/hypotheses/H01/run_h01_l10_METRIC011_point.R"
    )),
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

add_pilot_identity <- function(data, run) {
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
    h01_abort("Missing point fit for `%s`", run$run_id)
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
    pilot <- checkpoint$pilot
    runtime <- checkpoint$runtime
    checkpoint_status <- "REUSED_COMPLETED_TARGET_CHECKPOINT"
  } else {
    message("Piloting H01 METRIC-011 target: ", run$run_id)
    started <- Sys.time()
    process_started <- proc.time()
    seed <- h01_primary_seed(
      spec$metric_order,
      run$data_scenario_id,
      run$placement,
      run$sample_scenario
    ) + 11000000L
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
      h01_abort("Pilot target `%s` did not pass", run$run_id)
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

  if (nrow(draws) != successful_refits) {
    h01_abort("Pilot draw count mismatch in `%s`", run$run_id)
  }
  point <- point_results |>
    dplyr::filter(
      .data$run_id == run$run_id,
      .data$metric_id == !!metric_id
    )
  summary_rows[[run_index]] <- add_pilot_identity(
    h01_summarize_bootstrap(point, draws),
    run
  )
  audit_rows[[run_index]] <- add_pilot_identity(pilot$audit, run)
  if (nrow(pilot$failures) > 0L) {
    failure_rows[[length(failure_rows) + 1L]] <- add_pilot_identity(
      pilot$failures,
      run
    )
  }
  runtime_rows[[run_index]] <- add_pilot_identity(
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
failures <- dplyr::bind_rows(failure_rows)
runtimes <- dplyr::bind_rows(runtime_rows)
if (
  nrow(audits) != 4L ||
    any(audits$status != "PASS") ||
    any(audits$used_refits != successful_refits) ||
    any(runtimes$successful_draws != successful_refits) ||
    any(summaries$bootstrap_successful_used != successful_refits)
) {
  h01_abort("H01 METRIC-011 pilot aggregate validation failed")
}

summary_path <- file.path(
  pilot_table_root,
  "H01_METRIC-011_bootstrap_pilot_r2_summaries.csv"
)
audit_path <- file.path(
  pilot_diagnostic_root,
  "H01_METRIC-011_bootstrap_pilot_audit.csv"
)
failure_path <- file.path(
  pilot_diagnostic_root,
  "H01_METRIC-011_bootstrap_pilot_failures.csv"
)
runtime_path <- file.path(
  pilot_diagnostic_root,
  "H01_METRIC-011_bootstrap_pilot_runtime.csv"
)
provenance_path <- file.path(
  pilot_diagnostic_root,
  "H01_METRIC-011_bootstrap_pilot_provenance.csv"
)
write_csv_artifact(summaries, summary_path, producer = producer)
write_csv_artifact(audits, audit_path, producer = producer)
write_csv_artifact(failures, failure_path, producer = producer)
write_csv_artifact(runtimes, runtime_path, producer = producer)

total_wall_seconds <- sum(runtimes$wall_seconds)
estimated_production_wall_seconds <- total_wall_seconds *
  1000 / successful_refits
provenance <- tibble::tibble(
  inference_status = pilot_label,
  pilot_contract_sha256 = pilot_contract_sha256,
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
  total_wall_seconds = total_wall_seconds,
  estimated_production_wall_seconds = estimated_production_wall_seconds,
  estimated_production_wall_hours =
    estimated_production_wall_seconds / 3600,
  checkpoint_granularity = "completed run-metric target",
  command = paste0(
    "H01_L10_PILOT_REFITS=", successful_refits,
    " H01_L10_PILOT_CORES=", pilot_cores,
    " Rscript --vanilla ", producer
  ),
  point_manifest_sha256 = artifact_sha256(point_manifest_path),
  point_results_sha256 = artifact_sha256(point_results_path),
  point_diagnostics_sha256 = artifact_sha256(point_diagnostics_path),
  producer_sha256 = artifact_sha256(file.path(root, producer)),
  pilot_status = "PASS_AWAITING_AUTHOR_PRODUCTION_APPROVAL",
  completed_utc = format(Sys.time(), tz = "UTC", usetz = TRUE)
)
write_csv_artifact(provenance, provenance_path, producer = producer)

plot_data <- summaries |>
  dplyr::filter(
    .data$measure %in% c(
      "marginal_r2",
      "conditional_r2",
      "participant_associated_share",
      "site_part_r2",
      "photoperiod_part_r2",
      "latitude_part_r2"
    )
  ) |>
  dplyr::mutate(
    run_label = dplyr::case_when(
      placement == "glasses" & sample_scenario == "all_available" ~
        "Near eye — all available",
      placement == "chest" & sample_scenario == "all_available" ~
        "Chest — all available",
      placement == "glasses" ~ "Near eye — paired/common",
      TRUE ~ "Chest — paired/common"
    ),
    component = factor(
      measure,
      levels = c(
        "marginal_r2",
        "conditional_r2",
        "participant_associated_share",
        "site_part_r2",
        "photoperiod_part_r2",
        "latitude_part_r2"
      )
    )
  )
plot_source_path <- file.path(
  pilot_source_root,
  "H01_METRIC-011_bootstrap_pilot_preview_source.csv"
)
write_csv_artifact(plot_data, plot_source_path, producer = producer)
pilot_plot <- ggplot2::ggplot(
  plot_data,
  ggplot2::aes(
    x = estimate,
    y = run_label,
    xmin = conf_low,
    xmax = conf_high
  )
) +
  ggplot2::geom_vline(xintercept = 0, colour = "grey70") +
  ggplot2::geom_errorbar(
    orientation = "y",
    width = 0.18,
    linewidth = 0.5
  ) +
  ggplot2::geom_point(size = 1.8) +
  ggplot2::facet_wrap(~component, scales = "free_x", ncol = 2) +
  ggplot2::labs(
    title = "H01 L10-mean bootstrap pilot preview",
    subtitle = pilot_label,
    x = "Pilot estimate and 95% percentile interval",
    y = NULL
  ) +
  ggplot2::theme_minimal(base_size = 10) +
  ggplot2::theme(
    panel.grid.minor = ggplot2::element_blank(),
    plot.subtitle = ggplot2::element_text(face = "bold")
  )
ggplot2::ggsave(
  file.path(
    pilot_figure_root,
    "H01_METRIC-011_bootstrap_pilot_preview.png"
  ),
  pilot_plot,
  width = 9,
  height = 7,
  units = "in",
  dpi = 180,
  bg = "white"
)

manifest_files <- sort(unique(c(
  unlist(lapply(
    c(
      pilot_model_root,
      pilot_diagnostic_root,
      pilot_table_root,
      pilot_figure_root,
      pilot_source_root
    ),
    list.files,
    recursive = TRUE,
    full.names = TRUE
  )),
  file.path(root, producer),
  file.path(root, "scripts/hypotheses/H01/h01_contract.R"),
  file.path(root, "scripts/hypotheses/H01/h01_modeling.R"),
  point_manifest_path,
  point_results_path,
  point_diagnostics_path,
  file.path(root, "audit/decisions/l10_numerical_zero_normalization.md")
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
write_csv_artifact(
  manifest,
  file.path(pilot_root, "H01_METRIC-011_bootstrap_pilot_manifest.csv"),
  producer = producer
)

message(
  "H01 METRIC-011 pilot completed: four targets × ",
  successful_refits,
  " used refits; awaiting author production approval"
)
