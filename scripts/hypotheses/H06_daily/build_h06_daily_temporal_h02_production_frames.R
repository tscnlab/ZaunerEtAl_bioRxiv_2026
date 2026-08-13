#!/usr/bin/env Rscript

# Build and statically audit the six author-approved H02-aligned temporal
# production frames. This stage performs no model fitting or association
# extraction.

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
stopifnot(
  identical(as.character(getRversion()), "4.6.1"),
  all(vapply(required_packages, requireNamespace, logical(1), quietly = TRUE))
)

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
  paste0(
    "scripts/hypotheses/H06_daily/",
    "h06_daily_temporal_h02_production_data.R"
  )
))

roots <- h06d_artifact_roots(root)
producer <- paste0(
  "scripts/hypotheses/H06_daily/",
  "build_h06_daily_temporal_h02_production_frames.R"
)
sha256 <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE)
}
relative_to_root <- function(path) {
  substring(path, nchar(root) + 2L)
}
write_csv <- function(data, path) {
  readr::write_csv(data, path, na = "")
  invisible(path)
}

input_contract <- tibble::tribble(
  ~input_id, ~relative_path, ~expected_sha256, ~analytical_role,
  "primary_near_eye_30_minute",
  "artifacts/06_model_data/base/metrics_glasses_30_minute_context.rds",
  "afa5a23308744ae495ef07a521c99e11bd7296aa855c5cb773f71f2b68eeb8e5",
  "prepared primary near-eye outcome grid",
  "primary_chest_30_minute",
  "artifacts/06_model_data/base/metrics_chest_30_minute_context.rds",
  "01a4a85e5ead5b30219f969c64d50b94a2bebf84b60cc4006badbc3c3c9513a2",
  "prepared primary chest outcome grid",
  "gap_timing_unaware_30_minute",
  paste0(
    "artifacts/06_model_data/scenarios/",
    "manuscript_prepared_data/thirty_minute_data.rds"
  ),
  "813453681cb24ca88cdf5f6b833824649f0e24e9f3bed5af80aad1c4f06fffdc",
  "prepared gap-timing-unaware outcome grid",
  "gap_timing_unaware_manifest",
  "artifacts/12_manifests/manuscript_prepared_data_artifacts.csv",
  "af74cc9fa36e426222d9b5f2328e2261c00b14436feb8d86fbf137d0ff313267",
  "prepared gap-timing-unaware artifact manifest",
  "base_model_data_manifest",
  "artifacts/12_manifests/base_model_data_artifacts.csv",
  "142d1044dd7e6a566e45e3a5c56033b1e8251e100c0d7c7523564c824950a0e4",
  "prepared primary model-data manifest",
  "wall_outcome_links",
  "artifacts/06_model_data/temporal_provenance/wall_outcome_links.rds",
  "69232e8f7bdfbf379e7f92a220d2ecad893bce38e9ec57add313f5545e62829a",
  "approved wall-to-true-time provenance",
  "temporal_provenance_manifest",
  "artifacts/06_model_data/temporal_provenance/artifact_manifest.csv",
  "9355f7ca4f249059cf49808a3fb1caf9e764a6160f5d61beba8234a2bfbdef7d",
  "approved temporal-provenance manifest",
  "exercise_diary",
  "artifacts/06_model_data/normalized_inputs/exercisediary.rds",
  "5bffe44cdd9c65f3d1dc20575d10b3f0a403577f3cf9109e83cfea95a2ae7107",
  "corrected immutable daily activity context",
  "sleep_diary",
  "artifacts/06_model_data/normalized_inputs/sleepdiaries.rds",
  "110819d74503c895170552c1f2214aca83de51cadd23bde7525aa821ee0b0e15",
  "work/free and previous-night sleep context",
  "site_display_registry",
  "config/site_display_registry.csv",
  "3d669d459ecc27d3154bbb5ff5b0d64cb510805d486b45264443228c44a6d809",
  "submitted site order and labels",
  "h02_selected_specification",
  "artifacts/07_models/H02/selected_temporal_model_specification.csv",
  "c3c95e97dbf7a260e4aa7513a15bb8c3c7e98bdb754d97c54700e4d82629310f",
  "frozen H02 structural specification",
  "h02_gap_near_eye_reference",
  paste0(
    "artifacts/06_model_data/H02/",
    "manuscript_prepared_data__glasses__all_available.rds"
  ),
  "be9eac0ef727912f32ebb21a1a4ceaf75f265afd6aaa5440732259ebb5737446",
  "read-only H02 gap-frame provenance cross-check",
  "h02_gap_chest_reference",
  paste0(
    "artifacts/06_model_data/H02/",
    "manuscript_prepared_data__chest__all_available.rds"
  ),
  "06d9ab3e4c8867efb3a254c3723a9893594b097a5aceee4a44b6e26f84a4921a",
  "read-only H02 gap-frame provenance cross-check",
  "corrected_near_eye_pilot_frame",
  paste0(
    "artifacts/06_model_data/H06_daily/",
    "H06_daily_temporal_h02_near_eye_frame.rds"
  ),
  "b774a4b36dca8d61940a78c08c89ec42592bef6c5d3596466f33f40c2f36bcb1",
  "read-only selected-pilot frame cross-check",
  "production_gate",
  paste0(
    "artifacts/08_diagnostics/H06_daily/",
    "H06_daily_temporal_h02_production_gate_contract.csv"
  ),
  "986743c70aef617d51c6aa601a18ac087808555271c9c0eca0d09abd70791db2",
  "author-approved pointwise-only production scope"
)

