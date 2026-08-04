# Focused scientific and structural checks for the standalone H05 report.

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(xml2)
})

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("H05 reader-report tests require R 4.6.1", call. = FALSE)
}

source(file.path(root, "scripts/pipeline/paths_io.R"))
source(file.path(root, "scripts/pipeline/p_value_display.R"))

qmd_path <- file.path(root, "notebooks/hypotheses/H05.qmd")
html_path <- file.path(
  root,
  "_build/nathealth/notebooks/hypotheses/H05.html"
)
builder_path <- file.path(
  root,
  "scripts/hypotheses/H05/build_h05_reader_artifacts.R"
)
near_path <- file.path(
  root,
  "artifacts/11_source_data/H05/H05_reader_near_eye_results.csv"
)
chest_path <- file.path(
  root,
  "artifacts/11_source_data/H05/H05_reader_chest_results.csv"
)
near_sample_path <- file.path(
  root,
  "artifacts/11_source_data/H05/H05_reader_near_eye_samples.csv"
)
chest_sample_path <- file.path(
  root,
  "artifacts/11_source_data/H05/H05_reader_chest_samples.csv"
)
stage3_manifest_path <- file.path(
  root,
  "artifacts/12_manifests/H05/H05_stage3_artifacts.csv"
)
stage3_handoff_path <- file.path(
  root,
  "audit/handoffs/H05_stage3_handoff.md"
)
paired_display_path <- file.path(
  root,
  "artifacts/11_source_data/H05/H05_paired_effect_comparison_data.csv"
)
gap_timing_unaware_path <- file.path(
  root,
  "artifacts/11_source_data/H05/H05_gap_timing_unaware_dataset.csv"
)

reader_figures <- file.path(
  root,
  "artifacts/10_figures/H05",
  c(
    "H05_reader_near_eye_effects.png",
    "H05_reader_chest_effects.png",
    "H05_reader_near_eye_adequacy.png",
    "H05_reader_chest_adequacy.png",
    "H05_reader_near_eye_residual_fitted.png",
    "H05_reader_near_eye_residual_qq.png",
    "H05_reader_paired_placement_effects.png"
  )
)
reader_sources <- file.path(
  root,
  "artifacts/11_source_data/H05",
  c(
    "H05_reader_near_eye_effect_figure_data.csv",
    "H05_reader_chest_effect_figure_data.csv",
    "H05_reader_near_eye_adequacy_figure_data.csv",
    "H05_reader_chest_adequacy_figure_data.csv",
    "H05_reader_near_eye_selected_diagnostics.csv",
    "H05_paired_effect_comparison_data.csv",
    "H05_gap_timing_unaware_dataset.csv"
  )
)

stopifnot(all(file.exists(c(
  qmd_path,
  html_path,
  builder_path,
  near_path,
  chest_path,
  near_sample_path,
  chest_sample_path,
  stage3_manifest_path,
  stage3_handoff_path,
  paired_display_path,
  gap_timing_unaware_path,
  reader_figures,
  reader_sources
))))

near <- readr::read_csv(near_path, show_col_types = FALSE)
chest <- readr::read_csv(chest_path, show_col_types = FALSE)
near_samples <- readr::read_csv(near_sample_path, show_col_types = FALSE)
chest_samples <- readr::read_csv(chest_sample_path, show_col_types = FALSE)
paired_display <- readr::read_csv(
  paired_display_path,
  show_col_types = FALSE
)
diagnostics <- readr::read_csv(
  file.path(root, "artifacts/08_diagnostics/H05/H05_model_diagnostics.csv"),
  show_col_types = FALSE
)
random_site <- readr::read_csv(
  file.path(root, "artifacts/09_tables/H05/H05_random_site_sensitivity.csv"),
  show_col_types = FALSE
)
leave_one_site_out <- readr::read_csv(
  file.path(root, "artifacts/09_tables/H05/H05_leave_one_site_out_summary.csv"),
  show_col_types = FALSE
)
paired <- readr::read_csv(
  file.path(root, "artifacts/09_tables/H05/H05_paired_placement_comparison.csv"),
  show_col_types = FALSE
)
preparation <- readr::read_csv(
  file.path(root, "artifacts/09_tables/H05/H05_manuscript_prepared_comparison.csv"),
  show_col_types = FALSE
)
exact_period <- readr::read_csv(
  file.path(
    root,
    paste0(
      "artifacts/09_tables/H05/",
      "H05_exactly_identified_longest_bout_sensitivity.csv"
    )
  ),
  show_col_types = FALSE
)
formula_registry <- readr::read_csv(
  file.path(root, "artifacts/06_model_data/H05/H05_formula_registry.csv"),
  show_col_types = FALSE
)

