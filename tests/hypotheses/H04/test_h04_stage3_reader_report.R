#!/usr/bin/env Rscript

# Verify the standalone H04 reader report and its linked accepted artifacts.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
project_library <- file.path(
  root,
  "renv/library/macos/R-4.6/aarch64-apple-darwin23"
)
.libPaths(c(project_library, .libPaths()))

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop(
    "H04 reader-report tests require R 4.6.1; found ",
    as.character(getRversion()),
    call. = FALSE
  )
}

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(xml2)
})

source(file.path(root, "scripts/pipeline/paths_io.R"))
source(file.path(root, "scripts/hypotheses/H04/h04_contract.R"))
source(file.path(root, "scripts/hypotheses/H04/h04_stage1_support.R"))
source(file.path(root, "scripts/hypotheses/H04/h04_reporting.R"))
source(file.path(root, "scripts/hypotheses/H04/h04_temporal.R"))

artifact <- function(...) file.path(root, "artifacts", ...)
read_h04 <- function(...) {
  readr::read_csv(artifact(...), show_col_types = FALSE, na = "")
}

qmd_path <- file.path(root, "notebooks/hypotheses/H04.qmd")
html_path <- file.path(
  root,
  "_build/nathealth/notebooks/hypotheses/H04.html"
)
figure_names <- c(
  "H04_reader_heterogeneity_category_estimates.png",
  "H04_site_activity_estimates.png",
  "H04_primary_diagnostics.png",
  "H04_paired_placement_comparison.png",
  "H04_temporal_near_eye.png",
  "H04_temporal_chest.png",
  "H04_temporal_diagnostics.png"
)
source_data_names <- c(
  "H04_reader_heterogeneity_category_figure.csv",
  "H04_site_activity_figure.csv",
  "H04_paired_placement_figure.csv",
  "H04_reader_primary_residual_points.csv",
  "H04_reader_primary_residual_bins.csv",
  "H04_reader_primary_zero_calibration.csv",
  "H04_reader_temporal_near_eye_curves.csv",
  "H04_reader_temporal_near_eye_ratios.csv",
  "H04_reader_temporal_near_eye_global.csv",
  "H04_reader_temporal_near_eye_support.csv",
  "H04_reader_temporal_chest_curves.csv",
  "H04_reader_temporal_chest_ratios.csv",
  "H04_reader_temporal_chest_global.csv",
  "H04_reader_temporal_chest_support.csv",
  "H04_reader_temporal_residual_points.csv",
  "H04_reader_temporal_residual_bins.csv",
  "H04_reader_temporal_zero_calibration.csv"
)
diagnostic_source_names <- c(
  "H04_reader_primary_residual_acf.csv",
  "H04_reader_temporal_residual_acf.csv"
)
required_files <- c(
  qmd_path,
  html_path,
  artifact("06_model_data", "H04", "H04_model_frame_index.csv"),
  artifact("09_tables", "H04", "H04_primary_category_estimands.csv"),
  artifact("09_tables", "H04", "H04_primary_and_heterogeneity_tests.csv"),
  artifact("09_tables", "H04", "H04_site_activity_estimands.csv"),
  artifact("09_tables", "H04", "H04_sensitivity_comparison.csv"),
  artifact("09_tables", "H04", "H04_paired_placement_estimands.csv"),
  artifact(
    "09_tables", "H04", "H04_reader_heterogeneity_category_estimands.csv"
  ),
  artifact("09_tables", "H04", "H04_reader_category_estimands.csv"),
  artifact("09_tables", "H04", "H04_reader_heterogeneity_r_squared.csv"),
  artifact(
    "09_tables", "H04", "H04_reader_temporal_weighted_r_squared.csv"
  ),
  artifact(
    "09_tables", "H04", "H04_reader_temporal_variance_allocation.csv"
  ),
  artifact("08_diagnostics", "H04", "H04_diagnostic_assessments.csv"),
  artifact("08_diagnostics", "H04", "H04_temporal_model_summary.csv"),
  artifact("08_diagnostics", "H04", "H04_temporal_retention_decision.csv"),
  artifact("08_diagnostics", "H04", "H04_temporal_uncertainty_contract.csv"),
  artifact("08_diagnostics", "H04", "H04_reader_primary_zero_mass.csv"),
  artifact("08_diagnostics", "H04", "H04_reader_temporal_zero_mass.csv"),
  artifact("12_manifests", "H04", "H04_stage3_reader_asset_manifest.csv"),
  artifact(
    "12_manifests", "H04", "H04_stage3_reader_derivation_manifest.csv"
  ),
  artifact("12_manifests", "H04", "H04_stage3_figure_readability_qa.csv"),
  artifact("12_manifests", "H04", "H04_stage3_artifacts.csv"),
  file.path(artifact("10_figures", "H04"), figure_names),
  file.path(artifact("11_source_data", "H04"), source_data_names),
  file.path(
    artifact("08_diagnostics", "H04"),
    diagnostic_source_names
  )
)
stopifnot(all(file.exists(required_files)))

