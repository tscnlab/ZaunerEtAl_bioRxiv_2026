#!/usr/bin/env Rscript

# Read-only independent acceptance check for the REPORT-018 H06_daily
# order-48 fail-closed result-page package.

suppressPackageStartupMessages({
  library(digest)
  library(readr)
})

root <- normalizePath(
  Sys.getenv("NATHEALTH_PROJECT_ROOT", unset = getwd()),
  winslash = "/",
  mustWork = TRUE
)

assert <- function(condition, message) {
  if (!isTRUE(all(condition))) {
    stop(message, call. = FALSE)
  }
  invisible(TRUE)
}

sha256 <- function(path) {
  digest::digest(path, algo = "sha256", file = TRUE, serialize = FALSE)
}

evidence_dir <- file.path(
  root,
  "audit/hypotheses/H06_daily/report018_order48_result_render"
)

assert(
  identical(as.character(getRversion()), "4.6.1"),
  "The order-48 acceptance check requires R 4.6.1"
)

authority <- data.frame(
  path = c(
    file.path(evidence_dir, "order48_fail_closed_completion.md"),
    file.path(evidence_dir, "order48_fail_closed_manifest.csv"),
    file.path(evidence_dir, "verify_order48_fail_closed_package.R"),
    file.path(root, "notebooks/hypotheses/H06_daily.qmd"),
    file.path(
      root,
      "_build/nathealth/notebooks/hypotheses/H06_daily.html"
    ),
    file.path(
      root,
      "audit/hypotheses/H06_daily/H06_daily_analysis_preparation.qmd"
    ),
    file.path(
      root,
      "_build/nathealth/audit/hypotheses/H06_daily/",
      "H06_daily_analysis_preparation.html"
    )
  ),
  sha256 = c(
    "43b2f7aa09e449e770cf7e4d6bf4f7ec7e5eaaf5861011d0b0c2acba2e7dcc22",
    "795e163e1b3cea96e635097c0095f92765794b71f9eabb715be23c52874cbc8b",
    "eed1ffe2cc6c6a3a6fbeedb7ac6e605c77c931b7b59f72ef03999919694568fb",
    "01213a193515c49419dcd1ed9cffcc070a88d639a7382e218275a89bd704cb08",
    "15c537269ac0be96ce06c6b574946dc0b98d46afe36c3c696f804a216a7d0c76",
    "ef4fde67d5dd2ebbb14deb76c025b5ac2ac9b6a34f7b34ca62c2fdb382bde709",
    "7f3adfd0d80c9e083baa34f6aa056bc12e0a30e233f786fbc55a6ad6ac176259"
  ),
  stringsAsFactors = FALSE
)
assert(all(file.exists(authority$path)), "A controlling order-48 path is missing")
assert(
  identical(
    unname(vapply(authority$path, sha256, character(1L))),
    authority$sha256
  ),
  "A controlling order-48 identity changed"
)

owner_manifest_path <- file.path(
  evidence_dir,
  "order48_fail_closed_manifest.csv"
)
owner_manifest <- readr::read_csv(owner_manifest_path, show_col_types = FALSE)
assert(
  nrow(owner_manifest) == 108L &&
    !anyDuplicated(owner_manifest$path) &&
    !basename(owner_manifest_path) %in% basename(owner_manifest$path),
  "The order-48 owner manifest is malformed or circular"
)
owner_paths <- file.path(root, owner_manifest$path)
assert(all(file.exists(owner_paths)), "The order-48 owner manifest has a missing path")
assert(
  identical(
    unname(vapply(owner_paths, sha256, character(1L))),
    owner_manifest$sha256
  ) &&
    identical(as.numeric(file.info(owner_paths)$size), as.numeric(owner_manifest$bytes)),
  "The order-48 owner manifest no longer resolves exactly"
)

defects <- readr::read_csv(
  file.path(evidence_dir, "visual_fail_closed_defect_summary.csv"),
  show_col_types = FALSE
)
assert(
  identical(
    defects$defect_id,
    c("ORDER48-DEFECT-001", "ORDER48-DEFECT-002")
  ) &&
    all(grepl("FAIL_CLOSED", defects$severity, fixed = TRUE)),
  "The consolidated order-48 defect set changed"
)

placement <- readr::read_csv(
  file.path(evidence_dir, "placement_tab_content_audit.csv"),
  show_col_types = FALSE
)
assert(
  nrow(placement) == 3L &&
    length(unique(placement$body_text_sha256)) == 1L &&
    all(placement$caption_matches_expected) &&
    all(placement$contains_all_three_primary_mean_estimates) &&
    !any(placement$predictor_specific_body) &&
    all(placement$source_filter_uses_data_mask_collision) &&
    all(
      placement$prospective_filter_expression ==
        "filter(.data$predictor_id == .env$predictor_id)"
    ),
  "The predictor-tab defect evidence changed"
)

cardinality <- readr::read_csv(
  file.path(evidence_dir, "placement_source_cardinality_audit.csv"),
  show_col_types = FALSE
)
assert(
  nrow(cardinality) == 12L &&
    all(cardinality$source_rows == 15L) &&
    all(cardinality$expected_rows == 15L) &&
    all(cardinality$one_row_per_metric) &&
    all(cardinality$status == "PASS"),
  "The frozen predictor-placement source cardinality changed"
)

typography <- readr::read_csv(
  file.path(evidence_dir, "figure_final_size_typography_audit.csv"),
  show_col_types = FALSE
)
failed_figures <- typography$figure_id[typography$overall_status != "PASS"]
assert(
  nrow(typography) == 5L &&
    identical(
      failed_figures,
      c(
        "fig-h06-daily-primary-ratio",
        "fig-h06-daily-primary-absolute",
        "fig-h06-daily-fdr-overview",
        "fig-h06-daily-primary-site-deviations"
      )
    ) &&
    all(typography$effective_text_pt_at_170mm[1:4] < 7) &&
    typography$effective_text_pt_at_170mm[[5L]] >= 7 &&
    typography$required_minimum_pt[[1L]] == 7,
  "The order-48 final-size typography finding changed"
)

nonvisual <- readr::read_csv(
  file.path(evidence_dir, "nonvisual_status.csv"),
  show_col_types = FALSE
)
assert(
  nrow(nonvisual) == 12L && all(nonvisual$status == "PASS"),
  "A nonvisual order-48 acceptance domain no longer passes"
)

final_gate <- readr::read_csv(
  file.path(evidence_dir, "order48_final_gate_summary.csv"),
  show_col_types = FALSE
)
assert(
  identical(
    final_gate$domain[final_gate$status == "FAIL_CLOSED"],
    c("predictor-tab content", "figure final-size typography", "order disposition")
  ),
  "The order-48 final-gate classification changed"
)

qmd <- paste(
  readLines(file.path(root, "notebooks/hypotheses/H06_daily.qmd"), warn = FALSE),
  collapse = "\n"
)
assert(
  lengths(regmatches(
    qmd,
    gregexpr(
      "filter(.data$predictor_id == predictor_id)",
      qmd,
      fixed = TRUE
    )
  )) == 2L,
  "The two accepted unsafe predictor filters changed before disposition"
)

cat(
  paste0(
    "H06_DAILY_ORDER48_STOP=PASS ",
    "owner_rows=108 defects=2 tables=14 figures=5 ",
    "semantic_substitutions=818 build=846 protected=3260\n"
  )
)
