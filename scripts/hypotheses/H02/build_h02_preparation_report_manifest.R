#!/usr/bin/env Rscript

# Record the source and rendered identities for the H02 preparation report.
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
source(file.path(root, "scripts/hypotheses/H02/h02_contract.R"))

if (getRversion() != "4.6.1") {
  h02_abort("H02 requires R 4.6.1; running %s", getRversion())
}

invisible(h02_validate_inputs(root))

producer <- paste0(
  "scripts/hypotheses/H02/",
  "build_h02_preparation_report_manifest.R"
)
output_path <- file.path(
  root,
  "artifacts/12_manifests/H02/H02_preparation_report_manifest.csv"
)

script_files <- list.files(
  file.path(root, "scripts/hypotheses/H02"),
  pattern = "\\.R$",
  full.names = TRUE
)
manifest_files <- list.files(
  file.path(root, "artifacts/12_manifests/H02"),
  pattern = "\\.csv$",
  full.names = TRUE
)
worker_manifest_path <- file.path(
  root,
  "artifacts/12_manifests/H02/H02_worker_output_hashes.csv"
)
manifest_files <- setdiff(
  manifest_files,
  c(output_path, worker_manifest_path)
)
preparation_asset_dir <- file.path(
  root,
  paste0(
    "_build/nathealth/audit/hypotheses/H02/",
    "H02_analysis_preparation_files"
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

authoring_qmd <- file.path(
  root,
  "audit/hypotheses/H02/H02_analysis_preparation.qmd"
)
build_qmd <- file.path(
  root,
  paste0(
    "_build/nathealth/audit/hypotheses/H02/",
    "H02_analysis_preparation.qmd"
  )
)
if (
  !file_test("-f", authoring_qmd) ||
    nzchar(Sys.readlink(authoring_qmd)) ||
    !file_test("-f", build_qmd) ||
    nzchar(Sys.readlink(build_qmd))
) {
  h02_abort("H02 preparation QMD paths must be regular non-symlink files")
}

authoring_qmd_sha256 <- artifact_sha256(authoring_qmd)
authoring_qmd_bytes <- unname(file.info(authoring_qmd)$size)
authoring_qmd_mode <- as.character(file.info(authoring_qmd)$mode)
if (
  !identical(
    authoring_qmd_sha256,
    "92424e41a7f54d05b816ff79144850a27aabc8181aa705384b22f4c7cdc3b9a1"
  ) ||
    !identical(authoring_qmd_bytes, 55146)
) {
  h02_abort("Unexpected H02 authoring companion identity")
}

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
    !identical(
      as.character(file.info(authoring_qmd)$mode),
      authoring_qmd_mode
    ) ||
    !file_test("-f", build_qmd) ||
    nzchar(Sys.readlink(build_qmd)) ||
    !identical(artifact_sha256(build_qmd), authoring_qmd_sha256) ||
    !identical(unname(file.info(build_qmd)$size), authoring_qmd_bytes) ||
    !identical(as.character(file.info(build_qmd)$mode), authoring_qmd_mode)
) {
  h02_abort("Could not synchronize the H02 preparation QMD exactly")
}

preparation_download_sources <- file.path(
  root,
  "artifacts/11_source_data/H02",
  c(
    "preparation_response_distribution_positive_observations.csv",
    "preparation_response_distribution_exact_zero_summary.csv"
  )
)
expected_download_sha256 <- c(
  "22dff3af0f213b3ceaed0d5ca827da4184b662ff7d0366d592b6598b56e96842",
  "f2cc126a168bf8d6db3c5b13b3c6fea83030b23e7fdebff882bea1eb390f31db"
)
expected_download_bytes <- c(1409727, 244)
if (
  any(!file_test("-f", preparation_download_sources)) ||
    any(nzchar(Sys.readlink(preparation_download_sources)))
) {
  h02_abort(
    "H02 preparation download sources must be regular non-symlink files"
  )
}

download_source_sha256 <- unname(vapply(
  preparation_download_sources,
  artifact_sha256,
  character(1)
))
download_source_bytes <- unname(file.info(preparation_download_sources)$size)
download_source_modes <- as.character(
  file.info(preparation_download_sources)$mode
)
if (
  !identical(download_source_sha256, expected_download_sha256) ||
    !identical(download_source_bytes, expected_download_bytes)
) {
  h02_abort("Unexpected H02 preparation download source identities")
}

download_dir <- file.path(
  root,
  "_build/nathealth/artifacts/11_source_data/H02"
)
dir.create(download_dir, recursive = TRUE, showWarnings = FALSE)
preparation_download_files <- file.path(
  download_dir,
  basename(preparation_download_sources)
)
downloads_copied <- file.copy(
  from = preparation_download_sources,
  to = preparation_download_files,
  overwrite = TRUE,
  copy.mode = TRUE
)
if (
  !all(downloads_copied) ||
    !identical(
      unname(vapply(
        preparation_download_sources,
        artifact_sha256,
        character(1)
      )),
      download_source_sha256
    ) ||
    !identical(
      unname(file.info(preparation_download_sources)$size),
      download_source_bytes
    ) ||
    !identical(
      as.character(file.info(preparation_download_sources)$mode),
      download_source_modes
    ) ||
    any(!file_test("-f", preparation_download_files)) ||
    any(nzchar(Sys.readlink(preparation_download_files))) ||
    !identical(
      unname(vapply(
        preparation_download_files,
        artifact_sha256,
        character(1)
      )),
      download_source_sha256
    ) ||
    !identical(
      unname(file.info(preparation_download_files)$size),
      download_source_bytes
    ) ||
    !identical(
      as.character(file.info(preparation_download_files)$mode),
      download_source_modes
    )
) {
  h02_abort("Could not create byte-identical H02 source-data downloads")
}

files <- unique(c(
  file.path(root, "_quarto-nathealth.yml"),
  authoring_qmd,
  file.path(
    root,
    "_build/nathealth/audit/hypotheses/H02/H02_analysis_preparation.html"
  ),
  build_qmd,
  file.path(root, "notebooks/hypotheses/H02.qmd"),
  file.path(root, "_build/nathealth/notebooks/hypotheses/H02.html"),
  file.path(root, "config/site_display_registry.csv"),
  file.path(root, "renv.lock"),
  file.path(root, "artifacts/06_model_data/H02/input_hashes.csv"),
  file.path(root, "artifacts/06_model_data/H02/sample_counts.csv"),
  file.path(root, "artifacts/06_model_data/H02/support_audit.csv"),
  file.path(
    root,
    "artifacts/06_model_data/H02/temporal_model_specification.csv"
  ),
  file.path(
    root,
    "artifacts/06_model_data/H02/main__glasses__all_available.rds"
  ),
  file.path(
    root,
    "artifacts/06_model_data/H02/main__chest__all_available.rds"
  ),
  file.path(root, "artifacts/08_diagnostics/H02/residual_acf.csv"),
  file.path(root, "artifacts/08_diagnostics/H02/ar_boundary_audit.csv"),
  file.path(root, "artifacts/09_tables/H02/model_fit_summary.csv"),
  file.path(
    root,
    "artifacts/09_tables/H02/model_structure_comparisons.csv"
  ),
  file.path(
    root,
    "artifacts/10_figures/H02/figure4_exact_layout_replication.png"
  ),
  file.path(
    root,
    "artifacts/10_figures/H02/figure4_exact_layout_replication_chest.png"
  ),
  file.path(
    root,
    paste0(
      "artifacts/11_source_data/H02/",
      "preparation_response_distribution_positive_observations.csv"
    )
  ),
  file.path(
    root,
    paste0(
      "artifacts/11_source_data/H02/",
      "preparation_response_distribution_exact_zero_summary.csv"
    )
  ),
  file.path(
    root,
    "artifacts/11_source_data/H02/paired_placement_site_curves.csv"
  ),
  preparation_download_files,
  preparation_asset_files,
  script_files,
  manifest_files
))

if (any(!file.exists(files))) {
  missing <- files[!file.exists(files)]
  h02_abort(
    "Missing H02 preparation-report provenance file(s): %s",
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
  relative == "audit/hypotheses/H02/H02_analysis_preparation.qmd" ~
    "preparation_source",
  relative ==
    paste0(
      "_build/nathealth/audit/hypotheses/H02/",
      "H02_analysis_preparation.html"
    ) ~
    "preparation_render",
  relative ==
    paste0(
      "_build/nathealth/audit/hypotheses/H02/",
      "H02_analysis_preparation.qmd"
    ) ~
    "preparation_rendered_source",
  startsWith(
    relative,
    paste0(
      "_build/nathealth/audit/hypotheses/H02/",
      "H02_analysis_preparation_files/"
    )
  ) ~
    "preparation_page_asset",
  relative %in%
    file.path(
      "_build/nathealth/artifacts/11_source_data/H02",
      basename(preparation_download_files)
    ) ~
    "preparation_page_download",
  relative == "notebooks/hypotheses/H02.qmd" ~ "result_report_source",
  relative == "_build/nathealth/notebooks/hypotheses/H02.html" ~
    "result_report_render",
  startsWith(relative, "scripts/hypotheses/H02/") ~ "H02_code",
  startsWith(relative, "artifacts/06_model_data/H02/") ~
    "displayed_model_data_or_contract",
  startsWith(relative, "artifacts/08_diagnostics/H02/") ~
    "displayed_diagnostic_source",
  startsWith(relative, "artifacts/09_tables/H02/") ~ "displayed_table_source",
  startsWith(relative, "artifacts/10_figures/H02/") ~ "reader_figure",
  startsWith(relative, "artifacts/11_source_data/H02/") ~
    "displayed_figure_source_data",
  startsWith(relative, "artifacts/12_manifests/H02/") ~
    "referenced_stage_manifest",
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
  h02_abort("Invalid H02 preparation-report manifest")
}

dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
invisible(write_csv_artifact(inventory, output_path, producer))
message("Recorded ", nrow(inventory), " H02 preparation-report identities")
