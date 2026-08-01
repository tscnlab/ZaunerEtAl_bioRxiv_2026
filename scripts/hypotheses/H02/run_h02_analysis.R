#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
  library(mgcv)
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
source(file.path(root, "scripts/pipeline/multiplicity.R"))
source(file.path(root, "scripts/hypotheses/H02/h02_contract.R"))
source(file.path(root, "scripts/hypotheses/H02/h02_data.R"))
source(file.path(root, "scripts/hypotheses/H02/h02_modeling.R"))

if (getRversion() != "4.6.1") {
  h02_abort("H02 requires R 4.6.1; running %s", getRversion())
}

# Fail closed if the coordinator-approved shared bundle changes after the
# H02-specific model frames are built but before any model is refitted.
input_audit <- h02_validate_inputs(root)

paths <- pipeline_paths(root)
producer <- "scripts/hypotheses/H02/run_h02_analysis.R"
directories <- file.path(
  c(
    paths$models,
    paths$diagnostics,
    paths$tables,
    paths$figures,
    paths$source_data,
    paths$manifests
  ),
  "H02"
)
invisible(vapply(
  directories,
  dir.create,
  logical(1),
  recursive = TRUE,
  showWarnings = FALSE
))

artifact_metadata <- list()
record_metadata <- function(metadata, id) {
  artifact_metadata[[id]] <<- metadata
  invisible(metadata)
}
write_h02_csv <- function(data, path, id) {
  record_metadata(
    write_csv_artifact(data, path, producer),
    id
  )
}
write_h02_rds <- function(object, path, id, metadata = list()) {
  record_metadata(
    write_rds_artifact(object, path, producer, metadata),
    id
  )
}
write_h02_plot <- function(plot, path, id, width, height) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  temporary <- tempfile(
    pattern = paste0(tools::file_path_sans_ext(basename(path)), "."),
    tmpdir = dirname(path),
    fileext = paste0(".", tools::file_ext(path))
  )
  on.exit(unlink(temporary), add = TRUE)
  ggplot2::ggsave(
    filename = temporary,
    plot = plot,
    width = width,
    height = height,
    units = "in",
    dpi = 300,
    bg = "white"
  )
  atomic_replace_artifact(temporary, path)
  info <- file.info(path)
  record_metadata(
    list(
      path = normalizePath(path, winslash = "/", mustWork = TRUE),
      sha256 = artifact_sha256(path),
      bytes = unname(info$size),
      producer = producer,
      r_version = as.character(getRversion()),
      written_utc = format(Sys.time(), tz = "UTC", usetz = TRUE)
    ),
    id
  )
}

registry <- h02_run_registry() |>
  dplyr::mutate(
    run_order = dplyr::case_when(
      .data$analytical_role == "primary" ~ 1L,
      .data$analytical_role == "manuscript_prepared_data_sensitivity" ~ 2L,
      .data$data_scenario_id == "main" &
        .data$placement == "chest" &
        .data$sample_scenario == "all_available" ~
        3L,
      .data$data_scenario_id == "manuscript_prepared_data" &
        .data$placement == "chest" &
        .data$sample_scenario == "all_available" ~
        4L,
      .data$data_scenario_id == "main" ~ 5L,
      TRUE ~ 6L
    )
  ) |>
  dplyr::arrange(.data$run_order, .data$run_id)

model_tables <- list()
comparison_tables <- list()
residual_acf_tables <- list()
residual_summary_tables <- list()
boundary_tables <- list()
k_check_tables <- list()
influence_score_tables <- list()
contribution_influence_tables <- list()
site_prediction_tables <- list()
variation_tables <- list()
selected_model_id <- NULL
primary_rho <- NA_real_

