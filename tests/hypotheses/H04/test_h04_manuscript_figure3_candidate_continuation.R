#!/usr/bin/env Rscript

# Verify the isolated H04 manuscript Figure 3 candidate against frozen inputs.

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
    "The H04 Figure 3 candidate test requires R 4.6.1; found ",
    as.character(getRversion()),
    call. = FALSE
  )
}

required_packages <- c("digest", "png", "readr", "stringr", "tibble", "xml2")
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
    "Missing synchronized project package(s): ",
    paste(missing_packages, collapse = ", "),
    call. = FALSE
  )
}

candidate_directory <- Sys.getenv("H04_FIGURE3_CANDIDATE_DIR", unset = "")
evidence_directory <- Sys.getenv("H04_FIGURE3_EVIDENCE_DIR", unset = "")
if (!nzchar(candidate_directory) || !dir.exists(candidate_directory)) {
  stop("The candidate directory is missing.", call. = FALSE)
}
if (!nzchar(evidence_directory)) {
  stop("The candidate evidence directory is not set.", call. = FALSE)
}
candidate_directory <- normalizePath(
  candidate_directory,
  winslash = "/",
  mustWork = TRUE
)
authorized_evidence_directory <- file.path(
  root,
  "audit/hypotheses/H04/manuscript_figure3_candidate"
)
continuation_evidence_directory <- file.path(
  authorized_evidence_directory,
  "verifier_continuation_2026_08_31"
)
if (
  !identical(
    normalizePath(
      dirname(evidence_directory),
      winslash = "/",
      mustWork = TRUE
    ),
    normalizePath(
      authorized_evidence_directory,
      winslash = "/",
      mustWork = TRUE
    )
  ) ||
    !identical(
      basename(evidence_directory),
      basename(continuation_evidence_directory)
    )
) {
  stop(
    "The evidence directory is outside the authorized H04 path.",
    call. = FALSE
  )
}
if (!dir.exists(evidence_directory)) {
  dir.create(evidence_directory, recursive = TRUE, showWarnings = FALSE)
}
evidence_directory <- normalizePath(
  evidence_directory,
  winslash = "/",
  mustWork = TRUE
)
if (
  length(list.files(evidence_directory, all.files = TRUE, no.. = TRUE)) > 0L
) {
  stop(
    "The candidate evidence directory must be empty before the test.",
    call. = FALSE
  )
}

checks <- list()
record_check <- function(gate, condition, detail) {
  checks[[length(checks) + 1L]] <<- tibble::tibble(
    gate = gate,
    status = if (isTRUE(condition)) "PASS" else "FAIL",
    detail = detail
  )
  invisible(condition)
}

sha256 <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE)
}

input_path <- function(path) file.path(root, path)
candidate_path <- function(path) file.path(candidate_directory, path)

owner_order <- input_path(
  "audit/report_harmonization/owner_orders/h04_manuscript_main_figure3_candidate_only.md"
)
dispatch_manifest <- input_path(
  paste0(
    "audit/report_harmonization/owner_orders/",
    "h04_manuscript_main_figure3_candidate_only_dispatch_manifest.csv"
  )
)
record_check(
  "owner_order_identity",
  identical(
    sha256(owner_order),
    "841efaef5f49467d3e7938aded1d1496d450da53b7dd3ba95b794a4d9a1f63fa"
  ) &&
    file.info(owner_order)$size == 6044,
  "The sealed candidate-only owner order has its dispatched identity."
)
record_check(
  "dispatch_manifest_identity",
  identical(
    sha256(dispatch_manifest),
    "8fe0f26e1f3252e578dd3b7d6048e84d82bc6bbf1ee6432fc7cff896255f5ea2"
  ) &&
    file.info(dispatch_manifest)$size == 2509,
  "The sealed non-circular dispatch manifest has its dispatched identity."
)

