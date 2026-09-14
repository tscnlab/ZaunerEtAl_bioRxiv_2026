#!/usr/bin/env Rscript

# Verifier-only continuation for the unchanged H04 Figure 3 revision-2 candidate.
# This script evaluates only the three centrally authorized corrected gates.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
project_library <- file.path(
  root,
  "renv/library/macos/R-4.6/aarch64-apple-darwin23"
)
.libPaths(c(project_library, .libPaths()))

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop(
    "The H04 Figure 3 revision-2 continuation requires R 4.6.1; found ",
    as.character(getRversion()),
    call. = FALSE
  )
}

required_packages <- c("digest", "png", "readr", "stringr", "tibble", "xml2")
missing_packages <- required_packages[
  !vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
]
if (length(missing_packages) > 0L) {
  stop(
    "Missing synchronized project package(s): ",
    paste(missing_packages, collapse = ", "),
    call. = FALSE
  )
}

candidate_directory <- Sys.getenv("H04_FIGURE3_CANDIDATE_DIR", unset = "")
evidence_directory <- Sys.getenv("H04_FIGURE3_EVIDENCE_DIR", unset = "")
if (!nzchar(candidate_directory) || !dir.exists(candidate_directory)) {
  stop("The unchanged revision-2 candidate directory is missing.", call. = FALSE)
}
if (!nzchar(evidence_directory)) {
  stop("The continuation evidence directory is not set.", call. = FALSE)
}
candidate_directory <- normalizePath(
  candidate_directory,
  winslash = "/",
  mustWork = TRUE
)
authorized_parent <- file.path(
  root,
  "audit/hypotheses/H04/manuscript_figure3_candidate"
)
expected_evidence_directory <- file.path(
  authorized_parent,
  "author_revision2_verifier_continuation_2026_08_31"
)
if (
  !identical(
    normalizePath(dirname(evidence_directory), winslash = "/", mustWork = TRUE),
    normalizePath(authorized_parent, winslash = "/", mustWork = TRUE)
  ) ||
    !identical(basename(evidence_directory), basename(expected_evidence_directory))
) {
  stop("The continuation evidence path is outside H04 ownership.", call. = FALSE)
}
if (!dir.exists(evidence_directory)) {
  dir.create(evidence_directory, recursive = TRUE, showWarnings = FALSE)
}
evidence_directory <- normalizePath(
  evidence_directory,
  winslash = "/",
  mustWork = TRUE
)
if (length(list.files(evidence_directory, all.files = TRUE, no.. = TRUE)) > 0L) {
  stop("The continuation evidence directory must be empty.", call. = FALSE)
}

input_path <- function(path) file.path(root, path)
candidate_path <- function(path) file.path(candidate_directory, path)
sha256 <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE)
}
text_sha256 <- function(value) {
  digest::digest(charToRaw(value), algo = "sha256", serialize = FALSE)
}

failed_verifier_path <- input_path(paste0(
  "tests/hypotheses/H04/",
  "test_h04_manuscript_figure3_candidate_author_revision2.R"
))
failed_evidence_directory <- input_path(paste0(
  "audit/hypotheses/H04/manuscript_figure3_candidate/",
  "author_revision2_2026_08_31"
))
failed_results_path <- file.path(
  failed_evidence_directory,
  "h04_manuscript_figure3_revision2_test_results.csv"
)
failed_pixel_path <- file.path(
  failed_evidence_directory,
  "h04_manuscript_figure3_revision2_pixel_verification.csv"
)
candidate_manifest_path <- candidate_path(
  "H04_manuscript_figure3_candidate_outputs.csv"
)
required_identity <- c(
  failed_verifier = "4dbeaf5867abd0dc7a80d5d066c39891135db693c8d4c68bc3d900fdb8786c55",
  failed_results = "4cbad35e28ecc3f6588a92297c087aa9c453f93c708317abcf602e2174a84a03",
  failed_pixel = "1a3577bc7dbf18d774627e053fc5d9cc382c0af314c4d99d53ddb089947cd9ac",
  candidate_manifest = "eaa9545ff52546f18908b0446f724fe93a659cdd764b71f0919d230f011f13a2"
)
observed_identity <- c(
  failed_verifier = sha256(failed_verifier_path),
  failed_results = sha256(failed_results_path),
  failed_pixel = sha256(failed_pixel_path),
  candidate_manifest = sha256(candidate_manifest_path)
)
if (!identical(observed_identity, required_identity)) {
  stop("The sealed failed-state or candidate manifest identity drifted.", call. = FALSE)
}