for (i in seq_len(nrow(registry))) {
  run <- registry[i, ]
  run_id <- run$run_id
  message(
    "Fitting H02 run ",
    i,
    "/",
    nrow(registry),
    ": ",
    run_id
  )
  frame_path <- file.path(
    paths$model_data,
    "H02",
    paste0(run_id, ".rds")
  )
  if (!file.exists(frame_path)) {
    h02_abort(
      "Missing H02 model frame %s; run build_h02_model_data.R first",
      frame_path
    )
  }
  frame <- readRDS(frame_path)

  if (run$analytical_role == "primary") {
    fitted <- h02_fit_primary_structure(frame, run_id)
    selected_model_id <- fitted$selected_model_id
    primary_rho <- fitted$rho
    model_tables[[run_id]] <- dplyr::bind_rows(
      fitted$model_table,
      h02_model_row(
        fitted$final,
        paste0(selected_model_id, "_final_fREML"),
        run_id,
        fitted$rho
      )
    )
    comparison_tables[[run_id]] <- fitted$comparisons
  } else {
    if (is.null(selected_model_id)) {
      h02_abort("Primary H02 model must be selected before sensitivities")
    }
    fitted <- h02_fit_selected_run(
      frame,
      run_id,
      selected_model_id
    )
    model_tables[[run_id]] <- fitted$model_table
  }

  residual_acf_tables[[run_id]] <- dplyr::bind_rows(
    h02_residual_acf(
      fitted$preliminary,
      fitted$data,
      "preliminary_no_AR1",
      run_id
    ),
    h02_residual_acf(
      fitted$final,
      fitted$data,
      "final_AR1_standardized",
      run_id
    )
  )
  residual_summary_tables[[run_id]] <- h02_residual_summary(
    fitted$final,
    fitted$data,
    run_id
  )
  boundary_tables[[run_id]] <- h02_boundary_audit(
    fitted$data,
    run_id
  )
  k_check_tables[[run_id]] <- h02_k_check(fitted$final, run_id)
  influence_score_tables[[run_id]] <- h02_influence_scores(
    fitted$final,
    fitted$data,
    run_id
  )

  site_predictions <- h02_site_predictions(
    fitted$final,
    fitted$data,
    run_id
  )
  variation <- h02_variation_summary(
    fitted$final,
    fitted$data,
    site_predictions,
    run_id
  )
  site_prediction_tables[[run_id]] <- site_predictions
  variation_tables[[run_id]] <- variation$summary

  if (run$analytical_role == "primary") {
    contribution_influence_tables[[run_id]] <-
      h02_contribution_influence(
        variation$contributions,
        variation$summary,
        run_id
      )
  }

  checkpoint <- list(
    run_id = run_id,
    selected_model_id = selected_model_id,
    rho = fitted$rho,
    model_table = model_tables[[run_id]],
    comparisons = comparison_tables[[run_id]],
    residual_acf = residual_acf_tables[[run_id]],
    residual_summary = residual_summary_tables[[run_id]],
    boundary_audit = boundary_tables[[run_id]],
    k_check = k_check_tables[[run_id]],
    influence_scores = influence_score_tables[[run_id]],
    contribution_influence = contribution_influence_tables[[run_id]],
    site_predictions = site_prediction_tables[[run_id]],
    variation_summary = variation_tables[[run_id]]
  )
  write_h02_rds(
    checkpoint,
    file.path(
      paths$diagnostics,
      "H02",
      paste0(run_id, "__checkpoint.rds")
    ),
    paste0(run_id, "__checkpoint")
  )
  model_path <- file.path(
    paths$models,
    "H02",
    paste0(run_id, "__selected_model.rds")
  )
  write_h02_rds(
    fitted$final,
    model_path,
    paste0(run_id, "__model"),
    metadata = list(
      run_id = run_id,
      selected_model_id = selected_model_id,
      rho = fitted$rho,
      participants = dplyr::n_distinct(fitted$data$participant),
      participant_days = dplyr::n_distinct(fitted$data$participant_day),
      observations = nrow(fitted$data),
      sites = dplyr::n_distinct(fitted$data$site)
    )
  )
  write_h02_rds(
    variation$contributions,
    file.path(
      paths$source_data,
      "H02",
      paste0(run_id, "__fitted_contributions.rds")
    ),
    paste0(run_id, "__contributions")
  )
  write_h02_rds(
    variation$bootstrap,
    file.path(
      paths$diagnostics,
      "H02",
      paste0(run_id, "__variation_bootstrap.rds")
    ),
    paste0(run_id, "__variation_bootstrap")
  )
  rm(variation, site_predictions, frame)
  if (!is.null(fitted$candidates)) {
    fitted$candidates <- NULL
  }
  rm(fitted)
  invisible(gc())
}

