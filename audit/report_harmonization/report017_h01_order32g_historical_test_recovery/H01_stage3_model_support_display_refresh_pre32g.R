# Verify the bounded H01 Stage 3 model-support FDR display refresh.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
source(file.path(root, "scripts/pipeline/paths_io.R"))

stopifnot(identical(as.character(getRversion()), "4.6.1"))

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
})

evidence_relative <-
  "audit/hypotheses/H01/report017_model_support_fdr_refresh"
source_relative <- paste0(
  "artifacts/11_source_data/H01/stage3/",
  "H01_stage3_METRIC011_l10_mean_medi_model_support_figure_source.csv"
)
historical_source_relative <- paste0(
  "artifacts/11_source_data/H01/stage3/",
  "H01_stage3_model_support_figure_source.csv"
)
builder_relative <-
  "scripts/hypotheses/H01/build_h01_stage3_reporting_inputs.R"
png_relative <-
  "artifacts/10_figures/H01/stage3/H01_stage3_model_support.png"
svg_relative <-
  "artifacts/10_figures/H01/stage3/H01_stage3_model_support.svg"
pre_png_relative <- file.path(
  evidence_relative,
  "H01_stage3_model_support_pre_refresh.png"
)
pre_svg_relative <- file.path(
  evidence_relative,
  "H01_stage3_model_support_pre_refresh.svg"
)
comparison_relative <- file.path(
  evidence_relative,
  "H01_model_support_fdr_refresh_sealed_source_comparison.csv"
)
png_difference_relative <- file.path(
  evidence_relative,
  "H01_model_support_fdr_refresh_png_difference.csv"
)
svg_difference_relative <- file.path(
  evidence_relative,
  "H01_model_support_fdr_refresh_svg_difference.csv"
)
core_manifest_relative <- file.path(
  evidence_relative,
  "H01_model_support_fdr_refresh_core_manifest.csv"
)

required <- c(
  source_relative,
  historical_source_relative,
  builder_relative,
  png_relative,
  svg_relative,
  pre_png_relative,
  pre_svg_relative,
  comparison_relative,
  png_difference_relative,
  svg_difference_relative,
  core_manifest_relative
)
stopifnot(all(file.exists(file.path(root, required))))

stopifnot(
  identical(
    artifact_sha256(file.path(root, source_relative)),
    "cf869aa233aca9230a9d295f7efae69fc51c1258a80daf90258d08122f5effc0"
  ),
  identical(
    artifact_sha256(file.path(root, historical_source_relative)),
    "2054c097bb6b901ebc12491c78082fe5a56ebca2ccc5e2c61afe7e21244c3772"
  ),
  identical(
    artifact_sha256(file.path(root, comparison_relative)),
    "b6d4caa0be10581d6b9580e3eaf893c90e15147366ecf94ab737cef547a23592"
  )
)

comparison <- readr::read_csv(
  file.path(root, comparison_relative),
  show_col_types = FALSE,
  progress = FALSE
)
stopifnot(
  comparison$result[comparison$check == "plot field equality"] == "PASS",
  comparison$result[comparison$check == "old rows"] == "136",
  comparison$result[comparison$check == "current rows"] == "136"
)

plot_fields <- strsplit(
  comparison$result[comparison$check == "plot fields"],
  "|",
  fixed = TRUE
)[[1]]
source_data <- readr::read_csv(
  file.path(root, source_relative),
  show_col_types = FALSE,
  progress = FALSE
)
plot_keys <- source_data |>
  select(all_of(plot_fields))
stopifnot(
  nrow(plot_keys) == 136L,
  nrow(distinct(plot_keys, across(all_of(plot_fields[1:6])))) == 136L,
  setequal(unique(plot_keys$support_status), c("Supported", "Not supported")),
  setequal(unique(plot_keys$support_symbol), c("✓", "–"))
)

