# File locations group scientific products by their type.
brown_file <- function(relative) {
  is_rds <- grepl("[.]rds$", relative, ignore.case = TRUE)
  root <- if (is_rds && grepl("^(frames|sensitivities/.+frames|placement/.+frames|calendar/.+frames)", relative)) {
    "results/intermediate/model_data/brown"
  } else if (is_rds) {
    "results/models/brown"
  } else if (grepl("^(diagnostics|likelihood)/", relative)) {
    "results/csv/diagnostics/brown"
  } else {
    "results/csv/source_data/brown"
  }
  file.path(root, relative)
}
lb_write_csv <- function(x, relative) {
  path <- brown_file(relative)
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  data.table::fwrite(as.data.frame(x), path, na = "", quote = TRUE)
  invisible(path)
}
lb_save_rds <- function(x, relative) {
  path <- brown_file(relative)
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  saveRDS(x, path)
  invisible(path)
}
brown_compile <- function(name) {
  input <- file.path("scripts/models/brown", paste0(name, ".cpp"))
  output <- "results/models/brown/compiled"
  dir.create(output, recursive = TRUE, showWarnings = FALSE)
  target <- file.path(output, basename(input))
  file.copy(input, target, overwrite = TRUE)
  TMB::compile(target, flags = "-O2 -std=gnu++17", safebounds = FALSE,
               safeunload = TRUE)
  dyn.load(TMB::dynlib(tools::file_path_sans_ext(target)))
  invisible(target)
}
brown_save_fit <- function(bundle) {
  id <- bundle$model_id
  lb_save_rds(bundle, paste0("models/", id, ".rds"))
  for (item in c("fit_diagnostics", "optimization_log", "fixed_summary",
                 "random_sd", "endpoint_summary")) {
    value <- bundle[[item]]
    if (is.data.frame(value)) lb_write_csv(value, paste0("models/", id, "_", item, ".csv"))
  }
  invisible(bundle)
}
