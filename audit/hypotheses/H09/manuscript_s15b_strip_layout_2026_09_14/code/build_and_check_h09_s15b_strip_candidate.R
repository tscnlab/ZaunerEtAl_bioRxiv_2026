#!/usr/bin/env Rscript

# Build and validate the bounded H09 S15B strip-label SVG candidate.

options(stringsAsFactors = FALSE, warn = 2)

required_packages <- c(
  digest = "0.6.39",
  xml2 = "1.6.0"
)
missing_packages <- names(required_packages)[
  !vapply(
    names(required_packages),
    requireNamespace,
    logical(1),
    quietly = TRUE
  )
]
if (length(missing_packages)) {
  stop(
    "Missing pinned package(s): ",
    paste(missing_packages, collapse = ", "),
    call. = FALSE
  )
}
observed_versions <- vapply(
  names(required_packages),
  function(package) as.character(utils::packageVersion(package)),
  character(1)
)
if (!identical(unname(observed_versions), unname(required_packages))) {
  stop("A verification package does not match its order pin.", call. = FALSE)
}
if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("H09 S15B candidate construction requires R 4.6.1.", call. = FALSE)
}

assert_true <- function(value, message) {
  if (!isTRUE(value)) stop(message, call. = FALSE)
}

assert_all <- function(value, message) {
  if (!length(value) || !all(value)) stop(message, call. = FALSE)
}

sha256_file <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
}

sha256_raw <- function(value) {
  digest::digest(value, algo = "sha256", serialize = FALSE)
}

read_raw_file <- function(path) {
  readBin(path, what = "raw", n = file.info(path)$size)
}

count_fixed <- function(text, pattern) {
  matches <- gregexpr(pattern, text, fixed = TRUE, useBytes = TRUE)[[1L]]
  if (matches[[1L]] == -1L) 0L else length(matches)
}

locations_fixed <- function(text, pattern) {
  matches <- gregexpr(pattern, text, fixed = TRUE, useBytes = TRUE)[[1L]]
  if (matches[[1L]] == -1L) integer() else as.integer(matches)
}

replace_fixed <- function(text, old, new) {
  gsub(old, new, text, fixed = TRUE, useBytes = TRUE)
}

attribute_string <- function(node) {
  attributes <- xml2::xml_attrs(node)
  paste(names(attributes), unname(attributes), sep = "=", collapse = "\u001f")
}

text_node_table <- function(document) {
  nodes <- xml2::xml_find_all(document, ".//*[local-name()='text']")
  data.frame(
    path = xml2::xml_path(nodes),
    text = xml2::xml_text(nodes),
    attributes = vapply(nodes, attribute_string, character(1)),
    stringsAsFactors = FALSE
  )
}

write_csv_once <- function(data, path) {
  assert_true(!file.exists(path), paste0("Evidence already exists: ", path))
  temporary <- tempfile(
    pattern = paste0(basename(path), "."),
    tmpdir = dirname(path),
    fileext = ".tmp"
  )
  on.exit(unlink(temporary), add = TRUE)
  utils::write.csv(data, temporary, row.names = FALSE, na = "")
  assert_true(file.rename(temporary, path), "Could not seal CSV evidence.")
  invisible(path)
}

write_lines_once <- function(lines, path) {
  assert_true(!file.exists(path), paste0("Evidence already exists: ", path))
  temporary <- tempfile(
    pattern = paste0(basename(path), "."),
    tmpdir = dirname(path),
    fileext = ".tmp"
  )
  on.exit(unlink(temporary), add = TRUE)
  writeLines(lines, temporary, useBytes = TRUE)
  assert_true(file.rename(temporary, path), "Could not seal text evidence.")
  invisible(path)
}

