# Reconcile the H01 reader-facing deviation table with REPORT-016.
#
# This script changes text and central-ID aliases only. It must not fit,
# predict, bootstrap, or otherwise recalculate an H01 scientific result.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
source(file.path(root, "scripts/pipeline/paths_io.R"))

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("REPORT-016 reconciliation requires R 4.6.1", call. = FALSE)
}

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(tibble)
})

producer <- "scripts/hypotheses/H01/reconcile_h01_report016_deviations.R"
target_relative <-
  "artifacts/09_tables/H01/stage3/H01_stage3_deviations.csv"
target_path <- file.path(root, target_relative)
stage3_manifest_relative <-
  "artifacts/12_manifests/H01_stage3_reporting_artifacts.csv"
stage3_manifest_path <- file.path(root, stage3_manifest_relative)
reporting_manifest_relative <-
  "artifacts/12_manifests/H01_reporting_artifacts.csv"
reporting_manifest_path <- file.path(root, reporting_manifest_relative)
audit_relative <- "audit/hypotheses/H01/report016"
audit_root <- file.path(root, audit_relative)
dir.create(audit_root, recursive = TRUE, showWarnings = FALSE)

archive_relative <- file.path(
  audit_relative,
  "H01_stage3_deviations_pre_REPORT016.csv"
)
archive_path <- file.path(root, archive_relative)
mapping_relative <- file.path(
  audit_relative,
  "H01_REPORT016_local_id_mapping.csv"
)
mapping_path <- file.path(root, mapping_relative)
row_reconciliation_relative <- file.path(
  audit_relative,
  "H01_REPORT016_row_reconciliation.csv"
)
row_reconciliation_path <- file.path(root, row_reconciliation_relative)
protected_relative <- file.path(
  audit_relative,
  "H01_REPORT016_protected_scientific_artifacts.csv"
)
protected_path <- file.path(root, protected_relative)
pre_identities_relative <- file.path(
  audit_relative,
  "H01_REPORT016_pre_correction_identities.csv"
)
pre_identities_path <- file.path(root, pre_identities_relative)
report_relative <- file.path(
  audit_relative,
  "H01_REPORT016_deviation_reconciliation.md"
)
report_path <- file.path(root, report_relative)
manifest_relative <- file.path(
  audit_relative,
  "H01_REPORT016_reconciliation_manifest.csv"
)
manifest_path <- file.path(root, manifest_relative)

expected_archive_sha256 <-
  "ecbf772d084582c643e1ee4523a8171db419d4e998f5d846ea34228238a6f709"

if (!file.exists(archive_path)) {
  if (!identical(artifact_sha256(target_path), expected_archive_sha256)) {
    stop(
      "The accepted pre-correction deviation table does not match its pin",
      call. = FALSE
    )
  }
  if (!file.copy(target_path, archive_path, overwrite = FALSE)) {
    stop("Could not preserve the pre-correction deviation table", call. = FALSE)
  }
}
if (!identical(artifact_sha256(archive_path), expected_archive_sha256)) {
  stop("The preserved pre-correction table does not match its pin", call. = FALSE)
}

read_table <- function(path) {
  readr::read_csv(path, show_col_types = FALSE, progress = FALSE)
}

before <- read_table(archive_path)
required_columns <- c(
  "deviation_ids",
  "topic",
  "registered_or_expected",
  "analysis_used"
)
if (!identical(names(before), required_columns)) {
  stop("Unexpected deviation-table columns", call. = FALSE)
}

after <- before
replace_row <- function(
  original_ids,
  deviation_ids = NULL,
  topic = NULL,
  registered_or_expected = NULL,
  analysis_used = NULL
) {
  index <- which(before$deviation_ids == original_ids)
  if (length(index) != 1L) {
    stop("Expected exactly one row for: ", original_ids, call. = FALSE)
  }
  values <- list(
    deviation_ids = deviation_ids,
    topic = topic,
    registered_or_expected = registered_or_expected,
    analysis_used = analysis_used
  )
  for (field in names(values)) {
    if (!is.null(values[[field]])) {
      after[[field]][index] <<- values[[field]]
    }
  }
  invisible(index)
}

