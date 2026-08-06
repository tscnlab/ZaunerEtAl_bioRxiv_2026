#!/usr/bin/env Rscript

# Finalize REPORT-011 status only after the recorded eight-page A4 inspection.
# This script changes display-QA metadata only; it performs no scientific
# calculation, model fit, prediction, or resampling.

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
})

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
source(file.path(root, "scripts/pipeline/paths_io.R"))

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("H11 Stage 3 figure QA requires R 4.6.1", call. = FALSE)
}

producer <- "scripts/hypotheses/H11/finalize_h11_stage3_figure_qa.R"
qa_path <- file.path(
  root,
  "artifacts/12_manifests/H11/H11_stage3_figure_readability_qa.csv"
)
record_path <- file.path(
  root,
  "audit/hypotheses/H11/03_figure_readability_qa.md"
)
proof_path <- file.path(
  root,
  "artifacts/12_manifests/H11/H11_stage3_figure_A4_proofs.pdf"
)

stopifnot(file.exists(qa_path), file.exists(record_path), file.exists(proof_path))
record <- paste(readLines(record_path, warn = FALSE), collapse = "\n")
if (!grepl("Overall outcome: PASS", record, fixed = TRUE)) {
  stop("Recorded physical-size visual inspection is not PASS", call. = FALSE)
}

qa <- readr::read_csv(qa_path, show_col_types = FALSE)
stopifnot(
  nrow(qa) == 8L,
  identical(as.integer(qa$a4_proof_page), 1:8),
  all(grepl("REPORT-011", qa$policy_id, fixed = TRUE)),
  all(abs(qa$base_width_in - 10.5) < 1e-12),
  all(abs(qa$export_scale_multiplier - 1) < 1e-12),
  all(abs(qa$export_width_in - 10.5) < 1e-12),
  all(abs(qa$native_export_width_mm - 266.7) < 1e-8),
  all(qa$intended_display_width_mm == 170),
  all(abs(qa$display_reduction_factor - 170 / 266.7) < 1e-12),
  all(qa$smallest_essential_nominal_text_pt == 12),
  all(qa$effective_final_essential_text_pt >= 7),
  all(qa$smallest_minor_nominal_text_pt == 11),
  all(qa$effective_final_minor_text_pt >= 7),
  all(qa$a4_page_width_mm == 210),
  all(qa$a4_side_margin_mm == 20)
)

qa_final <- qa |>
  dplyr::mutate(
    inspection_date = as.Date("2026-08-06"),
    inspection_basis = paste(
      "Eight-page A4 portrait raster proof of each exported asset reduced",
      "from 266.7 mm to 170 mm, with 20-mm side margins; inspected one",
      "page at a time at physical page geometry"
    ),
    clipping_or_cropping = "PASS",
    overlaps = "PASS",
    text_shape_and_distortion = "PASS",
    wrapping_and_units = "PASS",
    legend_and_data_region_balance = "PASS",
    marks_and_lines_distinguishable = "PASS",
    caption_and_alt_text_present = "PASS",
    typography_status = "PASS",
    visual_status = "PASS",
    overall_status = "PASS",
    qa_record = "audit/hypotheses/H11/03_figure_readability_qa.md"
  )

invisible(write_csv_artifact(qa_final, qa_path, producer = producer))
message("H11 Stage 3 REPORT-011 QA finalized: 8/8 figures PASS")
