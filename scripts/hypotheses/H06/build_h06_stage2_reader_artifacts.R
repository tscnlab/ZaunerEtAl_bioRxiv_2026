# Build H06 Stage 2 reader figures and physical-size QA previews.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
source(file.path(root, "scripts/pipeline/paths_io.R"))

if (!identical(as.character(getRversion()), "4.6.1")) {
  stop("H06 reader artifacts require R 4.6.1", call. = FALSE)
}
required_packages <- c("dplyr", "tidyr", "readr", "ggplot2", "scales")
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

qa_status <- Sys.getenv("H06_FIGURE_QA_STATUS", unset = "NOT TESTED")
if (!qa_status %in% c("NOT TESTED", "PASS")) {
  stop("H06_FIGURE_QA_STATUS must be `NOT TESTED` or `PASS`", call. = FALSE)
}

producer <- "scripts/hypotheses/H06/build_h06_stage2_reader_artifacts.R"
table_root <- file.path(root, "artifacts/09_tables/H06")
diagnostic_root <- file.path(root, "artifacts/08_diagnostics/H06")
figure_root <- file.path(root, "artifacts/10_figures/H06")
source_root <- file.path(root, "artifacts/11_source_data/H06")
manifest_root <- file.path(root, "artifacts/12_manifests/H06")
qa_root <- file.path(manifest_root, "qa")
invisible(vapply(
  c(figure_root, source_root, manifest_root, qa_root),
  dir.create,
  logical(1),
  recursive = TRUE,
  showWarnings = FALSE
))

write_source <- function(data, filename) {
  write_csv_artifact(
    data,
    file.path(source_root, filename),
    producer = producer
  )
  invisible(data)
}

read_table <- function(filename) {
  readr::read_csv(
    file.path(table_root, filename),
    show_col_types = FALSE,
    na = ""
  )
}

read_diagnostic <- function(filename) {
  readr::read_csv(
    file.path(diagnostic_root, filename),
    show_col_types = FALSE,
    na = ""
  )
}

native_width_mm <- 170
native_width_in <- native_width_mm / 25.4
smallest_nominal_text_pt <- 8

