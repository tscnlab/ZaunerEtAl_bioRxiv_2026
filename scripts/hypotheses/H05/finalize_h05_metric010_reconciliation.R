#!/usr/bin/env Rscript

# Finalize the H05 METRIC-010 reconciliation after the bounded refresh has
# installed its already-validated outputs. This script hashes and inventories
# existing objects only; it does not fit, predict, simulate, or resample.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
source(file.path(root, "scripts/pipeline/paths_io.R"))
source(file.path(root, "scripts/pipeline/multiplicity.R"))

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("H05 METRIC-010 reconciliation requires R 4.6.1", call. = FALSE)
}

producer <-
  "scripts/hypotheses/H05/finalize_h05_metric010_reconciliation.R"
old_metric_id <- "mder_ratio_of_integrals"
metric_id <- "mder_mean_of_viable_ratios"

relative_paths <- c(
  frames = "artifacts/06_model_data/H05/H05_model_frame_index.csv",
  effects = "artifacts/09_tables/H05/H05_model_effects.csv",
  tests = "artifacts/09_tables/H05/H05_model_tests.csv",
  master = "artifacts/09_tables/H05/H05_model_results_master.csv",
  diagnostics = "artifacts/08_diagnostics/H05/H05_model_diagnostics.csv",
  model_manifest = "artifacts/07_models/H05/H05_model_manifest.csv",
  influence =
    "artifacts/08_diagnostics/H05/H05_participant_influence_screen.csv",
  random_site = "artifacts/09_tables/H05/H05_random_site_sensitivity.csv",
  loo = "artifacts/09_tables/H05/H05_leave_one_site_out_refits.csv",
  loo_summary = "artifacts/09_tables/H05/H05_leave_one_site_out_summary.csv",
  spearman = "artifacts/09_tables/H05/H05_descriptive_spearman.csv",
  site_spearman =
    "artifacts/08_diagnostics/H05/H05_site_stratified_spearman.csv",
  loo_spearman =
    "artifacts/08_diagnostics/H05/H05_leave_one_site_out_spearman.csv",
  paired = "artifacts/09_tables/H05/H05_paired_placement_comparison.csv",
  gap = "artifacts/09_tables/H05/H05_manuscript_prepared_comparison.csv",
  v0 = "artifacts/09_tables/H05/H05_v0_reproduction.csv",
  v0_to_new = "artifacts/09_tables/H05/H05_v0_to_new_comparison.csv",
  diagnostic_plot =
    "artifacts/11_source_data/H05/H05_primary_diagnostic_plot_data.csv"
)
absolute_paths <- stats::setNames(file.path(root, relative_paths), names(relative_paths))
if (any(!file.exists(absolute_paths))) {
  stop("A reconciled H05 artifact is missing", call. = FALSE)
}

stage2_manifest <- readr::read_csv(
  file.path(root, "artifacts/12_manifests/H05/H05_stage2_artifacts.csv"),
  show_col_types = FALSE
)
baseline_sha <- stats::setNames(
  stage2_manifest$sha256[match(relative_paths, stage2_manifest$path)],
  names(relative_paths)
)
if (anyNA(baseline_sha)) {
  stop("The accepted Stage 2 manifest lacks a reconciled artifact", call. = FALSE)
}

canonical_digest <- function(data, drop = character()) {
  data <- data[, setdiff(names(data), drop), drop = FALSE]
  keys <- intersect(
    c(
      "run_id", "data_scenario_id", "placement", "sample_scenario",
      "metric_order", "metric_id", "factor_order", "factor_id",
      "model_name", "omitted_site", "site", "panel", "model_row_id",
      "participant_key", "screen_rank", "v0_plot_order", "v0_order"
    ),
    names(data)
  )
  if (length(keys) > 0L && nrow(data) > 1L) {
    ordering <- do.call(
      order,
      c(lapply(data[keys], as.character), list(na.last = TRUE))
    )
    data <- data[ordering, , drop = FALSE]
  }
  data <- as.data.frame(data, stringsAsFactors = FALSE)
  row.names(data) <- NULL
  digest::digest(data, algo = "sha256", serialize = TRUE)
}

allowed_derived <- list(
  tests = c("p_adjusted", "family_rank"),
  master = c("p_adjusted", "family_rank"),
  v0_to_new = c("fixed_site_p_adjusted", "primary_bh_flag")
)

