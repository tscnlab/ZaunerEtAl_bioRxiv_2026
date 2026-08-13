#!/usr/bin/env Rscript

# No-refit provenance-container repair for the H06_daily pre-sleep no-nugget
# diagnostic. Extract the exact pre-sleep member from the sealed historical
# composite, seal it as a standalone reference, and create the controlling
# repaired input manifest. Do not access the composite L10 member.

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
  "dplyr", "tibble", "readr", "digest", "lme4", "glmmTMB"
)
stopifnot(
  identical(as.character(getRversion()), "4.6.1"),
  all(vapply(required_packages, requireNamespace, logical(1), quietly = TRUE))
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
  "seal_h06_daily_pre_sleep_no_nugget_reference.R"
)
roots <- h06d_artifact_roots(root)
sha256 <- function(path) digest::digest(path, algo = "sha256", file = TRUE)
write_csv <- function(data, path) {
  readr::write_csv(data, path, na = "")
  invisible(path)
}
write_rds <- function(object, path) {
  saveRDS(object, path, version = 3)
  invisible(path)
}
serialized_sha256 <- function(object) {
  digest::digest(
    serialize(object, NULL, version = 3),
    algo = "sha256",
    serialize = FALSE
  )
}

parent_relative <- paste0(
  "artifacts/07_models/H06_daily/",
  "H06_daily_stage2_daily_ar_repair_pilot_models.rds"
)
parent_expected_sha256 <-
  "024ca6d5f51d8d5e80ed3f597a4faf93c4ce96697cf88496f782a059f9b9fdf4"
parent_path <- file.path(root, parent_relative)
stopifnot(identical(sha256(parent_path), parent_expected_sha256))

# The composite is deserialized once for the documented extraction. Only the
# exact pre-sleep member below is accessed; no L10 member is indexed or used.
parent <- readRDS(parent_path)
subobject_path <- "$fits$pre_sleep_identity"
reference <- parent$fits$pre_sleep_identity
stopifnot(
  !is.null(reference),
  identical(
    names(reference),
    c(
      "registry", "frame", "frozen_lmer_independent",
      "glmmTMB_independent", "glmmTMB_gap_aware_ar1",
      "independent_formula", "ar_formula", "independent_warnings",
      "ar_warnings"
    )
  ),
  !any(grepl("l10", names(reference$frame), ignore.case = TRUE)),
  !grepl(
    "l10",
    paste(deparse(reference$ar_formula), collapse = " "),
    ignore.case = TRUE
  )
)

standalone_relative <- paste0(
  "artifacts/07_models/H06_daily/",
  "H06_daily_pre_sleep_only_historical_reference.rds"
)
standalone_path <- file.path(root, standalone_relative)
parent_member_serialized_sha256 <- serialized_sha256(reference)
write_rds(reference, standalone_path)
sealed_reference <- readRDS(standalone_path)
standalone_serialized_sha256 <- serialized_sha256(sealed_reference)
serialization_byte_identical <- identical(
  serialize(reference, NULL, version = 3),
  serialize(sealed_reference, NULL, version = 3)
)
stopifnot(
  serialization_byte_identical,
  identical(
    parent_member_serialized_sha256,
    standalone_serialized_sha256
  ),
  identical(reference$frame, sealed_reference$frame),
  identical(
    paste(deparse(reference$ar_formula), collapse = " "),
    paste(deparse(sealed_reference$ar_formula), collapse = " ")
  )
)

executed_model_relative <- paste0(
  "artifacts/07_models/H06_daily/",
  "H06_daily_pre_sleep_no_nugget_diagnostic_model.rds"
)
executed_model_path <- file.path(root, executed_model_relative)
stopifnot(
  identical(
    sha256(executed_model_path),
    "d1271775f2a46252247ac945977e338866df3a99f68d9af123067329fd526368"
  )
)
executed_checkpoint <- readRDS(executed_model_path)
executed_frame <- readRDS(file.path(
  root,
  executed_checkpoint$frame_relative_path
))
stopifnot(
  identical(executed_frame, sealed_reference$frame),
  identical(
    paste(deparse(executed_checkpoint$formula), collapse = " "),
    paste(deparse(sealed_reference$ar_formula), collapse = " ")
  ),
  !any(grepl("l10", names(executed_frame), ignore.case = TRUE)),
  !grepl(
    "l10",
    paste(deparse(executed_checkpoint$formula), collapse = " "),
    ignore.case = TRUE
  )
)

