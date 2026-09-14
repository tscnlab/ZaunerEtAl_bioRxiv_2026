# Audit the bounded H01 consequences of METRIC-011.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
base::source(file.path(root, "scripts/pipeline/paths_io.R"))
base::source(file.path(root, "scripts/pipeline/multiplicity.R"))
base::source(file.path(root, "scripts/hypotheses/H01/h01_contract.R"))
base::source(file.path(root, "scripts/hypotheses/H01/h01_modeling.R"))

if (!identical(as.character(getRversion()), "4.6.1")) {
  h01_abort(
    "The H01 METRIC-011 audit requires R 4.6.1; found %s",
    as.character(getRversion())
  )
}

producer <- "scripts/hypotheses/H01/audit_h01_l10_METRIC011.R"
metric_id <- "l10_mean_medi"
audit_root <- file.path(
  root,
  "audit/hypotheses/H01/l10_METRIC-011"
)
point_root <- file.path(audit_root, "point_refit")
pilot_root <- file.path(audit_root, "bootstrap_pilot")
review_root <- file.path(audit_root, "author_gate")
dir.create(review_root, recursive = TRUE, showWarnings = FALSE)

read_csv_required <- function(path) {
  if (!file.exists(path)) {
    h01_abort("Missing H01 METRIC-011 input: %s", path)
  }
  readr::read_csv(path, show_col_types = FALSE, progress = FALSE)
}

write_review_csv <- function(data, name) {
  path <- file.path(review_root, name)
  write_csv_artifact(data, path, producer = producer)
  invisible(path)
}

accepted_table_path <- function(name) {
  file.path(root, "artifacts/09_tables/H01", name)
}

accepted_diagnostic_path <- function(name) {
  file.path(root, "artifacts/08_diagnostics/H01", name)
}

point_table_path <- function(name) {
  file.path(point_root, "artifacts/09_tables/H01", name)
}

point_diagnostic_path <- function(name) {
  file.path(point_root, "artifacts/08_diagnostics/H01", name)
}

pin_paths <- c(
  metric_decision = "audit/decisions/l10_numerical_zero_normalization.md",
  evidence_manifest = paste0(
    "audit/reconciliation/l10_METRIC-011/",
    "METRIC-011_evidence_manifest.csv"
  ),
  main_manifest = "artifacts/12_manifests/H01_model_data_artifacts.csv",
  main_rds = "artifacts/06_model_data/H01.rds",
  gap_manifest = paste0(
    "artifacts/12_manifests/",
    "H01_manuscript_prepared_data_artifacts.csv"
  ),
  gap_rds = paste0(
    "artifacts/06_model_data/H01/scenarios/",
    "manuscript_prepared_data/H01.rds"
  )
)
pin_sha256 <- c(
  metric_decision =
    "23b9f70d1d16f7fd3ebbdbc57aaf78c0a701fe1f9d22bd667d926cd320d40797",
  evidence_manifest =
    "a37efd3449a8d1a6065d0eb8964bd6cf8b241f1683a26c065ea1a946e23214fb",
  main_manifest =
    "25978c5d6903e6e835c1aff6a9bc2e7552b85295e8d840d3dd65bbf9b1eb6b72",
  main_rds =
    "0328fe1a698bc13965feb0b68b03ccf0fd20f32b55d6148635811b0d674e0a00",
  gap_manifest =
    "e0d98178ede61b74353e3a654e7f1b53d7e1c915833a2cda74eea45ed02f383b",
  gap_rds =
    "3c70363fc0468202a431904aa9d9444f2858af2e3add3475a56c872b49a18bd6"
)
absolute_pin_paths <- stats::setNames(
  file.path(root, unname(pin_paths)),
  names(pin_paths)
)
observed_pin_sha256 <- vapply(
  absolute_pin_paths,
  artifact_sha256,
  character(1)
)
if (!identical(unname(observed_pin_sha256), unname(pin_sha256))) {
  h01_abort("One or more H01 METRIC-011 pins changed")
}
input_pins <- tibble::tibble(
  input_id = names(pin_paths),
  path = unname(pin_paths),
  sha256 = unname(observed_pin_sha256),
  expected_sha256 = unname(pin_sha256),
  bytes = as.numeric(file.info(absolute_pin_paths)$size),
  status = "PASS"
)
write_review_csv(input_pins, "H01_METRIC-011_input_pins.csv")

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
run_registry <- h01_run_registry()
affected_runs <- run_registry |>
  dplyr::filter(.data$data_scenario_id == "main")
