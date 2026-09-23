cs_file <- function(name) {
  root <- if (grepl("[.]rds$", name)) "results/models/brown-association" else if (grepl("^(diagnostic|likelihood|fit_check|optimizer|bounded_refit)", name)) "results/csv/diagnostics/brown-association" else "results/csv/source_data/brown-association"
  file.path(root, name)
}
cs_write <- function(x, name) {
  path <- cs_file(name)
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  data.table::fwrite(x, path, quote = TRUE, na = "")
  invisible(path)
}
cs_save <- function(x, name) {
  path <- cs_file(name)
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  saveRDS(x, path, compress = "gzip")
  invisible(path)
}
cs_save_fit <- function(x) {
  cs_save(x, paste0("model_", x$model_id, ".rds"))
  for (part in c("fit_check", "fixed_summary", "endpoint_range", "optimization_log"))
    cs_write(x[[part]], paste0(part, "_", x$model_id, ".csv"))
  invisible(x)
}
