# Fit and bootstrap the approved H01 model package across declared scenarios.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
output_root_setting <- Sys.getenv("H01_OUTPUT_ROOT", unset = root)
dir.create(output_root_setting, recursive = TRUE, showWarnings = FALSE)
output_root <- normalizePath(
  output_root_setting,
  winslash = "/",
  mustWork = TRUE
)

source(file.path(root, "scripts/pipeline/paths_io.R"))
source(file.path(root, "scripts/pipeline/assertions.R"))
source(file.path(root, "scripts/pipeline/multiplicity.R"))
source(file.path(root, "scripts/hypotheses/H01/h01_contract.R"))
source(file.path(root, "scripts/hypotheses/H01/h01_modeling.R"))

if (!identical(as.character(getRversion()), "4.6.1")) {
  h01_abort(
    "H01 model fitting requires R 4.6.1; found %s",
    as.character(getRversion())
  )
}

stage <- Sys.getenv("H01_STAGE", unset = "fit")
if (!stage %in% c("fit", "bootstrap", "all", "manifest")) {
  h01_abort(
    "H01_STAGE must be one of fit, bootstrap, all, or manifest"
  )
}
bootstrap_refits <- as.integer(Sys.getenv(
  "H01_BOOTSTRAP_REFITS",
  unset = "1000"
))
bootstrap_cores <- as.integer(Sys.getenv(
  "H01_BOOTSTRAP_CORES",
  unset = as.character(max(1L, min(4L, parallel::detectCores() - 1L)))
))
run_filter <- Sys.getenv("H01_RUN_FILTER", unset = "")
metric_filter <- Sys.getenv("H01_METRIC_FILTER", unset = "")
save_plots <- !identical(
  tolower(Sys.getenv("H01_SAVE_PLOTS", unset = "true")),
  "false"
)

producer <- "scripts/hypotheses/H01/run_h01_models.R"
model_root <- file.path(output_root, "artifacts/07_models/H01")
diagnostic_root <- file.path(output_root, "artifacts/08_diagnostics/H01")
table_root <- file.path(output_root, "artifacts/09_tables/H01")
figure_root <- file.path(output_root, "artifacts/10_figures/H01")
source_root <- file.path(output_root, "artifacts/11_source_data/H01")
manifest_root <- file.path(output_root, "artifacts/12_manifests")
invisible(vapply(
  c(
    model_root,
    diagnostic_root,
    table_root,
    figure_root,
    source_root,
    manifest_root
  ),
  dir.create,
  logical(1),
  recursive = TRUE,
  showWarnings = FALSE
))

if (stage %in% c("fit", "all")) {
  superseded_output <- file.path(
    table_root,
    "H01_exactly_identified_bout_sensitivity.csv"
  )
  if (file.exists(superseded_output)) {
    unlink(superseded_output)
  }
  if (file.exists(superseded_output)) {
    h01_abort("Could not remove the superseded H01 period-output filename")
  }
}

h01_write_csv <- function(data, path) {
  write_csv_artifact(data, path, producer = producer)
  invisible(path)
}

h01_write_rds <- function(object, path) {
  write_rds_artifact(object, path, producer = producer)
  invisible(path)
}

