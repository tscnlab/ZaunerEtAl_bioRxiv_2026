source("scripts/hypotheses/H07/h07_stage2_core.R")

overwrite <- identical(Sys.getenv("H07_STAGE2_OVERWRITE", unset = "0"), "1")
long_data <- h07_stage2_load_long()

run_registry <- tibble::tribble(
  ~run_id, ~data_scenario, ~placement, ~analysis_role,
  "primary__near_eye", "primary", "near_eye", "primary",
  "primary__chest", "primary", "chest", "complementary"
)

readr::write_csv(
  h07_stage2_input_manifest,
  file.path(h07_stage2_paths$tables, "H07_input_manifest.csv")
)
readr::write_csv(
  h07_stage2_formula_registry,
  file.path(h07_stage2_paths$tables, "H07_formula_registry.csv")
)
readr::write_csv(
  h07_stage2_session,
  file.path(h07_stage2_paths$tables, "H07_session.csv")
)
readr::write_csv(
  run_registry,
  file.path(h07_stage2_paths$tables, "H07_main_run_registry.csv")
)

samples <- tibble::tibble()
diagnostics <- tibble::tibble()
tests <- tibble::tibble()

for (run_index in seq_len(nrow(run_registry))) {
  run <- run_registry[run_index, , drop = FALSE]
  for (metric_id in h07_stage2_metric_ids) {
    message(
      sprintf(
        "H07 MAIN START %s / %s at %s",
        run$run_id,
        metric_id,
        format(Sys.time(), "%Y-%m-%d %H:%M:%S")
      )
    )
    result <- h07_stage2_run_metric(
      long_data = long_data,
      run_id = run$run_id,
      data_scenario = run$data_scenario,
      placement = run$placement,
      metric_id = metric_id,
      model_ids = h07_stage2_main_model_ids,
      overwrite = overwrite
    )
    samples <- bind_rows(samples, result$sample) |>
      distinct(.data$run_id, .data$metric_id, .keep_all = TRUE)
    diagnostics <- bind_rows(diagnostics, result$diagnostics) |>
      distinct(.data$run_id, .data$metric_id, .data$model_id, .keep_all = TRUE)
    tests <- bind_rows(tests, result$tests) |>
      distinct(
        .data$run_id,
        .data$metric_id,
        .data$analysis_scope,
        .data$test_id,
        .keep_all = TRUE
      )
    readr::write_csv(
      samples,
      file.path(h07_stage2_paths$tables, "H07_main_samples.csv"),
      na = ""
    )
    readr::write_csv(
      diagnostics,
      file.path(h07_stage2_paths$tables, "H07_main_diagnostics.csv"),
      na = ""
    )
    readr::write_csv(
      tests,
      file.path(h07_stage2_paths$tables, "H07_main_tests_unadjusted.csv"),
      na = ""
    )
    message(
      sprintf(
        "H07 MAIN DONE %s / %s: %s",
        run$run_id,
        metric_id,
        paste(unique(result$diagnostics$fit_status), collapse = ", ")
      )
    )
    rm(result)
    invisible(gc())
  }
}

tests_adjusted <- tests |>
  left_join(
    h07_stage2_metric_contract |>
      select(
        "metric_id",
        "metric_order",
        "manuscript_name",
        "response_family",
        "response_transform",
        "effect_scale",
        "display_unit"
      ),
    by = "metric_id"
  ) |>
  group_by(.data$run_id, .data$analysis_scope, .data$test_id) |>
  arrange(.data$metric_order, .by_group = TRUE) |>
  mutate(
    planned_family_n = 9L,
    p_adjusted_BH_model = stats::p.adjust(
      .data$p_raw_model,
      method = "BH",
      n = 9L
    ),
    p_raw_release = if_else(
      .data$p_release_status == "RELEASE_CONDITIONAL_APPROXIMATE",
      .data$p_raw_model,
      NA_real_
    ),
    p_adjusted_BH_release = stats::p.adjust(
      .data$p_raw_release,
      method = "BH",
      n = 9L
    ),
    conditional_aic_support = case_when(
      is.na(.data$delta_aic_full_minus_reduced) ~ "UNAVAILABLE",
      .data$delta_aic_full_minus_reduced < -2 ~ "FULL_LOWER_BY_MORE_THAN_2",
      .data$delta_aic_full_minus_reduced <= 0 ~ "FULL_LOWER_BY_0_TO_2",
      TRUE ~ "REDUCED_LOWER"
    )
  ) |>
  ungroup() |>
  arrange(
    factor(.data$run_id, levels = run_registry$run_id),
    .data$analysis_scope,
    .data$test_id,
    .data$metric_order
  )

family_audit <- tests_adjusted |>
  count(
    .data$run_id,
    .data$analysis_scope,
    .data$test_id,
    name = "observed_family_n"
  ) |>
  mutate(
    planned_family_n = 9L,
    status = if_else(.data$observed_family_n == 9L, "PASS", "FAIL")
  )
if (any(family_audit$status != "PASS")) {
  h07_stage2_abort("A main H07 multiplicity family is incomplete")
}

readr::write_csv(
  tests_adjusted,
  file.path(h07_stage2_paths$tables, "H07_main_tests.csv"),
  na = ""
)
readr::write_csv(
  family_audit,
  file.path(h07_stage2_paths$tables, "H07_main_family_audit.csv"),
  na = ""
)

message("H07 main Stage 2 checkpoint run complete")