gap_runs <- run_registry |>
  dplyr::filter(.data$data_scenario_id == "manuscript_prepared_data")
stopifnot(nrow(affected_runs) == 4L, nrow(gap_runs) == 4L)

main_object <- readRDS(absolute_pin_paths[["main_rds"]])
gap_object <- readRDS(absolute_pin_paths[["gap_rds"]])
objects <- list(
  main = main_object,
  manuscript_prepared_data = gap_object
)

accepted_names <- c(
  tests = "H01_model_level_tests.csv",
  term_effects = "H01_term_effects.csv",
  site_estimates = "H01_site_estimates.csv",
  site_deviations = "H01_site_deviations.csv",
  marginalization = "H01_marginalization_comparison.csv",
  samples = "H01_exact_samples.csv",
  samples_by_site = "H01_exact_samples_by_site.csv",
  latitude_loo = "H01_latitude_leave_one_site_out.csv",
  random_site = "H01_random_site_descriptions.csv",
  r2_point = "H01_r2_point_summaries.csv",
  model_manifest = "H01_model_manifest.csv",
  preregistered_scope = "H01_preregistered_scope_sensitivity.csv"
)
accepted <- lapply(accepted_names, function(name) {
  if (name == "H01_latitude_leave_one_site_out.csv") {
    read_csv_required(accepted_diagnostic_path(name))
  } else {
    read_csv_required(accepted_table_path(name))
  }
})
accepted$diagnostics <- read_csv_required(
  accepted_diagnostic_path("H01_model_diagnostics.csv")
)
accepted$influence <- read_csv_required(
  accepted_diagnostic_path("H01_participant_influence.csv")
)

point <- lapply(accepted_names, function(name) {
  if (name == "H01_latitude_leave_one_site_out.csv") {
    read_csv_required(point_diagnostic_path(name))
  } else {
    read_csv_required(point_table_path(name))
  }
})
point$diagnostics <- read_csv_required(
  point_diagnostic_path("H01_model_diagnostics.csv")
)
point$influence <- read_csv_required(
  point_diagnostic_path("H01_participant_influence.csv")
)
for (name in names(point)) {
  data <- point[[name]]
  if (nrow(data) > 0L && "metric_id" %in% names(data)) {
    if (
      any(data$metric_id != metric_id) ||
        any(data$data_scenario_id != "main")
    ) {
      h01_abort("The isolated point output `%s` is out of scope", name)
    }
  }
}

