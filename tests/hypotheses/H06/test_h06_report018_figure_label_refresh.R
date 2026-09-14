#!/usr/bin/env Rscript

# Focused verifier for REPORT-018 H06 hourly order 46.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("The order 46 verifier requires R 4.6.1", call. = FALSE)
}

required_packages <- c("digest", "dplyr", "magick", "readr")
missing_packages <- required_packages[
  !vapply(
    required_packages,
    requireNamespace,
    logical(1),
    quietly = TRUE
  )
]
if (length(missing_packages) > 0L) {
  stop(
    "Missing project package(s): ",
    paste(missing_packages, collapse = ", "),
    call. = FALSE
  )
}

sha256_file <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
}

file_bytes <- function(path) unname(file.info(path)$size)

assert_true <- function(value, message) {
  if (!isTRUE(value)) {
    stop(message, call. = FALSE)
  }
  invisible(TRUE)
}

evidence_rel <- paste0(
  "audit/hypotheses/H06/",
  "report018_order46_figure_label_refresh"
)
evidence_dir <- file.path(root, evidence_rel)
refresh_rel <- paste0(
  "scripts/hypotheses/H06/",
  "refresh_h06_report018_reader_figure_labels.R"
)
test_rel <- paste0(
  "tests/hypotheses/H06/",
  "test_h06_report018_figure_label_refresh.R"
)
manifest_rel <- "artifacts/12_manifests/H06/H06_stage3_artifacts.csv"

fixed_pins <- tibble::tribble(
  ~path,
  ~sha256,
  ~bytes,
  "audit/report_harmonization/owner_orders/46_h06_hourly_reader_figure_label_refresh.md",
  "5e0823af8dcd5f1d05c7248d42b95f78e101615600b73626fcf7fa5cd38b5478",
  16269,
  "audit/report_harmonization/report018_h06_order46_dispatch_manifest.csv",
  "79d965aa26ac70522029df8f0f96c3e8fece12f82fae2d621d96103e1937d6e1",
  7767,
  "notebooks/hypotheses/H06.qmd",
  "468ecebe8485de05d2bc47bb4a0948a3eaf8308c7ea1fdf6dacb54316a7544e2",
  60677,
  "audit/hypotheses/H06/H06_analysis_preparation.qmd",
  "f952d5ec72066ee86fded4888aaa815bdf763c11f466806ebc7391c79e22918b",
  59613,
  "audit/handoffs/H06_worker_handoff.md",
  "21b37d161f07ec27a2802239a3999621f484b9d697c7cddaf3a73f6c09fe4e90",
  11453,
  "_build/nathealth/notebooks/hypotheses/H06.html",
  "ff3518c09a4322dc8a2c23a961f2ef3ffc8d124843874547a40415c8330fd555",
  6109797,
  "_build/nathealth/audit/hypotheses/H06/H06_analysis_preparation.html",
  "222894f4416f6f4d48bace8e9bfa9c08d22f22d613bf2b0c1e5440b0485efcae",
  771694,
  "config/site_display_registry.csv",
  "3d669d459ecc27d3154bbb5ff5b0d64cb510805d486b45264443228c44a6d809",
  295
)
for (index in seq_len(nrow(fixed_pins))) {
  path <- file.path(root, fixed_pins$path[[index]])
  assert_true(
    file.exists(path),
    paste("Missing fixed file:", fixed_pins$path[[index]])
  )
  assert_true(
    identical(sha256_file(path), fixed_pins$sha256[[index]]) &&
      identical(file_bytes(path), fixed_pins$bytes[[index]]),
    paste("Fixed-file drift:", fixed_pins$path[[index]])
  )
}

