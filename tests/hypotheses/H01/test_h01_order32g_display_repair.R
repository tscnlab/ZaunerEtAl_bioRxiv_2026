#!/usr/bin/env Rscript

# Focused display-only contract for REPORT-017 H01 order 32g.

suppressPackageStartupMessages({
  library(digest)
  library(png)
  library(readr)
  library(xml2)
})

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("The H01 order-32g display test requires R 4.6.1", call. = FALSE)
}

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
evidence_dir <- file.path(
  root,
  "audit/hypotheses/H01/report017_order32g_continuation"
)

sha256_file <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
}

source_contract <- c(
  H01_stage3_METRIC011_l10_mean_medi_model_support_figure_source.csv =
    "cf869aa233aca9230a9d295f7efae69fc51c1258a80daf90258d08122f5effc0",
  H01_stage3_METRIC011_l10_mean_medi_paired_placement_figure_source.csv =
    "8e1672e499e6bee05cde70647165e780dfa5cb9195ed0c3f1bd203da5d838853",
  H01_stage3_diagnostic_figure_source.csv =
    "d9b424ae246fc688670a77a561717701fec3ddffaf000af72ea6b68f214b9397"
)
source_paths <- file.path(
  root,
  "artifacts/11_source_data/H01/stage3",
  names(source_contract)
)
source_actual <- vapply(source_paths, sha256_file, character(1))
if (!identical(unname(source_actual), unname(source_contract))) {
  stop("A frozen display source changed", call. = FALSE)
}

figure_contract <- c(
  H01_stage3_model_support.png =
    "a06d33e4d9708e7a60c0296a645b7c136ffea9f6be5bcf0c7a5e38615a3069de",
  H01_stage3_model_support.svg =
    "897e7b11a27136fd2f3ffca978af72c108ba1f443bb8941ce7d9a5515847e8ba",
  H01_stage3_paired_placement.png =
    "5ca5a91ed367bdf0158bae99a671819eccf14de0d06938c91a2268275998fee5",
  H01_stage3_paired_placement.svg =
    "87d0df52d9e5134b4a760cea63acd3bdd6f9bc82b675551a3325e30e3afa8a2b",
  H01_stage3_diagnostic_assessment.png =
    "103556d8d6ca681cb8fba1ba65f4b1d7d5839ee477215becdfbc7480af0613c4",
  H01_stage3_diagnostic_assessment.svg =
    "be25f8b9c83996a2e70cd7333283ae8111a659392f577f02a585508f37116f44"
)
figure_paths <- file.path(
  root,
  "artifacts/10_figures/H01/stage3",
  names(figure_contract)
)
figure_actual <- vapply(figure_paths, sha256_file, character(1))
if (!identical(unname(figure_actual), unname(figure_contract))) {
  stop("A repaired durable figure identity is not exact", call. = FALSE)
}

output_inventory <- read_csv(
  file.path(evidence_dir, "candidate_validation/output_inventory.csv"),
  show_col_types = FALSE
)
candidate_rows <- output_inventory[output_inventory$set == "candidate", ]
candidate_key <- paste0("H01_stage3_", candidate_rows$figure_id, ".", candidate_rows$format)
candidate_hash <- stats::setNames(candidate_rows$sha256, candidate_key)
if (
  nrow(candidate_rows) != 6L ||
    !identical(candidate_hash[names(figure_contract)], figure_contract)
) {
  stop("The durable figures do not equal the accepted candidate set", call. = FALSE)
}

geometry <- read_csv(
  file.path(evidence_dir, "candidate_validation/geometry_check.csv"),
  show_col_types = FALSE
)
if (
  nrow(geometry) != 3L ||
    !all(geometry$width_exact & geometry$height_exact & geometry$dpi_exact)
) {
  stop("The accepted candidate geometry is not exact", call. = FALSE)
}
structure <- read_csv(
  file.path(evidence_dir, "candidate_validation/svg_structure_check.csv"),
  show_col_types = FALSE
)
if (
  nrow(structure) != 3L ||
    !all(structure$node_structure_equal & structure$text_multiset_equal)
) {
  stop("The accepted candidate SVG contract is not exact", call. = FALSE)
}
typography <- read_csv(
  file.path(evidence_dir, "candidate_validation/typography_minimums.csv"),
  show_col_types = FALSE
)
if (
  nrow(typography) != 2L ||
    any(typography$minimum_final_size_pt_708 < 7)
) {
  stop("A repaired matrix contains text below 7 pt at 708 px", call. = FALSE)
}
collisions <- read_csv(
  file.path(evidence_dir, "candidate_validation/paired_label_collisions.csv"),
  show_col_types = FALSE
)
if (nrow(collisions) != 0L) {
  stop("The repaired paired-placement figure has a label collision", call. = FALSE)
}

