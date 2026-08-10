# Run H03 Stage 2 primary, complementary, sensitivity, influence, and V0 fits.

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
source(file.path(root, "scripts/hypotheses/H03/h03_contract.R"))
source(file.path(root, "scripts/hypotheses/H03/h03_data.R"))
source(file.path(root, "scripts/hypotheses/H03/h03_modeling.R"))
source(file.path(root, "scripts/hypotheses/H03/h03_reporting.R"))

options(lifecycle_verbosity = "quiet", warn = 1)
if (!identical(as.character(getRversion()), "4.6.1")) {
  h03_abort(
    "H03 Stage 2 requires R 4.6.1; found %s",
    as.character(getRversion())
  )
}
required_packages <- c(
  "dplyr", "tidyr", "purrr", "tibble", "readr", "digest", "openssl",
  "statmod", "sandwich", "glmmTMB", "emmeans", "performance",
  "ggplot2", "scales", "LightLogR", "cowplot", "patchwork", "gt"
)
missing_packages <- required_packages[!vapply(
  required_packages,
  requireNamespace,
  logical(1),
  quietly = TRUE
)]
if (length(missing_packages) > 0L) {
  h03_abort(
    "Missing project package(s): %s",
    paste(missing_packages, collapse = ", ")
  )
}

producer <- "scripts/hypotheses/H03/run_h03_stage2.R"
stage <- Sys.getenv("H03_STAGE", unset = "fit")
if (!stage %in% c("fit", "manifest")) {
  h03_abort("H03_STAGE must be `fit` or `manifest`")
}
roots <- list(
  model_data = file.path(root, "artifacts/06_model_data/H03"),
  models = file.path(root, "artifacts/07_models/H03"),
  diagnostics = file.path(root, "artifacts/08_diagnostics/H03"),
  tables = file.path(root, "artifacts/09_tables/H03"),
  figures = file.path(root, "artifacts/10_figures/H03"),
  source_data = file.path(root, "artifacts/11_source_data/H03"),
  manifests = file.path(root, "artifacts/12_manifests/H03")
)
invisible(vapply(
  roots,
  dir.create,
  logical(1),
  recursive = TRUE,
  showWarnings = FALSE
))

h03_relative_path <- function(path) {
  normalized <- normalizePath(path, winslash = "/", mustWork = TRUE)
  if (startsWith(normalized, paste0(root, "/"))) {
    substring(normalized, nchar(root) + 2L)
  } else {
    normalized
  }
}

