# Immutable source specifications and cache handling for Preparation 05.

model_input_source_catalog <- function() {
  tibble::tribble(
    ~modality,
    ~relative_source_path,
    ~object_name,
    ~reuse_preparation01,
    "demographics",
    "data/imported/demographics.RData",
    "demographics",
    FALSE,
    "chronotype",
    "data/imported/chronotype.RData",
    "chronotype",
    FALSE,
    "leba",
    "data/imported/leba.RData",
    "leba",
    FALSE,
    "vlsq8",
    "data/imported/vlsq8.RData",
    "vlsq8",
    FALSE,
    "exercisediary",
    "data/imported/continuous/exercisediary.RData",
    "exercisediary",
    FALSE,
    "lightexposurediary",
    "data/imported/continuous/lightexposurediary.RData",
    "lightexposurediary",
    FALSE,
    "sleepdiaries",
    "data/imported/continuous/sleepdiaries.RData",
    "sleepdiary",
    TRUE
  )
}

model_input_source_pin_columns <- function() {
  c(
    "site",
    "modality",
    "repository",
    "commit",
    "doi",
    "relative_source_path",
    "object_name",
    "expected_sha256",
    "expected_bytes",
    "reason_code"
  )
}

empty_model_input_source_pins <- function() {
  columns <- stats::setNames(
    rep(list(character()), length(model_input_source_pin_columns())),
    model_input_source_pin_columns()
  )
  columns$expected_bytes <- numeric()
  tibble::as_tibble(columns)
}

validate_model_input_source_pins <- function(
  pins,
  site_sources,
  availability,
  catalog = model_input_source_catalog()
) {
  required <- model_input_source_pin_columns()
  if (!identical(names(pins), required)) {
    abort_pipeline(
      "Model-input source-pin columns must be exactly: %s",
      paste(required, collapse = ", ")
    )
  }
  if (nrow(pins) == 0L) {
    return(pins)
  }
  assert_unique_key(
    pins,
    c("site", "modality"),
    object = "model-input source-pin manifest"
  )
  text_columns <- setdiff(required, "expected_bytes")
  invalid_text <- vapply(
    pins[text_columns],
    function(column) anyNA(column) || any(!nzchar(column)),
    logical(1)
  )
  if (
    any(invalid_text) ||
      anyNA(pins$expected_bytes) ||
      any(!is.finite(pins$expected_bytes)) ||
      any(pins$expected_bytes < 1) ||
      any(pins$expected_bytes != floor(pins$expected_bytes))
  ) {
    abort_pipeline(
      "Model-input source-pin manifest contains missing or invalid values"
    )
  }
  if (
    any(!grepl("^[0-9a-f]{40}$", pins$commit)) ||
      any(!grepl("^[0-9a-f]{64}$", pins$expected_sha256)) ||
      any(!grepl("^[a-z][a-z0-9_]*$", pins$reason_code)) ||
      any(grepl("^/", pins$relative_source_path)) ||
      any(grepl("(^|/)[.][.](/|$)", pins$relative_source_path))
  ) {
    abort_pipeline(
      "Model-input source-pin manifest has malformed provenance"
    )
  }

  site_rows <- match(pins$site, site_sources$site)
  modality_rows <- match(pins$modality, catalog$modality)
  if (anyNA(site_rows) || anyNA(modality_rows)) {
    abort_pipeline(
      "Model-input source-pin manifest has an unknown site or modality"
    )
  }
  availability_rows <- match(
    paste(pins$site, pins$modality, sep = "/"),
    paste(availability$site, availability$modality, sep = "/")
  )
  if (
    anyNA(availability_rows) ||
      any(availability$expected_status[availability_rows] != "present")
  ) {
    abort_pipeline(
      "Model-input source pins may target only declared-present inputs"
    )
  }
  if (any(catalog$reuse_preparation01[modality_rows])) {
    abort_pipeline(
      paste0(
        "Model-input source pins may not repin Preparation 01 reuse; ",
        "update that upstream stage instead"
      )
    )
  }
  source_matches <- pins$repository == site_sources$repository[site_rows] &
    pins$doi == site_sources$doi[site_rows] &
    pins$relative_source_path == catalog$relative_source_path[modality_rows] &
    pins$object_name == catalog$object_name[modality_rows]
  if (any(!source_matches)) {
    abort_pipeline(
      "Model-input source pin changes repository, DOI, path, or object identity"
    )
  }
  if (any(pins$commit == site_sources$commit[site_rows])) {
    abort_pipeline(
      "Model-input source pin must identify a distinct modality-specific commit"
    )
  }

  pins |>
    dplyr::mutate(
      site_order = match(.data$site, site_sources$site),
      modality_order = match(.data$modality, catalog$modality)
    ) |>
    dplyr::arrange(.data$site_order, .data$modality_order) |>
    dplyr::select(-dplyr::all_of(c("site_order", "modality_order")))
}

