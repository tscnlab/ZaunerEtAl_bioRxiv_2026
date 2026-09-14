#!/usr/bin/env Rscript

# Verify the candidate-first H09 Order 56a display-only refresh.

options(stringsAsFactors = FALSE, warn = 2)

assert_true <- function(value, message) {
  if (!isTRUE(value)) stop(message, call. = FALSE)
}

assert_all <- function(value, message) {
  if (!length(value) || !all(value)) stop(message, call. = FALSE)
}

assert_none <- function(value, message) {
  if (length(value) && any(value)) stop(message, call. = FALSE)
}

assert_true(
  identical(as.character(getRversion()), "4.6.1"),
  sprintf("Order 56a focused test requires R 4.6.1, found %s.", getRversion())
)

required_packages <- c("digest", "dplyr", "ggplot2", "png", "readr")
missing_packages <- required_packages[
  !vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
]
assert_true(
  length(missing_packages) == 0L,
  paste(
    "Missing synchronized package(s):",
    paste(missing_packages, collapse = ", ")
  )
)

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
setwd(root)

arguments <- commandArgs(trailingOnly = TRUE)
assert_true(
  length(arguments) == 1L,
  "Supply exactly one phase: `candidate` or `prerender`."
)
phase <- match.arg(arguments[[1L]], c("candidate", "prerender"))

work_dir <- Sys.getenv("H09_ORDER56A_WORK_DIR", unset = "")
assert_true(
  nzchar(work_dir) && startsWith(work_dir, "/private/tmp/"),
  "`H09_ORDER56A_WORK_DIR` must be an absolute directory under `/private/tmp`."
)
work_dir <- normalizePath(work_dir, winslash = "/", mustWork = TRUE)
evidence_dir <- file.path(
  root,
  "audit/hypotheses/H09/report018_order56a_display_repair"
)
assert_true(dir.exists(evidence_dir), "The Order 56a evidence root is missing.")

sha256_file <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
}

write_evidence <- function(object, name) {
  readr::write_csv(object, file.path(evidence_dir, name), na = "")
}

refresh_path <- file.path(
  root,
  "scripts/hypotheses/H09/refresh_h09_order56_figures.R"
)
refresh_text <- paste(
  readLines(refresh_path, warn = FALSE, encoding = "UTF-8"),
  collapse = "\n"
)

forbidden_call_pattern <- paste0(
  "(?i)(^|[^[:alnum:]_.])",
  "(lmer|glmer|lm|glm|gam|bam|brm|stan_glm|predict|simulate|",
  "bootstrap|boot|sample|p[.]adjust|confint|emmeans|anova|",
  "readRDS|load|source|qread)",
  "[[:space:]]*[(]"
)
forbidden_call_matches <- gregexpr(
  forbidden_call_pattern,
  refresh_text,
  perl = TRUE
)[[1L]]
forbidden_call_count <- if (forbidden_call_matches[[1L]] == -1L) {
  0L
} else {
  length(forbidden_call_matches)
}
allowed_input_literals <- c(
  "artifacts/11_source_data/H09/H09_primary_effects_data.csv",
  "artifacts/11_source_data/H09/H09_paired_placement_effects_data.csv",
  "artifacts/11_source_data/H09/H09_primary_diagnostic_figure_data.csv",
  "artifacts/12_manifests/H09/H09_figure_manifest.csv"
)
input_literal_matches <- regmatches(
  refresh_text,
  gregexpr(
    "artifacts/[[:alnum:]_./-]+[.](csv|rds|rda|RData)",
    refresh_text,
    perl = TRUE
  )
)[[1L]]
input_literals <- sort(unique(input_literal_matches[nzchar(
  input_literal_matches
)]))
read_csv_count <- lengths(regmatches(
  refresh_text,
  gregexpr("readr::read_csv[[:space:]]*[(]", refresh_text, perl = TRUE)
))
no_scientific_call_audit <- data.frame(
  check = c(
    "forbidden scientific calls",
    "input literal allow-list",
    "read_csv call count",
    "model or analysis-frame path literal",
    "RDS or workspace input literal"
  ),
  observed = c(
    forbidden_call_count,
    paste(input_literals, collapse = "|"),
    read_csv_count,
    sum(grepl(
      "(?i)(models?/|analysis[_ -]?frame)",
      input_literals,
      perl = TRUE
    )),
    sum(grepl("(?i)[.](rds|rda|RData)$", input_literals, perl = TRUE))
  ),
  expected = c(
    "0",
    paste(sort(allowed_input_literals), collapse = "|"),
    "4",
    "0",
    "0"
  ),
  stringsAsFactors = FALSE
)
no_scientific_call_audit$status <- ifelse(
  no_scientific_call_audit$observed == no_scientific_call_audit$expected,
  "PASS",
  "FAIL"
)
write_evidence(no_scientific_call_audit, "no_scientific_call_audit.csv")
assert_all(
  no_scientific_call_audit$status == "PASS",
  "The dedicated refresh failed its static call or input audit."
)