configured_project_root <- Sys.getenv(
  "H09_S15B_ORDER010A_PROJECT_ROOT",
  unset = ""
)
configured_owner_root <- Sys.getenv("H09_S15B_ORDER010A_OWNER_ROOT", unset = "")
assert_true(
  nzchar(configured_project_root) && nzchar(configured_owner_root),
  "Both H09 S15B order root variables must be explicit."
)
project_root <- normalizePath(
  configured_project_root,
  winslash = "/",
  mustWork = TRUE
)
owner_root <- normalizePath(
  configured_owner_root,
  winslash = "/",
  mustWork = TRUE
)
expected_owner_root <- file.path(
  project_root,
  "audit/hypotheses/H09/manuscript_s15b_strip_layout_2026_09_14"
)
assert_true(
  identical(owner_root, expected_owner_root),
  "The candidate root is not the sole authorized H09 owner root."
)

candidate_dir <- file.path(owner_root, "candidate")
evidence_dir <- file.path(owner_root, "evidence")
qa_dir <- file.path(owner_root, "qa")
assert_true(
  dir.exists(candidate_dir) && dir.exists(evidence_dir) && dir.exists(qa_dir),
  "The bounded owner-root directories are incomplete."
)
assert_true(
  length(list.files(candidate_dir, all.files = TRUE, no.. = TRUE)) == 0L &&
    length(list.files(evidence_dir, all.files = TRUE, no.. = TRUE)) == 0L &&
    length(list.files(qa_dir, all.files = TRUE, no.. = TRUE)) == 0L,
  "Candidate, evidence, and QA directories must be empty before construction."
)

order_path <- file.path(
  project_root,
  "audit/report_harmonization/final_documents_2026_09_13/h09_s15b_strip_candidate_order_010a.md"
)
dispatch_path <- file.path(
  project_root,
  "audit/report_harmonization/final_documents_2026_09_13/h09_s15b_strip_candidate_order_010a_dispatch_manifest.csv"
)
assert_true(
  identical(
    sha256_file(order_path),
    "d57812fe4cfb8242a51ff8e716aa02e30889ff22d7fe9e8ef806100bab4ff68d"
  ) &&
    file.info(order_path)$size == 6407 &&
    identical(
      sha256_file(dispatch_path),
      "5461baf4380ef285a4df9156edac3f4b3fbcd40ff0c396a437f7e338373546f8"
    ) &&
    file.info(dispatch_path)$size == 5711,
  "The controlling order or dispatch identity changed."
)

dispatch <- utils::read.csv(
  dispatch_path,
  stringsAsFactors = FALSE,
  check.names = FALSE
)
assert_true(
  nrow(dispatch) == 32L &&
    !anyDuplicated(dispatch$path) &&
    !sub(paste0("^", project_root, "/"), "", dispatch_path) %in%
      dispatch$path,
  "The dispatch manifest is not exact, unique, and non-circular."
)
dispatch_resolved <- file.path(project_root, dispatch$path)
dispatch_exists <- file.exists(dispatch_resolved)
dispatch_actual_sha256 <- rep(NA_character_, nrow(dispatch))
dispatch_actual_bytes <- rep(NA_real_, nrow(dispatch))
dispatch_actual_sha256[dispatch_exists] <- vapply(
  dispatch_resolved[dispatch_exists],
  sha256_file,
  character(1)
)
dispatch_actual_bytes[dispatch_exists] <- unname(
  file.info(dispatch_resolved[dispatch_exists])$size
)
dispatch_rehash <- data.frame(
  path = dispatch$path,
  expected_sha256 = dispatch$sha256,
  actual_sha256 = dispatch_actual_sha256,
  expected_bytes = as.numeric(dispatch$bytes),
  actual_bytes = dispatch_actual_bytes,
  status = ifelse(
    dispatch_exists &
      dispatch_actual_sha256 == dispatch$sha256 &
      dispatch_actual_bytes == as.numeric(dispatch$bytes),
    "PASS",
    "FAIL"
  ),
  stringsAsFactors = FALSE
)
assert_all(
  dispatch_rehash$status == "PASS",
  "A dispatch member changed before candidate construction."
)

