# Run H04 Stage 2 mean models, sensitivities, heterogeneity, diagnostics, and V0 bridge.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
project_library <- file.path(
  root,
  "renv/library/macos/R-4.6/aarch64-apple-darwin23"
)
.libPaths(c(project_library, .libPaths()))

source(file.path(root, "scripts/pipeline/paths_io.R"))
source(file.path(root, "scripts/pipeline/p_value_display.R"))
source(file.path(root, "scripts/hypotheses/H04/h04_contract.R"))
source(file.path(root, "scripts/hypotheses/H04/h04_stage1_support.R"))
source(file.path(root, "scripts/hypotheses/H04/h04_data.R"))
source(file.path(root, "scripts/hypotheses/H04/h04_modeling.R"))
source(file.path(root, "scripts/hypotheses/H04/h04_reporting.R"))

options(lifecycle_verbosity = "quiet", warn = 1)
if (!identical(as.character(getRversion()), "4.6.1")) {
  h04_abort(
    "H04 Stage 2 requires R 4.6.1; found %s",
    as.character(getRversion())
  )
}
required_packages <- c(
  "dplyr",
  "tidyr",
  "purrr",
  "tibble",
  "readr",
  "digest",
  "openssl",
  "statmod",
  "sandwich",
  "glmmTMB",
  "emmeans",
  "ggplot2",
  "scales",
  "LightLogR",
  "patchwork",
  "gt"
)
missing_packages <- required_packages[
  !vapply(
    required_packages,
    requireNamespace,
    logical(1),
    quietly = TRUE
  )
]
if (length(missing_packages) > 0L) {
  h04_abort(
    "Missing synchronized project package(s): %s",
    paste(missing_packages, collapse = ", ")
  )
}

producer <- "scripts/hypotheses/H04/run_h04_stage2.R"
stage <- Sys.getenv("H04_STAGE", unset = "fit")
if (!stage %in% c("fit", "manifest")) {
  h04_abort("H04_STAGE must be `fit` or `manifest`")
}
roots <- list(
  model_data = file.path(root, "artifacts/06_model_data/H04"),
  models = file.path(root, "artifacts/07_models/H04"),
  diagnostics = file.path(root, "artifacts/08_diagnostics/H04"),
  tables = file.path(root, "artifacts/09_tables/H04"),
  figures = file.path(root, "artifacts/10_figures/H04"),
  source_data = file.path(root, "artifacts/11_source_data/H04"),
  manifests = file.path(root, "artifacts/12_manifests/H04")
)
invisible(vapply(
  roots,
  dir.create,
  logical(1),
  recursive = TRUE,
  showWarnings = FALSE
))

h04_relative_path <- function(path) {
  normalized <- normalizePath(path, winslash = "/", mustWork = TRUE)
  if (startsWith(normalized, paste0(root, "/"))) {
    substring(normalized, nchar(root) + 2L)
  } else {
    normalized
  }
}

h04_build_stage2_manifest <- function() {
  artifact_files <- sort(unique(unlist(lapply(
    roots,
    list.files,
    recursive = TRUE,
    full.names = TRUE
  ))))
  manifest_path <- file.path(roots$manifests, "H04_stage2_artifacts.csv")
  artifact_files <- artifact_files[
    file.exists(artifact_files) &
      !dir.exists(artifact_files) &
      normalizePath(artifact_files, winslash = "/", mustWork = TRUE) !=
        normalizePath(manifest_path, winslash = "/", mustWork = FALSE)
  ]
  code_and_reports <- c(
    file.path(root, "scripts/hypotheses/H04/h04_stage1_support.R"),
    file.path(root, "scripts/hypotheses/H04/h04_contract.R"),
    file.path(root, "scripts/hypotheses/H04/h04_data.R"),
    file.path(root, "scripts/hypotheses/H04/h04_modeling.R"),
    file.path(root, "scripts/hypotheses/H04/h04_reporting.R"),
    file.path(root, "scripts/hypotheses/H04/h04_temporal.R"),
    file.path(root, "scripts/hypotheses/H04/h04_temporal_bootstrap.R"),
    file.path(root, "scripts/hypotheses/H04/run_h04_stage2.R"),
    file.path(
      root,
      "scripts/hypotheses/H04/run_h04_mundlak_sensitivity.R"
    ),
    file.path(root, "scripts/hypotheses/H04/build_h04_stage2_figures.R"),
    file.path(root, "scripts/hypotheses/H04/build_h04_stage2_support.R"),
    file.path(root, "scripts/hypotheses/H04/build_h04_temporal_figures.R"),
    file.path(root, "scripts/hypotheses/H04/run_h04_temporal.R"),
    file.path(
      root,
      "scripts/hypotheses/H04/refresh_h04_temporal_uncertainty.R"
    ),
    file.path(root, "scripts/hypotheses/H04/run_h04_temporal_bootstrap.R"),
    file.path(root, "tests/hypotheses/H04/test_h04_stage2.R"),
    file.path(root, "audit/hypotheses/H04/01_audit_and_plan.qmd"),
    file.path(
      root,
      "audit/hypotheses/H04/02_implementation_and_v0_comparison.qmd"
    ),
    file.path(
      root,
      "audit/hypotheses/H04/02_implementation_and_v0_comparison.html"
    ),
    file.path(root, "audit/handoffs/H04_worker_handoff.md")
  )
  files <- sort(unique(c(
    artifact_files,
    code_and_reports[file.exists(code_and_reports)]
  )))
  manifest <- dplyr::bind_rows(lapply(files, function(path) {
    info <- file.info(path)
    relative_path <- h04_relative_path(path)
    artifact_status <- if (grepl(
      "H04_temporal_bootstrap_(gate|supersession)[.]csv$",
      relative_path
    )) {
      "current supersession record"
    } else if (grepl("temporal_bootstrap", relative_path, fixed = TRUE)) {
      "superseded pilot evidence; not used for H04 inference or reporting"
    } else {
      "current"
    }
    tibble::tibble(
      path = relative_path,
      artifact_type = tools::file_ext(path),
      artifact_status = artifact_status,
      sha256 = artifact_sha256(path),
      bytes = as.numeric(info$size),
      producer = producer,
      r_version = as.character(getRversion()),
      written_utc = format(info$mtime, tz = "UTC", usetz = TRUE)
    )
  }))
  write_csv_artifact(manifest, manifest_path, producer)
  invisible(manifest_path)
}