samples <- read_h04("06_model_data", "H04", "H04_model_frame_index.csv")
primary <- read_h04("09_tables", "H04", "H04_primary_category_estimands.csv")
tests <- read_h04(
  "09_tables", "H04", "H04_primary_and_heterogeneity_tests.csv"
)
site_activity <- read_h04(
  "09_tables", "H04", "H04_site_activity_estimands.csv"
)
reader_category <- read_h04(
  "09_tables", "H04", "H04_reader_category_estimands.csv"
)
sensitivity <- read_h04(
  "09_tables", "H04", "H04_sensitivity_comparison.csv"
)
temporal <- read_h04(
  "08_diagnostics", "H04", "H04_temporal_model_summary.csv"
)
temporal_retention <- read_h04(
  "08_diagnostics", "H04", "H04_temporal_retention_decision.csv"
)
temporal_uncertainty <- read_h04(
  "08_diagnostics", "H04", "H04_temporal_uncertainty_contract.csv"
)
figure_qa <- read_h04(
  "12_manifests", "H04", "H04_stage3_figure_readability_qa.csv"
)
asset_manifest <- read_h04(
  "12_manifests", "H04", "H04_stage3_reader_asset_manifest.csv"
)
derivation_manifest <- read_h04(
  "12_manifests", "H04", "H04_stage3_reader_derivation_manifest.csv"
)
stage3_manifest <- read_h04(
  "12_manifests", "H04", "H04_stage3_artifacts.csv"
)

main_samples <- samples |>
  filter(.data$scenario_id == "primary_dataset") |>
  arrange(match(.data$placement, c("Near-eye", "Chest")))
f1 <- tests |>
  filter(.data$test_id == "H04-F1") |>
  arrange(match(.data$placement, c("Near-eye", "Chest")))
heterogeneity <- tests |>
  filter(.data$test_id == "H04-F3") |>
  arrange(match(.data$placement, c("Near-eye", "Chest")))
paired_samples <- samples |>
  filter(.data$scenario_id == "paired_common_sample") |>
  arrange(match(.data$placement, c("Near-eye", "Chest")))
temporal_activity <- temporal |>
  filter(.data$formula_id == "temporal_activity_long") |>
  arrange(match(.data$placement, c("Near-eye", "Chest")))
reader_named_heterogeneity <- reader_category |>
  filter(.data$inferential_role == "NAMED_VERSUS_HOME")
reader_p_check <- reader_named_heterogeneity |>
  group_by(.data$placement) |>
  summarise(
    comparisons = dplyr::n(),
    maximum_adjustment_error = max(abs(
      .data$ratio_p_adjusted -
        stats::p.adjust(.data$ratio_p_raw, method = "BH", n = 4L)
    )),
    .groups = "drop"
  )
reader_registry <- h04_reader_activity_registry()
reader_codes <- c(
  "home", "working_indoor", "outdoors", "road_vehicle", "sleeping", "other"
)
reader_labels <- c(
  "At home", "Office/home working", "Outdoors", "Vehicle/public transport",
  "Sleeping", "Other/unspecified"
)

