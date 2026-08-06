# Structural, source-data, display, and provenance checks for the H11
# analysis-preparation companion. These checks never fit or refit models.

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

paths <- preparation_companion_paths(root, "H11")
required <- unlist(paths, use.names = FALSE)
stopifnot(all(file.exists(required)))
stopifnot(identical(
  read_file_bytes(paths$qmd),
  read_file_bytes(paths$rendered_qmd)
))

qmd_lines <- readLines(paths$qmd, warn = FALSE, encoding = "UTF-8")
qmd <- paste(qmd_lines, collapse = "\n")
calls <- executable_r_call_names(qmd_lines)
forbidden_calls <- c(
  "mgcv::gam", "mgcv::bam", "gam", "bam", "lme4::lmer", "lmer",
  "stats::predict", "predict", "stats::simulate", "simulate",
  "boot::boot", "boot", "h02_fit_bam", "h11_stage2_robust_context",
  "h11_stage2_robust_tests", "h11_activity_robust_test",
  "h11_stage2_effect_pilot", "h11_activity_pointwise_curves"
)
stopifnot(length(intersect(calls, forbidden_calls)) == 0L)

stopifnot(
  grepl("flowchart TD", qmd, fixed = TRUE),
  grepl("../../../notebooks/hypotheses/H11.html", qmd, fixed = TRUE),
  grepl("gap-timing-unaware dataset", qmd, fixed = TRUE),
  grepl("at least 50% valid", qmd, fixed = TRUE),
  grepl("at least 80% valid", qmd, fixed = TRUE),
  grepl("time-sensitive primary metric", qmd, fixed = TRUE),
  grepl("invalidate or reverse", qmd, fixed = TRUE),
  grepl("cannot cleanly separate", qmd, fixed = TRUE),
  grepl("pointwise 95%", qmd, fixed = TRUE),
  grepl("LightLogR::symlog_trans(base = 10, thr = 1, scale = 1)",
    readLines(
      file.path(
        root,
        "audit/hypotheses/H11/H11_preparation_figure_readability_qa.md"
      ),
      warn = FALSE
    ) |>
      paste(collapse = "\n"),
    fixed = TRUE
  ),
  grepl("::: {.callout-note", qmd, fixed = TRUE),
  !grepl("::: {.callout-warning", qmd, fixed = TRUE),
  !grepl("::: {.callout-important", qmd, fixed = TRUE)
)

exact_formulas <- c(
  paste0(
    "response ~ sex + s(time_hour, bs = \"cc\", k = 12) + ",
    "s(time_hour, by = sex_smooth, bs = \"cc\", k = 12) + ",
    "s(time_hour, site, bs = \"sz\", k = 12) + ",
    "s(time_hour, participant, bs = \"fs\", k = 10) + ",
    "s(participant_day, bs = \"re\")"
  ),
  paste0(
    "response ~ s(time_hour, bs = \"cc\", k = 12) + ",
    "s(time_hour, site, bs = \"sz\", k = 12) + ",
    "s(time_hour, participant, bs = \"fs\", k = 10) + ",
    "s(participant_day, bs = \"re\")"
  ),
  paste0(
    "response ~ sex + activity + s(time_hour, bs = \"cc\", k = 12) + ",
    "s(time_hour, by = sex_smooth, bs = \"cc\", k = 12) + ",
    "s(time_hour, by = activity_smooth, bs = \"cc\", k = 12, id = 2) + ",
    "s(time_hour, site, bs = \"sz\", k = 12) + ",
    "s(time_hour, participant, bs = \"fs\", k = 10) + ",
    "s(participant_day, bs = \"re\")"
  ),
  paste0(
    "response ~ activity + s(time_hour, bs = \"cc\", k = 12) + ",
    "s(time_hour, by = activity_smooth, bs = \"cc\", k = 12, id = 2) + ",
    "s(time_hour, site, bs = \"sz\", k = 12) + ",
    "s(time_hour, participant, bs = \"fs\", k = 10) + ",
    "s(participant_day, bs = \"re\")"
  )
)
formula_manifest <- readr::read_csv(
  file.path(root, "artifacts/06_model_data/H11/stage2/formula_and_fit_manifest.csv"),
  show_col_types = FALSE
)
activity_formula_manifest <- readr::read_csv(
  file.path(
    root,
    "artifacts/06_model_data/H11/activity_context/formula_and_fit_manifest.csv"
  ),
  show_col_types = FALSE
)
stored_formulas <- unique(c(
  formula_manifest$formula,
  activity_formula_manifest$formula
))
stopifnot(all(exact_formulas %in% stored_formulas))

