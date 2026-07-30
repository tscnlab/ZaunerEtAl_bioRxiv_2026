source_catalog <- function() {
  tibble::tribble(
    ~modality,
    ~relative_path,
    ~object_name,
    ~availability_column,
    "light_glasses",
    "data/imported/light/light_glasses.RData",
    "light_glasses",
    "has_glasses",
    "light_chest",
    "data/imported/light/light_chest.RData",
    "light_chest",
    "has_chest",
    "sleepdiaries",
    "data/imported/continuous/sleepdiaries.RData",
    "sleepdiary",
    NA_character_,
    "wearlog",
    "data/imported/continuous/wearlog.RData",
    "wearlog",
    NA_character_
  )
}

read_site_sources <- function(path) {
  sources <- readr::read_csv(path, show_col_types = FALSE)
  required <- c(
    "site",
    "location",
    "repository",
    "commit",
    "doi",
    "timezone",
    "has_glasses",
    "has_chest"
  )
  assert_columns(sources, required, object = "site source manifest")
  assert_unique_key(sources, "site", object = "site source manifest")

  invalid_commit <- !grepl("^[0-9a-f]{40}$", sources$commit)
  if (any(invalid_commit)) {
    abort_pipeline(
      "Site source manifest has %d invalid 40-character Git commit(s)",
      sum(invalid_commit)
    )
  }
  invalid_doi <- !grepl("^10[.]5281/zenodo[.][0-9]+$", sources$doi)
  if (any(invalid_doi)) {
    abort_pipeline(
      "Site source manifest has invalid DOI(s): %s",
      paste(unique(sources$doi[invalid_doi]), collapse = ", ")
    )
  }
  invalid_timezone <- !sources$timezone %in% OlsonNames()
  if (any(invalid_timezone)) {
    abort_pipeline(
      "Site source manifest has invalid time zone(s): %s",
      paste(unique(sources$timezone[invalid_timezone]), collapse = ", ")
    )
  }
  sources
}

source_specification <- function(sources, site, modality) {
  catalog <- source_catalog()
  if (!modality %in% catalog$modality) {
    abort_pipeline(
      "Unknown modality '%s'; expected one of %s",
      modality,
      paste(catalog$modality, collapse = ", ")
    )
  }

  site_row <- sources[sources$site == site, , drop = FALSE]
  if (nrow(site_row) != 1L) {
    abort_pipeline(
      "Expected exactly one source-manifest row for site '%s'; found %d",
      site,
      nrow(site_row)
    )
  }
  modality_row <- catalog[catalog$modality == modality, , drop = FALSE]
  availability <- modality_row$availability_column
  if (
    !is.na(availability) &&
      (!availability %in% names(site_row) || !isTRUE(site_row[[availability]]))
  ) {
    abort_pipeline("Modality '%s' is unavailable for site '%s'", modality, site)
  }

  repository <- site_row$repository
  commit <- site_row$commit
  relative_path <- modality_row$relative_path
  tibble::tibble(
    site = site,
    location = site_row$location,
    repository = repository,
    commit = commit,
    doi = site_row$doi,
    timezone = site_row$timezone,
    modality = modality,
    object_name = modality_row$object_name,
    source_url = paste0(
      "https://raw.githubusercontent.com/MeLiDosProject/",
      repository,
      "/",
      commit,
      "/",
      relative_path
    )
  )
}

available_source_specifications <- function(sources) {
  assert_columns(
    sources,
    c("site", "has_glasses", "has_chest"),
    object = "site source manifest"
  )
  catalog <- source_catalog()
  specifications <- list()
  for (site_name in sources$site) {
    site_row <- sources[sources$site == site_name, , drop = FALSE]
    for (modality_name in catalog$modality) {
      modality_row <- catalog[catalog$modality == modality_name, , drop = FALSE]
      availability <- modality_row$availability_column
      available <- is.na(availability) ||
        isTRUE(site_row[[availability]])
      if (available) {
        key <- paste(site_name, modality_name, sep = "/")
        specifications[[key]] <- source_specification(
          sources = sources,
          site = site_name,
          modality = modality_name
        )
      }
    }
  }
  dplyr::bind_rows(specifications)
}

