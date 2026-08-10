# Structural, scientific-record, and provenance checks for the H09
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

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("H09 preparation verification requires R 4.6.1", call. = FALSE)
}

paths <- preparation_companion_paths(root, "H09")
required_files <- c(
  paths$qmd,
  paths$html,
  paths$rendered_qmd,
  paths$result_qmd,
  paths$result_html,
  paths$manifest,
  paths$quarto_profile
)
stopifnot(all(file.exists(required_files)))
stopifnot(identical(
  read_file_bytes(paths$qmd),
  read_file_bytes(paths$rendered_qmd)
))

qmd_lines <- readLines(paths$qmd, warn = FALSE, encoding = "UTF-8")
qmd <- paste(qmd_lines, collapse = "\n")
result_qmd <- paste(
  readLines(paths$result_qmd, warn = FALSE, encoding = "UTF-8"),
  collapse = "\n"
)

stopifnot(
  grepl("flowchart TD", qmd, fixed = TRUE),
  grepl("../../../notebooks/hypotheses/H09.html", qmd, fixed = TRUE),
  grepl(
    "../../audit/hypotheses/H09/H09_analysis_preparation.html",
    result_qmd,
    fixed = TRUE
  ),
  grepl("gap-timing-unaware dataset", qmd, fixed = TRUE),
  grepl("50%-per-hour", qmd, fixed = TRUE),
  grepl("80%-per-day", qmd, fixed = TRUE),
  grepl("remaining gaps' time of day", qmd, fixed = TRUE),
  grepl("time-sensitive primary dataset", qmd, fixed = TRUE),
  grepl("mctq_hour_centered", qmd, fixed = TRUE),
  grepl("meq_10_centered", qmd, fixed = TRUE),
  grepl("4.1135843", qmd, fixed = TRUE),
  grepl("52.8602151", qmd, fixed = TRUE),
  grepl("one hour later corrected midsleep", qmd, fixed = TRUE),
  grepl("10 score points toward greater morning preference", qmd, fixed = TRUE),
  grepl("does not change the chronotype slope", qmd, fixed = TRUE),
  grepl("fig-width: 6.692913", qmd, fixed = TRUE),
  grepl("out-width: \"100%\"", qmd, fixed = TRUE),
  grepl("::: {.callout-note", qmd, fixed = TRUE),
  !grepl("::: {.callout-important", qmd, fixed = TRUE),
  !grepl("::: {.callout-warning", qmd, fixed = TRUE)
)

executable_calls <- executable_r_call_names(qmd_lines)
prohibited_calls <- c(
  "mgcv::gam", "mgcv::bam", "gam", "bam",
  "lme4::lmer", "lmer", "lme4::glmer", "glmer",
  "glmmTMB::glmmTMB", "glmmTMB", "nlme::lme", "lme",
  "stats::predict", "predict", "stats::simulate", "simulate",
  "boot::boot", "boot", "emmeans::emmeans", "emmeans",
  "h09_fit_model", "h09_fit_bundle", "h09_fit_models",
  "h09_model_diagnostics", "h09_residual_diagnostics",
  "h09_leave_one_site_out", "h09_participant_influence",
  "h09_photoperiod_sensitivity", "h09_participant_summary_sensitivity",
  "h09_ar1_sensitivity"
)
stopifnot(length(intersect(executable_calls, prohibited_calls)) == 0L)

document <- xml2::read_html(paths$html)
main <- xml2::xml_find_first(
  document,
  "//main[@id='quarto-document-content']"
)
stopifnot(!inherits(main, "xml_missing"))
main_text <- xml2::xml_text(main)
stopifnot(
  grepl("H09 analysis preparation and provenance", main_text, fixed = TRUE),
  grepl("186 unique participants", main_text, fixed = TRUE),
  grepl("108 unique frames", main_text, fixed = TRUE),
  grepl("540 model records", main_text, fixed = TRUE),
  grepl("20 exact key records", main_text, fixed = TRUE),
  grepl("Sixteen estimable exact pairs", main_text, fixed = TRUE),
  grepl("four registered longest-period pairs unavailable", main_text, fixed = TRUE),
  grepl("4.1135843", main_text, fixed = TRUE),
  grepl("52.8602151", main_text, fixed = TRUE),
  grepl(
    "mctq_hour_centered = MCTQ MSFsc in hours - 4.1135843",
    main_text,
    fixed = TRUE
  ),
  grepl(
    "meq_10_centered = (MEQ score - 52.8602151) / 10",
    main_text,
    fixed = TRUE
  ),
  !grepl("[ = - 4.1135843, ]", main_text, fixed = TRUE),
  !grepl("[ = . ]", main_text, fixed = TRUE),
  grepl("131–141 participants", main_text, fixed = TRUE),
  grepl("478–816", main_text, fixed = TRUE),
  grepl("149–154 participants", main_text, fixed = TRUE),
  grepl("547–902", main_text, fixed = TRUE),
  grepl("Eighteen targets are acceptable", main_text, fixed = TRUE),
  grepl("six retain", main_text, fixed = TRUE),
  !grepl("Execution halted", main_text, fixed = TRUE)
)