model_table <- dplyr::bind_rows(model_tables)
comparison_table <- dplyr::bind_rows(comparison_tables) |>
  dplyr::mutate(
    family_id = dplyr::if_else(
      .data$comparison_id == "site_pattern_vs_no_site",
      "H02-F1-site-pattern",
      NA_character_
    ),
    family_n = dplyr::if_else(
      .data$comparison_id == "site_pattern_vs_no_site",
      1L,
      NA_integer_
    ),
    adjustment_method = dplyr::if_else(
      .data$comparison_id == "site_pattern_vs_no_site",
      "BH",
      NA_character_
    ),
    inferential_role = dplyr::if_else(
      .data$comparison_id == "site_pattern_vs_no_site",
      "single registered omnibus site-pattern family",
      paste(
        "restricted-likelihood structure diagnostic;",
        "no multiplicity claim"
      )
    )
  )
comparison_table$p_adjusted <- NA_real_
family_rows <- which(
  comparison_table$comparison_id == "site_pattern_vs_no_site"
)
comparison_table$p_adjusted[family_rows] <- adjust_p_family(
  comparison_table$p_raw[family_rows],
  method = "BH",
  n = 1L
)
residual_acf <- dplyr::bind_rows(residual_acf_tables)
residual_summary <- dplyr::bind_rows(residual_summary_tables)
boundary_audit <- dplyr::bind_rows(boundary_tables)
k_check <- dplyr::bind_rows(k_check_tables)
influence_scores <- dplyr::bind_rows(influence_score_tables)
contribution_influence <- dplyr::bind_rows(
  contribution_influence_tables
)
site_predictions <- dplyr::bind_rows(site_prediction_tables)
variation_summary <- dplyr::bind_rows(variation_tables)
site_windows <- dplyr::bind_rows(lapply(
  unique(site_predictions$run_id),
  function(run_id) h02_site_windows(site_predictions, run_id)
))

primary_id <- "main__glasses__all_available"
manuscript_id <-
  "manuscript_prepared_data__glasses__all_available"
primary_variation <- dplyr::filter(
  variation_summary,
  .data$run_id == primary_id
)
manuscript_variation <- dplyr::filter(
  variation_summary,
  .data$run_id == manuscript_id
)
stability <- dplyr::inner_join(
  primary_variation |>
    dplyr::transmute(
      summary_id = .data$summary_id,
      main_estimate = .data$estimate,
      main_lower_95 = .data$lower_95,
      main_upper_95 = .data$upper_95
    ),
  manuscript_variation |>
    dplyr::transmute(
      summary_id = .data$summary_id,
      manuscript_estimate = .data$estimate,
      manuscript_lower_95 = .data$lower_95,
      manuscript_upper_95 = .data$upper_95
    ),
  by = "summary_id",
  relationship = "one-to-one"
) |>
  dplyr::mutate(
    relative_change = (.data$manuscript_estimate - .data$main_estimate) /
      .data$main_estimate,
    confidence_intervals_overlap = pmax(
      .data$main_lower_95,
      .data$manuscript_lower_95
    ) <=
      pmin(.data$main_upper_95, .data$manuscript_upper_95),
    ratio_summary = grepl("ratio$", .data$summary_id),
    main_relation_to_one = dplyr::case_when(
      !.data$ratio_summary ~ "not_applicable",
      .data$main_lower_95 > 1 ~ "above_one",
      .data$main_upper_95 < 1 ~ "below_one",
      TRUE ~ "includes_one"
    ),
    manuscript_relation_to_one = dplyr::case_when(
      !.data$ratio_summary ~ "not_applicable",
      .data$manuscript_lower_95 > 1 ~ "above_one",
      .data$manuscript_upper_95 < 1 ~ "below_one",
      TRUE ~ "includes_one"
    ),
    stability_classification = dplyr::case_when(
      .data$ratio_summary &
        sign(.data$main_estimate - 1) != sign(.data$manuscript_estimate - 1) ~
        "unstable",
      .data$ratio_summary &
        .data$main_relation_to_one != .data$manuscript_relation_to_one ~
        "inference-sensitive",
      abs(.data$relative_change) <= 0.20 &
        .data$confidence_intervals_overlap ~
        "stable",
      abs(.data$relative_change) <= 0.50 &
        .data$confidence_intervals_overlap ~
        "directionally stable",
      TRUE ~ "magnitude-sensitive"
    ),
    scenario_change = paste(
      "Only the prepared dataset changed; formula, transformation, basis",
      "dimensions, structure, selection result, rho-estimation algorithm,",
      "AR-boundary algorithm, summaries, and CI algorithm were identical."
    )
  )

