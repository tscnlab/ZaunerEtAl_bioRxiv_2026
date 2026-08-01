# Create the author-requested Gate B histogram for an approved clock cut.
#
# This visualization is explicitly non-inferential. It records the exact
# model-data identities used for the primary 16:00 conversion or another
# explicitly requested comparison cut.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
source(file.path(root, "scripts/pipeline/paths_io.R"))
source(file.path(root, "scripts/hypotheses/H01/h01_contract.R"))
source(file.path(root, "scripts/hypotheses/H01/h01_modeling.R"))

if (!identical(as.character(getRversion()), "4.6.1")) {
  h01_abort(
    "The H01 Gate B histogram requires R 4.6.1; found %s",
    as.character(getRversion())
  )
}

shift_cutpoint_hour <- suppressWarnings(as.numeric(Sys.getenv(
  "H01_L10_SHIFT_CUTPOINT_HOUR",
  unset = "16"
)))
if (
  length(shift_cutpoint_hour) != 1L ||
    !is.finite(shift_cutpoint_hour) ||
    shift_cutpoint_hour <= 0 ||
    shift_cutpoint_hour >= 24
) {
  h01_abort(
    paste0(
      "H01_L10_SHIFT_CUTPOINT_HOUR must be one finite hour strictly ",
      "between 0 and 24."
    )
  )
}

is_primary_cutpoint <- isTRUE(all.equal(
  shift_cutpoint_hour,
  16,
  tolerance = 1e-12
))
is_noon_cutpoint <- isTRUE(all.equal(
  shift_cutpoint_hour,
  12,
  tolerance = 1e-12
))
cutpoint_text <- format(
  shift_cutpoint_hour,
  trim = TRUE,
  scientific = FALSE
)
cutpoint_tag <- gsub("\\.", "p", cutpoint_text)
cutpoint_clock_label <- sprintf("%02d:00", as.integer(shift_cutpoint_hour))
conversion_rule <- sprintf(
  "if clock hour > %s, subtract 24",
  cutpoint_text
)
axis_limits <- c(shift_cutpoint_hour - 24, shift_cutpoint_hour)
axis_breaks <- seq(
  axis_limits[[1]] + 4,
  axis_limits[[2]] - 4,
  by = 4
)

if (is_primary_cutpoint) {
  input_status <- "AUTHOR_APPROVED_PRIMARY_CONVERSION"
  variant_id <- "primary_16h_cutpoint"
  output_stem <- "H01_l10_midpoint_primary_16h_conversion_histogram"
  manifest_filename <- paste0(output_stem, "_artifacts.csv")
} else if (is_noon_cutpoint) {
  input_status <- "REGISTERED_NOON_SENSITIVITY"
  variant_id <- "noon_cutpoint_sensitivity"
  output_stem <- "H01_l10_midpoint_noon_conversion_sensitivity_histogram"
  manifest_filename <- paste0(output_stem, "_artifacts.csv")
} else {
  input_status <- "NON_REGISTERED_DIAGNOSTIC_CUTPOINT"
  variant_id <- paste0("experimental_", cutpoint_tag, "h_cutpoint")
  output_stem <- paste0(
    "H01_l10_midpoint_shift_after_",
    cutpoint_tag,
    "h_experimental_histogram"
  )
  manifest_filename <- paste0(output_stem, "_artifacts.csv")
}

producer <- "scripts/hypotheses/H01/plot_h01_l10_midpoint_gate.R"
source_root <- file.path(root, "artifacts/11_source_data/H01/gates")
table_root <- file.path(root, "artifacts/09_tables/H01/gates")
figure_root <- file.path(root, "artifacts/10_figures/H01/gates")
manifest_root <- file.path(root, "artifacts/12_manifests")
invisible(vapply(
  c(source_root, table_root, figure_root, manifest_root),
  dir.create,
  logical(1),
  recursive = TRUE,
  showWarnings = FALSE
))

