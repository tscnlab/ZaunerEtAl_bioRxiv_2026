# Post-build verification for Canonical Preparation 01.
#
# Source paths_io.R and assertions.R before calling
# verify_import_alignment_artifacts(). The verifier reads the completed
# artifacts only; it does not rebuild or modify them.

verify_manifest_files <- function(manifest, object = "artifact manifest") {
  assert_columns(
    manifest,
    c("path", "sha256", "bytes"),
    object = object
  )
  assert_unique_key(manifest, "path", object = object)

  exists <- file.exists(manifest$path)
  if (!all(exists)) {
    abort_pipeline(
      "%s references missing file(s): %s",
      object,
      paste(manifest$path[!exists], collapse = ", ")
    )
  }

  observed_sha256 <- vapply(
    manifest$path,
    artifact_sha256,
    character(1)
  )
  observed_bytes <- unname(file.info(manifest$path)$size)
  hash_match <- observed_sha256 == as.character(manifest$sha256)
  byte_match <- observed_bytes == manifest$bytes
  if (!all(hash_match & byte_match)) {
    failed <- !(hash_match & byte_match)
    abort_pipeline(
      "%s disagrees with file bytes for: %s",
      object,
      paste(manifest$path[failed], collapse = ", ")
    )
  }

  tibble::tibble(
    artifacts = nrow(manifest),
    files_present = sum(exists),
    sha256_matches = sum(hash_match),
    byte_counts_match = sum(byte_match)
  )
}

verify_source_hash_propagation <- function(source_audit, pinned_downloads) {
  assert_columns(
    source_audit,
    c("site", "modality", "source_sha256", "source_bytes"),
    object = "source audit"
  )
  assert_columns(
    pinned_downloads,
    c(
      "site",
      "modality",
      "local_path",
      "sha256",
      "bytes",
      "downloaded"
    ),
    object = "pinned download manifest"
  )
  assert_unique_key(
    source_audit,
    c("site", "modality"),
    object = "source audit"
  )
  assert_unique_key(
    pinned_downloads,
    c("site", "modality"),
    object = "pinned download manifest"
  )

  if (
    !is.logical(pinned_downloads$downloaded) ||
      any(is.na(pinned_downloads$downloaded)) ||
      any(pinned_downloads$downloaded)
  ) {
    abort_pipeline(
      "The completed reuse build records a download or missing download flag"
    )
  }

  source_keys <- dplyr::select(
    source_audit,
    dplyr::all_of(c("site", "modality"))
  )
  pinned_keys <- dplyr::select(
    pinned_downloads,
    dplyr::all_of(c("site", "modality"))
  )
  source_only <- dplyr::anti_join(
    source_keys,
    pinned_keys,
    by = c("site", "modality")
  )
  pinned_only <- dplyr::anti_join(
    pinned_keys,
    source_keys,
    by = c("site", "modality")
  )
  if (nrow(source_only) > 0L || nrow(pinned_only) > 0L) {
    abort_pipeline(
      paste0(
        "Source audit and pinned download manifest have different ",
        "site/modality key sets"
      )
    )
  }

  source_exists <- file.exists(pinned_downloads$local_path)
  if (!all(source_exists)) {
    abort_pipeline(
      "Pinned download manifest references missing source file(s): %s",
      paste(
        pinned_downloads$local_path[!source_exists],
        collapse = ", "
      )
    )
  }
  observed_source_sha256 <- vapply(
    pinned_downloads$local_path,
    artifact_sha256,
    character(1)
  )
  observed_source_bytes <- unname(
    file.info(pinned_downloads$local_path)$size
  )
  source_byte_mismatch <-
    observed_source_sha256 != as.character(pinned_downloads$sha256) |
    observed_source_bytes != pinned_downloads$bytes
  if (any(source_byte_mismatch)) {
    abort_pipeline(
      "Pinned source bytes disagree with their manifest for: %s",
      paste(
        paste(
          pinned_downloads$site[source_byte_mismatch],
          pinned_downloads$modality[source_byte_mismatch],
          sep = "/"
        ),
        collapse = ", "
      )
    )
  }

  checked <- dplyr::left_join(
    source_audit,
    dplyr::transmute(
      pinned_downloads,
      site = .data$site,
      modality = .data$modality,
      pinned_sha256 = .data$sha256,
      pinned_bytes = .data$bytes
    ),
    by = c("site", "modality"),
    relationship = "one-to-one"
  )
  mismatch <- is.na(checked$pinned_sha256) |
    checked$source_sha256 != checked$pinned_sha256 |
    checked$source_bytes != checked$pinned_bytes
  if (any(mismatch)) {
    abort_pipeline(
      "Source hashes or byte counts failed to propagate for: %s",
      paste(
        paste(checked$site[mismatch], checked$modality[mismatch], sep = "/"),
        collapse = ", "
      )
    )
  }
  invisible(checked)
}

