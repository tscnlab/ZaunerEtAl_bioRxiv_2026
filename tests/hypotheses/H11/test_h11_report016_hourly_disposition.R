# Verify the REPORT-016 H11 hourly-outcome disposition without recomputation.

options(stringsAsFactors = FALSE)

test_argument <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
if (length(test_argument) != 1L) {
  stop("Could not determine the H11 REPORT-016 test location", call. = FALSE)
}
test_path <- normalizePath(
  sub("^--file=", "", test_argument),
  winslash = "/",
  mustWork = TRUE
)
root <- dirname(dirname(dirname(dirname(test_path))))

stopifnot(
  identical(as.character(getRversion()), "4.6.1"),
  requireNamespace("digest", quietly = TRUE),
  requireNamespace("knitr", quietly = TRUE)
)

read_text <- function(relative_path) {
  path <- file.path(root, relative_path)
  stopifnot(file.exists(path), file.info(path)$size > 0)
  paste(readLines(path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
}

sha256 <- function(relative_path) {
  path <- file.path(root, relative_path)
  stopifnot(file.exists(path))
  digest::digest(path, algo = "sha256", file = TRUE)
}

verify_manifest_rows <- function(
  relative_manifest,
  path_column,
  selector,
  expected_rows,
  expected_manifest_sha256
) {
  stopifnot(identical(sha256(relative_manifest), expected_manifest_sha256))
  manifest <- utils::read.csv(
    file.path(root, relative_manifest),
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
  manifest <- manifest[selector(manifest), , drop = FALSE]
  stopifnot(nrow(manifest) == expected_rows)
  relative_paths <- manifest[[path_column]]
  stopifnot(all(file.exists(file.path(root, relative_paths))))
  observed <- vapply(relative_paths, sha256, character(1))
  stopifnot(identical(unname(observed), unname(manifest$sha256)))
  invisible(manifest)
}

parse_qmd_r <- function(relative_path) {
  output <- tempfile(fileext = ".R")
  on.exit(unlink(output), add = TRUE)
  knitr::purl(
    file.path(root, relative_path),
    output = output,
    documentation = 0L,
    quiet = TRUE
  )
  parse(file = output)
  invisible(TRUE)
}

message("Testing current and historical disposition wording")
result_source <- read_text("notebooks/hypotheses/H11.qmd")
companion_source <- read_text(
  "audit/hypotheses/H11/H11_analysis_preparation.qmd"
)
handoff <- read_text("audit/handoffs/H11_worker_handoff.md")
stage1_plan <- read_text("audit/hypotheses/H11/01_audit_and_plan.qmd")
stage2_report <- read_text(
  "audit/hypotheses/H11/02_implementation_and_v0_comparison.qmd"
)
result_source_compact <- gsub("[[:space:]]+", " ", result_source)
companion_source_compact <- gsub("[[:space:]]+", " ", companion_source)
handoff_compact <- gsub("[[:space:]]+", " ", handoff)
stage1_plan_compact <- gsub("[[:space:]]+", " ", stage1_plan)
stage2_report_compact <- gsub("[[:space:]]+", " ", stage2_report)

parse_qmd_r("notebooks/hypotheses/H11.qmd")
parse_qmd_r("audit/hypotheses/H11/H11_analysis_preparation.qmd")

stopifnot(
  grepl(
    "not an outstanding H11 sensitivity",
    result_source_compact,
    fixed = TRUE
  ),
  grepl(
    "is outside the accepted H11 analysis rather than an outstanding sensitivity",
    result_source_compact,
    fixed = TRUE
  ),
  grepl(
    "outside—and superseded by—the accepted author-approved H02 30-minute inheritance",
    companion_source_compact,
    fixed = TRUE
  ),
  grepl(
    "Outside/superseded by accepted H11 analysis",
    companion_source_compact,
    fixed = TRUE
  ),
  grepl(
    "Disposition: (c), outside/superseded by the accepted H11 analysis",
    handoff_compact,
    fixed = TRUE
  ),
  !grepl(
    "registered hourly outcome remains an unresolved sensitivity",
    result_source_compact,
    fixed = TRUE
  ),
  grepl(
    "registered hourly geometric-mean outcome remains a named sensitivity",
    stage1_plan_compact,
    fixed = TRUE
  ),
  grepl(
    "The registered hourly geometric-mean outcome, paired common-sample fits",
    stage2_report_compact,
    fixed = TRUE
  ),
  !grepl("preregistration_deviations.qmd#", result_source, fixed = TRUE),
  !grepl("preregistration_deviations.qmd#", companion_source, fixed = TRUE)
)

reconciliation <- utils::read.csv(
  file.path(
    root,
    "audit/hypotheses/H11/06_report016_hourly_outcome_reconciliation.csv"
  ),
  check.names = FALSE,
  stringsAsFactors = FALSE
)
stopifnot(
  nrow(reconciliation) == 8L,
  identical(
    reconciliation$record_id,
    sprintf("H11-RH-SCI-002-%02d", seq_len(8L))
  ),
  sum(reconciliation$action == "added") == 1L,
  sum(reconciliation$action == "preserved") == 3L,
  sum(reconciliation$action == "revised") == 4L
)

reader_dispositions <- utils::read.csv(
  file.path(root, "audit/ledgers/deviation_reader_dispositions.csv"),
  check.names = FALSE,
  stringsAsFactors = FALSE
)
dev_042 <- reader_dispositions[
  reader_dispositions$deviation_id == "DEV-042",
  ,
  drop = FALSE
]
dev_003 <- reader_dispositions[
  reader_dispositions$deviation_id == "DEV-003",
  ,
  drop = FALSE
]
stopifnot(
  nrow(dev_042) == 1L,
  dev_042$reader_section == "scientific_deviation",
  dev_042$current_status == "approved_implemented_verified",
  nrow(dev_003) == 1L,
  dev_003$reader_section == "current_qualification",
  dev_003$current_status == "open_current_qualification",
  sum(reader_dispositions$reader_section == "current_qualification") == 1L
)

message("Testing that no registered-hourly fit exists")
deferred <- utils::read.csv(
  file.path(root, "artifacts/06_model_data/H11/stage2/deferred_analysis_registry.csv"),
  check.names = FALSE,
  stringsAsFactors = FALSE
)
stage2_formulas <- utils::read.csv(
  file.path(root, "artifacts/06_model_data/H11/stage2/formula_and_fit_manifest.csv"),
  check.names = FALSE,
  stringsAsFactors = FALSE
)
activity_formulas <- utils::read.csv(
  file.path(
    root,
    "artifacts/06_model_data/H11/activity_context/formula_and_fit_manifest.csv"
  ),
  check.names = FALSE,
  stringsAsFactors = FALSE
)
stopifnot(
  sum(deferred$scenario_id == "registered_hourly_geometric_mean") == 1L,
  deferred$stage2_status[
    deferred$scenario_id == "registered_hourly_geometric_mean"
  ] == "deferred",
  setequal(stage2_formulas$data_scenario_id, c("main", "manuscript_prepared_data")),
  !any(grepl(
    "registered_hourly|hourly_geometric",
    unlist(stage2_formulas, use.names = FALSE),
    ignore.case = TRUE
  )),
  !any(grepl(
    "registered_hourly|hourly_geometric",
    unlist(activity_formulas, use.names = FALSE),
    ignore.case = TRUE
  ))
)

message("Testing frozen scientific identities")
verify_manifest_rows(
  "artifacts/12_manifests/H11/H11_stage2_output_hashes.csv",
  "path",
  function(x) {
    grepl(
      paste0(
        "^artifacts/(06_model_data|07_models|08_diagnostics|09_tables|",
        "10_figures|11_source_data)/H11/stage2/"
      ),
      x$path
    )
  },
  81L,
  "a3cb30de615c615cfbfd6bfb1b7994634b1721915ed446eee5e00157638d44a2"
)
verify_manifest_rows(
  "artifacts/12_manifests/H11/H11_stage3_artifact_manifest.csv",
  "path",
  function(x) x$role == "reader_artifact",
  42L,
  "2f55cef62117af71beab6e320fac842489b24be149209ea60a1d54cbd172f645"
)
verify_manifest_rows(
  "artifacts/12_manifests/H11/H11_activity_context_output_hashes.csv",
  "relative_path",
  function(x) rep(TRUE, nrow(x)),
  48L,
  "6960448adc102d29ff48c06d07eb53cdb97a1bba89ea7dce73f779d5c5a4eecc"
)

message("Testing corrected source identities")
expected_source_hashes <- c(
  "notebooks/hypotheses/H11.qmd" =
    "6d8efe39896812437037ee60675f95fb71fd8f74f3eaf0e65b151f27f0822dbd",
  "audit/hypotheses/H11/H11_analysis_preparation.qmd" =
    "fc7781c887ba4470b1bb660143f5df207e780efd257ca268138dae2d35d42e7f",
  "audit/handoffs/H11_worker_handoff.md" =
    "5f01ac88745d55d749854b41d22ce3bd0afe43f42dbbaded98da7a61e1b53289",
  "audit/hypotheses/H11/06_report016_hourly_outcome_reconciliation.csv" =
    "7dc4ab4a68f21a7274562a06b19bedc904605dc8ab0d721d1b70f6c87b80a64b"
)
observed_source_hashes <- vapply(
  names(expected_source_hashes),
  sha256,
  character(1)
)
stopifnot(identical(observed_source_hashes, expected_source_hashes))

message(
  "H11 REPORT-016 disposition verified: no accepted model or result changed"
)
