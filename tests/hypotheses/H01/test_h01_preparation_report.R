#!/usr/bin/env Rscript

# H01-specific checks layered on the shared preparation-page contract.

suppressPackageStartupMessages({
  library(readr)
  library(xml2)
})

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
source(file.path(root, "scripts/pipeline/paths_io.R"))
source(file.path(
  root,
  "scripts/pipeline/hypothesis_preparation_provenance_contract.R"
))

result <- verify_hypothesis_preparation_companion(
  root = root,
  hypothesis_id = "H01",
  min_figures = 2L,
  min_gt_tables = 20L,
  extra_forbidden_calls = c(
    "h01_fit_model",
    "h01_fit_metric_models",
    "h01_model_tests",
    "h01_site_summaries",
    "h01_prediction_bounds",
    "h01_residual_diagnostics",
    "h01_participant_influence",
    "h01_latitude_leave_one_site_out",
    "h01_fit_random_site_summary",
    "h01_simulate_response",
    "h01_bootstrap_one",
    "h01_bootstrap_r2"
  )
)

paths <- preparation_companion_paths(root, "H01")
qmd <- paste(readLines(paths$qmd, warn = FALSE), collapse = "\n")
stopifnot(
  grepl("flowchart TD", qmd, fixed = TRUE),
  grepl("h01_input_contract(root)", qmd, fixed = TRUE),
  grepl("calendar-day cumulative", qmd, ignore.case = TRUE),
  grepl("strictly after 16:00", qmd, fixed = TRUE),
  grepl("gap-timing-unaware dataset", qmd, fixed = TRUE),
  grepl("four separate complete 17-test", qmd, fixed = TRUE),
  grepl("H01_preparation_fitted_sample_support.csv", qmd, fixed = TRUE),
  grepl("H01_preparation_model_frame_retention.csv", qmd, fixed = TRUE),
  grepl("run_h01_models.R", qmd, fixed = TRUE),
  grepl("run_h01_response_family_bootstrap_production.R", qmd, fixed = TRUE),
  grepl("../../../notebooks/hypotheses/H01.html", qmd, fixed = TRUE),
  !grepl("alternative preparation", qmd, ignore.case = TRUE),
  !grepl("manuscript-prepared", qmd, ignore.case = TRUE),
  !grepl("H01_postbootstrap_response_family_gate_evidence.csv", qmd, fixed = TRUE)
)

source_files <- file.path(
  root,
  "artifacts/11_source_data/H01/preparation",
  c(
    "H01_preparation_fitted_sample_support.csv",
    "H01_preparation_model_frame_retention.csv"
  )
)
stopifnot(all(file.exists(source_files)))

sample_source <- readr::read_csv(
  source_files[[1L]],
  show_col_types = FALSE,
  progress = FALSE
)
retention_source <- readr::read_csv(
  source_files[[2L]],
  show_col_types = FALSE,
  progress = FALSE
)
stopifnot(
  nrow(sample_source) == 34L,
  nrow(retention_source) == 34L,
  identical(sort(unique(sample_source$placement)), c("Chest", "Near eye")),
  all(sample_source$participants > 0L),
  all(sample_source$participant_days > 0L),
  all(sample_source$observations > 0L),
  all(retention_source$retention > 0 & retention_source$retention <= 1)
)

document <- xml2::read_html(paths$html)
main <- xml2::xml_find_first(
  document,
  "//main[@id='quarto-document-content']"
)
stopifnot(!inherits(main, "xml_missing"))
main_text <- xml2::xml_text(main)
stopifnot(
  grepl("H01 analysis preparation and provenance", main_text, fixed = TRUE),
  grepl("17 prespecified light-exposure metrics", main_text, fixed = TRUE),
  grepl("gap-timing-unaware dataset", main_text, fixed = TRUE),
  grepl("At least 1,000 successful joint refits", main_text, fixed = TRUE),
  grepl("816", main_text, fixed = TRUE),
  grepl("902", main_text, fixed = TRUE),
  !grepl("alternative preparation", main_text, ignore.case = TRUE),
  !grepl("Execution halted", main_text, fixed = TRUE)
)

expected_figures <- c(
  "fig-h01-prep-sample-support",
  "fig-h01-prep-model-frame-retention"
)
for (id in expected_figures) {
  node <- xml2::xml_find_first(main, paste0(".//*[@id='", id, "']"))
  stopifnot(!inherits(node, "xml_missing"))
}

source_links <- xml2::xml_find_all(
  main,
  paste0(
    ".//a[contains(@href, ",
    "'H01_analysis_preparation_files/source-data/')]"
  )
)
stopifnot(length(source_links) == 2L)
download_files <- file.path(
  root,
  "_build/nathealth/audit/hypotheses/H01",
  xml2::xml_attr(source_links, "href")
)
stopifnot(
  all(file.exists(download_files)),
  identical(
    sort(unname(vapply(source_files, artifact_sha256, character(1)))),
    sort(unname(vapply(download_files, artifact_sha256, character(1))))
  )
)

manifest <- readr::read_csv(
  paths$manifest,
  show_col_types = FALSE,
  progress = FALSE
)
stopifnot(
  nrow(manifest) >= 35L,
  !anyDuplicated(manifest$path),
  all(nchar(manifest$sha256) == 64L),
  all(c(
    "artifacts/11_source_data/H01/preparation/H01_preparation_fitted_sample_support.csv",
    "artifacts/11_source_data/H01/preparation/H01_preparation_model_frame_retention.csv"
  ) %in% manifest$path),
  sum(startsWith(
    manifest$path,
    paste0(
      "_build/nathealth/audit/hypotheses/H01/",
      "H01_analysis_preparation_files/"
    )
  )) >= 2L
)

message(
  "H01 preparation report passed: ",
  result$figures,
  " figures, ",
  result$gt_tables,
  " gt tables, ",
  result$manifest_identities,
  " manifest identities"
)
