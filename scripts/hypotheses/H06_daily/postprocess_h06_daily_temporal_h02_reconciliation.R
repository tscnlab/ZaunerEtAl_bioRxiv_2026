#!/usr/bin/env Rscript

# Reconcile the corrected H02-aligned H06-daily temporal pilot after the
# bounded work/free basis-capacity sensitivity. This script reads frozen
# pilot artifacts only; it does not refit a model or extract associations.

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

required_packages <- c("digest", "dplyr", "readr", "tibble")
missing_packages <- required_packages[!vapply(
  required_packages,
  requireNamespace,
  logical(1),
  quietly = TRUE
)]
if (length(missing_packages) > 0L) {
  stop(
    "Missing synchronized project package(s): ",
    paste(missing_packages, collapse = ", "),
    call. = FALSE
  )
}
if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("Temporal reconciliation requires R 4.6.1", call. = FALSE)
}

source(file.path(
  root,
  "scripts/hypotheses/H06_daily/h06_daily_contract.R"
))

roots <- h06d_artifact_roots(root)
producer <- paste0(
  "scripts/hypotheses/H06_daily/",
  "postprocess_h06_daily_temporal_h02_reconciliation.R"
)
sha256 <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE)
}
relative_to_root <- function(path) {
  substring(path, nchar(root) + 2L)
}
read_csv <- function(path) {
  readr::read_csv(path, show_col_types = FALSE, na = "")
}
write_csv <- function(data, path) {
  readr::write_csv(data, path, na = "")
  invisible(path)
}
verify_manifest <- function(path) {
  manifest <- read_csv(path)
  observed <- vapply(
    file.path(root, manifest$relative_path),
    sha256,
    character(1)
  )
  if (!identical(unname(observed), manifest$sha256)) {
    h06d_abort("Manifest verification failed: %s", relative_to_root(path))
  }
  manifest
}

selected_manifests <- file.path(
  roots$manifests,
  c(
    "H06_daily_temporal_h02_input_manifest.csv",
    "H06_daily_temporal_h02_code_manifest.csv",
    "H06_daily_temporal_h02_output_manifest.csv"
  )
)
basis_manifests <- file.path(
  roots$manifests,
  c(
    "H06_daily_temporal_h02_basis_repair_input_manifest.csv",
    "H06_daily_temporal_h02_basis_repair_code_manifest.csv",
    "H06_daily_temporal_h02_basis_repair_output_manifest.csv"
  )
)
invisible(lapply(c(selected_manifests, basis_manifests), verify_manifest))

artifact <- function(stage, file) {
  file.path(root, "artifacts", stage, "H06_daily", file)
}
component_path <- artifact(
  "08_diagnostics",
  "H06_daily_temporal_h02_component_diagnostics.csv"
)
original_verdict_path <- artifact(
  "08_diagnostics",
  "H06_daily_temporal_h02_diagnostic_verdict.csv"
)
support_path <- artifact(
  "08_diagnostics",
  "H06_daily_temporal_h02_support_overall.csv"
)
context_path <- artifact(
  "08_diagnostics",
  "H06_daily_temporal_h02_context_cells.csv"
)
smooth_path <- artifact(
  "08_diagnostics",
  "H06_daily_temporal_h02_smooth_registry.csv"
)
identifiability_path <- artifact(
  "08_diagnostics",
  "H06_daily_temporal_h02_identifiability_screen.csv"
)
closure_path <- artifact(
  "08_diagnostics",
  "H06_daily_temporal_h02_global_closure.csv"
)
site_acf_path <- artifact(
  "08_diagnostics",
  "H06_daily_temporal_h02_site_residual_acf.csv"
)
runtime_path <- artifact(
  "08_diagnostics",
  "H06_daily_temporal_h02_runtime.csv"
)
basis_comparison_path <- artifact(
  "08_diagnostics",
  "H06_daily_temporal_h02_basis_repair_comparison.csv"
)
basis_diagnostics_path <- artifact(
  "08_diagnostics",
  "H06_daily_temporal_h02_basis_repair_model_diagnostics.csv"
)
basis_runtime_path <- artifact(
  "08_diagnostics",
  "H06_daily_temporal_h02_basis_repair_runtime.csv"
)

