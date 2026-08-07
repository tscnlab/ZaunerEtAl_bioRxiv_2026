source("scripts/hypotheses/H07/h07_stage2_core.R")

overwrite <- identical(Sys.getenv("H07_STAGE2_OVERWRITE", unset = "0"), "1")
long_data <- h07_stage2_load_long()

placements <- c("near_eye", "chest")
registry <- tidyr::crossing(
  placement = placements,
  metric_id = h07_stage2_metric_ids
) |>
  mutate(
    main_run_id = paste("primary", .data$placement, sep = "__"),
    main_frame_path = file.path(
      h07_stage2_paths$models,
      "frames",
      .data$main_run_id,
      paste0(.data$metric_id, ".rds")
    )
  )
if (!all(file.exists(registry$main_frame_path))) {
  h07_stage2_abort("A primary H07 frame required for LOSO is missing")
}

loso_registry <- purrr::pmap_dfr(
  registry,
  function(placement, metric_id, main_run_id, main_frame_path) {
    frame <- readRDS(main_frame_path)
    tibble::tibble(
      placement = placement,
      metric_id = metric_id,
      omitted_site = levels(frame$site)
    )
  }
) |>
  mutate(
    omitted_site_slug = stringr::str_replace_all(
      stringr::str_to_lower(.data$omitted_site),
      "[^a-z0-9]+",
      "_"
    ),
    run_id = paste0(
      "loso__",
      .data$placement,
      "__omit_",
      .data$omitted_site_slug
    )
  )
if (anyDuplicated(loso_registry[c("placement", "metric_id", "omitted_site")])) {
  h07_stage2_abort("H07 LOSO placement/metric/site rows are not unique")
}
run_mapping <- loso_registry |>
  distinct(.data$placement, .data$omitted_site, .data$run_id)
if (anyDuplicated(run_mapping$run_id)) {
  h07_stage2_abort("H07 LOSO run identifiers collide across omitted sites")
}
readr::write_csv(
  loso_registry,
  file.path(h07_stage2_paths$tables, "H07_loso_run_registry.csv")
)

samples <- tibble::tibble()
diagnostics <- tibble::tibble()

for (row_index in seq_len(nrow(loso_registry))) {
  run <- loso_registry[row_index, , drop = FALSE]
  main_run_id <- paste("primary", run$placement[[1L]], sep = "__")
  main_frame <- readRDS(file.path(
    h07_stage2_paths$models,
    "frames",
    main_run_id,
    paste0(run$metric_id[[1L]], ".rds")
  ))
  keys <- main_frame |>
    filter(as.character(.data$site) != run$omitted_site[[1L]]) |>
    transmute(
      site = as.character(.data$site),
      Id = as.character(.data$Id),
      local_date = as.Date(.data$local_date)
    )
  message(sprintf(
    "H07 LOSO START %s / %s / omit %s at %s",
    run$placement,
    run$metric_id,
    run$omitted_site,
    format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  ))
  result <- h07_stage2_run_metric(
    long_data = long_data,
    run_id = run$run_id[[1L]],
    data_scenario = "primary",
    placement = run$placement[[1L]],
    metric_id = run$metric_id[[1L]],
    model_ids = "adapted_photoperiod_smooth",
    keys = keys,
    overwrite = overwrite
  )
  samples <- bind_rows(
    samples,
    result$sample |>
      mutate(
        placement = run$placement[[1L]],
        omitted_site = run$omitted_site[[1L]]
      )
  ) |>
    distinct(
      .data$run_id,
      .data$metric_id,
      .data$omitted_site,
      .keep_all = TRUE
    )
  diagnostics <- bind_rows(
    diagnostics,
    result$diagnostics |>
      mutate(
        placement = run$placement[[1L]],
        omitted_site = run$omitted_site[[1L]]
      )
  ) |>
    distinct(
      .data$run_id,
      .data$metric_id,
      .data$model_id,
      .data$omitted_site,
      .keep_all = TRUE
    )
  readr::write_csv(
    samples,
    file.path(h07_stage2_paths$tables, "H07_loso_samples.csv"),
    na = ""
  )
  readr::write_csv(
    diagnostics,
    file.path(h07_stage2_paths$tables, "H07_loso_diagnostics.csv"),
    na = ""
  )
  message(sprintf(
    "H07 LOSO DONE %s / %s / omit %s: %s",
    run$placement,
    run$metric_id,
    run$omitted_site,
    paste(unique(result$diagnostics$fit_status), collapse = ", ")
  ))
  rm(result, main_frame)
  invisible(gc())
}

expected <- loso_registry |>
  count(.data$placement, .data$metric_id, name = "expected_omissions")
observed <- diagnostics |>
  count(.data$placement, .data$metric_id, name = "observed_omissions")
completion <- expected |>
  left_join(observed, by = c("placement", "metric_id")) |>
  mutate(
    status = if_else(
      .data$expected_omissions == .data$observed_omissions,
      "PASS",
      "FAIL"
    )
  )
if (any(completion$status != "PASS")) {
  h07_stage2_abort("The H07 LOSO battery is incomplete")
}
readr::write_csv(
  completion,
  file.path(h07_stage2_paths$tables, "H07_loso_completion_audit.csv")
)

message("H07 Stage 2 leave-one-site-out checkpoint run complete")
