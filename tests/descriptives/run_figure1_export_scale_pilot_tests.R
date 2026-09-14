# Verify the corrected Figure 1-only export-scale showcase.

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)

assert_true <- function(condition, message) {
  if (!isTRUE(condition)) stop(message, call. = FALSE)
  invisible(condition)
}

assert_equal <- function(actual, expected, message, tolerance = 1e-10) {
  if (!isTRUE(all.equal(actual, expected, tolerance = tolerance))) {
    stop(
      message,
      "\nExpected: ",
      paste(expected, collapse = ", "),
      "\nObserved: ",
      paste(actual, collapse = ", "),
      call. = FALSE
    )
  }
  invisible(actual)
}

changed_r_files <- file.path(
  root,
  c(
    "scripts/descriptives/plot_descriptive_replications.R",
    "scripts/descriptives/descriptive_contract.R",
    "scripts/descriptives/build_descriptives.R",
    "scripts/descriptives/run_descriptive_overview_export_scale_pilot.R",
    "scripts/descriptives/run_figure1_2_display_refresh.R",
    "tests/descriptives/run_figure1_export_scale_pilot_tests.R"
  )
)
invisible(lapply(changed_r_files, parse))

source(file.path(root, "scripts/descriptives/build_descriptives.R"))
source_descriptive_modules(root)

spec <- descriptive_figure_spec()
pilot_spec <- spec[spec$figure_id == "descriptive_overview", , drop = FALSE]
assert_true(nrow(pilot_spec) == 1L, "Figure 1 is absent from the figure spec.")
assert_equal(
  unname(unlist(pilot_spec[c(
    "base_width_in",
    "base_height_in",
    "export_scale_multiplier",
    "export_width_in",
    "export_height_in",
    "print_display_width_mm",
    "dpi"
  )])),
  c(10.5, 10, 1.5, 15.75, 15, 170, 300),
  "The corrected Figure 1 export contract changed."
)
assert_true(
  identical(pilot_spec$html_out_width, "100%"),
  "Figure 1 is not displayed at 100% HTML width."
)
assert_equal(
  pilot_spec$effective_min_essential_text_pt,
  pilot_spec$nominal_min_essential_text_pt *
    pilot_spec$display_reduction_factor,
  "The Figure 1 effective text-size calculation is stale."
)
assert_true(
  identical(
    pilot_spec$physical_size_qa,
    "AUTHOR_ACCEPTED_FINAL"
  ),
  "The Figure 1 author-acceptance status is not current."
)

profile_scale <- replica_profile_y_scale(include_context_baseline = TRUE)
assert_true(
  identical(profile_scale$trans$name, "symlog-1-10-1"),
  "The Figure 1--3 profile helper is not LightLogR symlog threshold 1."
)

overview_function_names <- c(
  "replica_recommendation_bracket",
  "make_site_map_replica_plot",
  "make_collection_replica_plot",
  "make_photoperiod_replica_plot",
  "make_overall_profile_replica_plot",
  "make_overview_replica_figure"
)
overview_code <- paste(
  vapply(
    overview_function_names,
    function(name)
      paste(deparse(get(name, mode = "function")), collapse = "\n"),
    character(1)
  ),
  collapse = "\n"
)
assert_true(
  !grepl(
    "visual_scale_multiplier|export_scale_multiplier|font_size = 10\\.5|font_size = 11",
    overview_code
  ),
  "A Figure 1 helper still contains a pilot multiplier or reduced base theme."
)
assert_true(
  sum(grepl("theme_cowplot\\(\\)", strsplit(overview_code, "\n")[[1L]])) >= 4L,
  "The submitted default 14-pt cowplot themes were not restored."
)
assert_true(
  grepl("size = 3.5", overview_code, fixed = TRUE) &&
    !grepl("size = 2.7", overview_code, fixed = TRUE),
  "The requested enlarged map-label size is absent."
)

paths <- descriptive_paths(root)

