# Structural, source-data, display, and provenance checks for the H08
# analysis-preparation companion. These checks never fit or refit a model.

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

preintegration_only <- identical(
  tolower(Sys.getenv("H08_PREINTEGRATION_ONLY", unset = "false")),
  "true"
)
paths <- preparation_companion_paths(root, "H08")
if (preintegration_only) {
  html_path <- file.path(
    root,
    "audit/hypotheses/H08/H08_analysis_preparation.html"
  )
  stopifnot(file.exists(paths$qmd), file.exists(html_path))
  verification <- NULL
} else {
  verification <- verify_hypothesis_preparation_companion(
    root = root,
    hypothesis_id = "H08",
    min_figures = 3L,
    min_gt_tables = 19L,
    extra_forbidden_calls = c(
      "h08_fit_model",
      "h08_fit_bundle",
      "h08_fit_inferential_bundle",
      "h08_model_diagnostics",
      "h08_leave_one_site_out",
      "h08_photoperiod_sensitivity",
      "h08_participant_summary_sensitivity"
    )
  )
  html_path <- paths$html
}

qmd_lines <- readLines(paths$qmd, warn = FALSE, encoding = "UTF-8")
qmd <- paste(qmd_lines, collapse = "\n")
stopifnot(
  grepl("flowchart TD", qmd, fixed = TRUE),
  grepl("../../../notebooks/hypotheses/H08.html", qmd, fixed = TRUE),
  grepl("gap-timing-unaware\\s+dataset", qmd, perl = TRUE),
  grepl("at least 50% valid", qmd, fixed = TRUE),
  grepl("at least 80% valid", qmd, fixed = TRUE),
  grepl("timing of the\\s+remaining missing observations", qmd, perl = TRUE),
  grepl("time-sensitive primary metric dataset", qmd, fixed = TRUE),
  grepl("Exact evaluated Wilkinson formulae", qmd, fixed = TRUE),
  grepl("complete nine-test", qmd, fixed = TRUE),
  grepl("no adjusted p-value met the 0.050 criterion", qmd, fixed = TRUE),
  grepl("METRIC-011 exact-zero maintenance", qmd, fixed = TRUE),
  grepl("H08_metric011_result_comparison.csv", qmd, fixed = TRUE),
  grepl("H08_metric011_reconciliation.csv", qmd, fixed = TRUE),
  grepl("fig-width: 6.692913", qmd, fixed = TRUE),
  grepl("out-width: \"100%\"", qmd, fixed = TRUE),
  grepl("::: {.callout-note", qmd, fixed = TRUE),
  !grepl("::: {.callout-important", qmd, fixed = TRUE),
  !grepl("::: {.callout-warning", qmd, fixed = TRUE)
)

if (preintegration_only) {
  executable_calls <- executable_r_call_names(qmd_lines)
  prohibited_calls <- c(
    "mgcv::gam",
    "mgcv::bam",
    "gam",
    "bam",
    "lme4::lmer",
    "lmer",
    "glmmTMB::glmmTMB",
    "glmmTMB",
    "stats::predict",
    "predict",
    "stats::simulate",
    "simulate",
    "boot::boot",
    "boot",
    "h08_fit_model",
    "h08_fit_bundle",
    "h08_fit_inferential_bundle",
    "h08_model_diagnostics",
    "h08_leave_one_site_out"
  )
  stopifnot(length(intersect(executable_calls, prohibited_calls)) == 0L)
}

document <- xml2::read_html(html_path)
main <- xml2::xml_find_first(
  document,
  "//main[@id='quarto-document-content']"
)
stopifnot(!inherits(main, "xml_missing"))
main_text <- xml2::xml_text(main)
stopifnot(
  grepl("H08 analysis preparation and provenance", main_text, fixed = TRUE),
  grepl("184 participants", main_text, fixed = TRUE),
  grepl("108 frames", main_text, fixed = TRUE),
  grepl("12 unique runs", main_text, fixed = TRUE),
  grepl("18 exact pairs", main_text, fixed = TRUE),
  grepl("139–141 participants", main_text, fixed = TRUE),
  grepl("655–816 participant-days", main_text, fixed = TRUE),
  grepl("153–154 participants", main_text, fixed = TRUE),
  grepl("743–902", main_text, fixed = TRUE),
  grepl("All 153 planned", main_text, fixed = TRUE),
  grepl("no adjusted p-value met the 0.050 criterion", main_text, fixed = TRUE),
  grepl("METRIC-011 exact-zero maintenance", main_text, fixed = TRUE),
  grepl("6 of 6", main_text, fixed = TRUE),
  !grepl("Execution halted", main_text, fixed = TRUE)
)

