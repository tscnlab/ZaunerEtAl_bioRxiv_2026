#!/usr/bin/env Rscript

# One non-mutating scalar-geometry preflight for REPORT-017 order 32g.

suppressPackageStartupMessages({
  library(digest)
  library(dplyr)
  library(png)
  library(readr)
  library(tibble)
  library(xml2)
})

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("Order 32g requires R 4.6.1", call. = FALSE)
}

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
order32e_dir <- "/private/tmp/H01-order32e-candidates.hltKEs"
order32f_dir <- "/private/tmp/H01-order32f-candidates.eDOsrp"
quarantine_dir <- "/private/tmp/H01-order32d-quarantine.Xc28uF"
old_failed_dir <- "/private/tmp/H01-order32d-candidates.nW90PN"

sha256_file <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
}

png_metadata <- function(path) {
  image <- png::readPNG(path, native = TRUE, info = TRUE)
  info <- attr(image, "info")
  tibble(
    png_width = dim(image)[[2]],
    png_height = dim(image)[[1]],
    dpi_x = unname(info$dpi[[1]]),
    dpi_y = unname(info$dpi[[2]])
  )
}

svg_inventory <- function(path) {
  doc <- xml2::read_xml(path)
  nodes <- xml2::xml_find_all(doc, ".//*")
  tibble(node_name = xml2::xml_name(nodes)) |>
    count(.data$node_name, name = "n") |>
    arrange(.data$node_name)
}

svg_text_inventory <- function(path) {
  doc <- xml2::read_xml(path)
  nodes <- xml2::xml_find_all(doc, ".//*[local-name()='text']")
  tibble(text = xml2::xml_text(nodes)) |>
    count(.data$text, name = "n") |>
    arrange(.data$text)
}

font_sizes <- function(svg_path) {
  doc <- xml2::read_xml(svg_path)
  nodes <- xml2::xml_find_all(doc, ".//*[local-name()='text']")
  styles <- xml2::xml_attr(nodes, "style")
  sizes <- vapply(
    styles,
    function(value) {
      match <- regmatches(value, regexpr("font-size: [0-9.]+px", value))
      if (!length(match) || identical(match, "")) {
        return(NA_real_)
      }
      as.numeric(sub(
        "font-size: ",
        "",
        sub("px", "", match, fixed = TRUE),
        fixed = TRUE
      ))
    },
    numeric(1)
  )
  sizes[is.finite(sizes)]
}

baseline_specs <- tribble(
  ~figure_id, ~png_width, ~png_height, ~source_png, ~source_svg, ~sealed_png, ~sealed_svg,
  "model_support",
  3360L,
  2368L,
  "2e3b1ddb7954584a70ff9d434cc862f9d1769dc45be607d2ca34840cbc9c1760",
  "12e4cf421a844da11844444e41601dec5e559e28b4ad77ac0081bd9ef2cfddcd",
  "2244f043d4fb676200524440098be223e23106578513f4ac61567ba3f636da8b",
  "602dd62de063d3e12ac53ca7d22dd2563e64213255b9cdc7e138941450ce1966",
  "paired_placement",
  3840L,
  2176L,
  "866670f47457bf304467e787481589298d9b7cf7c2c5de560ac9500f044c4608",
  "fe101f32cb0ffd4912b81ddbad4090c9558263aa85cc4f13ecad73369ac074f0",
  "866670f47457bf304467e787481589298d9b7cf7c2c5de560ac9500f044c4608",
  "fe101f32cb0ffd4912b81ddbad4090c9558263aa85cc4f13ecad73369ac074f0",
  "diagnostic_assessment",
  3680L,
  2432L,
  "95f46b0909b43c9b281a93a860d577b38a7753cb4d151ad751e2aca8a017b12d",
  "a15b3bae14b1b76d5a48ae9a21d0eb86dfd264db238179fb2a4486c002876a52",
  "95f46b0909b43c9b281a93a860d577b38a7753cb4d151ad751e2aca8a017b12d",
  "a15b3bae14b1b76d5a48ae9a21d0eb86dfd264db238179fb2a4486c002876a52"
)

