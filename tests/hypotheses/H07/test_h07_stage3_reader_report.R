# Focused scientific and structural checks for the standalone H07 report.

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
  stop("H07 reader-report tests require R 4.6.1", call. = FALSE)
}

qmd_path <- file.path(root, "notebooks/hypotheses/H07.qmd")
html_path <- file.path(
  root,
  "_build/nathealth/notebooks/hypotheses/H07.html"
)
table_dir <- file.path(root, "artifacts/09_tables/H07")
figure_dir <- file.path(root, "artifacts/08_figures/H07")

required_files <- c(
  qmd_path,
  html_path,
  file.path(table_dir, "H07_main_samples.csv"),
  file.path(table_dir, "H07_main_curve_points.csv"),
  file.path(table_dir, "H07_revised_derivative_points.csv"),
  file.path(table_dir, "H07_revised_plateau_summary.csv"),
  file.path(table_dir, "H07_revised_sensitivity_plateau_comparison.csv"),
  file.path(table_dir, "H07_revised_model_form_plateau_comparison.csv"),
  file.path(table_dir, "H07_revised_loso_plateau_influence_summary.csv"),
  file.path(table_dir, "H07_main_diagnostics.csv"),
  file.path(table_dir, "H07_main_pairwise_concurvity.csv"),
  file.path(table_dir, "H07_main_tweedie_distribution_pilot.csv"),
  file.path(table_dir, "H07_formula_registry.csv"),
  file.path(
    figure_dir,
    "H07_revised_smooth_derivative_pairs_near_eye.png"
  ),
  file.path(
    figure_dir,
    "H07_revised_smooth_derivative_pairs_chest.png"
  )
)
stopifnot(all(file.exists(required_files)))

plateau <- readr::read_csv(
  file.path(table_dir, "H07_revised_plateau_summary.csv"),
  show_col_types = FALSE
) |>
  filter(.data$method_id == "REVISED_CENTRAL_UNCONDITIONAL_POINTWISE")
samples <- readr::read_csv(
  file.path(table_dir, "H07_main_samples.csv"),
  show_col_types = FALSE
) |>
  mutate(placement = sub("^primary__", "", .data$run_id))
sensitivity <- readr::read_csv(
  file.path(table_dir, "H07_revised_sensitivity_plateau_comparison.csv"),
  show_col_types = FALSE
)
model_form <- readr::read_csv(
  file.path(table_dir, "H07_revised_model_form_plateau_comparison.csv"),
  show_col_types = FALSE
)
loso <- readr::read_csv(
  file.path(table_dir, "H07_revised_loso_plateau_influence_summary.csv"),
  show_col_types = FALSE
)
diagnostics <- readr::read_csv(
  file.path(table_dir, "H07_main_diagnostics.csv"),
  show_col_types = FALSE
) |>
  filter(.data$model_id == "adapted_photoperiod_smooth")
concurvity <- readr::read_csv(
  file.path(table_dir, "H07_main_pairwise_concurvity.csv"),
  show_col_types = FALSE
) |>
  filter(
    .data$model_id == "adapted_photoperiod_smooth",
    .data$measure == "estimate",
    .data$supplier_term == "s(site_participant)",
    .data$target_term == "s(photoperiod_hours)"
  )
tweedie <- readr::read_csv(
  file.path(table_dir, "H07_main_tweedie_distribution_pilot.csv"),
  show_col_types = FALSE
)
formulas <- readr::read_csv(
  file.path(table_dir, "H07_formula_registry.csv"),
  show_col_types = FALSE
)

near <- plateau |>
  filter(.data$placement == "near_eye") |>
  arrange(.data$metric_order)
chest <- plateau |>
  filter(.data$placement == "chest") |>
  arrange(.data$metric_order)

stopifnot(
  nrow(plateau) == 18L,
  nrow(near) == 9L,
  nrow(chest) == 9L,
  sum(near$revised_plateau_pattern) == 6L,
  sum(chest$revised_plateau_pattern) == 7L,
  identical(
    as.integer(near$metric_order[near$revised_plateau_pattern]),
    c(1L, 2L, 3L, 4L, 5L, 9L)
  ),
  identical(
    as.integer(chest$metric_order[chest$revised_plateau_pattern]),
    c(1L, 3L, 4L, 5L, 7L, 8L, 9L)
  ),
  min(samples$participants[samples$placement == "near_eye"]) == 139L,
  max(samples$participants[samples$placement == "near_eye"]) == 141L,
  min(samples$participant_days[samples$placement == "near_eye"]) == 655L,
  max(samples$participant_days[samples$placement == "near_eye"]) == 816L,
  all(samples$sites[samples$placement == "near_eye"] == 9L),
  min(samples$participants[samples$placement == "chest"]) == 153L,
  max(samples$participants[samples$placement == "chest"]) == 154L,
  min(samples$participant_days[samples$placement == "chest"]) == 743L,
  max(samples$participant_days[samples$placement == "chest"]) == 902L,
  all(samples$sites[samples$placement == "chest"] == 8L),
  all(samples$participant_days == samples$observations)
)

