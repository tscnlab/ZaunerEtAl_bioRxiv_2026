#!/usr/bin/env Rscript

# Focused scientific, reporting, render, and physical-size checks for the
# standalone H10 reader report.

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
  stop("H10 reader-report tests require R 4.6.1", call. = FALSE)
}

source(file.path(root, "scripts/pipeline/paths_io.R"))
source(file.path(root, "scripts/pipeline/p_value_display.R"))

qmd_path <- file.path(root, "notebooks/hypotheses/H10.qmd")
html_path <- file.path(
  root,
  "_build/nathealth/notebooks/hypotheses/H10.html"
)
approval_path <- file.path(
  root,
  "audit/hypotheses/H10/02_author_decision.md"
)
qa_script_path <- file.path(
  root,
  paste0(
    "scripts/hypotheses/H10/",
    "build_h10_stage3_figure_qa.R"
  )
)
qa_csv_path <- file.path(
  root,
  paste0(
    "artifacts/12_manifests/H10/",
    "H10_stage3_figure_readability_qa.csv"
  )
)
qa_pdf_path <- file.path(
  root,
  "artifacts/12_manifests/H10/H10_stage3_figure_A4_proofs.pdf"
)
qa_record_path <- file.path(
  root,
  "audit/hypotheses/H10/03_stage3_figure_qa.md"
)
stage3_manifest_path <- file.path(
  root,
  "artifacts/12_manifests/H10/H10_stage3_artifacts.csv"
)
overview_builder_path <- file.path(
  root,
  paste0(
    "scripts/hypotheses/H10/",
    "build_h10_stage3_association_overview.R"
  )
)
overview_source_path <- file.path(
  root,
  paste0(
    "artifacts/11_source_data/H10/",
    "H10_age_site_significant_associations_data.csv"
  )
)
overview_manifest_path <- file.path(
  root,
  paste0(
    "artifacts/12_manifests/H10/",
    "H10_stage3_reader_figure_manifest.csv"
  )
)
core_diagnostic_builder_path <- file.path(
  root,
  paste0(
    "scripts/hypotheses/H10/",
    "build_h10_core_diagnostic_figures.R"
  )
)
core_diagnostic_manifest_path <- file.path(
  root,
  paste0(
    "artifacts/12_manifests/H10/",
    "H10_core_diagnostic_figure_manifest.csv"
  )
)
core_diagnostic_appendix_path <- file.path(
  root,
  paste0(
    "artifacts/10_figures/H10/",
    "H10_all_primary_model_core_diagnostics.pdf"
  )
)
core_diagnostic_all_source_path <- file.path(
  root,
  paste0(
    "artifacts/11_source_data/H10/",
    "H10_all_primary_core_diagnostic_data.csv"
  )
)
core_diagnostic_index_path <- file.path(
  root,
  paste0(
    "artifacts/11_source_data/H10/",
    "H10_all_primary_core_diagnostic_index.csv"
  )
)

reader_figure_names <- c(
  "H10_primary_age_associations.png",
  "H10_age_site_significant_associations.png",
  "H10_primary_biological_sex_associations.png",
  "H10_diagnostic_assessment.png",
  "H10_retained_age_core_diagnostics.png",
  "H10_retained_biological_sex_core_diagnostics.png",
  "H10_paired_placement_effects.png",
  "H10_gap_common_sample_effects.png"
)
reader_source_names <- c(
  "H10_primary_age_associations_data.csv",
  "H10_age_site_significant_associations_data.csv",
  "H10_primary_biological_sex_associations_data.csv",
  "H10_diagnostic_assessment_data.csv",
  "H10_retained_age_core_diagnostic_data.csv",
  "H10_retained_biological_sex_core_diagnostic_data.csv",
  "H10_paired_placement_effects_data.csv",
  "H10_gap_common_sample_effects_data.csv"
)
reader_figures <- file.path(
  root,
  "artifacts/10_figures/H10",
  reader_figure_names
)
reader_sources <- file.path(
  root,
  "artifacts/11_source_data/H10",
  reader_source_names
)

stopifnot(all(file.exists(c(
  qmd_path,
  html_path,
  approval_path,
  qa_script_path,
  qa_csv_path,
  qa_pdf_path,
  qa_record_path,
  stage3_manifest_path,
  overview_builder_path,
  overview_source_path,
  overview_manifest_path,
  core_diagnostic_builder_path,
  core_diagnostic_manifest_path,
  core_diagnostic_appendix_path,
  core_diagnostic_all_source_path,
  core_diagnostic_index_path,
  reader_figures,
  reader_sources
))))

