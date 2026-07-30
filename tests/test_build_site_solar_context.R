options(warn = 2)

source("scripts/pipeline/paths_io.R")
source("scripts/pipeline/assertions.R")
source("scripts/pipeline/site_solar_context.R")
source("scripts/pipeline/build_site_solar_context.R")

message("Building canonical site/solar artifacts in an isolated output root")
test_root <- tempfile("nathealth-site-solar-build-")
dir.create(test_root, recursive = TRUE)
on.exit(unlink(test_root, recursive = TRUE), add = TRUE)

canonical_root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
metric_paths <- site_solar_default_metric_paths(canonical_root)
site_metadata_path <- file.path(
  canonical_root,
  "config",
  "site_metadata.csv"
)
first_build <- build_site_solar_context_artifacts(
  root = test_root,
  site_metadata_path = site_metadata_path,
  metric_paths = metric_paths,
  input_root = canonical_root
)
first_manifest_sha256 <- artifact_sha256(first_build$paths$manifest)
first_hashes <- vapply(
  c(
    first_build$paths$context_rds,
    first_build$paths$context_csv,
    first_build$paths$join_audit
  ),
  artifact_sha256,
  character(1)
)

stopifnot(
  nrow(first_build$context) == 616L,
  dplyr::n_distinct(first_build$context$site) == 9L,
  sum(first_build$context$local_day_crosses_dst) == 4L,
  all(first_build$context$solar_noon_role == "contextual_metadata_only"),
  identical(
    lubridate::tz(first_build$context$civil_dawn_utc),
    "UTC"
  ),
  identical(
    lubridate::tz(first_build$context$civil_dusk_utc),
    "UTC"
  ),
  identical(
    lubridate::tz(first_build$context$solar_noon_utc),
    "UTC"
  ),
  nrow(first_build$join_audit) == 6L,
  all(first_build$join_audit$relationship == "many-to-one"),
  all(first_build$join_audit$unmatched_rows == 0L),
  all(first_build$join_audit$status == "PASS"),
  nrow(first_build$manifest) == 3L,
  all(first_build$manifest$status == "PASS"),
  identical(
    names(first_build$manifest),
    site_solar_manifest_columns()
  ),
  !"written_utc" %in% names(first_build$manifest),
  all(!grepl("^/", first_build$manifest$path)),
  all(!grepl("^/", first_build$manifest$site_metadata_path)),
  all(!grepl("=[/]", first_build$manifest$input_paths)),
  all(file.exists(unlist(
    first_build$paths[names(first_build$paths) != "root"],
    use.names = FALSE
  )))
)

transition_keys <- paste(
  first_build$context$site[first_build$context$local_day_crosses_dst],
  first_build$context$local_date[
    first_build$context$local_day_crosses_dst
  ],
  sep = "|"
)
stopifnot(setequal(
  transition_keys,
  c(
    "FUSPCEU|2024-10-27",
    "MPI|2023-10-29",
    "RISE|2025-03-30",
    "THUAS|2025-03-30"
  )
))

message("Checking explicit UTC serialization in the durable CSV")
csv_text <- readr::read_csv(
  first_build$paths$context_csv,
  col_types = readr::cols(.default = readr::col_character()),
  show_col_types = FALSE,
  progress = FALSE
)
utc_columns <- c(
  "civil_dawn_utc",
  "civil_dusk_utc",
  "solar_noon_utc",
  "local_day_start_utc",
  "next_local_day_start_utc"
)
stopifnot(
  all(grepl("Z$", unlist(csv_text[utc_columns]), perl = TRUE)),
  all(
    grepl(
      "^[0-9]{4}-[0-9]{2}-[0-9]{2}$",
      csv_text$local_date
    )
  )
)

message("Checking byte-stable scientific artifacts on regeneration")
second_build <- build_site_solar_context_artifacts(
  root = test_root,
  site_metadata_path = site_metadata_path,
  metric_paths = metric_paths,
  input_root = canonical_root
)
second_hashes <- vapply(
  c(
    second_build$paths$context_rds,
    second_build$paths$context_csv,
    second_build$paths$join_audit
  ),
  artifact_sha256,
  character(1)
)
stopifnot(
  identical(first_hashes, second_hashes),
  identical(
    first_manifest_sha256,
    artifact_sha256(second_build$paths$manifest)
  ),
  identical(first_build$context, second_build$context),
  identical(first_build$join_audit, second_build$join_audit)
)

message("Checking rejection of an incomplete temporal metric grid")
invalid_metric_root <- file.path(test_root, "invalid-input")
dir.create(invalid_metric_root, recursive = TRUE)
invalid_30_minute <- readRDS(metric_paths[["glasses_30_minute"]])
invalid_30_minute <- invalid_30_minute[-1L, , drop = FALSE]
invalid_path <- file.path(
  invalid_metric_root,
  "metrics_glasses_30_minute.rds"
)
saveRDS(invalid_30_minute, invalid_path, version = 3, compress = "xz")
invalid_paths <- metric_paths
invalid_paths[["glasses_30_minute"]] <- invalid_path
invalid_output_root <- file.path(test_root, "invalid-output")
dir.create(invalid_output_root, recursive = TRUE)
invalid_grid_message <- NA_character_
invalid_grid_error <- tryCatch(
  {
    build_site_solar_context_artifacts(
      root = invalid_output_root,
      site_metadata_path = site_metadata_path,
      metric_paths = invalid_paths,
      input_root = canonical_root
    )
    FALSE
  },
  error = function(error) {
    invalid_grid_message <<- conditionMessage(error)
    TRUE
  }
)
stopifnot(
  invalid_grid_error,
  grepl("complete expected 30_minute clock grid", invalid_grid_message)
)

message("Site/solar artifact builder tests passed")
