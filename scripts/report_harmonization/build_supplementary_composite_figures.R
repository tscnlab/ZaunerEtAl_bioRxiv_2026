#!/usr/bin/env Rscript

# Build manuscript-level Supplementary Figures S6 and S14 as single,
# owner-pinned composite assets. Scientific component images are embedded
# unchanged in the SVG wrappers. The 300-dpi PNG copies use nearest-neighbour
# raster placement and add only an external white tag band.

required_packages <- c("base64enc", "digest", "grid", "png", "ragg")
missing_packages <- required_packages[
  !vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
]
if (length(missing_packages)) {
  stop(
    "Missing required packages: ",
    paste(missing_packages, collapse = ", "),
    call. = FALSE
  )
}

required_r <- "4.6.1"
if (!identical(as.character(getRversion()), required_r)) {
  stop("This figure builder must run under R ", required_r, ".")
}

project_root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
setwd(project_root)

asset_dir <- file.path(
  "audit",
  "manuscript_nature_health",
  "figure_table_selection_assets"
)
dir.create(asset_dir, recursive = TRUE, showWarnings = FALSE)

sha256_file <- function(path) {
  digest::digest(file = path, algo = "sha256", serialize = FALSE)
}

specs <- list(
  supplementary_figure_s6 = list(
    panel_paths = c(
      "artifacts/10_figures/H01/stage3/H01_stage3_model_support.png",
      paste0(
        "artifacts/08_figures/H07/",
        "H07_revised_smooth_derivative_pairs_near_eye.png"
      )
    ),
    panel_hashes = c(
      "cff7d52c1483b1d90d9fc187a8797b58ec7f0707ec8fc14df7dde9cd08ee5696",
      "f19763fe3c14c723ac38846bf735c0465ba2ee18765777a4f7304c677be71113"
    ),
    title = paste(
      "Supplementary Figure S6: Geographic support and nonlinear",
      "photoperiod classifications"
    ),
    description = paste(
      "Two-panel figure. Panel A is an FDR support matrix for site, civil",
      "photoperiod, latitude, and site-versus-latitude adequacy across four",
      "separate 17-metric families. Panel B shows near-eye response smooths",
      "and first derivatives across observed civil photoperiod."
    )
  ),
  supplementary_figure_s14 = list(
    panel_paths = c(
      "artifacts/10_figures/H09/H09_primary_effects.png",
      "artifacts/10_figures/H09/H09_observed_timing_patterns.png"
    ),
    panel_hashes = c(
      "8525b9dda4a635efe2d8410e6eeb6a99722c6bc0d225f09abe684a73595dc4dd",
      "a23cb2a9a90a232ae9bf3f94ec7b1c5ac0e3c83933d056c0920ffd59e8e0eb59"
    ),
    title = "Supplementary Figure S14: Chronotype and light-exposure timing",
    description = paste(
      "Two-panel figure. Panel A shows study-site-adjusted chronotype",
      "associations with five timing metrics. Panel B shows observed",
      "participant-day timing values across chronotype and country-coded",
      "study sites."
    )
  )
)

canvas_width_px <- 2008L
gutter_px <- 48L
tag_band_px <- 52L
panel_width_px <- as.integer((canvas_width_px - gutter_px) / 2L)
tag_font_effective_pt <- 6.5
tag_font_px <- tag_font_effective_pt * 300 / 72
panel_x_px <- c(0L, panel_width_px + gutter_px)

source_records <- list()
layout_records <- list()

