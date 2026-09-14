# Verify the bounded H01 REPORT-016 deviation reconciliation.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
source(file.path(root, "scripts/pipeline/paths_io.R"))

stopifnot(identical(as.character(getRversion()), "4.6.1"))

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
})

read_table <- function(relative_path) {
  readr::read_csv(
    file.path(root, relative_path),
    show_col_types = FALSE,
    progress = FALSE
  )
}

audit_root <- "audit/hypotheses/H01/report016"
target_relative <-
  "artifacts/09_tables/H01/stage3/H01_stage3_deviations.csv"
archive_relative <- file.path(
  audit_root,
  "H01_stage3_deviations_pre_REPORT016.csv"
)
mapping_relative <- file.path(
  audit_root,
  "H01_REPORT016_local_id_mapping.csv"
)
reconciliation_relative <- file.path(
  audit_root,
  "H01_REPORT016_row_reconciliation.csv"
)
protected_relative <- file.path(
  audit_root,
  "H01_REPORT016_protected_scientific_artifacts.csv"
)
manifest_relative <- file.path(
  audit_root,
  "H01_REPORT016_reconciliation_manifest.csv"
)
stage3_manifest_relative <-
  "artifacts/12_manifests/H01_stage3_reporting_artifacts.csv"
worker_manifest_relative <-
  "artifacts/12_manifests/H01_worker_artifacts.csv"

required_paths <- c(
  target_relative,
  archive_relative,
  mapping_relative,
  reconciliation_relative,
  protected_relative,
  manifest_relative,
  stage3_manifest_relative,
  worker_manifest_relative,
  "notebooks/hypotheses/H01.qmd",
  "audit/hypotheses/H01/H01_analysis_preparation.qmd",
  "_build/nathealth/notebooks/hypotheses/H01.html",
  "scripts/hypotheses/H01/build_h01_stage3_reporting_inputs.R"
)
stopifnot(all(file.exists(file.path(root, required_paths))))

before <- read_table(archive_relative)
after <- read_table(target_relative)
mapping <- read_table(mapping_relative)
reconciliation <- read_table(reconciliation_relative)
protected <- read_table(protected_relative)
manifest <- read_table(manifest_relative)
stage3_manifest <- read_table(stage3_manifest_relative)
worker_manifest <- read_table(worker_manifest_relative)

stopifnot(
  identical(
    artifact_sha256(file.path(root, archive_relative)),
    "ecbf772d084582c643e1ee4523a8171db419d4e998f5d846ea34228238a6f709"
  ),
  nrow(before) == nrow(after),
  identical(names(before), names(after)),
  nrow(reconciliation) == 9L,
  identical(mapping$local_id, sprintf("H01-%03d", 1:8)),
  identical(
    mapping$proposed_central_ids,
    c(
      "IMP-001",
      "DEV-009",
      "IMP-004",
      "IMP-003|IMP-004",
      "DEV-018",
      "DEV-009|IMP-001",
      "IMP-024",
      "IMP-023"
    )
  ),
  all(grepl("no new central record requested", mapping$owner_disposition)),
  !any(grepl("\\bH01-00[1-8]\\b", after$deviation_ids))
)

mder <- after |>
  filter(.data$deviation_ids == "DEV-058")
zero_day <- after |>
  filter(.data$deviation_ids == "DEV-057")
timing <- after |>
  filter(.data$deviation_ids == "DEV-008; DEV-054")
stopifnot(
  nrow(mder) == 1L,
  grepl("arithmetic mean", mder$analysis_used, fixed = TRUE),
  grepl("one-minute", mder$analysis_used, fixed = TRUE),
  grepl("720 viable minutes", mder$analysis_used, fixed = TRUE),
  !grepl("ratio of integrated", mder$analysis_used, fixed = TRUE),
  nrow(zero_day) == 1L,
  grepl("exactly 0 lx", zero_day$analysis_used, fixed = TRUE),
  grepl("individual zeros remain valid", zero_day$analysis_used, fixed = TRUE),
  !grepl("more than 1,440 valid", zero_day$analysis_used, fixed = TRUE),
  nrow(timing) == 1L,
  grepl("registered midpoint", timing$analysis_used, fixed = TRUE),
  grepl("is retained", timing$analysis_used, fixed = TRUE),
  grepl("adapted sensitivity", timing$analysis_used, fixed = TRUE)
)

