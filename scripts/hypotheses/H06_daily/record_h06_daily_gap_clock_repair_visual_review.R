#!/usr/bin/env Rscript

# Record the manual residual review for the 90 repaired gap clock cells.
# Numeric residual summaries are retained as context only and never assign the
# verdict. The reviewer inspected every indexed residual-vs-fitted and Q-Q plot
# (ten atlases, with cell-level plots available at full resolution).

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)
.libPaths(c(
  file.path(root, "renv/library/macos/R-4.6/aarch64-apple-darwin23"),
  .libPaths()
))

required_packages <- c("digest", "dplyr", "readr")
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
  "scripts/hypotheses/H06_daily/h06_daily_gap_clock_repair_contract.R"
))

h06d_gap_assert(
  identical(as.character(getRversion()), "4.6.1"),
  "Visual-review recording requires R 4.6.1"
)
paths <- h06d_gap_paths(root)
invisible(h06d_gap_verify_direct_pins(root))
invisible(h06d_gap_verify_protected_1011(root, "pre_visual_review_record"))

template_path <- file.path(
  paths$diagnostic,
  "H06_daily_gap_clock_repair_visual_review_template.csv"
)
review_path <- file.path(
  paths$diagnostic,
  "H06_daily_gap_clock_repair_visual_review.csv"
)
review <- readr::read_csv(template_path, show_col_types = FALSE)

h06d_gap_assert(
  nrow(review) == 90L && !anyDuplicated(review$frame_key) &&
    identical(sort(unique(review$metric_slot)), as.numeric(9:13)) &&
    all(review$verdict_source == "MANUAL_VISUAL_REVIEW_REQUIRED") &&
    !any(review$numeric_threshold_set_verdict),
  "The repaired visual-review template is incomplete or malformed"
)

# Verify that the images and paired source data inspected by the reviewer are
# still exactly the indexed artifacts.
plot_paths <- file.path(root, review$diagnostic_plot_relative_path)
source_paths <- file.path(root, review$source_data_relative_path)
atlas_paths <- file.path(root, review$atlas_relative_path)
h06d_gap_assert(
  all(file.exists(plot_paths)) && all(file.exists(source_paths)) &&
    all(file.exists(atlas_paths)),
  "A visual-review artifact is missing"
)
h06d_gap_assert(
  identical(
    unname(vapply(plot_paths, h06d_gap_sha256, character(1L))),
    review$diagnostic_plot_sha256
  ) &&
    identical(
      unname(vapply(source_paths, h06d_gap_sha256, character(1L))),
      review$source_data_sha256
    ) &&
    identical(
      unname(vapply(atlas_paths, h06d_gap_sha256, character(1L))),
      review$atlas_sha256
    ),
  "A plotted residual artifact changed after indexing"
)

hc3_explanation <- paste(
  "The residual-versus-fitted display shows mild centering or variance",
  "structure and the Q-Q display shows discrete or heavy-tail departure.",
  "The pattern is a reportable limitation, not a gross failure;",
  "participant-cluster HC3 remains the accepted inference route."
)
mixed_explanation <- paste(
  "The residual-versus-fitted display shows visible mild curvature or",
  "centering/variance structure and the Q-Q display shows tail departure.",
  "The pattern warrants disclosure but is not gross enough to invalidate",
  "the repaired base fit."
)

review <- review |>
  dplyr::mutate(
    visual_residual_verdict = "REVIEW_LIMITATION",
    visual_reason_codes = dplyr::if_else(
      .data$metric_slot == 11L,
      "VIS_CENTERING_OR_SCALE_PATTERN;VIS_TAIL_DEPARTURE",
      "VIS_CENTERING_OR_SCALE_PATTERN;VIS_DISCRETE_OR_HEAVY_TAIL"
    ),
    visual_explanation = dplyr::if_else(
      .data$metric_slot == 11L,
      .env$mixed_explanation,
      .env$hc3_explanation
    ),
    reviewer = "Codex scientific visual review",
    review_date = "2026-08-12",
    review_method = paste(
      "Direct visual inspection of every indexed residual-vs-fitted and",
      "normal Q-Q display; no numeric verdict rule"
    )
  )

h06d_gap_assert(
  all(review$visual_residual_verdict %in%
        c("PASS", "REVIEW_LIMITATION", "FAIL_GROSS")) &&
    !anyNA(review$visual_residual_verdict) &&
    !any(review$numeric_threshold_set_verdict) &&
    sum(review$visual_residual_verdict == "FAIL_GROSS") == 0L &&
    sum(review$visual_residual_verdict == "REVIEW_LIMITATION") == 90L,
  "The manual visual-review verdicts failed their contract"
)

h06d_gap_write_csv(review, review_path)
invisible(h06d_gap_verify_protected_1011(root, "post_visual_review_record"))
message(
  "Manual repaired residual review recorded: 90 REVIEW_LIMITATION, 0 FAIL_GROSS"
)
