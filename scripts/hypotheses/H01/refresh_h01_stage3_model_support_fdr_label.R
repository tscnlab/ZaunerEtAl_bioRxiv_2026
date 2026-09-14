# Refresh only the H01 Stage 3 model-support legend from frozen plot data.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
source(file.path(root, "scripts/pipeline/paths_io.R"))

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("The H01 model-support display refresh requires R 4.6.1", call. = FALSE)
}

suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
  library(readr)
})

started <- Sys.time()
producer <-
  "scripts/hypotheses/H01/refresh_h01_stage3_model_support_fdr_label.R"
evidence_relative <-
  "audit/hypotheses/H01/report017_model_support_fdr_refresh"
evidence_root <- file.path(root, evidence_relative)
dir.create(evidence_root, recursive = TRUE, showWarnings = FALSE)

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
test_relative <-
  "tests/hypotheses/H01/test_h01_stage3_model_support_display_refresh.R"
png_relative <-
  "artifacts/10_figures/H01/stage3/H01_stage3_model_support.png"
svg_relative <-
  "artifacts/10_figures/H01/stage3/H01_stage3_model_support.svg"
comparison_external <-
  "/private/tmp/H01_VIS001_AUDIT.Ynn9ZM/support_source_comparison.csv"

source_path <- file.path(root, source_relative)
historical_source_path <- file.path(root, historical_source_relative)
builder_path <- file.path(root, builder_relative)
test_path <- file.path(root, test_relative)
png_path <- file.path(root, png_relative)
svg_path <- file.path(root, svg_relative)

expected <- c(
  source = "cf869aa233aca9230a9d295f7efae69fc51c1258a80daf90258d08122f5effc0",
  historical_source = "2054c097bb6b901ebc12491c78082fe5a56ebca2ccc5e2c61afe7e21244c3772",
  builder_pre = "eca3e1e855314838c51172d3dd24922ac8e5db096b6c5e3b505d74853885b28c",
  png_pre = "601c65eebff8260b9c19d6f5e3a6054799e1fb7fa7f39442745073cb36098e7a",
  svg_pre = "c054674bacdd41ca2d02fff0a784955dfd77caf7604dacc166ccd0c8e1cfc098",
  comparison = "b6d4caa0be10581d6b9580e3eaf893c90e15147366ecf94ab737cef547a23592"
)

required_paths <- c(
  source_path,
  historical_source_path,
  builder_path,
  test_path,
  png_path,
  svg_path,
  comparison_external
)
if (!all(file.exists(required_paths))) {
  stop(
    "A required H01 display-refresh input is missing: ",
    paste(required_paths[!file.exists(required_paths)], collapse = ", "),
    call. = FALSE
  )
}

stopifnot(
  identical(artifact_sha256(source_path), unname(expected[["source"]])),
  identical(
    artifact_sha256(historical_source_path),
    unname(expected[["historical_source"]])
  ),
  identical(artifact_sha256(png_path), unname(expected[["png_pre"]])),
  identical(artifact_sha256(svg_path), unname(expected[["svg_pre"]])),
  identical(
    artifact_sha256(comparison_external),
    unname(expected[["comparison"]])
  )
)

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
    unname(expected[["builder_pre"]])
  )
)

comparison_copy_relative <- file.path(
  evidence_relative,
  "H01_model_support_fdr_refresh_sealed_source_comparison.csv"
)
comparison_copy <- file.path(root, comparison_copy_relative)
if (!file.copy(comparison_external, comparison_copy, overwrite = TRUE)) {
  stop("Could not preserve the sealed source-comparison evidence", call. = FALSE)
}

comparison <- readr::read_csv(
  comparison_copy,
  show_col_types = FALSE,
  progress = FALSE
)
stopifnot(
  comparison$result[comparison$check == "R version"] ==
    "R version 4.6.1 (2026-06-24)",
  comparison$result[comparison$check == "old rows"] == "136",
  comparison$result[comparison$check == "current rows"] == "136",
  comparison$result[comparison$check == "plot field equality"] == "PASS"
)