input_path <- file.path(
  project_root,
  "audit/hypotheses/H09/report018_order72j_split_svg_export/candidate/H09_observed_timing_patterns.svg"
)
primary_path <- file.path(
  project_root,
  "audit/hypotheses/H09/report018_order72j_split_svg_export/candidate/H09_primary_effects.svg"
)
source_csv_path <- file.path(
  project_root,
  "artifacts/11_source_data/H09/H09_observed_timing_patterns_data.csv"
)
expected_protected <- data.frame(
  path = c(input_path, source_csv_path, primary_path),
  expected_sha256 = c(
    "c937252509c5de9448944358a9846842c973bac26b0f0fb4640728fcf8a908b3",
    "34640aba210181b973902e00cd6924f79f6ae76faf01fa3c5b66078e2e2e7cee",
    "a3f9bdb969c075d33adf9a0e6e751a1f967d5111856fcd0db07cbc36575a745a"
  ),
  expected_bytes = c(1245097, 3028981, 20707),
  stringsAsFactors = FALSE
)
expected_protected$actual_sha256 <- vapply(
  expected_protected$path,
  sha256_file,
  character(1)
)
expected_protected$actual_bytes <- unname(
  file.info(expected_protected$path)$size
)
expected_protected$status <- ifelse(
  expected_protected$actual_sha256 == expected_protected$expected_sha256 &
    expected_protected$actual_bytes == expected_protected$expected_bytes,
  "PASS",
  "FAIL"
)
expected_protected$path <- sub(
  paste0("^", project_root, "/"),
  "",
  expected_protected$path
)
assert_all(
  expected_protected$status == "PASS",
  "A protected H09 input changed."
)

input_raw <- read_raw_file(input_path)
input_text <- rawToChar(input_raw)
assert_true(
  identical(sha256_raw(input_raw), expected_protected$expected_sha256[[1L]]),
  "The in-memory SVG input identity changed."
)

centers <- c(185.13, 404.21, 623.28)
old_x <- c("105.65", "324.73", "543.80")
new_x <- c("89.13", "308.21", "527.28")
old_patterns <- sprintf(
  "x='%s' y='86.06' width='158.96' height='47.66'",
  old_x
)
new_patterns <- sprintf(
  "x='%s' y='86.06' width='192.00' height='47.66'",
  new_x
)
old_counts <- vapply(
  old_patterns,
  function(pattern) count_fixed(input_text, pattern),
  integer(1)
)
new_counts_before <- vapply(
  new_patterns,
  function(pattern) count_fixed(input_text, pattern),
  integer(1)
)
assert_true(
  identical(unname(old_counts), rep(2L, 3L)) &&
    identical(unname(new_counts_before), rep(0L, 3L)),
  "The exact six-match forward patch precondition failed."
)

change_rows <- vector("list", length(old_patterns))
for (index in seq_along(old_patterns)) {
  locations <- locations_fixed(input_text, old_patterns[[index]])
  assert_true(length(locations) == 2L, "A selected prefix is not two-match.")
  lines <- vapply(
    locations,
    function(location) {
      before <- substr(input_text, 1L, location)
      line_start <- max(c(0L, gregexpr("\n", before, fixed = TRUE)[[1L]])) + 1L
      after <- substr(input_text, location, nchar(input_text, type = "bytes"))
      relative_end <- regexpr("\n", after, fixed = TRUE)[[1L]]
      line_end <- if (relative_end == -1L) {
        nchar(input_text, type = "bytes")
      } else {
        location + relative_end - 2L
      }
      substr(input_text, line_start, line_end)
    },
    character(1)
  )
  assert_true(
    !grepl("style=", lines[[1L]], fixed = TRUE) &&
      grepl(
        "style='stroke-width: 1.65; stroke: #333333; fill: #D9D9D9;'",
        lines[[2L]],
        fixed = TRUE
      ),
    "The two selected rectangles are not the clip and visible-strip pair."
  )
  change_rows[[index]] <- data.frame(
    label_center_x = centers[[index]],
    rectangle_role = c("clipPath_rectangle", "visible_grey_background"),
    occurrence = 1:2,
    old_x = as.numeric(old_x[[index]]),
    old_width = 158.96,
    candidate_x = as.numeric(new_x[[index]]),
    candidate_width = 192.00,
    y = 86.06,
    height = 47.66,
    original_byte_offset = locations,
    stringsAsFactors = FALSE
  )
}
change_map <- do.call(rbind, change_rows)
assert_true(nrow(change_map) == 6L, "The literal change map is not six rows.")

