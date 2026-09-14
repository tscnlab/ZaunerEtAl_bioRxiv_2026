# Scoped descriptives refresh for METRIC-011 L10 numerical-zero normalization.
#
# Only the eight verified L10 mean values, their L10 summaries, the Table 2
# thumbnail source/export, and provenance records are eligible to change. No
# non-L10 descriptive value or figure is rebuilt by this script.

options(warn = 2)

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
.libPaths(c(
  file.path(root, "renv/library/macos/R-4.6/aarch64-apple-darwin23"),
  .Library
))
source(file.path(root, "scripts", "descriptives", "build_descriptives.R"))
source_descriptive_modules(root)
check_descriptive_packages()
paths <- descriptive_paths(root)

producer <- "scripts/descriptives/run_l10_metric011_refresh.R"
l10_id <- "l10_mean_medi"

expected_hashes <- c(
  decision = "23b9f70d1d16f7fd3ebbdbc57aaf78c0a701fe1f9d22bd667d926cd320d40797",
  evidence_manifest = "a37efd3449a8d1a6065d0eb8964bd6cf8b241f1683a26c065ea1a946e23214fb",
  metric_manifest = "028bce108339c1277df4a070597430ea20b49c34c2888f4eef42741c1fe76a5e",
  site_context_manifest = "c0c6d7f97782c0d880a213050f576213f5d56b3204a02732f6399e7e4aeb8518",
  base_manifest = "8344bdc0339a53079bf9eeb7d86de1ad7c15373641c3a0a5a01d040b418895ce",
  preanalysis_manifest = "f3c4bfbf120d2023c045b44e3c7c04c58bce1f8d11621956bca1e5ede90c5623",
  near_eye_context = "013afe75e9b75b141b4cb48d04111a9e6c688630085a24c9fe07ca3d142a4e9a",
  chest_context = "497466ccd1a35635cca40bb8f9ce51efb97321ab04b42ee1bb76785e466a2057",
  gap_manifest = "4ed62fbe58de65a6d05d8cfc6b5d870d7c74a3c83fe89bcd72bd1dd838698935",
  renv_lock = "3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350"
)
controlling_paths <- c(
  decision = "audit/decisions/l10_numerical_zero_normalization.md",
  evidence_manifest = paste0(
    "audit/reconciliation/l10_METRIC-011/",
    "METRIC-011_evidence_manifest.csv"
  ),
  metric_manifest = "artifacts/12_manifests/metric_artifacts.csv",
  site_context_manifest = "artifacts/12_manifests/site_solar_context_artifacts.csv",
  base_manifest = "artifacts/12_manifests/base_model_data_artifacts.csv",
  preanalysis_manifest = "artifacts/12_manifests/preanalysis_comparison_artifacts.csv",
  near_eye_context = paste0(
    "artifacts/06_model_data/base/",
    "metrics_glasses_participant_day_context.rds"
  ),
  chest_context = paste0(
    "artifacts/06_model_data/base/",
    "metrics_chest_participant_day_context.rds"
  ),
  gap_manifest = "artifacts/12_manifests/manuscript_prepared_data_artifacts.csv",
  renv_lock = "renv.lock"
)
observed_hashes <- stats::setNames(
  vapply(
    file.path(root, controlling_paths),
    artifact_sha256,
    character(1)
  ),
  names(controlling_paths)
)
if (!identical(observed_hashes, expected_hashes)) {
  stop("A controlling METRIC-011 or environment hash changed", call. = FALSE)
}
if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("The scoped METRIC-011 refresh requires R 4.6.1", call. = FALSE)
}

base_manifest <- read_plot_source_csv(
  file.path(root, controlling_paths[["base_manifest"]])
)
base_input_bundle <- unique(base_manifest$input_bundle_sha256)
if (!identical(
  base_input_bundle,
  "e840ce9d2a7f653bc5ebbfe020ce087017dfdaf0276df09da578bda30a539916"
)) {
  stop("The controlling base input bundle changed", call. = FALSE)
}