document <- xml2::read_html(paths$html)
main <- xml2::xml_find_first(document, "//main[@id='quarto-document-content']")
stopifnot(!inherits(main, "xml_missing"))
main_text <- xml2::xml_text(main)
stopifnot(
  grepl("H11 analysis preparation and provenance", main_text, fixed = TRUE),
  grepl("141 participants", main_text, fixed = TRUE),
  grepl("816 participant-days", main_text, fixed = TRUE),
  grepl("37,756 observations", main_text, fixed = TRUE),
  grepl("154 participants", main_text, fixed = TRUE),
  grepl("902 participant-days", main_text, fixed = TRUE),
  grepl("41,842 observations", main_text, fixed = TRUE),
  grepl("126 participants", main_text, fixed = TRUE),
  grepl("30,499 observations", main_text, fixed = TRUE),
  grepl("150 participants", main_text, fixed = TRUE),
  grepl("36,711 observations", main_text, fixed = TRUE),
  grepl("does not invalidate or reverse", main_text, fixed = TRUE),
  grepl("activity-adjusted exploratory global tests do not meet", main_text,
    fixed = TRUE
  ),
  !grepl("Execution halted", main_text, fixed = TRUE)
)

xml2::xml_remove(xml2::xml_find_all(
  main,
  ".//div[contains(concat(' ', normalize-space(@class), ' '), ' sourceCode ')]"
))
reader_text <- xml2::xml_text(main)
forbidden_reader_patterns <- c(
  "\\bStep\\s+[0-9]+\\b",
  "\\bStage\\s+[0-9]+\\b",
  "\\bcoordinat(?:or|ing) task\\b",
  "\\bworker task\\b",
  "\\bauthor approval\\b",
  "\\bapproval gate\\b",
  "\\bmigration history\\b",
  "\\bV0\\b",
  "manuscript-prepared",
  "alternative manuscript"
)
stopifnot(!any(vapply(
  forbidden_reader_patterns,
  grepl,
  logical(1),
  x = reader_text,
  ignore.case = TRUE,
  perl = TRUE
)))

figures <- xml2::xml_find_all(main, ".//figure")
images <- xml2::xml_find_all(main, ".//figure//img")
captions <- xml2::xml_find_all(main, ".//figure/figcaption")
stopifnot(
  length(figures) >= 3L,
  length(images) >= 3L,
  length(captions) >= 3L,
  all(nzchar(xml2::xml_attr(images, "alt"))),
  all(nzchar(trimws(xml2::xml_text(captions))))
)

gt_tables <- xml2::xml_find_all(
  main,
  ".//table[contains(concat(' ', normalize-space(@class), ' '), ' gt_table ')]"
)
stopifnot(length(gt_tables) >= 18L)

source_data_contract <- c(
  "H11_preparation_frame_integrity.csv" = 6L,
  "H11_preparation_sample_support.csv" = 6L,
  "H11_preparation_input_identities.csv" = 10L,
  "H11_preparation_site_sex_support.csv" = 34L,
  "H11_preparation_melEDI_distribution.csv" = 4L,
  "H11_preparation_AR_boundary_support.csv" = 28L,
  "H11_preparation_activity_attrition.csv" = 12L,
  "H11_preparation_environment.csv" = 9L
)
for (filename in names(source_data_contract)) {
  data <- readr::read_csv(
    file.path(root, "artifacts/11_source_data/H11/preparation", filename),
    show_col_types = FALSE
  )
  stopifnot(nrow(data) == unname(source_data_contract[[filename]]))
}

