#!/usr/bin/env Rscript

# Build the final METRIC-011 preservation, input, code, output, software, and
# report manifests. This script performs no model fit or scientific transform.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
.libPaths(c(
  file.path(root, "renv/library/macos/R-4.6/aarch64-apple-darwin23"),
  .libPaths()
))
required_packages <- c("digest", "dplyr", "readr", "tibble")
stopifnot(
  identical(as.character(getRversion()), "4.6.1"),
  all(vapply(required_packages, requireNamespace, logical(1), quietly = TRUE))
)

sha256 <- function(path) digest::digest(path, algo = "sha256", file = TRUE)
relative <- function(path) {
  sub(paste0("^", root, "/"), "", normalizePath(
    path,
    winslash = "/",
    mustWork = TRUE
  ))
}
manifest_frame <- function(paths, roles, producer) {
  paths <- unique(paths)
  stopifnot(length(paths) == length(unique(paths)))
  absolute <- file.path(root, paths)
  stopifnot(length(paths) == length(roles), all(file.exists(absolute)))
  tibble::tibble(
    relative_path = paths,
    sha256 = unname(vapply(absolute, sha256, character(1))),
    bytes = unname(file.info(absolute)$size),
    role = roles,
    producer = producer,
    r_version = as.character(getRversion())
  )
}
write_manifest <- function(paths, roles, output, producer) {
  manifest <- manifest_frame(paths, roles, producer)
  readr::write_csv(manifest, file.path(root, output), na = "")
  manifest
}

artifact_root <- file.path(root, "artifacts")
diagnostic_root <- file.path(artifact_root, "08_diagnostics/H06_daily")
manifest_root <- file.path(artifact_root, "12_manifests/H06_daily")
producer <- paste0(
  "scripts/hypotheses/H06_daily/",
  "build_h06_daily_l10_metric011_manifests.R"
)

# Final byte-for-byte preservation check against the pre-METRIC-011 baseline.
baseline_path <- file.path(
  diagnostic_root,
  "H06_daily_l10_metric011_protected_baseline.csv"
)
baseline <- readr::read_csv(
  baseline_path,
  show_col_types = FALSE,
  na = c("", "NA")
)
protected_absolute <- file.path(root, baseline$relative_path)
stopifnot(all(file.exists(protected_absolute)))
final_preservation <- baseline |>
  dplyr::mutate(
    sha256_after = unname(vapply(
      protected_absolute,
      sha256,
      character(1)
    )),
    bytes_after = unname(file.info(protected_absolute)$size),
    preserved_byte_for_byte =
      .data$sha256_before == .data$sha256_after &
      .data$bytes_before == .data$bytes_after,
    verification_stage = "final report and manifest seal"
  )
stopifnot(nrow(final_preservation) == 294L)
if (!all(final_preservation$preserved_byte_for_byte)) {
  stop("A protected H06_daily file changed before the final seal", call. = FALSE)
}
final_preservation_path <- file.path(
  diagnostic_root,
  "H06_daily_l10_metric011_protected_preservation_final.csv"
)
readr::write_csv(final_preservation, final_preservation_path, na = "")

# Inputs used across static audit, production, finalizer, postprocessing, and
# deletion diagnostics.
input_contract <- readr::read_csv(
  file.path(
    diagnostic_root,
    "H06_daily_l10_metric011_input_contract.csv"
  ),
  show_col_types = FALSE,
  na = c("", "NA")
)
stopifnot(all(input_contract$identity_pass))
frame_registry_path <- paste0(
  "artifacts/06_model_data/H06_daily/",
  "H06_daily_l10_metric011_frame_registry.csv"
)
frame_registry <- readr::read_csv(
  file.path(root, frame_registry_path),
  show_col_types = FALSE,
  na = c("", "NA")
)
stopifnot(nrow(frame_registry) == 36L)

input_paths <- c(
  input_contract$relative_path,
  frame_registry_path,
  frame_registry$frame_path,
  "artifacts/08_diagnostics/H06_daily/H06_daily_l10_metric011_scenario_component_change_inventory.csv",
  "artifacts/08_diagnostics/H06_daily/H06_daily_l10_metric011_pilot_runtime_projection.csv",
  "artifacts/08_diagnostics/H06_daily/H06_daily_l10_metric011_protected_baseline.csv",
  "artifacts/09_tables/H06_daily/H06_daily_mder_metric010_model_tests.csv",
  "artifacts/12_manifests/H06_daily/H06_daily_l10_metric011_static_output_manifest.csv"
)
input_roles <- c(
  paste0("sealed upstream input: ", input_contract$role),
  "sealed 36-component frame registry",
  paste0(
    "sealed L10 component frame: ",
    frame_registry$run_id,
    " / ",
    frame_registry$predictor_id,
    " / ",
    frame_registry$component
  ),
  "scenario/component change and fit-action inventory",
  "passed production runtime pilot",
  "protected pre-amendment H06_daily baseline",
  "frozen MDER slots used only to complete dependent BH fields",
  "static-audit output manifest"
)
input_output <- paste0(
  "artifacts/12_manifests/H06_daily/",
  "H06_daily_l10_metric011_production_input_manifest.csv"
)
input_manifest <- write_manifest(
  input_paths,
  input_roles,
  input_output,
  producer
)

