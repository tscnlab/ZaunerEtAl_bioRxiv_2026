source("scripts/pipeline/paths_io.R")
source("scripts/pipeline/assertions.R")
source("scripts/pipeline/import_sources.R")
source("scripts/pipeline/model_input_acquisition.R")
source("scripts/pipeline/build_model_input_acquisition.R")
source("scripts/pipeline/verify_model_input_acquisition.R")

expect_pipeline_error <- function(expression, pattern) {
  error <- tryCatch(
    {
      force(expression)
      NULL
    },
    error = identity
  )
  stopifnot(
    inherits(error, "error"),
    grepl(pattern, conditionMessage(error))
  )
  invisible(error)
}

write_synthetic_rdata <- function(path, object_name, value) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  source_environment <- new.env(parent = emptyenv())
  source_environment[[object_name]] <- value
  save(
    list = object_name,
    file = path,
    envir = source_environment,
    version = 3,
    compress = "xz"
  )
  invisible(path)
}

message("Checking the production source grids without network access")
production_site_sources <- read_site_sources("config/site_sources.csv")
production_availability <- read_model_input_availability(
  "config/model_input_availability.csv",
  sites = production_site_sources$site
)
production_source_pins <- read_model_input_source_pins(
  "config/model_input_source_pins.csv",
  site_sources = production_site_sources,
  availability = production_availability
)
production_specifications <- model_input_source_specifications(
  site_sources = production_site_sources,
  availability = production_availability,
  source_pins = production_source_pins
)
preparation01_specifications <- available_source_specifications(
  production_site_sources
)
stopifnot(
  nrow(production_site_sources) == 9L,
  nrow(preparation01_specifications) == 35L,
  identical(
    source_catalog()$modality,
    c("light_glasses", "light_chest", "sleepdiaries", "wearlog")
  ),
  nrow(production_specifications) == 63L,
  sum(production_specifications$modality == "sleepdiaries") == 9L,
  sum(production_specifications$modality != "sleepdiaries") == 54L,
  nrow(production_source_pins) == 1L,
  production_source_pins$site == "TUM",
  production_source_pins$modality == "exercisediary",
  production_source_pins$commit == "618fda8521f3cf581661ceb2c026e3de7cd9ba82",
  production_source_pins$expected_sha256 ==
    "0db56324e9826d427c42984fdfc43eb1e7487211365f222a1c0b2ecff618f1ef",
  production_source_pins$expected_bytes == 2662,
  sum(production_specifications$source_pin_applied) == 1L,
  production_specifications$commit[
    production_specifications$site == "TUM" &
      production_specifications$modality == "exercisediary"
  ] ==
    "618fda8521f3cf581661ceb2c026e3de7cd9ba82",
  all(
    production_specifications$commit[
      production_specifications$site == "TUM" &
        production_specifications$modality != "exercisediary"
    ] ==
      "eeafeea65ee0d2e0f3a5ab9f17b0f22b29e63e57"
  ),
  all(production_specifications$expected_status == "present"),
  !any(grepl(
    "/main/",
    production_specifications$source_url,
    fixed = TRUE
  )),
  all(vapply(
    seq_len(nrow(production_specifications)),
    function(row_index) {
      grepl(
        paste0(
          "/",
          production_specifications$commit[row_index],
          "/"
        ),
        production_specifications$source_url[row_index],
        fixed = TRUE
      )
    },
    logical(1)
  ))
)

message("Building an isolated synthetic immutable-input cache")
test_root <- tempfile("nathealth-model-input-acquisition-")
dir.create(test_root, recursive = TRUE)
on.exit(unlink(test_root, recursive = TRUE), add = TRUE)
dir.create(file.path(test_root, "config"), recursive = TRUE)

synthetic_site_sources <- tibble::tibble(
  site = c("A", "B"),
  location = c("Alpha", "Beta"),
  repository = c("AlphaDataset", "BetaDataset"),
  commit = c(
    paste(rep("a", 40L), collapse = ""),
    paste(rep("b", 40L), collapse = "")
  ),
  doi = c("10.5281/zenodo.1001", "10.5281/zenodo.1002"),
  timezone = c("UTC", "UTC"),
  has_glasses = TRUE,
  has_chest = TRUE
)
synthetic_site_sources_path <- file.path(
  test_root,
  "config",
  "site_sources.csv"
)
readr::write_csv(synthetic_site_sources, synthetic_site_sources_path)

synthetic_availability <- dplyr::cross_join(
  tibble::tibble(site = synthetic_site_sources$site),
  dplyr::select(
    model_input_source_catalog(),
    dplyr::all_of("modality")
  )
) |>
  dplyr::mutate(
    expected_status = "present",
    absence_reason_code = NA_character_
  )