for (figure_name in names(specs)) {
  spec <- specs[[figure_name]]
  if (!all(file.exists(spec$panel_paths))) {
    stop("A component input is missing for ", figure_name, ".")
  }
  observed_hashes <- vapply(spec$panel_paths, sha256_file, character(1))
  if (!identical(unname(observed_hashes), unname(spec$panel_hashes))) {
    stop("A pinned component identity changed for ", figure_name, ".")
  }

  panels <- lapply(spec$panel_paths, png::readPNG, native = FALSE)
  source_dimensions <- t(vapply(
    panels,
    function(panel) c(height = dim(panel)[[1]], width = dim(panel)[[2]]),
    numeric(2)
  ))
  panel_height_px <- as.integer(round(
    panel_width_px * source_dimensions[, "height"] /
      source_dimensions[, "width"]
  ))
  canvas_height_px <- tag_band_px + max(panel_height_px)

  png_path <- file.path(asset_dir, paste0(figure_name, ".png"))
  ragg::agg_png(
    filename = png_path,
    width = canvas_width_px,
    height = canvas_height_px,
    units = "px",
    res = 300,
    background = "white",
    scaling = 1
  )
  grid::grid.newpage()
  grid::pushViewport(grid::viewport(
    x = 0,
    y = 0,
    width = 1,
    height = 1,
    just = c("left", "bottom"),
    xscale = c(0, canvas_width_px),
    yscale = c(0, canvas_height_px)
  ))
  for (panel_index in seq_along(panels)) {
    grid::grid.raster(
      panels[[panel_index]],
      x = grid::unit(
        panel_x_px[[panel_index]] + panel_width_px / 2,
        "native"
      ),
      y = grid::unit(
        canvas_height_px - tag_band_px - panel_height_px[[panel_index]] / 2,
        "native"
      ),
      width = grid::unit(panel_width_px, "native"),
      height = grid::unit(panel_height_px[[panel_index]], "native"),
      interpolate = FALSE
    )
    grid::grid.text(
      label = c("A", "B")[[panel_index]],
      x = grid::unit(panel_x_px[[panel_index]] + 4, "native"),
      y = grid::unit(canvas_height_px - tag_band_px / 2, "native"),
      just = c("left", "center"),
      gp = grid::gpar(
        col = "#17324D",
        fontsize = tag_font_effective_pt,
        fontface = "bold",
        fontfamily = "sans"
      )
    )
  }
  grid::popViewport()
  grDevices::dev.off()

  embedded_png <- vapply(
    spec$panel_paths,
    base64enc::base64encode,
    character(1),
    linewidth = 0
  )
  canvas_height_mm <- 170 * canvas_height_px / canvas_width_px
  svg_lines <- c(
    "<?xml version='1.0' encoding='UTF-8'?>",
    sprintf(
      paste0(
        "<svg xmlns='http://www.w3.org/2000/svg' ",
        "xmlns:xlink='http://www.w3.org/1999/xlink' ",
        "width='170mm' height='%.4fmm' viewBox='0 0 %d %d' ",
        "role='img' aria-labelledby='%s-title %s-desc'>"
      ),
      canvas_height_mm,
      canvas_width_px,
      canvas_height_px,
      figure_name,
      figure_name
    ),
    sprintf("<title id='%s-title'>%s</title>", figure_name, spec$title),
    sprintf("<desc id='%s-desc'>%s</desc>", figure_name, spec$description),
    sprintf(
      "<rect x='0' y='0' width='%d' height='%d' fill='#FFFFFF'/>",
      canvas_width_px,
      canvas_height_px
    ),
    sprintf(
      paste0(
        "<text id='%s-panel-tag-a' x='4' y='36' ",
        "font-family='Arial, Helvetica, sans-serif' font-size='%.3f' ",
        "font-weight='700' fill='#17324D'>A</text>"
      ),
      figure_name,
      tag_font_px
    ),
    sprintf(
      paste0(
        "<text id='%s-panel-tag-b' x='%d' y='36' ",
        "font-family='Arial, Helvetica, sans-serif' font-size='%.3f' ",
        "font-weight='700' fill='#17324D'>B</text>"
      ),
      figure_name,
      panel_x_px[[2]] + 4L,
      tag_font_px
    ),
    sprintf(
      paste0(
        "<image id='%s-panel-a' x='%d' y='%d' width='%d' height='%d' ",
        "preserveAspectRatio='none' href='data:image/png;base64,%s'/>"
      ),
      figure_name,
      panel_x_px[[1]],
      tag_band_px,
      panel_width_px,
      panel_height_px[[1]],
      embedded_png[[1]]
    ),
    sprintf(
      paste0(
        "<image id='%s-panel-b' x='%d' y='%d' width='%d' height='%d' ",
        "preserveAspectRatio='none' href='data:image/png;base64,%s'/>"
      ),
      figure_name,
      panel_x_px[[2]],
      tag_band_px,
      panel_width_px,
      panel_height_px[[2]],
      embedded_png[[2]]
    ),
    "</svg>"
  )
  svg_path <- file.path(asset_dir, paste0(figure_name, ".svg"))
  writeLines(svg_lines, svg_path, useBytes = TRUE)

  source_records[[figure_name]] <- data.frame(
    figure = figure_name,
    panel = c("A", "B"),
    path = spec$panel_paths,
    width_px = source_dimensions[, "width"],
    height_px = source_dimensions[, "height"],
    bytes = as.numeric(file.info(spec$panel_paths)$size),
    sha256 = observed_hashes,
    stringsAsFactors = FALSE
  )
  layout_records[[figure_name]] <- data.frame(
    figure = figure_name,
    panel = c("A", "B"),
    x_px = panel_x_px,
    y_px = rep(tag_band_px, 2L),
    width_px = rep(panel_width_px, 2L),
    height_px = panel_height_px,
    canvas_width_px = rep(canvas_width_px, 2L),
    canvas_height_px = rep(canvas_height_px, 2L),
    output_png = png_path,
    output_svg = svg_path,
    stringsAsFactors = FALSE
  )
}

