#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE, warn = 2)
suppressPackageStartupMessages({
  library(openssl)
  library(readr)
})

stopifnot(identical(as.character(getRversion()), "4.6.1"))
arguments <- commandArgs(trailingOnly = TRUE)
stopifnot(length(arguments) == 1L, arguments[[1L]] %in% c("pre", "post"))
phase <- arguments[[1L]]

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
setwd(root)

evidence_rel <- paste0(
  "audit/report_harmonization/",
  "report018_final_corpus_integration"
)
evidence_dir <- file.path(root, evidence_rel)
dir.create(evidence_dir, recursive = TRUE, showWarnings = FALSE)
evidence_dir <- normalizePath(evidence_dir, winslash = "/", mustWork = TRUE)

sha256_file <- function(path) {
  connection <- file(path, open = "rb")
  on.exit(close(connection), add = TRUE)
  paste0(openssl::sha256(connection))
}

relative_path <- function(path) {
  normalized <- normalizePath(path, winslash = "/", mustWork = FALSE)
  stopifnot(startsWith(normalized, paste0(root, "/")))
  substring(normalized, nchar(root) + 2L)
}

inventory_build <- function() {
  build_root <- normalizePath(
    file.path(root, "_build/nathealth"),
    winslash = "/",
    mustWork = TRUE
  )
  members <- sort(list.files(
    build_root,
    recursive = TRUE,
    full.names = TRUE,
    all.files = TRUE,
    include.dirs = TRUE,
    no.. = TRUE
  ))
  links <- Sys.readlink(members)
  stopifnot(!any(nzchar(links)))
  info <- file.info(members)
  is_file <- !is.na(info$isdir) & !info$isdir
  hashes <- rep(NA_character_, length(members))
  hashes[is_file] <- vapply(members[is_file], sha256_file, character(1))
  bytes <- rep(NA_real_, length(members))
  bytes[is_file] <- unname(as.numeric(info$size[is_file]))
  data.frame(
    path = substring(members, nchar(build_root) + 2L),
    type = ifelse(is_file, "file", "directory"),
    sha256 = hashes,
    bytes = bytes,
    mtime_utc = format(info$mtime, tz = "UTC", usetz = TRUE),
    link_target = links,
    stringsAsFactors = FALSE
  )
}

collect_protected_paths <- function() {
  roots <- c(
    "artifacts",
    "audit/analyses",
    "audit/decisions",
    "audit/handoffs",
    "audit/hypotheses",
    "audit/ledgers",
    "audit/preparation_reports",
    "audit/reconciliation",
    "audit/report_harmonization",
    "config",
    "notebooks",
    "scripts",
    "tests"
  )
  paths <- unlist(
    lapply(roots, function(directory) {
      if (!dir.exists(directory)) return(character())
      list.files(
        directory,
        recursive = TRUE,
        full.names = TRUE,
        all.files = TRUE,
        include.dirs = FALSE,
        no.. = TRUE
      )
    }),
    use.names = FALSE
  )
  root_files <- c(
    "_quarto-nathealth.yml",
    "_quarto.yml",
    "renv.lock",
    "bibliography.bib",
    "nature.csl",
    "styles.css",
    "index.qmd",
    "supplementary_information.qmd"
  )
  paths <- unique(c(paths, root_files[file.exists(root_files)]))
  paths <- paths[file.exists(paths) & !dir.exists(paths)]
  normalized <- normalizePath(paths, winslash = "/", mustWork = FALSE)
  paths <- paths[!startsWith(normalized, paste0(evidence_dir, "/"))]
  sort(paths)
}

inventory_protected <- function() {
  paths <- collect_protected_paths()
  stopifnot(length(paths) > 3000L, !anyDuplicated(paths))
  links <- Sys.readlink(paths)
  regular <- !nzchar(links)
  hashes <- rep(NA_character_, length(paths))
  hashes[regular] <- vapply(paths[regular], sha256_file, character(1))
  info <- file.info(paths)
  data.frame(
    path = vapply(paths, relative_path, character(1)),
    type = ifelse(regular, "file", "symlink"),
    sha256 = hashes,
    bytes = unname(as.numeric(info$size)),
    link_target = links,
    stringsAsFactors = FALSE
  )
}

if (phase == "pre") {
  corpus_path <- "audit/report_harmonization/phase4_corpus_manifest.csv"
  historical_path <- file.path(
    evidence_dir,
    "historical_phase4_corpus_manifest_pre.csv"
  )
  source_raw <- readBin(
    corpus_path,
    what = "raw",
    n = file.info(corpus_path)$size
  )
  if (file.exists(historical_path)) {
    stopifnot(sha256_file(historical_path) == sha256_file(corpus_path))
  } else {
    connection <- file(historical_path, open = "wb")
    writeBin(source_raw, connection)
    close(connection)
  }
  identity <- data.frame(
    path = corpus_path,
    copied_path = relative_path(historical_path),
    sha256 = sha256_file(corpus_path),
    copied_sha256 = sha256_file(historical_path),
    bytes = unname(as.numeric(file.info(corpus_path)$size)),
    copied_bytes = unname(as.numeric(file.info(historical_path)$size)),
    exact = sha256_file(corpus_path) == sha256_file(historical_path),
    stringsAsFactors = FALSE
  )
  readr::write_csv(
    identity,
    file.path(
      evidence_dir,
      "historical_phase4_corpus_manifest_pre_identity.csv"
    )
  )
  stopifnot(identity$exact)
}

build <- inventory_build()
protected <- inventory_protected()
readr::write_csv(
  build,
  file.path(evidence_dir, paste0("build_inventory_", phase, ".csv"))
)
readr::write_csv(
  protected,
  file.path(evidence_dir, paste0("protected_inventory_", phase, ".csv"))
)
summary <- data.frame(
  phase = phase,
  build_members = nrow(build),
  build_files = sum(build$type == "file"),
  build_directories = sum(build$type == "directory"),
  build_symlinks = sum(nzchar(build$link_target)),
  protected_members = nrow(protected),
  protected_symlinks = sum(protected$type == "symlink"),
  stringsAsFactors = FALSE
)
readr::write_csv(
  summary,
  file.path(evidence_dir, paste0("inventory_summary_", phase, ".csv"))
)
stopifnot(nrow(build) == 1180L, !any(nzchar(build$link_target)))

cat(sprintf(
  paste0(
    "REPORT018_FINAL_CORPUS_INVENTORY=%s build=%d files=%d ",
    "directories=%d symlinks=%d protected=%d R=%s\n"
  ),
  toupper(phase),
  nrow(build),
  sum(build$type == "file"),
  sum(build$type == "directory"),
  sum(nzchar(build$link_target)),
  nrow(protected),
  as.character(getRversion())
))
