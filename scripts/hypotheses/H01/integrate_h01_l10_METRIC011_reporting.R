# Integrate the accepted H01 METRIC-011 L10 production amendment into
# reporting artifacts without fitting, predicting, simulating, or resampling.
#
# The canonical four-target point/bootstrap integration is assumed complete.
# This script updates only L10 rows and summaries that depend on those rows,
# writes new L10-labelled figure-source CSVs so accepted mixed source files
# remain byte-identical, and recreates only the three figures whose numerical
# coordinates include the amended L10 estimates or intervals.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
source(file.path(root, "scripts/pipeline/paths_io.R"))

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("H01 METRIC-011 reporting integration requires R 4.6.1", call. = FALSE)
}

suppressPackageStartupMessages({
  library(cowplot)
  library(dplyr)
  library(ggplot2)
  library(ggrepel)
  library(readr)
  library(tibble)
  library(tidyr)
})

producer <- paste0(
  "scripts/hypotheses/H01/",
  "integrate_h01_l10_METRIC011_reporting.R"
)
metric_id <- "l10_mean_medi"
primary_run <- "main__glasses__all_available"
chest_run <- "main__chest__all_available"
paired_near_run <- "main__glasses__paired_common_sample"
paired_chest_run <- "main__chest__paired_common_sample"
target_runs <- c(chest_run, paired_chest_run, primary_run, paired_near_run)
selected_runs <- c(primary_run, chest_run)

audit_root <- file.path(root, "audit/hypotheses/H01/l10_METRIC-011")
integration_root <- file.path(audit_root, "production_integration")
overlay_root <- file.path(integration_root, "current_overlays")
reporting_root <- file.path(integration_root, "reporting")
dir.create(reporting_root, recursive = TRUE, showWarnings = FALSE)

table_root <- file.path(root, "artifacts/09_tables/H01")
stage2_root <- file.path(table_root, "reporting")
stage3_root <- file.path(table_root, "stage3")
stage3_source_root <- file.path(root, "artifacts/11_source_data/H01/stage3")
stage3_figure_root <- file.path(root, "artifacts/10_figures/H01/stage3")

relative_to_root <- function(path) {
  normalized <- normalizePath(path, winslash = "/", mustWork = TRUE)
  prefix <- paste0(root, "/")
  ifelse(
    startsWith(normalized, prefix),
    substring(normalized, nchar(prefix) + 1L),
    normalized
  )
}

read_csv_strict <- function(path) {
  if (!file.exists(path)) {
    stop("Missing reporting-integration input: ", path, call. = FALSE)
  }
  readr::read_csv(path, show_col_types = FALSE, progress = FALSE)
}

key_string <- function(data, keys) {
  stopifnot(all(keys %in% names(data)))
  values <- lapply(data[keys], function(value) {
    value <- as.character(value)
    value[is.na(value)] <- "<NA>"
    value
  })
  do.call(paste, c(values, sep = "\r"))
}

replace_rows_by_key <- function(base, replacement, keys, label) {
  stopifnot(identical(names(base), names(replacement)))
  base_key <- key_string(base, keys)
  replacement_key <- key_string(replacement, keys)
  if (anyDuplicated(base_key) || anyDuplicated(replacement_key)) {
    stop("Duplicate key in ", label, call. = FALSE)
  }
  index <- match(replacement_key, base_key)
  if (anyNA(index)) {
    stop("Replacement key absent from ", label, call. = FALSE)
  }
  # Cast every replacement column back to the existing reporting-table type
  # before assignment.  A tibble-wide replacement can otherwise promote a
  # complete column when the bounded L10 row has a different inferred type,
  # needlessly rewriting the frozen non-L10 CSV cells.
  for (column in names(base)) {
    replacement_value <- vctrs::vec_cast(
      replacement[[column]],
      base[[column]],
      x_arg = paste0(label, " replacement$", column),
      to_arg = paste0(label, " base$", column)
    )
    base[[column]][index] <- replacement_value
  }
  base
}

copy_common_columns <- function(template, current, keys, label) {
  template_key <- key_string(template, keys)
  current_key <- key_string(current, keys)
  index <- match(template_key, current_key)
  if (anyNA(index) || anyDuplicated(template_key) || anyDuplicated(current_key)) {
    stop("Cannot align current rows for ", label, call. = FALSE)
  }
  shared <- intersect(names(template), names(current))
  shared <- setdiff(shared, keys)
  for (column in shared) {
    template[[column]] <- current[[column]][index]
  }
  template
}

write_output <- function(data, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  write_csv_artifact(data, path, producer = producer)
  path
}

verify_manifest <- function(path) {
  manifest <- read_csv_strict(path)
  stopifnot(all(c("path", "sha256") %in% names(manifest)))
  files <- file.path(root, manifest$path)
  stopifnot(all(file.exists(files)))
  observed <- unname(vapply(files, artifact_sha256, character(1)))
  stopifnot(identical(observed, unname(manifest$sha256)))
  invisible(manifest)
}

reseal_manifest <- function(path, changed_paths, additions, role) {
  manifest <- read_csv_strict(path)
  files <- file.path(root, manifest$path)
  stopifnot(all(file.exists(files)))
  manifest$sha256 <- unname(vapply(files, artifact_sha256, character(1)))
  manifest$bytes <- as.numeric(file.info(files)$size)
  changed_relative <- relative_to_root(changed_paths)
  manifest$producer[manifest$path %in% changed_relative] <- producer

  addition_paths <- additions[file.exists(additions)]
  addition_relative <- relative_to_root(addition_paths)
  new_rows <- tibble::tibble(
    path = addition_relative,
    sha256 = unname(vapply(addition_paths, artifact_sha256, character(1))),
    bytes = as.numeric(file.info(addition_paths)$size),
    role = role,
    producer = producer,
    r_version = as.character(getRversion())
  )
  shared_names <- intersect(names(manifest), names(new_rows))
  new_rows <- new_rows[, shared_names, drop = FALSE]
  for (column in setdiff(names(manifest), names(new_rows))) {
    new_rows[[column]] <- NA
  }
  new_rows <- new_rows[, names(manifest), drop = FALSE]
  manifest <- manifest |>
    filter(!.data$path %in% addition_relative) |>
    bind_rows(new_rows) |>
    arrange(.data$path)
  write_csv_artifact(manifest, path, producer = producer)
  verify_manifest(path)
  path
}

# Confirm the already-completed production integration and its frozen edge.
source(file.path(root, "tests/hypotheses/H01/test_h01_l10_METRIC011_production.R"))
integration_summary <- read_csv_strict(file.path(
  integration_root,
  "H01_METRIC-011_integration_summary.csv"
))
stopifnot(
  nrow(integration_summary) == 1L,
  integration_summary$targets == 4L,
  integration_summary$successful_refits_per_target >= 1000L,
  integration_summary$support_changes == 0L,
  integration_summary$diagnostic_disposition_changes == 0L,
  integration_summary$sensitivity_disposition_changes == 0L,
  integration_summary$claim_disposition_changes == 0L,
  integration_summary$integration_status == "PASS_NO_NEW_AUTHOR_GATE"
)

tests <- read_csv_strict(file.path(table_root, "H01_model_level_tests.csv"))
effects <- read_csv_strict(file.path(table_root, "H01_term_effects.csv"))
site_deviations <- read_csv_strict(file.path(table_root, "H01_site_deviations.csv"))
site_estimates <- read_csv_strict(file.path(table_root, "H01_site_estimates.csv"))
samples <- read_csv_strict(file.path(table_root, "H01_exact_samples.csv"))
samples_by_site <- read_csv_strict(file.path(
  table_root,
  "H01_exact_samples_by_site.csv"
))
r2 <- read_csv_strict(file.path(table_root, "H01_r2_bootstrap_summaries.csv"))
scope <- read_csv_strict(file.path(
  table_root,
  "H01_preregistered_scope_sensitivity.csv"
))
marginalization <- read_csv_strict(file.path(
  table_root,
  "H01_marginalization_comparison.csv"
))
diagnostics <- read_csv_strict(file.path(
  overlay_root,
  "H01_model_diagnostics_current.csv"
))
participant_influence <- read_csv_strict(file.path(
  overlay_root,
  "H01_participant_influence_current.csv"
))
latitude_loo <- read_csv_strict(file.path(
  overlay_root,
  "H01_latitude_leave_one_site_out_current.csv"
))

metric_registry <- read_csv_strict(file.path(
  stage3_root,
  "H01_stage3_metric_registry.csv"
))
old_exact_samples <- read_csv_strict(file.path(
  stage3_root,
  "H01_stage3_exact_samples.csv"
))
run_registry <- old_exact_samples |>
  distinct(
    .data$run_id, .data$run_order, .data$run_label, .data$data_label,
    .data$placement_label, .data$sample_label
  )
