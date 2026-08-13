# Post-process the frozen H06-daily Stage 2 pilot; this script never refits.

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

library(mgcv)
library(dplyr)

source(file.path(
  root,
  "scripts/hypotheses/H06_daily/h06_daily_contract.R"
))
source(file.path(
  root,
  "scripts/hypotheses/H06_daily/h06_daily_data.R"
))
source(file.path(
  root,
  "scripts/hypotheses/H06_daily/h06_daily_modeling.R"
))

if (!identical(as.character(getRversion()), "4.6.1")) {
  h06d_abort("H06-daily pilot post-processing requires R 4.6.1")
}

roots <- h06d_artifact_roots(root)
temporal_path <- file.path(
  roots$models,
  "H06_daily_30_minute_temporal_family_pilot.rds"
)
daily_path <- file.path(
  roots$models,
  "H06_daily_stage2_pilot_daily_models.rds"
)
if (!file.exists(temporal_path) || !file.exists(daily_path)) {
  h06d_abort("Frozen H06-daily pilot model checkpoints are missing")
}
temporal_checkpoint <- readRDS(temporal_path)
daily_checkpoint <- readRDS(daily_path)

restore_entry <- function(entry) {
  list(
    data = entry$data,
    formula = entry$formula,
    rho = entry$rho,
    preliminary = list(
      elapsed_seconds = entry$preliminary_elapsed_seconds,
      warnings = entry$preliminary_warnings
    ),
    final = list(
      value = entry$model,
      elapsed_seconds = entry$final_elapsed_seconds,
      warnings = entry$final_warnings
    )
  )
}

one <- restore_entry(temporal_checkpoint$one_part)
one$tweedie_power <- temporal_checkpoint$one_part$tweedie_power
occurrence <- restore_entry(temporal_checkpoint$occurrence)
positive <- restore_entry(temporal_checkpoint$positive)
temporal <- list(
  one_part = one,
  occurrence = occurrence,
  positive = positive
)

diagnostics <- h06d_temporal_pilot_diagnostics(temporal)
component_path <- file.path(
  roots$diagnostics,
  "H06_daily_30_minute_temporal_component_diagnostics.csv"
)
readr::write_csv(diagnostics$component, component_path, na = "")

closure <- dplyr::bind_rows(
  h06d_temporal_closure(
    one$final$value,
    one$data,
    "one_part_tweedie",
    "conditional_mean"
  ),
  h06d_temporal_closure(
    occurrence$final$value,
    occurrence$data,
    "two_part",
    "occurrence"
  ),
  h06d_temporal_closure(
    positive$final$value,
    positive$data,
    "two_part",
    "positive_magnitude"
  )
)
closure_path <- file.path(
  roots$diagnostics,
  "H06_daily_30_minute_temporal_cyclic_closure.csv"
)
readr::write_csv(closure, closure_path, na = "")

message("Computing bounded fitted-term concurvity fallback; no model refit")
concurvity <- dplyr::bind_rows(
  h06d_term_concurvity_fallback(
    one$final$value,
    "one_part_tweedie",
    "conditional_mean",
    seed = 61062026L
  ),
  h06d_term_concurvity_fallback(
    occurrence$final$value,
    "two_part",
    "occurrence",
    seed = 61062027L
  ),
  h06d_term_concurvity_fallback(
    positive$final$value,
    "two_part",
    "positive_magnitude",
    seed = 61062028L
  )
)
concurvity_path <- file.path(
  roots$diagnostics,
  "H06_daily_30_minute_temporal_concurvity_fallback.csv"
)
readr::write_csv(concurvity, concurvity_path, na = "")

site_acf <- dplyr::bind_rows(
  h06d_site_residual_acf(
    one,
    "one_part_tweedie",
    "conditional_mean"
  ),
  h06d_site_residual_acf(
    occurrence,
    "two_part",
    "occurrence"
  ),
  h06d_site_residual_acf(
    positive,
    "two_part",
    "positive_magnitude"
  )
)
site_acf_path <- file.path(
  roots$diagnostics,
  "H06_daily_30_minute_temporal_site_residual_acf.csv"
)
readr::write_csv(site_acf, site_acf_path, na = "")

