#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) == 1L, args[[1L]] %in% c("pre", "post"))
phase <- args[[1L]]

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
setwd(root)
source(file.path(root, "scripts/pipeline/paths_io.R"))
stopifnot(identical(as.character(getRversion()), "4.6.1"))

evidence_dir <- file.path(
  root,
  "audit/hypotheses/H02/report018_order39_companion_render"
)
dir.create(evidence_dir, recursive = TRUE, showWarnings = FALSE)

write_csv <- function(x, name) {
  utils::write.csv(
    x,
    file.path(evidence_dir, name),
    row.names = FALSE,
    na = "",
    fileEncoding = "UTF-8"
  )
}

hash_regular <- function(path) {
  if (!file_test("-f", path) || nzchar(Sys.readlink(path))) {
    return(NA_character_)
  }
  artifact_sha256(path)
}

relative_path <- function(path) {
  normalized <- normalizePath(path, winslash = "/", mustWork = TRUE)
  ifelse(
    startsWith(normalized, paste0(root, "/")),
    substring(normalized, nchar(root) + 2L),
    normalized
  )
}

dispatch <- utils::read.csv(
  "audit/report_harmonization/report018_h02_companion_order39_dispatch_manifest.csv",
  check.names = FALSE,
  stringsAsFactors = FALSE
)
dispatch_abs <- ifelse(
  startsWith(dispatch$path, "/"),
  dispatch$path,
  file.path(root, dispatch$path)
)
dispatch$current_sha256 <- vapply(dispatch_abs, hash_regular, character(1))
dispatch$current_bytes <- as.numeric(file.info(dispatch_abs)$size)
dispatch$exact_at_collection <- dispatch$current_sha256 == dispatch$sha256 &
  dispatch$current_bytes == dispatch$bytes
write_csv(dispatch, paste0("dispatch_reconciliation_", phase, ".csv"))
if (phase == "pre") {
  stopifnot(
    nrow(dispatch) == 37L,
    !anyDuplicated(dispatch$path),
    all(dispatch$exact_at_collection)
  )
}

directory_files <- function(path) {
  if (!dir.exists(path)) {
    return(character())
  }
  list.files(
    path,
    recursive = TRUE,
    full.names = TRUE,
    all.files = TRUE,
    include.dirs = FALSE,
    no.. = TRUE
  )
}

protected_files <- unique(c(
  file.path(root, c(
    "notebooks/hypotheses/H02.qmd",
    "audit/hypotheses/H02/H02_analysis_preparation.qmd",
    "audit/handoffs/H02_worker_handoff.md",
    "audit/handoffs/H02_shared_change_request.md",
    "_quarto-nathealth.yml",
    "_quarto.yml",
    "renv.lock",
    "config/site_display_registry.csv",
    "supplementary_information.qmd",
    "_build/nathealth/supplementary_information.html",
    "_build/nathealth/notebooks/hypotheses/H02.html"
  )),
  directory_files(file.path(root, "scripts/hypotheses/H02")),
  directory_files(file.path(root, "tests/hypotheses/H02")),
  directory_files(file.path(root, "artifacts/06_model_data/H02")),
  directory_files(file.path(root, "artifacts/07_models/H02")),
  directory_files(file.path(root, "artifacts/08_diagnostics/H02")),
  directory_files(file.path(root, "artifacts/09_tables/H02")),
  directory_files(file.path(root, "artifacts/10_figures/H02")),
  directory_files(file.path(root, "artifacts/11_source_data/H02")),
  directory_files(file.path(root, "artifacts/12_manifests/H02")),
  directory_files(file.path(root, "audit/ledgers")),
  directory_files(file.path(root, "manuscript/R0_NatMed"))
))
protected_files <- protected_files[file.exists(protected_files)]
stopifnot(length(protected_files) > 0L, !anyDuplicated(protected_files))
protected_info <- file.info(protected_files)
protected <- data.frame(
  path = relative_path(protected_files),
  sha256 = vapply(protected_files, hash_regular, character(1)),
  bytes = as.numeric(protected_info$size),
  mode = sprintf("%04o", as.integer(protected_info$mode)),
  mtime_utc = format(
    protected_info$mtime,
    "%Y-%m-%d %H:%M:%OS6 UTC",
    tz = "UTC"
  ),
  stringsAsFactors = FALSE
)
protected <- protected[order(protected$path), , drop = FALSE]
row.names(protected) <- NULL
write_csv(protected, paste0("protected_inventory_", phase, ".csv"))

build_root <- normalizePath(
  file.path(root, "_build/nathealth"),
  winslash = "/",
  mustWork = TRUE
)
build_entries <- c(
  build_root,
  list.files(
    build_root,
    recursive = TRUE,
    full.names = TRUE,
    all.files = TRUE,
    include.dirs = TRUE,
    no.. = TRUE
  )
)
build_entries <- sort(unique(build_entries))
links <- Sys.readlink(build_entries)
is_link <- nzchar(links)
is_dir <- dir.exists(build_entries) & !is_link
is_file <- file.exists(build_entries) & !dir.exists(build_entries) & !is_link
build_info <- file.info(build_entries)
build_hash <- rep("", length(build_entries))
build_hash[is_file] <- vapply(
  build_entries[is_file],
  artifact_sha256,
  character(1)
)
link_resolved <- rep("", length(build_entries))
link_safe <- rep(NA, length(build_entries))
if (any(is_link)) {
  for (index in which(is_link)) {
    candidate <- if (startsWith(links[[index]], "/")) {
      links[[index]]
    } else {
      file.path(dirname(build_entries[[index]]), links[[index]])
    }
    resolved <- normalizePath(candidate, winslash = "/", mustWork = TRUE)
    link_resolved[[index]] <- resolved
    link_safe[[index]] <- identical(resolved, build_root) ||
      startsWith(resolved, paste0(build_root, "/"))
  }
}
build <- data.frame(
  path = ifelse(
    build_entries == build_root,
    "",
    substring(build_entries, nchar(build_root) + 2L)
  ),
  type = ifelse(is_link, "symlink", ifelse(is_dir, "directory", "file")),
  sha256 = build_hash,
  bytes = ifelse(is_file, as.numeric(build_info$size), NA_real_),
  mode = sprintf("%04o", as.integer(build_info$mode)),
  mtime_utc = format(
    build_info$mtime,
    "%Y-%m-%d %H:%M:%OS6 UTC",
    tz = "UTC"
  ),
  link_target = links,
  link_resolved = link_resolved,
  link_safe = link_safe,
  stringsAsFactors = FALSE
)
build <- build[order(build$path), , drop = FALSE]
row.names(build) <- NULL
write_csv(build, paste0("build_inventory_", phase, ".csv"))
write_csv(
  build[build$type == "symlink", , drop = FALSE],
  paste0("build_symlinks_", phase, ".csv")
)
stopifnot(!any(build$type == "symlink" & !build$link_safe, na.rm = TRUE))

versions <- data.frame(
  component = c("R", "Quarto"),
  version = c(
    as.character(getRversion()),
    paste(system2("quarto", "--version", stdout = TRUE), collapse = " ")
  ),
  stringsAsFactors = FALSE
)
write_csv(versions, paste0("versions_", phase, ".csv"))

cat(sprintf(
  "ORDER39_INVENTORY=PASS phase=%s dispatch=%d/%d protected=%d build=%d files=%d directories=%d symlinks=%d\n",
  phase,
  sum(dispatch$exact_at_collection),
  nrow(dispatch),
  nrow(protected),
  nrow(build),
  sum(build$type == "file"),
  sum(build$type == "directory"),
  sum(build$type == "symlink")
))
