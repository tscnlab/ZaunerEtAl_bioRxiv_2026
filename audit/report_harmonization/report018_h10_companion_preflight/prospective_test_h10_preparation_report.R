# Structural, scientific, display, and provenance checks for the H10
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
  tolower(Sys.getenv("H10_PREINTEGRATION_ONLY", unset = "false")),
  "true"
)
paths <- preparation_companion_paths(root, "H10")
if (preintegration_only) {
  html_path <- file.path(
    root,
    "audit/hypotheses/H10/H10_analysis_preparation.html"
  )
  stopifnot(file.exists(paths$qmd), file.exists(html_path))
  verification <- NULL
} else {
  required_files <- unlist(paths, use.names = FALSE)
  stopifnot(all(file.exists(required_files)))
  stopifnot(identical(
    read_file_bytes(paths$qmd),
    read_file_bytes(paths$rendered_qmd)
  ))

  profile_lines <- readLines(
    paths$quarto_profile,
    warn = FALSE,
    encoding = "UTF-8"
  )
  assert_adjacent_profile_entries(
    profile_lines,
    "notebooks/hypotheses/H10.qmd",
    "audit/hypotheses/H10/H10_analysis_preparation.qmd"
  )

  manifest <- readr::read_csv(paths$manifest, show_col_types = FALSE)
  manifest_files <- file.path(root, manifest$path)
  stopifnot(
    nrow(manifest) > 100L,
    !anyDuplicated(manifest$path),
    all(c("path", "sha256", "bytes", "r_version") %in% names(manifest)),
    all(nchar(manifest$sha256) == 64L),
    all(file.exists(manifest_files)),
    all(unname(as.numeric(file.info(manifest_files)$size)) == manifest$bytes),
    all(
      vapply(manifest_files, artifact_sha256, character(1)) == manifest$sha256
    ),
    all(nzchar(manifest$r_version)),
    all(
      c(
        "audit/hypotheses/H10/H10_analysis_preparation.qmd",
        paste0(
          "_build/nathealth/audit/hypotheses/H10/",
          "H10_analysis_preparation.qmd"
        ),
        paste0(
          "_build/nathealth/audit/hypotheses/H10/",
          "H10_analysis_preparation.html"
        ),
        "_quarto-nathealth.yml"
      ) %in%
        manifest$path
    ),
    any(startsWith(manifest$path, "scripts/hypotheses/H10/")),
    any(startsWith(manifest$path, "artifacts/11_source_data/H10/"))
  )
  verification <- NULL
  html_path <- paths$html
}

qmd_lines <- readLines(paths$qmd, warn = FALSE, encoding = "UTF-8")
qmd <- paste(qmd_lines, collapse = "\n")
qmd_normalized <- gsub("\\s+", " ", qmd, perl = TRUE)
result_qmd <- paste(
  readLines(paths$result_qmd, warn = FALSE, encoding = "UTF-8"),
  collapse = "\n"
)

stopifnot(
  grepl("flowchart TD", qmd, fixed = TRUE),
  grepl("../../../notebooks/hypotheses/H10.qmd", qmd, fixed = TRUE),
  grepl(
    "../../audit/hypotheses/H10/H10_analysis_preparation.qmd",
    result_qmd,
    fixed = TRUE
  ),
  grepl("gap-timing-unaware dataset", qmd_normalized, fixed = TRUE),
  grepl(
    "daily value is retained with at least 720 viable minutes",
    qmd_normalized,
    fixed = TRUE
  ),
  grepl(
    "same general coverage rules as the primary dataset",
    qmd_normalized,
    fixed = TRUE
  ),
  grepl(
    "does not use the timing of remaining missing observations",
    qmd_normalized,
    fixed = TRUE
  ),
  grepl("age_decade = age / 10", qmd, fixed = TRUE),
  grepl(
    "Biological sex had exactly the levels Male and Female",
    qmd_normalized,
    fixed = TRUE
  ),
  grepl(
    "Biological sex and gender were recorded as separate variables",
    qmd,
    fixed = TRUE
  ),
  grepl(
    "accepted analyses used biological sex, coded Female or Male",
    qmd,
    fixed = TRUE
  ),
  grepl("gender was not analysed", qmd, fixed = TRUE),
  grepl(
    "The gender variable and unsupported predictors did not enter any model",
    qmd,
    fixed = TRUE
  ),
  !grepl("neither measured nor inferred", qmd, fixed = TRUE),
  !grepl("No gender field", qmd, fixed = TRUE),
  grepl(
    "Four separate complete 17-metric FDR families",
    qmd_normalized,
    fixed = TRUE
  ),
  grepl("build_h10_core_diagnostic_figures.R", qmd, fixed = TRUE),
  grepl("run_h10_metric010_update.R", qmd, fixed = TRUE),
  grepl("run_h10_metric011_update.R", qmd, fixed = TRUE),
  grepl("build_h10_metric011_figures.R", qmd, fixed = TRUE),
  grepl("L10 numerical-zero normalization", qmd_normalized, fixed = TRUE),
  grepl("arithmetic mean of viable one-minute", qmd, fixed = TRUE),
  grepl(
    paste(
      "corrected gap-timing-unaware chest day with no viable momentary",
      "ratio is recorded as missing"
    ),
    qmd_normalized,
    fixed = TRUE
  ),
  grepl("reason-coded missing", qmd, fixed = TRUE),
  grepl("68-page appendix", qmd, fixed = TRUE),
  grepl("::: {.callout-note", qmd, fixed = TRUE),
  !grepl("::: {.callout-important", qmd, fixed = TRUE),
  !grepl("::: {.callout-warning", qmd, fixed = TRUE),
  !grepl("::: {.callout-caution", qmd, fixed = TRUE)
)

