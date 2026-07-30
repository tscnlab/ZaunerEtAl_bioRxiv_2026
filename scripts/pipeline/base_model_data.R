# Define pure contracts and joins for Preparation 06 canonical base-model data.
#
# Source scripts/pipeline/assertions.R before this file.

base_model_placements <- function() {
  c("glasses", "chest")
}

base_model_questionnaire_modalities <- function() {
  c("demographics", "chronotype", "leba", "vlsq8")
}

base_model_normalized_modalities <- function() {
  c(
    base_model_questionnaire_modalities(),
    "exercisediary",
    "lightexposurediary",
    "sleepdiaries"
  )
}

base_model_normalization_provenance_columns <- function() {
  c(
    "site",
    "site_location",
    "site_timezone",
    "source_repository",
    "source_commit",
    "source_doi",
    "source_relative_path",
    "source_object_name",
    "source_sha256",
    "source_row",
    "Id"
  )
}

base_model_disallowed_free_text_columns <- function() {
  c(
    "comments",
    "comments_english",
    "type",
    "type_english",
    "activity_desc",
    "activity_desc_english"
  )
}

base_model_metric_specification <- function(root) {
  metric_root <- file.path(root, "artifacts", "05_metrics")
  tibble::tribble(
    ~input_id,
    ~placement,
    ~resolution,
    ~artifact_type,
    ~path,
    "glasses_participant_day",
    "glasses",
    "participant_day",
    "participant_day_metrics_rds",
    file.path(metric_root, "metrics_glasses_participant_day.rds"),
    "chest_participant_day",
    "chest",
    "participant_day",
    "participant_day_metrics_rds",
    file.path(metric_root, "metrics_chest_participant_day.rds"),
    "glasses_participant",
    "glasses",
    "participant",
    "participant_is_iv_rds",
    file.path(metric_root, "metrics_glasses_participant.rds"),
    "chest_participant",
    "chest",
    "participant",
    "participant_is_iv_rds",
    file.path(metric_root, "metrics_chest_participant.rds"),
    "glasses_30_minute",
    "glasses",
    "30_minute",
    "complete_30_minute_arithmetic_medi_grid_rds",
    file.path(metric_root, "metrics_glasses_30_minute.rds"),
    "chest_30_minute",
    "chest",
    "30_minute",
    "complete_30_minute_arithmetic_medi_grid_rds",
    file.path(metric_root, "metrics_chest_30_minute.rds"),
    "glasses_one_hour",
    "glasses",
    "one_hour",
    "complete_one_hour_geometric_medi_grid_rds",
    file.path(metric_root, "metrics_glasses_one_hour.rds"),
    "chest_one_hour",
    "chest",
    "one_hour",
    "complete_one_hour_geometric_medi_grid_rds",
    file.path(metric_root, "metrics_chest_one_hour.rds")
  )
}

base_model_normalized_specification <- function(root) {
  normalized_root <- file.path(
    root,
    "artifacts",
    "06_model_data",
    "normalized_inputs"
  )
  modalities <- base_model_normalized_modalities()
  tibble::tibble(
    modality = modalities,
    artifact_id = paste0("normalized_", modalities),
    path = file.path(normalized_root, paste0(modalities, ".rds"))
  )
}

base_model_input_manifest_paths <- function(root) {
  manifest_root <- file.path(root, "artifacts", "12_manifests")
  c(
    metrics = file.path(manifest_root, "metric_artifacts.csv"),
    normalization = file.path(
      manifest_root,
      "model_input_normalization.csv"
    ),
    site_context = file.path(
      manifest_root,
      "site_solar_context_artifacts.csv"
    )
  )
}