# The complete frozen numerical package must still match its sealed inventory.
stage2_manifest <- readr::read_csv(
  file.path(root, "artifacts/12_manifests/H10/H10_stage2_artifacts.csv"),
  show_col_types = FALSE
)
stage2_frozen_manifest <- stage2_manifest |>
  filter(!startsWith(.data$path, "audit/handoffs/H10_"))
stage2_paths <- file.path(root, stage2_frozen_manifest$path)
stopifnot(all(file.exists(stage2_paths)))
stage2_observed <- unname(vapply(
  stage2_paths,
  artifact_sha256,
  character(1)
))
stopifnot(identical(stage2_observed, stage2_frozen_manifest$sha256))

metric_registry <- readr::read_csv(
  file.path(root, "artifacts/06_model_data/H10/H10_metric_registry.csv"),
  show_col_types = FALSE
)
main <- readr::read_csv(
  file.path(root, "artifacts/09_tables/H10/H10_primary_main_results.csv"),
  show_col_types = FALSE
)
interactions <- readr::read_csv(
  file.path(
    root,
    "artifacts/09_tables/H10/H10_primary_interaction_results.csv"
  ),
  show_col_types = FALSE
)
diagnostics <- readr::read_csv(
  file.path(
    root,
    paste0(
      "artifacts/08_diagnostics/H10/",
      "H10_primary_diagnostic_assessment.csv"
    )
  ),
  show_col_types = FALSE
)
stability <- readr::read_csv(
  file.path(
    root,
    paste0(
      "artifacts/08_diagnostics/H10/sensitivity/",
      "H10_sensitivity_stability_summary.csv"
    )
  ),
  show_col_types = FALSE
)
paired <- readr::read_csv(
  file.path(
    root,
    paste0(
      "artifacts/08_diagnostics/H10/sensitivity/",
      "H10_paired_placement_main_effects.csv"
    )
  ),
  show_col_types = FALSE
)
gap_common <- readr::read_csv(
  file.path(
    root,
    paste0(
      "artifacts/08_diagnostics/H10/sensitivity/",
      "H10_primary_gap_common_sample_effects.csv"
    )
  ),
  show_col_types = FALSE
)
prereg <- readr::read_csv(
  file.path(
    root,
    paste0(
      "artifacts/08_diagnostics/H10/sensitivity/",
      "H10_preregistered_exclusion_effects.csv"
    )
  ),
  show_col_types = FALSE
)
mder_amendment <- readr::read_csv(
  file.path(
    root,
    "artifacts/09_tables/H10/H10_METRIC010_amendment_results.csv"
  ),
  show_col_types = FALSE
)
mder_distribution <- readr::read_csv(
  file.path(
    root,
    paste0(
      "artifacts/08_diagnostics/H10/sensitivity/",
      "H10_mder_current_distribution.csv"
    )
  ),
  show_col_types = FALSE
)
mder_influence <- readr::read_csv(
  file.path(
    root,
    paste0(
      "artifacts/08_diagnostics/H10/sensitivity/",
      "H10_mder_current_influence_assessment.csv"
    )
  ),
  show_col_types = FALSE
)
overview_source <- readr::read_csv(
  overview_source_path,
  show_col_types = FALSE
)
overview_manifest <- readr::read_csv(
  overview_manifest_path,
  show_col_types = FALSE
)
core_diagnostic_manifest <- readr::read_csv(
  core_diagnostic_manifest_path,
  show_col_types = FALSE
)
core_diagnostic_all <- readr::read_csv(
  core_diagnostic_all_source_path,
  show_col_types = FALSE
)
core_diagnostic_index <- readr::read_csv(
  core_diagnostic_index_path,
  show_col_types = FALSE
)
core_diagnostic_age <- readr::read_csv(
  file.path(
    root,
    paste0(
      "artifacts/11_source_data/H10/",
      "H10_retained_age_core_diagnostic_data.csv"
    )
  ),
  show_col_types = FALSE
)
core_diagnostic_sex <- readr::read_csv(
  file.path(
    root,
    paste0(
      "artifacts/11_source_data/H10/",
      "H10_retained_biological_sex_core_diagnostic_data.csv"
    )
  ),
  show_col_types = FALSE
)
site_registry <- readr::read_csv(
  file.path(root, "config/site_display_registry.csv"),
  show_col_types = FALSE
) |>
  arrange(.data$display_order)