Sys.setenv(H09_ORDER56A_SOURCE_ONLY = "TRUE")
source(refresh_path, local = environment())

historical_dir <- file.path(work_dir, "historical")
candidate_dir <- file.path(work_dir, "repaired")
assert_true(
  dir.exists(historical_dir) && dir.exists(candidate_dir),
  "Both historical and repaired candidate directories are required."
)

figure_stems <- c(
  primary_effects = "H09_primary_effects",
  paired_placement_effects = "H09_paired_placement_effects",
  diagnostics_near_eye = "H09_diagnostics_near_eye",
  diagnostics_chest = "H09_diagnostics_chest"
)
extensions <- c("png", "pdf")
output_names <- as.vector(outer(
  unname(figure_stems),
  extensions,
  paste,
  sep = "."
))
historical_paths <- file.path(historical_dir, output_names)
candidate_paths <- file.path(candidate_dir, output_names)
durable_paths <- file.path(root, "artifacts/10_figures/H09", output_names)
assert_all(
  file.exists(c(historical_paths, candidate_paths, durable_paths)),
  "A required historical, candidate, or durable figure is missing."
)

expected_preimage_hashes <- c(
  H09_primary_effects.png = "f288cfaff6e555715af30c778974e50d9bcc8c9a90c643b5e994ad2d8b95be1f",
  H09_primary_effects.pdf = "b354077d2c1225104ecef7af1d879acd2037a7b740940392092b2d09f2f833e0",
  H09_paired_placement_effects.png = "4cffc5339801d25e817639064b6f40e0b0a6bbe69a735e5f245d97cee898e185",
  H09_paired_placement_effects.pdf = "5d8f8e95c4642ca29391941f63852776ee6d4ee3cb0cbdedfe74d24ec645ff7c",
  H09_diagnostics_near_eye.png = "df6a267517ea08635a00fcfa153a1e3a7f6dbbbe764745860c16bd3b53165e96",
  H09_diagnostics_near_eye.pdf = "a01d7184d3fc68bf33375f950c9ba422ac7f86f803cd214064ddf86d003ca5ac",
  H09_diagnostics_chest.png = "e82b32d5d69a73e45a7d93e8b1bb8357dc3104e67c5f128eba4f3f5538961a75",
  H09_diagnostics_chest.pdf = "614b46f3cb2026ea1f6c7350959482ce4473c114b0c90ec066a176f73c635596"
)
observed_durable_hashes <- vapply(durable_paths, sha256_file, character(1))

decoded_png_identical <- function(first, second) {
  first_pixels <- png::readPNG(first, native = TRUE)
  second_pixels <- png::readPNG(second, native = TRUE)
  identical(first_pixels, second_pixels)
}

