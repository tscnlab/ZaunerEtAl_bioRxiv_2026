#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE, warn = 2)
suppressPackageStartupMessages({
  library(openssl)
  library(readr)
})

stopifnot(identical(as.character(getRversion()), "4.6.1"))
root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
setwd(root)

sha256_file <- function(path) {
  connection <- file(path, open = "rb")
  on.exit(close(connection), add = TRUE)
  paste0(openssl::sha256(connection))
}

evidence_dir <- paste0(
  "audit/report_harmonization/",
  "report018_sensitivity_battery_order62_render"
)
archive_dir <- file.path(evidence_dir, "initial_postrender_inventory")
dir.create(archive_dir, recursive = TRUE, showWarnings = FALSE)
names <- c(
  "build_inventory_postrender.csv",
  "protected_inventory_postrender.csv",
  "inventory_summary_postrender.csv"
)
for (name in names) {
  source <- file.path(evidence_dir, name)
  destination <- file.path(archive_dir, name)
  stopifnot(file.exists(source))
  if (!file.exists(destination)) {
    stopifnot(file.copy(source, destination, overwrite = FALSE))
  }
  stopifnot(sha256_file(source) == sha256_file(destination))
}

output <- suppressWarnings(system2(
  file.path(R.home("bin"), "Rscript"),
  c(
    "--vanilla",
    "scripts/report_harmonization/capture_report018_sensitivity_order62_inventory.R",
    "postrender"
  ),
  stdout = TRUE,
  stderr = TRUE,
  env = c(
    "RENV_CONFIG_AUTOLOADER_ENABLED=FALSE",
    paste0("R_LIBS_USER=", Sys.getenv("R_LIBS_USER")),
    paste0("NATHEALTH_PROJECT_ROOT=", root)
  )
))
status <- attr(output, "status")
if (is.null(status)) status <- 0L
writeLines(
  enc2utf8(output),
  file.path(evidence_dir, "refresh_preqa_baseline_output.txt"),
  useBytes = TRUE
)
stopifnot(
  status == 0L,
  any(grepl(
    "REPORT018_SENSITIVITY_ORDER62_INVENTORY=POSTRENDER",
    output,
    fixed = TRUE
  )),
  sha256_file("_build/nathealth/notebooks/sensitivity_battery.html") ==
    "875f53995f5f47ec30b630a5cf47edfef1d0fe925034d3fab4944be8c6c6b4be"
)

before <- readr::read_csv(
  file.path(archive_dir, "protected_inventory_postrender.csv"),
  show_col_types = FALSE
)
after <- readr::read_csv(
  file.path(evidence_dir, "protected_inventory_postrender.csv"),
  show_col_types = FALSE
)
added <- setdiff(after$path, before$path)
removed <- setdiff(before$path, after$path)
transition <- data.frame(
  metric = c(
    "historical_postrender_members",
    "preqa_baseline_members",
    "authorized_audit_harness_additions",
    "removed_paths",
    "build_members",
    "target_sha256"
  ),
  value = c(
    nrow(before),
    nrow(after),
    length(added),
    length(removed),
    nrow(readr::read_csv(
      file.path(evidence_dir, "build_inventory_postrender.csv"),
      show_col_types = FALSE
    )),
    sha256_file("_build/nathealth/notebooks/sensitivity_battery.html")
  ),
  status = c(
    "HISTORICAL_EXACT",
    "PREQA_BASELINE",
    "AUTHORIZED_EVIDENCE_ONLY",
    ifelse(length(removed) == 0L, "PASS", "FAIL"),
    "PASS",
    "PASS"
  ),
  stringsAsFactors = FALSE
)
readr::write_csv(
  transition,
  file.path(evidence_dir, "preqa_baseline_transition.csv")
)
readr::write_csv(
  data.frame(path = added, stringsAsFactors = FALSE),
  file.path(evidence_dir, "preqa_authorized_harness_additions.csv")
)
stopifnot(length(removed) == 0L)

cat(sprintf(
  paste0(
    "REPORT018_SENSITIVITY_ORDER62_PREQA_BASELINE=PASS protected=%d ",
    "added_evidence=%d removed=0 R=%s\n"
  ),
  nrow(after),
  length(added),
  as.character(getRversion())
))