stopifnot(
  identical(as.integer(main_samples$participants), c(126L, 150L)),
  identical(as.integer(main_samples$participant_days), c(724L, 875L)),
  identical(
    as.integer(main_samples$unique_participant_hours),
    c(16526L, 20128L)
  ),
  identical(as.integer(main_samples$long_rows), c(17266L, 21071L)),
  all(abs(
    main_samples$effective_weighted_hours -
      main_samples$unique_participant_hours
  ) < 1e-8),
  nrow(primary) == 12L,
  all(table(primary$placement) == 6L),
  abs(
    primary$standardized_mean_lx[
      primary$placement == "Near-eye" & primary$activity_code == "home"
    ] - 74.6907
  ) < 0.01,
  abs(
    primary$ratio_to_home[
      primary$placement == "Near-eye" & primary$activity_code == "outdoors"
    ] - 11.578
  ) < 0.001,
  nrow(reader_category) == 12L,
  all(table(reader_category$placement) == 6L),
  identical(reader_registry$activity_code, reader_codes),
  identical(reader_registry$reader_label, reader_labels),
  all(!grepl("[\r\n]", reader_registry$reader_label)),
  all(nchar(reader_registry$reader_label) <= 24L),
  all(vapply(
    split(reader_category$activity_code, reader_category$placement),
    identical,
    logical(1),
    y = reader_codes
  )),
  sum(reader_category$model_source == "site_heterogeneity") == 10L,
  sum(reader_category$model_source == "additive_display_only") == 2L,
  nrow(reader_named_heterogeneity) == 8L,
  all(is.finite(reader_named_heterogeneity$ratio_p_raw)),
  all(is.finite(reader_named_heterogeneity$ratio_p_adjusted)),
  all(reader_named_heterogeneity$ratio_p_adjusted < 0.001),
  all(reader_p_check$comparisons == 4L),
  all(reader_p_check$maximum_adjustment_error < 1e-15),
  abs(
    reader_category$standardized_mean_lx[
      reader_category$placement == "Near-eye" &
        reader_category$activity_code == "home"
    ] - 76.3581
  ) < 0.01,
  abs(
    reader_category$ratio_to_home[
      reader_category$placement == "Near-eye" &
        reader_category$activity_code == "outdoors"
    ] - 9.35358
  ) < 0.001,
  all(abs(f1$f_statistic - c(83.5944, 93.3078)) < 1e-3),
  all(f1$p_raw < 0.001),
  all(abs(heterogeneity$f_statistic - c(8.0309, 11.6190)) < 1e-3),
  all(heterogeneity$p_raw < 0.001),
  sum(site_activity$site_deviation_p_adjusted < 0.05, na.rm = TRUE) == 26L,
  all(
    sensitivity$stability[
      sensitivity$activity_code %in%
        c("sleeping", "road_vehicle", "working_indoor", "outdoors")
    ] == "stable"
  ),
  identical(as.integer(paired_samples$participants), c(110L, 110L)),
  identical(as.integer(paired_samples$participant_days), c(625L, 625L)),
  identical(
    as.integer(paired_samples$unique_participant_hours),
    c(14308L, 14308L)
  ),
  identical(as.integer(paired_samples$long_rows), c(15001L, 15001L)),
  nrow(temporal_activity) == 2L,
  all(temporal_activity$converged),
  all(temporal_activity$final_warning_count == 0L),
  all(temporal_activity$smoothing_hessian_positive_definite),
  all(temporal_retention$retained_for_context),
  all(temporal_retention$assessment == "ACCEPTABLE WITH LIMITATION"),
  all(temporal_uncertainty$resampling_replicates == 0L),
  all(!temporal_uncertainty$simultaneous_band),
  all(!temporal_uncertainty$curve_wide_inference),
  nrow(figure_qa) == 7L,
  all(figure_qa$smallest_essential_effective_pt >= 5),
  all(figure_qa$clipping_checked),
  all(figure_qa$text_wrapping_checked),
  all(figure_qa$panel_balance_checked),
  all(figure_qa$final_size_legible),
  all(
    figure_qa$base_height_in[
      figure_qa$figure %in%
        c("H04_temporal_near_eye", "H04_temporal_chest")
    ] == 12.5
  ),
  nrow(asset_manifest) == 40L,
  all(nchar(asset_manifest$sha256) == 64L),
  nrow(derivation_manifest) == 46L,
  all(nchar(derivation_manifest$sha256) == 64L),
  all(nchar(stage3_manifest$sha256) == 64L)
)

stopifnot(
  all(file.exists(derivation_manifest$path)),
  identical(
    unname(vapply(
      derivation_manifest$path,
      artifact_sha256,
      character(1)
    )),
    derivation_manifest$sha256
  )
)

site_average_check <- site_activity |>
  filter(.data$reporting_status == "ESTIMABLE") |>
  distinct(
    .data$placement,
    .data$activity_code,
    .data$category_standardized_mean_lx
  ) |>
  left_join(
    reader_category |>
      filter(.data$model_source == "site_heterogeneity") |>
      transmute(
        placement = .data$placement,
        activity_code = .data$activity_code,
        reader_standardized_mean_lx = .data$standardized_mean_lx
      ),
    by = c("placement", "activity_code"),
    relationship = "one-to-one"
  )
stopifnot(
  nrow(site_average_check) == 10L,
  all(abs(
    site_average_check$category_standardized_mean_lx -
      site_average_check$reader_standardized_mean_lx
  ) < 1e-8)
)