base_model_paths <- function(root, output_root = root) {
  root <- normalizePath(root, winslash = "/", mustWork = TRUE)
  output_root <- normalizePath(
    output_root,
    winslash = "/",
    mustWork = TRUE
  )
  base_root <- file.path(
    output_root,
    "artifacts",
    "06_model_data",
    "base"
  )
  data_paths <- c(
    participant_metadata = file.path(
      base_root,
      "participant_metadata.rds"
    ),
    glasses_participant_day_context = file.path(
      base_root,
      "metrics_glasses_participant_day_context.rds"
    ),
    chest_participant_day_context = file.path(
      base_root,
      "metrics_chest_participant_day_context.rds"
    ),
    glasses_participant = file.path(
      base_root,
      "metrics_glasses_participant.rds"
    ),
    chest_participant = file.path(
      base_root,
      "metrics_chest_participant.rds"
    ),
    glasses_30_minute_context = file.path(
      base_root,
      "metrics_glasses_30_minute_context.rds"
    ),
    chest_30_minute_context = file.path(
      base_root,
      "metrics_chest_30_minute_context.rds"
    ),
    glasses_one_hour_context = file.path(
      base_root,
      "metrics_glasses_one_hour_context.rds"
    ),
    chest_one_hour_context = file.path(
      base_root,
      "metrics_chest_one_hour_context.rds"
    ),
    glasses_participant_day_enriched = file.path(
      base_root,
      "metrics_glasses_participant_day_enriched.rds"
    ),
    chest_participant_day_enriched = file.path(
      base_root,
      "metrics_chest_participant_day_enriched.rds"
    ),
    glasses_participant_enriched = file.path(
      base_root,
      "metrics_glasses_participant_enriched.rds"
    ),
    chest_participant_enriched = file.path(
      base_root,
      "metrics_chest_participant_enriched.rds"
    )
  )
  audit_paths <- c(
    input_provenance = file.path(base_root, "input_provenance.csv"),
    metric_registry_firewall = file.path(
      base_root,
      "metric_registry_firewall.csv"
    ),
    metric_key_join = file.path(base_root, "metric_key_join_audit.csv"),
    modality_key_join = file.path(
      base_root,
      "modality_key_join_audit.csv"
    ),
    participant_availability = file.path(
      base_root,
      "participant_availability_audit.csv"
    ),
    metadata_fields = file.path(base_root, "metadata_field_audit.csv"),
    metric_metadata_availability = file.path(
      base_root,
      "metric_metadata_availability_audit.csv"
    ),
    contract = file.path(base_root, "base_model_contract.csv")
  )
  list(
    root = root,
    output_root = output_root,
    base_root = base_root,
    data_paths = data_paths,
    audit_paths = audit_paths,
    manifest = file.path(
      output_root,
      "artifacts",
      "12_manifests",
      "base_model_data_artifacts.csv"
    )
  )
}

base_model_metric_key <- function(resolution) {
  participant_key <- c("site", "Id", "position")
  participant_day_key <- c(participant_key, "local_date")
  switch(
    resolution,
    participant = participant_key,
    participant_day = participant_day_key,
    `30_minute` = c(participant_day_key, "clock_bin"),
    one_hour = c(participant_day_key, "clock_minute"),
    abort_pipeline("Unknown base-model metric resolution: %s", resolution)
  )
}

base_model_internal_window_boundary_columns <- function() {
  c(
    "m10_onset_clock_minute",
    "m10_offset_clock_minute",
    "l10_onset_clock_minute",
    "l10_offset_clock_minute"
  )
}

base_model_assert_no_internal_window_boundaries <- function(
  data,
  object = deparse(substitute(data))
) {
  present <- intersect(
    names(data),
    base_model_internal_window_boundary_columns()
  )
  if (length(present) > 0L) {
    abort_pipeline(
      "%s contains internal M10/L10 boundary field(s): %s",
      object,
      paste(present, collapse = ", ")
    )
  }
  invisible(data)
}

base_model_apply_metric_registry_firewall <- function(
  data,
  input_id,
  placement,
  resolution
) {
  validate_base_model_metric_input(
    data,
    placement = placement,
    resolution = resolution,
    object = paste0("metric input `", input_id, "` before registry firewall")
  )
  forbidden <- base_model_internal_window_boundary_columns()
  present <- intersect(names(data), forbidden)
  if (
    length(present) > 0L &&
      !identical(resolution, "participant_day")
  ) {
    abort_pipeline(
      paste0(
        "Internal M10/L10 boundary fields appeared at unexpected ",
        "resolution `%s` in `%s`"
      ),
      resolution,
      input_id
    )
  }
  keep <- setdiff(names(data), forbidden)
  output <- data[, keep, drop = FALSE]
  validate_base_model_metric_input(
    output,
    placement = placement,
    resolution = resolution,
    object = paste0("metric input `", input_id, "` after registry firewall")
  )
  base_model_assert_no_internal_window_boundaries(
    output,
    object = paste0("metric input `", input_id, "` after registry firewall")
  )
  key <- base_model_metric_key(resolution)
  key_preserved <- identical(data[key], output[key])
  row_order_preserved <- nrow(data) == nrow(output) &&
    key_preserved
  present_text <- if (length(present) == 0L) {
    NA_character_
  } else {
    paste(present, collapse = "|")
  }
  audit <- tibble::tibble(
    input_id = input_id,
    placement = placement,
    resolution = resolution,
    input_rows = nrow(data),
    output_rows = nrow(output),
    input_columns = ncol(data),
    output_columns = ncol(output),
    prohibited_columns_expected = paste(forbidden, collapse = "|"),
    prohibited_columns_present = present_text,
    prohibited_columns_removed = present_text,
    prohibited_column_count = length(present),
    row_order_preserved = row_order_preserved,
    key_set_preserved = key_preserved,
    outcome_values_recalculated = FALSE,
    status = if (
      nrow(data) == nrow(output) &&
        ncol(output) == ncol(data) - length(present) &&
        row_order_preserved &&
        key_preserved &&
        length(intersect(names(output), forbidden)) == 0L
    ) {
      "PASS"
    } else {
      "FAIL"
    }
  )
  if (audit$status != "PASS") {
    abort_pipeline(
      "Metric-registry firewall failed for `%s`",
      input_id
    )
  }
  list(data = output, audit = audit)
}