failed_results <- readr::read_csv(failed_results_path, show_col_types = FALSE)
corrected_gates <- c(
  "other_vector_numeric_tokens",
  "compact_header_support",
  "temporal_png_decoded_pixel_identity"
)
if (
  nrow(failed_results) != 22L ||
    sum(failed_results$status == "PASS") != 19L ||
    !identical(
      failed_results$gate[failed_results$status == "FAIL"],
      corrected_gates
    )
) {
  stop("The sealed 19/22 stopped-state contract drifted.", call. = FALSE)
}

# Exact forward-and-reverse proof. The three old snippets must each occur once
# in the sealed failed verifier. Reversing the three prospective substitutions
# must recreate every byte of the failed verifier source.
failed_source <- paste(readLines(failed_verifier_path, warn = FALSE), collapse = "\n")
old_blocks <- c(
  numeric = paste(
    "  identical(\n    as.numeric(xml2::xml_attr(other_overall_group, \"data-mean\")),\n    other$standardized_mean_lx\n  ) &&\n    identical(\n      as.numeric(xml2::xml_attr(other_overall_group, \"data-mean-low\")),\n      other$mean_conf_low_lx\n    ) &&\n    identical(\n      as.numeric(xml2::xml_attr(other_overall_group, \"data-mean-high\")),\n      other$mean_conf_high_lx\n    ) &&\n    identical(\n      as.numeric(xml2::xml_attr(other_overall_group, \"data-ratio\")),\n      other$ratio_to_home\n    ) &&\n    identical(\n      as.numeric(xml2::xml_attr(other_overall_group, \"data-ratio-low\")),\n      other$ratio_conf_low\n    ) &&\n    identical(\n      as.numeric(xml2::xml_attr(other_overall_group, \"data-ratio-high\")),\n      other$ratio_conf_high\n    ) &&",
    collapse = ""
  ),
  header = paste(
    "expected_support_text <- sprintf(\n  \"P %d · D %d · H %s\",\n  expected_support$participants,\n  expected_support$participant_days,\n  format(\n    expected_support$unique_participant_hours,\n    big.mark = \",\",\n    scientific = FALSE\n  )\n)",
    collapse = ""
  ),
  pixel = paste(
    "accepted_png <- png::readPNG(\n  input_path(\"artifacts/10_figures/H04/H04_temporal_near_eye.png\"),\n  native = TRUE\n)\ncandidate_png <- png::readPNG(\n  candidate_path(\"H04_manuscript_figure3_candidate.png\"),\n  native = TRUE\n)\ncandidate_top <- candidate_png[seq_len(nrow(accepted_png)), , drop = FALSE]\ndifference_index <- which(accepted_png != candidate_top)\ndifference_coordinates <- cbind(\n  row = ((difference_index - 1L) %/% ncol(accepted_png)) + 1L,\n  col = ((difference_index - 1L) %% ncol(accepted_png)) + 1L\n)",
    collapse = ""
  )
)
new_blocks <- c(
  numeric = paste(
    "  length(svg_other_values) == 6L &&\n    length(accepted_other_values) == 6L &&\n    all(vapply(\n      seq_along(svg_other_values),\n      function(index) isTRUE(all.equal(\n        svg_other_values[[index]],\n        accepted_other_values[[index]],\n        tolerance = 1e-12,\n        check.attributes = FALSE\n      )),\n      logical(1)\n    )) &&",
    collapse = ""
  ),
  header = paste(
    "expected_support_text <- vapply(\n  seq_len(nrow(expected_support)),\n  function(index) sprintf(\n    \"P %d · D %d · H %s\",\n    expected_support$participants[[index]],\n    expected_support$participant_days[[index]],\n    format(\n      expected_support$unique_participant_hours[[index]],\n      big.mark = \",\",\n      scientific = FALSE,\n      trim = TRUE\n    )\n  ),\n  character(1)\n)",
    collapse = ""
  ),
  pixel = paste(
    "accepted_png <- png::readPNG(\n  input_path(\"artifacts/10_figures/H04/H04_temporal_near_eye.png\")\n)\ncandidate_png <- png::readPNG(\n  candidate_path(\"H04_manuscript_figure3_candidate.png\")\n)\ncandidate_top <- candidate_png[\n  seq_len(dim(accepted_png)[[1]]),\n  ,\n  ,\n  drop = FALSE\n]\npixel_difference <- apply(accepted_png != candidate_top, c(1, 2), any)\ndifference_coordinates <- which(pixel_difference, arr.ind = TRUE)\ncolnames(difference_coordinates) <- c(\"row\", \"col\")",
    collapse = ""
  )
)

