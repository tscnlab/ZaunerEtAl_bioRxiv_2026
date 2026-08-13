#!/usr/bin/env Rscript

# Build the report-level manifest for the bounded H06_daily no-nugget gate.

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
stopifnot(
  identical(as.character(getRversion()), "4.6.1"),
  requireNamespace("digest", quietly = TRUE),
  requireNamespace("readr", quietly = TRUE),
  requireNamespace("tibble", quietly = TRUE)
)

producer <- paste0(
  "scripts/hypotheses/H06_daily/",
  "build_h06_daily_pre_sleep_no_nugget_report_manifest.R"
)
paths <- c(
  "audit/hypotheses/H06_daily/07_pre_sleep_no_nugget_diagnostic.qmd",
  "audit/hypotheses/H06_daily/07_pre_sleep_no_nugget_diagnostic.html",
  paste0(
    "audit/hypotheses/H06_daily/",
    "H06_daily_pre_sleep_no_nugget_authorization.md"
  ),
  paste0(
    "audit/hypotheses/H06_daily/",
    "H06_daily_pre_sleep_no_nugget_transition.md"
  ),
  paste0(
    "audit/hypotheses/H06_daily/",
    "H06_daily_daily_ar_repair_pilot_transition.md"
  ),
  "audit/handoffs/H06_daily_worker_handoff.md",
  "audit/handoffs/H06_daily_shared_change_request.md",
  paste0(
    "scripts/hypotheses/H06_daily/",
    "run_h06_daily_pre_sleep_no_nugget_diagnostic.R"
  ),
  paste0(
    "scripts/hypotheses/H06_daily/",
    "finalize_h06_daily_pre_sleep_no_nugget_diagnostic.R"
  ),
  paste0(
    "scripts/hypotheses/H06_daily/",
    "seal_h06_daily_pre_sleep_no_nugget_reference.R"
  ),
  producer,
  paste0(
    "tests/hypotheses/H06_daily/",
    "test_h06_daily_pre_sleep_no_nugget_diagnostic.R"
  ),
  paste0(
    "artifacts/07_models/H06_daily/",
    "H06_daily_pre_sleep_no_nugget_diagnostic_model.rds"
  ),
  paste0(
    "artifacts/07_models/H06_daily/",
    "H06_daily_pre_sleep_only_historical_reference.rds"
  ),
  paste0(
    "artifacts/08_diagnostics/H06_daily/",
    "H06_daily_pre_sleep_no_nugget_frame_equivalence.csv"
  ),
  paste0(
    "artifacts/08_diagnostics/H06_daily/",
    "H06_daily_pre_sleep_no_nugget_support.csv"
  ),
  paste0(
    "artifacts/08_diagnostics/H06_daily/",
    "H06_daily_pre_sleep_no_nugget_model_diagnostics.csv"
  ),
  paste0(
    "artifacts/08_diagnostics/H06_daily/",
    "H06_daily_pre_sleep_no_nugget_verdict.csv"
  ),
  paste0(
    "artifacts/08_diagnostics/H06_daily/",
    "H06_daily_pre_sleep_no_nugget_final_model_diagnostics.csv"
  ),
  paste0(
    "artifacts/08_diagnostics/H06_daily/",
    "H06_daily_pre_sleep_no_nugget_final_verdict.csv"
  ),
  paste0(
    "artifacts/08_diagnostics/H06_daily/",
    "H06_daily_pre_sleep_no_nugget_audit_correction.csv"
  ),
  paste0(
    "artifacts/08_diagnostics/H06_daily/",
    "H06_daily_pre_sleep_no_nugget_site_residual_lag.csv"
  ),
  paste0(
    "artifacts/08_diagnostics/H06_daily/",
    "H06_daily_pre_sleep_no_nugget_runtime.csv"
  ),
  paste0(
    "artifacts/08_diagnostics/H06_daily/",
    "H06_daily_pre_sleep_no_nugget_reference_provenance.csv"
  ),
  paste0(
    "artifacts/09_tables/H06_daily/",
    "H06_daily_pre_sleep_no_nugget_effect_stability.csv"
  ),
  paste0(
    "artifacts/12_manifests/H06_daily/",
    "H06_daily_pre_sleep_no_nugget_diagnostic_input_manifest.csv"
  ),
  paste0(
    "artifacts/12_manifests/H06_daily/",
    "H06_daily_pre_sleep_no_nugget_diagnostic_code_manifest.csv"
  ),
  paste0(
    "artifacts/12_manifests/H06_daily/",
    "H06_daily_pre_sleep_no_nugget_diagnostic_output_manifest.csv"
  ),
  paste0(
    "artifacts/12_manifests/H06_daily/",
    "H06_daily_pre_sleep_no_nugget_diagnostic_software_manifest.csv"
  ),
  paste0(
    "artifacts/12_manifests/H06_daily/",
    "H06_daily_pre_sleep_no_nugget_final_input_manifest.csv"
  ),
  paste0(
    "artifacts/12_manifests/H06_daily/",
    "H06_daily_pre_sleep_no_nugget_final_code_manifest.csv"
  ),
  paste0(
    "artifacts/12_manifests/H06_daily/",
    "H06_daily_pre_sleep_no_nugget_final_output_manifest.csv"
  ),
  paste0(
    "artifacts/12_manifests/H06_daily/",
    "H06_daily_pre_sleep_no_nugget_final_software_manifest.csv"
  ),
  paste0(
    "artifacts/12_manifests/H06_daily/",
    "H06_daily_pre_sleep_no_nugget_diagnostic_repaired_input_manifest.csv"
  ),
  paste0(
    "artifacts/12_manifests/H06_daily/",
    "H06_daily_pre_sleep_no_nugget_reference_seal_input_manifest.csv"
  ),
  paste0(
    "artifacts/12_manifests/H06_daily/",
    "H06_daily_pre_sleep_no_nugget_reference_seal_code_manifest.csv"
  ),
  paste0(
    "artifacts/12_manifests/H06_daily/",
    "H06_daily_pre_sleep_no_nugget_reference_seal_output_manifest.csv"
  ),
  paste0(
    "artifacts/12_manifests/H06_daily/",
    "H06_daily_pre_sleep_no_nugget_reference_seal_software_manifest.csv"
  )
)
roles <- c(
  "executed no-nugget gate source",
  "self-contained no-nugget gate report",
  "immutable author authorization",
  "current no-nugget transition",
  "parent daily AR repair transition",
  "current worker handoff",
  "shared L10 implementation request",
  "executed one-fit script",
  "no-refit parameter-map finalizer",
  "no-refit standalone-reference sealer",
  "report-manifest builder",
  "focused no-refit verification",
  "executed no-nugget model checkpoint",
  "standalone pre-sleep-only historical reference",
  "current-versus-authorized frame equivalence",
  "daily sequence support",
  "immutable preliminary model diagnostics",
  "immutable preliminary verdict",
  "final model diagnostics",
  "final acceptable verdict",
  "parameter-map audit correction",
  "site-specific residual lag screen",
  "one-fit runtime record",
  "standalone-reference provenance and disclosure",
  "engineering effect stability",
  "immutable executed input manifest",
  "executed code manifest",
  "immutable executed output manifest",
  "executed software manifest",
  "no-refit finalizer input manifest",
  "no-refit finalizer code manifest",
  "no-refit finalizer output manifest",
  "no-refit finalizer software manifest",
  "controlling repaired scientific input manifest",
  "reference-seal provenance input manifest",
  "reference-seal code manifest",
  "reference-seal output manifest",
  "reference-seal software manifest"
)
stopifnot(length(paths) == length(roles), all(file.exists(file.path(root, paths))))
sha256 <- function(path) digest::digest(path, algo = "sha256", file = TRUE)
manifest <- tibble::tibble(
  relative_path = paths,
  sha256 = vapply(file.path(root, paths), sha256, character(1)),
  bytes = unname(file.info(file.path(root, paths))$size),
  role = roles,
  producer = producer,
  r_version = as.character(getRversion())
)
output <- file.path(
  root,
  paste0(
    "audit/hypotheses/H06_daily/",
    "H06_daily_pre_sleep_no_nugget_report_manifest.csv"
  )
)
readr::write_csv(manifest, output, na = "")
message("Wrote ", sub(paste0("^", root, "/"), "", output))