code_paths <- paste0(
  "scripts/hypotheses/H06_daily/",
  c(
    "h06_daily_l10_metric011_contract.R",
    "h06_daily_l10_metric011_data.R",
    "h06_daily_l10_metric011_modeling.R",
    "audit_h06_daily_l10_metric011.R",
    "run_h06_daily_l10_metric011_pilot.R",
    "run_h06_daily_l10_metric011_production.R",
    "run_h06_daily_l10_metric011_influence_pilot.R",
    "run_h06_daily_l10_metric011_influence.R",
    "finalize_h06_daily_l10_metric011.R",
    "postprocess_h06_daily_l10_metric011.R",
    "build_h06_daily_l10_metric011_manifests.R"
  )
)
code_roles <- c(
  "controlling contract and registries",
  "component-frame construction and audit helpers",
  "component models and diagnostics",
  "no-fit static input and change audit",
  "bounded production-code model pilot",
  "serial L10-only production",
  "50-refit influence pilot",
  "serial positive-only influence batch",
  "no-refit coordinator-disposition finalizer",
  "no-refit report-data and figure postprocessor",
  "final manifest and preservation builder"
)
code_output <- paste0(
  "artifacts/12_manifests/H06_daily/",
  "H06_daily_l10_metric011_production_code_manifest.csv"
)
code_manifest <- write_manifest(
  code_paths,
  code_roles,
  code_output,
  producer
)

# Every task-owned L10 output outside the manifest directory is included.
output_directories <- file.path(
  root,
  "artifacts",
  c(
    "06_model_data/H06_daily",
    "07_models/H06_daily",
    "08_diagnostics/H06_daily",
    "09_tables/H06_daily",
    "10_figures/H06_daily",
    "11_source_data/H06_daily"
  )
)
output_absolute <- unlist(lapply(
  output_directories,
  function(directory) list.files(
    directory,
    pattern = "^H06_daily_l10_metric011",
    full.names = TRUE
  )
), use.names = FALSE)
output_paths <- sort(vapply(output_absolute, relative, character(1)))
output_roles <- rep(
  "METRIC-011 task-owned model/data/diagnostic/table/figure/source output",
  length(output_paths)
)
output_manifest_path <- paste0(
  "artifacts/12_manifests/H06_daily/",
  "H06_daily_l10_metric011_production_output_manifest.csv"
)
output_manifest <- write_manifest(
  output_paths,
  output_roles,
  output_manifest_path,
  producer
)

software_packages <- c(
  "digest", "dplyr", "ggplot2", "glmmTMB", "gt", "lme4",
  "performance", "readr", "svglite", "tibble", "tidyr"
)
software_manifest <- tibble::tibble(
  software = c("R", software_packages),
  version = c(
    as.character(getRversion()),
    vapply(
      software_packages,
      function(package) as.character(utils::packageVersion(package)),
      character(1)
    )
  ),
  role = c(
    "authoritative research computation language",
    rep("synchronized project package", length(software_packages))
  ),
  producer = producer
)
software_output <- file.path(
  manifest_root,
  "H06_daily_l10_metric011_production_software_manifest.csv"
)
readr::write_csv(software_manifest, software_output, na = "")

# Report-level durable artifact map. The manifest does not hash itself.
report_paths <- c(
  "audit/hypotheses/H06_daily/08_l10_metric011_amendment.qmd",
  "audit/hypotheses/H06_daily/08_l10_metric011_amendment.html",
  "audit/hypotheses/H06_daily/H06_daily_l10_metric011_transition.md",
  "audit/handoffs/H06_daily_worker_handoff.md",
  "audit/handoffs/H06_daily_shared_change_request.md",
  code_paths,
  "tests/hypotheses/H06_daily/test_h06_daily_l10_metric011.R",
  input_output,
  code_output,
  output_manifest_path,
  "artifacts/12_manifests/H06_daily/H06_daily_l10_metric011_production_software_manifest.csv",
  output_paths
)
report_roles <- c(
  "author-gate Quarto source",
  "self-contained author-gate HTML",
  "H06-D-G2P-L10-METRIC011 transition",
  "current H06_daily worker handoff",
  "resolved shared METRIC-011 request",
  rep("executed or reproducibility code", length(code_paths)),
  "focused METRIC-011 verification test",
  "production input manifest",
  "production code manifest",
  "production output manifest",
  "production software manifest",
  rep("durable METRIC-011 output", length(output_paths))
)
report_output <- paste0(
  "audit/hypotheses/H06_daily/",
  "H06_daily_l10_metric011_report_manifest.csv"
)
report_manifest <- write_manifest(
  report_paths,
  report_roles,
  report_output,
  producer
)

stopifnot(
  nrow(input_manifest) >= 54L,
  nrow(code_manifest) == 11L,
  nrow(output_manifest) >= 50L,
  nrow(software_manifest) == 12L,
  nrow(report_manifest) > nrow(output_manifest),
  all(final_preservation$preserved_byte_for_byte)
)
message(
  "METRIC-011 manifests sealed; ",
  nrow(output_manifest),
  " task-owned outputs and 294 protected files verified."
)
