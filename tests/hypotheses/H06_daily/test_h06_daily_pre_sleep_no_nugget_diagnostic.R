#!/usr/bin/env Rscript

# Focused no-refit verification of the H06_daily pre-sleep no-nugget gate.

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
stopifnot(
  identical(as.character(getRversion()), "4.6.1"),
  requireNamespace("digest", quietly = TRUE),
  requireNamespace("readr", quietly = TRUE),
  requireNamespace("glmmTMB", quietly = TRUE),
  requireNamespace("lme4", quietly = TRUE)
)

sha256 <- function(path) digest::digest(path, algo = "sha256", file = TRUE)
read_csv <- function(path) {
  readr::read_csv(path, show_col_types = FALSE, na = "")
}
artifact <- function(stage, file) {
  file.path(root, "artifacts", stage, "H06_daily", file)
}
normalize_formula <- function(formula) {
  gsub("[[:space:]]+", " ", paste(deparse(formula), collapse = " "))
}
serialized_sha256 <- function(object) {
  digest::digest(
    serialize(object, NULL, version = 3),
    algo = "sha256",
    serialize = FALSE
  )
}
verify_manifest <- function(path) {
  manifest <- read_csv(path)
  absolute <- file.path(root, manifest$relative_path)
  stopifnot(
    all(file.exists(absolute)),
    identical(
      unname(vapply(absolute, sha256, character(1))),
      manifest$sha256
    )
  )
  invisible(manifest)
}

verify_manifest(artifact(
  "12_manifests",
  "H06_daily_pre_sleep_no_nugget_diagnostic_code_manifest.csv"
))
verify_manifest(artifact(
  "12_manifests",
  "H06_daily_pre_sleep_no_nugget_diagnostic_output_manifest.csv"
))
verify_manifest(artifact(
  "12_manifests",
  "H06_daily_pre_sleep_no_nugget_final_code_manifest.csv"
))
verify_manifest(artifact(
  "12_manifests",
  "H06_daily_pre_sleep_no_nugget_final_output_manifest.csv"
))
verify_manifest(artifact(
  "12_manifests",
  "H06_daily_pre_sleep_no_nugget_reference_seal_code_manifest.csv"
))
verify_manifest(artifact(
  "12_manifests",
  "H06_daily_pre_sleep_no_nugget_reference_seal_output_manifest.csv"
))

original_input <- read_csv(artifact(
  "12_manifests",
  "H06_daily_pre_sleep_no_nugget_diagnostic_input_manifest.csv"
))
stopifnot(
  nrow(original_input) == 13L,
  all(original_input$verified),
  identical(original_input$expected_sha256, original_input$observed_sha256)
)
repaired_input <- read_csv(artifact(
  "12_manifests",
  "H06_daily_pre_sleep_no_nugget_diagnostic_repaired_input_manifest.csv"
))
superseded <- c(
  "prior_repair_models", "prior_repair_diagnostics", "prior_repair_verdict",
  "prior_repair_effects", "prior_repair_output_manifest"
)
stopifnot(
  nrow(repaired_input) == 10L,
  all(repaired_input$verified),
  identical(
    repaired_input$expected_sha256,
    unname(vapply(
      file.path(root, repaired_input$relative_path),
      sha256,
      character(1)
    ))
  ),
  !any(repaired_input$input_id %in% superseded),
  sum(repaired_input$input_id == "standalone_pre_sleep_reference") == 1L,
  sum(repaired_input$input_id == "pre_sleep_reference_provenance") == 1L,
  !any(grepl("l10", repaired_input$relative_path, ignore.case = TRUE)),
  all(repaired_input$controlling_status ==
        "CONTROLLING_AFTER_NO_REFIT_CONTAINER_REPAIR")
)

