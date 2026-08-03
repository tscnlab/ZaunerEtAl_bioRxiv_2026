# Focused scientific, reporting, and structural checks for the standalone H08
# reader report. All scientific assertions read the accepted frozen outputs;
# this test does not refit an inferential model.

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
  stop("H08 reader-report tests require R 4.6.1", call. = FALSE)
}

source(file.path(root, "scripts/pipeline/paths_io.R"))
source(file.path(root, "scripts/pipeline/p_value_display.R"))

h08_path <- function(area, name) {
  file.path(root, "artifacts", area, "H08", name)
}

qmd_path <- file.path(root, "notebooks/hypotheses/H08.qmd")
html_path <- file.path(
  root,
  "_build/nathealth/notebooks/hypotheses/H08.html"
)
builder_path <- file.path(
  root,
  "scripts/hypotheses/H08/build_h08_stage3_manifest.R"
)
handoff_path <- file.path(root, "audit/handoffs/H08_worker_handoff.md")
manifest_path <- h08_path("12_manifests", "H08_stage3_artifacts.csv")

required_files <- c(
  qmd_path,
  html_path,
  builder_path,
  handoff_path,
  manifest_path,
  h08_path("06_model_data", "H08_metric_registry.csv"),
  h08_path("06_model_data", "H08_model_frame_index.csv"),
  h08_path("08_diagnostics", "H08_model_diagnostics.csv"),
  h08_path("08_diagnostics", "H08_response_family_gate.csv"),
  h08_path("08_diagnostics", "H08_leave_one_site_out_summary.csv"),
  h08_path("09_tables", "H08_model_results_master.csv"),
  h08_path("09_tables", "H08_family_audit.csv"),
  h08_path("09_tables", "H08_gap_timing_unaware_sensitivity.csv"),
  h08_path("09_tables", "H08_photoperiod_sensitivity.csv"),
  h08_path("09_tables", "H08_participant_summary_sensitivity.csv"),
  h08_path(
    "09_tables",
    "H08_exactly_identified_longest_period_sensitivity.csv"
  ),
  h08_path("09_tables", "H08_observed_dose_sensitivity.csv"),
  h08_path("10_figures", "H08_near_eye_effects.png"),
  h08_path("10_figures", "H08_chest_effects.png"),
  h08_path("10_figures", "H08_paired_placement_effects.png"),
  h08_path("10_figures", "H08_near_eye_model_adequacy.png"),
  h08_path("10_figures", "H08_gap_common_sample_effects.png")
)
stopifnot(all(file.exists(required_files)))

master <- readr::read_csv(
  h08_path("09_tables", "H08_model_results_master.csv"),
  show_col_types = FALSE
)
families <- readr::read_csv(
  h08_path("09_tables", "H08_family_audit.csv"),
  show_col_types = FALSE
)
samples <- readr::read_csv(
  h08_path("06_model_data", "H08_model_frame_index.csv"),
  show_col_types = FALSE
)
diagnostics <- readr::read_csv(
  h08_path("08_diagnostics", "H08_model_diagnostics.csv"),
  show_col_types = FALSE
)
response_gate <- readr::read_csv(
  h08_path("08_diagnostics", "H08_response_family_gate.csv"),
  show_col_types = FALSE
)
loo <- readr::read_csv(
  h08_path("08_diagnostics", "H08_leave_one_site_out_summary.csv"),
  show_col_types = FALSE
)
gap <- readr::read_csv(
  h08_path("09_tables", "H08_gap_timing_unaware_sensitivity.csv"),
  show_col_types = FALSE
)
photoperiod <- readr::read_csv(
  h08_path("09_tables", "H08_photoperiod_sensitivity.csv"),
  show_col_types = FALSE
)
participant_summary <- readr::read_csv(
  h08_path("09_tables", "H08_participant_summary_sensitivity.csv"),
  show_col_types = FALSE
)
exact_longest <- readr::read_csv(
  h08_path(
    "09_tables",
    "H08_exactly_identified_longest_period_sensitivity.csv"
  ),
  show_col_types = FALSE
)
observed_dose <- readr::read_csv(
  h08_path("09_tables", "H08_observed_dose_sensitivity.csv"),
  show_col_types = FALSE
)

near_id <- "main__glasses__all_available"
chest_id <- "main__chest__all_available"
near <- master |>
  filter(.data$run_id == near_id) |>
  arrange(.data$metric_order)
