# Standalone structural, source-data, display, and provenance checks for the
# H05 analysis-preparation companion. These checks do not fit or refit models.

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

verification <- verify_hypothesis_preparation_companion(
  root = root,
  hypothesis_id = "H05",
  min_figures = 3L,
  min_gt_tables = 17L,
  extra_forbidden_calls = c(
    "h05_fit_model",
    "h05_fit_bundle",
    "h05_diagnostic_summary",
    "h05_random_site_summary",
    "h05_leave_one_site_out",
    "h01_residual_diagnostics",
    "h01_diagnostic_plot_data"
  )
)

paths <- preparation_companion_paths(root, "H05")
qmd_lines <- readLines(paths$qmd, warn = FALSE, encoding = "UTF-8")
qmd <- paste(qmd_lines, collapse = "\n")

stopifnot(
  grepl("flowchart TD", qmd, fixed = TRUE),
  grepl("../../../notebooks/hypotheses/H05.html", qmd, fixed = TRUE),
  grepl("gap-timing-unaware dataset", qmd, fixed = TRUE),
  grepl("at least 50% valid", qmd, fixed = TRUE),
  grepl("at least 80% valid", qmd, fixed = TRUE),
  grepl("time-sensitive primary metric", qmd, fixed = TRUE),
  grepl("arithmetic mean of viable one-minute", qmd, fixed = TRUE),
  grepl("complete 1,440 local wall-clock minutes", qmd, fixed = TRUE),
  grepl("not a ratio of daily integrals", qmd, fixed = TRUE),
  grepl("H05_mder_metric010_upper_tail_summary.csv", qmd, fixed = TRUE),
  grepl("H05_mder_metric010_influence_refits.csv", qmd, fixed = TRUE),
  grepl("H05_mder_metric010_gap_influence_refits.csv", qmd, fixed = TRUE),
  grepl(
    "H05_mder_metric010_gap_paired_placement_comparison.csv",
    qmd,
    fixed = TRUE
  ),
  grepl("H05_metric010_reconciliation.csv", qmd, fixed = TRUE),
  grepl("H05_metric010_gap_reseal_reconciliation.csv", qmd, fixed = TRUE),
  grepl("l10_numerical_zero_normalization.md", qmd, fixed = TRUE),
  grepl("H05_metric011_primary_l10_frame_audit.csv", qmd, fixed = TRUE),
  grepl("H05_metric011_bh_change_audit.csv", qmd, fixed = TRUE),
  grepl("H05_metric011_reconciliation.csv", qmd, fixed = TRUE),
  grepl("H05_metric011_artifact_update_manifest.csv", qmd, fixed = TRUE),
  grepl("reseal_h05_l10_metric011.R", qmd, fixed = TRUE),
  grepl("build_h05_metric011_displays.R", qmd, fixed = TRUE),
  grepl("unfit for H05 inference", qmd, fixed = TRUE),
  grepl(
    "another hypothesis that uses a different response variable",
    qmd,
    fixed = TRUE
  ),
  grepl("Exact evaluated Wilkinson formulas", qmd, fixed = TRUE),
  grepl("complete 68-value vector", qmd, fixed = TRUE),
  grepl("Zero of 68 primary associations", qmd, fixed = TRUE),
  grepl("121 of 136 fits passed", qmd, fixed = TRUE),
  grepl("15 were unstable", qmd, fixed = TRUE),
  grepl("longest **period**", qmd, fixed = TRUE),
  grepl("Benjamini–Hochberg cannot retain", qmd, fixed = TRUE),
  grepl("For one unchanged vector of raw p-values", qmd, fixed = TRUE),
  grepl("theme_minimal(base_size = 12)", qmd, fixed = TRUE),
  grepl("::: {.callout-note", qmd, fixed = TRUE),
  !grepl("::: {.callout-important", qmd, fixed = TRUE),
  !grepl("::: {.callout-warning", qmd, fixed = TRUE)
)

document <- xml2::read_html(paths$html)
main <- xml2::xml_find_first(
  document,
  "//main[@id='quarto-document-content']"
)
stopifnot(!inherits(main, "xml_missing"))
main_text <- xml2::xml_text(main)