frozen_inputs <- tibble::tribble(
  ~path,
  ~sha256_expected,
  "notebooks/hypotheses/H04.qmd",
  "f8adb6d78be041ce296dd7e89eb92769b128631c1b4227ce5d8ab3d526daf1d5",
  "_build/nathealth/notebooks/hypotheses/H04.html",
  "edb592760ee086c4b58abf7ab8946dbdf2be2c4b35bb7e6f11d84f66f71160e0",
  "artifacts/10_figures/H04/H04_temporal_near_eye.png",
  "8f048e0716e036413f541054a03c521941b4728f661871223b3e4c238991b3d4",
  "artifacts/10_figures/H04/H04_temporal_near_eye.svg",
  "2a804065daa8550523f90391350ed9ec654f3ad66dbc3d5e410ef408739a7678",
  "artifacts/10_figures/H04/H04_temporal_near_eye.pdf",
  "627376f457ec710793834755d7bde8f37389c213e10763334dfaab7b77f2d379",
  "artifacts/11_source_data/H04/H04_reader_temporal_near_eye_curves.csv",
  "97025e3f0166b8d4c896cd7504ac75c32aa49a7b315b8b17aef9929c1669d7e1",
  "artifacts/11_source_data/H04/H04_reader_temporal_near_eye_ratios.csv",
  "26a5c2de41e46894171b1442cb41da8053c633bda97d8a68b1ba514262bfc613",
  "artifacts/11_source_data/H04/H04_reader_temporal_near_eye_global.csv",
  "4f4445bb359bf3023d97b4e2445e3905950c22d570f9d47fc3ed554d12d34749",
  "artifacts/11_source_data/H04/H04_reader_temporal_near_eye_support.csv",
  "6d0a3a3b82d7c4dbbbb8863bf09307ec1ffa719f09e71593c5e9eae69516e508",
  "artifacts/09_tables/H04/H04_reader_heterogeneity_category_estimands.csv",
  "733086079d21a6bb13ea36a43020c6a0d0204f648797337dff1d6ea4dcd32084",
  "artifacts/06_model_data/H04/H04_category_support.csv",
  "bd8b8837e2357ca18466c080c6121eee6b857e4440554e662d3632cb308cd463",
  "scripts/hypotheses/H04/build_h04_stage3_reader_figures.R",
  "2ae1ae770d4b0cf3725b04cd337d883659d429ff9a8f7c482d38f0af516c158a",
  "scripts/hypotheses/H04/build_h04_stage3_reader_assets.R",
  "9fef4f87941e28c0db784d5e9ef2971cd96e1d5f8ffd55847b51ccbcc2a24c60",
  "artifacts/12_manifests/H04/H04_stage3_reader_asset_manifest.csv",
  "b7963a6bf11617ea4831ce8e53baaf1e9d6746a0bd147ca866cd1fbbb8901be3",
  "artifacts/12_manifests/H04/H04_stage3_artifacts.csv",
  "6215a9496f5f542ff92c19536b5601aa49c1ca804523eb7f9ff8bfdff852e115"
)
frozen_inputs$sha256_observed <- vapply(
  input_path(frozen_inputs$path),
  sha256,
  character(1)
)
record_check(
  "frozen_input_identities",
  all(frozen_inputs$sha256_expected == frozen_inputs$sha256_observed),
  "All 15 frozen report, display, source, builder, and manifest inputs match."
)

builder_path <- input_path(
  "scripts/hypotheses/H04/build_h04_manuscript_figure3_candidate.R"
)
test_path <- input_path(
  "tests/hypotheses/H04/test_h04_manuscript_figure3_candidate.R"
)
invisible(parse(builder_path, keep.source = TRUE))
invisible(parse(test_path, keep.source = TRUE))
record_check(
  "r_parse",
  TRUE,
  "The candidate builder and focused test both parse under R 4.6.1."
)

required_outputs <- c(
  "H04_manuscript_figure3_panel_d_source.csv",
  "H04_manuscript_figure3_category_support.csv",
  "H04_manuscript_figure3_frame_contract.csv",
  "H04_manuscript_figure3_input_identities.csv",
  "H04_manuscript_figure3_temporal_tag_boxes.csv",
  "H04_manuscript_figure3_panel_d.svg",
  "H04_manuscript_figure3_panel_d.png",
  "H04_manuscript_figure3_candidate.svg",
  "H04_manuscript_figure3_candidate.png",
  "H04_manuscript_figure3_candidate_170mm.png",
  "H04_manuscript_figure3_candidate_vector_170mm.png",
  "H04_manuscript_figure3_candidate_caption.txt",
  "H04_manuscript_figure3_candidate_outputs.csv"
)
record_check(
  "candidate_output_scope",
  all(file.exists(candidate_path(required_outputs))) &&
    setequal(list.files(candidate_directory), required_outputs),
  "Exactly the 13 authorized candidate-package files exist in the fresh temp directory."
)

