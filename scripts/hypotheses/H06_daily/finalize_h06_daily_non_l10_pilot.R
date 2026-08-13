# Seal the non-circular H06-D-G2P-NONL10 report manifest without refitting.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
.libPaths(c(
  file.path(root, "renv/library/macos/R-4.6/aarch64-apple-darwin23"),
  .libPaths()
))
stopifnot(
  identical(as.character(getRversion()), "4.6.1"),
  requireNamespace("digest", quietly = TRUE),
  requireNamespace("readr", quietly = TRUE),
  requireNamespace("tibble", quietly = TRUE)
)

producer <-
  "scripts/hypotheses/H06_daily/finalize_h06_daily_non_l10_pilot.R"
manifest_relative <- paste0(
  "audit/hypotheses/H06_daily/",
  "H06_daily_non_l10_pilot_report_manifest.csv"
)
paths <- c(
  "audit/decisions/h06_primary_selection_and_daily_complement.md",
  "audit/decisions/h06_daily_non_l10_grid_reopening.md",
  "audit/hypotheses/H06_daily/10_non_l10_pilot.qmd",
  "audit/hypotheses/H06_daily/10_non_l10_pilot.html",
  paste0(
    "audit/hypotheses/H06_daily/",
    "H06_daily_non_l10_pilot_transition.md"
  ),
  "scripts/hypotheses/H06_daily/h06_daily_non_l10_pilot_contract.R",
  "scripts/hypotheses/H06_daily/h06_daily_non_l10_pilot_data.R",
  "scripts/hypotheses/H06_daily/h06_daily_non_l10_pilot_modeling.R",
  "scripts/hypotheses/H06_daily/run_h06_daily_non_l10_pilot.R",
  "scripts/hypotheses/H06_daily/postprocess_h06_daily_non_l10_pilot.R",
  producer,
  "tests/hypotheses/H06_daily/test_h06_daily_non_l10_pilot.R",
  paste0(
    "artifacts/12_manifests/H06_daily/",
    "H06_daily_non_l10_pilot_input_manifest.csv"
  ),
  paste0(
    "artifacts/12_manifests/H06_daily/",
    "H06_daily_non_l10_pilot_code_manifest.csv"
  ),
  paste0(
    "artifacts/12_manifests/H06_daily/",
    "H06_daily_non_l10_pilot_output_manifest.csv"
  ),
  paste0(
    "artifacts/12_manifests/H06_daily/",
    "H06_daily_non_l10_pilot_software_manifest.csv"
  ),
  paste0(
    "artifacts/08_diagnostics/H06_daily/",
    "H06_daily_non_l10_pilot_verdict.csv"
  ),
  paste0(
    "artifacts/08_diagnostics/H06_daily/",
    "H06_daily_non_l10_pilot_preservation_final.csv"
  )
)
roles <- c(
  "primary/complementary role decision",
  "bounded pilot authorization",
  "author gate source",
  "rendered author gate",
  "task transition and stop state",
  "pilot scientific contract",
  "current-source and frame construction code",
  "model and diagnostic code",
  "bounded pilot runner",
  "no-refit runtime correction and manifest reseal",
  "non-circular report-manifest sealer",
  "focused no-refit verifier",
  "sealed input identities",
  "sealed code identities",
  "sealed scientific-output identities",
  "authoritative software identity",
  "pilot stop-gate verdict",
  "protected historical identity evidence"
)
stopifnot(
  length(paths) == length(roles),
  !manifest_relative %in% paths,
  !anyDuplicated(paths)
)
absolute <- file.path(root, paths)
stopifnot(all(file.exists(absolute)))
manifest <- tibble::tibble(
  relative_path = paths,
  sha256 = unname(vapply(
    absolute,
    digest::digest,
    character(1),
    algo = "sha256",
    file = TRUE
  )),
  bytes = unname(file.info(absolute)$size),
  role = roles,
  producer = producer,
  r_version = as.character(getRversion())
)
manifest_path <- file.path(root, manifest_relative)
temporary <- tempfile(
  pattern = paste0(basename(manifest_path), "-"),
  tmpdir = dirname(manifest_path),
  fileext = ".tmp"
)
readr::write_csv(manifest, temporary, na = "")
if (!file.rename(temporary, manifest_path)) {
  unlink(temporary)
  stop("Could not atomically write report manifest", call. = FALSE)
}
cat(sprintf(
  "Sealed %d non-circular H06-D-G2P-NONL10 report identities.\n",
  nrow(manifest)
))