locations <- read_plot_source_csv(file.path(
  paths$source_dir,
  "site_locations.csv"
))
world <- read_plot_source_csv(file.path(paths$source_dir, "world_map_wkt.csv"))
collection_intervals <- read_plot_source_csv(file.path(
  paths$source_dir,
  "collection_intervals.csv"
)) |>
  dplyr::mutate(
    interval_start = as.Date(.data$interval_start),
    interval_end = as.Date(.data$interval_end)
  )
collection_days <- read_plot_source_csv(file.path(
  paths$source_dir,
  "available_collection_days.csv"
)) |>
  dplyr::mutate(local_date = as.Date(.data$local_date))
profile <- read_plot_source_csv(file.path(
  paths$source_dir,
  "profile_summary.csv"
))
state <- read_plot_source_csv(file.path(
  paths$source_dir,
  "profile_context_bands.csv"
))
period <- read_plot_source_csv(file.path(
  paths$source_dir,
  "profile_average_periods.csv"
))
protocol_path <- file.path(root, "assets", "2026-03-30_MeLiDos_Protocol.png")

component_plots <- list(
  protocol = make_protocol_replica_plot(protocol_path),
  map = make_site_map_replica_plot(locations, world),
  collection = make_collection_replica_plot(collection_intervals),
  photoperiod = make_photoperiod_replica_plot(collection_days),
  profile = make_overall_profile_replica_plot(profile, state, period)
)
map_label_data <- component_plots$map$layers[[4L]]$data
assert_true(
  all(grepl(" — ", map_label_data$label, fixed = TRUE)) &&
    all(grepl("°", map_label_data$label, fixed = TRUE)) &&
    all(vapply(
      descriptive_site_reader_labels(),
      function(site_label) any(startsWith(map_label_data$label, site_label)),
      logical(1)
    )),
  "Panel B does not restore registered names plus country and coordinates."
)
expected_map_anchors <- data.frame(
  site = descriptive_site_order(),
  label_longitude = c(
    12.9,
    -127.2,
    0,
    20.6,
    20.6,
    -127.2,
    26.6,
    -84.1,
    -1.6
  ),
  label_latitude = c(77, 52, 65, 60, 48, 40.4, 30, 19, -2),
  label_hjust = c(0.5, 0, 1, 0, 0, 0, 0.5, 0.5, 0.5),
  stringsAsFactors = FALSE
)
observed_map_anchors <- map_label_data |>
  dplyr::select(
    "site",
    "label_longitude",
    "label_latitude",
    "label_hjust"
  ) |>
  dplyr::arrange(match(.data$site, descriptive_site_order()))