output_manifest <- readr::read_csv(
  candidate_path("H04_manuscript_figure3_candidate_outputs.csv"),
  show_col_types = FALSE
)
record_check(
  "candidate_output_manifest_non_circular",
  nrow(output_manifest) == 12L &&
    !any(
      basename(output_manifest$path) ==
        basename(
          candidate_path("H04_manuscript_figure3_candidate_outputs.csv")
        )
    ) &&
    all(dirname(output_manifest$path) == candidate_directory),
  "The output inventory contains all 12 products and excludes itself."
)
manifest_identity_ok <- all(file.exists(output_manifest$path)) &&
  all(
    output_manifest$sha256 ==
      vapply(
        output_manifest$path,
        sha256,
        character(1)
      )
  )
record_check(
  "candidate_output_identities",
  manifest_identity_ok,
  "Every output listed by the non-circular temp manifest has its sealed hash."
)

input_identity_output <- readr::read_csv(
  candidate_path("H04_manuscript_figure3_input_identities.csv"),
  show_col_types = FALSE
)
record_check(
  "builder_input_identity_evidence",
  identical(input_identity_output$path, frozen_inputs$path) &&
    identical(input_identity_output$sha256, frozen_inputs$sha256_expected) &&
    identical(
      input_identity_output$observed_sha256,
      frozen_inputs$sha256_observed
    ),
  "The builder recorded the complete frozen-input identity set without drift."
)

activity_order <- c(
  "At home",
  "Working in the office/from home",
  "Outdoors",
  "On the road with public transport/car",
  "Sleeping"
)
activity_labels <- c(
  "At home" = "At home",
  "Working in the office/from home" = "Office/home working",
  "Outdoors" = "Outdoors",
  "On the road with public transport/car" = "Vehicle/public transport",
  "Sleeping" = "Sleeping"
)

frame_contract <- readr::read_csv(
  candidate_path("H04_manuscript_figure3_frame_contract.csv"),
  show_col_types = FALSE
)
expected_frame <- tibble::tibble(
  participants = 126,
  participant_days = 724,
  unique_participant_hours = 16135,
  generated_long_rows = 16875,
  effective_weighted_hours = 16135,
  sites = 9,
  exact_zero_participant_hours = 4746,
  retained_categories = 5,
  site_category_cells = 45,
  estimable_family_members = 44,
  fdr_labelled_site_deviations = 17
)
record_check(
  "exact_frame_contract",
  identical(as.data.frame(frame_contract), as.data.frame(expected_frame)),
  paste(
    "The candidate carries 126 participants, 724 days, 16,135 unique hours,",
    "16,875 long rows, 16,135 weighted hours, nine sites, 4,746 zero hours,",
    "five categories, 45 cells, 44 estimable members, and 17 FDR labels."
  )
)
order_text <- paste(readLines(owner_order, warn = FALSE), collapse = "\n")
record_check(
  "exact_zero_order_authority",
  stringr::str_detect(
    order_text,
    stringr::fixed("4,746 exact-zero participant-hours")
  ),
  "The exact-zero count agrees with the sealed order authority."
)

category_support <- readr::read_csv(
  input_path("artifacts/06_model_data/H04/H04_category_support.csv"),
  show_col_types = FALSE
)
category_support <- category_support[
  category_support$placement == "Near-eye" &
    category_support$activity %in% activity_order,
  ,
  drop = FALSE
]
category_support <- category_support[
  match(activity_order, category_support$activity),
  ,
  drop = FALSE
]
candidate_support <- readr::read_csv(
  candidate_path("H04_manuscript_figure3_category_support.csv"),
  show_col_types = FALSE
)
record_check(
  "five_category_support_source",
  identical(
    as.data.frame(candidate_support),
    as.data.frame(category_support)
  ) &&
    identical(as.character(candidate_support$activity), activity_order) &&
    sum(candidate_support$long_rows) == 16875 &&
    abs(sum(candidate_support$effective_weighted_hours) - 16135) < 1e-8 &&
    all(candidate_support$sites == 9),
  "All five category-specific sample and 1/k-weighted support fields match."
)