question_registry <- tibble::tribble(
  ~family_id, ~question_order, ~question_id, ~question_label,
  "H01-F1-site", 1L, "site", "Overall site",
  "H01-F2-photoperiod", 2L, "photoperiod", "Photoperiod",
  "H01-F3-latitude", 3L, "latitude", "Latitude",
  "H01-F4-site-latitude-adequacy", 4L, "adequacy",
  "Site versus linear latitude"
)
site_registry <- read_csv_strict(file.path(root, "config/site_display_registry.csv")) |>
  arrange(.data$display_order)

stopifnot(
  nrow(tests) == 8L * 17L * 4L,
  all(tests$family_n == 17L),
  all(tests$family_status == "COMPLETE"),
  nrow(r2 |> filter(
    .data$run_id %in% target_runs,
    .data$metric_id == .env$metric_id,
    .data$approximation == "lognormal"
  )) == 32L,
  all((r2 |> filter(
    .data$run_id %in% target_runs,
    .data$metric_id == .env$metric_id,
    .data$approximation == "lognormal"
  ))$bootstrap_successful_used == 1000L)
)

assessment_label <- function(value) {
  case_when(
    value == "PASS" ~ "Acceptable",
    value == "WARN_REVIEW" ~ "Acceptable with limitations",
    value == "NON_ESTIMABLE" ~ "Not fitted",
    TRUE ~ "Not acceptable"
  )
}
residual_label <- function(value) {
  case_when(
    value == "PASS" ~ "No flagged residual issue",
    value == "WARN_GAUSSIAN_DIAGNOSTIC" ~ "Gaussian residual-shape warning",
    value == "WARN_STRONG_GAUSSIAN_MISFIT" ~
      "Strong Gaussian residual-shape warning",
    value == "WARN_TWEEDIE_DIAGNOSTIC" ~
      "Tweedie simulation-diagnostic warning",
    value == "WARN_STRONG_TWEEDIE_MISFIT" ~
      "Strong Tweedie simulation-diagnostic warning",
    TRUE ~ "Not available"
  )
}
bound_label <- function(value) {
  case_when(
    value == "PASS" ~ "Prediction bounds passed",
    value == "WARN_PREDICTED_BOUND" ~
      "Predicted values crossed a physical bound",
    value == "UPPER_BOUND_UNAVAILABLE" ~
      "No verified upper bound available",
    TRUE ~ "Not available"
  )
}

# Stage 3: model result rows.
model_results_path <- file.path(stage3_root, "H01_stage3_model_results.csv")
model_results <- read_csv_strict(model_results_path)
model_l10 <- model_results |>
  filter(.data$run_id %in% selected_runs, .data$metric_id == .env$metric_id)
sample_l10 <- samples |>
  filter(.data$run_id %in% selected_runs, .data$metric_id == .env$metric_id)
model_l10 <- copy_common_columns(
  model_l10,
  sample_l10,
  c("run_id", "metric_id"),
  "Stage 3 L10 model samples"
)
sample_index <- match(model_l10$run_id, sample_l10$run_id)
model_l10$analysis_unit.x <- sample_l10$analysis_unit[sample_index]
model_l10$response_family.x <- sample_l10$response_family[sample_index]
model_l10$response_transform.x <- sample_l10$response_transform[sample_index]

for (family in question_registry$family_id) {
  prefix <- question_registry$question_id[question_registry$family_id == family]
  current <- tests |>
    filter(
      .data$run_id %in% selected_runs,
      .data$metric_id == .env$metric_id,
      .data$family_id == family
    )
  index <- match(model_l10$run_id, current$run_id)
  stopifnot(!anyNA(index))
  for (column in c(
    "statistic", "df", "p_raw", "p_adjusted", "comparison_status",
    "family_status"
  )) {
    target <- if (
      column == "p_raw" && prefix %in% c("photoperiod", "latitude")
    ) {
      paste0(prefix, "_p_raw.x")
    } else {
      paste0(prefix, "_", column)
    }
    model_l10[[target]] <- current[[column]][index]
  }
}
term_map <- c(
  photoperiod = "photoperiod_centered_hours",
  latitude = "absolute_latitude_10deg_centered"
)
for (prefix in names(term_map)) {
  term_name <- term_map[[prefix]]
  current <- effects |>
    filter(
      .data$run_id %in% selected_runs,
      .data$metric_id == .env$metric_id,
      .data$term == .env$term_name
    )
  index <- match(model_l10$run_id, current$run_id)
  stopifnot(!anyNA(index))
  model_l10[[paste0(prefix, "_effect_type")]] <- current$effect_type[index]
  model_l10[[paste0(prefix, "_estimate_practical")]] <-
    current$estimate_practical[index]
  model_l10[[paste0(prefix, "_conf_low_practical")]] <-
    current$conf_low_practical[index]
  model_l10[[paste0(prefix, "_conf_high_practical")]] <-
    current$conf_high_practical[index]
  model_l10[[paste0(prefix, "_p_raw.y")]] <- current$p_raw[index]
  model_l10[[paste0(prefix, "_interval_method")]] <-
    current$interval_method[index]
  model_l10[[paste0(prefix, "_status")]] <- current$status[index]
}
diag_l10 <- diagnostics |>
  filter(.data$run_id %in% selected_runs, .data$metric_id == .env$metric_id)
diag_index <- match(model_l10$run_id, diag_l10$run_id)
stopifnot(!anyNA(diag_index))
model_l10$assessment <- assessment_label(
  diag_l10$diagnostic_status[diag_index]
)
model_l10$residual_assessment <- residual_label(
  diag_l10$residual_status[diag_index]
)
model_l10$bound_assessment <- bound_label(
  diag_l10$prediction_bound_status[diag_index]
)
model_results <- replace_rows_by_key(
  model_results,
  model_l10[, names(model_results), drop = FALSE],
  c("run_id", "metric_id"),
  "H01_stage3_model_results.csv"
)

publication_path <- file.path(
  stage3_root,
  "H01_stage3_primary_publication_summary.csv"
)
publication <- read_csv_strict(publication_path)
publication_current <- model_results |>
  filter(.data$run_id == primary_run) |>
  transmute(
    .data$metric_order,
    .data$metric_id,
    .data$manuscript_category,
    .data$manuscript_name,
    .data$display_unit,
    .data$site_p_adjusted,
    .data$photoperiod_effect_type,
    .data$photoperiod_estimate_practical,
    .data$photoperiod_conf_low_practical,
    .data$photoperiod_conf_high_practical,
    .data$photoperiod_p_adjusted,
    .data$latitude_effect_type,
    .data$latitude_estimate_practical,
    .data$latitude_conf_low_practical,
    .data$latitude_conf_high_practical,
    .data$latitude_p_adjusted,
    .data$adequacy_p_adjusted,
    .data$participants,
    .data$participant_days,
    .data$observations,
    .data$sites
  ) |>
  arrange(.data$metric_order)
stopifnot(identical(names(publication_current), names(publication)))
publication <- publication_current

# Stage 3: exact samples and per-site support. Only four primary L10 branches
# are replaced; the four gap-timing-unaware L10 rows remain untouched.
exact_l10 <- old_exact_samples |>
  filter(.data$run_id %in% target_runs, .data$metric_id == .env$metric_id)
sample_target <- samples |>
  filter(.data$run_id %in% target_runs, .data$metric_id == .env$metric_id)
exact_l10 <- copy_common_columns(
  exact_l10,
  sample_target,
  c("run_id", "metric_id"),
  "Stage 3 exact L10 samples"
)
sample_index <- match(exact_l10$run_id, sample_target$run_id)
exact_l10$analysis_unit.x <- sample_target$analysis_unit[sample_index]
exact_l10$response_family.x <- sample_target$response_family[sample_index]
exact_l10$response_transform.x <- sample_target$response_transform[sample_index]
exact_samples <- replace_rows_by_key(
  old_exact_samples,
  exact_l10[, names(old_exact_samples), drop = FALSE],
  c("run_id", "metric_id"),
  "H01_stage3_exact_samples.csv"
)

exact_site_path <- file.path(
  stage3_root,
  "H01_stage3_exact_samples_by_site.csv"
)
exact_sites <- read_csv_strict(exact_site_path)
exact_sites_l10 <- exact_sites |>
  filter(.data$run_id %in% target_runs, .data$metric_id == .env$metric_id)
sample_site_target <- samples_by_site |>
  filter(.data$run_id %in% target_runs, .data$metric_id == .env$metric_id)
