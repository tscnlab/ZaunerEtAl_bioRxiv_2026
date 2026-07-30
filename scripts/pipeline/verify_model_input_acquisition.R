# Independently verify Preparation 05 immutable model-input acquisition.

verify_model_input_acquisition <- function(
  root = project_root(),
  site_sources_path = file.path(root, "config", "site_sources.csv"),
  availability_path = file.path(
    root,
    "config",
    "model_input_availability.csv"
  ),
  source_pins_path = file.path(
    root,
    "config",
    "model_input_source_pins.csv"
  ),
  preparation01_manifest_path = file.path(
    root,
    "artifacts",
    "12_manifests",
    "pinned_downloads.csv"
  ),
  manifest_path = model_input_acquisition_paths(root)$manifest,
  object_audit_path = model_input_acquisition_paths(root)$object_audit,
  column_audit_path = model_input_acquisition_paths(root)$column_audit
) {
  root <- normalizePath(root, winslash = "/", mustWork = TRUE)
  required_paths <- c(
    source_pins_path,
    preparation01_manifest_path,
    manifest_path,
    object_audit_path,
    column_audit_path
  )
  missing_paths <- required_paths[!file.exists(required_paths)]
  if (length(missing_paths) > 0L) {
    abort_pipeline(
      "Model-input verification is missing required artifact(s): %s",
      paste(missing_paths, collapse = ", ")
    )
  }

  site_sources <- read_site_sources(site_sources_path)
  availability <- read_model_input_availability(
    availability_path,
    sites = site_sources$site
  )
  source_pins <- read_model_input_source_pins(
    path = source_pins_path,
    site_sources = site_sources,
    availability = availability
  )
  specifications <- model_input_source_specifications(
    site_sources = site_sources,
    availability = availability,
    source_pins = source_pins
  )
  preparation01_manifest <- readr::read_csv(
    preparation01_manifest_path,
    show_col_types = FALSE,
    progress = FALSE
  )
  manifest <- readr::read_csv(
    manifest_path,
    show_col_types = FALSE,
    progress = FALSE
  )
  if (!identical(names(manifest), model_input_manifest_columns())) {
    abort_pipeline(
      paste0(
        "Model-input acquisition manifest columns differ from the ",
        "declared contract"
      )
    )
  }
  assert_unique_key(
    manifest,
    c("site", "modality"),
    object = "model-input acquisition manifest"
  )
  expected_key <- paste(
    specifications$site,
    specifications$modality,
    sep = "/"
  )
  observed_key <- paste(manifest$site, manifest$modality, sep = "/")
  if (
    nrow(manifest) != nrow(specifications) ||
      !setequal(observed_key, expected_key)
  ) {
    abort_pipeline(
      paste0(
        "Model-input acquisition manifest does not contain the exact ",
        "declared site-by-modality rows"
      )
    )
  }
  manifest <- manifest[
    match(expected_key, observed_key),
    ,
    drop = FALSE
  ]

  specification_fields <- c(
    "site",
    "modality",
    "expected_status",
    "absence_reason_code",
    "repository",
    "commit",
    "doi",
    "relative_source_path",
    "source_url",
    "object_name",
    "source_pin_applied",
    "source_pin_reason_code",
    "expected_sha256",
    "expected_bytes"
  )
  mismatches <- vapply(
    specification_fields,
    function(field) {
      expected <- as.character(specifications[[field]])
      observed <- as.character(manifest[[field]])
      !identical(expected, observed)
    },
    logical(1)
  )
  if (any(mismatches)) {
    abort_pipeline(
      "Model-input manifest differs from source specifications for: %s",
      paste(specification_fields[mismatches], collapse = ", ")
    )
  }
  if (
    any(grepl("/main/", manifest$source_url, fixed = TRUE)) ||
      any(
        !grepl(
          "/[0-9a-f]{40}/",
          manifest$source_url
        )
      )
  ) {
    abort_pipeline(
      "Model-input manifest contains a moving or unpinned source URL"
    )
  }

  present <- manifest$expected_status == "present"
  absent <- !present
  valid_present_status <- manifest$observed_status %in%
    c("present_reused", "present_downloaded")
  if (any(present & !valid_present_status)) {
    abort_pipeline(
      "Present model-input row(s) have invalid observed status"
    )
  }
  present_downloaded <- present &
    manifest$observed_status == "present_downloaded"
  present_reused <- present &
    manifest$observed_status == "present_reused"
  inconsistent_download <- present_downloaded &
    (is.na(manifest$downloaded) |
      !manifest$downloaded |
      is.na(manifest$cache_origin) |
      manifest$cache_origin != "model_input_download")
  inconsistent_reuse <- present_reused &
    (is.na(manifest$downloaded) |
      manifest$downloaded |
      is.na(manifest$cache_origin) |
      !manifest$cache_origin %in%
        c("model_input_cache", "preparation01"))
  if (any(inconsistent_download | inconsistent_reuse)) {
    abort_pipeline(
      paste0(
        "Model-input observed status, cache origin, and downloaded flag ",
        "are inconsistent"
      )
    )
  }
  if (any(absent & manifest$observed_status != "absent_expected")) {
    abort_pipeline(
      "Expected-absence model-input row(s) have invalid observed status"
    )
  }
  absent_path_fields <- c("cache_path", "sha256", "cache_origin")
  absent_values <- unlist(
    lapply(
      manifest[absent, absent_path_fields, drop = FALSE],
      function(value) !is.na(value) & nzchar(as.character(value))
    ),
    use.names = FALSE
  )
  if (
    any(absent_values) ||
      any(!is.na(manifest$bytes[absent])) ||
      any(manifest$downloaded[absent])
  ) {
    abort_pipeline(
      "Expected-absence model-input rows must not claim cached content"
    )
  }
  if (
    any(is.na(manifest$cache_path[present])) ||
      any(grepl("^/", manifest$cache_path[present])) ||
      any(grepl("(^|/)[.][.](/|$)", manifest$cache_path[present]))
  ) {
    abort_pipeline(
      "Present model-input cache paths must be project-relative"
    )
  }

  sleep_rows <- specifications$reuse_preparation01
  present_sleep_rows <- sleep_rows & present
  if (
    any(
      manifest$observed_status[present_sleep_rows] != "present_reused" |
        manifest$cache_origin[present_sleep_rows] != "preparation01" |
        manifest$downloaded[present_sleep_rows]
    )
  ) {
    abort_pipeline(
      "Preparation 01 sleep diaries were not recorded as exact reuse"
    )
  }
  for (row_index in which(present_sleep_rows)) {
    reusable <- validate_reusable_source_row(
      specification = specifications[row_index, , drop = FALSE],
      source_manifest = preparation01_manifest,
      root = root,
      manifest_name = "Preparation 01 pinned-download manifest",
      path_column = "local_path"
    )
    if (
      !identical(
        reusable$relative_path,
        manifest$cache_path[row_index]
      ) ||
        !identical(reusable$sha256, manifest$sha256[row_index]) ||
        !isTRUE(reusable$bytes == manifest$bytes[row_index])
    ) {
      abort_pipeline(
        "Preparation 01 reuse differs from model-input manifest for %s/%s",
        manifest$site[row_index],
        manifest$modality[row_index]
      )
    }
  }

  inspections <- lapply(which(present), function(row_index) {
    source_path <- model_input_absolute_path(
      manifest$cache_path[row_index],
      root = root,
      must_work = TRUE
    )
    current_sha256 <- artifact_sha256(source_path)
    current_bytes <- unname(file.info(source_path)$size)
    if (
      !identical(current_sha256, manifest$sha256[row_index]) ||
        !isTRUE(current_bytes == manifest$bytes[row_index])
    ) {
      abort_pipeline(
        "Cached model-input content differs from manifest for %s/%s",
        manifest$site[row_index],
        manifest$modality[row_index]
      )
    }
    validate_model_input_expected_content(
      source_path,
      specifications[row_index, , drop = FALSE]
    )
    inspect_model_input_object(
      source_path,
      specifications[row_index, , drop = FALSE]
    )
  })
  reconstructed_object_audit <- if (length(inspections) == 0L) {
    tibble::tibble(
      site = character(),
      modality = character(),
      object_name = character(),
      object_class = character(),
      object_type = character(),
      rows = integer(),
      columns = integer()
    )
  } else {
    dplyr::bind_rows(lapply(inspections, `[[`, "object_audit"))
  }
  reconstructed_column_audit <- if (length(inspections) == 0L) {
    tibble::tibble(
      site = character(),
      modality = character(),
      column_order = integer(),
      column_name = character(),
      column_class = character(),
      column_type = character()
    )
  } else {
    dplyr::bind_rows(lapply(inspections, `[[`, "column_audit"))
  }

  object_audit <- readr::read_csv(
    object_audit_path,
    show_col_types = FALSE,
    progress = FALSE
  )
  column_audit <- readr::read_csv(
    column_audit_path,
    show_col_types = FALSE,
    progress = FALSE
  )
  object_columns <- names(reconstructed_object_audit)
  column_columns <- names(reconstructed_column_audit)
  if (
    !identical(names(object_audit), object_columns) ||
      !identical(names(column_audit), column_columns)
  ) {
    abort_pipeline(
      "Model-input object or column audit columns differ from contract"
    )
  }
  object_audit <- dplyr::arrange(
    object_audit,
    .data$site,
    .data$modality
  )
  reconstructed_object_audit <- dplyr::arrange(
    reconstructed_object_audit,
    .data$site,
    .data$modality
  )
  column_audit <- dplyr::arrange(
    column_audit,
    .data$site,
    .data$modality,
    .data$column_order
  )
  reconstructed_column_audit <- dplyr::arrange(
    reconstructed_column_audit,
    .data$site,
    .data$modality,
    .data$column_order
  )
  if (
    !isTRUE(all.equal(
      as.data.frame(object_audit),
      as.data.frame(reconstructed_object_audit),
      check.attributes = FALSE
    )) ||
      !isTRUE(all.equal(
        as.data.frame(column_audit),
        as.data.frame(reconstructed_column_audit),
        check.attributes = FALSE
      ))
  ) {
    abort_pipeline(
      "Model-input structural audit does not match cached objects"
    )
  }

  list(
    status = "PASS",
    expected_sources = nrow(specifications),
    present_sources = sum(present),
    expected_absences = sum(absent),
    preparation01_reused = sum(present_sleep_rows),
    source_pins = nrow(source_pins),
    source_pins_sha256 = artifact_sha256(source_pins_path),
    downloaded_in_manifest = sum(manifest$downloaded),
    manifest_sha256 = artifact_sha256(manifest_path),
    object_audit_sha256 = artifact_sha256(object_audit_path),
    column_audit_sha256 = artifact_sha256(column_audit_path)
  )
}
