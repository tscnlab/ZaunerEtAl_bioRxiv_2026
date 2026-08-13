#!/usr/bin/env Rscript

# Run the author-approved, one-fit H06_daily pre-sleep no-nugget AR diagnostic.
# This script does not open or modify L10 or MDER and does not run an
# independent-model refit, resampling, deletion diagnostics, or the remaining
# daily production grid.

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

required_packages <- c(
  "dplyr", "tibble", "readr", "digest", "lme4", "glmmTMB",
  "performance", "melidosData"
)
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
source(file.path(
  root,
  "scripts/hypotheses/H06_daily/h06_daily_daily_ar_repair.R"
))

if (!identical(as.character(getRversion()), "4.6.1")) {
  h06d_abort(
    "H06_daily no-nugget diagnostic requires R 4.6.1; found %s",
    as.character(getRversion())
  )
}
if (!identical(as.character(utils::packageVersion("glmmTMB")), "1.1.14")) {
  h06d_abort("H06_daily no-nugget diagnostic requires glmmTMB 1.1.14")
}
if (!identical(as.character(utils::packageVersion("melidosData")), "1.0.6")) {
  h06d_abort("H06_daily no-nugget diagnostic requires melidosData 1.0.6")
}

producer <- paste0(
  "scripts/hypotheses/H06_daily/",
  "run_h06_daily_pre_sleep_no_nugget_diagnostic.R"
)
roots <- h06d_artifact_roots(root)
invisible(lapply(roots, dir.create, recursive = TRUE, showWarnings = FALSE))

write_csv <- function(data, path) {
  readr::write_csv(data, path, na = "")
  invisible(path)
}
write_rds <- function(object, path) {
  saveRDS(object, path, version = 3)
  invisible(path)
}
sha256 <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE)
}
normalize_formula <- function(formula) {
  gsub("[[:space:]]+", " ", paste(deparse(formula), collapse = " "))
}

input_contract <- tibble::tribble(
  ~input_id, ~relative_path, ~expected_sha256, ~role,
  "metric_manifest",
  "artifacts/12_manifests/metric_artifacts.csv",
  "7bb2830c695e5600f0877acca500a187a040fe727a029bdb069f69099abe4f43",
  "current shared metric manifest",
  "base_manifest",
  "artifacts/12_manifests/base_model_data_artifacts.csv",
  "b6fa22836faee5243bb6ce1cc9dceab5d5403f94d688f8f74472a19dbf6e3e09",
  "current shared base-model-data manifest",
  "primary_near_eye_daily",
  "artifacts/06_model_data/base/metrics_glasses_participant_day_enriched.rds",
  "fb04a84f49a410f3474cc64ef97e91183db413197f5815f5dd83805a7d40b06e",
  "current near-eye participant-day source",
  "exercise_diary",
  "artifacts/06_model_data/normalized_inputs/exercisediary.rds",
  "5bffe44cdd9c65f3d1dc20575d10b3f0a403577f3cf9109e83cfea95a2ae7107",
  "immutable daily activity context loaded by the shared adapter",
  "sleep_diary",
  "artifacts/06_model_data/normalized_inputs/sleepdiaries.rds",
  "110819d74503c895170552c1f2214aca83de51cadd23bde7525aa821ee0b0e15",
  "immutable previous-night sleep context",
  "site_registry",
  "config/site_display_registry.csv",
  "3d669d459ecc27d3154bbb5ff5b0d64cb510805d486b45264443228c44a6d809",
  "submitted site order",
  "frozen_pre_sleep_frame",
  paste0(
    "artifacts/06_model_data/H06_daily/",
    "H06_daily_stage2_daily_ar_repair__pre_sleep_identity__frame.rds"
  ),
  "e96176090cdaea27c80c91ee5ff7099f0ec1419bf5d66b172f3c09dc89419f05",
  "unchanged author-approved 648-day diagnostic frame",
  "prior_repair_models",
  paste0(
    "artifacts/07_models/H06_daily/",
    "H06_daily_stage2_daily_ar_repair_pilot_models.rds"
  ),
  "024ca6d5f51d8d5e80ed3f597a4faf93c4ce96697cf88496f782a059f9b9fdf4",
  "frozen independent and failed free-dispersion AR references",
  "prior_repair_diagnostics",
  paste0(
    "artifacts/08_diagnostics/H06_daily/",
    "H06_daily_stage2_daily_ar_repair_pilot_model_diagnostics.csv"
  ),
  "825330baa4a459b35f66b425a8516447a4bda1e8286b0fe4284d8533168d9a5e",
  "frozen diagnostic reference",
  "prior_repair_verdict",
  paste0(
    "artifacts/08_diagnostics/H06_daily/",
    "H06_daily_stage2_daily_ar_repair_pilot_verdict.csv"
  ),
  "dd601372727ded8442c5a5b4f8b03322c6e867c843104a86b89a300a7cd0f967",
  "frozen acceptance-gate reference",
  "prior_repair_effects",
  paste0(
    "artifacts/09_tables/H06_daily/",
    "H06_daily_stage2_daily_ar_repair_pilot_effect_stability.csv"
  ),
  "c7349235431a34fe951ef5d6b56ada73ebee090ebb011524a3f91950acd64396",
  "frozen engineering effect reference",
  "prior_repair_output_manifest",
  paste0(
    "artifacts/12_manifests/H06_daily/",
    "H06_daily_stage2_daily_ar_repair_pilot_output_manifest.csv"
  ),
  "39a9a8d56bbe93138b646e2f63dc6e9627d782be090ee55a88c4246ad769b400",
  "frozen repair-pilot output identity",
  "author_authorization",
  paste0(
    "audit/hypotheses/H06_daily/",
    "H06_daily_pre_sleep_no_nugget_authorization.md"
  ),
  "0fa00e9ca5100b801538665290040795851ab619651d3a3a903d931a59c31a73",
  "immutable author authorization and execution boundary"
) |>
  dplyr::mutate(
    observed_sha256 = vapply(
      file.path(.env$root, .data$relative_path),
      sha256,
      character(1)
    ),
    bytes = unname(file.info(
      file.path(.env$root, .data$relative_path)
    )$size),
    verified = .data$expected_sha256 == .data$observed_sha256
  )