evidence_manifest <- read_plot_source_csv(
  file.path(root, controlling_paths[["evidence_manifest"]])
)
evidence_paths <- file.path(root, evidence_manifest$path)
if (
  any(!file.exists(evidence_paths)) ||
    !all(evidence_manifest$status == "PASS") ||
    !identical(
      unname(vapply(evidence_paths, artifact_sha256, character(1))),
      evidence_manifest$sha256
    )
) {
  stop("The METRIC-011 evidence manifest is stale", call. = FALSE)
}
evidence_path <- file.path(
  root,
  evidence_manifest$path[
    evidence_manifest$artifact == "primary_scientific_cell_changes"
  ]
)
if (length(evidence_path) != 1L) {
  stop("The primary METRIC-011 evidence row is missing", call. = FALSE)
}
evidence <- read_plot_source_csv(evidence_path) |>
  dplyr::mutate(
    placement = dplyr::recode(.data$position, glasses = "near_eye"),
    local_date = as.Date(.data$local_date)
  )
if (
  nrow(evidence) != 8L ||
    !all(evidence$metric == l10_id) ||
    !all(evidence$old_value_lx == 4.163336342344337e-17) ||
    !all(evidence$new_value_lx == 0)
) {
  stop("The controlling eight-cell L10 evidence changed", call. = FALSE)
}

manifest_checks <- verify_descriptive_manifests(root)
input_checks <- verify_descriptive_inputs(root)

metric_summary_path <- file.path(
  paths$table_dir,
  "metric_distribution_summary.csv"
)
metric_availability_path <- file.path(
  paths$table_dir,
  "metric_availability.csv"
)
metric_replica_path <- file.path(
  paths$table_dir,
  "metric_descriptive_summary_replica.csv"
)
metric_plot_path <- file.path(paths$source_dir, "metric_plot_values.csv")
source_map_path <- file.path(
  paths$manifest_dir,
  "figure_source_data_map.csv"
)
visual_path <- file.path(paths$audit_dir, "visual_export_comparison.csv")
manifest_checks_path <- file.path(
  paths$audit_dir,
  "shared_manifest_verification.csv"
)
input_checks_path <- file.path(
  paths$audit_dir,
  "prepared_input_provenance.csv"
)

current <- list(
  metric_summary = read_plot_source_csv(metric_summary_path),
  metric_availability = read_plot_source_csv(metric_availability_path),
  metric_replica = read_plot_source_csv(metric_replica_path),
  metric_plot_values = read_plot_source_csv(metric_plot_path)
)

figure_ids <- c(
  "descriptive_overview",
  "near_eye_site_profiles",
  "chest_site_profiles",
  "near_eye_metric_distributions",
  "time_series_to_metrics",
  "latitude_photoperiod_diagnostic"
)
untouched_paths <- c(
  unlist(lapply(
    figure_ids,
    function(figure_id) {
      file.path(
        paths$figure_dir,
        paste0(figure_id, ".", c("png", "jpeg", "pdf", "svg"))
      )
    }
  )),
  file.path(
    root,
    "artifacts",
    "08_diagnostics",
    "descriptives",
    "a4_mockups",
    paste0(figure_ids, "_a4.png")
  ),
  file.path(
    paths$table_dir,
    c(
      "participant_site_characteristics_replica.png",
      "participant_site_characteristics_manuscript_replica.png",
      "recommendation_context_replica.png"
    )
  )
)
if (any(!file.exists(untouched_paths))) {
  stop("An untouched descriptive export is missing", call. = FALSE)
}
untouched_before <- vapply(untouched_paths, artifact_sha256, character(1))

frame_sha256 <- function(data) {
  path <- tempfile(fileext = ".rds")
  on.exit(unlink(path), add = TRUE)
  saveRDS(data, path, version = 3L)
  artifact_sha256(path)
}

normalize_frame <- function(data, key) {
  data |>
    dplyr::mutate(
      dplyr::across(where(is.factor), as.character),
      dplyr::across(dplyr::any_of("local_date"), as.character)
    ) |>
    dplyr::arrange(dplyr::across(dplyr::all_of(key))) |>
    as.data.frame()
}

non_l10_frame <- function(data, key) {
  data |>
    dplyr::filter(.data$metric_id != l10_id) |>
    normalize_frame(key)
}

row_key <- function(data, columns) {
  values <- data[, columns, drop = FALSE]
  values[] <- lapply(values, as.character)
  do.call(paste, c(values, sep = "\r"))
}