provenance <- read_csv(artifact(
  "08_diagnostics",
  "H06_daily_pre_sleep_no_nugget_reference_provenance.csv"
))
stopifnot(
  nrow(provenance) == 1L,
  provenance$parent_sha256 ==
    "024ca6d5f51d8d5e80ed3f597a4faf93c4ce96697cf88496f782a059f9b9fdf4",
  provenance$exact_subobject_path == "$fits$pre_sleep_identity",
  provenance$serialization_byte_identical,
  provenance$frame_identical_to_executed_model,
  provenance$formula_identical_to_executed_model,
  !provenance$l10_field_in_executed_frame,
  !provenance$l10_text_in_executed_formula,
  !provenance$model_refit,
  !provenance$shared_artifact_changed,
  grepl("deserialized", provenance$disclosure, fixed = TRUE)
)

parent <- readRDS(file.path(root, provenance$parent_relative_path))
standalone <- readRDS(file.path(root, provenance$standalone_relative_path))
parent_member <- parent$fits$pre_sleep_identity
stopifnot(
  identical(
    serialized_sha256(parent_member),
    serialized_sha256(standalone)
  ),
  identical(
    serialized_sha256(parent_member),
    provenance$parent_member_serialized_sha256
  ),
  identical(parent_member$frame, standalone$frame),
  identical(
    normalize_formula(parent_member$ar_formula),
    normalize_formula(standalone$ar_formula)
  )
)

checkpoint <- readRDS(artifact(
  "07_models",
  "H06_daily_pre_sleep_no_nugget_diagnostic_model.rds"
))
model <- checkpoint$model
frame <- readRDS(file.path(root, checkpoint$frame_relative_path))
stopifnot(
  checkpoint$seed == 20260811L,
  nrow(frame) == 648L,
  length(unique(frame$participant_key)) == 139L,
  length(unique(frame$site)) == 9L,
  identical(frame, standalone$frame),
  identical(
    normalize_formula(checkpoint$formula),
    paste(
      "response_value ~ site + previous_sleep_duration_centered_h +",
      "(1 | participant_key) + ar1(day_index_factor + 0 | day_sequence_id)"
    )
  ),
  identical(normalize_formula(model$modelInfo$allForm$dispformula), "~0"),
  all(is.na(model$obj$env$map$betadisp)),
  !"betadisp" %in% names(model$fit$par),
  abs(stats::sigma(model) - exp(log(.Machine$double.eps) / 4)) < 1e-12
)

preliminary_verdict <- read_csv(artifact(
  "08_diagnostics",
  "H06_daily_pre_sleep_no_nugget_verdict.csv"
))
stopifnot(setequal(
  preliminary_verdict$domain[!preliminary_verdict$passed],
  c("Authorized no-nugget specification", "Overall no-nugget gate")
))
final_verdict <- read_csv(artifact(
  "08_diagnostics",
  "H06_daily_pre_sleep_no_nugget_final_verdict.csv"
))
stopifnot(
  nrow(final_verdict) == 13L,
  all(final_verdict$passed),
  all(final_verdict$verdict == "ACCEPTABLE")
)

diagnostics <- read_csv(artifact(
  "08_diagnostics",
  "H06_daily_pre_sleep_no_nugget_final_model_diagnostics.csv"
))
stopifnot(
  nrow(diagnostics) == 1L,
  diagnostics$converged,
  diagnostics$positive_definite_hessian,
  !diagnostics$singular,
  diagnostics$warning_count == 0L,
  diagnostics$dispformula == "~0",
  diagnostics$dispersion_fixed_by_parameter_map,
  !diagnostics$dispersion_in_optimized_vector,
  diagnostics$no_free_dispersion,
  diagnostics$no_nugget_verified,
  abs(diagnostics$residual_standard_deviation - 0.0001220703125) < 1e-12,
  abs(diagnostics$participant_standard_deviation - 0.6545) < 0.0001,
  abs(diagnostics$ar_standard_deviation - 0.7981) < 0.0001,
  abs(diagnostics$ar_rho - (-0.0847860)) < 1e-6,
  diagnostics$residual_temporal_threshold_pass,
  abs(diagnostics$true_date_residual_lag1 - (-0.135)) < 0.001,
  diagnostics$maximum_absolute_site_residual_lag1 < 0.30,
  diagnostics$distribution_pass,
  diagnostics$bounds_pass
)

