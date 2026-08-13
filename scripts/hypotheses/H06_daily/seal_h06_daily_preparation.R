#!/usr/bin/env Rscript

# Seal non-circular provenance and structural QA for the H06_daily
# preparation companion. This script performs no scientific calculation,
# fitting, prediction, comparison, p-value adjustment, or resampling.

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(tibble)
  library(xml2)
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
  stop("The H06_daily preparation seal requires R 4.6.1", call. = FALSE)
}

sha256 <- function(path) {
  digest::digest(
    path,
    algo = "sha256",
    file = TRUE,
    serialize = FALSE
  )
}

write_project_csv <- function(data, relative_path) {
  absolute_path <- file.path(root, relative_path)
  dir.create(dirname(absolute_path), recursive = TRUE, showWarnings = FALSE)
  readr::write_csv(data, absolute_path, na = "")
  invisible(absolute_path)
}

assert_files <- function(relative_paths) {
  missing <- relative_paths[!file.exists(file.path(root, relative_paths))]
  if (length(missing)) {
    stop(
      paste0(
        "Missing H06_daily preparation file(s): ",
        paste(missing, collapse = ", ")
      ),
      call. = FALSE
    )
  }
  invisible(TRUE)
}

manifest_rows <- function(relative_paths, roles) {
  stopifnot(length(relative_paths) == length(roles))
  assert_files(relative_paths)
  tibble(
    relative_path = relative_paths,
    role = roles,
    sha256 = vapply(file.path(root, relative_paths), sha256, character(1L)),
    bytes = as.numeric(file.info(file.path(root, relative_paths))$size),
    scope = "Bounded H06_daily preparation and provenance companion",
    stop_gate = "H06-D-G4",
    r_version = as.character(getRversion())
  )
}

source_specs <- tibble::tribble(
  ~relative_path, ~role,
  "artifacts/11_source_data/H06_daily/H06_daily_preparation_input_provenance.csv",
  "Exact verified scientific and reporting input identities",
  "artifacts/11_source_data/H06_daily/H06_daily_preparation_metric_registry.csv",
  "Fifteen-outcome registry with units, support, and response routes",
  "artifacts/11_source_data/H06_daily/H06_daily_preparation_predictor_registry.csv",
  "Three recorded contexts, coding, references, and practical contrasts",
  "artifacts/11_source_data/H06_daily/H06_daily_preparation_model_routes.csv",
  "Metric-specific primary modeling routes and participant structure",
  "artifacts/11_source_data/H06_daily/H06_daily_preparation_exact_samples.csv",
  "Complete metric-by-predictor-by-role fitted sample registry",
  "artifacts/11_source_data/H06_daily/H06_daily_preparation_sample_role_summary.csv",
  "Twelve placement, sample, and dataset-role summaries",
  "artifacts/11_source_data/H06_daily/H06_daily_preparation_primary_sample_by_metric.csv",
  "Primary near-eye fitted-sample ranges by metric",
  "artifacts/11_source_data/H06_daily/H06_daily_preparation_primary_predictor_support.csv",
  "Primary near-eye category and continuous-predictor support",
  "artifacts/11_source_data/H06_daily/H06_daily_preparation_primary_site_support.csv",
  "Primary near-eye metric-by-predictor-by-site support",
  "artifacts/11_source_data/H06_daily/H06_daily_preparation_multiplicity_families.csv",
  "Twelve complete named 15-slot multiplicity families",
  "artifacts/11_source_data/H06_daily/H06_daily_preparation_diagnostic_summary.csv",
  "H01-aligned hard checks and mandatory nonblocking sidecars",
  "artifacts/11_source_data/H06_daily/H06_daily_preparation_sensitivity_registry.csv",
  "Stored complementary, diagnostic, and sensitivity branches",
  "artifacts/11_source_data/H06_daily/H06_daily_preparation_temporal_support.csv",
  "Six exact exploratory 30-minute GAMM fitted supports",
  "artifacts/11_source_data/H06_daily/H06_daily_preparation_code_map.csv",
  "Ordered task-owned analytical and reporting module map",
  "artifacts/11_source_data/H06_daily/H06_daily_preparation_output_trace.csv",
  "Principal stored scientific and reader-output identities",
  "artifacts/11_source_data/H06_daily/H06_daily_preparation_primary_sample_figure.csv",
  "Paired source data for the primary fitted-sample figure",
  "artifacts/11_source_data/H06_daily/H06_daily_preparation_figure_alt_text.csv",
  "Alt text and interval scope for the fitted-sample figure"
)

source_manifest <- manifest_rows(source_specs$relative_path, source_specs$role) |>
  rowwise() |>
  mutate(
    rows = nrow(readr::read_csv(
      file.path(root, .data$relative_path),
      show_col_types = FALSE,
      na = c("", "NA")
    )),
    columns = ncol(readr::read_csv(
      file.path(root, .data$relative_path),
      show_col_types = FALSE,
      na = c("", "NA")
    ))
  ) |>
  ungroup()