synthetic_availability_path <- file.path(
  test_root,
  "config",
  "model_input_availability.csv"
)
readr::write_csv(
  synthetic_availability,
  synthetic_availability_path,
  na = ""
)

synthetic_base_specifications <- model_input_source_specifications(
  site_sources = synthetic_site_sources,
  availability = synthetic_availability
)
remote_root <- file.path(test_root, "synthetic_remote")
remote_paths <- character(nrow(synthetic_base_specifications))
for (row_index in seq_len(nrow(synthetic_base_specifications))) {
  specification <- synthetic_base_specifications[row_index, , drop = FALSE]
  remote_path <- file.path(
    remote_root,
    paste0(specification$site, "_", specification$modality, ".RData")
  )
  value <- tibble::tibble(
    Id = paste0(specification$site, "_P01"),
    value = row_index
  )
  write_synthetic_rdata(
    remote_path,
    object_name = specification$object_name,
    value = value
  )
  remote_paths[row_index] <- remote_path
}

synthetic_pin_row <- synthetic_base_specifications[
  synthetic_base_specifications$site == "A" &
    synthetic_base_specifications$modality == "exercisediary",
  ,
  drop = FALSE
]
synthetic_pin_remote_path <- remote_paths[
  synthetic_base_specifications$site == "A" &
    synthetic_base_specifications$modality == "exercisediary"
]
synthetic_source_pins <- tibble::tibble(
  site = synthetic_pin_row$site,
  modality = synthetic_pin_row$modality,
  repository = synthetic_pin_row$repository,
  commit = paste(rep("c", 40L), collapse = ""),
  doi = synthetic_pin_row$doi,
  relative_source_path = synthetic_pin_row$relative_source_path,
  object_name = synthetic_pin_row$object_name,
  expected_sha256 = artifact_sha256(synthetic_pin_remote_path),
  expected_bytes = unname(file.info(synthetic_pin_remote_path)$size),
  reason_code = "upstream_test_correction"
)
synthetic_source_pins_path <- file.path(
  test_root,
  "config",
  "model_input_source_pins.csv"
)
readr::write_csv(synthetic_source_pins, synthetic_source_pins_path)
synthetic_source_pins <- read_model_input_source_pins(
  synthetic_source_pins_path,
  site_sources = synthetic_site_sources,
  availability = synthetic_availability
)
synthetic_specifications <- model_input_source_specifications(
  site_sources = synthetic_site_sources,
  availability = synthetic_availability,
  source_pins = synthetic_source_pins
)
remote_by_url <- stats::setNames(
  remote_paths,
  synthetic_specifications$source_url
)
synthetic_downloader <- function(url, destfile, mode, quiet) {
  source <- unname(remote_by_url[url])
  if (length(source) != 1L || is.na(source) || !file.exists(source)) {
    return(1L)
  }
  copied <- file.copy(source, destfile, overwrite = TRUE)
  if (isTRUE(copied)) 0L else 1L
}

preparation01_cache <- file.path(
  test_root,
  "artifacts",
  "01_imported",
  "cache"
)
dir.create(preparation01_cache, recursive = TRUE)
sleep_specifications <- synthetic_specifications[
  synthetic_specifications$modality == "sleepdiaries",
  ,
  drop = FALSE
]
preparation01_rows <- lapply(
  seq_len(nrow(sleep_specifications)),
  function(row_index) {
    specification <- sleep_specifications[row_index, , drop = FALSE]
    source_path <- unname(remote_by_url[specification$source_url])
    cache_path <- file.path(
      preparation01_cache,
      paste0(
        specification$site,
        "_sleepdiaries_",
        substr(specification$commit, 1L, 12L),
        ".RData"
      )
    )
    stopifnot(file.copy(source_path, cache_path))
    tibble::tibble(
      site = specification$site,
      modality = specification$modality,
      repository = specification$repository,
      commit = specification$commit,
      doi = specification$doi,
      source_url = specification$source_url,
      local_path = normalizePath(
        cache_path,
        winslash = "/",
        mustWork = TRUE
      ),
      sha256 = artifact_sha256(cache_path),
      bytes = unname(file.info(cache_path)$size)
    )
  }
)
preparation01_manifest <- dplyr::bind_rows(preparation01_rows)
preparation01_manifest_path <- file.path(
  test_root,
  "artifacts",
  "12_manifests",
  "pinned_downloads.csv"
)
dir.create(dirname(preparation01_manifest_path), recursive = TRUE)
readr::write_csv(preparation01_manifest, preparation01_manifest_path)
preparation01_manifest_sha256 <- artifact_sha256(
  preparation01_manifest_path
)