candidate_text <- input_text
for (index in seq_along(old_patterns)) {
  candidate_text <- replace_fixed(
    candidate_text,
    old_patterns[[index]],
    new_patterns[[index]]
  )
}
candidate_raw <- charToRaw(candidate_text)
candidate_old_counts <- vapply(
  old_patterns,
  function(pattern) count_fixed(candidate_text, pattern),
  integer(1)
)
candidate_new_counts <- vapply(
  new_patterns,
  function(pattern) count_fixed(candidate_text, pattern),
  integer(1)
)
assert_true(
  identical(unname(candidate_old_counts), rep(0L, 3L)) &&
    identical(unname(candidate_new_counts), rep(2L, 3L)),
  "The exact six-match forward patch failed."
)

reverse_text <- candidate_text
for (index in seq_along(new_patterns)) {
  reverse_text <- replace_fixed(
    reverse_text,
    new_patterns[[index]],
    old_patterns[[index]]
  )
}
reverse_raw <- charToRaw(reverse_text)
assert_true(
  identical(reverse_raw, input_raw) &&
    identical(
      sha256_raw(reverse_raw),
      expected_protected$expected_sha256[[1L]]
    ),
  "The candidate does not reverse byte-exactly to the accepted input."
)

mask_selected <- function(text, patterns) {
  output <- text
  for (index in seq_along(patterns)) {
    output <- replace_fixed(
      output,
      patterns[[index]],
      paste0("{{ORDER010A_RECTANGLE_", index, "}}")
    )
  }
  output
}
masked_input <- mask_selected(input_text, old_patterns)
masked_candidate <- mask_selected(candidate_text, new_patterns)
assert_true(
  identical(masked_input, masked_candidate),
  "A non-selected SVG byte changed."
)

input_document <- xml2::read_xml(input_raw, options = c("NOBLANKS", "NONET"))
candidate_document <- xml2::read_xml(
  candidate_raw,
  options = c("NOBLANKS", "NONET")
)
input_text_nodes <- text_node_table(input_document)
candidate_text_nodes <- text_node_table(candidate_document)
assert_true(
  identical(input_text_nodes, candidate_text_nodes),
  "A text node, font, text position, or text attribute changed."
)

input_nodes <- xml2::xml_find_all(input_document, ".//*")
candidate_nodes <- xml2::xml_find_all(candidate_document, ".//*")
input_names <- xml2::xml_name(input_nodes)
candidate_names <- xml2::xml_name(candidate_nodes)
input_ids <- xml2::xml_attr(input_nodes, "id")
candidate_ids <- xml2::xml_attr(candidate_nodes, "id")
input_ids <- input_ids[!is.na(input_ids) & nzchar(input_ids)]
candidate_ids <- candidate_ids[!is.na(candidate_ids) & nzchar(candidate_ids)]
assert_true(
  identical(input_names, candidate_names) &&
    identical(input_ids, candidate_ids) &&
    !anyDuplicated(candidate_ids),
  "Node order, SVG identifiers, or identifier uniqueness changed."
)

candidate_attributes <- unlist(
  lapply(candidate_nodes, xml2::xml_attrs),
  use.names = FALSE
)
url_hits <- regmatches(
  candidate_attributes,
  gregexpr("url\\(#([^)]+)\\)", candidate_attributes, perl = TRUE)
)
url_hits <- unlist(url_hits, use.names = FALSE)
url_references <- if (length(url_hits)) {
  sub("^url\\(#([^)]+)\\)$", "\\1", url_hits)
} else {
  character()
}
href_values <- unlist(
  lapply(candidate_nodes, function(node) {
    attributes <- xml2::xml_attrs(node)
    attributes[names(attributes) %in% c("href", "xlink:href")]
  }),
  use.names = FALSE
)
href_references <- substring(href_values[startsWith(href_values, "#")], 2L)
references <- unique(c(url_references, href_references))
unresolved_references <- setdiff(references, candidate_ids)
assert_true(
  length(unresolved_references) == 0L,
  "The candidate contains an unresolved local SVG reference."
)