stopifnot(
  nrow(near) == 68L,
  nrow(chest) == 68L,
  nrow(near_samples) == 17L,
  nrow(chest_samples) == 17L,
  all(near$family_observed_tests == 68L),
  all(chest$family_observed_tests == 68L),
  sum(near$p_adjusted <= 0.05, na.rm = TRUE) == 0L,
  sum(chest$p_adjusted <= 0.05, na.rm = TRUE) == 0L,
  sum(near$reader_inference_status == "unfit_for_inference") == 4L,
  sum(chest$reader_inference_status == "unfit_for_inference") == 4L,
  all(
    near$reader_inference_status[
      near$metric_id == "duration_below_1_sleep_environment"
    ] == "unfit_for_inference"
  ),
  all(
    chest$reader_inference_status[
      chest$metric_id == "duration_below_1_sleep_environment"
    ] == "unfit_for_inference"
  ),
  sum(near$model_adequacy == "acceptable") == 19L,
  sum(
    near$model_adequacy == "acceptable_with_specified_limitations"
  ) == 49L,
  sum(chest$model_adequacy == "acceptable") == 14L,
  sum(
    chest$model_adequacy == "acceptable_with_specified_limitations"
  ) == 54L,
  !any(near$model_adequacy == "not_acceptable"),
  !any(chest$model_adequacy == "not_acceptable")
)

required_paired_columns <- c(
  "analysis_unit__near_eye",
  "analysis_unit__chest",
  "observations__near_eye",
  "observations__chest",
  "participants__near_eye",
  "participants__chest",
  "participant_days__near_eye",
  "participant_days__chest",
  "sites__near_eye",
  "sites__chest",
  "comparison_scale",
  "exact_sample_match"
)
stopifnot(
  nrow(paired_display) == 68L,
  all(required_paired_columns %in% names(paired_display)),
  all(paired_display$exact_sample_match),
  all(
    paired_display$analysis_unit__near_eye ==
      paired_display$analysis_unit__chest
  ),
  all(
    paired_display$observations__near_eye ==
      paired_display$observations__chest
  ),
  all(
    paired_display$participants__near_eye ==
      paired_display$participants__chest
  ),
  all(paired_display$sites__near_eye == 8L),
  min(paired_display$participants__near_eye) == 110L,
  max(paired_display$participants__near_eye) == 112L,
  min(paired_display$participant_days__near_eye, na.rm = TRUE) == 505L,
  max(paired_display$participant_days__near_eye, na.rm = TRUE) == 643L
)

stopifnot(
  identical(
    nh_format_p_value(c(0.0009, 0.001, 0.032, 0.247, 1, NA_real_)),
    c("<0.001", "0.001", "0.032", "0.247", "1.000", "—")
  ),
  identical(
    nh_p_value_display(c(0.04, 0.06), c(TRUE, FALSE))$p_bold,
    c(TRUE, FALSE)
  )
)

near_duration <- near |>
  filter(
    .data$metric_id == "duration_above_1000",
    .data$factor_id == "leba_f2"
  )
near_dose <- near |>
  filter(
    .data$metric_id == "dose_time_sensitive_corrected_medi",
    .data$factor_id == "leba_f2"
  )
stopifnot(
  nrow(near_duration) == 1L,
  nrow(near_dose) == 1L,
  isTRUE(all.equal(
    near_duration$estimate_practical_per_sd,
    1.2344498,
    tolerance = 1e-7
  )),
  isTRUE(all.equal(
    near_duration$conf_low_practical_per_sd,
    1.084319,
    tolerance = 1e-6
  )),
  isTRUE(all.equal(
    near_duration$conf_high_practical_per_sd,
    1.405367,
    tolerance = 1e-6
  )),
  isTRUE(all.equal(
    near_duration$p_raw,
    0.0018486894572194699,
    tolerance = 1e-12
  )),
  isTRUE(all.equal(
    near_duration$p_adjusted,
    0.12449982791512618,
    tolerance = 1e-12
  )),
  isTRUE(all.equal(
    near_dose$estimate_practical_per_sd,
    1.2784885,
    tolerance = 1e-7
  )),
  isTRUE(all.equal(
    near_dose$p_adjusted,
    0.12449982791512618,
    tolerance = 1e-12
  ))
)