replace_row(
  "DEV-008; DEV-054",
  analysis_used = paste(
    "The registered midpoint of the longest qualifying period is retained.",
    "Mean timing above 250 lx melEDI is a distinct circular",
    "duration-weighted metric and is labelled as an adapted sensitivity;",
    "period construction follows verified continuity and support rules."
  )
)
replace_row(
  "DEV-018; H01-005",
  deviation_ids = "DEV-018"
)
replace_row(
  "IMP-001; H01-001; H01-006",
  deviation_ids = "IMP-001; DEV-009"
)
replace_row(
  "H01-002",
  deviation_ids = "DEV-009"
)
replace_row(
  "IMP-004; H01-003; H01-004",
  deviation_ids = "IMP-003; IMP-004",
  topic = "Variation, uncertainty, and exact samples",
  registered_or_expected = paste(
    "Conditional R² and significance-dependent component summaries were",
    "used without joint interval estimation or exact model-specific sample",
    "reporting."
  ),
  analysis_used = paste(
    "Marginal and conditional R², participant-associated share, and",
    "non-overlapping term part-R² summaries use 1,000 successful joint",
    "bootstrap refits and 95% intervals; exact model-specific samples are",
    "reported."
  )
)
replace_row(
  "IMP-013; DEV-051",
  deviation_ids = "DEV-058",
  registered_or_expected = paste(
    "The submitted implementation averaged available momentary",
    "melEDI-to-photopic-illuminance ratios; the preregistration did not",
    "specify a ratio-of-integrals replacement."
  ),
  analysis_used = paste(
    "MDER is the arithmetic mean of viable one-minute",
    "melEDI-to-photopic-illuminance ratios. Both channels must be finite and",
    "strictly positive, and at least 720 viable minutes are required on the",
    "complete 1,440-minute local wall-clock grid."
  )
)
replace_row(
  "DEV-057",
  registered_or_expected = paste(
    "The preregistration and submitted implementation use coverage and",
    "signal-validity rules but do not specify exclusion of an otherwise",
    "eligible complete exact-zero melEDI day."
  ),
  analysis_used = paste(
    "An otherwise eligible participant-day is excluded only when every",
    "finite one-minute melEDI value is exactly 0 lx; individual zeros remain",
    "valid and the former inclusion is retained as a fixed data sensitivity."
  )
)
replace_row(
  "H01-007; IMP-024",
  deviation_ids = "IMP-024"
)
replace_row(
  "H01-008; IMP-023",
  deviation_ids = "IMP-023"
)

changed <- vapply(seq_len(nrow(before)), function(index) {
  !identical(before[index, , drop = FALSE], after[index, , drop = FALSE])
}, logical(1))
if (!identical(sum(changed), 9L)) {
  stop("REPORT-016 must change exactly nine deviation-table rows", call. = FALSE)
}
if (any(grepl("\\bH01-00[1-8]\\b", after$deviation_ids))) {
  stop("A local H01-001 through H01-008 alias remains", call. = FALSE)
}

central_register <- read_table(
  file.path(root, "audit/ledgers/deviation_register.csv")
)
display_ids <- trimws(unlist(strsplit(after$deviation_ids, ";", fixed = TRUE)))
unknown_ids <- setdiff(unique(display_ids), central_register$deviation_id)
if (length(unknown_ids) > 0L) {
  stop(
    "Reconciled table contains noncentral IDs: ",
    paste(unknown_ids, collapse = ", "),
    call. = FALSE
  )
}

local_mapping <- tibble::tribble(
  ~local_id, ~proposed_central_ids, ~owner_disposition, ~mapping_basis,
  "H01-001", "IMP-001", "editorial alias; no new central record requested",
  "The local decision defines H01's complete vector-wide multiplicity implementation; IMP-001 is the central H01 multiplicity repair.",
  "H01-002", "DEV-009", "editorial detail; no new central record requested",
  "The hierarchical site localization is a secondary follow-up to the supported overall site question in the accepted H01 model and does not define a new primary model or family.",
  "H01-003", "IMP-004", "editorial alias; no new central record requested",
  "The local decision repairs H01 variation summaries; IMP-004 is the central H01 model-R² repair.",
  "H01-004", "IMP-003|IMP-004", "editorial detail; no new central record requested",
  "The local decision joins joint uncertainty for H01 model summaries with exact model-specific samples; IMP-004 and IMP-003 are the corresponding central records.",
  "H01-005", "DEV-018", "editorial alias; no new central record requested",
  "The local response-family package is the implementation governed by the central H01 response-model deviation.",
  "H01-006", "DEV-009|IMP-001", "editorial detail; no new central record requested",
  "The formal same-frame adequacy comparison is the fourth complete H01 family and therefore belongs to the central H01 model and multiplicity records.",
  "H01-007", "IMP-024", "editorial alias; no new central record requested",
  "The local calendar-day pre-sleep decision is the source decision for central record IMP-024.",
  "H01-008", "IMP-023", "editorial alias; no new central record requested",
  "The local strict-after-16:00 L10 midpoint decision is the source decision for central record IMP-023."
) |>
  mutate(
    local_source = case_when(
      local_id %in% sprintf("H01-%03d", 1:4) ~
        "audit/decisions/h01_model_specification.md",
      local_id %in% c("H01-005", "H01-006") ~
        "audit/decisions/h01_prefit_gate.md",
      TRUE ~ "audit/decisions/h01_gate_resolution.md"
    ),
    coordinator_action = paste(
      "Confirm this owner mapping in the REPORT-016 crosswalk before",
      "releasing dynamic deviation-page links."
    ),
    .after = proposed_central_ids
  )

