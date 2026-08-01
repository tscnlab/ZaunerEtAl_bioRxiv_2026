# Run the author-approved H05 Stage 2 implementation and V0 comparison.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)

source(file.path(root, "scripts/pipeline/paths_io.R"))
source(file.path(root, "scripts/pipeline/multiplicity.R"))
source(file.path(root, "scripts/hypotheses/H01/h01_contract.R"))
source(file.path(root, "scripts/hypotheses/H01/h01_modeling.R"))
source(file.path(root, "scripts/hypotheses/H05/h05_contract.R"))
source(file.path(root, "scripts/hypotheses/H05/h05_modeling.R"))

# Keep clean-session logs focused on analytical warnings. Tidyselect's
# lifecycle notices do not change results and are separately covered by tests.
options(lifecycle_verbosity = "quiet", warn = 1)

if (!identical(as.character(getRversion()), "4.6.1")) {
  h05_abort(
    "H05 Stage 2 requires R 4.6.1; found %s",
    as.character(getRversion())
  )
}

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
  h05_abort(
    "H05 Stage 2 is missing project package(s): %s",
    paste(missing_packages, collapse = ", ")
  )
}

producer <- "scripts/hypotheses/H05/run_h05_stage2.R"
stage <- Sys.getenv("H05_STAGE", unset = "fit")
if (!stage %in% c("fit", "manifest")) {
  h05_abort("H05_STAGE must be `fit` or `manifest`")
}
run_loo <- !identical(
  tolower(Sys.getenv("H05_RUN_LOO", unset = "true")),
  "false"
)

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

h05_write_csv <- function(data, path) {
  write_csv_artifact(data, path, producer = producer)
  invisible(path)
}

h05_write_rds <- function(object, path) {
  write_rds_artifact(object, path, producer = producer)
  invisible(path)
}

h05_relative_path <- function(path) {
  normalized <- normalizePath(path, winslash = "/", mustWork = TRUE)
  if (startsWith(normalized, paste0(root, "/"))) {
    substring(normalized, nchar(root) + 2L)
  } else {
    normalized
  }
}

h05_build_manifest <- function() {
  artifact_files <- sort(unique(unlist(lapply(
    roots,
    list.files,
    recursive = TRUE,
    full.names = TRUE
  ))))
  manifest_path <- file.path(roots$manifests, "H05_stage2_artifacts.csv")
  artifact_files <- artifact_files[
    file.exists(artifact_files) &
      !dir.exists(artifact_files) &
      normalizePath(artifact_files, winslash = "/", mustWork = TRUE) !=
        normalizePath(manifest_path, winslash = "/", mustWork = FALSE)
  ]
  code_and_report <- c(
    file.path(root, "scripts/hypotheses/H05/h05_contract.R"),
    file.path(root, "scripts/hypotheses/H05/h05_modeling.R"),
    file.path(root, "scripts/hypotheses/H05/run_h05_stage2.R"),
    file.path(root, "tests/hypotheses/H05/test_h05_stage2.R"),
    file.path(root, "audit/hypotheses/H05/02_implementation_and_v0_comparison.qmd"),
    file.path(root, "audit/hypotheses/H05/02_implementation_and_v0_comparison.html"),
    file.path(root, "audit/handoffs/H05_stage2_handoff.md")
  )
  files <- sort(unique(c(
    artifact_files,
    code_and_report[file.exists(code_and_report)]
  )))
  manifest <- dplyr::bind_rows(lapply(files, function(path) {
    info <- file.info(path)
    tibble::tibble(
      path = h05_relative_path(path),
      artifact_type = tools::file_ext(path),
      sha256 = artifact_sha256(path),
      bytes = as.numeric(info$size),
      producer = producer,
      r_version = as.character(getRversion()),
      written_utc = format(info$mtime, tz = "UTC", usetz = TRUE)
    )
  }))
  h05_write_csv(manifest, manifest_path)
  invisible(manifest_path)
}

