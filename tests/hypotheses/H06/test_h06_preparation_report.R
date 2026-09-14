# Structural, source-data, display, and provenance checks for the H06
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

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop(
    sprintf("H06 requires R 4.6.1; running %s", getRversion()),
    call. = FALSE
  )
}

paths <- preparation_companion_paths(root, "H06")
required_local <- c(
  paths$qmd,
  paths$html,
  paths$rendered_qmd,
  paths$result_qmd,
  paths$result_html,
  paths$manifest,
  file.path(
    root,
    paste0(
      "artifacts/12_manifests/H06/",
      "H06_preparation_figure_readability_qa.csv"
    )
  ),
  file.path(
    root,
    paste0(
      "artifacts/12_manifests/H06/qa/",
      "H06_preparation_figure_A4_proofs.pdf"
    )
  )
)
stopifnot(all(file.exists(required_local)))

qmd_lines <- readLines(paths$qmd, warn = FALSE, encoding = "UTF-8")
qmd <- paste(qmd_lines, collapse = "\n")
stopifnot(
  grepl("flowchart TD", qmd, fixed = TRUE),
  grepl("../../../notebooks/hypotheses/H06.html", qmd, fixed = TRUE),
  grepl("gap-timing-unaware dataset", qmd, fixed = TRUE),
  grepl("50%-per-hour", qmd, fixed = TRUE),
  grepl("80%-per-day", qmd, fixed = TRUE),
  grepl("time-sensitive", qmd, fixed = TRUE),
  grepl(
    paste0(
      "response_value ~ site + work_free_day + activity_status + ",
      '"'
    ),
    qmd,
    fixed = TRUE
  ),
  grepl(
    "previous_sleep_duration_centered_h",
    qmd,
    fixed = TRUE
  ),
  grepl(
    "response_value ~ site * work_free_day + site * activity_status + ",
    qmd,
    fixed = TRUE
  ),
  grepl("Quasi-Poisson mean with log link", qmd, fixed = TRUE),
  grepl("Participant-cluster HC3 covariance", qmd, fixed = TRUE),
  grepl("participants minus one degrees of freedom", qmd, fixed = TRUE),
  grepl("separate nine-site Benjamini", qmd, fixed = TRUE),
  grepl("LightLogR::symlog_trans", qmd, fixed = TRUE),
  grepl("discrete = TRUE", qmd, fixed = TRUE),
  grepl("no site-specific clock smooth", qmd, fixed = TRUE),
  grepl("seven `TUM_S001`", qmd, fixed = TRUE),
  grepl("no `S101`", qmd, fixed = TRUE),
  grepl("::: {.callout-note", qmd, fixed = TRUE),
  !grepl("::: {.callout-important", qmd, fixed = TRUE),
  !grepl("::: {.callout-warning", qmd, fixed = TRUE),
  !grepl('bs = "sz"', qmd, fixed = TRUE),
  !grepl("longest bout", qmd, ignore.case = TRUE),
  !grepl("H06-G", qmd, fixed = TRUE),
  !grepl("submitted", qmd, ignore.case = TRUE),
  !grepl("V0 analysis", qmd, fixed = TRUE)
)

result_qmd <- paste(
  readLines(paths$result_qmd, warn = FALSE, encoding = "UTF-8"),
  collapse = "\n"
)
stopifnot(
  grepl(
    "../../audit/hypotheses/H06/H06_analysis_preparation.html",
    result_qmd,
    fixed = TRUE
  ),
  !grepl("Stage 4 remains blocked", result_qmd, fixed = TRUE),
  !grepl("H06-G3 author-review gate", result_qmd, fixed = TRUE)
)