assert_true(
  isTRUE(all.equal(
    observed_map_anchors,
    expected_map_anchors,
    tolerance = 0,
    check.attributes = FALSE
  )),
  "Panel B does not use the reviewed non-overlapping map-label anchors."
)
map_segment_data <- component_plots$map$layers[[2L]]$data
assert_true(
  identical(map_segment_data$site, c("BAUA", "MPI", "TUM")) &&
    identical(map_segment_data$connection_longitude, c(0, 20.6, 20.6)) &&
    identical(map_segment_data$connection_latitude, c(62, 60, 48)),
  paste(
    "Panel B must connect only the three German sites and terminate at the",
    "reviewed Dortmund, Tübingen, and Munich label edges."
  )
)
annotation_layers <- component_plots$profile$layers[
  vapply(
    component_plots$profile$layers,
    function(layer) {
      "label" %in%
        names(layer$data) &&
        all(
          c(
            "label_x",
            "arrow_x",
            "arrow_y",
            "target_x",
            "target_y"
          ) %in%
            names(layer$data)
        )
    },
    logical(1)
  )
]
assert_true(
  length(annotation_layers) == 2L &&
    all(vapply(
      annotation_layers,
      function(layer) nrow(layer$data) == 4L,
      logical(1)
    )) &&
    setequal(
      annotation_layers[[1L]]$data$label,
      c(
        "Central 90% of values",
        "Central 50% of values",
        "Pooled median",
        "Site median"
      )
    ) &&
    isTRUE(all.equal(
      annotation_layers[[1L]]$data$label_x,
      c(1241.631713, 1241.631713, 1321.002743, 1355.015267),
      tolerance = 1e-6
    )) &&
    identical(
      annotation_layers[[1L]]$data$label_center_x,
      rep(1500, 4)
    ) &&
    identical(
      annotation_layers[[1L]]$data$label_center_y,
      c(15000, 6500, 2800, 1200)
    ) &&
    identical(
      annotation_layers[[1L]]$data$target_site,
      c("Overall", "Overall", "Overall", "UCR")
    ) &&
    identical(
      annotation_layers[[1L]]$data$target_x,
      c(1950, 2040, 2010, 1935)
    ) &&
    isTRUE(all.equal(
      annotation_layers[[1L]]$data$arrow_x,
      2 *
        annotation_layers[[1L]]$data$label_center_x -
        annotation_layers[[1L]]$data$label_x,
      tolerance = 1e-8
    )) &&
    identical(
      annotation_layers[[1L]]$data$arrow_y,
      annotation_layers[[1L]]$data$label_y
    ) &&
    all(
      annotation_layers[[1L]]$data$arrow_x <
        annotation_layers[[1L]]$data$target_x
    ),
  paste(
    "Panel E annotations are not centred at 01:00 on day two or their",
    "lower-right leaders do not point exclusively to right-day data."
  )
)
assert_true(
  any(vapply(
    annotation_layers,
    function(layer) inherits(layer$geom, "GeomSegment"),
    logical(1)
  )) &&
    !any(vapply(
      annotation_layers,
      function(layer) inherits(layer$geom, "GeomCurve"),
      logical(1)
    )),
  "Panel E annotation leaders must be straight segments, not curves."
)
annotation_data <- annotation_layers[[1L]]$data
profile_symlog <- LightLogR::symlog_trans(
  base = 10,
  thr = 1,
  scale = 1
)$transform
profile_panel_width_in <- 7.87945
profile_panel_height_in <- 3.556003
leader_width_in <-
  (annotation_data$target_x - annotation_data$arrow_x) /
  2880 *
  profile_panel_width_in
leader_height_in <-
  (profile_symlog(annotation_data$arrow_y) -
    profile_symlog(annotation_data$target_y)) /
  diff(profile_symlog(c(-0.35, 20000))) *
  profile_panel_height_in
assert_true(
  max(abs(leader_width_in / leader_height_in - 1)) < 0.09,
  "Panel E annotation leaders do not leave their labels at about 45 degrees."
)
annotation_label_layer <- annotation_layers[[which(vapply(
  annotation_layers,
  function(layer) inherits(layer$geom, "GeomLabel"),
  logical(1)
))]]
assert_true(
  identical(annotation_label_layer$aes_params$hjust, 0) &&
    identical(annotation_label_layer$aes_params$vjust, 0),
  "Panel E labels are not anchored by their lower-left corners."
)
assert_true(
  all(c("value_lower_90_lx", "value_upper_90_lx") %in% names(profile)) &&
    grepl("value_lower_50_lx", overview_code, fixed = TRUE) &&
    grepl("value_lower_90_lx", overview_code, fixed = TRUE) &&
    grepl("ymin = -Inf, ymax = -0.1", overview_code, fixed = TRUE),
  "The Figure 1 profile lacks its 50%/90% ribbons or corrected sleep strip."
)
assert_true(
  grepl("text_size = 12", overview_code, fixed = TRUE) &&
    grepl("label_hjust = rep(0.5, 3)", overview_code, fixed = TRUE),
  "Panel E does not match its 12-pt outer ticks or center the inner labels."
)

resolved_text_size <- function(plot, element) {
  resolved <- ggplot2::calc_element(element, plot$theme)
  if (inherits(resolved, "element_blank") || is.null(resolved$size)) {
    return(NA_real_)
  }
  resolved$size
}

