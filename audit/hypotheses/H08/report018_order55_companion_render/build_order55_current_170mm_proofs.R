#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE, warn = 2)

stop_unless <- function(value, message) {
  if (!isTRUE(value)) stop(message, call. = FALSE)
}

stop_unless(
  identical(as.character(getRversion()), "4.6.1"),
  sprintf("R 4.6.1 required, found %s", getRversion())
)
stop_unless(
  requireNamespace("png", quietly = TRUE),
  "The accepted project library must provide package 'png'"
)
stop_unless(
  requireNamespace("digest", quietly = TRUE),
  "The accepted project library must provide package 'digest'"
)

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
setwd(root)

evidence_relative <-
  "audit/hypotheses/H08/report018_order55_companion_render"
evidence_dir <- file.path(root, evidence_relative)

figures <- data.frame(
  figure_id = c(
    "fig-h08-prep-vlsq-distribution",
    "fig-h08-prep-sample-support",
    "fig-h08-prep-site-range"
  ),
  figure_path = file.path(
    "_build/nathealth/audit/hypotheses/H08",
    "H08_analysis_preparation_files/figure-html",
    c(
      "fig-h08-prep-vlsq-distribution-1.png",
      "fig-h08-prep-sample-support-1.png",
      "fig-h08-prep-site-range-1.png"
    )
  ),
  source_data_path = c(
    "artifacts/11_source_data/H08/H08_preparation_vlsq_score_distribution.csv",
    "artifacts/11_source_data/H08/H08_preparation_sample_support.csv",
    "artifacts/11_source_data/H08/H08_preparation_site_support_summary.csv"
  ),
  native_width_mm = rep(170, 3L),
  native_height_mm = c(4.6, 4.9, 5.9) * 25.4,
  intended_width_mm = rep(170, 3L),
  smallest_essential_nominal_text_pt = rep(8, 3L),
  stringsAsFactors = FALSE
)
figures$scale_factor <-
  figures$intended_width_mm / figures$native_width_mm
figures$effective_final_text_pt <-
  figures$smallest_essential_nominal_text_pt * figures$scale_factor

stop_unless(
  nrow(figures) == 3L &&
    !anyDuplicated(figures$figure_id) &&
    all(figures$scale_factor == 1) &&
    all(figures$effective_final_text_pt >= 7),
  "Order-55 170-mm figure registry violates the sealed geometry"
)

absolute_figures <- file.path(root, figures$figure_path)
absolute_sources <- file.path(root, figures$source_data_path)
stop_unless(all(file.exists(absolute_figures)), "A target PNG is missing")
stop_unless(all(file.exists(absolute_sources)), "A frozen source CSV is missing")

proof_paths <- file.path(
  evidence_dir,
  paste0("current_170mm_", figures$figure_id, "_A4.png")
)

for (index in seq_len(nrow(figures))) {
  figure_raster <- png::readPNG(absolute_figures[index])
  grDevices::png(
    filename = proof_paths[index],
    width = 210,
    height = 297,
    units = "mm",
    res = 150,
    type = "cairo-png",
    bg = "white"
  )
  grid::grid.newpage()
  grid::grid.rect(gp = grid::gpar(fill = "white", col = NA))
  grid::grid.lines(
    x = grid::unit(c(20, 20), "mm"),
    y = grid::unit(c(0, 297), "mm"),
    gp = grid::gpar(col = "#D1D5DB", lwd = 0.5)
  )
  grid::grid.lines(
    x = grid::unit(c(190, 190), "mm"),
    y = grid::unit(c(0, 297), "mm"),
    gp = grid::gpar(col = "#D1D5DB", lwd = 0.5)
  )
  figure_viewport <- grid::viewport(
    x = grid::unit(105, "mm"),
    y = grid::unit(148.5, "mm"),
    width = grid::unit(figures$intended_width_mm[index], "mm"),
    height = grid::unit(figures$native_height_mm[index], "mm")
  )
  grid::pushViewport(figure_viewport)
  grid::grid.raster(
    figure_raster,
    width = grid::unit(1, "npc"),
    height = grid::unit(1, "npc"),
    interpolate = TRUE
  )
  grid::grid.rect(gp = grid::gpar(fill = NA, col = "#9CA3AF", lwd = 0.5))
  grid::popViewport()
  grid::grid.text(
    paste0(
      figures$figure_id[index],
      " | current order-55 target | 170 mm on A4 portrait"
    ),
    x = grid::unit(20, "mm"),
    y = grid::unit(7, "mm"),
    just = c("left", "bottom"),
    gp = grid::gpar(fontsize = 6, col = "#4B5563")
  )
  grDevices::dev.off()
}

dimensions <- lapply(
  absolute_figures,
  function(path) dim(png::readPNG(path, native = TRUE))
)
figures$pixel_width <- vapply(dimensions, `[[`, integer(1), 2L)
figures$pixel_height <- vapply(dimensions, `[[`, integer(1), 1L)
figures$figure_sha256 <- vapply(
  absolute_figures,
  digest::digest,
  character(1),
  algo = "sha256",
  file = TRUE,
  serialize = FALSE
)
figures$figure_bytes <- unname(file.info(absolute_figures)$size)
figures$proof_path <- substring(proof_paths, nchar(root) + 2L)
figures$proof_sha256 <- vapply(
  proof_paths,
  digest::digest,
  character(1),
  algo = "sha256",
  file = TRUE,
  serialize = FALSE
)
figures$proof_bytes <- unname(file.info(proof_paths)$size)
figures$calculation_status <- "PASS"
figures$visual_inspection <- "PENDING"

registry_path <- file.path(evidence_dir, "current_170mm_proof_registry.csv")
utils::write.csv(
  figures,
  registry_path,
  row.names = FALSE,
  na = "",
  fileEncoding = "UTF-8"
)

cat(sprintf(
  paste0(
    "ORDER55_CURRENT_170MM_PROOFS=PASS figures=%d ",
    "minimum_effective_text_pt=%.1f evidence_only=TRUE\n"
  ),
  nrow(figures),
  min(figures$effective_final_text_pt)
))
