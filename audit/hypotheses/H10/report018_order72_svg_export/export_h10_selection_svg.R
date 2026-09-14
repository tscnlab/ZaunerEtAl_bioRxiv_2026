#!/usr/bin/env Rscript

# REPORT-018 Order 72, H10 only: reconstruct the accepted manuscript-selection
# display from its frozen rows and display-text contract, then export one native
# vector SVG. This script does not fit, predict from, or recompute any model.

suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
  library(patchwork)
  library(readr)
  library(stringr)
  library(tibble)
})

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop(sprintf("Order 72 requires R 4.6.1; running %s", getRversion()), call. = FALSE)
}

sha256_file <- function(path) {
  digest::digest(file = path, algo = "sha256")
}

assert_pin <- function(relative_path, expected_sha256, expected_bytes = NULL) {
  path <- file.path(root, relative_path)
  if (!file.exists(path)) {
    stop(sprintf("Missing released input: %s", relative_path), call. = FALSE)
  }
  observed_sha256 <- sha256_file(path)
  observed_bytes <- unname(file.info(path)$size)
  if (!identical(observed_sha256, expected_sha256)) {
    stop(
      sprintf(
        "Released input drift: %s expected %s observed %s",
        relative_path,
        expected_sha256,
        observed_sha256
      ),
      call. = FALSE
    )
  }
  if (!is.null(expected_bytes) && !identical(observed_bytes, expected_bytes)) {
    stop(
      sprintf(
        "Released input byte drift: %s expected %s observed %s",
        relative_path,
        expected_bytes,
        observed_bytes
      ),
      call. = FALSE
    )
  }
  tibble(
    path = relative_path,
    expected_sha256 = expected_sha256,
    observed_sha256 = observed_sha256,
    expected_bytes = if (is.null(expected_bytes)) NA_real_ else expected_bytes,
    observed_bytes = observed_bytes,
    status = "PASS"
  )
}

release_manifest_relative <- paste0(
  "audit/report_harmonization/report018_order72_release/",
  "release_manifest.csv"
)
release_manifest_sha256 <-
  "8e25aa779f0115a3a5da9ffcdc3913b81cd6fb06df0c17c9f6d5825356263526"
invisible(assert_pin(release_manifest_relative, release_manifest_sha256))

release_manifest <- readr::read_csv(
  file.path(root, release_manifest_relative),
  show_col_types = FALSE,
  progress = FALSE
)
if (
  !identical(names(release_manifest), c("path", "sha256", "bytes")) ||
    nrow(release_manifest) != 71L ||
    anyDuplicated(release_manifest$path)
) {
  stop("Released Order 72 manifest is not the sealed 71-row schema", call. = FALSE)
}
release_pin_audit <- bind_rows(Map(
  assert_pin,
  release_manifest$path,
  release_manifest$sha256,
  release_manifest$bytes
))
if (!all(release_pin_audit$status == "PASS")) {
  stop("One or more released identities failed", call. = FALSE)
}

explicit_pins <- c(
  "audit/report_harmonization/owner_orders/72_manuscript_svg_exports_released.md" =
    "d14575d7c262b01fe58ba85d343f966d5953601a0fb41cc0f61c25279eb4071c",
  "audit/report_harmonization/owner_orders/72_manuscript_svg_exports_proposed.md" =
    "d3f329a2149149663c47e5db4514cbb7771b0afb6362afc8b911871068d0ebcd",
  "audit/manuscript_nature_health/figure_table_selection_assets/H10_age_site_significant_associations_selection_candidate.png" =
    "e989646f21543203ef07916dde8917e85243667d54b5aa492815476edc6c4b60",
  "artifacts/10_figures/H10/H10_age_site_significant_associations.pdf" =
    "5f5c5cdf91b62dbe3fbb2cd215d6f1658d1835c62eab5504d9aa3570a60de5cf",
  "artifacts/11_source_data/H10/H10_age_site_significant_associations_data.csv" =
    "5f06ab98bada441d02123e56d073e52bfacae75c0277ab73803efd401c33c8fd",
  "audit/hypotheses/H10/manuscript_selection_figure_candidate/candidate_display_text.csv" =
    "e34ffd6de2bf1abb1e50a1474fd8c84611a2cef9ee7a8b9b4e7b971a25bb3ce5",
  "audit/hypotheses/H10/manuscript_selection_figure_candidate/build_h10_selection_figure_candidate.R" =
    "5a2f9cb8fee62a5f19002405db4bb4868a7a1b13ebc950719335dd33458b8c7c"
)
explicit_pin_audit <- bind_rows(Map(assert_pin, names(explicit_pins), explicit_pins))