if (identical(stage, "manifest")) {
  h05_build_manifest()
  message("H05 Stage 2 manifest refreshed")
  quit(save = "no", status = 0L)
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
  h05_abort(
    "A frozen H05 input or inherited source differs from its approved hash"
  )
}

objects <- list(
  main = readRDS(input_contract$main$path),
  manuscript_prepared_data = readRDS(
    input_contract$manuscript_prepared_data$path
  )
)
leba <- readRDS(input_contract$leba$path)
h01_fit_results <- readRDS(
  input_contract$h01_fit_results_site_evidence$path
)
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
leba_audit <- h05_verified_leba(leba, factor_registry)
approval_registry <- h05_approval_registry()

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
      which(
        objects$main$metric_contract[[.data$field]] !=
          objects$manuscript_prepared_data$metric_contract[[.data$field]] |
          xor(
            is.na(objects$main$metric_contract[[.data$field]]),
            is.na(
              objects$manuscript_prepared_data$metric_contract[[.data$field]]
            )
          )
      ),
      collapse = ","
    )
  ) |>
  dplyr::ungroup()
core_metric_fields <- c(
  "metric_order", "metric_id", "analysis_unit", "source_field",
  "source_unit", "manuscript_name", "manuscript_category", "display_unit"
)
if (any(!metric_contract_comparison$identical[
  metric_contract_comparison$field %in% core_metric_fields
])) {
  h05_abort("Main and manuscript-prepared core H05 metric contracts differ")
}
if (
  any(!stats::complete.cases(
    metric_registry[c("manuscript_name", "display_unit", "response_family")]
  )) ||
    nrow(approval_registry) != 13L ||
    any(!approval_registry$approved)
) {
  h05_abort("The H05 display or approval contract is incomplete")
}

h05_write_csv(input_audit, file.path(roots$model_data, "H05_input_audit.csv"))
h05_write_csv(
  approval_registry,
  file.path(roots$model_data, "H05_author_approvals.csv")
)
h05_write_csv(
  factor_registry,
  file.path(roots$model_data, "H05_factor_registry.csv")
)
h05_write_csv(
  metric_registry,
  file.path(roots$model_data, "H05_metric_registry.csv")
)
h05_write_csv(
  run_registry,
  file.path(roots$model_data, "H05_run_registry.csv")
)
h05_write_csv(
  leba_audit,
  file.path(roots$diagnostics, "H05_leba_score_audit.csv")
)

h01_fixed_site_evidence <- h01_fit_results$diagnostics |>
  dplyr::filter(.data$run_id == "main__glasses__all_available")
h01_random_site_evidence <- h01_fit_results$random_site |>
  dplyr::filter(.data$run_id == "main__glasses__all_available")
h05_site_structure_evidence <- tibble::tibble(
  evidence_source = "H01 main near-eye all-available fits",
  fixed_site_metrics = nrow(h01_fixed_site_evidence),
  fixed_site_converged = sum(h01_fixed_site_evidence$converged %in% TRUE),
  fixed_site_positive_definite_hessian = sum(
    h01_fixed_site_evidence$positive_definite_hessian %in% TRUE
  ),
  fixed_site_singular = sum(h01_fixed_site_evidence$singular %in% TRUE),
  fixed_site_pass = sum(
    h01_fixed_site_evidence$diagnostic_status == "PASS"
  ),
  fixed_site_warn_review = sum(
    h01_fixed_site_evidence$diagnostic_status == "WARN_REVIEW"
  ),
  random_site_descriptive_pass = sum(
    h01_random_site_evidence$status == "DESCRIPTIVE_PASS"
  ),
  random_site_descriptive_unstable = sum(
    h01_random_site_evidence$status == "DESCRIPTIVE_UNSTABLE"
  ),
  random_site_non_estimable = sum(
    h01_random_site_evidence$status == "NON_ESTIMABLE"
  ),
  random_site_singular = sum(
    h01_random_site_evidence$random_site_singular %in% TRUE
  ),
  author_resolution = paste0(
    "fixed site primary with sum contrasts; registered random site retained ",
    "as a sensitivity"
  )
)
h05_write_csv(
  h05_site_structure_evidence,
  file.path(roots$model_data, "H05_site_structure_evidence.csv")
)
h05_write_csv(
  metric_contract_comparison,
  file.path(roots$model_data, "H05_input_metric_contract_comparison.csv")
)

