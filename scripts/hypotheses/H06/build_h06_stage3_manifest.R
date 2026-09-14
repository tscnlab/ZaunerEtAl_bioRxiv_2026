#!/usr/bin/env Rscript

# Seal the H06 Stage 3 reader report, H06-scoped code, accepted analytical
# artifacts, linked reader assets, and audit provenance. This script hashes
# files and performs no scientific calculation or model fitting.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
source(file.path(root, "scripts/pipeline/paths_io.R"))

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop(
    sprintf(
      "The H06 Stage 3 manifest requires R 4.6.1; found %s",
      as.character(getRversion())
    ),
    call. = FALSE
  )
}

producer <- "scripts/hypotheses/H06/build_h06_stage3_manifest.R"
output_path <- file.path(
  root,
  "artifacts/12_manifests/H06/H06_stage3_artifacts.csv"
)

accepted_inputs <- tibble::tribble(
  ~relative_path,
  ~expected_sha256,
  "audit/hypotheses/H06/02_implementation_and_v0_comparison.qmd",
  "736926de3576a7dceaed7b92fb65f65a05d8f6d32604d533fd9eb6e45e26a36d",
  "audit/hypotheses/H06/02_implementation_and_v0_comparison.html",
  "eea3da853bb23db96a59759d11a8f7eeb838e2e42960bf71ab96830030289b75",
  "artifacts/12_manifests/H06/H06_stage2_artifacts.csv",
  "2407f2045d960be1025dbd5e338d0df9a733bd4caf2afc29f16a9680fb355752",
  "audit/decisions/h06_stage2_gate_and_stage3_transition.md",
  "88fb0bae10e24d3fb300de64d8c6959865a5cfa7ed9ced98e66ae2dffbe0617d"
)
accepted_paths <- file.path(root, accepted_inputs$relative_path)
if (
  any(!file.exists(accepted_paths)) ||
    !identical(
      unname(vapply(accepted_paths, artifact_sha256, character(1))),
      accepted_inputs$expected_sha256
    )
) {
  stop("An accepted H06-G2 input identity changed", call. = FALSE)
}

inventory_roots <- file.path(
  root,
  c(
    "scripts/hypotheses/H06",
    "tests/hypotheses/H06",
    "audit/hypotheses/H06",
    "artifacts/06_model_data/H06",
    "artifacts/07_models/H06",
    "artifacts/08_diagnostics/H06",
    "artifacts/09_tables/H06",
    "artifacts/10_figures/H06",
    "artifacts/11_source_data/H06",
    "artifacts/12_manifests/H06",
    "_build/nathealth/notebooks/hypotheses/H06_files",
    "_build/nathealth/artifacts/06_model_data/H06",
    "_build/nathealth/artifacts/09_tables/H06",
    "_build/nathealth/artifacts/11_source_data/H06"
  )
)
inventory_files <- unlist(lapply(
  inventory_roots[dir.exists(inventory_roots)],
  list.files,
  recursive = TRUE,
  full.names = TRUE,
  include.dirs = FALSE
))
single_files <- file.path(
  root,
  c(
    "notebooks/hypotheses/H06.qmd",
    "notebooks/hypotheses/H06.css",
    "_build/nathealth/notebooks/hypotheses/H06.html",
    "audit/handoffs/H06_worker_handoff.md",
    "audit/handoffs/H06_shared_change_request.md",
    "audit/decisions/h06_stage2_gate_and_stage3_transition.md",
    "scripts/pipeline/p_value_display.R"
  )
)
files <- sort(unique(c(inventory_files, single_files)))
files <- files[file.exists(files) & !dir.exists(files)]

normalized_output <- normalizePath(
  output_path,
  winslash = "/",
  mustWork = FALSE
)
normalized_files <- normalizePath(files, winslash = "/", mustWork = TRUE)
files <- normalized_files[normalized_files != normalized_output]
relative <- substring(files, nchar(root) + 2L)

artifact_class <- dplyr::case_when(
  relative == "notebooks/hypotheses/H06.qmd" ~ "reader_report_source",
  relative == "notebooks/hypotheses/H06.css" ~ "reader_report_style",
  relative == "_build/nathealth/notebooks/hypotheses/H06.html" ~
    "reader_report_render",
  startsWith(
    relative,
    "_build/nathealth/notebooks/hypotheses/H06_files/"
  ) ~
    "reader_report_page_asset",
  startsWith(relative, "_build/nathealth/artifacts/") ~
    "reader_report_linked_asset",
  startsWith(relative, "scripts/hypotheses/H06/") ~ "H06_code",
  startsWith(relative, "tests/hypotheses/H06/") ~ "H06_test",
  startsWith(relative, "audit/hypotheses/H06/") ~ "H06_audit_report",
  startsWith(relative, "audit/handoffs/H06_") ~ "H06_handoff",
  relative == "audit/decisions/h06_stage2_gate_and_stage3_transition.md" ~
    "coordinator_gate_decision",
  relative == "scripts/pipeline/p_value_display.R" ~ "shared_reporting_helper",
  startsWith(relative, "artifacts/06_model_data/H06/") ~
    "frozen_model_data_or_contract",
  startsWith(relative, "artifacts/07_models/H06/") ~ "frozen_model_archive",
  startsWith(relative, "artifacts/08_diagnostics/H06/") ~
    "frozen_diagnostic_source",
  startsWith(relative, "artifacts/09_tables/H06/") ~ "frozen_table_source",
  startsWith(relative, "artifacts/10_figures/H06/") ~ "H06_figure",
  startsWith(relative, "artifacts/11_source_data/H06/") ~ "H06_source_data",
  startsWith(relative, "artifacts/12_manifests/H06/") ~
    "prior_or_supporting_H06_manifest",
  TRUE ~ "supporting_provenance"
)
artifact_type <- tolower(tools::file_ext(relative))
artifact_type[artifact_type == ""] <- "file"
written_utc <- format(Sys.time(), tz = "UTC", usetz = TRUE)

inventory <- tibble::tibble(
  path = relative,
  artifact_class = artifact_class,
  artifact_type = artifact_type,
  sha256 = unname(vapply(files, artifact_sha256, character(1))),
  bytes = as.numeric(file.info(files)$size),
  producer = producer,
  r_version = as.character(getRversion()),
  written_utc = written_utc
) |>
  dplyr::arrange(.data$artifact_class, .data$path)

if (
  anyDuplicated(inventory$path) ||
    anyNA(inventory$sha256) ||
    any(nchar(inventory$sha256) != 64L) ||
    output_path %in% file.path(root, inventory$path)
) {
  stop("Invalid H06 Stage 3 artifact inventory", call. = FALSE)
}

dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
invisible(write_csv_artifact(inventory, output_path, producer))
message(
  "H06 Stage 3 artifact manifest completed: ",
  nrow(inventory),
  " entries"
)