chest <- master |>
  filter(.data$run_id == chest_id) |>
  arrange(.data$metric_order)

stopifnot(
  nrow(near) == 9L,
  nrow(chest) == 9L,
  nrow(families) == 8L,
  all(families$complete_nine_member_family),
  all(families$independent_recalculation_matches),
  sum(families$adjusted_significant_n) == 0L,
  sum(near$average_adjusted_significant) == 0L,
  sum(near$interaction_adjusted_significant) == 0L,
  sum(chest$average_adjusted_significant) == 0L,
  sum(chest$interaction_adjusted_significant) == 0L
)

near_dose <- near |>
  filter(.data$metric_id == "dose_time_sensitive_corrected_medi")
stopifnot(
  nrow(near_dose) == 1L,
  isTRUE(all.equal(
    near_dose$estimate_practical_per_sd,
    0.84576049319764,
    tolerance = 1e-12
  )),
  isTRUE(all.equal(
    near_dose$conf_low_practical_per_sd,
    0.715965149670316,
    tolerance = 1e-12
  )),
  isTRUE(all.equal(
    near_dose$conf_high_practical_per_sd,
    0.999086075884138,
    tolerance = 1e-12
  )),
  isTRUE(all.equal(
    near_dose$average_p_raw,
    0.0510410963693195,
    tolerance = 1e-12
  )),
  isTRUE(all.equal(
    near_dose$average_p_adjusted,
    0.160039116372493,
    tolerance = 1e-12
  ))
)

main_samples <- samples |>
  filter(.data$run_id %in% c(near_id, chest_id))
near_samples <- main_samples |>
  filter(.data$run_id == near_id)
chest_samples <- main_samples |>
  filter(.data$run_id == chest_id)
stopifnot(
  range(near_samples$participants) == c(139L, 141L),
  range(near_samples$participant_days) == c(655L, 816L),
  all(near_samples$sites == 9L),
  range(chest_samples$participants) == c(153L, 154L),
  range(chest_samples$participant_days) == c(743L, 902L),
  all(chest_samples$sites == 8L)
)

main_diagnostics <- diagnostics |>
  filter(.data$run_id %in% c(near_id, chest_id))
flagged <- main_diagnostics |>
  filter(.data$diagnostic_status != "PASS")
stopifnot(
  nrow(main_diagnostics) == 18L,
  all(main_diagnostics$additive_converged),
  all(main_diagnostics$interaction_converged),
  all(main_diagnostics$additive_positive_definite_hessian),
  all(main_diagnostics$interaction_positive_definite_hessian),
  !any(main_diagnostics$additive_singular),
  !any(main_diagnostics$interaction_singular),
  all(main_diagnostics$additive_fixed_full_rank),
  all(main_diagnostics$interaction_fixed_full_rank),
  nrow(flagged) == 4L,
  setequal(
    unique(flagged$metric_id),
    c("l10_mean_medi", "duration_below_1_sleep_environment")
  ),
  all(
    flagged$observed_zero_n[
      flagged$metric_id == "duration_below_1_sleep_environment"
    ] ==
      4L
  ),
  nrow(response_gate) == 9L,
  sum(response_gate$family_gate_status == "PASS") == 6L,
  sum(
    response_gate$family_gate_status == "RETAIN_WITH_EXPLICIT_LIMITATIONS"
  ) ==
    3L,
  sum(loo$successful_refits) == 153L
)

gap_common <- gap |>
  filter(.data$sample_scenario == "main_gap_common_sample")
gap_available <- gap |>
  filter(.data$sample_scenario == "all_available")
stopifnot(
  nrow(gap_common) == 18L,
  all(gap_common$exact_common_keys),
  all(
    gap_common$stability_classification == "stable within model uncertainty"
  ),
  nrow(gap_available) == 18L,
  sum(gap_available$stability_classification == "precision-sensitive") == 2L,
  all(
    gap_available$placement[
      gap_available$stability_classification == "precision-sensitive"
    ] ==
      "glasses"
  )
)

stopifnot(
  nrow(photoperiod) == 18L,
  nrow(participant_summary) == 18L,
  all(photoperiod$converged),
  all(photoperiod$fixed_full_rank),
  all(participant_summary$converged),
  all(participant_summary$fixed_full_rank),
  nrow(exact_longest) == 4L,
  nrow(observed_dose) == 4L
)

exact_near <- exact_longest |>
  filter(
    .data$placement == "glasses",
    .data$sample_scenario == "all_available"
  )