sleep <- diagnostics |>
  filter(
    .data$run_id %in% c(
      "main__glasses__all_available",
      "main__chest__all_available"
    ),
    .data$metric_id == "duration_below_1_sleep_environment"
  )
stopifnot(
  nrow(sleep) == 8L,
  all(grepl("WARN_STRONG_TWEEDIE_MISFIT", sleep$specified_limitations)),
  all(grepl("WARN_PREDICTED_BOUND", sleep$specified_limitations)),
  all(sleep$dharma_uniformity_p < 1e-8),
  all(sleep$dharma_zero_inflation_p == 0),
  all(sleep$predicted_above_bound_n >= 183L),
  all(sleep$predicted_above_bound_n <= 244L)
)

stopifnot(
  sum(random_site$random_site_status == "DESCRIPTIVE_UNSTABLE") == 15L,
  sum(
    random_site$placement == "glasses" &
      random_site$random_site_status == "DESCRIPTIVE_UNSTABLE"
  ) == 7L,
  sum(
    random_site$placement == "chest" &
      random_site$random_site_status == "DESCRIPTIVE_UNSTABLE"
  ) == 8L,
  sum(leave_one_site_out$successful_refits) == 612L,
  sum(leave_one_site_out$stability_class == "stable") == 21L,
  sum(
    leave_one_site_out$stability_class ==
      "direction_stable_magnitude_sensitive"
  ) == 27L,
  sum(leave_one_site_out$stability_class == "direction_unstable") == 20L,
  sum(paired$sign_concordant & paired$component_intervals_overlap) == 59L,
  sum(!paired$sign_concordant & paired$component_intervals_overlap) == 9L,
  sum(preparation$sign_concordant & preparation$component_intervals_overlap) ==
    64L,
  sum(!preparation$sign_concordant & preparation$component_intervals_overlap) ==
    4L,
  nrow(exact_period) == 4L,
  all(exact_period$observations == 500L),
  all(exact_period$participants == 132L),
  all(exact_period$participant_days == 500L),
  all(exact_period$sites == 9L),
  all(exact_period$sign_concordant)
)

expected_formulas <- c(
  "response_value ~ site + leba_centered",
  "response_value ~ site",
  "response_value ~ leba_centered + (1 | site)",
  "response_value ~ site + leba_centered + (1 | participant_key)",
  "response_value ~ site + (1 | participant_key)",
  paste0(
    "response_value ~ leba_centered + (1 | site) + ",
    "(1 | participant_key)"
  )
)
stopifnot(
  nrow(formula_registry) == 6L,
  setequal(formula_registry$formula, expected_formulas)
)

qmd <- paste(readLines(qmd_path, warn = FALSE), collapse = "\n")
builder <- paste(readLines(builder_path, warn = FALSE), collapse = "\n")
stopifnot(
  grepl(
    '::: {.callout-note title="Answer in brief"}',
    qmd,
    fixed = TRUE
  ),
  !grepl('title="Results in brief"', qmd, fixed = TRUE),
  !grepl('callout-tip title="Answer in brief"', qmd, fixed = TRUE)
)
forbidden_source_patterns <- c(
  "\\bV0\\b",
  "submitted-versus-new",
  "\\bStage [1234]\\b",
  "author gate",
  "Codex",
  "legacy",
  "discarded",
  "manuscript-prepared",
  "alternative coverage, gap-handling"
)
for (pattern in forbidden_source_patterns) {
  stopifnot(!grepl(pattern, qmd, ignore.case = TRUE, perl = TRUE))
}
expensive_fit_patterns <- c(
  "lme4::lmer\\s*\\(",
  "glmmTMB::glmmTMB\\s*\\(",
  "stats::lm\\s*\\(",
  "stats::glm\\s*\\(",
  "h05_fit_",
  "cor.test\\s*\\("
)
for (pattern in expensive_fit_patterns) {
  stopifnot(
    !grepl(pattern, qmd, perl = TRUE),
    !grepl(pattern, builder, perl = TRUE)
  )
}

