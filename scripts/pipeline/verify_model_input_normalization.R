# Independently verify Preparation 06 normalized model inputs and audits.

normalization_verifier_difference_count <- function(source, normalized) {
  if (length(source) != length(normalized)) {
    return(max(length(source), length(normalized)))
  }
  source_missing <- is.na(source)
  normalized_missing <- is.na(normalized)
  missing_difference <- xor(source_missing, normalized_missing)
  comparable <- !source_missing & !normalized_missing
  if (is.factor(source)) {
    equal <- as.integer(source)[comparable] ==
      as.integer(normalized)[comparable]
  } else if (
    is.numeric(source) ||
      inherits(source, c("POSIXt", "Date", "difftime"))
  ) {
    equal <- as.numeric(source)[comparable] ==
      as.numeric(normalized)[comparable]
  } else {
    equal <- as.character(source)[comparable] ==
      as.character(normalized)[comparable]
  }
  sum(missing_difference) + sum(!equal)
}

normalization_verifier_expected_time_coordinates <- function(
  source,
  timezone
) {
  utc <- as.POSIXct(
    as.numeric(source),
    origin = "1970-01-01",
    tz = "UTC"
  )
  local_label <- format(
    utc,
    tz = timezone,
    format = "%Y-%m-%d %H:%M:%S",
    usetz = FALSE
  )
  local_label[is.na(utc)] <- NA_character_
  wall <- as.POSIXct(
    local_label,
    format = "%Y-%m-%d %H:%M:%S",
    tz = "UTC"
  )
  offset_text <- format(utc, tz = timezone, format = "%z")
  sign <- ifelse(substr(offset_text, 1L, 1L) == "-", -1L, 1L)
  offset <- sign * (
    suppressWarnings(as.integer(substr(offset_text, 2L, 3L))) * 60L +
      suppressWarnings(as.integer(substr(offset_text, 4L, 5L)))
  )
  offset[is.na(utc)] <- NA_integer_
  dst_integer <- as.POSIXlt(utc, tz = timezone)$isdst
  is_dst <- dst_integer > 0L
  is_dst[is.na(utc) | dst_integer < 0L] <- NA
  list(
    utc = utc,
    local_label = local_label,
    wall = wall,
    utc_offset_minutes = as.integer(offset),
    is_dst = is_dst
  )
}

normalization_verifier_required_path_map <- function(root) {
  paths <- model_input_normalization_paths(root)
  modality_map <- stats::setNames(
    unname(paths$modality_paths),
    paste0("normalized_", names(paths$modality_paths))
  )
  audit_map <- stats::setNames(
    unname(paths$audit_paths),
    paste0("audit_", names(paths$audit_paths))
  )
  c(modality_map, audit_map)
}