replace_once <- function(value, old, new) {
  positions <- gregexpr(old, value, fixed = TRUE)[[1]]
  count <- if (identical(positions[[1]], -1L)) 0L else length(positions)
  if (count != 1L) {
    stop("Expected exactly one verifier substitution target.", call. = FALSE)
  }
  sub(old, new, value, fixed = TRUE)
}

corrected_source <- failed_source
for (name in names(old_blocks)) {
  corrected_source <- replace_once(
    corrected_source,
    old_blocks[[name]],
    new_blocks[[name]]
  )
}
reversed_source <- corrected_source
for (name in rev(names(old_blocks))) {
  reversed_source <- replace_once(
    reversed_source,
    new_blocks[[name]],
    old_blocks[[name]]
  )
}
reverse_proof_ok <- identical(reversed_source, failed_source)
if (!reverse_proof_ok) {
  stop("The continuation reverse proof failed.", call. = FALSE)
}

panel_d_svg <- xml2::read_xml(
  candidate_path("H04_manuscript_figure3_panel_d.svg")
)
other_overall_group <- xml2::xml_find_first(
  panel_d_svg,
  paste0(
    '//*[contains(concat(" ", normalize-space(@class), " "), ',
    '" panel-d-cell ") and @data-row-type="site_average" and ',
    '@data-activity="Other/unspecified activity"]'
  )
)
svg_other_values <- c(
  as.numeric(xml2::xml_attr(other_overall_group, "data-mean")),
  as.numeric(xml2::xml_attr(other_overall_group, "data-mean-low")),
  as.numeric(xml2::xml_attr(other_overall_group, "data-mean-high")),
  as.numeric(xml2::xml_attr(other_overall_group, "data-ratio")),
  as.numeric(xml2::xml_attr(other_overall_group, "data-ratio-low")),
  as.numeric(xml2::xml_attr(other_overall_group, "data-ratio-high"))
)
other_source <- readr::read_csv(
  input_path("artifacts/09_tables/H04/H04_reader_category_estimands.csv"),
  show_col_types = FALSE
)
other <- other_source[
  other_source$placement == "Near-eye" &
    other_source$activity == "Other/unspecified activity",
  ,
  drop = FALSE
]
accepted_other_values <- c(
  other$standardized_mean_lx,
  other$mean_conf_low_lx,
  other$mean_conf_high_lx,
  other$ratio_to_home,
  other$ratio_conf_low,
  other$ratio_conf_high
)
numeric_gate <- length(svg_other_values) == 6L &&
  length(accepted_other_values) == 6L &&
  all(vapply(
    seq_along(svg_other_values),
    function(index) isTRUE(all.equal(
      svg_other_values[[index]],
      accepted_other_values[[index]],
      tolerance = 1e-12,
      check.attributes = FALSE
    )),
    logical(1)
  )) &&
  identical(
    xml2::xml_attr(other_overall_group, "data-model-source"),
    "additive_display_only"
  ) &&
  identical(
    xml2::xml_attr(other_overall_group, "data-p-text"),
    "Additive display only"
  ) &&
  nrow(other) == 1L &&
  other$inferential_role == "DISPLAY_ONLY" &&
  is.na(other$ratio_p_adjusted)