if (!all(input_contract$verified)) {
  h06d_abort(
    "H06_daily no-nugget input drift: %s",
    paste(input_contract$input_id[!input_contract$verified], collapse = ", ")
  )
}

frame_path <- file.path(
  roots$model_data,
  "H06_daily_stage2_daily_ar_repair__pre_sleep_identity__frame.rds"
)
frozen_frame <- readRDS(frame_path)
diaries <- h06d_load_diaries(root)
current_frame <- h06d_daily_frame(
  root,
  placement = "near_eye",
  metric_id = "duration_below_10_pre_sleep",
  predictor_id = "previous_sleep_duration_centered_h",
  diaries = diaries
) |>
  h06d_prepare_daily_response("identity") |>
  h06d_ar_add_day_sequences()
frame_equivalence <- h06d_ar_frame_equivalence(
  frozen_frame,
  current_frame,
  "pre_sleep_no_nugget"
)
if (!isTRUE(frame_equivalence$equivalence_pass[[1L]])) {
  h06d_abort("The current pre-sleep frame differs from the authorized frame")
}
if (
  any(frozen_frame$response_source < 0) ||
    any(frozen_frame$response_source > 6)
) {
  h06d_abort("The pre-sleep response violates its 0-6 h source bound")
}
support <- h06d_ar_sequence_support(frozen_frame)
if (!isTRUE(support$support_pass[[1L]])) {
  h06d_abort("The authorized pre-sleep frame lacks daily AR sequence support")
}
stopifnot(
  nrow(frozen_frame) == 648L,
  dplyr::n_distinct(frozen_frame$participant_key) == 139L,
  dplyr::n_distinct(frozen_frame$site) == 9L,
  support$adjacent_pairs[[1L]] == 450L
)

