#!/usr/bin/env Rscript

# Independent H05 visual proofs for REPORT-018 Orders 72b and 72c.

stopifnot(as.character(getRversion()) == "4.6.1")
stopifnot(requireNamespace("png", quietly = TRUE))
stopifnot(requireNamespace("digest", quietly = TRUE))

root <- normalizePath(".", mustWork = TRUE)
review_root <- file.path(
  root,
  "audit/report_harmonization/report018_order72_qa_recovery/reviewer"
)
case_dir <- file.path(review_root, "h05")
dir.create(case_dir, recursive = TRUE, showWarnings = FALSE)

accepted <- file.path(root, "artifacts/10_figures/H05/H05_reader_near_eye_effects.png")
candidate_original <- file.path(
  review_root,
  "h05_original/H05_reader_near_eye_effects_2700x2700_svg_raster.png"
)
candidate_reader <- file.path(
  review_root,
  "h05_reader/H05_reader_near_eye_effects_643x643_svg_raster.png"
)
accepted_reader <- file.path(case_dir, "h05_accepted_reader_643x643.png")
original_comparison <- file.path(case_dir, "h05_original_accepted_left_svg_right.png")
reader_comparison <- file.path(case_dir, "h05_reader_accepted_left_svg_right.png")
evidence_path <- file.path(case_dir, "h05_visual_proof_inventory.csv")
stopifnot(
  all(file.exists(c(accepted, candidate_original, candidate_reader))),
  !any(file.exists(c(accepted_reader, original_comparison, reader_comparison, evidence_path)))
)

as_rgb <- function(image) {
  dims <- dim(image)
  if (length(dims) == 2L) return(array(rep(image, 3L), dim = c(dims, 3L)))
  if (dims[[3]] == 3L) return(image)
  stopifnot(dims[[3]] == 4L)
  alpha <- image[, , 4L]
  out <- image[, , 1:3, drop = FALSE]
  for (channel in seq_len(3L)) {
    out[, , channel] <- out[, , channel] * alpha + (1 - alpha)
  }
  out
}

resize_png <- function(source, destination, width, height) {
  image <- png::readPNG(source)
  grDevices::png(
    destination,
    width = width,
    height = height,
    units = "px",
    bg = "white",
    type = "cairo-png"
  )
  grid::grid.newpage()
  grid::grid.raster(
    image,
    x = 0,
    y = 0,
    width = grid::unit(1, "npc"),
    height = grid::unit(1, "npc"),
    just = c("left", "bottom"),
    interpolate = TRUE
  )
  invisible(grDevices::dev.off())
}

comparison <- function(left_path, right_path, destination, gap) {
  left <- as_rgb(png::readPNG(left_path))
  right <- as_rgb(png::readPNG(right_path))
  stopifnot(identical(dim(left), dim(right)))
  height <- dim(left)[[1]]
  width <- dim(left)[[2]]
  canvas <- array(1, dim = c(height, 2L * width + gap, 3L))
  canvas[, seq_len(width), ] <- left
  canvas[, width + gap + seq_len(width), ] <- right
  canvas[, width + seq_len(gap), ] <- 0.92
  png::writePNG(canvas, destination)
}

accepted_image <- png::readPNG(accepted)
original_image <- png::readPNG(candidate_original)
reader_image <- png::readPNG(candidate_reader)
stopifnot(
  identical(dim(accepted_image)[1:2], c(2700L, 2700L)),
  identical(dim(original_image)[1:2], c(2700L, 2700L)),
  identical(dim(reader_image)[1:2], c(643L, 643L))
)
resize_png(accepted, accepted_reader, 643L, 643L)
comparison(accepted, candidate_original, original_comparison, 12L)
comparison(accepted_reader, candidate_reader, reader_comparison, 8L)

difference <- abs(as_rgb(accepted_image) - as_rgb(original_image))
record <- data.frame(
  owner = "H05",
  accepted_path = sub(paste0("^", root, "/"), "", accepted),
  accepted_sha256 = digest::digest(file = accepted, algo = "sha256"),
  candidate_original_path = sub(paste0("^", root, "/"), "", candidate_original),
  candidate_original_sha256 = digest::digest(file = candidate_original, algo = "sha256"),
  candidate_reader_path = sub(paste0("^", root, "/"), "", candidate_reader),
  candidate_reader_sha256 = digest::digest(file = candidate_reader, algo = "sha256"),
  accepted_reader_path = sub(paste0("^", root, "/"), "", accepted_reader),
  original_comparison_path = sub(paste0("^", root, "/"), "", original_comparison),
  reader_comparison_path = sub(paste0("^", root, "/"), "", reader_comparison),
  original_width = 2700L,
  original_height = 2700L,
  reader_width = 643L,
  reader_height = 643L,
  mean_absolute_channel_difference = mean(difference),
  fraction_channel_difference_above_0_10 = mean(difference > 0.10),
  stringsAsFactors = FALSE
)
write.csv(record, evidence_path, row.names = FALSE)
cat("H05_VISUAL_PROOFS=PASS evidence=", evidence_path, "\n", sep = "")
