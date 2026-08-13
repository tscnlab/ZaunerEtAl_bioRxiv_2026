#!/usr/bin/env Rscript

# Focused no-refit verification of the H06-D-G4 author acceptance closure.

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
  requireNamespace("readr", quietly = TRUE)
)

sha256 <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
}

acceptance_relative <- paste0(
  "audit/hypotheses/H06_daily/",
  "H06_daily_stage4_preparation_acceptance.md"
)
gate_relative <- paste0(
  "audit/hypotheses/H06_daily/",
  "H06_daily_stage4_preparation_gate.md"
)
manifest_relative <- paste0(
  "artifacts/12_manifests/H06_daily/",
  "H06_daily_preparation_acceptance_manifest.csv"
)

acceptance_text <- paste(
  readLines(file.path(root, acceptance_relative), warn = FALSE),
  collapse = "\n"
)
stopifnot(
  grepl("Author instruction: `approved - wrap up`", acceptance_text, fixed = TRUE),
  grepl("Status: **author accepted; task closed**", acceptance_text, fixed = TRUE),
  grepl("There is no automatic next analytical", acceptance_text, fixed = TRUE),
  sha256(file.path(root, gate_relative)) ==
    "075d5e4b749d0e4f814dd925b54bea6a9619245b202e5d8f1f01a6a7debee974"
)

expected_frozen <- c(
  "audit/hypotheses/H06_daily/H06_daily_analysis_preparation.qmd" =
    "fdfe94cf96e16ecfff3455c3e2427bd94c6419ee62350211a724821870058c0e",
  "audit/hypotheses/H06_daily/H06_daily_analysis_preparation.html" =
    "7f3adfd0d80c9e083baa34f6aa056bc12e0a30e233f786fbc55a6ad6ac176259",
  "audit/hypotheses/H06_daily/H06_daily_analysis_preparation_report_manifest.csv" =
    "1579815ec9d3110f4e5b37fe7f5843947f1e0543dbe1b219c834be0ba388e28d",
  "artifacts/12_manifests/H06_daily/H06_daily_preparation_source_data_manifest.csv" =
    "19f441e87912962c7d60268899511c1f3a8e4c318502a6ed1c79e7e8e125f8ba",
  "artifacts/12_manifests/H06_daily/H06_daily_preparation_software_manifest.csv" =
    "25f547ccf47c8c3afc75d9b43dc457fe41d4bac7e2e9cf16baf710f7384d95e9",
  "artifacts/12_manifests/H06_daily/H06_daily_preparation_figure_readability_qa.csv" =
    "ae5dbb7a2a9f7f0dc47a60297e6bc9a244d103859186748756797332942dba45",
  "artifacts/12_manifests/H06_daily/H06_daily_preparation_render_qa.csv" =
    "840fdaef6c31a51e2aabd6727a60b66a8a9df54cb0199b4a6c018c3080ea22de",
  "artifacts/12_manifests/H06_daily/H06_daily_preparation_output_manifest.csv" =
    "50461464c788a882635809881638856dde8b6f16a8593eb0fa76194be9feb190",
  "tests/hypotheses/H06_daily/test_h06_daily_preparation_report.R" =
    "4fbf8ba28dc957295ec5c90e42247f644c0010b3097195652d1e260fb6bdc2a0",
  "notebooks/hypotheses/H06_daily.qmd" =
    "0318fd6cf874380631296d35095486b9de7f987a9779e4dc5d59c5a635a8c3dc",
  "notebooks/hypotheses/H06_daily.html" =
    "5a20c0680011be17111f72bb6b15aed6a4f4700c8866a13ea6dcf49a589fcce3",
  "audit/hypotheses/H06_daily/H06_daily_stage3_revision_gate.md" =
    "733dd1dd4c57bfdb6df7bf10e69e635455c451373c8dd0f6e3060c12b6e3884e"
)
frozen_paths <- file.path(root, names(expected_frozen))
stopifnot(
  all(file.exists(frozen_paths)),
  identical(
    unname(vapply(frozen_paths, sha256, character(1L))),
    unname(expected_frozen)
  )
)

manifest <- readr::read_csv(
  file.path(root, manifest_relative),
  show_col_types = FALSE,
  na = c("", "NA")
)
manifest_paths <- file.path(root, manifest$relative_path)
stopifnot(
  identical(
    names(manifest),
    c(
      "relative_path", "sha256", "bytes", "role", "producer", "r_version",
      "closure_status", "closed_gate"
    )
  ),
  nrow(manifest) == 19L,
  !anyDuplicated(manifest$relative_path),
  !manifest_relative %in% manifest$relative_path,
  acceptance_relative %in% manifest$relative_path,
  gate_relative %in% manifest$relative_path,
  all(manifest$closure_status == "AUTHOR_ACCEPTED_CLOSED"),
  all(manifest$closed_gate == "H06-D-G4"),
  all(manifest$r_version == "4.6.1"),
  all(file.exists(manifest_paths)),
  identical(
    unname(vapply(manifest_paths, sha256, character(1L))),
    manifest$sha256
  ),
  identical(as.numeric(file.info(manifest_paths)$size), manifest$bytes)
)

cat(
  paste0(
    "PASS: H06-D-G4 author acceptance verified under R ",
    getRversion(),
    ": 19 non-circular identities, accepted preparation and Stage 3 outputs ",
    "preserved, and no scientific computation.\n"
  )
)