download_pinned_source <- function(
  specification,
  cache_directory,
  cache_policy = c("reuse", "refresh", "error")
) {
  cache_policy <- match.arg(cache_policy)
  assert_columns(
    specification,
    c("site", "commit", "modality", "source_url"),
    object = "source specification"
  )
  if (nrow(specification) != 1L) {
    abort_pipeline(
      "Source specification must have one row; found %d",
      nrow(specification)
    )
  }

  dir.create(cache_directory, recursive = TRUE, showWarnings = FALSE)
  destination <- file.path(
    cache_directory,
    paste0(
      specification$site,
      "_",
      specification$modality,
      "_",
      substr(specification$commit, 1L, 12L),
      ".RData"
    )
  )

  if (file.exists(destination) && cache_policy == "error") {
    abort_pipeline("Pinned source cache already exists: %s", destination)
  }
  should_download <- !file.exists(destination) || cache_policy == "refresh"
  if (should_download) {
    temporary <- tempfile(
      pattern = paste0(basename(destination), "."),
      tmpdir = cache_directory
    )
    on.exit(unlink(temporary), add = TRUE)
    status <- utils::download.file(
      url = specification$source_url,
      destfile = temporary,
      mode = "wb",
      quiet = TRUE
    )
    if (!identical(status, 0L) || !file.exists(temporary)) {
      abort_pipeline(
        "Failed to download pinned source for %s/%s",
        specification$site,
        specification$modality
      )
    }
    if (
      !file.copy(temporary, destination, overwrite = TRUE, copy.mode = TRUE)
    ) {
      abort_pipeline("Failed to cache pinned source: %s", destination)
    }
  }

  tibble::tibble(
    site = specification$site,
    modality = specification$modality,
    repository = specification$repository,
    commit = specification$commit,
    doi = specification$doi,
    source_url = specification$source_url,
    local_path = normalizePath(destination, winslash = "/", mustWork = TRUE),
    sha256 = artifact_sha256(destination),
    bytes = unname(file.info(destination)$size),
    cache_mtime_utc = format(
      file.info(destination)$mtime,
      tz = "UTC",
      usetz = TRUE
    ),
    verified_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
    downloaded = should_download
  )
}

download_pinned_sources <- function(
  sources,
  cache_directory,
  cache_policy = c("reuse", "refresh", "error")
) {
  cache_policy <- match.arg(cache_policy)
  specifications <- available_source_specifications(sources)
  rows <- lapply(seq_len(nrow(specifications)), function(row) {
    download_pinned_source(
      specification = specifications[row, , drop = FALSE],
      cache_directory = cache_directory,
      cache_policy = cache_policy
    )
  })
  manifest <- dplyr::bind_rows(rows)
  assert_unique_key(
    manifest,
    c("site", "modality"),
    object = "pinned download manifest"
  )
  manifest
}

downloaded_source_row <- function(download_manifest, site, modality) {
  assert_columns(
    download_manifest,
    c("site", "modality", "local_path", "sha256"),
    object = "pinned download manifest"
  )
  row <- download_manifest[
    download_manifest$site == site &
      download_manifest$modality == modality,
    ,
    drop = FALSE
  ]
  if (nrow(row) != 1L) {
    abort_pipeline(
      paste0(
        "Expected one downloaded source for site '%s' and modality '%s'; ",
        "found %d"
      ),
      site,
      modality,
      nrow(row)
    )
  }
  row
}

load_pinned_source <- function(specification, downloaded_source) {
  assert_columns(
    specification,
    c("site", "timezone", "modality", "object_name"),
    object = "source specification"
  )
  assert_columns(
    downloaded_source,
    c("site", "modality", "local_path", "sha256"),
    object = "downloaded source"
  )
  if (
    nrow(specification) != 1L ||
      nrow(downloaded_source) != 1L ||
      specification$site != downloaded_source$site ||
      specification$modality != downloaded_source$modality
  ) {
    abort_pipeline("Source specification and downloaded source do not match")
  }

  source_environment <- new.env(parent = emptyenv())
  loaded_names <- load(downloaded_source$local_path, envir = source_environment)
  expected_name <- specification$object_name
  if (!expected_name %in% loaded_names) {
    abort_pipeline(
      paste0(
        "Pinned source %s/%s did not contain object '%s'. ",
        "Loaded object(s): %s"
      ),
      specification$site,
      specification$modality,
      expected_name,
      paste(loaded_names, collapse = ", ")
    )
  }
  object <- source_environment[[expected_name]]
  if (!is.data.frame(object)) {
    abort_pipeline(
      "Pinned source object %s/%s is not a data frame",
      specification$site,
      specification$modality
    )
  }

  attr(object, "source_provenance") <- list(
    site = specification$site,
    modality = specification$modality,
    repository = specification$repository,
    commit = specification$commit,
    doi = specification$doi,
    source_url = specification$source_url,
    sha256 = downloaded_source$sha256,
    timezone = specification$timezone
  )
  object
}
