#!/usr/bin/env Rscript

# Refresh only the H05 Stage 2 reporting/display identities changed during the
# approved Stage 3 presentation revision. Scientific data, fitted models,
# diagnostics, estimates, and sensitivity tables must retain their hashes.

suppressPackageStartupMessages({
  library(readr)
})

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
source(file.path(root, "scripts/pipeline/paths_io.R"))

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("The H05 Stage 2 reporting manifest requires R 4.6.1", call. = FALSE)
}

producer <-
  "scripts/hypotheses/H05/refresh_h05_stage2_reporting_manifest.R"
manifest_path <- file.path(
  root,
  "artifacts/12_manifests/H05/H05_stage2_artifacts.csv"
)
manifest <- readr::read_csv(manifest_path, show_col_types = FALSE)

expected_columns <- c(
  "path", "artifact_type", "sha256", "bytes", "producer", "r_version",
  "written_utc"
)
if (!identical(names(manifest), expected_columns) || anyDuplicated(manifest$path)) {
  stop("Unexpected H05 Stage 2 manifest schema", call. = FALSE)
}

absolute_paths <- file.path(root, manifest$path)
if (any(!file.exists(absolute_paths))) {
  stop(
    paste0(
      "A Stage 2 manifest path is missing: ",
      paste(manifest$path[!file.exists(absolute_paths)], collapse = ", ")
    ),
    call. = FALSE
  )
}

observed_sha256 <- unname(vapply(
  absolute_paths,
  artifact_sha256,
  character(1)
))
changed <- manifest$path[observed_sha256 != manifest$sha256]

allowed_changed <- c(
  "audit/hypotheses/H05/02_implementation_and_v0_comparison.qmd",
  "audit/hypotheses/H05/02_implementation_and_v0_comparison.html",
  "audit/handoffs/H05_stage2_handoff.md",
  "tests/hypotheses/H05/test_h05_stage2.R",
  "artifacts/10_figures/H05/H05_paired_placement_effects.png",
  "artifacts/10_figures/H05/H05_primary_model_adequacy.png",
  "artifacts/10_figures/H05/H05_v0_chest_corrected.pdf",
  "artifacts/10_figures/H05/H05_v0_chest_corrected.png",
  "artifacts/10_figures/H05/H05_v0_chest_faithful.pdf",
  "artifacts/10_figures/H05/H05_v0_chest_faithful.png",
  "artifacts/10_figures/H05/H05_v0_near_eye_corrected.pdf",
  "artifacts/10_figures/H05/H05_v0_near_eye_corrected.png",
  "artifacts/10_figures/H05/H05_v0_near_eye_faithful.pdf",
  "artifacts/10_figures/H05/H05_v0_near_eye_faithful.png",
  "artifacts/11_source_data/H05/H05_paired_effect_comparison_data.csv"
)
unexpected <- setdiff(changed, allowed_changed)
if (length(unexpected) > 0L) {
  stop(
    paste0(
      "A frozen scientific or unapproved Stage 2 identity changed: ",
      paste(unexpected, collapse = ", ")
    ),
    call. = FALSE
  )
}

required_reporting_changes <- c(
  "audit/hypotheses/H05/02_implementation_and_v0_comparison.html",
  "audit/handoffs/H05_stage2_handoff.md",
  "artifacts/10_figures/H05/H05_paired_placement_effects.png"
)
missing_expected_changes <- setdiff(required_reporting_changes, changed)
if (length(missing_expected_changes) > 0L) {
  stop(
    paste0(
      "Expected H05 reporting revisions are absent: ",
      paste(missing_expected_changes, collapse = ", ")
    ),
    call. = FALSE
  )
}

changed_rows <- match(changed, manifest$path)
manifest$sha256[changed_rows] <- observed_sha256[changed_rows]
manifest$bytes[changed_rows] <- as.numeric(file.info(absolute_paths)$size)[
  changed_rows
]
manifest$producer[changed_rows] <- producer
manifest$r_version[changed_rows] <- as.character(getRversion())
manifest$written_utc[changed_rows] <- format(
  Sys.time(),
  tz = "UTC",
  usetz = TRUE
)

invisible(write_csv_artifact(manifest, manifest_path, producer))
message(
  "H05 Stage 2 reporting manifest refreshed for ",
  length(changed),
  " approved presentation files; all other identities are unchanged"
)