plot_fields <- strsplit(
  comparison$result[comparison$check == "plot fields"],
  "|",
  fixed = TRUE
)[[1]]
expected_plot_fields <- c(
  "metric_order",
  "metric_id",
  "manuscript_name",
  "placement_label",
  "question_order",
  "question_id",
  "question_label",
  "support_status",
  "support_symbol"
)
stopifnot(identical(plot_fields, expected_plot_fields))

support_matrix <- readr::read_csv(
  source_path,
  show_col_types = FALSE,
  progress = FALSE
)
plot_keys <- support_matrix |>
  select(all_of(plot_fields)) |>
  arrange(
    .data$placement_label,
    .data$metric_order,
    .data$question_order
  )
stopifnot(
  nrow(plot_keys) == 136L,
  nrow(distinct(plot_keys, across(all_of(plot_fields[1:6])))) == 136L,
  identical(sort(unique(plot_keys$metric_order)), as.numeric(seq_len(17L))),
  identical(sort(unique(plot_keys$question_order)), as.numeric(seq_len(4L))),
  setequal(unique(plot_keys$placement_label), c("Near eye", "Chest")),
  setequal(
    unique(plot_keys$support_status),
    c("Supported", "Not supported")
  ),
  setequal(unique(plot_keys$support_symbol), c("✓", "–"))
)

plot_keys_relative <- file.path(
  evidence_relative,
  "H01_model_support_fdr_refresh_plot_keys.csv"
)
readr::write_csv(plot_keys, file.path(root, plot_keys_relative), na = "")

pre_png_relative <- file.path(
  evidence_relative,
  "H01_stage3_model_support_pre_refresh.png"
)
pre_svg_relative <- file.path(
  evidence_relative,
  "H01_stage3_model_support_pre_refresh.svg"
)
pre_png_path <- file.path(root, pre_png_relative)
pre_svg_path <- file.path(root, pre_svg_relative)
if (
  !file.copy(png_path, pre_png_path, overwrite = TRUE) ||
    !file.copy(svg_path, pre_svg_path, overwrite = TRUE)
) {
  stop("Could not preserve the pre-refresh display artifacts", call. = FALSE)
}
stopifnot(
  identical(artifact_sha256(pre_png_path), unname(expected[["png_pre"]])),
  identical(artifact_sha256(pre_svg_path), unname(expected[["svg_pre"]]))
)

metric_levels <- support_matrix |>
  distinct(.data$metric_order, .data$manuscript_name) |>
  arrange(.data$metric_order) |>
  pull(.data$manuscript_name) |>
  rev()
question_levels <- support_matrix |>
  distinct(.data$question_order, .data$question_label) |>
  arrange(.data$question_order) |>
  pull(.data$question_label)

make_support_plot <- function(legend_title) {
  support_matrix |>
    mutate(
      manuscript_name = factor(
        .data$manuscript_name,
        levels = metric_levels
      ),
      question_label = factor(
        .data$question_label,
        levels = question_levels
      ),
      placement_label = factor(
        .data$placement_label,
        levels = c("Near eye", "Chest")
      )
    ) |>
    ggplot(aes(x = .data$question_label, y = .data$manuscript_name)) +
    geom_tile(
      aes(fill = .data$support_status),
      colour = "white",
      linewidth = 0.35
    ) +
    geom_text(
      aes(label = .data$support_symbol),
      size = 3.2,
      colour = "#111111"
    ) +
    facet_wrap(vars(.data$placement_label), ncol = 2) +
    scale_fill_manual(
      values = c(
        Supported = "#88CCEE",
        `Not supported` = "#ECECEC",
        `Not estimable` = "#CC6677"
      ),
      drop = FALSE
    ) +
    labs(x = NULL, y = NULL, fill = legend_title) +
    theme_minimal(base_size = 9) +
    theme(
      panel.grid = element_blank(),
      axis.text.x = element_text(angle = 28, hjust = 1),
      strip.text = element_text(face = "bold"),
      legend.position = "bottom"
    )
}