read_model_input_source_pins <- function(
  path,
  site_sources,
  availability,
  catalog = model_input_source_catalog()
) {
  if (!file.exists(path)) {
    abort_pipeline(
      "Model-input source-pin manifest does not exist: %s",
      path
    )
  }
  pins <- readr::read_csv(
    path,
    col_types = readr::cols(
      .default = readr::col_character(),
      expected_bytes = readr::col_double()
    ),
    show_col_types = FALSE,
    progress = FALSE,
    trim_ws = FALSE
  )
  validate_model_input_source_pins(
    pins = pins,
    site_sources = site_sources,
    availability = availability,
    catalog = catalog
  )
}

model_input_manifest_columns <- function() {
  c(
    "site",
    "modality",
    "expected_status",
    "observed_status",
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
    "expected_bytes",
    "cache_path",
    "sha256",
    "bytes",
    "cache_origin",
    "downloaded",
    "verified_utc"
  )
}

model_input_acquisition_paths <- function(root) {
  root <- normalizePath(root, winslash = "/", mustWork = TRUE)
  source_root <- file.path(
    root,
    "artifacts",
    "01_imported",
    "model_inputs"
  )
  list(
    root = root,
    source_root = source_root,
    cache = file.path(source_root, "cache"),
    object_audit = file.path(source_root, "object_audit.csv"),
    column_audit = file.path(source_root, "column_audit.csv"),
    manifest = file.path(
      root,
      "artifacts",
      "12_manifests",
      "model_input_acquisition.csv"
    )
  )
}

read_model_input_availability <- function(
  path,
  sites,
  catalog = model_input_source_catalog()
) {
  availability <- readr::read_csv(
    path,
    col_types = readr::cols(.default = readr::col_character()),
    show_col_types = FALSE,
    progress = FALSE
  )
  validate_model_input_availability(
    availability = availability,
    sites = sites,
    catalog = catalog
  )
}