save_figure <- function(plot, filename, height_mm) {
  height_in <- height_mm / 25.4
  ggplot2::ggsave(
    file.path(figure_root, paste0(filename, ".png")),
    plot = plot,
    width = native_width_in,
    height = height_in,
    units = "in",
    dpi = 320,
    bg = "white"
  )
  ggplot2::ggsave(
    file.path(figure_root, paste0(filename, ".pdf")),
    plot = plot,
    width = native_width_in,
    height = height_in,
    units = "in",
    device = grDevices::cairo_pdf,
    bg = "white"
  )
  preview_path <- file.path(qa_root, paste0(filename, "_A4_preview.pdf"))
  grDevices::cairo_pdf(
    preview_path,
    width = 210 / 25.4,
    height = 297 / 25.4,
    bg = "white"
  )
  grid::grid.newpage()
  grid::grid.rect(gp = grid::gpar(fill = "white", col = NA))
  grid::pushViewport(grid::viewport(
    width = grid::unit(native_width_mm, "mm"),
    height = grid::unit(height_mm, "mm")
  ))
  print(plot, newpage = FALSE)
  grid::popViewport()
  grDevices::dev.off()
  invisible(preview_path)
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

effect_labels <- c(
  work_free_day = "Free day versus work day",
  activity_status = "Active versus sedentary",
  previous_sleep_duration_centered_h =
    "Per additional hour of previous sleep"
)
effect_short <- c(
  work_free_day = "Free versus work day",
  activity_status = "Active versus sedentary",
  previous_sleep_duration_centered_h = "Previous sleep (per h)"
)
run_labels <- c(
  main__glasses__all_available = "Primary near-eye",
  main__chest__all_available = "Chest (all available)",
  main__glasses__paired_common = "Near-eye (paired days)",
  main__chest__paired_common = "Chest (paired days)",
  gap_timing_unaware__glasses__all_available =
    "Gap-timing-unaware near-eye",
  gap_timing_unaware__chest__all_available =
    "Gap-timing-unaware chest"
)
run_order <- unname(run_labels)

effects <- read_table("H06_robust_core_effects.csv") |>
  dplyr::filter(.data$distribution == "equal_site") |>
  dplyr::transmute(
    .data$run_id,
    scenario = factor(run_labels[.data$run_id], levels = rev(run_order)),
    placement = ifelse(grepl("chest", .data$run_id), "Chest", "Near-eye"),
    effect = factor(
      effect_labels[.data$predictor_id],
      levels = unname(effect_labels)
    ),
    predictor_id = .data$predictor_id,
    ratio = .data$estimate_ratio,
    conf_low = .data$conf_low_ratio,
    conf_high = .data$conf_high_ratio,
    p_adjusted = .data$p_adjusted,
    inferential_role = dplyr::case_when(
      .data$run_id == "main__glasses__all_available" ~
        "Primary prespecified association",
      .data$run_id ==
        "gap_timing_unaware__glasses__all_available" ~
        "Prespecified data sensitivity",
      TRUE ~ "Contextual placement estimate; no new p-value family"
    )
  )
write_source(effects, "H06_core_effects_figure.csv")

core_plot <- ggplot2::ggplot(
  effects,
  ggplot2::aes(
    x = .data$ratio,
    y = .data$scenario,
    xmin = .data$conf_low,
    xmax = .data$conf_high,
    colour = .data$placement,
    shape = .data$placement
  )
) +
  ggplot2::geom_vline(xintercept = 1, colour = "grey55", linewidth = 0.4) +
  ggplot2::geom_errorbar(orientation = "y", width = 0.18, linewidth = 0.5) +
  ggplot2::geom_point(size = 2.1) +
  ggplot2::facet_wrap(~effect, scales = "free_x", ncol = 1) +
  ggplot2::scale_x_log10(
    breaks = c(0.5, 0.75, 1, 1.5, 2, 3),
    labels = scales::label_number(accuracy = 0.01)
  ) +
  ggplot2::scale_colour_manual(
    values = c("Near-eye" = "#0072B2", "Chest" = "#D55E00")
  ) +
  ggplot2::labs(
    x = "Ratio of expected supported-hour melEDI (95% CI; log scale)",
    y = NULL,
    colour = "Placement",
    shape = "Placement"
  ) +
  theme_h06()
save_figure(core_plot, "H06_core_effects", height_mm = 188)

site_registry <- readr::read_csv(
  file.path(root, "config/site_display_registry.csv"),
  show_col_types = FALSE
) |>
  dplyr::arrange(.data$display_order)
site_effects <- read_table("H06_robust_site_specific_effects.csv") |>
  dplyr::filter(.data$run_id == "main__glasses__all_available") |>
  dplyr::left_join(
    site_registry,
    by = "site",
    relationship = "many-to-one"
  ) |>
  dplyr::transmute(
    .data$site,
    display_name = factor(
      .data$display_name,
      levels = rev(site_registry$display_name)
    ),
    .data$display_order,
    .data$color_hex,
    effect = factor(
      effect_labels[.data$predictor_id],
      levels = unname(effect_labels)
    ),
    predictor_id = .data$predictor_id,
    ratio = .data$estimate_ratio,
    conf_low = .data$conf_low_ratio,
    conf_high = .data$conf_high_ratio,
    inferential_role =
      "Site-specific estimate and 95% CI; no site-specific p-value screen"
  )
write_source(site_effects, "H06_primary_site_effects_figure.csv")

site_plot <- ggplot2::ggplot(
  site_effects,
  ggplot2::aes(
    x = .data$ratio,
    y = .data$display_name,
    xmin = .data$conf_low,
    xmax = .data$conf_high,
    colour = .data$site
  )
) +
  ggplot2::geom_vline(xintercept = 1, colour = "grey55", linewidth = 0.4) +
  ggplot2::geom_errorbar(orientation = "y", width = 0.15, linewidth = 0.5) +
  ggplot2::geom_point(size = 2) +
  ggplot2::facet_wrap(~effect, scales = "free_x", ncol = 1) +
  ggplot2::scale_x_log10(labels = scales::label_number(accuracy = 0.01)) +
  ggplot2::scale_colour_manual(
    values = stats::setNames(site_registry$color_hex, site_registry$site),
    guide = "none"
  ) +
  ggplot2::labs(
    x = "Site-specific expected-hour ratio (95% CI; log scale)",
    y = NULL
  ) +
  theme_h06()
save_figure(site_plot, "H06_primary_site_effects", height_mm = 215)

v0_frozen <- read_table("H06_frozen_V0_output_summary.csv")
v0_current <- read_table("H06_current_pin_V0_method_effects.csv") |>
  dplyr::filter(.data$effect_id %in% c("free_vs_work", "per_hour_sleep")) |>
  dplyr::transmute(
    .data$placement,
    analysis = "Current-pin V0 method",
    effect = dplyr::recode(
      .data$effect_id,
      free_vs_work = "Free day versus work day",
      per_hour_sleep = "Per additional hour of previous sleep"
    ),
    ratio = .data$estimate_ratio,
    conf_low = .data$conf_low_ratio,
    conf_high = .data$conf_high_ratio
  )
revised <- effects |>
  dplyr::filter(
    .data$run_id %in% c(
      "main__glasses__all_available",
      "main__chest__all_available"
    ),
    .data$effect %in% c(
      "Free day versus work day",
      "Per additional hour of previous sleep"
    )
  ) |>
  dplyr::transmute(
    placement = .data$placement,
    analysis = "Revised population-mean model",
    effect = as.character(.data$effect),
    .data$ratio,
    .data$conf_low,
    .data$conf_high
  )
frozen_long <- dplyr::bind_rows(
  v0_frozen |>
    dplyr::transmute(
      .data$placement,
      analysis = "Frozen submitted V0",
      effect = "Free day versus work day",
      ratio = .data$free_vs_work_ratio,
      conf_low = NA_real_,
      conf_high = NA_real_
    ),
  v0_frozen |>
    dplyr::transmute(
      .data$placement,
      analysis = "Frozen submitted V0",
      effect = "Per additional hour of previous sleep",
      ratio = .data$sleep_ratio_per_hour,
      conf_low = NA_real_,
      conf_high = NA_real_
    )
)
v0_comparison <- dplyr::bind_rows(frozen_long, v0_current, revised) |>
  dplyr::mutate(
    placement = factor(
      dplyr::recode(
        tolower(as.character(.data$placement)),
        glasses = "Near-eye",
        `near-eye` = "Near-eye",
        chest = "Chest"
      ),
      levels = c("Near-eye", "Chest")
    ),
    analysis = factor(
      .data$analysis,
      levels = c(
        "Frozen submitted V0",
        "Current-pin V0 method",
        "Revised population-mean model"
      )
    ),
    effect = factor(.data$effect, levels = unname(effect_labels[c(1, 3)])),
    interval_role = ifelse(
      is.finite(.data$conf_low),
      "95% CI available",
      "Frozen point estimate; interval not recoverable from frozen table"
    )
  )
write_source(v0_comparison, "H06_V0_comparison_figure.csv")

v0_plot <- ggplot2::ggplot(
  v0_comparison,
  ggplot2::aes(
    x = .data$ratio,
    y = .data$analysis,
    xmin = .data$conf_low,
    xmax = .data$conf_high,
    colour = .data$placement,
    shape = .data$placement
  )
) +
  ggplot2::geom_vline(xintercept = 1, colour = "grey55", linewidth = 0.4) +
  ggplot2::geom_errorbar(
    orientation = "y",
    width = 0.16,
    linewidth = 0.5,
    na.rm = TRUE
  ) +
  ggplot2::geom_point(size = 2.2) +
  ggplot2::facet_wrap(~effect, ncol = 1) +
  ggplot2::scale_x_log10(
    breaks = c(0.75, 1, 1.25, 1.5, 2),
    labels = scales::label_number(accuracy = 0.01)
  ) +
  ggplot2::scale_colour_manual(
    values = c("Near-eye" = "#0072B2", "Chest" = "#D55E00")
  ) +
  ggplot2::labs(
    x = "Ratio (95% CI where available; log scale)",
    y = NULL,
    colour = "Placement",
    shape = "Placement"
  ) +
  theme_h06()
save_figure(v0_plot, "H06_V0_comparison", height_mm = 132)

clock_residual <- read_diagnostic("H06_robust_residuals_by_local_clock.csv") |>
  dplyr::filter(.data$run_id == "main__glasses__all_available") |>
  dplyr::summarise(
    residual_mean = stats::weighted.mean(
      .data$residual_mean,
      w = .data$one_hour_observations
    ),
    one_hour_observations = sum(.data$one_hour_observations),
    .by = c("site", "work_free_day", "clock_hour_bin")
  ) |>
  dplyr::left_join(
    site_registry,
    by = "site",
    relationship = "many-to-one"
  ) |>
  dplyr::mutate(
    display_name = factor(
      .data$display_name,
      levels = site_registry$display_name
    )
  )
write_source(clock_residual, "H06_primary_residual_clock_figure.csv")

clock_plot <- ggplot2::ggplot(
  clock_residual,
  ggplot2::aes(
    x = .data$clock_hour_bin + 0.5,
    y = .data$residual_mean,
    colour = .data$work_free_day
  )
) +
  ggplot2::geom_hline(yintercept = 0, colour = "grey55", linewidth = 0.4) +
  ggplot2::geom_line(linewidth = 0.5) +
  ggplot2::geom_point(
    ggplot2::aes(size = .data$one_hour_observations),
    alpha = 0.75
  ) +
  ggplot2::facet_wrap(~display_name, ncol = 3) +
  ggplot2::scale_colour_manual(
    values = c("Work day" = "#0072B2", "Free day" = "#D55E00")
  ) +
  ggplot2::scale_size_continuous(range = c(0.5, 2.2), guide = "none") +
  ggplot2::scale_x_continuous(breaks = c(0, 6, 12, 18, 24)) +
  ggplot2::labs(
    x = "Local clock hour",
    y = "Mean Pearson residual",
    colour = "Day type"
  ) +
  theme_h06()
save_figure(clock_plot, "H06_primary_residual_clock", height_mm = 182)

paired_effects <- effects |>
  dplyr::filter(
    .data$run_id %in% c(
      "main__glasses__paired_common",
      "main__chest__paired_common"
    )
  ) |>
  dplyr::mutate(
    effect = factor(
      effect_short[.data$predictor_id],
      levels = rev(unname(effect_short))
    ),
    paired_participant_days = 553L,
    paired_participants = 109L,
    near_hours = 12842L,
    chest_hours = 12842L,
    exact_common_hour_keys = 12839L,
    display_role = paste0(
      "Side-by-side paired-day estimates; identity scatterplot not applicable ",
      "because three hour keys differ by placement"
    )
  ) |>
  dplyr::select(
    "run_id", "placement", "predictor_id", "effect", "ratio", "conf_low",
    "conf_high", "paired_participant_days", "paired_participants",
    "near_hours", "chest_hours", "exact_common_hour_keys", "display_role"
  )
write_source(paired_effects, "H06_paired_placement_effects_figure.csv")

paired_plot <- ggplot2::ggplot(
  paired_effects,
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
save_figure(paired_plot, "H06_paired_placement_effects", height_mm = 120)

figure_registry <- tibble::tribble(
  ~figure_id, ~native_height_mm, ~source_csv,
  "H06_core_effects", 188,
  "artifacts/11_source_data/H06/H06_core_effects_figure.csv",
  "H06_primary_site_effects", 215,
  "artifacts/11_source_data/H06/H06_primary_site_effects_figure.csv",
  "H06_V0_comparison", 132,
  "artifacts/11_source_data/H06/H06_V0_comparison_figure.csv",
  "H06_primary_residual_clock", 182,
  "artifacts/11_source_data/H06/H06_primary_residual_clock_figure.csv",
  "H06_paired_placement_effects", 120,
  "artifacts/11_source_data/H06/H06_paired_placement_effects_figure.csv"
)
qa_text <- if (qa_status == "PASS") {
  paste0(
    "PASS at 170 mm on an A4 portrait page with 20-mm side margins: ",
    "no clipping, overlap, harmful wrapping, distortion, or materially ",
    "imbalanced data region."
  )
} else {
  paste0(
    "NOT TESTED: inspect the A4 physical-size preview for clipping, overlap, ",
    "wrapping, distortion, and data-region balance before reader use."
  )
}
figure_qa <- figure_registry |>
  dplyr::mutate(
    base_width_in = native_width_in,
    base_height_in = .data$native_height_mm / 25.4,
    export_scale_multiplier = 1,
    export_width_in = native_width_in,
    export_height_in = .data$native_height_mm / 25.4,
    raster_dpi = 320,
    native_width_mm = native_width_mm,
    intended_html_display_width_mm = 170,
    intended_print_display_width_mm = 170,
    scale_factor = 170 / .data$native_width_mm,
    smallest_essential_nominal_text_pt = smallest_nominal_text_pt,
    effective_final_text_pt =
      .data$smallest_essential_nominal_text_pt * .data$scale_factor,
    physical_size_inspection = qa_text,
    clipping_overlap_wrapping_distortion_balance = qa_text,
    report_011_status = qa_status,
    a4_preview = file.path(
      "artifacts/12_manifests/H06/qa",
      paste0(.data$figure_id, "_A4_preview.pdf")
    )
  ) |>
  dplyr::relocate(
    "figure_id",
    "source_csv",
    "a4_preview",
    "native_width_mm",
    "native_height_mm",
    "intended_print_display_width_mm",
    "scale_factor",
    "smallest_essential_nominal_text_pt",
    "effective_final_text_pt",
    "physical_size_inspection",
    "report_011_status"
  )
write_csv_artifact(
  figure_qa,
  file.path(manifest_root, "H06_stage2_figure_readability_qa.csv"),
  producer = producer
)

message("H06 Stage 2 reader artifacts and A4 QA previews built: ", qa_status)
