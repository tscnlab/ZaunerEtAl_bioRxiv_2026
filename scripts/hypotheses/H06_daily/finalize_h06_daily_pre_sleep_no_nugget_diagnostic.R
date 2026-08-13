#!/usr/bin/env Rscript

# Correct the post-fit no-nugget parameter-map audit without refitting.
# The executed fit and its preliminary artifacts remain immutable inputs. This
# script writes final diagnostic/verdict artifacts that recognize glmmTMB's
# mapped fixed dispersion parameter correctly.

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
  "dplyr", "tibble", "readr", "digest", "glmmTMB", "performance"
)
stopifnot(
  identical(as.character(getRversion()), "4.6.1"),
  all(vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)),
  identical(as.character(utils::packageVersion("glmmTMB")), "1.1.14")
)
library(dplyr)

source(file.path(
  root,
  "scripts/hypotheses/H06_daily/h06_daily_contract.R"
))
source(file.path(
  root,
  "scripts/hypotheses/H06_daily/h06_daily_daily_ar_repair.R"
))

producer <- paste0(
  "scripts/hypotheses/H06_daily/",
  "finalize_h06_daily_pre_sleep_no_nugget_diagnostic.R"
)
roots <- h06d_artifact_roots(root)
sha256 <- function(path) digest::digest(path, algo = "sha256", file = TRUE)
read_csv <- function(path) {
  readr::read_csv(path, show_col_types = FALSE, na = "")
}
write_csv <- function(data, path) {
  readr::write_csv(data, path, na = "")
  invisible(path)
}
normalize_formula <- function(formula) {
  gsub("[[:space:]]+", " ", paste(deparse(formula), collapse = " "))
}

