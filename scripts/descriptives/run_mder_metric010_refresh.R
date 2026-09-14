# Scoped descriptives refresh for the controlling METRIC-010 MDER amendment.
#
# This script consumes the repaired gap-timing-unaware MDER artifacts and
# replaces only MDER rows in descriptive sources and displays. It does not fit
# a model or rebuild any non-MDER scientific result.

options(warn = 2)

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
source(file.path(root, "scripts", "descriptives", "build_descriptives.R"))
source_descriptive_modules(root)
check_descriptive_packages()
paths <- descriptive_paths(root)

producer <- "scripts/descriptives/run_mder_metric010_refresh.R"
mder_id <- "mder_mean_of_viable_ratios"
mder_ids <- c(mder_id, "mder_ratio_of_integrals")

expected_hashes <- c(
  decision = "1664347de976057807fcb5ac6e24bd4b66af1fe32378fabd1f2acafcfc9266de",
  metric_manifest = "028bce108339c1277df4a070597430ea20b49c34c2888f4eef42741c1fe76a5e",
  independent_audit = "5bd34fd4ac26dc2761540393d40e096cde835d8dd4b4edda9253243c9083d4bb",
  base_manifest = "8344bdc0339a53079bf9eeb7d86de1ad7c15373641c3a0a5a01d040b418895ce",
  site_context_manifest = "c0c6d7f97782c0d880a213050f576213f5d56b3204a02732f6399e7e4aeb8518",
  preanalysis_manifest = "f3c4bfbf120d2023c045b44e3c7c04c58bce1f8d11621956bca1e5ede90c5623",
  gap_manifest = "4ed62fbe58de65a6d05d8cfc6b5d870d7c74a3c83fe89bcd72bd1dd838698935",
  gap_participant_day = "7561b5dd47cb5e23ca94ba59bd57648f11fe492f86af53a566c5c9cf42d932f1",
  gap_mder_support = "a0bc5d7ea2142709412da2253158086416ddb730b0f60ff616bba9d6ccb1edc5",
  gap_repair_evidence = "81e3aa9439b88cf239d6669dc4343cfb146cd2f45790bae412ab837156315018",
  renv_lock = "3bf99c633fb123626eb14d29f0847b91f71030c92e90331fe401e3204bca8350"
)
controlling_paths <- c(
  decision = "audit/decisions/mder_mean_of_viable_ratios.md",
  metric_manifest = "artifacts/12_manifests/metric_artifacts.csv",
  independent_audit = "artifacts/08_diagnostics/mder_METRIC-010/audit_manifest.csv",
  base_manifest = "artifacts/12_manifests/base_model_data_artifacts.csv",
  site_context_manifest = "artifacts/12_manifests/site_solar_context_artifacts.csv",
  preanalysis_manifest = "artifacts/12_manifests/preanalysis_comparison_artifacts.csv",
  gap_manifest = "artifacts/12_manifests/manuscript_prepared_data_artifacts.csv",
  gap_participant_day = paste0(
    "artifacts/06_model_data/scenarios/manuscript_prepared_data/",
    "participant_day_metrics.rds"
  ),
  gap_mder_support = paste0(
    "artifacts/06_model_data/scenarios/manuscript_prepared_data/",
    "mder_support.rds"
  ),
  gap_repair_evidence = paste0(
    "audit/reconciliation/mder_METRIC-010_gap_repair/",
    "gap_repair_evidence_manifest.csv"
  ),
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
  stop("A controlling METRIC-010 or environment hash changed", call. = FALSE)
}

base_manifest <- read_plot_source_csv(
  file.path(root, controlling_paths[["base_manifest"]])
)
base_input_bundle <- unique(base_manifest$input_bundle_sha256)
if (
  !identical(
    base_input_bundle,
    "e840ce9d2a7f653bc5ebbfe020ce087017dfdaf0276df09da578bda30a539916"
  )
) {
  stop("The controlling base input bundle changed", call. = FALSE)
}
if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("The scoped MDER refresh requires R 4.6.1", call. = FALSE)
}