activity_order <- c(
  "At home",
  "Working in the office/from home",
  "Outdoors",
  "On the road with public transport/car",
  "Sleeping",
  "Other/unspecified activity"
)
expected_support <- readr::read_csv(
  input_path("artifacts/11_source_data/H04/H04_preparation_category_support.csv"),
  show_col_types = FALSE
)
expected_support <- expected_support[
  expected_support$placement == "Near-eye" &
    expected_support$activity %in% activity_order,
  ,
  drop = FALSE
]
expected_support <- expected_support[
  match(activity_order, expected_support$activity),
  ,
  drop = FALSE
]
support_groups <- xml2::xml_find_all(
  panel_d_svg,
  '//*[contains(concat(" ", normalize-space(@class), " "), " category-support ")]'
)
support_text <- vapply(
  support_groups,
  function(group) {
    texts <- xml2::xml_text(
      xml2::xml_find_all(group, './*[local-name()="text"]')
    )
    tail(texts, 1L)
  },
  character(1)
)
expected_support_text <- vapply(
  seq_len(nrow(expected_support)),
  function(index) sprintf(
    "P %d · D %d · H %s",
    expected_support$participants[[index]],
    expected_support$participant_days[[index]],
    format(
      expected_support$unique_participant_hours[[index]],
      big.mark = ",",
      scientific = FALSE,
      trim = TRUE
    )
  ),
  character(1)
)
support_nodes <- xml2::xml_find_all(
  panel_d_svg,
  '//*[contains(concat(" ", normalize-space(@class), " "), " category-support ")]/*[local-name()="text"]'
)
support_y <- as.numeric(xml2::xml_attr(support_nodes, "y"))
one_support_line_per_group <- vapply(
  support_groups,
  function(group) {
    group_y <- as.numeric(xml2::xml_attr(
      xml2::xml_find_all(group, './*[local-name()="text"]'),
      "y"
    ))
    sum(group_y == 112) == 1L
  },
  logical(1)
)
header_gate <- nrow(expected_support) == 6L &&
  length(support_groups) == 6L &&
  identical(support_text, expected_support_text) &&
  all(one_support_line_per_group) &&
  identical(sort(unique(support_y)), c(74, 82, 89, 112)) &&
  !any(stringr::str_detect(
    support_text,
    "(?:^|·\\s)(?:R|WH|S)\\s"
  ))

tag_boxes <- readr::read_csv(
  candidate_path("H04_manuscript_figure3_temporal_tag_boxes.csv"),
  show_col_types = FALSE
)
accepted_png <- png::readPNG(
  input_path("artifacts/10_figures/H04/H04_temporal_near_eye.png")
)
candidate_png <- png::readPNG(
  candidate_path("H04_manuscript_figure3_candidate.png")
)
candidate_top <- candidate_png[
  seq_len(dim(accepted_png)[[1]]),
  ,
  ,
  drop = FALSE
]
pixel_difference <- apply(accepted_png != candidate_top, c(1, 2), any)
difference_coordinates <- which(pixel_difference, arr.ind = TRUE)
colnames(difference_coordinates) <- c("row", "col")
inside_authorized_box <- rep(FALSE, nrow(difference_coordinates))
for (index in seq_len(nrow(tag_boxes))) {
  inside_authorized_box <- inside_authorized_box |
    (difference_coordinates[, "row"] >= tag_boxes$y_start[[index]] &
      difference_coordinates[, "row"] <= tag_boxes$y_end[[index]] &
      difference_coordinates[, "col"] >= tag_boxes$x_start[[index]] &
      difference_coordinates[, "col"] <= tag_boxes$x_end[[index]])
}
each_box_changed <- vapply(
  seq_len(nrow(tag_boxes)),
  function(index) {
    any(
      difference_coordinates[, "row"] >= tag_boxes$y_start[[index]] &
        difference_coordinates[, "row"] <= tag_boxes$y_end[[index]] &
        difference_coordinates[, "col"] >= tag_boxes$x_start[[index]] &
        difference_coordinates[, "col"] <= tag_boxes$x_end[[index]]
    )
  },
  logical(1)
)
pixel_gate <- nrow(tag_boxes) == 6L &&
  nrow(difference_coordinates) == 5650L &&
  all(inside_authorized_box) &&
  all(each_box_changed)

continuation_results <- tibble::tibble(
  gate = corrected_gates,
  status = ifelse(c(numeric_gate, header_gate, pixel_gate), "PASS", "FAIL"),
  detail = c(
    paste(
      "Six Other numeric attributes agree at tolerance 1e-12; source model,",
      "display-only role, and absent p-value are exact."
    ),
    paste(
      "Six rowwise scalar-formatted P/D/H strings, one support line per header,",
      "allowed y positions, and absence of R/WH/S are exact."
    ),
    paste(
      "Numeric channel-reduced comparison finds exactly 5,650 changed pixels,",
      "all inside all six authorized old/new tag boxes."
    )
  )
)

