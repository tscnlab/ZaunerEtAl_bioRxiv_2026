#!/usr/bin/env Rscript

# One non-mutating harness preflight for REPORT-017 order 32f.

suppressPackageStartupMessages({
  library(digest)
  library(dplyr)
  library(png)
  library(readr)
  library(tibble)
  library(xml2)
})

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("Order 32f requires R 4.6.1", call. = FALSE)
}

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
stopped_candidate_dir <- "/private/tmp/H01-order32e-candidates.hltKEs"
old_failed_candidate_dir <- "/private/tmp/H01-order32d-candidates.nW90PN"
quarantine_dir <- "/private/tmp/H01-order32d-quarantine.Xc28uF"

sha256_file <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
}

path_rows_contract <- function(paths, set_name) {
  bind_rows(lapply(names(paths), function(current_figure_id) {
    current_paths <- paths[[current_figure_id]]
    tibble(
      set = set_name,
      figure_id = current_figure_id,
      format = names(current_paths),
      path = unname(current_paths),
      sha256 = vapply(unname(current_paths), sha256_file, character(1)),
      bytes = as.numeric(file.info(unname(current_paths))$size)
    )
  }))
}

synthetic_paths <- list(
  figure_a = c(
    png = file.path(
      root,
      "audit/report_harmonization/owner_orders/32f_h01_final_consolidated_harness_continuation.md"
    ),
    svg = file.path(
      root,
      "audit/report_harmonization/report017_h01_order32f_dispatch_manifest.csv"
    )
  ),
  figure_b = c(
    png = file.path(root, "notebooks/hypotheses/H01.qmd"),
    svg = file.path(
      root,
      "scripts/hypotheses/H01/build_h01_stage3_reporting_inputs.R"
    )
  )
)
synthetic_rows <- path_rows_contract(synthetic_paths, "synthetic")
expected_synthetic <- bind_rows(lapply(names(synthetic_paths), function(id) {
  current_paths <- synthetic_paths[[id]]
  tibble(
    set = "synthetic",
    figure_id = id,
    format = names(current_paths),
    path = unname(current_paths),
    sha256 = vapply(unname(current_paths), sha256_file, character(1)),
    bytes = as.numeric(file.info(unname(current_paths))$size)
  )
}))
if (!identical(synthetic_rows, expected_synthetic) || nrow(synthetic_rows) != 4L) {
  stop("The corrected path_rows contract failed", call. = FALSE)
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
  nrow(distinct(support, .data$placement_label, .data$metric_order, .data$question_order)) !=
    136L ||
    nrow(distinct(paired, .data$effect_scale, .data$point_label)) != 30L ||
    nrow(distinct(
      diagnostic,
      .data$placement_label,
      .data$metric_order,
      .data$check_order
    )) != 204L
) {
  stop("A frozen display key is not unique", call. = FALSE)
}
if (
  !identical(
    sort(unique(support$support_status)),
    c("Not supported", "Supported")
  ) ||
    !identical(
      sort(unique(diagnostic$check_status)),
      c("Not applicable", "Pass", "Review")
    ) ||
    !identical(sort(unique(paired$effect_scale)), c("Difference", "Ratio")) ||
    !all(paired$sample_exactly_matched)
) {
  stop("A source category or paired matched-sample flag changed", call. = FALSE)
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

paired_svg <- file.path(
  stopped_candidate_dir,
  "attempt01/H01_stage3_paired_placement.svg"
)
paired_doc <- read_xml(paired_svg)
paired_nodes <- xml_find_all(paired_doc, ".//*[local-name()='text']")
paired_values <- xml_text(paired_nodes)
paired_nodes <- paired_nodes[paired_values %in% paired$point_label]
paired_values <- xml_text(paired_nodes)
if (
  length(paired_values) != 30L ||
    anyDuplicated(paired_values) ||
    !identical(sort(paired_values), sort(paired$point_label))
) {
  stop("The stopped paired candidate label set is not exact", call. = FALSE)
}
raw_width <- xml_attr(paired_nodes, "textLength")
if (
  length(raw_width) != 30L ||
    anyNA(raw_width) ||
    !all(grepl("^[0-9]+(?:\\.[0-9]+)?px$", raw_width, perl = TRUE))
) {
  stop("A stopped paired candidate textLength is invalid", call. = FALSE)
}
width <- as.numeric(sub("px$", "", raw_width))
if (any(!is.finite(width))) {
  stop("A stopped paired candidate width is nonfinite", call. = FALSE)
}

style <- xml_attr(paired_nodes, "style")
font_size <- vapply(style, function(value) {
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
  stop("The stopped paired candidate contains a label collision", call. = FALSE)
}

stopped_seal <- read_csv(
  file.path(
    root,
    "audit/report_harmonization/report017_h01_order32e_stopped_state_independent_manifest.csv"
  ),
  show_col_types = FALSE
)
stopped_candidate_rows <- stopped_seal |>
  filter(startsWith(.data$path, paste0(stopped_candidate_dir, "/"))) |>
  rowwise() |>
  mutate(
    present = file.exists(.data$path),
    current_sha256 = if (.data$present) sha256_file(.data$path) else NA_character_,
    current_bytes = if (.data$present) as.numeric(file.info(.data$path)$size) else NA_real_,
    exact = .data$present && .data$current_sha256 == .data$sha256 &&
      .data$current_bytes == as.numeric(.data$bytes)
  ) |>
  ungroup()
if (nrow(stopped_candidate_rows) != 12L || any(!stopped_candidate_rows$exact)) {
  stop("A stopped order-32e candidate file changed", call. = FALSE)
}

figure1_source_png <- file.path(
  stopped_candidate_dir,
  "baseline/H01_stage3_model_support.png"
)
figure1_source_svg <- file.path(
  stopped_candidate_dir,
  "baseline/H01_stage3_model_support.svg"
)
figure1_sealed_png <- file.path(
  root,
  "artifacts/10_figures/H01/stage3/H01_stage3_model_support.png"
)
figure1_sealed_svg <- file.path(
  root,
  "artifacts/10_figures/H01/stage3/H01_stage3_model_support.svg"
)
figure_hash_contract <- c(
  source_png = "2e3b1ddb7954584a70ff9d434cc862f9d1769dc45be607d2ca34840cbc9c1760",
  source_svg = "12e4cf421a844da11844444e41601dec5e559e28b4ad77ac0081bd9ef2cfddcd",
  sealed_png = "2244f043d4fb676200524440098be223e23106578513f4ac61567ba3f636da8b",
  sealed_svg = "602dd62de063d3e12ac53ca7d22dd2563e64213255b9cdc7e138941450ce1966"
)
figure_hash_actual <- c(
  source_png = sha256_file(figure1_source_png),
  source_svg = sha256_file(figure1_source_svg),
  sealed_png = sha256_file(figure1_sealed_png),
  sealed_svg = sha256_file(figure1_sealed_svg)
)
if (!identical(figure_hash_actual, figure_hash_contract)) {
  stop("A Figure 1 baseline-provenance hash changed", call. = FALSE)
}

sealed_raster <- readPNG(figure1_sealed_png)
source_raster <- readPNG(figure1_source_png)
pixel_difference <- apply(abs(sealed_raster - source_raster), c(1, 2), max)
changed_pixels <- which(pixel_difference > 0, arr.ind = TRUE)
if (
  nrow(changed_pixels) != 9477L ||
    !identical(range(changed_pixels[, "col"]), c(1927L, 2496L)) ||
    !identical(range(changed_pixels[, "row"]), c(2256L, 2325L))
) {
  stop("The Figure 1 raster transition is not exact", call. = FALSE)
}
sealed_lines <- readLines(figure1_sealed_svg, warn = FALSE, encoding = "UTF-8")
source_lines <- readLines(figure1_source_svg, warn = FALSE, encoding = "UTF-8")
if (
  length(sealed_lines) != 372L ||
    length(source_lines) != 372L ||
    !identical(which(sealed_lines != source_lines), 366:369)
) {
  stop("The Figure 1 SVG transition is not confined to lines 366:369", call. = FALSE)
}

baseline_contract <- c(
  paired_png = "866670f47457bf304467e787481589298d9b7cf7c2c5de560ac9500f044c4608",
  paired_svg = "fe101f32cb0ffd4912b81ddbad4090c9558263aa85cc4f13ecad73369ac074f0",
  diagnostic_png = "95f46b0909b43c9b281a93a860d577b38a7753cb4d151ad751e2aca8a017b12d",
  diagnostic_svg = "a15b3bae14b1b76d5a48ae9a21d0eb86dfd264db238179fb2a4486c002876a52"
)
baseline_actual <- c(
  paired_png = sha256_file(file.path(
    stopped_candidate_dir,
    "baseline/H01_stage3_paired_placement.png"
  )),
  paired_svg = sha256_file(file.path(
    stopped_candidate_dir,
    "baseline/H01_stage3_paired_placement.svg"
  )),
  diagnostic_png = sha256_file(file.path(
    stopped_candidate_dir,
    "baseline/H01_stage3_diagnostic_assessment.png"
  )),
  diagnostic_svg = sha256_file(file.path(
    stopped_candidate_dir,
    "baseline/H01_stage3_diagnostic_assessment.svg"
  ))
)
if (!identical(baseline_actual, baseline_contract)) {
  stop("A Figure 5 or Figure 6 baseline changed", call. = FALSE)
}

order32d_evidence <- file.path(
  root,
  "audit/hypotheses/H01/report017_order32d_display_repair"
)
quarantine <- read_csv(
  file.path(order32d_evidence, "quarantine_recovery_evidence.csv"),
  show_col_types = FALSE
)
quarantine_exact <- vapply(seq_len(nrow(quarantine)), function(index) {
  row <- quarantine[index, ]
  file.exists(row$recovery_path[[1]]) &&
    !file.info(row$recovery_path[[1]])$isdir &&
    !nzchar(Sys.readlink(row$recovery_path[[1]])) &&
    sha256_file(row$recovery_path[[1]]) == row$expected_sha256[[1]] &&
    as.numeric(file.info(row$recovery_path[[1]])$size) == row$expected_bytes[[1]] &&
    !file.exists(file.path(root, row$original_path[[1]]))
}, logical(1))
if (nrow(quarantine) != 3L || !all(quarantine_exact)) {
  stop("The quarantine is not exact", call. = FALSE)
}

build_pre <- read_csv(
  file.path(order32d_evidence, "build_inventory_prechange.csv"),
  show_col_types = FALSE
)
build_stop <- read_csv(
  file.path(order32d_evidence, "build_inventory_postqa.csv"),
  show_col_types = FALSE
)
build_transitions <- full_join(
  select(build_pre, "path", pre_present = "present"),
  select(build_stop, "path", stop_present = "present"),
  by = "path",
  relationship = "one-to-one"
) |>
  filter(.data$pre_present %in% TRUE, is.na(.data$stop_present)) |>
  pull(.data$path) |>
  sort()
if (!identical(build_transitions, sort(quarantine$recovery_relative_path))) {
  stop("The build-relative path basis changed", call. = FALSE)
}

protected_pre <- read_csv(
  file.path(order32d_evidence, "protected_inventory_prechange.csv"),
  show_col_types = FALSE
)
protected_stop <- read_csv(
  file.path(order32d_evidence, "protected_inventory_postqa.csv"),
  show_col_types = FALSE
)
protected_transitions <- full_join(
  select(protected_pre, "path", pre_present = "present"),
  select(protected_stop, "path", stop_present = "present"),
  by = "path",
  relationship = "one-to-one"
) |>
  filter(.data$pre_present %in% TRUE, .data$stop_present %in% FALSE) |>
  pull(.data$path) |>
  sort()
if (!identical(protected_transitions, sort(quarantine$original_path))) {
  stop("The project-relative protected path basis changed", call. = FALSE)
}

if (
  !dir.exists(old_failed_candidate_dir) ||
    length(list.files(old_failed_candidate_dir, all.files = TRUE, no.. = TRUE)) != 0L ||
    !dir.exists(quarantine_dir)
) {
  stop("An earlier temporary directory changed", call. = FALSE)
}

cat(
  "ORDER32F_HARNESS_PREFLIGHT=PASS\n",
  "R_VERSION=", as.character(getRversion()), "\n",
  "SYNTHETIC_PATH_ROWS=4/4\n",
  "PAIRED_LABELS=30/30\n",
  "PAIRED_TEXT_LENGTHS=30/30\n",
  "PAIRED_COLLISIONS=0\n",
  "FIGURE1_CHANGED_PIXELS=9477\n",
  "FIGURE1_CHANGED_SVG_LINES=366,367,368,369\n",
  "FIGURE5_BASELINE=EXACT\n",
  "FIGURE6_BASELINE=EXACT\n",
  "STOPPED_CANDIDATE_FILES=12/12\n",
  "QUARANTINE_FILES=3/3\n",
  "OLD_FAILED_CANDIDATE_ENTRIES=0\n",
  sep = ""
)