if (identical(stage, "manifest")) {
  h04_build_stage2_manifest()
  message("H04 Stage 2 manifest refreshed")
  quit(save = "no", status = 0L)
}

metadata <- list()
h04_write_csv <- function(data, path, id) {
  metadata[[id]] <<- write_csv_artifact(data, path, producer)
  invisible(path)
}
h04_write_rds <- function(object, path, id) {
  metadata[[id]] <<- write_rds_artifact(object, path, producer)
  invisible(path)
}

message("Validating frozen H04 inputs and assembling exact scenario frames")
input_audit <- h04_validate_inputs(root)
inputs <- h04_load_inputs(root)
frames <- h04_prepare_scenario_frames(inputs, root)
spec <- h04_specification()
formulas <- h04_formula_set()

expected_main <- tibble::tribble(
  ~placement,
  ~participants,
  ~participant_days,
  ~hours,
  ~long_rows,
  ~weighted,
  "Near-eye",
  126L,
  724L,
  16526L,
  17266L,
  16526,
  "Chest",
  150L,
  875L,
  20128L,
  21071L,
  20128
)
observed_main <- dplyr::bind_rows(
  h04_sample_summary(
    frames$main$near_eye,
    "main__near_eye",
    "primary_dataset",
    "Near-eye"
  ),
  h04_sample_summary(
    frames$main$chest,
    "main__chest",
    "primary_dataset",
    "Chest"
  )
)
stopifnot(
  identical(observed_main$participants, expected_main$participants),
  identical(observed_main$participant_days, expected_main$participant_days),
  identical(observed_main$unique_participant_hours, expected_main$hours),
  identical(observed_main$long_rows, expected_main$long_rows),
  all(
    abs(observed_main$effective_weighted_hours - expected_main$weighted) < 1e-10
  )
)

message("Fitting primary near-eye and complementary chest mean models")
main_results <- list(
  near_eye = h04_fit_additive_run(
    frames$main$near_eye,
    "main__near_eye",
    "primary_dataset",
    "Near-eye"
  ),
  chest = h04_fit_additive_run(
    frames$main$chest,
    "main__chest",
    "primary_dataset",
    "Chest"
  )
)
main_estimands <- dplyr::bind_rows(lapply(main_results, `[[`, "estimands"))
main_tests <- dplyr::bind_rows(lapply(main_results, `[[`, "tests"))
main_diagnostics <- dplyr::bind_rows(lapply(
  main_results,
  `[[`,
  "diagnostics"
))
main_samples <- dplyr::bind_rows(lapply(main_results, `[[`, "sample"))

message("Applying the results-blind named-category heterogeneity gate")
heterogeneity <- list(
  near_eye = h04_run_heterogeneity_gate(
    frames$main$near_eye,
    "Near-eye",
    root
  ),
  chest = h04_run_heterogeneity_gate(
    frames$main$chest,
    "Chest",
    root
  )
)
heterogeneity_gate <- dplyr::bind_rows(lapply(
  heterogeneity,
  `[[`,
  "gate"
))
heterogeneity_tests <- dplyr::bind_rows(lapply(
  heterogeneity,
  `[[`,
  "test"
))
heterogeneity_estimands <- dplyr::bind_rows(
  heterogeneity$near_eye$selected$estimands |>
    dplyr::mutate(placement = "Near-eye", .before = 1),
  heterogeneity$chest$selected$estimands |>
    dplyr::mutate(placement = "Chest", .before = 1)
)

