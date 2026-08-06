#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE, scipen = 999)

script_argument <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
if (length(script_argument) != 1L) {
  stop("Could not determine the H11 Stage 1 manifest script location", call. = FALSE)
}
script_path <- normalizePath(
  sub("^--file=", "", script_argument),
  winslash = "/",
  mustWork = TRUE
)
source(file.path(dirname(script_path), "h11_stage1.R"))
root <- h11_find_project_root(dirname(script_path))

stage1_csv <- list.files(
  file.path(root, "artifacts/06_model_data/H11"),
  pattern = "^stage1_.*[.]csv$",
  full.names = FALSE
)
relative_paths <- c(
  "audit/hypotheses/H11/01_audit_and_plan.qmd",
  "audit/hypotheses/H11/01_audit_and_plan.html",
  "audit/handoffs/H11_worker_handoff.md",
  "audit/handoffs/H11_shared_change_request.md",
  "scripts/hypotheses/H11/h11_stage1.R",
  "scripts/hypotheses/H11/build_h11_stage1_audit.R",
  "scripts/hypotheses/H11/build_h11_stage1_output_manifest.R",
  "tests/hypotheses/H11/test_h11_stage1_audit.R",
  file.path("artifacts/06_model_data/H11", sort(stage1_csv)),
  "artifacts/12_manifests/H11/H11_stage1_artifacts.csv"
)
paths <- file.path(root, relative_paths)
if (any(!file.exists(paths))) {
  stop(
    "Missing H11 Stage 1 outputs: ",
    paste(relative_paths[!file.exists(paths)], collapse = "; "),
    call. = FALSE
  )
}

artifact_class <- dplyr::case_when(
  grepl("[.]html$", relative_paths) ~ "rendered_report",
  grepl("[.]qmd$", relative_paths) ~ "report_source",
  grepl("^audit/handoffs/", relative_paths) ~ "handoff",
  grepl("^tests/", relative_paths) ~ "test",
  grepl("^scripts/", relative_paths) ~ "code",
  grepl("^artifacts/12_manifests/", relative_paths) ~ "manifest",
  TRUE ~ "stage1_audit_data"
)
manifest <- tibble::tibble(
  path = relative_paths,
  sha256 = vapply(paths, h11_sha256, character(1)),
  bytes = as.numeric(file.info(paths)$size),
  artifact_class = artifact_class,
  producer = "H11 Stage 1 gated audit",
  r_version = paste(R.version$major, R.version$minor, sep = ".")
)

output <- file.path(
  root,
  "artifacts/12_manifests/H11/H11_stage1_output_hashes.csv"
)
utils::write.csv(manifest, output, row.names = FALSE, na = "")
cat("H11 Stage 1 output manifest written:", output, "\n")
print(manifest, n = Inf)