output_root <- file.path(
  root,
  "audit/hypotheses/H10/report018_order72_svg_export"
)
candidate_path <- file.path(
  output_root,
  "candidate/H10_age_site_significant_associations_selection_candidate.svg"
)
export_contract_path <- file.path(output_root, "export_contract.csv")
package_versions_path <- file.path(output_root, "package_versions.csv")
session_info_path <- file.path(output_root, "session_info.txt")
command_record_path <- file.path(output_root, "export_command.csv")
pre_export_pin_path <- file.path(output_root, "input_pin_audit_pre_export.csv")
new_outputs <- c(
  candidate_path,
  export_contract_path,
  package_versions_path,
  session_info_path,
  command_record_path,
  pre_export_pin_path
)
if (any(file.exists(new_outputs))) {
  stop(
    paste(
      "Refusing to overwrite an Order 72 output:",
      paste(new_outputs[file.exists(new_outputs)], collapse = ", ")
    ),
    call. = FALSE
  )
}
dir.create(dirname(candidate_path), recursive = TRUE, showWarnings = FALSE)

display_spec_relative <- paste0(
  "audit/hypotheses/H10/manuscript_selection_figure_candidate/",
  "candidate_display_text.csv"
)
display_spec_path <- file.path(root, display_spec_relative)
display_spec <- readr::read_csv(
  display_spec_path,
  show_col_types = FALSE,
  progress = FALSE
)
if (
  !identical(names(display_spec), c("key", "text")) ||
    nrow(display_spec) != 22L ||
    anyDuplicated(display_spec$key) ||
    anyNA(display_spec$text)
) {
  stop("Accepted display-text contract is malformed", call. = FALSE)
}
display_text <- stats::setNames(display_spec$text, display_spec$key)
required_text_keys <- c(
  "overall_title", "overall_subtitle", "overall_caption",
  "age_title", "age_subtitle", "age_x", "biological_sex_legend",
  "placement_near_eye", "placement_chest", "main_title",
  "main_subtitle", "main_x", "placement_legend",
  "association_legend", "association_age", "association_sex",
  "panel_near_age", "panel_chest_age", "panel_chest_sex",
  "interaction_title", "interaction_subtitle", "interaction_x"
)
if (!identical(sort(display_spec$key), sort(required_text_keys))) {
  stop("Display-text keys differ from the accepted contract", call. = FALSE)
}
if (any(grepl("\\b(H10|BH)\\b", display_spec$text, perl = TRUE))) {
  stop("Reader-facing display text contains an internal H10 or BH label", call. = FALSE)
}
if (!any(grepl("\\bFDR\\b", display_spec$text, perl = TRUE))) {
  stop("Reader-facing display text does not contain FDR", call. = FALSE)
}

source_relative <- paste0(
  "artifacts/11_source_data/H10/",
  "H10_age_site_significant_associations_data.csv"
)
source_path <- file.path(root, source_relative)
source_data <- readr::read_csv(
  source_path,
  show_col_types = FALSE,
  progress = FALSE
)
required_source_columns <- c(
  "panel", "placement", "placement_label", "site",
  "site_display_order", "site_display_name", "site_color_hex",
  "participant_display_index", "age", "biological_sex", "predictor",
  "association_label", "metric_order", "metric_id", "manuscript_name",
  "standardized_estimate", "standardized_conf_low",
  "standardized_conf_high", "estimate_practical", "conf_low_practical",
  "conf_high_practical", "p_adjusted", "observations", "participants",
  "participant_days", "interaction_p_adjusted"
)
if (!all(required_source_columns %in% names(source_data))) {
  stop("Frozen display source is missing required columns", call. = FALSE)
}
panel_counts <- table(source_data$panel)
expected_panel_counts <- c(
  age_distribution = 295L,
  retained_main_association = 11L,
  retained_site_heterogeneity = 16L
)
if (
  nrow(source_data) != 322L ||
    !identical(
      as.integer(panel_counts[names(expected_panel_counts)]),
      unname(expected_panel_counts)
    )
) {
  stop("Frozen display-source panel counts changed", call. = FALSE)
}
character_content <- unlist(
  source_data[vapply(source_data, is.character, logical(1))],
  use.names = FALSE
)
if (any(grepl("\\b(H10|BH)\\b", character_content, perl = TRUE), na.rm = TRUE)) {
  stop("Frozen plotted labels contain an internal H10 or BH label", call. = FALSE)
}