prior_checkpoint <- readRDS(file.path(
  roots$models,
  "H06_daily_stage2_daily_ar_repair_pilot_models.rds"
))
prior_entry <- prior_checkpoint$fits$pre_sleep_identity
if (is.null(prior_entry)) {
  h06d_abort("The frozen pre-sleep repair reference is missing")
}
formula <- h06d_ar_formula(
  "previous_sleep_duration_centered_h",
  ar = TRUE
)
expected_formula <- paste(
  "response_value ~ site + previous_sleep_duration_centered_h +",
  "(1 | participant_key) + ar1(day_index_factor + 0 | day_sequence_id)"
)
if (!identical(normalize_formula(formula), expected_formula)) {
  h06d_abort("The no-nugget AR formula differs from the authorized formula")
}

zero_dispersion_value <- log(.Machine$double.eps) / 4
expected_fixed_residual_sd <- exp(zero_dispersion_value)
set.seed(20260811L)
message("H06_daily pre-sleep no-nugget diagnostic: fitting exactly one model")
fit <- h06d_ar_capture(glmmTMB::glmmTMB(
  formula = formula,
  dispformula = ~0,
  data = frozen_frame,
  family = stats::gaussian(link = "identity"),
  REML = TRUE,
  control = glmmTMB::glmmTMBControl(
    zerodisp_val = zero_dispersion_value,
    optCtrl = list(iter.max = 10000L, eval.max = 10000L)
  )
))
if (is.null(fit$value)) {
  h06d_abort("The no-nugget fit failed: %s", fit$error)
}
model <- fit$value

status <- h06d_ar_model_status(model, fit)
parameters <- h06d_ar_parameters(model)
residual_diagnostic <- h06d_ar_residual_diagnostics(
  model,
  frozen_frame,
  response_transform = "identity",
  lower_bound = 0,
  upper_bound = 6
)
lag <- h06d_ar_lag_screen(
  frozen_frame,
  as.numeric(stats::residuals(model))
)
dispersion_formula <- model$modelInfo$allForm$dispformula
no_free_dispersion <- length(glmmTMB::fixef(model)$disp) == 0L
fixed_residual_sd <- stats::sigma(model)
no_nugget_verified <- identical(
  normalize_formula(dispersion_formula),
  "~0"
) && no_free_dispersion && isTRUE(all.equal(
  fixed_residual_sd,
  expected_fixed_residual_sd,
  tolerance = 1e-12
))

diagnostics <- dplyr::bind_cols(
  tibble::tibble(
    diagnostic_id = "pre_sleep_no_nugget",
    metric_id = "duration_below_10_pre_sleep",
    predictor_id = "previous_sleep_duration_centered_h",
    model_id = "glmmTMB_gap_aware_ar1_no_nugget",
    observations = nrow(frozen_frame),
    participants = dplyr::n_distinct(frozen_frame$participant_key),
    sites = dplyr::n_distinct(frozen_frame$site),
    formula = normalize_formula(formula),
    dispformula = normalize_formula(dispersion_formula),
    zero_dispersion_value = zero_dispersion_value,
    expected_fixed_residual_sd = expected_fixed_residual_sd,
    no_free_dispersion = no_free_dispersion,
    no_nugget_verified = no_nugget_verified
  ),
  status,
  parameters,
  residual_diagnostic,
  lag$overall |>
    dplyr::rename(
      true_adjacent_pairs = "adjacent_pairs",
      participants_with_true_adjacent_pair =
        "participants_with_adjacent_pair",
      true_date_residual_lag1 = "residual_lag1",
      maximum_absolute_site_residual_lag1 =
        "maximum_absolute_site_lag1",
      residual_temporal_threshold_pass = "temporal_threshold_pass"
    )
)

