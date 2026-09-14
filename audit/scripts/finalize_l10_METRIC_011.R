# Finalize the shared METRIC-011 numerical-zero normalization and rebuild only
# prepared-data artifacts that inherit the primary L10 mean. This script does
# not fit or refit a hypothesis model.

Sys.setenv(TZ = "UTC")
options(stringsAsFactors = FALSE, warn = 2)

root <- normalizePath(".", winslash = "/", mustWork = TRUE)
if (!identical(as.character(getRversion()), "4.6.1")) {
  stop(
    "METRIC-011 finalization requires R 4.6.1; found ",
    as.character(getRversion()),
    call. = FALSE
  )
}

source("scripts/pipeline/paths_io.R")
source("scripts/pipeline/assertions.R")
source("scripts/pipeline/metric_display_registry.R")
source("scripts/pipeline/state_alignment.R")
source("scripts/pipeline/time_axes.R")
source("scripts/pipeline/time_support.R")
source("scripts/pipeline/reference_profiles.R")
source("scripts/pipeline/state_interval_projection.R")
source("scripts/pipeline/metric_derivation.R")
source("scripts/pipeline/verify_metric_derivation_core.R")
source("scripts/pipeline/verify_metric_derivation_mder.R")

source("scripts/pipeline/site_solar_context.R")
source("scripts/pipeline/build_site_solar_context.R")
source("scripts/pipeline/verify_site_solar_context_artifacts.R")

source("scripts/pipeline/base_model_data.R")
source("scripts/pipeline/build_base_model_data.R")
source("scripts/pipeline/verify_base_model_data_artifacts.R")

source("scripts/pipeline/h01_model_data.R")
source("scripts/pipeline/build_h01_model_data.R")
source("scripts/pipeline/verify_h01_model_data_artifacts.R")

source("scripts/pipeline/manuscript_prepared_data.R")
source("scripts/pipeline/build_manuscript_prepared_data.R")
source("scripts/pipeline/verify_manuscript_prepared_data_artifacts.R")
source("scripts/pipeline/h01_manuscript_prepared_adapter.R")
source("scripts/pipeline/build_h01_manuscript_prepared_data.R")
source("scripts/pipeline/verify_h01_manuscript_prepared_data_artifacts.R")

source("scripts/pipeline/preanalysis_comparison.R")
source("scripts/pipeline/build_preanalysis_comparison.R")
source("scripts/pipeline/verify_preanalysis_comparison_artifacts.R")

producer <- "audit/scripts/finalize_l10_METRIC_011.R"
audit_root <- file.path(root, "audit", "reconciliation", "l10_METRIC-011")
dir.create(audit_root, recursive = TRUE, showWarnings = FALSE)

snapshot_path <- file.path(root, "tmp", "l10_METRIC011_before_snapshot.rds")
if (!file.exists(snapshot_path)) {
  abort_pipeline("METRIC-011 pre-rebuild snapshot is missing")
}
snapshot <- readRDS(snapshot_path)

relative_path <- function(path) {
  sub(paste0("^", root, "/?"), "", normalizePath(
    path,
    winslash = "/",
    mustWork = TRUE
  ))
}

strip_frame_attributes <- function(data) {
  retained <- attributes(data)[c("names", "row.names", "class")]
  attributes(data) <- retained
  data
}

same_scientific_object <- function(old, new) {
  if (is.data.frame(old) && is.data.frame(new)) {
    old <- strip_frame_attributes(old)
    new <- strip_frame_attributes(new)
  }
  identical(old, new)
}

same_vector <- function(observed, expected) {
  if (inherits(observed, "POSIXt") && inherits(expected, "POSIXt")) {
    observed <- as.numeric(observed)
    expected <- as.numeric(expected)
  }
  if (inherits(observed, "Date") && inherits(expected, "Date")) {
    observed <- as.numeric(observed)
    expected <- as.numeric(expected)
  }
  if (is.numeric(observed) && is.numeric(expected)) {
    return(
      length(observed) == length(expected) &&
        all(
          (is.na(observed) & is.na(expected)) |
            (!is.na(observed) & !is.na(expected) & observed == expected)
        )
    )
  }
  identical(observed, expected)
}

