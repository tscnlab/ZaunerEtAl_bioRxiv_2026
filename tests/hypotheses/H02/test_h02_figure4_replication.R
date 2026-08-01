# Standalone checks for the audited H02 Figure 4 replication and interval
# robustness analysis.

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
})

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
source(file.path(root, "scripts/pipeline/paths_io.R"))

figure_path <- file.path(
  root,
  "artifacts/10_figures/H02/figure4_exact_layout_replication.png"
)
chest_figure_path <- file.path(
  root,
  "artifacts/10_figures/H02/figure4_exact_layout_replication_chest.png"
)
source_path <- file.path(
  root,
  "artifacts/11_source_data/H02/figure4_exact_layout_source.rds"
)
chest_source_path <- file.path(
  root,
  "artifacts/11_source_data/H02/figure4_exact_layout_source_chest.rds"
)
methods_path <- file.path(
  root,
  "artifacts/09_tables/H02/uncertainty_band_methods.csv"
)
robustness_path <- file.path(
  root,
  "artifacts/09_tables/H02/uncertainty_band_robustness.csv"
)
pointwise_windows_path <- file.path(
  root,
  "artifacts/09_tables/H02/figure4_pointwise_conditional_windows.csv"
)
inputs_path <- file.path(
  root,
  "artifacts/12_manifests/H02/figure4_replication_inputs.csv"
)
manifest_path <- file.path(
  root,
  "artifacts/12_manifests/H02/figure4_replication_manifest.csv"
)
stopifnot(all(file.exists(c(
  figure_path,
  chest_figure_path,
  source_path,
  chest_source_path,
  methods_path,
  robustness_path,
  pointwise_windows_path,
  inputs_path,
  manifest_path
))))

expected_registry <- tibble::tribble(
  ~site, ~display_order, ~display_name, ~color_hex,
  "RISE", 1L, "Borås (SE)", "#88CCEE",
  "THUAS", 2L, "Delft (NL)", "#117733",
  "BAUA", 3L, "Dortmund (DE)", "#DDCC77",
  "MPI", 4L, "Tübingen (DE)", "#DDCC77",
  "TUM", 5L, "Munich (DE)", "#DDCC77",
  "FUSPCEU", 6L, "Madrid (ES)", "#CC6677",
  "IZTECH", 7L, "Izmir (TR)", "#332288",
  "UCR", 8L, "San José (CR)", "#44AA99",
  "KNUST", 9L, "Kumasi (GH)", "#AA4499"
)
registry <- readr::read_csv(
  file.path(root, "config/site_display_registry.csv"),
  show_col_types = FALSE
) |>
  dplyr::mutate(display_order = as.integer(.data$display_order))
stopifnot(identical(as.data.frame(registry), as.data.frame(expected_registry)))

source_data <- readRDS(source_path)
chest_source_data <- readRDS(chest_source_path)
stopifnot(
  identical(
    as.data.frame(
      source_data$display_registry |>
        dplyr::mutate(display_order = as.integer(.data$display_order))
    ),
    as.data.frame(expected_registry)
  ),
  nrow(source_data$common_curve) == 48L,
  nrow(source_data$site_curves) == 9L * 48L,
  nrow(source_data$participant_curves) == 141L * 48L,
  source_data$participant_days == 816L,
  identical(
    levels(source_data$site_curves$display_name),
    expected_registry$display_name
  ),
  nrow(chest_source_data$common_curve) == 48L,
  nrow(chest_source_data$site_curves) == 8L * 48L,
  chest_source_data$participant_days == 902L,
  identical(
    levels(chest_source_data$site_curves$display_name),
    expected_registry$display_name[expected_registry$site != "MPI"]
  )
)

for (figure_source in list(source_data, chest_source_data)) {
  deviations <- figure_source$primary_deviations
  critical <- stats::qnorm(0.975)
  stopifnot(
    max(abs(
      deviations$ratio_lower -
        10^(deviations$deviation_eta - critical * deviations$standard_error)
    )) < 1e-12,
    max(abs(
      deviations$ratio_upper -
        10^(deviations$deviation_eta + critical * deviations$standard_error)
    )) < 1e-12,
    all(deviations$direction %in% c(
      "higher",
      "lower",
      "not_distinguishable"
    ))
  )
}

