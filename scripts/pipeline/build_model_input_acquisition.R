# Acquire and structurally audit immutable Preparation 05 model inputs.

build_model_input_acquisition <- function(
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
  cache_policy = c("reuse", "refresh"),
  download_function = utils::download.file
) {
  cache_policy <- match.arg(cache_policy)
  root <- normalizePath(root, winslash = "/", mustWork = TRUE)
  paths <- model_input_acquisition_paths(root)
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

  if (!file.exists(preparation01_manifest_path)) {
    abort_pipeline(
      paste0(
        "Preparation 01 pinned-download manifest is required before ",
        "model-input acquisition: %s"
      ),
      preparation01_manifest_path
    )
  }
  preparation01_manifest <- readr::read_csv(
    preparation01_manifest_path,
    show_col_types = FALSE,
    progress = FALSE
  )
  previous_manifest <- if (file.exists(paths$manifest)) {
    readr::read_csv(
      paths$manifest,
      show_col_types = FALSE,
      progress = FALSE
    )
  } else {
    NULL
  }

  dir.create(paths$cache, recursive = TRUE, showWarnings = FALSE)
  dir.create(dirname(paths$manifest), recursive = TRUE, showWarnings = FALSE)
  verified_utc <- format(Sys.time(), tz = "UTC", usetz = TRUE)
  resolved_rows <- lapply(seq_len(nrow(specifications)), function(row_index) {
    resolve_model_input_source(
      specification = specifications[row_index, , drop = FALSE],
      root = root,
      preparation01_manifest = preparation01_manifest,
      previous_manifest = previous_manifest,
      cache_policy = cache_policy,
      download_function = download_function,
      verified_utc = verified_utc
    )
  })
  manifest <- dplyr::bind_rows(resolved_rows) |>
    dplyr::select(dplyr::all_of(model_input_manifest_columns()))
  assert_unique_key(
    manifest,
    c("site", "modality"),
    object = "model-input acquisition manifest"
  )

  present_rows <- which(manifest$observed_status != "absent_expected")
  inspections <- lapply(present_rows, function(row_index) {
    specification <- specifications[row_index, , drop = FALSE]
    source_path <- model_input_absolute_path(
      manifest$cache_path[row_index],
      root = root,
      must_work = TRUE
    )
    inspect_model_input_object(source_path, specification)
  })
  object_audit <- if (length(inspections) == 0L) {
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
  column_audit <- if (length(inspections) == 0L) {
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
  assert_unique_key(
    object_audit,
    c("site", "modality"),
    object = "model-input object audit"
  )
  assert_unique_key(
    column_audit,
    c("site", "modality", "column_order"),
    object = "model-input column audit"
  )

  object_metadata <- write_csv_artifact(
    object_audit,
    paths$object_audit,
    producer = "scripts/pipeline/build_model_input_acquisition.R"
  )
  column_metadata <- write_csv_artifact(
    column_audit,
    paths$column_audit,
    producer = "scripts/pipeline/build_model_input_acquisition.R"
  )
  manifest_metadata <- write_csv_artifact(
    manifest,
    paths$manifest,
    producer = "scripts/pipeline/build_model_input_acquisition.R"
  )

  list(
    source_pins = source_pins,
    specifications = specifications,
    manifest = manifest,
    object_audit = object_audit,
    column_audit = column_audit,
    paths = paths,
    artifact_metadata = list(
      manifest = manifest_metadata,
      object_audit = object_metadata,
      column_audit = column_metadata
    )
  )
}
