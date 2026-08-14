# Add the H04 Mundlak sensitivity to the accepted frozen primary frames.

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

source(file.path(root, "scripts/pipeline/paths_io.R"))
source(file.path(root, "scripts/hypotheses/H04/h04_contract.R"))
source(file.path(root, "scripts/hypotheses/H04/h04_stage1_support.R"))
source(file.path(root, "scripts/hypotheses/H04/h04_data.R"))
source(file.path(root, "scripts/hypotheses/H04/h04_modeling.R"))

options(lifecycle_verbosity = "quiet", warn = 1)
if (!identical(as.character(getRversion()), "4.6.1")) {
  h04_abort(
    "The H04 Mundlak sensitivity requires R 4.6.1; found %s",
    as.character(getRversion())
  )
}
required_packages <- c(
  "dplyr", "tidyr", "tibble", "readr", "digest", "openssl", "statmod",
  "sandwich"
)
missing_packages <- required_packages[
  !vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
]
if (length(missing_packages) > 0L) {
  h04_abort(
    "Missing synchronized project package(s): %s",
    paste(missing_packages, collapse = ", ")
  )
}

producer <- "scripts/hypotheses/H04/run_h04_mundlak_sensitivity.R"
roots <- list(
  model_data = file.path(root, "artifacts/06_model_data/H04"),
  models = file.path(root, "artifacts/07_models/H04"),
  diagnostics = file.path(root, "artifacts/08_diagnostics/H04"),
  tables = file.path(root, "artifacts/09_tables/H04")
)

read_h04_csv <- function(directory, name) {
  readr::read_csv(
    file.path(roots[[directory]], name),
    show_col_types = FALSE,
    na = ""
  )
}
without_mundlak <- function(data) {
  if (!"scenario_id" %in% names(data)) {
    return(data)
  }
  dplyr::filter(data, .data$scenario_id != "mundlak_within_between")
}

frame_path <- file.path(roots$model_data, "H04_model_frames.rds")
expected_frame_sha256 <-
  "09ac59a49b0177d9628c470d8c290c8f6373d416ea2581685460b2804b4c9082"
observed_frame_sha256 <- artifact_sha256(frame_path)
if (!identical(observed_frame_sha256, expected_frame_sha256)) {
  h04_abort(
    "The accepted H04 model-frame archive drifted: expected %s, observed %s",
    expected_frame_sha256,
    observed_frame_sha256
  )
}

message("Reading the accepted frozen H04 primary frames")
frames <- readRDS(frame_path)
if (
  !all(c("near_eye", "chest") %in% names(frames$main)) ||
    nrow(frames$main$near_eye) != 17266L ||
    nrow(frames$main$chest) != 21071L ||
    dplyr::n_distinct(frames$main$near_eye$analysis_hour_id) != 16526L ||
    dplyr::n_distinct(frames$main$chest$analysis_hour_id) != 20128L
) {
  h04_abort("The accepted H04 primary frames failed their cardinality contract")
}

mundlak_frames <- list(
  near_eye = h04_add_mundlak_proportions(frames$main$near_eye),
  chest = h04_add_mundlak_proportions(frames$main$chest)
)
mundlak_support <- dplyr::bind_rows(
  h04_mundlak_support(mundlak_frames$near_eye, "Near-eye"),
  h04_mundlak_support(mundlak_frames$chest, "Chest")
) |>
  dplyr::arrange(
    factor(.data$placement, levels = c("Near-eye", "Chest")),
    .data$display_order
  )

message("Fitting H04 Mundlak within/between sensitivity models")
spec <- h04_specification()
formula <- h04_formula_set()$secondary_mundlak_audit
mundlak_results <- list(
  near_eye = h04_fit_additive_run(
    mundlak_frames$near_eye,
    "mundlak__near_eye",
    "mundlak_within_between",
    "Near-eye",
    working_power = spec$working_tweedie_power,
    formula = formula
  ),
  chest = h04_fit_additive_run(
    mundlak_frames$chest,
    "mundlak__chest",
    "mundlak_within_between",
    "Chest",
    working_power = spec$working_tweedie_power,
    formula = formula
  )
)

