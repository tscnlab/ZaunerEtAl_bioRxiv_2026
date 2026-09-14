#!/usr/bin/env Rscript

stopifnot(identical(as.character(getRversion()), "4.6.1"))
root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
setwd(root)
source(file.path(root, "scripts/pipeline/paths_io.R"))
accepted_audit <- paste0(
  "audit/hypotheses/H01/report017_order32j_no_render_finalization/",
  "audit_order32j_stopped_html.R"
)
stopifnot(
  artifact_sha256(accepted_audit) ==
    "d13f1202f7a7ac349c1a6ff96dacfeec2285253823dd0eda74cb8b27c8bc3015",
  file.info(accepted_audit)$size == 15651
)
code <- readLines(accepted_audit, warn = FALSE, encoding = "UTF-8")
code <- gsub(
  "report017_order32j_no_render_finalization",
  "report017_order32k_companion_acceptance",
  code,
  fixed = TRUE
)
code <- gsub("order32j_stopped_", "order32k_", code, fixed = TRUE)
environment <- new.env(parent = globalenv())
eval(parse(text = code), envir = environment)
