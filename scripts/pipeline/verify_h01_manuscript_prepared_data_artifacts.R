# Verify the H01 manuscript-prepared-data sensitivity artifacts.
#
# Source the files required by build_h01_manuscript_prepared_data.R plus
# verify_h01_model_data_artifacts.R before this file.

h01_manuscript_prepared_expected_model_samples <- function(contract) {
  daily_metrics <- contract$metric_id[
    contract$analysis_unit == "participant_day"
  ]
  all_available <- dplyr::bind_rows(
    tibble::tibble(
      placement = "glasses",
      scenario = "all_available",
      metric_id = contract$metric_id,
      model_observations = c(
        141L,
        141L,
        rep(811L, 4L),
        755L,
        780L,
        790L,
        rep(811L, 3L),
        rep(778L, 3L),
        811L,
        725L
      ),
      participants = c(
        141L,
        141L,
        rep(141L, 4L),
        140L,
        141L,
        141L,
        rep(141L, 3L),
        rep(141L, 3L),
        141L,
        140L
      ),
      participant_days = c(
        NA_integer_,
        NA_integer_,
        rep(811L, 4L),
        755L,
        780L,
        790L,
        rep(811L, 3L),
        rep(778L, 3L),
        811L,
        725L
      ),
      contributing_participant_days = c(
        811L,
        811L,
        rep(811L, 4L),
        755L,
        780L,
        790L,
        rep(811L, 3L),
        rep(778L, 3L),
        811L,
        725L
      ),
      sites = 9L
    ),
    tibble::tibble(
      placement = "chest",
      scenario = "all_available",
      metric_id = contract$metric_id,
      model_observations = c(
        154L,
        154L,
        rep(897L, 4L),
        839L,
        867L,
        878L,
        rep(897L, 3L),
        rep(867L, 3L),
        897L,
        729L
      ),
      participants = c(
        154L,
        154L,
        rep(154L, 4L),
        153L,
        154L,
        154L,
        rep(154L, 3L),
        rep(154L, 3L),
        154L,
        154L
      ),
      participant_days = c(
        NA_integer_,
        NA_integer_,
        rep(897L, 4L),
        839L,
        867L,
        878L,
        rep(897L, 3L),
        rep(867L, 3L),
        897L,
        729L
      ),
      contributing_participant_days = c(
        897L,
        897L,
        rep(897L, 4L),
        839L,
        867L,
        878L,
        rep(897L, 3L),
        rep(867L, 3L),
        897L,
        729L
      ),
      sites = 8L
    )
  )
  paired_observations <- stats::setNames(
    rep(640L, length(daily_metrics)),
    daily_metrics
  )
  paired_participants <- stats::setNames(
    rep(112L, length(daily_metrics)),
    daily_metrics
  )
  paired_special_metrics <- c(
    "duration_above_250_wake",
    "duration_below_10_pre_sleep",
    "duration_below_1_sleep_environment",
    "mean_timing_above_250",
    "first_timing_above_250",
    "last_timing_above_250",
    "mder_ratio_of_integrals"
  )
  paired_observations[paired_special_metrics] <- c(
    592L,
    615L,
    621L,
    603L,
    603L,
    603L,
    476L
  )
  paired_participants[c(
    "duration_above_250_wake",
    "mder_ratio_of_integrals"
  )] <- c(111L, 111L)
  paired <- tidyr::crossing(
    placement = h01_placements(),
    scenario = "paired_common_sample",
    metric_id = daily_metrics
  ) |>
    dplyr::mutate(
      model_observations = unname(paired_observations[.data$metric_id]),
      participants = unname(paired_participants[.data$metric_id]),
      participant_days = .data$model_observations,
      contributing_participant_days = .data$model_observations,
      sites = 8L
    )
  dplyr::bind_rows(all_available, paired) |>
    dplyr::arrange(
      factor(.data$scenario, levels = h01_scenarios()),
      factor(.data$placement, levels = h01_placements()),
      match(.data$metric_id, contract$metric_id)
    )
}

