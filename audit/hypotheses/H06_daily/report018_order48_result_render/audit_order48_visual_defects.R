#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE)

stopifnot(identical(as.character(getRversion()), "4.6.1"))

suppressPackageStartupMessages({
  library(digest)
  library(dplyr)
  library(jsonlite)
  library(readr)
  library(rvest)
  library(tibble)
  library(xml2)
})

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
setwd(root)

evidence_dir <- file.path(
  root,
  "audit/hypotheses/H06_daily/report018_order48_result_render"
)
html_path <- file.path(
  root,
  "_build/nathealth/notebooks/hypotheses/H06_daily.html"
)
qmd_path <- file.path(root, "notebooks/hypotheses/H06_daily.qmd")
placement_path <- file.path(
  root,
  "artifacts/11_source_data/H06_daily/H06_daily_stage3_placement_results.csv"
)

stopifnot(
  dir.exists(evidence_dir),
  file.exists(html_path),
  file.exists(qmd_path),
  file.exists(placement_path)
)

sha256_file <- function(path) {
  digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
}

hash_text <- function(value) {
  digest(enc2utf8(value), algo = "sha256", serialize = FALSE)
}

clean_text <- function(node) {
  value <- html_text2(node)
  value <- gsub("[[:space:]]+", " ", value)
  trimws(value)
}

write_evidence <- function(data, filename) {
  write_csv(data, file.path(evidence_dir, filename), na = "")
}

# Predictor-specific tab content

document <- read_html(html_path)
tab_contract <- tribble(
  ~table_id,
  ~expected_predictor_id,
  ~expected_caption_fragment,
  "tbl-h06-daily-placement-work-free",
  "work_free_day",
  "Free versus Work day",
  "tbl-h06-daily-placement-activity",
  "activity_status",
  "Active versus Sedentary status",
  "tbl-h06-daily-placement-sleep",
  "previous_sleep_duration_centered_h",
  "additional hour of previous-night sleep"
)

placement <- read_csv(placement_path, show_col_types = FALSE)
stopifnot(
  nrow(placement) == 180L,
  n_distinct(placement$predictor_id) == 3L,
  n_distinct(placement$scenario_label) == 4L,
  n_distinct(placement$metric_slot) == 15L
)

primary_mean <- placement |>
  filter(
    .data$metric_slot == 1L,
    .data$scenario_label == "Primary near eye, all available"
  ) |>
  select("predictor_id", "estimate") |>
  arrange(match(
    .data$predictor_id,
    c(
      "work_free_day",
      "activity_status",
      "previous_sleep_duration_centered_h"
    )
  ))
stopifnot(nrow(primary_mean) == 3L)
primary_mean_tokens <- sprintf("%.2f", primary_mean$estimate)

tab_rows <- lapply(seq_len(nrow(tab_contract)), function(index) {
  endpoint <- html_element(
    document,
    paste0("#", tab_contract$table_id[[index]])
  )
  body <- html_element(endpoint, "tbody")
  rows <- html_elements(body, "tr")
  caption <- clean_text(html_element(endpoint, "figcaption"))
  body_text <- clean_text(body)
  first_metric_row <- clean_text(rows[[2L]])
  contains_all_predictor_values <- all(vapply(
    primary_mean_tokens,
    grepl,
    logical(1),
    x = first_metric_row,
    fixed = TRUE
  ))
  tibble(
    table_id = tab_contract$table_id[[index]],
    expected_predictor_id = tab_contract$expected_predictor_id[[index]],
    caption = caption,
    caption_matches_expected = grepl(
      tab_contract$expected_caption_fragment[[index]],
      caption,
      fixed = TRUE
    ),
    body_text_sha256 = hash_text(body_text),
    first_metric_row = first_metric_row,
    contains_all_three_primary_mean_estimates = contains_all_predictor_values,
    predictor_specific_body = !contains_all_predictor_values,
    status = ifelse(
      contains_all_predictor_values,
      "FAIL_REPEATED_THREE_PREDICTOR_CONTENT",
      "PASS"
    )
  )
})
tab_audit <- bind_rows(tab_rows)

