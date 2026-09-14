# Refresh Figures 1 and 2 from their stored descriptive source data.

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
source(file.path(root, "renv", "activate.R"))
source(file.path(root, "scripts", "descriptives", "build_descriptives.R"))
source_descriptive_modules(root)
check_descriptive_packages()
paths <- descriptive_paths(root)

# The metric table and metric-distribution figure are deliberately outside this
# display-only run while the coordinator-owned MDER source is being rebuilt.
figure_ids <- c(
  "descriptive_overview",
  "near_eye_site_profiles",
  "chest_site_profiles"
)
figure_build <- build_and_save_descriptive_figures(
  paths,
  figure_ids = figure_ids
)

write_descriptive_csv(
  figure_build$spec,
  file.path(paths$manifest_dir, "figure_specifications.csv")
)
write_descriptive_csv(
  figure_build$qa,
  file.path(paths$audit_dir, "figure_readability_qa.csv")
)

source_map <- descriptive_figure_source_map()
source_map_table <- dplyr::bind_rows(lapply(
  names(source_map),
  function(figure_id) {
    data.frame(
      figure_id = figure_id,
      source_data_path = file.path(
        "artifacts/11_source_data/descriptives",
        source_map[[figure_id]]
      ),
      stringsAsFactors = FALSE
    )
  }
)) |>
  dplyr::mutate(
    source_data_sha256 = vapply(
      file.path(root, .data$source_data_path),
      artifact_sha256,
      character(1)
    )
  )
write_descriptive_csv(
  source_map_table,
  file.path(paths$manifest_dir, "figure_source_data_map.csv")
)

visual_comparison <- build_visual_export_comparison(
  paths,
  list(spec = publication_table_export_spec()),
  figure_build
)
write_descriptive_csv(
  visual_comparison,
  file.path(paths$audit_dir, "visual_export_comparison.csv")
)

manifest_path <- file.path(paths$manifest_dir, "descriptive_artifacts.csv")
manifest <- read_plot_source_csv(manifest_path)
refreshed_records <- figure_build$records
refreshed_index <- match(refreshed_records$path, manifest$path)
if (anyNA(refreshed_index)) {
  stop(
    "A refreshed Figure 1/2 artifact is absent from the manifest",
    call. = FALSE
  )
}
record_fields <- c(
  "artifact_type",
  "placement",
  "source_data",
  "figure_id",
  "width_in",
  "height_in",
  "dpi"
)
for (field in record_fields) {
  manifest[[field]][refreshed_index] <- refreshed_records[[field]]
}

absolute_paths <- file.path(root, manifest$path)
if (any(!file.exists(absolute_paths))) {
  stop(
    "A manifest path is missing during the Figure 1/2 refresh",
    call. = FALSE
  )
}
manifest$sha256 <- vapply(absolute_paths, artifact_sha256, character(1))
manifest$bytes <- as.numeric(file.info(absolute_paths)$size)
write_descriptive_csv(manifest, manifest_path)

message("Figures 1 and 2 refreshed without rebuilding Table 2 or Figures 3--5.")