manifest_checks <- verify_descriptive_manifests(root)
input_checks <- verify_descriptive_inputs(root)
manifest_checks_path <- file.path(
  paths$audit_dir,
  "shared_manifest_verification.csv"
)
input_checks_path <- file.path(
  paths$audit_dir,
  "prepared_input_provenance.csv"
)
write_descriptive_csv(manifest_checks, manifest_checks_path)
write_descriptive_csv(input_checks, input_checks_path)

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
alt_text_path <- file.path(paths$source_dir, "figure_alt_text.csv")
previous_table2_path <- file.path(
  paths$audit_dir,
  "previous_table2_comparison.csv"
)

current <- list(
  metric_summary = read_plot_source_csv(metric_summary_path),
  metric_availability = read_plot_source_csv(metric_availability_path),
  metric_replica = read_plot_source_csv(metric_replica_path),
  metric_plot_values = read_plot_source_csv(metric_plot_path),
  alt_text = read_plot_source_csv(alt_text_path),
  previous_table2 = read_plot_source_csv(previous_table2_path)
)

untouched_figure_ids <- c(
  "descriptive_overview",
  "near_eye_site_profiles",
  "chest_site_profiles",
  "time_series_to_metrics",
  "latitude_photoperiod_diagnostic"
)
untouched_paths <- c(
  unlist(lapply(
    untouched_figure_ids,
    function(figure_id)
      file.path(
        paths$figure_dir,
        paste0(figure_id, ".", c("png", "jpeg", "pdf", "svg"))
      )
  )),
  file.path(
    paths$root,
    "artifacts",
    "08_diagnostics",
    "descriptives",
    "a4_mockups",
    paste0(untouched_figure_ids, "_a4.png")
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

inputs <- load_descriptive_inputs(root)
validate_descriptive_inputs(inputs)
metric_values <- build_metric_values(inputs)
rebuilt_summary <- build_metric_summary(metric_values)
rebuilt_replica <- build_metric_replica(rebuilt_summary)
rebuilt_plot_values <- build_metric_plot_values(metric_values)

mder_support <- metric_values |>
  dplyr::filter(
    .data$metric_id == .env$mder_id,
    .data$finite,
    is.finite(.data$value)
  ) |>
  dplyr::group_by(.data$placement) |>
  dplyr::summarise(
    participants = dplyr::n_distinct(.data$Id),
    participant_days = dplyr::n(),
    mean = mean(.data$value),
    median = stats::median(.data$value),
    .groups = "drop"
  ) |>
  dplyr::arrange(match(.data$placement, c("near_eye", "chest")))
if (
  !identical(mder_support$participants, c(137L, 152L)) ||
    !identical(mder_support$participant_days, c(687L, 723L)) ||
    max(abs(mder_support$mean - c(0.7242573, 0.7567377))) > 5e-8 ||
    max(abs(mder_support$median - c(0.7238676, 0.7495175))) > 5e-8
) {
  stop("MDER support or distribution differs from METRIC-010", call. = FALSE)
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

non_mder_frame <- function(data, key) {
  data |>
    dplyr::filter(!.data$metric_id %in% .env$mder_ids) |>
    normalize_frame(key)
}

frame_sha256 <- function(data) {
  path <- tempfile(fileext = ".rds")
  on.exit(unlink(path), add = TRUE)
  saveRDS(data, path, version = 3L)
  artifact_sha256(path)
}

replace_fixed_mder_rows <- function(current_data, replacement, key) {
  positions <- which(current_data$metric_id %in% mder_ids)
  if (!length(positions) || length(positions) != nrow(replacement)) {
    stop("A fixed MDER block has an unexpected size", call. = FALSE)
  }
  current_keys <- do.call(
    paste,
    c(current_data[positions, key, drop = FALSE], sep = "\r")
  )
  replacement_keys <- do.call(
    paste,
    c(replacement[key], sep = "\r")
  )
  order <- match(current_keys, replacement_keys)
  if (anyNA(order)) {
    stop("A fixed MDER replacement key is missing", call. = FALSE)
  }
  replacement <- replacement[order, names(current_data), drop = FALSE]
  current_data[positions, ] <- replacement
  current_data
}

replace_plot_mder_rows <- function(current_data, replacement) {
  placement_order <- unique(current_data$placement)
  result <- lapply(placement_order, function(placement) {
    block <- current_data[current_data$placement == placement, , drop = FALSE]
    positions <- which(block$metric_id %in% mder_ids)
    new_block <- replacement |>
      dplyr::filter(.data$placement == .env$placement) |>
      dplyr::select(dplyr::all_of(names(block)))
    if (!length(positions) || !nrow(new_block)) {
      stop("A placement-specific MDER plot block is missing", call. = FALSE)
    }
    first <- min(positions)
    last <- max(positions)
    before <- if (first > 1L) block[seq_len(first - 1L), , drop = FALSE] else
      block[0, , drop = FALSE]
    after <- if (last < nrow(block)) {
      block[seq.int(last + 1L, nrow(block)), , drop = FALSE]
    } else {
      block[0, , drop = FALSE]
    }
    dplyr::bind_rows(before, new_block, after)
  })
  dplyr::bind_rows(result)
}

new_mder_summary <- rebuilt_summary |>
  dplyr::filter(.data$metric_id == .env$mder_id)
new_mder_availability <- new_mder_summary |>
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
new_mder_replica <- rebuilt_replica |>
  dplyr::filter(.data$metric_id == .env$mder_id)
new_mder_plot_values <- rebuilt_plot_values |>
  dplyr::filter(.data$metric_id == .env$mder_id)

updated <- list(
  metric_summary = replace_fixed_mder_rows(
    current$metric_summary,
    new_mder_summary,
    c("placement", "site")
  ),
  metric_availability = replace_fixed_mder_rows(
    current$metric_availability,
    new_mder_availability,
    c("placement", "site")
  ),
  metric_replica = replace_fixed_mder_rows(
    current$metric_replica,
    new_mder_replica,
    "site"
  ),
  metric_plot_values = replace_plot_mder_rows(
    current$metric_plot_values,
    new_mder_plot_values
  )
)

preservation_keys <- list(
  metric_summary = c("placement", "metric_id", "site"),
  metric_availability = c("placement", "metric_id", "site"),
  metric_replica = c("metric_id", "site"),
  metric_plot_values = c("placement", "metric_id", "site", "Id", "local_date")
)
non_mder_hash_before <- vapply(
  names(preservation_keys),
  function(name) {
    frame_sha256(non_mder_frame(current[[name]], preservation_keys[[name]]))
  },
  character(1)
)
non_mder_hash_after <- vapply(
  names(preservation_keys),
  function(name) {
    frame_sha256(non_mder_frame(updated[[name]], preservation_keys[[name]]))
  },
  character(1)
)
if (!identical(non_mder_hash_before, non_mder_hash_after)) {
  stop("A non-MDER descriptive source row changed", call. = FALSE)
}

updated_alt_text <- current$alt_text
alt_row <- match(
  "near_eye_metric_distributions",
  updated_alt_text$figure_id
)
if (is.na(alt_row)) {
  stop("The metric-distribution alt-text row is missing", call. = FALSE)
}
updated_alt_text$long_description[[alt_row]] <- paste(
  "Rows within each panel are the nine named sites. Ridges and white boxes",
  "show finite distributions and middle 50% intervals for duration,",
  "regularity, dose, level, spectrum, and circular timing metrics. Sample",
  "sizes vary by verified metric support; the overall table contains 17",
  "registered near-eye metrics with explicit participants, participant-days,",
  "and observations. For MDER, each daily value is the arithmetic mean of",
  "viable one-minute melEDI/photopic-illuminance ratios. Both channels must",
  "be finite and strictly positive, and at least 720 of the complete 1,440",
  "local wall-clock minutes are required (inclusive 50% rule)."
)

previous_render_table2 <- read_plot_source_csv(file.path(
  paths$audit_dir,
  "previous_render_table_2.csv"
))
rebuilt_previous_table2 <- build_previous_table2_comparison(
  previous_render_table2,
  updated$metric_replica
)
updated_previous_table2 <- replace_fixed_mder_rows(
  current$previous_table2,
  rebuilt_previous_table2 |>
    dplyr::filter(.data$metric_id == .env$mder_id),
  "site"
)
if (
  !identical(
    frame_sha256(non_mder_frame(
      current$previous_table2,
      c("metric_id", "site")
    )),
    frame_sha256(non_mder_frame(
      updated_previous_table2,
      c("metric_id", "site")
    ))
  )
) {
  stop("A non-MDER Table 2 comparison row changed", call. = FALSE)
}

write_descriptive_csv(updated$metric_summary, metric_summary_path)
write_descriptive_csv(updated$metric_availability, metric_availability_path)
write_descriptive_csv(updated$metric_replica, metric_replica_path)
write_descriptive_csv(updated$metric_plot_values, metric_plot_path)
write_descriptive_csv(updated_alt_text, alt_text_path)
write_descriptive_csv(updated_previous_table2, previous_table2_path)

stored_after <- list(
  metric_summary = read_plot_source_csv(metric_summary_path),
  metric_availability = read_plot_source_csv(metric_availability_path),
  metric_replica = read_plot_source_csv(metric_replica_path),
  metric_plot_values = read_plot_source_csv(metric_plot_path)
)
stored_non_mder_hash_after <- vapply(
  names(preservation_keys),
  function(name) {
    frame_sha256(non_mder_frame(
      stored_after[[name]],
      preservation_keys[[name]]
    ))
  },
  character(1)
)
if (!identical(non_mder_hash_before, stored_non_mder_hash_after)) {
  stop("CSV serialization changed a non-MDER descriptive value", call. = FALSE)
}

metric_table <- build_metric_publication_gt(
  stored_after$metric_replica,
  stored_after$metric_plot_values
)
metric_spec <- publication_table_export_spec() |>
  dplyr::filter(.data$table_id == "near_eye_metric_summary")
metric_table_png <- file.path(paths$table_dir, metric_spec$filename[[1L]])
gt::gtsave(
  metric_table,
  filename = metric_table_png,
  vwidth = metric_spec$viewport_width_px[[1L]]
)

figure_build <- build_and_save_descriptive_figures(
  paths,
  figure_ids = "near_eye_metric_distributions"
)

qa_path <- file.path(paths$audit_dir, "figure_readability_qa.csv")
qa <- read_plot_source_csv(qa_path)
qa_row <- match("near_eye_metric_distributions", qa$figure_id)
new_qa <- figure_build$qa |>
  dplyr::filter(.data$figure_id == "near_eye_metric_distributions")
if (is.na(qa_row) || nrow(new_qa) != 1L) {
  stop("The Figure 3 readability-QA row is missing", call. = FALSE)
}
qa[qa_row, ] <- new_qa[, names(qa), drop = FALSE]
write_descriptive_csv(qa, qa_path)

source_map_path <- file.path(
  paths$manifest_dir,
  "figure_source_data_map.csv"
)
source_map <- read_plot_source_csv(source_map_path)
source_row <- which(
  source_map$figure_id == "near_eye_metric_distributions" &
    basename(source_map$source_data_path) == "metric_plot_values.csv"
)
if (length(source_row) != 1L) {
  stop("The Figure 3 source-map row is missing", call. = FALSE)
}
source_map$source_data_sha256[[source_row]] <- artifact_sha256(metric_plot_path)
write_descriptive_csv(source_map, source_map_path)

visual_path <- file.path(paths$audit_dir, "visual_export_comparison.csv")
visual <- read_plot_source_csv(visual_path)
rebuilt_visual <- build_visual_export_comparison(
  paths,
  list(spec = publication_table_export_spec()),
  figure_build
)
for (output_id in c(
  "near_eye_metric_summary",
  "near_eye_metric_distributions"
)) {
  old_row <- match(output_id, visual$output_id)
  new_row <- match(output_id, rebuilt_visual$output_id)
  if (is.na(old_row) || is.na(new_row)) {
    stop("A refreshed visual-comparison row is missing", call. = FALSE)
  }
  visual[old_row, ] <- rebuilt_visual[new_row, names(visual), drop = FALSE]
}
write_descriptive_csv(visual, visual_path)

support_audit <- mder_support |>
  dplyr::mutate(
    source_scenario = "repaired_gap_timing_unaware",
    expected_participants = c(137L, 152L),
    expected_participant_days = c(687L, 723L),
    total_gap_candidate_participant_days = c(811L, 897L),
    primary_main_participant_days = c(816L, 902L),
    expected_mean = c(0.7242573, 0.7567377),
    expected_median = c(0.7238676, 0.7495175),
    viable_minute_threshold = 720L,
    full_wall_clock_minutes = 1440L,
    threshold_inclusive = TRUE,
    status = "PASS",
    .after = "placement"
  ) |>
  dplyr::rename(
    observed_participants = "participants",
    observed_participant_days = "participant_days",
    observed_mean = "mean",
    observed_median = "median"
  )
support_audit_path <- file.path(
  paths$audit_dir,
  "mder_metric010_refresh_verification.csv"
)
write_descriptive_csv(support_audit, support_audit_path)

source_audit <- data.frame(
  artifact = names(controlling_paths),
  path = unname(controlling_paths),
  expected_sha256 = unname(expected_hashes),
  observed_sha256 = unname(observed_hashes),
  status = "PASS",
  stringsAsFactors = FALSE
)
source_audit$base_input_bundle_sha256 <- ifelse(
  source_audit$artifact == "base_manifest",
  base_input_bundle,
  NA_character_
)
source_audit_path <- file.path(
  paths$audit_dir,
  "mder_metric010_source_provenance.csv"
)
write_descriptive_csv(source_audit, source_audit_path)

untouched_after <- vapply(untouched_paths, artifact_sha256, character(1))
if (!identical(untouched_before, untouched_after)) {
  stop("A non-MDER descriptive export changed", call. = FALSE)
}
preservation_audit <- dplyr::bind_rows(
  data.frame(
    artifact_class = "non-MDER source rows",
    path = names(non_mder_hash_before),
    sha256_before = unname(non_mder_hash_before),
    sha256_after = unname(stored_non_mder_hash_after),
    status = "PASS",
    stringsAsFactors = FALSE
  ),
  data.frame(
    artifact_class = "untouched reader-facing export",
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
  "mder_metric010_non_mder_preservation.csv"
)
write_descriptive_csv(preservation_audit, preservation_audit_path)

package_names <- c(
  "dplyr",
  "readr",
  "ggplot2",
  "ggridges",
  "gt",
  "webshot2",
  "ragg",
  "svglite",
  "LightLogR"
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
  "mder_metric010_package_versions.csv"
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
  if (is.na(index)) {
    return(dplyr::bind_rows(manifest, record))
  }
  manifest[index, ] <- record
  manifest
}

csv_records <- list(
  list(metric_summary_path, "descriptive_table_csv", "mixed_or_not_applicable"),
  list(
    metric_availability_path,
    "descriptive_table_csv",
    "mixed_or_not_applicable"
  ),
  list(metric_replica_path, "descriptive_table_csv", "mixed_or_not_applicable"),
  list(metric_plot_path, "figure_source_data_csv", "mixed_or_not_applicable"),
  list(alt_text_path, "figure_source_data_csv", "mixed_or_not_applicable"),
  list(
    previous_table2_path,
    "descriptive_audit_csv",
    "mixed_or_not_applicable"
  ),
  list(manifest_checks_path, "descriptive_audit_csv", "not_applicable"),
  list(input_checks_path, "descriptive_audit_csv", "not_applicable"),
  list(qa_path, "descriptive_figure_readability_qa", "not_applicable"),
  list(visual_path, "descriptive_visual_comparison", "not_applicable"),
  list(
    support_audit_path,
    "descriptive_mder_refresh_audit",
    "mixed_or_not_applicable"
  ),
  list(source_audit_path, "descriptive_mder_refresh_audit", "not_applicable"),
  list(
    preservation_audit_path,
    "descriptive_mder_refresh_audit",
    "not_applicable"
  ),
  list(package_audit_path, "descriptive_mder_refresh_audit", "not_applicable")
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

figure_records <- figure_build$records
figure_records$producer <- producer
for (index in seq_len(nrow(figure_records))) {
  manifest <- upsert_record(manifest, figure_records[index, , drop = FALSE])
}

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
  "METRIC-010 descriptive refresh completed: near-eye 137 participants / ",
  "687 days; chest 152 participants / 723 days."
)