replace_fixed_rows <- function(current_data, replacement, key) {
  positions <- which(current_data$metric_id == l10_id)
  if (length(positions) != nrow(replacement)) {
    stop("An L10 summary block has an unexpected size", call. = FALSE)
  }
  order <- match(
    row_key(current_data[positions, , drop = FALSE], key),
    row_key(replacement, key)
  )
  if (anyNA(order)) {
    stop("An L10 summary replacement key is missing", call. = FALSE)
  }
  replacement <- replacement[order, names(current_data), drop = FALSE]
  current_data[positions, ] <- replacement
  current_data
}

# A browser-restricted gt export can stop after the corrected CSVs have been
# written. Reconstruct the verified pre-amendment baseline in memory so a
# resumed run retains the same eight-cell before/after audit without reverting
# any durable output.
evidence_positions <- match(
  row_key(evidence, c("placement", "site", "Id", "local_date")),
  row_key(
    current$metric_plot_values |>
      dplyr::filter(.data$metric_id == l10_id),
    c("placement", "site", "Id", "local_date")
  )
)
if (anyNA(evidence_positions)) {
  stop("An evidence key is absent from the stored L10 source", call. = FALSE)
}
current_l10_positions <- which(current$metric_plot_values$metric_id == l10_id)
stored_evidence_values <- current$metric_plot_values$value[
  current_l10_positions[evidence_positions]
]
if (all(stored_evidence_values == 0)) {
  current$metric_plot_values$value[
    current_l10_positions[evidence_positions]
  ] <- evidence$old_value_lx
  baseline_l10_summary <- build_metric_summary(
    current$metric_plot_values |>
      dplyr::filter(.data$metric_id == l10_id)
  )
  current$metric_summary <- replace_fixed_rows(
    current$metric_summary,
    baseline_l10_summary,
    c("placement", "site")
  )
  baseline_l10_replica <- build_metric_replica(baseline_l10_summary)
  current$metric_replica <- replace_fixed_rows(
    current$metric_replica,
    baseline_l10_replica,
    "site"
  )
} else if (!all(stored_evidence_values == evidence$old_value_lx)) {
  stop("The stored L10 evidence cells are in a mixed state", call. = FALSE)
}

preservation_keys <- list(
  metric_summary = c("placement", "metric_id", "site"),
  metric_replica = c("metric_id", "site"),
  metric_plot_values = c(
    "placement", "metric_id", "site", "Id", "local_date", "value"
  )
)
non_l10_hash_before <- vapply(
  names(preservation_keys),
  function(name) {
    frame_sha256(non_l10_frame(current[[name]], preservation_keys[[name]]))
  },
  character(1)
)

inputs <- load_descriptive_inputs(root)
validate_descriptive_inputs(inputs)
metric_values <- build_metric_values(inputs)
rebuilt_plot_values <- build_metric_plot_values(metric_values)
rebuilt_summary <- build_metric_summary(metric_values)

plot_key <- c("placement", "site", "Id", "local_date", "metric_id")
old_l10_plot <- current$metric_plot_values |>
  dplyr::filter(.data$metric_id == l10_id)
new_l10_plot <- rebuilt_plot_values |>
  dplyr::filter(.data$metric_id == l10_id)
if (
  nrow(old_l10_plot) != 1718L ||
    nrow(new_l10_plot) != 1718L ||
    anyDuplicated(row_key(old_l10_plot, plot_key)) ||
    anyDuplicated(row_key(new_l10_plot, plot_key))
) {
  stop("The L10 participant-day plot domain changed", call. = FALSE)
}
new_order <- match(
  row_key(old_l10_plot, plot_key),
  row_key(new_l10_plot, plot_key)
)
if (anyNA(new_order)) {
  stop("An updated L10 plot key is missing", call. = FALSE)
}
new_l10_plot <- new_l10_plot[new_order, , drop = FALSE]
changed_l10 <- old_l10_plot |>
  dplyr::select(dplyr::all_of(plot_key), old_value = "value") |>
  dplyr::mutate(new_value = new_l10_plot$value) |>
  dplyr::filter(.data$old_value != .data$new_value)
evidence_key <- c("placement", "site", "Id", "local_date")
if (
  nrow(changed_l10) != 8L ||
    !setequal(
      row_key(changed_l10, evidence_key),
      row_key(evidence, evidence_key)
    ) ||
    !all(changed_l10$old_value == 4.163336342344337e-17) ||
    !all(changed_l10$new_value == 0)
) {
  stop("The descriptive L10 delta is not the controlling eight cells", call. = FALSE)
}