assert_frame_except <- function(old, new, except, object) {
  old <- strip_frame_attributes(old)
  new <- strip_frame_attributes(new)
  if (!identical(names(old), names(new)) || nrow(old) != nrow(new)) {
    abort_pipeline("%s changed dimensions or columns", object)
  }
  checked <- setdiff(names(old), except)
  changed <- checked[!vapply(
    checked,
    function(column) same_vector(old[[column]], new[[column]]),
    logical(1L)
  )]
  if (length(changed) > 0L) {
    abort_pipeline(
      "%s changed outside the allowed field(s): %s",
      object,
      paste(changed, collapse = ", ")
    )
  }
  invisible(TRUE)
}

target_key_columns <- c("position", "site", "Id", "local_date")
target_cells <- tibble::tribble(
  ~position, ~site, ~Id, ~local_date, ~source_valid_minutes,
  "glasses", "KNUST", "KNUST_S001", as.Date("2024-10-13"), 600L,
  "glasses", "KNUST", "KNUST_S005", as.Date("2024-11-08"), 600L,
  "glasses", "KNUST", "KNUST_S010", as.Date("2024-12-14"), 600L,
  "chest", "FUSPCEU", "FUSPCEU_S019", as.Date("2024-12-12"), 600L,
  "chest", "KNUST", "KNUST_S001", as.Date("2024-10-13"), 600L,
  "chest", "KNUST", "KNUST_S002", as.Date("2024-10-19"), 547L,
  "chest", "KNUST", "KNUST_S009", as.Date("2024-12-07"), 600L,
  "chest", "KNUST", "KNUST_S011", as.Date("2024-12-22"), 600L
) |>
  dplyr::arrange(.data$position, .data$site, .data$Id, .data$local_date)

message("Independently verifying the rebuilt primary metrics")
core_verification <- verify_metric_derivation_core(
  root = root,
  sample_days_per_placement = 48L
)
mder_verification <- verify_metric_derivation_mder(root = root)
stopifnot(
  identical(core_verification$status, "PASS"),
  identical(mder_verification$status, "PASS")
)

metric_audit_paths <- c(
  chest = file.path(
    root,
    "artifacts/05_metrics/metrics_chest_numerical_zero_audit.csv"
  ),
  glasses = file.path(
    root,
    "artifacts/05_metrics/metrics_glasses_numerical_zero_audit.csv"
  )
)
numerical_zero_audit <- purrr::imap_dfr(
  metric_audit_paths,
  function(path, placement) {
    readr::read_csv(path, show_col_types = FALSE, progress = FALSE) |>
      dplyr::mutate(
        position = as.character(.data$position),
        local_date = as.Date(.data$local_date),
        audit_placement = placement
      )
  }
)
if (
  nrow(numerical_zero_audit) == 0L ||
    any(numerical_zero_audit$position != numerical_zero_audit$audit_placement) ||
    any(numerical_zero_audit$numerical_zero_decision_id != "METRIC-011") ||
    any(numerical_zero_audit$normalized_value_lx != 0) ||
    any(!numerical_zero_audit$raw_value_preserved)
) {
  abort_pipeline("Canonical numerical-zero audit violates METRIC-011")
}

positive_reclassifications <- numerical_zero_audit |>
  dplyr::filter(.data$raw_backtransformed_value_lx > 0) |>
  dplyr::arrange(.data$position, .data$site, .data$Id, .data$local_date)
observed_targets <- positive_reclassifications |>
  dplyr::select(dplyr::all_of(target_key_columns))
expected_targets <- target_cells |>
  dplyr::select(dplyr::all_of(target_key_columns))
if (
  nrow(positive_reclassifications) != nrow(target_cells) ||
    !identical(observed_targets, expected_targets) ||
    any(positive_reclassifications$metric != "l10_mean_medi") ||
    any(positive_reclassifications$analysis_unit != "participant_day_window") ||
    any(!positive_reclassifications$source_all_zero) ||
    any(
      positive_reclassifications$source_valid_minutes !=
        target_cells$source_valid_minutes
    ) ||
    any(
      positive_reclassifications$source_zero_minutes !=
        positive_reclassifications$source_valid_minutes
    ) ||
    any(positive_reclassifications$source_positive_minutes != 0L) ||
    any(
      positive_reclassifications$source_valid_minutes +
        positive_reclassifications$source_missing_minutes != 600L
    ) ||
    any(positive_reclassifications$source_real_minutes != 600L) ||
    any(
      positive_reclassifications$source_valid_real_minutes !=
        positive_reclassifications$source_valid_minutes
    ) ||
    any(
      abs(positive_reclassifications$raw_backtransformed_value_lx) >
        positive_reclassifications$numerical_zero_tolerance_lx
    )
) {
  abort_pipeline(
    "Positive METRIC-011 reclassifications differ from the eight source-proven zeros"
  )
}

