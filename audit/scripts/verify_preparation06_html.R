# Verify the executable Preparation 06 HTML and its copied figure resources.

options(warn = 2)

stopifnot(identical(as.character(getRversion()), "4.6.1"))

source("scripts/pipeline/paths_io.R")

root <- project_root()
manifest_paths <- c(
  normalization = file.path(
    root,
    "artifacts",
    "12_manifests",
    "model_input_normalization.csv"
  ),
  site_context = file.path(
    root,
    "artifacts",
    "12_manifests",
    "site_solar_context_artifacts.csv"
  ),
  temporal = file.path(
    root,
    "artifacts",
    "06_model_data",
    "temporal_provenance",
    "artifact_manifest.csv"
  ),
  base = file.path(
    root,
    "artifacts",
    "12_manifests",
    "base_model_data_artifacts.csv"
  ),
  h01_main = file.path(
    root,
    "artifacts",
    "12_manifests",
    "H01_model_data_artifacts.csv"
  ),
  manuscript_prepared_inputs = file.path(
    root,
    "artifacts",
    "12_manifests",
    "manuscript_prepared_data_artifacts.csv"
  ),
  h01_manuscript_prepared = file.path(
    root,
    "artifacts",
    "12_manifests",
    "H01_manuscript_prepared_data_artifacts.csv"
  ),
  comparison = file.path(
    root,
    "artifacts",
    "12_manifests",
    "preanalysis_comparison_artifacts.csv"
  )
)
expected_manifest_hashes <- c(
  normalization = "e3d484711abb54f69d63ff302e5a0329efda3fd0a8c85feaf9cc4f850005c9ab",
  site_context = "727f48016f430d1d48f1fe091c47bc7721011d72786fc691f3ca0d25a0a8386b",
  temporal = "d05f8cf2ba7f5be01ae2fa5eb9c27350da2f84ed07508a731e243f1db23e1bb6",
  base = "fd48dc5d1ecd5da125dd2c360c32239f0adfe7009eca881f5838b0e61b81b13d",
  h01_main = "48f7cb7a9539bd1a35237275187a76528f1daacfc9abe368cbc4bc1397ed0375",
  manuscript_prepared_inputs = "af74cc9fa36e426222d9b5f2328e2261c00b14436feb8d86fbf137d0ff313267",
  h01_manuscript_prepared = "672312ba62871317b0910fbd781f7f6db92e6718fed26961e17a986a5eb989f5",
  comparison = "a6ed6cbb184383fb7b649ae9b67e8d5c44e24fffb3ff3fbb8af52fbb252e768c"
)
observed_manifest_hashes <- vapply(
  manifest_paths,
  artifact_sha256,
  character(1)
)
stopifnot(identical(observed_manifest_hashes, expected_manifest_hashes))

html_path <- file.path(
  root,
  "_build",
  "nathealth",
  "notebooks",
  "preparation",
  "06_model_ready_datasets.html"
)
stopifnot(file.exists(html_path))

html <- paste(
  readLines(html_path, warn = FALSE, encoding = "UTF-8"),
  collapse = "\n"
)
required_text <- c(
  "Preparation 06: Prepare data for each hypothesis",
  "Check and standardize questionnaire and diary files",
  "Data available for each primary near-eye H01 model.",
  "Rows retained in the checked manuscript-prepared-data sensitivity inputs.",
  "Data available for each primary near-eye H01 model in the manuscript-prepared-data sensitivity.",
  "Not available from retained prepared artifacts",
  "this is not a formal sensitivity scenario",
  "Light-exposure metric names and categories used in the manuscript.",
  "Checks completed before comparing the manuscript-prepared and main datasets.",
  "Available observations, participants and participant-days in the manuscript-prepared and main datasets.",
  "Means, medians and distributions in the manuscript-prepared and main datasets.",
  "Category frequencies in the manuscript-prepared and main datasets.",
  "Show R code"
)
stopifnot(all(vapply(
  required_text,
  grepl,
  logical(1),
  x = html,
  fixed = TRUE
)))

forbidden_text <- c(
  "Could not fetch resource",
  "File not found",
  "Unable to load image",
  "Canonical Nature Health analysis",
  "Verified model-input normalization",
  "Canonical base-model data"
)
stopifnot(
  !any(vapply(
    forbidden_text,
    grepl,
    logical(1),
    x = html,
    fixed = TRUE
  ))
)

relative_figure_paths <- c(
  numeric = "../../artifacts/08_diagnostics/preanalysis_comparison/numeric_distribution_overview.png",
  categorical = "../../artifacts/08_diagnostics/preanalysis_comparison/categorical_distribution_overview.png"
)
required_image_markup <- paste0('<img src="', relative_figure_paths, '"')
stopifnot(all(vapply(
  required_image_markup,
  grepl,
  logical(1),
  x = html,
  fixed = TRUE
)))

copied_figure_paths <- vapply(
  relative_figure_paths,
  function(path) {
    normalizePath(
      file.path(dirname(html_path), path),
      winslash = "/",
      mustWork = TRUE
    )
  },
  character(1)
)
source_figure_paths <- stats::setNames(
  file.path(
    root,
    "artifacts",
    "08_diagnostics",
    "preanalysis_comparison",
    basename(relative_figure_paths)
  ),
  names(relative_figure_paths)
)
expected_figure_hashes <- c(
  numeric = "96210013f9ee40e0d243e721d486b95bcd8f2efbf3000f00ff909fefe3cc705d",
  categorical = "033fb43f955fccd4702fc9f8133bed1e2ff7108a5adf348edd7d0f6687bb7ac6"
)
source_figure_hashes <- vapply(
  source_figure_paths,
  artifact_sha256,
  character(1)
)
copied_figure_hashes <- vapply(
  copied_figure_paths,
  artifact_sha256,
  character(1)
)
stopifnot(
  identical(source_figure_hashes, expected_figure_hashes),
  identical(copied_figure_hashes, expected_figure_hashes)
)

cat(
  "Preparation 06 HTML verification passed\n",
  "HTML SHA-256: ",
  artifact_sha256(html_path),
  "\n",
  "Copied image hashes: ",
  paste(unname(copied_figure_hashes), collapse = ", "),
  "\n",
  sep = ""
)