frame_comparisons <- list()
changed_rows <- list()
distribution_rows <- list()
for (run_index in seq_len(nrow(run_registry))) {
  run <- run_registry[run_index, , drop = FALSE]
  current_frame <- h01_prepare_model_frame(
    objects[[run$data_scenario_id]],
    spec,
    placement = run$placement,
    sample_scenario = run$sample_scenario
  )
  accepted_frame_path <- file.path(
    root,
    "artifacts/07_models/H01",
    run$data_scenario_id,
    run$placement,
    run$sample_scenario,
    paste0(metric_id, "_model_frame.rds")
  )
  accepted_frame <- readRDS(accepted_frame_path)
  stopifnot(identical(accepted_frame$.model_row_id, current_frame$.model_row_id))
  if (run$data_scenario_id == "main") {
    point_frame_path <- file.path(
      point_root,
      "artifacts/07_models/H01",
      run$data_scenario_id,
      run$placement,
      run$sample_scenario,
      paste0(metric_id, "_model_frame.rds")
    )
    point_frame <- readRDS(point_frame_path)
    stopifnot(identical(current_frame, point_frame))
  }
  changed <- accepted_frame$value != current_frame$value
  response_changed <-
    accepted_frame$response_value != current_frame$response_value
  frame_comparisons[[run_index]] <- tibble::tibble(
    run_id = run$run_id,
    data_scenario_id = run$data_scenario_id,
    placement = run$placement,
    sample_scenario = run$sample_scenario,
    rows = nrow(current_frame),
    row_keys_identical = identical(
      accepted_frame$.model_row_id,
      current_frame$.model_row_id
    ),
    changed_value_rows = sum(changed),
    changed_response_rows = sum(response_changed),
    max_absolute_value_change = if (any(changed)) {
      max(abs(accepted_frame$value[changed] - current_frame$value[changed]))
    } else {
      0
    },
    max_absolute_response_change = if (any(response_changed)) {
      max(abs(
        accepted_frame$response_value[response_changed] -
          current_frame$response_value[response_changed]
      ))
    } else {
      0
    },
    current_frame_identical = identical(accepted_frame, current_frame)
  )
  if (any(changed)) {
    changed_rows[[length(changed_rows) + 1L]] <- tibble::tibble(
      run_id = run$run_id,
      placement = run$placement,
      sample_scenario = run$sample_scenario,
      model_row_id = current_frame$.model_row_id[changed],
      site = as.character(current_frame$site[changed]),
      participant_key = current_frame$participant_key[changed],
      local_date = as.character(current_frame$local_date[changed]),
      accepted_value = accepted_frame$value[changed],
      current_value = current_frame$value[changed],
      accepted_response_value = accepted_frame$response_value[changed],
      current_response_value = current_frame$response_value[changed]
    )
  }
  distribution_rows[[run_index]] <- tibble::tibble(
    run_id = run$run_id,
    data_scenario_id = run$data_scenario_id,
    placement = run$placement,
    sample_scenario = run$sample_scenario,
    participants = dplyr::n_distinct(current_frame$participant_key),
    participant_days = nrow(current_frame),
    observations = nrow(current_frame),
    sites = dplyr::n_distinct(current_frame$site),
    exact_zero_n = sum(current_frame$value == 0),
    exact_zero_fraction = mean(current_frame$value == 0),
    minimum_lx = min(current_frame$value),
    median_lx = stats::median(current_frame$value),
    mean_lx = mean(current_frame$value),
    maximum_lx = max(current_frame$value),
    minimum_transformed = min(current_frame$response_value),
    median_transformed = stats::median(current_frame$response_value),
    maximum_transformed = max(current_frame$response_value)
  )
}
frame_comparison <- dplyr::bind_rows(frame_comparisons)
changed_rows <- dplyr::bind_rows(changed_rows)
distribution_summary <- dplyr::bind_rows(distribution_rows)
stopifnot(
  sum(
    frame_comparison$changed_value_rows[
      frame_comparison$data_scenario_id == "main" &
        frame_comparison$sample_scenario == "all_available"
    ]
  ) == 8L,
  all(
    frame_comparison$changed_value_rows[
      frame_comparison$data_scenario_id == "manuscript_prepared_data"
    ] == 0L
  ),
  nrow(changed_rows) == 16L,
  all(changed_rows$current_value == 0)
)
write_review_csv(
  frame_comparison,
  "H01_METRIC-011_model_frame_comparison.csv"
)
write_review_csv(changed_rows, "H01_METRIC-011_changed_model_rows.csv")
write_review_csv(
  distribution_summary,
  "H01_METRIC-011_distribution_summary.csv"
)

derived_test_columns <- c(
  "family_instance_id",
  "p_adjusted",
  "family_rank",
  "family_observed_tests",
  "family_status"
)
test_base_columns <- setdiff(names(accepted$tests), derived_test_columns)
accepted_affected_tests <- accepted$tests |>
  dplyr::filter(.data$run_id %in% affected_runs$run_id)
point_test_base <- point$tests |>
  dplyr::select(dplyr::all_of(test_base_columns))
complete_tests <- dplyr::bind_rows(
  accepted_affected_tests |>
    dplyr::filter(.data$metric_id != !!metric_id) |>
    dplyr::select(dplyr::all_of(test_base_columns)),
  point_test_base
) |>
  dplyr::mutate(
    family_instance_id = paste(.data$run_id, .data$family_id, sep = "::")
  )
complete_tests <- adjust_result_families(
  complete_tests,
  family_col = "family_instance_id",
  p_col = "p_raw",
  family_n_col = "family_n",
  output_col = "p_adjusted",
  method = "BH"
) |>
  dplyr::group_by(.data$family_instance_id) |>
  dplyr::mutate(
    family_rank = ifelse(
      is.na(.data$p_raw),
      NA_integer_,
      rank(.data$p_raw, ties.method = "min", na.last = "keep")
    ),
    family_observed_tests = sum(!is.na(.data$p_raw))
  ) |>
  dplyr::ungroup()
complete_diagnostics <- dplyr::bind_rows(
  accepted$diagnostics |>
    dplyr::filter(
      .data$run_id %in% affected_runs$run_id,
      .data$metric_id != !!metric_id
    ),
  point$diagnostics
)
gated_runs <- unique(
  complete_diagnostics$run_id[
    complete_diagnostics$diagnostic_status == "FAIL_MAJOR_GATE"
  ]
)
complete_tests <- complete_tests |>
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
  ) |>
  dplyr::arrange(
    .data$run_id,
    .data$family_order,
    .data$metric_order
  )