base_model_modality_key <- function(modality) {
  switch(
    modality,
    demographics = c("site", "Id"),
    chronotype = c("site", "Id"),
    leba = c("site", "Id"),
    vlsq8 = c("site", "Id"),
    exercisediary = c("site", "Id", "Date"),
    lightexposurediary = c("site", "source_row"),
    sleepdiaries = c("site", "source_row"),
    abort_pipeline("Unknown normalized modality: %s", modality)
  )
}

base_model_modality_key_role <- function(modality) {
  if (modality %in% base_model_questionnaire_modalities()) {
    return("participant_analysis_key")
  }
  if (identical(modality, "exercisediary")) {
    return("participant_day_analysis_key")
  }
  "source_trace_key"
}

validate_base_model_metric_input <- function(
  data,
  placement,
  resolution,
  object = deparse(substitute(data))
) {
  if (!is.data.frame(data) || nrow(data) == 0L) {
    abort_pipeline("%s must be a non-empty data frame", object)
  }
  key <- base_model_metric_key(resolution)
  assert_unique_key(data, key, object = object)
  assert_columns(data, c("site", "Id", "position"), object = object)
  if (
    !is.character(data$site) ||
      !is.character(data$Id) ||
      !is.character(data$position)
  ) {
    abort_pipeline(
      "%s must have character `site`, `Id`, and `position` columns",
      object
    )
  }
  if (!identical(unique(as.character(data$position)), placement)) {
    abort_pipeline(
      "%s has placement(s) %s; expected only %s",
      object,
      paste(unique(data$position), collapse = ", "),
      placement
    )
  }
  if (!identical(resolution, "participant")) {
    if (!inherits(data$local_date, "Date")) {
      abort_pipeline("%s column `local_date` must be Date", object)
    }
  }
  if (resolution %in% c("30_minute", "one_hour")) {
    clock_column <- if (identical(resolution, "30_minute")) {
      "clock_bin"
    } else {
      "clock_minute"
    }
    expected_grid <- if (identical(resolution, "30_minute")) {
      seq.int(0L, 1410L, by = 30L)
    } else {
      seq.int(0L, 1380L, by = 60L)
    }
    grid <- data |>
      dplyr::group_by(
        dplyr::across(
          dplyr::all_of(c("site", "Id", "position", "local_date"))
        )
      ) |>
      dplyr::summarise(
        rows = dplyr::n(),
        grid_matches = identical(
          sort(as.integer(.data[[clock_column]])),
          expected_grid
        ),
        .groups = "drop"
      )
    if (
      any(grid$rows != length(expected_grid)) ||
        any(!grid$grid_matches)
    ) {
      abort_pipeline(
        "%s does not contain a complete %s wall-clock grid",
        object,
        resolution
      )
    }
  }
  invisible(data)
}

validate_base_model_context <- function(
  context,
  object = deparse(substitute(context))
) {
  if (!is.data.frame(context) || nrow(context) == 0L) {
    abort_pipeline("%s must be a non-empty data frame", object)
  }
  key <- c("site", "local_date")
  assert_unique_key(context, key, object = object)
  if (
    !is.character(context$site) ||
      !inherits(context$local_date, "Date")
  ) {
    abort_pipeline(
      "%s requires character `site` and Date `local_date`",
      object
    )
  }
  invisible(context)
}