aligned_stream_verification_row <- function(
  aligned,
  placement,
  saturation_threshold
) {
  required <- c(
    "site",
    "Id",
    "position",
    "local_date",
    "datetime_utc",
    "MEDI",
    "LIGHT",
    "MEDI_raw",
    "LIGHT_raw",
    "invalid_nonwear",
    "medi_saturated",
    "valid_medi",
    "valid_light",
    "valid_medi_light_pair"
  )
  assert_columns(
    aligned,
    required,
    object = paste0("combined ", placement, " aligned stream")
  )
  flag_columns <- c(
    "invalid_nonwear",
    "medi_saturated",
    "valid_medi",
    "valid_light",
    "valid_medi_light_pair"
  )
  invalid_flags <- flag_columns[
    !vapply(
      aligned[flag_columns],
      function(column) is.logical(column) && !anyNA(column),
      logical(1)
    )
  ]
  if (length(invalid_flags) > 0L) {
    abort_pipeline(
      "Combined %s stream has invalid logical flag(s): %s",
      placement,
      paste(invalid_flags, collapse = ", ")
    )
  }
  if (
    anyNA(aligned$position) ||
      !identical(unique(as.character(aligned$position)), placement)
  ) {
    abort_pipeline(
      "Combined %s stream has an unexpected placement label",
      placement
    )
  }
  assert_unique_key(
    aligned,
    c("site", "Id", "position", "datetime_utc"),
    object = paste0("combined ", placement, " aligned stream")
  )

  expected_saturated <- is.finite(aligned$MEDI_raw) &
    aligned$MEDI_raw >= saturation_threshold
  if (!identical(as.logical(aligned$medi_saturated), expected_saturated)) {
    abort_pipeline(
      "Combined %s stream does not implement MEDI >= %s as invalid",
      placement,
      format(saturation_threshold, scientific = FALSE)
    )
  }
  if (any(expected_saturated & is.finite(aligned$MEDI))) {
    abort_pipeline(
      "Combined %s stream retains MEDI at or above its operating boundary",
      placement
    )
  }
  saturation_only <- expected_saturated & !aligned$invalid_nonwear
  if (
    any(
      is.finite(aligned$LIGHT_raw[saturation_only]) &
        !is.finite(aligned$LIGHT[saturation_only])
    )
  ) {
    abort_pipeline(
      "Combined %s stream incorrectly applies the MEDI boundary to LIGHT",
      placement
    )
  }

  expected_valid_medi <- is.finite(aligned$MEDI)
  expected_valid_light <- is.finite(aligned$LIGHT)
  expected_pair <- expected_valid_medi & expected_valid_light
  if (
    !identical(as.logical(aligned$valid_medi), expected_valid_medi) ||
      !identical(as.logical(aligned$valid_light), expected_valid_light) ||
      !identical(
        as.logical(aligned$valid_medi_light_pair),
        expected_pair
      )
  ) {
    abort_pipeline(
      "Combined %s stream has inconsistent signal-validity flags",
      placement
    )
  }

  tibble::tibble(
    placement = placement,
    rows = nrow(aligned),
    participants = dplyr::n_distinct(aligned$Id),
    participant_days = nrow(dplyr::distinct(
      aligned,
      .data$site,
      .data$Id,
      .data$local_date
    )),
    saturated_minutes = sum(expected_saturated),
    saturated_participants = dplyr::n_distinct(
      aligned$Id[expected_saturated]
    ),
    saturated_participant_days = nrow(dplyr::distinct(
      aligned[expected_saturated, , drop = FALSE],
      .data$site,
      .data$Id,
      .data$local_date
    ))
  )
}

verify_expected_import_summary <- function(observed, expected) {
  if (is.null(expected)) {
    return(invisible(observed))
  }
  required <- c(
    "placement",
    "rows",
    "participants",
    "participant_days",
    "saturated_minutes",
    "saturated_participants",
    "saturated_participant_days"
  )
  assert_columns(expected, required, object = "expected import summary")
  assert_unique_key(expected, "placement", object = "expected import summary")
  if (
    !setequal(
      as.character(observed$placement),
      as.character(expected$placement)
    )
  ) {
    abort_pipeline(
      paste0(
        "Observed and expected import summaries have different ",
        "placement sets"
      )
    )
  }
  checked <- dplyr::left_join(
    observed,
    expected,
    by = "placement",
    suffix = c("_observed", "_expected"),
    relationship = "one-to-one"
  )
  fields <- setdiff(required, "placement")
  mismatch <- Reduce(
    `|`,
    lapply(
      fields,
      function(field) {
        checked[[paste0(field, "_observed")]] !=
          checked[[paste0(field, "_expected")]]
      }
    )
  )
  if (any(is.na(mismatch)) || any(mismatch)) {
    abort_pipeline(
      "Preparation 01 summary differs from its approved expectation for: %s",
      paste(checked$placement[is.na(mismatch) | mismatch], collapse = ", ")
    )
  }
  invisible(checked)
}

