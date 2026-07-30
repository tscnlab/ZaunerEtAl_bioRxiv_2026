# Independently verify Preparation 06 canonical base-model artifacts.
#
# Source paths_io.R and assertions.R before this file. This verifier does not
# call the base-model producer, builder, or their helper functions.

p06_base_verify_placements <- function() {
  c("glasses", "chest")
}

p06_base_verify_modalities <- function() {
  c(
    "demographics",
    "chronotype",
    "leba",
    "vlsq8",
    "exercisediary",
    "lightexposurediary",
    "sleepdiaries"
  )
}

p06_base_verify_questionnaires <- function() {
  c("demographics", "chronotype", "leba", "vlsq8")
}

p06_base_verify_provenance_fields <- function() {
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

p06_base_verify_disallowed_free_text <- function() {
  c(
    "comments",
    "comments_english",
    "type",
    "type_english",
    "activity_desc",
    "activity_desc_english"
  )
}

p06_base_verify_metric_specification <- function(root) {
  metric_root <- file.path(root, "artifacts", "05_metrics")
  tibble::tribble(
    ~input_id,
    ~placement,
    ~resolution,
    ~path,
    "glasses_participant_day",
    "glasses",
    "participant_day",
    file.path(metric_root, "metrics_glasses_participant_day.rds"),
    "chest_participant_day",
    "chest",
    "participant_day",
    file.path(metric_root, "metrics_chest_participant_day.rds"),
    "glasses_participant",
    "glasses",
    "participant",
    file.path(metric_root, "metrics_glasses_participant.rds"),
    "chest_participant",
    "chest",
    "participant",
    file.path(metric_root, "metrics_chest_participant.rds"),
    "glasses_30_minute",
    "glasses",
    "30_minute",
    file.path(metric_root, "metrics_glasses_30_minute.rds"),
    "chest_30_minute",
    "chest",
    "30_minute",
    file.path(metric_root, "metrics_chest_30_minute.rds"),
    "glasses_one_hour",
    "glasses",
    "one_hour",
    file.path(metric_root, "metrics_glasses_one_hour.rds"),
    "chest_one_hour",
    "chest",
    "one_hour",
    file.path(metric_root, "metrics_chest_one_hour.rds")
  )
}

p06_base_verify_normalized_paths <- function(root) {
  modalities <- p06_base_verify_modalities()
  stats::setNames(
    file.path(
      root,
      "artifacts",
      "06_model_data",
      "normalized_inputs",
      paste0(modalities, ".rds")
    ),
    modalities
  )
}

p06_base_verify_output_paths <- function(output_root) {
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

p06_base_verify_metric_key <- function(resolution) {
  participant <- c("site", "Id", "position")
  participant_day <- c(participant, "local_date")
  switch(
    resolution,
    participant = participant,
    participant_day = participant_day,
    `30_minute` = c(participant_day, "clock_bin"),
    one_hour = c(participant_day, "clock_minute"),
    abort_pipeline("Verifier encountered unknown resolution: %s", resolution)
  )
}

p06_base_verify_internal_window_boundary_columns <- function() {
  c(
    "m10_onset_clock_minute",
    "m10_offset_clock_minute",
    "l10_onset_clock_minute",
    "l10_offset_clock_minute"
  )
}

p06_base_verify_registry_firewall <- function(
  data,
  input_id,
  placement,
  resolution
) {
  p06_base_verify_metric_input(
    data,
    placement,
    resolution,
    paste0("verifier metric `", input_id, "` before firewall")
  )
  prohibited <- p06_base_verify_internal_window_boundary_columns()
  present <- intersect(names(data), prohibited)
  if (
    length(present) > 0L &&
      !identical(resolution, "participant_day")
  ) {
    abort_pipeline(
      "Verifier found window boundaries at unexpected resolution `%s`",
      resolution
    )
  }
  output <- data[, setdiff(names(data), prohibited), drop = FALSE]
  p06_base_verify_metric_input(
    output,
    placement,
    resolution,
    paste0("verifier metric `", input_id, "` after firewall")
  )
  key <- p06_base_verify_metric_key(resolution)
  key_preserved <- identical(data[key], output[key])
  row_order_preserved <- nrow(data) == nrow(output) &&
    key_preserved
  if (
    ncol(output) != ncol(data) - length(present) ||
      !row_order_preserved ||
      length(intersect(names(output), prohibited)) > 0L
  ) {
    abort_pipeline(
      "Verifier metric-registry firewall failed for `%s`",
      input_id
    )
  }
  present_text <- if (length(present) == 0L) {
    NA_character_
  } else {
    paste(present, collapse = "|")
  }
  list(
    data = output,
    audit = tibble::tibble(
      input_id = input_id,
      placement = placement,
      resolution = resolution,
      input_rows = nrow(data),
      output_rows = nrow(output),
      input_columns = ncol(data),
      output_columns = ncol(output),
      prohibited_columns_expected = paste(prohibited, collapse = "|"),
      prohibited_columns_present = present_text,
      prohibited_columns_removed = present_text,
      prohibited_column_count = length(present),
      row_order_preserved = row_order_preserved,
      key_set_preserved = key_preserved,
      outcome_values_recalculated = FALSE,
      status = "PASS"
    )
  )
}

p06_base_verify_modality_key <- function(modality) {
  switch(
    modality,
    demographics = c("site", "Id"),
    chronotype = c("site", "Id"),
    leba = c("site", "Id"),
    vlsq8 = c("site", "Id"),
    exercisediary = c("site", "Id", "Date"),
    lightexposurediary = c("site", "source_row"),
    sleepdiaries = c("site", "source_row"),
    abort_pipeline("Verifier encountered unknown modality: %s", modality)
  )
}

p06_base_verify_relative_path <- function(path, anchor) {
  path <- normalizePath(path, winslash = "/", mustWork = TRUE)
  anchor <- normalizePath(anchor, winslash = "/", mustWork = TRUE)
  prefix <- paste0(anchor, "/")
  if (startsWith(path, prefix)) {
    return(substring(path, nchar(prefix) + 1L))
  }
  path
}

p06_base_verify_absolute_path <- function(path, anchor) {
  vapply(
    path,
    function(value) {
      candidate <- if (grepl("^/", value)) {
        value
      } else {
        file.path(anchor, value)
      }
      normalizePath(candidate, winslash = "/", mustWork = TRUE)
    },
    character(1)
  )
}

p06_base_verify_text_hash <- function(text) {
  unname(unclass(as.character(openssl::sha256(charToRaw(text)))))
}

p06_base_verify_participant_keys <- function(data) {
  assert_no_missing_key(data, c("site", "Id"), object = "verifier input")
  tibble::tibble(
    site = as.character(data$site),
    Id = as.character(data$Id)
  ) |>
    dplyr::distinct() |>
    dplyr::arrange(.data$site, .data$Id)
}

p06_base_verify_metric_input <- function(
  data,
  placement,
  resolution,
  object
) {
  if (!is.data.frame(data) || nrow(data) == 0L) {
    abort_pipeline("%s must be a non-empty data frame", object)
  }
  key <- p06_base_verify_metric_key(resolution)
  assert_unique_key(data, key, object = object)
  if (
    !is.character(data$site) ||
      !is.character(data$Id) ||
      !is.character(data$position) ||
      !identical(unique(as.character(data$position)), placement)
  ) {
    abort_pipeline("%s has invalid participant/placement keys", object)
  }
  if (
    !identical(resolution, "participant") &&
      !inherits(data$local_date, "Date")
  ) {
    abort_pipeline("%s has a non-Date `local_date`", object)
  }
  if (resolution %in% c("30_minute", "one_hour")) {
    clock <- if (identical(resolution, "30_minute")) {
      "clock_bin"
    } else {
      "clock_minute"
    }
    expected <- if (identical(resolution, "30_minute")) {
      seq.int(0L, 1410L, by = 30L)
    } else {
      seq.int(0L, 1380L, by = 60L)
    }
    grids <- split(
      as.integer(data[[clock]]),
      interaction(
        data$site,
        data$Id,
        data$position,
        data$local_date,
        drop = TRUE,
        lex.order = TRUE
      )
    )
    valid <- vapply(
      grids,
      function(value) identical(sort(value), expected),
      logical(1)
    )
    if (!all(valid)) {
      abort_pipeline("%s has an incomplete clock grid", object)
    }
  }
  invisible(data)
}

p06_base_verify_context_join <- function(metric, context) {
  assert_unique_key(
    context,
    c("site", "local_date"),
    object = "verifier site context"
  )
  input <- metric |>
    dplyr::mutate(.verify_row = dplyr::row_number())
  lookup <- context |>
    dplyr::mutate(.verify_context = TRUE)
  joined <- dplyr::left_join(
    input,
    lookup,
    by = c("site", "local_date"),
    relationship = "many-to-one"
  )
  if (
    nrow(joined) != nrow(metric) ||
      anyNA(joined$.verify_context) ||
      !identical(joined$.verify_row, seq_len(nrow(metric)))
  ) {
    abort_pipeline("Independent context reconstruction lost or reordered rows")
  }
  joined |>
    dplyr::select(-dplyr::all_of(c(".verify_row", ".verify_context")))
}

p06_base_verify_build_metadata <- function(normalized, metrics) {
  modality_keys <- lapply(
    p06_base_verify_modalities(),
    function(modality) {
      data <- normalized[[modality]]
      assert_unique_key(
        data,
        p06_base_verify_modality_key(modality),
        object = paste0("verifier normalized `", modality, "`")
      )
      p06_base_verify_participant_keys(data)
    }
  )
  metric_keys <- lapply(metrics, p06_base_verify_participant_keys)
  metadata <- dplyr::bind_rows(c(modality_keys, metric_keys)) |>
    dplyr::distinct() |>
    dplyr::arrange(.data$site, .data$Id)
  fields_by_modality <- list()
  observed_fields <- character()
  for (modality in p06_base_verify_questionnaires()) {
    data <- normalized[[modality]]
    fields <- setdiff(
      names(data),
      p06_base_verify_provenance_fields()
    )
    if (
      length(fields) == 0L ||
        length(intersect(observed_fields, fields)) > 0L
    ) {
      abort_pipeline(
        "Verifier found empty or colliding questionnaire fields"
      )
    }
    fields_by_modality[[modality]] <- fields
    observed_fields <- c(observed_fields, fields)
    metadata <- dplyr::left_join(
      metadata,
      data |>
        dplyr::select(dplyr::all_of(c("site", "Id", fields))),
      by = c("site", "Id"),
      relationship = "one-to-one"
    )
  }
  modality_flags <- paste0("has_", p06_base_verify_modalities())
  for (index in seq_along(p06_base_verify_modalities())) {
    modality <- p06_base_verify_modalities()[[index]]
    flag <- modality_flags[[index]]
    available <- p06_base_verify_participant_keys(
      normalized[[modality]]
    )
    available[[flag]] <- TRUE
    metadata <- dplyr::left_join(
      metadata,
      available,
      by = c("site", "Id"),
      relationship = "one-to-one"
    )
    metadata[[flag]] <- dplyr::coalesce(metadata[[flag]], FALSE)
  }
  placement_flags <- paste0(
    "has_",
    p06_base_verify_placements(),
    "_metrics"
  )
  for (index in seq_along(p06_base_verify_placements())) {
    placement <- p06_base_verify_placements()[[index]]
    flag <- placement_flags[[index]]
    selected <- metrics[
      vapply(
        metrics,
        function(data)
          identical(unique(as.character(data$position)), placement),
        logical(1)
      )
    ]
    available <- dplyr::bind_rows(
      lapply(selected, p06_base_verify_participant_keys)
    ) |>
      dplyr::distinct() |>
      dplyr::arrange(.data$site, .data$Id)
    available[[flag]] <- TRUE
    metadata <- dplyr::left_join(
      metadata,
      available,
      by = c("site", "Id"),
      relationship = "one-to-one"
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
        observed_fields
      ))
    ) |>
    dplyr::arrange(.data$site, .data$Id)
  for (modality in p06_base_verify_questionnaires()) {
    for (field in fields_by_modality[[modality]]) {
      attr(metadata[[field]], "label") <- attr(
        normalized[[modality]][[field]],
        "label",
        exact = TRUE
      )
    }
  }
  assert_unique_key(
    metadata,
    c("site", "Id"),
    object = "verifier participant metadata"
  )
  metadata
}

p06_base_verify_enrichment <- function(metric, metadata) {
  input <- metric |>
    dplyr::mutate(.verify_row = dplyr::row_number())
  lookup <- metadata |>
    dplyr::mutate(.verify_metadata = TRUE)
  joined <- dplyr::left_join(
    input,
    lookup,
    by = c("site", "Id"),
    relationship = "many-to-one"
  )
  if (
    nrow(joined) != nrow(metric) ||
      anyNA(joined$.verify_metadata) ||
      !identical(joined$.verify_row, seq_len(nrow(metric)))
  ) {
    abort_pipeline(
      "Independent participant-metadata reconstruction lost or reordered rows"
    )
  }
  output <- joined |>
    dplyr::select(
      -dplyr::all_of(c(".verify_row", ".verify_metadata"))
    )
  for (field in setdiff(names(metadata), c("site", "Id"))) {
    attr(output[[field]], "label") <- attr(
      metadata[[field]],
      "label",
      exact = TRUE
    )
  }
  output
}

p06_base_verify_data_identical <- function(observed, expected, object) {
  if (!identical(observed, expected)) {
    if (
      !identical(names(observed), names(expected)) ||
        nrow(observed) != nrow(expected) ||
        ncol(observed) != ncol(expected)
    ) {
      abort_pipeline(
        "%s differs in names or dimensions from independent reconstruction",
        object
      )
    }
    differing <- names(observed)[vapply(
      names(observed),
      function(column) {
        !identical(observed[[column]], expected[[column]])
      },
      logical(1)
    )]
    abort_pipeline(
      "%s differs from independent reconstruction in column(s): %s",
      object,
      paste(differing, collapse = ", ")
    )
  }
  invisible(TRUE)
}

p06_base_verify_expected_input_ids <- function() {
  c(
    p06_base_verify_metric_specification(".")$input_id,
    "site_solar_context",
    paste0("normalized_", p06_base_verify_modalities())
  )
}

verify_base_model_data_artifacts <- function(
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
    abort_pipeline(
      "Base-model verification requires R 4.6.1; found %s",
      as.character(getRversion())
    )
  }
  output_paths <- p06_base_verify_output_paths(output_root)
  required_outputs <- c(
    output_paths$data_paths,
    output_paths$audit_paths,
    output_paths$manifest
  )
  missing_outputs <- required_outputs[!file.exists(required_outputs)]
  if (length(missing_outputs) > 0L) {
    abort_pipeline(
      "Base-model verification is missing artifact(s): %s",
      paste(missing_outputs, collapse = ", ")
    )
  }

  manifest <- readr::read_csv(
    output_paths$manifest,
    show_col_types = FALSE,
    progress = FALSE
  )
  expected_manifest_columns <- c(
    "artifact_id",
    "artifact_type",
    "path",
    "sha256",
    "bytes",
    "rows",
    "columns",
    "input_bundle_sha256",
    "metric_manifest_sha256",
    "normalization_manifest_sha256",
    "site_context_manifest_sha256",
    "producer",
    "r_version",
    "status"
  )
  if (!identical(names(manifest), expected_manifest_columns)) {
    abort_pipeline("Base-model manifest columns differ from the contract")
  }
  expected_ids <- c(
    names(output_paths$data_paths),
    names(output_paths$audit_paths)
  )
  if (!identical(manifest$artifact_id, expected_ids)) {
    abort_pipeline("Base-model manifest artifact order differs")
  }
  assert_unique_key(
    manifest,
    "artifact_id",
    object = "base-model manifest"
  )
  expected_paths <- c(
    output_paths$data_paths,
    output_paths$audit_paths
  )
  expected_types <- c(
    rep("rds", length(output_paths$data_paths)),
    rep("csv", length(output_paths$audit_paths))
  )
  if (!identical(manifest$artifact_type, expected_types)) {
    abort_pipeline("Base-model manifest artifact types differ")
  }
  expected_relative <- vapply(
    expected_paths,
    p06_base_verify_relative_path,
    character(1),
    anchor = output_root
  )
  if (!identical(manifest$path, unname(expected_relative))) {
    abort_pipeline("Base-model manifest paths differ from expected outputs")
  }
  for (index in seq_len(nrow(manifest))) {
    path <- expected_paths[[manifest$artifact_id[[index]]]]
    artifact <- if (manifest$artifact_type[[index]] == "rds") {
      readRDS(path)
    } else {
      readr::read_csv(
        path,
        show_col_types = FALSE,
        progress = FALSE
      )
    }
    if (
      artifact_sha256(path) != manifest$sha256[[index]] ||
        unname(file.info(path)$size) != manifest$bytes[[index]] ||
        nrow(artifact) != manifest$rows[[index]] ||
        ncol(artifact) != manifest$columns[[index]] ||
        manifest$producer[[index]] !=
          "scripts/pipeline/build_base_model_data.R" ||
        manifest$r_version[[index]] != "4.6.1" ||
        manifest$status[[index]] != "PASS"
    ) {
      abort_pipeline(
        "Base-model manifest integrity failed for `%s`",
        manifest$artifact_id[[index]]
      )
    }
  }

  provenance <- readr::read_csv(
    output_paths$audit_paths[["input_provenance"]],
    show_col_types = FALSE,
    progress = FALSE
  )
  expected_input_ids <- p06_base_verify_expected_input_ids()
  if (!identical(provenance$input_id, expected_input_ids)) {
    abort_pipeline("Base-model input provenance order differs")
  }
  assert_unique_key(
    provenance,
    "input_id",
    object = "base-model input provenance"
  )
  for (index in seq_len(nrow(provenance))) {
    input_path <- p06_base_verify_absolute_path(
      provenance$path[[index]],
      root
    )
    upstream_manifest_path <- p06_base_verify_absolute_path(
      provenance$upstream_manifest_path[[index]],
      root
    )
    if (
      artifact_sha256(input_path) != provenance$sha256[[index]] ||
        unname(file.info(input_path)$size) != provenance$bytes[[index]] ||
        artifact_sha256(upstream_manifest_path) !=
          provenance$upstream_manifest_sha256[[index]] ||
        provenance$sha256[[index]] !=
          provenance$upstream_declared_sha256[[index]] ||
        provenance$upstream_r_version[[index]] != "4.6.1" ||
        provenance$status[[index]] != "PASS"
    ) {
      abort_pipeline(
        "Independent input-provenance verification failed for `%s`",
        provenance$input_id[[index]]
      )
    }
    input_object <- readRDS(input_path)
    if (
      !is.data.frame(input_object) ||
        nrow(input_object) != provenance$rows[[index]] ||
        ncol(input_object) != provenance$columns[[index]]
    ) {
      abort_pipeline(
        "Input dimensions differ for `%s`",
        provenance$input_id[[index]]
      )
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
  input_bundle_sha256 <- p06_base_verify_text_hash(input_bundle_text)
  if (any(manifest$input_bundle_sha256 != input_bundle_sha256)) {
    abort_pipeline("Base-model manifest input-bundle hash differs")
  }
  manifest_names <- c(
    metrics = "metric_manifest_sha256",
    normalization = "normalization_manifest_sha256",
    site_context = "site_context_manifest_sha256"
  )
  for (name in names(manifest_names)) {
    expected_hash <- unique(
      provenance$upstream_manifest_sha256[
        grepl(
          switch(
            name,
            metrics = "metric_artifacts",
            normalization = "model_input_normalization",
            site_context = "site_solar_context_artifacts"
          ),
          provenance$upstream_manifest_path
        )
      ]
    )
    if (
      length(expected_hash) != 1L ||
        any(manifest[[manifest_names[[name]]]] != expected_hash)
    ) {
      abort_pipeline(
        "Base-model manifest has inconsistent %s provenance",
        name
      )
    }
  }

  metric_specification <- p06_base_verify_metric_specification(root)
  metric_paths <- stats::setNames(
    metric_specification$path,
    metric_specification$input_id
  )
  metrics <- stats::setNames(
    lapply(metric_paths, readRDS),
    names(metric_paths)
  )
  normalized_paths <- p06_base_verify_normalized_paths(root)
  normalized <- stats::setNames(
    lapply(normalized_paths, readRDS),
    names(normalized_paths)
  )
  context_path <- file.path(
    root,
    "artifacts",
    "06_model_data",
    "context",
    "site_solar_context.rds"
  )
  context <- readRDS(context_path)
  assert_unique_key(
    context,
    c("site", "local_date"),
    object = "verifier site context"
  )
  for (index in seq_len(nrow(metric_specification))) {
    specification <- metric_specification[index, , drop = FALSE]
    p06_base_verify_metric_input(
      metrics[[specification$input_id]],
      specification$placement,
      specification$resolution,
      paste0("verifier metric `", specification$input_id, "`")
    )
  }
  firewall_results <- lapply(
    seq_len(nrow(metric_specification)),
    function(index) {
      specification <- metric_specification[index, , drop = FALSE]
      p06_base_verify_registry_firewall(
        metrics[[specification$input_id]],
        input_id = specification$input_id,
        placement = specification$placement,
        resolution = specification$resolution
      )
    }
  )
  firewall_expected <- dplyr::bind_rows(
    lapply(firewall_results, `[[`, "audit")
  )
  metrics <- stats::setNames(
    lapply(firewall_results, `[[`, "data"),
    metric_specification$input_id
  )
  for (modality in p06_base_verify_modalities()) {
    data <- normalized[[modality]]
    assert_unique_key(
      data,
      p06_base_verify_modality_key(modality),
      object = paste0("verifier normalized `", modality, "`")
    )
    assert_no_missing_key(
      data,
      c("site", "Id"),
      object = paste0("verifier normalized `", modality, "`")
    )
  }

  observed_data <- stats::setNames(
    lapply(output_paths$data_paths, readRDS),
    names(output_paths$data_paths)
  )
  metadata_expected <- p06_base_verify_build_metadata(
    normalized,
    metrics
  )
  p06_base_verify_data_identical(
    observed_data$participant_metadata,
    metadata_expected,
    "participant metadata"
  )
  expected_data <- list(participant_metadata = metadata_expected)
  for (placement in p06_base_verify_placements()) {
    participant_day_id <- paste0(placement, "_participant_day")
    participant_id <- paste0(placement, "_participant")
    day_context <- p06_base_verify_context_join(
      metrics[[participant_day_id]],
      context
    )
    expected_data[[paste0(
      placement,
      "_participant_day_context"
    )]] <- day_context
    expected_data[[participant_id]] <- metrics[[participant_id]]
    for (resolution in c("30_minute", "one_hour")) {
      input_id <- paste(placement, resolution, sep = "_")
      expected_data[[paste0(input_id, "_context")]] <-
        p06_base_verify_context_join(metrics[[input_id]], context)
    }
    expected_data[[paste0(
      placement,
      "_participant_day_enriched"
    )]] <- p06_base_verify_enrichment(
      day_context,
      metadata_expected
    )
    expected_data[[paste0(
      placement,
      "_participant_enriched"
    )]] <- p06_base_verify_enrichment(
      metrics[[participant_id]],
      metadata_expected
    )
  }
  expected_data <- expected_data[names(output_paths$data_paths)]
  for (artifact_id in names(expected_data)) {
    p06_base_verify_data_identical(
      observed_data[[artifact_id]],
      expected_data[[artifact_id]],
      artifact_id
    )
  }

  audit_data <- stats::setNames(
    lapply(output_paths$audit_paths, function(path) {
      readr::read_csv(
        path,
        show_col_types = FALSE,
        progress = FALSE
      )
    }),
    names(output_paths$audit_paths)
  )
  registry_firewall <- audit_data$metric_registry_firewall
  if (
    !isTRUE(all.equal(
      registry_firewall,
      firewall_expected,
      check.attributes = FALSE
    )) ||
      any(registry_firewall$status != "PASS") ||
      any(!registry_firewall$row_order_preserved) ||
      any(!registry_firewall$key_set_preserved) ||
      any(registry_firewall$outcome_values_recalculated)
  ) {
    abort_pipeline("Metric-registry firewall audit does not reconcile")
  }
  metric_audit <- audit_data$metric_key_join
  if (
    nrow(metric_audit) != 12L ||
      any(metric_audit$status != "PASS") ||
      any(metric_audit$input_rows != metric_audit$output_rows) ||
      any(metric_audit$missing_key_rows != 0L) ||
      any(metric_audit$duplicated_key_rows != 0L) ||
      any(metric_audit$unmatched_rows != 0L) ||
      any(!metric_audit$row_order_preserved) ||
      any(!metric_audit$key_set_preserved)
  ) {
    abort_pipeline("Metric key/join audit does not reconcile")
  }
  modality_audit <- audit_data$modality_key_join
  if (
    !identical(
      modality_audit$modality,
      p06_base_verify_modalities()
    ) ||
      any(modality_audit$status != "PASS") ||
      any(modality_audit$missing_key_rows != 0L) ||
      any(modality_audit$duplicated_key_rows != 0L) ||
      any(modality_audit$participants_absent_from_domain != 0L) ||
      any(
        modality_audit$available_participants_flagged_false != 0L
      )
  ) {
    abort_pipeline("Modality key/join audit does not reconcile")
  }
  for (index in seq_along(p06_base_verify_modalities())) {
    modality <- p06_base_verify_modalities()[[index]]
    participant_count <- nrow(
      p06_base_verify_participant_keys(normalized[[modality]])
    )
    if (
      modality_audit$input_rows[[index]] != nrow(normalized[[modality]]) ||
        modality_audit$unique_participants[[index]] != participant_count ||
        modality_audit$participants_flagged_available[[index]] !=
          participant_count
    ) {
      abort_pipeline(
        "Modality audit count differs for `%s`",
        modality
      )
    }
  }
  participant_availability <- audit_data$participant_availability
  availability_flags <- c(
    "has_any_light_metric",
    "has_glasses_metrics",
    "has_chest_metrics",
    paste0("has_", p06_base_verify_modalities())
  )
  if (
    nrow(participant_availability) != nrow(metadata_expected) ||
      any(participant_availability$status != "PASS") ||
      any(participant_availability$filtering_applied) ||
      !identical(
        participant_availability[c("site", "Id")],
        metadata_expected[c("site", "Id")]
      )
  ) {
    abort_pipeline("Participant availability audit does not reconcile")
  }
  for (flag in availability_flags) {
    if (
      !identical(
        participant_availability[[flag]],
        metadata_expected[[flag]]
      )
    ) {
      abort_pipeline(
        "Participant availability flag `%s` differs",
        flag
      )
    }
  }
  tum_s001 <- participant_availability[
    participant_availability$site == "TUM" &
      participant_availability$Id == "TUM_S001",
    ,
    drop = FALSE
  ]
  if (
    nrow(tum_s001) != 1L ||
      !tum_s001$has_any_light_metric[[1L]] ||
      !tum_s001$has_glasses_metrics[[1L]] ||
      !tum_s001$has_chest_metrics[[1L]] ||
      !tum_s001$has_demographics[[1L]] ||
      !tum_s001$has_chronotype[[1L]] ||
      !tum_s001$has_leba[[1L]] ||
      !tum_s001$has_vlsq8[[1L]] ||
      !tum_s001$has_exercisediary[[1L]] ||
      !tum_s001$has_lightexposurediary[[1L]] ||
      !tum_s001$has_sleepdiaries[[1L]] ||
      any(
        participant_availability$site == "TUM" &
          participant_availability$Id == "TUM_S101"
      )
  ) {
    abort_pipeline(
      "Corrected TUM_S001 availability differs from normalized inputs"
    )
  }
  field_audit <- audit_data$metadata_fields
  expected_field_count <- sum(vapply(
    p06_base_verify_questionnaires(),
    function(modality) {
      length(setdiff(
        names(normalized[[modality]]),
        p06_base_verify_provenance_fields()
      ))
    },
    integer(1)
  ))
  if (
    nrow(field_audit) != expected_field_count ||
      any(field_audit$status != "PASS") ||
      any(!field_audit$values_preserved) ||
      any(!field_audit$factor_levels_preserved) ||
      any(!field_audit$label_preserved)
  ) {
    abort_pipeline("Questionnaire field-preservation audit failed")
  }
  availability <- audit_data$metric_metadata_availability
  if (
    nrow(availability) != 14L ||
      any(availability$status != "PASS") ||
      any(availability$filtering_applied)
  ) {
    abort_pipeline("Metric/metadata availability audit is incomplete")
  }
  availability_expected <- list()
  availability_index <- 0L
  for (placement in p06_base_verify_placements()) {
    selected <- metrics[
      vapply(
        metrics,
        function(data)
          identical(unique(as.character(data$position)), placement),
        logical(1)
      )
    ]
    metric_participants <- dplyr::bind_rows(
      lapply(selected, p06_base_verify_participant_keys)
    ) |>
      dplyr::distinct()
    for (modality in p06_base_verify_modalities()) {
      availability_index <- availability_index + 1L
      modality_participants <- p06_base_verify_participant_keys(
        normalized[[modality]]
      )
      present_count <- nrow(dplyr::semi_join(
        metric_participants,
        modality_participants,
        by = c("site", "Id")
      ))
      absent_count <- nrow(metric_participants) - present_count
      modality_only_count <- nrow(dplyr::anti_join(
        modality_participants,
        metric_participants,
        by = c("site", "Id")
      ))
      availability_expected[[availability_index]] <- tibble::tibble(
        placement = placement,
        modality = modality,
        metric_participants = nrow(metric_participants),
        modality_participants = nrow(modality_participants),
        metric_participants_present = present_count,
        metric_participants_absent = absent_count,
        modality_participants_without_placement_metrics = modality_only_count
      )
    }
  }
  availability_expected <- dplyr::bind_rows(availability_expected)
  comparison_columns <- names(availability_expected)
  availability_matches <- isTRUE(all.equal(
    availability[comparison_columns],
    availability_expected,
    check.attributes = FALSE
  ))
  if (!availability_matches) {
    abort_pipeline(
      "Metric/metadata availability counts differ from reconstruction"
    )
  }
  contract <- audit_data$contract
  if (
    nrow(contract) != 1L ||
      contract$r_version[[1L]] != "4.6.1" ||
      contract$dplyr_version[[1L]] !=
        as.character(utils::packageVersion("dplyr")) ||
      contract$readr_version[[1L]] !=
        as.character(utils::packageVersion("readr")) ||
      contract$tibble_version[[1L]] !=
        as.character(utils::packageVersion("tibble")) ||
      contract$status[[1L]] != "PASS" ||
      contract$diary_join_rule[[1L]] !=
        paste0(
          "no_semantic_diary_join;",
          "diaries_contribute_availability_flags_only"
        ) ||
      contract$metric_registry_rule[[1L]] !=
        paste0(
          "m10_l10_onset_offset_internal_diagnostics_only;",
          "absent_from_model_ready_outputs"
        )
  ) {
    abort_pipeline("Base-model contract audit differs")
  }
  disallowed_outputs <- names(observed_data)[vapply(
    observed_data,
    function(data) {
      length(intersect(
        names(data),
        p06_base_verify_disallowed_free_text()
      )) >
        0L
    },
    logical(1)
  )]
  if (length(disallowed_outputs) > 0L) {
    abort_pipeline(
      "Base-model output(s) contain free-text fields: %s",
      paste(disallowed_outputs, collapse = ", ")
    )
  }
  boundary_outputs <- names(observed_data)[vapply(
    observed_data,
    function(data) {
      length(intersect(
        names(data),
        p06_base_verify_internal_window_boundary_columns()
      )) >
        0L
    },
    logical(1)
  )]
  if (length(boundary_outputs) > 0L) {
    abort_pipeline(
      "Base-model output(s) contain internal M10/L10 boundaries: %s",
      paste(boundary_outputs, collapse = ", ")
    )
  }

  artifact_summary <- tibble::tibble(
    artifact_id = manifest$artifact_id,
    path = manifest$path,
    rows = as.integer(manifest$rows),
    columns = as.integer(manifest$columns),
    sha256 = manifest$sha256,
    status = "PASS"
  )
  anomaly_summary <- availability |>
    dplyr::select(
      dplyr::all_of(c(
        "placement",
        "modality",
        "metric_participants",
        "metric_participants_present",
        "metric_participants_absent"
      ))
    )
  list(
    status = "PASS",
    artifact_summary = artifact_summary,
    input_bundle_sha256 = input_bundle_sha256,
    participant_metadata_rows = nrow(metadata_expected),
    metric_registry_firewall = registry_firewall,
    anomaly_summary = anomaly_summary,
    manifest_sha256 = artifact_sha256(output_paths$manifest)
  )
}