families <- split(complete_tests, complete_tests$family_instance_id)
stopifnot(
  nrow(complete_tests) == 4L * 4L * 17L,
  length(families) == 16L,
  all(vapply(families, nrow, integer(1)) == 17L),
  all(complete_tests$family_status == "COMPLETE")
)
write_review_csv(
  complete_tests,
  "H01_METRIC-011_complete_model_level_tests.csv"
)

test_keys <- c("run_id", "metric_id", "comparison_id")
test_impact <- dplyr::inner_join(
  accepted_affected_tests |>
    dplyr::select(
      dplyr::all_of(test_keys),
      old_p_raw = p_raw,
      old_p_adjusted = p_adjusted,
      old_family_rank = family_rank,
      old_family_status = family_status
    ),
  complete_tests |>
    dplyr::select(
      dplyr::all_of(test_keys),
      metric_order,
      family_id,
      new_p_raw = p_raw,
      new_p_adjusted = p_adjusted,
      new_family_rank = family_rank,
      new_family_status = family_status
    ),
  by = test_keys,
  relationship = "one-to-one"
) |>
  dplyr::mutate(
    raw_p_delta = .data$new_p_raw - .data$old_p_raw,
    adjusted_p_delta = .data$new_p_adjusted - .data$old_p_adjusted,
    old_supported = !is.na(.data$old_p_adjusted) &
      .data$old_p_adjusted < 0.05,
    new_supported = !is.na(.data$new_p_adjusted) &
      .data$new_p_adjusted < 0.05,
    support_changed = .data$old_supported != .data$new_supported,
    raw_p_unchanged_for_non_l10 = dplyr::if_else(
      .data$metric_id == .env$metric_id,
      NA,
      (is.na(.data$old_p_raw) & is.na(.data$new_p_raw)) |
        abs(.data$old_p_raw - .data$new_p_raw) <=
          16 * .Machine$double.eps * pmax(
            abs(.data$old_p_raw),
            abs(.data$new_p_raw),
            .Machine$double.xmin,
            na.rm = TRUE
          )
    )
  )
stopifnot(
  nrow(test_impact) == nrow(accepted_affected_tests),
  all(
    test_impact$raw_p_unchanged_for_non_l10[
      test_impact$metric_id != metric_id
    ]
  ),
  !any(test_impact$support_changed)
)
write_review_csv(test_impact, "H01_METRIC-011_complete_BH_impact.csv")

new_site_support <- complete_tests |>
  dplyr::filter(
    .data$metric_id == .env$metric_id,
    .data$family_id == "H01-F1-site"
  ) |>
  dplyr::select(
    run_id,
    overall_site_p_adjusted = p_adjusted
  )
point_site_deviations <- point$site_deviations |>
  dplyr::select(-dplyr::any_of(c(
    "overall_site_p_adjusted",
    "inferential_followup_supported"
  ))) |>
  dplyr::left_join(
    new_site_support,
    by = "run_id",
    relationship = "many-to-one"
  ) |>
  dplyr::mutate(
    inferential_followup_supported =
      !is.na(.data$overall_site_p_adjusted) &
      .data$overall_site_p_adjusted < 0.05
  )
write_review_csv(
  point_site_deviations,
  "H01_METRIC-011_site_deviations.csv"
)
write_review_csv(point$site_estimates, "H01_METRIC-011_site_estimates.csv")
write_review_csv(point$term_effects, "H01_METRIC-011_term_effects.csv")
write_review_csv(point$samples, "H01_METRIC-011_exact_samples.csv")
write_review_csv(
  point$samples_by_site,
  "H01_METRIC-011_exact_samples_by_site.csv"
)
write_review_csv(point$diagnostics, "H01_METRIC-011_model_diagnostics.csv")
write_review_csv(
  point$influence,
  "H01_METRIC-011_participant_influence.csv"
)
write_review_csv(
  point$latitude_loo,
  "H01_METRIC-011_latitude_leave_one_site_out.csv"
)
write_review_csv(
  point$random_site,
  "H01_METRIC-011_random_site_descriptions.csv"
)
write_review_csv(point$r2_point, "H01_METRIC-011_r2_point_summaries.csv")
write_review_csv(
  point$marginalization,
  "H01_METRIC-011_marginalization_comparison.csv"
)
write_review_csv(
  point$preregistered_scope,
  "H01_METRIC-011_preregistered_scope_sensitivity.csv"
)

