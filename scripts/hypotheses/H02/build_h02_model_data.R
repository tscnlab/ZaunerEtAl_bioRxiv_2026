#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(tibble)
  library(tidyr)
})

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
source(file.path(root, "scripts/pipeline/paths_io.R"))
source(file.path(root, "scripts/pipeline/assertions.R"))
source(file.path(root, "scripts/hypotheses/H02/h02_contract.R"))
source(file.path(root, "scripts/hypotheses/H02/h02_data.R"))

if (getRversion() != "4.6.1") {
  h02_abort("H02 requires R 4.6.1; running %s", getRversion())
}

paths <- pipeline_paths(root)
producer <- "scripts/hypotheses/H02/build_h02_model_data.R"
input_audit <- h02_validate_inputs(root)
links <- h02_temporal_links(root)
h02_assert_temporal_links(links)

input <- h02_input_contract(root)
input_path <- function(id) input$path[match(id, input$input_id)]

main_gr_grid <- h02_main_grid(
  input_path("main_glasses"),
  "main",
  links
)
main_ch_grid <- h02_main_grid(
  input_path("main_chest"),
  "main",
  links
)
mp_all <- h02_manuscript_grid(
  input_path("manuscript_prepared"),
  links
)
mp_gr_grid <- dplyr::filter(mp_all, .data$position == "glasses")
mp_ch_grid <- dplyr::filter(mp_all, .data$position == "chest")

frames <- list(
  main = list(
    glasses = h02_model_frame(main_gr_grid),
    chest = h02_model_frame(main_ch_grid)
  ),
  manuscript_prepared_data = list(
    glasses = h02_model_frame(mp_gr_grid),
    chest = h02_model_frame(mp_ch_grid)
  )
)
for (scenario in names(frames)) {
  paired <- h02_paired_frames(
    frames[[scenario]]$glasses,
    frames[[scenario]]$chest
  )
  frames[[scenario]]$paired_common_sample <- paired
}

registry <- h02_run_registry()
frame_for_run <- function(scenario, placement, sample) {
  if (sample == "all_available") {
    frames[[scenario]][[placement]]
  } else {
    frames[[scenario]]$paired_common_sample[[placement]]
  }
}

model_data_dir <- file.path(paths$model_data, "H02")
manifest_dir <- file.path(paths$manifests, "H02")
dir.create(model_data_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(manifest_dir, recursive = TRUE, showWarnings = FALSE)

artifact_metadata <- list()
for (i in seq_len(nrow(registry))) {
  run <- registry[i, ]
  frame <- frame_for_run(
    run$data_scenario_id,
    run$placement,
    run$sample_scenario
  )
  path <- file.path(model_data_dir, paste0(run$run_id, ".rds"))
  artifact_metadata[[run$run_id]] <- write_rds_artifact(
    frame,
    path,
    producer,
    metadata = list(
      run_id = run$run_id,
      scenario = run$data_scenario_id,
      placement = run$placement,
      sample_scenario = run$sample_scenario,
      participants = dplyr::n_distinct(frame$participant_key),
      participant_days = dplyr::n_distinct(frame$participant_day_key),
      observations = nrow(frame),
      sites = dplyr::n_distinct(frame$site)
    )
  )
}

sample_counts <- purrr::pmap_dfr(
  registry[c("data_scenario_id", "placement", "sample_scenario", "run_id")],
  function(data_scenario_id, placement, sample_scenario, run_id) {
    h02_sample_counts(
      frame_for_run(data_scenario_id, placement, sample_scenario),
      run_id
    )
  }
)
support_audit <- dplyr::bind_rows(
  h02_support_audit(main_gr_grid, "main", "glasses"),
  h02_support_audit(main_ch_grid, "main", "chest"),
  h02_support_audit(
    mp_gr_grid,
    "manuscript_prepared_data",
    "glasses"
  ),
  h02_support_audit(
    mp_ch_grid,
    "manuscript_prepared_data",
    "chest"
  )
)

comparison <- dplyr::full_join(
  frames$main$glasses |>
    dplyr::select(
      dplyr::all_of(h02_key),
      main_metric_value_lx = "metric_value_lx"
    ),
  frames$manuscript_prepared_data$glasses |>
    dplyr::select(
      dplyr::all_of(h02_key),
      manuscript_metric_value_lx = "metric_value_lx"
    ),
  by = h02_key,
  relationship = "one-to-one"
) |>
  dplyr::mutate(position = "glasses")
comparison_chest <- dplyr::full_join(
  frames$main$chest |>
    dplyr::select(
      dplyr::all_of(h02_key),
      main_metric_value_lx = "metric_value_lx"
    ),
  frames$manuscript_prepared_data$chest |>
    dplyr::select(
      dplyr::all_of(h02_key),
      manuscript_metric_value_lx = "metric_value_lx"
    ),
  by = h02_key,
  relationship = "one-to-one"
) |>
  dplyr::mutate(position = "chest")
scenario_input_comparison <- dplyr::bind_rows(comparison, comparison_chest) |>
  dplyr::group_by(.data$position) |>
  dplyr::summarise(
    main_finite = sum(is.finite(.data$main_metric_value_lx)),
    manuscript_finite = sum(is.finite(.data$manuscript_metric_value_lx)),
    common_finite = sum(
      is.finite(.data$main_metric_value_lx) &
        is.finite(.data$manuscript_metric_value_lx)
    ),
    exactly_equal_common = sum(
      is.finite(.data$main_metric_value_lx) &
        is.finite(.data$manuscript_metric_value_lx) &
        .data$main_metric_value_lx == .data$manuscript_metric_value_lx
    ),
    mean_main_minus_manuscript_lx = mean(
      .data$main_metric_value_lx - .data$manuscript_metric_value_lx,
      na.rm = TRUE
    ),
    max_absolute_difference_lx = max(
      abs(.data$main_metric_value_lx - .data$manuscript_metric_value_lx),
      na.rm = TRUE
    ),
    .groups = "drop"
  )

tables <- list(
  sample_counts = sample_counts,
  support_audit = support_audit,
  input_hashes = input_audit,
  scenario_input_comparison = scenario_input_comparison,
  temporal_model_specification = h02_specification_table()
)
table_metadata <- lapply(names(tables), function(name) {
  write_csv_artifact(
    tables[[name]],
    file.path(model_data_dir, paste0(name, ".csv")),
    producer
  )
})
names(table_metadata) <- names(tables)

manifest <- dplyr::bind_rows(c(
  lapply(artifact_metadata, manifest_row),
  lapply(table_metadata, manifest_row)
)) |>
  dplyr::mutate(
    path = sub(
      paste0("^", gsub("([][{}()+*^$|\\\\?.])", "\\\\\\1", root), "/"),
      "",
      .data$path
    )
  )
write_csv_artifact(
  manifest,
  file.path(manifest_dir, "H02_model_data_manifest.csv"),
  producer
)

message("Built ", nrow(registry), " H02 model frames")