input_root <- xml2::xml_root(input_document)
candidate_root <- xml2::xml_root(candidate_document)
dimension_attributes <- c("width", "height", "viewBox")
assert_true(
  identical(
    vapply(
      dimension_attributes,
      function(attribute) xml2::xml_attr(input_root, attribute),
      character(1)
    ),
    vapply(
      dimension_attributes,
      function(attribute) xml2::xml_attr(candidate_root, attribute),
      character(1)
    )
  ) &&
    identical(xml2::xml_attr(candidate_root, "width"), "1134.00pt") &&
    identical(xml2::xml_attr(candidate_root, "height"), "918.00pt") &&
    identical(
      xml2::xml_attr(candidate_root, "viewBox"),
      "0 0 1134.00 918.00"
    ),
  "The SVG dimensions or viewBox changed."
)

selected_labels <- xml2::xml_find_all(
  candidate_document,
  ".//*[local-name()='text' and text()='MCTQ MSFsc (hours)']"
)
assert_true(length(selected_labels) == 4L, "The four MCTQ labels changed.")
label_x <- as.numeric(xml2::xml_attr(selected_labels, "x"))
label_text_length <- as.numeric(sub(
  "px$",
  "",
  xml2::xml_attr(selected_labels, "textLength")
))
label_y <- as.numeric(xml2::xml_attr(selected_labels, "y"))
assert_true(
  identical(label_x, c(centers, 984.14)) &&
    identical(label_text_length, rep(172.83, 4L)) &&
    identical(label_y, c(rep(106.79, 3L), 125.15)),
  "A required label position or extent changed."
)

selected_rectangles <- xml2::xml_find_all(
  candidate_document,
  ".//*[local-name()='rect' and @y='86.06' and @height='47.66' and @width='192.00']"
)
selected_rect_x <- as.numeric(xml2::xml_attr(selected_rectangles, "x"))
assert_true(
  length(selected_rectangles) == 6L &&
    identical(
      tabulate(match(selected_rect_x, as.numeric(new_x)), 3L),
      rep(2L, 3L)
    ),
  "The candidate does not contain exactly six selected rectangles."
)
selected_rect_style <- xml2::xml_attr(selected_rectangles, "style")
assert_true(
  sum(is.na(selected_rect_style)) == 3L &&
    sum(
      selected_rect_style ==
        "stroke-width: 1.65; stroke: #333333; fill: #D9D9D9;",
      na.rm = TRUE
    ) ==
      3L,
  "A selected rectangle style changed."
)

label_geometry <- data.frame(
  label = rep("MCTQ MSFsc (hours)", 4L),
  label_center_x = label_x,
  label_text_length = label_text_length,
  label_left = label_x - label_text_length / 2,
  label_right = label_x + label_text_length / 2,
  strip_x = c(as.numeric(new_x), 858.18),
  strip_width = c(rep(192.00, 3L), 251.91),
  strip_right = c(as.numeric(new_x), 858.18) + c(rep(192.00, 3L), 251.91),
  stringsAsFactors = FALSE
)
label_geometry$left_inset <- label_geometry$label_left - label_geometry$strip_x
label_geometry$right_inset <- label_geometry$strip_right -
  label_geometry$label_right
label_geometry$status <- ifelse(
  label_geometry$left_inset >= 0 & label_geometry$right_inset >= 0,
  "PASS",
  "FAIL"
)
assert_true(
  all(label_geometry$status == "PASS") &&
    isTRUE(all.equal(label_geometry$left_inset[1:3], rep(9.585, 3L))) &&
    isTRUE(all.equal(label_geometry$right_inset[1:3], rep(9.585, 3L))),
  "A selected label extent is not inside its enlarged strip."
)

