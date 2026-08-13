#!/usr/bin/env Rscript

# Seal non-circular provenance and structural QA for the revised H06_daily
# Stage 3 reader report. This script performs no scientific calculation or fit.

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
if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("The Stage 3 seal requires R 4.6.1", call. = FALSE)
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
      paste0("Missing Stage 3 file(s): ", paste(missing, collapse = ", ")),
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
    authorization = "H06-D-015 plus author-requested Stage 3 revision",
    gate = "H06-D-G3",
    r_version = as.character(getRversion())
  )
}

source_paths <- c(
  "artifacts/11_source_data/H06_daily/H06_daily_non_l10_production_primary_ratio_effects.csv",
  "artifacts/11_source_data/H06_daily/H06_daily_non_l10_production_primary_absolute_effects.csv",
  "artifacts/11_source_data/H06_daily/H06_daily_stage3_primary_results.csv",
  "artifacts/11_source_data/H06_daily/H06_daily_stage3_placement_results.csv",
  "artifacts/11_source_data/H06_daily/H06_daily_stage3_gap_results.csv",
  "artifacts/11_source_data/H06_daily/H06_daily_stage3_gap_decision_changes.csv",
  "artifacts/11_source_data/H06_daily/H06_daily_stage3_family_summary.csv",
  "artifacts/11_source_data/H06_daily/H06_daily_stage3_diagnostic_summary.csv",
  "artifacts/11_source_data/H06_daily/H06_daily_stage3_sample_role_summary.csv",
  "artifacts/11_source_data/H06_daily/H06_daily_stage3_fdr_overview_figure.csv",
  "artifacts/11_source_data/H06_daily/H06_daily_stage3_figure_alt_text.csv",
  "artifacts/11_source_data/H06_daily/H06_daily_stage3_primary_site_interaction_estimates.csv",
  "artifacts/11_source_data/H06_daily/H06_daily_stage3_primary_site_interaction_summary.csv",
  "artifacts/11_source_data/H06_daily/H06_daily_stage3_primary_site_deviation_figure.csv",
  "artifacts/11_source_data/H06_daily/H06_daily_stage3_primary_site_deviation_figure_alt_text.csv",
  "artifacts/11_source_data/H06_daily/H06_daily_joint_context_exploratory_stability.csv",
  "artifacts/11_source_data/H06_daily/H06_daily_joint_context_exploratory_site_estimates.csv",
  "artifacts/11_source_data/H06_daily/H06_daily_stage3_joint_site_interaction_summary.csv",
  "artifacts/09_tables/H06_daily/H06_daily_joint_context_exploratory_family_summary.csv",
  "artifacts/11_source_data/H06_daily/H06_daily_stage3_main_hourly_comparison.csv",
  "artifacts/11_source_data/H06_daily/H06_daily_stage3_temporal_gamm_summary.csv",
  "artifacts/11_source_data/H06_daily/H06_daily_temporal_h02_primary_context_functions_figure_source.csv",
  "artifacts/11_source_data/H06_daily/H06_daily_temporal_h02_figure_alt_text.csv"
)
source_roles <- c(
  "Paired source data for the reused primary ratio-scale figure",
  "Paired source data for the reused primary absolute-scale figure",
  "Complete 45-row primary reader results",
  "Complete 180-row placement reader results",
  "Complete 45-row gap-timing-unaware reader results",
  "Exact three primary-versus-gap FDR decision changes",
  "Twelve fixed 15-slot primary and gap family summaries",
  "H01-aligned diagnostics and mandatory limitation sidecars",
  "Five analysis-role fitted-sample ranges",
  "Paired source data for the 90-symbol FDR overview",
  "Alt text and source-data pairing for the three daily-grid figures",
  "All 90 primary site-specific interaction contrasts",
  "Ten FDR-supported primary interaction summaries",
  "Paired source data for the primary site-deviation figure",
  "Alt text and interval scope for the primary site-deviation figure",
  "Complete 45-row common-sample covariate-stability results",
  "All 378 conditional site-specific exploratory contrasts",
  "Six conditionally supported interaction summaries",
  "Six exploratory joint-context 15-slot family summaries",
  "Three-row comparison with the selected main hourly H06 analysis",
  "Four accepted temporal GAMM whole-function summaries",
  "Paired source data for the temporal GAMM context-function figure",
  "Accepted alt text for temporal GAMM figures"
)