exact_sites_l10 <- copy_common_columns(
  exact_sites_l10,
  sample_site_target,
  c("run_id", "metric_id", "site"),
  "Stage 3 exact per-site L10 samples"
)
sample_site_index <- match(
  key_string(exact_sites_l10, c("run_id", "metric_id", "site")),
  key_string(sample_site_target, c("run_id", "metric_id", "site"))
)
exact_sites_l10$analysis_unit.x <-
  sample_site_target$analysis_unit[sample_site_index]
exact_sites_l10$response_family.x <-
  sample_site_target$response_family[sample_site_index]
exact_sites_l10$response_transform.x <-
  sample_site_target$response_transform[sample_site_index]
exact_sites <- replace_rows_by_key(
  exact_sites,
  exact_sites_l10[, names(exact_sites), drop = FALSE],
  c("run_id", "metric_id", "site"),
  "H01_stage3_exact_samples_by_site.csv"
)

# Stage 3: hierarchical site contrasts and exact site support.
site_path <- file.path(stage3_root, "H01_stage3_site_contrasts.csv")
site_contrasts <- read_csv_strict(site_path)
site_l10 <- site_contrasts |>
  filter(.data$run_id %in% selected_runs, .data$metric_id == .env$metric_id)
site_current <- site_deviations |>
  filter(
    .data$run_id %in% selected_runs,
    .data$metric_id == .env$metric_id,
    .data$inferential_followup_supported
  )
site_l10 <- copy_common_columns(
  site_l10,
  site_current,
  c("run_id", "metric_id", "site"),
  "Stage 3 L10 site contrasts"
)
site_index <- match(
  key_string(site_l10, c("run_id", "metric_id", "site")),
  key_string(site_current, c("run_id", "metric_id", "site"))
)
site_l10$analysis_unit.x <- site_current$analysis_unit[site_index]
site_l10$response_family.x <- site_current$response_family[site_index]
site_l10$response_transform.x <- site_current$response_transform[site_index]
site_support <- samples_by_site |>
  filter(.data$run_id %in% selected_runs, .data$metric_id == .env$metric_id)
support_index <- match(
  key_string(site_l10, c("run_id", "metric_id", "site")),
  key_string(site_support, c("run_id", "metric_id", "site"))
)
stopifnot(!anyNA(support_index))
site_l10$site_participants <- as.integer(site_support$participants[support_index])
site_l10$site_participant_days <-
  as.integer(site_support$participant_days[support_index])
site_l10$site_observations <- as.integer(site_support$observations[support_index])
site_l10 <- site_l10 |>
  mutate(
    null_value = if_else(.data$effect_type == "ratio", 1, 0),
    supported_within_metric = .data$p_adjusted_within_metric < 0.05,
    support_display = if_else(
      .data$supported_within_metric,
      "Adjusted p < 0.050",
      "Adjusted p ≥ 0.050"
    ),
    scale_group = if_else(.data$effect_type == "ratio", "Ratios", "Differences"),
    figure_panel_tag = if_else(.data$scale_group == "Ratios", "A", "B"),
    figure_panel_label = paste0(.data$figure_panel_tag, ". ", .data$scale_group),
    metric_facet_label = .data$manuscript_name,
    site_panel_key = paste(.data$metric_id, .data$site, sep = "__"),
    site_axis_label = paste0(
      sub("\\)$", "", .data$display_name),
      ", n=", .data$site_observations, ")"
    )
  ) |>
  group_by(.data$run_id, .data$metric_id) |>
  mutate(
    display_half_range = 1.08 * max(
      abs(c(
        .data$conf_low_practical - first(.data$null_value),
        .data$conf_high_practical - first(.data$null_value)
      )),
      na.rm = TRUE
    ),
    display_half_range = pmax(
      .data$display_half_range,
      if_else(first(.data$null_value) == 1, 0.05, 0.10)
    ),
    display_x_min = .data$null_value - .data$display_half_range,
    display_x_max = .data$null_value + .data$display_half_range
  ) |>
  ungroup()
site_contrasts <- replace_rows_by_key(
  site_contrasts,
  site_l10[, names(site_contrasts), drop = FALSE],
  c("run_id", "metric_id", "site"),
  "H01_stage3_site_contrasts.csv"
) |>
  arrange(.data$run_order, .data$metric_order, .data$display_order)

# Stage 3: R-squared summaries and dependent grand averages.
r2_stage3_path <- file.path(stage3_root, "H01_stage3_r2.csv")
r2_stage3 <- read_csv_strict(r2_stage3_path)
r2_l10 <- r2_stage3 |>
  filter(.data$run_id %in% selected_runs, .data$metric_id == .env$metric_id)
r2_current <- r2 |>
  filter(
    .data$run_id %in% selected_runs,
    .data$metric_id == .env$metric_id,
    .data$approximation == "lognormal"
  )
r2_l10 <- copy_common_columns(
  r2_l10,
  r2_current,
  c("run_id", "metric_id", "approximation", "measure"),
  "Stage 3 L10 R-squared summaries"
)
r2_index <- match(
  key_string(r2_l10, c("run_id", "metric_id", "approximation", "measure")),
  key_string(r2_current, c("run_id", "metric_id", "approximation", "measure"))
)
r2_l10$analysis_unit.x <- r2_current$analysis_unit[r2_index]
r2_l10$response_family.x <- r2_current$response_family[r2_index]
r2_l10$response_transform.x <- r2_current$response_transform[r2_index]

question_support <- tests |>
  filter(.data$run_id %in% selected_runs, .data$metric_id == .env$metric_id) |>
  left_join(question_registry, by = "family_id", relationship = "many-to-one") |>
  transmute(
    .data$run_id,
    .data$metric_id,
    .data$question_id,
    supported = !is.na(.data$p_adjusted) & .data$p_adjusted < 0.05
  ) |>
  pivot_wider(
    names_from = "question_id",
    values_from = "supported",
    names_glue = "{question_id}_supported"
  )
support_index <- match(
  key_string(r2_l10, c("run_id", "metric_id")),
  key_string(question_support, c("run_id", "metric_id"))
)
stopifnot(!anyNA(support_index))
for (question in c("site", "photoperiod", "latitude", "adequacy")) {
  column <- paste0(question, "_supported")
  r2_l10[[column]] <- question_support[[column]][support_index]
}
r2_l10$term_supported <- case_when(
  r2_l10$measure == "site_part_r2" ~ r2_l10$site_supported,
  r2_l10$measure == "photoperiod_part_r2" ~ r2_l10$photoperiod_supported,
  r2_l10$measure == "latitude_part_r2" ~ r2_l10$latitude_supported,
  TRUE ~ NA
)
r2_stage3 <- replace_rows_by_key(
  r2_stage3,
  r2_l10[, names(r2_stage3), drop = FALSE],
  c("run_id", "metric_id", "approximation", "measure"),
  "H01_stage3_r2.csv"
) |>
  arrange(.data$run_order, .data$metric_order, .data$measure)

r2_table_path <- file.path(stage3_root, "H01_stage3_r2_table.csv")
r2_table_old <- read_csv_strict(r2_table_path)
r2_table_measures <- c(
  "conditional_r2", "marginal_r2", "participant_associated_share",
  "unrepresented_share", "site_part_r2", "photoperiod_part_r2",
  "latitude_part_r2"
)
r2_term_measures <- c(
  "site_part_r2", "photoperiod_part_r2", "latitude_part_r2"
)
r2_table_metrics <- r2_stage3 |>
  filter(.data$measure %in% r2_table_measures) |>
  transmute(
    .data$run_id,
    .data$run_order,
    .data$run_label,
    .data$placement_label,
    row_type = "Metric",
    .data$metric_order,
    .data$metric_id,
    .data$manuscript_category,
    .data$manuscript_name,
    .data$measure,
    .data$estimate,
    .data$conf_low,
    .data$conf_high,
    .data$bootstrap_successful_used,
    .data$term_supported,
    supported_n = if_else(
      .data$measure %in% r2_term_measures & .data$term_supported %in% TRUE,
      1L,
      if_else(.data$measure %in% r2_term_measures, 0L, NA_integer_)
    ),
    unsupported_n = if_else(
      .data$measure %in% r2_term_measures & .data$term_supported %in% FALSE,
      1L,
      if_else(.data$measure %in% r2_term_measures, 0L, NA_integer_)
    )
  )
