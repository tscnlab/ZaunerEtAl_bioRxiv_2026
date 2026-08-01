# Verify the immutable H01 Stage 2 comparison archive without executing models.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
source(file.path(root, "scripts/pipeline/paths_io.R"))

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("The H01 Stage 2 archive verifier requires R 4.6.1", call. = FALSE)
}

archive <- tibble::tribble(
  ~role, ~path, ~expected_sha256,
  "accepted Stage 2 source",
  "audit/hypotheses/H01/02_implementation_and_v0_comparison.qmd",
  "af6a50df9d8f384f7a07053bdb543bd9c475f8dc13736ba3cb432f693b6628b3",
  "accepted Stage 2 HTML",
  "_build/nathealth/audit/H01/02_implementation_and_v0_comparison.html",
  "4daa424552ce83cd0a5879cae4ced62d6ca75c4703bc0a1b3be2806ff332c10e",
  "Stage 2 reporting-manifest snapshot",
  paste0(
    "audit/hypotheses/H01/",
    "02_implementation_and_v0_comparison_reporting_manifest.csv"
  ),
  "03f9f8eb728c43392c099e3a243d43da59f0319b1edd5ef97f0b90f17962675e",
  "Stage 2 model-results-manifest snapshot",
  paste0(
    "audit/hypotheses/H01/",
    "02_implementation_and_v0_comparison_model_results_manifest.csv"
  ),
  "19aacb9604e052cbdd2d60ee6689239faf520673ca0f6b10aaf84a5492ef73ae",
  "Stage 2 worker-manifest snapshot",
  paste0(
    "audit/hypotheses/H01/",
    "02_implementation_and_v0_comparison_worker_manifest.csv"
  ),
  "1bd6c563549c8d1b3d828a435fc73fcef5661e873704bb84ebe1a1a407ab09f1"
)

absolute_paths <- file.path(root, archive$path)
if (any(!file.exists(absolute_paths))) {
  stop(
    "The H01 Stage 2 archive is missing: ",
    paste(archive$path[!file.exists(absolute_paths)], collapse = ", "),
    call. = FALSE
  )
}

archive <- archive |>
  dplyr::mutate(
    observed_sha256 = vapply(absolute_paths, artifact_sha256, character(1)),
    bytes = as.numeric(file.info(absolute_paths)$size),
    hash_status = dplyr::if_else(
      .data$observed_sha256 == .data$expected_sha256,
      "PASS",
      "FAIL"
    ),
    r_version = as.character(getRversion()),
    verifier = "scripts/hypotheses/H01/verify_h01_stage2_archive.R"
  )

if (any(archive$hash_status != "PASS")) {
  stop("The H01 Stage 2 archive differs from the accepted hashes", call. = FALSE)
}

html_resources <- file.path(
  root,
  "_build/nathealth",
  c("site_libs", "styles.css", "artifacts", "manuscript")
)
if (any(!file.exists(html_resources))) {
  stop(
    "The archived H01 Stage 2 HTML is missing a local resource root",
    call. = FALSE
  )
}

manifest_path <- file.path(
  root,
  "audit/hypotheses/H01/",
  "02_implementation_and_v0_comparison_archive_manifest.csv"
)
readr::write_csv(archive, manifest_path, na = "")
message("H01 Stage 2 archive verification passed: ", nrow(archive), " files")
