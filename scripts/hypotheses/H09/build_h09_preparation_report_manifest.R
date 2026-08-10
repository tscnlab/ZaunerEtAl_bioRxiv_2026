#!/usr/bin/env Rscript

# Seal the H09 analysis-preparation source, scoped render, scientific inputs,
# frozen outputs, display assets, and verification code. This preintegration
# manifest records the current shared Quarto profile but does not require the
# coordinator-owned navigation entry. It performs no scientific calculation.

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
source(file.path(
  root,
  "scripts/pipeline/hypothesis_preparation_provenance_contract.R"
))

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop(
    paste0(
      "The H09 preparation-report manifest requires R 4.6.1; found ",
      as.character(getRversion())
    ),
    call. = FALSE
  )
}

paths <- preparation_companion_paths(root, "H09")
producer <- paste0(
  "scripts/hypotheses/H09/",
  "build_h09_preparation_report_manifest.R"
)
output_path <- paths$manifest
local_scoped_html <- file.path(
  root,
  "audit/hypotheses/H09/H09_analysis_preparation.html"
)
profile_text <- paste(
  readLines(paths$quarto_profile, warn = FALSE, encoding = "UTF-8"),
  collapse = "\n"
)
profile_integrated <- grepl(
  "audit/hypotheses/H09/H09_analysis_preparation.qmd",
  profile_text,
  fixed = TRUE
)

if (!file.exists(paths$qmd)) {
  stop(
    "The H09 preparation source must exist first",
    call. = FALSE
  )
}

# Before coordinator-owned profile integration, Quarto writes a single-file
# scoped render beside its source. Preserve that exact render at the intended
# website path. Once integrated, the profile-produced website render is used
# directly and is never replaced from the local preintegration copy.
if (!profile_integrated) {
  if (!file.exists(local_scoped_html)) {
    stop("The H09 scoped preparation HTML render is missing", call. = FALSE)
  }
  dir.create(dirname(paths$html), recursive = TRUE, showWarnings = FALSE)
  if (!file.copy(local_scoped_html, paths$html, overwrite = TRUE)) {
    stop("Could not preserve the H09 scoped website HTML", call. = FALSE)
  }
  if (!identical(
    read_file_bytes(local_scoped_html),
    read_file_bytes(paths$html)
  )) {
    stop("The preserved H09 HTML is not byte-identical", call. = FALSE)
  }
} else if (!file.exists(paths$html)) {
  stop("The profile-integrated H09 preparation HTML is missing", call. = FALSE)
}

dir.create(dirname(paths$rendered_qmd), recursive = TRUE, showWarnings = FALSE)
if (!file.copy(paths$qmd, paths$rendered_qmd, overwrite = TRUE)) {
  stop("Could not create the H09 website QMD source copy", call. = FALSE)
}
if (!identical(read_file_bytes(paths$qmd), read_file_bytes(paths$rendered_qmd))) {
  stop(
    "The H09 website QMD copy is not byte-identical to its authoring source",
    call. = FALSE
  )
}

list_artifacts <- function(path, pattern = NULL) {
  if (!dir.exists(path)) {
    return(character())
  }
  list.files(
    path,
    pattern = pattern,
    recursive = TRUE,
    full.names = TRUE,
    include.dirs = FALSE
  )
}

h09_roots <- file.path(
  root,
  c(
    "scripts/hypotheses/H09",
    "tests/hypotheses/H09",
    "audit/hypotheses/H09",
    "artifacts/06_model_data/H09",
    "artifacts/07_models/H09",
    "artifacts/08_diagnostics/H09",
    "artifacts/09_tables/H09",
    "artifacts/10_figures/H09",
    "artifacts/11_source_data/H09",
    "artifacts/12_manifests/H09"
  )
)
h09_files <- unlist(lapply(h09_roots, list_artifacts), use.names = FALSE)

preparation_assets <- list_artifacts(file.path(
  dirname(paths$html),
  "H09_analysis_preparation_files"
))

decision_files <- file.path(
  root,
  c(
    "audit/decisions/answer_in_brief_callout.md",
    "audit/decisions/bootstrap_execution_policy.md",
    "audit/decisions/figure_readability_and_layout.md",
    "audit/decisions/gap_timing_unaware_dataset_terminology.md",
    "audit/decisions/hypothesis_preparation_provenance_companions.md",
    "audit/decisions/model_reporting.md",
    "audit/decisions/p_value_display_conventions.md",
    "audit/decisions/paired_placement_comparison_display.md",
    "audit/decisions/placement_decision.md",
    "audit/decisions/reader_facing_symlog_scale.md",
    "audit/decisions/site_display_conventions.md"
  )
)

supporting_files <- file.path(
  root,
  c(
    "AGENTS.md",
    "renv.lock",
    "_quarto.yml",
    "_quarto-nathealth.yml",
    "notebooks/hypotheses/H09.qmd",
    "_build/nathealth/notebooks/hypotheses/H09.html",
    "config/metric_display_registry.csv",
    "config/site_display_registry.csv",
    "audit/evidence/preregistration_contract.md",
    "audit/hypotheses/H03-H11_gated_workflow.qmd",
    "audit/hypotheses/H09-H11_migration_map.md",
    "scripts/pipeline/paths_io.R",
    "scripts/pipeline/p_value_display.R",
    "scripts/pipeline/hypothesis_preparation_provenance_contract.R"
  )
)

