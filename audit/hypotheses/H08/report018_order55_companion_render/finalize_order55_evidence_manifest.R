#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE, warn = 2)

stop_unless <- function(value, message) {
  if (!isTRUE(value)) stop(message, call. = FALSE)
}

stop_unless(
  identical(as.character(getRversion()), "4.6.1"),
  sprintf("R 4.6.1 required, found %s", getRversion())
)

suppressPackageStartupMessages(library(digest))

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
setwd(root)

evidence_relative <-
  "audit/hypotheses/H08/report018_order55_companion_render"
evidence_dir <- file.path(root, evidence_relative)
manifest_relative <- file.path(
  evidence_relative,
  "order55_evidence_manifest.csv"
)
manifest_path <- file.path(root, manifest_relative)

sha256_file <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
}

as_manifest_path <- function(path) {
  normalized <- normalizePath(path, winslash = "/", mustWork = TRUE)
  prefix <- paste0(root, "/")
  if (startsWith(normalized, prefix)) {
    substring(normalized, nchar(prefix) + 1L)
  } else {
    normalized
  }
}

evidence_files <- list.files(
  evidence_dir,
  all.files = TRUE,
  full.names = TRUE,
  recursive = FALSE,
  include.dirs = FALSE,
  no.. = TRUE
)
evidence_files <- evidence_files[
  normalizePath(evidence_files, winslash = "/", mustWork = FALSE) !=
    normalizePath(manifest_path, winslash = "/", mustWork = FALSE)
]

controlling_files <- file.path(root, c(
  "audit/report_harmonization/owner_orders/55_h08_companion_report018_render.md",
  "audit/report_harmonization/report018_h08_companion_order55_dispatch_manifest.csv",
  "audit/report_harmonization/report018_h08_companion_release.md",
  "audit/report_harmonization/report018_h08_companion_release_manifest.csv",
  "audit/report_harmonization/report018_h08_companion_release_pins.csv",
  "audit/report_harmonization/report018_h08_companion_release_verification.csv",
  "scripts/report_harmonization/check_h08_companion_report018_release.R",
  "audit/report_harmonization/report018_h08_result_independent_acceptance.md",
  "audit/report_harmonization/report018_h08_result_independent_acceptance_manifest.csv",
  "audit/report_harmonization/report018_h08_result_independent_verification.csv"
))

source_held_and_build_files <- file.path(root, c(
  "audit/hypotheses/H08/H08_analysis_preparation.qmd",
  "_build/nathealth/audit/hypotheses/H08/H08_analysis_preparation.qmd",
  "_build/nathealth/audit/hypotheses/H08/H08_analysis_preparation.html",
  "notebooks/hypotheses/H08.qmd",
  "_build/nathealth/notebooks/hypotheses/H08.html",
  "_build/nathealth/search.json",
  "_build/nathealth/sitemap.xml",
  "_quarto-nathealth.yml",
  "scripts/hypotheses/H08/build_h08_preparation_report_manifest.R",
  "tests/hypotheses/H08/test_h08_preparation_report.R",
  "tests/hypotheses/H08/test_h08_stage3_reader_report.R",
  "artifacts/12_manifests/H08/H08_preparation_report_manifest.csv",
  "artifacts/12_manifests/H08/H08_stage3_artifacts.csv",
  "artifacts/12_manifests/H08/H08_figure_manifest.csv",
  "artifacts/12_manifests/H08/H08_figure_physical_size_qa.csv",
  "audit/handoffs/H08_worker_handoff.md",
  "scripts/report_harmonization/post_render_gt_html_semantics.R",
  "scripts/report_harmonization/repair_gt_html_semantics.R",
  "audit/report_harmonization/phase4_corpus_manifest.csv",
  "notebooks/preregistration_deviations.qmd",
  "renv.lock"
))

source_data_files <- file.path(root, c(
  "artifacts/11_source_data/H08/H08_preparation_sample_support.csv",
  "artifacts/11_source_data/H08/H08_preparation_vlsq_score_distribution.csv",
  "artifacts/11_source_data/H08/H08_preparation_vlsq_site_support.csv",
  "artifacts/11_source_data/H08/H08_preparation_site_support.csv",
  "artifacts/11_source_data/H08/H08_preparation_site_support_summary.csv",
  "artifacts/11_source_data/H08/H08_preparation_metric_availability.csv"
))