validate_base_model_normalized_input <- function(
  data,
  modality,
  object = deparse(substitute(data))
) {
  if (!is.data.frame(data) || nrow(data) == 0L) {
    abort_pipeline("%s must be a non-empty data frame", object)
  }
  assert_unique_key(
    data,
    base_model_modality_key(modality),
    object = object
  )
  assert_no_missing_key(data, c("site", "Id"), object = object)
  if (!is.character(data$site) || !is.character(data$Id)) {
    abort_pipeline(
      "%s requires character `site` and `Id` columns",
      object
    )
  }
  disallowed <- intersect(
    names(data),
    base_model_disallowed_free_text_columns()
  )
  if (length(disallowed) > 0L) {
    abort_pipeline(
      "%s contains disallowed free-text field(s): %s",
      object,
      paste(disallowed, collapse = ", ")
    )
  }
  invisible(data)
}

base_model_questionnaire_fields <- function(data, modality) {
  validate_base_model_normalized_input(
    data,
    modality,
    object = paste0("normalized ", modality)
  )
  fields <- setdiff(
    names(data),
    base_model_normalization_provenance_columns()
  )
  if (length(fields) == 0L) {
    abort_pipeline(
      "Normalized questionnaire `%s` has no questionnaire fields",
      modality
    )
  }
  fields
}

base_model_participant_keys <- function(data) {
  assert_no_missing_key(data, c("site", "Id"))
  tibble::tibble(
    site = as.character(data$site),
    Id = as.character(data$Id)
  ) |>
    dplyr::distinct() |>
    dplyr::arrange(.data$site, .data$Id)
}

base_model_build_participant_domain <- function(
  normalized_inputs,
  metric_inputs
) {
  modality_keys <- lapply(
    base_model_normalized_modalities(),
    function(modality) {
      base_model_participant_keys(normalized_inputs[[modality]])
    }
  )
  metric_keys <- lapply(metric_inputs, base_model_participant_keys)
  dplyr::bind_rows(c(modality_keys, metric_keys)) |>
    dplyr::distinct() |>
    dplyr::arrange(.data$site, .data$Id)
}

base_model_join_context <- function(
  data,
  context,
  placement,
  resolution,
  input_id
) {
  validate_base_model_metric_input(
    data,
    placement,
    resolution,
    object = paste0("metric input `", input_id, "`")
  )
  validate_base_model_context(context, object = "site solar context")
  overlap <- intersect(
    setdiff(names(data), c("site", "local_date")),
    setdiff(names(context), c("site", "local_date"))
  )
  if (length(overlap) > 0L) {
    abort_pipeline(
      "Metric/context join for `%s` has overlapping non-key field(s): %s",
      input_id,
      paste(overlap, collapse = ", ")
    )
  }
  context_join <- context |>
    dplyr::mutate(.base_context_matched = TRUE)
  input <- data |>
    dplyr::mutate(.base_input_row = dplyr::row_number())
  joined <- left_join_checked(
    input,
    context_join,
    by = c("site", "local_date"),
    relationship = "many-to-one",
    x_name = paste0("metric input `", input_id, "`"),
    y_name = "site solar context"
  )
  unmatched <- sum(is.na(joined$.base_context_matched))
  row_order_preserved <- identical(
    joined$.base_input_row,
    seq_len(nrow(data))
  )
  if (
    nrow(joined) != nrow(data) ||
      unmatched != 0L ||
      !row_order_preserved
  ) {
    abort_pipeline(
      paste0(
        "Context join for `%s` failed: %d input rows, %d output rows, ",
        "%d unmatched, row order preserved=%s"
      ),
      input_id,
      nrow(data),
      nrow(joined),
      unmatched,
      row_order_preserved
    )
  }
  output <- joined |>
    dplyr::select(
      -dplyr::all_of(c(".base_input_row", ".base_context_matched"))
    )
  key <- base_model_metric_key(resolution)
  assert_unique_key(output, key, object = paste0(input_id, " with context"))
  list(
    data = output,
    audit = tibble::tibble(
      input_id = input_id,
      placement = placement,
      resolution = resolution,
      stage = "context_join",
      join_key = "site|local_date",
      relationship = "many-to-one",
      input_rows = nrow(data),
      output_rows = nrow(output),
      input_unique_keys = nrow(unique(data[key])),
      output_unique_keys = nrow(unique(output[key])),
      missing_key_rows = sum(!stats::complete.cases(output[key])),
      duplicated_key_rows = sum(
        duplicated(output[key]) |
          duplicated(output[key], fromLast = TRUE)
      ),
      unmatched_rows = unmatched,
      row_order_preserved = row_order_preserved,
      key_set_preserved = identical(
        data[key],
        output[key]
      ),
      status = "PASS"
    )
  )
}