formula_registry <- tidyr::crossing(
  analysis_unit = c("participant", "participant_day"),
  formula_id = c("fixed_full", "fixed_reduced", "random_site")
) |>
  dplyr::rowwise() |>
  dplyr::mutate(
    formula = paste(
      deparse(h05_formula_set(.data$analysis_unit)[[.data$formula_id]]),
      collapse = " "
    )
  ) |>
  dplyr::ungroup()
h05_write_csv(
  formula_registry,
  file.path(roots$model_data, "H05_formula_registry.csv")
)

h05_identity <- function(run, spec, factor_row) {
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

h05_bind_identity <- function(identity, data) {
  if (nrow(data) == 0L) {
    return(data)
  }
  dplyr::bind_cols(identity[rep(1L, nrow(data)), , drop = FALSE], data)
}

results <- list(
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
  diagnostic_plot_data = list(),
  exact_bout = list()
)
result_index <- stats::setNames(rep(1L, length(results)), names(results))
add_result <- function(name, value) {
  if (nrow(value) == 0L) {
    return(invisible(NULL))
  }
  results[[name]][[result_index[[name]]]] <<- value
  result_index[[name]] <<- result_index[[name]] + 1L
  invisible(NULL)
}
model_frames <- list()
inferential_models <- list()

for (run_index in seq_len(nrow(run_registry))) {
  run <- run_registry[run_index, , drop = FALSE]
  object <- objects[[run$data_scenario_id]]
  message("H05 run ", run_index, "/8: ", run$run_id)
  for (metric_index in seq_len(nrow(metric_registry))) {
    spec <- metric_registry[metric_index, , drop = FALSE]
    message("  metric ", spec$metric_order, "/17: ", spec$metric_id)
    prepared <- h05_prepare_metric_rows(
      object,
      spec,
      placement = run$placement,
      sample_scenario = run$sample_scenario,
      leba = leba,
      site_levels = site_levels
    )
    frame_key <- paste(run$run_id, spec$metric_id, sep = "::")
    model_frames[[frame_key]] <- prepared$rows |>
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

    for (factor_index in seq_len(nrow(factor_registry))) {
      factor_row <- factor_registry[factor_index, , drop = FALSE]
      identity <- h05_identity(run, spec, factor_row)
      factor_frame <- h05_add_factor_to_frame(
        prepared$rows,
        spec,
        factor_row
      )
      frame <- factor_frame$frame
      sample_row <- dplyr::bind_cols(
        prepared$base_flow,
        factor_frame$scaling
      )
      add_result("samples", h05_bind_identity(identity, sample_row))

      if (nrow(frame) == 0L) {
        empty_bundle <- list(
          spec = spec,
          formulas = h05_formula_set(spec$analysis_unit),
          inferential = run$inferential_family,
          comparison_full = list(
            model = NULL,
            warnings = character(),
            error = "No estimable rows"
          ),
          comparison_reduced = list(
            model = NULL,
            warnings = character(),
            error = "No estimable rows"
          ),
          final = list(
            model = NULL,
            warnings = character(),
            error = "No estimable rows"
          )
        )
        add_result("effects", h05_bind_identity(identity, h05_empty_effect()))
        add_result("tests", h05_bind_identity(identity, h05_lrt_summary(empty_bundle)))
        add_result(
          "model_manifest",
          h05_bind_identity(identity, h05_model_manifest_rows(empty_bundle))
        )
        next
      }

      bundle <- h05_fit_bundle(
        frame,
        spec,
        inferential = run$inferential_family
      )
      effect <- h05_effect_summary(
        bundle$final$model,
        spec,
        factor_frame$scaling$leba_participant_sd
      )
      test <- h05_lrt_summary(bundle)
      diagnostic_seed <- as.integer(
        500000L + run_index * 10000L + metric_index * 100L + factor_index
      )
      diagnostics <- h05_diagnostic_summary(
        bundle,
        frame,
        seed = diagnostic_seed
      )
      model_manifest <- h05_model_manifest_rows(bundle)
      participant_summary <- h05_participant_summary(frame, spec)
      spearman <- h05_spearman_summary(participant_summary)
      influence <- h05_influence_candidates(
        bundle$final$model,
        frame,
        n = 3L
      )

      add_result("effects", h05_bind_identity(identity, effect))
      add_result("tests", h05_bind_identity(identity, test))
      add_result("diagnostics", h05_bind_identity(identity, diagnostics))
      add_result(
        "model_manifest",
        h05_bind_identity(identity, model_manifest)
      )
      add_result("spearman", h05_bind_identity(identity, spearman))
      add_result("influence", h05_bind_identity(identity, influence))

      if (run$inferential_family) {
        model_key <- paste(
          run$run_id,
          spec$metric_id,
          factor_row$factor_id,
          sep = "::"
        )
        inferential_models[[model_key]] <- bundle
      }

      main_all_available <-
        run$data_scenario_id == "main" &&
        run$sample_scenario == "all_available"
      if (main_all_available) {
        random_site <- h05_random_site_summary(
          frame,
          spec,
          factor_frame$scaling$leba_participant_sd
        )
        add_result(
          "random_site",
          h05_bind_identity(identity, random_site)
        )
        add_result(
          "site_spearman",
          h05_bind_identity(
            identity,
            h05_site_stratified_spearman(participant_summary)
          )
        )
        add_result(
          "loo_spearman",
          h05_bind_identity(
            identity,
            h05_leave_one_site_out_spearman(participant_summary)
          )
        )
      }

      primary_run <-
        run$data_scenario_id == "main" &&
        run$placement == "glasses" &&
        run$sample_scenario == "all_available"
      if (primary_run) {
        if (run_loo) {
          loo <- h05_leave_one_site_out(
            frame,
            spec,
            factor_frame$scaling$leba_participant_sd,
            full_estimate = effect$estimate_model_per_point
          )
          add_result("loo", h05_bind_identity(identity, loo))
        }
        plot_data <- h01_diagnostic_plot_data(bundle$final$model, frame)
        add_result(
          "diagnostic_plot_data",
          h05_bind_identity(identity, plot_data)
        )
        if (spec$metric_id == "longest_bout_above_250") {
          exact_rows <- prepared$rows[
            !is.na(prepared$rows$metric_any_censored) &
              !prepared$rows$metric_any_censored,
            ,
            drop = FALSE
          ]
          exact_factor_frame <- h05_add_factor_to_frame(
            exact_rows,
            spec,
            factor_row
          )
          exact_frame <- exact_factor_frame$frame
          exact_bundle <- h05_fit_bundle(
            exact_frame,
            spec,
            inferential = FALSE
          )
          exact_effect <- h05_effect_summary(
            exact_bundle$final$model,
            spec,
            exact_factor_frame$scaling$leba_participant_sd
          )
          exact_diagnostics <- h05_diagnostic_summary(
            exact_bundle,
            exact_frame,
            seed = diagnostic_seed + 900000L
          )
          exact_sample <- tibble::tibble(
            sensitivity_id = "longest_bout_exactly_identified_only",
            observations = nrow(exact_frame),
            participants = dplyr::n_distinct(exact_frame$participant_key),
            participant_days = nrow(exact_frame),
            sites = nlevels(exact_frame$site),
            leba_participant_mean =
              exact_factor_frame$scaling$leba_participant_mean,
            leba_participant_sd =
              exact_factor_frame$scaling$leba_participant_sd,
            model_frame_hash = exact_factor_frame$scaling$model_frame_hash
          )
          add_result(
            "exact_bout",
            h05_bind_identity(
              identity,
              dplyr::bind_cols(
                exact_sample,
                exact_effect,
                exact_diagnostics
              )
            )
          )
        }
      }
    }
  }
}

results <- lapply(results, dplyr::bind_rows)
effects <- results$effects
tests <- results$tests
diagnostics <- results$diagnostics
samples <- results$samples

if (
  nrow(effects) != 544L ||
    nrow(tests) != 544L ||
    nrow(diagnostics) != 544L ||
    nrow(samples) != 544L
) {
  h05_abort("H05 did not produce one core result per 8 x 17 x 4 cell")
}

inferential_tests <- tests |>
  dplyr::filter(.data$inferential_family) |>
  dplyr::mutate(family_instance_id = .data$family_id)
inferential_tests <- adjust_result_families(
  inferential_tests,
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
tests <- dplyr::bind_rows(inferential_tests, noninferential_tests) |>
  dplyr::arrange(
    .data$data_scenario_id,
    .data$placement,
    .data$sample_scenario,
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
    vector_bh_verified = all.equal(
      .data$p_adjusted,
      adjust_p_family(.data$p_raw, method = "BH", n = 68L),
      tolerance = 1e-14
    ) == TRUE,
    .groups = "drop"
  )
if (
  nrow(family_audit) != 3L ||
    any(family_audit$registry_rows != 68L) ||
    any(!family_audit$vector_bh_verified)
) {
  h05_abort("H05 multiplicity families fail the complete-vector audit")
}

master <- effects |>
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
  )

random_site <- results$random_site |>
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

loo_summary <- if (nrow(results$loo) > 0L) {
  results$loo |>
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
} else {
  tibble::tibble()
}

paired_effects <- effects |>
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
  )