submitted_comparison <- tibble::tribble(
  ~placement,
  ~comparison_item,
  ~submitted_value,
  ~submitted_definition,
  "glasses",
  "fitted_30_minute_observations",
  37603,
  "finite submitted model rows",
  "glasses",
  "participants",
  141,
  "submitted participant count",
  "glasses",
  "participant_term_share",
  0.1013,
  "variance of isolated participant-term predictions divided by sum of isolated term-prediction variances",
  "glasses",
  "participant_plus_day_term_share",
  0.1118,
  "sum of submitted participant and participant-day isolated prediction shares",
  "glasses",
  "site_term_share",
  0.0487,
  "variance of isolated site-term predictions divided by sum of isolated term-prediction variances",
  "glasses",
  "participant_plus_day_to_site_ratio",
  0.1118 / 0.0487,
  "ratio of the two submitted isolated term-prediction shares",
  "glasses",
  "selected_fREML_model_AIC",
  64952.13,
  "AIC from a separately fREML-fitted model with invalid participant-only AR resets",
  "chest",
  "fitted_30_minute_observations",
  41664,
  "finite submitted model rows",
  "chest",
  "participants",
  154,
  "submitted participant count",
  "chest",
  "participant_term_share",
  0.0817,
  "variance of isolated participant-term predictions divided by sum of isolated term-prediction variances",
  "chest",
  "participant_day_term_share",
  0.0159,
  "variance of isolated participant-day predictions divided by sum of isolated term-prediction variances",
  "chest",
  "participant_plus_day_term_share",
  0.0817 + 0.0159,
  "sum of submitted participant and participant-day isolated prediction shares",
  "chest",
  "site_term_share",
  0.0519,
  "variance of isolated site-term predictions divided by sum of isolated term-prediction variances",
  "chest",
  "participant_plus_day_to_site_ratio",
  (0.0817 + 0.0159) / 0.0519,
  "ratio of the two submitted isolated term-prediction shares",
  "chest",
  "selected_fREML_model_AIC",
  81644.58,
  "AIC from a separately fREML-fitted model with invalid participant-only AR resets"
) |>
  dplyr::mutate(
    submitted_source = dplyr::if_else(
      .data$comparison_item %in%
        c(
          "participants",
          "fitted_30_minute_observations"
        ),
      paste0(
        "data/metrics_separate_",
        .data$placement,
        ".RData and RQ1.qmd"
      ),
      "RQ1.qmd frozen submitted output"
    ),
    comparison_status = dplyr::case_when(
      grepl("term_share", .data$comparison_item) ~
        "not reproduced: submitted quantity is not observed variance explained and omits covariance",
      grepl("to_site_ratio", .data$comparison_item) ~
        paste(
          "definition changed: compare only the qualitative ordering;",
          "new H02 uses explicitly defined integrated fitted-curve",
          "variation with a 95% interval"
        ),
      grepl("AIC", .data$comparison_item) ~
        paste(
          "not directly comparable: submitted comparison changed fixed",
          "effects/structure and used invalid AR boundaries; new fREML",
          "comparisons keep parametric fixed effects and rho identical"
        ),
      TRUE ~ "direct sample comparison available"
    )
  )