stopifnot(
  nrow(metric_registry) == 17L,
  nrow(main) == 68L,
  nrow(interactions) == 68L,
  nrow(diagnostics) == 68L,
  nrow(stability) == 68L,
  nrow(paired) == 136L,
  nrow(gap_common) == 136L,
  nrow(prereg) == 68L,
  nrow(mder_amendment) == 8L,
  all(!mder_amendment$adjusted_significant),
  nrow(mder_distribution) == 38L,
  nrow(mder_influence) == 4L,
  all(mder_influence$metric_id == "mder_mean_of_viable_ratios"),
  sum(main$adjusted_significant) == 11L,
  sum(
    main$placement == "glasses" &
      main$predictor == "age" &
      main$adjusted_significant
  ) ==
    3L,
  sum(
    main$placement == "glasses" &
      main$predictor == "biological_sex" &
      main$adjusted_significant
  ) ==
    0L,
  sum(
    main$placement == "chest" &
      main$predictor == "age" &
      main$adjusted_significant
  ) ==
    6L,
  sum(
    main$placement == "chest" &
      main$predictor == "biological_sex" &
      main$adjusted_significant
  ) ==
    2L,
  sum(interactions$adjusted_significant) == 2L,
  all(
    interactions$placement[interactions$adjusted_significant] == "chest"
  ),
  all(
    interactions$predictor[interactions$adjusted_significant] == "age"
  ),
  sum(diagnostics$final_assessment == "acceptable") == 25L,
  sum(
    diagnostics$final_assessment == "acceptable with specified limitations"
  ) ==
    43L,
  !any(diagnostics$final_assessment == "not acceptable"),
  all(diagnostics$converged),
  all(diagnostics$positive_definite_hessian),
  all(diagnostics$fixed_full_rank),
  all(!diagnostics$singular),
  all(is.na(diagnostics$fit_error)),
  all(is.na(diagnostics$fit_warnings)),
  sum(stability$baseline_supported) == 11L,
  sum(
    stability$baseline_supported &
      stability$direction_stable
  ) ==
    11L,
  sum(
    stability$baseline_supported &
      stability$adjusted_support_stable
  ) ==
    8L
)

overview_age <- overview_source |>
  filter(.data$panel == "age_distribution")
overview_main <- overview_source |>
  filter(.data$panel == "retained_main_association")
overview_heterogeneity <- overview_source |>
  filter(.data$panel == "retained_site_heterogeneity")
overview_site_map <- overview_age |>
  distinct(
    .data$site,
    .data$site_display_order,
    .data$site_display_name,
    .data$site_color_hex
  ) |>
  arrange(.data$site_display_order)
stopifnot(
  nrow(overview_source) == 322L,
  nrow(overview_age) == 295L,
  sum(overview_age$placement == "glasses") == 141L,
  sum(overview_age$placement == "chest") == 154L,
  nrow(overview_main) == 11L,
  nrow(overview_heterogeneity) == 16L,
  identical(
    sort(unique(overview_main$metric_id)),
    sort(unique(main$metric_id[main$adjusted_significant]))
  ),
  all(overview_main$p_adjusted <= 0.05),
  setequal(
    unique(overview_heterogeneity$metric_id),
    c("m10_midpoint", "last_timing_above_250")
  ),
  identical(overview_site_map$site, site_registry$site),
  identical(overview_site_map$site_display_order, site_registry$display_order),
  identical(overview_site_map$site_display_name, site_registry$display_name),
  identical(overview_site_map$site_color_hex, site_registry$color_hex),
  !"Id" %in% names(overview_source),
  !"participant_key" %in% names(overview_source),
  nrow(overview_manifest) == 1L,
  overview_manifest$width_in == 9.4,
  overview_manifest$height_in == 13,
  overview_manifest$dpi == 300L,
  overview_manifest$pixel_width == 2820L,
  overview_manifest$pixel_height == 3900L,
  overview_manifest$display_width_mm == 170,
  nchar(overview_manifest$alt_text) >= 300L,
  identical(
    overview_manifest$figure_sha256,
    artifact_sha256(file.path(root, overview_manifest$figure_path))
  ),
  identical(
    overview_manifest$pdf_sha256,
    artifact_sha256(file.path(root, overview_manifest$pdf_path))
  ),
  identical(
    overview_manifest$source_data_sha256,
    artifact_sha256(file.path(root, overview_manifest$source_data_path))
  )
)

