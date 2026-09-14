#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE, warn = 2)

required_packages <- c("jsonlite", "magick")
missing_packages <- required_packages[
  !vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
]
if (length(missing_packages)) {
  stop(
    "Missing synchronized project package(s): ",
    paste(missing_packages, collapse = ", "),
    call. = FALSE
  )
}

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = "."),
  winslash = "/",
  mustWork = TRUE
)
evidence_dir <- file.path(
  root,
  "audit/hypotheses/H09/report018_order56b_environment_retry"
)

crop_endpoint <- function(full_page, endpoint, output_path) {
  x <- floor(endpoint$x)
  y <- floor(endpoint$y)
  width <- ceiling(endpoint$width)
  height <- ceiling(endpoint$height)
  geometry <- sprintf("%dx%d+%d+%d", width, height, x, y)
  crop <- magick::image_crop(
    full_page,
    geometry = geometry,
    gravity = "northwest",
    repage = TRUE
  )
  magick::image_write(crop, output_path, format = "png")
  data.frame(
    endpoint = endpoint$id,
    output_path = substring(output_path, nchar(root) + 2L),
    x = x,
    y = y,
    width = width,
    height = height,
    geometry = geometry,
    status = "PASS",
    stringsAsFactors = FALSE
  )
}

captures_708 <- jsonlite::fromJSON(
  file.path(evidence_dir, "browser_anchor_table_captures.json"),
  simplifyVector = TRUE
)
if (
  nrow(captures_708) != 11L ||
    any(captures_708$viewportWidth != 708) ||
    any(captures_708$x < 0) ||
    any(captures_708$y < 0) ||
    any(captures_708$y + captures_708$height >
      captures_708$viewportHeight)
) {
  stop("The anchored 708-pixel table capture contract failed.", call. = FALSE)
}
table_rows <- lapply(seq_len(nrow(captures_708)), function(index) {
  endpoint <- captures_708[index, , drop = FALSE]
  name <- sub("^tbl-h09-", "", endpoint$id)
  crop_endpoint(
    magick::image_read(endpoint$rawPath),
    endpoint,
    file.path(
      evidence_dir,
      sprintf("visual_table_%s_708px.png", name)
    )
  )
})

captures_170 <- jsonlite::fromJSON(
  file.path(evidence_dir, "browser_anchor_figure_captures.json"),
  simplifyVector = TRUE
)
if (
  nrow(captures_170) != 4L ||
    any(captures_170$viewportWidth != 694) ||
    any(captures_170$imgWidth != 643) ||
    any(!captures_170$complete) ||
    any(captures_170$x < 0) ||
    any(captures_170$y < 0) ||
    any(captures_170$y + captures_170$height >
      captures_170$viewportHeight)
) {
  stop("The exact 170-mm browser geometry failed.", call. = FALSE)
}
figure_rows <- lapply(seq_len(nrow(captures_170)), function(index) {
  endpoint <- captures_170[index, , drop = FALSE]
  name <- sub("^fig-h09-", "", endpoint$id)
  crop_endpoint(
    magick::image_read(endpoint$rawPath),
    endpoint,
    file.path(
      evidence_dir,
      sprintf("visual_finalsize_170mm_%s.png", name)
    )
  )
})

crop_audit <- do.call(rbind, c(table_rows, figure_rows))
utils::write.csv(
  crop_audit,
  file.path(evidence_dir, "visual_endpoint_crop_audit.csv"),
  row.names = FALSE,
  na = "",
  fileEncoding = "UTF-8"
)

cat(
  sprintf(
    "H09_ORDER56B_VISUAL_ENDPOINT_CROPS=PASS tables=%d figures=%d width170=643\n",
    length(table_rows),
    length(figure_rows)
  )
)