source_data_contract <- c(
  "artifacts/11_source_data/H06/H06_preparation_frame_integrity.csv" = 6L,
  "artifacts/11_source_data/H06/H06_preparation_response_distribution.csv" = 2L,
  "artifacts/11_source_data/H06/H06_preparation_site_day_activity_support.csv" = 68L,
  "artifacts/11_source_data/H06/H06_preparation_clock_day_activity_support.csv" = 192L,
  "artifacts/11_source_data/H06/H06_preparation_participant_day_support.csv" = 1504L,
  "artifacts/11_source_data/H06/H06_preparation_input_provenance.csv" = 10L,
  "artifacts/11_source_data/H06/H06_preparation_shared_provenance.csv" = 3L,
  "artifacts/11_source_data/H06/H06_preparation_exercise_diary_source_pin.csv" = 1L
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
    "artifacts/11_source_data/H06/H06_preparation_frame_integrity.csv"
  ),
  show_col_types = FALSE
)
response <- readr::read_csv(
  file.path(
    root,
    paste0(
      "artifacts/11_source_data/H06/",
      "H06_preparation_response_distribution.csv"
    )
  ),
  show_col_types = FALSE
)
site_support <- readr::read_csv(
  file.path(
    root,
    paste0(
      "artifacts/11_source_data/H06/",
      "H06_preparation_site_day_activity_support.csv"
    )
  ),
  show_col_types = FALSE
)
clock_support <- readr::read_csv(
  file.path(
    root,
    paste0(
      "artifacts/11_source_data/H06/",
      "H06_preparation_clock_day_activity_support.csv"
    )
  ),
  show_col_types = FALSE
)
participant_day_support <- readr::read_csv(
  file.path(
    root,
    paste0(
      "artifacts/11_source_data/H06/",
      "H06_preparation_participant_day_support.csv"
    )
  ),
  show_col_types = FALSE
)
input_provenance <- readr::read_csv(
  file.path(
    root,
    "artifacts/11_source_data/H06/H06_preparation_input_provenance.csv"
  ),
  show_col_types = FALSE
)
shared_provenance <- readr::read_csv(
  file.path(
    root,
    "artifacts/11_source_data/H06/H06_preparation_shared_provenance.csv"
  ),
  show_col_types = FALSE
)
diary_pin <- readr::read_csv(
  file.path(
    root,
    paste0(
      "artifacts/11_source_data/H06/",
      "H06_preparation_exercise_diary_source_pin.csv"
    )
  ),
  show_col_types = FALSE
)

main_near <- integrity[
  integrity$run_id == "main__glasses__all_available",
]
main_chest <- integrity[
  integrity$run_id == "main__chest__all_available",
]
stopifnot(
  nrow(integrity) == 6L,
  nrow(main_near) == 1L,
  nrow(main_chest) == 1L,
  identical(main_near$observations, 16596),
  identical(main_near$participants, 137),
  identical(main_near$participant_days, 715),
  identical(main_near$sites, 9),
  identical(main_near$exact_zero_hours, 4697),
  identical(main_chest$observations, 18352),
  identical(main_chest$participants, 149),
  identical(main_chest$participant_days, 789),
  identical(main_chest$sites, 8),
  identical(main_chest$exact_zero_hours, 5337),
  all(integrity$duplicate_hour_keys == 0L),
  all(integrity$missing_outcome == 0L),
  all(integrity$missing_site == 0L),
  all(integrity$missing_day_type == 0L),
  all(integrity$missing_activity == 0L),
  all(integrity$missing_previous_sleep == 0L),
  all(integrity$invalid_response == 0L),
  all(integrity$accepted_identity_match),
  all(integrity$provenance_only_file_reseal),
  identical(response$observations, c(16596, 18352)),
  identical(response$exact_zero_hours, c(4697, 5337)),
  all(response$zeros_retained_in_models),
  all(response$display_transform == paste0(
    "LightLogR::symlog_trans(base = 10, thr = 1, scale = 1)"
  )),
  nrow(site_support) == 68L,
  sum(site_support$support_status == "Supported") == 55L,
  sum(site_support$support_status == "Observed but sparse") == 13L,
  setequal(site_support$placement, c("Near-eye", "Chest")),
  all(clock_support$local_hour %in% 0:23),
  nrow(clock_support) == 2L * 4L * 24L,
  all(clock_support$hours > 0L),
  nrow(participant_day_support) == 715L + 789L,
  all(participant_day_support$supported_hours >= 19L),
  all(participant_day_support$supported_hours <= 24L),
  nrow(input_provenance) == 10L,
  all(input_provenance$hash_verified),
  all(input_provenance$expected_sha256 == input_provenance$observed_sha256),
  nrow(shared_provenance) == 3L,
  all(shared_provenance$status == "PASS"),
  identical(diary_pin$melidosData_release, "1.0.6"),
  identical(diary_pin$normalized_s001_rows, 7),
  identical(diary_pin$normalized_s101_rows, 0),
  identical(diary_pin$local_identifier_rewrite, FALSE)
)

document <- xml2::read_html(paths$html)
main <- xml2::xml_find_first(
  document,
  "//main[@id='quarto-document-content']"
)
stopifnot(!inherits(main, "xml_missing"))
main_text <- xml2::xml_text(main)
stopifnot(
  grepl("H06 analysis preparation and provenance", main_text, fixed = TRUE),
  grepl("16,596", main_text, fixed = TRUE),
  grepl("18,352", main_text, fixed = TRUE),
  grepl("137", main_text, fixed = TRUE),
  grepl("149", main_text, fixed = TRUE),
  grepl("715", main_text, fixed = TRUE),
  grepl("789", main_text, fixed = TRUE),
  grepl("gap-timing-unaware dataset", main_text, fixed = TRUE),
  !grepl("Execution halted", main_text, fixed = TRUE)
)

