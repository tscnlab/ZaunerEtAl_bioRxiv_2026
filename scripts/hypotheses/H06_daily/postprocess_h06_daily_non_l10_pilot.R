# Reseal H06-D-G2P-NONL10 reporting artifacts without fitting any model.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
.libPaths(c(
  file.path(root, "renv/library/macos/R-4.6/aarch64-apple-darwin23"),
  .libPaths()
))
suppressPackageStartupMessages({
  library(digest)
  library(dplyr)
  library(readr)
  library(tibble)
})
source(file.path(
  root,
  "scripts/hypotheses/H06_daily/h06_daily_non_l10_pilot_contract.R"
))

h06d_nl_assert(
  identical(as.character(getRversion()), "4.6.1"),
  "No-refit postprocessing requires R 4.6.1"
)
roots <- h06d_nl_artifact_roots(root)
producer <-
  "scripts/hypotheses/H06_daily/postprocess_h06_daily_non_l10_pilot.R"

write_csv_atomic <- function(data, path) {
  temporary <- tempfile(
    pattern = paste0(basename(path), "-"),
    tmpdir = dirname(path),
    fileext = ".tmp"
  )
  readr::write_csv(data, temporary, na = "")
  if (!file.rename(temporary, path)) {
    unlink(temporary)
    h06d_nl_abort("Could not atomically write `%s`", path)
  }
  invisible(path)
}

relative_path <- function(path) {
  sub(paste0("^", root, "/?"), "", normalizePath(
    path,
    winslash = "/",
    mustWork = FALSE
  ))
}

file_identity <- function(path) {
  h06d_nl_assert(file.exists(path), "Missing file `%s`", path)
  tibble::tibble(
    relative_path = relative_path(path),
    sha256 = h06d_nl_sha256(path),
    bytes = unname(file.info(path)$size)
  )
}

inventory_path <- file.path(
  roots$model_data,
  "H06_daily_non_l10_pilot_frame_inventory.csv"
)
class_runtime_path <- file.path(
  roots$diagnostics,
  "H06_daily_non_l10_pilot_deletion_runtime_by_class.csv"
)
runtime_path <- file.path(
  roots$diagnostics,
  "H06_daily_non_l10_pilot_runtime_and_projection.csv"
)
frame_inventory <- readr::read_csv(inventory_path, show_col_types = FALSE)
class_runtime <- readr::read_csv(class_runtime_path, show_col_types = FALSE)
runtime <- readr::read_csv(runtime_path, show_col_types = FALSE)
h06d_nl_assert(
  nrow(frame_inventory) == 468L && nrow(class_runtime) == 5L,
  "The pilot inventory or five-class runtime evidence is incomplete"
)

classify_inventory <- function(metric_id) {
  dplyr::case_when(
    metric_id %in% c(
      "daily_geometric_mean_medi", "m10_mean_medi",
      "longest_bout_above_250", "dose_time_sensitive_corrected_medi"
    ) ~ "gaussian_offset",
    metric_id %in% c(
      "duration_above_1000", "duration_above_250_wake",
      "duration_below_1_sleep_environment"
    ) ~ "tweedie_log",
    metric_id == "duration_below_10_pre_sleep" ~ "gaussian_identity",
    metric_id == "l10_midpoint" ~ "strict_clock",
    TRUE ~ "ordinary_clock"
  )
}

influence_projection <- frame_inventory |>
  dplyr::mutate(
    class_id = classify_inventory(.data$metric_id),
    row_level_deletion_refits = .data$participants + .data$sites
  ) |>
  dplyr::left_join(
    class_runtime |>
      dplyr::select("class_id", "median_seconds"),
    by = "class_id",
    relationship = "many-to-one"
  ) |>
  dplyr::summarise(
    projected_cells = dplyr::n(),
    projected_seconds = sum(
      .data$row_level_deletion_refits * .data$median_seconds
    ),
    projected_deletion_refits = sum(.data$row_level_deletion_refits),
    .by = c("dataset_id", "analysis_role")
  )