h03_category_palette <- c(
  "#4477AA", "#EE6677", "#228833", "#CCBB44", "#66CCEE", "#AA3377",
  "#777777"
)
h04_temporal_palette <- h04_temporal_activity_palette()
temporal_ratio_breaks <- h04_temporal_ratio_breaks()
temporal_ratio_data <- dplyr::bind_rows(
  read_h04(
    "11_source_data", "H04", "H04_reader_temporal_near_eye_ratios.csv"
  ),
  read_h04(
    "11_source_data", "H04", "H04_reader_temporal_chest_ratios.csv"
  )
)
stopifnot(
  length(h04_temporal_palette) == 6L,
  !anyDuplicated(unname(h04_temporal_palette)),
  length(intersect(unname(h04_temporal_palette), h03_category_palette)) == 0L,
  identical(
    temporal_ratio_breaks,
    c(0.01, 0.02, 0.05, 0.1, 0.2, 0.5, 1, 2, 5, 10, 20, 50)
  ),
  min(temporal_ratio_data$ratio_conf_low, na.rm = TRUE) >=
    min(temporal_ratio_breaks),
  max(temporal_ratio_data$ratio_conf_high, na.rm = TRUE) <=
    max(temporal_ratio_breaks)
)

temporal_formula_compact <- gsub(
  "[[:space:]]+",
  "",
  temporal_activity$formula[[1L]]
)
required_temporal_fragments <- c(
  's(time_hour,bs="cc",k=12)',
  's(time_hour,activity,bs="sz",k=12)',
  's(time_hour,site,bs="sz",k=12)',
  's(time_hour,participant,bs="fs",k=10)',
  's(participant_day,bs="re")'
)
stopifnot(all(vapply(
  required_temporal_fragments,
  grepl,
  logical(1),
  x = temporal_formula_compact,
  fixed = TRUE
)))
stopifnot(!grepl("xt=list", temporal_formula_compact, fixed = TRUE))

qmd_text <- paste(readLines(qmd_path, warn = FALSE), collapse = "\n")
required_qmd_phrases <- c(
  "Answer in brief",
  "H04_reader_heterogeneity_category_estimates.png",
  "H04_site_activity_estimates.png",
  "H04_primary_diagnostics.png",
  "H04_paired_placement_comparison.png",
  "H04_temporal_near_eye.png",
  "H04_temporal_chest.png",
  "H04_temporal_diagnostics.png",
  "H04_reader_temporal_near_eye_ratios.csv",
  "Point allocation of fitted temporal linear-predictor variance",
  "these descriptive means",
  "qualitative palette distinct from the light-source",
  "Dashed lines are the equal-site geometric means",
  "BH-adjusted p-values",
  "0.01-to-50 ratio scale",
  "gap-timing-unaware dataset",
  "Other/unspecified activity",
  "pointwise 95% intervals",
  "not simultaneous bands"
)
stopifnot(all(vapply(
  required_qmd_phrases,
  grepl,
  logical(1),
  x = qmd_text,
  fixed = TRUE
)))
stopifnot(length(gregexpr("#\\| fig-alt:", qmd_text, fixed = FALSE)[[1L]]) == 7L)

reporting_text <- paste(
  readLines(
    file.path(root, "scripts/hypotheses/H04/h04_reporting.R"),
    warn = FALSE
  ),
  collapse = "\n"
)
stopifnot(
  grepl("ggplot2::geom_vline", reporting_text, fixed = TRUE),
  grepl("category_standardized_mean_lx", reporting_text, fixed = TRUE)
)

forbidden_reader_patterns <- c(
  "\\bV0\\b",
  "Stage [1-4]",
  "construction-history",
  "author approval",
  "author-approved repair",
  "result gate"
)
stopifnot(!any(vapply(
  forbidden_reader_patterns,
  grepl,
  logical(1),
  x = qmd_text,
  perl = TRUE,
  ignore.case = TRUE
)))
doc <- xml2::read_html(html_path)
main <- xml2::xml_find_first(doc, "//main")
html_text <- xml2::xml_text(main)
required_html_phrases <- c(
  "Answer in brief",
  "F(4, 125) = 83.59",
  "16,526 unique participant-hours",
  "20,128 unique participant-hours",
  "9.354",
  "Heterogeneity-model equal-site standardized",
  "Site-specific context",
  "Common-sample placement comparison",
  "Exploratory time-of-day context",
  "acceptable with limitation",
  "No resampling enters the displayed estimates or intervals"
)
stopifnot(all(vapply(
  tolower(required_html_phrases),
  grepl,
  logical(1),
  x = tolower(html_text),
  fixed = TRUE
)))
stopifnot(!grepl("p = 0.000", html_text, fixed = TRUE))
stopifnot(!any(vapply(
  forbidden_reader_patterns,
  grepl,
  logical(1),
  x = html_text,
  perl = TRUE,
  ignore.case = TRUE
)))
reader_only_forbidden_patterns <- c(
  "H04-F[0-9]",
  "\\bH03\\b",
  "H04-specific",
  "accepted heterogeneity model"
)
stopifnot(!any(vapply(
  reader_only_forbidden_patterns,
  grepl,
  logical(1),
  x = html_text,
  perl = TRUE,
  ignore.case = TRUE
)))