target_and_physical_figure_files <- file.path(root, c(
  "_build/nathealth/audit/hypotheses/H08/H08_analysis_preparation_files/figure-html/fig-h08-prep-vlsq-distribution-1.png",
  "_build/nathealth/audit/hypotheses/H08/H08_analysis_preparation_files/figure-html/fig-h08-prep-sample-support-1.png",
  "_build/nathealth/audit/hypotheses/H08/H08_analysis_preparation_files/figure-html/fig-h08-prep-site-range-1.png",
  "artifacts/12_manifests/H08/physical_size_qa/fig-h08-prep-vlsq-distribution_A4_170mm.png",
  "artifacts/12_manifests/H08/physical_size_qa/fig-h08-prep-sample-support_A4_170mm.png",
  "artifacts/12_manifests/H08/physical_size_qa/fig-h08-prep-site-range_A4_170mm.png"
))

external_semantic_files <- c(
  "/private/tmp/H08-order55-semantic.yNe1KK/001__build__nathealth__audit__hypotheses__H08__H08_analysis_preparation.html_gt_semantic_ledger.csv",
  "/private/tmp/H08-order55-semantic.yNe1KK/gt_html_semantic_post_render_summary.csv"
)

groups <- list(
  order55_evidence = evidence_files,
  controlling = controlling_files,
  source_held_and_build = source_held_and_build_files,
  frozen_source_data = source_data_files,
  target_and_physical_figures = target_and_physical_figure_files,
  external_semantic = external_semantic_files
)

all_files <- unlist(groups, use.names = FALSE)
missing <- all_files[!file.exists(all_files)]
stop_unless(
  !length(missing),
  sprintf("Missing manifest input: %s", paste(missing, collapse = ", "))
)

manifest <- do.call(
  rbind,
  lapply(names(groups), function(scope) {
    paths <- groups[[scope]]
    data.frame(
      scope = scope,
      path = vapply(paths, as_manifest_path, character(1)),
      sha256 = vapply(paths, sha256_file, character(1)),
      bytes = unname(file.info(paths)$size),
      stringsAsFactors = FALSE
    )
  })
)

manifest <- manifest[order(manifest$scope, manifest$path), , drop = FALSE]
rownames(manifest) <- NULL

stop_unless(!anyDuplicated(manifest$path), "Manifest paths are not unique")
stop_unless(
  !manifest_relative %in% manifest$path,
  "Evidence manifest must not contain itself"
)

utils::write.csv(
  manifest,
  manifest_path,
  row.names = FALSE,
  na = "",
  fileEncoding = "UTF-8"
)

readback <- utils::read.csv(
  manifest_path,
  stringsAsFactors = FALSE,
  check.names = FALSE
)
stop_unless(
  isTRUE(all.equal(readback, manifest, check.attributes = FALSE)),
  "Manifest readback values differ"
)
stop_unless(!anyDuplicated(readback$path), "Readback paths are not unique")
stop_unless(
  !manifest_relative %in% readback$path,
  "Readback manifest contains itself"
)

resolved <- vapply(readback$path, function(path) {
  if (startsWith(path, "/")) path else file.path(root, path)
}, character(1))
stop_unless(all(file.exists(resolved)), "A sealed path disappeared")
stop_unless(
  identical(
    unname(vapply(resolved, sha256_file, character(1))),
    unname(readback$sha256)
  ),
  "A sealed SHA-256 differs after manifest write"
)
stop_unless(
  identical(as.numeric(file.info(resolved)$size), as.numeric(readback$bytes)),
  "A sealed byte count differs after manifest write"
)

cat(sprintf(
  paste0(
    "ORDER55_EVIDENCE_MANIFEST=PASS rows=%d sha256=%s bytes=%d ",
    "non_circular=TRUE unique=TRUE live_exact=TRUE\n"
  ),
  nrow(readback),
  sha256_file(manifest_path),
  unname(file.info(manifest_path)$size)
))