r2_table_grand <- r2_table_metrics |>
  mutate(is_term_measure = .data$measure %in% r2_term_measures) |>
  group_by(
    .data$run_id, .data$run_order, .data$run_label, .data$placement_label,
    .data$measure, .data$is_term_measure
  ) |>
  summarise(
    row_type = "Grand average",
    metric_order = 0L,
    metric_id = "grand_average",
    manuscript_category = "Grand average",
    manuscript_name = "Grand average",
    estimate = if_else(
      dplyr::first(.data$is_term_measure),
      mean(.data$estimate[.data$term_supported %in% TRUE], na.rm = TRUE),
      mean(.data$estimate, na.rm = TRUE)
    ),
    conf_low = NA_real_,
    conf_high = NA_real_,
    bootstrap_successful_used = NA_integer_,
    supported_n = if_else(
      dplyr::first(.data$is_term_measure),
      sum(.data$term_supported %in% TRUE),
      NA_integer_
    ),
    unsupported_n = if_else(
      dplyr::first(.data$is_term_measure),
      sum(.data$term_supported %in% FALSE),
      NA_integer_
    ),
    term_supported = NA,
    .groups = "drop"
  ) |>
  select(-"is_term_measure")
r2_table <- bind_rows(r2_table_grand, r2_table_metrics) |>
  arrange(.data$run_order, .data$metric_order, .data$measure)
stopifnot(identical(names(r2_table), names(r2_table_old)))

# Stage 3: detailed diagnostics.
diagnostic_path <- file.path(stage3_root, "H01_stage3_diagnostic_details.csv")
diagnostic_details <- read_csv_strict(diagnostic_path)
diagnostic_l10 <- diagnostic_details |>
  filter(.data$run_id %in% selected_runs, .data$metric_id == .env$metric_id)
diagnostic_l10 <- copy_common_columns(
  diagnostic_l10,
  diag_l10,
  c("run_id", "metric_id"),
  "Stage 3 L10 diagnostic details"
)
diag_index <- match(diagnostic_l10$run_id, diag_l10$run_id)
diagnostic_l10$assessment <- assessment_label(
  diag_l10$diagnostic_status[diag_index]
)
diagnostic_l10$residual_assessment <- residual_label(
  diag_l10$residual_status[diag_index]
)
diagnostic_l10$bound_assessment <- bound_label(
  diag_l10$prediction_bound_status[diag_index]
)
diagnostic_details <- replace_rows_by_key(
  diagnostic_details,
  diagnostic_l10[, names(diagnostic_details), drop = FALSE],
  c("run_id", "metric_id"),
  "H01_stage3_diagnostic_details.csv"
)

# Stage 3: paired/common-sample placement display.
paired_path <- file.path(stage3_root, "H01_stage3_paired_placement.csv")
paired_placement <- read_csv_strict(paired_path)
paired_l10 <- paired_placement |>
  filter(.data$metric_id == .env$metric_id)
placement_run_map <- c(near = paired_near_run, chest = paired_chest_run)
for (prefix in names(placement_run_map)) {
  run_id <- placement_run_map[[prefix]]
  current_effects <- effects |>
    filter(
      .data$run_id == .env$run_id,
      .data$metric_id == .env$metric_id,
      .data$term %in% c(
        "photoperiod_centered_hours",
        "absolute_latitude_10deg_centered"
      )
    )
  effect_index <- match(paired_l10$term, current_effects$term)
  stopifnot(!anyNA(effect_index))
  for (column in c(
    "analysis_unit", "response_family", "response_transform", "effect_type",
    "estimate_practical", "conf_low_practical", "conf_high_practical",
    "p_raw", "status"
  )) {
    paired_l10[[paste0(prefix, "_", column)]] <-
      current_effects[[column]][effect_index]
  }
  current_tests <- tests |>
    filter(
      .data$run_id == .env$run_id,
      .data$metric_id == .env$metric_id,
      .data$family_id %in% c("H01-F2-photoperiod", "H01-F3-latitude")
    ) |>
    mutate(
      term = if_else(
        .data$family_id == "H01-F2-photoperiod",
        "photoperiod_centered_hours",
        "absolute_latitude_10deg_centered"
      )
    )
  test_index <- match(paired_l10$term, current_tests$term)
  paired_l10[[paste0(prefix, "_model_level_p_raw")]] <-
    current_tests$p_raw[test_index]
  paired_l10[[paste0(prefix, "_model_level_bh_adjusted_p")]] <-
    current_tests$p_adjusted[test_index]
  current_sample <- samples |>
    filter(.data$run_id == .env$run_id, .data$metric_id == .env$metric_id)
  stopifnot(nrow(current_sample) == 1L)
  for (column in c("participants", "participant_days", "observations", "sites")) {
    paired_l10[[paste0(prefix, "_", column)]] <-
      as.integer(current_sample[[column]])
  }
}
paired_l10$effect_scale <- if_else(
  paired_l10$near_effect_type == "ratio",
  "Ratio",
  "Difference"
)
paired_l10$null_value <- if_else(paired_l10$near_effect_type == "ratio", 1, 0)
paired_l10$sample_exactly_matched <-
  paired_l10$near_participants == paired_l10$chest_participants &
  paired_l10$near_participant_days == paired_l10$chest_participant_days &
  paired_l10$near_observations == paired_l10$chest_observations &
  paired_l10$near_sites == paired_l10$chest_sites
stopifnot(all(paired_l10$sample_exactly_matched))
paired_placement <- replace_rows_by_key(
  paired_placement,
  paired_l10[, names(paired_placement), drop = FALSE],
  c("metric_id", "term"),
  "H01_stage3_paired_placement.csv"
) |>
  arrange(.data$effect_scale, .data$metric_order, .data$predictor_order)

# Stage 3: preregistered-scope, influence, leave-one-site-out, and
# marginalisation rows.
scope_path <- file.path(stage3_root, "H01_stage3_scope_sensitivity.csv")
scope_stage3 <- read_csv_strict(scope_path)
scope_l10 <- scope_stage3 |>
  filter(.data$metric_id == .env$metric_id)
scope_current <- scope |>
  filter(.data$metric_id == .env$metric_id)
scope_l10 <- copy_common_columns(
  scope_l10,
  scope_current,
  c("run_id", "metric_id", "family_id"),
  "Stage 3 L10 scope sensitivity"
)
scope_index <- match(
  key_string(scope_l10, c("run_id", "metric_id", "family_id")),
  key_string(scope_current, c("run_id", "metric_id", "family_id"))
)
scope_l10$analysis_unit.x <- scope_current$analysis_unit[scope_index]
scope_l10$response_family.x <- scope_current$response_family[scope_index]
scope_l10$response_transform.x <- scope_current$response_transform[scope_index]
scope_stage3 <- replace_rows_by_key(
  scope_stage3,
  scope_l10[, names(scope_stage3), drop = FALSE],
  c("run_id", "metric_id", "family_id"),
  "H01_stage3_scope_sensitivity.csv"
)

influence_path <- file.path(stage3_root, "H01_stage3_influence_summary.csv")
influence_stage3 <- read_csv_strict(influence_path)
influence_l10 <- participant_influence |>
  filter(.data$run_id %in% selected_runs, .data$metric_id == .env$metric_id) |>
  group_by(.data$run_id, .data$metric_order, .data$metric_id) |>
  arrange(desc(.data$maximum_absolute_dfbeta), .by_group = TRUE) |>
  summarise(
    refits = dplyr::n(),
    successful_refits = sum(.data$refit_status == "PASS"),
    maximum_absolute_dfbeta = dplyr::first(.data$maximum_absolute_dfbeta),
    most_influential_participant = dplyr::first(.data$omitted_participant),
    maximum_dfbeta_term = dplyr::first(.data$maximum_dfbeta_term),
    .groups = "drop"
  )
influence_template <- influence_stage3 |>
  filter(.data$run_id %in% selected_runs, .data$metric_id == .env$metric_id)
influence_template <- copy_common_columns(
  influence_template,
  influence_l10,
  c("run_id", "metric_id"),
  "Stage 3 L10 influence summary"
)
influence_stage3 <- replace_rows_by_key(
  influence_stage3,
  influence_template[, names(influence_stage3), drop = FALSE],
  c("run_id", "metric_id"),
  "H01_stage3_influence_summary.csv"
)

loo_path <- file.path(stage3_root, "H01_stage3_latitude_loo_summary.csv")
loo_stage3 <- read_csv_strict(loo_path)
loo_l10 <- latitude_loo |>
  filter(.data$run_id %in% selected_runs, .data$metric_id == .env$metric_id) |>
  group_by(.data$run_id, .data$metric_order, .data$metric_id, .data$effect_type) |>
  summarise(
    omitted_site_refits = dplyr::n(),
    successful_refits = sum(.data$status == "PASS" & is.na(.data$refit_error)),
    minimum_estimate = min(.data$estimate_practical, na.rm = TRUE),
    maximum_estimate = max(.data$estimate_practical, na.rm = TRUE),
    .groups = "drop"
  ) |>
  mutate(
    null_value = if_else(.data$effect_type == "ratio", 1, 0),
    range_crosses_null =
      .data$minimum_estimate <= .data$null_value &
      .data$maximum_estimate >= .data$null_value
  )