input_contract <- tibble::tribble(
  ~input_id, ~relative_path, ~expected_sha256, ~role,
  "executed_model",
  paste0(
    "artifacts/07_models/H06_daily/",
    "H06_daily_pre_sleep_no_nugget_diagnostic_model.rds"
  ),
  "d1271775f2a46252247ac945977e338866df3a99f68d9af123067329fd526368",
  "immutable one-fit diagnostic checkpoint",
  "preliminary_diagnostics",
  paste0(
    "artifacts/08_diagnostics/H06_daily/",
    "H06_daily_pre_sleep_no_nugget_model_diagnostics.csv"
  ),
  "6eaafe92f521f2b15c2ce1fe737878ea631b22859b40d47ae5289ce4820849df",
  "preliminary diagnostics containing the parameter-map audit error",
  "preliminary_verdict",
  paste0(
    "artifacts/08_diagnostics/H06_daily/",
    "H06_daily_pre_sleep_no_nugget_verdict.csv"
  ),
  "d8f773a26c386bb52cebf94c190fe3fbe6ab084598238ea97f7565483be70eb3",
  "preliminary verdict containing the derived false failure",
  "effect_stability",
  paste0(
    "artifacts/09_tables/H06_daily/",
    "H06_daily_pre_sleep_no_nugget_effect_stability.csv"
  ),
  "f38ab2af03c086d01ca4fc2cbaa3f77b1af9864a9b8b60d2d8e4a7bad650ee13",
  "engineering effect comparison from the executed fit",
  "executed_code_manifest",
  paste0(
    "artifacts/12_manifests/H06_daily/",
    "H06_daily_pre_sleep_no_nugget_diagnostic_code_manifest.csv"
  ),
  "e31bac93a93cca4559ccdf8d737aa281d7b44ca6140b226c8bd9d379142f36c5",
  "exact code identity that executed the one fit",
  "executed_output_manifest",
  paste0(
    "artifacts/12_manifests/H06_daily/",
    "H06_daily_pre_sleep_no_nugget_diagnostic_output_manifest.csv"
  ),
  "89c0faf24e43016f6c72d942426f3e64b302b31180b7199c656475e40f9b0523",
  "immutable preliminary output identity"
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
stopifnot(all(input_contract$verified))

checkpoint <- readRDS(file.path(root, input_contract$relative_path[[1L]]))
model <- checkpoint$model
frame <- readRDS(file.path(root, checkpoint$frame_relative_path))
# The stored glmmTMB call records `data = frozen_frame`; restore that binding
# for prediction-based diagnostics without updating or refitting the model.
frozen_frame <- frame
preliminary_diagnostics <- read_csv(file.path(
  roots$diagnostics,
  "H06_daily_pre_sleep_no_nugget_model_diagnostics.csv"
))
preliminary_verdict <- read_csv(file.path(
  roots$diagnostics,
  "H06_daily_pre_sleep_no_nugget_verdict.csv"
))
effect_stability <- read_csv(file.path(
  roots$tables,
  "H06_daily_pre_sleep_no_nugget_effect_stability.csv"
))

# A `~0` glmmTMB dispersion formula retains the fixed value in `fixef()`, but
# maps it out of the optimized parameter vector. The preliminary check treated
# its presence in `fixef()` as evidence of free estimation. The parameter map
# and optimized vector are the authoritative evidence.
dispersion_map <- model$obj$env$map$betadisp
dispersion_fixed_by_map <- length(dispersion_map) > 0L &&
  all(is.na(dispersion_map))
dispersion_in_optimized_vector <- "betadisp" %in% names(model$fit$par)
fixed_dispersion_value <- unname(model$obj$env$parList()$betadisp[[1L]])
expected_dispersion_value <- checkpoint$zero_dispersion_value
fixed_residual_sd <- stats::sigma(model)
expected_fixed_residual_sd <- checkpoint$expected_fixed_residual_sd
no_nugget_verified <- identical(
  normalize_formula(model$modelInfo$allForm$dispformula),
  "~0"
) &&
  dispersion_fixed_by_map &&
  !dispersion_in_optimized_vector &&
  isTRUE(all.equal(
    fixed_dispersion_value,
    expected_dispersion_value,
    tolerance = 1e-12
  )) &&
  isTRUE(all.equal(
    fixed_residual_sd,
    expected_fixed_residual_sd,
    tolerance = 1e-12
  ))
stopifnot(no_nugget_verified)

# Recompute all model-dependent diagnostic quantities from the stored model and
# immutable frame to ensure the correction does not conceal a scientific drift.
status <- h06d_ar_model_status(model, list(error = NA_character_, warnings = checkpoint$fit_warnings))
parameters <- h06d_ar_parameters(model)
residual_diagnostic <- h06d_ar_residual_diagnostics(
  model,
  frame,
  response_transform = "identity",
  lower_bound = 0,
  upper_bound = 6
)
lag <- h06d_ar_lag_screen(frame, as.numeric(stats::residuals(model)))
recomputed <- dplyr::bind_cols(
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
recomputed_columns <- intersect(
  names(recomputed),
  names(preliminary_diagnostics)
)
recomputed_columns <- setdiff(recomputed_columns, "warnings")
stopifnot(all(vapply(
  recomputed_columns,
  function(column) isTRUE(all.equal(
    recomputed[[column]],
    preliminary_diagnostics[[column]],
    tolerance = 1e-12,
    check.attributes = FALSE
  )),
  logical(1)
)))
stopifnot(
  length(checkpoint$fit_warnings) == 0L,
  is.na(preliminary_diagnostics$warnings[[1L]])
)

final_diagnostics <- preliminary_diagnostics |>
  dplyr::mutate(
    preliminary_no_free_dispersion_check = .data$no_free_dispersion,
    preliminary_no_nugget_verified = .data$no_nugget_verified,
    dispersion_fixed_by_parameter_map = dispersion_fixed_by_map,
    dispersion_in_optimized_vector = dispersion_in_optimized_vector,
    fixed_dispersion_value = fixed_dispersion_value,
    no_free_dispersion = dispersion_fixed_by_map &&
      !dispersion_in_optimized_vector,
    no_nugget_verified = .env$no_nugget_verified
  )

expected_preliminary_failures <- c(
  "Authorized no-nugget specification",
  "Overall no-nugget gate"
)
stopifnot(setequal(
  preliminary_verdict$domain[!preliminary_verdict$passed],
  expected_preliminary_failures
))
final_verdict <- preliminary_verdict |>
  dplyr::mutate(
    passed = dplyr::case_when(
      .data$domain == "Authorized no-nugget specification" ~ TRUE,
      .data$domain == "Overall no-nugget gate" ~ TRUE,
      TRUE ~ .data$passed
    ),
    observed = dplyr::case_when(
      .data$domain == "Authorized no-nugget specification" ~ sprintf(
        paste0(
          "dispformula=~0; betadisp mapped fixed=%s; ",
          "betadisp optimized=%s; fixed SD=%.9f h"
        ),
        dispersion_fixed_by_map,
        dispersion_in_optimized_vector,
        fixed_residual_sd
      ),
      .data$domain == "Overall no-nugget gate" ~
        "all domains acceptable after parameter-map audit correction",
      TRUE ~ .data$observed
    ),
    verdict = ifelse(.data$passed, "ACCEPTABLE", "NOT_ACCEPTABLE")
  )
stopifnot(all(final_verdict$passed))

new_effect <- effect_stability |>
  dplyr::filter(.data$model_id == "no_nugget_ar1")
stopifnot(
  nrow(new_effect) == 1L,
  new_effect$direction_matches_frozen_lmer[[1L]],
  new_effect$shift_from_frozen_lmer_se[[1L]] < 1
)

correction <- tibble::tibble(
  correction_id = "H06-D-AR-NN-AUDIT-001",
  issue = paste(
    "The preliminary post-fit audit assumed that a nonempty fixef(model)$disp",
    "meant dispersion was freely estimated."
  ),
  glmmTMB_semantics = paste(
    "With dispformula=~0, glmmTMB retains the fixed betadisp value for",
    "reporting but maps it out of the optimized parameter vector."
  ),
  evidence = sprintf(
    paste0(
      "dispformula=~0; map betadisp all NA=%s; optimized betadisp=%s; ",
      "fixed betadisp=%.9f; sigma=%.9f h"
    ),
    dispersion_fixed_by_map,
    dispersion_in_optimized_vector,
    fixed_dispersion_value,
    fixed_residual_sd
  ),
  action = paste(
    "Correct derived specification and overall verdicts only; preserve the",
    "executed model and all model-dependent diagnostics."
  ),
  model_refit = FALSE,
  scientific_quantity_changed = FALSE,
  final_verdict = "ACCEPTABLE"
)

final_diagnostic_path <- file.path(
  roots$diagnostics,
  "H06_daily_pre_sleep_no_nugget_final_model_diagnostics.csv"
)
final_verdict_path <- file.path(
  roots$diagnostics,
  "H06_daily_pre_sleep_no_nugget_final_verdict.csv"
)
correction_path <- file.path(
  roots$diagnostics,
  "H06_daily_pre_sleep_no_nugget_audit_correction.csv"
)
input_manifest_path <- file.path(
  roots$manifests,
  "H06_daily_pre_sleep_no_nugget_final_input_manifest.csv"
)
code_manifest_path <- file.path(
  roots$manifests,
  "H06_daily_pre_sleep_no_nugget_final_code_manifest.csv"
)
software_manifest_path <- file.path(
  roots$manifests,
  "H06_daily_pre_sleep_no_nugget_final_software_manifest.csv"
)
output_manifest_path <- file.path(
  roots$manifests,
  "H06_daily_pre_sleep_no_nugget_final_output_manifest.csv"
)

write_csv(final_diagnostics, final_diagnostic_path)
write_csv(final_verdict, final_verdict_path)
write_csv(correction, correction_path)
write_csv(input_contract, input_manifest_path)

code_paths <- c(
  producer,
  "scripts/hypotheses/H06_daily/h06_daily_daily_ar_repair.R",
  "scripts/hypotheses/H06_daily/h06_daily_contract.R"
)
code_manifest <- tibble::tibble(
  relative_path = code_paths,
  sha256 = vapply(file.path(root, code_paths), sha256, character(1)),
  bytes = unname(file.info(file.path(root, code_paths))$size),
  role = c(
    "no-refit parameter-map audit finalizer",
    "frozen daily AR diagnostic helpers",
    "artifact-root and error helpers"
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
    "authoritative no-refit audit",
    rep("synchronized project library", length(required_packages))
  )
)
write_csv(software_manifest, software_manifest_path)

output_paths <- c(
  final_diagnostic_path,
  final_verdict_path,
  correction_path,
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
  "H06_daily pre-sleep no-nugget diagnostic finalized without refit: ",
  "ACCEPTABLE; preliminary parameter-map audit error preserved and corrected"
)