if (!identical(local_mapping$local_id, sprintf("H01-%03d", 1:8))) {
  stop("The local-ID mapping is incomplete or out of order", call. = FALSE)
}

authority <- case_when(
  before$deviation_ids == "DEV-008; DEV-054" ~
    "DEV-008|DEV-054; audit/decisions/metric_implementation_parameters.md",
  before$deviation_ids == "DEV-018; H01-005" ~
    "DEV-018; audit/decisions/h01_prefit_gate.md",
  before$deviation_ids == "IMP-001; H01-001; H01-006" ~
    "IMP-001|DEV-009; audit/decisions/h01_model_specification.md",
  before$deviation_ids == "H01-002" ~
    "DEV-009; audit/decisions/h01_model_specification.md",
  before$deviation_ids == "IMP-004; H01-003; H01-004" ~
    "IMP-003|IMP-004; audit/decisions/h01_model_specification.md",
  before$deviation_ids == "IMP-013; DEV-051" ~
    "DEV-058|METRIC-010; audit/decisions/mder_mean_of_viable_ratios.md",
  before$deviation_ids == "DEV-057" ~
    "DEV-057; audit/decisions/all_zero_medi_day_exclusion.md",
  before$deviation_ids == "H01-007; IMP-024" ~
    "IMP-024; audit/decisions/h01_gate_resolution.md",
  before$deviation_ids == "H01-008; IMP-023" ~
    "IMP-023; audit/decisions/h01_gate_resolution.md",
  TRUE ~ NA_character_
)

row_reconciliation <- tibble::tibble(
  row_number = which(changed),
  before_deviation_ids = before$deviation_ids[changed],
  after_deviation_ids = after$deviation_ids[changed],
  before_topic = before$topic[changed],
  after_topic = after$topic[changed],
  before_registered_or_expected = before$registered_or_expected[changed],
  after_registered_or_expected = after$registered_or_expected[changed],
  before_analysis_used = before$analysis_used[changed],
  after_analysis_used = after$analysis_used[changed],
  authoritative_record = authority[changed]
)
if (anyNA(row_reconciliation$authoritative_record)) {
  stop("A changed row lacks an authoritative record", call. = FALSE)
}

protected_roots <- file.path(
  root,
  c(
    "artifacts/07_models/H01",
    "artifacts/08_diagnostics/H01",
    "artifacts/09_tables/H01",
    "artifacts/10_figures/H01",
    "artifacts/11_source_data/H01"
  )
)
protected_files <- sort(unique(unlist(lapply(
  protected_roots[dir.exists(protected_roots)],
  list.files,
  recursive = TRUE,
  full.names = TRUE
))))
protected_files <- protected_files[
  file.exists(protected_files) &
    !dir.exists(protected_files) &
    normalizePath(protected_files, winslash = "/", mustWork = TRUE) !=
      normalizePath(target_path, winslash = "/", mustWork = TRUE)
]
protected_now <- tibble::tibble(
  path = substring(
    normalizePath(protected_files, winslash = "/", mustWork = TRUE),
    nchar(root) + 2L
  ),
  sha256 = vapply(protected_files, artifact_sha256, character(1)),
  bytes = as.numeric(file.info(protected_files)$size)
)
if (file.exists(protected_path)) {
  protected_pinned <- read_table(protected_path)
  protected_match <-
    identical(names(protected_pinned), names(protected_now)) &&
    nrow(protected_pinned) == nrow(protected_now) &&
    all(protected_pinned$path == protected_now$path) &&
    all(protected_pinned$sha256 == protected_now$sha256) &&
    all(protected_pinned$bytes == protected_now$bytes)
  if (!protected_match) {
    stop("A protected H01 scientific artifact changed", call. = FALSE)
  }
} else {
  invisible(write_csv_artifact(
    protected_now,
    protected_path,
    producer = producer
  ))
}

