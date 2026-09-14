#!/usr/bin/env Rscript

# Seal a non-circular navigation-integration completion package for an
# independent Harmonizer review.

options(stringsAsFactors = FALSE, warn = 2)
suppressPackageStartupMessages({
  library(openssl)
  library(readr)
})

stopifnot(identical(as.character(getRversion()), "4.6.1"))

project_root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
setwd(project_root)
source(
  file.path(
    project_root,
    "scripts/report_harmonization/navigation_integration_support.R"
  ),
  local = TRUE
)

evidence_dir <- file.path(project_root, nav_integration_evidence_rel)
checks <- readr::read_csv(
  file.path(evidence_dir, "postflight_checks_final.csv"),
  show_col_types = FALSE
)
stopifnot(nrow(checks) == 10L, all(checks$pass))

completion_path <- file.path(
  evidence_dir,
  "navigation_integration_completion.md"
)
manifest_path <- file.path(
  evidence_dir,
  "navigation_integration_completion_manifest.csv"
)
stopifnot(!file.exists(completion_path), !file.exists(manifest_path))

corpus <- readr::read_csv(
  "audit/report_harmonization/phase4_corpus_manifest.csv",
  show_col_types = FALSE
)
promotion <- readr::read_csv(
  file.path(evidence_dir, "promotion_execution.csv"),
  show_col_types = FALSE
)
reseal <- readr::read_csv(
  file.path(evidence_dir, "manifest_reseal_execution.csv"),
  show_col_types = FALSE
)
historical_path <- file.path(
  evidence_dir,
  "historical_phase4_corpus_manifest_pre.csv"
)

completion <- paste0(
  "# Nature Health navigation integration completion\n\n",
  "Status: sealed for independent Harmonizer acceptance\n\n",
  "The approved navigation shell was integrated without rendering any ",
  "research QMD. Exactly 37 existing reader HTML files and three new shared ",
  "CSS files were promoted in one execution. The historical phase-4 manifest ",
  "is preserved in this evidence root, and the live 37-row manifest was ",
  "resealed exactly once with the accepted source baseline retained. Live ",
  "concurrent hypothesis-QMD hashes are checkpointed separately and are not ",
  "claimed to be rendered by this corpus manifest.\n\n",
  "- Routes: 37/37\n",
  "- Preregistration anchors: 86/86\n",
  "- gt tables: 572\n",
  "- Figures: 160\n",
  "- Build members: 1,183, comprising 874 files and 309 directories\n",
  "- Build symlinks: 0\n",
  "- Promotion executions: ", promotion$execution_count[[1L]], "\n",
  "- Navigation manifest resealer executions: ",
  reseal$resealer_execution_count[[1L]], "\n",
  "- Accepted source hashes retained: ",
  reseal$historical_source_hashes_retained[[1L]], "/37\n",
  "- Authorized live source-only drift paths at reseal: ",
  reseal$authorized_source_drift_paths[[1L]], "\n",
  "- Historical manifest SHA-256: ", nav_sha256_file(historical_path), "\n",
  "- Rebuilt manifest SHA-256: ",
  nav_sha256_file("audit/report_harmonization/phase4_corpus_manifest.csv"),
  "\n",
  "- R: ", as.character(getRversion()), "\n"
)
nav_write_text_atomic(completion, completion_path)

evidence_members <- sort(list.files(
  evidence_dir,
  recursive = TRUE,
  full.names = TRUE,
  all.files = TRUE,
  include.dirs = FALSE,
  no.. = TRUE
))
evidence_members <- setdiff(evidence_members, manifest_path)
members <- unique(c(
  file.path(project_root, corpus$source),
  file.path(project_root, corpus$expected_html),
  file.path(project_root, "_build/nathealth", names(nav_candidate_asset_hashes)),
  file.path(project_root, c(
    "_quarto-nathealth.yml",
    "styles-nathealth.css",
    "_includes/nathealth-mobile-toc.html",
    "audit/report_harmonization/phase4_corpus_manifest.csv",
    "scripts/report_harmonization/navigation_integration_support.R",
    "scripts/report_harmonization/capture_navigation_integration_preflight.R",
    "scripts/report_harmonization/build_navigation_shell_candidate.R",
    "scripts/report_harmonization/check_navigation_candidate.R",
    "scripts/report_harmonization/seal_navigation_candidate_production_boundary.R",
    "scripts/report_harmonization/promote_navigation_candidate_once.R",
    "scripts/report_harmonization/reseal_navigation_manifest_once.R",
    "scripts/report_harmonization/check_navigation_integration_postflight.R",
    "scripts/report_harmonization/seal_navigation_integration_acceptance.R",
    "renv.lock"
  )),
  evidence_members
))
stopifnot(
  !manifest_path %in% members,
  !anyDuplicated(members),
  all(file.exists(members)),
  !any(dir.exists(members)),
  !any(nzchar(Sys.readlink(members)))
)
completion_manifest <- data.frame(
  path = vapply(members, nav_relative_to, character(1), root = project_root),
  sha256 = vapply(members, nav_sha256_file, character(1)),
  bytes = vapply(members, nav_file_bytes, numeric(1)),
  stringsAsFactors = FALSE
)
readr::write_csv(completion_manifest, manifest_path)

replay <- readr::read_csv(manifest_path, show_col_types = FALSE)
stopifnot(
  nrow(replay) == nrow(completion_manifest),
  !anyDuplicated(replay$path),
  !nav_relative_to(manifest_path, project_root) %in% replay$path,
  all(file.exists(file.path(project_root, replay$path))),
  all(vapply(
    file.path(project_root, replay$path),
    nav_sha256_file,
    character(1)
  ) == replay$sha256),
  all(vapply(
    file.path(project_root, replay$path),
    nav_file_bytes,
    numeric(1)
  ) == replay$bytes)
)

cat(sprintf(
  paste0(
    "NAVIGATION_INTEGRATION_SEAL=PASS members=%d manifest_sha256=%s ",
    "completion_sha256=%s R=%s\n"
  ),
  nrow(replay),
  nav_sha256_file(manifest_path),
  nav_sha256_file(completion_path),
  as.character(getRversion())
))