validate_model_input_availability <- function(
  availability,
  sites,
  catalog = model_input_source_catalog()
) {
  required <- c(
    "site",
    "modality",
    "expected_status",
    "absence_reason_code"
  )
  assert_columns(
    availability,
    required,
    object = "model-input availability manifest"
  )
  if (!identical(names(availability), required)) {
    abort_pipeline(
      paste0(
        "Model-input availability manifest columns must be exactly: %s; ",
        "found: %s"
      ),
      paste(required, collapse = ", "),
      paste(names(availability), collapse = ", ")
    )
  }
  assert_unique_key(
    availability,
    c("site", "modality"),
    object = "model-input availability manifest"
  )

  unknown_sites <- setdiff(unique(availability$site), sites)
  unknown_modalities <- setdiff(
    unique(availability$modality),
    catalog$modality
  )
  if (length(unknown_sites) > 0L) {
    abort_pipeline(
      "Model-input availability manifest has unknown site(s): %s",
      paste(unknown_sites, collapse = ", ")
    )
  }
  if (length(unknown_modalities) > 0L) {
    abort_pipeline(
      "Model-input availability manifest has unknown modality/modalities: %s",
      paste(unknown_modalities, collapse = ", ")
    )
  }

  expected_keys <- dplyr::cross_join(
    tibble::tibble(site = sites),
    dplyr::select(catalog, dplyr::all_of("modality"))
  )
  observed_key <- paste(availability$site, availability$modality, sep = "/")
  expected_key <- paste(
    expected_keys$site,
    expected_keys$modality,
    sep = "/"
  )
  missing_keys <- setdiff(expected_key, observed_key)
  extra_keys <- setdiff(observed_key, expected_key)
  if (length(missing_keys) > 0L || length(extra_keys) > 0L) {
    abort_pipeline(
      paste0(
        "Model-input availability manifest must contain the complete ",
        "site-by-modality grid. Missing: %s. Extra: %s."
      ),
      if (length(missing_keys) == 0L) {
        "none"
      } else {
        paste(missing_keys, collapse = ", ")
      },
      if (length(extra_keys) == 0L) {
        "none"
      } else {
        paste(extra_keys, collapse = ", ")
      }
    )
  }

  allowed_status <- c("present", "absent_expected")
  invalid_status <- !availability$expected_status %in% allowed_status
  if (any(invalid_status)) {
    abort_pipeline(
      "Model-input availability manifest has invalid expected status(es): %s",
      paste(
        unique(availability$expected_status[invalid_status]),
        collapse = ", "
      )
    )
  }
  reason_present <- !is.na(availability$absence_reason_code) &
    nzchar(trimws(availability$absence_reason_code))
  invalid_present_reason <- availability$expected_status == "present" &
    reason_present
  invalid_absent_reason <- availability$expected_status == "absent_expected" &
    !reason_present
  if (any(invalid_present_reason)) {
    abort_pipeline(
      paste0(
        "Present model-input rows must not declare an absence reason: %s"
      ),
      paste(
        paste(
          availability$site[invalid_present_reason],
          availability$modality[invalid_present_reason],
          sep = "/"
        ),
        collapse = ", "
      )
    )
  }
  if (any(invalid_absent_reason)) {
    abort_pipeline(
      paste0(
        "Expected-absence model-input rows require a reason code: %s"
      ),
      paste(
        paste(
          availability$site[invalid_absent_reason],
          availability$modality[invalid_absent_reason],
          sep = "/"
        ),
        collapse = ", "
      )
    )
  }
  invalid_reason_code <- reason_present &
    !grepl("^[a-z][a-z0-9_]*$", availability$absence_reason_code)
  if (any(invalid_reason_code)) {
    abort_pipeline(
      "Model-input absence reason code(s) must use lower snake case: %s",
      paste(
        unique(availability$absence_reason_code[invalid_reason_code]),
        collapse = ", "
      )
    )
  }

  availability |>
    dplyr::mutate(
      site_order = match(.data$site, sites),
      modality_order = match(.data$modality, catalog$modality)
    ) |>
    dplyr::arrange(.data$site_order, .data$modality_order) |>
    dplyr::select(-dplyr::all_of(c("site_order", "modality_order")))
}