message("Running the prespecified H04 sensitivity battery")
scenario_frames <- list(
  exactly_one_near = frames$exactly_one$near_eye,
  exactly_one_chest = frames$exactly_one$chest,
  other_retained_near = frames$retain_coselected_other$near_eye,
  other_retained_chest = frames$retain_coselected_other$chest,
  other_excluded_near = frames$exclude_other_only$near_eye,
  other_excluded_chest = frames$exclude_other_only$chest,
  unweighted_near = frames$unweighted_long$near_eye,
  unweighted_chest = frames$unweighted_long$chest,
  gap_near = frames$gap$near_eye,
  gap_chest = frames$gap$chest,
  paired_near = frames$paired$near_eye,
  paired_chest = frames$paired$chest,
  main_near = frames$main$near_eye,
  main_chest = frames$main$chest,
  mundlak_near = h04_add_mundlak_proportions(frames$main$near_eye),
  mundlak_chest = h04_add_mundlak_proportions(frames$main$chest)
)
run_registry <- tibble::tribble(
  ~run_id,
  ~scenario_id,
  ~placement,
  ~frame_id,
  ~working_power,
  "exactly_one__near_eye",
  "exactly_one_category",
  "Near-eye",
  "exactly_one_near",
  1.539919,
  "exactly_one__chest",
  "exactly_one_category",
  "Chest",
  "exactly_one_chest",
  1.539919,
  "retain_coselected_other__near_eye",
  "retain_coselected_other",
  "Near-eye",
  "other_retained_near",
  1.539919,
  "retain_coselected_other__chest",
  "retain_coselected_other",
  "Chest",
  "other_retained_chest",
  1.539919,
  "exclude_other_only__near_eye",
  "exclude_other_only",
  "Near-eye",
  "other_excluded_near",
  1.539919,
  "exclude_other_only__chest",
  "exclude_other_only",
  "Chest",
  "other_excluded_chest",
  1.539919,
  "unweighted_long__near_eye",
  "unweighted_long_rows",
  "Near-eye",
  "unweighted_near",
  1.539919,
  "unweighted_long__chest",
  "unweighted_long_rows",
  "Chest",
  "unweighted_chest",
  1.539919,
  "gap_timing_unaware__near_eye",
  "gap_timing_unaware",
  "Near-eye",
  "gap_near",
  1.539919,
  "gap_timing_unaware__chest",
  "gap_timing_unaware",
  "Chest",
  "gap_chest",
  1.539919,
  "paired_common__near_eye",
  "paired_common_sample",
  "Near-eye",
  "paired_near",
  1.539919,
  "paired_common__chest",
  "paired_common_sample",
  "Chest",
  "paired_chest",
  1.539919,
  "working_power_1_30__near_eye",
  "working_power_1_30",
  "Near-eye",
  "main_near",
  1.30,
  "working_power_1_30__chest",
  "working_power_1_30",
  "Chest",
  "main_chest",
  1.30,
  "working_power_1_80__near_eye",
  "working_power_1_80",
  "Near-eye",
  "main_near",
  1.80,
  "working_power_1_80__chest",
  "working_power_1_80",
  "Chest",
  "main_chest",
  1.80
)
run_registry <- dplyr::bind_rows(
  run_registry |>
    dplyr::mutate(formula_id = "primary_full"),
  tibble::tribble(
    ~run_id,
    ~scenario_id,
    ~placement,
    ~frame_id,
    ~working_power,
    ~formula_id,
    "mundlak__near_eye",
    "mundlak_within_between",
    "Near-eye",
    "mundlak_near",
    spec$working_tweedie_power,
    "secondary_mundlak_audit",
    "mundlak__chest",
    "mundlak_within_between",
    "Chest",
    "mundlak_chest",
    spec$working_tweedie_power,
    "secondary_mundlak_audit"
  )
)
sensitivity_results <- vector("list", nrow(run_registry))
for (index in seq_len(nrow(run_registry))) {
  run <- run_registry[index, , drop = FALSE]
  message("  ", run$run_id)
  sensitivity_results[[index]] <- h04_fit_additive_run(
    scenario_frames[[run$frame_id]],
    run$run_id,
    run$scenario_id,
    run$placement,
    working_power = run$working_power,
    formula = formulas[[run$formula_id]]
  )
}
names(sensitivity_results) <- run_registry$run_id
sensitivity_estimands <- dplyr::bind_rows(lapply(
  sensitivity_results,
  `[[`,
  "estimands"
))
sensitivity_tests <- dplyr::bind_rows(lapply(
  sensitivity_results,
  `[[`,
  "tests"
))
sensitivity_diagnostics <- dplyr::bind_rows(lapply(
  sensitivity_results,
  `[[`,
  "diagnostics"
))
sensitivity_samples <- dplyr::bind_rows(lapply(
  sensitivity_results,
  `[[`,
  "sample"
))

reference_estimands <- main_estimands |>
  dplyr::select(
    .data$placement,
    .data$activity_code,
    primary_ratio = .data$ratio_to_home,
    primary_conf_low = .data$ratio_conf_low,
    primary_conf_high = .data$ratio_conf_high,
    primary_p_adjusted = .data$p_adjusted
  )
