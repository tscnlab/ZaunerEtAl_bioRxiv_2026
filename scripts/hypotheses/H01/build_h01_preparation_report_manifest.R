#!/usr/bin/env Rscript

# Record the source and rendered identities for the H01 preparation report.
# This script performs no scientific calculation.

suppressPackageStartupMessages({
  library(dplyr)
  library(tibble)
})

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
source(file.path(root, "scripts/pipeline/paths_io.R"))
source(file.path(root, "scripts/hypotheses/H01/h01_contract.R"))

if (!identical(as.character(getRversion()), "4.6.1")) {
  h01_abort("H01 requires R 4.6.1; running %s", getRversion())
}

producer <- paste0(
  "scripts/hypotheses/H01/",
  "build_h01_preparation_report_manifest.R"
)
output_path <- file.path(
  root,
  "artifacts/12_manifests/H01/H01_preparation_report_manifest.csv"
)

script_files <- list.files(
  file.path(root, "scripts/hypotheses/H01"),
  pattern = "\\.R$",
  full.names = TRUE
)
flat_manifest_files <- list.files(
  file.path(root, "artifacts/12_manifests"),
  pattern = "^H01.*\\.csv$",
  full.names = TRUE
)
worker_manifest_path <- file.path(
  root,
  "artifacts/12_manifests/H01_worker_artifacts.csv"
)
flat_manifest_files <- setdiff(
  flat_manifest_files,
  c(output_path, worker_manifest_path)
)

preparation_asset_dir <- file.path(
  root,
  paste0(
    "_build/nathealth/audit/hypotheses/H01/",
    "H01_analysis_preparation_files"
  )
)
preparation_asset_files <- if (dir.exists(preparation_asset_dir)) {
  list.files(
    preparation_asset_dir,
    recursive = TRUE,
    full.names = TRUE,
    include.dirs = FALSE
  )
} else {
  character()
}

preparation_source_files <- list.files(
  file.path(root, "artifacts/11_source_data/H01/preparation"),
  pattern = "\\.csv$",
  full.names = TRUE
)

authoring_qmd <- file.path(
  root,
  "audit/hypotheses/H01/H01_analysis_preparation.qmd"
)
build_qmd <- file.path(
  root,
  paste0(
    "_build/nathealth/audit/hypotheses/H01/",
    "H01_analysis_preparation.qmd"
  )
)
if (
  !file_test("-f", authoring_qmd) ||
    nzchar(Sys.readlink(authoring_qmd)) ||
    !file_test("-f", build_qmd) ||
    nzchar(Sys.readlink(build_qmd))
) {
  h01_abort("H01 preparation QMD paths must be regular non-symlink files")
}

authoring_qmd_sha256 <- artifact_sha256(authoring_qmd)
authoring_qmd_bytes <- unname(file.info(authoring_qmd)$size)
authoring_qmd_mode <- as.character(file.info(authoring_qmd)$mode)
qmd_copied <- file.copy(
  from = authoring_qmd,
  to = build_qmd,
  overwrite = TRUE,
  copy.mode = TRUE
)
if (
  !isTRUE(qmd_copied) ||
    !identical(artifact_sha256(authoring_qmd), authoring_qmd_sha256) ||
    !identical(unname(file.info(authoring_qmd)$size), authoring_qmd_bytes) ||
    !file_test("-f", build_qmd) ||
    nzchar(Sys.readlink(build_qmd)) ||
    !identical(artifact_sha256(build_qmd), authoring_qmd_sha256) ||
    !identical(unname(file.info(build_qmd)$size), authoring_qmd_bytes) ||
    !identical(as.character(file.info(build_qmd)$mode), authoring_qmd_mode)
) {
  h01_abort("Could not synchronize the H01 preparation QMD exactly")
}

download_dir <- file.path(preparation_asset_dir, "source-data")
dir.create(download_dir, recursive = TRUE, showWarnings = FALSE)
download_files <- file.path(download_dir, basename(preparation_source_files))
copied <- file.copy(
  from = preparation_source_files,
  to = download_files,
  overwrite = TRUE,
  copy.mode = TRUE
)
if (
  !all(copied) ||
    !identical(
      unname(vapply(preparation_source_files, artifact_sha256, character(1))),
      unname(vapply(download_files, artifact_sha256, character(1)))
    )
) {
  h01_abort("Could not create byte-identical H01 source-data downloads")
}

preparation_asset_files <- list.files(
  preparation_asset_dir,
  recursive = TRUE,
  full.names = TRUE,
  include.dirs = FALSE
)

