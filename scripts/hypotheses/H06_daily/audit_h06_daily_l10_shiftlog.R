#!/usr/bin/env Rscript

# Verify the H06-D-003 shifted-log contract and exact reusable pilot objects.

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
options(contrasts = c("contr.treatment", "contr.poly"))

required_packages <- c(
  "digest",
  "dplyr",
  "lme4",
  "readr",
  "reformulas",
  "tibble",
  "tidyr"
)
stopifnot(
  identical(as.character(getRversion()), "4.6.1"),
  all(vapply(required_packages, requireNamespace, logical(1), quietly = TRUE))
)

source(file.path(
  root,
  "scripts/hypotheses/H06_daily/h06_daily_l10_shiftlog_contract.R"
))
source(file.path(
  root,
  "scripts/hypotheses/H06_daily/h06_daily_l10_shiftlog_data.R"
))
source(file.path(
  root,
  "scripts/hypotheses/H06_daily/h06_daily_l10_metric011_contract.R"
))
source(file.path(
  root,
  "scripts/hypotheses/H06_daily/h06_daily_l10_metric011_data.R"
))

roots <- h06d_shiftlog_artifact_roots(root)
invisible(lapply(roots, dir.create, recursive = TRUE, showWarnings = FALSE))

#####
# Step 1: Verify controlling inputs and historical preservation
#####

input_contract <- h06d_shiftlog_input_contract() |>
  dplyr::mutate(
    actual_sha256 = vapply(
      file.path(root, .data$relative_path),
      h06d_shiftlog_sha256,
      character(1)
    ),
    identity_pass = .data$expected_sha256 == .data$actual_sha256
  )
h06d_shiftlog_assert(
  all(input_contract$identity_pass),
  "H06-D-003 shifted-log input identity failed"
)

historical_report_manifest <- readr::read_csv(
  file.path(
    root,
    "audit/hypotheses/H06_daily/",
    "H06_daily_l10_metric011_report_manifest.csv"
  ),
  show_col_types = FALSE,
  na = c("", "NA")
)
historical_preservation <- historical_report_manifest |>
  dplyr::mutate(
    file_exists = file.exists(file.path(root, .data$relative_path)),
    actual_sha256 = vapply(
      file.path(root, .data$relative_path),
      h06d_shiftlog_sha256,
      character(1)
    ),
    actual_bytes = unname(file.info(file.path(root, .data$relative_path))$size),
    preserved_byte_for_byte = .data$file_exists &
      .data$sha256 == .data$actual_sha256 &
      .data$bytes == .data$actual_bytes
  )
h06d_shiftlog_assert(
  nrow(historical_preservation) == 118L &&
    all(historical_preservation$preserved_byte_for_byte),
  "The H06-D-001/H06-D-002 historical record is not byte-identical"
)

#####
# Step 2: Rebuild the current frames without fitting
#####

current_source <- h06d_l10_load_sources(root)
current_frames <- h06d_l10_build_frames(current_source)
predictors <- h06d_shiftlog_predictor_registry()
historical_bundle_path <- file.path(
  root,
  "artifacts/07_models/H06_daily/",
  "H06_daily_l10_metric011_production_models.rds"
)
historical_bundle <- readRDS(historical_bundle_path)

frame_rows <- list()
reuse_rows <- list()
reference_rows <- list()