exact_chest <- exact_longest |>
  filter(
    .data$placement == "chest",
    .data$sample_scenario == "all_available"
  )
observed_near <- observed_dose |>
  filter(
    .data$placement == "glasses",
    .data$sample_scenario == "all_available"
  )
observed_chest <- observed_dose |>
  filter(
    .data$placement == "chest",
    .data$sample_scenario == "all_available"
  )
stopifnot(
  isTRUE(all.equal(
    exact_near$estimate_practical_per_sd,
    0.9580707,
    tolerance = 1e-7
  )),
  isTRUE(all.equal(
    exact_chest$estimate_practical_per_sd,
    0.9390994,
    tolerance = 1e-7
  )),
  isTRUE(all.equal(
    observed_near$estimate_practical_per_sd,
    0.8420895,
    tolerance = 1e-7
  )),
  isTRUE(all.equal(
    observed_chest$estimate_practical_per_sd,
    0.8680240,
    tolerance = 1e-7
  ))
)

stopifnot(
  identical(
    nh_format_p_value(c(0.0009, 0.001, 0.051, 0.160, 1, NA_real_)),
    c("<0.001", "0.001", "0.051", "0.160", "1.000", "—")
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
  "glmmTMB::glmmTMB\\s*\\(",
  "stats::lm\\s*\\(",
  "stats::glm\\s*\\(",
  "boot::boot\\s*\\(",
  "simulate\\s*\\("
)
for (pattern in fit_patterns) {
  stopifnot(
    !grepl(pattern, qmd, perl = TRUE),
    !grepl(pattern, builder, perl = TRUE)
  )
}

expected_formulas <- c(
  "response_value ~ site + (1 | site:Id)",
  "response_value ~ site + VLSQ8_c + (1 | site:Id)",
  "response_value ~ site * VLSQ8_c + (1 | site:Id)",
  "response_value ~ site + photoperiod_c + (1 | site:Id)",
  paste0(
    "response_value ~ site + photoperiod_c + VLSQ8_c + ",
    "(1 | site:Id)"
  ),
  paste0(
    "response_value ~ site * VLSQ8_c + photoperiod_c + ",
    "(1 | site:Id)"
  ),
  "participant_response ~ site",
  "participant_response ~ site + VLSQ8_c",
  "participant_response ~ site * VLSQ8_c"
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
    paste(
      "H8: Duration-, exposure-history-, and level-based metrics are",
      "associated with VLSQ-8 light sensitivity scores."
    ),
    main_text,
    fixed = TRUE
  ),
  grepl("Results in brief", main_text, fixed = TRUE),
  !grepl("Answer in brief", main_text, fixed = TRUE),
  grepl("ratio 0.846", main_text, fixed = TRUE),
  grepl("0.716–0.999", main_text, fixed = TRUE),
  grepl("raw p = 0.051", main_text, fixed = TRUE),
  grepl("BH-adjusted p = 0.160", main_text, fixed = TRUE),
  grepl("gap-timing-unaware dataset", main_text_lower, fixed = TRUE),
  grepl("50%-per-hour", main_text_lower, fixed = TRUE),
  grepl("80%-per-day", main_text_lower, fixed = TRUE),
  grepl("time-sensitive primary metric dataset", main_text_lower, fixed = TRUE),
  grepl("153 planned leave-one-site-out refits", main_text_lower, fixed = TRUE),
  grepl("not an equivalence test", main_text_lower, fixed = TRUE),
  grepl(
    "does it support physiological or health-effect claims",
    main_text_lower,
    fixed = TRUE
  ),
  !grepl("\\bV0\\b", main_text, perl = TRUE),
  !grepl("\\bStage [1234]\\b", main_text, perl = TRUE),
  !grepl("\\btemperature\\b", main_text_lower, perl = TRUE),
  !grepl("\\bbout\\b", main_text_lower, perl = TRUE)
)
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
callout_title <- xml2::xml_find_first(
  callout,
  ".//*[contains(concat(' ', normalize-space(@class), ' '), ' callout-title-container ')]"
)
stopifnot(
  !inherits(hypothesis_section, "xml_missing"),
  !inherits(callout, "xml_missing"),
  xml2::xml_attr(callout, "title") == "Results in brief",
  grepl("Results in brief", xml2::xml_text(callout_title), fixed = TRUE),
  identical(xml2::xml_parent(callout), hypothesis_section),
  xml2::xml_path(tail(xml2::xml_children(hypothesis_section), 1L)) ==
    xml2::xml_path(callout)
)
callout_text <- tolower(xml2::xml_text(callout))
stopifnot(
  grepl("bh-adjusted", callout_text, fixed = TRUE),
  grepl("95% ci", callout_text, fixed = TRUE),
  grepl("chest", callout_text, fixed = TRUE),
  grepl("sensitivity", callout_text, fixed = TRUE)
)

