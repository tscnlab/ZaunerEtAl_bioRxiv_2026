#!/usr/bin/env Rscript

# Candidate-only native SVG export for REPORT-018 Order 72.
# This script reads the two frozen H06 display CSVs and the site display
# registry. It does not read a fitted model or calculate a scientific result.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("Order 72 requires R 4.6.1", call. = FALSE)
}

required_packages <- c(
  "cowplot", "digest", "dplyr", "ggplot2", "readr", "scales",
  "svglite", "systemfonts"
)
missing_packages <- required_packages[!vapply(
  required_packages,
  requireNamespace,
  logical(1),
  quietly = TRUE
)]
if (length(missing_packages) > 0L) {
  stop(
    "Missing accepted library package(s): ",
    paste(missing_packages, collapse = ", "),
    call. = FALSE
  )
}

sha256 <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
}

relative <- function(...) file.path(root, ...)

release_paths <- c(
  order = "audit/report_harmonization/owner_orders/72_manuscript_svg_exports_released.md",
  specification = "audit/report_harmonization/owner_orders/72_manuscript_svg_exports_proposed.md",
  release_manifest = "audit/report_harmonization/report018_order72_release/release_manifest.csv"
)
release_expected <- c(
  order = "d14575d7c262b01fe58ba85d343f966d5953601a0fb41cc0f61c25279eb4071c",
  specification = "d3f329a2149149663c47e5db4514cbb7771b0afb6362afc8b911871068d0ebcd",
  release_manifest = "8e25aa779f0115a3a5da9ffcdc3913b81cd6fb06df0c17c9f6d5825356263526"
)
release_actual <- vapply(relative(release_paths), sha256, character(1))
if (!identical(unname(release_actual), unname(release_expected))) {
  stop("Order 72 release identity changed", call. = FALSE)
}

release_manifest <- readr::read_csv(
  relative(release_paths[["release_manifest"]]),
  show_col_types = FALSE
)
if (nrow(release_manifest) != 71L || anyDuplicated(release_manifest$path)) {
  stop("Order 72 release manifest is not the sealed 71-row inventory", call. = FALSE)
}
manifest_actual_sha256 <- vapply(
  relative(release_manifest$path),
  sha256,
  character(1)
)
manifest_actual_bytes <- unname(file.info(relative(release_manifest$path))$size)
if (
  any(manifest_actual_sha256 != release_manifest$sha256) ||
    any(manifest_actual_bytes != release_manifest$bytes)
) {
  stop("An Order 72 release-manifest input changed", call. = FALSE)
}

h06_pins <- data.frame(
  role = c(
    "S9 accepted PNG", "S9 accepted PDF", "S9 frozen plotting source",
    "S9 builder reference", "S12 accepted PNG", "S12 accepted PDF",
    "S12 frozen plotting source", "S12 builder reference",
    "S12 site display registry"
  ),
  path = c(
    "artifacts/10_figures/H06/H06_paired_placement_effects.png",
    "artifacts/10_figures/H06/H06_paired_placement_effects.pdf",
    "artifacts/11_source_data/H06/H06_paired_placement_effects_figure.csv",
    "scripts/hypotheses/H06/build_h06_stage2_reader_artifacts.R",
    "artifacts/10_figures/H06/H06_stage3_site_specific_significance_screen.png",
    "artifacts/10_figures/H06/H06_stage3_site_specific_significance_screen.pdf",
    "artifacts/11_source_data/H06/H06_stage3_site_specific_significance_screen_figure.csv",
    "scripts/hypotheses/H06/build_h06_stage3_site_specific_screening.R",
    "config/site_display_registry.csv"
  ),
  expected_sha256 = c(
    "e0a63c615a5422d28e1af7d2cc15ca29e65057b7639308c5cbdcb028e25f9478",
    "035f8a32d2356d33280d6f8945bbef7b4e5ba24d6c0fbd4fe251296eac0c7fa7",
    "b50dc0a8db8396666fb1ea8cf18cfbf01bb3bb022973755de0edcf835168fba2",
    "3588b7440c4d5b0f7614034762c40cb62cb7e0fe36c32ff896dd1237df4c3291",
    "88aeef89cda1208a80ead843ca9551011350ed5f78734c57ceee380bf994f02e",
    "fc5d39926af682d629bca21966dd68dbc9bda89e51a511003004d033d6185694",
    "8d15804a66a6589b6c6f408db147e65c0fa2a42f71cd32fb1dcd2acd6657d642",
    "e92aedc03a2f5e75e9c6ce884498ebb69fa8ea79af4ce122325fc2dd26ebd7cd",
    "3d669d459ecc27d3154bbb5ff5b0d64cb510805d486b45264443228c44a6d809"
  ),
  stringsAsFactors = FALSE
)
h06_pins$actual_sha256 <- vapply(relative(h06_pins$path), sha256, character(1))
h06_pins$bytes <- unname(file.info(relative(h06_pins$path))$size)
h06_pins$match <- h06_pins$actual_sha256 == h06_pins$expected_sha256
if (!all(h06_pins$match)) {
  stop(
    "An H06 Order 72 input changed: ",
    paste(h06_pins$role[!h06_pins$match], collapse = ", "),
    call. = FALSE
  )
}