new_primary_ratio <- primary_variation |>
  dplyr::filter(
    .data$summary_id == "participant_plus_day_to_site_ratio"
  )
new_chest_ratio <- variation_summary |>
  dplyr::filter(
    .data$run_id == "main__chest__all_available",
    .data$summary_id == "participant_plus_day_to_site_ratio"
  )
new_sample_counts <- readr::read_csv(
  file.path(paths$model_data, "H02", "sample_counts.csv"),
  show_col_types = FALSE
) |>
  dplyr::filter(
    .data$site == "ALL_SITES",
    .data$run_id %in%
      c(
        "main__glasses__all_available",
        "main__chest__all_available"
      )
  )
new_primary_counts <- new_sample_counts |>
  dplyr::filter(.data$run_id == "main__glasses__all_available")
new_chest_counts <- new_sample_counts |>
  dplyr::filter(.data$run_id == "main__chest__all_available")
if (nrow(new_primary_counts) != 1L || nrow(new_chest_counts) != 1L) {
  h02_abort("Could not resolve exact current H02 sample counts")
}
submitted_comparison <- submitted_comparison |>
  dplyr::mutate(
    new_H02_value = dplyr::case_when(
      .data$placement == "glasses" &
        .data$comparison_item == "fitted_30_minute_observations" ~
        new_primary_counts$observations_30_minute,
      .data$placement == "glasses" &
        .data$comparison_item == "participants" ~
        new_primary_counts$participants,
      .data$placement == "glasses" &
        .data$comparison_item == "participant_plus_day_to_site_ratio" ~
        new_primary_ratio$estimate,
      .data$placement == "chest" &
        .data$comparison_item == "fitted_30_minute_observations" ~
        new_chest_counts$observations_30_minute,
      .data$placement == "chest" &
        .data$comparison_item == "participants" ~
        new_chest_counts$participants,
      .data$placement == "chest" &
        .data$comparison_item == "participant_plus_day_to_site_ratio" ~
        new_chest_ratio$estimate,
      TRUE ~ NA_real_
    ),
    new_H02_lower_95 = dplyr::if_else(
      .data$placement == "glasses" &
        .data$comparison_item == "participant_plus_day_to_site_ratio",
      new_primary_ratio$lower_95,
      dplyr::if_else(
        .data$placement == "chest" &
          .data$comparison_item == "participant_plus_day_to_site_ratio",
        new_chest_ratio$lower_95,
        NA_real_
      )
    ),
    new_H02_upper_95 = dplyr::if_else(
      .data$placement == "glasses" &
        .data$comparison_item == "participant_plus_day_to_site_ratio",
      new_primary_ratio$upper_95,
      dplyr::if_else(
        .data$placement == "chest" &
          .data$comparison_item == "participant_plus_day_to_site_ratio",
        new_chest_ratio$upper_95,
        NA_real_
      )
    )
  )

primary_window_summary <- site_windows |>
  dplyr::filter(.data$run_id == primary_id) |>
  dplyr::mutate(
    window_text = dplyr::if_else(
      .data$direction == "no_simultaneous_difference",
      "No 30-minute bin had a simultaneous 95% interval excluding 1",
      sprintf(
        "%s %s-%s; point-ratio range %.2f-%.2f",
        .data$direction,
        .data$start_local_clock,
        .data$end_local_clock,
        .data$minimum_point_ratio,
        .data$maximum_point_ratio
      )
    )
  ) |>
  dplyr::group_by(.data$site) |>
  dplyr::summarise(
    new_H02_simultaneous_result = paste(
      .data$window_text,
      collapse = "; "
    ),
    .groups = "drop"
  )