files <- unique(c(
  file.path(root, "_quarto-nathealth.yml"),
  file.path(root, "audit/hypotheses/H01/H01_analysis_preparation.qmd"),
  file.path(
    root,
    paste0(
      "_build/nathealth/audit/hypotheses/H01/",
      "H01_analysis_preparation.html"
    )
  ),
  file.path(
    root,
    paste0(
      "_build/nathealth/audit/hypotheses/H01/",
      "H01_analysis_preparation.qmd"
    )
  ),
  file.path(root, "notebooks/hypotheses/H01.qmd"),
  file.path(root, "_build/nathealth/notebooks/hypotheses/H01.html"),
  file.path(root, "config/site_display_registry.csv"),
  file.path(root, "renv.lock"),
  file.path(root, "scripts/pipeline/paths_io.R"),
  file.path(root, "scripts/pipeline/p_value_display.R"),
  file.path(
    root,
    "scripts/pipeline/hypothesis_preparation_provenance_contract.R"
  ),
  file.path(root, "artifacts/06_model_data/H01/model_rows.csv"),
  file.path(root, "artifacts/06_model_data/H01/sample_flow.csv"),
  file.path(root, "artifacts/06_model_data/H01/exclusion_reasons.csv"),
  file.path(root, "artifacts/06_model_data/H01/metric_contract.csv"),
  file.path(root, "artifacts/08_diagnostics/H01/H01_model_diagnostics.csv"),
  file.path(root, "artifacts/08_diagnostics/H01/H01_r2_bootstrap_audit.csv"),
  file.path(
    root,
    paste0(
      "audit/hypotheses/H01/l10_METRIC-011/bootstrap_production/",
      "H01_METRIC-011_bootstrap_production_manifest.csv"
    )
  ),
  file.path(
    root,
    paste0(
      "audit/hypotheses/H01/l10_METRIC-011/production_integration/reporting/",
      "H01_METRIC-011_reporting_integration_manifest.csv"
    )
  ),
  file.path(root, "audit/decisions/mder_mean_of_viable_ratios.md"),
  file.path(
    root,
    paste0(
      "audit/hypotheses/H01/mder_METRIC-010/bootstrap_production/",
      "H01_METRIC-010_bootstrap_production_manifest.csv"
    )
  ),
  file.path(
    root,
    paste0(
      "audit/hypotheses/H01/mder_METRIC-010/production_integration/",
      "H01_METRIC-010_production_integration_manifest.csv"
    )
  ),
  file.path(
    root,
    paste0(
      "audit/hypotheses/H01/mder_METRIC-010/production_integration/",
      "H01_METRIC-010_production_integration_summary.csv"
    )
  ),
  file.path(root, "artifacts/09_tables/H01/H01_exact_samples_by_site.csv"),
  file.path(
    root,
    "artifacts/09_tables/H01/stage3/H01_stage3_exact_samples.csv"
  ),
  file.path(
    root,
    "artifacts/09_tables/H01/stage3/H01_stage3_formula_manifest.csv"
  ),
  preparation_source_files,
  preparation_asset_files,
  script_files,
  flat_manifest_files
))

if (any(!file.exists(files))) {
  missing <- files[!file.exists(files)]
  h01_abort(
    "Missing H01 preparation-report provenance file(s): %s",
    paste(missing, collapse = ", ")
  )
}

relative <- sub(
  paste0(
    "^",
    gsub("([][{}()+*^$|\\\\?.])", "\\\\\\1", root),
    "/"
  ),
  "",
  normalizePath(files, winslash = "/", mustWork = TRUE)
)

role <- dplyr::case_when(
  relative == "audit/hypotheses/H01/H01_analysis_preparation.qmd" ~
    "preparation_source",
  relative == paste0(
    "_build/nathealth/audit/hypotheses/H01/",
    "H01_analysis_preparation.html"
  ) ~ "preparation_render",
  relative == paste0(
    "_build/nathealth/audit/hypotheses/H01/",
    "H01_analysis_preparation.qmd"
  ) ~ "preparation_rendered_source",
  startsWith(
    relative,
    paste0(
      "_build/nathealth/audit/hypotheses/H01/",
      "H01_analysis_preparation_files/"
    )
  ) ~ "preparation_page_asset",
  relative == "notebooks/hypotheses/H01.qmd" ~ "result_report_source",
  relative == "_build/nathealth/notebooks/hypotheses/H01.html" ~
    "result_report_render",
  startsWith(relative, "scripts/hypotheses/H01/") ~ "H01_code",
  startsWith(relative, "scripts/pipeline/") ~ "shared_verification_code",
  startsWith(relative, "artifacts/06_model_data/H01/") ~
    "displayed_model_data_or_contract",
  startsWith(relative, "artifacts/08_diagnostics/H01/") ~
    "displayed_diagnostic_source",
  startsWith(relative, "artifacts/09_tables/H01/") ~
    "displayed_table_source",
  startsWith(relative, "artifacts/11_source_data/H01/preparation/") ~
    "displayed_figure_source_data",
  startsWith(relative, "artifacts/12_manifests/") ~
    "referenced_analysis_manifest",
  relative == "_quarto-nathealth.yml" ~ "shared_quarto_profile",
  relative == "config/site_display_registry.csv" ~ "shared_display_registry",
  relative == "renv.lock" ~ "environment_lock",
  TRUE ~ "supporting_provenance"
)

inventory <- tibble::tibble(
  path = relative,
  role = role,
  sha256 = vapply(files, artifact_sha256, character(1)),
  bytes = unname(file.info(files)$size),
  producer = producer,
  r_version = as.character(getRversion())
) |>
  arrange(.data$role, .data$path)

if (
  anyDuplicated(inventory$path) ||
    anyNA(inventory$sha256) ||
    any(nchar(inventory$sha256) != 64L)
) {
  h01_abort("Invalid H01 preparation-report manifest")
}

dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
invisible(write_csv_artifact(inventory, output_path, producer))
message("Recorded ", nrow(inventory), " H01 preparation-report identities")