h01_add_identity <- function(data, run, spec) {
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

h01_model_manifest_rows <- function(bundle, run, spec) {
  rows <- list()
  index <- 1L
  for (stage_name in c("comparison", "final")) {
    for (model_name in names(bundle[[stage_name]])) {
      fit <- bundle[[stage_name]][[model_name]]
      model <- fit$model
      status <- h01_model_fit_status(model)
      rows[[index]] <- h01_add_identity(
        tibble::tibble(
          model_name = model_name,
          estimation_stage = stage_name,
          formula = if (is.null(model)) {
            paste(deparse(bundle$formulas[[model_name]]), collapse = " ")
          } else {
            paste(deparse(stats::formula(model)), collapse = " ")
          },
          engine = if (spec$analysis_unit == "participant") {
            "lm"
          } else if (spec$response_family == "gaussian") {
            "lmer"
          } else {
            "glmmTMB"
          },
          estimation_method = if (
            spec$analysis_unit == "participant"
          ) {
            "maximum_likelihood"
          } else if (
            spec$response_family == "gaussian" &&
              stage_name == "final"
          ) {
            "restricted_maximum_likelihood"
          } else {
            "maximum_likelihood"
          },
          family = if (spec$response_family == "tweedie_log") {
            "Tweedie"
          } else {
            "Gaussian"
          },
          link = if (spec$response_family == "tweedie_log") {
            "log"
          } else {
            "identity_after_declared_transformation"
          },
          observations = if (is.null(model)) {
            NA_integer_
          } else {
            stats::nobs(model)
          },
          log_likelihood = if (is.null(model)) {
            NA_real_
          } else {
            as.numeric(stats::logLik(model))
          },
          aic = if (is.null(model)) NA_real_ else stats::AIC(model),
          converged = status$converged,
          positive_definite_hessian = status$positive_definite_hessian,
          singular = status$singular,
          max_gradient = status$max_gradient,
          warnings = paste(fit$warnings, collapse = " | "),
          error = fit$error,
          status = if (is.null(model)) "NON_ESTIMABLE" else "FITTED"
        ),
        run,
        spec
      )
      index <- index + 1L
    }
  }
  dplyr::bind_rows(rows)
}

h01_empty_metric_rows <- function(run, spec) {
  families <- h01_family_registry()
  tests <- h01_add_identity(
    dplyr::transmute(
      families,
      comparison_id = comparison,
      statistic = NA_real_,
      df = NA_real_,
      p_raw = NA_real_,
      log_lik_reduced = NA_real_,
      log_lik_full = NA_real_,
      n_obs_reduced = NA_integer_,
      n_obs_full = NA_integer_,
      comparison_status = "NON_ESTIMABLE",
      family_order,
      family_id,
      family_label,
      family_n,
      adjustment_method
    ),
    run,
    spec
  )
  diagnostics <- h01_add_identity(
    tibble::tibble(
      converged = FALSE,
      positive_definite_hessian = FALSE,
      singular = NA,
      max_gradient = NA_real_,
      diagnostic_status = "NON_ESTIMABLE",
      fit_error = "Prepared scenario is unavailable for this metric"
    ),
    run,
    spec
  )
  samples <- h01_add_identity(
    tibble::tibble(
      participants = 0L,
      participant_days = 0L,
      observations = 0L,
      sites = 0L,
      derivation_support_hours = NA_real_,
      derivation_support_status = "not_applicable",
      derivation_support_unavailability_reason =
        "prepared_scenario_unavailable",
      sample_status = "NON_ESTIMABLE"
    ),
    run,
    spec
  )
  list(tests = tests, diagnostics = diagnostics, samples = samples)
}

h01_adjust_primary_families <- function(tests) {
  tests <- tests |>
    dplyr::mutate(
      family_instance_id = paste(run_id, family_id, sep = "::")
    )
  tests <- adjust_result_families(
    tests,
    family_col = "family_instance_id",
    p_col = "p_raw",
    family_n_col = "family_n",
    output_col = "p_adjusted",
    method = "BH"
  )
  tests |>
    dplyr::group_by(family_instance_id) |>
    dplyr::mutate(
      family_rank = ifelse(
        is.na(p_raw),
        NA_integer_,
        rank(p_raw, ties.method = "min", na.last = "keep")
      ),
      family_observed_tests = sum(!is.na(p_raw))
    ) |>
    dplyr::ungroup()
}

h01_fit_registered_scope <- function(frame, spec, primary_tests) {
  if (spec$preregistered_photoperiod) {
    output <- primary_tests |>
      dplyr::mutate(scope_change = "none_duration_metric")
  } else {
    formulas <- h01_formula_set(
      spec$analysis_unit,
      preregistered_scope = TRUE
    )
    bundle <- h01_fit_metric_models(frame, spec, formulas = formulas)
    output <- h01_model_tests(bundle) |>
      dplyr::filter(
        comparison_id != "site_full_vs_no_photoperiod"
      ) |>
      dplyr::mutate(
        scope_change = "photoperiod_omitted_for_non_duration_metric"
      )
  }
  output
}

h01_build_manifest <- function() {
  roots <- c(
    model_root,
    diagnostic_root,
    table_root,
    figure_root,
    source_root
  )
  files <- sort(unique(unlist(lapply(
    roots,
    list.files,
    recursive = TRUE,
    full.names = TRUE
  ))))
  files <- files[file.exists(files) & !dir.exists(files)]
  code_paths <- h01_code_paths(root)
  code_paths <- code_paths[file.exists(code_paths)]
  files <- sort(unique(c(files, code_paths)))
  manifest <- dplyr::bind_rows(lapply(files, function(path) {
    absolute_path <- path
    info <- file.info(path)
    relative <- if (startsWith(path, paste0(output_root, "/"))) {
      substring(path, nchar(output_root) + 2L)
    } else if (startsWith(path, paste0(root, "/"))) {
      substring(path, nchar(root) + 2L)
    } else {
      path
    }
    tibble::tibble(
      path = relative,
      artifact_type = tools::file_ext(path),
      sha256 = artifact_sha256(absolute_path),
      bytes = as.numeric(info$size),
      producer = producer,
      r_version = as.character(getRversion()),
      main_input_manifest_sha256 = input_contract$main$manifest_sha256,
      manuscript_prepared_input_manifest_sha256 =
        input_contract$manuscript_prepared_data$manifest_sha256,
      model_implementation_id = input_contract$model_implementation_id
    )
  }))
  path <- file.path(
    manifest_root,
    "H01_model_results_artifacts.csv"
  )
  h01_write_csv(manifest, path)
  invisible(path)
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
  h01_abort("Pinned H01 model-data manifests differ from the prefit handoff")
}
objects <- list(
  main = readRDS(input_contract$main$path),
  manuscript_prepared_data = readRDS(
    input_contract$manuscript_prepared_data$path
  )
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
    h01_abort("H01 `%s` input identity differs from the approved gate", name)
  }
}