figure_nodes <- xml2::xml_find_all(main, ".//figure//img")
alt_text <- xml2::xml_attr(figure_nodes, "alt")
stopifnot(
  length(figure_nodes) >= 7L,
  all(!is.na(alt_text)),
  all(nchar(trimws(alt_text)) >= 80L)
)

gt_tables <- xml2::xml_find_all(main, ".//table[contains(@class, 'gt_table')]")
stopifnot(length(gt_tables) >= 14L)

first_table_cells <- function(table_id) {
  table_node <- xml2::xml_find_first(
    main,
    paste0(".//*[@id='", table_id, "']")
  )
  rows <- xml2::xml_find_all(table_node, ".//tbody/tr")
  vapply(
    rows,
    function(row) {
      gsub(
        "[[:space:]]+",
        " ",
        trimws(xml2::xml_text(xml2::xml_find_first(row, "./th|./td")))
      )
    },
    character(1)
  )
}
full_reader_order <- c(
  "At home", "Office/home working", "Outdoors",
  "Vehicle/public transport", "Sleeping", "Other/unspecified activity"
)
stopifnot(
  identical(
    first_table_cells("tbl-h04-category-support"),
    c("Near-eye", full_reader_order, "Chest", full_reader_order)
  ),
  identical(
    first_table_cells("tbl-h04-primary-results"),
    c("Near-eye", full_reader_order, "Chest", full_reader_order)
  ),
  identical(
    first_table_cells("tbl-h04-named-contrasts"),
    c(
      "Near-eye", full_reader_order[2:5],
      "Chest", full_reader_order[2:5]
    )
  )
)

site_table <- xml2::xml_find_first(
  main,
  ".//*[@id='tbl-h04-near-site-factorization']"
)
site_headers <- xml2::xml_find_all(site_table, ".//thead//th") |>
  xml2::xml_text() |>
  gsub(pattern = "[[:space:]]+", replacement = "")
stopifnot(identical(
  site_headers,
  c(
    "Site", "Athome", "Office/homeworking", "Outdoors",
    "Vehicle/publictransport", "Sleeping"
  )
))
site_table_text <- xml2::xml_text(site_table)
site_table_body <- xml2::xml_find_first(site_table, ".//tbody")
site_table_overall_text <- xml2::xml_text(
  xml2::xml_find_first(site_table_body, "./tr[1]")
)
site_table_site_rows <- xml2::xml_find_all(
  site_table_body,
  "./tr[position() > 2]"
)
site_table_site_text <- paste(xml2::xml_text(site_table_site_rows), collapse = " ")
count_fixed <- function(pattern, text) {
  matches <- gregexpr(pattern, text, fixed = TRUE)[[1L]]
  if (length(matches) == 1L && matches[[1L]] < 0L) {
    0L
  } else {
    sum(matches > 0L)
  }
}
stopifnot(
  count_fixed("raw p", site_table_site_text) == 0L,
  count_fixed("BH p", site_table_site_text) == 44L,
  count_fixed("BH p", site_table_overall_text) == 5L,
  count_fixed("<0.001", site_table_overall_text) == 4L,
  length(xml2::xml_find_all(
    site_table_body,
    "./tr[position() > 2]//strong"
  )) == 34L,
  grepl(
    "report only the BH-adjusted deviation p-value",
    site_table_text,
    fixed = TRUE
  )
)

manifest_paths <- file.path(root, stage3_manifest$path)
observed_hashes <- unname(vapply(
  manifest_paths,
  artifact_sha256,
  character(1)
))
stopifnot(identical(observed_hashes, stage3_manifest$sha256))

message("H04 standalone reader-report contracts passed")