candidate_paths <- lapply(baseline_specs$figure_id, function(id) {
  stem <- file.path(order32f_dir, "attempt01", paste0("H01_stage3_", id))
  c(png = paste0(stem, ".png"), svg = paste0(stem, ".svg"))
})
names(candidate_paths) <- baseline_specs$figure_id
baseline_paths <- lapply(baseline_specs$figure_id, function(id) {
  stem <- file.path(order32f_dir, "baseline", paste0("H01_stage3_", id))
  c(png = paste0(stem, ".png"), svg = paste0(stem, ".svg"))
})
names(baseline_paths) <- baseline_specs$figure_id

geometry_rows <- function(candidate_paths, baseline_specs) {
  bind_rows(lapply(names(candidate_paths), function(current_figure_id) {
    current_paths <- candidate_paths[[current_figure_id]]
    candidate_png <- current_paths[["png"]]
    current_spec <- baseline_specs[
      baseline_specs$figure_id == current_figure_id,
      ,
      drop = FALSE
    ]
    if (nrow(current_spec) != 1L) {
      stop(
        "A candidate figure does not have exactly one geometry specification",
        call. = FALSE
      )
    }
    actual <- png_metadata(candidate_png)
    actual |>
      mutate(
        figure_id = current_figure_id,
        expected_width = current_spec$png_width[[1]],
        expected_height = current_spec$png_height[[1]],
        width_exact = .data$png_width == .data$expected_width,
        height_exact = .data$png_height == .data$expected_height,
        dpi_exact = abs(.data$dpi_x - 320) < 0.1 &
          abs(.data$dpi_y - 320) < 0.1
      )
  }))
}

geometry <- geometry_rows(candidate_paths, baseline_specs)
if (
  nrow(geometry) != 3L ||
    !identical(geometry$figure_id, baseline_specs$figure_id) ||
    !all(geometry$width_exact & geometry$height_exact & geometry$dpi_exact)
) {
  stop("The scalar-safe geometry contract failed", call. = FALSE)
}

source_specs <- tribble(
  ~name, ~path, ~sha256, ~rows,
  "support",
  "artifacts/11_source_data/H01/stage3/H01_stage3_METRIC011_l10_mean_medi_model_support_figure_source.csv",
  "cf869aa233aca9230a9d295f7efae69fc51c1258a80daf90258d08122f5effc0",
  136L,
  "paired",
  "artifacts/11_source_data/H01/stage3/H01_stage3_METRIC011_l10_mean_medi_paired_placement_figure_source.csv",
  "8e1672e499e6bee05cde70647165e780dfa5cb9195ed0c3f1bd203da5d838853",
  30L,
  "diagnostic",
  "artifacts/11_source_data/H01/stage3/H01_stage3_diagnostic_figure_source.csv",
  "d9b424ae246fc688670a77a561717701fec3ddffaf000af72ea6b68f214b9397",
  204L
)

read_frozen <- function(spec) {
  path <- file.path(root, spec$path[[1]])
  if (!file.exists(path) || sha256_file(path) != spec$sha256[[1]]) {
    stop("Frozen source identity mismatch: ", spec$path[[1]], call. = FALSE)
  }
  value <- read_csv(path, show_col_types = FALSE, progress = FALSE)
  if (nrow(value) != spec$rows[[1]]) {
    stop("Frozen source row-count mismatch: ", spec$path[[1]], call. = FALSE)
  }
  value
}

support <- read_frozen(source_specs[1, ])
paired <- read_frozen(source_specs[2, ])
diagnostic <- read_frozen(source_specs[3, ])
if (
  nrow(distinct(support, .data$placement_label, .data$metric_order, .data$question_order)) != 136L ||
    nrow(distinct(paired, .data$effect_scale, .data$point_label)) != 30L ||
    nrow(distinct(
      diagnostic,
      .data$placement_label,
      .data$metric_order,
      .data$check_order
    )) != 204L ||
    !identical(sort(unique(support$support_status)), c("Not supported", "Supported")) ||
    !identical(
      sort(unique(diagnostic$check_status)),
      c("Not applicable", "Pass", "Review")
    ) ||
    !identical(sort(unique(paired$effect_scale)), c("Difference", "Ratio")) ||
    !all(paired$sample_exactly_matched)
) {
  stop("A frozen source contract changed", call. = FALSE)
}

