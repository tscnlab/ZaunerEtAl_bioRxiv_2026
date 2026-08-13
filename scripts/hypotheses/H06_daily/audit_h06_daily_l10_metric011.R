#!/usr/bin/env Rscript

# Static METRIC-011 gate. This script constructs and seals the complete L10
# component registry and the required change inventory. It fits no model.

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

required_packages <- c("digest", "dplyr", "readr", "tibble", "tidyr")
stopifnot(
  identical(as.character(getRversion()), "4.6.1"),
  all(vapply(required_packages, requireNamespace, logical(1), quietly = TRUE))
)

source(file.path(
  root,
  "scripts/hypotheses/H06_daily/h06_daily_l10_metric011_contract.R"
))
source(file.path(
  root,
  "scripts/hypotheses/H06_daily/h06_daily_l10_metric011_data.R"
))

roots <- h06d_l10_artifact_roots(root)
invisible(lapply(roots, dir.create, recursive = TRUE, showWarnings = FALSE))

input_contract <- h06d_l10_input_contract() |>
  dplyr::mutate(
    actual_sha256 = vapply(
      file.path(root, .data$relative_path),
      h06d_l10_sha256,
      character(1)
    ),
    identity_pass = .data$actual_sha256 == .data$expected_sha256
  )
h06d_l10_assert(
  all(input_contract$identity_pass),
  "At least one METRIC-011 input is outside its pinned identity"
)

base_manifest <- readr::read_csv(
  file.path(root, "artifacts/12_manifests/base_model_data_artifacts.csv"),
  show_col_types = FALSE
)
h06d_l10_assert(
  dplyr::n_distinct(base_manifest$input_bundle_sha256) == 1L &&
    unique(base_manifest$input_bundle_sha256) == h06d_l10_base_bundle_sha256(),
  "METRIC-011 base input-bundle identity failed"
)

# Freeze every pre-existing H06_daily scientific artifact, plus the historical
# 06/07 reports. New METRIC-011 paths are excluded because they are created by
# this amendment. This inventory is checked again after fitting and rendering.
artifact_dirs <- file.path(
  root,
  paste0(
    "artifacts/",
    sprintf("%02d", 6:12),
    c(
      "_model_data", "_models", "_diagnostics", "_tables", "_figures",
      "_source_data", "_manifests"
    ),
    "/H06_daily"
  )
)
protected_files <- unlist(lapply(
  artifact_dirs,
  function(path) {
    if (!dir.exists(path)) character() else list.files(
      path,
      recursive = TRUE,
      full.names = TRUE
    )
  }
), use.names = FALSE)
protected_files <- c(
  protected_files,
  file.path(
    root,
    "audit/hypotheses/H06_daily",
    c(
      "06_daily_ar_repair_pilot.qmd",
      "06_daily_ar_repair_pilot.html",
      "07_pre_sleep_no_nugget_diagnostic.qmd",
      "07_pre_sleep_no_nugget_diagnostic.html"
    )
  )
)
protected_files <- protected_files[
  file.exists(protected_files) &
    !grepl("H06_daily_l10_metric011", basename(protected_files), fixed = TRUE)
]
protected_files <- sort(unique(normalizePath(protected_files, winslash = "/")))
protected_baseline <- tibble::tibble(
  relative_path = substring(protected_files, nchar(root) + 2L),
  sha256_before = vapply(protected_files, h06d_l10_sha256, character(1)),
  bytes_before = as.numeric(file.info(protected_files)$size),
  preservation_scope = dplyr::case_when(
    grepl("pre_sleep_no_nugget|07_pre_sleep", .data$relative_path) ~
      "approved pre-sleep no-nugget branch: byte-for-byte frozen",
    TRUE ~ "pre-existing H06_daily artifact: no overwrite by METRIC-011"
  )
)

source_data <- h06d_l10_load_sources(root)
current <- h06d_l10_build_frames(source_data)
counterfactual <- h06d_l10_build_frames(
  h06d_l10_counterfactual_pre_metric011(source_data)
)
h06d_l10_assert(
  length(current$frames) == 36L && nrow(current$registry) == 36L,
  "METRIC-011 must define exactly 36 component frames"
)
h06d_l10_assert(
  identical(names(current$frames), names(counterfactual$frames)),
  "Current and pre-METRIC-011 counterfactual registries differ"
)

