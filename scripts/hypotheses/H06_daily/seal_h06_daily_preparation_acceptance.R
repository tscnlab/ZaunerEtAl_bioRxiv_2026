#!/usr/bin/env Rscript

# Create the non-circular identity manifest for the author-accepted H06_daily
# preparation companion. This closure performs no scientific computation.

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(tibble)
})

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
.libPaths(c(
  file.path(root, "renv/library/macos/R-4.6/aarch64-apple-darwin23"),
  .libPaths()
))

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("The H06_daily preparation acceptance seal requires R 4.6.1", call. = FALSE)
}

sha256 <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
}

manifest_specs <- tibble::tribble(
  ~relative_path, ~role,
  "audit/hypotheses/H06_daily/H06_daily_stage4_preparation_acceptance.md",
  "Task-local author acceptance and final closure",
  "audit/hypotheses/H06_daily/H06_daily_stage4_preparation_gate.md",
  "Accepted H06-D-G4 review record",
  "audit/hypotheses/H06_daily/H06_daily_analysis_preparation.qmd",
  "Accepted preparation companion source",
  "audit/hypotheses/H06_daily/H06_daily_analysis_preparation.html",
  "Accepted standalone preparation companion HTML",
  "audit/hypotheses/H06_daily/H06_daily_analysis_preparation_report_manifest.csv",
  "Preparation report identity manifest",
  "artifacts/12_manifests/H06_daily/H06_daily_preparation_source_data_manifest.csv",
  "Preparation source-data identity manifest",
  "artifacts/12_manifests/H06_daily/H06_daily_preparation_software_manifest.csv",
  "Preparation software manifest",
  "artifacts/12_manifests/H06_daily/H06_daily_preparation_figure_readability_qa.csv",
  "Preparation figure readability and source-data QA",
  "artifacts/12_manifests/H06_daily/H06_daily_preparation_render_qa.csv",
  "Preparation rendered-DOM QA",
  "artifacts/12_manifests/H06_daily/H06_daily_preparation_output_manifest.csv",
  "Preparation non-circular output manifest",
  "scripts/hypotheses/H06_daily/build_h06_daily_preparation_artifacts.R",
  "Bounded preparation source-data and figure builder",
  "scripts/hypotheses/H06_daily/seal_h06_daily_preparation.R",
  "Preparation provenance sealer",
  "scripts/hypotheses/H06_daily/seal_h06_daily_preparation_acceptance.R",
  "Preparation acceptance manifest sealer",
  "tests/hypotheses/H06_daily/test_h06_daily_preparation_report.R",
  "Focused preparation report verifier",
  "tests/hypotheses/H06_daily/test_h06_daily_preparation_acceptance.R",
  "Focused author-acceptance identity verifier",
  "audit/hypotheses/H06_daily/H06_daily_stage3_acceptance_stage4_transition.md",
  "Task-local Stage 3 acceptance and bounded Stage 4 transition",
  "notebooks/hypotheses/H06_daily.qmd",
  "Accepted complementary results-report source",
  "notebooks/hypotheses/H06_daily.html",
  "Accepted complementary results-report HTML",
  "audit/hypotheses/H06_daily/H06_daily_stage3_revision_gate.md",
  "Accepted complementary results-report gate record"
)

absolute_paths <- file.path(root, manifest_specs$relative_path)
missing <- manifest_specs$relative_path[!file.exists(absolute_paths)]
if (length(missing)) {
  stop(
    paste("Missing H06_daily acceptance input:", paste(missing, collapse = ", ")),
    call. = FALSE
  )
}

manifest <- manifest_specs |>
  transform(
    sha256 = vapply(absolute_paths, sha256, character(1L)),
    bytes = as.numeric(file.info(absolute_paths)$size),
    producer = paste0(
      "scripts/hypotheses/H06_daily/",
      "seal_h06_daily_preparation_acceptance.R"
    ),
    r_version = as.character(getRversion()),
    closure_status = "AUTHOR_ACCEPTED_CLOSED",
    closed_gate = "H06-D-G4"
  ) |>
  tibble::as_tibble() |>
  select(
    "relative_path", "sha256", "bytes", "role", "producer", "r_version",
    "closure_status", "closed_gate"
  )

manifest_relative <- paste0(
  "artifacts/12_manifests/H06_daily/",
  "H06_daily_preparation_acceptance_manifest.csv"
)
stopifnot(
  nrow(manifest) == 19L,
  !anyDuplicated(manifest$relative_path),
  !manifest_relative %in% manifest$relative_path
)
readr::write_csv(manifest, file.path(root, manifest_relative), na = "")

message(
  "H06_daily preparation acceptance sealed: ",
  nrow(manifest),
  " non-circular identities; H06-D-G4 closed."
)
