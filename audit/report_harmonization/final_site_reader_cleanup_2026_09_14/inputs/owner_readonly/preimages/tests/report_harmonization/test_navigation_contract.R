#!/usr/bin/env Rscript

# Static navigation and corpus-manifest contract. No Quarto source is executed.

project_root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = "."),
  winslash = "/",
  mustWork = TRUE
)
builder <- file.path(
  project_root,
  "scripts",
  "report_harmonization",
  "build_phase4_corpus_manifest.R"
)

stopifnot(file.exists(builder))
source(builder, local = new.env(parent = globalenv()))

manifest_path <- file.path(
  project_root,
  "audit",
  "report_harmonization",
  "phase4_corpus_manifest.csv"
)
manifest <- read.csv(manifest_path, stringsAsFactors = FALSE, check.names = FALSE)

stopifnot(
  nrow(manifest) == 37L,
  !anyDuplicated(manifest$source),
  all(nzchar(manifest$source_sha256)),
  all(!is.na(manifest$render_position)),
  all(!is.na(manifest$sidebar_position))
)

cat(sprintf(
  "Navigation contract passed for %d accepted reader sources.\n",
  nrow(manifest)
))