executable_calls <- executable_r_call_names(qmd_lines)
prohibited_calls <- c(
  "mgcv::gam",
  "mgcv::bam",
  "gam",
  "bam",
  "lme4::lmer",
  "lmer",
  "lme4::glmer",
  "glmer",
  "glmmTMB::glmmTMB",
  "glmmTMB",
  "stats::predict",
  "predict",
  "stats::simulate",
  "simulate",
  "boot::boot",
  "boot",
  "emmeans::emmeans",
  "emmeans",
  "h10_fit_model",
  "h10_fit_bundle",
  "h10_coefficient_summary",
  "h10_site_effects",
  "h10_model_diagnostics",
  "h10_participant_deletion",
  "h10_leave_one_site_out"
)
stopifnot(length(intersect(executable_calls, prohibited_calls)) == 0L)

document <- xml2::read_html(html_path)
main <- xml2::xml_find_first(
  document,
  "//main[@id='quarto-document-content']"
)
stopifnot(!inherits(main, "xml_missing"))
main_text <- xml2::xml_text(main)
stopifnot(
  grepl("H10 analysis preparation and provenance", main_text, fixed = TRUE),
  grepl(
    "Personal light exposure metrics depend on age and gender",
    main_text,
    fixed = TRUE
  ),
  grepl(
    "Biological sex and gender were recorded as separate variables",
    main_text,
    fixed = TRUE
  ),
  grepl("816 near-eye and 902 chest participant-days", main_text, fixed = TRUE),
  grepl("295 de-identified participant display rows", main_text, fixed = TRUE),
  grepl("68 frames", main_text, fixed = TRUE),
  grepl("612 fits", main_text, fixed = TRUE),
  grepl("136 main-effect estimates", main_text, fixed = TRUE),
  grepl("272 model comparisons", main_text, fixed = TRUE),
  grepl("25 were acceptable", main_text, fixed = TRUE),
  grepl("43 acceptable with specified limitations", main_text, fixed = TRUE),
  grepl("none was classified not acceptable", main_text, fixed = TRUE),
  grepl("68-page appendix", main_text, fixed = TRUE),
  grepl("stored fitted values, Pearson residuals", main_text, fixed = TRUE),
  grepl(
    "No bootstrap, simulation, or other resampling was required",
    main_text,
    fixed = TRUE
  ),
  grepl("current Preparation 06 model-ready layer", main_text, fixed = TRUE),
  grepl("36 exact file identities", main_text, fixed = TRUE),
  grepl("current MDER values", main_text, fixed = TRUE),
  grepl("L10 numerical-zero normalization", main_text, fixed = TRUE),
  grepl("exactly eight primary L10 values", main_text, fixed = TRUE),
  grepl("reason-coded missing", main_text, fixed = TRUE),
  grepl(
    "every finite gap MDER value is strictly positive",
    main_text,
    fixed = TRUE
  ),
  !grepl("Execution halted", main_text, fixed = TRUE)
)

reader_content <- xml2::xml_find_first(
  xml2::read_html(html_path),
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
  !grepl("author approval", reader_text_lower, fixed = TRUE),
  !grepl("migration history", reader_text_lower, fixed = TRUE),
  !grepl("v0 analysis", reader_text_lower, fixed = TRUE),
  !grepl("temperature", reader_text_lower, fixed = TRUE),
  !grepl("longest bout", reader_text_lower, fixed = TRUE)
)