pointwise_windows <- readr::read_csv(
  pointwise_windows_path,
  show_col_types = FALSE
)
stopifnot(
  setequal(
    unique(pointwise_windows$run_id),
    c("main__glasses__all_available", "main__chest__all_available")
  ),
  all(pointwise_windows$bins_30_minute > 0L),
  all(pointwise_windows$direction %in% c("higher", "lower"))
)

methods <- readr::read_csv(methods_path, show_col_types = FALSE)
expected_methods <- c(
  "pointwise_conditional_95",
  "bonferroni_within_site_95",
  "global_covariance_aware_95",
  "global_bonferroni_conditional_95",
  "global_bonferroni_unconditional_95"
)
stopifnot(
  identical(methods$method_id, expected_methods),
  methods$critical_value[1] < methods$critical_value[2],
  methods$critical_value[2] < methods$critical_value[3],
  methods$critical_value[3] < methods$critical_value[4],
  methods$critical_value[4] == methods$critical_value[5],
  grepl("Vc", methods$standard_error_source[5], fixed = TRUE)
)

robustness <- readr::read_csv(
  robustness_path,
  show_col_types = FALSE
)
stopifnot(
  nrow(robustness) == 5L * 9L,
  all(robustness$contradictory_bins == 0L)
)
most_conservative <- robustness |>
  dplyr::filter(
    .data$method_id == "global_bonferroni_unconditional_95"
  ) |>
  dplyr::arrange(.data$display_order)
stopifnot(
  identical(
    most_conservative$display_name,
    expected_registry$display_name
  ),
  most_conservative$significant_bins[
    most_conservative$site == "RISE"
  ] == 0L,
  all(
    most_conservative$significant_bins[
      most_conservative$site %in% c("BAUA", "TUM", "FUSPCEU", "KNUST")
    ] > 0L
  ),
  all(
    most_conservative$significant_bins[
      most_conservative$site %in% c("THUAS", "MPI", "IZTECH", "UCR")
    ] == 0L
  )
)

pointwise <- robustness |>
  dplyr::filter(.data$method_id == "pointwise_conditional_95")
stopifnot(
  pointwise$significant_bins[pointwise$site == "MPI"] > 0L,
  pointwise$significant_bins[pointwise$site == "IZTECH"] > 0L
)

input_manifest <- readr::read_csv(inputs_path, show_col_types = FALSE)
for (i in seq_len(nrow(input_manifest))) {
  stopifnot(
    file.exists(input_manifest$path[i]),
    identical(
      artifact_sha256(input_manifest$path[i]),
      input_manifest$sha256[i]
    )
  )
}

manifest <- readr::read_csv(manifest_path, show_col_types = FALSE)
stopifnot(nrow(manifest) == 12L, all(manifest$status == "PASS"))
for (i in seq_len(nrow(manifest))) {
  path <- manifest$path[i]
  if (!startsWith(path, "/")) {
    path <- file.path(root, path)
  }
  stopifnot(
    file.exists(path),
    identical(artifact_sha256(path), manifest$sha256[i])
  )
}

# Both placement figures use the more compact 11 x 14 inch layout requested
# for the H02 render. Read PNG IHDR values directly to avoid image-decoding
# dependencies.
read_png_dimensions <- function(path) {
  connection <- file(path, open = "rb")
  on.exit(close(connection), add = TRUE)
  signature <- readBin(connection, what = "raw", n = 8L)
  chunk_length <- readBin(
    connection,
    what = "integer",
    n = 1L,
    size = 4L,
    endian = "big"
  )
  chunk_type <- rawToChar(readBin(connection, what = "raw", n = 4L))
  pixel_width <- readBin(
    connection,
    what = "integer",
    n = 1L,
    size = 4L,
    endian = "big"
  )
  pixel_height <- readBin(
    connection,
    what = "integer",
    n = 1L,
    size = 4L,
    endian = "big"
  )
  stopifnot(
    identical(
      as.integer(signature),
      as.integer(charToRaw("\x89PNG\r\n\x1a\n"))
    ),
    chunk_length == 13L,
    chunk_type == "IHDR"
  )
  c(width = pixel_width, height = pixel_height)
}
stopifnot(
  identical(
    unname(read_png_dimensions(figure_path)),
    c(3300L, 4200L)
  ),
  identical(
    unname(read_png_dimensions(chest_figure_path)),
    c(3300L, 4200L)
  )
)

message("All H02 Figure 4 replication tests passed")