source_pins <- tibble::tribble(
  ~path,
  ~sha256,
  ~bytes,
  "artifacts/11_source_data/H06/H06_reader_primary_effects_figure.csv",
  "8a5482eb687a707ec193e2021233d954ca0ca21c322e75a9cd136042d0b51bfe",
  4668,
  "artifacts/11_source_data/H06/H06_stage3_site_specific_significance_screen_figure.csv",
  "8d15804a66a6589b6c6f408db147e65c0fa2a42f71cd32fb1dcd2acd6657d642",
  49970,
  "artifacts/11_source_data/H06/H06_reader_temporal_day_type_curves.csv",
  "838dc1485dd1c20caaa1693ec8d9969dc60619601a5fb11f9c1f1b350f7bfdab",
  132409,
  "artifacts/11_source_data/H06/H06_reader_temporal_day_type_ratios.csv",
  "789c3375b8e7d9db16862c0d084a9484d88123523a7524b1280bee5f13bfce03",
  89294,
  "artifacts/11_source_data/H06/H06_reader_temporal_day_type_support.csv",
  "597b72279bf499cecf63c95b11004b29dd388e1858f687ec6a21c0a1e95dfc60",
  2918,
  "artifacts/11_source_data/H06/H06_reader_temporal_activity_curves.csv",
  "c947918e14c3d83fc51e8b4c9216d3ad9e5a18002d3b5f3f877b3d30b18cfa6d",
  130390,
  "artifacts/11_source_data/H06/H06_reader_temporal_activity_ratios.csv",
  "1a12833bf7fa7aabdc91c23c1c28be26e685d3db4c7ddcea546720efafeb2b14",
  95026,
  "artifacts/11_source_data/H06/H06_reader_temporal_activity_support.csv",
  "cac58f8236192d20fbf52ad2c8bd9a2f2809293a841d686969d47275e665fd08",
  2870
)
for (index in seq_len(nrow(source_pins))) {
  path <- file.path(root, source_pins$path[[index]])
  assert_true(
    identical(sha256_file(path), source_pins$sha256[[index]]) &&
      identical(file_bytes(path), source_pins$bytes[[index]]),
    paste("Frozen figure-source drift:", source_pins$path[[index]])
  )
}

protected <- readr::read_csv(
  file.path(evidence_dir, "protected_inventory.csv"),
  show_col_types = FALSE,
  col_types = readr::cols(
    path = readr::col_character(),
    sha256 = readr::col_character(),
    bytes = readr::col_double()
  )
)
protected_paths <- file.path(root, protected$path)
assert_true(all(file.exists(protected_paths)), "A protected file is missing")
assert_true(
  identical(
    unname(vapply(protected_paths, sha256_file, character(1))),
    protected$sha256
  ) &&
    identical(
      unname(vapply(protected_paths, file_bytes, numeric(1))),
      protected$bytes
    ),
  "A protected file changed"
)

for (path in file.path(
  root,
  c(
    refresh_rel,
    test_rel,
    "scripts/hypotheses/H06/build_h06_stage3_reader_displays.R",
    "scripts/hypotheses/H06/build_h06_stage3_site_specific_screening.R"
  )
)) {
  parse(file = path)
}

refresh_names <- all.names(
  parse(file = file.path(root, refresh_rel)),
  functions = TRUE
)
prohibited_calls <- c(
  "readRDS",
  "load",
  "saveRDS",
  "lm",
  "glm",
  "gam",
  "bam",
  "gamm",
  "predict",
  "simulate",
  "boot",
  "p.adjust",
  "sample",
  "summarise",
  "summarize"
)
assert_true(
  !any(refresh_names %in% prohibited_calls),
  paste(
    "Prohibited call in refresh script:",
    paste(
      intersect(refresh_names, prohibited_calls),
      collapse = ", "
    )
  )
)

checks <- readr::read_csv(
  file.path(evidence_dir, "source_value_and_geometry_checks.csv"),
  show_col_types = FALSE
)
assert_true(
  nrow(checks) >= 40L && all(checks$status),
  "A source or geometry check failed"
)
visual <- readr::read_csv(
  file.path(evidence_dir, "visual_qa.csv"),
  show_col_types = FALSE,
  col_types = readr::cols(.default = readr::col_character())
)
assert_true(
  nrow(visual) == 4L &&
    all(visual$overall_status == "PASS") &&
    all(as.numeric(visual$effective_final_text_pt) >= 7),
  "Visual QA is incomplete"
)

manifest <- readr::read_csv(
  file.path(root, manifest_rel),
  show_col_types = FALSE,
  col_types = readr::cols(.default = readr::col_character())
)
assert_true(
  nrow(manifest) == 308L && dplyr::n_distinct(manifest$path) == 308L,
  "Stage 3 manifest does not contain 308 unique rows"
)
append_paths <- c(
  refresh_rel,
  test_rel,
  paste0(evidence_rel, "/authorized_label_transitions.csv"),
  paste0(evidence_rel, "/source_value_and_geometry_checks.csv"),
  paste0(evidence_rel, "/visual_qa.csv"),
  paste0(evidence_rel, "/protected_inventory.csv"),
  paste0(evidence_rel, "/package_versions.csv")
)
assert_true(
  identical(tail(manifest$path, 7L), append_paths),
  "Manifest append set drift"
)
for (path in append_paths) {
  row <- manifest[manifest$path == path, , drop = FALSE]
  assert_true(nrow(row) == 1L, paste("Missing appended manifest row:", path))
  absolute <- file.path(root, path)
  assert_true(
    identical(row$sha256[[1L]], sha256_file(absolute)) &&
      identical(as.numeric(row$bytes[[1L]]), file_bytes(absolute)),
    paste("Appended manifest identity drift:", path)
  )
}