stopifnot(
  grepl("H05 analysis preparation and provenance", main_text, fixed = TRUE),
  grepl("184 unique", main_text, fixed = TRUE),
  grepl("136 frames", main_text, fixed = TRUE),
  grepl("544", main_text, fixed = TRUE),
  grepl("121 of 136", main_text, fixed = TRUE),
  grepl("15 were unstable", main_text, fixed = TRUE),
  grepl("Zero of 68", main_text, fixed = TRUE),
  grepl("702 near-eye participant-days", main_text, fixed = TRUE),
  grepl("732 chest participant-days", main_text, fixed = TRUE),
  grepl(
    "All 44 day- and participant-deletion refits passed",
    main_text,
    fixed = TRUE
  ),
  grepl("687 near-eye participant-days", main_text, fixed = TRUE),
  grepl("723 chest participant-days", main_text, fixed = TRUE),
  grepl("478 days from 107 participants", main_text, fixed = TRUE),
  grepl("All 44 gap deletion refits passed", main_text, fixed = TRUE),
  grepl("27 non-MDER adjusted-p changes", main_text, fixed = TRUE),
  grepl("26 rank changes", main_text, fixed = TRUE),
  grepl("All 20 reconciliation checks pass", main_text, fixed = TRUE),
  grepl("Numerical-zero normalization", main_text, fixed = TRUE),
  grepl(
    "three near-eye and five chest participant-days",
    main_text,
    fixed = TRUE
  ),
  grepl("did not alter any fitted sample", main_text, fixed = TRUE),
  grepl("Sixteen factor–model cells were refreshed", main_text, fixed = TRUE),
  grepl("Seven inferential raw p-values", main_text, fixed = TRUE),
  grepl("no family rank changed", main_text, fixed = TRUE),
  grepl("zero gap L10 and zero non-L10 refits", main_text, fixed = TRUE),
  grepl(
    "All 22 frozen-scope reconciliation checks pass",
    main_text,
    fixed = TRUE
  ),
  grepl("132 participants", main_text, fixed = TRUE),
  grepl("500 participant-days", main_text, fixed = TRUE),
  grepl("9 sites", main_text, fixed = TRUE),
  grepl("gap-timing-unaware dataset", main_text, fixed = TRUE),
  grepl("unfit for H05 inference", main_text, fixed = TRUE),
  grepl("different response variable", main_text, fixed = TRUE),
  !grepl("Execution halted", main_text, fixed = TRUE)
)

xml2::xml_remove(xml2::xml_find_all(
  main,
  ".//div[contains(concat(' ', normalize-space(@class), ' '), ' sourceCode ')]"
))
reader_text <- xml2::xml_text(main)
stopifnot(
  !grepl("manuscript-prepared", reader_text, ignore.case = TRUE),
  !grepl("alternative manuscript", reader_text, ignore.case = TRUE),
  !grepl("V0", reader_text, fixed = TRUE),
  !grepl("longest bout", reader_text, ignore.case = TRUE)
)

formula_text <- c(
  "response_value ~ site + leba_centered + (1 | participant_key)",
  "response_value ~ site + (1 | participant_key)",
  "response_value ~ site + leba_centered",
  "response_value ~ site",
  "response_value ~ leba_centered + (1 | site) + (1 | participant_key)",
  "response_value ~ leba_centered + (1 | site)"
)
stopifnot(all(vapply(
  formula_text,
  grepl,
  logical(1),
  x = main_text,
  fixed = TRUE
)))

expected_figures <- c(
  "fig-h05-prep-leba-distribution",
  "fig-h05-prep-sample-support",
  "fig-h05-prep-site-range"
)
figure_widths <- c(
  `fig-h05-prep-leba-distribution` = "960",
  `fig-h05-prep-sample-support` = "1056",
  `fig-h05-prep-site-range` = "1056"
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
    identical(xml2::xml_attr(image, "width"), unname(figure_widths[[id]]))
  )
}

source_data_contract <- c(
  "artifacts/11_source_data/H05/H05_preparation_sample_support.csv" = 34L,
  "artifacts/11_source_data/H05/H05_preparation_leba_score_distribution.csv" = 72L,
  "artifacts/11_source_data/H05/H05_preparation_site_support.csv" = 1122L,
  "artifacts/11_source_data/H05/H05_preparation_site_support_summary.csv" = 17L
)
for (relative_path in names(source_data_contract)) {
  data <- readr::read_csv(
    file.path(root, relative_path),
    show_col_types = FALSE
  )
  stopifnot(nrow(data) == unname(source_data_contract[[relative_path]]))
}