output_root <- relative(
  "audit/hypotheses/H06/report018_order72_svg_export"
)
candidate_root <- file.path(output_root, "candidate")
qa_root <- file.path(output_root, "qa")
if (!dir.exists(candidate_root) || !dir.exists(qa_root)) {
  stop("The sealed H06 candidate directories are unavailable", call. = FALSE)
}
if (length(list.files(candidate_root, all.files = TRUE, no.. = TRUE)) > 0L) {
  stop("The H06 Order 72 candidate directory is not empty", call. = FALSE)
}

s9_source <- relative(
  "artifacts/11_source_data/H06/H06_paired_placement_effects_figure.csv"
)
s12_source <- relative(
  paste0(
    "artifacts/11_source_data/H06/",
    "H06_stage3_site_specific_significance_screen_figure.csv"
  )
)
site_registry_path <- relative("config/site_display_registry.csv")

s9 <- readr::read_csv(s9_source, show_col_types = FALSE, na = "")
s12 <- readr::read_csv(s12_source, show_col_types = FALSE, na = "")
site_registry <- readr::read_csv(
  site_registry_path,
  show_col_types = FALSE,
  na = ""
) |>
  dplyr::arrange(.data$display_order)

required_s9 <- c(
  "run_id", "placement", "predictor_id", "effect", "ratio",
  "conf_low", "conf_high"
)
required_s12 <- c(
  "site", "display_name", "display_order", "color_hex",
  "predictor_label", "estimate_ratio", "conf_low_ratio",
  "conf_high_ratio", "adjusted_significant_0_05",
  "interaction_equal_site_ratio"
)
if (
  nrow(s9) != 6L || !all(required_s9 %in% names(s9)) ||
    nrow(s12) != 27L || !all(required_s12 %in% names(s12))
) {
  stop("A frozen H06 plotting source has the wrong display schema", call. = FALSE)
}

frozen_site_registry <- s12 |>
  dplyr::distinct(
    .data$site,
    .data$display_order,
    .data$display_name,
    .data$color_hex
  ) |>
  dplyr::arrange(.data$display_order)
if (!identical(as.data.frame(frozen_site_registry), as.data.frame(site_registry))) {
  stop("The S12 frozen display rows disagree with the site registry", call. = FALSE)
}

theme_h06 <- function(base_size = 8.5) {
  ggplot2::theme_minimal(base_size = base_size) +
    ggplot2::theme(
      axis.text = ggplot2::element_text(size = 8),
      axis.title = ggplot2::element_text(size = 8.5),
      legend.text = ggplot2::element_text(size = 8),
      legend.title = ggplot2::element_text(size = 8.5),
      panel.grid.minor = ggplot2::element_blank(),
      legend.position = "bottom",
      strip.text = ggplot2::element_text(size = 8.5, face = "bold"),
      plot.title.position = "plot"
    )
}