submitted_site_claims <- tibble::tribble(
  ~site,
  ~submitted_claim,
  ~comparison_classification,
  "BAUA",
  "Dortmund higher after dawn and before dusk, approximately 2- to 3-fold",
  "partly retained: evening increase only",
  "FUSPCEU",
  "Madrid lower around dawn (about 5-fold) and dusk (about 2-fold)",
  "retained qualitatively with narrower simultaneous windows",
  "IZTECH",
  "Izmir lower around dawn and 3- to 4-fold higher in the evening",
  "not retained with simultaneous intervals",
  "KNUST",
  "Kumasi lower around dawn, noon, afternoon, and evening",
  "partly retained: afternoon/evening reduction only",
  "MPI",
  "Tübingen did not differ significantly from the overall curve",
  "retained",
  "RISE",
  "Borås 2- to 5-fold higher after dawn and before dusk",
  "partly retained: morning increase only",
  "THUAS",
  "Delft did not differ significantly from the overall curve",
  "retained",
  "TUM",
  "Munich showed a smaller 2- to 3-fold morning/evening increase",
  "partly retained: evening increase only",
  "UCR",
  "San José showed no significant deviation",
  "retained"
) |>
  dplyr::left_join(
    readr::read_csv(
      file.path(root, "config/site_metadata.csv"),
      show_col_types = FALSE
    ) |>
      dplyr::select("site", "city", "country"),
    by = "site",
    relationship = "one-to-one"
  ) |>
  dplyr::left_join(
    primary_window_summary,
    by = "site",
    relationship = "one-to-one"
  ) |>
  dplyr::mutate(
    submitted_source = "RQ1.qmd lines 1010-1022 and index.qmd lines 293-303",
    new_inference_scope = paste(
      "simultaneous 95% intervals across all 9 sites and 48 time bins;",
      "ratios compare each fitted site curve with the equal-site mean curve"
    )
  ) |>
  dplyr::select(
    "site",
    "city",
    "country",
    "submitted_claim",
    "new_H02_simultaneous_result",
    "comparison_classification",
    "submitted_source",
    "new_inference_scope"
  )

selected_specification <- h02_selected_model_specification(
  readRDS(file.path(
    paths$models,
    "H02",
    paste0(primary_id, "__selected_model.rds")
  )),
  selected_model_id,
  primary_rho,
  primary_id
)

tables <- list(
  model_fit_summary = model_table,
  model_structure_comparisons = comparison_table,
  residual_acf = residual_acf,
  residual_summary = residual_summary,
  ar_boundary_audit = boundary_audit,
  basis_dimension_checks = k_check,
  influence_scores = influence_scores,
  conditional_deletion_influence = contribution_influence,
  variation_summary = variation_summary,
  manuscript_prepared_stability = stability,
  submitted_implementation_comparison = submitted_comparison,
  submitted_site_claim_comparison = submitted_site_claims,
  simultaneous_site_windows = site_windows,
  selected_temporal_model_specification = selected_specification
)
table_locations <- c(
  model_fit_summary = file.path(
    paths$tables,
    "H02",
    "model_fit_summary.csv"
  ),
  model_structure_comparisons = file.path(
    paths$tables,
    "H02",
    "model_structure_comparisons.csv"
  ),
  residual_acf = file.path(
    paths$diagnostics,
    "H02",
    "residual_acf.csv"
  ),
  residual_summary = file.path(
    paths$diagnostics,
    "H02",
    "residual_summary.csv"
  ),
  ar_boundary_audit = file.path(
    paths$diagnostics,
    "H02",
    "ar_boundary_audit.csv"
  ),
  basis_dimension_checks = file.path(
    paths$diagnostics,
    "H02",
    "basis_dimension_checks.csv"
  ),
  influence_scores = file.path(
    paths$diagnostics,
    "H02",
    "influence_scores.csv"
  ),
  conditional_deletion_influence = file.path(
    paths$diagnostics,
    "H02",
    "conditional_deletion_influence.csv"
  ),
  variation_summary = file.path(
    paths$tables,
    "H02",
    "variation_summary.csv"
  ),
  manuscript_prepared_stability = file.path(
    paths$tables,
    "H02",
    "manuscript_prepared_stability.csv"
  ),
  submitted_implementation_comparison = file.path(
    paths$tables,
    "H02",
    "submitted_implementation_comparison.csv"
  ),
  submitted_site_claim_comparison = file.path(
    paths$tables,
    "H02",
    "submitted_site_claim_comparison.csv"
  ),
  simultaneous_site_windows = file.path(
    paths$tables,
    "H02",
    "simultaneous_site_windows.csv"
  ),
  selected_temporal_model_specification = file.path(
    paths$models,
    "H02",
    "selected_temporal_model_specification.csv"
  )
)
for (name in names(tables)) {
  write_h02_csv(
    tables[[name]],
    table_locations[[name]],
    paste0("table__", name)
  )
}

