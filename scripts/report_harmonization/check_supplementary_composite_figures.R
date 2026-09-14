#!/usr/bin/env Rscript

required_packages <- c("base64enc", "digest", "png", "xml2")
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
  stop("This figure check must run under R ", required_r, ".")
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
layout_path <- file.path(asset_dir, "supplementary_composite_layout.csv")
source_path <- file.path(
  asset_dir,
  "supplementary_composite_source_identity.csv"
)
visual_path <- file.path(asset_dir, "supplementary_composite_visual_qa.csv")

sha256_file <- function(path) {
  digest::digest(file = path, algo = "sha256", serialize = FALSE)
}

checks <- list()
add_check <- function(id, condition, evidence) {
  checks[[length(checks) + 1L]] <<- data.frame(
    check_id = id,
    status = if (isTRUE(condition)) "PASS" else "FAIL",
    evidence = evidence,
    stringsAsFactors = FALSE
  )
}

layout <- read.csv(layout_path, check.names = FALSE, stringsAsFactors = FALSE)
source_identity <- read.csv(
  source_path,
  check.names = FALSE,
  stringsAsFactors = FALSE
)
add_check(
  "layout_rows",
  nrow(layout) == 4L && identical(layout$panel, rep(c("A", "B"), 2L)),
  paste0("rows=", nrow(layout))
)
add_check(
  "source_rows",
  nrow(source_identity) == 4L && all(file.exists(source_identity$path)),
  paste0("rows=", nrow(source_identity))
)

observed_source_hashes <- vapply(
  source_identity$path,
  sha256_file,
  character(1)
)
add_check(
  "source_hashes",
  identical(unname(observed_source_hashes), unname(source_identity$sha256)),
  paste0("matched=", sum(observed_source_hashes == source_identity$sha256), "/4")
)

for (figure_name in unique(layout$figure)) {
  figure_layout <- layout[layout$figure == figure_name, , drop = FALSE]
  figure_sources <- source_identity[
    source_identity$figure == figure_name,
    ,
    drop = FALSE
  ]
  png_path <- unique(figure_layout$output_png)
  svg_path <- unique(figure_layout$output_svg)
  add_check(
    paste0(figure_name, "_outputs_exist"),
    length(png_path) == 1L && length(svg_path) == 1L &&
      file.exists(png_path) && file.exists(svg_path),
    paste(png_path, svg_path, sep = "; ")
  )

  output_png <- png::readPNG(png_path, native = FALSE)
  observed_png_dim <- dim(output_png)[1:2]
  expected_png_dim <- c(
    unique(figure_layout$canvas_height_px),
    unique(figure_layout$canvas_width_px)
  )
  add_check(
    paste0(figure_name, "_png_geometry"),
    identical(as.integer(observed_png_dim), as.integer(expected_png_dim)),
    paste(observed_png_dim, collapse = "x")
  )

  svg <- xml2::read_xml(svg_path)
  images <- xml2::xml_find_all(svg, ".//*[local-name()='image']")
  tags <- xml2::xml_find_all(svg, ".//*[local-name()='text']")
  add_check(
    paste0(figure_name, "_svg_structure"),
    length(images) == 2L &&
      length(tags) == 2L &&
      identical(xml2::xml_text(tags), c("A", "B")),
    paste0("images=", length(images), "; tags=", paste(xml2::xml_text(tags), collapse = ","))
  )
  add_check(
    paste0(figure_name, "_svg_panel_geometry"),
    identical(
      as.integer(xml2::xml_attr(images, "width")),
      as.integer(figure_layout$width_px)
    ) &&
      identical(
        as.integer(xml2::xml_attr(images, "height")),
        as.integer(figure_layout$height_px)
      ) &&
      all(xml2::xml_attr(images, "preserveAspectRatio") == "none"),
    "Equal panel widths, top alignment, and recorded aspect scaling"
  )

  hrefs <- xml2::xml_attr(images, "href")
  if (all(is.na(hrefs))) {
    hrefs <- xml2::xml_attr(images, "xlink:href")
  }
  embedded_raw <- lapply(
    sub("^data:image/png;base64,", "", hrefs),
    base64enc::base64decode
  )
  embedded_hashes <- vapply(
    embedded_raw,
    digest::digest,
    character(1),
    algo = "sha256",
    serialize = FALSE
  )
  add_check(
    paste0(figure_name, "_embedded_identity"),
    identical(unname(embedded_hashes), unname(figure_sources$sha256)),
    paste0("matched=", sum(embedded_hashes == figure_sources$sha256), "/2")
  )
}

add_check(
  "visual_qa_record",
  file.exists(visual_path) && {
    visual <- read.csv(visual_path, check.names = FALSE, stringsAsFactors = FALSE)
    nrow(visual) == 8L && all(visual$status == "PASS")
  },
  if (file.exists(visual_path)) visual_path else "missing"
)

verification <- do.call(rbind, checks)
verification_path <- file.path(
  asset_dir,
  "supplementary_composite_verification.csv"
)
write.csv(verification, verification_path, row.names = FALSE, na = "")
if (any(verification$status != "PASS")) {
  stop(
    "Supplementary composite verification failed: ",
    paste(verification$check_id[verification$status != "PASS"], collapse = ", "),
    call. = FALSE
  )
}

session_path <- file.path(
  asset_dir,
  "supplementary_composite_verification_session_info.txt"
)
writeLines(capture.output(utils::sessionInfo()), session_path, useBytes = TRUE)

manifest_paths <- c(
  source_identity$path,
  unique(layout$output_png),
  unique(layout$output_svg),
  "scripts/report_harmonization/build_supplementary_composite_figures.R",
  "scripts/report_harmonization/check_supplementary_composite_figures.R",
  layout_path,
  source_path,
  file.path(asset_dir, "supplementary_composite_caption_alt_text.md"),
  file.path(asset_dir, "supplementary_composite_builder_session_info.txt"),
  visual_path,
  verification_path,
  session_path
)
if (anyDuplicated(manifest_paths) || !all(file.exists(manifest_paths))) {
  stop("The supplementary composite manifest inputs are invalid.")
}
manifest <- data.frame(
  path = manifest_paths,
  bytes = as.numeric(file.info(manifest_paths)$size),
  sha256 = vapply(manifest_paths, sha256_file, character(1)),
  stringsAsFactors = FALSE
)
manifest_path <- file.path(
  asset_dir,
  "supplementary_composite_manifest.csv"
)
write.csv(manifest, manifest_path, row.names = FALSE, na = "")

cat(
  "SUPPLEMENTARY_COMPOSITE_CHECK=PASS",
  paste0("checks=", nrow(verification)),
  paste0("manifest=", nrow(manifest)),
  paste0("R=", as.character(getRversion())),
  "\n"
)
