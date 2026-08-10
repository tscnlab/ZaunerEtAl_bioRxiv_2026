# Focused scientific, reporting, and structural checks for the standalone H09
# reader report. Scientific assertions read accepted frozen outputs and do not
# refit an inferential model.

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
  stop("H09 reader-report tests require R 4.6.1", call. = FALSE)
}

source(file.path(root, "scripts/pipeline/paths_io.R"))
source(file.path(root, "scripts/pipeline/p_value_display.R"))

h09_path <- function(area, name) {
  file.path(root, "artifacts", area, "H09", name)
}
read_h09 <- function(area, name) {
  readr::read_csv(h09_path(area, name), show_col_types = FALSE, na = "")
}

qmd_path <- file.path(root, "notebooks/hypotheses/H09.qmd")
html_path <- file.path(
  root,
  "_build/nathealth/notebooks/hypotheses/H09.html"
)
builder_path <- file.path(
  root,
  "scripts/hypotheses/H09/build_h09_stage3_manifest.R"
)
handoff_path <- file.path(root, "audit/handoffs/H09_worker_handoff.md")
decision_path <- file.path(
  root,
  "audit/hypotheses/H09/H09_stage2_gate_and_stage3_transition.md"
)
manifest_path <- h09_path("12_manifests", "H09_stage3_artifacts.csv")

required_files <- c(
  qmd_path,
  html_path,
  builder_path,
  handoff_path,
  decision_path,
  manifest_path,
  h09_path("06_model_data", "H09_metric_registry.csv"),
  h09_path("06_model_data", "H09_predictor_registry.csv"),
  h09_path("08_diagnostics", "H09_chronotype_score_audit.csv"),
  h09_path("08_diagnostics", "H09_diagnostic_assessment_registry.csv"),
  h09_path("08_diagnostics", "H09_diagnostic_target_summary.csv"),
  h09_path("08_diagnostics", "H09_diagnostic_author_adjudication.csv"),
  h09_path("08_diagnostics", "H09_residual_diagnostics.csv"),
  h09_path("09_tables", "H09_model_results_master.csv"),
  h09_path("09_tables", "H09_family_audit.csv"),
  h09_path("09_tables", "H09_paired_placement_effects.csv"),
  h09_path("09_tables", "H09_gap_timing_unaware_sensitivity.csv"),
  h09_path("09_tables", "H09_photoperiod_sensitivity.csv"),
  h09_path("09_tables", "H09_participant_summary_sensitivity.csv"),
  h09_path("09_tables", "H09_ar1_sensitivity.csv"),
  h09_path("09_tables", "H09_l10_cut_sensitivity.csv"),
  h09_path("09_tables", "H09_fifth_outcome_sensitivity.csv"),
  h09_path("10_figures", "H09_primary_effects.png"),
  h09_path("10_figures", "H09_paired_placement_effects.png"),
  h09_path("10_figures", "H09_diagnostics_near_eye.png"),
  h09_path("10_figures", "H09_diagnostics_chest.png")
)
stopifnot(all(file.exists(required_files)))

master <- read_h09("09_tables", "H09_model_results_master.csv")
families <- read_h09("09_tables", "H09_family_audit.csv")
diagnostic_registry <- read_h09(
  "08_diagnostics",
  "H09_diagnostic_assessment_registry.csv"
)
diagnostic_summary <- read_h09(
  "08_diagnostics",
  "H09_diagnostic_target_summary.csv"
)
diagnostic_adjudication <- read_h09(
  "08_diagnostics",
  "H09_diagnostic_author_adjudication.csv"
)
residual <- read_h09("08_diagnostics", "H09_residual_diagnostics.csv")
paired <- read_h09("09_tables", "H09_paired_placement_effects.csv")
gap <- read_h09("09_tables", "H09_gap_timing_unaware_sensitivity.csv")
photoperiod <- read_h09("09_tables", "H09_photoperiod_sensitivity.csv")
participant <- read_h09(
  "09_tables",
  "H09_participant_summary_sensitivity.csv"
)
ar1 <- read_h09("09_tables", "H09_ar1_sensitivity.csv")
l10 <- read_h09("09_tables", "H09_l10_cut_sensitivity.csv")
fifth <- read_h09("09_tables", "H09_fifth_outcome_sensitivity.csv")