placement_names <- c(
  glasses = display_text[["placement_near_eye"]],
  chest = display_text[["placement_chest"]]
)
placement_colors <- c(glasses = "#0072B2", chest = "#D55E00")

site_contract <- source_data |>
  filter(.data$panel == "age_distribution") |>
  distinct(
    .data$site,
    .data$site_display_order,
    .data$site_display_name,
    .data$site_color_hex
  ) |>
  arrange(.data$site_display_order)
if (
  nrow(site_contract) != 9L ||
    !identical(as.integer(site_contract$site_display_order), 1:9) ||
    any(site_contract$site_display_order != as.integer(site_contract$site_display_order)) ||
    anyDuplicated(site_contract$site) ||
    anyDuplicated(site_contract$site_display_name) ||
    anyNA(site_contract$site_color_hex)
) {
  stop("Frozen site display order or colour contract changed", call. = FALSE)
}
site_colors <- stats::setNames(site_contract$site_color_hex, site_contract$site)
site_labels <- stats::setNames(site_contract$site_display_name, site_contract$site)

age_plot_data <- source_data |>
  filter(.data$panel == "age_distribution") |>
  mutate(
    placement_label = factor(
      .data$placement_label,
      levels = unname(placement_names[c("glasses", "chest")])
    ),
    site_display_name = factor(
      .data$site_display_name,
      levels = rev(site_contract$site_display_name)
    )
  )
age_counts <- age_plot_data |>
  count(.data$placement, name = "participants") |>
  arrange(match(.data$placement, c("glasses", "chest")))
if (
  !identical(age_counts$placement, c("glasses", "chest")) ||
    !identical(age_counts$participants, c(141L, 154L)) ||
    anyNA(age_plot_data$age) ||
    any(age_plot_data$age < 18 | age_plot_data$age > 68) ||
    !setequal(unique(age_plot_data$biological_sex), c("Female", "Male"))
) {
  stop("Frozen age-distribution contract changed", call. = FALSE)
}

main_plot_data <- source_data |>
  filter(.data$panel == "retained_main_association")
ordered_metric_names <- main_plot_data |>
  arrange(.data$predictor, .data$placement, .data$metric_order) |>
  pull(.data$manuscript_name) |>
  unique()
main_plot_data <- main_plot_data |>
  mutate(
    association_panel = case_when(
      .data$placement == "glasses" & .data$predictor == "age" ~
        display_text[["panel_near_age"]],
      .data$placement == "chest" & .data$predictor == "age" ~
        display_text[["panel_chest_age"]],
      TRUE ~ display_text[["panel_chest_sex"]]
    ),
    association_panel = factor(
      .data$association_panel,
      levels = unname(display_text[c(
        "panel_near_age", "panel_chest_age", "panel_chest_sex"
      )])
    ),
    metric_display = factor(
      .data$manuscript_name,
      levels = rev(ordered_metric_names)
    )
  )