k_check <- diagnostics$k_check
calibration <- diagnostics$calibration

component_evidence <- function(candidate, part) {
  diagnostics$component |>
    dplyr::filter(
      .data$candidate_id == candidate,
      .data$component == part
    ) |>
    dplyr::slice(1L)
}

k_evidence <- function(candidate, part) {
  rows <- k_check |>
    dplyr::filter(
      .data$candidate_id == candidate,
      .data$component == part,
      is.finite(.data$k_index)
    )
  tibble::tibble(
    minimum_k_index = min(rows$k_index),
    maximum_edf_fraction = max(rows$effective_df / rows$k_prime)
  )
}

acf_evidence <- function(candidate, part) {
  pooled <- component_evidence(candidate, part)$standardized_residual_lag1
  sites <- site_acf |>
    dplyr::filter(
      .data$candidate_id == candidate,
      .data$component == part
    )
  tibble::tibble(
    pooled = pooled,
    maximum_site_absolute = max(abs(sites$residual_lag1), na.rm = TRUE)
  )
}

zero_calibration <- calibration |>
  dplyr::filter(grepl("probability", .data$component)) |>
  dplyr::summarise(
    minimum_ratio = min(.data$observed_to_predicted),
    maximum_ratio = max(.data$observed_to_predicted),
    .by = "component"
  )
positive_calibration <- calibration |>
  dplyr::filter(.data$component == "two_part_positive_magnitude_mean") |>
  dplyr::summarise(
    minimum_ratio = min(.data$observed_to_predicted),
    maximum_ratio = max(.data$observed_to_predicted)
  )

one_component <- component_evidence("one_part_tweedie", "conditional_mean")
occ_component <- component_evidence("two_part", "occurrence")
positive_component <- component_evidence("two_part", "positive_magnitude")
one_k <- k_evidence("one_part_tweedie", "mean")
occ_k <- k_evidence("two_part", "occurrence")
positive_k <- k_evidence("two_part", "positive_magnitude")
one_acf <- acf_evidence("one_part_tweedie", "conditional_mean")
occ_acf <- acf_evidence("two_part", "occurrence")
positive_acf <- acf_evidence("two_part", "positive_magnitude")
one_zero <- zero_calibration |>
  dplyr::filter(.data$component == "one_part_tweedie_zero_probability")
two_zero <- zero_calibration |>
  dplyr::filter(
    .data$component == "two_part_positive_occurrence_probability"
  )

