#!/usr/bin/env Rscript

# Independent infrastructure-only visual proofs for REPORT-018 Order 72b.
# This script reads frozen accepted PNGs and the separately rasterized,
# byte-preserved SVG candidates. It does not modify any owner artifact.

stopifnot(as.character(getRversion()) == "4.6.1")
stopifnot(requireNamespace("png", quietly = TRUE))
stopifnot(requireNamespace("digest", quietly = TRUE))

root <- normalizePath(".", mustWork = TRUE)
review_root <- file.path(
  root,
  "audit/report_harmonization/report018_order72_qa_recovery/reviewer"
)

cases <- data.frame(
  owner = c("H02", "H08", "H10", "H11"),
  accepted = c(
    "artifacts/10_figures/H02/figure4_exact_layout_replication.png",
    "artifacts/10_figures/H08/H08_near_eye_effects.png",
    "audit/manuscript_nature_health/figure_table_selection_assets/H10_age_site_significant_associations_selection_candidate.png",
    "artifacts/10_figures/H11/stage3/H11_reader_primary_near_eye_curves.png"
  ),
  candidate_original = c(
    "audit/report_harmonization/report018_order72_qa_recovery/reviewer/h02_original/figure4_exact_layout_replication_3300x4200_svg_raster.png",
    "audit/report_harmonization/report018_order72_qa_recovery/reviewer/h08_original/H08_near_eye_effects_2007x1606_svg_raster.png",
    "audit/report_harmonization/report018_order72_qa_recovery/reviewer/h10_original/H10_age_site_significant_associations_selection_candidate_2820x3900_svg_raster.png",
    "audit/report_harmonization/report018_order72_qa_recovery/reviewer/h11_original/H11_reader_primary_near_eye_curves_3150x3300_svg_raster.png"
  ),
  candidate_reader = c(
    "audit/report_harmonization/report018_order72_qa_recovery/reviewer/h02_reader/figure4_exact_layout_replication_680x865_svg_raster.png",
    "audit/report_harmonization/report018_order72_qa_recovery/reviewer/h08_reader/H08_near_eye_effects_643x514_svg_raster.png",
    "audit/report_harmonization/report018_order72_qa_recovery/reviewer/h10_reader/H10_age_site_significant_associations_selection_candidate_643x889_svg_raster.png",
    "audit/report_harmonization/report018_order72_qa_recovery/reviewer/h11_reader/H11_reader_primary_near_eye_curves_643x674_svg_raster.png"
  ),
  original_width = c(3300L, 2007L, 2820L, 3150L),
  original_height = c(4200L, 1606L, 3900L, 3300L),
  reader_width = c(680L, 643L, 643L, 643L),
  reader_height = c(865L, 514L, 889L, 674L),
  stringsAsFactors = FALSE
)

as_rgb <- function(image) {
  dims <- dim(image)
  stopifnot(length(dims) %in% 2:3)
  if (length(dims) == 2L) {
    return(array(rep(image, 3L), dim = c(dims, 3L)))
  }
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
  check <- png::readPNG(destination)
  stopifnot(dim(check)[[2]] == width, dim(check)[[1]] == height)
}

comparison <- function(left_path, right_path, destination, gap = 12L) {
  left <- as_rgb(png::readPNG(left_path))
  right <- as_rgb(png::readPNG(right_path))
  stopifnot(identical(dim(left), dim(right)))
  height <- dim(left)[[1]]
  width <- dim(left)[[2]]
  canvas <- array(1, dim = c(height, 2L * width + gap, 3L))
  canvas[, seq_len(width), ] <- left
  canvas[, width + gap + seq_len(width), ] <- right
  divider <- width + seq_len(gap)
  canvas[, divider, ] <- 0.92
  png::writePNG(canvas, destination)
  invisible(c(width = 2L * width + gap, height = height))
}

records <- vector("list", nrow(cases))
for (i in seq_len(nrow(cases))) {
  x <- cases[i, ]
  accepted <- file.path(root, x$accepted)
  candidate_original <- file.path(root, x$candidate_original)
  candidate_reader <- file.path(root, x$candidate_reader)
  stopifnot(file.exists(accepted), file.exists(candidate_original), file.exists(candidate_reader))

  accepted_image <- png::readPNG(accepted)
  candidate_original_image <- png::readPNG(candidate_original)
  candidate_reader_image <- png::readPNG(candidate_reader)
  stopifnot(
    dim(accepted_image)[[2]] == x$original_width,
    dim(accepted_image)[[1]] == x$original_height,
    dim(candidate_original_image)[[2]] == x$original_width,
    dim(candidate_original_image)[[1]] == x$original_height,
    dim(candidate_reader_image)[[2]] == x$reader_width,
    dim(candidate_reader_image)[[1]] == x$reader_height
  )

  case_dir <- file.path(review_root, tolower(x$owner))
  dir.create(case_dir, recursive = TRUE, showWarnings = FALSE)
  accepted_reader <- file.path(
    case_dir,
    sprintf("%s_accepted_reader_%dx%d.png", tolower(x$owner), x$reader_width, x$reader_height)
  )
  original_comparison <- file.path(
    case_dir,
    sprintf("%s_original_accepted_left_svg_right.png", tolower(x$owner))
  )
  reader_comparison <- file.path(
    case_dir,
    sprintf("%s_reader_accepted_left_svg_right.png", tolower(x$owner))
  )
  stopifnot(!file.exists(accepted_reader), !file.exists(original_comparison), !file.exists(reader_comparison))
  resize_png(accepted, accepted_reader, x$reader_width, x$reader_height)
  comparison(accepted, candidate_original, original_comparison)
  comparison(accepted_reader, candidate_reader, reader_comparison, gap = 8L)

  left <- as_rgb(accepted_image)
  right <- as_rgb(candidate_original_image)
  difference <- abs(left - right)
  records[[i]] <- data.frame(
    owner = x$owner,
    accepted_path = x$accepted,
    accepted_sha256 = digest::digest(file = accepted, algo = "sha256"),
    candidate_original_path = x$candidate_original,
    candidate_original_sha256 = digest::digest(file = candidate_original, algo = "sha256"),
    candidate_reader_path = x$candidate_reader,
    candidate_reader_sha256 = digest::digest(file = candidate_reader, algo = "sha256"),
    accepted_reader_path = sub(paste0("^", root, "/"), "", accepted_reader),
    original_comparison_path = sub(paste0("^", root, "/"), "", original_comparison),
    reader_comparison_path = sub(paste0("^", root, "/"), "", reader_comparison),
    original_width = x$original_width,
    original_height = x$original_height,
    reader_width = x$reader_width,
    reader_height = x$reader_height,
    mean_absolute_channel_difference = mean(difference),
    fraction_channel_difference_above_0_10 = mean(difference > 0.10),
    stringsAsFactors = FALSE
  )
}

evidence <- do.call(rbind, records)
evidence_path <- file.path(review_root, "visual_proof_inventory.csv")
stopifnot(!file.exists(evidence_path))
write.csv(evidence, evidence_path, row.names = FALSE)
cat("VISUAL_PROOFS=PASS rows=", nrow(evidence), " evidence=", evidence_path, "\n", sep = "")