node_lines <- function(node) {
  collect_text <- function(current) {
    node_type <- xml2::xml_type(current)
    if (identical(node_type, "text")) {
      return(xml2::xml_text(current))
    }
    if (identical(xml2::xml_name(current), "br")) {
      return("\n")
    }
    paste(
      vapply(
        xml2::xml_contents(current),
        collect_text,
        character(1)
      ),
      collapse = ""
    )
  }
  lines <- strsplit(collect_text(node), "\n", fixed = TRUE)[[1]]
  lines <- trimws(gsub("\u00a0", " ", lines, fixed = TRUE))
  lines[nzchar(lines)]
}

accepted_html <- xml2::read_html(input_path(
  "_build/nathealth/notebooks/hypotheses/H04.html"
))
factorization_table <- xml2::xml_find_first(
  accepted_html,
  '//*[@id="tbl-h04-near-site-factorization"]//table'
)
header_nodes <- xml2::xml_find_all(factorization_table, ".//thead//th")
header_labels <- vapply(
  header_nodes,
  function(node) paste(node_lines(node), collapse = " "),
  character(1)
)
record_check(
  "panel_d_category_headers",
  identical(header_labels, c("Site", unname(activity_labels))),
  "Panel d retains the accepted five-category order and display labels."
)

body_rows <- xml2::xml_find_all(factorization_table, ".//tbody/tr")
body_rows <- body_rows[vapply(
  body_rows,
  function(row) {
    cells <- xml2::xml_find_all(row, "./td")
    length(cells) == 6L && length(node_lines(cells[[1]])) > 0L
  },
  logical(1)
)]
overall_cells <- xml2::xml_find_all(body_rows[[1]], "./td")
expected_overall <- do.call(
  rbind,
  lapply(seq_along(activity_order), function(index) {
    lines <- node_lines(overall_cells[[index + 1L]])
    tibble::tibble(
      row_type = "site_average",
      site = "Site-average estimate",
      site_color = NA_character_,
      activity = activity_order[[index]],
      display_activity = unname(activity_labels[activity_order[[index]]]),
      estimate = lines[[1]],
      confidence_interval = lines[[2]],
      fdr_p = lines[[3]],
      estimable = TRUE,
      fdr_label = !identical(activity_order[[index]], "At home")
    )
  })
)
expected_sites <- do.call(
  rbind,
  lapply(body_rows[-1L], function(row) {
    cells <- xml2::xml_find_all(row, "./td")
    site <- sub("^●[[:space:]]*", "", node_lines(cells[[1]])[[1]])
    style <- xml2::xml_attr(
      xml2::xml_find_first(cells[[1]], ".//span"),
      "style"
    )
    color <- sub(".*color:([^;]+).*", "\\1", style)
    do.call(
      rbind,
      lapply(seq_along(activity_order), function(index) {
        cell <- cells[[index + 1L]]
        lines <- node_lines(cell)
        estimable <- !identical(lines[[1]], "Not estimable")
        tibble::tibble(
          row_type = "site_deviation",
          site = site,
          site_color = color,
          activity = activity_order[[index]],
          display_activity = unname(activity_labels[activity_order[[index]]]),
          estimate = lines[[1]],
          confidence_interval = if (estimable) lines[[2]] else NA_character_,
          fdr_p = if (estimable) lines[[3]] else NA_character_,
          estimable = estimable,
          fdr_label = length(xml2::xml_find_all(cell, ".//strong")) > 0L
        )
      })
    )
  })
)
expected_panel_d <- rbind(expected_overall, expected_sites)
candidate_panel_d <- readr::read_csv(
  candidate_path("H04_manuscript_figure3_panel_d_source.csv"),
  show_col_types = FALSE
)
record_check(
  "panel_d_source_exactness",
  identical(as.data.frame(candidate_panel_d), as.data.frame(expected_panel_d)),
  paste(
    "All 50 displayed site-average and site-specific cells reproduce the",
    "accepted estimates, intervals, FDR labels, categories, colours, and sites."
  )
)
record_check(
  "panel_d_estimability_and_fdr",
  nrow(expected_sites) == 45L &&
    sum(expected_sites$estimable) == 44L &&
    sum(expected_sites$fdr_label) == 17L &&
    identical(
      expected_sites$site[!expected_sites$estimable],
      "San José (CR)"
    ) &&
    identical(
      expected_sites$activity[!expected_sites$estimable],
      "Outdoors"
    ),
  "The 45-cell, 44-member, one-non-estimable, 17-label contract is exact."
)