verify_import_alignment_artifacts <- function(
  root = project_root(),
  saturation_threshold = 100000,
  expected_summary = NULL
) {
  if (
    length(saturation_threshold) != 1L ||
      !is.finite(saturation_threshold) ||
      !identical(as.numeric(saturation_threshold), 100000)
  ) {
    abort_pipeline(
      "Preparation 01 verification requires the fixed 100000-lx boundary"
    )
  }
  paths <- pipeline_paths(root)
  manifest_path <- file.path(
    paths$manifests,
    "import_alignment_artifacts.csv"
  )
  pinned_path <- file.path(paths$manifests, "pinned_downloads.csv")
  source_audit_path <- file.path(paths$aligned, "source_audit.csv")
  saturation_audit_path <- file.path(
    paths$aligned,
    "saturation_audit.csv"
  )
  required_paths <- c(
    manifest_path,
    pinned_path,
    source_audit_path,
    saturation_audit_path
  )
  if (!all(file.exists(required_paths))) {
    abort_pipeline(
      "Preparation 01 verification is missing required artifact(s): %s",
      paste(required_paths[!file.exists(required_paths)], collapse = ", ")
    )
  }

  manifest <- readr::read_csv(manifest_path, show_col_types = FALSE)
  pinned_downloads <- readr::read_csv(
    pinned_path,
    show_col_types = FALSE
  )
  source_audit <- readr::read_csv(
    source_audit_path,
    show_col_types = FALSE
  )
  saturation_audit <- readr::read_csv(
    saturation_audit_path,
    show_col_types = FALSE
  )
  manifest_check <- verify_manifest_files(
    manifest,
    object = "Preparation 01 artifact manifest"
  )
  verify_source_hash_propagation(source_audit, pinned_downloads)

  assert_columns(
    saturation_audit,
    c("site", "placement", "operating_limit_lux_mel_edi"),
    object = "saturation audit"
  )
  if (
    anyNA(saturation_audit$operating_limit_lux_mel_edi) ||
      any(
        saturation_audit$operating_limit_lux_mel_edi != saturation_threshold
      )
  ) {
    abort_pipeline(
      "Saturation audit does not uniformly record the %s-lx boundary",
      format(saturation_threshold, scientific = FALSE)
    )
  }

  summaries <- lapply(
    c("glasses", "chest"),
    function(placement) {
      path <- file.path(
        paths$aligned,
        paste0("light_", placement, "_aligned.rds")
      )
      aligned <- read_rds_artifact(path, expected_class = "data.frame")
      aligned_stream_verification_row(
        aligned,
        placement = placement,
        saturation_threshold = saturation_threshold
      )
    }
  )
  summary <- dplyr::bind_rows(summaries)
  verify_expected_import_summary(summary, expected_summary)

  audit_summary <- saturation_audit |>
    dplyr::group_by(.data$placement) |>
    dplyr::summarise(
      saturated_minutes = sum(.data$saturated_minutes),
      saturated_participants = sum(.data$affected_participants),
      saturated_participant_days = sum(
        .data$affected_participant_days
      ),
      .groups = "drop"
    )
  count_check <- dplyr::left_join(
    dplyr::transmute(
      summary,
      placement = .data$placement,
      saturated_minutes = .data$saturated_minutes
    ),
    dplyr::transmute(
      audit_summary,
      placement = .data$placement,
      audit_saturated_minutes = .data$saturated_minutes
    ),
    by = "placement",
    relationship = "one-to-one"
  )
  if (
    anyNA(count_check$audit_saturated_minutes) ||
      any(
        count_check$saturated_minutes != count_check$audit_saturated_minutes
      )
  ) {
    abort_pipeline(
      "Combined streams and saturation audit disagree on minute counts"
    )
  }

  list(
    status = "PASS",
    manifest = manifest_check,
    source_files = nrow(pinned_downloads),
    source_hashes_propagated = nrow(source_audit),
    summary = summary
  )
}