effect_term <- "previous_sleep_duration_centered_h"
frozen_effect <- h06d_ar_effect_row(
  prior_entry$frozen_lmer_independent,
  effect_term,
  "identity"
)
prior_ar_effect <- h06d_ar_effect_row(
  prior_entry$glmmTMB_gap_aware_ar1,
  effect_term,
  "identity"
)
new_effect <- h06d_ar_effect_row(model, effect_term, "identity")
effect_stability <- dplyr::bind_rows(
  frozen_effect |>
    dplyr::mutate(model_id = "frozen_lmer_independent"),
  prior_ar_effect |>
    dplyr::mutate(model_id = "failed_free_dispersion_ar1"),
  new_effect |>
    dplyr::mutate(model_id = "no_nugget_ar1")
) |>
  dplyr::mutate(
    diagnostic_id = "pre_sleep_no_nugget",
    contrast = "Per 1 h greater previous-night sleep duration",
    display_scale = "absolute difference in pre-sleep duration (h)",
    shift_from_frozen_lmer_se = abs(
      .data$estimate - frozen_effect$estimate[[1L]]
    ) / frozen_effect$standard_error[[1L]],
    direction_matches_frozen_lmer = sign(.data$estimate) ==
      sign(frozen_effect$estimate[[1L]]),
    shift_from_failed_ar_se = abs(
      .data$estimate - prior_ar_effect$estimate[[1L]]
    ) / frozen_effect$standard_error[[1L]],
    diagnostic_role = "engineering covariance diagnostic; no association claim",
    .before = 1L
  )
new_effect_row <- dplyr::filter(
  effect_stability,
  .data$model_id == "no_nugget_ar1"
)

prior_diagnostics <- readr::read_csv(
  file.path(
    roots$diagnostics,
    "H06_daily_stage2_daily_ar_repair_pilot_model_diagnostics.csv"
  ),
  show_col_types = FALSE
)
independent_diagnostic <- prior_diagnostics |>
  dplyr::filter(
    .data$repair_id == "pre_sleep_identity",
    .data$model_id == "frozen_lmer_independent"
  )
if (nrow(independent_diagnostic) != 1L) {
  h06d_abort("The frozen independent temporal trigger is not unique")
}

checks <- tibble::tribble(
  ~domain, ~passed, ~rule, ~observed,
  "Input identity",
  all(input_contract$verified),
  "all direct inputs match their author-approved SHA-256 identities",
  sprintf("%d of %d inputs verified", sum(input_contract$verified), nrow(input_contract)),
  "Current-versus-authorized frame",
  frame_equivalence$equivalence_pass[[1L]],
  "same participant-days, values, columns, order, and factor levels",
  sprintf("%d rows; normalized SHA-256 %s", nrow(frozen_frame), frame_equivalence$old_normalized_sha256[[1L]]),
  "Sequence support",
  support$support_pass[[1L]],
  ">=100 true adjacent pairs and >=20 participants with adjacency",
  sprintf("%d pairs; %d participants", support$adjacent_pairs[[1L]], support$participants_with_adjacent_pair[[1L]]),
  "Independent-model AR trigger",
  !independent_diagnostic$residual_temporal_threshold_pass[[1L]],
  "pooled |lag-1| >=0.20 or any site |lag-1| >=0.30",
  sprintf("pooled %.3f; site maximum %.3f", independent_diagnostic$true_date_residual_lag1[[1L]], independent_diagnostic$maximum_absolute_site_residual_lag1[[1L]]),
  "Authorized no-nugget specification",
  no_nugget_verified,
  "dispformula ~0, no estimated dispersion coefficient, and package-fixed residual SD",
  sprintf("dispformula=%s; free dispersion=%s; fixed SD=%.9f h", normalize_formula(dispersion_formula), !no_free_dispersion, fixed_residual_sd),
  "AR numerical fit",
  diagnostics$converged[[1L]] &&
    diagnostics$positive_definite_hessian[[1L]] &&
    diagnostics$finite_fixed_effects[[1L]] &&
    diagnostics$finite_standard_errors[[1L]],
  "convergence code 0, positive-definite Hessian, finite estimates and SEs",
  sprintf("converged=%s; PD Hessian=%s; warnings=%d", diagnostics$converged[[1L]], diagnostics$positive_definite_hessian[[1L]], diagnostics$warning_count[[1L]]),
  "AR structured-covariance singularity",
  isFALSE(diagnostics$singular[[1L]]),
  "required participant/AR covariance structure is not singular",
  sprintf("singular=%s; participant SD=%.4f; AR SD=%.4f", diagnostics$singular[[1L]], diagnostics$participant_standard_deviation[[1L]], diagnostics$ar_standard_deviation[[1L]]),
  "AR coefficient",
  is.finite(diagnostics$ar_rho[[1L]]) && abs(diagnostics$ar_rho[[1L]]) < 0.95,
  "finite |rho| <0.95",
  sprintf("rho=%.3f", diagnostics$ar_rho[[1L]]),
  "Effect stability",
  new_effect_row$shift_from_frozen_lmer_se[[1L]] < 1 &&
    new_effect_row$direction_matches_frozen_lmer[[1L]],
  "same direction and <1 frozen-model SE shift",
  sprintf("shift=%.3f SE; direction match=%s", new_effect_row$shift_from_frozen_lmer_se[[1L]], new_effect_row$direction_matches_frozen_lmer[[1L]]),
  "Residual temporal dependence after AR",
  diagnostics$residual_temporal_threshold_pass[[1L]],
  "pooled |lag-1| <0.20 and every site |lag-1| <0.30",
  sprintf("pooled %.3f; site maximum %.3f", diagnostics$true_date_residual_lag1[[1L]], diagnostics$maximum_absolute_site_residual_lag1[[1L]]),
  "Gaussian residual distribution",
  diagnostics$distribution_pass[[1L]],
  "Q-Q >=0.95, |spread Spearman| <0.20, and <1% residuals exceed |4|",
  sprintf("Q-Q %.3f; spread %.3f; >|4| %.3f", diagnostics$residual_qq_correlation[[1L]], diagnostics$absolute_residual_fitted_spearman[[1L]], diagnostics$standardized_residual_gt4_fraction[[1L]]),
  "Physical predictions",
  diagnostics$bounds_pass[[1L]],
  "no more than 1% of conditional or marginal predictions outside 0-6 h by >0.05 h",
  sprintf("conditional %.3f; marginal %.3f violation fraction", diagnostics$conditional_bound_violation_fraction[[1L]], diagnostics$marginal_bound_violation_fraction[[1L]])
) |>
  dplyr::mutate(
    diagnostic_id = "pre_sleep_no_nugget",
    verdict = ifelse(.data$passed, "ACCEPTABLE", "NOT_ACCEPTABLE"),
    .before = 1L
  )