loo_template <- loo_stage3 |>
  filter(.data$run_id %in% selected_runs, .data$metric_id == .env$metric_id)
loo_template <- copy_common_columns(
  loo_template,
  loo_l10,
  c("run_id", "metric_id"),
  "Stage 3 L10 latitude leave-one-site-out summary"
)
loo_stage3 <- replace_rows_by_key(
  loo_stage3,
  loo_template[, names(loo_stage3), drop = FALSE],
  c("run_id", "metric_id"),
  "H01_stage3_latitude_loo_summary.csv"
)

marginal_path <- file.path(stage3_root, "H01_stage3_marginalization.csv")
marginal_stage3 <- read_csv_strict(marginal_path)
marginal_l10 <- marginal_stage3 |>
  filter(.data$run_id %in% selected_runs, .data$metric_id == .env$metric_id)
marginal_current <- marginalization |>
  filter(.data$run_id %in% selected_runs, .data$metric_id == .env$metric_id)
marginal_l10 <- copy_common_columns(
  marginal_l10,
  marginal_current,
  c("run_id", "metric_id"),
  "Stage 3 L10 marginalisation"
)
marginal_index <- match(marginal_l10$run_id, marginal_current$run_id)
marginal_l10$analysis_unit.x <- marginal_current$analysis_unit[marginal_index]
marginal_l10$response_family.x <- marginal_current$response_family[marginal_index]
marginal_l10$response_transform.x <-
  marginal_current$response_transform[marginal_index]
marginal_stage3 <- replace_rows_by_key(
  marginal_stage3,
  marginal_l10[, names(marginal_stage3), drop = FALSE],
  c("run_id", "metric_id"),
  "H01_stage3_marginalization.csv"
)

# Stage 2 reporting tables. V0 fields remain frozen; only current L10 fields
# and the dependent R-squared grand average are refreshed.
model_overview_path <- file.path(stage2_root, "H01_reporting_model_overview.csv")
model_overview <- read_csv_strict(model_overview_path)
overview_l10 <- model_overview |>
  filter(.data$metric_id == .env$metric_id)
stopifnot(nrow(overview_l10) == 1L)

primary_tests <- tests |>
  filter(.data$run_id == primary_run, .data$metric_id == .env$metric_id)
for (family in question_registry$family_id) {
  prefix <- question_registry$question_id[question_registry$family_id == family]
  current <- primary_tests |>
    filter(.data$family_id == family)
  stopifnot(nrow(current) == 1L)
  overview_l10[[paste0(prefix, "_p_raw")]] <- current$p_raw
  overview_l10[[paste0(prefix, "_p_adjusted")]] <- current$p_adjusted
  overview_l10[[paste0(prefix, "_comparison_status")]] <-
    current$comparison_status
}
for (prefix in names(term_map)) {
  term_name <- term_map[[prefix]]
  current <- effects |>
    filter(
      .data$run_id == primary_run,
      .data$metric_id == .env$metric_id,
      .data$term == .env$term_name
    )
  stopifnot(nrow(current) == 1L)
  for (column in c(
    "effect_type", "estimate_practical", "conf_low_practical",
    "conf_high_practical", "status"
  )) {
    overview_l10[[paste0(prefix, "_", column)]] <- current[[column]]
  }
}
overall_current <- site_estimates |>
  filter(
    .data$run_id == primary_run,
    .data$metric_id == .env$metric_id,
    .data$estimand == "overall_equal_site_mean"
  )
stopifnot(nrow(overall_current) == 1L)
overview_l10$overall_estimate <- overall_current$estimate_practical
overview_l10$overall_conf_low <- overall_current$conf_low_practical
overview_l10$overall_conf_high <- overall_current$conf_high_practical
overview_l10$overall_interval_method <- overall_current$interval_method
sample_current <- samples |>
  filter(.data$run_id == primary_run, .data$metric_id == .env$metric_id)
for (column in c(
  "participants", "participant_days", "observations", "sites",
  "derivation_support_hours", "derivation_support_status"
)) {
  overview_l10[[column]] <- sample_current[[column]]
}
diag_current <- diagnostics |>
  filter(.data$run_id == primary_run, .data$metric_id == .env$metric_id)
for (column in intersect(names(overview_l10), names(diag_current))) {
  overview_l10[[column]] <- diag_current[[column]]
}
model_overview <- replace_rows_by_key(
  model_overview,
  overview_l10[, names(model_overview), drop = FALSE],
  "metric_id",
  "H01_reporting_model_overview.csv"
)

followup_path <- file.path(stage2_root, "H01_reporting_site_followups.csv")
followups <- read_csv_strict(followup_path)
followup_l10 <- followups |>
  filter(.data$metric_id == .env$metric_id)
followup_current <- site_deviations |>
  filter(
    .data$run_id == primary_run,
    .data$metric_id == .env$metric_id,
    .data$inferential_followup_supported
  )
followup_l10 <- copy_common_columns(
  followup_l10,
  followup_current,
  c("metric_id", "site"),
  "Stage 2 L10 site follow-ups"
)
followups <- replace_rows_by_key(
  followups,
  followup_l10[, names(followups), drop = FALSE],
  c("metric_id", "site"),
  "H01_reporting_site_followups.csv"
)

report_samples_path <- file.path(stage2_root, "H01_reporting_exact_samples.csv")
report_samples <- read_csv_strict(report_samples_path)
report_sample_l10 <- report_samples |>
  filter(.data$data_scenario_id == "main", .data$metric_id == .env$metric_id)
report_sample_current <- samples |>
  filter(.data$run_id == primary_run, .data$metric_id == .env$metric_id)
report_sample_l10 <- copy_common_columns(
  report_sample_l10,
  report_sample_current,
  "metric_id",
  "Stage 2 exact L10 sample"
)
report_samples <- replace_rows_by_key(
  report_samples,
  report_sample_l10[, names(report_samples), drop = FALSE],
  c("data_scenario_id", "metric_id"),
  "H01_reporting_exact_samples.csv"
)

r2_long_path <- file.path(stage2_root, "H01_reporting_r2_preview_long.csv")
r2_long <- read_csv_strict(r2_long_path)
r2_long_l10 <- r2_long |>
  filter(.data$metric_id == .env$metric_id)
r2_primary <- r2 |>
  filter(
    .data$run_id == primary_run,
    .data$metric_id == .env$metric_id,
    .data$approximation == "lognormal"
  )
r2_long_l10 <- copy_common_columns(
  r2_long_l10,
  r2_primary,
  c("run_id", "metric_id", "approximation", "measure"),
  "Stage 2 L10 R-squared summaries"
)
r2_long_l10$evidence_status <-
  "PRODUCTION — 1,000 successful joint bootstrap refits"
r2_long_l10$preview_only <- FALSE
r2_long <- replace_rows_by_key(
  r2_long,
  r2_long_l10[, names(r2_long), drop = FALSE],
  c("run_id", "metric_id", "approximation", "measure"),
  "H01_reporting_r2_preview_long.csv"
) |>
  arrange(.data$metric_order, .data$measure)

r2_wide_path <- file.path(stage2_root, "H01_reporting_r2_preview_wide.csv")
r2_wide_old <- read_csv_strict(r2_wide_path)
r2_stage2_measures <- c(
  "conditional_r2", "marginal_r2", "site_part_r2",
  "photoperiod_part_r2", "latitude_part_r2",
  "participant_associated_share", "unrepresented_share"
)
r2_wide_metrics <- r2_long |>
  filter(.data$measure %in% r2_stage2_measures) |>
  select(
    .data$metric_order, .data$metric_id, .data$manuscript_name,
    .data$manuscript_category, .data$evidence_status, .data$preview_only,
    .data$measure, .data$estimate, .data$conf_low, .data$conf_high,
    .data$bootstrap_successful_used
  ) |>
  pivot_wider(
    names_from = .data$measure,
    values_from = c(
      .data$estimate, .data$conf_low, .data$conf_high,
      .data$bootstrap_successful_used
    ),
    names_glue = "{measure}_{.value}"
  ) |>
  arrange(.data$metric_order)
r2_grand <- r2_long |>
  filter(.data$measure %in% r2_stage2_measures) |>
  group_by(.data$measure) |>
  summarise(estimate = mean(.data$estimate, na.rm = TRUE), .groups = "drop") |>
  pivot_wider(
    names_from = .data$measure,
    values_from = .data$estimate,
    names_glue = "{measure}_estimate"
  ) |>
  mutate(
    metric_order = 0L,
    metric_id = "grand_average",
    manuscript_name = "Grand average",
    manuscript_category = "Grand average",
    evidence_status = paste(
      "DESCRIPTIVE MEAN — all component models have 1,000 successful",
      "joint bootstrap refits; no interval is claimed for this mean"
    ),
    preview_only = FALSE
  )