updated_plot_values <- current$metric_plot_values
global_positions <- match(
  row_key(changed_l10, plot_key),
  row_key(updated_plot_values, plot_key)
)
replacement_positions <- match(
  row_key(changed_l10, plot_key),
  row_key(new_l10_plot, plot_key)
)
if (anyNA(global_positions) || anyNA(replacement_positions)) {
  stop("An L10 replacement position is missing", call. = FALSE)
}
updated_plot_values$value[global_positions] <-
  new_l10_plot$value[replacement_positions]

new_l10_summary <- rebuilt_summary |>
  dplyr::filter(.data$metric_id == l10_id)
updated_summary <- replace_fixed_rows(
  current$metric_summary,
  new_l10_summary,
  c("placement", "site")
)
rebuilt_replica <- build_metric_replica(updated_summary)
new_l10_replica <- rebuilt_replica |>
  dplyr::filter(.data$metric_id == l10_id)
updated_replica <- replace_fixed_rows(
  current$metric_replica,
  new_l10_replica,
  "site"
)

rebuilt_availability <- rebuilt_summary |>
  dplyr::select(
    "placement",
    "placement_label",
    "site",
    "metric_id",
    "metric_label",
    "analysis_unit",
    "n_participants",
    "n_participant_days",
    "n_observations",
    "n_possible_observations"
  )
if (!isTRUE(all.equal(
  current$metric_availability |>
    dplyr::filter(.data$metric_id == l10_id),
  rebuilt_availability |>
    dplyr::filter(.data$metric_id == l10_id),
  check.attributes = FALSE,
  tolerance = 0
))) {
  stop("Metric support changed during the METRIC-011 refresh", call. = FALSE)
}

updated <- list(
  metric_summary = updated_summary,
  metric_replica = updated_replica,
  metric_plot_values = updated_plot_values
)
non_l10_hash_after <- vapply(
  names(preservation_keys),
  function(name) {
    frame_sha256(non_l10_frame(updated[[name]], preservation_keys[[name]]))
  },
  character(1)
)
if (!identical(non_l10_hash_before, non_l10_hash_after)) {
  stop("A non-L10 descriptive source row changed", call. = FALSE)
}

zero_stats <- function(data, version) {
  l10 <- data |>
    dplyr::filter(.data$metric_id == l10_id)
  summarise_zero <- function(x) {
    x |>
      dplyr::group_by(.data$placement, .data$site) |>
      dplyr::summarise(
        participant_days = dplyr::n(),
        participants = dplyr::n_distinct(.data$Id),
        exact_zero = sum(.data$value == 0, na.rm = TRUE),
        positive_roundoff = sum(
          .data$value > 0 & .data$value < 1e-12,
          na.rm = TRUE
        ),
        .groups = "drop"
      )
  }
  dplyr::bind_rows(
    summarise_zero(l10),
    summarise_zero(dplyr::mutate(l10, site = "Overall"))
  ) |>
    dplyr::mutate(version = version, .before = 1L)
}
zero_before <- zero_stats(current$metric_plot_values, "stored_before")
zero_after <- zero_stats(updated_plot_values, "METRIC-011_after")
zero_effect <- dplyr::full_join(
  zero_before,
  zero_after,
  by = c("placement", "site"),
  suffix = c("_before", "_after")
) |>
  dplyr::mutate(
    exact_zero_delta = .data$exact_zero_after - .data$exact_zero_before,
    positive_roundoff_delta =
      .data$positive_roundoff_after - .data$positive_roundoff_before,
    support_unchanged =
      .data$participant_days_before == .data$participant_days_after &
      .data$participants_before == .data$participants_after,
    status = dplyr::if_else(.data$support_unchanged, "PASS", "FAIL")
  ) |>
  dplyr::arrange(
    match(.data$placement, c("near_eye", "chest")),
    factor(.data$site, levels = c("Overall", descriptive_site_order()))
  )
overall_zero_effect <- zero_effect |>
  dplyr::filter(.data$site == "Overall") |>
  dplyr::arrange(match(.data$placement, c("near_eye", "chest")))