metric_registry <- h01_metric_registry()
h01_validate_registry(metric_registry)
display_registry <- objects$main$metric_contract |>
  dplyr::select(
    metric_order,
    metric_id,
    manuscript_name,
    abbreviation,
    manuscript_category,
    display_unit,
    variant_label,
    value_definition
  )
metric_registry <- dplyr::left_join(
  metric_registry,
  display_registry,
  by = c("metric_order", "metric_id"),
  relationship = "one-to-one"
)
if (any(!stats::complete.cases(
  metric_registry[c("manuscript_name", "display_unit")]
))) {
  h01_abort("H01 display registry does not cover all 17 metrics")
}

run_registry <- h01_run_registry()
if (nzchar(run_filter)) {
  run_registry <- run_registry[grepl(run_filter, run_registry$run_id), ]
}
if (nzchar(metric_filter)) {
  metric_registry <- metric_registry[
    grepl(metric_filter, metric_registry$metric_id),
    ,
    drop = FALSE
  ]
}
if (nrow(run_registry) == 0L || nrow(metric_registry) == 0L) {
  h01_abort("H01 filters selected no declared run or metric")
}

if (stage %in% c("fit", "all")) {
  result_lists <- list(
    tests = list(),
    term_effects = list(),
    site_estimates = list(),
    site_deviations = list(),
    marginalization = list(),
    samples = list(),
    samples_by_site = list(),
    diagnostics = list(),
    influence = list(),
    latitude_loo = list(),
    random_site = list(),
    r2_point = list(),
    model_manifest = list(),
    preregistered_scope = list(),
    exactly_identified_period = list(),
    l10_noon_tests = list(),
    l10_noon_term_effects = list(),
    l10_noon_site_estimates = list(),
    l10_noon_site_deviations = list(),
    l10_noon_samples = list(),
    l10_noon_diagnostics = list(),
    l10_noon_r2 = list(),
    l10_noon_model_manifest = list()
  )
  result_index <- stats::setNames(
    rep(1L, length(result_lists)),
    names(result_lists)
  )
  add_result <- function(name, value) {
    if (nrow(value) == 0L) {
      return(invisible(NULL))
    }
    result_lists[[name]][[result_index[[name]]]] <<- value
    result_index[[name]] <<- result_index[[name]] + 1L
    invisible(NULL)
  }

  for (run_index in seq_len(nrow(run_registry))) {
    run <- run_registry[run_index, , drop = FALSE]
    object <- objects[[run$data_scenario_id]]
    message("Fitting H01 run: ", run$run_id)
    for (metric_index in seq_len(nrow(metric_registry))) {
      spec <- metric_registry[metric_index, , drop = FALSE]
      message("  ", spec$metric_order, "/17 ", spec$metric_id)
      frame <- h01_prepare_model_frame(
        object,
        spec,
        placement = run$placement,
        sample_scenario = run$sample_scenario
      )
      run_path <- file.path(
        run$data_scenario_id,
        run$placement,
        run$sample_scenario
      )
      model_directory <- file.path(model_root, run_path)
      diagnostic_directory <- file.path(diagnostic_root, run_path)
      source_directory <- file.path(source_root, run_path)
      invisible(vapply(
        c(model_directory, diagnostic_directory, source_directory),
        dir.create,
        logical(1),
        recursive = TRUE,
        showWarnings = FALSE
      ))
      frame_path <- file.path(
        model_directory,
        paste0(spec$metric_id, "_model_frame.rds")
      )
      bundle_path <- file.path(
        model_directory,
        paste0(spec$metric_id, "_models.rds")
      )
      if (nrow(frame) == 0L) {
        empty <- h01_empty_metric_rows(run, spec)
        add_result("tests", empty$tests)
        add_result("diagnostics", empty$diagnostics)
        add_result("samples", empty$samples)
        h01_write_rds(
          list(
            status = "NON_ESTIMABLE",
            spec = spec,
            run = run,
            reason = "Prepared scenario is unavailable for this metric"
          ),
          bundle_path
        )
        h01_write_rds(frame, frame_path)
        next
      }
      bundle <- h01_fit_metric_models(frame, spec)
      h01_write_rds(frame, frame_path)
      h01_write_rds(bundle, bundle_path)
      frame_csv <- frame |>
        dplyr::select(
          .model_row_id,
          site,
          participant_key,
          local_date,
          value,
          response_value,
          photoperiod_hours,
          photoperiod_centered_hours,
          latitude_deg,
          absolute_latitude_10deg_centered,
          metric_support_available,
          metric_support_valid_minutes,
          metric_support_expected_minutes,
          metric_any_censored
        )
      h01_write_csv(
        frame_csv,
        file.path(
          source_directory,
          paste0(spec$metric_id, "_model_frame.csv")
        )
      )

      tests <- h01_model_tests(bundle) |>
        dplyr::left_join(
          h01_family_registry(),
          by = c("comparison_id" = "comparison"),
          relationship = "many-to-one"
        )
      add_result("tests", h01_add_identity(tests, run, spec))

      site_model <- h01_unwrap_model(bundle, "final", "site_full")
      latitude_model <- h01_unwrap_model(
        bundle,
        "final",
        "latitude_full"
      )
      effects <- dplyr::bind_rows(
        h01_extract_term_effect(
          site_model,
          "photoperiod_centered_hours",
          "Photoperiod per hour",
          spec
        ),
        h01_extract_term_effect(
          latitude_model,
          "absolute_latitude_10deg_centered",
          "Absolute latitude per 10 degrees",
          spec
        )
      )
      add_result(
        "term_effects",
        h01_add_identity(effects, run, spec)
      )

      site <- h01_site_summaries(site_model, frame, spec)
      add_result(
        "site_estimates",
        h01_add_identity(site$estimates, run, spec)
      )
      add_result(
        "site_deviations",
        h01_add_identity(site$deviations, run, spec)
      )
      add_result(
        "marginalization",
        h01_add_identity(site$marginalization, run, spec)
      )

      samples <- h01_sample_summary(frame, spec)
      add_result(
        "samples",
        h01_add_identity(
          dplyr::mutate(samples$overall, sample_status = "FITTED"),
          run,
          spec
        )
      )
      add_result(
        "samples_by_site",
        h01_add_identity(samples$by_site, run, spec)
      )

      seed <- h01_primary_seed(
        spec$metric_order,
        run$data_scenario_id,
        run$placement,
        run$sample_scenario
      )
      diagnostics <- h01_model_diagnostics(bundle, frame, seed)
      add_result(
        "diagnostics",
        h01_add_identity(diagnostics, run, spec)
      )
      diagnostic_data <- h01_diagnostic_plot_data(site_model, frame)
      diagnostic_source_path <- file.path(
        source_directory,
        paste0(spec$metric_id, "_diagnostic_plot_data.csv")
      )
      h01_write_csv(diagnostic_data, diagnostic_source_path)
      if (save_plots) {
        h01_save_diagnostic_plot(
          diagnostic_data,
          file.path(
            diagnostic_directory,
            paste0(spec$metric_id, "_diagnostics.png")
          ),
          paste(
            "H01",
            spec$manuscript_name,
            run$data_scenario_id,
            run$placement,
            run$sample_scenario,
            sep = " — "
          )
        )
      }

      add_result(
        "influence",
        h01_add_identity(
          h01_participant_influence(bundle, frame),
          run,
          spec
        )
      )
      add_result(
        "latitude_loo",
        h01_add_identity(
          h01_latitude_leave_one_site_out(bundle, frame),
          run,
          spec
        )
      )
      add_result(
        "random_site",
        h01_add_identity(
          h01_fit_random_site_summary(bundle),
          run,
          spec
        )
      )
      add_result(
        "r2_point",
        h01_add_identity(
          h01_r2_point_summary(bundle),
          run,
          spec
        )
      )
      add_result(
        "model_manifest",
        h01_model_manifest_rows(bundle, run, spec)
      )

      if (
        run$data_scenario_id == "main" &&
          run$placement == "glasses" &&
          run$sample_scenario == "all_available"
      ) {
        registered <- h01_fit_registered_scope(frame, spec, tests)
        add_result(
          "preregistered_scope",
          h01_add_identity(registered, run, spec)
        )
      }

      if (spec$metric_id == "longest_bout_above_250") {
        exact_frame <- h01_prepare_model_frame(
          object,
          spec,
          placement = run$placement,
          sample_scenario = run$sample_scenario,
          exactly_identified_only = TRUE
        )
        if (nrow(exact_frame) > 0L) {
          exact_bundle <- h01_fit_metric_models(exact_frame, spec)
          exact_tests <- h01_model_tests(exact_bundle)
          exact_samples <- h01_sample_summary(exact_frame, spec)$overall
          exact_diagnostics <- h01_model_diagnostics(
            exact_bundle,
            exact_frame,
            seed + 500000L
          )
          exact_output <- dplyr::bind_cols(
            exact_tests,
            exact_samples[rep(1L, nrow(exact_tests)), , drop = FALSE],
            exact_diagnostics[
              rep(1L, nrow(exact_tests)),
              ,
              drop = FALSE
            ]
          ) |>
            dplyr::mutate(
              sensitivity_id = "exactly_identified_longest_period",
              excluded_censored_rows = nrow(frame) - nrow(exact_frame)
            )
          add_result(
            "exactly_identified_period",
            h01_add_identity(exact_output, run, spec)
          )
          h01_write_rds(
            exact_bundle,
            file.path(
              model_directory,
              paste0(
                spec$metric_id,
                "_exactly_identified_period_sensitivity_models.rds"
              )
            )
          )
        }
      }

      if (spec$metric_id == "l10_midpoint") {
        noon_spec <- spec
        noon_spec$response_transform <- "clock_hours_midnight_after_12"
        noon_frame <- h01_prepare_model_frame(
          object,
          noon_spec,
          placement = run$placement,
          sample_scenario = run$sample_scenario
        )
        if (!identical(frame$.model_row_id, noon_frame$.model_row_id)) {
          h01_abort(
            "The H01 L10 noon sensitivity changed the primary model rows"
          )
        }
        noon_bundle <- h01_fit_metric_models(noon_frame, noon_spec)
        noon_tests <- h01_model_tests(noon_bundle) |>
          dplyr::mutate(
            sensitivity_id = "l10_midpoint_noon_conversion",
            multiplicity_role = "unadjusted_sensitivity_not_family_member"
          )
        noon_site_model <- h01_unwrap_model(
          noon_bundle,
          "final",
          "site_full"
        )
        noon_latitude_model <- h01_unwrap_model(
          noon_bundle,
          "final",
          "latitude_full"
        )
        noon_effects <- dplyr::bind_rows(
          h01_extract_term_effect(
            noon_site_model,
            "photoperiod_centered_hours",
            "Photoperiod per hour",
            noon_spec
          ),
          h01_extract_term_effect(
            noon_latitude_model,
            "absolute_latitude_10deg_centered",
            "Absolute latitude per 10 degrees",
            noon_spec
          )
        ) |>
          dplyr::mutate(
            sensitivity_id = "l10_midpoint_noon_conversion"
          )
        noon_site <- h01_site_summaries(
          noon_site_model,
          noon_frame,
          noon_spec
        )
        noon_samples <- h01_sample_summary(noon_frame, noon_spec)$overall |>
          dplyr::mutate(
            sensitivity_id = "l10_midpoint_noon_conversion",
            sample_status = "FITTED"
          )
        noon_diagnostics <- h01_model_diagnostics(
          noon_bundle,
          noon_frame,
          seed + 600000L
        ) |>
          dplyr::mutate(
            sensitivity_id = "l10_midpoint_noon_conversion"
          )
        noon_r2 <- h01_r2_point_summary(noon_bundle) |>
          dplyr::mutate(
            sensitivity_id = "l10_midpoint_noon_conversion"
          )
        add_result(
          "l10_noon_tests",
          h01_add_identity(noon_tests, run, noon_spec)
        )
        add_result(
          "l10_noon_term_effects",
          h01_add_identity(noon_effects, run, noon_spec)
        )
        add_result(
          "l10_noon_site_estimates",
          h01_add_identity(
            dplyr::mutate(
              noon_site$estimates,
              sensitivity_id = "l10_midpoint_noon_conversion"
            ),
            run,
            noon_spec
          )
        )
        add_result(
          "l10_noon_site_deviations",
          h01_add_identity(
            dplyr::mutate(
              noon_site$deviations,
              sensitivity_id = "l10_midpoint_noon_conversion"
            ),
            run,
            noon_spec
          )
        )
        add_result(
          "l10_noon_samples",
          h01_add_identity(noon_samples, run, noon_spec)
        )
        add_result(
          "l10_noon_diagnostics",
          h01_add_identity(noon_diagnostics, run, noon_spec)
        )
        add_result(
          "l10_noon_r2",
          h01_add_identity(noon_r2, run, noon_spec)
        )
        add_result(
          "l10_noon_model_manifest",
          h01_model_manifest_rows(noon_bundle, run, noon_spec) |>
            dplyr::mutate(
              sensitivity_id = "l10_midpoint_noon_conversion"
            )
        )
        h01_write_rds(
          noon_frame,
          file.path(
            model_directory,
            paste0(
              spec$metric_id,
              "_noon_conversion_sensitivity_model_frame.rds"
            )
          )
        )
        h01_write_rds(
          noon_bundle,
          file.path(
            model_directory,
            paste0(
              spec$metric_id,
              "_noon_conversion_sensitivity_models.rds"
            )
          )
        )
        h01_write_csv(
          noon_frame |>
            dplyr::select(
              .model_row_id,
              site,
              participant_key,
              local_date,
              value,
              response_value,
              photoperiod_hours,
              photoperiod_centered_hours,
              latitude_deg,
              absolute_latitude_10deg_centered
            ),
          file.path(
            source_directory,
            paste0(
              spec$metric_id,
              "_noon_conversion_sensitivity_model_frame.csv"
            )
          )
        )
      }
    }
  }

  results <- lapply(result_lists, dplyr::bind_rows)
  results$tests <- h01_adjust_primary_families(results$tests)
  gated_runs <- unique(
    results$diagnostics$run_id[
      results$diagnostics$diagnostic_status == "FAIL_MAJOR_GATE"
    ]
  )
  results$tests <- results$tests |>
    dplyr::mutate(
      family_status = ifelse(
        .data$run_id %in% gated_runs,
        "INVALID_OPEN_MAJOR_GATE",
        "COMPLETE"
      ),
      p_adjusted = ifelse(
        .data$run_id %in% gated_runs,
        NA_real_,
        .data$p_adjusted
      )
    )
  site_support <- results$tests |>
    dplyr::filter(family_id == "H01-F1-site") |>
    dplyr::select(
      run_id,
      metric_id,
      overall_site_p_adjusted = p_adjusted
    )
  results$site_deviations <- results$site_deviations |>
    dplyr::left_join(
      site_support,
      by = c("run_id", "metric_id"),
      relationship = "many-to-one"
    ) |>
    dplyr::mutate(
      inferential_followup_supported =
        !is.na(overall_site_p_adjusted) &
          overall_site_p_adjusted < 0.05
    )

  if (nrow(results$preregistered_scope) > 0L) {
    scope_family <- dplyr::case_when(
      results$preregistered_scope$comparison_id ==
        "site_full_vs_no_site" ~ "H01-S1-registered-site",
      results$preregistered_scope$comparison_id ==
        "latitude_full_vs_no_latitude" ~ "H01-S2-registered-latitude",
      results$preregistered_scope$comparison_id ==
        "site_full_vs_latitude_full" ~ "H01-S3-registered-adequacy",
      results$preregistered_scope$comparison_id ==
        "site_full_vs_no_photoperiod" ~
          "H01-S4-registered-photoperiod",
      TRUE ~ NA_character_
    )
    results$preregistered_scope$family_id <- scope_family
    results$preregistered_scope$family_n <- ifelse(
      scope_family == "H01-S4-registered-photoperiod",
      5L,
      17L
    )
    results$preregistered_scope$family_instance_id <- paste(
      results$preregistered_scope$run_id,
      scope_family,
      sep = "::"
    )
    results$preregistered_scope <- results$preregistered_scope |>
      dplyr::filter(!is.na(family_id))
    results$preregistered_scope <- adjust_result_families(
      results$preregistered_scope,
      family_col = "family_instance_id",
      p_col = "p_raw",
      family_n_col = "family_n",
      output_col = "p_adjusted",
      method = "BH"
    ) |>
      dplyr::mutate(
        family_status = ifelse(
          .data$run_id %in% gated_runs,
          "INVALID_OPEN_MAJOR_GATE",
          "COMPLETE"
        ),
        p_adjusted = ifelse(
          .data$run_id %in% gated_runs,
          NA_real_,
          .data$p_adjusted
        )
      )
  }

  output_names <- c(
    tests = "H01_model_level_tests.csv",
    term_effects = "H01_term_effects.csv",
    site_estimates = "H01_site_estimates.csv",
    site_deviations = "H01_site_deviations.csv",
    marginalization = "H01_marginalization_comparison.csv",
    samples = "H01_exact_samples.csv",
    samples_by_site = "H01_exact_samples_by_site.csv",
    diagnostics = "H01_model_diagnostics.csv",
    influence = "H01_participant_influence.csv",
    latitude_loo = "H01_latitude_leave_one_site_out.csv",
    random_site = "H01_random_site_descriptions.csv",
    r2_point = "H01_r2_point_summaries.csv",
    model_manifest = "H01_model_manifest.csv",
    preregistered_scope = "H01_preregistered_scope_sensitivity.csv",
    exactly_identified_period =
      "H01_exactly_identified_period_sensitivity.csv",
    l10_noon_tests = "H01_l10_noon_conversion_model_tests.csv",
    l10_noon_term_effects =
      "H01_l10_noon_conversion_term_effects.csv",
    l10_noon_site_estimates =
      "H01_l10_noon_conversion_site_estimates.csv",
    l10_noon_site_deviations =
      "H01_l10_noon_conversion_site_deviations.csv",
    l10_noon_samples = "H01_l10_noon_conversion_samples.csv",
    l10_noon_diagnostics =
      "H01_l10_noon_conversion_diagnostics.csv",
    l10_noon_r2 = "H01_l10_noon_conversion_r2.csv",
    l10_noon_model_manifest =
      "H01_l10_noon_conversion_model_manifest.csv"
  )
  for (name in names(output_names)) {
    h01_write_csv(
      results[[name]],
      file.path(
        if (name %in% c(
          "diagnostics",
          "influence",
          "latitude_loo",
          "l10_noon_diagnostics"
        )) {
          diagnostic_root
        } else {
          table_root
        },
        output_names[[name]]
      )
    )
  }
  h01_write_rds(
    results,
    file.path(model_root, "H01_fit_results.rds")
  )
}

