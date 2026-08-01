#!/usr/bin/env Rscript

# Build the non-circular checksum inventory for the completed H02 worker scope.

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

producer <- "scripts/hypotheses/H02/build_h02_worker_manifest.R"
output_path <- file.path(
  root,
  "artifacts/12_manifests/H02/H02_worker_output_hashes.csv"
)
handoff_path <- file.path(
  root,
  "audit/handoffs/H02_worker_handoff.md"
)

scope <- c(
  file.path(root, "scripts/hypotheses/H02"),
  file.path(root, "tests/hypotheses/H02"),
  file.path(root, "notebooks/hypotheses/H02.qmd"),
  file.path(root, "artifacts/06_model_data/H02"),
  file.path(root, "artifacts/07_models/H02"),
  file.path(root, "artifacts/08_diagnostics/H02"),
  file.path(root, "artifacts/09_tables/H02"),
  file.path(root, "artifacts/10_figures/H02"),
  file.path(root, "artifacts/11_source_data/H02"),
  file.path(root, "artifacts/12_manifests/H02"),
  file.path(root, "audit/hypotheses/H02"),
  file.path(root, "audit/handoffs/H02_shared_change_request.md"),
  file.path(
    root,
    "_build/nathealth/notebooks/hypotheses/H02.html"
  ),
  file.path(
    root,
    "_build/nathealth/notebooks/hypotheses/H02_files"
  ),
  file.path(
    root,
    paste0(
      "_build/nathealth/audit/hypotheses/H02/",
      "H02_analysis_preparation.html"
    )
  ),
  file.path(
    root,
    paste0(
      "_build/nathealth/audit/hypotheses/H02/",
      "H02_analysis_preparation_files"
    )
  ),
  file.path(root, "_build/nathealth/artifacts/10_figures/H02")
)

files_in_scope <- function(path) {
  if (!file.exists(path)) {
    return(character())
  }
  if (!dir.exists(path)) {
    return(path)
  }
  list.files(
    path,
    all.files = FALSE,
    recursive = TRUE,
    full.names = TRUE,
    include.dirs = FALSE
  )
}

files <- sort(unique(unlist(lapply(scope, files_in_scope))))
files <- files[
  file.info(files)$isdir %in% FALSE & !files %in% c(output_path, handoff_path)
]
if (length(files) == 0L) {
  h02_abort("The H02 worker checksum scope is empty")
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
artifact_class <- dplyr::case_when(
  startsWith(relative, "scripts/") ~ "code",
  startsWith(relative, "tests/") ~ "test",
  startsWith(relative, "notebooks/") ~ "source_notebook",
  startsWith(relative, "audit/") ~ "audit",
  startsWith(relative, "_build/") ~ "rendered_output",
  startsWith(relative, "artifacts/06_model_data/") ~ "model_data",
  startsWith(relative, "artifacts/07_models/") ~ "model",
  startsWith(relative, "artifacts/08_diagnostics/") ~ "diagnostic",
  startsWith(relative, "artifacts/09_tables/") ~ "result_table",
  startsWith(relative, "artifacts/10_figures/") ~ "figure",
  startsWith(relative, "artifacts/11_source_data/") ~ "source_data",
  startsWith(relative, "artifacts/12_manifests/") ~ "manifest",
  TRUE ~ "other"
)

inventory <- tibble::tibble(
  path = relative,
  sha256 = vapply(files, artifact_sha256, character(1)),
  bytes = unname(file.info(files)$size),
  artifact_class = artifact_class,
  producer = producer,
  r_version = as.character(getRversion())
)
if (
  anyDuplicated(inventory$path) ||
    anyNA(inventory$sha256) ||
    any(nchar(inventory$sha256) != 64L)
) {
  h02_abort("Invalid H02 worker checksum inventory")
}

dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
invisible(write_csv_artifact(inventory, output_path, producer))
message("Recorded ", nrow(inventory), " non-circular H02 worker hashes")