pdf_page_geometry <- function(path) {
  pdfinfo <- Sys.which("pdfinfo")
  assert_true(
    nzchar(pdfinfo),
    "`pdfinfo` is required for the PDF geometry audit."
  )
  output <- suppressWarnings(system2(
    pdfinfo,
    path,
    stdout = TRUE,
    stderr = TRUE
  ))
  status <- attr(output, "status")
  assert_true(is.null(status) || status == 0L, "`pdfinfo` failed.")
  page_size <- grep("^Page size:", output, value = TRUE)
  pages <- grep("^Pages:", output, value = TRUE)
  assert_true(
    length(page_size) == 1L && length(pages) == 1L,
    "Could not extract PDF geometry."
  )
  paste(trimws(pages), trimws(page_size), sep = "|")
}

render_pdf_for_comparison <- function(path, prefix) {
  pdftoppm <- Sys.which("pdftoppm")
  assert_true(nzchar(pdftoppm), "`pdftoppm` is required for the PDF audit.")
  output <- suppressWarnings(system2(
    pdftoppm,
    c("-png", "-singlefile", "-r", "144", path, prefix),
    stdout = TRUE,
    stderr = TRUE
  ))
  status <- attr(output, "status")
  assert_true(is.null(status) || status == 0L, "`pdftoppm` failed.")
  rendered_path <- paste0(prefix, ".png")
  assert_true(
    file.exists(rendered_path),
    "The rendered PDF comparison is missing."
  )
  rendered_path
}

plain_source_columns <- function(prepared, source) {
  value <- prepared[, names(source), drop = FALSE]
  factor_columns <- vapply(value, is.factor, logical(1))
  value[factor_columns] <- lapply(value[factor_columns], as.character)
  value
}

rectangular_values_identical <- function(first, second) {
  if (!identical(names(first), names(second)) || nrow(first) != nrow(second)) {
    return(FALSE)
  }
  first_values <- lapply(first, function(value) {
    if (is.factor(value)) as.character(value) else unname(value)
  })
  second_values <- lapply(second, function(value) {
    if (is.factor(value)) as.character(value) else unname(value)
  })
  identical(first_values, second_values)
}

plot_build_safely <- function(plot) {
  suppressMessages(suppressWarnings(ggplot2::ggplot_build(plot)))
}

scale_signature <- function(plot) {
  build <- plot_build_safely(plot)
  extract <- function(scale) {
    breaks <- scale$get_breaks()
    list(
      limits = scale$get_limits(),
      breaks = breaks,
      labels = scale$get_labels(breaks)
    )
  }
  list(
    layout = build$layout$layout,
    x = lapply(build$layout$panel_scales_x, extract),
    y = lapply(build$layout$panel_scales_y, extract)
  )
}

inputs <- read_frozen_inputs(root)
historical_plot_set <- build_h09_order56_plots(inputs, "historical")
candidate_plot_set <- build_h09_order56_plots(inputs, "repaired")

source_reconciliations <- list(
  primary_effects = rectangular_values_identical(
    plain_source_columns(
      historical_plot_set$prepared$primary_effects,
      inputs$primary
    ),
    inputs$primary
  ),
  paired_placement_effects = rectangular_values_identical(
    plain_source_columns(
      historical_plot_set$prepared$paired_placement_effects,
      inputs$paired
    ),
    inputs$paired
  ),
  diagnostics_near_eye = rectangular_values_identical(
    plain_source_columns(
      historical_plot_set$prepared$diagnostics_near_eye,
      inputs$diagnostic
    ),
    dplyr::filter(inputs$diagnostic, .data$placement == "glasses")
  ),
  diagnostics_chest = rectangular_values_identical(
    plain_source_columns(
      historical_plot_set$prepared$diagnostics_chest,
      inputs$diagnostic
    ),
    dplyr::filter(inputs$diagnostic, .data$placement == "chest")
  )
)
source_row_audit <- data.frame(
  figure_id = names(source_reconciliations),
  source_rows = c(
    nrow(inputs$primary),
    nrow(inputs$paired),
    sum(inputs$diagnostic$placement == "glasses"),
    sum(inputs$diagnostic$placement == "chest")
  ),
  plotted_rows = vapply(
    historical_plot_set$prepared,
    nrow,
    integer(1)
  ),
  source_values_exact = unlist(source_reconciliations, use.names = FALSE),
  stringsAsFactors = FALSE
)
source_row_audit$status <- ifelse(
  source_row_audit$source_rows == source_row_audit$plotted_rows &
    source_row_audit$source_values_exact,
  "PASS",
  "FAIL"
)
write_evidence(source_row_audit, "source_row_reconciliation.csv")
assert_all(
  source_row_audit$status == "PASS",
  "A plotted frame does not reconcile exactly to its frozen CSV rows."
)