base_model_availability_flag <- function(modality) {
  paste0("has_", modality)
}

base_model_build_participant_metadata <- function(
  normalized_inputs,
  metric_inputs
) {
  expected_modalities <- base_model_normalized_modalities()
  if (
    is.null(names(normalized_inputs)) ||
      !setequal(names(normalized_inputs), expected_modalities)
  ) {
    abort_pipeline(
      "Normalized inputs must be named exactly: %s",
      paste(expected_modalities, collapse = ", ")
    )
  }
  normalized_inputs <- normalized_inputs[expected_modalities]
  for (modality in expected_modalities) {
    validate_base_model_normalized_input(
      normalized_inputs[[modality]],
      modality,
      object = paste0("normalized `", modality, "`")
    )
  }
  domain <- base_model_build_participant_domain(
    normalized_inputs,
    metric_inputs
  )
  metadata <- domain
  questionnaire_fields <- character()
  for (modality in base_model_questionnaire_modalities()) {
    input <- normalized_inputs[[modality]]
    fields <- base_model_questionnaire_fields(input, modality)
    collisions <- intersect(questionnaire_fields, fields)
    if (length(collisions) > 0L) {
      abort_pipeline(
        paste0(
          "Questionnaire field names collide across modalities: %s. ",
          "Resolve explicitly before creating model data."
        ),
        paste(collisions, collapse = ", ")
      )
    }
    questionnaire_fields <- c(questionnaire_fields, fields)
    metadata <- left_join_checked(
      metadata,
      input |>
        dplyr::select(
          dplyr::all_of(c("site", "Id", fields))
        ),
      by = c("site", "Id"),
      relationship = "one-to-one",
      x_name = "participant metadata domain",
      y_name = paste0("normalized `", modality, "`")
    )
  }
  modality_flags <- character()
  for (modality in expected_modalities) {
    flag <- base_model_availability_flag(modality)
    modality_flags <- c(modality_flags, flag)
    available <- base_model_participant_keys(
      normalized_inputs[[modality]]
    )
    available[[flag]] <- TRUE
    metadata <- left_join_checked(
      metadata,
      available,
      by = c("site", "Id"),
      relationship = "one-to-one",
      x_name = "participant metadata domain",
      y_name = paste0("availability flag for `", modality, "`")
    )
    metadata[[flag]] <- dplyr::coalesce(metadata[[flag]], FALSE)
  }
  placement_flags <- character()
  for (placement in base_model_placements()) {
    flag <- paste0("has_", placement, "_metrics")
    placement_flags <- c(placement_flags, flag)
    placement_inputs <- metric_inputs[
      vapply(
        metric_inputs,
        function(data)
          identical(unique(as.character(data$position)), placement),
        logical(1)
      )
    ]
    available <- dplyr::bind_rows(
      lapply(placement_inputs, base_model_participant_keys)
    ) |>
      dplyr::distinct() |>
      dplyr::arrange(.data$site, .data$Id)
    available[[flag]] <- TRUE
    metadata <- left_join_checked(
      metadata,
      available,
      by = c("site", "Id"),
      relationship = "one-to-one",
      x_name = "participant metadata domain",
      y_name = paste0("metric availability for `", placement, "`")
    )
    metadata[[flag]] <- dplyr::coalesce(metadata[[flag]], FALSE)
  }
  metadata$has_any_light_metric <- metadata$has_glasses_metrics |
    metadata$has_chest_metrics
  metadata <- metadata |>
    dplyr::select(
      dplyr::all_of(c(
        "site",
        "Id",
        "has_any_light_metric",
        placement_flags,
        modality_flags,
        questionnaire_fields
      ))
    ) |>
    dplyr::arrange(.data$site, .data$Id)
  for (modality in base_model_questionnaire_modalities()) {
    source <- normalized_inputs[[modality]]
    fields <- base_model_questionnaire_fields(source, modality)
    for (field in fields) {
      attr(metadata[[field]], "label") <- attr(
        source[[field]],
        "label",
        exact = TRUE
      )
    }
  }
  assert_unique_key(
    metadata,
    c("site", "Id"),
    object = "participant metadata"
  )
  disallowed <- intersect(
    names(metadata),
    base_model_disallowed_free_text_columns()
  )
  if (length(disallowed) > 0L) {
    abort_pipeline(
      "Participant metadata contains free-text field(s): %s",
      paste(disallowed, collapse = ", ")
    )
  }
  metadata
}