metric_change_rows <- purrr::map_dfr(c("chest", "glasses"), function(position) {
  path <- file.path(
    root,
    "artifacts/05_metrics",
    paste0("metrics_", position, "_participant_day.rds")
  )
  relative <- relative_path(path)
  old <- snapshot$objects[[relative]]
  new <- readRDS(path)
  assert_frame_except(
    old,
    new,
    except = "l10_mean_medi_lx",
    object = paste0(position, " participant-day metrics")
  )
  changed <- which(
    !(
      (is.na(old$l10_mean_medi_lx) & is.na(new$l10_mean_medi_lx)) |
        (!is.na(old$l10_mean_medi_lx) &
          !is.na(new$l10_mean_medi_lx) &
          old$l10_mean_medi_lx == new$l10_mean_medi_lx)
    )
  )
  tibble::tibble(
    position = as.character(new$position[changed]),
    site = as.character(new$site[changed]),
    Id = as.character(new$Id[changed]),
    local_date = as.Date(new$local_date[changed]),
    metric = "l10_mean_medi",
    old_value_lx = old$l10_mean_medi_lx[changed],
    new_value_lx = new$l10_mean_medi_lx[changed]
  )
}) |>
  dplyr::arrange(.data$position, .data$site, .data$Id, .data$local_date)
if (
  nrow(metric_change_rows) != nrow(target_cells) ||
    !identical(
      metric_change_rows |>
        dplyr::select(dplyr::all_of(target_key_columns)),
      target_cells |>
        dplyr::select(dplyr::all_of(target_key_columns))
    ) ||
    any(metric_change_rows$old_value_lx <= 0) ||
    any(metric_change_rows$new_value_lx != 0)
) {
  abort_pipeline("Primary metric changes are not exactly the eight approved L10 cells")
}

unchanged_metric_rds <- c(
  "artifacts/05_metrics/metrics_chest_30_minute.rds",
  "artifacts/05_metrics/metrics_glasses_30_minute.rds",
  "artifacts/05_metrics/metrics_chest_one_hour.rds",
  "artifacts/05_metrics/metrics_glasses_one_hour.rds",
  "artifacts/05_metrics/metrics_chest_participant.rds",
  "artifacts/05_metrics/metrics_glasses_participant.rds"
)
for (relative in unchanged_metric_rds) {
  if (!identical(
    strip_frame_attributes(snapshot$objects[[relative]]),
    strip_frame_attributes(readRDS(file.path(root, relative)))
  )) {
    abort_pipeline("Scientific values changed unexpectedly in %s", relative)
  }
}

supplemental_dates <- c(
  manuscript_prepared_participant_day = file.path(
    root,
    "artifacts/06_model_data/scenarios/manuscript_prepared_data/participant_day_metrics.rds"
  )
)

message("Repinning site/daylight context without changing its values")
site_build <- build_site_solar_context_artifacts(
  root = root,
  supplemental_date_paths = supplemental_dates,
  input_root = root
)
site_verification <- verify_site_solar_context_artifacts(
  root = root,
  supplemental_date_paths = supplemental_dates,
  input_root = root
)
stopifnot(identical(site_verification$status, "PASS"))
site_relative <- "artifacts/06_model_data/context/site_solar_context.rds"
if (!identical(
  strip_frame_attributes(snapshot$objects[[site_relative]]),
  strip_frame_attributes(readRDS(file.path(root, site_relative)))
)) {
  abort_pipeline("Site/daylight context values changed during the METRIC-011 repin")
}

message("Rebuilding and verifying shared base-model data")
base_build <- build_base_model_data_artifacts(root = root, output_root = root)
base_verification <- verify_base_model_data_artifacts(
  root = root,
  output_root = root
)
stopifnot(
  identical(base_build$status, "PASS"),
  identical(base_verification$status, "PASS")
)

base_daily_paths <- c(
  "artifacts/06_model_data/base/metrics_glasses_participant_day_context.rds",
  "artifacts/06_model_data/base/metrics_chest_participant_day_context.rds",
  "artifacts/06_model_data/base/metrics_glasses_participant_day_enriched.rds",
  "artifacts/06_model_data/base/metrics_chest_participant_day_enriched.rds"
)
for (relative in base_daily_paths) {
  assert_frame_except(
    snapshot$objects[[relative]],
    readRDS(file.path(root, relative)),
    except = "l10_mean_medi_lx",
    object = relative
  )
}
unchanged_base_paths <- setdiff(
  names(snapshot$objects)[startsWith(
    names(snapshot$objects),
    "artifacts/06_model_data/base/"
  )],
  base_daily_paths
)
for (relative in unchanged_base_paths) {
  if (!identical(
    strip_frame_attributes(snapshot$objects[[relative]]),
    strip_frame_attributes(readRDS(file.path(root, relative)))
  )) {
    abort_pipeline("Scientific values changed unexpectedly in %s", relative)
  }
}