compare_columns <- function(old, new, keys, value_columns) {
  old |>
    dplyr::filter(
      .data$run_id %in% affected_runs$run_id,
      .data$metric_id == .env$metric_id
    ) |>
    dplyr::select(
      dplyr::all_of(keys),
      dplyr::all_of(value_columns)
    ) |>
    dplyr::rename_with(
      ~paste0(.x, "_old"),
      dplyr::all_of(value_columns)
    ) |>
    dplyr::inner_join(
      new |>
        dplyr::select(
          dplyr::all_of(keys),
          dplyr::all_of(value_columns)
        ) |>
        dplyr::rename_with(
          ~paste0(.x, "_new"),
          dplyr::all_of(value_columns)
        ),
      by = keys,
      relationship = "one-to-one"
    )
}

term_comparison <- compare_columns(
  accepted$term_effects,
  point$term_effects,
  keys = c("run_id", "metric_id", "term"),
  value_columns = c(
    "estimate_model",
    "std_error",
    "conf_low_model",
    "conf_high_model",
    "p_raw",
    "estimate_practical",
    "conf_low_practical",
    "conf_high_practical",
    "status"
  )
)
write_review_csv(term_comparison, "H01_METRIC-011_term_effect_comparison.csv")

sample_comparison <- compare_columns(
  accepted$samples,
  point$samples,
  keys = c("run_id", "metric_id"),
  value_columns = c(
    "participants",
    "participant_days",
    "observations",
    "sites",
    "sample_status"
  )
)
write_review_csv(sample_comparison, "H01_METRIC-011_sample_comparison.csv")

diagnostic_comparison <- compare_columns(
  accepted$diagnostics,
  point$diagnostics,
  keys = c("run_id", "metric_id"),
  value_columns = c(
    "converged",
    "positive_definite_hessian",
    "singular",
    "max_gradient",
    "shapiro_p",
    "residual_variance_ratio",
    "standardized_residual_over_3_fraction",
    "standardized_residual_over_4_fraction",
    "residual_status",
    "prediction_bound_status",
    "diagnostic_status"
  )
)
write_review_csv(
  diagnostic_comparison,
  "H01_METRIC-011_diagnostic_comparison.csv"
)

r2_comparison <- compare_columns(
  accepted$r2_point,
  point$r2_point,
  keys = c("run_id", "metric_id", "approximation"),
  value_columns = c(
    "marginal_r2",
    "conditional_r2",
    "participant_associated_share",
    "site_part_r2",
    "photoperiod_part_r2",
    "latitude_model_marginal_r2",
    "latitude_part_r2",
    "unrepresented_share",
    "status"
  )
)
write_review_csv(r2_comparison, "H01_METRIC-011_r2_point_comparison.csv")

influence_summary <- function(data, suffix) {
  data |>
    dplyr::filter(
      .data$run_id %in% affected_runs$run_id,
      .data$metric_id == .env$metric_id
    ) |>
    dplyr::group_by(.data$run_id, .data$metric_id) |>
    dplyr::summarise(
      successful_refits = sum(.data$refit_status == "PASS"),
      failed_refits = sum(.data$refit_status != "PASS"),
      maximum_absolute_dfbeta = max(
        .data$maximum_absolute_dfbeta,
        na.rm = TRUE
      ),
      maximum_participant = .data$omitted_participant[
        which.max(.data$maximum_absolute_dfbeta)
      ],
      maximum_term = .data$maximum_dfbeta_term[
        which.max(.data$maximum_absolute_dfbeta)
      ],
      .groups = "drop"
    ) |>
    dplyr::rename_with(
      ~paste0(.x, suffix),
      -dplyr::all_of(c("run_id", "metric_id"))
    )
}
influence_comparison <- dplyr::inner_join(
  influence_summary(accepted$influence, "_old"),
  influence_summary(point$influence, "_new"),
  by = c("run_id", "metric_id"),
  relationship = "one-to-one"
)
write_review_csv(
  influence_comparison,
  "H01_METRIC-011_influence_comparison.csv"
)

paired_effects <- point$term_effects |>
  dplyr::filter(.data$sample_scenario == "paired_common_sample") |>
  dplyr::select(
    run_id,
    placement,
    term,
    effect_type,
    estimate_practical,
    conf_low_practical,
    conf_high_practical,
    term_p_raw = p_raw,
    status
  )
paired_tests <- complete_tests |>
  dplyr::filter(
    .data$metric_id == .env$metric_id,
    .data$sample_scenario == "paired_common_sample",
    .data$comparison_id %in% c(
      "site_full_vs_no_photoperiod",
      "latitude_full_vs_no_latitude"
    )
  ) |>
  dplyr::mutate(
    term = dplyr::if_else(
      .data$comparison_id == "site_full_vs_no_photoperiod",
      "photoperiod_centered_hours",
      "absolute_latitude_10deg_centered"
    )
  ) |>
  dplyr::select(
    run_id,
    term,
    model_p_raw = p_raw,
    model_p_adjusted = p_adjusted,
    family_status
  )