input_contract <- input_contract |>
  dplyr::mutate(
    observed_sha256 = vapply(
      file.path(root, .data$relative_path),
      sha256,
      character(1)
    ),
    hash_match = .data$observed_sha256 == .data$expected_sha256,
    bytes = unname(file.info(file.path(root, .data$relative_path))$size)
  )
if (!all(input_contract$hash_match)) {
  failed <- input_contract$input_id[!input_contract$hash_match]
  h06d_abort("Production input hash mismatch: %s", paste(failed, collapse = ", "))
}

frames <- h06d_h02_production_frames(root)
support <- h06d_h02_production_support(frames)
registry <- support$registry

# The reconstructed all-available primary near-eye frame must reproduce the
# selected pilot row-for-row for every consequential model variable.
pilot_reference <- readRDS(file.path(
  root,
  paste0(
    "artifacts/06_model_data/H06_daily/",
    "H06_daily_temporal_h02_near_eye_frame.rds"
  )
))
primary_near <- frames$primary__near_eye__all_available
pilot_columns <- c(
  h06d_h02_production_key(),
  "arithmetic_mean_medi_lx", "work_free_day", "activity_status",
  "previous_sleep_duration_h", "sleep_between_h", "sleep_within_h",
  "source_utc_start", "source_utc_end", "one_to_one_elapsed_coordinate",
  "elapsed_from_previous_seconds", "AR_start", "response"
)
pilot_exact <- isTRUE(all.equal(
  dplyr::select(primary_near, dplyr::all_of(pilot_columns)),
  dplyr::select(pilot_reference, dplyr::all_of(pilot_columns)),
  tolerance = 0,
  check.attributes = FALSE
))
if (!pilot_exact) {
  h06d_abort("Production primary near-eye frame differs from selected pilot")
}