if (
  !identical(overall_zero_effect$exact_zero_before, c(111L, 120L)) ||
    !identical(overall_zero_effect$exact_zero_after, c(114L, 125L)) ||
    !identical(overall_zero_effect$positive_roundoff_after, c(0L, 0L)) ||
    !all(zero_effect$status == "PASS")
) {
  stop("The L10 zero-count effect differs from METRIC-011", call. = FALSE)
}

summary_effect <- dplyr::full_join(
  current$metric_summary |>
    dplyr::filter(.data$metric_id == l10_id) |>
    dplyr::select(
      "placement", "site", "metric_id", dplyr::starts_with("n_"),
      "mean", "sd", "q1", "median", "q3", "mean_display",
      "median_middle_50_display"
    ),
  updated_summary |>
    dplyr::filter(.data$metric_id == l10_id) |>
    dplyr::select(
      "placement", "site", "metric_id", dplyr::starts_with("n_"),
      "mean", "sd", "q1", "median", "q3", "mean_display",
      "median_middle_50_display"
    ),
  by = c("placement", "site", "metric_id"),
  suffix = c("_before", "_after")
) |>
  dplyr::mutate(
    q1_delta = .data$q1_after - .data$q1_before,
    support_unchanged =
      .data$n_possible_observations_before ==
        .data$n_possible_observations_after &
      .data$n_observations_before == .data$n_observations_after &
      .data$n_participants_before == .data$n_participants_after &
      .data$n_participant_days_before == .data$n_participant_days_after,
    display_changed =
      .data$mean_display_before != .data$mean_display_after |
      .data$median_middle_50_display_before !=
        .data$median_middle_50_display_after,
    status = dplyr::if_else(.data$support_unchanged, "PASS", "FAIL")
  ) |>
  dplyr::arrange(
    match(.data$placement, c("near_eye", "chest")),
    factor(.data$site, levels = c("Overall", descriptive_site_order()))
  )
if (
  !all(summary_effect$status == "PASS") ||
    sum(summary_effect$display_changed) != 1L ||
    !identical(
      summary_effect$site[summary_effect$display_changed],
      "KNUST"
    ) ||
    !identical(
      summary_effect$placement[summary_effect$display_changed],
      "chest"
    )
) {
  stop("The L10 summary effect is broader than expected", call. = FALSE)
}

table_effect <- dplyr::full_join(
  current$metric_replica |>
    dplyr::filter(.data$metric_id == l10_id) |>
    dplyr::select(
      "site", "metric_id", "median_formatted", "q1_formatted",
      "q3_formatted", "mean_formatted", "sd_formatted", "display"
    ),
  updated_replica |>
    dplyr::filter(.data$metric_id == l10_id) |>
    dplyr::select(
      "site", "metric_id", "median_formatted", "q1_formatted",
      "q3_formatted", "mean_formatted", "sd_formatted", "display"
    ),
  by = c("site", "metric_id"),
  suffix = c("_before", "_after")
) |>
  dplyr::mutate(
    displayed_values_changed =
      .data$median_formatted_before != .data$median_formatted_after |
      .data$q1_formatted_before != .data$q1_formatted_after |
      .data$q3_formatted_before != .data$q3_formatted_after |
      .data$mean_formatted_before != .data$mean_formatted_after |
      .data$sd_formatted_before != .data$sd_formatted_after |
      .data$display_before != .data$display_after,
    status = dplyr::if_else(
      !.data$displayed_values_changed,
      "PASS_VISIBLE_VALUES_UNCHANGED",
      "DISPLAY_CHANGED"
    )
  )
if (any(table_effect$displayed_values_changed)) {
  stop("A visible near-eye Table 2 L10 value changed", call. = FALSE)
}

