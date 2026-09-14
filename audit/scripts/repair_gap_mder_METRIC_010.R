# Repair and verify gap-timing-unaware MDER from frozen one-minute inputs.

Sys.setenv(TZ = "UTC")
options(stringsAsFactors = FALSE, warn = 2)

root <- normalizePath(".", winslash = "/", mustWork = TRUE)
if (!identical(as.character(getRversion()), "4.6.1")) {
  stop(
    "The gap MDER repair requires R 4.6.1; found ",
    as.character(getRversion()),
    call. = FALSE
  )
}

source("scripts/pipeline/paths_io.R")
source("scripts/pipeline/assertions.R")
source("scripts/pipeline/metric_display_registry.R")
source("scripts/pipeline/time_support.R")
source("scripts/pipeline/manuscript_prepared_data.R")
source("scripts/pipeline/build_manuscript_prepared_data.R")
source("scripts/pipeline/verify_manuscript_prepared_data_artifacts.R")

paths <- manuscript_prepared_output_paths(root, root)
if (!file.exists(paths$rds[["participant_day_metrics"]])) {
  stop("The pre-repair participant-day artifact is missing", call. = FALSE)
}

evidence_root <- file.path(
  root,
  "audit",
  "reconciliation",
  "mder_METRIC-010_gap_repair"
)
dir.create(evidence_root, recursive = TRUE, showWarnings = FALSE)

old_participant_day <- readRDS(paths$rds[["participant_day_metrics"]])
old_manifest_sha256 <- artifact_sha256(paths$manifest)

build_manuscript_prepared_data(root = root, output_root = root)
verification <- verify_manuscript_prepared_data_artifacts(
  root = root,
  output_root = root
)
if (!identical(verification$status, "PASS")) {
  stop("The rebuilt gap-timing-unaware artifacts did not verify", call. = FALSE)
}

new_participant_day <- readRDS(paths$rds[["participant_day_metrics"]])
new_support <- readRDS(paths$rds[["mder_support"]])
new_manifest_sha256 <- artifact_sha256(paths$manifest)

key <- c(
  "scenario_id",
  "model_implementation_id",
  "position",
  "position_role",
  "site",
  "Id",
  "local_date",
  "metric_id"
)
old_non_mder <- dplyr::filter(
  old_participant_day,
  .data$metric_id != manuscript_prepared_mder_metric_id()
)
new_non_mder <- dplyr::filter(
  new_participant_day,
  .data$metric_id != manuscript_prepared_mder_metric_id()
)
manuscript_prepared_assert_identical_frame(
  new_non_mder,
  old_non_mder,
  key,
  "pre/post-repair non-MDER participant-day cells"
)

old_mder <- old_participant_day |>
  dplyr::filter(.data$metric_id == manuscript_prepared_mder_metric_id()) |>
  dplyr::select(dplyr::all_of(key), old_value = "manuscript_prepared_value")
new_mder <- new_participant_day |>
  dplyr::filter(.data$metric_id == manuscript_prepared_mder_metric_id()) |>
  dplyr::select(dplyr::all_of(key), new_value = "manuscript_prepared_value")
mder_comparison <- old_mder |>
  dplyr::full_join(new_mder, by = key, relationship = "one-to-one") |>
  dplyr::left_join(
    dplyr::select(
      new_support,
      dplyr::all_of(key),
      "viable_ratio_minutes",
      "expected_minutes",
      "viable_ratio_fraction",
      "raw_source_rows",
      "observed_local_minutes",
      "duplicated_local_minutes",
      "duplicate_source_rows",
      "estimable",
      "failure_reason"
    ),
    by = key,
    relationship = "one-to-one"
  ) |>
  dplyr::mutate(
    old_finite = is.finite(.data$old_value),
    new_finite = is.finite(.data$new_value),
    finite_value_changed =
      .data$old_finite &
        .data$new_finite &
        .data$old_value != .data$new_value,
    availability_changed = .data$old_finite != .data$new_finite
  ) |>
  dplyr::arrange(.data$position, .data$site, .data$Id, .data$local_date)

mder_summary <- mder_comparison |>
  dplyr::group_by(.data$position) |>
  dplyr::summarise(
    participant_days = dplyr::n(),
    participants = dplyr::n_distinct(.data$site, .data$Id),
    old_estimable_days = sum(.data$old_finite),
    new_estimable_days = sum(.data$new_finite),
    old_finite_new_missing = sum(.data$old_finite & !.data$new_finite),
    old_missing_new_finite = sum(!.data$old_finite & .data$new_finite),
    finite_value_changes = sum(.data$finite_value_changed),
    old_nonpositive_finite = sum(.data$old_finite & .data$old_value <= 0),
    new_nonpositive_finite = sum(.data$new_finite & .data$new_value <= 0),
    old_mean = mean(.data$old_value, na.rm = TRUE),
    new_mean = mean(.data$new_value, na.rm = TRUE),
    old_median = stats::median(.data$old_value, na.rm = TRUE),
    new_median = stats::median(.data$new_value, na.rm = TRUE),
    old_maximum = max(.data$old_value, na.rm = TRUE),
    new_maximum = max(.data$new_value, na.rm = TRUE),
    .groups = "drop"
  )