source_identity <- do.call(rbind, source_records)
layout <- do.call(rbind, layout_records)
rownames(source_identity) <- NULL
rownames(layout) <- NULL
write.csv(
  source_identity,
  file.path(asset_dir, "supplementary_composite_source_identity.csv"),
  row.names = FALSE,
  na = ""
)
write.csv(
  layout,
  file.path(asset_dir, "supplementary_composite_layout.csv"),
  row.names = FALSE,
  na = ""
)

caption_alt_lines <- c(
  "# Supplementary composite caption and alternative-text record",
  "",
  "## Supplementary Figure S6",
  "",
  paste0(
    "Alternative text: Two-panel figure. Panel A is an FDR support matrix ",
    "for site, civil photoperiod, latitude, and site-versus-latitude ",
    "adequacy across four separate 17-metric families. Panel B shows ",
    "near-eye response smooths and first derivatives across observed civil ",
    "photoperiod."
  ),
  "",
  paste0(
    "Caption: Geographic and civil-photoperiod associations across near-eye ",
    "personal light-exposure metrics. Panel A shows evidence retained after ",
    "FDR adjustment for overall site, civil photoperiod, latitude, and ",
    "site-versus-linear-latitude adequacy. Panel B shows nonlinear ",
    "civil-photoperiod associations and their fitted slopes."
  ),
  "",
  "## Supplementary Figure S14",
  "",
  paste0(
    "Alternative text: Two-panel figure. Panel A shows study-site-adjusted ",
    "chronotype associations with five timing metrics. Panel B shows ",
    "observed participant-day timing values across chronotype and ",
    "country-coded study sites."
  ),
  "",
  paste0(
    "Caption: Chronotype and timing of personal light exposure. Panel A ",
    "shows study-site-adjusted associations of two separate chronotype ",
    "instruments with the analysed timing metrics. Panel B shows observed ",
    "participant-day timing values across chronotype and country-coded study ",
    "sites for the samples used in the corresponding models."
  )
)
writeLines(
  caption_alt_lines,
  file.path(asset_dir, "supplementary_composite_caption_alt_text.md"),
  useBytes = TRUE
)

writeLines(
  capture.output(utils::sessionInfo()),
  file.path(asset_dir, "supplementary_composite_builder_session_info.txt"),
  useBytes = TRUE
)

cat(
  "SUPPLEMENTARY_COMPOSITE_BUILD=PASS",
  paste0("figures=", length(specs)),
  paste0("R=", as.character(getRversion())),
  paste0("ragg=", as.character(packageVersion("ragg"))),
  "\n"
)
