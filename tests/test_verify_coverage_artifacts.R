source("scripts/pipeline/paths_io.R")
source("scripts/pipeline/assertions.R")
source("scripts/pipeline/aggregation_coverage.R")
source("scripts/pipeline/build_coverage_sample_flow.R")
source("scripts/pipeline/verify_coverage_artifacts.R")

local({
  message("Checking independent Preparation 02 artifact verification")

  expect_pipeline_error <- function(code, pattern) {
    error <- tryCatch(
      {
        force(code)
        NULL
      },
      error = identity
    )
    stopifnot(
      inherits(error, "error"),
      grepl(pattern, conditionMessage(error), fixed = TRUE)
    )
    invisible(error)
  }

  backup_file <- function(path) {
    backup <- tempfile(paste0(basename(path), "-backup-"))
    stopifnot(file.copy(path, backup))
    backup
  }

  restore_file <- function(backup, path) {
    stopifnot(file.copy(backup, path, overwrite = TRUE))
    invisible(path)
  }

  refresh_manifest_artifact <- function(manifest, path) {
    normalized_path <- normalizePath(path, winslash = "/", mustWork = TRUE)
    row <- normalizePath(
      manifest$path,
      winslash = "/",
      mustWork = TRUE
    ) ==
      normalized_path
    stopifnot(sum(row) == 1L)
    manifest$sha256[row] <- artifact_sha256(path)
    manifest$bytes[row] <- unname(file.info(path)$size)
    manifest
  }

  make_aligned_day <- function(
    site,
    id,
    placement,
    date,
    medi,
    light,
    medi_raw,
    light_raw,
    invalid_nonwear,
    omit_clock_minute = integer(),
    fold_clock_minute = integer()
  ) {
    stopifnot(
      length(medi) == 1440L,
      length(light) == 1440L,
      length(medi_raw) == 1440L,
      length(light_raw) == 1440L,
      length(invalid_nonwear) == 1440L
    )
    clock_minute <- setdiff(0:1439, omit_clock_minute)
    index <- clock_minute + 1L
    datetime_wall <- as.POSIXct(date, tz = "UTC") +
      clock_minute * 60
    state <- ifelse(clock_minute < 480L, "sleep", "active")
    data <- tibble::tibble(
      site = site,
      Id = id,
      position = placement,
      datetime_utc = datetime_wall,
      datetime_wall = datetime_wall,
      local_date = as.Date(date),
      clock_minute = clock_minute,
      utc_offset_minutes = 0L,
      is_dst = FALSE,
      MEDI = medi[index],
      LIGHT = light[index],
      MEDI_raw = medi_raw[index],
      LIGHT_raw = light_raw[index],
      State.Brown = state,
      invalid_nonwear = invalid_nonwear[index],
      medi_saturated = is.finite(medi_raw[index]) &
        medi_raw[index] >= 100000
    )
    if (length(fold_clock_minute) > 0L) {
      duplicate <- data[
        data$clock_minute %in% fold_clock_minute,
        ,
        drop = FALSE
      ]
      duplicate$datetime_utc <- max(data$datetime_utc) +
        seq_len(nrow(duplicate)) * 60
      duplicate$utc_offset_minutes <- -60L
      duplicate$is_dst <- TRUE
      duplicate$MEDI <- duplicate$MEDI + 2
      duplicate$LIGHT <- duplicate$LIGHT + 4
      duplicate$MEDI_raw <- duplicate$MEDI
      duplicate$LIGHT_raw <- duplicate$LIGHT
      duplicate$medi_saturated <- FALSE
      data <- dplyr::bind_rows(data, duplicate) |>
        dplyr::arrange(.data$datetime_utc)
    }
    data$valid_medi <- is.finite(data$MEDI)
    data$valid_light <- is.finite(data$LIGHT)
    data$valid_medi_light_pair <-
      data$valid_medi & data$valid_light
    data
  }

  test_root <- tempfile("nathealth-coverage-verifier-")
  dir.create(test_root, recursive = TRUE)
  on.exit(unlink(test_root, recursive = TRUE), add = TRUE)
  paths <- pipeline_paths(test_root)
  ensure_pipeline_directories(paths)
  run_label <- "verify"
  aligned_root <- file.path(paths$aligned, "runs", run_label)
  dir.create(aligned_root, recursive = TRUE)

  medi_a <- rep(10, 1440L)
  light_a <- rep(20, 1440L)
  medi_raw_a <- medi_a
  light_raw_a <- light_a
  invalid_nonwear_a <- rep(FALSE, 1440L)
  medi_raw_a[6L] <- 100000
  medi_a[6L] <- NA_real_
  invalid_nonwear_a[7L] <- TRUE
  medi_a[7L] <- NA_real_
  light_a[7L] <- NA_real_
  medi_a[301L] <- NA_real_
  medi_raw_a[301L] <- NA_real_
  light_a[401L] <- NA_real_
  light_raw_a[401L] <- NA_real_
  medi_a[601:631] <- NA_real_
  medi_raw_a[601:631] <- NA_real_
  glasses_a <- make_aligned_day(
    site = "A",
    id = "P01",
    placement = "glasses",
    date = "2026-01-01",
    medi = medi_a,
    light = light_a,
    medi_raw = medi_raw_a,
    light_raw = light_raw_a,
    invalid_nonwear = invalid_nonwear_a,
    omit_clock_minute = 100L,
    fold_clock_minute = 120L
  )

  medi_b <- c(rep(10, 1100L), rep(NA_real_, 340L))
  light_b <- rep(20, 1440L)
  medi_raw_b <- medi_b
  light_raw_b <- light_b
  glasses_b <- make_aligned_day(
    site = "B",
    id = "P02",
    placement = "glasses",
    date = "2026-01-02",
    medi = medi_b,
    light = light_b,
    medi_raw = medi_raw_b,
    light_raw = light_raw_b,
    invalid_nonwear = rep(FALSE, 1440L)
  )
  glasses_input <- dplyr::bind_rows(glasses_a, glasses_b)

  medi_chest <- rep(12, 1440L)
  light_chest <- rep(24, 1440L)
  medi_raw_chest <- medi_chest
  light_raw_chest <- light_chest
  invalid_nonwear_chest <- rep(FALSE, 1440L)
  medi_raw_chest[11L] <- 100001
  medi_chest[11L] <- NA_real_
  invalid_nonwear_chest[12L] <- TRUE
  medi_chest[12L] <- NA_real_
  light_chest[12L] <- NA_real_
  chest_input <- make_aligned_day(
    site = "A",
    id = "P03",
    placement = "chest",
    date = "2026-01-01",
    medi = medi_chest,
    light = light_chest,
    medi_raw = medi_raw_chest,
    light_raw = light_raw_chest,
    invalid_nonwear = invalid_nonwear_chest
  )

  glasses_input_path <- file.path(
    aligned_root,
    "light_glasses_aligned.rds"
  )
  chest_input_path <- file.path(
    aligned_root,
    "light_chest_aligned.rds"
  )
  saveRDS(glasses_input, glasses_input_path, version = 3, compress = "xz")
  saveRDS(chest_input, chest_input_path, version = 3, compress = "xz")

  build <- build_coverage_sample_flow(
    root = test_root,
    run_label = run_label,
    placements = c("glasses", "chest")
  )
  manifest_path <- build$artifact_manifest_path

  result <- verify_coverage_artifacts(
    root = test_root,
    run_label = run_label
  )
  stopifnot(
    identical(result$status, "PASS"),
    result$manifest$artifacts == 10L,
    result$manifest$sha256_matches == 10L,
    result$manifest$byte_counts_match == 10L,
    all(result$summary$input_rows == result$summary$output_rows),
    result$summary$eligible_days[
      result$summary$placement == "glasses"
    ] ==
      1L,
    result$summary$ineligible_days[
      result$summary$placement == "glasses"
    ] ==
      1L,
    result$summary$saturated_minutes[
      result$summary$placement == "glasses"
    ] ==
      1L
  )

  glasses_hourly <- readr::read_csv(
    build$output_paths$glasses$hourly,
    show_col_types = FALSE
  )
  stopifnot(
    glasses_hourly$hour_valid_minutes[
      glasses_hourly$site == "A" &
        glasses_hourly$clock_hour == 3L
    ] ==
      60L
  )
  glasses_eligible <- readRDS(build$output_paths$glasses$eligible)
  boundary <- glasses_eligible[
    which(glasses_eligible$MEDI_raw == 100000),
    ,
    drop = FALSE
  ]
  stopifnot(
    nrow(boundary) == 1L,
    is.na(boundary$MEDI),
    is.finite(boundary$LIGHT),
    boundary$medi_saturated
  )
  rm(glasses_eligible)

  manifest_original <- readr::read_csv(
    manifest_path,
    show_col_types = FALSE
  )

  message("Checking corrupt artifact-hash rejection")
  manifest_backup <- backup_file(manifest_path)
  corrupt_manifest <- manifest_original
  corrupt_manifest$sha256[[1L]] <- strrep("0", 64L)
  readr::write_csv(corrupt_manifest, manifest_path)
  expect_pipeline_error(
    verify_coverage_artifacts(
      root = test_root,
      run_label = run_label
    ),
    "manifest disagrees with file bytes"
  )
  restore_file(manifest_backup, manifest_path)

  message("Checking exact Rule A metadata rejection")
  settings_backup <- backup_file(build$settings_path)
  manifest_backup <- backup_file(manifest_path)
  settings_bad <- readr::read_csv(
    build$settings_path,
    show_col_types = FALSE
  )
  settings_bad$minimum_day_coverage[
    settings_bad$placement == "glasses"
  ] <- 0.75
  readr::write_csv(settings_bad, build$settings_path)
  manifest_bad <- manifest_original
  manifest_bad <- refresh_manifest_artifact(
    manifest_bad,
    build$settings_path
  )
  readr::write_csv(manifest_bad, manifest_path)
  expect_pipeline_error(
    verify_coverage_artifacts(
      root = test_root,
      run_label = run_label
    ),
    "does not record `minimum_day_coverage` as 0.8"
  )
  restore_file(settings_backup, build$settings_path)
  restore_file(manifest_backup, manifest_path)

  message("Checking independent hourly-flag reconstruction")
  hourly_path <- build$output_paths$glasses$hourly
  hourly_backup <- backup_file(hourly_path)
  manifest_backup <- backup_file(manifest_path)
  hourly_bad <- readr::read_csv(hourly_path, show_col_types = FALSE)
  hourly_bad$hour_eligible[[1L]] <- !hourly_bad$hour_eligible[[1L]]
  readr::write_csv(hourly_bad, hourly_path)
  manifest_bad <- refresh_manifest_artifact(
    manifest_original,
    hourly_path
  )
  readr::write_csv(manifest_bad, manifest_path)
  expect_pipeline_error(
    verify_coverage_artifacts(
      root = test_root,
      run_label = run_label
    ),
    "hourly coverage disagrees with independent reconstruction"
  )
  restore_file(hourly_backup, hourly_path)
  restore_file(manifest_backup, manifest_path)

  message("Checking eligible-channel semantic rejection")
  eligible_path <- build$output_paths$glasses$eligible
  eligible_backup <- backup_file(eligible_path)
  manifest_backup <- backup_file(manifest_path)
  eligible_bad <- readRDS(eligible_path)
  valid_row <- which(is.finite(eligible_bad$LIGHT_eligible))[[1L]]
  eligible_bad$LIGHT_eligible[[valid_row]] <- NA_real_
  saveRDS(eligible_bad, eligible_path, version = 3, compress = "xz")
  manifest_bad <- refresh_manifest_artifact(
    manifest_original,
    eligible_path
  )
  readr::write_csv(manifest_bad, manifest_path)
  expect_pipeline_error(
    verify_coverage_artifacts(
      root = test_root,
      run_label = run_label
    ),
    "inconsistent eligible-channel `LIGHT_eligible`"
  )
  restore_file(eligible_backup, eligible_path)
  restore_file(manifest_backup, manifest_path)

  message("Checking sample-flow reconciliation")
  flow_backup <- backup_file(build$sample_flow_path)
  manifest_backup <- backup_file(manifest_path)
  flow_bad <- readr::read_csv(
    build$sample_flow_path,
    show_col_types = FALSE
  )
  flow_bad$true_utc_minutes[[1L]] <-
    flow_bad$true_utc_minutes[[1L]] + 1L
  readr::write_csv(flow_bad, build$sample_flow_path)
  manifest_bad <- refresh_manifest_artifact(
    manifest_original,
    build$sample_flow_path
  )
  readr::write_csv(manifest_bad, manifest_path)
  expect_pipeline_error(
    verify_coverage_artifacts(
      root = test_root,
      run_label = run_label
    ),
    "sample flow disagrees with independent reconstruction"
  )
  restore_file(flow_backup, build$sample_flow_path)
  restore_file(manifest_backup, manifest_path)

  message("Checking inherited 100000-lx boundary rejection")
  input_backup <- backup_file(glasses_input_path)
  settings_backup <- backup_file(build$settings_path)
  manifest_backup <- backup_file(manifest_path)
  aligned_bad <- readRDS(glasses_input_path)
  boundary_row <- which(aligned_bad$MEDI_raw == 100000)[[1L]]
  aligned_bad$medi_saturated[[boundary_row]] <- FALSE
  saveRDS(
    aligned_bad,
    glasses_input_path,
    version = 3,
    compress = "xz"
  )
  changed_input_sha256 <- artifact_sha256(glasses_input_path)
  settings_bad <- readr::read_csv(
    build$settings_path,
    show_col_types = FALSE
  )
  settings_bad$input_sha256[
    settings_bad$placement == "glasses"
  ] <- changed_input_sha256
  readr::write_csv(settings_bad, build$settings_path)
  manifest_bad <- manifest_original
  manifest_bad$input_sha256[
    !is.na(manifest_bad$placement) &
      manifest_bad$placement == "glasses"
  ] <- changed_input_sha256
  manifest_bad <- refresh_manifest_artifact(
    manifest_bad,
    build$settings_path
  )
  readr::write_csv(manifest_bad, manifest_path)
  expect_pipeline_error(
    verify_coverage_artifacts(
      root = test_root,
      run_label = run_label
    ),
    "does not implement MEDI >=100000"
  )
  restore_file(input_backup, glasses_input_path)
  restore_file(settings_backup, build$settings_path)
  restore_file(manifest_backup, manifest_path)

  stopifnot(
    identical(
      verify_coverage_artifacts(
        root = test_root,
        run_label = run_label
      )$status,
      "PASS"
    )
  )

  message("Independent Preparation 02 verification checks passed")
})
