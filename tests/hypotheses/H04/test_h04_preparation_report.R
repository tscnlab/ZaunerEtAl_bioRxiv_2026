# Structural, source-data, display, and provenance checks for the H04
# analysis-preparation companion. These checks do not fit or refit models.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
project_library <- file.path(
  root,
  "renv/library/macos/R-4.6/aarch64-apple-darwin23"
)
.libPaths(c(project_library, .libPaths()))

suppressPackageStartupMessages({
  library(readr)
  library(xml2)
})
source(file.path(root, "scripts/pipeline/paths_io.R"))
source(file.path(
  root,
  "scripts/pipeline/hypothesis_preparation_provenance_contract.R"
))

paths <- preparation_companion_paths(root, "H04")
required_local <- c(
  paths$qmd,
  paths$html,
  paths$rendered_qmd,
  paths$result_qmd,
  paths$result_html,
  paths$manifest
)
stopifnot(all(file.exists(required_local)))

qmd_lines <- readLines(paths$qmd, warn = FALSE, encoding = "UTF-8")
qmd <- paste(qmd_lines, collapse = "\n")
stopifnot(
  grepl("flowchart TD", qmd, fixed = TRUE),
  grepl("../../../notebooks/hypotheses/H04.qmd", qmd, fixed = TRUE),
  grepl(
    "../../../notebooks/hypotheses/H04.qmd#h04-preregistration-deviations",
    qmd,
    fixed = TRUE
  ),
  grepl("gap-timing-unaware dataset", qmd, fixed = TRUE),
  grepl("one-hour zero-aware geometric mean melEDI", qmd, fixed = TRUE),
  grepl("geo_medi_1h ~ site + activity", qmd, fixed = TRUE),
  grepl("geo_medi_1h ~ site * activity_named", qmd, fixed = TRUE),
  grepl(
    "geo_medi_1h ~ site * activity_named + (1 | participant)",
    qmd,
    fixed = TRUE
  ),
  grepl(
    "H04_participant_random_intercept_summary.csv",
    qmd,
    fixed = TRUE
  ),
  grepl(
    "{#sec-h04-prep-participant-random-intercept}",
    qmd,
    fixed = TRUE
  ),
  grepl("participant-level variation", qmd, fixed = TRUE),
  grepl(
    paste0(
      "random intercept lets participants have different[[:space:]]+",
      "overall exposure levels"
    ),
    qmd,
    perl = TRUE
  ),
  grepl(
    "generalized linear mixed model was fitted in R with `glmmTMB`",
    qmd,
    fixed = TRUE
  ),
  !grepl("stable participant-level heterogeneity", qmd, fixed = TRUE),
  grepl("s(time_hour, bs = \"cc\", k = 12)", qmd, fixed = TRUE),
  grepl(
    "s(time_hour, activity, bs = \"sz\", k = 12)",
    qmd,
    fixed = TRUE
  ),
  grepl("s(time_hour, site, bs = \"sz\", k = 12)", qmd, fixed = TRUE),
  grepl(
    "s(time_hour, participant, bs = \"fs\", k = 10)",
    qmd,
    fixed = TRUE
  ),
  grepl("s(participant_day, bs = \"re\")", qmd, fixed = TRUE),
  grepl("participant-clustered HC1", qmd, fixed = TRUE),
  grepl("back-transform", qmd, ignore.case = TRUE),
  grepl("VERIFIED CURRENT IDENTITY", qmd, fixed = TRUE),
  grepl("::: {.callout-note", qmd, fixed = TRUE),
  !grepl("::: {.callout-important", qmd, fixed = TRUE),
  !grepl("::: {.callout-warning", qmd, fixed = TRUE),
  !grepl("H04-F[0-9]", qmd, perl = TRUE),
  !grepl("V0", qmd, fixed = TRUE),
  !grepl("longest bout", qmd, ignore.case = TRUE)
)