s9$effect <- factor(
  s9$effect,
  levels = rev(c(
    "Free versus work day",
    "Active versus sedentary",
    "Previous sleep (per h)"
  ))
)
if (anyNA(s9$effect)) {
  stop("The S9 accepted effect labels changed", call. = FALSE)
}

s9_plot <- ggplot2::ggplot(
  s9,
  ggplot2::aes(
    x = .data$ratio,
    y = .data$effect,
    xmin = .data$conf_low,
    xmax = .data$conf_high,
    colour = .data$placement,
    shape = .data$placement
  )
) +
  ggplot2::geom_vline(xintercept = 1, colour = "grey55", linewidth = 0.45) +
  ggplot2::geom_errorbar(
    orientation = "y",
    position = ggplot2::position_dodge(width = 0.45),
    width = 0.18,
    linewidth = 0.55
  ) +
  ggplot2::geom_point(
    position = ggplot2::position_dodge(width = 0.45),
    size = 2.4
  ) +
  ggplot2::scale_x_log10(
    breaks = c(0.75, 1, 1.5, 2, 3),
    labels = scales::label_number(accuracy = 0.01)
  ) +
  ggplot2::scale_colour_manual(
    values = c("Near-eye" = "#0072B2", "Chest" = "#D55E00")
  ) +
  ggplot2::labs(
    x = "Expected-hour ratio (95% CI; log scale)",
    y = NULL,
    colour = "Placement",
    shape = "Placement"
  ) +
  theme_h06()

effect_order <- c(
  "Free day versus work day",
  "Active versus sedentary",
  "Previous sleep duration (per hour)"
)
s12 <- s12 |>
  dplyr::mutate(
    predictor_label = factor(
      .data$predictor_label,
      levels = .env$effect_order
    ),
    predictor_display = factor(
      dplyr::recode(
        as.character(.data$predictor_label),
        `Free day versus work day` = "Free day versus\nwork day",
        `Active versus sedentary` = "Active versus\nsedentary",
        `Previous sleep duration (per hour)` =
          "Previous sleep\n(per additional hour)"
      ),
      levels = c(
        "Free day versus\nwork day",
        "Active versus\nsedentary",
        "Previous sleep\n(per additional hour)"
      )
    ),
    display_name = factor(
      .data$display_name,
      levels = rev(.env$site_registry$display_name)
    )
  )
if (anyNA(s12$predictor_display) || anyNA(s12$display_name)) {
  stop("The S12 accepted display factors changed", call. = FALSE)
}
if (
  any(!is.finite(s12$interaction_equal_site_ratio)) ||
    any(s12$interaction_equal_site_ratio <= 0)
) {
  stop("The S12 frozen display references are invalid", call. = FALSE)
}

interaction_references <- s12 |>
  dplyr::distinct(
    .data$predictor_display,
    .data$interaction_equal_site_ratio
  )