sensitivity_comparison <- sensitivity_estimands |>
  dplyr::left_join(
    reference_estimands,
    by = c("placement", "activity_code"),
    relationship = "many-to-one"
  ) |>
  dplyr::mutate(
    ratio_relative_change_percent = 100 *
      (.data$ratio_to_home / .data$primary_ratio - 1),
    direction_concordant = dplyr::if_else(
      .data$inferential_role == "NAMED_VERSUS_HOME",
      sign(log(.data$ratio_to_home)) == sign(log(.data$primary_ratio)),
      NA
    ),
    primary_ratio_inside_sensitivity_interval = .data$primary_ratio >=
      .data$ratio_conf_low &
      .data$primary_ratio <= .data$ratio_conf_high,
    stability = dplyr::case_when(
      .data$inferential_role != "NAMED_VERSUS_HOME" ~ "not_in_claim_family",
      !is.finite(.data$ratio_to_home) ~ "non_estimable",
      .data$direction_concordant &
        abs(.data$ratio_relative_change_percent) <= 25 ~
        "stable",
      .data$direction_concordant ~ "magnitude_shift",
      TRUE ~ "direction_shift"
    )
  )

paired_estimands <- sensitivity_estimands |>
  dplyr::filter(.data$scenario_id == "paired_common_sample")
mundlak_between_estimands <- dplyr::bind_rows(
  h04_mundlak_between_estimands(
    sensitivity_results[["mundlak__near_eye"]]$bundle
  ) |>
    dplyr::mutate(
      placement = "Near-eye",
      scenario_id = "mundlak_within_between",
      .before = 1
    ),
  h04_mundlak_between_estimands(
    sensitivity_results[["mundlak__chest"]]$bundle
  ) |>
    dplyr::mutate(
      placement = "Chest",
      scenario_id = "mundlak_within_between",
      .before = 1
    )
)
mundlak_between_omnibus <- dplyr::bind_rows(
  h04_mundlak_between_omnibus(
    sensitivity_results[["mundlak__near_eye"]]$bundle
  ) |>
    dplyr::mutate(
      placement = "Near-eye",
      scenario_id = "mundlak_within_between",
      .before = 1
    ),
  h04_mundlak_between_omnibus(
    sensitivity_results[["mundlak__chest"]]$bundle
  ) |>
    dplyr::mutate(
      placement = "Chest",
      scenario_id = "mundlak_within_between",
      .before = 1
    )
)
mundlak_support <- dplyr::bind_rows(
  h04_mundlak_support(scenario_frames$mundlak_near, "Near-eye"),
  h04_mundlak_support(scenario_frames$mundlak_chest, "Chest")
)

message("Calculating weighted diagnostics on one row per participant-hour")
cluster_diagnostics <- dplyr::bind_rows(
  h04_cluster_diagnostics(main_results$near_eye$bundle) |>
    dplyr::mutate(
      run_id = "main__near_eye",
      placement = "Near-eye",
      .before = 1
    ),
  h04_cluster_diagnostics(main_results$chest$bundle) |>
    dplyr::mutate(
      run_id = "main__chest",
      placement = "Chest",
      .before = 1
    )
)
residual_acf <- dplyr::bind_rows(
  h04_residual_acf(main_results$near_eye$bundle) |>
    dplyr::mutate(
      run_id = "main__near_eye",
      placement = "Near-eye",
      .before = 1
    ),
  h04_residual_acf(main_results$chest$bundle) |>
    dplyr::mutate(
      run_id = "main__chest",
      placement = "Chest",
      .before = 1
    )
)
residual_calibration <- dplyr::bind_rows(
  h04_residual_calibration(main_results$near_eye$bundle, "main__near_eye") |>
    dplyr::mutate(placement = "Near-eye", .after = "run_id"),
  h04_residual_calibration(main_results$chest$bundle, "main__chest") |>
    dplyr::mutate(placement = "Chest", .after = "run_id")
)
group_calibration <- dplyr::bind_rows(
  h04_group_calibration(main_results$near_eye$bundle, "main__near_eye") |>
    dplyr::mutate(placement = "Near-eye", .after = "run_id"),
  h04_group_calibration(main_results$chest$bundle, "main__chest") |>
    dplyr::mutate(placement = "Chest", .after = "run_id")
)