component <- read_csv(component_path)
original_verdict <- read_csv(original_verdict_path)
support <- read_csv(support_path)
context <- read_csv(context_path)
smooth <- read_csv(smooth_path)
identifiability <- read_csv(identifiability_path)
closure <- read_csv(closure_path)
site_acf <- read_csv(site_acf_path)
runtime <- read_csv(runtime_path)
basis <- read_csv(basis_comparison_path)
basis_diagnostics <- read_csv(basis_diagnostics_path)
basis_runtime <- read_csv(basis_runtime_path)

failed_diagnostic_domains <- original_verdict |>
  dplyr::filter(
    .data$domain != "Overall pilot gate",
    .data$status == "FAIL"
  ) |>
  dplyr::pull("domain")
stopifnot(
  nrow(component) == 1L,
  nrow(support) == 1L,
  nrow(basis) == 1L,
  identical(failed_diagnostic_domains, "Basis capacity"),
  identical(
    basis$basis_repair_status,
    "K12_RETAINED_AFTER_K16_SENSITIVITY"
  ),
  isTRUE(basis$curve_stability_pass),
  isTRUE(basis$global_k_check_pass),
  isTRUE(basis$diagnostic_fit_pass),
  isTRUE(basis$exact_same_rows),
  all(smooth$xt_is_null),
  identical(component$convergence, "full convergence"),
  component$final_warning_count == 0L,
  abs(component$final_standardized_residual_lag1) < 0.20,
  max(abs(site_acf$residual_lag1)) < 0.30,
  max(identifiability$fitted_term_multiple_r_squared) < 0.80,
  all(closure$cyclic_closure_pass)
)

minimum_context_days <- min(context$participant_days)
maximum_site_lag1 <- max(abs(site_acf$residual_lag1))
maximum_identifiability_r2 <- max(
  identifiability$fitted_term_multiple_r_squared
)
reconciled <- tibble::tribble(
  ~domain, ~evidence, ~assessment, ~implication,
  "Frame and context support",
  sprintf(
    paste0(
      "%d bins; %d days; %d participants; %d sites; ",
      "smallest work/free-by-activity cell %d days"
    ),
    support$observations_30_minute,
    support$participant_days,
    support$participants,
    support$sites,
    minimum_context_days
  ),
  "ACCEPTABLE",
  "Retain the exact complete-core near-eye pilot frame",
  "Formula and H02 basis inheritance",
  sprintf(
    "Exact selected formula; %d of %d fitted smooths have xt = NULL",
    sum(smooth$xt_is_null),
    nrow(smooth)
  ),
  "ACCEPTABLE",
  paste(
    "Only global clock time is cyclic; retain default thin-plate",
    "marginals for sz, fs, and sleep terms"
  ),
  "Convergence and smoothing Hessian",
  sprintf(
    paste0(
      "%s; warnings %d; Hessian minimum relative eigenvalue %.2e"
    ),
    component$convergence,
    component$final_warning_count,
    component$smoothing_hessian_minimum_relative_eigenvalue
  ),
  "ACCEPTABLE_WITH_NUMERICAL_TOLERANCE",
  paste(
    "The tiny negative Hessian eigenvalue is at floating-point tolerance;",
    "retain with explicit disclosure"
  ),
  "Basis capacity",
  sprintf(
    paste0(
      "work/free k=12 versus k=16: max link difference %.3f, ",
      "RMSE %.3f, correlation %.3f; global k-index %.3f (p=%.4f)"
    ),
    basis$maximum_absolute_work_contrast_difference_link,
    basis$work_contrast_difference_rmse_link,
    basis$work_contrast_curve_correlation,
    basis$selected_global_k_index,
    basis$selected_global_k_p_value
  ),
  "ACCEPTABLE_AFTER_BOUNDED_SENSITIVITY",
  "Retain k=12; the k=16 model is diagnostic only",
  "Residual distribution and scale pattern",
  sprintf(
    "QQ correlation %.3f; Spearman correlation of |residual| with fitted %.3f",
    component$standardized_residual_qq_correlation,
    component$absolute_residual_fitted_spearman
  ),
  "ACCEPTABLE_FOR_EXPLORATORY_MODEL",
  "Retain the shifted-log Gaussian architecture and report limitations",
  "Residual temporal dependence",
  sprintf(
    "pooled lag-1 %.3f; maximum absolute site lag-1 %.3f",
    component$final_standardized_residual_lag1,
    maximum_site_lag1
  ),
  "ACCEPTABLE",
  "Retain the frame-specific fixed working AR(1) correction",
  "Fixed-term identifiability screen",
  sprintf(
    "maximum bounded fitted-term multiple R-squared %.3f",
    maximum_identifiability_r2
  ),
  "ACCEPTABLE",
  "Retain the jointly adjusted context model",
  "Global cyclic closure",
  sprintf(
    "absolute 24:00 versus 00:00 link difference %.2e",
    closure$absolute_endpoint_difference_link
  ),
  "ACCEPTABLE",
  "Retain the cyclic global clock smooth",
  "Overall corrected pilot gate",
  "All eight prespecified diagnostic domains are acceptable after the bounded basis sensitivity",
  "ACCEPTABLE_FOR_EFFECT_EXTRACTION_AFTER_APPROVAL",
  paste(
    "No association has been extracted or accepted; stop at H06-D-G2P-H02",
    "for explicit production approval"
  )
)