sample_support <- readr::read_csv(
  file.path(
    root,
    "artifacts/11_source_data/H05/H05_preparation_sample_support.csv"
  ),
  show_col_types = FALSE
)
mder_support <- sample_support[
  sample_support$metric_id == "mder_mean_of_viable_ratios",
  ,
  drop = FALSE
]
mder_upper_tail <- readr::read_csv(
  file.path(
    root,
    paste0(
      "artifacts/08_diagnostics/H05/",
      "H05_mder_metric010_upper_tail_summary.csv"
    )
  ),
  show_col_types = FALSE
)
mder_influence <- readr::read_csv(
  file.path(
    root,
    paste0(
      "artifacts/08_diagnostics/H05/",
      "H05_mder_metric010_influence_refits.csv"
    )
  ),
  show_col_types = FALSE
)
mder_gap_influence <- readr::read_csv(
  file.path(
    root,
    paste0(
      "artifacts/08_diagnostics/H05/",
      "H05_mder_metric010_gap_influence_refits.csv"
    )
  ),
  show_col_types = FALSE
)
mder_gap_paired <- readr::read_csv(
  file.path(
    root,
    paste0(
      "artifacts/09_tables/H05/",
      "H05_mder_metric010_gap_paired_placement_comparison.csv"
    )
  ),
  show_col_types = FALSE
)
mder_reconciliation <- readr::read_csv(
  file.path(
    root,
    "artifacts/12_manifests/H05/H05_metric010_reconciliation.csv"
  ),
  show_col_types = FALSE
)
mder_gap_reconciliation <- readr::read_csv(
  file.path(
    root,
    paste0(
      "artifacts/12_manifests/H05/",
      "H05_metric010_gap_reseal_reconciliation.csv"
    )
  ),
  show_col_types = FALSE
)
l10_frame_audit <- readr::read_csv(
  file.path(
    root,
    paste0(
      "artifacts/12_manifests/H05/",
      "H05_metric011_primary_l10_frame_audit.csv"
    )
  ),
  show_col_types = FALSE
)
l10_bh_audit <- readr::read_csv(
  file.path(
    root,
    "artifacts/12_manifests/H05/H05_metric011_bh_change_audit.csv"
  ),
  show_col_types = FALSE
)
l10_result_change <- readr::read_csv(
  file.path(
    root,
    paste0(
      "artifacts/12_manifests/H05/",
      "H05_metric011_l10_result_change_audit.csv"
    )
  ),
  show_col_types = FALSE
)
l10_input_cells <- readr::read_csv(
  file.path(
    root,
    "artifacts/12_manifests/H05/H05_metric011_input_cell_audit.csv"
  ),
  show_col_types = FALSE
)
l10_reconciliation <- readr::read_csv(
  file.path(
    root,
    "artifacts/12_manifests/H05/H05_metric011_reconciliation.csv"
  ),
  show_col_types = FALSE
)
stopifnot(
  nrow(mder_support) == 2L,
  mder_support$participant_days[mder_support$placement == "glasses"] == 702L,
  mder_support$participants[mder_support$placement == "glasses"] == 137L,
  mder_support$participant_days[mder_support$placement == "chest"] == 732L,
  mder_support$participants[mder_support$placement == "chest"] == 152L,
  nrow(mder_upper_tail) == 8L,
  nrow(mder_influence) == 44L,
  all(mder_influence$refit_status == "PASS"),
  sum(mder_influence$sensitivity_interval_contains_zero) == 40L,
  all(
    mder_influence$sensitivity_interval_contains_zero[
      mder_influence$run_id == "main__chest__all_available"
    ]
  ),
  all(
    mder_upper_tail$observations[
      mder_upper_tail$run_id ==
        "manuscript_prepared_data__glasses__all_available"
    ] ==
      687L
  ),
  all(
    mder_upper_tail$observations[
      mder_upper_tail$run_id == "manuscript_prepared_data__chest__all_available"
    ] ==
      723L
  ),
  nrow(mder_gap_influence) == 44L,
  all(mder_gap_influence$refit_status == "PASS"),
  sum(mder_gap_influence$sensitivity_interval_contains_zero) == 40L,
  nrow(mder_gap_paired) == 4L,
  all(mder_gap_paired$exact_sample_match),
  all(mder_gap_paired$participant_days__glasses == 478L),
  all(mder_gap_paired$participants__glasses == 107L),
  all(mder_gap_paired$sign_concordant),
  all(mder_gap_paired$component_intervals_overlap),
  nrow(mder_reconciliation) == 20L,
  all(mder_reconciliation$invariant_verified),
  nrow(mder_gap_reconciliation) == 16L,
  all(mder_gap_reconciliation$invariant_verified),
  nrow(l10_frame_audit) == 4L,
  all(l10_frame_audit$non_value_fields_identical),
  all(l10_frame_audit$changed_keys_verified),
  nrow(l10_input_cells) == 16L,
  nrow(dplyr::distinct(
    l10_input_cells,
    .data$position,
    .data$participant_key,
    .data$local_date
  )) ==
    8L,
  all(l10_input_cells$new_value_lx == 0),
  all(l10_input_cells$current_value_lx == 0),
  nrow(l10_result_change) == 16L,
  max(abs(l10_result_change$estimate_change_per_point)) < 4e-12,
  !any(l10_result_change$bh_retained_after, na.rm = TRUE),
  nrow(l10_bh_audit) == 204L,
  sum(l10_bh_audit$raw_p_changed) == 7L,
  sum(l10_bh_audit$adjusted_p_changed) == 2L,
  sum(l10_bh_audit$family_rank_changed) == 0L,
  nrow(l10_reconciliation) == 22L,
  all(l10_reconciliation$invariant_verified)
)

