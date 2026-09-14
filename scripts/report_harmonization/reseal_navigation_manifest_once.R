#!/usr/bin/env Rscript

# One-time navigation-specific corpus reseal after promotion. The historical
# accepted source identities remain the substantive HTML provenance. Live
# concurrent authoring hashes are recorded separately and are not represented
# as rendered by this manifest.

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
promotion <- readr::read_csv(
  file.path(evidence_dir, "promotion_execution.csv"),
  show_col_types = FALSE
)
production_seal <- readr::read_csv(
  file.path(evidence_dir, "candidate_production_seal.csv"),
  show_col_types = FALSE
)
stopifnot(
  nrow(promotion) == 1L,
  promotion$execution_count == 1L,
  promotion$total_promoted_files == 40L,
  nrow(production_seal) == 1L,
  production_seal$candidate_checks_passed == 11L
)

execution_path <- file.path(evidence_dir, "manifest_reseal_execution.csv")
start_marker <- file.path(evidence_dir, "manifest_reseal_started.txt")
stopifnot(!file.exists(execution_path), !file.exists(start_marker))

manifest_path <- "audit/report_harmonization/phase4_corpus_manifest.csv"
historical_path <- file.path(
  evidence_dir,
  "historical_phase4_corpus_manifest_pre.csv"
)
historical <- readr::read_csv(historical_path, show_col_types = FALSE)
stopifnot(
  nrow(historical) == 37L,
  nav_sha256_file(historical_path) == unname(nav_pinned_identities[[manifest_path]]),
  nav_sha256_file(manifest_path) == nav_sha256_file(historical_path)
)

promotion_manifest <- readr::read_csv(
  file.path(evidence_dir, "candidate_promotion_manifest.csv"),
  show_col_types = FALSE
)
routes <- vapply(historical$expected_html, nav_html_route, character(1))
html_live <- vapply(historical$expected_html, nav_sha256_file, character(1))
candidate_html <- promotion_manifest[
  match(routes, promotion_manifest$path),
  ,
  drop = FALSE
]
stopifnot(
  all(candidate_html$path == routes),
  all(candidate_html$sha256 == html_live),
  all(html_live != historical$html_sha256)
)

allowlist <- nav_load_authorized_source_allowlist(evidence_dir, historical)
source_checkpoint <- nav_live_source_checkpoint(historical, project_root)
source_drift <- nav_source_drift_audit(source_checkpoint, allowlist)
stopifnot(
  all(source_drift$authorized),
  !length(setdiff(source_drift$path, allowlist$path))
)
source_checkpoint$corpus_acceptance_claim <- ifelse(
  source_checkpoint$accepted_source_sha256 == source_checkpoint$live_source_sha256,
  "MATCHES_ACCEPTED_SOURCE_BASELINE",
  "SOURCE_ONLY_NOT_RENDERED_OR_ACCEPTED_BY_THIS_MANIFEST"
)
readr::write_csv(
  source_checkpoint,
  file.path(evidence_dir, "live_authoring_source_checkpoint_manifest_reseal.csv")
)
readr::write_csv(
  source_drift,
  file.path(evidence_dir, "authorized_source_drift_manifest_reseal.csv")
)

resealed <- historical
resealed$html_exists <- file.exists(resealed$expected_html)
resealed$html_sha256 <- html_live
source_columns <- setdiff(names(historical), c("html_exists", "html_sha256"))
stopifnot(
  identical(resealed[source_columns], historical[source_columns]),
  identical(as.integer(resealed$render_position), c(36L, 37L, seq_len(35L))),
  identical(as.integer(resealed$sidebar_position), seq_len(37L))
)

nav_write_text_atomic(
  paste0("started_utc=", format(Sys.time(), tz = "UTC", usetz = TRUE), "\n"),
  start_marker
)
temporary_manifest <- tempfile(
  "phase4_corpus_manifest.",
  tmpdir = dirname(manifest_path),
  fileext = ".csv"
)
on.exit(if (file.exists(temporary_manifest)) unlink(temporary_manifest), add = TRUE)
readr::write_csv(resealed, temporary_manifest)
stopifnot(file.rename(temporary_manifest, manifest_path))

live_manifest <- readr::read_csv(manifest_path, show_col_types = FALSE)
stopifnot(
  nrow(live_manifest) == 37L,
  identical(live_manifest[source_columns], historical[source_columns]),
  all(live_manifest$html_exists),
  all(live_manifest$html_sha256 == html_live),
  !anyDuplicated(live_manifest$source),
  !anyDuplicated(live_manifest$expected_html)
)

transitions <- data.frame(
  logical_order = historical$logical_order,
  source = historical$source,
  expected_html = historical$expected_html,
  historical_source_sha256 = historical$source_sha256,
  live_authoring_source_sha256 = source_checkpoint$live_source_sha256,
  source_matches_accepted_baseline =
    historical$source_sha256 == source_checkpoint$live_source_sha256,
  historical_html_sha256 = historical$html_sha256,
  resealed_html_sha256 = live_manifest$html_sha256,
  live_html_sha256 = html_live,
  html_changed = historical$html_sha256 != live_manifest$html_sha256,
  stringsAsFactors = FALSE
)
readr::write_csv(
  transitions,
  file.path(evidence_dir, "manifest_html_transitions.csv")
)

provenance_statement <- paste0(
  "# Navigation corpus reseal provenance\n\n",
  "The 37 source hashes in `phase4_corpus_manifest.csv` remain the accepted ",
  "source baseline for the substantive HTML bodies. The navigation reseal ",
  "updated only the 37 HTML hashes after the shell-only promotion. Current ",
  "live hypothesis-QMD hashes are recorded separately in ",
  "`live_authoring_source_checkpoint_manifest_reseal.csv`. Any row marked ",
  "`SOURCE_ONLY_NOT_RENDERED_OR_ACCEPTED_BY_THIS_MANIFEST` is authoring work ",
  "in progress and is not claimed to have produced the promoted HTML.\n"
)
nav_write_text_atomic(
  provenance_statement,
  file.path(evidence_dir, "manifest_source_provenance_statement.md")
)

execution <- data.frame(
  resealer_execution_count = 1L,
  rows = nrow(live_manifest),
  unique_sources = length(unique(live_manifest$source)),
  historical_source_hashes_retained = sum(
    live_manifest$source_sha256 == historical$source_sha256
  ),
  live_authoring_source_matches = sum(
    historical$source_sha256 == source_checkpoint$live_source_sha256
  ),
  authorized_source_drift_paths = nrow(source_drift),
  html_hashes_changed = sum(transitions$html_changed),
  html_hashes_live_exact = sum(live_manifest$html_sha256 == html_live),
  historical_manifest_sha256 = nav_sha256_file(historical_path),
  resealed_manifest_sha256 = nav_sha256_file(manifest_path),
  completed_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
  stringsAsFactors = FALSE
)
readr::write_csv(execution, execution_path)

cat(sprintf(
  paste0(
    "NAVIGATION_MANIFEST_RESEAL=PASS executions=1 rows=37 ",
    "accepted_source_hashes_retained=37 live_source_drift=%d ",
    "html_changed=37 html_live_exact=37 sha256=%s\n"
  ),
  nrow(source_drift),
  nav_sha256_file(manifest_path)
))
