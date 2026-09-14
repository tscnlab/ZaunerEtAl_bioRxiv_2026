#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(digest)
  library(readr)
})

project_root <- normalizePath(getwd(), mustWork = TRUE)

sha256_file <- function(relative_path) {
  digest(
    file.path(project_root, relative_path),
    algo = "sha256",
    file = TRUE,
    serialize = FALSE
  )
}

bytes_file <- function(relative_path) {
  as.numeric(file.info(file.path(project_root, relative_path))$size)
}

assert_true <- function(condition, message) {
  if (!isTRUE(condition)) {
    stop(message, call. = FALSE)
  }
}

assert_true(
  identical(as.character(getRversion()), "4.6.1"),
  paste0("R 4.6.1 is required; found ", getRversion())
)

owner_manifest_path <-
  "artifacts/12_manifests/H06_daily/H06_daily_stage3_site_deviation_label_refresh_manifest.csv"
protected_inventory_path <-
  "audit/hypotheses/H06_daily/H06_daily_stage3_site_deviation_label_refresh_protected_inventory.csv"
visual_qa_path <-
  "audit/hypotheses/H06_daily/H06_daily_stage3_site_deviation_label_refresh_visual_qa.csv"

owner_manifest <- read_csv(
  file.path(project_root, owner_manifest_path),
  show_col_types = FALSE
)
assert_true(nrow(owner_manifest) == 13L, "Owner manifest must have 13 rows")
assert_true(
  all(file.exists(file.path(project_root, owner_manifest$relative_path))),
  "An owner-manifest path does not exist"
)
assert_true(
  identical(
    unname(vapply(owner_manifest$relative_path, sha256_file, character(1))),
    owner_manifest$sha256
  ),
  "An owner-manifest SHA-256 does not match"
)
assert_true(
  identical(
    unname(vapply(owner_manifest$relative_path, bytes_file, numeric(1))),
    as.numeric(owner_manifest$bytes)
  ),
  "An owner-manifest byte count does not match"
)

protected_inventory <- read_csv(
  file.path(project_root, protected_inventory_path),
  show_col_types = FALSE
)
assert_true(
  nrow(protected_inventory) == 34L,
  "Protected inventory must have 34 rows"
)
assert_true(
  all(file.exists(file.path(project_root, protected_inventory$relative_path))),
  "A protected-inventory path does not exist"
)
assert_true(
  identical(
    unname(vapply(
      protected_inventory$relative_path,
      sha256_file,
      character(1)
    )),
    protected_inventory$pre_sha256
  ),
  "A protected-inventory SHA-256 does not match"
)
assert_true(
  identical(
    unname(vapply(protected_inventory$relative_path, bytes_file, numeric(1))),
    as.numeric(protected_inventory$pre_bytes)
  ),
  "A protected-inventory byte count does not match"
)

visual_qa <- read_csv(
  file.path(project_root, visual_qa_path),
  show_col_types = FALSE
)
assert_true(nrow(visual_qa) == 2L, "Visual-QA record must have two rows")
assert_true(
  setequal(
    visual_qa$inspection_view,
    c("original_resolution", "final_width_170_mm")
  ),
  "Visual-QA views are incomplete"
)
assert_true(all(visual_qa$verdict == "PASS"), "A visual-QA view did not pass")
assert_true(
  all(!visual_qa$equal_site_visible),
  "Visible equal-site wording remains"
)
assert_true(
  all(!visual_qa$uncoded_site_visible),
  "An uncoded site label remains visible"
)
assert_true(
  all(
    visual_qa$figure_sha256 ==
      "a1ddd2ae719d5a6ab11c1c591801d4b4aa7cb06f9eb0bcad7c983d8024fd86e1"
  ),
  "Visual-QA rows do not identify the accepted refreshed PNG"
)
assert_true(
  all(
    visual_qa$source_data_sha256 ==
      "12193a0a1795fe478bf4829a3986c2b1290510038e4c4aed59aa7e61714bcbcc"
  ),
  "Visual-QA rows do not identify the frozen source data"
)

cat(
  "H06_daily order 21 independent display audit PASS:",
  nrow(owner_manifest),
  "manifest entries;",
  nrow(protected_inventory),
  "protected identities;",
  nrow(visual_qa),
  "visual-QA views\n"
)