# Each H06_daily gap frame must be an exact complete-context subset of the
# frozen H02 frame made from the same prepared grid and true-time provenance.
gap_crosscheck <- dplyr::bind_rows(lapply(
  c("near_eye", "chest"),
  function(placement_id) {
    position <- if (placement_id == "near_eye") "glasses" else "chest"
    run_id <- paste0(
      "gap_timing_unaware__", placement_id, "__all_available"
    )
    reference <- readRDS(file.path(
      root,
      "artifacts/06_model_data/H02",
      paste0(
        "manuscript_prepared_data__", position, "__all_available.rds"
      )
    ))
    observed <- frames[[run_id]] |>
      dplyr::select(
        dplyr::all_of(h06d_h02_production_key()),
        arithmetic_mean_medi_lx,
        source_utc_start,
        source_utc_end,
        one_to_one_elapsed_coordinate,
        relationship_type
      )
    comparison <- observed |>
      dplyr::left_join(
        reference |>
          dplyr::select(
            dplyr::all_of(h06d_h02_production_key()),
            reference_medi_lx = metric_value_lx,
            reference_source_utc_start = source_utc_start,
            reference_source_utc_end = source_utc_end,
            reference_one_to_one = one_to_one_elapsed_coordinate,
            reference_relationship_type = relationship_type
          ),
        by = h06d_h02_production_key(),
        relationship = "one-to-one"
      )
    tibble::tibble(
      run_id = run_id,
      observations = nrow(observed),
      reference_rows = nrow(reference),
      missing_reference_rows = sum(is.na(comparison$reference_medi_lx)),
      outcome_exact = all(
        comparison$arithmetic_mean_medi_lx == comparison$reference_medi_lx
      ),
      source_start_exact = all(
        comparison$source_utc_start == comparison$reference_source_utc_start
      ),
      source_end_exact = all(
        comparison$source_utc_end == comparison$reference_source_utc_end
      ),
      one_to_one_exact = identical(
        comparison$one_to_one_elapsed_coordinate,
        comparison$reference_one_to_one
      ),
      relationship_exact = identical(
        comparison$relationship_type,
        comparison$reference_relationship_type
      )
    )
  }
))
if (
  any(gap_crosscheck$missing_reference_rows != 0L) ||
    !all(gap_crosscheck$outcome_exact) ||
    !all(gap_crosscheck$source_start_exact) ||
    !all(gap_crosscheck$source_end_exact) ||
    !all(gap_crosscheck$one_to_one_exact) ||
    !all(gap_crosscheck$relationship_exact)
) {
  h06d_abort("Gap-timing-unaware H02 provenance cross-check failed")
}

context_gate <- support$context_cells |>
  dplyr::summarise(
    context_cells = dplyr::n(),
    minimum_participant_days = min(.data$participant_days),
    minimum_sites = min(.data$sites),
    .by = "run_id"
  )
sleep_gate <- support$sleep_support |>
  dplyr::summarise(
    minimum_within_sleep_sd_h = min(.data$within_sleep_sd_h),
    minimum_between_sleep_sd_h = min(.data$between_sleep_sd_h),
    .by = "run_id"
  )
static_gate <- support$overall |>
  dplyr::select(
    run_order, run_id, data_scenario_id, placement_id, sample_scenario,
    observations_30_minute, participant_days, participants, sites
  ) |>
  dplyr::left_join(context_gate, by = "run_id", relationship = "one-to-one") |>
  dplyr::left_join(sleep_gate, by = "run_id", relationship = "one-to-one") |>
  dplyr::mutate(
    exact_four_context_cells = .data$context_cells == 4L,
    context_support_acceptable =
      .data$minimum_participant_days >= 30L & .data$minimum_sites >= 5L,
    sleep_support_acceptable =
      .data$minimum_within_sleep_sd_h > 0 &
        .data$minimum_between_sleep_sd_h > 0,
    temporal_provenance_acceptable = vapply(
      .data$run_id,
      function(run_id) {
        frame <- frames[[run_id]]
        all(frame$elapsed_from_previous_seconds[!frame$AR_start] == 0) &&
          all(frame$one_to_one_elapsed_coordinate[!frame$AR_start])
      },
      logical(1)
    ),
    formula_estimable_static =
      .data$exact_four_context_cells &
        .data$context_support_acceptable &
        .data$sleep_support_acceptable &
        .data$temporal_provenance_acceptable,
    static_gate = dplyr::if_else(
      .data$formula_estimable_static,
      "PASS",
      "FAIL"
    )
  ) |>
  dplyr::arrange(.data$run_order)
if (
  !all(static_gate$static_gate == "PASS") ||
    !isTRUE(support$paired_audit$keys_identical) ||
    support$paired_audit$near_eye_observations !=
      support$paired_audit$chest_observations ||
    !pilot_exact
) {
  h06d_abort("One or more temporal production frames failed the static gate")
}