effect_relative <- paste0(
  "artifacts/09_tables/H06_daily/",
  "H06_daily_pre_sleep_no_nugget_effect_stability.csv"
)
effect_path <- file.path(root, effect_relative)
stopifnot(
  identical(
    sha256(effect_path),
    "f38ab2af03c086d01ca4fc2cbaa3f77b1af9864a9b8b60d2d8e4a7bad650ee13"
  )
)
stored_effects <- readr::read_csv(
  effect_path,
  show_col_types = FALSE,
  na = ""
)
reference_effects <- dplyr::bind_rows(
  h06d_ar_effect_row(
    sealed_reference$frozen_lmer_independent,
    "previous_sleep_duration_centered_h",
    "identity"
  ) |>
    dplyr::mutate(model_id = "frozen_lmer_independent"),
  h06d_ar_effect_row(
    sealed_reference$glmmTMB_gap_aware_ar1,
    "previous_sleep_duration_centered_h",
    "identity"
  ) |>
    dplyr::mutate(model_id = "failed_free_dispersion_ar1")
)
for (model_id in reference_effects$model_id) {
  observed <- dplyr::filter(
    stored_effects,
    .data$model_id == .env$model_id
  )
  expected <- dplyr::filter(
    reference_effects,
    .data$model_id == .env$model_id
  )
  stopifnot(
    nrow(observed) == 1L,
    isTRUE(all.equal(
      observed$estimate,
      expected$estimate,
      tolerance = 1e-12
    )),
    isTRUE(all.equal(
      observed$standard_error,
      expected$standard_error,
      tolerance = 1e-12
    ))
  )
}

provenance_path <- file.path(
  roots$diagnostics,
  "H06_daily_pre_sleep_no_nugget_reference_provenance.csv"
)
provenance <- tibble::tibble(
  repair_id = "H06-D-AR-NN-PROV-001",
  parent_relative_path = parent_relative,
  parent_sha256 = parent_expected_sha256,
  exact_subobject_path = subobject_path,
  standalone_relative_path = standalone_relative,
  standalone_file_sha256 = sha256(standalone_path),
  parent_member_serialized_sha256 = parent_member_serialized_sha256,
  standalone_serialized_sha256 = standalone_serialized_sha256,
  serialization_byte_identical = serialization_byte_identical,
  frame_identical_to_executed_model = identical(
    executed_frame,
    sealed_reference$frame
  ),
  formula_identical_to_executed_model = identical(
    paste(deparse(executed_checkpoint$formula), collapse = " "),
    paste(deparse(sealed_reference$ar_formula), collapse = " ")
  ),
  l10_field_in_executed_frame = any(grepl(
    "l10",
    names(executed_frame),
    ignore.case = TRUE
  )),
  l10_text_in_executed_formula = grepl(
    "l10",
    paste(deparse(executed_checkpoint$formula), collapse = " "),
    ignore.case = TRUE
  ),
  disclosure = paste(
    "The initial process deserialized the sealed parent composite and",
    "accessed only $fits$pre_sleep_identity. The composite also contains a",
    "historical L10 member, but no L10 member or field entered the executed",
    "frame, formula, fit, effect comparison, or diagnostic."
  ),
  coordinator_disposition = paste(
    "Permissible without refit; replace the composite as a controlling",
    "scientific input with this exactly sealed pre-sleep-only reference."
  ),
  model_refit = FALSE,
  shared_artifact_changed = FALSE
)
write_csv(provenance, provenance_path)

original_input_relative <- paste0(
  "artifacts/12_manifests/H06_daily/",
  "H06_daily_pre_sleep_no_nugget_diagnostic_input_manifest.csv"
)
original_input_path <- file.path(root, original_input_relative)
stopifnot(
  identical(
    sha256(original_input_path),
    "d1462e3eb699a1e5c2f796b90fc79e8e788f6b420a7bfb04ad30dfbce6a765eb"
  )
)
original_input <- readr::read_csv(
  original_input_path,
  show_col_types = FALSE,
  na = ""
)
superseded_container_inputs <- c(
  "prior_repair_models", "prior_repair_diagnostics", "prior_repair_verdict",
  "prior_repair_effects", "prior_repair_output_manifest"
)
stopifnot(all(superseded_container_inputs %in% original_input$input_id))

