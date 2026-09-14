#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE, warn = 2)

if (!requireNamespace("magick", quietly = TRUE)) {
  stop("The synchronized magick package is missing.", call. = FALSE)
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

groups <- list(
  c(
    "metrics",
    "formulas",
    "primary-samples",
    "near-eye-results"
  ),
  c(
    "chest-results",
    "paired-placement",
    "interactions",
    "qualified-diagnostics"
  ),
  c(
    "gap-sensitivity",
    "sensitivity-summary",
    "mean-timing-sensitivity"
  )
)

make_panel <- function(name) {
  path <- file.path(
    evidence_dir,
    sprintf("visual_table_%s_708px.png", name)
  )
  if (!file.exists(path)) {
    stop(sprintf("Missing table screenshot: %s", path), call. = FALSE)
  }
  image <- magick::image_read(path)
  info <- magick::image_info(image)
  label <- magick::image_blank(
    width = info$width,
    height = 38,
    color = "white"
  )
  label <- magick::image_annotate(
    label,
    sprintf("H09 table: %s", name),
    gravity = "west",
    location = "+10+0",
    size = 20,
    color = "black"
  )
  magick::image_append(c(label, image), stack = TRUE)
}

for (index in seq_along(groups)) {
  panels <- lapply(groups[[index]], make_panel)
  sheet <- magick::image_append(do.call(c, panels), stack = TRUE)
  magick::image_write(
    sheet,
    file.path(
      evidence_dir,
      sprintf("visual_table_contact_sheet_%d.png", index)
    ),
    format = "png"
  )
}

cat("H09_ORDER56B_TABLE_CONTACT_SHEETS=PASS sheets=3 tables=11\n")