for (panel in c("map", "collection", "photoperiod", "profile")) {
  assert_equal(
    unname(vapply(
      c("axis.text.x", "axis.text.y"),
      function(element) resolved_text_size(component_plots[[panel]], element),
      numeric(1)
    )),
    c(12, 12),
    paste("Panel", panel, "does not retain the submitted 12-pt tick text.")
  )
  assert_equal(
    unname(vapply(
      c("axis.title.x", "axis.title.y", "plot.tag"),
      function(element) resolved_text_size(component_plots[[panel]], element),
      numeric(1)
    )),
    c(14, 14, 14),
    paste("Panel", panel, "does not retain the submitted 14-pt titles/tags.")
  )
  assert_equal(
    resolved_text_size(component_plots[[panel]], "plot.caption"),
    11,
    paste("Panel", panel, "does not retain the submitted 11-pt caption text.")
  )
}
assert_equal(
  resolved_text_size(component_plots$protocol, "plot.tag"),
  14,
  "The protocol panel does not retain the submitted 14-pt tag."
)
map_layer_sizes <- vapply(
  component_plots$map$layers,
  function(layer) {
    if (is.null(layer$aes_params$size)) NA_real_ else layer$aes_params$size
  },
  numeric(1)
)
assert_equal(
  unname(map_layer_sizes[!is.na(map_layer_sizes)]),
  c(3, 3.5),
  "The map does not retain 3-unit points and 3.5-unit labels."
)

overview_plot <- make_overview_replica_figure(
  protocol_asset_path = protocol_path,
  site_locations = locations,
  world_map = world,
  collection_intervals = collection_intervals,
  collection_days = collection_days,
  profile = profile,
  state_source = state,
  period_source = period
)
overview_grob <- patchwork::patchworkGrob(overview_plot)
tag_records <- list()
collect_panel_tags <- function(grob) {
  if (
    inherits(grob, "text") &&
      length(grob$label) == 1L &&
      grob$label %in% LETTERS[1:5]
  ) {
    tag_records[[length(tag_records) + 1L]] <<- data.frame(
      label = grob$label,
      size_pt = grob$gp$fontsize,
      stringsAsFactors = FALSE
    )
  }
  if (!is.null(grob$grobs)) {
    invisible(lapply(grob$grobs, collect_panel_tags))
  }
  if (!is.null(grob$children)) {
    invisible(lapply(grob$children, collect_panel_tags))
  }
  invisible(NULL)
}
collect_panel_tags(overview_grob)
tag_records <- do.call(rbind, tag_records)
tag_records <- tag_records[order(tag_records$label), , drop = FALSE]
assert_true(
  identical(tag_records$label, LETTERS[1:5]),
  "The assembled Figure 1 does not contain exactly the A--E panel tags."
)
assert_equal(
  tag_records$size_pt,
  rep(14, 5),
  "The assembled Figure 1 panel tags are not all 14 pt."
)

overview_png <- file.path(paths$figure_dir, "descriptive_overview.png")
overview_a4 <- file.path(
  paths$diagnostic_dir,
  "a4_mockups",
  "descriptive_overview_a4.png"
)
submitted_png <- file.path(root, "figures", "Fig1.png")
assert_true(
  identical(
    artifact_sha256(submitted_png),
    "3933c77a9d9c64f3155f5c460619e586ba7f9a5c3ad20b97d99e7e58409344a1"
  ),
  "The retained submitted Figure 1 reference is not the audited original."
)
assert_equal(
  unname(read_png_dimensions(submitted_png)),
  c(4725L, 4500L),
  "The retained submitted Figure 1 is not 4725 by 4500 pixels."
)
assert_equal(
  unname(read_png_dimensions(overview_png)),
  c(4725L, 4500L),
  "Figure 1 is not exactly 4725 by 4500 pixels."
)
assert_equal(
  unname(read_png_dimensions(overview_a4)),
  c(1240L, 1754L),
  "The Figure 1 A4 mock-up does not have the expected 150-dpi dimensions."
)