temporal_verdict <- tibble::tribble(
  ~candidate, ~domain, ~evidence, ~status, ~consequence, ~required_action,
  "One-part Tweedie", "Frame and support",
  sprintf(
    "%s bins; %s participant-days; %s participants; %s sites; %.1f%% zeros",
    format(one_component$observations, big.mark = ","),
    one_component$participant_days,
    one_component$participants,
    one_component$sites,
    100 * one_component$observed_zero_fraction
  ),
  "PASS", "Exact requested near-eye frame is identified", "None",
  "One-part Tweedie", "Convergence and Hessian",
  sprintf(
    "%s; Hessian min %.2e (relative %.2e)",
    one_component$convergence,
    one_component$smoothing_hessian_minimum_eigenvalue,
    one_component$smoothing_hessian_minimum_relative_eigenvalue
  ),
  "FAIL", "Strict positive-definite smoothing Hessian rule is not met",
  "Do not accept one-part production inference",
  "One-part Tweedie", "Basis capacity",
  sprintf(
    "minimum deterministic k-index %.3f; maximum edf/k-prime %.3f",
    one_k$minimum_k_index,
    one_k$maximum_edf_fraction
  ),
  "FAIL", "Time and sleep functions press against k = 12",
  "Increase k in a bounded repair pilot",
  "One-part Tweedie", "Zero calibration",
  sprintf(
    "observed %.3f; working %.3f; decile ratios %.3f to %.3f",
    one_component$observed_zero_fraction,
    one_component$working_zero_fraction,
    one_zero$minimum_ratio,
    one_zero$maximum_ratio
  ),
  "FAIL", "Compound Tweedie zero coupling is badly miscalibrated",
  "Reject one-part Tweedie as the production family",
  "One-part Tweedie", "Residual dependence after AR",
  sprintf(
    "pooled lag-1 %.3f; maximum site |lag-1| %.3f",
    one_acf$pooled,
    one_acf$maximum_site_absolute
  ),
  "FAIL", "Working AR correction leaves material serial dependence",
  "Do not make curve-wide inferential claims",
  "One-part Tweedie", "Cyclic closure",
  sprintf(
    "maximum 24:00 versus 00:00 link difference %.2e",
    closure$maximum_absolute_endpoint_difference_link[
      closure$candidate_id == "one_part_tweedie"
    ]
  ),
  "PASS", "All declared population time components close at midnight",
  "None",
  "Two-part occurrence", "Convergence and Hessian",
  sprintf(
    "%s; Hessian min %.2e",
    occ_component$convergence,
    occ_component$smoothing_hessian_minimum_eigenvalue
  ),
  "PASS", "Numerical gate is met", "None",
  "Two-part occurrence", "Basis capacity",
  sprintf(
    "minimum deterministic k-index %.3f; maximum edf/k-prime %.3f",
    occ_k$minimum_k_index,
    occ_k$maximum_edf_fraction
  ),
  "WARN", "Global clock smooth is high but not k-index deficient",
  "Recheck at k = 16",
  "Two-part occurrence", "Occurrence calibration",
  sprintf(
    "global zero fraction reproduced; positive-probability decile ratios %.3f to %.3f",
    two_zero$minimum_ratio,
    two_zero$maximum_ratio
  ),
  "FAIL", "Lowest predicted-probability bins remain miscalibrated",
  "Revise/check mean structure before production inference",
  "Two-part occurrence", "Residual dependence after AR",
  sprintf(
    "pooled lag-1 %.3f; maximum site |lag-1| %.3f",
    occ_acf$pooled,
    occ_acf$maximum_site_absolute
  ),
  "WARN", "Working AR correction remains incomplete",
  "Run a bounded rho/mean-structure sensitivity",
  "Two-part positive magnitude", "Convergence and Hessian",
  sprintf(
    "%s; Hessian min %.2e",
    positive_component$convergence,
    positive_component$smoothing_hessian_minimum_eigenvalue
  ),
  "PASS", "Numerical gate is met", "None",
  "Two-part positive magnitude", "Basis capacity",
  sprintf(
    "minimum deterministic k-index %.3f; maximum edf/k-prime %.3f",
    positive_k$minimum_k_index,
    positive_k$maximum_edf_fraction
  ),
  "FAIL", "Global time and sleep functions press against k = 12",
  "Increase k in a bounded repair pilot",
  "Two-part positive magnitude", "Positive-mean calibration",
  sprintf(
    "observed/predicted decile ratios %.3f to %.3f",
    positive_calibration$minimum_ratio,
    positive_calibration$maximum_ratio
  ),
  "WARN", "Highest fitted-mean decile is underpredicted",
  "Retain explicit upper-tail limitation and reassess at k = 16",
  "Two-part positive magnitude", "Residual dependence after AR",
  sprintf(
    "pooled lag-1 %.3f; maximum site |lag-1| %.3f",
    positive_acf$pooled,
    positive_acf$maximum_site_absolute
  ),
  "WARN", "Working AR correction remains incomplete",
  "Run a bounded rho/mean-structure sensitivity",
  "Two-part combined", "Cyclic closure",
  sprintf(
    "component maxima %.2e and %.2e on link scales",
    closure$maximum_absolute_endpoint_difference_link[
      closure$component == "occurrence"
    ],
    closure$maximum_absolute_endpoint_difference_link[
      closure$component == "positive_magnitude"
    ]
  ),
  "PASS", "Both components close at midnight", "None",
  "Two-part combined", "Pilot family decision",
  "Separates exact-zero occurrence from positive magnitude; current k = 12 fits retain calibration and residual-dependence failures",
  "RETAIN_ARCHITECTURE_REPAIR_SPECIFICATION",
  "More defensible than one-part Tweedie, but not acceptable for production effect inference yet",
  "Obtain author approval for a bounded k = 16 / correlation repair pilot"
)
temporal_verdict_path <- file.path(
  roots$diagnostics,
  "H06_daily_30_minute_temporal_diagnostic_verdict.csv"
)
readr::write_csv(temporal_verdict, temporal_verdict_path, na = "")