base_model_join_participant_metadata <- function(
  data,
  participant_metadata,
  placement,
  resolution,
  input_id
) {
  validate_base_model_metric_input(
    data,
    placement,
    resolution,
    object = paste0("metric input `", input_id, "`")
  )
  assert_unique_key(
    participant_metadata,
    c("site", "Id"),
    object = "participant metadata"
  )
  overlap <- intersect(
    setdiff(names(data), c("site", "Id")),
    setdiff(names(participant_metadata), c("site", "Id"))
  )
  if (length(overlap) > 0L) {
    abort_pipeline(
      "Metric/metadata join for `%s` has overlapping field(s): %s",
      input_id,
      paste(overlap, collapse = ", ")
    )
  }
  metadata_join <- participant_metadata |>
    dplyr::mutate(.base_metadata_matched = TRUE)
  input <- data |>
    dplyr::mutate(.base_input_row = dplyr::row_number())
  joined <- left_join_checked(
    input,
    metadata_join,
    by = c("site", "Id"),
    relationship = "many-to-one",
    x_name = paste0("metric input `", input_id, "`"),
    y_name = "participant metadata"
  )
  unmatched <- sum(is.na(joined$.base_metadata_matched))
  row_order_preserved <- identical(
    joined$.base_input_row,
    seq_len(nrow(data))
  )
  if (
    nrow(joined) != nrow(data) ||
      unmatched != 0L ||
      !row_order_preserved
  ) {
    abort_pipeline(
      paste0(
        "Participant metadata join for `%s` failed: %d input rows, ",
        "%d output rows, %d unmatched, row order preserved=%s"
      ),
      input_id,
      nrow(data),
      nrow(joined),
      unmatched,
      row_order_preserved
    )
  }
  output <- joined |>
    dplyr::select(
      -dplyr::all_of(c(".base_input_row", ".base_metadata_matched"))
    )
  metadata_fields <- setdiff(
    names(participant_metadata),
    c("site", "Id")
  )
  for (field in metadata_fields) {
    attr(output[[field]], "label") <- attr(
      participant_metadata[[field]],
      "label",
      exact = TRUE
    )
  }
  key <- base_model_metric_key(resolution)
  assert_unique_key(output, key, object = paste0(input_id, " enriched"))
  list(
    data = output,
    audit = tibble::tibble(
      input_id = input_id,
      placement = placement,
      resolution = resolution,
      stage = "participant_metadata_join",
      join_key = "site|Id",
      relationship = "many-to-one",
      input_rows = nrow(data),
      output_rows = nrow(output),
      input_unique_keys = nrow(unique(data[key])),
      output_unique_keys = nrow(unique(output[key])),
      missing_key_rows = sum(!stats::complete.cases(output[key])),
      duplicated_key_rows = sum(
        duplicated(output[key]) |
          duplicated(output[key], fromLast = TRUE)
      ),
      unmatched_rows = unmatched,
      row_order_preserved = row_order_preserved,
      key_set_preserved = identical(
        data[key],
        output[key]
      ),
      status = "PASS"
    )
  )
}

base_model_equal_vector <- function(x, y) {
  if (
    length(x) != length(y) ||
      !identical(is.na(x), is.na(y)) ||
      !identical(class(x), class(y))
  ) {
    return(FALSE)
  }
  keep <- !is.na(x)
  if (!any(keep)) {
    return(TRUE)
  }
  if (
    is.numeric(x) ||
      inherits(x, c("POSIXt", "Date", "difftime"))
  ) {
    return(identical(as.numeric(x[keep]), as.numeric(y[keep])))
  }
  identical(as.character(x[keep]), as.character(y[keep]))
}