expected_tables <- c(
  "tbl-h08-metrics",
  "tbl-h08-formulas",
  "tbl-h08-families",
  "tbl-h08-primary-samples",
  "tbl-h08-near-eye-results",
  "tbl-h08-near-eye-predictions",
  "tbl-h08-chest-results",
  "tbl-h08-interactions",
  "tbl-h08-paired-placement",
  "tbl-h08-response-gate",
  "tbl-h08-flagged-diagnostics",
  "tbl-h08-site-influence",
  "tbl-h08-gap-common-sample",
  "tbl-h08-photoperiod-participant-summary",
  "tbl-h08-metric-definition-sensitivities"
)
expected_figures <- c(
  "fig-h08-near-eye-effects",
  "fig-h08-chest-effects",
  "fig-h08-paired-placement",
  "fig-h08-model-adequacy",
  "fig-h08-gap-common-sample"
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
stopifnot(length(gt_tables) == 14L)
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
stopifnot(all(data_rows <= 18L), all(header_columns <= 7L))

figure_predicate <- paste0("@id='", expected_figures, "'", collapse = " or ")
images <- xml2::xml_find_all(
  main,
  paste0(".//*[", figure_predicate, "]//img")
)
stopifnot(length(images) == length(expected_figures))
image_sources <- xml2::xml_attr(images, "src")
image_alt <- xml2::xml_attr(images, "alt")
stopifnot(all(nzchar(image_sources)), all(nzchar(image_alt)))

expected_source_links <- c(
  "H08_model_frame_index.csv",
  "H08_near_eye_effects_data.csv",
  "H08_model_results_master.csv",
  "H08_chest_effects_data.csv",
  "H08_site_specific_slopes.csv",
  "H08_paired_placement_effects_data.csv",
  "H08_model_diagnostics.csv",
  "H08_near_eye_model_adequacy_data.csv",
  "H08_participant_influence_screen.csv",
  "H08_gap_common_sample_effects_data.csv",
  "H08_gap_timing_unaware_sensitivity.csv",
  "H08_photoperiod_sensitivity.csv",
  "H08_participant_summary_sensitivity.csv",
  "H08_exactly_identified_longest_period_sensitivity.csv",
  "H08_observed_dose_sensitivity.csv",
  "H08_figure_manifest.csv"
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
  "notebooks/hypotheses/H08.qmd",
  "_build/nathealth/notebooks/hypotheses/H08.html",
  "scripts/hypotheses/H08/h08_contract.R",
  "scripts/hypotheses/H08/h08_modeling.R",
  "scripts/hypotheses/H08/run_h08_stage2.R",
  "scripts/hypotheses/H08/build_h08_stage3_manifest.R",
  "tests/hypotheses/H08/test_h08_stage2.R",
  "tests/hypotheses/H08/test_h08_stage3_reader_report.R",
  "audit/hypotheses/H08/01_audit_and_plan.qmd",
  "audit/hypotheses/H08/02_implementation_and_v0_comparison.qmd",
  "audit/handoffs/H08_worker_handoff.md",
  "artifacts/09_tables/H08/H08_model_results_master.csv",
  "artifacts/10_figures/H08/H08_near_eye_effects.png",
  "artifacts/10_figures/H08/H08_chest_effects.png",
  "artifacts/11_source_data/H08/H08_near_eye_effects_data.csv",
  "artifacts/12_manifests/H08/H08_stage2_artifacts.csv"
)
stopifnot(
  identical(names(manifest), expected_manifest_columns),
  !anyDuplicated(manifest$path),
  all(expected_manifest_paths %in% manifest$path),
  !"artifacts/12_manifests/H08/H08_stage3_artifacts.csv" %in%
    manifest$path,
  !"audit/hypotheses/H08/H08_analysis_preparation.qmd" %in%
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
  "H08 reader-report tests passed: nine near-eye and nine chest metrics, ",
  "zero multiplicity-retained associations, 14 compact tables, five ",
  "accessible figures, and all accepted diagnostic qualifications"
)