l10_one <- daily_checkpoint[["l10_one_part__fixed_site_additive"]]
l10_zero <- daily_checkpoint[["l10_two_part__zero_occurrence"]]
l10_positive <- daily_checkpoint[["l10_two_part__positive_magnitude"]]

l10_levels <- levels(l10_one$frame$work_free_day)
l10_sites <- levels(droplevels(l10_one$frame$site))
l10_grid <- tidyr::expand_grid(
  site = factor(l10_sites, levels = levels(l10_one$frame$site)),
  work_free_day = factor(l10_levels, levels = l10_levels),
  participant_key = factor(
    levels(l10_one$frame$participant_key)[[1L]],
    levels = levels(l10_one$frame$participant_key)
  )
)
one_log <- stats::predict(
  l10_one$model,
  newdata = l10_grid,
  re.form = NA
)
zero_probability <- stats::predict(
  l10_zero$model,
  newdata = l10_grid,
  type = "response",
  re.form = NA
)
positive_log <- stats::predict(
  l10_positive$model,
  newdata = l10_grid,
  re.form = NA
)

l10_predictions <- l10_grid |>
  dplyr::mutate(
    one_part_mean_lx = pmax(0, 10^as.numeric(one_log) - 0.1),
    two_part_mean_lx =
      (1 - as.numeric(zero_probability)) * 10^as.numeric(positive_log)
  ) |>
  dplyr::summarise(
    one_part_equal_site_mean_lx = mean(.data$one_part_mean_lx),
    two_part_equal_site_mean_lx = mean(.data$two_part_mean_lx),
    .by = "work_free_day"
  )
l10_ratios <- l10_predictions |>
  dplyr::summarise(
    one_part_free_vs_work_ratio =
      .data$one_part_equal_site_mean_lx[.data$work_free_day == "Free day"] /
      .data$one_part_equal_site_mean_lx[.data$work_free_day == "Work day"],
    two_part_free_vs_work_ratio =
      .data$two_part_equal_site_mean_lx[.data$work_free_day == "Free day"] /
      .data$two_part_equal_site_mean_lx[.data$work_free_day == "Work day"],
    direction_agrees =
      sign(log(.data$one_part_free_vs_work_ratio)) ==
      sign(log(.data$two_part_free_vs_work_ratio)),
    analysis_role = paste(
      "bounded zero-mass family pilot point comparison;",
      "no interval or production inference"
    )
  )
l10_comparison <- dplyr::bind_cols(
  l10_predictions |>
    tidyr::pivot_wider(
      names_from = "work_free_day",
      values_from = c(
        "one_part_equal_site_mean_lx",
        "two_part_equal_site_mean_lx"
      ),
      names_sep = "__"
    ),
  l10_ratios
)
l10_path <- file.path(
  roots$diagnostics,
  "H06_daily_l10_zero_mass_family_pilot.csv"
)
readr::write_csv(l10_comparison, l10_path, na = "")

daily_diagnostics <- readr::read_csv(
  file.path(
    roots$diagnostics,
    "H06_daily_stage2_pilot_daily_diagnostics.csv"
  ),
  show_col_types = FALSE
)
registered <- daily_diagnostics |>
  dplyr::filter(.data$model_id == "registered_random_site")