mundlak_estimands <- dplyr::bind_rows(lapply(
  mundlak_results,
  `[[`,
  "estimands"
))
mundlak_tests <- dplyr::bind_rows(lapply(mundlak_results, `[[`, "tests"))
mundlak_diagnostics <- dplyr::bind_rows(lapply(
  mundlak_results,
  `[[`,
  "diagnostics"
))
mundlak_samples <- dplyr::bind_rows(lapply(mundlak_results, `[[`, "sample"))
mundlak_between <- dplyr::bind_rows(
  h04_mundlak_between_estimands(mundlak_results$near_eye$bundle) |>
    dplyr::mutate(
      placement = "Near-eye",
      scenario_id = "mundlak_within_between",
      .before = 1
    ),
  h04_mundlak_between_estimands(mundlak_results$chest$bundle) |>
    dplyr::mutate(
      placement = "Chest",
      scenario_id = "mundlak_within_between",
      .before = 1
    )
)
mundlak_between_omnibus <- dplyr::bind_rows(
  h04_mundlak_between_omnibus(mundlak_results$near_eye$bundle) |>
    dplyr::mutate(
      placement = "Near-eye",
      scenario_id = "mundlak_within_between",
      .before = 1
    ),
  h04_mundlak_between_omnibus(mundlak_results$chest$bundle) |>
    dplyr::mutate(
      placement = "Chest",
      scenario_id = "mundlak_within_between",
      .before = 1
    )
)

primary_estimands <- read_h04_csv(
  "tables",
  "H04_primary_category_estimands.csv"
)
reference_estimands <- primary_estimands |>
  dplyr::select(
    .data$placement,
    .data$activity_code,
    primary_ratio = .data$ratio_to_home,
    primary_conf_low = .data$ratio_conf_low,
    primary_conf_high = .data$ratio_conf_high,
    primary_p_adjusted = .data$p_adjusted
  )
mundlak_comparison <- mundlak_estimands |>
  dplyr::left_join(
    reference_estimands,
    by = c("placement", "activity_code"),
    relationship = "many-to-one"
  ) |>
  dplyr::mutate(
    ratio_relative_change_percent = 100 *
      (.data$ratio_to_home / .data$primary_ratio - 1),
    direction_concordant = dplyr::if_else(
      .data$inferential_role == "NAMED_VERSUS_HOME",
      sign(log(.data$ratio_to_home)) == sign(log(.data$primary_ratio)),
      NA
    ),
    primary_ratio_inside_sensitivity_interval = .data$primary_ratio >=
      .data$ratio_conf_low &
      .data$primary_ratio <= .data$ratio_conf_high,
    stability = dplyr::case_when(
      .data$inferential_role != "NAMED_VERSUS_HOME" ~ "not_in_claim_family",
      !is.finite(.data$ratio_to_home) ~ "non_estimable",
      .data$direction_concordant &
        abs(.data$ratio_relative_change_percent) <= 25 ~ "stable",
      .data$direction_concordant ~ "magnitude_shift",
      TRUE ~ "direction_shift"
    )
  )

primary_mundlak_tests <- mundlak_tests |>
  dplyr::filter(.data$decision_role == "PRIMARY")
if (
  !all(mundlak_diagnostics$converged) ||
    !all(mundlak_diagnostics$full_rank) ||
    !all(mundlak_diagnostics$finite_coefficients) ||
    !all(mundlak_diagnostics$covariance_finite) ||
    !all(mundlak_diagnostics$covariance_positive_definite) ||
    !all(primary_mundlak_tests$status == "ESTIMABLE") ||
    !all(mundlak_between_omnibus$status == "ESTIMABLE")
) {
  h04_abort("The H04 Mundlak sensitivity failed its structural gate")
}