superseded_stems <- c(
  "H01_l10_midpoint_converted_histogram",
  "H01_l10_midpoint_shift_after_16h_experimental_histogram"
)
superseded_paths <- c(
  file.path(
    source_root,
    paste0(
      rep(superseded_stems, each = 2L),
      rep(c("_source.csv", "_bins.csv"), times = length(superseded_stems))
    )
  ),
  file.path(
    table_root,
    paste0(
      rep(superseded_stems, each = 2L),
      rep(c("_summary.csv", "_provenance.csv"), times = length(superseded_stems))
    )
  ),
  file.path(
    figure_root,
    paste0(
      rep(superseded_stems, each = 2L),
      rep(c(".png", ".svg"), times = length(superseded_stems))
    )
  ),
  file.path(
    manifest_root,
    paste0(superseded_stems, "_artifacts.csv")
  ),
  file.path(
    manifest_root,
    "H01_l10_midpoint_gate_histogram_artifacts.csv"
  )
)
unlink(superseded_paths[file.exists(superseded_paths)])
if (any(file.exists(superseded_paths))) {
  h01_abort("Could not remove superseded H01 Gate B display artifacts")
}

paths <- list(
  main_object = file.path(root, "artifacts/06_model_data/H01.rds"),
  main_manifest = file.path(
    root,
    "artifacts/12_manifests/H01_model_data_artifacts.csv"
  ),
  sensitivity_object = file.path(
    root,
    paste0(
      "artifacts/06_model_data/H01/scenarios/",
      "manuscript_prepared_data/H01.rds"
    )
  ),
  sensitivity_manifest = file.path(
    root,
    paste0(
      "artifacts/12_manifests/",
      "H01_manuscript_prepared_data_artifacts.csv"
    )
  )
)
input_hashes <- vapply(paths, artifact_sha256, character(1))
objects <- list(
  main = readRDS(paths$main_object),
  manuscript_prepared_data = readRDS(paths$sensitivity_object)
)

spec <- h01_metric_registry() |>
  dplyr::filter(.data$metric_id == "l10_midpoint")
stopifnot(nrow(spec) == 1L)

histogram_data <- dplyr::bind_rows(lapply(
  names(objects),
  function(data_scenario_id) {
    dplyr::bind_rows(lapply(c("glasses", "chest"), function(placement) {
      frame <- h01_prepare_model_frame(
        objects[[data_scenario_id]],
        spec,
        placement = placement,
        sample_scenario = "all_available"
      )
      dplyr::transmute(
        frame,
        data_scenario_id = data_scenario_id,
        data_scenario = ifelse(
          data_scenario_id == "main",
          "Main data",
          "Manuscript-prepared data"
        ),
        placement = placement,
        placement_label = ifelse(
          placement == "glasses",
          "Near eye (primary)",
          "Chest (complementary)"
        ),
        site = as.character(.data$site),
        participant_key = as.character(.data$participant_key),
        local_date = as.character(.data$local_date),
        l10_midpoint_original_minutes = .data$value,
        l10_midpoint_original_clock_hour = .data$value / 60,
        primary_16h_converted_hour = .data$response_value,
        noon_sensitivity_converted_hour = h01_transform_response(
          .data$value,
          "clock_hours_midnight_after_12"
        ),
        l10_midpoint_converted_hour = ifelse(
          .data$value / 60 > shift_cutpoint_hour,
          .data$value / 60 - 24,
          .data$value / 60
        ),
        shift_cutpoint_hour = shift_cutpoint_hour,
        conversion_rule = conversion_rule,
        variant_id = variant_id,
        input_status = input_status
      )
    }))
  }
))

expected_conversion <- ifelse(
  histogram_data$l10_midpoint_original_clock_hour > shift_cutpoint_hour,
  histogram_data$l10_midpoint_original_clock_hour - 24,
  histogram_data$l10_midpoint_original_clock_hour
)
stopifnot(
  nrow(histogram_data) > 0L,
  all(is.finite(histogram_data$l10_midpoint_converted_hour)),
  all.equal(
    histogram_data$l10_midpoint_converted_hour,
    expected_conversion,
    tolerance = 1e-12
  ),
  all(histogram_data$l10_midpoint_converted_hour >= axis_limits[[1]]),
  all(histogram_data$l10_midpoint_converted_hour <= axis_limits[[2]]),
  !anyDuplicated(histogram_data[c(
    "data_scenario_id",
    "placement",
    "participant_key",
    "local_date"
  )])
)
if (is_primary_cutpoint) {
  stopifnot(isTRUE(all.equal(
    histogram_data$l10_midpoint_converted_hour,
    histogram_data$primary_16h_converted_hour,
    tolerance = 1e-12
  )))
}

