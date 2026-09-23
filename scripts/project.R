# Configure shared analysis settings and save the data behind displayed tables.

analysis_setup <- function(params = NULL) {
  if (is.null(params)) {
    params <- get0("params", envir = parent.frame(), inherits = TRUE, ifnotfound = list())
  }
  if (!is.list(params)) stop("Analysis parameters must be a named list.", call. = FALSE)
  root <- Sys.getenv("QUARTO_PROJECT_DIR", unset = getwd())
  root <- normalizePath(root, winslash = "/", mustWork = TRUE)
  settings <- yaml::read_yaml(file.path(root, "config", "analysis.yml"))
  override <- params$bootstrap_replicates
  profiles <- strsplit(Sys.getenv("QUARTO_PROFILE"), ",", fixed = TRUE)[[1L]]
  if (is.null(override) && "quick" %in% profiles) {
    override <- settings$bootstrap$quick_replicates
  }
  if (!is.null(override)) {
    stopifnot(length(override) == 1L, is.finite(override),
              override >= 1, override == as.integer(override))
  }
  options(
    nh.root = root,
    nh.bootstrap_replicates = override,
    nh.workers = as.integer(settings$workers),
    stringsAsFactors = FALSE
  )
  Sys.setenv(TZ = "UTC", NATHEALTH_PROJECT_ROOT = root)
  # Keep table operations independent of parallel model workers.
  data.table::setDTthreads(1L)
  directories <- c(
    "results/images", "results/tables", "results/models",
    "results/csv/diagnostics", "results/csv/source_data",
    "results/intermediate/imported", "results/intermediate/aligned",
    "results/intermediate/coverage", "results/intermediate/reference_profiles",
    "results/intermediate/metrics", "results/intermediate/model_data"
  )
  for (directory in directories) {
    dir.create(file.path(root, directory), recursive = TRUE, showWarnings = FALSE)
  }
  register_table_exports()
  invisible(settings)
}

bootstrap_count <- function(default) {
  count <- getOption("nh.bootstrap_replicates", default)
  if (is.null(count)) count <- default
  if (length(count) != 1L || !is.finite(count) || count < 1 ||
      count != as.integer(count)) {
    stop("Bootstrap count must be a positive integer.", call. = FALSE)
  }
  as.integer(count)
}

analysis_workers <- function() {
  max(1L, getOption("nh.workers", 1L))
}

register_table_exports <- function() {
  if (isTRUE(getOption("nh.table_exports_registered"))) return(invisible(NULL))
  loadNamespace("gt")
  original <- utils::getS3method("knit_print", "gt_tbl", envir = asNamespace("knitr"))
  with_exports <- function(x, ...) {
    label <- knitr::opts_current$get("label")
    input <- knitr::current_input()
    if (!is.null(label) && nzchar(label) && nzchar(input)) {
      document <- tools::file_path_sans_ext(basename(input))
      directory <- file.path(getOption("nh.root"), "results", "tables", document)
      dir.create(directory, recursive = TRUE, showWarnings = FALSE)
      saveRDS(x, file.path(directory, paste0(label, ".rds")), version = 3)
      if (is.data.frame(x[["_data"]])) {
        readr::write_csv(x[["_data"]], file.path(directory, paste0(label, ".csv")))
      }
    }
    original(x, ...)
  }
  registerS3method("knit_print", "gt_tbl", with_exports, envir = asNamespace("knitr"))
  options(nh.table_exports_registered = TRUE)
  invisible(NULL)
}

# Validate from the execution directory before knitr makes the image URL
# relative to the document. Quarto then copies the image into the website.
include_project_graphics <- function(path, ...) {
  path <- normalizePath(path, winslash = "/", mustWork = TRUE)
  knitr::include_graphics(path, ..., error = FALSE)
}