primary <- master |>
  filter(
    .data$data_scenario_id == "primary",
    .data$sample_scenario == "all_available",
    .data$primary_family_member
  )
near <- primary |> filter(.data$placement == "glasses")
chest <- primary |> filter(.data$placement == "chest")
primary_families <- families |>
  filter(.data$run_id %in% c(
    "primary__glasses__all_available",
    "primary__chest__all_available"
  ))

stopifnot(
  nrow(primary) == 20L,
  nrow(near) == 10L,
  nrow(chest) == 10L,
  nrow(primary_families) == 8L,
  all(primary_families$planned_members == 5L),
  all(primary_families$complete_registered_family),
  all(primary_families$independent_recalculation_matches),
  sum(near$main_adjusted_significant) == 6L,
  sum(chest$main_adjusted_significant) == 4L,
  !any(primary$interaction_adjusted_significant),
  range(near$participants) == c(131L, 141L),
  range(near$participant_days) == c(478L, 816L),
  range(near$observations) == c(478L, 816L),
  isTRUE(all.equal(range(near$derivation_hours), c(11325.55, 18851.0))),
  all(near$sites == 9L),
  range(chest$participants) == c(149L, 154L),
  range(chest$participant_days) == c(547L, 902L),
  range(chest$observations) == c(547L, 902L),
  isTRUE(all.equal(range(chest$derivation_hours), c(12980.05, 20891.75))),
  all(chest$sites == 8L)
)

near_first_mctq <- near |>
  filter(
    .data$metric_id == "first_timing_above_250",
    .data$instrument_id == "MCTQ"
  )
near_first_meq <- near |>
  filter(
    .data$metric_id == "first_timing_above_250",
    .data$instrument_id == "MEQ"
  )
stopifnot(
  nrow(near_first_mctq) == 1L,
  isTRUE(all.equal(
    near_first_mctq$estimate,
    0.381236542890041,
    tolerance = 1e-12
  )),
  isTRUE(all.equal(
    near_first_mctq$conf_low,
    0.146253946350557,
    tolerance = 1e-12
  )),
  isTRUE(all.equal(
    near_first_mctq$conf_high,
    0.616219139429526,
    tolerance = 1e-12
  )),
  isTRUE(all.equal(
    near_first_mctq$main_p_adjusted,
    0.00298827104154086,
    tolerance = 1e-12
  )),
  nrow(near_first_meq) == 1L,
  isTRUE(all.equal(
    near_first_meq$estimate,
    -0.443907364409369,
    tolerance = 1e-12
  )),
  isTRUE(all.equal(
    near_first_meq$conf_low,
    -0.698616503785482,
    tolerance = 1e-12
  )),
  isTRUE(all.equal(
    near_first_meq$conf_high,
    -0.189198225033256,
    tolerance = 1e-12
  )),
  isTRUE(all.equal(
    near_first_meq$main_p_adjusted,
    0.00130345909142947,
    tolerance = 1e-12
  ))
)

stopifnot(
  nrow(diagnostic_registry) == 24L * 16L,
  sum(diagnostic_summary$overall_assessment == "acceptable") == 18L,
  sum(diagnostic_summary$overall_assessment == "not acceptable") == 6L,
  all(
    diagnostic_registry$assessment[
      diagnostic_registry$domain %in% c(
        "Response and residual distribution",
        "Residual heteroscedasticity"
      )
    ] == "acceptable"
  ),
  all(grepl(
    "H09-002",
    diagnostic_registry$assessment_basis[
      diagnostic_registry$domain %in% c(
        "Response and residual distribution",
        "Residual heteroscedasticity"
      )
    ]
  )),
  nrow(diagnostic_adjudication) == 48L,
  all(diagnostic_adjudication$author_final_assessment == "acceptable"),
  sum(diagnostic_adjudication$numeric_flag_overridden) == 12L,
  sum(residual$distribution_assessment == "not acceptable") == 14L,
  sum(residual$heteroscedasticity_assessment == "not acceptable") == 4L
)

registered_gap <- gap |>
  filter(.data$metric_id != "mean_timing_above_250")
