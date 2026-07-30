project_root <- function(start = getwd()) {
  override <- Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = "")
  if (nzchar(override)) {
    root <- normalizePath(override, winslash = "/", mustWork = TRUE)
  } else {
    root <- normalizePath(start, winslash = "/", mustWork = TRUE)
    repeat {
      markers <- file.exists(file.path(root, c("_quarto.yml", "renv.lock")))
      if (all(markers)) {
        break
      }
      parent <- dirname(root)
      if (identical(parent, root)) {
        stop("Could not locate project root from ", start, call. = FALSE)
      }
      root <- parent
    }
  }
  root
}

pipeline_paths <- function(root = project_root()) {
  artifact_root <- file.path(root, "artifacts")
  list(
    root = root,
    artifacts = artifact_root,
    imported = file.path(artifact_root, "01_imported"),
    aligned = file.path(artifact_root, "02_aligned"),
    coverage = file.path(artifact_root, "03_coverage"),
    profiles = file.path(artifact_root, "04_reference_profiles"),
    metrics = file.path(artifact_root, "05_metrics"),
    model_data = file.path(artifact_root, "06_model_data"),
    models = file.path(artifact_root, "07_models"),
    diagnostics = file.path(artifact_root, "08_diagnostics"),
    tables = file.path(artifact_root, "09_tables"),
    figures = file.path(artifact_root, "10_figures"),
    source_data = file.path(artifact_root, "11_source_data"),
    manifests = file.path(artifact_root, "12_manifests")
  )
}

ensure_pipeline_directories <- function(paths = pipeline_paths()) {
  directories <- unname(unlist(
    paths[names(paths) != "root"],
    use.names = FALSE
  ))
  invisible(vapply(
    directories,
    dir.create,
    logical(1),
    recursive = TRUE,
    showWarnings = FALSE
  ))
}

artifact_sha256 <- function(path) {
  if (!file.exists(path)) {
    stop("Cannot hash missing artifact: ", path, call. = FALSE)
  }
  connection <- file(path, open = "rb")
  on.exit(close(connection), add = TRUE)
  unname(unclass(as.character(openssl::sha256(connection))))
}

atomic_replace_artifact <- function(temporary, path) {
  if (!file.exists(temporary)) {
    stop(
      "Cannot install missing temporary artifact: ",
      temporary,
      call. = FALSE
    )
  }
  if (!file.rename(temporary, path)) {
    stop(
      "Failed to atomically install artifact: ",
      path,
      call. = FALSE
    )
  }
  invisible(path)
}

write_rds_artifact <- function(object, path, producer, metadata = list()) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  temporary <- tempfile(
    pattern = paste0(basename(path), "."),
    tmpdir = dirname(path)
  )
  on.exit(unlink(temporary), add = TRUE)
  saveRDS(object, temporary, version = 3, compress = "xz")
  atomic_replace_artifact(temporary, path)

  info <- file.info(path)
  c(
    list(
      path = normalizePath(path, winslash = "/", mustWork = TRUE),
      sha256 = artifact_sha256(path),
      bytes = unname(info$size),
      producer = producer,
      r_version = as.character(getRversion()),
      written_utc = format(Sys.time(), tz = "UTC", usetz = TRUE)
    ),
    metadata
  )
}

read_rds_artifact <- function(path, expected_class = NULL) {
  if (!file.exists(path)) {
    stop("Required RDS artifact does not exist: ", path, call. = FALSE)
  }
  object <- readRDS(path)
  if (!is.null(expected_class) && !inherits(object, expected_class)) {
    stop(
      "Artifact ",
      path,
      " has class ",
      paste(class(object), collapse = "/"),
      "; expected ",
      expected_class,
      call. = FALSE
    )
  }
  object
}

write_csv_artifact <- function(data, path, producer, metadata = list()) {
  if (!is.data.frame(data)) {
    stop("CSV artifacts must be data frames", call. = FALSE)
  }
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  temporary <- tempfile(
    pattern = paste0(basename(path), "."),
    tmpdir = dirname(path)
  )
  on.exit(unlink(temporary), add = TRUE)
  readr::write_csv(data, temporary, na = "")
  atomic_replace_artifact(temporary, path)
  info <- file.info(path)
  c(
    list(
      path = normalizePath(path, winslash = "/", mustWork = TRUE),
      sha256 = artifact_sha256(path),
      bytes = unname(info$size),
      rows = nrow(data),
      columns = ncol(data),
      producer = producer,
      r_version = as.character(getRversion()),
      written_utc = format(Sys.time(), tz = "UTC", usetz = TRUE)
    ),
    metadata
  )
}

manifest_row <- function(metadata) {
  scalar <- vapply(metadata, length, integer(1)) == 1L
  as.data.frame(metadata[scalar], stringsAsFactors = FALSE, optional = TRUE)
}