histogram_data <- histogram_data |>
  dplyr::mutate(
    data_scenario = factor(
      .data$data_scenario,
      levels = c("Main data", "Manuscript-prepared data")
    ),
    placement_label = factor(
      .data$placement_label,
      levels = c("Near eye (primary)", "Chest (complementary)")
    )
  ) |>
  dplyr::arrange(
    .data$data_scenario,
    .data$placement_label,
    .data$site,
    .data$participant_key,
    .data$local_date
  )

summary_data <- histogram_data |>
  dplyr::group_by(
    .data$data_scenario_id,
    .data$data_scenario,
    .data$placement,
    .data$placement_label
  ) |>
  dplyr::summarise(
    participants = dplyr::n_distinct(.data$participant_key),
    participant_days = dplyr::n(),
    observations = dplyr::n(),
    sites = dplyr::n_distinct(.data$site),
    minimum_converted_hour = min(.data$l10_midpoint_converted_hour),
    first_quartile_converted_hour = stats::quantile(
      .data$l10_midpoint_converted_hour,
      0.25,
      names = FALSE
    ),
    median_converted_hour = stats::median(
      .data$l10_midpoint_converted_hour
    ),
    third_quartile_converted_hour = stats::quantile(
      .data$l10_midpoint_converted_hour,
      0.75,
      names = FALSE
    ),
    maximum_converted_hour = max(.data$l10_midpoint_converted_hour),
    transformed_span_hours = diff(range(
      .data$l10_midpoint_converted_hour
    )),
    shift_cutpoint_hour = dplyr::first(.data$shift_cutpoint_hour),
    shifted_after_cutpoint_n = sum(
      .data$l10_midpoint_original_clock_hour > shift_cutpoint_hour
    ),
    shifted_after_cutpoint_percent =
      100 * .data$shifted_after_cutpoint_n / .data$observations,
    changed_from_primary_16h_n = sum(
      abs(
        .data$l10_midpoint_converted_hour -
          .data$primary_16h_converted_hour
      ) > 1e-12
    ),
    changed_from_primary_16h_percent =
      100 * .data$changed_from_primary_16h_n / .data$observations,
    .groups = "drop"
  )

bin_width <- 0.5
histogram_bins <- histogram_data |>
  dplyr::mutate(
    bin_index = pmin(
      47L,
      pmax(
        0L,
        floor(
          (
            .data$l10_midpoint_converted_hour -
              axis_limits[[1]]
          ) / bin_width
        )
      )
    )
  ) |>
  dplyr::count(
    .data$data_scenario_id,
    .data$data_scenario,
    .data$placement,
    .data$placement_label,
    .data$bin_index,
    name = "participant_days"
  ) |>
  tidyr::complete(
    .data$data_scenario_id,
    .data$data_scenario,
    .data$placement,
    .data$placement_label,
    bin_index = 0:47,
    fill = list(participant_days = 0L)
  ) |>
  dplyr::mutate(
    bin_left_hour = axis_limits[[1]] + .data$bin_index * bin_width,
    bin_right_hour = .data$bin_left_hour + bin_width,
    bin_midpoint_hour = .data$bin_left_hour + bin_width / 2,
    bin_width_hours = bin_width
  )

plot <- ggplot2::ggplot(
  histogram_bins,
  ggplot2::aes(
    x = .data$bin_midpoint_hour,
    y = .data$participant_days,
    fill = .data$placement_label
  )
) +
  ggplot2::geom_col(width = bin_width * 0.94, colour = "white", linewidth = 0.1) +
  ggplot2::geom_vline(
    xintercept = 0,
    colour = "grey25",
    linewidth = 0.55
  ) +
  ggplot2::facet_grid(
    rows = ggplot2::vars(.data$data_scenario),
    cols = ggplot2::vars(.data$placement_label),
    scales = "fixed"
  ) +
  ggplot2::scale_fill_manual(
    values = c(
      "Near eye (primary)" = "#0072B2",
      "Chest (complementary)" = "#D55E00"
    ),
    guide = "none"
  ) +
  ggplot2::scale_x_continuous(
    limits = axis_limits,
    breaks = axis_breaks,
    expand = ggplot2::expansion(mult = c(0.005, 0.005))
  ) +
  ggplot2::scale_y_continuous(
    expand = ggplot2::expansion(mult = c(0, 0.08))
  ) +
  ggplot2::labs(
    title = ifelse(
      is_primary_cutpoint,
      "L10 midpoint after the primary 16:00 conversion",
      paste0(
        "L10 midpoint with the ",
        cutpoint_clock_label,
        " cutpoint"
      )
    ),
    subtitle = paste0(
      "Values strictly after ",
      cutpoint_clock_label,
      " are shifted by -24 h; ",
      if (is_primary_cutpoint) {
        "primary model conversion"
      } else if (is_noon_cutpoint) {
        "registered sensitivity conversion"
      } else {
        "additional diagnostic conversion"
      }
    ),
    x = "Converted L10 midpoint (hours; 0 = midnight)",
    y = "Participant-days",
    caption = paste0(
      "All-available frames. Near eye is primary; chest is complementary.\n",
      "Bin width: 0.5 h. Vertical line: midnight."
    )
  ) +
  ggplot2::theme_minimal(base_size = 12) +
  ggplot2::theme(
    panel.grid.minor = ggplot2::element_blank(),
    panel.grid.major.x = ggplot2::element_blank(),
    panel.spacing.x = grid::unit(0.8, "lines"),
    strip.text = ggplot2::element_text(face = "bold"),
    plot.title.position = "plot",
    plot.caption.position = "plot"
  )