mpd_comparison <- effects |>
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
  )

exact_bout <- results$exact_bout |>
  dplyr::left_join(
    effects |>
      dplyr::filter(
        .data$run_id == "main__glasses__all_available",
        .data$metric_id == "longest_bout_above_250"
      ) |>
      dplyr::select(
        .data$factor_id,
        all_available_estimate_model_per_sd = .data$estimate_model_per_sd,
        all_available_estimate_practical_per_sd =
          .data$estimate_practical_per_sd
      ),
    by = "factor_id",
    relationship = "one-to-one"
  ) |>
  dplyr::mutate(
    estimate_change_exact_minus_all_model_scale =
      .data$estimate_model_per_sd - .data$all_available_estimate_model_per_sd,
    sign_concordant = sign(.data$estimate_model_per_sd) ==
      sign(.data$all_available_estimate_model_per_sd)
  )

v0_registry <- h05_v0_metric_registry()
v0_near <- h05_reproduce_v0_placement(
  input_contract$v0_near_eye$path,
  "near-eye",
  leba,
  v0_registry,
  factor_registry
)
v0_chest <- h05_reproduce_v0_placement(
  input_contract$v0_chest$path,
  "chest",
  leba,
  v0_registry,
  factor_registry
)
v0_associations <- dplyr::bind_rows(
  v0_near$associations,
  v0_chest$associations
)
if (
  sum(v0_near$associations$v0_display_flag) != 2L ||
    sum(v0_chest$associations$v0_display_flag) != 1L ||
    sum(v0_near$associations$consistent_spearman_flag) != 2L ||
    sum(v0_chest$associations$consistent_spearman_flag) != 0L
) {
  h05_abort("The clean Stage 2 V0 reconstruction differs from Stage 1")
}