s12_plot <- ggplot2::ggplot(
  s12,
  ggplot2::aes(
    x = .data$estimate_ratio,
    y = .data$display_name,
    xmin = .data$conf_low_ratio,
    xmax = .data$conf_high_ratio,
    colour = .data$site
  )
) +
  ggplot2::geom_vline(
    xintercept = 1,
    colour = "grey70",
    linewidth = 0.45
  ) +
  ggplot2::geom_vline(
    data = interaction_references,
    ggplot2::aes(xintercept = .data$interaction_equal_site_ratio),
    inherit.aes = FALSE,
    colour = "grey30",
    linetype = "dashed",
    linewidth = 0.65
  ) +
  ggplot2::geom_errorbar(
    orientation = "y",
    width = 0,
    linewidth = 0.6
  ) +
  ggplot2::geom_point(
    data = dplyr::filter(s12, !.data$adjusted_significant_0_05),
    shape = 21,
    fill = "white",
    size = 3,
    stroke = 0.8
  ) +
  ggplot2::geom_point(
    data = dplyr::filter(s12, .data$adjusted_significant_0_05),
    ggplot2::aes(fill = .data$site),
    shape = 21,
    size = 3.4,
    stroke = 0.7
  ) +
  ggplot2::facet_wrap(~predictor_display, ncol = 3) +
  ggplot2::scale_x_log10(
    breaks = c(0.25, 0.5, 1, 2, 4, 8),
    labels = scales::label_number(accuracy = 0.01)
  ) +
  ggplot2::scale_colour_manual(
    values = stats::setNames(site_registry$color_hex, site_registry$site),
    guide = "none"
  ) +
  ggplot2::scale_fill_manual(
    values = stats::setNames(site_registry$color_hex, site_registry$site),
    guide = "none"
  ) +
  ggplot2::labs(
    title = "Site-specific mean hourly near-eye melEDI ratios",
    subtitle = paste(
      "Dashed: site-average estimate from this model; filled: retained",
      "after nine-site FDR adjustments; open:",
      "not retained"
    ),
    x = "Site-specific ratio (log scale)",
    y = NULL,
    caption = paste0(
      "Bars are participant-cluster HC3 pointwise 95% confidence intervals from the current\n",
      "predictor-by-site interaction model. The grey line at 1 is the site-specific association null.\n",
      "The dashed line is the site-average geometric mean of the nine ratios in this same model.\n",
      "Filled points pass a separate nine-site FDR adjustment within that predictor; this does\n",
      "not test deviation from the site-average estimate or the overall predictor-by-site interaction."
    )
  ) +
  cowplot::theme_cowplot(font_size = 10.5) +
  ggplot2::theme(
    axis.text = ggplot2::element_text(size = 8, colour = "black"),
    axis.title = ggplot2::element_text(size = 9),
    strip.background = ggplot2::element_rect(fill = "#D9D9D9", colour = NA),
    strip.text = ggplot2::element_text(size = 9, face = "bold"),
    plot.title = ggplot2::element_text(size = 10.5, face = "bold"),
    plot.subtitle = ggplot2::element_text(size = 8.5),
    plot.caption = ggplot2::element_text(
      size = 7.5,
      hjust = 0,
      lineheight = 1.03,
      margin = ggplot2::margin(t = 8, b = 4)
    ),
    panel.grid.major.y = ggplot2::element_line(
      colour = "#E3E6E8",
      linewidth = 0.35
    ),
    panel.grid.major.x = ggplot2::element_blank(),
    panel.grid.minor = ggplot2::element_blank(),
    panel.spacing = grid::unit(1.1, "lines"),
    plot.title.position = "plot",
    plot.caption.position = "plot",
    plot.margin = ggplot2::margin(t = 7, r = 8, b = 10, l = 7)
  )

svg_specs <- data.frame(
  figure = c(
    "H06_paired_placement_effects",
    "H06_stage3_site_specific_significance_screen"
  ),
  width_mm = c(170, 170),
  height_mm = c(120, 135),
  stringsAsFactors = FALSE
)
plots <- list(s9_plot, s12_plot)

for (index in seq_len(nrow(svg_specs))) {
  ggplot2::ggsave(
    filename = file.path(
      candidate_root,
      paste0(svg_specs$figure[[index]], ".svg")
    ),
    plot = plots[[index]],
    width = svg_specs$width_mm[[index]] / 25.4,
    height = svg_specs$height_mm[[index]] / 25.4,
    units = "in",
    device = svglite::svglite,
    bg = "white"
  )
}

