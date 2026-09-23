# Identify local downloaded recording releases.

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