first_build <- build_model_input_acquisition(
  root = test_root,
  site_sources_path = synthetic_site_sources_path,
  availability_path = synthetic_availability_path,
  preparation01_manifest_path = preparation01_manifest_path,
  cache_policy = "refresh",
  download_function = synthetic_downloader
)
stopifnot(
  sum(synthetic_specifications$source_pin_applied) == 1L,
  synthetic_specifications$commit[
    synthetic_specifications$site == "A" &
      synthetic_specifications$modality == "exercisediary"
  ] ==
    paste(rep("c", 40L), collapse = ""),
  nrow(first_build$manifest) == 14L,
  sum(first_build$manifest$observed_status == "present_downloaded") == 12L,
  sum(first_build$manifest$observed_status == "present_reused") == 2L,
  sum(first_build$manifest$cache_origin == "preparation01") == 2L,
  sum(first_build$manifest$downloaded) == 12L,
  !any(grepl("^/", first_build$manifest$cache_path)),
  nrow(first_build$object_audit) == 14L,
  nrow(first_build$column_audit) == 28L,
  artifact_sha256(preparation01_manifest_path) == preparation01_manifest_sha256
)

first_verification <- verify_model_input_acquisition(
  root = test_root,
  site_sources_path = synthetic_site_sources_path,
  availability_path = synthetic_availability_path,
  preparation01_manifest_path = preparation01_manifest_path
)
stopifnot(
  first_verification$status == "PASS",
  first_verification$expected_sources == 14L,
  first_verification$present_sources == 14L,
  first_verification$expected_absences == 0L,
  first_verification$preparation01_reused == 2L,
  first_verification$source_pins == 1L,
  first_build$manifest$sha256[
    first_build$manifest$site == "A" &
      first_build$manifest$modality == "exercisediary"
  ] ==
    synthetic_source_pins$expected_sha256
)

message("Checking source-pin expiry and duplicate-pin rejection")
pinned_cache_path <- model_input_absolute_path(
  first_build$manifest$cache_path[
    first_build$manifest$site == "A" &
      first_build$manifest$modality == "exercisediary"
  ],
  root = test_root
)
write_synthetic_rdata(
  synthetic_pin_remote_path,
  object_name = "exercisediary",
  value = tibble::tibble(Id = "A_P99", value = -1L)
)
expect_pipeline_error(
  build_model_input_acquisition(
    root = test_root,
    site_sources_path = synthetic_site_sources_path,
    availability_path = synthetic_availability_path,
    source_pins_path = synthetic_source_pins_path,
    preparation01_manifest_path = preparation01_manifest_path,
    cache_policy = "refresh",
    download_function = synthetic_downloader
  ),
  "source pin has expired"
)
stopifnot(
  file.copy(
    pinned_cache_path,
    synthetic_pin_remote_path,
    overwrite = TRUE
  )
)
duplicate_pins <- dplyr::bind_rows(
  synthetic_source_pins,
  synthetic_source_pins
)
expect_pipeline_error(
  validate_model_input_source_pins(
    pins = duplicate_pins,
    site_sources = synthetic_site_sources,
    availability = synthetic_availability
  ),
  "duplicated"
)

message("Checking manifest-validated reuse without network access")
network_forbidden <- function(url, destfile, mode, quiet) {
  stop("Synthetic network function must not be called", call. = FALSE)
}
second_build <- build_model_input_acquisition(
  root = test_root,
  site_sources_path = synthetic_site_sources_path,
  availability_path = synthetic_availability_path,
  preparation01_manifest_path = preparation01_manifest_path,
  cache_policy = "reuse",
  download_function = network_forbidden
)
stopifnot(
  all(second_build$manifest$observed_status == "present_reused"),
  !any(second_build$manifest$downloaded),
  sum(second_build$manifest$cache_origin == "preparation01") == 2L,
  sum(second_build$manifest$cache_origin == "model_input_cache") == 12L,
  artifact_sha256(preparation01_manifest_path) == preparation01_manifest_sha256,
  verify_model_input_acquisition(
    root = test_root,
    site_sources_path = synthetic_site_sources_path,
    availability_path = synthetic_availability_path,
    preparation01_manifest_path = preparation01_manifest_path
  )$status ==
    "PASS"
)