svg_paths <- file.path(candidate_root, paste0(svg_specs$figure, ".svg"))
svg_text <- lapply(svg_paths, function(path) {
  paste(readLines(path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
})

forbidden_patterns <- c(
  "<image", "<script", "<foreignObject", "data:image", "xlink:href=",
  " href=", "@import", "javascript:", "file://", "run_id",
  "predictor_id", "accepted_input_sha256", "exact_common_hour_keys",
  "model_archive"
)
expected_tokens <- list(
  c(
    "Free versus work day", "Active versus sedentary",
    "Previous sleep (per h)", "Expected-hour ratio (95% CI; log scale)",
    "Placement", "Chest", "Near-eye"
  ),
  c(
    "Site-specific mean hourly near-eye melEDI ratios",
    "Free day versus", "work day", "Active versus", "sedentary",
    "Previous sleep", "(per additional hour)", "Borås (SE)",
    "Kumasi (GH)", "Site-specific ratio (log scale)",
    "participant-cluster HC3 pointwise 95% confidence intervals"
  )
)
svg_checks <- lapply(seq_along(svg_paths), function(index) {
  text <- svg_text[[index]]
  vector_elements <- sum(vapply(
    c("<line", "<polyline", "<polygon", "<path", "<rect", "<circle", "<text"),
    grepl,
    logical(1),
    x = text,
    fixed = TRUE
  ))
  data.frame(
    figure = svg_specs$figure[[index]],
    svg_sha256 = sha256(svg_paths[[index]]),
    bytes = unname(file.info(svg_paths[[index]])$size),
    width_mm = svg_specs$width_mm[[index]],
    height_mm = svg_specs$height_mm[[index]],
    viewbox = sub(
      ".*viewBox='([^']+)'.*",
      "\\1",
      regmatches(text, regexpr("viewBox='[^']+'", text))
    ),
    native_vector = grepl("<svg", text, fixed = TRUE) && vector_elements >= 3L,
    no_embedded_raster = !grepl("<image", text, fixed = TRUE) &&
      !grepl("data:image", text, fixed = TRUE),
    no_script = !grepl("<script", text, fixed = TRUE) &&
      !grepl("javascript:", text, fixed = TRUE),
    no_external_or_hidden_payload = !any(vapply(
      forbidden_patterns,
      grepl,
      logical(1),
      x = text,
      fixed = TRUE
    )),
    no_participant_identifier = !grepl(
      "[A-Z]{2,}[_-]S[0-9]{3}",
      text,
      perl = TRUE
    ),
    visible_tokens_complete = all(vapply(
      expected_tokens[[index]],
      grepl,
      logical(1),
      x = text,
      fixed = TRUE
    )),
    stringsAsFactors = FALSE
  )
}) |>
  dplyr::bind_rows()

check_columns <- c(
  "native_vector", "no_embedded_raster", "no_script",
  "no_external_or_hidden_payload", "no_participant_identifier",
  "visible_tokens_complete"
)
if (!all(unlist(svg_checks[check_columns], use.names = FALSE))) {
  stop("An H06 candidate SVG failed a native-vector or privacy check", call. = FALSE)
}

arial <- systemfonts::match_fonts("Arial")
if (nrow(arial) != 1L || !file.exists(arial$path[[1L]])) {
  stop("Arial did not resolve for the native SVG device", call. = FALSE)
}

readr::write_csv(h06_pins, file.path(output_root, "input_pin_checks.csv"))
readr::write_csv(svg_checks, file.path(output_root, "svg_structure_checks.csv"))
readr::write_csv(
  data.frame(
    library_path = .libPaths(),
    stringsAsFactors = FALSE
  ),
  file.path(output_root, "library_paths.csv")
)
readr::write_csv(
  data.frame(
    package = required_packages,
    version = vapply(
      required_packages,
      function(package) as.character(utils::packageVersion(package)),
      character(1)
    ),
    stringsAsFactors = FALSE
  ),
  file.path(output_root, "package_versions.csv")
)
readr::write_csv(
  data.frame(
    requested_family = "Arial",
    resolved_path = arial$path[[1L]],
    resolved_index = arial$index[[1L]],
    stringsAsFactors = FALSE
  ),
  file.path(output_root, "font_resolution.csv")
)

session_lines <- capture.output(utils::sessionInfo())
writeLines(session_lines, file.path(output_root, "session_info.txt"), useBytes = TRUE)

cat(
  "REPORT018_ORDER72_H06_EXPORT=PASS\n",
  paste0(svg_checks$figure, " ", svg_checks$svg_sha256, "\n"),
  sep = ""
)