pre_identities <- tibble::tribble(
  ~path, ~sha256, ~bytes,
  target_relative,
  expected_archive_sha256, 5307,
  "notebooks/hypotheses/H01.qmd",
  "8c7ca4e7382b1f9cc5fe07bb9cdf8a1318fd6e311f7df4e86556ae3e390abe96", 87441,
  "audit/hypotheses/H01/H01_analysis_preparation.qmd",
  "685641fcb163e55b96b34778f25b276d8ce289bacd0ad73ece4351d859ebb4cb", 54286,
  "_build/nathealth/notebooks/hypotheses/H01.html",
  "53a216ff0ae82b2e9177671d6330862832c1c5f2a9e79251e0da0acb5671260f", 1351940,
  stage3_manifest_relative,
  "12599e3b307bba9aa042697fe304e68a95cdf161fa9d297197f00abfb3bb0ada", 22735,
  reporting_manifest_relative,
  "79e68e3676e7862e596495584e4bd8900b9bffd7f1778a8cfcbe2eef696baa79", 11054,
  "artifacts/12_manifests/H01_worker_artifacts.csv",
  "b2b1a38dc0538d46e0c630b5a55c6d4fea86be0d970d8fa37f473d2be085ebcd", 388963,
  "scripts/hypotheses/H01/build_h01_stage3_reporting_inputs.R",
  "294789e6716910d45e9a00f4bb955d6793f12a81320e75595500465379e036be", 67604
)

unchanged_report_paths <- pre_identities |>
  filter(path %in% c(
    "notebooks/hypotheses/H01.qmd",
    "audit/hypotheses/H01/H01_analysis_preparation.qmd",
    "_build/nathealth/notebooks/hypotheses/H01.html"
  ))
for (index in seq_len(nrow(unchanged_report_paths))) {
  candidate <- file.path(root, unchanged_report_paths$path[[index]])
  if (!identical(
    artifact_sha256(candidate),
    unchanged_report_paths$sha256[[index]]
  )) {
    stop(
      "A held H01 source/report identity changed during reconciliation: ",
      unchanged_report_paths$path[[index]],
      call. = FALSE
    )
  }
}

invisible(write_csv_artifact(local_mapping, mapping_path, producer = producer))
invisible(write_csv_artifact(
  row_reconciliation,
  row_reconciliation_path,
  producer = producer
))
invisible(write_csv_artifact(
  pre_identities,
  pre_identities_path,
  producer = producer
))
invisible(write_csv_artifact(after, target_path, producer = producer))

protected_after <- protected_now |>
  mutate(
    current_sha256 = vapply(
      file.path(root, .data$path),
      artifact_sha256,
      character(1)
    ),
    current_bytes = as.numeric(file.info(file.path(root, .data$path))$size)
  )
if (!all(
  protected_after$sha256 == protected_after$current_sha256 &
    protected_after$bytes == protected_after$current_bytes
)) {
  stop("Scientific-artifact preservation failed after table write", call. = FALSE)
}

refresh_manifest_rows <- function(manifest_path, relative_paths) {
  manifest <- read_table(manifest_path)
  for (relative_path in relative_paths) {
    index <- which(manifest$path == relative_path)
    if (length(index) != 1L) {
      stop(
        "Manifest lacks exactly one row for: ",
        relative_path,
        call. = FALSE
      )
    }
    artifact_path <- file.path(root, relative_path)
    manifest$sha256[[index]] <- artifact_sha256(artifact_path)
    manifest$bytes[[index]] <- as.numeric(file.info(artifact_path)$size)
  }
  invisible(write_csv_artifact(manifest, manifest_path, producer = producer))
}

refresh_manifest_rows(
  stage3_manifest_path,
  c(
    target_relative,
    "notebooks/hypotheses/H01.qmd",
    "audit/hypotheses/H01/H01_analysis_preparation.qmd",
    "scripts/hypotheses/H01/build_h01_stage3_reporting_inputs.R"
  )
)
refresh_manifest_rows(
  reporting_manifest_path,
  c(
    "notebooks/hypotheses/H01.qmd",
    "audit/hypotheses/H01/H01_analysis_preparation.qmd"
  )
)

