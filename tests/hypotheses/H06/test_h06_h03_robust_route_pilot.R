# Verify the bounded H03-informed H06 robust-mean architecture amendment.

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
if (!file.exists(file.path(root, "renv.lock"))) {
  stop("Run this test from the project root", call. = FALSE)
}
if (!identical(as.character(getRversion()), "4.6.1")) {
  stop(
    "H06 robust-route test requires R 4.6.1; found ",
    as.character(getRversion()),
    call. = FALSE
  )
}

required_packages <- c("dplyr", "readr", "xml2")
missing_packages <- required_packages[!vapply(
  required_packages,
  requireNamespace,
  logical(1),
  quietly = TRUE
)]
if (length(missing_packages) > 0L) {
  stop(
    "Missing project package(s): ",
    paste(missing_packages, collapse = ", "),
    call. = FALSE
  )
}

model_data_root <- file.path(root, "artifacts/06_model_data/H06")
model_root <- file.path(root, "artifacts/07_models/H06")
diagnostic_root <- file.path(root, "artifacts/08_diagnostics/H06")
table_root <- file.path(root, "artifacts/09_tables/H06")

paths <- c(
  registry = file.path(
    model_data_root,
    "H06_h03_robust_route_pilot_registry.csv"
  ),
  fit = file.path(
    diagnostic_root,
    "H06_h03_robust_route_pilot_fit_diagnostics.csv"
  ),
  mean_gate = file.path(
    diagnostic_root,
    "H06_h03_robust_route_pilot_mean_structure_gate.csv"
  ),
  covariance = file.path(
    diagnostic_root,
    "H06_h03_robust_route_pilot_covariance.csv"
  ),
  power = file.path(
    diagnostic_root,
    "H06_h03_robust_route_pilot_power_sensitivity.csv"
  ),
  deletions = file.path(
    diagnostic_root,
    "H06_h03_robust_route_pilot_targeted_deletions.csv"
  ),
  summary = file.path(
    table_root,
    "H06_h03_robust_route_pilot_summary.csv"
  ),
  model = file.path(
    model_root,
    "H06_h03_robust_route_pilot_models.rds"
  ),
  qmd = file.path(root, "audit/hypotheses/H06/01_audit_and_plan.qmd"),
  html = file.path(root, "audit/hypotheses/H06/01_audit_and_plan.html")
)
stopifnot(all(file.exists(paths)))

read_h06 <- function(path) readr::read_csv(path, show_col_types = FALSE)
normalize_formula_text <- function(x) {
  gsub("[[:space:]]+", " ", trimws(x))
}
registry <- read_h06(paths[["registry"]])
fit <- read_h06(paths[["fit"]])
mean_gate <- read_h06(paths[["mean_gate"]])
covariance <- read_h06(paths[["covariance"]])
power <- read_h06(paths[["power"]])
deletions <- read_h06(paths[["deletions"]])
summary <- read_h06(paths[["summary"]])

stopifnot(
  nrow(registry) == 4L,
  identical(
    registry$route_id,
    c(
      "quasi_poisson_p1",
      "h03_literal_p1_539919",
      "h06_stable_p1_8",
      "h06_v0_boundary_p1_9"
    )
  ),
  identical(registry$working_power, c(1, 1.539919, 1.8, 1.9)),
  identical(
    registry$route_id[registry$selected_for_revised_gate],
    "quasi_poisson_p1"
  ),
  !any(registry$confirmatory_clock_term),
  all(normalize_formula_text(registry$fixed_formula) == paste(
    "response_value ~ site * work_free_day + site * activity_status +",
    "site * previous_sleep_duration_centered_h"
  )),
  nrow(fit) == 8L,
  nrow(mean_gate) == 2L,
  nrow(covariance) == 14L,
  nrow(power) == 8L,
  nrow(deletions) == 10L,
  nrow(summary) == 2L,
  identical(sort(summary$observations), c(16596, 18352)),
  identical(sort(summary$participant_days), c(715, 789)),
  identical(sort(summary$participant_clusters), c(137, 149)),
  all(summary$numerical_gate_pass),
  all(summary$additive_numerical_gate_pass),
  all(summary$hc3_covariance_positive_definite),
  all(summary$targeted_participant_refits == 5L),
  all(summary$successful_refits == 5L),
  max(summary$maximum_abs_core_shift_full_hc3_se) < 1,
  all(mean_gate$converged),
  all(mean_gate$full_rank),
  all(mean_gate$hc3_covariance_positive_definite),
  identical(mean_gate$design_rank, c(12, 11)),
  identical(mean_gate$design_columns, c(12, 11)),
  all(normalize_formula_text(mean_gate$formula) == paste(
    "response_value ~ site + work_free_day + activity_status +",
    "previous_sleep_duration_centered_h"
  )),
  all(fit$converged[fit$route_id %in% c(
    "quasi_poisson_p1", "h03_literal_p1_539919", "h06_stable_p1_8"
  )]),
  !fit$converged[
    fit$placement == "glasses" &
      fit$route_id == "h06_v0_boundary_p1_9"
  ],
  grepl(
    "NA/NaN/Inf in 'x'",
    fit$fit_error[
      fit$placement == "glasses" &
        fit$route_id == "h06_v0_boundary_p1_9"
    ],
    fixed = TRUE
  ),
  all(deletions$refit_converged),
  all(deletions$refit_full_rank),
  max(
    power$maximum_abs_core_and_site_interaction_shift_selected_hc3_se,
    na.rm = TRUE
  ) < 0.75
)

model_bundle <- readRDS(paths[["model"]])
stopifnot(
  identical(
    model_bundle$contract_version,
    "h06_h03_robust_route_pilot_v1"
  ),
  identical(
    normalize_formula_text(paste(deparse(model_bundle$formula), collapse = " ")),
    paste(
      "response_value ~ site * work_free_day + site * activity_status +",
      "site * previous_sleep_duration_centered_h"
    )
  ),
  identical(sort(names(model_bundle$fits)), c("chest", "glasses")),
  is.null(
    model_bundle$fits$glasses$routes$h06_v0_boundary_p1_9$model
  ),
  !is.null(model_bundle$fits$chest$routes$h06_v0_boundary_p1_9$model),
  !is.null(model_bundle$fits$glasses$additive_primary$model),
  !is.null(model_bundle$fits$chest$additive_primary$model)
)

qmd_text <- paste(readLines(paths[["qmd"]], warn = FALSE), collapse = "\n")
stopifnot(
  grepl("Author decision requested: H06-G1A", qmd_text, fixed = TRUE),
  grepl("quasi-Poisson log-link additive mean model", qmd_text, fixed = TRUE),
  grepl("participant-cluster HC3 covariance", qmd_text, fixed = TRUE),
  grepl("fixed-power quasi-Tweedie `p = 1.8`", qmd_text, fixed = TRUE),
  grepl("H06-G1A is awaiting explicit author approval", qmd_text, fixed = TRUE)
)

html <- xml2::read_html(paths[["html"]])
html_text <- xml2::xml_text(html)
stopifnot(
  grepl("Revised H06 Stage 1 gate", html_text, fixed = TRUE),
  grepl("H06-G1A is awaiting explicit author approval", html_text, fixed = TRUE),
  grepl("Quasi-Poisson, p = 1 (proposed primary)", html_text, fixed = TRUE),
  grepl("Quasi-Tweedie, p = 1.9 (boundary check)", html_text, fixed = TRUE),
  grepl("Stage 3 notebook", html_text, fixed = TRUE)
)

cat("H06 H03-informed robust-route pilot tests passed\n")
