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
  "audit/hypotheses/H08/report018_order54_result_render"
evidence_dir <- file.path(root, evidence_relative)
manifest_relative <- file.path(
  evidence_relative,
  "order54_evidence_manifest.csv"
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
  "audit/report_harmonization/owner_orders/54_h08_result_report018_render.md",
  "audit/report_harmonization/report018_h08_order54_dispatch_manifest.csv",
  "audit/report_harmonization/report018_h08_result_release.md",
  "audit/report_harmonization/report018_h08_result_release_manifest.csv",
  "audit/report_harmonization/report018_h08_result_release_pins.csv",
  "scripts/report_harmonization/check_h08_result_report018_release.R",
  "audit/report_harmonization/report018_h07_companion_independent_acceptance.md",
  "audit/report_harmonization/report018_h07_companion_independent_acceptance_manifest.csv",
  "audit/report_harmonization/owner_orders/10_h08.md"
))

source_and_held_files <- file.path(root, c(
  "notebooks/hypotheses/H08.qmd",
  "audit/hypotheses/H08/H08_analysis_preparation.qmd",
  "_quarto-nathealth.yml",
  "_build/nathealth/notebooks/hypotheses/H08.html",
  "_build/nathealth/audit/hypotheses/H08/H08_analysis_preparation.html",
  "_build/nathealth/search.json",
  "_build/nathealth/sitemap.xml",
  "tests/hypotheses/H08/test_h08_stage3_reader_report.R",
  "tests/hypotheses/H08/test_h08_preparation_report.R",
  "tests/hypotheses/H08/test_h08_stage2.R",
  "tests/hypotheses/H08/test_h08_metric011_reseal.R",
  "artifacts/12_manifests/H08/H08_stage3_artifacts.csv",
  "artifacts/12_manifests/H08/H08_preparation_report_manifest.csv",
  "artifacts/12_manifests/H08/H08_figure_manifest.csv",
  "artifacts/12_manifests/H08/H08_figure_physical_size_qa.csv",
  "audit/handoffs/H08_worker_handoff.md",
  "scripts/report_harmonization/post_render_gt_html_semantics.R",
  "scripts/report_harmonization/repair_gt_html_semantics.R",
  "renv.lock",
  "audit/report_harmonization/phase4_corpus_manifest.csv",
  "notebooks/preregistration_deviations.qmd"
))

figure_files <- file.path(root, c(
  "artifacts/10_figures/H08/H08_near_eye_effects.png",
  "artifacts/10_figures/H08/H08_chest_effects.png",
  "artifacts/10_figures/H08/H08_paired_placement_effects.png",
  "artifacts/10_figures/H08/H08_near_eye_model_adequacy.png",
  "artifacts/10_figures/H08/H08_gap_common_sample_effects.png",
  "artifacts/12_manifests/H08/physical_size_qa/fig-h08-near-eye-effects_A4_170mm.png",
  "artifacts/12_manifests/H08/physical_size_qa/fig-h08-chest-effects_A4_170mm.png",
  "artifacts/12_manifests/H08/physical_size_qa/fig-h08-paired-placement_A4_170mm.png",
  "artifacts/12_manifests/H08/physical_size_qa/fig-h08-model-adequacy_A4_170mm.png",
  "artifacts/12_manifests/H08/physical_size_qa/fig-h08-gap-common-sample_A4_170mm.png"
))

external_semantic_files <- c(
  "/private/tmp/H08-order54-semantic.XXQVYp/001__build__nathealth__notebooks__hypotheses__H08.html_gt_semantic_ledger.csv",
  "/private/tmp/H08-order54-semantic.XXQVYp/gt_html_semantic_post_render_summary.csv"
)

groups <- list(
  order54_evidence = evidence_files,
  controlling = controlling_files,
  source_held_and_build = source_and_held_files,
  scientific_figures_and_physical_proofs = figure_files,
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
  "ORDER54_EVIDENCE_MANIFEST=PASS rows=%d sha256=%s bytes=%d non_circular=TRUE unique=TRUE\n",
  nrow(readback),
  sha256_file(manifest_path),
  unname(file.info(manifest_path)$size)
))