base_model_build_metadata_field_audit <- function(
  normalized_inputs,
  participant_metadata
) {
  rows <- list()
  row_index <- 0L
  for (modality in base_model_questionnaire_modalities()) {
    source <- normalized_inputs[[modality]]
    fields <- base_model_questionnaire_fields(source, modality)
    matched <- left_join_checked(
      source |>
        dplyr::select(dplyr::all_of(c("site", "Id"))),
      participant_metadata,
      by = c("site", "Id"),
      relationship = "one-to-one",
      x_name = paste0("source keys for `", modality, "`"),
      y_name = "participant metadata"
    )
    for (field in fields) {
      row_index <- row_index + 1L
      source_levels <- levels(source[[field]])
      output_levels <- levels(participant_metadata[[field]])
      source_label <- attr(source[[field]], "label", exact = TRUE)
      output_label <- attr(
        participant_metadata[[field]],
        "label",
        exact = TRUE
      )
      levels_preserved <- if (is.null(source_levels)) {
        is.null(output_levels)
      } else {
        identical(source_levels, output_levels)
      }
      label_preserved <- if (is.null(source_label)) {
        is.null(output_label)
      } else {
        identical(source_label, output_label)
      }
      values_preserved <- base_model_equal_vector(
        source[[field]],
        matched[[field]]
      )
      rows[[row_index]] <- tibble::tibble(
        modality = modality,
        source_field = field,
        output_field = field,
        source_class = paste(class(source[[field]]), collapse = "/"),
        output_class = paste(
          class(participant_metadata[[field]]),
          collapse = "/"
        ),
        source_nonmissing = sum(!is.na(source[[field]])),
        output_nonmissing_on_source_keys = sum(!is.na(matched[[field]])),
        values_preserved = values_preserved,
        factor_levels_preserved = levels_preserved,
        label_preserved = label_preserved,
        status = if (
          values_preserved &&
            levels_preserved &&
            label_preserved
        ) {
          "PASS"
        } else {
          "FAIL"
        }
      )
    }
  }
  dplyr::bind_rows(rows)
}

base_model_build_modality_audit <- function(
  normalized_inputs,
  participant_metadata
) {
  rows <- lapply(base_model_normalized_modalities(), function(modality) {
    data <- normalized_inputs[[modality]]
    key <- base_model_modality_key(modality)
    missing_key <- !stats::complete.cases(data[key])
    duplicated_key <- duplicated(data[key]) |
      duplicated(data[key], fromLast = TRUE)
    participants <- base_model_participant_keys(data)
    flag <- base_model_availability_flag(modality)
    matched <- left_join_checked(
      participants,
      participant_metadata |>
        dplyr::select(dplyr::all_of(c("site", "Id", flag))),
      by = c("site", "Id"),
      relationship = "one-to-one",
      x_name = paste0("participant keys for `", modality, "`"),
      y_name = "participant metadata"
    )
    missing_participants <- sum(is.na(matched[[flag]]))
    false_flags <- sum(!is.na(matched[[flag]]) & !matched[[flag]])
    tibble::tibble(
      modality = modality,
      key_role = base_model_modality_key_role(modality),
      key_columns = paste(key, collapse = "|"),
      input_rows = nrow(data),
      missing_key_rows = sum(missing_key),
      duplicated_key_rows = sum(duplicated_key),
      unique_participants = nrow(participants),
      participant_domain_rows = nrow(participant_metadata),
      availability_flag = flag,
      participants_flagged_available = sum(
        participant_metadata[[flag]]
      ),
      participants_absent_from_domain = missing_participants,
      available_participants_flagged_false = false_flags,
      participant_flag_join_relationship = "one-to-one",
      status = if (
        sum(missing_key) == 0L &&
          sum(duplicated_key) == 0L &&
          missing_participants == 0L &&
          false_flags == 0L &&
          sum(participant_metadata[[flag]]) == nrow(participants)
      ) {
        "PASS"
      } else {
        "FAIL"
      }
    )
  })
  dplyr::bind_rows(rows)
}

