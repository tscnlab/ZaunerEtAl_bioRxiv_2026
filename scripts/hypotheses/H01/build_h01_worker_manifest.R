# Hash every H01 worker-owned output without modifying analytical artifacts.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
source(file.path(root, "scripts/pipeline/paths_io.R"))

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop(
    sprintf(
      "The H01 worker manifest requires R 4.6.1; found %s",
      as.character(getRversion())
    ),
    call. = FALSE
  )
}

manifest_path <- file.path(
  root,
  "artifacts/12_manifests/H01_worker_artifacts.csv"
)
roots <- c(
  file.path(root, "scripts/hypotheses/H01"),
  file.path(root, "tests/hypotheses/H01"),
  file.path(root, "audit/hypotheses/H01"),
  file.path(root, "artifacts/07_models/H01"),
  file.path(root, "artifacts/08_diagnostics/H01"),
  file.path(root, "artifacts/09_tables/H01"),
  file.path(root, "artifacts/10_figures/H01"),
  file.path(root, "artifacts/11_source_data/H01"),
  file.path(root, "artifacts/12_manifests/H01"),
  file.path(root, "_build/nathealth/audit/hypotheses/H01")
)
files <- unlist(lapply(
  roots[dir.exists(roots)],
  list.files,
  recursive = TRUE,
  full.names = TRUE
))
single_files <- file.path(
  root,
  c(
    "notebooks/hypotheses/H01.qmd",
    "_quarto-nathealth.yml",
    "_build/nathealth/notebooks/hypotheses/H01.html",
    "_build/nathealth/audit/H01/02_implementation_and_v0_comparison.html",
    "audit/handoffs/H01_shared_change_request.md",
    "audit/handoffs/H01_worker_handoff.md",
    "artifacts/12_manifests/H01_model_results_artifacts.csv"
  )
)
h01_manifests <- list.files(
  file.path(root, "artifacts/12_manifests"),
  pattern = "^H01.*[.]csv$",
  full.names = TRUE
)
files <- sort(unique(c(
  files,
  single_files[file.exists(single_files)],
  h01_manifests
)))
files <- files[
  file.exists(files) &
    !dir.exists(files) &
    normalizePath(
      files,
      winslash = "/",
      mustWork = TRUE
    ) != normalizePath(
      manifest_path,
      winslash = "/",
      mustWork = FALSE
    )
]

manifest <- dplyr::bind_rows(lapply(files, function(path) {
  normalized <- normalizePath(path, winslash = "/", mustWork = TRUE)
  tibble::tibble(
    path = substring(normalized, nchar(root) + 2L),
    sha256 = artifact_sha256(normalized),
    bytes = as.numeric(file.info(normalized)$size),
    producer = "scripts/hypotheses/H01/build_h01_worker_manifest.R",
    r_version = as.character(getRversion())
  )
}))
readr::write_csv(manifest, manifest_path, na = "")
message("H01 worker manifest completed: ", nrow(manifest), " files")