non_mder_invariance <- data.frame(
  check = c(
    "non_mder_rows_before",
    "non_mder_rows_after",
    "non_mder_cells_exactly_unchanged",
    "shared_independent_verifier_status",
    "construct_impossible_zero_repaired"
  ),
  value = c(
    nrow(old_non_mder),
    nrow(new_non_mder),
    TRUE,
    verification$status,
    verification$mder_impossible_zero_repaired
  ),
  stringsAsFactors = FALSE
)

support_summary <- new_support |>
  dplyr::group_by(.data$position, .data$failure_reason, .drop = FALSE) |>
  dplyr::summarise(
    participant_days = dplyr::n(),
    participants = dplyr::n_distinct(.data$site, .data$Id),
    viable_minutes_minimum = min(.data$viable_ratio_minutes),
    viable_minutes_median = stats::median(.data$viable_ratio_minutes),
    viable_minutes_maximum = max(.data$viable_ratio_minutes),
    .groups = "drop"
  ) |>
  dplyr::arrange(.data$position, .data$failure_reason)

input_output_hashes <- data.frame(
  artifact = c(
    "decision",
    "preprocessed_glasses_2",
    "preprocessed_chest_2",
    "pre_repair_manifest",
    "post_repair_manifest",
    "post_repair_participant_day_rds",
    "post_repair_mder_support_rds"
  ),
  path = c(
    "audit/decisions/mder_mean_of_viable_ratios.md",
    "data/preprocessed_glasses_2.RData",
    "data/preprocessed_chest_2.RData",
    "artifacts/12_manifests/manuscript_prepared_data_artifacts.csv",
    "artifacts/12_manifests/manuscript_prepared_data_artifacts.csv",
    manuscript_prepared_relative_path(
      paths$rds[["participant_day_metrics"]],
      paths
    ),
    manuscript_prepared_relative_path(paths$rds[["mder_support"]], paths)
  ),
  phase = c(
    "input",
    "input",
    "input",
    "before",
    "after",
    "after",
    "after"
  ),
  sha256 = c(
    artifact_sha256(file.path(
      root,
      "audit/decisions/mder_mean_of_viable_ratios.md"
    )),
    artifact_sha256(file.path(root, "data/preprocessed_glasses_2.RData")),
    artifact_sha256(file.path(root, "data/preprocessed_chest_2.RData")),
    old_manifest_sha256,
    new_manifest_sha256,
    artifact_sha256(paths$rds[["participant_day_metrics"]]),
    artifact_sha256(paths$rds[["mder_support"]])
  ),
  stringsAsFactors = FALSE
)

output_paths <- c(
  gap_mder_value_comparison = file.path(
    evidence_root,
    "gap_mder_value_comparison.csv"
  ),
  gap_mder_summary = file.path(evidence_root, "gap_mder_summary.csv"),
  gap_non_mder_invariance = file.path(
    evidence_root,
    "gap_non_mder_invariance.csv"
  ),
  gap_mder_support_summary = file.path(
    evidence_root,
    "gap_mder_support_summary.csv"
  ),
  gap_repair_input_output_hashes = file.path(
    evidence_root,
    "gap_repair_input_output_hashes.csv"
  )
)
utils::write.csv(
  mder_comparison,
  output_paths[["gap_mder_value_comparison"]],
  row.names = FALSE,
  na = ""
)
utils::write.csv(
  mder_summary,
  output_paths[["gap_mder_summary"]],
  row.names = FALSE,
  na = ""
)
utils::write.csv(
  non_mder_invariance,
  output_paths[["gap_non_mder_invariance"]],
  row.names = FALSE,
  na = ""
)
utils::write.csv(
  support_summary,
  output_paths[["gap_mder_support_summary"]],
  row.names = FALSE,
  na = ""
)
utils::write.csv(
  input_output_hashes,
  output_paths[["gap_repair_input_output_hashes"]],
  row.names = FALSE,
  na = ""
)

evidence_manifest <- data.frame(
  artifact = names(output_paths),
  path = sub(paste0("^", root, "/?"), "", output_paths),
  sha256 = vapply(output_paths, artifact_sha256, character(1L)),
  bytes = as.numeric(file.info(output_paths)$size),
  producer = "audit/scripts/repair_gap_mder_METRIC_010.R",
  r_version = as.character(getRversion()),
  dplyr_version = as.character(utils::packageVersion("dplyr")),
  tidyr_version = as.character(utils::packageVersion("tidyr")),
  status = "PASS",
  stringsAsFactors = FALSE
)
manifest_path <- file.path(evidence_root, "gap_repair_evidence_manifest.csv")
utils::write.csv(
  evidence_manifest,
  manifest_path,
  row.names = FALSE,
  na = ""
)

message(
  "Gap-timing-unaware METRIC-010 repair PASS; artifact manifest SHA-256 ",
  new_manifest_sha256,
  "; evidence manifest SHA-256 ",
  artifact_sha256(manifest_path)
)