strip_left <- label_geometry$strip_x
strip_right <- label_geometry$strip_right
adjacent_gaps <- data.frame(
  left_strip = c("selected_1", "selected_2", "selected_3"),
  right_strip = c("selected_2", "selected_3", "unchanged_boxplot"),
  left_right_edge = strip_right[1:3],
  right_left_edge = strip_left[2:4],
  gap = strip_left[2:4] - strip_right[1:3],
  stringsAsFactors = FALSE
)
adjacent_gaps$status <- ifelse(adjacent_gaps$gap > 0, "PASS", "FAIL")
assert_true(
  all(adjacent_gaps$status == "PASS"),
  "Enlarged strips overlap an adjacent strip."
)

fourth_rectangles <- xml2::xml_find_all(
  candidate_document,
  ".//*[local-name()='rect' and @x='858.18' and @y='104.42' and @width='251.91' and @height='29.30']"
)
assert_true(
  length(fourth_rectangles) == 2L &&
    label_geometry$status[[4L]] == "PASS",
  "The unchanged fourth MCTQ label or strip is incomplete."
)

structure_checks <- data.frame(
  check = c(
    "input_xml_parses",
    "candidate_xml_parses",
    "exact_six_forward_changes",
    "exact_byte_reverse",
    "all_nonselected_bytes_exact",
    "text_nodes_and_attributes_exact",
    "node_order_exact",
    "identifier_sequence_exact",
    "duplicate_ids",
    "unresolved_references",
    "dimensions_exact",
    "viewBox_exact",
    "selected_label_extents_inside",
    "selected_inset_each_side",
    "adjacent_strip_overlap",
    "unchanged_fourth_label_complete"
  ),
  expected = c(
    "PASS",
    "PASS",
    "6",
    expected_protected$expected_sha256[[1L]],
    "TRUE",
    paste0(nrow(input_text_nodes), "/", nrow(input_text_nodes)),
    as.character(length(input_names)),
    as.character(length(input_ids)),
    "0",
    "0",
    "1134.00pt x 918.00pt",
    "0 0 1134.00 918.00",
    "4/4",
    "9.585",
    "0",
    "PASS"
  ),
  actual = c(
    "PASS",
    "PASS",
    as.character(sum(candidate_new_counts)),
    sha256_raw(reverse_raw),
    as.character(identical(masked_input, masked_candidate)),
    paste0(nrow(candidate_text_nodes), "/", nrow(input_text_nodes)),
    as.character(length(candidate_names)),
    as.character(length(candidate_ids)),
    as.character(anyDuplicated(candidate_ids)),
    as.character(length(unresolved_references)),
    paste(
      xml2::xml_attr(candidate_root, "width"),
      "x",
      xml2::xml_attr(candidate_root, "height")
    ),
    xml2::xml_attr(candidate_root, "viewBox"),
    paste0(sum(label_geometry$status == "PASS"), "/4"),
    sprintf("%.3f", label_geometry$left_inset[[1L]]),
    as.character(sum(adjacent_gaps$gap <= 0)),
    ifelse(length(fourth_rectangles) == 2L, "PASS", "FAIL")
  ),
  stringsAsFactors = FALSE
)
structure_checks$status <- ifelse(
  structure_checks$expected == structure_checks$actual,
  "PASS",
  "FAIL"
)
assert_all(
  structure_checks$status == "PASS",
  "A pre-write candidate structure check failed."
)

candidate_path <- file.path(candidate_dir, "H09_observed_timing_patterns.svg")
candidate_temporary <- tempfile(
  pattern = "H09_observed_timing_patterns.",
  tmpdir = candidate_dir,
  fileext = ".tmp"
)
on.exit(unlink(candidate_temporary), add = TRUE)
writeBin(candidate_raw, candidate_temporary)
assert_true(
  identical(read_raw_file(candidate_temporary), candidate_raw),
  "The staged candidate did not round-trip byte-exactly."
)
assert_true(
  file.rename(candidate_temporary, candidate_path),
  "Could not promote the sole candidate inside the bounded owner root."
)