source_data_contract <- c(
  "artifacts/11_source_data/H04/H04_preparation_frame_integrity.csv" = 2L,
  "artifacts/11_source_data/H04/H04_preparation_zero_summary.csv" = 2L,
  "artifacts/11_source_data/H04/H04_preparation_positive_response_distribution.csv" = 80L,
  "artifacts/11_source_data/H04/H04_preparation_category_support.csv" = 12L,
  "artifacts/11_source_data/H04/H04_preparation_site_category_support.csv" = 102L,
  "artifacts/11_source_data/H04/H04_preparation_clock_category_support.csv" = 288L,
  "artifacts/11_source_data/H04/H04_preparation_participant_day_support.csv" = 1599L
)
for (relative_path in names(source_data_contract)) {
  data <- readr::read_csv(
    file.path(root, relative_path),
    show_col_types = FALSE
  )
  stopifnot(nrow(data) == unname(source_data_contract[[relative_path]]))
}

integrity <- readr::read_csv(
  file.path(
    root,
    "artifacts/11_source_data/H04/H04_preparation_frame_integrity.csv"
  ),
  show_col_types = FALSE
)
category_support <- readr::read_csv(
  file.path(
    root,
    "artifacts/11_source_data/H04/H04_preparation_category_support.csv"
  ),
  show_col_types = FALSE
)
site_support <- readr::read_csv(
  file.path(
    root,
    paste0(
      "artifacts/11_source_data/H04/",
      "H04_preparation_site_category_support.csv"
    )
  ),
  show_col_types = FALSE
)
clock_support <- readr::read_csv(
  file.path(
    root,
    paste0(
      "artifacts/11_source_data/H04/",
      "H04_preparation_clock_category_support.csv"
    )
  ),
  show_col_types = FALSE
)
reconciliation <- readr::read_csv(
  file.path(
    root,
    "artifacts/08_diagnostics/H04/H04_metric010_input_reconciliation.csv"
  ),
  show_col_types = FALSE
)
invariance <- readr::read_csv(
  file.path(
    root,
    "artifacts/08_diagnostics/H04/H04_metric010_frame_invariance.csv"
  ),
  show_col_types = FALSE
)
stopifnot(
  identical(integrity$long_rows, c(17266, 21071)),
  identical(integrity$unique_participant_hours, c(16526, 20128)),
  identical(integrity$participants, c(126, 150)),
  identical(integrity$participant_days, c(724, 875)),
  identical(integrity$sites, c(9, 8)),
  identical(integrity$categories, c(6, 6)),
  all(integrity$duplicate_hour_activity_memberships == 0L),
  all(integrity$missing_outcome_rows == 0L),
  all(integrity$missing_activity_rows == 0L),
  all(integrity$invalid_response_rows == 0L),
  all(integrity$invalid_weight_rows == 0L),
  all(integrity$hour_response_conflicts == 0L),
  all(integrity$row_k_mismatches == 0L),
  all(integrity$distinct_label_mismatches == 0L),
  all(integrity$long_k_mismatches == 0L),
  all(integrity$maximum_weight_sum_error < 1e-12),
  identical(integrity$co_selected_other_suppressed_hours, c(67, 119)),
  all(integrity$co_selected_other_retained_rows == 0L),
  identical(integrity$other_only_hours, c(391, 631)),
  identical(integrity$exact_zero_unique_hours, c(4784, 5923)),
  identical(integrity$positive_unique_hours, c(11742, 14205)),
  nrow(category_support) == 12L,
  sum(site_support$support_status == "Supported") == 98L,
  sum(site_support$support_status == "Observed but sparse") == 4L,
  sum(clock_support$support_status == "Supported") == 202L,
  sum(clock_support$support_status == "Locally sparse") == 81L,
  sum(clock_support$support_status == "No observations") == 5L,
  all(clock_support$clock_hour %in% 0:23),
  nrow(reconciliation) == 2L,
  all(reconciliation$current_contract_verified),
  all(reconciliation$all_downstream_frame_values_identical),
  nrow(invariance) == 14L,
  all(invariance$values_match_tolerance_zero)
)