symlog <- LightLogR::symlog_trans(base = 10, thr = 1, scale = 1)
metric_contract <- replica_metric_contract()
symlog_audit <- data.frame(
  metric_id = l10_id,
  table_contract_scaling = metric_contract$scaling[
    metric_contract$metric_id == l10_id
  ],
  transform_name = symlog$name,
  base = 10,
  threshold = 1,
  scale = 1,
  exact_zero_before_near_eye = overall_zero_effect$exact_zero_before[
    overall_zero_effect$placement == "near_eye"
  ],
  exact_zero_after_near_eye = overall_zero_effect$exact_zero_after[
    overall_zero_effect$placement == "near_eye"
  ],
  exact_zero_before_chest = overall_zero_effect$exact_zero_before[
    overall_zero_effect$placement == "chest"
  ],
  exact_zero_after_chest = overall_zero_effect$exact_zero_after[
    overall_zero_effect$placement == "chest"
  ],
  status = if (
    identical(
      metric_contract$scaling[metric_contract$metric_id == l10_id],
      "Symlog"
    ) && identical(symlog$name, "symlog-1-10-1")
  ) "PASS" else "FAIL",
  stringsAsFactors = FALSE
)
if (!identical(symlog_audit$status, "PASS")) {
  stop("The approved L10 symlog display rule changed", call. = FALSE)
}

write_descriptive_csv(updated_summary, metric_summary_path)
write_descriptive_csv(updated_replica, metric_replica_path)
write_descriptive_csv(updated_plot_values, metric_plot_path)
write_descriptive_csv(manifest_checks, manifest_checks_path)
write_descriptive_csv(input_checks, input_checks_path)

stored_after <- list(
  metric_summary = read_plot_source_csv(metric_summary_path),
  metric_replica = read_plot_source_csv(metric_replica_path),
  metric_plot_values = read_plot_source_csv(metric_plot_path)
)
stored_non_l10_hash_after <- vapply(
  names(preservation_keys),
  function(name) {
    frame_sha256(non_l10_frame(
      stored_after[[name]],
      preservation_keys[[name]]
    ))
  },
  character(1)
)
if (!identical(non_l10_hash_before, stored_non_l10_hash_after)) {
  stop("CSV serialization changed a non-L10 descriptive row", call. = FALSE)
}
stored_changed <- stored_after$metric_plot_values |>
  dplyr::filter(
    row_key(
      stored_after$metric_plot_values,
      plot_key
    ) %in% row_key(changed_l10, plot_key)
  )
if (nrow(stored_changed) != 8L || !all(stored_changed$value == 0)) {
  stop("The stored L10 source does not contain the eight exact zeros", call. = FALSE)
}

source_map <- read_plot_source_csv(source_map_path)
source_row <- which(
  source_map$figure_id == "near_eye_metric_distributions" &
    basename(source_map$source_data_path) == "metric_plot_values.csv"
)
if (length(source_row) != 1L) {
  stop("The metric source-map row is missing", call. = FALSE)
}
source_map$source_data_sha256[[source_row]] <- artifact_sha256(metric_plot_path)
write_descriptive_csv(source_map, source_map_path)

metric_spec <- publication_table_export_spec() |>
  dplyr::filter(.data$table_id == "near_eye_metric_summary")
metric_table_png <- file.path(paths$table_dir, metric_spec$filename[[1L]])
table_png_before <- artifact_sha256(metric_table_png)
metric_table <- build_metric_publication_gt(
  stored_after$metric_replica,
  stored_after$metric_plot_values
)
gt::gtsave(
  metric_table,
  filename = metric_table_png,
  vwidth = metric_spec$viewport_width_px[[1L]]
)
table_png_after <- artifact_sha256(metric_table_png)
table_dimensions <- read_png_dimensions(metric_table_png)

visual <- read_plot_source_csv(visual_path)
rebuilt_visual <- build_visual_export_comparison(
  paths,
  list(spec = publication_table_export_spec()),
  list(spec = descriptive_figure_spec())
)
old_visual_row <- match("near_eye_metric_summary", visual$output_id)
new_visual_row <- match("near_eye_metric_summary", rebuilt_visual$output_id)
if (is.na(old_visual_row) || is.na(new_visual_row)) {
  stop("The Table 2 visual-comparison row is missing", call. = FALSE)
}
visual[old_visual_row, ] <- rebuilt_visual[
  new_visual_row,
  names(visual),
  drop = FALSE
]
write_descriptive_csv(visual, visual_path)

source_audit <- data.frame(
  artifact = names(controlling_paths),
  path = unname(controlling_paths),
  expected_sha256 = unname(expected_hashes),
  observed_sha256 = unname(observed_hashes),
  status = "PASS",
  base_input_bundle_sha256 = ifelse(
    names(controlling_paths) == "base_manifest",
    base_input_bundle,
    NA_character_
  ),
  stringsAsFactors = FALSE
)
source_audit_path <- file.path(
  paths$audit_dir,
  "l10_metric011_source_provenance.csv"
)
write_descriptive_csv(source_audit, source_audit_path)