overall_pass <- all(checks$passed)
overall <- tibble::tibble(
  diagnostic_id = "pre_sleep_no_nugget",
  domain = "Overall no-nugget gate",
  passed = overall_pass,
  rule = paste(
    "every authorized input, frame, support, specification, numerical,",
    "covariance, temporal, distributional, stability, and bounds check passes"
  ),
  observed = if (overall_pass) {
    "all domains acceptable"
  } else {
    paste(checks$domain[!checks$passed], collapse = " | ")
  },
  verdict = ifelse(overall_pass, "ACCEPTABLE", "NOT_ACCEPTABLE")
)
verdict <- dplyr::bind_rows(checks, overall)

site_lag <- lag$by_site |>
  dplyr::mutate(
    diagnostic_id = "pre_sleep_no_nugget",
    model_id = "glmmTMB_gap_aware_ar1_no_nugget",
    .before = 1L
  )
runtime <- tibble::tibble(
  diagnostic_id = "pre_sleep_no_nugget",
  fits_run = 1L,
  elapsed_fit_seconds = fit$elapsed_seconds,
  bootstrap_replicates = 0L,
  simulation_replicates = 0L,
  deletion_refits = 0L,
  remaining_grid_fits = 0L,
  interpretation = "one author-approved engineering diagnostic only"
)

checkpoint <- list(
  model = model,
  formula = formula,
  dispformula = ~0,
  zero_dispersion_value = zero_dispersion_value,
  expected_fixed_residual_sd = expected_fixed_residual_sd,
  frame_relative_path = sub(paste0("^", root, "/"), "", frame_path),
  frame_sha256 = sha256(frame_path),
  frame_equivalence = frame_equivalence,
  support = support,
  diagnostics = diagnostics,
  site_lag = site_lag,
  effect_stability = effect_stability,
  verdict = verdict,
  fit_warnings = fit$warnings,
  input_contract = input_contract,
  seed = 20260811L,
  r_version = as.character(getRversion()),
  package_versions = vapply(
    required_packages,
    function(package) as.character(utils::packageVersion(package)),
    character(1)
  )
)