refresh_source <- readLines(
  file.path(root, "scripts/hypotheses/H01/refresh_h01_order32d_figures.R"),
  warn = FALSE,
  encoding = "UTF-8"
)
if (
  !any(grepl("`Not estimable` = \"#CC6677\"", refresh_source, fixed = TRUE)) ||
    !any(grepl("Fail = \"#CC6677\"", refresh_source, fixed = TRUE))
) {
  stop("A broader unused plotting level was removed", call. = FALSE)
}

structure <- bind_rows(lapply(names(candidate_paths), function(id) {
  tibble(
    figure_id = id,
    node_structure_equal = identical(
      svg_inventory(baseline_paths[[id]][["svg"]]),
      svg_inventory(candidate_paths[[id]][["svg"]])
    ),
    text_multiset_equal = identical(
      svg_text_inventory(baseline_paths[[id]][["svg"]]),
      svg_text_inventory(candidate_paths[[id]][["svg"]])
    )
  )
}))
if (
  nrow(structure) != 3L ||
    !all(structure$node_structure_equal & structure$text_multiset_equal)
) {
  stop("A retained candidate changed SVG structure or visible text", call. = FALSE)
}

paired_doc <- read_xml(candidate_paths$paired_placement[["svg"]])
paired_nodes <- xml_find_all(paired_doc, ".//*[local-name()='text']")
paired_values <- xml_text(paired_nodes)
paired_nodes <- paired_nodes[paired_values %in% paired$point_label]
paired_values <- xml_text(paired_nodes)
if (
  length(paired_values) != 30L ||
    anyDuplicated(paired_values) ||
    !identical(sort(paired_values), sort(paired$point_label))
) {
  stop("The paired candidate label set is not exact", call. = FALSE)
}
raw_width <- xml_attr(paired_nodes, "textLength")
if (
  length(raw_width) != 30L ||
    anyNA(raw_width) ||
    !all(grepl("^[0-9]+(?:\\.[0-9]+)?px$", raw_width, perl = TRUE))
) {
  stop("A paired candidate textLength is invalid", call. = FALSE)
}
width <- as.numeric(sub("px$", "", raw_width))
if (any(!is.finite(width))) {
  stop("A paired candidate textLength is nonfinite", call. = FALSE)
}
styles <- xml_attr(paired_nodes, "style")
font_size <- vapply(styles, function(value) {
  match <- regmatches(value, regexpr("font-size: [0-9.]+px", value))
  as.numeric(sub(
    "font-size: ",
    "",
    sub("px", "", match, fixed = TRUE),
    fixed = TRUE
  ))
}, numeric(1))
x <- as.numeric(xml_attr(paired_nodes, "x"))
y <- as.numeric(xml_attr(paired_nodes, "y"))
anchor <- xml_attr(paired_nodes, "text-anchor")
xmin <- ifelse(anchor == "middle", x - width / 2, x)
xmax <- ifelse(anchor == "middle", x + width / 2, x + width)
ymin <- y - 0.82 * font_size
ymax <- y + 0.22 * font_size
pairs <- utils::combn(seq_along(paired_values), 2L)
collision <- apply(pairs, 2L, function(index) {
  x_overlap <- min(xmax[index]) - max(xmin[index])
  y_overlap <- min(ymax[index]) - max(ymin[index])
  x_overlap > -0.5 && y_overlap > -0.5
})
if (any(collision)) {
  stop("The retained paired candidate has a label collision", call. = FALSE)
}

minimum_final_text <- c(
  model_support = min(font_sizes(candidate_paths$model_support[["svg"]])) *
    642 / (10.5 * 96),
  diagnostic_assessment = min(font_sizes(
    candidate_paths$diagnostic_assessment[["svg"]]
  )) * 642 / (11.5 * 96)
)
if (any(!is.finite(minimum_final_text)) || any(minimum_final_text < 7)) {
  stop("A retained candidate has text below 7 pt at 708 px", call. = FALSE)
}

baseline_hashes <- unlist(lapply(names(baseline_paths), function(id) {
  c(
    png = sha256_file(baseline_paths[[id]][["png"]]),
    svg = sha256_file(baseline_paths[[id]][["svg"]])
  )
}), use.names = FALSE)
expected_baseline_hashes <- as.vector(t(as.matrix(
  baseline_specs[, c("source_png", "source_svg")]
)))
if (!identical(baseline_hashes, expected_baseline_hashes)) {
  stop("A source-derived baseline identity changed", call. = FALSE)
}