for (predictor_index in seq_len(nrow(predictors))) {
  predictor <- predictors[predictor_index, ]
  predictor_id <- predictor$predictor_id[[1L]]
  parent <- h06d_shiftlog_read_parent_frame(root, predictor_id)
  historical_frame_key <- paste(
    h06d_shiftlog_pilot_run_id(),
    predictor_id,
    "zero_occurrence",
    sep = "__"
  )
  rebuilt_parent <- current_frames$frames[[historical_frame_key]]
  h06d_shiftlog_assert(
    identical(parent$frame, rebuilt_parent),
    "Current-source parent frame differs from the sealed frame for `%s`",
    predictor_id
  )
  shifted_frame <- h06d_shiftlog_prepare_frame(parent$frame, predictor)
  model_key <- h06d_shiftlog_model_key(
    h06d_shiftlog_pilot_run_id(),
    predictor_id
  )
  historical_capture <- historical_bundle$models[[model_key]]$one_part
  h06d_shiftlog_assert(
    !is.null(historical_capture$value),
    "Historical one-part object is missing for `%s`",
    predictor_id
  )
  reuse <- h06d_shiftlog_reuse_verification(
    shifted_frame,
    predictor,
    historical_capture,
    historical_bundle$package_versions
  )
  frame_relative <- file.path(
    "artifacts/06_model_data/H06_daily",
    paste0(h06d_shiftlog_frame_stem(predictor_id), ".rds")
  )
  frame_path <- file.path(root, frame_relative)
  saveRDS(shifted_frame, frame_path, compress = "xz")

  frame_rows[[predictor_id]] <- h06d_shiftlog_frame_summary(
    shifted_frame,
    predictor
  ) |>
    dplyr::mutate(
      run_id = h06d_shiftlog_pilot_run_id(),
      frame_path = frame_relative,
      frame_file_sha256 = h06d_shiftlog_sha256(frame_path),
      parent_frame_path = parent$registry$frame_path[[1L]],
      parent_frame_file_sha256 = parent$registry$frame_file_sha256[[1L]],
      current_source_rebuild_identical = identical(
        parent$frame,
        rebuilt_parent
      ),
      historical_internal_component_label = as.character(
        unique(shifted_frame$component)
      ),
      internal_component_label_role = paste0(
        "unused historical container field; scientific frame role is ",
        "one_part_shifted_log"
      ),
      .before = 1L
    )
  reuse_rows[[predictor_id]] <- reuse |>
    dplyr::mutate(
      run_id = h06d_shiftlog_pilot_run_id(),
      historical_parent_bundle_path = paste0(
        "artifacts/07_models/H06_daily/",
        "H06_daily_l10_metric011_production_models.rds"
      ),
      historical_parent_bundle_sha256 = h06d_shiftlog_sha256(
        historical_bundle_path
      ),
      new_frame_path = frame_relative,
      new_frame_file_sha256 = h06d_shiftlog_sha256(frame_path),
      new_frame_object_sha256 = h06d_shiftlog_object_sha256(shifted_frame),
      .before = 1L
    )
  reference_rows[[predictor_id]] <- tibble::tibble(
    run_id = h06d_shiftlog_pilot_run_id(),
    predictor_order = predictor$predictor_order[[1L]],
    predictor_id = predictor_id,
    reference_role = "exact reusable Gaussian additive REML object",
    parent_path = paste0(
      "artifacts/07_models/H06_daily/",
      "H06_daily_l10_metric011_production_models.rds"
    ),
    parent_sha256 = h06d_shiftlog_sha256(historical_bundle_path),
    subobject_path = reuse$historical_subobject_path[[1L]],
    capture_object_sha256 = reuse$historical_capture_object_sha256[[1L]],
    model_object_sha256 = reuse$historical_model_object_sha256[[1L]],
    reuse_disposition = reuse$reuse_disposition[[1L]],
    disclosure = paste0(
      "The object was first fitted as a diagnostic sensitivity inside the ",
      "historical composite; H06-D-003 permits reuse only after this exact ",
      "frame/formula/contrast/family/method/package verification."
    )
  )
}

frame_registry <- dplyr::bind_rows(frame_rows) |>
  dplyr::arrange(.data$predictor_order)
reuse_verification <- dplyr::bind_rows(reuse_rows) |>
  dplyr::arrange(.data$predictor_order)
reference_registry <- dplyr::bind_rows(reference_rows) |>
  dplyr::arrange(.data$predictor_order)
h06d_shiftlog_assert(
  nrow(frame_registry) == 3L &&
    all(frame_registry$current_source_rebuild_identical) &&
    nrow(reuse_verification) == 3L &&
    all(reuse_verification$exact_reuse_authorized),
  "The three shifted-log pilot frames did not pass exact reuse verification"
)

#####
# Step 3: Seal formulas and the compute hold
#####

formula_registry <- dplyr::bind_rows(lapply(
  seq_len(nrow(predictors)),
  function(index) {
    predictor <- predictors[index, ]
    formulas <- h06d_shiftlog_formula_set(predictor$column[[1L]])
    tibble::tibble(
      predictor_order = predictor$predictor_order[[1L]],
      predictor_id = predictor$predictor_id[[1L]],
      model_role = c(
        "fixed_site_reduced_ml",
        "fixed_site_additive_ml",
        "fixed_site_additive_reml",
        "fixed_site_heterogeneity_ml",
        "registered_random_site_benchmark_reml",
        "student_t_shifted_log_additive_reml",
        "triggered_gap_aware_ar_additive_reml"
      ),
      formula = c(
        h06d_shiftlog_formula_text(formulas$fixed_site_reduced),
        h06d_shiftlog_formula_text(formulas$fixed_site_additive),
        h06d_shiftlog_formula_text(formulas$fixed_site_additive),
        h06d_shiftlog_formula_text(formulas$fixed_site_heterogeneity),
        h06d_shiftlog_formula_text(formulas$registered_random_site),
        h06d_shiftlog_formula_text(formulas$fixed_site_additive),
        h06d_shiftlog_formula_text(
          h06d_shiftlog_formula_set(
            predictor$column[[1L]],
            ar = TRUE
          )$fixed_site_additive
        )
      ),
      family = c(
        rep("Gaussian identity on log10(L10 mean melEDI + 0.1 lx)", 5L),
        "Student-t identity on log10(L10 mean melEDI + 0.1 lx)",
        "Gaussian identity on log10(L10 mean melEDI + 0.1 lx) with AR(1)"
      ),
      fit_action = c(
        "FIT_AFTER_COMPUTE_CLEARANCE",
        "FIT_AFTER_COMPUTE_CLEARANCE",
        "REUSE_EXACT_VERIFIED_OBJECT",
        "FIT_AFTER_COMPUTE_CLEARANCE",
        "FIT_AFTER_COMPUTE_CLEARANCE",
        "FIT_AFTER_COMPUTE_CLEARANCE",
        "FIT_ONLY_IF_LAG_TRIGGER_AFTER_COMPUTE_CLEARANCE"
      )
    )
  }
)) |>
  dplyr::arrange(.data$predictor_order, .data$model_role)