estimands <- readr::read_csv(
  input_path(
    "artifacts/09_tables/H04/H04_reader_heterogeneity_category_estimands.csv"
  ),
  show_col_types = FALSE
)
estimands <- estimands[
  estimands$placement == "Near-eye" & estimands$activity %in% activity_order,
  ,
  drop = FALSE
]
estimands <- estimands[
  match(activity_order, estimands$activity),
  ,
  drop = FALSE
]
expected_means <- sprintf(
  "%.1f (%.1f–%.1f) lx",
  estimands$standardized_mean_lx,
  estimands$mean_conf_low_lx,
  estimands$mean_conf_high_lx
)
record_check(
  "site_average_estimand_source",
  identical(expected_overall$estimate, expected_means),
  "Every site-average melEDI estimate and confidence interval matches its CSV source."
)

panel_d_svg <- xml2::read_xml(candidate_path(
  "H04_manuscript_figure3_panel_d.svg"
))
cell_groups <- xml2::xml_find_all(
  panel_d_svg,
  '//*[contains(concat(" ", normalize-space(@class), " "), " panel-d-cell ")]'
)
svg_cells <- do.call(
  rbind,
  lapply(seq_along(cell_groups), function(index) {
    group <- cell_groups[[index]]
    text_tokens <- xml2::xml_text(
      xml2::xml_find_all(group, "./*[local-name()='text']")
    )
    estimable <- identical(xml2::xml_attr(group, "data-estimable"), "true")
    tibble::tibble(
      row_type = xml2::xml_attr(group, "data-row-type"),
      site = xml2::xml_attr(group, "data-site"),
      activity = xml2::xml_attr(group, "data-activity"),
      estimate = text_tokens[[1]],
      confidence_interval = if (estimable) text_tokens[[2]] else NA_character_,
      fdr_p = if (estimable) text_tokens[[3]] else NA_character_,
      estimable = estimable,
      fdr_label = identical(xml2::xml_attr(group, "data-fdr-label"), "true")
    )
  })
)
record_check(
  "panel_d_vector_cell_tokens",
  nrow(svg_cells) == nrow(candidate_panel_d) &&
    identical(svg_cells$row_type, candidate_panel_d$row_type) &&
    identical(svg_cells$site, candidate_panel_d$site) &&
    identical(svg_cells$activity, candidate_panel_d$activity) &&
    identical(svg_cells$estimate, candidate_panel_d$estimate) &&
    identical(
      svg_cells$confidence_interval,
      candidate_panel_d$confidence_interval
    ) &&
    identical(svg_cells$fdr_p, candidate_panel_d$fdr_p) &&
    identical(svg_cells$estimable, candidate_panel_d$estimable) &&
    identical(svg_cells$fdr_label, candidate_panel_d$fdr_label),
  "Every panel-d vector cell displays the exact independently parsed tokens."
)

support_groups <- xml2::xml_find_all(
  panel_d_svg,
  '//*[contains(concat(" ", normalize-space(@class), " "), " category-support ")]'
)
svg_support <- do.call(
  rbind,
  lapply(support_groups, function(group) {
    tibble::tibble(
      activity = xml2::xml_attr(group, "data-activity"),
      participants = as.numeric(xml2::xml_attr(group, "data-participants")),
      participant_days = as.numeric(xml2::xml_attr(
        group,
        "data-participant-days"
      )),
      unique_participant_hours = as.numeric(xml2::xml_attr(
        group,
        "data-unique-hours"
      )),
      long_rows = as.numeric(xml2::xml_attr(group, "data-long-rows")),
      effective_weighted_hours = as.numeric(
        xml2::xml_attr(group, "data-weighted-hours")
      ),
      sites = as.numeric(xml2::xml_attr(group, "data-sites"))
    )
  })
)
record_check(
  "panel_d_vector_support_tokens",
  nrow(svg_support) == 5L &&
    identical(svg_support$activity, activity_order) &&
    identical(
      svg_support$participants,
      as.numeric(candidate_support$participants)
    ) &&
    identical(
      svg_support$participant_days,
      as.numeric(candidate_support$participant_days)
    ) &&
    identical(
      svg_support$unique_participant_hours,
      as.numeric(candidate_support$unique_participant_hours)
    ) &&
    identical(svg_support$long_rows, as.numeric(candidate_support$long_rows)) &&
    identical(
      svg_support$effective_weighted_hours,
      as.numeric(candidate_support$effective_weighted_hours)
    ) &&
    identical(svg_support$sites, as.numeric(candidate_support$sites)),
  "Every panel-d category support token matches the frozen support CSV."
)