reverse_proof <- tibble::tibble(
  item = c(
    "failed_verifier_sha256",
    "corrected_in_memory_sha256",
    "reversed_in_memory_sha256",
    "reverse_byte_identity",
    "substitution_blocks"
  ),
  value = c(
    sha256(failed_verifier_path),
    text_sha256(corrected_source),
    text_sha256(reversed_source),
    reverse_proof_ok,
    length(old_blocks)
  )
)
numeric_evidence <- tibble::tibble(
  field = c(
    "mean",
    "mean_conf_low",
    "mean_conf_high",
    "ratio_to_home",
    "ratio_conf_low",
    "ratio_conf_high"
  ),
  svg_value = svg_other_values,
  accepted_value = accepted_other_values,
  absolute_difference = abs(svg_other_values - accepted_other_values),
  tolerance = 1e-12
)
header_evidence <- tibble::tibble(
  activity = activity_order,
  rendered = support_text,
  expected = expected_support_text,
  exact = support_text == expected_support_text,
  one_support_line = one_support_line_per_group
)
pixel_evidence <- tibble::tibble(
  metric = c(
    "changed_decoded_pixels",
    "tag_boxes",
    "all_changes_inside_tag_boxes",
    "all_six_tag_boxes_changed",
    "accepted_temporal_width_px",
    "accepted_temporal_height_px",
    "candidate_width_px",
    "candidate_height_px"
  ),
  value = c(
    nrow(difference_coordinates),
    nrow(tag_boxes),
    all(inside_authorized_box),
    all(each_box_changed),
    dim(accepted_png)[[2]],
    dim(accepted_png)[[1]],
    dim(candidate_png)[[2]],
    dim(candidate_png)[[1]]
  )
)

completed_results <- failed_results
for (gate in corrected_gates) {
  index <- match(gate, completed_results$gate)
  continuation_index <- match(gate, continuation_results$gate)
  completed_results$status[[index]] <- continuation_results$status[[
    continuation_index
  ]]
  completed_results$detail[[index]] <- paste(
    "Verifier continuation:",
    continuation_results$detail[[continuation_index]]
  )
}
completed_results$verification_source <- ifelse(
  completed_results$gate %in% corrected_gates,
  "authorized_continuation",
  "sealed_initial_verifier"
)

continuation_results_path <- file.path(
  evidence_directory,
  "h04_manuscript_figure3_revision2_continuation_results.csv"
)
completed_results_path <- file.path(
  evidence_directory,
  "h04_manuscript_figure3_revision2_completed_22_gate_results.csv"
)
reverse_proof_path <- file.path(
  evidence_directory,
  "h04_manuscript_figure3_revision2_reverse_proof.csv"
)
numeric_evidence_path <- file.path(
  evidence_directory,
  "h04_manuscript_figure3_revision2_other_numeric_evidence.csv"
)
header_evidence_path <- file.path(
  evidence_directory,
  "h04_manuscript_figure3_revision2_header_evidence.csv"
)
pixel_evidence_path <- file.path(
  evidence_directory,
  "h04_manuscript_figure3_revision2_corrected_pixel_evidence.csv"
)
session_path <- file.path(
  evidence_directory,
  "h04_manuscript_figure3_revision2_continuation_session_info.txt"
)
readr::write_csv(continuation_results, continuation_results_path)
readr::write_csv(completed_results, completed_results_path)
readr::write_csv(reverse_proof, reverse_proof_path)
readr::write_csv(numeric_evidence, numeric_evidence_path)
readr::write_csv(header_evidence, header_evidence_path)
readr::write_csv(pixel_evidence, pixel_evidence_path)
writeLines(capture.output(sessionInfo()), session_path, useBytes = TRUE)

evidence_paths <- c(
  continuation_results_path,
  completed_results_path,
  reverse_proof_path,
  numeric_evidence_path,
  header_evidence_path,
  pixel_evidence_path,
  session_path
)
evidence_manifest <- tibble::tibble(
  role = c(
    "three_gate_continuation",
    "completed_22_gate_results",
    "reverse_proof",
    "other_numeric_evidence",
    "compact_header_evidence",
    "corrected_pixel_evidence",
    "session_info"
  ),
  path = evidence_paths,
  sha256 = vapply(evidence_paths, sha256, character(1)),
  bytes = as.numeric(file.info(evidence_paths)$size),
  r_version = as.character(getRversion())
)
readr::write_csv(
  evidence_manifest,
  file.path(
    evidence_directory,
    "h04_manuscript_figure3_revision2_continuation_manifest.csv"
  )
)

if (
  any(continuation_results$status != "PASS") ||
    any(completed_results$status != "PASS") ||
    !reverse_proof_ok
) {
  failed <- continuation_results$gate[
    continuation_results$status != "PASS"
  ]
  stop(
    "H04 Figure 3 revision-2 continuation failed: ",
    paste(failed, collapse = ", "),
    call. = FALSE
  )
}

message(
  "H04 manuscript Figure 3 revision-2 continuation passed 3/3; ",
  "combined completion is 22/22."
)