paired_samples <- point$samples |>
  dplyr::filter(.data$sample_scenario == "paired_common_sample") |>
  dplyr::select(
    run_id,
    participants,
    participant_days,
    observations,
    sites
  )
paired <- paired_effects |>
  dplyr::left_join(
    paired_tests,
    by = c("run_id", "term"),
    relationship = "one-to-one"
  ) |>
  dplyr::left_join(
    paired_samples,
    by = "run_id",
    relationship = "many-to-one"
  )
near <- paired |>
  dplyr::filter(.data$placement == "glasses") |>
  dplyr::select(-placement, -run_id) |>
  dplyr::rename_with(~paste0("near_", .x), -term)
chest <- paired |>
  dplyr::filter(.data$placement == "chest") |>
  dplyr::select(-placement, -run_id) |>
  dplyr::rename_with(~paste0("chest_", .x), -term)
paired_comparison <- dplyr::inner_join(
  near,
  chest,
  by = "term",
  relationship = "one-to-one"
) |>
  dplyr::mutate(
    sample_exactly_matched =
      .data$near_participants == .data$chest_participants &
      .data$near_participant_days == .data$chest_participant_days &
      .data$near_observations == .data$chest_observations &
      .data$near_sites == .data$chest_sites,
    same_side_of_null =
      sign(log(.data$near_estimate_practical)) ==
      sign(log(.data$chest_estimate_practical))
  )
stopifnot(nrow(paired_comparison) == 2L, all(paired_comparison$sample_exactly_matched))
write_review_csv(
  paired_comparison,
  "H01_METRIC-011_paired_placement_comparison.csv"
)

gap_effects <- accepted$term_effects |>
  dplyr::filter(
    .data$data_scenario_id == "manuscript_prepared_data",
    .data$metric_id == .env$metric_id
  )
gap_tests <- accepted$tests |>
  dplyr::filter(
    .data$data_scenario_id == "manuscript_prepared_data",
    .data$metric_id == .env$metric_id
  )
gap_samples <- accepted$samples |>
  dplyr::filter(
    .data$data_scenario_id == "manuscript_prepared_data",
    .data$metric_id == .env$metric_id
  )
scenario_pairs <- affected_runs |>
  dplyr::transmute(
    primary_run_id = .data$run_id,
    gap_run_id = paste(
      "manuscript_prepared_data",
      .data$placement,
      .data$sample_scenario,
      sep = "__"
    )
  )
primary_effects <- point$term_effects |>
  dplyr::left_join(
    scenario_pairs,
    by = c("run_id" = "primary_run_id"),
    relationship = "many-to-one"
  )
gap_effects_selected <- gap_effects |>
  dplyr::select(
    gap_run_id = run_id,
    term,
    gap_estimate_practical = estimate_practical,
    gap_conf_low_practical = conf_low_practical,
    gap_conf_high_practical = conf_high_practical,
    gap_term_p_raw = p_raw,
    gap_status = status
  )
gap_comparison <- primary_effects |>
  dplyr::select(
    primary_run_id = run_id,
    gap_run_id,
    placement,
    sample_scenario,
    term,
    primary_estimate_practical = estimate_practical,
    primary_conf_low_practical = conf_low_practical,
    primary_conf_high_practical = conf_high_practical,
    primary_term_p_raw = p_raw,
    primary_status = status
  ) |>
  dplyr::inner_join(
    gap_effects_selected,
    by = c("gap_run_id", "term"),
    relationship = "one-to-one"
  )
stopifnot(nrow(gap_comparison) == 8L)
write_review_csv(
  gap_comparison,
  "H01_METRIC-011_gap_timing_unaware_comparison.csv"
)

pilot_provenance <- read_csv_required(file.path(
  pilot_root,
  "diagnostics/H01_METRIC-011_bootstrap_pilot_provenance.csv"
))
pilot_audit <- read_csv_required(file.path(
  pilot_root,
  "diagnostics/H01_METRIC-011_bootstrap_pilot_audit.csv"
))
pilot_failures_path <- file.path(
  pilot_root,
  "diagnostics/H01_METRIC-011_bootstrap_pilot_failures.csv"
)
pilot_failure_bytes <- as.numeric(file.info(pilot_failures_path)$size)
stopifnot(
  nrow(pilot_provenance) == 1L,
  pilot_provenance$pilot_status ==
    "PASS_AWAITING_AUTHOR_PRODUCTION_APPROVAL",
  nrow(pilot_audit) == 4L,
  all(pilot_audit$status == "PASS"),
  all(pilot_audit$used_refits == 50L),
  all(pilot_audit$failed_refits == 0L),
  all(pilot_audit$warning_refits == 0L),
  pilot_failure_bytes == 0
)