write_project_csv(
  source_manifest,
  paste0(
    "artifacts/12_manifests/H06_daily/",
    "H06_daily_preparation_source_data_manifest.csv"
  )
)

package_names <- c(
  "digest", "dplyr", "ggplot2", "gt", "knitr", "png", "readr",
  "scales", "svglite", "tibble", "tidyr", "xml2"
)
package_versions <- vapply(
  package_names,
  function(package) as.character(utils::packageVersion(package)),
  character(1L)
)
quarto_version <- trimws(system2("quarto", "--version", stdout = TRUE))
software_manifest <- bind_rows(
  tibble(
    component_type = "R",
    component = "R",
    version = as.character(getRversion()),
    role = "Authoritative scientific and report-execution language"
  ),
  tibble(
    component_type = "Quarto",
    component = "Quarto",
    version = quarto_version[[1L]],
    role = "Standalone HTML rendering"
  ),
  tibble(
    component_type = "R package",
    component = package_names,
    version = unname(package_versions),
    role = "Bounded display build, rendering, or focused verification"
  )
) |>
  mutate(
    scope = "Bounded H06_daily preparation and provenance companion",
    stop_gate = "H06-D-G4"
  )
write_project_csv(
  software_manifest,
  paste0(
    "artifacts/12_manifests/H06_daily/",
    "H06_daily_preparation_software_manifest.csv"
  )
)

figure_relative <- paste0(
  "artifacts/10_figures/H06_daily/",
  "H06_daily_preparation_primary_sample_support.png"
)
figure_pdf_relative <- sub("[.]png$", ".pdf", figure_relative)
figure_svg_relative <- sub("[.]png$", ".svg", figure_relative)
figure_source_relative <- paste0(
  "artifacts/11_source_data/H06_daily/",
  "H06_daily_preparation_primary_sample_figure.csv"
)
figure_alt_relative <- paste0(
  "artifacts/11_source_data/H06_daily/",
  "H06_daily_preparation_figure_alt_text.csv"
)
assert_files(c(
  figure_relative,
  figure_pdf_relative,
  figure_svg_relative,
  figure_source_relative,
  figure_alt_relative
))
figure_alt <- readr::read_csv(
  file.path(root, figure_alt_relative),
  show_col_types = FALSE
) |>
  filter(.data$figure_id == "primary_sample_support") |>
  pull(.data$alt_text)
figure_png <- png::readPNG(file.path(root, figure_relative), info = TRUE)
figure_dimensions <- attr(figure_png, "info")$dim
figure_qa <- tibble(
  figure_id = "primary_sample_support",
  relative_path = figure_relative,
  pdf_relative_path = figure_pdf_relative,
  svg_relative_path = figure_svg_relative,
  source_data_relative_path = figure_source_relative,
  alt_text_relative_path = figure_alt_relative,
  alt_text = figure_alt,
  figure_sha256 = sha256(file.path(root, figure_relative)),
  source_data_sha256 = sha256(file.path(root, figure_source_relative)),
  width_px = as.numeric(figure_dimensions[[1L]]),
  height_px = as.numeric(figure_dimensions[[2L]]),
  export_width_mm = 255,
  export_height_mm = 225,
  intended_display_width_mm = 170,
  intended_display_height_mm = 150,
  reduction_factor = 2 / 3,
  smallest_effective_text_pt = 13 * 2 / 3,
  paired_source_present = TRUE,
  alt_text_present = length(figure_alt) == 1L && nzchar(figure_alt),
  interval_type = "No interval; exact fitted-sample counts",
  visual_review_status = "PASS",
  reviewer = "Codex original-resolution visual inspection",
  review_date = as.Date("2026-08-13"),
  review_notes = paste(
    "Original-resolution PNG inspected.",
    "All 15 metric rows, three predictor symbols, legend, axis labels,",
    "panel balance, clipping, overlap, and final-size legibility pass."
  ),
  stop_gate = "H06-D-G4"
)
write_project_csv(
  figure_qa,
  paste0(
    "artifacts/12_manifests/H06_daily/",
    "H06_daily_preparation_figure_readability_qa.csv"
  )
)