component_rows <- list()
layer_rows <- list()
scale_rows <- list()
for (figure_id in names(historical_plot_set$components)) {
  historical_components <- historical_plot_set$components[[figure_id]]
  candidate_components <- candidate_plot_set$components[[figure_id]]
  assert_true(
    identical(names(historical_components), names(candidate_components)),
    paste("Component order changed for", figure_id)
  )
  for (component_id in names(historical_components)) {
    historical_build <- plot_build_safely(historical_components[[component_id]])
    candidate_build <- plot_build_safely(candidate_components[[component_id]])
    layer_identical <- identical(historical_build$data, candidate_build$data)
    scales_identical <- identical(
      scale_signature(historical_components[[component_id]]),
      scale_signature(candidate_components[[component_id]])
    )
    layer_rows[[length(layer_rows) + 1L]] <- data.frame(
      figure_id = figure_id,
      component_id = component_id,
      historical_layer_count = length(historical_build$data),
      candidate_layer_count = length(candidate_build$data),
      historical_layer_hash = digest::digest(
        historical_build$data,
        algo = "sha256"
      ),
      candidate_layer_hash = digest::digest(
        candidate_build$data,
        algo = "sha256"
      ),
      scientific_layer_data_identical = layer_identical,
      status = ifelse(layer_identical, "PASS", "FAIL"),
      stringsAsFactors = FALSE
    )
    scale_rows[[length(scale_rows) + 1L]] <- data.frame(
      figure_id = figure_id,
      component_id = component_id,
      scales_breaks_labels_panels_identical = scales_identical,
      status = ifelse(scales_identical, "PASS", "FAIL"),
      stringsAsFactors = FALSE
    )
    component_rows[[length(component_rows) + 1L]] <- data.frame(
      figure_id = figure_id,
      component_id = component_id,
      source_rows = nrow(historical_plot_set$prepared[[figure_id]]),
      historical_point_rows = nrow(historical_build$data[[length(
        historical_build$data
      )]]),
      candidate_point_rows = nrow(candidate_build$data[[length(
        candidate_build$data
      )]]),
      status = ifelse(
        nrow(historical_plot_set$prepared[[figure_id]]) ==
          nrow(historical_build$data[[length(historical_build$data)]]) &&
          nrow(historical_build$data[[length(historical_build$data)]]) ==
            nrow(candidate_build$data[[length(candidate_build$data)]]),
        "PASS",
        "FAIL"
      ),
      stringsAsFactors = FALSE
    )
  }
}
layer_audit <- dplyr::bind_rows(layer_rows)
scale_audit <- dplyr::bind_rows(scale_rows)
component_audit <- dplyr::bind_rows(component_rows)
write_evidence(layer_audit, "scientific_layer_audit.csv")
write_evidence(scale_audit, "scale_break_label_panel_audit.csv")
write_evidence(component_audit, "source_layer_cardinality_audit.csv")
assert_all(
  layer_audit$status == "PASS",
  "A candidate changed scientific layer data."
)
assert_all(
  scale_audit$status == "PASS",
  "A candidate changed panel assignment, scale breaks, or label meaning."
)
assert_all(
  component_audit$status == "PASS",
  "A point layer does not contain every frozen source row exactly once."
)

