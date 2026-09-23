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
  artifact_root <- file.path(root, "results")
  list(
    root = root,
    artifacts = artifact_root,
    imported = file.path(artifact_root, "intermediate/imported"),
    aligned = file.path(artifact_root, "intermediate/aligned"),
    coverage = file.path(artifact_root, "intermediate/coverage"),
    profiles = file.path(artifact_root, "intermediate/reference_profiles"),
    metrics = file.path(artifact_root, "intermediate/metrics"),
    model_data = file.path(artifact_root, "intermediate/model_data"),
    models = file.path(artifact_root, "models"),
    diagnostics = file.path(artifact_root, "csv/diagnostics"),
    tables = file.path(artifact_root, "tables"),
    figures = file.path(artifact_root, "images"),
    source_data = file.path(artifact_root, "csv/source_data")
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
  saveRDS(object, temporary, version = 3, compress = TRUE)
  atomic_replace_artifact(temporary, path)

  invisible(list(path = path))
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
  invisible(list(path = path))
}

write_result_pair <- function(data, stem) {
  write_rds_artifact(data, paste0(stem, ".rds"), "quarto render")
  write_csv_artifact(data, paste0(stem, ".csv"), "quarto render")
  invisible(data)
}

read_downloaded_object <- function(path, object_name) {
  if (!file.exists(path)) stop("Downloaded input is missing: ", path, call. = FALSE)
  environment <- new.env(parent = emptyenv())
  loaded <- load(path, envir = environment)
  if (!identical(loaded, object_name)) {
    stop("Expected only object ", object_name, " in ", path, call. = FALSE)
  }
  object <- environment[[object_name]]
  if (!is.data.frame(object)) stop("Expected a data frame in ", path, call. = FALSE)
  dplyr::ungroup(object)
}

recording_source <- function(site_sources, site, modality, root = project_root()) {
  specification <- source_specification(site_sources, site, modality)
  path <- file.path(root, "data", "downloaded", "recordings", paste0(
    site, "_", modality, "_", substr(specification$commit, 1, 12), ".RData"
  ))
  list(data = read_downloaded_object(path, specification$object_name),
       specification = specification,
       downloaded_source = list(local_path = path, sha256 = artifact_sha256(path)))
}