frame_paths <- file.path(
  roots$model_data,
  paste0(
    "H06_daily_temporal_h02_production__",
    registry$run_id,
    "__frame.rds"
  )
)
for (i in seq_len(nrow(registry))) {
  saveRDS(frames[[registry$run_id[[i]]]], frame_paths[[i]], version = 3)
}

table_paths <- c(
  registry = file.path(
    roots$model_data,
    "H06_daily_temporal_h02_production_run_registry.csv"
  ),
  overall_support = file.path(
    roots$diagnostics,
    "H06_daily_temporal_h02_production_support_overall.csv"
  ),
  context_cells = file.path(
    roots$diagnostics,
    "H06_daily_temporal_h02_production_context_cells.csv"
  ),
  sleep_support = file.path(
    roots$diagnostics,
    "H06_daily_temporal_h02_production_sleep_support_by_site.csv"
  ),
  ar_boundaries = file.path(
    roots$diagnostics,
    "H06_daily_temporal_h02_production_ar_boundaries.csv"
  ),
  paired_audit = file.path(
    roots$diagnostics,
    "H06_daily_temporal_h02_production_paired_common_audit.csv"
  ),
  gap_crosscheck = file.path(
    roots$diagnostics,
    "H06_daily_temporal_h02_production_gap_h02_crosscheck.csv"
  ),
  static_gate = file.path(
    roots$diagnostics,
    "H06_daily_temporal_h02_production_static_gate.csv"
  )
)
tables <- list(
  registry,
  support$overall,
  support$context_cells,
  support$sleep_support,
  support$ar_boundaries,
  support$paired_audit,
  gap_crosscheck,
  static_gate
)
invisible(Map(write_csv, tables, table_paths))

input_manifest_path <- file.path(
  roots$manifests,
  "H06_daily_temporal_h02_production_frame_input_manifest.csv"
)
code_manifest_path <- file.path(
  roots$manifests,
  "H06_daily_temporal_h02_production_frame_code_manifest.csv"
)
output_manifest_path <- file.path(
  roots$manifests,
  "H06_daily_temporal_h02_production_frame_output_manifest.csv"
)
software_manifest_path <- file.path(
  roots$manifests,
  "H06_daily_temporal_h02_production_frame_software_manifest.csv"
)
write_csv(input_contract, input_manifest_path)

code_relative <- c(
  "scripts/hypotheses/H06_daily/h06_daily_contract.R",
  "scripts/hypotheses/H06_daily/h06_daily_data.R",
  paste0(
    "scripts/hypotheses/H06_daily/",
    "h06_daily_temporal_h02_production_data.R"
  ),
  producer
)
code_manifest <- tibble::tibble(
  relative_path = code_relative,
  sha256 = vapply(file.path(root, code_relative), sha256, character(1)),
  bytes = unname(file.info(file.path(root, code_relative))$size)
)
write_csv(code_manifest, code_manifest_path)

output_paths <- c(
  frame_paths,
  unname(table_paths),
  input_manifest_path,
  code_manifest_path,
  software_manifest_path
)
software <- tibble::tibble(
  component = c("R", required_packages),
  version = c(
    as.character(getRversion()),
    vapply(
      required_packages,
      function(package) as.character(utils::packageVersion(package)),
      character(1)
    )
  )
)
write_csv(software, software_manifest_path)
output_paths <- c(
  frame_paths,
  unname(table_paths),
  input_manifest_path,
  code_manifest_path,
  software_manifest_path
)
output_manifest <- tibble::tibble(
  relative_path = vapply(output_paths, relative_to_root, character(1)),
  sha256 = vapply(output_paths, sha256, character(1)),
  bytes = unname(file.info(output_paths)$size),
  producer = producer,
  r_version = as.character(getRversion())
)
write_csv(output_manifest, output_manifest_path)

message(
  "H06-D-G2P-H02 static production gate: PASS for ",
  nrow(static_gate),
  " frames"
)
