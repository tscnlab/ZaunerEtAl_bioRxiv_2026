#!/usr/bin/env Rscript

# Record the author-approved H02-aligned H06-daily temporal production gate.
# The historical reconciled pilot gate remains immutable; this script writes a
# new decision artifact containing the pointwise-only amendment.

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

required_packages <- c("digest", "readr", "tibble")
stopifnot(
  identical(as.character(getRversion()), "4.6.1"),
  all(vapply(required_packages, requireNamespace, logical(1), quietly = TRUE))
)

producer <- paste0(
  "scripts/hypotheses/H06_daily/",
  "record_h06_daily_temporal_h02_production_approval.R"
)
historical_gate <- paste0(
  "artifacts/08_diagnostics/H06_daily/",
  "H06_daily_temporal_h02_reconciled_gate_contract.csv"
)
author_transition <- paste0(
  "audit/hypotheses/H06_daily/",
  "H06_daily_temporal_h02_production_transition.md"
)
direct_inputs <- c(historical_gate, author_transition)
stopifnot(all(file.exists(file.path(root, direct_inputs))))

gate <- tibble::tribble(
  ~decision_id, ~decision, ~approved_contract, ~status,
  "H06-D-G2P-H02-01",
  "Response and structural model",
  paste(
    "Use 30-minute arithmetic-mean melEDI, log10(Y + 0.1 lx), Gaussian",
    "identity bam; only the global time smooth is cyclic"
  ),
  "CLOSED_BY_AUTHOR_CONFIRMATION",
  "H06-D-G2P-H02-02",
  "Context estimands",
  paste(
    "Extract Free day minus Work day and Active minus Sedentary profile",
    "contrasts, plus +1 h within- and between-participant sleep-duration",
    "association functions; use observational language"
  ),
  "APPROVED",
  "H06-D-G2P-H02-03",
  "Scale and uncertainty",
  paste(
    "Report transformed-scale curves, ratios for Y + 0.1, and inverse-",
    "transformed conditional-median-like profiles with pointwise 95%",
    "confidence intervals only; never call these raw-scale E[Y]"
  ),
  "APPROVED_POINTWISE_ONLY",
  "H06-D-G2P-H02-04",
  "Exploratory multiplicity",
  paste(
    "Use one separate four-test BH family for work/free, activity,",
    "within-participant sleep, and between-participant sleep whole-function",
    "tests; do not mix it with preregistration-aligned daily families"
  ),
  "APPROVED",
  "H06-D-G2P-H02-05",
  "Placement and scenario batch",
  paste(
    "Fit near-eye/chest all available, paired/common near-eye/chest, and",
    "gap-timing-unaware near-eye/chest after static support checks; each",
    "frame re-estimates rho and reports its exact sample"
  ),
  "APPROVED",
  "H06-D-G2P-H02-06",
  "Heavy diagnostics and resampling",
  paste(
    "Withhold site-deletion or other heavy resampling until a bounded",
    "production-code pilot measures 50/100 resamples or representative",
    "deletions and receives separate approval"
  ),
  "WITHHELD_PENDING_PILOT",
  "H06-D-G2P-H02-07",
  "MDER",
  paste(
    "Exclude MDER until the coordinator supplies the replacement manifest",
    "and targeted H06_daily repinning instructions"
  ),
  "UPSTREAM_HOLD"
)

diagnostics_dir <- file.path(root, "artifacts/08_diagnostics/H06_daily")
manifests_dir <- file.path(root, "artifacts/12_manifests/H06_daily")
output_relative <- paste0(
  "artifacts/08_diagnostics/H06_daily/",
  "H06_daily_temporal_h02_production_gate_contract.csv"
)
output <- file.path(root, output_relative)
readr::write_csv(gate, output, na = "")

sha256 <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE)
}
manifest <- function(relative_paths, roles) {
  absolute_paths <- file.path(root, relative_paths)
  tibble::tibble(
    relative_path = relative_paths,
    sha256 = vapply(absolute_paths, sha256, character(1)),
    bytes = unname(file.info(absolute_paths)$size),
    role = roles,
    producer = producer,
    r_version = as.character(getRversion())
  )
}

input_manifest <- manifest(
  direct_inputs,
  c("historical_pilot_gate", "author_approval_transition")
)
code_manifest <- manifest(producer, "approval_recorder")
output_manifest <- manifest(output_relative, "current_production_gate")
software_manifest <- tibble::tibble(
  component = c("R", required_packages),
  version = c(
    as.character(getRversion()),
    vapply(
      required_packages,
      function(package) as.character(utils::packageVersion(package)),
      character(1)
    )
  )
)

readr::write_csv(
  input_manifest,
  file.path(
    manifests_dir,
    "H06_daily_temporal_h02_production_gate_input_manifest.csv"
  ),
  na = ""
)
readr::write_csv(
  code_manifest,
  file.path(
    manifests_dir,
    "H06_daily_temporal_h02_production_gate_code_manifest.csv"
  ),
  na = ""
)
readr::write_csv(
  output_manifest,
  file.path(
    manifests_dir,
    "H06_daily_temporal_h02_production_gate_output_manifest.csv"
  ),
  na = ""
)
readr::write_csv(
  software_manifest,
  file.path(
    manifests_dir,
    "H06_daily_temporal_h02_production_gate_software_manifest.csv"
  ),
  na = ""
)

message("Recorded H06-D-G2P-H02 production approval with pointwise intervals")