message("Rebuilding H01 prepared inputs without fitting models")
h01_build <- build_h01_model_data_artifacts(root = root, output_root = root)
h01_verification <- verify_h01_model_data_artifacts(
  root = root,
  output_root = root
)
stopifnot(
  identical(h01_build$status, "PASS_WITH_DECLARED_UNAVAILABLE_SCENARIO"),
  identical(
    h01_verification$status,
    "PASS_WITH_DECLARED_UNAVAILABLE_SCENARIO"
  )
)

h01_relative <- "artifacts/06_model_data/H01.rds"
old_h01 <- snapshot$objects[[h01_relative]]
new_h01 <- readRDS(file.path(root, h01_relative))
for (component in setdiff(
  names(old_h01),
  c("model_rows", "input_provenance", "metadata")
)) {
  if (!same_scientific_object(old_h01[[component]], new_h01[[component]])) {
    abort_pipeline("H01 component `%s` changed unexpectedly", component)
  }
}
assert_frame_except(
  old_h01$model_rows,
  new_h01$model_rows,
  except = "value",
  object = "H01 model rows"
)
h01_changed <- which(
  !(
    (is.na(old_h01$model_rows$value) & is.na(new_h01$model_rows$value)) |
      (!is.na(old_h01$model_rows$value) &
        !is.na(new_h01$model_rows$value) &
        old_h01$model_rows$value == new_h01$model_rows$value)
  )
)
if (
  length(h01_changed) == 0L ||
    any(new_h01$model_rows$metric_id[h01_changed] != "l10_mean_medi")
) {
  abort_pipeline("H01 changed values are not confined to L10 mean")
}

message("Repinning the H01 gap-timing-unaware adapter without changing values")
h01_gap_build <- build_h01_manuscript_prepared_data_artifacts(
  root = root,
  output_root = root
)
h01_gap_verification <- verify_h01_manuscript_prepared_data_artifacts(
  root = root,
  output_root = root
)
expected_gap_status <- paste0(
  "PASS_WITH_DECLARED_UNAVAILABLE_SUPPORT_",
  "AND_PAIRED_PARTICIPANT_METRICS"
)
stopifnot(
  identical(h01_gap_build$status, expected_gap_status),
  identical(h01_gap_verification$status, expected_gap_status)
)
gap_rds_relatives <- names(snapshot$objects)[startsWith(
  names(snapshot$objects),
  "artifacts/06_model_data/H01/scenarios/manuscript_prepared_data/"
)]
for (relative in gap_rds_relatives) {
  old <- snapshot$objects[[relative]]
  new <- readRDS(file.path(root, relative))
  if (is.list(old) && !is.data.frame(old)) {
    for (component in setdiff(
      names(old),
      c("input_provenance", "metadata")
    )) {
      if (!same_scientific_object(old[[component]], new[[component]])) {
        abort_pipeline(
          "Gap-timing-unaware H01 component `%s` changed unexpectedly",
          component
        )
      }
    }
  } else {
    if (is.data.frame(old) && is.data.frame(new)) {
      old <- strip_frame_attributes(old)
      new <- strip_frame_attributes(new)
    }
    if (!identical(old, new)) {
      abort_pipeline(
        "Gap-timing-unaware H01 scientific values changed in %s",
        relative
      )
    }
  }
}

normalization_manifest <- file.path(
  root,
  "artifacts/12_manifests/model_input_normalization.csv"
)
base_manifest <- file.path(
  root,
  "artifacts/12_manifests/base_model_data_artifacts.csv"
)
message("Rebuilding the descriptive pre-analysis comparison")
preanalysis_build <- build_preanalysis_comparison_artifacts(
  root = root,
  output_root = root,
  expected_normalization_manifest_sha256 = artifact_sha256(
    normalization_manifest
  ),
  expected_base_manifest_sha256 = artifact_sha256(base_manifest)
)
preanalysis_verification <- verify_preanalysis_comparison_artifacts(
  root = root,
  output_root = root,
  expected_normalization_manifest_sha256 = artifact_sha256(
    normalization_manifest
  ),
  expected_base_manifest_sha256 = artifact_sha256(base_manifest)
)
stopifnot(
  identical(preanalysis_build$status, "PASS"),
  identical(preanalysis_verification$status, "PASS")
)