accepted_svg_lines <- readLines(
  input_path("artifacts/10_figures/H04/H04_temporal_near_eye.svg"),
  warn = FALSE,
  encoding = "UTF-8"
)
accepted_root_open <- grep("^<svg ", accepted_svg_lines)
accepted_root_close <- tail(grep("^</svg>$", accepted_svg_lines), 1L)
accepted_inner <- accepted_svg_lines[
  (accepted_root_open + 1L):(accepted_root_close - 1L)
]
candidate_svg_lines <- readLines(
  candidate_path("H04_manuscript_figure3_candidate.svg"),
  warn = FALSE,
  encoding = "UTF-8"
)
begin_marker <- grep("^<!-- BEGIN TEMPORAL PANELS -->$", candidate_svg_lines)
end_marker <- grep("^<!-- END TEMPORAL PANELS -->$", candidate_svg_lines)
candidate_inner <- candidate_svg_lines[(begin_marker + 2L):(end_marker - 2L)]
tag_coordinates <- c("27.29" = "A", "308.04" = "B", "564.24" = "C")
expected_inner <- accepted_inner
tag_change_count <- 0L
for (coordinate in names(tag_coordinates)) {
  upper <- unname(tag_coordinates[[coordinate]])
  match_index <- grep(
    paste0(" y='", coordinate, "'.*>", upper, "</text>$"),
    expected_inner
  )
  if (length(match_index) == 1L) {
    expected_inner[[match_index]] <- sub(
      paste0(">", upper, "</text>$"),
      paste0(">", tolower(upper), "</text>"),
      expected_inner[[match_index]]
    )
    tag_change_count <- tag_change_count + 1L
  }
}
record_check(
  "temporal_svg_normalized_identity",
  tag_change_count == 3L && identical(candidate_inner, expected_inner),
  paste(
    "The embedded temporal SVG is byte-identical after exactly the three",
    "authorized uppercase-to-lowercase tag substitutions and wrapper removal."
  )
)

tag_boxes <- readr::read_csv(
  candidate_path("H04_manuscript_figure3_temporal_tag_boxes.csv"),
  show_col_types = FALSE
)
accepted_png <- png::readPNG(
  input_path("artifacts/10_figures/H04/H04_temporal_near_eye.png"),
  native = TRUE
)
candidate_png <- png::readPNG(
  candidate_path("H04_manuscript_figure3_candidate.png"),
  native = TRUE
)
accepted_pixels <- unclass(accepted_png)
candidate_pixels <- unclass(candidate_png)
candidate_top_pixels <- candidate_pixels[seq_len(length(accepted_pixels))]
difference_index <- which(accepted_pixels != candidate_top_pixels)
difference_coordinates <- cbind(
  row = ((difference_index - 1L) %/% ncol(accepted_png)) + 1L,
  col = ((difference_index - 1L) %% ncol(accepted_png)) + 1L
)
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
record_check(
  "temporal_png_decoded_pixel_identity",
  ncol(candidate_png) == ncol(accepted_png) &&
    nrow(candidate_png) > nrow(accepted_png) &&
    nrow(difference_coordinates) > 0L &&
    all(inside_authorized_box) &&
    all(each_box_changed),
  paste(
    "Decoded pixels in panels a-c are identical outside the three tag boxes,",
    "and each authorized box contains a lowercase-tag change."
  )
)

composite_svg <- xml2::read_xml(candidate_path(
  "H04_manuscript_figure3_candidate.svg"
))
all_svg_text <- xml2::xml_text(
  xml2::xml_find_all(composite_svg, ".//*[local-name()='text']")
)
lower_tags <- vapply(
  c("a", "b", "c", "d"),
  function(tag) {
    sum(all_svg_text == tag)
  },
  integer(1)
)
record_check(
  "lowercase_panel_tags",
  identical(unname(lower_tags), rep(1L, 4L)),
  "The vector candidate contains one bold lowercase tag for each panel a-d."
)