longest_gap <- registered_gap$metric_id == "longest_period_midpoint"
estimable_gap <- !longest_gap
stopifnot(
  nrow(registered_gap) == 20L,
  sum(longest_gap) == 4L,
  all(registered_gap$exact_common_keys[estimable_gap]),
  sum(
    registered_gap$common_sample_stability[estimable_gap] ==
      "stable within model uncertainty"
  ) == 15L,
  sum(
    registered_gap$common_sample_stability[estimable_gap] ==
      "precision-sensitive"
  ) == 1L,
  all(registered_gap$common_sample_stability[longest_gap] == "non-estimable"),
  nrow(paired) == 10L,
  all(paired$exact_sample_match),
  all(grepl("Not estimated", paired$difference_interval_status)),
  all(grepl("Not assessed", paired$equivalence_status)),
  nrow(photoperiod) == 24L,
  sum(photoperiod$stability_classification ==
    "stable within model uncertainty") == 21L,
  sum(photoperiod$stability_classification == "direction-sensitive") == 2L,
  sum(photoperiod$stability_classification == "precision-sensitive") == 1L,
  nrow(participant) == 24L,
  sum(participant$stability_classification ==
    "stable within model uncertainty") == 20L,
  sum(participant$stability_classification == "direction-sensitive") == 4L,
  nrow(ar1) == 24L,
  all(ar1$stability_classification == "stable within model uncertainty"),
  max(abs(ar1$ar1_effect_difference)) < 0.0162,
  nrow(l10) == 4L,
  all(l10$clock_cut_assessment == "acceptable"),
  max(abs(l10$estimate_difference)) < 0.0372
)

near_mean_meq <- fifth |>
  filter(
    .data$placement == "glasses",
    .data$instrument_id == "MEQ",
    .data$metric_id == "mean_timing_above_250"
  )
stopifnot(
  nrow(near_mean_meq) == 1L,
  isTRUE(all.equal(
    near_mean_meq$estimate,
    -0.168546786308248,
    tolerance = 1e-12
  )),
  isTRUE(all.equal(
    near_mean_meq$conf_low,
    -0.334338166366937,
    tolerance = 1e-12
  )),
  isTRUE(all.equal(
    near_mean_meq$conf_high,
    -0.00275540624955922,
    tolerance = 1e-12
  )),
  isTRUE(all.equal(
    near_mean_meq$main_p_raw,
    0.0405414552561953,
    tolerance = 1e-12
  )),
  is.na(near_mean_meq$main_p_adjusted)
)

stopifnot(
  identical(
    nh_format_p_value(c(0.0009, 0.001, 0.003, 0.055, 1, NA_real_)),
    c("<0.001", "0.001", "0.003", "0.055", "1.000", "—")
  ),
  identical(
    nh_p_value_display(c(0.04, 0.06), c(TRUE, FALSE))$p_bold,
    c(TRUE, FALSE)
  )
)

qmd <- paste(readLines(qmd_path, warn = FALSE), collapse = "\n")
builder <- paste(readLines(builder_path, warn = FALSE), collapse = "\n")
handoff <- paste(readLines(handoff_path, warn = FALSE), collapse = "\n")
stopifnot(
  grepl(artifact_sha256(qmd_path), handoff, fixed = TRUE),
  grepl(artifact_sha256(html_path), handoff, fixed = TRUE),
  grepl(
    paste0(
      "bytes: ",
      format(
        file.info(qmd_path)$size,
        big.mark = ",",
        scientific = FALSE,
        trim = TRUE
      )
    ),
    handoff,
    fixed = TRUE
  ),
  grepl(
    paste0(
      "bytes: ",
      format(
        file.info(html_path)$size,
        big.mark = ",",
        scientific = FALSE,
        trim = TRUE
      )
    ),
    handoff,
    fixed = TRUE
  )
)