main_reader <- xml2::read_html(html_path)
reader_content <- xml2::xml_find_first(
  main_reader,
  "//main[@id='quarto-document-content']"
)
xml2::xml_remove(xml2::xml_find_all(
  reader_content,
  ".//div[contains(concat(' ', normalize-space(@class), ' '), ' sourceCode ')]"
))
reader_text <- xml2::xml_text(reader_content)
reader_text_lower <- tolower(reader_text)
stopifnot(
  !grepl("\\bStage\\s+[0-9]+\\b", reader_text, ignore.case = TRUE, perl = TRUE),
  !grepl("\\bStep\\s+[0-9]+\\b", reader_text, ignore.case = TRUE, perl = TRUE),
  !grepl("worker task", reader_text_lower, fixed = TRUE),
  !grepl("coordinator task", reader_text_lower, fixed = TRUE),
  !grepl("migration history", reader_text_lower, fixed = TRUE),
  !grepl("v0 analysis", reader_text_lower, fixed = TRUE),
  !grepl("temperature", reader_text_lower, fixed = TRUE),
  !grepl("longest bout", reader_text_lower, fixed = TRUE)
)

report_010_position <- regexpr(
  "gap-timing-unaware\\s+dataset",
  reader_text,
  ignore.case = TRUE,
  perl = TRUE
)[1L]
report_010_explanation <- regexpr(
  "at least 50% valid minutes per hour",
  reader_text_lower,
  fixed = TRUE
)[1L]
stopifnot(
  report_010_position > 0L,
  report_010_explanation > report_010_position,
  grepl("at least 80% valid hours per day", reader_text, fixed = TRUE),
  grepl("time-sensitive primary metric dataset", reader_text, fixed = TRUE)
)

formula_text <- c(
  "response_value ~ site + (1 | site:Id)",
  "response_value ~ site + VLSQ8_c + (1 | site:Id)",
  "response_value ~ site * VLSQ8_c + (1 | site:Id)",
  "response_value ~ site + photoperiod_c + (1 | site:Id)",
  "response_value ~ site + photoperiod_c + VLSQ8_c + (1 | site:Id)",
  "response_value ~ site * VLSQ8_c + photoperiod_c + (1 | site:Id)",
  "participant_response ~ site",
  "participant_response ~ site + VLSQ8_c",
  "participant_response ~ site * VLSQ8_c"
)
stopifnot(all(vapply(
  formula_text,
  grepl,
  logical(1),
  x = main_text,
  fixed = TRUE
)))

expected_figures <- c(
  "fig-h08-prep-vlsq-distribution",
  "fig-h08-prep-sample-support",
  "fig-h08-prep-site-range"
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
    identical(xml2::xml_attr(image, "style"), "width:100.0%")
  )
}

source_data_contract <- c(
  "artifacts/11_source_data/H08/H08_preparation_sample_support.csv" = 18L,
  "artifacts/11_source_data/H08/H08_preparation_vlsq_score_distribution.csv" = 24L,
  "artifacts/11_source_data/H08/H08_preparation_vlsq_site_support.csv" = 9L,
  "artifacts/11_source_data/H08/H08_preparation_site_support.csv" = 153L,
  "artifacts/11_source_data/H08/H08_preparation_site_support_summary.csv" = 17L,
  "artifacts/11_source_data/H08/H08_preparation_metric_availability.csv" = 56L
)
for (relative_path in names(source_data_contract)) {
  data <- readr::read_csv(
    file.path(root, relative_path),
    show_col_types = FALSE
  )
  stopifnot(nrow(data) == unname(source_data_contract[[relative_path]]))
}

score_audit <- readr::read_csv(
  file.path(root, "artifacts/08_diagnostics/H08/H08_vlsq_score_audit.csv"),
  show_col_types = FALSE
)
frame_index <- readr::read_csv(
  file.path(root, "artifacts/06_model_data/H08/H08_model_frame_index.csv"),
  show_col_types = FALSE
)
family_audit <- readr::read_csv(
  file.path(root, "artifacts/09_tables/H08/H08_family_audit.csv"),
  show_col_types = FALSE
)
loo_summary <- readr::read_csv(
  file.path(
    root,
    "artifacts/08_diagnostics/H08/H08_leave_one_site_out_summary.csv"
  ),
  show_col_types = FALSE
)
response_gate <- readr::read_csv(
  file.path(
    root,
    "artifacts/08_diagnostics/H08/H08_response_family_gate.csv"
  ),
  show_col_types = FALSE
)
stopifnot(
  score_audit$participants == 184L,
  score_audit$missing_scores == 0L,
  score_audit$missing_item_cells == 0L,
  score_audit$scoring_rule_verified,
  nrow(frame_index) == 108L,
  !anyDuplicated(frame_index[c("run_id", "metric_id")]),
  nrow(family_audit) == 8L,
  all(family_audit$planned_n == 9L),
  all(family_audit$observed_raw_p == 9L),
  all(family_audit$complete_nine_member_family),
  all(family_audit$independent_recalculation_matches),
  sum(family_audit$adjusted_significant_n) == 0L,
  sum(loo_summary$successful_refits) == 153L,
  nrow(response_gate) == 9L,
  all(response_gate$major_failures == 0L),
  all(response_gate$average_non_estimable == 0L),
  all(response_gate$interaction_non_estimable == 0L)
)