message("Running bounded leave-one-site and top-five participant refits")
influence_jobs <- dplyr::bind_rows(
  tidyr::crossing(
    placement = "Near-eye",
    deletion_type = "site",
    deletion_id = levels(main_results$near_eye$bundle$data$site)
  ),
  tidyr::crossing(
    placement = "Chest",
    deletion_type = "site",
    deletion_id = levels(main_results$chest$bundle$data$site)
  ),
  tibble::tibble(
    placement = "Near-eye",
    deletion_type = "participant",
    deletion_id = cluster_diagnostics |>
      dplyr::filter(.data$placement == "Near-eye") |>
      dplyr::slice_min(.data$score_rank, n = 5L) |>
      dplyr::pull(.data$participant)
  ),
  tibble::tibble(
    placement = "Chest",
    deletion_type = "participant",
    deletion_id = cluster_diagnostics |>
      dplyr::filter(.data$placement == "Chest") |>
      dplyr::slice_min(.data$score_rank, n = 5L) |>
      dplyr::pull(.data$participant)
  )
)
influence_results <- vector("list", nrow(influence_jobs))
for (index in seq_len(nrow(influence_jobs))) {
  job <- influence_jobs[index, , drop = FALSE]
  is_near <- job$placement == "Near-eye"
  frame <- if (is_near) frames$main$near_eye else frames$main$chest
  reduced <- if (job$deletion_type == "site") {
    dplyr::filter(frame, as.character(.data$site) != job$deletion_id)
  } else {
    dplyr::filter(
      frame,
      as.character(.data$participant) != job$deletion_id
    )
  }
  reduced <- h04_set_analysis_frame(reduced)
  run_id <- paste(
    "influence",
    if (is_near) "near_eye" else "chest",
    job$deletion_type,
    job$deletion_id,
    sep = "__"
  )
  result <- h04_fit_additive_run(
    reduced,
    run_id,
    paste0("delete_", job$deletion_type),
    job$placement
  )
  reference <- if (is_near) {
    main_results$near_eye
  } else {
    main_results$chest
  }
  primary_p <- reference$tests |>
    dplyr::filter(.data$test_id == "H04-F1") |>
    dplyr::pull(.data$p_raw)
  deletion_p <- result$tests |>
    dplyr::filter(.data$test_id == "H04-F1") |>
    dplyr::pull(.data$p_raw)
  influence_results[[index]] <- result$estimands |>
    dplyr::left_join(
      reference$estimands |>
        dplyr::select(
          .data$activity_code,
          full_ratio = .data$ratio_to_home,
          full_conf_low = .data$ratio_conf_low,
          full_conf_high = .data$ratio_conf_high,
          full_p_adjusted = .data$p_adjusted
        ),
      by = "activity_code",
      relationship = "one-to-one"
    ) |>
    dplyr::mutate(
      deletion_type = job$deletion_type,
      deletion_id = job$deletion_id,
      full_primary_p = primary_p,
      deletion_primary_p = deletion_p,
      primary_decision_changed = (primary_p < 0.05) != (deletion_p < 0.05),
      ratio_relative_change_percent = 100 *
        (.data$ratio_to_home / .data$full_ratio - 1),
      .before = 1
    )
}
influence_refits <- dplyr::bind_rows(influence_results)

message("Fitting explicit V0 mixed-model bridges on current normalized inputs")
v0_data <- list(
  near_eye = h04_prepare_v0_data(
    inputs$near_eye,
    frames$diary_primary,
    "Near-eye",
    root
  ),
  chest = h04_prepare_v0_data(
    inputs$chest,
    frames$diary_primary,
    "Chest",
    root
  )
)
v0 <- list(
  near_eye = h04_fit_v0_bridge(v0_data$near_eye, "Near-eye"),
  chest = h04_fit_v0_bridge(v0_data$chest, "Chest")
)
v0_models <- dplyr::bind_rows(lapply(v0, `[[`, "model_table"))
v0_tests <- dplyr::bind_rows(lapply(v0, `[[`, "test"))
v0_means <- dplyr::bind_rows(lapply(v0, `[[`, "means"))
v0_ratios <- dplyr::bind_rows(lapply(v0, `[[`, "ratios"))
v0_comparison <- dplyr::bind_rows(
  tibble::tribble(
    ~placement,
    ~implementation,
    ~long_rows,
    ~unique_participant_hours,
    ~effective_weighted_hours,
    ~categories,
    ~test_definition,
    "Near-eye",
    "Frozen V0 model",
    16801L,
    NA_integer_,
    16801,
    5L,
    "site-only versus category-plus-site-interaction likelihood-ratio test",
    "Chest",
    "Frozen V0 model",
    20327L,
    NA_integer_,
    20327,
    5L,
    "site-only versus category-plus-site-interaction likelihood-ratio test"
  ),
  v0_models |>
    dplyr::filter(.data$model_id == "v0_full_joint") |>
    dplyr::transmute(
      .data$placement,
      implementation = "V0 bridge on current normalized inputs",
      .data$long_rows,
      .data$unique_participant_hours,
      effective_weighted_hours = as.numeric(.data$long_rows),
      .data$categories,
      test_definition = paste(
        "site-only versus category-plus-site-interaction",
        "likelihood-ratio test"
      )
    ),
  main_samples |>
    dplyr::transmute(
      .data$placement,
      implementation = "Approved repaired H04",
      .data$long_rows,
      .data$unique_participant_hours,
      .data$effective_weighted_hours,
      .data$categories,
      test_definition = paste(
        "four-restriction participant-cluster robust F test for",
        "equality of five named categories; Other unrestricted"
      )
    )
)