for (measure in r2_stage2_measures) {
  r2_grand[[paste0(measure, "_conf_low")]] <- NA_real_
  r2_grand[[paste0(measure, "_conf_high")]] <- NA_real_
  r2_grand[[paste0(measure, "_bootstrap_successful_used")]] <- NA_real_
}
r2_wide <- bind_rows(r2_grand, r2_wide_metrics) |>
  arrange(.data$metric_order)
stopifnot(identical(names(r2_wide), names(r2_wide_old)))

v0_tests_path <- file.path(stage2_root, "H01_reporting_v0_new_tests.csv")
v0_tests <- read_csv_strict(v0_tests_path)
v0_l10 <- v0_tests |>
  filter(.data$metric_id == .env$metric_id)
for (index in seq_len(nrow(v0_l10))) {
  family <- c(
    site = "H01-F1-site",
    photoperiod = "H01-F2-photoperiod",
    latitude = "H01-F3-latitude"
  )[[v0_l10$question[[index]]]]
  current <- primary_tests |>
    filter(.data$family_id == family)
  v0_l10$current_p_raw[[index]] <- current$p_raw
  v0_l10$current_p_adjusted[[index]] <- current$p_adjusted
}
v0_l10 <- v0_l10 |>
  mutate(
    current_supported = is.finite(.data$current_p_adjusted) &
      .data$current_p_adjusted < 0.05,
    support_comparison = case_when(
      .data$current_supported & .data$submitted_supported ~ "Supported in both",
      .data$current_supported & !.data$submitted_supported ~
        "Supported only in audited analysis",
      !.data$current_supported & .data$submitted_supported ~
        "Supported only in submitted analysis",
      TRUE ~ "Unsupported in both"
    )
  )
v0_tests <- replace_rows_by_key(
  v0_tests,
  v0_l10[, names(v0_tests), drop = FALSE],
  c("metric_id", "question"),
  "H01_reporting_v0_new_tests.csv"
)

v0_r2_path <- file.path(stage2_root, "H01_reporting_v0_new_r2.csv")
v0_r2 <- read_csv_strict(v0_r2_path)
v0_r2_l10 <- v0_r2 |>
  filter(.data$metric_id == .env$metric_id)
r2_current_l10 <- r2_long |>
  filter(.data$metric_id == .env$metric_id, .data$measure %in% r2_stage2_measures)
r2_index <- match(v0_r2_l10$measure, r2_current_l10$measure)
stopifnot(!anyNA(r2_index))
v0_r2_l10$current_estimate <- r2_current_l10$estimate[r2_index]
v0_r2_l10$current_conf_low <- r2_current_l10$conf_low[r2_index]
v0_r2_l10$current_conf_high <- r2_current_l10$conf_high[r2_index]
v0_r2_l10$current_bootstrap_refits <-
  r2_current_l10$bootstrap_successful_used[r2_index]
v0_r2_l10$evidence_status <- r2_current_l10$evidence_status[r2_index]
v0_r2_l10$preview_only <- r2_current_l10$preview_only[r2_index]
v0_r2_l10$difference_current_minus_submitted <-
  v0_r2_l10$current_estimate - v0_r2_l10$submitted_estimate
v0_r2 <- replace_rows_by_key(
  v0_r2,
  v0_r2_l10[, names(v0_r2), drop = FALSE],
  c("metric_id", "measure"),
  "H01_reporting_v0_new_r2.csv"
)

# Seal the non-L10 rows of every mixed table before writing. Grand-average
# rows are excluded because they are deliberately dependent on the amended
# L10 R-squared values. All MDER rows remain inside this frozen boundary.
reporting_change_paths <- c(
  model_results_path, publication_path,
  file.path(stage3_root, "H01_stage3_exact_samples.csv"), exact_site_path,
  site_path, r2_stage3_path, r2_table_path, diagnostic_path, paired_path,
  scope_path, influence_path, loo_path, marginal_path,
  model_overview_path, followup_path, report_samples_path, r2_long_path,
  r2_wide_path, v0_tests_path, v0_r2_path
)
non_l10_identity <- function(path) {
  data <- read_csv_strict(path)
  if ("metric_id" %in% names(data)) {
    data <- data |>
      filter(
        .data$metric_id != .env$metric_id,
        is.na(.data$metric_id) | .data$metric_id != "grand_average"
      )
  }
  stable_values <- lapply(data, function(value) {
    output <- enc2utf8(as.character(value))
    numeric_cell <- !is.na(output) & grepl(
      "^[+-]?(?:[0-9]+\\.?[0-9]*|\\.[0-9]+)(?:[eE][+-]?[0-9]+)?$",
      output,
      perl = TRUE
    )
    if (any(numeric_cell)) {
      numeric_value <- as.numeric(output[numeric_cell])
      output[numeric_cell] <- format(
        numeric_value,
        digits = 17L,
        scientific = TRUE,
        trim = TRUE
      )
    }
    output[is.na(value)] <- "<NA>"
    output
  })
  tibble::tibble(
    path = relative_to_root(path),
    non_l10_rows = nrow(data),
    hash_method = "column_names_and_numeric_cell_values_v2",
    non_l10_value_sha256 = digest::digest(
      list(names = names(data), values = stable_values),
      algo = "sha256",
      serialize = TRUE
    )
  )
}
reporting_baseline_path <- file.path(
  integration_root,
  "H01_METRIC-011_reporting_non_l10_baseline.csv"
)
baseline_signature <- function(data) {
  do.call(
    paste,
    c(lapply(data, function(value) {
      output <- as.character(value)
      output[is.na(value)] <- "<NA>"
      output
    }), sep = "\r")
  )
}
observed_reporting_baseline <- bind_rows(lapply(
  reporting_change_paths,
  non_l10_identity
)) |>
  arrange(.data$path)
if (file.exists(reporting_baseline_path)) {
  accepted_reporting_baseline <- read_csv_strict(reporting_baseline_path)
  expected_hash_method <- unique(observed_reporting_baseline$hash_method)
  if (
    !"hash_method" %in% names(accepted_reporting_baseline) ||
      !identical(unique(accepted_reporting_baseline$hash_method), expected_hash_method)
  ) {
    prior_method <- if ("hash_method" %in% names(accepted_reporting_baseline)) {
      unique(accepted_reporting_baseline$hash_method)
    } else {
      "serialized_type_sensitive"
    }
    prior_method <- gsub("[^A-Za-z0-9_-]", "_", prior_method)
    type_sensitive_path <- file.path(
      integration_root,
      paste0(
        "H01_METRIC-011_reporting_non_l10_",
        prior_method,
        "_prewrite_baseline.csv"
      )
    )
    if (!file.exists(type_sensitive_path)) {
      stopifnot(file.copy(reporting_baseline_path, type_sensitive_path))
    }
    accepted_reporting_baseline <- observed_reporting_baseline
    write_csv_artifact(
      accepted_reporting_baseline,
      reporting_baseline_path,
      producer = producer
    )
  } else {
    accepted_reporting_baseline <- accepted_reporting_baseline |>
      arrange(.data$path)
    stopifnot(identical(
      baseline_signature(observed_reporting_baseline),
      baseline_signature(accepted_reporting_baseline)
    ))
  }
} else {
  write_csv_artifact(
    observed_reporting_baseline,
    reporting_baseline_path,
    producer = producer
  )
  accepted_reporting_baseline <- observed_reporting_baseline
}

# Write the bounded tables.
stage3_outputs <- c(
  write_output(model_results, model_results_path),
  write_output(publication, publication_path),
  write_output(exact_samples, file.path(stage3_root, "H01_stage3_exact_samples.csv")),
  write_output(exact_sites, exact_site_path),
  write_output(site_contrasts, site_path),
  write_output(r2_stage3, r2_stage3_path),
  write_output(r2_table, r2_table_path),
  write_output(diagnostic_details, diagnostic_path),
  write_output(paired_placement, paired_path),
  write_output(scope_stage3, scope_path),
  write_output(influence_stage3, influence_path),
  write_output(loo_stage3, loo_path),
  write_output(marginal_stage3, marginal_path)
)
stage2_outputs <- c(
  write_output(model_overview, model_overview_path),
  write_output(followups, followup_path),
  write_output(report_samples, report_samples_path),
  write_output(r2_long, r2_long_path),
  write_output(r2_wide, r2_wide_path),
  write_output(v0_tests, v0_tests_path),
  write_output(v0_r2, v0_r2_path)
)
postwrite_reporting_baseline <- bind_rows(lapply(
  reporting_change_paths,
  non_l10_identity
)) |>
  arrange(.data$path)