document <- xml2::read_html(html_path)
main <- xml2::xml_find_first(document, "//main[@id='quarto-document-content']")
stopifnot(!inherits(main, "xml_missing"))
main_text <- xml2::xml_text(main)
main_text_lower <- tolower(main_text)
question_section <- xml2::xml_find_first(main, ".//section[@id='question']")
answer_callouts <- xml2::xml_find_all(
  main,
  paste0(
    ".//*[contains(concat(' ', normalize-space(@class), ' '), ",
    "' callout-note ') and @title='Answer in brief']"
  )
)
question_answer_callout <- xml2::xml_find_first(
  question_section,
  paste0(
    "./div[contains(concat(' ', normalize-space(@class), ' '), ",
    "' callout-note ') and @title='Answer in brief']"
  )
)
answer_text <- gsub(
  "[[:space:]]+",
  " ",
  xml2::xml_text(question_answer_callout)
)

stopifnot(
  !inherits(question_section, "xml_missing"),
  length(answer_callouts) == 1L,
  !inherits(question_answer_callout, "xml_missing"),
  grepl("None of the 68 primary near-eye associations", answer_text, fixed = TRUE),
  grepl("95% CI 1.084–1.405", answer_text, fixed = TRUE),
  grepl("95% CI 1.079–1.514", answer_text, fixed = TRUE),
  grepl("BH-adjusted p = 0.124", answer_text, fixed = TRUE),
  grepl("Complementary chest results", answer_text, fixed = TRUE),
  grepl("gap-timing-unaware dataset", answer_text, fixed = TRUE),
  grepl("Uncertainty remains", answer_text, fixed = TRUE),
  grepl("unfit for H05 inference", answer_text, fixed = TRUE),
  !grepl("Results in brief", main_text, fixed = TRUE),
  grepl(
    paste(
      "H5: LEBA questionnaire factors correlate with selected personal",
      "light exposure metrics."
    ),
    main_text,
    fixed = TRUE
  ),
  grepl("zero of 68", main_text_lower, fixed = TRUE),
  grepl("0.124", main_text, fixed = TRUE),
  !grepl("0.1245", main_text, fixed = TRUE),
  grepl("0.002", main_text, fixed = TRUE),
  grepl("0.004", main_text, fixed = TRUE),
  grepl("0.224", main_text, fixed = TRUE),
  grepl("0.070", main_text, fixed = TRUE),
  grepl("15 of 136", main_text, fixed = TRUE),
  grepl("183–187", main_text, fixed = TRUE),
  grepl("241–244", main_text, fixed = TRUE),
  grepl("gap-timing-unaware dataset", main_text_lower, fixed = TRUE),
  grepl("50%-per-hour", main_text_lower, fixed = TRUE),
  grepl("80%-per-day", main_text_lower, fixed = TRUE),
  grepl("time-sensitive primary metric dataset", main_text_lower, fixed = TRUE),
  !grepl("manuscript-prepared", main_text_lower, fixed = TRUE),
  !grepl("alternative coverage, gap-handling", main_text_lower, fixed = TRUE),
  grepl("specific to this h05 sleep-environment response", main_text_lower, fixed = TRUE),
  grepl("another hypothesis", main_text_lower, fixed = TRUE),
  grepl("different response variable or model structure", main_text_lower, fixed = TRUE),
  grepl("unfit for inference", main_text_lower, fixed = TRUE),
  grepl("longest period", main_text_lower, fixed = TRUE),
  !grepl("\\bbout\\b", main_text_lower, perl = TRUE)
)
for (formula in expected_formulas) {
  stopifnot(grepl(formula, main_text, fixed = TRUE))
}
for (pattern in forbidden_source_patterns) {
  stopifnot(!grepl(pattern, main_text, ignore.case = TRUE, perl = TRUE))
}