source_manifest <- manifest_rows(source_paths, source_roles) |>
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
  "artifacts/12_manifests/H06_daily/H06_daily_stage3_source_data_manifest.csv"
)

package_names <- c(
  "digest",
  "dplyr",
  "ggplot2",
  "gt",
  "knitr",
  "png",
  "readr",
  "svglite",
  "tidyr",
  "xml2"
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
    role = "Display build, Quarto execution, or focused verification"
  )
) |>
  mutate(
    authorization = "H06-D-015 plus author-requested Stage 3 revision",
    gate = "H06-D-G3"
  )
write_project_csv(
  software_manifest,
  "artifacts/12_manifests/H06_daily/H06_daily_stage3_software_manifest.csv"
)

# Retain the three accepted original-resolution reviews and add the temporal
# figure that was newly admitted to the reader report.
base_figure_qa_path <- file.path(
  root,
  "artifacts/12_manifests/H06_daily/H06_daily_stage3_figure_readability_qa.csv"
)
base_figure_qa <- readr::read_csv(base_figure_qa_path, show_col_types = FALSE)
stopifnot(nrow(base_figure_qa) == 3L)
temporal_figure_relative <- paste0(
  "artifacts/10_figures/H06_daily/",
  "H06_daily_temporal_h02_primary_context_functions.png"
)
temporal_source_relative <- paste0(
  "artifacts/11_source_data/H06_daily/",
  "H06_daily_temporal_h02_primary_context_functions_figure_source.csv"
)
temporal_alt <- readr::read_csv(
  file.path(
    root,
    "artifacts/11_source_data/H06_daily/",
    "H06_daily_temporal_h02_figure_alt_text.csv"
  ),
  show_col_types = FALSE
) |>
  filter(.data$figure_id == "primary_functions") |>
  pull(.data$alt_text)
temporal_png <- png::readPNG(
  file.path(root, temporal_figure_relative),
  info = TRUE
)
temporal_dimensions <- attr(temporal_png, "info")$dim
temporal_figure_qa <- tibble(
  figure_id = "temporal_gamm_context_functions",
  relative_path = temporal_figure_relative,
  source_data_relative_path = temporal_source_relative,
  alt_text = temporal_alt,
  figure_sha256 = sha256(file.path(root, temporal_figure_relative)),
  source_data_sha256 = sha256(file.path(root, temporal_source_relative)),
  width_px = as.numeric(temporal_dimensions[[1L]]),
  height_px = as.numeric(temporal_dimensions[[2L]]),
  paired_source_present = file.exists(file.path(root, temporal_source_relative)),
  alt_text_present = length(temporal_alt) == 1L && nzchar(temporal_alt),
  interval_type = "Pointwise 95% confidence intervals",
  visual_review_status = "PASS",
  reviewer = "Codex original-resolution visual inspection",
  review_date = as.Date("2026-08-13"),
  review_notes = paste(
    "Original-resolution 3150 by 2160 PNG inspected.",
    "Panel labels, curves, pointwise bands, axes, null lines, caption,",
    "balance, clipping, and final-size legibility pass."
  ),
  authorization = "Author-requested Stage 3 revision",
  gate = "H06-D-G3"
)
site_deviation_figure_relative <- paste0(
  "artifacts/10_figures/H06_daily/",
  "H06_daily_stage3_primary_site_deviations.png"
)
site_deviation_source_relative <- paste0(
  "artifacts/11_source_data/H06_daily/",
  "H06_daily_stage3_primary_site_deviation_figure.csv"
)
site_deviation_alt_path <- paste0(
  "artifacts/11_source_data/H06_daily/",
  "H06_daily_stage3_primary_site_deviation_figure_alt_text.csv"
)
site_deviation_alt <- readr::read_csv(
  file.path(root, site_deviation_alt_path),
  show_col_types = FALSE
) |>
  filter(.data$figure_id == "primary_site_deviations") |>
  pull(.data$alt_text)