influence_projection <- dplyr::bind_rows(
  influence_projection,
  influence_projection |>
    dplyr::summarise(
      dataset_id = "all_datasets",
      analysis_role = "all_authorized_scenarios",
      projected_cells = sum(.data$projected_cells),
      projected_seconds = sum(.data$projected_seconds),
      projected_deletion_refits = sum(.data$projected_deletion_refits)
    )
)
h06d_nl_assert(
  all(is.finite(influence_projection$projected_seconds)) &&
    influence_projection$projected_seconds[
      influence_projection$analysis_role == "all_authorized_scenarios"
    ] < 3600,
  "Corrected deletion projection is not finite or exceeds one hour"
)

runtime_corrected <- dplyr::bind_rows(
  runtime |>
    dplyr::filter(!grepl("^full deletion projection:", .data$component)),
  influence_projection |>
    dplyr::transmute(
      component = paste0(
        "full deletion projection: ",
        .data$dataset_id,
        " / ",
        .data$analysis_role
      ),
      completed_units = 0,
      measured_seconds = NA_real_,
      projected_units = .data$projected_deletion_refits,
      projected_seconds = .data$projected_seconds,
      projection_scope =
        "all participant and submitted-site deletions; not run"
    )
) |>
  dplyr::mutate(
    display_order = dplyr::case_when(
      .data$component == "15-cell primary near-eye clock-family pilot" ~ 1L,
      .data$component == "five-class deletion pilot" ~ 2L,
      grepl("^full deletion projection:", .data$component) ~ 3L,
      TRUE ~ 4L
    )
  ) |>
  dplyr::arrange(.data$display_order, .data$component) |>
  dplyr::select(-"display_order")
write_csv_atomic(runtime_corrected, runtime_path)

code_manifest_path <- file.path(
  roots$manifests,
  "H06_daily_non_l10_pilot_code_manifest.csv"
)
code_manifest <- readr::read_csv(code_manifest_path, show_col_types = FALSE)
postprocess_row <- tibble::tibble(
  relative_path = producer,
  sha256 = NA_character_,
  bytes = NA_real_,
  role = "no-refit projection correction and manifest reseal"
)
code_manifest <- dplyr::bind_rows(
  code_manifest |>
    dplyr::filter(.data$relative_path != .env$producer),
  postprocess_row
) |>
  dplyr::arrange(.data$relative_path)
for (index in seq_len(nrow(code_manifest))) {
  identity <- file_identity(file.path(root, code_manifest$relative_path[[index]]))
  code_manifest$sha256[[index]] <- identity$sha256[[1L]]
  code_manifest$bytes[[index]] <- identity$bytes[[1L]]
}
write_csv_atomic(code_manifest, code_manifest_path)

preservation_path <- file.path(
  roots$diagnostics,
  "H06_daily_non_l10_pilot_preservation_final.csv"
)
preservation <- readr::read_csv(preservation_path, show_col_types = FALSE)
for (index in seq_len(nrow(preservation))) {
  path <- file.path(root, preservation$relative_path[[index]])
  h06d_nl_assert(
    h06d_nl_sha256(path) == preservation$baseline_sha256[[index]] &&
      unname(file.info(path)$size) == preservation$baseline_bytes[[index]],
    "Protected historical identity changed: `%s`",
    preservation$relative_path[[index]]
  )
}

output_manifest_path <- file.path(
  roots$manifests,
  "H06_daily_non_l10_pilot_output_manifest.csv"
)
output_manifest <- readr::read_csv(
  output_manifest_path,
  show_col_types = FALSE
)
verdict_path <- file.path(
  roots$diagnostics,
  "H06_daily_non_l10_pilot_verdict.csv"
)
output_paths <- unique(c(
  file.path(root, output_manifest$relative_path),
  verdict_path
))
output_manifest_corrected <- dplyr::bind_rows(lapply(
  output_paths,
  file_identity
)) |>
  dplyr::mutate(
    gate = "H06-D-G2P-NONL10",
    producer = producer,
    authorization = "bounded_pilot_only_no_BH_no_full_grid"
  ) |>
  dplyr::arrange(.data$relative_path)
write_csv_atomic(output_manifest_corrected, output_manifest_path)

message(sprintf(
  paste0(
    "No-refit reseal complete: all-scenario deletion projection %.1f s ",
    "for %d refits; %d output identities."
  ),
  influence_projection$projected_seconds[
    influence_projection$analysis_role == "all_authorized_scenarios"
  ],
  influence_projection$projected_deletion_refits[
    influence_projection$analysis_role == "all_authorized_scenarios"
  ],
  nrow(output_manifest_corrected)
))