if (
  nrow(main_plot_data) != 11L ||
    sum(main_plot_data$placement == "glasses") != 3L ||
    sum(main_plot_data$placement == "chest" & main_plot_data$predictor == "age") != 6L ||
    sum(main_plot_data$predictor == "biological_sex") != 2L ||
    anyNA(main_plot_data$standardized_estimate) ||
    anyNA(main_plot_data$standardized_conf_low) ||
    anyNA(main_plot_data$standardized_conf_high) ||
    any(main_plot_data$standardized_conf_low > main_plot_data$standardized_estimate) ||
    any(main_plot_data$standardized_estimate > main_plot_data$standardized_conf_high) ||
    any(main_plot_data$p_adjusted > 0.05)
) {
  stop("Frozen retained-main-association contract changed", call. = FALSE)
}

interaction_plot_data <- source_data |>
  filter(.data$panel == "retained_site_heterogeneity") |>
  mutate(
    site_display_name = factor(
      .data$site_display_name,
      levels = rev(site_contract$site_display_name)
    ),
    metric_display = factor(
      .data$manuscript_name,
      levels = c(
        "Midpoint of the brightest 10 hours",
        "Last light timing above 250 lx melEDI"
      )
    )
  )
if (
  nrow(interaction_plot_data) != 16L ||
    !all(interaction_plot_data$placement == "chest") ||
    !all(interaction_plot_data$predictor == "age") ||
    n_distinct(interaction_plot_data$metric_id) != 2L ||
    !all(count(interaction_plot_data, .data$metric_id)$n == 8L) ||
    anyNA(interaction_plot_data$estimate_practical) ||
    anyNA(interaction_plot_data$conf_low_practical) ||
    anyNA(interaction_plot_data$conf_high_practical) ||
    any(interaction_plot_data$conf_low_practical > interaction_plot_data$estimate_practical) ||
    any(interaction_plot_data$estimate_practical > interaction_plot_data$conf_high_practical) ||
    any(interaction_plot_data$interaction_p_adjusted > 0.05)
) {
  stop("Frozen retained-interaction contract changed", call. = FALSE)
}

theme_selection_overview <- function(base_size = 10) {
  theme_minimal(base_size = base_size) +
    theme(
      plot.title.position = "plot",
      plot.title = element_text(face = "bold", size = rel(1.15)),
      plot.subtitle = element_text(size = rel(0.96), color = "grey25"),
      plot.caption = element_text(size = rel(0.72), hjust = 0, color = "grey25"),
      panel.grid.minor = element_blank(),
      panel.grid.major.y = element_blank(),
      strip.text = element_text(face = "bold", size = rel(0.9)),
      axis.title = element_text(size = rel(0.92)),
      axis.text = element_text(size = rel(0.82)),
      legend.position = "bottom",
      legend.title = element_text(size = rel(0.85)),
      legend.text = element_text(size = rel(0.82)),
      plot.margin = margin(5.5, 8, 5.5, 8)
    )
}

p_age <- ggplot(
  age_plot_data,
  aes(x = .data$age, y = .data$site_display_name)
) +
  geom_boxplot(
    aes(color = .data$site),
    width = 0.56,
    outlier.shape = NA,
    linewidth = 0.65,
    show.legend = FALSE
  ) +
  geom_jitter(
    aes(color = .data$site, shape = .data$biological_sex),
    position = position_jitter(width = 0, height = 0.12, seed = 1010),
    alpha = 0.68,
    size = 1.25,
    stroke = 0,
    show.legend = c(color = FALSE, shape = TRUE)
  ) +
  facet_wrap(~placement_label, ncol = 2) +
  scale_color_manual(
    values = site_colors,
    breaks = site_contract$site,
    labels = site_labels,
    drop = FALSE
  ) +
  scale_shape_manual(
    values = c(Female = 16, Male = 17),
    name = display_text[["biological_sex_legend"]]
  ) +
  scale_x_continuous(
    breaks = seq(20, 70, 10),
    limits = c(17, 70),
    expand = expansion(mult = c(0.01, 0.01))
  ) +
  labs(
    title = display_text[["age_title"]],
    subtitle = display_text[["age_subtitle"]],
    x = display_text[["age_x"]],
    y = NULL
  ) +
  theme_selection_overview(10)

