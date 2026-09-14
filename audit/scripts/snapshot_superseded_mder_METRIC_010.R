# Preserve the superseded ratio-of-integrals MDER values before METRIC-010.
#
# This script is intentionally read-only with respect to Preparation 04. It
# writes a namespaced audit snapshot under artifacts/08_diagnostics so the
# value and sample changes caused by METRIC-010 remain exactly reproducible.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)

source(file.path(root, "scripts/pipeline/paths_io.R"))
source(file.path(root, "scripts/pipeline/assertions.R"))

paths <- pipeline_paths(root)
manifest_path <- file.path(paths$manifests, "metric_artifacts.csv")
settings_path <- file.path(paths$metrics, "metric_derivation_settings.csv")
manifest <- readr::read_csv(
  manifest_path,
  show_col_types = FALSE,
  progress = FALSE
)
settings <- readr::read_csv(
  settings_path,
  show_col_types = FALSE,
  progress = FALSE
)

assert_columns(
  settings,
  c(
    "placement", "mder_support_decision_id", "mder_ratio_definition",
    "mder_support_cutoff"
  ),
  object = "superseded Preparation 04 settings"
)
if (
  !all(settings$mder_support_decision_id == "METRIC-003") ||
    !all(
      settings$mder_ratio_definition ==
        "ratio_of_observed_paired_integrals"
    )
) {
  abort_pipeline(
    paste0(
      "The current Preparation 04 artifacts are not the superseded ",
      "METRIC-003 ratio-of-integrals run; refusing to overwrite the snapshot"
    )
  )
}

output_root <- file.path(
  paths$diagnostics,
  "mder_METRIC-010",
  "superseded_METRIC-003"
)
dir.create(output_root, recursive = TRUE, showWarnings = FALSE)

placements <- sort(unique(as.character(settings$placement)))
snapshot_rows <- lapply(placements, function(placement) {
  input_path <- file.path(
    paths$metrics,
    paste0("metrics_", placement, "_participant_day.rds")
  )
  data <- readRDS(input_path)
  mder_columns <- names(data)[grepl("^mder($|_)", names(data))]
  assert_columns(
    data,
    c("site", "Id", "position", "local_date", "mder", mder_columns),
    object = paste0(placement, " superseded MDER data")
  )
  selected <- data |>
    dplyr::select(
      dplyr::all_of(c(
        "site", "Id", "position", "local_date", mder_columns
      ))
    ) |>
    dplyr::arrange(
      .data$site,
      .data$Id,
      .data$position,
      .data$local_date
    )
  output_path <- file.path(
    output_root,
    paste0("mder_ratio_of_integrals_", placement, ".csv")
  )
  readr::write_csv(selected, output_path, na = "")
  tibble::tibble(
    placement = placement,
    path = normalizePath(output_path, winslash = "/", mustWork = TRUE),
    sha256 = artifact_sha256(output_path),
    bytes = unname(file.info(output_path)$size),
    participant_days = nrow(selected),
    participants = dplyr::n_distinct(selected$Id),
    estimable_mder_days = sum(is.finite(selected$mder)),
    missing_mder_days = sum(!is.finite(selected$mder)),
    mder_mean = mean(selected$mder, na.rm = TRUE),
    mder_median = stats::median(selected$mder, na.rm = TRUE),
    mder_min = min(selected$mder, na.rm = TRUE),
    mder_max = max(selected$mder, na.rm = TRUE)
  )
})

snapshot_manifest <- dplyr::bind_rows(snapshot_rows) |>
  dplyr::mutate(
    superseded_decision_id = "METRIC-003",
    superseding_decision_id = "METRIC-010",
    source_metric_manifest_path = normalizePath(
      manifest_path,
      winslash = "/",
      mustWork = TRUE
    ),
    source_metric_manifest_sha256 = artifact_sha256(manifest_path),
    source_settings_sha256 = artifact_sha256(settings_path),
    snapshot_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
    r_version = paste(R.version$major, R.version$minor, sep = ".")
  )

snapshot_manifest_path <- file.path(output_root, "snapshot_manifest.csv")
readr::write_csv(snapshot_manifest, snapshot_manifest_path, na = "")
cat(
  normalizePath(snapshot_manifest_path, winslash = "/", mustWork = TRUE),
  "\n",
  artifact_sha256(snapshot_manifest_path),
  "\n",
  sep = ""
)