identity <- daily_diagnostics |>
  dplyr::filter(.data$pilot_id == "gaussian_identity")
l10_positive_diag <- daily_diagnostics |>
  dplyr::filter(
    .data$pilot_id == "l10_two_part",
    .data$model_id == "positive_magnitude"
  )
daily_verdict <- tibble::tribble(
  ~pilot_problem, ~evidence, ~status, ~required_action,
  "Signed random-site/random-slope benchmark",
  sprintf(
    "singular = %s; %s",
    registered$singular,
    registered$convergence_message
  ),
  "NON_ESTIMABLE",
  "Retain exact formula as benchmark; do not simplify or use as primary",
  "Fixed-site representative models",
  "All reduced/additive/heterogeneity representative fits converged without singularity",
  "PASS_PILOT",
  "Proceed only after production-batch approval",
  "Identity-Gaussian pre-sleep duration",
  sprintf("true-date residual lag-1 = %.3f", identity$residual_lag1),
  "AR1_TRIGGERED",
  "Fit the prespecified actual-date gap-aware AR counterpart in production",
  "L10 one-part versus two-part",
  sprintf(
    "13.3%% zeros; one-part ratio %.3f; two-part ratio %.3f; direction agrees = %s; positive-part residual lag-1 %.3f",
    l10_ratios$one_part_free_vs_work_ratio,
    l10_ratios$two_part_free_vs_work_ratio,
    l10_ratios$direction_agrees,
    l10_positive_diag$residual_lag1
  ),
  "RETAIN_TWO_PART_PILOT_NOT_FINAL",
  "Do not accept the one-part L10 family until the positive-part daily AR and full diagnostics are resolved"
)
daily_verdict_path <- file.path(
  roots$diagnostics,
  "H06_daily_stage2_pilot_daily_verdict.csv"
)
readr::write_csv(daily_verdict, daily_verdict_path, na = "")

code_paths <- c(
  "scripts/hypotheses/H06_daily/h06_daily_contract.R",
  "scripts/hypotheses/H06_daily/h06_daily_data.R",
  "scripts/hypotheses/H06_daily/h06_daily_modeling.R",
  "scripts/hypotheses/H06_daily/run_h06_daily_stage2_pilot.R",
  "scripts/hypotheses/H06_daily/postprocess_h06_daily_stage2_pilot.R"
)
code_manifest <- tibble::tibble(
  relative_path = code_paths,
  sha256 = vapply(
    file.path(root, code_paths),
    digest::digest,
    character(1),
    algo = "sha256",
    file = TRUE
  ),
  bytes = unname(file.info(file.path(root, code_paths))$size)
)
code_manifest_path <- file.path(
  roots$manifests,
  "H06_daily_stage2_pilot_code_manifest.csv"
)
readr::write_csv(code_manifest, code_manifest_path, na = "")

artifact_files <- unlist(lapply(roots, function(path) {
  list.files(path, full.names = TRUE, recursive = TRUE)
}), use.names = FALSE)
output_manifest_path <- file.path(
  roots$manifests,
  "H06_daily_stage2_pilot_output_manifest.csv"
)
artifact_files <- sort(setdiff(artifact_files, output_manifest_path))
output_manifest <- tibble::tibble(
  relative_path = sub(paste0("^", root, "/"), "", artifact_files),
  sha256 = vapply(
    artifact_files,
    digest::digest,
    character(1),
    algo = "sha256",
    file = TRUE
  ),
  bytes = unname(file.info(artifact_files)$size),
  modified_utc = format(
    file.info(artifact_files)$mtime,
    tz = "UTC",
    usetz = TRUE
  ),
  manifest_generated_by =
    "scripts/hypotheses/H06_daily/postprocess_h06_daily_stage2_pilot.R",
  r_version = as.character(getRversion())
)
readr::write_csv(output_manifest, output_manifest_path, na = "")

message(
  "H06-daily Stage 2 pilot post-processing complete; no model was refitted"
)
