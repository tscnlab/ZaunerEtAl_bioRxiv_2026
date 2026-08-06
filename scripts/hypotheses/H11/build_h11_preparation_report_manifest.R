#!/usr/bin/env Rscript

# Record the source, rendered identities, display assets, scientific inputs,
# and verification code for the H11 preparation companion. Before shared-site
# integration, the bounded standalone render is copied into the expected site
# tree. No scientific calculation is performed.

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

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("H11 preparation manifest requires R 4.6.1", call. = FALSE)
}

producer <- paste0(
  "scripts/hypotheses/H11/",
  "build_h11_preparation_report_manifest.R"
)
output_path <- file.path(
  root,
  "artifacts/12_manifests/H11/H11_preparation_report_manifest.csv"
)
source_path <- file.path(
  root,
  "audit/hypotheses/H11/H11_analysis_preparation.qmd"
)
local_render_path <- file.path(
  root,
  "audit/hypotheses/H11/H11_analysis_preparation.html"
)
local_asset_dir <- file.path(
  root,
  "audit/hypotheses/H11/H11_analysis_preparation_files"
)
build_dir <- file.path(root, "_build/nathealth/audit/hypotheses/H11")
rendered_source_path <- file.path(build_dir, "H11_analysis_preparation.qmd")
rendered_html_path <- file.path(build_dir, "H11_analysis_preparation.html")
rendered_asset_dir <- file.path(build_dir, "H11_analysis_preparation_files")
profile_path <- file.path(root, "_quarto-nathealth.yml")

read_raw_file <- function(path) {
  readBin(path, what = "raw", n = file.info(path)$size)
}

copy_file_verified <- function(from, to) {
  if (!file.exists(from)) {
    stop("Missing file to copy: ", from, call. = FALSE)
  }
  dir.create(dirname(to), recursive = TRUE, showWarnings = FALSE)
  if (!file.copy(from, to, overwrite = TRUE)) {
    stop("Could not copy ", from, " to ", to, call. = FALSE)
  }
  if (!identical(read_raw_file(from), read_raw_file(to))) {
    stop("Copied file is not byte-identical: ", to, call. = FALSE)
  }
  invisible(to)
}

copy_tree_verified <- function(from, to) {
  if (!dir.exists(from)) {
    stop("Missing directory to copy: ", from, call. = FALSE)
  }
  source_files <- list.files(
    from,
    recursive = TRUE,
    full.names = TRUE,
    include.dirs = FALSE,
    all.files = TRUE,
    no.. = TRUE
  )
  relative <- substring(source_files, nchar(from) + 2L)
  destination_files <- file.path(to, relative)
  for (index in seq_along(source_files)) {
    copy_file_verified(source_files[[index]], destination_files[[index]])
  }
  invisible(destination_files)
}

dir.create(build_dir, recursive = TRUE, showWarnings = FALSE)
copy_file_verified(source_path, rendered_source_path)

profile_lines <- readLines(profile_path, warn = FALSE, encoding = "UTF-8")
profile_integrated <- any(
  trimws(profile_lines) ==
    "- audit/hypotheses/H11/H11_analysis_preparation.qmd"
)

if (!profile_integrated) {
  if (!file.exists(local_render_path) || !dir.exists(local_asset_dir)) {
    stop(
      paste(
        "Before shared-site integration, render the bounded H11 preparation",
        "source once so its local HTML and resource directory can be copied."
      ),
      call. = FALSE
    )
  }
  copy_file_verified(local_render_path, rendered_html_path)
  copy_tree_verified(local_asset_dir, rendered_asset_dir)

  copy_tree_verified(
    file.path(root, "artifacts/10_figures/H11/preparation"),
    file.path(root, "_build/nathealth/artifacts/10_figures/H11/preparation")
  )
  copy_tree_verified(
    file.path(root, "artifacts/11_source_data/H11/preparation"),
    file.path(root, "_build/nathealth/artifacts/11_source_data/H11/preparation")
  )
}

