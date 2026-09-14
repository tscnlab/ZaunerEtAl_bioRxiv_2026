#!/usr/bin/env Rscript

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
source(file.path(root, "scripts/pipeline/paths_io.R"))

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("REPORT-017 order 31f inventory requires R 4.6.1", call. = FALSE)
}

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1L || !args[[1]] %in% c("pre", "post")) {
  stop("Supply exactly one inventory phase: `pre` or `post`", call. = FALSE)
}
phase <- args[[1]]

evidence_relative <-
  "audit/hypotheses/H01/report017_model_support_fdr_refresh"
evidence_root <- file.path(root, evidence_relative)
dir.create(evidence_root, recursive = TRUE, showWarnings = FALSE)

read_manifest_paths <- function(relative_path) {
  manifest <- utils::read.csv(
    file.path(root, relative_path),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  manifest$path
}

files_under <- function(relative_path) {
  path <- file.path(root, relative_path)
  if (!dir.exists(path)) {
    return(character())
  }
  absolute <- list.files(
    path,
    recursive = TRUE,
    full.names = TRUE,
    all.files = TRUE,
    no.. = TRUE
  )
  absolute <- absolute[file.info(absolute)$isdir %in% FALSE]
  substring(absolute, nchar(root) + 2L)
}

artifact_paths <- unique(c(
  read_manifest_paths("artifacts/12_manifests/H01_worker_artifacts.csv"),
  read_manifest_paths("artifacts/12_manifests/H01_stage3_reporting_artifacts.csv"),
  read_manifest_paths("artifacts/12_manifests/H01_reporting_artifacts.csv"),
  "artifacts/06_model_data/H01.rds",
  files_under("artifacts/06_model_data/H01"),
  files_under("artifacts/07_models/H01"),
  files_under("artifacts/08_diagnostics/H01"),
  files_under("artifacts/09_tables/H01"),
  files_under("artifacts/10_figures/H01"),
  files_under("artifacts/11_source_data/H01")
))

report016_paths <- unique(c(
  files_under("audit/hypotheses/H01/report016"),
  list.files(
    file.path(root, "audit"),
    pattern = "report016",
    recursive = TRUE,
    full.names = TRUE,
    ignore.case = TRUE
  ) |>
    (function(paths) paths[file.info(paths)$isdir %in% FALSE])() |>
    substring(nchar(root) + 2L)
))

explicit_paths <- c(
  "notebooks/hypotheses/H01.qmd",
  "audit/hypotheses/H01/H01_analysis_preparation.qmd",
  "_quarto-nathealth.yml",
  "scripts/report_harmonization/post_render_gt_html_semantics.R",
  "scripts/report_harmonization/repair_gt_html_semantics.R",
  "scripts/hypotheses/H01/build_h01_stage3_reporting_inputs.R",
  "tests/hypotheses/H01/test_h01_reporting_inputs.R",
  "tests/hypotheses/H01/test_h01_report016_deviation_reconciliation.R",
  "artifacts/12_manifests/H01_reporting_artifacts.csv",
  "artifacts/12_manifests/H01_stage3_reporting_artifacts.csv",
  "artifacts/12_manifests/H01_worker_artifacts.csv",
  "audit/handoffs/H01_worker_handoff.md",
  "_build/nathealth/notebooks/hypotheses/H01.html"
)

relative_paths <- sort(unique(c(
  artifact_paths,
  report016_paths,
  explicit_paths
)))
relative_paths <- relative_paths[
  !startsWith(relative_paths, paste0(evidence_relative, "/"))
]
absolute_paths <- file.path(root, relative_paths)
if (!all(file.exists(absolute_paths))) {
  missing <- relative_paths[!file.exists(absolute_paths)]
  stop(
    "Inventory scope contains missing files: ",
    paste(missing, collapse = ", "),
    call. = FALSE
  )
}

inventory <- data.frame(
  path = relative_paths,
  sha256 = vapply(absolute_paths, artifact_sha256, character(1)),
  bytes = unname(file.info(absolute_paths)$size),
  mode = as.character(file.info(absolute_paths)$mode),
  scope = ifelse(
    relative_paths %in% report016_paths,
    "historical_report016",
    ifelse(
      startsWith(relative_paths, "artifacts/"),
      "h01_scientific_or_input_artifact",
      "h01_source_configuration_or_held_output"
    )
  ),
  stringsAsFactors = FALSE
)

output <- file.path(
  evidence_root,
  paste0("H01_model_support_fdr_refresh_protected_inventory_", phase, ".csv")
)
utils::write.csv(inventory, output, row.names = FALSE, na = "")

cat(sprintf(
  "REPORT-017 order 31f %s inventory: %d paths, including %d historical REPORT-016 paths\n",
  phase,
  nrow(inventory),
  sum(inventory$scope == "historical_report016")
))