message("Classifying prespecified diagnostic acceptability")
diagnostic_assessments <- dplyr::bind_rows(lapply(
  c("Near-eye", "Chest"),
  function(placement) {
    diagnostic <- dplyr::filter(
      main_diagnostics,
      .data$placement == .env$placement
    )
    test <- main_tests |>
      dplyr::filter(
        .data$placement == .env$placement,
        .data$test_id == "H04-F1"
      )
    frame <- if (placement == "Near-eye") {
      frames$main$near_eye
    } else {
      frames$main$chest
    }
    weight_check <- frame |>
      dplyr::group_by(.data$analysis_hour_id) |>
      dplyr::summarise(
        weight_sum = sum(.data$analysis_weight),
        rows = dplyr::n(),
        k = dplyr::first(.data$k),
        .groups = "drop"
      )
    power <- sensitivity_comparison |>
      dplyr::filter(
        .data$placement == .env$placement,
        .data$scenario_id %in% c("working_power_1_30", "working_power_1_80"),
        .data$inferential_role == "NAMED_VERSUS_HOME"
      )
    structural_pass <- diagnostic$converged &&
      diagnostic$full_rank &&
      diagnostic$finite_coefficients &&
      diagnostic$covariance_finite &&
      test$status == "ESTIMABLE"
    power_stable <- all(power$direction_concordant %in% TRUE) &&
      max(abs(power$ratio_relative_change_percent), na.rm = TRUE) <= 25
    tibble::tribble(
      ~placement,
      ~diagnostic,
      ~evidence,
      ~assessment,
      ~interpretation,
      placement,
      "Fractional-weight integrity",
      sprintf(
        "%s hours checked; maximum |sum(weight)-1| = %.3g; rows equal k: %s",
        nrow(weight_check),
        max(abs(weight_check$weight_sum - 1)),
        all(weight_check$rows == weight_check$k)
      ),
      if (
        all(abs(weight_check$weight_sum - 1) < 1e-10) &&
          all(weight_check$rows == weight_check$k)
      )
        "ACCEPTABLE" else "NOT ACCEPTABLE",
      "Each participant-hour contributes one total unit across retained categories.",
      placement,
      "IRLS, design, and robust covariance",
      sprintf(
        "converged=%s; rank=%s/%s; covariance finite=%s; H04-F1 status=%s",
        diagnostic$converged,
        diagnostic$design_rank,
        diagnostic$design_columns,
        diagnostic$covariance_finite,
        test$status
      ),
      if (structural_pass) "ACCEPTABLE" else "NOT ACCEPTABLE",
      "The fitted mean and registered robust restriction are numerically estimable.",
      placement,
      "Participant-cluster influence",
      sprintf(
        "maximum score share=%.3f; maximum leverage share=%.3f",
        diagnostic$maximum_cluster_score_share,
        diagnostic$maximum_cluster_leverage_share
      ),
      if (
        diagnostic$maximum_cluster_score_share <= 0.50 &&
          diagnostic$maximum_cluster_leverage_share <= 0.20
      )
        "ACCEPTABLE" else "NOT ACCEPTABLE",
      "No participant exceeds the predeclared architecture-gate influence limits.",
      placement,
      "Mean-variance and calibration",
      sprintf(
        "hour residual-fitted Spearman=%.3f; absolute-residual Spearman=%.3f",
        diagnostic$hour_residual_fitted_spearman,
        diagnostic$hour_absolute_residual_fitted_spearman
      ),
      "ACCEPTABLE WITH LIMITATION",
      paste(
        "The quasi mean model is used for robust population-average inference;",
        "remaining variance-pattern structure is visible in calibration diagnostics."
      ),
      placement,
      "Exact zeros and positive tail",
      sprintf(
        "%s/%s unique hours are exactly zero (%.1f%%)",
        diagnostic$exact_zero_unique_hours,
        diagnostic$unique_participant_hours,
        100 * diagnostic$exact_zero_fraction
      ),
      "ACCEPTABLE WITH LIMITATION",
      paste(
        "The zero-aware geometric mean remains in the fit, but the quasi model",
        "does not separately model the probability of zero."
      ),
      placement,
      "Within-run serial dependence",
      sprintf(
        "unique-hour Pearson residual lag-1 correlation=%.3f",
        diagnostic$hour_residual_lag1_correlation
      ),
      "ACCEPTABLE WITH LIMITATION",
      paste(
        "Serial correlation remains visible; participant clustering encompasses",
        "the complete longitudinal record and is the inferential basis."
      ),
      placement,
      "Working variance power",
      sprintf(
        "p=1.30/1.80: named-contrast directions stable=%s; maximum ratio change=%.1f%%",
        all(power$direction_concordant %in% TRUE),
        max(abs(power$ratio_relative_change_percent), na.rm = TRUE)
      ),
      if (power_stable) "ACCEPTABLE" else "ACCEPTABLE WITH LIMITATION",
      "Fixed power checks do not select the model by H04 significance.",
      placement,
      "Overall primary mean-model assessment",
      sprintf(
        "structural checks pass=%s; inference uses %s participant clusters",
        structural_pass,
        diagnostic$participants
      ),
      if (structural_pass) {
        "ACCEPTABLE WITH LIMITATION"
      } else {
        "NOT ACCEPTABLE"
      },
      paste(
        "The registered mean model is usable for Stage 2 inference, with explicit",
        "limitations for zero structure, residual variance, and serial dependence."
      )
    )
  }
))

