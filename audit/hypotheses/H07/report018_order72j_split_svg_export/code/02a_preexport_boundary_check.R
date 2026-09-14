#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE, warn = 2)

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
project_library <- file.path(
  root,
  "renv/library/macos/R-4.6/aarch64-apple-darwin23"
)
.libPaths(c(project_library, .libPaths()))
suppressPackageStartupMessages(library(digest))
stopifnot(identical(as.character(getRversion()), "4.6.1"))

owner_relative <-
  "audit/hypotheses/H07/report018_order72j_split_svg_export"
owner_root <- normalizePath(
  file.path(root, owner_relative),
  winslash = "/",
  mustWork = TRUE
)
implementation_path <- file.path(owner_root, "code", "02_export_attempt_01.R")
evidence_dir <- file.path(owner_root, "evidence")
attempt_path <- file.path(
  owner_root,
  "attempts/attempt_01/H07_revised_smooth_derivative_pairs_near_eye.svg"
)
candidate_path <- file.path(
  owner_root,
  "candidate/H07_revised_smooth_derivative_pairs_near_eye.svg"
)
stopifnot(
  file.exists(implementation_path),
  !file.exists(attempt_path),
  !file.exists(candidate_path),
  file.exists(file.path(evidence_dir, "execution_input_rehash_pre.csv")),
  file.exists(file.path(evidence_dir, "preservation_rehash_pre.csv"))
)

parsed <- parse(file = implementation_path, keep.source = TRUE)
stopifnot(length(parsed) > 0L)
implementation_text <- paste(readLines(implementation_path, warn = FALSE), collapse = "\n")

prohibited <- c(
  "source\\s*\\(",
  "readRDS\\s*\\(",
  "load\\s*\\(",
  "mgcv::",
  "gratia::",
  "\\bgam\\s*\\(",
  "\\bbam\\s*\\(",
  "predict\\s*\\(",
  "derivatives\\s*\\(",
  "p[.]adjust\\s*\\(",
  "simulate\\s*\\(",
  "boot\\s*\\(",
  "quarto",
  "pandoc",
  "rmarkdown",
  "file[.]remove\\s*\\(",
  "unlink\\s*\\(",
  "system2?\\s*\\(",
  "build_h07_stage2_paired_smooth_derivative_figures[.]R",
  "h07_stage2_core[.]R"
)
prohibited_hits <- vapply(
  prohibited,
  function(pattern) grepl(pattern, implementation_text, perl = TRUE),
  logical(1)
)
stopifnot(!any(prohibited_hits))

required_literals <- c(
  "artifacts/09_tables/H07/H07_main_curve_points.csv",
  "artifacts/09_tables/H07/H07_revised_derivative_points.csv",
  "artifacts/09_tables/H07/H07_revised_plateau_summary.csv",
  "artifacts/09_tables/H07/H07_revised_derivative_photoperiod_rows.csv",
  "artifacts/09_tables/H07/H07_revised_paired_figure_settings.csv",
  "artifacts/06_model_data/H05/H05_metric_registry.csv",
  "REVISED_CENTRAL_UNCONDITIONAL_POINTWISE",
  "Near-eye — primary",
  "nine rows; fitted value left and first derivative right",
  "unconditional pointwise 95% confidence interval",
  "svglite::svglite"
)
required_present <- vapply(
  required_literals,
  function(value) grepl(value, implementation_text, fixed = TRUE),
  logical(1)
)
stopifnot(all(required_present))

checks <- data.frame(
  check = c(
    "R parse",
    "attempt SVG absent before export",
    "candidate SVG absent before export",
    "preflight input rehash exists",
    "preflight preservation rehash exists",
    "broad source calls absent",
    "model and inferential readers absent",
    "model, prediction, derivative and simulation calls absent",
    "shell and destructive calls absent",
    "six frozen CSV path literals present",
    "accepted method, placement, arrangement and interval literals present",
    "native SVG device literal present",
    "implementation SHA-256"
  ),
  observed = c(
    "PASS",
    "absent",
    "absent",
    "present",
    "present",
    "0",
    "0",
    "0",
    "0",
    "6/6",
    "4/4",
    "present",
    digest::digest(
      implementation_path,
      algo = "sha256",
      file = TRUE,
      serialize = FALSE
    )
  ),
  expected = c(
    "PASS",
    "absent",
    "absent",
    "present",
    "present",
    "0",
    "0",
    "0",
    "0",
    "6/6",
    "4/4",
    "present",
    "recorded"
  ),
  status = "PASS",
  stringsAsFactors = FALSE
)

target <- file.path(evidence_dir, "implementation_boundary_preexport.csv")
stopifnot(startsWith(target, paste0(owner_root, "/")))
utils::write.csv(
  checks,
  target,
  row.names = FALSE,
  na = "",
  fileEncoding = "UTF-8"
)

cat(sprintf(
  "ORDER72J_H07_BOUNDARY=PASS checks=%d implementation_sha256=%s\n",
  nrow(checks),
  checks$observed[[nrow(checks)]]
))