expected_tables <- c(
  "tbl-h05-factors",
  "tbl-h05-model-deviations",
  "tbl-h05-data-deviations",
  "tbl-h05-formulas",
  "tbl-h05-response-specifications",
  "tbl-h05-near-samples",
  "tbl-h05-near-results-a",
  "tbl-h05-near-results-b",
  "tbl-h05-near-adequacy-counts",
  "tbl-h05-near-limitations",
  "tbl-h05-near-sleep-diagnostics",
  "tbl-h05-chest-samples",
  "tbl-h05-chest-results-a",
  "tbl-h05-chest-results-b",
  "tbl-h05-chest-adequacy-counts",
  "tbl-h05-chest-limitations",
  "tbl-h05-chest-sleep-diagnostics",
  "tbl-h05-paired-f2",
  "tbl-h05-paired-f3",
  "tbl-h05-paired-f4",
  "tbl-h05-paired-f5",
  "tbl-h05-leading-sensitivities",
  "tbl-h05-descriptive-spearman",
  "tbl-h05-random-site-summary",
  "tbl-h05-leave-site-summary",
  "tbl-h05-exact-period"
)
expected_figures <- c(
  "fig-h05-near-effects",
  "fig-h05-near-adequacy",
  "fig-h05-near-residual-fitted",
  "fig-h05-near-residual-qq",
  "fig-h05-chest-effects",
  "fig-h05-chest-adequacy",
  "fig-h05-paired-placement"
)
for (id in c(expected_tables, expected_figures)) {
  stopifnot(
    length(xml2::xml_find_all(main, paste0(".//*[@id='", id, "']"))) == 1L
  )
}

gt_tables <- xml2::xml_find_all(
  main,
  ".//table[contains(concat(' ', normalize-space(@class), ' '), ' gt_table ')]"
)
stopifnot(length(gt_tables) == length(expected_tables))
data_rows <- vapply(
  gt_tables,
  function(table) length(xml2::xml_find_all(table, ".//tbody/tr")),
  integer(1)
)
header_columns <- vapply(
  gt_tables,
  function(table) {
    length(xml2::xml_find_all(table, ".//thead/tr[last()]/th"))
  },
  integer(1)
)
# The two 17-metric grouped tables add four visual group-header rows.
stopifnot(all(data_rows <= 21L), all(header_columns <= 8L))

figure_predicate <- paste0("@id='", expected_figures, "'", collapse = " or ")
images <- xml2::xml_find_all(
  main,
  paste0(".//*[", figure_predicate, "]//img")
)
stopifnot(length(images) == length(expected_figures))
image_sources <- xml2::xml_attr(images, "src")
image_alt <- xml2::xml_attr(images, "alt")
stopifnot(
  all(nzchar(image_alt)),
  all(!startsWith(image_sources, "/")),
  all(file.exists(file.path(dirname(html_path), image_sources)))
)
paired_image <- xml2::xml_find_first(
  main,
  ".//*[@id='fig-h05-paired-placement']//img"
)
paired_alt <- tolower(xml2::xml_attr(paired_image, "alt"))
stopifnot(
  grepl("near-eye effects on the horizontal axis", paired_alt, fixed = TRUE),
  grepl("chest effects on the vertical axis", paired_alt, fixed = TRUE),
  grepl("identity line", paired_alt, fixed = TRUE),
  grepl("null lines", paired_alt, fixed = TRUE),
  grepl("110 to 112 participants", paired_alt, fixed = TRUE),
  grepl("505 to 643 matched participant-days", paired_alt, fixed = TRUE),
  grepl("does not establish equivalence", paired_alt, fixed = TRUE)
)

result_table_ids <- c(
  "tbl-h05-near-results-a",
  "tbl-h05-near-results-b",
  "tbl-h05-chest-results-a",
  "tbl-h05-chest-results-b"
)
result_bold_text <- unlist(lapply(result_table_ids, function(id) {
  nodes <- xml2::xml_find_all(
    main,
    paste0(".//*[@id='", id, "']//strong")
  )
  trimws(xml2::xml_text(nodes))
}), use.names = FALSE)
stopifnot(!any(grepl("^(<0\\.001|[01]\\.[0-9]{3})$", result_bold_text)))