frame_paths <- character(nrow(current$registry))
frame_file_hashes <- character(nrow(current$registry))
for (index in seq_len(nrow(current$registry))) {
  key <- current$registry$frame_key[[index]]
  relative <- file.path(
    "artifacts/06_model_data/H06_daily",
    sprintf("H06_daily_l10_metric011__%s__frame.rds", key)
  )
  saveRDS(current$frames[[key]], file.path(root, relative), compress = "xz")
  frame_paths[[index]] <- relative
  frame_file_hashes[[index]] <- h06d_l10_sha256(file.path(root, relative))
}
frame_registry <- current$registry |>
  dplyr::mutate(
    frame_path = frame_paths,
    frame_file_sha256 = frame_file_hashes
  )

historical_bundle_relative <- paste0(
  "artifacts/07_models/H06_daily/",
  "H06_daily_stage2_pilot_daily_models.rds"
)
historical_bundle <- readRDS(file.path(root, historical_bundle_relative))
historical_map <- tibble::tribble(
  ~frame_key, ~subobject_path,
  paste(
    "primary__near_eye__all_available",
    "work_free_day",
    "zero_occurrence",
    sep = "__"
  ),
  "$`l10_two_part__zero_occurrence`$frame",
  paste(
    "primary__near_eye__all_available",
    "work_free_day",
    "positive_magnitude",
    sep = "__"
  ),
  "$`l10_two_part__positive_magnitude`$frame"
)

column_attribute_identity <- function(current_frame, prior_frame) {
  identical(attributes(current_frame), attributes(prior_frame)) &&
    identical(
      lapply(current_frame, attributes),
      lapply(prior_frame, attributes)
    )
}

inventory_rows <- lapply(seq_len(nrow(frame_registry)), function(index) {
  registry <- frame_registry[index, ]
  key <- registry$frame_key[[1L]]
  current_frame <- current$frames[[key]]
  prior_frame <- counterfactual$frames[[key]]
  map <- historical_map |>
    dplyr::filter(.data$frame_key == .env$key)
  historical_frame <- NULL
  if (nrow(map) == 1L) {
    historical_frame <- if (registry$component[[1L]] == "zero_occurrence") {
      historical_bundle[["l10_two_part__zero_occurrence"]]$frame
    } else {
      historical_bundle[["l10_two_part__positive_magnitude"]]$frame
    }
  }
  prior_fit_exists <- !is.null(historical_frame)
  historical_exact <- prior_fit_exists && identical(current_frame, historical_frame)
  prior_counterfactual_exact <- identical(current_frame, prior_frame)
  action <- dplyr::case_when(
    prior_fit_exists && historical_exact ~ "PRESERVE_ACCEPTED_FIT_BYTE_FOR_BYTE",
    registry$dataset_id[[1L]] == "primary" &&
      registry$metric011_changed_parent_rows[[1L]] > 0L ~
      "REFIT_REQUIRED_METRIC011",
    TRUE ~ "FIT_REQUIRED_TO_COMPLETE_PREVIOUSLY_HELD_BRANCH"
  )
  # The only historical L10 fits were bounded engineering-family pilots. They
  # were never production fits and are not preservation-eligible. Therefore a
  # coincidental object match cannot silently promote one to production.
  if (action == "PRESERVE_ACCEPTED_FIT_BYTE_FOR_BYTE") {
    action <- "FIT_REQUIRED_TO_COMPLETE_PREVIOUSLY_HELD_BRANCH"
  }
  tibble::tibble(
    run_order = registry$run_order[[1L]],
    run_id = registry$run_id[[1L]],
    dataset_id = registry$dataset_id[[1L]],
    placement_id = registry$placement_id[[1L]],
    sample_role = registry$sample_role[[1L]],
    predictor_order = registry$predictor_order[[1L]],
    predictor_id = registry$predictor_id[[1L]],
    component = registry$component[[1L]],
    current_rows = nrow(current_frame),
    pre_metric011_rows = nrow(prior_frame),
    row_identity_to_pre_metric011 = identical(
      as.character(current_frame$participant_day_key),
      as.character(prior_frame$participant_day_key)
    ),
    value_identity_to_pre_metric011 = identical(
      current_frame$response_source,
      prior_frame$response_source
    ) && identical(current_frame$response_value, prior_frame$response_value),
    attribute_identity_to_pre_metric011 = column_attribute_identity(
      current_frame,
      prior_frame
    ),
    exact_frame_identity_to_pre_metric011 = prior_counterfactual_exact,
    metric011_changed_parent_rows =
      registry$metric011_changed_parent_rows[[1L]],
    historical_fit_exists = prior_fit_exists,
    historical_fit_role = ifelse(
      prior_fit_exists,
      "bounded engineering-family pilot; not an accepted production input",
      "no previous fitted production component"
    ),
    historical_parent_path = ifelse(
      prior_fit_exists,
      historical_bundle_relative,
      NA_character_
    ),
    historical_parent_sha256 = ifelse(
      prior_fit_exists,
      h06d_l10_sha256(file.path(root, historical_bundle_relative)),
      NA_character_
    ),
    historical_subobject_path = ifelse(
      prior_fit_exists,
      map$subobject_path[[1L]],
      NA_character_
    ),
    exact_frame_identity_to_historical_fit = historical_exact,
    fit_action = action,
    action_reason = dplyr::case_when(
      action == "REFIT_REQUIRED_METRIC011" ~
        "shared primary L10 normalization changes this scenario parent",
      registry$dataset_id[[1L]] == "gap_timing_unaware" ~
        paste0(
          "gap L10 scientific values are invariant; no prior production ",
          "component exists, so this completes the held branch and is not a ",
          "METRIC-011 scientific repair"
        ),
      TRUE ~ paste0(
        "no accepted production component exists; fit only to complete the ",
        "previously held L10 branch"
      )
    )
  )
})
change_inventory <- dplyr::bind_rows(inventory_rows) |>
  dplyr::arrange(.data$predictor_order, .data$run_order, .data$component)