write_h02_csv(
  site_predictions,
  file.path(paths$source_data, "H02", "site_curve_predictions.csv"),
  "source__site_curve_predictions"
)

primary_curves <- dplyr::filter(
  site_predictions,
  .data$run_id == primary_id
)
curve_plot <- ggplot(
  primary_curves,
  aes(x = .data$time_hour, y = .data$estimate_melEDI_lx)
) +
  geom_ribbon(
    aes(
      ymin = .data$lower_melEDI_lx,
      ymax = .data$upper_melEDI_lx
    ),
    fill = "#6B7280",
    alpha = 0.22
  ) +
  geom_line(colour = "#005A8D", linewidth = 0.8) +
  facet_wrap(vars(.data$site), ncol = 3) +
  scale_x_continuous(
    breaks = seq(0, 24, by = 6),
    limits = c(0, 24)
  ) +
  scale_y_continuous(
    trans = scales::pseudo_log_trans(base = 10, sigma = 0.1),
    breaks = c(0, 1, 10, 100, 1000),
    labels = scales::label_number(big.mark = ",")
  ) +
  labs(
    x = "Local wall-clock time (hours)",
    y = "Fitted melEDI (lx; pseudo-log scale)",
    title = "H02 primary near-eye site curves",
    subtitle = paste(
      "Back-transformed conditional means with simultaneous 95%",
      "confidence bands"
    )
  ) +
  theme_minimal(base_size = 11) +
  theme(panel.grid.minor = element_blank())
write_h02_plot(
  curve_plot,
  file.path(paths$figures, "H02", "primary_site_curves.png"),
  "figure__primary_site_curves",
  width = 10,
  height = 8
)

acf_plot_data <- residual_acf |>
  dplyr::filter(.data$run_id == primary_id)
acf_plot <- ggplot(
  acf_plot_data,
  aes(
    x = .data$lag_30_minute_bins,
    y = .data$correlation,
    colour = .data$stage
  )
) +
  geom_hline(yintercept = 0, colour = "grey70") +
  geom_line(linewidth = 0.8) +
  geom_point(size = 2) +
  scale_x_continuous(breaks = seq_len(6L)) +
  scale_colour_manual(
    values = c(
      preliminary_no_AR1 = "#A61C3C",
      final_AR1_standardized = "#005A8D"
    ),
    breaks = c(
      "preliminary_no_AR1",
      "final_AR1_standardized"
    ),
    labels = c(
      "Preliminary residuals",
      "AR-standardized residuals"
    )
  ) +
  labs(
    x = "Lag (30-minute bins, never crossing an AR boundary)",
    y = "Residual correlation",
    colour = NULL,
    title = "H02 primary residual temporal dependence"
  ) +
  theme_minimal(base_size = 11) +
  theme(legend.position = "bottom", panel.grid.minor = element_blank())
write_h02_plot(
  acf_plot,
  file.path(paths$figures, "H02", "primary_residual_acf.png"),
  "figure__primary_residual_acf",
  width = 7,
  height = 4.5
)

manifest <- dplyr::bind_rows(lapply(artifact_metadata, manifest_row)) |>
  dplyr::mutate(
    path = sub(
      paste0("^", gsub("([][{}()+*^$|\\\\?.])", "\\\\\\1", root), "/"),
      "",
      .data$path
    )
  )
write_csv_artifact(
  manifest,
  file.path(paths$manifests, "H02", "H02_analysis_manifest.csv"),
  producer
)

message(
  "Completed H02 analysis with selected model ",
  selected_model_id,
  " and primary rho ",
  format(primary_rho, digits = 5)
)
