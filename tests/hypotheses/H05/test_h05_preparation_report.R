# Standalone structural, source-data, display, and provenance checks for the
# H05 analysis-preparation companion. These checks do not fit or refit models.

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

verification <- verify_hypothesis_preparation_companion(
  root = root,
  hypothesis_id = "H05",
  min_figures = 3L,
  min_gt_tables = 16L,
  extra_forbidden_calls = c(
    "h05_fit_model",
    "h05_fit_bundle",
    "h05_diagnostic_summary",
    "h05_random_site_summary",
    "h05_leave_one_site_out",
    "h01_residual_diagnostics",
    "h01_diagnostic_plot_data"
  )
)

paths <- preparation_companion_paths(root, "H05")
qmd_lines <- readLines(paths$qmd, warn = FALSE, encoding = "UTF-8")
qmd <- paste(qmd_lines, collapse = "\n")

stopifnot(
  grepl("flowchart TD", qmd, fixed = TRUE),
  grepl("../../../notebooks/hypotheses/H05.html", qmd, fixed = TRUE),
  grepl("gap-timing-unaware dataset", qmd, fixed = TRUE),
  grepl("at least 50% valid", qmd, fixed = TRUE),
  grepl("at least 80% valid", qmd, fixed = TRUE),
  grepl("time-sensitive primary metric", qmd, fixed = TRUE),
  grepl("unfit for H05 inference", qmd, fixed = TRUE),
  grepl("another hypothesis that uses a different response variable", qmd, fixed = TRUE),
  grepl("Exact evaluated Wilkinson formulas", qmd, fixed = TRUE),
  grepl("complete 68-value vector", qmd, fixed = TRUE),
  grepl("Zero of 68 primary associations", qmd, fixed = TRUE),
  grepl("121 of 136 fits passed", qmd, fixed = TRUE),
  grepl("15 were unstable", qmd, fixed = TRUE),
  grepl("longest **period**", qmd, fixed = TRUE),
  grepl("Benjamini–Hochberg cannot retain", qmd, fixed = TRUE),
  grepl("For one unchanged vector of raw p-values", qmd, fixed = TRUE),
  grepl("theme_minimal(base_size = 12)", qmd, fixed = TRUE),
  grepl("::: {.callout-note", qmd, fixed = TRUE),
  !grepl("::: {.callout-important", qmd, fixed = TRUE),
  !grepl("::: {.callout-warning", qmd, fixed = TRUE)
)

document <- xml2::read_html(paths$html)
main <- xml2::xml_find_first(
  document,
  "//main[@id='quarto-document-content']"
)
stopifnot(!inherits(main, "xml_missing"))
main_text <- xml2::xml_text(main)

stopifnot(
  grepl("H05 analysis preparation and provenance", main_text, fixed = TRUE),
  grepl("184 unique", main_text, fixed = TRUE),
  grepl("136 frames", main_text, fixed = TRUE),
  grepl("544", main_text, fixed = TRUE),
  grepl("121 of 136", main_text, fixed = TRUE),
  grepl("15 were unstable", main_text, fixed = TRUE),
  grepl("Zero of 68", main_text, fixed = TRUE),
  grepl("132 participants", main_text, fixed = TRUE),
  grepl("500 participant-days", main_text, fixed = TRUE),
  grepl("9 sites", main_text, fixed = TRUE),
  grepl("gap-timing-unaware dataset", main_text, fixed = TRUE),
  grepl("unfit for H05 inference", main_text, fixed = TRUE),
  grepl("different response variable", main_text, fixed = TRUE),
  !grepl("Execution halted", main_text, fixed = TRUE)
)

xml2::xml_remove(xml2::xml_find_all(
  main,
  ".//div[contains(concat(' ', normalize-space(@class), ' '), ' sourceCode ')]"
))
reader_text <- xml2::xml_text(main)
stopifnot(
  !grepl("manuscript-prepared", reader_text, ignore.case = TRUE),
  !grepl("alternative manuscript", reader_text, ignore.case = TRUE),
  !grepl("V0", reader_text, fixed = TRUE),
  !grepl("longest bout", reader_text, ignore.case = TRUE)
)