durable_stem <- file.path(
  root,
  "artifacts/10_figures/H01/stage3/H01_stage3_model_support"
)
sealed_png <- paste0(durable_stem, ".png")
sealed_svg <- paste0(durable_stem, ".svg")
if (
  sha256_file(sealed_png) != baseline_specs$sealed_png[[1]] ||
    sha256_file(sealed_svg) != baseline_specs$sealed_svg[[1]]
) {
  stop("The sealed Figure 1 identity changed", call. = FALSE)
}
sealed_raster <- readPNG(sealed_png)
source_raster <- readPNG(baseline_paths$model_support[["png"]])
changed_pixels <- which(
  apply(abs(sealed_raster - source_raster), c(1, 2), max) > 0,
  arr.ind = TRUE
)
if (
  nrow(changed_pixels) != 9477L ||
    !identical(range(changed_pixels[, "col"]), c(1927L, 2496L)) ||
    !identical(range(changed_pixels[, "row"]), c(2256L, 2325L))
) {
  stop("The Figure 1 raster provenance transition is not exact", call. = FALSE)
}
sealed_lines <- readLines(sealed_svg, warn = FALSE, encoding = "UTF-8")
source_lines <- readLines(
  baseline_paths$model_support[["svg"]],
  warn = FALSE,
  encoding = "UTF-8"
)
expected_sealed_lines <- c(
  "<rect x='432.92' y='507.05' width='16.29' height='16.29' style='stroke-width: 0.75; stroke: #FFFFFF; stroke-linecap: butt; stroke-linejoin: miter; fill: #ECECEC;' />",
  "<rect x='504.34' y='507.05' width='16.29' height='16.29' style='stroke-width: 0.75; stroke: #FFFFFF; stroke-linecap: butt; stroke-linejoin: miter; fill: #88CCEE;' />",
  "<text x='454.19' y='517.77' style='font-size: 7.20px; font-family: \"Arial\";' textLength='45.17px' lengthAdjust='spacingAndGlyphs'>Not supported</text>",
  "<text x='525.61' y='517.77' style='font-size: 7.20px; font-family: \"Arial\";' textLength='33.19px' lengthAdjust='spacingAndGlyphs'>Supported</text>"
)
expected_source_lines <- c(
  "<rect x='435.92' y='507.05' width='16.29' height='16.29' style='stroke-width: 0.75; stroke: #FFFFFF; stroke-linecap: butt; stroke-linejoin: miter; fill: #ECECEC;' />",
  "<rect x='507.34' y='507.05' width='16.29' height='16.29' style='stroke-width: 0.75; stroke: #FFFFFF; stroke-linecap: butt; stroke-linejoin: miter; fill: #88CCEE;' />",
  "<text x='457.19' y='517.77' style='font-size: 7.20px; font-family: \"Arial\";' textLength='45.17px' lengthAdjust='spacingAndGlyphs'>Not supported</text>",
  "<text x='528.61' y='517.77' style='font-size: 7.20px; font-family: \"Arial\";' textLength='33.19px' lengthAdjust='spacingAndGlyphs'>Supported</text>"
)
changed_lines <- which(sealed_lines != source_lines)
if (
  length(sealed_lines) != 372L ||
    length(source_lines) != 372L ||
    !identical(changed_lines, 366:369) ||
    !identical(sealed_lines[changed_lines], expected_sealed_lines) ||
    !identical(source_lines[changed_lines], expected_source_lines)
) {
  stop("The Figure 1 SVG provenance transition is not exact", call. = FALSE)
}

order32f_inventory <- read_csv(
  file.path(
    root,
    "audit/hypotheses/H01/report017_order32f_continuation/partial_candidate_inventory.csv"
  ),
  show_col_types = FALSE
)
order32f_files <- sort(list.files(
  order32f_dir,
  recursive = TRUE,
  full.names = TRUE,
  all.files = TRUE,
  no.. = TRUE
))
if (
  nrow(order32f_inventory) != 16L ||
    length(order32f_files) != 16L ||
    !identical(order32f_files, sort(order32f_inventory$path))
) {
  stop("The retained order-32f directory membership changed", call. = FALSE)
}
order32f_exact <- vapply(seq_len(nrow(order32f_inventory)), function(index) {
  row <- order32f_inventory[index, ]
  file.exists(row$path[[1]]) &&
    sha256_file(row$path[[1]]) == row$sha256[[1]] &&
    as.numeric(file.info(row$path[[1]])$size) == row$bytes[[1]]
}, logical(1))
if (!all(order32f_exact)) {
  stop("A retained order-32f file changed", call. = FALSE)
}

