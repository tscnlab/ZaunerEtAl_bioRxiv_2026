#!/usr/bin/env Rscript
# Infrastructure-only SVG comparison preparation. Never alters its source SVG.
args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) == 5L, as.character(getRversion()) == "4.6.1")
mode <- args[[1]]
source_svg <- normalizePath(args[[2]], mustWork = TRUE)
width_px <- as.integer(args[[3]])
height_px <- as.integer(args[[4]])
out <- normalizePath(args[[5]], mustWork = TRUE)
stopifnot(mode %in% c("prepare", "extract"), width_px > 0L, height_px > 0L,
          width_px <= 5000L, height_px <= 5000L)
sha <- function(p) digest::digest(file = p, algo = "sha256")
before <- sha(source_svg)
stem <- paste0(tools::file_path_sans_ext(basename(source_svg)), "_", width_px, "x", height_px)
wrapper_path <- file.path(out, paste0(stem, "_qa_wrapper.svg"))
evidence_path <- file.path(out, paste0(stem, "_wrapper_contract.csv"))
square <- max(width_px, height_px)
if (mode == "prepare") {
  stopifnot(!file.exists(wrapper_path), !file.exists(evidence_path))
  original <- xml2::read_xml(source_svg, options = "NONET")
  viewbox <- as.numeric(strsplit(xml2::xml_attr(original, "viewBox"), "[ ,]+")[[1]])
  stopifnot(length(viewbox) == 4L, all(is.finite(viewbox)), all(viewbox[3:4] > 0))
  relative_ratio_error <- abs((width_px / height_px) / (viewbox[[3]] / viewbox[[4]]) - 1)
  stopifnot(relative_ratio_error <= 0.002)
  wrapper <- xml2::read_xml(sprintf(
    '<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d"></svg>',
    square, square, square, square))
  inner <- xml2::xml_add_child(wrapper, original)
  old_attributes <- xml2::xml_attrs(inner)
  xml2::xml_set_attr(inner, "x", "0")
  xml2::xml_set_attr(inner, "y", "0")
  xml2::xml_set_attr(inner, "width", as.character(width_px))
  xml2::xml_set_attr(inner, "height", as.character(height_px))
  before_nodes <- xml2::xml_find_all(original, ".//*")
  after_nodes <- xml2::xml_find_all(inner, ".//*")
  stopifnot(length(before_nodes) == length(after_nodes),
            identical(vapply(before_nodes, as.character, character(1)),
                      vapply(after_nodes, as.character, character(1))),
            identical(xml2::xml_attr(inner, "viewBox"), xml2::xml_attr(original, "viewBox")))
  other_attributes <- setdiff(names(old_attributes), c("x", "y", "width", "height"))
  stopifnot(identical(xml2::xml_attrs(inner)[other_attributes], old_attributes[other_attributes]))
  xml2::write_xml(wrapper, wrapper_path)
  contract <- data.frame(source = source_svg, source_sha256 = before,
                         wrapper = wrapper_path, wrapper_sha256 = sha(wrapper_path),
                         width_px = width_px, height_px = height_px, square_px = square,
                         unchanged_inner_descendants = length(before_nodes),
                         relative_ratio_error = relative_ratio_error)
  write.csv(contract, evidence_path, row.names = FALSE)
  cat("WRAPPER_PREPARE=PASS", wrapper_path, "qlmanage_size", square, "\n")
} else {
  contract <- read.csv(evidence_path, stringsAsFactors = FALSE)
  stopifnot(nrow(contract) == 1L, before == contract$source_sha256,
            sha(wrapper_path) == contract$wrapper_sha256,
            contract$width_px == width_px, contract$height_px == height_px)
  thumbnail_path <- paste0(wrapper_path, ".png")
  a <- png::readPNG(thumbnail_path)
  stopifnot(dim(a)[1] == square, dim(a)[2] == square)
  pixels <- a[seq_len(height_px), seq_len(width_px), , drop = FALSE]
  dest <- file.path(out, paste0(stem, "_svg_raster.png"))
  stopifnot(!file.exists(dest))
  png::writePNG(pixels, dest)
  check <- png::readPNG(dest)
  stopifnot(identical(dim(check), dim(pixels)), max(abs(check - pixels)) <= 1 / 255)
  cat("WRAPPER_EXTRACT=PASS", dest, width_px, height_px, "source_sha256", before, "\n")
}
stopifnot(sha(source_svg) == before)