expected_figures <- c(
  "fig-h06-prep-response-distribution",
  "fig-h06-prep-site-day-activity-support",
  "fig-h06-prep-clock-support"
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

result_document <- xml2::read_html(paths$result_html)
result_main <- xml2::xml_find_first(
  result_document,
  "//main[@id='quarto-document-content']"
)
result_links <- xml2::xml_attr(
  xml2::xml_find_all(result_main, ".//a"),
  "href"
)
stopifnot(any(grepl(
  "../../audit/hypotheses/H06/H06_analysis_preparation.html",
  result_links,
  fixed = TRUE
)))

qa <- readr::read_csv(
  file.path(
    root,
    paste0(
      "artifacts/12_manifests/H06/",
      "H06_preparation_figure_readability_qa.csv"
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
  nrow(qa) == 3L,
  setequal(qa$figure_id, expected_figures),
  all(qa$status == "PASS"),
  all(qa$overall_status == "PASS"),
  all(qa$visual_status == "PASS"),
  all(qa$typography_status == "PASS_BY_CALCULATION"),
  all(qa$intended_display_width_mm == 170),
  all(qa$effective_final_essential_text_pt >= 7),
  all(qa$effective_final_central_text_pt >= 7),
  identical(
    unname(vapply(
      file.path(root, qa$path),
      artifact_sha256,
      character(1L)
    )),
    qa$sha256
  ),
  all(vapply(
    qa[qa_checks],
    function(value) all(value == "PASS"),
    logical(1)
  ))
)

preparation_manifest <- readr::read_csv(
  paths$manifest,
  show_col_types = FALSE
)
manifest_absolute_paths <- file.path(root, preparation_manifest$path)
expected_manifest_paths <- c(
  "audit/hypotheses/H06/H06_analysis_preparation.qmd",
  paste0(
    "_build/nathealth/audit/hypotheses/H06/",
    "H06_analysis_preparation.qmd"
  ),
  paste0(
    "_build/nathealth/audit/hypotheses/H06/",
    "H06_analysis_preparation.html"
  ),
  "notebooks/hypotheses/H06.qmd",
  "_build/nathealth/notebooks/hypotheses/H06.html",
  "artifacts/12_manifests/H06/H06_stage3_artifacts.csv",
  paste0(
    "artifacts/12_manifests/H06/",
    "H06_preparation_figure_readability_qa.csv"
  ),
  "artifacts/12_manifests/base_model_data_artifacts.csv",
  paste0(
    "artifacts/08_diagnostics/mder_METRIC-010/downstream_rebuild/",
    "h06_hourly_frame_invariance.csv"
  ),
  "audit/decisions/h06_stage3_gate_and_stage4_transition.md",
  "_quarto-nathealth.yml"
)
stopifnot(
  nrow(preparation_manifest) >= 280L,
  !anyDuplicated(preparation_manifest$path),
  all(expected_manifest_paths %in% preparation_manifest$path),
  !"artifacts/12_manifests/H06/H06_preparation_report_manifest.csv" %in%
    preparation_manifest$path,
  !"audit/handoffs/H06_worker_handoff.md" %in%
    preparation_manifest$path,
  !"audit/handoffs/H06_shared_change_request.md" %in%
    preparation_manifest$path,
  all(file.exists(manifest_absolute_paths)),
  all(preparation_manifest$r_version == "4.6.1"),
  identical(
    unname(vapply(
      manifest_absolute_paths,
      artifact_sha256,
      character(1L)
    )),
    preparation_manifest$sha256
  )
)

# The common verifier is last so all H06-owned checks complete before any
# shared profile or website integration issue is reported.
verification <- verify_hypothesis_preparation_companion(
  root = root,
  hypothesis_id = "H06",
  min_figures = 3L,
  min_gt_tables = 20L,
  extra_forbidden_calls = c(
    "h06_fit_quasi",
    "h06_fit_robust_model",
    "h06_fit_interaction_model",
    "h06_fit_temporal_model",
    "h06_leave_one_site_out",
    "h06_participant_deletion"
  )
)

stopifnot(
  verification$figures >= 3L,
  verification$gt_tables >= 20L,
  verification$manifest_identities >= 280L,
  isTRUE(verification$source_copy_identical)
)

message(
  "H06 preparation companion verified: ",
  verification$figures,
  " figures, ",
  verification$gt_tables,
  " gt tables, ",
  verification$manifest_identities,
  " manifest identities, and byte-identical source copy"
)