document <- xml2::read_html(paths$html)
main <- xml2::xml_find_first(
  document,
  "//main[@id='quarto-document-content']"
)
stopifnot(!inherits(main, "xml_missing"))
main_text <- xml2::xml_text(main)
stopifnot(
  grepl("H04 analysis preparation and provenance", main_text, fixed = TRUE),
  grepl("17,266", main_text, fixed = TRUE),
  grepl("21,071", main_text, fixed = TRUE),
  grepl("16,526", main_text, fixed = TRUE),
  grepl("20,128", main_text, fixed = TRUE),
  grepl("126", main_text, fixed = TRUE),
  grepl("150", main_text, fixed = TRUE),
  grepl("724", main_text, fixed = TRUE),
  grepl("875", main_text, fixed = TRUE),
  grepl("gap-timing-unaware dataset", main_text, fixed = TRUE),
  grepl(
    "Exploratory participant random-intercept decomposition",
    main_text,
    fixed = TRUE
  ),
  grepl("Marginal R²", main_text, fixed = TRUE),
  grepl("Conditional R²", main_text, fixed = TRUE),
  !grepl("H04-F[0-9]", main_text, perl = TRUE),
  !grepl("Execution halted", main_text, fixed = TRUE)
)

participant_r2_table <- xml2::xml_find_first(
  main,
  ".//*[@id='tbl-h04-prep-participant-r2']"
)
participant_r2_table_text <- xml2::xml_text(participant_r2_table)
stopifnot(
  !inherits(participant_r2_table, "xml_missing"),
  grepl("0.766", participant_r2_table_text, fixed = TRUE),
  grepl("0.858", participant_r2_table_text, fixed = TRUE),
  grepl("0.768", participant_r2_table_text, fixed = TRUE),
  grepl("0.859", participant_r2_table_text, fixed = TRUE)
)

expected_figures <- c(
  "fig-h04-prep-positive-distribution",
  "fig-h04-prep-category-support",
  "fig-h04-prep-site-category-support",
  "fig-h04-prep-clock-category-support"
)
for (figure_id in expected_figures) {
  figure <- xml2::xml_find_first(
    main,
    paste0(".//*[@id='", figure_id, "']")
  )
  stopifnot(!inherits(figure, "xml_missing"))
  image <- xml2::xml_find_first(figure, ".//img")
  caption <- xml2::xml_find_first(figure, ".//figcaption")
  stopifnot(
    !inherits(image, "xml_missing"),
    !inherits(caption, "xml_missing"),
    nzchar(xml2::xml_attr(image, "alt")),
    nzchar(trimws(xml2::xml_text(caption)))
  )
}

qa <- readr::read_csv(
  file.path(
    root,
    paste0(
      "artifacts/12_manifests/H04/",
      "H04_preparation_figure_readability_qa.csv"
    )
  ),
  show_col_types = FALSE
)
qa_checks <- c(
  "clipping_or_cropping",
  "overlaps",
  "text_shape_and_distortion",
  "wrapping_and_units",
  "important_text_readable",
  "legend_and_data_region_balance",
  "marks_and_lines_distinguishable",
  "caption_and_alt_text_present"
)
stopifnot(
  nrow(qa) == 4L,
  setequal(qa$figure_id, expected_figures),
  all(qa$status == "PASS"),
  all(qa$overall_status == "PASS"),
  all(qa$visual_status == "PASS"),
  all(qa$typography_status == "PASS_BY_CALCULATION"),
  all(qa$intended_display_width_mm == 170),
  all(qa$effective_final_essential_text_pt >= 5),
  all(qa$effective_final_central_text_pt >= 7),
  all(vapply(
    qa[qa_checks],
    function(value) all(value == "PASS"),
    logical(1)
  )),
  file.exists(file.path(
    root,
    "artifacts/12_manifests/H04/H04_preparation_figure_A4_proofs.pdf"
  ))
)

preparation_manifest <- readr::read_csv(
  paths$manifest,
  show_col_types = FALSE
)
manifest_absolute_paths <- file.path(root, preparation_manifest$path)
stopifnot(
  nrow(preparation_manifest) >= 250L,
  !anyDuplicated(preparation_manifest$path),
  all(file.exists(manifest_absolute_paths)),
  all(c(
    "preparation_source",
    "preparation_website_source",
    "preparation_website_render",
    "preparation_website_page_asset"
  ) %in% preparation_manifest$role),
  !any(preparation_manifest$role %in% c(
    "preparation_direct_render",
    "preparation_direct_page_asset"
  )),
  !any(
    preparation_manifest$path ==
      "audit/hypotheses/H04/H04_analysis_preparation.html"
  ),
  !any(startsWith(
    preparation_manifest$path,
    "audit/hypotheses/H04/H04_analysis_preparation_files/"
  )),
  "artifacts/12_manifests/H04/H04_stage3_artifacts.csv" %in%
    preparation_manifest$path,
  !"artifacts/12_manifests/H04/H04_preparation_report_manifest.csv" %in%
    preparation_manifest$path,
  identical(
    unname(vapply(
      manifest_absolute_paths,
      artifact_sha256,
      character(1L)
    )),
    preparation_manifest$sha256
  )
)

