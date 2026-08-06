# Focused checks for the H11 Stage 1 audit. No model is fitted here.

options(
  stringsAsFactors = FALSE,
  scipen = 999,
  dplyr.summarise.inform = FALSE
)

test_argument <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
if (length(test_argument) != 1L) {
  stop("Could not determine the H11 Stage 1 test location", call. = FALSE)
}
test_path <- normalizePath(
  sub("^--file=", "", test_argument),
  winslash = "/",
  mustWork = TRUE
)
root_candidate <- dirname(dirname(dirname(dirname(test_path))))
source(file.path(root_candidate, "scripts/hypotheses/H11/h11_stage1.R"))

root <- h11_find_project_root(root_candidate)
artifacts <- h11_stage1_artifacts(root)

stopifnot(
  nrow(artifacts$input_provenance) == 44L,
  all(artifacts$input_provenance$hash_verified),
  nrow(artifacts$candidate_sample_counts) == 10L,
  all(artifacts$candidate_sample_counts$missing_biological_sex_rows == 0L),
  nrow(artifacts$formula_manifest) == 8L,
  nrow(artifacts$findings) == 16L,
  nrow(artifacts$author_decisions) == 11L,
  nrow(artifacts$sensitivity_plan) == 9L
)

main <- artifacts$candidate_sample_counts |>
  dplyr::filter(
    .data$data_scenario_id == "main",
    .data$sample_scenario == "all_available"
  ) |>
  dplyr::arrange(factor(.data$placement, levels = c("glasses", "chest")))
stopifnot(
  identical(main$participants, c(141L, 154L)),
  identical(main$participant_days, c(816L, 902L)),
  identical(main$observations_or_hours, c(37756L, 41842L)),
  identical(main$sites, c(9L, 8L)),
  identical(main$female_participants, c(79L, 86L)),
  identical(main$male_participants, c(62L, 68L))
)

registered_hourly <- artifacts$candidate_sample_counts |>
  dplyr::filter(.data$data_scenario_id == "registered_outcome_sensitivity") |>
  dplyr::arrange(factor(.data$placement, levels = c("glasses", "chest")))
stopifnot(
  identical(registered_hourly$participants, c(141L, 154L)),
  identical(registered_hourly$participant_days, c(816L, 902L)),
  identical(registered_hourly$observations_or_hours, c(18953L, 21004L)),
  identical(registered_hourly$observation_unit, rep("one-hour observations", 2L))
)

common <- artifacts$main_manuscript_common_samples |>
  dplyr::arrange(factor(.data$placement, levels = c("glasses", "chest")))
stopifnot(
  identical(common$participants, c(141L, 154L)),
  identical(common$participant_days, c(809L, 894L)),
  identical(common$common_observations_30_minute, c(37298L, 41325L)),
  identical(common$sites, c(9L, 8L))
)

site_cells <- artifacts$site_sex_support |>
  dplyr::count(.data$placement, .data$site, name = "categories")
stopifnot(
  all(site_cells$categories == 2L),
  min(artifacts$site_sex_support$participants) == 2L,
  identical(
    unique(
      artifacts$site_sex_support$display_name[
        artifacts$site_sex_support$placement == "glasses"
      ]
    ),
    c(
      "Borås (SE)", "Delft (NL)", "Dortmund (DE)", "Tübingen (DE)",
      "Munich (DE)", "Madrid (ES)", "Izmir (TR)", "San José (CR)",
      "Kumasi (GH)"
    )
  )
)

crosswalk <- artifacts$sex_gender_crosswalk
cell_n <- function(sex, gender) {
  value <- crosswalk$participants[
    crosswalk$biological_sex == sex & crosswalk$gender == gender
  ]
  if (length(value) == 0L) 0L else value
}
stopifnot(
  cell_n("Female", "Woman") == 105L,
  cell_n("Male", "Man") == 84L,
  cell_n("Male", "Woman") == 1L,
  cell_n("Male", "Non-binary") == 1L
)

formulas <- h11_formula_set(root)
h02_selected <- h11_h02_formula_set(root)$site_pattern
formula_terms <- function(x) attr(stats::terms(x), "term.labels")
stopifnot(
  identical(
    h11_formula_text(formulas$proposed_m0),
    h11_formula_text(h02_selected)
  ),
  identical(
    setdiff(formula_terms(formulas$proposed_mlevel), "sex"),
    formula_terms(h02_selected)
  ),
  all(formula_terms(h02_selected) %in% formula_terms(formulas$proposed_mpattern)),
  "sex" %in% formula_terms(formulas$proposed_mpattern),
  any(grepl("sex_smooth", formula_terms(formulas$proposed_mpattern), fixed = TRUE)),
  !any(grepl("photoperiod", formula_terms(formulas$proposed_mpattern), fixed = TRUE)),
  !any(grepl("gender", formula_terms(formulas$proposed_mpattern), fixed = TRUE))
)

script_text <- paste(
  readLines(file.path(root, "scripts/hypotheses/H11/h11_stage1.R"), warn = FALSE),
  collapse = "\n"
)
runner_text <- paste(
  readLines(
    file.path(root, "scripts/hypotheses/H11/build_h11_stage1_audit.R"),
    warn = FALSE
  ),
  collapse = "\n"
)
forbidden_fit_call <- "mgcv::(bam|gam)[[:space:]]*\\("
stopifnot(
  !grepl(forbidden_fit_call, script_text, perl = TRUE),
  !grepl(forbidden_fit_call, runner_text, perl = TRUE)
)

output_dir <- file.path(root, "artifacts/06_model_data/H11")
for (artifact_id in names(artifacts)) {
  persisted <- utils::read.csv(
    file.path(output_dir, paste0("stage1_", artifact_id, ".csv")),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  stopifnot(nrow(persisted) == nrow(artifacts[[artifact_id]]))
}

environment <- artifacts$environment
stopifnot(
  environment$version[environment$component == "R"] == "4.6.1",
  environment$version[environment$component == "mgcv"] == "1.9.4",
  environment$version[environment$component == "gratia"] == "0.11.2",
  environment$version[environment$component == "gt"] == "1.3.0"
)

output_manifest_path <- file.path(
  root,
  "artifacts/12_manifests/H11/H11_stage1_output_hashes.csv"
)
if (file.exists(output_manifest_path)) {
  output_manifest <- utils::read.csv(
    output_manifest_path,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  output_paths <- file.path(root, output_manifest$path)
  stopifnot(
    !anyDuplicated(output_manifest$path),
    all(file.exists(output_paths)),
    identical(
      unname(vapply(output_paths, h11_sha256, character(1))),
      output_manifest$sha256
    )
  )
}

cat("H11 Stage 1 focused audit tests: PASS\n")