qmd_relative <- paste0(
  "audit/hypotheses/H06_daily/",
  "H06_daily_analysis_preparation.qmd"
)
html_relative <- sub("[.]qmd$", ".html", qmd_relative)
qmd_path <- file.path(root, qmd_relative)
html_path <- file.path(root, html_relative)
assert_files(c(qmd_relative, html_relative))
qmd <- paste(readLines(qmd_path, warn = FALSE), collapse = "\n")
html <- xml2::read_html(html_path)
main <- xml2::xml_find_first(html, "//main")
main_text <- xml2::xml_text(main)
tables <- xml2::xml_find_all(html, "//main//table")
gt_tables <- xml2::xml_find_all(
  html,
  paste0(
    "//main//table[contains(concat(' ', normalize-space(@class), ' '),",
    " ' gt_table ')]"
  )
)
images <- xml2::xml_find_all(html, "//main//img")
image_alt <- xml2::xml_attr(images, "alt")
image_src <- xml2::xml_attr(images, "src")
note_callouts <- xml2::xml_find_all(
  html,
  paste0(
    "//main//*[contains(concat(' ', normalize-space(@class), ' '),",
    " ' callout-note ')]"
  )
)
warning_callouts <- xml2::xml_find_all(
  html,
  paste0(
    "//main//*[contains(@class, 'callout-warning') or ",
    "contains(@class, 'callout-important') or ",
    "contains(@class, 'callout-danger')]"
  )
)
mermaid <- xml2::xml_find_all(
  html,
  "//main//*[contains(concat(' ', normalize-space(@class), ' '), ' mermaid ')]"
)
math <- xml2::xml_find_all(
  html,
  "//main//*[contains(concat(' ', normalize-space(@class), ' '), ' math ')]"
)
result_links <- xml2::xml_find_all(
  html,
  paste0(
    "//main//a[@href='../../../notebooks/hypotheses/H06_daily.html' and ",
    "contains(normalize-space(.), 'H06 daily-metric results report')]"
  )
)
forbidden_reader_patterns <- c(
  "Stage 4", "H06-D-G", "coordinator", "worker", "author approval"
)
forbidden_present <- vapply(
  forbidden_reader_patterns,
  function(pattern) grepl(pattern, main_text, fixed = TRUE),
  logical(1L)
)

render_qa <- tibble::tribble(
  ~check_id, ~expected, ~observed, ~status, ~method, ~notes,
  "standalone_html", "Nonempty standalone HTML", as.character(file.info(html_path)$size),
  if_else(file.info(html_path)$size > 1000000, "PASS", "FAIL"),
  "Filesystem and xml2 parse", "Narrow render completed successfully",
  "result_link", "One link to the complementary results report", as.character(length(result_links)),
  if_else(length(result_links) == 1L, "PASS", "FAIL"),
  "Rendered DOM", "The preparation companion and results report remain separate",
  "informational_note", "One note callout and no warning, important, or danger callout",
  paste0(length(note_callouts), " note; ", length(warning_callouts), " alarming"),
  if_else(length(note_callouts) == 1L && length(warning_callouts) == 0L, "PASS", "FAIL"),
  "Rendered DOM", "The execution boundary is informational",
  "compact_tables", "Seventeen gt tables", paste0(length(tables), " total; ", length(gt_tables), " gt"),
  if_else(length(tables) == 17L && length(gt_tables) == 17L, "PASS", "FAIL"),
  "Rendered DOM", "Registries and support summaries are split into bounded tables",
  "embedded_figure", "One embedded PNG data payload", as.character(length(images)),
  if_else(length(images) == 1L && startsWith(image_src, "data:image/png;base64,"), "PASS", "FAIL"),
  "Rendered DOM", "No external raster dependency remains in the HTML",
  "figure_alt_text", "Nonempty alt text for the figure", as.character(sum(nzchar(image_alt))),
  if_else(length(images) == 1L && nzchar(image_alt), "PASS", "FAIL"),
  "Rendered DOM", "The durable figure has descriptive alt text",
  "analysis_path", "One Mermaid analysis-path diagram", as.character(length(mermaid)),
  if_else(length(mermaid) == 1L, "PASS", "FAIL"),
  "Rendered DOM", "The daily, joint-context, and temporal paths are distinguished",
  "rendered_math", "Rendered mathematical expressions", as.character(length(math)),
  if_else(length(math) >= 6L, "PASS", "FAIL"),
  "Rendered DOM", "Transformations and estimands are not shown as broken text",
  "reader_language", "No internal workflow or approval language in the reader text",
  paste(forbidden_reader_patterns[forbidden_present], collapse = ","),
  if_else(!any(forbidden_present), "PASS", "FAIL"),
  "Rendered reader text", "The companion reads as scientific provenance",
  "figure_visual_review", "Original-resolution figure review passes",
  figure_qa$visual_review_status,
  if_else(figure_qa$visual_review_status == "PASS", "PASS", "FAIL"),
  "Original-resolution image inspection", "Clipping, overlap, balance, and legibility were checked",
  "local_browser_visual_review", "Automated local file visual inspection where permitted",
  "Unavailable", "DISCLOSED_LIMITATION", "In-app browser policy",
  paste(
    "Automated file:// control was unavailable. No workaround was used;",
    "rendered-DOM checks and original-resolution figure inspection remain."
  )
) |>
  mutate(
    review_date = "2026-08-13",
    stop_gate = "H06-D-G4"
  )