qmd_text <- paste(
  readLines(qmd_path, warn = FALSE, encoding = "UTF-8"),
  collapse = "\n"
)
filter_expression <- "filter(.data$predictor_id == predictor_id)"
tab_audit <- tab_audit |>
  mutate(
    all_three_body_hashes_identical = n_distinct(.data$body_text_sha256) == 1L,
    source_filter_expression = filter_expression,
    source_filter_uses_data_mask_collision = grepl(
      filter_expression,
      qmd_text,
      fixed = TRUE
    ),
    prospective_filter_expression = "filter(.data$predictor_id == .env$predictor_id)"
  )

stopifnot(
  all(tab_audit$caption_matches_expected),
  all(tab_audit$contains_all_three_primary_mean_estimates),
  all(tab_audit$all_three_body_hashes_identical),
  all(tab_audit$source_filter_uses_data_mask_collision),
  all(tab_audit$status == "FAIL_REPEATED_THREE_PREDICTOR_CONTENT")
)
write_evidence(tab_audit, "placement_tab_content_audit.csv")

placement_cardinality <- placement |>
  count(
    .data$predictor_id,
    .data$scenario_label,
    name = "source_rows"
  ) |>
  mutate(
    expected_rows = 15L,
    one_row_per_metric = .data$source_rows == .data$expected_rows,
    status = ifelse(.data$one_row_per_metric, "PASS", "FAIL")
  )
stopifnot(nrow(placement_cardinality) == 12L)
write_evidence(
  placement_cardinality,
  "placement_source_cardinality_audit.csv"
)

# Figure typography at the required final sizes

narrow_metrics <- fromJSON(
  file.path(evidence_dir, "visual_708x1000_measurements_stable.json"),
  simplifyVector = FALSE
)
wide_metrics <- fromJSON(
  file.path(evidence_dir, "visual_1440x1000_measurements_stable.json"),
  simplifyVector = FALSE
)
narrow_widths <- setNames(
  vapply(
    narrow_metrics$figures,
    function(item) item$imageRect$width,
    numeric(1)
  ),
  vapply(narrow_metrics$figures, function(item) item$id, character(1))
)
wide_widths <- setNames(
  vapply(wide_metrics$figures, function(item) item$imageRect$width, numeric(1)),
  vapply(wide_metrics$figures, function(item) item$id, character(1))
)

figure_contract <- tribble(
  ~figure_id,
  ~figure_file,
  ~source_script,
  ~design_width_in,
  ~smallest_essential_nominal_text_pt,
  ~smallest_text_role,
  "fig-h06-daily-primary-ratio",
  "H06_daily_non_l10_production_primary_ratio_effects.png",
  "scripts/hypotheses/H06_daily/make_h06_daily_non_l10_production_figures.R",
  12,
  9,
  "metric axis labels",
  "fig-h06-daily-primary-absolute",
  "H06_daily_non_l10_production_primary_absolute_effects.png",
  "scripts/hypotheses/H06_daily/make_h06_daily_non_l10_production_figures.R",
  12,
  9,
  "metric axis labels",
  "fig-h06-daily-fdr-overview",
  "H06_daily_stage3_fdr_overview.png",
  "scripts/hypotheses/H06_daily/build_h06_daily_stage3_reader.R",
  11.8,
  10.5,
  "metric and legend labels",
  "fig-h06-daily-primary-site-deviations",
  "H06_daily_stage3_primary_site_deviations.png",
  "scripts/hypotheses/H06_daily/build_h06_daily_stage3_revision_inputs.R",
  260 / 25.4,
  8.2,
  "site and tick labels",
  "fig-h06-daily-temporal-gamm",
  "H06_daily_temporal_h02_primary_context_functions.png",
  "scripts/hypotheses/H06_daily/build_h06_daily_temporal_h02_production_figures.R",
  10.5,
  12.5,
  "axis, subtitle, and legend labels"
)