model_path <- file.path(
  roots$models,
  "H06_daily_pre_sleep_no_nugget_diagnostic_model.rds"
)
equivalence_path <- file.path(
  roots$diagnostics,
  "H06_daily_pre_sleep_no_nugget_frame_equivalence.csv"
)
support_path <- file.path(
  roots$diagnostics,
  "H06_daily_pre_sleep_no_nugget_support.csv"
)
diagnostic_path <- file.path(
  roots$diagnostics,
  "H06_daily_pre_sleep_no_nugget_model_diagnostics.csv"
)
site_lag_path <- file.path(
  roots$diagnostics,
  "H06_daily_pre_sleep_no_nugget_site_residual_lag.csv"
)
verdict_path <- file.path(
  roots$diagnostics,
  "H06_daily_pre_sleep_no_nugget_verdict.csv"
)
runtime_path <- file.path(
  roots$diagnostics,
  "H06_daily_pre_sleep_no_nugget_runtime.csv"
)
effect_path <- file.path(
  roots$tables,
  "H06_daily_pre_sleep_no_nugget_effect_stability.csv"
)
input_manifest_path <- file.path(
  roots$manifests,
  "H06_daily_pre_sleep_no_nugget_diagnostic_input_manifest.csv"
)
code_manifest_path <- file.path(
  roots$manifests,
  "H06_daily_pre_sleep_no_nugget_diagnostic_code_manifest.csv"
)
software_manifest_path <- file.path(
  roots$manifests,
  "H06_daily_pre_sleep_no_nugget_diagnostic_software_manifest.csv"
)
output_manifest_path <- file.path(
  roots$manifests,
  "H06_daily_pre_sleep_no_nugget_diagnostic_output_manifest.csv"
)

write_rds(checkpoint, model_path)
write_csv(frame_equivalence, equivalence_path)
write_csv(support, support_path)
write_csv(diagnostics, diagnostic_path)
write_csv(site_lag, site_lag_path)
write_csv(verdict, verdict_path)
write_csv(runtime, runtime_path)
write_csv(effect_stability, effect_path)
write_csv(input_contract, input_manifest_path)

code_paths <- c(
  producer,
  "scripts/hypotheses/H06_daily/h06_daily_daily_ar_repair.R",
  "scripts/hypotheses/H06_daily/h06_daily_contract.R",
  "scripts/hypotheses/H06_daily/h06_daily_data.R",
  "scripts/hypotheses/H06_daily/h06_daily_modeling.R"
)
code_manifest <- tibble::tibble(
  relative_path = code_paths,
  sha256 = vapply(file.path(root, code_paths), sha256, character(1)),
  bytes = unname(file.info(file.path(root, code_paths))$size),
  role = c(
    "executed one-fit no-nugget diagnostic",
    "frozen daily AR diagnostic helpers",
    "daily metric and predictor contracts",
    "daily frame construction",
    "frozen independent-model helpers"
  )
)
write_csv(code_manifest, code_manifest_path)

software_manifest <- tibble::tibble(
  item = c("R", required_packages),
  version = c(
    as.character(getRversion()),
    vapply(
      required_packages,
      function(package) as.character(utils::packageVersion(package)),
      character(1)
    )
  ),
  role = c(
    "authoritative computation",
    rep("synchronized project library", length(required_packages))
  )
)
write_csv(software_manifest, software_manifest_path)

output_paths <- c(
  model_path,
  equivalence_path,
  support_path,
  diagnostic_path,
  site_lag_path,
  verdict_path,
  runtime_path,
  effect_path,
  input_manifest_path,
  code_manifest_path,
  software_manifest_path
)
output_manifest <- tibble::tibble(
  relative_path = sub(paste0("^", root, "/"), "", output_paths),
  sha256 = vapply(output_paths, sha256, character(1)),
  bytes = unname(file.info(output_paths)$size),
  producer = producer,
  r_version = as.character(getRversion()),
  written_utc = format(Sys.time(), tz = "UTC", usetz = TRUE)
)
write_csv(output_manifest, output_manifest_path)

message(
  "H06_daily pre-sleep no-nugget diagnostic complete: ",
  overall$verdict[[1L]],
  "; one model fit; no L10, MDER, resampling, deletion, or production grid"
)