files <- unique(c(
  paths$qmd,
  paths$html,
  paths$rendered_qmd,
  paths$result_qmd,
  paths$result_html,
  paths$quarto_profile,
  h09_files,
  preparation_assets,
  decision_files,
  supporting_files
))

# These records continue to change after the scientific outputs are frozen;
# excluding them prevents a circular or immediately stale manifest.
files <- files[
  !grepl(
    "audit/handoffs/H09_(?:worker_handoff|shared_change_request)\\.md$",
    files,
    perl = TRUE
  )
]
files <- setdiff(files, output_path)
files <- files[file.exists(files) & !dir.exists(files)]

if (length(files) == 0L || any(!file.exists(files))) {
  stop("No complete H09 preparation provenance inventory is available", call. = FALSE)
}

normalized_files <- normalizePath(files, winslash = "/", mustWork = TRUE)
normalized_files <- sort(unique(normalized_files))
relative <- substring(normalized_files, nchar(root) + 2L)

role <- dplyr::case_when(
  relative == "audit/hypotheses/H09/H09_analysis_preparation.qmd" ~
    "preparation_source",
  relative == paste0(
    "_build/nathealth/audit/hypotheses/H09/",
    "H09_analysis_preparation.html"
  ) ~ "preparation_render",
  relative == paste0(
    "_build/nathealth/audit/hypotheses/H09/",
    "H09_analysis_preparation.qmd"
  ) ~ "preparation_rendered_source",
  startsWith(
    relative,
    paste0(
      "_build/nathealth/audit/hypotheses/H09/",
      "H09_analysis_preparation_files/"
    )
  ) ~ "preparation_page_asset",
  relative == "notebooks/hypotheses/H09.qmd" ~ "result_report_source",
  relative == "_build/nathealth/notebooks/hypotheses/H09.html" ~
    "result_report_render",
  startsWith(relative, "scripts/hypotheses/H09/") ~ "H09_code",
  startsWith(relative, "tests/hypotheses/H09/") ~ "H09_test",
  startsWith(relative, "audit/hypotheses/H09/") ~ "H09_audit_record",
  startsWith(relative, "artifacts/06_model_data/H09/") ~
    "stored_model_data_or_contract",
  startsWith(relative, "artifacts/07_models/H09/") ~ "stored_model_output",
  startsWith(relative, "artifacts/08_diagnostics/H09/") ~
    "stored_diagnostic_output",
  startsWith(relative, "artifacts/09_tables/H09/") ~ "stored_table_output",
  startsWith(relative, "artifacts/10_figures/H09/") ~ "reader_figure",
  startsWith(relative, "artifacts/11_source_data/H09/") ~
    "reader_figure_or_table_source_data",
  startsWith(relative, "artifacts/12_manifests/H09/") ~
    "referenced_H09_manifest",
  startsWith(relative, "audit/decisions/") ~ "approved_reporting_rule",
  relative == "audit/evidence/preregistration_contract.md" ~
    "preregistration_contract",
  relative == "audit/hypotheses/H03-H11_gated_workflow.qmd" ~
    "approved_workflow_contract",
  relative == "audit/hypotheses/H09-H11_migration_map.md" ~ "migration_map",
  relative == "_quarto-nathealth.yml" ~ "pending_shared_quarto_profile",
  relative == "_quarto.yml" ~ "shared_quarto_configuration",
  startsWith(relative, "config/") ~ "shared_display_registry",
  relative == "renv.lock" ~ "environment_lock",
  relative == "AGENTS.md" ~ "project_instructions",
  startsWith(relative, "scripts/pipeline/") ~ "shared_pipeline_code",
  TRUE ~ "supporting_provenance"
)

artifact_type <- tolower(tools::file_ext(relative))
artifact_type[artifact_type == ""] <- "file"
written_utc <- format(Sys.time(), tz = "UTC", usetz = TRUE)

inventory <- tibble::tibble(
  path = relative,
  role = role,
  artifact_class = role,
  artifact_type = artifact_type,
  sha256 = unname(vapply(normalized_files, artifact_sha256, character(1))),
  bytes = as.numeric(file.info(normalized_files)$size),
  producer = producer,
  r_version = as.character(getRversion()),
  written_utc = written_utc
) |>
  arrange(.data$role, .data$path)

required_paths <- c(
  "audit/hypotheses/H09/H09_analysis_preparation.qmd",
  paste0(
    "_build/nathealth/audit/hypotheses/H09/",
    "H09_analysis_preparation.qmd"
  ),
  paste0(
    "_build/nathealth/audit/hypotheses/H09/",
    "H09_analysis_preparation.html"
  ),
  "notebooks/hypotheses/H09.qmd",
  "_build/nathealth/notebooks/hypotheses/H09.html",
  "scripts/hypotheses/H09/build_h09_preparation_report_manifest.R",
  "tests/hypotheses/H09/test_h09_preparation_report.R",
  "_quarto-nathealth.yml"
)

if (
  anyDuplicated(inventory$path) ||
    anyNA(inventory$sha256) ||
    any(nchar(inventory$sha256) != 64L) ||
    !all(required_paths %in% inventory$path) ||
    any(grepl("audit/handoffs/H09_", inventory$path, fixed = TRUE)) ||
    basename(output_path) %in% basename(inventory$path)
) {
  stop("Invalid H09 preparation-report manifest", call. = FALSE)
}

dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
invisible(write_csv_artifact(inventory, output_path, producer))
message(
  "Recorded ",
  nrow(inventory),
  " H09 preparation-report identities with a byte-identical website source copy"
)