changed_cells_path <- file.path(
  paths$audit_dir,
  "l10_metric011_changed_cells.csv"
)
write_descriptive_csv(changed_l10, changed_cells_path)
zero_effect_path <- file.path(
  paths$audit_dir,
  "l10_metric011_zero_count_effect.csv"
)
write_descriptive_csv(zero_effect, zero_effect_path)
summary_effect_path <- file.path(
  paths$audit_dir,
  "l10_metric011_summary_effect.csv"
)
write_descriptive_csv(summary_effect, summary_effect_path)
table_effect_path <- file.path(
  paths$audit_dir,
  "l10_metric011_table_effect.csv"
)
write_descriptive_csv(table_effect, table_effect_path)
symlog_audit_path <- file.path(
  paths$audit_dir,
  "l10_metric011_symlog_display.csv"
)
write_descriptive_csv(symlog_audit, symlog_audit_path)

untouched_after <- vapply(untouched_paths, artifact_sha256, character(1))
if (!identical(untouched_before, untouched_after)) {
  stop("An L10-independent descriptive export changed", call. = FALSE)
}
preservation_audit <- dplyr::bind_rows(
  data.frame(
    artifact_class = "non-L10 source rows",
    path = names(non_l10_hash_before),
    sha256_before = unname(non_l10_hash_before),
    sha256_after = unname(stored_non_l10_hash_after),
    status = "PASS",
    stringsAsFactors = FALSE
  ),
  data.frame(
    artifact_class = "L10-independent reader-facing export",
    path = vapply(
      untouched_paths,
      relative_descriptive_path,
      character(1),
      root = root
    ),
    sha256_before = unname(untouched_before),
    sha256_after = unname(untouched_after),
    status = "PASS",
    stringsAsFactors = FALSE
  )
)
preservation_audit_path <- file.path(
  paths$audit_dir,
  "l10_metric011_non_l10_preservation.csv"
)
write_descriptive_csv(preservation_audit, preservation_audit_path)

refresh_audit <- data.frame(
  check = c(
    "primary L10 cells changed",
    "near-eye exact-zero count",
    "chest exact-zero count",
    "near-eye support",
    "chest support",
    "visible Table 2 values",
    "Table 2 thumbnail transform",
    "Table 2 PNG width",
    "Table 2 PNG height",
    "Table 2 PNG SHA-256 before",
    "Table 2 PNG SHA-256 after",
    "Figure 3 export isolation"
  ),
  observed = c(
    as.character(nrow(changed_l10)),
    as.character(overall_zero_effect$exact_zero_after[
      overall_zero_effect$placement == "near_eye"
    ]),
    as.character(overall_zero_effect$exact_zero_after[
      overall_zero_effect$placement == "chest"
    ]),
    paste0(
      overall_zero_effect$participants_after[
        overall_zero_effect$placement == "near_eye"
      ],
      " participants / ",
      overall_zero_effect$participant_days_after[
        overall_zero_effect$placement == "near_eye"
      ],
      " participant-days"
    ),
    paste0(
      overall_zero_effect$participants_after[
        overall_zero_effect$placement == "chest"
      ],
      " participants / ",
      overall_zero_effect$participant_days_after[
        overall_zero_effect$placement == "chest"
      ],
      " participant-days"
    ),
    "unchanged to three decimal places",
    symlog$name,
    as.character(table_dimensions[["width_px"]]),
    as.character(table_dimensions[["height_px"]]),
    table_png_before,
    table_png_after,
    "all Figure 3 PNG/JPEG/PDF/SVG and A4 hashes unchanged"
  ),
  expected = c(
    "8",
    "114",
    "125",
    "141 participants / 816 participant-days",
    "154 participants / 902 participant-days",
    "unchanged to three decimal places",
    "symlog-1-10-1",
    as.character(table_dimensions[["width_px"]]),
    as.character(table_dimensions[["height_px"]]),
    table_png_before,
    table_png_after,
    "all Figure 3 PNG/JPEG/PDF/SVG and A4 hashes unchanged"
  ),
  status = "PASS",
  stringsAsFactors = FALSE
)
refresh_audit_path <- file.path(
  paths$audit_dir,
  "l10_metric011_refresh_verification.csv"
)
write_descriptive_csv(refresh_audit, refresh_audit_path)