stopifnot(identical(
  baseline_signature(postwrite_reporting_baseline),
  baseline_signature(accepted_reporting_baseline)
))

# L10-labelled, full-panel source CSVs preserve accepted mixed source files.
old_support_source <- read_csv_strict(file.path(
  stage3_source_root,
  "H01_stage3_model_support_figure_source.csv"
))
support_l10 <- old_support_source |>
  filter(.data$run_id %in% selected_runs, .data$metric_id == .env$metric_id)
support_current <- tests |>
  filter(.data$run_id %in% selected_runs, .data$metric_id == .env$metric_id)
support_l10 <- copy_common_columns(
  support_l10,
  support_current,
  c("run_id", "metric_id", "family_id"),
  "Stage 3 L10 support figure source"
)
support_l10 <- support_l10 |>
  mutate(
    support_status = case_when(
      is.na(.data$p_adjusted) ~ "Not estimable",
      .data$p_adjusted < 0.05 ~ "Supported",
      TRUE ~ "Not supported"
    ),
    support_symbol = case_when(
      .data$support_status == "Supported" ~ "✓",
      .data$support_status == "Not estimable" ~ "?",
      TRUE ~ "–"
    )
  )
support_source <- replace_rows_by_key(
  old_support_source,
  support_l10[, names(old_support_source), drop = FALSE],
  c("run_id", "metric_id", "family_id"),
  "current model-support figure source"
)
r2_source <- r2_stage3 |>
  filter(.data$measure %in% c(
    "marginal_r2", "conditional_r2", "participant_associated_share",
    "unrepresented_share"
  ))

source_paths <- c(
  model_support = file.path(
    stage3_source_root,
    "H01_stage3_METRIC011_l10_mean_medi_model_support_figure_source.csv"
  ),
  site_contrast = file.path(
    stage3_source_root,
    "H01_stage3_METRIC011_l10_mean_medi_site_contrast_figure_source.csv"
  ),
  r2 = file.path(
    stage3_source_root,
    "H01_stage3_METRIC011_l10_mean_medi_r2_figure_source.csv"
  ),
  paired = file.path(
    stage3_source_root,
    "H01_stage3_METRIC011_l10_mean_medi_paired_placement_figure_source.csv"
  )
)
write_output(support_source, source_paths[["model_support"]])
write_output(site_contrasts, source_paths[["site_contrast"]])
write_output(r2_source, source_paths[["r2"]])
write_output(paired_placement, source_paths[["paired"]])

# Recreate only figures whose coordinates contain the amended L10 results.
site_colors <- stats::setNames(site_registry$color_hex, site_registry$display_name)
make_contrast_scale_panel <- function(data, scale_group, show_legend) {
  data <- data |>
    filter(.data$scale_group == .env$scale_group)
  facet_levels <- data |>
    distinct(.data$metric_order, .data$metric_facet_label) |>
    arrange(.data$metric_order) |>
    pull(.data$metric_facet_label)
  site_panel_levels <- data |>
    distinct(.data$metric_order, .data$display_order, .data$site_panel_key) |>
    arrange(.data$metric_order, desc(.data$display_order)) |>
    pull(.data$site_panel_key)
  site_panel_labels <- data |>
    distinct(.data$site_panel_key, .data$site_axis_label) |>
    tibble::deframe()
  panel_limits <- data |>
    distinct(
      .data$metric_order, .data$metric_facet_label,
      .data$display_x_min, .data$display_x_max
    ) |>
    pivot_longer(
      cols = c("display_x_min", "display_x_max"),
      names_to = "limit_name",
      values_to = "display_limit"
    )
  data <- data |>
    mutate(
      site_panel_key = factor(.data$site_panel_key, levels = site_panel_levels),
      metric_facet_label = factor(
        .data$metric_facet_label,
        levels = facet_levels
      ),
      support_display = factor(
        .data$support_display,
        levels = c("Adjusted p < 0.050", "Adjusted p ≥ 0.050")
      )
    )
  panel_limits <- panel_limits |>
    mutate(
      metric_facet_label = factor(
        .data$metric_facet_label,
        levels = facet_levels
      )
    )
  nulls <- data |>
    distinct(.data$metric_facet_label, .data$null_value)
  ggplot(
    data,
    aes(
      x = .data$estimate_practical,
      y = .data$site_panel_key,
      colour = .data$display_name
    )
  ) +
    geom_blank(
      data = panel_limits,
      aes(x = .data$display_limit),
      inherit.aes = FALSE
    ) +
    geom_vline(
      data = nulls,
      aes(xintercept = .data$null_value),
      inherit.aes = FALSE,
      colour = "#555555",
      linetype = 2,
      linewidth = 0.35
    ) +
    geom_errorbar(
      aes(
        xmin = .data$conf_low_practical,
        xmax = .data$conf_high_practical,
        linewidth = .data$support_display
      ),
      width = 0,
      orientation = "y"
    ) +
    geom_point(
      aes(shape = .data$support_display, fill = .data$display_name),
      size = 2.7,
      stroke = 0.7
    ) +
    facet_wrap(vars(.data$metric_facet_label), scales = "free", ncol = 2) +
    scale_x_continuous(expand = expansion(mult = c(0.04, 0.04))) +
    scale_y_discrete(labels = site_panel_labels) +
    scale_colour_manual(values = site_colors, drop = FALSE, guide = "none") +
    scale_fill_manual(values = site_colors, drop = FALSE, guide = "none") +
    scale_shape_manual(
      name = "Within-metric contrast",
      values = c("Adjusted p < 0.050" = 21, "Adjusted p ≥ 0.050" = 1)
    ) +
    scale_linewidth_manual(
      values = c("Adjusted p < 0.050" = 0.9, "Adjusted p ≥ 0.050" = 0.38),
      guide = "none"
    ) +
    labs(
      title = paste0(if (scale_group == "Ratios") "A" else "B", ". ", scale_group),
      x = if (scale_group == "Ratios") {
        "Ratio versus the equally weighted site mean"
      } else {
        "Difference versus the equally weighted site mean"
      },
      y = NULL
    ) +
    theme_minimal(base_size = 11.5) +
    theme(
      panel.grid.minor = element_blank(),
      axis.text = element_text(size = 10),
      axis.title = element_text(size = 11),
      strip.text = element_text(face = "bold", size = 10.5),
      plot.title = element_text(face = "bold", size = 13, hjust = 0),
      plot.title.position = "plot",
      legend.position = if (show_legend) "bottom" else "none",
      legend.title = element_text(size = 10),
      legend.text = element_text(size = 10)
    ) +
    guides(
      shape = guide_legend(
        override.aes = list(
          colour = "#444444",
          fill = c("#444444", "white"),
          size = 2.7,
          linewidth = c(0.9, 0.38)
        )
      )
    )
}
make_contrast_plot <- function(data, placement_name) {
  selected <- data |>
    filter(.data$placement_label == .env$placement_name)
  metric_counts <- selected |>
    distinct(.data$scale_group, .data$metric_id) |>
    count(.data$scale_group, name = "metrics")
  ratio_rows <- ceiling(
    metric_counts$metrics[metric_counts$scale_group == "Ratios"] / 2
  )
  difference_rows <- ceiling(
    metric_counts$metrics[metric_counts$scale_group == "Differences"] / 2
  )
  cowplot::plot_grid(
    make_contrast_scale_panel(selected, "Ratios", show_legend = FALSE),
    make_contrast_scale_panel(selected, "Differences", show_legend = TRUE),
    ncol = 1,
    align = "v",
    axis = "lr",
    rel_heights = c(ratio_rows + 0.45, difference_rows + 0.80)
  )
}

metric_levels <- rev(metric_registry$manuscript_name)
r2_measure_labels <- c(
  marginal_r2 = "Marginal R²",
  conditional_r2 = "Conditional R²",
  participant_associated_share = "Participant-associated share",
  unrepresented_share = "Not represented"
)
r2_plot_data <- r2_source |>
  filter(.data$status == "PASS") |>
  mutate(
    manuscript_name = factor(.data$manuscript_name, levels = metric_levels),
    measure_label = factor(
      unname(r2_measure_labels[.data$measure]),
      levels = unname(r2_measure_labels)
    ),
    placement_label = factor(
      .data$placement_label,
      levels = c("Near eye", "Chest")
    )
  )