protected_roots <- c(
  file.path(root, "artifacts/07_models/H01"),
  file.path(root, "artifacts/08_diagnostics/H01"),
  file.path(root, "artifacts/11_source_data/H01")
)
accepted_artifacts <- sort(unique(unlist(lapply(
  protected_roots,
  list.files,
  recursive = TRUE,
  full.names = TRUE
))))
accepted_artifacts <- accepted_artifacts[
  file.exists(accepted_artifacts) & !dir.exists(accepted_artifacts)
]
is_gap_l10 <- grepl(
  "/manuscript_prepared_data/.*l10_mean_medi",
  accepted_artifacts
)
is_non_l10 <- !grepl("l10_mean_medi", accepted_artifacts)
mder_paths <- sort(unique(c(
  list.files(
    file.path(root, "audit/hypotheses/H01/mder_METRIC-010"),
    recursive = TRUE,
    full.names = TRUE
  ),
  file.path(root, "scripts/hypotheses/H01/audit_h01_mder_METRIC010.R"),
  file.path(root, "tests/hypotheses/H01/test_h01_mder_METRIC010_gate.R")
)))
mder_paths <- mder_paths[file.exists(mder_paths) & !dir.exists(mder_paths)]
protected_paths <- sort(unique(c(
  accepted_artifacts[is_non_l10 | is_gap_l10],
  mder_paths
)))
protected_manifest <- dplyr::bind_rows(lapply(protected_paths, function(path) {
  tibble::tibble(
    path = substring(path, nchar(root) + 2L),
    sha256 = artifact_sha256(path),
    bytes = as.numeric(file.info(path)$size),
    protection_reason = dplyr::case_when(
      startsWith(
        path,
        file.path(root, "audit/hypotheses/H01/mder_METRIC-010")
      ) || basename(path) %in% c(
        "audit_h01_mder_METRIC010.R",
        "test_h01_mder_METRIC010_gate.R"
      ) ~ "METRIC-010_GATE_DO_NOT_DISTURB",
      grepl(
        "/manuscript_prepared_data/.*l10_mean_medi",
        path
      ) ~ "UNCHANGED_GAP_L10_ARTIFACT",
      TRUE ~ "NON_L10_ACCEPTED_ARTIFACT"
    )
  )
}))
write_review_csv(
  protected_manifest,
  "H01_METRIC-011_protected_artifact_baseline.csv"
)

point_primary <- point$term_effects |>
  dplyr::filter(.data$run_id == "main__glasses__all_available")
point_primary_tests <- complete_tests |>
  dplyr::filter(
    .data$run_id == "main__glasses__all_available",
    .data$metric_id == .env$metric_id
  )