forbidden_reader_patterns <- c(
  "\\bV0\\b",
  "\\bStage [1234]\\b",
  "construction variant",
  "author gate",
  "Codex",
  "legacy",
  "\\btemperature\\b",
  "\\bbout\\b"
)
for (pattern in forbidden_reader_patterns) {
  stopifnot(!grepl(pattern, qmd, ignore.case = TRUE, perl = TRUE))
}
fit_patterns <- c(
  "lme4::lmer\\s*\\(",
  "nlme::lme\\s*\\(",
  "stats::lm\\s*\\(",
  "stats::glm\\s*\\(",
  "boot::boot\\s*\\(",
  "predict\\s*\\(",
  "simulate\\s*\\("
)
for (pattern in fit_patterns) {
  stopifnot(
    !grepl(pattern, qmd, perl = TRUE),
    !grepl(pattern, builder, perl = TRUE)
  )
}

expected_formulas <- c(
  "timing_hour ~ site + (1 | site:Id)",
  "timing_hour ~ site + mctq_hour_centered + (1 | site:Id)",
  "timing_hour ~ site * mctq_hour_centered + (1 | site:Id)",
  "timing_hour ~ site + meq_10_centered + (1 | site:Id)",
  "timing_hour ~ site * meq_10_centered + (1 | site:Id)"
)
for (formula in expected_formulas) {
  stopifnot(grepl(formula, qmd, fixed = TRUE))
}

document <- xml2::read_html(html_path)
main <- xml2::xml_find_first(document, "//main[@id='quarto-document-content']")
stopifnot(!inherits(main, "xml_missing"))
main_text <- xml2::xml_text(main)
main_text_lower <- tolower(main_text)

stopifnot(
  grepl(
    "H9: Timing-based metrics are associated with chronotype (MCTQ, MEQ).",
    main_text,
    fixed = TRUE
  ),
  grepl("Answer in brief", main_text, fixed = TRUE),
  grepl("+0.381 h", main_text, fixed = TRUE),
  grepl("+0.146 to +0.616", main_text, fixed = TRUE),
  grepl("BH-adjusted p = 0.003", main_text, fixed = TRUE),
  grepl("−0.444 h", main_text, fixed = TRUE),
  grepl("−0.699 to −0.189", main_text, fixed = TRUE),
  grepl("BH-adjusted p = 0.001", main_text, fixed = TRUE),
  grepl("gap-timing-unaware dataset", main_text_lower, fixed = TRUE),
  grepl("50%-per-hour", main_text_lower, fixed = TRUE),
  grepl("80%-per-day", main_text_lower, fixed = TRUE),
  grepl("time-sensitive primary dataset", main_text_lower, fixed = TRUE),
  grepl("eighteen targets", main_text_lower, fixed = TRUE),
  grepl("six retained", main_text_lower, fixed = TRUE),
  grepl("not an equivalence", main_text_lower, fixed = TRUE),
  grepl("does not establish that chronotype causes", main_text_lower, fixed = TRUE)
)
for (pattern in forbidden_reader_patterns) {
  stopifnot(!grepl(pattern, main_text, ignore.case = TRUE, perl = TRUE))
}
for (formula in expected_formulas) {
  stopifnot(grepl(formula, main_text, fixed = TRUE))
}

hypothesis_section <- xml2::xml_find_first(
  main,
  ".//section[@id='hypothesis-and-analytical-question']"
)
callout <- xml2::xml_find_first(
  hypothesis_section,
  ".//div[contains(concat(' ', normalize-space(@class), ' '), ' callout-note ')]"
)
stopifnot(
  !inherits(hypothesis_section, "xml_missing"),
  !inherits(callout, "xml_missing"),
  xml2::xml_attr(callout, "title") == "Answer in brief",
  identical(xml2::xml_parent(callout), hypothesis_section),
  xml2::xml_path(tail(xml2::xml_children(hypothesis_section), 1L)) ==
    xml2::xml_path(callout)
)
callout_text <- tolower(xml2::xml_text(callout))
stopifnot(
  grepl("near-eye", callout_text, fixed = TRUE),
  grepl("chest", callout_text, fixed = TRUE),
  grepl("95% ci", callout_text, fixed = TRUE),
  grepl("bh-adjusted", callout_text, fixed = TRUE),
  grepl("sensitiv", callout_text)
)