site_deviation_png <- png::readPNG(
  file.path(root, site_deviation_figure_relative),
  info = TRUE
)
site_deviation_dimensions <- attr(site_deviation_png, "info")$dim
site_deviation_figure_qa <- tibble(
  figure_id = "primary_site_deviations",
  relative_path = site_deviation_figure_relative,
  source_data_relative_path = site_deviation_source_relative,
  alt_text = site_deviation_alt,
  figure_sha256 = sha256(file.path(root, site_deviation_figure_relative)),
  source_data_sha256 = sha256(file.path(root, site_deviation_source_relative)),
  width_px = as.numeric(site_deviation_dimensions[[1L]]),
  height_px = as.numeric(site_deviation_dimensions[[2L]]),
  paired_source_present = file.exists(file.path(root, site_deviation_source_relative)),
  alt_text_present = length(site_deviation_alt) == 1L && nzchar(site_deviation_alt),
  interval_type = "Pointwise 95% confidence intervals",
  visual_review_status = "PASS",
  reviewer = "Codex original-resolution visual inspection",
  review_date = as.Date("2026-08-13"),
  review_notes = paste(
    "Original-resolution faceted PNG inspected.",
    "All ten strips, nine site rows per panel, site colours, intervals,",
    "log-scale null lines, wrapped caption, and final-size labels pass.",
    "No interval or caption clipping was observed."
  ),
  authorization = "Author-requested Stage 3 revision",
  gate = "H06-D-G3"
)
revision_figure_qa <- bind_rows(
  base_figure_qa,
  site_deviation_figure_qa,
  temporal_figure_qa
)
write_project_csv(
  revision_figure_qa,
  paste0(
    "artifacts/12_manifests/H06_daily/",
    "H06_daily_stage3_revision_figure_readability_qa.csv"
  )
)

qmd_relative <- "notebooks/hypotheses/H06_daily.qmd"
html_relative <- "notebooks/hypotheses/H06_daily.html"
qmd_path <- file.path(root, qmd_relative)
html_path <- file.path(root, html_relative)
assert_files(c(qmd_relative, html_relative))
qmd <- paste(readLines(qmd_path, warn = FALSE), collapse = "\n")
html <- xml2::read_html(html_path)
main <- xml2::xml_find_first(html, "//main")
main_text <- xml2::xml_text(main)
tables <- xml2::xml_find_all(html, "//main//table")
images <- xml2::xml_find_all(html, "//main//img")
image_alt <- xml2::xml_attr(images, "alt")
image_src <- xml2::xml_attr(images, "src")
callout <- xml2::xml_find_all(
  html,
  paste0(
    "//div[contains(concat(' ', normalize-space(@class), ' '), ' callout-note ')",
    " and contains(concat(' ', normalize-space(@class), ' '), ' no-icon ')]",
    "//*[contains(@class, 'callout-title') and ",
    "contains(normalize-space(.), 'Answer in brief')]"
  )
)
gt_tables <- xml2::xml_find_all(
  html,
  "//main//table[contains(concat(' ', normalize-space(@class), ' '), ' gt_table ')]"
)
math_inline <- xml2::xml_find_all(
  html,
  "//main//span[contains(concat(' ', normalize-space(@class), ' '), ' math ') and contains(concat(' ', normalize-space(@class), ' '), ' inline ')]"
)
headings <- xml2::xml_text(xml2::xml_find_all(html, "//main//*[self::h1 or self::h2 or self::h3]"))
captions <- xml2::xml_text(xml2::xml_find_all(html, "//main//figcaption"))
site_color_dots <- xml2::xml_find_all(
  html,
  paste0(
    "//main//span[contains(@style, 'color:') and ",
    "contains(normalize-space(.), '●')]"
  )
)
fixed_count <- function(text, pattern) {
  matches <- gregexpr(pattern, text, fixed = TRUE)[[1L]]
  if (identical(matches[[1L]], -1L)) 0L else length(matches)
}

required_headings <- c(
  "Supported predictor-by-site interactions",
  "Complementary placement evidence",
  "Gap-timing-unaware sensitivity",
  "Exploratory mutually adjusted daily analysis",
  "Exploratory 30-minute time-of-day GAMM",
  "Comparison with the selected main H06 analysis"
)
required_batch_captions <- c(
  "Primary near-eye predictor-specific participant-day associations.",
  "Equal-site contrasts and site adjustment factors for primary interaction blocks retained by the global FDR rule.",
  "Exploratory mutually adjusted daily-model FDR families.",
  "Exploratory primary near-eye 30-minute GAMM summaries.",
  "Selected main hourly H06 versus daily mean-melEDI associations."
)
batch_caption_presence <- vapply(
  required_batch_captions,
  function(expected) any(grepl(expected, captions, fixed = TRUE)),
  logical(1L)
)