old_reference_png <- tempfile(tmpdir = evidence_root, fileext = ".png")
old_reference_svg <- tempfile(tmpdir = evidence_root, fileext = ".svg")
new_candidate_png <- tempfile(tmpdir = evidence_root, fileext = ".png")
new_candidate_svg <- tempfile(tmpdir = evidence_root, fileext = ".svg")
on.exit(
  unlink(c(
    old_reference_png,
    old_reference_svg,
    new_candidate_png,
    new_candidate_svg
  )),
  add = TRUE
)

ggsave(
  old_reference_png,
  make_support_plot("BH-adjusted result"),
  width = 10.5,
  height = 7.4,
  units = "in",
  dpi = 320,
  bg = "white"
)
ggsave(
  old_reference_svg,
  make_support_plot("BH-adjusted result"),
  width = 10.5,
  height = 7.4,
  units = "in",
  bg = "white"
)
ggsave(
  new_candidate_png,
  make_support_plot("FDR-adjusted result"),
  width = 10.5,
  height = 7.4,
  units = "in",
  dpi = 320,
  bg = "white"
)
ggsave(
  new_candidate_svg,
  make_support_plot("FDR-adjusted result"),
  width = 10.5,
  height = 7.4,
  units = "in",
  bg = "white"
)

pre_png <- png::readPNG(pre_png_path)
reference_png <- png::readPNG(old_reference_png)
candidate_png <- png::readPNG(new_candidate_png)
stopifnot(
  identical(dim(pre_png), c(2368L, 3360L, 3L)),
  identical(dim(reference_png), dim(pre_png)),
  identical(dim(candidate_png), dim(pre_png)),
  identical(
    artifact_sha256(old_reference_png),
    unname(expected[["png_pre"]])
  ),
  identical(pre_png, reference_png)
)

pre_svg_text <- rawToChar(readBin(
  pre_svg_path,
  what = "raw",
  n = file.info(pre_svg_path)$size
))
reference_svg_text <- rawToChar(readBin(
  old_reference_svg,
  what = "raw",
  n = file.info(old_reference_svg)$size
))
candidate_svg_text <- rawToChar(readBin(
  new_candidate_svg,
  what = "raw",
  n = file.info(new_candidate_svg)$size
))
stopifnot(
  identical(
    artifact_sha256(old_reference_svg),
    unname(expected[["svg_pre"]])
  ),
  identical(pre_svg_text, reference_svg_text)
)

pre_svg_lines <- strsplit(pre_svg_text, "\n", fixed = TRUE)[[1]]
reference_svg_lines <- strsplit(reference_svg_text, "\n", fixed = TRUE)[[1]]
candidate_svg_lines <- strsplit(candidate_svg_text, "\n", fixed = TRUE)[[1]]
pre_title_index <- grep("BH-adjusted result", pre_svg_lines, fixed = TRUE)
candidate_title_index <- grep(
  "FDR-adjusted result",
  candidate_svg_lines,
  fixed = TRUE
)
stopifnot(
  length(pre_title_index) == 1L,
  identical(candidate_title_index, pre_title_index),
  length(pre_svg_lines) == length(candidate_svg_lines)
)

authorized_region <- c(x_min = 1540L, x_max = 1920L, y_min = 2240L, y_max = 2340L)
final_png <- reference_png
final_png[
  authorized_region[["y_min"]]:authorized_region[["y_max"]],
  authorized_region[["x_min"]]:authorized_region[["x_max"]],
] <- candidate_png[
  authorized_region[["y_min"]]:authorized_region[["y_max"]],
  authorized_region[["x_min"]]:authorized_region[["x_max"]],
]
png::writePNG(final_png, new_candidate_png, dpi = 320)
candidate_png <- png::readPNG(new_candidate_png)

final_svg_lines <- reference_svg_lines
final_svg_lines[[pre_title_index]] <-
  candidate_svg_lines[[candidate_title_index]]