builder_path <- file.path(root, builder_relative)
builder_raw <- readBin(builder_path, what = "raw", n = file.info(builder_path)$size)
builder_text <- rawToChar(builder_raw)
stopifnot(
  lengths(regmatches(
    builder_text,
    gregexpr("FDR-adjusted result", builder_text, fixed = TRUE)
  )) == 1L,
  !grepl("BH-adjusted result", builder_text, fixed = TRUE)
)
builder_reversed <- sub(
  "FDR-adjusted result",
  "BH-adjusted result",
  builder_text,
  fixed = TRUE
)
builder_reverse_path <- tempfile(fileext = ".R")
on.exit(unlink(builder_reverse_path), add = TRUE)
writeBin(charToRaw(builder_reversed), builder_reverse_path)
stopifnot(
  identical(
    artifact_sha256(builder_reverse_path),
    "eca3e1e855314838c51172d3dd24922ac8e5db096b6c5e3b505d74853885b28c"
  )
)

numeric_tokens <- function(text) {
  regmatches(
    text,
    gregexpr("(?<![A-Za-z_])[0-9]+(?:[.][0-9]+)?", text, perl = TRUE)
  )[[1]]
}
stopifnot(identical(numeric_tokens(builder_text), numeric_tokens(builder_reversed)))

pre_png <- png::readPNG(file.path(root, pre_png_relative))
post_png <- png::readPNG(file.path(root, png_relative))
stopifnot(
  identical(dim(pre_png), c(2368L, 3360L, 3L)),
  identical(dim(post_png), dim(pre_png))
)
png_info <- utils::read.csv(
  file.path(root, png_difference_relative),
  stringsAsFactors = FALSE
)
difference_mask <- apply(abs(pre_png - post_png) > 0, c(1, 2), any)
difference_index <- which(difference_mask, arr.ind = TRUE)
stopifnot(
  nrow(png_info) == 1L,
  png_info$width_pixels == 3360L,
  png_info$height_pixels == 2368L,
  png_info$dpi == 320,
  png_info$differences_confined_to_legend_title,
  png_info$all_pixels_outside_region_identical,
  nrow(difference_index) == png_info$differing_pixels,
  min(difference_index[, "col"]) == png_info$x_min,
  max(difference_index[, "col"]) == png_info$x_max,
  min(difference_index[, "row"]) == png_info$y_min,
  max(difference_index[, "row"]) == png_info$y_max,
  all(!difference_mask[
    seq_len(nrow(difference_mask)) < png_info$authorized_y_min |
      seq_len(nrow(difference_mask)) > png_info$authorized_y_max,
    ,
    drop = FALSE
  ])
)

pre_svg <- readLines(file.path(root, pre_svg_relative), warn = FALSE)
post_svg <- readLines(file.path(root, svg_relative), warn = FALSE)
pre_title <- grep("BH-adjusted result", pre_svg, fixed = TRUE)
post_title <- grep("FDR-adjusted result", post_svg, fixed = TRUE)
stopifnot(
  length(pre_title) == 1L,
  identical(post_title, pre_title),
  !any(grepl("BH-adjusted result", post_svg, fixed = TRUE)),
  identical(pre_svg[-pre_title], post_svg[-post_title])
)
svg_info <- utils::read.csv(
  file.path(root, svg_difference_relative),
  stringsAsFactors = FALSE
)
stopifnot(
  nrow(svg_info) == 1L,
  svg_info$differing_lines == 1L,
  svg_info$all_non_title_lines_identical
)

core_manifest <- readr::read_csv(
  file.path(root, core_manifest_relative),
  show_col_types = FALSE,
  progress = FALSE
)
stopifnot(
  !any(core_manifest$path == core_manifest_relative),
  !anyDuplicated(core_manifest$path),
  all(file.exists(file.path(root, core_manifest$path)))
)
for (index in seq_len(nrow(core_manifest))) {
  path <- file.path(root, core_manifest$path[[index]])
  stopifnot(
    identical(artifact_sha256(path), core_manifest$sha256[[index]]),
    identical(as.numeric(file.info(path)$size), core_manifest$bytes[[index]])
  )
}

message(
  "H01 Stage 3 model-support display refresh checks passed: ",
  "136 frozen cells and title-only PNG/SVG change"
)