gate_contract <- tibble::tribble(
  ~decision_id, ~decision, ~proposed_contract, ~status,
  "H06-D-G2P-H02-01",
  "Response and structural model",
  paste(
    "Use 30-minute arithmetic-mean melEDI, log10(Y + 0.1 lx), Gaussian",
    "identity bam; only the global time smooth is cyclic"
  ),
  "CLOSED_BY_AUTHOR_CONFIRMATION",
  "H06-D-G2P-H02-02",
  "Context estimands",
  paste(
    "Extract Free day minus Work day and Active minus Sedentary profile",
    "contrasts, plus +1 h within- and between-participant sleep-duration",
    "association functions; use observational language"
  ),
  "PENDING_APPROVAL",
  "H06-D-G2P-H02-03",
  "Scale and uncertainty",
  paste(
    "Report transformed-scale curves, ratios for Y + 0.1, and inverse-",
    "transformed conditional-median-like profiles with pointwise and",
    "simultaneous 95% intervals; never call these raw-scale E[Y]"
  ),
  "PENDING_APPROVAL",
  "H06-D-G2P-H02-04",
  "Exploratory multiplicity",
  paste(
    "Use one separate four-test BH family for work/free, activity,",
    "within-participant sleep, and between-participant sleep whole-curve",
    "tests; do not mix it with preregistration-aligned daily families"
  ),
  "PENDING_APPROVAL",
  "H06-D-G2P-H02-05",
  "Placement and scenario batch",
  paste(
    "Authorize near-eye/chest all available, paired/common near-eye/chest,",
    "and gap-timing-unaware near-eye/chest frames; each frame re-estimates",
    "rho and reports its exact sample"
  ),
  "PENDING_RUNTIME_APPROVAL",
  "H06-D-G2P-H02-06",
  "Heavy diagnostics and resampling",
  paste(
    "Withhold site-deletion or other heavy resampling until a bounded",
    "production-code pilot measures 50/100 resamples or representative",
    "deletions and receives separate approval"
  ),
  "WITHHELD_PENDING_PILOT",
  "H06-D-G2P-H02-07",
  "MDER",
  "Exclude MDER until the coordinator supplies the replacement manifest and targeted repinning instructions",
  "UPSTREAM_HOLD"
)