repaired_input <- original_input |>
  dplyr::filter(!.data$input_id %in% .env$superseded_container_inputs) |>
  dplyr::select(
    "input_id", "relative_path", "expected_sha256", "role",
    "observed_sha256", "bytes", "verified"
  )
additional_inputs <- tibble::tribble(
  ~input_id, ~relative_path, ~role,
  "standalone_pre_sleep_reference",
  standalone_relative,
  "controlling sealed historical pre-sleep-only model/effect reference",
  "pre_sleep_reference_provenance",
  sub(paste0("^", root, "/"), "", provenance_path),
  "parent container, exact subobject, identity, and disclosure record"
) |>
  dplyr::mutate(
    expected_sha256 = vapply(
      file.path(.env$root, .data$relative_path),
      sha256,
      character(1)
    ),
    observed_sha256 = .data$expected_sha256,
    bytes = unname(file.info(
      file.path(.env$root, .data$relative_path)
    )$size),
    verified = TRUE
  ) |>
  dplyr::select(names(repaired_input))
repaired_input <- dplyr::bind_rows(repaired_input, additional_inputs) |>
  dplyr::mutate(
    controlling_status = "CONTROLLING_AFTER_NO_REFIT_CONTAINER_REPAIR",
    supersedes = dplyr::if_else(
      .data$input_id == "standalone_pre_sleep_reference",
      paste(superseded_container_inputs, collapse = " | "),
      NA_character_
    )
  )
stopifnot(
  all(repaired_input$verified),
  !any(repaired_input$input_id %in% superseded_container_inputs),
  !any(grepl("l10", repaired_input$relative_path, ignore.case = TRUE))
)

repaired_input_path <- file.path(
  roots$manifests,
  "H06_daily_pre_sleep_no_nugget_diagnostic_repaired_input_manifest.csv"
)
write_csv(repaired_input, repaired_input_path)

input_manifest_path <- file.path(
  roots$manifests,
  "H06_daily_pre_sleep_no_nugget_reference_seal_input_manifest.csv"
)
code_manifest_path <- file.path(
  roots$manifests,
  "H06_daily_pre_sleep_no_nugget_reference_seal_code_manifest.csv"
)
software_manifest_path <- file.path(
  roots$manifests,
  "H06_daily_pre_sleep_no_nugget_reference_seal_software_manifest.csv"
)
output_manifest_path <- file.path(
  roots$manifests,
  "H06_daily_pre_sleep_no_nugget_reference_seal_output_manifest.csv"
)
seal_input_paths <- c(
  parent_relative,
  original_input_relative,
  executed_model_relative,
  effect_relative,
  "audit/hypotheses/H06_daily/H06_daily_pre_sleep_no_nugget_authorization.md"
)
seal_input_manifest <- tibble::tibble(
  relative_path = seal_input_paths,
  sha256 = vapply(file.path(root, seal_input_paths), sha256, character(1)),
  bytes = unname(file.info(file.path(root, seal_input_paths))$size),
  role = c(
    "sealed parent container used only to extract $fits$pre_sleep_identity",
    "immutable executed input contract retained as disclosure",
    "executed one-fit checkpoint used to verify frame/formula identity",
    "executed engineering effect table used to verify reference equality",
    "immutable author authorization and L10 exclusion boundary"
  ),
  scientific_input_status = c(
    "PROVENANCE_CONTAINER_ONLY_SUPERSEDED",
    "HISTORICAL_DISCLOSURE_SUPERSEDED",
    "EXECUTED_PRE_SLEEP_OUTPUT",
    "EXECUTED_PRE_SLEEP_OUTPUT",
    "CONTROLLING_AUTHORIZATION"
  )
)
write_csv(seal_input_manifest, input_manifest_path)
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
    "no-refit standalone reference sealer",
    "frozen effect-extraction helpers",
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
    "authoritative no-refit provenance repair",
    rep("synchronized project library", length(required_packages))
  )
)
write_csv(software_manifest, software_manifest_path)
output_paths <- c(
  standalone_path,
  provenance_path,
  repaired_input_path,
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
  "H06_daily pre-sleep reference sealed without refit: exact serialized ",
  "identity verified; composite disclosure retained; controlling input ",
  "manifest repaired"
)