static_verdict <- tibble::tibble(
  decision_id = "H06-D-003",
  change_id = "CHG-111",
  gate_id = "H06-D-G2P-L10-SHIFTLOG",
  input_pins = nrow(input_contract),
  input_pins_pass = all(input_contract$identity_pass),
  historical_manifest_entries = nrow(historical_preservation),
  historical_entries_preserved = sum(
    historical_preservation$preserved_byte_for_byte
  ),
  pilot_frames = nrow(frame_registry),
  current_source_frame_rebuilds_identical = all(
    frame_registry$current_source_rebuild_identical
  ),
  exact_reusable_additive_reml_objects = sum(
    reuse_verification$exact_reuse_authorized
  ),
  expected_exact_reusable_additive_reml_objects = 3L,
  model_fits_run = 0L,
  bh_fields_updated = 0L,
  deletion_refits_run = 0L,
  compute_status = "HELD_AWAITING_SEPARATE_COORDINATOR_CLEARANCE",
  static_disposition = paste0(
    "STATIC_CONTRACT_PASS; THREE_REML_ADDITIVE_OBJECTS_EXACTLY_REUSABLE; ",
    "NO_MODEL_LAUNCH"
  )
)

software <- tibble::tibble(
  software = c("R", required_packages),
  version = c(
    as.character(getRversion()),
    vapply(
      required_packages,
      function(package) as.character(utils::packageVersion(package)),
      character(1)
    )
  ),
  role = "H06-D-003 static contract and exact-reuse verification"
)

#####
# Step 4: Write only new shifted-log static artifacts
#####

outputs <- list(
  input_contract,
  historical_preservation,
  reuse_verification,
  reference_registry,
  static_verdict,
  formula_registry,
  frame_registry,
  software
)
names(outputs) <- c(
  file.path(
    roots$diagnostics,
    "H06_daily_l10_shiftlog_input_contract.csv"
  ),
  file.path(
    roots$diagnostics,
    "H06_daily_l10_shiftlog_historical_preservation_baseline.csv"
  ),
  file.path(
    roots$diagnostics,
    "H06_daily_l10_shiftlog_exact_reuse_verification.csv"
  ),
  file.path(
    roots$diagnostics,
    "H06_daily_l10_shiftlog_reference_registry.csv"
  ),
  file.path(
    roots$diagnostics,
    "H06_daily_l10_shiftlog_static_verdict.csv"
  ),
  file.path(
    roots$tables,
    "H06_daily_l10_shiftlog_formula_registry.csv"
  ),
  file.path(
    roots$model_data,
    "H06_daily_l10_shiftlog_pilot_frame_registry.csv"
  ),
  file.path(
    roots$manifests,
    "H06_daily_l10_shiftlog_static_software_manifest.csv"
  )
)
for (path in names(outputs)) {
  readr::write_csv(outputs[[path]], path)
}

historical_after <- historical_report_manifest |>
  dplyr::mutate(
    actual_sha256 = vapply(
      file.path(root, .data$relative_path),
      h06d_shiftlog_sha256,
      character(1)
    ),
    actual_bytes = unname(file.info(file.path(root, .data$relative_path))$size),
    preserved_byte_for_byte = .data$sha256 == .data$actual_sha256 &
      .data$bytes == .data$actual_bytes
  )
h06d_shiftlog_assert(
  all(historical_after$preserved_byte_for_byte),
  "Static shifted-log verification changed a historical H06-D-001/H06-D-002 file"
)

message(
  "H06-D-003 static verification complete: three exact reusable REML objects; ",
  "zero model fits; compute remains held."
)
