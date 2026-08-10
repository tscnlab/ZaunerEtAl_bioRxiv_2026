# Record the bounded final-size visual inspection of H09 Stage 2 figures.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)

project_library <- file.path(
  root,
  "renv/library/macos/R-4.6/aarch64-apple-darwin23"
)
if (dir.exists(project_library)) {
  .libPaths(c(project_library, .libPaths()))
}

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
})

source(file.path(root, "scripts/pipeline/paths_io.R"))

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("H09 figure QA requires R 4.6.1", call. = FALSE)
}

manifest_path <- file.path(
  root,
  "artifacts/12_manifests/H09/H09_figure_manifest.csv"
)
figure_manifest <- readr::read_csv(
  manifest_path,
  show_col_types = FALSE,
  na = ""
)

stopifnot(
  nrow(figure_manifest) == 6L,
  all(file.exists(file.path(root, figure_manifest$figure_path))),
  all(file.exists(file.path(root, figure_manifest$pdf_path))),
  all(file.exists(file.path(root, figure_manifest$source_data_path))),
  all(file.info(file.path(root, figure_manifest$figure_path))$size > 0),
  all(file.info(file.path(root, figure_manifest$pdf_path))$size > 0),
  all(figure_manifest$intended_display_width_mm == 170),
  all(figure_manifest$export_scale_multiplier == 1.5),
  all(figure_manifest$effective_final_text_pt >= 5)
)

figure_manifest <- figure_manifest |>
  mutate(
    visual_qa_status = paste(
      "PASS — inspected at 170 mm as final-size PNG and rendered PDF on",
      "2026-08-07; no clipping, overlap, distortion, awkward line breaks,",
      "or excess whitespace"
    )
  )

write_csv_artifact(
  figure_manifest,
  manifest_path,
  producer = "scripts/hypotheses/H09/finalize_h09_figure_qa.R"
)

message("H09 final-size figure QA status recorded")