manifest_path <- file.path(paths$manifest_dir, "descriptive_artifacts.csv")
manifest <- readr::read_csv(manifest_path, show_col_types = FALSE)
manifest_paths <- file.path(root, manifest$path)
assert_true(
  all(file.exists(manifest_paths)),
  "A manifested artifact is missing."
)
assert_true(
  identical(
    unname(vapply(manifest_paths, artifact_sha256, character(1))),
    manifest$sha256
  ),
  "At least one descriptive manifest hash is stale."
)

overview_manifest <- manifest[
  manifest$figure_id == "descriptive_overview" &
    manifest$artifact_type %in%
      c(
        "descriptive_figure_png",
        "descriptive_figure_jpeg",
        "descriptive_figure_pdf",
        "descriptive_figure_svg"
      ),
  ,
  drop = FALSE
]
assert_true(
  nrow(overview_manifest) == 4L &&
    all(overview_manifest$width_in == 15.75) &&
    all(overview_manifest$height_in == 15) &&
    all(
      overview_manifest$producer %in%
        c(
          "scripts/descriptives/run_descriptive_overview_export_scale_pilot.R",
          "scripts/descriptives/build_descriptives.R"
        )
    ),
  "The Figure 1 export manifest does not record the approved scale contract."
)

other_figure_ids <- setdiff(spec$figure_id, "descriptive_overview")
other_paths <- c(
  file.path(paths$figure_dir, paste0(other_figure_ids, ".png")),
  file.path(
    paths$diagnostic_dir,
    "a4_mockups",
    paste0(other_figure_ids, "_a4.png")
  )
)
assert_true(
  all(file.exists(other_paths)) &&
    all(nzchar(vapply(other_paths, artifact_sha256, character(1)))),
  "A descriptive PNG or diagnostic A4 mock-up is missing after the full build."
)

source_map <- readr::read_csv(
  file.path(paths$manifest_dir, "figure_source_data_map.csv"),
  show_col_types = FALSE
)
overview_sources <- source_map[
  source_map$figure_id == "descriptive_overview",
  ,
  drop = FALSE
]
overview_source_paths <- file.path(root, overview_sources$source_data_path)
assert_true(
  nrow(overview_sources) == 8L && all(file.exists(overview_source_paths)),
  "The Figure 1 source-data map is incomplete."
)
assert_true(
  identical(
    unname(vapply(overview_source_paths, artifact_sha256, character(1))),
    overview_sources$source_data_sha256
  ),
  "A Figure 1 source-data hash is stale."
)

html_path <- file.path(root, "_build/nathealth/notebooks/descriptives.html")
assert_true(
  file.exists(html_path),
  "The rendered descriptives HTML is missing."
)
html <- xml2::read_html(html_path)
overview_img <- xml2::xml_find_all(
  html,
  "//*[@id='fig-descriptive-overview']//img"
)
assert_true(length(overview_img) == 1L, "Figure 1 is not unique in the HTML.")
img_src <- xml2::xml_attr(overview_img, "src")
img_style <- xml2::xml_attr(overview_img, "style")
img_alt <- xml2::xml_attr(overview_img, "alt")
html_asset_path <- normalizePath(
  file.path(dirname(html_path), img_src),
  winslash = "/",
  mustWork = TRUE
)
assert_true(
  grepl("width:100.0%", img_style, fixed = TRUE) && nzchar(img_alt),
  "Figure 1 HTML width or alt text is incorrect."
)
assert_true(
  identical(artifact_sha256(html_asset_path), artifact_sha256(overview_png)),
  "The HTML does not embed the current Figure 1 asset."
)

cat(
  paste0(
    "Figure 1 export-scale pilot tests passed.\n",
    "PNG: 4725 x 4500 at the 300-dpi contract.\n",
    "Typography: 12-pt ticks, 14-pt titles/tags, 11-pt captions,",
    " 3.5-unit map labels.\n",
    "Panel tags: A--E all resolve to 14 pt in the assembled grob.\n",
    "Scale: LightLogR symlog threshold 1.\n",
    "HTML: exact asset, non-empty alt, width 100%.\n",
    "Figures 2--5: present and covered by the current full-build manifest.\n"
  )
)