final_svg_text <- paste(final_svg_lines, collapse = "\n")
if (endsWith(pre_svg_text, "\n")) {
  final_svg_text <- paste0(final_svg_text, "\n")
}
writeBin(charToRaw(final_svg_text), new_candidate_svg)
candidate_svg_text <- rawToChar(readBin(
  new_candidate_svg,
  what = "raw",
  n = file.info(new_candidate_svg)$size
))
candidate_svg_lines <- strsplit(candidate_svg_text, "\n", fixed = TRUE)[[1]]

pixel_difference <- apply(abs(pre_png - candidate_png) > 0, c(1, 2), any)
difference_index <- which(pixel_difference, arr.ind = TRUE)
stopifnot(nrow(difference_index) > 0L)
difference_bounds <- c(
  x_min = min(difference_index[, "col"]),
  x_max = max(difference_index[, "col"]),
  y_min = min(difference_index[, "row"]),
  y_max = max(difference_index[, "row"])
)
inside_authorized_region <-
  difference_bounds[["x_min"]] >= authorized_region[["x_min"]] &&
  difference_bounds[["x_max"]] <= authorized_region[["x_max"]] &&
  difference_bounds[["y_min"]] >= authorized_region[["y_min"]] &&
  difference_bounds[["y_max"]] <= authorized_region[["y_max"]]
stopifnot(inside_authorized_region)

if (!file.copy(new_candidate_png, png_path, overwrite = TRUE)) {
  stop("Could not install the refreshed H01 PNG", call. = FALSE)
}
if (!file.copy(new_candidate_svg, svg_path, overwrite = TRUE)) {
  stop("Could not install the refreshed H01 SVG", call. = FALSE)
}

post_png <- png::readPNG(png_path)
post_svg_text <- rawToChar(readBin(
  svg_path,
  what = "raw",
  n = file.info(svg_path)$size
))
stopifnot(
  identical(post_png, candidate_png),
  identical(post_svg_text, candidate_svg_text),
  grepl("FDR-adjusted result", post_svg_text, fixed = TRUE),
  !grepl("BH-adjusted result", post_svg_text, fixed = TRUE)
)

png_difference_relative <- file.path(
  evidence_relative,
  "H01_model_support_fdr_refresh_png_difference.csv"
)
readr::write_csv(
  tibble::tibble(
    pre_sha256 = unname(expected[["png_pre"]]),
    post_sha256 = artifact_sha256(png_path),
    width_pixels = dim(post_png)[[2]],
    height_pixels = dim(post_png)[[1]],
    dpi = 320,
    differing_pixels = nrow(difference_index),
    x_min = difference_bounds[["x_min"]],
    x_max = difference_bounds[["x_max"]],
    y_min = difference_bounds[["y_min"]],
    y_max = difference_bounds[["y_max"]],
    authorized_x_min = authorized_region[["x_min"]],
    authorized_x_max = authorized_region[["x_max"]],
    authorized_y_min = authorized_region[["y_min"]],
    authorized_y_max = authorized_region[["y_max"]],
    differences_confined_to_legend_title = inside_authorized_region,
    all_pixels_outside_region_identical = inside_authorized_region
  ),
  file.path(root, png_difference_relative),
  na = ""
)

svg_difference_relative <- file.path(
  evidence_relative,
  "H01_model_support_fdr_refresh_svg_difference.csv"
)
readr::write_csv(
  tibble::tibble(
    pre_sha256 = unname(expected[["svg_pre"]]),
    post_sha256 = artifact_sha256(svg_path),
    line_count_pre = length(pre_svg_lines),
    line_count_post = length(candidate_svg_lines),
    differing_lines = sum(pre_svg_lines != candidate_svg_lines),
    title_line = pre_title_index,
    all_non_title_lines_identical = identical(
      pre_svg_lines[-pre_title_index],
      candidate_svg_lines[-candidate_title_index]
    ),
    pre_title = pre_svg_lines[[pre_title_index]],
    post_title = candidate_svg_lines[[candidate_title_index]]
  ),
  file.path(root, svg_difference_relative),
  na = ""
)

