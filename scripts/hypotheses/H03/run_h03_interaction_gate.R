# Run the results-blind H03 site-heterogeneity architecture gate.

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

source(file.path(root, "scripts/pipeline/paths_io.R"))
source(file.path(root, "scripts/hypotheses/H03/h03_contract.R"))
source(file.path(root, "scripts/hypotheses/H03/h03_data.R"))
source(file.path(root, "scripts/hypotheses/H03/h03_modeling.R"))

if (!identical(as.character(getRversion()), "4.6.1")) {
  h03_abort(
    "H03 interaction gate requires R 4.6.1; found %s",
    as.character(getRversion())
  )
}
required_packages <- c(
  "dplyr", "tidyr", "purrr", "tibble", "readr", "digest", "openssl",
  "statmod", "sandwich"
)
missing_packages <- required_packages[!vapply(
  required_packages,
  requireNamespace,
  logical(1),
  quietly = TRUE
)]
if (length(missing_packages) > 0L) {
  h03_abort(
    "Missing project package(s): %s",
    paste(missing_packages, collapse = ", ")
  )
}

producer <- "scripts/hypotheses/H03/run_h03_interaction_gate.R"
paths <- list(
  model_data = file.path(root, "artifacts/06_model_data/H03"),
  models = file.path(root, "artifacts/07_models/H03"),
  diagnostics = file.path(root, "artifacts/08_diagnostics/H03"),
  manifests = file.path(root, "artifacts/12_manifests/H03")
)
invisible(vapply(
  paths,
  dir.create,
  logical(1),
  recursive = TRUE,
  showWarnings = FALSE
))

metadata <- list()
write_h03_csv <- function(data, path, id) {
  metadata[[id]] <<- write_csv_artifact(data, path, producer)
  invisible(path)
}
write_h03_rds <- function(object, path, id) {
  metadata[[id]] <<- write_rds_artifact(object, path, producer)
  invisible(path)
}

input_audit <- h03_validate_inputs(root)
inputs <- h03_load_inputs(root)
spec <- h03_specification()
diary <- h03_prepare_diary(
  inputs$diary,
  inputs$categories,
  inputs$sites
)
near_eye <- h03_prepare_primary_frame(
  inputs$near_eye,
  diary,
  "Near-eye",
  inputs$categories,
  inputs$sites
)$frame
chest <- h03_prepare_primary_frame(
  inputs$chest,
  diary,
  "Chest",
  inputs$categories,
  inputs$sites
)$frame

message("Running results-blind near-eye interaction gate")
near_gate <- h03_run_interaction_gate(
  near_eye,
  "Near-eye",
  inputs$categories,
  inputs$sites,
  spec
)
message("Running results-blind chest interaction gate")
chest_gate <- h03_run_interaction_gate(
  chest,
  "Chest",
  inputs$categories,
  inputs$sites,
  spec
)

gate_diagnostics <- dplyr::bind_rows(near_gate$gate, chest_gate$gate)
selection <- tibble::tibble(
  placement = c("Near-eye", "Chest"),
  selected_architecture = c(
    near_gate$selected_architecture,
    chest_gate$selected_architecture
  ),
  selection_rule = c(
    "first predeclared architecture passing all results-blind hard gates",
    "first predeclared architecture passing all results-blind hard gates"
  ),
  full_architecture_passed = c(
    isTRUE(near_gate$gate$gate_pass[1]),
    isTRUE(chest_gate$gate$gate_pass[1])
  ),
  interaction_effects_inspected_for_selection = FALSE,
  interaction_p_values_inspected_for_selection = FALSE
)

write_h03_csv(
  input_audit,
  file.path(paths$model_data, "H03_input_audit.csv"),
  "input_audit"
)
write_h03_csv(
  gate_diagnostics,
  file.path(paths$diagnostics, "H03_interaction_architecture_gate.csv"),
  "interaction_gate"
)
write_h03_csv(
  selection,
  file.path(paths$diagnostics, "H03_interaction_architecture_selection.csv"),
  "interaction_selection"
)
write_h03_rds(
  list(
    near_eye = near_gate,
    chest = chest_gate,
    specification = spec,
    executed_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
    effect_inspection_used_for_selection = FALSE
  ),
  file.path(paths$models, "H03_interaction_gate_models.rds"),
  "interaction_gate_models"
)

manifest <- dplyr::bind_rows(lapply(metadata, manifest_row))
write_csv_artifact(
  manifest,
  file.path(paths$manifests, "H03_interaction_gate_manifest.csv"),
  producer
)

print(as.data.frame(gate_diagnostics), row.names = FALSE)
print(as.data.frame(selection), row.names = FALSE)
message("H03 results-blind interaction gate complete; no effect was emitted")