post_identities <- tibble::tibble(
  path = c(
    target_relative,
    "notebooks/hypotheses/H01.qmd",
    "audit/hypotheses/H01/H01_analysis_preparation.qmd",
    "_build/nathealth/notebooks/hypotheses/H01.html",
    stage3_manifest_relative,
    reporting_manifest_relative,
    "scripts/hypotheses/H01/build_h01_stage3_reporting_inputs.R"
  )
) |>
  mutate(
    sha256 = vapply(file.path(root, .data$path), artifact_sha256, character(1)),
    bytes = as.numeric(file.info(file.path(root, .data$path))$size)
  )

post_lines <- paste0(
  "- `", post_identities$path, "`: `", post_identities$sha256, "` (",
  format(post_identities$bytes, scientific = FALSE, trim = TRUE), " bytes)"
)
report_lines <- c(
  "# H01 REPORT-016 deviation reconciliation",
  "",
  "Date: 2026-08-12  ",
  "Status: H01-owner reconciliation complete; central mapping confirmation and dynamic-link release pending",
  "",
  "## Boundary",
  "",
  paste(
    "This bounded repair changes only the stored H01 deviation display, its",
    "deterministic producer, and audit/manifests that describe the repair."
  ),
  paste(
    "No model, prediction, bootstrap, p-value, FDR value, estimate, interval,",
    "sample, diagnostic, sensitivity result, or claim was recomputed."
  ),
  "",
  "The pre-correction CSV is preserved byte-for-byte at",
  paste0("`", archive_relative, "` with SHA-256 `", expected_archive_sha256, "`."),
  "",
  "## Reconciled scientific wording",
  "",
  paste(
    "The current display now defines MDER under DEV-058/METRIC-010 as the",
    "arithmetic mean of viable momentary one-minute ratios, assigns DEV-057",
    "to the complete exact-zero melEDI-day exclusion, and states that the",
    "registered longest-period midpoint is retained while mean timing is a",
    "separately labelled adapted sensitivity."
  ),
  "",
  paste0(
    "Exact row-level before/after evidence is in `",
    row_reconciliation_relative,
    "`."
  ),
  "",
  "## H01-local decision IDs",
  "",
  paste(
    "All eight H01-local IDs were classified by the H01 scientific owner as",
    "decision-layer aliases or implementation details of existing central",
    "records; no genuinely distinct unresolved deviation was identified."
  ),
  paste0("The explicit proposed mapping is in `", mapping_relative, "`."),
  paste(
    "The coordinator must confirm that mapping before REPORT-016 adds any",
    "dynamic preregistration-deviation link."
  ),
  "",
  "## Preservation evidence",
  "",
  paste0(
    "The protected inventory contains ", nrow(protected_now),
    " non-display H01 scientific artifacts. Every SHA-256 and byte count",
    " matched before and after this repair."
  ),
  paste0("The inventory is `", protected_relative, "`."),
  "",
  "Held source/report identities were not changed. Current identities:",
  "",
  post_lines,
  "",
  "The main report has deliberately not been rendered in this bounded pass.",
  "No dynamic deviation-page link has been added."
)
writeLines(report_lines, report_path, useBytes = TRUE)

manifest_paths <- c(
  archive_relative,
  mapping_relative,
  row_reconciliation_relative,
  protected_relative,
  pre_identities_relative,
  report_relative,
  target_relative,
  stage3_manifest_relative,
  reporting_manifest_relative,
  "notebooks/hypotheses/H01.qmd",
  "audit/hypotheses/H01/H01_analysis_preparation.qmd",
  "_build/nathealth/notebooks/hypotheses/H01.html",
  "scripts/hypotheses/H01/build_h01_stage3_reporting_inputs.R",
  producer,
  "tests/hypotheses/H01/test_h01_report016_deviation_reconciliation.R"
)
manifest <- tibble::tibble(path = manifest_paths) |>
  mutate(
    sha256 = vapply(file.path(root, .data$path), artifact_sha256, character(1)),
    bytes = as.numeric(file.info(file.path(root, .data$path))$size),
    role = case_when(
      path == archive_relative ~ "preserved pre-correction display",
      path == target_relative ~ "reconciled reader display source",
      path == protected_relative ~ "scientific-output preservation inventory",
      path == mapping_relative ~ "local-to-central ID mapping proposal",
      path == row_reconciliation_relative ~ "row-level before/after evidence",
      path == pre_identities_relative ~ "pre-correction identities",
      path == report_relative ~ "reconciliation handoff",
      TRUE ~ "reconciliation dependency or held report"
    ),
    producer = producer,
    r_version = as.character(getRversion())
  )
invisible(write_csv_artifact(manifest, manifest_path, producer = producer))

message(
  "H01 REPORT-016 deviation reconciliation complete: ",
  artifact_sha256(target_path)
)