main_pilot_seconds <- runtime$observed_or_projected_seconds[
  runtime$scope == "Corrected near-eye bounded pilot"
]
six_frame_seconds <- runtime$observed_or_projected_seconds[
  runtime$scope == "Six declared placement/scenario frames"
]
basis_seconds <- basis_runtime$observed_seconds
reconciled_runtime <- tibble::tribble(
  ~scope, ~fits, ~seconds, ~minutes, ~basis, ~authorization,
  "Corrected near-eye pilot plus basis sensitivity",
  3L,
  main_pilot_seconds + basis_seconds,
  (main_pilot_seconds + basis_seconds) / 60,
  "Measured wall time, including diagnostics and two fixed-seed k checks",
  "COMPLETED",
  "Six-frame base-model batch",
  12L,
  six_frame_seconds,
  six_frame_seconds / 60,
  "Linear fit-only projection from two bam fits per frame",
  "NOT_AUTHORIZED",
  "Prediction, simultaneous-interval, or deletion work",
  NA_integer_,
  NA_real_,
  NA_real_,
  "Not yet timed; bounded production-code pilot required before heavy work",
  "NOT_AUTHORIZED"
)

reconciled_path <- artifact(
  "08_diagnostics",
  "H06_daily_temporal_h02_reconciled_verdict.csv"
)
gate_path <- artifact(
  "08_diagnostics",
  "H06_daily_temporal_h02_reconciled_gate_contract.csv"
)
reconciled_runtime_path <- artifact(
  "08_diagnostics",
  "H06_daily_temporal_h02_reconciled_runtime.csv"
)
write_csv(reconciled, reconciled_path)
write_csv(gate_contract, gate_path)
write_csv(reconciled_runtime, reconciled_runtime_path)

direct_inputs <- c(
  component_path,
  original_verdict_path,
  support_path,
  context_path,
  smooth_path,
  identifiability_path,
  closure_path,
  site_acf_path,
  runtime_path,
  basis_comparison_path,
  basis_diagnostics_path,
  basis_runtime_path,
  selected_manifests,
  basis_manifests
)
input_manifest <- tibble::tibble(
  relative_path = vapply(direct_inputs, relative_to_root, character(1)),
  sha256 = vapply(direct_inputs, sha256, character(1)),
  bytes = unname(file.info(direct_inputs)$size)
)
code_paths <- c(
  "scripts/hypotheses/H06_daily/h06_daily_contract.R",
  producer
)
code_manifest <- tibble::tibble(
  relative_path = code_paths,
  sha256 = vapply(file.path(root, code_paths), sha256, character(1)),
  bytes = unname(file.info(file.path(root, code_paths))$size)
)
software_manifest <- tibble::tibble(
  component = c("R", required_packages),
  version = c(
    as.character(getRversion()),
    vapply(
      required_packages,
      function(package) {
        as.character(utils::packageVersion(package))
      },
      character(1)
    )
  )
)
input_manifest_path <- file.path(
  roots$manifests,
  "H06_daily_temporal_h02_reconciliation_input_manifest.csv"
)
code_manifest_path <- file.path(
  roots$manifests,
  "H06_daily_temporal_h02_reconciliation_code_manifest.csv"
)
software_manifest_path <- file.path(
  roots$manifests,
  "H06_daily_temporal_h02_reconciliation_software_manifest.csv"
)
write_csv(input_manifest, input_manifest_path)
write_csv(code_manifest, code_manifest_path)
write_csv(software_manifest, software_manifest_path)

outputs <- c(
  reconciled_path,
  gate_path,
  reconciled_runtime_path,
  input_manifest_path,
  code_manifest_path,
  software_manifest_path
)
output_manifest <- tibble::tibble(
  relative_path = vapply(outputs, relative_to_root, character(1)),
  sha256 = vapply(outputs, sha256, character(1)),
  bytes = unname(file.info(outputs)$size),
  producer = producer,
  r_version = as.character(getRversion())
)
output_manifest_path <- file.path(
  roots$manifests,
  "H06_daily_temporal_h02_reconciliation_output_manifest.csv"
)
write_csv(output_manifest, output_manifest_path)

message(
  "H06-D-G2P-H02 reconciliation: ",
  reconciled$assessment[reconciled$domain == "Overall corrected pilot gate"]
)