caption <- paste(
  readLines(
    candidate_path("H04_manuscript_figure3_candidate_caption.txt"),
    warn = FALSE
  ),
  collapse = " "
)
reader_text <- paste(caption, paste(all_svg_text, collapse = " "))
frame_tokens <- c(
  "126 participants",
  "724 participant-days",
  "16,135 unique participant-hours",
  "16,875 generated long rows",
  "16,135 effective weighted hours",
  "nine sites",
  "4,746 exact-zero participant-hours"
)
record_check(
  "reader_language_and_frame_note",
  stringr::str_detect(reader_text, stringr::fixed("site-average estimate")) &&
    stringr::str_detect(
      reader_text,
      stringr::fixed("activity-by-site interaction model")
    ) &&
    all(vapply(
      frame_tokens,
      function(token) stringr::str_detect(reader_text, stringr::fixed(token)),
      logical(1)
    )) &&
    !stringr::str_detect(
      tolower(reader_text),
      stringr::fixed("heterogeneity model")
    ) &&
    !stringr::str_detect(reader_text, "H04[-–—]") &&
    stringr::str_detect(reader_text, stringr::fixed("1/k")),
  paste(
    "Reader text uses the approved interaction-model vocabulary, carries the",
    "complete frame contract and 1/k note, and exposes no internal H04 label."
  )
)

png_info <- lapply(
  c(
    candidate_path("H04_manuscript_figure3_candidate.png"),
    candidate_path("H04_manuscript_figure3_candidate_170mm.png"),
    candidate_path("H04_manuscript_figure3_candidate_vector_170mm.png"),
    candidate_path("H04_manuscript_figure3_panel_d.png")
  ),
  png::readPNG,
  info = TRUE,
  native = TRUE
)
png_dimensions <- do.call(rbind, lapply(png_info, dim))
record_check(
  "candidate_dimensions",
  png_dimensions[1L, 2L] == 4725L &&
    png_dimensions[2L, 2L] == round(170 / 25.4 * 300) &&
    png_dimensions[3L, 2L] == round(170 / 25.4 * 300) &&
    png_dimensions[4L, 2L] == 4725L &&
    all(png_dimensions[, 1L] > 0L),
  "Original and 170 mm PNG and vector previews have the intended positive dimensions."
)

verification <- do.call(rbind, checks)
verification_path <- file.path(
  evidence_directory,
  "h04_manuscript_figure3_candidate_test_results.csv"
)
readr::write_csv(verification, verification_path)
readr::write_csv(
  frozen_inputs,
  file.path(
    evidence_directory,
    "h04_manuscript_figure3_candidate_frozen_input_verification.csv"
  )
)
readr::write_csv(
  frame_contract,
  file.path(
    evidence_directory,
    "h04_manuscript_figure3_candidate_frame_verification.csv"
  )
)
readr::write_csv(
  tibble::tibble(
    metric = c(
      "changed_decoded_pixels",
      "all_changes_inside_tag_boxes",
      "all_three_tag_boxes_changed",
      "accepted_temporal_width_px",
      "accepted_temporal_height_px",
      "candidate_width_px",
      "candidate_height_px"
    ),
    value = c(
      nrow(difference_coordinates),
      all(inside_authorized_box),
      all(each_box_changed),
      ncol(accepted_png),
      nrow(accepted_png),
      ncol(candidate_png),
      nrow(candidate_png)
    )
  ),
  file.path(
    evidence_directory,
    "h04_manuscript_figure3_candidate_pixel_verification.csv"
  )
)
writeLines(
  capture.output(sessionInfo()),
  file.path(
    evidence_directory,
    "h04_manuscript_figure3_candidate_session_info.txt"
  ),
  useBytes = TRUE
)

if (any(verification$status != "PASS")) {
  failed <- verification$gate[verification$status != "PASS"]
  stop(
    "H04 manuscript Figure 3 candidate test failed: ",
    paste(failed, collapse = ", "),
    call. = FALSE
  )
}

message(
  "H04 manuscript Figure 3 candidate focused test passed ",
  nrow(verification),
  "/",
  nrow(verification)
)