expected_geometry <- list(
  H01_stage3_model_support.png = c(3360L, 2368L),
  H01_stage3_paired_placement.png = c(3840L, 2176L),
  H01_stage3_diagnostic_assessment.png = c(3680L, 2432L)
)
for (name in names(expected_geometry)) {
  image <- readPNG(
    file.path(root, "artifacts/10_figures/H01/stage3", name),
    native = TRUE,
    info = TRUE
  )
  info <- attr(image, "info")
  actual_dimension <- c(dim(image)[[2]], dim(image)[[1]])
  if (
    !identical(actual_dimension, expected_geometry[[name]]) ||
      any(abs(unname(info$dpi) - 320) >= 0.1)
  ) {
    stop("A repaired PNG has unexpected dimensions or DPI", call. = FALSE)
  }
}

builder_path <- file.path(
  root,
  "scripts/hypotheses/H01/build_h01_stage3_reporting_inputs.R"
)
builder <- paste(readLines(builder_path, warn = FALSE), collapse = "\n")
required_builder_literals <- c(
  "geom_text(aes(label = .data$support_symbol), size = 4.0, colour = \"#111111\")",
  "axis.text.x = element_text(size = 11.2, angle = 28, hjust = 1)",
  "axis.text.y = element_text(size = 11.2)",
  "legend.title = element_text(size = 11.2)",
  "geom_text(aes(label = .data$check_symbol), size = 4.3)",
  "axis.text.x = element_text(size = 12.2, angle = 28, hjust = 1)",
  "axis.text.y = element_text(size = 12.2)",
  "legend.title = element_text(size = 12.2)",
  "box.padding = 0.55",
  "point.padding = 0.32",
  "force = 8",
  "force_pull = 0.05",
  "max.iter = 100000",
  "max.time = 10"
)
if (!all(vapply(required_builder_literals, grepl, logical(1), x = builder, fixed = TRUE))) {
  stop("The accepted builder does not mirror every display literal", call. = FALSE)
}
parse(file = builder_path, keep.source = FALSE)

refresh_path <- file.path(
  root,
  "scripts/hypotheses/H01/refresh_h01_order32d_figures.R"
)
refresh <- paste(readLines(refresh_path, warn = FALSE), collapse = "\n")
required_refresh_literals <- c(
  "function(current_figure_id)",
  "current_paths <- candidate_paths[[current_figure_id]]",
  "candidate_png <- current_paths[[\"png\"]]",
  "baseline_specs$figure_id == current_figure_id",
  "drop = FALSE",
  "nrow(current_spec) != 1L",
  "expected_width = current_spec$png_width[[1]]",
  "expected_height = current_spec$png_height[[1]]"
)
if (!all(vapply(required_refresh_literals, grepl, logical(1), x = refresh, fixed = TRUE))) {
  stop("The scalar-safe refresh implementation is incomplete", call. = FALSE)
}
parse(file = refresh_path, keep.source = FALSE)

model_support_svg <- read_xml(
  file.path(
    root,
    "artifacts/10_figures/H01/stage3/H01_stage3_model_support.svg"
  )
)
if (
  length(xml_find_all(
    model_support_svg,
    ".//*[local-name()='text' and text()='FDR-adjusted result']"
  )) != 1L
) {
  stop("The repaired Figure 1 does not use the accepted FDR label", call. = FALSE)
}

cat(
  "H01_ORDER32G_DISPLAY_REPAIR=PASS\n",
  "R_VERSION=", as.character(getRversion()), "\n",
  "FROZEN_SOURCES=3/3\n",
  "DURABLE_FIGURES=6/6\n",
  "GEOMETRY=3/3\n",
  "SVG_STRUCTURE=3/3\n",
  "PAIRED_COLLISIONS=0\n",
  "BUILDER_LITERALS=14/14\n",
  sep = ""
)