display_width_170_in <- 170 / 25.4
figure_typography <- figure_contract |>
  mutate(
    durable_figure = file.path(
      "artifacts/10_figures/H06_daily",
      .data$figure_file
    ),
    durable_figure_sha256 = vapply(
      file.path(root, .data$durable_figure),
      sha256_file,
      character(1)
    ),
    source_script_sha256 = vapply(
      file.path(root, .data$source_script),
      sha256_file,
      character(1)
    ),
    narrow_display_width_px = unname(narrow_widths[.data$figure_id]),
    desktop_display_width_px = unname(wide_widths[.data$figure_id]),
    intended_print_width_mm = 170,
    print_reduction_factor = display_width_170_in / .data$design_width_in,
    narrow_reduction_factor = (.data$narrow_display_width_px / 96) /
      .data$design_width_in,
    desktop_reduction_factor = (.data$desktop_display_width_px / 96) /
      .data$design_width_in,
    effective_text_pt_at_170mm = .data$smallest_essential_nominal_text_pt *
      .data$print_reduction_factor,
    effective_text_pt_at_708px_view = .data$smallest_essential_nominal_text_pt *
      .data$narrow_reduction_factor,
    effective_text_pt_at_1440px_view = .data$smallest_essential_nominal_text_pt *
      .data$desktop_reduction_factor,
    required_minimum_pt = 7,
    print_170mm_status = ifelse(
      .data$effective_text_pt_at_170mm >= .data$required_minimum_pt,
      "PASS",
      "FAIL_BELOW_7_PT"
    ),
    narrow_708px_status = ifelse(
      .data$effective_text_pt_at_708px_view >= .data$required_minimum_pt,
      "PASS",
      "FAIL_BELOW_7_PT"
    ),
    desktop_1440px_status = ifelse(
      .data$effective_text_pt_at_1440px_view >= .data$required_minimum_pt,
      "PASS",
      "FAIL_BELOW_7_PT"
    ),
    overall_status = ifelse(
      .data$print_170mm_status == "PASS" &
        .data$narrow_708px_status == "PASS" &
        .data$desktop_1440px_status == "PASS",
      "PASS",
      "FAIL_FINAL_SIZE_TYPOGRAPHY"
    )
  )

stopifnot(
  nrow(figure_typography) == 5L,
  all(figure_typography$narrow_display_width_px == 642),
  all(figure_typography$desktop_display_width_px == 923),
  sum(figure_typography$overall_status == "FAIL_FINAL_SIZE_TYPOGRAPHY") == 4L,
  figure_typography$overall_status[
    figure_typography$figure_id == "fig-h06-daily-temporal-gamm"
  ] ==
    "PASS"
)
write_evidence(
  figure_typography,
  "figure_final_size_typography_audit.csv"
)

defects <- tribble(
  ~defect_id,
  ~scope,
  ~severity,
  ~evidence,
  ~required_disposition,
  "ORDER48-DEFECT-001",
  "Tables 5, 6, and 7",
  "FAIL_CLOSED_CONTENT_LABEL_MISMATCH",
  paste(
    "All three predictor-tab table bodies are text-identical and every mean",
    "melEDI cell contains the Work/Free, activity, and sleep estimates.",
    "The predictor-specific captions therefore do not match their bodies."
  ),
  paste(
    "At a later authorized source repair, make the function argument explicit",
    "inside dplyr::filter with .env$predictor_id, rebuild the three tables from",
    "the frozen placement CSV, then render and re-audit."
  ),
  "ORDER48-DEFECT-002",
  "Figures 1 through 4",
  "FAIL_CLOSED_BELOW_7_PT",
  paste(
    "Four figures have essential final-size text below 7 pt at both the",
    "642-pixel narrow display and the controlling 170-mm print width. The",
    "effective minima are 5.02, 5.02, 5.95, and 5.36 pt. Figure 5 is 7.97 pt."
  ),
  paste(
    "At a later authorized display-only repair, rebuild the four figures from",
    "their frozen source data with typography and canvas geometry that meet",
    "the 7-pt floor at 170 mm, without changing scientific values or marks."
  )
)
write_evidence(defects, "visual_fail_closed_defect_summary.csv")

status <- tibble(
  order = "REPORT-018 order 48",
  target = "notebooks/hypotheses/H06_daily.qmd",
  source_sha256 = sha256_file(qmd_path),
  html_sha256 = sha256_file(html_path),
  static_and_semantic_status = "PASS",
  visual_status = "FAIL_CLOSED",
  defects = nrow(defects),
  patch_or_rerender_performed = FALSE,
  disposition = "RETURN_CONSOLIDATED_DEFECT_LIST"
)
write_evidence(status, "order48_fail_closed_status.csv")

cat(sprintf(
  paste0(
    "ORDER48_VISUAL=FAIL_CLOSED defects=%d repeated_tabs=%d ",
    "sub7_figures=%d temporal_pass=%d\n"
  ),
  nrow(defects),
  nrow(tab_audit),
  sum(figure_typography$overall_status == "FAIL_FINAL_SIZE_TYPOGRAPHY"),
  sum(figure_typography$overall_status == "PASS")
))