core_diagnostic_figure_rows <- core_diagnostic_manifest |>
  filter(!is.na(.data$figure_path))
core_site_map <- core_diagnostic_all |>
  distinct(
    .data$site,
    .data$site_display_order,
    .data$site_display_name,
    .data$site_color_hex
  ) |>
  arrange(.data$site_display_order)
stopifnot(
  nrow(core_diagnostic_manifest) == 3L,
  !anyDuplicated(core_diagnostic_manifest$figure_id),
  sum(core_diagnostic_manifest$models) == 79L,
  core_diagnostic_manifest$models[
    core_diagnostic_manifest$figure_id == "fig-h10-all-primary-core-diagnostics"
  ] ==
    68L,
  core_diagnostic_manifest$pages[
    core_diagnostic_manifest$figure_id == "fig-h10-all-primary-core-diagnostics"
  ] ==
    68L,
  all(
    vapply(
      file.path(root, core_diagnostic_figure_rows$figure_path),
      artifact_sha256,
      character(1)
    ) ==
      core_diagnostic_figure_rows$figure_sha256
  ),
  all(
    vapply(
      file.path(root, core_diagnostic_manifest$pdf_path),
      artifact_sha256,
      character(1)
    ) ==
      core_diagnostic_manifest$pdf_sha256
  ),
  all(
    vapply(
      file.path(root, core_diagnostic_manifest$source_data_path),
      artifact_sha256,
      character(1)
    ) ==
      core_diagnostic_manifest$source_data_sha256
  ),
  all(
    vapply(
      file.path(root, core_diagnostic_manifest$model_index_path),
      artifact_sha256,
      character(1)
    ) ==
      core_diagnostic_manifest$model_index_sha256
  ),
  nrow(core_diagnostic_all) == 99312L,
  !anyDuplicated(core_diagnostic_all[c(
    "model_key",
    "diagnostic_type",
    "model_row_id"
  )]),
  nrow(distinct(core_diagnostic_all, .data$model_key)) == 68L,
  setequal(
    unique(core_diagnostic_all$diagnostic_type),
    c("Residuals vs fitted", "Normal Q-Q")
  ),
  nrow(core_diagnostic_index) == 68L,
  !anyDuplicated(core_diagnostic_index$model_key),
  identical(as.integer(core_diagnostic_index$page), seq_len(68L)),
  sum(core_diagnostic_index$adjusted_significant) == 11L,
  nrow(core_diagnostic_age) == 15340L,
  nrow(distinct(core_diagnostic_age, .data$model_key)) == 9L,
  all(core_diagnostic_age$predictor == "age"),
  all(core_diagnostic_age$adjusted_significant),
  nrow(core_diagnostic_sex) == 3608L,
  nrow(distinct(core_diagnostic_sex, .data$model_key)) == 2L,
  all(core_diagnostic_sex$predictor == "biological_sex"),
  all(core_diagnostic_sex$adjusted_significant),
  identical(core_site_map$site, site_registry$site),
  identical(core_site_map$site_display_order, site_registry$display_order),
  identical(core_site_map$site_display_name, site_registry$display_name),
  identical(core_site_map$site_color_hex, site_registry$color_hex)
)

tbt10 <- metric_registry |>
  filter(.data$metric_id == "duration_below_10_pre_sleep")
mder <- metric_registry |>
  filter(.data$metric_id == "mder_mean_of_viable_ratios")
primary_mder <- main |>
  filter(.data$metric_id == "mder_mean_of_viable_ratios")
stopifnot(
  nrow(tbt10) == 1L,
  tbt10$response_family == "gaussian",
  tbt10$response_transform == "identity",
  tbt10$effect_scale == "difference",
  tbt10$display_unit == "h",
  nrow(mder) == 1L,
  mder$response_family == "gaussian",
  mder$response_transform == "identity",
  nrow(primary_mder) == 4L,
  setequal(primary_mder$participants, c(137L, 152L)),
  setequal(primary_mder$participant_days, c(702L, 732L)),
  all(!primary_mder$adjusted_significant)
)