base_model_build_participant_availability_audit <- function(
  participant_metadata
) {
  flag_columns <- c(
    "has_any_light_metric",
    "has_glasses_metrics",
    "has_chest_metrics",
    paste0("has_", base_model_normalized_modalities())
  )
  assert_columns(
    participant_metadata,
    c("site", "Id", flag_columns),
    object = "participant metadata"
  )
  questionnaire_flags <- paste0(
    "has_",
    base_model_questionnaire_modalities()
  )
  diary_flags <- paste0(
    "has_",
    c("exercisediary", "lightexposurediary", "sleepdiaries")
  )
  participant_metadata |>
    dplyr::transmute(
      site = .data$site,
      Id = .data$Id,
      metric_scope = dplyr::case_when(
        .data$has_glasses_metrics & .data$has_chest_metrics ~
          "glasses_and_chest",
        .data$has_glasses_metrics ~ "glasses_only",
        .data$has_chest_metrics ~ "chest_only",
        TRUE ~ "no_light_metric"
      ),
      has_any_light_metric = .data$has_any_light_metric,
      has_glasses_metrics = .data$has_glasses_metrics,
      has_chest_metrics = .data$has_chest_metrics,
      has_demographics = .data$has_demographics,
      has_chronotype = .data$has_chronotype,
      has_leba = .data$has_leba,
      has_vlsq8 = .data$has_vlsq8,
      has_exercisediary = .data$has_exercisediary,
      has_lightexposurediary = .data$has_lightexposurediary,
      has_sleepdiaries = .data$has_sleepdiaries,
      questionnaire_modalities_available = rowSums(
        dplyr::pick(dplyr::all_of(questionnaire_flags))
      ),
      diary_modalities_available = rowSums(
        dplyr::pick(dplyr::all_of(diary_flags))
      ),
      no_participant_questionnaire = .data$has_demographics == FALSE &
        .data$has_chronotype == FALSE &
        .data$has_leba == FALSE &
        .data$has_vlsq8 == FALSE,
      filtering_applied = FALSE,
      status = "PASS"
    ) |>
    dplyr::arrange(.data$site, .data$Id)
}

base_model_build_metric_metadata_availability_audit <- function(
  metric_inputs,
  normalized_inputs
) {
  rows <- list()
  row_index <- 0L
  for (placement in base_model_placements()) {
    selected <- metric_inputs[
      vapply(
        metric_inputs,
        function(data)
          identical(unique(as.character(data$position)), placement),
        logical(1)
      )
    ]
    metric_participants <- dplyr::bind_rows(
      lapply(selected, base_model_participant_keys)
    ) |>
      dplyr::distinct() |>
      dplyr::arrange(.data$site, .data$Id)
    for (modality in base_model_normalized_modalities()) {
      row_index <- row_index + 1L
      modality_participants <- base_model_participant_keys(
        normalized_inputs[[modality]]
      )
      present <- dplyr::semi_join(
        metric_participants,
        modality_participants,
        by = c("site", "Id")
      )
      absent <- dplyr::anti_join(
        metric_participants,
        modality_participants,
        by = c("site", "Id")
      )
      modality_only <- dplyr::anti_join(
        modality_participants,
        metric_participants,
        by = c("site", "Id")
      )
      metric_participant_count <- nrow(metric_participants)
      modality_participant_count <- nrow(modality_participants)
      present_count <- nrow(present)
      absent_count <- nrow(absent)
      modality_only_count <- nrow(modality_only)
      rows[[row_index]] <- tibble::tibble(
        placement = placement,
        modality = modality,
        metric_participants = metric_participant_count,
        modality_participants = modality_participant_count,
        metric_participants_present = present_count,
        metric_participants_absent = absent_count,
        modality_participants_without_placement_metrics = modality_only_count,
        availability_proportion = present_count /
          metric_participant_count,
        filtering_applied = FALSE,
        status = "PASS"
      )
    }
  }
  dplyr::bind_rows(rows)
}

base_model_contract <- function() {
  tibble::tibble(
    layer = "preparation06_canonical_base_model_data",
    scope = paste0(
      "hypothesis_neutral_joins_only_no_models_no_estimands_",
      "no_complete_case_filtering"
    ),
    participant_domain_rule = paste0(
      "union_of_all_normalized_modality_and_metric_participant_keys"
    ),
    participant_metadata_rule = paste0(
      "questionnaire_fields_preserved_without_rescoring_plus_",
      "seven_modality_availability_flags"
    ),
    context_join_key = "site|local_date",
    context_join_relationship = "many-to-one",
    metadata_join_key = "site|Id",
    metadata_join_relationship = "many-to-one",
    diary_join_rule = paste0(
      "no_semantic_diary_join;diaries_contribute_availability_flags_only"
    ),
    metric_registry_rule = paste0(
      "m10_l10_onset_offset_internal_diagnostics_only;",
      "absent_from_model_ready_outputs"
    ),
    missing_data_rule = "retain_missing_values_no_complete_case_filter",
    placement_rule = "placement_specific_no_pooling",
    r_version = as.character(getRversion()),
    dplyr_version = as.character(utils::packageVersion("dplyr")),
    readr_version = as.character(utils::packageVersion("readr")),
    tibble_version = as.character(utils::packageVersion("tibble")),
    status = "PASS"
  )
}
