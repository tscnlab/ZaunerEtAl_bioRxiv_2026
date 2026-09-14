#!/usr/bin/env Rscript

locate_project_root <- function(start = getwd()) {
  candidate <- normalizePath(start, winslash = "/", mustWork = TRUE)
  repeat {
    if (
      file.exists(file.path(candidate, "renv.lock")) &&
        file.exists(file.path(candidate, "_quarto.yml"))
    ) {
      return(candidate)
    }
    parent <- dirname(candidate)
    if (identical(parent, candidate)) {
      stop("Could not locate project root", call. = FALSE)
    }
    candidate <- parent
  }
}

root <- locate_project_root()
stopifnot(identical(as.character(getRversion()), "4.6.1"))

main_path <- file.path(root, "notebooks/hypotheses/H06.qmd")
companion_path <- file.path(
  root,
  "audit/hypotheses/H06/H06_analysis_preparation.qmd"
)
report_path <- file.path(
  root,
  paste0(
    "audit/hypotheses/H06/employment_eligibility_sensitivity/",
    "H06_employment_eligibility_sensitivity.qmd"
  )
)
flow_path <- file.path(
  root,
  paste0(
    "artifacts/06_model_data/H06/employment_eligibility_sensitivity/",
    "H06_employment_eligibility_sample_flow.csv"
  )
)
effects_path <- file.path(
  root,
  paste0(
    "artifacts/09_tables/H06/employment_eligibility_sensitivity/",
    "H06_employment_eligibility_effect_comparison.csv"
  )
)
heterogeneity_path <- file.path(
  root,
  paste0(
    "artifacts/09_tables/H06/employment_eligibility_sensitivity/",
    "H06_employment_eligibility_heterogeneity_comparison.csv"
  )
)

protected_paths <- c(
  main_path,
  companion_path,
  report_path,
  flow_path,
  effects_path,
  heterogeneity_path
)
stopifnot(all(file.exists(protected_paths)))

main <- paste(readLines(main_path, warn = FALSE), collapse = "\n")
companion <- paste(readLines(companion_path, warn = FALSE), collapse = "\n")
main_flat <- gsub("[[:space:]]+", " ", main)
companion_flat <- gsub("[[:space:]]+", " ", companion)

main_tokens <- c(
  "### Employment-eligibility sensitivity (near-eye only)",
  "excluded six participants recorded as not employed or",
  "15,871",
  "684 participant-days",
  "131 participants",
  "stable within model uncertainty",
  "F(8, 130) = 3.59",
  "FDR-adjusted p = 0.003",
  "H06_employment_eligibility_effect_comparison.csv",
  "H06_employment_eligibility_heterogeneity_comparison.csv"
)
stopifnot(all(vapply(
  main_tokens,
  grepl,
  logical(1),
  x = main_flat,
  fixed = TRUE
)))

companion_tokens <- c(
  "#### Employment eligibility (near-eye only)",
  "retains students and trainees",
  "does not use age above 65 years as an exclusion rule",
  "The sensitivity was not repeated for the chest position.",
  "H06_employment_eligibility_sample_flow.csv",
  "H06_employment_eligibility_heterogeneity_comparison.csv"
)
stopifnot(all(vapply(
  companion_tokens,
  grepl,
  logical(1),
  x = companion_flat,
  fixed = TRUE
)))

flow <- read.csv(flow_path, check.names = FALSE, stringsAsFactors = FALSE)
effects <- read.csv(
  effects_path,
  check.names = FALSE,
  stringsAsFactors = FALSE
)
heterogeneity <- read.csv(
  heterogeneity_path,
  check.names = FALSE,
  stringsAsFactors = FALSE
)

primary_flow <- flow[flow$scenario_id == "H06-primary-near-eye", , drop = FALSE]
restricted_flow <- flow[flow$scenario_id == "H06-S-EMP-NE", , drop = FALSE]
stopifnot(
  nrow(primary_flow) == 1L,
  nrow(restricted_flow) == 1L,
  identical(primary_flow$one_hour_observations, 16596L),
  identical(primary_flow$participant_days, 715L),
  identical(primary_flow$participants, 137L),
  identical(primary_flow$sites, 9L),
  identical(restricted_flow$one_hour_observations, 15871L),
  identical(restricted_flow$participant_days, 684L),
  identical(restricted_flow$participants, 131L),
  identical(restricted_flow$sites, 9L)
)

expected_effects <- data.frame(
  predictor_id = c(
    "work_free_day",
    "activity_status",
    "previous_sleep_duration_centered_h"
  ),
  ratio = c(1.4573288, 1.8791782, 0.9482283),
  low = c(1.1125438, 1.4210658, 0.8285288),
  high = c(1.908965, 2.484973, 1.085221),
  p_adjusted = c(9.924450e-03, 5.128863e-05, 4.371806e-01),
  stringsAsFactors = FALSE
)
matched_effects <- effects[
  match(expected_effects$predictor_id, effects$predictor_id),
  ,
  drop = FALSE
]
stopifnot(
  identical(matched_effects$predictor_id, expected_effects$predictor_id),
  max(abs(matched_effects$alternative_ratio - expected_effects$ratio)) < 1e-7,
  max(abs(matched_effects$alternative_conf_low - expected_effects$low)) < 1e-7,
  max(abs(matched_effects$alternative_conf_high - expected_effects$high)) < 1e-6,
  max(
    abs(matched_effects$alternative_p_adjusted - expected_effects$p_adjusted)
  ) < 1e-7,
  all(
    matched_effects$detailed_stability_classification ==
      "stable within model uncertainty"
  )
)

day_type_heterogeneity <- heterogeneity[
  heterogeneity$predictor_id == "work_free_day",
  ,
  drop = FALSE
]
stopifnot(
  nrow(day_type_heterogeneity) == 1L,
  abs(day_type_heterogeneity$sensitivity_f_statistic - 3.5881476) < 1e-7,
  identical(day_type_heterogeneity$sensitivity_df1, 8L),
  identical(day_type_heterogeneity$sensitivity_df2, 130L),
  abs(day_type_heterogeneity$sensitivity_p_adjusted - 0.002564231) < 1e-8,
  isTRUE(day_type_heterogeneity$sensitivity_adjusted_supported),
  !any(heterogeneity$adjusted_conclusion_changed)
)

extract_r_chunks <- function(path) {
  lines <- readLines(path, warn = FALSE)
  starts <- grep("^```\\{r", lines)
  chunks <- vector("list", length(starts))
  for (index in seq_along(starts)) {
    end_candidates <- which(
      seq_along(lines) > starts[[index]] & lines == "```"
    )
    stopifnot(length(end_candidates) > 0L)
    chunks[[index]] <- lines[
      seq.int(starts[[index]] + 1L, end_candidates[[1L]] - 1L)
    ]
  }
  chunks
}

for (path in c(main_path, companion_path)) {
  chunks <- extract_r_chunks(path)
  stopifnot(length(chunks) > 0L)
  invisible(lapply(chunks, function(chunk) parse(text = chunk)))
}

cat(
  paste0(
    "PASS: H06 employment-eligibility reader integration; ",
    "R ", as.character(getRversion()), "; 2 QMD sources; ",
    "3 stored sensitivity tables.\n"
  )
)