p_main <- ggplot(
  main_plot_data,
  aes(
    x = .data$standardized_estimate,
    y = .data$metric_display,
    xmin = .data$standardized_conf_low,
    xmax = .data$standardized_conf_high,
    color = .data$placement,
    shape = .data$predictor
  )
) +
  geom_vline(xintercept = 0, color = "grey50", linewidth = 0.45) +
  geom_errorbar(orientation = "y", width = 0, linewidth = 0.7) +
  geom_point(size = 2.35, stroke = 0.25) +
  facet_wrap(~association_panel, ncol = 3, scales = "free") +
  scale_color_manual(
    values = placement_colors,
    breaks = c("glasses", "chest"),
    labels = placement_names,
    name = display_text[["placement_legend"]]
  ) +
  scale_shape_manual(
    values = c(age = 16, biological_sex = 17),
    breaks = c("age", "biological_sex"),
    labels = unname(display_text[c("association_age", "association_sex")]),
    name = display_text[["association_legend"]]
  ) +
  scale_y_discrete(labels = function(x) stringr::str_wrap(x, width = 24)) +
  scale_x_continuous(
    breaks = function(x) {
      candidates <- pretty(x, n = 3)
      sort(unique(c(
        0,
        candidates[candidates >= x[[1]] & candidates <= x[[2]]]
      )))
    },
    expand = expansion(mult = c(0.08, 0.08))
  ) +
  labs(
    title = display_text[["main_title"]],
    subtitle = display_text[["main_subtitle"]],
    x = display_text[["main_x"]],
    y = NULL
  ) +
  theme_selection_overview(10) +
  theme(
    legend.position = "none",
    panel.spacing.x = grid::unit(12, "pt")
  )

p_interaction <- ggplot(
  interaction_plot_data,
  aes(
    x = .data$estimate_practical,
    y = .data$site_display_name,
    xmin = .data$conf_low_practical,
    xmax = .data$conf_high_practical,
    color = .data$site
  )
) +
  geom_vline(xintercept = 0, color = "grey50", linewidth = 0.45) +
  geom_errorbar(orientation = "y", width = 0, linewidth = 0.7) +
  geom_point(size = 2.2) +
  facet_wrap(~metric_display, ncol = 2) +
  scale_color_manual(
    values = site_colors,
    breaks = site_contract$site,
    labels = site_labels,
    drop = FALSE
  ) +
  labs(
    title = display_text[["interaction_title"]],
    subtitle = display_text[["interaction_subtitle"]],
    x = display_text[["interaction_x"]],
    y = NULL
  ) +
  theme_selection_overview(10) +
  theme(legend.position = "none")

overview <- p_age /
  p_main /
  p_interaction +
  plot_layout(heights = c(1.0, 1.2, 1.15)) +
  plot_annotation(
    title = display_text[["overall_title"]],
    subtitle = display_text[["overall_subtitle"]],
    caption = display_text[["overall_caption"]],
    tag_levels = "A",
    theme = theme(
      plot.title = element_text(face = "bold", size = 15),
      plot.subtitle = element_text(size = 11, color = "grey25"),
      plot.caption = element_text(size = 7, hjust = 0, color = "grey25"),
      plot.tag.position = "topleft",
      plot.tag = element_text(face = "bold", size = 15)
    )
  )

candidate_tmp <- tempfile(
  pattern = "H10-order72-selection-",
  tmpdir = tempdir(),
  fileext = ".svg"
)
on.exit(unlink(candidate_tmp[file.exists(candidate_tmp)]), add = TRUE)
svglite::svglite(
  candidate_tmp,
  width = 9.4,
  height = 13,
  bg = "white",
  pointsize = 12,
  standalone = TRUE,
  web_fonts = list(),
  fix_text_size = TRUE,
  always_valid = FALSE
)
print(overview)
grDevices::dev.off()
if (!file.exists(candidate_tmp) || file.info(candidate_tmp)$size <= 0) {
  stop("Native SVG export is absent or empty", call. = FALSE)
}

svg_doc <- xml2::read_xml(candidate_tmp)
svg_root <- xml2::xml_root(svg_doc)
svg_width <- xml2::xml_attr(svg_root, "width")
svg_height <- xml2::xml_attr(svg_root, "height")
svg_viewbox <- xml2::xml_attr(svg_root, "viewBox")
if (
  !identical(svg_width, "676.80pt") ||
    !identical(svg_height, "936.00pt") ||
    !identical(svg_viewbox, "0 0 676.80 936.00")
) {
  stop("Native SVG geometry differs from the accepted 9.4 by 13 inch canvas", call. = FALSE)
}

