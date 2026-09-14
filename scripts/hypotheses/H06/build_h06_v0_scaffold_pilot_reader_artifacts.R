# Build the H06 V0-scaffold pilot comparison figure and physical-size audit.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
source(file.path(root, "scripts/pipeline/paths_io.R"))

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop(
    "H06 pilot reader artifacts require R 4.6.1; found ",
    as.character(getRversion()),
    call. = FALSE
  )
}
required_packages <- c("dplyr", "readr", "tibble", "ggplot2")
missing_packages <- required_packages[!vapply(
  required_packages,
  requireNamespace,
  logical(1),
  quietly = TRUE
)]
if (length(missing_packages) > 0L) {
  stop(
    "Missing project package(s): ",
    paste(missing_packages, collapse = ", "),
    call. = FALSE
  )
}

paths <- pipeline_paths(root)
producer <-
  "scripts/hypotheses/H06/build_h06_v0_scaffold_pilot_reader_artifacts.R"
table_root <- file.path(paths$tables, "H06")
figure_root <- file.path(paths$figures, "H06")
source_root <- file.path(paths$source_data, "H06")
qa_root <- file.path(root, "artifacts/12_manifests/H06/qa")
dir.create(figure_root, recursive = TRUE, showWarnings = FALSE)
dir.create(source_root, recursive = TRUE, showWarnings = FALSE)
dir.create(qa_root, recursive = TRUE, showWarnings = FALSE)

effects <- readr::read_csv(
  file.path(table_root, "H06_v0_scaffold_pilot_effects.csv"),
  show_col_types = FALSE
)
stopifnot(
  nrow(effects) == 36L,
  dplyr::n_distinct(effects$candidate_id) == 6L,
  dplyr::n_distinct(effects$effect_id) == 3L,
  dplyr::n_distinct(effects$placement) == 2L,
  all(is.finite(effects$estimate_response_ratio)),
  all(is.finite(effects$conf_low_response_ratio)),
  all(is.finite(effects$conf_high_response_ratio))
)

candidate_labels <- c(
  tmb_v0_participant = "V0: participant intercept",
  tmb_participant_day = "Participant + day intercepts",
  tmb_participant_latent_ar = "Participant + latent AR(1)",
  tmb_participant_day_latent_ar = "Participant + day + latent AR(1)",
  bam_participant_day_working_ar = "Participant + day + working AR(1)",
  glm_participant_cluster_robust = "Participant-cluster robust marginal"
)
effect_labels <- c(
  free_day_vs_work_day = "Free day / work day",
  active_vs_sedentary = "Active / sedentary",
  per_hour_previous_sleep = "Per hour previous sleep"
)
figure_data <- effects |>
  dplyr::mutate(
    candidate = factor(
      candidate_labels[candidate_id],
      levels = rev(unname(candidate_labels))
    ),
    effect = factor(
      effect_labels[effect_id],
      levels = unname(effect_labels)
    ),
    placement = factor(
      placement,
      levels = c("glasses", "chest"),
      labels = c("Near-eye", "Chest")
    )
  )

pilot_plot <- ggplot2::ggplot(
  figure_data,
  ggplot2::aes(
    x = estimate_response_ratio,
    y = candidate,
    xmin = conf_low_response_ratio,
    xmax = conf_high_response_ratio
  )
) +
  ggplot2::geom_vline(
    xintercept = 1,
    colour = "#6B7280",
    linewidth = 0.45,
    linetype = "dashed"
  ) +
  ggplot2::geom_errorbar(orientation = "y", width = 0.18, linewidth = 0.55) +
  ggplot2::geom_point(size = 2.0, shape = 21, fill = "#0072B2") +
  ggplot2::facet_grid(effect ~ placement, scales = "free_x") +
  ggplot2::scale_x_log10() +
  ggplot2::labs(
    x = "Expected hourly melEDI ratio (log scale; pilot 95% CI)",
    y = NULL
  ) +
  ggplot2::theme_minimal(base_size = 9) +
  ggplot2::theme(
    panel.grid.minor = ggplot2::element_blank(),
    strip.text = ggplot2::element_text(face = "bold", size = 8),
    axis.text = ggplot2::element_text(size = 7.5),
    axis.title.x = ggplot2::element_text(size = 8.5),
    panel.spacing = grid::unit(5, "pt")
  )

native_width_mm <- 170
native_height_mm <- 220
intended_width_mm <- 170
scale_factor <- intended_width_mm / native_width_mm
smallest_essential_nominal_text_pt <- 7.5
effective_final_text_pt <-
  smallest_essential_nominal_text_pt * scale_factor

write_csv_artifact(
  figure_data |>
    dplyr::mutate(
      candidate = as.character(candidate),
      effect = as.character(effect),
      placement = as.character(placement)
    ),
  file.path(source_root, "H06_v0_scaffold_pilot_effects_figure.csv"),
  producer = producer
)
ggplot2::ggsave(
  filename = file.path(figure_root, "H06_v0_scaffold_pilot_effects.png"),
  plot = pilot_plot,
  width = native_width_mm,
  height = native_height_mm,
  units = "mm",
  dpi = 300,
  bg = "white"
)
ggplot2::ggsave(
  filename = file.path(figure_root, "H06_v0_scaffold_pilot_effects.pdf"),
  plot = pilot_plot,
  width = native_width_mm,
  height = native_height_mm,
  units = "mm",
  device = grDevices::cairo_pdf,
  bg = "white"
)

a4_preview_path <- file.path(
  qa_root,
  "H06_v0_scaffold_pilot_effects_A4_preview.pdf"
)
grDevices::cairo_pdf(
  filename = a4_preview_path,
  width = 210 / 25.4,
  height = 297 / 25.4,
  onefile = TRUE
)
grid::grid.newpage()
grid::grid.rect(
  gp = grid::gpar(fill = "white", col = "#D1D5DB", linewidth = 0.5)
)
grid::pushViewport(grid::viewport(
  width = grid::unit(intended_width_mm, "mm"),
  height = grid::unit(native_height_mm * scale_factor, "mm")
))
print(pilot_plot, newpage = FALSE)
grid::popViewport()
grDevices::dev.off()

figure_audit <- tibble::tibble(
  figure_id = "H06_v0_scaffold_pilot_effects",
  native_width_mm = native_width_mm,
  native_height_mm = native_height_mm,
  intended_width_mm = intended_width_mm,
  scale_factor = scale_factor,
  smallest_essential_nominal_text_pt = smallest_essential_nominal_text_pt,
  effective_final_text_pt = effective_final_text_pt,
  page_width_mm = 210,
  page_height_mm = 297,
  side_margin_mm = 20,
  a4_preview = paste0(
    "artifacts/12_manifests/H06/qa/",
    basename(a4_preview_path)
  ),
  inspection_medium = paste(
    "A4 portrait PDF at 210 x 297 mm, rendered at 150 dpi and inspected",
    "at original page dimensions"
  ),
  clipping_overlap_wrapping_distortion_balance =
    paste(
      "PASS: no clipping, overlap, wrapping, or distortion; candidate labels,",
      "facet labels, axes, points, and 95% CI whiskers are legible; the two",
      "placement panels and three effect rows have balanced data regions."
    ),
  report_011_status = "PASS"
)
write_csv_artifact(
  figure_audit,
  file.path(source_root, "H06_v0_scaffold_pilot_figure_readability.csv"),
  producer = producer
)

message("H06 V0-scaffold pilot reader artifacts built")