central_register <- read_table("audit/ledgers/deviation_register.csv")
display_ids <- trimws(unlist(strsplit(after$deviation_ids, ";", fixed = TRUE)))
stopifnot(length(setdiff(unique(display_ids), central_register$deviation_id)) == 0L)

protected_current <- protected |>
  mutate(
    current_sha256 = vapply(
      file.path(root, .data$path),
      artifact_sha256,
      character(1)
    ),
    current_bytes = as.numeric(file.info(file.path(root, .data$path))$size)
  )
stopifnot(
  nrow(protected_current) > 0L,
  all(protected_current$sha256 == protected_current$current_sha256),
  all(protected_current$bytes == protected_current$current_bytes)
)

for (index in seq_len(nrow(manifest))) {
  path <- file.path(root, manifest$path[[index]])
  stopifnot(
    file.exists(path),
    identical(artifact_sha256(path), manifest$sha256[[index]]),
    identical(as.numeric(file.info(path)$size), manifest$bytes[[index]])
  )
}

stage3_row <- stage3_manifest |>
  filter(.data$path == target_relative)
stopifnot(
  nrow(stage3_row) == 1L,
  identical(stage3_row$sha256, artifact_sha256(file.path(root, target_relative))),
  identical(stage3_row$bytes, as.numeric(file.info(file.path(root, target_relative))$size))
)

worker_required <- c(
  target_relative,
  archive_relative,
  mapping_relative,
  reconciliation_relative,
  protected_relative,
  manifest_relative,
  "scripts/hypotheses/H01/reconcile_h01_report016_deviations.R",
  "tests/hypotheses/H01/test_h01_report016_deviation_reconciliation.R"
)
worker_rows <- worker_manifest |>
  filter(.data$path %in% worker_required)
stopifnot(
  setequal(worker_rows$path, worker_required),
  all(vapply(seq_len(nrow(worker_rows)), function(index) {
    identical(
      artifact_sha256(file.path(root, worker_rows$path[[index]])),
      worker_rows$sha256[[index]]
    )
  }, logical(1)))
)

qmd <- paste(
  readLines(file.path(root, "notebooks/hypotheses/H01.qmd"), warn = FALSE),
  collapse = "\n"
)
generator <- paste(
  readLines(
    file.path(root, "scripts/hypotheses/H01/build_h01_stage3_reporting_inputs.R"),
    warn = FALSE
  ),
  collapse = "\n"
)
stopifnot(
  grepl('read_stage3("H01_stage3_deviations")', qmd, fixed = TRUE),
  grepl("tbl-h01-deviations", qmd, fixed = TRUE),
  !grepl("preregistration_deviations.qmd", qmd, fixed = TRUE),
  grepl('"DEV-058", "Melanopic daylight efficacy ratio"', generator, fixed = TRUE),
  grepl("complete exact-zero melEDI day", generator, fixed = TRUE),
  grepl("adapted sensitivity", generator, fixed = TRUE),
  !grepl('"DEV-018; H01-005"', generator, fixed = TRUE),
  !grepl('"H01-002", "Site follow-ups"', generator, fixed = TRUE),
  !grepl('"H01-007; IMP-024"', generator, fixed = TRUE),
  !grepl('"H01-008; IMP-023"', generator, fixed = TRUE)
)

message(
  "H01 REPORT-016 deviation reconciliation checks passed: ",
  nrow(protected),
  " protected scientific artifacts unchanged"
)