sensitivity_count <- function(
  sensitivity_name,
  placement_name,
  data_scenario_name = "primary"
) {
  selected <- sensitivity |>
    filter(
      .data$sensitivity == .env$sensitivity_name,
      .data$placement == .env$placement_name,
      .data$data_scenario == .env$data_scenario_name
    )
  c(
    agreement = sum(selected$classification_agrees, na.rm = TRUE),
    evaluable = sum(!is.na(selected$classification_agrees))
  )
}

stopifnot(
  identical(
    unname(sensitivity_count(
      "gap_timing_unaware",
      "near_eye",
      "gap_timing_unaware"
    )),
    c(9L, 9L)
  ),
  identical(
    unname(sensitivity_count(
      "gap_timing_unaware",
      "chest",
      "gap_timing_unaware"
    )),
    c(8L, 9L)
  ),
  identical(
    unname(sensitivity_count("paired_common_placement", "near_eye")),
    c(4L, 9L)
  ),
  identical(
    unname(sensitivity_count("paired_common_placement", "chest")),
    c(6L, 9L)
  )
)

model_form_counts <- model_form |>
  group_by(.data$placement, .data$model_id) |>
  summarise(
    agreement = sum(.data$classification_agrees, na.rm = TRUE),
    evaluable = sum(!is.na(.data$classification_agrees)),
    failed = sum(grepl("^FAIL", .data$fit_status)),
    .groups = "drop"
  )
stopifnot(
  identical(model_form_counts$agreement, c(8L, 8L, 8L, 8L)),
  identical(model_form_counts$evaluable, c(9L, 9L, 8L, 9L)),
  sum(model_form_counts$failed) == 1L,
  all(diagnostics$converged),
  max(abs(diagnostics$pooled_consecutive_day_lag1), na.rm = TRUE) < 0.25,
  min(concurvity$concurvity) > 0.998,
  max(concurvity$concurvity) < 0.999,
  nrow(tweedie) == 6L
)

sleep_tweedie <- tweedie |>
  filter(.data$metric_id == "duration_below_1_sleep_environment")
stopifnot(
  nrow(sleep_tweedie) == 2L,
  all(sleep_tweedie$draws == 100L),
  all(sleep_tweedie$observed_zero_count == 4L),
  all(sleep_tweedie$analytic_expected_zero_count < 0.0001),
  all(sleep_tweedie$simulated_zero_lower == 0L),
  all(sleep_tweedie$simulated_zero_upper == 0L),
  loso$omissions_matching_main[
    loso$placement == "chest" & loso$metric_order == 7L
  ] == 3L
)

reported_formula <- formulas$formula[
  formulas$model_id == "adapted_photoperiod_smooth"
]
stopifnot(
  length(reported_formula) == 1L,
  grepl("s\\(photoperiod_hours, k = 6, bs = \"tp\"\\)", reported_formula),
  grepl("s\\(site,", reported_formula),
  grepl("s\\(site_participant,", reported_formula)
)

qmd_text <- paste(readLines(qmd_path, warn = FALSE), collapse = "\n")
doc <- xml2::read_html(html_path)
html_text <- xml2::xml_text(xml2::xml_find_first(doc, "//main"))

required_reader_phrases <- c(
  "Answer in brief",
  "six of nine primary near-eye metrics",
  "seven of nine metrics",
  "gap-timing-unaware dataset",
  "derivative-defined plateau pattern",
  "Absolute latitude cannot be separated from site",
  "not establish a ceiling",
  "do not establish a ceiling"
)
stopifnot(
  all(vapply(
    required_reader_phrases,
    grepl,
    logical(1L),
    x = html_text,
    fixed = TRUE
  )),
  !grepl("\\bV0\\b", html_text),
  !grepl("Stage [1-4]", html_text),
  !grepl("\\bbout\\b", html_text, ignore.case = TRUE),
  grepl(
    "primary preparation could be interpreted as a time-sensitive",
    html_text,
    fixed = TRUE
  ),
  grepl("melEDI", html_text, fixed = TRUE),
  grepl("period", html_text, fixed = TRUE),
  !grepl("temperature_hours|temperature_c", qmd_text)
)

figures <- xml2::xml_find_all(doc, "//figure//img")
alts <- xml2::xml_attr(figures, "alt")
stopifnot(
  length(figures) == 2L,
  all(!is.na(alts)),
  all(nchar(alts) >= 200L),
  length(xml2::xml_find_all(
    doc,
    "//table[contains(@class, 'gt_table')]"
  )) == 11L
)

local_links <- xml2::xml_attr(
  xml2::xml_find_all(doc, "//a[starts-with(@href, '../../artifacts/') ]"),
  "href"
)
local_sources <- normalizePath(
  file.path(dirname(html_path), local_links),
  winslash = "/",
  mustWork = FALSE
)
stopifnot(
  length(local_links) >= 4L,
  all(grepl("\\.csv$", local_links)),
  all(file.exists(local_sources))
)

cat("H07 Stage 3 reader-report checks passed.\n")