gap_position <- regexpr(
  "gap-timing-unaware\\s+dataset",
  reader_text,
  ignore.case = TRUE,
  perl = TRUE
)[1L]
coverage_position <- regexpr(
  "same general coverage rules as the primary dataset",
  reader_text,
  fixed = TRUE
)[1L]
stopifnot(
  gap_position > 0L,
  coverage_position > gap_position,
  grepl("at least 720 viable minutes", reader_text, fixed = TRUE),
  grepl(
    "does not use the timing of remaining missing observations",
    reader_text,
    fixed = TRUE
  )
)

formula_text <- c(
  "response ~ site",
  "response ~ site + age_decade",
  "response ~ site * age_decade",
  "response ~ site + biological_sex",
  "response ~ site * biological_sex",
  "response ~ site + (1 | site:Id)",
  "response ~ site + age_decade + (1 | site:Id)",
  "response ~ site * age_decade + (1 | site:Id)",
  "response ~ site + biological_sex + (1 | site:Id)",
  "response ~ site * biological_sex + (1 | site:Id)"
)
stopifnot(all(vapply(
  formula_text,
  grepl,
  logical(1),
  x = main_text,
  fixed = TRUE
)))

expected_figures <- c(
  "fig-h10-prep-age-distribution",
  "fig-h10-prep-sample-support"
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

gt_tables <- xml2::xml_find_all(
  main,
  ".//table[contains(concat(' ', normalize-space(@class), ' '), ' gt_table ')]"
)
stopifnot(length(gt_tables) == 19L)

source_data_contract <- c(
  "artifacts/11_source_data/H10/H10_preparation_age_distribution_data.csv" = 295L,
  "artifacts/11_source_data/H10/H10_preparation_sample_support_data.csv" = 34L
)
for (relative_path in names(source_data_contract)) {
  data <- readr::read_csv(
    file.path(root, relative_path),
    show_col_types = FALSE
  )
  stopifnot(nrow(data) == unname(source_data_contract[[relative_path]]))
}

input_audit <- readr::read_csv(
  file.path(root, "artifacts/06_model_data/H10/H10_input_audit.csv"),
  show_col_types = FALSE
)
input_hashes <- vapply(
  file.path(root, input_audit$path),
  artifact_sha256,
  character(1)
)
stopifnot(
  nrow(input_audit) == 36L,
  all(input_audit$exists),
  all(input_audit$hash_verified),
  all(input_hashes == input_audit$observed_sha256)
)

frame_index <- readr::read_csv(
  file.path(root, "artifacts/06_model_data/H10/H10_model_frame_index.csv"),
  show_col_types = FALSE
)
model_manifest <- readr::read_csv(
  file.path(root, "artifacts/07_models/H10/H10_model_manifest.csv"),
  show_col_types = FALSE
)
family_audit <- readr::read_csv(
  file.path(root, "artifacts/09_tables/H10/H10_multiplicity_family_audit.csv"),
  show_col_types = FALSE
)
main_results <- readr::read_csv(
  file.path(root, "artifacts/09_tables/H10/H10_primary_main_results.csv"),
  show_col_types = FALSE
)
interaction_results <- readr::read_csv(
  file.path(
    root,
    "artifacts/09_tables/H10/H10_primary_interaction_results.csv"
  ),
  show_col_types = FALSE
)
diagnostics <- readr::read_csv(
  file.path(
    root,
    "artifacts/08_diagnostics/H10/H10_primary_diagnostic_assessment.csv"
  ),
  show_col_types = FALSE
)
stopifnot(
  nrow(frame_index) == 68L,
  !anyDuplicated(frame_index[c("run_id", "metric_id")]),
  nrow(model_manifest) == 612L,
  all(model_manifest$converged),
  all(model_manifest$positive_definite_hessian),
  all(!model_manifest$singular),
  all(model_manifest$fixed_full_rank),
  nrow(family_audit) == 16L,
  all(family_audit$planned_n == 17L),
  all(family_audit$complete_17_member_family),
  all(family_audit$independent_recalculation_matches),
  sum(main_results$adjusted_significant) == 11L,
  sum(interaction_results$adjusted_significant) == 2L,
  nrow(diagnostics) == 68L,
  sum(diagnostics$final_assessment == "acceptable") == 25L,
  sum(
    diagnostics$final_assessment == "acceptable with specified limitations"
  ) ==
    43L,
  !any(diagnostics$final_assessment == "not acceptable")
)

core_manifest <- readr::read_csv(
  file.path(
    root,
    paste0(
      "artifacts/12_manifests/H10/",
      "H10_core_diagnostic_figure_manifest.csv"
    )
  ),
  show_col_types = FALSE
)
core_index <- readr::read_csv(
  file.path(
    root,
    paste0(
      "artifacts/11_source_data/H10/",
      "H10_all_primary_core_diagnostic_index.csv"
    )
  ),
  show_col_types = FALSE
)
core_data <- readr::read_csv(
  file.path(
    root,
    paste0(
      "artifacts/11_source_data/H10/",
      "H10_all_primary_core_diagnostic_data.csv"
    )
  ),
  show_col_types = FALSE
)
core_figure_rows <- !is.na(core_manifest$figure_path)
stopifnot(
  nrow(core_manifest) == 3L,
  !anyDuplicated(core_manifest$figure_id),
  sum(core_manifest$models) == 79L,
  core_manifest$models[
    core_manifest$figure_id == "fig-h10-all-primary-core-diagnostics"
  ] ==
    68L,
  core_manifest$pages[
    core_manifest$figure_id == "fig-h10-all-primary-core-diagnostics"
  ] ==
    68L,
  all(
    vapply(
      file.path(root, core_manifest$figure_path[core_figure_rows]),
      artifact_sha256,
      character(1)
    ) ==
      core_manifest$figure_sha256[core_figure_rows]
  ),
  all(
    vapply(
      file.path(root, core_manifest$pdf_path),
      artifact_sha256,
      character(1)
    ) ==
      core_manifest$pdf_sha256
  ),
  all(
    vapply(
      file.path(root, core_manifest$source_data_path),
      artifact_sha256,
      character(1)
    ) ==
      core_manifest$source_data_sha256
  ),
  all(
    vapply(
      file.path(root, core_manifest$model_index_path),
      artifact_sha256,
      character(1)
    ) ==
      core_manifest$model_index_sha256
  ),
  nrow(core_index) == 68L,
  !anyDuplicated(core_index$model_key),
  identical(as.integer(core_index$page), seq_len(68L)),
  sum(core_index$adjusted_significant) == 11L,
  nrow(core_data) == 99312L,
  !anyDuplicated(core_data[c(
    "model_key",
    "diagnostic_type",
    "model_row_id"
  )]),
  length(unique(core_data$model_key)) == 68L,
  setequal(
    unique(core_data$diagnostic_type),
    c("Residuals vs fitted", "Normal Q-Q")
  )
)

qa_path <- file.path(
  root,
  paste0(
    "artifacts/12_manifests/H10/",
    "H10_preparation_figure_readability_qa.csv"
  )
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
  nrow(qa) == 2L,
  !anyDuplicated(qa$figure_id),
  all(qa$intended_display_width_mm == 170),
  all(qa$effective_final_essential_text_pt >= 5),
  all(qa$effective_final_central_text_pt >= 7),
  all(qa$overall_status == "PASS"),
  all(file.exists(file.path(root, qa$path))),
  all(file.exists(file.path(root, qa$source_data_path))),
  all(file.exists(file.path(root, qa$a4_proof_path))),
  all(vapply(qa[qa_checks], function(value) all(value == "PASS"), logical(1))),
  all(
    vapply(
      file.path(root, qa$path),
      artifact_sha256,
      character(1)
    ) ==
      qa$sha256
  ),
  all(
    vapply(
      file.path(root, qa$source_data_path),
      artifact_sha256,
      character(1)
    ) ==
      qa$source_data_sha256
  )
)

result_document <- xml2::read_html(paths$result_html)
result_main <- xml2::xml_find_first(
  result_document,
  "//main[@id='quarto-document-content']"
)
stopifnot(
  length(xml2::xml_find_all(
    result_main,
    paste0(
      ".//a[contains(@href, '",
      "../../audit/hypotheses/H10/H10_analysis_preparation.html",
      "')]"
    )
  )) >=
    1L
)

if (!preintegration_only) {
  prep_pagination <- xml2::xml_find_all(
    document,
    "//a[contains(@class, 'pagination-link')]"
  )
  result_pagination <- xml2::xml_find_all(
    result_document,
    "//a[contains(@class, 'pagination-link')]"
  )
  stopifnot(
    any(grepl(
      "../../../notebooks/hypotheses/H10.html",
      xml2::xml_attr(prep_pagination, "href"),
      fixed = TRUE
    )),
    any(grepl(
      "../../audit/hypotheses/H10/H10_analysis_preparation.html",
      xml2::xml_attr(result_pagination, "href"),
      fixed = TRUE
    ))
  )
}

message(
  "H10 preparation companion verified: ",
  length(gt_tables),
  " gt tables, 2 descriptive figures, 68 frozen frames; mode ",
  ifelse(preintegration_only, "preintegration", "strict")
)
