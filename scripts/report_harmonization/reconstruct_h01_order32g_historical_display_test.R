#!/usr/bin/env Rscript

# Reconstruct the immutable pre-order-32g H01 display test from the two exact
# source edits recorded by the H01 owner. This is a provenance operation only.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
source(file.path(root, "scripts/pipeline/paths_io.R"))

stopifnot(identical(as.character(getRversion()), "4.6.1"))

args <- commandArgs(trailingOnly = TRUE)
input_path <- if (length(args) >= 1L) {
  normalizePath(args[[1]], winslash = "/", mustWork = TRUE)
} else {
  file.path(
    root,
    "tests/hypotheses/H01/test_h01_stage3_model_support_display_refresh.R"
  )
}
output_path <- if (length(args) >= 2L) args[[2]] else tempfile(fileext = ".R")

expected_current <- c(
  sha256 = "dcd3e62574a493d18733a9cb50eb6eb9d7493f8ac7bbb27918dc6535dcd1a603",
  bytes = "8224"
)
expected_historical <- c(
  sha256 = "121135a4ea1c86cc6e11fc476615ee207fb34fe01270912d3f74ef2c8b5ad9cb",
  bytes = "6747"
)

stopifnot(
  identical(artifact_sha256(input_path), unname(expected_current[["sha256"]])),
  identical(as.character(file.info(input_path)$size), unname(expected_current[["bytes"]]))
)

lines <- readLines(input_path, warn = FALSE)

drop_exact_block <- function(lines, first_line, last_line) {
  start <- which(lines == first_line)
  stopifnot(length(start) == 1L)
  finish <- which(seq_along(lines) >= start & lines == last_line)
  stopifnot(length(finish) >= 1L)
  lines[-seq.int(start, finish[[1]])]
}

lines <- drop_exact_block(lines, "pre32g_png_relative <- paste0(", ")")
lines <- drop_exact_block(lines, "pre32g_svg_relative <- paste0(", ")")
lines <- lines[!lines %in% c(
  "  pre32g_png_relative,",
  "  pre32g_svg_relative,"
)]

builder_assertion <- which(
  lines == "    artifact_sha256(file.path(root, builder_relative)),"
)
stopifnot(
  length(builder_assertion) == 1L,
  lines[[builder_assertion - 1L]] == "  identical(",
  lines[[builder_assertion + 2L]] == "  ),",
  lines[[builder_assertion + 3L]] == "  identical("
)
lines <- lines[-seq.int(builder_assertion, builder_assertion + 3L)]

replace_exact <- function(lines, old, new) {
  index <- which(lines == old)
  stopifnot(length(index) == 1L)
  lines[[index]] <- new
  lines
}

lines <- replace_exact(
  lines,
  "    \"97b0ecdde86904ef97025901f315fb60cb516eb49281f38c53f63a782111f766\"",
  "    \"eca3e1e855314838c51172d3dd24922ac8e5db096b6c5e3b505d74853885b28c\""
)
lines <- replace_exact(
  lines,
  "post_png <- png::readPNG(file.path(root, pre32g_png_relative))",
  "post_png <- png::readPNG(file.path(root, png_relative))"
)
lines <- replace_exact(
  lines,
  "post_svg <- readLines(file.path(root, pre32g_svg_relative), warn = FALSE)",
  "post_svg <- readLines(file.path(root, svg_relative), warn = FALSE)"
)

loop_start <- which(lines == "for (index in seq_len(nrow(core_manifest))) {")
stopifnot(length(loop_start) == 1L)
loop_assertion <- which(
  seq_along(lines) > loop_start & lines == "  stopifnot("
)[[1]]
lines <- c(
  lines[seq_len(loop_start)],
  "  path <- file.path(root, core_manifest$path[[index]])",
  lines[loop_assertion:length(lines)]
)

message_start <- which(lines == "message(")
stopifnot(length(message_start) == 1L)
live_block_start <- max(which(
  seq_along(lines) < message_start & lines == "stopifnot("
))
live_block_end <- which(
  seq_along(lines) > live_block_start &
    seq_along(lines) < message_start &
    lines == ")"
)
stopifnot(length(live_block_end) >= 1L)
live_block_end <- live_block_end[[length(live_block_end)]]
stopifnot(lines[[live_block_end + 1L]] == "")
lines <- lines[-seq.int(live_block_start, live_block_end + 1L)]
lines <- replace_exact(
  lines,
  "  \"136 frozen cells, historical title-only transition, and current display repair\"",
  "  \"136 frozen cells and title-only PNG/SVG change\""
)
lines <- c(lines, "")

stopifnot(dir.exists(dirname(output_path)))
writeLines(lines, output_path, useBytes = TRUE)

stopifnot(
  identical(artifact_sha256(output_path), unname(expected_historical[["sha256"]])),
  identical(
    as.character(file.info(output_path)$size),
    unname(expected_historical[["bytes"]])
  )
)

cat(
  "H01_ORDER32G_HISTORICAL_DISPLAY_TEST_RECOVERY=PASS\n",
  "R_VERSION=", as.character(getRversion()), "\n",
  "CURRENT_SHA256=", expected_current[["sha256"]], "\n",
  "CURRENT_BYTES=", expected_current[["bytes"]], "\n",
  "RECOVERED_SHA256=", expected_historical[["sha256"]], "\n",
  "RECOVERED_BYTES=", expected_historical[["bytes"]], "\n",
  "OUTPUT=", normalizePath(output_path, winslash = "/", mustWork = TRUE), "\n",
  sep = ""
)