reader_content <- xml2::xml_find_first(
  xml2::read_html(paths$html),
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

result_document <- xml2::read_html(paths$result_html)
result_main <- xml2::xml_find_first(
  result_document,
  "//main[@id='quarto-document-content']"
)
result_prep_links <- xml2::xml_find_all(
  result_main,
  paste0(
    ".//a[contains(@href, '",
    "../../audit/hypotheses/H09/H09_analysis_preparation.html",
    "')]"
  )
)
prep_result_links <- xml2::xml_find_all(
  main,
  ".//a[contains(@href, '../../../notebooks/hypotheses/H09.html')]"
)
stopifnot(length(result_prep_links) >= 1L, length(prep_result_links) >= 1L)

figure <- xml2::xml_find_first(
  main,
  ".//*[@id='fig-h09-prep-sample-support']"
)
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

expected_table_ids <- c(
  "tbl-h09-prep-boundary",
  "tbl-h09-prep-input-identities",
  "tbl-h09-prep-integrity-checks",
  "tbl-h09-prep-score-audit",
  "tbl-h09-prep-predictor-contract",
  "tbl-h09-prep-metric-contract",
  "tbl-h09-prep-primary-samples",
  "tbl-h09-prep-common-samples",
  "tbl-h09-prep-primary-formulas",
  "tbl-h09-prep-sensitivity-formulas",
  "tbl-h09-prep-intermediate-artifacts",
  "tbl-h09-prep-families",
  "tbl-h09-prep-diagnostic-summary",
  "tbl-h09-prep-sensitivity-map",
  "tbl-h09-prep-code-map",
  "tbl-h09-prep-script-map",
  "tbl-h09-prep-reader-manifest-check",
  "tbl-h09-prep-key-output-identities",
  "tbl-h09-prep-execution"
)
for (id in expected_table_ids) {
  stopifnot(!inherits(
    xml2::xml_find_first(main, paste0(".//*[@id='", id, "']")),
    "xml_missing"
  ))
}
gt_tables <- xml2::xml_find_all(
  main,
  ".//table[contains(concat(' ', normalize-space(@class), ' '), ' gt_table ')]"
)
stopifnot(length(gt_tables) >= length(expected_table_ids))

read_h09 <- function(area, name) {
  readr::read_csv(
    file.path(root, "artifacts", area, "H09", name),
    show_col_types = FALSE,
    progress = FALSE
  )
}

score <- read_h09("08_diagnostics", "H09_chronotype_score_audit.csv")
frames <- read_h09("06_model_data", "H09_model_frame_index.csv")
fits <- read_h09("07_models", "H09_model_fit_index.csv")
paired <- read_h09("06_model_data", "H09_paired_sample_audit.csv")
gap_common <- read_h09("06_model_data", "H09_gap_common_sample_audit.csv")
non_estimable <- read_h09("06_model_data", "H09_non_estimable_targets.csv")
diagnostics <- read_h09(
  "08_diagnostics",
  "H09_diagnostic_target_summary.csv"
)
adjudication <- read_h09(
  "08_diagnostics",
  "H09_diagnostic_author_adjudication.csv"
)
residuals <- read_h09("08_diagnostics", "H09_residual_diagnostics.csv")
families <- read_h09("09_tables", "H09_family_audit.csv")
gap_results <- read_h09(
  "09_tables",
  "H09_gap_timing_unaware_sensitivity.csv"
)
photoperiod <- read_h09("09_tables", "H09_photoperiod_sensitivity.csv")
participant <- read_h09(
  "09_tables",
  "H09_participant_summary_sensitivity.csv"
)
ar1 <- read_h09("09_tables", "H09_ar1_sensitivity.csv")
l10 <- read_h09("09_tables", "H09_l10_cut_sensitivity.csv")
paired_effects <- read_h09(
  "09_tables",
  "H09_paired_placement_effects.csv"
)
fifth <- read_h09("09_tables", "H09_fifth_outcome_sensitivity.csv")
execution <- read_h09("12_manifests", "H09_execution_record.csv")

stopifnot(
  nrow(score) == 1L,
  score$participants == 186L,
  score$mctq_complete == 185L,
  score$mctq_missing == 1L,
  score$meq_complete == 186L,
  score$meq_missing == 0L,
  abs(score$mctq_center_hour - 4.1135843) < 1e-7,
  abs(score$meq_center_score - 52.8602151) < 1e-7,
  nrow(frames) == 108L,
  !anyDuplicated(frames$frame_id),
  nrow(fits) == 540L,
  nrow(paired) == 12L,
  all(paired$exact_row_keys_match),
  nrow(gap_common) == 20L,
  all(gap_common$exact_row_keys_match),
  nrow(non_estimable) == 12L,
  nrow(diagnostics) == 24L,
  sum(diagnostics$overall_assessment == "acceptable") == 18L,
  sum(diagnostics$overall_assessment == "not acceptable") == 6L,
  nrow(adjudication) == 48L,
  all(adjudication$author_final_assessment == "acceptable"),
  sum(adjudication$numeric_screen_assessment == "not acceptable") == 12L,
  sum(residuals$distribution_assessment == "not acceptable") == 14L,
  sum(residuals$heteroscedasticity_assessment == "not acceptable") == 4L,
  nrow(families) == 40L,
  all(families$planned_members == 5L),
  all(families$complete_registered_family),
  all(families$independent_recalculation_matches),
  nrow(gap_results) == 24L,
  sum(gap_results$exact_common_keys, na.rm = TRUE) == 20L,
  nrow(photoperiod) == 24L,
  nrow(participant) == 24L,
  nrow(ar1) == 24L,
  nrow(l10) == 4L,
  nrow(paired_effects) == 10L,
  all(paired_effects$exact_sample_match),
  nrow(fifth) == 8L,
  execution$r_version == "4.6.1",
  execution$model_frames == 108L,
  execution$fitted_model_objects == 540L,
  execution$diagnostic_targets == 24L,
  execution$production_resampling_replicates == 0L
)

manifest <- readr::read_csv(paths$manifest, show_col_types = FALSE)
required_manifest_columns <- c(
  "path", "role", "artifact_class", "sha256", "bytes", "producer",
  "r_version"
)
required_manifest_paths <- c(
  "audit/hypotheses/H09/H09_analysis_preparation.qmd",
  paste0(
    "_build/nathealth/audit/hypotheses/H09/",
    "H09_analysis_preparation.qmd"
  ),
  paste0(
    "_build/nathealth/audit/hypotheses/H09/",
    "H09_analysis_preparation.html"
  ),
  "notebooks/hypotheses/H09.qmd",
  "_build/nathealth/notebooks/hypotheses/H09.html",
  "scripts/hypotheses/H09/build_h09_preparation_report_manifest.R",
  "tests/hypotheses/H09/test_h09_preparation_report.R",
  "_quarto-nathealth.yml"
)
stopifnot(
  all(required_manifest_columns %in% names(manifest)),
  !anyDuplicated(manifest$path),
  all(nchar(manifest$sha256) == 64L),
  all(manifest$r_version == "4.6.1"),
  all(required_manifest_paths %in% manifest$path),
  any(startsWith(manifest$path, "scripts/hypotheses/H09/")),
  any(startsWith(manifest$path, "tests/hypotheses/H09/")),
  any(startsWith(manifest$path, "artifacts/11_source_data/H09/")),
  !any(grepl("audit/handoffs/H09_", manifest$path, fixed = TRUE)),
  !any(manifest$path ==
    "artifacts/12_manifests/H09/H09_preparation_report_manifest.csv")
)
manifest_files <- file.path(root, manifest$path)
stopifnot(all(file.exists(manifest_files)))
observed_bytes <- as.numeric(file.info(manifest_files)$size)
observed_hashes <- unname(vapply(
  manifest_files,
  artifact_sha256,
  character(1)
))
stopifnot(
  all(observed_bytes == as.numeric(manifest$bytes)),
  all(observed_hashes == manifest$sha256)
)

profile <- paste(
  readLines(paths$quarto_profile, warn = FALSE, encoding = "UTF-8"),
  collapse = "\n"
)
prep_profile_path <-
  "audit/hypotheses/H09/H09_analysis_preparation.qmd"
stopifnot(!grepl(prep_profile_path, profile, fixed = TRUE))

shared_request_path <- file.path(
  root,
  "audit/handoffs/H09_shared_change_request.md"
)
shared_request <- paste(
  readLines(shared_request_path, warn = FALSE, encoding = "UTF-8"),
  collapse = "\n"
)
stopifnot(
  grepl(prep_profile_path, shared_request, fixed = TRUE),
  grepl("H09 preparation and provenance", shared_request, fixed = TRUE)
)

message(
  "H09 preparation companion verified: one accessible figure, ",
  length(gt_tables),
  " gt tables, ",
  nrow(manifest),
  " current identities, reciprocal links, and no scientific refitting"
)