script_relative <- paste0(
  "audit/hypotheses/H10/report018_order72_svg_export/",
  "export_h10_selection_svg.R"
)
script_path <- file.path(root, script_relative)
font_match <- systemfonts::match_fonts("Arial")
if (nrow(font_match) != 1L || !file.exists(font_match$path[[1]])) {
  stop("Arial did not resolve to an installed system font", call. = FALSE)
}
package_names <- c(
  "digest", "dplyr", "ggplot2", "patchwork", "readr", "stringr",
  "svglite", "systemfonts", "tibble", "xml2"
)
package_versions <- tibble(
  package = package_names,
  version = vapply(package_names, function(x) as.character(packageVersion(x)), character(1))
)
export_contract <- tribble(
  ~contract_item, ~value,
  "status", "PASS",
  "r_version", as.character(getRversion()),
  "library_paths", paste(.libPaths(), collapse = " | "),
  "release_manifest_path", release_manifest_relative,
  "release_manifest_sha256", sha256_file(file.path(root, release_manifest_relative)),
  "release_manifest_rows_verified", as.character(nrow(release_pin_audit)),
  "frozen_source_path", source_relative,
  "frozen_source_sha256", sha256_file(source_path),
  "frozen_source_rows", as.character(nrow(source_data)),
  "age_distribution_rows", as.character(nrow(age_plot_data)),
  "retained_main_rows", as.character(nrow(main_plot_data)),
  "retained_interaction_rows", as.character(nrow(interaction_plot_data)),
  "display_text_path", display_spec_relative,
  "display_text_sha256", sha256_file(display_spec_path),
  "builder_reference_sha256", explicit_pins[[length(explicit_pins)]],
  "export_script_path", script_relative,
  "export_script_sha256", sha256_file(script_path),
  "panel_tags", "uppercase A, B, C",
  "panel_tag_face", "bold",
  "canvas_width_in", "9.4",
  "canvas_height_in", "13",
  "accepted_raster_width_px", "2820",
  "accepted_raster_height_px", "3900",
  "intended_display_width_mm", "170",
  "svg_width", svg_width,
  "svg_height", svg_height,
  "svg_viewBox", svg_viewbox,
  "svg_sha256", sha256_file(candidate_tmp),
  "svg_bytes", as.character(file.info(candidate_tmp)$size),
  "resolved_svg_font_family", "Arial",
  "resolved_svg_font_path", font_match$path[[1]],
  "resolved_svg_font_sha256", sha256_file(font_match$path[[1]])
)
command_record <- tibble(
  sequence = 1L,
  purpose = "single native-vector H10 selection candidate export",
  command = paste(
    "RENV_CONFIG_AUTOLOADER_ENABLED=FALSE Rscript --vanilla",
    script_relative
  ),
  status = "PASS"
)

readr::write_csv(
  bind_rows(
    mutate(explicit_pin_audit, pin_set = "explicit H10/order pin"),
    mutate(release_pin_audit, pin_set = "71-row release manifest")
  ) |>
    select(.data$pin_set, everything()),
  pre_export_pin_path,
  na = ""
)
readr::write_csv(package_versions, package_versions_path, na = "")
readr::write_csv(export_contract, export_contract_path, na = "")
readr::write_csv(command_record, command_record_path, na = "")
writeLines(capture.output(sessionInfo()), session_info_path, useBytes = TRUE)
if (!file.rename(candidate_tmp, candidate_path)) {
  stop("Could not seal the native SVG candidate", call. = FALSE)
}
if (!identical(sha256_file(candidate_path), export_contract$value[export_contract$contract_item == "svg_sha256"])) {
  stop("Candidate SVG identity changed during sealing", call. = FALSE)
}

message(
  "REPORT018_ORDER72_H10_EXPORT_PASS ",
  sha256_file(candidate_path),
  " ",
  file.info(candidate_path)$size,
  " bytes"
)