r2_plot <- ggplot(
  r2_plot_data,
  aes(
    x = .data$estimate,
    y = .data$manuscript_name,
    colour = .data$measure_label,
    shape = .data$measure_label
  )
) +
  geom_errorbar(
    aes(xmin = .data$conf_low, xmax = .data$conf_high),
    width = 0,
    orientation = "y",
    position = position_dodge(width = 0.62),
    linewidth = 0.4
  ) +
  geom_point(position = position_dodge(width = 0.62), size = 1.55) +
  facet_wrap(vars(.data$placement_label), ncol = 2) +
  scale_colour_manual(values = c("#117733", "#332288", "#CC6677", "#777777")) +
  scale_shape_manual(values = c(16, 17, 15, 18)) +
  coord_cartesian(xlim = c(0, 1)) +
  labs(x = "Share of outcome variance (95% bootstrap interval)", y = NULL) +
  theme_minimal(base_size = 9.5) +
  theme(
    panel.grid.minor = element_blank(),
    strip.text = element_text(face = "bold"),
    legend.position = "bottom",
    legend.title = element_blank()
  )

make_paired_placement_panel <- function(data, scale_name) {
  panel_data <- data |>
    filter(.data$effect_scale == scale_name)
  axis_range <- range(c(
    panel_data$near_estimate_practical,
    panel_data$chest_estimate_practical,
    panel_data$null_value
  ), na.rm = TRUE)
  padding <- max(diff(axis_range) * 0.12, 0.02)
  axis_limits <- axis_range + c(-padding, padding)
  ggplot(
    panel_data,
    aes(
      x = .data$near_estimate_practical,
      y = .data$chest_estimate_practical
    )
  ) +
    geom_abline(
      intercept = 0, slope = 1, colour = "#555555", linewidth = 0.55,
      linetype = 2
    ) +
    geom_vline(
      xintercept = unique(panel_data$null_value),
      colour = "#111111", linewidth = 0.45, linetype = 3
    ) +
    geom_hline(
      yintercept = unique(panel_data$null_value),
      colour = "#111111", linewidth = 0.45, linetype = 3
    ) +
    geom_point(
      aes(colour = .data$predictor, shape = .data$predictor),
      size = 2.1
    ) +
    ggrepel::geom_text_repel(
      aes(label = .data$point_label, colour = .data$predictor),
      size = 3.1,
      seed = 20260801,
      min.segment.length = 0,
      box.padding = 0.22,
      point.padding = 0.14,
      max.overlaps = Inf,
      show.legend = FALSE
    ) +
    scale_colour_manual(
      values = c(Photoperiod = "#117733", `Latitude per 10°` = "#332288")
    ) +
    scale_shape_manual(values = c(Photoperiod = 16, `Latitude per 10°` = 17)) +
    coord_equal(xlim = axis_limits, ylim = axis_limits, expand = TRUE) +
    labs(
      title = scale_name,
      x = "Near-eye estimate",
      y = "Chest estimate",
      colour = NULL,
      shape = NULL
    ) +
    theme_minimal(base_size = 10.5) +
    theme(
      panel.grid.minor = element_blank(),
      plot.title = element_text(face = "bold"),
      legend.position = "bottom"
    )
}

figure_specs <- list(
  H01_stage3_site_contrasts_near_eye = list(
    plot = make_contrast_plot(site_contrasts, "Near eye"),
    width = 11.5, height = 14.5
  ),
  H01_stage3_site_contrasts_chest = list(
    plot = make_contrast_plot(site_contrasts, "Chest"),
    width = 11.5, height = 21.0
  ),
  H01_stage3_r2_intervals = list(
    plot = r2_plot,
    width = 10.5, height = 8.0
  ),
  H01_stage3_paired_placement = list(
    plot = cowplot::plot_grid(
      make_paired_placement_panel(paired_placement, "Difference"),
      make_paired_placement_panel(paired_placement, "Ratio"),
      nrow = 1, align = "hv", axis = "tblr", rel_widths = c(1, 1)
    ),
    width = 12, height = 6.8
  )
)
figure_paths <- character()
for (name in names(figure_specs)) {
  specification <- figure_specs[[name]]
  for (extension in c("png", "svg")) {
    path <- file.path(stage3_figure_root, paste0(name, ".", extension))
    arguments <- list(
      filename = path,
      plot = specification$plot,
      width = specification$width,
      height = specification$height,
      units = "in",
      bg = "white"
    )
    if (extension == "png") {
      arguments$dpi <- 320
    }
    do.call(ggsave, arguments)
    figure_paths <- c(figure_paths, path)
  }
}

source_outputs <- unname(source_paths)
report_qmds <- file.path(root, c(
  "audit/hypotheses/H01/02_implementation_and_v0_comparison.qmd",
  "notebooks/hypotheses/H01.qmd",
  "audit/hypotheses/H01/H01_analysis_preparation.qmd"
))
test_path <- file.path(
  root,
  "tests/hypotheses/H01/test_h01_l10_METRIC011_reporting.R"
)
figure_qa_path <- file.path(
  reporting_root,
  "H01_METRIC-011_figure_readability_qa.md"
)
reporting_incident_path <- file.path(
  reporting_root,
  "H01_METRIC-011_reporting_integration_incident.md"
)

stage2_manifest_path <- file.path(
  root,
  "artifacts/12_manifests/H01_reporting_artifacts.csv"
)
stage3_manifest_path <- file.path(
  root,
  "artifacts/12_manifests/H01_stage3_reporting_artifacts.csv"
)
common_additions <- c(
  file.path(root, producer),
  file.path(
    integration_root,
    "H01_METRIC-011_production_integration_manifest.csv"
  ),
  file.path(
    integration_root,
    "H01_METRIC-011_integration_summary.csv"
  ),
  reporting_baseline_path,
  figure_qa_path,
  reporting_incident_path,
  report_qmds,
  test_path
)
reseal_manifest(
  stage2_manifest_path,
  stage2_outputs,
  common_additions,
  "H01 METRIC-011 bounded reporting integration"
)
reseal_manifest(
  stage3_manifest_path,
  c(stage3_outputs, source_outputs, figure_paths),
  c(common_additions, source_outputs),
  "H01 METRIC-011 bounded Stage 3 integration"
)

reporting_summary <- tibble::tibble(
  decision_id = "H01-013",
  change_id = "CHG-110",
  metric_decision = "METRIC-011",
  updated_primary_targets = 4L,
  successful_joint_refits_per_target = 1000L,
  stage2_tables_updated = length(stage2_outputs),
  stage3_tables_updated = length(stage3_outputs),
  new_l10_figure_source_files = length(source_outputs),
  dependent_figures_recreated = length(figure_specs),
  support_changes = 0L,
  diagnostic_disposition_changes = 0L,
  sensitivity_disposition_changes = 0L,
  claim_disposition_changes = 0L,
  protected_mixed_source_files_overwritten = 0L,
  status = "PASS_NO_NEW_AUTHOR_GATE"
)
summary_path <- write_output(
  reporting_summary,
  file.path(reporting_root, "H01_METRIC-011_reporting_integration_summary.csv")
)

manifest_inputs <- unique(c(
  file.path(root, producer),
  file.path(root, "tests/hypotheses/H01/test_h01_l10_METRIC011_production.R"),
  file.path(
    integration_root,
    "H01_METRIC-011_production_integration_manifest.csv"
  ),
  file.path(
    integration_root,
    "H01_METRIC-011_integration_summary.csv"
  ),
  reporting_baseline_path,
  file.path(root, "config/site_display_registry.csv"),
  figure_qa_path,
  reporting_incident_path,
  report_qmds
))
manifest_outputs <- unique(c(
  stage2_outputs,
  stage3_outputs,
  source_outputs,
  figure_paths,
  stage2_manifest_path,
  stage3_manifest_path,
  summary_path,
  reporting_baseline_path,
  figure_qa_path,
  reporting_incident_path
))
reporting_manifest <- bind_rows(lapply(
  sort(unique(c(manifest_inputs, manifest_outputs))),
  function(path) {
    tibble::tibble(
      path = relative_to_root(path),
      sha256 = artifact_sha256(path),
      bytes = as.numeric(file.info(path)$size),
      role = if_else(
        path %in% manifest_outputs,
        "H01 METRIC-011 reporting output",
        "H01 METRIC-011 verified reporting input"
      ),
      producer = producer,
      r_version = as.character(getRversion()),
      integration_status = "PASS_NO_NEW_AUTHOR_GATE"
    )
  }
))
reporting_manifest_path <- file.path(
  reporting_root,
  "H01_METRIC-011_reporting_integration_manifest.csv"
)
write_csv_artifact(reporting_manifest, reporting_manifest_path, producer = producer)

message(
  "H01 METRIC-011 reporting integration completed from stored outputs: ",
  "four L10 targets, 1,000 used refits each, no disposition change"
)