candidate_sha256 <- sha256_file(candidate_path)
candidate_bytes <- file.info(candidate_path)$size
assert_true(
  identical(candidate_sha256, sha256_raw(candidate_raw)) &&
    candidate_bytes == length(candidate_raw),
  "The sealed candidate identity differs from the validated bytes."
)

change_map$candidate_byte_offset <- unlist(lapply(
  seq_along(new_patterns),
  function(index) locations_fixed(candidate_text, new_patterns[[index]])
))
change_map$old_prefix <- rep(old_patterns, each = 2L)
change_map$candidate_prefix <- rep(new_patterns, each = 2L)
change_map$status <- "PASS"

forward_reverse_checks <- data.frame(
  check = c(
    "input_sha256",
    "input_bytes",
    "old_prefix_matches",
    "candidate_new_prefix_matches",
    "candidate_old_prefix_matches",
    "candidate_sha256",
    "candidate_bytes",
    "reverse_sha256",
    "reverse_bytes",
    "reverse_byte_identity",
    "masked_nonselected_sha256_input",
    "masked_nonselected_sha256_candidate",
    "masked_nonselected_identity"
  ),
  expected = c(
    expected_protected$expected_sha256[[1L]],
    as.character(expected_protected$expected_bytes[[1L]]),
    "2+2+2",
    "2+2+2",
    "0+0+0",
    candidate_sha256,
    as.character(candidate_bytes),
    expected_protected$expected_sha256[[1L]],
    as.character(expected_protected$expected_bytes[[1L]]),
    "TRUE",
    sha256_raw(charToRaw(masked_input)),
    sha256_raw(charToRaw(masked_input)),
    "TRUE"
  ),
  actual = c(
    sha256_raw(input_raw),
    as.character(length(input_raw)),
    paste(old_counts, collapse = "+"),
    paste(candidate_new_counts, collapse = "+"),
    paste(candidate_old_counts, collapse = "+"),
    candidate_sha256,
    as.character(candidate_bytes),
    sha256_raw(reverse_raw),
    as.character(length(reverse_raw)),
    as.character(identical(reverse_raw, input_raw)),
    sha256_raw(charToRaw(masked_input)),
    sha256_raw(charToRaw(masked_candidate)),
    as.character(identical(masked_input, masked_candidate))
  ),
  stringsAsFactors = FALSE
)
forward_reverse_checks$status <- ifelse(
  forward_reverse_checks$expected == forward_reverse_checks$actual,
  "PASS",
  "FAIL"
)
assert_all(
  forward_reverse_checks$status == "PASS",
  "A sealed-candidate forward or reverse check failed."
)

protected_post <- expected_protected
protected_post$current_sha256 <- vapply(
  file.path(project_root, protected_post$path),
  sha256_file,
  character(1)
)
protected_post$current_bytes <- unname(
  file.info(file.path(project_root, protected_post$path))$size
)
protected_post$post_status <- ifelse(
  protected_post$current_sha256 == protected_post$expected_sha256 &
    protected_post$current_bytes == protected_post$expected_bytes,
  "PASS",
  "FAIL"
)
assert_all(
  protected_post$post_status == "PASS",
  "A protected input changed after candidate construction."
)

candidate_summary <- data.frame(
  candidate = sub(paste0("^", project_root, "/"), "", candidate_path),
  sha256 = candidate_sha256,
  bytes = candidate_bytes,
  input_sha256 = expected_protected$expected_sha256[[1L]],
  exact_rectangle_changes = nrow(change_map),
  all_nonselected_bytes_exact = TRUE,
  reverse_byte_exact = TRUE,
  text_nodes_exact = TRUE,
  visual_status = "PENDING_REQUIRED_BROWSER_QA",
  stringsAsFactors = FALSE
)