model_input_source_specifications <- function(
  site_sources,
  availability,
  source_pins = empty_model_input_source_pins(),
  catalog = model_input_source_catalog()
) {
  assert_columns(
    site_sources,
    c("site", "repository", "commit", "doi"),
    object = "site source manifest"
  )
  assert_unique_key(
    site_sources,
    "site",
    object = "site source manifest"
  )
  availability <- validate_model_input_availability(
    availability = availability,
    sites = site_sources$site,
    catalog = catalog
  )
  source_pins <- validate_model_input_source_pins(
    pins = source_pins,
    site_sources = site_sources,
    availability = availability,
    catalog = catalog
  )

  specifications <- dplyr::cross_join(
    dplyr::select(
      site_sources,
      dplyr::all_of(c("site", "repository", "commit", "doi"))
    ),
    catalog
  ) |>
    dplyr::left_join(
      availability,
      by = c("site", "modality"),
      relationship = "one-to-one"
    ) |>
    dplyr::left_join(
      source_pins |>
        dplyr::rename(
          pin_repository = "repository",
          pin_commit = "commit",
          pin_doi = "doi",
          pin_relative_source_path = "relative_source_path",
          pin_object_name = "object_name",
          source_pin_reason_code = "reason_code"
        ),
      by = c("site", "modality"),
      relationship = "one-to-one"
    ) |>
    dplyr::mutate(
      source_pin_applied = !is.na(.data$pin_commit),
      repository = dplyr::coalesce(
        .data$pin_repository,
        .data$repository
      ),
      commit = dplyr::coalesce(.data$pin_commit, .data$commit),
      doi = dplyr::coalesce(.data$pin_doi, .data$doi),
      relative_source_path = dplyr::coalesce(
        .data$pin_relative_source_path,
        .data$relative_source_path
      ),
      object_name = dplyr::coalesce(
        .data$pin_object_name,
        .data$object_name
      ),
      source_url = paste0(
        "https://raw.githubusercontent.com/MeLiDosProject/",
        .data$repository,
        "/",
        .data$commit,
        "/",
        .data$relative_source_path
      )
    )
  assert_unique_key(
    specifications,
    c("site", "modality"),
    object = "model-input source specifications"
  )

  invalid_commit <- !grepl("^[0-9a-f]{40}$", specifications$commit)
  commit_is_embedded <- vapply(
    seq_len(nrow(specifications)),
    function(row_index) {
      grepl(
        paste0("/", specifications$commit[row_index], "/"),
        specifications$source_url[row_index],
        fixed = TRUE
      )
    },
    logical(1)
  )
  invalid_url <- grepl("/main/", specifications$source_url, fixed = TRUE) |
    !grepl(
      paste0(
        "^https://raw[.]githubusercontent[.]com/",
        "MeLiDosProject/[^/]+/[0-9a-f]{40}/"
      ),
      specifications$source_url
    ) |
    !commit_is_embedded
  if (any(invalid_commit)) {
    abort_pipeline(
      "Model-input specifications have %d invalid commit(s)",
      sum(invalid_commit)
    )
  }
  if (any(invalid_url)) {
    abort_pipeline(
      "Model-input specifications have unpinned or malformed URL(s): %s",
      paste(
        paste(
          specifications$site[invalid_url],
          specifications$modality[invalid_url],
          sep = "/"
        ),
        collapse = ", "
      )
    )
  }
  pin_missing_provenance <- specifications$source_pin_applied &
    (is.na(specifications$source_pin_reason_code) |
      is.na(specifications$expected_sha256) |
      is.na(specifications$expected_bytes))
  unpinned_claims_expected_content <- !specifications$source_pin_applied &
    (!is.na(specifications$source_pin_reason_code) |
      !is.na(specifications$expected_sha256) |
      !is.na(specifications$expected_bytes))
  if (any(pin_missing_provenance | unpinned_claims_expected_content)) {
    abort_pipeline(
      "Model-input specifications have inconsistent source-pin provenance"
    )
  }

  specifications |>
    dplyr::select(dplyr::all_of(c(
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
      "expected_bytes",
      "reuse_preparation01"
    )))
}

model_input_project_relative_path <- function(path, root, must_work = TRUE) {
  root <- normalizePath(root, winslash = "/", mustWork = TRUE)
  absolute <- if (grepl("^/", path)) {
    path
  } else {
    file.path(root, path)
  }
  absolute <- normalizePath(
    absolute,
    winslash = "/",
    mustWork = must_work
  )
  root_prefix <- paste0(root, "/")
  if (!startsWith(absolute, root_prefix)) {
    abort_pipeline(
      "Model-input path is outside the project root: %s",
      absolute
    )
  }
  substring(absolute, nchar(root_prefix) + 1L)
}