package_names <- c(
  "dplyr", "readr", "gt", "webshot2", "ggridges", "LightLogR"
)
package_audit <- data.frame(
  package = c("R", package_names),
  version = c(
    as.character(getRversion()),
    vapply(
      package_names,
      function(package) as.character(utils::packageVersion(package)),
      character(1)
    )
  ),
  stringsAsFactors = FALSE
)
package_audit_path <- file.path(
  paths$audit_dir,
  "l10_metric011_package_versions.csv"
)
write_descriptive_csv(package_audit, package_audit_path)

manifest_path <- file.path(paths$manifest_dir, "descriptive_artifacts.csv")
manifest <- read_plot_source_csv(manifest_path)

complete_record <- function(record) {
  record$producer <- producer
  record$r_version <- as.character(getRversion())
  for (column in setdiff(names(manifest), names(record))) {
    record[[column]] <- NA
  }
  record[, names(manifest), drop = FALSE]
}

upsert_record <- function(manifest, record) {
  record <- complete_record(record)
  index <- match(record$path[[1L]], manifest$path)
  if (is.na(index)) return(dplyr::bind_rows(manifest, record))
  manifest[index, ] <- record
  manifest
}

csv_records <- list(
  list(metric_summary_path, "descriptive_table_csv", "mixed_or_not_applicable"),
  list(metric_replica_path, "descriptive_table_csv", "mixed_or_not_applicable"),
  list(metric_plot_path, "figure_source_data_csv", "mixed_or_not_applicable"),
  list(source_map_path, "descriptive_figure_source_map", "not_applicable"),
  list(visual_path, "descriptive_visual_comparison", "not_applicable"),
  list(manifest_checks_path, "descriptive_audit_csv", "not_applicable"),
  list(input_checks_path, "descriptive_audit_csv", "not_applicable"),
  list(source_audit_path, "descriptive_l10_refresh_audit", "not_applicable"),
  list(changed_cells_path, "descriptive_l10_refresh_audit", "near_eye_and_chest"),
  list(zero_effect_path, "descriptive_l10_refresh_audit", "near_eye_and_chest"),
  list(summary_effect_path, "descriptive_l10_refresh_audit", "near_eye_and_chest"),
  list(table_effect_path, "descriptive_l10_refresh_audit", "near_eye"),
  list(symlog_audit_path, "descriptive_l10_refresh_audit", "near_eye_and_chest"),
  list(
    preservation_audit_path,
    "descriptive_l10_refresh_audit",
    "mixed_or_not_applicable"
  ),
  list(refresh_audit_path, "descriptive_l10_refresh_audit", "not_applicable"),
  list(package_audit_path, "descriptive_l10_refresh_audit", "not_applicable")
)
for (definition in csv_records) {
  path <- definition[[1L]]
  data <- read_plot_source_csv(path)
  record <- file_artifact_record(
    path,
    root,
    artifact_type = definition[[2L]],
    placement = definition[[3L]]
  )
  record$rows <- nrow(data)
  record$columns <- ncol(data)
  manifest <- upsert_record(manifest, record)
}

table_record <- file_artifact_record(
  metric_table_png,
  root,
  artifact_type = "descriptive_table_png",
  placement = "near_eye",
  source_data = relative_descriptive_path(metric_replica_path, root)
)
table_record$table_id <- "near_eye_metric_summary"
table_record$viewport_width_px <- metric_spec$viewport_width_px[[1L]]
manifest <- upsert_record(manifest, table_record)

write_descriptive_csv(manifest, manifest_path)
stored_manifest <- read_plot_source_csv(manifest_path)
manifest_paths <- file.path(root, stored_manifest$path)
if (
  any(!file.exists(manifest_paths)) ||
    !identical(
      unname(vapply(manifest_paths, artifact_sha256, character(1))),
      stored_manifest$sha256
    )
) {
  stop("The scoped descriptive artifact manifest is stale", call. = FALSE)
}

message(
  "METRIC-011 descriptive refresh completed: 8 L10 cells normalized; ",
  "near-eye zeros 111 -> 114; chest zeros 120 -> 125; ",
  "all non-L10 exports unchanged."
)
