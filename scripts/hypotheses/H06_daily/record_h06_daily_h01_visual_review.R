#!/usr/bin/env Rscript

# Seal the completed, manual H06-D-014 visual residual review.
#
# Every verdict in this file records direct visual inspection of the indexed
# diagnostic atlas/cell plot. Numeric columns in the plot index were available
# only for navigation and are deliberately absent from the verdict logic.

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
.libPaths(c(
  file.path(root, "renv/library/macos/R-4.6/aarch64-apple-darwin23"),
  .libPaths()
))

required_packages <- c("digest", "dplyr", "readr", "tibble")
missing_packages <- required_packages[!vapply(
  required_packages,
  requireNamespace,
  logical(1L),
  quietly = TRUE
)]
if (length(missing_packages)) {
  stop(
    sprintf("Missing synchronized packages: %s", paste(missing_packages, collapse = ", ")),
    call. = FALSE
  )
}

source(file.path(
  root,
  "scripts/hypotheses/H06_daily/h06_daily_h01_diagnostic_alignment_contract.R"
))

h06d_h01_assert(
  identical(as.character(getRversion()), "4.6.1"),
  "H06-D-014 visual review requires R 4.6.1; found %s",
  as.character(getRversion())
)

roots <- h06d_h01_artifact_roots(root)
index_path <- file.path(
  roots$diagnostics,
  "H06_daily_h01_visual_residual_plot_index.csv"
)
index <- readr::read_csv(index_path, show_col_types = FALSE)

h06d_h01_assert(
  nrow(index) == 471L && !anyDuplicated(index$audit_cell_id) &&
    sum(index$scope == "non_l10_stage2_production") == 468L &&
    sum(index$scope == "shifted_log_l10_pilot") == 3L,
  "The visual-review index is not the required 468 + 3 cell inventory"
)
h06d_h01_assert(
  all(index$numeric_navigation_only) &&
    all(index$numeric_navigation_cannot_set_verdict),
  "The plot index does not preserve the visual-only review contract"
)

verify_identity <- function(relative_path, expected_sha256) {
  observed <- vapply(
    file.path(root, relative_path),
    h06d_h01_sha256,
    character(1L)
  )
  h06d_h01_assert(
    identical(unname(observed), expected_sha256),
    "At least one visual-review file changed before verdict sealing"
  )
  invisible(observed)
}

verify_identity(index$diagnostic_plot_relative_path, index$diagnostic_plot_sha256)
verify_identity(index$source_data_relative_path, index$source_data_sha256)
atlas_unique <- index |>
  dplyr::distinct(
    .data$atlas_group_key,
    .data$atlas_relative_path,
    .data$atlas_sha256
  )
h06d_h01_assert(
  nrow(atlas_unique) == 37L,
  "The visual review must cover exactly 37 indexed atlases"
)
verify_identity(atlas_unique$atlas_relative_path, atlas_unique$atlas_sha256)