if (stage %in% c("bootstrap", "all")) {
  point_path <- file.path(table_root, "H01_r2_point_summaries.csv")
  diagnostic_path <- file.path(
    diagnostic_root,
    "H01_model_diagnostics.csv"
  )
  if (!file.exists(point_path)) {
    h01_abort("H01 bootstrap requires the completed fit-stage R2 summaries")
  }
  if (!file.exists(diagnostic_path)) {
    h01_abort("H01 bootstrap requires the completed fit-stage diagnostics")
  }
  gate_diagnostics <- readr::read_csv(
    diagnostic_path,
    show_col_types = FALSE
  ) |>
    dplyr::filter(
      .data$run_id %in% run_registry$run_id,
      .data$metric_id %in% metric_registry$metric_id,
      .data$diagnostic_status == "FAIL_MAJOR_GATE"
    )
  if (nrow(gate_diagnostics) > 0L) {
    gate_labels <- unique(paste(
      gate_diagnostics$run_id,
      gate_diagnostics$metric_id,
      sep = "::"
    ))
    h01_abort(
      paste0(
        "H01 production bootstrap is blocked by an open major gate: %s. ",
        "Do not replace a response family without approval."
      ),
      paste(gate_labels, collapse = ", ")
    )
  }
  point_results <- readr::read_csv(point_path, show_col_types = FALSE)
  bootstrap_summaries <- list()
  bootstrap_audits <- list()
  bootstrap_failures <- list()
  summary_index <- 1L
  audit_index <- 1L
  failure_index <- 1L
  for (run_index in seq_len(nrow(run_registry))) {
    run <- run_registry[run_index, , drop = FALSE]
    message("Bootstrapping H01 run: ", run$run_id)
    for (metric_index in seq_len(nrow(metric_registry))) {
      spec <- metric_registry[metric_index, , drop = FALSE]
      run_path <- file.path(
        run$data_scenario_id,
        run$placement,
        run$sample_scenario
      )
      model_directory <- file.path(model_root, run_path)
      bundle_path <- file.path(
        model_directory,
        paste0(spec$metric_id, "_models.rds")
      )
      frame_path <- file.path(
        model_directory,
        paste0(spec$metric_id, "_model_frame.rds")
      )
      if (!file.exists(bundle_path) || !file.exists(frame_path)) {
        h01_abort(
          "H01 bootstrap input is missing for `%s` in `%s`",
          spec$metric_id,
          run$run_id
        )
      }
      bundle <- readRDS(bundle_path)
      frame <- readRDS(frame_path)
      if (
        identical(bundle$status, "NON_ESTIMABLE") ||
          nrow(frame) == 0L
      ) {
        next
      }
      message("  ", spec$metric_order, "/17 ", spec$metric_id)
      seed <- h01_primary_seed(
        spec$metric_order,
        run$data_scenario_id,
        run$placement,
        run$sample_scenario
      )
      bootstrap <- h01_bootstrap_r2(
        bundle,
        frame,
        seed = seed,
        successful_refits = bootstrap_refits,
        cores = bootstrap_cores
      )
      draws_path <- file.path(
        model_directory,
        paste0(spec$metric_id, "_r2_bootstrap_draws.rds")
      )
      h01_write_rds(bootstrap$draws, draws_path)
      point <- point_results |>
        dplyr::filter(
          run_id == run$run_id,
          metric_id == spec$metric_id
        )
      summary <- h01_summarize_bootstrap(point, bootstrap$draws)
      bootstrap_summaries[[summary_index]] <- h01_add_identity(
        summary,
        run,
        spec
      )
      summary_index <- summary_index + 1L
      bootstrap_audits[[audit_index]] <- h01_add_identity(
        bootstrap$audit,
        run,
        spec
      )
      audit_index <- audit_index + 1L
      if (nrow(bootstrap$failures) > 0L) {
        bootstrap_failures[[failure_index]] <- h01_add_identity(
          bootstrap$failures,
          run,
          spec
        )
        failure_index <- failure_index + 1L
      }
    }
  }
  h01_write_csv(
    dplyr::bind_rows(bootstrap_summaries),
    file.path(table_root, "H01_r2_bootstrap_summaries.csv")
  )
  h01_write_csv(
    dplyr::bind_rows(bootstrap_audits),
    file.path(diagnostic_root, "H01_r2_bootstrap_audit.csv")
  )
  h01_write_csv(
    dplyr::bind_rows(bootstrap_failures),
    file.path(diagnostic_root, "H01_r2_bootstrap_failures.csv")
  )
}

h01_build_manifest()
message("H01 ", stage, " stage completed")