h01_manuscript_prepared_verify_sample_sizes <- function(
  sample_flow,
  contract
) {
  observed <- sample_flow |>
    dplyr::filter(
      .data$stage == "site_photoperiod_model",
      .data$scope == "overall",
      .data$status == "AVAILABLE"
    ) |>
    dplyr::select(
      "placement",
      "scenario",
      "metric_id",
      "model_observations",
      "participants",
      "participant_days",
      "contributing_participant_days",
      "sites",
      "participant_hours",
      "metric_support_missing_observations",
      "metric_support_valid_hours",
      "metric_support_expected_hours",
      "prepared_record_support_missing_observations",
      "prepared_record_valid_melEDI_hours",
      "prepared_record_valid_illuminance_hours"
    )
  expected <- h01_manuscript_prepared_expected_model_samples(contract)
  observed_counts <- observed |>
    dplyr::select(dplyr::all_of(names(expected))) |>
    dplyr::arrange(
      factor(.data$scenario, levels = h01_scenarios()),
      factor(.data$placement, levels = h01_placements()),
      match(.data$metric_id, contract$metric_id)
    )
  if (
    !isTRUE(all.equal(
      observed_counts,
      expected,
      check.attributes = FALSE,
      tolerance = 0
    )) ||
      any(!is.na(observed$participant_hours)) ||
      any(
        observed$metric_support_missing_observations !=
          observed$model_observations
      ) ||
      any(!is.na(observed$metric_support_valid_hours)) ||
      any(!is.na(observed$metric_support_expected_hours)) ||
      any(
        observed$prepared_record_support_missing_observations !=
          observed$model_observations
      ) ||
      any(!is.na(observed$prepared_record_valid_melEDI_hours)) ||
      any(
        !is.na(
          observed$prepared_record_valid_illuminance_hours
        )
      )
  ) {
    h01_abort(
      "H01 manuscript-prepared model-frame sample sizes differ"
    )
  }
  invisible(observed)
}