frame_integrity <- readr::read_csv(
  file.path(
    root,
    "artifacts/11_source_data/H11/preparation/H11_preparation_frame_integrity.csv"
  ),
  show_col_types = FALSE
)
sample_support <- readr::read_csv(
  file.path(
    root,
    "artifacts/11_source_data/H11/preparation/H11_preparation_sample_support.csv"
  ),
  show_col_types = FALSE
)
stopifnot(
  all(frame_integrity$overall_status == "PASS"),
  identical(sample_support$participants, c(141, 154, 141, 154, 126, 150)),
  identical(sample_support$participant_days, c(816, 902, 809, 894, 724, 875)),
  identical(
    sample_support$observations_30_minute,
    c(37756, 41842, 37603, 41664, 30499, 36711)
  )
)

qa_path <- file.path(
  root,
  "artifacts/12_manifests/H11/H11_preparation_figure_readability_qa.csv"
)
qa <- readr::read_csv(qa_path, show_col_types = FALSE)
qa_checks <- c(
  "clipping_or_cropping", "overlaps", "text_shape_and_distortion",
  "wrapping_and_units", "legend_and_data_region_balance",
  "marks_and_lines_distinguishable", "caption_and_alt_text_present"
)
stopifnot(
  nrow(qa) == 3L,
  !anyDuplicated(qa$figure_id),
  all(qa$overall_status == "PASS"),
  all(qa$visual_status == "PASS"),
  all(qa$typography_status == "PASS"),
  all(qa$intended_display_width_mm == 170),
  all(qa$effective_final_essential_text_pt >= 7),
  all(qa$effective_final_minor_text_pt >= 7),
  identical(as.integer(qa$a4_proof_page), 1:3),
  all(qa$a4_page_width_mm == 210),
  all(qa$a4_page_height_mm == 297),
  all(qa$a4_side_margin_mm == 20),
  all(vapply(qa[qa_checks], function(value) all(value == "PASS"), logical(1)))
)

result_document <- xml2::read_html(paths$result_html)
result_main <- xml2::xml_find_first(
  result_document,
  "//main[@id='quarto-document-content']"
)
prep_href <- paste0(
  "../../audit/hypotheses/H11/",
  "H11_analysis_preparation.html"
)
prep_links <- xml2::xml_find_all(
  result_main,
  paste0(".//a[contains(@href, '", prep_href, "')]")
)
stopifnot(length(prep_links) >= 1L)

manifest <- readr::read_csv(paths$manifest, show_col_types = FALSE)
stopifnot(
  !anyDuplicated(manifest$path),
  all(nchar(manifest$sha256) == 64L),
  all(nzchar(manifest$r_version)),
  all(file.exists(file.path(root, manifest$path)))
)
manifest_files <- file.path(root, manifest$path)
stopifnot(
  all(unname(file.info(manifest_files)$size) == manifest$bytes),
  all(vapply(manifest_files, artifact_sha256, character(1)) == manifest$sha256)
)

profile_lines <- readLines(paths$quarto_profile, warn = FALSE, encoding = "UTF-8")
profile_integrated <- any(
  trimws(profile_lines) ==
    "- audit/hypotheses/H11/H11_analysis_preparation.qmd"
)

if (profile_integrated) {
  verification <- verify_hypothesis_preparation_companion(
    root = root,
    hypothesis_id = "H11",
    min_figures = 3L,
    min_gt_tables = 18L,
    extra_forbidden_calls = c(
      "h02_fit_bam", "h11_stage2_robust_context",
      "h11_stage2_robust_tests", "h11_activity_robust_test",
      "h11_stage2_effect_pilot", "h11_activity_pointwise_curves"
    )
  )
  stopifnot(
    verification$figures >= 3L,
    verification$gt_tables >= 18L,
    verification$manifest_identities >= 100L,
    isTRUE(verification$source_copy_identical)
  )
  message("H11 preparation companion verified after shared-site integration")
} else {
  request_path <- file.path(
    root,
    "audit/handoffs/H11_shared_change_request.md"
  )
  stopifnot(file.exists(request_path))
  request <- paste(readLines(request_path, warn = FALSE), collapse = "\n")
  stopifnot(
    grepl("H11_analysis_preparation.qmd", request, fixed = TRUE),
    grepl("shared integration pending", request, ignore.case = TRUE)
  )
  message(
    "H11-owned preparation companion verified before shared-site integration: ",
    length(figures), " figures, ", length(gt_tables), " gt tables, ",
    nrow(manifest), " manifest identities, and a byte-identical source copy"
  )
}