changes <- readr::read_csv(
  file.path(evidence_dir, "manifest_row_changes.csv"),
  show_col_types = FALSE,
  col_types = readr::cols(.default = readr::col_character())
)
assert_true(
  sum(changes$change_type == "updated") == 13L &&
    sum(changes$change_type == "appended") == 7L,
  "Manifest change evidence is not exactly 13 updates plus seven appends"
)
manifest_lines <- readLines(file.path(root, manifest_rel), warn = FALSE)
reverse_lines <- manifest_lines[seq_len(length(manifest_lines) - 7L)]
updated <- changes[changes$change_type == "updated", , drop = FALSE]
for (index in seq_len(nrow(updated))) {
  line_index <- match(updated$post_line[[index]], reverse_lines)
  assert_true(
    !is.na(line_index),
    paste("Updated manifest line missing:", updated$path[[index]])
  )
  reverse_lines[[line_index]] <- updated$pre_line[[index]]
}
reverse_path <- tempfile(
  pattern = "h06_order46_manifest_reverse_",
  fileext = ".csv"
)
writeLines(reverse_lines, reverse_path, useBytes = TRUE)
assert_true(
  identical(
    sha256_file(reverse_path),
    "d77054228581a2700f80f0c571536ae2799a7e5ac0f6869d189767e0dfe3bb21"
  ),
  "Stage 3 manifest reverse proof failed"
)
unlink(reverse_path)

exports <- changes[
  changes$change_type == "updated" &
    grepl(
      "^artifacts/10_figures/H06/",
      changes$path
    ),
  ,
  drop = FALSE
]
assert_true(
  nrow(exports) == 11L,
  "The manifest does not record 11 refreshed exports"
)
for (index in seq_len(nrow(exports))) {
  absolute <- file.path(root, exports$path[[index]])
  row <- manifest[manifest$path == exports$path[[index]], , drop = FALSE]
  assert_true(
    identical(sha256_file(absolute), exports$post_sha256[[index]]) &&
      identical(row$sha256[[1L]], exports$post_sha256[[index]]),
    paste("Refreshed export identity drift:", exports$path[[index]])
  )
}

png_paths <- exports$path[grepl("[.]png$", exports$path)]
expected_dimensions <- list(
  H06_reader_primary_effects.png = c(2141L, 1486L),
  H06_stage3_site_specific_significance_screen.png = c(2141L, 1700L),
  H06_reader_temporal_day_type.png = c(2141L, 2582L),
  H06_reader_temporal_activity.png = c(2141L, 2582L)
)
for (path in png_paths) {
  info <- magick::image_info(magick::image_read(file.path(root, path)))
  actual <- c(info$width[[1L]], info$height[[1L]])
  assert_true(
    identical(actual, expected_dimensions[[basename(path)]]),
    paste("PNG dimension drift:", path)
  )
}

proof <- readr::read_csv(
  file.path(evidence_dir, "builder_reverse_proof.csv"),
  show_col_types = FALSE
)
assert_true(
  nrow(proof) == 2L && all(proof$reverse_matches_preimage),
  "Builder reverse proof failed"
)
for (index in seq_len(nrow(proof))) {
  assert_true(
    identical(
      sha256_file(file.path(root, proof$path[[index]])),
      proof$post_sha256[[index]]
    ),
    paste("Builder postimage drift:", proof$path[[index]])
  )
}

owner_manifest <- readr::read_csv(
  file.path(evidence_dir, "owner_evidence_manifest.csv"),
  show_col_types = FALSE,
  col_types = readr::cols(.default = readr::col_character())
)
assert_true(
  !any(
    owner_manifest$path == paste0(evidence_rel, "/owner_evidence_manifest.csv")
  ),
  "Owner evidence manifest is circular"
)
owner_paths <- file.path(root, owner_manifest$path)
assert_true(
  all(file.exists(owner_paths)),
  "Owner evidence package contains a missing file"
)
assert_true(
  identical(
    unname(vapply(owner_paths, sha256_file, character(1))),
    owner_manifest$sha256
  ) &&
    identical(
      unname(vapply(owner_paths, file_bytes, numeric(1))),
      as.numeric(owner_manifest$bytes)
    ),
  "Owner evidence package identity drift"
)

message(
  paste(
    "PASS: REPORT-018 H06 order 46 focused verifier;",
    "308 unique manifest rows, 13 updates, seven appends,",
    "11 paired exports, four visual-QA families, and all protected identities."
  )
)