verify_h01_manuscript_prepared_data_artifacts <- function(
  root = project_root(),
  output_root = root
) {
  root <- normalizePath(root, winslash = "/", mustWork = TRUE)
  output_root <- normalizePath(
    output_root,
    winslash = "/",
    mustWork = TRUE
  )
  if (!identical(as.character(getRversion()), "4.6.1")) {
    h01_abort(
      paste0(
        "H01 manuscript-prepared verification requires R 4.6.1; ",
        "found %s"
      ),
      as.character(getRversion())
    )
  }
  upstream <- verify_manuscript_prepared_data_artifacts(
    root = root,
    output_root = root
  )
  main_verification <- verify_h01_model_data_artifacts(
    root = root,
    output_root = root
  )
  site_verification <- verify_site_solar_context_artifacts(
    root = root,
    input_root = root
  )
  if (
    !identical(upstream$status, "PASS") ||
      !identical(
        main_verification$status,
        "PASS_WITH_DECLARED_UNAVAILABLE_SCENARIO"
      ) ||
      !identical(site_verification$status, "PASS")
  ) {
    h01_abort(
      "An upstream artifact failed before H01 sensitivity verification"
    )
  }
  paths <- h01_manuscript_prepared_output_paths(root, output_root)
  expected_scenario_files <- sort(c(
    basename(paths$rds),
    basename(paths$csv)
  ))
  observed_scenario_files <- sort(list.files(paths$scenario_root))
  if (!identical(observed_scenario_files, expected_scenario_files)) {
    h01_abort(
      paste0(
        "H01 manuscript-prepared output directory contains missing or ",
        "undeclared files"
      )
    )
  }
  required <- c(paths$rds, paths$csv, paths$manifest)
  missing <- required[!file.exists(required)]
  if (length(missing) > 0L) {
    h01_abort(
      "H01 manuscript-prepared artifact is missing: %s",
      paste(missing, collapse = ", ")
    )
  }
  manifest <- readr::read_csv(
    paths$manifest,
    show_col_types = FALSE,
    progress = FALSE
  )
  expected_ids <- c("H01", names(paths$csv))
  expected_paths <- c(H01 = paths$rds, paths$csv)
  if (
    !identical(
      names(manifest),
      h01_manuscript_prepared_manifest_columns()
    ) ||
      !identical(manifest$artifact_id, expected_ids) ||
      anyDuplicated(manifest$artifact_id) ||
      nrow(manifest) != length(expected_ids) ||
      any(
        manifest$data_scenario_id != h01_manuscript_prepared_scenario_id()
      ) ||
      any(
        manifest$model_implementation_id !=
          h01_manuscript_prepared_model_implementation_id()
      )
  ) {
    h01_abort(
      "H01 manuscript-prepared manifest differs from its schema"
    )
  }
  producer <-
    "scripts/pipeline/build_h01_manuscript_prepared_data.R"
  for (index in seq_len(nrow(manifest))) {
    artifact_id <- manifest$artifact_id[[index]]
    path <- expected_paths[[artifact_id]]
    artifact <- h01_verify_artifact_object(
      path,
      manifest$artifact_type[[index]]
    )
    rows <- if (artifact_id == "H01") {
      nrow(artifact$model_rows)
    } else {
      nrow(artifact)
    }
    columns <- if (artifact_id == "H01") {
      ncol(artifact$model_rows)
    } else {
      ncol(artifact)
    }
    if (
      h01_relative_path(path, output_root) != manifest$path[[index]] ||
        artifact_sha256(path) != manifest$sha256[[index]] ||
        unname(file.info(path)$size) != manifest$bytes[[index]] ||
        rows != manifest$rows[[index]] ||
        columns != manifest$columns[[index]] ||
        manifest$producer[[index]] != producer ||
        manifest$r_version[[index]] != "4.6.1" ||
        manifest$status[[index]] != "PASS"
    ) {
      h01_abort(
        "H01 manuscript-prepared manifest failed for `%s`",
        artifact_id
      )
    }
  }

  object <- readRDS(paths$rds)
  expected_status <- paste0(
    "PASS_WITH_DECLARED_UNAVAILABLE_SUPPORT_",
    "AND_PAIRED_PARTICIPANT_METRICS"
  )
  if (
    !identical(
      names(object),
      h01_manuscript_prepared_object_contract()
    ) ||
      object$hypothesis_id != "H01" ||
      object$status != expected_status ||
      object$metadata$data_scenario_id !=
        h01_manuscript_prepared_scenario_id() ||
      object$metadata$model_implementation_id !=
        h01_manuscript_prepared_model_implementation_id()
  ) {
    h01_abort(
      "H01 manuscript-prepared RDS differs from its top-level contract"
    )
  }
  csv_members <- list(
    model_rows = object$model_rows,
    metric_contract = object$metric_contract,
    sample_flow = object$sample_flow,
    exclusion_reasons = object$exclusion_reasons,
    scenario_status = object$scenario_status,
    predictor_centers = object$predictor_centers,
    variable_dictionary = object$variable_dictionary,
    input_provenance = object$input_provenance,
    contract_equivalence = object$contract_equivalence,
    timing_conversion_audit = object$timing_conversion_audit
  )
  for (artifact_id in names(csv_members)) {
    csv <- readr::read_csv(
      paths$csv[[artifact_id]],
      show_col_types = FALSE,
      progress = FALSE
    )
    if (!h01_csv_content_equal(csv_members[[artifact_id]], csv)) {
      h01_abort(
        "H01 manuscript-prepared `%s` CSV differs from its RDS member",
        artifact_id
      )
    }
  }

  contract <- object$metric_contract
  main_contract <- h01_metric_contract(root)
  if (
    nrow(contract) != 17L ||
      h01_implementation_contract_sha256(contract) !=
        h01_implementation_contract_sha256(main_contract)
  ) {
    h01_abort(
      "H01 manuscript-prepared metric contract changed implementation"
    )
  }
  equivalence <- object$contract_equivalence
  if (
    nrow(equivalence) != 17L ||
      any(!equivalence$implementation_fields_match) ||
      any(!equivalence$data_scenario_ids_differ) ||
      any(!equivalence$model_implementation_ids_match) ||
      any(
        equivalence$main_implementation_contract_sha256 !=
          equivalence$scenario_implementation_contract_sha256
      ) ||
      any(
        equivalence$main_shared_implementation_sha256 !=
          object$metadata$shared_implementation_sha256
      ) ||
      any(equivalence$main_data_scenario_id != "main")
  ) {
    h01_abort(
      "H01 data-scenario and implementation identity proof failed"
    )
  }
  timing <- object$timing_conversion_audit
  if (
    nrow(timing) != 10L ||
      sum(timing$negative_input_values) != 62L ||
      sum(timing$wrapped_values) != 62L ||
      any(
        timing$input_values_outside_0_24[
          timing$metric_id != "l10_midpoint"
        ] !=
          0L
      ) ||
      any(timing$output_min_clock_minute < 0) ||
      any(timing$output_max_clock_minute >= 1440) ||
      any(timing$input_unit != "decimal_clock_hour") ||
      any(timing$output_unit != "clock_minute")
  ) {
    h01_abort(
      "H01 manuscript-prepared timing audit differs from its contract"
    )
  }

  rows <- object$model_rows
  if (
    nrow(rows) != 45410L ||
      sum(
        rows$scenario == "all_available" &
          rows$placement == "glasses"
      ) !=
        12447L ||
      sum(
        rows$scenario == "all_available" &
          rows$placement == "chest"
      ) !=
        13763L ||
      sum(
        rows$scenario == "paired_common_sample" &
          rows$placement == "glasses"
      ) !=
        9600L ||
      sum(
        rows$scenario == "paired_common_sample" &
          rows$placement == "chest"
      ) !=
        9600L ||
      any(
        rows$data_scenario_id != h01_manuscript_prepared_scenario_id()
      ) ||
      any(
        rows$model_implementation_id !=
          h01_manuscript_prepared_model_implementation_id()
      ) ||
      any(rows$prepared_record_support_available) ||
      any(rows$metric_support_available) ||
      any(!is.na(rows$prepared_record_expected_minutes)) ||
      any(!is.na(rows$prepared_record_valid_melEDI_minutes)) ||
      any(
        !is.na(rows$prepared_record_valid_illuminance_minutes)
      ) ||
      any(!is.na(rows$metric_support_valid_minutes)) ||
      any(!is.na(rows$metric_support_expected_minutes)) ||
      any(
        rows$prepared_record_support_unavailability_reason !=
          h01_manuscript_prepared_support_reason()
      ) ||
      any(
        rows$metric_support_unavailability_reason !=
          h01_manuscript_prepared_support_reason()
      )
  ) {
    h01_abort(
      "H01 manuscript-prepared row or support contract changed"
    )
  }
  expected_construct <- h01_manuscript_prepared_measurement_construct(
    rows$placement
  )
  if (
    anyNA(expected_construct) ||
      any(rows$measurement_construct != expected_construct)
  ) {
    h01_abort(
      "H01 manuscript-prepared placement construct is mislabeled"
    )
  }
  h01_verify_model_row_keys(rows)
  h01_verify_scenario_estimability(rows)
  h01_verify_paired_model_frames(rows, "site_photoperiod_included")
  h01_verify_paired_model_frames(
    rows,
    "latitude_photoperiod_included"
  )
  h01_verify_predictor_centers(rows)
  rebuilt <- h01_build_manuscript_prepared_inputs(root)
  rebuilt_centered <- h01_build_model_rows_from_inputs(
    inputs = rebuilt$inputs,
    contract = rebuilt$contract,
    data_scenario_id = h01_manuscript_prepared_scenario_id(),
    model_implementation_id = h01_manuscript_prepared_model_implementation_id()
  )
  rebuilt_rows <- rebuilt_centered$rows |>
    dplyr::arrange(
      factor(.data$scenario, levels = h01_scenarios()),
      factor(.data$placement, levels = h01_placements()),
      .data$metric_order,
      .data$site,
      .data$Id,
      .data$local_date
    )
  main_object <- readRDS(h01_model_data_paths(root, root)$rds)
  rebuilt_equivalence <- rebuilt$contract_equivalence |>
    dplyr::mutate(
      main_data_scenario_id = main_object$metadata$data_scenario_id,
      data_scenario_ids_differ = .data$main_data_scenario_id !=
        .data$data_scenario_id,
      main_model_implementation_id = main_object$metadata$model_implementation_id,
      model_implementation_ids_match = .data$main_model_implementation_id ==
        .data$model_implementation_id,
      main_shared_implementation_sha256 = main_object$metadata$shared_implementation_sha256,
      .after = "model_implementation_id"
    )
  rebuilt_scenario_status <- h01_scenario_status(
    rebuilt$contract,
    data_scenario_id = h01_manuscript_prepared_scenario_id(),
    model_implementation_id = h01_manuscript_prepared_model_implementation_id()
  )
  if (
    !isTRUE(all.equal(
      object$model_rows,
      rebuilt_rows,
      check.attributes = FALSE,
      tolerance = 0
    )) ||
      !isTRUE(all.equal(
        object$metric_contract,
        rebuilt$contract,
        check.attributes = FALSE,
        tolerance = 0
      )) ||
      !isTRUE(all.equal(
        object$predictor_centers,
        rebuilt_centered$centers,
        check.attributes = FALSE,
        tolerance = 0
      )) ||
      !isTRUE(all.equal(
        object$contract_equivalence,
        rebuilt_equivalence,
        check.attributes = FALSE,
        tolerance = 0
      )) ||
      !isTRUE(all.equal(
        object$timing_conversion_audit,
        rebuilt$timing_conversion_audit,
        check.attributes = FALSE,
        tolerance = 0
      )) ||
      !isTRUE(all.equal(
        object$scenario_status,
        rebuilt_scenario_status,
        check.attributes = FALSE,
        tolerance = 0
      )) ||
      !isTRUE(all.equal(
        object$variable_dictionary,
        h01_variable_dictionary(),
        check.attributes = FALSE,
        tolerance = 0
      ))
  ) {
    h01_abort(
      paste0(
        "H01 manuscript-prepared artifact differs from an independent ",
        "rebuild of its verified inputs"
      )
    )
  }
  expected_flow <- h01_build_sample_flow(
    rows,
    object$scenario_status
  )
  expected_exclusions <- h01_build_exclusion_summary(
    rows,
    object$scenario_status
  )
  if (
    !isTRUE(all.equal(
      object$sample_flow,
      expected_flow,
      check.attributes = FALSE,
      tolerance = 0
    )) ||
      !isTRUE(all.equal(
        object$exclusion_reasons,
        expected_exclusions,
        check.attributes = FALSE,
        tolerance = 0
      ))
  ) {
    h01_abort(
      "H01 manuscript-prepared sample flow does not reconcile"
    )
  }
  model_samples <- h01_manuscript_prepared_verify_sample_sizes(
    object$sample_flow,
    contract
  )
  latitude_samples <- object$sample_flow |>
    dplyr::filter(
      .data$stage == "latitude_photoperiod_model",
      .data$scope == "overall",
      .data$status == "AVAILABLE"
    ) |>
    dplyr::select(
      "placement",
      "scenario",
      "metric_id",
      "model_observations",
      "participants",
      "participant_days",
      "contributing_participant_days",
      "sites"
    )
  site_samples <- model_samples |>
    dplyr::select(dplyr::all_of(names(latitude_samples)))
  latitude_samples <- latitude_samples |>
    dplyr::arrange(
      factor(.data$scenario, levels = h01_scenarios()),
      factor(.data$placement, levels = h01_placements()),
      match(.data$metric_id, contract$metric_id)
    )
  site_samples <- site_samples |>
    dplyr::arrange(
      factor(.data$scenario, levels = h01_scenarios()),
      factor(.data$placement, levels = h01_placements()),
      match(.data$metric_id, contract$metric_id)
    )
  if (
    !isTRUE(all.equal(
      latitude_samples,
      site_samples,
      check.attributes = FALSE,
      tolerance = 0
    ))
  ) {
    h01_abort(
      "H01 latitude and site model-frame sample sizes differ"
    )
  }

  provenance <- object$input_provenance
  expected_provenance <- tibble::tribble(
    ~input_id,
    ~input_role,
    "manuscript_prepared_participant_day_metrics",
    "scenario_participant_day_metric_rds",
    "manuscript_prepared_participant_metrics",
    "scenario_participant_metric_rds",
    "manuscript_prepared_metric_crosswalk",
    "scenario_metric_crosswalk_csv",
    "manuscript_prepared_normalized_input_references",
    "scenario_normalized_input_reference_rds",
    "manuscript_prepared_artifact_manifest",
    "scenario_input_manifest_csv",
    "main_h01_model_data",
    "main_h01_model_data_rds",
    "main_h01_model_data_manifest",
    "main_h01_model_data_manifest_csv",
    "site_solar_context",
    "verified_site_solar_context_rds",
    "site_solar_context_manifest",
    "site_context_manifest_csv",
    "metric_display_registry",
    "display_registry_csv",
    "shared_h01_model_data_implementation",
    "shared_r_implementation",
    "manuscript_prepared_h01_adapter",
    "scenario_r_adapter",
    "manuscript_prepared_h01_builder",
    "scenario_r_builder"
  )
  if (
    !identical(
      names(provenance),
      c(
        "input_id",
        "input_role",
        "path",
        "sha256",
        "bytes",
        "rows",
        "columns",
        "upstream_manifest_path",
        "upstream_manifest_sha256",
        "r_version",
        "status"
      )
    ) ||
      !identical(
        provenance[c("input_id", "input_role")],
        expected_provenance
      ) ||
      anyDuplicated(provenance$input_id) ||
      nrow(provenance) != 13L ||
      any(provenance$status != "PASS") ||
      any(provenance$r_version != "4.6.1")
  ) {
    h01_abort(
      "H01 manuscript-prepared input provenance is incomplete"
    )
  }
  for (index in seq_len(nrow(provenance))) {
    path <- h01_declared_absolute_path(
      provenance$path[[index]],
      root
    )
    if (
      artifact_sha256(path) != provenance$sha256[[index]] ||
        unname(file.info(path)$size) != provenance$bytes[[index]]
    ) {
      h01_abort(
        "H01 manuscript-prepared input changed for `%s`",
        provenance$input_id[[index]]
      )
    }
    upstream_path <- provenance$upstream_manifest_path[[index]]
    if (!is.na(upstream_path)) {
      upstream_path <- h01_declared_absolute_path(
        upstream_path,
        root
      )
      if (
        artifact_sha256(upstream_path) !=
          provenance$upstream_manifest_sha256[[index]]
      ) {
        h01_abort(
          "H01 manuscript-prepared upstream manifest changed"
        )
      }
    }
  }
  input_bundle_text <- paste(
    paste(
      provenance$input_id,
      provenance$sha256,
      provenance$upstream_manifest_sha256,
      sep = "="
    ),
    collapse = "|"
  )
  input_bundle_sha256 <- h01_text_sha256(input_bundle_text)
  scenario_input_manifest_sha256 <- artifact_sha256(
    paths$source$manifest
  )
  site_context_manifest_sha256 <- artifact_sha256(file.path(
    root,
    "artifacts",
    "12_manifests",
    "site_solar_context_artifacts.csv"
  ))
  shared_implementation_sha256 <- artifact_sha256(file.path(
    root,
    "scripts",
    "pipeline",
    "h01_model_data.R"
  ))
  if (
    object$metadata$input_bundle_sha256 != input_bundle_sha256 ||
      object$metadata$scenario_input_manifest_sha256 !=
        scenario_input_manifest_sha256 ||
      object$metadata$site_context_manifest_sha256 !=
        site_context_manifest_sha256 ||
      object$metadata$implementation_contract_sha256 !=
        h01_implementation_contract_sha256(contract) ||
      object$metadata$shared_implementation_sha256 !=
        shared_implementation_sha256 ||
      any(manifest$input_bundle_sha256 != input_bundle_sha256) ||
      any(
        manifest$scenario_input_manifest_sha256 !=
          scenario_input_manifest_sha256
      ) ||
      any(
        manifest$site_context_manifest_sha256 != site_context_manifest_sha256
      ) ||
      any(
        manifest$implementation_contract_sha256 !=
          object$metadata$implementation_contract_sha256
      ) ||
      any(
        manifest$shared_implementation_sha256 != shared_implementation_sha256
      )
  ) {
    h01_abort(
      "H01 manuscript-prepared manifest provenance changed"
    )
  }

  list(
    status = object$status,
    data_scenario_id = object$metadata$data_scenario_id,
    model_implementation_id = object$metadata$model_implementation_id,
    model_rows = nrow(rows),
    all_available_glasses_rows = sum(
      rows$scenario == "all_available" &
        rows$placement == "glasses"
    ),
    all_available_chest_rows = sum(
      rows$scenario == "all_available" &
        rows$placement == "chest"
    ),
    paired_daily_keys = nrow(h01_paired_common_day_keys(rows)),
    implementation_contract_sha256 = object$metadata$implementation_contract_sha256,
    shared_implementation_sha256 = object$metadata$shared_implementation_sha256,
    manifest_sha256 = artifact_sha256(paths$manifest),
    model_samples = model_samples
  )
}
