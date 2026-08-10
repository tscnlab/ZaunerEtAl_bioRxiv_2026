# Structural, source-data, display, and provenance checks for the H03
# analysis-preparation companion. These checks do not fit or refit models.

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

paths <- preparation_companion_paths(root, "H03")
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
  grepl("../../../notebooks/hypotheses/H03.html", qmd, fixed = TRUE),
  grepl("gap-timing-unaware dataset", qmd, fixed = TRUE),
  grepl("at least 50% valid minutes per hour", qmd, fixed = TRUE),
  grepl("80% valid hours per day", qmd, fixed = TRUE),
  grepl("time-sensitive primary metric dataset", qmd, fixed = TRUE),
  grepl("geo_medi_1h ~ site + light_source", qmd, fixed = TRUE),
  grepl("geo_medi_1h ~ site * light_source", qmd, fixed = TRUE),
  grepl("geo_medi_1h ~ 0 + site_source_cell", qmd, fixed = TRUE),
  grepl("s(time_hour, bs = \"cc\", k = 12)", qmd, fixed = TRUE),
  grepl("s(time_hour, light_source, bs = \"sz\", k = 12)", qmd, fixed = TRUE),
  grepl("s(time_hour, site, bs = \"sz\", k = 12)", qmd, fixed = TRUE),
  grepl("s(time_hour, participant, bs = \"fs\", k = 10)", qmd, fixed = TRUE),
  grepl("s(participant_day, bs = \"re\")", qmd, fixed = TRUE),
  grepl("participant-clustered HC1", qmd, fixed = TRUE),
  grepl("back-transformed once", qmd, fixed = TRUE),
  grepl("indoor electric light", qmd, ignore.case = TRUE),
  grepl("::: {.callout-note", qmd, fixed = TRUE),
  !grepl("::: {.callout-important", qmd, fixed = TRUE),
  !grepl("::: {.callout-warning", qmd, fixed = TRUE),
  !grepl("V0", qmd, fixed = TRUE),
  !grepl("longest bout", qmd, ignore.case = TRUE)
)

source_data_contract <- c(
  "artifacts/11_source_data/H03/H03_preparation_frame_integrity.csv" = 2L,
  "artifacts/11_source_data/H03/H03_preparation_zero_summary.csv" = 2L,
  "artifacts/11_source_data/H03/H03_preparation_positive_response_distribution.csv" = 80L,
  "artifacts/11_source_data/H03/H03_preparation_category_support.csv" = 14L,
  "artifacts/11_source_data/H03/H03_preparation_site_category_support.csv" = 126L,
  "artifacts/11_source_data/H03/H03_preparation_clock_category_support.csv" = 336L,
  "artifacts/11_source_data/H03/H03_preparation_participant_day_support.csv" = 1681L
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
    "artifacts/11_source_data/H03/H03_preparation_frame_integrity.csv"
  ),
  show_col_types = FALSE
)
category_support <- readr::read_csv(
  file.path(
    root,
    "artifacts/11_source_data/H03/H03_preparation_category_support.csv"
  ),
  show_col_types = FALSE
)
site_support <- readr::read_csv(
  file.path(
    root,
    paste0(
      "artifacts/11_source_data/H03/",
      "H03_preparation_site_category_support.csv"
    )
  ),
  show_col_types = FALSE
)
clock_support <- readr::read_csv(
  file.path(
    root,
    paste0(
      "artifacts/11_source_data/H03/",
      "H03_preparation_clock_category_support.csv"
    )
  ),
  show_col_types = FALSE
)
stopifnot(
  identical(integrity$observations, c(17935, 19512)),
  identical(integrity$participants, c(140, 151)),
  identical(integrity$participant_days, c(801, 880)),
  identical(integrity$sites, c(9, 8)),
  all(integrity$duplicate_hour_keys == 0L),
  all(integrity$missing_outcome == 0L),
  all(integrity$missing_category == 0L),
  all(integrity$category_mapping_conflicts == 0L),
  all(integrity$source_flag_zero == 0L),
  all(integrity$ar_sequences == integrity$ar_sequence_starts),
  nrow(category_support) == 14L,
  all(category_support$pooled_estimable),
  sum(site_support$support_status == "Supported") == 101L,
  sum(site_support$support_status == "Observed but sparse") == 17L,
  sum(site_support$support_status == "No observations") == 8L,
  nrow(clock_support) == 336L,
  all(clock_support$local_hour %in% 0:23)
)

document <- xml2::read_html(paths$html)
main <- xml2::xml_find_first(
  document,
  "//main[@id='quarto-document-content']"
)
stopifnot(!inherits(main, "xml_missing"))
main_text <- xml2::xml_text(main)
stopifnot(
  grepl("H03 analysis preparation and provenance", main_text, fixed = TRUE),
  grepl("17,935", main_text, fixed = TRUE),
  grepl("19,512", main_text, fixed = TRUE),
  grepl("140", main_text, fixed = TRUE),
  grepl("151", main_text, fixed = TRUE),
  grepl("801", main_text, fixed = TRUE),
  grepl("880", main_text, fixed = TRUE),
  grepl("gap-timing-unaware dataset", main_text, fixed = TRUE),
  !grepl("Execution halted", main_text, fixed = TRUE)
)

expected_figures <- c(
  "fig-h03-prep-positive-distribution",
  "fig-h03-prep-category-support",
  "fig-h03-prep-site-category-support",
  "fig-h03-prep-clock-category-support"
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
      "artifacts/12_manifests/H03/",
      "H03_preparation_figure_readability_qa.csv"
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
    "artifacts/12_manifests/H03/H03_preparation_figure_A4_proofs.pdf"
  ))
)

preparation_manifest <- readr::read_csv(
  paths$manifest,
  show_col_types = FALSE
)
manifest_absolute_paths <- file.path(root, preparation_manifest$path)
stopifnot(
  nrow(preparation_manifest) == 319L,
  !anyDuplicated(preparation_manifest$path),
  all(file.exists(manifest_absolute_paths)),
  "artifacts/12_manifests/H03/H03_stage3_artifacts.csv" %in%
    preparation_manifest$path,
  !"artifacts/12_manifests/H03/H03_preparation_report_manifest.csv" %in%
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

# The common verifier is last so all H03-owned checks complete before a
# coordinator-owned website-profile omission can block the integrated test.
verification <- verify_hypothesis_preparation_companion(
  root = root,
  hypothesis_id = "H03",
  min_figures = 4L,
  min_gt_tables = 24L,
  extra_forbidden_calls = c(
    "h03_fit_quasi",
    "h03_fit_additive_run",
    "h03_fit_interaction_architecture",
    "h03_fit_temporal_model",
    "h03_fit_reader_temporal_model",
    "h03_temporal_model",
    "h03_leave_one_site_out"
  )
)

stopifnot(
  verification$figures >= 4L,
  verification$gt_tables >= 24L,
  verification$manifest_identities >= 60L,
  isTRUE(verification$source_copy_identical)
)

message(
  "H03 preparation companion verified: ",
  verification$figures,
  " figures, ",
  verification$gt_tables,
  " gt tables, ",
  verification$manifest_identities,
  " manifest identities, and byte-identical source copy"
)
