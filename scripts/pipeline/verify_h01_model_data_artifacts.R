# Verify the H01 model-data artifact and its audit-facing CSV contract.
#
# Source paths_io.R, assertions.R, metric_display_registry.R,
# h01_model_data.R, and build_h01_model_data.R before this file.

h01_verify_artifact_object <- function(path, artifact_type) {
  if (artifact_type == "rds") {
    return(readRDS(path))
  }
  readr::read_csv(path, show_col_types = FALSE, progress = FALSE)
}

h01_csv_content_equal <- function(expected, observed) {
  if (
    !identical(names(expected), names(observed)) ||
      nrow(expected) != nrow(observed)
  ) {
    return(FALSE)
  }
  equal_column <- function(target, current) {
    if (inherits(target, "Date")) {
      return(
        inherits(current, "Date") &&
          identical(as.character(target), as.character(current))
      )
    }
    if (is.numeric(target) || is.logical(target)) {
      if (!is.numeric(current) && !is.logical(current)) {
        return(FALSE)
      }
      target <- as.numeric(target)
      current <- as.numeric(current)
      if (!identical(is.na(target), is.na(current))) {
        return(FALSE)
      }
      keep <- !is.na(target)
      return(isTRUE(all.equal(
        target[keep],
        current[keep],
        tolerance = 1e-12,
        check.attributes = FALSE
      )))
    }
    if (all(is.na(current)) && all(is.na(target))) {
      return(TRUE)
    }
    identical(as.character(target), as.character(current))
  }
  all(vapply(
    names(expected),
    function(column) {
      equal_column(expected[[column]], observed[[column]])
    },
    logical(1)
  ))
}

h01_verify_model_row_keys <- function(rows) {
  analysis_key <- ifelse(
    rows$analysis_unit == "participant",
    paste(rows$site, rows$Id, sep = "::"),
    paste(rows$site, rows$Id, rows$local_date, sep = "::")
  )
  key <- data.frame(
    data_scenario_id = rows$data_scenario_id,
    model_implementation_id = rows$model_implementation_id,
    placement = rows$placement,
    scenario = rows$scenario,
    metric_id = rows$metric_id,
    analysis_key = analysis_key,
    stringsAsFactors = FALSE
  )
  if (anyDuplicated(key)) {
    h01_abort("H01 model rows contain a duplicated analysis key")
  }
  invisible(TRUE)
}

h01_verify_paired_model_frames <- function(rows, flag) {
  paired <- rows |>
    dplyr::filter(
      .data$scenario == "paired_common_sample",
      .data[[flag]]
    )
  for (metric_id in unique(paired$metric_id)) {
    metric <- paired[paired$metric_id == metric_id, , drop = FALSE]
    glasses <- metric |>
      dplyr::filter(.data$placement == "glasses") |>
      dplyr::select(dplyr::all_of(c("site", "Id", "local_date"))) |>
      dplyr::arrange(.data$site, .data$Id, .data$local_date)
    chest <- metric |>
      dplyr::filter(.data$placement == "chest") |>
      dplyr::select(dplyr::all_of(c("site", "Id", "local_date"))) |>
      dplyr::arrange(.data$site, .data$Id, .data$local_date)
    if (!identical(glasses, chest)) {
      h01_abort(
        "H01 paired `%s` frames differ for metric `%s`",
        flag,
        metric_id
      )
    }
  }
  invisible(TRUE)
}

h01_verify_predictor_centers <- function(rows) {
  rows <- rows |>
    dplyr::mutate(
      center_group = ifelse(
        .data$scenario == "paired_common_sample",
        paste(
          .data$data_scenario_id,
          .data$model_implementation_id,
          .data$scenario,
          .data$metric_id,
          sep = "::"
        ),
        paste(
          .data$data_scenario_id,
          .data$model_implementation_id,
          .data$scenario,
          .data$placement,
          .data$metric_id,
          sep = "::"
        )
      )
    )
  for (group in unique(rows$center_group)) {
    data <- rows[rows$center_group == group, , drop = FALSE]
    site_data <- data[data$site_photoperiod_included, , drop = FALSE]
    latitude_data <- data[
      data$latitude_photoperiod_included,
      ,
      drop = FALSE
    ] |>
      dplyr::distinct(
        .data$site,
        .data$absolute_latitude_10deg_centered
      )
    if (
      nrow(site_data) == 0L ||
        abs(mean(site_data$photoperiod_centered_hours)) > 1e-10 ||
        nrow(latitude_data) == 0L ||
        abs(mean(latitude_data$absolute_latitude_10deg_centered)) > 1e-10
    ) {
      h01_abort("H01 predictor centering failed for `%s`", group)
    }
  }
  invisible(TRUE)
}