preflight_attempts <- data.frame(
  attempt = 1:2,
  phase = "read_only_before_owner_root_creation",
  dispatch_pass = TRUE,
  writer_439_pass = TRUE,
  old_match_counts = "2+2+2",
  files_written = FALSE,
  status = c("VALIDATION_HELPER_SENTINEL_DEFECT", "PASS"),
  detail = c(
    paste(
      "The absence helper used identical() on gregexpr output carrying",
      "attributes; no-match was misreported as one. No file was written."
    ),
    paste(
      "The corrected helper tests the first gregexpr position against -1L;",
      "new-pattern counts were 0+0+0 and the owner root was absent."
    )
  ),
  stringsAsFactors = FALSE
)
construction_attempts <- data.frame(
  attempt = 1:2,
  phase = "candidate_construction_and_validation",
  candidate_written = c(FALSE, TRUE),
  evidence_written = c(FALSE, TRUE),
  status = c("STRICT_VALIDATOR_UNIT_COERCION_STOP", "PASS"),
  detail = c(
    paste(
      "Direct numeric coercion of textLength='172.83px' raised the expected",
      "unit-suffix warning under warn=2. The stop preceded every write."
    ),
    paste(
      "The validator removed only the terminal px unit before numeric",
      "comparison; the SVG transformation and all required checks passed."
    )
  ),
  stringsAsFactors = FALSE
)

write_csv_once(dispatch_rehash, file.path(evidence_dir, "dispatch_rehash.csv"))
write_csv_once(
  expected_protected,
  file.path(evidence_dir, "protected_inputs_pre.csv")
)
write_csv_once(change_map, file.path(evidence_dir, "rectangle_change_map.csv"))
write_csv_once(
  forward_reverse_checks,
  file.path(evidence_dir, "forward_reverse_checks.csv")
)
write_csv_once(
  structure_checks,
  file.path(evidence_dir, "svg_structure_checks.csv")
)
write_csv_once(label_geometry, file.path(evidence_dir, "label_geometry.csv"))
write_csv_once(
  adjacent_gaps,
  file.path(evidence_dir, "adjacent_strip_gaps.csv")
)
write_csv_once(
  protected_post,
  file.path(evidence_dir, "protected_inputs_post_candidate.csv")
)
write_csv_once(
  candidate_summary,
  file.path(evidence_dir, "candidate_summary.csv")
)
write_csv_once(
  preflight_attempts,
  file.path(evidence_dir, "preflight_attempts.csv")
)
write_csv_once(
  construction_attempts,
  file.path(evidence_dir, "construction_attempts.csv")
)
write_csv_once(
  data.frame(
    package = names(required_packages),
    version = unname(observed_versions),
    expected_version = unname(required_packages),
    status = "PASS",
    stringsAsFactors = FALSE
  ),
  file.path(evidence_dir, "package_versions.csv")
)
write_lines_once(
  c(
    paste0("R_VERSION=", getRversion()),
    paste0("LIB_PATHS=", paste(.libPaths(), collapse = "|")),
    capture.output(utils::sessionInfo())
  ),
  file.path(evidence_dir, "session_info.txt")
)
write_lines_once(
  c(
    "# H09 S15B order 010a execution command",
    "",
    paste(
      "RENV_CONFIG_AUTOLOADER_ENABLED=FALSE",
      paste0("R_LIBS='", .libPaths()[[1L]], "'"),
      paste0("H09_S15B_ORDER010A_PROJECT_ROOT='", project_root, "'"),
      paste0("H09_S15B_ORDER010A_OWNER_ROOT='", owner_root, "'"),
      "Rscript --vanilla",
      sub(
        paste0("^", project_root, "/"),
        "",
        file.path(
          owner_root,
          "code/build_and_check_h09_s15b_strip_candidate.R"
        )
      )
    )
  ),
  file.path(evidence_dir, "execution_command.md")
)

cat(sprintf(
  paste0(
    "H09_S15B_ORDER010A_CANDIDATE=PASS candidate=%s bytes=%d ",
    "changes=6 reverse=PASS nonselected=PASS text=PASS geometry=PASS ",
    "dispatch=32/32 protected=3/3 R=%s\n"
  ),
  candidate_sha256,
  candidate_bytes,
  as.character(getRversion())
))