message("Appending H04-owned sensitivity artifacts")
formula_registry <- tibble::tibble(
  formula_id = names(h04_formula_set()),
  formula = vapply(h04_formula_set(), h04_formula_text, character(1))
)
run_registry <- read_h04_csv(
  "model_data",
  "H04_sensitivity_run_registry.csv"
) |>
  without_mundlak()
if (!"formula_id" %in% names(run_registry)) {
  run_registry$formula_id <- "primary_full"
}
run_registry <- dplyr::bind_rows(
  run_registry,
  tibble::tribble(
    ~run_id,
    ~scenario_id,
    ~placement,
    ~frame_id,
    ~working_power,
    ~formula_id,
    "mundlak__near_eye",
    "mundlak_within_between",
    "Near-eye",
    "mundlak_near",
    spec$working_tweedie_power,
    "secondary_mundlak_audit",
    "mundlak__chest",
    "mundlak_within_between",
    "Chest",
    "mundlak_chest",
    spec$working_tweedie_power,
    "secondary_mundlak_audit"
  )
)
frame_index <- dplyr::bind_rows(
  read_h04_csv("model_data", "H04_model_frame_index.csv") |>
    without_mundlak(),
  mundlak_samples
)
all_estimands <- dplyr::bind_rows(
  read_h04_csv("tables", "H04_all_category_estimands.csv") |>
    without_mundlak(),
  mundlak_estimands
)
sensitivity_tests <- dplyr::bind_rows(
  read_h04_csv("tables", "H04_sensitivity_omnibus_tests.csv") |>
    without_mundlak(),
  mundlak_tests
)
sensitivity_comparison <- dplyr::bind_rows(
  read_h04_csv("tables", "H04_sensitivity_comparison.csv") |>
    without_mundlak(),
  mundlak_comparison
)
model_diagnostics <- dplyr::bind_rows(
  read_h04_csv("diagnostics", "H04_model_diagnostics.csv") |>
    without_mundlak(),
  mundlak_diagnostics
)
model_objects <- readRDS(file.path(
  roots$models,
  "H04_additive_model_objects.rds"
))
model_objects$sensitivities$mundlak__near_eye <-
  mundlak_results$near_eye$bundle
model_objects$sensitivities$mundlak__chest <-
  mundlak_results$chest$bundle

write_csv_artifact(
  formula_registry,
  file.path(roots$model_data, "H04_formula_registry.csv"),
  producer
)
write_csv_artifact(
  run_registry,
  file.path(roots$model_data, "H04_sensitivity_run_registry.csv"),
  producer
)
write_csv_artifact(
  frame_index,
  file.path(roots$model_data, "H04_model_frame_index.csv"),
  producer
)
write_rds_artifact(
  model_objects,
  file.path(roots$models, "H04_additive_model_objects.rds"),
  producer
)
write_csv_artifact(
  model_diagnostics,
  file.path(roots$diagnostics, "H04_model_diagnostics.csv"),
  producer
)
write_csv_artifact(
  mundlak_support,
  file.path(roots$diagnostics, "H04_mundlak_activity_support.csv"),
  producer
)
write_csv_artifact(
  all_estimands,
  file.path(roots$tables, "H04_all_category_estimands.csv"),
  producer
)
write_csv_artifact(
  sensitivity_tests,
  file.path(roots$tables, "H04_sensitivity_omnibus_tests.csv"),
  producer
)
write_csv_artifact(
  sensitivity_comparison,
  file.path(roots$tables, "H04_sensitivity_comparison.csv"),
  producer
)
write_csv_artifact(
  mundlak_between,
  file.path(
    roots$tables,
    "H04_mundlak_between_participant_estimands.csv"
  ),
  producer
)
write_csv_artifact(
  mundlak_between_omnibus,
  file.path(
    roots$tables,
    "H04_mundlak_between_participant_omnibus.csv"
  ),
  producer
)

message("H04 Mundlak sensitivity completed from the accepted frozen frames")