verify_model_input_normalization <- function(
  root = project_root(),
  site_sources_path = file.path(root, "config", "site_sources.csv"),
  availability_path = file.path(
    root,
    "config",
    "model_input_availability.csv"
  ),
  preparation01_manifest_path = file.path(
    root,
    "artifacts",
    "12_manifests",
    "pinned_downloads.csv"
  ),
  acquisition_manifest_path = model_input_acquisition_paths(root)$manifest,
  acquisition_object_audit_path =
    model_input_acquisition_paths(root)$object_audit,
  acquisition_column_audit_path =
    model_input_acquisition_paths(root)$column_audit,
  normalization_manifest_path =
    model_input_normalization_paths(root)$manifest
) {
  root <- normalizePath(root, winslash = "/", mustWork = TRUE)
  paths <- model_input_normalization_paths(root)
  acquisition_verification <- verify_model_input_acquisition(
    root = root,
    site_sources_path = site_sources_path,
    availability_path = availability_path,
    preparation01_manifest_path = preparation01_manifest_path,
    manifest_path = acquisition_manifest_path,
    object_audit_path = acquisition_object_audit_path,
    column_audit_path = acquisition_column_audit_path
  )
  if (!identical(acquisition_verification$status, "PASS")) {
    abort_pipeline(
      "Normalization verification requires a PASS acquisition verification"
    )
  }
  if (!identical(as.character(getRversion()), "4.6.1")) {
    abort_pipeline(
      "Normalization verification must run under R 4.6.1; found %s",
      as.character(getRversion())
    )
  }

  required_path_map <- normalization_verifier_required_path_map(root)
  required_paths <- c(normalization_manifest_path, required_path_map)
  missing <- required_paths[!file.exists(required_paths)]
  if (length(missing) > 0L) {
    abort_pipeline(
      "Normalization verification is missing artifact(s): %s",
      paste(missing, collapse = ", ")
    )
  }

  manifest <- readr::read_csv(
    normalization_manifest_path,
    show_col_types = FALSE,
    progress = FALSE
  )
  if (
    !identical(
      names(manifest),
      model_input_normalization_manifest_columns()
    )
  ) {
    abort_pipeline("Normalization manifest columns differ from the contract")
  }
  assert_unique_key(
    manifest,
    "artifact_id",
    object = "model-input normalization manifest"
  )
  expected_artifacts <- model_input_normalization_expected_artifacts()
  if (!identical(manifest$artifact_id, expected_artifacts)) {
    abort_pipeline(
      "Normalization manifest does not contain the exact ordered artifact set"
    )
  }
  expected_relative_paths <- vapply(
    required_path_map[expected_artifacts],
    model_input_project_relative_path,
    character(1),
    root = root,
    must_work = TRUE
  )
  if (!identical(manifest$path, unname(expected_relative_paths))) {
    abort_pipeline(
      "Normalization manifest paths differ from the declared output paths"
    )
  }
  if (
    any(grepl("^/", manifest$path)) ||
      any(grepl("(^|/)[.][.](/|$)", manifest$path))
  ) {
    abort_pipeline("Normalization manifest paths must be project-relative")
  }
  expected_types <- c(
    rep("rds", length(model_input_normalization_modalities())),
    rep("csv", length(paths$audit_paths))
  )
  if (!identical(manifest$artifact_type, expected_types)) {
    abort_pipeline("Normalization manifest artifact types differ")
  }

  input_manifest_sha256 <- artifact_sha256(acquisition_manifest_path)
  if (
    any(manifest$input_manifest_sha256 != input_manifest_sha256) ||
      any(manifest$r_version != "4.6.1")
  ) {
    abort_pipeline(
      "Normalization manifest has stale input provenance or R version"
    )
  }
  for (row_index in seq_len(nrow(manifest))) {
    artifact_path <- model_input_absolute_path(
      manifest$path[row_index],
      root = root,
      must_work = TRUE
    )
    if (
      !identical(artifact_sha256(artifact_path), manifest$sha256[row_index]) ||
        !isTRUE(
          unname(file.info(artifact_path)$size) ==
            manifest$bytes[row_index]
        )
    ) {
      abort_pipeline(
        "Normalization artifact differs from manifest: %s",
        manifest$artifact_id[row_index]
      )
    }
  }

  normalized <- stats::setNames(
    lapply(paths$modality_paths, function(path) {
      object <- readRDS(path)
      if (!is.data.frame(object) || is.environment(object)) {
        abort_pipeline(
          "Normalized RDS must contain one data-frame object: %s",
          path
        )
      }
      object
    }),
    names(paths$modality_paths)
  )
  audit_data <- lapply(paths$audit_paths, function(path) {
    readr::read_csv(
      path,
      show_col_types = FALSE,
      progress = FALSE
    )
  })

  artifact_rows <- vapply(
    c(normalized, audit_data),
    nrow,
    integer(1)
  )
  artifact_columns <- vapply(
    c(normalized, audit_data),
    ncol,
    integer(1)
  )
  if (
    !identical(as.integer(manifest$rows), unname(artifact_rows)) ||
      !identical(as.integer(manifest$columns), unname(artifact_columns))
  ) {
    abort_pipeline(
      "Normalization manifest row/column dimensions differ from artifacts"
    )
  }

  acquisition_manifest <- readr::read_csv(
    acquisition_manifest_path,
    show_col_types = FALSE,
    progress = FALSE
  )
  site_sources <- read_site_sources(site_sources_path)
  records <- collect_model_input_records(
    acquisition_manifest,
    site_sources,
    root = root
  )
  expected_rows <- vapply(
    model_input_normalization_modalities(),
    function(modality) {
      sum(vapply(
        records[
          vapply(records, `[[`, character(1), "modality") == modality
        ],
        function(record) nrow(record$data),
        integer(1)
      ))
    },
    integer(1)
  )
  if (!identical(vapply(normalized, nrow, integer(1)), expected_rows)) {
    abort_pipeline(
      "Normalized RDS row counts differ from verified pinned sources"
    )
  }

  schema_audit <- audit_data$source_schema
  label_audit <- audit_data$labels
  missingness_audit <- audit_data$missingness
  free_text_audit <- audit_data$free_text
  value_audit <- audit_data$value_preservation
  assert_unique_key(
    schema_audit,
    c("site", "modality", "source_column"),
    object = "normalization source-schema audit"
  )
  assert_unique_key(
    label_audit,
    c("site", "modality", "source_column"),
    object = "normalization label audit"
  )
  assert_unique_key(
    missingness_audit,
    c("site", "modality", "source_column"),
    object = "normalization missingness audit"
  )
  assert_unique_key(
    value_audit,
    c("site", "modality", "source_column"),
    object = "normalization value-preservation audit"
  )
  if (
    nrow(schema_audit) != 963L ||
      nrow(label_audit) != 963L ||
      nrow(missingness_audit) != 963L ||
      nrow(value_audit) != 963L ||
      any(value_audit$status != "PASS")
  ) {
    abort_pipeline(
      "Normalization column audits differ from the 963 verified source columns"
    )
  }

  free_contract <- model_input_free_text_contract()
  time_contract <- model_input_time_contract()
  for (record in records) {
    modality <- record$modality
    source <- record$data
    output <- normalized[[modality]]
    output <- output[output$site == record$site, , drop = FALSE]
    output <- output[order(output$source_row), , drop = FALSE]
    if (
      nrow(output) != nrow(source) ||
        !identical(output$source_row, seq_len(nrow(source)))
    ) {
      abort_pipeline(
        "Source-row trace failed for %s/%s",
        record$site,
        modality
      )
    }

    provenance_values <- list(
      site_location = record$site_source$location,
      site_timezone = record$site_source$timezone,
      source_repository = record$manifest$repository,
      source_commit = record$manifest$commit,
      source_doi = record$manifest$doi,
      source_relative_path = record$manifest$relative_source_path,
      source_object_name = record$manifest$object_name,
      source_sha256 = record$manifest$sha256
    )
    for (provenance_column in names(provenance_values)) {
      if (
        !provenance_column %in% names(output) ||
          any(
            output[[provenance_column]] !=
              provenance_values[[provenance_column]]
          )
      ) {
        abort_pipeline(
          "Release provenance failed for %s/%s/%s",
          record$site,
          modality,
          provenance_column
        )
      }
    }
    for (column_name in names(source)) {
      source_column <- source[[column_name]]
      is_free_text <- any(
        free_contract$modality == modality &
          free_contract$source_column == column_name
      )
      time_row <- time_contract[
        time_contract$modality == modality &
          time_contract$source_column == column_name,
        ,
        drop = FALSE
      ]
      schema_row <- schema_audit[
        schema_audit$site == record$site &
          schema_audit$modality == modality &
          schema_audit$source_column == column_name,
        ,
        drop = FALSE
      ]
      label_row <- label_audit[
        label_audit$site == record$site &
          label_audit$modality == modality &
          label_audit$source_column == column_name,
        ,
        drop = FALSE
      ]
      missingness_row <- missingness_audit[
        missingness_audit$site == record$site &
          missingness_audit$modality == modality &
          missingness_audit$source_column == column_name,
        ,
        drop = FALSE
      ]
      if (
        nrow(schema_row) != 1L ||
          nrow(label_row) != 1L ||
          nrow(missingness_row) != 1L ||
          schema_row$source_class != paste(class(source_column), collapse = " | ") ||
          schema_row$source_type != typeof(source_column) ||
          schema_row$source_rows != length(source_column) ||
          schema_row$source_missing != sum(is.na(source_column)) ||
          !identical(
            label_row$source_label,
            model_input_attribute_text(source_column, "label")
          ) ||
          missingness_row$missing_rows != sum(is.na(source_column)) ||
          missingness_row$nonmissing_rows != sum(!is.na(source_column))
      ) {
        abort_pipeline(
          "Source audit reconstruction failed for %s/%s/%s",
          record$site,
          modality,
          column_name
        )
      }

      if (is_free_text) {
        if (column_name %in% names(output)) {
          abort_pipeline(
            "Free text entered analytic RDS: %s/%s",
            modality,
            column_name
          )
        }
        next
      }
      if (nrow(time_row) == 1L) {
        prefix <- time_row$normalized_prefix
        expected <- normalization_verifier_expected_time_coordinates(
          source_column,
          record$site_source$timezone
        )
        targets <- c(
          utc = paste0(prefix, "_utc"),
          local_label = paste0(prefix, "_local_label"),
          wall = paste0(prefix, "_wall"),
          utc_offset_minutes = paste0(prefix, "_utc_offset_minutes"),
          is_dst = paste0(prefix, "_is_dst")
        )
        if (
          any(!targets %in% names(output)) ||
            normalization_verifier_difference_count(
              expected$utc,
              output[[targets[["utc"]]]]
            ) != 0L ||
            normalization_verifier_difference_count(
              expected$local_label,
              output[[targets[["local_label"]]]]
            ) != 0L ||
            normalization_verifier_difference_count(
              expected$wall,
              output[[targets[["wall"]]]]
            ) != 0L ||
            normalization_verifier_difference_count(
              expected$utc_offset_minutes,
              output[[targets[["utc_offset_minutes"]]]]
            ) != 0L ||
            normalization_verifier_difference_count(
              expected$is_dst,
              output[[targets[["is_dst"]]]]
            ) != 0L
        ) {
          abort_pipeline(
            "Time-coordinate verification failed for %s/%s/%s",
            record$site,
            modality,
            column_name
          )
        }
      } else {
        if (
          !column_name %in% names(output) ||
            normalization_verifier_difference_count(
              source_column,
              output[[column_name]]
            ) != 0L
        ) {
          abort_pipeline(
            "Source values changed for %s/%s/%s",
            record$site,
            modality,
            column_name
          )
        }
        if (
          is.factor(source_column) &&
            !identical(levels(source_column), levels(output[[column_name]]))
        ) {
          abort_pipeline(
            "Factor levels changed for %s/%s/%s",
            record$site,
            modality,
            column_name
          )
        }
        if (
          inherits(source_column, "difftime") &&
            !identical(
              attr(source_column, "units", exact = TRUE),
              attr(output[[column_name]], "units", exact = TRUE)
            )
        ) {
          abort_pipeline(
            "Difftime units changed for %s/%s/%s",
            record$site,
            modality,
            column_name
          )
        }
      }
    }
  }

  if (
    any(!free_text_audit$excluded_from_analytic_rds) ||
      any(free_text_audit$content_exported) ||
      nrow(free_text_audit) != nrow(free_contract) * nrow(site_sources)
  ) {
    abort_pipeline("Free-text audit is incomplete or exports content")
  }
  expected_label_differences <- label_audit |>
    dplyr::filter(!.data$label_matches_reference)
  if (
    nrow(expected_label_differences) != 2L ||
      !setequal(
        expected_label_differences$known_difference_code,
        c(
          "rise_sleepprep_wake_wording",
          "rise_sleep_duration_label_missing"
        )
      )
  ) {
    abort_pipeline("Known RISE sleep-label audit differs from the contract")
  }

  key_audit <- audit_data$keys
  if (any(key_audit$status != "PASS")) {
    abort_pipeline("Normalized key audit contains a failure")
  }
  participant_modalities <- c(
    "demographics",
    "chronotype",
    "leba",
    "vlsq8"
  )
  for (modality in participant_modalities) {
    assert_unique_key(
      normalized[[modality]],
      c("site", "Id"),
      object = paste(modality, "normalized input")
    )
  }
  assert_unique_key(
    normalized$exercisediary,
    c("site", "Id", "Date"),
    object = "exercise normalized input"
  )

  light <- normalized$lightexposurediary
  expected_light_eligible <- !is.na(light$interval_start_utc) &
    !is.na(light$interval_end_utc) &
    light$interval_start_utc < light$interval_end_utc
  if (
    !identical(light$interval_analysis_eligible, expected_light_eligible) ||
      !identical(light$interval_quarantined, !expected_light_eligible) ||
      sum(light$interval_quarantined) != 27L ||
      sum(light$interval_quarantined & light$site == "RISE") != 1L ||
      sum(light$interval_quarantined & light$site == "THUAS") != 26L ||
      !all(light$form_timestamp_excluded_from_interval_analysis)
  ) {
    abort_pipeline("Light-diary interval disposition failed verification")
  }
  sleep <- normalized$sleepdiaries
  expected_sleep_eligible <- !is.na(sleep$sleepprep_utc) &
    !is.na(sleep$wake_utc) &
    sleep$sleepprep_utc < sleep$wake_utc
  if (
    !identical(
      sleep$sleep_interval_analysis_eligible,
      expected_sleep_eligible
    ) ||
      !identical(
        sleep$sleep_interval_quarantined,
        !expected_sleep_eligible
      ) ||
      sum(sleep$sleep_interval_quarantined) != 1L ||
      sum(
        sleep$sleep_interval_quarantined &
          sleep$site == "MPI" &
          sleep$sleep_interval_issue_code == "missing_wake"
      ) != 1L ||
      !all(normalized$exercisediary$
        form_timestamps_excluded_from_interval_analysis)
  ) {
    abort_pipeline("Sleep/exercise interval disposition failed verification")
  }

  interval_issues <- audit_data$interval_issues
  if (
    nrow(interval_issues) != 28L ||
      sum(interval_issues$modality == "lightexposurediary") != 27L ||
      sum(interval_issues$modality == "sleepdiaries") != 1L
  ) {
    abort_pipeline("Interval issue audit does not contain the exact 28 rows")
  }
  total_interval_rows <- audit_data$intervals |>
    dplyr::filter(.data$site == "_all_sites")
  expected_total_rows <- c(
    exercisediary = 1174L,
    lightexposurediary = 30199L,
    lightexposurediary = 30199L,
    sleepdiaries = 1276L
  )
  if (
    length(total_interval_rows$rows) != length(expected_total_rows) ||
      !all(total_interval_rows$rows == unname(expected_total_rows))
  ) {
    abort_pipeline("Interval audit total rows differ from source releases")
  }

  list(
    status = "PASS",
    acquisition_status = acquisition_verification$status,
    input_manifest_sha256 = input_manifest_sha256,
    normalization_manifest_sha256 = artifact_sha256(
      normalization_manifest_path
    ),
    artifact_summary = manifest |>
      dplyr::select(
        dplyr::all_of(
          c(
            "artifact_id",
            "artifact_type",
            "rows",
            "columns",
            "sha256"
          )
        )
      ),
    interval_summary = total_interval_rows |>
      dplyr::select(
        dplyr::all_of(
          c(
            "modality",
            "timestamp_role",
            "rows",
            "analysis_eligible",
            "quarantined",
            "excluded_as_form_metadata"
          )
        )
      )
  )
}