formula_text <- c(
  "response_value ~ site + leba_centered + (1 | participant_key)",
  "response_value ~ site + (1 | participant_key)",
  "response_value ~ site + leba_centered",
  "response_value ~ site",
  "response_value ~ leba_centered + (1 | site) + (1 | participant_key)",
  "response_value ~ leba_centered + (1 | site)"
)
stopifnot(all(vapply(
  formula_text,
  grepl,
  logical(1),
  x = main_text,
  fixed = TRUE
)))

expected_figures <- c(
  "fig-h05-prep-leba-distribution",
  "fig-h05-prep-sample-support",
  "fig-h05-prep-site-range"
)
figure_widths <- c(
  `fig-h05-prep-leba-distribution` = "960",
  `fig-h05-prep-sample-support` = "1056",
  `fig-h05-prep-site-range` = "1056"
)
for (id in expected_figures) {
  figure <- xml2::xml_find_first(main, paste0(".//*[@id='", id, "']"))
  stopifnot(!inherits(figure, "xml_missing"))
  image <- xml2::xml_find_first(figure, ".//img")
  caption <- xml2::xml_find_first(figure, ".//figcaption")
  stopifnot(
    !inherits(image, "xml_missing"),
    !inherits(caption, "xml_missing"),
    nzchar(xml2::xml_attr(image, "alt")),
    nzchar(trimws(xml2::xml_text(caption))),
    identical(xml2::xml_attr(image, "width"), unname(figure_widths[[id]]))
  )
}

source_data_contract <- c(
  "artifacts/11_source_data/H05/H05_preparation_sample_support.csv" = 34L,
  "artifacts/11_source_data/H05/H05_preparation_leba_score_distribution.csv" = 72L,
  "artifacts/11_source_data/H05/H05_preparation_site_support.csv" = 1122L,
  "artifacts/11_source_data/H05/H05_preparation_site_support_summary.csv" = 17L
)
for (relative_path in names(source_data_contract)) {
  data <- readr::read_csv(
    file.path(root, relative_path),
    show_col_types = FALSE
  )
  stopifnot(nrow(data) == unname(source_data_contract[[relative_path]]))
}

factor_registry <- readr::read_csv(
  file.path(root, "artifacts/06_model_data/H05/H05_factor_registry.csv"),
  show_col_types = FALSE
)
frame_index <- readr::read_csv(
  file.path(root, "artifacts/06_model_data/H05/H05_model_frame_index.csv"),
  show_col_types = FALSE
)
family_audit <- readr::read_csv(
  file.path(root, "artifacts/09_tables/H05/H05_family_audit.csv"),
  show_col_types = FALSE
)
stopifnot(
  nrow(factor_registry) == 4L,
  nrow(frame_index) == 544L,
  !anyDuplicated(frame_index[c("run_id", "metric_id", "factor_id")]),
  nrow(family_audit) == 3L,
  all(family_audit$planned_tests == 68L),
  all(family_audit$observed_tests == 68L),
  all(family_audit$estimable_adjusted_tests == 68L),
  all(family_audit$passes_bh_0_05 == 0L),
  all(family_audit$vector_bh_verified)
)

qa_path <- file.path(
  root,
  "artifacts/12_manifests/H05/H05_figure_readability_qa.csv"
)
qa <- readr::read_csv(qa_path, show_col_types = FALSE)
qa_checks <- c(
  "no_clipping_or_cropping",
  "no_overlap",
  "no_text_distortion",
  "no_bad_wrapping",
  "important_text_readable",
  "data_region_proportionate",
  "marks_distinguishable",
  "caption_and_alt_text_present"
)
stopifnot(
  nrow(qa) == 10L,
  !anyDuplicated(qa$figure_id),
  all(qa$status == "PASS"),
  all(qa$reporting_rule == "REPORT-011"),
  all(qa$pixel_width >= 1900L),
  all(qa$pixel_height >= 1200L),
  all(vapply(qa[qa_checks], function(value) all(value), logical(1)))
)

stopifnot(
  verification$figures >= 3L,
  verification$gt_tables >= 16L,
  verification$manifest_identities >= 45L,
  isTRUE(verification$source_copy_identical)
)

message(
  "H05 preparation companion verified: ",
  verification$figures,
  " figures, ",
  verification$gt_tables,
  " gt tables, ",
  verification$manifest_identities,
  " manifest identities, and byte-identical source copy"
)