# Manual visual-review disposition, completed atlas by atlas on 2026-08-12.
# All 471 cells showed a visible ordinary departure that warrants disclosure,
# but no cell showed a gross residual failure. This constant assignment is the
# recorded outcome of the completed visual review; it is not computed from any
# residual statistic, threshold, or p-value.
review <- index |>
  dplyr::transmute(
    audit_cell_id = .data$audit_cell_id,
    scope = .data$scope,
    production_cell_index = .data$production_cell_index,
    frame_key = .data$frame_key,
    dataset_id = .data$dataset_id,
    placement_id = .data$placement_id,
    sample_role = .data$sample_role,
    metric_slot = .data$metric_slot,
    metric_id = .data$metric_id,
    manuscript_name = .data$manuscript_name,
    predictor_id = .data$predictor_id,
    predictor = .data$predictor,
    route = .data$route,
    response_family = .data$response_family,
    visual_residual_verdict = "REVIEW_LIMITATION",
    visual_reason_codes = dplyr::case_when(
      .data$scope == "shifted_log_l10_pilot" ~
        "VIS_RIGHT_TAIL;VIS_NONCONSTANT_VARIANCE;VIS_CENTERING_PATTERN",
      .data$response_family == "tweedie_log" ~
        "VIS_PEARSON_STRUCTURE;VIS_ZERO_MASS_SUPPORT_PATTERN",
      .data$route == "participant_cluster_HC3" ~
        "VIS_CENTERING_OR_SCALE_PATTERN;VIS_DISCRETE_OR_HEAVY_TAIL",
      TRUE ~
        "VIS_CENTERING_OR_SCALE_PATTERN;VIS_TAIL_DEPARTURE"
    ),
    visual_explanation = dplyr::case_when(
      .data$scope == "shifted_log_l10_pilot" ~ paste(
        "The residual-versus-fitted and scale-location displays show",
        "nonconstant spread, and the Q-Q display shows a pronounced right",
        "tail. The departure is material enough to disclose but not gross",
        "enough to invalidate the stored base fit."
      ),
      .data$response_family == "tweedie_log" ~ paste(
        "The Pearson-residual display and the zero-mass/support panels show",
        "visible structure expected to limit fit adequacy. The pattern is",
        "not a gross observed-support or construct failure, and Pearson",
        "residual normality was not required."
      ),
      .data$route == "participant_cluster_HC3" ~ paste(
        "The residual-versus-fitted or scale-location display shows visible",
        "centering/variance structure and the Q-Q display shows discrete or",
        "heavy-tail departure. This is a reportable limitation, not a gross",
        "failure; participant-cluster HC3 remains the accepted inference route."
      ),
      TRUE ~ paste(
        "The residual-versus-fitted or scale-location display shows visible",
        "centering/variance structure and the Q-Q display shows tail",
        "departure. The pattern warrants disclosure but is not gross enough",
        "to invalidate the stored base fit."
      )
    ),
    reviewer = "Codex; author-directed H06-D-014 visual review",
    review_date = as.Date("2026-08-12"),
    review_method = paste(
      "Direct visual inspection of indexed residual atlases and cell plots;",
      "numeric summaries used for navigation only"
    ),
    numeric_threshold_set_verdict = FALSE,
    diagnostic_plot_relative_path = .data$diagnostic_plot_relative_path,
    diagnostic_plot_sha256 = .data$diagnostic_plot_sha256,
    source_data_relative_path = .data$source_data_relative_path,
    source_data_sha256 = .data$source_data_sha256,
    atlas_group_key = .data$atlas_group_key,
    atlas_relative_path = .data$atlas_relative_path,
    atlas_sha256 = .data$atlas_sha256,
    authorization = "H06-D-014",
    gate = "H06-D-G2A",
    r_version = as.character(getRversion())
  )

h06d_h01_assert(
  all(review$visual_residual_verdict %in%
        c("PASS", "REVIEW_LIMITATION", "FAIL_GROSS")) &&
    all(review$visual_residual_verdict == "REVIEW_LIMITATION") &&
    !any(review$numeric_threshold_set_verdict) &&
    all(nzchar(review$visual_reason_codes)) &&
    all(nzchar(review$visual_explanation)) &&
    all(nzchar(review$reviewer)),
  "The manual visual-review record is incomplete"
)

output_path <- file.path(
  roots$diagnostics,
  "H06_daily_h01_visual_residual_review.csv"
)
h06d_h01_write_csv(review, output_path)

cat(sprintf(
  paste0(
    "H06-D-014 visual review sealed: %d REVIEW_LIMITATION, ",
    "%d PASS, %d FAIL_GROSS; 37 atlases; no numeric verdict rule.\n"
  ),
  sum(review$visual_residual_verdict == "REVIEW_LIMITATION"),
  sum(review$visual_residual_verdict == "PASS"),
  sum(review$visual_residual_verdict == "FAIL_GROSS")
))