h03_build_stage2_manifest <- function() {
  artifact_files <- sort(unique(unlist(lapply(
    roots,
    list.files,
    recursive = TRUE,
    full.names = TRUE
  ))))
  manifest_path <- file.path(roots$manifests, "H03_stage2_artifacts.csv")
  artifact_files <- artifact_files[
    file.exists(artifact_files) &
      !dir.exists(artifact_files) &
      normalizePath(artifact_files, winslash = "/", mustWork = TRUE) !=
        normalizePath(manifest_path, winslash = "/", mustWork = FALSE)
  ]
  code_and_reports <- c(
    file.path(root, "scripts/hypotheses/H03/h03_contract.R"),
    file.path(root, "scripts/hypotheses/H03/h03_data.R"),
    file.path(root, "scripts/hypotheses/H03/h03_modeling.R"),
    file.path(root, "scripts/hypotheses/H03/h03_reporting.R"),
    file.path(root, "scripts/hypotheses/H03/run_h03_interaction_gate.R"),
    file.path(root, "scripts/hypotheses/H03/run_h03_stage2.R"),
    file.path(root, "scripts/hypotheses/H03/build_h03_stage2_figures.R"),
    file.path(root, "scripts/hypotheses/H03/run_h03_postfit_diagnostics.R"),
    file.path(root, "scripts/hypotheses/H03/run_h03_glm_fit_assessment.R"),
    file.path(root, "scripts/hypotheses/H03/h03_temporal.R"),
    file.path(root, "scripts/hypotheses/H03/run_h03_temporal.R"),
    file.path(
      root,
      "scripts/hypotheses/H03/run_h03_temporal_cyclic_sz_comparison.R"
    ),
    file.path(root, "tests/hypotheses/H03/test_h03_stage2.R"),
    file.path(
      root,
      "audit/hypotheses/H03/02_implementation_and_v0_comparison.qmd"
    ),
    file.path(
      root,
      "audit/hypotheses/H03/02_implementation_and_v0_comparison.html"
    ),
    file.path(root, "audit/handoffs/H03_worker_handoff.md")
  )
  files <- sort(unique(c(
    artifact_files,
    code_and_reports[file.exists(code_and_reports)]
  )))
  manifest <- dplyr::bind_rows(lapply(files, function(path) {
    info <- file.info(path)
    tibble::tibble(
      path = h03_relative_path(path),
      artifact_type = tools::file_ext(path),
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
  h03_build_stage2_manifest()
  message("H03 Stage 2 manifest refreshed")
  quit(save = "no", status = 0L)
}

metadata <- list()
h03_write_csv <- function(data, path, id) {
  metadata[[id]] <<- write_csv_artifact(data, path, producer)
  invisible(path)
}
h03_write_rds <- function(object, path, id) {
  metadata[[id]] <<- write_rds_artifact(object, path, producer)
  invisible(path)
}
h03_record_plot_metadata <- function(items, prefix) {
  for (extension in names(items)) {
    metadata[[paste(prefix, extension, sep = "_")]] <<- items[[extension]]
  }
}

message("Validating frozen inputs and assembling H03 frames")
input_audit <- h03_validate_inputs(root)
inputs <- h03_load_inputs(root)
spec <- h03_specification()
formulas <- h03_formula_set()
approvals <- h03_approval_registry()
multiplicity <- h03_multiplicity_registry()
diary <- h03_prepare_diary(
  inputs$diary,
  inputs$categories,
  inputs$sites
)
near_prepared <- h03_prepare_primary_frame(
  inputs$near_eye,
  diary,
  "Near-eye",
  inputs$categories,
  inputs$sites
)
chest_prepared <- h03_prepare_primary_frame(
  inputs$chest,
  diary,
  "Chest",
  inputs$categories,
  inputs$sites
)
main_frames <- list(
  near_eye = near_prepared$frame,
  chest = chest_prepared$frame
)
paired_frames <- h03_prepare_paired_frames(
  main_frames$near_eye,
  main_frames$chest
)
paired_frames <- lapply(paired_frames, h03_add_ar_sequences)
gap_frames_raw <- h03_prepare_gap_frames(
  inputs$gap_timing_unaware,
  diary,
  inputs$categories,
  inputs$sites
)
gap_frames <- list(
  near_eye = gap_frames_raw$glasses,
  chest = gap_frames_raw$chest
)
boundary_frames <- lapply(
  main_frames,
  function(frame) h03_add_ar_sequences(h03_exclude_boundary_hours(frame))
)
supported_cell_frames <- lapply(
  main_frames,
  function(frame) {
    h03_add_ar_sequences(h03_exclude_unsupported_cells(
      frame,
      inputs$categories,
      inputs$sites,
      spec
    ))
  }
)

gate_path <- file.path(roots$models, "H03_interaction_gate_models.rds")
if (!file.exists(gate_path)) {
  h03_abort(
    "Run scripts/hypotheses/H03/run_h03_interaction_gate.R before Stage 2"
  )
}
interaction_gate <- readRDS(gate_path)
if (
  !isTRUE(interaction_gate$near_eye$gate$gate_pass[1L]) ||
    !isTRUE(interaction_gate$chest$gate$gate_pass[1L]) ||
    !identical(interaction_gate$near_eye$selected_architecture, "full_literal") ||
    !identical(
      interaction_gate$chest$selected_architecture,
      "full_observed_cell"
    )
) {
  h03_abort("The durable H03 interaction gate does not authorize full models")
}

message("Fitting primary near-eye and complementary chest mean models")
main_near <- h03_fit_additive_run(
  main_frames$near_eye,
  "main__near_eye",
  "Near-eye",
  "primary_dataset",
  inputs$categories,
  spec,
  family_prefix = "H03-F"
)
main_near$estimands$family_id <- "H03-F2-context-contrasts"
main_near$omnibus$family_id <- "H03-F1-omnibus"
main_near$observed_weighted$family_id <-
  "H03-S5-near-eye-observed-sample-weighting"

main_chest <- h03_fit_additive_run(
  main_frames$chest,
  "main__chest",
  "Chest",
  "primary_dataset",
  inputs$categories,
  spec,
  family_prefix = "H03-C"
)
main_chest$estimands$family_id <- "H03-C2-context-contrasts"
main_chest$omnibus$family_id <- "H03-C1-omnibus"
main_chest$observed_weighted$family_id <-
  "H03-S5-chest-observed-sample-weighting"

message("Extracting accepted full-interaction effects after gate selection")
near_interaction <- interaction_gate$near_eye
chest_interaction <- interaction_gate$chest
near_site_estimands <- h03_interaction_estimands(
  near_interaction$selected_bundle,
  near_interaction$selected_architecture,
  inputs$categories,
  near_interaction$cell_support,
  "H03-F4-site-context-contrasts"
) |>
  dplyr::mutate(placement = "Near-eye", .before = 1)
chest_site_estimands <- h03_interaction_estimands(
  chest_interaction$selected_bundle,
  chest_interaction$selected_architecture,
  inputs$categories,
  chest_interaction$cell_support,
  "H03-C4-site-context-contrasts"
) |>
  dplyr::mutate(placement = "Chest", .before = 1)
near_heterogeneity <- h03_interaction_omnibus(
  near_interaction$selected_bundle,
  near_interaction$selected_restriction,
  "H03-F3-site-heterogeneity",
  near_interaction$selected_architecture
) |>
  dplyr::mutate(placement = "Near-eye", .before = 1)
chest_heterogeneity <- h03_interaction_omnibus(
  chest_interaction$selected_bundle,
  chest_interaction$selected_restriction,
  "H03-C3-site-heterogeneity",
  chest_interaction$selected_architecture
) |>
  dplyr::mutate(placement = "Chest", .before = 1)

run_registry <- tibble::tribble(
  ~run_id, ~scenario_id, ~placement, ~frame_id, ~working_power, ~formula_id,
  "paired__near_eye", "paired_common_sample", "Near-eye", "paired_near", spec$working_tweedie_power, "primary_population_mean",
  "paired__chest", "paired_common_sample", "Chest", "paired_chest", spec$working_tweedie_power, "primary_population_mean",
  "gap__near_eye", "gap_timing_unaware_dataset", "Near-eye", "gap_near", spec$working_tweedie_power, "primary_population_mean",
  "gap__chest", "gap_timing_unaware_dataset", "Chest", "gap_chest", spec$working_tweedie_power, "primary_population_mean",
  "boundary_excluded__near_eye", "boundary_hours_excluded", "Near-eye", "boundary_near", spec$working_tweedie_power, "primary_population_mean",
  "boundary_excluded__chest", "boundary_hours_excluded", "Chest", "boundary_chest", spec$working_tweedie_power, "primary_population_mean",
  "supported_cells__near_eye", "unsupported_cells_excluded", "Near-eye", "supported_near", spec$working_tweedie_power, "primary_population_mean",
  "supported_cells__chest", "unsupported_cells_excluded", "Chest", "supported_chest", spec$working_tweedie_power, "primary_population_mean",
  "power_1_30__near_eye", "working_power_1_30", "Near-eye", "main_near", 1.30, "primary_population_mean",
  "power_1_30__chest", "working_power_1_30", "Chest", "main_chest", 1.30, "primary_population_mean",
  "power_1_80__near_eye", "working_power_1_80", "Near-eye", "main_near", 1.80, "primary_population_mean",
  "power_1_80__chest", "working_power_1_80", "Chest", "main_chest", 1.80, "primary_population_mean",
  "mundlak__near_eye", "mundlak_within_between", "Near-eye", "mundlak_near", spec$working_tweedie_power, "secondary_mundlak_audit",
  "mundlak__chest", "mundlak_within_between", "Chest", "mundlak_chest", spec$working_tweedie_power, "secondary_mundlak_audit"
)
scenario_frames <- list(
  paired_near = paired_frames$near_eye,
  paired_chest = paired_frames$chest,
  gap_near = gap_frames$near_eye,
  gap_chest = gap_frames$chest,
  boundary_near = boundary_frames$near_eye,
  boundary_chest = boundary_frames$chest,
  supported_near = supported_cell_frames$near_eye,
  supported_chest = supported_cell_frames$chest,
  main_near = main_frames$near_eye,
  main_chest = main_frames$chest,
  mundlak_near = h03_add_mundlak_proportions(main_frames$near_eye, spec),
  mundlak_chest = h03_add_mundlak_proportions(main_frames$chest, spec)
)

message("Running bounded additive sensitivity fits")
sensitivity_runs <- vector("list", nrow(run_registry))
for (index in seq_len(nrow(run_registry))) {
  run <- run_registry[index, , drop = FALSE]
  message("  ", run$run_id)
  formula <- formulas[[run$formula_id]]
  sensitivity_runs[[index]] <- h03_fit_additive_run(
    scenario_frames[[run$frame_id]],
    run$run_id,
    run$placement,
    run$scenario_id,
    inputs$categories,
    spec,
    working_power = run$working_power,
    formula = formula,
    family_prefix = paste0("H03-S-", run$run_id)
  )
}
names(sensitivity_runs) <- run_registry$run_id

sensitivity_estimands <- dplyr::bind_rows(lapply(
  sensitivity_runs,
  `[[`,
  "estimands"
))
sensitivity_omnibus <- dplyr::bind_rows(lapply(
  sensitivity_runs,
  `[[`,
  "omnibus"
))
sensitivity_diagnostics <- dplyr::bind_rows(lapply(
  sensitivity_runs,
  `[[`,
  "diagnostics"
))
sensitivity_samples <- dplyr::bind_rows(lapply(
  sensitivity_runs,
  `[[`,
  "sample"
))

main_estimands <- dplyr::bind_rows(
  main_near$estimands,
  main_chest$estimands
)
main_omnibus <- dplyr::bind_rows(main_near$omnibus, main_chest$omnibus)
main_diagnostics <- dplyr::bind_rows(
  main_near$diagnostics,
  main_chest$diagnostics
)
main_samples <- dplyr::bind_rows(main_near$sample, main_chest$sample)
weighting_sensitivity <- dplyr::bind_rows(
  main_near$observed_weighted,
  main_chest$observed_weighted
)

comparison_reference <- main_estimands |>
  dplyr::select(
    .data$placement,
    .data$category_code,
    primary_ratio = .data$ratio_to_indoor,
    primary_conf_low = .data$ratio_conf_low,
    primary_conf_high = .data$ratio_conf_high,
    primary_p_adjusted = .data$p_adjusted
  )
sensitivity_comparison <- sensitivity_estimands |>
  dplyr::left_join(
    comparison_reference,
    by = c("placement", "category_code"),
    relationship = "many-to-one"
  ) |>
  dplyr::mutate(
    ratio_relative_change_percent = 100 *
      (.data$ratio_to_indoor / .data$primary_ratio - 1),
    sign_relative_to_null_concordant = sign(log(.data$ratio_to_indoor)) ==
      sign(log(.data$primary_ratio)),
    primary_ratio_inside_sensitivity_interval =
      .data$primary_ratio >= .data$ratio_conf_low &
      .data$primary_ratio <= .data$ratio_conf_high,
    stability = dplyr::case_when(
      .data$estimability_status == "SUPPORT_NON_ESTIMABLE" ~
        "support_non_estimable",
      !is.finite(.data$ratio_to_indoor) ~ "non_estimable",
      .data$sign_relative_to_null_concordant &
        abs(.data$ratio_relative_change_percent) <= 25 ~ "stable",
      .data$sign_relative_to_null_concordant ~ "magnitude_shift",
      TRUE ~ "direction_shift"
    )
  )

paired_comparison <- sensitivity_estimands |>
  dplyr::filter(.data$scenario_id == "paired_common_sample") |>
  dplyr::mutate(
    placement_id = dplyr::recode(
      .data$placement,
      `Near-eye` = "near_eye",
      Chest = "chest"
    )
  ) |>
  dplyr::select(
    .data$placement_id,
    .data$category_order,
    .data$category_code,
    .data$estimability_status,
    .data$ratio_to_indoor,
    .data$ratio_conf_low,
    .data$ratio_conf_high,
    .data$hours,
    .data$participants,
    .data$participant_days,
    .data$sites
  ) |>
  tidyr::pivot_wider(
    names_from = "placement_id",
    values_from = c(
      "estimability_status", "ratio_to_indoor", "ratio_conf_low",
      "ratio_conf_high", "hours", "participants", "participant_days",
      "sites"
    ),
    names_glue = "{.value}_{placement_id}"
  ) |>
  dplyr::transmute(
    .data$category_order,
    .data$category_code,
    near_estimability_status = .data$estimability_status_near_eye,
    chest_estimability_status = .data$estimability_status_chest,
    near_ratio = .data$ratio_to_indoor_near_eye,
    near_conf_low = .data$ratio_conf_low_near_eye,
    near_conf_high = .data$ratio_conf_high_near_eye,
    chest_ratio = .data$ratio_to_indoor_chest,
    chest_conf_low = .data$ratio_conf_low_chest,
    chest_conf_high = .data$ratio_conf_high_chest,
    paired_hours_near = .data$hours_near_eye,
    paired_hours_chest = .data$hours_chest,
    paired_participants_near = .data$participants_near_eye,
    paired_participants_chest = .data$participants_chest,
    paired_days_near = .data$participant_days_near_eye,
    paired_days_chest = .data$participant_days_chest,
    paired_sites_near = .data$sites_near_eye,
    paired_sites_chest = .data$sites_chest
  )

message("Running bounded leave-one-site and participant-influence refits")
influence_refit <- function(
  frame,
  placement,
  deletion_type,
  deletion_id,
  primary_result,
  fit_interaction = FALSE,
  primary_site_estimands = NULL,
  selected_architecture = NULL
) {
  reduced <- if (deletion_type == "site") {
    dplyr::filter(frame, as.character(.data$site) != deletion_id)
  } else {
    dplyr::filter(frame, as.character(.data$participant) != deletion_id)
  }
  reduced <- h03_add_ar_sequences(droplevels(reduced))
  run_id <- paste("influence", placement, deletion_type, deletion_id, sep = "__")
  additive <- h03_fit_additive_run(
    reduced,
    run_id,
    placement,
    paste0("delete_", deletion_type),
    inputs$categories,
    spec,
    family_prefix = paste0("H03-I-", placement, "-", deletion_type)
  )
  category <- additive$estimands |>
    dplyr::left_join(
      primary_result$estimands |>
        dplyr::select(
          .data$category_code,
          full_ratio = .data$ratio_to_indoor,
          full_conf_low = .data$ratio_conf_low,
          full_conf_high = .data$ratio_conf_high,
          full_p_adjusted = .data$p_adjusted
        ),
      by = "category_code",
      relationship = "one-to-one"
    ) |>
    dplyr::mutate(
      deletion_type = deletion_type,
      deletion_id = deletion_id,
      full_omnibus_p = primary_result$omnibus$p_raw,
      deletion_omnibus_p = additive$omnibus$p_raw,
      omnibus_decision_changed =
        (primary_result$omnibus$p_raw < 0.05) !=
        (additive$omnibus$p_raw < 0.05),
      ratio_relative_change_percent = 100 *
        (.data$ratio_to_indoor / .data$full_ratio - 1),
      full_ratio_inside_deletion_interval =
        .data$full_ratio >= .data$ratio_conf_low &
        .data$full_ratio <= .data$ratio_conf_high,
      .before = 1
    )
  site_result <- NULL
  if (fit_interaction) {
    interaction_frame <- h03_make_interaction_frame(
      reduced,
      selected_architecture,
      inputs$categories,
      spec
    )
    interaction_bundle <- h03_fit_quasi(
      h03_interaction_formula(selected_architecture),
      interaction_frame,
      spec$working_tweedie_power
    )
    restriction <- h03_interaction_restriction(
      interaction_bundle,
      selected_architecture
    )
    support <- h03_cell_support(
      reduced,
      inputs$categories,
      inputs$sites,
      spec
    )
    site_result <- h03_interaction_estimands(
      interaction_bundle,
      selected_architecture,
      inputs$categories,
      support,
      paste0("H03-I-site-context-", deletion_type)
    ) |>
      dplyr::left_join(
        primary_site_estimands |>
          dplyr::select(
            .data$site,
            .data$category_code,
            full_site_deviation = .data$site_deviation_ratio,
            full_site_conf_low = .data$site_deviation_conf_low,
            full_site_conf_high = .data$site_deviation_conf_high
          ),
        by = c("site", "category_code"),
        relationship = "one-to-one"
      ) |>
      dplyr::mutate(
        placement = placement,
        deletion_type = deletion_type,
        deletion_id = deletion_id,
        site_deviation_relative_change_percent = 100 *
          (.data$site_deviation_ratio / .data$full_site_deviation - 1),
        full_deviation_inside_deletion_interval =
          .data$full_site_deviation >= .data$site_deviation_conf_low &
          .data$full_site_deviation <= .data$site_deviation_conf_high,
        .before = 1
      )
  }
  list(
    category = category,
    site = site_result,
    diagnostics = additive$diagnostics,
    sample = additive$sample
  )
}

near_clusters <- h03_cluster_diagnostics(main_near$bundle)
chest_clusters <- h03_cluster_diagnostics(main_chest$bundle)
influence_jobs <- dplyr::bind_rows(
  tidyr::crossing(
    placement = c("Near-eye", "Chest"),
    deletion_type = "site",
    deletion_id = c(
      levels(main_near$bundle$data$site),
      setdiff(
        levels(main_chest$bundle$data$site),
        levels(main_near$bundle$data$site)
      )
    )
  ) |>
    dplyr::filter(
      (.data$placement == "Near-eye" &
        .data$deletion_id %in% levels(main_near$bundle$data$site)) |
        (.data$placement == "Chest" &
          .data$deletion_id %in% levels(main_chest$bundle$data$site))
    ),
  tibble::tibble(
    placement = "Near-eye",
    deletion_type = "participant",
    deletion_id = near_clusters$participant[1:5]
  ),
  tibble::tibble(
    placement = "Chest",
    deletion_type = "participant",
    deletion_id = chest_clusters$participant[1:5]
  )
)
influence_results <- vector("list", nrow(influence_jobs))
for (index in seq_len(nrow(influence_jobs))) {
  job <- influence_jobs[index, , drop = FALSE]
  message(
    "  ", job$placement, " delete ", job$deletion_type, ": ",
    job$deletion_id
  )
  is_near <- job$placement == "Near-eye"
  influence_results[[index]] <- influence_refit(
    frame = if (is_near) main_frames$near_eye else main_frames$chest,
    placement = job$placement,
    deletion_type = job$deletion_type,
    deletion_id = job$deletion_id,
    primary_result = if (is_near) main_near else main_chest,
    fit_interaction = is_near,
    primary_site_estimands = if (is_near) near_site_estimands else NULL,
    selected_architecture = if (is_near) {
      near_interaction$selected_architecture
    } else {
      NULL
    }
  )
}
influence_category <- dplyr::bind_rows(lapply(
  influence_results,
  `[[`,
  "category"
))
influence_site <- dplyr::bind_rows(lapply(
  influence_results,
  `[[`,
  "site"
))
influence_diagnostics <- dplyr::bind_rows(lapply(
  influence_results,
  `[[`,
  "diagnostics"
))
influence_samples <- dplyr::bind_rows(lapply(
  influence_results,
  `[[`,
  "sample"
))

message("Running exact V0 five-category joint-test bridges")
v0_near <- h03_v0_bridge(main_frames$near_eye, "Near-eye", spec)
v0_chest <- h03_v0_bridge(main_frames$chest, "Chest", spec)
v0_models <- dplyr::bind_rows(v0_near$model_table, v0_chest$model_table)
v0_tests <- dplyr::bind_rows(v0_near$test, v0_chest$test)
v0_ratios <- dplyr::bind_rows(v0_near$ratios, v0_chest$ratios)
v0_comparison <- dplyr::bind_rows(
  tibble::tribble(
    ~placement, ~implementation, ~observations, ~categories, ~test_definition,
    "Near-eye", "Frozen V0", 16774L, 5L,
    "site-only versus category-plus-site-interaction likelihood-ratio test",
    "Chest", "Frozen V0", 18391L, 5L,
    "site-only versus category-plus-site-interaction likelihood-ratio test"
  ),
  v0_models |>
    dplyr::filter(.data$model_id == "v0_full_joint") |>
    dplyr::transmute(
      .data$placement,
      implementation = "Exact V0 bridge on current common rows",
      .data$observations,
      .data$categories,
      test_definition = paste(
        "site-only versus category-plus-site-interaction likelihood-ratio test"
      )
    ),
  main_samples |>
    dplyr::transmute(
      .data$placement,
      implementation = "Approved H03 Stage 2",
      .data$observations,
      categories = 7L,
      test_definition = paste(
        "separate six-restriction category robust Wald-F and",
        "site-heterogeneity robust Wald-F tests"
      )
    )
)

model_diagnostics <- dplyr::bind_rows(
  main_diagnostics,
  sensitivity_diagnostics,
  influence_diagnostics
)
residual_groups <- dplyr::bind_rows(
  h03_residual_group_summary(main_near$bundle, "main__near_eye") |>
    dplyr::mutate(placement = "Near-eye", .after = "run_id"),
  h03_residual_group_summary(main_chest$bundle, "main__chest") |>
    dplyr::mutate(placement = "Chest", .after = "run_id")
)
residual_plot_data <- dplyr::bind_rows(
  h03_residual_plot_data(main_near$bundle, "main__near_eye") |>
    dplyr::mutate(placement = "Near-eye", .after = "run_id"),
  h03_residual_plot_data(main_chest$bundle, "main__chest") |>
    dplyr::mutate(placement = "Chest", .after = "run_id")
)
cluster_diagnostics <- dplyr::bind_rows(
  near_clusters |>
    dplyr::mutate(run_id = "main__near_eye", placement = "Near-eye", .before = 1),
  chest_clusters |>
    dplyr::mutate(run_id = "main__chest", placement = "Chest", .before = 1)
)

main_tests <- dplyr::bind_rows(
  main_omnibus,
  near_heterogeneity,
  chest_heterogeneity
)
all_samples <- dplyr::bind_rows(
  main_samples,
  sensitivity_samples,
  influence_samples
)
all_category_estimands <- dplyr::bind_rows(
  main_estimands,
  sensitivity_estimands,
  weighting_sensitivity
)
all_site_estimands <- dplyr::bind_rows(
  near_site_estimands,
  chest_site_estimands
)

formula_registry <- tibble::tibble(
  formula_id = names(formulas),
  formula = vapply(
    formulas,
    function(value) paste(deparse(value), collapse = " "),
    character(1)
  )
)
deferred_computation <- tibble::tribble(
  ~component, ~status, ~reason, ~pilot_or_production,
  "site-stratified participant bootstrap", "DEFERRED",
  "50-replicate feasibility pilot completed in Stage 1; production requires approval",
  "production not run",
  "simultaneous temporal bands", "DEFERRED",
  "requires a 100-draw pilot and separate production approval",
  "pilot not yet run",
  "temporal Shapley uncertainty simulation", "DEFERRED",
  "exact point allocation does not require simulation; interval simulation requires approval",
  "production not run"
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

message("Writing H03 Stage 2 tables, diagnostics, and model objects")
h03_write_csv(input_audit, file.path(roots$model_data, "H03_input_audit.csv"), "input_audit")
h03_write_csv(approvals, file.path(roots$model_data, "H03_author_approvals.csv"), "approvals")
h03_write_csv(multiplicity, file.path(roots$model_data, "H03_multiplicity_registry.csv"), "multiplicity")
h03_write_csv(formula_registry, file.path(roots$model_data, "H03_formula_registry.csv"), "formulas")
h03_write_csv(run_registry, file.path(roots$model_data, "H03_sensitivity_run_registry.csv"), "run_registry")
h03_write_csv(all_samples, file.path(roots$model_data, "H03_model_frame_index.csv"), "samples")
h03_write_csv(
  dplyr::bind_rows(
    h03_category_support(main_frames$near_eye, inputs$categories, spec) |>
      dplyr::mutate(placement = "Near-eye", .before = 1),
    h03_category_support(main_frames$chest, inputs$categories, spec) |>
      dplyr::mutate(placement = "Chest", .before = 1)
  ),
  file.path(roots$model_data, "H03_category_support.csv"),
  "category_support"
)
h03_write_csv(
  dplyr::bind_rows(
    h03_cell_support(main_frames$near_eye, inputs$categories, inputs$sites, spec) |>
      dplyr::select(-"participant_ids", -"reference_ids") |>
      dplyr::mutate(placement = "Near-eye", .before = 1),
    h03_cell_support(main_frames$chest, inputs$categories, inputs$sites, spec) |>
      dplyr::select(-"participant_ids", -"reference_ids") |>
      dplyr::mutate(placement = "Chest", .before = 1)
  ),
  file.path(roots$model_data, "H03_site_category_support.csv"),
  "cell_support"
)
h03_write_rds(
  list(
    main = main_frames,
    paired = paired_frames,
    gap_timing_unaware = gap_frames,
    boundary_excluded = boundary_frames,
    supported_cells_only = supported_cell_frames
  ),
  file.path(roots$model_data, "H03_model_frames.rds"),
  "model_frames"
)
h03_write_rds(
  list(
    main_near_eye = main_near$bundle,
    main_chest = main_chest$bundle,
    sensitivities = lapply(sensitivity_runs, `[[`, "bundle")
  ),
  file.path(roots$models, "H03_additive_model_objects.rds"),
  "additive_models"
)
h03_write_rds(
  list(
    near_eye = list(full = v0_near$full, site_only = v0_near$site_only),
    chest = list(full = v0_chest$full, site_only = v0_chest$site_only)
  ),
  file.path(roots$models, "H03_v0_bridge_model_objects.rds"),
  "v0_models"
)

h03_write_csv(main_estimands, file.path(roots$tables, "H03_primary_category_estimands.csv"), "primary_estimands")
h03_write_csv(all_category_estimands, file.path(roots$tables, "H03_all_category_estimands.csv"), "all_estimands")
h03_write_csv(main_tests, file.path(roots$tables, "H03_primary_omnibus_tests.csv"), "primary_tests")
h03_write_csv(all_site_estimands, file.path(roots$tables, "H03_site_context_estimands.csv"), "site_estimands")
h03_write_csv(sensitivity_comparison, file.path(roots$tables, "H03_sensitivity_comparison.csv"), "sensitivity_comparison")
h03_write_csv(sensitivity_omnibus, file.path(roots$tables, "H03_sensitivity_omnibus_tests.csv"), "sensitivity_tests")
h03_write_csv(paired_comparison, file.path(roots$tables, "H03_paired_placement_comparison.csv"), "paired")
h03_write_csv(influence_category, file.path(roots$tables, "H03_influence_category_refits.csv"), "influence_category")
h03_write_csv(influence_site, file.path(roots$tables, "H03_influence_site_context_refits.csv"), "influence_site")
h03_write_csv(v0_models, file.path(roots$tables, "H03_v0_bridge_models.csv"), "v0_model_table")
h03_write_csv(v0_tests, file.path(roots$tables, "H03_v0_bridge_tests.csv"), "v0_tests")
h03_write_csv(v0_ratios, file.path(roots$tables, "H03_v0_bridge_ratios.csv"), "v0_ratios")
h03_write_csv(v0_comparison, file.path(roots$tables, "H03_v0_denominator_and_test_comparison.csv"), "v0_comparison")
h03_write_csv(deferred_computation, file.path(roots$tables, "H03_deferred_computation.csv"), "deferred")

h03_write_csv(model_diagnostics, file.path(roots$diagnostics, "H03_model_diagnostics.csv"), "diagnostics")
h03_write_csv(residual_groups, file.path(roots$diagnostics, "H03_residual_group_summary.csv"), "residual_groups")
h03_write_csv(residual_plot_data, file.path(roots$source_data, "H03_primary_residual_plot_data.csv"), "residual_plot_data")
h03_write_csv(cluster_diagnostics, file.path(roots$diagnostics, "H03_cluster_influence_scores.csv"), "cluster_scores")
h03_write_csv(influence_jobs, file.path(roots$diagnostics, "H03_influence_refit_registry.csv"), "influence_jobs")
h03_write_csv(software_environment, file.path(roots$manifests, "H03_execution_environment.csv"), "environment")

primary_figure_source <- main_estimands
site_figure_source <- near_site_estimands
paired_figure_source <- paired_comparison
h03_write_csv(primary_figure_source, file.path(roots$source_data, "H03_primary_category_figure_data.csv"), "primary_figure_source")
h03_write_csv(site_figure_source, file.path(roots$source_data, "H03_near_eye_site_context_figure_data.csv"), "site_figure_source")
h03_write_csv(paired_figure_source, file.path(roots$source_data, "H03_paired_placement_figure_data.csv"), "paired_figure_source")

message("Creating bounded, final-size H03 figures")
primary_plot <- h03_primary_category_figure(
  primary_figure_source,
  inputs$categories
)
site_plot <- h03_site_context_figure(
  site_figure_source,
  inputs$categories,
  inputs$sites
)
paired_plot <- h03_paired_placement_figure(
  paired_figure_source,
  inputs$categories
)
residual_plot <- h03_residual_figure(residual_plot_data)
h03_record_plot_metadata(
  h03_save_plot(
    primary_plot,
    "H03_primary_category_estimates",
    roots$figures,
    width = 12,
    height = 10,
    producer = producer
  ),
  "primary_figure"
)
h03_record_plot_metadata(
  h03_save_plot(
    site_plot,
    "H03_near_eye_site_context_estimates",
    roots$figures,
    width = 15,
    height = 10,
    producer = producer
  ),
  "site_figure"
)
h03_record_plot_metadata(
  h03_save_plot(
    paired_plot,
    "H03_paired_placement_comparison",
    roots$figures,
    width = 8,
    height = 8,
    producer = producer
  ),
  "paired_figure"
)
h03_record_plot_metadata(
  h03_save_plot(
    residual_plot,
    "H03_primary_residual_diagnostics",
    roots$figures,
    width = 11,
    height = 6.5,
    producer = producer
  ),
  "residual_figure"
)

run_manifest <- dplyr::bind_rows(lapply(metadata, manifest_row))
write_csv_artifact(
  run_manifest,
  file.path(roots$manifests, "H03_stage2_run_manifest.csv"),
  producer
)
h03_build_stage2_manifest()

message("H03 Stage 2 primary/sensitivity/V0 execution complete")
print(as.data.frame(main_samples), row.names = FALSE)
print(as.data.frame(main_tests), row.names = FALSE)
