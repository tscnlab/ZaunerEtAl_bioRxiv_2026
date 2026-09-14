#!/usr/bin/env Rscript

# Build one manuscript-selection candidate from the frozen H10 display rows.
# This script does not fit, predict from, or otherwise recompute a model. It
# writes no canonical H10 or manuscript-selection source, table, or render.

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
  stop(
    sprintf("Selection candidate requires R 4.6.1; running %s", getRversion()),
    call. = FALSE
  )
}

sha256_file <- function(path) {
  digest::digest(file = path, algo = "sha256")
}

assert_pin <- function(relative_path, expected_sha256) {
  path <- file.path(root, relative_path)
  if (!file.exists(path)) {
    stop(sprintf("Missing released input: %s", relative_path), call. = FALSE)
  }
  observed <- sha256_file(path)
  if (!identical(observed, expected_sha256)) {
    stop(
      sprintf(
        "Released input drift: %s expected %s observed %s",
        relative_path,
        expected_sha256,
        observed
      ),
      call. = FALSE
    )
  }
  invisible(path)
}

released_pins <- c(
  "notebooks/hypotheses/H10.qmd" =
    "0cf302f74c482168c5f5d4c640bbc6a80ef451333f7d76f3c3be204ac1b5f64d",
  "_build/nathealth/notebooks/hypotheses/H10.html" =
    "c0f4cbc78b899b41cad904e723891c9ac499bf4485233cf7aefff2ebaa059409",
  "artifacts/10_figures/H10/H10_age_site_significant_associations.png" =
    "f63973b770ecaca01a3fb2b24fa455b14f7a5208c82df377317578a443d411a6",
  "artifacts/10_figures/H10/H10_age_site_significant_associations.pdf" =
    "5f5c5cdf91b62dbe3fbb2cd215d6f1658d1835c62eab5504d9aa3570a60de5cf",
  "artifacts/11_source_data/H10/H10_age_site_significant_associations_data.csv" =
    "5f06ab98bada441d02123e56d073e52bfacae75c0277ab73803efd401c33c8fd",
  "artifacts/12_manifests/H10/H10_stage3_reader_figure_manifest.csv" =
    "4d270e49c99f980e431fbb7e12d51c017edfe86b793a63458c574e0f0564f7a0",
  "artifacts/12_manifests/H10/H10_stage3_artifacts.csv" =
    "b556d9fdb19eeda766414bab30420846ee5c46138e9d7861f61e92da7516683e",
  "audit/manuscript_nature_health/manuscript_figure_table_selection.qmd" =
    "f430fe5bcbb6e40420a80797e8858d6b5ce42a7a046ad2da73877ae925c7acf3",
  "audit/manuscript_nature_health/manuscript_figure_table_selection.html" =
    "e149e394e0a23da2063c4db2871c54a123ba75958c9282bb1fa7d171512a68a9",
  "audit/manuscript_nature_health/figure_table_selection_assets/tbl-h10-main-results.html" =
    "b511c4fcc0a95c7e58d940816dd38fe63f9c6dffde782e6f736e285ba8e31193"
)
invisible(mapply(assert_pin, names(released_pins), released_pins))

evidence_dir <- file.path(
  root,
  "audit/hypotheses/H10/manuscript_selection_figure_candidate"
)
display_spec_path <- file.path(evidence_dir, "candidate_display_text.csv")
candidate_path <- file.path(
  root,
  paste0(
    "audit/manuscript_nature_health/figure_table_selection_assets/",
    "H10_age_site_significant_associations_selection_candidate.png"
  )
)
build_contract_path <- file.path(evidence_dir, "candidate_build_contract.csv")
proof_path <- file.path(evidence_dir, "candidate_170mm_A4_proof.png")
session_path <- file.path(evidence_dir, "candidate_build_session_info.txt")

new_outputs <- c(
  candidate_path,
  build_contract_path,
  proof_path,
  session_path
)
if (any(file.exists(new_outputs))) {
  stop(
    paste(
      "Refusing to overwrite an existing candidate output:",
      paste(new_outputs[file.exists(new_outputs)], collapse = ", ")
    ),
    call. = FALSE
  )
}