v0_to_new <- v0_associations |>
  dplyr::filter(.data$placement == "near-eye") |>
  dplyr::left_join(
    results$spearman |>
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
    v0_repaired_rho_change =
      .data$new_descriptive_rho - .data$spearman_rho,
    primary_bh_flag = .data$fixed_site_p_adjusted <= 0.05
  )

primary_master <- master |>
  dplyr::filter(
    .data$data_scenario_id == "main",
    .data$placement == "glasses",
    .data$sample_scenario == "all_available"
  )
primary_highlights <- primary_master |>
  dplyr::filter(.data$p_adjusted <= 0.05) |>
  dplyr::arrange(.data$p_adjusted)

h05_write_rds(
  list(
    hypothesis_id = "H05",
    status = "stage2_complete_author_gate",
    input_contract = input_contract,
    approvals = approval_registry,
    factor_registry = factor_registry,
    metric_registry = metric_registry,
    run_registry = run_registry,
    model_frames = model_frames,
    metadata = list(
      r_version = as.character(getRversion()),
      participant_centering = paste0(
        "mean and sample SD over unique participants in each exact ",
        "run-metric-factor model frame"
      ),
      primary_site_structure = "fixed_site_sum_contrasts",
      random_site_role = "registered_sensitivity",
      l10_noon_sensitivity = "not_run_author_excluded"
    )
  ),
  file.path(roots$model_data, "H05_model_frames.rds")
)
h05_write_rds(
  inferential_models,
  file.path(roots$models, "H05_inferential_model_objects.rds")
)