model_input_absolute_path <- function(path, root, must_work = TRUE) {
  relative <- model_input_project_relative_path(
    path,
    root = root,
    must_work = must_work
  )
  file.path(normalizePath(root, winslash = "/", mustWork = TRUE), relative)
}

model_input_cache_path <- function(specification, root) {
  if (nrow(specification) != 1L) {
    abort_pipeline(
      "Model-input source specification must have one row; found %d",
      nrow(specification)
    )
  }
  paths <- model_input_acquisition_paths(root)
  file.path(
    paths$cache,
    paste0(
      specification$site,
      "_",
      specification$modality,
      "_",
      substr(specification$commit, 1L, 12L),
      ".RData"
    )
  )
}

inspect_model_input_object <- function(path, specification) {
  if (nrow(specification) != 1L) {
    abort_pipeline(
      "Model-input source specification must have one row; found %d",
      nrow(specification)
    )
  }
  if (!file.exists(path)) {
    abort_pipeline(
      "Required model-input source does not exist: %s",
      path
    )
  }

  source_environment <- new.env(parent = emptyenv())
  loaded_names <- load(path, envir = source_environment)
  expected_name <- specification$object_name
  if (
    length(loaded_names) != 1L ||
      !identical(loaded_names, expected_name)
  ) {
    abort_pipeline(
      paste0(
        "Model-input source %s/%s must contain exactly the sole object ",
        "'%s'; loaded object(s): %s"
      ),
      specification$site,
      specification$modality,
      expected_name,
      if (length(loaded_names) == 0L) {
        "none"
      } else {
        paste(loaded_names, collapse = ", ")
      }
    )
  }
  object <- source_environment[[expected_name]]
  if (!is.data.frame(object)) {
    abort_pipeline(
      "Model-input source object %s/%s is not a data frame",
      specification$site,
      specification$modality
    )
  }

  object_class <- paste(class(object), collapse = "|")
  object_audit <- tibble::tibble(
    site = specification$site,
    modality = specification$modality,
    object_name = expected_name,
    object_class = object_class,
    object_type = typeof(object),
    rows = nrow(object),
    columns = ncol(object)
  )
  column_audit <- tibble::tibble(
    site = specification$site,
    modality = specification$modality,
    column_order = seq_along(object),
    column_name = names(object),
    column_class = vapply(
      object,
      function(column) paste(class(column), collapse = "|"),
      character(1)
    ),
    column_type = vapply(object, typeof, character(1))
  )
  list(
    object_audit = object_audit,
    column_audit = column_audit
  )
}

validate_model_input_expected_content <- function(
  path,
  specification
) {
  if (nrow(specification) != 1L) {
    abort_pipeline(
      "Expected-content validation requires one source specification"
    )
  }
  if (!isTRUE(specification$source_pin_applied)) {
    return(invisible(path))
  }
  observed_sha256 <- artifact_sha256(path)
  observed_bytes <- unname(file.info(path)$size)
  if (
    !identical(observed_sha256, specification$expected_sha256) ||
      !isTRUE(observed_bytes == specification$expected_bytes)
  ) {
    abort_pipeline(
      paste0(
        "Pinned content for %s/%s does not match expected SHA-256 or bytes; ",
        "the modality-specific source pin has expired"
      ),
      specification$site,
      specification$modality
    )
  }
  invisible(path)
}

model_input_manifest_row <- function(
  specification,
  observed_status,
  cache_path = NA_character_,
  sha256 = NA_character_,
  bytes = NA_real_,
  cache_origin = NA_character_,
  downloaded = FALSE,
  verified_utc = format(Sys.time(), tz = "UTC", usetz = TRUE)
) {
  tibble::tibble(
    site = specification$site,
    modality = specification$modality,
    expected_status = specification$expected_status,
    observed_status = observed_status,
    absence_reason_code = specification$absence_reason_code,
    repository = specification$repository,
    commit = specification$commit,
    doi = specification$doi,
    relative_source_path = specification$relative_source_path,
    source_url = specification$source_url,
    object_name = specification$object_name,
    source_pin_applied = specification$source_pin_applied,
    source_pin_reason_code = specification$source_pin_reason_code,
    expected_sha256 = specification$expected_sha256,
    expected_bytes = specification$expected_bytes,
    cache_path = cache_path,
    sha256 = sha256,
    bytes = bytes,
    cache_origin = cache_origin,
    downloaded = downloaded,
    verified_utc = verified_utc
  )
}