expected_source_links <- c(
  "H05_reader_near_eye_results.csv",
  "H05_reader_near_eye_samples.csv",
  "H05_reader_near_eye_effect_figure_data.csv",
  "H05_reader_near_eye_adequacy_figure_data.csv",
  "H05_reader_near_eye_selected_diagnostics.csv",
  "H05_reader_chest_results.csv",
  "H05_reader_chest_samples.csv",
  "H05_reader_chest_effect_figure_data.csv",
  "H05_reader_chest_adequacy_figure_data.csv",
  "H05_paired_effect_comparison_data.csv",
  "H05_paired_placement_comparison.csv",
  "H05_random_site_sensitivity.csv",
  "H05_leave_one_site_out_summary.csv",
  "H05_gap_timing_unaware_dataset.csv",
  "H05_exactly_identified_longest_bout_sensitivity.csv"
)
hrefs <- xml2::xml_attr(xml2::xml_find_all(main, ".//a[@href]"), "href")
for (filename in expected_source_links) {
  stopifnot(any(grepl(filename, hrefs, fixed = TRUE)))
}

stage3_manifest <- readr::read_csv(
  stage3_manifest_path,
  show_col_types = FALSE
)
expected_manifest_columns <- c(
  "path",
  "artifact_class",
  "artifact_type",
  "sha256",
  "bytes",
  "producer",
  "r_version",
  "written_utc"
)
expected_manifest_paths <- c(
  "notebooks/hypotheses/H05.qmd",
  "_build/nathealth/notebooks/hypotheses/H05.html",
  "scripts/hypotheses/H05/build_h05_reader_artifacts.R",
  "scripts/hypotheses/H05/build_h05_stage3_manifest.R",
  "tests/hypotheses/H05/test_h05_stage3_reader_report.R",
  "audit/hypotheses/H05/02_implementation_and_v0_comparison.qmd",
  "audit/hypotheses/H05/02_implementation_and_v0_comparison.html",
  "audit/handoffs/H05_stage2_handoff.md",
  "audit/decisions/h05_stage2_gate_and_stage3_transition.md",
  "audit/decisions/p_value_display_conventions.md",
  "audit/decisions/paired_placement_comparison_display.md",
  "audit/decisions/gap_timing_unaware_dataset_terminology.md",
  "audit/decisions/manuscript_prepared_data_sensitivity.md",
  "audit/decisions/answer_in_brief_callout.md",
  "audit/decisions/figure_readability_and_layout.md",
  "audit/decisions/report011_physical_size_revalidation.md",
  "audit/decisions/reader_facing_symlog_scale.md",
  "audit/hypotheses/H05/H05_figure_readability_qa.md",
  "artifacts/12_manifests/H05/H05_figure_A4_proofs.pdf",
  "audit/ledgers/hypothesis_stage_gates.csv",
  "audit/ledgers/change_log.csv",
  "scripts/pipeline/p_value_display.R",
  "artifacts/12_manifests/H05/H05_stage2_artifacts.csv",
  "artifacts/10_figures/H05/H05_reader_near_eye_effects.png",
  "artifacts/10_figures/H05/H05_reader_chest_effects.png",
  "artifacts/11_source_data/H05/H05_reader_near_eye_results.csv",
  "artifacts/11_source_data/H05/H05_reader_chest_results.csv",
  "artifacts/11_source_data/H05/H05_gap_timing_unaware_dataset.csv",
  paste0(
    "_build/nathealth/artifacts/11_source_data/H05/",
    "H05_reader_near_eye_results.csv"
  ),
  paste0(
    "_build/nathealth/artifacts/11_source_data/H05/",
    "H05_reader_chest_results.csv"
  )
)
stopifnot(
  identical(names(stage3_manifest), expected_manifest_columns),
  !anyDuplicated(stage3_manifest$path),
  all(expected_manifest_paths %in% stage3_manifest$path),
  !"artifacts/12_manifests/H05/H05_stage3_artifacts.csv" %in%
    stage3_manifest$path,
  !"audit/handoffs/H05_stage3_handoff.md" %in% stage3_manifest$path,
  all(stage3_manifest$r_version == "4.6.1"),
  all(nchar(stage3_manifest$sha256) == 64L)
)
manifest_absolute_paths <- file.path(root, stage3_manifest$path)
stopifnot(
  all(file.exists(manifest_absolute_paths)),
  identical(
    unname(vapply(
      manifest_absolute_paths,
      artifact_sha256,
      character(1)
    )),
    stage3_manifest$sha256
  )
)

message(
  "H05 reader-report tests passed: 68 near-eye and 68 chest models, ",
  "zero multiplicity-retained associations, 26 bounded tables, seven ",
  "accessible figures, and all material diagnostic qualifications"
)