h05_write_csv(samples, file.path(roots$model_data, "H05_model_frame_index.csv"))
h05_write_csv(effects, file.path(roots$tables, "H05_model_effects.csv"))
h05_write_csv(tests, file.path(roots$tables, "H05_model_tests.csv"))
h05_write_csv(master, file.path(roots$tables, "H05_model_results_master.csv"))
h05_write_csv(family_audit, file.path(roots$tables, "H05_family_audit.csv"))
h05_write_csv(
  primary_highlights,
  file.path(roots$tables, "H05_primary_bh_highlights.csv")
)
h05_write_csv(
  diagnostics,
  file.path(roots$diagnostics, "H05_model_diagnostics.csv")
)
h05_write_csv(
  results$model_manifest,
  file.path(roots$models, "H05_model_manifest.csv")
)
h05_write_csv(
  results$influence,
  file.path(roots$diagnostics, "H05_participant_influence_screen.csv")
)
h05_write_csv(
  random_site,
  file.path(roots$tables, "H05_random_site_sensitivity.csv")
)
h05_write_csv(
  results$loo,
  file.path(roots$tables, "H05_leave_one_site_out_refits.csv")
)
h05_write_csv(
  loo_summary,
  file.path(roots$tables, "H05_leave_one_site_out_summary.csv")
)
h05_write_csv(
  results$spearman,
  file.path(roots$tables, "H05_descriptive_spearman.csv")
)
h05_write_csv(
  results$site_spearman,
  file.path(roots$diagnostics, "H05_site_stratified_spearman.csv")
)
h05_write_csv(
  results$loo_spearman,
  file.path(roots$diagnostics, "H05_leave_one_site_out_spearman.csv")
)
h05_write_csv(
  paired_effects,
  file.path(roots$tables, "H05_paired_placement_comparison.csv")
)
h05_write_csv(
  mpd_comparison,
  file.path(roots$tables, "H05_manuscript_prepared_comparison.csv")
)
h05_write_csv(
  exact_bout,
  file.path(
    roots$tables,
    "H05_exactly_identified_longest_bout_sensitivity.csv"
  )
)
h05_write_csv(
  v0_associations,
  file.path(roots$tables, "H05_v0_reproduction.csv")
)
h05_write_csv(
  v0_to_new,
  file.path(roots$tables, "H05_v0_to_new_comparison.csv")
)
h05_write_csv(
  results$diagnostic_plot_data,
  file.path(roots$source_data, "H05_primary_diagnostic_plot_data.csv")
)