h01_verify_scenario_estimability <- function(rows) {
  all_available <- rows$scenario == "all_available"
  if (
    any(
      rows$scenario_estimable[all_available] !=
        rows$metric_estimable[all_available]
    )
  ) {
    h01_abort(
      "H01 all-available scenario flags differ from metric estimability"
    )
  }
  paired <- rows |>
    dplyr::filter(.data$scenario == "paired_common_sample") |>
    dplyr::group_by(
      .data$data_scenario_id,
      .data$model_implementation_id,
      .data$metric_id,
      .data$site,
      .data$Id,
      .data$local_date
    ) |>
    dplyr::summarise(
      placements = dplyr::n_distinct(.data$placement),
      expected = all(.data$metric_estimable),
      observed_values = dplyr::n_distinct(.data$scenario_estimable),
      observed = dplyr::first(.data$scenario_estimable),
      .groups = "drop"
    )
  if (
    any(paired$placements != 2L) ||
      any(paired$observed_values != 1L) ||
      any(paired$observed != paired$expected)
  ) {
    h01_abort(
      "H01 paired scenario flags do not equal joint estimability"
    )
  }
  invisible(TRUE)
}

h01_expected_model_row_counts <- function(provenance, contract, root) {
  input_path <- function(input_id) {
    row <- provenance[provenance$input_id == input_id, , drop = FALSE]
    if (nrow(row) != 1L) {
      h01_abort("H01 provenance does not identify `%s` exactly once", input_id)
    }
    h01_declared_absolute_path(row$path[[1L]], root)
  }
  glasses_day <- readRDS(input_path("glasses_participant_day_enriched"))
  chest_day <- readRDS(input_path("chest_participant_day_enriched"))
  glasses_participant <- readRDS(
    input_path("glasses_participant_enriched")
  )
  chest_participant <- readRDS(input_path("chest_participant_enriched"))

  day_key <- c("site", "Id", "position", "local_date")
  participant_key <- c("site", "Id", "position")
  assert_unique_key(
    glasses_day,
    day_key,
    object = "verified near-eye participant-day input"
  )
  assert_unique_key(
    chest_day,
    day_key,
    object = "verified chest participant-day input"
  )
  assert_unique_key(
    glasses_participant,
    participant_key,
    object = "verified near-eye participant input"
  )
  assert_unique_key(
    chest_participant,
    participant_key,
    object = "verified chest participant input"
  )

  daily_metrics <- sum(contract$analysis_unit == "participant_day")
  participant_metrics <- sum(contract$analysis_unit == "participant")
  common_key <- c("site", "Id", "local_date")
  common_days <- dplyr::inner_join(
    dplyr::distinct(
      glasses_day,
      dplyr::across(dplyr::all_of(common_key))
    ),
    dplyr::distinct(
      chest_day,
      dplyr::across(dplyr::all_of(common_key))
    ),
    by = common_key,
    relationship = "one-to-one"
  )
  c(
    all_available_glasses =
      nrow(glasses_day) * daily_metrics +
        nrow(glasses_participant) * participant_metrics,
    all_available_chest =
      nrow(chest_day) * daily_metrics +
        nrow(chest_participant) * participant_metrics,
    paired_common_sample_glasses = nrow(common_days) * daily_metrics,
    paired_common_sample_chest = nrow(common_days) * daily_metrics
  )
}