display_spec <- readr::read_csv(
  display_spec_path,
  show_col_types = FALSE,
  progress = FALSE
)
if (
  !identical(names(display_spec), c("key", "text")) ||
    anyDuplicated(display_spec$key) ||
    anyNA(display_spec$text)
) {
  stop("Candidate display-text contract is malformed", call. = FALSE)
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
  stop("Candidate display-text keys differ from the declared contract", call. = FALSE)
}
if (any(grepl("\\b(H10|BH)\\b", display_spec$text, perl = TRUE))) {
  stop("Reader-facing candidate text contains an internal H10 or BH label", call. = FALSE)
}
if (!any(grepl("\\bFDR\\b", display_spec$text, perl = TRUE))) {
  stop("Reader-facing candidate text does not contain FDR", call. = FALSE)
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
  pattern = "H10-selection-candidate-",
  tmpdir = dirname(candidate_path),
  fileext = ".png"
)
proof_tmp <- tempfile(
  pattern = "H10-selection-proof-",
  tmpdir = evidence_dir,
  fileext = ".png"
)
contract_tmp <- tempfile(
  pattern = "H10-selection-contract-",
  tmpdir = evidence_dir,
  fileext = ".csv"
)
session_tmp <- tempfile(
  pattern = "H10-selection-session-",
  tmpdir = evidence_dir,
  fileext = ".txt"
)
temporary_outputs <- c(candidate_tmp, proof_tmp, contract_tmp, session_tmp)
on.exit(unlink(temporary_outputs[file.exists(temporary_outputs)]), add = TRUE)

ragg::agg_png(
  candidate_tmp,
  width = 9.4,
  height = 13,
  units = "in",
  res = 300,
  background = "white"
)
print(overview)
grDevices::dev.off()

candidate_raster <- png::readPNG(candidate_tmp)
if (!identical(dim(candidate_raster)[1:2], c(3900L, 2820L))) {
  stop("Candidate raster dimensions differ from the released geometry", call. = FALSE)
}

ragg::agg_png(
  proof_tmp,
  width = 210,
  height = 297,
  units = "mm",
  res = 300,
  background = "white"
)
grid::grid.newpage()
grid::grid.raster(
  candidate_raster,
  width = grid::unit(170, "mm"),
  height = grid::unit(170 * 13 / 9.4, "mm"),
  interpolate = TRUE
)
grDevices::dev.off()

hash_object <- function(x) {
  digest::digest(x, algo = "sha256", serialize = TRUE)
}
candidate_sha256 <- sha256_file(candidate_tmp)
proof_sha256 <- sha256_file(proof_tmp)
build_contract <- tibble::tribble(
  ~contract_item, ~value,
  "r_version", as.character(getRversion()),
  "frozen_source_path", source_relative,
  "frozen_source_sha256", sha256_file(source_path),
  "frozen_source_rows", as.character(nrow(source_data)),
  "age_distribution_rows", as.character(nrow(age_plot_data)),
  "retained_main_rows", as.character(nrow(main_plot_data)),
  "retained_interaction_rows", as.character(nrow(interaction_plot_data)),
  "retained_interaction_metrics", as.character(n_distinct(interaction_plot_data$metric_id)),
  "age_rows_object_sha256", hash_object(filter(source_data, .data$panel == "age_distribution")),
  "main_rows_object_sha256", hash_object(filter(source_data, .data$panel == "retained_main_association")),
  "interaction_rows_object_sha256", hash_object(filter(source_data, .data$panel == "retained_site_heterogeneity")),
  "site_order_object_sha256", hash_object(site_contract),
  "display_text_sha256", sha256_file(display_spec_path),
  "panel_tag_levels", "uppercase A, B, C",
  "panel_tag_face", "bold",
  "panel_tag_position", "left side, top-left",
  "panel_tag_nominal_pt", "15",
  "canvas_width_in", "9.4",
  "canvas_height_in", "13",
  "candidate_pixel_width", "2820",
  "candidate_pixel_height", "3900",
  "intended_display_width_mm", "170",
  "display_reduction_factor", format(170 / (9.4 * 25.4), digits = 16),
  "effective_panel_tag_size_pt", format(15 * 170 / (9.4 * 25.4), digits = 16),
  "candidate_sha256", candidate_sha256,
  "candidate_bytes", as.character(file.info(candidate_tmp)$size),
  "proof_sha256", proof_sha256,
  "proof_bytes", as.character(file.info(proof_tmp)$size)
)
readr::write_csv(build_contract, contract_tmp, na = "")
writeLines(capture.output(sessionInfo()), session_tmp, useBytes = TRUE)

if (!all(file.info(temporary_outputs)$size > 0)) {
  stop("One or more temporary candidate outputs are empty", call. = FALSE)
}

destinations <- c(candidate_path, proof_path, build_contract_path, session_path)
for (i in seq_along(temporary_outputs)) {
  if (!file.rename(temporary_outputs[[i]], destinations[[i]])) {
    stop(sprintf("Could not seal candidate output: %s", destinations[[i]]), call. = FALSE)
  }
}

if (!identical(sha256_file(candidate_path), candidate_sha256)) {
  stop("Candidate identity changed during sealing", call. = FALSE)
}
if (!identical(sha256_file(proof_path), proof_sha256)) {
  stop("170-mm proof identity changed during sealing", call. = FALSE)
}

message(
  "Built isolated H10 manuscript-selection candidate from 322 frozen rows: ",
  candidate_sha256
)