h05_v0_plot <- function(data, corrected = FALSE, title) {
  plot_data <- data |>
    dplyr::mutate(
      metric_label = stringr::str_to_sentence(
        stringr::str_replace_all(.data$v0_name, "_", " ")
      ),
      metric_label = factor(
        .data$metric_label,
        levels = unique(.data$metric_label[order(.data$v0_plot_order)])
      ),
      factor_display = paste0(
        stringr::str_to_upper(stringr::str_remove(.data$factor_id, "leba_")),
        ": ",
        .data$factor_label
      ),
      factor_display = factor(
        .data$factor_display,
        levels = rev(unique(.data$factor_display[order(.data$factor_order)]))
      ),
      displayed_p = if (corrected) {
        .data$consistent_spearman_vector_bh
      } else {
        .data$v0_display_p
      },
      displayed_flag = if (corrected) {
        .data$consistent_spearman_flag
      } else {
        .data$v0_display_flag
      },
      label = paste0(
        "rho=", sprintf("%.2f", .data$spearman_rho),
        if (corrected) "\nq=" else "\np=",
        scales::pvalue(.data$displayed_p, accuracy = 0.001)
      )
    )
  plot <- ggplot2::ggplot(
    plot_data,
    ggplot2::aes(x = .data$metric_label, y = .data$factor_display)
  ) +
    ggplot2::geom_blank()
  if (corrected) {
    plot <- plot +
      ggplot2::geom_tile(
        ggplot2::aes(fill = .data$spearman_rho),
        colour = "white",
        linewidth = 0.25
      ) +
      ggplot2::scale_fill_gradient2(
        low = "#3B4CC0",
        mid = "white",
        high = "#B40426",
        midpoint = 0,
        limits = c(-0.4, 0.4),
        oob = scales::squish,
        name = "Spearman rho"
      )
  } else {
    plot <- plot +
      ggplot2::geom_tile(
        data = plot_data[plot_data$displayed_flag, , drop = FALSE],
        ggplot2::aes(fill = abs(.data$spearman_rho)),
        linewidth = 0.25
      ) +
      ggplot2::scale_fill_viridis_c(limits = c(0, 1), guide = "none")
  }
  plot +
    ggplot2::geom_text(
      ggplot2::aes(
        label = .data$label,
        colour = .data$displayed_flag
      ),
      fontface = "bold",
      size = 2.15,
      lineheight = 0.9
    ) +
    ggplot2::scale_colour_manual(
      values = c(`FALSE` = "#D7191C", `TRUE` = "white"),
      guide = "none"
    ) +
    ggplot2::coord_fixed() +
    ggplot2::labs(
      title = title,
      subtitle = if (corrected) {
        "Consistent Spearman tests with one vector-wide 68-cell BH adjustment"
      } else {
        paste0(
          "Faithful V0 computation: Spearman coefficient with Pearson-derived ",
          "scalar p adjustment"
        )
      },
      x = "Metrics",
      y = "LEBA factors"
    ) +
    ggplot2::theme_minimal(base_size = 10) +
    ggplot2::theme(
      axis.text.x = ggplot2::element_text(angle = 45, hjust = 1),
      panel.grid = ggplot2::element_blank(),
      plot.title.position = "plot"
    )
}

v0_source_path <- file.path(
  roots$source_data,
  "H05_v0_correlation_figure_data.csv"
)
h05_write_csv(v0_associations, v0_source_path)
for (placement_value in c("near-eye", "chest")) {
  placement_data <- v0_associations |>
    dplyr::filter(.data$placement == placement_value)
  for (corrected in c(FALSE, TRUE)) {
    version <- if (corrected) "corrected" else "faithful"
    plot <- h05_v0_plot(
      placement_data,
      corrected = corrected,
      title = paste0(
        "H05 V0 correlation matrix - ",
        placement_value,
        " (",
        version,
        ")"
      )
    )
    for (extension in c("png", "pdf")) {
      ggplot2::ggsave(
        filename = file.path(
          roots$figures,
          paste0(
            "H05_v0_",
            stringr::str_replace_all(placement_value, "-", "_"),
            "_",
            version,
            ".",
            extension
          )
        ),
        plot = plot,
        width = 13,
        height = 5.5,
        dpi = 220
      )
    }
  }
}

