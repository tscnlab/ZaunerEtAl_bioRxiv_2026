# One-time reconciliation from the former unopened text-connection digest to
# exact bytewise SHA-256 hashes. This script never downloads or changes a
# cached source file.

legacy_unopened_connection_sha256 <- function(path) {
  if (!file.exists(path)) {
    stop("Cannot hash missing cached source: ", path, call. = FALSE)
  }
  unname(unclass(as.character(openssl::sha256(file(path)))))
}

project_relative_path <- function(path, root) {
  root <- normalizePath(root, winslash = "/", mustWork = TRUE)
  path <- normalizePath(path, winslash = "/", mustWork = TRUE)
  prefix <- paste0(root, "/")
  if (any(!startsWith(path, prefix))) {
    stop(
      "Cannot record a path outside the project as project-relative",
      call. = FALSE
    )
  }
  substring(path, nchar(prefix) + 1L)
}

reconcile_pinned_download_hashes <- function(root = project_root()) {
  paths <- pipeline_paths(root)
  manifest_path <- file.path(paths$manifests, "pinned_downloads.csv")
  if (!file.exists(manifest_path)) {
    stop(
      "Pinned-download manifest does not exist: ",
      manifest_path,
      call. = FALSE
    )
  }

  previous <- readr::read_csv(manifest_path, show_col_types = FALSE)
  required <- c(
    "site",
    "modality",
    "repository",
    "commit",
    "doi",
    "source_url",
    "local_path",
    "sha256",
    "bytes",
    "cache_mtime_utc"
  )
  assert_columns(previous, required, object = "pinned download manifest")
  assert_unique_key(
    previous,
    c("site", "modality"),
    object = "pinned download manifest"
  )
  if (any(!file.exists(previous$local_path))) {
    stop(
      "Cannot reconcile a manifest with missing cached source files",
      call. = FALSE
    )
  }

  sources <- read_site_sources(file.path(root, "config", "site_sources.csv"))
  refreshed <- download_pinned_sources(
    sources = sources,
    cache_directory = file.path(paths$imported, "cache"),
    cache_policy = "reuse"
  )
  if (any(refreshed$downloaded)) {
    stop(
      "Hash reconciliation unexpectedly downloaded a cached source",
      call. = FALSE
    )
  }

  previous_ordered <- previous |>
    dplyr::arrange(.data$site, .data$modality)
  refreshed_ordered <- refreshed |>
    dplyr::arrange(.data$site, .data$modality)
  key_columns <- c("site", "modality")
  if (
    !identical(
      previous_ordered[key_columns],
      refreshed_ordered[key_columns]
    )
  ) {
    stop(
      "Pinned-source keys changed during hash reconciliation",
      call. = FALSE
    )
  }

  unchanged_fields <- c(
    "repository",
    "commit",
    "doi",
    "source_url",
    "local_path",
    "bytes",
    "cache_mtime_utc"
  )
  changed_metadata <- vapply(
    unchanged_fields,
    function(column) {
      !identical(
        as.character(previous_ordered[[column]]),
        as.character(refreshed_ordered[[column]])
      )
    },
    logical(1)
  )
  if (any(changed_metadata)) {
    stop(
      "Cached-source metadata changed during reconciliation: ",
      paste(names(changed_metadata)[changed_metadata], collapse = ", "),
      call. = FALSE
    )
  }

  legacy_sha256 <- vapply(
    refreshed_ordered$local_path,
    legacy_unopened_connection_sha256,
    character(1)
  )
  hash_state <- ifelse(
    previous_ordered$sha256 == legacy_sha256,
    "legacy_pseudo_hash",
    ifelse(
      previous_ordered$sha256 == refreshed_ordered$sha256,
      "bytewise_sha256",
      "unexplained"
    )
  )
  if (any(hash_state == "unexplained")) {
    stop(
      paste0(
        "At least one recorded source digest matches neither the former ",
        "nor bytewise hashing implementation; manual provenance review ",
        "is required"
      ),
      call. = FALSE
    )
  }

  expected_reconciliation <- dplyr::transmute(
    refreshed_ordered,
    .data$site,
    .data$modality,
    .data$repository,
    .data$commit,
    local_path = project_relative_path(.data$local_path, root),
    .data$bytes,
    .data$cache_mtime_utc,
    old_pseudo_sha256 = legacy_sha256,
    bytewise_sha256 = .data$sha256,
    old_digest_reproduced = TRUE,
    cached_bytes_unchanged = TRUE,
    downloaded = .data$downloaded,
    reconciliation_utc = format(Sys.time(), tz = "UTC", usetz = TRUE)
  )

  reconciliation_path <- file.path(
    root,
    "audit",
    "reconciliation",
    "pinned_download_hash_reconciliation.csv"
  )
  reconciliation_created <- !file.exists(reconciliation_path)
  if (reconciliation_created) {
    reconciliation <- expected_reconciliation
    write_csv_artifact(
      reconciliation,
      reconciliation_path,
      producer = "scripts/pipeline/reconcile_pinned_download_hashes.R",
      metadata = list(
        artifact_type = "pinned_download_hash_reconciliation",
        former_hash_method = "openssl_sha256_unopened_text_connection",
        current_hash_method = "sha256_exact_bytes_binary_connection"
      )
    )
  } else {
    reconciliation <- readr::read_csv(
      reconciliation_path,
      show_col_types = FALSE
    ) |>
      dplyr::arrange(.data$site, .data$modality)
    assert_columns(
      reconciliation,
      names(expected_reconciliation),
      object = "pinned-download hash reconciliation"
    )
    stable_fields <- setdiff(
      names(expected_reconciliation),
      "reconciliation_utc"
    )
    invalid_reconciliation <- vapply(
      stable_fields,
      function(column) {
        !identical(
          as.character(reconciliation[[column]]),
          as.character(expected_reconciliation[[column]])
        )
      },
      logical(1)
    )
    if (any(invalid_reconciliation)) {
      stop(
        "Existing hash reconciliation is inconsistent in: ",
        paste(
          names(invalid_reconciliation)[invalid_reconciliation],
          collapse = ", "
        ),
        call. = FALSE
      )
    }
  }

  manifest_hashes_updated <- sum(hash_state == "legacy_pseudo_hash")
  if (manifest_hashes_updated > 0L) {
    write_csv_artifact(
      refreshed,
      manifest_path,
      producer = "scripts/pipeline/reconcile_pinned_download_hashes.R",
      metadata = list(
        artifact_type = "pinned_download_manifest",
        cache_policy = "reuse",
        downloaded_sources = 0L
      )
    )
  }

  verified <- readr::read_csv(manifest_path, show_col_types = FALSE) |>
    dplyr::arrange(.data$site, .data$modality)
  if (
    !identical(
      unname(verified$sha256),
      unname(refreshed_ordered$sha256)
    )
  ) {
    stop(
      "Written pinned-download manifest failed byte-hash verification",
      call. = FALSE
    )
  }

  baseline_path <- file.path(
    root,
    "audit",
    "baseline",
    "pinned_source_hashes.csv"
  )
  baseline_hashes_updated <- 0L
  if (file.exists(baseline_path)) {
    baseline <- readr::read_csv(baseline_path, show_col_types = FALSE)
    assert_columns(
      baseline,
      c(
        "site",
        "modality",
        "repository",
        "commit",
        "source_url",
        "sha256",
        "bytes",
        "cache_mtime_utc"
      ),
      object = "baseline pinned-source hashes"
    )
    baseline_key <- paste(baseline$site, baseline$modality, sep = "\r")
    refreshed_key <- paste(
      refreshed_ordered$site,
      refreshed_ordered$modality,
      sep = "\r"
    )
    refreshed_index <- match(baseline_key, refreshed_key)
    if (
      anyNA(refreshed_index) ||
        length(refreshed_index) != nrow(refreshed_ordered)
    ) {
      stop(
        "Baseline pinned-source keys do not match the source manifest",
        call. = FALSE
      )
    }
    baseline_metadata_fields <- c(
      "repository",
      "commit",
      "source_url",
      "bytes",
      "cache_mtime_utc"
    )
    invalid_baseline_metadata <- vapply(
      baseline_metadata_fields,
      function(column) {
        !identical(
          as.character(baseline[[column]]),
          as.character(refreshed_ordered[[column]][refreshed_index])
        )
      },
      logical(1)
    )
    if (any(invalid_baseline_metadata)) {
      stop(
        "Baseline pinned-source metadata changed in: ",
        paste(
          names(invalid_baseline_metadata)[invalid_baseline_metadata],
          collapse = ", "
        ),
        call. = FALSE
      )
    }
    baseline_legacy <- legacy_sha256[refreshed_index]
    baseline_bytewise <- refreshed_ordered$sha256[refreshed_index]
    valid_baseline_hash <- baseline$sha256 == baseline_legacy |
      baseline$sha256 == baseline_bytewise
    if (any(!valid_baseline_hash)) {
      stop(
        "Baseline contains an unexplained pinned-source digest",
        call. = FALSE
      )
    }
    baseline_hashes_updated <- sum(baseline$sha256 == baseline_legacy)
    if (baseline_hashes_updated > 0L) {
      baseline$sha256 <- baseline_bytewise
      write_csv_artifact(
        baseline,
        baseline_path,
        producer = "scripts/pipeline/reconcile_pinned_download_hashes.R",
        metadata = list(
          artifact_type = "baseline_pinned_source_hashes",
          corrected_hash_method = "sha256_exact_bytes_binary_connection"
        )
      )
    }
  }

  list(
    manifest_path = manifest_path,
    reconciliation_path = reconciliation_path,
    sources_reconciled = nrow(reconciliation),
    sources_downloaded = sum(refreshed$downloaded),
    reconciliation_created = reconciliation_created,
    manifest_hashes_updated = manifest_hashes_updated,
    baseline_hashes_updated = baseline_hashes_updated
  )
}

if (sys.nframe() == 0L) {
  root_override <- Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = "")
  execution_root <- if (nzchar(root_override)) {
    normalizePath(root_override, winslash = "/", mustWork = TRUE)
  } else {
    normalizePath(getwd(), winslash = "/", mustWork = TRUE)
  }
  for (dependency in c(
    "paths_io.R",
    "assertions.R",
    "import_sources.R"
  )) {
    source(file.path(
      execution_root,
      "scripts",
      "pipeline",
      dependency
    ))
  }
  print(reconcile_pinned_download_hashes(execution_root))
}