if (!identical(read_raw_file(source_path), read_raw_file(rendered_source_path))) {
  stop("The H11 website QMD copy is not byte-identical", call. = FALSE)
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

script_files <- list_artifacts(
  file.path(root, "scripts/hypotheses/H11"),
  pattern = "\\.R$"
)
test_files <- list_artifacts(
  file.path(root, "tests/hypotheses/H11"),
  pattern = "\\.R$"
)
model_data_files <- list_artifacts(file.path(root, "artifacts/06_model_data/H11"))
model_files <- list_artifacts(file.path(root, "artifacts/07_models/H11"))
diagnostic_files <- list_artifacts(file.path(root, "artifacts/08_diagnostics/H11"))
table_files <- list_artifacts(file.path(root, "artifacts/09_tables/H11"))
figure_files <- list_artifacts(file.path(root, "artifacts/10_figures/H11"))
source_data_files <- list_artifacts(file.path(root, "artifacts/11_source_data/H11"))
manifest_files <- list_artifacts(
  file.path(root, "artifacts/12_manifests/H11"),
  pattern = "\\.(csv|pdf)$"
)
manifest_files <- setdiff(manifest_files, output_path)
preparation_asset_files <- list_artifacts(rendered_asset_dir)
site_figure_copies <- list_artifacts(file.path(
  root,
  "_build/nathealth/artifacts/10_figures/H11/preparation"
))
site_source_copies <- list_artifacts(file.path(
  root,
  "_build/nathealth/artifacts/11_source_data/H11/preparation"
))

decision_files <- file.path(root, c(
  "audit/decisions/hypothesis_preparation_provenance_companions.md",
  "audit/decisions/p_value_display_conventions.md",
  "audit/decisions/paired_placement_comparison_display.md",
  "audit/decisions/gap_timing_unaware_dataset_terminology.md",
  "audit/decisions/figure_readability_and_layout.md",
  "audit/decisions/report011_physical_size_revalidation.md",
  "audit/decisions/reader_facing_symlog_scale.md",
  "audit/decisions/answer_in_brief_callout.md"
))

files <- unique(c(
  profile_path,
  source_path,
  rendered_source_path,
  rendered_html_path,
  file.path(root, "notebooks/hypotheses/H11.qmd"),
  file.path(root, "_build/nathealth/notebooks/hypotheses/H11.html"),
  file.path(root, "config/site_display_registry.csv"),
  file.path(root, "renv.lock"),
  file.path(
    root,
    "audit/hypotheses/H11/H11_preparation_figure_readability_qa.md"
  ),
  file.path(root, "audit/hypotheses/H11/05_stage3_gate_and_stage4_transition.md"),
  file.path(root, "scripts/pipeline/paths_io.R"),
  file.path(root, "scripts/pipeline/p_value_display.R"),
  file.path(
    root,
    "scripts/pipeline/hypothesis_preparation_provenance_contract.R"
  ),
  decision_files,
  preparation_asset_files,
  site_figure_copies,
  site_source_copies,
  script_files,
  test_files,
  model_data_files,
  model_files,
  diagnostic_files,
  table_files,
  figure_files,
  source_data_files,
  manifest_files
))

if (any(!file.exists(files))) {
  missing <- files[!file.exists(files)]
  stop(
    "Missing H11 preparation-report provenance file(s): ",
    paste(missing, collapse = ", "),
    call. = FALSE
  )
}

normalized_files <- normalizePath(files, winslash = "/", mustWork = TRUE)
relative <- substring(normalized_files, nchar(root) + 2L)

role <- dplyr::case_when(
  relative == "audit/hypotheses/H11/H11_analysis_preparation.qmd" ~
    "preparation_source",
  relative == paste0(
    "_build/nathealth/audit/hypotheses/H11/",
    "H11_analysis_preparation.html"
  ) ~ "preparation_render",
  relative == paste0(
    "_build/nathealth/audit/hypotheses/H11/",
    "H11_analysis_preparation.qmd"
  ) ~ "preparation_rendered_source",
  startsWith(
    relative,
    paste0(
      "_build/nathealth/audit/hypotheses/H11/",
      "H11_analysis_preparation_files/"
    )
  ) ~ "preparation_page_asset",
  startsWith(relative, "_build/nathealth/artifacts/") ~
    "preparation_site_asset_copy",
  relative == "notebooks/hypotheses/H11.qmd" ~ "result_report_source",
  relative == "_build/nathealth/notebooks/hypotheses/H11.html" ~
    "result_report_render",
  startsWith(relative, "scripts/hypotheses/H11/") ~ "H11_code",
  startsWith(relative, "tests/hypotheses/H11/") ~ "H11_test",
  startsWith(relative, "artifacts/06_model_data/H11/") ~
    "stored_model_data_or_contract",
  startsWith(relative, "artifacts/07_models/H11/") ~ "stored_model_output",
  startsWith(relative, "artifacts/08_diagnostics/H11/") ~
    "stored_diagnostic_output",
  startsWith(relative, "artifacts/09_tables/H11/") ~ "stored_table_output",
  startsWith(relative, "artifacts/10_figures/H11/") ~ "reader_figure",
  startsWith(relative, "artifacts/11_source_data/H11/") ~
    "reader_figure_or_table_source_data",
  startsWith(relative, "artifacts/12_manifests/H11/") ~
    "referenced_H11_manifest",
  startsWith(relative, "audit/decisions/") ~ "approved_reporting_rule",
  startsWith(relative, "audit/hypotheses/H11/") ~ "H11_audit_record",
  relative == "_quarto-nathealth.yml" ~ "shared_quarto_profile",
  relative == "config/site_display_registry.csv" ~ "shared_display_registry",
  relative == "renv.lock" ~ "environment_lock",
  startsWith(relative, "scripts/pipeline/") ~ "shared_pipeline_code",
  TRUE ~ "supporting_provenance"
)

inventory <- tibble::tibble(
  path = relative,
  role = role,
  artifact_class = role,
  sha256 = vapply(normalized_files, artifact_sha256, character(1)),
  bytes = unname(file.info(normalized_files)$size),
  producer = producer,
  r_version = as.character(getRversion())
) |>
  arrange(.data$role, .data$path)

required_paths <- c(
  "audit/hypotheses/H11/H11_analysis_preparation.qmd",
  paste0(
    "_build/nathealth/audit/hypotheses/H11/",
    "H11_analysis_preparation.qmd"
  ),
  paste0(
    "_build/nathealth/audit/hypotheses/H11/",
    "H11_analysis_preparation.html"
  ),
  "_quarto-nathealth.yml"
)
if (
  anyDuplicated(inventory$path) ||
    anyNA(inventory$sha256) ||
    any(nchar(inventory$sha256) != 64L) ||
    !all(required_paths %in% inventory$path)
) {
  stop("Invalid H11 preparation-report manifest", call. = FALSE)
}

dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
invisible(write_csv_artifact(inventory, output_path, producer = producer))
message(
  "Recorded ",
  nrow(inventory),
  " H11 preparation-report identities with a byte-identical website source copy; shared profile integration = ",
  profile_integrated
)