h06d_l10_assert(
  nrow(change_inventory) == 36L &&
    !any(change_inventory$fit_action == "PRESERVE_ACCEPTED_FIT_BYTE_FOR_BYTE"),
  "METRIC-011 change-inventory contract failed"
)
h06d_l10_assert(
  all(
    change_inventory$exact_frame_identity_to_pre_metric011[
      change_inventory$dataset_id == "gap_timing_unaware"
    ]
  ),
  "A gap L10 component changed under METRIC-011"
)

zero_audit <- source_data |>
  dplyr::filter(is.finite(.data$response_source), .data$response_source == 0) |>
  dplyr::transmute(
    dataset_id = .data$dataset_id,
    placement_id = .data$placement_id,
    site = as.character(.data$site),
    participant_hash = substr(
      vapply(
        as.character(.data$participant_key),
        digest::digest,
        character(1),
        algo = "sha256"
      ),
      1L,
      12L
    ),
    local_date = .data$local_date,
    exact_zero = TRUE,
    metric011_changed_source_cell = .data$metric011_changed_source_cell,
    component_handling = paste0(
      "retained as event in zero-occurrence component; excluded only from ",
      "strictly-positive magnitude"
    )
  ) |>
  dplyr::arrange(.data$dataset_id, .data$placement_id, .data$site, .data$local_date)

sample_summary <- frame_registry |>
  dplyr::select(
    "run_order", "run_id", "dataset_id", "placement_id", "sample_role",
    "analysis_role", "test_role", "predictor_order", "predictor_id",
    "component", "participant_days", "parent_participant_days",
    "participants", "sites", "parent_exact_zeros", "parent_positive_values",
    "metric011_changed_parent_rows"
  )

category_cells <- dplyr::bind_rows(lapply(
  seq_len(nrow(frame_registry)),
  function(index) {
    registry <- frame_registry[index, ]
    frame <- current$frames[[registry$frame_key[[1L]]]]
    predictor_id <- registry$predictor_id[[1L]]
    predictor <- h06d_l10_predictor_registry() |>
      dplyr::filter(.data$predictor_id == .env$predictor_id)
    column <- predictor$column[[1L]]
    if (predictor$type[[1L]] == "categorical") {
      frame |>
        dplyr::count(
          site = as.character(.data$site),
          level = as.character(.data[[column]]),
          name = "participant_days"
        )
    } else {
      frame |>
        dplyr::group_by(site = as.character(.data$site)) |>
        dplyr::summarise(
          level = "continuous support",
          participant_days = dplyr::n(),
          minimum = min(.data[[column]]),
          maximum = max(.data[[column]]),
          .groups = "drop"
        )
    } |>
      dplyr::mutate(
        run_id = registry$run_id[[1L]],
        predictor_id = predictor_id,
        component = registry$component[[1L]],
        .before = 1L
      )
  }
))