factor_registry <- readr::read_csv(
  file.path(root, "artifacts/06_model_data/H05/H05_factor_registry.csv"),
  show_col_types = FALSE
)
frame_index <- readr::read_csv(
  file.path(root, "artifacts/06_model_data/H05/H05_model_frame_index.csv"),
  show_col_types = FALSE
)
family_audit <- readr::read_csv(
  file.path(root, "artifacts/09_tables/H05/H05_family_audit.csv"),
  show_col_types = FALSE
)
stopifnot(
  nrow(factor_registry) == 4L,
  nrow(frame_index) == 544L,
  !anyDuplicated(frame_index[c("run_id", "metric_id", "factor_id")]),
  nrow(family_audit) == 3L,
  all(family_audit$planned_tests == 68L),
  all(family_audit$observed_tests == 68L),
  all(family_audit$estimable_adjusted_tests == 68L),
  all(family_audit$passes_bh_0_05 == 0L),
  all(family_audit$vector_bh_verified)
)

qa_path <- file.path(
  root,
  "artifacts/12_manifests/H05/H05_figure_readability_qa.csv"
)
qa <- readr::read_csv(qa_path, show_col_types = FALSE)
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
proof_path <- file.path(
  root,
  "artifacts/12_manifests/H05/H05_figure_A4_proofs.pdf"
)
qa_record_path <- file.path(
  root,
  "audit/hypotheses/H05/H05_figure_readability_qa.md"
)
stopifnot(
  nrow(qa) == 10L,
  !anyDuplicated(qa$figure_id),
  all(qa$status == "PASS"),
  all(qa$overall_status == "PASS"),
  all(qa$visual_status == "PASS"),
  all(qa$typography_status == "PASS_BY_CALCULATION"),
  all(qa$reporting_rule == "REPORT-011; REPORT-013 assessed not applicable"),
  all(qa$symlog_applicability == "NOT_APPLICABLE"),
  all(qa$intended_display_width_mm >= 149.5),
  all(qa$intended_display_width_mm <= 170),
  all(qa$display_reduction_factor > 0),
  all(qa$display_reduction_factor <= 1),
  all(qa$effective_final_essential_text_pt >= 5),
  all(
    is.na(qa$effective_final_central_text_pt) |
      qa$effective_final_central_text_pt >= 7
  ),
  identical(as.integer(qa$a4_proof_page), seq_len(10L)),
  all(qa$a4_page_width_mm == 210),
  all(qa$a4_page_height_mm == 297),
  all(qa$a4_side_margin_mm >= 20),
  all(vapply(qa[qa_checks], function(value) all(value == "PASS"), logical(1))),
  file.exists(proof_path),
  file.info(proof_path)$size > 0,
  file.exists(qa_record_path)
)

stopifnot(
  verification$figures >= 3L,
  verification$gt_tables >= 17L,
  verification$manifest_identities >= 45L,
  isTRUE(verification$source_copy_identical)
)

message(
  "H05 preparation companion verified: ",
  verification$figures,
  " figures, ",
  verification$gt_tables,
  " gt tables, ",
  verification$manifest_identities,
  " manifest identities, and byte-identical source copy"
)