gate_summary <- tibble::tibble(
  metric_id = metric_id,
  response_family = spec$response_family,
  response_transform = spec$response_transform,
  affected_point_runs = nrow(point$samples),
  unique_primary_cells_normalized = sum(
    frame_comparison$changed_value_rows[
      frame_comparison$data_scenario_id == "main" &
        frame_comparison$sample_scenario == "all_available"
    ]
  ),
  changed_fitted_rows_across_all_primary_runs = nrow(changed_rows),
  maximum_absolute_response_change = max(
    frame_comparison$max_absolute_response_change
  ),
  exact_sample_changes = sum(
    sample_comparison$participants_old != sample_comparison$participants_new |
      sample_comparison$participant_days_old !=
        sample_comparison$participant_days_new |
      sample_comparison$observations_old !=
        sample_comparison$observations_new |
      sample_comparison$sites_old != sample_comparison$sites_new
  ),
  major_diagnostic_failures = sum(
    point$diagnostics$diagnostic_status == "FAIL_MAJOR_GATE"
  ),
  maximum_absolute_raw_p_change = max(abs(
    test_impact$raw_p_delta[test_impact$metric_id == metric_id]
  )),
  maximum_absolute_adjusted_p_change = max(abs(
    test_impact$adjusted_p_delta
  ), na.rm = TRUE),
  l10_support_changes = sum(
    test_impact$support_changed & test_impact$metric_id == metric_id
  ),
  non_l10_BH_support_changes = sum(
    test_impact$support_changed & test_impact$metric_id != metric_id
  ),
  gap_l10_changed_rows = sum(
    frame_comparison$changed_value_rows[
      frame_comparison$data_scenario_id == "manuscript_prepared_data"
    ]
  ),
  primary_photoperiod_ratio = point_primary$estimate_practical[
    point_primary$term == "photoperiod_centered_hours"
  ],
  primary_photoperiod_ci_low = point_primary$conf_low_practical[
    point_primary$term == "photoperiod_centered_hours"
  ],
  primary_photoperiod_ci_high = point_primary$conf_high_practical[
    point_primary$term == "photoperiod_centered_hours"
  ],
  primary_latitude_ratio = point_primary$estimate_practical[
    point_primary$term == "absolute_latitude_10deg_centered"
  ],
  primary_latitude_ci_low = point_primary$conf_low_practical[
    point_primary$term == "absolute_latitude_10deg_centered"
  ],
  primary_latitude_ci_high = point_primary$conf_high_practical[
    point_primary$term == "absolute_latitude_10deg_centered"
  ],
  primary_site_q = point_primary_tests$p_adjusted[
    point_primary_tests$family_id == "H01-F1-site"
  ],
  primary_photoperiod_q = point_primary_tests$p_adjusted[
    point_primary_tests$family_id == "H01-F2-photoperiod"
  ],
  primary_latitude_q = point_primary_tests$p_adjusted[
    point_primary_tests$family_id == "H01-F3-latitude"
  ],
  primary_adequacy_q = point_primary_tests$p_adjusted[
    point_primary_tests$family_id == "H01-F4-site-latitude-adequacy"
  ],
  pilot_targets = nrow(pilot_audit),
  pilot_successful_refits_per_target = min(pilot_audit$used_refits),
  pilot_failed_refits = sum(pilot_audit$failed_refits),
  pilot_warning_refits = sum(pilot_audit$warning_refits),
  pilot_total_wall_seconds = pilot_provenance$total_wall_seconds,
  estimated_production_wall_hours =
    pilot_provenance$estimated_production_wall_hours,
  production_bootstrap_launched = FALSE,
  reader_report_merge_started = FALSE,
  gate_status = "STOP_AUTHOR_GATE_PRODUCTION_BOOTSTRAP_APPROVAL"
)
stopifnot(
  gate_summary$unique_primary_cells_normalized == 8L,
  gate_summary$exact_sample_changes == 0L,
  gate_summary$major_diagnostic_failures == 0L,
  gate_summary$l10_support_changes == 0L,
  gate_summary$non_l10_BH_support_changes == 0L,
  gate_summary$gap_l10_changed_rows == 0L,
  gate_summary$pilot_failed_refits == 0L,
  gate_summary$pilot_warning_refits == 0L,
  !gate_summary$production_bootstrap_launched,
  !gate_summary$reader_report_merge_started
)
write_review_csv(gate_summary, "H01_METRIC-011_gate_summary.csv")

review_files <- list.files(
  review_root,
  recursive = TRUE,
  full.names = TRUE
)
review_files <- review_files[
  file.exists(review_files) &
    !dir.exists(review_files) &
    basename(review_files) != "H01_METRIC-011_author_gate_manifest.csv"
]
provenance_files <- c(
  file.path(root, producer),
  file.path(root, "scripts/hypotheses/H01/run_h01_l10_METRIC011_point.R"),
  file.path(
    root,
    "scripts/hypotheses/H01/run_h01_l10_METRIC011_bootstrap_pilot.R"
  ),
  file.path(root, "scripts/hypotheses/H01/h01_contract.R"),
  file.path(root, "scripts/hypotheses/H01/h01_modeling.R"),
  file.path(root, "tests/hypotheses/H01/test_h01_l10_METRIC011_gate.R"),
  file.path(audit_root, "H01_METRIC-011_author_gate.md"),
  absolute_pin_paths,
  file.path(
    point_root,
    "artifacts/12_manifests/H01_model_results_artifacts.csv"
  ),
  file.path(
    pilot_root,
    "H01_METRIC-011_bootstrap_pilot_manifest.csv"
  )
)
manifest_files <- sort(unique(c(review_files, provenance_files)))
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
    r_version = as.character(getRversion())
  )
}))
write_review_csv(
  manifest,
  "H01_METRIC-011_author_gate_manifest.csv"
)

message("H01 METRIC-011 bounded author-gate audit completed")