validate_reusable_source_row <- function(
  specification,
  source_manifest,
  root,
  manifest_name,
  path_column
) {
  required <- c(
    "site",
    "modality",
    "repository",
    "commit",
    "doi",
    "source_url",
    path_column,
    "sha256",
    "bytes"
  )
  assert_columns(source_manifest, required, object = manifest_name)
  assert_unique_key(
    source_manifest,
    c("site", "modality"),
    object = manifest_name
  )
  row <- source_manifest[
    source_manifest$site == specification$site &
      source_manifest$modality == specification$modality,
    ,
    drop = FALSE
  ]
  if (nrow(row) != 1L) {
    abort_pipeline(
      "%s must contain one row for %s/%s; found %d",
      manifest_name,
      specification$site,
      specification$modality,
      nrow(row)
    )
  }

  exact_fields <- c("repository", "commit", "doi", "source_url")
  mismatch <- vapply(
    exact_fields,
    function(field)
      !identical(
        as.character(row[[field]]),
        as.character(specification[[field]])
      ),
    logical(1)
  )
  if (any(mismatch)) {
    abort_pipeline(
      "%s provenance does not match %s/%s for: %s",
      manifest_name,
      specification$site,
      specification$modality,
      paste(exact_fields[mismatch], collapse = ", ")
    )
  }
  absolute_path <- model_input_absolute_path(
    row[[path_column]],
    root = root,
    must_work = TRUE
  )
  current_sha256 <- artifact_sha256(absolute_path)
  current_bytes <- unname(file.info(absolute_path)$size)
  if (
    !identical(current_sha256, as.character(row$sha256)) ||
      !isTRUE(current_bytes == as.numeric(row$bytes))
  ) {
    abort_pipeline(
      "%s content hash or byte size differs for %s/%s",
      manifest_name,
      specification$site,
      specification$modality
    )
  }
  list(
    path = absolute_path,
    relative_path = model_input_project_relative_path(
      absolute_path,
      root = root
    ),
    sha256 = current_sha256,
    bytes = current_bytes
  )
}

reuse_preparation01_model_input <- function(
  specification,
  preparation01_manifest,
  root,
  verified_utc
) {
  if (
    !identical(specification$modality, "sleepdiaries") ||
      !isTRUE(specification$reuse_preparation01)
  ) {
    abort_pipeline(
      "Only the pinned Preparation 01 sleep diary may be reused here"
    )
  }
  reusable <- validate_reusable_source_row(
    specification = specification,
    source_manifest = preparation01_manifest,
    root = root,
    manifest_name = "Preparation 01 pinned-download manifest",
    path_column = "local_path"
  )
  inspect_model_input_object(reusable$path, specification)
  validate_model_input_expected_content(reusable$path, specification)
  model_input_manifest_row(
    specification = specification,
    observed_status = "present_reused",
    cache_path = reusable$relative_path,
    sha256 = reusable$sha256,
    bytes = reusable$bytes,
    cache_origin = "preparation01",
    downloaded = FALSE,
    verified_utc = verified_utc
  )
}