if (phase == "candidate") {
  assert_true(
    identical(
      unname(observed_durable_hashes),
      unname(expected_preimage_hashes[basename(durable_paths)])
    ),
    "A durable figure changed before candidate validation."
  )

  png_names <- paste0(unname(figure_stems), ".png")
  png_audit <- lapply(png_names, function(name) {
    baseline_path <- file.path(historical_dir, name)
    durable_path <- file.path(root, "artifacts/10_figures/H09", name)
    decoded_identical <- decoded_png_identical(baseline_path, durable_path)
    data.frame(
      figure_file = name,
      historical_sha256 = sha256_file(baseline_path),
      durable_sha256 = sha256_file(durable_path),
      byte_identical = sha256_file(baseline_path) == sha256_file(durable_path),
      decoded_pixel_identical = decoded_identical,
      status = ifelse(decoded_identical, "PASS", "FAIL"),
      stringsAsFactors = FALSE
    )
  }) |>
    dplyr::bind_rows()
  write_evidence(png_audit, "historical_png_reproduction.csv")
  assert_all(
    png_audit$status == "PASS",
    "Historical-theme PNG reproduction is not pixel-identical."
  )

  pdf_compare_dir <- file.path(work_dir, "pdf_visible_content")
  dir.create(pdf_compare_dir, recursive = TRUE, showWarnings = FALSE)
  pdf_names <- paste0(unname(figure_stems), ".pdf")
  pdf_audit <- lapply(pdf_names, function(name) {
    baseline_path <- file.path(historical_dir, name)
    durable_path <- file.path(root, "artifacts/10_figures/H09", name)
    stem <- sub("[.]pdf$", "", name)
    baseline_render <- render_pdf_for_comparison(
      baseline_path,
      file.path(pdf_compare_dir, paste0(stem, "_historical"))
    )
    durable_render <- render_pdf_for_comparison(
      durable_path,
      file.path(pdf_compare_dir, paste0(stem, "_durable"))
    )
    geometry_identical <- identical(
      pdf_page_geometry(baseline_path),
      pdf_page_geometry(durable_path)
    )
    visible_identical <- decoded_png_identical(
      baseline_render,
      durable_render
    )
    data.frame(
      figure_file = name,
      historical_sha256 = sha256_file(baseline_path),
      durable_sha256 = sha256_file(durable_path),
      byte_identical = sha256_file(baseline_path) == sha256_file(durable_path),
      page_geometry_identical = geometry_identical,
      rendered_visible_content_identical = visible_identical,
      status = ifelse(geometry_identical && visible_identical, "PASS", "FAIL"),
      stringsAsFactors = FALSE
    )
  }) |>
    dplyr::bind_rows()
  write_evidence(pdf_audit, "historical_pdf_reproduction.csv")
  assert_all(
    pdf_audit$status == "PASS",
    "Historical-theme PDF geometry or visible-content reproduction failed."
  )

  typography_audit <- data.frame(
    figure_id = names(figure_stems),
    base_width_in = c(10.5, 8, 10.5, 10.5),
    historical_height_in = c(6, 6, 14, 14),
    candidate_height_in = c(6.5, 6.5, 17.5, 17.5),
    export_scale_multiplier = 1.5,
    nominal_minimum_pt = c(17, 13, 17, 17),
    nominal_minimum_lower = c(17, 13, 17, 17),
    nominal_minimum_upper = c(20, 16, 20, 20),
    stringsAsFactors = FALSE
  ) |>
    dplyr::mutate(
      export_width_in = .data$base_width_in * .data$export_scale_multiplier,
      export_height_in = .data$candidate_height_in *
        .data$export_scale_multiplier,
      height_increase_fraction = .data$candidate_height_in /
        .data$historical_height_in -
        1,
      effective_pt_at_170mm = .data$nominal_minimum_pt *
        (170 / 25.4) /
        .data$export_width_in,
      effective_pt_at_643px = .data$nominal_minimum_pt *
        (643 / 96) /
        .data$export_width_in,
      nominal_range_ok = .data$nominal_minimum_pt >=
        .data$nominal_minimum_lower &
        .data$nominal_minimum_pt <= .data$nominal_minimum_upper,
      height_increase_ok = .data$height_increase_fraction <= 0.25 + 1e-12,
      effective_floor_ok = .data$effective_pt_at_170mm >= 7 &
        .data$effective_pt_at_643px >= 7,
      status = ifelse(
        .data$nominal_range_ok &
          .data$height_increase_ok &
          .data$effective_floor_ok,
        "PASS",
        "FAIL"
      )
    )
  write_evidence(typography_audit, "candidate_typography_contract.csv")
  assert_all(
    typography_audit$status == "PASS",
    "The repaired candidate failed its bounded typography contract."
  )

  candidate_inventory <- data.frame(
    figure_file = basename(candidate_paths),
    candidate_path = candidate_paths,
    sha256 = vapply(candidate_paths, sha256_file, character(1)),
    bytes = as.numeric(file.info(candidate_paths)$size),
    stringsAsFactors = FALSE
  )
  write_evidence(candidate_inventory, "candidate_inventory.csv")

  source_inventory <- data.frame(
    input_id = names(inputs$paths),
    path = unname(inputs$paths),
    sha256 = vapply(inputs$paths, sha256_file, character(1)),
    bytes = as.numeric(file.info(inputs$paths)$size),
    stringsAsFactors = FALSE
  )
  write_evidence(source_inventory, "source_input_inventory_candidate.csv")

  qa_html <- c(
    "<!doctype html>",
    "<html lang='en'><head><meta charset='utf-8'>",
    "<meta name='viewport' content='width=device-width, initial-scale=1'>",
    "<title>H09 Order 56a candidate QA</title>",
    paste0(
      "<style>body{font-family:sans-serif;margin:18px;background:#fff;color:#111}",
      ".figure{margin:0 0 34px}.final{display:block;width:170mm;max-width:none;",
      "height:auto;border:1px solid #ddd}h1{font-size:22px}",
      "h2{font-size:18px;margin-top:24px}</style></head><body>"
    ),
    "<h1>H09 Order 56a repaired candidates at 170 mm</h1>",
    paste0(
      "<section class='figure'><h2>",
      names(figure_stems),
      "</h2><img class='final' src='repaired/",
      paste0(unname(figure_stems), ".png"),
      "' alt='H09 repaired candidate for final-size QA'></section>"
    ),
    "</body></html>"
  )
  writeLines(qa_html, file.path(work_dir, "candidate_qa.html"), useBytes = TRUE)

  cat(sprintf(
    paste0(
      "H09_ORDER56A_CANDIDATE_TEST=PASS png=%d pdf=%d layers=%d ",
      "sources=%d effective_min_170mm=%.6f effective_min_643px=%.6f qa=%s\n"
    ),
    nrow(png_audit),
    nrow(pdf_audit),
    nrow(layer_audit),
    nrow(source_row_audit),
    min(typography_audit$effective_pt_at_170mm),
    min(typography_audit$effective_pt_at_643px),
    file.path(work_dir, "candidate_qa.html")
  ))
}