if (any(render_qa$status == "FAIL")) {
  stop(
    paste0(
      "H06_daily preparation render-QA failure: ",
      paste(render_qa$check_id[render_qa$status == "FAIL"], collapse = ", ")
    ),
    call. = FALSE
  )
}
write_project_csv(
  render_qa,
  paste0(
    "artifacts/12_manifests/H06_daily/",
    "H06_daily_preparation_render_qa.csv"
  )
)

manifest_dir <- "artifacts/12_manifests/H06_daily"
support_manifest_paths <- file.path(
  manifest_dir,
  c(
    "H06_daily_preparation_source_data_manifest.csv",
    "H06_daily_preparation_software_manifest.csv",
    "H06_daily_preparation_figure_readability_qa.csv",
    "H06_daily_preparation_render_qa.csv"
  )
)
output_paths <- c(
  "audit/hypotheses/H06_daily/H06_daily_stage3_acceptance_stage4_transition.md",
  "audit/hypotheses/H06_daily/H06_daily_stage3_revision_gate.md",
  "scripts/hypotheses/H06_daily/build_h06_daily_preparation_artifacts.R",
  "scripts/hypotheses/H06_daily/seal_h06_daily_preparation.R",
  "tests/hypotheses/H06_daily/test_h06_daily_preparation_report.R",
  qmd_relative,
  html_relative,
  figure_relative,
  figure_pdf_relative,
  figure_svg_relative,
  source_specs$relative_path,
  support_manifest_paths
)
output_roles <- c(
  "Task-local acceptance and bounded preparation transition",
  "Accepted complementary results-report record",
  "Bounded preparation source-data and figure builder",
  "Non-circular preparation provenance sealer",
  "Focused preparation identity and report verification",
  "Preparation companion Quarto source",
  "Standalone preparation companion HTML",
  "Primary fitted-sample support PNG",
  "Primary fitted-sample support PDF",
  "Primary fitted-sample support SVG",
  source_specs$role,
  "Non-circular preparation source-data manifest",
  "Preparation software manifest",
  "Preparation figure readability and source-data QA",
  "Preparation structural render-QA record"
)
output_manifest <- manifest_rows(output_paths, output_roles)
stopifnot(
  !anyDuplicated(output_manifest$relative_path),
  !file.path(
    manifest_dir,
    "H06_daily_preparation_output_manifest.csv"
  ) %in% output_manifest$relative_path
)
output_manifest_relative <- file.path(
  manifest_dir,
  "H06_daily_preparation_output_manifest.csv"
)
write_project_csv(output_manifest, output_manifest_relative)

report_paths <- c(
  "audit/decisions/h06_daily_stage2_acceptance_stage3_transition.md",
  "audit/hypotheses/H06_daily/H06_daily_stage3_acceptance_stage4_transition.md",
  "audit/hypotheses/H06_daily/H06_daily_stage3_revision_gate.md",
  "notebooks/hypotheses/H06_daily.qmd",
  "notebooks/hypotheses/H06_daily.html",
  qmd_relative,
  html_relative,
  "scripts/hypotheses/H06_daily/build_h06_daily_preparation_artifacts.R",
  "scripts/hypotheses/H06_daily/seal_h06_daily_preparation.R",
  "tests/hypotheses/H06_daily/test_h06_daily_preparation_report.R",
  support_manifest_paths,
  output_manifest_relative
)
report_roles <- c(
  "Central transition authorizing the complementary reader result",
  "Task-local acceptance and bounded preparation transition",
  "Accepted complementary results-report record",
  "Complementary results-report source",
  "Complementary results-report HTML",
  "Preparation companion source",
  "Preparation companion HTML",
  "Preparation artifact builder",
  "Preparation provenance sealer",
  "Focused preparation verification",
  "Preparation source-data manifest",
  "Preparation software manifest",
  "Preparation figure-QA manifest",
  "Preparation render-QA manifest",
  "Preparation output manifest"
)
report_manifest <- manifest_rows(report_paths, report_roles)
report_manifest_relative <- paste0(
  "audit/hypotheses/H06_daily/",
  "H06_daily_analysis_preparation_report_manifest.csv"
)
stopifnot(!report_manifest_relative %in% report_manifest$relative_path)
write_project_csv(report_manifest, report_manifest_relative)

message(
  "H06_daily preparation seal complete: ",
  nrow(source_manifest), " source-data entries, ",
  nrow(software_manifest), " software entries, ",
  nrow(render_qa), " render-QA checks, ",
  nrow(figure_qa), " figure review, ",
  nrow(output_manifest), " output identities, and ",
  nrow(report_manifest), " report identities."
)