expected_findings <- tibble::tribble(
  ~placement,
  ~predictor,
  ~metric_id,
  ~estimate,
  ~low,
  ~high,
  ~p_adjusted,
  "glasses",
  "age",
  "m10_mean_medi",
  1.313871132,
  1.092089315,
  1.580692464,
  0.017547150,
  "glasses",
  "age",
  "duration_above_1000",
  1.269840506,
  1.112084131,
  1.449975651,
  0.009269941,
  "glasses",
  "age",
  "dose_time_sensitive_corrected_medi",
  1.305134346,
  1.093177131,
  1.558188159,
  0.017547150,
  "chest",
  "age",
  "daily_geometric_mean_medi",
  1.161772878,
  1.042194292,
  1.295071592,
  0.016651692,
  "chest",
  "age",
  "m10_mean_medi",
  1.345532447,
  1.154202204,
  1.568579197,
  0.000580353,
  "chest",
  "age",
  "duration_above_1000",
  1.311858537,
  1.179017027,
  1.459667487,
  0.000024102,
  "chest",
  "age",
  "duration_above_250_wake",
  1.157400855,
  1.060865063,
  1.262721139,
  0.004021490,
  "chest",
  "age",
  "longest_bout_above_250",
  1.177184663,
  1.086916654,
  1.274949396,
  0.000327336,
  "chest",
  "age",
  "dose_time_sensitive_corrected_medi",
  1.395458951,
  1.212402195,
  1.606154865,
  0.000033297,
  "chest",
  "biological_sex",
  "daily_geometric_mean_medi",
  0.741827454,
  0.598127896,
  0.920050671,
  0.048198610,
  "chest",
  "biological_sex",
  "l10_mean_medi",
  0.762538182,
  0.647876110,
  0.897493317,
  0.016386871
)
observed_findings <- main |>
  filter(.data$adjusted_significant) |>
  select(
    "placement",
    "predictor",
    "metric_id",
    estimate = "estimate_practical",
    low = "conf_low_practical",
    high = "conf_high_practical",
    "p_adjusted"
  ) |>
  arrange(.data$placement, .data$predictor, .data$metric_id)
expected_findings <- expected_findings |>
  arrange(.data$placement, .data$predictor, .data$metric_id)