render_qa <- tribble(
  ~check_id, ~expected, ~observed, ~status, ~method, ~notes,
  "standalone_html",
  "Rendered HTML exists and is nonempty",
  as.character(file.info(html_path)$size),
  if_else(file.info(html_path)$size > 0, "PASS", "FAIL"),
  "Filesystem and xml2 parse",
  "Isolated Quarto render completed successfully",
  "answer_in_brief_note",
  "One simple note callout with no icon",
  as.character(length(callout)),
  if_else(length(callout) == 1L, "PASS", "FAIL"),
  "Rendered DOM",
  "The answer callout is not a warning or important callout",
  "compact_tables",
  "Fourteen gt tables",
  paste0(length(tables), " total; ", length(gt_tables), " gt"),
  if_else(length(tables) == 14L && length(gt_tables) == 14L, "PASS", "FAIL"),
  "Rendered DOM",
  "Primary, complementary, sensitivity, and exploratory batches are separated",
  "embedded_figures",
  "Five embedded reader figures",
  as.character(length(images)),
  if_else(length(images) == 5L, "PASS", "FAIL"),
  "Rendered DOM",
  "All resources are embedded in the standalone HTML",
  "figure_alt_text",
  "Nonempty alt text for all five figures",
  as.character(sum(!is.na(image_alt) & nzchar(image_alt))),
  if_else(length(images) == 5L && all(!is.na(image_alt) & nzchar(image_alt)), "PASS", "FAIL"),
  "Rendered DOM",
  "Alt text is present on each image element",
  "embedded_image_payloads",
  "Five embedded PNG data payloads",
  as.character(sum(startsWith(image_src, "data:image/png;base64,"))),
  if_else(length(images) == 5L && all(startsWith(image_src, "data:image/png;base64,")), "PASS", "FAIL"),
  "Rendered DOM",
  "No external image dependency remains in the HTML",
  "dynamic_source_links",
  "Main H06 and preregistration-deviation source links",
  paste0(
    "H06.qmd=",
    grepl("[main H06 analysis](H06.qmd)", qmd, fixed = TRUE),
    "; deviations=",
    grepl("../preregistration_deviations.qmd#dev-015", qmd, fixed = TRUE)
  ),
  if_else(
    grepl("[main H06 analysis](H06.qmd)", qmd, fixed = TRUE) &&
      grepl("../preregistration_deviations.qmd#dev-015", qmd, fixed = TRUE),
    "PASS",
    "FAIL"
  ),
  "QMD source inspection",
  "Links remain project-relative and resolve in a later project render",
  "reader_language",
  "No V0, gate, pilot, repair, sealed, or frozen reader language",
  as.character(grepl(
    "\\b(V0|gate|pilot|repair|sealed|frozen)\\b",
    main_text,
    ignore.case = TRUE,
    perl = TRUE
  )),
  if_else(
    !grepl(
      "\\b(V0|gate|pilot|repair|sealed|frozen)\\b",
      main_text,
      ignore.case = TRUE,
      perl = TRUE
    ),
    "PASS",
    "FAIL"
  ),
  "Rendered reader text",
  "Scientific metric-construction terminology is not treated as history",
  "pointwise_intervals",
  "Pointwise 95% CIs and an explicit non-simultaneous statement",
  paste0(
    "pointwise=",
    grepl("pointwise 95% confidence intervals", main_text, fixed = TRUE),
    "; nonsimultaneous=",
    grepl("none is simultaneous", main_text, fixed = TRUE)
  ),
  if_else(
    grepl("pointwise 95% confidence intervals", main_text, fixed = TRUE) &&
      grepl("none is simultaneous", main_text, fixed = TRUE),
    "PASS",
    "FAIL"
  ),
  "Rendered reader text",
  "No simultaneous interval was constructed",
  "reader_sections",
  "All requested result sections are present",
  paste(required_headings %in% headings, collapse = ","),
  if_else(all(required_headings %in% headings), "PASS", "FAIL"),
  "Rendered headings",
  "Site, batch, joint, GAMM, and main-H06 requests are represented",
  "batch_captions",
  "Requested result batches are explicitly captioned",
  paste(batch_caption_presence, collapse = ","),
  if_else(all(batch_caption_presence), "PASS", "FAIL"),
  "Rendered captions",
  "Sensitivity and exploratory results are not merged into the primary table",
  "inline_math",
  "Rendered inline math spans for the GAMM estimand",
  as.character(length(math_inline)),
  if_else(length(math_inline) >= 2L, "PASS", "FAIL"),
  "Rendered DOM",
  "The shifted-log response is encoded as Quarto inline math",
  "primary_site_mean_example",
  "Mean-melEDI site contrasts identify the four pointwise-clear sites",
  paste(
    c("Dortmund", "Tübingen", "Madrid", "Kumasi") %in%
      unlist(strsplit(main_text, "[^[:alpha:]üÜíÍ]+", perl = TRUE)),
    collapse = ","
  ),
  if_else(
    all(vapply(
      c("Dortmund", "Tübingen", "Madrid", "Kumasi"),
      function(site) grepl(site, main_text, fixed = TRUE),
      logical(1L)
    )),
    "PASS",
    "FAIL"
  ),
  "Rendered reader text",
  "The requested interaction-model answer is explicit",
  "site_colour_markers",
  "One submitted-colour filled dot before each of 144 site mentions",
  as.character(length(site_color_dots)),
  if_else(length(site_color_dots) == 144L, "PASS", "FAIL"),
  "Rendered DOM",
  paste(
    "Ninety primary and 54 mutually adjusted site contrasts use the",
    "submitted site colours; dots do not encode significance"
  ),
  "site_effect_scale",
  "Primary adjustment factors and mutually adjusted full effects are distinguished",
  paste0(
    "primary-factor-definition=",
    grepl("Multiplying the equal-site ratio", main_text, fixed = TRUE),
    "; joint-not-a-multiplier=",
    grepl("not a multiplier", main_text, fixed = TRUE),
    "; recovery-formula=",
    grepl("recovers the site", main_text, fixed = TRUE)
  ),
  if_else(
    grepl("Multiplying the equal-site ratio", main_text, fixed = TRUE) &&
      grepl("not a multiplier", main_text, fixed = TRUE) &&
      grepl("recovers the site", main_text, fixed = TRUE),
    "PASS",
    "FAIL"
  ),
  "Rendered reader text",
  paste(
    "Table 4 factors multiply the equal-site ratio; the later exploratory",
    "table continues to show full site-specific ratios"
  ),
  "comparison_interaction_selection",
  "Four supported mean-melEDI comparisons use interaction-model contrasts",
  as.character(fixed_count(
    main_text,
    "Interaction model: equal-site full contrast"
  )),
  if_else(
    fixed_count(main_text, "Interaction model: equal-site full contrast") == 4L,
    "PASS",
    "FAIL"
  ),
  "Rendered reader text",
  paste(
    "Main hourly day type, daily predictor-specific day type and activity,",
    "and mutually adjusted daily day type use supported interaction models"
  ),
  "figure_visual_review",
  "Five original-resolution figure reviews pass",
  as.character(sum(revision_figure_qa$visual_review_status == "PASS")),
  if_else(
    nrow(revision_figure_qa) == 5L &&
      all(revision_figure_qa$visual_review_status == "PASS"),
    "PASS",
    "FAIL"
  ),
  "Original-resolution image inspection",
  "Labels, legends, balance, clipping, and overlap were inspected",
  "local_browser_visual_review",
  "Automated local file visual inspection where permitted",
  "Unavailable",
  "DISCLOSED_LIMITATION",
  "In-app browser policy",
  paste(
    "The browser blocked automated file:// access. No workaround was used;",
    "rendered-DOM, table-structure, and original-resolution figure QA remain."
  )
) |>
  mutate(
    authorization = "H06-D-015 plus author-requested Stage 3 revision",
    gate = "H06-D-G3",
    review_date = "2026-08-13"
  )
