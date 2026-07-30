source("scripts/pipeline/paths_io.R")
source("scripts/pipeline/assertions.R")
source("scripts/pipeline/verify_import_alignment_artifacts.R")

local({
  message("Checking Preparation 01 post-build verification")

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

  write_raw_file <- function(path, payload) {
    dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
    connection <- file(path, open = "wb")
    on.exit(close(connection), add = TRUE)
    writeBin(payload, connection)
    invisible(path)
  }

  bytewise_sha256 <- function(path) {
    bytes <- unname(file.info(path)$size)
    connection <- file(path, open = "rb")
    on.exit(close(connection), add = TRUE)
    payload <- readBin(connection, what = "raw", n = bytes)
    unname(unclass(as.character(openssl::sha256(payload))))
  }

  make_aligned_stream <- function(
    placement,
    ids,
    local_dates,
    medi_raw,
    light_raw,
    invalid_nonwear
  ) {
    medi_saturated <- is.finite(medi_raw) & medi_raw >= 100000
    medi <- medi_raw
    medi[medi_saturated | invalid_nonwear] <- NA_real_
    light <- light_raw
    light[invalid_nonwear] <- NA_real_
    valid_medi <- is.finite(medi)
    valid_light <- is.finite(light)

    tibble::tibble(
      site = "TEST",
      Id = ids,
      position = placement,
      local_date = as.Date(local_dates),
      datetime_utc = as.POSIXct(
        "2024-01-01 00:00:00",
        tz = "UTC"
      ) +
        60 * (seq_along(ids) - 1L),
      MEDI = medi,
      LIGHT = light,
      MEDI_raw = medi_raw,
      LIGHT_raw = light_raw,
      invalid_nonwear = invalid_nonwear,
      medi_saturated = medi_saturated,
      valid_medi = valid_medi,
      valid_light = valid_light,
      valid_medi_light_pair = valid_medi & valid_light
    )
  }

  test_root <- tempfile("nathealth-import-verifier-")
  dir.create(test_root, recursive = TRUE)
  on.exit(unlink(test_root, recursive = TRUE), add = TRUE)
  paths <- pipeline_paths(test_root)
  ensure_pipeline_directories(paths)

  source_paths <- file.path(
    paths$imported,
    "cache",
    c("test_glasses.rds", "test_chest.rds")
  )
  write_raw_file(
    source_paths[[1L]],
    as.raw(c(0x00, 0x0d, 0x0a, 0x80, 0xff))
  )
  write_raw_file(
    source_paths[[2L]],
    as.raw(c(0xff, 0x7f, 0x41, 0x0a, 0x00))
  )
  source_sha256 <- vapply(
    source_paths,
    bytewise_sha256,
    character(1)
  )
  source_bytes <- unname(file.info(source_paths)$size)

  pinned_downloads <- tibble::tibble(
    site = c("TEST", "TEST"),
    modality = c("light_glasses", "light_chest"),
    local_path = normalizePath(
      source_paths,
      winslash = "/",
      mustWork = TRUE
    ),
    sha256 = source_sha256,
    bytes = source_bytes,
    downloaded = FALSE
  )
  source_audit <- tibble::tibble(
    site = pinned_downloads$site,
    modality = pinned_downloads$modality,
    source_sha256 = pinned_downloads$sha256,
    source_bytes = pinned_downloads$bytes
  )

  glasses <- make_aligned_stream(
    placement = "glasses",
    ids = c("P001", "P001", "P001", "P002"),
    local_dates = rep("2024-01-01", 4L),
    medi_raw = c(99999, 100000, 100001, 50),
    light_raw = c(10, 20, 30, 40),
    invalid_nonwear = c(FALSE, FALSE, FALSE, TRUE)
  )
  chest <- make_aligned_stream(
    placement = "chest",
    ids = c("P003", "P003", "P004"),
    local_dates = c("2024-01-01", "2024-01-01", "2024-01-02"),
    medi_raw = c(0, 100000, 99999.5),
    light_raw = c(1, 2, 3),
    invalid_nonwear = rep(FALSE, 3L)
  )

  glasses_path <- file.path(
    paths$aligned,
    "light_glasses_aligned.rds"
  )
  chest_path <- file.path(paths$aligned, "light_chest_aligned.rds")
  saveRDS(glasses, glasses_path, version = 3, compress = "xz")
  saveRDS(chest, chest_path, version = 3, compress = "xz")

  pinned_path <- file.path(paths$manifests, "pinned_downloads.csv")
  source_audit_path <- file.path(paths$aligned, "source_audit.csv")
  saturation_audit_path <- file.path(
    paths$aligned,
    "saturation_audit.csv"
  )
  manifest_path <- file.path(
    paths$manifests,
    "import_alignment_artifacts.csv"
  )
  saturation_audit <- tibble::tibble(
    site = c("TEST", "TEST"),
    placement = c("glasses", "chest"),
    operating_limit_lux_mel_edi = c(100000, 100000),
    saturated_minutes = c(2L, 1L),
    affected_participants = c(1L, 1L),
    affected_participant_days = c(1L, 1L)
  )
  readr::write_csv(pinned_downloads, pinned_path)
  readr::write_csv(source_audit, source_audit_path)
  readr::write_csv(saturation_audit, saturation_audit_path)

  artifact_paths <- c(
    glasses_path,
    chest_path,
    pinned_path,
    source_audit_path,
    saturation_audit_path
  )
  write_artifact_manifest <- function(
    sha256 = vapply(artifact_paths, bytewise_sha256, character(1))
  ) {
    manifest <- tibble::tibble(
      path = normalizePath(
        artifact_paths,
        winslash = "/",
        mustWork = TRUE
      ),
      sha256 = unname(sha256),
      bytes = unname(file.info(artifact_paths)$size)
    )
    readr::write_csv(manifest, manifest_path)
    invisible(manifest)
  }
  manifest <- write_artifact_manifest()

  expected_summary <- tibble::tibble(
    placement = c("glasses", "chest"),
    rows = c(4L, 3L),
    participants = c(2L, 2L),
    participant_days = c(2L, 2L),
    saturated_minutes = c(2L, 1L),
    saturated_participants = c(1L, 1L),
    saturated_participant_days = c(1L, 1L)
  )

  result <- verify_import_alignment_artifacts(
    root = test_root,
    expected_summary = expected_summary
  )
  stopifnot(
    identical(result$status, "PASS"),
    result$manifest$artifacts == length(artifact_paths),
    result$manifest$sha256_matches == length(artifact_paths),
    result$manifest$byte_counts_match == length(artifact_paths),
    result$source_files == nrow(pinned_downloads),
    result$source_hashes_propagated == nrow(source_audit),
    all(is.finite(glasses$LIGHT[glasses$medi_saturated])),
    all(is.na(glasses$MEDI[glasses$medi_saturated])),
    all(is.finite(chest$LIGHT[chest$medi_saturated])),
    all(is.na(chest$MEDI[chest$medi_saturated]))
  )

  bad_expected <- expected_summary
  bad_expected$rows[bad_expected$placement == "glasses"] <- 5L
  expect_pipeline_error(
    verify_import_alignment_artifacts(
      root = test_root,
      expected_summary = bad_expected
    ),
    "differs from its approved expectation"
  )

  corrupt_manifest_sha256 <- manifest$sha256
  corrupt_manifest_sha256[
    manifest$path ==
      normalizePath(
        chest_path,
        winslash = "/",
        mustWork = TRUE
      )
  ] <- strrep("0", 64L)
  write_artifact_manifest(corrupt_manifest_sha256)
  expect_pipeline_error(
    verify_import_alignment_artifacts(
      root = test_root,
      expected_summary = expected_summary
    ),
    "disagrees with file bytes"
  )
  write_artifact_manifest()

  glasses_boundary_error <- glasses
  boundary_row <- which(glasses_boundary_error$MEDI_raw == 100000)[[1L]]
  glasses_boundary_error$medi_saturated[boundary_row] <- FALSE
  saveRDS(
    glasses_boundary_error,
    glasses_path,
    version = 3,
    compress = "xz"
  )
  write_artifact_manifest()
  expect_pipeline_error(
    verify_import_alignment_artifacts(
      root = test_root,
      expected_summary = expected_summary
    ),
    "does not implement MEDI >= 100000 as invalid"
  )

  saveRDS(glasses, glasses_path, version = 3, compress = "xz")
  write_artifact_manifest()
  stopifnot(
    identical(
      verify_import_alignment_artifacts(
        root = test_root,
        expected_summary = expected_summary
      )$status,
      "PASS"
    )
  )

  message("Preparation 01 post-build verification checks passed")
})