expected_tables <- c(
  "tbl-h09-metrics",
  "tbl-h09-formulas",
  "tbl-h09-primary-samples",
  "tbl-h09-near-eye-results",
  "tbl-h09-chest-results",
  "tbl-h09-interactions",
  "tbl-h09-paired-placement",
  "tbl-h09-qualified-diagnostics",
  "tbl-h09-gap-sensitivity",
  "tbl-h09-sensitivity-summary",
  "tbl-h09-mean-timing-sensitivity"
)
expected_figures <- c(
  "fig-h09-primary-effects",
  "fig-h09-paired-placement",
  "fig-h09-near-eye-diagnostics",
  "fig-h09-chest-diagnostics"
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
stopifnot(all(data_rows <= 20L), all(header_columns <= 7L))

figure_predicate <- paste0("@id='", expected_figures, "'", collapse = " or ")
images <- xml2::xml_find_all(
  main,
  paste0(".//*[", figure_predicate, "]//img")
)
stopifnot(length(images) == length(expected_figures))
stopifnot(
  all(nzchar(xml2::xml_attr(images, "src"))),
  all(nzchar(xml2::xml_attr(images, "alt")))
)

expected_source_links <- c(
  "H09_primary_effects_data.csv",
  "H09_model_results_master.csv",
  "H09_site_specific_slopes.csv",
  "H09_paired_placement_effects_data.csv",
  "H09_diagnostic_assessment_registry.csv",
  "H09_diagnostic_author_adjudication.csv",
  "H09_participant_influence_summary.csv",
  "H09_leave_one_site_out_summary.csv",
  "H09_gap_timing_unaware_sensitivity.csv",
  "H09_photoperiod_sensitivity.csv",
  "H09_participant_summary_sensitivity.csv",
  "H09_ar1_sensitivity.csv",
  "H09_l10_cut_sensitivity.csv",
  "H09_fifth_outcome_sensitivity.csv",
  "H09_figure_manifest.csv"
)
hrefs <- xml2::xml_attr(xml2::xml_find_all(main, ".//a[@href]"), "href")
for (filename in expected_source_links) {
  matching_href <- hrefs[grepl(filename, hrefs, fixed = TRUE)]
  stopifnot(
    length(matching_href) >= 1L,
    all(file.exists(file.path(dirname(html_path), matching_href)))
  )
}

manifest <- readr::read_csv(manifest_path, show_col_types = FALSE)
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
  "notebooks/hypotheses/H09.qmd",
  "_build/nathealth/notebooks/hypotheses/H09.html",
  "scripts/hypotheses/H09/h09_contract.R",
  "scripts/hypotheses/H09/h09_modeling.R",
  "scripts/hypotheses/H09/run_h09_stage2.R",
  "scripts/hypotheses/H09/build_h09_stage3_manifest.R",
  "tests/hypotheses/H09/test_h09_stage2.R",
  "tests/hypotheses/H09/test_h09_stage3_reader_report.R",
  "audit/hypotheses/H09/01_audit_and_plan.qmd",
  "audit/hypotheses/H09/02_implementation_and_v0_comparison.qmd",
  "audit/hypotheses/H09/H09_stage2_gate_and_stage3_transition.md",
  "audit/handoffs/H09_worker_handoff.md",
  "artifacts/09_tables/H09/H09_model_results_master.csv",
  "artifacts/10_figures/H09/H09_primary_effects.png",
  "artifacts/10_figures/H09/H09_paired_placement_effects.png",
  "artifacts/12_manifests/H09/H09_stage2_artifacts.csv"
)
stopifnot(
  identical(names(manifest), expected_manifest_columns),
  !anyDuplicated(manifest$path),
  all(expected_manifest_paths %in% manifest$path),
  !"artifacts/12_manifests/H09/H09_stage3_artifacts.csv" %in%
    manifest$path,
  !"audit/hypotheses/H09/H09_analysis_preparation.qmd" %in%
    manifest$path,
  all(manifest$r_version == "4.6.1"),
  all(nchar(manifest$sha256) == 64L)
)
manifest_absolute <- file.path(root, manifest$path)
stopifnot(
  all(file.exists(manifest_absolute)),
  identical(
    unname(vapply(manifest_absolute, artifact_sha256, character(1))),
    manifest$sha256
  )
)

message(
  "H09 reader-report tests passed: five registered outcomes, separate MCTQ ",
  "and MEQ families, 11 compact tables, four accessible figures, exact ",
  "samples, amended diagnostics, and structured sensitivities"
)
