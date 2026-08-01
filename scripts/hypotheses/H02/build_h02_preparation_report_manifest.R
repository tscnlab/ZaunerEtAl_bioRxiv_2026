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

files <- unique(c(
  file.path(root, "_quarto-nathealth.yml"),
  file.path(root, "audit/hypotheses/H02/H02_analysis_preparation.qmd"),
  file.path(
    root,
    "_build/nathealth/audit/hypotheses/H02/H02_analysis_preparation.html"
  ),
  file.path(
    root,
    "_build/nathealth/audit/hypotheses/H02/H02_analysis_preparation.qmd"
  ),
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
  relative == paste0(
    "_build/nathealth/audit/hypotheses/H02/",
    "H02_analysis_preparation.html"
  ) ~ "preparation_render",
  relative == paste0(
    "_build/nathealth/audit/hypotheses/H02/",
    "H02_analysis_preparation.qmd"
  ) ~ "preparation_rendered_source",
  startsWith(
    relative,
    paste0(
      "_build/nathealth/audit/hypotheses/H02/",
      "H02_analysis_preparation_files/"
    )
  ) ~ "preparation_page_asset",
  relative == "notebooks/hypotheses/H02.qmd" ~ "result_report_source",
  relative == "_build/nathealth/notebooks/hypotheses/H02.html" ~
    "result_report_render",
  startsWith(relative, "scripts/hypotheses/H02/") ~ "H02_code",
  startsWith(relative, "artifacts/06_model_data/H02/") ~
    "displayed_model_data_or_contract",
  startsWith(relative, "artifacts/08_diagnostics/H02/") ~
    "displayed_diagnostic_source",
  startsWith(relative, "artifacts/09_tables/H02/") ~
    "displayed_table_source",
  startsWith(relative, "artifacts/10_figures/H02/") ~
    "reader_figure",
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