if (phase == "prerender") {
  candidate_inventory <- readr::read_csv(
    file.path(evidence_dir, "candidate_inventory.csv"),
    show_col_types = FALSE
  )
  visual_qa <- readr::read_csv(
    file.path(evidence_dir, "candidate_visual_qa.csv"),
    show_col_types = FALSE
  )
  assert_true(
    nrow(candidate_inventory) == 8L &&
      nrow(visual_qa) >= 4L &&
      all(visual_qa$status == "PASS"),
    "The complete candidate inventory or visual QA is not accepted."
  )
  expected_candidate_hashes <- stats::setNames(
    candidate_inventory$sha256,
    candidate_inventory$figure_file
  )
  durable_hashes <- vapply(durable_paths, sha256_file, character(1))
  assert_true(
    identical(
      unname(durable_hashes),
      unname(expected_candidate_hashes[basename(durable_paths)])
    ),
    "A durable figure is not identical to its accepted candidate."
  )
  cat(sprintf(
    paste0(
      "H09_ORDER56A_PRERENDER_TEST=PASS outputs=%d layers=%d ",
      "sources=%d visual_domains=%d R=%s\n"
    ),
    length(durable_paths),
    nrow(layer_audit),
    nrow(source_row_audit),
    nrow(visual_qa),
    as.character(getRversion())
  ))
}