manifest_paths <- c(
  metric = "artifacts/12_manifests/metric_artifacts.csv",
  manuscript_prepared =
    "artifacts/12_manifests/manuscript_prepared_data_artifacts.csv",
  site = "artifacts/12_manifests/site_solar_context_artifacts.csv",
  base = "artifacts/12_manifests/base_model_data_artifacts.csv",
  h01 = "artifacts/12_manifests/H01_model_data_artifacts.csv",
  h01_gap =
    "artifacts/12_manifests/H01_manuscript_prepared_data_artifacts.csv",
  preanalysis =
    "artifacts/12_manifests/preanalysis_comparison_artifacts.csv",
  normalization = "artifacts/12_manifests/model_input_normalization.csv"
)
manifest_transition <- tibble::tibble(
  artifact = names(manifest_paths),
  path = unname(manifest_paths),
  sha256_before = unname(snapshot$manifest_hashes[names(manifest_paths)]),
  sha256_after = vapply(
    file.path(root, manifest_paths),
    artifact_sha256,
    character(1L)
  )
) |>
  dplyr::mutate(changed = .data$sha256_before != .data$sha256_after)

invariance_summary <- tibble::tribble(
  ~check, ~status, ~detail,
  "primary_participant_day_cells", "PASS",
  "Exactly eight L10 mean values changed from positive roundoff to zero",
  "primary_non_L10_metrics", "PASS",
  "Every non-L10 participant-day field is exactly unchanged",
  "primary_30_minute_hourly_participant_outputs", "PASS",
  "All RDS scientific values are exactly unchanged",
  "site_daylight_context", "PASS",
  "All context values are exactly unchanged; provenance was repinned",
  "base_model_data", "PASS",
  "Only the inherited eight L10 mean values changed in daily frames",
  "H01_primary_prepared_data", "PASS",
  "Only L10 mean model-row values changed; no sample or contract changed",
  "H01_gap_timing_unaware_data", "PASS",
  "Scientific values are exactly unchanged; provenance was repinned",
  "hypothesis_models", "NOT_RUN",
  "No hypothesis model was fitted or refitted by this script"
)

package_versions <- tibble::tibble(
  package = c("R", "dplyr", "readr", "tibble", "openssl"),
  version = c(
    as.character(getRversion()),
    as.character(utils::packageVersion("dplyr")),
    as.character(utils::packageVersion("readr")),
    as.character(utils::packageVersion("tibble")),
    as.character(utils::packageVersion("openssl"))
  )
)

output_data <- list(
  all_numerical_zero_reclassifications = numerical_zero_audit,
  positive_roundoff_reclassifications = positive_reclassifications,
  primary_scientific_cell_changes = metric_change_rows,
  manifest_transition = manifest_transition,
  invariance_summary = invariance_summary,
  package_versions = package_versions
)
output_paths <- purrr::imap(output_data, function(data, name) {
  path <- file.path(audit_root, paste0(name, ".csv"))
  readr::write_csv(data, path, na = "")
  path
})

commands_path <- file.path(audit_root, "commands.txt")
writeLines(
  c(
    paste(
      "env R_PROFILE_USER=/dev/null",
      "R_LIBS_USER=<project-renv-library>",
      "NATHEALTH_PROJECT_ROOT=<project-root>",
      "Rscript scripts/pipeline/build_metric_derivation.R"
    ),
    paste(
      "env R_PROFILE_USER=/dev/null",
      "R_LIBS_USER=<project-renv-library>",
      "Rscript audit/scripts/finalize_l10_METRIC_011.R"
    )
  ),
  commands_path
)
output_paths$commands <- commands_path

evidence_manifest <- tibble::tibble(
  artifact = names(output_paths),
  path = vapply(output_paths, relative_path, character(1L)),
  sha256 = vapply(output_paths, artifact_sha256, character(1L)),
  bytes = as.numeric(file.info(unlist(output_paths))$size),
  producer = producer,
  r_version = as.character(getRversion()),
  status = "PASS"
)
evidence_manifest_path <- file.path(
  audit_root,
  "METRIC-011_evidence_manifest.csv"
)
readr::write_csv(evidence_manifest, evidence_manifest_path, na = "")

message(
  "METRIC-011 finalization PASS; evidence manifest SHA-256: ",
  artifact_sha256(evidence_manifest_path)
)