message("Checking independent cache-status provenance validation")
tampered_manifest <- second_build$manifest
tampered_row <- which(
  tampered_manifest$modality != "sleepdiaries"
)[1L]
tampered_manifest$observed_status[tampered_row] <- "present_downloaded"
readr::write_csv(
  tampered_manifest,
  second_build$paths$manifest,
  na = ""
)
expect_pipeline_error(
  verify_model_input_acquisition(
    root = test_root,
    site_sources_path = synthetic_site_sources_path,
    availability_path = synthetic_availability_path,
    preparation01_manifest_path = preparation01_manifest_path
  ),
  "status, cache origin, and downloaded flag"
)
readr::write_csv(
  second_build$manifest,
  second_build$paths$manifest,
  na = ""
)

message("Checking independent source-pin provenance validation")
tampered_pin_manifest <- second_build$manifest
tampered_pin_row <- which(tampered_pin_manifest$source_pin_applied)
tampered_pin_manifest$expected_sha256[tampered_pin_row] <-
  paste(rep("0", 64L), collapse = "")
readr::write_csv(
  tampered_pin_manifest,
  second_build$paths$manifest,
  na = ""
)
expect_pipeline_error(
  verify_model_input_acquisition(
    root = test_root,
    site_sources_path = synthetic_site_sources_path,
    availability_path = synthetic_availability_path,
    source_pins_path = synthetic_source_pins_path,
    preparation01_manifest_path = preparation01_manifest_path
  ),
  "expected_sha256"
)
readr::write_csv(
  second_build$manifest,
  second_build$paths$manifest,
  na = ""
)

message("Checking declared absence and exact sole-object rejection")
absence_manifest <- synthetic_availability
absence_manifest$expected_status[1L] <- "absent_expected"
absence_manifest$absence_reason_code[1L] <- "not_collected"
absence_path <- file.path(
  test_root,
  "config",
  "model_input_availability_absence.csv"
)
readr::write_csv(absence_manifest, absence_path, na = "")
absence <- read_model_input_availability(
  absence_path,
  sites = synthetic_site_sources$site
)
stopifnot(
  sum(absence$expected_status == "absent_expected") == 1L,
  absence$absence_reason_code[absence$expected_status == "absent_expected"] ==
    "not_collected"
)
absence_build <- build_model_input_acquisition(
  root = test_root,
  site_sources_path = synthetic_site_sources_path,
  availability_path = absence_path,
  preparation01_manifest_path = preparation01_manifest_path,
  cache_policy = "reuse",
  download_function = network_forbidden
)
absence_verification <- verify_model_input_acquisition(
  root = test_root,
  site_sources_path = synthetic_site_sources_path,
  availability_path = absence_path,
  preparation01_manifest_path = preparation01_manifest_path
)
stopifnot(
  sum(absence_build$manifest$observed_status == "absent_expected") == 1L,
  nrow(absence_build$object_audit) == 13L,
  nrow(absence_build$column_audit) == 26L,
  absence_verification$status == "PASS",
  absence_verification$present_sources == 13L,
  absence_verification$expected_absences == 1L,
  !absence_build$manifest$downloaded[
    absence_build$manifest$observed_status == "absent_expected"
  ]
)
missing_reason <- absence_manifest
missing_reason$absence_reason_code[1L] <- NA_character_
missing_reason_path <- file.path(
  test_root,
  "config",
  "model_input_availability_missing_reason.csv"
)
readr::write_csv(missing_reason, missing_reason_path, na = "")
expect_pipeline_error(
  read_model_input_availability(
    missing_reason_path,
    sites = synthetic_site_sources$site
  ),
  "require a reason code"
)

multiple_object_path <- file.path(test_root, "multiple_objects.RData")
multiple_environment <- new.env(parent = emptyenv())
multiple_environment$demographics <- tibble::tibble(Id = "A_P01")
multiple_environment$unexpected <- tibble::tibble(value = 1)
save(
  list = c("demographics", "unexpected"),
  file = multiple_object_path,
  envir = multiple_environment
)
demographics_specification <- synthetic_specifications[
  synthetic_specifications$site == "A" &
    synthetic_specifications$modality == "demographics",
  ,
  drop = FALSE
]
expect_pipeline_error(
  inspect_model_input_object(
    multiple_object_path,
    demographics_specification
  ),
  "exactly the sole object"
)

message("Checking hypothesis notebooks contain no acquisition calls")
hypothesis_paths <- list.files(
  "notebooks/hypotheses",
  pattern = "[.]qmd$",
  full.names = TRUE
)
hypothesis_text <- unlist(
  lapply(hypothesis_paths, readLines, warn = FALSE),
  use.names = FALSE
)
stopifnot(
  !any(grepl(
    paste0(
      "download[.]file|raw[.]githubusercontent|",
      "build_model_input_acquisition|melidosData::load_data"
    ),
    hypothesis_text
  ))
)

message("All immutable model-input acquisition tests passed")
