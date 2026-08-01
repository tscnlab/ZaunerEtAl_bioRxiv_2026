# Standalone structural and provenance checks for the H02 preparation report.

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

qmd_path <- file.path(
  root,
  "audit/hypotheses/H02/H02_analysis_preparation.qmd"
)
html_path <- file.path(
  root,
  "_build/nathealth/audit/hypotheses/H02/H02_analysis_preparation.html"
)
rendered_qmd_path <- file.path(
  root,
  "_build/nathealth/audit/hypotheses/H02/H02_analysis_preparation.qmd"
)
manifest_path <- file.path(
  root,
  "artifacts/12_manifests/H02/H02_preparation_report_manifest.csv"
)

stopifnot(all(file.exists(c(
  qmd_path,
  rendered_qmd_path,
  html_path,
  manifest_path
))))
stopifnot(identical(
  readLines(qmd_path, warn = FALSE),
  readLines(rendered_qmd_path, warn = FALSE)
))

qmd <- paste(readLines(qmd_path, warn = FALSE), collapse = "\n")
stopifnot(
  grepl("flowchart TD", qmd, fixed = TRUE),
  grepl("global time effect", qmd, fixed = TRUE),
  grepl("h02_validate_inputs(root)", qmd, fixed = TRUE),
  grepl("run_h02_analysis.R", qmd, fixed = TRUE),
  grepl("run_h02_dominance_analysis.R", qmd, fixed = TRUE),
  grepl("../../../notebooks/hypotheses/H02.html", qmd, fixed = TRUE),
  grepl("H02_worker_output_hashes.csv", qmd, fixed = TRUE),
  grepl("p_value_display.R", qmd, fixed = TRUE),
  grepl("gap-timing-unaware dataset", qmd, fixed = TRUE),
  grepl('title.position = "top"', qmd, fixed = TRUE),
  grepl('barwidth = grid::unit(9, "cm")', qmd, fixed = TRUE),
  grepl("::: {.callout-note", qmd, fixed = TRUE),
  !grepl("::: {.callout-important", qmd, fixed = TRUE),
  grepl("response_distribution_positive", qmd, fixed = TRUE),
  grepl(
    "preparation_response_distribution_exact_zero_summary.csv",
    qmd,
    fixed = TRUE
  ),
  !grepl("Step 3", qmd, fixed = TRUE),
  !grepl("Step 4", qmd, fixed = TRUE),
  !grepl("coordinator", qmd, ignore.case = TRUE),
  !grepl("alternative preparation", qmd, ignore.case = TRUE),
  !grepl("h02_fit_bam(", qmd, fixed = TRUE),
  !grepl("h02_bootstrap_variation(", qmd, fixed = TRUE)
)

document <- xml2::read_html(html_path)
main <- xml2::xml_find_first(
  document,
  "//main[@id='quarto-document-content']"
)
stopifnot(!inherits(main, "xml_missing"))
main_text <- xml2::xml_text(main)
result_links <- xml2::xml_find_all(
  main,
  ".//a[contains(@href, 'notebooks/hypotheses/H02.html')]"
)
stale_result_links <- xml2::xml_find_all(
  main,
  ".//a[contains(@href, 'notebooks/hypotheses/H02.qmd')]"
)
note_callouts <- xml2::xml_find_all(
  main,
  ".//*[contains(concat(' ', normalize-space(@class), ' '), ' callout-note ')]"
)
important_callouts <- xml2::xml_find_all(
  main,
  ".//*[contains(concat(' ', normalize-space(@class), ' '), ' callout-important ')]"
)
stopifnot(
  grepl("H02 analysis preparation and provenance", main_text, fixed = TRUE),
  grepl("37,756", main_text, fixed = TRUE),
  grepl("41,842", main_text, fixed = TRUE),
  grepl("816", main_text, fixed = TRUE),
  grepl("902", main_text, fixed = TRUE),
  grepl("global time effect", main_text, fixed = TRUE),
  grepl("gap-timing-unaware dataset", main_text, fixed = TRUE),
  grepl("BH-adjusted p", main_text, fixed = TRUE),
  grepl("<0.001", main_text, fixed = TRUE),
  !grepl("alternative preparation", main_text, ignore.case = TRUE),
  grepl("does not call mgcv::gam() or mgcv::bam()", main_text, fixed = TRUE),
  !grepl("Execution halted", main_text, fixed = TRUE)
)
stopifnot(
  length(result_links) >= 1L,
  length(stale_result_links) == 0L,
  length(note_callouts) >= 1L,
  length(important_callouts) == 0L
)

expected_figures <- c(
  "fig-h02-prep-response-distribution",
  "fig-h02-prep-clock-support",
  "fig-h02-prep-day-support",
  "fig-h02-prep-ar-change"
)
for (id in expected_figures) {
  node <- xml2::xml_find_first(main, paste0(".//*[@id='", id, "']"))
  stopifnot(!inherits(node, "xml_missing"))
}

images <- xml2::xml_find_all(
  main,
  ".//img[contains(@class, 'img-fluid') or @alt]"
)
image_alt <- xml2::xml_attr(images, "alt")
stopifnot(length(images) >= 4L, all(!is.na(image_alt)), all(nzchar(image_alt)))

gt_tables <- xml2::xml_find_all(
  main,
  ".//table[contains(concat(' ', normalize-space(@class), ' '), ' gt_table ')]"
)
stopifnot(length(gt_tables) >= 12L)

manifest <- readr::read_csv(manifest_path, show_col_types = FALSE)
stopifnot(
  nrow(manifest) >= 35L,
  !anyDuplicated(manifest$path),
  all(nchar(manifest$sha256) == 64L)
)
stopifnot(
  "_quarto-nathealth.yml" %in% manifest$path,
  paste0(
    "artifacts/11_source_data/H02/",
    "preparation_response_distribution_positive_observations.csv"
  ) %in% manifest$path,
  paste0(
    "artifacts/11_source_data/H02/",
    "preparation_response_distribution_exact_zero_summary.csv"
  ) %in% manifest$path,
  "artifacts/11_source_data/H02/paired_placement_site_curves.csv" %in%
    manifest$path,
  paste0(
    "_build/nathealth/audit/hypotheses/H02/",
    "H02_analysis_preparation.qmd"
  ) %in% manifest$path,
  sum(startsWith(
    manifest$path,
    paste0(
      "_build/nathealth/audit/hypotheses/H02/",
      "H02_analysis_preparation_files/"
    )
  )) == 4L
)
manifest_files <- file.path(root, manifest$path)
stopifnot(all(file.exists(manifest_files)))
actual_hashes <- unname(vapply(
  manifest_files,
  artifact_sha256,
  character(1)
))
stopifnot(identical(actual_hashes, unname(manifest$sha256)))