# H04 uses dynamic QMD source links under the accepted harmonization contract.
# The registered HTML pages still resolve those links to reciprocal HTML hrefs.
source_copy_identical <- identical(
  read_file_bytes(paths$qmd),
  read_file_bytes(paths$rendered_qmd)
)
profile_lines <- readLines(
  paths$quarto_profile,
  warn = FALSE,
  encoding = "UTF-8"
)
assert_adjacent_profile_entries(
  profile_lines,
  "notebooks/hypotheses/H04.qmd",
  "audit/hypotheses/H04/H04_analysis_preparation.qmd"
)

forbidden_calls <- c(
  "mgcv::gam", "mgcv::bam", "gam", "bam",
  "lme4::lmer", "lmer", "lme4::glmer", "glmer",
  "glmmTMB::glmmTMB", "glmmTMB", "brms::brm", "brm",
  "stats::predict", "predict", "stats::simulate", "simulate",
  "boot::boot", "boot", "emmeans::emmeans", "emmeans",
  "h04_fit_quasi", "h04_fit_additive_run",
  "h04_fit_interaction_architecture", "h04_fit_temporal_model",
  "h04_fit_reader_temporal_model", "h04_temporal_model",
  "h04_leave_one_site_out"
)
stopifnot(length(intersect(
  executable_r_call_names(qmd_lines),
  forbidden_calls
)) == 0L)

note_callouts <- xml2::xml_find_all(
  main,
  ".//*[contains(concat(' ', normalize-space(@class), ' '), ' callout-note ')]"
)
warning_callouts <- xml2::xml_find_all(
  main,
  paste0(
    ".//*[contains(@class, 'callout-important') or ",
    "contains(@class, 'callout-warning') or ",
    "contains(@class, 'callout-caution') or ",
    "contains(@class, 'callout-danger')]"
  )
)
result_href <- "../../../notebooks/hypotheses/H04.html"
result_links <- xml2::xml_find_all(
  main,
  paste0(".//a[contains(@href, '", result_href, "')]")
)
result_document <- xml2::read_html(paths$result_html)
result_main <- xml2::xml_find_first(
  result_document,
  "//main[@id='quarto-document-content']"
)
prep_href <- "../../audit/hypotheses/H04/H04_analysis_preparation.html"
prep_links <- xml2::xml_find_all(
  result_main,
  paste0(".//a[contains(@href, '", prep_href, "')]")
)
gt_tables <- xml2::xml_find_all(
  main,
  ".//table[contains(concat(' ', normalize-space(@class), ' '), ' gt_table ')]"
)
required_manifest_paths <- c(
  "audit/hypotheses/H04/H04_analysis_preparation.qmd",
  paste0(
    "_build/nathealth/audit/hypotheses/H04/",
    "H04_analysis_preparation.qmd"
  ),
  paste0(
    "_build/nathealth/audit/hypotheses/H04/",
    "H04_analysis_preparation.html"
  ),
  "_quarto-nathealth.yml"
)

verification <- list(
  figures = length(xml2::xml_find_all(main, ".//figure")),
  gt_tables = length(gt_tables),
  manifest_identities = nrow(preparation_manifest),
  source_copy_identical = source_copy_identical
)

stopifnot(
  verification$figures >= 4L,
  verification$gt_tables >= 24L,
  verification$manifest_identities >= 60L,
  isTRUE(verification$source_copy_identical),
  length(note_callouts) >= 1L,
  length(warning_callouts) == 0L,
  length(result_links) >= 1L,
  !inherits(result_main, "xml_missing"),
  length(prep_links) >= 1L,
  all(required_manifest_paths %in% preparation_manifest$path)
)

message(
  "H04 preparation companion verified: ",
  verification$figures,
  " figures, ",
  verification$gt_tables,
  " gt tables, ",
  verification$manifest_identities,
  " manifest identities, and byte-identical website QMD provenance copy"
)