paths <- list(
  frame_registry = file.path(
    roots$model_data,
    "H06_daily_l10_metric011_frame_registry.csv"
  ),
  metric_contract = file.path(
    roots$model_data,
    "H06_daily_l10_metric011_metric_contract.csv"
  ),
  metric_slots = file.path(
    roots$model_data,
    "H06_daily_l10_metric011_metric_slot_registry.csv"
  ),
  change_inventory = file.path(
    roots$diagnostics,
    "H06_daily_l10_metric011_scenario_component_change_inventory.csv"
  ),
  sample_summary = file.path(
    roots$diagnostics,
    "H06_daily_l10_metric011_sample_summary.csv"
  ),
  category_cells = file.path(
    roots$diagnostics,
    "H06_daily_l10_metric011_category_cells.csv"
  ),
  zero_audit = file.path(
    roots$diagnostics,
    "H06_daily_l10_metric011_exact_zero_audit.csv"
  ),
  input_contract = file.path(
    roots$diagnostics,
    "H06_daily_l10_metric011_input_contract.csv"
  ),
  protected_baseline = file.path(
    roots$diagnostics,
    "H06_daily_l10_metric011_protected_baseline.csv"
  ),
  static_verdict = file.path(
    roots$diagnostics,
    "H06_daily_l10_metric011_static_verdict.csv"
  )
)

readr::write_csv(frame_registry, paths$frame_registry)
readr::write_csv(h06d_l10_metric_contract(), paths$metric_contract)
readr::write_csv(h06d_l10_metric_slot_registry(), paths$metric_slots)
readr::write_csv(change_inventory, paths$change_inventory)
readr::write_csv(sample_summary, paths$sample_summary)
readr::write_csv(category_cells, paths$category_cells)
readr::write_csv(zero_audit, paths$zero_audit)
readr::write_csv(input_contract, paths$input_contract)
readr::write_csv(protected_baseline, paths$protected_baseline)

static_verdict <- tibble::tibble(
  gate = "H06-D-G2P-L10-METRIC011-STATIC",
  input_pins_pass = all(input_contract$identity_pass),
  base_bundle_pass = TRUE,
  component_frames = nrow(frame_registry),
  expected_component_frames = 36L,
  current_primary_changed_cells = sum(
    source_data$dataset_id == "primary" &
      source_data$metric011_changed_source_cell
  ),
  expected_primary_changed_cells = 8L,
  gap_components_exactly_invariant = all(
    change_inventory$exact_frame_identity_to_pre_metric011[
      change_inventory$dataset_id == "gap_timing_unaware"
    ]
  ),
  accepted_fit_preservations = sum(
    change_inventory$fit_action == "PRESERVE_ACCEPTED_FIT_BYTE_FOR_BYTE"
  ),
  model_fits_run = 0L,
  disposition = "PASS_STATIC_GATE_MODEL_PILOT_ALLOWED"
)
readr::write_csv(static_verdict, paths$static_verdict)

code_paths <- c(
  "scripts/hypotheses/H06_daily/h06_daily_l10_metric011_contract.R",
  "scripts/hypotheses/H06_daily/h06_daily_l10_metric011_data.R",
  "scripts/hypotheses/H06_daily/audit_h06_daily_l10_metric011.R"
)
code_manifest <- tibble::tibble(
  relative_path = code_paths,
  sha256 = vapply(file.path(root, code_paths), h06d_l10_sha256, character(1)),
  role = c("contract", "frame construction", "static gate runner")
)
readr::write_csv(
  code_manifest,
  file.path(roots$manifests, "H06_daily_l10_metric011_static_code_manifest.csv")
)

software_manifest <- tibble::tibble(
  package = c("R", required_packages),
  version = c(
    as.character(getRversion()),
    vapply(required_packages, function(package) {
      as.character(utils::packageVersion(package))
    }, character(1))
  )
)
readr::write_csv(
  software_manifest,
  file.path(roots$manifests, "H06_daily_l10_metric011_static_software_manifest.csv")
)

output_paths <- c(
  unname(unlist(paths)),
  file.path(
    roots$manifests,
    c(
      "H06_daily_l10_metric011_static_code_manifest.csv",
      "H06_daily_l10_metric011_static_software_manifest.csv"
    )
  ),
  file.path(root, frame_registry$frame_path)
)
output_manifest <- tibble::tibble(
  relative_path = substring(output_paths, nchar(root) + 2L),
  sha256 = vapply(output_paths, h06d_l10_sha256, character(1)),
  bytes = as.numeric(file.info(output_paths)$size),
  producer = "scripts/hypotheses/H06_daily/audit_h06_daily_l10_metric011.R"
)
readr::write_csv(
  output_manifest,
  file.path(roots$manifests, "H06_daily_l10_metric011_static_output_manifest.csv")
)

message(
  "METRIC-011 static gate passed: ",
  nrow(frame_registry),
  " component frames; no model fitted."
)