if (any(render_qa$status == "FAIL")) {
  stop(
    paste0(
      "Stage 3 render-QA failure: ",
      paste0(
        render_qa$check_id[render_qa$status == "FAIL"],
        " [observed=",
        render_qa$observed[render_qa$status == "FAIL"],
        "]",
        collapse = ", "
      )
    ),
    call. = FALSE
  )
}
write_project_csv(
  render_qa,
  "artifacts/12_manifests/H06_daily/H06_daily_stage3_render_qa.csv"
)

output_paths <- c(
  "audit/hypotheses/H06_daily/H06_daily_gap_clock_repair_transition.md",
  "audit/hypotheses/H06_daily/H06_daily_joint_context_exploratory_authorization.md",
  "audit/hypotheses/H06_daily/H06_daily_stage3_revision_gate.md",
  "audit/handoffs/H06_daily_worker_handoff.md",
  "scripts/hypotheses/H06_daily/build_h06_daily_stage3_reader.R",
  "scripts/hypotheses/H06_daily/build_h06_daily_stage3_revision_inputs.R",
  "scripts/hypotheses/H06_daily/h06_daily_joint_context_exploratory_contract.R",
  "scripts/hypotheses/H06_daily/run_h06_daily_joint_context_exploratory.R",
  "scripts/hypotheses/H06_daily/seal_h06_daily_stage3_reader.R",
  "tests/hypotheses/H06_daily/test_h06_daily_joint_context_exploratory.R",
  "tests/hypotheses/H06_daily/test_h06_daily_stage3_reader_report.R",
  qmd_relative,
  html_relative,
  "artifacts/10_figures/H06_daily/H06_daily_non_l10_production_primary_ratio_effects.png",
  "artifacts/10_figures/H06_daily/H06_daily_non_l10_production_primary_absolute_effects.png",
  "artifacts/10_figures/H06_daily/H06_daily_stage3_fdr_overview.png",
  "artifacts/10_figures/H06_daily/H06_daily_stage3_fdr_overview.svg",
  site_deviation_figure_relative,
  "artifacts/10_figures/H06_daily/H06_daily_stage3_primary_site_deviations.svg",
  temporal_figure_relative,
  source_paths,
  paste0(
    "artifacts/12_manifests/H06_daily/",
    c(
      "H06_daily_stage3_input_manifest.csv",
      "H06_daily_stage3_revision_input_manifest.csv",
      "H06_daily_stage3_figure_readability_qa.csv",
      "H06_daily_stage3_revision_figure_readability_qa.csv",
      "H06_daily_joint_context_exploratory_input_manifest.csv",
      "H06_daily_joint_context_exploratory_code_manifest.csv",
      "H06_daily_joint_context_exploratory_output_manifest.csv",
      "H06_daily_joint_context_exploratory_software_manifest.csv",
      "H06_daily_stage3_source_data_manifest.csv",
      "H06_daily_stage3_software_manifest.csv",
      "H06_daily_stage3_render_qa.csv"
    )
  )
)
output_roles <- c(
  "Task-owned Stage 2 acceptance transition",
  "Task-local authorization for the exploratory joint-context revision",
  "Revised H06-D-G3 author stop-gate record",
  "Revised task-owned H06_daily worker handoff",
  "Bounded original Stage 3 display builder",
  "No-refit Stage 3 revision input and contrast builder",
  "Exploratory joint-context model contract",
  "Exploratory joint-context production script",
  "Non-circular revised Stage 3 provenance sealer",
  "Focused exploratory joint-context verification",
  "Focused revised Stage 3 identity and reader-report verification",
  "Standalone complementary reader-report source",
  "Standalone complementary reader-report HTML",
  "Reused primary ratio-scale reader figure",
  "Reused primary absolute-scale reader figure",
  "Stage 3 FDR decision overview PNG",
  "Stage 3 FDR decision overview SVG",
  "Primary site-to-equal-site deviation figure PNG",
  "Primary site-to-equal-site deviation figure SVG",
  "Accepted temporal GAMM context-function figure",
  source_roles,
  "Exact accepted original Stage 3 input contract",
  "Exact Stage 3 revision input and preservation contract",
  "Original three-figure readability QA",
  "Revised five-figure readability and source-data QA",
  "Exploratory joint-context input contract",
  "Exploratory joint-context code manifest",
  "Exploratory joint-context output manifest",
  "Exploratory joint-context software manifest",
  "Non-circular revised Stage 3 source-data manifest",
  "Revised Stage 3 software manifest",
  "Revised Stage 3 structural and disclosed visual-QA record"
)
output_manifest <- manifest_rows(output_paths, output_roles)
stopifnot(
  !anyDuplicated(output_manifest$relative_path),
  !"artifacts/12_manifests/H06_daily/H06_daily_stage3_output_manifest.csv" %in%
    output_manifest$relative_path
)
write_project_csv(
  output_manifest,
  "artifacts/12_manifests/H06_daily/H06_daily_stage3_output_manifest.csv"
)

message(
  "H06_daily revised Stage 3 seal complete: ",
  nrow(source_manifest),
  " source-data entries, ",
  nrow(software_manifest),
  " software entries, ",
  nrow(render_qa),
  " render-QA checks, ",
  nrow(revision_figure_qa),
  " figure reviews, and ",
  nrow(output_manifest),
  " non-circular output identities."
)