reuse_model_input_cache <- function(
  specification,
  previous_manifest,
  destination,
  root,
  verified_utc
) {
  if (is.null(previous_manifest)) {
    abort_pipeline(
      paste0(
        "Model-input cache exists without its acquisition manifest for ",
        "%s/%s. Use `cache_policy = \"refresh\"` only after resolving ",
        "the unverified cache provenance."
      ),
      specification$site,
      specification$modality
    )
  }
  reusable <- validate_reusable_source_row(
    specification = specification,
    source_manifest = previous_manifest,
    root = root,
    manifest_name = "existing model-input acquisition manifest",
    path_column = "cache_path"
  )
  expected_destination <- normalizePath(
    destination,
    winslash = "/",
    mustWork = TRUE
  )
  if (!identical(reusable$path, expected_destination)) {
    abort_pipeline(
      "Existing manifest cache path does not match %s/%s destination",
      specification$site,
      specification$modality
    )
  }
  inspect_model_input_object(reusable$path, specification)
  validate_model_input_expected_content(reusable$path, specification)
  model_input_manifest_row(
    specification = specification,
    observed_status = "present_reused",
    cache_path = reusable$relative_path,
    sha256 = reusable$sha256,
    bytes = reusable$bytes,
    cache_origin = "model_input_cache",
    downloaded = FALSE,
    verified_utc = verified_utc
  )
}

download_model_input_source <- function(
  specification,
  destination,
  root,
  download_function,
  verified_utc
) {
  dir.create(dirname(destination), recursive = TRUE, showWarnings = FALSE)
  temporary <- tempfile(
    pattern = paste0(basename(destination), "."),
    tmpdir = dirname(destination)
  )
  on.exit(unlink(temporary), add = TRUE)
  status <- download_function(
    url = specification$source_url,
    destfile = temporary,
    mode = "wb",
    quiet = TRUE
  )
  if (
    length(status) != 1L ||
      is.na(status) ||
      as.integer(status) != 0L ||
      !file.exists(temporary)
  ) {
    abort_pipeline(
      "Failed to download pinned model input for %s/%s",
      specification$site,
      specification$modality
    )
  }
  inspect_model_input_object(temporary, specification)
  validate_model_input_expected_content(temporary, specification)
  if (!file.copy(temporary, destination, overwrite = TRUE, copy.mode = TRUE)) {
    abort_pipeline(
      "Failed to cache pinned model input for %s/%s",
      specification$site,
      specification$modality
    )
  }
  current_sha256 <- artifact_sha256(destination)
  current_bytes <- unname(file.info(destination)$size)
  model_input_manifest_row(
    specification = specification,
    observed_status = "present_downloaded",
    cache_path = model_input_project_relative_path(destination, root = root),
    sha256 = current_sha256,
    bytes = current_bytes,
    cache_origin = "model_input_download",
    downloaded = TRUE,
    verified_utc = verified_utc
  )
}

resolve_model_input_source <- function(
  specification,
  root,
  preparation01_manifest,
  previous_manifest = NULL,
  cache_policy = c("reuse", "refresh"),
  download_function = utils::download.file,
  verified_utc = format(Sys.time(), tz = "UTC", usetz = TRUE)
) {
  cache_policy <- match.arg(cache_policy)
  if (nrow(specification) != 1L) {
    abort_pipeline(
      "Model-input source specification must have one row; found %d",
      nrow(specification)
    )
  }
  if (specification$expected_status == "absent_expected") {
    return(model_input_manifest_row(
      specification = specification,
      observed_status = "absent_expected",
      verified_utc = verified_utc
    ))
  }
  if (isTRUE(specification$reuse_preparation01)) {
    return(reuse_preparation01_model_input(
      specification = specification,
      preparation01_manifest = preparation01_manifest,
      root = root,
      verified_utc = verified_utc
    ))
  }

  destination <- model_input_cache_path(specification, root = root)
  if (file.exists(destination) && cache_policy == "reuse") {
    return(reuse_model_input_cache(
      specification = specification,
      previous_manifest = previous_manifest,
      destination = destination,
      root = root,
      verified_utc = verified_utc
    ))
  }
  download_model_input_source(
    specification = specification,
    destination = destination,
    root = root,
    download_function = download_function,
    verified_utc = verified_utc
  )
}