stopifnot(
  identical(
    observed_findings[, c("placement", "predictor", "metric_id")],
    expected_findings[, c("placement", "predictor", "metric_id")]
  ),
  isTRUE(all.equal(
    observed_findings$estimate,
    expected_findings$estimate,
    tolerance = 5e-6
  )),
  isTRUE(all.equal(
    observed_findings$low,
    expected_findings$low,
    tolerance = 5e-6
  )),
  isTRUE(all.equal(
    observed_findings$high,
    expected_findings$high,
    tolerance = 5e-6
  )),
  isTRUE(all.equal(
    observed_findings$p_adjusted,
    expected_findings$p_adjusted,
    tolerance = 5e-6
  ))
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

qmd <- paste(readLines(qmd_path, warn = FALSE), collapse = "\n")
required_qmd <- c(
  "title=\"Answer in brief\"",
  "age_decade = age / 10",
  "response ~ site + age_decade + (1 | site:Id)",
  "response ~ site * biological_sex + (1 | site:Id)",
  "Gaussian identity model on hours",
  "four separate complete 17-test FDR families",
  "arithmetic mean of viable one-minute",
  "mder_mean_of_viable_ratios",
  "Every finite primary and gap-timing-unaware MDER value is strictly ",
  "Biological sex and gender were recorded as separate variables",
  "accepted analyses used biological sex, coded Female or Male",
  "gender was not analysed",
  "analysis provides no inference about gender identity",
  "The near-eye sensor position was primary",
  "not an equivalence margin",
  "complete independent reconstruction",
  "Core residual checks",
  "68-page diagnostic appendix"
)
stopifnot(all(vapply(
  required_qmd,
  function(x) grepl(x, qmd, fixed = TRUE),
  logical(1)
)))
stopifnot(
  !grepl("neither measured nor inferred", qmd, fixed = TRUE),
  !grepl("No gender field", qmd, fixed = TRUE),
  !grepl(
    "\\b(lmer|glmer|glmmTMB|lm|glm|gam|bam)\\s*\\(",
    qmd,
    perl = TRUE
  ),
  !grepl(
    "\\b(predict|simulate|bootstrap|boot)\\s*\\(",
    qmd,
    perl = TRUE
  )
)

html <- xml2::read_html(html_path)
main_node <- xml2::xml_find_first(html, "//main")
stopifnot(!inherits(main_node, "xml_missing"))
main_text <- xml2::xml_text(main_node)
main_text_compact <- gsub("[[:space:]]+", " ", main_text)

required_html <- c(
  "Answer in brief",
  "Personal light exposure metrics depend on age and gender",
  "measured biological sex",
  "Age, per 10 years",
  "Female minus Male",
  "Time below 10 lx melEDI before sleep",
  "Current MDER associations",
  "702 participant-days from 137 participants",
  "687 participant-days from 137 participants",
  "Every finite primary and gap-timing-unaware MDER value is strictly positive",
  "A day with no viable momentary ratio is reason-coded missing",
  "Gaussian",
  "FDR-adjusted p",
  "Near eye (primary)",
  "Chest (complementary)",
  "The 11 main associations retained after FDR adjustment.",
  "every main association that met its separately labelled 17-metric FDR rule",
  "295 de-identified participant display rows",
  "Twenty-five models were assessed acceptable",
  "43 acceptable with specified limitations",
  "zero not acceptable",
  "Core residual checks",
  "68-page diagnostic appendix",
  "gap-timing-unaware dataset",
  "applies the same general coverage rules as the primary dataset",
  paste0(
    "does not use the timing of remaining missing observations ",
    "for metric-specific adjustment"
  ),
  "not an equivalence margin",
  "IS and IV were unavailable",
  "R 4.6.1"
)
stopifnot(all(vapply(
  required_html,
  function(x) grepl(x, main_text_compact, fixed = TRUE),
  logical(1)
)))
stopifnot(
  grepl(
    "Biological sex and gender were recorded as separate variables",
    main_text_compact,
    fixed = TRUE
  ),
  grepl(
    "accepted analyses used biological sex, coded Female or Male",
    main_text_compact,
    fixed = TRUE
  ),
  grepl("gender was not analysed", main_text_compact, fixed = TRUE),
  grepl(
    "analysis provides no inference about gender identity",
    main_text_compact,
    fixed = TRUE
  ),
  grepl(
    "gender was recorded separately but not analysed",
    main_text_compact,
    fixed = TRUE
  ),
  !grepl("neither measured nor inferred", main_text_compact, fixed = TRUE),
  !grepl("No gender field", main_text_compact, fixed = TRUE)
)

answer_position <- regexpr("Answer in brief", main_text_compact, fixed = TRUE)
methods_position <- regexpr(
  "Methods and rationale",
  main_text_compact,
  fixed = TRUE
)
gap_term_position <- regexpr(
  "gap-timing-unaware dataset",
  main_text_compact,
  fixed = TRUE
)
gap_definition_position <- regexpr(
  "applies the same general coverage rules as the primary dataset",
  main_text_compact,
  fixed = TRUE
)
stopifnot(
  answer_position > 0L,
  methods_position > answer_position,
  gap_term_position > 0L,
  gap_definition_position > gap_term_position,
  gap_definition_position - gap_term_position < 200L
)

forbidden_html <- c(
  "\\bV0\\b",
  "\\bStage[[:space:]]+[1-4]\\b",
  "construction variant",
  "\\bbout\\b",
  "temperature"
)
stopifnot(all(
  !vapply(
    forbidden_html,
    function(pattern)
      grepl(
        pattern,
        main_text_compact,
        ignore.case = TRUE,
        perl = TRUE
      ),
    logical(1)
  )
))

figure_images <- xml2::xml_find_all(
  main_node,
  ".//figure//img[contains(concat(' ', normalize-space(@class), ' '), ' figure-img ')]"
)
stopifnot(length(figure_images) == 8L)
figure_alts <- xml2::xml_attr(figure_images, "alt")
stopifnot(
  all(!is.na(figure_alts)),
  all(nchar(figure_alts) >= 200L),
  all(
    grepl("95% confidence", figure_alts, fixed = TRUE) |
      grepl("acceptable", figure_alts, ignore.case = TRUE) |
      grepl("Pearson residual", figure_alts, fixed = TRUE)
  )
)

gt_tables <- xml2::xml_find_all(
  main_node,
  ".//table[contains(concat(' ', normalize-space(@class), ' '), ' gt_table ')]"
)
stopifnot(length(gt_tables) >= 12L)

csv_links <- xml2::xml_find_all(main_node, ".//a[contains(@href, '.csv')]")
csv_hrefs <- unique(xml2::xml_attr(csv_links, "href"))
stopifnot(length(csv_hrefs) >= 17L)
resolved_links <- file.path(dirname(html_path), utils::URLdecode(csv_hrefs))
stopifnot(all(file.exists(resolved_links)))

pdf_links <- xml2::xml_find_all(main_node, ".//a[contains(@href, '.pdf')]")
pdf_hrefs <- unique(xml2::xml_attr(pdf_links, "href"))
stopifnot(any(grepl(
  "H10_all_primary_model_core_diagnostics.pdf",
  pdf_hrefs,
  fixed = TRUE
)))
resolved_pdf_links <- file.path(
  dirname(html_path),
  utils::URLdecode(pdf_hrefs)
)
stopifnot(all(file.exists(resolved_pdf_links)))

qa <- readr::read_csv(qa_csv_path, show_col_types = FALSE)
stopifnot(
  nrow(qa) == 8L,
  all(qa$overall_status == "PASS"),
  all(qa$visual_status == "PASS"),
  all(qa$typography_status == "PASS_BY_CALCULATION"),
  all(abs(qa$intended_display_width_mm - 170) < 1e-8),
  all(qa$a4_side_margin_mm >= 20),
  all(qa$effective_final_essential_text_pt >= 5),
  all(qa$effective_final_central_text_pt >= 7),
  all(qa$pixel_width == 2820L),
  all(nchar(qa$sha256) == 64L),
  file.info(qa_pdf_path)$size > 0L
)

stage3_manifest <- readr::read_csv(
  stage3_manifest_path,
  show_col_types = FALSE
)
stage3_paths <- file.path(root, stage3_manifest$path)
downstream_preparation_manifest_path <- file.path(
  root,
  "artifacts/12_manifests/H10/H10_preparation_report_manifest.csv"
)
stopifnot(
  nrow(stage3_manifest) > 80L,
  !anyDuplicated(stage3_manifest$path),
  all(file.exists(stage3_paths)),
  all(nchar(stage3_manifest$sha256) == 64L),
  !stage3_manifest_path %in% stage3_paths,
  !downstream_preparation_manifest_path %in% stage3_paths
)
stage3_observed <- unname(vapply(
  stage3_paths,
  artifact_sha256,
  character(1)
))
stage3_mismatch <- stage3_manifest$path[
  stage3_observed != stage3_manifest$sha256
]
expected_historical_transitions <- c(
  "audit/hypotheses/H10/H10_analysis_preparation.qmd",
  "tests/hypotheses/H10/test_h10_preparation_report.R",
  "tests/hypotheses/H10/test_h10_stage3_reader_report.R",
  "_build/nathealth/notebooks/hypotheses/H10.html",
  "notebooks/hypotheses/H10.qmd",
  "_quarto-nathealth.yml"
)
stopifnot(
  length(stage3_mismatch) == 6L,
  setequal(stage3_mismatch, expected_historical_transitions),
  identical(
    artifact_sha256(
      file.path(
        root,
        "audit/hypotheses/H10/H10_analysis_preparation.qmd"
      )
    ),
    "706fe46f293bd09bfd3cb75c14bc3082410a452acfff666d76219f266fded1a6"
  ),
  identical(
    artifact_sha256(
      file.path(root, "tests/hypotheses/H10/test_h10_preparation_report.R")
    ),
    "15d20f3c3fe4d5387eb64152479d07ea0e94b397b27b0a7b59b3d41c7a1924c4"
  ),
  identical(
    artifact_sha256(file.path(root, "notebooks/hypotheses/H10.qmd")),
    "0cf302f74c482168c5f5d4c640bbc6a80ef451333f7d76f3c3be204ac1b5f64d"
  ),
  identical(
    artifact_sha256(file.path(root, "_quarto-nathealth.yml")),
    "80dd05573b6c764272d0d0aa1c82571bdaab3cb2bee9ee34441e2456318708e3"
  ),
  !identical(
    artifact_sha256(html_path),
    stage3_manifest$sha256[
      stage3_manifest$path == "_build/nathealth/notebooks/hypotheses/H10.html"
    ]
  )
)

message("H10 standalone reader-report checks passed")