versions_relative <- file.path(
  evidence_relative,
  "H01_model_support_fdr_refresh_package_versions.csv"
)
packages <- c("dplyr", "ggplot2", "png", "readr", "svglite", "tibble")
readr::write_csv(
  tibble::tibble(
    component = c("R", packages),
    version = c(
      as.character(getRversion()),
      vapply(packages, function(package) {
        as.character(utils::packageVersion(package))
      }, character(1))
    )
  ),
  file.path(root, versions_relative),
  na = ""
)

audit_relative <- file.path(
  evidence_relative,
  "H01_model_support_fdr_refresh_audit.csv"
)
audit <- tibble::tribble(
  ~check, ~status, ~evidence,
  "R version", "PASS", as.character(getRversion()),
  "frozen current source", "PASS", artifact_sha256(source_path),
  "historical source pinned but not read as plot data", "PASS", artifact_sha256(historical_source_path),
  "sealed comparison", "PASS", artifact_sha256(comparison_copy),
  "unique plotted cells", "PASS", as.character(nrow(plot_keys)),
  "support states and symbols", "PASS", "Supported/check and Not supported/dash only",
  "old-title reconstruction", "PASS", "Exact PNG pixels and exact SVG bytes",
  "builder reverse substitution", "PASS", unname(expected[["builder_pre"]]),
  "PNG dimensions", "PASS", "3360 x 2368",
  "PNG resolution", "PASS", "320 dpi",
  "PNG difference region", "PASS", paste(difference_bounds, collapse = ":"),
  "SVG normalized structure", "PASS", "All non-title lines byte-identical",
  "new legend title", "PASS", "FDR-adjusted result",
  "model or inference computation", "PASS", "None"
)
readr::write_csv(audit, file.path(root, audit_relative), na = "")

completed <- Sys.time()
execution_relative <- file.path(
  evidence_relative,
  "H01_model_support_fdr_refresh_execution.csv"
)
readr::write_csv(
  tibble::tibble(
    command = paste(
      "Rscript",
      "scripts/hypotheses/H01/refresh_h01_stage3_model_support_fdr_label.R"
    ),
    started_utc = format(started, tz = "UTC", usetz = TRUE),
    completed_utc = format(completed, tz = "UTC", usetz = TRUE),
    runtime_seconds = as.numeric(difftime(completed, started, units = "secs")),
    exit_status = 0L,
    producer = producer
  ),
  file.path(root, execution_relative),
  na = ""
)

core_manifest_relative <- file.path(
  evidence_relative,
  "H01_model_support_fdr_refresh_core_manifest.csv"
)
core_paths <- c(
  source_relative,
  historical_source_relative,
  builder_relative,
  producer,
  test_relative,
  png_relative,
  svg_relative,
  pre_png_relative,
  pre_svg_relative,
  comparison_copy_relative,
  plot_keys_relative,
  png_difference_relative,
  svg_difference_relative,
  versions_relative,
  audit_relative,
  execution_relative,
  file.path(
    evidence_relative,
    "H01_model_support_fdr_refresh_protected_inventory_pre.csv"
  ),
  file.path(
    evidence_relative,
    "collect_h01_report017_31f_inventory.R"
  )
)
core_absolute <- file.path(root, core_paths)
stopifnot(all(file.exists(core_absolute)))
core_manifest <- tibble::tibble(
  path = core_paths,
  sha256 = vapply(core_absolute, artifact_sha256, character(1)),
  bytes = unname(file.info(core_absolute)$size),
  role = if_else(
    core_paths %in% c(source_relative, historical_source_relative),
    "frozen provenance input",
    "H01 model-support FDR display refresh evidence"
  ),
  producer = producer,
  r_version = as.character(getRversion())
)
readr::write_csv(
  core_manifest,
  file.path(root, core_manifest_relative),
  na = ""
)

message(
  "H01 model-support display refreshed: 136 frozen cells; PNG differences ",
  "confined to legend-title region; SVG differs only on the title line"
)