formula_registry <- tibble::tibble(
  formula_id = names(formulas),
  formula = vapply(formulas, h04_formula_text, character(1))
)
software_environment <- tibble::tibble(
  component = c("R", paste0("R package: ", required_packages)),
  version = c(
    as.character(getRversion()),
    vapply(
      required_packages,
      function(package) as.character(utils::packageVersion(package)),
      character(1)
    )
  )
)
deferred_computation <- tibble::tribble(
  ~component,
  ~status,
  ~reason,
  ~pilot_or_production,
  "model-based pointwise temporal intervals",
  "COMPLETED IN TEMPORAL DRIVER",
  paste(
    "H03-aligned fitted-coefficient covariance; no simultaneous band or",
    "curve-wide inference"
  ),
  "zero resampling replicates",
  "site-stratified participant bootstrap for temporal curves",
  "SUPERSEDED",
  paste(
    "the owner selected the H03 uncertainty implementation on 2026-08-11;",
    "incomplete pilot checkpoints are provenance only"
  ),
  "no production run required or authorized"
)

sample_flow <- dplyr::bind_rows(
  h04_sample_flow(frames$preparation_bundles$main_near_eye),
  h04_sample_flow(frames$preparation_bundles$main_chest),
  h04_gap_sample_flow(frames$preparation_bundles$gap_near_eye),
  h04_gap_sample_flow(frames$preparation_bundles$gap_chest)
)
category_support <- dplyr::bind_rows(
  h04_category_support_stage2(frames$main$near_eye) |>
    dplyr::mutate(placement = "Near-eye", .before = 1),
  h04_category_support_stage2(frames$main$chest) |>
    dplyr::mutate(placement = "Chest", .before = 1)
)
cell_support <- dplyr::bind_rows(
  h04_site_category_support_stage2(frames$main$near_eye, root) |>
    dplyr::mutate(placement = "Near-eye", .before = 1),
  h04_site_category_support_stage2(frames$main$chest, root) |>
    dplyr::mutate(placement = "Chest", .before = 1)
)

message("Writing H04 Stage 2 analytical artifacts")
h04_write_csv(
  input_audit,
  file.path(roots$model_data, "H04_input_audit.csv"),
  "input_audit"
)
h04_write_csv(
  h04_approval_registry(),
  file.path(roots$model_data, "H04_author_approvals.csv"),
  "approvals"
)
h04_write_csv(
  h04_multiplicity_registry(),
  file.path(roots$model_data, "H04_multiplicity_registry.csv"),
  "multiplicity"
)
h04_write_csv(
  formula_registry,
  file.path(roots$model_data, "H04_formula_registry.csv"),
  "formulas"
)
h04_write_csv(
  run_registry,
  file.path(roots$model_data, "H04_sensitivity_run_registry.csv"),
  "run_registry"
)
h04_write_csv(
  dplyr::bind_rows(main_samples, sensitivity_samples),
  file.path(roots$model_data, "H04_model_frame_index.csv"),
  "model_frames_index"
)
h04_write_csv(
  sample_flow,
  file.path(roots$model_data, "H04_sample_flow.csv"),
  "sample_flow"
)
h04_write_csv(
  category_support,
  file.path(roots$model_data, "H04_category_support.csv"),
  "category_support"
)
h04_write_csv(
  cell_support,
  file.path(roots$model_data, "H04_site_category_support.csv"),
  "cell_support"
)
h04_write_rds(
  list(
    main = frames$main,
    paired = frames$paired[c("near_eye", "chest")],
    exactly_one = frames$exactly_one,
    retain_coselected_other = frames$retain_coselected_other,
    exclude_other_only = frames$exclude_other_only,
    unweighted_long = frames$unweighted_long,
    gap_timing_unaware = frames$gap,
    mundlak = list(
      near_eye = scenario_frames$mundlak_near,
      chest = scenario_frames$mundlak_chest
    )
  ),
  file.path(roots$model_data, "H04_model_frames.rds"),
  "model_frames"
)
h04_write_rds(
  list(
    main = lapply(main_results, `[[`, "bundle"),
    sensitivities = lapply(sensitivity_results, `[[`, "bundle")
  ),
  file.path(roots$models, "H04_additive_model_objects.rds"),
  "additive_models"
)
h04_write_rds(
  heterogeneity,
  file.path(roots$models, "H04_heterogeneity_model_objects.rds"),
  "heterogeneity_models"
)
h04_write_rds(
  list(
    near_eye = list(full = v0$near_eye$full, null = v0$near_eye$null),
    chest = list(full = v0$chest$full, null = v0$chest$null)
  ),
  file.path(roots$models, "H04_v0_bridge_model_objects.rds"),
  "v0_models"
)

h04_write_csv(
  dplyr::bind_rows(main_diagnostics, sensitivity_diagnostics),
  file.path(roots$diagnostics, "H04_model_diagnostics.csv"),
  "model_diagnostics"
)
h04_write_csv(
  diagnostic_assessments,
  file.path(roots$diagnostics, "H04_diagnostic_assessments.csv"),
  "diagnostic_assessments"
)
h04_write_csv(
  mundlak_support,
  file.path(roots$diagnostics, "H04_mundlak_activity_support.csv"),
  "mundlak_support"
)
h04_write_csv(
  cluster_diagnostics,
  file.path(roots$diagnostics, "H04_cluster_influence_scores.csv"),
  "cluster_diagnostics"
)
h04_write_csv(
  residual_acf,
  file.path(roots$diagnostics, "H04_primary_residual_acf.csv"),
  "residual_acf"
)
h04_write_csv(
  residual_calibration,
  file.path(roots$diagnostics, "H04_residual_calibration_bins.csv"),
  "residual_calibration"
)
h04_write_csv(
  group_calibration,
  file.path(roots$diagnostics, "H04_group_calibration.csv"),
  "group_calibration"
)
h04_write_csv(
  heterogeneity_gate,
  file.path(roots$diagnostics, "H04_heterogeneity_architecture_gate.csv"),
  "heterogeneity_gate"
)
h04_write_csv(
  influence_jobs,
  file.path(roots$diagnostics, "H04_influence_refit_registry.csv"),
  "influence_registry"
)