effects <- read_csv(artifact(
  "09_tables",
  "H06_daily_pre_sleep_no_nugget_effect_stability.csv"
))
new_effect <- effects[effects$model_id == "no_nugget_ar1", , drop = FALSE]
stopifnot(
  nrow(effects) == 3L,
  nrow(new_effect) == 1L,
  abs(new_effect$estimate - (-0.1078)) < 0.0001,
  abs(new_effect$standard_error - 0.0253) < 0.0001,
  abs(new_effect$lower_95 - (-0.157)) < 0.001,
  abs(new_effect$upper_95 - (-0.0583)) < 0.0001,
  new_effect$shift_from_frozen_lmer_se < 0.131,
  new_effect$shift_from_failed_ar_se < 0.00002,
  new_effect$direction_matches_frozen_lmer,
  grepl("no association claim", new_effect$diagnostic_role, fixed = TRUE)
)

runtime <- read_csv(artifact(
  "08_diagnostics",
  "H06_daily_pre_sleep_no_nugget_runtime.csv"
))
stopifnot(
  runtime$fits_run == 1L,
  runtime$elapsed_fit_seconds > 0,
  runtime$bootstrap_replicates == 0L,
  runtime$simulation_replicates == 0L,
  runtime$deletion_refits == 0L,
  runtime$remaining_grid_fits == 0L
)
correction <- read_csv(artifact(
  "08_diagnostics",
  "H06_daily_pre_sleep_no_nugget_audit_correction.csv"
))
stopifnot(
  nrow(correction) == 1L,
  !correction$model_refit,
  !correction$scientific_quantity_changed,
  correction$final_verdict == "ACCEPTABLE"
)

qmd_path <- file.path(
  root,
  "audit/hypotheses/H06_daily/07_pre_sleep_no_nugget_diagnostic.qmd"
)
html_path <- sub("[.]qmd$", ".html", qmd_path)
transition_path <- file.path(
  root,
  paste0(
    "audit/hypotheses/H06_daily/",
    "H06_daily_pre_sleep_no_nugget_transition.md"
  )
)
stopifnot(
  file.exists(qmd_path),
  file.exists(html_path),
  file.exists(transition_path)
)
qmd <- paste(readLines(qmd_path, warn = FALSE), collapse = "\n")
html <- paste(readLines(html_path, warn = FALSE), collapse = "\n")
transition <- paste(readLines(transition_path, warn = FALSE), collapse = "\n")
stopifnot(
  grepl("H06-D-G2P-AR-NN", qmd, fixed = TRUE),
  grepl("H06-D-G2P-AR-NN", html, fixed = TRUE),
  grepl("H06-D-G2P-AR-NN", transition, fixed = TRUE),
  grepl("author approved", qmd, ignore.case = TRUE),
  grepl("author approved", html, ignore.case = TRUE),
  grepl("author approved", transition, ignore.case = TRUE),
  grepl("ACCEPTABLE", html, fixed = TRUE),
  grepl("no association", html, ignore.case = TRUE),
  grepl("deserialized", html, fixed = TRUE),
  grepl("remaining daily-metric production grid remain on hold", html, fixed = TRUE),
  !grepl("math display", html, ignore.case = TRUE)
)

report_manifest <- file.path(
  root,
  paste0(
    "audit/hypotheses/H06_daily/",
    "H06_daily_pre_sleep_no_nugget_report_manifest.csv"
  )
)
verify_manifest(report_manifest)

message(
  "H06_daily pre-sleep no-nugget integrity passed: one acceptable fit, ",
  "no-refit audit correction, standalone pre-sleep reference, no L10 ",
  "analytical dependency"
)