verify_h01_model_data_artifacts <- function(
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
      "H01 model-data verification requires R 4.6.1; found %s",
      as.character(getRversion())
    )
  }
  paths <- h01_model_data_paths(root, output_root)
  required <- c(paths$rds, paths$csv, paths$manifest)
  missing <- required[!file.exists(required)]
  if (length(missing) > 0L) {
    h01_abort(
      "H01 model-data verification is missing artifact(s): %s",
      paste(missing, collapse = ", ")
    )
  }
  manifest <- readr::read_csv(
    paths$manifest,
    show_col_types = FALSE,
    progress = FALSE
  )
  if (
    !identical(names(manifest), h01_manifest_columns()) ||
      anyDuplicated(manifest$artifact_id) ||
      nrow(manifest) != 1L + length(paths$csv)
  ) {
    h01_abort("H01 manifest differs from its declared schema")
  }
  expected_ids <- c("H01", names(paths$csv))
  expected_paths <- c(H01 = paths$rds, paths$csv)
  if (!identical(manifest$artifact_id, expected_ids)) {
    h01_abort("H01 manifest artifact order differs from the contract")
  }
  for (index in seq_len(nrow(manifest))) {
    artifact_id <- manifest$artifact_id[[index]]
    path <- expected_paths[[artifact_id]]
    object <- h01_verify_artifact_object(
      path,
      manifest$artifact_type[[index]]
    )
    observed_rows <- if (artifact_id == "H01") {
      nrow(object$model_rows)
    } else {
      nrow(object)
    }
    observed_columns <- if (artifact_id == "H01") {
      ncol(object$model_rows)
    } else {
      ncol(object)
    }
    if (
      h01_relative_path(path, output_root) != manifest$path[[index]] ||
        artifact_sha256(path) != manifest$sha256[[index]] ||
        unname(file.info(path)$size) != manifest$bytes[[index]] ||
        observed_rows != manifest$rows[[index]] ||
        observed_columns != manifest$columns[[index]] ||
        manifest$producer[[index]] !=
          "scripts/pipeline/build_h01_model_data.R" ||
        manifest$r_version[[index]] != "4.6.1" ||
        manifest$status[[index]] != "PASS"
    ) {
      h01_abort("H01 manifest integrity failed for `%s`", artifact_id)
    }
  }

  object <- readRDS(paths$rds)
  if (
    !identical(names(object), h01_output_contract()$top_level) ||
      object$hypothesis_id != "H01" ||
      object$status != "PASS_WITH_DECLARED_UNAVAILABLE_SCENARIO"
  ) {
    h01_abort("H01 RDS does not satisfy its top-level contract")
  }
  csv_members <- list(
    model_rows = object$model_rows,
    metric_contract = object$metric_contract,
    sample_flow = object$sample_flow,
    exclusion_reasons = object$exclusion_reasons,
    scenario_status = object$scenario_status,
    predictor_centers = object$predictor_centers,
    variable_dictionary = object$variable_dictionary,
    input_provenance = object$input_provenance
  )
  for (artifact_id in names(csv_members)) {
    csv_object <- readr::read_csv(
      paths$csv[[artifact_id]],
      show_col_types = FALSE,
      progress = FALSE
    )
    if (!h01_csv_content_equal(csv_members[[artifact_id]], csv_object)) {
      h01_abort(
        "H01 `%s` CSV differs from the RDS member",
        artifact_id
      )
    }
  }
  contract <- h01_metric_contract(root)
  if (
    !isTRUE(all.equal(
      object$metric_contract,
      contract,
      check.attributes = FALSE
    ))
  ) {
    h01_abort("H01 metric contract differs from the declared 17 metrics")
  }
  rows <- object$model_rows
  required_row_columns <- c(
    "hypothesis_id",
    "data_scenario_id",
    "model_implementation_id",
    "placement",
    "scenario",
    "metric_order",
    "metric_id",
    "analysis_unit",
    "site",
    "Id",
    "position",
    "local_date",
    "profile_variant",
    "measurement_construct",
    "participant_days_contributing",
    "prepared_record_support_available",
    "prepared_record_support_unavailability_reason",
    "prepared_record_expected_minutes",
    "prepared_record_valid_melEDI_minutes",
    "prepared_record_valid_illuminance_minutes",
    "metric_support_available",
    "metric_support_unavailability_reason",
    "metric_support_valid_minutes",
    "metric_support_expected_minutes",
    "value",
    "source_unit",
    "manuscript_name",
    "manuscript_category",
    "display_unit",
    "variant_label",
    "value_definition",
    "metric_estimable",
    "metric_failure_reason",
    "scenario_estimable",
    "scenario_failure_reason",
    "photoperiod_hours",
    "latitude_deg",
    "site_photoperiod_included",
    "site_photoperiod_exclusion_reason",
    "latitude_photoperiod_included",
    "latitude_photoperiod_exclusion_reason"
  )
  assert_columns(rows, required_row_columns, object = "H01 model rows")
  if (
    !identical(
      unique(rows$data_scenario_id),
      object$metadata$data_scenario_id
    ) ||
      !identical(
        unique(rows$model_implementation_id),
        object$metadata$model_implementation_id
      ) ||
      !identical(
        sort(unique(rows$site)),
        object$metadata$site_levels
      ) ||
      any(rows$position != rows$placement) ||
      any(!rows$placement %in% h01_placements()) ||
      any(!rows$scenario %in% h01_scenarios()) ||
      any(!rows$metric_id %in% contract$metric_id) ||
      any(rows$hypothesis_id != "H01") ||
      anyNA(rows$metric_estimable) ||
      any(rows$metric_estimable != is.finite(rows$value))
  ) {
    h01_abort("H01 model rows violate placement, metric, or value rules")
  }
  expected_contract <- contract[
    match(rows$metric_id, contract$metric_id),
    ,
    drop = FALSE
  ]
  contract_fields_match <-
    rows$metric_order == expected_contract$metric_order &
    rows$analysis_unit == expected_contract$analysis_unit &
    rows$source_unit == expected_contract$source_unit &
    rows$manuscript_name == expected_contract$manuscript_name &
    rows$manuscript_category == expected_contract$manuscript_category &
    rows$display_unit == expected_contract$display_unit &
    rows$variant_label == expected_contract$variant_label &
    rows$value_definition == expected_contract$value_definition
  invalid_text <- is.na(rows$profile_variant) |
    !nzchar(rows$profile_variant) |
    is.na(rows$measurement_construct) |
    !nzchar(rows$measurement_construct)
  prepared_status_invalid <-
    is.na(rows$prepared_record_support_available) |
    (rows$prepared_record_support_available &
      !is.na(rows$prepared_record_support_unavailability_reason)) |
    (!rows$prepared_record_support_available &
      (is.na(
        rows$prepared_record_support_unavailability_reason
      ) |
        !nzchar(
          rows$prepared_record_support_unavailability_reason
        )))
  prepared_support_finite <-
    is.finite(rows$prepared_record_expected_minutes) &
    is.finite(rows$prepared_record_valid_melEDI_minutes)
  prepared_support_missing <-
    is.na(rows$prepared_record_expected_minutes) &
    is.na(rows$prepared_record_valid_melEDI_minutes) &
    is.na(rows$prepared_record_valid_illuminance_minutes)
  prepared_status_invalid <- prepared_status_invalid |
    (rows$prepared_record_support_available &
      !prepared_support_finite) |
    (!rows$prepared_record_support_available &
      !prepared_support_missing)
  prepared_bounds_invalid <-
    rows$prepared_record_support_available &
    (rows$prepared_record_expected_minutes <= 0 |
      rows$prepared_record_valid_melEDI_minutes < 0 |
      rows$prepared_record_valid_melEDI_minutes >
        rows$prepared_record_expected_minutes |
      (is.finite(
        rows$prepared_record_valid_illuminance_minutes
      ) &
        (rows$prepared_record_valid_illuminance_minutes < 0 |
          rows$prepared_record_valid_illuminance_minutes >
            rows$prepared_record_expected_minutes)))
  support_missing_mismatch <-
    is.na(rows$metric_support_valid_minutes) !=
      is.na(rows$metric_support_expected_minutes)
  support_bounds_invalid <-
    is.finite(rows$metric_support_valid_minutes) &
    (rows$metric_support_valid_minutes < 0 |
      !is.finite(rows$metric_support_expected_minutes) |
      rows$metric_support_expected_minutes < 0 |
      (rows$metric_estimable &
        rows$metric_support_expected_minutes == 0) |
      rows$metric_support_valid_minutes > rows$metric_support_expected_minutes)
  support_status_invalid <-
    is.na(rows$metric_support_available) |
    rows$metric_support_available !=
      (is.finite(rows$metric_support_valid_minutes) &
        is.finite(rows$metric_support_expected_minutes)) |
    (rows$metric_support_available &
      !is.na(rows$metric_support_unavailability_reason)) |
    (!rows$metric_support_available &
      (is.na(rows$metric_support_unavailability_reason) |
        !nzchar(rows$metric_support_unavailability_reason)))
  if (
    any(!contract_fields_match) ||
      any(invalid_text) ||
      any(prepared_status_invalid) ||
      any(prepared_bounds_invalid) ||
      any(support_missing_mismatch) ||
      any(support_status_invalid) ||
      any(support_bounds_invalid)
  ) {
    h01_abort(
      "H01 model-row labels or measurement-support fields are invalid"
    )
  }
  missing_metric_reason <- !rows$metric_estimable &
    (is.na(rows$metric_failure_reason) |
      !nzchar(rows$metric_failure_reason))
  unexpected_metric_reason <- rows$metric_estimable &
    !is.na(rows$metric_failure_reason)
  missing_scenario_reason <- !rows$scenario_estimable &
    (is.na(rows$scenario_failure_reason) |
      !nzchar(rows$scenario_failure_reason))
  unexpected_scenario_reason <- rows$scenario_estimable &
    !is.na(rows$scenario_failure_reason)
  invalid_site_reason <- rows$site_photoperiod_included !=
    is.na(rows$site_photoperiod_exclusion_reason)
  invalid_latitude_reason <- rows$latitude_photoperiod_included !=
    is.na(rows$latitude_photoperiod_exclusion_reason)
  if (
    any(missing_metric_reason) ||
      any(unexpected_metric_reason) ||
      any(missing_scenario_reason) ||
      any(unexpected_scenario_reason) ||
      any(invalid_site_reason) ||
      any(invalid_latitude_reason)
  ) {
    h01_abort("H01 inclusion and exclusion reasons do not reconcile")
  }
  h01_verify_model_row_keys(rows)
  h01_verify_scenario_estimability(rows)

  all_rows <- rows[rows$scenario == "all_available", , drop = FALSE]
  paired_rows <- rows[
    rows$scenario == "paired_common_sample",
    ,
    drop = FALSE
  ]
  if (any(paired_rows$analysis_unit != "participant_day")) {
    h01_abort("H01 paired rows contain a non-daily metric")
  }

  scenario_status <- object$scenario_status
  if (
    nrow(scenario_status) != 68L ||
      sum(!scenario_status$available) != 4L ||
      any(
        scenario_status$analysis_unit[!scenario_status$available] !=
          "participant"
      ) ||
      any(
        scenario_status$availability_reason[
          !scenario_status$available
        ] !=
          h01_output_contract()$unavailable_scenario_reason
      )
  ) {
    h01_abort("H01 paired participant-metric status is not explicit")
  }
  h01_verify_paired_model_frames(rows, "site_photoperiod_included")
  h01_verify_paired_model_frames(
    rows,
    "latitude_photoperiod_included"
  )
  h01_verify_predictor_centers(rows)

  expected_sample_flow <- h01_build_sample_flow(rows, scenario_status)
  expected_exclusions <- h01_build_exclusion_summary(
    rows,
    scenario_status
  )
  if (
    !isTRUE(all.equal(
      object$sample_flow,
      expected_sample_flow,
      check.attributes = FALSE
    )) ||
      !isTRUE(all.equal(
        object$exclusion_reasons,
        expected_exclusions,
        check.attributes = FALSE
      ))
  ) {
    h01_abort("H01 sample flow or exclusion summaries do not reconcile")
  }

  provenance <- object$input_provenance
  expected_input_ids <- c(
    "glasses_participant_day_enriched",
    "glasses_participant_enriched",
    "glasses_metric_admissibility",
    "glasses_metric_support",
    "chest_participant_day_enriched",
    "chest_participant_enriched",
    "chest_metric_admissibility",
    "chest_metric_support",
    "metric_display_registry"
  )
  if (
    !setequal(provenance$input_id, expected_input_ids) ||
      anyDuplicated(provenance$input_id) ||
      nrow(provenance) != length(expected_input_ids) ||
      any(provenance$status != "PASS") ||
      any(provenance$r_version != "4.6.1")
  ) {
    h01_abort("H01 input provenance has a non-PASS row")
  }
  for (index in seq_len(nrow(provenance))) {
    input_path <- h01_declared_absolute_path(
      provenance$path[[index]],
      root
    )
    if (
      artifact_sha256(input_path) != provenance$sha256[[index]] ||
        unname(file.info(input_path)$size) != provenance$bytes[[index]]
    ) {
      h01_abort(
        "H01 current input differs for `%s`",
        provenance$input_id[[index]]
      )
    }
    if (!is.na(provenance$upstream_manifest_path[[index]])) {
      upstream <- h01_declared_absolute_path(
        provenance$upstream_manifest_path[[index]],
        root
      )
      if (
        artifact_sha256(upstream) !=
          provenance$upstream_manifest_sha256[[index]]
      ) {
        h01_abort(
          "H01 upstream manifest differs for `%s`",
          provenance$input_id[[index]]
        )
      }
    }
  }
  expected_row_counts <- h01_expected_model_row_counts(
    provenance,
    contract,
    root
  )
  observed_row_counts <- c(
    all_available_glasses = nrow(
      all_rows[all_rows$placement == "glasses", , drop = FALSE]
    ),
    all_available_chest = nrow(
      all_rows[all_rows$placement == "chest", , drop = FALSE]
    ),
    paired_common_sample_glasses = nrow(
      paired_rows[paired_rows$placement == "glasses", , drop = FALSE]
    ),
    paired_common_sample_chest = nrow(
      paired_rows[paired_rows$placement == "chest", , drop = FALSE]
    )
  )
  if (!identical(observed_row_counts, expected_row_counts)) {
    h01_abort("H01 production row counts differ from the verified inputs")
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
  implementation_contract_sha256 <-
    h01_implementation_contract_sha256(contract)
  shared_implementation_sha256 <- artifact_sha256(file.path(
    root,
    "scripts",
    "pipeline",
    "h01_model_data.R"
  ))
  if (
    object$metadata$input_bundle_sha256 != input_bundle_sha256 ||
      object$metadata$implementation_contract_sha256 !=
        implementation_contract_sha256 ||
      object$metadata$shared_implementation_sha256 !=
        shared_implementation_sha256 ||
      any(manifest$input_bundle_sha256 != input_bundle_sha256) ||
      any(
        manifest$base_manifest_sha256 != object$metadata$base_manifest_sha256
      ) ||
      any(
        manifest$metric_manifest_sha256 !=
          object$metadata$metric_manifest_sha256
      )
  ) {
    h01_abort("H01 manifest input-bundle provenance differs")
  }

  primary_flow <- object$sample_flow |>
    dplyr::filter(
      .data$scenario == "all_available",
      .data$placement == "glasses",
      .data$stage == "site_photoperiod_model",
      .data$scope == "overall"
    ) |>
    dplyr::select(dplyr::all_of(c(
      "metric_id",
      "model_observations",
      "participants",
      "participant_days",
      "participant_hours",
      "contributing_participant_days",
      "metric_support_missing_observations",
      "metric_support_valid_hours",
      "metric_support_expected_hours",
      "prepared_record_support_missing_observations",
      "prepared_record_valid_melEDI_hours",
      "prepared_record_valid_illuminance_hours",
      "sites"
    )))
  list(
    status = object$status,
    h01_metrics = nrow(contract),
    model_rows = nrow(rows),
    all_available_glasses_rows = sum(
      rows$scenario == "all_available" &
        rows$placement == "glasses"
    ),
    all_available_chest_rows = sum(
      rows$scenario == "all_available" &
        rows$placement == "chest"
    ),
    paired_daily_keys = nrow(
      h01_paired_common_day_keys(rows)
    ),
    unavailable_scenario_rows = sum(!scenario_status$available),
    manifest_sha256 = artifact_sha256(paths$manifest),
    primary_model_sample = primary_flow
  )
}