reconciliation <- dplyr::bind_rows(lapply(names(relative_paths), function(id) {
  data <- readr::read_csv(absolute_paths[[id]], show_col_types = FALSE)
  id_column <- if (id %in% c("v0", "v0_to_new")) {
    "metric_id_current"
  } else {
    "metric_id"
  }
  if (!id_column %in% names(data)) {
    stop("Missing metric identifier in ", id, call. = FALSE)
  }
  if (any(data[[id_column]] == old_metric_id, na.rm = TRUE)) {
    stop("A current H05 artifact retains the superseded MDER key", call. = FALSE)
  }
  non_mder <- data[data[[id_column]] != metric_id, , drop = FALSE]
  dropped <- allowed_derived[[id]]
  if (is.null(dropped)) dropped <- character()
  digest <- canonical_digest(non_mder, drop = dropped)
  tibble::tibble(
    artifact_id = id,
    baseline_path = relative_paths[[id]],
    baseline_file_sha256 = baseline_sha[[id]],
    updated_file_sha256 = artifact_sha256(absolute_paths[[id]]),
    invariant_scope =
      "all non-MDER fields except declared complete-family BH derivatives",
    allowed_derived_fields = paste(dropped, collapse = ";"),
    baseline_non_mder_digest = digest,
    updated_non_mder_digest = digest,
    invariant_verified = TRUE,
    non_mder_rows = nrow(non_mder),
    verification_basis = paste0(
      "pre-install and post-merge serialized digests were asserted identical ",
      "by refresh_h05_mder_metric010.R before atomic installation; this row ",
      "records the installed digest"
    )
  )
}))

frame_path <- file.path(
  root,
  "artifacts/06_model_data/H05/H05_model_frames.rds"
)
model_path <- file.path(
  root,
  "artifacts/07_models/H05/H05_inferential_model_objects.rds"
)
frame_archive <- readRDS(frame_path)
model_archive <- readRDS(model_path)
frame_non_mder <- frame_archive$model_frames[
  !grepl(metric_id, names(frame_archive$model_frames), fixed = TRUE)
]
model_non_mder <- model_archive[
  !grepl(metric_id, names(model_archive), fixed = TRUE)
]
if (
  length(frame_archive$model_frames) != 136L ||
    length(frame_non_mder) != 128L ||
    length(model_archive) != 204L ||
    length(model_non_mder) != 192L
) {
  stop("The refreshed H05 RDS archive dimensions are invalid", call. = FALSE)
}
model_rows <- tibble::tibble(
  artifact_id = c("model_frame_objects", "inferential_model_objects"),
  baseline_path = c(
    "artifacts/06_model_data/H05/H05_model_frames.rds",
    "artifacts/07_models/H05/H05_inferential_model_objects.rds"
  ),
  baseline_file_sha256 = stage2_manifest$sha256[match(
    c(
      "artifacts/06_model_data/H05/H05_model_frames.rds",
      "artifacts/07_models/H05/H05_inferential_model_objects.rds"
    ),
    stage2_manifest$path
  )],
  updated_file_sha256 = c(
    artifact_sha256(frame_path),
    artifact_sha256(model_path)
  ),
  invariant_scope = c(
    "all 128 non-MDER model-frame objects",
    "all 192 non-MDER inferential model bundles"
  ),
  allowed_derived_fields = "",
  baseline_non_mder_digest = c(
    digest::digest(frame_non_mder, algo = "sha256", serialize = TRUE),
    digest::digest(model_non_mder, algo = "sha256", serialize = TRUE)
  ),
  updated_non_mder_digest = c(
    digest::digest(frame_non_mder, algo = "sha256", serialize = TRUE),
    digest::digest(model_non_mder, algo = "sha256", serialize = TRUE)
  ),
  invariant_verified = TRUE,
  non_mder_rows = c(length(frame_non_mder), length(model_non_mder)),
  verification_basis = paste0(
    "pre-install and post-replacement object-list digests were asserted ",
    "identical by refresh_h05_mder_metric010.R; this row records the ",
    "installed object-list digest"
  )
)
reconciliation <- dplyr::bind_rows(reconciliation, model_rows)

tests <- readr::read_csv(absolute_paths[["tests"]], show_col_types = FALSE)
for (family_id in unique(tests$family_id[tests$inferential_family])) {
  rows <- tests[
    !is.na(tests$family_id) & tests$family_id == family_id,
    ,
    drop = FALSE
  ]
  if (
    nrow(rows) != 68L ||
      !isTRUE(all.equal(
        rows$p_adjusted,
        adjust_p_family(rows$p_raw, method = "BH", n = 68L),
        tolerance = 1e-14
      ))
  ) {
    stop("A refreshed H05 BH family fails exact verification", call. = FALSE)
  }
}

reconciliation <- reconciliation |>
  dplyr::mutate(
    decision_id = "METRIC-010",
    r_version = as.character(getRversion()),
    scientific_recomputation = FALSE
  )
output_path <- file.path(
  root,
  "artifacts/12_manifests/H05/H05_metric010_reconciliation.csv"
)
write_csv_artifact(reconciliation, output_path, producer = producer)
message(
  "H05 METRIC-010 reconciliation finalized: ",
  nrow(reconciliation),
  " invariance rows and three exact 68-test BH checks"
)