primary_figure_data <- primary_master |>
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
    q_label = ifelse(
      .data$p_adjusted <= 0.05,
      paste0("q=", scales::pvalue(.data$p_adjusted, accuracy = 0.001)),
      ""
    )
  )
h05_write_csv(
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
  ggplot2::geom_tile(
    data = primary_figure_data[
      primary_figure_data$p_adjusted <= 0.05,
      ,
      drop = FALSE
    ],
    fill = NA,
    colour = "black",
    linewidth = 1.1
  ) +
  ggplot2::geom_text(
    ggplot2::aes(label = paste(.data$effect_label, .data$q_label, sep = "\n")),
    size = 2.4,
    lineheight = 0.9
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
      "black borders mark q <= 0.05"
    ),
    x = NULL,
    y = NULL
  ) +
  ggplot2::theme_minimal(base_size = 10) +
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
  dpi = 220
)
ggplot2::ggsave(
  file.path(roots$figures, "H05_primary_effect_overview.pdf"),
  primary_plot,
  width = 11,
  height = 9
)

diagnostic_figure_data <- primary_master |>
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
    )
  )
h05_write_csv(
  diagnostic_figure_data,
  file.path(roots$source_data, "H05_primary_adequacy_overview_data.csv")
)
diagnostic_plot <- ggplot2::ggplot(
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
    subtitle = "Every factor-metric model is classified using the approved fit, residual, support, and dependence checks",
    x = NULL,
    y = NULL
  ) +
  ggplot2::theme_minimal(base_size = 10) +
  ggplot2::theme(
    panel.grid = ggplot2::element_blank(),
    axis.text.x = ggplot2::element_text(angle = 30, hjust = 1),
    plot.title.position = "plot"
  )
ggplot2::ggsave(
  file.path(roots$figures, "H05_primary_model_adequacy.png"),
  diagnostic_plot,
  width = 11,
  height = 8.5,
  dpi = 220
)

h05_write_csv(
  paired_effects,
  file.path(roots$source_data, "H05_paired_effect_comparison_data.csv")
)
paired_plot <- ggplot2::ggplot(
  paired_effects,
  ggplot2::aes(
    x = .data$estimate_model_per_sd__glasses,
    y = .data$estimate_model_per_sd__chest,
    colour = .data$factor_label
  )
) +
  ggplot2::geom_hline(yintercept = 0, colour = "grey75") +
  ggplot2::geom_vline(xintercept = 0, colour = "grey75") +
  ggplot2::geom_abline(slope = 1, intercept = 0, linetype = 2) +
  ggplot2::geom_point(alpha = 0.8, size = 2) +
  ggplot2::facet_wrap(~factor_label, scales = "free") +
  ggplot2::labs(
    title = "Paired/common-sample near-eye and chest effects",
    subtitle = "Model-scale effects per participant SD; component intervals are reported in the paired table",
    x = "Near-eye estimate",
    y = "Chest estimate"
  ) +
  ggplot2::guides(colour = "none") +
  ggplot2::theme_minimal(base_size = 10)
ggplot2::ggsave(
  file.path(roots$figures, "H05_paired_placement_effects.png"),
  paired_plot,
  width = 10,
  height = 7,
  dpi = 220
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
h05_write_csv(
  environment,
  file.path(roots$manifests, "H05_execution_environment.csv")
)

h05_build_manifest()
message(
  "H05 Stage 2 complete: ",
  nrow(primary_highlights),
  " primary BH cells; adequacy = ",
  paste(
    names(table(primary_master$model_adequacy)),
    as.integer(table(primary_master$model_adequacy)),
    sep = ":",
    collapse = ", "
  )
)