h04_write_csv(
  main_estimands,
  file.path(roots$tables, "H04_primary_category_estimands.csv"),
  "primary_estimands"
)
h04_write_csv(
  dplyr::bind_rows(main_estimands, sensitivity_estimands),
  file.path(roots$tables, "H04_all_category_estimands.csv"),
  "all_estimands"
)
h04_write_csv(
  dplyr::bind_rows(main_tests, heterogeneity_tests),
  file.path(roots$tables, "H04_primary_and_heterogeneity_tests.csv"),
  "primary_tests"
)
h04_write_csv(
  sensitivity_tests,
  file.path(roots$tables, "H04_sensitivity_omnibus_tests.csv"),
  "sensitivity_tests"
)
h04_write_csv(
  sensitivity_comparison,
  file.path(roots$tables, "H04_sensitivity_comparison.csv"),
  "sensitivity_comparison"
)
h04_write_csv(
  mundlak_between_estimands,
  file.path(
    roots$tables,
    "H04_mundlak_between_participant_estimands.csv"
  ),
  "mundlak_between_estimands"
)
h04_write_csv(
  mundlak_between_omnibus,
  file.path(
    roots$tables,
    "H04_mundlak_between_participant_omnibus.csv"
  ),
  "mundlak_between_omnibus"
)
h04_write_csv(
  paired_estimands,
  file.path(roots$tables, "H04_paired_placement_estimands.csv"),
  "paired_estimands"
)
h04_write_csv(
  heterogeneity_estimands,
  file.path(roots$tables, "H04_site_activity_estimands.csv"),
  "site_activity_estimands"
)
h04_write_csv(
  influence_refits,
  file.path(roots$tables, "H04_influence_category_refits.csv"),
  "influence_refits"
)
h04_write_csv(
  v0_models,
  file.path(roots$tables, "H04_v0_bridge_models.csv"),
  "v0_models_table"
)
h04_write_csv(
  v0_tests,
  file.path(roots$tables, "H04_v0_bridge_tests.csv"),
  "v0_tests"
)
h04_write_csv(
  v0_means,
  file.path(roots$tables, "H04_v0_bridge_means.csv"),
  "v0_means"
)
h04_write_csv(
  v0_ratios,
  file.path(roots$tables, "H04_v0_bridge_ratios.csv"),
  "v0_ratios"
)
h04_write_csv(
  v0_comparison,
  file.path(roots$tables, "H04_v0_denominator_and_test_comparison.csv"),
  "v0_comparison"
)
h04_write_csv(
  deferred_computation,
  file.path(roots$tables, "H04_deferred_computation.csv"),
  "deferred_computation"
)
h04_write_csv(
  software_environment,
  file.path(roots$tables, "H04_software_environment.csv"),
  "software_environment"
)

message("Creating durable source data and publication-scale figures")
h04_write_csv(
  main_estimands,
  file.path(roots$source_data, "H04_primary_category_figure.csv"),
  "primary_figure_source"
)
h04_write_csv(
  heterogeneity_estimands,
  file.path(roots$source_data, "H04_site_activity_figure.csv"),
  "site_activity_figure_source"
)
h04_write_csv(
  paired_estimands,
  file.path(roots$source_data, "H04_paired_placement_figure.csv"),
  "paired_figure_source"
)
h04_write_csv(
  residual_calibration,
  file.path(roots$source_data, "H04_diagnostic_calibration_figure.csv"),
  "diagnostic_calibration_source"
)
h04_write_csv(
  residual_acf,
  file.path(roots$source_data, "H04_diagnostic_acf_figure.csv"),
  "diagnostic_acf_source"
)
h04_save_plot(
  h04_primary_figure(main_estimands),
  "H04_primary_category_estimates",
  roots$figures,
  width = 12.5,
  height = 9.5,
  producer = producer
)
h04_save_plot(
  h04_site_activity_figure(heterogeneity_estimands),
  "H04_site_activity_estimates",
  roots$figures,
  width = 16,
  height = 9.5,
  producer = producer
)
h04_save_plot(
  h04_paired_figure(paired_estimands),
  "H04_paired_placement_comparison",
  roots$figures,
  width = 9.5,
  height = 5.8,
  producer = producer
)
h04_save_plot(
  h04_diagnostic_figure(residual_calibration, residual_acf),
  "H04_primary_diagnostics",
  roots$figures,
  width = 13,
  height = 5.8,
  producer = producer
)

h04_build_stage2_manifest()
message("H04 Stage 2 non-temporal pipeline completed")