sample_support <- readr::read_csv(
  file.path(
    root,
    "artifacts/11_source_data/H08/H08_preparation_sample_support.csv"
  ),
  show_col_types = FALSE
)
near <- sample_support[sample_support$placement == "glasses", ]
chest <- sample_support[sample_support$placement == "chest", ]
stopifnot(
  nrow(near) == 9L,
  nrow(chest) == 9L,
  identical(range(near$participants), c(139, 141)),
  identical(range(near$participant_days), c(655, 816)),
  all(near$sites == 9L),
  identical(range(chest$participants), c(153, 154)),
  identical(range(chest$participant_days), c(743, 902)),
  all(chest$sites == 8L)
)

qa_path <- file.path(
  root,
  "artifacts/12_manifests/H08/H08_figure_physical_size_qa.csv"
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
  nrow(qa) == 8L,
  !anyDuplicated(qa$figure_id),
  all(qa$reporting_rule == "REPORT-011"),
  all(qa$native_export_width_mm == 170),
  all(qa$intended_display_width_mm == 170),
  all(abs(qa$scale_factor - 1) < 1e-10),
  all(qa$smallest_essential_nominal_text_pt >= 7.5),
  all(qa$effective_final_essential_text_pt >= 7),
  all(qa$a4_page_width_mm == 210),
  all(qa$a4_page_height_mm == 297),
  all(qa$a4_side_margin_mm == 20),
  all(qa$physical_size_calculation == "PASS"),
  all(qa$visual_inspection == "PASS"),
  all(qa$status == "PASS"),
  all(file.exists(file.path(root, qa$path))),
  all(file.exists(file.path(root, qa$source_data_path))),
  all(file.exists(file.path(root, qa$a4_proof_path))),
  all(vapply(qa[qa_checks], function(value) all(value), logical(1)))
)
current_figure_hashes <- vapply(
  file.path(root, qa$path),
  artifact_sha256,
  character(1)
)
current_proof_hashes <- vapply(
  file.path(root, qa$a4_proof_path),
  artifact_sha256,
  character(1)
)
stopifnot(
  all(current_figure_hashes == qa$figure_sha256),
  all(current_proof_hashes == qa$a4_proof_sha256)
)

result_document <- xml2::read_html(paths$result_html)
result_main <- xml2::xml_find_first(
  result_document,
  "//main[@id='quarto-document-content']"
)
result_prep_links <- xml2::xml_find_all(
  result_main,
  ".//a[contains(@href, '../../audit/hypotheses/H08/H08_analysis_preparation.html')]"
)
stopifnot(length(result_prep_links) >= 1L)

gt_tables <- xml2::xml_find_all(
  main,
  ".//table[contains(concat(' ', normalize-space(@class), ' '), ' gt_table ')]"
)
stopifnot(length(gt_tables) >= 19L)

if (!preintegration_only) {
  preparation_manifest <- readr::read_csv(
    paths$manifest,
    show_col_types = FALSE
  )
  expected_metric011_paths <- c(
    "scripts/hypotheses/H08/reseal_h08_l10_metric011.R",
    "tests/hypotheses/H08/test_h08_metric011_reseal.R",
    "audit/decisions/l10_numerical_zero_normalization.md",
    paste0(
      "audit/reconciliation/l10_METRIC-011/",
      "METRIC-011_evidence_manifest.csv"
    ),
    "artifacts/09_tables/H08/H08_metric011_result_comparison.csv",
    "artifacts/09_tables/H08/H08_metric011_display_invariance.csv",
    "artifacts/09_tables/H08/H08_metric011_bh_recalculation.csv",
    "artifacts/12_manifests/H08/H08_metric011_reconciliation.csv"
  )
  stopifnot(all(expected_metric011_paths %in% preparation_manifest$path))
}

if (preintegration_only) {
  message(
    "H08 preparation preintegration checks passed: three descriptive figures, ",
    length(gt_tables),
    " gt tables, eight passing A4 physical-size inspections, and frozen ",
    "scientific assertions. Shared-profile adjacency and final website ",
    "provenance remain required."
  )
} else {
  stopifnot(
    verification$figures >= 3L,
    verification$gt_tables >= 19L,
    verification$manifest_identities >= 45L,
    isTRUE(verification$source_copy_identical)
  )
  message(
    "H08 preparation companion verified: ",
    verification$figures,
    " figures, ",
    verification$gt_tables,
    " gt tables, ",
    verification$manifest_identities,
    " manifest identities, eight passing A4 physical-size inspections, and ",
    "a byte-identical source copy"
  )
}