order32e_seal <- read_csv(
  file.path(
    root,
    "audit/report_harmonization/report017_h01_order32e_stopped_state_independent_manifest.csv"
  ),
  show_col_types = FALSE
)
order32e_rows <- order32e_seal |>
  filter(startsWith(.data$path, paste0(order32e_dir, "/")))
order32e_files <- sort(list.files(
  order32e_dir,
  recursive = TRUE,
  full.names = TRUE,
  all.files = TRUE,
  no.. = TRUE
))
if (
  nrow(order32e_rows) != 12L ||
    length(order32e_files) != 12L ||
    !identical(order32e_files, sort(order32e_rows$path))
) {
  stop("The retained order-32e directory membership changed", call. = FALSE)
}
order32e_exact <- vapply(seq_len(nrow(order32e_rows)), function(index) {
  row <- order32e_rows[index, ]
  file.exists(row$path[[1]]) &&
    sha256_file(row$path[[1]]) == row$sha256[[1]] &&
    as.numeric(file.info(row$path[[1]])$size) == row$bytes[[1]]
}, logical(1))
if (!all(order32e_exact)) {
  stop("A retained order-32e file changed", call. = FALSE)
}

quarantine <- read_csv(
  file.path(
    root,
    "audit/hypotheses/H01/report017_order32d_display_repair/quarantine_recovery_evidence.csv"
  ),
  show_col_types = FALSE
)
quarantine_files <- sort(list.files(
  quarantine_dir,
  recursive = TRUE,
  full.names = TRUE,
  all.files = TRUE,
  no.. = TRUE
))
quarantine_exact <- vapply(seq_len(nrow(quarantine)), function(index) {
  row <- quarantine[index, ]
  file.exists(row$recovery_path[[1]]) &&
    !file.info(row$recovery_path[[1]])$isdir &&
    !nzchar(Sys.readlink(row$recovery_path[[1]])) &&
    sha256_file(row$recovery_path[[1]]) == row$expected_sha256[[1]] &&
    as.numeric(file.info(row$recovery_path[[1]])$size) == row$expected_bytes[[1]] &&
    !file.exists(file.path(root, row$original_path[[1]]))
}, logical(1))
if (
  nrow(quarantine) != 3L ||
    length(quarantine_files) != 3L ||
    !all(quarantine_exact)
) {
  stop("The quarantine is not exact", call. = FALSE)
}
if (
  !dir.exists(old_failed_dir) ||
    length(list.files(old_failed_dir, all.files = TRUE, no.. = TRUE)) != 0L
) {
  stop("The old failed candidate directory changed", call. = FALSE)
}

cat(
  "ORDER32G_SCALAR_GEOMETRY_PREFLIGHT=PASS\n",
  "R_VERSION=", as.character(getRversion()), "\n",
  "GEOMETRY_ROWS=3/3\n",
  "GEOMETRY_EXACT=3/3\n",
  "SVG_STRUCTURE_EXACT=3/3\n",
  "SVG_TEXT_MULTISET_EXACT=3/3\n",
  "PAIRED_LABELS=30/30\n",
  "PAIRED_TEXT_LENGTHS=30/30\n",
  "PAIRED_COLLISIONS=0\n",
  "MIN_FINAL_TEXT_MODEL_SUPPORT=", format(minimum_final_text[[1]], digits = 8), "\n",
  "MIN_FINAL_TEXT_DIAGNOSTIC=", format(minimum_final_text[[2]], digits = 8), "\n",
  "FIGURE1_CHANGED_PIXELS=9477\n",
  "FIGURE1_CHANGED_SVG_LINES=366,367,368,369\n",
  "ORDER32F_RETAINED_FILES=16/16\n",
  "ORDER32E_RETAINED_FILES=12/12\n",
  "QUARANTINE_FILES=3/3\n",
  sep = ""
)