source_path <- file.path(
  source_root,
  paste0(output_stem, "_source.csv")
)
bin_path <- file.path(
  source_root,
  paste0(output_stem, "_bins.csv")
)
summary_path <- file.path(
  table_root,
  paste0(output_stem, "_summary.csv")
)
png_path <- file.path(
  figure_root,
  paste0(output_stem, ".png")
)
svg_path <- file.path(
  figure_root,
  paste0(output_stem, ".svg")
)
provenance_path <- file.path(
  table_root,
  paste0(output_stem, "_provenance.csv")
)
manifest_path <- file.path(
  manifest_root,
  manifest_filename
)

readr::write_csv(histogram_data, source_path, na = "")
readr::write_csv(histogram_bins, bin_path, na = "")
readr::write_csv(summary_data, summary_path, na = "")
ggplot2::ggsave(
  png_path,
  plot = plot,
  width = 10,
  height = 7,
  units = "in",
  dpi = 300,
  bg = "white"
)
grDevices::svg(
  filename = svg_path,
  width = 10,
  height = 7,
  bg = "white"
)
print(plot)
grDevices::dev.off()

provenance <- tibble::tibble(
  input_status = input_status,
  r_version = as.character(getRversion()),
  ggplot2_version = as.character(utils::packageVersion("ggplot2")),
  command = paste(
    "RENV_CONFIG_SANDBOX_ENABLED=FALSE",
    "NATHEALTH_PROJECT_ROOT=<project>",
    paste0(
      "H01_L10_SHIFT_CUTPOINT_HOUR=",
      cutpoint_text
    ),
    "Rscript scripts/hypotheses/H01/plot_h01_l10_midpoint_gate.R"
  ),
  main_object_sha256 = input_hashes[["main_object"]],
  main_manifest_sha256 = input_hashes[["main_manifest"]],
  sensitivity_object_sha256 = input_hashes[["sensitivity_object"]],
  sensitivity_manifest_sha256 = input_hashes[["sensitivity_manifest"]],
  implementation_contract_sha256 =
    objects$main$metadata$implementation_contract_sha256,
  shared_implementation_sha256 =
    objects$main$metadata$shared_implementation_sha256,
  variant_id = variant_id,
  shift_cutpoint_hour = shift_cutpoint_hour,
  conversion_rule = conversion_rule,
  axis_minimum_hour = axis_limits[[1]],
  axis_maximum_hour = axis_limits[[2]],
  bin_width_hours = bin_width,
  producer_sha256 = artifact_sha256(file.path(root, producer))
)
readr::write_csv(provenance, provenance_path, na = "")

output_files <- c(
  file.path(root, producer),
  source_path,
  bin_path,
  summary_path,
  png_path,
  svg_path,
  provenance_path
)
manifest <- dplyr::bind_rows(lapply(output_files, function(path) {
  tibble::tibble(
    path = substring(
      normalizePath(path, winslash = "/", mustWork = TRUE),
      nchar(root) + 2L
    ),
    sha256 = artifact_sha256(path),
    bytes = as.numeric(file.info(path)$size),
    producer = producer,
    r_version = as.character(getRversion()),
    input_status = input_status
  )
}))
readr::write_csv(manifest, manifest_path, na = "")

message(
  "H01 Gate B histogram completed for cutpoint ",
  cutpoint_clock_label
)
print(summary_data)
